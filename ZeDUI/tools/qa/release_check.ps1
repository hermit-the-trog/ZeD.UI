# ZeDUI/tools/qa/release_check.ps1  (Nov 2 2026, QA; punch list 70, the five-minute release check)
# Part of every per-build pass and run before every upload. Starts the real-mouse helper (release_check_mouse.ps1) in
# the background, runs release_check.txt through zedqa_run.ps1 at 4K (the test resolution), stops the helper, and
# prints the result: PASS when every check passed. Uses the screen while it runs (the game in front, one real click).
#   pwsh -File ZeDUI/tools/qa/release_check.ps1 [-Report name] [-Width 1280 -Height 800]   (a size: windowed at it, the Deck)
# -Staged: on the staged Workshop copy, right before Upload (Nov 3 2026). Copy QABridge.lua into the staged copy first and
# take it out after; the runner refuses a staged copy without its -StagedCopy, and with it unless the bridge is there.
param([string]$Report = "", [int]$Width = 0, [int]$Height = 0, [switch]$Staged, [string]$Manifest = "release_check.txt")   # -Manifest (Nov 3 2026): another manifest that needs the real mouse
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$lua = $(if ($env:ZEDQA_ZDIR) { Join-Path $env:ZEDQA_ZDIR "Lua" } else { "$($env:USERPROFILE)\Zomboid\Lua" })
foreach ($f in "zedqa_click.txt", "zedqa_click_done.txt", "zedqa_click_stop.txt") { $p = Join-Path $lua $f; if (Test-Path $p) { Remove-Item $p -Force } }
$t0 = Get-Date   # (Nov 12 2026) no -Report: zedqa_run names it in ZeDUI/qa/regression, dated; a bare name goes there too, never to the repo root
$reportArg = if ($Report) { @("-Report", $Report) } else { @() }
$size = if ($Width -gt 0) { @("-Mode", "windowed", "-Width", $Width, "-Height", $Height) } else { @("-Mode", "fullscreen4k") }
$helper = Start-Process pwsh -ArgumentList @("-NoProfile", "-File", (Join-Path $here "release_check_mouse.ps1")) -WindowStyle Hidden -PassThru
try {
    & pwsh -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here $Manifest) @size @reportArg -StagedCopy:$Staged
}
finally {
    Set-Content -Path (Join-Path $lua "zedqa_click_stop.txt") -Value "stop"
    Start-Sleep -Milliseconds 600
    if (-not $helper.HasExited) { Stop-Process -Id $helper.Id -Force }   # (only the helper this script started)
}
$repDir = Join-Path (Split-Path (Split-Path $here)) "qa\regression"
$rep = Get-ChildItem -Path $repDir -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -ge $t0 } | Sort-Object LastWriteTime | Select-Object -Last 1
if ($Report -and (Test-Path -LiteralPath $Report)) { $rep = Get-Item -LiteralPath $Report }   # (an explicit path)
$res = if ($rep) { Select-String -Path $rep.FullName -Pattern "ZEDQA rel (RESULT|  FAIL)" | ForEach-Object { $_.Line } } else { @("no report in $repDir") }
$res | Select-Object -Unique
