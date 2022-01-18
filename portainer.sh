docker rm -f portainer
docker build --tag api/l5/portainer docker-images/portainer
docker run -d -p 9000:9000 --name portainer --rm -v /var/run/docker.sock:/var/run/docker.sock api/l5/portainer
sleep 3
xdg-open http://localhost:9000/