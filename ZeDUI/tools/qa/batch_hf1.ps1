#Requires -Version 7.0
# ZeDUI/tools/qa/batch_hf1.ps1  (Nov 6 2026, QA): 0.3.0-beta6a, the first stretch: every tab and real cards over them, the Ranch pages at 4K and Deck, then the server: the Admin and Server rails at 4K and Deck, and the server's log.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Shots = "$env:USERPROFILE\Zomboid\Screenshots"
foreach ($d in "tsw_4k", "acl_4k", "acl_deck", "rail_4k", "rail_deck") { if (Test-Path "$Shots\$d") { Move-Item "$Shots\$d" "$Shots\pre_hf_$d" -Force } }
& pwsh -NoProfile -File "$Qa\batch_tab_sweep.ps1"
& pwsh -NoProfile -File "$Qa\batch_animals_clip.ps1"
& pwsh -NoProfile -File "$Qa\batch_rail.ps1"
Write-Output "hf1 done"
