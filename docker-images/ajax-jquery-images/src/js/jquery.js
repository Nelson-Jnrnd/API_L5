
$( "#roll" ).on( "click", function() {
    console.log("rolling dices...");
    $.getJSON( "/dynamic/diceRoller/?roll=100d6", function(result){
        console.log(result);
        if(result.length > 0){
            $("#result").text("you rolled " + result[0]["query"] + " and the result is -> " + result[0]["result"]);
        }
    });
  });
