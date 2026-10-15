-- ZeDUI/tools/qa/zedqa_seats_build.lua  (Oct 15 2026)
-- The ZeD seat chooser and siren controller (HOOK_MAP row 4) live on the
-- ZeD-QA save: opens them through vanilla's own entry points
-- (ISVehicleMenu.onShowSeatUI, ISVehicleMenu.onLightbar -> the timed action),
-- checks vanilla's windows stay shut, captures each state. Copy to
-- Zomboid/Lua/zedqa.lua and bump zedqa.go; grep console.txt for "ZEDQA sb".
-- Spawned vehicles are removed at the end; the planks go too.

local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA sb " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_sb_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local Seats, Siren = ZeD.Seats, ZeD.Siren
local pickup, police, van
local spawned = {}
local function spawn(script, dx, dy)
    local sq = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, 0)
    local v = sq and addVehicleDebug(script, IsoDirections.N, nil, sq)
    if v then spawned[#spawned + 1] = v end
    return v
end
local function enter(v, seat)
    if not v then say("no vehicle"); return end
    local d = v:DistTo(p)
    say("enter " .. v:getScriptName() .. " dist=" .. string.format("%.1f", d))
    if d > 12 then say("too far, skipped"); return end
    v:enter(seat, p); triggerEvent("OnEnterVehicle", p)
end
local function leave() local v = p:getVehicle(); if v then v:exit(p); triggerEvent("OnExitVehicle", p) end end
local function win() return Seats.get(pn) end
local function report(tag)
    local w = win()
    local vanillaSeat = ISVehicleMenu.seatUI and ISVehicleMenu.seatUI[pn]
    say(string.format("%s zed=%s vis=%s x=%s y=%s w=%s h=%s title=%s seats=%d doors=%d vanillaSeatUI=%s", tag, tostring(w ~= nil),
        tostring(w and w:isReallyVisible()), tostring(w and w.x), tostring(w and w.y), tostring(w and w.width), tostring(w and w.height),
        tostring(w and w.title), w and w._seats and #w._seats or 0, (function() local c = 0; for _ in pairs(w and w._doors or {}) do c = c + 1 end; return c end)(),
        tostring(vanillaSeat and vanillaSeat:isReallyVisible())))
    if w and w._seats then
        local t = {}
        for n, st in ipairs(w._seats) do t[#t + 1] = n .. ":" .. tostring(st.kind) .. (st.off and "/off" or "") .. (st.far and "/far" or "") .. (st.dx and "" or "/noplace") end
        say(tag .. " seats " .. table.concat(t, " "))
    end
end
local function vanillaLightbarOpen()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local ok, t = pcall(function() return ui:get(i):getTable() end)
        if ok and t and t.Type == "ISLightbarUI" then return true end
    end
    return false
end
local function seatItems(v, seat, n)
    local part = v and v:getPartForSeatContainer(seat)
    local c = part and part:getItemContainer()
    if not c then return end
    if n > 0 then for _ = 1, n do c:AddItem("Base.Plank") end else c:removeAllItems() end
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    say("class seats=" .. tostring(ZeD_SeatChooser ~= nil) .. " siren=" .. tostring(ZeD_SirenController ~= nil) .. " hooked=" .. tostring(ISVehicleMenu._zedSeats ~= nil) .. "/" .. tostring(ISLightbarUITimedAction and ISLightbarUITimedAction._zedSiren ~= nil))
end)
-- the nearest of a kind (a run before may have left one parked), else a new one
local function near(pred, maxD)
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if pred(v) then local d = v:DistTo(p); if d < maxD and (not bd or d < bd) then best, bd = v, d end end
    end
    return best
end
at(5, function()
    pickup = near(function(v) return v:getScriptName() == "Base.PickUpTruck" end, 15) or spawn("Base.PickUpTruck", -4, 0)
    police = near(function(v) return v:hasLightbar() end, 15) or spawn("Base.CarLightsPolice", 4, 0)
    van = near(function(v) return v:getScriptName() == "Base.VanSeats" end, 15) or spawn("Base.VanSeats", 0, -5)
    say("spawned " .. tostring(pickup) .. " " .. tostring(police) .. " " .. tostring(van))
end)
-- 1. the pickup: plain, a pointed seat, a pointed door, items on seat 2
at(30, function() enter(pickup, 0) end)
at(80, function() ISVehicleMenu.onShowSeatUI(p, pickup) end)
at(95, function() report("pickup"); shot("01_pickup") end)
at(100, function() Seats.qaPoint = { seat = 2 } end)
at(110, function() shot("02_pickup_point") end)
at(115, function() Seats.qaPoint = { door = 2 } end)
at(125, function() shot("03_pickup_door") end)
at(130, function() Seats.qaPoint = nil; win():close(); seatItems(pickup, 1, 8) end)
at(140, function() ISVehicleMenu.onShowSeatUI(p, pickup); Seats.qaPoint = { seat = 2 } end)
at(155, function() report("pickup items"); shot("04_pickup_items") end)
at(160, function() Seats.qaPoint = nil; win():close(); seatItems(pickup, 1, 0); leave() end)
-- 2. the sheriff car: the caged back, then the lightbar through the wheel's own path
at(190, function() enter(police, 0) end)
at(240, function() ISVehicleMenu.onShowSeatUI(p, police); Seats.qaPoint = { seat = 4 } end)
at(255, function() report("police"); shot("05_police_back") end)
at(260, function() Seats.qaPoint = nil; win():close() end)
at(270, function() ISVehicleMenu.onLightbar(p) end)
at(330, function()
    local s = Siren.get(pn)
    say("lightbar zed=" .. tostring(s ~= nil) .. " vis=" .. tostring(s and s:isReallyVisible()) .. " x=" .. tostring(s and s.x) .. " y=" .. tostring(s and s.y) .. " w=" .. tostring(s and s.width) .. " h=" .. tostring(s and s.height) .. " vanilla=" .. tostring(vanillaLightbarOpen()))
    shot("06_lightbar_off")
end)
at(340, function() local s = Siren.get(pn); if s then s:set("lights", 2); s:set("siren", 1) end end)
at(360, function() Siren.qaPoint = "siren:1"; local v = p:getVehicle(); say("modes lights=" .. v:getLightbarLightsMode() .. " siren=" .. v:getLightbarSirenMode()); shot("07_lightbar_on") end)
at(370, function() Siren.qaPoint = nil; Siren.qaJoy = {}; local s = Siren.get(pn); if s then s.focus = 2 end end)
at(385, function() shot("08_lightbar_pad") end)
at(390, function() local s = Siren.get(pn); if s then s:onJoypadDirDown(); s:onJoypadDirLeft(); s:onJoypadDirUp() end end)
at(400, function() local v = p:getVehicle(); say("pad turned: lights=" .. v:getLightbarLightsMode() .. " siren=" .. v:getLightbarSirenMode() .. " focus=" .. tostring(Siren.get(pn).focus)) end)
at(405, function()
    Siren.qaJoy = nil
    local s = Siren.get(pn); if s then s:set("lights", 0); s:set("siren", 0) end
end)
at(420, function() ISVehicleMenu.onLightbar(p) end)   -- the slice again: puts it away
at(470, function() local s = Siren.get(pn); say("lightbar after second slice vis=" .. tostring(s and s:isReallyVisible())) end)
at(475, function() leave() end)
-- 3. the six-seat van, the controller look on the middle left
at(505, function() enter(van, 0) end)
at(550, function() ISVehicleMenu.onShowSeatUI(p, van); Seats.qaJoy = {}; win().joypadSeat = 3 end)
at(565, function() report("van"); shot("09_van_pad") end)
at(570, function() Seats.qaJoy = nil; win():close(); leave() end)
-- 4. from outside: Enter Vehicle on the van (the nearest)
at(600, function() ISVehicleMenu.onShowSeatUI(p, van) end)
at(615, function() report("outside"); shot("10_outside") end)
at(620, function() if win() then win():close() end end)
at(630, function() say("DONE (vehicles kept for the real-input pass)") end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 650 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
ZeD.QAVehicles = function() return pickup, police, van, spawned end
say("start")
