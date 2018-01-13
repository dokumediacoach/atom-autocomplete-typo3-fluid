fs = require 'fs'

module.exports =

  completionsFolder: 'completions'

  getCompletionsJsonFileNames: ->
    fileNames = fs.readdirSync("#{__dirname}/../#{@completionsFolder}/").filter (fileName) ->
      /\.json$/.test fileName


  getConfigSchema: ->
    if not @configSchema?
      @buildConfigSchema()
    @configSchema

  buildConfigSchema: ->
    @configSchema =
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

    namespaceVersions = {}
    for fileName in @getCompletionsJsonFileNames()
      fileObject = require "../#{@completionsFolder}/#{fileName}"
      if fileObject.meta?.namespace and fileObject.meta?.version
        if not namespaceVersions.hasOwnProperty fileObject.meta.namespace
          namespaceVersions[fileObject.meta.namespace] = {}
        namespaceVersions[fileObject.meta.namespace][fileObject.meta.version] = true

    for namespace, versionsObject of namespaceVersions
      @configSchema.viewHelperNamespaces.properties[namespace] =
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
      for version in Object.keys(versionsObject).sort()
        @configSchema.viewHelperNamespaces.properties[namespace].properties.version.enum.push version
        @configSchema.viewHelperNamespaces.properties[namespace].properties.version.default = version


  getCompletions: ->
    if @rebuildCompletions or not @completions?
      @buildCompletions()
      @rebuildCompletions = false
    @completions

  rebuildCompletions: true

  buildCompletions: ->
    @completions =
      htmlAttributes:
        'data-namespace-typo3-fluid':
          description: 'Omit TYPO3 Fluid Namespace(s) in HTML output'
          options: ['true']
      inlineNamespaceDefinitions: {}
      xmlnsMap: {}
      namespaces: {}

    for fileName in @getCompletionsJsonFileNames()
      fo = require "../#{@completionsFolder}/#{fileName}"
      if fo.meta?.namespace and fo.meta?.version and
          atom.config.get("autocomplete-typo3-fluid.viewHelperNamespaces.#{fo.meta.namespace}.enabled") and
          atom.config.get("autocomplete-typo3-fluid.viewHelperNamespaces.#{fo.meta.namespace}.version") is fo.meta.version
        if fo.meta.namespacePrefix and fo.meta.xmlns
          if not @completions.htmlAttributes.hasOwnProperty "xmlns:#{fo.meta.namespacePrefix}"
            @completions.htmlAttributes["xmlns:#{fo.meta.namespacePrefix}"] = {}
          if not @completions.htmlAttributes["xmlns:#{fo.meta.namespacePrefix}"].hasOwnProperty 'description'
            @completions.htmlAttributes["xmlns:#{fo.meta.namespacePrefix}"].description = 'XML Namespace declaration for Fluid ViewHelpers'
          @mergeArrayUniqueInValueAtKey.call @completions.htmlAttributes["xmlns:#{fo.meta.namespacePrefix}"], fo.meta.xmlns, 'options'
        if fo.meta.namespacePrefix and fo.meta.namespace
          if not @completions.inlineNamespaceDefinitions.hasOwnProperty fo.meta.namespacePrefix
            @completions.inlineNamespaceDefinitions[fo.meta.namespacePrefix] = {}
          if not @completions.inlineNamespaceDefinitions[fo.meta.namespacePrefix].hasOwnProperty 'description'
            @completions.inlineNamespaceDefinitions[fo.meta.namespacePrefix].description = 'Namespace declaration for Fluid ViewHelpers'
          @mergeArrayUniqueInValueAtKey.call @completions.inlineNamespaceDefinitions[fo.meta.namespacePrefix], fo.meta.namespace, 'options'
        if fo.meta.xmlns and fo.meta.namespace
          @completions.xmlnsMap[fo.meta.xmlns] = fo.meta.namespace
        if not @completions.namespaces.hasOwnProperty fo.meta.namespace
          @completions.namespaces[fo.meta.namespace] =
            viewHelpers:
              global: {}
        if fo.hasOwnProperty 'viewHelpers'
          @mergeViewHelper fo.meta.namespace, name, object for name, object of fo.viewHelpers
        if fo.hasOwnProperty 'elementRules'
          @mergeElementRules fo.meta.namespace, fo.elementRules

    @expandElementRules()
    @optimizeCompletions()

  mergeViewHelper: (namespace, viewHelperName, viewHelperObject) ->
    completionsViewHelpers = @completions.namespaces[namespace].viewHelpers.global
    if not completionsViewHelpers.hasOwnProperty viewHelperName
      completionsViewHelpers[viewHelperName] = {}
    if viewHelperObject.hasOwnProperty 'description'
      completionsViewHelpers[viewHelperName].description = viewHelperObject.description
    if viewHelperObject.hasOwnProperty 'mandatoryProperties'
      @mergeArrayUniqueInValueAtKey.call completionsViewHelpers[viewHelperName], viewHelperObject.mandatoryProperties, 'mandatoryProperties'
    if viewHelperObject.hasOwnProperty 'properties'
      if not completionsViewHelpers[viewHelperName].hasOwnProperty 'properties'
        completionsViewHelpers[viewHelperName].properties = {}
      for name, object of viewHelperObject.properties
        if not completionsViewHelpers[viewHelperName].properties.hasOwnProperty name
          completionsViewHelpers[viewHelperName].properties[name] = {}
        if object.hasOwnProperty 'description'
          completionsViewHelpers[viewHelperName].properties[name].description = object.description

  mergeElementRules: (namespace, elementRules) ->
    completionsNamespace = @completions.namespaces[namespace]
    if not completionsNamespace.hasOwnProperty 'elementRules'
      completionsNamespace.elementRules = {}
    if elementRules.hasOwnProperty 'localViewHelpers'
      @mergeArrayUniqueInValueAtKey.call completionsNamespace.elementRules, elementRules.localViewHelpers, 'localViewHelpers'
    if elementRules.hasOwnProperty 'parent'
      if not completionsNamespace.elementRules.hasOwnProperty 'parent'
        completionsNamespace.elementRules.parent = {}
      for name, object of elementRules.parent
        if not completionsNamespace.elementRules.parent.hasOwnProperty name
          completionsNamespace.elementRules.parent[name] = {}
        if object.hasOwnProperty 'firstChild'
          @mergeArrayUniqueInValueAtKey.call completionsNamespace.elementRules.parent[name], object.firstChild, 'firstChild'
        if object.hasOwnProperty 'after'
          if not completionsNamespace.elementRules.parent[name].hasOwnProperty 'after'
            completionsNamespace.elementRules.parent[name].after = {}
          for element, array of object.after
            @mergeArrayUniqueInValueAtKey.call completionsNamespace.elementRules.parent[name].after, array, element

  mergeArrayUniqueInValueAtKey: (array, key) ->
    if not Array.isArray array
      if Object.prototype.toString.call(String(array)) isnt '[object String]'
        console.log "could not merge array unique in value at key '#{key}' - parameter error #{Object.prototype.toString.call String(array)}"
        return
      array = [String(array)]
    if not @hasOwnProperty key
      @[key] = []
    else if not Array.isArray @[key]
      if Object.prototype.toString.call(String(@[key])) isnt '[object String]'
        console.log "could not merge array unique in value at key '#{key}' - object value error #{Object.prototype.toString.call String(@[key])}"
        return
      @[key] = [String(@[key])]
    array.forEach (value) =>
      if @[key].indexOf(value) is -1
        @[key].push value

  expandElementRules: ->
    for namespace, namespaceObject of @completions.namespaces
      if namespaceObject.hasOwnProperty 'elementRules'
        if namespaceObject.elementRules.hasOwnProperty 'localViewHelpers'
          globalElements = {}
          for name, object of @completions.namespaces[namespace].viewHelpers.global
            if namespaceObject.elementRules.localViewHelpers.indexOf(name) is -1
              globalElements[name] = true
        if namespaceObject.elementRules.hasOwnProperty 'parent' and globalElements?
          for name, parentObject of namespaceObject.elementRules.parent
            if parentObject.hasOwnProperty 'firstChild'
              parentObject.firstChild = @mergeGlobalInArray parentObject.firstChild, globalElements
            if parentObject.hasOwnProperty 'after'
              for previous, namesArray of parentObject.after
                parentObject.after[previous] = @mergeGlobalInArray namesArray, globalElements

  mergeGlobalInArray: (array, globalElementsObject) ->
    returnArray = []
    for name in array
      if name is '#global'
        for globalName in Object.keys globalElementsObject
          returnArray.push "<g>#{globalName}"
      else if globalElementsObject.hasOwnProperty name
        returnArray.push "<g>#{name}"
      else
        returnArray.push "<l>#{name}"
    returnArray

  optimizeCompletions: ->
    autoInsertMandatoryProperties = atom.config.get('autocomplete-typo3-fluid.autoInsertMandatoryProperties')
    eddEndTagOnElementCompletion = atom.config.get('autocomplete-typo3-fluid.eddEndTagOnElementCompletion')
    nonWordCharacters = atom.config.get('editor.nonWordCharacters', scope: ['text.html.typo3-fluid'])
    for namespace, namespaceObject of @completions.namespaces
      namespaceObject.viewHelperProperties = {}
      for viewHelperName, viewHelperObject of namespaceObject.viewHelpers.global
        if viewHelperObject.hasOwnProperty 'properties'
          propertiesCopy = JSON.parse(JSON.stringify(viewHelperObject.properties))
          namespaceObject.viewHelperProperties[viewHelperName] = propertiesCopy
          delete viewHelperObject.properties
        hasMandatoryProperties = viewHelperObject.hasOwnProperty 'mandatoryProperties'
        if autoInsertMandatoryProperties and hasMandatoryProperties
          tagProperties = ''
          inlineProperties = ''
          for property, i in viewHelperObject.mandatoryProperties
            tagProperties += " #{property}=\"$#{i + 1}\""
            if i
              inlineProperties += ', '
            inlineProperties += "#{property}: $#{i + 1}"
          tagProperties += "$#{viewHelperObject.mandatoryProperties.length + 1}"
        else
          tagProperties = '$1'
          inlineProperties = '$1'
        viewHelperObject.snippets =
          tag: "#{viewHelperName}#{tagProperties}>$"
          inline: "#{viewHelperName}(#{inlineProperties})$0"
        if eddEndTagOnElementCompletion
          viewHelperObject.snippets.tag += if hasMandatoryProperties then "#{(viewHelperObject.mandatoryProperties.length + 2)}" else '2'
          viewHelperObject.snippets.endTagEnd = "#{viewHelperName}>$0"
        else
          viewHelperObject.snippets.tag += '0'
        if hasMandatoryProperties
          delete viewHelperObject.mandatoryProperties
        if not viewHelperObject.description
          viewHelperObject.description = "ViewHelper #{viewHelperName}"
        viewHelperObject.characterMatchIndices = @getCharacterMatchIndices viewHelperName, nonWordCharacters

      for viewHelperName, propertiesObject of namespaceObject.viewHelperProperties
        for propertyName, propertyObject of propertiesObject
          propertyObject.snippets =
            tag: "#{propertyName}=\"$1\"$0"
            inline: "#{propertyName}: $1"
          if not propertyObject.hasOwnProperty('description') or not propertyObject.description
            propertyObject.description = "ViewHelper property #{propertyName}"
          propertyObject.characterMatchIndices = @getCharacterMatchIndices propertyName, nonWordCharacters

      if namespaceObject.hasOwnProperty('elementRules') and namespaceObject.elementRules.hasOwnProperty('localViewHelpers')
        namespaceObject.viewHelpers.local = {}
        for localName in namespaceObject.elementRules.localViewHelpers
          if namespaceObject.viewHelpers.global.hasOwnProperty localName
            globalCopy = JSON.parse(JSON.stringify(namespaceObject.viewHelpers.global[localName]))
            namespaceObject.viewHelpers.local[localName] = globalCopy
            delete namespaceObject.viewHelpers.global[localName]
        delete namespaceObject.elementRules.localViewHelpers

  getCharacterMatchIndices: (completionName, nonWordCharacters) ->
    returnArray = []
    for character, index in completionName
      if not nonWordCharacters.includes character
        returnArray.push index
    returnArray
