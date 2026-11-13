-- ZeDUI/tools/qa/zedqa_scale_even.lua  (Oct 21 2026)
-- In game on the ZeD-QA save, fullscreen 3840x2160: the UI at the in-between
-- scale steps. Sets ZeD's UI scale option to 1.25, 1.5, 1.75 and 2.0 in turn
-- (ZeD.Settings.uiScaleOption index 5..8) and at each step takes
--   zqa_se_<step>_win.png     both windows: Loot lists, an item card open
--   zqa_se_<step>_health.png  the Health tab's body figure
--   zqa_se_<step>_belt.png    the belt with a watch worn (the mini watch)
--   zqa_se_<step>_pop.png     the full watch popped above the belt
--   zqa_se_<step>_dash.png    a pixel dashboard (a Nyala spawned beside the
--                             character, entered, key on; removed after)
-- and prints the geometry the measuring script (tools/qa/scale_even_check.py)
-- crops on: "ZEDQA se <step> geom ...". Everything goes back at the end: the
-- scale option (the director plays at 1.75), the watch place option, the
-- popped watch's spot, the tabs, the windows open or shut, the added items,
-- the car. The option is put back in memory only; ModOptions.ini is written
-- only if the value could not be put back as it was.
-- grep "ZEDQA se".
local TAG = "se"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); return end
local inv = p:getInventory()
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end

-- ---------------------------------------------------------------------------
-- What there was, to put back
-- ---------------------------------------------------------------------------
local scaleOpt = ZeD.Settings.uiScaleOption
local scaleWas = scaleOpt:getValue()
local watchOpt = ZeD.Settings.watchPlaceOption
local watchWas = watchOpt:getValue()
local popWas = p:getModData().ZeD_WatchPop
local wasChar, wasWorld = CWm.isOpen(), WWm.isOpen()
local cw0 = CW() and CW()._activeTab
local ww0 = WW() and WW()._activeTab
local healthExpWas = CW() and CW()._healthFigureExpanded
local added = {}
local watchItem = nil
local car, carKey = nil, nil

local STEPS = { { idx = 5, tag = "x125" }, { idx = 6, tag = "x150" }, { idx = 7, tag = "x175" }, { idx = 8, tag = "x200" } }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function shot(name)
    local ok, e = pcall(function() getCore():TakeFullScreenshot(name .. ".png") end)
    say("shot " .. name .. (ok and "" or (" ERR " .. tostring(e))))
end
local function rect(el)
    if not el then return "nil" end
    local ok, s = pcall(function()
        return string.format("%d,%d,%d,%d", el:getAbsoluteX(), el:getAbsoluteY(), el:getWidth(), el:getHeight())
    end)
    return ok and s or "nil"
end
local function closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
    end
end
local function openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
        CWm.toggleBothPaired(0)
    end
end
local function goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local function charTab(id) local w = CW(); return (w and goTab(w, w._tabStripPanel, id)) and true or false end
local function worldTab(id) local w = WW(); return (w and goTab(w, w._actionTabStrip, id)) and true or false end
local function selectItem(item)
    local w = CW()
    local c = w and w._mainContent
    if not c then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
local function watchBox()
    local hud = ZeD.Belt.getHUD()
    for _, b in ipairs(hud and hud._boxes or {}) do if b.kind == "watch" then return b, hud end end
    return nil, hud
end
local function leaveCar()
    local v = p:getVehicle()
    if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
    if car then pcall(function() car:permanentlyRemove() end) end
    if carKey then pcall(function() inv:Remove(carKey) end) end
    car, carKey = nil, nil
end

local function geomWindows(tag)
    local T = ZeD.T
    local cw, ww = CW(), WW()
    local card = cw and cw._itemCard
    say(string.format("%s geom root=%s scale=%s px1=%d rowH=%d titleBarH=%d art=%s pk=%s char=%s world=%s card=%s screen=%dx%d",
        tag, tostring(ZeD.Scale.root()), tostring(T.scale), T.px(1), T.rowH, T.titleBarH, tostring(T.art),
        tostring(ZeD.Px and ZeD.Px.k(ZeD.Scale.root())), rect(cw), rect(ww), (card and card:isVisible()) and rect(card) or "nil",
        getCore():getScreenWidth(), getCore():getScreenHeight()))
