## Laying the groundwork for nomad and podman

> **Note**
>
> [What is Nomad?>](https://www.nomadproject.io)
>
> [What is Consul?>](https://www.consul.io)
>
> Consul is the service mesh, Nomad is the orchestrator, Vault keeps secrets, and podman (daemonless)
>
> [What is Podman?>](https://www.redhat.com/en/topics/containers/what-is-podman)
>
> [Installing Podman>](https://podman.io/getting-started/installation)

## Nomad at scale example

[![Nomad](https://img.youtube.com/vi/hIb9PKcm6dI/0.jpg)](https://www.youtube.com/watch?v=hIb9PKcm6dI)

to-do's

enable tls for nomad servers/clients

generate nomad/podman task/job's for dast scans

#

nomad arch
<p align="center">
  <img src="https://content.hashicorp.com/api/assets?product=tutorials&version=main&asset=public%2Fimg%2Fnomad%2Fproduction%2Fnomad_reference_diagram.png?raw=true" alt="Nomad Architecture"/>
</p>


```sh
# install nomad

sudo dnf install yum-utils -y
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install nomad -y

# create nomad user

sudo groupadd -r nomad
sudo useradd -r -g nomad nomad -m
sudo passwd nomad

# create nomad sysd service

sudo touch /etc/systemd/system/nomad.service

sudo tee -a /etc/systemd/system/nomad.service<<EOF
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

# When using Nomad with Consul it is not necessary to start Consul first. These
# lines start Consul before Nomad as an optimization to avoid Nomad logging
# that Consul is unavailable at startup.
Wants=consul.service
After=consul.service

[Service]

# Nomad server should be run as the nomad user. Nomad clients
# should be run as root
User=nomad
Group=nomad

ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
Restart=on-failure
RestartSec=2

## Configure unit start rate limiting. Units which are started more than
## *burst* times within an *interval* time span are not permitted to start any
## more. Use `StartLimitIntervalSec` or `StartLimitInterval` (depending on
## systemd version) to configure the checking interval and `StartLimitBurst`
## to configure how many starts per interval are allowed. The values in the
## commented lines are defaults.

StartLimitBurst = 5

## StartLimitIntervalSec is used for systemd versions >= 230
StartLimitIntervalSec = 10s

## StartLimitInterval is used for systemd versions < 230
# StartLimitInterval = 10s

TasksMax=infinity
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
EOF

# common config

sudo mkdir --parents /etc/nomad.d
sudo chmod 700 /etc/nomad.d

sudo touch /etc/nomad.d/nomad.hcl

sudo tee -a /etc/nomad.d/nomad.hcl<<EOF
datacenter = "dc1"
data_dir = "/opt/nomad"
EOF

sudo touch /etc/nomad.d/server.hcl

sudo tee -a /etc/nomad.d/server.hcl<<EOF
server {
  enabled = true
  bootstrap_expect = 3
}
EOF

sudo touch /etc/nomad.d/client.hcl

sudo tee -a /etc/nomad.d/client.hcl<<EOF
client {
  enabled = true
}
EOF

sudo systemctl enable nomad
sudo systemctl start nomad
sudo systemctl status nomad

# create podman api svc account

sudo useradd -m podman_api
sudo usermod -aG wheel podman_api
sudo usermod -u 1007 podman_api
sudo passwd podman_api
sudo runuser -l podman_api -c 'systemctl --user enable --now podman.socket'

# create sysd service for podman api

sudo tee /etc/systemd/system/podman.service<<EOF
[Unit]
Description=Podman API service
[Service]
User=podman_api
WorkingDirectory=/run/user/1007/podman/
ExecStart=podman system service --timeout 0 unix:///run/user/1007/podman/podman.sock
Restart=no
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo service podman restart

# install the nomad podman driver

sudo wget https://github.com/hashicorp/nomad-driver-podman/archive/refs/heads/main.zip
sudo unzip main.zip
sudo mv nomad-driver-podman-main ./nomad-driver-podman
sudo mv nomad-driver-podman /usr/lib/nomad/plugins/

# modify client node config file

plugin "nomad-driver-podman" {
    config {
        socket_path = "unix:///run/user/1007/podman/podman.sock"
    }
}

```
