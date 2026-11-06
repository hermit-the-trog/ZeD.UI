#Requires -Version 7.0
# ZeDUI/tools/qa/batch_bgm.ps1  (Nov 5 2026, QA): the real mouse on Butcher's bar with the staged copy in place (the bridge in for the run), the save put back.
$Qa = $PSScriptRoot
$Root = "C:\Users\you\Zomboid\mods\ZeD-UI"
$save = "C:\Users\you\Zomboid\Saves\Sandbox\ZeD-QA"; $snap = Join-Path $env:TEMP "ZeD-QA.bars-snapshot"
$dest = "C:\Users\you\Zomboid\Workshop\ZeD-UI\Contents\mods\ZeD-UI\42\media\lua\client\ZeD"
if (Test-Path $snap) { Remove-Item -Recurse -Force $snap }
Copy-Item -Recurse $save $snap
Copy-Item "$Root\42\media\lua\client\ZeD\QABridge.lua" $dest -Force
try { & pwsh -NoProfile -File "$Qa\release_check.ps1" -Staged -Manifest "bars_game.txt" -Report "$Root\ZeDUI\qa\regression\2026-11-05_bars_game5.md" 2>&1 | Out-Null }
finally {
    Remove-Item (Join-Path $dest "QABridge.lua") -Force -ErrorAction SilentlyContinue
    if (-not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) { Remove-Item -Recurse -Force $save; Copy-Item -Recurse $snap $save; Remove-Item -Recurse -Force $snap }
}
