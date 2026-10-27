<#
.SYNOPSIS
    The window edges and Solid while in use, with the real mouse, in game (Oct 27 2026).
.DESCRIPTION
    Run it while the game is up on the ZeD-QA save with both windows open, for example
    after zedqa_run.ps1 -KeepOpen with a manifest of zedqa_prelude.lua. For the
    Character window: the real pointer rests on the bottom edge, then on the right
    edge, and the bridge times how long after the pointer arrives the handle shows
    (it should take about 350 ms, so passing over an edge shows nothing); a drag on
    the bottom edge changes the height only, a drag on the right edge (after the rest)
    the width only. Then with see-through at 60 and Solid while in use on, the pointer
    over the Character window: it goes solid, the World window stays see-through.
    Screenshots zqa_we_*.png. The settings and the window places are put back.
    With -Quit the game quits at the end and -ModOptionsKeep (the director's file the
    runner kept aside, <report>.modoptions.ini) goes back over Lua/ModOptions.ini.
    The real pointer moves only while the game is the front window and the computer
    has been idle at least -IdleSec seconds (default 0: on this PC something always
    registers input, so the idle time reads 0 even with nobody there). Holds Zomboid/Lua/zedqa.lock.
    (Mouse.setXY moves the game's idea of the pointer, not what update() reads for
    the edges, hence real input.)
    Exit codes: 0 every check passed, 1 a check failed or the run broke, 2 refused.
#>
param([switch]$Quit, [string]$ModOptionsKeep = "", [int]$IdleSec = 0)
$Lua = "C:\Users\danie\Zomboid\Lua"
$QA = $PSScriptRoot
$log = "C:\Users\danie\Zomboid\console.txt"
$lock = Join-Path $Lua "zedqa.lock"
$proc = Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { "the game is not running; start it first (zedqa_run.ps1 -KeepOpen)"; exit 2 }
if ((Get-Content $lock -Raw -ErrorAction SilentlyContinue) -match '^busy') { "the lock says busy; not starting"; exit 2 }
Set-Content -Path $lock -Value "busy zedqa_window_edges_run" -NoNewline

Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class ZedWeInput {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [StructLayout(LayoutKind.Sequential)] public struct LII { public uint cbSize; public uint dwTime; }
  [DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref LII p);
  public static uint IdleMs() { LII l = new LII(); l.cbSize = (uint)Marshal.SizeOf(l); GetLastInputInfo(ref l); return (uint)Environment.TickCount - l.dwTime; }
}
"@
[void][ZedWeInput]::SetProcessDPIAware()

$fails = 0
function Check($ok, $what) { if ($ok) { "PASS $what" } else { $script:fails++; "FAIL $what" } }
function Next-Go {
    $cf = Join-Path $Lua "zedqa.counter"; $gf = Join-Path $Lua "zedqa.go"
    [long]$n = 9999
    $t = Get-Content $cf -Raw -ErrorAction SilentlyContinue
    if ($t -and $t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }
    $cur = Get-Content $gf -Raw -ErrorAction SilentlyContinue
    if ($cur -and $cur.Trim() -match '^\d+$' -and [long]$cur.Trim() -ge $n) { $n = [long]$cur.Trim() }
    $n++
    Set-Content -Path $cf -Value "$n" -NoNewline
    return $n
}
function Send-Go($n) { Set-Content -Path (Join-Path $Lua "zedqa.go") -Value "$n`n" -NoNewline }
function LogText { ((Get-Content $log -Raw -ErrorAction SilentlyContinue) -replace "`0", "") }
function Wait-Log($pattern, $seconds) {
    for ($i = 0; $i -lt $seconds * 4; $i++) {
        Start-Sleep -Milliseconds 250
        $m = [regex]::Match((LogText), $pattern)
        if ($m.Success) { return $m }
    }
    return $null
}

