source docker-images/build-all-images.sh
docker-compose up --scale static-http=3 --scale dynamic-http=3