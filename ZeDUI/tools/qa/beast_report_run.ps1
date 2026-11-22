#Requires -Version 7.0
<#
    ZeDUI/tools/qa/beast_report_run.ps1  (Nov 21 2026, QA beast day): full-screen 4K pictures of the day's visible fixes
    (the director's standing ask: every visible change gets a picture before a release). One launch per part, 4K, on
    the 1.0 gallery's staging (the story stage, gallery_unload, G1, hfr_common.lua):
      inv craft menus win lite   beast_report_<part>.txt with bxr_<part>.lua
    Every Screenshots/bxr_<name>.png moves to Screenshots/beast_day_report/<name>.png. After EVERY launch the director's
    Lua files (ModOptions.ini, ZeD_setup.txt, ZeD_tutorial.txt, ZeD_setup_seen.txt) are written back byte for byte,
    latestSave.ini is the director's again, and options.ini has fontSize=3.
    Refuses (exit 2) while ProjectZomboid64.exe runs or Zomboid/Lua/zedqa.lock says busy.
      pwsh -NoProfile -File ZeDUI/tools/qa/beast_report_run.ps1 -Part inv,craft
#>
param([string[]]$Part = @("inv", "craft", "menus", "win", "lite"), [string]$OutName = "beast_day_report")
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$Z = "$($env:USERPROFILE)\Zomboid"
$lua = Join-Path $Z "Lua"
$lock = Join-Path $lua "zedqa.lock"
$shots = Join-Path $Z "Screenshots"
$out = Join-Path $shots $OutName
$names = @("ModOptions.ini", "ZeD_setup.txt", "ZeD_tutorial.txt", "ZeD_setup_seen.txt")
$env:ZEDQA_NOSTEAM = "1"

$Part = @($Part | ForEach-Object { $_ -split "," } | Where-Object { $_ })
$ls = $null
try { $ls = [string](Get-Content -LiteralPath $lock -Raw -ErrorAction Stop) } catch { }
if ($ls -and $ls.Trim() -match '^busy') { Write-Output "beast_report_run: not starting: $lock says busy"; exit 2 }
if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "beast_report_run: not starting: ProjectZomboid64.exe is running"; exit 2 }

# (a file read inside $( ) that is 0 bytes unrolls to $null and reads as "absent": assign directly)
$was = @{}
foreach ($n in $names) { $f = Join-Path $lua $n; if (Test-Path -LiteralPath $f) { $was[$n] = [IO.File]::ReadAllBytes($f) } else { $was[$n] = $null } }
function Restore-Files {
    if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "beast_report_run: the game still runs; files not put back yet"; return $false }
    $ok = $true
    foreach ($n in $names) {
        $f = Join-Path $lua $n
        if ($null -eq $was[$n]) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force } }
        else {
            [IO.File]::WriteAllBytes($f, $was[$n])
            if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($f)) -ne [Convert]::ToBase64String($was[$n])) { $ok = $false; Write-Output "beast_report_run: $n did NOT come back" }
        }
    }
    return $ok
}
function Restore-Director {
    Copy-Item -LiteralPath (Join-Path $Z "zed_backups\latestSave_director_20261114.ini") -Destination (Join-Path $Z "latestSave.ini") -Force
    $oi = Join-Path $Z "options.ini"
    if (Test-Path -LiteralPath $oi) {
        $t = [IO.File]::ReadAllText($oi)
        $t = [regex]::Replace($t, '(?m)^fontSize=.*$', 'fontSize=3')
        [IO.File]::WriteAllText($oi, $t)
    }
    Write-Output "beast_report_run: latestSave.ini is the director's again, options.ini fontSize=3"
}
function Move-Shots {
    New-Item -ItemType Directory -Force $out | Out-Null
    $moved = 0
    Get-ChildItem -LiteralPath $shots -Filter "bxr_*.png" | ForEach-Object {
        Move-Item -LiteralPath $_.FullName -Destination (Join-Path $out ($_.Name.Substring(4))) -Force
        $moved++
    }
    Write-Output "beast_report_run: $moved pictures moved to $out"
}
$codes = @()
try {
    foreach ($pt in $Part) {
        if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "beast_report_run: a game is running, stopping before $pt"; $codes += 3; break }
        Write-Output "beast_report_run: part $pt"
        try {
            [IO.File]::WriteAllText((Join-Path $Z "latestSave.ini"), "ZeD-QA`r`nSandbox")
            & pwsh -NoProfile -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "beast_report_$pt.txt") -Mode fullscreen4k -Report "beast_report_$pt" -TimeoutSec 3000
            $codes += $LASTEXITCODE
        }
        finally {
            if (-not (Restore-Files)) { $codes += 1 }
            Restore-Director
            Move-Shots
        }
    }
}
finally {
    if (Restore-Files) { Write-Output "beast_report_run: the director's four Lua files put back byte for byte" }
}
$bad = @($codes | Where-Object { $_ -ne 0 })
Write-Output "beast_report_run: exit codes $($codes -join ', ')"
exit $(if ($bad.Count) { 1 } else { 0 })
