-- ZeDUI/tools/qa/zedqa_b8_dash.lua  (Nov 7 2026, QA; tag b8dk): the Simple dash strip's speed follows the game's measurement option
-- (the outside review of beta 7, item 3; Build's 13f362ac, D.plainSpeed).
--   pure    D.plainSpeed on a made-up state: 60 mph reads "60" with the mph key, 96.6 km/h reads "97" with the km/h key (EN: "km/h").
--   drawn   a car on the drag strip, the dash set to Simple, the game's units set to Metric then Imperial: the strip passes the units
--           to D.plainSpeed each frame (recorded), the figure it gets, and a picture each (zqa_b8_dk_metric.png, zqa_b8_dk_imperial.png).
--           The car stands still (0 km/h and 0 mph): the unit, not the number, is what is checked.
-- Restores the game's units option, the dash look, and removes the car and its key. If the car cannot be staged the drawn part says
-- NOTE and the pure part still counts. grep "ZEDQA b8dk".
local TAG = "b8dk"
local p = getPlayer()
local D = ZeD.Dashboard
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end
if getGameSpeed() == 0 then setGameSpeed(1) end
local Q = { pass = 0, fail = 0 }
local function verdict(ok, what)
    if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what)
    return ok
end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_b8_dk_" .. name .. ".png") end) end

local steps, qi = {}, 1
local function step(f) steps[#steps + 1] = f end
local function now() return getTimestampMs() end
local function act(f) step(function() f(); return true end) end
local function waitMs(ms) local t0 = nil; step(function() t0 = t0 or now(); if now() - t0 >= ms then t0 = nil; return true end end) end
local function waitFor(cond, ms, onTimeout)
    local t0 = nil
    step(function()
        t0 = t0 or now()
        if cond() then t0 = nil; return true end
        if now() - t0 >= ms then t0 = nil; if onTimeout then onTimeout() end; return true end
    end)
end

-- pure
act(function()
    verdict(type(D.plainSpeed) == "function", "D.plainSpeed exists")
    if type(D.plainSpeed) ~= "function" then return end
    local st = { speed_mph = 60, speed_kmh = 96.6 }
    local v1, k1 = D.plainSpeed(st, false)
    local v2, k2 = D.plainSpeed(st, true)
    verdict(v1 == "60" and k1 == "UI_ZeD_DashPlain_Mph", "Imperial: 60 mph reads " .. tostring(v1) .. " with " .. tostring(k1))
    verdict(v2 == "97" and k2 == "UI_ZeD_DashPlain_Kmh", "Metric: 96.6 km/h reads " .. tostring(v2) .. " with " .. tostring(k2))
    local unit = ZeD.tr("UI_ZeD_DashPlain_Kmh")
    say("the km/h key reads '" .. tostring(unit) .. "' in this language, the mph key '" .. tostring(ZeD.tr("UI_ZeD_DashPlain_Mph")) .. "'")
    verdict(unit ~= "UI_ZeD_DashPlain_Kmh" and unit ~= "", "the km/h key has a translation")
end)

-- a car (as zedqa_dash_odo.lua: a settled car on the strip, the key in the bag, seated)
local cur, curKey, tries = nil, nil, 0
local OFFS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 } }
local settledSince = nil
local function carSettled(v)
    local removed, sq, chunk, dist = false, nil, nil, 999
    pcall(function() removed = v:isRemovedFromWorld() end)
    pcall(function() sq = v:getSquare() end)
    pcall(function() chunk = v:getChunk() end)
    pcall(function() dist = v:DistTo(p) end)
    if removed or not sq or not chunk or dist > 12 then settledSince = nil; return false end
    settledSince = settledSince or now()
    return now() - settledSince >= 1500
end
local function spawn(script)
    while tries < #OFFS do
        tries = tries + 1
        local o = OFFS[tries]
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
local function leave()
    local v = p:getVehicle()
    if v then pcall(function() v:exit(p) end); triggerEvent("OnExitVehicle", p) end
    if cur then pcall(function() cur:permanentlyRemove() end) end
    if curKey then pcall(function() p:getInventory():Remove(curKey) end) end
    cur, curKey = nil, nil
