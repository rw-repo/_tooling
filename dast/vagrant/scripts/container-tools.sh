#!/usr/bin/env bash
#
# Provisioning script for the Container Tools meta-package
#
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl.
#
# Description: Installs the podman, buildah and skopeo Container Tools
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
echo 'Installing Container Tools meta-package'

dnf -y install container-tools ansible

echo 'Create dast account & keypair'

groupadd -r dast && useradd -r -g dast dast -m
mkdir -p /home/dast/.ssh
ssh-keygen -q -b 2048 -t rsa -N '' -C 'creating SSH' -f /home/dast/.ssh/id_rsa_dast creates='/home/dast/.ssh/id_rsa_dast'
mv /home/dast/id_rsa_dast.pub /home/dast/.ssh/authorized_keys
chmod 0600 /home/dast/.ssh/authorized_keys
chmod 0700 /home/dast/.ssh
chown -R dast:dast /home/dast
        
echo 'Modifying ssh daemon config for rsa key auth'

tee -a /etc/ssh/sshd_config<< EOF
#***********************************************************
# Enable RSA Key Authentication:
# generated for ansible
#***********************************************************
PubkeyAuthentication yes
RSAAuthentication yes
EOF

echo 'Container Tools are ready to use'
echo 'To get started, on your host, run:'
echo '  vagrant ssh'
echo
echo 'Then, within the guest (for example):'
echo '  rsync -av ipv4.address.of.host:_tooling/dast/dasty-webscan.sh /home/dast'
echo
