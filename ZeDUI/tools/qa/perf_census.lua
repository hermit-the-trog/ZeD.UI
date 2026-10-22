-- ZeDUI/tools/qa/perf_census.lua  (Oct 22 2026)
-- Draw-call census for the drawing-cost work (PERF_2026-10-22.md, "After the fixes").
-- After gallery_v3_core.lua, perf_bench_clean.lua and gallery_v3_stage.lua, with ZeD on.
-- Wraps the ISUIElement draw calls (drawRect, drawRectBorder, drawText*, drawTexture*,
-- setStencilRect) and ZeD.TM's measures with counters, then for each scene (hud: windows
-- shut; pair: both windows, multi-column Loot; card: item card on an apple; map: Maps
-- tab; car: the dash at night) counts 240 frames and prints the calls per frame by the
-- drawing element's class. Everything is unwrapped at the end. Counts only: the numbers
-- are exact and do not depend on the clock. "ZEDQA pcen ... DONE".
local TAG = PERF_CEN_TAG or "pcen"
local G = GAL
if not (G and G.spot and G.car and G.newSeq) then print("ZEDQA " .. TAG .. " ERR run gallery_v3_core/stage first"); print("ZEDQA " .. TAG .. " DONE"); return end
local S = G.newSeq(TAG, 900000)
local say = S.say
local p, core = G.p, G.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local C = { on = false, frames = 0, n = {}, ms = {}, wrappers = {} }
local FRAMES = 240

local function owner(o)
    if type(o) ~= "table" then return "?" end
    return tostring(o.Type or "?") .. (o._zedLabel and ("/" .. tostring(o._zedLabel)) or "")
