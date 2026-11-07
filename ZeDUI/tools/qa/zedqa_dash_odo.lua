-- ZeDUI/tools/qa/zedqa_dash_odo.lua  (Nov 7 2026, QA; punch list 92 and 94, Build's 44df3931): the odometers and the trip.
-- Built on zedqa_dash_r6_parts.lua (the drag strip, the car staging, the push that drives with no keys pressed).
--   for a Nyala (drum dash) and a ModernCar (Dash Elite):
--     key on    the bulb check (a picture), the starting figures; the seed stable, a wreck higher (D.odoSeed)
--     engine    the lamps dark (a picture)
--     drive     straight up the strip for about 20 s; the car's own path summed square by square against what the
--               odometer and the trip counted (a square is a metre at the game's speeds), then stopped
--     trip      the stem zeroes the trip; on the Dash Elite the window switches ODO / TRIP, its second verb zeroes the trip
--               only while the trip shows
--   then the Dash Elite at night (panel lights off and on, key on and off), and the Simple dash in miles and in km
--   The Dash Elite stays beside the strip with its key and figures in Zomboid/Lua/zedqa_odo_persist.txt for
--   zedqa_dash_odo_reload.lua (the next launch). Screenshots zqa_dod_<case>.png. grep "ZEDQA dod".
local p = getPlayer(); local D = ZeD.Dashboard
local TAG = "dod"
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
-- a step that runs f every tick for ms (f gets the time since it began)
local function during(ms, f) local t0 = nil; step(function() t0 = t0 or now(); f(now() - t0); if now() - t0 >= ms then t0 = nil; return true end end) end

local function dash() return D.getInstance() end
local function st() local d = dash(); return d and d._st end
local function click(id, right)
    local d = dash(); if not d then return false end
    for _, hr in ipairs(d._hit or {}) do
        if hr.id == id then
            local x, y = hr.x + math.floor(hr.w / 2), hr.y + math.floor(hr.h / 2)
            if right then return d:onRightMouseDown(x, y) and true or false end
            return d:onMouseDown(x, y) and true or false
        end
    end
    return false
end
local function hitOf(id) local d = dash(); for _, hr in ipairs(d and d._hit or {}) do if hr.id == id then return hr end end return nil end
local function shot(case) pcall(function() getCore():TakeFullScreenshot("zqa_dod_" .. case .. ".png") end) end
local function rect()
    local d = dash(); local x, y, w, h = -1, -1, -1, -1
    pcall(function() x, y, w, h = d:getAbsoluteX(), d:getAbsoluteY(), d:getWidth(), d:getHeight() end)
    return string.format("%d,%d,%d,%d k=%s", x, y, w, h, tostring(d and d._s))
end
local function money(v) return string.format("%.2f", tonumber(v) or -1) end

-- staging (as zedqa_dashnight.lua)
local OFFS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 }, { 6, 6 }, { -6, 0 } }
local MAXD = 12
local cur, curKey, tries, rot = nil, nil, 0, 0
local keep = {}          -- cars left in the world for the reload check
local function carReady(v)
    local sq, chunk, phys, dist = nil, nil, false, 999
    pcall(function() sq = v:getSquare() end)
    local okC = pcall(function() chunk = v:getChunk() end)
    if not okC and sq then pcall(function() chunk = sq:getChunk() end) end
    pcall(function() phys = v:isPhysicsActive() end)
    pcall(function() dist = v:DistTo(p) end)
    -- (not live physics: a parked car's physics sleeps after a repair until someone sits in it, Oct 24 final pass)
    return sq ~= nil and chunk ~= nil and dist <= MAXD
end
-- ready, and still ready READY_HOLD_MS later (a car's square can have its chunk a moment before the car is attached to
-- it; seating the character then drops the game to the main menu: VehiclesDB2.updateVehicle NPE, Oct 24 run 2)
local READY_HOLD_MS = 1500
local readySince = nil
local function carSettled(v)
    local removed = false; pcall(function() removed = v:isRemovedFromWorld() end)
    if removed or not carReady(v) then readySince = nil; return false end
    readySince = readySince or getTimestampMs()
    return getTimestampMs() - readySince >= READY_HOLD_MS
end
local function diag(v)
    local sq, chunk, phys, dist, rem = nil, nil, nil, -1, nil
    pcall(function() sq = v:getSquare() end)
    pcall(function() chunk = v:getChunk() end)
    pcall(function() phys = v:isPhysicsActive() end)
    pcall(function() dist = v:DistTo(p) end)
    pcall(function() rem = v:isRemovedFromWorld() end)
    return string.format("(square=%s chunk=%s physics=%s dist=%.1f removed=%s hold=%s)", tostring(sq ~= nil), tostring(chunk ~= nil), tostring(phys), dist, tostring(rem), tostring(readySince))
end
local function spawn(script)
    while tries < #OFFS do
        tries = tries + 1
        local o = (tries <= 4) and OFFS[(rot + tries - 1) % 4 + 1] or OFFS[tries]   -- (the four good squares in turn: a removed car's square is not reused at once; (-6,0), (6,6) and (-4,-4) never settled)
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
local function fuel(v, f) pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity() * f) end) end
local function leave(keepCar)
    local v = p:getVehicle(); if v then pcall(function() v:exit(p) end); triggerEvent("OnExitVehicle", p) end
    if cur and not keepCar then pcall(function() cur:permanentlyRemove() end) end
    if curKey then pcall(function() p:getInventory():Remove(curKey) end) end
    cur, curKey = nil, nil
