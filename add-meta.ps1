<#
Add meta data to the temporary mods csv file.
Add the full format string like it is presented on POE items.
    Stat id's from the mods json file contain a range or a single figure.
    If more than 2 figures are needed to present a string, another stat id is used.
    - no number
    - 1 number: 
        Damage Penetrates 2% Elemental Resistance if you haven't Killed Recently
    - 2 numbers:
        Example: (9 - 10)% chance to Avoid being Frozen
        Example: Adds 1 to 3 Physical Damage to Attacks
    - 3 numbers:
        Example: Adds 1 to (19 - 20) Lightning Damage to Axe Attacks
    - 4 numbers:
        #Example: Adds (10 - 12) to (21 - 24) Fire Damage to Attacks

    The field "Sign" is used to represent negative or positive values used

Add tiers to the temporary mods file
    For all non-hybrid modifiers, go over the mods file backwards.
    If the modifier before the current has the same tags, string,sign and domain then it belongs to the same range of modifiers.
    For Hybrid modifiers, go over the mods file backwars but grouped by hybrid.
#>

$DATA_DIR = (get-item $PSScriptRoot).fullname 
$TEMP_MODS = $DATA_DIR + "\temp_mods1.csv"
$TEMP_MODS2 = $DATA_DIR + "\temp_mods2.csv"
$TIERS = $DATA_DIR + "\mods.csv"
(Get-Culture).NumberFormat.NumberDecimalSeparator = '.'


function Format_figure {
param( [string]$format, [string]$str_figure)
    switch ($format)
    {
        '#' {break}
        'ignore' {break}
        '#%' {$str_figure=$str_figure + '%';break}
        '+#' {$str_figure='+' + $str_figure;break}
        '+#%' {$str_figure='+' + $str_figure + '%';break}
    }
    return $str_figure
}

clear
"Loading Files.."
$TEMP_MODS_csv = import-csv $TEMP_MODS -Delimiter ";"


