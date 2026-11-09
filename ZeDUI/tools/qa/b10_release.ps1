#Requires -Version 7.0
# ZeDUI/tools/qa/b10_release.ps1  (Nov 9 2026, QA): the beta 10 release pass on the dev mod, every stage in a row.
# Each stage runs through Start-Process with its output to a file and WaitForExit (never piped, never -Wait), so a
# game or server it starts cannot hold the run open. Lines go to b10_release.log as they happen; run stall_watch.ps1
# beside it on that log and console.txt. The staged Workshop copy is held aside for the run and put back after.
$here = $PSScriptRoot
$log = Join-Path $here "b10_release.log"
$Ws = "$($env:USERPROFILE)\Zomboid\Workshop\ZeD-UI"
$lock = "$($env:USERPROFILE.Replace('\','/'))/Zomboid/Lua/zedqa.lock"
function Say([string]$s) { "{0}  {1}" -f (Get-Date -Format "HH:mm:ss"), $s | Add-Content -LiteralPath $log }
function Wait-Free {
    while ($true) {
        $busy = (Test-Path $lock) -and ((Get-Content $lock -Raw).Trim() -ne "free")
        if (-not $busy -and -not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) { return }
        Start-Sleep -Seconds 20
    }
}
function Stage([string]$name, [string[]]$argv) {
    Wait-Free
    $out = Join-Path $here ("b10r_" + ($name -replace '\W', '_') + ".out")
    Say "START $name"
    $p = Start-Process pwsh -ArgumentList (@("-NoProfile") + $argv) -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    $p.WaitForExit()
    $tail = (Get-Content $out -ErrorAction SilentlyContinue | Where-Object { $_ -match "pass,|FAIL|TIMEOUT|refus|error|report" } | Select-Object -Last 10) -join " || "
    Say "END $name (exit $($p.ExitCode)) $tail"
}
Set-Content -LiteralPath $log -Value "b10 release pass, started $(Get-Date)"
$env:ZEDQA_NOSTEAM = "1"
if (Test-Path "$Ws\Contents") { Rename-Item "$Ws\Contents" "Contents.hold"; Say "staged Contents held aside" }
try {
    Stage "1 release check" @("-File", "$here\release_check.ps1", "-Report", "b10r_release")
    Stage "2 regression" @("-File", "$here\zedqa_run.ps1", "-Mode", "fullscreen4k", "-Manifest", "$here\regression.txt", "-Report", "b10r_regression")
    Stage "3 tooltips and context menu" @("-File", "$here\zedqa_run.ps1", "-Mode", "fullscreen4k", "-Manifest", "$here\b10_check_manifest.txt", "-Report", "b10r_check")
    Stage "4 guide frames and bubble" @("-File", "$here\zedqa_run.ps1", "-Mode", "fullscreen4k", "-Manifest", "$here\b10_gframes_manifest.txt", "-Report", "b10r_gframes")
    Stage "5 hotfix 9a scripts" @("-File", "$here\batch_b9a.ps1", "-Report", "$($env:USERPROFILE)\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-11-09_b10_b9a_4k.md")
    $empty = Join-Path $here "b8_empty_mods.txt"; Set-Content -LiteralPath $empty -Value ""
    Stage "6 corkboard" @("-File", "$here\zedqa_menu_mods_run.ps1", "-ModList", $empty, "-Script", "$here\zedqa_menunote_shot.lua", "-Tag", "mmn", "-TimeoutSec", "400")
} finally {
    if (Test-Path "$Ws\Contents.hold") { Rename-Item "$Ws\Contents.hold" "Contents"; Say "staged Contents put back" }
    Wait-Free
    $r = & "$here\pzrestorewin.ps1" 2>&1 | Out-String
    Say "restore: $($r.Trim())"
    Say "ALL DONE"
}
