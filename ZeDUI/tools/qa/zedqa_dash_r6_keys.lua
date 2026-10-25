-- ZeD QA (Oct 24 2026): dashboards round 6 on all 19 designs. Per car (a fresh spawn beside the character, seated once
-- it is really in the world): the key in (OFF), a start by a click on the key (OFF - ON - START while the starter turns -
-- ON once it runs), the lights on, screenshots at k = 2 and k = 1 (D.scale), the ash tray opened and shut by clicks (or,
-- on the emergency designs, no tray at all), shutting off (ON a step, then OFF), a start on an empty tank that does not
-- catch (back through ON to OFF), the key out (no key). Every key move is logged by the dash itself, with its time from
-- the click; a sequence that differs from the handoff's is an ERR. Screenshots: Zomboid/Screenshots/zqa_r6_<n>_<case>.png.
-- grep "ZEDQA r6k".
local p = getPlayer(); local D = ZeD.Dashboard
local TAG = "r6k"
local LIST = {
    { "01_luxury", "Base.CarLuxury" }, { "02_nyala", "Base.CarNormal" }, { "03_cossette", "Base.SportsCar" },
    { "04_police", "Base.CarLightsPolice" }, { "05_d6", "Base.PickUpTruck" }, { "06_dashelite", "Base.ModernCar" },
    { "07_primani", "Base.ModernCar02" }, { "08_dart", "Base.SmallCar" }, { "09_horizon", "Base.SmallCar02" },
    { "10_wagon", "Base.CarStationWagon" }, { "11_suv", "Base.SUV" }, { "12_van", "Base.Van" },
    { "13_bulldriver", "Base.PickUpVan" }, { "14_rancher", "Base.OffRoad" }, { "15_taxi", "Base.CarTaxi" },
    { "16_ambulance", "Base.VanAmbulance" }, { "17_fire", "Base.PickUpTruckLightsFire" }, { "18_ranger", "Base.CarLightsRanger" },
    { "19_race", "Base.RaceCar12" },
}
local NO_TRAY = { police = true, ambulance = true, fire = true, ranger = true, race = true }
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if getGameSpeed() == 0 then setGameSpeed(1) end
local errs = 0
local function err(s) errs = errs + 1; say("ERR " .. s) end

-- the steps: each is called every tick until it returns true
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

