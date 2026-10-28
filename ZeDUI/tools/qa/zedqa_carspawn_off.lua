-- ZeDUI/tools/qa/zedqa_carspawn_off.lua  (Oct 27 2026)
-- ZeD OFF (zedqa_off_run.ps1 -Tag cso): the cars zedqa_seat_lightbar_vanilla.lua spawns and enters,
-- in the same order and at the same places, with only the game's own code: does the game log
-- "FBORenderLevels.getNLevels ... Index -1" by itself? Vanilla calls only. grep "ZEDQA cso".
local p = getPlayer()
local function say(s) print("ZEDQA cso " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local spawned = {}
local function spawn(script, dx, dy)
    local sq = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
    if not sq then say("no square for " .. script); return nil end
    local v = addVehicleDebug(script, IsoDirections.N, nil, sq)
    if v then spawned[#spawned + 1] = v end
    return v
end
local function enter(v)
    if not v then return end
    say("enter " .. v:getScriptName() .. " dist=" .. string.format("%.1f", v:DistTo(p)))
    if v:DistTo(p) > 12 then say("too far, skipped"); return end
    v:enter(0, p); triggerEvent("OnEnterVehicle", p)
end
local function leave() local v = p:getVehicle(); if v then v:exit(p); triggerEvent("OnExitVehicle", p) end end
local pickup, police, van
at(2, function() p:setGodMod(true); if getGameSpeed() <= 0 then setGameSpeed(1) end; say("start") end)
at(5, function()
    pickup = spawn("Base.PickUpTruck", -4, 0)
    police = spawn("Base.CarLightsPolice", 4, 0)
    van = spawn("Base.VanSeats", 0, -5)
    say("spawned " .. #spawned)
end)
at(30, function() enter(pickup) end)
at(160, function() leave() end)
at(190, function() enter(police) end)
at(295, function() local v = p:getVehicle(); if v then pcall(function() v:setLightbarLightsMode(2) end) end end)
at(360, function() leave() end)
at(390, function() enter(van) end)
at(460, function() leave() end)
at(500, function()
    for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. tostring(e)) end end end
    if tick > 510 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
