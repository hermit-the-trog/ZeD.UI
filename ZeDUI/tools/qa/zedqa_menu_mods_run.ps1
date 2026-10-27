#Requires -Version 7.0
<#
.SYNOPSIS
    A main menu script with other mods on (Oct 25 2026: the Looks screen with
    Spongie's Character Customisation, zedqa_spncc_looks.lua).

.DESCRIPTION
    Writes mods/default.txt as -ModList plus ZeD_UI, sets ZeD's UI scale to 1.75x in
    Lua/ModOptions.ini, launches ProjectZomboid64.exe -debug (fullscreen, the
    director's options.ini), waits for "[ZeD.QA] bridge armed (main menu", runs
    -Script through the bridge until "ZEDQA <tag> DONE", quits to the desktop and
    puts default.txt, ModOptions.ini and the lock back. Refuses to start (exit 2)
    while the lock is busy or the game runs. Prints the script's ZEDQA lines.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ModList,
    [Parameter(Mandatory)][string]$Script,
    [Parameter(Mandatory)][string]$Tag,
    [int]$TimeoutSec = 300,
    [string]$Maps = ""   # (Oct 26 2026, compat round 3) a file of map folder names for default.txt's maps section (Muldraugh, KY added last)
)
$ErrorActionPreference = "Stop"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Z = "C:\Users\danie\Zomboid"
$Lua = Join-Path $Z "Lua"
$Lock = Join-Path $Lua "zedqa.lock"
$Default = Join-Path $Z "mods\default.txt"
$ModOptions = Join-Path $Lua "ModOptions.ini"
$Console = Join-Path $Z "console.txt"
$GameDir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
function Write-T([string]$p, [string]$t) { [System.IO.File]::WriteAllText($p, $t, $Utf8NoBom) }
function Read-T([string]$p) { try { return [string](Get-Content -LiteralPath $p -Raw -ErrorAction Stop) } catch { return "" } }
function Log { return ((Read-T $Console) -replace "`0", "") }
function Running { return [bool](Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) }
function Bump {
    $c = Join-Path $Lua "zedqa.counter"
    [long]$n = 9999; $t = Read-T $c; if ($t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }
    $n++; Write-T $c "$n"; Write-T (Join-Path $Lua "zedqa.go") "$n"
}

if ((Read-T $Lock) -match '^busy') { Write-Output "not starting: the lock is busy"; exit 2 }
if (Running) { Write-Output "not starting: the game is running"; exit 2 }
Write-T $Lock "busy"
$keepDefault = Read-T $Default
$keepOptions = Read-T $ModOptions
$keepAuto = Read-T (Join-Path $Lua "zedqa.autoload")
try {
    $mapLines = ""
    if ($Maps) { $mapLines = ((@(Get-Content $Maps | ForEach-Object { $_.Trim() } | Where-Object { $_ }) + @("Muldraugh, KY") | ForEach-Object { "    map = $_," }) -join "`r`n") + "`r`n" }
    $ids = @(Get-Content $ModList | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne "ZeD_UI" }) + @("ZeD_UI")
    Write-T $Default ("VERSION = 1,`r`n`r`nmods`r`n{`r`n" + (($ids | ForEach-Object { "    mod = $_," }) -join "`r`n") + "`r`n}`r`n`r`nmaps`r`n{`r`n" + $mapLines + "}`r`n")
    $lines = @(($keepOptions -split "\r?\n") | Where-Object { $_ -ne "" -and $_ -notmatch '\|ZeD_UI\|uiScale\|' }) + @("combobox|ZeD_UI|uiScale|7")
    Write-T $ModOptions (($lines -join "`r`n") + "`r`n")
    Write-T (Join-Path $Lua "zedqa.autoload") "0"
    Start-Process -FilePath (Join-Path $GameDir "ProjectZomboid64.exe") -ArgumentList "-debug" -WorkingDirectory $GameDir | Out-Null
    Start-Sleep -Seconds 10
    $t0 = Get-Date
    while (-not ((Log) -match '\[ZeD\.QA\] bridge armed \(main menu')) {
        if (-not (Running)) { throw "the game closed while loading" }
        if (((Get-Date) - $t0).TotalSeconds -gt 600) { throw "the bridge never armed at the main menu" }
        Start-Sleep -Seconds 2
    }
    Start-Sleep -Seconds 5
    Copy-Item -LiteralPath $Script -Destination (Join-Path $Lua "zedqa.lua") -Force
    Bump
    $t0 = Get-Date
    while (-not ((Log) -match "ZEDQA $Tag DONE")) {
        if (-not (Running)) { throw "the game closed during the script" }
        if (((Get-Date) - $t0).TotalSeconds -gt $TimeoutSec) { Write-Output "TIMEOUT"; break }
        Start-Sleep -Seconds 2
    }
    (Log) -split "\r?\n" | Where-Object { $_ -match "ZEDQA $Tag " } | ForEach-Object { ($_ -replace '^.*?ZEDQA ', 'ZEDQA ') }
}
finally {
    if (Running) {
        Write-T (Join-Path $Lua "zedqa.lua") "getCore():quitToDesktop()"
        Bump
        for ($i = 0; $i -lt 60 -and (Running); $i++) { Start-Sleep -Seconds 2 }
    }
    if (Running) { Write-Output "the game is still running: default.txt and ModOptions.ini NOT put back" }
    else {
        Write-T $Default $keepDefault; Write-T $ModOptions $keepOptions; Write-T (Join-Path $Lua "zedqa.autoload") $keepAuto
        Write-Output "default.txt, ModOptions.ini and autoload put back"
    }
    Write-T $Lock "free"
}
