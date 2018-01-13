{CompositeDisposable} = require 'atom'

Provider = require './provider'

main =
  subscriptions: null

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'autocomplete-typo3-fluid:rebuildConfigSchema': => @rebuildConfigSchema()
      'autocomplete-typo3-fluid:rebuildCompletions': => @triggerRebuildCompletions()
    onConfigChangeKeys = [
      'autocomplete-typo3-fluid.autoInsertMandatoryProperties'
      'autocomplete-typo3-fluid.eddEndTagOnElementCompletion'
      'autocomplete-typo3-fluid.viewHelperNamespaces'
    ]
    for key in onConfigChangeKeys
      @subscriptions.add atom.config.onDidChange key, => @triggerRebuildCompletions()

  deactivate: ->
    @subscriptions.dispose()

  rebuildConfigSchema: -> @getProvider().completionsCollector.buildConfigSchema()

  triggerRebuildCompletions: -> @getProvider().completionsCollector.rebuildCompletions = true

  getProvider: -> Provider

Object.defineProperty main, 'config',
    get: -> @getProvider().completionsCollector.getConfigSchema()

module.exports = main
