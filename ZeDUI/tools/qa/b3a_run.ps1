# ZeDUI/tools/qa/b3a_run.ps1  (Nov 4 2026, QA): the Beta 3a spreads retake, one run. Runs b3a_<N>.txt at 4K with the
# real-mouse helper alongside (run 7's hovered row needs it), then copies the pictures this run owns (b3a_keep.json:
# each spread picture assigned to the run that made the one in use) from Zomboid/Screenshots into
# Screenshots/gallery_b3a. Prints fresh / missing. After all seven: copy gallery_b3a over gallery_t14.
#   pwsh -File ZeDUI/tools/qa/b3a_run.ps1 -N 1
param([Parameter(Mandatory)][ValidateRange(1, 7)][int]$N)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$lua = "$($env:USERPROFILE)\Zomboid\Lua"
$scr = "$($env:USERPROFILE)\Zomboid\Screenshots"
$stage = Join-Path $scr "gallery_b3a"
New-Item -ItemType Directory -Force $stage | Out-Null
$start = Get-Date
foreach ($f in "zedqa_click.txt", "zedqa_click_done.txt", "zedqa_click_stop.txt") { $p = Join-Path $lua $f; if (Test-Path $p) { Remove-Item $p -Force } }
$helper = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", (Join-Path $here "release_check_mouse.ps1"), "-MaxMinutes", "90") -WindowStyle Hidden -PassThru
try {
    & pwsh -File (Join-Path $here "zedqa_run.ps1") -Mode fullscreen4k -Manifest (Join-Path $here "b3a_$N.txt") -Report "b3a_$N"
}
finally {
    Set-Content -Path (Join-Path $lua "zedqa_click_stop.txt") -Value "stop"
    Start-Sleep -Milliseconds 600
    if (-not $helper.HasExited) { Stop-Process -Id $helper.Id -Force }   # (only the helper this script started)
}
$keep = (Get-Content (Join-Path $here "b3a_keep.json") -Raw | ConvertFrom-Json).keep
$fresh = 0; $missing = @()
foreach ($p in $keep.PSObject.Properties) {
    if ([int]$p.Value -ne $N) { continue }
    $src = Join-Path $scr $p.Name
    if ((Test-Path $src) -and (Get-Item $src).LastWriteTime -ge $start) { Copy-Item $src (Join-Path $stage $p.Name) -Force; $fresh++ }
    else { $missing += $p.Name }
}
"b3a run $N : fresh $fresh, missing $($missing.Count) $($missing -join ' ')"
