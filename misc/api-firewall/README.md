# Step 1. Create the docker-compose.yml file
```sh
tee ./docker-compose.yml<< EOF
version: '3'

networks:
  api-network:
    name: api-network

services:
  api-firewall:
    container_name: api-firewall
    image: wallarm/api-firewall:latest
    restart: on-failure
    volumes:
      - <HOST_PATH_TO_SPEC>:<CONTAINER_PATH_TO_SPEC>
    environment:
      APIFW_API_SPECS: <PATH_TO_MOUNTED_SPEC>
      APIFW_URL: <API_FIREWALL_URL>
      APIFW_SERVER_URL: <PROTECTED_APP_URL>
      APIFW_REQUEST_VALIDATION: <REQUEST_VALIDATION_MODE>
      APIFW_RESPONSE_VALIDATION: <RESPONSE_VALIDATION_MODE>
    ports:
      - "8088:8088"
    stop_grace_period: 1s
    networks:
      - api-network
      
  backend:
    container_name: <container_backend_webapp>
    image: <repo/image>
    restart: on-failure
    ports:
      - 8080:8080
    stop_grace_period: 1s
    networks:
      - api-network
EOF
```
# Step 2. Configure the Docker network
https://docs.wallarm.com/api-firewall/installation-guides/docker-container/#step-2-configure-the-docker-network
# Step 3. Configure the application to be protected with API Firewall
https://docs.wallarm.com/api-firewall/installation-guides/docker-container/#step-3-configure-the-application-to-be-protected-with-api-firewall
# Step 4. Configure API Firewall
https://docs.wallarm.com/api-firewall/installation-guides/docker-container/#step-4-configure-api-firewall
# Step 5. Deploy the configured environment
To build and start the configured environment, run the following command:
```sh
docker-compose up -d --force-recreate
```
To check the log output:
```sh
docker-compose logs -f
```
# Step 6. Test API Firewall operation
```
To test API Firewall operation, send the request that does not match the mounted Open API 3.0 specification to the API Firewall Docker container address. 

For example, you can pass the string value in the parameter that requires the integer value.

If the request does not match the provided API schema, the appropriate ERROR message will be added to the API Firewall Docker container logs.
```
Step 7. Enable traffic on API Firewall

To finalize the API Firewall configuration, please enable incoming traffic on API Firewall by updating your application deployment scheme configuration. 

For example, this would require updating the Ingress, NGINX, or load balancer settings.

Using docker run to start API Firewall
To start API Firewall on Docker, you can also use regular Docker commands as in the examples below:

To create a separate Docker network to allow the containerized application and API Firewall communication without manual linking:
```sh
docker network create api-firewall-network
```
To start the containerized application to be protected with API Firewall:
```sh
docker run --rm -it --network api-firewall-network \
    --network-alias backend -p 8090:8090 kennethreitz/httpbin
```       
To start API Firewall:
```sh
docker run --rm -it --network api-firewall-network --network-alias api-firewall \
    -v <HOST_PATH_TO_SPEC>:<CONTAINER_PATH_TO_SPEC> -e APIFW_API_SPECS=<PATH_TO_MOUNTED_SPEC> \
    -e APIFW_URL=<API_FIREWALL_URL> -e APIFW_SERVER_URL=<PROTECTED_APP_URL> \
    -e APIFW_REQUEST_VALIDATION=<REQUEST_VALIDATION_MODE> -e APIFW_RESPONSE_VALIDATION=<RESPONSE_VALIDATION_MODE> \
    -p 8088:8088 wallarm/api-firewall:v0.6.9
```
