-- ZeDUI/tools/qa/zedqa_roadworthy.lua  (Nov 6 2026, QA): ZeD's dash reading Vehicle Kit Library and Roadworthy, in the game. Both
-- mods on: zedqa_mods_run.ps1 -ModList roadworthy_mods.txt -Mode fullscreen4k -Manifest .../roadworthy_manifest.txt
-- Without them it says SKIP. vskdash_sim.lua proves the logic and that nothing changes without the mods; this is the part only
-- the game can show: Roadworthy's real numbers reaching the parts, and how they look.
--   elite     DASH ELITE (ModernCar), engine running: the needles equal Roadworthy's gauges, the LCD is its odometer's last
--             four figures, the scale, the gear label. No hot lamp on this plate: hot shows on the needle, Simple lists it.
--   hot       Nyala (CarNormal), its engine held at 125, 132 and 142 through Roadworthy's own setTemperature (the Dev panel's
--             way): amber, red, red blinking; the needle climbs; the engine role at red. Then 146: the engine stops and the
--             dash stays lit with the ignition held (SKIP when it does not stop in time).
--   lamps     Roadworthy's lamps read back against the plate's, the seat belt among them
--   simple    a lamp, a gauge and a readout registered here through the public VSK.Dashboard.register, plus a provider that
--             throws: on Full nothing new lights, on Simple each is listed by name; the throwing one retires and the dash runs on
-- Screenshots zqa_rw_*.png; grep "ZEDQA rw". The speed reading needs the car driven: by hand, 100 on the needle at 65 game km/h
-- (the World Scale default). The car is removed and every provider unregistered at the end.
local p = getPlayer(); local D = ZeD.Dashboard
local TAG = "rw"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if getGameSpeed() == 0 then setGameSpeed(1) end
local V = ZeD.ModSupport and ZeD.ModSupport.VSKDash
if not (D and D.applyPublished and V) then say("ERR the new code is not loaded"); say("DONE"); return end
local VD = VSK and VSK.Dashboard
if not (VD and RDO and RDO.Maint and RDO.Maint.setTemperature) then say("SKIP Vehicle Kit Library and Roadworthy are not both on"); say("DONE"); return end
local M = RDO.Maint
if ZEDQA_HOME then ZEDQA_HOME(TAG) end

local errs = 0
local function err(s) errs = errs + 1; say("ERR " .. s) end
local function check(ok, what) if ok then say("PASS " .. what) else err("FAIL " .. what) end; return ok end
local function near(a, b, eps) return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (eps or 0.02) end

local Q, qi = {}, 1
local function step(f) Q[#Q + 1] = f end
local function now() return getTimestampMs() end
local function waitMs(ms) local t0 = nil; step(function() t0 = t0 or now(); if now() - t0 >= ms then t0 = nil; return true end end) end
local function act(f) step(function() f(); return true end) end
local function during(ms, f) local t0 = nil; step(function() t0 = t0 or now(); f(now() - t0); if now() - t0 >= ms then t0 = nil; return true end end) end
local function waitFor(cond, ms, onTimeout)
    local t0 = nil
    step(function()
        t0 = t0 or now()
        if cond() then t0 = nil; return true end
        if now() - t0 >= ms then t0 = nil; if onTimeout then onTimeout() end; return true end
    end)
end
local function dash() return D.getInstance() end
local function st() local d = dash(); return d and d._st end
local function pub() local s = st(); return s and s.pub end
local function shot(case) pcall(function() getCore():TakeFullScreenshot("zqa_rw_" .. case .. ".png") end) end
local function click(id)
    local d = dash(); if not d then return false end
    for _, hr in ipairs(d._hit or {}) do
        if hr.id == id then return d:onMouseDown(hr.x + math.floor(hr.w / 2), hr.y + math.floor(hr.h / 2)) and true or false end
    end
    return false
end

-- staging, as zedqa_dash_lamps.lua (its notes on what each wait is for)
local OFFS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 } }
local cur, curKey, tries, rot = nil, nil, 0, 0
local readySince = nil
local function carSettled(v)
    local sq, chunk, removed, dist = nil, nil, false, 999
    pcall(function() removed = v:isRemovedFromWorld() end)
    pcall(function() sq = v:getSquare() end)
    pcall(function() chunk = sq and sq:getChunk() end)
    pcall(function() dist = v:DistTo(p) end)
    if removed or not (sq and chunk and dist <= 12) then readySince = nil; return false end
    readySince = readySince or now()
    return now() - readySince >= 1500
