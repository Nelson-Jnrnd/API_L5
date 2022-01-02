# Configuration

# The Node App
The node app is a dice roller, it receive a request asking for a specific roll of dices, it will simulate it and return the result.

The dice size handled are : 4, 6, 8, 10, 12, 20, 30 and 100
## Notation
The dice notation the app uses is quite simple, it follows the following syntax : numberOfDices d sizeOfTheDice (without spaces)

Exemple : 3d6
## Request format
The server respond to GET requests. To specify your roll you'll have to send a query string with a parameter roll.

Exemple : /?roll=1d10

If the format is incorrect the app will return an error message

If you want to add multiple dices in one request you will have to use the + sign. But since it has a semantic meaning in the query string it is required to write %2B (hexcode of +).

Exemple : /?roll=2d4%2B3d10%2B1d6