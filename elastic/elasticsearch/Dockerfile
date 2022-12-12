ARG ELASTIC_VERSION

# https://www.docker.elastic.co/
FROM docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}
USER root
RUN apt-get update -y && apt-get autoremove -y
# Add healthcheck
COPY scripts/docker-healthcheck .
HEALTHCHECK CMD sh ./docker-healthcheck
USER elasticsearch:root
# Add your elasticsearch plugins setup here
# Example: RUN elasticsearch-plugin install analysis-icu
