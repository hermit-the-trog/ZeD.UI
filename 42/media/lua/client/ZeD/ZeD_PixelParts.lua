-- ZeD-UI/42/media/lua/client/ZeD/ZeD_PixelParts.lua
-- ============================================================================
-- PIXEL PARTS — the shelf atom for ZeD's pixel-art organisms (the dashboards first;
-- the belt buckles, the main menu desk and the radios share the same density rule).
--
-- One art pixel is one screen pixel at 1080p and a whole multiple k above it, so
-- every pixel stays square. Pixel art loads with nearest filtering
-- (Texture.getSharedTexture(path, 3): FILTER_MIN_NEAREST 1 + FILTER_MAG_NEAREST 2,
-- KB Q205). Everything live is drawn the same way the art was painted: rects on
-- the art grid. A needle is rasterised into art pixels (a lit side and a shaded
-- side, its shadow below), seven-segment figures are segment rects, and text uses
-- the two pixel fonts (ZeD/PixelFonts.lua): 3 x 5 for legends, 5 x 7 for badges.
--
-- A "canvas" binds an element, the screen offset of the art's origin inside it,
-- and the multiple: cv = P.canvas(self, 0, 0, k). Every coordinate after that is
-- in art pixels. Colours are "#rrggbb" strings, converted once and cached.
-- ============================================================================

require "ZeD/PixelFonts"
require "ZeD/PixelFontsExt"

ZeD = ZeD or {}
ZeD.Px = ZeD.Px or {}
local P = ZeD.Px

P.NEAREST = 3

-- ---------------------------------------------------------------------------
-- colours and textures
-- ---------------------------------------------------------------------------
local _col = {}
function P.color(h)
    if type(h) == "table" then return h end
    local c = _col[h or "#ffffff"]
    if not c then
        local s = tostring(h or "#ffffff"):gsub("#", "")
        c = { r = (tonumber(s:sub(1, 2), 16) or 255) / 255, g = (tonumber(s:sub(3, 4), 16) or 255) / 255, b = (tonumber(s:sub(5, 6), 16) or 255) / 255 }
        _col[h or "#ffffff"] = c
    end
    return c
end
function P.shade(h, f)
    local key = tostring(h) .. "*" .. tostring(f)
    local c = _col[key]
    if not c then
        local b = P.color(h)
        c = { r = math.min(1, b.r * f), g = math.min(1, b.g * f), b = math.min(1, b.b * f) }
        _col[key] = c
    end
    return c
end
P.BLACK = { r = 0, g = 0, b = 0 }

local _tex = {}
-- a texture with nearest filtering, cached (false when missing, so a missing file is asked for once)
function P.tex(path)
    local t = _tex[path]
    if t == nil then
        t = Texture.getSharedTexture(path, P.NEAREST) or false
        _tex[path] = t
    end
    return t or nil
end

-- the whole multiple for a UI scale (1080p = 1.0): never below 1, never fractional. The nearest whole
-- number (Oct 21 2026, director: crisp at every scale step; 1.75 draws at 2, 1.25 at 1, .5 rounds up);
-- it was the scale rounded down, which left every prop at 1x up to 1.95.
function P.k(scale)
    local Sc = ZeD.Scale
    if Sc and Sc.artZoom then return Sc.artZoom(scale or 1) end
    return math.max(1, math.floor((scale or 1) + 0.5 + 1e-6))
end
-- the same, for art `artW` texels wide inside a column `availW` screen px wide (a plate in a card): a whole
-- step smaller while it would not fit, never below 1. The caller lays out with the k it gets.
function P.kFit(scale, artW, availW)
    local k = P.k(scale)
    while k > 1 and artW * k > availW do k = k - 1 end
    return k
end

-- ---------------------------------------------------------------------------
-- the canvas and its primitives (art pixels)
-- ---------------------------------------------------------------------------
function P.canvas(el, ox, oy, k) return { el = el, ox = ox or 0, oy = oy or 0, k = k or 1 } end

function P.rect(cv, x, y, w, h, c, a)
    if w <= 0 or h <= 0 then return end
    local k = cv.k
    cv.el:drawRect(cv.ox + x * k, cv.oy + y * k, w * k, h * k, a or 1, c.r, c.g, c.b)
end

