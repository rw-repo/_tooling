## FedRAMP System Security Plan template

This will fill some of the data as a launching point for the SSP draft.

XML's located here:  https://github.com/ComplianceAsCode/oscal/tree/master/xml

Modify XML with control response and load in container to generate the document in docx format.

```sh
podman build -t oscal .
podman run --rm -it --name oscal -d oscal
podman cp oscal:FedRAMP-High-rhel8.docx ./
```

```console
Replace Dockerfile with any of the following:

OSCAL formatted SSPs (System Security Plans)

ansible-tower-fedramp-High.xml
ansible-tower-fedramp-Low.xml
ansible-tower-fedramp-Moderate.xml
coreos-4-fedramp-High.xml
coreos-4-fedramp-Low.xml
coreos-4-fedramp-Moderate.xml
identity-management-fedramp-High.xml
identity-management-fedramp-Low.xml
identity-management-fedramp-Moderate.xml
openshift-container-platform-3-fedramp-High.xml
openshift-container-platform-3-fedramp-Low.xml
openshift-container-platform-3-fedramp-Moderate.xml
openshift-container-platform-4-fedramp-High.xml
openshift-container-platform-4-fedramp-Low.xml
openshift-container-platform-4-fedramp-Moderate.xml
openshift-dedicated-fedramp-High.xml
openshift-dedicated-fedramp-Low.xml
openshift-dedicated-fedramp-Moderate.xml
openstack-platform-13-fedramp-High.xml
openstack-platform-13-fedramp-Low.xml
openstack-platform-13-fedramp-Moderate.xml
rhacm-fedramp-High.xml
rhacm-fedramp-Low.xml
rhacm-fedramp-Moderate.xml
rhel-7-fedramp-High.xml
rhel-7-fedramp-Low.xml
rhel-7-fedramp-Moderate.xml
rhel-8-fedramp-High.xml
rhel-8-fedramp-Low.xml
rhel-8-fedramp-Moderate.xml
virtualization-host-fedramp-High.xml
virtualization-host-fedramp-Low.xml
virtualization-host-fedramp-Moderate.xml
virtualization-manager-fedramp-High.xml
virtualization-manager-fedramp-Low.xml
virtualization-manager-fedramp-Moderate.xml
```
