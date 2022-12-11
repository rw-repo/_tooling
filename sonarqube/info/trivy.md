<div id="header" align="center">
<img src="https://devopstales.github.io/img/trivy.png" width=20% height=20%><img src="https://www.sonarqube.org/logos/index/sonarqube-logo@2x.png" width=20% height=20%>
</div>

# Trivy and Sonarqube

Example commands to run trivy scans of docker images:
```sh
sudo mkdir -p ./{trivy-cache,trivy-output}
# json output
podman run --rm -v ./trivy-cache/:/root/.cache/:z \
                -v ./trivy-output:/output:z \
                aquasec/trivy image \
                -f json -o /output/<give_this_a_name-report>.json \
                <repo/image_name:tag>
              
# html output
podman run --rm -v ./trivy-cache/:/root/.cache/:z \
                -v ./trivy-output:/output:z \
                aquasec/trivy image \
                --format template --template "@contrib/html.tpl" -o /output/<give_this_a_name-report>.html \
                <repo/image_name:tag>
```

### Create a custom Sonarqube JSON output

This step will use the sonarqube.tpl as a template:

```sh
podman run --rm -v ./trivy-cache/:/root/.cache/:z \
                -v ./sonarqube.tpl:/input/sonarqube.tpl:ro \
                -v ./trivy-output:/output:z aquasec/trivy \
                image --exit-code 1 --no-progress \
                --format template --template "@/input/sonarqube.tpl" \
                -o /output/<image_name>-report.json \
                <repo/image_name:tag>
```

A `<image_name>-report.json` appears in trivy-output. 

### Send the generated report to Sonarqube

Finally you can send the generated report.json to Sonarqube using Sonar Scanner CLI.  Substitute the SONAR_LOGIN value below with your project's token.  

```sh
# Login to localhost:9000 (admin/admin), change password and create a new project - generate token.
podman run --rm \
           -e SONAR_HOST_URL=http://<Insert ipv4 here>:9000 \
           -e SONAR_LOGIN=<Insert the token here> \
           -v ./:/usr/src:z \
           sonarsource/sonar-scanner-cli \
           -Dsonar.projectKey=test \
           -Dsonar.externalIssuesReportPaths=./trivy-output/<name-of-report-using-sonarqube.tpl.json>
```

Go to the Sonarqube test project and look for the vulnerabilities there.

## (Optional) Install sonar-scanner locally (linux):

```sh
sudo wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.7.0.2747-linux.zip
sudo unzip sonar-scanner-cli-4.7.0.2747-linux.zip
sudo mv sonar-scanner-cli-4.7.0.2747-linux/ /opt/sonar-scanner

sudo tee -a /opt/sonar-scanner/conf/sonar-scanner.properties<< EOF
sonar.host.url=http://localhost:9000
sonar.sourceEncoding=UTF-8
EOF

sudo tee /etc/profile.d/sonar-scanner.sh<< EOF
#!/bin/bash
export PATH="$PATH:/opt/sonar-scanner/bin"
EOF

sudo source /etc/profile.d/sonar-scanner.sh
### reboot?
```

```sh
# Login to localhost:9000 (admin/admin), change password and create a new project - generate token.
# Example using local install of sonar-scanner

sonar-scanner \
           -Dsonar.projectKey=<project name> \
           -Dsonar.externalIssuesReportPaths=./trivy-output/<image-name>-report.json
           -Dsonar.host.url=http://localhost:9000 \
           -Dsonar.login=<insert token value>
```