end
local WR = {}
local function wrapEl(name, cls)
    cls = cls or ISUIElement
    local orig = rawget(cls, name)
    if type(orig) ~= "function" or C.wrappers[orig] then return end   -- (a class listed under two names: once)
    WR[#WR + 1] = { t = cls, k = name, f = orig }
    local wrapper
    wrapper = function(self, ...)
        if C.on then
            local k = owner(self) .. " " .. name .. (C.ctx and (" <" .. C.ctx .. ">") or "")
            C.n[k] = (C.n[k] or 0) + 1
        end
        return orig(self, ...)
    end
    C.wrappers[wrapper] = true
    cls[name] = wrapper
end
-- the pixel parts (the dash and the other plates): which part drew the rect
local function wrapPx(name)
    local Px = ZeD.Px
    local orig = Px and rawget(Px, name)
    if type(orig) ~= "function" then return end
    WR[#WR + 1] = { t = Px, k = name, f = orig }
    Px[name] = function(...)
        if C.ctx then return orig(...) end
        C.ctx = "Px." .. name
        local a, b, c = orig(...)
        C.ctx = nil
        return a, b, c
    end
end
local function wrapTM(name)
    local TM = ZeD.TM
    local orig = rawget(TM, name)
    if type(orig) ~= "function" then return end
    WR[#WR + 1] = { t = TM, k = name, f = orig }
    TM[name] = function(self, ...)
        if C.on then
            local k = "TM " .. name
            C.n[k] = (C.n[k] or 0) + 1
        end
        return orig(self, ...)
    end
end
local function frame() if C.on then C.frames = C.frames + 1 end end
local function report(scene)
    local rows, tot = {}, 0
    local f = math.max(C.frames, 1)
    for k, v in pairs(C.n) do
        rows[#rows + 1] = { k = k, v = v / f }
        if not k:find("^TM ") then tot = tot + v / f end
    end
    table.sort(rows, function(a, b) return a.v > b.v end)
    say(string.format("CEN|%s|frames=%d|draw calls per frame=%.1f", scene, C.frames, tot))
    for i = 1, math.min(#rows, 60) do say(string.format("CEN|%s|%.1f|%s", scene, rows[i].v, rows[i].k)) end
end

-- ---------------------------------------------------------------------------
local Z = {}
function Z.CW() return CWm.getWindow() end
function Z.WW() return WWm.getWindow() end
function Z.closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
    end
end
function Z.openPair() if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end end
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
function Z.mc(on)
    local c, w = Z.CW(), Z.WW()
    if not (c and w) then return false end
    if on then Z.charTab("loot"); Z.worldTab("loot") end
    local cl, wl = {}, {}
    for _, k in ipairs({ "back", "webbing" }) do
        local b = G.bags and G.bags[k]
        if b then cl[#cl + 1] = b:getInventory() end
    end
    if G.trunk then wl[#wl + 1] = G.trunk end
    if G.duffel then wl[#wl + 1] = G.duffel:getInventory() end
    local done = true
    for _, inv in ipairs(cl) do if Z.colOn(c, inv) ~= on then CWm.toggleColumn(inv); done = false end end
    for _, inv in ipairs(wl) do if Z.colOn(w, inv) ~= on then WWm.toggleColumn(inv); done = false end end
    return done
end
function Z.found(ft)
    local items = G.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft then return it end
    end
    return nil
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
local function count(scene)
    S.step(60, function() C.n, C.frames = {}, 0; C.on = true end)
    S.step(FRAMES, function() C.on = false; report(scene) end)
end

S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook(); G.day(); G.stand()
    for _, n in ipairs({ "drawRect", "drawRectBorder", "drawText", "drawTextRight", "drawTextCentre", "drawTextZoomed",
                         "drawTexture", "drawTextureScaled", "drawTextureScaledAspect", "drawTextureScaledUniform",
                         "drawTextureTiled", "drawTextureTiledX", "drawTextureTiledY", "setStencilRect", "drawLine2" }) do wrapEl(n) end
    -- the ZeD classes' own lean draw calls (Overrides/TextScale.lua), counted the same way
    for _, cn in ipairs({ "ZeD_Panel", "ZeD_Window", "ZeD_Button", "ZeD_TextInput", "ZeD_TextEntry", "ZeD_SearchField", "ZeD_Tooltip",
                          "ZeD_ScrollList", "ZeD_ScrollPanel", "ZeD_ZoneList", "ZeD_Dropdown", "ZeD_Modal", "ZeD_TabPanel", "ZeD_ItemGrid",
                          "ZeD_ItemCard", "ZeD_BodyFigure", "ZeD_ContextMenu", "ZeD_ContextList", "ZeD_Dashboard", "ZeD_Watch",
                          "ZeD_ObjectCard", "ZeD_FurnitureChip", "ZeD_MMBar", "ZeD_MMDrop", "ZeD_MMIcons" }) do
        local cls = _G[cn]
        if type(cls) == "table" then
            for _, n in ipairs({ "drawRect", "drawRectBorder", "drawText", "drawTextureScaled", "drawTextureScaledAspect" }) do wrapEl(n, cls) end
        end
    end
    for _, n in ipairs({ "MeasureStringX", "getFontHeight" }) do wrapTM(n) end
    for _, n in ipairs({ "text", "rects", "rect", "needle", "pointer", "digits", "ring", "image", "imageTint" }) do wrapPx(n) end
    Events.OnRenderTick.Add(frame)
    say("wrapped " .. #WR)
    Z.closePair()
end)
count("hud")
S.step(2, function() Z.openPair() end)
S.step(30, function() Z.charTab("loot"); Z.worldTab("loot") end)
S.poll(10, 600, function() return Z.mc(true) end)
count("pair")
S.poll(2, 600, function() return Z.mc(false) end)
S.step(20, function() local it = Z.found("Base.Apple"); if it then Z.selectItem(it) end end)
count("card")
S.step(2, function() Z.selectItem(nil) end)
S.poll(2, 120, function() return Z.worldTab("maps") end)
S.step(10, function()
    local w = Z.WW()
    local m = w and w._worldMapPanel
    if m then pcall(function() ZeD.MapsTab.setStyle(w, "survey"); m.mapAPI:centerOn(p:getX(), p:getY()); m:_zoomTo(15) end) end
end)
count("map")
S.step(2, function() Z.worldTab("loot"); Z.closePair() end)
S.step(2, function()
    local v = G.car
    pcall(function() v:enter(0, p) end)
    if p:getVehicle() then pcall(function() triggerEvent("OnEnterVehicle", p) end) end
end)
S.step(30, function() pcall(function() G.car:setKeysInIgnition(true) end) end)
S.poll(10, 1500, function()
    local run = false
    pcall(function() run = G.car:isEngineRunning() end)
    if run or not p:getVehicle() then return true end
    if S.tick % 150 == 0 then pcall(function() ISVehicleMenu.onStartEngine(p) end) end
    return false
end)
S.step(60, function()
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if d and d._st and not d._st.lights then d:_fire("lights", false) end
    G.night()
end)
S.step(120, function() end)
count("car")
S.step(2, function()
    G.dayAgain()
    local v = p:getVehicle()
    if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
end)
S.step(40, function()
    G.stand(); G.openTrunk(G.car); G.faceFront()
    for i = #WR, 1, -1 do local w = WR[i]; w.t[w.k] = w.f end
    Events.OnRenderTick.Remove(frame)
    say("unwrapped")
end)
S.start()
