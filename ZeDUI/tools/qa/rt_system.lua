-- ZeDUI/tools/qa/rt_system.lua  (Nov 18 2026, QA; tag rt_sys): the release test's system row (ZeDUI/qa/RELEASE_TEST.md).
-- Built on rt_kit.lua (the global RT); run after it. grep "ZEDQA rt_sys".
--   1. ZeD setup's settings (Settings.lua): a setting changed through ZeD's settings API (the action bar's style) is
--      written to ModOptions.ini, comes back when the game reads that file again, and is put back (file and value)
--   2. the in-game Options (ZeD_MainMenuOptions.lua, ZeD_MainMenuOptionGroups.lua): opened from the pause menu; ZeD
--      setup has its rows and groups; every group's page opens on screen with no Lua error; Back leaves it
--   3. UI scale (shared/ZeD/Scale.lua): every step this screen offers (not the retired 0.5x, not one too big for the
--      screen) is applied as ZeD setup applies it; the theme follows the new scale and both windows come back open
--      and on screen (RT.bounds); then the run's own step, and the windows where they were
--   4. themes and accents (Tokens.lua, PlayerTheme.lua): each base theme and each accent applies to ZeD's table and
--      the windows draw on screen in each base theme; then the run's own theme
--   5. safe mode (SafeMode.lua; zedqa_safemode.lua's checks): a trip shuts ZeD's windows and hands back the game's
--      inventory page, hotbar and moodles with a note; the inventory key goes to the game; a reset brings ZeD back;
--      the Safe mode option On and Off is picked up by itself within a second; a short burst of faults leaves ZeD on;
--      one place failing every frame trips it at two seconds, not before
--   6. step-aside (ZeD_StepAside.lua): with a mod that replaces a ZeD screen, that screen is handed back (its switch,
--      the record, "Taken by"); SKIP when no such mod is active
--   7. Messages (ZeD_Messages.lua, ZeD_MessagesWindow.lua): another mod's note is kept, not shown; the window opens
--      on that mod with the note's card; its OK runs the mod's own callback once
--   8. a short soak: two minutes of play with both windows open and their tabs turned, no new Lua error, and Lua
--      memory (collectgarbage("count"), after a full collect) grows by no more than SOAK_KB
--   9. translation (shared/ZeD/Tr.lua): every key in ZeD's English UI.json has text in the game, and every key ZeD
--      asked ZeD.tr for while this script ran (themes, scales, every tab in the soak) has text
-- Every setting is put back exactly (the option values, the file, the scale, the theme, the windows).
if not RT then
    print("ZEDQA rt_sys FAIL the kit (rt_kit.lua) is not loaded")
    print("ZEDQA rt_sys VERDICT FAIL 1")
    print("ZEDQA rt_sys DONE")
    return
end
local Q = RT.make("rt_sys")
Q.maxMs = 1020000                    -- (the runner gives this script 1200 s: the put-back runs before that)
local p, pn = RT.p, RT.pn
local St, Sf, MM, Sc = ZeD.Settings, ZeD.Safe, ZeD.MainMenu, ZeD.Scale
local SOAK_MS = 120000               -- two minutes of play
local SOAK_KB = 262144               -- the soak's memory bound: 256 MB of Java heap after a full collect
-- the run's state, one table (Kahlua's local limit)
local S = { keys = {}, trOn = false }
local H = {}

-- ===================================================================== helpers
function H.errs()
    local n = nil
    pcall(function() n = getLuaDebuggerErrorCount() end)
    return n
end
function H.mem()
    local kb = nil
    pcall(function() collectgarbage("collect") end)
    pcall(function() kb = collectgarbage("count") end)
    return kb
end
function H.menuUp()
    local up = false
    pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end)
    return up
end
function H.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
function H.onScreen(el)
    local ok = false
    pcall(function()
        local W, Hh = getCore():getScreenWidth(), getCore():getScreenHeight()
        local x, y = el:getAbsoluteX(), el:getAbsoluteY()
        ok = x >= -1 and y >= -1 and x + el:getWidth() <= W + 1 and y + el:getHeight() <= Hh + 1
    end)
    return ok
