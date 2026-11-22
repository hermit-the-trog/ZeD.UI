-- ZeDUI/tools/qa/showcase_s4.lua  (Nov 18 2026)
-- MAIN MENU ONLY, pushed through the QA bridge. The 1.0 Workshop description's showcase graphic 4,
-- "Before you play" (workshop/showcase/SHOWCASE_CAPTURES.md, section 4; sc4_server is a separate,
-- in-game run and is not here). Built on gallery_v1_ch8.lua. Takes, in Zomboid/Screenshots (move
-- them to Screenshots/showcase after):
--   sc4_desk            the main menu desk on the default wallpaper (the original painting), no
--                       window open, as gallery_desk_pass.lua stages it
--   sc4_mods            the Mods window: the list in four folders (Quality of life, Getting around,
--                       Medical, Maps folded shut; Unfiled folded shut), the profile "Main run" in use
--                       in the title bar, the two bicycle mods' rows each with a "1 conflict" tag, and
--                       Bicycle! picked (its pane on the right, the Conflicts tab counted)
--   sc4_mods_conflict   the same moment with Bicycle!'s pane on its Conflicts tab: which mod's copy
--                       of the same files the game runs, and why (the close-up)
--   sc4_profiles        the Mod profiles page, "Main run" picked: its pane shows Loading it (one
--                       mod to turn on) and its Load order with the separators' headings (Interface,
--                       Gameplay, Maps), as gallery_v1_ch8.lua's 08b
-- The conflict is real, not staged: Bicycle! (BicycleMod) and Bicycle! - Standalone Weight & Fixes
-- (BicycleB4220MPFixed) both ship 40 of the same Lua files under media/lua/client and shared, with
-- different text, and neither mod.info says it needs or excludes the other, so the game runs both
-- and ZeD's conflict check (ZeD_ModScan) finds them. The later one in the load order wins.
-- The mods: showcase_s4_mods.txt (gallery_v1_ch8_mods.txt plus the two bicycle mods; the runner
-- adds ZeD-GUI). The look: Dark + PZ Teal, small text, the Mods screen's Detailed view, set here
-- through ZeD's options (the runner sets only the 1.75x UI scale); the desk's Debug menu left out
-- of the menu bar; the pointer hidden and parked in the bottom right corner for every shot; the
-- Mods window made tall (as gallery_v4_menus.lua does) so each page shows whole, after the desk shot.
-- Every window's box is logged before each shot ("box ...").
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself), 4K fullscreen:
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/showcase_s4_mods.txt `
--        -Script ZeDUI/tools/qa/showcase_s4.lua -Tag sc4 -TimeoutSec 400
--
-- Puts back: the wallpaper choice (Lua/ZeD_wallpaper.txt, only touched if it was not the painting),
-- ZeD.ModFolders.FILE (the run works on Lua/ZeDQA_Showcase_ModFolders.cfg, never the player's
-- ModFolders.cfg, and empties it after), Lua/ZeD_modfolders.txt if it changed, the profile file
-- ZeD_modprofiles.txt as it was (text), the load order, every mod's on / off (Discard changes, so
-- nothing new is accepted), the test profile deleted, the theme and Mods view options, the desk's
-- menus, the pointer, the screen area. grep "ZEDQA sc4": "ERR ..." lines are failures; DONE last.
local MM = ZeD.MainMenu
local O = ZeD.ModOrder
local F = ZeD.ModFolders
local MS = ZeD.ModScan
local function say(s) print("ZEDQA sc4 " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot(n .. ".png") end) end
local steps, t = {}, 0
local T0 = 0
-- (each step runs n frames after the one before it, as in gallery_v4_menus.lua)
local function at(n, fn) T0 = T0 + n; steps[#steps + 1] = { n = T0, fn = fn } end
-- a wait: the timeline stops until cond() is true or max frames pass (then an ERR line, and on)
local hold, holdMax, holdN, holdWhat = nil, 0, 0, ""
local function waitFor(what, max, cond) at(1, function() hold, holdMax, holdN, holdWhat = cond, max, 0, what end) end
local function W() return MM.root and MM.root.modsWin end
local function model() return ModSelector.instance.model end
local function jlist(l) local r = {}; if l then for i = 0, l:size() - 1 do r[#r + 1] = l:get(i) end end; return r end
local function idx(list, id) for i, x in ipairs(list) do if x == id then return i end end; return nil end

local PROFILE = "Main run"
local TESTF = "ZeDQA_Showcase_ModFolders.cfg"
local UISTATE = "ZeD_modfolders.txt"
-- the two mods that really conflict: LOSER loads first, WINNER after it (its copies run)
local LOSER, WINNER = "BicycleMod", "BicycleB4220MPFixed"
-- the folders, in this order; Maps is folded shut. MediaExpansion, ZeD-GUI and every other installed
-- mod stay in Unfiled (folded shut too)
local FOLDERS = {
    { name = "Quality of life", ids = { "ConeVisionOutline", "ContainerCapacityIndicator", "GasPumpIndicator", "SeedSeasonIndicator",
                                        "HeartHealthMeter", "KAMER_WallHealth", "VisibleDoorDamagebyYurik" } },
    { name = "Getting around", ids = { LOSER, WINNER, "MoreBuilds", "KnoxPacks" } },
    { name = "Medical", ids = { "EnhancedMedical", "EnhancedMedicalChronic", "TheOnlyCurePlus", "WoundExpansion" } },
    { name = "Maps", ids = { "Erikas_Tiles", "Taylorsville", "Maplewood" }, shut = true },
}
-- the separators, in this order, each over its mods in this order (a mod before the mods that need
-- it: Enhanced Medical before its Chronic Conditions, Erikas_Tiles before Taylorsville; the loser
-- before the winner, as they loaded); every other mod on (ZeD-GUI ...) goes in the top
local SEPS = {
    { name = "Interface", ids = FOLDERS[1].ids },
    { name = "Gameplay", ids = { "EnhancedMedical", "EnhancedMedicalChronic", "TheOnlyCurePlus", "WoundExpansion", LOSER, WINNER,
                                 "MoreBuilds", "KnoxPacks", "MediaExpansion" } },
    { name = "Maps", ids = FOLDERS[4].ids },
}
-- turned off after the profile shots of the list, so the profile's pane has a Loading it line ("turns on 1")
local OFFMOD = "MediaExpansion"
-- ZeD's options for the pictures: Dark (1), PZ Teal (6: Settings.lua accentKeys), small text (1),
-- the Mods screen's Detailed view (1: folders, tags and the pane's tabs show only there)
local LOOK = { baseTheme = 1, accentColor = 6, textSize = 1, modsStyle = 1 }

local keep = {}

local function readRaw(name)
    local r = getFileReader(name, false)
    if not r then return nil end
    local lines = {}
    local line = r:readLine()
    while line do lines[#lines + 1] = line; line = r:readLine() end
    r:close()
    return table.concat(lines, "\n") .. "\n"
end
local function writeRaw(name, s)
    local w = getFileWriter(name, true, false)
    if w then w:write(s); w:close() end
end

-- the pointer out of the pictures: parked in the corner (no hover look on any row), then hidden
-- (the park comes first, since a move can show it again)
local function park() pcall(function() Mouse.setXY(getCore():getScreenWidth() - 4, getCore():getScreenHeight() - 4) end) end
local function hide() pcall(function() Mouse.setCursorVisible(false) end) end

-- every window's box in the log (the Mods window, and the monitor's screen area it sits in)
local function boxes(tag)
    local w = W()
    if w and w:isVisible() then
        say(string.format("box %s mods %d,%d %dx%d page=%s", tag, math.floor(w:getX()), math.floor(w:getY()),
            math.floor(w:getWidth()), math.floor(w:getHeight()), tostring(w.page)))
    else
        say("box " .. tag .. " no Mods window")
    end
    local L = MM._layout
    if L then say(string.format("box %s tube %d,%d %dx%d", tag, math.floor(L.tx), math.floor(L.ty), math.floor(L.tw), math.floor(L.th))) end
end

-- a picture: 2 frames to start settling (pointer hidden, boxes logged), 30 more, then the shot
local function picture(name)
    at(2, function() park(); hide(); boxes(name) end)
    at(30, function() hide(); shot(name); say("shot " .. name) end)
end

-- 0. set-up: the look, the desk's menus, the default wallpaper, the desk with nothing open
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    park()
    pcall(function() keep.cursor = Mouse.isCursorVisible() end)
    -- the theme and the Mods view, through the options (so what ZeD draws follows them); the old values kept
    local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
    keep.opts = {}
    if opts then
        for id, v in pairs(LOOK) do
            local o = opts:getOption(id)
            if o then keep.opts[id] = o:getValue(); pcall(function() o:setValue(v) end)
            else say("ERR no option " .. id) end
        end
        pcall(function() ZeD.Settings.reapplyFromOptions() end)
    else
        say("ERR no ZeD options")
    end
    -- the desk's Debug menu (the bridge needs -debug) left out of the menu bar, as gallery_b11_look_menu.lua does
    if MM.menus then
        keep.menus = MM.menus
        MM.menus = function(...)
            local out = {}
            for _, m in ipairs(keep.menus(...)) do if m.key ~= "debug" then out[#out + 1] = m end end
            return out
        end
    end
    -- the default wallpaper, the original painting (the old choice put back at the end)
    keep.wall = MM.desktop()
    if keep.wall ~= "painting" then MM.setDesktop("painting") end
    MM.ctx.open = nil
    MM.showView("main")
    say("look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize)
        .. "; wallpaper was " .. tostring(keep.wall) .. "; view " .. tostring(MM.view))
end)

-- 1. sc4_desk: the desk, settled a few seconds (gallery_desk_pass.lua waits 240 frames)
at(240, function() MM.ctx.open = nil; park(); hide() end)
picture("sc4_desk")

-- 2. the folders file, the folders, the tall screen area, the Mods window
at(5, function()
    keep.ffile = F.FILE
    keep.ui = readRaw(UISTATE)
    keep.raw = readRaw("ZeD_modprofiles.txt")
    F.FILE = TESTF
    writeRaw(TESTF, "")
    F.load()
    keep.fid = {}
    for i, f in ipairs(FOLDERS) do
        local ok, fid = F.create(f.name)
        if ok and fid then
            keep.fid[i] = fid
            F.assign(f.ids, fid)
            if f.shut then F.setOpen(fid, false) end
        else
            say("ERR folder not made: " .. f.name)
        end
    end
    -- (every installed Workshop mod not in a folder lands in Unfiled, hundreds of rows on this
    -- machine; it is folded shut for the shots. Its open/shut state file (UISTATE) is put back at the end.)
    pcall(F.setUnfiledOpen, false)
    say("folders " .. #F.folders() .. " in " .. tostring(F.FILE) .. "; Unfiled open " .. tostring(F.unfiledOpen()))
    -- tall windows: the monitor's screen area stretched to the bottom of the display (gallery_v4_menus.lua);
    -- MM._layout is dropped at the end and rebuilt as it was
    local L = MM.layout()
    L.th = getCore():getScreenHeight() - L.ty - math.floor(L.s * 4)
    MM.ctx.open = nil
    MM.openMods()
end)

-- 3. the list checked, then the conflict check left to finish (it runs while the list is up)
at(60, function()
    local w = W()
    local m = model()
    -- the load order and what is on as the window opened, to put back
    keep.order0 = jlist(m:getActiveMods():getMods())
    local all, on = w:counts()
    say(string.format("mods all %d on %d; simple view %s; folders on %s", all, on, tostring(w:simple()), tostring(w:foldersOn())))
    for _, f in ipairs(FOLDERS) do
        for _, id in ipairs(f.ids) do
            if not m.mods[id] then say("ERR not installed: " .. id)
            elseif not m.mods[id].isActive then say("ERR not on: " .. id) end
        end
    end
    w.filter = "all"
    w.find:setText("")
    w.scroll, w.dscroll = 0, 0
    w:dirty()
end)
waitFor("the conflict check", 900, function() return MS.res and MS.res.done end)
at(5, function()
    say(string.format("conflicts: %s %d, %s %d (loaded %s %s)", LOSER, MS.count(LOSER), WINNER, MS.count(WINNER),
        tostring(MS.isLoaded(LOSER)), tostring(MS.isLoaded(WINNER))))
    if MS.count(LOSER) == 0 then say("ERR no conflict found on " .. LOSER) end
    for _, e in ipairs(MS.forMod(LOSER)) do say("conflict " .. tostring(e.kind) .. " " .. tostring(e.loser) .. " > " .. tostring(e.winner) .. ": " .. #e.things) end
end)

-- 4. the separators made on the Load order page and kept with Done (the list's own layout), then the
-- profile saved from it, so the title bar shows it in use
at(10, function()
    local w = W()
    w:enterOrder("order")
    local inSep = {}
    local seps = {}
    for _, s in ipairs(SEPS) do
        local ids = {}
        for _, id in ipairs(s.ids) do
            if idx(w.order, id) and (w.oZone[id] or 2) == 2 then ids[#ids + 1] = id; inSep[id] = true end
        end
        seps[#seps + 1] = { uid = O.newUid(), name = s.name, on = true, open = true, ids = ids }
    end
    -- (any separators or top the list had go for the run; ZeD_modprofiles.txt comes back as text at the end)
    local top = {}
    for _, id in ipairs(w.order) do if (w.oZone[id] or 2) == 2 and not inSep[id] then top[#top + 1] = id end end
    w:orderSnap()
    w.oLo.seps, w.oLo.top = seps, top
    w:orderLayout(false)
    local res = w:orderCheck()
    say("order " .. table.concat(w.order, ";") .. " | red " .. tostring(res.nBad))
    -- Done (refuses while a row is red: then kept anyway, so the run goes on, and logged)
    w:orderDone()
    if w.page == "order" then say("ERR Done refused (a red row); kept anyway"); w:leaveOrder(true) end
    say("list separators " .. #O.getLo(O.listKey(model())).seps)
end)
at(10, function()
    local w = W()
    if not w:nameFree(PROFILE) then say("ERR a profile named " .. PROFILE .. " is already there: not touched, sc4_profiles skipped"); keep.noProfile = true; return end
    w:writeProfile(PROFILE)
    keep.madeProfile = true
    local e = O.entry(PROFILE)
    say("profile " .. PROFILE .. " saved: " .. #(e and e.order or {}) .. " mods, " .. #(e and e.seps or {}) .. " separators")
    w:dirty()
end)

-- 5. sc4_mods: the list in folders, the loser's row picked, its pane on About (the tabs show Conflicts 1)
at(10, function()
    local w = W()
    if w.page ~= "list" then say("ERR on page " .. tostring(w.page) .. ", not the list") end
    w.filter = "all"
    w.find:setText("")
    w.scroll, w.dscroll = 0, 0
    w.fsel = nil
    w.sel = LOSER
    w.dtab = "about"
    w.focusId = "mrow:" .. LOSER
    w:dirty()
    say("in use " .. tostring(w:profileInUse()))
    if w:profileInUse() ~= PROFILE then say("ERR the title bar does not show " .. PROFILE .. " in use") end
end)
picture("sc4_mods")

-- 6. sc4_mods_conflict: the same, its pane on the Conflicts tab
at(5, function()
    local w = W()
    w.sel = LOSER
    w.dtab = "conflicts"
    w.dscroll = 0
end)
picture("sc4_mods_conflict")

-- 7. sc4_profiles: one mod off (so loading the profile would turn it on), the Mod profiles page,
-- Main run picked
at(10, function()
    local w = W()
    if keep.noProfile then return end
    local m = model()
    w.dtab = "about"
    w.sel = nil
    if m.mods[OFFMOD] and m.mods[OFFMOD].isActive then
        m:forceActivateMods(m.mods[OFFMOD].modInfo, false)
        keep.offed = true
        w:dirty()
    end
    w:enterProfiles()
    w.psel = PROFILE
    w._profOrd = nil
    w.scroll, w.dscroll = 0, 0
    for i, p in ipairs(w:profiles()) do if p.name == PROFILE then w.focusId = "prow:" .. i end end
    local d = w:profileDiff({ name = PROFILE })
    say(string.format("profile pane: %d mods, turns on %d, off %d, missing %d", d.count, #d.on, #d.off, #d.missing))
end)
picture("sc4_profiles")

-- 8. put everything back
at(10, function()
    local w = W()
    local m = model()
    if keep.offed and m.mods[OFFMOD] and not m.mods[OFFMOD].isActive then m:forceActivateMods(m.mods[OFFMOD].modInfo, true); w:dirty() end
    if w.page == "order" or w.page == "maps" then w:leaveOrder(false) end
    if w.page == "profiles" then w:leaveProfiles() end
    if keep.order0 then w:saveOrder(keep.order0) end
    if keep.madeProfile and m.presets[PROFILE] then w.psel = PROFILE; w:deletePreset() end
    if keep.raw ~= nil or keep.ffile then writeRaw("ZeD_modprofiles.txt", keep.raw or "") end
    O.load()
    if keep.ffile then
        F.FILE = keep.ffile
        writeRaw(TESTF, "")
        if readRaw(UISTATE) ~= keep.ui then writeRaw(UISTATE, keep.ui or "unfiledOpen=1\n") end
        F.load()
    end
    -- the theme and Mods view options as they were, applied and saved
    local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
    if opts and keep.opts then
        for id, v in pairs(keep.opts) do
            local o = opts:getOption(id)
            if o then pcall(function() o:setValue(v) end) end
        end
        pcall(function() ZeD.Settings.reapplyFromOptions() end)
        pcall(function() PZAPI.ModOptions:save() end)
    end
    if keep.menus then MM.menus = keep.menus end
    if keep.wall and keep.wall ~= MM.desktop() then MM.setDesktop(keep.wall) end
    pcall(function() Mouse.setCursorVisible(keep.cursor ~= false) end)
    MM._layout = nil
    w.sel, w.fsel, w.focusId = nil, nil, nil
    w:discard()
end)
at(25, function()
    say("view " .. tostring(MM.view) .. "; folders file " .. tostring(F.FILE) .. "; look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent)
        .. "; wallpaper " .. tostring(MM.desktop()))
    say("DONE")
end)

local function tick()
    if hold then
        holdN = holdN + 1
        local ok, r = pcall(hold)
        if ok and r then
            say("waited " .. holdN .. " frames for " .. holdWhat)
            hold = nil
        elseif holdN >= holdMax then
            say("ERR waited " .. holdN .. " frames for " .. holdWhat .. ", going on")
            hold = nil
        else
            return
        end
    end
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > T0 + 5 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
