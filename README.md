# TYPO3 Fluid Autocomplete package

TYPO3 Fluid tag and inline notation autocompletions in Atom.

New language grammar can be used to determine the fluid element structure.
Element rules can be added to completions, so that suggestions can be made
dependend on element context (parent element, preceding sibling element).

Depends on [language-typo3-fluid](https://atom.io/packages/language-typo3-fluid).

Autocompletions come from JSON files in completions folder. These files get merged
[(see completions/index.coffee)](https://github.com/dokumediacoach/atom-autocomplete-typo3-fluid/blob/master/completions/index.coffee).  
More JSONs can be added for more Namespaces / Versions / ViewHelpers
[(see atom-typo3-fluid.dokumediacoach.de)](http://atom-typo3-fluid.dokumediacoach.de).