-- ---------------------------------------------------------------------------
-- Fewer rects, the same pixels (Oct 22 2026, the drawing-cost work): a set of rects of one colour that never
-- overlap can be drawn as fewer, taller rects where a rect sits right under one of the same x and width. Every
-- pixel is still covered exactly once, in the same colour and alpha, so the picture is the same.
-- ---------------------------------------------------------------------------
-- flat {x, y, w, h, ...} -> the same pixels as fewer rects (flat), or the list itself when its rects overlap
local function mergeFlat(list)
    local n = #list
    if n < 8 then return list end
    local seen = {}
    for i = 1, n, 4 do
        local x, y, w, h = list[i], list[i + 1], list[i + 2], list[i + 3]
        for yy = y, y + h - 1 do
            for xx = x, x + w - 1 do
                local key = yy * 65536 + xx
                if seen[key] then return list end
                seen[key] = true
            end
        end
    end
    local out, open = {}, {}
    for i = 1, n, 4 do
        local x, y, w, h = list[i], list[i + 1], list[i + 2], list[i + 3]
        local key = x * 65536 + w
        local j = open[key]
        if j and out[j + 1] + out[j + 3] == y then
            out[j + 3] = out[j + 3] + h
        else
            j = #out + 1
            out[j], out[j + 1], out[j + 2], out[j + 3] = x, y, w, h
            open[key] = j
        end
    end
    return out
