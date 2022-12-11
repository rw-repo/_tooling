
subjectAltName to x509 cert

```sh
mkdir certs && cd certs

# generate CA, server certificate and key

openssl genrsa -out gitlab-ca.key 2048 

openssl req -new -x509 -days 365 -key gitlab-ca.key \
-subj "/C=USA/ST=CO/L=Mars/O=Testing/CN=GitLab Root CA" -out gitlab-ca.crt

openssl req -newkey rsa:2048 -nodes -keyout gitlab.testing.io.key \
-subj "/C=USA/ST=CO/L=Mars/O=Testing/CN=*.gitlab.testing.io" -out gitlab.testing.io.csr

openssl x509 -req -extfile <(printf "subjectAltName=DNS:gitlab.testing.io,DNS:www.gitlab.testing.io") \
-days 365 -in gitlab.testing.io.csr -CA gitlab-ca.crt -CAkey gitlab-ca.key -CAcreateserial \
-out gitlab.testing.io.crt

```
