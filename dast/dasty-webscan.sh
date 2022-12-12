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
&& dnf install podman podman-compose -y #comment out if using docker instead

DATE=$(date +"%Y%m%d%H%M")
TARGET="testhtml5.vulnweb.com"
#declare -a TARGETS=(
#"google-gruyere.appspot.com"
#"www.itsecgames.com"
#"HackThisSite.org"
#"www.root-me.org")
#declare -a APP_NAME=(
#"google"
#"itsecgames"
#"hackthissite"
#"rootme")
THREADS=35
BURP_HOST=#burp.domainname.io
BURP_PORT=#8080
BURP_APIKEY=#someapikey
ZAP_API_ALLOW_IP="127.0.0.1"
RESULT_DIR=./

mkdir -p ./{owasp-zap,arachni,nuclei}

# ---------------------------------------------------- burpsuite;
#podman build -t burpsuite -f ./burp/Dockerfile
#podman run --rm -it --name burpsuite -p 8080:8080 -p 1337:1337 -d burpsuite
#podman exec burpsuite mkdir -p $RESULT_DIR/dast
#podman exec burpsuite curl -s -X POST "http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan" \
#-d "{\"scope\":{\"include\":[{\"rule\":\"http://$TARGET:80\"}],\"type\":\"SimpleScope\"},\"urls\":[\"http://$TARGET:$WEBPORT\"]}"
#podman exec burpsuite curl -s -X POST "http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan" \
#-d "{\"scope\":{\"include\":[{\"rule\":\"https://$TARGET:443\"}],\"type\":\"SimpleScope\"},\"urls\":[\"https://$TARGET:$WEBPORT\"]}"
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
#podman cp burpsuite:$RESULT_DIR/dast $RESULT_DIR/dast
#echo "---------------------------------------------burp scan; done."

# ---------------------------------------------------- zed attack proxy;
#podman build -t owasp-zap -f ./zap/Dockerfile
#build
genkey() {
    cat /dev/urandom | tr -cd 'A-Za-z0-9' | fold -w 24 | head -1
}
key=$(genkey)
podman run -v $(pwd):/zap/wrk/:rw -u zap -p 8080:8080 -it --name owasp-zap -d docker.io/owasp/zap2docker-stable \
zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.addrs.addr.name=$ZAP_API_ALLOW_IP \
-config api.addrs.addr.regex=true -config api.key=$key
#for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec owasp-zap zap-full-scan.py -t http://$TARGET -r /zap/zap-report-$TARGET-http-$DATE.html
#podman exec owasp-zap zap-full-scan.py -t http://${TARGETS[$i]} -r /zap/zap-report-${APP_NAME[$i]}-http-$DATE.html
#done
#for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec owasp-zap zap-full-scan.py -t https://$TARGET -r /zap/zap-report-$TARGET-https-$DATE.html
#podman exec owasp-zap zap-full-scan.py -t https://${TARGETS[$i]} -r /zap/zap-report-${APP_NAME[$i]}-https-$DATE.html
#done
#for ((i=0; i<${#APP_NAME[@]}; i++)); do
podman cp owasp-zap:/zap/zap-report-$TARGET-http-$DATE.html $RESULT_DIR/owasp-zap
podman cp owasp-zap:/zap/zap-report-$TARGET-https-$DATE.html $RESULT_DIR/owasp-zap
#podman cp owasp-zap:/zap/zap-report-${APP_NAME[$i]}-http.html $RESULT_DIR/dast
#podman cp owasp-zap:/zap/zap-report-${APP_NAME[$i]}-https.html $RESULT_DIR/dast
#done
echo "---------------------------------------------zap scan; done."

# ---------------------------------------------------- arachni;
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
podman run -it --name arachni -d arachni
echo "---------------------------------------------arachni build; done."

