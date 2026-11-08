#Requires -Version 7.0
# ZeDUI/tools/qa/batch_night1.ps1  (Nov 5 2026, QA): the half card at the Deck, the radial wheels' suite at 4K, the license on the server.
$Qa = $PSScriptRoot
$Root = "$env:USERPROFILE\Zomboid\mods\ZeD-UI"
$Out = "$Root\ZeDUI\qa\batch_night_20261105.txt"
$Rep = "$Root\ZeDUI\qa\regression"
function Note($s) { "$(Get-Date -Format HH:mm) $s" | Add-Content $Out }
$o = & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\mods_none.txt" -Mode windowed -Width 1280 -Height 800 -Manifest "$Qa\identity_half.txt" 2>&1
Note "half card: $(($o | Select-Object -Last 2) -join ' | ')"
$o = & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\mods_none.txt" -Mode fullscreen4k -Manifest "$Qa\wheels_91.txt" 2>&1
Note "wheels: $(($o | Select-Object -Last 2) -join ' | ')"
& "$Qa\mp_server.ps1" -Start | Out-Null
$o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\mp_iss.txt" -Mp -Report "$Rep\2026-11-05_mp_iss.md" 2>&1
Note "license on the server: $(($o | Select-Object -Last 1) -join ' ')"
& "$Qa\mp_server.ps1" -Stop | Out-Null
