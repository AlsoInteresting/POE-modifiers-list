$DATA_DIR = (get-item $PSScriptRoot).fullname 
$MODS = $DATA_DIR + "\MODS.csv"
$ITEMS = $DATA_DIR + "\temp_base_items.csv"
$ITEMS2 = $DATA_DIR + "\temp_base_items2.csv"
$RESULT_ITEMS = $DATA_DIR + "\base_items.csv"
$RELATION = $DATA_DIR + "\item_mods.csv"
(Get-Culture).NumberFormat.NumberDecimalSeparator = '.'

clear
"Loading files.."
$mod_lines = import-csv $MODS -Delimiter ";"
$item_lines = import-csv $ITEMS -Delimiter ";"

$unique_tags=@() 
$unique_item_tag_combination = $item_lines | select tags | sort tags -Unique


"Writing temp tag files"
foreach ($tags in $unique_item_tag_combination)
{
    $unique_tags+= ($tags.tags -split ",")
}

$unique_tags  = $unique_tags | Sort-Object -Unique

$tagscounter=1
foreach ($tag in $unique_tags)
{
    "Tag "+ $tag
    $all_mods = @() 
    #foreach ($mod in $mod_lines  | where-object {($_.name -eq 'AdditionalPierceInfluence1')})
    foreach ($mod in $mod_lines)
    {
        if (($mod.Tags_without_influence -split ",").contains($tag))
        {
                $singular_mod = [PSCustomObject]@{
                Item_Tag = $tag
                ModName = $mod.name
                Influence=''
            }
            $all_mods += $singular_mod
            if ($mod.influences.length -gt 0)
            {
                foreach ($influence in ($mod.influences -split ","))
                {
                    $singular_mod = [PSCustomObject]@{
                        Item_Tag = $tag
                        ModName = $mod.name
                        Influence=$influence
                    }
                    $all_mods += $singular_mod
                }
            }
        }
    } 
    $tagscounter+=1
    $all_mods | Export-csv -Delimiter ";" -literalpath ($DATA_DIR + "\temp_tag_" + $tag + ".csv") -NoTypeInformation
}

"Combining tags per tag combination.."
$all_mods = @() 
$tags_counter =1

#add field item_tags_combination
Import-Csv $ITEMS -Delimiter ";" | Select-Object *,@{Name='item_tags_combination';Expression={0}} | Export-Csv -Delimiter ";" -literalpath $ITEMS2 -NoTypeInformation
$all_items = Import-Csv $ITEMS2 -Delimiter ";"

foreach ($tags in $unique_item_tag_combination)
{
    $tags  
    $all_tags = @() 
    foreach ($item_tag in ($tags.tags -split ","))
    {
        $all_tags += @(Import-Csv -Delimiter ";" -literalpath ($DATA_DIR + "\temp_tag_" + $item_tag + ".csv"))
    }
   
    $all_tags = ($all_tags |  Select-Object @{Name='item_tags_combination';Expression={$tags_counter}},@{Name='Tags';Expression={$tags.tags}},*)
    $all_mods = $all_mods + $all_tags
    foreach ($item in $all_items | where-object {($_.tags -eq $tags.tags)})
    {
        $item.item_tags_combination = $tags_counter
    }
    $tags_counter +=1
}
$all_mods | Export-csv -Delimiter ";" -literalpath $RELATION -NoTypeInformation
$all_items | Export-csv -Delimiter ";" -literalpath $RESULT_ITEMS -NoTypeInformation
remove-item $ITEMS2

"Deleting temp files.."
foreach ($tag in $unique_tags)
{
    remove-item ($DATA_DIR + "\temp_tag_" + $tag + ".csv")
}

"Done."
[console]::beep(500,300)
get-date