end
local _merged, _mergedN = {}, 0
local function mergedOf(list)
    local m = _merged[list]
    if m then return m end
    m = mergeFlat(list)
    _mergedN = _mergedN + 1
    if _mergedN > 512 then _merged, _mergedN = {}, 1 end    -- (the lists are the plates' data: a handful)
    _merged[list] = m
    return m
end
P._mergeFlat = mergeFlat

-- a flat rect list {x, y, w, h, x, y, w, h, ...}, offset by (dx, dy)
function P.rects(cv, list, c, a, dx, dy)
    if not list then return end
    list = mergedOf(list)
    local el, k, ox, oy = cv.el, cv.k, cv.ox + (dx or 0) * cv.k, cv.oy + (dy or 0) * cv.k
    local al = a or 1
    for i = 1, #list, 4 do
        el:drawRect(ox + list[i] * k, oy + list[i + 1] * k, list[i + 2] * k, list[i + 3] * k, al, c.r, c.g, c.b)
    end
end

-- horizontal runs {x, y, w} as built by the rasterisers below; a merged run carries its height (r[4])
local function drawRuns(cv, runs, c, a, dx, dy)
    local el, k = cv.el, cv.k
    local ox, oy = cv.ox + (dx or 0) * k, cv.oy + (dy or 0) * k
    for i = 1, #runs do
        local r = runs[i]
        el:drawRect(ox + r[1] * k, oy + r[2] * k, r[3] * k, (r[4] or 1) * k, a or 1, c.r, c.g, c.b)
    end
end
-- runs {x, y, w} (one pixel tall, never overlapping, rows in order) merged down into {x, y, w, h}
local function mergeRuns(runs)
    local out, open = {}, {}
    for i = 1, #runs do
        local r = runs[i]
        local key = r[1] * 65536 + r[3]
        local m = open[key]
        if m and m[2] + m[4] == r[2] then
            m[4] = m[4] + 1
        else
            m = { r[1], r[2], r[3], 1 }
            out[#out + 1] = m
            open[key] = m
        end
    end
    return out
end

function P.image(cv, tex, x, y, w, h, a)
    if not tex then return end
    local k = cv.k
    cv.el:drawTextureScaled(tex, cv.ox + x * k, cv.oy + y * k, w * k, h * k, a or 1, 1, 1, 1)
end

-- the same, its colours multiplied by m = { r, g, b } (a part in the dark: ZeD_Plate's night light)
function P.imageTint(cv, tex, x, y, w, h, m, a)
    if not tex then return end
    local k = cv.k
    cv.el:drawTextureScaled(tex, cv.ox + x * k, cv.oy + y * k, w * k, h * k, a or 1, m.r, m.g, m.b)
end

-- a colour times a multiplier, kept per (multiplier, colour) so a frame allocates nothing once warm. Both
-- are long-lived tables (P.color's cache, the night light's multipliers), so the cache stays small.
local _mulc = {}
function P.mulColor(c, m)
    if not m then return c end
    local byM = _mulc[m]
    if not byM then byM = {}; _mulc[m] = byM end
    local o = byM[c]
    if not o then o = { r = c.r * m.r, g = c.g * m.g, b = c.b * m.b }; byM[c] = o end
    return o
end

-- ---------------------------------------------------------------------------
-- pixel sets -> runs
-- ---------------------------------------------------------------------------
local KEYW = 8192
local function runsOf(set)
    local keys = {}
    for key, _ in pairs(set) do keys[#keys + 1] = key end
    table.sort(keys)
    local out = {}
    local cur = nil
    for i = 1, #keys do
        local key = keys[i]
        local y = math.floor(key / KEYW)
        local x = key - y * KEYW - 4096
        if cur and cur[2] == y and cur[1] + cur[3] == x then
            cur[3] = cur[3] + 1
        else
            cur = { x, y, 1 }
            out[#out + 1] = cur
        end
    end
    return out
end
local function pkey(x, y) return y * KEYW + x + 4096 end

-- ---------------------------------------------------------------------------
-- needles: a line from r0 to r1 (r0 may be negative: the tail past the hub), w pixels
-- wide, rasterised on the art grid. Angles are screen degrees (0 = right, 90 = down).
-- The side facing the windshield light is lit; the other side is the colour darker;
-- its shadow falls one pixel right and two down. Pixels inside `hub` are left to the
-- plate (the hub cap sits over the needle).
-- ---------------------------------------------------------------------------
local LX, LY = -0.41, -0.91
function P.needleRuns(cx, cy, deg, r0, r1, w, hub)
    local a = deg * math.pi / 180
    local ca, sa = math.cos(a), math.sin(a)
    local px, py = -sa, ca
    local lit = ((px * LX + py * LY) > 0) and 1 or -1
    local body, edge = {}, {}
    local steps = math.floor(math.abs(r1 - r0) * 2) + 1
    local horiz = math.abs(ca) >= math.abs(sa)
    hub = hub or 0
    w = w or 2
    for i = 0, steps do
        local r = r0 + (r1 - r0) * i / steps
        if math.abs(r) >= hub then
            local x, y = cx + ca * r, cy + sa * r
            for j = 0, w - 1 do
                local off = j - (w - 1) / 2
                local X, Y
                if horiz then X, Y = math.floor(x), math.floor(y + off) else X, Y = math.floor(x + off), math.floor(y) end
                local side = (X + 0.5 - x) * px + (Y + 0.5 - y) * py
                local key = pkey(X, Y)
                if w == 1 or side * lit >= 0 then body[key] = true else edge[key] = true end
            end
        end
    end
    local all = {}
    for key, _ in pairs(body) do all[key] = true; edge[key] = nil end
    for key, _ in pairs(edge) do all[key] = true end
    return runsOf(body), runsOf(edge), runsOf(all)
end


-- The rasterised needle, kept per needle and angle (Oct 22 2026, the drawing-cost work: a needle at rest is
-- rasterised once, not every frame), with each set also merged down for the drawing that has one colour:
-- { body, edge, all, bodyM, edgeM, allM }. A needle's angles past NR_MAX start its list over.
local NR_MAX = 64
local _nr = {}
-- the needle's samples as P.needleRuns takes them (the same steps, the same arithmetic): each sample's pixel
-- key, doubled, plus one when it falls on the shaded side; in order
local function needleSamples(cx, cy, deg, r0, r1, w, hub)
    local a = deg * math.pi / 180
    local ca, sa = math.cos(a), math.sin(a)
    local px, py = -sa, ca
    local lit = ((px * LX + py * LY) > 0) and 1 or -1
    local steps = math.floor(math.abs(r1 - r0) * 2) + 1
    local horiz = math.abs(ca) >= math.abs(sa)
    local out, n = {}, 0
    for i = 0, steps do
        local r = r0 + (r1 - r0) * i / steps
        if math.abs(r) >= hub then
            local x, y = cx + ca * r, cy + sa * r
            for j = 0, w - 1 do
                local off = j - (w - 1) / 2
                local X, Y
                if horiz then X, Y = math.floor(x), math.floor(y + off) else X, Y = math.floor(x + off), math.floor(y) end
                local side = (X + 0.5 - x) * px + (Y + 0.5 - y) * py
                n = n + 1
                out[n] = pkey(X, Y) * 2 + ((w == 1 or side * lit >= 0) and 0 or 1)
            end
        end
    end
    return out
end
local function needleSets(cx, cy, deg, r0, r1, w, hub)
    w, hub = w or 2, hub or 0
    local key = tostring(cx) .. "|" .. tostring(cy) .. "|" .. tostring(r0) .. "|" .. tostring(r1) .. "|" .. tostring(w) .. "|" .. tostring(hub)
    local byDeg = _nr[key]
    if not byDeg then byDeg = { n = 0, d = {} }; _nr[key] = byDeg end
    local s = byDeg.d[deg]
    if s then return s end
    -- a moving needle (a reading settling) comes at a new angle every frame, but its pixels change only
    -- now and then: when every sample lands on the same pixel, on the same side, as at the angle before,
    -- the pixels are the same and so is everything made from them
    local smp = needleSamples(cx, cy, deg, r0, r1, w, hub)
    local last = byDeg.last
    if last and #last.smp == #smp then
        local same = true
        for i = 1, #smp do if smp[i] ~= last.smp[i] then same = false; break end end
        if same then
            s = last.set
            byDeg.d[deg] = s
            byDeg.n = byDeg.n + 1
            if byDeg.n >= NR_MAX then byDeg.d, byDeg.n = {}, 0 end
            return s
        end
    end
    local body, edge, all = P.needleRuns(cx, cy, deg, r0, r1, w, hub)
    s = { body, edge, all }          -- [4..6]: the merged sets, made when first drawn (merged)
    byDeg.last = { smp = smp, set = s }
    if byDeg.n >= NR_MAX then byDeg.d, byDeg.n = {}, 0 end
    byDeg.d[deg] = s
    byDeg.n = byDeg.n + 1
    return s
end
local function mergedSet(s, i)
    local m = s[i + 3]
    if not m then m = mergeRuns(s[i]); s[i + 3] = m end
    return m
end
-- a lit needle's colours, run by run (L.dim(L, c, x, y) at each run's middle: ZeD_Plate's night light), kept on the needle's set while the
-- light and the colour stay: { edge colours, body colours }
local function litColours(s, c, ec, L)
    local lc = s.lit
    if lc and lc.c == c and lc.dim == L.dim and lc.map == L.map and lc.n8 == L.n8 and lc.lit == L.lit and lc.amb == L.amb
       and lc.levels == L.levels and lc.tint == L.tint and lc.tmap == L.tmap and lc.cell == L.cell and lc.cols == L.cols
       and lc.rows == L.rows then
        return lc
    end
    lc = { c = c, dim = L.dim, map = L.map, n8 = L.n8, lit = L.lit, amb = L.amb, levels = L.levels, tint = L.tint, tmap = L.tmap,
           cell = L.cell, cols = L.cols, rows = L.rows, e = {}, b = {} }
    for i, r in ipairs(s[2]) do lc.e[i] = L.dim(L, ec, r[1] + r[3] * 0.5, r[2]) end
    for i, r in ipairs(s[1]) do lc.b[i] = L.dim(L, c, r[1] + r[3] * 0.5, r[2]) end
    s.lit = lc
    return lc
end
local function drawRunsCols(cv, runs, cols)
    local el, k = cv.el, cv.k
    local ox, oy = cv.ox, cv.oy
    for i = 1, #runs do
        local r, cc = runs[i], cols[i]
        el:drawRect(ox + r[1] * k, oy + r[2] * k, r[3] * k, k, 1, cc.r, cc.g, cc.b)
    end
end

-- L (optional): a light the needle follows run by run (in the dark only the stretch in a bulb's pool reads)
function P.needle(cv, cx, cy, deg, r0, r1, w, hub, c, noShadow, L)
    local s = needleSets(cx, cy, deg, r0, r1, w, hub)
    if not noShadow then drawRuns(cv, mergedSet(s, 3), P.BLACK, 0.45, 1, 2) end
    local ec = c._edge                 -- the shaded side, kept on the colour (one table, not one a frame)
    if not ec then ec = { r = c.r * 0.55, g = c.g * 0.55, b = c.b * 0.55 }; c._edge = ec end
    if L then
        local lc = litColours(s, c, ec, L)
        if #s[2] > 0 then drawRunsCols(cv, s[2], lc.e) end
        drawRunsCols(cv, s[1], lc.b)
        return
    end
    if #s[2] > 0 then drawRuns(cv, mergedSet(s, 2), ec) end
    drawRuns(cv, mergedSet(s, 1), c)
end

-- a plain pointer line (knob pointers, clock hands): no shading, no shadow
function P.pointer(cv, cx, cy, deg, r0, r1, w, c, hub)
    local s = needleSets(cx, cy, deg, r0, r1, w or 1, hub or 0)
    drawRuns(cv, mergedSet(s, 3), c)
end

-- ---------------------------------------------------------------------------
-- a ring on the art grid: every pixel whose centre lies between r0 and r1 from
-- (cx, cy), drawn one run a row (two where the hole cuts the row). The plates use
-- it as the cue round a knob (a fill over a knob would hide its knurl).
-- ---------------------------------------------------------------------------
function P.ring(cv, cx, cy, r0, r1, c, a)
    for y = math.floor(cy - r1), math.ceil(cy + r1) do
        local dy = math.abs(y + 0.5 - cy)
        if dy <= r1 then
            local xo = math.sqrt(r1 * r1 - dy * dy)
            local xa, xb = math.ceil(cx - xo - 0.5), math.floor(cx + xo - 0.5)   -- the row's outer pixels
            if dy < r0 then
                local xi = math.sqrt(r0 * r0 - dy * dy)
                local la, rb = math.floor(cx - xi - 0.5), math.ceil(cx + xi - 0.5)
                if la >= xa then P.rect(cv, xa, y, la - xa + 1, 1, c, a) end
                if xb >= rb then P.rect(cv, rb, y, xb - rb + 1, 1, c, a) end
            elseif xb >= xa then
                P.rect(cv, xa, y, xb - xa + 1, 1, c, a)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- seven-segment figures: cw x ch cells, stroke t, a cell every `pitch`; '.' rides on the
-- figure before it, ':' takes a narrow cell of its own; `ghost` draws the unlit segments
-- ---------------------------------------------------------------------------
local SEGS = { ["0"] = "abcdef", ["1"] = "bc", ["2"] = "abged", ["3"] = "abgcd", ["4"] = "fgbc", ["5"] = "afgcd", ["6"] = "afgedc",
    ["7"] = "abc", ["8"] = "abcdefg", ["9"] = "abcfgd", ["-"] = "g", [" "] = "", E = "afged", F = "afge", A = "abcefg", P = "abefg",
    C = "afed", L = "fed", H = "fbgec", r = "eg", n = "ceg", o = "cdeg", d = "bcdeg", t = "fged", U = "bcdef", b = "fgcde", S = "afgcd" }
local SEG_ORDER = { "a", "b", "c", "d", "e", "f", "g" }
local function segRect(seg, x, y, w, h, t)
    local hh = math.floor((h - t) / 2)
    if seg == "a" then return x + t, y, w - 2 * t, t end
    if seg == "d" then return x + t, y + h - t, w - 2 * t, t end
    if seg == "g" then return x + t, y + hh, w - 2 * t, t end
    if seg == "f" then return x, y + t, t, hh - t end
    if seg == "b" then return x + w - t, y + t, t, hh - t end
    if seg == "e" then return x, y + hh + t, t, h - hh - 2 * t end
    return x + w - t, y + hh + t, t, h - hh - 2 * t   -- c
end

-- txt is drawn into n cells (right-aligned unless align == "l"); returns nothing
function P.digits(cv, txt, x, y, cw, ch, pitch, t, c, ghost, align, n)
    local cells = {}
    txt = tostring(txt or "")
    for i = 1, #txt do
        local s = txt:sub(i, i)
        if s == "." and #cells > 0 then cells[#cells].dot = true
        elseif s == ":" then cells[#cells + 1] = { s = ":", colon = true }
        else cells[#cells + 1] = { s = s } end
    end
    n = n or #cells
    while #cells > n do table.remove(cells, 1) end
    local pad = n - #cells
    local xx = x
    if align ~= "l" then
        for _ = 1, pad do
            if ghost then for _, sg in ipairs(SEG_ORDER) do local a, b, w, h = segRect(sg, xx, y, cw, ch, t); P.rect(cv, a, b, w, h, ghost) end end
            xx = xx + pitch
        end
    end
    for _, cell in ipairs(cells) do
        if cell.colon then
            P.rect(cv, xx, y + math.floor(ch * 0.3), t, t, c); P.rect(cv, xx, y + math.floor(ch * 0.7) - t + 1, t, t, c)
            xx = xx + t + 2
        else
            local lit = SEGS[cell.s] or ""
            for _, sg in ipairs(SEG_ORDER) do
                local a, b, w, h = segRect(sg, xx, y, cw, ch, t)
                if lit:find(sg, 1, true) then P.rect(cv, a, b, w, h, c) elseif ghost then P.rect(cv, a, b, w, h, ghost) end
            end
            if cell.dot then P.rect(cv, xx + cw + math.max(0, math.floor((pitch - cw - t) / 2)), y + ch - t, t, t, c) end
            xx = xx + pitch
        end
    end
end

-- ---------------------------------------------------------------------------
-- the pixel fonts
-- ---------------------------------------------------------------------------
-- The faces hold capitals, digits, signs, the accented Latin capitals and the Cyrillic capitals
-- (ZeD/PixelFonts.lua and PixelFontsExt.lua). Text is laid out word by word: a word whose letters
-- are all in the face is drawn in the face; a word with a letter the face lacks (Chinese, say) is
-- drawn whole in the regular F1 face, sized so its capitals match the face's height. A layout is
-- worked out once per string and kept (oldest dropped first), so a frame only walks cells.

-- lowercase to capital for the letters the faces carry. Kahlua's string.upper already does this
-- through Java, but the table keeps the pixel text from depending on that.
local UP = {}
do
    local function pair(lo, hi) UP[string.char(lo)] = string.char(hi) end
    for c = 224, 254 do if c ~= 247 then pair(c, c - 32) end end   -- the Latin-1 letters
    pair(255, 376)                                                  -- y with dieresis
    for c = 1072, 1103 do pair(c, c - 32) end                       -- Russian a-ya
    for c = 1104, 1119 do pair(c, c - 80) end                       -- yo and the rest of that block
    pair(1169, 1168)                                                -- Ukrainian ghe with upturn
end

-- typographic signs the faces draw as their plain cousins (a string means "write these characters")
local NORM = {}
do
    local function put(codes, rep) for i = 1, #codes do NORM[string.char(codes[i])] = rep end end
    put({ 8216, 8217, 8218, 8219, 700 }, "'")
    put({ 8220, 8221, 8222, 171, 187 }, '"')
    put({ 8208, 8209, 8210, 8211, 8212, 8722 }, "-")
    put({ 160, 8194, 8195, 8201, 8202, 8239 }, " ")
    put({ 8230 }, "...")
    put({ 215 }, "x")
end

-- Turkish writes the capital of i with a dot
local function turkic()
    local ok, name = pcall(function() return Translator.getLanguage():name() end)
    return ok and (name == "TR" or name == "AZ")
end

-- the face's key for a character, or nil when the face has no glyph for it
local function faceKey(F, ch, tr)
    if tr and ch == "i" and F[string.char(304)] then return string.char(304) end
    if F[ch] then return ch end
    local u = UP[ch] or string.upper(ch)
    if #u == 1 and F[u] then return u end
    return nil
end

local _glyphs = {}     -- font -> key -> { w = cols, runs = { {dx, dy, w}, ... } }
local function glyph(font, ch)
    local F = ZeD.PixelFonts and ZeD.PixelFonts[font]
    if not F then return nil end
    local cache = _glyphs[font]
    if not cache then cache = {}; _glyphs[font] = cache end
    local g = cache[ch]
    if g then return g end
    local rows = F[ch] or F[" "]
    g = { w = #rows[1], h = #rows, runs = {} }
    for ry = 1, #rows do
        local row = rows[ry]
        local start = nil
        for rx = 1, #row + 1 do
            local on = rx <= #row and row:sub(rx, rx) == "1"
            if on and not start then start = rx end
            if (not on) and start then g.runs[#g.runs + 1] = { start - 1, ry - 1, rx - start }; start = nil end
        end
    end
    cache[ch] = g
    return g
end

-- the regular F1 face, for words the pixel faces cannot spell
local FB_CAP = 0.57        -- the F1 face's capital height over its line height
local function fbFont()
    local T = ZeD.T
    return T and T.fontF1 or nil
end
-- a word's width and the face's line height at zoom 1, or nil when the text manager is not ready
local function fbMeasure(word)
    local X, f = ZeD.Text, fbFont()
    if not (X and X.realTM and f) then return nil end
    local ok, w, lh = pcall(function() local tm = X.realTM(); return tm:MeasureStringX(f, word), tm:getFontHeight(f) end)
    if not ok or type(w) ~= "number" or type(lh) ~= "number" or lh <= 0 then return nil end
    return w, lh
end

-- layouts: font -> string -> { cells = {...}, w = width in art pixels at scale 1 }, oldest dropped first
local LAY_CAP = 256
local _lay, _layKeys, _layHead, _layN, _layFont = {}, {}, 0, 0, nil
local function layStore(font, str, lay)
    local bucket = _lay[font]
    if not bucket then bucket = {}; _lay[font] = bucket end
    if _layN < LAY_CAP then
        _layN = _layN + 1
        _layKeys[_layN] = { font, str }
    else
        _layHead = _layHead % LAY_CAP + 1
        local old = _layKeys[_layHead]
        if _lay[old[1]] then _lay[old[1]][old[2]] = nil end
        _layKeys[_layHead] = { font, str }
    end
    bucket[str] = lay
end

local function layoutBuild(str, font)
    local F = ZeD.PixelFonts and ZeD.PixelFonts[font]
    if not F then return nil end
    local h = (font == "57") and 7 or 5
    local tr = turkic()
    local chars = {}
    for i = 1, #str do
        local ch = str:sub(i, i)
        local rep = NORM[ch]
        if rep then
            for j = 1, #rep do chars[#chars + 1] = rep:sub(j, j) end
        else
            chars[#chars + 1] = ch
        end
    end
    local cells, n, i, complete = {}, #chars, 1, true
    while i <= n do
        if chars[i]:find("%s") then
            cells[#cells + 1] = glyph(font, " ")
            i = i + 1
        else
            local j = i
            while j <= n and not chars[j]:find("%s") do j = j + 1 end
            local keys, ok = {}, true
            for k = i, j - 1 do
                local key = faceKey(F, chars[k], tr)
                if key then keys[#keys + 1] = key else ok = false; break end
            end
            if ok then
                for k = 1, #keys do cells[#cells + 1] = glyph(font, keys[k]) end
            else
                local word = ZeD.upper(table.concat(chars, "", i, j - 1))
                local raw, lh = fbMeasure(word)
                if raw then
                    cells[#cells + 1] = { fb = true, text = word, raw = math.max(1, raw), lh = lh, w = math.max(1, math.floor(raw * h / FB_CAP / lh + 0.5)) }
                else
                    complete = false                      -- the text manager is not up yet: spaces now, ask again next time
                    for _ = i, j - 1 do cells[#cells + 1] = glyph(font, " ") end
                end
            end
            i = j
        end
    end
    local w = 0
    for k = 1, #cells do w = w + cells[k].w + 1 end
    return { cells = cells, w = math.max(0, w - 1) }, complete
end

local function layoutOf(str, font)
    local f1 = fbFont()
    if f1 ~= _layFont then                 -- another F1 face: the measured widths are stale
        _lay, _layKeys, _layHead, _layN, _layFont = {}, {}, 0, 0, f1
    end
    local bucket = _lay[font]
    local lay = bucket and bucket[str]
    if lay then return lay end
    local complete
    lay, complete = layoutBuild(str, font)
    if lay and complete then layStore(font, str, lay) end
    return lay
end

function P.textWidth(str, font, scale)
    str = tostring(str or ""); font = font or "35"; scale = scale or 1
    if str == "" then return 0 end
    local lay = layoutOf(str, font)
    if not lay then return (#str * 3 - 1) * scale end
    return lay.w * scale
end

function P.fontHeight(font) return (font == "57") and 7 or 5 end

-- fit a label in w pixels: the make off the front first, then the smaller face, then letters off the end
function P.fit(str, font, scale, w)
    str = tostring(str or "")
    if P.textWidth(str, font, scale) <= w then return str, font, scale end
    if scale > 1 and P.textWidth(str, font, scale - 1) <= w then return str, font, scale - 1 end
    local words = {}
    for wd in str:gmatch("%S+") do words[#words + 1] = wd end
    while #words > 1 and P.textWidth(table.concat(words, " "), font, scale) > w do table.remove(words, 1) end
    local s = table.concat(words, " ")
    if P.textWidth(s, font, scale) <= w then return s, font, scale end
    if font == "57" and P.textWidth(s, "35", scale) <= w then return s, "35", scale end
    font = "35"
    while #s > 1 and P.textWidth(s, font, scale) > w do s = s:sub(1, -2) end
    return s, font, scale
end

local CHROME = { "#15171b", "#24272d", "#3a3e46", "#5a5f69", "#848a94", "#b3b9c2", "#dde2e8", "#ffffff" }
local CHROME_ROWS = { [5] = { 8, 7, 6, 6, 5 }, [7] = { 8, 8, 7, 6, 6, 5, 4 } }

-- A text in the pixel faces kept as its rects (Oct 22 2026, the drawing-cost work): the badges, legends and
-- readouts are the same text frame after frame, so their rects are worked out once, merged down where a run sits
-- under one of the same colour, x and width (each pass covers its pixels exactly once, so the picture is the same),
-- and a frame only draws them. Kept per text, face, scale, style and colours; past TC_MAX texts (a marquee walks
-- through many) and on a language change (the Turkish dotted I) the store starts over. A text with a word in the
-- regular F1 face takes the full path below.
local TC_MAX = 768
local _tc, _tcN, _tcGen = {}, 0, nil
local function textRects(str, font, scale, style, c, shadow, mul)
    if _tcGen ~= ZeD._trGen or _tcN >= TC_MAX then _tc, _tcN, _tcGen = {}, 0, ZeD._trGen end
    local k1 = str .. "\1" .. font .. "\1" .. tostring(scale) .. "\1" .. tostring(style or "")
    local a = _tc[k1]
    if not a then a = {}; _tc[k1] = a end
    local ck = c or false
    local b = a[ck]
    if not b then b = {}; a[ck] = b end
    local sk = shadow or false
    local d = b[sk]
    if not d then d = {}; b[sk] = d end
    local mk = mul or false
    local e = d[mk]
    if e ~= nil then return e end
    -- build: the layout must be all pixel glyphs
    local lay = layoutOf(str, font)
    e = false
    if lay then
        local pure = true
        for i = 1, #lay.cells do if lay.cells[i].fb then pure = false; break end end
        if pure then
            local out = {}
            local cells = lay.cells
            local function addPass(dx, dy, colr, rowTones)
                local open = {}
                local cx = 0
                for i = 1, #cells do
                    local g = cells[i]
                    local runs = g.runs
                    for j = 1, #runs do
                        local r = runs[j]
                        local cc = colr
                        if rowTones then cc = P.mulColor(P.color(CHROME[rowTones[r[2] + 1] or 6]), mul) end
                        local rx, ry, rw = cx + r[1] * scale + dx, r[2] * scale + dy, r[3] * scale
                        local byC = open[cc]
                        if not byC then byC = {}; open[cc] = byC end
                        local okey = (rx + 32768) * 65536 + rw
                        local o = byC[okey]
                        if o and out[o + 1] + out[o + 3] == ry then
                            out[o + 3] = out[o + 3] + scale
                        else
                            o = #out + 1
                            out[o], out[o + 1], out[o + 2], out[o + 3], out[o + 4] = rx, ry, rw, scale, cc
                            byC[okey] = o
                        end
                    end
                    cx = cx + (g.w + 1) * scale
                end
            end
            if shadow then addPass(1, 1, P.color(shadow)) end
            if style == "chrome" then
                addPass(0, 0, nil, CHROME_ROWS[P.fontHeight(font) * scale] or CHROME_ROWS[5])
            else
                addPass(0, 0, c)
            end
            e = { w = lay.w * scale, r = out }
        end
    end
    d[mk] = e
    _tcN = _tcN + 1
    return e
end

-- text at (x, y) (its top), align "l" | "c" | "r"; style "chrome" shades each row like the plate's chrome letters;
-- mul (optional { r, g, b }) dims the chrome rows too (a badge in the dark; flat colours come in already dimmed)
function P.text(cv, str, x, y, c, font, scale, align, style, shadow, mul)
    str = tostring(str or "")
    if str == "" then return 0 end
    font = font or "35"; scale = scale or 1
    local e = textRects(str, font, scale, style, c, shadow, mul)
    if e then
        local w = e.w
        if align == "c" then x = x - math.floor(w / 2) elseif align == "r" then x = x - w end
        local list = e.r
        local el, k, ox, oy = cv.el, cv.k, cv.ox, cv.oy
        for i = 1, #list, 5 do
            local cc = list[i + 4]
            el:drawRect(ox + (x + list[i]) * k, oy + (y + list[i + 1]) * k, list[i + 2] * k, list[i + 3] * k, 1, cc.r, cc.g, cc.b)
        end
        return w
    end
    local w = P.textWidth(str, font, scale)
    if align == "c" then x = x - math.floor(w / 2) elseif align == "r" then x = x - w end
    local lay = layoutOf(str, font)
    if not lay then return w end
    local cells = lay.cells
    local faceH = P.fontHeight(font) * scale
    local function pass(dx, dy, colr, rowTones)
        local cx = x
        for i = 1, #cells do
            local g = cells[i]
            if g.fb then
                -- a word the face cannot spell: the regular F1 face, its capitals as tall as the face's,
                -- the line centred on the face's rows
                local f1 = fbFont()
                local cc = colr or P.mulColor(P.color(CHROME[6]), mul)
                if f1 then
                    local k = cv.k
                    local zoom = g.w * scale * k / g.raw
                    local top = cv.oy + (y + dy) * k + (faceH * k - g.lh * zoom) / 2
                    cv.el:drawTextZoomed(g.text, math.floor(cv.ox + (cx + dx) * k), math.floor(top), zoom, cc.r, cc.g, cc.b, cv.el._zedAlpha or 1, f1)
                end
            else
                for _, r in ipairs(g.runs) do
                    local cc = colr
                    if rowTones then cc = P.mulColor(P.color(CHROME[rowTones[r[2] + 1] or 6]), mul) end
                    P.rect(cv, cx + r[1] * scale + dx, y + r[2] * scale + dy, r[3] * scale, scale, cc)
                end
            end
            cx = cx + (g.w + 1) * scale
        end
    end
    if shadow then pass(1, 1, P.color(shadow)) end
    if style == "chrome" then
        pass(0, 0, nil, CHROME_ROWS[P.fontHeight(font) * scale] or CHROME_ROWS[5])
    else
        pass(0, 0, c)
    end
    return w
end

return P
