#Requires -Version 7.0
# ZeDUI/tools/qa/batch_card_real.ps1  (Nov 6 2026, QA): zedqa_card_real.lua at 4K with the real-mouse helper beside it. The save and the options come back after.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "C:\Users\danie\Zomboid"
$Lua = "$Z\Lua"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$KeepSave = "C:\Users\danie\ZedQaSaveKeep_20261106"
$Opt = "$Z\options.ini"
$KeepOpt = "$KeepSave.options.ini"
$Shots = "$Z\Screenshots"
if (Test-Path $KeepSave) { Write-Output "keep folder exists, stop"; exit 1 }
Copy-Item $Save $KeepSave -Recurse
Copy-Item $Opt $KeepOpt -Force
Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt" -ErrorAction SilentlyContinue
$h = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\release_check_mouse.ps1", "-MaxMinutes", "6" -WindowStyle Hidden -PassThru
try { & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\card_real.txt" -Report "$Z\mods\ZeD-UI\ZeDUI\qa\regression\2026-11-06_hotfix_card_real.md" }
finally {
    Set-Content "$Lua\zedqa_click_stop.txt" "stop" -NoNewline
    for ($i = 0; $i -lt 10 -and -not $h.HasExited; $i++) { Start-Sleep 1 }
    Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt", "$Lua\zedqa_click_done.txt" -ErrorAction SilentlyContinue
    Copy-Item "$Z\console.txt" "$Shots\crr_console.txt" -Force
    New-Item -ItemType Directory -Force "$Shots\crr" | Out-Null
    Get-ChildItem $Shots -Filter "zqa_crr_*.png" | Move-Item -Destination "$Shots\crr" -Force
    Copy-Item $KeepOpt $Opt -Force
    Remove-Item $Save -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item $KeepSave $Save -Recurse
    Remove-Item $KeepSave -Recurse -Force
    Remove-Item $KeepOpt -Force
}
Write-Output "done"
