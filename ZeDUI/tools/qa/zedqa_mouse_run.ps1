<#
.SYNOPSIS
    The director's mouse pass (Oct 30 2026), with the real mouse, in game.
.DESCRIPTION
    Run it while the game is up on the ZeD-QA save with both windows open, for example
    after zedqa_run.ps1 -KeepOpen with a manifest of zedqa_prelude.lua (mouse_keep.txt).
    With the Character window's drawer shut and the list view:
      * a right-click on the first inventory row opens ZeD's menu (the tab hint layer over
        the window let the right button through: 42.22 counts a handler that returns
        nothing as taking the click);
      * a press on the window closes that menu (it closed only on a release outside, which
        a window under the pointer takes);
      * the pointer resting on the window box keeps its words on the help line on every
        frame drawn (update() runs every 100 ms; the line strobed);
      * three quick clicks (60 ms) on the window box open its menu three times;
      * a row clicked opens its item card, and a quick click (70 ms) on the card's back key
        shuts it (the card polled the mouse in update(), which runs every 100 ms).
    Then in the Equip tab with the Loadouts fold open: a quick click (70 ms) on the
    loadout picker opens its list and the list stays (it closed on the click's own
    release), and a click away closes it.
    Screenshots zqa_ms_*.png. The tab, the drawer, the fold and the view are put back.
    With -Quit the game quits at the end and -ModOptionsKeep (the director's file the
    runner kept aside, <report>.modoptions.ini) goes back over Lua/ModOptions.ini.
    The real pointer moves only while the game is the front window. Holds Zomboid/Lua/zedqa.lock.
    Exit codes: 0 every check passed, 1 a check failed or the run broke, 2 refused.
