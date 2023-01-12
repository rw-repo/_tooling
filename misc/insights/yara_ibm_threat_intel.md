if using rhel; insights offers free malware scanning with IBM X-Force Threat Intelligence Malware Team signatures:
```sh
dnf install yara -y
insights-client --register
# run initial test scan
insights-client --collector malware-detection
# modify config
# To perform proper scans, please set test_scan: false in /etc/insights-client/malware-detection-config.yml
insights-client --collector malware-detection
```
to view detection results:   https://console.redhat.com/insights/malware/systems
