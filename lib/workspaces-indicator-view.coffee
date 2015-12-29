{Emitter} = require 'atom'

module.exports =
class WorkspacesIndicatorView
  constructor: (state) ->
    @emitter = new Emitter

    # Create root element
    @element = document.createElement('div')
    @element.classList.add('workspaces-indicator')
    @element.classList.add('inline-block')

    # convenience querySelector methods
    @$ = @element.querySelector.bind(@element)
    @$$ = @element.querySelectorAll.bind(@element)

  onItemClicked: (callback) ->
    @emitter.on 'item-clicked', callback

  initStatusBar: (statusBar) ->
    @status = statusBar.addLeftTile(item: @element, priority: Math.infinity)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.parentNode.removeChild(@element)
    @emitter.dispose()

  addItem: ->
    indicatorItems = @$$('.workspaces-indicator-item')
    n = if indicatorItems then indicatorItems.length + 1 else 1

    # create indicator item
    div = document.createElement 'div'
    div.classList.add 'workspaces-indicator-item'
    div.innerText = n
    div.addEventListener 'click', =>
      num = parseInt div.innerText
      @setActive num
      @emitter.emit 'item-clicked', num
    @element.appendChild div

  removeItem: ->
    active = @$('.active')
    active.parentNode.removeChild(active)
    @update()

  update: ->
    for node, i in @$$('.workspaces-indicator-item')
      node.innerText = i + 1

  getActive: ->
    return parseInt(@$('.active').innerText)

  setActive: (num) ->
    node.classList.remove('active') for node, i in (@$$('.workspaces-indicator-item.active') ? [])
    el = @$("div:nth-child(#{ num })")
    el.classList.add('active') if el
