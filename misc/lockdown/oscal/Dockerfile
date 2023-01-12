FROM docker.io/oraclelinux:9 as build-env
RUN dnf install golang libxml2-devel -y \
    && go install -v github.com/gocomply/fedramp/cli/gocomply_fedramp@latest
FROM oraclelinux:9
RUN dnf install ca-certificates wget git -y \
    && dnf update -y \
    && dnf autoremove -y
WORKDIR /bin
COPY --from=build-env /root/go/bin/* /bin/
RUN gocomply_fedramp opencontrol https://github.com/ComplianceAsCode/redhat xml/ \
    && wget https://raw.githubusercontent.com/ComplianceAsCode/oscal/master/xml/rhel-8-fedramp-High.xml \
    && gocomply_fedramp convert ./rhel-8-fedramp-High.xml FedRAMP-High-rhel8.docx
