-- ZeD QA (Oct 21 2026): the dashboards at night (night.py's plates, ZeD_Plate's night light).
-- Per car: spawn beside the player, key, start, radio + heater + headlights; then screenshots
-- (Zomboid/Screenshots/zqa_dashnight_<tag>_<case>.png) at the game's own light (real), forced day, dusk,
-- night with the dash lights on, night with them off. The first car also reads the game's own light at
-- noon (the clock to 13:00) and back at the save's own hour with the headlamps on, then off. Logs the light
-- readings, the nightness in eighths and the plate laid over. Puts back D.qaNight / D.qaLit, the time,
-- the car and its key. grep "ZEDQA dnt".
local p = getPlayer(); local D = ZeD.Dashboard
local LIST = {
    { "wagon", "Base.CarStationWagon" }, { "nyala", "Base.CarNormal" }, { "dashelite", "Base.ModernCar" },
    { "luxury", "Base.CarLuxury" }, { "ambulance", "Base.VanAmbulance" }, { "race", "Base.RaceCar12" },
    { "d6", "Base.PickUpTruck" },
}
local function say(s) print("ZEDQA dnt " .. tostring(s)) end
if getGameSpeed() == 0 then setGameSpeed(1) end
local gt = getGameTime()
local hour0 = gt:getTimeOfDay()
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local cur, curKey = nil, nil
local function leave()
    local v = p:getVehicle(); if v then v:exit(p); triggerEvent("OnExitVehicle", p) end
    if cur then pcall(function() cur:permanentlyRemove() end) end
    if curKey then pcall(function() p:getInventory():Remove(curKey) end) end
    cur, curKey = nil, nil
end
local function shot(tag, case) pcall(function() getCore():TakeFullScreenshot("zqa_dashnight_" .. tag .. "_" .. case .. ".png") end) end
local function report(tag, case)
    local d = D.getInstance()
    local L = d and d._light
    local lux = -1
    pcall(function() lux = D._luxAt(cur, p) end)
    say(string.format("%s %s design=%s lux=%.3f smooth=%.3f n8=%s lit=%s over=%s lights=%s dashLit=%s k=%s hour=%.2f",
        tag, case, tostring(d and d._designId), lux or -1, (d and d._lux) or -1, tostring(L and L.n8), tostring(L and L.lit),
        tostring(L and L.over), tostring(d and d._st and d._st.lights), tostring(d and d._st and d._st.dashLit), tostring(d and d._s),
        gt:getTimeOfDay()))
end
local CASES = { { "real", nil, nil }, { "day", 0, nil }, { "dusk", 0.5, true }, { "night", 1, true }, { "nightoff", 1, false } }
local t = 10
at(t, leave)
t = t + 20
for _, e in ipairs(LIST) do
    local tag, script = e[1], e[2]
    local entered = false
    at(t, function()
        entered = false
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
        pcall(function() v:enter(0, p) end)
        entered = p:getVehicle() ~= nil
        if not entered then say(tag .. " could not enter " .. script); return end
        triggerEvent("OnEnterVehicle", p)
    end)
    at(t + 20, function() if cur and entered then pcall(function() cur:setKeysInIgnition(true) end) end end)
    at(t + 40, function()
        if not cur or not entered then return end
        pcall(function() ISVehicleMenu.onStartEngine(p) end)
        local d = D.getInstance(); if not (d and d._st) then say(tag .. " no dashboard"); return end
        if not d._st.radioOn then d:_fire("pwr", false) end
        if not d._st.heaterOn then d:_fire("heat", false) end
        if not d._st.lights then d:_fire("lights", false) end
    end)
    local tt = t + 200
    for _, c in ipairs(CASES) do
        local case, n, lit = c[1], c[2], c[3]
        at(tt, function() D.qaNight = n; D.qaLit = lit end)
        at(tt + 40, function() if entered then shot(tag, case); report(tag, case) end end)
        tt = tt + 60
    end
    at(tt, function() D.qaNight = nil; D.qaLit = nil end)
    if tag == LIST[1][1] then
        -- the game's own light: noon, then back to the save's hour (headlamps on, then off)
        at(tt + 10, function() pcall(function() gt:setTimeOfDay(13.0) end) end)
        at(tt + 610, function() if entered then shot(tag, "real_noon"); report(tag, "real_noon") end end)
        at(tt + 620, function() pcall(function() gt:setTimeOfDay(hour0) end) end)
        at(tt + 1220, function() if entered then shot(tag, "real_back_on"); report(tag, "real_back_on") end end)
        at(tt + 1230, function() local d = D.getInstance(); if d and d._st and d._st.lights then d:_fire("lights", false) end end)
        at(tt + 1350, function() if entered then shot(tag, "real_back_off"); report(tag, "real_back_off") end end)
        tt = tt + 1360
    end
    at(tt + 20, leave)
    t = tt + 40
end
at(t, function() D.qaNight = nil; D.qaLit = nil; pcall(function() gt:setTimeOfDay(hour0) end); say("DONE") end)
local nT, i = 0, 1
local function tick()
    nT = nT + 1
    while steps[i] and steps[i].n <= nT do
        local ok, err = pcall(steps[i].f); if not ok then say("step error: " .. tostring(err)) end
        i = i + 1
    end
    if not steps[i] then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick)
