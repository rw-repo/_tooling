
#
Sn1per Community Edition is an automated scanner that can be used during a penetration test to enumerate and scan for vulnerabilities.

https://sn1persecurity.com/wordpress/

https://aws.amazon.com/marketplace/pp/prodview-rmloab6wnymno

https://github.com/1N3/Sn1per

#

> **Note**
>
> Using podman-compose. (1.0.4 and podman 4.1.1)
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


# Setup example:

```bash
tee ./Dockerfile<<EOF
FROM kalilinux/kali-rolling

LABEL org.label-schema.name='Sn1per - Kali Linux' \
    org.label-schema.description='Automated pentest framework for offensive security experts' \
    org.label-schema.usage='https://github.com/1N3/Sn1per' \
    org.label-schema.url='https://github.com/1N3/Sn1per' \
    org.label-schema.vendor='https://sn1persecurity.com' \
    org.label-schema.schema-version='1.0' \
    org.label-schema.docker.cmd.devel='docker run --rm -ti xer0dayz/sniper' \
    MAINTAINER="@xer0dayz"

RUN echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" > /etc/apt/sources.list && \
    echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list
ENV DEBIAN_FRONTEND noninteractive

RUN set -x \
        && apt-get -yqq update \
        && apt-get -yqq dist-upgrade \
        && apt-get clean
RUN apt-get install -y metasploit-framework

RUN sed -i 's/systemctl status ${PG_SERVICE}/service ${PG_SERVICE} status/g' /usr/bin/msfdb && \
    service postgresql start && \
    msfdb reinit

RUN apt-get --yes install git \
    && mkdir -p security \
    && cd security \
    && git clone https://github.com/1N3/Sn1per.git \
    && cd Sn1per \
    && ./install.sh \
    && sniper -u force

CMD ["bash"]
EOF

podman build -t sn1per . 

sudo mkdir sn1per_scans

podman run --rm -it --name pen_test \
       -p 4444:4444 -p 80:80 -p 8080:8080 \
       -p 443:443 -p 445:445 -p 8081:8081 \
       -d sn1per

podman exec pen_test apt autoremove -y
```

# Usage:

```bash

#discover targets
podman exec pen_test sniper -t 192.168.0.0/24 -m discover

# normal scan
podman exec pen_test sniper -t 192.168.2.18

#collect results
podman cp pen_test:/workspace/192.168.2.18 ./sn1per_scans/

```


```
NORMAL: Performs basic scan of targets and open ports using both active and passive checks for optimal performance.
STEALTH: Quickly enumerate single targets using mostly non-intrusive scans to avoid WAF/IPS blocking.
FLYOVER: Fast multi-threaded high level scans of multiple targets (useful for collecting high level data on many hosts quickly).
AIRSTRIKE: Quickly enumerates open ports/services on multiple hosts and performs basic fingerprinting. To use, specify the full location of the file which contains all hosts, IPs that need to be scanned and run ./sn1per /full/path/to/targets.txt airstrike to begin scanning.
NUKE: Launch full audit of multiple hosts specified in text file of choice. Usage example: ./sniper /pentest/loot/targets.txt nuke.
DISCOVER: Parses all hosts on a subnet/CIDR (ie. 192.168.0.0/16) and initiates a sniper scan against each host. Useful for internal network scans.
PORT: Scans a specific port for vulnerabilities. Reporting is not currently available in this mode.
FULLPORTONLY: Performs a full detailed port scan and saves results to XML.
MASSPORTSCAN: Runs a "fullportonly" scan on mutiple targets specified via the "-f" switch.
WEB: Adds full automatic web application scans to the results (port 80/tcp & 443/tcp only). Ideal for web applications but may increase scan time significantly.
MASSWEB: Runs "web" mode scans on multiple targets specified via the "-f" switch.
WEBPORTHTTP: Launches a full HTTP web application scan against a specific host and port.
WEBPORTHTTPS: Launches a full HTTPS web application scan against a specific host and port.
WEBSCAN: Launches a full HTTP & HTTPS web application scan against via Burpsuite and Arachni.
MASSWEBSCAN: Runs "webscan" mode scans of multiple targets specified via the "-f" switch.
VULNSCAN: Launches a OpenVAS vulnerability scan.
MASSVULNSCAN: Launches a "vulnscan" mode scans on multiple targets specified via the "-f" switch.
```

<p align="center">
  <img src="https://media.giphy.com/media/26tPnAAJxXTvpLwJy/giphy.gif" />
</p>

