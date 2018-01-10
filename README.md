# TYPO3 Fluid Autocomplete package

TYPO3 Fluid tag and inline notation autocompletions in Atom.

Depends on [language-typo3-fluid](https://atom.io/packages/language-typo3-fluid).

Autocompletions come from JSON files in completions folder. These files get merged.  
More JSONs can be added for more Namespaces / Versions / ViewHelpers
[(see atom-typo3-fluid.dokumediacoach.de)](http://atom-typo3-fluid.dokumediacoach.de).

Starting with Version 0.3 this package gets activated only when language-typo3-fluid grammar is used
(TYPO3 Fluid file is openend in Atom) to reduce Atom startup time when not needed.

Version 0.3 contains a lot of fixes of things that did not work as intended, like
autocompletions in html tag.

Version 0.3 also brings better performance by a new approach to merge completions
[(see lib/completions-collector.coffee)](https://github.com/dokumediacoach/atom-autocomplete-typo3-fluid/blob/master/lib/completions-collector.coffee).

Starting with version 0.2 element rules can be added to completions, so that
suggestions can be made dependend on element context (parent element, preceding
sibling element).
