# Step 1: Static HTTP server with apache httpd

## Dockerfile
For our php webserver we've decided to use [the official php docker image](https://hub.docker.com/_/php).
As such, we specify the image with the FROM instruction :
```docker
FROM php:7.2-apache
```
We have created a source folder for the files of our site. The COPY instruction allows us to copy those files in the root of our server within the docker-image's filesystem.
```docker
COPY src/ /var/www/html
```
At this point if we try to contact our webserver we are met with a forbidden error message. To fix this issue, we execute the chmod command on the files to give read and execution rights to all the users.

Also, we're setting the working directory to our root directory in case of future docker commands.
```docker
WORKDIR /var/www/html
RUN chmod -R 555 ./*
```
## Apache Configuration