#>
param([switch]$Quit, [string]$ModOptionsKeep = "")
$Lua = "C:\Users\danie\Zomboid\Lua"
$QA = $PSScriptRoot
$log = "C:\Users\danie\Zomboid\console.txt"
$lock = Join-Path $Lua "zedqa.lock"
$proc = Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { "the game is not running; start it first (zedqa_run.ps1 -KeepOpen -Manifest mouse_keep.txt)"; exit 2 }
if ((Get-Content $lock -Raw -ErrorAction SilentlyContinue) -match '^busy') { "the lock says busy; not starting"; exit 2 }
Set-Content -Path $lock -Value "busy zedqa_mouse_run" -NoNewline

Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class ZedMsInput {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
"@
[void][ZedMsInput]::SetProcessDPIAware()

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

# the Lua side: a prelude, then one job; every line is "ZEDQA ms <go> ..."
$Prelude = @'
local G = "__GO__"
local function say(s) print("ZEDQA ms " .. G .. " " .. tostring(s)) end
local c = ZeD_CharacterWindow.getWindow()
local EL = ZeD.EquipLoadout
local pn = c and c.playerNum or 0
local function pt(x, y) return math.floor(x) .. "," .. math.floor(y) end
local function later(n, fn)
    local k = 0
    local function f() k = k + 1; if k >= n then Events.OnTick.Remove(f); fn() end end
    Events.OnTick.Add(f)
end
'@
$Jobs = @{
    # the drawer shut, nothing picked, the list view; then the first row, the window box, a
    # spot on the window's help line
    setup = @'
ZEDQA_MS = ZEDQA_MS or { tab = c._activeTab, open = c._drawerOpen, mode = c._drawerMode, fold = EL and EL.openFor[pn], view = ZeD.EquipDoll and ZeD.EquipDoll.view(), listExp = c._equipListExpanded }
local cp = c._contentPanel
for k in pairs(cp._selectedItems or {}) do cp._selectedItems[k] = nil end
c._drawerItem = nil
c._activeTab = "loot"; c._drawerOpen = false; c._drawerMode = nil
later(40, function()
    local row
    for _, z in ipairs(cp._hitZones or {}) do
        local id = z.id
        if (type(id) ~= "string" and id ~= nil) or (type(id) == "string" and id:sub(1, 6) == "stack:") then
            row = pt(cp:getAbsoluteX() + z.x + z.w / 3, cp:getAbsoluteY() + z.y + z.h / 2); break
        end
    end
    local b = c:windowBoxRect()
    local box = b and pt(c:getAbsoluteX() + b.x + b.w / 2, c:getAbsoluteY() + b.y + b.h / 2) or "none"
    local help = pt(c:getAbsoluteX() + c:getWidth() / 2, c:getAbsoluteY() + c:getHeight() - ZeD.T.px(10))
    say("TARGETS row " .. tostring(row) .. " box " .. box .. " help " .. help .. " width " .. math.floor(c:getWidth()))
end)
'@
    # the ZeD menus open now
    menus = @'
local n, kinds = 0, {}
local ui = UIManager.getUI()
for i = 0, ui:size() - 1 do
    local t = ui:get(i):getTable()
    if t and (t.Type == "ZeD_ContextMenu" or t.Type == "ZeD_ContextList" or t.Type == "ZeD_WindowMenu") and t._ctx and t._ctx.open then
        n = n + 1; kinds[#kinds + 1] = t.Type
    end
end
say("MENUS " .. n .. " " .. table.concat(kinds, ","))
'@
    # the help line for 1.5 s from 0.6 s on: frames with the window box's words, frames without
    helpwatch = @'
if not ZEDQA_TAKE then
    ZEDQA_TAKE = true
    local o = ZeD.Help.take
    ZeD.Help.take = function(win)
        local t = o(win)
        local k = ZEDQA_HW
        if k and not k.done and win == ZeD_CharacterWindow.getWindow() then
            local now = getTimestampMs() - k.t0
            if now >= 600 then
                if t == k.want then k.on = k.on + 1 else k.off = k.off + 1 end
                if now >= 2100 then
                    k.done = true
                    print("ZEDQA ms " .. k.g .. " HELP on " .. k.on .. " off " .. k.off)
                end
            end
        end
        return t
    end
end
ZEDQA_HW = { on = 0, off = 0, t0 = getTimestampMs(), want = ZeD.tr("UI_ZeD_WinMenu_Help"), g = G }
'@
    # counts the window menus opened from now
    wmcount = @'
if not ZEDQA_WMC then
    ZEDQA_WMC = { n = 0 }
    local o = ZeD_WindowMenu.open
    ZeD_WindowMenu.open = function(self, ...) ZEDQA_WMC.n = ZEDQA_WMC.n + 1; return o(self, ...) end
end
say("WM " .. ZEDQA_WMC.n)
'@
    # the Equip tab, the list view, Equipped folded (so the Loadouts fold sits under the heading,
    # in view) and the Loadouts fold open; then the loadout picker, if it is in the tab's view
    equip = @'
ZeD.EquipDoll.setView("list")
c._activeTab = "equip"; c._drawerMode = "tab"; c._drawerOpen = true
c._equipSelected = nil
c._equipListExpanded = false
EL.openFor[pn] = true
if c._equipScroll then c._equipScroll:setScrollPos(0) end
later(40, function()
    local dp = c._drawerPanel
    local at = "none"
    for _, z in ipairs(c._elZones or {}) do
        if z.id == "loadout" then
            local v = z.view
            local inView = (not v) or (z.y >= v.y and z.y + z.h <= v.y + v.h)
            at = inView and pt(dp:getAbsoluteX() + z.x + z.w / 2, dp:getAbsoluteY() + z.y + z.h / 2) or "out_of_view"
        end
    end
    say("LOADOUT " .. at)
end)
'@
    # the item card in the drawer: shown, its item, its back key on the screen
    card = @'
local card = c._itemCard
local r = card and card._backBarRects and card._backBarRects.back
say("CARD vis " .. tostring(card ~= nil and card:isVisible()) .. " item " .. tostring(c._drawerItem ~= nil)
    .. " back " .. (r and pt(card:getAbsoluteX() + r.x + r.w / 2, card:getAbsoluteY() + r.y + r.h / 2) or "none"))
'@
    shot = @'
getCore():TakeFullScreenshot("__NAME__")
say("SHOT __NAME__")
'@
    restore = @'
local ui = UIManager.getUI()
for i = ui:size() - 1, 0, -1 do
    local t = ui:get(i):getTable()
    if t and (t.Type == "ZeD_ContextMenu" or t.Type == "ZeD_ContextList" or t.Type == "ZeD_WindowMenu") and t._ctx and t._ctx.open then pcall(function() t:close() end) end
end
local s = ZEDQA_MS
if s then
    c._activeTab, c._drawerOpen, c._drawerMode = s.tab, s.open, s.mode
    if EL then EL.openFor[pn] = s.fold end
    c._equipListExpanded = s.listExp
    if s.view and ZeD.EquipDoll then ZeD.EquipDoll.setView(s.view) end
end
ZEDQA_MS, ZEDQA_HW = nil, nil
say("RESTORED tab " .. tostring(c._activeTab))
'@
}
function Run-Job($job, $subs, $wait = 30) {
    $g = Next-Go
    $text = ($Prelude + "`n" + $Jobs[$job]) -replace '__GO__', "$g"
    if ($subs) { foreach ($k in $subs.Keys) { $text = $text -replace "__$($k)__", $subs[$k] } }
    Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value $text -NoNewline
    Send-Go $g
    $m = Wait-Log "ZEDQA ms $g ([^\r\n]+)" $wait
    if (-not $m) { return "" }
    return $m.Groups[1].Value
}
function Front {
    $p = Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $p) { return $false }
    $fg = [uint32]0
    [void][ZedMsInput]::GetWindowThreadProcessId([ZedMsInput]::GetForegroundWindow(), [ref]$fg)
    if ($fg -ne [uint32]$p.Id) { try { & (Join-Path $QA "pzfront.ps1") | Out-Null } catch { }; Start-Sleep -Milliseconds 800
        [void][ZedMsInput]::GetWindowThreadProcessId([ZedMsInput]::GetForegroundWindow(), [ref]$fg) }
    return ($fg -eq [uint32]$p.Id)
}
function XY($s) { $a = $s -split ','; return @([int]$a[0], [int]$a[1]) }
function Put-Pointer($xy) { $p = XY $xy; [void][ZedMsInput]::SetCursorPos($p[0] + 3, $p[1] + 2); Start-Sleep -Milliseconds 200; [void][ZedMsInput]::SetCursorPos($p[0], $p[1]); Start-Sleep -Milliseconds 250 }
# a click at $xy: down, $holdMs, up (right = the right button)
function Click($xy, $holdMs, [switch]$Right) {
    if (-not (Front)) { return $false }
    Put-Pointer $xy
    $d, $u = if ($Right) { 8, 16 } else { 2, 4 }
    [ZedMsInput]::mouse_event($d, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds $holdMs
    [ZedMsInput]::mouse_event($u, 0, 0, 0, [UIntPtr]::Zero)
    return $true
}
function Menus { $l = Run-Job "menus" @{}; if ($l -match 'MENUS (\d+)') { return [int]$Matches[1] } return -1 }
$park = "1920,1500"   # (open ground under the windows at 4K)

try {
    if (-not (Front)) { "the game is not the front window"; $fails++; return }
    [void](Run-Job "restore" @{})   # (no menu left open from before)
    $s = Run-Job "setup" @{} 20
    if ($s -notmatch 'TARGETS row (\S+) box (\S+) help (\S+)') { "FAIL no report from the game ($s)"; $fails++; return }
    $row, $box, $help = $Matches[1], $Matches[2], $Matches[3]
    "targets: $s"

    # 1. the drawer shut: a right-click on the first row opens the menu
    $ok = Click $row 120 -Right
    Start-Sleep -Milliseconds 900
    $n = Menus
    Check ($ok -and $n -ge 1) "the drawer shut: a right-click on the first inventory row opens ZeD's menu ($n open)"
    [void](Run-Job "shot" @{ NAME = "zqa_ms_1_rightclick.png" })
    # 2. a press on the window (its help line) closes it
    $ok = Click $help 90
    Start-Sleep -Milliseconds 700
    $n = Menus
    Check ($ok -and $n -eq 0) "a press on a window closes the menu ($n open)"

    # 3. the window box: its words on every frame the pointer rests there (the drawer shut again)
    $s = Run-Job "setup" @{} 20
    if ($s -match 'box (\S+)') { $box = $Matches[1] }
    Put-Pointer $park; Start-Sleep -Milliseconds 300
    $g = Next-Go
    Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value (($Prelude + "`n" + $Jobs["helpwatch"]) -replace '__GO__', "$g") -NoNewline
    Send-Go $g
    Start-Sleep -Milliseconds 150
    Put-Pointer $box
    $m = Wait-Log "ZEDQA ms $g HELP on (\d+) off (\d+)" 12
    $on = if ($m) { [int]$m.Groups[1].Value } else { 0 }; $off = if ($m) { [int]$m.Groups[2].Value } else { -1 }
    Check ($m -and $on -ge 20 -and $off -le [math]::Ceiling($on / 20)) "the pointer on the window box: its words on the help line every frame ($on frames with, $off without)"
    # 4. three quick clicks on the window box open its menu three times
    $w0 = Run-Job "wmcount" @{}; $n0 = if ($w0 -match 'WM (\d+)') { [int]$Matches[1] } else { -1 }
    for ($i = 1; $i -le 3; $i++) {
        [void](Click $box 60)
        Start-Sleep -Milliseconds 800
        if ($i -eq 1) { [void](Run-Job "shot" @{ NAME = "zqa_ms_4_window_menu.png" }) }
        [void](Click $park 60)
        Start-Sleep -Milliseconds 600
    }
    $w1 = Run-Job "wmcount" @{}; $n1 = if ($w1 -match 'WM (\d+)') { [int]$Matches[1] } else { -1 }
    Check ($n0 -ge 0 -and $n1 - $n0 -eq 3) "three quick clicks (60 ms) on the window box open its menu three times ($($n1 - $n0))"

    # 5. the item card's back key: a row clicked opens its card, a quick click (70 ms) on back shuts it
    #    (the card polled the mouse in update(), every 100 ms: the click did nothing)
    $s = Run-Job "setup" @{} 20
    if ($s -match 'row (\d+,\d+)') { $row = $Matches[1] }
    [void](Click $row 80)
    Start-Sleep -Milliseconds 900
    $cs = Run-Job "card" @{}
    $back = if ($cs -match 'back (\d+,\d+)') { $Matches[1] } else { $null }
    Check ($cs -match 'item true' -and $back -ne $null) "a click on a row opens its card ($cs)"
    if ($back) {
        [void](Run-Job "shot" @{ NAME = "zqa_ms_5_card.png" })
        [void](Click $back 70)
        Start-Sleep -Milliseconds 800
        $cs2 = Run-Job "card" @{}
        Check ($cs2 -match 'item false') "a quick click (70 ms) on the card's back key shuts the card ($cs2)"
    }

    # 6. the Equip tab's Loadouts fold: a quick click on the loadout picker opens its list, which stays
    $e = Run-Job "equip" @{} 20
    $lo = if ($e -match 'LOADOUT (\d+,\d+)') { $Matches[1] } else { $null }
    Check ($lo -ne $null) "the Loadouts fold opens with its loadout picker ($e)"
    if ($lo) {
        $ok = Click $lo 70
        Start-Sleep -Milliseconds 1000
        $n = Menus
        Check ($ok -and $n -ge 1) "a quick click (70 ms) on the loadout picker opens its list and it stays ($n open)"
        [void](Run-Job "shot" @{ NAME = "zqa_ms_6_loadout_list.png" })
        [void](Click $park 70)
        Start-Sleep -Milliseconds 700
        $n = Menus
        Check ($n -eq 0) "a click away closes the list ($n open)"
    }
}
finally {
    [void][ZedMsInput]::SetCursorPos(1920, 1500)
    "put back: " + (Run-Job "restore" @{} 15)
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
