# Step 1: Static HTTP server with apache httpd

## Content
Our server displays a nice looking web page thanks to a bootsrap template that we slightly modified.

## Dockerfile
For our php webserver we've decided to use [the official php docker image](https://hub.docker.com/_/php).
As such, we specify the image with the FROM instruction :
```docker
FROM php:7.2-apache
```
We're setting the working directory to our root directory. This way, we don't need to specify the directory in future docker instructions
```docker
WORKDIR /var/www/html
```

We have created a source folder for the files of our site. The COPY instruction allows us to copy those files in the root of our server within the docker-image's filesystem.
```docker
COPY src/ .
```
At this point if we try to contact our webserver we are met with a forbidden error message. To fix this issue, we execute the chmod command on the files to give read and execution rights to all the users.
```docker
RUN chmod -R 555 ./*
```
## Apache Configuration
The apache configuration file can be found in the container at /etc/apache2, and the main configuration file is apache2.conf

For this step we did not need to do any changes to the base configuration given in this docker image.

# Step 2: Dynamic HTTP server with express.js

## Configuration

### Dockerfile
For this step we've decided to use [the official node docker image](https://hub.docker.com/_/node).
As such, we specify the image with the FROM instruction :
```docker
FROM node:current
```
We're setting the working directory to our root directory. This way, we don't need to specify the directory in future docker instructions
```docker
WORKDIR /opt/app
```

We have created a source folder for the files of our server. The COPY instruction allows us to copy those files in the root of our server within the docker-image's filesystem.
```docker
COPY src/ .
```

We then have to install the dependencies of our application. They are contained in the package.json created by npm. To do this we are using the npm install command.
```docker
RUN npm install
```

And finally, we run our application.
```docker
CMD ["node", "index.js"]
```

### Run script
We once again have a run.sh script to launch our container, it's the same as step one except this time we are using the port 81.

## The Node App
The node app is a dice roller, it receive a request asking for a specific roll of dices, it will simulate it and return the result.

The dice size handled are : 4, 6, 8, 10, 12, 20, 30 and 100
### Notation
The dice notation the app uses is quite simple, it follows the following syntax : numberOfDices d sizeOfTheDice (without spaces)

Exemple : 3d6
### Request format
The server respond to GET requests. To specify your roll you'll have to send a query string with a parameter roll.

Exemple : /?roll=1d10

If the format is incorrect the app will return an error message

If you want to add multiple dices in one request you will have to use the + sign. But since it has a semantic meaning in the query string it is required to write %2B (hexcode of +).

Exemple : /?roll=2d4%2B3d10%2B1d6

### Exiting the server
Contrary to the webserver in step 1, Ctrl+C didn't kill the server at first, to implement this behavior we had to handle the SIGINT signal ourselves in the .js script.
```js
process.on('SIGINT', function() {
    console.log( "\nGracefully shutting down from SIGINT (Ctrl-C)" );
    process.exit(0);
  });
```

# Step 3: Reverse proxy with apache (static configuration)

The goal is to add a reverse proxy as the entry point of our infra. All files created for this step are in `docker-images/apache-reverse-proxy`

We use the docker image `php:8.1-apache`.

## Reverse proxy configuration

Two configuration files are givent to apache : `000-default.conf` and `001-reverse-proxy.conf`.

`000-default.conf` defines a default empty site that is used when the received request does not have a `host: l5.api.ch` header.

`001-reverse-proxy.conf` is used when the request does have a `host: l5.api.ch` header. This file decribes the reverse proxy rules : redirect requests for `/dynamic/diceRoller/` to `http://172.17.0.4:4242/` and redirect other requests to `http://172.17.0.3:80/`. Note that the order of the configurations is important : as the second rule is more generic it must be the last one, because otherwise it would cath all requests.

## Dockerfile

We copy our configuration files inside the image with

```
COPY conf/ /etc/apache2
```

and then we enable the proxy modules and apply our configuration files with

```
RUN a2enmod proxy proxy_http
RuN a2ensite 000-* 001-*
```

## Running the infrastructure

The reverse proxy is the single entry point of our infra and has port 80 mapped to the host. For this to work, the ip address of the static HTTP server must be 172.17.0.3 and the ip address of the dynamic HTTP server must be 172.17.0.4. It is usually the case when we run first the reverse proxy, then the static server and then the dynamic server. There is no guarantee that this will always be the case, though. This means our infrastructure is fragile.