end
local function stage(n, script)
    local failed = false
    act(function() leave() end)
    waitMs(1500)   -- (Oct 24 run 3: a spawn right after a removal dropped the game to the main menu, VehiclesDB2)
    act(function()
        tries = 0; rot = rot + 1; failed = false
        if not spawn(script) then failed = true; err(n .. " spawn failed " .. script) end
    end)
    act(function() readySince = nil end)
    waitFor(function() return failed or not cur or carSettled(cur) end, 5000, function()
        if cur then pcall(function() cur:permanentlyRemove() end); cur = nil end
        if not spawn(script) then failed = true; err(n .. " no ready car " .. script) end
    end)
    -- dressed first (a repair resets the car's parts and its physics for a moment: seated right after it, every other
    -- car was not settled, Oct 24 runs), then settled again, then seated with nothing in between
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
        if not carSettled(v) then err(n .. " car not settled at the seat step; not entered " .. diag(v)); failed = true; return end
        -- (the game puts a key in some cars' locks when it spawns them: out, so every car starts with the key out)
        pcall(function() if v:isKeysInIgnition() then v:setKeysInIgnition(false) end end)
        pcall(function() curKey = p:getInventory():AddItem(v:createVehicleKey()) end)
        pcall(function() v:enter(0, p) end)
        if p:getVehicle() then triggerEvent("OnEnterVehicle", p) else err(n .. " could not enter " .. script) end
    end)
    waitMs(400)
    act(function() if cur then pcall(function() if cur:isKeysInIgnition() then cur:setKeysInIgnition(false) end end) end end)
    waitMs(300)
    return function() return not failed and cur ~= nil and p:getVehicle() == cur end
end
local function startEngine(n)
    local tries_, t0 = 0, nil
    act(function() t0 = now(); click("ignition") end)
    waitFor(function()
        local s = st()
        if s and s.running then return true end
        if s and s.keyPos == "acc" and not s.cranking and now() - t0 > 1500 then
            tries_ = tries_ + 1
            if tries_ >= 5 then return true end
            t0 = now(); click("ignition")
        end
        return false
    end, 25000, function() err(n .. " engine never ran") end)
end

-- open ground (director, Oct 24 2026: "You are spawning cars in the forest with rocks all over. Go to a large parking
-- lot or the drag strip"): the Irvington Speedway's drag strip. Where the character stood is kept in its modData
-- (ZeDDashOdoHome) and it goes back there at the end, so the other QA scripts find it where they expect.
local SITE = { x = 925, y = 13040 }   -- mid-strip, between the two grandstands (x 875-893 and 964-977)
local pmd = p:getModData()
pmd.ZeDDashOdoHome = pmd.ZeDDashOdoHome or { x = p:getX(), y = p:getY(), z = p:getZ() }
local function tp(x, y, z)
    p:teleportTo(x, y, z or 0)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z or 0); p:setLastX(x); p:setLastY(y); p:setLastZ(z or 0) end)
