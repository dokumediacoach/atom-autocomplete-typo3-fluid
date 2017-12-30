fs = require 'fs'

completions =
  htmlAttributes:
    "data-namespace-typo3-fluid":
      description: "Omit TYPO3 Fluid Namespace(s) in HTML output"
      options: [true]
  nsMap: {}
  viewHelpers: {}

mergeArraysUnique = (array1, array2) ->
  mergedArray = []
  array1.concat(array2).forEach (item) ->
    if mergedArray.indexOf(item) is -1
      mergedArray.push(item)
  return mergedArray

mergeViewHelper = (ns, version, vhName, vhObject) ->
  if not completions.viewHelpers[ns]?
    completions.viewHelpers[ns] = {}
  if not completions.viewHelpers[ns][version]?
    completions.viewHelpers[ns][version] = {}
  if not completions.viewHelpers[ns][version][vhName]?
    completions.viewHelpers[ns][version][vhName] = {}
  if vhObject.description
    completions.viewHelpers[ns][version][vhName].description = vhObject.description
  if vhObject.mandatoryProperties
    cMandatoryProperties = completions.viewHelpers[ns][version][vhName].mandatoryProperties
    if cMandatoryProperties?
      cMandatoryProperties = mergeArraysUnique cMandatoryProperties, vhObject.mandatoryProperties
    completions.viewHelpers[ns][version][vhName].mandatoryProperties = cMandatoryProperties ? vhObject.mandatoryProperties
  if vhObject.properties?
    if not completions.viewHelpers[ns][version][vhName].properties?
      completions.viewHelpers[ns][version][vhName].properties = {}
    for name, object of vhObject.properties
      do (name, object) ->
        if not completions.viewHelpers[ns][version][vhName].properties[name]?
          completions.viewHelpers[ns][version][vhName].properties[name] = {}
        completions.viewHelpers[ns][version][vhName].properties[name].description = object.description

mergeElementRules = (ns, version, elementRules) ->
  if not completions.elementRules?
    completions.elementRules = {}
  if not completions.elementRules[ns]?
    completions.elementRules[ns] = {}
  if not completions.elementRules[ns][version]?
    completions.elementRules[ns][version] = {}
  if elementRules.localViewHelpers?
    cLocalViewHelpers = completions.elementRules[ns][version].localViewHelpers
    if cLocalViewHelpers?
      cLocalViewHelpers = mergeArraysUnique cLocalViewHelpers, elementRules.localViewHelpers
    completions.elementRules[ns][version].localViewHelpers = cLocalViewHelpers ? elementRules.localViewHelpers
  if elementRules.parent?
    if not completions.elementRules[ns][version].parent?
      completions.elementRules[ns][version].parent = {}
    for name, object of elementRules.parent
      do (name, object) ->
        if not completions.elementRules[ns][version].parent[name]?
          completions.elementRules[ns][version].parent[name] = {}
        if object.firstChild?
          cFirstChildren = completions.elementRules[ns][version].parent[name].firstChild
          if cFirstChildren?
            cFirstChildren = mergeArraysUnique cFirstChildren, object.firstChild
          completions.elementRules[ns][version].parent[name].firstChild = cFirstChildren ? object.firstChild
        if object.after?
          if not completions.elementRules[ns][version].parent[name].after
            completions.elementRules[ns][version].parent[name].after = {}
          for e, array of object.after
            cFollower = completions.elementRules[ns][version].parent[name].after[e]
            if cFollower?
              cFollower = mergeArraysUnique cFollower, array
            completions.elementRules[ns][version].parent[name].after[e] = cFollower ? array

expandElementRules = ->
  if not completions.elementRules?
    return
  for namespace, nsObject of completions.elementRules
    for version, vObject of nsObject
      if vObject.localViewHelpers?
        vObject.global = []
        for name, object of completions.viewHelpers[namespace][version]
          if vObject.localViewHelpers.indexOf(name) is -1
            vObject.global.push(name)
      if vObject.parent? and vObject.global?
        for name, pObject of vObject.parent
          if pObject.firstChild?
            pObject.firstChild = mergeGlobalInArray pObject.firstChild, vObject.global
          if pObject.after?
            for previous, namesArray of pObject.after
              namesArray = mergeGlobalInArray namesArray, vObject.global

mergeGlobalInArray = (array, globalArray) ->
  returnArray = []
  for name in array
    if name is '#global'
      for globalName in globalArray
        returnArray.push globalName
    else
      returnArray.push name
  returnArray

fs.readdirSync(__dirname + '/').forEach (file) ->
  if file.match /\.json$/
    fo = require "./#{file}"
    if fo.meta.xmlnsPrefix and fo.meta.xmlns and fo.meta.ns and fo.meta.version
      if completions.htmlAttributes["xmlns:#{fo.meta.xmlnsPrefix}"]?
        cHtmlXmlnsAttributeOptions = completions.htmlAttributes["xmlns:#{fo.meta.xmlnsPrefix}"].options
        if cHtmlXmlnsAttributeOptions?
          cHtmlXmlnsAttributeOptions = mergeArraysUnique cHtmlXmlnsAttributeOptions, [fo.meta.xmlns]
        completions.htmlAttributes["xmlns:#{fo.meta.xmlnsPrefix}"].options = cHtmlXmlnsAttributeOptions ? [fo.meta.xmlns]
      else
        completions.htmlAttributes["xmlns:#{fo.meta.xmlnsPrefix}"] =
          options: [fo.meta.xmlns]
      completions.nsMap[fo.meta.xmlns] = fo.meta.ns
      mergeViewHelper fo.meta.ns, fo.meta.version, name, object for name, object of fo.viewHelpers
      if fo.elementRules?
        mergeElementRules fo.meta.ns, fo.meta.version, fo.elementRules

expandElementRules()

module.exports = completions
