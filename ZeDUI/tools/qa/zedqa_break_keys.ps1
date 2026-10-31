<#
.SYNOPSIS
    QA's break-it pass on the keyboard (Oct 31 2026; the director: "Try to break things.").
.DESCRIPTION
    Run it while the game is up on the ZeD-QA save (zedqa_run.ps1 -KeepOpen -Manifest mouse_keep.txt).
    400 presses of the game's window and panel keys, picked from a fixed seed, 40-120 ms apart: Tab
    (inventory), I, M (map), H (health), L, K, J, U, C, B, N, P, O, Escape, and Q / E / R / F. Every 50
    presses: the game's own errors counted in console.txt and ZeD's safe mode checked; at the end two
    Escapes, then a screenshot zqa_bkey_end.png and whether ZeD is still in charge. With -Quit the
    game quits at the end. Holds Zomboid/Lua/zedqa.lock. Exit 0 no errors, 1 errors, 2 refused.
#>
param([switch]$Quit, [int]$Presses = 400)
$Lua = "C:\Users\danie\Zomboid\Lua"
$QA = $PSScriptRoot
$log = "C:\Users\danie\Zomboid\console.txt"
$lock = Join-Path $Lua "zedqa.lock"
$proc = Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { "the game is not running"; exit 2 }
if ((Get-Content $lock -Raw -ErrorAction SilentlyContinue) -match '^busy') { "the lock says busy; not starting"; exit 2 }
Set-Content -Path $lock -Value "busy zedqa_break_keys" -NoNewline
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class ZedKeyInput {
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint type);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
"@
function Front {
    $p = Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $p) { return $false }
    $fg = [uint32]0
    [void][ZedKeyInput]::GetWindowThreadProcessId([ZedKeyInput]::GetForegroundWindow(), [ref]$fg)
    if ($fg -ne [uint32]$p.Id) { try { & (Join-Path $QA "pzfront.ps1") | Out-Null } catch { }; Start-Sleep -Milliseconds 800
        [void][ZedKeyInput]::GetWindowThreadProcessId([ZedKeyInput]::GetForegroundWindow(), [ref]$fg) }
    return ($fg -eq [uint32]$p.Id)
}
function Key($vk) {
    $sc = [byte][ZedKeyInput]::MapVirtualKey($vk, 0)
    [ZedKeyInput]::keybd_event([byte]$vk, $sc, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 30
    [ZedKeyInput]::keybd_event([byte]$vk, $sc, 2, [UIntPtr]::Zero)
}
function LogText { ((Get-Content $log -Raw -ErrorAction SilentlyContinue) -replace "`0", "") }
function Counts { $t = LogText; return @([regex]::Matches($t, 'Exception thrown').Count, [regex]::Matches($t, 'stepped aside').Count, $t.Length) }
function Next-Go {
    $cf = Join-Path $Lua "zedqa.counter"; $gf = Join-Path $Lua "zedqa.go"
    [long]$n = 9999
    $t = Get-Content $cf -Raw -ErrorAction SilentlyContinue
    if ($t -and $t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }
    $cur = Get-Content $gf -Raw -ErrorAction SilentlyContinue
    if ($cur -and $cur.Trim() -match '^\d+$' -and [long]$cur.Trim() -ge $n) { $n = [long]$cur.Trim() }
    $n++; Set-Content -Path $cf -Value "$n" -NoNewline; return $n
}
function Run-Lua($code, $pattern, $wait = 20) {
    $g = Next-Go
    Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value ($code -replace '__GO__', "$g") -NoNewline
    Set-Content -Path (Join-Path $Lua "zedqa.go") -Value "$g`n" -NoNewline
    for ($i = 0; $i -lt $wait * 4; $i++) { Start-Sleep -Milliseconds 250; $m = [regex]::Match((LogText), "ZEDQA bkey $g ([^\r\n]+)"); if ($m.Success) { return $m.Groups[1].Value } }
    return ""
}
# Tab, I, M, H, L, K, J, U, C, B, N, P, O, Escape, Q, E, R, F
$keys = @(0x09, 0x49, 0x4D, 0x48, 0x4C, 0x4B, 0x4A, 0x55, 0x43, 0x42, 0x4E, 0x50, 0x4F, 0x1B, 0x51, 0x45, 0x52, 0x46)
$seed = 1993
function Rnd($n) { $script:seed = ($script:seed * 1103515245 + 12345) % 2147483648; return [int]($script:seed % $n) }
$errors = 0; $first = ""
try {
    if (-not (Front)) { "the game is not the front window"; $errors++; return }
    $start = Counts
    for ($i = 1; $i -le $Presses; $i++) {
        if (-not (Front)) { "lost the front window at press $i"; $errors++; break }
        Key $keys[(Rnd $keys.Count)]
        Start-Sleep -Milliseconds (40 + (Rnd 80))
        if ($i % 50 -eq 0) {
            $now = Counts
            $ne = $now[0] - $start[0]; $ns = $now[1] - $start[1]
            "after $i presses: $ne exception(s), safe mode $ns"
            if (($ne -gt 0 -or $ns -gt 0) -and -not $first) {
                $tail = (LogText).Substring($start[2])
                $m = [regex]::Match($tail, '(?s)(Exception thrown|stepped aside).{0,600}')
                if ($m.Success) { $first = (($m.Value -split "`r?`n") | Select-Object -First 6) -join " | " }
            }
        }
    }
    Key 0x1B; Start-Sleep -Milliseconds 400; Key 0x1B; Start-Sleep -Milliseconds 800
    $end = Counts
    $errors += ($end[0] - $start[0]) + ($end[1] - $start[1])
    $state = Run-Lua @'
local function say(s) print("ZEDQA bkey __GO__ " .. tostring(s)) end
local safe = false; pcall(function() safe = ZeD.Safe.on() end)
getCore():TakeFullScreenshot("zqa_bkey_end.png")
say("END safe " .. tostring(safe) .. " char open " .. tostring(ZeD_CharacterWindow.isOpen()) .. " world open " .. tostring(ZeD_WorldWindow.isOpen()) .. " paused " .. tostring(getGameSpeed() == 0))
'@ "END"
    "state: $state"
    if ($first) { "first error: $first" }
} finally {
    if ($Quit) {
        $g = Next-Go
        Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value "getCore():quitToDesktop()" -NoNewline
        Set-Content -Path (Join-Path $Lua "zedqa.go") -Value "$g`n" -NoNewline
        Start-Sleep -Seconds 15
    }
    Set-Content -Path $lock -Value "free" -NoNewline
}
"total errors: $errors"
if ($errors -gt 0) { exit 1 } else { exit 0 }
