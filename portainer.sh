docker build --tag api/l5/portainer docker-images/portainer
xdg-open http://localhost:9000/
docker run -p 9000:9000 --name portainer --rm -v /var/run/docker.sock:/var/run/docker.sock api/l5/portainer