The infra can be run by building the images and then running

 ```
docker run --name reverse --rm -d -p 80:80 -p 4242:4242 api/l5/apache-reverse-proxy
docker run --name static --rm -d api/l5/static-http-server
docker run --name dynamic --rm -d api/l5/dynamic-http-server
 ```

 Only the reverse proxy has a port mapped to the host, the two HTTP servers are not directly accessible.

 As the reverse-proxy only forwards requests with a `host: l5.api.ch` header, in order to access the web page from a browser you need to edit your `etc/hosts` config file and add the following line : `127.0.0.1   l5.api.ch`. 

# Step 4: AJAX requests with JQuery

# Step 5 and additional steps 1 and 3: dynamic reverse proxy with automatic node detection and round-robin load balancing

Thanks to this step, the reverse proxy now automatically detects when new HTTP servers appear and disappear from the infrastructure, and distributes requests between the running servers.

## Traefik proxy

Our infrastructure now uses Docker compose with a Traefik container as reverse proxy.

### Main traefik concepts

Traefik observes the infrastructure using the Docker API. The configuration of Traefik is dynamically influenced by the start and stop of containers, and by the `labels` associated to them. A label is a key-value pair associated to docker images and containers. We define labels for our images in the `docker-compose.yml` file.

Some of the key concepts of Traefik are the following :
* Traefik associates a `router` to each image of the docker-compose file. A router determines which HTTP requests it will catch.
* Traefik associates a `service` to each image of the docker-compose file. A service has a load balancer that distributes requests to the containers instancied by the image. The load balancer knows when new instances of the image are started and when running containers are stoped. By default, round-robin load balancing is done.
* A router can optionnaly refer to a `middleware` that transforms requests before they are sent to the service and transforms responses that come frome the service.

### Traefik Dockerfile

We add tcpdump to the Traefik image :

```
RUN apk add tcpdump
```
and we ask Traefik to get its dynamic configuation from Docker :
```
CMD ["--providers.docker"]
```

### Docker-compose file and Traefik configuration

The infrastructure is described in the file `docker-compose.yml`

#### Reverse proxy

The Traefik instance has port 80 mapped to the host. It is the only entry point of the infrastructure.

The file `/var/run/docker.sock` of the host gives access to the Docker API. It is mapped inside the container file system, which allows Traefik to access this API.

#### Static HTTP server

The static http server image has the following label :

```
- "traefik.http.routers.static-http.rule=Host(`l5.api.ch`)"
```
This makes the routeur of the static HTTP server catch requests for `l5.api.ch`.

#### Dynamic HTTP server

The dynamic http server image has the following labels :

```
- "traefik.http.routers.dynamic-http.rule=Host(`l5.api.ch`) && Path(`/dynamic/diceRoller/`)"
```
This makes the router of the dynamic HTTP server catch requests for `l5.api.ch/dynamic/diceRoller/`. Requests are tested against router rules in decreasing rule length, and consequently this rule will catch requests before the static http server router. All requets for `l5.api.ch` that don't have the specific path `/dynamic/diceRoller/` will go to the static router.

```
- "traefik.http.middlewares.diceRoller.stripprefix.prefixes=/dynamic/diceRoller"
- "traefik.http.routers.dynamic-http.middlewares=diceRoller"
```
This makes the router apply a middleware that will transform the path of the requests from `/dynamic/diceRoller/` to `/`.

## Running the infrastructure

Run the following command while being at the root of the project to run the infrastructure (with X and Y replaced by the desired static and dynamic HTTP servers instances numbers) :

```
docker-compose up -d --scale static-http=<X> --scale dynamic-http=<Y>
```

Running the command again with different numbers makes docker start and stop the appropriate number of containers to match the requested server counts. Traefik load balancers automatically detect the change.

Run the following command to stop the infrastructure :

```
docker-compose down
```

# Additional step 2 : Sticky session load balancing for the static HTTP server

Thanks to this step, the load balancing for the static HTTP servers uses sticky session, which means that subsequent requests of a client are sent to the server that received its first request.

This is done by adding this label to the static HTTP server in the docker-compose file :
```
- "traefik.http.services.static-http.loadBalancer.sticky.cookie.name=apil5-sticky"
```
This configures the load-balancer of the service associated with the static HTTP server image to use sticky-session with a cookie named `apil5-sticky`. The first time the load-balancer receives a request from a client, it will include a `set-cookie` header with an id. When the client sends new requests, the load-balancer uses this id to send them to the same server.