-- the key's moves, logged by the dash itself every frame (ZeD_Dashboard:_keyPos), from a mark
local W = nil
local keyPos0 = ZeD_Dashboard._keyPos
ZeD_Dashboard._keyPos = function(self, st, t)
    local r = keyPos0(self, st, t)
    if W then
        local dt = t - W.t0
        local k = tostring(r)
        if k ~= W.lk then W.k[#W.k + 1] = { k, dt }; W.lk = k end
        local e = tostring(st.engState) .. (st.running and "+run" or "")
        if e ~= W.le then W.e[#W.e + 1] = e .. "@" .. dt; W.le = e end
        if W.wasRun and not st.running and not W.stopAt then W.stopAt = dt end
        W.wasRun = st.running
    end
    return r
end
local function mark(name)
    local d = D.getInstance()
    local k0 = tostring(d and d._keyShown)
    W = { name = name, t0 = now(), k = { { k0, 0 } }, lk = k0, e = {} }
end
-- the moves as "off@0 on@0 start@121 ...", the positions alone, and how long each held
local function moves()
    local s, seq, held = {}, {}, {}
    for i, m in ipairs(W.k) do
        s[#s + 1] = m[1] .. "@" .. m[2]
        seq[#seq + 1] = m[1]
        held[i] = (W.k[i + 1] and W.k[i + 1][2] or (now() - W.t0)) - m[2]
    end
    return table.concat(s, " "), table.concat(seq, " "), held
end
-- want: the positions in order; steps: the indices of the ON steps between the ends (each ~120 ms); stopStep: the
-- index of the OFF that follows the engine stopping (ON rests ~120 ms after the engine stops)
local function report(tag, want, steps, stopStep)
    if not W then return end
    local s, seq, held = moves()
    say(string.format("%s %s key: %s | engine: %s", tag, W.name, s, table.concat(W.e, " ")))
    if want and seq ~= want then err(string.format("%s %s key went %s, want %s", tag, W.name, seq, want)) end
    local function near120(ms, what)
        if ms < 90 or ms > 400 then err(string.format("%s %s %s %d ms (want ~120)", tag, W.name, what, ms))
        else say(string.format("%s %s %s %d ms", tag, W.name, what, ms)) end
    end
    for _, i in ipairs(steps or {}) do if held[i] and seq == want then near120(held[i], "ON step " .. i .. " held") end end
    if stopStep and W.stopAt and W.k[stopStep] and seq == want then near120(W.k[stopStep][2] - W.stopAt, "ON after the engine stopped") end
    W = nil
end

local function dash() return D.getInstance() end
local function st() local d = dash(); return d and d._st end
-- a click on a control's middle, as the mouse would (the dash's own hit test); right = the second verb
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
local function hasHit(id) local d = dash(); for _, hr in ipairs(d and d._hit or {}) do if hr.id == id then return true end end return false end
local function shot(n, case) pcall(function() getCore():TakeFullScreenshot("zqa_r6_" .. n .. "_" .. case .. ".png") end) end
local function rect()
    local d = dash(); local x, y, w, h = -1, -1, -1, -1
    pcall(function() x, y, w, h = d:getAbsoluteX(), d:getAbsoluteY(), d:getWidth(), d:getHeight() end)
    return string.format("%d,%d,%d,%d k=%s", x, y, w, h, tostring(d and d._s))
end

-- staging (after zedqa_dashnight.lua): a fresh spawn on a loaded free square, seated only once the car has had a
-- square and a chunk, within MAXD of the character, for READY_HOLD_MS in a row
local OFFS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 }, { 6, 6 }, { -6, 0 } }
local MAXD = 12
local cur, curKey, tries, rot = nil, nil, 0, 0
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
local function leave()
    local v = p:getVehicle(); if v then pcall(function() v:exit(p) end); triggerEvent("OnExitVehicle", p) end
    if cur then pcall(function() cur:permanentlyRemove() end) end
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
    waitFor(function()
        if failed or not cur then return true end
        return carSettled(cur)
    end, 5000, function()
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

-- a start by clicking the key, until it runs (a start that does not catch is tried again, up to 4 times)
local function startEngine(n)
    local tries_ = 0
    act(function() mark("start"); click("ignition") end)
    waitFor(function()
        local s = st()
        if s and s.running and s.keyPos == "on" then return true end
        -- (a start that gave up: the key back at OFF and the engine idle; log it and turn again)
        if W and s and s.keyPos == "off" and not s.cranking and now() - W.t0 > 1500 then
            report(n, nil); tries_ = tries_ + 1
            if tries_ >= 4 then return true end
            mark("start (again)"); click("ignition")
        end
        return false
    end, 20000, function() err(n .. " engine never ran") end)
    act(function() report(n, "off on start on", { 2 }) end)
end

-- open ground (director, Oct 24 2026: "You are spawning cars in the forest with rocks all over. Go to a large parking
-- lot or the drag strip"): the Irvington Speedway's drag strip. Where the character stood is kept in its modData
-- (ZeDDashR6Home) and it goes back there at the end, so the other QA scripts find it where they expect.
local SITE = { x = 925, y = 13040 }   -- mid-strip, between the two grandstands (x 875-893 and 964-977)
local pmd = p:getModData()
pmd.ZeDDashR6Home = pmd.ZeDDashR6Home or { x = p:getX(), y = p:getY(), z = p:getZ() }
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
        say(string.format("at the speedway %d,%d (home %d,%d)", math.floor(p:getX()), math.floor(p:getY()), math.floor(pmd.ZeDDashR6Home.x), math.floor(pmd.ZeDDashR6Home.y)))
        pcall(function() getCore():TakeFullScreenshot("zqa_" .. TAG .. "_site.png") end)
    end)
end
local function goHome()
    act(function() local h = pmd.ZeDDashR6Home; if h then tp(h.x, h.y, h.z) end end)
    waitFor(function() local h = pmd.ZeDDashR6Home; return not h or loadedAround(h.x, h.y) end, 40000)
    act(function() pmd.ZeDDashR6Home = nil; say(string.format("back home %d,%d", math.floor(p:getX()), math.floor(p:getY()))) end)
end
goSite()

for _, e in ipairs(LIST) do
    local n, script = e[1], e[2]
    local design = n:sub(4)
    local ok = stage(n, script)
    local d0 = nil
    act(function()
        if not ok() then return end
        local s = st()
        say(string.format("%s staged design=%s script=%s keyPos=%s keyId=%s rect=%s", n, tostring(dash()._designId), script,
            tostring(s and s.keyPos), tostring(cur:getKeyId()), rect()))
        if s and s.keyPos ~= nil then err(n .. " a key drawn before it is in: " .. tostring(s.keyPos)) end
        mark("insert"); click("ignition")
    end)
    waitMs(500)
    act(function() if ok() then report(n, "nil off") end end)
    startEngine(n)
    act(function() if ok() then local s = st(); if s and not s.lights then click("lights") end end end)
    waitMs(900)
    act(function() if ok() then shot(n, "run_k2"); say(n .. " run_k2 " .. rect()) end end)
    waitMs(300)
    act(function() D.scale = 1 / 1.75 end)
    waitMs(500)
    act(function() if ok() then shot(n, "run_k1"); say(n .. " run_k1 " .. rect()) end end)
    waitMs(300)
    act(function() D.scale = 1.0 end)
    waitMs(300)
    -- the ash tray: two clicks (open / shut or shut / open), each logged; the emergency designs have none
    act(function()
        if not ok() then return end
        local s = st()
        if NO_TRAY[design] then
            if hasHit("ash") then err(n .. " has an ash tray control") end
            if s.ashOpen ~= 0 then err(n .. " ashOpen=" .. tostring(s.ashOpen)) end
            say(string.format("%s no tray (hit=%s ashOpen=%s)", n, tostring(hasHit("ash")), tostring(s.ashOpen)))
            return
        end
        d0 = { open = s.ashIsOpen, lv = s.ashOpen }
        say(string.format("%s tray default open=%s level=%s md=%s", n, tostring(s.ashIsOpen), tostring(s.ashOpen), tostring(cur:getModData().ZeD_ash)))
        if not click("ash") then err(n .. " ash click not taken") end
    end)
    waitMs(250)
    act(function()
        if not (ok() and d0) then return end
        local s = st()
        say(string.format("%s tray click1 open=%s level=%s md=%s", n, tostring(s.ashIsOpen), tostring(s.ashOpen), tostring(cur:getModData().ZeD_ash)))
        if s.ashIsOpen == d0.open then err(n .. " the tray did not move on click 1") end
        shot(n, s.ashIsOpen and "tray_open" or "tray_shut")
    end)
    waitMs(300)
    act(function() if ok() and d0 then click("ash") end end)
    waitMs(250)
    act(function()
        if not (ok() and d0) then return end
        local s = st()
        say(string.format("%s tray click2 open=%s level=%s", n, tostring(s.ashIsOpen), tostring(s.ashOpen)))
        if s.ashIsOpen ~= d0.open or s.ashOpen ~= d0.lv then err(n .. " the tray did not come back on click 2") end
        if s.ashIsOpen then shot(n, "tray_open") end
    end)
    -- shut off: ON a step, then OFF
    act(function() if ok() then mark("shutoff"); click("ignition") end end)
    waitFor(function() local s = st(); return not ok() or (s and not s.running and s.keyPos == "off" and now() - W.t0 > 300) end, 6000,
        function() err(n .. " never shut off") end)
    act(function() if ok() then report(n, "on off", nil, 2) end end)
    -- a start on an empty tank: it does not catch (once the engine has wound down: a start while it reads
    -- ShuttingDown is ignored by the game)
    waitFor(function() local s = st(); return not ok() or (s and s.engState == "Idle") end, 8000,
        function() err(n .. " engine never went Idle after shutting off") end)
    act(function() if ok() then fuel(cur, 0); mark("dry start"); click("ignition") end end)
    waitMs(250)
    act(function() if ok() and W and st() and st().keyPos == "start" then shot(n, "key_start") end end)
    waitFor(function() local s = st(); return not ok() or (s and not s.running and not s.cranking and s.keyPos == "off" and now() - W.t0 > 1200) end, 15000,
        function() err(n .. " dry start never settled") end)
    act(function()
        if not ok() then return end
        local s = st()
        if s.running then err(n .. " ran on an empty tank") end
        report(n, "off on start on off", { 2, 4 })
        fuel(cur, 1)
    end)
    -- the key out
    act(function() if ok() then mark("key out"); click("ignition", true) end end)
    waitMs(300)
    act(function() if ok() then report(n, "off nil") end end)
    act(leave)
    waitMs(300)
end
act(function() leave() end)
goHome()
act(function()
    ZeD_Dashboard._keyPos = keyPos0
    D.scale = 1.0
    say("errors=" .. errs)
    say("DONE")
end)

local function tick()
    if not Q[qi] then Events.OnTick.Remove(tick); return end
    local ok, r = pcall(Q[qi])
    if not ok then say("step error: " .. tostring(r)); r = true end
    if r then qi = qi + 1 end
end
Events.OnTick.Add(tick)
