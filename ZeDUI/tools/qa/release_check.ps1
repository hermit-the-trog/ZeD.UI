# ZeDUI/tools/qa/release_check.ps1  (Nov 2 2026, QA; punch list 70, the five-minute release check)
# Part of every per-build pass and run before every upload. Starts the real-mouse helper (release_check_mouse.ps1) in
# the background, runs release_check.txt through zedqa_run.ps1 at 4K (the test resolution), stops the helper, and
# prints the result: PASS when every check passed. Uses the screen while it runs (the game in front, one real click).
#   pwsh -File ZeDUI/tools/qa/release_check.ps1 [-Report name]
param([string]$Report = "release_check")
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$lua = "C:\Users\danie\Zomboid\Lua"
foreach ($f in "zedqa_click.txt", "zedqa_click_done.txt", "zedqa_click_stop.txt") { $p = Join-Path $lua $f; if (Test-Path $p) { Remove-Item $p -Force } }
$helper = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", (Join-Path $here "release_check_mouse.ps1")) -WindowStyle Hidden -PassThru
try {
    & pwsh -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "release_check.txt") -Mode fullscreen4k -Report $Report
}
finally {
    Set-Content -Path (Join-Path $lua "zedqa_click_stop.txt") -Value "stop"
    Start-Sleep -Milliseconds 600
    if (-not $helper.HasExited) { Stop-Process -Id $helper.Id -Force }   # (only the helper this script started)
}
$rep = Join-Path (Split-Path (Split-Path (Split-Path $here))) $Report
$res = if (Test-Path $rep) { Select-String -Path $rep -Pattern "ZEDQA rel (RESULT|  FAIL)" | ForEach-Object { $_.Line } } else { @("no report at $rep") }
$res | Select-Object -Unique
