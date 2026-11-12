# ZeDUI/tools/qa/cinema_run.ps1  (Nov 4 2026, QA; the director's cinema breaks): one cinema scene at 4K on its shot
# save, with the real-mouse helper running so the scene can move the pointer out of the picture (C.pointerAway).
#   pwsh -File ZeDUI/tools/qa/cinema_run_laura2.ps1 (Nov 11 2026: the fishing reshoot)   (Laura: the Rosa save, renamed)
$Who = "Laura"
$save = if ($Who -eq "Laura") { "ZeD-Shots-Rosa" } else { "ZeD-Shots-$Who" }
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$lua = "$($env:USERPROFILE)\Zomboid\Lua"
foreach ($f in "zedqa_click.txt", "zedqa_click_done.txt", "zedqa_click_stop.txt") { $p = Join-Path $lua $f; if (Test-Path $p) { Remove-Item $p -Force } }
$helper = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", (Join-Path $here "release_check_mouse.ps1")) -WindowStyle Hidden -PassThru
try {
    & pwsh -File (Join-Path $here "zedqa_run.ps1") -Mode fullscreen4k -ShotSave $save -Manifest (Join-Path $here $(if ($env:CLAU3_MANIFEST) { $env:CLAU3_MANIFEST } else { "cinema_laura3.txt" }))
}
finally {
    Set-Content -Path (Join-Path $lua "zedqa_click_stop.txt") -Value "stop"
    Start-Sleep -Milliseconds 600
    if (-not $helper.HasExited) { Stop-Process -Id $helper.Id -Force }   # (only the helper this script started)
}


