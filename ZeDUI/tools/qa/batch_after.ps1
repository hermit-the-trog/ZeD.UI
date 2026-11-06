#Requires -Version 7.0
# ZeDUI/tools/qa/batch_after.ps1  (Nov 5 2026, QA): the corkboard note at every size, then the full regression, for after the
# batches. Results in qa/menu_note_20261105.log and the regression report.
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\batch_known_issues_20261105.txt")
$Log = [IO.Path]::GetFullPath("$Qa\..\..\qa\menu_note_20261105.log")
function Note($s) { "$(Get-Date -Format HH:mm) $s" | Add-Content $Out }
$none = "$Qa\mods_none.txt"
foreach ($sz in @(@(0, 0), @(1920, 1080), @(1280, 800), @(1280, 720), @(2560, 1080))) {
    $a = @{ ModList = $none; Script = "$Qa\zedqa_menu_note.lua"; Tag = "nte"; TimeoutSec = 90 }
    if ($sz[0] -gt 0) { $a.Width = $sz[0]; $a.Height = $sz[1] }
    "== $($sz[0])x$($sz[1])" | Add-Content $Log
    & "$Qa\zedqa_menu_mods_run.ps1" @a 2>&1 | Add-Content $Log
    Note "note at $($sz[0])x$($sz[1]) done"
}
Note "regression start"
$o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\regression_b4.txt" -Mode fullscreen4k -Report ([IO.Path]::GetFullPath("$Qa\..\..\qa\regression\2026-11-05_after_known_issues_4k.md")) 2>&1
Note "regression: $(($o | Select-Object -Last 1) -join ' ')"
