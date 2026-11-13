-- ZeDUI/tools/qa/dash_odo_sim.lua  (Nov 7 2026, Build): the dashes' odometers and trip odometers with no game running
-- (punch list 92; docs/handoffs/HANDOFF_design_dash_roadworthy_20261106.md). The real ZeD_PixelParts.lua, ZeD_Plate.lua,
-- DashPx.lua and ZeD_Dashboard.lua run on Lua 5.1 stubs of the game, a car and a panel that writes down every draw.
--   WHEELS  the drums' figures: zero padded, rolled over past the last wheel, the tenths; the tenths wheel holds for 80%
--           of each tenth and then turns over, clipped to its window; the LCD kind right-aligned, capitals for lower case
--   PLATE   the wheels draw with the key off, the LCD only with it on; at night every run goes through the light
--   SEED    a found car's mileage is stable for a car, inside its range, and odd ids can't break it
--   COUNT   miles only while the engine runs, only for the driver, km/h x 0.6214; saved on the car's modData, so a new
--           dash (a reload) reads the same figures; the taxi's fare keeps its own counter
--   SHOW    the VFD and LCD readings, ODO / TRIP, the words lit with the key
--   VERBS   the stem zeroes the trip; the window's A switches, its X zeroes only while the trip shows; both on the pad
--   SERVER  the driver's client sends the server a command with the car's figures (never the car's modData: the
--           client never calls transmitModData, punch list 94) no more than every tenth of a mile, and at once after
--           a press; the miles not sent yet go when the car stops, the engine stops, the driver leaves the seat or the
--           car (OnExitVehicle's D.hide, on a panel that gets no prerender once hidden), takes another, or safe mode or
--           the hidden UI takes the dash; a last send more than 3 s late is dropped, never sent from a parked car;
--           single player and a passenger send nothing; no link to the server part is no error; the server's copy
--           coming back after a send never winds the driver's figures back, nor a press made just before it lands;
--           the server's answer to a refused send (sync) puts the driver on its figures, a stale one is dropped;
--           stop-and-go traffic sends no more often; a press, a first mileage, the engine off and the driver leaving
--           ask the server to save (send the car out), the tenths and a stop don't, and the engine off with nothing new
--           since a tenth asks once; stopped, an older copy at the same odometer never undoes a press; the driver's
--           figures the server sends the other seats go on their copy only, junk and another car's dropped, and a
--           driver keeps their own; a passenger asks for them as it sits down, again every 2 s until they come,
--           three times at most, and the driver never asks; the ash tray is the car's (modData ZeD_ash): on a server
--           the press shows at once and asks the server (DP.ASH, its shape checked), whose copy, sent out, keeps it;
--           single player keeps it on the car's modData
--   SPLIT   split-screen (known issue Nov 7 2026): each local player gets a dash of their own; the second player's
--           driver sends as themselves (the server takes only the driver's); the other seats' figures and a refusal
--           reach the right player's dash; the controller goes to the first player's dash only
--   HOT     the hot lamp lights in the key-on bulb check; the Simple dash's Temperature bar goes red only when hot
--   SIMPLE  the Trip cell beside Odometer, in the player's units, one decimal; A on it zeroes the trip; the units
--           option is read at most once a second
--   DIGITAL the Lang 4000's and the Cossette's speed figures in the game's units, the KM/H or MPH legend lit; the
--           needles stay in mph
-- From the in-game dash scripts (Nov 12 2026):
--   KEYS    (zedqa_dash_keys_edge.lua, archive/zedqa_dash_r6_keys.lua) the key reads ACC in, START while the starter
--           turns, ON running; a start ACC-OFF-ON-START-ON, shut off ON-OFF-ACC, a dry start back to ACC, the key out
--           none; each step 90 to 400 ms; the dash flush on the screen's bottom edge; the ash tray's click, none on
--           the fleet dashes
--   BRANDS  (zedqa_dash_brands.lua) each civilian car's dash and its maker's mark with its sprite; the Step Van on
--           the Valuline's dash with the Chevalier mark and STEP VAN; a modded car's name gets the plaque
--   NIGHT   (zedqa_dashnight.lua) the light to nightness in eighths, the dark plate or the lit one laid over, the dash
--           lights brightening the plate, D.qaNight
--   PARTS   (zedqa_dash_r6_parts.lua) the taxi's fare: flag drop by a click, a minute's wait, a fifth of a mile, the
--           extras per rider, the sandbox read live, the key out clearing it; the hula girl at rest and both ways;
--           the licence's unit line; the van's decal, NO SMOKING or ash tray
-- Run from the repo root:  lua51 ZeDUI/tools/qa/dash_odo_sim.lua
-- It prints FAIL lines and a last line "dash_odo_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]dash_odo_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/"
local SHARED = ROOT .. "42/media/lua/shared/"

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
local env = { simple = false, pad = false, units = "Imperial", client = false, errors = {} }

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

Events = setmetatable({}, { __index = function() return { Add = noop, Remove = noop } end })
getTimestampMs = function() return clock end
getText = function(k) return k end
getTextOrNull = function() return nil end
getGameSpeed = function() return 1 end
getGameTime = function() return { getHour = function() return 10 end, getMinutes = function() return 8 end } end
getPlayerScreenLeft, getPlayerScreenTop = function() return 0 end, function() return 0 end
getPlayerScreenWidth, getPlayerScreenHeight = function() return 1920 end, function() return 1080 end
getCell = function() return nil end
getCore = function() return { getOptionTemperatureDisplayCelsius = function() return true end,
    getOptionClock24Hour = function() return true end, getOptionMeasurementFormat = function() env.unitReads = (env.unitReads or 0) + 1; return env.units end } end
isClient = function() return env.client end
instanceof = function() return true end
isMouseButtonDown = function() return false end
SandboxVars = {}
UIFont = {}
Texture = { getSharedTexture = function(path) return { path = path, isReady = function() return true end } end }
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
-- (shown or hidden as the game would: a hidden panel gets no prerender, see frame below)
function ZeD_Panel:setVisible(v) self._hidden = not v end
function ZeD_Panel:isVisible() return not self._hidden end

ZeD = { _trGen = 0 }
local defaults = {}
ZeD.trDefaults = function(t) for k, v in pairs(t) do defaults[k] = v end end
ZeD.tr = function(key, ...)
    local s = defaults[key] or key
    for i = 1, select("#", ...) do s = string.gsub(s, "%%" .. i, (string.gsub(tostring((select(i, ...))), "%%", "%%%%"))) end
    return s
end
ZeD.upper, ZeD.textCase = string.upper, function(s) return s end
ZeD.logOnce = function(key, msg) env.errors[#env.errors + 1] = tostring(key) .. ": " .. tostring(msg) end
ZeD.Safe = { on = function() return false end, register = function(name, t) env.safe = env.safe or {}; env.safe[name] = t end }
ZeD.Settings = { dashSimple = function() return env.simple end, dashLampsOn = function() return false end }
ZeD.RadioOps = { read = function() return nil end }
ZeD.Input = { Detector = { getMode = function() return env.pad and "gamepad" or "mouse" end } }
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
ZeD.Focus = { mark = function() return false end }
ZeD.PadGlyphs = { stripH = function() return 0 end, drawStrip = noop, set = function() return nil end }

local REAL = { ["ZeD/DashPx"] = true, ["ZeD/ZeD_PixelParts"] = true, ["ZeD/PixelFonts"] = true, ["ZeD/ZeD_Plate"] = true }
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
    elseif name == "ZeD/ZeD_DashProto" and not loaded[name] then
        loaded[name] = true
        dofile(SHARED .. name .. ".lua")
    end
end
-- the link to the server part (ZeD_ServerLink.lua's S.send): each command is written down, and a send of the figures
-- (DP.ODO, not a passenger's ask) counted on its car; and the routes the dash hands the server's answers to (S.on)
local CARS, SENT, ROUTES = {}, {}, {}
ZeD.ServerPart = { send = function(module, command, args, player)
    SENT[#SENT + 1] = { module = module, command = command, args = args, player = player }
    local car = CARS[args and args.veh]
    if car and command == ZeD.DashProto.ODO then car.sent = car.sent + 1 end
    return true
end, on = function(module, fn) ROUTES[module] = fn end }
dofile(CLIENT .. "ZeD/ZeD_Dashboard.lua")
local D = ZeD.Dashboard
local P = ZeD.Px
local PL = ZeD.Plate
assert(D and P and PL, "the dash files loaded")

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
function Car:isHotwired() return false end
function Car:getCurrentSpeedKmHour() return self.kmh or 0 end
function Car:getEngineSpeed() return self.running and 2000 or 0 end
function Car:getTransmissionNumberLetter() return "3" end
function Car:getBatteryCharge() return 0.8 end
function Car:getHeadlightsOn() return false end
function Car:getHeadlightCanEmmitLight() return false end
function Car:isRegulator() return false end
function Car:getRegulatorSpeed() return 0 end
function Car:hasLightbar() return false end
function Car:getId() return self.id or 7 end
function Car:getScriptName() return self.script end
function Car:getScript() local s = self.script; return { getCarModelName = function() return s end, getName = function() return s end } end
function Car:getMaxPassengers() return 2 end
function Car:isDriver() return self.passenger ~= true end
function Car:getModData() return self.md end
function Car:getPartById(id)
    if id == "GasTank" then return tankPart(0.6) end
    if id == "Engine" then return part(self.engine or 90) end
    if id == "Battery" then return part(90) end
    return nil
end
-- (the car's transmitModData is there, as on the game's cars, and counts: the dash must never call it)
local ALLCARS = {}
local function newCar(t)
    t = t or {}
    t.md = t.md or {}
    t.sent, t.transmits = 0, 0
    t.transmitModData = function(self) self.transmits = self.transmits + 1 end
    CARS[t.id or 7] = t
    ALLCARS[#ALLCARS + 1] = t
    return setmetatable(t, Car)
end
local SCRIPT = { d6 = "Base.PickUpTruck", dashelite = "Base.ModernCar", cossette = "Base.SportsCar", luxury = "Base.CarLuxury",
    taxi = "Base.CarTaxi", race = "Base.RaceCar", nyala = "Base.CarNormal" }

local inst, curCar
local CHR = { getVehicle = function() return curCar end, getPlayerNum = function() return 0 end,
    isLocalPlayer = function() return true end,
    getInventory = function() return { haveThisKeyId = function() return true end } end }
getSpecificPlayer = function() return CHR end
-- into a car (OnEnterVehicle shows the dash), or out of it with seat(nil): a bare seat(nil) is the car lost some
-- other way; getting out is out() below, which fires OnExitVehicle's D.hide as the game does
local function seat(car)
    curCar = car
    if car and inst then inst:setVisible(true) end
end
local function out()
    curCar = nil
    D.hide(CHR)
end
-- one frame: the UI manager calls prerender only on a shown panel
local function frame(ms)
    clock = clock + (ms or 100)
    LOG = {}
    if inst:isVisible() then inst:prerender() end
    return LOG
end
local function frames(n, ms) for _ = 1, n do frame(ms) end end
local function newDash() inst = ZeD_Dashboard:new(0); D._instance = inst; D._instances = { [0] = inst }; return inst end
local function st() return inst._st end
local function drive(design, t)
    t = t or {}
    t.script = SCRIPT[design]
    local car = newCar(t)
    seat(car)
    newDash()
    frame(0)
    return car
end
local function element(id)
    for _, e in ipairs(inst._elements) do if e.id == "dash:" .. id then return e end end
    return nil
end

-- a canvas that writes down every rect in art pixels
local RECTS
local function canvas()
    RECTS = {}
    local el = { drawRect = function(_, x, y, w, h, a, r, g, b) RECTS[#RECTS + 1] = { x = x, y = y, w = w, h = h, r = r, g = g, b = b } end }
    return P.canvas(el, 0, 0, 1)
end
local function rowsDrawn()
    local ys = {}
    for _, r in ipairs(RECTS) do for y = r.y, r.y + r.h - 1 do ys[y] = (ys[y] or 0) + r.w end end
    return ys
end

-- ---------------------------------------------------------------------------
section("WHEELS")
-- ---------------------------------------------------------------------------
do
    local s, roll = P.drumFigures(41837.36, 6)
    check("five whole miles and the tenths", s == "418373", s)
    check("held at the start of a tenth", roll == 0, roll)
    s = P.drumFigures(128.64, 4)
    check("the trip: three whole miles and the tenths", s == "1286", s)
    s = P.drumFigures(7.2, 6)
    check("zero padded", s == "000072", s)
    s = P.drumFigures(123456.7, 6)
    check("rolled over past the last wheel", s == "234567", s)
    s = P.drumFigures(999.95, 4)
    check("the trip rolls over too", s == "9999", s)
    s = P.drumFigures(1000.0, 4)
    check("and comes round to zero", s == "0000", s)
    s = P.drumFigures(-3, 6)
    check("nothing below zero", s == "000000", s)
    s = P.drumFigures(nil, 6)
    check("no reading reads zero", s == "000000", s)
    s = P.drumFigures(2 ^ 33 + 0.4, 6)          -- far past 2^31: the remainders by floor hold
    check("a reading past 2^31 still turns the wheels right", s == "345924", s)
    local _, r1 = P.drumFigures(10.07, 6)
    check("70% into a tenth: still held", r1 == 0, r1)
    local _, r2 = P.drumFigures(10.09, 6)
    check("90% into a tenth: halfway over", near(r2, 0.5, 0.01), r2)
    local _, r3 = P.drumFigures(10.0999, 6)
    check("at the end of a tenth: nearly over", r3 > 0.95 and r3 <= 1, r3)
    check("the LCD kind: right-aligned to six", P.drumText("t  128", 6) == "t  128" and P.drumText("42", 6) == "    42")
    check("the LCD kind keeps the last six", P.drumText("1234567", 6) == "234567")

    -- the drawing: a 6-wheel row 5 px wide, 7 tall
    local p = { t = "drums", x = 100, y = 50, n = 6, cw = 5, ch = 7, fg = "#e8e4d8", last_fg = "#1a1a1a", tenths = true }
    P.drums(canvas(), p, 88888.84)
    local fg, last = P.color(p.fg), P.color(p.last_fg)
    local minx, maxx, miny, maxy, lastN, fgN = 1e9, -1e9, 1e9, -1e9, 0, 0
    for _, r in ipairs(RECTS) do
        minx, maxx = math.min(minx, r.x), math.max(maxx, r.x + r.w - 1)
        miny, maxy = math.min(miny, r.y), math.max(maxy, r.y + r.h - 1)
        if r.r == last.r and r.g == last.g then lastN = lastN + r.w elseif r.r == fg.r then fgN = fgN + r.w end
    end
    check("the figures sit in the 3 x 5 face, centered in their wheels", miny == 51 and maxy == 55, miny .. ".." .. maxy)
    check("the first figure at the wheel's left (cw 5: (5 - 4) // 2 = 0)", minx == 100, minx)
    check("the last figure in the last wheel", maxx == 100 + 5 * 5 + 2, maxx)
    check("an 8 is 13 pixels: five in fg, one in last_fg", fgN == 65 and lastN == 13, fgN .. " / " .. lastN)
    local p6 = { t = "drums", x = 0, y = 0, n = 2, cw = 6, ch = 8, fg = "#ffffff", last_fg = "#000000", tenths = true }
    P.drums(canvas(), p6, 1.0)
    local mx = 1e9
    for _, r in ipairs(RECTS) do mx = math.min(mx, r.x) end
    check("cw 6: the figure one pixel in ((6 - 4) // 2 = 1)", mx == 1, mx)

    -- the tenths wheel turning over: everything stays in the window; the old figure goes up, the new one comes up
    local ok = true
    for _, v in ipairs({ 10.081, 10.085, 10.09, 10.095, 10.0999 }) do
        P.drums(canvas(), p, v)
        for _, r in ipairs(RECTS) do if r.y < p.y or r.y + r.h - 1 >= p.y + p.ch then ok = false end end
    end
    check("a turning tenths wheel never draws outside its window", ok)
    P.drums(canvas(), p, 10.09)                    -- halfway: the 0 going up, the 1 coming up from below
    local lastRows = {}
    for _, r in ipairs(RECTS) do if r.x >= 125 then lastRows[r.y] = true end end
    check("halfway over: the leaving figure's foot is at the top of the window", lastRows[50] == true)
    check("halfway over: the coming figure's head is at the bottom", lastRows[56] == true)
    P.drums(canvas(), p, 10.07)
    local still = {}
    for _, r in ipairs(RECTS) do if r.x >= 125 then still[r.y] = true end end
    check("held: the tenths figure sits in its rows only", not still[50] and not still[56] and still[51] and still[55])
    local q = { t = "drums", x = 0, y = 0, n = 4, cw = 5, ch = 7, fg = "#ffffff", last_fg = "#000000" }
    P.drums(canvas(), q, 10.09)
    local outside = false
    for _, r in ipairs(RECTS) do if r.x >= 15 and (r.y < 1 or r.y > 5) then outside = true end end
    check("a row without tenths = true never rolls", not outside)

    -- the LCD kind: "t" in capitals, spaces drawn as nothing
    local lcd = { t = "drums", x = 230, y = 93, n = 6, cw = 5, ch = 10, fg = "#1c2418", last_fg = "#1c2418", text = true }
    P.drums(canvas(), lcd, "t  128")
    local cols = {}
    for _, r in ipairs(RECTS) do for x = r.x, r.x + r.w - 1 do cols[x] = true end end
    check("the t is drawn (as a capital T) in the first cell", cols[230] and cols[231] and cols[232])
    check("the spaces are empty", not cols[235] and not cols[240])
    local miny2 = 1e9
    for _, r in ipairs(RECTS) do miny2 = math.min(miny2, r.y) end
    check("centered in the LCD's 10 rows", miny2 == 95, miny2)
end

-- ---------------------------------------------------------------------------
section("PLATE")
-- ---------------------------------------------------------------------------
do
    local parts = {
        { t = "drums", src = "odo", x = 10, y = 10, n = 6, cw = 5, ch = 7, fg = "#e8e4d8", last_fg = "#1a1a1a", tenths = true },
        { t = "drums", src = "odoShownT", x = 10, y = 30, n = 6, cw = 5, ch = 10, fg = "#1c2418", last_fg = "#1c2418", text = true },
    }
    local function count(y0, y1)
        local n = 0
        for _, r in ipairs(RECTS) do if r.y >= y0 and r.y <= y1 then n = n + 1 end end
        return n
    end
    PL.drawParts(canvas(), parts, { power = false, odo = 41837.3, odoShownT = "041837" }, {})
    check("the wheels show with the key off", count(10, 16) > 0)
    check("the LCD is blank with the key off", count(30, 40) == 0)
    PL.drawParts(canvas(), parts, { power = true, odo = 41837.3, odoShownT = "041837" }, {})
    check("the LCD shows with the key on", count(30, 40) > 0)
    -- at night every run asks the light where it sits (the dark plate, lights off: the ambient level)
    local L = { n8 = 8, lit = false, amb = 1, levels = 15 }
    PL.drawParts(canvas(), { parts[1] }, { power = false, odo = 88888.8 }, { light = L })
    local dimmed = true
    local fg = P.color("#e8e4d8")
    for _, r in ipairs(RECTS) do if r.r >= fg.r - 0.0001 then dimmed = false end end
    check("at night, lights off, the wheels' figures are in the dark", dimmed and #RECTS > 0)
    PL.drawParts(canvas(), { parts[1] }, { power = false, odo = 88888.8 }, {})
    local day = false
    for _, r in ipairs(RECTS) do if math.abs(r.r - fg.r) < 0.0001 then day = true end end
    check("by day, their own color", day)
    -- every dash with a speedo dial carries the wheels; the electronic ones their windows (the export, DashPx.lua)
    local drumDash, elec = 0, {}
    for id, des in pairs(ZeD.DashPx.designs) do
        local odo, trip, hit = false, false, false
        for _, p in ipairs(des.parts) do
            if p.t == "drums" and p.src == "odo" then odo = true end
            if p.t == "drums" and p.src == "trip" then trip = true end
            if p.t == "drums" and p.src == "odoShownT" then elec[id] = true end
            if p.t == "digits" and p.src == "odoShown" then elec[id] = true end
        end
        for _, h in ipairs(des.hits) do if h.id == "tripReset" or h.id == "odoButton" then hit = true end end
        if odo and trip then drumDash = drumDash + 1 end
        if (odo or elec[id]) and not hit then check(id .. ": its odometer has a control", false) end
    end
    check("15 dashes turn wheels", drumDash == 15, drumDash)
    check("the Cossette, Lang 4000 and Dash Elite have electronic odometers", elec.cossette and elec.luxury and elec.dashelite)
end

-- ---------------------------------------------------------------------------
section("SEED")
-- ---------------------------------------------------------------------------
do
    local a, b = D.odoSeed(7, 90), D.odoSeed(7, 90)
    check("the same car, the same mileage", a == b, a)
    check("another car, another mileage", D.odoSeed(8, 90) ~= a)
    check("a worn engine has gone further", D.odoSeed(7, 20) > D.odoSeed(7, 95))
    local ok = true
    for _, id in ipairs({ 0, 1, 7, 32767, -32768, -1, 65535, 70000, 2 ^ 31, 2 ^ 40, 1.5 }) do
        for _, c in ipairs({ 0, 50, 100, -10, 250 }) do
            local v = D.odoSeed(id, c)
            if not (v == v and v >= 20000 and v < 140000) then ok = false; print("   seed", id, c, v) end
        end
    end
    check("every seed is a number inside 20000 .. 140000, odd ids and conditions too", ok)
    check("no condition reads as a sound engine", D.odoSeed(7, nil) == D.odoSeed(7, 100))
end

-- ---------------------------------------------------------------------------
section("COUNT")
-- ---------------------------------------------------------------------------
do
    local car = drive("d6", { keysIn = true, running = true, kmh = 0, engine = 90 })
    local seeded = car.md.ZeD_odo
    check("a car ZeD hasn't seen gets its mileage at once", near(seeded, D.odoSeed(7, 90), 1e-9), seeded)
    check("and the trip starts at 0", st().trip == 0, st().trip)
    car.kmh = 100
    frames(400, 250)                                   -- 100 s at 100 km/h
    local want = 100 * 0.6214 * 100 / 3600
    check("100 s at 100 km/h counts 1.726 miles", near(st().odo - seeded, want, 0.01), st().odo - seeded)
    check("the trip counts the same", near(st().trip, want, 0.01), st().trip)
    check("both kept on the car", near(car.md.ZeD_odo, st().odo, 1e-9) and near(car.md.ZeD_trip, st().trip, 1e-9))
    local o1 = st().odo
    car.running = false
    frames(40, 250)
    check("not running: nothing counts (coasting, towed)", near(st().odo, o1, 1e-9), st().odo)
    car.running = true
    newDash()                                          -- a reload: a new dash reads the car
    frame(0)
    check("a new dash reads the same figures", near(st().odo, o1, 1e-9) and near(st().trip, want, 0.01))
    local fare = inst._trips[7]
    check("the taxi's fare counter is its own (nothing on the fare without the flag)", fare and fare.fareMiles == 0)
    -- a frame longer than 250 ms counts as 250 (a hitch never jumps the odometer)
    local o2 = st().odo
    frame(5000)
    check("a long frame counts as 250 ms", near(st().odo - o2, 100 * 0.6214 * 0.25 / 3600, 1e-6), st().odo - o2)
    -- paused: nothing
    getGameSpeed = function() return 0 end
    local o3 = st().odo
    frames(10, 250)
    check("paused: nothing counts", near(st().odo, o3, 1e-9))
    getGameSpeed = function() return 1 end
    -- a passenger never counts or writes
    local pcar = drive("d6", { keysIn = true, running = true, kmh = 100, passenger = true, md = { ZeD_odo = 5000, ZeD_trip = 2 } })
    frames(40, 250)
    check("a passenger reads the car's figures", near(st().odo, 5000, 1e-9) and near(st().trip, 2, 1e-9))
    check("a passenger doesn't count", pcar.md.ZeD_odo == 5000 and pcar.md.ZeD_trip == 2)
    -- reversing counts too (the speed's size)
    local rcar = drive("d6", { keysIn = true, running = true, kmh = -20, md = { ZeD_odo = 100, ZeD_trip = 0 } })
    frames(40, 250)
    check("backing up still turns the wheels forward", st().odo > 100)
    -- no modData: the seed, no error
    local ncar = newCar({ script = SCRIPT.d6, keysIn = true, running = true, kmh = 50 })
    ncar.md = nil
    seat(ncar); newDash(); frames(4, 250)
    check("a car with no modData shows its seed and no error", near(st().odo, D.odoSeed(7, 90), 1e-9) and #env.errors == 0, env.errors[1])
end

-- ---------------------------------------------------------------------------
section("SHOW")
-- ---------------------------------------------------------------------------
do
    local s = { power = true, odo = 41837.36, trip = 128.64, odoTrip = false }
    D.odoShow(s)
    check("ODO: the VFD's whole miles", s.odoShown == 41837, s.odoShown)
    check("ODO: the LCD's six figures, zero padded", s.odoShownT == "041837", s.odoShownT)
    check("ODO: the ODO word lit, TRIP dark", s.odoMode == true and s.tripMode == false)
    s.odoTrip = true
    D.odoShow(s)
    check("TRIP: the VFD shows the trip", s.odoShown == 128, s.odoShown)
    check("TRIP: the LCD shows t and the trip", s.odoShownT == "t  128", s.odoShownT)
    check("TRIP: the TRIP word lit", s.odoMode == false and s.tripMode == true)
    s.power = false
    D.odoShow(s)
    check("key off: both words dark", s.odoMode == false and s.tripMode == false)
    s = { power = true, odo = 1234567.8, trip = 123456.7, odoTrip = false }
    D.odoShow(s)
    check("past six figures the LCD rolls over", s.odoShownT == "234567", s.odoShownT)
    s.odoTrip = true
    D.odoShow(s)
    check("the LCD trip keeps five figures after the t", s.odoShownT == "t23456", s.odoShownT)
    -- in the car: the Dash Elite's LCD and the Cossette's words
    local car = drive("dashelite", { keysIn = true, running = true, md = { ZeD_odo = 41837.36, ZeD_trip = 128.64 } })
    frame(100)
    check("the Dash Elite reads its car", st().odoShownT == "041837", st().odoShownT)
    car.md.ZeD_odoTrip = true
    frame(100)
    check("and shows the trip when the car says so", st().odoShownT == "t  128", st().odoShownT)
    car.md.ZeD_odoTrip = nil
    -- Metric: every odometer in kilometers, as the speed is; the car still keeps miles
    env.units = "Metric"
    frame(1000)                                        -- (the option is read again within a second)
    check("Metric: the LCD counts kilometers", st().odoShownT == "067330", st().odoShownT)
    check("Metric: the wheels' figures in kilometers", math.abs((st().odoView or 0) - 41837.36 * 1.609344) < 1e-6 and math.abs((st().tripView or 0) - 128.64 * 1.609344) < 1e-6)
    check("Metric: the car still keeps miles", near(car.md.ZeD_odo, 41837.36, 0.2) and near(st().odo, 41837.36, 0.2), car.md.ZeD_odo)
    car.md.ZeD_odoTrip = true
    frame(100)
    check("Metric: the trip in kilometers", st().odoShownT == "t  207", st().odoShownT)
    local m = { power = true, odo = 41837.36, trip = 128.64, odoTrip = false }
    D.odoShow(m)
    check("Metric: the VFD (Cossette, Luxury) counts kilometers", m.odoShown == 67330, m.odoShown)
    local cv = canvas()
    local seen = {}
    local PX = ZeD.Px
    local realDrums = PX.drums
    PX.drums = function(_, p, v) seen[p.src] = v end
    PL.drawParts(cv, { { t = "drums", src = "odo", x = 0, y = 0, n = 6, cw = 5, ch = 7, tenths = true },
                       { t = "drums", src = "trip", x = 0, y = 9, n = 4, cw = 5, ch = 6, tenths = true } }, m, {})
    PX.drums = realDrums
    check("Metric: the mechanical wheels turn in kilometers", seen.odo and math.abs(seen.odo - 41837.36 * 1.609344) < 1e-6 and seen.trip and math.abs(seen.trip - 128.64 * 1.609344) < 1e-6, tostring(seen.odo))
    env.units = "Imperial"
    car.md.ZeD_odoTrip = nil
    frame(1000)
    check("back to miles on the LCD", st().odoShownT == "041837", st().odoShownT)
end

-- ---------------------------------------------------------------------------
section("VERBS")
-- ---------------------------------------------------------------------------
do
    env.pad = true
    local car = drive("d6", { keysIn = true, running = true, md = { ZeD_odo = 500, ZeD_trip = 12.5 } })
    frame(100)
    local e = element("tripReset")
    check("the stem is on the pad's walk", e ~= nil)
    check("its A says what it does", e and e.promptA == "Reset trip", e and e.promptA)
    check("and it has no X", e and e.promptX == nil)
    inst:_fire("tripReset", false)
    check("A on the stem zeroes the trip", car.md.ZeD_trip == 0, car.md.ZeD_trip)
    check("and leaves the odometer", car.md.ZeD_odo == 500)
    -- a click on the stem's hit rect does the same
    car.md.ZeD_trip = 3
    frame(100)
    local hr
    for _, h in ipairs(inst._hit) do if h.id == "tripReset" then hr = h end end
    check("the stem has a click area", hr ~= nil)
    if hr then inst:onMouseDown(hr.x + 1, hr.y + 1) end
    check("a click on the stem zeroes the trip", car.md.ZeD_trip == 0, car.md.ZeD_trip)

    local ec = drive("dashelite", { keysIn = true, running = true, md = { ZeD_odo = 41837.36, ZeD_trip = 128.64 } })
    frame(100)
    e = element("odoButton")
    check("the window is on the pad's walk", e ~= nil)
    check("showing ODO: A says Trip", e and e.promptA == "Trip", e and e.promptA)
    check("showing ODO: no X (nothing to zero)", e and e.promptX == nil, e and e.promptX)
    inst:_fire("odoButton", true)
    check("a stray X on ODO does nothing", ec.md.ZeD_trip == 128.64 and not ec.md.ZeD_odoTrip)
    inst:_fire("odoButton", false)
    check("A switches to TRIP", ec.md.ZeD_odoTrip == true)
    frame(100)
    e = element("odoButton")
    check("the LCD shows the trip", st().odoShownT == "t  128", st().odoShownT)
    check("showing TRIP: A says Odometer", e and e.promptA == "Odometer", e and e.promptA)
    check("showing TRIP: X says Reset trip", e and e.promptX == "Reset trip", e and e.promptX)
    inst:_fire("odoButton", true)
    check("X while the trip shows zeroes it", ec.md.ZeD_trip == 0, ec.md.ZeD_trip)
    check("and stays on the trip", ec.md.ZeD_odoTrip == true)
    inst:_fire("odoButton", false)
    check("A again: back to ODO", ec.md.ZeD_odoTrip == false)
    -- the window needs the key; the stem doesn't
    ec.keysIn, ec.running = false, false
    frame(100)
    local en = nil
    for _, h in ipairs(inst._hit) do if h.id == "odoButton" then en = h.enabled end end
    check("key out: the window's button is off", en == false, en)
    local dc = drive("d6", { md = { ZeD_odo = 500, ZeD_trip = 4 } })
    frame(100)
    for _, h in ipairs(inst._hit) do if h.id == "tripReset" then en = h.enabled end end
    check("key out: the stem still works", en == true, en)
    inst:_fire("tripReset", false)
    check("and zeroes the trip", dc.md.ZeD_trip == 0)
    -- the Cossette and the Lang 4000 switch the same way
    for _, id in ipairs({ "cossette", "luxury" }) do
        local cc = drive(id, { keysIn = true, running = true, md = { ZeD_odo = 777.7, ZeD_trip = 55.5 } })
        frame(100)
        check(id .. ": the VFD shows the odometer", st().odoShown == 777 and st().odoMode == true, st().odoShown)
        inst:_fire("odoButton", false)
        frame(100)
        check(id .. ": A switches to the trip", st().odoShown == 55 and st().tripMode == true, st().odoShown)
    end
    -- a passenger can't press
    local pc = drive("d6", { keysIn = true, running = true, passenger = true, md = { ZeD_odo = 500, ZeD_trip = 9 } })
    frame(100)
    inst:_fire("tripReset", false)
    check("a passenger can't zero the trip", pc.md.ZeD_trip == 9)
    env.pad = false
end

-- ---------------------------------------------------------------------------
section("SERVER")
-- ---------------------------------------------------------------------------
do
    env.client = true
    -- the save flag on the last command sent: true at a coarse moment (a press, a first mileage, the engine off, the
    -- driver leaving), when the server sends the car's whole modData out; false for the tenths and a stop
    local function lastSave()
        for i = #SENT, 1, -1 do if SENT[i].command == ZeD.DashProto.ODO then return SENT[i].args.save end end
        return nil
    end
    local s0 = #SENT
    local car = drive("d6", { keysIn = true, running = true, kmh = 0, md = { ZeD_odo = 1000, ZeD_trip = 0 } })
    frames(4, 250)
    check("first sight of a car with figures: nothing sent", car.sent == 0, car.sent)
    car.kmh = 100
    -- one mile at 100 km/h: 3600 / 62.14 s
    local ms = 3600 / 62.14 * 1000
    for _ = 1, math.floor(ms / 250) do frame(250) end
    check("a mile driven: sent about ten times", car.sent >= 9 and car.sent <= 10, car.sent)
    local saves = 0
    for i = s0 + 1, #SENT do if SENT[i].args.save ~= false then saves = saves + 1 end end
    check("the tenths: none asks the server to send the car out", saves == 0, saves)
    local before = car.sent
    inst:_fire("tripReset", false)
    check("a press sends at once", car.sent == before + 1, car.sent - before)
    check("a press: save", lastSave() == true, tostring(lastSave()))
    -- the miles under a tenth that a drive ends on: they go when it ends (12 frames at 100 km/h: 0.052 mi)
    before = car.sent
    frames(12, 250)
    check("under a tenth since the last send: nothing yet", car.sent == before, car.sent - before)
    car.running = false
    frame(250)
    check("the engine stops: the rest goes at once", car.sent == before + 1, car.sent - before)
    check("the engine stops: save", lastSave() == true, tostring(lastSave()))
    frames(40, 250)
    check("and only once while it stays off", car.sent == before + 1, car.sent - before)
    car.running = true
    inst:_fire("tripReset", false)                     -- (each case starts from a send: a press sends at once)
    before = car.sent
    frames(12, 250)
    out()                                              -- (OnExitVehicle: D.hide, the engine still running)
    check("the driver gets out: the rest goes at once", car.sent == before + 1, car.sent - before)
    check("the driver gets out: save", lastSave() == true, tostring(lastSave()))
    check("and the dash is hidden: no prerender after", not inst:isVisible())
    frames(10, 250)
    check("and nothing more after", car.sent == before + 1, car.sent - before)
    seat(car)
    frame(250)
    inst:_fire("tripReset", false)
    before = car.sent
    frames(12, 250)
    car.passenger = true
    frame(250)
    check("the driver moves to another seat: the rest goes", car.sent == before + 1, car.sent - before)
    check("another seat: save", lastSave() == true, tostring(lastSave()))
    car.passenger = nil
    frame(250)
    inst:_fire("tripReset", false)
    before = car.sent
    frames(12, 250)
    local other = newCar({ script = SCRIPT.d6, keysIn = true, running = true, kmh = 0, id = 8, md = { ZeD_odo = 50, ZeD_trip = 0 } })
    seat(other)
    frame(250)
    check("the driver takes another car: the first one's rest goes", car.sent == before + 1, car.sent - before)
    check("and the other car sends nothing on first sight", other.sent == 0, other.sent)
    out()
    check("out of a car with nothing new: nothing sent", other.sent == 0, other.sent)
    -- a dash hidden some way that sent nothing, the driver gone, and the dash drawn again long after (the next car):
    -- the old car's miles are dropped, never sent from a parked car the server no longer looks after
    seat(car)
    frame(250)
    inst:_fire("tripReset", false)
    before = car.sent
    frames(12, 250)
    inst:setVisible(false)                             -- (no hide path: nothing sent)
    curCar = nil
    clock = clock + 20000
    seat(other)
    frame(250)
    check("a last send 20 s late is dropped", car.sent == before, car.sent - before)
    check("and nothing is left waiting to send", inst._odoCar == other, tostring(inst._odoCar))
    -- the UI hidden mid-drive (the hide-UI key): the dash stops counting, so its miles go first
    seat(car)
    frame(250)
    inst:_fire("tripReset", false)
    before = car.sent
    frames(12, 250)
    ISUIHandler = { allUIVisible = false }
    frame(250)
    check("the UI hidden while driving: the rest goes", car.sent == before + 1, car.sent - before)
    check("and the dash is hidden", not inst:isVisible())
    ISUIHandler = nil
    -- safe mode taking the dash away mid-drive sends the rest the same way as D.hide
    getPlayerVehicleDashboard = nil
    seat(car)
    frame(250)
    inst:_fire("tripReset", false)
    before = car.sent
    frames(12, 250)
    env.safe.dashboard.leave()
    check("safe mode takes the dash mid-drive: the rest goes", car.sent == before + 1 and not inst:isVisible(), car.sent - before)
    -- D.show (entering or changing seats) with no car hides the dash: the rest goes there too
    seat(car)
    frame(250)
    inst:_fire("tripReset", false)
    before = car.sent
    frames(12, 250)
    D.show(CHR)                                        -- (still in the car: shown, nothing sent)
    check("shown again in the same car: nothing sent", car.sent == before, car.sent - before)
    curCar = nil
    D.show(CHR)                                        -- (D.show with no car: hidden, the rest goes)
    check("D.show with no car hides and sends the rest", car.sent == before + 1 and not inst:isVisible(), car.sent - before)
    -- a car never seen: its new mileage goes out at once, so the other seats read the same
    local fresh = drive("d6", { keysIn = true, running = true, kmh = 0 })
    check("a first mileage goes out at once", fresh.sent == 1, fresh.sent)
    check("a first mileage: save", lastSave() == true, tostring(lastSave()))
    -- a passenger sends nothing
    local pc = drive("d6", { keysIn = true, running = true, kmh = 100, passenger = true, md = { ZeD_odo = 1, ZeD_trip = 0 } })
    frames(200, 250)
    check("a passenger sends no figures (its asks aside)", pc.sent == 0, pc.sent)
    -- no link to the server part (it failed to load): no error, still counting
    local link = ZeD.ServerPart
    ZeD.ServerPart = nil
    local old = drive("d6", { keysIn = true, running = true, kmh = 100 })
    frames(100, 250)
    check("no link to the server part: no error, still counting", #env.errors == 0 and st().odo > D.odoSeed(7, 90), env.errors[1])
    ZeD.ServerPart = link
    -- single player sends nothing
    env.client = false
    local sp = drive("d6", { keysIn = true, running = true, kmh = 100 })
    frames(200, 250)
    check("single player sends nothing", sp.sent == 0, sp.sent)
    env.client = true

    -- what goes: one command, the car's number and its three figures, nothing else
    SENT = {}
    local cc = drive("dashelite", { keysIn = true, running = true, kmh = 0, id = 21, md = { ZeD_odo = 500, ZeD_trip = 12.5, Roadworthy = { odo = 3 } } })
    frame(250)
    inst:_fire("odoButton", false)                     -- (A: the window shows the trip; a press sends at once)
    local c1 = SENT[#SENT]
    check("a press sends one command", #SENT == 1 and cc.sent == 1, #SENT)
    check("on the dash's module", c1 and c1.module == ZeD.DashProto.MOD and c1.command == ZeD.DashProto.ODO, c1 and c1.module)
    local keys = 0
    for _ in pairs(c1 and c1.args or {}) do keys = keys + 1 end
    check("with the car's number, its three figures and the save flag only", c1 and keys == 5 and c1.args.veh == 21
        and c1.args.odo == 500 and c1.args.trip == 12.5 and c1.args.show == true and c1.args.save == true, keys)
    check("the other mod's key never goes", c1 and c1.args.Roadworthy == nil)
    -- the car stops: the miles not sent yet go while the driver is still at the wheel (the game lets no one out of a
    -- car that isn't stopped, and its exit lands on the server before the dash's last send)
    cc.kmh = 100
    frames(12, 250)
    local before = cc.sent
    cc.kmh = 0
    frame(250)
    check("the car stops: the rest goes at once", cc.sent == before + 1, cc.sent - before)
    check("a stop with the engine on: no save", lastSave() == false, tostring(lastSave()))
    frames(40, 250)
    check("and once while it stays stopped", cc.sent == before + 1, cc.sent - before)
    cc.kmh = 0.5                                       -- (creeping under the game's stopped speed: no send each frame)
    frames(40, 250)
    check("creeping at a stop sends nothing more", cc.sent == before + 1, cc.sent - before)
    cc.kmh = 0
    frames(4, 250)
    check("stopped from a creep: nothing new to send", cc.sent == before + 1, cc.sent - before)
    -- the server's copy comes back after a send, as it was when sent: the driver's figures stand
    cc.kmh = 100
    frames(30, 250)
    local s1 = SENT[#SENT].args
    frames(6, 250)
    local odoNow, tripNow = st().odo, st().trip
    check("still counting past the last send", odoNow > s1.odo, odoNow - s1.odo)
    cc.md = { ZeD_odo = s1.odo, ZeD_trip = s1.trip, ZeD_odoTrip = s1.show, Roadworthy = { odo = 3 } }   -- (wiped, then the server's)
    frame(250)
    check("the echo doesn't wind the odometer back", st().odo > odoNow and cc.md.ZeD_odo > odoNow, st().odo - odoNow)
    check("nor the trip", st().trip > tripNow, st().trip - tripNow)
    check("the window stays on the trip", st().odoTrip == true and cc.md.ZeD_odoTrip == true)
    -- a reset, with an older send's echo landing after it: the trip stays at what was driven since the reset
    inst:_fire("odoButton", true)                      -- (X while the trip shows: zero)
    frames(2, 250)
    local tReset = st().trip
    check("the reset holds", tReset < 0.02, tReset)
    cc.md = { ZeD_odo = s1.odo, ZeD_trip = s1.trip, ZeD_odoTrip = true }
    frame(250)
    check("an old echo after the reset doesn't bring the trip back", st().trip < 0.02 and st().trip >= tReset, st().trip)
    -- a press, and an older send's echo landing before the next frame: the press stands
    frames(8, 250)
    inst:_fire("odoButton", false)                     -- (A: the window back to the odometer)
    cc.md = { ZeD_odo = s1.odo, ZeD_trip = s1.trip, ZeD_odoTrip = true }
    frame(250)
    check("a switch, then an old echo before the next frame: the switch stands", st().odoTrip == false
        and cc.md.ZeD_odoTrip == false, tostring(st().odoTrip))
    inst:_fire("odoButton", false)                     -- (the trip again)
    frames(8, 250)
    inst:_fire("odoButton", true)                      -- (zero)
    cc.md = { ZeD_odo = s1.odo, ZeD_trip = s1.trip, ZeD_odoTrip = true }
    frame(250)
    check("a reset, then an old echo before the next frame: the trip stays zeroed", st().trip < 0.02 and st().odoTrip == true, st().trip)
    check("and the press's send carried the reset", SENT[#SENT].args.trip < 0.02, SENT[#SENT].args.trip)

    -- stop-and-go traffic: crossing the stopped line again and again sends no more than the tenths do
    inst:_fire("tripReset", false)                     -- (from a send)
    local before = cc.sent
    for i = 1, 40 do cc.kmh = (i % 2 == 1) and 1.2 or 0; frame(250) end
    check("creeping in and out of a stop: no send for each crossing", cc.sent == before, cc.sent - before)
    cc.kmh = 30
    frames(8, 250)                                     -- (0.01 mi and more)
    cc.kmh = 0
    frame(250)
    check("a real stop after that: the rest goes", cc.sent == before + 1, cc.sent - before)
    -- the engine off with nothing new since that send: the same figures go once more, with save, so the server sends
    -- out what it took
    local so = SENT[#SENT].args.odo
    cc.running = false
    frame(250)
    check("the engine off, nothing new: one send with save", cc.sent == before + 2 and lastSave() == true
        and SENT[#SENT].args.odo == so, cc.sent - before)
    frames(10, 250)
    check("and only one", cc.sent == before + 2, cc.sent - before)
    cc.running = true
    frame(250)
    -- stopped, the engine on: a press, then an older copy of the car at the same odometer (the server's send of the
    -- figures before the press): the press stands
    local E = { odo = cc.md.ZeD_odo, trip = cc.md.ZeD_trip, show = cc.md.ZeD_odoTrip }
    check("the trip shows, and isn't zero", E.show == true and E.trip > 0, E.trip)
    inst:_fire("odoButton", true)                      -- (X while the trip shows: zero)
    check("a press while stopped: saved at once", lastSave() == true and SENT[#SENT].args.trip == 0)
    cc.md = { ZeD_odo = E.odo, ZeD_trip = E.trip, ZeD_odoTrip = E.show }
    frame(250)
    check("stopped: an older copy at the same odometer doesn't bring the trip back", st().trip == 0 and cc.md.ZeD_trip == 0
        and st().odo == E.odo, st().trip)
    inst:_fire("odoButton", false)                     -- (A: the window to the odometer)
    cc.md = { ZeD_odo = E.odo, ZeD_trip = 0, ZeD_odoTrip = true }
    frame(250)
    check("stopped: nor the switch", st().odoTrip == false and cc.md.ZeD_odoTrip == false, tostring(st().odoTrip))
    inst:_fire("odoButton", false)                     -- (back to the trip)
    frame(250)

    -- the server refused this driver's figures as behind its own (ZeD_ServerDash.lua): its answer puts them on its figures
    local route = ROUTES[ZeD.DashProto.MOD]
    check("the dash takes the server's answers", type(route) == "function")
    local X = st().odo
    before = cc.sent
    route(ZeD.DashProto.SYNC, { veh = 21, odo = X + 50, trip = 3, sent = X - 0.05 })
    frame(250)
    check("the server's odometer was ahead: on from it, plus the miles since the refused send",
        near(st().odo, X + 50.05, 1e-6) and near(cc.md.ZeD_odo, X + 50.05, 1e-6), st().odo - X)
    check("and the trip from the server's, plus the same", near(st().trip, 3.05, 1e-6), st().trip)
    check("the window keeps the driver's switch", st().odoTrip == true)
    check("nothing sent until a tenth past the server's", cc.sent == before, cc.sent - before)
    route(ZeD.DashProto.SYNC, { veh = 21, odo = X + 80, trip = 1, sent = X - 0.1 })
    frame(250)
    check("an answer to a send from before that one: dropped", near(st().odo, X + 50.05, 1e-6), st().odo - X)
    -- the trip too far (another driver zeroed it, and this copy never heard): the odometer stands, the trip is the server's
    local Y = st().odo
    route(ZeD.DashProto.SYNC, { veh = 21, odo = Y - 0.3, trip = 0.5, sent = Y })
    frame(250)
    check("the trip refused: the odometer stands", near(st().odo, Y, 1e-6), st().odo - Y)
    check("the trip is the server's, plus the miles past its figure", near(st().trip, 0.8, 1e-6), st().trip)
    cc.kmh = 50
    frame(250)
    local sy = SENT[#SENT].args
    check("the next send goes at once, in step with the server", cc.sent == before + 1
        and near(sy.trip - 0.5, sy.odo - (Y - 0.3), 1e-6), cc.sent - before)
    cc.kmh = 0
    frame(250)
    local O = st().odo
    route(ZeD.DashProto.SYNC, { veh = 99, odo = O + 10, trip = 0, sent = O })
    route(ZeD.DashProto.SYNC, { veh = 21, odo = "lots", trip = 0, sent = O })
    route(ZeD.DashProto.SYNC, { veh = 21, odo = 0 / 0, trip = 0, sent = O })
    route("nonsense", { veh = 21, odo = O + 10, trip = 0, sent = O })
    frame(250)
    check("another car's answer, junk or another command: nothing", near(st().odo, O, 1e-9) and #env.errors == 0, st().odo - O)
    -- another seat: the dash reads the car as it comes (a passenger's figures are the server's)
    local function asks()
        local n, last = 0, nil
        for _, c in ipairs(SENT) do if c.command == ZeD.DashProto.ASK then n, last = n + 1, c.args end end
        return n, last
    end
    check("the driver's dash never asks for the figures", asks() == 0, asks())
    cc.passenger = true
    frame(250)
    local nA, lastA = asks()
    local keysA = 0
    for _ in pairs(lastA or {}) do keysA = keysA + 1 end
    check("a passenger's dash asks the server for the car's figures as it sits down", nA == 1 and lastA.veh == 21
        and keysA == 1, nA)
    frame(250)
    check("and not again a moment later", asks() == 1, asks())
    cc.md = { ZeD_odo = 600, ZeD_trip = 1, ZeD_odoTrip = false }
    frame(250)
    check("a passenger takes the server's figures as they come", st().odo == 600 and st().trip == 1, st().odo)
    -- the figures the server took from the driver, sent to the other seats (DP.FIG): onto this copy of the car only
    local nSent = #SENT
    route(ZeD.DashProto.FIG, { veh = 21, odo = 610, trip = 2, show = true })
    frame(250)
    check("a passenger: the driver's figures from the server go on this copy of the car", cc.md.ZeD_odo == 610
        and cc.md.ZeD_trip == 2 and cc.md.ZeD_odoTrip == true and st().odo == 610 and st().odoTrip == true, st().odo)
    route(ZeD.DashProto.FIG, { veh = 99, odo = 620, trip = 2, show = true })
    route(ZeD.DashProto.FIG, { veh = 21, odo = 620, trip = 700, show = true })
    route(ZeD.DashProto.FIG, { veh = 21, odo = "lots", trip = 2, show = true })
    route(ZeD.DashProto.FIG, { veh = 21, odo = 0 / 0, trip = 2, show = true })
    route(ZeD.DashProto.FIG, { veh = 21, odo = 620, trip = 2, show = 1 })
    route(ZeD.DashProto.FIG, nil)
    frame(250)
    check("another car's figures, a trip past the odometer, junk: nothing", cc.md.ZeD_odo == 610 and cc.md.ZeD_trip == 2
        and #env.errors == 0, cc.md.ZeD_odo)
    check("a passenger sends nothing for them", #SENT == nSent, #SENT - nSent)
    frames(12, 250)
    check("the figures came: the passenger asks no more", asks() == 1, asks())
    cc.passenger = nil
    frame(250)
    local O2 = st().odo
    route(ZeD.DashProto.FIG, { veh = 21, odo = O2 + 100, trip = 0, show = false })
    frame(250)
    check("at the wheel: the dash keeps its own figures", st().odo == O2 and cc.md.ZeD_odo == O2, st().odo - O2)
    -- a passenger whose ask goes unanswered (the server doesn't see them seated yet, or holds no figures): again every
    -- 2 s, three times at most; out and back in, it asks again
    local a0 = asks()
    local pq = drive("nyala", { keysIn = true, running = true, kmh = 0, id = 41, passenger = true,
        md = { ZeD_odo = 900, ZeD_trip = 3 } })
    check("a new passenger asks at once", asks() == a0 + 1, asks() - a0)
    frames(7, 250)
    check("no answer: not again inside 2 s", asks() == a0 + 1, asks() - a0)
    frames(2, 250)
    check("no answer after 2 s: asked again", asks() == a0 + 2, asks() - a0)
    frames(40, 250)
    check("three asks at most", asks() == a0 + 3, asks() - a0)
    local _, la = asks()
    check("each ask names the car", la.veh == 41, la.veh)
    out()
    seat(pq)
    frame(250)
    check("out and back in: asks again", asks() == a0 + 4, asks() - a0)
    pq.passenger = nil
    frames(12, 250)
    check("at the wheel: no ask", asks() == a0 + 4, asks() - a0)
    pq.passenger = true
    frame(250)
    check("back to a passenger seat: asks again", asks() == a0 + 5, asks() - a0)
    -- the join rules answered (ZeD_ServerLink.lua, S.agreed counts them): until then the server refused every ask and send
    frames(40, 250)
    local a1 = asks()
    check("a passenger's three asks spent", asks() == a0 + 7, asks() - a0)
    ZeD.ServerPart.agreedN = (ZeD.ServerPart.agreedN or 0) + 1
    frame(250)
    check("the join rules answered: a passenger whose asks were refused asks again", asks() == a1 + 1, asks() - a1)
    frames(40, 250)
    check("and three times at most again", asks() == a1 + 3, asks() - a1)
    pq.passenger = nil
    frame(250)
    inst:_fire("tripReset", false)
    local b0 = pq.sent
    pq.kmh = 100
    frames(4, 250)
    check("a driver under a tenth since the last send: nothing yet", pq.sent == b0, pq.sent - b0)
    ZeD.ServerPart.agreedN = ZeD.ServerPart.agreedN + 1
    frame(250)
    check("the join rules answered: the driver's figures go at once (the server refused the ones before)", pq.sent == b0 + 1, pq.sent - b0)
    frames(4, 250)
    check("and only once", pq.sent == b0 + 1, pq.sent - b0)
    pq.kmh = 0
    local aSP = asks()
    env.client = false
    drive("nyala", { keysIn = true, running = true, kmh = 0, id = 42, passenger = true, md = { ZeD_odo = 900, ZeD_trip = 3 } })
    frames(12, 250)
    check("single player: a passenger never asks", asks() == aSP, asks() - aSP)
    env.client = true

    -- the ash tray on a server: the car's, one tray a car (known issue Nov 7 2026: it was each player's, for the
    -- session). The press shows at once on this copy and asks the server, which writes its own and sends the car out
    local ac = drive("luxury", { keysIn = true, running = true, kmh = 0, id = 31, md = { ZeD_odo = 10, ZeD_trip = 0 } })
    frame(250)
    local ash0 = st().ashIsOpen
    local nSent = #SENT
    inst:_fire("ash", false)
    frame(250)
    check("on a server the ash tray opens or shuts", st().ashIsOpen == not ash0, tostring(st().ashIsOpen))
    check("and shows on this copy of the car at once", ac.md.ZeD_ash == not ash0, tostring(ac.md.ZeD_ash))
    local ashCmd = nil
    for i = nSent + 1, #SENT do if SENT[i].command == ZeD.DashProto.ASH then ashCmd = SENT[i] end end
    check("the press asks the server for the car's tray", ashCmd ~= nil and ashCmd.module == ZeD.DashProto.MOD
        and ashCmd.args.veh == 31 and ashCmd.args.open == not ash0 and ashCmd.player == CHR, ashCmd and tostring(ashCmd.args.open))
    ac.md = { ZeD_odo = 10, ZeD_trip = 0, ZeD_ash = not ash0 }   -- (the server took it and sent the car out)
    frame(250)
    check("the server's copy keeps it", st().ashIsOpen == not ash0)
    ac.md = { ZeD_odo = 10, ZeD_trip = 0, ZeD_ash = ash0 }       -- (another seat shut it again: the server's send)
    frame(250)
    check("another seat's press, sent out by the server, shows here", st().ashIsOpen == ash0)
    env.client = false
    local sc = drive("luxury", { keysIn = true, running = true, kmh = 0, id = 32, md = { ZeD_odo = 10, ZeD_trip = 0 } })
    frame(250)
    local ash1 = st().ashIsOpen
    inst:_fire("ash", false)
    frame(250)
    check("single player keeps the tray on the car's modData", sc.md.ZeD_ash == (not ash1) and st().ashIsOpen == not ash1)
    env.client = true

    -- across every case above: the client never sent the car's modData itself
    local tx = 0
    for _, car in ipairs(ALLCARS) do tx = tx + car.transmits end
    check("the client never calls transmitModData", tx == 0, tx)
    local junk = 0
    for _, c in ipairs(SENT) do
        local a = c.args
        if c.command == ZeD.DashProto.ASK then
            if not ZeD.DashProto.okVeh(a.veh) then junk = junk + 1 end
        elseif c.command == ZeD.DashProto.ASH then
            if not ZeD.DashProto.okAsh(a) then junk = junk + 1 end
        elseif not (c.command == ZeD.DashProto.ODO and ZeD.DashProto.okVeh(a.veh) and ZeD.DashProto.okMiles(a.odo)
            and ZeD.DashProto.okMiles(a.trip) and type(a.show) == "boolean" and a.trip <= a.odo) then junk = junk + 1 end
    end
    check("every command sent is one the server takes the shape of", #SENT > 0 and junk == 0, junk)
    env.client = false
end

-- ---------------------------------------------------------------------------
section("SPLIT")
-- ---------------------------------------------------------------------------
do
    env.client = true
    -- two local players: the first a passenger in car 51, the second at the wheel of car 52; then both in car 53
    local cars = {}
    local function chr(pn)
        return { getVehicle = function() return cars[pn] end, getPlayerNum = function() return pn end,
            isLocalPlayer = function() return true end,
            getInventory = function() return { haveThisKeyId = function() return true end } end }
    end
    local P0, P1 = chr(0), chr(1)
    local PLAYERS = { [0] = P0, [1] = P1 }
    local saveGSP = getSpecificPlayer
    getSpecificPlayer = function(pn) return PLAYERS[pn] end
    local saveNew = ZeD_Panel.new
    ZeD_Panel.new = function(cls, x, y, w, h)
        local o = saveNew(cls, x, y, w, h)
        o.initialise, o.addToUIManager = noop, noop
        return o
    end
    D._instance, D._instances = nil, {}
    local c51 = newCar({ id = 51, script = SCRIPT.nyala, keysIn = true, running = true, kmh = 0, md = { ZeD_odo = 300, ZeD_trip = 1 } })
    local c52 = newCar({ id = 52, script = SCRIPT.nyala, keysIn = true, running = true, kmh = 0, md = { ZeD_odo = 700, ZeD_trip = 2 } })
    c51.isDriver = function(self, p) return p == self.driverChr end
    c52.isDriver = function(self, p) return p == self.driverChr end
    c52.driverChr = P1
    cars[0], cars[1] = c51, c52
    D.show(P0)
    D.show(P1)
    local d0, d1 = D.getInstance(0), D.getInstance(1)
    check("each local player gets a dash of their own", d0 ~= nil and d1 ~= nil and d0 ~= d1, tostring(d1))
    check("the second player's dash is theirs", d1 and d1.playerNum == 1)
    check("the first player's dash is still the one the other parts know", D._instance == d0 and D.getInstance() == d0)
    local function pre(d) clock = clock + 250; if d and d:isVisible() then d:prerender() end end
    for _ = 1, 4 do pre(d0); pre(d1) end
    -- the second player drives: their miles go to the server as them
    local n0 = #SENT
    c52.kmh = 100
    for _ = 1, 40 do pre(d0); pre(d1) end          -- (10 s at 100 km/h: well past a tenth)
    local mine, other = 0, 0
    for i = n0 + 1, #SENT do
        local c = SENT[i]
        if c.command == ZeD.DashProto.ODO and c.args.veh == 52 then
            if c.player == P1 then mine = mine + 1 else other = other + 1 end
        end
    end
    check("the second player's miles are sent as the second player", mine > 0 and other == 0, mine .. "/" .. other)
    check("and counted on their car", (c52.md.ZeD_odo or 0) > 700, c52.md.ZeD_odo)
    -- the first player rides in car 51: the server's figures for 51 reach their dash's copy, not the driver's car
    local route = ROUTES[ZeD.DashProto.MOD]
    route(ZeD.DashProto.FIG, { veh = 51, odo = 333, trip = 3, show = false })
    check("figures for the first player's car reach it", c51.md.ZeD_odo == 333, c51.md.ZeD_odo)
    local odo52 = c52.md.ZeD_odo
    route(ZeD.DashProto.FIG, { veh = 52, odo = 10, trip = 0, show = false })
    check("figures for a car a local player drives are not taken (its driver keeps their own)", c52.md.ZeD_odo == odo52)
    -- the first player's passenger ask goes as them
    local askBy = nil
    for i = n0 + 1, #SENT do if SENT[i].command == ZeD.DashProto.ASK and SENT[i].args.veh == 51 then askBy = SENT[i].player end end
    check("the first player's ask goes as the first player", askBy == P0, tostring(askBy))
    -- the server refuses the second player's figures: its answer reaches the second player's dash
    local o1 = d1 and d1._odoMine and d1._odoMine.odo or 0
    route(ZeD.DashProto.SYNC, { veh = 52, odo = o1 + 40, trip = 1, sent = o1 })
    pre(d1)
    check("a refusal reaches the driver's dash, the second player's", d1._odoMine and near(d1._odoMine.odo, o1 + 40, 0.01), d1._odoMine and d1._odoMine.odo)
    -- the second player as a passenger of car 53, the first at its wheel: the second player asks as themselves
    local c53 = newCar({ id = 53, script = SCRIPT.nyala, keysIn = true, running = true, kmh = 0, md = { ZeD_odo = 900, ZeD_trip = 0 } })
    c53.isDriver = function(self, p) return p == self.driverChr end
    c53.driverChr = P0
    cars[0], cars[1] = c53, c53
    local n1 = #SENT
    for _ = 1, 3 do pre(d0); pre(d1) end
    local ask1 = nil
    for i = n1 + 1, #SENT do if SENT[i].command == ZeD.DashProto.ASK and SENT[i].args.veh == 53 then ask1 = SENT[i].player end end
    check("the second player's ask goes as the second player", ask1 == P1, tostring(ask1))
    local o53 = c53.md.ZeD_odo
    route(ZeD.DashProto.FIG, { veh = 53, odo = o53 - 5, trip = 0, show = false })
    check("figures for a car this client drives (another seat's) are not taken", c53.md.ZeD_odo == o53)
    -- the controller: the first player's dash only (the focus follows the first player's pad)
    check("the second player's dash never takes the pad", D.canTakePad(P1) == false)
    -- each player's leaving hides their own dash
    cars[1] = nil
    D.hide(P1)
    check("the second player out: their dash hides, the first's stays", d1 ~= nil and d0 ~= nil and not d1:isVisible() and d0:isVisible())
    getSpecificPlayer = saveGSP
    ZeD_Panel.new = saveNew
    env.client = false
end

-- ---------------------------------------------------------------------------
section("HOT")
-- ---------------------------------------------------------------------------
do
    drive("race", { keysIn = true, running = false })
    frame(100)
    check("key on: the hot lamp in the bulb check", st().tempLamp == true and st().oilLamp == true and st().beltLamp == true)
    drive("race", { keysIn = true, running = true })
    frames(4, 250)
    check("running and cool: dark", st().tempLamp == false, st().tempLamp)
    drive("race", { keysIn = true, running = true, engine = 20 })
    frames(4, 250)
    check("running and hot: lit", st().tempLamp == true, st().tempLamp)
    drive("race", {})
    frame(100)
    check("key out: dark", st().tempLamp == false, st().tempLamp)
    local water = false
    for _, p in ipairs(ZeD.DashPx.designs.race.parts) do if p.t == "lamp" and p.src == "tempLamp" then water = true end end
    check("the race car's WATER jewel is the hot lamp", water)
    local dartTemp = false
    for _, p in ipairs(ZeD.DashPx.designs.dart.parts) do if p.t == "needle" and p.src == "temp" then dartTemp = true end end
    check("the Dart's new gauge reads the temperature every gauge reads", dartTemp)
    -- the Simple dash's Temperature bar: red for a hot engine, not for the bulb check (review, Nov 7 2026)
    env.simple = true
    local function barIn(log, col)
        for _, l in ipairs(log) do if l:find("drawFillBar", 1, true) and l:find(col, 1, true) then return true end end
        return false
    end
    drive("d6", { keysIn = true, running = false })
    local log = frame(100)
    check("Simple, key on and cold: the hot lamp is in the bulb check", st().tempLamp == true)
    check("Simple, key on and cold: no red bar", barIn(log, "accent") and not barIn(log, "danger"))
    drive("d6", { keysIn = true, running = true, engine = 20 })
    frames(4, 250)
    log = frame(100)
    check("Simple, running hot: the Temperature bar is red", barIn(log, "danger"))
    env.simple = false
end

-- ---------------------------------------------------------------------------
section("SIMPLE")
-- ---------------------------------------------------------------------------
do
    env.simple, env.pad = true, true
    local function drew(log, s)
        for _, l in ipairs(log) do if l:find(s, 1, true) then return true end end
        return false
    end
    local car = drive("d6", { keysIn = true, running = true, md = { ZeD_odo = 41837.36, ZeD_trip = 128.64 } })
    local log = frame(100)
    check("Odometer in miles", drew(log, "41837 mi"))
    check("Trip in miles, one decimal", drew(log, "Trip") and drew(log, "128.6 mi"))
    env.units = "Metric"
    log = frame(1000)                                  -- (the option is read again within a second)
    check("Odometer in km", drew(log, "67330 km"), "41837.36 mi")
    check("Trip in km, one decimal", drew(log, "207.0 km"))
    env.units = "Imperial"
    env.unitReads = 0
    frames(10, 100)                                    -- one second of frames
    check("the units option is read at most twice a second, not every frame", env.unitReads <= 2, env.unitReads)
    log = frame(1000)
    check("back to miles", drew(log, "41837 mi"))
    -- the speed in the same units as the Odometer and Trip (review of beta 7: "0 mph" beside "95507 km")
    car.kmh = 100
    frames(20, 250)                                    -- (the needle settles)
    log = frame(100)
    check("Simple speed in mph with Imperial", drew(log, "drawText 62 ") and drew(log, "drawText mph "))
    env.units = "Metric"
    log = frame(1000)
    check("Simple speed in km/h with Metric", drew(log, "drawText 100 ") and drew(log, "drawText km/h "))
    check("no mph beside km", not drew(log, "drawText mph ") and drew(log, " km "))
    env.units = "Imperial"
    log = frame(1000)
    check("back to mph", drew(log, "drawText 62 ") and drew(log, "drawText mph ") and not drew(log, "km/h"))
    car.kmh = 0
    frames(20, 250)
    local e = element("tripReset")
    check("the Trip cell is on the pad's walk", e ~= nil)
    check("its A says Reset trip", e and e.promptA == "Reset trip", e and e.promptA)
    local n = 0
    for _, el in ipairs(inst._elements) do if el.id == "dash:tripReset" or el.id == "dash:odoButton" then n = n + 1 end end
    check("the stem isn't a button too (one trip control)", n == 1, n)
    inst:_fire("tripReset", false)
    check("A on Trip zeroes it", car.md.ZeD_trip == 0)
    car.md.ZeD_trip = 7
    frame(100)
    local hr
    for _, h in ipairs(inst._hit) do if h.id == "tripReset" then hr = h end end
    check("the Trip cell has a click area", hr ~= nil and hr.enabled)
    if hr then inst:onMouseDown(hr.x + 1, hr.y + 1) end
    check("a click on Trip zeroes it", car.md.ZeD_trip == 0, car.md.ZeD_trip)
    -- the Dash Elite on the Simple dash: the same one cell, no ODO / TRIP switch
    drive("dashelite", { keysIn = true, running = true, md = { ZeD_odo = 1, ZeD_trip = 2 } })
    frame(100)
    n = 0
    for _, el in ipairs(inst._elements) do if el.id == "dash:tripReset" or el.id == "dash:odoButton" then n = n + 1 end end
    check("the Dash Elite on Simple: one trip control", n == 1 and element("tripReset") ~= nil, n)
    env.simple, env.pad = false, false
end

-- ---------------------------------------------------------------------------
section("DIGITAL")
-- ---------------------------------------------------------------------------
-- (director, Nov 7 2026, "digital readouts only": the Lang 4000's and the Cossette's speed figures follow the game's
-- Metric option and light the legend in use, KM/H or MPH; every needle and wheel stays in mph and miles)
do
    local figures, needlesMph, others = {}, true, {}
    for id, des in pairs(ZeD.DashPx.designs) do
        for _, p in ipairs(des.parts or {}) do
            if p.t == "digits" and (p.src == "speed_mph" or p.src == "speed_kmh") then others[#others + 1] = id end
            if p.t == "digits" and p.src == "speedShown" then figures[id] = true end
            if (p.t == "needle" or p.t == "ribbon") and p.src and p.src:find("speed", 1, true) and p.src ~= "speed_mph" then needlesMph = false end
        end
    end
    check("the Lang 4000 and the Cossette show speedShown", figures.luxury and figures.cossette)
    check("no digital figure reads mph alone, in any design", #others == 0, others[1])
    check("every speed needle and ribbon still reads mph", needlesMph)
    for _, id in ipairs({ "luxury", "cossette" }) do
        local lamps = {}
        for _, p in ipairs(ZeD.DashPx.designs[id].parts) do if p.t == "lamp" then lamps[p.src] = true end end
        check(id .. ": an MPH and a KM/H legend", lamps.mphLamp and lamps.kmhLamp)
        local car = drive(id, { keysIn = true, running = true, kmh = 100, md = { ZeD_odo = 10, ZeD_trip = 0 } })
        env.units = "Imperial"
        frames(20, 250)
        local s = st()
        check(id .. ": Imperial, the figures in mph", near(s.speedShown, 62.14, 0.6), s.speedShown)
        check(id .. ": Imperial, MPH lit, KM/H dark", s.mphLamp == true and s.kmhLamp == false)
        env.units = "Metric"
        frame(1000)
        s = st()
        check(id .. ": Metric, the figures in km/h", near(s.speedShown, 100, 1), s.speedShown)
        check(id .. ": Metric, KM/H lit, MPH dark", s.kmhLamp == true and s.mphLamp == false)
        check(id .. ": Metric, the needles' mph unchanged", near(s.speed_mph, 62.14, 0.6), s.speed_mph)
        car.keysIn, car.running = false, false
        frames(4, 250)
        s = st()
        check(id .. ": key off, both legends dark", s.kmhLamp == false and s.mphLamp == false)
        env.units = "Imperial"
        frame(1000)
    end
end

-- ---------------------------------------------------------------------------
-- From the in-game dash scripts (the QA cleanup, Nov 12 2026): KEYS (zedqa_dash_keys_edge.lua, zedqa_dash_r6_keys.lua),
-- BRANDS (zedqa_dash_brands.lua), NIGHT (zedqa_dashnight.lua), PARTS (zedqa_dash_r6_parts.lua)
-- ---------------------------------------------------------------------------
function Car:getEngineState() return self.engState or (self.running and "Running" or "Idle") end
function Car:getSquare() local lux = self.lux or 1; return { getLightLevel = function() return lux end, getX = function() return 0 end,
    getY = function() return 0 end, getZ = function() return 0 end } end
function Car:getX() return self.x or 0 end
function Car:getY() return self.y or 0 end
function Car:getAngleX() return 0 end
function Car:getAngleZ() return 0 end
function Car:getHeadlightsOn() return self.lights or false end
function Car:getHeadlightCanEmmitLight() return self.lights or false end
ISVehicleMenu = { onStartEngine = noop, onShutOff = noop, onToggleHeadlights = noop }

section("KEYS")
do
    -- the key's place each 30 ms frame, written down as it changes, with the time of each change
    local function watch(ms, n)
        local last = tostring(st().keyPos)
        local seq, at = { last }, { clock }
        for _ = 1, n do
            frame(ms)
            local k = tostring(st().keyPos)
            if k ~= last then seq[#seq + 1] = k; at[#at + 1] = clock; last = k end
        end
        return seq, at
    end
    local function steps(at)
        local lo, hi = 1e9, 0
        for i = 3, #at do lo = math.min(lo, at[i] - at[i - 1]); hi = math.max(hi, at[i] - at[i - 1]) end
        return lo, hi
    end
    local car = drive("nyala", { keysIn = true })
    frames(3, 30)
    check("KEYS the key in, the engine off: ACC", st().keyPos == "acc", st().keyPos)
    check("KEYS the dash flush on the screen's bottom edge", inst:getY() + inst:getHeight() == 1080, inst:getY() + inst:getHeight())
    -- the click on the key with the engine off: the hand turns it to START; the engine cranks, then runs
    inst:_fire("ignition", false)
    local s1, at1 = watch(30, 8)
    car.engState = "StartingSuccess"
    local s2 = watch(30, 20)
    car.engState, car.running = nil, true
    local s3, at3 = watch(30, 20)
    local all, ats = {}, {}
    for _, t in ipairs({ { s1, at1 }, { s2, nil }, { s3, at3 } }) do
        for i, k in ipairs(t[1]) do if all[#all] ~= k then all[#all + 1] = k; if t[2] then ats[#ats + 1] = t[2][i] end end end
    end
    check("KEYS a start: ACC - OFF - ON - START - ON", table.concat(all, "-") == "acc-off-on-start-on", table.concat(all, "-"))
    check("KEYS running: ON", st().keyPos == "on", st().keyPos)
    local lo, hi = steps(at1)
    check("KEYS each step of the turn 90 to 400 ms", #at1 >= 3 and lo >= 90 and hi <= 400, #at1 .. ": " .. lo .. ".." .. hi)
    -- shut off: ON held a step, then OFF, then ACC
    car.running = false
    local s4, at4 = watch(30, 20)
    check("KEYS shut off: ON - OFF - ACC", table.concat(s4, "-") == "on-off-acc", table.concat(s4, "-"))
    lo, hi = steps(at4)
    check("KEYS the shut-off's steps 90 to 400 ms", lo >= 90 and hi <= 400, lo .. ".." .. hi)
    -- a dry start: the key held at START while the hand turns it, then back to ACC
    inst:_fire("ignition", false)
    local s5 = watch(30, 50)
    check("KEYS an empty-tank start falls back: ACC - OFF - ON - START - ON - OFF - ACC", table.concat(s5, "-") == "acc-off-on-start-on-off-acc", table.concat(s5, "-"))
    car.keysIn = false
    frame(30)
    check("KEYS the key out: no key drawn", st().keyPos == nil, st().keyPos)
    -- the ash tray: a click opens or shuts it, on the car; the fleet dashes have none
    car.keysIn = true
    frame(30)
    local was = st().ashIsOpen
    inst:_fire("ash", false)
    frame(30)
    check("KEYS a click on the ash tray opens or shuts it", st().ashIsOpen == not was and car.md.ZeD_ash == not was)
    inst:_fire("ash", false)
    frame(30)
    check("KEYS and back", st().ashIsOpen == was)
    for _, id in ipairs({ "police", "fire", "ambulance", "ranger" }) do
        local des = ZeD.DashPx.designs[id]
        local tray = false
        for _, p in ipairs(des and des.parts or {}) do if p.src == "ashOpen" then tray = true end end
        for _, h in ipairs(des and des.hits or {}) do if h.id == "ash" then tray = true end end
        check("KEYS no ash tray on the " .. id .. " dash", des and not tray)
    end
    out()
end

section("BRANDS")
do
    -- the game's own English car names (IGUI_VehicleName<model>, the game's IG_UI.json)
    local NAMES = { CarLuxury = "Mercia Lang 4000", CarNormal = "Chevalier Nyala", SportsCar = "Chevalier Cossette",
        PickUpTruck = "Chevalier D6", ModernCar = "Dash Elite", ModernCar02 = "Chevalier Primani", SmallCar = "Chevalier Dart",
        SmallCar02 = "Masterson Horizon", CarStationWagon = "Chevalier Cerise Wagon", SUV = "Franklin All-Terrain",
        Van = "Franklin Valuline", PickUpVan = "Dash Bulldriver", OffRoad = "Dash Rancher", StepVan = "Chevalier Step Van" }
    local keepText = getTextOrNull
    getTextOrNull = function(k) return NAMES[(tostring(k):gsub("^IGUI_VehicleName", ""))] end
    local CASES = {
        { "Base.CarLuxury", "luxury", "mercia" }, { "Base.CarNormal", "nyala", "chevalier" }, { "Base.SportsCar", "cossette", "chevalier" },
        { "Base.PickUpTruck", "d6", "chevalier" }, { "Base.ModernCar", "dashelite", "dash" }, { "Base.ModernCar02", "primani", "chevalier" },
        { "Base.SmallCar", "dart", "chevalier" }, { "Base.SmallCar02", "horizon", "masterson" }, { "Base.CarStationWagon", "wagon", "chevalier" },
        { "Base.SUV", "suv", "franklin" }, { "Base.Van", "van", "franklin" }, { "Base.PickUpVan", "bulldriver", "dash" },
        { "Base.OffRoad", "rancher", "dash" }, { "Base.StepVan", "van", "chevalier" },
    }
    for _, c in ipairs(CASES) do
        local car = newCar({ script = c[1], keysIn = true })
        seat(car); newDash(); frame(30)
        local des = ZeD.DashPx.designs[c[2]]
        local sprite = false
        for _, p in ipairs(des.parts) do
            if p.t == "sprite" and p.src == "brand" and p.when == st().brand and des.sprites[p.sprite] then sprite = true end
        end
        check("BRANDS " .. c[1] .. ": the " .. c[2] .. " dash", inst._designId == c[2], inst._designId)
        check("BRANDS " .. c[1] .. ": the " .. c[3] .. " mark", st().brand == c[3], st().brand)
        check("BRANDS " .. c[1] .. ": the mark has its sprite", sprite)
        if c[1] == "Base.StepVan" then
            check("BRANDS the Step Van's model line: STEP VAN", inst._badge and inst._badge.model == "STEP VAN", inst._badge and inst._badge.model)
        end
        out()
    end
    -- a modded car's name on a game car: the plaque
    getTextOrNull = function() return "Ford Bronco" end
    local b = D._badges(ZeD.DashPx.designs.nyala, newCar({ script = "Base.FordBronco" }), "Base.FordBronco", false)
    check("BRANDS a modded car (Ford Bronco) gets the plaque", b.brand == "plaque" and b.make == "FORD" and b.model == "BRONCO", b.brand)
    getTextOrNull = keepText
end

section("NIGHT")
do
    local car = drive("dashelite", { keysIn = true, lux = 0.9 })
    local nd = ZeD.DashPx.designs.dashelite.night
    local function settle(lux) car.lux = lux; frames(60, 100); return inst._light end
    local L = settle(0.9)
    check("NIGHT day: nightness 0", L.n8 == 0, L.n8)
    L = settle(0.42)
    check("NIGHT dusk: nightness 4 eighths", L.n8 == 4, L.n8)
    L = settle(0.1)
    check("NIGHT night: nightness 8 eighths", L.n8 == 8, L.n8)
    check("NIGHT the lights off: the dark plate laid over", nd and L.over == nd.dark and L.lit == false)
    car.lights = true
    frames(2, 100)
    check("NIGHT the lights on: the night plate with its bulbs", nd and inst._light.over == nd.plate and inst._light.lit == true)
    -- lit, the plate's parts read brighter than in the dark (the bulbs' light map)
    local function sum(light)
        PL.drawParts(canvas(), ZeD.DashPx.designs.dashelite.parts, st(), { light = light, sprites = ZeD.DashPx.designs.dashelite.sprites, tex = function() return nil end })
        local s = 0
        for _, r in ipairs(RECTS) do s = s + (r.r or 0) + (r.g or 0) + (r.b or 0) end
        return s
    end
    local Llit = {}; for k, v in pairs(inst._light) do Llit[k] = v end
    local Ldark = {}; for k, v in pairs(inst._light) do Ldark[k] = v end
    Ldark.lit, Ldark.over = false, nd.dark
    check("NIGHT the dash lights brighten the plate at night", sum(Llit) > sum(Ldark), sum(Llit) .. " vs " .. sum(Ldark))
    D.qaNight = 0.5
    frames(2, 100)
    check("NIGHT D.qaNight stands in for the reading", inst._light.n8 == 4, inst._light.n8)
    D.qaNight = nil
    out()
end

section("PARTS")
do
    defaults["UI_ZeD_Dash_UnitCab"] = "%1 - CAB %2"
    SandboxVars.ZeD = nil
    local car = drive("taxi", { keysIn = true, running = true, kmh = 0 })
    inst:_fire("meter", false)
    frame(30)
    check("PARTS the flag down by a click starts the meter at the flag drop (1.50)", st().meterOn == true and near(st().fare, 1.50), st().fare)
    frames(601, 100)
    check("PARTS a minute's wait adds its rate (1.75)", near(st().fare, 1.75), st().fare)
    SandboxVars.ZeD = { TaxiFlagDrop = 2.00 }
    frame(30)
    check("PARTS the fare settings read live (flag drop 2.00)", near(st().fare, 2.25), st().fare)
    SandboxVars.ZeD = nil
    inst:_fire("meter", false); frame(30); inst:_fire("meter", false)
    car.kmh = 100
    frames(120, 100)                            -- 12 s at 62.14 mph: 0.207 miles, one fifth
    check("PARTS a fifth of a mile adds its rate (1.75)", near(st().fare, 1.75), st().fare)
    for _, c in ipairs({ { 2, 0.50 }, { 3, 1.00 }, { 1, 0 } }) do
        D.qaRiders = c[1]
        frame(30)
        check(("PARTS %d riders: extras %.2f"):format(c[1], c[2]), near(st().fareExtra, c[2]), st().fareExtra)
    end
    D.qaRiders = nil
    -- the hula girl: at rest standing still, both ways in turns
    car.kmh = 0
    frames(5, 200)
    check("PARTS the hula girl at rest standing still", st().hula == 0, st().hula)
    car.kmh = 40
    D.qaHula = 1
    frames(5, 200)
    local left = st().hula
    D.qaHula = -1
    frames(5, 200)
    local right = st().hula
    D.qaHula = nil
    check("PARTS she sways both ways in turns", left == 1 and right == 2, tostring(left) .. "/" .. tostring(right))
    check("PARTS the licence's unit line: TAXI - CAB nn", inst._badge and tostring(inst._badge.unit):match("^TAXI %- CAB %d%d$") ~= nil, inst._badge and inst._badge.unit)
    car.kmh, car.running, car.keysIn = 0, false, false
    frame(30)
    check("PARTS the key out clears the meter", st().meterOn == false and st().fare == 0, st().fare)
    out()
    -- the van's right side: a logo van its sticker, another company's van NO SMOKING, a private van the ash tray
    local logoVan = next(ZeD.DashPx.vanLogos)
    local vr, logo = D._vanRight(logoVan)
    check("PARTS a logo van wears its decal", vr == nil and logo ~= nil, logoVan)
    check("PARTS a private van has the ash tray", D._vanRight("Van") == "ash" and D._vanRight("VanSeats") == "ash" and D._vanRight("StepVan") == "ash")
    check("PARTS another company's van: NO SMOKING", D._vanRight("VanKnoxDisti") == "nosmoke")
end

-- ---------------------------------------------------------------------------
section("CABIN")
-- ---------------------------------------------------------------------------
-- (Nov 12 2026, punch list 179) the cabin color through the real dash: the car's paint and key pick the color, the
-- dash draws that color's pictures, the car keeps it; the fleet black and plain; nothing ever sent
do
    SCRIPT.wagon, SCRIPT.police = "Base.CarStationWagon", "Base.CarLightsPolice"
    function Car:getKeyId() return self.key end
    function Car:getColorHue() return self.hue end
    function Car:getColorSaturation() return self.sat end
    function Car:getColorValue() return self.val end
    local Pr = ZeD.DashProto
    local function drew(log, pat)
        for _, l in ipairs(log) do if l:find(pat) then return true end end
        return false
    end
    local function plainOf(log, des)
        for _, n in ipairs(des.cabinTex or {}) do
            if drew(log, "/" .. n .. "%.png") then return n end
        end
        return nil
    end
    env.client = false
    local key, des = 4815162, ZeD.DashPx.designs.nyala
    local want = Pr.cabinFor("nyala", "BLUE", Pr.cabRoll(key))
    local car = drive("nyala", { key = key, hue = 0.58, sat = 0.9, val = 0.7, keysIn = true })
    local log = frame(100)
    check("CABIN a blue Nyala draws its rolled color's plate", drew(log, "dash_nyala__" .. want .. "%.png"), want)
    check("CABIN no picture by its plain name where the colors differ", plainOf(log, des) == nil, plainOf(log, des))
    check("CABIN the car keeps it (single player stamps its modData)", car.md[Pr.CAB_KEY] == "BLUE:" .. Pr.cabRoll(key), car.md[Pr.CAB_KEY])
    check("CABIN the model line's shadow is the color's own", inst._cabin and inst._cabin.id == want and inst._cabin.shadow ~= nil)
    car.hue = 0.0                                                          -- repainted red
    newDash()
    log = frame(100)
    check("CABIN a reload, repainted since: the same color", drew(log, "dash_nyala__" .. want .. "%.png"))
    D.qaCabin = "v_navy70"
    log = frame(100)
    check("CABIN D.qaCabin forces a color", drew(log, "dash_nyala__v_navy70%.png"))
    D.qaCabin = nil
    log = frame(100)
    check("CABIN and lets go of it", drew(log, "dash_nyala__" .. want .. "%.png"))
    check("CABIN the dash never sends the car's modData", car.transmits == 0, car.transmits)
    out()
    -- multiplayer: another machine's copy of the same car (the server's key and paint), no stamp yet: the same color,
    -- its own copy stamped, nothing sent
    env.client = true
    local s0 = #SENT
    local twin = drive("nyala", { key = key, hue = 0.58, sat = 0.9, val = 0.7, keysIn = true, id = 31 })
    log = frame(100)
    check("CABIN multiplayer: another machine draws the same color", drew(log, "dash_nyala__" .. want .. "%.png"))
    -- (the driver's first-mileage odometer send may go: it is the only command, and it carries no color)
    local other = nil
    for i = s0 + 1, #SENT do
        if SENT[i].command ~= ZeD.DashProto.ODO or SENT[i].args.cab ~= nil then other = SENT[i].command end
    end
    check("CABIN multiplayer: no transmit, no command for the color", twin.transmits == 0 and other == nil, other)
    out()
    env.client = false
    -- a wagon whose paint can't be read: the white/silver/gray/black row, unstamped
    local bare = drive("wagon", { key = 99, keysIn = true, id = 32 })
    log = frame(100)
    local fb = Pr.cabinFor("wagon", nil, Pr.cabRoll(99))
    check("CABIN unread paint: the neutral row's color", drew(log, "dash_wagon__" .. fb .. "%.png"), fb)
    check("CABIN unread paint: not stamped", bare.md[Pr.CAB_KEY] == nil)
    out()
    -- public service: black, plain names, whatever the paint
    local cop = drive("police", { key = 5, hue = 0.58, sat = 0.9, val = 0.7, keysIn = true, id = 33 })
    log = frame(100)
    check("CABIN the police dash draws its one black plate", drew(log, "/dash_police%.png") and not drew(log, "dash_police__"))
    check("CABIN the police dash has no colors to pick", inst._cabin == nil and ZeD.DashPx.designs.police.cabins == nil)
    out()
end

check("nothing logged", #env.errors == 0, env.errors[1])

print("dash_odo_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
