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

module.exports = completions
