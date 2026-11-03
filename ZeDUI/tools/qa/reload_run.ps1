# ZeDUI/tools/qa/reload_run.ps1  (Nov 2 2026, QA; the beta checklist, old item 10: save and reload)
# Two runs at 4K. The first changes two settings, moves the Character window and leaves it on Skills, makes a loadout,
# and copies the saved ModOptions.ini to Lua/zedqa_reload_ini.txt; the runner's quit saves the game. That copy is put
# in place for the second run (the runner puts the director's file back after each run), which checks all of it came
# back, then puts it back. The director's ModOptions.ini is restored at the end whatever happens.
#   pwsh -File ZeDUI/tools/qa/reload_run.ps1
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$lua = "C:\Users\danie\Zomboid\Lua"
$ini = Join-Path $lua "ModOptions.ini"
$copy = Join-Path $lua "zedqa_reload_ini.txt"
$was = [System.IO.File]::ReadAllBytes($ini)
try {
    if (Test-Path $copy) { Remove-Item $copy }
    & pwsh -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "reload_a.txt") -Mode fullscreen4k -Report "rc_reload_a"
    if (-not (Test-Path $copy)) { Write-Output "the first half wrote no ModOptions copy; not running the second"; exit 1 }
    Copy-Item $copy $ini -Force
    & pwsh -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "reload_b.txt") -Mode fullscreen4k -Report "rc_reload_b"
}
finally {
    [System.IO.File]::WriteAllBytes($ini, $was)
    Write-Output "ModOptions.ini put back"
}
