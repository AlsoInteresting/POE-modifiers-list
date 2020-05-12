$DATA_DIR = (get-item $PSScriptRoot).fullname 
$BASE_ITEMS_URL = "https://github.com/brather1ng/RePoE/raw/master/RePoE/data/base_items.json"
$BASE_ITEMS_DOWNLOAD = $DATA_DIR + "\base_items.json"
$BASE_MODIFIER_RESULT_FILE = $DATA_DIR + "\temp_base_items.csv"
(Get-Culture).NumberFormat.NumberDecimalSeparator = '.'

clear
"Loading JSON file.."
Invoke-WebRequest -Uri $BASE_ITEMS_URL -OutFile $BASE_ITEMS_DOWNLOAD
$base_json = Get-Content $BASE_ITEMS_DOWNLOAD -raw |  ConvertFrom-Json
"Iterating through JSON file.."
$all_bases = @()
if (test-path($BASE_MODIFIER_RESULT_FILE)) {remove-item $BASE_MODIFIER_RESULT_FILE}
$mod_counter =0
$base_json | Get-Member -MemberType *Property | % {
    if ($base_json.($_.name).domain -eq "item" -and ($base_json.($_.name).release_state -ne "legacy"))
    {

        $item_class_req =""
        $item_class = ($base_json.($_.name).item_class).tolower()
        $attack_second =  $base_json.($_.name).properties.attack_time
        if ($attack_second.length -gt 0)
        {
            $attack_second = $attack_second/1000
        }
        $critical_chance = $base_json.($_.name).properties.critical_strike_chance
        if ($critical_chance.length -gt 0)
        {
            $critical_chance = $critical_chance/100
        }
        $tags=@()
        foreach ($tag in $base_json.($_.name).tags)
        {
            $tags+=$tag
        }
        $singular_base = New-Object System.Object
        $singular_base | Add-Member -type NoteProperty -Name 'item_class' -Value $item_class
        $singular_base | Add-Member -type NoteProperty -Name 'name' -Value $base_json.($_.name).name
        $singular_base | Add-Member -type NoteProperty -Name 'tags' -Value ($tags -join ",")
        $singular_base | Add-Member -type NoteProperty -Name 'armour' -Value $base_json.($_.name).properties.armour
        $singular_base | Add-Member -type NoteProperty -Name 'movement speed' -Value $base_json.($_.name).properties.movement_speed
        $singular_base | Add-Member -type NoteProperty -Name 'energy shield' -Value $base_json.($_.name).properties.energy_shield
        $singular_base | Add-Member -type NoteProperty -Name 'evasion rating' -Value $base_json.($_.name).properties.evasion
        $singular_base | Add-Member -type NoteProperty -Name 'chance to block' -Value $base_json.($_.name).properties.block
        $singular_base | Add-Member -type NoteProperty -Name 'attacks per second' -Value $attack_second
        $singular_base | Add-Member -type NoteProperty -Name 'critical strike chance' -Value $critical_chance
        $singular_base | Add-Member -type NoteProperty -Name 'physical damage min' -Value $base_json.($_.name).properties.physical_damage_min
        $singular_base | Add-Member -type NoteProperty -Name 'physical damage' -Value $base_json.($_.name).properties.physical_damage_max
        $singular_base | Add-Member -type NoteProperty -Name 'weapon range' -Value $base_json.($_.name).properties.range
        $singular_base | Add-Member -type NoteProperty -Name 'dexterity' -Value ($base_json.($_.name).requirements.dexterity)
        $singular_base | Add-Member -type NoteProperty -Name 'intelligence' -Value ($base_json.($_.name).requirements.intelligence)
        $singular_base | Add-Member -type NoteProperty -Name 'strength' -Value ($base_json.($_.name).requirements.strength)
        $singular_base | Add-Member -type NoteProperty -Name 'level' -Value ($base_json.($_.name).requirements.level)
        if ($base_json.($_.name).requirements.dexterity -gt 0) {$item_class_req += "dex"}
        if ($singular_base.intelligence -gt 0) {$item_class_req += "int"}
        if ($singular_base.strength -gt 0) {$item_class_req += "str"}
        $singular_base | Add-Member -type NoteProperty -Name 'item_class_req' -Value $item_class_req
        $modifier_counter +=1
        $all_bases += $singular_base
    }
}
$all_bases | sort item_class,name,tags -unique| Export-csv -Delimiter ";" -literalpath $BASE_MODIFIER_RESULT_FILE -NoTypeInformation
"Done."
[console]::beep(500,300)
get-date