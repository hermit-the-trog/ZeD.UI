-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Watch.lua
-- ============================================================================
-- CAZIO WATCH (S123) — the HUD clock, built from scratch in ZeD language.
--
-- Replaces the Java clock (UIManager.getClock()) visually: same footprint
-- and position (top-right), same rule (only drawn while a wrist watch is
-- worn), same clock-format option. The face comes from the worn item:
--   WristWatch_*_Digital{Black,Red,Dress} -> CaZio LCD module
--   WristWatch_*_Classic{Black,Brown,Gold,Military} -> analog dial
--   WristWatch_*_Expensive -> ivory analog dial with a date window
-- Mockup: ZeDUI/mockups/zed_cazio_watch_v1.html. Hook row: HOOK_MAP.md #7.
--
-- Lua-flat: fills, 1px borders, text. Analog hands are short runs of 2x2
-- rects along the hand vector (no line primitive needed, no AA).
-- ============================================================================

require "ZeD/ZeD_Panel"

ZeD = ZeD or {}
ZeD.Watch = ZeD.Watch or {}
local W = ZeD.Watch

local MONTHS = { "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" }
local DAYS   = { "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" }

-- Face palettes (flat colours; no gradients).
local FACES = {
    digitalblack  = { kind = "digital", bg = { r = 0.05, g = 0.10, b = 0.05 }, fg = { r = 0.27, g = 0.93, b = 0.27 }, brand = "CAZIO" },
    digitalred    = { kind = "digital", bg = { r = 0.10, g = 0.05, b = 0.05 }, fg = { r = 0.93, g = 0.33, b = 0.33 }, brand = "CAZIO" },
    digitaldress  = { kind = "digital", bg = { r = 0.06, g = 0.08, b = 0.09 }, fg = { r = 0.87, g = 0.90, b = 0.93 }, brand = "CAZIO" },
    classicblack  = { kind = "analog",  bg = { r = 0.08, g = 0.08, b = 0.08 }, fg = { r = 0.90, g = 0.89, b = 0.86 }, brand = "TIMEKS" },
    classicbrown  = { kind = "analog",  bg = { r = 0.16, g = 0.11, b = 0.07 }, fg = { r = 0.90, g = 0.85, b = 0.77 }, brand = "TIMEKS" },
    classicgold   = { kind = "analog",  bg = { r = 0.23, g = 0.18, b = 0.06 }, fg = { r = 0.94, g = 0.82, b = 0.44 }, brand = "TIMEKS" },
    classicmilitary = { kind = "analog", bg = { r = 0.11, g = 0.14, b = 0.09 }, fg = { r = 0.73, g = 0.79, b = 0.64 }, brand = "TIMEKS", military = true },
    expensive     = { kind = "analog",  bg = { r = 0.94, g = 0.93, b = 0.88 }, fg = { r = 0.08, g = 0.08, b = 0.08 }, brand = "ROLLEX", date = true, gold = true },
}

-- Find the worn wrist watch (AlarmClockClothing on a wrist location).
local function _wornWatch(player)
    if not player then return nil end
    local ok, worn = pcall(player.getWornItems, player)
    if not ok or not worn then return nil end
    for i = 0, worn:size() - 1 do
        local w = worn:get(i)
        local item = w and w:getItem()
        if item and instanceof(item, "AlarmClockClothing") then
            local loc = tostring(w:getLocation() or "")
            if loc:lower():find("wrist") then return item end
        end
    end
    return nil
end

local function _faceFor(item)
    if not item then return nil end
    local t = tostring(item:getFullType() or ""):lower()
    for key, face in pairs(FACES) do
        if t:find(key, 1, true) then return face end
    end
    -- Unknown watch mod/variant: digital if the item says so, else classic.
    local okD, dig = pcall(item.isDigital, item)
    return (okD and dig) and FACES.digitalblack or FACES.classicblack
end

-- Zeller (Gregorian). month 1-12, day 1-31 -> 1 = Sunday.
local function _dayOfWeek(y, m, d)
    if m < 3 then m = m + 12; y = y - 1 end
    local k, j = y % 100, math.floor(y / 100)
    local h = (d + math.floor(13 * (m + 1) / 5) + k + math.floor(k / 4) + math.floor(j / 4) + 5 * j) % 7
    return ((h + 6) % 7) + 1   -- 0=Sat in Zeller -> shift so 1=Sun
end

