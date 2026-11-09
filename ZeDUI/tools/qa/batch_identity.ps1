#Requires -Version 7.0
# ZeDUI/tools/qa/batch_identity.ps1  (Nov 5 2026, QA): the Identity tab at 4K, then at the Deck, with the mouse helper; the QA save and ModOptions are put back.
$Qa = $PSScriptRoot
$Root = "$($env:USERPROFILE)\Zomboid\mods\ZeD-UI"
$save = "$($env:USERPROFILE)\Zomboid\Saves\Sandbox\ZeD-QA"; $snap = Join-Path $env:TEMP "ZeD-QA.identity-snapshot"
if (Test-Path $snap) { Remove-Item -Recurse -Force $snap }
Copy-Item -Recurse $save $snap
try {
    & pwsh -NoProfile -File "$Qa\release_check.ps1" -Manifest "identity.txt" -Report "$Root\ZeDUI\qa\regression\2026-11-05_identity_4k.md" 2>&1 | Out-Null
    & pwsh -NoProfile -File "$Qa\release_check.ps1" -Manifest "identity.txt" -Width 1280 -Height 800 -Report "$Root\ZeDUI\qa\regression\2026-11-05_identity_deck.md" 2>&1 | Out-Null
}
finally {
    if (-not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) { Remove-Item -Recurse -Force $save; Copy-Item -Recurse $snap $save; Remove-Item -Recurse -Force $snap }
    else { "game still running: the save was NOT put back" }
}
