-- ZeDUI/tools/qa/gallery_v1_ch8.lua  (Nov 18 2026)
-- MAIN MENU ONLY, pushed through the QA bridge. The 1.0 Workshop gallery's chapter 8 retake
-- (workshop/gallery/v1_plan/ADD_ch8_folders_separators.md; director, Nov 18: "Profiles and load
-- order doesn't show folders"). Takes, in Zomboid/Screenshots (move them to
-- Screenshots/gallery_v1_wip after):
--   zed_08a_mods_folders           the Mods window, the list in four folders (headings with their
--                                  counts and on / off boxes), Maps folded shut, the rest open
--   zed_08b_profiles               the Mod profiles page, "Gallery run" picked: its pane shows
--                                  Loading it (one mod to turn on) and its Load order with the
--                                  separators' headings
--   zed_08c_load_order_separators  the Load order page with three separators (Interface, Gameplay,
--                                  Maps); Enhanced Medical - Chronic Conditions moved above Enhanced
--                                  Medical, which it needs, ON THE PAGE ONLY, so its row is red and
--                                  Done waits
--   zed_08d_seps_from_folders      the same page just after Start separators from folders ran
-- The mods: gallery_v1_ch8_mods.txt (17 Workshop mods; the runner adds ZeD-GUI).
-- The look: Dark + PZ Teal, small text, set here through ZeD's options (the runner sets only the
-- 1.75x UI scale); the desk's Debug menu left out of the menu bar; the pointer hidden and parked in
-- the bottom right corner for every shot; windows made tall (as gallery_v4_menus.lua does) so each
-- page shows whole. Every window's box is logged before each shot ("box ...").
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself), 4K fullscreen:
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/gallery_v1_ch8_mods.txt `
--        -Script ZeDUI/tools/qa/gallery_v1_ch8.lua -Tag g18 -TimeoutSec 300
--
-- Puts back: ZeD.ModFolders.FILE (the run works on Lua/ZeDQA_Gallery_ModFolders.cfg, never the
-- player's ModFolders.cfg, and empties it after), Lua/ZeD_modfolders.txt if it changed, the profile
-- file ZeD_modprofiles.txt as it was (text), the load order, every mod's on / off (Discard changes,
-- vanilla's NO, so nothing new is accepted), the test profile deleted, the theme options, the desk's
-- menus, the pointer, the screen area. grep "ZEDQA g18": "ERR ..." lines are failures; DONE last.
local MM = ZeD.MainMenu
local O = ZeD.ModOrder
local F = ZeD.ModFolders
local function say(s) print("ZEDQA g18 " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot(n .. ".png") end) end
local steps, t = {}, 0
local T0 = 0
-- (each step runs n frames after the one before it, as in gallery_v4_menus.lua)
local function at(n, fn) T0 = T0 + n; steps[#steps + 1] = { n = T0, fn = fn } end
local function W() return MM.root and MM.root.modsWin end
local function model() return ModSelector.instance.model end
local function jlist(l) local r = {}; if l then for i = 0, l:size() - 1 do r[#r + 1] = l:get(i) end end; return r end
local function idx(list, id) for i, x in ipairs(list) do if x == id then return i end end; return nil end

local PROFILE = "Gallery run"
local TESTF = "ZeDQA_Gallery_ModFolders.cfg"
local UISTATE = "ZeD_modfolders.txt"
-- the folders, in this order; Maps is folded shut. MediaExpansion, ZeD-GUI and every other installed
-- mod stay in Unfiled
local FOLDERS = {
    { name = "Quality of life", ids = { "ConeVisionOutline", "ContainerCapacityIndicator", "GasPumpIndicator", "SeedSeasonIndicator",
                                        "HeartHealthMeter", "KAMER_WallHealth", "VisibleDoorDamagebyYurik" } },
    { name = "Medical", ids = { "EnhancedMedical", "EnhancedMedicalChronic", "TheOnlyCurePlus", "WoundExpansion" } },
    { name = "Crafting", ids = { "MoreBuilds", "KnoxPacks" } },
    { name = "Maps", ids = { "Erikas_Tiles", "Taylorsville", "Maplewood" }, shut = true },
}
-- the separators, in this order, each over its mods in this order (a mod before the mods that need
-- it: Enhanced Medical before its Chronic Conditions, Erikas_Tiles before Taylorsville); every other
-- mod on (ZeD-GUI ...) goes in the top, above the first separator
local SEPS = {
    { name = "Interface", ids = FOLDERS[1].ids },
    { name = "Gameplay", ids = { "EnhancedMedical", "EnhancedMedicalChronic", "TheOnlyCurePlus", "WoundExpansion", "MoreBuilds", "KnoxPacks", "MediaExpansion" } },
    { name = "Maps", ids = FOLDERS[4].ids },
}
-- the pair broken on the page only for 08c: NEEDER needs NEEDED (EnhancedMedicalChronic's mod.info
-- require=EnhancedMedical)
local NEEDER, NEEDED = "EnhancedMedicalChronic", "EnhancedMedical"
-- turned off after the profile is saved, so the profile's pane has a Loading it line ("turns on 1")
local OFFMOD = "MediaExpansion"
-- ZeD's theme options for the pictures: Dark (1), PZ Teal (6: Settings.lua accentKeys), small text (1)
local LOOK = { baseTheme = 1, accentColor = 6, textSize = 1 }

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
-- (gallery_b19_b.lua's way; the park comes first, since a move can show it again)
local function park() pcall(function() Mouse.setXY(getCore():getScreenWidth() - 4, getCore():getScreenHeight() - 4) end) end
local function hide() pcall(function() Mouse.setCursorVisible(false) end) end

-- every window's box in the log (the Mods window, and the monitor's screen area it sits in)
local function boxes(tag)
    local w = W()
    if w then
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

-- 0. set-up: the look, the folders file, the folders, the screen area, the Mods window
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    park()
    pcall(function() keep.cursor = Mouse.isCursorVisible() end)
    -- the theme, through the options (so what ZeD draws follows them); the old values kept
    local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
    keep.opts = {}
    if opts then
        for id, v in pairs(LOOK) do
            local o = opts:getOption(id)
            if o then keep.opts[id] = o:getValue(); pcall(function() o:setValue(v) end) end
        end
        pcall(function() ZeD.Settings.reapplyFromOptions() end)
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
    if MM.ctx and MM.ctx.open == "debug" then MM.ctx.open = nil end
    -- the run's own folders file, empty, so the player's ModFolders.cfg is never read or written
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
    -- (QA, Nov 18 2026: every installed Workshop mod not in a folder lands in Unfiled, hundreds of rows on this
    -- machine; it is folded shut for the shots. Its open/shut state file (UISTATE) is put back at the end.)
    pcall(F.setUnfiledOpen, false)
    say("folders " .. #F.folders() .. " in " .. tostring(F.FILE) .. "; Unfiled open " .. tostring(F.unfiledOpen()))
    -- tall windows: the monitor's screen area stretched to the bottom of the display (gallery_v4_menus.lua);
    -- MM._layout is dropped at the end and rebuilt as it was
    local L = MM.layout()
    L.th = getCore():getScreenHeight() - L.ty - math.floor(L.s * 4)
    say("look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize))
    MM.ctx.open = nil
    MM.openMods()
end)

-- 1. zed_08a: the list in folders, the Quality of life folder picked (its pane on the right)
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
    w.sel = nil
    w.fsel = keep.fid[1]
    w.focusId = keep.fid[1] and ("frow:" .. keep.fid[1]) or nil
    w:dirty()
end)
picture("zed_08a_mods_folders")

-- 2. the separators made on the Load order page and kept with Done (the list's own layout), then the
-- profile saved from it
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
    if not w:nameFree(PROFILE) then say("ERR a profile named " .. PROFILE .. " is already there: not touched, 08b skipped"); keep.noProfile = true; return end
    w:writeProfile(PROFILE)
    keep.madeProfile = true
    local e = O.entry(PROFILE)
    say("profile " .. PROFILE .. " saved: " .. #(e and e.order or {}) .. " mods, " .. #(e and e.seps or {}) .. " separators")
    -- one mod off now, so loading the profile would turn it on (the pane's Loading it line)
    local m = model()
    if m.mods[OFFMOD] and m.mods[OFFMOD].isActive then
        m:forceActivateMods(m.mods[OFFMOD].modInfo, false)
        keep.offed = true
        w:dirty()
    end
end)

-- 3. zed_08b: the Mod profiles page, Gallery run picked
at(10, function()
    local w = W()
    if keep.noProfile then return end
    w:enterProfiles()
    w.psel = PROFILE
    w._profOrd = nil
    w.scroll, w.dscroll = 0, 0
    for i, p in ipairs(w:profiles()) do if p.name == PROFILE then w.focusId = "prow:" .. i end end
    local d = w:profileDiff({ name = PROFILE })
    say(string.format("profile pane: %d mods, turns on %d, off %d, missing %d", d.count, #d.on, #d.off, #d.missing))
end)
picture("zed_08b_profiles")

-- 4. zed_08c: back on, the Load order page with the separators; NEEDER moved above NEEDED on the
-- page only (never kept: the page is left with Back)
at(10, function()
    local w = W()
    local m = model()
    if keep.offed then m:forceActivateMods(m.mods[OFFMOD].modInfo, true); w:dirty() end
    if w.page == "profiles" then w:leaveProfiles() end
    w:enterOrder("order")
    local a, b = idx(w.order, NEEDER), idx(w.order, NEEDED)
    if a and b and a > b then
        table.remove(w.order, a)
        table.insert(w.order, b, NEEDER)
        w:orderChanged()
    else
        say("ERR the pair is not on the page in order (" .. tostring(a) .. ", " .. tostring(b) .. ")")
    end
    local i = idx(w.order, NEEDER)
    if i then w:orderSelectAt(i, true) end
    local res = w:orderCheck()
    say(string.format("order page: %d separators, red %d, %s %s", #w.oLo.seps, res.nBad, NEEDER, tostring(i and res.st[i])))
    say("order " .. table.concat(w.order, ";"))
end)
picture("zed_08c_load_order_separators")

-- 5. zed_08d: Start separators from folders (the list has separators: confirmed, as after its question)
at(10, function()
    local w = W()
    w:sepFromFolders(true)
    local names = {}
    for _, sp in ipairs(w.oLo.seps) do names[#names + 1] = sp.name end
    say("from folders: " .. table.concat(names, ", ") .. " | band: " .. tostring(w.note and w.note.text))
end)
picture("zed_08d_seps_from_folders")

-- 6. put everything back
at(10, function()
    local w = W()
    if w.page == "order" or w.page == "maps" then w:leaveOrder(false) end
    if w.page == "profiles" then w:leaveProfiles() end
    local m = model()
    -- MediaExpansion on again if a step failed before it was
    if keep.offed and m.mods[OFFMOD] and not m.mods[OFFMOD].isActive then m:forceActivateMods(m.mods[OFFMOD].modInfo, true) end
    if keep.order0 then w:saveOrder(keep.order0) end
    if keep.madeProfile and m.presets[PROFILE] then w.psel = PROFILE; w:deletePreset() end
    writeRaw("ZeD_modprofiles.txt", keep.raw or "")
    O.load()
    F.FILE = keep.ffile or "ModFolders.cfg"
    writeRaw(TESTF, "")
    if readRaw(UISTATE) ~= keep.ui then writeRaw(UISTATE, keep.ui or "unfiledOpen=1\n") end
    F.load()
    -- the theme options as they were, applied and saved
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
    pcall(function() Mouse.setCursorVisible(keep.cursor ~= false) end)
    MM._layout = nil
    w:discard()
end)
at(25, function()
    say("view " .. tostring(MM.view) .. "; folders file " .. tostring(F.FILE) .. "; look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent))
    say("DONE")
end)

local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > T0 + 5 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
