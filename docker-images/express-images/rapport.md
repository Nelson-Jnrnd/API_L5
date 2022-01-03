# Step 2: Dynamic HTTP server with express.js

## Configuration

### Dockerfile
For this step we've decided to use [the official node docker image](https://hub.docker.com/_/node).
As such, we specify the image with the FROM instruction :
```docker
FROM node:current
```
We're setting the working directory to our root directory. This way, we don't need to specify the directory in future docker instructions
```docker
WORKDIR /opt/app
```

We have created a source folder for the files of our server. The COPY instruction allows us to copy those files in the root of our server within the docker-image's filesystem.
```docker
COPY src/ .
```

We then have to install the dependencies of our application. They are contained in the package.json created by npm. To do this we are using the npm install command.
```docker
RUN npm install
```

And finally, we run our application.
```docker
CMD ["node", "index.js"]
```

### Run script
We once again have a run.sh script to launch our container, it's the same as step one except this time we are using the port 81.

## The Node App
The node app is a dice roller, it receive a request asking for a specific roll of dices, it will simulate it and return the result.

The dice size handled are : 4, 6, 8, 10, 12, 20, 30 and 100
### Notation
The dice notation the app uses is quite simple, it follows the following syntax : numberOfDices d sizeOfTheDice (without spaces)

Exemple : 3d6
### Request format
The server respond to GET requests. To specify your roll you'll have to send a query string with a parameter roll.

Exemple : /?roll=1d10

If the format is incorrect the app will return an error message

If you want to add multiple dices in one request you will have to use the + sign. But since it has a semantic meaning in the query string it is required to write %2B (hexcode of +).

Exemple : /?roll=2d4%2B3d10%2B1d6