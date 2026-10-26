-- ZeDUI/tools/qa/zedqa_dash_lamps.lua  (Oct 26 2026)
-- The dash lamps by condition and their hover text (mockup zed_belt_ammo_dash_v1, "Warning only" and "Chip above
-- the lamp"; approved Oct 26 2026), on a DASH ELITE (ModernCar) at the Irvington Speedway's drag strip:
--   good    engine running, every part in good order: the battery and engine lamps dark, the heater's light its green
--   worn    engine 34% (amber), battery 52% with its charge at 18% (red: the weaker), heater 8% (red, blinking),
--           right headlight 40%: each lamp's colour, the blink seen both ways, the hover chip over each lamp
--   check   key on, engine off: the bulb check lights every lamp in its own colour; the hover still answers
--   designs every design's lamps have their hover places (battery, engine, headlights; the heater where it has controls)
-- The pointer is stood in on the dash (its own getMouseX / getMouseY / isMouseOver): a script cannot move a
-- fullscreen game's pointer. The car is removed and the character goes back home. Screenshots zqa_dl_*.png;
-- grep "ZEDQA dl".
local p = getPlayer(); local D = ZeD.Dashboard; local DP = ZeD.DashPx
local TAG = "dl"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if getGameSpeed() == 0 then setGameSpeed(1) end
local errs = 0
local function err(s) errs = errs + 1; say("ERR " .. s) end
local function check(ok, what) if ok then say("PASS " .. what) else err("FAIL " .. what) end; return ok end
if not (D and D.lampText and D._lampZones) then say("ERR the new code is not loaded"); say("DONE"); return end

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
local function shot(case) pcall(function() getCore():TakeFullScreenshot("zqa_dl_" .. case .. ".png") end) end

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
-- (ZeDDashLampsHome) and it goes back there at the end, so the other QA scripts find it where they expect.
local SITE = { x = 925, y = 13040 }   -- mid-strip, between the two grandstands (x 875-893 and 964-977)
local pmd = p:getModData()
pmd.ZeDDashLampsHome = pmd.ZeDDashLampsHome or { x = p:getX(), y = p:getY(), z = p:getZ() }
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
        say(string.format("at the speedway %d,%d (home %d,%d)", math.floor(p:getX()), math.floor(p:getY()), math.floor(pmd.ZeDDashLampsHome.x), math.floor(pmd.ZeDDashLampsHome.y)))
        pcall(function() getCore():TakeFullScreenshot("zqa_" .. TAG .. "_site.png") end)
    end)
end
local function goHome()
    act(function() local h = pmd.ZeDDashLampsHome; if h then tp(h.x, h.y, h.z) end end)
    waitFor(function() local h = pmd.ZeDDashLampsHome; return not h or loadedAround(h.x, h.y) end, 40000)
    act(function() pmd.ZeDDashLampsHome = nil; say(string.format("back home %d,%d", math.floor(p:getX()), math.floor(p:getY()))) end)
end

-- ===================================================================== the test
local function partOf(id) local v = cur; return v and v:getPartById(id) end
local function setCond(id, c) pcall(function() partOf(id):setCondition(c) end) end
local function setCharge(f)
    pcall(function()
        local it = partOf("Battery"):getInventoryItem()
        pcall(function() it:setCurrentUsesFloat(f) end); pcall(function() it:setUsedDelta(f) end)
    end)
end
local function design() local d = dash(); return d and DP.designs[d._designId] end
local function zoneOf(id) for _, z in ipairs(D._lampZones(design()) or {}) do if z.id == id then return z end end end
-- the pointer stood in over a lamp's hover place (nil: let go)
local function pointAt(id)
    local d = dash(); if not d then return end
    local z = id and zoneOf(id)
    if z then
        local k = d._s or 1
        local x, y = math.floor((z.x + z.w / 2) * k), math.floor((z.y + z.h / 2) * k)
        d.getMouseX = function() return x end
        d.getMouseY = function() return y end
        d.isMouseOver = function() return true end
    else
        d.getMouseX, d.getMouseY, d.isMouseOver = nil, nil, nil
    end
end
local function lamps(tag)
    local s = st() or {}
    say(string.format("%s: running=%s check=%s genLamp=%s engLamp=%s heatOn=%s battTone=%s engTone=%s heaterTone=%s batt=%.2f battCond=%s engine=%s heater=%s hl=%s/%s",
        tag, tostring(s.running), tostring(s.check), tostring(s.genLamp), tostring(s.engLamp), tostring(s.heatOn), tostring(s.battTone),
        tostring(s.engTone), tostring(s.heaterTone), s.battRaw or -1, tostring(s.battCond), tostring(s.engineCond), tostring(s.heaterCond),
        tostring(s.hlL), tostring(s.hlR)))
    return s
