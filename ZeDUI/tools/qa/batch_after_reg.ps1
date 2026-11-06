#Requires -Version 7.0
# ZeDUI/tools/qa/batch_after_reg.ps1  (Nov 6 2026, QA): after the full regression: the auto-collapse, the one failed script again, the real drag, the ticket pad walk, then
# Roadworthy with the game's mod list read first and the console kept.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
# (with no Steam the Workshop folder isn't read: the mods under test are copied in for the run, and taken out at its end)
$Wk = "E:\Project Zomboid\steamapps\workshop\content\108600"
$Mods = "C:\Users\you\Zomboid\mods"
$Copied = @()
foreach ($id in 3828608843, 3828607335, 3414634809, 3814843526) {
    foreach ($d in Get-ChildItem "$Wk\$id\mods" -Directory) {
        if (-not (Test-Path "$Mods\$($d.Name)")) { Copy-Item $d.FullName "$Mods\$($d.Name)" -Recurse; $Copied += "$Mods\$($d.Name)" }
    }
}
$Rep = [IO.Path]::GetFullPath("$Qa\..\..\qa\regression")
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\tickets_20261105.txt")
$Keep = Join-Path $env:TEMP "zedqa_mp_keep_tk"
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
function Run($m, $tag) { $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\$m" -Report "$Rep\2026-11-06_$tag.md" 2>&1; Note "$tag : $(($o | Select-Object -Last 1) -join ' ')" }
Run "autocollapse.txt" "autocollapse"
Run "cx_again.txt" "cx_again"
$o = & "$Qa\batch_drag.ps1" 2>&1; Note "drag : $(($o | Select-Object -Last 1) -join ' ')"
& "$Qa\batch_tickets.ps1" -Runs "mp_tk_pad.txt:tk_pad5:1280:800"
$o = & "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\roadworthy_mods.txt" -Mode fullscreen4k -Manifest "$Qa\roadworthy_list_manifest.txt" 2>&1
Note "roadworthy : $(($o | Select-Object -Last 1) -join ' ')"
$o = & "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\spncc_long_mods.txt" -Mode fullscreen4k -Manifest "$Qa\spncc_long_manifest.txt" 2>&1
Note "spncc in game : $(($o | Select-Object -Last 1) -join ' ')"
Copy-Item "C:\Users\you\Zomboid\console.txt" "$Keep\console_roadworthy.txt" -Force
foreach ($c in $Copied) { Remove-Item $c -Recurse -Force }
Note "the copied mods taken out"
