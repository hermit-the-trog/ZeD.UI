<#
.SYNOPSIS
    The main menu windows' frame squares (theme, accent, text size) and close box,
    pressed with the real mouse (Oct 24 2026; director: "theme, accent, font button
    on the main menu windows doesn't do anything").
.DESCRIPTION
    Launches the game at the director's own (fullscreen) settings to the main menu,
    then for the Project Zomboid, Mods, Options and Load Game windows: the bridge
    reports where the squares are, the real pointer goes onto each (SetCursorPos),
    the bridge says whether it lit, a real left click goes in (only while the game
    is the front window), and the bridge says whether the setting changed. The close
    box is checked for hover, and clicked on the Mods window. The theme, accent and
    size are put back, the game quits. Holds Zomboid/Lua/zedqa.lock while it runs.
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
local function targets(v)
    local w = win(v)
    local r = w._themeControlRects or {}
    local cb = w:closeRect()
    local t = {}
    for i = 1, 3 do
        local q = r[i]
        t[#t + 1] = q and (math.floor(q.x + q.w / 2) .. "," .. math.floor(q.y + q.h / 2)) or "none"
    end
    t[#t + 1] = math.floor(w:getAbsoluteX() + cb.x + cb.w / 2) .. "," .. math.floor(w:getAbsoluteY() + cb.y + cb.h / 2)
    return table.concat(t, " ")
end
'@
$Jobs = @{
    show = @'
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
say("PROBE mouse " .. getMouseX() .. "," .. getMouseY() .. " hover " .. tostring(w._themeControlHover) .. " close " .. tostring(w._closeHover) .. " VALUES " .. values() .. " VIEW " .. tostring(MM.view))
'@
    shot = @'
getCore():TakeFullScreenshot("__NAME__")
say("SHOT __NAME__")
'@
    restore = @'
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
    if ($line -match 'TARGETS (\S+) (\S+) (\S+) (\S+)') { $o.t = @($Matches[1], $Matches[2], $Matches[3], $Matches[4]) }
    if ($line -match 'VALUES (\S+) (\S+) (\S+)') { $o.v = @($Matches[1], $Matches[2], $Matches[3]) }
    if ($line -match 'hover (\S+)') { $o.hover = $Matches[1] }
    if ($line -match 'close (\S+)') { $o.close = $Matches[1] }
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
    $names = @("theme", "accent", "text size")
    foreach ($view in @("main", "mods", "options", "load")) {
        $s = Parse (Run-Job "show" @{ VIEW = $view })
        if (-not $s.t) { "FAIL ${view}: no report"; $fails++; continue }
        if (-not $was) { $was = $s.v; "start values: $($was -join ' ')" }
        Check ($s.view -eq $view) "${view}: the window is up"
        $before = $s.v
        for ($i = 0; $i -lt 3; $i++) {
            if ($s.t[$i] -eq "none") { Check $false "${view}: the $($names[$i]) square is drawn"; continue }
            Point $s.t[$i]
            $h = Parse (Run-Job "probe" @{ VIEW = $view })
            Check ($h.hover -eq "$($i + 1)") "${view}: the $($names[$i]) square lights under the pointer (hover $($h.hover), pointer $($h.mouse))"
            $clicked = Click
            $a = Parse (Run-Job "probe" @{ VIEW = $view })
            Check ($clicked -and $a.v -and $a.v[$i] -ne $before[$i]) "${view}: a click on the $($names[$i]) square changes it ($($before[$i]) to $($a.v[$i]))"
            if ($view -eq "main") { [void](Run-Job "shot" @{ NAME = "zqa_mf_main_$($i + 1).png" }) }
            if ($a.v) { $before = $a.v }
            if ($i -eq 2) { $s = Parse (Run-Job "report" @{ VIEW = $view }) }   # (a size change moves the frame)
        }
        Point $s.t[3]
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
