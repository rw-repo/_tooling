ARG ELASTIC_VERSION

# https://www.docker.elastic.co/
FROM docker.elastic.co/kibana/kibana:${ELASTIC_VERSION}
USER root
RUN apt-get update -y && apt-get autoremove -y
USER kibana:root
# Add your kibana plugins setup here
# Example: RUN kibana-plugin install <name|url>