end

local keepFmt, keepStyle, calls = nil, nil, { n = 0 }
local realPlain = D.plainSpeed
local seated = false
act(function()
    if not spawn("Base.CarNormal") then say("NOTE no free square for the car: the drawn part is skipped"); return end
end)
waitFor(function() return cur == nil or carSettled(cur) end, 8000, function() say("NOTE the car never settled: the drawn part is skipped") end)
act(function()
    if not cur or not carSettled(cur) then return end
    local v = cur
    pcall(function() v:repair() end)
    pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
    pcall(function() if v:isKeysInIgnition() then v:setKeysInIgnition(false) end end)
    pcall(function() curKey = p:getInventory():AddItem(v:createVehicleKey()) end)
    pcall(function() v:enter(0, p) end)
    if p:getVehicle() then triggerEvent("OnEnterVehicle", p); seated = true else say("NOTE could not enter the car: the drawn part is skipped") end
end)
waitMs(1500)
act(function()
    if not seated then return end
    keepStyle = ZeD.Settings.dashStyleOption:getValue()
    pcall(function() keepFmt = getCore():getOptionMeasurementFormat() end)
    ZeD.Settings.dashStyleOption:setValue(2)   -- Simple
    D.plainSpeed = function(st, metric)
        calls.n = calls.n + 1; calls.metric = metric
        return realPlain(st, metric)
    end
    pcall(function() getCore():setOptionMeasurementFormat("Metric") end)
    calls.n = 0
end)
-- the unit is read from the option every second or so (UNITS_MS): give it time
waitFor(function() return not seated or (calls.n > 0 and calls.metric == true) end, 6000, function()
    say("NOTE the strip never asked D.plainSpeed with Metric on within 6 s (Simple " .. tostring(D.simple()) .. ", calls " .. calls.n .. ")")
end)
act(function()
    if not seated then return end
    verdict(calls.n > 0 and calls.metric == true, "Metric: the Simple strip asks for km/h (" .. calls.n .. " calls, metric " .. tostring(calls.metric) .. ")")
    shot("metric")
    pcall(function() getCore():setOptionMeasurementFormat("Imperial") end)
    calls.n = 0
end)
waitFor(function() return not seated or (calls.n > 0 and calls.metric == false) end, 6000, function()
    say("NOTE the strip never asked D.plainSpeed with Imperial on within 6 s")
end)
act(function()
    if not seated then return end
    verdict(calls.n > 0 and calls.metric == false, "Imperial: the Simple strip asks for mph (" .. calls.n .. " calls, metric " .. tostring(calls.metric) .. ")")
    shot("imperial")
end)
act(function()
    D.plainSpeed = realPlain
    if keepFmt then pcall(function() getCore():setOptionMeasurementFormat(keepFmt) end) end
    if keepStyle then ZeD.Settings.dashStyleOption:setValue(keepStyle) end
    say("units put back: " .. tostring(getCore():getOptionMeasurementFormat()) .. ", dash look " .. tostring(ZeD.Settings.dashStyleOption:getValue()))
    leave()
end)
waitMs(1500)
act(function()
    say("summary: " .. Q.pass .. " PASS, " .. Q.fail .. " FAIL")
    say("DONE")
end)

local function onTick()
    if not steps[qi] then Events.OnTick.Remove(onTick); return end
    local ok, r = pcall(steps[qi])
    if not ok then
        say("ERR step " .. qi .. ": " .. tostring(r))
        -- put everything back at once if a step throws
        D.plainSpeed = realPlain
        if keepFmt then pcall(function() getCore():setOptionMeasurementFormat(keepFmt) end) end
        if keepStyle then pcall(function() ZeD.Settings.dashStyleOption:setValue(keepStyle) end) end
        r = true
    end
    if r then qi = qi + 1 end
end
Events.OnTick.Add(onTick)
