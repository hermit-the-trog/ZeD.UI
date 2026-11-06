#Requires -Version 7.0
# ZeDUI/tools/qa/batch_gallery.ps1  (Nov 6 2026, QA): the gallery retake on beta 6: the in-game pictures, the main menu's, the mods panes', with no Steam. The collect and the
# spreads' render follow by hand, after a look at what came back.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\tickets_20261105.txt")
function Note($s) { "$(Get-Date -Format HH:mm:ss) $s" | Add-Content $Out }
Note "gallery start"
$o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\gallery_t14_manifest.txt" -Report ([IO.Path]::GetFullPath("$Qa\..\..\qa\regression\2026-11-06_gallery_b6.md")) 2>&1
Note "gallery in game : $(($o | Select-Object -Last 1) -join ' ')"
$o = & "$Qa\gallery_menus_run.ps1" 2>&1
Note "gallery menus : $(($o | Select-Object -Last 1) -join ' ')"
$o = & "$Qa\zedqa_mods_panes_run.ps1" 2>&1
Note "gallery panes : $(($o | Select-Object -Last 1) -join ' ')"
