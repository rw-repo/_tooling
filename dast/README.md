#

> **Note**
>
> Using el8/9 distro with podman-compose. (1.0.4 [development release] and podman 4.1.1)
>
> sudo curl -o /usr/local/bin/podman-compose \
>
> https://raw.githubusercontent.com/containers/podman-compose/devel/podman_compose.py
>
> sudo chmod +x /usr/local/bin/podman-compose
>
> alias podman-compose=/usr/local/bin/podman-compose
>
> [What is Podman?>](https://www.redhat.com/en/topics/containers/what-is-podman)
>
> [Installing Podman>](https://podman.io/getting-started/installation)
>
> [What is OWASP ZAP?>](https://www.zaproxy.org/)
>
> [What is Arachni?>](https://www.arachni-scanner.com/)
>
> [What is Nuclei?>](https://projectdiscovery.io/)

```sh
#install podman/podman-compose from package repo
sudo dnf install podman podman-compose -y
```

#

```sh
#set env variables and make output directories

DATE=$(date +"%Y%m%d")
MODE="http" #or https
TARGET="testhtml5.vulnweb.com"
THREADS=35
ZAP_API_ALLOW_IP="127.0.0.1"
RESULT_DIR=./

mkdir -p ./{owasp-zap,arachni,nuclei}
```

## OWASP Zed Attack Proxy  <img src="https://res.cloudinary.com/practicaldev/image/fetch/s--r24tUVpQ--/c_imagga_scale,f_auto,fl_progressive,h_900,q_auto,w_1600/https://dev-to-uploads.s3.amazonaws.com/i/8uadzrkmk3n3tige1kgx.png" width=20% height=20%>

```sh

genkey() {
    cat /dev/urandom | tr -cd 'A-Za-z0-9' | fold -w 24 | head -1
}
key=$(genkey)
podman run --rm -v $(pwd):/zap/wrk/:rw -u zap -p 8080:8080 -it --name owasp-zap \
-d docker.io/owasp/zap2docker-stable@sha256:aabcb321ec17686a93403a6958541d8646c453fe9437ea43ceafc177c0308611 \
zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.addrs.addr.name=$ZAP_API_ALLOW_IP \
-config api.addrs.addr.regex=true -config api.key=$key

podman exec owasp-zap mkdir -p /zap/results
podman exec owasp-zap zap-full-scan.py -a -j -t ${MODE}://${TARGET} -r /zap/results/zap-report-${MODE}-${TARGET}-${DATE}.html
podman cp owasp-zap:/zap/results/ $RESULT_DIR/owasp-zap
```

## Arachni  <img src="https://camo.githubusercontent.com/1ba175bad30bd9869f493975a08eb65a7a16e944e528ba22e8eb4df571319fd2/687474703a2f2f7777772e61726163686e692d7363616e6e65722e636f6d2f6c617267652d6c6f676f2e706e67" width=20% height=20%>

```sh

cd arachni
#build arachni
tee ./Dockerfile<<EOF
FROM docker.io/debian:stable@sha256:1f51b4ada92150468a245a7aca50710bff8b07b774e164d9136a8e00cc74a57a
RUN apt-get update -y && apt-get install build-essential \
    libcurl4 libcurl4-openssl-dev ruby ruby-dev \
    wget ca-certificates chromium -y && apt-get autoremove -y
RUN wget -qO- https://github.com/Arachni/arachni/releases/download/v1.6.1.3/arachni-1.6.1.3-0.6.1.1-linux-x86_64.tar.gz \
    | tar zx && mv /arachni-1.6.1.3-0.6.1.1 /opt/arachni
RUN groupadd -r arachni && useradd -r -g arachni arachni
RUN chown -R arachni:arachni /opt/arachni
USER arachni
CMD ["/bin/bash"]
EOF

podman build -t arachni .
podman run --rm -it --name arachni -d arachni

#execute scan
podman exec arachni mkdir -p /opt/arachni/results/arachni_${MODE}_scan_${DATE}/
podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--output-only-positives ${MODE}://$TARGET

#generate html report from afr
podman exec arachni /opt/arachni/bin/arachni_reporter \
/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--report=html:outfile=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}_${DATE}.html.zip

podman cp arachni:/opt/arachni/results/ $RESULT_DIR/arachni
```

## Nuclei  <img src="https://escape.tech/blog/content/images/2021/11/image-11.png" width=20% height=20%>

```sh

cd ../nuclei
tee ./Dockerfile<<EOF
FROM docker.io/golang:1.19.4-alpine@sha256:f33331e12ca70192c0dbab2d0a74a52e1dd344221507d88aaea605b0219a212f as build-env
RUN apk add build-base
RUN go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
FROM alpine:3.17.0@sha256:c0d488a800e4127c334ad20d61d7bc21b4097540327217dfab52262adc02380c
RUN apk add --no-cache bind-tools ca-certificates chromium
COPY --from=build-env /go/bin/nuclei /usr/local/bin/nuclei
EOF

podman build -t nuclei .
podman run --rm -it --name nuclei -d nuclei

#update templates
podman exec nuclei nuclei -ut
podman exec nuclei mkdir -p /results

#execute scan
podman exec nuclei nuclei -c $THREADS -ni -u ${MODE}://${TARGET} -o /results/nuclei-${MODE}-${TARGET}-${DATE}.log
podman cp nuclei:/results $RESULT_DIR/nuclei
```
