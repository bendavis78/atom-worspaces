module.exports =
class WorkspacesView
  constructor: (serializedState) ->
    # Create root element
    @container = document.createElement('div')
    @container.classList.add('workspaces')
    @container.classList.add('inline-block')
    @body = document.querySelector('body')

    @$ = @container.querySelector.bind(@container)
    @$$ = @container.querySelectorAll.bind(@container)

  initStatusBar: (statusBar) ->
    console.log('initStatusBar')
    @status = statusBar.addLeftTile(item: @container, priority: 1)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @container.remove()

  create: ->
    workspaces = @$$('.workspaces-workspace')
    n = if workspaces then workspaces.length + 1 else 1
    console.log('n=', n)
    div = document.createElement('div')
    div.classList.add('workspaces-workspace')
    div.innerText = n
    div.addEventListener 'click', =>
      @setActive(parseInt(div.innerText))
    @container.appendChild(div)
    return n

  remove: ->
    @$$('.current').remove()
    @update()

  update: ->
    for node, i in @$$('.workspaces > div')
      node.innerText = i + 1

  getActive: ->
    return parseInt(@$('.active').innerText)

  setActive: (num) ->
    console.log 'setActive', num
    console.log('currently active:', @$$('.workspaces-workspace.active') ? [])
    console.log node for node, i in (@$$('.workspaces-workspace.active') ? [])
    node.classList.remove('active') for node, i in (@$$('.workspaces-workspace.active') ? [])
    @body.dataset.workspacesActiveWorkspace = num
    el = @$("div:nth-child(#{ num })")
    el.classList.add('active') if el
