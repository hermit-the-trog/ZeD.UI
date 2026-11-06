#Requires -Version 7.0
# ZeDUI/tools/qa/batch_pairs.ps1  (Nov 5 2026, QA): Hands-On Interactions with each mod of the group it fails with, one pair a
# run; then the Ranch step with the fixed test and the button board with the controller's marks.
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\batch_known_issues_20261105.txt")
function Note($s) { "$(Get-Date -Format HH:mm) $s" | Add-Content $Out }
$H = "HandsOnInteractionsIso"
& "$Qa\hb_bisect.ps1" -Sets @($H, "SuperOl3gContextMenuIcons,$H", "ImmersiveMoodles,$H", "ParavelsEnhancedUI,ParavelsEnhancedInventory,$H", "LightBelt,$H")
Note "hair pairs done"
$o = & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\mods_none.txt" -Mode fullscreen4k -Manifest "$Qa\after_f59f2.txt" 2>&1; Note "Ranch step and marks: $(($o | Select-Object -Last 2) -join ' | ')"
& "$Qa\batch_mp.ps1"
