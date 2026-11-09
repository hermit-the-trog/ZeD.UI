# ZeDUI/tools/qa/cmap_run.ps1  (Nov 2 2026, QA; punch list 67)
# The controller map's checks with the real-mouse helper running (its close box is clicked for real).
#   pwsh -File ZeDUI/tools/qa/cmap_run.ps1          4K, cmap.txt
#   pwsh -File ZeDUI/tools/qa/cmap_run.ps1 -Deck    1280x800 windowed, Large text, cmap_large.txt
#   pwsh -File ZeDUI/tools/qa/cmap_run.ps1 -Short   1280x720 windowed, Large text (the body runs past the window)
param([switch]$Deck, [switch]$Short, [string]$Report = "")
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$lua = "$($env:USERPROFILE)\Zomboid\Lua"
foreach ($f in "zedqa_click.txt", "zedqa_click_done.txt", "zedqa_click_stop.txt") { $p = Join-Path $lua $f; if (Test-Path $p) { Remove-Item $p -Force } }
$helper = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", (Join-Path $here "release_check_mouse.ps1")) -WindowStyle Hidden -PassThru
try {
    if ($Deck -or $Short) {
        $h = if ($Short) { 720 } else { 800 }
        if (-not $Report) { $Report = "pl67_cmap_${h}L" }
        & pwsh -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "cmap_large.txt") -Mode windowed -Width 1280 -Height $h -Report $Report
    } else {
        if (-not $Report) { $Report = "pl67_cmap_4k" }
        & pwsh -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "cmap.txt") -Mode fullscreen4k -Report $Report
    }
}
finally {
    Set-Content -Path (Join-Path $lua "zedqa_click_stop.txt") -Value "stop"
    Start-Sleep -Milliseconds 600
    if (-not $helper.HasExited) { Stop-Process -Id $helper.Id -Force }   # (only the helper this script started)
}
