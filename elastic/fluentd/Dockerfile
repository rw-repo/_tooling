# fluentd/Dockerfile

FROM fluent/fluentd:v1.15.0-debian-1.0
USER root
RUN ["gem", "install", "fluent-plugin-elasticsearch", "--no-document", "--version", "5.2.4"]
RUN ["gem", "install", "fluent-plugin-logdna", "--no-document", "--version", "0.4.0"]
RUN ["gem", "install", "fluent-plugin-cloudwatch", "--no-document", "--version", "2.1.1"]
RUN ["gem", "install", "fluent-plugin-grok-parser", "--no-document", "--version", "2.6.2"]
USER fluent
