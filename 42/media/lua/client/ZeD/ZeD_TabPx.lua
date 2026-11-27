-- ZeD-UI/42/media/lua/client/ZeD/ZeD_TabPx.lua
-- ============================================================================
-- THE WINDOW TABS IN LIT PIXEL ART
-- Client; molecules on ZeD.TabPx. The character and world windows draw their
-- tabs through TP.drawTab, tied to the rest of the pixel art (the plates, the
-- dash, the watches) without changing the strips' layout:
--   * each tab's icon is a small object lit from the top left, in five tones
--     of the theme's accent, with a one-pixel shadow under it
--   * the active tab is a bevelled, lit accent panel (light top and left
--     edges, shaded bottom and right) with its icon pressed into it
--   * the pointer's hover is the T.hover wash; the controller's focus is the
--     player's focus mark (ZeD.Focus.mark), on the active tab too
-- Everything is coloured from ZeD.T every frame, so all 3 bases x 9 accents
-- keep working; nothing is baked in colour, but the 14 tabs' color icons
-- (the director, Nov 25 2026: TP.colorSet, below), drawn in their own colors.
--
-- The icons: ZeDUI/tools/tabpx/icons.py, exported as five white tone masks
-- and a shadow mask per icon (media/textures/ZeD/TabIcons/px/<id>_<tone>.png),
-- each drawn tinted. Pixels stay whole: the icon is drawn at k x 16 screen
-- pixels, k = the root scale rounded to the nearest whole number.
--
-- Before adding a tab: the windows draw a tab only when TP.has(id) is true,
-- so a new tab needs its six pictures exported and its id in TP.ICONS.
-- ============================================================================

require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_TabColorArt"   -- (the tabs' color icons: TP.drawIcon)

ZeD = ZeD or {}
ZeD.TabPx = ZeD.TabPx or {}
local TP = ZeD.TabPx

TP.DIR = "media/textures/ZeD/TabIcons/px/"
-- the tab ids that have a lit icon (both windows; Radio sits in both). Tabs
-- defined in other files (admin, server, cooking, the mod-support tabs) add
-- their own id here when they load.
TP.ICONS = { loot = true, equip = true, health = true, thermal = true, identity = true, journal = true, skills = true,
             radio = true, craft = true, build = true, furniture = true, maps = true, forage = true, animals = true,
             vehicle = true,
             -- (Nov 14 2026, punch list 216: not a tab of its own: the World Radio tab draws it while a TV set shows on it)
             tv = true }
local TONES = { "w", "l", "m", "d", "k" }

--- True when this tab id has a lit icon; the windows draw a tab only then.
function TP.has(id) return TP.ICONS[id] == true end

-- ---------------------------------------------------------------------------
-- colour helpers (results written into reused tables: a frame allocates nothing)
-- ---------------------------------------------------------------------------
local function clamp(v) if v < 0 then return 0 elseif v > 1 then return 1 end; return v end
local function shade(out, c, f) out.r, out.g, out.b = clamp(c.r * f), clamp(c.g * f), clamp(c.b * f); return out end
local function mix(out, a, b, t) out.r, out.g, out.b = a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t; return out end
local WHITE = { r = 1.0, g = 250 / 255, b = 240 / 255 }

-- the five tones for an icon: on the strip (lit from the top left) or pressed into the active panel.
-- A strip asks for the same tones once per tab, every frame, so each set (pressed in, and on the strip) is worked
-- out again only when the colours it comes from change. A window with its own accent swaps those colours in while
-- it draws, so the colours themselves are compared, not the token table.
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

--- The whole multiple the icon is drawn at: the root scale rounded to the
--- nearest whole number, never below 1. ZeD_FocusPaint sizes its pixel hand
--- with it too.
function TP.k()
    local Sc = ZeD.Scale
    local s = (Sc and Sc.root and Sc.root()) or 1
    return math.max(1, math.floor(s + 0.5))
end

local _c = {}
local function rect(el, x, y, w, h, c, a) if w > 0 and h > 0 then el:drawRect(x, y, w, h, a or 1, c.r, c.g, c.b) end end

-- ---------------------------------------------------------------------------
-- one tab
-- ---------------------------------------------------------------------------
local _markOpts = {}
local _washBg = {}
--- Draw one tab inside (x, y, w, h) of el: its background (the active panel, or
--- the hover wash), the controller's focus mark and its icon. `line` = the
--- strip's 1-pixel line width (T.px(1)).
--- isWashed: the pointer is over it, so an inactive tab gets the hover wash
--- (the controller's focus goes in opts.focus instead).
--- opts (optional): { focus = the ZeD.Focus.mark opts ({ win, zone }) when this tab
--- has the controller's focus, help = the help line's words (pass them only while
--- the pointer is over the tab) }
-- The lit tab's panel: the accent, its bottom and right in shade, its top and left catching the light. The shown
-- container's button draws the same one (ZeD.GridTint.stripCell), so the two strips have one selected look (the
-- director, Nov 26 2026: "the same selection type that's on the tabs").
function TP.drawLitPanel(el, x, y, w, h, line)
    local T = ZeD.T
    local acc, bright = T.accent, T.accentBright or T.accent
    local b = line or 1
    rect(el, x, y, w, h, shade(_c, acc, 0.85))
    rect(el, x, y + h - 2 * b, w, 2 * b, shade(_c, acc, 0.55))        -- the bottom falls into shade
    rect(el, x + w - b, y, b, h, shade(_c, acc, 0.60))                -- and the right
    rect(el, x, y, w, b, shade(_c, bright, 1.10))                    -- the top catches the light
    rect(el, x, y, b, h, shade(_c, bright, 1.05))                    -- and the left
