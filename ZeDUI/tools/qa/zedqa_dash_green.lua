-- ZeD QA (Oct 29 2026): the dash needles and the green gauge light (HANDOFF_dash_needles_green_20261029.md).
--   d6       a parked Chevalier D6 by day: the fan speedometer's needle at rest, its root inside the shroud
--   fire     the fire pickup at speed (pushed along its heading, no keys pressed): the needle in mid-sweep
--   green    each late model at night, its headlights on and then off: the Dash Elite, the Primani, the SUV, the
--            Lang 4000 (the clock's wash green) and the Cossette (its lamps green). The needles keep their orange
--            (needleOwn, the director's pick, Oct 29 2026)
-- Run zedqa_dash_green_only.lua first (dash_green_night.txt) for the green cars alone.
-- The windows' layout is reset (ZeD_Window.resetLayout) before each car. Night is D.qaNight = 1 (the QA stand-in for
-- the light at the car); the dash lights follow the car's real headlight switch. Puts back D.qaNight, the needle
-- option, the car and its key. Screenshots: Zomboid/Screenshots/zqa_dgr_<case>.png; each shot logs the dash's screen
-- rect. grep "ZEDQA dgr".
local p = getPlayer(); local D = ZeD.Dashboard
local TAG = "dgr"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if getGameSpeed() == 0 then setGameSpeed(1) end
local errs = 0
local function err(s) errs = errs + 1; say("ERR " .. s) end

local Q, qi = {}, 1
local function step(f) Q[#Q + 1] = f end
local function now() return getTimestampMs() end
local function waitMs(ms) local t0 = nil; step(function() t0 = t0 or now(); if now() - t0 >= ms then t0 = nil; return true end end) end
local function waitFor(cond, ms, onTimeout)
    local t0 = nil
    step(function()
        t0 = t0 or now()
        if cond() then t0 = nil; return true end
        if now() - t0 >= ms then t0 = nil; if onTimeout then onTimeout() end; return true end
    end)
end
local function act(f) step(function() f(); return true end) end
local function during(ms, f) local t0 = nil; step(function() t0 = t0 or now(); local r = f(now() - t0); if r or now() - t0 >= ms then t0 = nil; return true end end) end

local function dash() return D.getInstance() end
local function st() local d = dash(); return d and d._st end
local function click(id)
    local d = dash(); if not d then return false end
    for _, hr in ipairs(d._hit or {}) do
        if hr.id == id then return d:onMouseDown(hr.x + math.floor(hr.w / 2), hr.y + math.floor(hr.h / 2)) and true or false end
    end
    return false
end
local function shot(case)
    local d = dash()
    local L = d and d._light
    local x, y, w, h = -1, -1, -1, -1
    pcall(function() x, y, w, h = d:getAbsoluteX(), d:getAbsoluteY(), d:getWidth(), d:getHeight() end)
    local s = d and d._st or {}
    say(string.format("shot %s design=%s rect=%d,%d,%d,%d k=%s n8=%s lit=%s tmap=%s needleOwn=%s lights=%s running=%s kmh=%.1f mph=%.1f",
        case, tostring(d and d._designId), x, y, w, h, tostring(d and d._s), tostring(L and L.n8), tostring(L and L.lit),
        tostring(L and L.tmap ~= nil), tostring(L and L.needleOwn), tostring(s.lights), tostring(s.running),
        tonumber(s.speed) or -1, (tonumber(s.speed) or 0) * 0.6214))
    pcall(function() getCore():TakeFullScreenshot("zqa_" .. TAG .. "_" .. case .. ".png") end)
end
local function resetWindows() pcall(function() ZeD_Window.resetLayout() end) end

-- staging (as zedqa_dash_r6_parts.lua): a fresh car on a free loaded square beside the character, seated only once it
-- has a square and a chunk and has held them READY_HOLD_MS (never a car from elsewhere in the world)
local OFFS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 }, { 6, 6 }, { -6, 0 } }
local MAXD = 12
local cur, curKey, tries, rot = nil, nil, 0, 0
local function carReady(v)
    local sq, chunk, dist = nil, nil, 999
    pcall(function() sq = v:getSquare() end)
    local okC = pcall(function() chunk = v:getChunk() end)
    if not okC and sq then pcall(function() chunk = sq:getChunk() end) end
    pcall(function() dist = v:DistTo(p) end)
    -- (42.22: seated before its physics is up, the engine's BaseVehicle.updatePhysics NPE drops the game to the
    -- main menu, as zedqa_dash19.lua and zedqa_dashnight.lua found; Oct 29 2026 it did so here)
    local phys = false
    pcall(function() phys = v:isPhysicsActive() end)
    return sq ~= nil and chunk ~= nil and dist <= MAXD and phys == true
