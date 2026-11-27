-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Watch.lua
-- ============================================================================
-- THE WATCH - client organism; a physical wristwatch at the top right, drawn as
-- a pixel-art plate by the shared plate template (ZeD_Plate.lua). It replaces
-- the Java clock AND the Java speed controls. Before touching it: those two are
-- never removed, only parked off-screen every frame (prerender), and the speed
-- controls stay the authority for the game's speed.
--
-- Two brands and the expensive one:
--   CaZio  digital (black, gold): ALARM and SET keys on the face, SPEED and
--          START metal keys below; the thermometer is its perk.
--          classic (black, gold): hands + a small display; SET, ALARM, SPEED,
--          START pushers, the crown opens the alarm's setting.
--          LIGHT: a small yellow glowing bulb, deliberately cheap-looking;
--          a pusher high on the left (the digital) or at nine (the classic)
--          lights a tiny bulb at the display's left edge for W.LIGHT_MS; the
--          glass goes a little warmer and lighter by it, fading across; the
--          night stays (the plate's "bulb" pictures, st.bulb; plate data light = "bulb").
--   Timez  digital (red, steel): SET, ALARM, SPEED, START pushers in the case's
--          cut corners and the big INDIGLOW key under the screen.
--          analogue (Easy Reader, Camper): the main crown is the light, the small
--          crown opens the alarm's setting, START and SPEED pushers.
--          The light is Timez's perk: the screen or dial glows for a few seconds.
--   Rollex the expensive one: START and SPEED pushers, the crown opens the alarm's
--          setting; its hands and index dots glow in the dark.
-- At night every watch's screen and dial go faint (still readable); the plate
-- art carries a "dark" picture and its live parts carry night colours.
-- No watch worn: nothing shows here. The game speed's keys live in one spot, the belt row's right end, watch or
-- no watch (Time buttons, the director, Nov 22 2026; the tape deck keys that stood here are gone).
--
-- ON THE BELT (the "Watch" option, default): the worn watch shows
-- small on the belt (WatchMini.lua, laid out by ZeD_Belt.lua) and this panel
-- stays tucked away (still parking the Java clock). Its face pops the full
-- watch up above it, or where the player last dragged it (drag it by any part
-- that is not a control; kept per character); it tucks back after a few idle
-- seconds or another press on the small one.
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
-- glowing hands are all in the art and data, so registering says no more than
-- "this item wears this plate". An item nobody registered borrows a CaZio (digital or not).
--
-- The controls every plate may carry (click area ids):
--   speed  steps the game speed 1x 2x 3x 4x    start  pauses / runs
--   alarm  arms or disarms the alarm         set, crown  open / close the alarm's setting
--   light  lights the watch (Timez, CaZio)   setdn, setup  the alarm hour -1 / +1 while setting
--                                             (one hour past 23 or before 0 is OFF)
--   speed0..speed4  set that speed (0 paused .. 4 Wait): the belt's speed keys press these through W.act
-- ============================================================================

require "ZeD/Tr"
require "ZeD/ZeD_Panel"
require "ZeD/SafeMode"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"
require "ZeD/WatchMini"

ZeD = ZeD or {}
ZeD.Watch = ZeD.Watch or {}
local W = ZeD.Watch
-- Whether the game's clock would show the date now (a watch that shows it), read before the watch parks the clock;
-- nil when no watch has drawn lately (the clock then reads as the game has it). (QA I10, Nov 27 2026)
function W.dateVisible()
    if W._dateVisible ~= nil and getTimestampMs() - (W._dateAt or 0) < 2000 then return W._dateVisible end
    local clock = UIManager and UIManager.getClock and UIManager.getClock() or nil
    if not clock then return false end
    local ok, v = pcall(clock.isDateVisible, clock)
    return ok and v == true
end
W.scale = W.scale or 1.0
W.LIGHT_MS = 3000                  -- how long a Timez or a CaZio's bulb stays lit after a press (a real one: about three seconds)
W.watches = W.watches or {}        -- full item type -> its registration
W.fallback = W.fallback or { digital = "digital_black", analog = "classic_black" }

local function _safe(fn, default) local ok, v = pcall(fn); if ok then return v end; return default end

-- ---------------------------------------------------------------------------
-- The registry
-- ---------------------------------------------------------------------------
--- Register a watch, ZeD-UI's own or an addon's (THE WATCH REGISTRY above):
--- def = { plate = id, items = { full types }, design = data table or nil, texdir = folder or nil }
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

--- Whether a registration's plate (or a plate id) has a light: a Timez's glow or a CaZio's bulb (its
--- "light" control); asked once per registration.
function W.hasLight(def)
    if type(def) == "string" then def = { plate = def } end
    if type(def) ~= "table" then return false end
    if def._hasLight == nil then
        local des = _plateOf(def)
        local has = false
        for _, h in ipairs((des and des.hits) or {}) do if h.id == "light" then has = true end end
        def._hasLight = has
    end
    return def._hasLight
end

-- ---------------------------------------------------------------------------
-- What the watch reads
-- ---------------------------------------------------------------------------
-- the weekday on the LCD, two letters: the keys UI_ZeD_Watch_Day<Su..Sa>, read when the day draws
local DAYS = { "UI_ZeD_Watch_DaySu", "UI_ZeD_Watch_DayMo", "UI_ZeD_Watch_DayTu", "UI_ZeD_Watch_DayWe", "UI_ZeD_Watch_DayTh",
               "UI_ZeD_Watch_DayFr", "UI_ZeD_Watch_DaySa" }
