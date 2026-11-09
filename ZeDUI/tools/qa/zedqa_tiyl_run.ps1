#Requires -Version 7.0
# ZeDUI/tools/qa/zedqa_tiyl_run.ps1  (Nov 5 2026, QA; punch list 64): one new game with This Is Your Life on, through ZeD's
# screens. -Pick "origin 2" or "story bakesale". Writes default.txt (the mod + ZeD_UI), starts the game at 1.75x, runs
# zedqa_tiyl_menu.lua at the main menu, waits for the world, runs zedqa_tiyl_game.lua, quits, then puts back default.txt,
# ModOptions.ini, autoload and latestSave.ini and removes only the save folder this run made. Output: qa/tiyl_<pick>.log.
param([Parameter(Mandatory)][string]$Pick, [int]$TimeoutSec = 420)
$ErrorActionPreference = "Stop"
$U = New-Object System.Text.UTF8Encoding($false)
$Z = "$($env:USERPROFILE)\Zomboid"; $Lua = "$Z\Lua"; $Lock = "$Lua\zedqa.lock"; $Default = "$Z\mods\default.txt"; $MO = "$Lua\ModOptions.ini"; $Con = "$Z\console.txt"; $Latest = "$Z\latestSave.ini"
$GameDir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
$Out = [IO.Path]::GetFullPath("$PSScriptRoot\..\..\qa\tiyl_$($Pick -replace ' ','_').log")
function W($p, $t) { [IO.File]::WriteAllText($p, $t, $U) }
function RT($p) { try { [string](Get-Content -LiteralPath $p -Raw -ErrorAction Stop) } catch { "" } }
function L { (RT $Con) -replace "`0", "" }
function Up { [bool](Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) }
function Bump { [long]$n = 9999; $t = RT "$Lua\zedqa.counter"; if ($t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }; $n++; W "$Lua\zedqa.counter" "$n"; W "$Lua\zedqa.go" "$n" }
function Run($s) { Copy-Item -LiteralPath $s "$Lua\zedqa.lua" -Force; Bump }
if ((RT $Lock) -match '^busy') { "lock busy"; exit 2 }
if (Up) { "game running"; exit 2 }
W $Lock "busy"
$keepD = RT $Default; $keepM = RT $MO; $keepA = RT "$Lua\zedqa.autoload"; $keepL = RT $Latest
$before = @(Get-ChildItem "$Z\Saves\Sandbox" -Directory | ForEach-Object Name)
try {
    W "$Lua\zedqa_tiyl_pick.txt" "$Pick`n"
    W $Default "VERSION = 1,`r`n`r`nmods`r`n{`r`n    mod = ThisIsYourLife,`r`n    mod = ZeD_UI,`r`n}`r`n`r`nmaps`r`n{`r`n}`r`n"
    $lines = @(($keepM -split "\r?\n") | Where-Object { $_ -ne "" -and $_ -notmatch '\|ZeD_UI\|uiScale\|' }); $lines += "combobox|ZeD_UI|uiScale|7"
    W $MO (($lines -join "`r`n") + "`r`n")
    W "$Lua\zedqa.autoload" "0"
    Start-Process "$GameDir\ProjectZomboid64.exe" -ArgumentList "-debug" -WorkingDirectory $GameDir | Out-Null
    Start-Sleep 10
    $t0 = Get-Date
    while (-not ((L) -match '\[ZeD\.QA\] bridge armed \(main menu')) { if (-not (Up)) { throw "closed" }; if (((Get-Date) - $t0).TotalSeconds -gt 600) { throw "no bridge" }; Start-Sleep 2 }
    Start-Sleep 5
    Run "$PSScriptRoot\zedqa_tiyl_menu.lua"
    $t0 = Get-Date
    while (-not ((L) -match 'ZEDQA tym DONE')) { if (-not (Up)) { throw "closed in the menu" }; if (((Get-Date) - $t0).TotalSeconds -gt 120) { "menu TIMEOUT"; break }; Start-Sleep 2 }
    $t0 = Get-Date; $lastClick = (Get-Date).AddMinutes(-5)
    while (-not ((L) -match '\[ZeD\.QA\] bridge armed \(in game')) { if (-not (Up)) { throw "closed while loading" }; if (((Get-Date) - $t0).TotalSeconds -gt $TimeoutSec) { "world TIMEOUT"; break }; if (((L) -match 'game loading took') -and (((Get-Date) - $lastClick).TotalSeconds -gt 25)) { $lastClick = Get-Date; Start-Sleep 8; & pwsh -NoProfile -File "$PSScriptRoot\pz_startclick.ps1" | Out-Null }; Start-Sleep 3 }
    if ((L) -match '\[ZeD\.QA\] bridge armed \(in game') {
        Start-Sleep 12
        Run "$PSScriptRoot\zedqa_tiyl_game.lua"
        $t0 = Get-Date
        while (-not ((L) -match 'ZEDQA tyg DONE')) { if (-not (Up)) { break }; if (((Get-Date) - $t0).TotalSeconds -gt 90) { "game script TIMEOUT"; break }; Start-Sleep 2 }
    }
}
finally {
    $log = L
    (($log -split "\r?\n") | Where-Object { $_ -match 'ZEDQA ty[mg] |This Is Your Life|attempted index|Exception thrown|ERROR: ' }) -join "`n" | Set-Content $Out
    if (Up) { W "$Lua\zedqa.lua" "getCore():quitToDesktop()"; Bump; for ($i = 0; $i -lt 60 -and (Up); $i++) { Start-Sleep 2 } }
    if (Up) { "game still running: nothing put back" } else {
        W $Default $keepD; W $MO $keepM; W "$Lua\zedqa.autoload" $keepA; W $Latest $keepL
        $new = @(Get-ChildItem "$Z\Saves\Sandbox" -Directory | Where-Object { $before -notcontains $_.Name })
        foreach ($d in $new) { "removing this run's save: $($d.Name)"; Remove-Item -Recurse -Force $d.FullName }
    }
    W $Lock "free"
}
