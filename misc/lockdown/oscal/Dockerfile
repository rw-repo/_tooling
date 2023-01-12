# editing
FROM docker.io/golang:1.19.4-alpine as build-env
RUN apk add build-base
RUN go install -v github.com/gocomply/fedramp/cli/gocomply_fedramp@latest
FROM alpine:3.17.0
RUN apk add --no-cache bind-tools ca-certificates wget
COPY --from=build-env /go/bin/gocomply_fedramp /usr/local/bin/gocomply_fedramp
RUN gocomply_fedramp opencontrol https://github.com/ComplianceAsCode/redhat xml/ \
    && wget https://raw.githubusercontent.com/ComplianceAsCode/oscal/master/xml/rhel-8-fedramp-High.xml \
    && gocomply_fedramp convert ./rhel-8-fedramp-High.xml FedRAMP-High-rhel8.docx