end
local function spawn(script)
    while tries < #OFFS do
        tries = tries + 1
        local o = OFFS[(rot + tries - 1) % 4 + 1]
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
    local v = p:getVehicle(); if v then pcall(function() v:exit(p) end); triggerEvent("OnExitVehicle", p) end
    if cur then pcall(function() cur:permanentlyRemove() end) end
    if curKey then pcall(function() p:getInventory():Remove(curKey) end) end
    cur, curKey = nil, nil
end
local function stage(n, script)
    local failed = false
    act(function() leave() end)
    waitMs(1500)
    act(function()
        tries = 0; rot = rot + 1; readySince = nil
        if not spawn(script) then failed = true; err(n .. " spawn failed " .. script) end
    end)
    waitFor(function() return failed or (cur and carSettled(cur)) end, 8000)
    act(function()
        if failed or not cur then return end
        local v = cur
        pcall(function() v:repair() end)
        pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
        pcall(function()
            local it = v:getPartById("Battery"):getInventoryItem()
            pcall(function() it:setCurrentUsesFloat(1.0) end); pcall(function() it:setUsedDelta(1.0) end)
        end)
        readySince = nil
    end)
    waitFor(function() return failed or (cur and carSettled(cur)) end, 8000)
    act(function()
        if failed or not cur then return end
        local v = cur
        pcall(function() if v:isKeysInIgnition() then v:setKeysInIgnition(false) end end)
        pcall(function() curKey = p:getInventory():AddItem(v:createVehicleKey()) end)
        pcall(function() v:enter(0, p) end)
        if p:getVehicle() then triggerEvent("OnEnterVehicle", p) else err(n .. " could not enter " .. script) end
    end)
    waitMs(700)
end
local function startEngine(n)
    local t0, n_ = nil, 0
    act(function() t0 = now(); click("ignition") end)
    waitFor(function()
        local s = st()
        if s and s.running then return true end
        if s and s.keyPos == "off" and not s.cranking and now() - t0 > 1500 then
            n_ = n_ + 1
            if n_ >= 5 then return true end
            t0 = now(); click("ignition")
        end
        return false
    end, 25000, function() err(n .. " engine never ran") end)
    waitMs(1200)
end
local function hold(temp, ms, f) during(ms, function(t) M.setTemperature(cur, temp); if f then f(t) end end) end
local function simple(on) ZeD.Settings.dashStyleOption:setValue(on and 2 or 1) end

-- ---------------------------------------------------------------------------- elite
stage("elite", "Base.ModernCar")
startEngine("elite")
waitMs(1000)
act(function()
    local s, u = st(), pub()
    if not check(u ~= nil, "the dash reads the library") then return end
    local tg, og = VD.get(cur, "rdo.temp_gauge"), VD.get(cur, "rdo.oil_gauge")
    check(tg and near(u.temp, tg.value), "temperature is Roadworthy's gauge: " .. tostring(u.temp) .. " / " .. tostring(tg and tg.value))
    check(og and near(u.oil, og.value, 0.1), "oil is Roadworthy's gauge: " .. tostring(u.oil) .. " / " .. tostring(og and og.value))
    local S = VSK.Scale.get()
    say("World Scale " .. tostring(S) .. ", speed multiplier " .. tostring(u.speedK))
    check(near((u.speedK or 1) * S, 1, 0.001), "the speed multiplier is the scale's")
    local km = VD.odometer(cur)
    if check(type(km) == "number", "Roadworthy's odometer is published: " .. tostring(km) .. " km") then
        local miles = math.floor(km / 1.609344)
        check(math.abs(s.odoMiles - miles) <= 1, "Simple's figure is the odometer: " .. tostring(s.odoMiles))
        check(math.abs(s.odo - (miles - math.floor(miles / 10000) * 10000)) <= 1, "the LCD is its last four figures: " .. tostring(s.odo))
    end
    local label = VD.gearLabel(cur)
    say("gear label " .. tostring(label) .. ", plate letter " .. tostring(s.gearSel))
    check(s.gearPub == label, "the gear label reached the dash")
    shot("1_elite")
end)

