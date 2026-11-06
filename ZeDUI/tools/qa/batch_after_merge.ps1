#Requires -Version 7.0
# ZeDUI/tools/qa/batch_after_merge.ps1  (Nov 6 2026, QA): after Build's merge: FAIV's checks and the auto-collapse, the real drag, the ticket pad walk, Spongie's in game.
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\tickets_20261105.txt")
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
$o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\faiv_after.txt" -Report ([IO.Path]::GetFullPath("$Qa\..\..\qa\regression\2026-11-06_faiv2.md")) 2>&1
Note "faiv : $(($o | Select-Object -Last 1) -join ' ')"
$o = & "$Qa\batch_drag.ps1" 2>&1; Note "drag : $(($o | Select-Object -Last 1) -join ' ')"
& "$Qa\batch_tickets.ps1" -Runs "mp_tk_pad.txt:tk_pad4:1280:800"
$o = & "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\spncc_long_mods.txt" -Mode fullscreen4k -Manifest "$Qa\spncc_long_manifest.txt" 2>&1
Note "spncc in game : $(($o | Select-Object -Last 1) -join ' ')"
