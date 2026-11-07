#Requires -Version 7.0
# ZeDUI/tools/qa/batch_ranch_long.ps1  (Nov 6 2026, QA): zedqa_ranch_long.lua at 4K, on the save as it stands.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
& pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\ranch_long.txt" -Report "C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-11-06_hotfix_ranch_long.md" -Mode fullscreen4k
