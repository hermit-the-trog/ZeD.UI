# ZeDUI/tools/qa/cinema_run2.ps1  (Nov 11 2026, QA; the gallery plan v2 shots): cinema_run.ps1 for any manifest, with the
# real-mouse helper running so the scene can move the pointer out of the picture (C.pointerAway).
#   pwsh -File ZeDUI/tools/qa/cinema_run2.ps1 -Manifest cinema_kohners2.txt -ShotSave ZeD-Shots-Kohners
#   pwsh -File ZeDUI/tools/qa/cinema_run2.ps1 -Manifest cinema_angel_open.txt            (no -ShotSave: the ZeD-QA save)
#   pwsh -File ZeDUI/tools/qa/cinema_run2.ps1 -Manifest cinema_angel_close.txt -Mp -KeepOpen   (the local test server)
param([Parameter(Mandatory)][string]$Manifest, [string]$ShotSave = "", [switch]$Mp, [switch]$KeepOpen, [string]$Report = "")
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$lua = "$($env:USERPROFILE)\Zomboid\Lua"
foreach ($f in "zedqa_click.txt", "zedqa_click_done.txt", "zedqa_click_stop.txt") { $p = Join-Path $lua $f; if (Test-Path $p) { Remove-Item $p -Force } }
$helper = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", (Join-Path $here "release_check_mouse.ps1"), "-MaxMinutes", "90") -WindowStyle Hidden -PassThru
try {
    $m = $(if ([IO.Path]::IsPathRooted($Manifest)) { $Manifest } else { Join-Path $here $Manifest })
    $a = @("-File", (Join-Path $here "zedqa_run.ps1"), "-Mode", "fullscreen4k", "-Manifest", $m)
    if ($ShotSave) { $a += @("-ShotSave", $ShotSave) }
    if ($Mp) { $a += "-Mp" }
    if ($KeepOpen) { $a += "-KeepOpen" }
    if ($Report) { $a += @("-Report", $Report) }
    & pwsh @a
}
finally {
    Set-Content -Path (Join-Path $lua "zedqa_click_stop.txt") -Value "stop"
    Start-Sleep -Milliseconds 600
    if (-not $helper.HasExited) { Stop-Process -Id $helper.Id -Force }   # (only the helper this script started)
}
