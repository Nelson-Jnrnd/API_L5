source ../build-all-images.sh
docker run --name reverse --rm -d -p 80:80 -p 4242:4242 api/l5/apache-reverse-proxy
docker run --name static --rm -d api/l5/static-http-server
docker run --name dynamic --rm -d api/l5/dynamic-http-server