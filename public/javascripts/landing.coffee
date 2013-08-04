###
  Author: Jinhyuk Lee
###

jQuery ->
  $('#myCarousel').carousel()

  $submenu = $('#submenu')
  if $submenu.length
    $submenu.affix {
      offset: {
        top: 480
      }
    }

  $features = $('#features')
  if $features.length
    $('body').scrollspy {
      target: '#submenu'
    }