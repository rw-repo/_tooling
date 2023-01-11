## Scan this code base with sonarqube and see why it's vulnerable.

```sh
podman run --rm \
           -e SONAR_HOST_URL=http://<Insert ipv4 here>:9000 \
           -e SONAR_LOGIN=<Insert the token here> \
           -v ./_tooling/sonarqube/vulnerable_code_examples:/usr/src:z \
           -d docker.io/sonarsource/sonar-scanner-cli
```
