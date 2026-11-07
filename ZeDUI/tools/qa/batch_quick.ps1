#Requires -Version 7.0
# ZeDUI/tools/qa/batch_quick.ps1  (Nov 7 2026, QA): one manifest at 4K with the QA save put back after. -Manifest name.txt -Tag report name.
param([string]$Manifest, [string]$Tag)
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "C:\Users\danie\Zomboid"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$KeepSave = "C:\Users\danie\ZedQaSaveKeep_quick"
if (Test-Path $KeepSave) { Write-Output "keep folder exists, stop"; exit 1 }
Copy-Item $Save $KeepSave -Recurse
try { & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\$Manifest" -Report "$Z\mods\ZeD-UI\ZeDUI\qa\regression\2026-11-07_$Tag.md" -Mode fullscreen4k 2>&1 | Select-Object -Last 1 }
finally { Remove-Item $Save -Recurse -Force -ErrorAction SilentlyContinue; Copy-Item $KeepSave $Save -Recurse; Remove-Item $KeepSave -Recurse -Force }
