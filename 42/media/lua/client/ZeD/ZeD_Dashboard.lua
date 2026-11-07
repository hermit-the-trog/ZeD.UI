-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Dashboard.lua
-- ============================================================================
-- VEHICLE DASHBOARD v6 — pixel art, one plate per design, live parts from data.
--
-- Art (director, Oct 16 2026): ZeDUI/tools/dashpx/ paints every dash as a lit
-- height field (the binnacle sunk under the brow, its shadow over the dials) and
-- writes ZeD/DashPx.lua: per design the plate, its state sprites, and the live
-- parts the game draws over it — needles, ribbons, lamps, LEDs, gear letters,
-- seven-segment figures, bars, knob pointers, lever tabs, badges, the clock, the
-- fare meter, the climate readout, the radio slot — plus the click areas. The
-- shared plate template (ZeD_Plate.lua) draws the plate and its parts from that
-- data; this file reads the car and acts on the controls.
--
-- Density: one plate pixel per screen pixel at 1080p, a whole multiple k above
-- (ZeD_PixelParts: nearest filtering, rects on the art grid), like the belt.
--
-- Replaces ISVehicleDashboard (parked, never removed). Every action is a vanilla
-- verb (ISVehicleMenu / ISVehiclePartMenu / vehicle client commands / radio
-- device data), so behaviour and MP commands stay identical to vanilla.
--
-- Gamepad: the D-pad stays with the wheels in the driver's seat (director, Oct
-- 24 2026); the World wheel's Vehicle > Dashboard hands the pad to the dash
-- (D.takePad: a FocusManager window only while it holds the pad). D-pad
-- cone-nav across the controls, A fires, X = the secondary (remove key, tune
-- down, volume, store preset), B lets go.
-- Passengers see the dash read-only. HOOK_MAP.md #2 / #4.
--
-- The radio slot shows the radio that is actually fitted: its small pixel face,
-- the display drawn in pixel figures from the same state the radio up close
-- reads (ZeD_RadioOps), and a click on the display brings the radio up close.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/ZeD_Panel"
require "ZeD/SafeMode"
require "ZeD/DashPx"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_RadioOps"
require "ZeD/ZeD_Plate"
require "ZeD/ZeD_DashProto"
require "ZeD/ZeD_ServerLink"

ZeD = ZeD or {}
ZeD.Dashboard = ZeD.Dashboard or {}
local D = ZeD.Dashboard
local DP = ZeD.DashPx
local P = ZeD.Px
local RO = ZeD.RadioOps
local PL = ZeD.Plate

local BASE_W, BASE_H = DP.w, DP.h
local TEXDIR = "media/textures/ZeD/dashpx/"
D.scale = D.scale or 1.0   -- organism multiplier on top of the root scale

-- (a clock in ms over a step: which of m steps it is on, 0 .. m-1. Not `math.floor(t / ms) % m`: the game's Lua gets
-- % wrong once the left side passes 2^31, and a clock in ms divided by a few hundred is far past it; Oct 31 2026)
local function clockStep(t, ms, m)
    local n = math.floor(t / ms)
    return n - math.floor(n / m) * m
end

local function clamp01(v) if v == nil then return 0 end; if v < 0 then return 0 end; if v > 1 then return 1 end; return v end
local function tex(name) return P.tex(TEXDIR .. name .. ".png") end

-- ---------------------------------------------------------------------------
-- Vehicle -> design (ids match ZeD/DashPx.lua)
-- ---------------------------------------------------------------------------
local MODEL_DESIGN = {
    CarLuxury = "luxury", CarNormal = "nyala", CarLights = "nyala", SportsCar = "cossette", PickUpTruck = "d6",
    ModernCar = "dashelite", ModernCar02 = "primani", SmallCar = "dart", SmallCar02 = "horizon",
    CarStationWagon = "wagon", CarStationWagon2 = "wagon", SUV = "suv", Van = "van", StepVan = "van", VanSeats = "van",
    PickUpVan = "bulldriver", OffRoad = "rancher", CarTaxi = "taxi", VanAmbulance = "ambulance", RaceCar = "race",
}
local LIVERY_DESIGN = {
    { "ambulance", "ambulance" }, { "hosp", "ambulance" }, { "fire", "fire" }, { "police", "police" }, { "sheriff", "police" },
    { "trooper", "police" }, { "swat", "police" }, { "kst", "police" }, { "louisvillepd", "police" }, { "louisvillecounty", "police" },
    { "westpoint", "police" }, { "ranger", "ranger" }, { "taxi", "taxi" }, { "race", "race" },
}
local function _designFor(scriptName)
    local n = tostring(scriptName or ""):gsub("^Base%.", "")
    local low = n:lower()
    for _, pair in ipairs(LIVERY_DESIGN) do
        if low:find(pair[1], 1, true) then return DP.designs[pair[2]], pair[2], true end
    end
    local best, bestLen = nil, 0
    for model, id in pairs(MODEL_DESIGN) do
        if n:sub(1, #model) == model and #model > bestLen then best, bestLen = id, #model end
    end
    -- the third value: the game's own car family (a modded car falls back to the Nyala's dash)
    if best then return DP.designs[best], best, true end
    return DP.designs.nyala, "nyala", false
end
D._designFor = _designFor   -- exposed for QA probes

-- the car's name as the game writes it ("Chevalier Nyala"; the simple dash's heading), and in capitals for the badges
local function _carName(vehicle, scriptName)
    local key = nil
    pcall(function() local sc = vehicle:getScript(); key = sc:getCarModelName() or sc:getName() end)
    local name = nil
    if key then
        key = tostring(key)
        name = getTextOrNull("IGUI_VehicleName" .. key)
        if not name and key:find("Burnt") then name = getTextOrNull("IGUI_VehicleName" .. (key:gsub("Burnt", ""))) end
    end
    local s = name and tostring(name) or tostring(scriptName or ""):gsub("^Base%.", ""):gsub("(%l)(%u)", "%1 %2")
    return s
end
local function _brandName(vehicle, scriptName) return ZeD.upper(_carName(vehicle, scriptName)) end

-- The game names a car "<livery> <maker> <model>": "Fossoil Chevalier D6", "Knox Distillery Franklin Valuline",
-- "Wrecked Dash Rancher", "Muldraugh Police Chevalier Nyala". The maker is one of these five (each names its mark on the
-- console, DashPx des.brands).
local MAKERS = { CHEVALIER = "chevalier", DASH = "dash", FRANKLIN = "franklin", MASTERSON = "masterson", MERCIA = "mercia" }
-- the game's own families whose car is not the dash's own, by script: the maker and model when the car's name carries
-- no maker word (a language that writes the makers in its own script). The Chevalier Step Van wears the Valuline's dash.
local FAMILY_CAR = { { "StepVan", "CHEVALIER", "STEP VAN" } }
-- the service a fleet livery names leads its unit plate ("Meade Sheriff" -> SHERIFF, "State Trooper" -> TROOPER)
local SERVICES = { "POLICE", "SHERIFF", "TROOPER", "SWAT", "RANGER", "FIRE", "AMBULANCE", "TAXI" }

local function _join(words, i, j)
    local s = ""
    for n = i, j do s = (s == "") and words[n] or (s .. " " .. words[n]) end
    return s
end

-- The console's mark (director, Oct 29 2026): picked by the car's own maker, never by the dash. The maker's own when the
-- dash has it cut (des.brands); a maker we don't know (a modded car's) gets the plaque. nil: a dash with no marks (the
-- fleet keeps its unit stencils, the race car has no badge).
local function _brandOf(design, make)
    local list = design.brands
    if not list then return nil end
    local want = MAKERS[make]
    if want then
        for i = 1, #list do if list[i] == want then return want end end
    end
    return "plaque"
end

