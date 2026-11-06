#Requires -Version 7.0
# ZeDUI/tools/qa/zedqa_menu_bars_run.ps1  (Nov 5 2026, QA): the main menu's scroll bars with the real mouse. Starts the game
# (4K fullscreen at 1.75x, or -Width / -Height a window at Auto, plus Large text with -Large), runs zedqa_menu_bars.lua; when it
# stops on Occupation and traits, presses the first long bar with the real mouse: down arrow, track, up arrow, wheel over the
# list. Results in qa/menu_bars_<size>.log. Puts back ModOptions.ini, autoload and the lock.
param([int]$Width = 0, [int]$Height = 0, [switch]$Large, [int]$TimeoutSec = 400, [string]$ModList = "")   # (-ModList: default.txt for the run, so the load order runs over)
$ErrorActionPreference = "Stop"
$U = New-Object System.Text.UTF8Encoding($false)
$Z = "C:\Users\you\Zomboid"; $Lua = "$Z\Lua"; $Lock = "$Lua\zedqa.lock"; $MO = "$Lua\ModOptions.ini"; $Con = "$Z\console.txt"
$GameDir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
$tag = $(if ($Width -gt 0) { "${Width}x$Height" } else { "4k" })
$Out = [IO.Path]::GetFullPath("$PSScriptRoot\..\..\qa\menu_bars_$tag.log")
function W($p, $t) { [IO.File]::WriteAllText($p, $t, $U) }
function RT($p) { try { [string](Get-Content -LiteralPath $p -Raw -ErrorAction Stop) } catch { "" } }
function L { (RT $Con) -replace "`0", "" }
function Up { [bool](Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) }
function Bump { [long]$n = 9999; $t = RT "$Lua\zedqa.counter"; if ($t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }; $n++; W "$Lua\zedqa.counter" "$n"; W "$Lua\zedqa.go" "$n" }
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class MbMouse {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
}
"@
[void][MbMouse]::SetProcessDPIAware()
function Click($x, $y, $holdMs = 120) {
    [void][MbMouse]::SetCursorPos($x, $y); Start-Sleep -Milliseconds 250
    [MbMouse]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds $holdMs
    [MbMouse]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 500
}
function Wheel($x, $y, $delta) {
    [void][MbMouse]::SetCursorPos($x, $y); Start-Sleep -Milliseconds 250
    [MbMouse]::mouse_event(0x800, 0, 0, [BitConverter]::ToUInt32([BitConverter]::GetBytes([int]$delta), 0), [UIntPtr]::Zero); Start-Sleep -Milliseconds 500
}
if ((RT $Lock) -match '^busy') { "lock busy"; exit 2 }
if (Up) { "game running"; exit 2 }
W $Lock "busy"
$Default = "$Z\mods\default.txt"; $keepD = RT $Default
$keepM = RT $MO; $keepA = RT "$Lua\zedqa.autoload"
Remove-Item "$Lua\zedqa_mbs_end.txt", "$Lua\zedqa_mbs_bars.txt", "$Lua\zedqa_mbs_large.txt" -ErrorAction SilentlyContinue
try {
    if ($Large) { W "$Lua\zedqa_mbs_large.txt" "1" }
    if ($ModList) {
        $ids = @(Get-Content $ModList | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne "ZeD_UI" }) + @("ZeD_UI")
        W $Default ("VERSION = 1,`r`n`r`nmods`r`n{`r`n" + (($ids | ForEach-Object { "    mod = $_," }) -join "`r`n") + "`r`n}`r`n`r`nmaps`r`n{`r`n}`r`n")
    }
    $lines = @(($keepM -split "\r?\n") | Where-Object { $_ -ne "" -and $_ -notmatch '\|ZeD_UI\|uiScale\|' })
    if ($Width -le 0) { $lines += "combobox|ZeD_UI|uiScale|7" }
    W $MO (($lines -join "`r`n") + "`r`n")
    W "$Lua\zedqa.autoload" "0"
    if ($Width -gt 0) { & "$PSScriptRoot\pzlaunchwin.ps1" -MainMenu -Width $Width -Height $Height | Out-Null }
    else { Start-Process "$GameDir\ProjectZomboid64.exe" -ArgumentList "-debug" -WorkingDirectory $GameDir | Out-Null }
    Start-Sleep 10
    $t0 = Get-Date
    while (-not ((L) -match '\[ZeD\.QA\] bridge armed \(main menu')) { if (-not (Up)) { throw "closed" }; if (((Get-Date) - $t0).TotalSeconds -gt 600) { throw "no bridge" }; Start-Sleep 2 }
    Start-Sleep 5
    Copy-Item "$PSScriptRoot\zedqa_menu_bars.lua" "$Lua\zedqa.lua" -Force; Bump
    $t0 = Get-Date
    while (-not ((L) -match 'ZEDQA mbs watching')) { if (-not (Up)) { throw "closed in the walk" }; if (((Get-Date) - $t0).TotalSeconds -gt $TimeoutSec) { "walk TIMEOUT"; break }; Start-Sleep 2 }
    if ((L) -match 'ZEDQA mbs watching') {
        & "$PSScriptRoot\pzfront.ps1" | Out-Null; Start-Sleep 1
        $bar = @((RT "$Lua\zedqa_mbs_bars.txt") -split "\r?\n" | Where-Object { $_ }) | Select-Object -First 1
        if ($bar -and $Width -le 0) {   # (fullscreen only: the bar's places are the game's, and a window's are not the screen's)
            $k, $ax, $ay, $h, $ar = $bar -split " "; $ax = [int]$ax; $ay = [int]$ay; $h = [int]$h; $ar = [int]$ar
            "real mouse on $k"
            Click $ax ($ay + $h - [int]($ar / 2)); Click $ax ($ay + $h - [int]($ar / 2))   # the down arrow, twice
            Click $ax ($ay + $h - $ar - 6)                                                 # the track under the thumb
            Click $ax ($ay + $h - [int]($ar / 2)) 900                                      # the down arrow held: repeats
            Click $ax ($ay + [int]($ar / 2))                                               # the up arrow
            Wheel ($ax - 80) ($ay + [int]($h / 2)) -120                                    # the wheel over the list
            Wheel ($ax - 80) ($ay + [int]($h / 2)) 120
            Start-Sleep 1
        }
        W "$Lua\zedqa_mbs_end.txt" "1"
        $t0 = Get-Date
        while (-not ((L) -match 'ZEDQA mbs DONE')) { if (((Get-Date) - $t0).TotalSeconds -gt 30) { break }; Start-Sleep 1 }
    }
}
finally {
    (((L) -split "\r?\n") | Where-Object { $_ -match 'ZEDQA mbs|attempted index|Exception thrown' } | ForEach-Object { $_ -replace '^.*?ZEDQA ', 'ZEDQA ' }) -join "`n" | Set-Content $Out
    if (Up) { W "$Lua\zedqa.lua" "getCore():quitToDesktop()"; Bump; for ($i = 0; $i -lt 60 -and (Up); $i++) { Start-Sleep 2 } }
    if ($Width -gt 0 -and -not (Up)) { & "$PSScriptRoot\pzrestorewin.ps1" | Out-Null }
    if (Up) { "game still running: nothing put back" } else { W $MO $keepM; W "$Lua\zedqa.autoload" $keepA; W $Default $keepD }
    Remove-Item "$Lua\zedqa_mbs_end.txt", "$Lua\zedqa_mbs_large.txt" -ErrorAction SilentlyContinue
    W $Lock "free"
}
