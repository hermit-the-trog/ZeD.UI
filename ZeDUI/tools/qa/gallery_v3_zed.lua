-- ZeDUI/tools/qa/gallery_v3_zed.lua  (Oct 21 2026)
-- Workshop gallery v3, the ZeD scenes: after gallery_v3_core.lua (+ gallery_v3_reveal.lua)
-- and gallery_v3_stage.lua, with ZeD on. Full 4K screenshots in Zomboid/Screenshots,
-- named zed_<nn>_<scene>.png and theme_<base>_<accent>.png. Set GAL_ONLY above this
-- header to take only some sections, e.g. GAL_ONLY = { hero = true, themes = true }:
--   hero      both windows, multi-column Loot in both (Character: inventory + backpack +
--             chest rig; World: ground + trunk + duffel), zoom 1.0 / 0.5 / 1.75   (01-03)
--   tabs      Equip doll, Health exercise, Skills, Crafting, Maps x3, curtain rolled,
--             item cards (food, weapon), context menu strip and list               (10-21)
--   hud       windows shut, zoom 0.5, two zombies near: belt + watch, watch popped,
--             action bar while reading                                            (30-32)
--   car       the station wagon: dash by day, by night                             (40-41)
--   settings  pause menu Options: ZeD setup page, Interface page                   (45-46)
--   themes    the pair, same place and tab, bases dark / light / hicon x 6 accents
-- The theme is high contrast + PZ Teal (ZeD.applyTheme, in memory only; the options
-- are re-applied at the end). Puts back what it changes; the scene stays for the next
-- script (gallery_v3_teardown.lua). "ZEDQA g3z ..." ending "ZEDQA g3z DONE".
local G = GAL
if not (G and G.spot and G.car and G.newSeq) then print("ZEDQA g3z ERR run gallery_v3_core.lua and gallery_v3_stage.lua first"); print("ZEDQA g3z DONE"); return end
if not (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then print("ZEDQA g3z ERR ZeD is not loaded"); print("ZEDQA g3z DONE"); return end
if ZeD.trTestOn and ZeD.trTestOn() then print("ZEDQA g3z ERR the test language is on"); print("ZEDQA g3z DONE"); return end
local ONLY = GAL_ONLY
local function want(k) return (not ONLY) or ONLY[k] end
local S = G.newSeq("g3z", 900000)
local say = S.say
local p, pn, core = G.p, G.pn, G.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local Opt = ZeD.Settings
local Z = { lock = nil, sc = { ok = true, why = "" }, was = {} }
Z.was.ctx = Opt.contextStyleOption:getValue()
Z.was.watch = Opt.watchPlaceOption:getValue()
Z.was.bar = Opt.actionBarOption:getValue()
Z.was.equip = ZeD.EquipDoll.view()
function Z.CW() return CWm.getWindow() end
function Z.WW() return WWm.getWindow() end

-- ---------------------------------------------------------------------------
-- windows
-- ---------------------------------------------------------------------------
function Z.closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
    end
end
-- placed once (centred, a small gap), then held: Character right edge, World left edge, tops
function Z.place()
    local c, w = Z.CW(), Z.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen()) then return false end
    if w._rolled then return false end
    local L = Z.lock
    if not L then
        local gap = ZeD.T and ZeD.T.px and ZeD.T.px(8) or 16
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        L = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap, cy = c:getY(), wy = w:getY() }
        Z.lock = L
    end
    c._anchorRightEdge = L.right
    c:setX(L.right - c:getWidth())
    w:setX(L.left)
    c:setY(L.cy)
    w:setY(L.wy)
    return true
end
function Z.openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
    Z.place()
end
function Z.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function Z.charTab(id) local w = Z.CW(); return (w and Z.goTab(w, w._tabStripPanel, id)) and true or false end
function Z.worldTab(id) local w = Z.WW(); return (w and Z.goTab(w, w._actionTabStrip, id)) and true or false end
-- is a container's column showing in a window's multi-column view
function Z.colOn(win, inv)
    if not (win and inv) then return false end
    for i, c in ipairs(win._containers or {}) do
        if c.inventory == inv then
            for _, j in ipairs(win._mcSelected or {}) do if j == i then return true end end
            return false
        end
    end
    return false
