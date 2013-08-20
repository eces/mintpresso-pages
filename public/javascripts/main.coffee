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

  onBlock = ($block) ->
    state = $block.data('state')
    if state is 0
      $block.data 'state', Math.round(Date.now()/1000)

    $block.addClass('active').fadeIn {
        duration: 300
        easing: 'easeOutQuint'
      }

  offContent = ($content) ->
    $content.find('div.active').fadeOut {
      duration: 300
      easing: 'easeOutQuint'
    }

  onMenu = ($submenu, $menu) ->
    $submenu.find('li:not(.reactive)').removeClass('active')
    $menu.addClass('active')
    if $submenu.data('parameter') is undefined
      $submenu.data('parameter', '')
    document.location.hash = '!/' + $menu.data('menu') + $.getParameterHash()

  triggerContent = ($content, $submenu, $menu, callback) ->
    $block = $content.find("[data-content=#{ $menu.data('menu') }]")
    if $menu.is('.active')
      return true

    if $menu.is('.reactive')
      $menu.removeClass('reactive')
    else
      offContent $content

    if $block.is('.wide')
      $content.addClass 'wide'
    else
      $content.removeClass 'wide'

    onMenu $submenu, $menu

    state = $block.data('state')
    if state is 0 or state < Math.round(Date.now()/1000) - _.loadingInterval
      callback $block
    else
      onBlock $block
    true

  refreshContent = ($content, $submenu, block, callback) ->
    $block = $content.find("[data-content=#{ block }]")
    $block.data('state', 0)
    el = $submenu.find "[data-menu=#{ block }]"
    if el.length > 0
      el.removeClass 'active'
      el.addClass 'reactive'
      el.trigger 'click'
      callback $block
    else
      console.log "Invalid data-menu=? at method refreshContent"

  triggerIndex = ($content, callback) ->
    $block = $content.find('[data-content=index]')
    offContent $content
    $submenu.find('li').removeClass('active')

    state = $block.data('state')
    if state is 0 or state < Math.round(Date.now()/1000) - _.loadingInterval
      callback $block
    else
      onBlock $block
    true

  triggerHash = ($content, $submenu) ->
    path = document.location.pathname
    if $.getParameterHash().length > 0
      hash = window.location.hash.slice(3, window.location.hash.indexOf('?'))
    else
      hash = window.location.hash.slice(3)

    menu = $('#menu li.active').data('menu')

    if hash is undefined or hash.length is 0
      triggerIndex $content, ($block) ->
        routes.controllers.Panel[menu + '_index'](_.id)
          .ajax()
          .error( blockError($block) )
          .success (e) ->
            $block.html e
            onBlock $block
    else if path.charAt(path.length - 1) is "/"
      el = $submenu.find "[data-menu=#{ hash }]"
      $submenu.data('data-parameter', $.getParameterHash())
      if el.length > 0
        el.trigger 'click'
      else
        console.log "Invalid data-menu='#{hash}' at method triggerHash"
        document.location.hash = '!/index' + $.getParameterHash()
        triggerIndex $content, ($block) ->
          routes.controllers.Panel[menu + '_index'](_.id)
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              onBlock $block
    else
      false

  blockError = ($block) ->
    return (xhr, status, error) -> 
      $block.html """
      <h1>#{error}</h1>
      <p>사용자 요청이 많아 일시적으로 응답이 지연되고 있습니다. 이 현상이 지속될 경우 support@mintpresso.com 또는 트위터로 연락바랍니다.</p>
      <div class="toolbar" style="height:220px">
        <a class="twitter-timeline" href="https://twitter.com/mintpresso" data-widget-id="310993678212665344">@mintpresso 님의 트윗</a>
        <script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");</script>
      </div>
      """
      onBlock $block

  formError = ($block) ->
    return (xhr, status, error) ->
      $('form span.help-block').html """<span class="label label-inverse">#{error}</span> """ + '사용자 요청이 많아 일시적으로 응답이 지연되고 있습니다. 이 현상이 지속될 경우 support@mintpresso.com 또는 트위터로 연락바랍니다.'
      $toolbar = $block.find('div.toolbar')
      if $toolbar.length is 0
        $block.append """
          <div class="toolbar" style="height:220px">
            <a class="twitter-timeline" href="https://twitter.com/mintpresso" data-widget-id="310993678212665344">@mintpresso 님의 트윗</a>
            <script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");</script>
          </div>
        """
      else
        $toolbar.html """
          <a class="twitter-timeline" href="https://twitter.com/mintpresso" data-widget-id="310993678212665344">@mintpresso 님의 트윗</a>
          <script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");</script>
        """
        $toolbar.height('220px')
      onBlock $block

  $meta = $('meta[name=panel]')
  if $meta.length > 0 and $meta isnt undefined
    _.page = $meta[0].getAttribute('content')

    if _.page is 'overview'
      $submenu = $("#submenu")
      $content = $("#content")

      $submenu.find('[data-menu=usage]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.overview_usage(_.id)
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              onBlock $block

      $submenu.find('[data-menu=account]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.overview_account(_.id)
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              onBlock $block

      $submenu.find('[data-menu=transaction]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.overview_transaction(_.id)
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              onBlock $block

      $submenu.find('[data-menu=api]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.overview_api(_.id)
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              $tbody = $block.find('table#tokens tbody')
              # for token in _._api
              token = _._api
              $tbody.prepend """
                <tr>
                  <td>
                    <input name="key" type="text" value="#{token.identifier}" disabled="disabled" class="editable code" style="width:450px; font-size:8pt" />
                    <br />
                    <textarea name="domain" title="Accessible Domains" class="editable" style="width:437px">#{token.data.url.split('|').join('\n')}</textarea>
                  </td>
                  <td>
                    <input name="name" type="text" value="#{token.data.name}" class="editable" />
                    <div class="btn-group">
                      <button type="submit" class="btn" style="width: 190px">SAVE</button>
                      <button class="btn dropdown-toggle" data-toggle="dropdown" style="width: 45px">
                        <span class="caret"></span>
                      </button>
                      <ul class="dropdown-menu" style="width: 230px">
                        <li><a href="#" class="api-js">JavaScript API</a></li>
                        <li><a href="#" class="api-scala">Scala API</a></li>
                      </ul>
                    </div>
                  </td>
                </tr>
                """

              # $tbody.append """
              #   <tr>
              #     <td>
              #       <input name="key" type="text" value="새로운 API 인증 토큰 추가" disabled="disabled" class="editable code" style="width:450px; font-size:8pt" />
              #       <br />
              #       <textarea name="domain" title="Accessible Domains" class="editable" style="width:437px"></textarea>
              #     </td>
              #     <td>
              #       <input name="name" type="text" placeholder="토큰을 알아보기 쉬운 이름" class="editable" />
              #       <button type="button" data-type="new" class="btn btn-small btn-block">SAVE</button>
              #     </td>
              #   </tr>
              #   """

              $tbody.find('span.seal').click () ->
                $(this).toggleClass 'seal'

              $tbody.find('tr').first().find('td div.btn-group button.dropdown-toggle').tooltip {
                title: "API KEY가 들어간 소스코드를 받을 수 있습니다."
              }

              $tbody.find('ul.dropdown-menu a').click (e) ->
                $elem = $(this)
                key = $elem.closest('tr').find('input[name=key]').val()
                id = _.id

                if $elem.is('.api-js')
                  alert """
Add it into <head> ... </head>

<script type="text/javascript">
(function(e,t,k,o){var n,r,i;r=e.createElement("script");
r.type="text/javascript";r.async=!0;
r.onload=function(){if('mintpresso' in window){return window["mintpresso"].init(t,k,o);}else{console.error('Failed to load mintpresso.js (please check http://mintpresso.statuspage.io)')}};
i="//mintpresso.com/assets/javascript-api/mintpresso-0.2.js";
if("https:"===e.location.protocol){r.src="https:"+i}else{r.src="http:"+i}n=e.getElementsByTagName("script")[0];return n.parentNode.insertBefore(r,n)}
)(document,"#{key}",#{id}, {withoutCallback: false, useLocalhost: false, callbackFunction: 'mintpressoInit', disableDebugCallback: true})
</script>
"""
                else if $elem.is('.api-scala')
                  alert """
Copy and paste block you need from these 3 examples.

// for application.conf
mintpresso.api="#{key}"
mintpresso.id=#{id}

// inline Affogato
val mintpresso: Affogato = Affogato("#{key}", #{id})

// Affogato with Play Framework
val mintpresso: Affogato = Affogato( 
  Play.configuration.getString("mintpresso.api").getOrElse("#{key}"),
  Play.configuration.getLong("mintpresso.id").getOrElse(#{id}L)
)

"""

              $block.find('form#domain').find('tr button[type=submit]').each (k,v) ->
                $elem = $(v)
                $elem.click (e) ->
                  if $(this).attr('data-type') is 'new'
                    alert '현재 인증키는 하나만 발급가능합니다.'
                    return false
                  else
                    $form = $(this).closest('tr')

                    offContent $content
                    args =
                      success: (e) ->
                        refreshContent $content, $submenu, 'api', ($block) ->
                          true
                      error: blockError($block)

                    routes.controllers.Panel.overview_api_set(
                      _.id,
                      $form.find('input[name=key]').val(),
                      $form.find('textarea[name=domain]').val(),
                      $form.find('input[name=name]').val()
                    ).ajax args
                    e.preventDefault()
                    e.stopPropagation()
                    return false
              onBlock $block

      triggerHash $content, $submenu
      _.waitForLoading = false
    else if _.page is 'data'
      $submenu = $("#submenu")
      $content = $("#content")

      $submenu.find('[data-menu=log]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.data_log(_.id)
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e

              _._recents = 0
              if _._errors isnt undefined and _._errors._length > 0
                $tbody = $block.find('table#logs')
                for e in _._errors.edges
                  d1 = moment(e.createdAt).format('YYYY-MM-DD HH:mm:ss')
                  d2 = moment(e.createdAt).fromNow()
                  data = e.object.data
                  msg = data['message']
                  delete data['message']
                  data = e.object.data
                  delete data['message']
                  d = js_beautify JSON.stringify(data), { indent_size: 2 }
                  recentClass = ''
                  if Date.now() < (e.createdAt + 3600000)
                    recentClass = 'recents error'
                    _._recents++
                  $tbody.append """
                    <tr class="errors #{recentClass}">
                      <td><i class="icon-frown"></i> #{msg}</td>
                      <td><button class="btn btn-mini" data-trigger="json">Show details</button></td>
                      <td>
                        <time datetime="#{d1}" title="#{d1}">#{d2}</time>
                      </td>
                    </tr>
                    <tr class="hide editor">
                      <td colspan="5">
                        <textarea class="code">#{d}</textarea>
                      </td>
                    </tr>
                    """
              
              if _._warnings isnt undefined and _._warnings._length > 0
                $tbody = $block.find('table#logs')
                for e in _._warnings.edges
                  d1 = moment(e.createdAt).format('YYYY-MM-DD HH:mm:ss')
                  d2 = moment(e.createdAt).fromNow()
                  data = e.object.data
                  msg = data['message']
                  delete data['message']
                  d = js_beautify JSON.stringify(data), { indent_size: 2 }
                  recentClass = ''
                  if Date.now() < (e.createdAt + 3600000)
                    recentClass = 'recents warning'
                    _._recents++
                  $tbody.append """
                    <tr class="warnings #{recentClass}">
                      <td><i class="icon-meh"></i> #{msg}</td>
                      <td><button class="btn btn-mini" data-trigger="json">Show details</button></td>
                      <td>
                        <time datetime="#{d1}" title="#{d1}">#{d2}</time>
                      </td>
                    </tr>
                    <tr class="hide editor">
                      <td colspan="5">
                        <textarea class="code">#{d}</textarea>
                      </td>
                    </tr>
                    """

              if _._requests isnt undefined and _._requests._length > 0
                $tbody = $block.find('table#logs')
                for e in _._requests.edges
                  d1 = moment(e.createdAt).format('YYYY-MM-DD HH:mm:ss')
                  d2 = moment(e.createdAt).fromNow()
                  data = e.object.data
                  msg = data['message']
                  delete data['message']
                  data = e.object.data
                  delete data['message']
                  d = js_beautify JSON.stringify(data), { indent_size: 2 }
                  recentClass = ''
                  if Date.now() < (e.createdAt + 3600000)
                    recentClass = 'recents success'
                    _._recents++
                  $tbody.append """
                    <tr class="requests #{recentClass}">
                      <td><i class="icon-smile"></i> #{msg}</td>
                      <td><button class="btn btn-mini" data-trigger="json">Show details</button></td>
                      <td>
                        <time datetime="#{d1}" title="#{d1}">#{d2}</time>
                      </td>
                    </tr>
                    <tr class="hide editor">
                      <td colspan="5">
                        <textarea class="code">#{d}</textarea>
                      </td>
                    </tr>
                    """
              if _._errors isnt undefined and _._warnings isnt undefined and _._requests isnt undefined and (_._errors._length + _._warnings._length + _._requests._length) is 0
                $("""
<div class="status-popup">
<br />
<br />
<br />
<i class="icon-rotate-right icon-spin" style="font-size:100pt; color: #1ABC9C"></i>
<br />
<h1 style="font-weight: 900">WE'RE RECEIVING DATA !</h1>
</div>
                """).insertAfter $block.find('#selector')
              else

                $block.find('button[data-trigger=json]').click (e) ->
                  $this = $(this)
                  $tr = $this.closest('tr').next()
                  $text = $tr.find('textarea')
                  $tr.toggle()
                  $text.height $text[0].scrollHeight if not $text.is('.scaled')  

                $block.find('#selector div.btn-group button').each (k, v) ->
                  $this = $(v)
                  switch $this.data 'field'
                    when 'recent'  then $this.html """{0} <span class="typo-number label-number">{1}</span>""".format( $this.html(), _._recents ) if _._recents > 0
                    when 'error'   then $this.html """{0} <span class="typo-number label-number">{1}</span>""".format( $this.html(), _._errors._length ) if _._errors._length > 0
                    when 'warning' then $this.html """{0} <span class="typo-number label-number">{1}</span>""".format( $this.html(), _._warnings._length ) if _._warnings._length > 0 
                    when 'request' then $this.html """{0} <span class="typo-number label-number">{1}</span>""".format( $this.html(), _._requests._length ) if _._requests._length > 0 

                switcher = (className) ->
                  $tbody.find('tbody tr').hide()
                  $tbody.find('tbody tr.' + className + ':not(.editor)').show()

                $popup = $block.find('#no-recents')
                switcherForRecent = () ->
                  switcher 'recents'
                  if _._recents is 0
                    $popup.show()

                $block.find('#selector div.btn-group button').click (e) ->
                  $this = $(this)
                  $popup.hide()
                  switch $this.data 'field'
                    when 'recent' then switcherForRecent()
                    when 'error' then switcher 'errors'
                    when 'warning' then switcher 'warnings'
                    when 'request' then switcher 'requests'
                
                switcherForRecent()
                $tbody.fadeIn()
              onBlock $block

      $submenu.find('[data-menu=view]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.data_view(_.id, $.getParameter('_filter'))
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              $block.find('input[name=s]').typeahead { source: _._types }
              $block.find('input[name=o]').typeahead { source: _._types }
              $block.find('#selector div.custom-filter a.add').tooltip {title: "Add new filter"}

              $revert = $block.find('#revert')
              if $.getParameter("_filter").length > 0
                $revert.click () ->
                  $.setParameter "_filter", ""
                  refreshContent $content, $submenu, 'view', ($block) ->
                    true
              else
                $revert[0].disabled = 'disabled'
              
              $refresh = $block.find('#refresh')
              $refresh.click () ->
                refreshContent $content, $submenu, 'view', ($block) ->
                  true

              if _._points isnt undefined and _._points.points.length > 0
                $tbody = $block.find('table#points')
                for p in _._points.points
                  d1 = moment(p.createdAt).format('YYYY-MM-DD HH:mm:ss')
                  d2 = moment(p.createdAt).fromNow()
                  d = js_beautify JSON.stringify(p.data), { indent_size: 2 }
                  dCount = Object.keys(p.data).length
                  if dCount > 0
                    dLabel = dCount + " keys"
                  else
                    dLabel = 'Empty'
                  if d is "{}"
                    d = "/* no data json */"
                  $tbody.prepend """
                    <tr>
                      <td><a href="#{p._url}">#{p.id}</a></td>
                      <td>#{p.type}</td>
                      <td>#{p.identifier}</td>
                      <td><button class="btn" data-trigger="json">#{dLabel}</button></td>
                      <td>
                        <time datetime="#{d1}" title="#{d1}">#{d2}</time>
                      </td>
                    </tr>
                    <tr class="hide editor">
                      <td colspan="5">
                        <textarea class="code">#{d}</textarea>
                      </td>
                    </tr>
                    """
                $tbody.fadeIn()
              else if _._edges isnt undefined and _._edges.edges.length > 0
                $tbody = $block.find('table#edges')
                for e in _._edges.edges
                  d1 = moment(e.createdAt).format('YYYY-MM-DD HH:mm:ss')
                  d2 = moment(e.createdAt).fromNow()

                  subjectD = js_beautify JSON.stringify(e.subject), { indent_size: 2 }
                  objectD = js_beautify JSON.stringify(e.object), { indent_size: 2 }

                  d = "/* no data json */"
                  $tbody.prepend """
                    <tr>
                      <td>
                        <button class="btn btn-small" data-trigger="json" data-type="subject">#{e.subjectType}</button>
                        <button class="btn btn-small btn-primary" data-trigger="fill" data-type="subjectId">#{e.subjectId}</button>
                      </td>
                      <td>#{e.verb}</td>
                      <td>
                        <button class="btn btn-small" data-trigger="json" data-type="object">#{e.objectType}</button>
                        <button class="btn btn-small btn-primary" data-trigger="fill" data-type="objectId">#{e.objectId}</button>
                      </td>
                      <td class="code">#{d}</td>
                      <td>
                        <time datetime="#{d1}" title="#{d1}">#{d2}</time>
                      </td>
                    </tr>
                    <tr class="hide editor">
                      <td colspan="2">
                        <textarea class="code subject">#{subjectD}</textarea>
                      </td>
                      <td colspan="3">
                        <textarea class="code object">#{objectD}</textarea>
                      </td>
                    </tr>
                    """
                $tbody.fadeIn()
              
              $block.find('button[data-trigger=json]').click (e) ->
                $this = $(this)
                $tr = $this.closest('tr').next()
                if $this.data('type') is ('subject' or 'object')
                  $text = $tr.find('textarea')
                  $tr.toggle()
                  $text.height Math.max($text[0].scrollHeight, $text[1].scrollHeight) if not $text.is('.scaled')
                else
                  $text = $tr.find('textarea')
                  $tr.toggle()
                  $text.height $text[0].scrollHeight if not $text.is('.scaled')

              $block.find('button[data-trigger=fill]').click (e) ->
                $this = $(this)
                $form = $('form#model')

                if $this.data('type') is 'subjectId'
                  $form.find('input[name=s]').val $this.html()
                else if $this.data('type') is 'objectId'
                  $form.find('input[name=o]').val $this.html()

              $modelForm = $block.find('form#model')
              $modelForm.submit () ->
                offContent $content
                $block.find('table').hide()

                `delete _._points`
                `delete _._edges`

                query = {
                  s: $modelForm.find('input[name=s]').val()
                  v: $modelForm.find('input[name=v]').val()
                  o: $modelForm.find('input[name=o]').val()
                }
                
                $.setParameter "_filter", JSON.stringify query

                refreshContent $content, $submenu, 'view', ($block) ->
                  true

              $relForm = $block.find('form#relation')

              onBlock $block

      $submenu.find('[data-menu=filter]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.data_filter(_.id)
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              onBlock $block

      $submenu.find('[data-menu=import]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.data_import(_.id)
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              onBlock $block
              $block.find('input[name=model]').typeahead { source: _._sTypes }
              $form = $block.find('form#model')
              $form.submit () ->
                args =
                  data: {
                    model: $form.find('input[name=model]').val()
                    identifier: $form.find('input[name=identifier]').val()
                    data: $form.find('textarea[name=data]').val()
                  }
                  success: (e) ->
                    refreshContent $content, $submenu, 'import', ($block) ->
                      true
                  error: formError($block)
                    
                      
                try
                  if args.data.data.length > 0
                    JSON.parse args.data.data
                catch error
                  $form.find('span.help-block').html "JSON 데이터가 유효하지 않습니다: " + error.toString()
                  return false
                
                offContent $content
                routes.controllers.Panel.data_import_add(_.id).ajax args
                return false
              $block.find('time').each (k,v) ->
                $time = $(v)
                $time.html moment($time.html()).fromNow()

      $submenu.find('[data-menu=export]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.data_export(_.id)
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              onBlock $block

      triggerHash $content, $submenu
      _.waitForLoading = false
      _.triggerContentWith = (name, json) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel['data_' + name](_.id, JSON.stringify(json))
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              onBlock $block
    else if _.page is 'support'
      $submenu = $("#submenu")
      $content = $("#content")

      $submenu.find('[data-menu=conversation]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.support_conversation(_.id)
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              onBlock $block

      $submenu.find('[data-menu=consulting]').click (e) ->
        triggerContent $content, $submenu, $(this), ($block) ->
          routes.controllers.Panel.support_consulting(_.id)
            .ajax()
            .error( blockError($block) )
            .success (e) ->
              $block.html e
              onBlock $block

      triggerHash $content, $submenu
      _.waitForLoading = false
    else if _.page is 'order'
      $submenu = $("#submenu")
      $content = $("#content")
      triggerHash $content, $submenu
      _.waitForLoading = false
    else if _.page is 'pickup'
      $submenu = $("#submenu")
      $content = $("#content")
      triggerHash $content, $submenu
      _.waitForLoading = false
    else
      alert("페이지를 불러올 수 없습니다. ")

  $meta = $('meta[name=document]')
  if $meta.length > 0 and $meta isnt undefined
    _.page = $meta[0].getAttribute('content')
    $body = $('#document #body')
    $body.find('time.updatedAt').each (k,v) ->
      $this = $(v)
      $this.html moment($this.html(), "YYYY-MM-DD").fromNow()

    if _.page is 'javascript/api'
      $code = $('div#body textarea.code');
      $code.val($code.val().replace("YOUR API KEY HERE", _._api.token + '::' + _.id))

    # if _.page is 'javascript/test'}}

  $meta = $('meta[name=login]')
  if $meta.length > 0 and $meta isnt undefined
    _.page = $meta[0].getAttribute('content')

    if _.page is 'changeAccount'
      $link = $('#link')
      l = $link.html() + location.hash
      $link.html l
      $link[0].href = l
