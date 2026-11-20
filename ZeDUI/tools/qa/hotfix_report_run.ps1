#Requires -Version 7.0
<#
    ZeDUI/tools/qa/hotfix_report_run.ps1  (Nov 20 2026, QA): the beta 21 hotfix report's pictures (the director's
    standing ask: before a full release test, full-screen pictures of every change). One launch per part, 4K:
      menu      the main menu (zedqa_menu_mods_run.ps1 with hfr_menu.lua)
      inv tabs tabs2 devices prompts   a game each (hotfix_<part>.txt, on the 1.0 gallery's staging)
    Every Screenshots/hfr_<name>.png moves to Screenshots/beta21_hotfix_report/<name>.png. After EVERY launch the
    director's Lua files (ModOptions.ini, ZeD_setup.txt, ZeD_tutorial.txt, ZeD_setup_seen.txt) are written back byte
    for byte, latestSave.ini is the director's again, and options.ini has fontSize=3.
    Refuses (exit 2) while ProjectZomboid64.exe runs or Zomboid/Lua/zedqa.lock says busy.
      pwsh -NoProfile -File ZeDUI/tools/qa/hotfix_report_run.ps1 -Part inv,tabs
#>
param([string[]]$Part = @("menu", "setup", "inv", "prompts", "devices", "veh", "tabs", "farm"), [string]$OutName = "beta21_hotfix_report")
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
if ($ls -and $ls.Trim() -match '^busy') { Write-Output "hotfix_report_run: not starting: $lock says busy"; exit 2 }
if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "hotfix_report_run: not starting: ProjectZomboid64.exe is running"; exit 2 }

$was = @{}
foreach ($n in $names) { $f = Join-Path $lua $n; $was[$n] = $(if (Test-Path -LiteralPath $f) { [IO.File]::ReadAllBytes($f) } else { $null }) }
function Restore-Files {
    if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "hotfix_report_run: the game still runs; files not put back yet"; return $false }
    $ok = $true
    foreach ($n in $names) {
        $f = Join-Path $lua $n
        if ($null -eq $was[$n]) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force } }
        else {
            [IO.File]::WriteAllBytes($f, $was[$n])
            if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($f)) -ne [Convert]::ToBase64String($was[$n])) { $ok = $false; Write-Output "hotfix_report_run: $n did NOT come back" }
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
    Write-Output "hotfix_report_run: latestSave.ini is the director's again, options.ini fontSize=3"
}
function Move-Shots {
    New-Item -ItemType Directory -Force $out | Out-Null
    $moved = 0
    Get-ChildItem -LiteralPath $shots -Filter "hfr_*.png" | ForEach-Object {
        Move-Item -LiteralPath $_.FullName -Destination (Join-Path $out ($_.Name.Substring(4))) -Force
        $moved++
    }
    Write-Output "hotfix_report_run: $moved pictures moved to $out"
}
$codes = @()
try {
    foreach ($pt in $Part) {
        if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "hotfix_report_run: a game is running, stopping before $pt"; $codes += 3; break }
        Write-Output "hotfix_report_run: part $pt"
        try {
            if ($pt -eq "menu" -or $pt -eq "setup" -or $pt -eq "disk") {
                & pwsh -NoProfile -File (Join-Path $here "zedqa_menu_mods_run.ps1") -ModList (Join-Path $here "zed_only_mods.txt") `
                    -Script (Join-Path $here "hfr_$pt.lua") -Tag $(if ($pt -eq "menu") { "mhfr" } elseif ($pt -eq "disk") { "mdsk" } else { "mset" }) -TimeoutSec 600
                $codes += $LASTEXITCODE
            }
            elseif ($pt -eq "farm") {
                [IO.File]::WriteAllText((Join-Path $Z "latestSave.ini"), "ZeD-QA`r`nSandbox")
                & pwsh -NoProfile -File (Join-Path $here "zedqa_mods_run.ps1") -ModList (Join-Path $here "zed_only_mods.txt") -Mode fullscreen4k -Manifest (Join-Path $here "hotfix_farm.txt")
                $codes += $LASTEXITCODE
            }
            else {
                [IO.File]::WriteAllText((Join-Path $Z "latestSave.ini"), "ZeD-QA`r`nSandbox")
                & pwsh -NoProfile -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here "hotfix_$pt.txt") -Mode fullscreen4k -Report "hotfix_$pt" -TimeoutSec 3000
                $codes += $LASTEXITCODE
            }
        }
        finally {
            if (-not (Restore-Files)) { $codes += 1 }
            Restore-Director
            Move-Shots
        }
    }
}
finally {
    if (Restore-Files) { Write-Output "hotfix_report_run: the director's four Lua files put back byte for byte" }
}
$bad = @($codes | Where-Object { $_ -ne 0 })
Write-Output "hotfix_report_run: exit codes $($codes -join ', ')"
exit $(if ($bad.Count) { 1 } else { 0 })
