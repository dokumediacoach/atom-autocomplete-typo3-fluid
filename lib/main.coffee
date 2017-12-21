provider = require './provider'

configSchema =
  autoInsertMandatoryProperties:
    type: 'boolean'
    default: true
  viewHelperNamespaces:
    title: 'ViewHelper Namespaces'
    type: 'object'
    properties: {}

for namespace, versionObject of provider.completions.viewHelpers
  do (namespace, versionObject) ->
    configSchema.viewHelperNamespaces.properties[namespace] =
      title: namespace
      type: 'object'
      properties:
        enabled:
          title: 'enabled'
          type: 'boolean'
          default: true
        version:
          title: 'Version'
          type: 'string'
          enum: []
    Object.keys(versionObject).sort().forEach (version) ->
      configSchema.viewHelperNamespaces.properties[namespace].properties.version.enum.push version
      configSchema.viewHelperNamespaces.properties[namespace].properties.version.default = version

module.exports =
  config: configSchema

  activate: ->

  getProvider: -> provider
