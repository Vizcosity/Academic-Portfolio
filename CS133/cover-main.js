// Resolve the random unsplash url, then append it to the page background.


$(document).ready(function(){

  $.ajax({
   type: "GET",
   url: "https://source.unsplash.com/random/1600x900"
 }, function callback(data){
   console.log(data);
   console.log(dataType);
   console.log(success);
 });


})
