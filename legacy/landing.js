$(document).ready(function(){

  // On click lift the white lower half and fade out content.
  $('button').click(function(){

    // Once clicked, the .lower and .upper mouseover events need to be unbounded in order
    // to remove interference of the animation that would have caused it to jump.
    $('.upper').unbind('mouseover');
    $('.lower').unbind('mouseover');

    // Fade out items.
    $('.name').fadeOut();
    $('.section').fadeOut();
    $(this).fadeOut(function(){
      // After fadeout, scaleup the lower white section.
      $(".lower").css('transform', 'scaleY(3)');
      $(".lower").one('transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd',function(){
        // Once the animation has finished, redirect to the next index page.
        window.location.href = "./CS133/index.html"
      });
    });
  });

  // On image mouseover show information about source.

    // Show on mouseover image
    $('.upper').mouseover(function(){
      $('.lower').css('transform','translateY(+30px)');
    });

    // Hide on mouseover white area
    $('.lower').mouseover(function(){
      $('.lower').css('transform','translateY(0)');
    });

});