end
function Z.mcList()
    local cl, wl = {}, {}
    for _, k in ipairs({ "back", "webbing" }) do
        local b = G.bags and G.bags[k]
        if b then cl[#cl + 1] = b:getInventory() end
    end
    if G.trunk then wl[#wl + 1] = G.trunk end
    if G.duffel then wl[#wl + 1] = G.duffel:getInventory() end
    return cl, wl
end
-- columns on (true) or off (false); true when every column is as wanted
function Z.mc(on)
    local c, w = Z.CW(), Z.WW()
    if not (c and w) then return false end
    if on then Z.charTab("loot"); Z.worldTab("loot") end
    local cl, wl = Z.mcList()
    local done = true
    for _, inv in ipairs(cl) do
        if Z.colOn(c, inv) ~= on then CWm.toggleColumn(inv); done = false end
    end
    for _, inv in ipairs(wl) do
        if Z.colOn(w, inv) ~= on then WWm.toggleColumn(inv); done = false end
    end
    return done
end
function Z.selectItem(item)
    local w = Z.CW()
    local c = w and w._mainContent
    if not c then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
function Z.found(ft)
    local items = G.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft then return it end
    end
    return nil
end
function Z.recipe(kind, open)
    local w = Z.WW()
    if not w then return false, "no World window" end
    local mod = (kind == "craft") and ZeD.CraftingTab or ZeD.BuildingTab
    local st = (kind == "craft") and w._craftState or w._buildState
    if not st then return false, "no " .. kind .. " state" end
    if not open then ZeD.CraftingCore.closeCraft(st); return true end
    local data = mod.gatherData(p, w)
    local pick = nil
    for _, rd in ipairs(data and data.recipes or {}) do
        if rd.status == "unlocked" then pick = rd; break end
    end
    pick = pick or (data and data.recipes and data.recipes[1])
    if not pick then return false, "no recipe" end
    ZeD.CraftingCore.openCraft(st, pick.entry.name)
    say("recipe open: " .. tostring(pick.entry.name))
    return true
end
function Z.mp() local w = Z.WW(); return w and w._worldMapPanel end
function Z.zm() local v = getPlayerContextMenu(pn); return v and v._zedMenu end
function Z.theme(base, accent)
    ZeD.applyTheme(base, accent, ZeD.currentSize)
    local c, w = Z.CW(), Z.WW()
    if c then c._accentKey = nil end
    if w then w._accentKey = nil end
end

-- a scene: setup (may return false, why), settle, shot
function Z.setup(fn)
    pcall(Z.place)
    G.faceFront()
    Z.sc.ok, Z.sc.why = true, ""
    if not fn then return end
    local ok, a, b = pcall(fn)
    if not ok then Z.sc.ok, Z.sc.why = false, tostring(a)
    elseif a == false then Z.sc.ok, Z.sc.why = false, tostring(b or "setup refused") end
end
function Z.finish(name) if Z.sc.ok then S.shot(name) else S.err(name, Z.sc.why) end end
function Z.Sc(name, settle, fn)
    S.step(2, function() Z.setup(fn) end)
    S.step(settle or 30, function() Z.finish(name) end)
end
function Z.T(name, which, tab, settle, fn)
    S.step(2, function() Z.sc.ok, Z.sc.why = true, "" end)
    S.poll(2, 120, function()
        if which == "c" then return Z.charTab(tab) end
        return Z.worldTab(tab)
    end, function() Z.sc.ok = false; Z.sc.why = "no tab " .. tab end)
    S.step(6, function() if Z.sc.ok then Z.setup(fn) end end)
    S.step(settle or 30, function() Z.finish(name) end)
end

-- ===========================================================================
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook()
    G.day()
    pcall(ZeD.Settings.reapplyFromOptions)
    if ZeD.currentBase ~= "hicon" or ZeD.currentAccent ~= "teal" then Z.theme("hicon", "teal") end
    say("theme " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " size " .. tostring(ZeD.currentSize)
        .. " | scale " .. tostring(ZeD.Scale and ZeD.Scale.current and ZeD.Scale.current()))
    Opt.watchPlaceOption:setValue(1)
    Opt.contextStyleOption:setValue(1)
    Opt.actionBarOption:setValue(1)
    G.tp(G.spot.px + 0.5, G.spot.py + 0.5, 0)
    Z.openPair()
end)
S.step(40, function() Z.charTab("loot"); Z.worldTab("loot"); Z.place() end)

-- ---- hero --------------------------------------------------------------------
if want("hero") then
    S.poll(10, 600, function() return Z.mc(true) end, function() say("note: the columns did not all come on") end)
    S.step(40, function()
        local c, w = Z.CW(), Z.WW()
        say(string.format("columns: char %d world %d | char %dx%d at %d,%d | world %dx%d at %d,%d",
            #(c._mcSelected or {}), #(w._mcSelected or {}), c:getWidth(), c:getHeight(), c:getX(), c:getY(),
            w:getWidth(), w:getHeight(), w:getX(), w:getY()))
        Z.place()
    end)
    S.zoomTo(1.0)
    Z.Sc("zed_01_hero_mid", 40)
    S.zoomTo(0.5)
    Z.Sc("zed_02_hero_close", 40)
    S.zoomTo(1.75)
    Z.Sc("zed_03_hero_wide", 40)
    S.step(2, function() Z.mc(false) end)
    S.step(20, function() Z.mc(false) end)
end
S.zoomTo(1.0)

-- ---- tabs --------------------------------------------------------------------
if want("tabs") then
    Z.T("zed_10_equip_doll", "c", "equip", 55, function() ZeD.EquipDoll.setView("doll") end)
    S.step(2, function() ZeD.EquipDoll.setView(Z.was.equip) end)
    Z.T("zed_11_health_exercise", "c", "health", 45, function()
        local w = Z.CW()
        if not (ZeD.HealthTab and ZeD.HealthTab.exerciseInfo and ZeD.HealthTab.exerciseInfo(p, "pushups")) then return false, "no exercise info" end
        Z.was.exSel = w._healthExerciseSel
        w._healthFigureExpanded = true
        pcall(function() w._healthScroll:setScrollPos(0) end)
        w._healthExerciseSel = "pushups"
    end)
    S.step(2, function() local w = Z.CW(); if w then w._healthExerciseSel = Z.was.exSel end end)
    Z.T("zed_12_skills", "c", "skills", 40)
    S.step(2, function() Z.charTab("loot") end)
    Z.T("zed_13_crafting", "w", "craft", 60, function() return Z.recipe("craft", true) end)
    S.step(2, function() Z.recipe("craft", false) end)
    local function mapStyle(style)
        return function()
            local w, m = Z.WW(), Z.mp()
            if not (w and m) then return false, "no map panel" end
            Z.was.mapStyle = Z.was.mapStyle or m.style
            ZeD.MapsTab.setStyle(w, style)
            if style == "paper" and Z.mp().style ~= "paper" then return false, "no paper style here" end
            pcall(function() Z.mp().mapAPI:centerOn(p:getX(), p:getY()) end)
            pcall(function() Z.mp():_zoomTo(15) end)
        end
    end
    Z.T("zed_14_maps_survey", "w", "maps", 90, mapStyle("survey"))
    Z.Sc("zed_15_maps_color", 90, mapStyle("color"))
    Z.Sc("zed_16_maps_paper", 90, mapStyle("paper"))
    S.step(2, function()
        local w = Z.WW()
        if w and Z.was.mapStyle then ZeD.MapsTab.setStyle(w, Z.was.mapStyle) end
    end)
    -- the curtain: the World window's loot side rolled up (on the Maps tab, as v13)
    Z.Sc("zed_17_curtain_rolled", 100, function()
        local w = Z.WW()
        if not w then return false, "no World window" end
        local r = w._rollBtn
        if r then w:onMouseDown(r.x + 2, r.y + 2) else ZeD.Curtain.roll(w) end
        if not w._rolled then return false, "did not roll" end
    end)
    S.step(2, function() local w = Z.WW(); if w and w._rolled then ZeD.Curtain.unroll(w) end end)
    S.step(100, function()
        local w = Z.WW()
        if w and w._rolled then ZeD.Curtain.unroll(w) end
        say("curtain back: rolled " .. tostring(w and w._rolled))
        Z.worldTab("loot"); Z.charTab("loot")
    end)
    S.step(40, function() Z.place() end)
    Z.Sc("zed_18_card_food", 40, function()
        local it = Z.found("Base.Apple")
        if not it then return false, "no apple" end
        if not Z.selectItem(it) then return false, "Loot list not ready" end
    end)
    Z.Sc("zed_19_card_weapon", 40, function()
        local it = Z.found("Base.Machete")
        if not it then return false, "no machete" end
        if not Z.selectItem(it) then return false, "Loot list not ready" end
    end)
    S.step(2, function() Z.selectItem(nil) end)
    local function menu(style)
        return function()
            Opt.contextStyleOption:setValue(style)
            local food = Z.found("Base.Apple")
            if not food then return false, "no apple" end
            local w = Z.CW()
            ISInventoryPaneContextMenu.createMenu(pn, true, { food }, w:getX() + math.floor(w:getWidth() * 0.42), w:getY() + math.floor(w:getHeight() * 0.30))
        end
    end
    S.step(20, function() end)
    Z.Sc("zed_20_ctx_strip", 30, menu(1))
    S.step(2, function() local m = Z.zm(); if m then m:close() end end)
    Z.Sc("zed_21_ctx_list", 30, menu(2))
    S.step(2, function() local m = Z.zm(); if m then m:close() end; Opt.contextStyleOption:setValue(Z.was.ctx) end)
    S.step(15, function() end)
end

-- ---- hud ---------------------------------------------------------------------
if want("hud") then
    S.step(2, function() Z.closePair() end)
    S.zoomTo(0.5)
    S.step(2, function()
        G.nearZombies(true)
        pcall(function() p:getStats():set(CharacterStat.HUNGER, 0.3); p:getStats():set(CharacterStat.THIRST, 0.35) end)
        p:getModData().ZeD_WatchPop = nil
    end)
    S.step(90, function() G.faceFront() end)
    Z.Sc("zed_30_hud_belt_watch", 30, function()
        if not ZeD.Watch.beltWatch(p) then return false, "no watch on the belt" end
    end)
    Z.Sc("zed_31_hud_watch_popped", 40, function()
        ZeD.Watch.togglePop(true)
        local inst = ZeD.Watch.getInstance()
        if inst then inst._popTouched = getTimestampMs() end
    end)
    S.step(2, function() pcall(function() ZeD.Watch.togglePop(false) end) end)
    S.step(30, function() end)
    Z.Sc("zed_32_action_bar_reading", 90, function()
        local book = Z.found("Base.Book")
        if not book then return false, "no book" end
        local ok = pcall(function() ISInventoryPaneContextMenu.readItem(book, pn) end)
        if not ok then ISTimedActionQueue.add(ISReadABook:new(p, book, 150)) end
    end)
    S.step(2, function()
        pcall(function() ISTimedActionQueue.clear(p) end)
        G.nearZombies(false)
        pcall(function() p:getStats():set(CharacterStat.HUNGER, 0); p:getStats():set(CharacterStat.THIRST, 0) end)
    end)
    S.step(30, function() end)
end

-- ---- car ---------------------------------------------------------------------
if want("car") then
    S.step(2, function() Z.closePair() end)
    S.zoomTo(1.0)
    S.step(2, function()
        local v = G.car
        local d = 99
        pcall(function() d = v:DistTo(p) end)
        if d > 12 then Z.sc.ok, Z.sc.why = false, "car " .. d .. " away"; return end
        pcall(function() v:enter(0, p) end)
        Z.entered = p:getVehicle() ~= nil
        if Z.entered then pcall(function() triggerEvent("OnEnterVehicle", p) end) end
        Z.sc.ok = Z.entered
        Z.sc.why = Z.entered and "" or "could not get in"
    end)
    S.step(30, function() if Z.entered then pcall(function() G.car:setKeysInIgnition(true) end) end end)
    local ES = { tries = 0, last = -9999 }
    S.poll(10, 1500, function()
        if not Z.entered then return true end
        local run = false
        pcall(function() run = G.car:isEngineRunning() end)
        if run then return true end
        local q = ISTimedActionQueue.getTimedActionQueue(p)
        local busy = q and q.queue and #q.queue > 0
        if not busy and S.tick - ES.last > 120 and ES.tries < 5 then
            ES.tries = ES.tries + 1; ES.last = S.tick
            pcall(function() ISVehicleMenu.onStartEngine(p) end)
        end
        return false
    end, function() say("note: the engine did not start") end)
    S.step(60, function()
        local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
        if not (Z.entered and d and d._st) then return end
        if not d._st.lights then d:_fire("lights", false) end
        if not d._st.radioOn then d:_fire("pwr", false) end
    end)
    S.step(120, function() if Z.entered then S.shot("zed_40_dash_day") else S.err("zed_40_dash_day", Z.sc.why) end end)
    S.step(2, function() if Z.entered then G.night() end end)
    S.step(260, function() if Z.entered then S.shot("zed_41_dash_night") end end)
    S.step(2, function()
        G.dayAgain()
        local v = p:getVehicle()
        if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
        Z.entered = false
    end)
    S.step(40, function() G.tp(G.spot.px + 0.5, G.spot.py + 0.5, 0); G.openTrunk(G.car); G.faceFront() end)
    S.step(30, function() end)
end

-- ---- settings ----------------------------------------------------------------
if want("settings") then
    local MM = ZeD.MainMenu
    S.step(2, function()
        Z.sc.ok, Z.sc.why = true, ""
        Z.pauseW0 = MM.pause and MM.pause.page
        ToggleEscapeMenu(Keyboard.KEY_ESCAPE)
    end)
    S.step(45, function()
        local ms = MainScreen.instance
        if ms and ms:isVisible() then MM.openOptions() else Z.sc.ok = false; Z.sc.why = "no pause menu" end
    end)
    local function page(raw, moot)
        return function()
            if not Z.sc.ok then return end
            local w = MM.pauseOpts
            if not (w and w:isVisible()) then Z.sc.ok = false; Z.sc.why = "no Options window"; return end
            local idx = nil
            for i, pg in ipairs(w:pages()) do if pg.raw == raw then idx = i end end
            if not idx then Z.sc.ok = false; Z.sc.why = "no page " .. raw; return end
            w.pageIdx = idx; w.scroll = 0; w.focusId = nil; w._cellRow = nil
            if moot then for _, r in ipairs(w:rowsFor(w:pages()[idx])) do if r.moot then w._cellRow = r; break end end end
        end
    end
    S.step(45, page("zed"))
    S.step(40, function() Z.finish("zed_45_settings_zed") end)
    S.step(2, page("interface", true))
    S.step(40, function() Z.finish("zed_46_settings_interface") end)
    S.step(2, function()
        local w = MM.pauseOpts
        if w then w._cellRow = nil end
        if w and w:isVisible() then w:back() end
    end)
    S.step(25, function()
        local ms = MainScreen.instance
        if ms and ms:isVisible() and MM.pause then MM.pause.page = Z.pauseW0; MM.pause.focusId = nil end
    end)
    S.step(5, function()
        local ms = MainScreen.instance
        if ms and ms:isVisible() then MM.pauseView = "pause"; ToggleEscapeMenu(Keyboard.KEY_ESCAPE) end
    end)
    S.step(40, function() if getGameSpeed() <= 0 then setGameSpeed(1) end end)
end

-- ---- themes ------------------------------------------------------------------
if want("themes") then
    S.step(2, function() Z.openPair() end)
    S.zoomTo(1.0)
    S.poll(10, 600, function() return Z.mc(true) end)
    S.step(30, function() Z.place() end)
    for _, base in ipairs({ "dark", "light", "hicon" }) do
        for _, acc in ipairs({ "orange", "teal", "blue", "green", "purple", "red" }) do
            S.step(2, function() Z.theme(base, acc) end)
            S.step(10, function() Z.place() end)
            S.step(25, function() S.shot("theme_" .. base .. "_" .. acc) end)
        end
    end
    S.step(2, function() Z.mc(false) end)
end

-- ---- back ---------------------------------------------------------------------
S.step(10, function()
    Z.mc(false)
    pcall(ZeD.Settings.reapplyFromOptions)
    Opt.contextStyleOption:setValue(Z.was.ctx)
    Opt.watchPlaceOption:setValue(Z.was.watch)
    Opt.actionBarOption:setValue(Z.was.bar)
    ZeD.EquipDoll.setView(Z.was.equip)
    Z.openPair()
    say("theme back: " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent))
end)
S.start()
