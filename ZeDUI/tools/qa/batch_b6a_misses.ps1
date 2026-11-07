#Requires -Version 7.0
# ZeDUI/tools/qa/batch_b6a_misses.ps1  (Nov 6 2026, QA): a real right click on dropped items on the save the regression ran on, then that save aside, the 5:05 pm backup back, and the regression's four misses again.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "C:\Users\you\Zomboid"
$Lua = "$Z\Lua"
$Shots = "$Z\Screenshots"
$Rep = "$Z\mods\ZeD-UI\ZeDUI\qa\regression"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$Aside = "C:\Users\you\ZedQaSavePen_20261106"
$Clean = "D:\ZeD-UI backup\2026-11-06-beta6\Saves_Sandbox_ZeD-QA"
Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt" -ErrorAction SilentlyContinue
$h = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\release_check_mouse.ps1", "-MaxMinutes", "4" -WindowStyle Hidden -PassThru
try { & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\floor_rclick.txt" -Report "$Rep\2026-11-06_hotfix_floor_rclick.md" }
finally {
    Set-Content "$Lua\zedqa_click_stop.txt" "stop" -NoNewline
    for ($i = 0; $i -lt 10 -and -not $h.HasExited; $i++) { Start-Sleep 1 }
    Remove-Item "$Lua\zedqa_click_stop.txt", "$Lua\zedqa_click.txt", "$Lua\zedqa_click_done.txt" -ErrorAction SilentlyContinue
}
if (-not (Test-Path "$Clean\map_t.bin")) { Write-Output "no clean save at $Clean, stop"; Get-ChildItem $Clean | Select-Object -First 5; exit 1 }
if (Test-Path $Aside) { Write-Output "aside folder exists, stop"; exit 1 }
Start-Sleep 5
Move-Item $Save $Aside
Copy-Item $Clean $Save -Recurse
& pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\b6a_misses.txt" -Report "$Rep\2026-11-06_beta6a_misses.md" -Mode fullscreen4k
