-- ZeD QA (Oct 29 2026): the key, the fob, the dash down to the screen's edge, the column's shroud
-- (HANDOFF_dash_keys_edge_20261029.md). Built on zedqa_dash_green.lua (staging) and zedqa_dash_r6_keys.lua (the dry start
-- that holds the key at START).
--   per design, all 19: a fresh car beside the character, the windows' layout reset first; then
--     off     the key in, the engine off: the key reads OFF, the fob hangs whole, the dash flush on the screen's bottom
--             edge (its rect's bottom = the player's screen bottom), the shroud meeting the edge
--     start   an empty tank and a turn of the key: the starter turns and the key reads START
--     on      the tank filled, the engine started: the key reads ON
--   A parked car that moves (> 3 km/h) fell through the ground: that design is rejected (ERR), not judged.
-- Screenshots: Zomboid/Screenshots/zqa_dke_<design>_<off|start|on>.png; each shot logs the dash's screen rect. Leaves no car,
-- no key and the windows reset. grep "ZEDQA dke".
local p = getPlayer(); local D = ZeD.Dashboard
local TAG = "dke"
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

local function dash() return D.getInstance() end
local function st() local d = dash(); return d and d._st end
local function click(id)
    local d = dash(); if not d then return false end
    for _, hr in ipairs(d._hit or {}) do
        if hr.id == id then return d:onMouseDown(hr.x + math.floor(hr.w / 2), hr.y + math.floor(hr.h / 2)) and true or false end
    end
    return false
end
local function resetWindows() pcall(function() ZeD_Window.resetLayout() end) end
local function fuel(v, f) pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity() * f) end) end

-- the dash's screen rect, and whether its bottom is the player's screen's bottom
local function flush(n, case)
    local d = dash(); if not d then err(n .. " no dash at " .. case); return end
    local x, y, w, h = -1, -1, -1, -1
    pcall(function() x, y, w, h = d:getAbsoluteX(), d:getAbsoluteY(), d:getWidth(), d:getHeight() end)
    local sb = getPlayerScreenTop(0) + getPlayerScreenHeight(0)
    local s = d._st or {}
    say(string.format("shot %s_%s design=%s rect=%d,%d,%d,%d bottom=%d screenBottom=%d k=%s keyPos=%s running=%s kmh=%.1f",
        n, case, tostring(d._designId), x, y, w, h, y + h, sb, tostring(d._s), tostring(s.keyPos), tostring(s.running),
        tonumber(s.speed) or -1))
    if y + h ~= sb then err(string.format("%s %s: the dash ends at %d, the screen at %d", n, case, y + h, sb)) end
end
local function shot(n, case)
    flush(n, case)
    pcall(function() getCore():TakeFullScreenshot("zqa_" .. TAG .. "_" .. n .. "_" .. case .. ".png") end)
end

-- staging, as zedqa_dash_green.lua: a fresh car on a free loaded square beside the character, seated only once it has a
-- square and a chunk and has held them READY_HOLD_MS (never a car from elsewhere in the world)
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
        fuel(v, 1)
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
local function design() local d = dash(); return d and d._designId end

local CARS = {
    { "luxury", "Base.CarLuxury" }, { "nyala", "Base.CarNormal" }, { "cossette", "Base.SportsCar" },
    { "police", "Base.CarLightsPolice" }, { "d6", "Base.PickUpTruck" }, { "dashelite", "Base.ModernCar" },
    { "primani", "Base.ModernCar02" }, { "dart", "Base.SmallCar" }, { "horizon", "Base.SmallCar02" },
    { "wagon", "Base.CarStationWagon" }, { "suv", "Base.SUV" }, { "van", "Base.Van" },
    { "bulldriver", "Base.PickUpVan" }, { "rancher", "Base.OffRoad" }, { "taxi", "Base.CarTaxi" },
    { "ambulance", "Base.VanAmbulance" }, { "fire", "Base.PickUpTruckLightsFire" }, { "ranger", "Base.CarLightsRanger" },
    { "race", "Base.RaceCar12" },
}
local ONLY = ZeD_QA_DKE_ONLY; ZeD_QA_DKE_ONLY = nil      -- (a set of design ids, to rerun a few)
act(function() D.qaNight = 0; D.qaLit = nil end)
for _, e in ipairs(CARS) do
    local n, script = e[1], e[2]
    if not ONLY or ONLY[n] then
        local ok = stage(n, script)
        local moving = false
        local function okM() return ok() and not moving end
        act(function()
            if not ok() then return end
            if design() ~= n then err(n .. " design " .. tostring(design()) .. ", want " .. n) end
            click("ignition")                 -- the key in, at OFF
        end)
        waitMs(1200)
        act(function()
            if not ok() then return end
            local s = st() or {}
            if (tonumber(s.speed) or 0) > 3 then
                moving = true; err(n .. " parked car moving at " .. tostring(s.speed) .. " km/h (fell through the ground?): rejected")
                return
            end
            if s.keyPos ~= "off" then err(n .. " key reads " .. tostring(s.keyPos) .. " with the key in, engine off; want off") end
            shot(n, "off")
        end)
        -- START: a turn on an empty tank holds the starter (the key at START) without catching
        act(function() if okM() then fuel(cur, 0); click("ignition") end end)
        local seenStart = false
        waitFor(function()
            if not okM() then return true end
            local s = st(); if s and s.keyPos == "start" then seenStart = true; return true end
        end, 2000)
        waitMs(150)
        act(function()
            if not okM() then return end
            if not seenStart then err(n .. " the key never read START while the starter turned"); return end
            local s = st() or {}
            if s.keyPos ~= "start" then say(n .. " (START gone before the shot: " .. tostring(s.keyPos) .. ")") end
            shot(n, "start")
        end)
        waitFor(function() local s = st(); return not okM() or (s and not s.running and not s.cranking and s.keyPos == "off") end, 15000,
            function() err(n .. " dry start never settled") end)
        waitFor(function() local s = st(); return not okM() or (s and s.engState == "Idle") end, 8000)
        -- ON: fill the tank and start it
        local tries_, t0 = 0, nil
        act(function() if okM() then fuel(cur, 1); t0 = now(); click("ignition") end end)
        waitFor(function()
            if not okM() then return true end
            local s = st()
            if s and s.running and s.keyPos == "on" then return true end
            if s and s.keyPos == "off" and not s.cranking and now() - t0 > 1500 then
                tries_ = tries_ + 1
                if tries_ >= 5 then return true end
                t0 = now(); click("ignition")
            end
            return false
        end, 25000, function() err(n .. " engine never ran") end)
        waitMs(400)
        act(function()
            if not okM() then return end
            local s = st() or {}
            if not (s.running and s.keyPos == "on") then err(n .. " key reads " .. tostring(s.keyPos) .. " running=" .. tostring(s.running) .. "; want on") end
            shot(n, "on")
        end)
    end
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