end
local READY_HOLD_MS = 1500
local readySince = nil
local function carSettled(v)
    local removed = false; pcall(function() removed = v:isRemovedFromWorld() end)
    if removed or not carReady(v) then readySince = nil; return false end
    readySince = readySince or getTimestampMs()
    return getTimestampMs() - readySince >= READY_HOLD_MS
end
local function spawn(script)
    while tries < #OFFS do
        tries = tries + 1
        local o = (tries <= 4) and OFFS[(rot + tries - 1) % 4 + 1] or OFFS[tries]
        local sq = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], math.floor(p:getZ()))
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
        if sq and free then
            local v = addVehicleDebug(script, IsoDirections.N, nil, sq)
            if v then cur = v; return true end
        end
    end
    return false
end
-- (42.22: a car removed in the same tick as the exit leaves the engine updating a seated player in a car with no
-- physics; the car goes once the character is out of it)
local pending = nil
local function clean()
    if pending and p:getVehicle() ~= pending then pcall(function() pending:permanentlyRemove() end); pending = nil end
end
local function leave()
    local v = p:getVehicle(); if v then pcall(function() v:exit(p) end); triggerEvent("OnExitVehicle", p) end
    if cur then
        if p:getVehicle() == cur then pending = cur else pcall(function() cur:permanentlyRemove() end) end
    end
    if curKey then pcall(function() p:getInventory():Remove(curKey) end) end
    cur, curKey = nil, nil
end
local function stage(n, script)
    local failed = false
    act(function() leave() end)
    waitMs(1500)
    act(function()
        resetWindows()
        tries = 0; rot = rot + 1; failed = false
        if not spawn(script) then failed = true; err(n .. " spawn failed " .. script) end
    end)
    act(function() readySince = nil end)
    waitFor(function() return failed or not cur or carSettled(cur) end, 5000, function()
        if cur then pcall(function() cur:permanentlyRemove() end); cur = nil end
        if not spawn(script) then failed = true; err(n .. " no ready car " .. script) end
    end)
    act(function()
        if failed or not cur then return end
        local v = cur
        pcall(function() v:repair() end)
        pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
        pcall(function()
            local b = v:getPartById("Battery"); local it = b and b:getInventoryItem()
            if it then pcall(function() it:setCurrentUsesFloat(1.0) end); pcall(function() it:setUsedDelta(1.0) end) end
        end)
        readySince = nil
    end)
    waitFor(function() return failed or (cur and carSettled(cur)) end, 8000)
    act(function()
        if failed or not cur then return end
        local v = cur
        if not carSettled(v) then err(n .. " car not settled at the seat step; not entered"); failed = true; return end
        pcall(function() if v:isKeysInIgnition() then v:setKeysInIgnition(false) end end)
        pcall(function() curKey = p:getInventory():AddItem(v:createVehicleKey()) end)
        pcall(function() v:enter(0, p) end)
        if p:getVehicle() then triggerEvent("OnEnterVehicle", p) else err(n .. " could not enter " .. script); failed = true end
    end)
    waitMs(800)
    act(function() resetWindows() end)
    waitMs(700)
    return function() return not failed and cur ~= nil and p:getVehicle() == cur end
