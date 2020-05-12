<#
Load all translation properties from translations.json into csv.
#>

$DATA_DIR = (get-item $PSScriptRoot).fullname 
$TRAN_URL = "https://github.com/brather1ng/RePoE/raw/master/RePoE/data/stat_translations.json"
$TRAN_DOWNLOAD = $DATA_DIR + "\stat_translations.json"
$TRANSLATION_RESULT_FILE = $DATA_DIR + "\temp_translations.csv"
(Get-Culture).NumberFormat.NumberDecimalSeparator = '.'

cls
"Loading JSON file.."
Invoke-WebRequest -Uri $TRAN_URL -OutFile $TRAN_DOWNLOAD
$stats_tran_json = Get-Content $TRAN_DOWNLOAD -raw | ConvertFrom-Json 
$all_trans = @()
if (test-path($TRANSLATION_RESULT_FILE)) {remove-item $TRANSLATION_RESULT_FILE}

$totalcount=$stats_tran_json.count

$mod_counter=0
foreach($stat in $stats_tran_json)
{
    $mod_counter+=1
    if (($mod_counter % 100) -eq 0) {"Processed " + $mod_counter.tostring()}
    $id_counter=0
    foreach ($id in $stat.ids)
    {
        #$id
        #foreach ($tran in $stats_tran_json.English)
        
            foreach($english in $stat.English)
            {
                if ($id -eq "dodge_attacks_and_spells_%_chance_if_have_been_hit_recently")
                {
                  #  pause
                }
                $min_max_counter=0
                foreach ($minmax in $english.condition)
                {
                    if ($min_max_counter -eq $id_counter)
                    {
                        $singular_tran = New-Object System.Object
                        $singular_tran | Add-Member -type NoteProperty -Name 'mod_id' -Value $mod_counter
                        $singular_tran | Add-Member -type NoteProperty -Name 'id' -Value $id
                        $singular_tran | Add-Member -type NoteProperty -Name 'id_count' -Value $stat.ids.count
                        $singular_tran | Add-Member -type NoteProperty -Name 'min' -Value $minmax.min
                        $singular_tran | Add-Member -type NoteProperty -Name 'max' -Value $minmax.max
                        $singular_tran | Add-Member -type NoteProperty -Name 'format' -Value $english.format[$min_max_counter]
                        $singular_tran | Add-Member -type NoteProperty -Name 'index_handler' -Value ($english.index_handlers[$min_max_counter] -join '-')
                        $singular_tran | Add-Member -type NoteProperty -Name 'string' -Value ($english.string -replace '\n',' ')
                        $all_trans+=$singular_tran
                    }
                    $min_max_counter+=1
                }
        }$id_counter+=1
    }
}
$all_trans | Export-csv -Delimiter ";" -literalpath $TRANSLATION_RESULT_FILE -NoTypeInformation
"Done"
[console]::beep(500,300)
get-date
