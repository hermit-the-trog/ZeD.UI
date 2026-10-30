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

local function _brandName(vehicle, scriptName)
    local key = nil
    pcall(function() local sc = vehicle:getScript(); key = sc:getCarModelName() or sc:getName() end)
    local name = nil
    if key then
        key = tostring(key)
        name = getTextOrNull("IGUI_VehicleName" .. key)
        if not name and key:find("Burnt") then name = getTextOrNull("IGUI_VehicleName" .. (key:gsub("Burnt", ""))) end
    end
    local s = name and tostring(name) or tostring(scriptName or ""):gsub("^Base%.", ""):gsub("(%l)(%u)", "%1 %2")
    return ZeD.upper(s)
end

-- The game names a car "<livery> <maker> <model>": "Fossoil Chevalier D6", "Knox Distillery Franklin Valuline",
-- "Wrecked Dash Rancher", "Muldraugh Police Chevalier Nyala". The maker is one of these five.
local MAKERS = { CHEVALIER = true, DASH = true, FRANKLIN = true, MASTERSON = true, MERCIA = true }
-- the service a fleet livery names leads its unit plate ("Meade Sheriff" -> SHERIFF, "State Trooper" -> TROOPER)
local SERVICES = { "POLICE", "SHERIFF", "TROOPER", "SWAT", "RANGER", "FIRE", "AMBULANCE", "TAXI" }

local function _join(words, i, j)
    local s = ""
    for n = i, j do s = (s == "") and words[n] or (s .. " " .. words[n]) end
    return s
end

-- The badge roles a design's badge parts ask for: the maker and model as one line (full), the make, the
-- model, the design's sub line ("5.0", "D6", "4X4"), and a fleet car's unit line ("TAXI - CAB 26").
-- The livery never reaches a maker's badge: a Fossoil D6 still says CHEVALIER. A name with no maker in
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
    return { full = make .. " " .. model, make = make, model = model, sub = design.sub or "", unit = unit, livery = livery, name = name }
end

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
    return not (S and S.dashLampsOn) or S.dashLampsOn()
end
function D.worse(a, b)
    if a == nil then return b end
    if b == nil then return a end
    return (TONE_RANK[a] >= TONE_RANK[b]) and a or b
