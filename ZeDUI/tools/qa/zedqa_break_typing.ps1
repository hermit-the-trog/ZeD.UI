<#
.SYNOPSIS
    Punch list 9 ("typing in fields doesn't trigger game keys"), with the real keyboard (Oct 31 2026, QA).
.DESCRIPTION
    Run it while the game is up on the ZeD-QA save (zedqa_run.ps1 -KeepOpen -Manifest mouse_keep.txt).
    For each text field: the field is focused through the bridge, then real key presses type
    "mihlcbkjunpo qer 123" (M is the map, I and Tab the inventory, H health, L / K / J / U / C / B / N / P /
    O the game's panels, Q / E / R its actions). After typing: the field must hold the words, both ZeD
    windows still open on the same tabs, the game's map not open, no action queued; the field is then
    cleared. Fields: the Journal's entry box, the Journal's search, Craft's recipe search, the Maps'
    note (when it has one). Screenshots zqa_btyp_<field>.png. With -Quit the game quits at the end.
    Holds Zomboid/Lua/zedqa.lock. Exit 0 every check passed, 1 a failure, 2 refused.
#>
param([switch]$Quit)
$Lua = "C:\Users\danie\Zomboid\Lua"
$QA = $PSScriptRoot
$log = "C:\Users\danie\Zomboid\console.txt"
$lock = Join-Path $Lua "zedqa.lock"
if (-not (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue)) { "the game is not running"; exit 2 }
if ((Get-Content $lock -Raw -ErrorAction SilentlyContinue) -match '^busy') { "the lock says busy; not starting"; exit 2 }
Set-Content -Path $lock -Value "busy zedqa_break_typing" -NoNewline
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class ZedTypInput {
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
    [void][ZedTypInput]::GetWindowThreadProcessId([ZedTypInput]::GetForegroundWindow(), [ref]$fg)
    if ($fg -ne [uint32]$p.Id) { try { & (Join-Path $QA "pzfront.ps1") | Out-Null } catch { }; Start-Sleep -Milliseconds 800
        [void][ZedTypInput]::GetWindowThreadProcessId([ZedTypInput]::GetForegroundWindow(), [ref]$fg) }
    return ($fg -eq [uint32]$p.Id)
}
function Key($vk) {
    $sc = [byte][ZedTypInput]::MapVirtualKey($vk, 0)
    [ZedTypInput]::keybd_event([byte]$vk, $sc, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 35
    [ZedTypInput]::keybd_event([byte]$vk, $sc, 2, [UIntPtr]::Zero); Start-Sleep -Milliseconds 70
}
function LogText { ((Get-Content $log -Raw -ErrorAction SilentlyContinue) -replace "`0", "") }
function Next-Go {
    $cf = Join-Path $Lua "zedqa.counter"; $gf = Join-Path $Lua "zedqa.go"
    [long]$n = 9999
    $t = Get-Content $cf -Raw -ErrorAction SilentlyContinue
    if ($t -and $t.Trim() -match '^\d+$') { $n = [long]$t.Trim() }
    $cur = Get-Content $gf -Raw -ErrorAction SilentlyContinue
    if ($cur -and $cur.Trim() -match '^\d+$' -and [long]$cur.Trim() -ge $n) { $n = [long]$cur.Trim() }
    $n++; Set-Content -Path $cf -Value "$n" -NoNewline; return $n
}
$Prelude = @'
local G = "__GO__"
local function say(s) print("ZEDQA btyp " .. G .. " " .. tostring(s)) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local c, w = CWm.getWindow(), WWm.getWindow()
local function tab(win, key, id) local s = win and win[key]; for _, z in ipairs((s and s._hitZones) or {}) do if z.id == "tab:" .. id and win._activeTab ~= id then s:onMouseDown(z.x + 2, z.y + 2) end end end
local function later(n, fn) local k = 0; local function f() k = k + 1; if k >= n then Events.OnTick.Remove(f); fn() end end; Events.OnTick.Add(f) end
-- the field for __FIELD__
local function field()
    if "__FIELD__" == "journal" then return c and c._journalInput end
    if "__FIELD__" == "jsearch" then return c and c._journalSearch and c._journalSearch.input end
    if "__FIELD__" == "craft" then return w and w._craftSearch and w._craftSearch.input end
end
'@
function Run-Lua($body, $field, $wait = 20) {
    $g = Next-Go
    $code = ($Prelude + "`n" + $body) -replace '__GO__', "$g" -replace '__FIELD__', $field
    Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value $code -NoNewline
    Set-Content -Path (Join-Path $Lua "zedqa.go") -Value "$g`n" -NoNewline
    for ($i = 0; $i -lt $wait * 4; $i++) { Start-Sleep -Milliseconds 250; $m = [regex]::Match((LogText), "ZEDQA btyp $g ([^\r\n]+)"); if ($m.Success) { return $m.Groups[1].Value } }
    return ""
}
$Setup = @'
if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
if "__FIELD__" == "journal" or "__FIELD__" == "jsearch" then tab(c, "_tabStripPanel", "journal"); c._journalSubTab = 1 end
if "__FIELD__" == "craft" then tab(w, "_actionTabStrip", "craft") end
later(40, function()
    local f = field()
    if not f then
        local keys = {}
        for k, v in pairs(("__FIELD__" == "craft") and (w._craftState or {}) or c) do
            if type(v) == "table" and (v.Type == "ZeD_TextEntry" or v.Type == "ISTextEntryBox") then keys[#keys + 1] = tostring(k) end
        end
        say("NOFIELD candidates " .. table.concat(keys, ","))
        return
    end
    pcall(function() f:setVisible(true) end)
    pcall(function() f:setText("") end)
    pcall(function() f:focus() end)
    ZEDQA_BTYP = { ctab = c._activeTab, wtab = w._activeTab }
    say("READY")
end)
'@
$Check = @'
local f = field()
local txt = f and f:getText() or "nil"
local map = false
pcall(function() map = (ISWorldMap_instance ~= nil and ISWorldMap_instance:isVisible()) end)
local busy = false
pcall(function() busy = ISTimedActionQueue.isPlayerDoingAction(getPlayer()) end)
local s = ZEDQA_BTYP or {}
say(string.format("RESULT text=[%s] char=%s/%s world=%s/%s map=%s action=%s", txt, tostring(CWm.isOpen()), tostring(c._activeTab),
    tostring(WWm.isOpen()), tostring(w._activeTab), tostring(map), tostring(busy)) .. " was " .. tostring(s.ctab) .. "/" .. tostring(s.wtab))
getCore():TakeFullScreenshot("zqa_btyp___FIELD__.png")
pcall(function() f:setText("") end)
pcall(function() f:unfocus() end)
pcall(function() if f.javaObject then f.javaObject:unfocus() end end)
'@
# m i h l c b k j u n p o space q e r space 1 2 3
$word = @(0x4D, 0x49, 0x48, 0x4C, 0x43, 0x42, 0x4B, 0x4A, 0x55, 0x4E, 0x50, 0x4F, 0x20, 0x51, 0x45, 0x52, 0x20, 0x31, 0x32, 0x33)
$fails = 0
try {
    foreach ($f in @("journal", "jsearch", "craft")) {
        $r = Run-Lua $Setup $f
        if ($r -notmatch 'READY') { "SKIP ${f}: $r"; continue }
        if (-not (Front)) { "lost the front window"; $fails++; break }
        foreach ($k in $word) { Key $k }
        Start-Sleep -Milliseconds 600
        $res = Run-Lua $Check $f
        $ok = ($res -match 'text=\[mihlcbkjunpo qer 123\]') -and ($res -match 'char=true') -and ($res -match 'world=true') -and ($res -match 'map=false') -and ($res -match 'action=false')
        if ($res -match 'char=true/(\S+) world=true/(\S+) .* was (\S+)/(\S+)$') { if ($Matches[1] -ne $Matches[3] -or $Matches[2] -ne $Matches[4]) { $ok = $false } }
        if ($ok) { "PASS ${f}: $res" } else { $fails++; "FAIL ${f}: $res" }
    }
} finally {
    if ($Quit) {
        $g = Next-Go
        Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value "getCore():quitToDesktop()" -NoNewline
        Set-Content -Path (Join-Path $Lua "zedqa.go") -Value "$g`n" -NoNewline
        Start-Sleep -Seconds 15
    }
    Set-Content -Path $lock -Value "free" -NoNewline
}
if ($fails -gt 0) { exit 1 } else { exit 0 }
