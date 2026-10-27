<#
.SYNOPSIS
    The main menu windows' window box (the box at the right end of the title bar that
    pulls down the window menu) and close box, pressed with the real mouse (first
    written Oct 24 2026 for the frame's theme, accent and text-size squares, which the
    window box replaced; director: "theme, accent, font button on the main menu
    windows doesn't do anything").
.DESCRIPTION
    Launches the game at the director's own (fullscreen) settings to the main menu,
    then for the Project Zomboid, Mods, Options and Load Game windows: the bridge
    reports where the window box is, the real pointer goes onto it (SetCursorPos),
    the bridge says whether it lit, a real left click goes in (only while the game
    is the front window), and the bridge says whether the window menu came down and
    the box shows it open. Then a click on the menu's Theme row, a click on the next
    base theme in its list, and the bridge says whether the theme changed and the
    menu closed. The close box is checked for hover, and clicked on the Mods window.
    The theme, accent and size are put back, the game quits. Holds
    Zomboid/Lua/zedqa.lock while it runs.
    (Mouse.setXY does not move the pointer at the main menu, hence real input.)
    Exit codes: 0 every check passed, 1 a check failed or the run broke, 2 refused.
#>
$Lua = "C:\Users\danie\Zomboid\Lua"
$QA = $PSScriptRoot
$log = "C:\Users\danie\Zomboid\console.txt"
$lock = Join-Path $Lua "zedqa.lock"
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is running; not starting"; exit 2 }
if ((Get-Content $lock -Raw -ErrorAction SilentlyContinue) -match '^busy') { "the lock says busy; not starting"; exit 2 }
Set-Content -Path $lock -Value "busy zedqa_menu_footer_run" -NoNewline

Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class ZedMfInput {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
"@
[void][ZedMfInput]::SetProcessDPIAware()

$fails = 0
function Check($ok, $what) { if ($ok) { "PASS $what" } else { $script:fails++; "FAIL $what" } }
# the next go number (kept in zedqa.counter, above 9999 like zedqa_run.ps1's); the
# caller writes zedqa.lua first and the number to zedqa.go after (Send-Go)
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

# the Lua side: a prelude, then one job; every line is "ZEDQA mf <go> ..."
$Prelude = @'
local MM = ZeD.MainMenu
local R = MM.root
local G = "__GO__"
local function say(s) print("ZEDQA mf " .. G .. " " .. tostring(s)) end
local function win(v)
    if v == "main" then return R.win elseif v == "mods" then return R.modsWin
    elseif v == "options" then return R.optsWin elseif v == "load" then return R.loadWin end
end
local function values() return tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize) end
-- the middle of a rect of the window (window coordinates in, screen point out), "none" without one
local function mid(w, r)
    if not r then return "none" end
    return math.floor(w:getAbsoluteX() + r.x + r.w / 2) .. "," .. math.floor(w:getAbsoluteY() + r.y + r.h / 2)
end
local function targets(v)
    local w = win(v)
    return mid(w, w:windowBoxRect()) .. " " .. mid(w, w:closeRect())
end
-- the window menu pulled down now (ZeD.WindowMenu.current), nil when none is
local function menu()
    local m = ZeD.WindowMenu and ZeD.WindowMenu.current
    return (m and m._ctx and m._ctx.open) and m or nil
end
local function shut() local m = menu(); if m then m:close() end end
-- the middle of the row of the menu item at index idx on level li, from the menu's hit zones
-- (its panel covers the screen, so they are screen points); "none" until the menu has drawn
local function rowPoint(li, idx)
    local m = menu()
    local lv = m and m._levels and m._levels[li]
    local def = lv and lv.items and lv.items[idx]
    if not def then return "none" end
    for ri, r in ipairs(lv.rows) do
        if r.def == def then
            for _, z in ipairs(m._hitZones or {}) do
                if z.id == "row:" .. li .. ":" .. ri then return math.floor(z.x + z.w / 2) .. "," .. math.floor(z.y + z.h / 2) end
            end
        end
    end
    return "none"
end
'@
$Jobs = @{
    show = @'
shut()
local v = "__VIEW__"
if v == "main" or v == "load" then MM.showView(v) elseif v == "mods" then MM.showView("main"); MM.openMods() else MM.showView("main"); MM.openOptions() end
local t0 = getTimestampMs()
local function f()
    if getTimestampMs() - t0 < 2500 then return end
    Events.OnFETick.Remove(f)
    say("TARGETS " .. targets(v) .. " VALUES " .. values() .. " VIEW " .. tostring(MM.view))
end
Events.OnFETick.Add(f)
'@
    report = @'
say("TARGETS " .. targets("__VIEW__") .. " VALUES " .. values() .. " VIEW " .. tostring(MM.view))
'@
    probe = @'
local w = win("__VIEW__")
say("PROBE mouse " .. getMouseX() .. "," .. getMouseY() .. " WBOX " .. tostring(w._wboxHover) .. " WOPEN " .. tostring(w._wboxOpen) .. " MENU " .. tostring(menu() ~= nil) .. " CLOSE " .. tostring(w._closeHover) .. " VALUES " .. values() .. " VIEW " .. tostring(MM.view))
'@
    menurow = @'
local keys = ZeD.Settings.baseKeys
local cur = 1
for i, k in ipairs(keys) do if k == ZeD.currentBase then cur = i end end
local want = (cur % #keys) + 1
local item = "__ITEM__"
say("ROW " .. rowPoint(__LEVEL__, (item == "next") and want or tonumber(item)) .. " WANT " .. keys[want] .. " MENU " .. tostring(menu() ~= nil))
'@
    shut = @'
shut()
say("SHUT MENU " .. tostring(menu() ~= nil))
'@
    shot = @'
getCore():TakeFullScreenshot("__NAME__")
say("SHOT __NAME__")
'@
    restore = @'
shut()
ZeD.applyTheme("__BASE__", "__ACCENT__", "__SIZE__")
pcall(ZeD.Settings.syncToModOptions)
MM.showView("main")
say("RESTORED " .. values())
'@
}
function Run-Job($job, $subs) {
    $g = Next-Go
    $text = ($Prelude + "`n" + $Jobs[$job]) -replace '__GO__', "$g"
    foreach ($k in $subs.Keys) { $text = $text -replace "__$($k)__", $subs[$k] }
    # (the bridge reads zedqa.lua when zedqa.go changes: the script first)
    Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value $text -NoNewline
    Send-Go $g
    $m = Wait-Log "ZEDQA mf $g ([^\r\n]+)" 30
    if (-not $m) { return $null }
    return $m.Groups[1].Value
}
function Parse($line) {
    $o = @{}
    if ($line -match 'TARGETS (\S+) (\S+)') { $o.t = @($Matches[1], $Matches[2]) }   # the window box, the close box
    if ($line -match 'VALUES (\S+) (\S+) (\S+)') { $o.v = @($Matches[1], $Matches[2], $Matches[3]) }
    if ($line -match 'WBOX (\S+)') { $o.wbox = $Matches[1] }
    if ($line -match 'WOPEN (\S+)') { $o.wopen = $Matches[1] }
    if ($line -match 'MENU (\S+)') { $o.menu = $Matches[1] }
    if ($line -match 'CLOSE (\S+)') { $o.close = $Matches[1] }
    if ($line -match 'ROW (\S+)') { $o.row = $Matches[1] }
    if ($line -match 'WANT (\S+)') { $o.want = $Matches[1] }
    if ($line -match 'VIEW (\S+)') { $o.view = $Matches[1] }
    if ($line -match 'mouse (\S+)') { $o.mouse = $Matches[1] }
    return $o
}
function Front {
    $proc = Get-Process -Name ProjectZomboid64 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) { return $false }
    $fg = [uint32]0
    [void][ZedMfInput]::GetWindowThreadProcessId([ZedMfInput]::GetForegroundWindow(), [ref]$fg)
    if ($fg -ne [uint32]$proc.Id) { try { & (Join-Path $QA "pzfront.ps1") | Out-Null } catch { }; Start-Sleep -Milliseconds 800
        [void][ZedMfInput]::GetWindowThreadProcessId([ZedMfInput]::GetForegroundWindow(), [ref]$fg) }
    return ($fg -eq [uint32]$proc.Id)
}
function Point($xy) {
    $x, $y = $xy -split ','
    [void][ZedMfInput]::SetCursorPos([int]$x - 2, [int]$y - 2); Start-Sleep -Milliseconds 250
    [void][ZedMfInput]::SetCursorPos([int]$x, [int]$y); Start-Sleep -Milliseconds 700
}
function Click {
    if (-not (Front)) { return $false }
    [ZedMfInput]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 150
    [ZedMfInput]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 1000
    return $true
}

$p = $null
$was = $null
try {
    Set-Content -Path (Join-Path $Lua "zedqa.autoload") -Value "0" -NoNewline
    $dir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
    $p = Start-Process -FilePath "$dir\ProjectZomboid64.exe" -ArgumentList "-debug" -WorkingDirectory $dir -PassThru
    "started the game (process $($p.Id))"
    Start-Sleep -Seconds 15
    if (-not (Wait-Log 'bridge armed \(main menu' 600)) { "never reached the main menu"; $fails++; return }
    Start-Sleep -Seconds 15
    if (-not (Front)) { "the game is not the front window"; $fails++; return }
    foreach ($view in @("main", "mods", "options", "load")) {
        $s = Parse (Run-Job "show" @{ VIEW = $view })
        if (-not $s.t) { "FAIL ${view}: no report"; $fails++; continue }
        if (-not $was) { $was = $s.v; "start values: $($was -join ' ')" }
        Check ($s.view -eq $view) "${view}: the window is up"
        $before = $s.v
        if ($s.t[0] -eq "none") {
            Check $false "${view}: the window box is drawn"
        } else {
            # the box lights under the pointer
            Point $s.t[0]
            $h = Parse (Run-Job "probe" @{ VIEW = $view })
            Check ($h.wbox -eq "true") "${view}: the window box lights under the pointer (hover $($h.wbox), pointer $($h.mouse))"
            # a click on it pulls the window menu down, the box stays lit while it is open
            $clicked = Click
            $a = Parse (Run-Job "probe" @{ VIEW = $view })
            Check ($clicked -and $a.menu -eq "true" -and $a.wopen -eq "true") "${view}: a click on the window box opens its menu (menu $($a.menu), box open $($a.wopen))"
            # a click on the Theme row (item 1) shows its choices; a click on the next base theme in the list changes the theme
            $r = Parse (Run-Job "menurow" @{ LEVEL = 1; ITEM = 1 })
            if ($r.row -eq "none") {
                Check $false "${view}: the menu's Theme row is drawn"
            } else {
                Point $r.row
                [void](Click)
                $r = Parse (Run-Job "menurow" @{ LEVEL = 2; ITEM = "next" })
                if ($view -eq "main") { [void](Run-Job "shot" @{ NAME = "zqa_mf_main_menu.png" }) }
                if ($r.row -eq "none") {
                    Check $false "${view}: the Theme choices are showing"
                } else {
                    Point $r.row
                    $clicked = Click
                    $a = Parse (Run-Job "probe" @{ VIEW = $view })
                    Check ($clicked -and $a.v -and $a.v[0] -eq $r.want -and $a.v[0] -ne $before[0]) "${view}: a click on a Theme choice changes the theme ($($before[0]) to $($a.v[0]), wanted $($r.want))"
                    Check ($a.menu -eq "false" -and $a.wopen -ne "true") "${view}: the menu closes after the pick (menu $($a.menu), box open $($a.wopen))"
                    if ($view -eq "main") { [void](Run-Job "shot" @{ NAME = "zqa_mf_main_picked.png" }) }
                    if ($a.v) { $before = $a.v }
                }
            }
            [void](Run-Job "shut" @{ })   # (a check that failed must not leave the menu over the close box)
        }
        $s = Parse (Run-Job "report" @{ VIEW = $view })   # (a new theme can move the frame)
        Point $s.t[1]
        $c = Parse (Run-Job "probe" @{ VIEW = $view })
        Check ($c.close -eq "true") "${view}: the close box answers the pointer"
        if ($view -eq "mods") {
            $clicked = Click
            $c = Parse (Run-Job "probe" @{ VIEW = $view })
            Check ($clicked -and $c.view -ne "mods") "mods: a click on the close box closes it (view now $($c.view))"
        }
    }
} finally {
    if ($p -and -not $p.HasExited) {
        [void][ZedMfInput]::SetCursorPos(1920, 1080)
        if ($was) { "put back: " + (Run-Job "restore" @{ BASE = $was[0]; ACCENT = $was[1]; SIZE = $was[2] }) }
        $g = Next-Go
        Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value "getCore():quit()" -NoNewline
        Send-Go $g
        for ($i = 0; $i -lt 60; $i++) { Start-Sleep -Seconds 2; if ($p.HasExited) { break } }
        if ($p.HasExited) { "the game closed" } else { "the game is still running (process $($p.Id)); left open" }
    }
    if (-not ($p -and -not $p.HasExited)) { Set-Content -Path $lock -Value "free" -NoNewline }
    if ($fails -eq 0) { "all checks passed" } else { "$fails failed" }
}
if ($fails -eq 0) { exit 0 } else { exit 1 }