end
-- the lamp for a tone: false (dark: fine, or the blink's dark half under 10%) or its colour
function D.lampColor(t)
    if t == nil or t == "good" then return false end
    if t == "dead" and math.floor(getTimestampMs() / D.BLINK_MS) % 2 == 1 then return false end
    return D.LAMP_COLOR[t]
end

-- The values the parts read (ZeDUI/tools/dashpx/live.py derives the same for the previews).
function D.derive(st, mem, dtMs)
    local live = st.running or st.keysIn or st.hotwired
    local batt = st.battRaw or 0
    st.power = (live and batt > 0.02) and true or false
    local v = {}
    v.speed_kmh = st.power and st.speed or 0
    v.speed_mph = v.speed_kmh * 0.6214
    v.rpm   = st.running and st.rpmRaw or 0
    v.fuel  = st.power and clamp01(st.fuelRaw) or 0
    v.batt  = st.power and clamp01(batt) or 0
    v.temp  = st.running and (st.engWarn and 0.82 or 0.5) or (st.power and 0.12 or 0)
    v.oil   = st.running and (0.45 + 0.35 * math.min(1, v.rpm / 6000)) or 0
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
    -- (ZeD setup's "Dashboard warning lamps", on by default: off, the lamps as before: the battery under 20% charge,
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
    st.brakeLamp  = check
    st.beltLamp   = check
    st.fuelLamp   = st.power and v.fuel < 0.15
    st.tempLamp   = st.power and v.temp > 0.8
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
-- the ash tray: open or shut, kept in the car's modData (a car the dash has not touched shows its own default)
ACT.ash    = function(chr, v, st) v:getModData().ZeD_ash = not st.ashIsOpen end
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
    preset4 = "UI_ZeD_Dash_PromptStore", preset5 = "UI_ZeD_Dash_PromptStore", preset6 = "UI_ZeD_Dash_PromptStore" }
ZeD.trDefaults({
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
    local y = getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) - h - 6 * k
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
        -- X offers the secondary verb only when it can happen: "Remove key" needs a key in the lock
        local secondary = SECONDARY[id]
        if id == "ignition" and not st.keysIn then secondary = nil end
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
    if not t then t = { miles = 0, fareMiles = 0, waitMs = 0, meterOn = false }; self._trips[id] = t end
    return t, id
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
    if st.running then t.miles = t.miles + miles end
    if not (st.keysIn or st.running or st.hotwired) then t.meterOn, t.fareMiles, t.waitMs = false, 0, 0 end
    if t.meterOn and st.running and moving then
        t.fareMiles = t.fareMiles + miles
        if (st.speed or 0) < WAIT_KMH then t.waitMs = t.waitMs + dtMs end
    end
    st.odo = (1000 + (id * 37) % 8000 + math.floor(t.miles)) % 10000
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
-- when starting"): OFF with the key in, START while the starter turns, ON while
-- the engine runs. It travels OFF - ON - START and rests a step on ON between
-- the ends: a start shows ON, then START; a start that does not catch steps back
-- through ON to OFF; shutting off holds ON a step, then OFF. From the click
-- the hand holds the key at START until the engine answers (KEY_REACH_MS).
-- Hotwired, there is no key to draw.
-- ---------------------------------------------------------------------------
local KEY_STEP_MS, KEY_REACH_MS = 120, 600
local KEY_ORDER = { off = 1, on = 2, start = 3 }
local KEY_AT = { "off", "on", "start" }
function ZeD_Dashboard:_keyPos(st, now)
    if st.cranking or st.running then self._keyTurn = nil end
    local want = nil
    if st.keysIn and not st.hotwired then
        if st.cranking then want = "start"
        elseif st.running then want = "on"
        elseif self._keyTurn and now - self._keyTurn < KEY_REACH_MS then want = "start"
        else want = "off" end
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
    local md = _get(vehicle, "getModData", nil)
    local open = md and md.ZeD_ash
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
-- prerender: the plate, the live parts, the hits and focus elements
-- ---------------------------------------------------------------------------
function ZeD_Dashboard:prerender()
    local chr = getSpecificPlayer(self.playerNum)
    local vehicle = chr and chr:getVehicle()
    -- (the car lost some way other than getting out: let go of the controller and the focus
    -- ring too, so an unseen dash keeps neither; code audit Oct 17 2026)
    if not chr or not vehicle then
        self:setVisible(false); self.vehicle = nil; self:_release(); self:_unregister()
        return
    end
    if ISUIHandler and ISUIHandler.allUIVisible == false then self:setVisible(false); return end
    if self.vehicle ~= vehicle then                            -- a new car: its needles start from rest
        self._mem = {}
        self._keyShown, self._keyWant, self._keyTurn, self._hulaS = nil, nil, nil, nil
    end
    self.vehicle = vehicle
    local vd = getPlayerVehicleDashboard and getPlayerVehicleDashboard(self.playerNum)
    if vd and vd.isVisible and vd:isVisible() then pcall(vd.setVisible, vd, false) end

    local w, h, k = self:_layout()
    self._s = k
    local now = getTimestampMs()
    local dt = self._lastMs and math.max(0, math.min(250, now - self._lastMs)) or 0
    self._lastMs = now
    local st = _state(vehicle, chr)
    D.derive(st, self._mem, dt)
    self:_trip(vehicle, st, dt)
    self._st = st
    self._driver = _safe(function() return vehicle:isDriver(chr) end, false)
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
    st.keyPos = self:_keyPos(st, now)
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
    _nightLight(self, vehicle, chr, st, des, dt)

    local cv = P.canvas(self, 0, 0, k)
    self._cv = cv
    local pending = {}
    local okD, eD = pcall(PL.draw, cv, des, st, self:_ctx(des, pending), BASE_W, BASE_H)
    if not okD then ZeD.logOnce("dash plate", eD); return end  -- (code audit Oct 17 2026)
    -- controls last, so a focus cue sits over the art
    self._over = self:isMouseOver()
    for _, hz in ipairs(des.hits) do
        local en = true
        if hz.needs then en = st[hz.needs] and true or false end
        if hz.id == "ignition" then en = st.hasKey or st.keysIn or st.hotwired or st.running end
        if hz.id == "meter" then en = st.power end
        self:_control(hz.id, hz.x, hz.y, hz.w, hz.h, st, en)
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
    if ZeD.Safe.on() then return end   -- safe mode: vanilla's dashboard stays (SafeMode.lua)
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
    inst.vehicle = nil
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

Events.OnGameStart.Add(function() D._instance = nil; D.install() end)
Events.OnEnterVehicle.Add(function(character) pcall(D.show, character) end)
Events.OnSwitchVehicleSeat.Add(function(character) pcall(D.show, character) end)
Events.OnExitVehicle.Add(function(character) pcall(D.hide, character) end)
