# POE-modifiers-list
Generate a flat file of POE item modifiers to identify rare item modifiers.
Without maps,uniques and legacy items though.

This Powershell code gets all the Path Of Exile modifiers from the https://github.com/brather1ng/RePoE repository.

Order of execution:
- import-translations.ps1
- import-base-item.ps1
- get-mods-from-json.ps1
- add-meta.ps1
- create-relation.ps1

The result are flat files with columns:
- mods.csv: all modifiers strings with tiers, req. levels, influence,..
- base-items: all base items
- item-mods: the relation between the items and possible mods
