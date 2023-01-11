## Laying the groundwork for nomad and podman

```sh

# create nomad svc account

sudo useradd -m nomad_svc
sudo usermod -aG wheel nomad_svc
sudo usermod -u 1007 nomad_svc
sudo passwd nomad_svc

# create sysd service for podman api

sudo bash -c ' cat << EOF > /etc/systemd/system/podman.service
[Unit]
Description=Podman API service
[Service]
User=nomad_svc
WorkingDirectory=/run/user/1007/podman/
ExecStart=podman system service --timeout 0 unix:///run/user/1007/podman/podman.sock
Restart=no
[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo service podman restart

# install the nomad podman driver

wget https://github.com/hashicorp/nomad-driver-podman/archive/refs/heads/main.zip
unzip main.zip && mv nomad-driver-podman-main ./nomad-driver-podman
mv nomad-driver-podman /var/nomad/plugins/

# modify client node config file

plugin "nomad-driver-podman" {
    config {
        socket_path = "unix:///run/user/1007/podman/podman.sock"
    }
}

```
