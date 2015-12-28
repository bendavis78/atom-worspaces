indicatorView = require './workspaces-indicator-view'
{CompositeDisposable} = require 'atom'

module.exports = Workspaces =
  indicatorView: null
  subscriptions: null
  currentWorkspace: null
  workspaces: []

  activate: (state) ->
    @indicatorView = new indicatorView(state.indicatorViewState)

    @atomWorkspace = atom.views.getView(atom.workspace)

    @restore state

    if !@workspaces.length
      @newWorkspace()

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:new-workspace': => @newWorkspace()
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:close-workspace': => @closeWorkspace()
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:next-workspace': => @nextWorkspace()
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:prev-workspace': => @prevWorkspace()

    atom.workspace.observePanes (pane) =>
      console.log('observed pane', pane.id)
      paneElement = atom.views.getView pane
      if (!paneElement.dataset.workspaceId)
        paneElement.dataset.workspaceId = @indicatorView.getActive()

  restore: (state) ->
    # restore from saved state
    if !state
      return

    if state.workspaces
      for workspace in state.workspaces
        @workspaces.push(workspace)
        @indicatorView.create()

    if state.currentWorspace
        @indicatorView.setActive state.currentWorkspace

  consumeStatusBar: (statusBar) ->
    @indicatorView.initStatusBar statusBar

  deactivate: ->
    @subscriptions.dispose()
    @indicatorView.destroy()

  newWorkspace: ->
    @numWorkspaces++
    n = @indicatorView.create()
    @setCurrent n

  setCurrent: (n) ->
    @currentWorkspace = n
    @indicatorView.setActive n
    @atomWorkspace.dataset.workspacesActiveWorkspace = n

  closeWorkspace: ->
    @indicatorView.remove()

  next: ->
    @setCurrent ((n - 1) % numWorkspaces) + 1

  prev: ->
    @setCurrent ((n - 1) % numWorkspaces) - 1

  serialize: ->
    workspaces: @workspaces
    currentWorkspace: @currentWorkspace
