-- ZeD QA (Oct 24 2026): dashboards round 6, the parts that are not the key.
--   vans    the logo vans (Spiffo's, Fossoil, McCoy's x2) wear the game's decal; a business van (Mechanic, Mail) has
--           NO SMOKING; a plain Van, a VanSeats paint job and a plain StepVan have an ash tray that opens by a click
--   taxi    the fare settings (SandboxVars.ZeD); the flag down by a click starts the meter at the flag drop; waiting
--           a minute adds a minute's rate; driving (the cruise regulator, the wheel turned one way, then the other) adds
--           a fifth of a mile's rate per fifth; the extras count the riders past the first; the hula girl sways in the
--           turns and is drawn above the dash's top edge; the licence card's unit line; the key out clears the meter
--   night   taxi, van and ambulance with the dash lights on and off (the new parts take the light map)
--   reload  two Nyalas left beside the character for zedqa_dash_r6_persist.lua (the next run): one untouched, one
--           with its tray clicked; their key numbers and trays go to Zomboid/Lua/zedqa_r6_persist.txt
-- Screenshots: Zomboid/Screenshots/zqa_r6p_<case>.png. grep "ZEDQA r6p".
local p = getPlayer(); local D = ZeD.Dashboard
local TAG = "r6p"
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
local function shot(case) pcall(function() getCore():TakeFullScreenshot("zqa_r6p_" .. case .. ".png") end) end
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
        if s and s.keyPos == "off" and not s.cranking and now() - t0 > 1500 then
            tries_ = tries_ + 1
            if tries_ >= 5 then return true end
            t0 = now(); click("ignition")
        end
        return false
    end, 25000, function() err(n .. " engine never ran") end)
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

-- ===================================================================== vans
local VANS = {
    { "van_spiffo", "Base.VanSpiffo", "logo", "Buisness_SpiffosDECAL" },
    { "van_fossoil", "Base.VanFossoil", "logo", "Buisness_FossoilDECAL" },
    { "van_mccoy", "Base.VanMccoy", "logo", "Buisness_McCoysDECAL" },
    { "van_johnmccoy", "Base.VanJohnMcCoy", "logo", "Buisness_McCoysDECAL" },
    { "van_mechanic", "Base.VanMechanic", "nosmoke" },
    { "van_mail", "Base.VanMail", "nosmoke" },
    { "van_plain", "Base.Van", "ash" },
    { "van_creature", "Base.VanSeats_Creature", "ash" },
    { "van_stepvan", "Base.StepVan", "ash" },
}
for _, e in ipairs(VANS) do
    local n, script, want, decal = e[1], e[2], e[3], e[4]
    local ok = stage(n, script)
    act(function() if ok() then click("ignition") end end)           -- the key in
    waitMs(500)
    act(function()
        if not ok() then return end
        local d, s = dash(), st()
        local logo = d._logo and d._logo.tex or "none"
        local got = s.vanRight or (d._logo and "logo") or "nil"
        say(string.format("%s design=%s vanRight=%s vanTray=%s logo=%s ash=%s/%s", n, tostring(d._designId), tostring(s.vanRight),
            tostring(s.vanTray), logo, tostring(s.ashIsOpen), tostring(s.ashOpen)))
        if d._designId ~= "van" then err(n .. " not on the van's dash: " .. tostring(d._designId)) end
        if got ~= want then err(n .. " right side " .. got .. ", want " .. want) end
        if decal and not logo:find(decal, 1, true) then err(n .. " logo " .. logo .. ", want " .. decal) end
        local h = hitOf("ash")
        if want ~= "ash" and h and h.enabled then err(n .. " has a live ash tray control") end
        if want ~= "ash" and s.ashOpen ~= 0 then err(n .. " shows an open tray") end
        shot(n)
    end)
    if want == "ash" then
        local before = nil
        act(function()
            if not ok() then return end
            before = st().ashIsOpen
            if not click("ash") then err(n .. " ash click not taken") end
        end)
        waitMs(300)
        act(function()
            if not ok() then return end
            local s = st()
            say(string.format("%s tray clicked: open %s -> %s level=%s", n, tostring(before), tostring(s.ashIsOpen), tostring(s.ashOpen)))
            if s.ashIsOpen == before then err(n .. " the tray did not move") end
            shot(n .. (s.ashIsOpen and "_open" or "_shut"))
        end)
    end
    act(function() leave() end)
    waitMs(300)
