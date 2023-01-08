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
