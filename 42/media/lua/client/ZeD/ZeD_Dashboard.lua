-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Dashboard.lua
-- ============================================================================
-- VEHICLE DASHBOARD v5 (S123) — a physical dash built from plates + live overlays.
--
-- Design: ZeDUI/mockups/zed_dashboard_v5_molded.html (locked Oct 12 2026).
-- Static art ships as PNG plates generated from that mockup by
-- ZeDUI/tools/plates/plates_dash.html (body per hood molding, tintable by cabin;
-- cluster per gauge style; switch row; console per kind; badge shapes; head-unit
-- overlays). Each plate carries an anchor table (DashPlates.lua, generated) that
-- tells this file where the live parts go: needles, lit segments, digits, lamps,
-- knob pointers, LEDs, display text, hit rects.
--
-- Replaces ISVehicleDashboard (parked, never removed). Every action is a vanilla
-- verb (ISVehicleMenu / ISVehiclePartMenu / vehicle client commands / radio
-- device data), so behaviour and MP commands stay identical to vanilla.
--
-- Gamepad: registers as a FocusManager window when the driver is seated and no
-- ZeD window owns focus. D-pad cone-nav across the controls, A fires, X = the
-- secondary (remove key, tune down, volume down, store preset), B releases.
-- Passengers see the dash read-only. HOOK_MAP.md #2 / #4.
-- ============================================================================

require "ZeD/ZeD_Panel"
require "ZeD/DashPlates"

ZeD = ZeD or {}
ZeD.Dashboard = ZeD.Dashboard or {}
local D = ZeD.Dashboard
local PL = ZeD.DashPlates

local BASE_W, BASE_H = 800, 172
local TEXDIR = "media/textures/ZeD/dash/"
local ICONDIR = "media/textures/ZeD/icons/"
D.scale = D.scale or 1.0   -- organism multiplier on top of T.scale (UI scale axis to come)

-- ---------------------------------------------------------------------------
-- Colour helpers
-- ---------------------------------------------------------------------------
local function hex(h)
    h = tostring(h or "#ffffff"):gsub("#", "")
    if #h == 3 then h = h:sub(1,1):rep(2) .. h:sub(2,2):rep(2) .. h:sub(3,3):rep(2) end
    local r = tonumber(h:sub(1,2), 16) or 255
    local g = tonumber(h:sub(3,4), 16) or 255
    local b = tonumber(h:sub(5,6), 16) or 255
    return { r = r/255, g = g/255, b = b/255, a = 1 }
end
local _colCache = {}
local function col(c)
    if type(c) == "table" then return c end
    if not c then return { r = 1, g = 1, b = 1, a = 1 } end
    local v = _colCache[c]
    if not v then
        if c:sub(1,4) == "rgba" then
            local r,g,b,a = c:match("rgba%(([%d%.]+),%s*([%d%.]+),%s*([%d%.]+),%s*([%d%.]+)%)")
            v = { r = (tonumber(r) or 0)/255, g = (tonumber(g) or 0)/255, b = (tonumber(b) or 0)/255, a = tonumber(a) or 1 }
        else v = hex(c) end
        _colCache[c] = v
    end
    return v
end

-- Cabin tints: the mockup pad colours. The body plate is a #d0d0d0 greyscale, so
-- the tint is the pad colour divided by 0.82 to land on the mockup's exact tone.
local function tintOf(h) local c = hex(h); return { r = math.min(1, c.r/0.82), g = math.min(1, c.g/0.82), b = math.min(1, c.b/0.82) } end
local CABINS = {
    walnut = tintOf("#3b2a19"), slate = tintOf("#3c4046"), red = tintOf("#4f1114"), patrol = tintOf("#15171c"),
    cocoa = tintOf("#3d2919"), charcoal = tintOf("#222224"), beige = tintOf("#5a5240"), navy = tintOf("#20263a"),
    burgundy = tintOf("#3a1018"), fleet = tintOf("#2a2b2c"), tan = tintOf("#4a3c2a"), khaki = tintOf("#3a3826"),
    taxi = tintOf("#181818"), medic = tintOf("#4a4c4e"), fire = tintOf("#3a0e0a"), race = tintOf("#1c1c1c"),
}