end

function TP.drawTab(el, x, y, w, h, id, isActive, isWashed, line, opts)
    local T = ZeD.T
    if isActive then
        TP.drawLitPanel(el, x, y, w, h, line)
    elseif isWashed then
        local hv = T.hover
        rect(el, x, y, w, h, hv, hv.a)
    end
    local onWash = false
    if opts then
        local f = opts.focus
        if f and ZeD.Focus and ZeD.Focus.mark then
            -- the active tab is already solid accent: the mark leaves out its wash
            local m = _markOpts
            m.win, m.zone, m.focused, m.pad, m.solid = f.win, f.zone, f.focused, f.pad, isActive or f.solid
            onWash = ZeD.Focus.mark(el, x, y, w, h, m)
        end
        if opts.help and ZeD.Help and ZeD.Help.set then ZeD.Help.set(el, opts.help) end
    end
    -- (on the one-wash mark the icon takes its pressed-in tones, which lean to the ink that reads on the accent; a
    -- color icon there picks its set against that mark's wash, not the lit panel: QA's read, Nov 25 2026)
    local bg = nil
    if onWash and not isActive then
        local T = ZeD.T
        local s1 = T.surf1 or T.base
        bg = mix(_washBg, s1, T.accent, 0.55)
    end
    TP.drawIcon(el, id, x + math.floor(w / 2), y + math.floor(h / 2), isActive or onWash, bg)
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

-- ---------------------------------------------------------------------------
-- THE ICONS IN COLOR (the director, Nov 25 2026; mock-up ZeDUI/mockups/container_tabs_color_v4.html, the picks
-- "Multicolor" and "Lit accent panel"). A tab with color art (ZeD.TabColorArt, made by ZeDUI/tools/tabpx/
-- color_icons.py with its pictures in TabIcons/color/) draws it in its own three colors, in place of the accent
-- tones: the Dark set on Dark and High contrast, the darker Light set on Light; on the lit accent panel (the shown
-- tab, or the controller's one-wash mark) whichever set has more of its pixels 3:1 or more off the panel. The same
-- one-pixel shadow under it. Tabs with no color art (the add-ons' and the server's tabs) keep the accent tones.
-- ---------------------------------------------------------------------------
TP.COLOR_DIR = "media/textures/ZeD/TabIcons/color/"
local _color = {}
local function colorTex(id)
    local t = _color[id]
    if t then return t end
    local P = ZeD.Px
    -- ("zedtabc_": a name no game texture shares; the game also finds a texture by its bare name, and "health" drew
    -- another picture, QA Nov 25 2026)
    local base = TP.COLOR_DIR .. "zedtabc_" .. id
    t = { dark = P.tex(base .. ".png") or false, light = P.tex(base .. "_light.png") or false,
          sh = P.tex(base .. "_sh.png") or false }
    _color[id] = t
    return t
end
-- the share of a set's pixels standing 3:1 or more off bg
local function share(set, bg)
    local n, ok = 0, 0
    for _, c in ipairs(set) do
        n = n + c.n
        if ZeD.contrast(c, bg) >= 3 then ok = ok + c.n end
    end
    return n > 0 and ok / n or 0
end
TP._colorShare = share
local _panel = {}
--- Which color set a tab draws: "dark" or "light" (nil: it has no color art). bg: what is behind it when that is
--- not the lit panel (the controller's one-wash mark)
function TP.colorSet(id, isActive, bg)
    local art = ZeD.TabColorArt and ZeD.TabColorArt[id]
    if not art then return nil end
    local T = ZeD.T
    if isActive then
        bg = bg or shade(_panel, T.accent, 0.85)
        return (share(art.light, bg) > share(art.dark, bg)) and "light" or "dark"
    end
    return (T.baseKey == "light") and "light" or "dark"
end

-- the icon centred on (cx, cy)
function TP.drawIcon(el, id, cx, cy, isActive, bg)
    if not TP.ICONS[id] then return false end
    local k = TP.k()
    local sz = 16 * k
    local ix, iy = cx - math.floor(sz / 2), cy - math.floor(sz / 2)
    local set = TP.colorSet(id, isActive, bg)
    if set then
        local ct = colorTex(id)
        local pic = ct[set]
        if pic then
            if ct.sh then el:drawTextureScaled(ct.sh, ix + k, iy + k, sz, sz, isActive and 0.25 or 0.55, 0, 0, 0) end
            el:drawTextureScaled(pic, ix, iy, sz, sz, 1, 1, 1, 1)
            return true
        end
    end
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