end
local function startEngine(n)
    local tries_, t0 = 0, nil
    act(function() t0 = now(); click("ignition") end)
    waitFor(function()
        local s = st()
        if s and s.running then return true end
        if s and s.keyPos == "off" and not s.cranking and now() - t0 > 1500 then
            tries_ = tries_ + 1
            if tries_ >= 5 then return true end
            t0 = now(); click("ignition")
        end
        return false
    end, 25000, function() err(n .. " engine never ran") end)
end
local function design() local d = dash(); return d and d._designId end
local function expectDesign(n, want)
    act(function() if design() ~= want then err(n .. " design " .. tostring(design()) .. ", want " .. want) end end)
end

local GREEN_ONLY = ZeD_QA_DGR_GREEN_ONLY == true
ZeD_QA_DGR_GREEN_ONLY = nil
if GREEN_ONLY then act(function() say("green cars only (zedqa_dash_green_only.lua)") end) end
if not GREEN_ONLY then
-- ===================================================================== the D6, parked, by day
act(function() D.qaNight = 0; D.qaLit = nil end)
local okD6 = stage("d6", "Base.PickUpTruck")
expectDesign("d6", "d6")
waitMs(1500)
act(function()
    if not okD6() then return end
    local d = dash(); local nd = nil
    for _, p_ in ipairs(ZeD.DashPx.designs.d6.parts) do if p_.t == "needle" and p_.src == "speed_mph" then nd = p_ end end
    say(string.format("d6 speedometer pivot %s,%s r1=%s a0=%s a1=%s", tostring(nd and nd.cx), tostring(nd and nd.cy), tostring(nd and nd.r1),
        tostring(nd and nd.a0), tostring(nd and nd.a1)))
    if not (nd and nd.cy == 96 and nd.a0 == 210 and nd.a1 == 330 and nd.r1 == 60) then err("d6 speedometer data is not the new fan (pivot 240,96, 210..330, r1 60)") end
    shot("d6_parked_day")
end)
-- the key in, the engine off: the needle still at rest
act(function() if okD6() then click("ignition") end end)
waitMs(1500)
act(function() if okD6() then shot("d6_parked_day_keyin") end end)

-- ===================================================================== the fire pickup, at speed
local okFire = stage("fire", "Base.PickUpTruckLightsFire")
expectDesign("fire", "fire")
act(function() if okFire() then click("ignition") end end)
waitMs(600)
startEngine("fire")
local drive = { F = 50, at = 0, maxKmh = 0, shot = false }
local fwd, zero = nil, nil
local function axes(v)
    fwd = fwd or Vector3f.new(); zero = zero or Vector3f.new(0, 0, 0)
    v:getForwardVector(fwd)
    return fwd:x(), fwd:y(), fwd:z()
