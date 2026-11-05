-- ZeDUI/tools/qa/gallery_cinema_kohners.lua  (Nov 4 2026, QA; the director's cinema breaks): Kohners on a deserted
-- road at dusk beside a broken-down white sedan (the Chevalier Nyala, the police model without the lights): hood up, a
-- front tire flat. Dark tank top, green camo trousers, boots, aviators, a pump shotgun, a map.
-- The road: the script looks for a road square with no building within 24 squares, in open country between the towns.
-- Run on the shot save: zedqa_run.ps1 -ShotSave ZeD-Shots-Kohners -Manifest cinema_kohners.txt. The look: Dark with
-- the pink (magenta) accent (the director). Pictures cin_koh_<name>.png:
--   vehicle  the Character window on Equip, the World window on Vehicle (the flat, the open hood)
--   maps     the Character window on Health, the World window on Maps
--   wide     no windows, pulled back: the road, the car, the dusk
-- grep "ZEDQA ckoh".
local C = CIN
local S = C.seq("ckoh")
local p = getPlayer()
-- open country between the towns (the trailer's spot at 7094,8388 is a cul-de-sac: houses block the view and the
-- unseen ground draws black)
local SPOTS = { { 8800, 10800 }, { 9500, 11600 }, { 10300, 12000 }, { 11200, 8800 }, { 7600, 9600 }, { 12000, 6800 } }
local road, car, si = nil, nil, 0

S.step(5, function() C.look("dark", "pink"); C.noWindows() end)
for k = 1, #SPOTS do
    S.step(5, function() if road then return end; C.moveTo(SPOTS[k][1], SPOTS[k][2], 0) end)
    S.step(150, function()
        if road then return end
        road = C.findRoad(SPOTS[k][1], SPOTS[k][2], 60, 24)
        S.say("spot " .. k .. ": road " .. tostring(road and (road[1] .. "," .. road[2])))
    end)
end
S.step(10, function()
    if not road then S.say("ERR no road"); return end
    C.clearScene(road[1], road[2], 12)
    -- which way the road runs: more road squares east-west or north-south
    local cell, ew, ns = getCell(), 0, 0
    local function isRoad(x, y)
        local sq = cell:getGridSquare(x, y, 0); local fl = sq and sq:getFloor()
        local nm = string.lower(tostring(fl and fl:getSprite() and fl:getSprite():getName() or ""))
        return nm:find("street", 1, true) or nm:find("road", 1, true)
    end
    for d = -6, 6 do if isRoad(road[1] + d, road[2]) then ew = ew + 1 end; if isRoad(road[1], road[2] + d) then ns = ns + 1 end end
    local dir = (ew >= ns) and "E" or "S"
    car = C.car("Base.CarNormal", road[1], road[2], dir, true)
    S.say("car " .. tostring(car ~= nil) .. " facing " .. dir .. " (ew " .. ew .. ", ns " .. ns .. ")")
    if car then
        pcall(function() local h = car:getPartById("EngineDoor"); car:playPartAnim(h, "Open"); h:getDoor():setOpen(true); car:transmitPartDoor(h) end)
        pcall(function() ZeD.MechanicsTab.pin(car) end)   -- the World window's Vehicle tab lists it
        pcall(function() local t = car:getPartById("TireFrontLeft"); t:setContainerContentAmount(0); t:setCondition(0) end)
        pcall(function() car:getPartById("Engine"):setCondition(8) end)
        pcall(function() car:getPartById("GasTank"):setContainerContentAmount(1) end)
        pcall(function() car:setHeadlightsOn(false) end)
    end
    -- stand at the open hood (the front of the car), facing it
    local fx, fy = road[1], road[2]
    if dir == "E" then fx = fx + 3 else fy = fy + 3 end
    C.moveTo(fx, fy, 0)
    p:setDir(dir == "E" and IsoDirections.W or IsoDirections.N)
    S.face = (dir == "E") and "W" or "N"
end)
S.step(10, function()
    C.time(19.1)
    C.clearSky()
    C.dress({ "Base.Vest_DefaultTEXTURE_TINT", "Base.Trousers_CamoGreen", "Base.Shoes_ArmyBoots", "Base.Glasses_Aviators",
              "Base.WristWatch_Left_DigitalBlack", "Base.Bag_FannyPackFront" }, "Base.Shotgun", { "Base.ShotgunShells", "Base.MuldraughMap", "Base.Lighter", "Base.WaterBottle" })
    C.profession("BURGER_FLIPPER")   -- (a profession that fits the role: the director)
    C.tint("Base.Vest_DefaultTEXTURE_TINT", 0.16, 0.16, 0.17)
    S.say("dressed; worn " .. tostring(p:getWornItems():size()))
end)
-- (the circle runs after the car is placed; S.face is read when the last step runs)
for _, d in ipairs({ "N", "NE", "E", "SE", "S", "SW", "W", "NW" }) do S.step(12, function() p:setDir(IsoDirections[d]) end) end
S.step(12, function() p:setDir(IsoDirections[S.face or "W"]) end)
C.pointerAway(S)
C.zoom(S, 0.5)
S.step(30, function() C.windows("equip", "vehicle") end)
S.step(150, function() C.shot(S, "koh_vehicle") end)
S.step(20, function() C.windows("health", "maps") end)
S.step(150, function() C.shot(S, "koh_maps") end)
S.step(20, function() C.noWindows() end)
C.zoom(S, 1.25)
S.step(90, function() C.shot(S, "koh_wide") end)
S.step(30, function() S.say("DONE") end)
S.run()
