# Tooling Repository

Open source tools and on-going projects for familiarization.  

Disclaimer: Not intended for production use.  

Random projects of open source software for knowledge sharing.

Remember, most companies shamlessly rip from open source and package it as their own.  "Proprietary"...

“The truth is like poetry… and most people (expletive) HATE poetry.” - The Big Short

Common software used here:

podman - https://podman.io/

docker - https://www.docker.com/

k8s - https://kubernetes.io/

rhel - https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux

oracle linux - https://www.oracle.com/linux/

nginx - https://nginx.org/en/

traefik - https://traefik.io/

openscap - https://www.open-scap.org/

trivy - https://www.aquasec.com/products/trivy/

syft & grype - https://anchore.com/opensource/

if using rhel; now insights offers free malware scanning:
```sh
dnf install yara -y
insights-client --register
# To perform proper scans, please set test_scan: false in /etc/insights-client/malware-detection-config.yml
insights-client --collector malware-detection
```
to view detection results:   https://console.redhat.com/insights/malware/systems
