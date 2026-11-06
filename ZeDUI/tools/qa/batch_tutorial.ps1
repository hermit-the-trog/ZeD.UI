#Requires -Version 7.0
# ZeDUI/tools/qa/batch_tutorial.ps1  (Nov 6 2026, QA): the game's Tutorial started once on this build: launches with ZeD on, calls the game's own start, waits for the world, keeps
# console.txt as qa/tutorial_console.txt, prints its error count and what mods it says loaded, and closes the game this script started. Mod list and lock put back.
$ErrorActionPreference = "Stop"
$Z = "C:\Users\you\Zomboid"; $Lua = "$Z\Lua"; $Lock = "$Lua\zedqa.lock"; $Default = "$Z\mods\default.txt"; $Console = "$Z\console.txt"
$GameDir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
$Utf8 = New-Object System.Text.UTF8Encoding($false)
function WriteT($p, $t) { [IO.File]::WriteAllText($p, $t, $Utf8) }
function ReadT($p) { try { [string](Get-Content -LiteralPath $p -Raw -ErrorAction Stop) } catch { "" } }
if ((ReadT $Lock) -match '^busy') { "not starting: the lock is busy"; exit 2 }
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "not starting: the game is running"; exit 2 }
WriteT $Lock "busy"
$keep = ReadT $Default
$game = $null
try {
    WriteT $Default "VERSION = 1,`r`n`r`nmods`r`n{`r`n    mod = ZeD_UI,`r`n}`r`n`r`nmaps`r`n{`r`n}`r`n"
    $game = Start-Process -FilePath "$GameDir\ProjectZomboid64.exe" -ArgumentList "-debug -nosteam" -WorkingDirectory $GameDir -PassThru
    Start-Sleep -Seconds 10
    $t0 = Get-Date
    while (-not ((ReadT $Console) -match '\[ZeD\.QA\] bridge armed \(main menu')) {
        if ($game.HasExited) { throw "the game closed while loading" }
        if (((Get-Date) - $t0).TotalSeconds -gt 300) { throw "the bridge never armed at the main menu" }
        Start-Sleep -Seconds 2
    }
    Start-Sleep -Seconds 5
    Copy-Item "$PSScriptRoot\zedqa_tutorial_start.lua" "$Lua\zedqa.lua" -Force
    $c = "$Lua\zedqa.counter"; [long]$n = 9999; $t = (ReadT $c).Trim(); if ($t -match '^\d+$') { $n = [long]$t }; $n++; WriteT $c "$n"; WriteT "$Lua\zedqa.go" "$n"
    Start-Sleep -Seconds 100
    & "$PSScriptRoot\pzfront.ps1" 2>&1 | Out-Null
    Start-Sleep -Seconds 40
    $keepLog = [IO.Path]::GetFullPath("$PSScriptRoot\..\..\qa\tutorial_console.txt")
    Copy-Item $Console $keepLog -Force
    $log = (ReadT $keepLog) -replace "`0", ""
    "exceptions: " + ([regex]::Matches($log, 'Exception thrown')).Count
    "ZeD lines after the start: " + ([regex]::Matches(($log -split 'ZEDQA tut starting')[-1], 'MOD:ZeD|ZeD')).Count
    ($log -split "\r?\n") | Where-Object { $_ -match 'ZEDQA tut|ResetLua|startTutorial|Tutorial|bridge armed|game started|gameMode' } | Select-Object -Last 14 | ForEach-Object { $_.Substring(0, [Math]::Min(170, $_.Length)) }
}
finally {
    if ($game -and -not $game.HasExited) { Stop-Process -Id $game.Id -Force; Start-Sleep -Seconds 3 }
    WriteT $Default $keep
    WriteT $Lock "free"
    "mod list and lock put back"
}