local function _timeStrings()
    local gt = getGameTime()
    local hour = gt:getHour()
    local min  = gt:getMinutes()
    -- Options: getOptionClock24Hour (24h vs 12h) and getOptionClockFormat
    -- (1 = Month/Day, 2 = Day/Month) are two different settings.
    local fmt24 = true
    local ok24, v24 = pcall(function() return getCore():getOptionClock24Hour() end)
    if ok24 and v24 == false then fmt24 = false end
    local monthFirst = true
    local okF, f = pcall(function() return getCore():getOptionClockFormat() end)
    if okF and f == 2 then monthFirst = false end
    local timeStr, suffix
    if fmt24 then
        timeStr = string.format("%02d:%02d", hour, min); suffix = "24H"
    else
        local h12 = hour % 12; if h12 == 0 then h12 = 12 end
        timeStr = string.format("%d:%02d", h12, min); suffix = (hour >= 12) and "PM" or "AM"
    end
    local day   = (gt:getDay() or 0) + 1
    local month = (gt:getMonth() or 0) + 1
    local year  = gt:getYear() or 1993
    local dow   = DAYS[_dayOfWeek(year, month, day)] or ""
    local dateStr
    if monthFirst then dateStr = string.format("%s %s %02d %d", dow, MONTHS[month] or "", day, year)
    else dateStr = string.format("%s %02d %s %d", dow, day, MONTHS[month] or "", year) end
    return timeStr, suffix, dateStr, hour, min, day, dow
end
W._timeStrings = _timeStrings   -- exposed for QA probes

