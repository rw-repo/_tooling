FROM openjdk:11-jre-slim@sha256:cd8e8c81caa2f6374692143e6fcf75b2f6e395371969cf5c624ff6f3e4cdd159
ARG PORTSWIGGER_EMAIL_ADDRESS=${PORTSWIGGER_EMAIL}
ARG PORTSWIGGER_PASSWORD=${PORTSWIGGER_PASS}
ENV BURP_SUITE_PRO_VERSION="2022.11.3"
ENV BURP_SUITE_PRO_CHECKSUM="6f088b1dbc21edfe1ea78c79c1e23fe13f50bc434e7f0449ac50bc580201b6b3"
ENV HOME /home/burp
ENV JAVA_OPTS "-Dawt.useSystemAAFontSettings=gasp "\
  "-Dswing.aatext=true "\
  "-Dsun.java2d.xrender=true" \
  "-XX:+UnlockExperimentalVMOptions "\
  "-XX:+UseCGroupMemoryLimitForHeap "\
  "-XshowSettings:vm"
RUN apt update && apt install -y curl openssl ca-certificates \
  fontconfig libxext6 libxrender1 libxtst6
COPY download.sh entrypoint.sh /home/burp/
RUN chmod +x /home/burp/download.sh /home/burp/entrypoint.sh && \
  /home/burp/download.sh && \
  mv "$HOME/burpsuite_pro_v$BURP_SUITE_PRO_VERSION.jar" /home/burp/burpsuite_pro.jar
RUN addgroup --system burp && \
  adduser --system --ingroup burp burp
RUN mkdir -p .java/.userPrefs
USER burp
WORKDIR $HOME
# Burp Proxy
EXPOSE 8080
# Burp REST API
EXPOSE 1337
ENTRYPOINT ["/home/burp/entrypoint.sh", "/home/burp/burpsuite_pro.jar"]
