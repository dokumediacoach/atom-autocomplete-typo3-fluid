class KeyArrayValueObject
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

module.exports =

  compileCompletions: ->

    completions =
      htmlAttributes:
        'data-namespace-typo3-fluid':
          description: 'Omit TYPO3 Fluid Namespace(s) in HTML output'
          options: ['true']
      xmlnsMap: {}
      namespaces: {}

    fs = require 'fs'
    for file in fs.readdirSync(__dirname + '/../completions/')
      if file.match /\.json$/
        fo = require "../completions/#{file}"
        if fo.meta?.namespace and fo.meta?.version and
            atom.config.get("autocomplete-typo3-fluid.viewHelperNamespaces.#{fo.meta.namespace}.enabled") and
            atom.config.get("autocomplete-typo3-fluid.viewHelperNamespaces.#{fo.meta.namespace}.version") is fo.meta.version
          if fo.meta.xmlnsPrefix and fo.meta.xmlns
            if not completions.htmlAttributes.hasOwnProperty "xmlns:#{fo.meta.xmlnsPrefix}"
              completions.htmlAttributes["xmlns:#{fo.meta.xmlnsPrefix}"] = new KeyArrayValueObject
            if not completions.htmlAttributes["xmlns:#{fo.meta.xmlnsPrefix}"].hasOwnProperty 'description'
              completions.htmlAttributes["xmlns:#{fo.meta.xmlnsPrefix}"].description = 'XML Namespace declaration for Fluid ViewHelpers'
            completions.htmlAttributes["xmlns:#{fo.meta.xmlnsPrefix}"].mergeArrayUniqueInValueAtKey fo.meta.xmlns, 'options'
          if fo.meta.xmlns and fo.meta.namespace
            completions.xmlnsMap[fo.meta.xmlns] = fo.meta.namespace
          if not completions.namespaces.hasOwnProperty fo.meta.namespace
            completions.namespaces[fo.meta.namespace] =
              viewHelpers:
                global: {}
          if fo.hasOwnProperty 'viewHelpers'
            @mergeViewHelper completions.namespaces[fo.meta.namespace].viewHelpers.global, name, object for name, object of fo.viewHelpers
          if fo.hasOwnProperty 'elementRules'
            @mergeElementRules completions.namespaces[fo.meta.namespace], fo.elementRules

    @expandElementRules completions

    @optimizeCompletions completions

    fs.writeFile __dirname + '/../compiledCompletions.json', JSON.stringify(completions), (err) ->
      if(err)
        return console.log(err)

  mergeViewHelper: (completionsViewHelpersObject, viewHelperName, viewHelperObject) ->
    if not completionsViewHelpersObject.hasOwnProperty viewHelperName
      completionsViewHelpersObject[viewHelperName] = new KeyArrayValueObject
    if viewHelperObject.hasOwnProperty 'description'
      completionsViewHelpersObject[viewHelperName].description = viewHelperObject.description
    if viewHelperObject.hasOwnProperty 'mandatoryProperties'
      completionsViewHelpersObject[viewHelperName].mergeArrayUniqueInValueAtKey viewHelperObject.mandatoryProperties, 'mandatoryProperties'
    if viewHelperObject.hasOwnProperty 'properties'
      if not completionsViewHelpersObject[viewHelperName].hasOwnProperty 'properties'
        completionsViewHelpersObject[viewHelperName].properties = {}
      for name, object of viewHelperObject.properties
        if not completionsViewHelpersObject[viewHelperName].properties.hasOwnProperty name
          completionsViewHelpersObject[viewHelperName].properties[name] = {}
        if object.hasOwnProperty 'description'
          completionsViewHelpersObject[viewHelperName].properties[name].description = object.description

  mergeElementRules: (completionsNamespaceObject, elementRules) ->
    if not completionsNamespaceObject.hasOwnProperty 'elementRules'
      completionsNamespaceObject.elementRules = new KeyArrayValueObject
    if elementRules.hasOwnProperty 'localViewHelpers'
      completionsNamespaceObject.elementRules.mergeArrayUniqueInValueAtKey elementRules.localViewHelpers, 'localViewHelpers'
    if elementRules.hasOwnProperty 'parent'
      if not completionsNamespaceObject.elementRules.hasOwnProperty 'parent'
        completionsNamespaceObject.elementRules.parent = {}
      for name, object of elementRules.parent
        if not completionsNamespaceObject.elementRules.parent.hasOwnProperty name
          completionsNamespaceObject.elementRules.parent[name] = new KeyArrayValueObject
        if object.hasOwnProperty 'firstChild'
          completionsNamespaceObject.elementRules.parent[name].mergeArrayUniqueInValueAtKey object.firstChild, 'firstChild'
        if object.hasOwnProperty 'after'
          if not completionsNamespaceObject.elementRules.parent[name].hasOwnProperty 'after'
            completionsNamespaceObject.elementRules.parent[name].after = new KeyArrayValueObject
          for element, array of object.after
            completionsNamespaceObject.elementRules.parent[name].after.mergeArrayUniqueInValueAtKey array, element

  expandElementRules: (completions) ->
    for namespace, namespaceObject of completions.namespaces
      if namespaceObject.hasOwnProperty 'elementRules'
        if namespaceObject.elementRules.hasOwnProperty 'localViewHelpers'
          globalElements = {}
          for name, object of completions.namespaces[namespace].viewHelpers.global
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

  optimizeCompletions: (completions) ->
    autoInsertMandatoryProperties = atom.config.get('autocomplete-typo3-fluid.autoInsertMandatoryProperties')
    eddEndTagOnElementCompletion = atom.config.get('autocomplete-typo3-fluid.eddEndTagOnElementCompletion')
    nonWordCharacters = atom.config.get('editor.nonWordCharacters', scope: ['text.html.typo3-fluid'])
    for namespace, namespaceObject of completions.namespaces
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
