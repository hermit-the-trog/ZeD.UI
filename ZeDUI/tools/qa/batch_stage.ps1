#Requires -Version 7.0
# ZeDUI/tools/qa/batch_stage.ps1  (Nov 5 2026, QA): the in-game bar by the real mouse, then 0.3.0-beta5 staged and its release check.
$Qa = $PSScriptRoot
$Root = "C:\Users\you\Zomboid\mods\ZeD-UI"
$Out = "$Root\ZeDUI\qa\batch_known_issues_20261105.txt"
function Note($s) { "$(Get-Date -Format HH:mm) $s" | Add-Content $Out }
$save = "C:\Users\you\Zomboid\Saves\Sandbox\ZeD-QA"; $snap = Join-Path $env:TEMP "ZeD-QA.bars-snapshot"
if (Test-Path $snap) { Remove-Item -Recurse -Force $snap }
Copy-Item -Recurse $save $snap
& pwsh -NoProfile -File "$Qa\release_check.ps1" -Manifest "bars_game.txt" -Report "$Root\ZeDUI\qa\regression\2026-11-05_bars_game.md" 2>&1 | Out-Null
if (-not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) { Remove-Item -Recurse -Force $save; Copy-Item -Recurse $snap $save; Remove-Item -Recurse -Force $snap; Note "bars game done, save put back" } else { Note "game still up: save NOT put back" ; exit 1 }
$o = & pwsh -NoProfile -File "$Root\ZeDUI\tools\release\stage_workshop.ps1" -Version 0.3.0-beta5 2>&1
$o | Select-Object -Last 12 | Set-Content "$Root\ZeDUI\qa\stage_beta5.txt"
Note "staged: $(($o | Select-Object -Last 1) -join ' ')"
$dest = "C:\Users\you\Zomboid\Workshop\ZeD-UI\Contents\mods\ZeD-UI\42\media\lua\client\ZeD"
Copy-Item "$Root\42\media\lua\client\ZeD\QABridge.lua" $dest -Force
try {
    $r = & pwsh -NoProfile -File "$Qa\release_check.ps1" -Staged -Manifest "release_check_pinned.txt" -Report "$Root\ZeDUI\qa\regression\2026-11-05_beta5_release_check_staged.md" 2>&1
    Note "release check: $(($r | Select-Object -Last 2) -join ' | ')"
}
finally { Remove-Item (Join-Path $dest "QABridge.lua") -Force -ErrorAction SilentlyContinue }