ZeD.trDefaults({
    UI_ZeD_Watch_DaySu = "SU", UI_ZeD_Watch_DayMo = "MO", UI_ZeD_Watch_DayTu = "TU", UI_ZeD_Watch_DayWe = "WE",
    UI_ZeD_Watch_DayTh = "TH", UI_ZeD_Watch_DayFr = "FR", UI_ZeD_Watch_DaySa = "SA",
    UI_ZeD_Watch_Alarm = "ALARM", UI_ZeD_Watch_AlarmOff = "ALARM OFF", UI_ZeD_Watch_SetHint = "-1H  +1H",
    UI_ZeD_Watch_SetText = "AL %1", UI_ZeD_Watch_SetTextOff = "AL OFF", UI_ZeD_Watch_Pause = "PAUSE", UI_ZeD_Watch_Alm = "ALM",
})
-- The words the LCD draws (day, ALM, PAUSE, the alarm's setting) sit in fixed cells in a pixel
-- face: never stretched by the test language, and a translation with a letter the face cannot
-- draw gives way to the English (1993 LCD watches printed English day names anyway).
local LCD_FACE = "35"
local function _lcdCan(s)
    local F = ZeD.PixelFonts and ZeD.PixelFonts[LCD_FACE]
    if not F then return true end
    for i = 1, #s do
        local c = s:sub(i, i)
        if c ~= " " and not F[c] and not F[string.upper(c)] then return false end
    end
    return true
end
local function _lcd(key, a1)
    local s = ZeD.trPlain(key, a1)
    if _lcdCan(s) then return s end
    return ZeD.trEnglish(key, a1)
end
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
W._isDark = _isDark   -- (the two-way radios' faces ask it too: TwoWayFace.lua)

-- the readout for the plate's display fields (a field draws only when its value is here),
-- filled into rd (reused every frame, so nothing is allocated)
local function _reading(rd, player, item, speed, setOpen, armed, alarmHour)
    for k in pairs(rd) do rd[k] = nil end
    local gt = getGameTime()
    local day = (gt:getDay() or 0) + 1
    rd.dateWin = tostring(day)                         -- the date window is its own wheel: it stays while setting
    if setOpen then
        rd.setTitle = armed and _lcd("UI_ZeD_Watch_Alarm") or _lcd("UI_ZeD_Watch_AlarmOff")
        rd.setVal = armed and string.format("%02d", alarmHour) or ""
        rd.setHint = _lcd("UI_ZeD_Watch_SetHint")
        rd.setText = armed and _lcd("UI_ZeD_Watch_SetText", string.format("%02d", alarmHour)) or _lcd("UI_ZeD_Watch_SetTextOff")
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
    local dayKey = DAYS[_dayOfWeek(year, month, day)]
    rd.day = dayKey and _lcd(dayKey) or ""
    rd.date = tostring(day)
    -- (the director, Nov 19 2026: "the watch only says the day, not the month": the plain face writes the month's
    -- short name too; the LCD faces keep their own day and number)
    local MON = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
    rd.mon = ZeD.tr("UI_ZeD_MainMenu_Month" .. (MON[month] or "Jan"))
    -- (the director, Nov 19 2026: "I'm almost positive month is on the vanilla watch. Is that not how you track what
    -- month you're in game?" The game's clock shows month and day; the drawn digital faces' date reads 11-14 too,
    -- PhysPx.lua's dateMD fields. While setting, the faces' middle shows what is set, so the date keeps to the day.)
    rd.dateMD = setOpen and tostring(day) or (tostring(month) .. "-" .. tostring(day))
    local t, unit = _thermo(player)
    if t then rd.temp = t; rd.tempUnit = string.char(176) .. unit end   -- the degree sign (Kahlua: one character)
    if speed == 0 then rd.pause = _lcd("UI_ZeD_Watch_Pause") else rd.speed = speed end
    if armed then
        rd.alm = _lcd("UI_ZeD_Watch_Alm")
        rd.almTime = string.format("%d:00", alarmHour)
    end
    return rd
end

-- ---------------------------------------------------------------------------
-- Finding the worn watch
-- ---------------------------------------------------------------------------
-- obj:fname() for pcall without a new closure: pcall(_invoke, obj, "isAlarmSet")
local function _invoke(obj, fname) return obj[fname](obj) end
local function _callOr(obj, fname, default)
    local ok, v = pcall(_invoke, obj, fname)
    if ok then return v end
    return default
end
W._callOr = _callOr

local function _wornScan(player)
    local worn = _callOr(player, "getWornItems", nil)
    if not worn then return nil end
    local other, otherLoc
    for i = 0, worn:size() - 1 do               -- a Java list: 0-based, :get / :size
        local wi = worn:get(i)
        local item = wi and wi:getItem()
        if item and instanceof(item, "AlarmClockClothing") then
            local loc = tostring(wi:getLocation() or ""):lower()
            -- the game's wrists, or a mod's own watch slot (Pack Mule moves watches to mule:left_watch)
            if loc:find("wrist") or loc:find("watch") or loc == "" then return item, loc end
            if not other then other, otherLoc = item, loc end   -- (worn anywhere else: still the watch)
        end
    end
    return other, otherLoc
end

-- The worn watch is looked up once per character per UI draw (the watch's
-- prerender, W.beltWatch and the belt's layout each walked the worn items every frame). Clothes change in the
-- game's update, never while the UI draws (UIManager.render: OnPreUIDraw, every element, OnPostUIDraw), so
-- within one draw the answer is the same; outside a draw every call looks again.
local _memo, _memoN, _drawing = {}, 0, false
local function _memoClear()
    for i = 1, _memoN do local e = _memo[i]; e.p, e.item, e.loc = nil, nil, nil end
    _memoN = 0
end
local function _wornWatch(player)
    if not _drawing then return _wornScan(player) end
    for i = 1, _memoN do
        local e = _memo[i]
        if e.p == player then return e.item, e.loc end
    end
    local item, loc = _wornScan(player)
    _memoN = _memoN + 1
    local e = _memo[_memoN]
    if not e then e = {}; _memo[_memoN] = e end
    e.p, e.item, e.loc = player, item, loc
    return item, loc
end
W._wornWatch = _wornWatch
if Events.OnPreUIDraw and Events.OnPostUIDraw then
    Events.OnPreUIDraw.Add(function() _memoClear(); _drawing = true end)
    Events.OnPostUIDraw.Add(function() _drawing = false; _memoClear() end)
end

-- ---------------------------------------------------------------------------
-- On the belt (the "Watch" option; WatchMini.lua draws the small one)
-- ---------------------------------------------------------------------------
W.POP_IDLE_MS = 6000     -- the full watch tucks back after this long untouched

--- The "Watch" option says the belt (its first choice, the default; no option at all counts as the belt).
function W.beltMode()
    -- (beta 21, the director: in Lite "the watches stay, but the watches aren't on the belt anymore": the corner)
    if ZeD.Settings and ZeD.Settings.lite and ZeD.Settings.lite() then return false end
    local o = ZeD.Settings and ZeD.Settings.watchPlaceOption
    return not o or o:getValue() == 1
end

--- The watch for the belt: item, plate, wrist ("left" / "right"), or nil.
function W.beltWatch(player)
    if not (player and W.beltMode() and ZeD.WatchMini) then return nil end
    local item, loc = _wornWatch(player)
    if not item then return nil end
    local plate = _defFor(item).plate
    if not ZeD.WatchMini.has(plate) then return nil end
    return item, plate, (loc and loc:find("right")) and "right" or "left"
end

-- ---------------------------------------------------------------------------
-- Game speed through the Java speed controls (parked, but still the authority)
-- ---------------------------------------------------------------------------
local function _speed() local sc = UIManager.getSpeedControls(); return sc and sc:getCurrentGameSpeed() or 1 end
-- The parked speed controls' visible flag: on in single player (the game's Pause on Focus Loss reads it),
-- off on a server
function W.parkSpeed(sc)
    if not sc then return end
    local want = not (isClient and isClient())
    if sc:isVisible() ~= want then pcall(sc.setVisible, sc, want) end
end
local SPEED_BUTTON = { [2] = "Fast Forward x 1", [3] = "Fast Forward x 2", [4] = "Wait" }
local SPEED_MULT = { [2] = 5, [3] = 20, [4] = 40 }
-- On a server the server sets the time: Start and Speed do nothing there (letting them through raised the
-- client's own multiplier and its clock ran ahead of the server's), as the D-pad
-- wheel's Game speed (ZeD_DpadWheels: UI_ZeD_Wheel_ServerTime)
local function _serverTime() return isClient() end
local function _setSpeed(n)
    if _serverTime() then return end
    local sc = UIManager.getSpeedControls(); if not sc then return end
    if n <= 0 then pcall(function() sc:ButtonClicked("Pause") end); return end
    -- the fast speeds go through the clock's own buttons: SetCurrentGameSpeed only moves
    -- the speed index and resets the time multiplier to 1, so x5 / x20 / x40 would
    -- show on the watch while time kept running at x1
    local button = SPEED_BUTTON[n]
    if button and pcall(function() sc:ButtonClicked(button) end) then return end
    local ok = pcall(function() sc:SetCurrentGameSpeed(n) end)
    if not ok and n == 1 then pcall(function() sc:ButtonClicked("Play") end) end
    local mult = SPEED_MULT[n]
    if ok and mult then pcall(function() getGameTime():setMultiplier(mult) end) end
end
W._lastRun = W._lastRun or 1
local function _actStart() local sp = _speed(); if sp == 0 then _setSpeed(W._lastRun or 1) else W._lastRun = sp; _setSpeed(0) end end
-- steps through every running speed vanilla offers: 1 (x1), 2 (x5), 3 (x20), 4 (x40, its Wait button)
local SPEED_TOP = 4
local function _actSpeed() local sp = _speed(); if sp == 0 then return end; local n = sp + 1; if n > SPEED_TOP then n = 1 end; W._lastRun = n; _setSpeed(n) end

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

local _mini = {}
--- The small watch's reading: hour, minute, fmt24, speed, armed, lit, night, dark (one reused table).
function W.miniState(player, item)
    local gt = getGameTime()
    _mini.hour, _mini.minute = gt:getHour(), gt:getMinutes()
    local ok24, v24 = pcall(function() return getCore():getOptionClock24Hour() end)
    _mini.fmt24 = not (ok24 and v24 == false)
    _mini.speed = _speed()
    _mini.armed = _callOr(item, "isAlarmSet", false) and true or false
    local inst = W._instance
    _mini.lit = inst ~= nil and getTimestampMs() < (inst._litUntil or 0)
    _mini.night = _isDark(gt:getTimeOfDay() or _mini.hour) and true or false   -- a CaZio's bulb keeps the night under it
    _mini.dark = (not _mini.lit) and _mini.night
    return _mini
end

--- A press on the small watch: its pushers act as the full watch's; the face pops it.
function W.act(id)
    local inst = W._instance
    if not inst then return end
    if id == "face" then W.togglePop(); return end
    pcall(inst._act, inst, id)
    inst._popTouched = getTimestampMs()
end

--- Pop the full watch up over the belt (on = true), tuck it back (false), or flip it (nil).
function W.togglePop(on)
    local inst = W._instance
    if not inst then return end
    if on == nil then on = not inst._popped end
    inst._popped = on and true or false
    inst._popTouched = getTimestampMs()
    if not on then inst._setOpen = false end
end

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

-- True when the open window `win` overlaps the box (x, y, w, h). No window, or a hidden one: false. (QA B8-3)
local function _overBox(win, x, y, w, h)
    if not (win and win.getIsVisible and win:getIsVisible()) then return false end
    local wx, wy = win:getX(), win:getY()
    return x < wx + win:getWidth() and x + w > wx and y < wy + win:getHeight() and y + h > wy
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
    -- QA's visual audit B1, Nov 20 2026: a wide World window (Crafting or Maps open) covered the corner clock.
    -- When the open World window's rect overlaps the clock's, the clock steps to the window's left side;
    -- when there is no room there, it steps below the window. No overlap: placed exactly as before.
    -- (QA B8-3) Both of the player's windows count: the Character window stands just left of the World window,
    -- so a step left of the World window lands under it. Look again after every step; at most 4 steps, and with
    -- no clear spot the clock stays at the last one. No tables or closures: _overBox reads the windows directly.
    local WWin = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(pn)
    local CWin = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow(pn)
    local gap = 4 * k
    for _ = 1, 4 do
        local over = nil
        if _overBox(WWin, x, y, w, h) then over = WWin
        elseif _overBox(CWin, x, y, w, h) then over = CWin end
        if not over then break end   -- clear of both windows
        local wx, wy = over:getX(), over:getY()   -- (screen edges are read only here, when a window is in the way)
        local left = getPlayerScreenLeft(pn)
        local bottom = getPlayerScreenTop(pn) + getPlayerScreenHeight(pn)
        if wx - gap - w >= left then
            x = wx - gap - w
        elseif wy + over:getHeight() + gap + h <= bottom then
            y = wy + over:getHeight() + gap
        else
            break   -- no room left or below: stay here
        end
    end
    if self:getWidth() ~= w then self:setWidth(w) end
    if self:getHeight() ~= h then self:setHeight(h) end
    if self:getX() ~= x then self:setX(x) end
    if self:getY() ~= y then self:setY(y) end
    return w, h
end

-- this frame's click areas from the plate (only the enabled ones), in screen pixels
-- (the enabled controls are read straight from the plate's hits, as
-- ZeD.Plate.controls lists them, into click areas reused frame to frame, so a frame makes no new tables)
function ZeD_Watch:_hitsFrom(des, st, k)
    local hits, pool = self._hit, self._hitPool
    if not pool then pool = {}; self._hitPool = pool end
    local n = 0
    local list = des.hits
    if list then
        for _, h in ipairs(list) do
            -- Plate.controls: a "look" area is not a control; one with needs is enabled while st[needs] is
            if (h.kind or "press") ~= "look" and (h.needs == nil or st[h.needs]) then
                n = n + 1
                local hr = pool[n]
                if not hr then hr = {}; pool[n] = hr end
                hr.id, hr.x, hr.y, hr.w, hr.h = h.id, h.x * k, h.y * k, h.w * k, h.h * k
                hits[n] = hr
            end
        end
    end
    for i = #hits, n + 1, -1 do hits[i] = nil end
end

-- ---------------------------------------------------------------------------
-- THE SIMPLE WATCH (the watchSimple setting): a plain clock box in
-- ZeD's own parts, with the same readings as the watch (the ids go to _act unchanged).
-- Worn: a plain face, the time large with its seconds, the weekday and date, the temperature and the alarm; while
-- setting, the alarm hour with - and + and Done. No time buttons: the game's speed keys live in one spot, the belt
-- row's right end, whatever the watch (Time buttons, the director, Nov 22 2026). No watch: nothing.
-- ---------------------------------------------------------------------------
--- The watchSimple setting is on.
function W.simple() return ZeD.Settings and ZeD.Settings.watchSimple and ZeD.Settings.watchSimple() or false end
--- Lite (beta 21): the plain clock with the speed as one pick-one row.
function W.lite() return ZeD.Settings and ZeD.Settings.lite and ZeD.Settings.lite() or false end

-- THE GAME'S SPEED KEYS, SHARED (Simple watch, the director, Nov 22 2026): "move the time controls out of the simple
-- watch ... we're using the same buttons we use down in the belt below, with a little bit of padding between." The
-- belt's five keys (KISS #22, ZeD_Belt.lua's _speedBoxes and _drawButton): Pause, Play, Fast forward x1, x2, Wait, the
-- one in use lit. (Time buttons, the director, Nov 22 2026: "put the time controls in the same spot no matter what."
-- The watch draws no keys of its own now; these are kept for the belt row's right end, the one spot, to draw with.)
-- (the same numbers as the belt's B.SPEED_KEY, B.SPEED_GAP, B.SPEED_ICONS and B.SPEED_WORDS)
W.SPEED_KEY, W.SPEED_GAP = 20, 2       -- a key's size and the gap between keys (design units)
W.SPEED_ICONS = { [0] = "pause", "play", "ff1", "ff2", "wait" }
W.SPEED_WORDS = { [0] = "UI_optionscreen_binding_Pause", "IGUI_BackButton_Play", "IGUI_BackButton_FF1", "IGUI_BackButton_FF2", "IGUI_BackButton_FF3" }
--- The key for speed n (0 paused .. 4 Wait) is lit at speed sp (Wait's key for any speed past it).
function W.speedLit(n, sp) return (sp == n) or (n == 4 and sp > 4) end
--- The row's width in screen pixels (five keys and four gaps).
function W.speedRowW() local px = ZeD.T.px; return 5 * px(W.SPEED_KEY) + 4 * px(W.SPEED_GAP) end
--- One speed key as the belt draws it: the box (the accent when lit), the pad's mark (focus) or the pointer's wash
--- (hover), the border, the icon. panel: the panel to draw in; (x, y): its corner; k: its size in screen pixels.
function W.drawSpeedKey(panel, x, y, k, n, lit, hover, focus)
    local T = ZeD.T
    local s1, bd = T.surf1, T.borderS
    local fill = lit and T.accent or s1
    panel:drawRect(x, y, k, k, lit and 1 or 0.92, fill.r, fill.g, fill.b)
    if focus then
        local F = ZeD.Focus
        if F and F.mark then F.mark(panel, x, y, k, k, { win = panel, focused = true }) end
    elseif hover then
        -- (the pointer's wash is off while the controller's marks show, as the belt's)
        local IF = ZeD.Input and ZeD.Input.Focus
        if not (IF and IF.cuesVisible and IF.cuesVisible(panel.playerNum)) then
            local hv = T.hover
            panel:drawRect(x, y, k, k, hv.a or 0.2, hv.r, hv.g, hv.b)
        end
    end
    panel:drawRectBorder(x, y, k, k, 1, bd.r, bd.g, bd.b)
    local ib = math.floor(k * 0.7)   -- the icon, 7 tenths of the key, centred
    local ink = lit and (T.base or T.text) or T.text
    ZeD.Atoms.drawPxIcon(panel, W.SPEED_ICONS[n], x + math.floor((k - ib) / 2), y + math.floor((k - ib) / 2), ib, 1, ink)
end
--- The hover words of speed key n (the belt's: the game's own words for its keys).
function W.speedWords(n) return getText(W.SPEED_WORDS[n]) end

local PLAIN_W, PLAIN_PAD, PLAIN_GAP = 150, 8, 4
-- (Simple watch, the director, Nov 22 2026) The face holds only the readings: the time with its seconds, the weekday and
-- date over the temperature and the alarm; the panel is the face alone (the speed keys are the belt row's: Time
-- buttons, the director, Nov 22 2026). Clicking the alarm opens its setting (the set mode keeps its own - + and Done
-- keys inside the face: they set the alarm, not the time).
function ZeD_Watch:_plain(player, item, speed, armed, alarmHour)
    local T = ZeD.T
    local px = T.px
    local f1, f2 = T.fontF1, T.fontF2
    local tm = ZeD.TM
    local fh1, fh2 = tm:getFontHeight(f1), tm:getFontHeight(f2)
    local hf = ZeD.Font and ZeD.Font.sdf and ZeD.Font.sdf.head
    local z = hf and (26 * (T.scale or 1) / (hf.face or 64)) or nil
    local bigH = (hf and z) and math.floor(ZeD.Text.height(hf, z)) or tm:getFontHeight(T.fontF5)
    local w = px(PLAIN_W)
    local pad, gap, bh = px(PLAIN_PAD), px(PLAIN_GAP), T.buttonH
    local rd = self._st.display
    local btns = {}
    local h
    local topH = nil
    local hits = self._hit
    for i = #hits, 1, -1 do hits[i] = nil end
    -- no watch: no face (prerender does not ask; the speed keys are the belt row's) (Time buttons, the director, Nov 22 2026)
    if not item then return end
    _reading(rd, player, item, speed, self._setOpen, armed, alarmHour)
    -- (the director, Nov 19 2026, on beta 21's report: "time can be large enough to take up two lines, and then
    -- stack day and temperature on the right. Time is on the left." The top block is the time beside a column of
    -- two lines, the weekday and date over the temperature, both right-aligned; it is as tall as the taller.)
    topH = math.max(bigH, 2 * fh2 + gap)
    h = pad + topH + pad
    if self._setOpen then
        btns = { { id = "setdn", text = "-" }, { id = "setup", text = "+" }, { id = "alarmtoggle", text = ZeD.tr("UI_ZeD_WatchPlain_AlarmOnOff") }, { id = "set", text = ZeD.tr("UI_ZeD_WatchPlain_Done") } }
    elseif _serverTime() then
        h = h + gap + fh2   -- (a server: the line "Server time" under the top block)
    end
    -- (QA's visual noise audit 6, Nov 20 2026, then every Simple watch, Nov 22 2026: the belt's lit speed key says the
    -- speed, so no speed line; the alarm sits beside the temperature. On a server the line stays: it says "Server time".)
    local faceTop = not self._setOpen
    -- as wide as the set mode's buttons' words need (each its text and a margin), never narrower than the design
    -- width (the buttons share the width equally, so each must hold the widest word)
    local widest = 0
    for _, bt in ipairs(btns) do widest = math.max(widest, ZeD.Molecules.buttonW(bt.text)) end
    local need = 2 * pad + (#btns - 1) * gap + #btns * widest
    if need > w then w = need end
    -- (Simple watch, the director, Nov 22 2026: "make the seconds the same text size as the hours and minutes." The
    -- time is one string, 12:34:56, in the big type. Its width is taken with every digit an 8 too, so the face does
    -- not grow and shrink as the seconds tick.)
    local tBig = (rd.time or ""):gsub("^%s+", "")
    if rd.sec then tBig = tBig .. ":" .. rd.sec end
    local function bigW(s) return (hf and z) and ZeD.Text.width(hf, s, z) or tm:MeasureStringX(T.fontF5, s) end
    -- the top block's width: the time, its PM, a gap, the wider of the two right-hand lines
    if faceTop then
        local tw0 = math.max(bigW(tBig), bigW((tBig:gsub("%d", "8"))))
        local tail0 = rd.pm and (" " .. ZeD.tr("UI_ZeD_WatchPlain_PM")) or ""
        local tailW = (tail0 ~= "") and (px(3) + tm:MeasureStringX(f1, tail0)) or 0
        local dayW = tm:MeasureStringX(f2, (rd.day or "") .. " " .. (rd.mon and (rd.mon .. " ") or "") .. (rd.date or ""))
        local tempW = rd.temp and tm:MeasureStringX(f2, tostring(rd.temp) .. (rd.tempUnit or "")) or 0
        -- (the alarm shares the temperature's line)
        local al0 = armed and ZeD.tr("UI_ZeD_WatchPlain_AlarmAt", rd.almTime or (tostring(alarmHour) .. ":00")) or ZeD.tr("UI_ZeD_WatchPlain_AlarmOff")
        tempW = tempW + ((tempW > 0) and px(10) or 0) + tm:MeasureStringX(f2, al0) + (armed and px(10) or 0)
        local needTop = 2 * pad + tw0 + tailW + px(12) + math.max(dayW, tempW)
        if needTop > w then w = needTop end
    end
    -- the panel is the face. Placed before anything draws (a draw lands where the panel is at that moment)
    local function place(fw, fh)
        self:_layout(fw, fh, 1)
        if self._belt then self:_placePopped(fw, fh) end
        self._s = 1
    end
    -- folded (a click on the face): one thin line, the time, the date and the temperature; a click unfolds it
    if self._plainThin and not self._setOpen then
        local tt = (rd.time or ""):gsub("^%s+", "") .. (rd.pm and (" " .. ZeD.tr("UI_ZeD_WatchPlain_PM")) or "")
        local dd = (rd.day or "") .. " " .. (rd.mon and (rd.mon .. " ") or "") .. (rd.date or "")
        local te = rd.temp and (tostring(rd.temp) .. (rd.tempUnit or "")) or nil
        local sep = px(10)
        local tw1, dw1 = tm:MeasureStringX(f2, tt), tm:MeasureStringX(f2, dd)
        local ew1 = te and tm:MeasureStringX(f2, te) or 0
        local sw = 2 * px(6) + tw1 + sep + dw1 + (te and (sep + ew1) or 0)
        local sh = px(4) + fh2 + px(4)
        place(sw, sh)
        ZeD.Surface.fill(self, 0, 0, sw, sh, "surf2")
        local bb = T.borderS
        self:drawRectBorder(0, 0, sw, sh, bb.a or 1, bb.r, bb.g, bb.b)
        local c1 = T.text
        local x1 = px(6)
        local ac1 = T.accent   -- (the time in the accent color)
        self:drawText(tt, x1, px(4), ac1.r, ac1.g, ac1.b, ac1.a or 1, f2)
        self:drawText(dd, x1 + tw1 + sep, px(4), c1.r, c1.g, c1.b, c1.a or 1, f2)
        if te then self:drawText(te, sw - px(6) - ew1, px(4), c1.r, c1.g, c1.b, c1.a or 1, f2) end
        hits[#hits + 1] = { id = "fold", x = 0, y = 0, w = sw, h = sh }
        return
    end
    -- set mode: the help line wraps to the box (the normal face, not the mono one)
    local helpLines = nil
    if self._setOpen then
        helpLines = ZeD.Atoms.wrapText(ZeD.tr("UI_ZeD_WatchPlain_SetHelp"), f2, w - 2 * pad)
        h = pad + bigH + gap + #helpLines * fh2 + gap + bh + pad
    end
    place(w, h)
    -- the face
    ZeD.Surface.fill(self, 0, 0, w, h, "surf2")
    local b = T.borderS
    self:drawRectBorder(0, 0, w, h, b.a or 1, b.r, b.g, b.b)
    local tc, td = T.text, T.textDim
    local y = pad
    local alarmHit, faceHit = nil, nil   -- (the face's fold area and the alarm line's, when drawn)
    if self._setOpen then
        local s = armed and ZeD.tr("UI_ZeD_WatchPlain_AlarmAt", string.format("%d:00", alarmHour)) or ZeD.tr("UI_ZeD_WatchPlain_AlarmOff")
        if hf and z then ZeD.Text.draw(self, hf, s, pad, y, z * 0.7, tc.r, tc.g, tc.b, tc.a or 1, "l")
        else self:drawText(s, pad, y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF5) end
        y = y + bigH + gap
        for _, l in ipairs(helpLines or {}) do
            self:drawText(l, pad, y, td.r, td.g, td.b, td.a or 1, f2)
            y = y + fh2
        end
        y = y + gap
    else
        local ty = y + math.floor(((topH or bigH) - bigH) / 2)   -- (the time centred in the top block)
        local ac = T.accent   -- (the time in the accent color, the director, Nov 19 2026)
        if hf and z then ZeD.Text.draw(self, hf, tBig, pad, ty, z, ac.r, ac.g, ac.b, ac.a or 1, "l")
        else self:drawText(tBig, pad, ty, ac.r, ac.g, ac.b, ac.a or 1, T.fontF5) end
        local tw = bigW(tBig)
        local tail = rd.pm and (" " .. ZeD.tr("UI_ZeD_WatchPlain_PM")) or ""
        -- (the director, Nov 19 2026, on beta 21's report: "Seconds is below baseline". The small PM stood on the foot
        -- of the time's line box, which sits under its baseline by the bigger face's descent. Both faces are ZeD's
        -- atlas (baseline 60 of a 77 px line, Scale.lua ZED_BASE), so the small line goes down by that share of the
        -- difference in line heights and its baseline meets the time's.)
        if tail ~= "" then self:drawText(tail, pad + tw + px(3), ty + math.floor((bigH - fh1) * 60 / 77 + 0.5), td.r, td.g, td.b, td.a or 1, f1) end
        -- the right-hand column, right-aligned: the weekday and date, then the temperature under it
        local th = topH or bigH
        local cy = y + math.floor((th - (2 * fh2 + gap)) / 2)
        local ds = (rd.day or "") .. " " .. (rd.mon and (rd.mon .. " ") or "") .. (rd.date or "")
        self:drawText(ds, w - pad - tm:MeasureStringX(f2, ds), cy, tc.r, tc.g, tc.b, tc.a or 1, f2)
        local tempW1 = 0
        if rd.temp then
            local ts = tostring(rd.temp) .. (rd.tempUnit or "")
            tempW1 = tm:MeasureStringX(f2, ts)
            self:drawText(ts, w - pad - tempW1, cy + fh2 + gap, tc.r, tc.g, tc.b, tc.a or 1, f2)
        end
        y = y + th + gap
        -- the alarm left of the temperature (a status dot when it is set); on a server the line "Server time"
        local al = armed and ZeD.tr("UI_ZeD_WatchPlain_AlarmAt", rd.almTime or string.format("%d:00", alarmHour)) or ZeD.tr("UI_ZeD_WatchPlain_AlarmOff")
        local aw = tm:MeasureStringX(f2, al)
        local ax = w - pad - tempW1 - ((tempW1 > 0) and px(10) or 0) - aw
        local ay = cy + fh2 + gap
        if _serverTime() then
            self:drawText(ZeD.tr("UI_ZeD_WatchPlain_ServerTime"), pad, y, td.r, td.g, td.b, td.a or 1, f2)
        end
        self:drawText(al, ax, ay, td.r, td.g, td.b, td.a or 1, f2)
        alarmHit = { id = "alarmline", x = ax - px(14), y = ay - px(2), w = aw + px(14), h = fh2 + px(4) }
        faceHit = { id = "fold", x = 0, y = 0, w = w, h = pad + (topH or bigH) }
        if armed then
            local dsz = px(6)
            ZeD.Atoms.drawStatusDot(self, ax - dsz - px(4), ay + math.floor((fh2 - dsz) / 2), T.accent, dsz)
        end
    end
    -- the set mode's buttons, evenly across the face; their ids are the watch's own
    local n = #btns
    local bw = (n > 0) and math.floor((w - 2 * pad - (n - 1) * gap) / n) or 0
    local mx, my = self:getMouseX(), self:getMouseY()
    for i, bt in ipairs(btns) do
        local bx = pad + (i - 1) * (bw + gap)
        local hov = mx >= bx and mx < bx + bw and my >= y and my < y + bh
        ZeD.Molecules.drawButton(self, bx, y, bw, bh, bt.text, bt.on and "primary" or "default", hov and isMouseButtonDown(0))
        hits[#hits + 1] = { id = bt.id, x = bx, y = y, w = bw, h = bh }
    end
    if alarmHit then hits[#hits + 1] = alarmHit end
    if faceHit then hits[#hits + 1] = faceHit end
end

function ZeD_Watch:_canvas(k)
    local cv = self._cv
    if not cv then cv = ZeD.Px.canvas(self, 0, 0, k); self._cv = cv end
    cv.k = k
    return cv
end

function ZeD_Watch:prerender()
    -- safe mode (SafeMode.lua): nothing parked, and this watch hides (a watch made
    -- after safe mode began hides here; the "watch" hook below shows it again)
    if ZeD.Safe.on("watch") then self:setVisible(false); return end
    local player = getSpecificPlayer(self.playerNum)
    if not player or (ISUIHandler and ISUIHandler.allUIVisible == false) then return end
    -- Park the Java clock and speed controls every frame. setVisible(false) is NOT enough in
    -- B42 (UIManager renders both regardless of the flag), so they also go off-screen. Java
    -- re-aligns their X every frame but leaves Y alone, so Y is the parking axis; the clock's
    -- original Y is remembered as the anchor for this watch, and both are remembered for
    -- safe mode to put back.
    local clock = UIManager.getClock()
    if clock then
        local cy = clock:getY()
        if cy >= 0 then W._clockY = cy; pcall(clock.setY, clock, -4000) end
        -- what the game's clock would show before it is parked: the game sets it visible each frame while a watch
        -- shows it, and its date shows while that clock is digital (Clock.isDateVisible = visible and digital).
        -- Read by ZeD.Watch.dateVisible, which the Info tab asks for the time survived (QA I10 second pass, Nov 27
        -- 2026: the parked flag read false there, and "Survived for" always read "--")
        local okV, vis = pcall(clock.isVisible, clock)
        local okD, dig = pcall(clock.isDigital, clock)
        W._dateVisible = (okV and vis == true) and (okD and dig == true)
        W._dateAt = getTimestampMs()
        if clock:isVisible() then pcall(clock.setVisible, clock, false) end
    end
    local sc = UIManager.getSpeedControls()
    if sc then
        local sy = sc:getY()
        if sy >= 0 then W._speedY = sy; pcall(sc.setY, sc, -4000) end
        -- Single player keeps their flag on (parked, they still draw nowhere): the game's own Pause on Focus
        -- Loss (Options, Display; on by default) pauses only while the speed controls are "really visible"
        -- (IngameState.onDisplayFocusLost, 42.21), so hidden here they would silently turn it off.
        -- A server's stay hidden: there they do nothing.
        W.parkSpeed(sc)
    end

    local PLT = ZeD.Plate
    local k = ZeD.Px.k(self:_scale())            -- whole art pixels only (k = the root scale to the nearest whole number)
    local speed = _speed()
    local item = _wornWatch(player)
    if item ~= self._item then self._setOpen = false; self._litUntil = 0 end   -- a different watch: nothing carries over
    self._item = item

    if not item then
        -- (Time buttons, the director, Nov 22 2026: "put the time controls in the same spot no matter what." No watch:
        -- nothing here. The tape deck keys, and the Simple watch's row of keys, gave way to the belt row's speed keys.)
        if self:getWidth() ~= 0 then self:setWidth(0); self:setHeight(0) end
        for i = #self._hit, 1, -1 do self._hit[i] = nil end
        if self:padOn() then self:padLeave() end   -- (the pad on it as the watch came off: the pad goes back)
        return
    end

    local def = _defFor(item)
    local des, ctx = _plateOf(def)
    if not des then return end
    self._def = def
    self._belt = W.beltWatch(player) ~= nil
    if self._belt and not self._popped then
        -- tucked: the small one on the belt is the watch
        if self:getWidth() ~= 0 then self:setWidth(0); self:setHeight(0) end
        for i = #self._hit, 1, -1 do self._hit[i] = nil end
        if self:padOn() then self:padLeave() end   -- (tucked away while the pad was on it: the pad goes back)
        return
    end
    if not self._belt then self._popped = false end
    local padOn = self:padOn()   -- (the pad on it keeps a popped watch up, as the pointer does)
    if W.simple() then
        local armedS = _callOr(item, "isAlarmSet", false) and true or false
        local hourS = _callOr(item, "getHour", 6) or 6
        if self._belt then
            local now = getTimestampMs()
            if self:isMouseOver() or self._dragAt or self._setOpen or padOn then self._popTouched = now
            elseif now - (self._popTouched or now) > W.POP_IDLE_MS then W.togglePop(false); return end
        end
        local okP, eP = pcall(self._plain, self, player, item, speed, armedS, hourS)
        if not okP then ZeD.logOnce("watch plain", eP) end
        self:_padDraw(speed)
        return
    end
    self:_layout(des.w, des.h, k); self._s = k
    if self._belt then
        self:_placePopped(des.w * k, des.h * k)
        local now = getTimestampMs()
        if self:isMouseOver() or self._dragAt or self._setOpen or padOn then self._popTouched = now
        elseif now - (self._popTouched or now) > W.POP_IDLE_MS then W.togglePop(false); return end
    end

    local armed = _callOr(item, "isAlarmSet", false) and true or false
    local alarmHour = _callOr(item, "getHour", 6) or 6
    local gt = getGameTime()
    local st = self._st
    st.hour, st.minute = gt:getHour(), gt:getMinutes()
    st.running = speed > 0
    st.alarmOn = armed
    st.setOpen = self._setOpen
    -- the light: a Timez glows (its lit picture replaces the dark one); a CaZio's bulb (des.light == "bulb")
    -- only warms the glass a little, so the dark stays and the bulb's picture goes over it
    local on = getTimestampMs() < (self._litUntil or 0)
    local isBulb = des.light == "bulb"
    st.lit = on and not isBulb
    st.bulb = on and isBulb
    st.dark = (not st.lit) and _isDark(gt:getTimeOfDay() or st.hour) or false
    st.bulbDay = st.bulb and not st.dark
    st.bulbNight = st.bulb and st.dark
    _reading(st.display, player, item, speed, self._setOpen, armed, alarmHour)
    -- (an add-on face with bad data logs once and is not drawn, rather than throwing every
    -- frame on an always-visible prop)
    local okD, eD = pcall(PLT.draw, self:_canvas(k), des, st, ctx)
    if not okD then ZeD.logOnce("watch plate " .. tostring(def and def.id), eD); return end
    self:_hitsFrom(des, st, k)
    self:_padDraw(speed)
end
function ZeD_Watch:render() end   -- (everything draws in prerender)

function ZeD_Watch:_act(id)
    local item = self._item
    if id:sub(1, 5) == "speed" and #id == 6 then _setSpeed(tonumber(id:sub(6))); return end   -- the belt's speed keys (B.speedKey)
    if id == "speed" then _actSpeed(); return end
    if id == "start" then _actStart(); return end   -- (both nothing on a server: _setSpeed)
    if not item then return end
    -- (the director, Nov 19 2026: "clicking the watch face, a single left mouse button click hides all but the time,
    -- temperature, and date ... A single left mouse button click again brings it back to full size. Clicking on the
    -- alarm set or not set allows them to set the alarm. Keep it super simple." The plain watch only.)
    if id == "fold" then self._plainThin = not self._plainThin; return end
    if id == "alarmline" then self._plainThin = false; self._setOpen = true; return end
    if id == "light" then
        if W.hasLight(self._def) then self._litUntil = getTimestampMs() + W.LIGHT_MS end   -- a watch without one: nothing
        return
    end
    if id == "alarmtoggle" then pcall(function() item:setAlarmSet(not item:isAlarmSet()) end); return end   -- (the Simple watch's set mode)
    if id == "alarm" then
        if self._setOpen then self._setOpen = false; return end
        pcall(function() item:setAlarmSet(not item:isAlarmSet()) end); return
    end
    if id == "set" or id == "crown" then self._setOpen = not self._setOpen; return end
    if id == "setup" then _alarmStep(item, 1); return end
    if id == "setdn" then _alarmStep(item, -1); return end
end

-- the popped watch's spot: where the player dragged it (kept per character, in
-- design units), else just above the small one, outer edges lined up
function ZeD_Watch:_placePopped(w, h)
    local T = ZeD.T
    local sc = (T and T.scale) or 1
    local x, y
    if self._dragAt then
        x, y = self._dragX, self._dragY
    else
        local p = getSpecificPlayer(self.playerNum)
        local saved = p and p:getModData().ZeD_WatchPop
        if saved and saved.x then
            x, y = saved.x * sc, saved.y * sc
        else
            local bx, by, bw, side = nil, nil, nil, nil
            if ZeD.Belt and ZeD.Belt.watchScreen then bx, by, bw, side = ZeD.Belt.watchScreen() end
            if not bx then return end
            x = (side == "left") and bx or (bx + bw - w)
            y = by - T.px(8) - h
        end
    end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    x = math.max(0, math.min(x, sw - w)); y = math.max(0, math.min(y, sh - h))
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)   -- a whole-pixel origin (a saved spot x a fractional scale lands between pixels)
    if self:getX() ~= x then self:setX(x) end
    if self:getY() ~= y then self:setY(y) end
end

function ZeD_Watch:onMouseDown(x, y)
    for _, hr in ipairs(self._hit or {}) do
        if x >= hr.x and x < hr.x + hr.w and y >= hr.y and y < hr.y + hr.h then
            pcall(function() ZeD.uiSound("UIActivateButton") end)
            local ok, err = pcall(self._act, self, hr.id)
            if not ok then print("[ZeD] Watch: action " .. tostring(hr.id) .. " failed: " .. tostring(err)) end
            self._popTouched = getTimestampMs()
            return true
        end
    end
    -- the popped watch: anything that is not a control drags it
    if self._belt and self._popped then
        self._dragAt = { mx = getMouseX(), my = getMouseY(), x = self:getX(), y = self:getY() }
        self._dragX, self._dragY = self:getX(), self:getY()
        self:setCapture(true)
        return true
    end
    return false
end

function ZeD_Watch:onMouseMove(dx, dy)
    local d = self._dragAt
    if not d then return end
    self._dragX = d.x + (getMouseX() - d.mx)
    self._dragY = d.y + (getMouseY() - d.my)
end
function ZeD_Watch:onMouseMoveOutside(dx, dy) self:onMouseMove(dx, dy) end

function ZeD_Watch:onMouseUp(x, y)
    local d = self._dragAt
    if not d then return false end
    self._dragAt = nil
    self:setCapture(false)
    if math.abs(self._dragX - d.x) + math.abs(self._dragY - d.y) >= 2 then
        local p = getSpecificPlayer(self.playerNum)
        local sc = (ZeD.T and ZeD.T.scale) or 1
        if p then p:getModData().ZeD_WatchPop = { x = self:getX() / sc, y = self:getY() / sc } end
    end
    return true
end
function ZeD_Watch:onMouseUpOutside(x, y) self:onMouseUp(x, y) end

-- ---------------------------------------------------------------------------
-- CONTROLLER (Nov 16 2026, punch list 251): the machine faces' "A grabs, D-pad turns" (TwoWayFull.lua). The D-pad
-- walks the watch's controls; A presses a key (Start, Alarm, Light, the set mode's - and +).
-- The setting key (SET, or the crown) and SPEED are grabbed with A: the D-pad then sets the alarm hour (Up / Right
-- one hour on, Down / Left one back; past 23 or before 0 is OFF) or the game speed (Up / Right faster, Down / Left
-- slower); A or B lets go, and letting go of the setting key closes the setting. B (nothing grabbed) gives the pad
-- back where it came from (the belt's watch, else the game) and tucks a popped watch away; Start pauses.
-- Ways in: the belt's watch (A) and the Character wheel's Use, Watch, Open the watch.
-- ---------------------------------------------------------------------------
local PAD_GRAB = { set = true, crown = true, speed = true }   -- the controls A grabs
local PAD_LAND = { "start", "set", "crown" }       -- where the pad lands first: the first of these there is
W.PAD_GRAB = PAD_GRAB

--- The pad of this watch's player is on it.
function ZeD_Watch:padOn()
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    return jd ~= nil and jd.focus == self
end

-- the focused control's click area this frame, nil when it is not there
function ZeD_Watch:_padHit()
    local id = self._padId
    if not id then return nil end
    for _, h in ipairs(self._hit or {}) do if h.id == id then return h end end
    return nil
end

-- the focus on a control that is there (a set mode's keys come and go; another watch has other controls)
function ZeD_Watch:_padSettle()
    if self:_padHit() then return end
    self._grab = false
    self._padId = nil
    local hits = self._hit or {}
    for _, id in ipairs(PAD_LAND) do
        for _, h in ipairs(hits) do if h.id == id then self._padId = id; return end end
    end
    if hits[1] then self._padId = hits[1].id end
end

--- The focused control is grabbed: the D-pad turns it.
function ZeD_Watch:padGrabbed() return self._grab == true and self._padId ~= nil and PAD_GRAB[self._padId] == true end

-- a grabbed control turned one step (d: +1 on, -1 back)
function ZeD_Watch:_padTurn(d)
    local id = self._padId
    if id == "speed" then
        local sp = _speed()
        if sp == 0 or _serverTime() then return end   -- (paused: Start runs it; a server sets the time)
        local n = math.max(1, math.min(SPEED_TOP, sp + d))
        if n ~= sp then W._lastRun = n; _setSpeed(n) end
        return
    end
    if self._item then _alarmStep(self._item, d) end
end

local function padSound() pcall(function() ZeD.uiSound("UISelectListItem") end) end

-- the D-pad: a grabbed control turns; anything else moves to the nearest control that way
function ZeD_Watch:_padDir(dx, dy, d)
    self._popTouched = getTimestampMs()
    if self:padGrabbed() then self:_padTurn(d); return end
    self:_padSettle()
    local TW = ZeD.TwoWay
    local best = TW and TW.nearest and TW.nearest(self._hit, self:_padHit(), dx, dy)
    if best then self._padId = best.id; self._grab = false; padSound() end
end
function ZeD_Watch:onJoypadDirLeft() self:_padDir(-1, 0, -1) end
function ZeD_Watch:onJoypadDirRight() self:_padDir(1, 0, 1) end
function ZeD_Watch:onJoypadDirUp() self:_padDir(0, -1, 1) end
function ZeD_Watch:onJoypadDirDown() self:_padDir(0, 1, -1) end

function ZeD_Watch:onJoypadDown(button, joypadData)
    if ZeD.padStart and ZeD.padStart(button, joypadData, self.playerNum) then return end   -- (Start pauses: punch list 263)
    self._popTouched = getTimestampMs()
    if button == Joypad.BButton then
        if self:padGrabbed() then self:_padLetGo(); padSound(); return end
        self:padLeave()
        return
    end
    if button ~= Joypad.AButton then return end
    self:_padSettle()
    local id = self._padId
    if not id then return end
    if self:padGrabbed() then self:_padLetGo(); padSound(); return end
    -- (the setting already open, by the mouse: its key closes it, as a click does)
    if PAD_GRAB[id] and not (id ~= "speed" and self._setOpen) then
        self._grab = true
        -- (the setting key grabbed opens the setting; it closes again on letting go)
        if id ~= "speed" and not self._setOpen then self._setOpen = true; self._grabOpened = true end
        padSound()
        return
    end
    pcall(function() ZeD.uiSound("UIActivateButton") end)
    local ok, err = pcall(self._act, self, id)
    if not ok then print("[ZeD] Watch: pad action " .. tostring(id) .. " failed: " .. tostring(err)) end
end

-- let go of the grabbed control (the setting it opened closes)
function ZeD_Watch:_padLetGo()
    if self._grabOpened then self._setOpen = false end
    self._grab, self._grabOpened = false, nil
end

function ZeD_Watch:onGainJoypadFocus(joypadData) self._popTouched = getTimestampMs() end
function ZeD_Watch:onLoseJoypadFocus(joypadData)
    if self:padGrabbed() then self:_padLetGo() end
    self._grab = false
end

--- The pad leaves the watch: back where it came from (the belt, from its watch), else to the game; a popped watch
--- tucks back onto the belt.
function ZeD_Watch:padLeave()
    if self._grab then self:_padLetGo() end
    local from = self._padFrom
    self._padFrom, self._padId = nil, nil
    if self._belt and self._popped then W.togglePop(false) end
    if not self:padOn() then return end
    if from and from.padReturn and from:padReturn() then return end
    setJoypadFocus(self.playerNum, nil)
end

--- Give the pad to the watch (the first player's): a belt watch pops up first. from: the element the pad came
--- from (the belt), which gets it back on B; nil: the game. Returns true when the watch took the pad.
function W.padOpen(pn, from)
    local inst = W._instance
    pn = pn or 0
    if not inst or pn ~= inst.playerNum or not (JoypadState and JoypadState.players and JoypadState.players[pn + 1]) then return false end
    if not inst:isVisible() then return false end
    local p = getSpecificPlayer(pn)
    if p and W.beltWatch(p) then W.togglePop(true) end
    inst._padFrom = from
    inst._padId, inst._grab, inst._grabOpened = nil, false, nil
    if from then from._padHandoff = true end   -- (the belt keeps its place while the watch has the pad)
    setJoypadFocus(pn, inst)
    if p then pcall(function() p:setJoypadIgnoreAimUntilCentered(true) end) end
    return true
end

-- the words for a control on the controller strip
function W.padLabel(id, speed)
    if id == "start" then return ZeD.tr((speed or 1) == 0 and "UI_ZeD_WatchPlain_Start" or "UI_ZeD_WatchPlain_Pause") end
    if id == "speed" then return ZeD.tr("UI_ZeD_WatchPlain_SpeedBtn") end
    if id == "alarm" then return ZeD.tr("UI_ZeD_WatchPlain_AlarmBtn") end
    if id == "alarmtoggle" then return ZeD.tr("UI_ZeD_WatchPlain_AlarmOnOff") end
    if id == "set" or id == "crown" then return ZeD.tr("UI_ZeD_WatchPlain_Set") end
    if id == "light" then return ZeD.tr("UI_ZeD_Belt_WatchLight") end
    if id == "setdn" then return "-" end
    if id == "setup" then return "+" end
    local n = id and id:match("^speed(%d)$")
    -- (the speed keys are the belt row's: their words, the game's own. Time buttons, the director, Nov 22 2026)
    if n then return W.speedWords(tonumber(n)) end
    return nil
end

-- the strip's prompts: the focused control (A and its name, or Grab; grabbed: the D-pad and its name, A / B Let go),
-- then B Close (one table, refilled each frame)
local _padItems, _pA, _pB, _pTurn, _pLetGo = {}, { glyph = "A" }, { glyph = "B" }, { pad = { "DU", "DD" } }, { glyph = "A B" }
function ZeD_Watch:padItems(speed)
    for i = #_padItems, 1, -1 do _padItems[i] = nil end
    local id = self._padId
    if self:padGrabbed() then
        _pTurn.label = (id == "speed") and ZeD.tr("UI_ZeD_WatchPlain_SpeedBtn") or ZeD.tr("UI_ZeD_WatchPlain_AlarmBtn")
        _pLetGo.label = ZeD.tr("UI_ZeD_Prompt_KnobLetGo")
        _padItems[1], _padItems[2] = _pTurn, _pLetGo
        return _padItems
    end
    if id then
        _pA.label = PAD_GRAB[id] and ZeD.tr("UI_ZeD_Prompt_KnobGrab") or (W.padLabel(id, speed) or ZeD.tr("UI_ZeD_RadioPrompt_Press"))
        _padItems[1] = _pA
    end
    _pB.label = ZeD.tr("UI_ZeD_Close")
    _padItems[#_padItems + 1] = _pB
    return _padItems
end

-- the pad's mark on its control and the strip (above a watch popped over the belt, below one in the corner); last
-- in prerender, so nothing covers them
local _markOpts, _markGrab = { focused = true }, { focused = true, solid = true }
function ZeD_Watch:_padDraw(speed)
    if not self:padOn() then return end
    self:_padSettle()
    local h = self:_padHit()
    if h then
        local o = self:padGrabbed() and _markGrab or _markOpts
        o.win = self
        ZeD.Focus.mark(self, h.x, h.y, h.w, h.h, o)
    end
    local PG = ZeD.PadGlyphs
    if PG and PG.drawStrip then
        local T = ZeD.T
        local items = self:padItems(speed)
        local w = self:getWidth()
        local sw = math.max(w, PG.stripW and PG.stripW(items, self.playerNum) or w)
        local sh, gap = PG.stripH(), T.px(3)
        local sy = (self._belt and self._popped) and (-gap - sh) or (self:getHeight() + gap)
        local sx = w - sw   -- (right edges lined up: the corner watch sits at the screen's right)
        local ax = self:getAbsoluteX() + sx
        if ax < 0 then sx = sx - ax end
        PG.drawStrip(self, sx, sy, sw, items)
    end
    if ZeD.Focus.drawOverlay then ZeD.Focus.drawOverlay(self, self) end
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------
--- Make the one watch panel (the first player's) and put it on screen; a second call returns the same one.
function W.install()
    if W._instance then return W._instance end
    local inst = ZeD_Watch:new(0)
    inst:initialise()
    -- (the first player's: adopt leaves it as it is; there for the day other players get a watch, PlayerTheme.lua)
    if ZeD.Theme and ZeD.Theme.adopt then ZeD.Theme.adopt(inst) end
    inst:addToUIManager()
    inst:setVisible(true)
    W._instance = inst
    print("[ZeD] Watch: plate watch installed (Java clock + speed controls parked)")
    return inst
end
--- The watch panel, or nil before the game starts.
function W.getInstance() return W._instance end

-- Safe mode (SafeMode.lua): the Java clock and speed controls go back where they
-- were and show; this watch hides. Taking over again shows it, and its next
-- prerender parks them again.
ZeD.Safe.register("watch", {
    leave = function()
        local inst = W._instance
        if inst then inst:setVisible(false) end
        if not getSpecificPlayer(0) then return end   -- the main menu: nothing was parked
        local clock = UIManager.getClock and UIManager.getClock()
        if clock then
            if W._clockY then clock:setY(W._clockY) end
            clock:setVisible(true)
        end
        -- (the speed controls stay hidden on a server: there they show at the top right and do nothing)
        local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
        if sc and not isClient() then
            if W._speedY then sc:setY(W._speedY) end
            sc:setVisible(true)
        end
    end,
    enter = function()
        local inst = W._instance
        if inst then inst:setVisible(true) end
    end,
})

Events.OnGameStart.Add(function() W._instance = nil; W.install() end)

-- On a server the game's speed controls do nothing, yet they showed at the top right from the join until the
-- watch's first drawing parked them: kept hidden there on every tick, whether a
-- watch is worn or not. The tick stands down in safe mode, whose leave keeps them hidden on a server too
Events.OnTick.Add(function()
    if not isClient() or ZeD.Safe.on("watch") then return end
    local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
    if sc and sc:isVisible() then pcall(sc.setVisible, sc, false) end
end)
