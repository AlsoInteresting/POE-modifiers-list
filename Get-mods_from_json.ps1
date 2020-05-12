<#
Read Repoe Docs on translations/mods to understand how the json needs to be parsed.
Load the mods.json file and put all useful properties into csv.

- For every id in stats.id in mods.json:
    - Look for the same id in translations.json
        - A set of translation id's has a set of corresponding conditions.
        - If a translation id doesn't exist as stats.id for that modifier, add a dummy to compare conditions
            For example BleedChanceAndDurationForJewel__.
            It has 2 stat.id's:
                - bleed_on_hit_with_attacks_%
                - base_bleed_duration_+%
            When looking up the English.String for bleed_on_hit_with_attacks_% in translations.json,
            it has 3 translation id's:
                - bleed_on_hit_with_attacks_%
                - global_bleed_on_hit
                - cannot_cause_bleeding
            So 2 dummy id's (global_bleed_on_hit, cannot_cause_bleeding) have to be added to compare conditions.
            Because global_bleed_on_hit, cannot_cause_bleeding don't exist as stat.id.
            The result is the first condition because 12 > stat.id min(1) and 16 > stat.id.max(99) AND other condition parts have min/max = 0.
        - If all conditions match for all translation id's for this lookup, get the English.String.
          This becomes the modifier string for that stat.id
#>


$DATA_DIR = (get-item $PSScriptRoot).fullname 
$MODS_URL = "https://github.com/brather1ng/RePoE/raw/master/RePoE/data/mods.json"
$MODS_DOWNLOAD = $DATA_DIR + "\mods.json"
$STATS_TRANSLATIONS_CSV=$DATA_DIR + "\temp_translations.csv"
$BASE_MODS = $DATA_DIR + "\temp_mods1.csv"
$INFLUENCE_LIST = @('_adjudicator','_basilisk','_crusader','_elder','_eyrie','_shaper')
(Get-Culture).NumberFormat.NumberDecimalSeparator = '.'

clear
"Loading json into memory.."
Invoke-WebRequest -Uri $MODS_URL -OutFile $MODS_DOWNLOAD
$mods_json = Get-Content $MODS_DOWNLOAD -raw |  ConvertFrom-Json
$stats_tran_csv = import-csv $STATS_TRANSLATIONS_CSV  -Delimiter ";"

function Modify_by_index_handler {
#recalculate min/max from mods.json with the index handler from translations.json
param( [string]$index_handler, [single]$str_figure)
    switch ($index_handler)
    {
        '30%_of_value' {$singular_tran.min=$str_figure*0.3;break}
        '60%_of_value' {$str_figure=$str_figure*0.6;break}
        'divide_by_one_hundred' {$str_figure=$str_figure*0.01;break}
        'divide_by_one_hundred_and_negate' {$str_figure=$str_figure*-0.01;break}
        'divide_by_one_hundred_2dp' {$str_figure=[math]::Round($str_figure*0.01,2);break}
        'milliseconds_to_seconds' {$str_figure=$str_figure*0.001;break}
        'milliseconds_to_seconds_0dp' {$str_figure=[math]::Round($str_figure*0.001,0);break}
        'milliseconds_to_seconds_1dp' {$str_figure=[math]::Round($str_figure*0.001,1);break}
        'milliseconds_to_seconds_2dp' {$str_figure=[math]::Round($str_figure*0.001,2);break}
        'milliseconds_to_seconds_2dp_if_required' {$str_figure=[math]::Round($str_figure*0.001,2);break}
        'multiplicative_damage_modifier' {$str_figure=$str_figure*0.6;break}
        'multiplicative_permyriad_damage_modifier' {$str_figure=$str_figure/100+100;break}
        'negate' {$str_figure=-$str_figure;break}
        'old_leech_percent' {$str_figure=$str_figure*0.5;break}
        'old_leech_permyriad' {$str_figure=$str_figure*0.05;break}
        'per_minute_to_per_second' {$str_figure=$str_figure/60;break}
        'per_minute_to_per_second_0dp' {$str_figure=[math]::Round($str_figure/60,0);break}
        'per_minute_to_per_second_1dp' {$str_figure=[math]::Round($str_figure/60,1);break}
        'per_minute_to_per_second_2dp' {$str_figure=$str_figure/60;break}
        'per_minute_to_per_second_2dp_if_required' {$str_figure=[math]::Round($str_figure/60,2);break}
        'divide_by_two_0dp' {$str_figure=[math]::Round($str_figure*0.5,0);break}
        'divide_by_six' {$str_figure=$str_figure/6;break}
        'divide_by_ten_0dp' {$str_figure=[math]::Round($str_figure*0.1,0);break}
        'divide_by_twelve' {$str_figure=$str_figure/12;break}
        'divide_by_fifteen_0dp' {$str_figure=[math]::Round($str_figure/15,0);break}
        'divide_by_twenty_then_double_0dp' {$str_figure=$str_figure*0.1;break}
        'times_twenty' {$str_figure=$str_figure*20;break}
    }
    return $str_figure
}



