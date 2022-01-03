docker stop api/l5/apache-php-image
docker rm api/l5/apache-php-image
docker build --tag api/l5/apache-php-image .
docker run -p 80:80 api/l5/apache-php-image