# Validation procedure for additional steps 1,2,3

Follow the following procedures to control that the load-balancing works correctly :

## Round-robin load-balancing

Run the infrastructure using 

```
docker-compose up -d --scale static-http=5 --scale dynamic-http=5
```

Run tcpdump in the reverse-proxy container to display packages going to dynamic HTTP servers instances (dynamic HTTP servers listen on port 4242)
```
docker exec -it api_l5_reverse-proxy_1 tcpdump -i eth0 -n -q dst port 80
```
In a web browser, access [http://l5.api.ch/](http://l5.api.ch/) and click the Roll a dice button several times to trigger requests to the dynamic server. If the load-balancing works correctly, the reverse-proxy should send each request to a different server.

## Sticky session load balancing

Follow the same procedure as above, but this time inspects packages going to port 80 :
```
docker exec -it api_l5_reverse-proxy_1 tcpdump -i eth0 -n -q dst port 4242
```

Then in your web browser refresh (`CTRL` `F5`) several times the web page at [http://l5.api.ch/](http://l5.api.ch/). If the load-balancing works correctly, the reverse-proxy should send each request to the same server and your browser should store a cookie named `apil5-sticky`. If you remove the cookie from your browser and reload the page, the request should be sent to a different server.

## Live scaling

The goal is to verify that the reverse-proxy correctly detects new servers and removed servers.

Run the infrastructure with only one instance of each server using 

```
docker-compose up -d
```

Then add new servers :

```
docker-compose up -d --scale static-http=5 --scale dynamic-http=5
```

Using the same commands as above, display packages going to dynamic HTTP servers instances on ports 80 or 4242

In your browser, refresh several time the webpage after having deleted the cookie, and click several time the Roll a dice button. Requests should be sent to several different servers, which proves that the load-balancers use the new servers.

Then run again

```
docker-compose up -d
```

to have only one instance of each server. Reload the webpage and click the Roll a dice button. There should be no error, which proves that the load-balancers only forward requests the remaining servers.

# Additional step 4 : Management UI

For this step, we use Portainer and we run our infra using Docker Swarm mode.

## Portainer

Portainer provides a management GUI for docker. It is itself run in a docker container that provides a web app.

### Dockerfile

The files related to our portainer image are located in `docker-images/portainer`. The admin password for the web app is defined in `api-config/password`.

The Dockerfile contains :

```
COPY api-config api-config
```
To copy the password configuration file inside the image file system and

```
CMD ["--admin-password-file", "api-config/password"]
```

To make Portainer use this file.

### Run script

The script `portainer.sh` at the root of the projects builds the Portainer image, opens a browser to access the web app and runs an instance of the image. The run command is :

```
docker run -p 9000:9000 --name portainer --rm -v /var/run/docker.sock:/var/run/docker.sock api/l5/portainer
```
This maps the port used to access the web application, and mounts `/var/run/docker.sock` inside the file system of the container to allow portainer to use the docker API of the host.

To have a nice management page in Portainer where we can see the two HTTP server images and set the number of instances that we want for each, we need to run the infrastructure with docker swarm mode.

## Docker swarm

### Modification of the docker-compose file

Swarm mode uses the docker-compose file but allows additional functionalities. In swarm mode, we can set the default number of instances of an image directly in the docker-compose file by adding
```
deploy:
      replicas: 2
```

to each HTTP server entry.

For a reason that we don't understand, when running the infra in swarm mode it seems that Traefik fails to detect that the different dynamic HTTP server instances come from the same image. Consequently, it creates a service for each server instance, instead of creating one service and load-balancing it on the instanes.

Adding this label to the dynamic HTTP server in the docker-compose file fixes the problem :

```
- "traefik.http.services.dynamic-http.loadBalancer.sticky.cookie=false"
```

Although this setting is the default value, for some reason adding this line makes Traefik create one service for all the dynamic server instances, which is what we want.

### Run script

The script `run_infra_in_swarm_mode.sh` enables swarm mode and runs the infrastructure using the docker-compose file. It then exits swarm mode when the infrastructure is stopped.

### Portainer with swarm mode

To test our final version of the infrastructure, run the script `run_infra_in_swarm_mode.sh` to run the infrastructure, and then run `portainer.sh` in an other terminal to run portainer.
In the browser, enter `admin` as username and `api` as password. Then click `Get started` and select the `local` environment. On the left panel click `Stacks` and `apil5stack`.
Here you can see each image of the infrastructure and define a new number of instances for each of them.

