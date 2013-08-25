###
Jinhyuk Lee at mintpresso.com
###

# extends String endsWith, startsWith
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

    self.data =
      usage: ko.observable()
      plansAndBilling: ko.observable()
      apiKey: ko.observable()

    self.menu = ko.observable()
    self._page = ko.observable()
    self.page = ko.computed {
      read: () ->
        return this._page()

      write: (value) ->
        # do nothing if page isn't change, let's use non-self referring value '_page()'
        if self._page() isnt value
          # update
          self._page value
          # ignore when pointing none page like '/account'
          if value.length > 0
            # change push state
            History.pushState {timestamp: moment().seconds() }, _('title.' + self.menu() + '.' + self._page() ), '/' + _.url + '/' + self.menu() + '/' + self._page()
        true
      owner: self
    }
    
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
            location.href = _.Pages.account(d, "").url
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

    # apply url to view model, returns hasPropagation
    self.applyUrl = () ->
      parts = location.pathname.split '/'
      self.menu parts[2] if parts.length > 2
      if parts.length > 3
        self.page parts[3]
      else
        self._page ''
        false

    self.applyUrl()

    # bind push state changes
    History.Adapter.bind window, 'statechange', (e) ->
      state = History.getState();

      # not triggered by page.write, should be from history.back
      if state.data.timestamp isnt moment().seconds()
        if self.applyUrl() is false
          return false

      route = $.camelCase( self.menu() + '-' + self.page() )

      # check the page
      if route of _.Pages
        _.Pages[ route ](_.url).ajax
          success: (d, s, x) ->
            if x.status isnt 200
              Messenger().post {
                message: _ d
                type: 'error'
                showCloseButton: true
              }
            else
              self.data[ $.camelCase(self.page()) ](d)
          error: (x, s, r) ->
            msg = Messenger().post {
              message: r
              type: 'error'
              showCloseButton: true
              actions:
                retry:
                  label: 'Retry Now'
                  action: ->
                    location.reload()
                # cancel:
                #   action: ->
                #     do msg.cancel
            }
      else
        Messenger().post {
          message: _ 'page.empty'
          type: 'error'
          showCloseButton: true
        }
      true

    $(window).trigger('statechange')
    true
  ko.applyBindings new pagesViewModel()  
  true
