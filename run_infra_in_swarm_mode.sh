source docker-images/build-all-images.sh

docker swarm init
docker stack deploy --compose-file docker-compose.yml apil5stack

read -p "Press enter to stop the HTTP infrastructure"

docker swarm leave --force