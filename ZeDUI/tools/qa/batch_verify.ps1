#Requires -Version 7.0
# ZeDUI/tools/qa/batch_verify.ps1  (Nov 5 2026, QA): Hair and beard after 9bbc36c0, the Farm and Ranch pictures, then the corkboard
# note and the full regression (batch_after.ps1). hb_bisect.ps1 logs callFrame counts; the wrong-thread line is counted here.
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\batch_known_issues_20261105.txt")
function Note($s) { "$(Get-Date -Format HH:mm) $s" | Add-Content $Out }
$H = "HandsOnInteractionsIso"
& "$Qa\hb_bisect.ps1" -Sets @("$H", "SuperOl3gContextMenuIcons,ImmersiveMoodles,ParavelsEnhancedUI,ParavelsEnhancedInventory,LightBelt,$H")
Note "hair after the fix done; wrong-thread lines in the last console: $((Select-String -Path "$env:USERPROFILE\Zomboid\console.txt" -Pattern 'wrong thread' -SimpleMatch).Count)"
$o = & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\mods_none.txt" -Mode fullscreen4k -Manifest "$Qa\gallery_farm_ranch.txt" 2>&1
Note "farm and ranch pictures: $(($o | Select-Object -Last 2) -join ' | ')"
& "$Qa\batch_after.ps1"
