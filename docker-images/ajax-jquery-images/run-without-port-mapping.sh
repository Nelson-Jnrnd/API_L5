docker stop api/l5/apache-php-image
docker rm api/l5/apache-php-image
docker build --tag api/l5/apache-php-image .
docker run api/l5/apache-php-image