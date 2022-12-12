ARG ELASTIC_VERSION

# https://www.docker.elastic.co/
FROM docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}

USER root

COPY . /

RUN set -eux; \
	mkdir /state; \
	chown elasticsearch /state; \
	chmod +x /entrypoint.sh && \
	apt-get update -y && \
    	apt-get upgrade -y && \
    	apt-get autoremove -y

USER elasticsearch:root

ENTRYPOINT ["/entrypoint.sh"]
