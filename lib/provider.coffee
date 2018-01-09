COMPLETIONS = require '../compiledCompletions.json'


## Regex Patterns

# @getInlineViewHelperCompletions Patterns:
inlineViewHelperPropertyStartPattern = /\b[a-zA-Z][.a-zA-Z0-9]*:[a-zA-Z][.a-zA-Z0-9]*\((?:[^){]*,)?\s*(?:[a-zA-Z][.a-zA-Z0-9]*)?$/
inlineViewHelperStartPattern = /\b[a-zA-Z][.a-zA-Z0-9]*:[a-zA-Z][.a-zA-Z0-9]*\([^)]*$/
inlineViewHelperEndPattern = /^[^)]*\)/
inlineViewHelperInfoPattern =/^([a-zA-Z][.a-zA-Z0-9]*):([a-zA-Z][.a-zA-Z0-9]*)\(([^)]*)/g
inlineViewHelperInfoPropertiesMatchPattern = /[a-zA-Z][.a-zA-Z0-9]*(?=:)/g
inlineViewHelperNameStartPattern = /[^(,]?\s*([a-zA-Z][.a-zA-Z0-9]*):(?:[a-zA-Z][.a-zA-Z0-9]*)?$/

# @getTagViewHelperCompletions Patterns:
tagViewHelperPropertyStartPattern = /<[a-zA-Z][.a-zA-Z0-9]*:[a-zA-Z][.a-zA-Z0-9]*(?:\s+[a-zA-Z][.a-zA-Z0-9]*=(?:"[^"]*"|\'[^\']\'))*\s+(?:[a-zA-Z][.a-zA-Z0-9]*)?$/
tagViewHelperStartPattern = /<[a-zA-Z][.a-zA-Z0-9]*:[a-zA-Z][.a-zA-Z0-9]*\s+[^>]*$/
tagViewHelperEndPattern = /^[^>]*>$/
tagViewHelperInfoPattern =/^<([a-zA-Z][.a-zA-Z0-9]*):([a-zA-Z][.a-zA-Z0-9]*)([^>]*)>/g
tagViewHelperInfoPropertiesMatchPattern = /[a-zA-Z][.a-zA-Z0-9]*(?==)/g
tagViewHelperNameStartPattern = /<([a-zA-Z][.a-zA-Z0-9]*):(?:[a-zA-Z][.a-zA-Z0-9]*)?$/
tagViewHelperSelfCloseStartPattern = /<([a-zA-Z][.a-zA-Z0-9]*:[a-zA-Z][.a-zA-Z0-9]*)(?:\s+[a-zA-Z][.a-zA-Z0-9]*=(?:"[^"]*"|\'[^\']*\'))*\s*\/$/

# @getClosingTagCompletion
tagCloseStartPattern = /<\/([a-zA-Z][.a-zA-Z0-9]*):(?:[a-zA-Z][.a-zA-Z0-9]*)?$/

# @getViewHelperNamespaceFromNamespacePrefix Patterns:
xmlNamespacePattern = /xmlns:([_a-zA-Z][-._a-zA-Z0-9]*)=(?:"([^"]+)"|\'([^\']+)\')/
inlineNamespacePattern = /{namespace\s+([_a-zA-Z][-._a-zA-Z0-9]*)=([^}\s]+)\s*}/

# @getParentElement Pattern:
elementScopePattern = /^meta\.tag\.element\.([a-zA-Z][.a-zA-Z0-9]*):([a-zA-Z][.a-zA-Z0-9]*)\.typo3-fluid$/

# @onDidInsertSuggestion Pattern:
selfCloseElementCompletionDisplayTextPattern = /^([a-zA-Z][.a-zA-Z0-9]*:[a-zA-Z][.a-zA-Z0-9]*)\sself-close$/

# @removeInlineNotationsFromString Pattern:
innermostInlineNotationPattern = /{([^{}]*)}/g

# @resolveRuleViewHelperArray Pattern:
ruleViewHelperNamePattern = /^<(g|l)>([a-zA-Z][.a-zA-Z0-9]*)$/

## Scopes

inlineNotationScope = 'meta.inline-notation.typo3-fluid'
inlinePropertiesScope = 'meta.inline.view-helper.properties.typo3-fluid'
inlineViewHelperScope = 'meta.inline.view-helper.typo3-fluid'

tagAttributesScope = 'meta.tag.start.attributes.typo3-fluid'
tagStartScope = 'meta.tag.start.typo3-fluid'
tagContentScope = 'meta.tag.content.typo3-fluid'

## Completion Suggestions

module.exports =
  selector: '.text.html'
  disableForSelector: '.text.html .comment'
  filterSuggestions: true
  completions: COMPLETIONS

  # include prior to default provider (inclusionPriority of 0).
  inclusionPriority: 1
  # exclude default provider
  excludeLowerPriority: true
  # suggest prior to default provider (suggestionPriority of 1).
  suggestionPriority: 2

  getSuggestions: (request) ->
    if @hasScope inlineNotationScope, request.scopeDescriptor
      @getInlineNotationCompletions request
    else if @hasScope tagStartScope, request.scopeDescriptor
      @getTagViewHelperCompletions request
    else if @hasScope tagContentScope, request.scopeDescriptor
      @getClosingTagCompletion request
    else
      []

  getInlineNotationCompletions: ({prefix, scopeDescriptor, bufferPosition, editor}) ->
    vhScopeLevel = @getNestingLevelForScope inlineViewHelperScope, scopeDescriptor
    vhScopeRange = @getRangeForScopeAtPosition inlineViewHelperScope, bufferPosition, editor
    if vhScopeLevel and vhScopeRange?
      vhStartText = editor.getTextInRange [vhScopeRange.start, bufferPosition]
      vhStartText = @removeInlineNotationsFromString vhStartText
      if inlineViewHelperPropertyStartPattern.test vhStartText
        if vhScopeLevel > 1
          openingBracketIndex = vhStartText.lastIndexOf '{'
          vhStartText = vhStartText.substring (openingBracketIndex + 1)
        vhStartText = inlineViewHelperStartPattern.exec vhStartText
        vhEndText = editor.getTextInRange [bufferPosition, vhScopeRange.end]
        vhEndText = @removeInlineNotationsFromString vhEndText
        if vhScopeLevel > 1
          closingBracketIndex = vhEndText.indexOf '}'
          vhEndText = vhEndText.substring 0, closingBracketIndex
        vhEndText = inlineViewHelperEndPattern.exec vhEndText
        viewHelperText = vhStartText + vhEndText
        return @getViewHelperPropertyCompletions 'inline', viewHelperText, bufferPosition, editor
    inScopeRange = @getRangeForScopeAtPosition inlineNotationScope, bufferPosition, editor
    inStartText = editor.getTextInRange [inScopeRange.start, bufferPosition]
    @getViewHelperCompletions 'inline', inStartText, bufferPosition, editor

  getTagViewHelperCompletions: ({prefix, scopeDescriptor, bufferPosition, editor, activatedManually}) ->
    vhScopeRange = @getRangeForScopeAtPosition tagStartScope, bufferPosition, editor
    vhStartText = editor.getTextInRange [vhScopeRange.start, bufferPosition]
    if tagViewHelperPropertyStartPattern.test vhStartText
      vhStartText = tagViewHelperStartPattern.exec vhStartText
      vhEndText = editor.getTextInRange [bufferPosition, vhScopeRange.end]
      vhEndText = tagViewHelperEndPattern.exec vhEndText
      viewHelperText = vhStartText + vhEndText
      @getViewHelperPropertyCompletions 'tag', viewHelperText, bufferPosition, editor
    else if not activatedManually and tagViewHelperSelfCloseStartPattern.test vhStartText
      startTagMatches = tagViewHelperSelfCloseStartPattern.exec vhStartText
      @getSelfClosingTagCompletion startTagMatches[1], bufferPosition, editor
    else
      @getViewHelperCompletions 'tag', vhStartText, bufferPosition, editor

  getClosingTagCompletion: ({prefix, scopeDescriptor, bufferPosition, editor}) ->
    lineStartText = editor.getTextInRange [[bufferPosition.row, 0], bufferPosition]
    return [] if not tagCloseStartPattern.test lineStartText
    namespacePrefixMatches = tagCloseStartPattern.exec lineStartText
    parent = @getParentElement namespacePrefixMatches[1], bufferPosition, editor
    return [] if not parent?
    [@buildClosingTagCompletion namespacePrefixMatches[1], parent]

  buildClosingTagCompletion: (namespacePrefix, parent) ->
    text: "#{parent}>"
    displayText: "#{namespacePrefix}:#{parent} end tag"
    type: 'function'
    description: "close #{namespacePrefix}:#{parent} ViewHelper"
    characterMatchIndices: [0..parent.length-1]

  getSelfClosingTagCompletion: (elementName, bufferPosition, editor) ->
    textBuffer = editor.getBuffer()
    lineEnd = textBuffer.lineLengthForRow(bufferPosition.row)
    lineEndText = editor.getTextInRange [bufferPosition, [bufferPosition.row, lineEnd]]
    emptyElementEndPattern = new RegExp "^><\/#{elementName}>"
    if not emptyElementEndPattern.test lineEndText
      return []
    [@buildSelfClosingTagCompletion elementName]

  buildSelfClosingTagCompletion: (emptyElement) ->
    text: '/'
    replacementPrefix: '/'
    displayText: "#{emptyElement} self-close"
    type: 'function'
    description: "make #{emptyElement} self-closing"

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
    if suggestion.text is '/'
      elementMatches = selfCloseElementCompletionDisplayTextPattern.exec suggestion.displayText
      deleteLength = elementMatches[1].length + 3
      textBuffer = editor.getBuffer()
      textBuffer.delete [triggerPosition, [triggerPosition.row, triggerPosition.column + deleteLength]]

  getViewHelperCompletions: (tagOrInline, viewHelperStartText, bufferPosition, editor) ->
    startPattern = if tagOrInline is 'tag' then tagViewHelperNameStartPattern else inlineViewHelperNameStartPattern
    viewHelperNameStart = startPattern.exec viewHelperStartText
    return [] if not viewHelperNameStart?
    namespacePrefix = viewHelperNameStart[1]
    namespace = @getViewHelperNamespaceFromNamespacePrefix namespacePrefix, bufferPosition, editor
    return [] if not namespace? or not @completions.namespaces?[namespace]?.viewHelpers?
    if tagOrInline is 'tag' and @completions.namespaces[namespace].elementRules?
      parent = @getParentElement namespacePrefix, bufferPosition, editor
      if parent? and (parentElementRules = @completions.namespaces[namespace].elementRules.parent?[parent])?
        viewHelpers = @getRuleViewHelperElements namespacePrefix, namespace, parent, parentElementRules, bufferPosition, editor
    if not viewHelpers?
      viewHelpers = @completions.namespaces[namespace].viewHelpers.global
    return [] if not viewHelpers?
    completions = []
    for name, object of viewHelpers
      completions.push @buildViewHelperCompletion tagOrInline, namespacePrefix, namespace, name, object
    if tagOrInline is 'inline' and (localViewHelpers = @completions.namespaces[namespace].viewHelpers.local)?
      for name, object of localViewHelpers
        completions.push @buildViewHelperCompletion tagOrInline, namespacePrefix, namespace, name, object
    completions

  getRuleViewHelperElements: (namespacePrefix, namespace, parent, parentElementRules, bufferPosition, editor) ->
    tagContentScopeRange = @getRangeForScopeAtPosition tagContentScope, bufferPosition, editor
    tagContentStartText = editor.getTextInRange [tagContentScopeRange.start, bufferPosition]
    parentNestingLevel = @getNestingLevelForScopeAtPosition "meta.tag.element.#{namespacePrefix}:#{parent}.typo3-fluid", bufferPosition, editor
    if parentNestingLevel > 1
      nestedParentPattern = new RegExp "<#{namespacePrefix}:#{parent}(?:\\s[^>]*?[^>\/]?)?>((?:.|[\\r\\n\\u2028\\u2029])*?)$"
      nestedParentPatternMatches = nestedParentPattern.exec tagContentStartText
      tagContentStartText = nestedParentPatternMatches[1]
    precedingSiblingPattern = new RegExp "(?:<\/#{namespacePrefix}:([a-zA-Z][.a-zA-Z0-9]*)>|<#{namespacePrefix}:([a-zA-Z][.a-zA-Z0-9]*)(?:\\s[^>]*?)?\/>)(?:.|[\\r\\n\\u2028\\u2029])*?$"
    precedingSiblingMatches = precedingSiblingPattern.exec tagContentStartText
    if precedingSiblingMatches?
      precedingSibling = precedingSiblingMatches[1] ? precedingSiblingMatches[2]
    if precedingSibling? and parentElementRules.after?[precedingSibling]?
      ruleViewHelpers = @resolveRuleViewHelperArray parentElementRules.after[precedingSibling], namespace
    else if parentElementRules.firstChild?
      ruleViewHelpers = @resolveRuleViewHelperArray parentElementRules.firstChild, namespace
    return if not ruleViewHelpers?
    ruleViewHelpers

  resolveRuleViewHelperArray: (viewHelperArray, namespace) ->
    returnViewHelpers = {}
    for name in viewHelperArray
      nameMatches = ruleViewHelperNamePattern.exec name
      if nameMatches?
        if nameMatches[1] is 'l' and @completions.namespaces[namespace].viewHelpers.local?.hasOwnProperty nameMatches[2]
          returnViewHelpers[nameMatches[2]] = @completions.namespaces[namespace].viewHelpers.local[nameMatches[2]]
          continue
        if nameMatches[1] is 'g' and @completions.namespaces[namespace].viewHelpers.global?.hasOwnProperty nameMatches[2]
          returnViewHelpers[nameMatches[2]] = @completions.namespaces[namespace].viewHelpers.global[nameMatches[2]]
          continue
      if @completions.namespaces[namespace].viewHelpers.local?.hasOwnProperty name
        returnViewHelpers[name] = @completions.namespaces[namespace].viewHelpers.local[name]
      else if @completions.namespaces[namespace].viewHelpers.global?.hasOwnProperty name
        returnViewHelpers[name] = @completions.namespaces[namespace].viewHelpers.global[name]
    returnViewHelpers

  getParentElement: (namespacePrefix, bufferPosition, editor) ->
    scopeDescriptor = editor.scopeDescriptorForBufferPosition(bufferPosition)
    scopesArray = scopeDescriptor.getScopesArray()
    for scope in scopesArray
      if elementScopePattern.test scope
        elementMatches = elementScopePattern.exec scope
        if elementMatches[1] is namespacePrefix
          element = elementMatches[2]
        continue
      if scope is tagContentScope and element?
        parent = element
    parent

  getViewHelperPropertyCompletions: (tagOrInline, viewHelperText, bufferPosition, editor, prefix) ->
    isTag = tagOrInline is 'tag'
    infoPattern = if isTag then tagViewHelperInfoPattern else inlineViewHelperInfoPattern
    propPattern = if isTag then tagViewHelperInfoPropertiesMatchPattern else inlineViewHelperInfoPropertiesMatchPattern
    viewHelperInfo = {}
    viewHelperText.replace infoPattern, (all, namespacePrefix, name, properties) ->
      viewHelperInfo.namespacePrefix = namespacePrefix
      viewHelperInfo.name = name
      if properties
        viewHelperInfo.properties = properties.match propPattern
    namespace = @getViewHelperNamespaceFromNamespacePrefix viewHelperInfo.namespacePrefix, bufferPosition, editor
    return [] if not namespace? or not @completions.namespaces?[namespace]?
    viewHelperProperties = @completions.namespaces[namespace].viewHelperProperties?[viewHelperInfo.name]
    return [] if not viewHelperProperties?
    completions = []
    viewHelperName = viewHelperInfo.namespacePrefix + ':' + viewHelperInfo.name
    for name, object of viewHelperProperties when not viewHelperInfo.properties? or viewHelperInfo.properties.indexOf(name) is -1
      completions.push @buildViewHelperPropertyCompletion tagOrInline, name, viewHelperName, object
    completions

  buildViewHelperCompletion: (tagOrInline, namespacePrefix, namespace, name, viewHelperObject) ->
    snippet = viewHelperObject.snippets[tagOrInline]
    if tagOrInline is 'tag' and viewHelperObject.snippets.hasOwnProperty 'endTagEnd'
      snippet += "</#{namespacePrefix}:#{viewHelperObject.snippets.endTagEnd}"
    completion =
      snippet: snippet
      displayText: "#{namespacePrefix}:#{name}"
      type: 'function'
      rightLabel: namespace
      description: viewHelperObject.description
      characterMatchIndices: viewHelperObject.characterMatchIndices

  buildViewHelperPropertyCompletion: (tagOrInline, name, viewHelperName, viewHelperPropertyObject) ->
    snippet: viewHelperPropertyObject.snippets[tagOrInline]
    displayText: name
    type: 'attribute'
    rightLabel: "#{viewHelperName} property"
    description: viewHelperPropertyObject.description
    characterMatchIndices: viewHelperPropertyObject.characterMatchIndices

  getViewHelperNamespaceFromNamespacePrefix: (namespacePrefix, bufferPosition, editor) ->
    textBuffer = editor.getBuffer()
    row = bufferPosition.copy().row
    result = {}
    loop
      row = textBuffer.previousNonBlankRow row
      return if not row?
      lineText = editor.lineTextForBufferRow row
      if xmlNamespacePattern.test lineText
        xmlNamespaceMatches = xmlNamespacePattern.exec lineText
        if xmlNamespaceMatches[1] is namespacePrefix
          xmlns = xmlNamespaceMatches[2] ? xmlNamespaceMatches[3]
          return @completions.xmlnsMap?[xmlns]
        continue
      if inlineNamespacePattern.test lineText
        inlineNamespaceMatches = inlineNamespacePattern.exec lineText
        if inlineNamespaceMatches[1] is namespacePrefix
          return inlineNamespaceMatches[2]

  getConfigVersionForNamespace: (namespace) ->
    return if not atom.config.get('autocomplete-typo3-fluid.viewHelperNamespaces.' + namespace + '.enabled')
    atom.config.get('autocomplete-typo3-fluid.viewHelperNamespaces.' + namespace + '.version')

  removeInlineNotationsFromString: (string) ->
    while innermostInlineNotationPattern.test string
      string = string.replace innermostInlineNotationPattern, '#r#'
    string

  ## Some more general helper methods and therefore better commented

  # Determine if a scope descriptor has a scope.
  #
  # * `scope` A scope name {String}.
  # * `scopeDescriptor` A scope descriptor {Object}.
  #
  # Returns a {Boolean}.
  hasScope: (scope, scopeDescriptor) ->
    scopesArray = scopeDescriptor.getScopesArray()
    scopesArray.indexOf(scope) isnt -1

  # Determine if a buffer position has a scope.
  #
  # * `scope` A scope name {String}.
  # * `position` A buffer position {Point}.
  # * `editor` A {TextEditor} instance.
  #
  # Returns a {Boolean}.
  hasScopeAtPosition: (scope, position, editor) ->
    scopeDescriptor = editor.scopeDescriptorForBufferPosition(position)
    @hasScope scope, scopeDescriptor

  # Get the nesting level depth for a scope in a scope descriptor.
  #
  # * `scope` A scope name {String}.
  # * `scopeDescriptor` A scope descriptor {Object}.
  #
  # Returns a {Number}.
  getNestingLevelForScope: (scope, scopeDescriptor) ->
    scopesArray = scopeDescriptor.getScopesArray()
    filteredScopesArray = scopesArray.filter (s) -> s is scope
    filteredScopesArray.length

  # Get the nesting level depth for a scope at a buffer position.
  #
  # * `scope` A scope name {String}.
  # * `position` A buffer position {Point}.
  # * `editor` A {TextEditor} instance.
  #
  # Returns a {Number}.
  getNestingLevelForScopeAtPosition: (scope, position, editor) ->
    scopeDescriptor = editor.scopeDescriptorForBufferPosition(position)
    @getNestingLevelForScope scope, scopeDescriptor

  # Get the text in a range for a scope at a buffer position.
  # Other than the TextEditor API Method (bufferRangeForScopeAtPosition) this
  # can get a range that may reach over multiple lines.
  #
  # * `scope` A scope name {String}.
  # * `positionParam` A {Point} inside the range.
  # * `editor` A {TextEditor} instance.
  # * `limitScope` An {Object} that defauts to null with the following keys
  #   * `start` A scope name {String} indicating the start of the higher level `scope`
  #   * `end` A scope name {String} indicating the end of the higher level `scope`
  # * `skipBlankRows` A {boolean}, true to skip blank rows when scope range
  #   reaches over multiple lines, defaults to true.
  #
  # Returns a {String}.
  getRangeForScopeAtPosition: (scope, position, editor, limitScope = null, skipBlankRows = true) ->
    scopeRange = editor.bufferRangeForScopeAtPosition scope, position
    return if not scopeRange?
    loop
      break if scopeRange.start.column
      if limitScope?.start?
        break if @hasScopeAtPosition limitScope.start, scopeRange.start, editor
      newPosition = @getPreviousLineEndPosition scopeRange.start, editor, skipBlankRows
      break if not newPosition?
      tempRange = editor.bufferRangeForScopeAtPosition scope, newPosition
      break if not tempRange?
      scopeRange = scopeRange.union tempRange
    loop
      break if scopeRange.end.column <= editor.lineTextForBufferRow(scopeRange.end.row).length
      if limitScope?.end?
        break if @hasScopeAtPosition limitScope.end, scopeRange.end, editor
      newPosition = @getNextLineStartPosition scopeRange.end, editor, skipBlankRows
      break if not newPosition?
      tempRange = editor.bufferRangeForScopeAtPosition scope, newPosition
      break if not tempRange?
      scopeRange = scopeRange.union tempRange
    scopeRange

  # Get the end position of the previous non blank line.
  #
  # * `positionParam` A {Point} from where to move upwards.
  # * `editor` A {TextEditor} instance.
  # * `skipBlankRows` A {boolean}, true to skip blank rows, defaults to true.
  #
  # Returns a {Point}.
  getPreviousLineEndPosition: (positionParam, editor, skipBlankRows = true) ->
    position = positionParam.copy()
    textBuffer = editor.getBuffer()
    if skipBlankRows
      previousRow = textBuffer.previousNonBlankRow(position.row)
    else
      previousRow = position.row - 1
    return null if not previousRow? or previousRow < 0
    position.row = previousRow
    position.column = textBuffer.lineLengthForRow(previousRow)
    position

  # Get the start position of the next non blank line.
  #
  # * `positionParam` A {Point} from where to move downwards.
  # * `editor` A {TextEditor} instance.
  # * `skipBlankRows` A {boolean}, true to skip blank rows, defaults to true.
  #
  # Returns a {Point}.
  getNextLineStartPosition: (positionParam, editor, skipBlankRows = true) ->
    position = positionParam.copy()
    textBuffer = editor.getBuffer()
    if skipBlankRows
      nextRow = textBuffer.nextNonBlankRow(position.row)
    else
      nextRow = position.row + 1
    return null if not nextRow? or nextRow > textBuffer.getLineCount()
    position.row = nextRow
    position.column = 0
    position
