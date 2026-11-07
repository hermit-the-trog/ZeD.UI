#Requires -Version 7.0
# ZeDUI/tools/qa/batch_b6a_gallery_stage.ps1  (Nov 6 2026, QA): the Ranching pictures retaken on the hot fix (the save comes back after), then 0.3.0-beta6a staged and the true staged check.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "C:\Users\you\Zomboid"
$Shots = "$Z\Screenshots"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$KeepSave = "C:\Users\you\ZedQaSaveKeep_b6a"
if (Test-Path $KeepSave) { Write-Output "keep folder exists, stop"; exit 1 }
$Before = "$Shots\gallery_t14\_before_b6a"
New-Item -ItemType Directory -Force $Before | Out-Null
Copy-Item "$Shots\gallery_t14\gfr_ranch*.png" $Before -Force
Copy-Item "$Shots\gallery_t14\gfr_animal.png", "$Shots\gallery_t14\gfr_butcher.png" $Before -Force -ErrorAction SilentlyContinue
Copy-Item $Save $KeepSave -Recurse
try { & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\gallery_farm_ranch.txt" -Report "$Z\mods\ZeD-UI\ZeDUI\qa\regression\2026-11-06_b6a_gallery_ranch.md" 2>&1 | Select-Object -Last 1 }
finally { Remove-Item $Save -Recurse -Force -ErrorAction SilentlyContinue; Copy-Item $KeepSave $Save -Recurse; Remove-Item $KeepSave -Recurse -Force }
& pwsh -NoProfile -File "$Qa\batch_stage_true_b6a.ps1" 2>&1 | Select-Object -Last 3
