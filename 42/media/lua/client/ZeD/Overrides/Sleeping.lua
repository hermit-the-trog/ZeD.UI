-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Sleeping.lua
-- ============================================================================
-- ASLEEP (HOOK_MAP row 16; mockup zed_fish_sleep_death_v5, director Oct 16
-- 2026: "sleep clock should be the oldschool red number clock")
--
-- Vanilla's ISSleepingUI stays: the engine darkens the screen, vanilla shows
-- its panel on every sleeping tick with the hour of the day and removes it on
-- waking. In place of its clock picture (a new one every ten minutes) ZeD
-- draws a 1980s clock radio: woodgrain, chrome bezel, smoked glass, red
-- seven-segment numbers by the minute, the AM / PM dot, the colon blinking
-- once a second, the ALARM lamp lit while an alarm is set (an alarm clock or
-- a watch the character set). The case is a plate (media/textures/ZeD/props/
-- clock_radio.png, 330 x 84 plate pixels; Design's plate pipeline draws the
-- final one); the lit segments are drawn live on it at whole multiples.
-- While ZeD's safe mode is on, vanilla's clock picture draws instead.
-- ============================================================================

require "ISUI/ISSleepingUI"
require "ZeD/SafeMode"

if not ISSleepingUI then return end

ZeD = ZeD or {}
ZeD.SleepClock = ZeD.SleepClock or {}
local S = ZeD.SleepClock

S.TEX = "media/textures/ZeD/props/clock_radio.png"
S.W, S.H = 330, 84
-- where the live parts sit on the plate (plate pixels)
local DX, DY = 36, 26                       -- the numbers' top left
local DIGIT_X = { 0, 22, 52, 74 }           -- the four digits
local DW, DH, DT = 16, 34, 3                -- a digit's width, height, stroke
local COLON = { { 44, 9 }, { 44, 22 } }
local AMPM = { am = { 25, 29 }, pm = { 25, 54 } }
local ALARM = { DX + 96, DY + 28 }
local LIT = { r = 1.0, g = 0.2, b = 0.133 }
local GLOW = { r = 0.353, g = 0.071, b = 0.047 }
local SEG = { [0] = "abcdef", "bc", "abdeg", "abcdg", "bcfg", "acdfg", "acdefg", "abc", "abcdefg", "abcdfg" }

-- an alarm set on anything the character carries or wears (vanilla's alarm clocks and watches)
local function alarmSet(playerObj)
    local found = false
    local function scan(inv, depth)
        if found or depth > 3 then return end
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            -- (only alarm clocks and watches have an alarm: ask nothing else)
            local ok, on = false, false
            if instanceof(it, "AlarmClock") or instanceof(it, "AlarmClockClothing") then ok, on = pcall(function() return it:isAlarmSet() end) end
            if ok and on then found = true; return end
            if instanceof(it, "InventoryContainer") then scan(it:getInventory(), depth + 1) end
        end
    end
    pcall(scan, playerObj:getInventory(), 0)
    return found
end

local function seg(self, ox, oy, k, x, y, w, h)
    self:drawRect(ox + (x - 1) * k, oy + (y - 1) * k, (w + 2) * k, (h + 2) * k, 1, GLOW.r, GLOW.g, GLOW.b)
    self:drawRect(ox + x * k, oy + y * k, w * k, h * k, 1, LIT.r, LIT.g, LIT.b)
end

local function digit(self, ox, oy, k, n, x, y)
    local on = SEG[n] or ""
    local half = math.floor(DH / 2)
    local rects = {
        a = { x + 2, y, DW - 4, DT }, d = { x + 2, y + DH - DT, DW - 4, DT }, g = { x + 2, y + half - 1, DW - 4, DT },
        b = { x + DW - DT, y + 2, DT, half - 3 }, c = { x + DW - DT, y + half + 1, DT, half - 3 },
        f = { x, y + 2, DT, half - 3 }, e = { x, y + half + 1, DT, half - 3 },
    }
    for i = 1, #on do
        local r = rects[on:sub(i, i)]
        seg(self, ox, oy, k, r[1], r[2], r[3], r[4])
    end
end

-- the clock radio at (ox, oy) in the panel, k screen pixels a plate pixel
function S.draw(self, ox, oy, k, hourOfDay, alarm)
    -- nearest filtering (3), so the pixel art stays square at 3x / 6x (Oct 16 2026: getTexture smoothed it)
    local tex = Texture.getSharedTexture(S.TEX, 3)
    if not tex then return false end
    self:drawTextureScaledAspect(tex, ox, oy, S.W * k, S.H * k, 1, 1, 1, 1)
    local h24 = math.floor(hourOfDay or 0) % 24
    local mm = math.floor(((hourOfDay or 0) - math.floor(hourOfDay or 0)) * 60 + 0.001) % 60
    local pm = h24 >= 12
    local h12 = h24 % 12; if h12 == 0 then h12 = 12 end
    -- (a 1980s clock blanks the leading zero of the hour)
    if h12 >= 10 then digit(self, ox, oy, k, math.floor(h12 / 10), DX + DIGIT_X[1], DY) end
    digit(self, ox, oy, k, h12 % 10, DX + DIGIT_X[2], DY)
    digit(self, ox, oy, k, math.floor(mm / 10), DX + DIGIT_X[3], DY)
    digit(self, ox, oy, k, mm % 10, DX + DIGIT_X[4], DY)
    if (getTimestampMs() % 1000) < 500 then
        for _, c in ipairs(COLON) do seg(self, ox, oy, k, DX + c[1], DY + c[2], 3, 3) end
    end
    local d = pm and AMPM.pm or AMPM.am
    seg(self, ox, oy, k, d[1], d[2], 3, 3)
    if alarm then seg(self, ox, oy, k, ALARM[1], ALARM[2], 3, 3) end
    return true
end

local _render = ISSleepingUI._zedOrigRender or ISSleepingUI.render
ISSleepingUI._zedOrigRender = _render

function ISSleepingUI:render()
    if ZeD.Safe.on() then return _render(self) end   -- safe mode: vanilla's clock
    ISPanel.render(self)
    local pn = self.playerIndex
    local w, h = getPlayerScreenWidth(pn), getPlayerScreenHeight(pn)
    -- whole multiples: 3 at 1080p, 6 at 4K
    local root = (ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) or (h / 1080)
    local k = math.max(1, math.floor(3 * root + 0.001))
    local pw, ph = S.W * k, S.H * k
    local ox = math.floor((w - pw) / 2)
    local oy = math.floor((h - ph) / 2)
    -- (the alarm is looked up once a second, not every frame)
    local now = getTimestampMs()
    if not self._zedAlarmAt or now - self._zedAlarmAt > 1000 then
        self._zedAlarmAt = now
        local p = getSpecificPlayer(pn)
        self._zedAlarm = p and alarmSet(p) or false
    end
    local ok, drawn = pcall(S.draw, self, ox, oy, k, self.hourOfDay, self._zedAlarm)
    if not (ok and drawn) then
        if not ok then ZeD.logOnce("sleep clock", drawn) end
        return _render(self)
    end
end

print("[ZeD] Overrides/Sleeping: the sleep clock is a red-number clock radio")
