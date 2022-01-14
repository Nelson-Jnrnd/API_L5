
$( "#roll" ).on( "click", function() {
    function rollDice() {
        console.log("rolling dices...");
        $.getJSON( "/dynamic/diceRoller/?roll=1d6", function(result){
            console.log(result);
            if(result.length > 0){
                $("#result").text("you rolled " + result[0]["query"] + " and the result is -> " + result[0]["result"]);
            }
            
        });
    }
    rollDice();
  });