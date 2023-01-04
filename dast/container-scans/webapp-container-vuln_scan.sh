#!/bin/bash
<<comment

This shell script will scan declared container images with

aquasec trivy - vulnerabilities (json,html)
anchore syft - SBOM
anchore grype - vulnerabilities (csv)

if using docker;

alias podman=docker
comment

#create report output directories
mkdir -p ./scan_results/{trivy-cache,trivy-output,syft,grype}

#example,
declare -a D_IMAGE=(
#"my_repo/dev/my_webapp:v1"
"docker.io/owasp/zap2docker-stable:latest"
"localhost/arachni"
"localhost/nuclei")
declare -a R_NAME=(
#"my_webapp"
"owasp-zap"
"arachni"
"nuclei")

for ((i=0; i<${#D_IMAGE[@]}; i++)); do
# json output
podman run --rm -v ./scan_results/trivy-cache/:/root/.cache/:z \
                -v ./scan_results/trivy-output:/output:z \
                docker.io/aquasec/trivy image \
                -f json -o /output/${R_NAME[$i]}-report.json \
                ${D_IMAGE[$i]}
done
for ((i=0; i<${#D_IMAGE[@]}; i++)); do
# html output
podman run --rm -v ./scan_results/trivy-cache/:/root/.cache/:z \
                -v ./scan_results/trivy-output:/output:z \
                docker.io/aquasec/trivy image \
                --format template --template "@contrib/html.tpl" -o /output/${R_NAME[$i]}-vulnerabilities.html \
                ${D_IMAGE[$i]}
done

# syft scans
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
for ((i=0; i<${#D_IMAGE[@]}; i++)); do
/usr/local/bin/syft ${D_IMAGE[$i]} -o syft-json=./scan_results/syft/${R_NAME[$i]}_sbom.json
done
for ((i=0; i<${#D_IMAGE[@]}; i++)); do
/usr/local/bin/syft ${D_IMAGE[$i]} -o syft-table=./scan_results/syft/${R_NAME[$i]}_sbom.csv
done

#install and run grype to get csv vuln output
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
for ((i=0; i<${#D_IMAGE[@]}; i++)); do
/usr/local/bin/grype ${D_IMAGE[$i]} -o table --file ./scan_results/grype/${R_NAME[$i]}_vulnerabilities.csv
done

#cleanup
podman rmi aquasec/trivy -f
rm -rf /usr/local/bin/syft /usr/local/bin/grype ./trivy-cache
echo "==========================================
See findings in ./scan_results/ directory.
=========================================="
