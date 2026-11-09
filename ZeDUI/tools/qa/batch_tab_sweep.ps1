#Requires -Version 7.0
# ZeDUI/tools/qa/batch_tab_sweep.ps1  (Nov 6 2026, QA): every Character and World tab with data in it, at 4K. The pen is built on the QA save, so the save and the options are put back after each run.
$Qa = $PSScriptRoot
$env:ZEDQA_NOSTEAM = "1"
$Z = "$env:USERPROFILE\Zomboid"
$Save = "$Z\Saves\Sandbox\ZeD-QA"
$KeepSave = "$env:USERPROFILE\ZedQaSaveKeep_20261106"
$Opt = "$Z\options.ini"
$KeepOpt = "$KeepSave.options.ini"
$Rep = "$Z\mods\ZeD-UI\ZeDUI\qa\regression"
$Shots = "$Z\Screenshots"
if (Test-Path $KeepSave) { Write-Output "keep folder exists, stop"; exit 1 }
Copy-Item $Save $KeepSave -Recurse
Copy-Item $Opt $KeepOpt -Force
try {
    foreach ($r in @(@{ n = "tsw_4k"; a = @("-Mode", "fullscreen4k") })) {
        & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Manifest "$Qa\tab_sweep.txt" -Report "$Rep\2026-11-06_hotfix_tab_sweep_$($r.n).md" @($r.a)
        Copy-Item "$Z\console.txt" "$Shots\$($r.n)_console.txt" -Force
        New-Item -ItemType Directory -Force "$Shots\$($r.n)" | Out-Null
        Get-ChildItem $Shots -Filter "zqa_tsw_*.png" | Move-Item -Destination "$Shots\$($r.n)" -Force
        Remove-Item $Save -Recurse -Force
        Copy-Item $KeepSave $Save -Recurse
    }
}
finally {
    Copy-Item $KeepOpt $Opt -Force
    if (Test-Path $KeepSave) { Remove-Item $Save -Recurse -Force -ErrorAction SilentlyContinue; Copy-Item $KeepSave $Save -Recurse }
    Remove-Item $KeepSave -Recurse -Force
    Remove-Item $KeepOpt -Force
}
Write-Output "done"
