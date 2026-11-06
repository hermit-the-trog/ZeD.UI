#Requires -Version 7.0
# ZeDUI/tools/qa/batch_known_issues.ps1  (Nov 5 2026, QA; the director: "Yes, run them all"): the rest of the known issues
# list one after another: the Animals tab and the hold X check after 4ec5b4f4, the mod manager's own checks with the round 4
# mods on, then the first three sets of Hair and beard's fault. Each run keeps the rules of its own script (lock, the QA
# save put back). One line per step in ZeDUI/qa/batch_known_issues_20261105.txt.
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\batch_known_issues_20261105.txt")
function Note($s) { "$(Get-Date -Format HH:mm) $s" | Add-Content $Out }
Note "start"
$r = & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\perf_spikes_mods.txt" -Mode fullscreen4k -Manifest "$Qa\after_4ec5b.txt" 2>&1
Note "animals and hold X: $(($r | Select-Object -Last 3) -join ' | ')"
foreach ($m in @(@("zedqa_mods_order.lua", "mlo"), @("zedqa_mods_folders.lua", "mfo"), @("zedqa_mods_hand.lua", "mhd"), @("zedqa_mods_profiles.lua", "mp"))) {
    $lines = & pwsh -NoProfile -File "$Qa\zedqa_menu_mods_run.ps1" -ModList "$Qa\compat_r4_mods.txt" -Script "$Qa\$($m[0])" -Tag $m[1] -TimeoutSec 400 2>&1
    $pass = @($lines | Where-Object { $_ -match ' PASS' }).Count
    $fail = @($lines | Where-Object { $_ -match ' FAIL|ERR |TIMEOUT' })
    Note "$($m[0]): $pass pass, $($fail.Count) fail"
    foreach ($l in $fail) { Note "   $l" }
}
$A = "SuperOl3gContextMenuIcons,ImmersiveMoodles,ParavelsEnhancedUI,ParavelsEnhancedInventory,LightBelt"
& pwsh -NoProfile -File "$Qa\hb_bisect.ps1" -Sets "$A,SladeBagCheck,HandsOnInteractionsIso,ImmersiveSleep", "$A,SladeBagCheck", "$A,HandsOnInteractionsIso"
Note "hair and beard: three sets done"
Note "end"
