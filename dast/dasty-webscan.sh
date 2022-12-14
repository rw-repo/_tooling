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

requirements:
linux64
internet connection

...editing
Burpsuite - editing
Zap - done
Arachni - done
Nuclei - done

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
BURP_HOST=#burp.domainname.io
BURP_PORT=#8080
BURP_APIKEY=#someapikey
ZAP_API_ALLOW_IP="127.0.0.1"
RESULT_DIR=./

mkdir -p ./{owasp-zap,arachni,nuclei}

# ----------------------------------------------------------------------------------------------------- burpsuite;
#podman build -t burpsuite -f ./burp/Dockerfile
#podman run --rm -it --name burpsuite -p 8080:8080 -p 1337:1337 -d burpsuite
#podman exec burpsuite mkdir -p $RESULT_DIR/burp

#if [ "$MODE" = http ]; then
#podman exec burpsuite curl -s -X POST "http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan" \
#-d "{\"scope\":{\"include\":[{\"rule\":\"http://$TARGET:80\"}],\"type\":\"SimpleScope\"},\"urls\":[\"http://$TARGET:$WEBPORT\"]}"

#elif [ "$MODE" = https ]; then
#podman exec burpsuite curl -s -X POST "http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan" \
#-d "{\"scope\":{\"include\":[{\"rule\":\"https://$TARGET:443\"}],\"type\":\"SimpleScope\"},\"urls\":[\"https://$TARGET:$WEBPORT\"]}"
#fi

#for a in {1..30}; 
#do 
#	podman exec burpsuite echo -n "[-] SCAN #$a: "
#	podman exec burpsuite curl -sI "http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan/$a" | grep HTTP | awk '{print $2}'
#	podman exec burpsuite BURP_STATUS=$(curl -s http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan/$a \
#	| grep -o -P "crawl_and_audit.{1,100}" | cut -d\" -f3 | grep "remaining")
#while [[ ${#podman exec burpsuite BURP_STATUS} -gt "5" ]]; 
#do 
#	podman exec burpsuite BURP_STATUS=$(curl -s http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan/$a \
#	| grep -o -P "crawl_and_audit.{1,100}" | cut -d\" -f3 | grep "remaining")
#	podman exec burpsuite BURP_STATUS_FULL=$(curl -s http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan/$a \
#	| grep -o -P "crawl_and_audit.{1,100}" | cut -d\" -f3)
#	podman exec burpsuite echo "[i] STATUS: $BURP_STATUS_FULL"
#	podman exec burpsuite sleep 15
#	done
#done

#for a in {1..30}; 
#do
#	podman exec burpsuite curl -s "http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan/$a" \
#	| jq '.issue_events[].issue | "[" + .severity + "] " + .name + " - " + .origin + .path' | sort -u | sed 's/\"//g' \
#	| tee $RESULT_DIR/web/burpsuite-$TARGET-$a.log
#done
#podman cp burpsuite:$RESULT_DIR/burp $RESULT_DIR/burp
#echo "---------------------------------------------burp scan; done."

# ----------------------------------------------------------------------------------------------------- zed attack proxy;
#podman build -t owasp-zap -f ./zap/Dockerfile
genkey() {
    cat /dev/urandom | tr -cd 'A-Za-z0-9' | fold -w 24 | head -1
}
key=$(genkey)
podman run --rm -v $(pwd):/zap/wrk/:rw -u zap -p 8080:8080 -it --name owasp-zap -d docker.io/owasp/zap2docker-live \
zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.addrs.addr.name=$ZAP_API_ALLOW_IP \
-config api.addrs.addr.regex=true -config api.key=$key

podman exec owasp-zap zap-full-scan.py -a -j -t ${MODE}://${TARGET} -r /zap/zap-report-${MODE}-${TARGET}-${DATE}.html
#for ((i=0; i<${#TARGETS[@]}; i++)); do
#podman exec owasp-zap zap-full-scan.py -a -j -t ${MODE}://${TARGETS[$i]} -r /zap/zap-report-${MODE}-${APP_NAME[$i]}-${DATE}.html
#done
echo "---------------------------------------------zap scan; done."

podman cp owasp-zap:/zap/ $RESULT_DIR/owasp-zap

# ----------------------------------------------------------------------------------------------------- arachni;
cd arachni
#build arachni
tee ./Dockerfile<<EOF
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

podman build -t arachni .
podman run --rm -it --name arachni -d arachni
echo "---------------------------------------------arachni build; done."

if [ "$MODE" = http ]; then
podman exec arachni mkdir -p /opt/arachni/results/arachni_${MODE}_scan_${DATE}/
#for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--output-only-positives ${MODE}://$TARGET
#podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
#--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${APP_NAME[i]}.afr \
#--output-only-positives ${MODE}://${TARGETS[$i]}
#done
echo "---------------------------------------------arachni http scans; done."

elif [ "$MODE" = https ]; then
podman exec arachni mkdir -p /opt/arachni/results/arachni_${MODE}_scan_${DATE}/
#for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--output-only-positives --scope-https-only ${MODE}://$TARGET
#podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
#--report-save-path=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${APP_NAME[i]}.afr \
#--output-only-positives --scope-https-only ${MODE}://${TARGETS[$i]}
#done
fi
echo "---------------------------------------------arachni https scans; done."

#for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec arachni /opt/arachni/bin/arachni_reporter \
/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGET}.afr \
--report=html:outfile=/opt/arachni/results/arachni_${MODE}_scan/arachni_${MODE}_${TARGET}_${DATE}.html.zip
#podman exec arachni /opt/arachni/bin/arachni_reporter \
#/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${APP_NAME[$i]}.afr \
#--report=html:outfile=/opt/arachni/results/arachni_${MODE}_scan_${DATE}/arachni_${MODE}_${TARGETS[$i]}.html.zip
#done
podman cp arachni:/opt/arachni/results/ $RESULT_DIR/arachni

# ----------------------------------------------------------------------------------------------------- nuclei;
cd ../nuclei
tee ./Dockerfile<<EOF
FROM docker.io/golang:1.19.3-alpine as build-env
RUN apk add build-base
RUN go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

FROM alpine:3.17.0
RUN apk add --no-cache bind-tools ca-certificates chromium wget unzip

COPY --from=build-env /go/bin/nuclei /usr/local/bin/nuclei
EOF

podman build -t nuclei .
podman run --rm -it --name nuclei -d nuclei
echo "---------------------------------------------nuclei build; done."

<<comment

update and run nuclei scans, modify here to use templates found in:
podman exec nuclei ls /root/nuclei-templates
podman exec nuclei nuclei -c $THREADS -t cves/ -t vulnerabilities/ \
-u ${MODE}://$TARGET -o /results/nuclei-${MODE}-${TARGET}-${DATE}.log
runs all templates against target

comment

podman exec nuclei nuclei --update
podman exec nuclei nuclei --ut
podman exec nuclei mkdir -p /results

podman exec nuclei nuclei -c $THREADS -ni -u ${MODE}://${TARGET} -o /results/nuclei-${MODE}-${TARGET}-${DATE}.log
#for ((i=0; i<${#TARGETS[@]}; i++)); do
#podman exec nuclei nuclei -c $THREADS -ni -u ${MODE}://${TARGETS[$i]} -o /results/nuclei-${MODE}-${APP_NAME[$i]}-${DATE}.log
#done
echo "---------------------------------------------nuclei scans; done."

podman cp nuclei:/results $RESULT_DIR/nuclei
cd ..

#cleanup
#podman system reset -f
#dnf remove podman podman-compose -y
