$(document).bind('mousemove', function(e){
    $('.tail').css({
       left:  e.pageX + 20,
       top:   e.pageY
    });
});

var myTail = document.getElementsByClassName("tail")[0]



var pieces = document.getElementsByClassName("piece");
for (var i = 0, len = pieces.length; i < len; i++) {
  pieces[i].addEventListener("click", function(event) {
    if (myTail.innerHTML === "") {
      change_class(event.currentTarget, myTail)
      console.log(event.currentTarget.className)
      myTail.innerHTML = event.currentTarget.innerHTML;
      event.currentTarget.innerHTML = ""; } else {
        change_class(myTail, event.currentTarget)
        event.currentTarget.innerHTML = myTail.innerHTML;
        myTail.innerHTML = "";
    }
  }, false);
}



function change_class(current, target){
    if ($(current).hasClass('black')){
      $(target).addClass('black');
      $(target).removeClass('white');
    }
    if ($(current).hasClass('white')) {
      $(target).addClass('white');
      $(target).removeClass('black');
    }
} 