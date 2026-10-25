<#
.SYNOPSIS
    The Mods screen's info pane tabs and file picks, at the main menu (Oct 24 2026;
    mockup zed_mods_settings_picks_v1, approved: "build the Mods screen changes as
    the mockup shows").
.DESCRIPTION
    Starts the game with a test mod list on (mods/default.txt: ZeD_UI, ZeD_Picks,
    Cone Vision Outline, GaelGunStore-Firearms, AAA_ModernFirearmsSystem, Constown
    B42, New Hartburg; Smart Radial Menu stays off) and, through the bridge at the
    main menu:
      * Cone Vision Outline: who made its options, its Options tab rows, a tick box
        changed in place reaches the option and ModOptions.ini, Defaults puts it back;
        its Sandbox tab (8 settings from its files)
      * Smart Radial Menu (off): the Options tab's note, its 4 sandbox settings
      * GaelGunStore-Firearms: the 13 shared files with AAA_ModernFirearmsSystem,
        the picker, two battery files picked, Use these picks (ZeD picks on and
        last, its copies are Gael's text), Undo picks (the copies follow load order)
      * Constown B42 / New Hartburg: the shared file with the same text is a grey note
    Pictures of each (the game's own frame only). Puts back default.txt,
    ModOptions.ini, the picks list and ZeD picks' folder, quits the game.
    Holds Zomboid/Lua/zedqa.lock. Exit 0 every check passed, 1 a failure, 2 refused.
#>
$Lua = "C:\Users\danie\Zomboid\Lua"
$QA = $PSScriptRoot
$Zomboid = "C:\Users\danie\Zomboid"
$log = Join-Path $Zomboid "console.txt"
$lock = Join-Path $Lua "zedqa.lock"
$DefaultMods = Join-Path $Zomboid "mods\default.txt"
$ModOptions = Join-Path $Lua "ModOptions.ini"
$PicksList = Join-Path $Lua "ZeD_picks.txt"
$Helper = Join-Path $Zomboid "mods\ZeD_Picks"
$Shots = Join-Path $Zomboid "Screenshots"
if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) { "the game is running; not starting"; exit 2 }
if ((Get-Content $lock -Raw -ErrorAction SilentlyContinue) -match '^busy') { "the lock says busy; not starting"; exit 2 }
if (-not (Test-Path (Join-Path $Helper "42\mod.info"))) { "ZeD picks is not installed at $Helper; not starting"; exit 2 }
Set-Content -Path $lock -Value "busy zedqa_mods_panes_run" -NoNewline

$Keep = Join-Path $env:TEMP "zedqa_mods_panes_keep"
New-Item -ItemType Directory -Force $Keep | Out-Null
Copy-Item $DefaultMods (Join-Path $Keep "default.txt") -Force
if (Test-Path $ModOptions) { Copy-Item $ModOptions (Join-Path $Keep "ModOptions.ini") -Force }
$hadPicks = Test-Path $PicksList
if ($hadPicks) { Copy-Item $PicksList (Join-Path $Keep "ZeD_picks.txt") -Force }

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
local MM = ZeD.MainMenu
local R = MM.root
local MS, S, P, OW = ZeD.ModScan, ZeD.ModSettings, ZeD.ModPicks, ZeD.ModOptionsOwners
local G = "__GO__"
local function say(s) print("ZEDQA mp " .. G .. " " .. tostring(s)) end
local function w() return R.modsWin end
local function m() return ModSelector.instance.model end
local function later(ms, fn)
    local t0 = getTimestampMs()
    local function f()
        if getTimestampMs() - t0 < ms then return end
        Events.OnFETick.Remove(f)
        local ok, e = pcall(fn)
        if not ok then say("ERR " .. tostring(e)) end
    end
    Events.OnFETick.Add(f)
end
local function rect() local x = w(); return math.floor(x:getAbsoluteX()) .. "," .. math.floor(x:getAbsoluteY()) .. "," .. math.floor(x.width) .. "," .. math.floor(x.height) end
local function sel(id, tab) local x = w(); x.filter = "all"; x.page = "list"; x.sel = id; x.dtab = tab; x.dscroll = 0; x.scroll = 0; x.focusId = nil end
local function fileConflict(id, other)
    for _, e in ipairs(MS.forMod(id)) do if e.kind == "file" and (e.loser == other or e.winner == other) then return e end end
end
'@
$Jobs = @{
    open = @'
MM.showView("main"); MM.openMods()
local t0 = getTimestampMs()
local function f()
    if not (MS.res.done or getTimestampMs() - t0 > 40000) then return end
    Events.OnFETick.Remove(f)
    local owners = {}
    for k, v in pairs(OW.byId) do owners[#owners + 1] = k .. "=" .. v end
    table.sort(owners)
    say("OPEN view=" .. tostring(MM.view) .. " scan=" .. tostring(MS.res.done) .. " owners=" .. table.concat(owners, ";"))
end
Events.OnFETick.Add(f)
'@
    cvoOptions = @'
sel("ConeVisionOutline", "options")
later(1500, function()
    local d = S.optionRows("ConeVisionOutline")
    local t = {}
    for _, sec in ipairs(d.sections) do for _, e in ipairs(sec.entries) do
        if e.kind == "opt" then t[#t + 1] = e.label .. "[" .. tostring(e.r and e.r.kind) .. "]" end
    end end
    local def = OW.default("ConeVisionOutline", "ScaleOutlineByLight")
    say("CVOOPT count=" .. d.count .. " rows=" .. table.concat(t, ";") .. " defLight=" .. tostring(def) .. " specs=" .. #w()._specs .. " RECT " .. rect())
end)
'@
    cvoToggle = @'
local d = S.optionRows("ConeVisionOutline")
local target
for _, sec in ipairs(d.sections) do for _, e in ipairs(sec.entries) do if e.option and e.option.id == "ScaleOutlineByLight" then target = e end end end
local c = target.r.control
local before = target.option.value
local want = not (c.selected[1] == true)
c.selected[1] = want
if c.changeOptionMethod then c.changeOptionMethod(c.changeOptionTarget, 1, want, c.changeOptionArg1, c.changeOptionArg2, c) end
later(1200, function()
    local ini = ""
    local r = getFileReader("ModOptions.ini", false)
    if r then local l = r:readLine(); while l do if l:find("ScaleOutlineByLight", 1, true) then ini = l end; l = r:readLine() end; r:close() end
    say("TOGGLE before=" .. tostring(before) .. " now=" .. tostring(target.option.value) .. " want=" .. tostring(want) .. " ini=" .. ini .. " offDefault=" .. tostring(S.offDefault("ConeVisionOutline")))
end)
'@
    cvoDefaults = @'
local ok = S.defaults("ConeVisionOutline")
later(800, function()
    local d = S.optionRows("ConeVisionOutline")
    local v
    for _, sec in ipairs(d.sections) do for _, e in ipairs(sec.entries) do if e.option and e.option.id == "ScaleOutlineByLight" then v = e.option.value end end end
    local ini = ""
    local r = getFileReader("ModOptions.ini", false)
    if r then local l = r:readLine(); while l do if l:find("ScaleOutlineByLight", 1, true) then ini = l end; l = r:readLine() end; r:close() end
    say("DEFAULTS ran=" .. tostring(ok) .. " value=" .. tostring(v) .. " ini=" .. ini .. " offDefault=" .. tostring(S.offDefault("ConeVisionOutline")))
end)
'@
    sandbox = @'
sel("__MOD__", "sandbox")
later(1200, function()
    local s = S.sandbox("__MOD__")
    local t = {}
    for _, st in ipairs(s and s.list or {}) do
        local v = st.value
        if st.type == "boolean" then v = st.on and "on" or "off" end
        t[#t + 1] = st.label .. "=" .. tostring(v)
    end
    say("SANDBOX mod=__MOD__ n=" .. #t .. " pages=" .. table.concat(s and s.pages or {}, ",") .. " list=" .. table.concat(t, ";"))
end)
'@
    srmOff = @'
sel("SmartRadialMenu", "options")
later(1200, function()
    local dd = m().mods["SmartRadialMenu"]
    local tabs = {}
    for _, t in ipairs(w():detailTabs(dd)) do tabs[#tabs + 1] = t.id .. "=" .. tostring(t.count) end
    say("SRM active=" .. tostring(dd.isActive) .. " tabs=" .. table.concat(tabs, ";") .. " options=" .. S.count("SmartRadialMenu"))
end)
'@
    gaelConflict = @'
sel("GaelGunStore_B42", "conflicts")
later(1200, function()
    local e = fileConflict("GaelGunStore_B42", "ModernFirearmsSystem")
    local chips = {}
    for _, c in ipairs(w():rowChips(m().mods["GaelGunStore_B42"])) do chips[#chips + 1] = c[1] end
    say("GAEL found=" .. tostring(e ~= nil) .. " loser=" .. tostring(e and e.loser) .. " winner=" .. tostring(e and e.winner) .. " files=" .. tostring(e and #e.things) .. " same=" .. tostring(e and e.same) .. " canPick=" .. tostring(e and w():canPick(e)) .. " chips=" .. table.concat(chips, ";") .. " count=" .. MS.count("GaelGunStore_B42") .. " optGael=" .. S.count("GaelGunStore_B42") .. " optMfs=" .. S.count("ModernFirearmsSystem"))
end)
'@
    pickerOpen = @'
local e = fileConflict("GaelGunStore_B42", "ModernFirearmsSystem")
w():enterPicks(e)
for i, p in ipairs(w().pickFiles) do if p:find("ISGunAddBatteryAction", 1, true) then w().pickSel = i end end
later(1200, function()
    local path = w().pickFiles[w().pickSel]
    local la, lb = P.lines(e.loser, path), P.lines(e.winner, path)
    say("PICKER page=" .. tostring(w().page) .. " files=" .. #w().pickFiles .. " sel=" .. tostring(path) .. " lines=" .. #(la or {}) .. "/" .. #(lb or {}) .. " diff=" .. P.diffCount(la, lb) .. " changed=" .. tostring(w():picksChanged()))
end)
'@
    pickerPick = @'
local e = w().pickFor
for _, p in ipairs(w().pickFiles) do if p:find("BatteryAction", 1, true) then w():setPick(p, e.loser) end end
later(1000, function()
    local n = 0
    for _, p in ipairs(w().pickFiles) do if w().pickDraft[p] then n = n + 1 end end
    say("DRAFT picked=" .. n .. " changed=" .. tostring(w():picksChanged()) .. " ask=" .. tostring(w()._ask))
end)
'@
    pickerUse = @'
local e = w().pickFor
local paths = {}
for _, p in ipairs(w().pickFiles) do if w().pickDraft[p] then paths[#paths + 1] = p end end
w():usePicks()
sel("GaelGunStore_B42", "conflicts")
later(1500, function()
    P.reset()
    local same = 0
    for _, p in ipairs(paths) do if P.same("GaelGunStore_B42", "ZeD_Picks", p) then same = same + 1 end end
    local order = {}
    local list = m():getActiveMods():getMods()
    for i = 0, list:size() - 1 do order[#order + 1] = list:get(i) end
    local h = m().mods["ZeD_Picks"]
    local chips = {}
    for _, c in ipairs(w():rowChips(m().mods["GaelGunStore_B42"])) do chips[#chips + 1] = c[1] end
    say("USED page=" .. tostring(w().page) .. " picks=" .. #paths .. " helperCopiesAreGael=" .. same .. " helperOn=" .. tostring(h and h.isActive) .. " last=" .. tostring(order[#order]) .. " chips=" .. table.concat(chips, ";") .. " ask=" .. tostring(w()._ask))
end)
'@
    undo = @'
local e = fileConflict("GaelGunStore_B42", "ModernFirearmsSystem")
local paths = {}
for _, p in ipairs(e.things) do if P.pickOf(p) then paths[#paths + 1] = p end end
w():undoPicks(e)
later(1200, function()
    P.reset()
    local mfs = 0
    for _, p in ipairs(paths) do if P.same("ModernFirearmsSystem", "ZeD_Picks", p) then mfs = mfs + 1 end end
    local left = 0
    for _ in pairs(P.picks()) do left = left + 1 end
    say("UNDO picksLeft=" .. left .. " helperCopiesFollowLoadOrder=" .. mfs .. "/" .. #paths)
end)
'@
    same = @'
sel("Constown42", "conflicts")
later(1200, function()
    local t = {}
    for _, e in ipairs(MS.forMod("Constown42")) do t[#t + 1] = e.kind .. ":" .. tostring(e.sameAll) .. ":" .. #e.things end
    local chips = {}
    for _, c in ipairs(w():rowChips(m().mods["Constown42"])) do chips[#chips + 1] = c[1] end
    say("SAME entries=" .. table.concat(t, ";") .. " count=" .. MS.count("Constown42") .. " chips=" .. table.concat(chips, ";"))
end)
'@
    reload = @'
-- the Mods screen's Reload (its accept), run from the window's own draw: a Lua reset from the
-- bridge's tick closes the game (KB Q265), one from the UI is vanilla's own path
local x = w()
local was = x.prerender
x.prerender = function(self, ...)
    self.prerender = was
    was(self, ...)
    say("RELOAD pressing accept, refreshed=" .. tostring(self._picksRefreshed))
    self:accept()
end
'@
    loaded = @'
local hits = {}
for i = 0, getLoadedLuaCount() - 1 do
    local f = tostring(getLoadedLua(i)):gsub("\\", "/")
    if f:find("ISGunAddBatteryAction", 1, true) or f:find("ISGunRemoveBatteryAction", 1, true) then
        hits[#hits + 1] = (f:match("/mods/([^/]+)/") or "?") .. ":" .. (f:match("([^/]+)$") or f)
    end
end
local n = 0
for _ in pairs(P.picks()) do n = n + 1 end
say("LOADED " .. table.concat(hits, ";") .. " picksKept=" .. n)
'@
    shot = @'
later(500, function() getCore():TakeFullScreenshot("__NAME__"); say("SHOT __NAME__ RECT " .. rect()) end)
'@
    back = @'
w():revert()
MM.showView("main")
say("BACK view=" .. tostring(MM.view))
'@
}
function Run-Job($job, $subs, $wait = 60) {
    $g = Next-Go
    $text = ($Prelude + "`n" + $Jobs[$job]) -replace '__GO__', "$g"
    if ($subs) { foreach ($k in $subs.Keys) { $text = $text -replace "__$($k)__", $subs[$k] } }
    Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value $text -NoNewline
    Set-Content -Path (Join-Path $Lua "zedqa.go") -Value "$g`n" -NoNewline
    $m = Wait-Log "ZEDQA mp $g ([^\r\n]+)" $wait
    if (-not $m) { $script:fails++; Write-Host "FAIL ${job}: no answer"; return "" }
    $line = $m.Groups[1].Value
    Write-Host "  $job -> $line"
    if ($line -match '^ERR') { $script:fails++; Write-Host "FAIL ${job}: $line" }
    return $line
}
function Shot($name) { Run-Job "shot" @{ NAME = "zqa_mp_$name.png" } 30 | Out-Null }

$p = $null
$out = New-Object System.Collections.Generic.List[string]
try {
    # the test's mod list, ZeD last but ZeD picks after it (the game keeps this order)
    $list = @("ConeVisionOutline", "GaelGunStore_B42", "ModernFirearmsSystem", "Constown42", "newhartburg", "ZeD_UI", "ZeD_Picks")
    $txt = "VERSION = 1,`n`nmods`n{`n" + (($list | ForEach-Object { "    mod = $_," }) -join "`n") + "`n}`n`nmaps`n{`n}`n"
    Set-Content -Path $DefaultMods -Value $txt -NoNewline
    Remove-Item $PicksList -ErrorAction SilentlyContinue
    Set-Content -Path (Join-Path $Lua "zedqa.autoload") -Value "0" -NoNewline
    $dir = "E:\Project Zomboid\SteamApps\common\ProjectZomboid"
    $p = Start-Process -FilePath "$dir\ProjectZomboid64.exe" -ArgumentList "-debug" -WorkingDirectory $dir -PassThru
    "started the game (process $($p.Id))"
    Start-Sleep -Seconds 15
    if (-not (Wait-Log 'bridge armed \(main menu' 600)) { "never reached the main menu"; $fails++; return }
    Start-Sleep -Seconds 10

    $l = Run-Job "open" $null 90
    Check ($l -match 'view=mods') "the Mods screen opens"
    Check ($l -match 'scan=true') "the conflict scan finishes"
    Check ($l -match 'ConeVisionOutline=ConeVisionOutline') "Cone Vision Outline's options are known to be its own"

    $l = Run-Job "cvoOptions"
    Check ($l -match 'count=8') "Cone Vision Outline: 8 options in its Options tab"
    Check ($l -match 'Scale outline by light level\[tick\]') "its rows are the Options window's (a tick box for Scale outline by light level)"
    Check ($l -match 'defLight=false') "its declared default is noted (Scale outline by light level: off)"
    Shot "1_cvo_options"
    $l = Run-Job "cvoToggle"
    Check ($l -match 'now=(\S+) want=(\S+)' -and $Matches[1] -eq $Matches[2]) "a tick box changed in the pane reaches the option"
    Check ($l -match 'ini=\S*ScaleOutlineByLight\S*') "the change is saved in ModOptions.ini"
    Check ($l -match 'offDefault=true') "the pane knows it is off its default"
    Shot "2_cvo_changed"
    $l = Run-Job "cvoDefaults"
    Check ($l -match 'ran=true value=false') "Defaults puts it back"
    Check ($l -match 'offDefault=false') "nothing is off its default after Defaults"
    $l = Run-Job "sandbox" @{ MOD = "ConeVisionOutline" }
    Check ($l -match 'n=8') "Cone Vision Outline: 8 sandbox settings read from its files"
    Check ($l -match 'Enforce these settings for all players=off' -and $l -match 'Outline animals=on') "they carry the mod's own names and defaults"
    Shot "3_cvo_sandbox"
    $l = Run-Job "srmOff"
    Check ($l -match 'active=false') "Smart Radial Menu is off"
    Check ($l -match 'sandbox=4') "its 4 sandbox settings are readable while it is off"
    Shot "4_srm_off"
    $l = Run-Job "sandbox" @{ MOD = "SmartRadialMenu" }
    Check ($l -match 'Add a slice to rip all clothing') "an off mod's sandbox settings are named from its own translation file"
    Shot "5_srm_sandbox"
    $l = Run-Job "gaelConflict"
    Check ($l -match 'found=true') "GaelGunStore-Firearms and AAA_ModernFirearmsSystem: a file conflict"
    Check ($l -match 'files=(1[3-9]|[2-9]\d)') "the shared files are all listed (13 or more)"
    Check ($l -match 'canPick=true') "Pick file by file is offered"
    Check ($l -match 'optGael=([1-9]\d*)') "GaelGunStore-Firearms' options (named unlike the mod) are found as its own ($($Matches[1]))"
    Check ($l -match 'optMfs=([1-9]\d*)') "AAA_ModernFirearmsSystem's options (AWCWF_42_Patch) are found as its own"
    Shot "6_gael_conflict"
    $l = Run-Job "pickerOpen"
    Check ($l -match 'page=picks files=(1[3-9]|[2-9]\d)') "the picker opens with the shared files"
    Check ($l -match 'diff=6') "ISGunAddBatteryAction.lua: 6 lines differ"
    Shot "7_picker"
    $l = Run-Job "pickerPick"
    Check ($l -match 'picked=2 changed=true') "two battery files picked from GaelGunStore-Firearms"
    Shot "8_picker_picked"
    $l = Run-Job "pickerUse"
    Check ($l -match 'page=list') "Use these picks goes back to the list"
    Check ($l -match 'helperCopiesAreGael=2') "ZeD picks holds GaelGunStore-Firearms' copies of the 2 files"
    Check ($l -match 'helperOn=true') "ZeD picks is on"
    Check ($l -match 'last=ZeD_Picks') "ZeD picks loads last"
    Check ($l -match 'chips=[^=]*PICKED') "the row says PICKED"
    Check ($l -match 'ask=Picked files changed') "the strip says a reload puts the picks in place"
    Shot "9_picked"
    # Reload (the strip's button, vanilla's Lua reset), then: did the game load ZeD picks' copies?
    $armed = ([regex]::Matches((LogText), 'bridge armed \(main menu')).Count
    [void](Run-Job "reload")
    $back = $false
    for ($i = 0; $i -lt 240; $i++) {
        Start-Sleep -Milliseconds 500
        if ($p.HasExited) { break }
        if (([regex]::Matches((LogText), 'bridge armed \(main menu')).Count -gt $armed) { $back = $true; break }
    }
    Check ($back) "Reload: the game reloads its Lua and comes back to the main menu (no restart)"
    if ($back) {
        Start-Sleep -Seconds 8
        $l = Run-Job "loaded"
        Check ($l -match 'ZeD_Picks:ISGunAddBatteryAction.lua' -and $l -match 'ZeD_Picks:ISGunRemoveBatteryAction.lua') "after the reload the game runs ZeD picks' copies of the 2 files"
        Check ($l -match 'picksKept=2') "the picks are kept across the reload"
        $l = Run-Job "open" $null 90
        Check ($l -match 'scan=true') "the Mods screen opens again after the reload"
        $l = Run-Job "gaelConflict"
        Check ($l -match 'files=13') "with ZeD picks running, it is still the two mods' conflict (13 files)"
        Check ($l -match 'chips=[^=]*PICKED') "and the row still says PICKED"
    }
    $l = Run-Job "undo"
    Check ($l -match 'picksLeft=0') "Undo picks clears them"
    Check ($l -match 'FollowLoadOrder=2/2') "ZeD picks' copies then follow load order (AAA_ModernFirearmsSystem's text)"
    $l = Run-Job "same"
    Check ($l -match 'file:true:1') "Constown B42 and New Hartburg: one shared file, the same text"
    Check ($l -match 'count=0') "it is not counted as a conflict"
    Check ($l -match 'chips=SAME TEXT') "the row says SAME TEXT"
    Shot "10_same_text"
    [void](Run-Job "back")
} finally {
    if ($p -and -not $p.HasExited) {
        $g = Next-Go
        Set-Content -Path (Join-Path $Lua "zedqa.lua") -Value "getCore():quit()" -NoNewline
        Set-Content -Path (Join-Path $Lua "zedqa.go") -Value "$g`n" -NoNewline
        for ($i = 0; $i -lt 60; $i++) { Start-Sleep -Seconds 2; if ($p.HasExited) { break } }
        if ($p.HasExited) { "the game closed" } else { "the game is still running (process $($p.Id)); left open" }
    }
    Copy-Item (Join-Path $Keep "default.txt") $DefaultMods -Force
    if (Test-Path (Join-Path $Keep "ModOptions.ini")) { Copy-Item (Join-Path $Keep "ModOptions.ini") $ModOptions -Force }
    if ($hadPicks) { Copy-Item (Join-Path $Keep "ZeD_picks.txt") $PicksList -Force } else { Remove-Item $PicksList -ErrorAction SilentlyContinue }
    $media = Join-Path $Helper "common\media"
    if (Test-Path $media) { Remove-Item $media -Recurse -Force }
    "put back: default.txt, ModOptions.ini, the picks list, ZeD picks' folder"
    if (-not ($p -and -not $p.HasExited)) { Set-Content -Path $lock -Value "free" -NoNewline }
    if ($fails -eq 0) { "all checks passed" } else { "$fails failed" }
}
if ($fails -eq 0) { exit 0 } else { exit 1 }
