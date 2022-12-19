#!/bin/bash

BURP_HOST=#burp.domainname.io
BURP_PORT=#8080
BURP_APIKEY=#someapikey
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
RESULT_DIR=./
mkdir -p ./burp

dnf update -y \
&& dnf install podman podman-compose -y

#curl -o /usr/local/bin/podman-compose \
#https://raw.githubusercontent.com/containers/podman-compose/devel/podman_compose.py
#chmod +x /usr/local/bin/podman-compose
#alias podman-compose=/usr/local/bin/podman-compose

# ----------------------------------------------------------------------------------------------------- burpsuite;
podman build -t burpsuite .
podman run --rm -it --name burpsuite -p 8080:8080 -p 1337:1337 -d burpsuite
podman exec burpsuite mkdir -p $RESULT_DIR/burp

if [ "$MODE" = http ]; then
podman exec burpsuite curl -s -X POST "http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan" \
-d "{\"scope\":{\"include\":[{\"rule\":\"http://$TARGET:80\"}],\"type\":\"SimpleScope\"},\"urls\":[\"http://$TARGET:$WEBPORT\"]}"

elif [ "$MODE" = https ]; then
podman exec burpsuite curl -s -X POST "http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan" \
-d "{\"scope\":{\"include\":[{\"rule\":\"https://$TARGET:443\"}],\"type\":\"SimpleScope\"},\"urls\":[\"https://$TARGET:$WEBPORT\"]}"
fi

for a in {1..30}; do 
podman exec burpsuite echo -n "[-] SCAN #$a: "
podman exec burpsuite curl -sI "http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan/$a" | grep HTTP | awk '{print $2}'
podman exec burpsuite BURP_STATUS=$(curl -s http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan/$a \
| grep -o -P "crawl_and_audit.{1,100}" | cut -d\" -f3 | grep "remaining")
while [[ ${#podman exec burpsuite BURP_STATUS} -gt "5" ]]; do 
podman exec burpsuite BURP_STATUS=$(curl -s http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan/$a \
| grep -o -P "crawl_and_audit.{1,100}" | cut -d\" -f3 | grep "remaining")
podman exec burpsuite BURP_STATUS_FULL=$(curl -s http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan/$a \
| grep -o -P "crawl_and_audit.{1,100}" | cut -d\" -f3)
podman exec burpsuite echo "[i] STATUS: $BURP_STATUS_FULL"
podman exec burpsuite sleep 15
	done
done

for a in {1..30}; do
podman exec burpsuite curl -s "http://$BURP_HOST:$BURP_PORT/$BURP_APIKEY/v0.1/scan/$a" \
| jq '.issue_events[].issue | "[" + .severity + "] " + .name + " - " + .origin + .path' | sort -u | sed 's/\"//g' \
| tee $RESULT_DIR/web/burpsuite-$TARGET-$a.log
done
podman cp burpsuite:$RESULT_DIR/burp $RESULT_DIR/burp
echo "---------------------------------------------burp scan; done."
