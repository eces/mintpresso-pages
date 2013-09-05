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

String.prototype.capitalize = (lower) ->
  if lower
    this.toLowerCase()
  else
    this.replace /(?:^|\s)\S/g, (a) ->
      return a.toUpperCase()

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
            parameter = ''
            if self.id() isnt undefined and String(self.id()).length > 0
              parameter = '/' + self.id()
            # change push state
            History.pushState {timestamp: moment().seconds() }, _('title.' + self.menu() + '.' + $.camelCase(self._page()) ), '/' + _.url + '/' + self.menu() + '/' + self._page() + parameter
        true
      owner: self
    }
    self.id = ko.observable ''

    self.username = ''
    self.email = ''
    self.password = ''

    self.signinButton = ko.observable _ 'signin'
    self.applyButton = ko.observable _ 'apply.change'
    
    self.findPassword = ->
      if self.email.length
        location.href = _.Users.findPassword(self.email).url
      else
        Messenger().post {
          message: _ 'form.empty.email'
          type: 'info'
        }
      false

    self.signin = (elem) ->
      self.signinButton _ 'signin.progress'
      _.Users.signin().ajax
        data:
          email: self.email
          password: self.password
        success: (d, s, x) ->
          if x.status is 202
            location.href = _.Pages.account(d, "").url
          else if x.status is 201
            Messenger().post {
              message: _ d
              type: 'info'
              showCloseButton: true
            }
            self.signinButton _ 'signin'
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

    self.search =
      data: ko.observable()
      dataType: ko.observable('')
      responseTime: ko.observable('0')
      itemString: ko.observable('0 item')
      apikey: ko.observable('')
      queries: ko.observable('')
      secretKey: ''
      template: ->
        if self.search.dataType() is 'model'
          'model-template'
        else if self.search.dataType() is 'status'
          'status-template'
        # if data.type is 'model'
        #   if data.length is 0 or 1
        #     'model-template'
        #   else
        #     'models-template'
        # else if data.type is 'model'
        #   if data.length is 0 or 1
        #     'status-template'
        #   else
        #     'status-template'
        else
          ''
      refresh: ->
        self.search.query self.search.queries()
      revert: ->
        self.search.queries ''
        self.search.data.removeAll()
      afterRender: ->
        self.search.secretKey = $('#secretKey').html()
        if self.search.secretKey.length is 0
          Messenger().post { message: _ 'secret.key.empty', type: 'error' }
        $('input[name=q]').focus()
        Prism.highlightElement $('#search table pre'), true
          

    self.search.query = (callback) ->
      parts = []
      if self.search.queries().length
        parts = self.search.queries().split(' ')
      
      switch parts.length
        when 0
          Messenger().post { message: _ 'query.empty', type: 'error', showCloseButton: true }
        when 1
          # Messenger().post { message: _ 'query.empty.2', type: 'error', showCloseButton: true }
          self.search.queries( parts[0] + ' {}')
          self.search.query()
        when 2
          if Number(parts[0]).toString() isnt 'NaN'
            Messenger().post { message: _ 'query.sType.invalid', type: 'error' }
            return false
          
          json = null
          try
            temp = JSON.parse(parts[1])
            if toString.call(temp) is '[object Object]'
              json = temp
          catch e
            # slient

          _.responseTime = Date.now()
          self.search.data []
          self.search.dataType 'model'

          if json is null
            url = _.server + "/#{parts[0]}/#{parts[1]}?apikey=#{self.search.secretKey}&json=#{encodeURIComponent(JSON.stringify(json))}"
          else
            url = _.server + "/#{parts[0]}?apikey=#{self.search.secretKey}&json=#{encodeURIComponent(JSON.stringify(json))}"
          
          $.ajax {
            url: url
            type: 'GET'
            async: true
            cache: false
            crossDomain: true
            dataType: 'jsonp'
            jsonpCallback: '_' + Date.now(),
            success: (d, s, x) ->
              self.search.responseTime( Date.now() - _.responseTime )
              if x.status is 200 and d.status isnt 404
                res = toString.call(d)
                if res is '[object Array]'
                  len = d.length
                  self.search.itemString "#{len} items"
                  for key of d
                    d[key].$type = parts[0]
                  self.search.data d
                else if res is '[object Object]'
                  self.search.itemString '1 item'
                  t = Object.keys(d)[0]
                  d[t].$type = parts[0]
                  self.search.data [d[t]]
                else
                  Messenger().post { message: _ 'query.response.invalid', type: 'error' }
              else
                if d.status isnt undefined
                  self.search.itemString "(#{_('response.'+d.status)}) - 0 item"
                else
                  self.search.itemString "(#{_('response.'+x.status)}) - 0 item"
            error: (x, s, r) ->
              self.search.responseTime( Date.now() - _.responseTime )
              self.search.itemString "(#{_('response.'+x.status)}) - 0 item"
            complete: ->
              $('input[name=q]').focus()
              self.prepareComponents()
          }

        when 3
          # Messenger().post { message: _ 'query.invalid.short', type: 'error' }
          if not isNaN Number parts[0]
            Messenger().post { message: _ 'query.sType.invalid', type: 'error' }
            return false
          if not isNaN Number parts[1]
            Messenger().post { message: _ 'query.v.invalid', type: 'error' }
            return false
          if not isNaN Number parts[2]
            Messenger().post { message: _ 'query.oType.invalid', type: 'error' }
            return false

          _.responseTime = Date.now()
          self.search.data []
          self.search.dataType 'status'

          url = _.server + "/#{parts[0]}/#{parts[1]}/#{parts[2]}?apikey=#{self.search.secretKey}"

          $.ajax {
            url: url
            type: 'GET'
            async: true
            cache: false
            crossDomain: true
            dataType: 'jsonp'
            jsonpCallback: '_' + Date.now(),
            success: (d, s, x) ->
              self.search.responseTime( Date.now() - _.responseTime )
              if x.status is 200
                len = d.length
                if len > 1
                  self.search.itemString "#{len} items"
                else
                  self.search.itemString "#{len} item"
                for key of d
                  d[key].$subject.$type = parts[0]
                  d[key].$subject.$expanded = ko.observable false
                  d[key].$object.$type = parts[2]
                  d[key].$object.$expanded = ko.observable false
                self.search.data d
              else
                if d.status isnt undefined
                  self.search.itemString "(#{_('response.'+d.status)}) - 0 item"
                else
                  self.search.itemString "(#{_('response.'+x.status)}) - 0 item"
            error: (x, s, r) ->
              self.search.responseTime( Date.now() - _.responseTime )
              self.search.itemString "(#{_('response.'+x.status)}) - 0 item"
            complete: ->
              $('input[name=q]').focus()
              self.prepareComponents()
          }

        when 4
          if not isNaN Number parts[0]
            Messenger().post { message: _ 'query.sType.invalid', type: 'error' }
            return false
          else
            # string
            temp = Number parts[1]
            if not isNaN temp and isFinite temp
              # string number
              if not isNaN Number parts[2]
                # string number string
                temp = Number parts[3]
                if not isNaN temp
                  Messenger().post { message: _ 'query.oType.invalid', type: 'error' }
                  return false
                # string number string string
            else
              # string string
              if not isNaN Number parts[2]
                Messenger().post { message: _ 'query.v.invalid', type: 'error' }
                return false
              else
                # string string string
                temp = Number parts[3]
                if (not isNaN temp and isFinite temp) is false
                  Messenger().post { message: _ 'query.oNo.invalid', type: 'error' }
                  return false
                # string string string number

          _.responseTime = Date.now()
          self.search.data []
          self.search.dataType 'status'

          url = _.server + "/#{parts[0]}/#{parts[1]}/#{parts[2]}/#{parts[3]}?apikey=#{self.search.secretKey}"
          $.ajax {
            url: url
            type: 'GET'
            async: true
            cache: false
            crossDomain: true
            dataType: 'jsonp'
            jsonpCallback: '_' + Date.now(),
            success: (d, s, x) ->
              self.search.responseTime( Date.now() - _.responseTime )
              if x.status is 200
                len = d.length
                if len > 1
                  self.search.itemString "#{len} items"
                else
                  self.search.itemString "#{len} item"
                for key of d
                  d[key].$subject.$type = parts[0]
                  d[key].$subject.$expanded = ko.observable false
                  d[key].$object.$type = parts[2]
                  d[key].$object.$expanded = ko.observable false
                self.search.data d
              else
                if d.status isnt undefined
                  self.search.itemString "(#{_('response.'+d.status)}) - 0 item"
                else
                  self.search.itemString "(#{_('response.'+x.status)}) - 0 item"
            error: (x, s, r) ->
              self.search.responseTime( Date.now() - _.responseTime )
              self.search.itemString "(#{_('response.'+x.status)}) - 0 item"
            complete: ->
              $('input[name=q]').focus()
              self.prepareComponents()
          }
        when 5
          if not isNaN Number parts[0]
            Messenger().post { message: _ 'query.sType.invalid', type: 'error' }
            return false

          if not isNaN Number parts[2]
            Messenger().post { message: _ 'query.v.invalid', type: 'error' }
            return false

          if not isNaN Number parts[3]
            Messenger().post { message: _ 'query.oType.invalid', type: 'error' }
            return false

          _.responseTime = Date.now()
          self.search.data []
          self.search.dataType 'status'

          url = _.server + "/#{parts[0]}/#{parts[1]}/#{parts[2]}/#{parts[3]}/#{parts[4]}?apikey=#{self.search.secretKey}"
          
          $.ajax {
            url: url
            type: 'GET'
            async: true
            cache: false
            crossDomain: true
            dataType: 'jsonp'
            jsonpCallback: '_' + Date.now(),
            success: (d, s, x) ->
              self.search.responseTime( Date.now() - _.responseTime )
              if x.status is 200
                len = d.length
                if len > 1
                  self.search.itemString "#{len} items"
                else
                  self.search.itemString "#{len} item"
                for key of d
                  d[key].$subject.$type = parts[0]
                  d[key].$subject.$expanded = ko.observable false
                  d[key].$object.$type = parts[2]
                  d[key].$object.$expanded = ko.observable false
                self.search.data d
              else
                if d.status isnt undefined
                  self.search.itemString "(#{_('response.'+d.status)}) - 0 item"
                else
                  self.search.itemString "(#{_('response.'+x.status)}) - 0 item"
            error: (x, s, r) ->
              self.search.responseTime( Date.now() - _.responseTime )
              self.search.itemString "(#{_('response.'+x.status)}) - 0 item"
            complete: ->
              $('input[name=q]').focus()
              self.prepareComponents()
          }

        else
          Messenger().post { message: _ 'query.invalid.long', type: 'error' }

      false
    self.apiKey = 
      data: ko.observableArray()
      create: ->
        self.apiKey.data.unshift {
          $id: ko.observable('')
          $no: ko.observable(0)
          label: ko.observable('test')
          $createdAt: 0
          $updatedAt: 0
          url: ko.observableArray [
            { value: ko.observable('*') }
          ]
          logThreshold: ko.observable('warn'),
          scope: ko.observableArray([
            { name: "read_model"    , value: true }
            { name: "create_model"  , value: true }
            { name: "update_model"  , value: true }
            { name: "search_status" , value: true }
            { name: "create_status" , value: true }
            { name: "delete_status" , value: false }
            { name: "manage_order" , value: false }
            { name: "manage_pickup" , value: false }
          ])
        }
      addUrl: (key) ->
        key.url.push { value: '' }
      removeUrl: ->
        key = arguments[0]
        value = arguments[1]
        key.url.remove value
      save: (key) ->
        # _.currentSave = key.label()
        _.Pages.accountApiKeyUpdate(_.url).ajax
          contentType: 'application/json'
          data: ko.toJSON key
          success: (d, s, x) ->
            if x.status isnt 201
              Messenger().post {
                message: _ d
                type: 'error'
                showCloseButton: true
              }
            else
              Messenger().post {
                message: _ d
                type: 'success'
                showCloseButton: true
                actions:
                  reload:
                    label: 'Refresh now'
                    action: ->
                      # location.hash = _.currentSave
                      location.reload()
              }
          error: (x, s, r) ->
            msg = Messenger().post {
              message: r
              type: 'error'
              showCloseButton: true
              actions:
                retry:
                  label: 'Retry Now'
                  action: ->
                    self.apiKey.save(key)
            }
        false
      delete: (key)-> 
        if confirm(_('confirm.delete')) is false
          return false

        if key.$no() > 0
          _.Pages.accountApiKeyDelete(_.url, key.$no()).ajax
            success: (d, s, x) ->
              if x.status isnt 201
                Messenger().post {
                  message: _ d
                  type: 'error'
                  showCloseButton: true
                }
              else
                self.apiKey.data.remove(key)
                Messenger().post {
                  message: _ d
                  type: 'success'
                  showCloseButton: true
                  actions:
                    reload:
                      label: 'Refresh now'
                      action: ->
                        location.hash = _.currentSave
                        location.reload()
                }
            error: (x, s, r) ->
              msg = Messenger().post {
                message: r
                type: 'error'
                showCloseButton: true
                actions:
                  retry:
                    label: 'Retry Now'
                    action: ->
                      self.apiKey.delete(key)
              }
        else
          Messenger().post {
            message: _ 'delete.fail'
            type: 'error'
            showCloseButton: true
          }

      # load data from json
      load: (data) ->
        ko.mapping.fromJS(data, {}, self.apiKey.data)

    self.orderStatus =
      data: ko.observableArray()
      create: ->
        true
      start: (item) ->
        _.Pages.orderStatusStart(_.url, item.$no()).ajax {
          success: (d, s, x) ->
            if x.status is 202
              item.state 'running'
            else
              # 200 or 204
              Messenger().post { message: _('order.start.fail'), type: 'error' }
          error: ->
            Messenger().post { message: _('order.start.fail'), type: 'error' }
        }
        true
      pause: (item) ->
        if not confirm _('confirm.order.pause')
          return false
        _.Pages.orderStatusPause(_.url, item.$no()).ajax {
          success: (d, s, x) ->
            if x.status is 202
              item.state 'paused'
            else
              # 200 or 204
              Messenger().post { message: _('order.pause.fail'), type: 'error' }
          error: ->
            Messenger().post { message: _('order.pause.fail'), type: 'error' }
        }
        true
      delete: (item) ->
        if not confirm _('confirm.order.delete')
          return false
        self.orderStatus.data.remove(item)
        _.Pages.orderDelete(_.url, item.$no()).ajax()
      afterRender: ->
        self.prepareComponents()

    self.orderAdd =
      source: []
      verbs: ko.observableArray()
      types: ko.observableArray()
      basicQuery: ko.observable()
      advancedQuery: ko.observable """
{
  "dataType": "",
  "dataQuery": "",
  "plans": [
    {
      "key": "",
      "value": ""
    }
  ],
  "duration": "5 minutes",
  "title": "",
  "state": "paused"
}
"""
      mode: ko.observable 'basic'
      data: 
        # dataType: ko.observable 'model'
        # dataQuery: ko.observable ''
        # plans: ko.observableArray [
        #   {
        #     key: 'count', value: ''
        #   }
        # ]
        # resultType: ko.observable ''
        # resultQuery: ko.observable ''
        # duration: '5 minutes'
        # title: ko.observable ''
        # state: ko.observable 'paused'

        dataType: ko.observable ''
        dataQuery: ko.observable ''
        plans: ko.observableArray []
        # resultType: ko.observable 'status-create'
        # resultQuery: ko.observable '{"count": $count}'
        duration: ko.observable '5 minutes'
        title: ko.observable ''
        state: ko.observable 'paused'

        # resultType: ko.observable ''
        # resultType: ko.observable ''
        # planCategory: ko.observable ''
        # query: ko.observable ''
        # availableNumberPlans: ko.observable [ 'count.node', 'count.edge' ]
        # plans: ko.observableArray [
        #   {
        #     availableActions: ko.observable [ 'filter', 'count', 'sum', 'ave', 'sd' ]
        #     availableKeys: ko.observable [ 'cdate', 'udate', 'rdate', 'type', 'id', 'json' ]
        #     availableDateOperators: ko.observable [ 'after', 'before' ]
        #     availableStringOperators: ko.observable [ 'eq', 'neq' ]
        #     availableOperators: ko.observable [ 'lt', 'lte', 'eq', 'neq', 'gt', 'gte' ]
        #     action: ko.observable ''
        #     operator: ko.observable ''
        #     key: ko.observable ''
        #     value: ko.observable ''
        #   }
        # ]

      secretKey: ''
      create: ->
        data = self.orderAdd
        request = data.data

        json = null

        if data.mode() is 'basic'
          q = data.basicQuery()
          if data.source.indexOf(q) is -1
            Messenger().post { message: _('form.basicQuery.invalid'), type: 'info' }
            return false
          else if q[q.length-1] is ' '
            Messenger().post { message: _('form.basicQuery.incomplete'), type: 'info' }
            return false
          q = q.split ' '
          switch q.length
            # count how many {model type}
            when 4
              request.dataType 'model'
              request.dataQuery q[3]
              request.plans.removeAll()
              request.plans.push {
                key: 'count'
                value: ''
              }
            # count how many {subject type} did {verb} some {object type}
            when 8
              request.dataType 'status'
              request.dataQuery q[3] + ' ' + q[6] + ' ' + q[8]
              request.plans.removeAll()
              request.plans.push {
                key: 'count'
                value: 's'
              }
            # count how many times does a user issue some key
            when 10
              request.dataType 'status'
              request.dataQuery q[6] + ' ' + q[7] + ' ' + q[9]
              request.plans.removeAll()
              request.plans.push {
                key: 'count'
                value: ''
              }
            # count how many times does a user listen for each music
            when 11
              request.dataType 'status'
              request.dataQuery q[6] + ' ' + q[7] + ' ' + q[10]
              request.plans.removeAll()
              request.plans.push {
                key: 'count'
                value: 'o'
              }
            else
              Messenger().post { message: _('form.basicQuery.incomplete'), type: 'info' }
              return false
          json = JSON.parse ko.toJSON request
          # data = JSON.parse d
        else if data.mode() is 'advanced'
          try
            json = JSON.parse data.advancedQuery()
          catch e
            Messenger().post { message: _('form.advancedQuery.invalid'), type: 'error' }
            return false
        
        else
          Messenger().post { message: _('form.empty'), type: 'error' }
          return false

        # check empty
        if not json.dataType.length
          Messenger().post { message: _('form.dataType.empty'), type: 'error' }
          return false
        if not json.dataQuery.length
          Messenger().post { message: _('form.dataQuery.empty'), type: 'error' }
          return false
        if not json.state.length
          Messenger().post { message: _('form.order.state.empty'), type: 'error' }
          return false
        if not json.title.length
          Messenger().post { message: _('form.order.title.empty'), type: 'error' }
          return false

        _.Pages.orderAddUpdate(_.url).ajax {
          contentType: 'application/json'
          data: JSON.stringify(json)
          success: (d, s, x) ->
            console.log d,s
            if x.status is 201
              Messenger().post { message: _(d), type: 'success' }
              location.href = _.Pages.order(_.url, '/status').url
            else
              Messenger().post { message: _(d), type: 'error' }
          error: (x, s, r) ->
            console.log r,s
            Messenger().post { message: _('error.' + x.status), type: 'error' }
        }
        false

      optionsAfterRender: (element, index, data) ->
        # console.log '>', element, index, data
        # $('select').selectpicker();
      afterRender: ->
        $('select').selectpicker();
        $('#basicQuery').focus();

        self.orderAdd.secretKey = $('#secretKey').html()
        self.search.secretKey = $('#secretKey').html()
        if self.orderAdd.secretKey.length is 0
          Messenger().post { message: _ 'secret.key.empty', type: 'error' }

        q = $('#basicQuery')
        q.typeahead {
          source: self.orderAdd.source
          items: 10
          minLength: 0
          matcher: (item) ->
            p1 = item.split(' ').length
            p2 = this.query.split(' ').length
            # and (itemParts.length-1) <= queryParts.length
            # console.log item, p1, p2
            if item.toUpperCase().startsWith(this.query.toUpperCase()) and Math.max(p1-2,0) <= p2
              true
            else
              false
        }

    # self.orderAdd.data.queryResult = ko.computed ->
    #   # # put queries to search form
    #   # self.search.queries self.orderAdd.data.query()
    #   # self.search.query()
    #   # # if self.search.data() isnt undefined
    #   # console.log '>'
    #   # # return self.orderAdd.data.query()
    #   'Preview not available - ' + self.orderAdd.data.query()
    # .extend { throttle: 400 }


    self.pickupStatus =
      data: ko.observable()
      afterRender: ->
        self.prepareComponents()

    self.usage =
      data: ko.observable()

    self.plansAndBilling =
      data: ko.observable()

    self.prepareComponents = ->
      $('time').each (k, v) ->
        $this = $(v)
        if $this.is '[ago]'
          m = moment( Number($this.html()) )
          $this.html m.fromNow()
          $this.attr 'datetime', m.format()
          $this.attr 'title', m.format()
          $this.tooltip {
            placement: 'bottom'
          }
        else
          m = moment( Number($this.html()) )
          $this.html m.format()
      $('input[type=file]').bootstrapFileInput()
      $('select').selectpicker()
      true

    # apply url to view model, returns hasPropagation
    self.applyUrl = () ->
      parts = location.pathname.split '/'
      self.menu parts[2] if parts.length > 2
      if parts.length > 3
        if parts[4] isnt undefined
          self.id parts[4] 
        # else
        #   self.id ''
        self.page parts[3]
      else
        self._page ''
        false

    self.applyUrl()

    # display messages from flash data
    self.showMessage = ->
      if _.error?.length
        Messenger().post {
          message: _ _.error
          type: 'error'
          showCloseButton: true
        }
      if _.success?.length
        Messenger().post {
          message: _ _.success
          type: 'success'
        }

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
              # for item in d
              #   self[ $.camelCase(self.page()) ].data.push item
              switch self.page()
                when 'api-key' then self.apiKey.load d
                when 'import' then self.showMessage()
                when 'status'
                  if self.menu() is 'order'
                    for key of d
                      d[key].$expanded = false
                    ko.mapping.fromJS d, {}, self.orderStatus.data
                    # console.log d
                  else
                    self.pickupStatus.data d
                when 'add'
                  if self.menu() is 'order'
                    # _.Pages.orderAddVerb(_.url).ajax {
                    #   success: (d, s, x) ->
                    #     self.orderAdd.verbs d
                    # }
                    # console.log self.orderAdd.types()
                    # _.Pages.orderAddType(_.url).ajax {
                    #   success: (d, s, x) ->
                    #     self.orderAdd.types d
                    #     console.log self.orderAdd.types()
                    # }

                    $.when(
                      _.Pages.orderAddVerb(_.url).ajax(),
                      _.Pages.orderAddType(_.url).ajax()
                    ).done (verbs, types) ->
                      self.orderAdd.types types[0]
                      self.orderAdd.verbs verbs[0]
                      self.orderAdd.source.push 'Count '
                      self.orderAdd.source.push 'Count how '
                      self.orderAdd.source.push 'Count how many '
                      self.orderAdd.source.push 'Count how many times '
                      self.orderAdd.source.push 'Count how many times does'
                      self.orderAdd.source.push 'Count how many times does a '
                      for a in self.orderAdd.types()
                        self.orderAdd.source.push "Count how many #{a.name}"
                        self.orderAdd.source.push "Count how many times does a #{a.name}"
                        self.orderAdd.source.push "Count how many #{a.name} did "
                        for v in self.orderAdd.verbs()
                          self.orderAdd.source.push "Count how many #{a.name} did #{v.verb} "
                          self.orderAdd.source.push "Count how many #{a.name} did #{v.verb} some "
                          self.orderAdd.source.push "Count how many times does a #{a.name} #{v.verb}"
                          self.orderAdd.source.push "Count how many times does a #{a.name} #{v.verb} some "
                          self.orderAdd.source.push "Count how many times does a #{a.name} #{v.verb} for each "
                        for b in self.orderAdd.types()
                          for v in self.orderAdd.verbs()
                            self.orderAdd.source.push "Count how many #{a.name} did #{v.verb} some #{b.name}"
                            self.orderAdd.source.push "Count how many times does a #{a.name} #{v.verb} some #{b.name}"
                            self.orderAdd.source.push "Count how many times does a #{a.name} #{v.verb} for each #{b.name}"

                  else
                    # self.pickupAdd.data d
                  true
                when 'export' then 
                else self[ $.camelCase(self.page()) ].data d
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
