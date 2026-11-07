-- ZeDUI/tools/qa/vskdash_sim.lua  (Nov 6 2026, QA): ModSupport/VSKDash.lua and the dash with no game running. The real
-- ZeD_Dashboard.lua, ZeD_Plate.lua, ZeD_PixelParts.lua, DashPx.lua and VSKDash.lua run on Lua 5.1 stubs of the library, a car
-- and a panel that writes down every draw. Vehicle Kit Library is a stub of its published shape (register, poll, gearLabel,
-- odometer, stalled, Scale), written here from its reference page, with providers shaped like Roadworthy's.
--   SAME    with no such mod every dash is exactly today's: the dash with no ModSupport/VSKDash.lua loaded (until Nov 7 2026
--           the dash as it stood before this work, git show BASE) and the dash with it, frame by frame over every design,
--           every car state, Full and Simple, lamps setting on and off: every reading and every draw call equal. Then again
--           with the library there and nobody publishing, and with the library holding a stall that no mod has anything to
--           say about.
--   NEEDLES the temperature and oil needles follow the published gauges and hand back when they go
--   LAMPS   amber, red, blink; each role on each plate: on a plate with the lamp it lights, on one without nothing is drawn and
--           the Simple strip lists it; dark leaves ZeD's own lamp; check engine; the named constant
--   GEAR, ODO, SPEED, STALL as published; made-up values stay where nothing is published
--   PASSENGER the World Scale and the odometer from any seat, and no provider run for a passenger
--   BREAKS  a poll, provider, gear, odometer or scale that throws or lies: ZeD's own value, no error out of the dash
--   SAFE MODE the real watchdog and the real ZeD.logOnce: another mod's failure never trips it
-- What it can't show is the real mods' numbers and how it looks: zedqa_roadworthy.lua, in the game with both mods on.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/vskdash_sim.lua
-- It prints FAIL lines and a last line "vskdash_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]vskdash_sim%.lua$", "")
local BASE = "cad0358e"     -- the commit this work started from (its ZeD_Dashboard.lua is "today's dash")
local CLIENT = ROOT .. "42/media/lua/client/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function near(a, b, eps) return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (eps or 0.001) end

-- ---------------------------------------------------------------------------
-- THE GAME, as far as the dash asks
-- ---------------------------------------------------------------------------
local clock = 1000000
local noop = function() end
local env = { simple = false, lampsOn = false, errors = {} }

local LOG = {}
local function logv(x)
    local t = type(x)
    if t == "number" then return string.format("%.4f", x) end
    if t == "table" then return x.path or x.name or string.format("{%s,%s,%s}", tostring(x.r), tostring(x.g), tostring(x.b)) end
    return tostring(x)