"Grouping by name,string.."
#$groups = import-csv $TEMP_MODS -Delimiter ";" | where-object {($_.Name -eq 'ArmourPenetrationInfluence1')} | Group-Object Name,string
#$groups = import-csv $TEMP_MODS -Delimiter ";" |  where-object {($_.Name -like 'A*')} | Group-Object Name,string
$groups = import-csv $TEMP_MODS -Delimiter ";" | Group-Object Name,string
$all_mods = @()
"Traversing, adding formatted string,Sign,Min1,Max1,Min2,Max2.."
foreach ($group in $groups)
{
    $formatted_string=""
    if ([int]$($group).Group[0].Stat_min -ge 0)
    {
        $posneg="positive"
    }
    else
    {
        $posneg="negative"
    }
    if  ($group.count  -eq 1)
    {
        #Example: Damage Penetrates 2% Elemental Resistance if you haven't Killed Recently
        if ($($group).Group[0].Stat_min -eq $($group).Group[0].Stat_max)
        {
            if ([single]$($group).Group[0].Stat_min -gt 0)
            {
                $replace_0 = Format_figure $($group).Group[0].format ($($group).Group[0].Stat_min)
                $replace_1 = Format_figure $($group).Group[0].format ($($group).Group[0].Stat_max)
            }
            else
            {
                $replace_0 = Format_figure $($group).Group[0].format ([System.Math]::Abs($($group).Group[0].Stat_min))
                $replace_0 = $replace_0 -replace '\+','-'
                $replace_1 = Format_figure $($group).Group[0].format ([System.Math]::Abs($($group).Group[0].Stat_max))
                $replace_1 = $replace_1 -replace '\+','-'
            }
            $formatted_string = $($group).Group[0].String -replace ( '\{0\}',$replace_0 ) -replace ('\{1\}',$replace_1 )
        }
        #Example: (9 - 10)% chance to Avoid being Frozen
        else
        {
            $replace_0 =  Format_figure $($group).Group[0].format ('(' + ([System.Math]::Abs($($group).Group[0].Stat_min))  + ' - ' +  ([System.Math]::Abs($($group).Group[0].Stat_max)) + ')')
            if ([single]$($group).Group[0].Stat_min -gt 0)
            {
                $formatted_string = $($group).Group[0].String -replace ( '\{0\}',$replace_0 ) 
            }
            else
            {
                $replace_0 = $replace_0 -replace '\+','-'
                $formatted_string =  $($group).Group[0].String -replace ( '\{0\}',$replace_0 ) 
            }
        }
        $min1=$($group).Group[0].Stat_min
        $max1=$($group).Group[0].Stat_max
        $min2=""
        $max2=""
    }
    else
    {
        if ($($group).Group[0].Stat_min -eq $($group).Group[0].Stat_max)
        {
            #Example: Adds 1 to 3 Physical Damage to Attacks
            if ([single]$($group).Group[1].Stat_min -eq $($group).Group[1].Stat_max)
            {
                if ($($group).Group[0].Stat_min -gt 0)
                {
                    $replace_0 = Format_figure $($group).Group[0].format $($group).Group[0].Stat_max  
                    $replace_1 = Format_figure $($group).Group[1].format $($group).Group[1].Stat_max  
                }
                else
                {
                    $replace_0 = Format_figure $($group).Group[0].format ([System.Math]::Abs($($group).Group[0].Stat_min))
                    $replace_0 = $replace_0 -replace '\+','-'
                    $replace_1 = Format_figure $($group).Group[1].format ([System.Math]::Abs($($group).Group[1].Stat_max))
                    $replace_1 = $replace_1 -replace '\+','-'
                }
                $min1=$($group).Group[0].Stat_min
                $max1=""
                $min2=$($group).Group[1].Stat_min
                $max2=""  
            }
            else
            #Example: Adds 1 to (19 - 20) Lightning Damage to Axe Attacks
            {
             
                $replace_0 = Format_figure $($group).Group[0].format $($group).Group[0].Stat_max  
                $replace_1 = Format_figure $($group).Group[1].format ('(' + $($group).Group[1].Stat_min  + ' - ' +  $($group).Group[1].Stat_max) + ')'

                $min1=$($group).Group[0].Stat_min
                $max1=""
                $min2=$($group).Group[1].Stat_min
                $max2=$($group).Group[1].Stat_max
            }
        }
        else
        {
            #Example: Adds (10 - 12) to (21 - 24) Fire Damage to Attacks
            $replace_0 =  Format_figure $($group).Group[0].format ('(' + [System.Math]::Abs($($group).Group[0].Stat_min)  + ' - ' +  [System.Math]::Abs($($group).Group[0].Stat_max) + ')')
            $replace_1 =  Format_figure $($group).Group[0].format ('(' + [System.Math]::Abs($($group).Group[1].Stat_min)  + ' - ' +  [System.Math]::Abs($($group).Group[1].Stat_max) + ')')
            $min1=$($group).Group[0].Stat_min
            $max1=$($group).Group[0].Stat_max
            $min2=$($group).Group[1].Stat_min
            $max2=$($group).Group[1].Stat_max
        }
        $formatted_string = $($group).Group[0].String -replace ( '\{0\}',$replace_0 ) -replace ('\{1\}',$replace_1 )
    }
    

    $singular_mod = [PSCustomObject]@{
        Name = $($group).Group[0].name
        Description  = $($group).Group[0].description
        Domain=$($group).Group[0].domain
        Generation_type=$($group).Group[0].Generation_type
        Group=$($group).Group[0].Group
        Tags=$($group).Group[0].tags
        Tags_without_influence= $($group).Group[0].Tags_without_influence
        Influences = $($group).Group[0].Influences
        Hybrid=$($group).Group[0].Hybrid
        IsEssenceOnly=$($group).Group[0].IsEssenceOnly
        Required_level=$($group).Group[0].Required_level
        Type=$($group).Group[0].Type
        Stat_ID=$($group).Group[0].Stat_ID
        Sign=$posneg
        Min1=$min1
        Max1=$max1
        Min2=$min2
        Max2=$max2
        String=$($group).Group[0].string
        Format_String=$formatted_string
        }
    $all_mods += $singular_mod
} 
$all_mods | Export-csv -Delimiter ";" -literalpath $TEMP_MODS2 -NoTypeInformation
pause


clear
"Loading Files to add tiers.."
Import-Csv $TEMP_MODS2 -Delimiter ";" | 
Select-Object *,@{Name='Tier';Expression={0}} | 
Export-Csv -Delimiter ";" -literalpath $TIERS -NoTypeInformation

$csv_lines = import-csv $TIERS -Delimiter ";" 
$csv_lines_hybrid = import-csv $TIERS -Delimiter ";" | where-object {($_.hybrid -like "H*")} 

