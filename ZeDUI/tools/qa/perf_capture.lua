-- ZeDUI/tools/qa/perf_capture.lua  (Oct 22 2026)
-- Before / after captures for the drawing-cost work (PERF_2026-10-22.md, "After the fixes").
-- After gallery_v3_core.lua, perf_bench_clean.lua and gallery_v3_stage.lua, with ZeD on.
-- An opaque black backdrop is put behind every UI element (the world under the UI moves
-- between runs: zombies, the character's idle), so two runs of this script give images that
-- differ only where the UI itself differs (and the clock, the needles, the rain).
-- At the UI scales 1.75x, 2x and 1x (in memory; the run's own step put back at the end):
--   hud    windows shut: the belt with the mini watch, moodles
--   pair   both windows, multi-column Loot (Character: inventory + backpack + chest rig, by
--          category; World: ground + trunk + duffel, by name)
--   card   the item card on an apple (single column)
--   map    the World window's Maps tab, Survey
--   dashd  the station wagon by day, engine on, lights on      dashn  the same at night
-- and at 1.75x the pair again in light / blue and hicon / teal (a theme switch), then
-- dark / orange. Shots pc_<scale>_<scene>.png in Zomboid/Screenshots; each shot prints
-- the screen rects of the belt, the windows and the dash. "ZEDQA pcap ... DONE".
local TAG = PERF_CAP_TAG or "pcap"
local PFX = PERF_CAP_PREFIX or "pc"
local G = GAL
if not (G and G.spot and G.car and G.newSeq) then print("ZEDQA " .. TAG .. " ERR run gallery_v3_core/stage first"); print("ZEDQA " .. TAG .. " DONE"); return end
if not (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then print("ZEDQA " .. TAG .. " ERR ZeD is not loaded"); print("ZEDQA " .. TAG .. " DONE"); return end
local S = G.newSeq(TAG, 1500000)
local say = S.say
local p, pn, core = G.p, G.pn, G.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local Opt = ZeD.Settings
local Z = { lock = nil, was = {}, ok = true, why = "" }
Z.was.scale = Opt.uiScaleOption:getValue() or 7
Z.was.watch = Opt.watchPlaceOption:getValue()
Z.was.bar = Opt.actionBarOption:getValue()
function Z.CW() return CWm.getWindow() end
function Z.WW() return WWm.getWindow() end
function Z.closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
    end
end
function Z.place()
    local c, w = Z.CW(), Z.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen()) then return false end
    if w._rolled then return false end
    local L = Z.lock
    if not L then
        local gap = ZeD.T and ZeD.T.px and ZeD.T.px(8) or 16
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        L = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap, cy = math.floor(core:getScreenHeight() * 0.18), wy = math.floor(core:getScreenHeight() * 0.18) }
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
function Z.sort(win, key, asc)
    local c = win and win._mainContent
    if not c then return end
    c._sortCol, c._sortAsc = key, asc
    for _, cs in ipairs(c._colStates or {}) do cs.sortCol, cs.sortAsc = key, asc end
end
function Z.sortSplit() Z.sort(Z.CW(), "cat", true); Z.sort(Z.WW(), "name", true) end
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
function Z.mp() local w = Z.WW(); return w and w._worldMapPanel end
function Z.theme(base, accent)
    ZeD.applyTheme(base, accent, ZeD.currentSize)
    local c, w = Z.CW(), Z.WW()
    if c then c._accentKey = nil end
    if w then w._accentKey = nil end
end

-- the black backdrop behind every UI element
function Z.backdrop(on)
    if on then
        if Z.bd then return end
        local bd = ISPanel:new(0, 0, core:getScreenWidth(), core:getScreenHeight())
        bd.backgroundColor = { r = 0, g = 0, b = 0, a = 1 }
        bd.borderColor = { r = 0, g = 0, b = 0, a = 0 }
        bd:initialise()
        bd:addToUIManager()
        bd:backMost()
        Z.bd = bd
    elseif Z.bd then
        Z.bd:removeFromUIManager()
        Z.bd = nil
    end
end

local function rect(o)
    if not (o and o:isVisible()) then return "-" end
    return string.format("%d,%d,%d,%d", o:getAbsoluteX(), o:getAbsoluteY(), o:getWidth(), o:getHeight())
end
local function shot(name)
    if not Z.ok then S.err(name, Z.why); return end
    S.shot(name)
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance()
    say(string.format("rects %s belt %s char %s world %s dash %s", name, rect(ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD()),
        rect(CWm.isOpen() and Z.CW() or nil), rect(WWm.isOpen() and Z.WW() or nil), rect(dash)))
end
local function setScale(idx)
    S.step(2, function()
        Opt.uiScaleOption:setValue(idx)
        Opt.applyScale()
        Z.lock = nil
    end)
    S.waitMs(2500)
    S.step(2, function()
        say(string.format("scale idx %d root %s T.scale %s art %s", idx, tostring(ZeD.Scale.root()), tostring(ZeD.T.scale), tostring(ZeD.T.art)))
    end)
end

local function carIn()
    S.step(2, function() Z.closePair() end)
    S.step(2, function()
        local v = G.car
        local d = 99
        pcall(function() d = v:DistTo(p) end)
        if d > 12 then Z.ok, Z.why = false, "car " .. d .. " away"; return end
        pcall(function() v:enter(0, p) end)
        Z.entered = p:getVehicle() ~= nil
        if Z.entered then pcall(function() triggerEvent("OnEnterVehicle", p) end) end
        Z.ok = Z.entered
        Z.why = Z.entered and "" or "could not get in"
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
    end)
end
local function carOut()
    S.step(2, function()
        G.dayAgain()
        local v = p:getVehicle()
        if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
        Z.entered = false
        Z.ok, Z.why = true, ""
    end)
    S.step(40, function() G.stand(); G.openTrunk(G.car); G.faceFront() end)
    S.step(30, function() end)
end

local function scaleSet(sc, idx)
    setScale(idx)
    -- hud
    S.step(2, function() Z.closePair(); Z.ok, Z.why = true, "" end)
    S.step(60, function() G.faceFront() end)
    S.step(30, function() shot(PFX .. "_" .. sc .. "_hud") end)
    -- the pair, multi-column
    S.step(2, function() Z.openPair() end)
    S.step(30, function() Z.charTab("loot"); Z.worldTab("loot"); Z.place() end)
    S.poll(10, 600, function() return Z.mc(true) end, function() say("note: the columns did not all come on") end)
    S.step(10, function() Z.sortSplit() end)
    S.step(40, function() Z.sortSplit(); Z.place() end)
    S.step(40, function() shot(PFX .. "_" .. sc .. "_pair") end)
    -- the card
    S.poll(2, 600, function() return Z.mc(false) end)
    S.step(20, function() Z.place() end)
    S.step(2, function()
        local it = Z.found("Base.Apple")
        if not it then Z.ok, Z.why = false, "no apple"; return end
        if not Z.selectItem(it) then Z.ok, Z.why = false, "Loot list not ready" end
    end)
    S.step(60, function() Z.place(); shot(PFX .. "_" .. sc .. "_card") end)
    S.step(2, function() Z.selectItem(nil); Z.ok, Z.why = true, "" end)
    -- the map
    S.poll(2, 120, function() return Z.worldTab("maps") end)
    S.step(10, function()
        local w, m = Z.WW(), Z.mp()
        if not (w and m) then Z.ok, Z.why = false, "no map panel"; return end
        Z.was.mapStyle = Z.was.mapStyle or m.style
        ZeD.MapsTab.setStyle(w, "survey")
        pcall(function() Z.mp().mapAPI:centerOn(p:getX(), p:getY()) end)
        pcall(function() Z.mp():_zoomTo(15) end)
    end)
    S.step(120, function() Z.place(); shot(PFX .. "_" .. sc .. "_map") end)
    S.step(2, function()
        local w = Z.WW()
        if w and Z.was.mapStyle then pcall(ZeD.MapsTab.setStyle, w, Z.was.mapStyle) end
        Z.worldTab("loot")
        Z.ok, Z.why = true, ""
    end)
    -- the dash, day and night
    carIn()
    S.step(120, function() shot(PFX .. "_" .. sc .. "_dashd") end)
    S.step(2, function() if Z.entered then G.night() end end)
    S.step(260, function() shot(PFX .. "_" .. sc .. "_dashn") end)
    carOut()
end

-- ===========================================================================
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook()
    G.day()
    pcall(ZeD.Settings.reapplyFromOptions)
    Z.theme("dark", "orange")
    Opt.watchPlaceOption:setValue(1)
    Opt.actionBarOption:setValue(1)
    G.stand()
    pcall(function() p:getStats():set(CharacterStat.HUNGER, 0.3); p:getStats():set(CharacterStat.THIRST, 0.35) end)
    Z.backdrop(true)
    say("theme " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " size " .. tostring(ZeD.currentSize)
        .. " | scale option " .. tostring(Z.was.scale) .. " | screen " .. core:getScreenWidth() .. "x" .. core:getScreenHeight())
end)
S.zoomTo(1.0)
scaleSet("175", 7)
-- a theme switch at 1.75x: the pair in light / blue, hicon / teal, then dark / orange again
S.step(2, function() Z.openPair() end)
S.step(30, function() Z.charTab("loot"); Z.worldTab("loot"); Z.place() end)
S.poll(10, 600, function() return Z.mc(true) end)
S.step(30, function() Z.sortSplit(); Z.place() end)
for _, t in ipairs({ { "light", "blue" }, { "hicon", "teal" }, { "dark", "orange" } }) do
    S.step(2, function() Z.theme(t[1], t[2]) end)
    S.step(30, function() Z.place() end)
    S.step(20, function() shot(PFX .. "_175_theme_" .. t[1] .. "_" .. t[2]) end)
end
S.poll(2, 600, function() return Z.mc(false) end)
S.step(2, function() Z.closePair() end)
scaleSet("200", 8)
scaleSet("100", 4)
-- back
setScale(Z.was.scale)
S.step(10, function()
    Z.backdrop(false)
    Z.mc(false)
    pcall(function() p:getStats():set(CharacterStat.HUNGER, 0); p:getStats():set(CharacterStat.THIRST, 0) end)
    pcall(ZeD.Settings.reapplyFromOptions)
    Opt.watchPlaceOption:setValue(Z.was.watch)
    Opt.actionBarOption:setValue(Z.was.bar)
    Z.openPair()
    say("back: scale option " .. tostring(Opt.uiScaleOption:getValue()) .. " theme " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent))
end)
S.start()
