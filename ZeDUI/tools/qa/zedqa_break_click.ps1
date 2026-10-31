<#
.SYNOPSIS
    QA's break-it pass with the real mouse (Oct 31 2026; the director: "Try to break things. Click
    repeatedly, make things too small and too big.").
.DESCRIPTION
    Run it while the game is up on the ZeD-QA save with both windows open (zedqa_run.ps1 -KeepOpen
    -Manifest mouse_keep.txt). For every tab of both windows: the tab clicked, then a grid of points
    over the tab's card (6 x 8), each clicked twice fast (40 ms down, 40 ms apart: a double click);
    then the tab strip clicked through as fast as it goes (30 ms a tab). After each tab: the game's
    own errors counted in console.txt since the tab began ("Exception thrown", ZeD's safe mode
    stepping aside), with the first error's lines, and a screenshot zqa_bclk_<win>_<tab>.png. Before
    each tab the windows are put back (both open, menus and cards shut, nothing picked, Loot).
    With -Quit the game quits at the end. Holds Zomboid/Lua/zedqa.lock.
    Exit codes: 0 no errors, 1 errors or the run broke, 2 refused.
#>
param([switch]$Quit, [int]$Cols = 6, [int]$Rows = 8)
$Lua = "C:\Users\danie\Zomboid\Lua"
$QA = $PSScriptRoot
$log = "C:\Users\danie\Zomboid\console.txt"
$lock = Join-Path $Lua "zedqa.lock"
$proc = Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { "the game is not running; start it first (zedqa_run.ps1 -KeepOpen -Manifest mouse_keep.txt)"; exit 2 }
if ((Get-Content $lock -Raw -ErrorAction SilentlyContinue) -match '^busy') { "the lock says busy; not starting"; exit 2 }
Set-Content -Path $lock -Value "busy zedqa_break_click" -NoNewline

Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class ZedBkInput {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
"@
[void][ZedBkInput]::SetProcessDPIAware()

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
$Prelude = @'
local G = "__GO__"
local function say(s) print("ZEDQA bclk " .. G .. " " .. tostring(s)) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function pt(x, y) return math.floor(x) .. "," .. math.floor(y) end
local function later(n, fn) local k = 0; local function f() k = k + 1; if k >= n then Events.OnTick.Remove(f); fn() end end; Events.OnTick.Add(f) end
'@
$Jobs = @{
    # both windows open, menus, cards and picks shut, both on Loot; then the tabs of both strips
    reset = @'
local p = getPlayer()
pcall(function() if getPlayerContextMenu(0) then getPlayerContextMenu(0):hideAndChildren() end end)
local ui = UIManager.getUI()
for i = ui:size() - 1, 0, -1 do
    local t = ui:get(i):getTable()
    if t and (t.Type == "ZeD_ContextMenu" or t.Type == "ZeD_ContextList" or t.Type == "ZeD_WindowMenu") and t._ctx and t._ctx.open then pcall(function() t:close() end) end
end
pcall(function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end)
pcall(function() ISTimedActionQueue.clear(p) end)
if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then pcall(ZeD.Safe.reset) end
if not (CWm.isOpen() and WWm.isOpen()) then
    if CWm.isOpen() then CWm.toggle(0) end
    if WWm.isOpen() then WWm.close() end
    CWm.toggleBothPaired(0)
end
later(20, function()
    pcall(ZeD_Window.resetLayout)
    local out = {}
    for _, pair in ipairs({ { "c", CWm.getWindow(), "_tabStripPanel" }, { "w", WWm.getWindow(), "_actionTabStrip" } }) do
        local w = pair[2]; local s = w and w[pair[3]]
        local cp = w and w._mainContent
        if cp and cp._selectedItems then for k in pairs(cp._selectedItems) do cp._selectedItems[k] = nil end; pcall(function() w._updateDrawer(cp) end) end
        for _, z in ipairs((s and s._hitZones) or {}) do
            if z.id == "tab:loot" and w._activeTab ~= "loot" then s:onMouseDown(z.x + 2, z.y + 2) end
        end
    end
    later(20, function()
        for _, pair in ipairs({ { "c", CWm.getWindow(), "_tabStripPanel" }, { "w", WWm.getWindow(), "_actionTabStrip" } }) do
            local w = pair[2]; local s = w and w[pair[3]]
            for _, z in ipairs((s and s._hitZones) or {}) do
                if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then
                    out[#out + 1] = pair[1] .. ":" .. z.id:sub(5) .. "@" .. pt(s:getAbsoluteX() + z.x + z.w / 2, s:getAbsoluteY() + z.y + z.h / 2)
                end
            end
        end
        say("TABS " .. table.concat(out, " "))
    end)
end)
'@
    # the card's rect on the screen for a window (the drawer), or the window's body when no drawer is open
    card = @'
local w = ("__WIN__" == "c") and CWm.getWindow() or WWm.getWindow()
local dp = w and w._drawerPanel
local r
if dp and dp:isVisible() and dp:getWidth() > 4 then r = { dp:getAbsoluteX(), dp:getAbsoluteY(), dp:getWidth(), dp:getHeight() }
elseif w then r = { w:getAbsoluteX(), w:getAbsoluteY() + ZeD.T.px(24), w:getWidth(), w:getHeight() - ZeD.T.px(48) } end
say("CARD " .. (r and (math.floor(r[1]) .. " " .. math.floor(r[2]) .. " " .. math.floor(r[3]) .. " " .. math.floor(r[4])) or "none") .. " tab " .. tostring(w and w._activeTab))
'@
    shot = @'
getCore():TakeFullScreenshot("__NAME__")
say("SHOT __NAME__")
'@
}
function Run-Job($job, $subs, $wait = 30) {
    $g = Next-Go
    $text = ($Prelude + "`n" + $Jobs[$job]) -replace '__GO__', "$g"
    if ($subs) { foreach ($k in $subs.Keys) { $text = $text -replace "__$($k)__", $subs[$k] } }
    Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value $text -NoNewline
    Send-Go $g
    $m = Wait-Log "ZEDQA bclk $g ([^\r\n]+)" $wait
    if (-not $m) { return "" }
    return $m.Groups[1].Value
}
function Front {
    $p = Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $p) { return $false }
    $fg = [uint32]0
    [void][ZedBkInput]::GetWindowThreadProcessId([ZedBkInput]::GetForegroundWindow(), [ref]$fg)
    if ($fg -ne [uint32]$p.Id) { try { & (Join-Path $QA "pzfront.ps1") | Out-Null } catch { }; Start-Sleep -Milliseconds 800
        [void][ZedBkInput]::GetWindowThreadProcessId([ZedBkInput]::GetForegroundWindow(), [ref]$fg) }
    return ($fg -eq [uint32]$p.Id)
}
function Tap($x, $y, $hold) {
    [void][ZedBkInput]::SetCursorPos($x, $y); Start-Sleep -Milliseconds 15
    [ZedBkInput]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds $hold
    [ZedBkInput]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
}
function XY($s) { $a = $s -split ','; return @([int]$a[0], [int]$a[1]) }
function ErrCount { $t = LogText; return @([regex]::Matches($t, 'Exception thrown').Count, [regex]::Matches($t, 'stepped aside').Count, $t.Length) }
function FirstErr($from) {
    $t = LogText
    if ($from -ge $t.Length) { return "" }
    $tail = $t.Substring($from)
    $m = [regex]::Match($tail, '(?s)Exception thrown.{0,700}')
    if ($m.Success) { return (($m.Value -split "`r?`n") | Select-Object -First 6) -join " | " }
    $m = [regex]::Match($tail, 'stepped aside[^\r\n]*')
    if ($m.Success) { return $m.Value }
    return ""
}

$total = 0; $broken = 0
try {
    if (-not (Front)) { "the game is not the front window"; $broken++; return }
    $tabs = Run-Job "reset" @{} 30
    if (-not ($tabs -match '^TABS (.+)$')) { "no tab list: $tabs"; $broken++; return }
    $list = $Matches[1] -split ' '
    "tabs: " + ($list | ForEach-Object { ($_ -split '@')[0] }) -join ' '
    foreach ($entry in $list) {
        $name, $at = $entry -split '@'
        $win = ($name -split ':')[0]; $tab = ($name -split ':')[1]
        [void](Run-Job "reset" @{} 30)
        $before = ErrCount
        if (-not (Front)) { "lost the front window at $name"; $broken++; break }
        $p = XY $at; Tap $p[0] $p[1] 60; Start-Sleep -Milliseconds 900
        $c = Run-Job "card" @{ WIN = $win } 15
        if ($c -match 'CARD (\d+) (\d+) (\d+) (\d+)') {
            $x0 = [int]$Matches[1]; $y0 = [int]$Matches[2]; $cw = [int]$Matches[3]; $ch = [int]$Matches[4]
            for ($r = 0; $r -lt $Rows; $r++) {
                for ($k = 0; $k -lt $Cols; $k++) {
                    $x = $x0 + [int](($k + 0.5) * $cw / $Cols); $y = $y0 + [int](($r + 0.5) * $ch / $Rows)
                    if (-not (Front)) { break }
                    Tap $x $y 40; Start-Sleep -Milliseconds 40; Tap $x $y 40; Start-Sleep -Milliseconds 60
                }
            }
        } else { "  ${name}: no card rect ($c)" }
        # the strip, as fast as it goes
        foreach ($e2 in $list) { $n2, $a2 = $e2 -split '@'; if (($n2 -split ':')[0] -eq $win) { $q = XY $a2; Tap $q[0] $q[1] 30; Start-Sleep -Milliseconds 30 } }
        Start-Sleep -Milliseconds 700
        [void](Run-Job "shot" @{ NAME = "zqa_bclk_${win}_${tab}.png" } 15)
        $after = ErrCount
        $ne = $after[0] - $before[0]; $ns = $after[1] - $before[1]
        $total += $ne + $ns
        if ($ne -gt 0 -or $ns -gt 0) { "ERRORS $name : $ne exception(s), safe mode $ns | " + (FirstErr $before[2]) } else { "clean  $name" }
    }
} finally {
    [void](Run-Job "reset" @{} 30)
    if ($Quit) {
        $g = Next-Go
        Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value "getCore():quitToDesktop()" -NoNewline
        Send-Go $g
        Start-Sleep -Seconds 15
    }
    Set-Content -Path $lock -Value "free" -NoNewline
}
"total errors: $total"
if ($broken -gt 0 -or $total -gt 0) { exit 1 } else { exit 0 }
