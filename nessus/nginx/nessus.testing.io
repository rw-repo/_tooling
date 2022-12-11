server {
  listen 80;
  listen [::]:80;
  server_name nessus.testing.io www.nessus.testing.io;
  return 301 https://$server_name$request_uri;
}
server {
  listen 443 ssl;
  listen [::]:443 ssl;
  include snippets/ssl-params.conf;
  client_max_body_size 20M;
  server_name nessus.testing.io;
  ssl_certificate /etc/ssl/certs/nessus.testing.io.crt;
  ssl_certificate_key /etc/ssl/private/nessus.testing.io.key;
  access_log /var/log/nginx/nessus.access.log;
  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-SSL on;
    proxy_set_header X-Forwarded-Host $host;
    proxy_pass https://nessus.testing.io:8834;
    proxy_max_temp_file_size 0;
    proxy_connect_timeout 30;
    proxy_send_timeout 15;
    proxy_read_timeout 15;
  }
}
