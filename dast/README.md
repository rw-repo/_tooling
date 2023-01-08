# Dynamic Application Security Testing

[What is DAST?>](https://en.wikipedia.org/wiki/Dynamic_application_security_testing)

[What is Podman?>](https://www.redhat.com/en/topics/containers/what-is-podman)

[Installing Podman>](https://podman.io/getting-started/installation)

[What is OWASP ZAP?>](https://www.zaproxy.org/)

[What is Arachni?>](https://www.arachni-scanner.com/)

[What is Nuclei?>](https://projectdiscovery.io/)

[What is Wapiti?>](https://wapiti-scanner.github.io/)

> **Note**
>
>   Disclaimer: scan only against websites where you have permission/authorization.
>
>   Using "testhtml5.vulnweb.com" for this demo.  The following readme shows how to manually build and scan with 
>
>   each application.  Use "dasty-webscan.sh" to automate the process in a single shell script.
>
>   Warning: This is an HTML5 application that is vulnerable by design. This is not a real collection of tweets. 
>
>   This application was created so that you can test your Acunetix, other tools, or your manual penetration testing skills. 
>
>   The application code is prone to attacks such as Cross-site Scripting (XSS) and XML External Entity (XXE). 
>
>   Links presented on this site have no affiliation to the site and are here only as samples.

```sh
#install podman/podman-compose from package repo, get latest podman-compose
sudo dnf install podman podman-compose -y
sudo curl -o /usr/local/bin/podman-compose \
https://raw.githubusercontent.com/containers/podman-compose/devel/podman_compose.py
sudo chmod +x /usr/local/bin/podman-compose
alias podman-compose=/usr/local/bin/podman-compose
```

#

```sh
#set env variables and make output directories

DATE=$(date +"%Y%m%d")
MODE=http
TARGET=testhtml5.vulnweb.com
THREADS=35
ZAP_API_ALLOW_IP=127.0.0.1
RESULT_DIR=./

mkdir -p ${RESULT_DIR}{owasp-zap,arachni,nuclei,wapiti}
```

## <img src="https://res.cloudinary.com/practicaldev/image/fetch/s--r24tUVpQ--/c_imagga_scale,f_auto,fl_progressive,h_900,q_auto,w_1600/https://dev-to-uploads.s3.amazonaws.com/i/8uadzrkmk3n3tige1kgx.png" width=40% height=40%>

```sh
<<comment
Generate random 24 char api key, container is meant to be ran as user zap, run a scan, and then deleted.  
Note: If keeping zap persistent, use the Dockerfile found in the zap directory, builds and updates packages.

podman build -t owasp-zap -f ./zap/Dockerfile
comment

genkey() {
    cat /dev/urandom | tr -cd 'A-Za-z0-9' | fold -w 24 | head -1
}

#run zap stable docker image
podman run --rm -v $(pwd):/zap/wrk/:rw -v /etc/localtime:/etc/localtime:ro -u zap -p 8080:8080 -it --name owasp-zap \
-d docker.io/owasp/zap2docker-stable zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.addrs.addr.name=$ZAP_API_ALLOW_IP \
-config api.addrs.addr.regex=true -config api.key=$(genkey)

<<comment

#run zap from Dockerfile build
podman run --rm -v $(pwd):/zap/wrk/:rw -v /etc/localtime:/etc/localtime:ro -u zap -p 8080:8080 -it --name owasp-zap \
-d owasp-zap zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.addrs.addr.name=$ZAP_API_ALLOW_IP \
-config api.addrs.addr.regex=true -config api.key=$(genkey)

comment

#create result directory and run scan
podman exec owasp-zap mkdir -p /zap/results
podman exec owasp-zap zap-full-scan.py -a -j -t ${MODE}://${TARGET} -r /zap/results/zap-report-${MODE}-${TARGET}-${DATE}.html
podman cp owasp-zap:/zap/results/ $RESULT_DIR/owasp-zap
```

## <img src="https://www.arachni-scanner.com/wp-content/uploads/2013/03/arachni-web-logo.png" width=40% height=40%>

```sh
tee $RESULT_DIR/arachni/Dockerfile<<EOF
FROM docker.io/debian:stable
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8
RUN apt-get update -y && apt-get install build-essential \
    libcurl4 libcurl4-openssl-dev ruby ruby-dev \
    wget ca-certificates chromium -y \
    && apt-get clean -yq \
    && apt-get autoremove -yq \
    && wget -qO- https://github.com/Arachni/arachni/releases/download/v1.6.1.3/arachni-1.6.1.3-0.6.1.1-linux-x86_64.tar.gz \
    | tar zx && mv /arachni-1.6.1.3-0.6.1.1 /opt/arachni
RUN groupadd -r arachni && useradd -r -g arachni arachni \
    && chown -R arachni:arachni /opt/arachni
USER arachni
EOF

#build arachni
podman build -t arachni -f $RESULT_DIR/arachni/Dockerfile
podman run --rm -v /etc/localtime:/etc/localtime:ro -it --name arachni -d arachni

#execute scan
podman exec arachni mkdir -p /opt/arachni/results/arachni_${MODE}_scan_${DATE}/
podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--output-only-positives ${MODE}://$TARGET

#generate html report from afr
podman exec arachni /opt/arachni/bin/arachni_reporter \
/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--report=html:outfile=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}_${DATE}.html.zip

#get results
podman cp arachni:/opt/arachni/results/ $RESULT_DIR/arachni
```

## <img src="https://1.bp.blogspot.com/-IywUo6ng-aA/Xqhh_Py83DI/AAAAAAAAGHA/xbkI1KWpuB0VnRyvdSoRWHM8tOEX0iD6QCLcBGAsYHQ/s1600/nuclei.png" width=20% height=20%>

```sh
tee $RESULT_DIR/nuclei/Dockerfile<<EOF
FROM docker.io/golang:1.19.4-alpine as build-env
RUN apk add build-base
RUN go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
FROM docker.io/alpine:3.17.0
RUN apk add --no-cache bind-tools ca-certificates chromium
COPY --from=build-env /go/bin/nuclei /usr/local/bin/nuclei
EOF

#build Nuclei
podman build -t nuclei -f $RESULT_DIR/nuclei/Dockerfile
podman run --rm -v /etc/localtime:/etc/localtime:ro -it --name nuclei -d nuclei

#update templates
podman exec nuclei nuclei -ut
podman exec nuclei mkdir -p /results

#execute scan
podman exec nuclei nuclei -c $THREADS -ni -u ${MODE}://${TARGET} -o /results/nuclei-${MODE}-${TARGET}-${DATE}.log
podman cp nuclei:/results $RESULT_DIR/nuclei
```

## <img src="https://wapiti-scanner.github.io/wapiti_400.png" width=20% height=20%>

```sh
tee $RESULT_DIR/wapiti/Dockerfile<<EOF
FROM docker.io/debian:bullseye-slim as build
ENV DEBIAN_FRONTEND=noninteractive \
  LANG=en_US.UTF-8
WORKDIR /usr/src/app/
RUN apt-get update \
  && apt-get install python3 python3-pip python3-setuptools ca-certificates wget unzip -y \
  && apt-get clean -yq \
  && apt-get autoremove -yq \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log \
  && wget https://github.com/wapiti-scanner/wapiti/archive/refs/heads/master.zip && unzip master.zip \
  && mv ./wapiti-master/* ./
RUN python3 setup.py install
FROM debian:bullseye-slim
ENV DEBIAN_FRONTEND=noninteractive \
  LANG=en_US.UTF-8 \
  PYTHONDONTWRITEBYTECODE=1
RUN apt-get update \
  && apt-get install python3 python3-setuptools -y \
  && apt-get clean -yq \
  && apt-get autoremove -yq \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log
COPY --from=build /usr/local/lib/python3.9/dist-packages/ /usr/local/lib/python3.9/dist-packages/
COPY --from=build /usr/local/bin/wapiti /usr/local/bin/wapiti-getcookie /usr/local/bin/
EOF

#build Wapiti
podman build -t wapiti -f $RESULT_DIR/wapiti/Dockerfile
podman run --rm -v /etc/localtime:/etc/localtime:ro -it --name wapiti -d wapiti

#update and execute scan
podman exec wapiti wapiti --update
podman exec wapiti wapiti -v2 -u ${MODE}://${TARGET}

#get report
podman cp wapiti:/root/.wapiti/generated_report $RESULT_DIR/wapiti
```

```sh
#cleanup
podman system reset -f
sudo dnf remove podman podman-compose -y
sudo rm -f /usr/local/bin/podman-compose
```

To-do's:

generate k8s services

terraform/nomad with podman automation
