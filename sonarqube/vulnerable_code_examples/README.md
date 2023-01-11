## Scan this code base with sonarqube and see why it's vulnerable.

podman run --rm \
           -e SONAR_HOST_URL=http://<Insert ipv4 here>:9000 \
           -e SONAR_LOGIN=<Insert the token here> \
           -v ./:/usr/src:z \
           docker.io/sonarsource/sonar-scanner-cli \
           -Dsonar.projectKey=<Insert name of project created> \
           -Dsonar.sources=./_tooling/sonarqube/vulnerable_code_examples
