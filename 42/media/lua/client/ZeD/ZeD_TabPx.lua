-- ZeD-UI/42/media/lua/client/ZeD/ZeD_TabPx.lua
-- ============================================================================
-- THE WINDOW TABS IN LIT PIXEL ART (director, Oct 16 2026)
-- The character and world windows' tab strips, tied to the rest of the pixel
-- art (the plates, the dash, the watches) without changing their layout:
--   * each tab's icon is a small object lit from the top left, in five tones
--     of the theme's accent, with a one-pixel shadow under it
--   * the active tab is a bevelled, lit accent panel (light top and left
--     edges, shaded bottom and right) with its icon pressed into it
--   * hover and gamepad focus paint the same soft accent wash (S113c parity)
-- Everything is coloured from ZeD.T every frame, so all 3 bases x 9 accents
-- keep working; nothing is baked in colour.
--
-- The icons: ZeDUI/tools/tabpx/icons.py, exported as five white tone masks
-- and a shadow mask per icon (media/textures/ZeD/TabIcons/px/<id>_<tone>.png),
-- each drawn tinted. Pixels stay whole: the icon is drawn at k x 16 screen
-- pixels, k = the root scale rounded to the nearest whole number.
-- ============================================================================

require "ZeD/ZeD_PixelParts"

ZeD = ZeD or {}
ZeD.TabPx = ZeD.TabPx or {}
local TP = ZeD.TabPx

TP.DIR = "media/textures/ZeD/TabIcons/px/"
-- the tab ids that have a lit icon (both windows; Radio sits in both)
TP.ICONS = { loot = true, equip = true, health = true, thermal = true, identity = true, journal = true, skills = true,
             radio = true, craft = true, build = true, furniture = true, maps = true, forage = true, animals = true,
             vehicle = true }
local TONES = { "w", "l", "m", "d", "k" }

function TP.has(id) return TP.ICONS[id] == true end

-- ---------------------------------------------------------------------------
-- colour helpers (results written into reused tables: a frame allocates nothing)
-- ---------------------------------------------------------------------------
local function clamp(v) if v < 0 then return 0 elseif v > 1 then return 1 end; return v end
local function shade(out, c, f) out.r, out.g, out.b = clamp(c.r * f), clamp(c.g * f), clamp(c.b * f); return out end
local function mix(out, a, b, t) out.r, out.g, out.b = a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t; return out end
local WHITE = { r = 1.0, g = 250 / 255, b = 240 / 255 }

-- the five tones for an icon: on the strip (lit from the top left) or pressed into the active panel
-- (Oct 22 2026, the drawing-cost work: a strip asks for the same tones once per tab, every frame; each set, pressed
-- in and on the strip, is worked out again only when the colours it comes from change. A window with its own accent
-- swaps those colours in while it draws, so the colours themselves are compared, not the token table.)
local _toneSet = { a = { w = {}, l = {}, m = {}, d = {}, k = {} }, i = { w = {}, l = {}, m = {}, d = {}, k = {} } }
local _toneKey = { a = {}, i = {} }
local _tmp = {}
local ENGRAVE = { w = 0.45, l = 0.55, m = 0.68, d = 0.80, k = 0.92 }   -- how far each tone leans to textOnAccent
local function tonesFresh(k, acc, bright, on)
    if k.ar == acc.r and k.ag == acc.g and k.ab == acc.b and k.br == bright.r and k.bg == bright.g and k.bb == bright.b
       and k.onr == on.r and k.ong == on.g and k.onb == on.b then
        return true
    end
    k.ar, k.ag, k.ab, k.br, k.bg, k.bb, k.onr, k.ong, k.onb = acc.r, acc.g, acc.b, bright.r, bright.g, bright.b, on.r, on.g, on.b
    return false
end
local function tones(T, active)
    local set = active and "a" or "i"
    local acc, bright = T.accent, T.accentBright or T.accent
    local _tone = _toneSet[set]
    if tonesFresh(_toneKey[set], acc, bright, T.textOnAccent) then return _tone end
    if active then
        -- pressed in: tones toward textOnAccent; the brightest tone is always the shine, whichever way that leans
        local on = T.textOnAccent
        local onLight = (on.r + on.g + on.b) > 1.5
        for _, t in ipairs(TONES) do
            local f = ENGRAVE[t]
            if onLight then f = 1.37 - f end          -- light text on a dark accent: the shine leans furthest
            mix(_tone[t], acc, on, f)
        end
    else
        shade(_tmp, bright, 1.0)
        mix(_tone.w, _tmp, WHITE, 0.55)
        shade(_tone.l, bright, 1.22)
        shade(_tone.m, acc, 1.0)
        shade(_tone.d, acc, 0.58)
        shade(_tone.k, acc, 0.34)
    end
    return _tone
end
TP._tones = tones

-- the whole multiple the icon is drawn at
function TP.k()
    local Sc = ZeD.Scale
    local s = (Sc and Sc.root and Sc.root()) or 1
    return math.max(1, math.floor(s + 0.5))
end

local _c = {}
local function rect(el, x, y, w, h, c, a) if w > 0 and h > 0 then el:drawRect(x, y, w, h, a or 1, c.r, c.g, c.b) end end

-- ---------------------------------------------------------------------------
-- one tab: its background (active panel, or the hover / focus wash) and its icon,
-- inside (x, y, w, h) of el; `line` = the strip's 1-pixel line width (T.px(1))
-- ---------------------------------------------------------------------------
function TP.drawTab(el, x, y, w, h, id, isActive, isWashed, line)
    local T = ZeD.T
    local acc, bright = T.accent, T.accentBright or T.accent
    local b = line or 1
    if isActive then
        rect(el, x, y, w, h, shade(_c, acc, 0.85))
        rect(el, x, y + h - 2 * b, w, 2 * b, shade(_c, acc, 0.55))        -- the bottom falls into shade
        rect(el, x + w - b, y, b, h, shade(_c, acc, 0.60))                -- and the right
        rect(el, x, y, w, b, shade(_c, bright, 1.10))                    -- the top catches the light
        rect(el, x, y, b, h, shade(_c, bright, 1.05))                    -- and the left
    elseif isWashed then
        rect(el, x, y, w, h, acc, 0.30)
    end
    TP.drawIcon(el, id, x + math.floor(w / 2), y + math.floor(h / 2), isActive)
end

-- an icon's six pictures (the shadow, then the five tones), looked up once
local _icons = {}
local function iconTex(id)
    local t = _icons[id]
    if t then return t end
    local P = ZeD.Px
    t = { sh = P.tex(TP.DIR .. id .. "_sh.png") or false }
    for i, tone in ipairs(TONES) do t[i] = P.tex(TP.DIR .. id .. "_" .. tone .. ".png") or false end
    _icons[id] = t
    return t
end

-- the icon centred on (cx, cy)
function TP.drawIcon(el, id, cx, cy, isActive)
    if not TP.ICONS[id] then return false end
    local k = TP.k()
    local sz = 16 * k
    local ix, iy = cx - math.floor(sz / 2), cy - math.floor(sz / 2)
    local it = iconTex(id)
    local sh = it.sh
    if sh then el:drawTextureScaled(sh, ix + k, iy + k, sz, sz, isActive and 0.25 or 0.55, 0, 0, 0) end
    local tn = tones(ZeD.T, isActive)
    for i = 1, #TONES do
        local tex = it[i]
        local c = tn[TONES[i]]
        if tex then el:drawTextureScaled(tex, ix, iy, sz, sz, 1, c.r, c.g, c.b) end
    end
    return true
end

return TP