-- ---------------------------------------------------------------------------
-- Vehicle -> design (hood molding, gauge style, console, badge, cabin, accessory)
-- ---------------------------------------------------------------------------
local DESIGNS = {
    luxury    = { hood = "arch",   style = "cadillac", console = "luxury", badge = "chrome",  cabin = "walnut",   brand = "ELECTRONIC INSTRUMENT CLUSTER" },
    nyala     = { hood = "arch",   style = "analog",   console = "sedan",  badge = "oval",    cabin = "slate" },
    cossette  = { hood = "arch",   style = "c4",       console = "sport",  badge = "script",  cabin = "red",      sub = "5.0", needle = "#E03030" },
    police    = { hood = "square", style = "analog",   console = "fleet",  badge = "stencil", cabin = "patrol",   accessory = true },
    d6        = { hood = "square", style = "analog",   console = "truck",  badge = "stamped", cabin = "cocoa",    sub = "D6" },
    dashelite = { hood = "trap",   style = "toyota",   console = "modern", badge = "decal",   cabin = "charcoal", sub = "EFI", brand = "DASH ELECTRONIC DISPLAY" },
    primani   = { hood = "trap",   style = "toyota",   console = "modern", badge = "decal",   cabin = "beige",    sub = "EFI", brand = "ELECTRONIC DISPLAY" },
    dart      = { hood = "arch",   style = "analog",   console = "sedan",  badge = "oval",    cabin = "navy" },
    horizon   = { hood = "arch",   style = "analog",   console = "sedan",  badge = "chrome",  cabin = "burgundy" },
    wagon     = { hood = "arch",   style = "analog",   console = "truck",  badge = "chrome",  cabin = "walnut" },
    suv       = { hood = "square", style = "analog",   console = "modern", badge = "decal",   cabin = "charcoal", sub = "4X4" },
    van       = { hood = "square", style = "analog",   console = "truck",  badge = "stamped", cabin = "fleet" },
    bulldriver= { hood = "square", style = "analog",   console = "truck",  badge = "stamped", cabin = "tan",      sub = "V8" },
    rancher   = { hood = "square", style = "analog",   console = "truck",  badge = "stamped", cabin = "khaki",    sub = "4X4" },
    taxi      = { hood = "arch",   style = "analog",   console = "fleet",  badge = "stencil", cabin = "taxi" },
    ambulance = { hood = "square", style = "analog",   console = "fleet",  badge = "stencil", cabin = "medic",    accessory = true },
    fire      = { hood = "square", style = "analog",   console = "fleet",  badge = "stencil", cabin = "fire",     accessory = true },
    ranger    = { hood = "square", style = "analog",   console = "fleet",  badge = "stencil", cabin = "khaki",    accessory = true },
    race      = { hood = "arch",   style = "c4",       console = "sport",  badge = "script",  cabin = "race",     needle = "#E03030", sub = "RACE" },
}
local MODEL_DESIGN = {
    CarLuxury = "luxury", CarNormal = "nyala", CarLights = "nyala", SportsCar = "cossette", PickUpTruck = "d6",
    ModernCar = "dashelite", ModernCar02 = "primani", SmallCar = "dart", SmallCar02 = "horizon",
    CarStationWagon = "wagon", CarStationWagon2 = "wagon", SUV = "suv", Van = "van", StepVan = "van", VanSeats = "van",
    PickUpVan = "bulldriver", OffRoad = "rancher", CarTaxi = "taxi", VanAmbulance = "ambulance", RaceCar = "race",
}
local LIVERY_DESIGN = {
    { "ambulance", "ambulance" }, { "hosp", "ambulance" }, { "fire", "fire" }, { "police", "police" }, { "sheriff", "police" },
    { "trooper", "police" }, { "swat", "police" }, { "kst", "police" }, { "louisvillepd", "police" }, { "ranger", "ranger" },
    { "taxi", "taxi" }, { "race", "race" },
}
local function _designFor(scriptName)
    local n = tostring(scriptName or ""):gsub("^Base%.", "")
    local low = n:lower()
    for _, pair in ipairs(LIVERY_DESIGN) do
        if low:find(pair[1], 1, true) then return DESIGNS[pair[2]], pair[2] end
    end
    local best, bestLen = nil, 0
    for model, id in pairs(MODEL_DESIGN) do
        if n:sub(1, #model) == model and #model > bestLen then best, bestLen = id, #model end
    end
    best = best or "nyala"
    return DESIGNS[best], best
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
    return s:upper()
end

-- Badge wording follows the locked mockups: oval/stamped badges carry the MAKE and the model goes
-- on the cluster face (or the stamped sub line); script badges carry the MODEL; stencil badges are
-- fleet markings with a unit number; chrome/decal badges carry the full name. Returns
-- label, sub, clusterBrand.
local function _badgeFor(design, vehicle, scriptName)
    local full = _brandName(vehicle, scriptName)
    local base = full:gsub("^.*POLICE%s+", "")                 -- "MULDRAUGH POLICE CHEVALIER NYALA" -> "CHEVALIER NYALA"
    local make, model = base:match("^(%S+)%s+(.+)$")
    if not make then make, model = base, nil end
    local kind = design.badge
    if kind == "oval" then return make, design.sub, base end
    if kind == "script" then return model or base, design.sub, model or base end
    if kind == "stamped" then return make, model or design.sub, make end
    if kind == "stencil" then
        local id = 0; pcall(function() id = vehicle:getId() or 0 end)   -- (_safe is declared further down)
        local fleet = full:find("POLICE") and "POLICE" or make
        local unit = (fleet == "TAXI") and "CAB" or ((fleet == "FIRE") and "ENGINE" or "UNIT")
        -- Kahlua strings are Java strings: char 183 IS the middle dot (no UTF-8 byte pairs)
        return fleet .. " " .. string.char(183) .. " " .. unit .. " " .. string.format("%02d", 10 + (id % 90)), design.sub, base
    end
    return full, design.sub, design.brand or base                  -- chrome, decal
end

-- ---------------------------------------------------------------------------
-- Vehicle state (per frame, every read guarded)
-- ---------------------------------------------------------------------------
local function _safe(fn, default) local ok, v = pcall(fn); if ok then return v end; return default end

local function _state(vehicle, chr)
    local st = {}
    st.running  = _safe(function() return vehicle:isEngineRunning() end, false)
    st.started  = _safe(function() return vehicle:isEngineStarted() end, false)
    st.keysIn   = _safe(function() return vehicle:isKeysInIgnition() end, false)
    st.hotwired = _safe(function() return vehicle:isHotwired() end, false)
    st.hasKey   = _safe(function() return chr:getInventory():haveThisKeyId(vehicle:getKeyId()) ~= nil end, false)
    st.speed    = math.floor(math.abs(_safe(function() return vehicle:getCurrentSpeedKmHour() end, 0)) + 0.5)
    st.rpm      = st.running and _safe(function() return vehicle:getEngineSpeed() end, 0) or 0
    st.gear     = st.running and _safe(function() return tostring(vehicle:getTransmissionNumberLetter()) end, "D") or "P"
    local live  = st.running or st.keysIn
    st.fuel = nil
    local tank = _safe(function() return vehicle:getPartById("GasTank") end, nil)
    if live and tank and _safe(function() return tank:isContainer() end, false) then
        st.fuel = _safe(function() return tank:getContainerContentAmount() / math.max(1, tank:getContainerCapacity()) end, nil)
    end
    st.battery  = live and _safe(function() return vehicle:getBatteryCharge() end, nil) or nil
    st.fuelLow  = st.fuel ~= nil and st.fuel < 0.15
    st.battLow  = st.battery ~= nil and st.battery < 0.2
    st.engineCond = _safe(function() return vehicle:getPartById("Engine"):getCondition() end, 100)
    st.engWarn  = st.engineCond < 40
    st.lights   = _safe(function() return vehicle:getHeadlightsOn() end, false)
    st.lightsOk = _safe(function() return vehicle:getHeadlightCanEmmitLight() end, true)
    st.allLocked = _safe(function() return vehicle:areAllDoorsLocked() end, false)
    st.anyLocked = _safe(function() return vehicle:isAnyDoorLocked() end, false)
    st.hasTrunk  = _safe(function() return vehicle:getPartById("TruckBed") ~= nil end, false)
    st.trunkLocked = _safe(function() return vehicle:isTrunkLocked() end, false)
    local heater = _safe(function() return vehicle:getPartById("Heater") end, nil)
    st.hasHeater = heater ~= nil
    st.heaterOn  = heater and _safe(function() return heater:getModData().active == true end, false) or false
    st.heaterTemp = heater and _safe(function() return tonumber(heater:getModData().temperature) or 0 end, 0) or 0  -- -25..25 (vanilla knob)
    -- PZ keeps ONE heater number (-25..25): its sign is the side (A/C or heat), its magnitude the blower
    local mag = math.abs(st.heaterTemp)
    st.fan = (not st.heaterOn) and 0 or (mag >= 21 and 3 or (mag >= 12 and 2 or 1))
    st.ac = st.heaterOn and st.heaterTemp < 0
    local radio  = _safe(function() return vehicle:getPartById("Radio") end, nil)
    st.radioPart = radio
    st.radioItem = radio and _safe(function() return radio:getInventoryItem() end, nil) or nil
    st.hasRadio  = st.radioItem ~= nil
    local dd = st.hasRadio and _safe(function() return radio:getDeviceData() end, nil) or nil
    st.dd = dd
    st.radioOn   = dd and _safe(function() return dd:getIsTurnedOn() end, false) or false
    st.channel   = dd and _safe(function() return dd:getChannel() end, 0) or 0
    st.volume    = dd and _safe(function() return dd:getDeviceVolume() end, 0.5) or 0.5
    st.radioKind = "none"
    if st.radioItem then
        local ft = _safe(function() return st.radioItem:getFullType() end, "")
        st.radioKind = ft:find("MakeShift") and "makeshift" or "native"
    end
    st.cruise    = _safe(function() return vehicle:isRegulator() end, false)
    st.cruiseSpeed = _safe(function() return vehicle:getRegulatorSpeed() end, 0)
    st.hasLightbar  = _safe(function() return vehicle:hasLightbar() end, false)
    st.lightbarMode = st.hasLightbar and _safe(function() return vehicle:getLightbarLightsMode() end, 0) or 0
    st.sirenMode    = st.hasLightbar and _safe(function() return vehicle:getLightbarSirenMode() end, 0) or 0
    return st
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
-- radio (device data on the vehicle's Radio part)
local MINHZ, MAXHZ, STEP = 88000, 108000, 100
local function _chanName(hz)
    local zr = getZomboidRadio and getZomboidRadio()
    if zr and zr.getChannelName then local n = _safe(function() return zr:getChannelName(hz) end, nil); if n and n ~= "" and not tostring(n):upper():find("UNKNOWN") then return tostring(n) end end
    return nil
end
ACT.pwr  = function(chr, v, st) if st.dd then pcall(function() getSoundManager():playUISound("VehicleRadioButton") end); st.dd:setIsTurnedOn(not st.dd:getIsTurnedOn()) end end
ACT.vol  = function(chr, v, st, secondary) if st.dd then local cur = st.dd:getDeviceVolume() or 0.5; local nv = secondary and (cur - 0.1) or (cur + 0.1); if nv > 1.001 then nv = 0 end; if nv < 0 then nv = 1 end; st.dd:setDeviceVolume(nv) end end
ACT.tune = function(chr, v, st, secondary) if st.dd then local cur = st.dd:getChannel() or MINHZ; local nv = cur + (secondary and -STEP or STEP); if nv > MAXHZ then nv = MINHZ end; if nv < MINHZ then nv = MAXHZ end; st.dd:setChannel(nv) end end
ACT.seek = function(chr, v, st, secondary)
    if not st.dd then return end
    local cur = st.dd:getChannel() or MINHZ
    for i = 1, 200 do
        cur = cur + (secondary and -STEP or STEP)
        if cur > MAXHZ then cur = MINHZ end
        if cur < MINHZ then cur = MAXHZ end
        if _chanName(cur) then st.dd:setChannel(cur); return end
    end
end
ACT.scan = ACT.seek
ACT.band = function() end
ACT.set  = function() end
local function _presets(v) local md = v:getModData(); md.zedPresets = md.zedPresets or {}; return md.zedPresets end
for i = 1, 6 do
    ACT["preset" .. i] = function(chr, v, st, secondary)
        if not st.dd then return end
        local ps = _presets(v)
        if secondary or not ps[i] then ps[i] = st.dd:getChannel(); pcall(function() getSoundManager():playUISound("VehicleRadioButton") end); return end
        st.dd:setChannel(ps[i])
    end
end

-- Prompt labels for the gamepad strip
local function _promptFor(id, st)
    if id == "ignition" then if st.running then return "Shut off" elseif st.keysIn or st.hotwired then return "Start" elseif st.hasKey then return "Insert key" else return "No key" end end
    if id == "lights" then return st.lights and "Lights off" or "Lights on" end
    if id == "lock" then return st.anyLocked and "Unlock" or "Lock" end
    if id == "trunk" then return st.trunkLocked and "Unlock trunk" or "Lock trunk" end
    if id == "cruise" then return st.cruise and "Cruise off" or "Cruise set" end
    if id == "heat" then return st.heaterOn and "Heater off" or "Heater on" end
    if id == "ac" then return st.ac and "A/C off" or "A/C" end
    if id == "pwr" then return st.radioOn and "Radio off" or "Radio on" end
    if id == "vol" then return "Volume +" end
    if id == "tune" then return "Tune +" end
    if id == "seek" or id == "scan" then return "Seek" end
    if id:sub(1, 6) == "preset" then return "Preset" end
    if id == "temp" or id == "tempup" then return "Warmer" end
    if id == "tempdn" then return "Cooler" end
    if id == "fan" or id == "fanup" then return "Fan +" end
    if id == "fandn" then return "Fan -" end
    if id == "lbar" then return "Lightbar" end
    if id == "siren" then return "Siren" end
    if id == "def" then return "Defrost" end
    if id == "off" then return "Climate off" end
    return "Press"
end
local SECONDARY = { ignition = "Remove key", vol = "Volume -", tune = "Tune -", temp = "Cooler", fan = "Fan -", seek = "Seek back", scan = "Seek back",
    preset1 = "Store", preset2 = "Store", preset3 = "Store", preset4 = "Store", preset5 = "Store", preset6 = "Store" }

-- ---------------------------------------------------------------------------
-- The organism
-- ---------------------------------------------------------------------------
ZeD_Dashboard = ZeD_Panel:derive("ZeD_Dashboard")

local _texCache = {}
local function tex(path) local t = _texCache[path]; if t == nil then t = getTexture(path) or false; _texCache[path] = t end; return t or nil end

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
    o._focusIdx  = 1
    o._s = 1
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor     = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

function ZeD_Dashboard:_scale() local Sc = ZeD.Scale; return ((Sc and Sc.root and Sc.root()) or 1) * (D.scale or 1) end   -- S124: root scale (1080p = 1.0)

function ZeD_Dashboard:_layout()
    local s = self:_scale()
    local w, h = math.floor(BASE_W * s), math.floor(BASE_H * s)
    local pn = self.playerNum
    local x = getPlayerScreenLeft(pn) + math.floor((getPlayerScreenWidth(pn) - w) / 2)
    local y = getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) - h - math.floor(6 * s)
    if self:getWidth() ~= w then self:setWidth(w) end
    if self:getHeight() ~= h then self:setHeight(h) end
    if self:getX() ~= x then self:setX(x) end
    if self:getY() ~= y then self:setY(y) end
    return w, h, s
end

-- ---- primitive overlays (dash-local 1x units, scaled by s) ----
function ZeD_Dashboard:_plate(name, x, y, w, h, tint, alpha)
    local t = tex(TEXDIR .. name .. ".png"); if not t then return false end
    local s = self._s
    local c = tint or { r = 1, g = 1, b = 1 }
    self:drawTextureScaledAspect(t, math.floor(x * s), math.floor(y * s), math.floor(w * s), math.floor(h * s), alpha or 1, c.r, c.g, c.b)
    return true
end
function ZeD_Dashboard:_rect(x, y, w, h, c, a)
    local s = self._s; c = col(c)
    self:drawRect(math.floor(x * s), math.floor(y * s), math.max(1, math.floor(w * s)), math.max(1, math.floor(h * s)), a or c.a or 1, c.r, c.g, c.b)
end
-- rect run from (cx,cy) along angle deg (0 = 12 o'clock, clockwise), radii r0..r1 in 1x units
function ZeD_Dashboard:_run(cx, cy, deg, r0, r1, c, thick)
    local s = self._s; c = col(c)
    local a = (deg - 90) * math.pi / 180
    local ca, sa = math.cos(a), math.sin(a)
    local t = math.max(1, math.floor((thick or 2) * s))
    local step = 1 / s
    local r = r0
    while r <= r1 do
        self:drawRect(math.floor((cx + ca * r) * s - t / 2), math.floor((cy + sa * r) * s - t / 2), t, t, c.a or 1, c.r, c.g, c.b)
        r = r + step
    end
end
local function fontFor(size, big)
    local F = ZeD.Font.sdf   -- S124: distance-field roles (crisp at any root scale)
    if big or (size or 5) >= 11 then return F.head end
    if (size or 5) >= 7 then return F.stat end
    return F.title
end
-- width of a string in BASE px (unscaled) for the font that `size` maps to
function ZeD_Dashboard:_measure(str, size, big)
    local f = fontFor(size, big)
    return ZeD.Text.width(f, str, ZeD.Text.zoomFor(f, f.px))   -- base units (design px at root 1)
end
-- trim a label to fit maxW base px: whole words first, then characters, with a trailing dot
function ZeD_Dashboard:_fit(str, size, maxW, big)
    str = tostring(str or "")
    if maxW == nil or maxW <= 0 or self:_measure(str, size, big) <= maxW then return str end
    local t = str
    while t:find("%s") and self:_measure(t, size, big) > maxW do t = (t:gsub("%s+%S*$", "")) end
    if self:_measure(t, size, big) <= maxW then return t end   -- whole words dropped: no ellipsis dot
    while #t > 1 and self:_measure(t .. ".", size, big) > maxW do t = t:sub(1, -2) end
    return t .. "."
end
function ZeD_Dashboard:_text(x, y, str, size, c, align, big)
    str = tostring(str)   -- anchors carry numeric labels (preset 1..6); MeasureStringX wants a String
    local s = self._s; c = col(c); local fe = fontFor(size, big); local f = ZeD.Text.uifont(fe)
    local z = ZeD.Text.zoomFor(fe, fe.px * s)                                   -- role design px x root scale
    local tm = getTextManager(); local w = tm:MeasureStringX(f, str) * z      -- screen px at zoom z
    local px = x * s
    if align == "r" then px = px - w elseif align == "c" then px = px - w / 2 end
    local h = tm:getFontHeight(f) * z; local py = y * s - math.max(0, (h - (size or 5) * s) / 2)
    self:drawTextZoomed(str, math.floor(px), math.floor(py), z, c.r, c.g, c.b, c.a or 1, f)   -- S124: glyphs follow the root scale
end
function ZeD_Dashboard:_needle(an, val, max, color)
    if val == nil then val = 0 end
    local deg = an.deg0 + an.sweep * math.max(0, math.min(1, val / (max or an.max)))
    self:_run(an.cx, an.cy, deg, an.r0, an.r1, color or "#E07A2A", an.thick or 2)
end
function ZeD_Dashboard:_segarc(an, val)
    if val == nil then return end
    local k = math.floor(math.min(1, val / an.max) * an.n + 0.5)
    for i = 0, k - 1 do
        local d = an.degA + (an.degB - an.degA) * i / (an.n - 1)
        local len = 5 + math.floor(i * 6 / an.n + 0.5)
        local c = an.on
        if an.redFrom and i >= an.redFrom then c = an.red elseif an.warnFrom and i >= an.warnFrom then c = an.warn end
        self:_run(an.cx, an.cy, d, an.r - len, an.r, c, 2)
    end
end
function ZeD_Dashboard:_ladder(an, val, warn)
    if val == nil then return end
    local k = math.floor(math.min(1, math.max(0, val)) * an.n + 0.5)
    for i = 0, k - 1 do self:_rect(an.x, an.yBottom - (i + 1) * an.pitch, an.w, an.h, warn and an.warn or an.on) end
end
function ZeD_Dashboard:_bars(an, val)
    if val == nil then return end
    local k = math.floor(math.min(1, val / an.max) * an.n + 0.5)
    for i = 0, k - 1 do
        local h = an.h0 + math.floor(i * an.dh + 0.5)
        local c = an.on
        if an.redFrom and i >= an.redFrom then c = an.red elseif an.warnFrom and i >= an.warnFrom then c = an.warn end
        self:_rect(an.x + i * an.pitch, an.yBase - h, an.w, h, c)
    end
end
local GEARS = { "P", "R", "N", "D", "2", "1" }
function ZeD_Dashboard:_prndl(an, gear)
    for i, g in ipairs(GEARS) do
        if g == gear then
            local gx = an.x + (i - 1) * an.pitch
            if an.box then self:_rect(gx + an.box.dx, an.y + an.box.dy, an.box.w, an.box.h, an.box.c) end
            self:_text(gx, an.y, g, an.size, an.color, "c")
        end
    end
end
local LAMP_ICON = { door = "door-closed", lamp = "lightbulb-on", batt = "car-battery", fuel = "fuel-gauge", eng = "engine", radio = "fm-radio", cruise = "fi-br-gauge-circle-bolt", lbar = "siren-on", siren = "essential-collection-213-alarm", lock = "fi-br-lock" }
function ZeD_Dashboard:_lamp(an, kind, lit, c)
    local s = self._s; c = col(c)
    local alpha = lit and 1 or 0.10
    if kind == "key" then   -- rect-drawn key glyph (no key icon in the set yet)
        local x, y = an.x, an.y
        self:_rect(x + 2, y + 3, 6, 6, c, alpha); self:_rect(x + 4, y + 5, 2, 2, "#000000", lit and 1 or 0.10)
        self:_rect(x + 8, y + 5, 8, 2, c, alpha); self:_rect(x + 13, y + 7, 1, 2, c, alpha); self:_rect(x + 10, y + 7, 1, 2, c, alpha)
        return
    end
    local t = tex(ICONDIR .. (LAMP_ICON[kind] or "engine") .. ".png"); if not t then return end
    self:drawTextureScaledAspect(t, math.floor(an.x * s), math.floor(an.y * s), math.floor(16 * s), math.floor(14 * s), alpha, c.r, c.g, c.b)
end
function ZeD_Dashboard:_knobPointer(an, deg)
    self:_run(an.cx, an.cy, deg, an.r - 7, an.r - 2, an.ptr or "#dddddd", 2)
end
function ZeD_Dashboard:_focusCue(x, y, w, h)
    local T = ZeD.T; local ac = T.accent
    self:_rect(x, y, w, h, { r = ac.r, g = ac.g, b = ac.b, a = 0.55 }, 0.55)
end

-- register a control: hit rect for the mouse, focus element for the pad (driver only)
function ZeD_Dashboard:_control(id, x, y, w, h, st, enabled)
    if not self._driver then return end
    local s = self._s
    local hr = { id = id, x = math.floor(x * s), y = math.floor(y * s), w = math.floor(w * s), h = math.floor(h * s), enabled = enabled ~= false }
    self._hit[#self._hit + 1] = hr
    if hr.enabled then
        local focused = self._focEl and self._focEl.id == "dash:" .. id
        if focused then self:_focusCue(x, y, w, h) end
        self._elements[#self._elements + 1] = {
            x = hr.x, y = hr.y, w = hr.w, h = hr.h, id = "dash:" .. id,
            promptA = _promptFor(id, st), promptX = SECONDARY[id], promptB = "Drive",
            onActivate = function(win, el) win:_fire(id, false) end,
            onContextMenu = function(win, el) if SECONDARY[id] then win:_fire(id, true) end end,
            onCancel = function(win, el) win:_release() end,
        }
    end
end

-- ---- cluster overlay ----
local function off(an, ox, oy)
    local o = {}
    for k, v in pairs(an) do o[k] = v end
    if an.cx then o.cx = an.cx + ox; o.cy = an.cy + oy end
    if an.x then o.x = an.x + ox end
    if an.y then o.y = an.y + oy end
    if an.yBottom then o.yBottom = an.yBottom + oy end
    if an.yBase then o.yBase = an.yBase + oy end
    return o
end
function ZeD_Dashboard:_drawCluster(design, st, ox, oy, A)
    local needle = design.needle or "#E07A2A"
    local live = st.running or st.keysIn or st.hotwired
    if design.style == "analog" then
        if A.fuel then self:_needle(off(A.fuel, ox, oy), st.fuel, 1, st.fuelLow and "#FF5A4A" or needle) end
        if A.speed then self:_needle(off(A.speed, ox, oy), st.speed, 200, needle) end
        if A.tach then self:_needle(off(A.tach, ox, oy), st.rpm, 8000, needle) end
        if A.batt then self:_needle(off(A.batt, ox, oy), st.battery, 1, st.battLow and "#FF5A4A" or needle) end
    else
        if A.speedArc then self:_segarc(off(A.speedArc, ox, oy), live and st.speed or nil) end
        if A.tachArc then self:_segarc(off(A.tachArc, ox, oy), st.running and st.rpm or nil) end
        if A.speedDigits then local an = off(A.speedDigits, ox, oy); self:_text(an.x, an.y, live and tostring(st.speed) or "---", 20, an.color, an.align, true) end
        if A.rpmDigits then local an = off(A.rpmDigits, ox, oy); self:_text(an.x, an.y, st.running and tostring(math.floor(st.rpm / 100 + 0.5)) or "--", 20, an.color, an.align, true) end
        if A.speedArcDigits then local an = off(A.speedArcDigits, ox, oy); self:_text(an.x, an.y, live and tostring(st.speed) or "---", 16, an.color, an.align, true) end
        if A.tachArcDigits then local an = off(A.tachArcDigits, ox, oy); self:_text(an.x, an.y, st.running and tostring(math.floor(st.rpm + 0.5)) or "---", 16, an.color, an.align, true) end
        if A.fuelLadder then self:_ladder(off(A.fuelLadder, ox, oy), st.fuel, st.fuelLow) end
        if A.battLadder then self:_ladder(off(A.battLadder, ox, oy), st.battery, st.battLow) end
        if A.tachBars then self:_bars(off(A.tachBars, ox, oy), st.running and st.rpm or nil) end
        if A.cruiseText and st.cruise then local an = off(A.cruiseText, ox, oy); self:_text(an.x, an.y, "CRUISE " .. tostring(math.floor(st.cruiseSpeed + 0.5)), 4, an.color, an.align) end
    end
    if A.prndl then self:_prndl(off(A.prndl, ox, oy), st.gear) end
    local noKey = (not st.hasKey) and (not st.keysIn) and (not st.hotwired)
    local lamps = {
        { "key", st.keysIn or noKey, noKey and "#FF5A4A" or "#44EE44" }, { "door", false, "#FFB347" }, { "lamp", st.lights, st.lightsOk and "#5AA0FF" or "#FF5A4A" },
        { "batt", st.battLow, "#FF5A4A" }, { "fuel", st.fuelLow, "#FFB347" }, { "eng", st.engWarn and st.running, "#FF5A4A" },
        { "radio", st.radioOn, "#44EE44" }, { "cruise", st.cruise, "#44EE44" },
    }
    if st.hasLightbar then lamps[#lamps + 1] = { "lbar", st.lightbarMode > 0, "#5AA0FF" }; lamps[#lamps + 1] = { "siren", st.sirenMode > 0, "#FFB347" } end
    for i, l in ipairs(lamps) do local an = A["lamp" .. (i - 1)]; if an then self:_lamp({ x = an.x + ox, y = an.y + oy }, l[1], l[2], l[3]) end end
    local brand = design.brand or self._clusterBrand
    if A.brand and brand then local an = off(A.brand, ox, oy); self:_text(an.x, an.y, self:_fit(brand, an.size, 220), an.size, an.color, an.align) end
end

-- ---- switch row overlay ----
function ZeD_Dashboard:_drawSwitches(st, ox, oy)
    local A = PL.switches; if not A then return end
    local kn = A.lights; self:_knobPointer({ cx = kn.cx + ox, cy = kn.cy + oy, r = kn.r, ptr = kn.ptr }, st.lights and 40 or -40)
    self:_control("lights", kn.cx - kn.r + ox, kn.cy - kn.r + oy, kn.r * 2, kn.r * 2, st)
    local ig = A.ignition; local ix, iy = ig.cx + ox, ig.cy + oy
    self:_rect(ix - 1, iy - 6, 2, 12, (st.keysIn or st.hotwired) and "#d8d8d8" or "#222222")
    if st.keysIn then self:_rect(ix - 3, iy + 6, 6, 3, "#d8d8d8") end
    local noKey = (not st.hasKey) and (not st.keysIn) and (not st.hotwired)
    if st.running then self:_rect(ig.led.x + ox, ig.led.y + oy, 3, 3, "#44EE44") elseif noKey then self:_rect(ig.led.x + ox, ig.led.y + oy, 3, 3, "#FF5A4A") end
    self:_control("ignition", ix - ig.r, iy - ig.r, ig.r * 2, ig.r * 2, st, not noKey or st.running)
    local lk = A.lock
    self:_rect(lk.top.x + ox, lk.top.y + oy, lk.top.w, lk.top.h, st.anyLocked and "#1a1a1a" or "#2e2e2e")
    self:_rect(lk.bot.x + ox, lk.bot.y + oy, lk.bot.w, lk.bot.h, st.anyLocked and "#2e2e2e" or "#1a1a1a")
    self:_lamp({ x = lk.lamp.x + ox, y = lk.lamp.y + oy }, "lock", st.anyLocked, "#44EE44")
    self:_control("lock", lk.x + ox, lk.y + oy, lk.w, lk.h, st)
    local tr = A.trunk; self:_control("trunk", tr.x + ox, tr.y + oy, tr.w, tr.h, st, st.hasTrunk)
    local cr = A.cruise; if st.cruise and cr.led then self:_rect(cr.led.x + ox, cr.led.y + oy, 4, 4, cr.led.c) end
    self:_control("cruise", cr.x + ox, cr.y + oy, cr.w, cr.h, st, st.running)
end

-- ---- console overlay ----
local function clamp01(v) return math.max(0, math.min(1, v or 0)) end
function ZeD_Dashboard:_drawHeadUnit(A, st, ox, oy)
    local on = st.radioOn
    local dsp = A.display
    if dsp then
        local freq = string.format("%.1f", (st.channel or 0) / 1000)
        local name = on and (_chanName(st.channel) or "") or ""
        if dsp.kind == "delco" then
            if on then self:_text(dsp.freq.x + ox, dsp.freq.y + oy, freq, 11, dsp.color, "r"); self:_text(dsp.station.x + ox, dsp.station.y + oy, self:_fit(name:upper(), 4, dsp.freq.x - dsp.station.x - self:_measure(freq, 11) - 6), 4, dsp.color, "l"); self:_rect(dsp.stereo.x + ox, dsp.stereo.y + oy, 3, 3, dsp.color); self:_text(dsp.stereo.tx + ox, dsp.stereo.ty + oy, "ST", 3, dsp.color, "l") end
        elseif dsp.kind == "sony" then
            if on then self:_text(dsp.freq.x + ox, dsp.freq.y + oy, "FM " .. freq, 7, dsp.color, "l"); self:_text(dsp.station.x + ox, dsp.station.y + oy, self:_fit(name:upper(), 4, dsp.station.x - dsp.freq.x - self:_measure("FM " .. freq, 7) - 6), 4, dsp.color, "r") end
        elseif dsp.kind == "kenwood" then
            if on then self:_text(dsp.freq.x + ox, dsp.freq.y + oy, freq, 14, dsp.color, "l", true); self:_text(dsp.fm.x + ox, dsp.fm.y + oy, "FM", 5, dsp.color, "l"); self:_text(dsp.st.x + ox, dsp.st.y + oy, "ST", 5, dsp.color, "l") end
        elseif dsp.kind == "dial" then
            if on then self:_rect(dsp.x + ox, dsp.y + oy, dsp.w, dsp.h, dsp.litBg, 0.85) end
            local sc = dsp.scale; local f = math.max(88, math.min(108, (st.channel or 88000) / 1000)); local nx = sc.x + math.floor(sc.w * (f - 88) / 20 + 0.5)
            self:_rect(nx + ox, sc.y + oy, 1, sc.h, "#D02020")
            if on then self:_rect(dsp.stereo.x + ox, dsp.stereo.y + oy, 3, 3, "#44EE44"); self:_text(dsp.stereo.tx + ox, dsp.stereo.ty + oy, "STEREO", 3, "#aaaaaa", "l") end
        elseif dsp.kind == "makeshift" then
            self:_text(dsp.x + dsp.w / 2 + ox, dsp.y + 4 + oy, on and freq or "---.-", 8, dsp.color, "c")
        end
    end
    if A.signal and on then local sg = A.signal; for i = 0, 4 do local c = (i < 4) and "#44EE44" or "#FFB347"; self:_rect(sg.x + i * sg.pitch + ox, sg.y + oy, sg.w, sg.h, c) end end
    if A.vol then local kn = A.vol; self:_knobPointer({ cx = kn.cx + ox, cy = kn.cy + oy, r = kn.r, ptr = kn.ptr }, -120 + 240 * clamp01(st.volume)); self:_control("vol", kn.cx - kn.r + ox, kn.cy - kn.r + oy, kn.r * 2, kn.r * 2, st, st.hasRadio) end
    if A.tune then local kn = A.tune; self:_knobPointer({ cx = kn.cx + ox, cy = kn.cy + oy, r = kn.r, ptr = kn.ptr }, -120 + 240 * clamp01(((st.channel or MINHZ) - MINHZ) / (MAXHZ - MINHZ))); self:_control("tune", kn.cx - kn.r + ox, kn.cy - kn.r + oy, kn.r * 2, kn.r * 2, st, st.hasRadio) end
    local ps = self.vehicle and _presets(self.vehicle) or {}
    for _, id in ipairs({ "pwr", "scan", "seek", "band", "set", "preset1", "preset2", "preset3", "preset4", "preset5", "preset6" }) do
        local b = A[id]
        if b then
            local pn = tonumber(id:sub(7))
            local lit = (id == "pwr" and on) or (pn ~= nil and ps[pn] ~= nil and st.channel == ps[pn])
            if b.led and lit then self:_rect(b.led.x + ox, b.led.y + oy, 4, 4, b.led.c) end
            if b.litText and lit then
                -- repaint the button face first: the plate prints the label as 4 px silkscreen and the lit
                -- label is a 9 px F5 glyph, so the two would ghost against each other (S124)
                if b.face then self:_rect(b.x + 1 + ox, b.y + 1 + oy, b.w - 2, b.h - 2, b.face) end
                self:_text(b.litText.x + ox, b.litText.y + oy, b.litText.lab, 4, b.litText.c, "c")
            end
            if id == "pwr" and lit and not b.led and not b.litText then self:_rect(b.x + 2 + ox, b.y + 2 + oy, 3, 3, "#FF3A2A") end
            self:_control(id, b.x + ox, b.y + oy, b.w, b.h, st, st.hasRadio and id ~= "band" and id ~= "set")
        end
    end
end
function ZeD_Dashboard:_drawConsole(design, st, ox, oy)
    local A = PL["console_" .. design.console]; if not A then return end
    local hu = A.headUnitArea
    if st.radioKind == "native" then
        self:_drawHeadUnit(A, st, ox, oy)
    elseif hu then
        local plate = (st.radioKind == "makeshift") and "headunit_makeshift" or "headunit_none"
        self:_plate(plate, ox + hu.x, oy + hu.y, hu.w, 52)
        if st.radioKind == "makeshift" and PL.headunit_makeshift then self:_drawHeadUnit(PL.headunit_makeshift, st, ox + hu.x, oy + hu.y) end
    end
    -- climate
    local tC = math.floor(21 + (st.heaterTemp or 0) * 0.28 + 0.5)
    if A.climateDisplay then
        local cd = A.climateDisplay
        if design.console == "luxury" then
            self:_text(cd.temp.x + ox, cd.temp.y + oy, tostring(tC) .. "C", 11, cd.color, "l")
            self:_text(cd.mode.x + ox, cd.mode.y + oy, st.heaterOn and (st.ac and "A/C" or "AUTO") or "OFF", 5, cd.color, "l")
            self:_text(cd.fan.x + ox, cd.fan.y + oy, "FAN " .. tostring(st.fan), 5, cd.color, "l")
        else
            self:_text(cd.temp.x + ox, cd.temp.y + oy, tostring(tC), 11, cd.color, "l")
            self:_text(cd.fanLabel.x + ox, cd.fanLabel.y + oy, "FAN", 4, cd.color, "l")
            self:_text(cd.fan.x + ox, cd.fan.y + oy, tostring(st.fan), 7, cd.color, "l")
        end
    end
    local tempF = clamp01(((st.heaterTemp or 0) + 25) / 50)
    local fanF = (st.fan or 0) / 3
    for _, id in ipairs({ "temp", "fan", "heat" }) do
        local an = A[id]
        if an then
            local v = (id == "temp") and tempF or ((id == "fan") and fanF or (st.heaterOn and 1 or 0))
            if an.t == "knob" then
                local deg = (id == "temp") and ((v * 2 - 1) * 120) or ((id == "fan") and (240 + 80 * (st.fan or 0)) or (st.heaterOn and 60 or -60))
                self:_knobPointer({ cx = an.cx + ox, cy = an.cy + oy, r = an.r, ptr = an.ptr }, deg)
                self:_control(id, an.cx - an.r + ox, an.cy - an.r + oy, an.r * 2, an.r * 2, st, st.hasHeater)
            elseif an.t == "slider" then
                local kx = an.x + math.floor((an.w - 8) * v + 0.5)
                self:_rect(kx + ox, an.y + oy, 8, 10, "#3a3a3a"); self:_rect(kx + ox, an.y + oy, 8, 1, "#6a6a6a"); self:_rect(kx + 3 + ox, an.y + 2 + oy, 2, 6, "#1a1a1a")
                self:_control(id, an.x + ox, an.y - 2 + oy, an.w, 14, st, st.hasHeater)
            elseif an.t == "lever" then
                local ky = an.y + math.floor((an.h - 8) * (1 - v) + 0.5)
                self:_rect(an.x - 2 + ox, ky + oy, 14, 8, "#9a9a9a"); self:_rect(an.x - 2 + ox, ky + oy, 14, 1, "#e0e0e0"); self:_rect(an.x + 2 + ox, ky + 3 + oy, 6, 2, "#3a3a3a")
                self:_control(id, an.x - 4 + ox, an.y - 2 + oy, 18, an.h + 4, st, st.hasHeater)
            elseif an.t == "btn" then
                if an.led and id == "heat" and st.heaterOn and not st.ac then self:_rect(an.led.x + ox, an.led.y + oy, an.led.s or 4, an.led.s or 4, an.led.c) end
                self:_control(id, an.x + ox, an.y + oy, an.w, an.h, st, st.hasHeater)
            end
        end
    end
    for _, id in ipairs({ "ac", "tempup", "tempdn", "fanup", "fandn", "def", "off", "mode" }) do
        local b = A[id]
        if b then
            if b.led and id == "ac" and st.ac then self:_rect(b.led.x + ox, b.led.y + oy, b.led.s or 4, b.led.s or 4, b.led.c) end
            self:_control(id, b.x + ox, b.y + oy, b.w, b.h, st, st.hasHeater and id ~= "mode")
        end
    end
    if A.lbar then
        local kn = A.lbar; self:_knobPointer({ cx = kn.cx + ox, cy = kn.cy + oy, r = kn.r, ptr = kn.ptr }, -60 + st.lightbarMode * 40); self:_control("lbar", kn.cx - kn.r + ox, kn.cy - kn.r + oy, kn.r * 2, kn.r * 2, st, st.hasLightbar)
        kn = A.siren; self:_knobPointer({ cx = kn.cx + ox, cy = kn.cy + oy, r = kn.r, ptr = kn.ptr }, -60 + st.sirenMode * 40); self:_control("siren", kn.cx - kn.r + ox, kn.cy - kn.r + oy, kn.r * 2, kn.r * 2, st, st.hasLightbar)
        if st.sirenMode > 0 and A.sirenLed then self:_rect(A.sirenLed.x + ox, A.sirenLed.y + oy, 3, 3, A.sirenLed.c) end
        if st.lightbarMode > 0 and A.lbarLed then self:_rect(A.lbarLed.x + ox, A.lbarLed.y + oy, 3, 3, A.lbarLed.c) end
    end
end

-- ---- badge overlay ----
local BADGE_MAXW = { chrome = 126, oval = 116, decal = 126, stencil = 126, stamped = 88, script = 100 }
function ZeD_Dashboard:_drawBadge(design, ox, oy, label, sub)
    local A = PL["badge_" .. design.badge]; if not A then return end
    local t = A.text
    label = self:_fit(label, t.size, BADGE_MAXW[design.badge] or 120)
    if t.t == "emboss" then
        self:_text(t.x + 1 + ox, t.y + 1 + oy, label, t.size, t.dark, t.align); self:_text(t.x + ox, t.y + oy, label, t.size, t.light, t.align)
    else
        self:_text(t.x + ox, t.y + oy, label, t.size, t.color, t.align)
    end
    if A.sub and sub then self:_text(A.sub.x + ox, A.sub.y + oy, sub, A.sub.size, A.sub.color, A.sub.align) end
end

-- ---------------------------------------------------------------------------
-- prerender: compose plates + overlays, rebuild hits and focus elements
-- ---------------------------------------------------------------------------
function ZeD_Dashboard:prerender()
    local chr = getSpecificPlayer(self.playerNum)
    local vehicle = chr and chr:getVehicle()
    if not chr or not vehicle or (ISUIHandler and ISUIHandler.allUIVisible == false) then self:setVisible(false); return end
    self.vehicle = vehicle
    local vd = getPlayerVehicleDashboard and getPlayerVehicleDashboard(self.playerNum)
    if vd and vd.isVisible and vd:isVisible() then pcall(vd.setVisible, vd, false) end

    local w, h, s = self:_layout()
    self._s = s
    local st = _state(vehicle, chr)
    self._st = st
    self._driver = _safe(function() return vehicle:isDriver(chr) end, false)
    local scriptName = _safe(function() return tostring(vehicle:getScriptName() or "") end, "")
    local design, designId = _designFor(scriptName)
    self._designId = designId
    self._badgeLabel, self._badgeSub, self._clusterBrand = _badgeFor(design, vehicle, scriptName)
    local Focus = ZeD.Input and ZeD.Input.Focus
    local DetM = ZeD.Input and ZeD.Input.Detector
    local gamepad = DetM and DetM.getMode and DetM.getMode() == "gamepad"
    -- the focus cue is a gamepad affordance: the dash still holds focus for the ring under mouse play, but paints nothing
    self._focEl = (gamepad and Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() == self) and Focus.getFocusedElement(self) or nil
    self._hit = {}; self._elements = {}

    local body = PL["body_" .. design.hood] or PL.body_arch
    local tint = CABINS[design.cabin] or CABINS.slate
    if not self:_plate("body_" .. design.hood, 0, 0, BASE_W, BASE_H, tint) then
        self:_rect(0, 0, BASE_W, BASE_H, "#1a1a1a")   -- plates missing: never let the dash vanish
    end
    local cl, sw, cs, bd = body.cluster, body.switches, body.console, body.badge
    self:_plate("cluster_" .. design.style, cl.x, cl.y, cl.w, cl.h)
    self:_drawCluster(design, st, cl.x, cl.y, PL["cluster_" .. design.style] or {})
    self:_plate("switches", sw.x, sw.y, sw.w, sw.h)
    self:_drawSwitches(st, sw.x, sw.y)
    self:_plate("console_" .. design.console, cs.x, cs.y, cs.w, cs.h)
    self:_drawConsole(design, st, cs.x, cs.y)
    self:_plate("badge_" .. design.badge, bd.x, bd.y, bd.w, bd.h)
    self:_drawBadge(design, bd.x, bd.y, self._badgeLabel, self._badgeSub)
    if not self._driver then self:_text(BASE_W - 10, BASE_H - 12, "PASSENGER", 5, "#8a8a8a", "r") end

    local Det = ZeD.Input and ZeD.Input.Detector
    if Det and Det.getMode and Det.getMode() == "gamepad" and self._driver then
        local pr = PL.switches and PL.switches.prompt
        local hint = self._focEl and ("A " .. (self._focEl.promptA or "Press") .. (self._focEl.promptX and ("  X " .. self._focEl.promptX) or "") .. "  B Drive") or "Dash: re-enter the seat to focus"
        -- the mockup prints the prompt right-aligned to the hood edge (left of the console), not inside the switches plate
        if pr then self:_text(cl.x + cl.w + 10, pr.y + sw.y, hint, pr.size, pr.color, "r") end
    end
    if Focus and Focus.setRingZoneElements then
        local zone = self._focusRing[1]
        local oldEl = zone.elements[zone.focusedElementIdx or 1]
        local keep = nil
        if oldEl then for i, e in ipairs(self._elements) do if e.id == oldEl.id then keep = i; break end end end
        Focus.setRingZoneElements(self, "dashControls", self._elements, keep)
        Focus.setZoneFocusable(self, "dashControls", #self._elements > 0)
    end
end

function ZeD_Dashboard:render() end

function ZeD_Dashboard:_fire(id, secondary)
    local chr = getSpecificPlayer(self.playerNum)
    local v = self.vehicle
    if not chr or not v or not self._driver then return end
    if getGameSpeed() == 0 then return end
    if getGameSpeed() > 1 then setGameSpeed(1) end
    local fn = ACT[id]; if not fn then return end
    local st = self._st or _state(v, chr)
    local ok, err = pcall(fn, chr, v, st, secondary)
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

function ZeD_Dashboard:_claim()
    local Focus = ZeD.Input and ZeD.Input.Focus; if not Focus then return end
    Focus.registerWindow(self)
    if not Focus.getFocusedWindow() then Focus.claimFocus(self) end
end
function ZeD_Dashboard:_release()
    local Focus = ZeD.Input and ZeD.Input.Focus; if not Focus then return end
    if Focus.getFocusedWindow() == self then Focus.releaseFocus() end
end
function ZeD_Dashboard:_unregister()
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
    print("[ZeD] Dashboard: v5 plate dashboard installed (vanilla parked)")
    return inst
end
function D.getInstance() return D._instance end
function D.show(character)
    if not (character and instanceof(character, "IsoPlayer") and character:isLocalPlayer()) then return end
    local inst = D._instance or D.install()
    local pn = character.getPlayerNum and character:getPlayerNum() or 0
    if pn ~= inst.playerNum then return end
    local vehicle = character:getVehicle()
    if vehicle then
        inst.vehicle = vehicle
        inst:setVisible(true)
        if vehicle:isDriver(character) then inst:_claim() else inst:_release(); inst:_unregister() end
    else
        inst:setVisible(false); inst:_release(); inst:_unregister()
    end
end
function D.hide(character)
    local inst = D._instance; if not inst then return end
    if not (character and instanceof(character, "IsoPlayer") and character:isLocalPlayer()) then return end
    local pn = character.getPlayerNum and character:getPlayerNum() or 0
    if pn ~= inst.playerNum then return end
    inst.vehicle = nil
    inst:setVisible(false); inst:_release(); inst:_unregister()
end

Events.OnGameStart.Add(function() D._instance = nil; D.install() end)
Events.OnEnterVehicle.Add(function(character) pcall(D.show, character) end)
Events.OnSwitchVehicleSeat.Add(function(character) pcall(D.show, character) end)
Events.OnExitVehicle.Add(function(character) pcall(D.hide, character) end)