# the Lua side: a prelude, then one job; every line is "ZEDQA we <go> ..."
$Prelude = @'
local G = "__GO__"
local function say(s) print("ZEDQA we " .. G .. " " .. tostring(s)) end
local T = ZeD.T
local S = ZeD.Settings
local c = ZeD_CharacterWindow.getWindow()
local w = ZeD_WorldWindow.getWindow()
local function pt(x, y) return math.floor(x) .. "," .. math.floor(y) end
local function size(win) return math.floor(win:getWidth()) .. "x" .. math.floor(win:getHeight()) end
'@
$Jobs = @{
    setup = @'
ZEDQA_WE = ZEDQA_WE or { see = S.seeThroughIndex(), solid = S.solidInUse() }
local ax, ay, cw, ch = c:getAbsoluteX(), c:getAbsoluteY(), c:getWidth(), c:getHeight()
-- the bottom edge a third of the way along (clear of the corners), the right edge half way
-- down, the body (the middle of the window)
say("TARGETS " .. pt(ax + cw / 3, ay + ch - T.px(2)) .. " " .. pt(ax + cw - T.px(2), ay + ch / 2) .. " "
    .. pt(ax + cw / 2, ay + ch / 2) .. " SIZE " .. size(c) .. " OPEN " .. tostring(c:isVisible()) .. "/" .. tostring(w and w:isVisible()))
'@
    # samples the Character window every frame for 1.5 s from now: when the pointer is first
    # on an edge zone, and when the handle first shows
    watch = @'
local t0 = getTimestampMs()
local zoneAt, litAt, zone, lit
local function f()
    local now = getTimestampMs() - t0
    if not zoneAt and c._rzZone then zoneAt, zone = now, c._rzZone end
    if not litAt and c._rzLit then litAt, lit = now, c._rzLit end
    if now >= 1500 then
        Events.OnTick.Remove(f)
        say("WATCH zone " .. tostring(zone) .. " at " .. tostring(zoneAt) .. " lit " .. tostring(lit) .. " at " .. tostring(litAt)
            .. " mouse " .. getMouseX() .. "," .. getMouseY())
    end
end
Events.OnTick.Add(f)
'@
    probe = @'
say("PROBE mouse " .. getMouseX() .. "," .. getMouseY() .. " SIZE " .. size(c) .. " RZ " .. tostring(c._rzLit)
    .. " SEE " .. tostring(c._seeA) .. " WSEE " .. tostring(w and w._seeA) .. " ON " .. tostring(c:pointerOn()))
'@
    solid = @'
S.setSeeThrough(#S.seeThroughKeys)
S.setSolidInUse(true)
say("SOLID set: see-through " .. tostring(S.seeThrough()) .. " solid " .. tostring(S.solidInUse()))
'@
    shot = @'
getCore():TakeFullScreenshot("__NAME__")
say("SHOT __NAME__")
'@
    restore = @'
if ZEDQA_WE then S.setSolidInUse(ZEDQA_WE.solid); S.setSeeThrough(ZEDQA_WE.see) end
ZEDQA_WE = nil
if ZeD_Window and ZeD_Window.resetLayout then ZeD_Window.resetLayout() end
say("RESTORED see-through " .. tostring(S.seeThrough()) .. " solid " .. tostring(S.solidInUse()) .. " size " .. size(c))
'@
}
function Run-Job($job, $subs, $wait = 30) {
    $g = Next-Go
    $text = ($Prelude + "`n" + $Jobs[$job]) -replace '__GO__', "$g"
    if ($subs) { foreach ($k in $subs.Keys) { $text = $text -replace "__$($k)__", $subs[$k] } }
    Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value $text -NoNewline
    Send-Go $g
    $m = Wait-Log "ZEDQA we $g ([^\r\n]+)" $wait
    if (-not $m) { return "" }
    return $m.Groups[1].Value
}
# sends a job and returns its go number without waiting (the watch runs while the pointer moves)
function Start-Job($job) {
    $g = Next-Go
    Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value (($Prelude + "`n" + $Jobs[$job]) -replace '__GO__', "$g") -NoNewline
    Send-Go $g
    return $g
}
function Front {
    $p = Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $p) { return $false }
    $fg = [uint32]0
    [void][ZedWeInput]::GetWindowThreadProcessId([ZedWeInput]::GetForegroundWindow(), [ref]$fg)
    if ($fg -ne [uint32]$p.Id) { try { & (Join-Path $QA "pzfront.ps1") | Out-Null } catch { }; Start-Sleep -Milliseconds 800
        [void][ZedWeInput]::GetWindowThreadProcessId([ZedWeInput]::GetForegroundWindow(), [ref]$fg) }
    return ($fg -eq [uint32]$p.Id)
}
function XY($s) { $a = $s -split ','; return @([int]$a[0], [int]$a[1]) }
function Move($xy) { $p = XY $xy; [void][ZedWeInput]::SetCursorPos($p[0], $p[1]) }
function Field($line, $name) { if ($line -match "$name (\S+)") { return $Matches[1] } return $null }
# a drag from $from by ($dx, $dy) with the left button, in small steps
function Drag($from, $dx, $dy) {
    if (-not (Front)) { return $false }
    $p = XY $from
    [ZedWeInput]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 200
    for ($i = 1; $i -le 10; $i++) {
        [void][ZedWeInput]::SetCursorPos($p[0] + [int]($dx * $i / 10), $p[1] + [int]($dy * $i / 10)); Start-Sleep -Milliseconds 40
    }
    Start-Sleep -Milliseconds 200
    [ZedWeInput]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 600
    return $true
}

