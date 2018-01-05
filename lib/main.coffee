{CompositeDisposable} = require 'atom'

csc = require './config-schema-compiler'

cc = require './completions-compiler'

configSchema = require '../compiledConfigSchema.json'

provider = require './provider'

module.exports =
  subscriptions: null

  activate: ->
    @subscriptions = new CompositeDisposable
    addCommands =
      'autocomplete-typo3-fluid:compileConfigSchema': => @compileConfigSchema()
      'autocomplete-typo3-fluid:compileCompletions': => @compileCompletions()
    @subscriptions.add(atom.commands.add('atom-workspace',addCommands))

  deactivate: ->
    @subscriptions.dispose()

  compileConfigSchema: -> csc.compileConfigSchema()

  compileCompletions: -> cc.compileCompletions()

  config: configSchema

  getProvider: -> provider
