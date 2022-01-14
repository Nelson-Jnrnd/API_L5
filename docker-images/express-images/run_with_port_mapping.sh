docker stop api/l5/express-images
docker rm api/l5/express-images
docker build --tag api/l5/express-images .
docker run -p 4242:4242 api/l5/express-images
