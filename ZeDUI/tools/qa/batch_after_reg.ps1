#Requires -Version 7.0
# ZeDUI/tools/qa/batch_after_reg.ps1  (Nov 6 2026, QA): after the full regression: the auto-collapse, the one failed script again, the real drag, the ticket pad walk, then
# Roadworthy with the game's mod list read first and the console kept.
$Qa = $PSScriptRoot
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
Copy-Item "C:\Users\you\Zomboid\console.txt" "$Keep\console_roadworthy.txt" -Force
