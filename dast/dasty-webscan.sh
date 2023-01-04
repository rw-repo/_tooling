#!/bin/bash

<<comment
------------------------------------------------------------------

Author: RW                         

If using debian/ubuntu;

alias dnf=apt-get

If using docker;

alias podman=docker
alias podman-compose=docker-compose

Builds Zap, Arachni, Nuclei containers, executes scan against 
target and outputs results in $RESULT_DIR

------------------------------------------------------------------
comment

dnf update -y \
&& dnf install podman podman-compose -y

#curl -o /usr/local/bin/podman-compose \
#https://raw.githubusercontent.com/containers/podman-compose/devel/podman_compose.py
#chmod +x /usr/local/bin/podman-compose
#alias podman-compose=/usr/local/bin/podman-compose

DATE=$(date +"%Y%m%d")
MODE="http" #or https
TARGET="testhtml5.vulnweb.com"
WEBPORT=#"8080"
#declare -a TARGETS=(
#"google-gruyere.appspot.com"
#"testhtml5.vulnweb.com"
#"HackThisSite.org"
#"www.root-me.org")
#declare -a APP_NAME=(
#"google"
#"hackthissite"
#"testhtml5"
#"rootme")
THREADS=35
ZAP_API_ALLOW_IP="127.0.0.1"
RESULT_DIR=./

mkdir -p ./{owasp-zap,arachni,nuclei,subfinder}

# ----------------------------------------------------------------------------------------------------- zed attack proxy;
#podman build -t owasp-zap -f ./zap/Dockerfile
genkey() {
    cat /dev/urandom | tr -cd 'A-Za-z0-9' | fold -w 24 | head -1
}
key=$(genkey)
podman run --rm -v $(pwd):/zap/wrk/:rw -v /etc/localtime:/etc/localtime:ro -u zap -p 8080:8080 -it --name owasp-zap \
-d docker.io/owasp/zap2docker-stable@sha256:aabcb321ec17686a93403a6958541d8646c453fe9437ea43ceafc177c0308611 \
zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.addrs.addr.name=$ZAP_API_ALLOW_IP \
-config api.addrs.addr.regex=true -config api.key=$key

podman exec owasp-zap mkdir -p /zap/results
podman exec owasp-zap zap-full-scan.py -a -j -t ${MODE}://${TARGET} -r /zap/results/zap-report-${MODE}-${TARGET}-${DATE}.html
#for ((i=0; i<${#TARGETS[@]}; i++)); do
#podman exec owasp-zap zap-full-scan.py -a -j -t ${MODE}://${TARGETS[$i]} -r /zap/results/zap-report-${MODE}-${APP_NAME[$i]}-${DATE}.html
#done
echo "---------------------------------------------zap scan; done."

podman cp owasp-zap:/zap/results/ $RESULT_DIR/owasp-zap

# ----------------------------------------------------------------------------------------------------- arachni;
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
podman run --rm -v /etc/localtime:/etc/localtime:ro -it --name arachni -d arachni
echo "---------------------------------------------arachni build; done."

if [ "$MODE" = http ]; then
podman exec arachni mkdir -p /opt/arachni/results/arachni_${MODE}_scan_${DATE}/
podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--output-only-positives ${MODE}://$TARGET
#for ((i=0; i<${#TARGETS[@]}; i++)); do
#podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
#--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${APP_NAME[i]}.afr \
#--output-only-positives ${MODE}://${TARGETS[$i]}
#done
echo "---------------------------------------------arachni http scans; done."

elif [ "$MODE" = https ]; then
podman exec arachni mkdir -p /opt/arachni/results/arachni_${MODE}_scan_${DATE}/
podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--output-only-positives --scope-https-only ${MODE}://$TARGET
#for ((i=0; i<${#TARGETS[@]}; i++)); do
#podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
#--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${APP_NAME[i]}.afr \
#--output-only-positives --scope-https-only ${MODE}://${TARGETS[$i]}
#done
fi
echo "---------------------------------------------arachni https scans; done."

podman exec arachni /opt/arachni/bin/arachni_reporter \
/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--report=html:outfile=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}_${DATE}.html.zip
#for ((i=0; i<${#TARGETS[@]}; i++)); do
#podman exec arachni /opt/arachni/bin/arachni_reporter \
#/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${APP_NAME[$i]}.afr \
#--report=html:outfile=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGETS[$i]}.html.zip
#done
podman cp arachni:/opt/arachni/results/ $RESULT_DIR/arachni

# ----------------------------------------------------------------------------------------------------- nuclei;
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
podman exec nuclei nuclei --ut
sleep 5s
podman exec nuclei nuclei -ut
podman exec nuclei mkdir -p /results

echo "---------------------------------------------nuclei full scan init; warn: this could take some time..."
sleep 5s
podman exec nuclei nuclei -c $THREADS -ni -u ${MODE}://${TARGET} -o /results/nuclei-${MODE}-${TARGET}-${DATE}.log
#for ((i=0; i<${#TARGETS[@]}; i++)); do
#podman exec nuclei nuclei -c $THREADS -ni -u ${MODE}://${TARGETS[$i]} -o /results/nuclei-${MODE}-${APP_NAME[$i]}-${DATE}.log
#done
echo "---------------------------------------------nuclei scans; done."

podman cp nuclei:/results $RESULT_DIR/nuclei
cd ../subfinder

tee ./Dockerfile<<EOF
FROM golang:1.19.4-alpine@sha256:f33331e12ca70192c0dbab2d0a74a52e1dd344221507d88aaea605b0219a212f AS build-env
RUN apk add build-base
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

FROM alpine:3.17.0@sha256:c0d488a800e4127c334ad20d61d7bc21b4097540327217dfab52262adc02380c
RUN apk -U upgrade --no-cache \
    && apk add --no-cache bind-tools ca-certificates
COPY --from=build-env /go/bin/subfinder /usr/local/bin/subfinder
EOF

echo "---------------------------------------------getting sub directories enumeration"
podman build -t subfinder .
podman run --rm -v /etc/localtime:/etc/localtime:ro -it --name subfinder -d subfinder
podman exec subfinder mkdir -p /results
podman exec subfinder subfinder -d ${TARGET} -o /results/subfinder-${TARGET}-${DATE}.log
podman cp subfinder:/results $RESULT_DIR/subfinder

#cleanup
#podman system reset -f
#dnf remove podman podman-compose -y