end
-- drawAt keeps its transform in the drawing panel's space: the panel's screen origin is noted on the way
-- through (the class method is wrapped while the script runs and put back at the end)
local origDrawAt = ZeD_BodyFigure.drawAt
ZeD_BodyFigure.drawAt = function(self, panel, ...)
    pcall(function() self._qaAbsX, self._qaAbsY = panel:getAbsoluteX(), panel:getAbsoluteY() end)
    return origDrawAt(self, panel, ...)
end
local function geomHealth(tag)
    local cw = CW()
    local f = cw and cw._healthBodyFigure
    local ax, ay = 0, 0
    pcall(function() ax, ay = cw:getAbsoluteX(), cw:getAbsoluteY() end)
    local absx, absy = "nil", "nil"
    if f and f._qaAbsX and f._drawAtX then absx, absy = tostring(f._qaAbsX + f._drawAtX), tostring(f._qaAbsY + f._drawAtY) end
    say(string.format("%s health fig s=%s x=%s y=%s absx=%s absy=%s winabs=%d,%d tab=%s", tag, tostring(f and f._drawAtS), tostring(f and f._drawAtX),
        tostring(f and f._drawAtY), absx, absy, ax, ay, tostring(cw and cw._activeTab)))
end
local function geomBelt(tag)
    local b, hud = watchBox()
    local hx, hy = 0, 0
    pcall(function() hx, hy = hud:getAbsoluteX(), hud:getAbsoluteY() end)
    local parts = {}
    for _, bx in ipairs(hud and hud._boxes or {}) do
        parts[#parts + 1] = bx.kind .. "@" .. bx.x .. "," .. bx.y .. "," .. bx.w .. "," .. bx.h
    end
    local c = hud and hud._closure
    local bk = hud and hud._buckle
    say(string.format("%s belt hud=%s watch=%s closure=%s buckle=%s boxes=%s", tag, rect(hud),
        b and string.format("%d,%d,%d,%d", hx + b.x, hy + b.y, b.w, b.h) or "nil",
        c and string.format("%s k=%s x=%s y=%s", tostring(c.kind), tostring(c.k), tostring(c.x), tostring(c.y)) or "nil",
        bk and string.format("%d,%d,%d,%d", bk.x, bk.y, bk.w, bk.h) or "nil", table.concat(parts, " ")))
end
local function geomWatch(tag)
    local inst = ZeD.Watch.getInstance()
    local k = nil
    pcall(function() k = ZeD.Px.k(inst:_scale()) end)
    say(string.format("%s watch popped=%s rect=%s k=%s", tag, tostring(inst and inst._popped), rect(inst), tostring(k)))
end

-- ---------------------------------------------------------------------------
-- The sequencer (OnTick: the car needs the game running)
-- ---------------------------------------------------------------------------
local steps = {}
local t = 0
local function at(dt, f) t = t + dt; steps[#steps + 1] = { n = t, f = f } end

at(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("start: scale option=" .. tostring(scaleWas) .. " root=" .. tostring(ZeD.Scale.root()) .. " watch place=" .. tostring(watchWas)
        .. " | windows char " .. tostring(wasChar) .. " world " .. tostring(wasWorld))
    local a = inv:AddItem("Base.Apple"); if a then added[#added + 1] = a end
    -- a watch on the left wrist, shown on the belt (place option 1)
    watchOpt:setValue(1)
    p:getModData().ZeD_WatchPop = nil
    local w = inv:AddItem("Base.WristWatch_Left_DigitalBlack")
    if w then
        local busy = false
        pcall(function() busy = p:getWornItem(w:getBodyLocation()) ~= nil end)
        if busy then say("note: the left wrist is taken; the worn watch shows instead")
        else p:setWornItem(w:getBodyLocation(), w); watchItem = w end
        added[#added + 1] = w
    end
    openPair()
end)

for _, st in ipairs(STEPS) do
    local tag = st.tag
    at(30, function()
        openPair()
        scaleOpt:setValue(st.idx)
        ZeD.Settings.applyScale(st.idx)
        say(tag .. " set option " .. st.idx .. " root=" .. tostring(ZeD.Scale.root()))
    end)
    -- the Scale tick re-applies the theme and closes / reopens open windows (every 30 ticks, reopen 3 later)
    at(100, function()
        openPair()
        charTab("loot"); worldTab("loot")
        if added[1] then selectItem(added[1]) end
    end)
    at(70, function() geomWindows(tag); shot("zqa_se_" .. tag .. "_win") end)
    at(5, function()
        selectItem(nil)
        local cw = CW(); if cw then cw._healthFigureExpanded = true end
        charTab("health")
    end)
    at(50, function() geomHealth(tag); shot("zqa_se_" .. tag .. "_health") end)
    at(5, function() charTab("loot"); closePair() end)
    at(40, function() geomBelt(tag); shot("zqa_se_" .. tag .. "_belt") end)
    at(5, function()
        local b, hud = watchBox()
        if b then hud:onMouseDown(b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2)) else say(tag .. " MISSING the watch box") end
    end)
    at(40, function() geomWatch(tag); shot("zqa_se_" .. tag .. "_pop") end)
    at(5, function()
        local inst = ZeD.Watch.getInstance()
        if inst and inst._popped then
            local b, hud = watchBox()
            if b then hud:onMouseDown(b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2)) end
        end
    end)
    -- the pixel dashboard
    at(20, function()
        local sq = getCell():getGridSquare(math.floor(p:getX()) + 5, math.floor(p:getY()) + 2, math.floor(p:getZ()))
        local v = sq and addVehicleDebug("Base.CarNormal", IsoDirections.N, nil, sq) or nil
        if not v then say(tag .. " MISSING dash: spawn failed"); return end
        car = v
        pcall(function() v:repair() end)
        pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
        pcall(function() carKey = inv:AddItem(v:createVehicleKey()) end)
        local ok = false; pcall(function() ok = v:enter(0, p) end)
        if p:getVehicle() then triggerEvent("OnEnterVehicle", p) else say(tag .. " MISSING dash: could not enter") end
    end)
    at(20, function() if car and p:getVehicle() then pcall(function() car:setKeysInIgnition(true) end) end end)
    at(90, function()
        if not (car and p:getVehicle()) then return end
        local d = ZeD.Dashboard.getInstance()
        say(string.format("%s dash rect=%s k=%s design=%s", tag, rect(d), tostring(d and d._s), tostring(d and d._designId)))
        shot("zqa_se_" .. tag .. "_dash")
    end)
    at(5, leaveCar)
    at(30, function() end)
end

-- ---------------------------------------------------------------------------
-- Put everything back
-- ---------------------------------------------------------------------------
at(5, function()
    ZeD_BodyFigure.drawAt = origDrawAt
    pcall(leaveCar)
    pcall(function() selectItem(nil) end)
    if watchItem then pcall(function() p:removeWornItem(watchItem) end) end
    for _, it in ipairs(added) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    added = {}
    pcall(function() watchOpt:setValue(watchWas) end)
    pcall(function() p:getModData().ZeD_WatchPop = popWas end)
    openPair()
    scaleOpt:setValue(scaleWas)
    ZeD.Settings.applyScale(scaleWas)
end)
at(100, function()
    pcall(function()
        local cw = CW()
        if cw and healthExpWas ~= nil then cw._healthFigureExpanded = healthExpWas end
        if cw0 then charTab(cw0) end
        if ww0 then worldTab(ww0) end
    end)
end)
at(10, function()
    if not wasChar and not wasWorld then closePair()
    elseif not wasChar then if CWm.isOpen() then CWm.toggle(0) end
    elseif not wasWorld then if WWm.isOpen() then WWm.close() end end
    local now = scaleOpt:getValue()
    if now ~= scaleWas then
        scaleOpt:setValue(scaleWas); ZeD.Settings.applyScale(scaleWas)
        pcall(function() PZAPI.ModOptions:save() end)
        say("ERR the scale option did not hold its old value; set and saved again")
    end
    say("restored: scale option=" .. tostring(scaleOpt:getValue()) .. " root=" .. tostring(ZeD.Scale.root())
        .. " watch place=" .. tostring(watchOpt:getValue()) .. " windows char " .. tostring(CWm.isOpen()) .. " world " .. tostring(WWm.isOpen()))
    say("DONE")
end)

local n, i = 0, 1
local function tick()
    n = n + 1
    while steps[i] and steps[i].n <= n do
        local ok, e = pcall(steps[i].f)
        if not ok then say("ERR step " .. i .. " " .. tostring(e)) end
        i = i + 1
    end
    if not steps[i] then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick)
say("armed")
