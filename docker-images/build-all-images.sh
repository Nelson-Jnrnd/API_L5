docker build -t api/l5/static-http-server ${BASH_SOURCE%/*}/ajax-jquery-images
docker build -t api/l5/dynamic-http-server ${BASH_SOURCE%/*}/express-images
docker build -t api/l5/apache-reverse-proxy ${BASH_SOURCE%/*}/apache-reverse-proxy
docker build -t api/l5/traefik ${BASH_SOURCE%/*}/traefik
docker build -t api/l5/portainer ${BASH_SOURCE%/*}/portainer