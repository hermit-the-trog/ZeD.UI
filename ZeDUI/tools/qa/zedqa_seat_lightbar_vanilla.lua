-- ZeDUI/tools/qa/zedqa_seat_lightbar_vanilla.lua  (S125)
-- Before captures for the seat chooser + lightbar mockup: vanilla's
-- ISVehicleSeatUI (pickup, police car, six-seat van) and ISLightbarUI, plus
-- plain backdrops with the ZeD dash, on the open field of the ZeD-QA save. Copy to Zomboid/Lua/zedqa.lua and bump
-- zedqa.go; grep console.txt for "ZEDQA sl". Spawned vehicles are removed.

local p = getPlayer()
local function say(s) print("ZEDQA sl " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_sl_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end

local function near(full, maxD)
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if v:getScript():getFullName() == full then
            local d = v:DistTo(p)
            if d < maxD and (not bd or d < bd) then best, bd = v, d end
        end
    end
    return best
end
local pickup, police, van, seatUI, lbUI
local spawned = {}
local function spawn(script, dx, dy)
    local sq = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
    if not sq then say("no square for " .. script); return nil end
    local v = addVehicleDebug(script, IsoDirections.N, nil, sq)
    if v then spawned[#spawned + 1] = v end
    return v
end
local function enter(v, seat)
    if not v then return end
    say("enter " .. v:getScriptName() .. " dist=" .. string.format("%.1f", v:DistTo(p)) .. " physics=" .. tostring(v:isPhysicsActive()))
    if v:DistTo(p) > 12 then say("too far, skipped"); return end
    v:enter(seat, p); triggerEvent("OnEnterVehicle", p)
end
local function leave()
    local v = p:getVehicle()
    if v then v:exit(p); triggerEvent("OnExitVehicle", p) end
end
local function openSeats(v)
    ISVehicleMenu.onShowSeatUI(p, v)
    seatUI = ISVehicleMenu.seatUI and ISVehicleMenu.seatUI[p:getPlayerNum()]
    if seatUI then say(string.format("seatUI x=%d y=%d w=%d h=%d seats=%d", seatUI:getX(), seatUI:getY(), seatUI:getWidth(), seatUI:getHeight(), v:getMaxPassengers())) end
end
-- vanilla's own pointed state: the joypad path draws the seat name, the reason and the A glyph
local function point(seat) if seatUI then seatUI.joyfocus = seatUI.joyfocus or {}; seatUI.joypadSeat = seat end end
local function closeSeats() if seatUI then seatUI.joyfocus = nil; seatUI:removeFromUIManager() end end
local function seatItems(v, seat, n)
    local part = v and v:getPartForSeatContainer(seat)
    local c = part and part:getItemContainer()
    if not c then return end
    if n > 0 then for _ = 1, n do c:AddItem("Base.Plank") end else c:removeAllItems() end
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
end)
at(5, function()
    pickup = near("Base.PickUpTruck", 20) or spawn("Base.PickUpTruck", -4, 0)
    police = spawn("Base.CarLightsPolice", 4, 0)
    van = spawn("Base.VanSeats", 0, -5)
    say("pickup=" .. tostring(pickup) .. " police=" .. tostring(police) .. " van=" .. tostring(van))
end)
-- 1. the pickup: plain backdrop, the chooser, a pointed empty seat, a seat with planks
at(30, function() enter(pickup, 0) end)
at(80, function() shot("bg_pickup") end)
at(90, function() openSeats(pickup) end)
at(110, function() shot("v01_pickup") end)
at(115, function() point(2) end)
at(125, function() shot("v02_pickup_point") end)
at(130, function() closeSeats(); seatItems(pickup, 1, 8) end)
at(140, function() openSeats(pickup); point(2) end)
at(155, function() shot("v03_pickup_items") end)
at(160, function() closeSeats(); seatItems(pickup, 1, 0); leave() end)
-- 2. the police car: chooser, then the lightbar window, then lights + yelp, then backdrop
at(190, function() enter(police, 0) end)
at(240, function() shot("bg_police") end)
at(245, function() openSeats(police) end)
at(265, function() shot("v04_police") end)
at(270, function() point(4) end)
at(280, function() shot("v05_police_point") end)
at(285, function() closeSeats() end)
at(295, function()
    lbUI = ISLightbarUI:new(0, 0, 430, 280, p); lbUI:initialise(); lbUI:addToUIManager()
    say(string.format("lightbar x=%d y=%d w=%d h=%d", lbUI:getX(), lbUI:getY(), lbUI:getWidth(), lbUI:getHeight()))
end)
at(315, function() shot("v06_lightbar") end)
at(320, function()
    sendClientCommand(p, "vehicle", "setLightbarLightsMode", { mode = 2 })
    sendClientCommand(p, "vehicle", "setLightbarSirenMode", { mode = 1 })
end)
at(345, function() shot("v07_lightbar_on") end)
at(350, function()
    sendClientCommand(p, "vehicle", "setLightbarLightsMode", { mode = 0 })
    sendClientCommand(p, "vehicle", "setLightbarSirenMode", { mode = 0 })
    if lbUI then lbUI:removeFromUIManager() end
end)
at(360, function() leave() end)
-- 3. the six-seat van, from the driver's seat
at(390, function() enter(van, 0) end)
at(435, function() openSeats(van); point(5) end)
at(455, function() shot("v08_van_point") end)
at(460, function() closeSeats(); leave() end)
-- 4. from outside (Enter Vehicle): the pickup
at(490, function() openSeats(pickup) end)
at(505, function() shot("v09_outside") end)
at(510, function() closeSeats() end)
at(520, function()
    for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 540 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