end
local function hover(id, case)
    act(function() pointAt(id) end)
    waitMs(250)
    act(function()
        local d = dash()
        local name, rest = D.lampText(id, st() or {})
        check(d and d._lampHov == id, case .. ": the pointer over the " .. id .. " lamp shows its chip (" .. tostring(d and d._lampHov) .. ": " .. tostring(name) .. " | " .. tostring(rest) .. ")")
        shot(case .. "_" .. id)
    end)
end

-- every design: the lamps' hover places
act(function()
    local n, miss = 0, {}
    for id, des in pairs(DP.designs) do
        local z = D._lampZones(des)
        local have = {}
        for _, q in ipairs(z) do have[q.id] = true end
        local lampsOn = {}
        for _, pt in ipairs(des.parts or {}) do if pt.t == "lamp" then lampsOn[pt.src] = true end end
        for src, zid in pairs({ genLamp = "batt", engLamp = "eng", hiBeam = "head" }) do
            if lampsOn[src] and not have[zid] then miss[#miss + 1] = id .. ":" .. zid end
        end
        n = n + 1
        say(string.format("design %s: %s%s%s%s", id, have.batt and "batt " or "", have.eng and "eng " or "", have.head and "head " or "", have.heat and "heat" or ""))
    end
    check(#miss == 0, n .. " designs: every battery, engine and headlight lamp has its hover place (" .. table.concat(miss, ", ") .. ")")
end)

goSite()
local ready = stage("elite", "Base.ModernCar")
startEngine("elite")
act(function() if st() and not st().heaterOn then click("heat") end end)
waitMs(1500)
-- 1. good
act(function()
    local s = lamps("good")
    check(s.running == true, "good: the engine runs")
    check(s.genLamp == false and s.engLamp == false, "good: the battery and engine lamps dark")
    check(s.heaterOn ~= true or s.heatOn == true, "good: the heater's light its own green (" .. tostring(s.heatOn) .. ")")
    shot("1_good")
end)
hover("batt", "1_good")
hover("heat", "1_good")
-- 2. worn
act(function()
    setCond("Engine", 34); setCond("Battery", 52); setCharge(0.18); setCond("Heater", 8); setCond("HeadlightRight", 40); setCond("HeadlightLeft", 85)
end)
waitMs(800)
local blinkSeen = {}
during(1600, function() local s = st(); if s then blinkSeen[tostring(s.heatOn)] = true end end)
act(function()
    local s = lamps("worn")
    check(s.engLamp == D.LAMP_COLOR.worn, "worn: the engine lamp amber at 34% (" .. tostring(s.engLamp) .. ")")
    check(s.battTone == "poor" and s.genLamp == D.LAMP_COLOR.poor, "worn: the battery lamp red, its charge 18% the weaker (" .. tostring(s.battTone) .. ", " .. tostring(s.genLamp) .. ")")
    local b = {} for k in pairs(blinkSeen) do b[#b + 1] = k end
    if s.heaterOn then
        check(blinkSeen[D.LAMP_COLOR.dead] and blinkSeen["false"], "worn: the heater's light red and blinking at 8% (seen: " .. table.concat(b, ", ") .. ")")
    else
        say("worn: the heater is off (seen " .. table.concat(b, ", ") .. ")")
    end
    shot("2_worn")
end)
hover("batt", "2_worn")
hover("eng", "2_worn")
hover("head", "2_worn")
hover("heat", "2_worn")
act(function()
    local name, rest = D.lampText("head", st())
    check(rest:find("40%", 1, true) ~= nil and rest:find("85%", 1, true) ~= nil, "worn: the headlights' chip gives each one (" .. rest .. ")")
    local n2, r2 = D.lampText("batt", st())
    check(r2:find("52%", 1, true) ~= nil and r2:find("18%", 1, true) ~= nil, "worn: the battery's chip gives its condition and charge (" .. r2 .. ")")
    pointAt(nil)
end)
-- 3. key on, engine off: the bulb check
act(function() click("ignition") end)
waitFor(function() local s = st(); return s and not s.running end, 8000, function() err("the engine never stopped") end)
waitMs(600)
act(function()
    local s = lamps("check")
    if not s.keysIn then pcall(function() cur:setKeysInIgnition(true) end) end
end)
waitMs(400)
act(function()
    local s = lamps("check")
    check(s.check == true and s.genLamp == true and s.engLamp == true, "key on, engine off: the bulb check lights the lamps in their own colours")
    shot("3_check")
end)
hover("eng", "3_check")
act(function() pointAt(nil) end)

act(function() leave() end)
goHome()
act(function()
    say("errors=" .. errs)
    say(errs == 0 and "all checks passed" or (errs .. " failed"))
    say("DONE")
end)

local function tick()
    if not Q[qi] then Events.OnTick.Remove(tick); return end
    local ok_, r = pcall(Q[qi])
    if not ok_ then err("step error: " .. tostring(r)); r = true end
    if r then qi = qi + 1 end
end
Events.OnTick.Add(tick)
say("start")
