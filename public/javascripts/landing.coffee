###
  Author: Jinhyuk Lee
###

jQuery ->
  $('#myCarousel').carousel()

  $toc = $('#toc')
  if $toc.length
    $toc.affix {
      offset: {
        top: 79
      }
    }

  $features = $('#features')
  if $features.length
    $('body').scrollspy {
      target: '#toc'
    }