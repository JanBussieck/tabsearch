
# TODO need overlay widget with result list

OVERLAY_HTML = """
   <div id = 'tabsearch-overlay' style= "display:none">
      <div id = "box">
         <input type = "text"> </input>
         <div id= "results">
            <ul></ul>
         </div>
      </div>
   </div>
"""

# TODO tab view class html widget for search result with highlight

class TabView
  constructor: (tab, indexes) ->
    @tab = tab
    @url = removeProtocol(@tab.url)

    @indexes = indexes

  # the render method renders each item return from the search and highlights
  # the indices matching the search term
  render: ->
    html = '<li>'
    html += "<img class='favicon' src='#{@tab.favIconUrl}'></img>" if @tab.favIconUrl?

    html+= '<span class="title">'
    html+= @tab.title
    html+= '</span>'

    html+= '<div class="url">'
    j = 0
    for i in [0..@url.length]
      if @indexes? && @indexes[j] == i
        html += "<b>#{@url.charAt(i)}</b>"
        j++
      else
        html += @url.charAt(i)

    html+= '</div></div>'
    html+= '</li>'

# TODO populate result element with tabs, need list of candidate, element

class TabListView
  constructor: (element) ->
    @element_ = element

  element: ->
    @element_

  render: ->
    @element().empty()
    for tabView in @tabViews then @element().append tabView.render()

  # update takes a new list of candidates and constructs a list of tab views and rerenders the view
  update: (candidates) ->
    @tabViews = for candidate in candidates
      new TabView(candidate.tab or candidate, candidate.indexes)

      @render()

class Application
  constructor: (config) ->
    @config_ = config
    @injectView()

    @element().find('input').keyup (event) =>
      @onInput(event)

    @tabListView = new TabListView @element().find('ul')

  element: ->
    @element_ ||= $('tabsearch-overlay')

  tabs: ->
    @tabs_

  onInput: (event) ->
    candidates = sortByMatchingScore(@tabs(), event.target.value)

    @tabListView.update candidates

    if event.keyCode == 13
      @switchTab candidates[0].tab if candidates?

  hide: ->
    @element().hide()

  show: ->
    @tabListView.update @tabs()

    @element().show()
    @element().find('input').focus()

  switchTab: (tab) ->
    @hide()
    chrome.extension.SendRequest(message:"switchTab", target:tab)

  injectView: ->
    $('body').append(OVERLAY_HTML)

  isKeyboardEventMatching: (event) ->
    event.ctrlKey == @config_.ctrlKey &&
    event.altKey   == @config_.altKey   &&
    event.shiftKey == @config_.shiftKey &&
    event.metaKey  == @config_.metaKey  &&
    event.keyCode  == @config_.keyCode

  hotKeyListener: (event) ->
    if event.keyCode?
      if @isKeyboardEventMatching(event)
        chrome.extension.SendRequest message: "getTabs", (response) =>
