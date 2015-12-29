indicatorView = require './workspaces-indicator-view'
{CompositeDisposable} = require 'atom'

module.exports = Workspaces =
  indicatorView: null
  subscriptions: null
  numWorkspaces: 0
  currentWorkspace: null
  createPaneInWorkspace: null
  paneMapping: {}
  activeItems: {}
  paneIdMapping: {}

  activate: (state) ->
    # TODO: hide entire pane container until panes are properly distributed

    window.workspaces = this
    @indicatorView = new indicatorView(state.indicatorViewState)

    @restore state

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Listen for when indicator item is clicked
    @subscriptions.add @indicatorView.onItemClicked (num) =>
      @setCurrent num

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:new-workspace': => @newWorkspace()
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:close-workspace': => @closeWorkspace()
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:next': => @next()
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:prev': => @prev()

    # Register panes as soon as they're created
    @subscriptions.add atom.workspace.observePanes (pane) => @registerPane pane

  registerPane: (pane) ->
    # make sure we have at least one workspace before registering a apane
    if @numWorkspaces == 0
      @newWorkspace()

    workspace = @currentWorkspace
    if @createPaneInWorkspace?
      workspace = @createPaneInWorkspace
      @createPaneInWorkspace = null

    @setPaneWorkspace pane, @paneMapping[pane.id] ? workspace

    @subscriptions.add pane.onDidDestroy =>
      paneWorkspace = @paneMapping[pane.id]
      delete @paneMapping[pane.id]
      if @getWorkspacePanes(paneWorkspace).length == 0
        @closeWorkspace workspace

  getWorkspacePanes: (workspace) ->
    workspace ?= @currentWorkspace
    (p for p, w of @paneMapping when w == workspace)

  setPaneWorkspace: (pane, n) ->
    console.debug("putting pane ##{pane.id} in workspace #{n}")
    n ?= @currentWorkspace

    while n > @numWorkspaces
      @createWorkspace()

    # TODO handle situation where nested pane has a parent in a different workspace
    if !pane
      return
    atom.views.getView(pane).dataset.workspacesWorkspaceNum = n
    @paneIdMapping[pane.id] = pane
    @paneMapping[pane.id] = n
    @updatePane pane

  updatePane: (pane) ->
    paneElement = atom.views.getView(pane)
    paneWorkspace = @paneMapping[pane.id]
    if paneWorkspace != @currentWorkspace
      paneElement.style.display = 'none';
      # Save active item for when workspace is restored
      activeItem = pane.getActiveItemIndex()
      if activeItem > -1
        @activeItems[pane.id] = activeItem
      else if @activeItems[pane.id]?
        delete @activeItems[pane.id]
    else
      paneElement.style.display = '';
      pane.activate()
      # Restore active pane item
      if @activeItems[pane.id]?
        pane.activateItemAtIndex(@activeItems[pane.id])

  restore: (state) ->
    # restore from saved state
    if !state
      return

    console.debug('restoring state:', state.paneMapping)
    if state.paneMapping
      # Panes will be updated as soon as they're observed based on @paneMapping
      @paneMapping = state.paneMapping

    if state.currentWorkspace
      @currentWorkspace = state.currentWorkspace

    if @numWorkspaces == 0
      @newWorkspace()
    else
      @setCurrent @currentWorkspace

  consumeStatusBar: (statusBar) ->
    @indicatorView.initStatusBar statusBar

  deactivate: ->
    #@@subscriptions.dispose()
    @indicatorView.destroy()

  newWorkspace: ->
    @createWorkspace()
    @setCurrent @numWorkspaces

  createWorkspace: ->
    @numWorkspaces++
    @indicatorView.addItem()
    @createPaneInWorkspace = @numWorkspaces

    #create a new intial pane for the workspace
    console.debug("Creating new initial pane? ", @numWorkspaces, @getWorkspacePanes())
    if @numWorkspaces > 1 && @getWorkspacePanes(@numWorkspaces).length == 0
      root = atom.workspace.paneContainer.root
      if root.children
        lastPane = root.children[root.children.length-1]
      else
        lastPane = root
      lastPane.splitRight()

  setCurrent: (n) ->
    n = (n % @numWorkspaces) || @numWorkspaces
    @currentWorkspace = n
    for paneId, workspace of @paneMapping
      pane = @getPane(paneId)
      if pane
        @updatePane(pane)
    @indicatorView.setActive n

  getPane: (id) ->
    return @paneIdMapping[id]

  closeWorkspace: (n) ->
    n ?= @currentWorkspace

    # close all panes in this workspace
    for paneId, workspace of @paneMapping
      if workspace == n
        @getPane(paneId).destroy()
      else if workspace > n
       @paneMapping[paneId] = workspace - 1

    if @numWorkspaces > 1
      @indicatorView.removeItem()
      @numWorkspaces--

    @next()

  next: ->
    @setCurrent @currentWorkspace + 1

  prev: ->
    @setCurrent @currentWorkspace - 1

  clean: ->
    @currentWorkspace = @currentWorkspace % @numWorkspaces || 1
    # clean up paneMapping
    for paneId, workspace of @paneMapping
      if !@getPane(paneId)
        console.debug("Removing non-existent pane ##{paneId}")
        delete @paneMapping[paneId]

  serialize: ->
    @clean()
    timestamp: new Date()
    paneMapping: @paneMapping
    currentWorkspace: @currentWorkspace