PORT=80
podman exec arachni mkdir -p /opt/arachni/results/arachni_${TARGET}_${PORT}/
#for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
--report-save-path=/opt/arachni/results/arachni_${TARGET}_${PORT}/arachni_${TARGET}_${PORT}.afr \
--output-only-positives http://$TARGET
#podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
#--report-save-path=/opt/arachni/results/arachni_${APP_NAME[$i]}_${PORT}/arachni_${TARGETS[i]}_${PORT}.afr \
#--output-only-positives http://${TARGETS[$i]}
#done
#for ((i=0; i<${#APP_NAME[@]}; i++)); do
podman exec arachni /opt/arachni/bin/arachni_reporter \
/opt/arachni/results/arachni_${TARGET}_${PORT}/arachni_${TARGET}_${PORT}.afr \
--report=html:outfile=/opt/arachni/results/arachni_${TARGET}_${PORT}/arachni_${TARGET}_${PORT}_${DATE}.html.zip
#podman exec arachni /opt/arachni/bin/arachni_reporter \
#/opt/arachni/results/arachni_${APP_NAME[$i]}_${PORT}/arachni_${APP_NAME[$i]}_${PORT}.afr \
#--report=html:outfile=/opt/arachni/results/arachni_${APP_NAME[$i]}_${PORT}/arachni_${APP_NAME[$i]}_${PORT}.html.zip
#done
echo "---------------------------------------------arachni 80 scans; done."

PORT=443
podman exec arachni mkdir -p /opt/arachni/results/arachni_${TARGET}_${PORT}/
#for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
--report-save-path=/opt/arachni/results/arachni_${TARGET}_${PORT}/arachni_${TARGET}_${PORT}.afr --output-only-positives \
--scope-https-only https://$TARGET
#podman exec arachni /opt/arachni/bin/arachni --output-verbose --scope-include-subdomains \
#--report-save-path=/opt/arachni/results/arachni_${APP_NAME[$i]}_${PORT}/arachni_${TARGETS[i]}_${PORT}.afr \
#--output-only-positives --scope-https-only https://${TARGETS[$i]}
#done
#for ((i=0; i<${#APP_NAME[@]}; i++)); do
podman exec arachni /opt/arachni/bin/arachni_reporter \
/opt/arachni/results/arachni_${TARGET}_${PORT}/arachni_${TARGET}_${PORT}.afr \
--report=html:outfile=/opt/arachni/results/arachni_${TARGET}_${PORT}/arachni_${TARGET}_${PORT}_${DATE}.html.zip
#podman exec arachni /opt/arachni/bin/arachni_reporter \
#/opt/arachni/results/arachni_${APP_NAME[$i]}_${PORT}_${DATE}/arachni_${APP_NAME[$i]}_${PORT}.afr \
#--report=html:outfile=/opt/arachni/results/arachni_${APP_NAME[$i]}_${PORT}/arachni_${APP_NAME[$i]}_${PORT}.html.zip
#done
podman cp arachni:/opt/arachni/results/ $RESULT_DIR/arachni
echo "---------------------------------------------arachni 443 scans; done."

# ---------------------------------------------------- nuclei;
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
podman run -it --name nuclei -d nuclei
echo "---------------------------------------------nuclei build; done."

#update and run nuclei scans, modify here to use templates found in:
#podman exec nuclei ls /root/nuclei-templates
#podman exec nuclei nuclei -c $THREADS -t cves/ -t vulnerabilities/ -u https://$TARGET -o results.log
#runs all templates against target
podman exec nuclei nuclei --update
podman exec nuclei nuclei --ut
podman exec nuclei mkdir -p /results
#for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec nuclei nuclei -c $THREADS -ni -u http://$TARGET -o /results/nuclei-http-${TARGET}-port80-${DATE}.log
#podman exec nuclei nuclei -c $THREADS -ni -u http://${TARGETS[$i]} -o /results/nuclei-http-${APP_NAME[$i]}-port80.log
#done
#for ((i=0; i<${#TARGETS[@]}; i++)); do
podman exec nuclei nuclei -c $THREADS -ni -u https://$TARGET -o /results/nuclei-https-${TARGET}-port443-${DATE}.log
#podman exec nuclei nuclei -c $THREADS -ni -u https://${TARGETS[$i]} -o /results/nuclei-https-${APP_NAME[$i]}-port443.log
#done
podman cp nuclei:/results $RESULT_DIR/nuclei
cd ..
echo "---------------------------------------------nuclei scans; done."

#cleanup
#podman system reset -f
#dnf remove podman podman-compose -y
