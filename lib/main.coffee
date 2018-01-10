{CompositeDisposable} = require 'atom'

Provider = require './provider'

main =
  subscriptions: null

  activate: ->
    @subscriptions = new CompositeDisposable
    addCommands =
      'autocomplete-typo3-fluid:buildConfigSchema': => @buildConfigSchema()
      'autocomplete-typo3-fluid:buildCompletions': => @buildCompletions()
    @subscriptions.add(atom.commands.add('atom-workspace',addCommands))

  deactivate: ->
    @subscriptions.dispose()

  buildConfigSchema: -> @getProvider().completionsCollector.buildConfigSchema()

  buildCompletions: -> @getProvider().completionsCollector.buildCompletions()

  getProvider: -> Provider

Object.defineProperty main, 'config',
    get: -> @getProvider().completionsCollector.getConfigSchema()

module.exports = main