end
local function logger(name)
    return function(_, ...)
        local a = { name }
        for i = 1, select("#", ...) do a[#a + 1] = logv((select(i, ...))) end
        LOG[#LOG + 1] = table.concat(a, " ")
    end
end
local function recorder(fixed)
    return setmetatable(fixed or {}, { __index = function(t, k)
        local f = function(...)
            local a = { k }
            for i = 1, select("#", ...) do
                local x = select(i, ...)
                if type(x) ~= "table" or x.name or x.r then a[#a + 1] = logv(x) end
            end
            LOG[#LOG + 1] = table.concat(a, " ")
        end
        rawset(t, k, f)
        return f
    end })
end

local function installGlobals()
    Events = setmetatable({}, { __index = function() return { Add = noop, Remove = noop } end })
    getTimestampMs = function() return clock end
    getText = function(k) return k end
    getTextOrNull = function() return nil end
    getGameSpeed = function() return 1 end
    getGameTime = function() return { getHour = function() return 10 end, getMinutes = function() return 8 end } end
    getPlayerScreenLeft, getPlayerScreenTop = function() return 0 end, function() return 0 end
    getPlayerScreenWidth, getPlayerScreenHeight = function() return 1920 end, function() return 1080 end
    getPlayerVehicleDashboard = nil
    getCell = function() return nil end
    getCore = function() return { getOptionTemperatureDisplayCelsius = function() return true end, getOptionClock24Hour = function() return true end } end
    instanceof = function() return true end
    isMouseButtonDown = function() return false end
    SandboxVars = {}
    UIFont = {}
    Texture = { getSharedTexture = function(path) return { path = path, isReady = function() return true end } end }
    ISUIHandler = nil
    ZeD_Panel = {}
    ZeD_Panel.__index = ZeD_Panel
    setmetatable(ZeD_Panel, { __index = function(_, k)
        if type(k) == "string" and k:sub(1, 4) == "draw" then return logger(k) end
        return nil
    end })
    function ZeD_Panel:derive() local c = {}; c.__index = c; return setmetatable(c, { __index = ZeD_Panel }) end
    function ZeD_Panel:new(x, y, w, h) return { _x = x, _y = y, _w = w, _h = h } end
    function ZeD_Panel:getX() return self._x end
    function ZeD_Panel:getY() return self._y end
    function ZeD_Panel:getWidth() return self._w end
    function ZeD_Panel:getHeight() return self._h end
    function ZeD_Panel:setX(v) self._x = v end
    function ZeD_Panel:setY(v) self._y = v end
    function ZeD_Panel:setWidth(v) self._w = v end
    function ZeD_Panel:setHeight(v) self._h = v end
    function ZeD_Panel:getMouseX() return -1 end
    function ZeD_Panel:getMouseY() return -1 end
    function ZeD_Panel:isMouseOver() return false end
    function ZeD_Panel:setVisible() end
    function ZeD_Panel:isVisible() return true end
    function ZeD_Panel:initialise() end
    function ZeD_Panel:addToUIManager() end
end

local function installZeD()
    ZeD = { _trGen = 0, ModSupport = nil }
    local defaults = {}
    ZeD.trDefaults = function(t) for k, v in pairs(t) do defaults[k] = v end end
    ZeD.tr = function(key, ...)
        local s = defaults[key] or key
        for i = 1, select("#", ...) do s = string.gsub(s, "%%" .. i, (string.gsub(tostring((select(i, ...))), "%%", "%%%%"))) end
        return s
    end
    ZeD.upper, ZeD.textCase = string.upper, function(s) return s end
    ZeD.logOnce = function(key, msg) env.errors[#env.errors + 1] = tostring(key) .. ": " .. tostring(msg) end
    ZeD.Safe = { on = function() return false end, register = noop }
    ZeD.Settings = { dashSimple = function() return env.simple end, dashLampsOn = function() return env.lampsOn end }
    ZeD.RadioOps = { read = function() return nil end }
    local T = { scale = 1, fontF1 = "F1", fontF2 = "F2", fontF4 = "F4", fillBarH = 8, buttonH = 20, px = function(n) return n end }
    ZeD.T = setmetatable(T, { __index = function(t, k)
        local c = { r = 0.5, g = 0.5, b = 0.5, a = 1, name = k }
        rawset(t, k, c)
        return c
    end })
    ZeD.TM = { getFontHeight = function() return 10 end, MeasureStringX = function(_, _, s) return #tostring(s) * 6 end }
    ZeD.Atoms = recorder({ mouseIn = function() return false end })
    ZeD.Molecules = recorder({ buttonW = function(s) return #tostring(s) * 6 + 20 end })
    ZeD.Surface = recorder()
end

local REAL = { ["ZeD/DashPx"] = true, ["ZeD/ZeD_PixelParts"] = true, ["ZeD/PixelFonts"] = true,   -- (PixelFontsExt: the game's wide chars)
               ["ZeD/ZeD_Plate"] = true }
local byteChar = string.char
string.char = function(...)     -- (the game's strings are wide; a wide char is one "?" here)
    local out = {}
    for i = 1, select("#", ...) do
        local c = select(i, ...)
        out[i] = c > 255 and "?" or byteChar(c)
    end
    return table.concat(out)
end
local loaded = {}
require = function(name)
    if REAL[name] and not loaded[name] then
        loaded[name] = true
        dofile(CLIENT .. name .. ".lua")
    end
end

-- a fresh game with this ZeD_Dashboard.lua (source text); withV: the file's ModSupport/VSKDash.lua too
local function boot(source, withV)
    loaded = {}
    VSK = nil
    ZeD_Dashboard = nil
    installGlobals()
    installZeD()
    if withV then dofile(CLIENT .. "ZeD/ModSupport/VSKDash.lua") end
    local f, err = loadstring(source, "=ZeD_Dashboard")
    assert(f, err)
    f()
    return ZeD.Dashboard
end

-- the car
local Car = {}
Car.__index = Car
local function part(c) return { getCondition = function() return c end, getItemType = function() return nil end,
    getModData = function() return {} end, isContainer = function() return false end } end
local function tankPart(f) return { getCondition = function() return 100 end, getItemType = function() return nil end,
    isContainer = function() return true end, getContainerContentAmount = function() return f * 100 end,
    getContainerCapacity = function() return 100 end } end
function Car:isEngineRunning() return self.running or false end
function Car:isEngineStarted() return self.running or false end
function Car:getEngineState() return self.running and "Running" or "Idle" end
function Car:isKeysInIgnition() return self.keysIn or false end
function Car:isHotwired() return self.hotwired or false end
function Car:getCurrentSpeedKmHour() return self.kmh or 0 end
function Car:getEngineSpeed() return self.rpm or 0 end
function Car:getTransmissionNumberLetter() return self.gear or "1" end
function Car:getBatteryCharge() return self.charge or 0.8 end
function Car:getHeadlightsOn() return self.lights or false end
function Car:getHeadlightCanEmmitLight() return self.lights or false end
function Car:isRegulator() return self.cruise or false end
function Car:getRegulatorSpeed() return 50 end
function Car:hasLightbar() return false end
function Car:getId() return self.id or 7 end
function Car:getScriptName() return self.script end
function Car:getScript() local s = self.script; return { getCarModelName = function() return s end, getName = function() return s end } end
function Car:getMaxPassengers() return 2 end
function Car:isDriver() return self.passenger ~= true end
function Car:getModData() return self.md or {} end
function Car:getPartById(id)
    if id == "GasTank" then return tankPart(self.fuel or 0.6) end
    if id == "Engine" then return part(self.engine or 90) end
    if id == "Battery" then return part(self.battery or 90) end
    if id == "Heater" then return self.heater and part(self.heater) or nil end
    return nil
end
local function newCar(t) return setmetatable(t or {}, Car) end

local SCRIPT = { luxury = "CarLuxury", nyala = "CarNormal", cossette = "SportsCar", d6 = "PickUpTruck", dashelite = "ModernCar",
    primani = "ModernCar02", dart = "SmallCar", horizon = "SmallCar02", wagon = "CarStationWagon", suv = "SUV", van = "Van",
    bulldriver = "PickUpVan", rancher = "OffRoad", taxi = "CarTaxi", ambulance = "VanAmbulance", race = "RaceCar",
    fire = "PickUpTruckFire", police = "CarLightsPolice", ranger = "CarLightsRanger" }
local DESIGNS = {}
for id in pairs(SCRIPT) do DESIGNS[#DESIGNS + 1] = id end
table.sort(DESIGNS)
local function scriptOf(id) return "Base." .. SCRIPT[id] end
assert(#DESIGNS == 19)

local CARS = {
    { name = "off" },
    { name = "key on", keysIn = true },
    { name = "idle", keysIn = true, running = true, rpm = 800 },
    { name = "cruising", keysIn = true, running = true, rpm = 3000, kmh = 60, gear = "3", lights = true },
    { name = "high revs", keysIn = true, running = true, rpm = 6800, kmh = 100, gear = "4", cruise = true },
    { name = "reverse", keysIn = true, running = true, rpm = 1200, kmh = -8, gear = "R" },
    { name = "worn", keysIn = true, running = true, rpm = 2000, kmh = 20, engine = 34, battery = 52, charge = 0.18, heater = 8 },
    { name = "dead battery", keysIn = true, running = true, rpm = 900, charge = 0.01 },
    { name = "hotwired", hotwired = true, running = true, rpm = 1500, kmh = 15 },
    { name = "low fuel", keysIn = true, running = true, rpm = 1500, kmh = 15, fuel = 0.05 },
    { name = "tired", keysIn = true, running = true, rpm = 1500, kmh = 15, engine = 30 },
    { name = "passenger", keysIn = true, running = true, rpm = 2000, kmh = 40, passenger = true },
}

-- the dash for one car: a frame is the character in the seat and one prerender
local inst, curCar
local function seat(car)
    curCar = car
    local chr = { getVehicle = function() return curCar end, getPlayerNum = function() return 0 end,
        getInventory = function() return { haveThisKeyId = function() return true end } end }
    getSpecificPlayer = function() return chr end
end
local function frame(ms)
    clock = clock + (ms or 100)
    LOG = {}
    inst:prerender()
    return LOG
end
local function frames(n, ms) for _ = 1, n do frame(ms) end end
local function newDash() inst = ZeD_Dashboard:new(0); return inst end

local SKIP = { pub = true, radioPart = true }
local function dumpSt(st, skipPub)
    local keys = {}
    for k in pairs(st) do if not SKIP[k] then keys[#keys + 1] = k end end
    table.sort(keys)
    local out = {}
    for _, k in ipairs(keys) do
        local v = st[k]
        out[#out + 1] = k .. "=" .. ((type(v) == "number") and string.format("%.6f", v) or tostring(v))
    end
    return table.concat(out, " ")
end

-- every design, car and form through a fresh dash: one string per frame (each reading and each draw)
local function sweep()
    local out = {}
    for _, simple in ipairs({ false, true }) do
        for _, lampsOn in ipairs({ false, true }) do
            env.simple, env.lampsOn = simple, lampsOn
            for _, id in ipairs(DESIGNS) do
                for _, c in ipairs(CARS) do
                    local car = {}
                    for k, v in pairs(c) do car[k] = v end
                    car.script = scriptOf(id)
                    seat(newCar(car))
                    newDash()
                    for i = 1, 4 do
                        local log = frame(137)
                        out[#out + 1] = id .. " " .. c.name .. " " .. i .. " simple=" .. tostring(simple) .. " lamps=" .. tostring(lampsOn)
                            .. "\n" .. dumpSt(inst._st) .. "\n" .. table.concat(log, "\n")
                    end
                end
            end
        end
    end
    return out
end

local function sameFrames(name, a, b)
    check(name .. ": same number of frames", #a == #b and #a > 0, #a .. " / " .. #b)
    local bad, first = 0, nil
    for i = 1, math.max(#a, #b) do
        if a[i] ~= b[i] then bad = bad + 1; first = first or i end
    end
    local detail = nil
    if first then
        local x, y = tostring(a[first]), tostring(b[first])
        local at = 1
        while at <= #x and x:sub(at, at) == y:sub(at, at) do at = at + 1 end
        detail = bad .. " frames differ, first: " .. x:sub(1, 60):gsub("\n", " | ") .. " ... today [" .. x:sub(at, at + 60) .. "] now [" .. y:sub(at, at + 60) .. "]"
    end
    check(name, bad == 0, detail)
end

-- ---------------------------------------------------------------------------
-- VEHICLE KIT LIBRARY, its published shape
-- ---------------------------------------------------------------------------
local LEVEL = { off = 0, ok = 1, warn = 2, crit = 3 }
local function stubLibrary(S)
    VSK = { Scale = { toReal = function(x) return x / (S or 1) end } }
    local K = { POLL_MS = 200, providers = {}, polls = 0, power = 1 }
    VSK.Dashboard = K
    local order = {}
    function K.register(def)
        def.kind = def.kind or "lamp"
        def.order = def.order or 100
        def.errors = 0
        K.providers[def.id] = def
        order = {}
        for _, d in pairs(K.providers) do order[#order + 1] = d end
        table.sort(order, function(a, b) if a.order ~= b.order then return a.order < b.order end; return a.id < b.id end)
    end
    function K.poll(v, player)
        K.polls = K.polls + 1
        if K.pollThrows then error("the library changed") end
        local c = { vehicle = v, power = K.power, results = {}, list = {} }
        local ctx = { vehicle = v, player = player, now = clock, power = K.power, kmh = false, stalled = K.held == true }
        for _, def in ipairs(order) do
            if not def.disabled then
                local ok, applies = true, true
                if def.appliesTo then ok, applies = pcall(def.appliesTo, v, ctx) end
                local res = nil
                if ok and applies then
                    local ok2, r = pcall(def.read, v, ctx)
                    if ok2 then res = r end
                    if not ok2 then def.errors = def.errors + 1; if def.errors >= 3 then def.disabled = true end end
                end
                if type(res) == "table" then
                    if not LEVEL[res.level] then res.level = "off" end
                    res.rank, res.def = LEVEL[res.level], def
                    c.results[def.id] = res
                    c.list[#c.list + 1] = res
                end
            end
        end
        K.cache = c
        return c
    end
    function K.gearLabel() if K.gearThrows then error("gear") end; return K.gear end
    function K.odometer() K.odoCalls = (K.odoCalls or 0) + 1; if K.odoThrows then error("odo") end; return K.km, K.tripKm end
    function K.stalled() return K.held == true end
    return K
end

-- providers shaped like Roadworthy's: rw holds what the car is doing
local function roadworthy(K, rw)
    local function powered(_, ctx) return (ctx.power or 0) > 0 end
    local span = 150 - 40
    K.register({ id = "rw.temp", kind = "lamp", order = 10, icon = "temp", short = "TEMP", checkEngine = "crit", name = "Temperature", appliesTo = powered,
        read = function()
            local t = rw.temp
            if rw.hotLamp then return { level = rw.hotLamp } end
            if t >= 130 then return { level = "crit", blink = t >= 140 } end
            if t >= 115 then return { level = "warn" } end
            return { level = "off" }
        end })
    K.register({ id = "rw.temp_gauge", kind = "gauge", gauge = "temp", order = 11, name = "Temperature", appliesTo = powered,
        read = function() return { level = "ok", value = (rw.temp - 40) / span, zones = { warn = 0.68, crit = 0.82 } } end })
    K.register({ id = "rw.belt", kind = "lamp", order = 15, icon = "belt", name = "Seat belt",
        read = function() return { level = rw.unbelted and "crit" or "off" } end })
    K.register({ id = "rw.oil", kind = "lamp", order = 20, icon = "oil", short = "OIL", checkEngine = "crit", name = "Oil pressure", appliesTo = powered,
        read = function() return { level = rw.oilLamp or "off", blink = rw.oilBlink } end })
    K.register({ id = "rw.oil_gauge", kind = "gauge", gauge = "oil", order = 21, name = "Oil pressure", appliesTo = powered,
        read = function() return { level = "ok", value = rw.press or 0.6 } end })
    K.register({ id = "rw.charge", kind = "lamp", order = 30, icon = "battery", short = "GEN", vanillaIcon = "battery", name = "Charge", appliesTo = powered,
        read = function() return { level = rw.charge and "crit" or "off" } end })
    K.register({ id = "rw.check", kind = "lamp", order = 40, icon = "engine", short = "CHK", checkEngine = "warn", vanillaIcon = "engine", name = "Check engine", appliesTo = powered,
        read = function() return { level = rw.check or "off", blink = rw.checkBlink } end })
    K.register({ id = "rw.tpms", kind = "lamp", order = 50, icon = "tire", short = "TPMS", name = "Tire pressure", appliesTo = powered,
        read = function() return { level = rw.tire or "off" } end })
    K.register({ id = "rw.odo", kind = "readout", order = 90, unpowered = true, odometer = true, name = "Odometer",
        read = function() return { level = "ok", text = "whole readout", tip = { "line" } } end })
end

-- ---------------------------------------------------------------------------
section("SAME: no such mod, today's dash against the dash now")
-- ---------------------------------------------------------------------------
local function readFile(path)
    local f = assert(io.open(path, "rb"))
    local s = f:read("*a")
    f:close()
    return s
end
local nowSource = readFile(CLIENT .. "ZeD/ZeD_Dashboard.lua")
local oldSource = nil
do
    -- (Nov 7 2026, punch list 92: ZeD's own dash changed on purpose (the hot lamp's bulb check, the odometers), so
    -- "today's dash" is the dash now with no ModSupport/VSKDash.lua loaded at all: boot(oldSource, false) below. The
    -- git BASE above is the dash this work was first proved against, kept for the record.)
    oldSource = nowSource
end
check("the dash is readable", oldSource and #oldSource > 10000)
if oldSource and #oldSource > 10000 then
    boot(oldSource, false)
    local today = sweep()
    print("   " .. #today .. " frames across " .. #DESIGNS .. " designs, " .. #CARS .. " car states, Full and Simple, lamps setting on and off")
    boot(nowSource, true)
    local now = sweep()
    sameFrames("no such mod", today, now)
    check("no such mod: nothing logged", #env.errors == 0, env.errors[1])
    boot(nowSource, true)
    stubLibrary(1)
    local silent = sweep()
    sameFrames("the library there, nobody publishing", today, silent)
    boot(nowSource, true)
    stubLibrary(1).held = true
    silent = sweep()
    sameFrames("the library holding a stall, nobody publishing", today, silent)
    -- the proof can fail: one number moved in the old dash shows up
    boot((string.gsub(oldSource, "st.engWarn and 0.82 or 0.5", "st.engWarn and 0.82 or 0.51")), false)
    local moved = sweep()
    local differs = false
    for i = 1, #today do if moved[i] ~= today[i] then differs = true; break end end
    check("the comparison can see a change", differs)
end

-- ---------------------------------------------------------------------------
-- the rest runs on the dash now, one car at a time
-- ---------------------------------------------------------------------------
local D = boot(nowSource, true)
local V = ZeD.ModSupport.VSKDash
for _, id in ipairs(DESIGNS) do
    local _, got = D._designFor(scriptOf(id))
    check("the sim's car for " .. id .. " wears that dash", got == id, got)
end
local n = 0
for _ in pairs(ZeD.DashPx.designs) do n = n + 1 end
check("every design is in the sim", n == #DESIGNS, n)
local function running(script, extra)
    local c = { script = script, keysIn = true, running = true, rpm = 2000, kmh = 40, gear = "3" }
    for k, v in pairs(extra or {}) do c[k] = v end
    return newCar(c)
end
local function start(design, extra, S)
    env.simple, env.lampsOn = false, false
    env.errors = {}
    local K = stubLibrary(S or 1)
    local rw = { temp = 90 }
    roadworthy(K, rw)
    seat(running(scriptOf(design), extra))
    newDash()
    frames(3, 250)
    return K, rw
end
-- run long enough for a needle to settle (the temperature's takes 9 s)
local function settle() frames(400, 250) end
local function st() return inst._st end
local AMBER, RED = D.LAMP_COLOR.worn, D.LAMP_COLOR.poor
local function drew(log, hex)
    local c = ZeD.Px.color(hex)
    local want = string.format("%.4f %.4f %.4f", c.r, c.g, c.b)
    local n = 0
    for _, l in ipairs(log) do if l:find("drawRect", 1, true) and l:find(want, 1, true) then n = n + 1 end end
    return n
end
local function drewText(log, s)
    for _, l in ipairs(log) do if l:find(s, 1, true) then return true end end
    return false
end

-- ---------------------------------------------------------------------------
section("NEEDLES")
-- ---------------------------------------------------------------------------
do
    local K, rw = start("nyala")
    settle()
    check("normal running: the needle reads the published 90 C", near(st().temp, 50 / 110, 0.01), st().temp)
    check("normal running: the hot lamp is dark", not st().tempLamp, st().tempLamp)
    rw.temp = 125
    settle()
    check("Roadworthy overheating: the needle climbs to 125 C", near(st().temp, 85 / 110, 0.01), st().temp)
    check("overheating: the lamp is amber", st().tempLamp == AMBER, st().tempLamp)
    check("overheating: ZeD's own engine reading would say normal", st().engWarn == false)
    rw.press = 0.25
    frames(40, 250)
    check("oil needle reads the published pressure", near(st().oil, 0.25, 0.01), st().oil)
    K.unregister = nil
    K.providers["rw.temp_gauge"].read = function() return nil end
    settle()
    check("the gauge gone: back to ZeD's own 0.5", near(st().temp, 0.5, 0.01), st().temp)
    K.providers["rw.oil_gauge"].read = function() return { level = "ok", value = 0.3, hidden = true } end
    frames(40, 250)
    check("a hidden gauge is no gauge: ZeD's own oil", near(st().oil, 0.45 + 0.35 * 2000 / 6000, 0.01), st().oil)
end
do
    local K, rw = start("nyala", { running = false, rpm = 0, kmh = 0 })
    rw.temp = 60
    settle()
    check("key on, engine off: the needle reads the published cooling engine", near(st().temp, 20 / 110, 0.01), st().temp)
    K.power = 0
    settle()
    check("ignition off: nothing published, ZeD's own rest", near(st().temp, 0.12, 0.01), st().temp)
end
do
    -- a gauge with nothing of its own to keep it dark: the library's contract does (a needle rests with no power)
    local K = start("nyala", { running = false, rpm = 0, kmh = 0 })
    K.providers["rw.temp_gauge"].appliesTo = nil
    K.providers["rw.oil_gauge"] = nil
    K.register({ id = "x.boost", kind = "gauge", name = "Boost", read = function() return { level = "ok", value = 0.4 } end })
    K.register({ id = "x.dial", kind = "gauge", name = "Coolant", read = function() return { level = "ok", value = 0.47, text = "92 C" } end })
    env.simple = true
    frames(3, 250)
    check("with power a role-less gauge is listed", drewText(frame(0), "Boost: 40%"))
    check("a gauge's text is what Simple prints", drewText(frame(0), "Coolant: 92 C") and not drewText(frame(0), "47%"))
    K.power = 0
    frames(3, 250)
    check("no power: the temperature gauge gives no needle", st().pub.temp == nil, st().pub.temp)
    check("no power: no gauge on Simple", not drewText(frame(0), "Boost") and not drewText(frame(0), "Coolant"))
    K.providers["rw.temp_gauge"].unpowered = true
    frames(3, 250)
    check("flagged unpowered: it reads with the key out", st().pub.temp ~= nil)
end

-- ---------------------------------------------------------------------------
section("LAMPS")
-- ---------------------------------------------------------------------------
do
    local K, rw = start("nyala")
    rw.temp = 120
    frames(3, 250)
    check("amber as published", st().tempLamp == AMBER, st().tempLamp)
    rw.temp = 132
    frames(3, 250)
    check("red as published", st().tempLamp == RED, st().tempLamp)
    check("crit with checkEngine lights the engine role too", inst._st.pub.lamps.engLamp and inst._st.pub.lamps.engLamp.rank == 3)
    rw.temp = 142
    frames(3, 250)
    local seen = {}
    for _ = 1, 8 do frame(250); seen[tostring(st().tempLamp)] = true end
    check("blink: red and dark, both", seen[RED] and seen["false"], tostring(seen[RED]) .. " " .. tostring(seen["false"]))
    rw.temp = 90
    rw.unbelted = true
    frames(3, 250)
    check("belt lamp red", st().beltLamp == RED, st().beltLamp)
    K.power = 0
    frames(3, 250)
    check("no power: a lamp that is not unpowered stays dark", not st().beltLamp, st().beltLamp)
end
do
    local _, rw = start("nyala", { battery = 52, charge = 0.18 })
    rw.charge = false
    env.lampsOn = true
    frames(3, 250)
    check("a dark published lamp leaves ZeD's own low-battery lamp", st().genLamp ~= false and st().genLamp ~= nil, st().genLamp)
    rw.charge = true
    frames(3, 250)
    check("the charge lamp lit takes it, red", st().genLamp == RED, st().genLamp)
end
do
    start("nyala", { running = false, rpm = 0, kmh = 0 })
    frames(3, 250)
    check("bulb check stands with nothing lit", st().oilLamp == true and st().tempLamp ~= nil, st().oilLamp)
end

do
    -- two lamps at one level on the engine lamp: steady, then blinking, in the library's order
    local _, rw = start("d6")
    rw.temp = 135
    rw.check, rw.checkBlink = "crit", true
    frames(3, 250)
    local l = st().pub.lamps.engLamp
    check("a steady red and a blinking red: the engine lamp blinks", l and l.blink == true, l and l.blink)
    check("it takes the name of the lamp that has one", l and l.name == "Check engine", l and l.name)
    local seen = {}
    for _ = 1, 8 do frame(250); seen[tostring(st().engLamp)] = true end
    check("the plate's engine lamp goes red and dark", seen[RED] and seen["false"], tostring(seen[RED]))
    rw.check, rw.checkBlink = nil, nil
    rw.oilLamp, rw.oilBlink = "crit", true
    frames(3, 250)
    l = st().pub.lamps.engLamp
    check("the oil lamp's blink reaches the engine lamp it lights", l and l.blink == true, l and l.blink)
    rw.oilBlink = nil
    frames(3, 250)
    l = st().pub.lamps.engLamp
    check("nothing blinking: steady", l and l.blink == false, l and l.blink)
end

local ROLES = {
    { src = "tempLamp", set = function(rw) rw.hotLamp = "warn" end, name = "Temperature", color = AMBER },
    { src = "oilLamp",  set = function(rw) rw.oilLamp = "warn" end, name = "Oil pressure", color = AMBER },
    { src = "genLamp",  set = function(rw) rw.charge = true end, name = "Charge", color = RED },
    { src = "engLamp",  set = function(rw) rw.check = "warn" end, name = "Check engine", color = AMBER },
    { src = "beltLamp", set = function(rw) rw.unbelted = true end, name = "Seat belt", color = RED },
}
for _, id in ipairs(DESIGNS) do
    local has = D._plainPlan(ZeD.DashPx.designs[id]).has
    -- (a parked car in gear, its needles settled: from here on only a lamp can change the picture)
    local _, rw = start(id, { kmh = 0 })
    settle()
    local dark = table.concat(frame(0), "\n")
    local function lit(role)
        for k in pairs(rw) do if k ~= "temp" then rw[k] = nil end end
        role.set(rw)
        frames(2, 200)
        return frame(0)
    end
    for _, role in ipairs(ROLES) do
        env.simple = false
        local log = lit(role)
        local what = id .. " " .. role.src
        if has[role.src] then
            check(what .. ": the plate's lamp lights in its color", drew(log, role.color) > 0, drew(log, role.color))
        else
            check(what .. ": no spot, the plate draws nothing new", table.concat(log, "\n") == dark)
        end
        env.simple = true
        check(what .. ": the Simple strip names it", drewText(frame(0), role.name), role.name)
    end
    -- a lamp with no glyph on any plate: left off the plate, listed on Simple
    env.simple = false
    local log = lit({ set = function(t) t.tire = "warn" end })
    check(id .. " tire pressure: no spot on any plate", table.concat(log, "\n") == dark)
    env.simple = true
    log = frame(0)
    check(id .. " tire pressure: on the Simple strip, amber", drewText(log, "Tire pressure") and drewText(log, "drawStatusDot"))
end
do
    local _, rw = start("nyala")
    rw.tire = "warn"
    V.BORROW_UNPAINTED = true
    env.lampsOn = true
    frames(2, 200)
    check("the constant on: a plate with no engine lamp lends its battery lamp", st().genLamp == AMBER, st().genLamp)
    V.BORROW_UNPAINTED = false
    frames(2, 200)
    check("the constant off, as shipped: it stays dark", st().genLamp == false, st().genLamp)
    _, rw = start("d6")
    rw.tire = "crit"
    V.BORROW_UNPAINTED = true
    frames(2, 200)
    check("the constant on: a plate with one lends its engine lamp", st().engLamp == RED, st().engLamp)
    V.BORROW_UNPAINTED = false
end
do
    local K = start("nyala")
    K.register({ id = "other.fuel", kind = "lamp", icon = "fuel", name = "Reserve", read = function() return { level = "ok", lit = true } end })
    frames(2, 200)
    check("an indicator lit with nothing wrong: the plate's own color", st().fuelLamp == true, st().fuelLamp)
    K.register({ id = "other.gauge", kind = "gauge", name = "Boost", read = function() return { level = "ok", value = 0.4 } end })
    K.register({ id = "other.text", kind = "readout", name = "Limiter", read = function() return { level = "ok", text = "55 mph" } end })
    env.simple = true
    frames(2, 200)
    check("with no odometer figure a mod's odometer readout is still shown", drewText(frame(0), "whole readout"))
    K.km, K.tripKm = 1000, 1
    frames(2, 200)
    local log = frame(0)
    check("Simple lists a mod's readout", drewText(log, "Limiter: 55 mph"))
    check("Simple lists a mod's gauge", drewText(log, "Boost: 40%"))
    check("Simple names the row", drewText(log, "Readouts"))
    check("Simple keeps the odometer out of the row (it has its own cell)", not drewText(log, "whole readout"))
end

do
    -- the library's high beam: there on high, not there at all on low. The plate's blue lamp says the headlights are on.
    local K = start("nyala", { lights = true })
    local high = false
    K.register({ id = "vsk.highbeam", kind = "lamp", icon = "beam", name = "High beam", order = 5,
        read = function() if high then return { level = "ok", lit = true, color = { 0, 0, 1 } } end; return nil end })
    frames(2, 200)
    check("low beam, headlights on: the plate's lamp as today", st().hiBeam == true, st().hiBeam)
    high = true
    frames(2, 200)
    check("high beam: the same lamp", st().hiBeam == true, st().hiBeam)
    check("high beam claims no plate lamp", st().pub.lamps.hiBeam == nil)
    env.simple = true
    check("Simple lists it by the mod's name", drewText(frame(0), "High beam"))
    env.simple = false
    V.BORROW_UNPAINTED = true
    env.lampsOn = true
    frames(2, 200)
    check("the constant on: an indicator with nothing wrong borrows no fault lamp", st().genLamp == false, st().genLamp)
    V.BORROW_UNPAINTED = false
end

-- ---------------------------------------------------------------------------
section("GEAR")
-- ---------------------------------------------------------------------------
do
    local K = start("nyala")
    local letters = D._plainPlan(ZeD.DashPx.designs.nyala).gearLetters
    check("the plate's letters are known", letters and letters.N and letters.D)
    for _, c in ipairs({ { "N", "N" }, { "1", "1" }, { "2", "2" }, { "D", "D" }, { "R", "R" }, { "M2", "2" }, { "D3", "D" }, { "3", "D" }, { "M4", "D" } }) do
        K.gear = c[1]
        frames(2, 200)
        check("label " .. c[1] .. " shows " .. c[2], st().gearSel == c[2], st().gearSel)
    end
    K.gear = nil
    frames(2, 200)
    check("no label: the plate's own selector", st().gearSel == "D", st().gearSel)
    K.gear = "4"
    env.simple = true
    frames(2, 200)
    check("Simple shows the whole label", drewText(frame(0), " 4 "), "4")
    start("d6", {})
    VSK.Dashboard.gear = "N"
    frames(2, 200)
    check("a plate with no letters: no error", #env.errors == 0, env.errors[1])
end

-- ---------------------------------------------------------------------------
section("ODOMETER")
-- ---------------------------------------------------------------------------
do
    local K = start("dashelite")
    local made = st().odo
    K.km, K.tripKm = 123513.5 * 1.609344, 5.15   -- trip 3.2 mi
    frames(2, 200)
    check("the LCD shows the last four of the real figure", st().odo == 3513, st().odo)
    check("it is not the made-up number", st().odo ~= made)
    local digits = false
    for _, l in ipairs(frame(0)) do digits = digits or l:find("drawRect", 1, true) ~= nil end
    check("the LCD draws", digits)
    env.simple = true
    local log = frame(0)
    check("Simple shows the whole figure", drewText(log, "123513 mi"))
    check("Simple shows the trip", drewText(log, "3.2 mi") and drewText(log, "Trip"))
    K.km = nil
    env.simple = false
    frames(2, 200)
    check("nothing published: the made-up number stays", st().odo == made or st().odo ~= 3513, st().odo)
end

-- ---------------------------------------------------------------------------
section("SPEED")
-- ---------------------------------------------------------------------------
do
    start("nyala", { kmh = 65 }, 0.65)
    frames(60, 250)
    check("World Scale 0.65: 65 game km/h reads the 100 it stands for", near(st().speed_kmh, 100, 0.5), st().speed_kmh)
    check("the needle is in mph", near(st().speed_mph, 62.14, 0.5), st().speed_mph)
    check("the car's own speed stays the game's (the fare, the hula girl)", near(st().speed, 65, 0.001), st().speed)
    start("nyala", { kmh = 65 }, 1)
    frames(60, 250)
    check("real figures: no change", near(st().speed_kmh, 65, 0.5), st().speed_kmh)
end

-- ---------------------------------------------------------------------------
section("STALL")
-- ---------------------------------------------------------------------------
do
    local K, rw = start("cossette", { keysIn = false, running = false, rpm = 0, kmh = 0 })
    rw.temp = 146
    K.held = true
    settle()
    check("stalled with the key gone: the dash stays lit", st().power == true)
    check("stalled: the hot reading stays", near(st().temp, 106 / 110, 0.01), st().temp)
    K.held = false
    K.power = 0
    frames(2, 250)
    check("the hold over: dark again", st().power == false)
end
do
    -- no mod behind the stall: the library's own lamp is not a mod publishing
    local K = stubLibrary(1)
    K.register({ id = "vsk.highbeam", kind = "lamp", icon = "beam", name = "High beam", read = function() return { level = "ok", lit = true } end })
    env.simple, env.lampsOn = false, false
    seat(running(scriptOf("cossette"), { keysIn = false, running = false, rpm = 0, kmh = 0 }))
    newDash()
    K.held = true
    frames(3, 250)
    check("only the library's lamp: no hold, dark as today", st().power == false and st().pub.stalled == nil, st().power)
    K.register({ id = "x.lamp", kind = "lamp", name = "Anything", read = function() return { level = "off" } end })
    frames(3, 250)
    check("a mod publishing for this car: the hold stands", st().power == true and st().pub.stalled == true, st().power)
    K.providers["x.lamp"].read = function() return { level = "off", hidden = true } end
    frames(3, 250)
    check("a hidden result is nobody publishing", st().power == false, st().power)
end

-- ---------------------------------------------------------------------------
section("PASSENGER")
-- ---------------------------------------------------------------------------
do
    local K, rw = start("nyala", { passenger = true, kmh = 65 }, 0.65)
    rw.temp, rw.unbelted, rw.oilLamp = 142, true, "crit"
    K.gear = "N"
    settle()
    check("a passenger's dash never polls", K.polls == 0, K.polls)
    check("a passenger reads the speed the car stands for, as the driver", near(st().speed_kmh, 100, 0.5), st().speed_kmh)
    check("a passenger's temperature is ZeD's own", near(st().temp, 0.5, 0.01), st().temp)
    check("a passenger's lamps are ZeD's own", not st().tempLamp and not st().beltLamp and not st().oilLamp)
    check("a passenger's gear letter is ZeD's own: the gearbox is a provider", st().gearSel == "D", st().gearSel)
    local c0 = K.odoCalls or 0
    for _ = 1, 600 do frame(16) end        -- 9.6 s at 60 fps
    local calls = (K.odoCalls or 0) - c0
    check("a passenger's figures are read five times a second", calls >= 44 and calls <= 50, calls)
    K = start("dashelite", { passenger = true })
    local made = st().odo
    K.km, K.tripKm = 123513.5 * 1.609344, 5.15
    frames(2, 200)
    check("a passenger's Dash Elite shows Roadworthy's odometer", st().odo == 3513 and st().odo ~= made, st().odo)
    env.simple = true
    check("and a passenger's Simple dash", drewText(frame(0), "123513 mi"))
    env.simple = false
    K.held = true
    seat(running(scriptOf("cossette"), { passenger = true, keysIn = false, running = false, rpm = 0, kmh = 0 }))
    frames(3, 250)
    check("a stall holds nothing up for a passenger", st().power == false and st().pub.stalled == nil, st().power)
    K.odoThrows, VSK.Scale = true, "gone"
    frames(3, 250)
    check("a passenger with a broken odometer and scale: ZeD's own", st().pub.odoMiles == nil and st().pub.speedK == nil)
    VSK = nil
    frames(3, 250)
    check("a passenger, no library: ZeD's own", st().pub == nil)
end

-- ---------------------------------------------------------------------------
section("COST, LOAD ORDER, ANOTHER CAR")
-- ---------------------------------------------------------------------------
do
    local K = start("nyala")
    local p0 = K.polls
    local pub0 = st().pub
    for _ = 1, 600 do frame(16) end        -- 9.6 s at 60 fps
    check("the library is read about five times a second", K.polls - p0 >= 44 and K.polls - p0 <= 50, K.polls - p0)
    frame(1)
    local a = st().pub
    frame(1)
    check("the frames between hand back the same table", st().pub == a)
    check("(the first table was replaced by a later poll)", a ~= pub0)

    VSK = nil
    env.errors = {}
    frames(2, 250)
    check("the library gone: ZeD's own", st().pub == nil)
    stubLibrary(1)
    frames(2, 250)
    check("a library that loads after ZeD is picked up", st().pub ~= nil)

    -- the list is the car's. Out of one and into another, as the game does it: D.hide, then D.show hands the dash the new car
    -- before its first frame, so the dash keeps its memory
    local car1 = curCar
    K = VSK.Dashboard
    K.register({ id = "x.tpms", kind = "lamp", name = "Tires", read = function() if curCar == car1 then return { level = "warn" } end; return nil end })
    frames(2, 250)
    local function listed(want)
        for _, e in ipairs(st().pub.list) do if e.id == want then return true end end
        return false
    end
    check("(the first car has its lamp)", listed("x.tpms"))
    inst.vehicle = nil
    inst.vehicle = car1
    K.providers["x.tpms"].read = function() return nil end
    frames(2, 250)
    check("back in the same car: its row holds still", listed("x.tpms"))
    local mem = inst._mem
    local car2 = running(scriptOf("d6"))
    seat(car2)
    inst.vehicle = nil
    inst.vehicle = car2
    K.register({ id = "x.only", kind = "lamp", name = "Only", read = function() return { level = "warn" } end })
    frames(2, 250)
    check("(the dash kept its memory, as in the game)", inst._mem == mem)
    local n, id = #st().pub.list, st().pub.list[1] and st().pub.list[1].id
    check("a new car starts its own list", n == 1 and id == "x.only", tostring(n) .. " " .. tostring(id))
    env.simple = true
    check("Simple lists no lamp of the car before", not drewText(frame(0), "Tires"))
    env.simple = false
end

-- ---------------------------------------------------------------------------
section("BREAKS")
-- ---------------------------------------------------------------------------
do
    local K, rw = start("nyala")
    rw.temp = 125
    settle()
    K.pollThrows = true
    env.errors = {}
    frames(3, 250)
    check("a poll that throws: no publishing", st().pub == nil)
    check("  nothing reaches ZeD.logOnce, which counts toward safe mode", #env.errors == 0, env.errors[1])
    local p1 = K.polls
    settle()
    check("  ZeD's own value", near(st().temp, 0.5, 0.01), st().temp)
    local asked = K.polls - p1
    check("  the library is asked again only now and then", asked >= 19 and asked <= 21, asked)
    K.pollThrows = false
    frames(21, 250)
    check("  and it comes back", st().pub ~= nil)

    K, rw = start("nyala")
    K.providers["rw.temp_gauge"].read = function() error("beta") end
    K.providers["rw.oil"].read = function() error("beta") end
    frames(30, 250)
    check("a provider that throws: ZeD carries on", st().pub ~= nil and st().pub.temp == nil)
    check("  the library has retired it", K.providers["rw.oil"].disabled == true)

    K = start("nyala")
    K.gearThrows, K.odoThrows = true, true
    frames(3, 250)
    check("gear and odometer that throw: nothing shown from them", st().pub ~= nil and st().pub.gear == nil and st().pub.odoMiles == nil)

    VSK.Scale.toReal = function() error("scale") end
    frames(3, 250)
    check("a scale that throws: the game's speed", st().pub ~= nil and st().pub.speedK == nil)
    VSK.Scale.toReal = function() return 0 / 0 end
    frames(3, 250)
    check("a scale that is not a number: the game's speed", st().pub.speedK == nil)
    VSK.Scale = "gone"
    frames(3, 250)
    check("a scale that is gone: the game's speed", st().pub.speedK == nil)

    K = start("nyala")
    local inf = 1 / 0
    local bad = {
        { "text for a value", "hot" }, { "NaN", 0 / 0 }, { "infinity", inf }, { "a table", {} },
    }
    for _, b in ipairs(bad) do
        K.providers["rw.temp_gauge"].read = function() return { level = "ok", value = b[2] } end
        frames(3, 250)
        check("a gauge of " .. b[1] .. ": ZeD's own", st().pub.temp == nil, tostring(st().pub.temp))
    end
    K.providers["rw.temp_gauge"].read = function() return { level = "ok", value = 7 } end
    frames(3, 250)
    check("a gauge past the end is held at the end", st().pub.temp == 1)
    K.km = "lots"
    K.gear = 3
    K.providers["rw.tpms"].read = function() return { level = "bogus" } end
    K.providers["rw.check"].read = function() return "fine" end
    K.providers["rw.oil"].read = function() return { level = "warn", name = 4 } end
    K.register({ id = 42, kind = "lamp", read = function() return { level = "warn" } end })
    env.simple = true
    env.errors = {}
    frames(3, 250)
    check("an odometer that is not a number: none", st().pub.odoMiles == nil)
    check("a gear that is not text: none", st().pub.gear == nil)
    check("lies leave the dash drawing", #frame(0) > 10)
    check("nothing thrown past the dash", #env.errors == 0, env.errors[1])

    K = start("nyala")
    K.poll = "gone"
    env.errors = {}
    frames(3, 250)
    check("a library with no poll: off", st().pub == nil and #env.errors == 0)
    VSK.Dashboard = nil
    frames(3, 250)
    check("a library with no Dashboard: off", st().pub == nil)
    VSK = "not a table"
    frames(3, 250)
    check("a VSK that is something else: off", st().pub == nil)
    VSK = nil
end

-- ---------------------------------------------------------------------------
section("SAFE MODE: another mod's failure is not ZeD's")
-- ---------------------------------------------------------------------------
do
    local Dn = boot(nowSource, true)
    ZeD.Safe = nil
    dofile(CLIENT .. "ZeD/SafeMode.lua")
    local body = readFile(ROOT .. "42/media/lua/shared/ZeD/Tokens.lua"):match("local _logSeen.-\nfunction ZeD%.logOnce.-\nend")
    assert(body, "ZeD.logOnce is not where the sim looks for it")
    assert(loadstring(body, "=logOnce"))()
    local trips = {}
    ZeD.Safe.trip = function(where) trips[#trips + 1] = tostring(where) end
    local outPrint = print
    local function failing(name, set)
        local K = start("nyala")
        set(K)
        trips = {}
        local said = {}
        print = function(x) said[#said + 1] = tostring(x) end
        local ok, err = pcall(function() for _ = 1, 600 do frame(16) end end)
        print = outPrint
        check(name .. ": the dash carries on", ok, err)
        check(name .. ": the watchdog never trips (10 s of frames)", #trips == 0, trips[1])
        return said
    end
    local said = failing("a poll that throws", function(K) K.pollThrows = true end)
    check("  it says so once", #said == 1 and said[1]:find("the library changed", 1, true) ~= nil, table.concat(said, " | "))
    failing("a poll with no list", function(K) K.poll = function() return {} end end)
    local apply = Dn.applyPublished
    said = failing("published data the dash can't take", function() Dn.applyPublished = function() error("published") end end)
    Dn.applyPublished = apply
    check("  it says so once", #said == 1, table.concat(said, " | "))
    -- the proof can fail: the same failure through ZeD.logOnce does trip it
    trips = {}
    for _ = 1, 400 do clock = clock + 16; ZeD.logOnce("control", "x") end
    check("the watchdog in this rig does trip on logOnce", #trips > 0, #trips)
end

-- ---------------------------------------------------------------------------
section("THE FILES")
-- ---------------------------------------------------------------------------
do
    local s = readFile(CLIENT .. "ZeD/ModSupport/VSKDash.lua")
    check("VSKDash.lua is plain ASCII", not s:find("[\128-\255]"))
    local function high(t) local _, n = t:gsub("[\128-\255]", ""); return n end
    check("ZeD_Dashboard.lua took no new non-ASCII", oldSource and high(nowSource) == high(oldSource))
    check("VSKDash patches nothing: it only reads", not s:find("VSK%.[%w%.]+%s*=") and not s:find("VD%.[%w]+%s*=[^=]") and not s:find("wrap"))
end

print("vskdash_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
