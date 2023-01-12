if using rhel; insights offers free malware scanning with IBM X-Force Threat Intelligence Malware Team:
```sh
dnf install yara -y
insights-client --register
# To perform proper scans, please set test_scan: false in /etc/insights-client/malware-detection-config.yml
insights-client --collector malware-detection
```
to view detection results:   https://console.redhat.com/insights/malware/systems
