#Requires -Version 7.0
# ZeDUI/tools/qa/batch_dash_odo.ps1  (Nov 6 2026, QA): the dash scripts over the Dash Elite odometer fix.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\tickets_20261105.txt")
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
$o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\dash_odo.txt" -Report ([IO.Path]::GetFullPath("$Qa\..\..\qa\regression\2026-11-06_dash_odo.md")) 2>&1
Note "dash odo : $(($o | Select-Object -Last 1) -join ' ')"
