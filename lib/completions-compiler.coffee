module.exports =

  compileCompletions: ->

    completions =
      htmlAttributes:
        "data-namespace-typo3-fluid":
          description: "Omit TYPO3 Fluid Namespace(s) in HTML output"
          options: [true]
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
            cHtmlXmlnsAttributeOptions = completions.htmlAttributes["xmlns:#{fo.meta.xmlnsPrefix}"]?.options
            if cHtmlXmlnsAttributeOptions?
              completions.htmlAttributes["xmlns:#{fo.meta.xmlnsPrefix}"].options = @mergeArraysUnique cHtmlXmlnsAttributeOptions, [fo.meta.xmlns]
            else
              completions.htmlAttributes["xmlns:#{fo.meta.xmlnsPrefix}"] =
                options: [fo.meta.xmlns]
          if fo.meta.xmlns and fo.meta.namespace
            completions.xmlnsMap[fo.meta.xmlns] = fo.meta.namespace
          if not completions.namespaces[fo.meta.namespace]?
            completions.namespaces[fo.meta.namespace] =
              viewHelpers:
                global: {}
          if fo.viewHelpers?
            @mergeViewHelper completions.namespaces[fo.meta.namespace].viewHelpers.global, name, object for name, object of fo.viewHelpers
          if fo.elementRules?
            if not completions.namespaces[fo.meta.namespace].elementRules?
              completions.namespaces[fo.meta.namespace].elementRules = {}
            @mergeElementRules fo.elementRules, completions.namespaces[fo.meta.namespace].elementRules

    @expandElementRules completions

    @optimizeCompletions completions

    fs.writeFile __dirname + '/../compiledCompletions.json', JSON.stringify(completions), (err) ->
      if(err)
        return console.log(err)

  mergeViewHelper: (completionsViewHelpers, viewHelperName, viewHelperObject) ->
    if not completionsViewHelpers[viewHelperName]?
      completionsViewHelpers[viewHelperName] = {}
    if viewHelperObject.description
      completionsViewHelpers[viewHelperName].description = viewHelperObject.description
    if viewHelperObject.mandatoryProperties
      cMandatoryProperties = completionsViewHelpers[viewHelperName].mandatoryProperties
      if cMandatoryProperties?
        completionsViewHelpers[viewHelperName].mandatoryProperties = mergeArraysUnique cMandatoryProperties, viewHelperObject.mandatoryProperties
      else
        completionsViewHelpers[viewHelperName].mandatoryProperties = viewHelperObject.mandatoryProperties
    if viewHelperObject.properties?
      if not completionsViewHelpers[viewHelperName].properties?
        completionsViewHelpers[viewHelperName].properties = {}
      for name, object of viewHelperObject.properties
        if not completionsViewHelpers[viewHelperName].properties[name]?
          completionsViewHelpers[viewHelperName].properties[name] = {}
        if object.description?
          completionsViewHelpers[viewHelperName].properties[name].description = object.description

  mergeElementRules: (elementRules, completionsElementRules) ->
    if elementRules.localViewHelpers?
      cLocalViewHelpers = completionsElementRules.localViewHelpers
      if cLocalViewHelpers?
        completionsElementRules.localViewHelpers = @mergeArraysUnique cLocalViewHelpers, elementRules.localViewHelpers
      else
        completionsElementRules.localViewHelpers = elementRules.localViewHelpers
    if elementRules.parent?
      if not completionsElementRules.parent?
        completionsElementRules.parent = {}
      for name, object of elementRules.parent
        if not completionsElementRules.parent[name]?
          completionsElementRules.parent[name] = {}
        if object.firstChild?
          cFirstChildren = completionsElementRules.parent[name].firstChild
          if cFirstChildren?
            completionsElementRules.parent[name].firstChild = @mergeArraysUnique cFirstChildren, object.firstChild
          else
            completionsElementRules.parent[name].firstChild = object.firstChild
        if object.after?
          if not completionsElementRules.parent[name].after
            completionsElementRules.parent[name].after = {}
          for e, array of object.after
            cFollower = completionsElementRules.parent[name].after[e]
            if cFollower?
              completionsElementRules.parent[name].after[e] = @mergeArraysUnique cFollower, array
            else
              completionsElementRules.parent[name].after[e] = array

  expandElementRules: (completions) ->
    for namespace, namespaceObject of completions.namespaces
      namespaceElementRules = namespaceObject.elementRules
      if namespaceElementRules?
        if namespaceElementRules.localViewHelpers?
          globalElements = {}
          for name, object of completions.namespaces[namespace].viewHelpers.global
            if namespaceElementRules.localViewHelpers.indexOf(name) is -1
              globalElements[name] = true
        if namespaceElementRules.parent? and globalElements?
          for name, parentObject of namespaceElementRules.parent
            if parentObject.firstChild?
              parentObject.firstChild = @mergeGlobalInArray parentObject.firstChild, globalElements
            if parentObject.after?
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

  mergeArraysUnique: (array1, array2) ->
    mergedArray = []
    array1.concat(array2).forEach (item) ->
      if mergedArray.indexOf(item) is -1
        mergedArray.push item
    return mergedArray

  optimizeCompletions: (completions) ->
    autoInsertMandatoryProperties = atom.config.get('autocomplete-typo3-fluid.autoInsertMandatoryProperties')
    eddEndTagOnElementCompletion = atom.config.get('autocomplete-typo3-fluid.eddEndTagOnElementCompletion')
    nonWordCharacters = atom.config.get('editor.nonWordCharacters', scope: ['text.html.typo3-fluid'])
    for namespace, namespaceObject of completions.namespaces
      namespaceObject.viewHelperProperties = {}
      for viewHelperName, viewHelperObject of namespaceObject.viewHelpers.global
        if viewHelperObject.properties?
          propertiesCopy = JSON.parse(JSON.stringify(viewHelperObject.properties))
          namespaceObject.viewHelperProperties[viewHelperName] = propertiesCopy
          delete viewHelperObject.properties
        mandatoryProperties = viewHelperObject.mandatoryProperties
        if autoInsertMandatoryProperties and mandatoryProperties?
          tagProperties = ''
          inlineProperties = ''
          for property, i in mandatoryProperties
            tagProperties += " #{property}=\"$#{i + 1}\""
            if i
              inlineProperties += ', '
            inlineProperties += "#{property}: $#{i + 1}"
          tagProperties += "$#{mandatoryProperties.length + 1}"
        else
          tagProperties = '$1'
          inlineProperties = '$1'
        viewHelperObject.snippets =
          tag: "#{viewHelperName}#{tagProperties}>$"
          inline: "#{viewHelperName}(#{inlineProperties})$0"
        if eddEndTagOnElementCompletion
          viewHelperObject.snippets.tag += if mandatoryProperties? then "#{(mandatoryProperties.length + 2)}" else '2'
          viewHelperObject.snippets.endTagEnd = "#{viewHelperName}>$0"
        else
          viewHelperObject.snippets.tag += '0'
        if mandatoryProperties?
          delete viewHelperObject.mandatoryProperties
        if not viewHelperObject.description
          viewHelperObject.description = "ViewHelper #{viewHelperName}"
        viewHelperObject.characterMatchIndices = @getCharacterMatchIndices viewHelperName, nonWordCharacters

      for viewHelperName, propertiesObject of namespaceObject.viewHelperProperties
        for propertyName, propertyObject of propertiesObject
          propertyObject.snippets =
            tag: "#{propertyName}=\"$1\"$0"
            inline: "#{propertyName}: $1"
          if not propertyObject.description
            propertyObject.description = "ViewHelper property #{propertyName}"
          propertyObject.characterMatchIndices = @getCharacterMatchIndices propertyName, nonWordCharacters

      namespaceElementRules = namespaceObject.elementRules
      if namespaceElementRules?.localViewHelpers?
        namespaceObject.viewHelpers.local = {}
        for localName in namespaceElementRules.localViewHelpers
          if namespaceObject.viewHelpers.global[localName]?
            globalCopy = JSON.parse(JSON.stringify(namespaceObject.viewHelpers.global[localName]))
            namespaceObject.viewHelpers.local[localName] = globalCopy
            delete namespaceObject.viewHelpers.global[localName]
        delete namespaceElementRules.localViewHelpers

  getCharacterMatchIndices: (completionName, nonWordCharacters) ->
    returnArray = []
    for character, index in completionName
      if not nonWordCharacters.includes character
        returnArray.push index
    returnArray