end
local TARGET = 64     -- km/h, about 40 mph: the needle in mid-sweep
during(20000, function(ms)
    if not okFire() then return true end
    local v = cur; local s = st(); if not s then return end
    pcall(function() v:setPhysicsActive(true) end)
    local okA, fx, fy, fz = pcall(axes, v)
    if okA and s.speed < TARGET then local F = drive.F; pcall(function() v:addImpulse(Vector3f.new(fx * F, fy * F, fz * F), zero) end) end
    if ms - drive.at >= 1000 then
        drive.at = ms
        if s.speed < TARGET * 0.5 then drive.F = math.min(drive.F * 2, 50000) end
        say(string.format("fire drive t=%d push=%d kmh=%.1f mph=%.1f", math.floor(ms / 1000), drive.F, s.speed or -1, (s.speed or 0) * 0.6214))
    end
    if s.speed > drive.maxKmh then drive.maxKmh = s.speed end
    if s.speed >= TARGET * 0.85 and not drive.shot then drive.shot = true; drive.t = ms end
    -- (the needle settles over a few frames: the shot 400 ms after the speed is reached)
    if drive.shot and ms - drive.t >= 400 then shot("fire_at_speed"); return true end
end)
act(function()
    say(string.format("fire drove: max %.1f km/h", drive.maxKmh))
    if not drive.shot then err("fire never reached " .. TARGET .. " km/h (max " .. string.format("%.1f", drive.maxKmh) .. ")") end
end)
during(10000, function()
    if not okFire() then return true end
    local v = cur; local s = st(); if not s then return end
    if s.speed <= 1 then return true end
    local okA, fx, fy, fz = pcall(axes, v)
    if okA then local F = drive.F; pcall(function() v:addImpulse(Vector3f.new(-fx * F, -fy * F, -fz * F), zero) end) end
end)
act(function() D.qaNight = nil end)
end

-- ===================================================================== the late models, at night
local GREEN = {
    { "dashelite", "Base.ModernCar" }, { "primani", "Base.ModernCar02" }, { "suv", "Base.SUV" },
    { "luxury", "Base.CarLuxury" }, { "cossette", "Base.SportsCar" },
}
for _, e in ipairs(GREEN) do
    local tag, script = e[1], e[2]
    local okC = stage(tag, script)
    expectDesign(tag, tag)
    act(function() if okC() then click("ignition") end end)
    waitMs(600)
    startEngine(tag)
    act(function()
        if not okC() then return end
        local d = dash(); if not (d and d._st) then return end
        if not d._st.radioOn then d:_fire("pwr", false) end
        if not d._st.heaterOn then d:_fire("heat", false) end
        if not d._st.lights then d:_fire("lights", false) end
        D.qaNight = 1; D.qaLit = nil
    end)
    waitMs(2500)
    act(function()
        if not okC() then return end
        local d = dash(); local L = d and d._light
        if not (L and L.tmap and L.tints) then err(tag .. " has no tint map at night (DashPx " .. tostring(ZeD.DashPx.designs[tag].night.tmap ~= nil) .. ")") end
        if not (L and L.lit) then err(tag .. " dash lights not on with the headlights on") end
        local hasNeedle = false
        for _, p_ in ipairs(ZeD.DashPx.designs[tag].parts) do if p_.t == "needle" then hasNeedle = true end end
        if hasNeedle and not (L and L.needleOwn) then err(tag .. " needles not light-piped (needleOwn)") end
        -- (a spawned car can drop through the ground under the character, the engine's FBORenderLevels at a level
        -- below 0: its speedometer then reads the fall; Oct 29 2026, the Dash Elite)
        if (tonumber(d and d._st and d._st.speed) or 0) > 3 then err(tag .. " car moving at " .. tostring(d._st.speed) .. " km/h while parked (fell through the ground?)") end
        shot(tag .. "_night_on")
    end)
    act(function() if okC() then local d = dash(); if d and d._st and d._st.lights then d:_fire("lights", false) end end end)
    waitMs(2000)
    act(function()
        if not okC() then return end
        local d = dash(); local L = d and d._light
        if L and L.lit then err(tag .. " dash lights still on with the headlights off") end
        shot(tag .. "_night_off")
    end)
    act(function() D.qaNight = nil end)
end

act(function()
    leave()
    D.qaNight = nil; D.qaLit = nil
    resetWindows()
end)
waitMs(1000)
act(function() clean(); say(errs == 0 and "PASS" or ("errors " .. errs)); say("DONE") end)

local function tick()
    clean()
    local f = Q[qi]
    if not f then Events.OnTick.Remove(tick); return end
    local ok, done = pcall(f)
    if not ok then say("step error: " .. tostring(done)); qi = qi + 1; return end
    if done then qi = qi + 1 end
end
Events.OnTick.Add(tick)