try {
    $idle = [ZedWeInput]::IdleMs()
    if ($idle -lt $IdleSec * 1000) { "the computer was used $([int]($idle / 1000)) s ago (under $IdleSec s): not moving the pointer"; $fails++; return }
    if (-not (Front)) { "the game is not the front window"; $fails++; return }
    $s = Run-Job "setup" @{}
    if ($s -notmatch 'TARGETS (\S+) (\S+) (\S+)') { "FAIL no report from the game ($s)"; $fails++; return }
    $bottom, $right, $body = $Matches[1], $Matches[2], $Matches[3]
    "targets: bottom $bottom, right $right, body $body | $(Field $s 'SIZE') open $(Field $s 'OPEN')"
    $park = "1920,1500"   # (open ground under the windows at 4K)
    foreach ($edge in @(@{ name = "bottom"; at = $bottom; zone = "s" }, @{ name = "right"; at = $right; zone = "e" })) {
        Move $park; Start-Sleep -Milliseconds 500
        # the watch starts, then the pointer arrives on the edge and rests
        $g = Start-Job "watch"
        Start-Sleep -Milliseconds 150
        Move $edge.at
        $m = Wait-Log "ZEDQA we $g ([^\r\n]+)" 10
        $line = if ($m) { $m.Groups[1].Value } else { "" }
        $zoneAt = Field $line ' at'; $zone = Field $line 'zone'; $lit = Field $line 'lit'
        $litAt = if ($line -match 'lit \S+ at (\S+)') { $Matches[1] } else { "nil" }
        $zAt = if ($line -match 'zone \S+ at (\S+)') { $Matches[1] } else { "nil" }
        $wait = if ($litAt -ne "nil" -and $zAt -ne "nil") { [int]$litAt - [int]$zAt } else { -1 }
        Check ($zone -eq $edge.zone -and $lit -eq $edge.zone -and $wait -ge 300 -and $wait -le 700) "$($edge.name) edge: the handle shows after the rest ($line; $wait ms after the pointer arrived)"
        [void](Run-Job "shot" @{ NAME = "zqa_we_$($edge.name)_handle.png" })
        # the drag: the bottom edge changes the height only, the right edge the width only
        $before = Field (Run-Job "probe" @{}) 'SIZE'
        $ok = Drag $edge.at 120 90
        $after = Field (Run-Job "probe" @{}) 'SIZE'
        $b = $before -split 'x'; $a = $after -split 'x'
        if ($edge.name -eq "bottom") {
            Check ($ok -and $a[1] -ne $b[1] -and $a[0] -eq $b[0]) "bottom edge: a drag changes the height only ($before to $after)"
        } else {
            Check ($ok -and $a[0] -ne $b[0] -and $a[1] -eq $b[1]) "right edge: a drag changes the width only ($before to $after)"
        }
        [void](Run-Job "restore" @{})   # (the window back to its place for the next edge)
        Start-Sleep -Milliseconds 500
        $s = Run-Job "setup" @{}
        if ($s -match 'TARGETS (\S+) (\S+) (\S+)') { $bottom, $right, $body = $Matches[1], $Matches[2], $Matches[3] }
    }
    # Solid while in use: see-through 60, the pointer over the Character window
    Move $park; Start-Sleep -Milliseconds 400
    "solid: " + (Run-Job "solid" @{})
    Start-Sleep -Milliseconds 600
    $o = Run-Job "probe" @{}
    Check ((Field $o 'SEE') -ne "1") "pointer off the windows: the Character window stays see-through ($o)"
    Move $body; Start-Sleep -Milliseconds 900
    $o = Run-Job "probe" @{}
    $see = Field $o 'SEE'; $wsee = Field $o 'WSEE'
    Check ($see -eq "1" -and $wsee -ne "1") "pointer on the Character window: it goes solid, the World window stays see-through ($o)"
    [void](Run-Job "shot" @{ NAME = "zqa_we_solid_in_use.png" })
} finally {
    [void][ZedWeInput]::SetCursorPos(1920, 1500)
    "put back: " + (Run-Job "restore" @{})
    if ($Quit) {
        Set-Content -Path (Join-Path $Lua "zedqa.autoload") -Value "0" -NoNewline
        # in game quit() goes to the main menu; there a second one closes the game
        $p = Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
        for ($q = 0; $q -lt 2 -and $p -and -not $p.HasExited; $q++) {
            $from = (LogText).Length
            $g = Next-Go
            Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value "getCore():quit()" -NoNewline
            Send-Go $g
            for ($i = 0; $i -lt 60; $i++) {
                Start-Sleep -Seconds 2
                if ($p.HasExited) { break }
                $t = LogText
                if ($t.Length -gt $from -and $t.Substring($from) -match '\[ZeD\.QA\] bridge armed \(main menu') { Start-Sleep -Seconds 5; break }
            }
        }
        if ($p -and -not $p.HasExited) { "the game is still running (process $($p.Id)); left open" } else { "the game closed" }
        if ($ModOptionsKeep -and (Test-Path $ModOptionsKeep) -and -not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) {
            Copy-Item $ModOptionsKeep (Join-Path $Lua "ModOptions.ini") -Force
            "ZeD settings: the director's ModOptions.ini put back"
        }
    }
    if (-not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) -or -not $Quit) { Set-Content -Path $lock -Value "free" -NoNewline }
    if ($fails -eq 0) { "all checks passed" } else { "$fails failed" }
}
if ($fails -eq 0) { exit 0 } else { exit 1 }