"Iterating through mods.."
$counter =0
$totalmods = ($mods_json | Get-Member -MemberType *Property).count
get-date
$all_mods = @()
#$mods_json |  Get-Member -MemberType *Property | where { $_.Name -eq "AddedColdDamagePerDexterityTwoHandInfluence1" } | % {
#$mods_json |  Get-Member -MemberType *Property | where { $_.Name -like "A*" } | % {
$mods_json |  Get-Member -MemberType *Property | % {
    $mod_name = $_.name
      
    #Only non-uniques and not maps
    if ($mods_json.($_.name).generation_type -ne "unique" -and $mods_json.($_.name).domain -ne "Area" )
    {
        #get-date
        $counter+=1
        $_.name
        $tags = @()
        $tags_without_influence= @()
        $influences = @()
        foreach ($tag_weight in $mods_json.($_.name).spawn_weights)
        {
            if ($tag_weight.weight -gt 0)
            {
                $tags+=$tag_weight.tag
                if (($INFLUENCE_LIST | %{$tag_weight.tag.contains($_)}) -contains $true)
                {
                    $influences +=$tag_weight.tag.substring($tag_weight.tag.lastIndexOf('_')+1,$tag_weight.tag.length -$tag_weight.tag.lastIndexOf('_')-1)
                    $tags_without_influence += $tag_weight.tag -replace ($tag_weight.tag.Substring($tag_weight.tag.lastIndexOf('_')),'')
                }
                else
                {
                    $tags_without_influence +=$tag_weight.tag
                }
            }
        }
        $influences = $influences | sort-object -unique
        foreach ($tag in $mods_json.($_.name).adds_tags)
        {
            $tags+=$tag
        }
        
        #if ($counter -gt 10) {get-date;return}
        foreach ($stat in $mods_json.($_.name).stats | where-object {-not ($_.min -eq 0 -and $_.max -eq 0)} )
        {
            "  stat id: " + $stat.id
            $string=""
            $arr_trans = ($stats_tran_csv| where id -eq $stat.id)
            $arr_trans_total=($arr_trans | measure).count
            #if a english translation has multiple id's get them all
            if ($arr_trans_total -gt 0 -and $tags.Count -gt 0)
            {
                if ($arr_trans_total -eq 1)
                #There exists just one English set. No comparison necessary. Just take that string.
                    {
                        $string = $arr_trans[0].string
                        $format = $arr_trans.format -Join ","
                        #$arr_trans
                        if ($arr_trans.index_handler.length -gt 0)
                        {
                            $stat.min = Modify_by_index_handler $arr_trans.index_handler $stat.min
                            $stat.max = Modify_by_index_handler $arr_trans.index_handler $stat.max
                        }
                        #"  single condition: " + $string
                    }
                else
                {
                    #Compare conditions for ALL translations id's with ALL stat id's
                    $arr_new_trans = ($stats_tran_csv| where mod_id -eq $arr_trans[0].mod_id)
                    $id_count = $arr_new_trans[0].id_count
                    $arr_new_stat = $mods_json.($_.name).stats
                    [PSObject[]]$arr_common_stat_ids=@()
                    $arr_common_stat_ids = ($arr_new_stat| Where-Object { $_.id -in $arr_new_trans.id} ) | select-object id, max, min
                     
                    #If a id from the stat.id's is missing in translations id, add it to the mods ids with zeroes as min/max.
                    #Just to get it comparing with translation id's
                    foreach ($missing in ($arr_new_trans.id | Where-Object { $_ -notin $arr_new_stat.id} | unique))
                    {
                        $obj = New-Object -TypeName PSObject
			            $obj | Add-Member -MemberType NoteProperty -Name id -Value $missing
			            $obj | Add-Member -MemberType NoteProperty -Name max -Value 0
			            $obj | Add-Member -MemberType NoteProperty -Name min -value 0
                        $arr_common_stat_ids+=$obj
			        }
                    #=> result= all stat_id's that are in tran_id's + zero values for every tran_id missing in stat_id
                   
                    #for a mod with 2 tranlation_id's and 4 conditions, 8 lines exist in the translations csv.
                    #Traverse the conditions in this order: 0,4,1,5,2,6,3,7
                    #Whenever 2 (=id_count=translation id's) sequential matches are found, the string is found. Exit the loop.
                    $condition_counter=0
                    do {
                        $trans_id_counter=0
                        $combination_of_conditions_counter=0
                        do {
                                
                            $calc_counter=$condition_counter+($trans_id_counter*(($arr_new_trans | measure).count/$id_count))
                            if (($arr_new_trans[$calc_counter].min -eq "" -or [int]$arr_new_trans[$calc_counter].min -le [int]($arr_common_stat_ids | Where-Object -Property id -eq $arr_new_trans[$calc_counter].id)[0].min) `
                            -and  ($arr_new_trans[$calc_counter].max -eq "" -or [int]$arr_new_trans[$calc_counter].max -ge [int]($arr_common_stat_ids | Where-Object -Property id -eq $arr_new_trans[$calc_counter].id)[0].max))
                            {
                                $combination_of_conditions_counter+=1
                            } 
                            $trans_id_counter+=1      
                        } 
                        until ($trans_id_counter -ge ($arr_common_stat_ids | measure).count)
                        $condition_counter+=1
                    }
                    until (($condition_counter -ge ($arr_new_trans | measure).count/$id_count) -or $combination_of_conditions_counter -eq $id_count)
                    if ($combination_of_conditions_counter -eq $id_count)
                    #combination of all conditions is true
                    {
                        $string=$arr_new_trans[$calc_counter].string
                        $found_mod = $arr_new_trans | ? {$_.string -eq $string -and $_.id -eq $stat.id} 
                        $format=$($found_mod | select-object format)[0].format
                        $index_handler=$($found_mod | select-object index_handler)[0].index_handler
                        if ($index_handler.length -gt 0)
                        {
                            $stat.min = Modify_by_index_handler $index_handler $stat.min
                            $stat.max = Modify_by_index_handler $index_handler $stat.max
                        }
                        #"  multiple condition: " + $string
                    }
                    else
                    {
                        "Stat id not found:" + $stat.id
                        "On modifier " + $mod_name
                        #pause
                    }
                  
                }
                #avoid unused mods
                if (-not ($stat.min -eq 0 -and $stat.max -eq 0))
                {
                    $singular_mod = [PSCustomObject]@{
                        Name = $mod_name
                        Description  = $mods_json.($_.name).name
                        Domain=($mods_json.($_.name).domain).tolower()
                        Generation_type=$mods_json.($_.name).generation_type
                        Group=$mods_json.($_.name).group
                        Tags=$tags -join ','
                        Tags_without_influence= $tags_without_influence -join ','
                        Influences = $influences -join ','
                        Hybrid=''
                        IsEssenceOnly=$mods_json.($_.name).is_essence_only
                        Required_level=$mods_json.($_.name).required_level
                        Type=$mods_json.($_.name).type
                        Stat_ID=$stat.id
                        Stat_min=$stat.min
                        Stat_max=$stat.max
                        Format=$format
                        String=$string
                    }
                    $all_mods += $singular_mod
                }
            }
        }
    }
    
}
get-date
"Putting on hybrid numbers.."
#Hybrid mods:
# Get distinct modname, string
# From this, only get the groups with the same modifier name but different strings
$hybrid_mods = $all_mods | select name,string | sort-object -Property name,string -Unique | Group-Object name | Sort-Object name | Select-Object Name, Count | where count -gt 1
$hybrid_counter=0
#Give all different stat modifiers that belong to the same hybrid, the same hybrid name
foreach($mod in $all_mods.where{($hybrid_mods.name -contains $_.name)})
{
    if ($preceding_modifier -ne $mod.name)
    {
        $hybrid_counter+=1
    }
    $mod.hybrid = "H" + $hybrid_counter.Tostring()
    $preceding_modifier = $mod.name
} 
$all_mods | Export-csv -Delimiter ";" -literalpath $BASE_MODS -NoTypeInformation
"Done."
[console]::beep(500,300)
get-date
