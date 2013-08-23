###
  Author: Jinhyuk Lee
###

if String.prototype.format is undefined
  String.prototype.format = () ->
    _arguments = arguments
    this.replace /{(\d+)}/g, (match, number) ->
      if typeof _arguments[number] isnt 'undefined' then _arguments[number] else match

String.prototype.endsWith = (suffix) ->
  return (this.substr(this.length - suffix.length) is suffix)

String.prototype.startsWith = (prefix) ->
  return (this.substr(0, prefix.length) is prefix)

jQuery ->
  $('input, textarea').placeholder()

  $.extend {
    getParameters: () ->
      vars = []
      if window.location.hash.indexOf('?') is -1
        return []
      for hash in window.location.hash.slice(window.location.hash.indexOf('?') + 1).split('&')
        continue if hash.length is 0
        kv = hash.split('=')
        vars.push kv[0]
        vars[kv[0]] = kv[1]
      return vars
    getParameter: (name) ->
      temp = $.getParameters()[name]
      if temp is undefined
        ""
      else
        temp

    getParameterHash: () ->
      if window.location.hash.indexOf('?') == -1 
        return ""
      else
        window.location.hash.slice(window.location.hash.indexOf('?'))

    setParameter: (key, value) ->
      if $.getParameter(key) is undefined
        if window.location.hash.indexOf('?') is -1
          window.location.hash += "?"
        window.location.hash += key + '=' + value + '&'
      else
        params = $.getParameters
        temp = "?"
        for p in params
          temp += p + '=' + params[p] + '&'
        temp += key + '=' + value + '&'
        window.location.hash = window.location.hash.slice(0, window.location.hash.indexOf('?')) + temp
      $('#submenu li.active').data('parameter', $.getParameterHash())
  }

  $body = $('body')

  event =
    afterLoad: () ->
      logo = $('#animation-mask #logo')
      html = $('html')
      support = html.is('.csstransitions') && html.is('.opacity')
      if _.doneLoading is true
        if _.waitForLoading is true
          if logo.is(':hidden')
            logo.fadeIn 1000, 'easeInQuint', (e) ->
              event.afterLoad()
          else
            setTimeout event.afterLoad, 500
        else
          logo.hide()
          if support
            $('#single-page div.modal').css {marginTop: '15.5px', opacity: 1.0}
            $('#animation-mask').hide()
            $('footer').parent().show()
          else
            $('#single-page div.modal').animate {marginTop: '15.5px'}, 1000, 'easeOutQuint'
            $('#animation-mask').fadeOut {
              duration: 1000
              easing: 'easeInQuint'
            }
      else
        if logo.is(':hidden')
          logo.fadeIn 1000, 'easeInQuint', (e) ->
            event.afterLoad()
        else
          setTimeout event.afterLoad, 500
      true

  _.waitForLoading = false if _.waitForLoading is undefined
  _.doneLoading = false if _.doneLoading is undefined
  _.loadingInterval = 60 * 3

  $meta = $('meta[name=animation]')
  if $meta.length > 0 and $meta isnt undefined
    content = $meta[0].getAttribute('content')
    if content is "fadein"
      $('#single-page').show()
      $(window).load (e) ->
        _.doneLoading = true
        event.afterLoad()

  pagesViewModel = () ->
    self = this

    self.menu = ko.observable()
    self.content = ko.observable()
    self._page = ''
    self.page = ko.computed {
      read: () ->
        return self._page

      write: (value) ->
        if self._page isnt value
          # update
          self._page =  value
          # change push state
          History.pushState {}, _('title.' + self.menu() + '.' + self._page ), '/' + _.url + '/' + self.menu() + '/' + self._page
        true
      owner: self
    }

    # self.setPage = (value) ->
    #   if self._page isnt value
    #     # update
    #     self._page =  value
    #     # change push state
    #     console.log 'pushState', value
    #     # History.pushState {}, _('title.' + self.menu() + '.' + self.page() ), _.url + '/' + self.page()
    #   true
    
    self.username = ''
    self.email = ''
    self.password = ''

    self.signinButton = ko.observable _ 'signin'
    
    self.signin = (elem) ->
      self.signinButton _ 'signin.progress'
      _.Users.signin().ajax
        data:
          email: self.email
          password: self.password
        success: (d, s, x) ->
          if x.status is 202
            location.href = _.Pages.account(d).url
          else
            Messenger().post {
              message: _ d
              type: 'error'
              showCloseButton: true
            }
            self.signinButton _ 'signin'
        error: (x, s, r) ->
          Messenger().post {
            message: _ r
            type: 'error'
            showCloseButton: true
          }
          self.signinButton _ 'signin'
      false

    # apply url to view model
    parts = location.pathname.split '/'
    self.menu parts[2] if parts.length > 2
    self.page parts[3] if parts.length > 3

    # bind push state changes
    History.Adapter.bind window, 'statechange', () ->
      # state = History.getState();

      # check the page
      if self.page() in _.Pages
        console.log self.menu() + '_' + self.page() 
        _.Pages[ self.menu() + '_' + self.page() ](_.url).ajax
          success: (d, s, x) ->
            if x.status isnt 200
              Messenger().post {
                message: _ d
                type: 'error'
                showCloseButton: true
              }
              console.log 'Go Back'
            else
              self.content(d)
      else
        Messenger().post {
          message: _ 'page.empty'
          type: 'error'
          showCloseButton: true
        }
      true
    true
  ko.applyBindings new pagesViewModel()  
  true
