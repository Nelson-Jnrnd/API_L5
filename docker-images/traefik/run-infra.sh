source ../build-all-images.sh
docker run --name traefik --rm -d -p 80:80 -v $PWD/config:/etc/traefik traefik
docker run --name static --rm -d api/l5/static-http-server
docker run --name dynamic --rm -d api/l5/dynamic-http-server