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

  # 4 spaces
  hljs.tabReplace = '  '
  $('pre code, code').each (i, e) -> 
    hljs.highlightBlock(e)

  landingViewModel = () ->
    self = this
    self.username = ''
    self.email = ''
    self.password = ''
    self.signupButton = ko.observable _('signup.button')
    self.signup = (elem) ->
      _.Users.signup().ajax 
        data:
          username: self.username,
          email: self.email,
          password: self.password
        success: (d, s, x) ->
          if x.status is 201
            self.signupButton _('signup.button.done')
            Messenger().post {
              message: _ 'signup.done.redirect'
              type: 'success'
            }

            setTimeout () ->
              location.href = _.Application.signin().url
            , 1000
          else
            Messenger().post {
              message: _ d
              type: 'error'
            }
            
        error: (x, s, r) ->
          Messenger().post {
            message: _ r
            type: 'error'
            showCloseButton: true
          }
      false

    true
  ko.applyBindings new landingViewModel()
  true