-- Hand = run of small rects from (cx,cy) along angle (0 = 12 o'clock, clockwise).
local function _drawHand(panel, cx, cy, angle, length, thick, c)
    local dx, dy = math.sin(angle), -math.cos(angle)
    local steps = math.max(1, math.floor(length))
    for i = 0, steps do
        local x = cx + dx * i
        local y = cy + dy * i
        panel:drawRect(math.floor(x - thick / 2), math.floor(y - thick / 2), thick, thick, 1, c.r, c.g, c.b)
    end
end

-- ---------------------------------------------------------------------------
-- The organism
-- ---------------------------------------------------------------------------
ZeD_Watch = ZeD_Panel:derive("ZeD_Watch")

function ZeD_Watch:new(playerNum)
    local o = ZeD_Panel:new(0, 0, 156, 62)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum or 0
    o._zedLabel = "Watch"
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor     = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

function ZeD_Watch:prerender()
    local T = ZeD.T
    local player = getSpecificPlayer(self.playerNum)
    local clock  = UIManager.getClock()

    -- ZeD owns the clock: keep the Java one hidden while this organism lives.
    if clock and clock.isVisible and clock:isVisible() then pcall(clock.setVisible, clock, false) end

    if not player or (ISUIHandler and ISUIHandler.allUIVisible == false) then return end
    local item = _wornWatch(player)
    if not item then return end
    local face = _faceFor(item)
    if not face then return end

    -- Footprint and position: the Java clock's (so nothing around it moves).
    local w, h = 156, 62
    local x, y
    if clock and clock.getWidth then
        w = math.max(120, clock:getWidth()); h = math.max(48, clock:getHeight())
        x, y = clock:getX(), clock:getY()
    else
        x = getPlayerScreenLeft(self.playerNum) + getPlayerScreenWidth(self.playerNum) - w - 10
        y = getPlayerScreenTop(self.playerNum) + 10
    end
    if self:getX() ~= x then self:setX(x) end
    if self:getY() ~= y then self:setY(y) end
    if self:getWidth() ~= w then self:setWidth(w) end
    if self:getHeight() ~= h then self:setHeight(h) end

    local timeStr, suffix, dateStr, hour, min, day, dow = _timeStrings()
    local tm = getTextManager()
    local s2 = T.surf2; local bd = T.border
    local dim = T.textDim

    -- Chassis
    self:drawRect(0, 0, w, h, s2.a, s2.r, s2.g, s2.b)
    self:drawRectBorder(0, 0, w, h, bd.a, bd.r, bd.g, bd.b)

    if face.kind == "digital" then
        -- LCD module
        local lx, ly, lw, lh = 8, 6, w - 16, math.floor(h * 0.55)
        self:drawRect(lx, ly, lw, lh, 1, face.bg.r, face.bg.g, face.bg.b)
        self:drawRectBorder(lx, ly, lw, lh, 1, 0, 0, 0)
        local font = T.fontF4
        local th = tm:getFontHeight(font)
        self:drawText(timeStr, lx + 6, ly + math.floor((lh - th) / 2), face.fg.r, face.fg.g, face.fg.b, 1, font)
        local tw = tm:MeasureStringX(font, timeStr)
        self:drawText(suffix, lx + 6 + tw + 6, ly + lh - tm:getFontHeight(T.fontF5) - 3, face.fg.r, face.fg.g, face.fg.b, 0.8, T.fontF5)
        -- Alarm set: red square
        local okA, alarmOn = pcall(item.isAlarmSet, item)
        if okA and alarmOn then local dg = T.danger; self:drawRect(w - 14, 9, 5, 5, 1, dg.r, dg.g, dg.b) end
        -- Date line + brand
        self:drawText(dateStr, 8, h - tm:getFontHeight(T.fontF5) - 3, dim.r, dim.g, dim.b, 1, T.fontF5)
        local bw = tm:MeasureStringX(T.fontF5, face.brand)
        self:drawText(face.brand, w - 8 - bw, h - tm:getFontHeight(T.fontF5) - 3, 0.33, 0.33, 0.33, 1, T.fontF5)
    else
        -- Analog dial
        local d = h - 10
        local dx, dy = 8, 5
        self:drawRect(dx, dy, d, d, 1, face.bg.r, face.bg.g, face.bg.b)
        self:drawRectBorder(dx, dy, d, d, 1, 0, 0, 0)
        local cx, cy = dx + d / 2, dy + d / 2
        local fg = face.fg
        -- 12 / 3 / 6 / 9 ticks
        self:drawRect(math.floor(cx), dy + 2, 1, 5, 1, fg.r, fg.g, fg.b)
        self:drawRect(math.floor(cx), dy + d - 7, 1, 5, 1, fg.r, fg.g, fg.b)
        self:drawRect(dx + 2, math.floor(cy), 5, 1, 1, fg.r, fg.g, fg.b)
        self:drawRect(dx + d - 7, math.floor(cy), 5, 1, 1, fg.r, fg.g, fg.b)
        -- Hands
        local hourAngle = ((hour % 12) + min / 60) / 12 * 2 * math.pi
        local minAngle  = (min / 60) * 2 * math.pi
        _drawHand(self, cx, cy, hourAngle, d * 0.28, 2, fg)
        _drawHand(self, cx, cy, minAngle,  d * 0.40, 1, fg)
        self:drawRect(math.floor(cx) - 1, math.floor(cy) - 1, 3, 3, 1, fg.r, fg.g, fg.b)
        if face.date then
            local dw, dh = 13, 9
            self:drawRect(dx + d - dw - 5, math.floor(cy) - math.floor(dh / 2), dw, dh, 1, face.bg.r, face.bg.g, face.bg.b)
            self:drawRectBorder(dx + d - dw - 5, math.floor(cy) - math.floor(dh / 2), dw, dh, 1, fg.r, fg.g, fg.b)
            self:drawText(tostring(day), dx + d - dw - 3, math.floor(cy) - math.floor(dh / 2) - 1, fg.r, fg.g, fg.b, 1, T.fontF5)
        end
        -- Readout to the right of the dial
        local tx = dx + d + 10
        local tc = face.gold and { r = 0.94, g = 0.82, b = 0.44 } or T.text
        local shown = face.military and (string.format("%02d%02d", hour, min)) or timeStr
        self:drawText(shown, tx, 10, tc.r, tc.g, tc.b, 1, T.fontF1)
        local sub = face.military and ("HRS - " .. dow) or ((suffix == "24H") and dow or suffix)
        if face.date then sub = dateStr end
        self:drawText(sub, tx, 10 + tm:getFontHeight(T.fontF1) + 2, dim.r, dim.g, dim.b, 1, T.fontF5)
        local bw = tm:MeasureStringX(T.fontF5, face.brand)
        self:drawText(face.brand, w - 8 - bw, h - tm:getFontHeight(T.fontF5) - 3, 0.33, 0.33, 0.33, 1, T.fontF5)
    end
end

function ZeD_Watch:render() end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------
function W.install()
    if W._instance then return W._instance end
    local inst = ZeD_Watch:new(0)
    inst:initialise()
    inst:addToUIManager()
    W._instance = inst
    print("[ZeD] Watch: CaZio HUD clock installed (Java clock parked)")
    return inst
end

function W.getInstance() return W._instance end

Events.OnGameStart.Add(function()
    W._instance = nil   -- fresh world, fresh UI manager
    W.install()
end)