$csv_lines_without_hybrid = import-csv $TIERS -Delimiter ";" | where-object {($_.hybrid -notlike "H*")} | sort -property domain, sign, tags,string,@{Expression = { [Math]::Abs([single]$_.Min1) }}

"Adding tiers for non-hybrid modifiers.."
$mod_counter=0
For ($i=($csv_lines_without_hybrid | measure).count-2; $i -ge 0; $i--) 
{
    $mod_counter+=1
    if (($mod_counter % 100) -eq 0) {"Processed " + $mod_counter.tostring()}
    if ($csv_lines_without_hybrid[$i].string -eq $csv_lines_without_hybrid[$i+1].string `
    -and $csv_lines_without_hybrid[$i].tags -eq $csv_lines_without_hybrid[$i+1].tags `
    -and $csv_lines_without_hybrid[$i].Domain -eq $csv_lines_without_hybrid[$i+1].Domain `
    -and [Math]::Abs([single][single]$csv_lines_without_hybrid[$i].Min1) -lt [Math]::Abs([single]$csv_lines_without_hybrid[$i+1].Min1)
    <#-and ( `
        ($csv_lines_without_hybrid[$i].sign -eq 'positive' `
        -and [single]$csv_lines_without_hybrid[$i].Min1 -lt [single]$csv_lines_without_hybrid[$i+1].Min1) `
        -or `
        ($csv_lines_without_hybrid[$i].sign -eq 'negative' `
        -and [single]$csv_lines_without_hybrid[$i].Min1 -gt [single]$csv_lines_without_hybrid[$i+1].Min1) `
        )`#>
    )
    {
        $tier+=1
    }
    else
    {
        $tier=1
    }
    $csv_lines_without_hybrid[$i].tier = $tier
}
 

"Adding tiers on hybrid modifiers temp file.."
$mod_counter=0
$groups_hybrid = import-csv $TIERS -Delimiter ";" | where-object {($_.hybrid -like "H*")} |sort -property domain, sign, tags,string,@{Expression = {  [Math]::Abs([single]$_.Min1) }} | group-object hybrid
$all_hybrids=@()
For ($i=($groups_hybrid | measure).count-2; $i -ge 0; $i--) 
{
    $mod_counter+=1
    if (($mod_counter % 100) -eq 0) {"Processed " + $mod_counter.tostring()}
    if ($groups_hybrid[$i].group[0].string -eq $groups_hybrid[$i+1].group[0].string `
    -and $groups_hybrid[$i].group[0].tags -eq $groups_hybrid[$i+1].group[0].tags `
    -and $groups_hybrid[$i].group[0].Domain -eq $groups_hybrid[$i+1].group[0].Domain  `
    -and [Math]::Abs([single]$groups_hybrid[$i].group[0].Min1) -lt [Math]::Abs([single]$groups_hybrid[$i+1].group[0].Min1)
    <#-and ( `
        ($groups_hybrid[$i].group[0].sign -eq 'positive' `
        -and [single]$groups_hybrid[$i].group[0].Min1 -lt [single]$groups_hybrid[$i+1].group[0].Min1) `
        -or `
        ($groups_hybrid[$i].group[0].sign -eq 'negative' `
        -and [single]$groups_hybrid[$i].group[0].Min1 -gt [single]$groups_hybrid[$i+1].group[0].Min1) `
        )` #>
    )
    {
        $tier+=1
    }
    else
    {
        $tier=1
    }
    $singular_hybrid = [PSCustomObject]@{
        Hybrid = $groups_hybrid[$i].Name
        Tier = $tier}
    $all_hybrids += $singular_hybrid
}

"Adding tiers from hybrids temp file to mods file.."
$mod_counter=0
foreach ($group in $all_hybrids )
{
    $mod_counter+=1
    if (($mod_counter % 100) -eq 0) {"Processed " + $mod_counter.tostring()}
    foreach($line in $csv_lines_hybrid |  where-object {($_.hybrid -eq $group.hybrid)})
    {
        $line.tier = $group.tier        
    }
}

($csv_lines_hybrid + $csv_lines_without_hybrid) | Export-csv -Delimiter ";" -literalpath $TIERS -NoTypeInformation


"Done."
[console]::beep(500,300)
get-date

