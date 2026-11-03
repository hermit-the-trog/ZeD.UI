# ZeDUI/tools/qa/pl60_plain_run.ps1  (Nov 2 2026, QA; punch list 60): the plain card checks with the real-mouse helper
#   pwsh -File ZeDUI/tools/qa/pl60_plain_run.ps1          4K
#   pwsh -File ZeDUI/tools/qa/pl60_plain_run.ps1 -Deck    1280x800 windowed, Large text
param([switch]$Deck)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$lua = "C:\Users\danie\Zomboid\Lua"
foreach ($f in "zedqa_click.txt", "zedqa_click_done.txt", "zedqa_click_stop.txt") { $p = Join-Path $lua $f; if (Test-Path $p) { Remove-Item $p -Force } }
$helper = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", (Join-Path $here "release_check_mouse.ps1")) -WindowStyle Hidden -PassThru
try {
    if ($Deck) { & pwsh -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "pl60_plain_large.txt") -Mode windowed -Width 1280 -Height 800 -Report pl60_plain_800L }
    else { & pwsh -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "pl60_plain.txt") -Mode fullscreen4k -Report pl60_plain_4k }
}
finally {
    Set-Content -Path (Join-Path $lua "zedqa_click_stop.txt") -Value "stop"
    Start-Sleep -Milliseconds 600
    if (-not $helper.HasExited) { Stop-Process -Id $helper.Id -Force }   # (only the helper this script started)
}
