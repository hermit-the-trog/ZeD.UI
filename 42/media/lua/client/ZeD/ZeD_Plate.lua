-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Plate.lua
-- ============================================================================
-- PLATE — the template every pixel-art machine in ZeD draws with: the vehicle
-- dashboards, the ovens and microwaves (the Craft tab), the generators and the
-- propane grill (the object cards), and the car radios and the siren
-- controller up close (director, Oct 16 2026: one shared plate template).
--
-- A plate is one fixed-size picture (ZeDUI/tools paints it as a lit height
-- field: one plate pixel = one screen pixel at 1080p, a whole multiple k above,
-- see ZeD_PixelParts) plus data: its LIVE PARTS, drawn over the picture from
-- the machine's state, and its CLICK AREAS. The data is generated:
-- ZeD/DashPx.lua for the dashboards, ZeD/PhysPx.lua for the other machines.
-- An organism reads the game into one flat state table (st), hands it to
-- PL.draw, and acts on the click areas; it draws no part of the machine itself.
--
-- Live parts (p.t) and what they read (st[p.src] unless noted):
--   sprite       a state picture (a key held down, a cord plugged in), drawn
--                while st[src] reads p.when: a flag (true unless p.when is
--                false), or one value of several when p.when is a string or a
--                number (the key's "off" / "on" / "start", a frame number)
--   needle       a gauge needle (lit side, shaded side, its shadow) at
--                a0 + (a1 - a0) * st[src] / max; st[low_src] turns it red
--   ptr          a knob's pointer line: angles[st[src] + 1] for a switch with
--                stops, else a0 + (a1 - a0) * st[src] (a fraction)
--   lamp         a lamp's lit pixels and their halo, while st[src]
--   led          a small lit rect, while st[src]
--   digits       seven-segment figures while st.power (or p.always): a number
--                (rounded; fmt "rpm100" counts hundreds) or a string as it is
--                ("10:08"); p.ghost draws the unlit segments
--   bars         a bar graph, st[src] / max of the bars lit (while st.power);
--                red_from / warn_from colour the top bars
--   ribbon       a moving strip (mode "fill") or a marker along x0 .. x1
--   gear         the automatic's selector letter (st.gearSel)
--   tab          a lever's tab sprite sliding along x0 .. x1
--   clock        an analog clock's hands (st.hour, st.minute)
--   badge        a maker's badge line: ctx.badge[p.role], fitted to p.w
--   sticker      a business van's logo, the game's own decal on a die-cut
--                backing (ctx.logo, the one the organism picked; none: blank)
--   headunit     the radio fitted in a dash's slot (st.radio, ctx.heads)
--   climate      a dash's climate readout (st.heaterTemp, heaterOn, ac, fan)
--   meter        the taxi's fare meter: st[src] as dollars and cents in p.digits
--                cells while the flag is down (st.meterOn); the flag up leaves
--                the plate's dark figures
--   radioDisplay a radio's readout, field by field, from st.display (the
--                reading ZeD.RadioOps.displayReading hands over; nil = off)
--   rangeText    a two-way set's RANGE line (st.range)
--   slotDisc     a disc's edge in a CD slot (st.hasMedia)
--   tape         preset names in ballpoint on masking tape (st.tapeNames),
--                in the game's handwriting font
--
-- ctx — what the organism lends the parts: tex(name) -> texture (its own
-- folder), sprites (the tab sprites' sizes), badge, scriptLow, logo, heads
-- (the dash's radio faces), pending (the head unit adds its controls here),
-- now (ms, for the marquees) and light (the night light, below; only the
-- dashboards lend one).
--
-- Click areas (des.hits): { id, x, y, w, h, kind, needs } in plate pixels.
-- kind "press" (a key or a switch: A presses it), "turn" (a knob: the wheel
-- and the D-pad turn it), "look" (part of the look: no control). A control
-- with needs waits for st[needs] (an oven's keys need power).
-- ============================================================================

require "ZeD/Tr"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_RadioOps"

ZeD = ZeD or {}
ZeD.Plate = ZeD.Plate or {}
ZeD.trDefaults({
    UI_ZeD_Dash_ClimateAc = "A/C", UI_ZeD_Dash_ClimateAuto = "AUTO", UI_ZeD_Dash_ClimateOff = "OFF", UI_ZeD_Dash_ClimateFan = "FAN%1",
})
local PL = ZeD.Plate
local P = ZeD.Px

local function clamp01(v) if v == nil then return 0 end; if v < 0 then return 0 end; if v > 1 then return 1 end; return v end
PL.clamp01 = clamp01

-- a part's reading as a fraction of its scale (true reads 1, false 0)
local function frac(st, p)
    local v = st[p.src]
    if type(v) == "boolean" then v = v and 1 or 0 end
    return (v or 0) / (p.max or 1)
end
PL.frac = frac

-- ---------------------------------------------------------------------------
-- the night light (the dashboards; director, Oct 21 2026: no gauge is
-- backlit, a few small incandescent bulbs in the panel's corners and a lamp
-- under the brow light what they can). The art is baked (ZeDUI/tools/dashpx/
-- night.py); ctx.light carries what the frame needs:
--   n8      how dark it is at the car, in eighths (0 = day: nothing changes)
--   lit     the dash lights are on (vanilla's headlight switch, with power)
--   over    the plate picture laid over the day one at n8 / 8 (the night
--           plate with the bulbs on, the dark one without)
--   map     the light map, one hex digit (0..levels) per cell x cell plate
--           pixels, cols a row; amb the level everywhere when the bulbs are
--           off; tint the bulb's colour { r, g, b } (a list)
--   glass   the backlit LCD glass: { color, r = rects } redrawn while st.power
-- A part that makes no light (needles, pointers, tabs, the key, badges, the
-- clock's hands, the radio's face) takes its colour times the multiplier of
-- the map's level under it; lamps, LEDs and displays keep their own.
-- ---------------------------------------------------------------------------
local _mul = {}          -- [0 or 1][n8][level] -> { r, g, b }, made once
local function mulFor(L, level)
    local li = L.lit and 1 or 0
    local byLit = _mul[li]
    if not byLit then byLit = {}; _mul[li] = byLit end
    local byN = byLit[L.n8]
    if not byN then byN = {}; byLit[L.n8] = byN end
    local m = byN[level]
    if not m then
        local n = L.n8 / 8
        local f = level / (L.levels or 15)
        local t = L.lit and L.tint or nil
        m = { r = (1 - n) + n * f * (t and t[1] or 1), g = (1 - n) + n * f * (t and t[2] or 1), b = (1 - n) + n * f * (t and t[3] or 1) }
        byN[level] = m
    end
    return m
end

-- the map's level at a plate point, bulbs on
local function levelRaw(L, x, y)
    if not L.map then return L.amb or 1 end
    local cell = L.cell or 4
    local c = math.floor(x / cell)
    local r = math.floor(y / cell)
    if c < 0 then c = 0 elseif c >= L.cols then c = L.cols - 1 end
    if r < 0 then r = 0 elseif r >= L.rows then r = L.rows - 1 end
    local b = string.byte(L.map, r * L.cols + c + 1) or 48
    if b >= 97 then return b - 87 end
    return b - 48
end
-- the level a part gets: the map's while the bulbs are on, the ambient level while they are off
local function levelAt(L, x, y)
    if not L.lit then return L.amb or 1 end
    return levelRaw(L, x, y)
end
local function lightMul(L, x, y) return mulFor(L, levelAt(L, x, y)) end
local function dim(L, c, x, y) return P.mulColor(c, mulFor(L, levelAt(L, x, y))) end
PL.lightLevel, PL.lightMul, PL.dim = levelAt, lightMul, dim

-- the radio's face in the dark: tinted to the light of its brightest cell row, every row below that darkened to
-- its own (the lamp above lights the top of the set, the lower edge falls away); the rows are worked out once
local function headRows(L, hu, w, h)
    local rows = hu._lightRows
    if rows and hu._lightMap == L.map then return rows end
    rows = {}
    local cell = L.cell or 4
    local r0, r1 = math.floor(hu.y / cell), math.floor((hu.y + h - 1) / cell)
    local c0, c1 = math.floor(hu.x / cell), math.floor((hu.x + w - 1) / cell)
    for r = r0, r1 do
        local sum, n = 0, 0
        for c = c0, c1 do sum = sum + levelRaw(L, c * cell, r * cell); n = n + 1 end
        local y0 = math.max(hu.y, r * cell)
        local y1 = math.min(hu.y + h, (r + 1) * cell)
        rows[#rows + 1] = { y0, y1 - y0, math.floor(sum / math.max(1, n) + 0.5) }
    end
    hu._lightRows, hu._lightMap = rows, L.map
    return rows
end
local function lum(m) return 0.3 * m.r + 0.59 * m.g + 0.11 * m.b end
local function headFace(cv, tex, hu, w, h, L)
    if not tex then return end
    local rows = headRows(L, hu, w, h)
    local top = 0
    for i = 1, #rows do
        local lv = L.lit and rows[i][3] or (L.amb or 1)
        if lv > top then top = lv end
    end
    local mt = mulFor(L, top)
    P.imageTint(cv, tex, hu.x, hu.y, w, h, mt)
    local lt = lum(mt)
    if lt <= 0 then return end
    for i = 1, #rows do
        local lv = L.lit and rows[i][3] or (L.amb or 1)
        if lv < top then
            local a = math.floor((1 - lum(mulFor(L, lv)) / lt) * 8 + 0.5) / 8
            if a > 0 then P.rect(cv, hu.x, rows[i][1], w, rows[i][2], P.BLACK, a) end
        end
    end
end

local LOW = "#ff4a3a"                                -- a needle's colour while its warning reads
local MISSING = { r = 0.1, g = 0.1, b = 0.1 }       -- the plate's stand-in when its picture is missing
local function blinkOn(ms) return math.floor(getTimestampMs() / (ms or 250)) % 2 == 0 end

-- a line that marches left a character at a time when it is too long (1993 displays did)
local function marquee(str, n, now)
    str = tostring(str or "")
    if #str <= n then return str end
    local loop = str .. "   "
    local k = math.floor((now or 0) / 320) % #loop
    return (loop .. loop):sub(k + 1, k + n)
end
PL.marquee = marquee

-- ---------------------------------------------------------------------------
-- the dash's head unit: the fitted radio's small face, its display in pixel
-- figures (the same reading the radio up close shows), its knob pointers; its
-- controls go to ctx.pending for the organism to register
-- ---------------------------------------------------------------------------
local function headDisplay(cv, hp, ox, oy, r)
    local RO = ZeD.RadioOps
    local x, y, w, h = ox + hp.x, oy + hp.y, hp.w, hp.h
    local c = P.color(hp.color)
    local ham = RO.HAM[hp.kind] == true
    if not r.on then
        if hp.style == "dot" then P.rect(cv, x - 2, y - 2, w + 4, h + 4, P.BLACK, 0.45) end   -- the backlight is out
        return
    end
    local ghost = hp.ghost and P.color(hp.ghost) or nil
    local tag = (r.flash and blinkOn(250)) and r.flashShort or (r.scanning and RO.word("scan")) or (r.muted and RO.word("mute")) or nil
    if hp.style == "seg" then
        if ham then
            local freq = RO.freqText(r.channel, true)                        -- "098.400"
            P.digits(cv, freq, x + w - 3 - 6 * 9, y + 3, 6, 11, 9, 1, c, ghost, "l", 6)
            P.text(cv, "CH" .. (r.presetIdx and string.format("%02d", r.presetIdx) or "--"), x + 3, y + 3, c)
            P.text(cv, tag or (r.micMuted and RO.word("mic") or "TX"), x + 3, y + 10, c)
        else
            local cd = r.playing
            local txt
            if cd then
                local s = math.floor((r.cdMs or 0) / 1000)
                txt = string.format("%d:%02d", math.floor(s / 60) % 100, s % 60)
            else
                txt = RO.freqText(r.channel, false)                             -- "98.4", "101.2"
            end
            local nfig = 0
            for i = 1, #txt do local ch = txt:sub(i, i); if ch ~= "." and ch ~= ":" then nfig = nfig + 1 end end
            local n = math.max(nfig, 3)
            P.digits(cv, txt, x + w - 3 - n * 10 - (cd and 4 or 0), y + 2, 7, 13, 10, 2, c, ghost, "r", n)
            P.text(cv, cd and "CD" or "FM", x + 3, y + 3, c)
            local t2 = tag or ((not cd) and r.presetIdx and r.presetIdx <= 6 and ("P" .. r.presetIdx)) or nil
            if t2 then P.text(cv, t2, x + 3, y + 10, c) end
            if r.signal and not cd then
                for i = 1, 3 do P.rect(cv, x + 13 + (i - 1) * 2, y + 8 - i * 2 + 1, 1, i * 2, c) end
            end
        end
    else
        local l1, l2
        if ham then
            l1 = "CH" .. (r.presetIdx and string.format("%02d", r.presetIdx) or "--") .. " " .. RO.freqText(r.channel, true)
            local nm = (r.name and ZeD.upper(r.name)) or (r.presetIdx and r.presets[r.presetIdx] and r.presets[r.presetIdx].name and ZeD.upper(r.presets[r.presetIdx].name)) or ""
            l2 = (r.flash and r.flash) or (r.muted and RO.word("mute")) or (nm ~= "" and nm) or (r.micMuted and RO.word("micOff") or RO.word("txOk"))
        else
            l1 = "FM " .. RO.freqText(r.channel, false) .. " MHZ"
            l2 = r.flash or (r.scanning and RO.word("scan")) or (r.muted and RO.word("mute")) or (r.name and ZeD.upper(r.name)) or ""
        end
        local n1 = math.floor((w - 3) / 6)
        local n2 = math.floor((w - 3) / 4)
        P.text(cv, l1:sub(1, n1), x + 2, y + 1, c, "57")
        P.text(cv, RO.marquee(l2, n2), x + 2, y + 10, c, "35")
    end
end

-- L: the night light (nil by day): the face follows the lamp above it, a lit liquid-crystal glass glows from behind
local function headUnit(cv, st, hu, ctx, L)
    local RO = ZeD.RadioOps
    local pending = ctx.pending or {}
    local r = st.radio
    local H = r and ctx.heads and ctx.heads[r.kind]
    if not H then
        if L then headFace(cv, ctx.tex("hu_blank"), hu, hu.w, hu.h, L)
        else P.image(cv, ctx.tex("hu_blank"), hu.x, hu.y, hu.w, hu.h) end
        return
    end
    if L then headFace(cv, ctx.tex(H.tex), hu, H.w, H.h, L)
    else P.image(cv, ctx.tex(H.tex), hu.x, hu.y, H.w, H.h) end
    for _, hp in ipairs(H.parts) do
        if hp.t == "display" then
            if L and hp.glass and r.on then P.rect(cv, hu.x + hp.x, hu.y + hp.y, hp.w, hp.h, P.color(hp.glass), L.n8 / 8) end
            headDisplay(cv, hp, hu.x, hu.y, r)
            pending[#pending + 1] = { "radio", hu.x + hp.x - 2, hu.y + hp.y - 2, hp.w + 4, hp.h + 4, true }
        elseif hp.t == "knob" then
            local deg = (hp.id == "vol") and (135 + 270 * clamp01(r.volume)) or ((((r.channel or 0) / RO.STEP) * 12) % 360)
            local pc = P.color(hp.ptr)
            if L then pc = dim(L, pc, hu.x + hp.cx, hu.y + hp.cy) end
            P.pointer(cv, hu.x + hp.cx, hu.y + hp.cy, deg, 3, hp.r - 2, 1, pc)
            pending[#pending + 1] = { hp.id, hu.x + hp.cx - hp.r, hu.y + hp.cy - hp.r, hp.r * 2, hp.r * 2, true }
        elseif hp.t == "button" then
            pending[#pending + 1] = { hp.id, hu.x + hp.x, hu.y + hp.y, hp.w, hp.h, true }
        elseif hp.t == "sprite" then
            -- a state picture (the makeshift rocker on, the talk/listen switch latched in); micLive is the switch's
            -- place, set while the microphone is live whether or not the set is on
            local v
            if hp.src == "micLive" then v = not r.micMuted else v = r[hp.src] end
            if (v and true or false) == (hp.when ~= false) then
                if L then P.imageTint(cv, ctx.tex(hp.tex), hu.x + hp.x, hu.y + hp.y, hp.w, hp.h, lightMul(L, hu.x + hp.x + hp.w / 2, hu.y + hp.y + hp.h / 2))
                else P.image(cv, ctx.tex(hp.tex), hu.x + hp.x, hu.y + hp.y, hp.w, hp.h) end
            end
        elseif hp.t == "lamp" then
            if r.on and r[hp.src] then
                local c = P.color(hp.color)
                if hp.halo then P.rects(cv, hp.halo, c, 0.30, hu.x, hu.y) end
                P.rects(cv, hp.r, c, 1, hu.x, hu.y)
            end
        elseif hp.t == "tape" then
            -- the ValuTech's preset names in ballpoint on the masking tape under the keys
            local ink = P.color(hp.color)
            if L then ink = dim(L, ink, hu.x + hu.w / 2, hu.y + hp.y) end
            for i = 1, hp.n do
                local pr = r.presets and r.presets[i]
                local nm = pr and pr.name and ZeD.upper(RO.tapeName(pr.name)) or ""     -- the slot's small letters are capitals
                if nm ~= "" then
                    local s = P.fit(nm, "35", 1, hp.w - 2)
                    P.text(cv, s, hu.x + hp.first + (i - 1) * hp.pitch, hu.y + hp.y, ink, "35", 1, "c")
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- a radio's readout up close: each field of the display's layout, from the
-- reading the radio's workings hand over
--   seg    seven-segment figures (x is the right edge unless align "l")
--   text   5 x 7 (or 3 x 5) letters; w caps the line, marquee marches it
--   cells  a character display's cells (5 x 7, the unlit cell ghosted)
--   bars   signal bars rising left to right
--   tri    the CD's play triangle
-- ---------------------------------------------------------------------------
-- a CaZio's bulb on a negative display (light figures on dark glass): the figures carry the light, so the
-- figure colour's rects take each step's colour left of its edge (p.bulbDay / p.bulbNight: { x, c } from the
-- display's left edge), split where a rect crosses an edge; the ghost and everything else pass untouched.
-- A stand-in canvas element (kept on the part) forwards to the real one.
local ZONE_EL = {}
ZONE_EL.__index = ZONE_EL
function ZONE_EL:drawRect(x, y, w, h, a, r, g, b)
    local real = self.real
    if w <= 0 or r ~= self.cr or g ~= self.cg or b ~= self.cb then real:drawRect(x, y, w, h, a, r, g, b); return end
    local zs, k, x0 = self.zones, self.k, self.x0
    local cx, right = x, x + w
    for i = 1, #zs do
        if cx >= right then return end
        local edge = x0 + zs[i].x * k
        if cx < edge then
            local e = math.min(edge, right)
            local c = P.color(zs[i].c)
            real:drawRect(cx, y, e - cx, h, a, c.r, c.g, c.b)
            cx = e
        end
    end
    if cx < right then real:drawRect(cx, y, right - cx, h, a, r, g, b) end
end
function ZONE_EL:drawTextZoomed(...) return self.real:drawTextZoomed(...) end

local function zoneCanvas(cv, p, zones, col)
    local z = p._zoneCv
    if not z then
        z = { el = setmetatable({}, ZONE_EL), ox = 0, oy = 0, k = 1 }
        p._zoneCv = z
    end
    local el = z.el
    el.real, el.zones, el.k, el.x0 = cv.el, zones, cv.k, cv.ox + p.x * cv.k
    el.cr, el.cg, el.cb = col.r, col.g, col.b
    el._zedAlpha = cv.el._zedAlpha
    z.ox, z.oy, z.k = cv.ox, cv.oy, cv.k
    return z
end

local function radioReadout(cv, p, st, ctx)
    local rd = st.display
    if not rd then
        -- off: a liquid-crystal glass has lost its backlight
        if p.style == "char" or p.style == "lcd" then P.rect(cv, p.x, p.y, p.w, p.h, P.BLACK, 0.45) end
        return
    end
    local ox, oy = p.x, p.y
    local col = P.color(p.color)
    local zones = st.bulb and (st.dark and p.bulbNight or p.bulbDay) or nil
    if zones then cv = zoneCanvas(cv, p, zones, col) end
    local ghost = p.ghost and P.color(p.ghost) or nil
    local now = ctx and ctx.now or 0
    for _, f in ipairs(p.fields or {}) do
        if not (f.when and not rd[f.when]) then
            local t = f.t
            if t == "seg" then
                local v = rd[f.src] ~= nil and tostring(rd[f.src]) or ""
                if v ~= "" then
                    local right = (f.align or "r") == "r"
                    P.digits(cv, v, ox + f.x - (right and f.n * f.pitch or 0), oy + f.y, f.cw, f.ch, f.pitch, f.st or 1, col,
                        f.ghost and ghost or nil, right and "r" or "l", f.n)
                end
            elseif t == "text" then
                local v = rd[f.src] ~= nil and tostring(rd[f.src]) or ""
                if v ~= "" then
                    if f.w then
                        local n = math.max(1, math.floor((f.w + 1) / 6))
                        if f.marquee then v = marquee(v, n, now) else v = v:sub(1, n) end
                    end
                    P.text(cv, v, ox + f.x, oy + f.y, col, f.font or "57", 1, f.align or "l")
                end
            elseif t == "cells" then
                local v = rd[f.src] ~= nil and tostring(rd[f.src]) or ""
                if f.marquee then v = marquee(v, f.cols, now) end
                for i = 1, f.cols do
                    local cx = ox + f.x + (i - 1) * f.pitch
                    if ghost then P.rect(cv, cx, oy + f.y, 5, 7, ghost) end
                    local ch = v:sub(i, i)
                    if ch ~= "" and ch ~= " " then
                        -- a narrow letter sits in the middle of its cell, as on the real glass
                        P.text(cv, ch, cx + math.floor((5 - P.textWidth(ch, "57", 1)) / 2), oy + f.y, col, "57", 1, "l")
                    end
                end
            elseif t == "bars" then
                local lit = tonumber(rd[f.src]) or 0
                for i = 0, f.n - 1 do
                    local bh = f.h0 + i * f.dh
                    local c = (i < lit) and col or ghost
                    if c then P.rect(cv, ox + f.x + i * (f.bw + f.gap), oy + f.y - bh, f.bw, bh, c) end
                end
            elseif t == "tri" then
                local sz = f.size
                local mid = math.floor(sz * 0.6)
                for i = 0, sz - 1 do
                    local hh = math.floor((sz - i) * 0.6)
                    P.rect(cv, ox + f.x + i, oy + f.y + mid - hh, 1, math.max(1, hh * 2), col)
                end
            end
        end
    end
end

-- a two-way set with a LAMP key (p.lamp = its backlight's colour): while lit (st.lampLit) the glass glows under
-- the figures; in the dark (st.dark) and unlit it can hardly be read
local function radioDisplay(cv, p, st, ctx)
    local lamp = p.lamp
    if lamp and st.lampLit and st.display then P.rect(cv, p.x, p.y, p.w, p.h, P.color(lamp), 0.35) end
    radioReadout(cv, p, st, ctx)
    if lamp and st.dark and not st.lampLit then P.rect(cv, p.x, p.y, p.w, p.h, P.BLACK, 0.6) end
end

-- the presets' names on the masking tape, in the game's handwriting, each
-- squeezed to its own key's width as a hand would
local TAPE_INK = { r = 0.114, g = 0.176, b = 0.478 }   -- blue ballpoint
local TAPE_JIT = { 0, 1, 0, -1, 1, 0 }                  -- a hand never writes level
local TAPE_LINE = 15                                    -- the writing's line height (plate pixels)
local function tape(cv, p, st)
    local names = st.tapeNames
    local X = ZeD.Text
    local f = UIFont and UIFont.Handwritten
    if not (names and X and X.realTM and f) then return end
    local tm = X.realTM()
    local fh = tm:getFontHeight(f)
    local k = cv.k
    for i = 1, 6 do
        local name = names[i]
        if name and name ~= "" then
            local z = TAPE_LINE * k / math.max(1, fh)
            local room = (p.pitch - 5) * k
            local tw = tm:MeasureStringX(f, name) * z
            if tw > room then z = z * room / tw end
            local lineH = fh * z
            cv.el:drawTextZoomed(name, cv.ox + math.floor((p.first + 1 + (i - 1) * p.pitch) * k),
                cv.oy + math.floor((p.y + p.h / 2 + TAPE_JIT[i] * 0.5) * k - lineH / 2), z, TAPE_INK.r, TAPE_INK.g, TAPE_INK.b, 0.92, f)
        end
    end
end

-- ---------------------------------------------------------------------------
-- the parts, in the order the data lists them (state sprites first, so the
-- live parts draw over them)
-- ---------------------------------------------------------------------------
-- a part in the dark or under a watch's light: its "night" or "lit" colours over
-- its own (merged once and kept on the part, so a frame allocates nothing)
local function inLight(p, st)
    if st.lit and p.lit then
        local q = p._litPart
        if not q then q = {}; for k, v in pairs(p) do q[k] = v end; for k, v in pairs(p.lit) do q[k] = v end; p._litPart = q end
        return q
    elseif st.dark and p.night then
        local q = p._nightPart
        if not q then q = {}; for k, v in pairs(p) do q[k] = v end; for k, v in pairs(p.night) do q[k] = v end; p._nightPart = q end
        return q
    end
    return p
end

-- a moving strip in the dark: a cell's width at a time, each in the light it lies in
-- (neighbouring cells in the same light are drawn as one stretch: the same pixels in the same colours, fewer rects;
-- Oct 22 2026, the drawing-cost work)
local function ribbonLit(cv, p, xx, L)
    local c0, c1, c2 = P.color(p.color), P.shade(p.color, 1.25), P.shade(p.color, 0.6)
    local cy = p.y + p.h / 2
    local step = L.cell or 4
    local x0 = p.x0
    local sx, sw, sm = nil, 0, nil          -- the stretch so far: its start, width and light
    while true do
        local w, m = 0, nil
        if x0 < xx then
            w = math.min(step, xx - x0)
            m = lightMul(L, x0 + w / 2, cy)
        end
        if sx and (m ~= sm or w == 0) then
            P.rect(cv, sx, p.y, sw, p.h, P.mulColor(c0, sm))
            P.rect(cv, sx, p.y, sw, 1, P.mulColor(c1, sm))
            P.rect(cv, sx, p.y + p.h - 1, sw, 1, P.mulColor(c2, sm))
            sx = nil
        end
        if w == 0 then break end
        if sx then sw = sw + w else sx, sw, sm = x0, w, m end
        x0 = x0 + step
    end
end

function PL.drawParts(cv, parts, st, ctx)
    ctx = ctx or {}
    local L = ctx.light
    if L and (L.n8 or 0) <= 0 then L = nil end             -- the day: every part exactly as it was
    if L then L.dim = dim end                               -- (what ZeD.Px's lit needle asks for each run)
    for _, p0 in ipairs(parts) do
        local p = inLight(p0, st)
        local t = p.t
        if t == "needle" then
            local f = math.max(0, math.min(p.peg and 1.02 or 1, frac(st, p)))
            local a = p.a0 + (p.a1 - p.a0) * f
            local c = P.color((p.low_src and st[p.low_src]) and LOW or p.color)
            P.needle(cv, p.cx, p.cy, a, p.r0, p.r1, p.w or 2, p.hub or 0, c, nil, L)
        elseif t == "ribbon" then
            local f = clamp01(frac(st, p))
            local xx = math.floor(p.x0 + (p.x1 - p.x0) * f + 0.5)
            if p.mode == "fill" then
                if xx > p.x0 then
                    if L then ribbonLit(cv, p, xx, L)
                    else
                        P.rect(cv, p.x0, p.y, xx - p.x0, p.h, P.color(p.color))
                        P.rect(cv, p.x0, p.y, xx - p.x0, 1, P.shade(p.color, 1.25))
                        P.rect(cv, p.x0, p.y + p.h - 1, xx - p.x0, 1, P.shade(p.color, 0.6))
                    end
                end
            else
                local c0, c1 = P.color(p.color), P.shade(p.color, 0.6)
                if L then local m = lightMul(L, xx, p.y + p.h / 2); c0, c1 = P.mulColor(c0, m), P.mulColor(c1, m) end
                P.rect(cv, xx + 1, p.y + 2, 2, p.h, P.BLACK, 0.45)
                P.rect(cv, xx - 1, p.y, 1, p.h, c0); P.rect(cv, xx, p.y, 1, p.h, c1)
            end
        elseif t == "lamp" then
            -- (a state that is a colour lights the lamp in it: the dash's lamps by condition, ZeD_Dashboard D.derive)
            local on = st[p.src]
            if on then
                local c = P.color(type(on) == "string" and on or p.color)
                if p.halo then P.rects(cv, p.halo, c, 0.30) end
                P.rects(cv, p.r, c)
            end
        elseif t == "led" then
            local on = st[p.src]
            if on then P.rect(cv, p.x, p.y, p.w, p.h, P.color(type(on) == "string" and on or p.color)) end
        elseif t == "gear" then
            if st.power then
                local rr = p.letters[st.gearSel]
                if rr then P.rects(cv, rr, P.color(p.color)) end
            end
        elseif t == "bars" then
            if st.power then
                local n = math.floor(clamp01(frac(st, p)) * #p.bars + 0.5)
                for i = 1, n do
                    local c = p.color
                    if p.red_from and (i - 1) >= p.red_from then c = p.red or "#ff3a20"
                    elseif p.warn_from and (i - 1) >= p.warn_from then c = p.warn or "#ffb02e" end
                    P.rects(cv, p.bars[i], P.color(c))
                end
            end
        elseif t == "digits" then
            if st.power or p.always then
                local v = st[p.src] or 0
                local txt
                if type(v) == "string" then txt = v
                elseif p.fmt == "rpm100" then txt = tostring(math.floor(v / 100 + 0.5))
                else txt = tostring(math.floor(v + 0.5)) end
                P.digits(cv, txt, p.x, p.y, p.cw, p.ch, p.pitch, p.st or 1, P.color(p.color), p.ghost and P.color(p.ghost) or nil, p.align or "r", p.n)
            end
        elseif t == "ptr" then
            local a
            if p.angles then
                local v = st[p.src]
                if type(v) == "boolean" then v = v and 1 or 0 end
                local i = math.max(1, math.min(#p.angles, math.floor((v or 0) + 0.5) + 1))
                a = p.angles[i]
            else
                a = p.a0 + (p.a1 - p.a0) * clamp01(st[p.src] or 0)
            end
            local c = P.color(p.color)
            if L then c = dim(L, c, p.cx, p.cy) end
            P.pointer(cv, p.cx, p.cy, a, p.r0, p.r1, p.w or 1, c)
        elseif t == "tab" then
            local spr = ctx.tex(p.sprite)
            local sz = ctx.sprites and ctx.sprites[p.sprite]
            if spr and sz then
                local x = math.floor(p.x0 + (p.x1 - p.x0) * clamp01(st[p.src] or 0) + 0.5)
                if L then P.imageTint(cv, spr, x, p.y, sz[1], sz[2], lightMul(L, x + sz[1] / 2, p.y + sz[2] / 2))
                else P.image(cv, spr, x, p.y, sz[1], sz[2]) end
            end
        elseif t == "sprite" then
            local w, on = p.when, nil
            local tw = type(w)
            if tw == "string" or tw == "number" then on = (st[p.src] == w)
            else on = ((st[p.src] and true or false) == (w ~= false)) end
            if on then
                if L then P.imageTint(cv, ctx.tex(p.sprite), p.x, p.y, p.w, p.h, lightMul(L, p.x + p.w / 2, p.y + p.h / 2))
                else P.image(cv, ctx.tex(p.sprite), p.x, p.y, p.w, p.h) end
            end
        elseif t == "badge" then
            local label = ctx.badge and ctx.badge[p.role] or ""
            if label ~= "" then
                local s, font, scale = P.fit(label, p.font or "35", p.scale or 1, p.w)
                local x = p.x + ((p.align or "c") == "c" and math.floor(p.w / 2) or 0)
                local y = p.y + math.floor((p.h - P.fontHeight(font) * scale) / 2)
                local m = L and lightMul(L, p.x + p.w / 2, p.y + p.h / 2) or nil
                if p.style == "emboss" then P.text(cv, s, x + 1, y + 1, P.mulColor(P.color("#f0f0ec"), m), font, scale, p.align or "c") end
                P.text(cv, s, x, y, P.mulColor(P.color(p.color or "#d8dade"), m), font, scale, p.align or "c", p.style,
                    (m and p.shadow) and P.mulColor(P.color(p.shadow), m) or p.shadow, m)
            end
        elseif t == "clock" then
            local h, m = st.hour or 10, st.minute or 0
            local am = m * 6 - 90
            local ah = (h % 12) * 30 + m * 0.5 - 90
            local c = P.color(p.color)
            if L then c = dim(L, c, p.cx, p.cy) end
            P.pointer(cv, p.cx, p.cy, ah, 0, p.rh, 2, c, 1.5)
            P.pointer(cv, p.cx, p.cy, am, 0, p.rm, 1, c, 1.5)
        elseif t == "sticker" then
            local S = ctx.logo
            if S then
                local stx = P.tex(S.tex)
                if stx then
                    local bx = p.x + math.floor((p.w - (S.w + 2 * S.pad)) / 2)
                    local by = p.y + math.floor((p.h - (S.h + 2 * S.pad)) / 2)
                    local m = L and lightMul(L, p.x + p.w / 2, p.y + p.h / 2) or nil
                    P.rects(cv, S.backing, P.mulColor(P.color(S.rim), m), 1, bx + 1, by + 1)
                    P.rects(cv, S.backing, P.mulColor(P.color(S.color), m), 1, bx, by)
                    if m then P.imageTint(cv, stx, bx + S.pad, by + S.pad, S.w, S.h, m)
                    else P.image(cv, stx, bx + S.pad, by + S.pad, S.w, S.h) end
                end
            end
        elseif t == "headunit" then
            headUnit(cv, st, p, ctx, L)
        elseif t == "climate" then
            if st.power then
                local c = P.color(p.color or "#1c2418")
                local tC = math.floor(21 + (st.heaterTemp or 0) * 0.28 + 0.5)
                if (p.units or "C") == "F" then tC = math.floor(tC * 9 / 5 + 32 + 0.5) end
                P.digits(cv, tostring(tC), p.x, p.y, 7, 11, 9, 1, c, nil, "l", 2)
                P.text(cv, st.heaterOn and (st.ac and ZeD.tr("UI_ZeD_Dash_ClimateAc") or ZeD.tr("UI_ZeD_Dash_ClimateAuto")) or ZeD.tr("UI_ZeD_Dash_ClimateOff"), p.x + 21, p.y, c)
                P.text(cv, ZeD.tr("UI_ZeD_Dash_ClimateFan", tostring(st.fan or 0)), p.x + 21, p.y + 6, c)
            end
        elseif t == "meter" then
            if st.power and st.meterOn then
                local n = p.digits or 5
                local f = math.max(0, math.min(10 ^ (n - 2) - 0.01, tonumber(st[p.src or "fare"]) or 0))
                P.digits(cv, string.format("%.2f", f), p.x, p.y, p.cw or 6, p.ch or 9, p.pitch or 9, 1, P.color(p.color), nil, "r", n)
            end
        elseif t == "radioDisplay" then
            radioDisplay(cv, p, st, ctx)
        elseif t == "rangeText" then
            if st.range and st.range ~= "" then P.text(cv, st.range, p.x, p.y, P.color(p.color), "35", 1, "c") end
        elseif t == "slotDisc" then
            if st.hasMedia then P.rect(cv, p.x, p.y, p.w, 1, P.color(p.color)) end
        elseif t == "tape" then
            tape(cv, p, st)
        end
    end
end

-- the plate's picture, then its live parts; w, h = the plate's size (des.w, des.h unless given)
function PL.draw(cv, des, st, ctx, w, h)
    w, h = w or des.w, h or des.h
    local plate = ctx.tex(des.plate)
    if plate then P.image(cv, plate, 0, 0, w, h)
    else P.rect(cv, 0, 0, w, h, MISSING) end         -- the art missing: never let the machine vanish
    -- at night: the plate in the dark (its bulbs on or off) over the day one, then the LCD glass lit from behind
    local L = ctx.light
    if L and (L.n8 or 0) > 0 then
        L.dim = dim
        local a = L.n8 / 8
        local over = L.over and ctx.tex(L.over)
        if over then P.image(cv, over, 0, 0, w, h, a) end
        if st.power and L.glass then
            for i = 1, #L.glass do local g = L.glass[i]; P.rects(cv, g.r, P.color(g.color), a) end
        end
    end
    PL.drawParts(cv, des.parts, st, ctx)
end

-- ---------------------------------------------------------------------------
-- click areas
-- ---------------------------------------------------------------------------
-- the plate's controls in this state (the look-only areas left out): a list of
-- { id, x, y, w, h, kind, enabled } in plate pixels
function PL.controls(des, st, out)
    out = out or {}
    for _, h in ipairs(des.hits or {}) do
        local kind = h.kind or "press"
        if kind ~= "look" then
            out[#out + 1] = { id = h.id, x = h.x, y = h.y, w = h.w, h = h.h, kind = kind,
                              enabled = (h.needs == nil) or (st[h.needs] and true or false) }
        end
    end
    return out
end

-- the control under a point (plate pixels), the last listed first
function PL.at(list, x, y)
    for i = #list, 1, -1 do
        local h = list[i]
        if x >= h.x and x < h.x + h.w and y >= h.y and y < h.y + h.h then return h end
    end
    return nil
end

-- the control with this id
function PL.find(list, id)
    for _, h in ipairs(list or {}) do if h.id == id then return h end end
    return nil
end

-- the cue over a control: a ring round a knob (the knob's own light, which
-- stays), a fill over a key; c = colour, a = alpha. A key's held shade
-- (P.BLACK) is drawn through here too. A key's pointer wash and the
-- controller's focus mark are PL.hoverKey and PL.markKey, not this.
function PL.cue(cv, h, c, a)
    if h.kind == "turn" then
        local r = math.min(h.w, h.h) / 2
        P.ring(cv, h.x + h.w / 2, h.y + h.h / 2, r + 1, r + 3, c, a)
    else
        P.rect(cv, h.x, h.y, h.w, h.h, c, a)
    end
end

-- the pointer over a key: the library's hover wash (T.hover). A knob keeps its ring.
function PL.hoverKey(cv, h)
    local hv = ZeD.T.hover
    P.rect(cv, h.x, h.y, h.w, h.h, hv, hv.a or 0.2)
end

-- the controller on a key: the chosen focus look (ZeD.Focus.mark) over the key's rect, in
-- panel pixels (the plate's top-left at (ox, oy), k screen pixels to a plate pixel). Call it
-- after the plate is drawn; the mark's top part comes with the window's overlay pass, or with
-- ZeD.Focus.drawOverlay(panel, panel) at the end of a prop's own render. opts as ZeD.Focus.mark
-- ({ win, focused = true for a prop with a focus model of its own }).
function PL.markKey(panel, h, ox, oy, k, opts)
    return ZeD.Focus.mark(panel, ox + h.x * k, oy + h.y * k, h.w * k, h.h * k, opts)
end

-- the whole multiple a plate is drawn at for a UI scale, and the screen offset
-- that centres a plate w plate pixels wide in a span of aw screen pixels
function PL.k(scale) return P.k(scale) end
function PL.centre(aw, w, k) return math.floor((aw - w * k) / 2) end

return PL
