-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Watch.lua
-- ============================================================================
-- THE WATCH (Oct 16 2026) - a physical wristwatch at the top right, drawn as a
-- pixel-art plate by the shared plate template (ZeD_Plate.lua). It replaces the
-- Java clock AND the Java speed controls.
--
-- Two brands and the expensive one (director's calls, Oct 16 2026):
--   CaZio  digital (black, gold): ALARM and SET keys on the face, SPEED and
--          START metal keys below; the thermometer is its perk.
--          classic (black, gold): hands + a small display; SET, ALARM, SPEED,
--          START pushers, the crown opens the alarm's setting.
--   Timez  digital (red, steel): SET, ALARM, SPEED, START pushers in the case's
--          cut corners and the big INDIGLOW key under the screen.
--          analogue (Easy Reader, Camper): the main crown is the light, the small
--          crown opens the alarm's setting, START and SPEED pushers.
--          The light is Timez's perk: the screen or dial glows for a few seconds.
--   Rollex the expensive one: START and SPEED pushers, the crown opens the alarm's
--          setting; its hands and index dots glow in the dark.
-- At night every watch's screen and dial go faint (still readable); the plate
-- art carries a "dark" picture and its live parts carry night colours.
-- No watch worn: a boom box's tape deck keys set the game speed.
--
-- THE WATCH REGISTRY (for ZeD-UI's own watches and for addons alike):
--   ZeD.Watch.register{
--       plate  = "timez_steel",                      -- the plate's id
--       items  = { "Base.WristWatch_Left_DigitalTimez",
--                  "Base.WristWatch_Right_DigitalTimez" },
--       design = nil,   -- optional: the plate's data table (an addon's own,
--                       -- made with ZeDUI/tools/physpx); default ZeD.PhysPx.plates[plate]
--       texdir = nil,   -- optional: where that plate's pictures live; default ZeD.PhysPx.texdir
--   }
-- A watch's features come from its plate: a thermometer field, a light key,
-- glowing hands are all in the art and data, so registering is just "this item
-- wears this plate". An item nobody registered borrows a CaZio (digital or not).
--
-- The controls every plate may carry (click area ids):
--   speed  steps the game speed 1x 2x 3x     start  pauses / runs
--   alarm  arms or disarms the alarm         set, crown  open / close the alarm's setting
--   light  lights the watch (Timez)          setdn, setup  the alarm hour -1 / +1 while setting
--                                             (one hour past 23 or before 0 is OFF)
--   speed0..speed3  the no-watch tape deck keys
-- ============================================================================

require "ZeD/ZeD_Panel"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"

ZeD = ZeD or {}
ZeD.Watch = ZeD.Watch or {}
local W = ZeD.Watch
W.scale = W.scale or 1.0
W.LIGHT_MS = 3000                  -- how long a Timez stays lit after a press (a real one: about three seconds)
W.watches = W.watches or {}        -- full item type -> its registration
W.fallback = W.fallback or { digital = "digital_black", analog = "classic_black" }

local function _safe(fn, default) local ok, v = pcall(fn); if ok then return v end; return default end

-- ---------------------------------------------------------------------------
-- The registry
-- ---------------------------------------------------------------------------
-- def = { plate = id, items = { full types }, design = data table or nil, texdir = folder or nil }
function W.register(def)
    if type(def) ~= "table" or not def.plate then
        print("[ZeD] Watch.register: a watch needs at least a plate id"); return
    end
    for _, ft in ipairs(def.items or {}) do W.watches[ft] = def end
end

-- ZeD-UI's own watches: vanilla's eight and the steel Timez this mod adds
local function both(name) return { "Base.WristWatch_Left_" .. name, "Base.WristWatch_Right_" .. name } end
W.register { plate = "digital_black", items = both("DigitalBlack") }
W.register { plate = "digital_gold",  items = both("DigitalDress") }     -- vanilla's Dress watch is gold: the gold CaZio
W.register { plate = "timez_red",     items = both("DigitalRed") }
W.register { plate = "timez_steel",   items = both("DigitalTimez") }     -- ZeD-UI's own item (media/scripts/ZeD_Watches.txt)
W.register { plate = "classic_black", items = both("ClassicBlack") }
W.register { plate = "classic_gold",  items = both("ClassicGold") }
W.register { plate = "timez_easy",    items = both("ClassicBrown") }
W.register { plate = "timez_camper",  items = both("ClassicMilitary") }
W.register { plate = "expensive",     items = both("Expensive") }

-- the registration for a worn item (an unknown one borrows a CaZio)
local _fallbackDefs = {}
local function _defFor(item)
    local ft = _safe(function() return tostring(item:getFullType()) end, "")
    local def = W.watches[ft]
    if def then return def end
    local which = _safe(function() return item:isDigital() end, true) and "digital" or "analog"
    local fb = _fallbackDefs[which]
    if not fb then fb = { plate = W.fallback[which] }; _fallbackDefs[which] = fb end
    return fb
end

-- a registration's plate data and its picture lookup (made once per registration)
local function _plateOf(def)
    local X = ZeD.PhysPx
    local des = def.design or (X and X.plates and X.plates[def.plate])
    if not des then return nil end
    if not def._ctx then
        local dir = def.texdir or (X and X.texdir) or ""
        def._ctx = { tex = function(name) return ZeD.Px.tex(dir .. name .. ".png") end }
    end
    return des, def._ctx
end

-- ---------------------------------------------------------------------------
-- What the watch reads
-- ---------------------------------------------------------------------------
local DAYS = { "SU", "MO", "TU", "WE", "TH", "FR", "SA" }
local function _dayOfWeek(y, m, d)   -- Zeller's rule, 1 = Sunday
    if m < 3 then m = m + 12; y = y - 1 end
    local k, j = y % 100, math.floor(y / 100)
    local h = (d + math.floor(13 * (m + 1) / 5) + k + math.floor(k / 4) + math.floor(j / 4) + 5 * j) % 7
    return ((h + 6) % 7) + 1
end

-- the air temperature as the vanilla clock shows it (ClimateManager, the Celsius / Fahrenheit option):
-- the number as text and its unit ("21", "C"), or nil when unavailable
local function _thermo(player)
    local ok, t = pcall(function() return getClimateManager():getAirTemperatureForCharacter(player, false) end)
    if not ok or type(t) ~= "number" then return nil end
    local celsius = true
    pcall(function() celsius = getCore():getOptionTemperatureDisplayCelsius() end)
    if celsius == false then t = t * 9 / 5 + 32 end
    return tostring(math.floor(t + 0.5)), (celsius == false) and "F" or "C"
end

-- dark: the sun is down (the season's dawn and dusk, 6 and 21 when the climate can't say;
-- asked once an in-game hour, not every frame)
local _sun = { hour = -1, dawn = 6, dusk = 21 }
local function _askSun()
    local season = getClimateManager():getSeason()
    _sun.dawn, _sun.dusk = season:getDawn(), season:getDusk()
end
local function _isDark(tod)
    local hr = math.floor(tod)
    if hr ~= _sun.hour then
        _sun.hour = hr
        if not pcall(_askSun) or type(_sun.dawn) ~= "number" or type(_sun.dusk) ~= "number" then _sun.dawn, _sun.dusk = 6, 21 end
    end
    return tod < _sun.dawn or tod >= _sun.dusk
end
W._isDark = _isDark

-- the readout for the plate's display fields (a field draws only when its value is here),
-- filled into rd (reused every frame, so nothing is allocated)
local function _reading(rd, player, item, speed, setOpen, armed, alarmHour)
    for k in pairs(rd) do rd[k] = nil end
    local gt = getGameTime()
    local day = (gt:getDay() or 0) + 1
    rd.dateWin = tostring(day)                         -- the date window is its own wheel: it stays while setting
    if setOpen then
        rd.setTitle = armed and "ALARM" or "ALARM OFF"
        rd.setVal = armed and string.format("%02d", alarmHour) or ""
        rd.setHint = "-1H  +1H"
        rd.setText = armed and string.format("AL %02d", alarmHour) or "AL OFF"
        return rd
    end
    local hour, min = gt:getHour(), gt:getMinutes()
    local tod = gt:getTimeOfDay() or (hour + min / 60)
    local fmt24 = true
    local ok24, v24 = pcall(function() return getCore():getOptionClock24Hour() end)
    if ok24 and v24 == false then fmt24 = false end
    local h = hour
    if not fmt24 then
        h = hour % 12; if h == 0 then h = 12 end
        if hour >= 12 then rd.pm = "P" end
    end
    rd.time = string.format("%2d:%02d", h, min)
    rd.sec = string.format("%02d", math.floor(tod * 3600) % 60)
    local month = (gt:getMonth() or 0) + 1
    local year = gt:getYear() or 1993
    rd.day = DAYS[_dayOfWeek(year, month, day)] or ""
    rd.date = tostring(day)
    local t, unit = _thermo(player)
    if t then rd.temp = t; rd.tempUnit = string.char(176) .. unit end   -- the degree sign (Kahlua: one character)
    if speed == 0 then rd.pause = "PAUSE" else rd.speed = speed end
    if armed then
        rd.alm = "ALM"
        rd.almTime = string.format("%d:00", alarmHour)
    end
    return rd
end

-- ---------------------------------------------------------------------------
-- Finding the worn watch
-- ---------------------------------------------------------------------------
local function _wornWatch(player)
    local worn = _safe(function() return player:getWornItems() end, nil)
    if not worn then return nil end
    for i = 0, worn:size() - 1 do               -- a Java list: 0-based, :get / :size
        local wi = worn:get(i)
        local item = wi and wi:getItem()
        if item and instanceof(item, "AlarmClockClothing") then
            local loc = tostring(wi:getLocation() or ""):lower()
            if loc:find("wrist") or loc == "" then return item end
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Game speed through the Java speed controls (parked, but still the authority)
-- ---------------------------------------------------------------------------
local function _speed() local sc = UIManager.getSpeedControls(); return sc and sc:getCurrentGameSpeed() or 1 end
local function _setSpeed(n)
    local sc = UIManager.getSpeedControls(); if not sc then return end
    if n <= 0 then pcall(function() sc:ButtonClicked("Pause") end); return end
    local ok = pcall(function() sc:SetCurrentGameSpeed(n) end)
    if not ok and n == 1 then pcall(function() sc:ButtonClicked("Play") end) end
end
W._lastRun = W._lastRun or 1
local function _actStart() local sp = _speed(); if sp == 0 then _setSpeed(W._lastRun or 1) else W._lastRun = sp; _setSpeed(0) end end
local function _actSpeed() local sp = _speed(); if sp == 0 then return end; local n = sp + 1; if n > 3 then n = 1 end; W._lastRun = n; _setSpeed(n) end

-- the alarm hour one step on (+1) or back (-1); between 23 and 0 sits OFF
local function _alarmStep(item, dir)
    local armed = _safe(function() return item:isAlarmSet() end, false)
    local h = _safe(function() return item:getHour() end, 6) or 6
    if not armed then
        h = (dir > 0) and 0 or 23
        pcall(function() item:setHour(h); item:setMinute(0); item:setAlarmSet(true) end)
        return
    end
    h = h + dir
    if h > 23 or h < 0 then pcall(function() item:setAlarmSet(false) end); return end
    pcall(function() item:setHour(h); item:setMinute(0) end)
end
W._alarmStep = _alarmStep

-- ---------------------------------------------------------------------------
-- The organism
-- ---------------------------------------------------------------------------
ZeD_Watch = ZeD_Panel:derive("ZeD_Watch")

function ZeD_Watch:new(playerNum)
    local o = ZeD_Panel:new(0, 0, 150, 176)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum or 0
    o._zedLabel = "Watch"
    o._hit = {}               -- this frame's click areas, screen pixels relative to the panel
    o._ctl = {}               -- the plate's controls (reused)
    o._st = { display = {} }  -- the plate's state (reused)
    o._s = 1
    o._setOpen = false
    o._litUntil = 0
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor     = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

function ZeD_Watch:_scale() local Sc = ZeD.Scale; return ((Sc and Sc.root and Sc.root()) or 1) * (W.scale or 1) end   -- root scale (1080p = 1.0)

-- the panel sits where the Java clock sat, sized to the plate at k screen pixels per art pixel
function ZeD_Watch:_layout(frameW, frameH, k)
    local w, h = frameW * k, frameH * k
    local pn = self.playerNum
    local right = getPlayerScreenLeft(pn) + getPlayerScreenWidth(pn)
    local clock = UIManager.getClock()
    local x = right - w - 8 * k
    local y = getPlayerScreenTop(pn) + (W._clockY or 10)   -- the Java clock's own Y (it is parked off-screen, see prerender)
    if clock then x = math.min(x, clock:getX() + clock:getWidth() - w) end
    if self:getWidth() ~= w then self:setWidth(w) end
    if self:getHeight() ~= h then self:setHeight(h) end
    if self:getX() ~= x then self:setX(x) end
    if self:getY() ~= y then self:setY(y) end
    return w, h
end

-- this frame's click areas from the plate (only the enabled ones), in screen pixels
function ZeD_Watch:_hitsFrom(des, st, k)
    local ctl = ZeD.Plate.controls(des, st, self._ctl)
    local hits = self._hit
    for i = #hits, 1, -1 do hits[i] = nil end
    for i = 1, #ctl do
        local c = ctl[i]
        if c.enabled then hits[#hits + 1] = { id = c.id, x = c.x * k, y = c.y * k, w = c.w * k, h = c.h * k } end
    end
    for i = #ctl, 1, -1 do ctl[i] = nil end      -- Plate.controls appends: start empty next frame
end

function ZeD_Watch:_canvas(k)
    local cv = self._cv
    if not cv then cv = ZeD.Px.canvas(self, 0, 0, k); self._cv = cv end
    cv.k = k
    return cv
end

function ZeD_Watch:prerender()
    local player = getSpecificPlayer(self.playerNum)
    if not player or (ISUIHandler and ISUIHandler.allUIVisible == false) then return end
    -- Park the Java clock and speed controls every frame. setVisible(false) is NOT enough in
    -- B42 (UIManager renders both regardless of the flag), so they also go off-screen. Java
    -- re-aligns their X every frame but leaves Y alone, so Y is the parking axis; the clock's
    -- original Y is remembered as the anchor for this watch.
    local clock = UIManager.getClock()
    if clock then
        local cy = clock:getY()
        if cy >= 0 then W._clockY = cy; pcall(clock.setY, clock, -4000) end
        if clock:isVisible() then pcall(clock.setVisible, clock, false) end
    end
    local sc = UIManager.getSpeedControls()
    if sc then
        if sc:getY() >= 0 then pcall(sc.setY, sc, -4000) end
        if sc:isVisible() then pcall(sc.setVisible, sc, false) end
    end

    local PLT = ZeD.Plate
    local k = ZeD.Px.k(self:_scale())            -- whole art pixels only (k = the root scale rounded down)
    local speed = _speed()
    local item = _wornWatch(player)
    if item ~= self._item then self._setOpen = false; self._litUntil = 0 end   -- a different watch: nothing carries over
    self._item = item

    if not item then
        -- no watch: the tape deck keys, the key for the game's speed sitting down
        local X = ZeD.PhysPx
        local des = X and X.plates and X.plates.speed_keys
        if not des then return end
        self:_layout(des.w, des.h, k); self._s = k
        local st = self._keySt or {}; self._keySt = st
        for i = 0, 3 do st["speed" .. i] = (speed == i) end
        local ctx = self._keyCtx
        if not ctx then ctx = { tex = function(name) return ZeD.Px.tex(X.texdir .. name .. ".png") end }; self._keyCtx = ctx end
        local okD, eD = pcall(PLT.draw, self:_canvas(k), des, st, ctx)
        if not okD then ZeD.logOnce("watch plate", eD); return end
        self:_hitsFrom(des, st, k)
        return
    end

    local def = _defFor(item)
    local des, ctx = _plateOf(def)
    if not des then return end
    self._def = def
    self:_layout(des.w, des.h, k); self._s = k

    local armed = _safe(function() return item:isAlarmSet() end, false) and true or false
    local alarmHour = _safe(function() return item:getHour() end, 6) or 6
    local gt = getGameTime()
    local st = self._st
    st.hour, st.minute = gt:getHour(), gt:getMinutes()
    st.running = speed > 0
    st.alarmOn = armed
    st.setOpen = self._setOpen
    st.lit = getTimestampMs() < (self._litUntil or 0)
    st.dark = (not st.lit) and _isDark(gt:getTimeOfDay() or st.hour) or false
    _reading(st.display, player, item, speed, self._setOpen, armed, alarmHour)
    -- (an add-on face with bad data logs once and is not drawn, rather than throwing every
    -- frame on an always-visible prop; code audit Oct 17 2026)
    local okD, eD = pcall(PLT.draw, self:_canvas(k), des, st, ctx)
    if not okD then ZeD.logOnce("watch plate " .. tostring(def and def.id), eD); return end
    self:_hitsFrom(des, st, k)
end
function ZeD_Watch:render() end

function ZeD_Watch:_act(id)
    local item = self._item
    if id:sub(1, 5) == "speed" and #id == 6 then _setSpeed(tonumber(id:sub(6))); return end   -- the tape deck keys
    if id == "speed" then _actSpeed(); return end
    if id == "start" then _actStart(); return end
    if not item then return end
    if id == "light" then self._litUntil = getTimestampMs() + W.LIGHT_MS; return end
    if id == "alarm" then
        if self._setOpen then self._setOpen = false; return end
        pcall(function() item:setAlarmSet(not item:isAlarmSet()) end); return
    end
    if id == "set" or id == "crown" then self._setOpen = not self._setOpen; return end
    if id == "setup" then _alarmStep(item, 1); return end
    if id == "setdn" then _alarmStep(item, -1); return end
end

function ZeD_Watch:onMouseDown(x, y)
    for _, hr in ipairs(self._hit or {}) do
        if x >= hr.x and x < hr.x + hr.w and y >= hr.y and y < hr.y + hr.h then
            pcall(function() getSoundManager():playUISound("UIActivateButton") end)
            local ok, err = pcall(self._act, self, hr.id)
            if not ok then print("[ZeD] Watch: action " .. tostring(hr.id) .. " failed: " .. tostring(err)) end
            return true
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------
function W.install()
    if W._instance then return W._instance end
    local inst = ZeD_Watch:new(0)
    inst:initialise()
    inst:addToUIManager()
    inst:setVisible(true)
    W._instance = inst
    print("[ZeD] Watch: plate watch installed (Java clock + speed controls parked)")
    return inst
end
function W.getInstance() return W._instance end

Events.OnGameStart.Add(function() W._instance = nil; W.install() end)
