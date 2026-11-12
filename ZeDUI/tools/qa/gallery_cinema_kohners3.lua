-- ZeDUI/tools/qa/gallery_cinema_kohners3.lua  (Nov 11 2026, QA; the gallery plan v2, shot 5): Kohners driving at dusk,
-- before the breakdown: the white sedan (the Chevalier Nyala of gallery_cinema_kohners.lua, whole and fuelled) on an open
-- country road, the engine on, the headlights on, the car radio on and tuned and up close (the vehicle wheel's Device
-- Options, ISVehicleMenu.onSignalDevice), both windows closed. The car is driven: W held through the real-mouse helper
-- (release_check_mouse.ps1 "keydown"), the picture taken on the move, then W let go and the car stopped.
-- Dark + Pink. Run on her shot save: cinema_run2.ps1 -Manifest cinema_kohners3.txt -ShotSave ZeD-Shots-Kohners
-- cin_koh_dusk.png. grep "ZEDQA ckoh3".
local C = CIN
local S = C.seq("ckoh3")
local p = getPlayer()
local pn = p:getPlayerNum()
local RO, CR = ZeD.RadioOps, ZeD.CarRadio
local SPOTS = { { 8800, 10800 }, { 9500, 11600 }, { 10300, 12000 }, { 11200, 8800 }, { 7600, 9600 }, { 12000, 6800 } }
local road, car, dir = nil, nil, "E"
local function roadRun(x, y, dx, dy)
    local cell, n = getCell(), 0
    for k = 1, 40 do
        local sq = cell:getGridSquare(x + dx * k, y + dy * k, 0)
        local fl = sq and sq:getFloor()
        local nm = string.lower(tostring(fl and fl:getSprite() and fl:getSprite():getName() or ""))
        if (nm:find("street", 1, true) or nm:find("road", 1, true)) and not sq:getBuilding() then n = n + 1 else break end
    end
    return n
end

S.step(5, function() C.time(21.6); C.look("dark", "pink"); C.noWindows(); if getGameSpeed() <= 0 then setGameSpeed(1) end; pcall(function() p:setGodMod(true) end) end)
for k = 1, #SPOTS do
    S.step(5, function() if road then return end; C.moveTo(SPOTS[k][1], SPOTS[k][2], 0) end)
    S.step(150, function()
        if road then return end
        local r = C.findRoad(SPOTS[k][1], SPOTS[k][2], 60, 24)
        if r then
            -- the way with the longest clear run of road ahead (somewhere to drive)
            local best, bn = nil, -1
            for _, d in ipairs({ { "E", 1, 0 }, { "W", -1, 0 }, { "S", 0, 1 }, { "N", 0, -1 } }) do
                local n = roadRun(r[1], r[2], d[2], d[3])
                if n > bn then best, bn = d[1], n end
            end
            S.say("spot " .. k .. ": road " .. r[1] .. "," .. r[2] .. ", " .. bn .. " squares clear to the " .. best)
            if bn >= 25 then road, dir = r, best end
        else S.say("spot " .. k .. ": no road") end
    end)
