#Requires -Version 7.0
<#
    ZeDUI/tools/qa/kiss_pics_run.ps1  (Nov 22 2026, QA, the KISS audit): full-screen pictures of the friction the KISS
    audit ranked, for the report page that puts the director's design calls to him. One launch per part, on the 1.0
    gallery's staging (the story stage, gallery_unload, G1, hfr_common.lua), as beast_report_run.ps1:
      loot screen pad   4K full screen      kiss_pics_<part>.txt with kiss_<part>.lua
      deck              windowed 1280x800   kiss_pics_deck.txt with kiss_deck.lua (the Steam Deck's own size)
    Every Screenshots/kiss_<name>.png moves to Screenshots/<OutName>/<name>.png. After EVERY launch the director's Lua
    files (ModOptions.ini, ZeD_setup.txt, ZeD_tutorial.txt, ZeD_setup_seen.txt) are written back byte for byte,
    latestSave.ini is the director's again, and options.ini has fontSize=3 and language=EN.
    Refuses (exit 2) while ProjectZomboid64.exe runs or Zomboid/Lua/zedqa.lock says busy.
      pwsh -NoProfile -File ZeDUI/tools/qa/kiss_pics_run.ps1 -Part loot,screen
#>
param([string[]]$Part = @("loot", "screen", "pad", "deck"), [string]$OutName = "kiss_report")
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
if ($ls -and $ls.Trim() -match '^busy') { Write-Output "kiss_pics_run: not starting: $lock says busy"; exit 2 }
if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "kiss_pics_run: not starting: ProjectZomboid64.exe is running"; exit 2 }

# (a file read inside $( ) that is 0 bytes unrolls to $null and reads as "absent": assign directly)
$was = @{}
foreach ($n in $names) { $f = Join-Path $lua $n; if (Test-Path -LiteralPath $f) { $was[$n] = [IO.File]::ReadAllBytes($f) } else { $was[$n] = $null } }
function Restore-Files {
    if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "kiss_pics_run: the game still runs; files not put back yet"; return $false }
    $ok = $true
    foreach ($n in $names) {
        $f = Join-Path $lua $n
        if ($null -eq $was[$n]) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force } }
        else {
            [IO.File]::WriteAllBytes($f, $was[$n])
            if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($f)) -ne [Convert]::ToBase64String($was[$n])) { $ok = $false; Write-Output "kiss_pics_run: $n did NOT come back" }
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
        $t = [regex]::Replace($t, '(?m)^language=.*$', 'language=EN')
        [IO.File]::WriteAllText($oi, $t)
    }
    Write-Output "kiss_pics_run: latestSave.ini is the director's again, options.ini fontSize=3 language=EN"
}
function Move-Shots {
    New-Item -ItemType Directory -Force $out | Out-Null
    $moved = 0
    Get-ChildItem -LiteralPath $shots -Filter "kiss_*.png" | ForEach-Object {
        Move-Item -LiteralPath $_.FullName -Destination (Join-Path $out ($_.Name.Substring(5))) -Force
        $moved++
    }
    Write-Output "kiss_pics_run: $moved pictures moved to $out"
}
$codes = @()
try {
    foreach ($pt in $Part) {
        if ((Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue)) { Write-Output "kiss_pics_run: a game is running, stopping before $pt"; $codes += 3; break }
        $man = Join-Path $here "kiss_pics_$pt.txt"
        if (-not (Test-Path -LiteralPath $man)) { Write-Output "kiss_pics_run: no manifest $man"; $codes += 4; continue }
        Write-Output "kiss_pics_run: part $pt"
        try {
            [IO.File]::WriteAllText((Join-Path $Z "latestSave.ini"), "ZeD-QA`r`nSandbox")
            if ($pt -eq "deck") {
                & pwsh -NoProfile -File (Join-Path $here "zedqa_run.ps1") -Manifest $man -Mode windowed -Width 1280 -Height 800 -Report "kiss_pics_$pt" -TimeoutSec 3000
            }
            else {
                & pwsh -NoProfile -File (Join-Path $here "zedqa_run.ps1") -Manifest $man -Mode fullscreen4k -Report "kiss_pics_$pt" -TimeoutSec 3000
            }
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
    if (Restore-Files) { Write-Output "kiss_pics_run: the director's four Lua files put back byte for byte" }
}
$bad = @($codes | Where-Object { $_ -ne 0 })
Write-Output "kiss_pics_run: exit codes $($codes -join ', ')"
exit $(if ($bad.Count) { 1 } else { 0 })
