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
