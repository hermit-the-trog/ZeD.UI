#Requires -Version 7.0
# ZeDUI/tools/qa/batch_m1_menu.ps1  (Nov 7 2026, QA): zedqa_m1_menu.lua with the shipped ZeD picks mod.info (require=\ZeD_UI) in the
# installed copy for the run; the installed one is put back after. Never while the game runs.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Inst = "C:\Users\you\Zomboid\mods\ZeD_Picks\42\mod.info"
$Ship = "C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\picks_mod\ZeD_Picks\42\mod.info"
$Keep = "$env:TEMP\zedqa_picks_mod.info.keep"
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is running, stop"; exit 2 }
Copy-Item $Inst $Keep -Force
try {
    Copy-Item $Ship $Inst -Force
    & pwsh -NoProfile -File "$Qa\zedqa_menu_mods_run.ps1" -ModList "$Qa\m1_menu_mods.txt" -Script "$Qa\zedqa_m1_menu.lua" -Tag m1m -TimeoutSec 240 2>&1 | Select-Object -Last 30
}
finally {
    if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { Write-Output "the game is still running: picks mod.info NOT put back; copy $Keep over $Inst" }
    else { Copy-Item $Keep $Inst -Force; Write-Output "picks mod.info put back" }
}
