module.exports =

  compileConfigSchema: ->

    fs = require 'fs'

    namespaceVersions = {}
    fs.readdirSync(__dirname + '/../completions/').forEach (file) ->
      if file.match /\.json$/
        fileObject = require "../completions/#{file}"
        if fileObject.meta?.ns and fileObject.meta?.version
          if not namespaceVersions[fileObject.meta.ns]?
            namespaceVersions[fileObject.meta.ns] = {}
          namespaceVersions[fileObject.meta.ns][fileObject.meta.version] = true

    configSchema =
      autoInsertMandatoryProperties:
        type: 'boolean'
        default: true
      eddEndTagOnElementCompletion:
        type: 'boolean'
        default: true
      viewHelperNamespaces:
        title: 'ViewHelper Namespaces'
        type: 'object'
        properties: {}

    for namespace, versionsObject of namespaceVersions
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
      Object.keys(versionsObject).sort().forEach (version) ->
        configSchema.viewHelperNamespaces.properties[namespace].properties.version.enum.push version
        configSchema.viewHelperNamespaces.properties[namespace].properties.version.default = version

    fs.writeFile __dirname + '/../compiledConfigSchema.json', JSON.stringify(configSchema), (err) ->
      if(err)
        return console.log(err)