end
-- ModOptions.ini's stored value for one of ZeD's options (the line "combobox|ZeD_UI|<id>|<n>"), nil when absent
function H.iniValue(id)
    local v = nil
    pcall(function()
        local r = getFileReader("ModOptions.ini", false)
        if not r then return end
        local want = "combobox|ZeD_UI|" .. id .. "|"
        local l = r:readLine()
        while l do
            if l:sub(1, #want) == want then v = tonumber(l:sub(#want + 1)) end
            l = r:readLine()
        end
        r:close()
    end)
    return v
end
-- ModOptions.ini as lines (nil when it cannot be read), and written back as it was (the game's own line ends)
function H.readIni()
    local t = nil
    pcall(function()
        local r = getFileReader("ModOptions.ini", false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
function H.writeIni(lines)
    if not lines then return false end
    local ok = pcall(function()
        local w = getFileWriter("ModOptions.ini", true, false)
        for _, l in ipairs(lines) do w:write(l .. "\r\n") end
        w:close()
    end)
    return ok
end
function H.bothOpen()
    local c, w = false, false
    pcall(function() c = ZeD_CharacterWindow.isOpen(pn) end)
    pcall(function() w = ZeD_WorldWindow.isOpen(pn) end)
    return c and w
end

-- every key ZeD.tr is asked for while the script runs (checked at the end: section 9)
S.trWas = ZeD.tr
ZeD.tr = function(key, ...)
    if S.trOn and type(key) == "string" then S.keys[key] = true end
    return S.trWas(key, ...)
end

-- ===================================================================== 0. setup
Q.step(5, function()
    S.trOn = true
    S.winsWere = RT.isOpen()
    RT.pairOpen()
    if ZEDQA_LAYOUT_SNAP then pcall(function() S.snap = ZEDQA_LAYOUT_SNAP() end) end
    S.err0 = H.errs()
    Q.check(St ~= nil and Sf ~= nil and MM ~= nil and Sc ~= nil, "ZeD's settings, safe mode, main menu and scale modules are loaded")
end)

-- ===================================================================== 1. a setting saves and comes back
Q.step(5, function()
    local o = St.actionBarOption
    if not o then Q.check(false, "ZeD's settings API has the action bar option"); return end
    S.abWas = o:getValue()
    S.abIniWas = H.iniValue("actionBar")
    -- (the whole file kept: saving writes every option's value in memory, so it is put back line for line)
    S.ini0 = H.readIni()
    S.abNew = (S.abWas == 2) and 1 or 2
    o:setValue(S.abNew)
    St.save()
    Q.check(H.iniValue("actionBar") == S.abNew, "a changed setting is written to ModOptions.ini", "file " .. tostring(H.iniValue("actionBar")) .. ", want " .. S.abNew)
    -- the value in memory set back, then the game reads its file again: the saved one comes back
    o:setValue(S.abWas)
    pcall(function() PZAPI.ModOptions:load() end)
    Q.check(o:getValue() == S.abNew, "the saved setting comes back when the game reads ModOptions.ini", "value " .. tostring(o:getValue()))
end)
Q.step(5, function()
    local o = St.actionBarOption
    if not (o and S.abWas) then return end
    o:setValue(S.abWas)
    if S.ini0 then H.writeIni(S.ini0) else St.save() end
    S.iniBack = true
    Q.check(o:getValue() == S.abWas and H.iniValue("actionBar") == S.abIniWas, "the setting is put back, in memory and in the file",
        "value " .. tostring(o:getValue()) .. ", file " .. tostring(H.iniValue("actionBar")))
    local now = H.readIni()
    Q.check(S.ini0 ~= nil and now ~= nil and table.concat(now, "\n") == table.concat(S.ini0, "\n"), "ModOptions.ini is back line for line",
        tostring(now and #now) .. " lines, " .. tostring(S.ini0 and #S.ini0) .. " before")
end)

-- ===================================================================== 2. the in-game Options: ZeD setup and the groups
Q.step(5, function()
    S.menuWas = H.menuUp()
    if not S.menuWas then H.toggleMenu() end
end)
Q.waitFor(10, 400, function() return H.menuUp() and MM.pauseOpts ~= nil end, function(ok)
    Q.check(ok, "the pause menu opens (ZeD's pause window)")
    if ok then pcall(MM.openOptions) end
end)
Q.waitFor(5, 300, function() return MM.pauseOpts ~= nil and MM.pauseOpts:isVisible() end, function(ok)
    Q.check(ok, "Options opens from the pause menu (ZeD's window)")
    S.optsOk = ok
    if not ok then return end
    local w = MM.pauseOpts
    S.pages = w:pages()
    S.pageWas = w.pageIdx
    S.pageRes = {}
    S.pi, S.pf = 0, 0
    S.errOpts = H.errs()
end)
-- each page in turn, six frames each; what each one showed is kept for the checks
Q.waitFor(2, 3000, function()
    if not S.optsOk then return true end
    local w = MM.pauseOpts
    S.pf = S.pf + 1
    if S.pf < 6 then return false end
    S.pf = 0
    if S.pi > 0 then
        local pg = S.pages[S.pi]
        local rows = w:rowsFor(pg) or {}
        local heads = 0
        for _, r in ipairs(rows) do if r.kind == "header" then heads = heads + 1 end end
        S.pageRes[S.pi] = { title = tostring(pg.title), setup = pg.setup, rows = #rows, heads = heads,
            shown = w:isVisible() and w.pageIdx == S.pi, onScreen = H.onScreen(w) }
    end
    S.pi = S.pi + 1
    if S.pi > #S.pages then return true end
    w.pageIdx = S.pi
    w.scroll = 0
    return false
end, function(ok)
    if not S.optsOk then return end
    Q.check(ok and #S.pageRes == #S.pages and #S.pages > 1, "every Options group's page was opened", #S.pageRes .. " of " .. #S.pages)
    local setupSeen = false
    for _, r in ipairs(S.pageRes) do
        if r.setup then
            setupSeen = true
            Q.check(r.rows > 0 and r.heads > 0, "ZeD setup opens with its groups and rows", r.heads .. " groups, " .. r.rows .. " rows")
        end
        Q.check(r.shown and r.onScreen, "Options, " .. r.title .. ": the page opens, the window on screen", r.rows .. " rows")
    end
    Q.check(setupSeen, "Options has ZeD setup")
    local e1 = H.errs()
    if S.errOpts and e1 then Q.check(e1 == S.errOpts, "the Options pages drew with no Lua error", (e1 - S.errOpts) .. " new") end
end)
Q.step(5, function()
    local w = MM.pauseOpts
    if not (S.optsOk and w) then return end
    if S.pageWas then w.pageIdx = S.pageWas end
    pcall(function() w:back() end)
end)
Q.step(10, function()
    if S.optsOk then Q.check(MM.pauseView == "pause", "Back leaves Options for the pause menu", tostring(MM.pauseView)) end
    if not S.menuWas and H.menuUp() then H.toggleMenu() end
end)
Q.waitFor(5, 300, function() return S.menuWas or not H.menuUp() end, function(ok)
    Q.check(ok, "the pause menu shuts again")
end)

-- ===================================================================== 3. UI scale: every step offered
Q.step(10, function()
    S.scaleOpt = St.uiScaleOption
    S.scaleWas = S.scaleOpt:getValue() or 1
    S.rootWas = Sc.root()
    RT.pairOpen()
end)
for i = 1, #((St and St.scaleKeys) or {}) do
    Q.step(5, function()
        S.stepSkip = nil
        local v = St.scaleKeys[i]
        if St.scaleStepOff(S.scaleOpt, i) then
            S.stepSkip = true
            Q.say("scale step " .. tostring(St.scaleLabels[i]) .. ": not offered on this screen (retired or too big)")
            return
        end
        S.scaleOpt:setValue(i)
        St.applyScale(i)
        S.wantRoot = (type(v) == "number") and v or nil
    end)
    Q.waitFor(10, 900, function()
        if S.stepSkip then return true end
        local T = ZeD.T
        return Sc._reopenAt == nil and T ~= nil and math.abs((T.root or 0) - Sc.root()) < 0.001 and H.bothOpen()
    end, function(ok)
        if S.stepSkip then return end
        local label = tostring(St.scaleLabels[i])
        Q.check(ok, "UI scale " .. label .. ": the theme follows the new scale and both windows are open again", "root " .. tostring(Sc.root()))
        if S.wantRoot then Q.check(math.abs(Sc.root() - S.wantRoot) < 0.001, "UI scale " .. label .. ": drawn at that scale", "root " .. tostring(Sc.root())) end
        RT.bounds(Q, "UI scale " .. label)
    end)
end
Q.step(5, function()
    S.scaleOpt:setValue(S.scaleWas)
    St.applyScale(S.scaleWas)
end)
Q.waitFor(10, 900, function()
    local T = ZeD.T
    return Sc._reopenAt == nil and T ~= nil and math.abs((T.root or 0) - Sc.root()) < 0.001
end, function(ok)
    Q.check(ok and S.scaleOpt:getValue() == S.scaleWas and math.abs(Sc.root() - S.rootWas) < 0.001,
        "UI scale put back on the run's own step", "option " .. tostring(S.scaleOpt:getValue()) .. ", root " .. tostring(Sc.root()))
    if ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, S.snap, "rt_sys scale") end
end)
Q.step(30, function() RT.bounds(Q, "the windows back after the scale steps") end)

-- ===================================================================== 4. themes and accents
Q.step(5, function()
    S.base0, S.accent0, S.size0 = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    RT.pairOpen()
end)
for _, b in ipairs((St and St.baseKeys) or {}) do
    Q.step(3, function() ZeD.applyTheme(b, S.accent0, S.size0) end)
    Q.step(8, function()
        local T = ZeD.T
        Q.check(T ~= nil and T.baseKey == b and ZeD.currentBase == b, "theme " .. b .. ": applies to ZeD's table", tostring(T and T.baseKey))
        RT.bounds(Q, "theme " .. b)
    end)
end
Q.step(3, function() ZeD.applyTheme(S.base0, S.accent0, S.size0) end)
for _, a in ipairs((St and St.accentKeys) or {}) do
    Q.step(2, function() ZeD.applyTheme(S.base0, a, S.size0) end)
    Q.step(4, function()
        local T = ZeD.T
        Q.check(T ~= nil and T.accentKey == a and T.accent ~= nil and ZeD.currentAccent == a, "accent " .. a .. ": applies to ZeD's table",
            tostring(T and T.accentKey))
    end)
end
Q.step(3, function() ZeD.applyTheme(S.base0, S.accent0, S.size0) end)
Q.step(5, function()
    local T = ZeD.T
    Q.check(ZeD.currentBase == S.base0 and ZeD.currentAccent == S.accent0 and ZeD.currentSize == S.size0 and T and T.baseKey == S.base0,
        "the run's own theme, accent and text size are back", tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize))
end)

-- ===================================================================== 5. safe mode
function H.vanillaInv() local v = false; pcall(function() local vi = getPlayerInventory(pn); v = vi ~= nil and vi:isVisible() end); return v end
function H.hotbar()
    local orig = Sf._originals and Sf._originals.ISHotbar
    if not orig then return "no original kept" end
    return (ISHotbar.render == orig.render) and "vanilla" or "replaced"
end
function H.moodles() local s = "none"; pcall(function() local l = ZeD.Moodles.getLayer(pn); if l then s = tostring(l:isVisible()) end end); return s end
function H.bothShut()
    local c, w = true, true
    pcall(function() c = ZeD_CharacterWindow.isOpen(pn) end)
    pcall(function() w = ZeD_WorldWindow.isOpen(pn) end)
    return not c and not w
end
function H.note()
    local n = Sf._note
    if n and n.javaObject and n:isVisible() then return n end
    return nil
end
function H.closeNote()
    local n = H.note()
    if not n then return false end
    pcall(function() if n.ok then n:onClick(n.ok) else n:destroy() end end)
    return true
end
function H.state()
    return "on " .. tostring(Sf.on()) .. " | pair shut " .. tostring(H.bothShut()) .. " | game's inventory " .. tostring(H.vanillaInv())
        .. " | hotbar " .. H.hotbar() .. " | moodle layer " .. H.moodles()
end
Q.step(5, function()
    S.safeOpt = St.safeModeOption
    S.safeWas = S.safeOpt:getValue()
    S.invKey = getCore():getKey("Toggle Inventory")
    RT.pairOpen()
end)
Q.step(30, function()
    Q.say("safe mode baseline: " .. H.state())
    S.safeSkip = Sf.on()
    if S.safeSkip then Q.skip("safe mode", "safe mode is already on in this game: ZeD is not running to trip"); return end
    Q.check(not H.bothShut() and not H.vanillaInv() and H.hotbar() == "replaced", "safe mode: ZeD runs to start with (its windows, its hotbar)")
    Sf.trip("rt_sys trip", "a test trip")
end)
Q.step(30, function()
    if S.safeSkip then return end
    Q.say("tripped: " .. H.state())
    Q.check(Sf.on() and H.bothShut(), "a trip: ZeD's windows shut")
    Q.check(H.vanillaInv() and H.hotbar() == "vanilla" and H.moodles() ~= "true", "a trip: the game's own inventory page, hotbar and moodles come back")
    Q.check(H.closeNote(), "a trip: the note shows (the game's own dialog) and closes")
end)
Q.step(10, function()
    if S.safeSkip then return end
    S.inv1 = H.vanillaInv()
    pcall(ZeD_CharacterWindow._onKeyPressed, S.invKey)
    S.inv2 = H.vanillaInv()
end)
Q.step(10, function()
    if S.safeSkip then return end
    pcall(ZeD_CharacterWindow._onKeyPressed, S.invKey)
    local inv3 = H.vanillaInv()
    Q.check(S.inv1 and not S.inv2 and inv3 and H.bothShut(), "tripped, the inventory key works the game's own page (hides, shows)",
        tostring(S.inv1) .. " -> " .. tostring(S.inv2) .. " -> " .. tostring(inv3))
    Sf.reset()
end)
Q.step(30, function()
    if S.safeSkip then return end
    Q.say("reset: " .. H.state())
    Q.check(not Sf.on() and H.hotbar() == "replaced" and H.moodles() == "true" and not H.vanillaInv(), "a reset brings ZeD back and hides the game's page")
    RT.pairOpen()
end)
Q.step(30, function()
    if S.safeSkip then return end
    Q.check(H.bothOpen() and not H.vanillaInv(), "after the reset ZeD's windows open again")
    RT.bounds(Q, "the windows after a safe mode reset")
end)
-- the option, with no forced re-read: the half-second poll picks it up
function H.optionPoll(value, want, name)
    Q.step(5, function()
        if S.safeSkip then return end
        S.safeOpt:setValue(value)
        S.tOpt = getTimestampMs()
    end)
    Q.waitFor(1, 900, function()
        if S.safeSkip then return true end
        return Sf.on() == want or getTimestampMs() - S.tOpt > 1000
    end, function()
        if S.safeSkip then return end
        local ms = getTimestampMs() - S.tOpt
        Q.check(Sf.on() == want and ms <= 1000, name, ms .. " ms")
    end)
end
H.optionPoll(2, true, "the Safe mode option On is picked up by itself within a second")
Q.step(30, function()
    if S.safeSkip then return end
    Q.check(H.bothShut() and H.vanillaInv() and H.hotbar() == "vanilla" and H.note() == nil, "Safe mode On: the game's own pages, no trip note")
end)
H.optionPoll(1, false, "the Safe mode option Off is picked up by itself within a second")
Q.step(30, function()
    if S.safeSkip then return end
    Q.check(not Sf.on() and H.hotbar() == "replaced" and not H.vanillaInv(), "Safe mode Off: ZeD back")
    S.burstN, S.tBurst = 0, nil
end)
-- the watchdog: a burst of five frames (the first with 100 faults, counted once) leaves ZeD on, 2.5 s later still
Q.waitFor(5, 60, function()
    if S.safeSkip then return true end
    if not S.tBurst then
        S.tBurst = getTimestampMs()
        for i = 1, 100 do Sf.fault("rt_sys burst", "burst " .. i) end
    else
        Sf.fault("rt_sys burst", "burst frame " .. S.burstN)
    end
    S.burstN = S.burstN + 1
    return S.burstN >= 5
end, function() end)
Q.waitFor(1, 2000, function()
    if S.safeSkip then return true end
    return Sf.on() or getTimestampMs() - S.tBurst >= 2500
end, function()
    if S.safeSkip then return end
    Q.check(not Sf.on(), "the watchdog: a five-frame burst of faults leaves ZeD on")
    if Sf.on() then H.closeNote(); Sf.reset() end
    S.tStreak, S.streakHits = nil, 0
end)
-- one place failing every frame: no trip before two seconds, a trip by 2.5 s
Q.waitFor(5, 3000, function()
    if S.safeSkip then return true end
    local now = getTimestampMs()
    if not S.tStreak then S.tStreak = now end
    if not Sf.on() then
        Sf.fault("rt_sys streak", "streak " .. S.streakHits)
        S.streakHits = S.streakHits + 1
    end
    if Sf.on() then S.streakMs = getTimestampMs() - S.tStreak; return true end
    return now - S.tStreak > 2500
end, function()
    if S.safeSkip then return end
    local ms = S.streakMs
    Q.check(ms ~= nil and ms >= 1990, "the watchdog: under two seconds of faults ZeD stays on", tostring(ms) .. " ms, " .. S.streakHits .. " frames")
    Q.check(ms ~= nil and ms <= 2500, "the watchdog: two seconds of faults every frame trip it", tostring(ms) .. " ms")
end)
Q.step(30, function()
    if S.safeSkip then return end
    Q.check(H.closeNote(), "the watchdog's note shows and closes")
    Sf.reset()
end)
Q.step(30, function()
    if S.safeSkip then return end
    S.safeOpt:setValue(S.safeWas)
    pcall(Sf.reread)
    -- ZeD keeps the game's pages hidden while it runs; the trip file emptied so the next start shows no note
    pcall(function() local vi = getPlayerInventory(pn); if vi then vi:setVisible(false) end end)
    pcall(function() local vl = getPlayerLoot(pn); if vl then vl:setVisible(false) end end)
    pcall(function() local f = getFileWriter("ZeD_safe_trip.txt", true, false); f:write(""); f:close() end)
    RT.pairOpen()
end)
Q.step(30, function()
    if S.safeSkip then return end
    Q.say("safe mode put back: " .. H.state())
    Q.check(S.safeOpt:getValue() == S.safeWas and not Sf.on() and H.bothOpen() and not H.vanillaInv(), "safe mode put back: the option as it was, ZeD running")
end)

-- ===================================================================== 6. step-aside
Q.step(5, function()
    local SA = ZeD.StepAside
    if not SA then Q.check(false, "ZeD's step-aside is loaded"); return end
    local found = {}
    pcall(function() found = SA.detect() or {} end)
    local any = false
    for sc, f in pairs(found) do
        any = true
        local rec = SA.record() or { set = {}, kept = {} }
        local o = St.screenOptions and St.screenOptions[sc]
        local val = o and o:getValue()
        if rec.kept and rec.kept[sc] == f.id then
            Q.check(val ~= 2, "step-aside: " .. sc .. " taken by " .. tostring(f.name) .. " was taken back by the player and stays ZeD's", "switch " .. tostring(val))
        else
            local s = rec.set and rec.set[sc]
            Q.check(s ~= nil and s.id == f.id, "step-aside: " .. sc .. " is handed back to " .. tostring(f.name) .. " (the record)", tostring(s and s.id))
            Q.check(val == 2 and Sf.on(sc), "step-aside: " .. sc .. "'s switch is the game's own and ZeD stays off it", "switch " .. tostring(val))
            local under = SA.underFor(sc)
            Q.check(under ~= nil and string.find(under, tostring(f.name), 1, true) ~= nil, "step-aside: ZeD setup says " .. sc .. " is taken by " .. tostring(f.name), tostring(under))
        end
    end
    if not any then Q.skip("step-aside", "no active mod replaces a ZeD screen in this game") end
end)

-- ===================================================================== 7. Messages keeps another mod's note
Q.step(5, function()
    local MS, MW = ZeD.Messages, ZeD.MessagesWindow
    if not (MS and MW) then Q.check(false, "ZeD's Messages is loaded"); S.msgSkip = true; return end
    S.SRC = "ZeD QA test mod"
    S.calls = 0
    S.catchWas = St.messagesCatchOption and St.messagesCatchOption:getValue()
    S.toastWas = St.messagesToastOption and St.messagesToastOption:getValue()
    S.toasts0 = {}
    for _, t in ipairs(MS.toasts or {}) do S.toasts0[#S.toasts0 + 1] = t end
    pcall(function() St.messagesCatchOption:setValue(2); St.messagesToastOption:setValue(2) end)
    S.popWas = MS.popupsFor(S.SRC)
    if S.popWas then MS.setPopups(S.SRC, false) end
    MS.qaSource = S.SRC
    S.target = {}
    S.note = ISModalDialog:new(0, 0, 300, 150, "QA: a note from another mod.", false, S.target, function() S.calls = S.calls + 1 end, pn)
    S.note:initialise()
    S.note:addToUIManager()
    MS.qaSource = nil
end)
Q.step(20, function()
    if S.msgSkip then return end
    local MS = ZeD.Messages
    local shown = false
    pcall(function() shown = S.note.javaObject ~= nil and S.note:isReallyVisible() end)
    Q.check(not shown and S.note._zedCaught == true, "another mod's note is kept in Messages, not shown over the game")
    local s = MS.sources[S.SRC]
    Q.check(s ~= nil and #s.items == 1 and not s.items[1].read, "Messages keeps the note, new, under the mod's name", tostring(s and #s.items))
    S.msgWin = ZeD.MessagesWindow.open(pn, S.SRC)
end)
Q.step(20, function()
    if S.msgSkip then return end
    local win = S.msgWin
    Q.check(win ~= nil and win:isReallyVisible() and win.sel == S.SRC, "the Messages window opens on the mod")
    local g = win and win._g
    Q.check(g ~= nil and #g.cards == 1 and #g.btns == 1, "the window shows the note's card with its OK", tostring(g and #g.cards))
    RT.bounds(Q, "the Messages window")
    if g and g.btns[1] then win:pressCard(g.btns[1]) end
end)
Q.step(10, function()
    if S.msgSkip then return end
    Q.check(S.calls == 1, "OK in Messages runs the mod's own callback once", S.calls .. " calls")
end)
Q.step(5, function()
    if S.msgSkip then return end
    local MS = ZeD.Messages
    MS.clear(S.SRC)
    pcall(function() S.msgWin:close() end)
    MS.toasts = S.toasts0
    if S.popWas then MS.setPopups(S.SRC, true) end
    pcall(function()
        if S.catchWas then St.messagesCatchOption:setValue(S.catchWas) end
        if S.toastWas then St.messagesToastOption:setValue(S.toastWas) end
    end)
    Q.check(MS.sources[S.SRC] == nil, "put back: the test mod's messages are cleared")
end)

-- ===================================================================== 8. the soak: two minutes of play
local SOAK_TABS = {
    { c = "loot", w = "loot" }, { c = "equip", w = "craft" }, { c = "health", w = "build" }, { c = "skills", w = "maps" },
    { c = "journal", w = "forage" }, { c = "thermal", w = "loot" },
}
Q.step(10, function()
    RT.pairOpen()
    if getGameSpeed() <= 0 then pcall(setGameSpeed, 1) end
    S.soakErr0 = H.errs()
    S.soakMem0 = H.mem()
    S.soakT0 = getTimestampMs()
    S.soakI = 0
    Q.say(string.format("soak start: %s KB, %s Lua errors so far", tostring(S.soakMem0), tostring(S.soakErr0)))
end)
-- the tabs turn every ten seconds while the game runs
Q.waitFor(5, math.floor(SOAK_MS / 3) + 3000, function()
    local el = getTimestampMs() - S.soakT0
    local want = math.floor(el / 10000)
    if want > S.soakI then
        S.soakI = want
        local t = SOAK_TABS[(want - math.floor(want / #SOAK_TABS) * #SOAK_TABS) + 1]
        RT.pairOpen()
        pcall(RT.charTab, t.c)
        pcall(RT.worldTab, t.w)
    end
    return el >= SOAK_MS
end, function(ok)
    Q.check(ok, "the soak ran its two minutes", math.floor((getTimestampMs() - S.soakT0) / 1000) .. " s")
    pcall(RT.charTab, "loot")
    pcall(RT.worldTab, "loot")
    local e1 = H.errs()
    if S.soakErr0 and e1 then
        Q.check(e1 == S.soakErr0, "the soak: no Lua error in two minutes with the windows open", (e1 - S.soakErr0) .. " new")
    else
        Q.skip("the soak's error count", "the game's Lua error count cannot be read here")
    end
    local m1 = H.mem()
    if S.soakMem0 and m1 then
        Q.check(m1 - S.soakMem0 <= SOAK_KB, string.format("the soak: Lua memory grows by no more than %d KB", SOAK_KB),
            string.format("%d KB -> %d KB (%d KB)", math.floor(S.soakMem0), math.floor(m1), math.floor(m1 - S.soakMem0)))
    else
        Q.skip("the soak's memory", "collectgarbage(\"count\") is not available")
    end
    RT.bounds(Q, "the windows after the soak")
end)

-- ===================================================================== 9. translation
Q.step(5, function()
    S.trOn = false
    -- ZeD's English file: every key in it has text in the game (the file loaded, each key whole)
    local lines = {}
    pcall(function()
        local r = getModFileReader("ZeD_UI", "media/lua/shared/Translate/EN/UI.json", false)
        if not r then return end
        local l = r:readLine()
        while l do lines[#lines + 1] = l; l = r:readLine() end
        r:close()
    end)
    if #lines == 0 then
        Q.skip("UI.json's keys", "ZeD's Translate/EN/UI.json could not be read in game")
    else
        local n, bad = 0, {}
        for _, l in ipairs(lines) do
            local k = l:match('^%s*"(UI_ZeD_[%w_]+)"%s*:')
            if k then
                n = n + 1
                local t = getTextOrNull(k, "%1", "%2", "%3", "%4")
                if t == nil or t == "" then bad[#bad + 1] = k end
            end
        end
        Q.check(n > 0 and #bad == 0, "every key in ZeD's English UI.json has text in the game",
            n .. " keys" .. ((#bad > 0) and (", none for: " .. table.concat(bad, " ", 1, math.min(#bad, 12))) or ""))
    end
end)
Q.step(3, function()
    -- every key ZeD asked for while this script ran
    local defaults = ZeD._trDefaults or {}
    local mine, game, badMine, badGame = 0, 0, {}, {}
    for k in pairs(S.keys) do
        local fam = k:match("^(%a+)_")
        local shaped = fam ~= nil and k:find(" ", 1, true) == nil and k:match("^[%w_]+$") ~= nil
        local isMine = k:sub(1, 7) == "UI_ZeD_"
        local isGame = shaped and not isMine and (fam == "UI" or fam == "IGUI" or fam == "ContextMenu" or fam == "Tooltip" or fam == "Sandbox")
        if isMine or isGame then
            local t = getTextOrNull(k, "%1", "%2", "%3", "%4")
            local has = (t ~= nil and t ~= "") or defaults[k] ~= nil
            if isMine then
                mine = mine + 1
                if not has then badMine[#badMine + 1] = k end
            else
                game = game + 1
                if not has then badGame[#badGame + 1] = k end
            end
        end
    end
    Q.check(mine > 0 and #badMine == 0, "every ZeD key read while the script ran has text",
        mine .. " keys" .. ((#badMine > 0) and (", none for: " .. table.concat(badMine, " ", 1, math.min(#badMine, 12))) or ""))
    Q.check(#badGame == 0, "every game key ZeD borrowed while the script ran has text",
        game .. " keys" .. ((#badGame > 0) and (", none for: " .. table.concat(badGame, " ", 1, math.min(#badGame, 12))) or ""))
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.trOn = false
    if ZeD.tr ~= S.trWas then ZeD.tr = S.trWas end
    -- the settings this script touched, each as it was (a run cut short jumps here)
    pcall(function() if S.abWas and St.actionBarOption:getValue() ~= S.abWas then St.actionBarOption:setValue(S.abWas) end end)
    if S.ini0 and not S.iniBack then H.writeIni(S.ini0) end
    pcall(function()
        if S.scaleWas and S.scaleOpt:getValue() ~= S.scaleWas then S.scaleOpt:setValue(S.scaleWas); St.applyScale(S.scaleWas) end
    end)
    pcall(function()
        if S.base0 and (ZeD.currentBase ~= S.base0 or ZeD.currentAccent ~= S.accent0 or ZeD.currentSize ~= S.size0) then
            ZeD.applyTheme(S.base0, S.accent0, S.size0)
        end
    end)
    pcall(function()
        if S.safeWas and S.safeOpt:getValue() ~= S.safeWas then S.safeOpt:setValue(S.safeWas); Sf.reread() end
        if Sf.on() and S.safeWas ~= 2 then H.closeNote(); Sf.reset() end
    end)
    pcall(function()
        local MS = ZeD.Messages
        MS.qaSource = nil
        if S.SRC and MS.sources[S.SRC] then MS.clear(S.SRC) end
        if S.catchWas then St.messagesCatchOption:setValue(S.catchWas) end
        if S.toastWas then St.messagesToastOption:setValue(S.toastWas) end
    end)
    if S.menuWas == false and H.menuUp() then H.toggleMenu() end
    if getGameSpeed() <= 0 then pcall(setGameSpeed, 1) end
end)
Q.waitFor(10, 900, function()
    local T = ZeD.T
    return Sc._reopenAt == nil and T ~= nil and math.abs((T.root or 0) - Sc.root()) < 0.001
end, function()
    if ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, S.snap, "rt_sys") end
    if S.winsWere == false then RT.pairShut() elseif S.winsWere then RT.pairOpen() end
    Q.check(ZeD.tr == S.trWas, "put back: ZeD.tr is ZeD's own again")
    Q.check((not S.abWas or St.actionBarOption:getValue() == S.abWas) and (not S.scaleWas or S.scaleOpt:getValue() == S.scaleWas)
        and (not S.safeWas or S.safeOpt:getValue() == S.safeWas) and (not S.base0 or ZeD.currentBase == S.base0),
        "put back: every setting this script changed is as it was")
end)
Q.start()
