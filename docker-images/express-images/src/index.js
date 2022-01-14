var Chance = require('chance');
var chance = new Chance();

var express = require('express');
var app = express();

app.get('/', function(req, res) {
    if(req.query.roll) {
        var json = [];
        json.push({
            query: req.query.roll,
            result: parseRollQuery(req.query.roll)
        });
        //console.log(json);
        res.send(json);
    } else{
        res.send("BAD REQUEST FORMAT");
    }
});

app.listen(81, function() {
    console.log("Dice roller is waiting for requests on port 81");    
});

process.on('SIGINT', function() {
    console.log( "\nGracefully shutting down from SIGINT (Ctrl-C)" );
    process.exit(0);
  });

function parseRollQuery(query) {
    var result = 0;
    var dices = query.split('+');
    for (var i = 0; i < dices.length; i++) {
        //console.log("Param " + i + " " + dices[i]);
        var diceData = dices[i].split('d');
        var nbDices = diceData[0], diceSize = diceData[1];
        //console.log("nbDices " + nbDices + " dice size " + diceSize);
        result += rollDice(nbDices, diceSize);
    }
    return result;
}

function rollDice(nbDices, diceSize) {
    var result = 0;
    nbDices = parseInt(nbDices);
    for(var noDice = 0; noDice < nbDices; noDice++) {
        switch (diceSize) {
            case '4':
                result += chance.d4();
                break;
            case '6':
                result += chance.d6();
                break;
            case '8':
                result += chance.d8();
                break;
            case '10':
                result += chance.d10();
                break;
            case '12':
                result += chance.d12();
                break;
            case '20':
                result += chance.d20();
                break;
            case '30':
                result += chance.d30();
                break;
            case '100':
                result += chance.d100();
                break;
            default:
                break;
        }       
    }
    return result;
}