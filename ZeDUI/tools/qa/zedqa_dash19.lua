-- ZeD QA (S125 polish pass): every dashboard design live, one vehicle at a time beside the player.
-- spawn, repair, fuel, battery, key, enter, key in, start, radio + heater + headlights (+ lightbar, no siren),
-- game screenshot (Zomboid/Screenshots/zqa_dash_<tag>.png), print the dashboard's screen rect, leave, remove.
local p = getPlayer(); local D = ZeD.Dashboard
local LIST = {
    { "01_luxury", "Base.CarLuxury" }, { "02_nyala", "Base.CarNormal" }, { "03_cossette", "Base.SportsCar" },
    { "04_police", "Base.CarLightsPolice" }, { "05_d6", "Base.PickUpTruck" }, { "06_dashelite", "Base.ModernCar" },
    { "07_primani", "Base.ModernCar02" }, { "08_dart", "Base.SmallCar" }, { "09_horizon", "Base.SmallCar02" },
    { "10_wagon", "Base.CarStationWagon" }, { "11_suv", "Base.SUV" }, { "12_van", "Base.Van" },
    { "13_bulldriver", "Base.PickUpVan" }, { "14_rancher", "Base.OffRoad" }, { "15_taxi", "Base.CarTaxi" },
    { "16_ambulance", "Base.VanAmbulance" }, { "17_fire", "Base.PickUpTruckLightsFire" }, { "18_ranger", "Base.CarLightsRanger" },
    { "19_race", "Base.RaceCar12" },
}
local function say(s) print("ZEDQA dash " .. tostring(s)) end
if getGameSpeed() == 0 then setGameSpeed(1) end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local cur, curKey = nil, nil
local function leave()
    local v = p:getVehicle(); if v then v:exit(p); triggerEvent("OnExitVehicle", p) end
    if cur then pcall(function() cur:permanentlyRemove() end) end
    if curKey then pcall(function() p:getInventory():Remove(curKey) end) end
    cur, curKey = nil, nil
end
local t = 10
at(t, leave)
t = t + 20
for _, e in ipairs(LIST) do
    local tag, script = e[1], e[2]
    at(t, function()
        local sq = getCell():getGridSquare(math.floor(p:getX()) + 5, math.floor(p:getY()) + 2, math.floor(p:getZ()))
        local v = sq and addVehicleDebug(script, IsoDirections.N, nil, sq) or nil
        if not v then say(tag .. " spawn failed " .. script); return end
        cur = v
        pcall(function() v:repair() end)
        pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
        pcall(function()
            local b = v:getPartById("Battery"); local it = b and b:getInventoryItem()
            if it then pcall(function() it:setCurrentUsesFloat(1.0) end); pcall(function() it:setUsedDelta(1.0) end) end
        end)
        pcall(function() curKey = p:getInventory():AddItem(v:createVehicleKey()) end)
        v:enter(0, p); triggerEvent("OnEnterVehicle", p)
    end)
    at(t + 20, function() if cur then pcall(function() cur:setKeysInIgnition(true) end) end end)
    at(t + 35, function()
        if not cur then return end
        pcall(function() ISVehicleMenu.onStartEngine(p) end)
        local d = D.getInstance(); if not (d and d._st) then say(tag .. " no dashboard"); return end
        if not d._st.radioOn then d:_fire("pwr", false) end
        if not d._st.heaterOn then d:_fire("heat", false) end
        if not d._st.lights then d:_fire("lights", false) end
        local lb = false; pcall(function() lb = cur:hasLightbar() end)
        if lb then d:_fire("lbar", false) end
    end)
    at(t + 260, function()
        local d = D.getInstance()
        pcall(function() getCore():TakeFullScreenshot("zqa_dash_" .. tag .. ".png") end)
        local x, y, w, h = -1, -1, -1, -1
        pcall(function() x, y, w, h = d:getAbsoluteX(), d:getAbsoluteY(), d:getWidth(), d:getHeight() end)
        local run = false; pcall(function() run = cur:isEngineRunning() end)
        say(string.format("%s design=%s rect=%d,%d,%d,%d running=%s radio=%s heat=%s lights=%s badge=%s/%s screen=%dx%d",
            tag, tostring(d and d._designId), x, y, w, h, tostring(run), tostring(d and d._st and d._st.radioOn),
            tostring(d and d._st and d._st.heaterOn), tostring(d and d._st and d._st.lights),
            tostring(d and d._badgeLabel), tostring(d and d._badgeSub), getCore():getScreenWidth(), getCore():getScreenHeight()))
    end)
    at(t + 285, leave)
    t = t + 305
end
at(t, function() say("DONE") end)
local n, i = 0, 1
local function tick()
    n = n + 1
    while steps[i] and steps[i].n <= n do
        local ok, err = pcall(steps[i].f); if not ok then say("step error: " .. tostring(err)) end
        i = i + 1
    end
    if not steps[i] then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick)
