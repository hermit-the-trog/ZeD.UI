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
--                while st[src] equals p.when (true unless p.when is false)
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
--   sticker      the game's own Spiffo's decal on a die-cut backing
--                (ctx.sticker), when the car's script matches p.match
--   headunit     the radio fitted in a dash's slot (st.radio, ctx.heads)
--   climate      a dash's climate readout (st.heaterTemp, heaterOn, ac, fan)
--   meter        the taxi's fare (st.fare)
--   radioDisplay a radio's readout, field by field, from st.display (the
--                reading ZeD.RadioOps.displayReading hands over; nil = off)
--   rangeText    a two-way set's RANGE line (st.range)
--   slotDisc     a disc's edge in a CD slot (st.hasMedia)
--   tape         preset names in ballpoint on masking tape (st.tapeNames),
--                in the game's handwriting font
--
-- ctx — what the organism lends the parts: tex(name) -> texture (its own
-- folder), sprites (the tab sprites' sizes), badge, scriptLow, sticker, heads
-- (the dash's radio faces), pending (the head unit adds its controls here) and
-- now (ms, for the marquees).
--
-- Click areas (des.hits): { id, x, y, w, h, kind, needs } in plate pixels.
-- kind "press" (a key or a switch: A presses it), "turn" (a knob: the wheel
-- and the D-pad turn it), "look" (part of the look: no control). A control
-- with needs waits for st[needs] (an oven's keys need power).
-- ============================================================================

require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_RadioOps"

ZeD = ZeD or {}
ZeD.Plate = ZeD.Plate or {}
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
    local tag = (r.flash and blinkOn(250)) and r.flash:gsub("STORE ", "P") or (r.scanning and "SCAN") or (r.muted and "MUTE") or nil
    if hp.style == "seg" then
        if ham then
            local freq = RO.freqText(r.channel, true)                        -- "098.400"
            P.digits(cv, freq, x + w - 3 - 6 * 9, y + 3, 6, 11, 9, 1, c, ghost, "l", 6)
            P.text(cv, "CH" .. (r.presetIdx and string.format("%02d", r.presetIdx) or "--"), x + 3, y + 3, c)
            P.text(cv, tag or (r.micMuted and "MIC" or "TX"), x + 3, y + 10, c)
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
            local nm = (r.name and r.name:upper()) or (r.presetIdx and r.presets[r.presetIdx] and r.presets[r.presetIdx].name and r.presets[r.presetIdx].name:upper()) or ""
            l2 = (r.flash and r.flash) or (r.muted and "MUTE") or (nm ~= "" and nm) or (r.micMuted and "MIC OFF" or "TX OK")
        else
            l1 = "FM " .. RO.freqText(r.channel, false) .. " MHZ"
            l2 = r.flash or (r.scanning and "SCAN") or (r.muted and "MUTE") or (r.name and r.name:upper()) or ""
        end
        local n1 = math.floor((w - 3) / 6)
        local n2 = math.floor((w - 3) / 4)
        P.text(cv, l1:sub(1, n1), x + 2, y + 1, c, "57")
        P.text(cv, RO.marquee(l2, n2), x + 2, y + 10, c, "35")
    end
end

local function headUnit(cv, st, hu, ctx)
    local RO = ZeD.RadioOps
    local pending = ctx.pending or {}
    local r = st.radio
    local H = r and ctx.heads and ctx.heads[r.kind]
    if not H then
        P.image(cv, ctx.tex("hu_blank"), hu.x, hu.y, hu.w, hu.h)
        return
    end
    P.image(cv, ctx.tex(H.tex), hu.x, hu.y, H.w, H.h)
    for _, hp in ipairs(H.parts) do
        if hp.t == "display" then
            headDisplay(cv, hp, hu.x, hu.y, r)
            pending[#pending + 1] = { "radio", hu.x + hp.x - 2, hu.y + hp.y - 2, hp.w + 4, hp.h + 4, true }
        elseif hp.t == "knob" then
            local deg = (hp.id == "vol") and (135 + 270 * clamp01(r.volume)) or ((((r.channel or 0) / RO.STEP) * 12) % 360)
            P.pointer(cv, hu.x + hp.cx, hu.y + hp.cy, deg, 3, hp.r - 2, 1, P.color(hp.ptr))
            pending[#pending + 1] = { hp.id, hu.x + hp.cx - hp.r, hu.y + hp.cy - hp.r, hp.r * 2, hp.r * 2, true }
        elseif hp.t == "button" then
            pending[#pending + 1] = { hp.id, hu.x + hp.x, hu.y + hp.y, hp.w, hp.h, true }
        elseif hp.t == "sprite" then
            -- a state picture (the makeshift rocker on, the talk/listen switch latched in); micLive is the switch's
            -- place, set while the microphone is live whether or not the set is on
            local v
            if hp.src == "micLive" then v = not r.micMuted else v = r[hp.src] end
            if (v and true or false) == (hp.when ~= false) then P.image(cv, ctx.tex(hp.tex), hu.x + hp.x, hu.y + hp.y, hp.w, hp.h) end
        elseif hp.t == "lamp" then
            if r.on and r[hp.src] then
                local c = P.color(hp.color)
                if hp.halo then P.rects(cv, hp.halo, c, 0.30, hu.x, hu.y) end
                P.rects(cv, hp.r, c, 1, hu.x, hu.y)
            end
        elseif hp.t == "tape" then
            -- the ValuTech's preset names in ballpoint on the masking tape under the keys
            local ink = P.color(hp.color)
            for i = 1, hp.n do
                local pr = r.presets and r.presets[i]
                local nm = pr and pr.name and RO.tapeName(pr.name):upper() or ""     -- the slot's small letters are capitals
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
local function radioDisplay(cv, p, st, ctx)
    local rd = st.display
    if not rd then
        -- off: a liquid-crystal glass has lost its backlight
        if p.style == "char" or p.style == "lcd" then P.rect(cv, p.x, p.y, p.w, p.h, P.BLACK, 0.45) end
        return
    end
    local ox, oy = p.x, p.y
    local col = P.color(p.color)
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

function PL.drawParts(cv, parts, st, ctx)
    ctx = ctx or {}
    for _, p0 in ipairs(parts) do
        local p = inLight(p0, st)
        local t = p.t
        if t == "needle" then
            local f = math.max(0, math.min(p.peg and 1.02 or 1, frac(st, p)))
            local a = p.a0 + (p.a1 - p.a0) * f
            local c = P.color((p.low_src and st[p.low_src]) and LOW or p.color)
            P.needle(cv, p.cx, p.cy, a, p.r0, p.r1, p.w or 2, p.hub or 0, c)
        elseif t == "ribbon" then
            local f = clamp01(frac(st, p))
            local xx = math.floor(p.x0 + (p.x1 - p.x0) * f + 0.5)
            if p.mode == "fill" then
                if xx > p.x0 then
                    P.rect(cv, p.x0, p.y, xx - p.x0, p.h, P.color(p.color))
                    P.rect(cv, p.x0, p.y, xx - p.x0, 1, P.shade(p.color, 1.25))
                    P.rect(cv, p.x0, p.y + p.h - 1, xx - p.x0, 1, P.shade(p.color, 0.6))
                end
            else
                P.rect(cv, xx + 1, p.y + 2, 2, p.h, P.BLACK, 0.45)
                P.rect(cv, xx - 1, p.y, 1, p.h, P.color(p.color)); P.rect(cv, xx, p.y, 1, p.h, P.shade(p.color, 0.6))
            end
        elseif t == "lamp" then
            if st[p.src] then
                local c = P.color(p.color)
                if p.halo then P.rects(cv, p.halo, c, 0.30) end
                P.rects(cv, p.r, c)
            end
        elseif t == "led" then
            if st[p.src] then P.rect(cv, p.x, p.y, p.w, p.h, P.color(p.color)) end
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
            P.pointer(cv, p.cx, p.cy, a, p.r0, p.r1, p.w or 1, P.color(p.color))
        elseif t == "tab" then
            local spr = ctx.tex(p.sprite)
            local sz = ctx.sprites and ctx.sprites[p.sprite]
            if spr and sz then
                local x = math.floor(p.x0 + (p.x1 - p.x0) * clamp01(st[p.src] or 0) + 0.5)
                P.image(cv, spr, x, p.y, sz[1], sz[2])
            end
        elseif t == "sprite" then
            local on = st[p.src] and true or false
            if on == (p.when ~= false) then P.image(cv, ctx.tex(p.sprite), p.x, p.y, p.w, p.h) end
        elseif t == "badge" then
            local label = ctx.badge and ctx.badge[p.role] or ""
            if label ~= "" then
                local s, font, scale = P.fit(label, p.font or "35", p.scale or 1, p.w)
                local x = p.x + ((p.align or "c") == "c" and math.floor(p.w / 2) or 0)
                local y = p.y + math.floor((p.h - P.fontHeight(font) * scale) / 2)
                if p.style == "emboss" then P.text(cv, s, x + 1, y + 1, P.color("#f0f0ec"), font, scale, p.align or "c") end
                P.text(cv, s, x, y, P.color(p.color or "#d8dade"), font, scale, p.align or "c", p.style, p.shadow)
            end
        elseif t == "clock" then
            local h, m = st.hour or 10, st.minute or 0
            local am = m * 6 - 90
            local ah = (h % 12) * 30 + m * 0.5 - 90
            local c = P.color(p.color)
            P.pointer(cv, p.cx, p.cy, ah, 0, p.rh, 2, c, 1.5)
            P.pointer(cv, p.cx, p.cy, am, 0, p.rm, 1, c, 1.5)
        elseif t == "sticker" then
            local S = ctx.sticker
            if S and ctx.scriptLow and ctx.scriptLow:find(p.match or "spiffo", 1, true) then
                local stx = P.tex(S.tex)
                if stx then
                    local bx = p.x + math.floor((p.w - (S.w + 2 * S.pad)) / 2)
                    local by = p.y + math.floor((p.h - (S.h + 2 * S.pad)) / 2)
                    P.rects(cv, S.backing, P.color(S.rim), 1, bx + 1, by + 1)
                    P.rects(cv, S.backing, P.color(S.color), 1, bx, by)
                    P.image(cv, stx, bx + S.pad, by + S.pad, S.w, S.h)
                end
            end
        elseif t == "headunit" then
            headUnit(cv, st, p, ctx)
        elseif t == "climate" then
            if st.power then
                local c = P.color(p.color or "#1c2418")
                local tC = math.floor(21 + (st.heaterTemp or 0) * 0.28 + 0.5)
                if (p.units or "C") == "F" then tC = math.floor(tC * 9 / 5 + 32 + 0.5) end
                P.digits(cv, tostring(tC), p.x, p.y, 7, 11, 9, 1, c, nil, "l", 2)
                P.text(cv, st.heaterOn and (st.ac and "A/C" or "AUTO") or "OFF", p.x + 21, p.y, c)
                P.text(cv, "FAN" .. tostring(st.fan or 0), p.x + 21, p.y + 6, c)
            end
        elseif t == "meter" then
            if st.power then
                local f = st.fare or 0
                P.digits(cv, string.format("%.2f", math.min(99.99, f)), p.x, p.y, p.cw or 6, p.ch or 9, p.pitch or 9, 1, P.color(p.color), nil, "r", 4)
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

-- the cue over a control (focus, hover, a key held): a ring round a knob, a
-- fill over a key; c = colour, a = alpha
function PL.cue(cv, h, c, a)
    if h.kind == "turn" then
        local r = math.min(h.w, h.h) / 2
        P.ring(cv, h.x + h.w / 2, h.y + h.h / 2, r + 1, r + 3, c, a)
    else
        P.rect(cv, h.x, h.y, h.w, h.h, c, a)
    end
end

-- the whole multiple a plate is drawn at for a UI scale, and the screen offset
-- that centres a plate w plate pixels wide in a span of aw screen pixels
function PL.k(scale) return P.k(scale) end
function PL.centre(aw, w, k) return math.floor((aw - w * k) / 2) end

return PL
