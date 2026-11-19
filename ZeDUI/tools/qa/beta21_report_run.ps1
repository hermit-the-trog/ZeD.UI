#Requires -Version 7.0
<#
    ZeDUI/tools/qa/beta21_report_run.ps1  (Nov 19 2026, QA): the beta 21 visual report's pictures (the director's
    standing ask, Nov 19: before a full release test, full-screen pictures of every change). Two launches at 4K:
      1. the main menu  zedqa_menu_mods_run.ps1 with zedqa_menu_b21r.lua (desk, Mods, the first-launch window)
      2. a game         zedqa_run.ps1 with beta21_report.txt (beta21_report.lua on the 1.0 gallery's staging)
    Then every Screenshots/b21r_<name>.png moves to Screenshots/beta21_report/<name>.png (an earlier one replaced).
    The director's Lua files the pictures could touch (ModOptions.ini, ZeD_setup.txt, ZeD_tutorial.txt,
    ZeD_setup_seen.txt) are read first and written back byte for byte after each launch, whatever happens (one that
    was not there is removed). latestSave.ini must already point at the QA save (the caller's chain sets it).
    Refuses (exit 2) while ProjectZomboid64.exe runs or Zomboid/Lua/zedqa.lock says busy.
      pwsh -NoProfile -File ZeDUI/tools/qa/beta21_report_run.ps1
#>
param([ValidateSet("both", "menu", "game")][string]$Part = "both")
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$Z = "$($env:USERPROFILE)\Zomboid"
$lua = Join-Path $Z "Lua"
$lock = Join-Path $lua "zedqa.lock"
$shots = Join-Path $Z "Screenshots"
$out = Join-Path $shots "beta21_report"
$names = @("ModOptions.ini", "ZeD_setup.txt", "ZeD_tutorial.txt", "ZeD_setup_seen.txt")

$ls = $null
try { $ls = [string](Get-Content -LiteralPath $lock -Raw -ErrorAction Stop) } catch { }
if ($ls -and $ls.Trim() -match '^busy') { Write-Output "beta21_report_run: not starting: $lock says busy"; exit 2 }
if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "beta21_report_run: not starting: ProjectZomboid64.exe is running"; exit 2 }

$was = @{}
foreach ($n in $names) { $f = Join-Path $lua $n; $was[$n] = $(if (Test-Path -LiteralPath $f) { [IO.File]::ReadAllBytes($f) } else { $null }) }
function Restore-Files {
    if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "beta21_report_run: the game still runs; files not put back yet"; return $false }
    $ok = $true
    foreach ($n in $names) {
        $f = Join-Path $lua $n
        if ($null -eq $was[$n]) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force } }
        else {
            [IO.File]::WriteAllBytes($f, $was[$n])
            if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($f)) -ne [Convert]::ToBase64String($was[$n])) { $ok = $false; Write-Output "beta21_report_run: $n did NOT come back" }
        }
    }
    return $ok
}
$codes = @()
try {
    if ($Part -ne "game") {
        & pwsh -NoProfile -File (Join-Path $here "zedqa_menu_mods_run.ps1") -ModList (Join-Path $here "zed_only_mods.txt") `
            -Script (Join-Path $here "zedqa_menu_b21r.lua") -Tag mb21r -TimeoutSec 300
        $codes += $LASTEXITCODE
        if (-not (Restore-Files)) { $codes += 1 }
    }
    if ($Part -ne "menu") {
        & pwsh -NoProfile -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "beta21_report.txt") -Mode fullscreen4k -Report "beta21_report"
        $codes += $LASTEXITCODE
    }
}
finally {
    if (Restore-Files) { Write-Output "beta21_report_run: the director's four Lua files put back byte for byte" }
    New-Item -ItemType Directory -Force $out | Out-Null
    $moved = 0
    Get-ChildItem -LiteralPath $shots -Filter "b21r_*.png" | ForEach-Object {
        Move-Item -LiteralPath $_.FullName -Destination (Join-Path $out ($_.Name.Substring(5))) -Force
        $moved++
    }
    Write-Output "beta21_report_run: $moved pictures moved to $out"
}
$bad = @($codes | Where-Object { $_ -ne 0 })
Write-Output "beta21_report_run: exit codes $($codes -join ', ')"
exit $(if ($bad.Count) { 1 } else { 0 })
