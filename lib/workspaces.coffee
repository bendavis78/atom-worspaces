WorkspacesView = require './workspaces-view'
{CompositeDisposable} = require 'atom'

module.exports = Workspaces =
  workspacesView: null
  subscriptions: null
  currentWorkspace: null

  activate: (state) ->
    @workspacesView = new WorkspacesView(state.workspacesViewState)
    @newWorkspace()

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:new-workspace': => @newWorkspace()
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:close-workspace': => @closeWorkspace()
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:next-workspace': => @nextWorkspace()
    @subscriptions.add atom.commands.add 'atom-workspace', 'workspaces:prev-workspace': => @prevWorkspace()

  consumeStatusBar: (statusBar) ->
    @workspacesView.initStatusBar statusBar

  deactivate: ->
    @subscriptions.dispose()
    @workspacesView.destroy()

  newWorkspace: ->
    n = @workspacesView.create()
    @workspacesView.setActive n
    console.log('created workspace')

  closeWorkspace: ->
    @workspacesView.remove()

  nextWorkspace: ->
    @workspacesView.next 1

  prevWorkspace: ->
    @workspacesView.next -1

  gotoWorkspace: (num) ->
    @workspacesView.setActive num

  serialize: ->
    workspacesViewState: @workspacesView.serialize()