end
S.step(10, function()
    if not road then S.say("ERR no road with a clear run"); return end
    C.clearScene(road[1], road[2], 14)
    -- (takes 1 and 2 drove into a lamppost) the lane: the square across the road (0..6 over) whose next 20 squares
    -- ahead are bare road (one floor object each, no tree)
    local cell = getCell()
    local d = ({ E = { 1, 0 }, W = { -1, 0 }, S = { 0, 1 }, N = { 0, -1 } })[dir]
    local px, py = (d[1] == 0) and 1 or 0, (d[2] == 0) and 1 or 0
    local lane = nil
    for _, o in ipairs({ -3, -4, -2, -5, 3, 4, -6 }) do   -- (the car is two squares wide: never the curb lane, where a lamppost stood)
        if not lane then
            local x0, y0, ok = road[1] + px * o, road[2] + py * o, true
            for k = -3, 20 do
                local sq = cell:getGridSquare(x0 + d[1] * k, y0 + d[2] * k, 0)
                local fl = sq and sq:getFloor()
                local nm = string.lower(tostring(fl and fl:getSprite() and fl:getSprite():getName() or ""))
                if not sq or sq:getTree() or sq:getObjects():size() > 1 or not (nm:find("street", 1, true) or nm:find("road", 1, true)) then ok = false end
            end
            if ok then lane = { x0, y0 }; S.say("lane " .. o .. " over: " .. x0 .. "," .. y0) end
        end
    end
    if lane then road = lane else S.say("note: no bare lane found") end
    car = C.car("Base.CarNormal", road[1], road[2], dir, true)
    S.say("car " .. tostring(car ~= nil) .. " facing " .. dir)
    if not car then return end
    pcall(function() car:repair() end)
    pcall(function() local g = car:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity() * 0.6); car:transmitPartModData(g) end)
    pcall(function() p:getInventory():AddItem(car:createVehicleKey()) end)
    -- (the first take's engine never started) a charged battery
    pcall(function() local b = car:getPartById("Battery"):getInventoryItem(); b:setCurrentUsesFloat(1.0) end)
    pcall(function() local b = car:getPartById("Battery"):getInventoryItem(); b:setUsedDelta(1.0) end)
    pcall(function() car:getPartById("Battery"):setCondition(100) end)
    C.time(21.6)   -- (dusk: 19.1 and 20.6 still read as day: a summer evening on the save's date)
    C.clearSky()
    C.dress({ "Base.Vest_DefaultTEXTURE_TINT", "Base.Trousers_CamoGreen", "Base.Shoes_ArmyBoots", "Base.Glasses_Aviators",
              "Base.WristWatch_Left_DigitalBlack", "Base.Bag_FannyPackFront" }, nil, { "Base.Shotgun", "Base.ShotgunShells", "Base.MuldraughMap", "Base.Lighter", "Base.WaterBottle" })
    pcall(function() local d = p:getDescriptor(); d:setForename("Sara"); d:setSurname("Kohners") end)
    C.profession("BURGER_FLIPPER")
    C.tint("Base.Vest_DefaultTEXTURE_TINT", 0.16, 0.16, 0.17)
    -- beside the driver's door
    local fx, fy = road[1], road[2]
    if dir == "E" or dir == "W" then fy = fy - 2 else fx = fx - 2 end
    C.moveTo(fx, fy, 0)
end)
C.lookAround(S, dir)
S.step(20, function()
    if not car then return end
    pcall(function() car:enter(0, p) end)
    S.inCar = p:getVehicle() ~= nil
    if S.inCar then pcall(function() triggerEvent("OnEnterVehicle", p) end) end
    S.say("in the driver's seat " .. tostring(S.inCar))
end)
S.step(30, function() if S.inCar then pcall(function() car:setKeysInIgnition(true) end) end end)
local tries, last, tick = 0, -9999, 0
S.poll(30, 120, function()
    tick = tick + 10
    if not S.inCar then return true end
    local run = false
    pcall(function() run = car:isEngineRunning() end)
    if run then return true end
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    if not (q and q.queue and #q.queue > 0) and tick - last > 120 and tries < 5 then
        tries = tries + 1; last = tick
        pcall(function() ISVehicleMenu.onStartEngine(p) end)
    end
    return false
end)
-- (the game's own start did not take: the engine's start as the game ends it)
S.step(30, function()
    local run = false; pcall(function() run = car:isEngineRunning() end)
    if not run and car then pcall(function() car:tryStartEngine(true) end); pcall(function() car:engineDoRunning() end); S.say("note: engine started directly") end
end)
S.step(60, function()
    local run = false; pcall(function() run = car:isEngineRunning() end)
    S.say("engine running " .. tostring(run))
    local on = false; pcall(function() on = car:getHeadlightsOn() end)
    if not on then pcall(function() ISVehicleMenu.onToggleHeadlights(p) end) end
end)
S.step(60, function()
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if d and d._st and not d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
    local part = car and car:getPartById("Radio")
    S.part = part
    if part then
        pcall(function() RO.setChannel(p, part, 101200) end)
        pcall(function() RO.run("SetVolume", p, part, 0.6) end)
    else S.say("ERR the car has no Radio part") end
end)
C.pointerAway(S)
C.zoom(S, 0.75)
-- dusk: the clock alone left the light at day (takes 1 and 2); the climate's night and daylight strengths as an admin's
-- climate panel sets them
-- (C.dusk left out: the clock alone, later in the evening)
-- (the light follows the clock slowly: the first take at 19.1 still read as day) time for dusk to come in
S.step(900, function() S.say(string.format("time %.2f", getGameTime():getTimeOfDay())) end)
S.step(60, function() if S.part then pcall(function() ISVehicleMenu.onSignalDevice(p, S.part) end) end end)
S.step(60, function()
    local pr = CR and CR.props and CR.props[pn]
    S.say("car radio up " .. tostring(pr and pr:isReallyVisible()))
end)
-- on the move: W held (virtual key 0x57, scan code 0x11)
C.key(S, "keydown", 87, 17)
S.step(240, function() local sp = 0; pcall(function() sp = car:getCurrentSpeedKmHour() end); S.say(string.format("speed %.1f km/h", sp)) end)
S.step(2, function()
    local sp = 0; pcall(function() sp = car:getCurrentSpeedKmHour() end)
    local st = nil; pcall(function() st = RO.read(S.part) end)
    local pr = CR and CR.props and CR.props[pn]
    S.say(string.format("shot at %.1f km/h | radio on %s channel %s | prop %s | lights %s", sp, tostring(st and st.on), tostring(st and st.channel),
        tostring(pr and pr:isReallyVisible()), tostring(car and car:getHeadlightsOn())))
    C.shot(S, "koh_dusk")
end)
C.key(S, "keyup", 87, 17)
-- stop: the brake (S, 0x53 / 0x1F) a moment
C.key(S, "keydown", 83, 31)
S.step(120, function() end)
C.key(S, "keyup", 83, 31)
S.step(20, function()
    pcall(function() CR.closeFor(pn) end)
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if d and d._st and d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
    pcall(function() if car:isEngineRunning() then car:shutOff() end end)
end)
S.step(30, function()
    local v = p:getVehicle()
    if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
end)
S.step(30, function() S.say("DONE") end)
S.run()
