#!/bin/bash

<<comment
------------------------------------------------------------------

Author: RW                         

If using debian/ubuntu;

alias dnf=apt-get

If using docker;

alias podman=docker
alias podman-compose=docker-compose

Builds Zap, Arachni, Nuclei, Wapiti containers, executes scan against 
target(s) and outputs results in $RESULT_DIR

------------------------------------------------------------------
comment

#install podman and pre-req's for podman-compose like buildah, etc.
dnf update -y \
&& dnf install podman podman-compose -y

#install latest release of podman-compose (devel)
curl -o /usr/local/bin/podman-compose \
https://raw.githubusercontent.com/containers/podman-compose/devel/podman_compose.py
chmod +x /usr/local/bin/podman-compose
alias podman-compose=/usr/local/bin/podman-compose

#set env variables for scans
DATE=$(date +"%Y%m%d")
MODE="http" #or https
SCAN_TYPE=single #or multiple
TARGET="testhtml5.vulnweb.com"
WEBPORT=#"8080"
declare -a TARGETS=(
"google-gruyere.appspot.com"
"testhtml5.vulnweb.com"
"itsecgames.com")
declare -a APP_NAME=(
"google"
"testhtml5"
"itsecgames")
THREADS=35
ZAP_API_ALLOW_IP="127.0.0.1"
RESULT_DIR=$(pwd) #or state explicit directory to offload scan results to

#make output directories
mkdir -p ${RESULT_DIR}{owasp-zap,arachni,nuclei,subfinder}

# ----------------------------------------------------------------------------------------------------- zed attack proxy;
#podman build -t owasp-zap -f ./zap/Dockerfile
genkey() {
    cat /dev/urandom | tr -cd 'A-Za-z0-9' | fold -w 24 | head -1
}

podman run --rm -v $(pwd):/zap/wrk/:rw -v /etc/localtime:/etc/localtime:ro -u zap -p 8080:8080 -it --name owasp-zap \
-d docker.io/owasp/zap2docker-stable zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.addrs.addr.name=$ZAP_API_ALLOW_IP \
-config api.addrs.addr.regex=true -config api.key=$(genkey)

podman exec owasp-zap mkdir -p /zap/results

if [ "$SCAN_TYPE" = single ]; then
podman exec owasp-zap zap-full-scan.py -a -j -t ${MODE}://${TARGET} -r /zap/results/zap-report-${MODE}-${TARGET}-${DATE}.html
elif [ "$SCAN_TYPE" = multiple ]; then
for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec owasp-zap zap-full-scan.py -a -j -t ${MODE}://${TARGETS[$i]} -r /zap/results/zap-report-${MODE}-${APP_NAME[$i]}-${DATE}.html
done
fi
echo "---------------------------------------------zap scan; done."

podman cp owasp-zap:/zap/results/ $RESULT_DIR/owasp-zap

# ----------------------------------------------------------------------------------------------------- arachni;
#build arachni
tee $RESULT_DIR/arachni/Dockerfile<<EOF
FROM docker.io/debian:stable

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

podman build -t arachni -f $RESULT_DIR/arachni/Dockerfile
podman run --rm -v /etc/localtime:/etc/localtime:ro -it --name arachni -d arachni
echo "---------------------------------------------arachni build; done."

if [ "$SCAN_TYPE" = single ]; then
podman exec arachni mkdir -p /opt/arachni/results/arachni_${MODE}_scan_${DATE}/
podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--output-only-positives ${MODE}://$TARGET

elif [ "$SCAN_TYPE" = multiple ]; then
for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${APP_NAME[i]}.afr \
--output-only-positives ${MODE}://${TARGETS[$i]}
done
fi
echo "---------------------------------------------arachni scans; done."

if [ "$SCAN_TYPE" = single ]; then
podman exec arachni /opt/arachni/bin/arachni_reporter \
/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--report=html:outfile=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}_${DATE}.html.zip

elif [ "$SCAN_TYPE" = multiple ]; then
for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec arachni /opt/arachni/bin/arachni_reporter \
/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${APP_NAME[$i]}.afr \
--report=html:outfile=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGETS[$i]}.html.zip
done
fi
podman cp arachni:/opt/arachni/results/ $RESULT_DIR/arachni

# ----------------------------------------------------------------------------------------------------- nuclei;
tee $RESULT_DIR/nuclei/Dockerfile<<EOF
FROM docker.io/golang:1.19.4-alpine as build-env
RUN apk add build-base
RUN go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

FROM alpine:3.17.0
RUN apk add --no-cache bind-tools ca-certificates chromium

COPY --from=build-env /go/bin/nuclei /usr/local/bin/nuclei
EOF

podman build -t nuclei -f $RESULT_DIR/nuclei/Dockerfile
podman run --rm -v /etc/localtime:/etc/localtime:ro -it --name nuclei -d nuclei
echo "---------------------------------------------nuclei build; done."

<<comment

update and run nuclei scans, modify here to use templates found in:
podman exec nuclei ls /root/nuclei-templates
podman exec nuclei nuclei -c $THREADS -t cves/ -t vulnerabilities/ \
-u ${MODE}://$TARGET -o /results/nuclei-${MODE}-${TARGET}-${DATE}.log

comment

podman exec nuclei nuclei --update
sleep 5s
podman exec nuclei nuclei -ut
podman exec nuclei mkdir -p /results

echo "---------------------------------------------nuclei full scan init; warn: this could take some time..."
sleep 5s
if [ "$SCAN_TYPE" = single ]; then
podman exec nuclei nuclei -c $THREADS -ni -u ${MODE}://${TARGET} -o /results/nuclei-${MODE}-${TARGET}-${DATE}.log

elif [ "$SCAN_TYPE" = multiple ]; then
for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec nuclei nuclei -c $THREADS -ni -u ${MODE}://${TARGETS[$i]} -o /results/nuclei-${MODE}-${APP_NAME[$i]}-${DATE}.log
done
fi
podman cp nuclei:/results $RESULT_DIR/nuclei
echo "---------------------------------------------nuclei scans; done."

# ----------------------------------------------------------------------------------------------------- wapiti;
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
echo "---------------------------------------------wapiti build; done."

#update and execute scan
podman exec wapiti wapiti --update

if [ "$SCAN_TYPE" = single ]; then
podman exec wapiti wapiti -v2 -u ${MODE}://${TARGET}
elif [ "$SCAN_TYPE" = multiple ]; then
for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec wapiti wapiti -v2 -u ${MODE}://${TARGET[$i]}
done
fi
#get report(s)
podman cp wapiti:/root/.wapiti/generated_report $RESULT_DIR/wapiti
echo "---------------------------------------------wapiti scans; done."

<<comment
tee $RESULT_DIR/subfinder/Dockerfile<<EOF
FROM golang:1.19.4-alpine AS build-env
RUN apk add build-base
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

FROM alpine:3.17.0
RUN apk -U upgrade --no-cache \
    && apk add --no-cache bind-tools ca-certificates
COPY --from=build-env /go/bin/subfinder /usr/local/bin/subfinder
EOF

echo "---------------------------------------------getting subdomains enumeration"
podman build -t subfinder -f $RESULT_DIR/subfinder/Dockerfile
podman run --rm -v /etc/localtime:/etc/localtime:ro -it --name subfinder -d subfinder
podman exec subfinder mkdir -p /results
podman exec subfinder subfinder -d ${TARGET} -o /results/subfinder-${TARGET}-${DATE}.log
podman cp subfinder:/results $RESULT_DIR/subfinder
comment

#cleanup
podman system reset -f
dnf remove podman podman-compose -y && rm -f /usr/local/bin/podman-compose