-- ---------------------------------------------------------------------------- hot
stage("hot", "Base.CarNormal")
startEngine("hot")
local needle0, seen = nil, {}
act(function() needle0 = st() and st().temp end)
hold(125, 15000)
act(function()
    local s, u = st(), pub()
    check(s.tempLamp == D.LAMP_COLOR.worn, "125: the hot lamp is amber: " .. tostring(s.tempLamp))
    check(u and near(u.temp, 85 / 110, 0.03), "125: the published needle: " .. tostring(u and u.temp))
    check(s.temp > (needle0 or 0) + 0.05, "125: the needle climbs: " .. tostring(needle0) .. " -> " .. tostring(s.temp))
    shot("2_amber")
end)
hold(132, 1500)
act(function()
    local s, u = st(), pub()
    check(s.tempLamp == D.LAMP_COLOR.poor, "132: the hot lamp is red: " .. tostring(s.tempLamp))
    check(u and u.lamps.engLamp and u.lamps.engLamp.rank == 3, "132: the engine lamp's role is red with it (checkEngine)")
    shot("3_red")
end)
hold(142, 4000, function() seen[tostring(st() and st().tempLamp)] = true end)
act(function()
    check(seen[D.LAMP_COLOR.poor] and seen["false"], "142: red and dark, blinking")
    shot("4_blink")
end)
local stopped = false
hold(146, 12000, function() stopped = stopped or not (st() and st().running) end)
act(function()
    if not stopped then say("SKIP 146: the engine did not stop in 12 s"); return end
    local s = st()
    check(pub() ~= nil and s.power == true, "the engine died: the dash stays lit")
    shot("5_stalled")
end)

-- ---------------------------------------------------------------------------- lamps
act(function() if cur then M.setTemperature(cur, 90) end end)
stage("lamps", "Base.CarNormal")
startEngine("lamps")
waitMs(800)
act(function()
    local u, s = pub(), st()
    if not check(u ~= nil, "lamps: the dash reads the library") then return end
    for _, e in ipairs(u.list) do
        say(string.format("lamp %s (%s) role=%s on=%s rank=%s", e.id, e.name, tostring(e.role), tostring(e.on), tostring(e.rank)))
        local r = VD.get(cur, e.id)
        check(r ~= nil and (r.level == "warn" or r.level == "crit" or r.lit == true) == e.on, e.id .. " as Roadworthy has it: " .. tostring(r and r.level))
    end
    local b = VD.get(cur, "rdo.belt")
    if b and b.level == "crit" then check(s.beltLamp == D.LAMP_COLOR.poor, "unbuckled: the belt lamp is red") end
    shot("6_lamps")
end)

-- ---------------------------------------------------------------------------- simple
local IDS = { "zedqa.lamp", "zedqa.gauge", "zedqa.text", "zedqa.throws" }
local before = nil
act(function()
    before = st() and st().genLamp
    VD.register({ id = "zedqa.lamp", kind = "lamp", order = 60, icon = "tire", name = "QA tires", read = function() return { level = "warn" } end })
    VD.register({ id = "zedqa.gauge", kind = "gauge", order = 61, name = "QA boost", read = function() return { level = "ok", value = 0.4 } end })
    VD.register({ id = "zedqa.text", kind = "readout", order = 62, name = "QA limiter", read = function() return { level = "ok", text = "55 mph" } end })
    VD.register({ id = "zedqa.throws", kind = "lamp", order = 63, name = "QA throws", read = function() error("on purpose") end })
end)
waitMs(1500)
act(function()
    local s, u = st(), pub()
    local listed = false
    for _, e in ipairs(u.list) do if e.id == "zedqa.lamp" then listed = e.on end end
    check(listed, "a lamp with no spot is published and lit")
    check(s.genLamp == before, "Full: nothing on the plate took it (the constant is off)")
    shot("7_full_unpainted")
    simple(true)
end)
waitMs(1200)
act(function()
    shot("8_simple")   -- Simple lists QA tires, QA boost: 40%, QA limiter: 55 mph; Trip and the whole odometer in the cells
    check(VD.providers["zedqa.throws"] == nil or VD.providers["zedqa.throws"].disabled == true, "the throwing provider has retired")
    check(pub() ~= nil, "the dash runs on")
    simple(false)
    for _, id in ipairs(IDS) do VD.unregister(id) end
end)

act(function() leave() end)
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
