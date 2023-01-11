# Sonarqube

[What is Sonarqube?>](https://docs.sonarqube.org/latest/)

[What is Podman?>](https://www.redhat.com/en/topics/containers/what-is-podman)

[Installing Podman>](https://podman.io/getting-started/installation)

[![Sonar](https://img.youtube.com/vi/vE39Fg8pvZg/0.jpg)](https://www.youtube.com/watch?v=vE39Fg8pvZg)

> **Note**  
> Using podman-compose.
>
> curl -o /usr/local/bin/podman-compose https://raw.githubusercontent.com/containers/podman-compose/devel/podman_compose.py
>
> chmod +x /usr/local/bin/podman-compose
>
> alias podman-compose=/usr/local/bin/podman-compose
>

#
Linux requirements:

```
    vm.max_map_count is greater than or equal to 524288

    fs.file-max is greater than or equal to 131072

    the user running SonarQube can open at least 131072 file descriptors

    the user running SonarQube can open at least 8192 threads
    
```   
#
Configuring those settings:    

```sh
sudo tee /etc/sysctl.d/99-sonarqube-pod.conf<<EOF
[main]
summary=Sonarqube/podman/traefik settings
[sysctl]
vm.max_map_count=524288
fs.file-max=131072
net.ipv4.ip_unprivileged_port_start=80
EOF

sudo sysctl -p /etc/sysctl.d/99-sonarqube-pod.conf

#If the user running SonarQube (sonarqube in this example) does not have the permission 
# to have at least 131072 open descriptors, you must insert this line in /etc/security/limits.conf
sudo tee -a /etc/security/limits.conf<< EOF
sonarqube   -   nofile   131072
sonarqube   -   nproc    8192
EOF

```
#

> **Note**  
> podman-compose commands are ran in this example with the user "sonarqube".

```sh
podman-compose up -d
```

http://localhost:9000

admin:admin  (will be prompted for new password)

## Spin up an external postgres db for sonarqube to connect to:

Enter a password for POSTGRES_PASS=
```sh
sudo tee ./.env<< EOF
POSTGRES_PASS=< ....... >
JPOSTGRESC_PASS=< ....... >
JDBC_IP=< ....... >
EOF

podman-compose -f docker-compose-postgres.yml up -d
podman exec -it postgres /bin/bash
```
#
```console
1001@704fa0524868:/$ psql -U postgres -W
Password: 
#enter password from .env for ${POSTGRES_PASS}

    create user sonar with encrypted password '_enter a password here_';
    create database sonarqube with owner sonar encoding 'UTF8';
    \q

exit
```
#
Update .env with the newly generated account info:
```console
JPOSTGRESC_USER=< ....... >
JPOSTGRESC_PASS=< ....... >
```
#
Get the IP address
```sh
podman inspect postgres | grep IPAddress
```
#
Update .env
```console

JDBC_IP=< ....... >

```
#

```yaml
  sonarqube:
    image: docker.io/sonarqube:latest
    container_name: sonarqube
    environment:
      SONAR_JDBC_URL: jdbc:postgresql:://${JDBC_IP}:5432/sonarqube
      
```
#
```sh
podman-compose -f docker-compose-postgres-sonar.yml up -d
```

```sh

#podman.sock for user (traefik ssl frontend)
#to expose podman.sock for traefik
sudo systemctl start podman.socket
systemctl --user enable podman.socket

#test socket connection
sudo curl -H "Content-Type: application/json" --unix-socket \
/run/user/<$uid>/podman/podman.sock http://localhost/_ping

```
#

Generate kubectl service with podman:

www.redhat.com/sysadmin/compose-kubernetes-podman
```sh
sudo podman generate kube -s -f new_kubernetes_service.yaml <container_name> <container_name>

The -s in the previous command signifies that Podman will generate service for this pod. 
The -f option allows us to save the generated YAML into a file. Otherwise, the output is sent to stdout, 
where it can be redirected to a file.

```