-- The badge roles a design's badge parts ask for: the maker and model as one line (full), the make, the
-- model, the design's sub line ("5.0", "D6", "4X4"), the performance tag after a mark's model line (the sub line
-- unless the model already says it: not the D6's), and a fleet car's unit line ("TAXI - CAB 26"); and brand, the
-- console's mark. The livery never reaches a maker's badge: a Fossoil D6 still says CHEVALIER. A name with no maker in
-- it is all livery when the car is one of the game's own ("Spiffo Van", "Creature Cruiser", "Taxi"), and the
-- badge shows the design's own car; a modded car's name ("Ford Bronco") is its own maker and model.
local function _badges(design, vehicle, scriptName, ownFamily)
    local name = _brandName(vehicle, scriptName)
    local words = {}
    for w in name:gmatch("%S+") do words[#words + 1] = w end
    local mi = nil
    for i = 1, #words - 1 do if MAKERS[words[i]] then mi = i; break end end
    local livery, make, model
    if mi then
        livery, make, model = _join(words, 1, mi - 1), words[mi], _join(words, mi + 1, #words)
    elseif ownFamily then
        livery, make, model = name, design.make or name, design.model or name
        local base = tostring(scriptName or ""):gsub("^Base%.", "")
        for _, fc in ipairs(FAMILY_CAR) do
            if base:sub(1, #fc[1]) == fc[1] then make, model = fc[2], fc[3]; break end
        end
    else
        local fi = 1                                     -- a model year leads many modded names ("1992 Ford ...")
        while fi < #words and words[fi]:match("^%d+$") do fi = fi + 1 end
        livery, make = "", words[fi] or name
        model = (fi < #words) and _join(words, fi + 1, #words) or make
    end
    local fleet = nil
    for _, s in ipairs(SERVICES) do if livery:find(s, 1, true) then fleet = s; break end end
    fleet = fleet or livery:match("^(%S+)") or make
    local id = 0; pcall(function() id = vehicle:getId() or 0 end)
    local wordKey = (fleet == "TAXI") and "UI_ZeD_Dash_UnitCab" or ((fleet == "FIRE") and "UI_ZeD_Dash_UnitEngine" or "UI_ZeD_Dash_UnitUnit")
    -- painted on the car: a plain hyphen (no middle dots, director Oct 16 2026)
    local unit = ZeD.tr(wordKey, fleet, string.format("%02d", 10 + (id % 90)))
    local sub = design.sub or ""
    local tag = (sub ~= "" and not model:find(sub, 1, true)) and sub or ""
    return { full = make .. " " .. model, make = make, model = model, sub = sub, tag = tag, unit = unit, livery = livery, name = name,
             brand = _brandOf(design, make), plainName = _carName(vehicle, scriptName) }
end
D._badges = _badges   -- exposed for QA probes (a modded car's name on a game car: the plaque)

-- ---------------------------------------------------------------------------
-- Vehicle state (per frame, every read guarded)
-- ---------------------------------------------------------------------------
local function _safe(fn, default) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return default end
-- the same for one method call with no arguments, without making a closure each time (these are read every frame;
-- Oct 22 2026, the drawing-cost work): o:m(), its value or the default when it fails or gives nil
local function _inv(o, m) return o[m](o) end
local function _get(o, m, default)
    if o == nil then return default end
    local ok, v = pcall(_inv, o, m)
    if ok and v ~= nil then return v end
    return default
end

local CRANKING = { Starting = true, RetryingStarting = true, StartingSuccess = true, StartingFailed = true }
-- a part's condition (0..100), or nil when the car has no such part or its item is not fitted
local function _partCond(vehicle, id)
    local ok, part = pcall(vehicle.getPartById, vehicle, id)
    if not (ok and part) then return nil end
    local it = _get(part, "getItemType", nil)
    if it ~= nil and not _get(it, "isEmpty", true) and _get(part, "getInventoryItem", nil) == nil then return nil end
    return _get(part, "getCondition", nil)
end
local function _state(vehicle, chr)
    local st = {}
    st.running  = _get(vehicle, "isEngineRunning", false)
    st.started  = _get(vehicle, "isEngineStarted", false)
    -- the starter turning: the engine's own state (BaseVehicle.engineStateTypes). tryStartEngine sets Starting for a
    -- moment, then the whole crank reads StartingSuccess until it runs (Running), or StartingFailed (RetryingStarting
    -- on another try) until it gives up (Idle); the vanilla dashboard's isStarting() where the state cannot be read
    local es = _get(vehicle, "getEngineState", nil)
    st.engState = es and tostring(es) or nil
    if st.engState then st.cranking = CRANKING[st.engState] == true and not st.running
    else st.cranking = _get(vehicle, "isStarting", false) and not st.running end
    st.keysIn   = _get(vehicle, "isKeysInIgnition", false)
    st.hotwired = _get(vehicle, "isHotwired", false)
    st.hasKey   = _safe(function() return chr:getInventory():haveThisKeyId(vehicle:getKeyId()) ~= nil end, false)
    st.speed    = math.abs(_get(vehicle, "getCurrentSpeedKmHour", 0))
    st.rpmRaw   = st.running and _get(vehicle, "getEngineSpeed", 0) or 0
    st.gear     = _safe(function() return tostring(vehicle:getTransmissionNumberLetter()) end, "D")
    local tank = _safe(function() return vehicle:getPartById("GasTank") end, nil)
    st.fuelRaw = 0
    if tank and _get(tank, "isContainer", false) then
        st.fuelRaw = _safe(function() return tank:getContainerContentAmount() / math.max(1, tank:getContainerCapacity()) end, 0)
    end
    st.battRaw  = _get(vehicle, "getBatteryCharge", 0)
    st.engineCond = _safe(function() return vehicle:getPartById("Engine"):getCondition() end, 100)
    st.engWarn  = st.engineCond < 40     -- (the temperature needle's hot side; the engine lamp reads the condition steps, D.derive)
    -- the parts the lamps and their hover text read (mockup zed_belt_ammo_dash_v1; approved Oct 26 2026): condition
    -- 0..100, nil where the part or its item is missing
    st.battCond = _partCond(vehicle, "Battery")
    st.heaterCond = _partCond(vehicle, "Heater")
    st.hlL = _partCond(vehicle, "HeadlightLeft")
    st.hlR = _partCond(vehicle, "HeadlightRight")
    st.lights   = _get(vehicle, "getHeadlightsOn", false)
    -- the dash lights burn on the headlight switch while the lamps can actually light (vanilla's own test, its
    -- dashboard's lights icon: switched on and getHeadlightCanEmmitLight)
    st.dashLit  = st.lights and _get(vehicle, "getHeadlightCanEmmitLight", false) or false
    st.allLocked = _get(vehicle, "areAllDoorsLocked", false)
    st.anyLocked = _get(vehicle, "isAnyDoorLocked", false)
    st.hasTrunk  = _safe(function() return vehicle:getPartById("TruckBed") ~= nil end, false)
    st.trunkLocked = _get(vehicle, "isTrunkLocked", false)
    local heater = _safe(function() return vehicle:getPartById("Heater") end, nil)
    st.hasHeater = heater ~= nil
    st.heaterOn  = heater and _safe(function() return heater:getModData().active == true end, false) or false
    st.heaterTemp = heater and _safe(function() return tonumber(heater:getModData().temperature) or 0 end, 0) or 0  -- -25..25 (vanilla knob)
    -- PZ keeps ONE heater number (-25..25): its sign is the side (A/C or heat), its magnitude the blower
    local mag = math.abs(st.heaterTemp)
    st.fan = (not st.heaterOn) and 0 or (mag >= 21 and 3 or (mag >= 12 and 2 or 1))
    st.ac = st.heaterOn and st.heaterTemp < 0
    -- the fitted radio, read the same way its close-up reads it (ZeD_RadioOps)
    local radio  = _safe(function() return vehicle:getPartById("Radio") end, nil)
    st.radioPart = radio
    st.radio     = radio and RO.read(radio) or nil
    st.radioOn   = st.radio ~= nil and st.radio.on
    st.radioSwitch = st.radio ~= nil and st.radio.switchOn
    st.cruise    = _get(vehicle, "isRegulator", false)
    st.cruiseSpeed = _get(vehicle, "getRegulatorSpeed", 0)
    st.hasLightbar  = _get(vehicle, "hasLightbar", false)
    st.lightbarMode = st.hasLightbar and _get(vehicle, "getLightbarLightsMode", 0) or 0
    st.sirenMode    = st.hasLightbar and _get(vehicle, "getLightbarSirenMode", 0) or 0
    local gt = getGameTime and getGameTime()
    st.hour   = gt and _get(gt, "getHour", 10) or 10
    st.minute = gt and _get(gt, "getMinutes", 8) or 8
    return st
end

-- How long each reading takes to settle (ms): needles have weight, the levers do not. A gauge
-- starts from rest when the dash first shows a car (the needles sweep up as the key turns).
local SETTLE = { speed_mph = 140, speed_kmh = 140, rpm = 160, fuel = 900, batt = 900, temp = 9000, oil = 600, volts = 700,
                 tempF = 80, fanF = 80, modeF = 80 }
local FROM_REST = { speed_mph = true, speed_kmh = true, rpm = true, fuel = true, batt = true, temp = true, oil = true, volts = true }

-- The condition steps (mockup zed_belt_ammo_dash_v1; approved Oct 26 2026): f 0..1 -> "good" / "worn" (under 60%) /
-- "poor" (under 30%) / "dead" (under 10%); nil stays nil (no such part)
D.LAMP_COLOR = { worn = "#ffb02e", poor = "#ff3a20", dead = "#c41a10" }
D.BLINK_MS = 500
local TONE_RANK = { good = 0, worn = 1, poor = 2, dead = 3 }
function D.tone(f)
    if f == nil then return nil end
    if f < 0.1 then return "dead" elseif f < 0.3 then return "poor" elseif f < 0.6 then return "worn" end
    return "good"
end
-- a battery's charge: amber under 40%, red under 20%, blinking under 10%
function D.chargeTone(c)
    if c == nil then return nil end
    if c < 0.1 then return "dead" elseif c < 0.2 then return "poor" elseif c < 0.4 then return "worn" end
    return "good"
end
function D.lampsOn()
    local S = ZeD.Settings
    return S and S.dashLampsOn and S.dashLampsOn() or false
end
function D.worse(a, b)
    if a == nil then return b end
    if b == nil then return a end
    return (TONE_RANK[a] >= TONE_RANK[b]) and a or b
end
-- the lamp for a tone: false (dark: fine, or the blink's dark half under 10%) or its colour
function D.lampColor(t)
    if t == nil or t == "good" then return false end
    if t == "dead" and clockStep(getTimestampMs(), D.BLINK_MS, 2) == 1 then return false end
    return D.LAMP_COLOR[t]
end

-- The values the parts read (ZeDUI/tools/dashpx/live.py derives the same for the previews).
function D.derive(st, mem, dtMs)
    -- (st.pub: what a mod on Vehicle Kit Library publishes, ModSupport/VSKDash.lua; nil, every value is ZeD's own. Its
    -- lamps, gear and odometer come after the design is known, D.applyPublished)
    local pub = st.pub
    local live = st.running or st.keysIn or st.hotwired or (pub and pub.stalled)
    local batt = st.battRaw or 0
    st.power = (live and batt > 0.02) and true or false
    local v = {}
    v.speed_kmh = st.power and st.speed * (pub and pub.speedK or 1) or 0
    v.speed_mph = v.speed_kmh * 0.6214
    v.rpm   = st.running and st.rpmRaw or 0
    v.fuel  = st.power and clamp01(st.fuelRaw) or 0
    v.batt  = st.power and clamp01(batt) or 0
    v.temp  = pub and pub.temp or (st.running and (st.engWarn and 0.82 or 0.5) or (st.power and 0.12 or 0))
    v.oil   = pub and pub.oil or (st.running and (0.45 + 0.35 * math.min(1, v.rpm / 6000)) or 0)
    v.volts = st.power and (st.running and 0.75 or (0.35 + 0.25 * batt)) or 0
    v.tempF = clamp01(((st.heaterTemp or 0) + 25) / 50)
    v.fanF  = (st.fan or 0) / 3
    v.modeF = (not st.heaterOn) and 0 or (st.ac and 0.33 or ((st.heaterTemp or 0) >= 25 and 1 or 0.66))
    for key, target in pairs(v) do
        local tau = SETTLE[key]
        local cur = mem[key]
        if cur == nil then cur = FROM_REST[key] and 0 or target end
        if tau and dtMs > 0 then cur = cur + (target - cur) * (dtMs / (tau + dtMs)) else cur = tau and cur or target end
        mem[key] = cur
        st[key] = cur
    end
    local check = st.power and not st.running         -- key on, engine off: the bulb check
    st.check      = check
    st.oilLamp    = check
    -- the battery and engine lamps (mockup zed_belt_ammo_dash_v1, "Warning only"; approved Oct 26 2026): dark while
    -- the part is fine, amber when worn (under 60%), red when poor (under 30%), red and blinking under 10%. The battery
    -- follows the weaker of its condition and its charge (amber under 40%, red under 20%, blinking under 10%). The
    -- bulb check (key on, engine off) still lights every lamp in its own colour. A lamp's state: true = its own
    -- colour, a colour = that colour (ZeD_Plate draws either), false = dark.
    st.battTone   = D.worse(D.tone(st.battCond and st.battCond / 100 or nil), D.chargeTone(st.power and batt or nil))
    st.engTone    = D.tone(st.engineCond and st.engineCond / 100 or nil)
    st.heaterTone = D.tone(st.heaterCond and st.heaterCond / 100 or nil)
    -- (ZeD setup's "Dashboard warning lamps", off for a new player since Oct 30 2026: off, the lamps as before: the battery under 20% charge,
    -- the engine under 40%, the heater's light plain)
    local lampsOn = D.lampsOn()
    st.lampsOn    = lampsOn
    if lampsOn then
        st.genLamp = check or (st.running and D.lampColor(st.battTone)) or false
        st.engLamp = check or (st.running and D.lampColor(st.engTone)) or false
    else
        st.genLamp = check or (st.power and batt < 0.2)
        st.engLamp = check or (st.running and st.engWarn) or false
    end
    -- (Nov 6 2026, punch list 92: the brake, belt and oil lamps have nothing to show yet, so they stay dark but for the
    -- bulb check. ROADWORTHY HOOK: when its states can be read (QA hasn't run it yet), the coolant, seat belt, oil and
    -- high beam lamps take them here, over ZeD's own; a mod on Vehicle Kit Library already reaches them through
    -- D.applyPublished)
    st.brakeLamp  = check
    st.beltLamp   = check
    st.fuelLamp   = st.power and v.fuel < 0.15
    -- the hot lamp bulb-checks with the rest (Nov 6 2026; the race car's WATER jewel is this lamp too). st.hot is the
    -- engine really running hot, without the bulb check: the Simple dash's Temperature bar reads that (_plainCells)
    st.hot        = st.power and v.temp > 0.8 or false
    st.tempLamp   = check or st.hot
    st.hiBeam     = st.power and st.lights or false
    st.lightsLamp = st.hiBeam
    st.turnL, st.turnR, st.fourWD = false, false, false
    st.cruiseLamp = st.power and st.cruise or false
    st.keyLed     = st.keysIn
    st.lightbar, st.siren = st.lightbarMode or 0, st.sirenMode or 0
    st.lbarLamp   = st.lightbar > 0
    st.sirenLamp  = st.siren > 0
    st.heatOn     = st.heaterOn and not st.ac
    -- the heater's own light (the DASH ELITE's over AUTO) is an on light: its green while the heater is fine, the
    -- condition's colour when it is worn, while the engine runs
    if lampsOn and st.heatOn and st.running and st.heaterTone and st.heaterTone ~= "good" then st.heatOn = D.lampColor(st.heaterTone) end
    st.shiftLamp  = st.running and v.rpm >= 6500
    -- an automatic's selector: P with the engine off, R backing up, otherwise D (PZ counts gears internally)
    local g = tostring(st.gear or "")
    st.gearSel = (not st.running) and "P" or ((g == "R") and "R" or "D")
    return st
end

-- ---------------------------------------------------------------------------
-- Night (director, Oct 21 2026): no gauge is backlit; small incandescent bulbs
-- in the cluster panel's corners and a lamp under the brow light what they can
-- (ZeDUI/tools/dashpx/night.py bakes it; ZeD_Plate.lua draws it). How dark the
-- dash is follows the game's own light at the car (IsoGridSquare:getLightLevel,
-- the light vanilla's foraging reads): at DAY_L and above it is the day plate,
-- exactly as before; at NIGHT_L and below, the night; dusk, a garage by day or
-- a tunnel fall in between. The car's square and its four neighbours are read
-- and the darkest kept, so the car's own headlamps (which light the road ahead)
-- do not count; the reading settles over LUX_TAU_MS, like an eye.
-- ---------------------------------------------------------------------------
local DAY_L, NIGHT_L = 0.62, 0.22
local LUX_SAMPLE_MS, LUX_TAU_MS = 250, 1200
local NB_DX, NB_DY = { 1, -1, 0, 0 }, { 0, 0, 1, -1 }
-- QA only (ZeDUI/tools/qa): D.qaNight = 0..1 and D.qaLit = true/false stand in for the reading and the switch
local function _luxAt(vehicle, chr)
    local sq = vehicle:getSquare() or chr:getCurrentSquare()
    if not sq then return nil end
    local pn = chr:getPlayerNum()
    local best = sq:getLightLevel(pn)
    local cell = getCell()
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    for i = 1, 4 do
        local nb = cell and cell:getGridSquare(x + NB_DX[i], y + NB_DY[i], z)
        if nb then
            local v = nb:getLightLevel(pn)
            if v < best then best = v end
        end
    end
    return best
end
D._luxAt = _luxAt   -- exposed for QA probes

-- the night light this frame (ZeD_Plate's ctx.light), one table kept per dash
local function _nightLight(self, vehicle, chr, st, des, dt)
    local L = self._light
    if not L then L = {}; self._light = L end
    local now = getTimestampMs()
    if (not self._luxMs) or now - self._luxMs >= LUX_SAMPLE_MS then
        self._luxMs = now
        local ok, v = pcall(_luxAt, vehicle, chr)
        if ok and type(v) == "number" then self._luxRaw = v end
    end
    local raw = self._luxRaw or 1
    if self._lux == nil then self._lux = raw
    elseif dt > 0 then self._lux = self._lux + (raw - self._lux) * (dt / (LUX_TAU_MS + dt)) end
    local n = (DAY_L - self._lux) / (DAY_L - NIGHT_L)
    if D.qaNight ~= nil then n = D.qaNight end
    if n < 0 then n = 0 elseif n > 1 then n = 1 end
    L.n8 = math.floor(n * 8 + 0.5)
    local lit = st.dashLit and true or false
    if D.qaLit ~= nil then lit = D.qaLit and true or false end
    L.lit = lit
    local nd = des.night
    local G = DP.night
    if nd then
        L.map, L.cols, L.rows, L.cell, L.glass = nd.map, nd.cols, nd.rows, nd.cell, nd.glass
        L.tmap, L.tints, L.needleOwn = nd.tmap, nd.tints, nd.needleOwn   -- a dash lit in two colours (else nil: one tint)
        L.over = lit and nd.plate or nd.dark
    else
        L.map, L.over, L.glass, L.n8 = nil, nil, nil, 0
        L.tmap, L.tints, L.needleOwn = nil, nil, nil
    end
    L.amb = G and G.amb or 1
    L.levels = G and G.levels or 15
    L.tint = G and G.tint or nil
    return L
end

-- ---------------------------------------------------------------------------
-- Actions (vanilla verbs). Errors are caught by _fire.
-- ---------------------------------------------------------------------------
local function _sendHeater(chr, v, on, temp)
    local heater = v:getPartById("Heater"); if not heater then return end
    temp = math.max(-25, math.min(25, temp or (tonumber(heater:getModData().temperature) or 0)))
    sendClientCommand(chr, "vehicle", "toggleHeater", { on = on, temp = temp })
end
local ACT = {}
ACT.ignition = function(chr, v, st, secondary)
    if secondary then if st.keysIn and not st.running then v:setKeysInIgnition(false) end; return end
    if st.running then ISVehicleMenu.onShutOff(chr); return end
    if st.keysIn or st.hotwired then ISVehicleMenu.onStartEngine(chr); return end
    if st.hasKey then v:setKeysInIgnition(true); return end
end
ACT.lights = function(chr, v) ISVehicleMenu.onToggleHeadlights(chr) end
-- the ash tray: open or shut (a car the dash has not touched shows its own default). Single player keeps it on the car's
-- modData, so it stays with the save. On a server it stays in this game's memory, per car (D._ash, by the car's
-- number): a key only the client writes into the car's modData goes each time the server sends the car out (the
-- odometer's coarse moments: a first mileage, a press, the engine off, the driver leaving; the client's copy is wiped
-- and replaced), and the client never sends the whole table back (punch list 94). The other seats see their own tray:
-- it is only a look.
D._ash = D._ash or {}
ACT.ash    = function(chr, v, st)
    if isClient and isClient() then D._ash[_get(v, "getId", 0)] = not st.ashIsOpen; return end
    v:getModData().ZeD_ash = not st.ashIsOpen
end
-- the odometers (Nov 6 2026, punch list 92): the stem by the trip wheels zeroes the trip; the electronic dashes' window
-- (cossette, luxury, dashelite) switches ODO / TRIP, and its second verb zeroes the trip, only while the trip shows
-- (so a stray X on the odometer does nothing). dash: the ZeD_Dashboard (_fire hands it over)
ACT.tripReset = function(chr, v, st, secondary, dash) if dash then dash:_tripZero(v) end end
ACT.odoButton = function(chr, v, st, secondary, dash)
    if not dash then return end
    if secondary then
        if st.odoTrip then dash:_tripZero(v) end
        return
    end
    dash:_odoShowTrip(v, not st.odoTrip)
end
-- the taxi's meter: the flag down starts it from the flag drop, up stops it (the dash keeps it, per car)
ACT.meter  = function(chr, v, st, secondary, dash) if st.power then dash:_meterFlag(v, not st.meterOn) end end
ACT.lock   = function(chr, v) ISVehiclePartMenu.onLockDoors(chr, v, not v:isAnyDoorLocked()) end
ACT.trunk  = function(chr, v) ISVehicleMenu.onToggleTrunkLocked(chr) end
ACT.cruise = function(chr, v)
    if v:isRegulator() then v:setRegulator(false); return end
    local sp = v:getCurrentSpeedForRegulator(); if sp and sp >= 5 then v:setRegulatorSpeed(sp); v:setRegulator(true) end
end
ACT.heat   = function(chr, v, st) if st.heaterOn and not st.ac then _sendHeater(chr, v, false, st.heaterTemp) else _sendHeater(chr, v, true, math.max(8, math.abs(st.heaterTemp))) end end
ACT.off    = function(chr, v, st) _sendHeater(chr, v, false, st.heaterTemp) end
ACT.def    = function(chr, v, st) _sendHeater(chr, v, true, 25) end
ACT.ac     = function(chr, v, st) if st.ac then _sendHeater(chr, v, false, st.heaterTemp) else _sendHeater(chr, v, true, -math.max(8, math.abs(st.heaterTemp))) end end
ACT.tempup = function(chr, v, st) _sendHeater(chr, v, st.heaterOn, st.heaterTemp + 8) end
ACT.tempdn = function(chr, v, st) _sendHeater(chr, v, st.heaterOn, st.heaterTemp - 8) end
ACT.temp   = function(chr, v, st, secondary) if secondary then ACT.tempdn(chr, v, st) else ACT.tempup(chr, v, st) end end
local FAN_MAG = { 8, 17, 25 }
local function _fanTemp(st, f) return ((st.heaterTemp or 0) < 0 and -1 or 1) * FAN_MAG[f] end
ACT.fanup  = function(chr, v, st) local f = math.min(3, st.fan + 1); if f == 0 then _sendHeater(chr, v, false, st.heaterTemp) else _sendHeater(chr, v, true, _fanTemp(st, f)) end end
ACT.fandn  = function(chr, v, st) local f = math.max(0, st.fan - 1); if f == 0 then _sendHeater(chr, v, false, st.heaterTemp) else _sendHeater(chr, v, true, _fanTemp(st, f)) end end
ACT.fan    = function(chr, v, st, secondary) if secondary then ACT.fandn(chr, v, st) else ACT.fanup(chr, v, st) end end
ACT.mode   = function() end
ACT.lbar   = function(chr, v) sendClientCommand(chr, "vehicle", "setLightbarLightsMode", { mode = (v:getLightbarLightsMode() + 1) % 4 }) end
ACT.siren  = function(chr, v) pcall(function() getSoundManager():playUISound("VehicleSetSiren") end); sendClientCommand(chr, "vehicle", "setLightbarSirenMode", { mode = (v:getLightbarSirenMode() + 1) % 4 }) end
-- radio: the same calls as the radio up close (vanilla's radio action code, vanilla's presets)
local function _rp(st) return st.radio and st.radioPart end
-- the makeshift sets switch on with their rocker (pwr); their volume control is a plain knob
local ROCKER = { makeshift = true, hammake = true }
ACT.vol  = function(chr, v, st, secondary)
    local p = _rp(st); if not p then return end
    if secondary or ROCKER[st.radio.kind] then RO.volStep(chr, p, 1, true)    -- X (or a rocker set's knob) turns it up (past full it starts over)
    else RO.power(chr, p) end                                                  -- VOL pushes for power
end
ACT.pwr  = function(chr, v, st) local p = _rp(st); if p then RO.power(chr, p) end end
ACT.tune = function(chr, v, st, secondary) local p = _rp(st); if p then RO.tuneStep(chr, p, secondary and -1 or 1) end end
ACT.seek = function(chr, v, st, secondary) local p = _rp(st); if p and st.radio.on then RO.seek(chr, p, secondary and -1 or 1) end end
ACT.chup = function(chr, v, st) local p = _rp(st); if p and st.radio.on then RO.chStep(chr, p, 1) end end
ACT.chdn = function(chr, v, st) local p = _rp(st); if p and st.radio.on then RO.chStep(chr, p, -1) end end
ACT.mic  = function(chr, v, st) local p = _rp(st); if p then RO.mic(chr, p) end end
ACT.scan = function(chr, v, st) local p = _rp(st); if p and st.radio.on then RO.scanToggle(chr, p) end end
ACT.mute = function(chr, v, st) local p = _rp(st); if p then RO.mute(chr, p) end end
ACT.mem  = function(chr, v, st) local p = _rp(st); if p and st.radio.on then RO.memAdd(chr, p) end end
ACT.eject = function(chr, v, st) local p = _rp(st); if p then RO.eject(chr, p) end end
ACT.play = function(chr, v, st) local p = _rp(st); if p then RO.playStop(chr, p) end end
-- the CD slot: a disc in it comes out; an empty one brings the radio up close, where the discs you carry are listed
ACT.slot = function(chr, v, st)
    local p = _rp(st); if not p then return end
    if st.radio.hasMedia then RO.eject(chr, p) elseif ZeD.CarRadio then ZeD.CarRadio.toggle(chr, p) end
end
ACT.radio = function(chr, v, st) local p = _rp(st); if p and ZeD.CarRadio then ZeD.CarRadio.toggle(chr, p) end end
for i = 1, 6 do
    ACT["preset" .. i] = function(chr, v, st, secondary)
        local p = _rp(st); if not (p and st.radio.on) then return end
        if secondary or not st.radio.presets[i] then RO.store(chr, p, i) else RO.recall(chr, p, i) end
    end
end

-- Prompt labels for the gamepad strip
-- (the words are keys in Translate/<LANG>/UI.json, UI_ZeD_Dash_Prompt<Name>; Shut off, Microphone, Lightbar and Volume are vanilla's)
local function _promptKey(id, st)
    if id == "ignition" then if st.running then return "ContextMenu_VehicleShutOff" elseif st.keysIn or st.hotwired then return "UI_ZeD_Dash_PromptStart" elseif st.hasKey then return "UI_ZeD_Dash_PromptInsertKey" else return "UI_ZeD_Dash_PromptNoKey" end end
    if id == "lights" then return st.lights and "UI_ZeD_Dash_PromptLightsOff" or "UI_ZeD_Dash_PromptLightsOn" end
    if id == "lock" then return st.anyLocked and "UI_ZeD_Dash_PromptUnlock" or "UI_ZeD_Dash_PromptLock" end
    if id == "trunk" then return st.trunkLocked and "IGUI_UnlockTrunk" or "IGUI_LockTrunk" end
    if id == "cruise" then return st.cruise and "UI_ZeD_Dash_PromptCruiseOff" or "UI_ZeD_Dash_PromptCruiseSet" end
    if id == "ash" then return st.ashIsOpen and "UI_ZeD_Dash_AshClose" or "UI_ZeD_Dash_AshOpen" end
    if id == "meter" then return st.meterOn and "UI_ZeD_Dash_MeterOff" or "UI_ZeD_Dash_MeterOn" end
    if id == "tripReset" then return "UI_ZeD_Dash_PromptTripReset" end
    -- (the window shows the other one on A: the word names what A brings up)
    if id == "odoButton" then return st.odoTrip and "UI_ZeD_DashPlain_Odometer" or "UI_ZeD_DashPlain_Trip" end
    if id == "heat" then return st.heaterOn and "UI_ZeD_Dash_PromptHeaterOff" or "UI_ZeD_Dash_PromptHeaterOn" end
    if id == "ac" then return st.ac and "UI_ZeD_Dash_PromptAcOff" or "UI_ZeD_Dash_PromptAc" end
    if id == "vol" and st.radio and ROCKER[st.radio.kind] then return "UI_ZeD_Dash_PromptVolumePlus" end
    if id == "pwr" or id == "vol" then return st.radioSwitch and "UI_ZeD_Dash_PromptRadioOff" or "UI_ZeD_Dash_PromptRadioOn" end
    if id == "mute" then return (st.radio and st.radio.muted) and "UI_ZeD_Dash_PromptSoundOn" or "UI_ZeD_Dash_PromptMute" end
    if id == "mem" then return "UI_ZeD_Dash_PromptStoreChannel" end
    if id == "eject" then return "UI_ZeD_Dash_PromptEject" end
    if id == "play" then return "UI_ZeD_Dash_PromptPlayStop" end
    if id == "slot" then return (st.radio and st.radio.hasMedia) and "UI_ZeD_Dash_PromptEject" or "UI_ZeD_Dash_PromptChooseDisc" end
    if id == "tune" then return "UI_ZeD_Dash_PromptTunePlus" end
    if id == "seek" then return "UI_ZeD_Dash_PromptSeek" end
    if id == "scan" then return "UI_ZeD_Dash_PromptScan" end
    if id:sub(1, 6) == "preset" then return "UI_ZeD_Dash_PromptPreset" end
    if id == "chup" then return "UI_ZeD_Dash_PromptChannelPlus" end
    if id == "chdn" then return "UI_ZeD_Dash_PromptChannelMinus" end
    if id == "mic" then return "IGUI_RadioMicrophone" end
    if id == "radio" then return "UI_ZeD_Dash_PromptRadioUp" end
    if id == "temp" or id == "tempup" then return "UI_ZeD_Dash_PromptWarmer" end
    if id == "tempdn" then return "UI_ZeD_Dash_PromptCooler" end
    if id == "fan" or id == "fanup" then return "UI_ZeD_Dash_PromptFanPlus" end
    if id == "fandn" then return "UI_ZeD_Dash_PromptFanMinus" end
    if id == "lbar" then return "ContextMenu_VehicleLightbar" end
    if id == "siren" then return "UI_ZeD_Dash_PromptSiren" end
    if id == "def" then return "UI_ZeD_Dash_PromptDefrost" end
    if id == "off" then return "UI_ZeD_Dash_PromptClimateOff" end
    return "UI_ZeD_Dash_PromptPress"
end
-- the second verb (X / right-click) per control, as keys
local SECONDARY = { ignition = "UI_ZeD_Dash_PromptRemoveKey", vol = "IGUI_RadioVolume", tune = "UI_ZeD_Dash_PromptTuneMinus",
    temp = "UI_ZeD_Dash_PromptCooler", fan = "UI_ZeD_Dash_PromptFanMinus", seek = "UI_ZeD_Dash_PromptSeekBack",
    preset1 = "UI_ZeD_Dash_PromptStore", preset2 = "UI_ZeD_Dash_PromptStore", preset3 = "UI_ZeD_Dash_PromptStore",
    preset4 = "UI_ZeD_Dash_PromptStore", preset5 = "UI_ZeD_Dash_PromptStore", preset6 = "UI_ZeD_Dash_PromptStore",
    odoButton = "UI_ZeD_Dash_PromptTripReset" }
ZeD.trDefaults({
    UI_ZeD_Dash_PromptTripReset = "Reset trip",
    UI_ZeD_Dash_PromptStart = "Start", UI_ZeD_Dash_PromptInsertKey = "Insert key", UI_ZeD_Dash_PromptNoKey = "No key",
    UI_ZeD_Dash_PromptLightsOff = "Lights off", UI_ZeD_Dash_PromptLightsOn = "Lights on", UI_ZeD_Dash_PromptUnlock = "Unlock",
    UI_ZeD_Dash_PromptLock = "Lock",
    UI_ZeD_Dash_PromptCruiseOff = "Cruise off", UI_ZeD_Dash_PromptCruiseSet = "Cruise set", UI_ZeD_Dash_PromptHeaterOff = "Heater off",
    UI_ZeD_Dash_PromptHeaterOn = "Heater on", UI_ZeD_Dash_PromptAcOff = "A/C off", UI_ZeD_Dash_PromptAc = "A/C",
    UI_ZeD_Dash_PromptVolumePlus = "Volume +", UI_ZeD_Dash_PromptRadioOff = "Radio off", UI_ZeD_Dash_PromptRadioOn = "Radio on",
    UI_ZeD_Dash_PromptSoundOn = "Sound on", UI_ZeD_Dash_PromptMute = "Mute", UI_ZeD_Dash_PromptStoreChannel = "Store channel",
    UI_ZeD_Dash_PromptEject = "Eject", UI_ZeD_Dash_PromptPlayStop = "Play / stop", UI_ZeD_Dash_PromptChooseDisc = "Choose a disc",
    UI_ZeD_Dash_PromptTunePlus = "Tune +", UI_ZeD_Dash_PromptSeek = "Seek", UI_ZeD_Dash_PromptScan = "Scan",
    UI_ZeD_Dash_PromptPreset = "Preset", UI_ZeD_Dash_PromptChannelPlus = "Channel +", UI_ZeD_Dash_PromptChannelMinus = "Channel -",
    UI_ZeD_Dash_PromptRadioUp = "Radio up close", UI_ZeD_Dash_PromptWarmer = "Warmer", UI_ZeD_Dash_PromptCooler = "Cooler",
    UI_ZeD_Dash_PromptFanPlus = "Fan +", UI_ZeD_Dash_PromptFanMinus = "Fan -", UI_ZeD_Dash_PromptSiren = "Siren",
    UI_ZeD_Dash_PromptDefrost = "Defrost", UI_ZeD_Dash_PromptClimateOff = "Climate off", UI_ZeD_Dash_PromptPress = "Press",
    UI_ZeD_Dash_PromptRemoveKey = "Remove key", UI_ZeD_Dash_PromptTuneMinus = "Tune -", UI_ZeD_Dash_PromptSeekBack = "Seek back",
    UI_ZeD_Dash_PromptStore = "Store", UI_ZeD_Dash_PromptDrive = "Drive", UI_ZeD_Dash_Passenger = "PASSENGER",
    UI_ZeD_Dash_HintAxb = "A %1  X %2  B %3", UI_ZeD_Dash_HintAb = "A %1  B %2", UI_ZeD_Dash_HintWheel = "D-pad Right: Vehicle / Dashboard",
    UI_ZeD_Dash_UnitCab = "%1 - CAB %2", UI_ZeD_Dash_UnitEngine = "%1 - ENGINE %2", UI_ZeD_Dash_UnitUnit = "%1 - UNIT %2",
    UI_ZeD_Dash_AshOpen = "Open ash tray", UI_ZeD_Dash_AshClose = "Close ash tray",
    UI_ZeD_Dash_MeterOn = "Meter on", UI_ZeD_Dash_MeterOff = "Meter off",
})

-- ---------------------------------------------------------------------------
-- The lamps' hover text (mockup zed_belt_ammo_dash_v1; approved Oct 26 2026): pointing at the battery, engine or
-- headlight lamp, or the heater's light (its button where the plate has no light of its own), shows the library's detail
-- card after the shared delay: the part's name, then its condition, the battery's charge, the heater's on / off, each
-- headlight. The lamps stay off the controller's path (the Vehicle tab lists every part's condition for the pad).
-- ---------------------------------------------------------------------------
local LAMP_ZONE = { genLamp = "batt", engLamp = "eng", hiBeam = "head", heatOn = "heat" }
local ZONE_MIN_W, ZONE_MIN_H = 13, 11   -- a small lamp's hover place at least this big round its middle (plate pixels)
-- the design's hover places in plate pixels (worked out once, kept on the design)
local function _lampZones(des)
    if des._lampZones then return des._lampZones end
    local z = {}
    local heatHit = nil
    for _, h in ipairs(des.hits or {}) do if h.id == "heat" then heatHit = h end end
    if not heatHit then for _, h in ipairs(des.hits or {}) do if h.id == "temp" then heatHit = heatHit or h end end end
    for _, p in ipairs(des.parts or {}) do
        local id = LAMP_ZONE[p.src]
        if id and (p.t == "lamp" or p.t == "led") and not (id == "heat" and des.hits and heatHit and heatHit.id == "heat") then
            local x0, y0, x1, y1
            if p.t == "led" then x0, y0, x1, y1 = p.x, p.y, p.x + p.w, p.y + p.h
            else
                x0, y0, x1, y1 = 9999, 9999, -9999, -9999
                for _, list in ipairs({ p.r or {}, p.halo or {} }) do
                    for i = 1, #list, 4 do
                        x0, y0 = math.min(x0, list[i]), math.min(y0, list[i + 1])
                        x1, y1 = math.max(x1, list[i] + list[i + 2]), math.max(y1, list[i + 1] + list[i + 3])
                    end
                end
            end
            if x1 > x0 then
                local w, h = math.max(ZONE_MIN_W, x1 - x0), math.max(ZONE_MIN_H, y1 - y0)
                z[#z + 1] = { id = id, x = math.floor((x0 + x1 - w) / 2), y = math.floor((y0 + y1 - h) / 2), w = w, h = h }
            end
        end
    end
    -- the heater: its button (the DASH ELITE's AUTO, with its light over it), or the temperature control
    local hasHeat = false
    for _, q in ipairs(z) do if q.id == "heat" then hasHeat = true end end
    if heatHit and not hasHeat then z[#z + 1] = { id = "heat", x = heatHit.x, y = heatHit.y, w = heatHit.w, h = heatHit.h } end
    des._lampZones = z
    return z
end
D._lampZones = _lampZones   -- (QA probes)

local function _pct(v) return tostring(math.floor((v or 0) + 0.5)) .. "%" end
local function _condLine(v) return v and ZeD.tr("UI_ZeD_Dash_LampCondLine", _pct(v)) or getText("IGUI_Missing") end
-- the hover card's two parts: the part's name (the game's word) and a line for what is known of it
function D.lampText(id, st)
    if id == "batt" then
        local lines = { _condLine(st.battCond) }
        if st.battCond then lines[2] = ZeD.tr("UI_ZeD_Dash_LampChargeLine", _pct((st.battRaw or 0) * 100)) end
        return getText("Tooltip_Dashboard_Battery"), lines
    elseif id == "eng" then
        return getText("IGUI_VehiclePartEngine"), { _condLine(st.engineCond) }
    elseif id == "heat" then
        return getText("Tooltip_Dashboard_Heater"), { _condLine(st.heaterCond), getText(st.heaterOn and "UI_On" or "UI_Off") }
    elseif id == "head" then
        local l = st.hlL and _pct(st.hlL) or getText("IGUI_Missing")
        local r = st.hlR and _pct(st.hlR) or getText("IGUI_Missing")
        return getText("Tooltip_Dashboard_Headlights"), { ZeD.tr("UI_ZeD_Dash_LampLeftLine", l), ZeD.tr("UI_ZeD_Dash_LampRightLine", r) }
    end
    return nil
end
ZeD.trDefaults({
    UI_ZeD_Dash_LampCondLine = "Condition %1", UI_ZeD_Dash_LampChargeLine = "Charge %1",
    UI_ZeD_Dash_LampLeftLine = "Left %1", UI_ZeD_Dash_LampRightLine = "Right %1",
})

-- ---------------------------------------------------------------------------
-- The organism
-- ---------------------------------------------------------------------------
ZeD_Dashboard = ZeD_Panel:derive("ZeD_Dashboard")

function ZeD_Dashboard:new(playerNum)
    local o = ZeD_Panel:new(0, 0, BASE_W, BASE_H)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum or 0
    o._zedLabel = "Dashboard"
    o.vehicle   = nil
    o._hit      = {}
    o._elements = {}
    o._focusRing = { { zone = "dashControls", focusable = false, elements = {}, focusedElementIdx = 1 } }
    o._markOpts = { win = o }   -- the dash is a focus window of its own (ZeD.Focus.mark)
    o._focusIdx  = 1
    o._s = 1
    o._mem = {}          -- the settling readings (needles have weight)
    o._trips = {}        -- per vehicle: distance this session (the trip meter, the taxi's fare)
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor     = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

function ZeD_Dashboard:_scale() local Sc = ZeD.Scale; return ((Sc and Sc.root and Sc.root()) or 1) * (D.scale or 1) end

-- the largest whole multiple of the plate the scale allows, centred at the bottom of the player's screen
function ZeD_Dashboard:_layout()
    local k = P.k(self:_scale())
    local w, h = BASE_W * k, BASE_H * k
    local pn = self.playerNum
    local x = getPlayerScreenLeft(pn) + math.floor((getPlayerScreenWidth(pn) - w) / 2)
    local y = getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) - h      -- flush on the screen's edge (Oct 29 2026)
    if self:getWidth() ~= w then self:setWidth(w) end
    if self:getHeight() ~= h then self:setHeight(h) end
    if self:getX() ~= x then self:setX(x) end
    if self:getY() ~= y then self:setY(y) end
    return w, h, k
end

-- the controller's mark on a control (plate pixels): the chosen focus look (ZeD.Focus.mark) over the key; the hand,
-- corners or ants come with the overlay pass at the end of the dash's render. A knob (the head unit's volume and
-- tuning) keeps its ring, which is the knob's own light.
local KNOB = { vol = true, tune = true }
function ZeD_Dashboard:_focusCue(id, x, y, w, h)
    if KNOB[id] then
        PL.cue(self._cv, { x = x, y = y, w = w, h = h, kind = "turn" }, ZeD.T.accent, 0.55)
    else
        PL.markKey(self, { x = x, y = y, w = w, h = h }, 0, 0, self._s, self._markOpts)
    end
end

-- the pointer on a control: the hover wash on a key, the ring (lighter) round a knob
function ZeD_Dashboard:_hoverCue(id, x, y, w, h)
    if KNOB[id] then
        PL.cue(self._cv, { x = x, y = y, w = w, h = h, kind = "turn" }, ZeD.T.accent, 0.30)
    else
        PL.hoverKey(self._cv, { x = x, y = y, w = w, h = h })
    end
end

-- register a control: hit rect for the mouse, focus element for the pad (driver only)
function ZeD_Dashboard:_control(id, x, y, w, h, st, enabled)
    if not self._driver then return end
    local s = self._s
    local hr = { id = id, x = math.floor(x * s), y = math.floor(y * s), w = math.floor(w * s), h = math.floor(h * s), enabled = enabled ~= false }
    self._hit[#self._hit + 1] = hr
    if hr.enabled then
        local focused = self._focEl and self._focEl.id == "dash:" .. id
        if focused then self:_focusCue(id, x, y, w, h)
        elseif self._over and ZeD.Atoms.mouseIn(self, hr.x, hr.y, hr.w, hr.h) then self:_hoverCue(id, x, y, w, h) end
        self:_element(id, hr, st)
    end
end

-- the control's focus element for the pad (hr: its rect in panel pixels); the plate and the simple strip both
-- come here, so A, X and B do the same on either
function ZeD_Dashboard:_element(id, hr, st)
    -- X offers the secondary verb only when it can happen: "Remove key" needs a key in the lock
    local secondary = SECONDARY[id]
    if id == "ignition" and not st.keysIn then secondary = nil end
    if id == "odoButton" and not st.odoTrip then secondary = nil end     -- (zeroing waits for the trip to show)
    self._elements[#self._elements + 1] = {
        x = hr.x, y = hr.y, w = hr.w, h = hr.h, id = "dash:" .. id,
        promptA = self._pad and ZeD.tr(_promptKey(id, st)) or nil,
        promptX = (self._pad and secondary) and ZeD.tr(secondary) or nil,
        promptB = self._pad and ZeD.tr("UI_ZeD_Dash_PromptDrive") or nil,
        onActivate = function(win, el) win:_fire(id, false) end,
        onContextMenu = function(win, el) if secondary then win:_fire(id, true) end end,
        onCancel = function(win, el) win:_release(); win:_unregister() end,
    }
end

-- a control of the simple strip, already drawn: its click area (screen pixels in the panel) and its focus element
function ZeD_Dashboard:_plainControl(id, x, y, w, h, st, enabled)
    if not self._driver then return end
    local hr = { id = id, x = x, y = y, w = w, h = h, enabled = enabled ~= false }
    self._hit[#self._hit + 1] = hr
    if hr.enabled then self:_element(id, hr, st) end
end

-- ---------------------------------------------------------------------------
-- the trip meter and the taxi's fare meter (session distance, per vehicle)
--
-- The meter (director, Oct 24 2026: "working meter"; the fares are ZeD's
-- sandbox options, so a server's rates reach every player): the flag pulled
-- down starts it at the flag drop; each fifth of a mile driven and each minute
-- waiting (under 5 km/h, the engine running) adds its rate. The extras are the
-- riders past the first (the seats taken but the driver's). The key coming out
-- puts the flag up and clears it.
-- ---------------------------------------------------------------------------
local FARE = { TaxiFlagDrop = 1.50, TaxiPerFifthMile = 0.25, TaxiPerMinuteWaiting = 0.25, TaxiPerExtraPassenger = 0.50 }
local function _fare(name)
    local S = SandboxVars and SandboxVars.ZeD
    local v = S and tonumber(S[name])
    return v or FARE[name]
end
D._fare = _fare   -- exposed for QA probes
local WAIT_KMH = 5

-- the seats taken but the driver's (QA: D.qaRiders stands in)
local function _riders(vehicle)
    if D.qaRiders then return D.qaRiders end
    local n = 0
    local seats = _get(vehicle, "getMaxPassengers", 0)
    for i = 1, seats - 1 do
        local ok, c = pcall(vehicle.getCharacter, vehicle, i)
        if ok and c then n = n + 1 end
    end
    return n
end

function ZeD_Dashboard:_tripOf(vehicle)
    local id = _get(vehicle, "getId", 0)
    local t = self._trips[id]
    if not t then t = { fareMiles = 0, waitMs = 0, meterOn = false }; self._trips[id] = t end
    return t, id
end

-- ---------------------------------------------------------------------------
-- the odometer and the trip odometer (Nov 6 2026, punch list 92; ZeDUI/HANDOFF_design_dash_roadworthy_20261106.md):
-- miles with decimals, kept on the car's modData (ZeD_odo, ZeD_trip; ZeD_odoTrip: the electronic dashes are showing
-- the trip), so they survive sessions and every player in the car reads the same figures. The game keeps no mileage,
-- so a car ZeD has not seen before gets one, once, from its id and its engine's condition (a wreck has gone further):
-- the same figure for a given car on every machine. Only the driver counts, only while the engine runs; on a server
-- the driver's client asks the server to write the three keys (ZeD_DashProto.lua, ZeD_ServerDash.lua) at most every
-- tenth of a mile, at once after a press, and as a drive stops or ends; the server writes only those, sends the three
-- figures to the other seats (a passenger's dash also asks for them as it sits down: ZeD_Dashboard:_odoAsk), and sends
-- the car's whole modData out only at the coarse moments (a first mileage, a press, the engine off, the driver
-- leaving). Never the client's transmitModData: it replaces the server's whole copy of the car's modData, and a
-- key another mod keeps only there (Roadworthy's) would be lost (punch list 94). The taxi's fare keeps its own counter
-- (_trips[id].fareMiles).
-- ROADWORTHY HOOK: a mod that keeps its own odometer and trip (on Vehicle Kit Library: VSKDash's pub.odoMiles and
-- pub.tripMiles) is read over these in D.applyPublished, so its dash and ours agree; when QA has Roadworthy running,
-- a direct read of its figures goes there too.
-- ---------------------------------------------------------------------------
local ODO_BASE, ODO_SPREAD, ODO_WORN = 20000, 60000, 60000   -- a found car: 20000 miles, up to 60000 more by its id,
                                                             -- up to 60000 more for a worn-out engine
local ODO_SEND_MILES = 0.1                                   -- the driver's client sends no more often than this
-- a last send later than this after the driver's dash last saw the car is dropped, not sent: the server takes a send
-- from the car's last driver for a moment once they are out of the seat (DashProto GRACE_MS), and no longer
local ODO_LATE_MS = 3000
local ODO_ASK_MS, ODO_ASK_TRIES = 2000, 3                    -- a passenger's dash asks again this often, this many times
local ODO_STOP_KMH = 0.8                                     -- stopped, as the game's BaseVehicle.isStopped (and no
                                                             -- one gets out of a car that isn't): the miles go then
local ODO_STOP_MILES = 0.01                                  -- but only this many or more: stop-and-go traffic that
                                                             -- crosses the line again and again sends no more often
local KM_PER_MILE = 1.609344

-- a remainder by floor (Kahlua's % keeps the sign and goes wrong past 2^31)
local function _floorMod(a, m) return a - math.floor(a / m) * m end

-- a found car's starting mileage: stable for a given id and condition (0..100)
function D.odoSeed(id, cond)
    -- (a vehicle id is a short; brought into 0..65535 anyway, so id * 7919 stays far under 2^31)
    local i = _floorMod(math.abs(math.floor(tonumber(id) or 0)), 65536)
    local c = tonumber(cond) or 100
    if c < 0 then c = 0 elseif c > 100 then c = 100 end
    local miles = ODO_BASE + _floorMod(i * 7919, ODO_SPREAD) + math.floor((100 - c) / 100 * ODO_WORN)
    return miles + _floorMod(i * 3, 10) / 10      -- and a tenth, so not every car's tenths wheel sits at 0
end

-- the readings the parts show, from st.odo, st.trip and st.odoTrip (the wheels read odo and trip themselves):
--   odoShown   the VFD figures (cossette, luxury): the trip's whole miles while it shows, else the odometer's
--   odoShownT  the Dash Elite's LCD, six characters: "t" and the trip's miles ("t  128"), else the odometer, zero padded
--   odoMode, tripMode   the ODO and TRIP words, lit with the key on
function D.odoShow(st)
    local odo, trip = tonumber(st.odo) or 0, tonumber(st.trip) or 0
    local onTrip = st.odoTrip and true or false
    st.odoShown = math.floor(onTrip and trip or odo)
    local s
    if onTrip then
        s = tostring(_floorMod(math.floor(trip), 100000))      -- five figures after the "t"
        s = "t" .. string.rep(" ", 5 - #s) .. s
    else
        s = tostring(_floorMod(math.floor(odo), 1000000))      -- six figures, rolled over past 999999
        s = string.rep("0", 6 - #s) .. s
    end
    st.odoShownT = s
    st.odoMode = st.power and not onTrip
    st.tripMode = st.power and onTrip
end

-- the driver's client sends the car's figures to the server (and so to the other players in the car): no more than
-- every ODO_SEND_MILES, or now (force: a press, a first mileage), or now if at least flush miles haven't gone yet
-- (0, any: the engine stopped, or the driver left the seat or the car; ODO_STOP_MILES: the car stopped), so a drive's
-- last tenth isn't lost. A press, a first mileage and a flush of 0 are the coarse moments: the send says save, and the
-- server sends the car's whole modData out then, not every tenth (ZeD_ServerDash.lua). A coarse moment with no new miles
-- still goes once when the last send wasn't one, so what the server took reaches the clients near the car.
-- Single player sends nothing: the car's modData is the game's own there.
-- KNOWN LIMIT: ZeD.ServerPart.send sends as the first local player, so on a server a second split-screen player at the
-- wheel has every send refused (the server takes only the driver's); their miles count on their screen and aren't saved
function ZeD_Dashboard:_odoSend(vehicle, id, odo, force, flush)
    if not (isClient and isClient()) then return end
    local at = self._odoSentAt
    if not at then at = {}; self._odoSentAt = at end
    local last = at[id]
    if last == nil and not force then at[id] = odo; return end      -- (first sight: what the car has is what was sent)
    if not force and odo < last then at[id] = odo; return end       -- (the server's figure came in lower: count from it)
    local save = force or flush == 0
    local unsaved = self._odoUnsaved
    if not unsaved then unsaved = {}; self._odoUnsaved = unsaved end
    -- (a flush with nothing new sends nothing, unless the last send wasn't a coarse one: so calling it every frame the
    -- engine is off costs a compare or two)
    if force or odo - last >= ODO_SEND_MILES or (flush and odo > last and odo - last >= flush) or (save and unsaved[id]) then
        at[id] = odo
        unsaved[id] = (not save) or nil
        local md = _get(vehicle, "getModData", nil)
        local S, Pr = ZeD.ServerPart, ZeD.DashProto
        if not (md and S and S.send and Pr) then return end
        -- (the server writes these three and nothing else: ZeD_ServerDash.lua)
        S.send(Pr.MOD, Pr.ODO, { veh = id, odo = odo, trip = tonumber(md.ZeD_trip) or 0, show = md.ZeD_odoTrip == true,
            save = save and true or false })
    end
end

-- this frame's odometer and trip (miles: the distance driven since the last frame)
function ZeD_Dashboard:_odometer(vehicle, st, miles, id)
    local md = _get(vehicle, "getModData", nil)
    local odo, trip, first = nil, 0, false
    local mine = self._odoMine
    if mine and (mine.car ~= vehicle or not self._driver) then mine = nil; self._odoMine = nil end
    if md then
        -- (on a server the car's modData comes back from the server at a coarse moment, as it was when sent, and over
        -- what this driver has counted or pressed since. Only this driver's sends move the server's figures while they
        -- drive, so an odometer no higher than theirs is that echo: this driver's own figures stand, the trip and the
        -- switch too. An equal one counts: stopped, a press after the last send, then that send's echo, would undo the
        -- press. A press is in these figures: it writes the car and them. When the server holds other figures, it says
        -- so (ZeD_Dashboard:_odoSync), and only that moves these. Single player has no echo: there an equal odometer
        -- with another trip or switch is the car's own, and is read as it is)
        local mdOdo = tonumber(md.ZeD_odo) or -1
        if mine and (mdOdo < mine.odo or (mdOdo == mine.odo and isClient())) then
            md.ZeD_odo, md.ZeD_trip, md.ZeD_odoTrip = mine.odo, mine.trip, mine.show
        end
        odo = tonumber(md.ZeD_odo)
        trip = tonumber(md.ZeD_trip) or 0
        st.odoTrip = md.ZeD_odoTrip == true
    else
        st.odoTrip = false
    end
    if not odo then
        odo = D.odoSeed(id, st.engineCond)
        first = true
        if md then md.ZeD_odo = odo end
    end
    -- (a car whose modData can't be read keeps still at its seed: there is nowhere to count to)
    if self._driver and st.running and miles > 0 and md then
        odo, trip = odo + miles, trip + miles
        md.ZeD_odo, md.ZeD_trip = odo, trip
    end
    st.odo, st.trip = odo, trip
    if self._driver and md then
        self._odoCar = vehicle                                  -- the car this driver counts in (ZeD_Dashboard:_odoLeave)
        self._odoAt = getTimestampMs()                          -- and when the dash last saw it from the driver's seat
        if not mine then mine = {}; self._odoMine = mine end
        mine.car, mine.odo, mine.trip, mine.show = vehicle, odo, trip, st.odoTrip
        -- (the car just stopped, or the engine is off: the miles not sent yet go now, while this is still the driver)
        local stopped = (st.speed or 0) < ODO_STOP_KMH
        local stopNow = stopped and self._odoRolling == true
        self._odoRolling = not stopped
        local flush = nil
        if not st.running then flush = 0 elseif stopNow then flush = ODO_STOP_MILES end
        self:_odoSend(vehicle, id, odo, first, flush)
    end
    self:_odoAsk(vehicle, id)
    D.odoShow(st)
end

-- a passenger's dash asks the server for the car's figures as it sits down (ZeD_ServerDash.lua answers with DP.FIG, to
-- this player alone): a car stopped with its engine on sends none, so until it moves a tenth or stops its engine this
-- dash would read the car as the server's last coarse send left it, maybe a whole drive behind. Again every ODO_ASK_MS
-- until figures come (D.odoFig marks them), at most ODO_ASK_TRIES times: the server may not have this player in the
-- seat yet, or holds no figures for the car. At the wheel it forgets, so the next passenger seat asks again.
-- (The answer comes to the first local player, as every ZeD command does: split-screen's second player doesn't ask)
function ZeD_Dashboard:_odoAsk(vehicle, id)
    if self._driver then self._odoAsking = nil; return end
    if not (isClient and isClient()) or self.playerNum ~= 0 then return end
    local a = self._odoAsking
    if not a or a.car ~= vehicle then a = { car = vehicle, n = 0, at = 0 }; self._odoAsking = a end
    if a.got or a.n >= ODO_ASK_TRIES then return end
    local now = getTimestampMs()
    if a.n > 0 and now - a.at < ODO_ASK_MS then return end
    local S, Pr = ZeD.ServerPart, ZeD.DashProto
    if not (S and S.send and Pr and Pr.ASK) then return end
    a.n, a.at = a.n + 1, now
    S.send(Pr.MOD, Pr.ASK, { veh = id })
end

-- the driver left the seat or the car (or the car is another): the miles it hasn't sent go now. D.hide calls it as
-- the driver gets out (a hidden dash gets no prerender), and so do safe mode and the UI hiding; prerender calls it for
-- a seat change or another car. Only while the driver is still at the car: a late one is dropped (ODO_LATE_MS)
function ZeD_Dashboard:_odoLeave()
    local car = self._odoCar
    self._odoCar, self._odoMine, self._odoRolling = nil, nil, nil
    if not car then return end
    if getTimestampMs() - (self._odoAt or 0) > ODO_LATE_MS then return end    -- (too late: those miles stay unsent)
    local md = _get(car, "getModData", nil)
    local odo = md and tonumber(md.ZeD_odo)
    if odo then self:_odoSend(car, _get(car, "getId", 0), odo, false, 0) end
end

-- the trip back to 0 (the stem, or X on the electronic window while it shows the trip). The driver's own figures
-- (self._odoMine) take it too, or an older send's echo landing before the next frame would bring the old trip back
function ZeD_Dashboard:_tripZero(vehicle)
    local md = _get(vehicle, "getModData", nil)
    if not md then return end
    md.ZeD_trip = 0
    local mine = self._odoMine
    if mine and mine.car == vehicle then mine.trip = 0 end
    self:_odoSend(vehicle, _get(vehicle, "getId", 0), tonumber(md.ZeD_odo) or 0, true)
end

-- the electronic dashes' window: the trip (on) or the odometer
function ZeD_Dashboard:_odoShowTrip(vehicle, on)
    local md = _get(vehicle, "getModData", nil)
    if not md then return end
    md.ZeD_odoTrip = on and true or false
    local mine = self._odoMine
    if mine and mine.car == vehicle then mine.show = md.ZeD_odoTrip end
    self:_odoSend(vehicle, _get(vehicle, "getId", 0), tonumber(md.ZeD_odo) or 0, true)
end

-- the server refused this driver's figures (ZeD_ServerDash.lua: the odometer went back, or the trip went further than
-- it allows): this copy of the car was behind the server's, say a trip another driver zeroed that never reached here.
-- a: { veh, odo, trip = the server's figures, sent = the odometer in the refused send }. The odometer goes on from the
-- higher of the two, plus what was driven since that send; the trip from the server's, plus the same miles; the
-- window keeps this driver's switch. A second answer to a send from before the first is stale, and dropped (the
-- driver's odometer only goes up, so its sends after this answer all read at least this)
function ZeD_Dashboard:_odoSync(a)
    local Pr, mine = ZeD.DashProto, self._odoMine
    if not (Pr and mine and self._driver and type(a) == "table") then return end
    if not (Pr.okVeh(a.veh) and Pr.okMiles(a.odo) and Pr.okMiles(a.trip) and Pr.okMiles(a.sent)) then return end
    if mine.syncFrom and a.sent < mine.syncFrom then return end
    local car = mine.car
    local id = _get(car, "getId", nil)
    local md = _get(car, "getModData", nil)
    if id ~= a.veh or not md then return end
    local since = mine.odo - a.sent
    if since < 0 then since = 0 end
    local odo = math.max(a.odo, a.sent) + since
    local trip = a.trip + (odo - a.odo)
    md.ZeD_odo, md.ZeD_trip, md.ZeD_odoTrip = odo, trip, mine.show
    mine.odo, mine.trip, mine.syncFrom = odo, trip, odo
    -- (counted from the server's figure: the next send goes a tenth past it, sooner if more was driven)
    if self._odoSentAt then self._odoSentAt[id] = a.odo end
end

-- the figures the server took from the driver of the car this player rides in (ZeD_ServerDash.lua sends them to the
-- other seats at each send it takes and to a passenger who asks, ZeD_Dashboard:_odoAsk, and sends the car's whole
-- modData out only at the coarse moments). Checked as the
-- server checks a send, then written to this client's copy of the car only, never sent on: the dash reads them there
-- next frame. A driver's dash keeps its own (the server sends these to the other seats; a late one is dropped here).
-- a: { veh, odo, trip, show }
function D.odoFig(a)
    local Pr = ZeD.DashProto
    if not (Pr and Pr.okFigs and Pr.okFigs(a)) then return end
    local p = getSpecificPlayer and getSpecificPlayer(0)
    local car = p and _get(p, "getVehicle", nil)
    if not car or _get(car, "getId", nil) ~= a.veh then return end
    if _safe(function() return car:isDriver(p) end, false) then return end
    local md = _get(car, "getModData", nil)
    if not md then return end
    md.ZeD_odo, md.ZeD_trip, md.ZeD_odoTrip = a.odo, a.trip, a.show
    local inst = D._instance
    local asking = inst and inst._odoAsking
    if asking and asking.car == car then asking.got = true end    -- (the passenger's ask is answered: no more)
end

-- the server part's answers on the dash's module (ZeD_ServerLink.lua routes them here)
function D.onServer(command, a)
    local Pr = ZeD.DashProto
    if not Pr then return end
    if command == Pr.FIG then return D.odoFig(a) end
    local inst = D._instance
    if inst and command == Pr.SYNC then inst:_odoSync(a) end
end

function ZeD_Dashboard:_meterFlag(vehicle, down)
    local t = self:_tripOf(vehicle)
    t.meterOn = down and true or false
    t.fareMiles, t.waitMs = 0, 0
end

function ZeD_Dashboard:_trip(vehicle, st, dtMs)
    local t, id = self:_tripOf(vehicle)
    local moving = getGameSpeed() > 0
    local miles = moving and (st.speed or 0) * 0.6214 * dtMs / 3600000 or 0
    if not (st.keysIn or st.running or st.hotwired) then t.meterOn, t.fareMiles, t.waitMs = false, 0, 0 end
    if t.meterOn and st.running and moving then
        t.fareMiles = t.fareMiles + miles
        if (st.speed or 0) < WAIT_KMH then t.waitMs = t.waitMs + dtMs end
    end
    self:_odometer(vehicle, st, miles, id)
    st.meterOn = t.meterOn
    if t.meterOn then
        st.fare = _fare("TaxiFlagDrop") + _fare("TaxiPerFifthMile") * math.floor(t.fareMiles * 5)
                + _fare("TaxiPerMinuteWaiting") * math.floor(t.waitMs / 60000)
        st.fareExtra = _fare("TaxiPerExtraPassenger") * math.max(0, _riders(vehicle) - 1)
    else
        st.fare, st.fareExtra = 0, 0
    end
end

-- ---------------------------------------------------------------------------
-- the key in the lock (director, Oct 24 2026: "key needs turning animation
-- when starting"): ACC with the key in (director, Nov 7 2026: the key in the
-- ignition lights every lamp, so "it should be in accessory mode"; ACC sits left
-- of OFF), START while the starter turns, ON while the engine runs. It travels
-- ACC - OFF - ON - START a step at a time and rests a step on ON between the
-- ends: a start shows OFF, ON, then START; a start that does not catch steps
-- back through ON and OFF to ACC; shutting off holds ON a step, then OFF, then
-- ACC. From the click the hand holds the key at START until the engine answers
-- (KEY_REACH_MS). Hotwired, there is no key to draw.
-- ---------------------------------------------------------------------------
local KEY_STEP_MS, KEY_REACH_MS = 120, 600
local KEY_ORDER = { acc = 1, off = 2, on = 3, start = 4 }
local KEY_AT = { "acc", "off", "on", "start" }
function ZeD_Dashboard:_keyPos(st, now)
    if st.cranking or st.running then self._keyTurn = nil end
    local want = nil
    if st.keysIn and not st.hotwired then
        if st.cranking then want = "start"
        elseif st.running then want = "on"
        elseif self._keyTurn and now - self._keyTurn < KEY_REACH_MS then want = "start"
        else want = "acc" end
    end
    local cur = self._keyShown
    if want == nil or cur == nil then
        self._keyShown, self._keyWant, self._keyHold = want, want, 0
        return want
    end
    if want ~= self._keyWant then
        self._keyWant = want
        if cur == "on" then self._keyHold = now + KEY_STEP_MS end
    end
    if cur ~= want and now >= (self._keyHold or 0) then
        local i, j = KEY_ORDER[cur], KEY_ORDER[want]
        cur = KEY_AT[i + ((j > i) and 1 or -1)]
        if cur ~= want then self._keyHold = now + KEY_STEP_MS end
        self._keyShown = cur
    end
    return cur
end

-- ---------------------------------------------------------------------------
-- the ash tray and the van's right side (director, Oct 24 2026)
--
-- Every car with a tray (a design with an "ash" hit) has its own: shut on 6
-- cars in 10, the others open at one of the design's levels (two, four or six
-- butts; the taxi has only the full one), picked from the car's key number so
-- a car always looks the same. A click opens or shuts it (modData ZeD_ash);
-- open again, it is the car's own level.
--
-- The van's right side: a business with a logo in the game wears it as a
-- sticker (DashPx.vanLogos), any other company's van has a NO SMOKING plate,
-- a private van (plain Van, VanSeats and its paint jobs, a plain StepVan, the
-- burnt ones) an ash tray.
-- ---------------------------------------------------------------------------
local function _carHash(vehicle)
    local key = _get(vehicle, "getKeyId", nil)
    if key == nil then key = _get(vehicle, "getId", 0) end
    local s, h = tostring(key), 7
    for i = 1, #s do h = (h * 31 + s:byte(i)) % 1000003 end
    return h
end

-- per design, the tray's levels its sprites draw (none: no tray)
local function _ashLevels(des)
    local lv = des._ashLevels
    if lv then return lv end
    lv = {}
    for _, p in ipairs(des.parts) do
        if p.t == "sprite" and p.src == "ashOpen" and type(p.when) == "number" then lv[#lv + 1] = p.when end
    end
    table.sort(lv)
    des._ashLevels = lv
    return lv
end

local function _vanRight(base)
    if DP.vanLogos and DP.vanLogos[base] then return nil, DP.stickers and DP.stickers[DP.vanLogos[base]] end
    if base:find("Burnt", 1, true) then return "ash" end
    local b = base:gsub("Smashed%a*$", "")
    if b == "Van" or b == "VanSeats" or b == "StepVan" or b:sub(1, 9) == "VanSeats_" then return "ash" end
    return "nosmoke"
end
D._vanRight = _vanRight   -- exposed for QA probes

function ZeD_Dashboard:_tray(vehicle, des, designId, st, scriptName)
    local ck = self._trayKey
    if not (ck and ck.v == vehicle and ck.s == scriptName) then
        local base = scriptName:gsub("^Base%.", "")
        local vr, logo = nil, nil
        if designId == "van" then vr, logo = _vanRight(base) end
        ck = { v = vehicle, s = scriptName, h = _carHash(vehicle), vr = vr, logo = logo }
        self._trayKey = ck
    end
    st.vanRight = ck.vr
    st.vanTray = (ck.vr == "ash")
    self._logo = ck.logo
    local lv = _ashLevels(des)
    st.ashIsOpen, st.ashOpen = false, 0
    if #lv == 0 or (designId == "van" and not st.vanTray) then return end
    local open = D._ash[_get(vehicle, "getId", 0)]               -- (on a server: this game's memory, ACT.ash)
    if open == nil then
        local md = _get(vehicle, "getModData", nil)
        open = md and md.ZeD_ash                                 -- (single player; or a car a server once sent with it)
    end
    if open == nil then open = (ck.h % 10) >= 6 end
    st.ashIsOpen = open and true or false
    if st.ashIsOpen then st.ashOpen = lv[1 + math.floor(ck.h / 10) % #lv] end
end

-- ---------------------------------------------------------------------------
-- the taxi's hula girl (director, Oct 24 2026): frame 0 at rest; above 5 km/h
-- in a turn she leans out of it (1 or 2 by the way the car turns); a hard
-- change of speed or a bump flicks her once, 1 then 2. Each frame holds at
-- least HULA_HOLD_MS, so she sways rather than flickers. The turn is read from
-- the way the car travels (its position frame to frame: the engine's heading
-- is not exposed to Lua, and getAngleY is an Euler angle that flips past 90).
-- ---------------------------------------------------------------------------
local HULA_HOLD_MS = 150
local HULA_TURN = 0.25       -- radians a second of heading change: a turn
local HULA_JOLT = 30         -- km/h a second: hard braking or a hard launch
local HULA_BUMP = 1.5        -- degrees of pitch or roll in a frame: a bump
local HULA_STEP = 0.02       -- squares the car must travel before its heading is read again
local function _wrapPi(a)
    while a > math.pi do a = a - 2 * math.pi end
    while a < -math.pi do a = a + 2 * math.pi end
    return a
end
function ZeD_Dashboard:_hula(vehicle, st, now, dt)
    local H = self._hulaS
    if not H then H = { f = 0, hold = 0, yaw = 0 }; self._hulaS = H end
    local x, y = _get(vehicle, "getX", 0), _get(vehicle, "getY", 0)
    local pitch, roll = _get(vehicle, "getAngleX", 0), _get(vehicle, "getAngleZ", 0)
    local jolt = false
    if dt > 0 and getGameSpeed() > 0 then
        -- the heading of travel, read once the car has gone HULA_STEP; its change a second is the turn
        H.ms = (H.ms or 0) + dt
        if H.x then
            local dx, dy = x - H.x, y - H.y
            if dx * dx + dy * dy >= HULA_STEP * HULA_STEP then
                local ang = math.atan2(dy, dx)
                if H.ang and st.speed > WAIT_KMH then
                    local rate = _wrapPi(ang - H.ang) * 1000 / H.ms
                    H.yaw = H.yaw + (rate - H.yaw) * (H.ms / (120 + H.ms))
                else
                    H.yaw = 0
                end
                H.ang, H.x, H.y, H.ms = ang, x, y, 0
            elseif H.ms > 400 then
                H.yaw, H.ang, H.x, H.y, H.ms = 0, nil, x, y, 0      -- standing (nearly) still: no turn
            end
        else
            H.x, H.y, H.ms = x, y, 0
        end
        -- the change of speed, settled over ~150 ms (a frame's reading jitters)
        if H.speed then
            local acc = (st.speed - H.speed) * 1000 / dt
            H.acc = (H.acc or 0) + (acc - (H.acc or 0)) * (dt / (150 + dt))
            if math.abs(H.acc) > HULA_JOLT then jolt = true end
        end
        if H.pitch and (math.abs(_wrapPi(math.rad(pitch - H.pitch))) > math.rad(HULA_BUMP)
            or math.abs(_wrapPi(math.rad(roll - H.roll))) > math.rad(HULA_BUMP)) then jolt = true end
    end
    H.speed, H.pitch, H.roll = st.speed, pitch, roll
    if jolt and not H.flick and st.speed > WAIT_KMH then H.flick = { 1, 2 } end
    if D.qaHula then H.yaw = D.qaHula end
    if now >= H.hold then
        local f = 0
        if H.flick then
            f = table.remove(H.flick, 1)
            if #H.flick == 0 then H.flick = nil end
        elseif st.speed > WAIT_KMH and math.abs(H.yaw) > HULA_TURN then
            f = (H.yaw > 0) and 1 or 2
        end
        if f ~= H.f then H.f, H.hold = f, now + HULA_HOLD_MS end
    end
    st.hula = H.f
end

-- ---------------------------------------------------------------------------
-- the plate and its live parts: the template draws them (ZeD_Plate.lua); the
-- dash lends it its textures, the badge lines, the van's logo, the radio faces,
-- and the list the head unit adds its controls to
-- ---------------------------------------------------------------------------
function ZeD_Dashboard:_ctx(des, pending)
    local ctx = self._plateCtx
    if not ctx then ctx = { tex = tex }; self._plateCtx = ctx end
    ctx.sprites   = des.sprites
    ctx.badge     = self._badge
    ctx.scriptLow = self._scriptLow
    ctx.logo      = self._logo
    ctx.heads     = DP.heads
    ctx.pending   = pending
    ctx.now       = getTimestampMs()
    ctx.light     = self._light
    return ctx
end

-- ---------------------------------------------------------------------------
-- THE SIMPLE DASH (the director, Nov 2 2026, punch list 60; ZeDUI/SIMPLE_VERSIONS_PROPOSAL.md): a plain strip in
-- ZeD's own parts where the pixel dash sits, showing what this car's dash shows and reaching what it reaches. ZeD
-- setup's "Dashboard" row picks it (ZeD.Settings.dashSimple); a change takes effect the next frame, mid-drive too.
--   heading   the car's name (Passenger at the right for a passenger)
--   readouts  speed and RPM in large type over their bars; fuel, temperature, oil and volts as bars; gear,
--             odometer, clock and the climate; in the taxi the fare and the extras
--   lamps     the warning lamps this car's dash has, as status dots with their names, then every lamp a mod publishes
--             that has no dot here (ModSupport/VSKDash.lua; its readouts get a row of their own)
--   controls  rows of plain buttons: the car and the climate (each in the plate's left-to-right order), then the
--             fitted radio (its face's order) with its display as words before them
-- Every button carries the plate's own control id (ZeD_Dashboard:_plainControl -> _element), so a click, the right
-- button, the wheel on the radio's knobs and the controller go through _fire to ACT exactly as on the plate; the
-- lamps' hover cards are the plate's (D.lampText).
-- ---------------------------------------------------------------------------
function D.simple() return ZeD.Settings and ZeD.Settings.dashSimple and ZeD.Settings.dashSimple() or false end

ZeD.trDefaults({
    UI_ZeD_DashPlain_Pair = "%1: %2", UI_ZeD_DashPlain_Speed = "Speed", UI_ZeD_DashPlain_Mph = "mph", UI_ZeD_DashPlain_Rpm = "RPM",
    UI_ZeD_DashPlain_Fuel = "Fuel", UI_ZeD_DashPlain_Oil = "Oil", UI_ZeD_DashPlain_Volts = "Volts", UI_ZeD_DashPlain_Gear = "Gear",
    UI_ZeD_DashPlain_Odometer = "Odometer", UI_ZeD_DashPlain_Miles = "%1 mi", UI_ZeD_DashPlain_Clock = "Clock",
    UI_ZeD_DashPlain_AM = "AM", UI_ZeD_DashPlain_PM = "PM", UI_ZeD_DashPlain_Climate = "Climate", UI_ZeD_DashPlain_Heat = "Heat",
    UI_ZeD_DashPlain_FanN = "Fan %1", UI_ZeD_DashPlain_Fare = "Fare", UI_ZeD_DashPlain_Extras = "Extras", UI_ZeD_DashPlain_Dollars = "$%1",
    UI_ZeD_DashPlain_Lamps = "Lamps", UI_ZeD_DashPlain_Brake = "Brake", UI_ZeD_DashPlain_Belt = "Belt", UI_ZeD_DashPlain_Hot = "Hot",
    UI_ZeD_DashPlain_Shift = "Shift", UI_ZeD_DashPlain_TurnL = "Left turn", UI_ZeD_DashPlain_TurnR = "Right turn",
    UI_ZeD_DashPlain_FourWD = "4WD", UI_ZeD_DashPlain_RowCar = "Car", UI_ZeD_DashPlain_Ignition = "Ignition",
    UI_ZeD_DashPlain_Hotwired = "Hotwired", UI_ZeD_DashPlain_KeyOut = "Key out", UI_ZeD_DashPlain_TrunkLock = "Trunk lock",
    UI_ZeD_DashPlain_Cruise = "Cruise", UI_ZeD_DashPlain_Meter = "Meter", UI_ZeD_DashPlain_AshTray = "Ash tray",
    UI_ZeD_DashPlain_SetTemp = "Temp", UI_ZeD_DashPlain_Fan = "Fan", UI_ZeD_DashPlain_Tune = "Tune", UI_ZeD_DashPlain_Power = "Power",
    UI_ZeD_DashPlain_Signal = "Signal", UI_ZeD_DashPlain_Disc = "Disc in", UI_ZeD_DashPlain_Lights = "Lights",
    UI_ZeD_DashPlain_Trip = "Trip", UI_ZeD_DashPlain_Readouts = "Readouts", UI_ZeD_DashPlain_Km = "%1 km",
    UI_ZeD_DashPlain_Acc = "ACC",
})

local PLAIN_W, PLAIN_PAD, PLAIN_GAP, PLAIN_BIG_W, PLAIN_ROW_W, PLAIN_BIG_SEGS = 800, 8, 6, 120, 64, 12
-- a control for a part the car does not have (no trunk bed, heater, lightbar or tray) leaves the strip; one waiting on
-- the engine (cruise) stays, greyed, as on the plate
local PLAIN_STATIC = { hasTrunk = true, hasHeater = true, hasLightbar = true, vanTray = true }
local CLIMATE_IDS = { temp = true, tempup = true, tempdn = true, heat = true, fan = true, fanup = true, fandn = true,
                      ac = true, def = true, off = true, mode = true }
-- the plate's controls the strip shows as a readout instead (Nov 7 2026: the Trip cell zeroes the trip)
local PLAIN_CELL_IDS = { tripReset = true, odoButton = true }
-- the warning lamps in the strip's order, their names and their colours (theme tokens: never the plate's own colours)
local LAMP_ORDER = { "genLamp", "engLamp", "oilLamp", "brakeLamp", "beltLamp", "fuelLamp", "tempLamp", "shiftLamp",
                     "hiBeam", "turnL", "turnR", "fourWD" }
local LAMP_WORD = { genLamp = "Tooltip_Dashboard_Battery", engLamp = "IGUI_VehiclePartEngine", oilLamp = "UI_ZeD_DashPlain_Oil",
    brakeLamp = "UI_ZeD_DashPlain_Brake", beltLamp = "UI_ZeD_DashPlain_Belt", fuelLamp = "UI_ZeD_DashPlain_Fuel",
    tempLamp = "UI_ZeD_DashPlain_Hot", shiftLamp = "UI_ZeD_DashPlain_Shift", hiBeam = "Tooltip_Dashboard_Headlights",
    turnL = "UI_ZeD_DashPlain_TurnL", turnR = "UI_ZeD_DashPlain_TurnR", fourWD = "UI_ZeD_DashPlain_FourWD" }
local LAMP_TOKEN = { genLamp = "danger", oilLamp = "danger", brakeLamp = "danger", beltLamp = "danger", tempLamp = "danger",
    shiftLamp = "danger", engLamp = "warning", fuelLamp = "warning", fourWD = "warning", hiBeam = "info",
    turnL = "positive", turnR = "positive" }
-- the lamps with a hover card (the plate's LAMP_ZONE ids)
local PLAIN_LAMP_ZONE = { genLamp = "batt", engLamp = "eng", hiBeam = "head" }
local SIREN_WORD = { [0] = "IGUI_VehicleLightbar_STANDBY", "IGUI_VehicleLightbar_YELP", "IGUI_VehicleLightbar_WAIL", "IGUI_VehicleLightbar_ALARM" }
D.SIREN_WORD = SIREN_WORD

-- a plate control's enabled state this frame (the plate and the strip ask the same)
local function _hitEnabled(hz, st)
    local en = true
    if hz.needs then en = st[hz.needs] and true or false end
    if hz.id == "ignition" then en = st.hasKey or st.keysIn or st.hotwired or st.running end
    if hz.id == "meter" then en = st.power end
    if hz.id == "odoButton" then en = st.power end      -- (the electronic odometer's button needs the key; the stem doesn't)
    return en and true or false
end

-- per design, worked out once: its controls split into the car's and the climate's (each left to right, as the
-- controller's cone-nav reads the plate), its warning lamps, its gauges' full scale and whether it has the fare meter
local function _plainPlan(des)
    local pl = des._plainPlan
    if pl then return pl end
    pl = { car = {}, climate = {}, lamps = {}, speedMax = 120, rpmMax = 7000 }
    local seen, list = {}, {}
    for _, hz in ipairs(des.hits or {}) do
        if not seen[hz.id] then seen[hz.id] = true; list[#list + 1] = hz end
    end
    table.sort(list, function(a, b)
        local ax, bx = a.x + a.w / 2, b.x + b.w / 2
        if ax ~= bx then return ax < bx end
        return a.y < b.y
    end)
    for _, hz in ipairs(list) do
        -- (the trip stem and the electronic odometer's window are the Trip cell here, not buttons: ZeD_Dashboard:_plainReadouts)
        if not PLAIN_CELL_IDS[hz.id] then
            local row = CLIMATE_IDS[hz.id] and pl.climate or pl.car
            row[#row + 1] = hz
        end
    end
    pl.meter = seen.meter == true
    local has, sp, rp = {}, false, false
    for _, p in ipairs(des.parts or {}) do
        if p.t == "lamp" and p.src then has[p.src] = true end
        if p.t == "gear" then pl.gearLetters = p.letters end
        if (p.t == "needle" or p.t == "ribbon") and p.max then
            if p.src == "speed_mph" and not sp then pl.speedMax, sp = p.max, true
            elseif p.src == "rpm" and not rp then pl.rpmMax, rp = p.max, true end
        end
    end
    for _, src in ipairs(LAMP_ORDER) do if has[src] then pl.lamps[#pl.lamps + 1] = src end end
    pl.has = has
    des._plainPlan = pl
    return pl
end
D._plainPlan = _plainPlan   -- (QA probes)

-- a published lamp's state this frame, as the plate's lamps take it: amber or red as published, dark in a blink's dark
-- half, true (the lamp's own color) for an indicator that is on with nothing wrong
local function _pubState(l, phase)
    if l.blink and phase == 1 then return false end
    if l.rank >= 3 then return D.LAMP_COLOR.poor end
    if l.rank >= 2 then return D.LAMP_COLOR.worn end
    return true
end

-- what a mod published onto this design's parts (ModSupport/VSKDash.lua), run over ZeD's own reading: a lit lamp takes
-- the plate's lamp, a dark one leaves ZeD's own (Roadworthy's charge lamp knows nothing of a flat battery). A lamp this
-- plate has no spot for lights nothing here (V.BORROW_UNPAINTED) and is listed on the simple strip. The gear letter
-- moves only to a letter the plate has. The odometers show the mod's figures, rolled over past their last wheel.
function D.applyPublished(st, pub, des)
    local pl = _plainPlan(des)
    local phase = clockStep(getTimestampMs(), D.BLINK_MS, 2)
    for src, l in pairs(pub.lamps) do st[src] = _pubState(l, phase) end
    local worst = nil
    for _, e in ipairs(pub.list) do
        e.state = e.on and _pubState(e, phase) or false
        if e.on and e.rank >= 2 and not (e.role and pl.has[e.role]) and (not worst or e.rank > worst.rank) then worst = e end
    end
    local V = ZeD.ModSupport.VSKDash
    if worst and V.BORROW_UNPAINTED then
        local src = pl.has.engLamp and "engLamp" or (pl.has.genLamp and "genLamp" or nil)
        if src and not pub.lamps[src] then st[src] = worst.state end
    end
    st.gearPub = pub.gear
    st.gearSel = V.gearLetter(pl.gearLetters, pub.gear) or st.gearSel
    -- (the odometers: the mod's own figures over ZeD's, so its dash and ours agree; the wheels, the VFD and the LCD
    -- all read st.odo and st.trip. The trip stem still zeroes ZeD's own trip, which shows again without the mod.)
    if pub.odoMiles or pub.tripMiles then
        if pub.odoMiles then st.odo = pub.odoMiles end
        if pub.tripMiles then st.trip = pub.tripMiles end
        D.odoShow(st)
    end
    st.odoMiles, st.tripMiles = pub.odoMiles, pub.tripMiles
end

local function _pair(a, b) return ZeD.tr("UI_ZeD_DashPlain_Pair", a, b) end

-- the heater's set temperature as the plate's climate readout prints it (21 C at the knob's middle), in the
-- player's unit
local function _heatTemp(st)
    local t = 21 + (st.heaterTemp or 0) * 0.28
    local c = true
    pcall(function() c = getCore():getOptionTemperatureDisplayCelsius() end)
    if c == false then return tostring(math.floor(t * 9 / 5 + 32 + 0.5)) .. string.char(176) .. "F" end
    return tostring(math.floor(t + 0.5)) .. string.char(176) .. "C"
end

-- the key in the lock, as the plate draws it (its ACC - OFF - ON - START steps, ZeD_Dashboard:_keyPos). A dash with
-- no ACC on its lock (the race car's IGN toggle, st.keyAcc false) says Off there, as its plate shows
local function _ignitionWord(st)
    if st.keysIn and not st.hotwired then
        if st.keyPos == "start" then return ZeD.tr("UI_ZeD_Dash_PromptStart") end
        if st.keyPos == "on" then return ZeD.tr("UI_On") end
        if st.keyPos == "off" or not st.keyAcc then return ZeD.tr("UI_Off") end
        return ZeD.tr("UI_ZeD_DashPlain_Acc")
    end
    if st.hotwired then return ZeD.tr("UI_ZeD_DashPlain_Hotwired") end
    if st.running then return ZeD.tr("UI_On") end
    return ZeD.tr(st.hasKey and "UI_ZeD_DashPlain_KeyOut" or "UI_ZeD_Dash_PromptNoKey")
end

-- a button's words and whether it shows on (the primary look): a switch names itself, a setting adds its value
local LABEL_KEY = { lights = "Tooltip_Dashboard_Headlights", lock = "Tooltip_Dashboard_LockedDoors", trunk = "UI_ZeD_DashPlain_TrunkLock",
    cruise = "UI_ZeD_DashPlain_Cruise", meter = "UI_ZeD_DashPlain_Meter", ash = "UI_ZeD_DashPlain_AshTray", ac = "UI_ZeD_Dash_PromptAc" }
local ON_FROM = { lights = "lights", lock = "anyLocked", trunk = "trunkLocked", cruise = "cruise", meter = "meterOn", ash = "ashIsOpen", ac = "ac" }
local function _radioLabel(id, r)
    if id == "vol" then return _pair(ZeD.tr("IGUI_RadioVolume"), _pct((r.volume or 0) * 100)), r.on end
    if id == "tune" then return _pair(ZeD.tr("UI_ZeD_DashPlain_Tune"), RO.freqText(r.channel, r.ham)), false end
    if id == "pwr" then return ZeD.tr("UI_ZeD_DashPlain_Power"), r.switchOn end
    if id == "mic" then return ZeD.tr("IGUI_RadioMicrophone"), not r.micMuted end
    if id == "scan" then return ZeD.tr("UI_ZeD_Dash_PromptScan"), r.scanning end
    if id == "mute" then return ZeD.tr("UI_ZeD_Dash_PromptMute"), r.muted end
    if id == "play" then return ZeD.tr("UI_ZeD_Dash_PromptPlayStop"), r.playing end
    if id:sub(1, 6) == "preset" then
        local i = tonumber(id:sub(7)) or 0
        local p = r.presets and r.presets[i]
        return _pair(tostring(i), p and RO.freqText(p.freq, r.ham) or "--"), r.presetIdx == i
    end
    return nil
end
local function _plainLabel(id, st)
    if id == "ignition" then return _pair(ZeD.tr("UI_ZeD_DashPlain_Ignition"), _ignitionWord(st)), st.running end
    if ON_FROM[id] then return ZeD.tr(LABEL_KEY[id]), st[ON_FROM[id]] and true or false end
    if id == "lbar" then
        local m = st.lightbarMode or 0
        return _pair(ZeD.tr("ContextMenu_VehicleLightbar"), m == 0 and ZeD.tr("UI_Off") or tostring(m)), m > 0
    end
    if id == "siren" then
        local m = st.sirenMode or 0
        return _pair(ZeD.tr("UI_ZeD_Dash_PromptSiren"), ZeD.textCase(ZeD.tr(SIREN_WORD[m] or SIREN_WORD[0]))), m > 0
    end
    if id == "heat" then return ZeD.tr("Tooltip_Dashboard_Heater"), st.heaterOn and not st.ac end
    if id == "def" then return ZeD.tr("UI_ZeD_Dash_PromptDefrost"), st.heaterOn and (st.heaterTemp or 0) >= 25 end
    if id == "off" then return ZeD.tr("UI_ZeD_Dash_PromptClimateOff"), not st.heaterOn end
    if id == "temp" then return _pair(ZeD.tr("UI_ZeD_DashPlain_SetTemp"), _heatTemp(st)), false end
    if id == "fan" then return _pair(ZeD.tr("UI_ZeD_DashPlain_Fan"), tostring(st.fan or 0)), (st.fan or 0) > 0 end
    if st.radio then
        local t, on = _radioLabel(id, st.radio)
        if t then return t, on and true or false end
    end
    return ZeD.tr(_promptKey(id, st)), false
end

-- the radio's display in words (what its glass shows: the band and frequency or the disc's time, the station or
-- the disc, then its marks)
local function _radioLine(r)
    if not r.on then return ZeD.tr("UI_Off") end
    local parts = {}
    if r.playing then
        local s = math.floor((r.cdMs or 0) / 1000)
        local m = math.floor(s / 60)
        parts[1] = string.format("CD %d:%02d", m, s - m * 60)
        parts[2] = r.mediaTitle or ZeD.textCase(RO.word("disc"))
    elseif r.ham then
        parts[1] = "CH" .. (r.presetIdx and string.format("%02d", r.presetIdx) or "--") .. " " .. RO.freqText(r.channel, true) .. " MHz"
        local p = r.presetIdx and r.presets and r.presets[r.presetIdx]
        local nm = r.name or (p and p.name ~= "" and p.name) or nil
        if nm then parts[2] = nm end
    else
        parts[1] = "FM " .. RO.freqText(r.channel, false) .. " MHz"
        if r.name then parts[#parts + 1] = r.name end
    end
    if r.flash then parts[#parts + 1] = ZeD.textCase(r.flash)
    elseif r.scanning then parts[#parts + 1] = ZeD.textCase(RO.word("scan")) end
    if r.muted then parts[#parts + 1] = ZeD.textCase(RO.word("mute")) end
    if r.ham and r.micMuted then parts[#parts + 1] = ZeD.textCase(RO.word("micOff")) end
    if not r.ham and not r.playing then
        if r.presetIdx and r.presetIdx <= 6 then parts[#parts + 1] = "P" .. r.presetIdx end
        if r.signal then parts[#parts + 1] = ZeD.tr("UI_ZeD_DashPlain_Signal") end
        if r.hasMedia then parts[#parts + 1] = ZeD.tr("UI_ZeD_DashPlain_Disc") end
    end
    return table.concat(parts, " | ")
end

local function _clockText(st)
    local h, m = st.hour or 0, st.minute or 0
    local ok, v24 = pcall(function() return getCore():getOptionClock24Hour() end)
    if ok and v24 == false then
        local pm = h >= 12
        h = h - math.floor(h / 12) * 12
        if h == 0 then h = 12 end
        return string.format("%d:%02d", h, m) .. " " .. ZeD.tr(pm and "UI_ZeD_DashPlain_PM" or "UI_ZeD_DashPlain_AM")
    end
    return string.format("%02d:%02d", h, m)
end

local function _climateText(st)
    if not (st.power and st.heaterOn) then return ZeD.tr("UI_Off") end
    return _heatTemp(st) .. " | " .. ZeD.tr(st.ac and "UI_ZeD_Dash_PromptAc" or "UI_ZeD_DashPlain_Heat")
        .. " | " .. ZeD.tr("UI_ZeD_DashPlain_FanN", tostring(st.fan or 0))
end

-- the readings beside the two big ones, in columns of three: { label, value (or nil), bar share (or nil), bar color,
-- id: the plate control it also is (the Trip: "tripReset"), else nil }
local function _cell(out, n, label, value, bar, col, id)
    n = n + 1
    local c = out[n]
    if not c then c = {}; out[n] = c end
    c.label, c.value, c.bar, c.col, c.id = label, value, bar, col, id
    return n
end

-- the player's distance units: the game's measurement option ("Imperial" or "Metric"; looked up first, as a build
-- may lack it: then miles, the cars being American). Read again at most once a second (the strip draws every frame;
-- an option changed in the Options screen shows within the second), and with no closure made per read.
local UNITS_MS = 1000
local _unitsAt, _unitsMetric = nil, false
local function _readMetric()
    local core = getCore()
    return core.getOptionMeasurementFormat ~= nil and core:getOptionMeasurementFormat() == "Metric"
end
local function _metric()
    local now = getTimestampMs()
    if _unitsAt == nil or now - _unitsAt >= UNITS_MS or now < _unitsAt then
        _unitsAt = now
        local ok, v = pcall(_readMetric)
        _unitsMetric = ok and v == true
    end
    return _unitsMetric
end
-- miles as the strip shows them, in the player's units: whole, or to the tenth (the trip; cut, not rounded, as the
-- wheels turn)
local function _distText(miles, tenths, metric)
    local v = (tonumber(miles) or 0) * (metric and KM_PER_MILE or 1)
    local s = tenths and string.format("%.1f", math.floor(v * 10) / 10) or tostring(math.floor(v))
    return ZeD.tr(metric and "UI_ZeD_DashPlain_Km" or "UI_ZeD_DashPlain_Miles", s)
end
local function _plainCells(st, pl, out)
    local T = ZeD.T
    local n = 0
    n = _cell(out, n, ZeD.tr("UI_ZeD_DashPlain_Fuel"), st.power and _pct((st.fuel or 0) * 100) or "--", st.fuel or 0, st.fuelLamp and T.danger or T.accent)
    -- (the bar goes red for a hot engine, not for the key-on bulb check that lights the hot lamp: st.hot is ZeD's own
    -- reading, and a lamp a mod publishes counts once the engine runs, when st.check is false)
    local hot = st.hot or (st.tempLamp and not st.check)
    n = _cell(out, n, ZeD.tr("IGUI_Temperature"), nil, st.temp or 0, (st.tempLamp == D.LAMP_COLOR.worn) and T.warning or (hot and T.danger or T.accent))
    n = _cell(out, n, ZeD.tr("UI_ZeD_DashPlain_Oil"), nil, st.oil or 0, T.accent)
    n = _cell(out, n, ZeD.tr("UI_ZeD_DashPlain_Volts"), nil, st.volts or 0, T.accent)
    local g = tostring(st.gear or "")
    local gear = st.gearSel or ""
    if gear == "D" and st.running and g:match("^%d$") then gear = gear .. " " .. g end
    n = _cell(out, n, ZeD.tr("UI_ZeD_DashPlain_Gear"), st.gearPub or gear)
    -- the odometer and the trip (Nov 7 2026, punch list 92): the plate's figures, in the player's units; A on Trip zeroes it
    local metric = _metric()
    n = _cell(out, n, ZeD.tr("UI_ZeD_DashPlain_Odometer"), _distText(st.odo, false, metric))
    n = _cell(out, n, ZeD.tr("UI_ZeD_DashPlain_Trip"), _distText(st.trip, true, metric), nil, nil, "tripReset")
    n = _cell(out, n, ZeD.tr("UI_ZeD_DashPlain_Clock"), _clockText(st))
    if st.hasHeater then n = _cell(out, n, ZeD.tr("UI_ZeD_DashPlain_Climate"), _climateText(st)) end
    if pl.meter then
        local live = st.power and st.meterOn
        n = _cell(out, n, ZeD.tr("UI_ZeD_DashPlain_Fare"), live and ZeD.tr("UI_ZeD_DashPlain_Dollars", string.format("%.2f", st.fare or 0)) or "--")
        n = _cell(out, n, ZeD.tr("UI_ZeD_DashPlain_Extras"), live and ZeD.tr("UI_ZeD_DashPlain_Dollars", string.format("%.2f", st.fareExtra or 0)) or "--")
    end
    return n
end

-- the buttons of a row (the plate's controls, the car's missing parts left out)
local function _plainItems(list, st, out)
    for _, hz in ipairs(list) do
        if not (hz.needs and PLAIN_STATIC[hz.needs] and not st[hz.needs]) then
            local text, on = _plainLabel(hz.id, st)
            out[#out + 1] = { id = hz.id, text = text, on = on, en = _hitEnabled(hz, st) }
        end
    end
    return out
end

-- the radio's row: its display in words, then its face's controls (the plate's head unit ids)
local function _radioItems(st)
    local r = st.radio
    local H = r and DP.heads and DP.heads[r.kind]
    if not H then return nil end
    local out = { { text = _radioLine(r) } }
    local seen = {}
    for _, hp in ipairs(H.parts) do
        local id = nil
        if hp.t == "display" then id = "radio" elseif hp.t == "knob" or hp.t == "button" then id = hp.id end
        if id and not seen[id] then
            seen[id] = true
            local text, on = _plainLabel(id, st)
            out[#out + 1] = { id = id, text = text, on = on, en = true }
        end
    end
    return out
end

-- lays items ({ w }) out left to right from x0, a new line where the next would pass xMax; the height taken
local function _flow(items, x0, xMax, y, h, gap)
    local x, lines = x0, 1
    for i = 1, #items do
        local it = items[i]
        if x > x0 and x + it.w > xMax then x = x0; y = y + h + gap; lines = lines + 1 end
        it.x, it.y = x, y
        x = x + it.w + gap
    end
    return lines * h + (lines - 1) * gap
end

-- a big reading: its name, the figure in large type with its unit, its bar under it
function ZeD_Dashboard:_plainBig(x, y, w, label, value, unit, share, col, big)
    local T = ZeD.T
    local px, tm = T.px, ZeD.TM
    local tc, td = T.text, T.textDim
    self:drawText(label, x, y, td.r, td.g, td.b, td.a or 1, T.fontF1)
    local y2 = y + big.fh1 + px(2)
    local vw
    if big.hf then vw = ZeD.Text.draw(self, big.hf, value, x, y2, big.z, tc.r, tc.g, tc.b, tc.a or 1, "l")
    else
        self:drawText(value, x, y2, tc.r, tc.g, tc.b, tc.a or 1, T.fontF4)
        vw = tm:MeasureStringX(T.fontF4, value)
    end
    if unit and unit ~= "" then self:drawText(unit, x + vw + px(4), y2 + big.h - big.fh1, td.r, td.g, td.b, td.a or 1, T.fontF1) end
    local s = math.max(0, math.min(1, share or 0))
    ZeD.Atoms.drawSegFill(self, x, y2 + big.h + px(3), w, big.barH, PLAIN_BIG_SEGS, math.floor(s * PLAIN_BIG_SEGS + 0.5), col)
end

-- the readouts block: the two big readings, then the cells in columns of rows
function ZeD_Dashboard:_plainReadouts(st, pl, cells, n, y, W, big, rows, cellH)
    local T = ZeD.T
    local px, tm = T.px, ZeD.TM
    local pad, gap = px(PLAIN_PAD), px(PLAIN_GAP)
    local bigW = px(PLAIN_BIG_W)
    local mph = math.floor((st.speed_mph or 0) + 0.5)
    self:_plainBig(pad, y, bigW, ZeD.tr("UI_ZeD_DashPlain_Speed"), tostring(mph), ZeD.tr("UI_ZeD_DashPlain_Mph"),
        (st.speed_mph or 0) / pl.speedMax, T.accent, big)
    local rpm = math.floor((st.rpm or 0) / 50 + 0.5) * 50
    self:_plainBig(pad + bigW + gap * 2, y, bigW, ZeD.tr("UI_ZeD_DashPlain_Rpm"), tostring(rpm), nil,
        (st.rpm or 0) / pl.rpmMax, st.shiftLamp and T.danger or T.accent, big)
    local ax = pad + 2 * bigW + gap * 4
    local cols = math.max(1, math.ceil(n / rows))
    local cw = math.floor((W - pad - ax - (cols - 1) * gap * 2) / cols)
    local f1, f2 = T.fontF1, T.fontF2
    local fh1, fh2 = tm:getFontHeight(f1), tm:getFontHeight(f2)
    local fbH = T.fillBarH or px(8)
    local tc, td = T.text, T.textDim
    for c = 0, cols - 1 do
        -- each column's names share one width (the longest of them)
        local lw = 0
        for r = 1, rows do
            local cell = (c * rows + r <= n) and cells[c * rows + r]
            if cell then lw = math.max(lw, tm:MeasureStringX(f1, cell.label)) end
        end
        lw = lw + px(6)
        local cx = ax + c * (cw + gap * 2)
        for r = 1, rows do
            local i = c * rows + r
            local cell = (i <= n) and cells[i]
            if cell then
                local cy = y + (r - 1) * cellH
                local vc, lc = tc, td        -- the value's and the name's colors (the focus ink on the mark)
                if cell.id then
                    -- a reading that is also a control (the Trip): the pointer's wash or the controller's mark under
                    -- it, its click area and its focus element (ZeD_Dashboard:_plainControl, the plate's ids)
                    local hx, hy, hw, hh = cx - px(2), cy - px(1), cw + px(4), fh2 + px(2)
                    if self._driver then
                        local focused = self._focEl and self._focEl.id == "dash:" .. cell.id
                        if focused and ZeD.Focus and ZeD.Focus.mark and ZeD.Focus.mark(self, hx, hy, hw, hh, self._markOpts, true) then
                            vc = T.textOnFocus
                            lc = vc
                        elseif self:isMouseOver() then
                            local mx, my = self:getMouseX(), self:getMouseY()
                            if mx >= hx and mx < hx + hw and my >= hy and my < hy + hh then
                                local hv = T.hover
                                self:drawRect(hx, hy, hw, hh, hv.a or 0.1, hv.r, hv.g, hv.b)
                            end
                        end
                    end
                    self:_plainControl(cell.id, hx, hy, hw, hh, st, true)
                end
                self:drawText(cell.label, cx, cy + math.floor((fh2 - fh1) / 2), lc.r, lc.g, lc.b, lc.a or 1, f1)
                local vx = cx + lw
                if cell.bar then
                    local vw = cell.value and math.max(px(32), tm:MeasureStringX(f2, cell.value)) or 0
                    local bw = cx + cw - vx - (cell.value and (vw + px(4)) or 0)
                    if bw > px(8) then ZeD.Atoms.drawFillBar(self, vx, cy + math.floor((fh2 - fbH) / 2), bw, cell.bar, false, cell.col, fbH) end
                    if cell.value then
                        self:drawText(cell.value, cx + cw - tm:MeasureStringX(f2, cell.value), cy, tc.r, tc.g, tc.b, tc.a or 1, f2)
                    end
                elseif cell.value then
                    self:drawText(cell.value, vx, cy, vc.r, vc.g, vc.b, vc.a or 1, f2)
                end
            end
        end
    end
end

-- a row's name in the left column
function ZeD_Dashboard:_plainRowName(text, y, h)
    local T = ZeD.T
    local td = T.textDim
    local fh1 = ZeD.TM:getFontHeight(T.fontF1)
    self:drawText(text, T.px(PLAIN_PAD), y + math.floor((h - fh1) / 2), td.r, td.g, td.b, td.a or 1, T.fontF1)
end

-- a row's buttons (and the radio's words), drawn, each registered under its plate id
local _btnOpts = {}
function ZeD_Dashboard:_plainButtons(items, st, mx, my, over, zones)
    local T = ZeD.T
    local bh = T.buttonH
    local tc = T.text
    local fh2 = ZeD.TM:getFontHeight(T.fontF2)
    for _, it in ipairs(items) do
        if it.id then
            local en = it.en and self._driver
            local hov = (en and over and mx >= it.x and mx < it.x + it.w and my >= it.y and my < it.y + bh) and true or false
            local o = _btnOpts
            o.hover, o.disabled = hov, not en
            o.focus = (en and self._focEl and self._focEl.id == "dash:" .. it.id) and self._markOpts or nil
            ZeD.Molecules.drawButton(self, it.x, it.y, it.w, bh, it.text, it.on and "primary" or "default", hov and isMouseButtonDown(0), nil, o)
            self:_plainControl(it.id, it.x, it.y, it.w, bh, st, it.en)
            -- the heater's hover card sits on its button (the plate's: the heater button, else the temperature control)
            if (it.id == "heat" or (it.id == "temp" and not zones.heat)) and st.hasHeater then
                zones.heat = { id = "heat", x = it.x, y = it.y, w = it.w, h = bh }
            end
        else
            self:drawText(it.text, it.x, it.y + math.floor((bh - fh2) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        end
    end
end

-- the lamps: a status dot each (its colour lit, a hollow square dark) and its name
function ZeD_Dashboard:_plainLamps(items, st, zones)
    local T = ZeD.T
    local px = T.px
    local ds = px(7)
    local fh2 = ZeD.TM:getFontHeight(T.fontF2)
    local tc = T.text
    for _, it in ipairs(items) do
        local v = nil
        if it.pub then v = it.pub.state else v = st[it.src] end
        local col = nil
        if type(v) == "string" then col = (v == D.LAMP_COLOR.worn) and T.warning or T.danger
        elseif v then col = it.pub and T.info or T[LAMP_TOKEN[it.src] or "danger"] end
        local dy = it.y + math.floor((fh2 - ds) / 2)
        if col then ZeD.Atoms.drawStatusDot(self, it.x, dy, col, ds)
        else ZeD.Atoms.drawStatusHollow(self, it.x, dy, T.textDim, ds) end
        self:drawText(it.text, it.x + ds + px(4), it.y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        local zid = it.src and PLAIN_LAMP_ZONE[it.src]
        if zid then zones[#zones + 1] = { id = zid, x = it.x, y = it.y, w = it.w, h = fh2 } end
    end
end

-- the lamp (or the heater's button) under the pointer: the plate's detail card
function ZeD_Dashboard:_plainLampHover(st, zones, mx, my)
    self._lampHov = nil
    if not st.lampsOn or not self:isMouseOver() then return end
    if zones.heat then zones[#zones + 1] = zones.heat end
    for _, z in ipairs(zones) do
        if mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h then
            local name, lines = D.lampText(z.id, st)
            if name then
                self._lampHov = z.id
                ZeD.Atoms.requestDetailCard(self, "lamp:" .. z.id, { title = name, lines = lines, maxW = 220 }, self)
            end
            return
        end
    end
end

-- the strip: lay out, size and place, then draw (k: the plate's multiple, kept for the props up close)
local _plainCellBuf = {}
function ZeD_Dashboard:_plain(des, st, k)
    local T = ZeD.T
    local px, tm = T.px, ZeD.TM
    local f1, f2 = T.fontF1, T.fontF2
    local fh1, fh2 = tm:getFontHeight(f1), tm:getFontHeight(f2)
    local pad, gap, bh = px(PLAIN_PAD), px(PLAIN_GAP), T.buttonH
    local pl = _plainPlan(des)
    local pn = self.playerNum
    local W = math.min(px(PLAIN_W), getPlayerScreenWidth(pn))
    local rowX, rowMax = pad + px(PLAIN_ROW_W), W - pad
    -- the big figures: the distance-field heading face (the simple watch's), else F4
    local big = self._plainBigM or {}
    self._plainBigM = big
    big.hf = ZeD.Font and ZeD.Font.sdf and ZeD.Font.sdf.head
    big.z = big.hf and (24 * (T.scale or 1) / (big.hf.face or 64)) or nil
    if not big.z then big.hf = nil end
    big.h = big.hf and math.floor(ZeD.Text.height(big.hf, big.z)) or tm:getFontHeight(T.fontF4)
    big.fh1, big.barH = fh1, px(8)
    local blockH = fh1 + px(2) + big.h + px(3) + big.barH
    local n = _plainCells(st, pl, _plainCellBuf)
    local rows = math.max(1, math.ceil(n / 3))
    local cellH = math.max(fh2, T.fillBarH or px(8)) + px(3)
    local readH = math.max(blockH, rows * cellH - px(3))

    -- the rows below the readouts, laid out first: their wrapping sets the strip's height
    local y = pad + fh1 + gap + readH + gap
    local lamps = {}
    local pub = st.pub
    for _, src in ipairs(pl.lamps) do
        local lit = pub and pub.lamps[src]
        local text = lit and lit.name or ZeD.tr(LAMP_WORD[src])
        lamps[#lamps + 1] = { src = src, text = text, w = px(7) + px(4) + tm:MeasureStringX(f2, text) + px(8) }
    end
    -- everything a mod published: the lamps with no dot of their own here, by the mod's own name, then its readouts
    if pub then
        local taken = {}
        for _, e in ipairs(pub.list) do
            if e.role and pl.has[e.role] and not taken[e.role] then taken[e.role] = true
            else lamps[#lamps + 1] = { pub = e, text = e.name, w = px(7) + px(4) + tm:MeasureStringX(f2, e.name) + px(8) } end
        end
    end
    local lampY = y
    if #lamps > 0 then y = y + _flow(lamps, rowX, rowMax, y, fh2, px(4)) + gap end
    local sections = {}
    local car = _plainItems(pl.car, st, {})
    if #car > 0 then sections[#sections + 1] = { name = ZeD.tr("UI_ZeD_DashPlain_RowCar"), items = car } end
    local clim = _plainItems(pl.climate, st, {})
    if #clim > 0 then sections[#sections + 1] = { name = ZeD.tr("UI_ZeD_DashPlain_Climate"), items = clim } end
    local radio = _radioItems(st)
    if radio then sections[#sections + 1] = { name = ZeD.tr("Tooltip_Dashboard_Radio"), items = radio } end
    if pub and #pub.cells > 0 then
        local items = {}
        for _, c in ipairs(pub.cells) do items[#items + 1] = { text = _pair(c.name, c.text or _pct(c.share * 100)) } end
        sections[#sections + 1] = { name = ZeD.tr("UI_ZeD_DashPlain_Readouts"), items = items }
    end
    for _, sec in ipairs(sections) do
        for _, it in ipairs(sec.items) do
            if it.id then it.w = ZeD.Molecules.buttonW(it.text)
            else it.w = math.min(rowMax - rowX, tm:MeasureStringX(f2, it.text) + px(8)) end
        end
        sec.y = y
        sec.h = _flow(sec.items, rowX, rowMax, y, bh, px(4))
        y = y + sec.h + gap
    end
    local stripH = (self._pad and self._driver) and ZeD.PadGlyphs.stripH() or 0
    local bodyH = y - gap + pad
    local H = bodyH + stripH

    -- the place: the pixel dash's, centred on the bottom edge of the player's screen
    local x0 = getPlayerScreenLeft(pn) + math.floor((getPlayerScreenWidth(pn) - W) / 2)
    local y0 = getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) - H
    if self:getWidth() ~= W then self:setWidth(W) end
    if self:getHeight() ~= H then self:setHeight(H) end
    if self:getX() ~= x0 then self:setX(x0) end
    if self:getY() ~= y0 then self:setY(y0) end
    -- the radio and the siren controller up close line up on the strip's right end (plate pixels, as the console)
    local cr = self._plainConsole or {}
    self._plainConsole = cr
    cr.x, cr.y, cr.w, cr.h = 0, 0, W / k, H / k
    self._consoleRect = cr

    -- the box and its heading
    ZeD.Surface.fill(self, 0, 0, W, bodyH, "surf2")
    local b = T.borderS
    self:drawRectBorder(0, 0, W, bodyH, b.a or 1, b.r, b.g, b.b)
    local th, td = T.textHead or T.text, T.textDim
    local name = (self._badge and self._badge.plainName) or ""
    self:drawText(name, pad, pad, th.r, th.g, th.b, th.a or 1, f1)
    if not self._driver then
        local pass = ZeD.textCase(ZeD.tr("UI_ZeD_Dash_Passenger"))
        self:drawText(pass, W - pad - tm:MeasureStringX(f1, pass), pad, td.r, td.g, td.b, td.a or 1, f1)
    end
    self:_plainReadouts(st, pl, _plainCellBuf, n, pad + fh1 + gap, W, big, rows, cellH)

    local mx, my = self:getMouseX(), self:getMouseY()
    self._over = self:isMouseOver()
    local zones = {}
    if #lamps > 0 then
        self:_plainRowName(ZeD.tr("UI_ZeD_DashPlain_Lamps"), lampY, fh2)
        self:_plainLamps(lamps, st, zones)
    end
    for _, sec in ipairs(sections) do
        self:_plainRowName(sec.name, sec.y, bh)
        self:_plainButtons(sec.items, st, mx, my, self._over, zones)
    end
    self:_plainLampHover(st, zones, mx, my)

    -- the controller's prompts while it has the dash (the help line's strip, as on the props up close)
    if stripH > 0 then
        local prompts
        local fe = self._focEl
        if fe then
            prompts = { { glyph = "A", label = fe.promptA or ZeD.tr("UI_ZeD_Dash_PromptPress") } }
            if fe.promptX then prompts[#prompts + 1] = { glyph = "X", label = fe.promptX } end
            prompts[#prompts + 1] = { glyph = "B", label = ZeD.tr("UI_ZeD_Dash_PromptDrive") }
        else
            prompts = { ZeD.tr("UI_ZeD_Dash_HintWheel") }
        end
        ZeD.PadGlyphs.drawStrip(self, 0, bodyH, W, prompts)
    end
end

-- ---------------------------------------------------------------------------
-- prerender: the plate, the live parts, the hits and focus elements
-- ---------------------------------------------------------------------------
function ZeD_Dashboard:prerender()
    local chr = getSpecificPlayer(self.playerNum)
    local vehicle = chr and chr:getVehicle()
    -- (in another car than the one the driver counted in: its last miles go to the server now, before anything returns.
    -- Getting out sends them in D.hide, since this dash is hidden then; _odoLeave drops a send that comes too late)
    if self._odoCar and self._odoCar ~= vehicle then self:_odoLeave() end
    -- (the car lost some way other than getting out: let go of the controller and the focus
    -- ring too, so an unseen dash keeps neither; code audit Oct 17 2026)
    if not chr or not vehicle then
        self:setVisible(false); self.vehicle = nil; self._odoAsking = nil; self:_release(); self:_unregister()
        return
    end
    if ISUIHandler and ISUIHandler.allUIVisible == false then
        if self._odoCar then self:_odoLeave() end              -- (hidden, the dash stops counting: what it counted goes now)
        self:setVisible(false); return
    end
    if self.vehicle ~= vehicle then                            -- a new car: its needles start from rest
        self._mem = {}
        self._keyShown, self._keyWant, self._keyTurn, self._hulaS = nil, nil, nil, nil
    end
    self.vehicle = vehicle
    local vd = getPlayerVehicleDashboard and getPlayerVehicleDashboard(self.playerNum)
    if vd and vd.isVisible and vd:isVisible() then pcall(vd.setVisible, vd, false) end

    -- (the simple strip sizes and places itself, ZeD_Dashboard:_plain; _s stays the plate's multiple, which the radio
    -- and the siren controller up close are drawn at)
    local plain = D.simple()
    local k
    if plain then k = P.k(self:_scale()) else local _, _, kk = self:_layout(); k = kk end
    self._s = k
    local now = getTimestampMs()
    local dt = self._lastMs and math.max(0, math.min(250, now - self._lastMs)) or 0
    self._lastMs = now
    self._driver = _safe(function() return vehicle:isDriver(chr) end, false)
    if self._odoCar and not self._driver then self:_odoLeave() end    -- (moved out of the driver's seat)
    local st = _state(vehicle, chr)
    local pubV = ZeD.ModSupport and ZeD.ModSupport.VSKDash
    if pubV then
        if self._driver then st.pub = pubV.read(vehicle, chr, self._mem) else st.pub = pubV.figures(vehicle, self._mem) end
    end
    D.derive(st, self._mem, dt)
    self:_trip(vehicle, st, dt)
    self._st = st
    local scriptName = _safe(function() return tostring(vehicle:getScriptName() or "") end, "")
    self._scriptLow = scriptName:lower()
    -- the design and the badge lines, worked out again only for another car or language (Oct 22 2026, the
    -- drawing-cost work: they were read every frame)
    local bk = self._badgeKey
    if ZeD.trTestOn then ZeD.trTestOn() end   -- (keeps the test-language state fresh)
    local trs = ZeD._trState
    local trOn = (trs and trs.on) and true or false
    local des, designId, ownFamily
    if bk and bk.v == vehicle and bk.s == scriptName and bk.gen == ZeD._trGen and bk.on == trOn then
        des, designId, ownFamily = bk.des, bk.id, bk.own
    else
        des, designId, ownFamily = _designFor(scriptName)
        -- every state picture of the design asked for now, as the dash first shows the car: the game loads a picture
        -- in the background the first time it is asked for, and one first wanted mid-drive was missing for a frame
        -- (the hula girl's first sway, QA Oct 25 2026)
        for name in pairs(des.sprites or {}) do tex(name) end
        self._badge = _badges(des, vehicle, scriptName, ownFamily)
        self._badgeKey = { v = vehicle, s = scriptName, gen = ZeD._trGen, on = trOn, des = des, id = designId, own = ownFamily }
    end
    self._designId = designId
    if st.pub then
        local okP, eP = pcall(D.applyPublished, st, st.pub, des)
        if not okP then pubV.note("dash published", eP) end    -- (never logOnce: a mod's data is no ZeD fault)
    end
    st.brand = self._badge and self._badge.brand      -- the console's mark: the sprite and its model line show by it
    st.keyPos = self:_keyPos(st, now)
    st.keyAcc = des.sprites ~= nil and des.sprites["key_acc_" .. tostring(designId)] ~= nil     -- a lock with ACC printed on it
    self:_tray(vehicle, des, designId, st, scriptName)
    if designId == "taxi" then self:_hula(vehicle, st, now, dt) else st.hula = 0 end
    local Focus = ZeD.Input and ZeD.Input.Focus
    local DetM = ZeD.Input and ZeD.Input.Detector
    local gamepad = DetM and DetM.getMode and DetM.getMode() == "gamepad"
    self._pad = gamepad and true or false      -- the controller prompts' words are looked up only while a pad plays
    -- the focus cue is a gamepad affordance: the dash still holds focus for the ring under mouse play, but paints nothing
    self._focEl = (gamepad and Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() == self) and Focus.getFocusedElement(self) or nil
    -- (the pad went to a window (LB / RB): the dash leaves the window list, so closing
    -- that window never hands the D-pad back to the dash)
    if self._reg and Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() ~= self then self:_unregister() end
    self._hit = {}; self._elements = {}
    self._consoleRect = des.console   -- the radio and siren props up close line up on the console (plate pixels; _s = k)
    if plain then
        local okP, eP = pcall(self._plain, self, des, st, k)
        if not okP then ZeD.logOnce("dash plain", eP) end
        self:_ring(Focus)
        return
    end
    _nightLight(self, vehicle, chr, st, des, dt)

    local cv = P.canvas(self, 0, 0, k)
    self._cv = cv
    local pending = {}
    local okD, eD = pcall(PL.draw, cv, des, st, self:_ctx(des, pending), BASE_W, BASE_H)
    if not okD then ZeD.logOnce("dash plate", eD); return end  -- (code audit Oct 17 2026)
    -- controls last, so a focus cue sits over the art
    self._over = self:isMouseOver()
    for _, hz in ipairs(des.hits) do
        self:_control(hz.id, hz.x, hz.y, hz.w, hz.h, st, _hitEnabled(hz, st))
    end
    for _, c in ipairs(pending) do self:_control(c[1], c[2], c[3], c[4], c[5], st, c[6]) end
    -- the top edge's two words: cream with a dark shadow, or a plain dark ink where the design's top edge is light
    if not self._driver then
        local pass = ZeD.tr("UI_ZeD_Dash_Passenger")
        if des.passInk then P.text(cv, pass, 12, 2, P.color(des.passInk), "35", 1, "l")
        else P.text(cv, pass, 12, 2, P.color("#d8d6cc"), "35", 1, "l", nil, "#101010") end
    end

    local Det = ZeD.Input and ZeD.Input.Detector
    if Det and Det.getMode and Det.getMode() == "gamepad" and self._driver then
        local hint
        local PG = ZeD.PadGlyphs
        local set = PG and PG.set()
        local ink, shadow = P.color(des.hintInk or "#ece8dc"), (not des.hintInk) and "#101010" or nil
        if self._focEl and set then
            -- the buttons as their small pictures, each before its word, right-aligned at DashPx.hintRight
            -- (ZeD_PadGlyphs; director, Oct 24 2026)
            local segs = { { "A", self._focEl.promptA or ZeD.tr("UI_ZeD_Dash_PromptPress") } }
            if self._focEl.promptX then segs[#segs + 1] = { "X", self._focEl.promptX } end
            segs[#segs + 1] = { "B", ZeD.tr("UI_ZeD_Dash_PromptDrive") }
            local x = DP.hintRight
            for i = #segs, 1, -1 do
                local word = ZeD.upper(segs[i][2])
                x = x - P.textWidth(word, "35", 1)
                P.text(cv, word, x, 2, ink, "35", 1, "l", nil, shadow)
                x = x - 3 - PG.miniWidth(segs[i][1], set)
                PG.drawMini(cv, segs[i][1], x, 2, ink, shadow, set)
                x = x - 5
            end
        else
            if self._focEl then
                local pa, pb = self._focEl.promptA or ZeD.tr("UI_ZeD_Dash_PromptPress"), ZeD.tr("UI_ZeD_Dash_PromptDrive")
                hint = self._focEl.promptX and ZeD.tr("UI_ZeD_Dash_HintAxb", pa, self._focEl.promptX, pb) or ZeD.tr("UI_ZeD_Dash_HintAb", pa, pb)
            else
                hint = ZeD.tr("UI_ZeD_Dash_HintWheel")
            end
            -- right-aligned in the room every plate leaves plain at the top edge's right end (DashPx.hintRight)
            P.text(cv, ZeD.upper(hint), DP.hintRight, 2, ink, "35", 1, "r", nil, shadow)
        end
    end
    self:_lampHover(des, st, k)
    self:_ring(Focus)
end

-- this frame's controls to the focus ring, the focused one kept by its id (the plate and the simple strip share the
-- ids, so the controller stays on the same control when the form changes mid-drive)
function ZeD_Dashboard:_ring(Focus)
    if Focus and Focus.setRingZoneElements then
        local zone = self._focusRing[1]
        local oldEl = zone.elements[zone.focusedElementIdx or 1]
        local keep = nil
        if oldEl then for i, e in ipairs(self._elements) do if e.id == oldEl.id then keep = i; break end end end
        Focus.setRingZoneElements(self, "dashControls", self._elements, keep)
        Focus.setZoneFocusable(self, "dashControls", #self._elements > 0)
    end
end

-- The overlay pass: the controller's mark on a control (the hand, corners or ants) and the lamp's detail card, drawn
-- last so nothing covers them
function ZeD_Dashboard:render()
    ZeD.Focus.drawOverlay(self, self)
end

-- the lamp under the pointer: the library's detail card (title in F4, a line for what is known in F2), asked for each
-- frame and drawn by the overlay pass after the shared delay
function ZeD_Dashboard:_lampHover(des, st, k)
    self._lampHov = nil
    if not st.lampsOn then return end
    if not self:isMouseOver() then return end
    local mx, my = self:getMouseX() / k, self:getMouseY() / k
    local hz = nil
    for _, z in ipairs(_lampZones(des)) do
        if mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h and (z.id ~= "heat" or st.hasHeater) then hz = z end
    end
    if not hz then return end
    local name, lines = D.lampText(hz.id, st)
    if not name then return end
    self._lampHov = hz.id
    ZeD.Atoms.requestDetailCard(self, "lamp:" .. hz.id, { title = name, lines = lines, maxW = 220 }, self)
end

function ZeD_Dashboard:_fire(id, secondary)
    local chr = getSpecificPlayer(self.playerNum)
    local v = self.vehicle
    if not chr or not v or not self._driver then return end
    if getGameSpeed() == 0 then return end
    if getGameSpeed() > 1 then setGameSpeed(1) end
    local fn = ACT[id]; if not fn then return end
    local st = self._st or _state(v, chr)
    -- the key turned to start: the dash shows it on its way (ZeD_Dashboard:_keyPos)
    if id == "ignition" and not secondary and st.keysIn and not st.running then self._keyTurn = getTimestampMs() end
    local ok, err = pcall(fn, chr, v, st, secondary, self)
    if not ok then print("[ZeD] Dashboard: action " .. tostring(id) .. " failed: " .. tostring(err)) end
end

function ZeD_Dashboard:onMouseDown(x, y)
    for _, hr in ipairs(self._hit or {}) do
        if hr.enabled and x >= hr.x and x < hr.x + hr.w and y >= hr.y and y < hr.y + hr.h then self:_fire(hr.id, false); return true end
    end
    return false
end
function ZeD_Dashboard:onRightMouseDown(x, y)
    for _, hr in ipairs(self._hit or {}) do
        if hr.enabled and SECONDARY[hr.id] and x >= hr.x and x < hr.x + hr.w and y >= hr.y and y < hr.y + hr.h then self:_fire(hr.id, true); return true end
    end
    return false
end

-- the wheel turns the radio knob under the pointer (a positive delta is the wheel turned down)
function ZeD_Dashboard:onMouseWheel(del)
    local x, y = self:getMouseX(), self:getMouseY()
    for _, hr in ipairs(self._hit or {}) do
        if hr.enabled and (hr.id == "vol" or hr.id == "tune") and x >= hr.x and x < hr.x + hr.w and y >= hr.y and y < hr.y + hr.h then
            local chr = getSpecificPlayer(self.playerNum)
            local st = self._st
            if chr and st and st.radio and self._driver then
                if hr.id == "vol" then RO.volStep(chr, st.radioPart, del > 0 and -1 or 1, false) else RO.tuneStep(chr, st.radioPart, del > 0 and -1 or 1) end
            end
            return true
        end
    end
    return false
end

function ZeD_Dashboard:_claim()
    local Focus = ZeD.Input and ZeD.Input.Focus; if not Focus then return end
    Focus.registerWindow(self)
    self._reg = true
    Focus.claimFocus(self)
end
function ZeD_Dashboard:_release()
    local Focus = ZeD.Input and ZeD.Input.Focus; if not Focus then return end
    if Focus.getFocusedWindow() == self then Focus.releaseFocus() end
end
function ZeD_Dashboard:_unregister()
    self._reg = nil
    local Focus = ZeD.Input and ZeD.Input.Focus
    if Focus then pcall(Focus.unregisterWindow, self) end
end

-- ---------------------------------------------------------------------------
-- Lifecycle + hooks (contract unchanged from the S123 first cut)
-- ---------------------------------------------------------------------------
function D.install()
    if D._instance then return D._instance end
    local inst = ZeD_Dashboard:new(0)
    inst:initialise()
    inst:addToUIManager()
    inst:setVisible(false)
    D._instance = inst
    print("[ZeD] Dashboard: v6 pixel dashboard installed (vanilla parked)")
    return inst
end
function D.getInstance() return D._instance end
function D.show(character)
    if ZeD.Safe.on("dashboard") then return end   -- safe mode: vanilla's dashboard stays (SafeMode.lua)
    if not (character and instanceof(character, "IsoPlayer") and character:isLocalPlayer()) then return end
    local inst = D._instance or D.install()
    local pn = character.getPlayerNum and character:getPlayerNum() or 0
    if pn ~= inst.playerNum then return end
    local vehicle = character:getVehicle()
    if vehicle then
        inst.vehicle = vehicle
        inst:setVisible(true)
        -- (the driver's seat leaves the D-pad with the wheels: Vehicle > Dashboard hands it over)
        if not vehicle:isDriver(character) then inst:_release(); inst:_unregister() end
    else
        if inst._odoCar then pcall(inst._odoLeave, inst) end    -- (the last miles first: a hidden dash draws nothing)
        inst:setVisible(false); inst:_release(); inst:_unregister()
    end
end
-- the driver's dash, shown (the World wheel's Vehicle > Dashboard asks)
function D.canTakePad(character)
    local inst = D._instance
    local vehicle = character and character:getVehicle()
    if not (inst and inst:isVisible() and vehicle) or inst.playerNum ~= character:getPlayerNum() then return false end
    return _safe(function() return vehicle:isDriver(character) end, false)
end
-- the controller on the dash's controls, until B (or LB / RB to a window)
function D.takePad(character)
    if not D.canTakePad(character) then return false end
    D._instance:_claim()
    return true
end

function D.hide(character)
    local inst = D._instance; if not inst then return end
    if not (character and instanceof(character, "IsoPlayer") and character:isLocalPlayer()) then return end
    local pn = character.getPlayerNum and character:getPlayerNum() or 0
    if pn ~= inst.playerNum then return end
    inst.vehicle, inst._odoAsking = nil, nil          -- (back in the same car later: a passenger asks again)
    -- (the driver got out: the miles not sent yet go now, while the car is still beside them and the server still
    -- looks after it; once hidden, this dash gets no prerender to send them from. ZeD_Dashboard:_odoLeave)
    if inst._odoCar then pcall(inst._odoLeave, inst) end
    inst:setVisible(false); inst:_release(); inst:_unregister()
end

-- Safe mode (SafeMode.lua): this dash hides and lets go of the controller, and
-- vanilla's (parked by setVisible only, still in the UI with its car) shows
-- again for a driver. Taking over again shows this one for whoever is seated;
-- its prerender hides vanilla's.
ZeD.Safe.register("dashboard", {
    leave = function()
        local inst = D._instance
        if inst then
            if inst._odoCar then pcall(inst._odoLeave, inst) end    -- (the last miles first, as D.hide)
            inst:setVisible(false)
            pcall(inst._release, inst)
            pcall(inst._unregister, inst)
        end
        local vd = getSpecificPlayer(0) and getPlayerVehicleDashboard and getPlayerVehicleDashboard(0)
        if vd and vd.vehicle and not (ISUIHandler and ISUIHandler.allUIVisible == false) then vd:setVisible(true) end
    end,
    enter = function()
        local p = getSpecificPlayer(0)
        if p and p:getVehicle() then D.show(p) end
    end,
})

-- the server part's answers to the odometer (ZeD_Dashboard:_odoSync; looked up at each call, so a reload takes effect)
do
    local SP, Pr = ZeD.ServerPart, ZeD.DashProto
    if SP and SP.on and Pr then SP.on(Pr.MOD, function(command, a) ZeD.Dashboard.onServer(command, a) end) end
end

Events.OnGameStart.Add(function() D._instance = nil; D.install() end)
Events.OnEnterVehicle.Add(function(character) pcall(D.show, character) end)
Events.OnSwitchVehicleSeat.Add(function(character) pcall(D.show, character) end)
Events.OnExitVehicle.Add(function(character) pcall(D.hide, character) end)