end
-- the squares round a point are loaded (a square and its chunk 8 squares out every way)
local function loadedAround(x, y)
    for _, o in ipairs({ { 0, 0 }, { 8, 0 }, { -8, 0 }, { 0, 8 }, { 0, -8 } }) do
        local sq = getCell():getGridSquare(math.floor(x) + o[1], math.floor(y) + o[2], 0)
        if not sq then return false end
        local ch = nil; pcall(function() ch = sq:getChunk() end)
        if not ch then return false end
    end
    return true
end
local function goSite()
    act(function() tp(SITE.x + 0.5, SITE.y + 0.5, 0) end)
    waitFor(function() return loadedAround(SITE.x, SITE.y) end, 40000, function() err("the speedway never loaded round the character") end)
    waitMs(3000)
    act(function()
        say(string.format("at the speedway %d,%d (home %d,%d)", math.floor(p:getX()), math.floor(p:getY()), math.floor(pmd.ZeDDashOdoHome.x), math.floor(pmd.ZeDDashOdoHome.y)))
        pcall(function() getCore():TakeFullScreenshot("zqa_" .. TAG .. "_site.png") end)
    end)
end
local function goHome()
    act(function() local h = pmd.ZeDDashOdoHome; if h then tp(h.x, h.y, h.z) end end)
    waitFor(function() local h = pmd.ZeDDashOdoHome; return not h or loadedAround(h.x, h.y) end, 40000)
    act(function() pmd.ZeDDashOdoHome = nil; say(string.format("back home %d,%d", math.floor(p:getX()), math.floor(p:getY()))) end)
