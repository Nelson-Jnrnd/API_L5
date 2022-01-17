docker build -t api/l5/static-http-server docker-images/ajax-jquery-images
docker build -t api/l5/dynamic-http-server docker-images/express-images
docker build -t api/l5/traefik docker-images/traefik
docker build -t api/l5/portainer docker-images/portainer

docker swarm init
docker stack deploy --compose-file docker-images/docker-compose.yml apil5stack

read -p "Press enter to stop the HTTP infrastructure"

docker swarm leave --force