end

-- ===================================================================== taxi
local ok = stage("taxi", "Base.CarTaxi")
local S0 = {}
act(function()
    if not ok() then return end
    local Z = SandboxVars and SandboxVars.ZeD
    say(string.format("taxi sandbox ZeD: %s flag=%s fifth=%s minute=%s extra=%s", tostring(Z ~= nil),
        tostring(Z and Z.TaxiFlagDrop), tostring(Z and Z.TaxiPerFifthMile), tostring(Z and Z.TaxiPerMinuteWaiting), tostring(Z and Z.TaxiPerExtraPassenger)))
    if not Z then err("taxi SandboxVars.ZeD missing (sandbox-options.txt not loaded)") end
    click("ignition")      -- the key in
end)
waitMs(400)
act(function()
    if not ok() then return end
    local s = st()
    say(string.format("taxi key in, engine off: meter hit enabled=%s meterOn=%s", tostring(hitOf("meter") and hitOf("meter").enabled), tostring(s.meterOn)))
end)
startEngine("taxi")
act(function() if ok() then local s = st(); if not s.lights then click("lights") end end end)
waitMs(800)
act(function()
    if not ok() then return end
    local d, s = dash(), st()
    say(string.format("taxi running: unit=%q hula=%s meterOn=%s fare=%s rect=%s", tostring(d._badge and d._badge.unit), tostring(s.hula),
        tostring(s.meterOn), money(s.fare), rect()))
    if s.hula ~= 0 then err("taxi hula not at rest standing still: " .. tostring(s.hula)) end
    shot("taxi_flag_up")
    if not click("meter") then err("taxi meter click not taken") end
end)
waitMs(300)
act(function()
    if not ok() then return end
    local s = st()
    say(string.format("taxi flag down: meterOn=%s fare=%s extras=%s riders(real)=%s", tostring(s.meterOn), money(s.fare), money(s.fareExtra), "driver only"))
    if not s.meterOn then err("taxi flag did not drop") end
    if money(s.fare) ~= "1.50" then err("taxi flag drop fare " .. money(s.fare)) end
    if money(s.fareExtra) ~= "0.00" then err("taxi extras with no rider " .. money(s.fareExtra)) end
    shot("taxi_flag_down")
    -- the fare settings are read live: a server's value shows at once
    local Z = SandboxVars and SandboxVars.ZeD
    if Z then S0.flag = Z.TaxiFlagDrop; Z.TaxiFlagDrop = 2.0 end
end)
waitMs(200)
act(function()
    if not ok() then return end
    local s = st()
    say("taxi sandbox flag drop 2.00 -> fare " .. money(s.fare))
    if money(s.fare) ~= "2.00" then err("taxi fare did not follow SandboxVars.ZeD.TaxiFlagDrop: " .. money(s.fare)) end
    local Z = SandboxVars and SandboxVars.ZeD
    if Z and S0.flag then Z.TaxiFlagDrop = S0.flag end
    D.qaRiders = 2
end)
waitMs(200)
act(function()
    local s = st(); say("taxi riders 2 -> extras " .. money(s.fareExtra))
    if money(s.fareExtra) ~= "0.50" then err("taxi extras with 2 riders " .. money(s.fareExtra)) end
    D.qaRiders = 3
end)
waitMs(200)
act(function()
    local s = st(); say("taxi riders 3 -> extras " .. money(s.fareExtra))
    if money(s.fareExtra) ~= "1.00" then err("taxi extras with 3 riders " .. money(s.fareExtra)) end
    shot("taxi_extras")
    D.qaRiders = 1
end)
waitMs(200)
act(function()
    local s = st(); say("taxi riders 1 -> extras " .. money(s.fareExtra))
    if money(s.fareExtra) ~= "0.00" then err("taxi extras with 1 rider " .. money(s.fareExtra)) end
    D.qaRiders = nil
end)
-- waiting: a minute standing still with the flag down adds the minute's rate
local tw0 = nil
act(function() tw0 = now(); say("taxi waiting from fare " .. money(st().fare)) end)
waitMs(30000)
act(function() say("taxi waited 30 s: fare " .. money(st().fare)) end)
waitMs(31500)
act(function()
    local s = st()
    say(string.format("taxi waited %d s: fare %s", math.floor((now() - tw0) / 1000), money(s.fare)))
    if money(s.fare) ~= "1.75" then err("taxi a minute's wait gave fare " .. money(s.fare) .. ", want 1.75") end
    shot("taxi_waited")
end)
-- driving, with no keys pressed (the PC may be in use, and the cruise regulator does not pull away from a standstill,
-- Oct 24 final pass): the script pushes the cab along its own heading (BaseVehicle:addImpulse) up to about 25 km/h, and
-- turns it with a small push sideways at its nose, left for half the drive, then right. About a quarter mile in all,
-- so a fifth must click on the meter. The push doubles each second while the cab barely moves (its scale is the
-- physics engine's), then holds.
local drive = { log = 0, frames = {}, seen1 = false, seen2 = false, maxKmh = 0, fare0 = nil, miles0 = nil, F = 50, at = 0 }
local function trip() return dash()._trips[cur:getId()] or {} end
local fwd, zero = nil, nil
-- the heading in the physics frame, and a ground-plane perpendicular to it (the up axis is the one the heading
-- hardly uses)
local function axes(v)
    fwd = fwd or Vector3f.new(); zero = zero or Vector3f.new(0, 0, 0)
    v:getForwardVector(fwd)
    local fx, fy, fz = fwd:x(), fwd:y(), fwd:z()
    if math.abs(fy) <= math.abs(fz) then return fx, fy, fz, fz, 0, -fx end
    return fx, fy, fz, fy, -fx, 0
end
local function driveTick(phase, turn, brake)
    return function(ms)
        if not ok() then return end
        local v = cur
        local s = st(); if not s then return end
        pcall(function() v:setPhysicsActive(true) end)
        local okA, fx, fy, fz, lx, ly, lz = pcall(axes, v)
        if okA then
            if brake then
                if s.speed > 1 then local F = drive.F; pcall(function() v:addImpulse(Vector3f.new(-fx * F, -fy * F, -fz * F), zero) end) end
            else
                if s.speed < 25 then local F = drive.F; pcall(function() v:addImpulse(Vector3f.new(fx * F, fy * F, fz * F), zero) end) end
                if turn ~= 0 and s.speed > 6 then
                    local T = drive.F * 0.15 * turn
                    pcall(function() v:addImpulse(Vector3f.new(lx * T, ly * T, lz * T), Vector3f.new(fx * 2, fy * 2, fz * 2)) end)
                end
            end
        end
        if not brake and ms - drive.at >= 1000 then
            drive.at = ms
            if s.speed < 5 then drive.F = math.min(drive.F * 2, 50000) end
        end
        drive.fare0 = drive.fare0 or s.fare
        drive.miles0 = drive.miles0 or trip().fareMiles
        if s.speed > drive.maxKmh then drive.maxKmh = s.speed end
        local f = s.hula
        if drive.frames[#drive.frames] ~= f then
            drive.frames[#drive.frames + 1] = f; drive.since = ms
            -- her first frame of each sway, as the player first sees it (the dash asks for its pictures when it first
            -- shows the car, so a frame's picture is ready before it is needed)
            if f == 1 and not drive.first1 then drive.first1 = true; shot("taxi_hula1_first") end
            if f == 2 and not drive.first2 then drive.first2 = true; shot("taxi_hula2_first") end
        end
        -- (the picture once the frame has held 300 ms: a shot on its first frame can catch a picture still loading)
        if f == 1 and not drive.seen1 and ms - (drive.since or ms) >= 300 then drive.seen1 = true; shot("taxi_hula1") end
        if f == 2 and not drive.seen2 and ms - (drive.since or ms) >= 300 then drive.seen2 = true; shot("taxi_hula2") end
        if ms - drive.log >= 1000 then
            drive.log = ms
            local H = dash()._hulaS
            say(string.format("taxi drive %s t=%d push=%d fwd=%s kmh=%.1f yaw=%.2f hula=%s fare=%s miles=%.3f wait=%ds heading=%s",
                phase, math.floor(ms / 1000), drive.F, okA and string.format("%.2f,%.2f,%.2f", fx, fy, fz) or tostring(fx),
                s.speed, H and H.yaw or 0, tostring(f), money(s.fare), trip().fareMiles or -1,
                math.floor((trip().waitMs or 0) / 1000), tostring(H and H.ang)))
        end
    end
end
-- the meter's distance starts at 0.19 mi (a QA seed, logged): the drive is about 0.07 mi before it meets a grandstand,
-- and the first fifth of a mile must click inside it
act(function()
    local t = trip(); if not t.meterOn then return end
    t.fareMiles = 0.19
    say("taxi QA seed: the meter's distance set to 0.19 mi, fare " .. money(st().fare))
end)
during(25000, driveTick("left", 1))
act(function() drive.log = 0 end)
during(25000, driveTick("right", -1))
act(function() drive.log = 0 end)
during(6000, driveTick("brake", 0, true))
act(function()
    local s = st()
    say(string.format("taxi drove: max %.1f km/h, hula frames %s, fare %s -> %s, fifths %.3f -> %.3f mi", drive.maxKmh,
        table.concat(drive.frames, ","), money(drive.fare0), money(s.fare), drive.miles0 or -1, trip().fareMiles or -1))
    if drive.maxKmh < 6 then err("taxi never moved") end
    -- (both ways: each sway frame shown at least once; a flick can be shorter than the 300 ms the second picture waits)
    if not (drive.first1 and drive.first2) then err("taxi hula did not sway both ways (1=" .. tostring(drive.first1) .. " 2=" .. tostring(drive.first2) .. ")") end
    if (trip().fareMiles or 0) <= (drive.miles0 or 0) then err("taxi meter counted no distance while driving") end
    if math.floor((trip().fareMiles or 0) * 5) < 1 then err("taxi drove less than a fifth of a mile: no distance click to see")
    elseif (tonumber(s.fare) or 0) < (tonumber(drive.fare0) or 0) + 0.25 then err("taxi fare did not climb by a fifth's rate")
    else say("taxi PASS the first fifth of a mile clicked: fare " .. money(drive.fare0) .. " -> " .. money(s.fare)) end
end)
waitFor(function() local s = st(); return s and s.speed < 1 end, 15000)
waitMs(500)
act(function() if ok() then local s = st(); say("taxi stopped: hula=" .. tostring(s.hula)); shot("taxi_stopped") end end)
-- night, with the flag down and the hula girl on the dash
act(function() D.qaNight = 1; D.qaLit = true end)
waitMs(400)
act(function() shot("taxi_night_lit") end)
waitMs(200)
act(function() D.qaLit = false end)
waitMs(400)
act(function() shot("taxi_night_dark"); D.qaNight = nil; D.qaLit = nil end)
-- the key out: the flag goes up, the meter clears
act(function() if ok() then click("ignition") end end)                  -- shut off
waitFor(function() local s = st(); return s and not s.running and s.keyPos == "off" end, 6000)
waitMs(300)
act(function() if ok() then click("ignition", true) end end)            -- the key out
waitMs(400)
act(function()
    if not ok() then return end
    local s = st()
    say(string.format("taxi key out: keysIn=%s meterOn=%s fare=%s extras=%s", tostring(s.keysIn), tostring(s.meterOn), money(s.fare), money(s.fareExtra)))
    if s.meterOn or money(s.fare) ~= "0.00" then err("taxi key out did not clear the meter") end
    shot("taxi_keyout")
end)
act(function() leave() end)
waitMs(300)

-- ===================================================================== night: van (plain, tray open) and ambulance
for _, e in ipairs({ { "van", "Base.Van" }, { "ambulance", "Base.VanAmbulance" } }) do
    local n, script = e[1], e[2]
    local ok2 = stage("night_" .. n, script)
    act(function() if ok2() then click("ignition"); local s = st(); if s and not s.lights then click("lights") end end end)
    waitMs(300)
    act(function() if ok2() and st().vanTray and not st().ashIsOpen then click("ash") end end)
    waitMs(200)
    act(function() if ok2() then D.qaNight = 1; D.qaLit = true end end)
    waitMs(400)
    act(function() if ok2() then shot("night_" .. n .. "_lit") end end)
    waitMs(200)
    act(function() D.qaLit = false end)
    waitMs(400)
    act(function() if ok2() then shot("night_" .. n .. "_dark") end; D.qaNight = nil; D.qaLit = nil end)
    act(function() leave() end)
    waitMs(300)
end

-- ===================================================================== reload: two Nyalas stay for the next run
-- (not when the reload check already ran in this game, zedqa_dash_r6_reload.txt: it sets ZeDQA_R6_NoKeep)
if not ZeDQA_R6_NoKeep then
goSite()   -- (back to the strip's middle: the taxi's drive carried the character up the strip)
local persist = {}
for i, which in ipairs({ "untouched", "clicked" }) do
    local okP = stage("keep_" .. which, "Base.CarNormal")
    act(function()
        if not okP() then return end
        local s = st()
        local rec = { which = which, key = cur:getKeyId(), open = s.ashIsOpen, level = s.ashOpen, x = math.floor(cur:getX()), y = math.floor(cur:getY()) }
        if which == "clicked" then
            click("ash")
        end
        persist[#persist + 1] = rec
    end)
    waitMs(300)
    act(function()
        if not okP() then return end
        local s = st()
        local rec = persist[#persist]
        rec.open, rec.level = s.ashIsOpen, s.ashOpen
        rec.md = tostring(cur:getModData().ZeD_ash)
        say(string.format("keep %s key=%s open=%s level=%s md=%s at %d,%d", rec.which, tostring(rec.key), tostring(rec.open), tostring(rec.level),
            rec.md, math.floor(cur:getX()), math.floor(cur:getY())))
        shot("keep_" .. which)
        leave(true)
    end)
    waitMs(500)
end
act(function()
    local w = getFileWriter("zedqa_r6_persist.txt", true, false)
    for _, r in ipairs(persist) do w:write(string.format("%s %s %s %s %d %d\n", r.which, tostring(r.key), tostring(r.open), tostring(r.level), r.x or SITE.x, r.y or SITE.y)) end
    w:close()
    say("persist file written: " .. #persist .. " cars")
end)
else
    act(function() say("keep: skipped (the reload check ran in this game)") end)
end

act(function() leave() end)
goHome()
act(function()
    D.qaRiders, D.qaNight, D.qaLit = nil, nil, nil
    say("errors=" .. errs)
    say("DONE")
end)

local function tick()
    if not Q[qi] then Events.OnTick.Remove(tick); return end
    local ok_, r = pcall(Q[qi])
    if not ok_ then say("step error: " .. tostring(r)); r = true end
    if r then qi = qi + 1 end
end
Events.OnTick.Add(tick)
