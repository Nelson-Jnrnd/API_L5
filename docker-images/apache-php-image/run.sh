docker stop httpserver
docker rm httpserver
docker build --tag apil5/httpserver .
docker run --name httpserver -p 4242:80 apil5/httpserver