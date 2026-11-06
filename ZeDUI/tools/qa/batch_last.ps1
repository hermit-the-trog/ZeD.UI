#Requires -Version 7.0
# ZeDUI/tools/qa/batch_last.ps1  (Nov 5 2026, QA): the Ranch pad again, the multiplayer pictures at 4K, then the full regression with the
# pcall watch on (every "[ZeD.QA] pcw" line kept in qa/pcallwatch_regression_20261105.txt).
$Qa = $PSScriptRoot
$Out = [IO.Path]::GetFullPath("$Qa\..\..\qa\batch_known_issues_20261105.txt")
$Rep = [IO.Path]::GetFullPath("$Qa\..\..\qa\regression")
function Note($s) { "$(Get-Date -Format HH:mm) $s" | Add-Content $Out }
$o = & pwsh -NoProfile -File "$Qa\zedqa_mods_run.ps1" -ModList "$Qa\mods_none.txt" -Mode fullscreen4k -Manifest "$Qa\ranch_pad.txt" 2>&1
Note "ranch pad: $(($o | Select-Object -Last 2) -join ' | ')"
& "$Qa\mp_server.ps1" -Start | Out-Null
$o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\mp_surfaces_shots.txt" -Mp -Report (Join-Path $Rep "2026-11-05_mp_gallery2.md") 2>&1
Note "multiplayer pictures: $(($o | Select-Object -Last 1) -join ' ')"
& "$Qa\mp_server.ps1" -Stop | Out-Null
$s = "C:\Users\danie\Zomboid\Screenshots"; New-Item -ItemType Directory -Force "$s\mp_4k_20261105" | Out-Null; Copy-Item "$s\mps_*.png" "$s\mp_4k_20261105\" -Force
Set-Content "C:\Users\danie\Zomboid\Lua\zedqa_pcallwatch.txt" "on"
try {
    Note "regression start"
    $o = & "$Qa\zedqa_run.ps1" -Manifest "$Qa\regression_b4.txt" -Mode fullscreen4k -Report (Join-Path $Rep "2026-11-05_after_known_issues_4k.md") 2>&1
    Note "regression: $(($o | Select-Object -Last 1) -join ' ')"
    Select-String -Path "C:\Users\danie\Zomboid\console.txt" -Pattern "pcw " -SimpleMatch | ForEach-Object { $_.Line } | Set-Content ([IO.Path]::GetFullPath("$Qa\..\..\qa\pcallwatch_regression_20261105.txt"))
}
finally { Remove-Item "C:\Users\danie\Zomboid\Lua\zedqa_pcallwatch.txt" -ErrorAction SilentlyContinue }
