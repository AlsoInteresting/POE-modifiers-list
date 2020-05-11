# POE-modifiers-list
Generate flat file of POE item modifiers

This Powershell code gets all the Path Of Exile modifiers from the Brather1ng RePoe repository.
Order of execution

-import-translations.ps1
-import-base-item.ps1
-get-mods-from-json.ps1
-add-meta.ps1
-create-relation.ps1

The result:
- mods.csv: all modifiers strings with tiers, req. levels, influence,..
- base-items: all base items
- item-mods: the relation between the items and possible mods