end
-- cars an earlier run kept for the reload check and nobody removed (listed in zedqa_r6_persist.txt): gone, here and at
-- the speedway (each car under its own pcall: one odd vehicle never stops the cleanup)
local function cleanLeftovers(where)
    local keys, n = {}, 0
    pcall(function()
        local r = getFileReader("zedqa_r6_persist.txt", false)
        if not r then return end
        local line = r:readLine()
        while line do local k = tonumber(string.match(tostring(line), "^%S+ (%S+)")); if k then keys[k] = true; n = n + 1 end; line = r:readLine() end
        r:close()
    end)
    if n == 0 then return end
    local it = getCell():getVehicles():iterator()   -- (the list's get() is not callable from Lua; its iterator is)
    local found = {}
    while it:hasNext() do
        local v = it:next()
        if v then
            local k = nil; pcall(function() k = v:getKeyId() end)
            if k and keys[k] then found[#found + 1] = v end
        end
    end
    for _, v in ipairs(found) do
        local k = nil; pcall(function() k = v:getKeyId() end)
        say("removed a car an earlier run kept (" .. where .. "), key " .. tostring(k))
        pcall(function() v:permanentlyRemove() end)
    end
end
act(function() cleanLeftovers("home") end)
goSite()
act(function() cleanLeftovers("speedway") end)

local pass_, fail_ = 0, 0
local function check(okc, what) if okc then pass_ = pass_ + 1; say("PASS " .. what) else fail_ = fail_ + 1; say("FAIL " .. what) end end
local function mdOf(v) local md = v and v:getModData(); return md and string.format("ZeD_odo=%s ZeD_trip=%s ZeD_odoTrip=%s", tostring(md.ZeD_odo), tostring(md.ZeD_trip), tostring(md.ZeD_odoTrip)) or "?" end
local fwd, zero = nil, nil
local function axes(v)
    fwd = fwd or Vector3f.new(); zero = zero or Vector3f.new(0, 0, 0)
    v:getForwardVector(fwd)
    return fwd:x(), fwd:y(), fwd:z()
end

-- the seed: stable for an id and condition, higher for a wreck
act(function()
    local a, b = D.odoSeed(1234, 100), D.odoSeed(1234, 100)
    local w = D.odoSeed(1234, 10)
    check(a == b, "the starting mileage is stable for a car (" .. tostring(a) .. ", " .. tostring(b) .. ")")
    check(w > a, "a wreck starts with more miles (" .. tostring(w) .. " against " .. tostring(a) .. ")")
end)

for _, e in ipairs({ { "nyala", "Base.CarNormal" }, { "dashelite", "Base.ModernCar" } }) do
    local n, script = e[1], e[2]
    local ok = stage(n, script)
    local R = {}
    act(function() if ok() then click("ignition") end end)          -- the key in: the bulb check
    waitMs(250)
    act(function()
        if not ok() then return end
        local s = st()
        R.odo0, R.trip0 = s.odo, s.trip
        say(string.format("%s key on: odo %s trip %s; %s; rect %s", n, tostring(s.odo), tostring(s.trip), mdOf(cur), rect()))
        shot(n .. "_keyon")
    end)
    startEngine(n)
    waitMs(1500)
    act(function() if ok() then shot(n .. "_running"); local s = st(); R.odo1, R.trip1 = s.odo, s.trip; say(string.format("%s running: odo %s trip %s", n, tostring(s.odo), tostring(s.trip))) end end)
    -- the drive
    local D_ = { F = 50, at = 0, dist = 0, lx = nil, ly = nil, maxKmh = 0, log = 0 }
    local function driveTick(brake)
        return function(ms)
            if not ok() then return end
            local v = cur
            local s = st(); if not s then return end
            pcall(function() v:setPhysicsActive(true) end)
            local okA, fx, fy, fz = pcall(axes, v)
            if okA then
                if brake then
                    if s.speed > 1 then pcall(function() v:addImpulse(Vector3f.new(-fx * D_.F, -fy * D_.F, -fz * D_.F), zero) end) end
                elseif s.speed < 30 then
                    pcall(function() v:addImpulse(Vector3f.new(fx * D_.F, fy * D_.F, fz * D_.F), zero) end)
                end
            end
            if not brake and ms - D_.at >= 1000 then D_.at = ms; if s.speed < 5 then D_.F = math.min(D_.F * 2, 50000) end end
            local x, y = v:getX(), v:getY()
            if D_.lx then D_.dist = D_.dist + math.sqrt((x - D_.lx) ^ 2 + (y - D_.ly) ^ 2) end
            D_.lx, D_.ly = x, y
            if s.speed > D_.maxKmh then D_.maxKmh = s.speed end
            if ms - D_.log >= 2000 then D_.log = ms; say(string.format("%s drive t=%d kmh=%.1f path=%.1f squares odo=%.3f trip=%.3f", n, math.floor(ms / 1000), s.speed, D_.dist, s.odo or -1, s.trip or -1)) end
        end
    end
    during(20000, driveTick(false))
    during(6000, driveTick(true))
    waitFor(function() local s = st(); return not ok() or (s and s.speed < 0.5) end, 15000)
    act(function()
        if not ok() then return end
        local v = cur
        local x, y = v:getX(), v:getY()
        if D_.lx then D_.dist = D_.dist + math.sqrt((x - D_.lx) ^ 2 + (y - D_.ly) ^ 2) end
        local s = st()
        local dOdo, dTrip = (s.odo or 0) - (R.odo1 or 0), (s.trip or 0) - (R.trip1 or 0)
        local miles = D_.dist / 1609.344
        say(string.format("%s drove %.1f squares (%.4f mi at a metre a square), top %.1f km/h; odometer +%.4f, trip +%.4f; %s", n, D_.dist, miles, D_.maxKmh, dOdo, dTrip, mdOf(v)))
        check(D_.maxKmh > 10 and miles > 0, n .. " moved (top " .. string.format("%.1f", D_.maxKmh) .. " km/h)")
        check(miles > 0 and math.abs(dOdo - miles) <= math.max(0.01, miles * 0.12), string.format("%s odometer counts the distance driven (%.4f against %.4f mi, %.0f%%)", n, dOdo, miles, miles > 0 and dOdo / miles * 100 or 0))
        check(math.abs(dTrip - dOdo) < 0.002, string.format("%s trip counts with the odometer (+%.4f, +%.4f)", n, dTrip, dOdo))
        shot(n .. "_after_drive")
    end)
    -- the trip
    if n == "nyala" then
        act(function() if ok() then local okc = click("tripReset"); say("stem pressed: " .. tostring(okc)) end end)
        waitMs(300)
        act(function() if ok() then local s = st(); check((s.trip or 1) < 0.05, n .. " the stem zeroes the trip (" .. tostring(s.trip) .. ", odo " .. tostring(s.odo) .. ")"); shot(n .. "_trip_zero") end end)
    else
        act(function() if ok() then local okc = click("odoButton", true); say("window second verb with ODO showing: " .. tostring(okc)) end end)
        waitMs(300)
        act(function() if ok() then local s = st(); check((s.trip or 0) > 0.001, n .. " the second verb does nothing while ODO shows (trip " .. tostring(s.trip) .. ")"); click("odoButton") end end)
        waitMs(300)
        act(function() if ok() then local s = st(); check(s.odoTrip == true, n .. " the window switches to TRIP (" .. tostring(s.odoTrip) .. ")"); shot(n .. "_trip_shown"); click("odoButton", true) end end)
        waitMs(300)
        act(function() if ok() then local s = st(); check((s.trip or 1) < 0.05, n .. " the second verb zeroes the trip while it shows (" .. tostring(s.trip) .. ")"); shot(n .. "_trip_zeroed") end end)
        -- night (TRIP left showing, for the reload check)
        act(function() if ok() then D.qaNight = 1; D.qaLit = false end end)
        waitMs(500)
        act(function() if ok() then shot(n .. "_night_dark_engine") end end)
        act(function() if ok() then D.qaLit = true end end)
        waitMs(500)
        act(function() if ok() then shot(n .. "_night_lit_engine") end end)
        act(function() if ok() then click("ignition") end end)          -- engine off
        waitFor(function() local s = st(); return not ok() or (s and not s.running) end, 6000)
        waitMs(300)
        act(function() if ok() then local s = st(); say(n .. " engine off: keyPos " .. tostring(s.keyPos) .. ", power " .. tostring(s.power)); shot(n .. "_night_lit_keyoff"); D.qaLit = false end end)
        waitMs(500)
        act(function() if ok() then shot(n .. "_night_dark_keyoff"); D.qaNight = nil; D.qaLit = nil end end)
        -- the Simple dash, miles then km
        local keepFmt, keepStyle
        act(function()
            keepStyle = ZeD.Settings.dashStyleOption:getValue()
            pcall(function() keepFmt = getCore():getOptionMeasurementFormat() end)
            ZeD.Settings.dashStyleOption:setValue(2)
            pcall(function() getCore():setOptionMeasurementFormat("Imperial") end)
        end)
        waitMs(2500)
        act(function() say("Simple dash (" .. tostring(D.simple()) .. "), " .. tostring(getCore():getOptionMeasurementFormat())); shot(n .. "_simple_mi") end)
        act(function() pcall(function() getCore():setOptionMeasurementFormat("Metric") end) end)
        waitMs(2500)
        act(function() say("Simple dash, " .. tostring(getCore():getOptionMeasurementFormat())); shot(n .. "_simple_km") end)
        act(function()
            pcall(function() getCore():setOptionMeasurementFormat(keepFmt or "Imperial") end)
            ZeD.Settings.dashStyleOption:setValue(keepStyle or 1)
            say("units put back " .. tostring(getCore():getOptionMeasurementFormat()) .. ", dash look " .. tostring(ZeD.Settings.dashStyleOption:getValue()))
        end)
        act(function() if ok() then click("ignition", true) end end)    -- the key out
        waitMs(300)
        act(function()
            if not ok() then return end
            local s = st()
            local rec = { key = cur:getKeyId(), odo = s.odo, trip = s.trip, show = s.odoTrip, x = math.floor(cur:getX()), y = math.floor(cur:getY()) }
            say(string.format("kept for the reload: key %s at %d,%d odo %s trip %s show %s; %s", tostring(rec.key), rec.x, rec.y, tostring(rec.odo), tostring(rec.trip), tostring(rec.show), mdOf(cur)))
            local w = getFileWriter("zedqa_odo_persist.txt", true, false)
            w:write(string.format("%s %s %s %s %d %d\n", tostring(rec.key), tostring(rec.odo), tostring(rec.trip), tostring(rec.show), rec.x, rec.y))
            w:close()
        end)
    end
    act(function() leave(n == "dashelite") end)
    waitMs(800)
end

act(function() leave() end)
goHome()
act(function()
    D.qaRiders, D.qaNight, D.qaLit = nil, nil, nil
    say(pass_ .. " passed, " .. fail_ .. " failed, errors=" .. errs)
    say("DONE")
end)

local function tick()
    if not Q[qi] then Events.OnTick.Remove(tick); return end
    local ok_, r = pcall(Q[qi])
    if not ok_ then say("step error: " .. tostring(r)); r = true end
    if r then qi = qi + 1 end
end
Events.OnTick.Add(tick)
