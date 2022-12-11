#!/bin/bash
GREEN='\033[92m'
ORANGE='\033[93m'
BLUE='\033[96m'
## Shell script to automate installation, initialization of kubernetes on el8/9 distro's
## installs required bins, firewall and other settings as well

echo -e "$ORANGE ######################################################################################$RESET"
echo -e "" 
echo -e "$GREEN __________________________________________________________________ k8s firewalld ports$RESET"
echo -e ""
echo -e "$ORANGE ######################################################################################$RESET"
echo -e "$BLUE"
sleep 2s

#master node
#firewalld k8s ports - https://kubernetes.io/docs/reference/ports-and-protocols/
firewall-cmd --permanent --new-policy kubernetes
firewall-cmd --permanent --policy kubernetes --set-target DROP
firewall-cmd --permanent --policy kubernetes --add-ingress-zone ANY
firewall-cmd --permanent --policy kubernetes --add-egress-zone ANY
firewall-cmd --permanent --policy kubernetes --add-port=6443/tcp
firewall-cmd --permanent --policy kubernetes --add-port=2379-2380/tcp
firewall-cmd --permanent --policy kubernetes --add-port=10250/tcp
firewall-cmd --permanent --policy kubernetes --add-port=10257/tcp
firewall-cmd --permanent --policy kubernetes --add-port=10259/tcp
firewall-cmd --permanent --policy kubernetes --add-masquerade
firewall-cmd --reload

echo -e "$GREEN ------------- firewalld rules set; done"

echo -e "$ORANGE ######################################################################################$RESET"
echo -e "" 
echo -e "$GREEN _______________________________________________________ containerd, etcd, k8s packages$RESET"
echo -e ""
echo -e "$ORANGE ######################################################################################$RESET"
echo -e "$BLUE"
sleep 2s

# installing pre-req's for k8s setup
mkdir k8s_setup && cd k8s_setup
dnf install git wget gcc golang iproute-tc -y

#installing containerd
git clone https://github.com/containerd/containerd
cd containerd && make BUILDTAGS=no_btrfs && make install

tee /etc/systemd/system/containerd.service<< EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
#uncomment to enable the experimental sbservice (sandboxed) version of containerd/cri integration
#Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now containerd && systemctl start containerd
cd ..

#installing etcd
git clone -b v3.5.0 https://github.com/etcd-io/etcd.git
cd etcd
./build.sh
export PATH="$PATH:$(pwd)/bin"
cd .. && etcd --version

#installing k8s packages for rhel
tee /etc/yum.repos.d/kubernetes.repo<< EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
dnf install kubectl kubeadm kubelet podman-docker -y
echo -e "$GREEN ------------- golang, containerd, etcd, k8s packages for rhel; done."

echo -e "$ORANGE ######################################################################################$RESET"
echo -e "" 
echo -e "$GREEN __________________________________________________________ configuring system settings$RESET"
echo -e ""
echo -e "$ORANGE ######################################################################################$RESET"
echo -e "$BLUE"
sleep 2s

#sysctl settings, selinux.
swapoff -a
sed -i 's/^\(.*swap.*\)$/#\1/' /etc/fstab

echo 'KUBELET_EXTRA_ARGS="--container-runtime=remote --container-runtime-endpoint=/run/containerd/containerd.sock"' > /etc/sysconfig/kubelet

modprobe overlay
modprobe br_netfilter

setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

tee /etc/sysctl.d/99-k8s.conf<< EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p /etc/sysctl.d/99-k8s.conf

echo -e "$GREEN ------------- swapoff, point kubelet to containerd socket, sysctl, selinux; done."

echo -e "$ORANGE ######################################################################################$RESET"
echo -e "" 
echo -e "$GREEN _________________________________________________________________ initializing kubeadm$RESET"
echo -e ""
echo -e "$ORANGE ######################################################################################$RESET"
echo -e "$BLUE"
sleep 2s

#singlenode
kubeadm init --pod-network-cidr=192.168.0.0/16
kubeadm init phase kubelet-start
kubeadm config images pull
kubeadm init --ignore-preflight-errors=all

export HOME="/root"
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#install calico, NAC
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml 
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml

## Create Audit Policy
tee /etc/kubernetes/audit-policy.yaml <<EOF
---
apiVersion: audit.k8s.io/v1
kind: Policy
# Don't generate audit events for all requests in RequestReceived stage.
omitStages:
  - "RequestReceived"
rules:
  # Log pod changes at RequestResponse level
  - level: RequestResponse
    resources:
    - group: ""
      # Resource "pods" doesn't match requests to any subresource of pods,
      # which is consistent with the RBAC policy.
      resources: ["pods"]
  # Log "pods/log", "pods/status" at Metadata level
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/log", "pods/status"]

  # Don't log requests to a configmap called "controller-leader"
  - level: None
    resources:
    - group: ""
      resources: ["configmaps"]
      resourceNames: ["controller-leader"]

  # Don't log watch requests by the "system:kube-proxy" on endpoints or services
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
    - group: "" # core API group
      resources: ["endpoints", "services"]

  # Don't log authenticated requests to certain non-resource URL paths.
  - level: None
    userGroups: ["system:authenticated"]
    nonResourceURLs:
    - "/api*" # Wildcard matching.
    - "/version"

  # Log the request body of configmap changes in kube-system.
  - level: Request
    resources:
    - group: "" # core API group
      resources: ["configmaps"]
    # This rule only applies to resources in the "kube-system" namespace.
    # The empty string "" can be used to select non-namespaced resources.
    namespaces: ["kube-system"]

  # Log configmap and secret changes in all other namespaces at the Metadata level.
  #- level: Metadata
  - level: Request
    resources:
    - group: "" # core API group
      resources: ["secrets", "configmaps"]

  # Log all other resources in core and extensions at the Request level.
  - level: Request
    resources:
    - group: "" # core API group
    - group: "extensions" # Version of group should NOT be included.

  # A catch-all rule to log all other requests at the Metadata level.
  - level: Metadata
    # Long-running requests like watches that fall under this rule will not
    # generate an audit event in RequestReceived.
    omitStages:
      - "RequestReceived"
EOF

# folder to save audit logs
mkdir -p /var/log/kubernetes/audit
echo -e "$GREEN ------------- kubeadm/kubelet initialized; done."

kubectl get pods --all-namespaces
