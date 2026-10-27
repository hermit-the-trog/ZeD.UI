-- ZeD-UI/42/media/lua/client/ZeD/Atoms.lua
-- ============================================================================
-- ATOM FACTORIES & DRAW HELPERS
-- The smallest indivisible UI pieces. Each atom is either:
--   - A draw function (called inside a parent's render/prerender)
--   - A factory function (creates and returns a configured ISPanel/etc.)
--
-- All atoms read from ZeD.T (the active palette). When the theme changes,
-- atoms automatically pick up new colors on the next frame.
-- ============================================================================

require "ISUI/ISPanel"

ZeD = ZeD or {}
ZeD.Atoms = ZeD.Atoms or {}

--- Safely call a method on an item, returning nil on error or missing method.
function ZeD.Atoms.safeGet(item, m, ...)
    local fn = item[m]; if not fn then return nil end
    local ok, r = pcall(fn, item, ...); if ok then return r end; return nil
end

-- ============================================================================
-- 00. SHARED PIECES (cohesion pass)
-- Small helpers every look below leans on: the one hover delay, a window surface
-- that does not stack on the body, a 1u frame, the hard System 7 shadow, and the
-- window a panel sits in.
-- ============================================================================

local NO_OPTS = {}

-- The pause before any hover box (hint or detail card) shows. One value for the
-- whole UI; ZeD.Atoms.HINT_MS is the older name for it.
ZeD.HINT_DELAY_MS = 450
ZeD.Atoms.HINT_MS = ZeD.HINT_DELAY_MS

-- Words that arrive in capitals at draw time read in sentence case
-- (ZeD.textCase; until it lands, ZeD.btnCase follows the same rules).
local function textCase(s)
    if s == nil then return "" end
    local f = ZeD.textCase or ZeD.btnCase
    if f then return f(s) end
    return tostring(s)
end
ZeD.Atoms.textCase = textCase

--- A window surface (surf1..surf4) drawn so it does not add opacity over the
-- window body (the see-through setting). ZeD.Surface.fill does that; until it is
-- there, a plain fill in the token's colour.
function ZeD.Atoms.surfaceFill(panel, x, y, w, h, key)
    if w <= 0 or h <= 0 then return end
    local S = ZeD.Surface
    if S and S.fill then S.fill(panel, x, y, w, h, key); return end
    local c = ZeD.T[key] or ZeD.T.surf2
    panel:drawRect(x, y, w, h, c.a or 1, c.r, c.g, c.b)
end

--- A rectangle outline `t` px thick (default one hairline, 1u) drawn inside
-- (x, y, w, h), its corners painted once (no doubled alpha).
function ZeD.Atoms.frame(panel, x, y, w, h, color, alpha, t)
    if not color or w <= 0 or h <= 0 then return end
    t = t or ZeD.T.hair
    local a = (color.a or 1) * (alpha or 1)
    local r, g, b = color.r, color.g, color.b
    panel:drawRect(x, y, w, t, a, r, g, b)
    panel:drawRect(x, y + h - t, w, t, a, r, g, b)
    if h > 2 * t then
        panel:drawRect(x, y + t, t, h - 2 * t, a, r, g, b)
        panel:drawRect(x + w - t, y + t, t, h - 2 * t, a, r, g, b)
    end
end

--- System 7's hard shadow: 1u right and 1u down, black at 0.5. Only things that
-- pop up over the game cast it (menus, context lists, hover boxes, balloons,
-- wheel cells, dropdown lists). Draw it before or after the box; it sits outside.
function ZeD.Atoms.drawHardShadow(panel, x, y, w, h)
    local u = ZeD.T.hair
    panel:drawRect(x + w, y + u, u, h, 0.5, 0, 0, 0)      -- right, down to the corner
    panel:drawRect(x + u, y + h, w - u, u, 0.5, 0, 0, 0)  -- bottom, short of the corner
end

--- The top-level element a panel sits in (its window, or a HUD panel itself).
function ZeD.Atoms.rootOf(panel)
    local p, n = panel, 0
    while p and p.parent and n < 64 do p = p.parent; n = n + 1 end
    return p
end

--- The window a panel sits in: its ZeD_Window (ZeD.Surface.windowOf), else its
-- top-level element (a HUD panel, a main menu screen).
function ZeD.Atoms.windowOf(panel)
    local S = ZeD.Surface
    local w = S and S.windowOf and S.windowOf(panel)
    return w or ZeD.Atoms.rootOf(panel)
end

--- True when `anc` is `panel` or one of its parents.
function ZeD.Atoms.isAncestor(anc, panel)
    local p, n = panel, 0
    while p and n < 64 do
        if p == anc then return true end
        p = p.parent; n = n + 1
    end
    return false
end

--- Mouse hover over a rect in panel space, for library pieces whose callers pass
-- no hover state. Off while the controller's mark is showing, so a pointer left
-- resting on a button never paints a second highlight beside the pad's.
-- A scrolled view: the clip a surface has set for the draw in progress
-- (setStencilRect, tracked by ZeD.Surface.clip) bounds the hover on its own, so
-- a row scrolled half under a header never lights while the pointer is on the
-- header. view (optional) says it outright, in the same panel space:
--   { x, y, w, h }  the part of the panel the rect can be seen in (the list's window)
--   { ox, oy }      the content is drawn shifted by this much (the rect is tested there)
function ZeD.Atoms.mouseIn(panel, x, y, w, h, view)
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.cuesVisible and F.cuesVisible() then return false end
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if view then
        x, y = x + (view.ox or 0), y + (view.oy or 0)
        if view.w and view.h then
            local vx, vy = view.x or 0, view.y or 0
            if mx < vx or mx >= vx + view.w or my < vy or my >= vy + view.h then return false end
        end
    end
    if not (mx >= x and mx < x + w and my >= y and my < y + h) then return false end
    local S = ZeD.Surface
    local c = S and S.clip and S.clip()
    if c then
        local ax, ay = getMouseX(), getMouseY()
        if ax < c.x0 or ax >= c.x1 or ay < c.y0 or ay >= c.y1 then return false end
    end
    return true
end

-- ============================================================================
-- 01. LABEL (draw helper)
-- Not a component — a draw function called inside a parent's render().
-- Three variants: heading, body, secondary.
-- ============================================================================

--- Draw a heading label (monospace, bold — system chrome voice)
-- @param panel  The parent ISPanel (provides drawing context)
-- @param text   String to draw
-- @param x, y   Position relative to parent
-- @param color  Optional color override (defaults to ZeD.T.textHead)
function ZeD.Atoms.drawHeading(panel, text, x, y, color)
    local c = color or ZeD.T.textHead
    local padTop = ZeD.T.sp.beforeHead or 0
    panel:drawText(text, x, y + padTop, c.r, c.g, c.b, c.a, ZeD.T.fontF1)
end

--- Draw a title (Bahnschrift Bold — display voice, 10% tracking baked in)
function ZeD.Atoms.drawTitle(panel, text, x, y, color)
    local c = color or ZeD.T.textHead
    panel:drawText(text, x, y, c.r, c.g, c.b, c.a, ZeD.T.fontF5)
end

--- Draw a stat value (K22 Xanthus — data voice, 42% tracking baked in)
function ZeD.Atoms.drawStat(panel, text, x, y, color)
    local c = color or ZeD.T.text
    panel:drawText(text, x, y, c.r, c.g, c.b, c.a, ZeD.T.fontF3)
end

--- Draw a body label (sans — content voice)
function ZeD.Atoms.drawBody(panel, text, x, y, color)
    local c = color or ZeD.T.text
    panel:drawText(text, x, y, c.r, c.g, c.b, c.a, ZeD.T.fontF2)
end

--- Draw a secondary label (monospace — metadata voice)
function ZeD.Atoms.drawSecondary(panel, text, x, y, color)
    local c = color or ZeD.T.textSec
    panel:drawText(text, x, y, c.r, c.g, c.b, c.a, ZeD.T.fontF1)
end

--- Draw right-aligned text (useful for metadata in list rows)
function ZeD.Atoms.drawTextRight(panel, text, x, y, font, color)
    local c = color or ZeD.T.textSec
    local tw = ZeD.TM:MeasureStringX(font or ZeD.T.fontF1, text)
    panel:drawText(text, x - tw, y, c.r, c.g, c.b, c.a, font or ZeD.T.fontF1)
end

-- ============================================================================
-- 02. DIVIDER (draw helper)
-- A 1px line for separating content. Horizontal or vertical.
-- ============================================================================

--- Draw a horizontal divider line
-- @param panel  The parent ISPanel
-- @param x      Left edge
-- @param y      Vertical position
-- @param w      Width of the line
-- @param strong If true, uses borderS (stronger). Default uses border.
function ZeD.Atoms.drawDividerH(panel, x, y, w, strong)
    local c = strong and ZeD.T.borderS or ZeD.T.border
    local h = ZeD.T.line(ZeD.T.borderW)  -- one hairline, two in High Contrast (T.borderW is design units; T.line keeps 2 = two hairlines at 1.25 / 1.5)
    panel:drawRect(x, y, w, h, c.a, c.r, c.g, c.b)
end

--- Draw a vertical divider line
function ZeD.Atoms.drawDividerV(panel, x, y, h, strong)
    local c = strong and ZeD.T.borderS or ZeD.T.border
    local w = ZeD.T.line(ZeD.T.borderW)
    panel:drawRect(x, y, w, h, c.a, c.r, c.g, c.b)
end

-- ============================================================================
-- 02b. SELECTIVE BORDER (draw helper)
-- Like drawRectBorder but only draws the edges specified in the edges table.
-- Used by structural containers to avoid double borders at flush edges.
-- ============================================================================

--- Draw a selective border around a rectangle
-- @param panel  The parent ISPanel
-- @param x, y   Top-left position
-- @param w, h   Dimensions
-- @param edges  Table {top=bool, right=bool, bottom=bool, left=bool} — nil means all true
-- @param strong If true, uses borderS. Default uses borderS (structural borders).
function ZeD.Atoms.drawBorder(panel, x, y, w, h, edges, strong)
    local T = ZeD.T
    local c = strong ~= false and T.borderS or T.border
    local bw = T.line(T.borderW)  -- T.borderW is design units (1, HC 2): that many hairlines; the HC test below reads the raw token

    -- Default: all edges drawn
    if not edges then
        panel:drawRectBorder(x, y, w, h, c.a, c.r, c.g, c.b)
        if T.borderW >= 2 then
            do local i = (panel.zedScaled and T.px(1)) or 1; panel:drawRectBorder(x + i, y + i, w - 2 * i, h - 2 * i, c.a, c.r, c.g, c.b) end  -- HC double ring: inset by the border's own thickness (scaled on ZeD panels)
        end
        return
    end

    -- Individual edges
    if edges.top then
        panel:drawRect(x, y, w, bw, c.a, c.r, c.g, c.b)
    end
    if edges.bottom then
        panel:drawRect(x, y + h - bw, w, bw, c.a, c.r, c.g, c.b)
    end
    if edges.left then
        panel:drawRect(x, y, bw, h, c.a, c.r, c.g, c.b)
    end
    if edges.right then
        panel:drawRect(x + w - bw, y, bw, h, c.a, c.r, c.g, c.b)
    end
end

-- ============================================================================
-- 03. ICON CONTAINER (draw helper)
-- Draws a texture centered in a fixed-size box.
-- The container itself is invisible — it just positions the texture.
-- ============================================================================

--- Draw an icon texture centered in a box
-- @param panel    The parent ISPanel
-- @param texture  A Texture object from getTexture()
-- @param x, y     Top-left of the container box
-- @param size     Container size (use ZeD.T.iconSm/iconMd/iconLg/iconXl)
-- @param alpha    Optional alpha (defaults to 1.0, use disabledAlpha for disabled)
-- Sized textures (Oct 13 2026): icons baked at 8..64 px
-- (ZeDUI/tools/icons/bake_tab_icons.py) as <dir><name>_<size>.png. Returns the
-- smallest baked size at or above `px`, so a 2x screen draws a true 32 px icon
-- instead of stretching a 16 px one, and every UI scale step (0.5x..2x) lands
-- on a baked size. Cached; nil when the file is missing.
local SIZED_STEPS = { 8, 12, 16, 20, 24, 28, 32, 36, 40, 48, 56, 64 }
local _sizedCache = {}
function ZeD.Atoms.sizedTexture(dir, name, px)
    local pick = SIZED_STEPS[#SIZED_STEPS]
    for _, step in ipairs(SIZED_STEPS) do
        if step >= px then pick = step; break end
    end
    local key = dir .. name .. "_" .. pick
    local t = _sizedCache[key]
    if t == nil then
        t = getTexture(key .. ".png") or false
        _sizedCache[key] = t
    end
    return t or nil
end

function ZeD.Atoms.drawIcon(panel, texture, x, y, size, alpha, tint)
    if not texture then return end
    local a = alpha or 1.0
    -- Tint color: defaults to theme text color so white icons match the theme
    local T = ZeD.T
    local r, g, b = 1, 1, 1
    if tint then
        r, g, b = tint.r, tint.g, tint.b
    elseif T then
        r, g, b = T.text.r, T.text.g, T.text.b
    end
    -- drawTextureScaledAspect fits into bounding box preserving aspect — pass size directly
    panel:drawTextureScaledAspect(texture, x, y, size, size, a, r, g, b)
end

-- ============================================================================
-- 04. FILL BAR (draw helper)
-- A horizontal bar showing a value as a proportion of a maximum.
-- Supports graduated color (green → yellow → red based on percentage).
-- ============================================================================

--- Draw a fill bar
-- @param panel     The parent ISPanel
-- @param x, y      Top-left position
-- @param w         Total width of the bar
-- @param percent   Fill amount, 0.0 to 1.0
-- @param graduated If true, color shifts based on percentage thresholds
-- @param fillColor Optional fixed fill color (overrides graduated logic)
-- @param h         Optional height; default T.fillBarH (13 / 15 Large). List rows use ZeD.Atoms.fillBarCompactH()
--
-- The System 7 "About This Macintosh" bar (director, Oct 26 2026: "a more chunky strip than a glowing line"):
-- a framed strip with a dark well and a flat, solid fill. Every condition, progress and amount bar draws
-- through here; no 1-5 unit lines, no glow, no gradient.
function ZeD.Atoms.fillBarCompactH()
    return ZeD.T.px(8)
end

function ZeD.Atoms.drawFillBar(panel, x, y, w, percent, graduated, fillColor, h)
    local T = ZeD.T
    h = h or T.fillBarH
    local bw = T.line(T.borderW)  -- T.borderW is design units (1, HC 2): that many hairlines; the HC test below reads the raw token

    -- Clamp percent
    percent = math.max(0.0, math.min(1.0, percent or 0))

    -- The well (the empty portion): the deepest surface, solid, so the strip reads the same over any see-through
    local bg = T.base
    panel:drawRect(x, y, w, h, 1, bg.r, bg.g, bg.b)

    -- Fill portion
    local fillW = math.max(0, math.floor((w - bw * 2) * percent))
    if fillW > 0 then
        -- Determine fill color
        local fc
        if fillColor then
            fc = fillColor
        elseif graduated then
            if percent > 0.6 then
                fc = T.positive
            elseif percent > 0.3 then
                fc = T.warning
            else
                fc = T.danger
            end
        else
            fc = T.accent
        end
        -- Minimum visible width of 2 units so tiny values still show; a flat, solid fill (no half-alpha glow)
        fillW = math.max(T.px(2), fillW)
        panel:drawRect(x + bw, y + bw, fillW, h - bw * 2, 1, fc.r, fc.g, fc.b)
    end

    -- Border (drawn on top)
    local bc = T.borderS
    panel:drawRectBorder(x, y, w, h, bc.a, bc.r, bc.g, bc.b)
    -- If High Contrast, draw a second border inset by 1px for thickness
    if T.borderW >= 2 then
        do local i = (panel.zedScaled and T.px(1)) or 1; panel:drawRectBorder(x + i, y + i, w - 2 * i, h - 2 * i, bc.a, bc.r, bc.g, bc.b) end  -- HC double ring: inset by the border's own thickness (scaled on ZeD panels)
    end
end

-- ============================================================================
-- 04a. GRADIENT BAR (draw helper)
-- Multi-stop horizontal gradient bar with a needle indicator.
-- General-purpose gauge for any 0-1 metric visualization.
--
-- stops:   Array of color tables (defaults to thermal 5-stop spectrum)
-- needlePct: 0.0 to 1.0 — position of the white needle indicator
-- ============================================================================

function ZeD.Atoms.drawGradientBar(panel, x, y, w, h, needlePct, stops)
    local T = ZeD.T
    stops = stops or { T.tempCold, T.tempCool, T.tempNorm, T.tempWarm, T.tempHot }
    local numSegs = #stops - 1
    if numSegs < 1 then return end
    local segW = w / numSegs

    -- Solid steps (the status bars' rule: no half-alpha), each stop then the halfway colour
    -- to the next, on whole pixels so neighbours meet without a seam or an overlap
    local x0 = x
    for si = 1, numSegs do
        local c1 = stops[si]
        local c2 = stops[si + 1]
        local xm = x + math.floor((si - 0.5) * segW + 0.5)
        local x1 = (si == numSegs) and (x + w) or (x + math.floor(si * segW + 0.5))
        panel:drawRect(x0, y, xm - x0, h, 1, c1.r, c1.g, c1.b)
        panel:drawRect(xm, y, x1 - xm, h, 1, (c1.r + c2.r) / 2, (c1.g + c2.g) / 2, (c1.b + c2.b) / 2)
        x0 = x1
    end

    -- the frame: 1u, 2u on High contrast
    ZeD.Atoms.frame(panel, x, y, w, h, T.borderS, 1, T.line(T.borderW))

    local clampedPct = math.max(0, math.min(1, needlePct or 0))
    local needleX = x + math.floor(w * clampedPct)
    panel:drawRect(needleX - T.px(1), y - T.px(1), T.px(1) * 2, h + T.px(1) * 2, 0.9, 1.0, 1.0, 1.0)
end

-- ============================================================================
-- 04b. BAR SEGMENTS (draw helper)
-- Multi-segment fill bar — background + stacked fills + border, no button.
-- Used for zone-top condition readout in the clothing detail zone.
-- ============================================================================

--- Draw a multi-segment fill bar.
-- @param panel  ISPanel
-- @param x, y   Top-left (local coords)
-- @param w      Total width
-- @param h      Bar height (use T.fillBarH for standard)
-- @param segs   Array of {ratio=0..1, color={r,g,b,a}} drawn left-to-right
function ZeD.Atoms.drawBarSegs(panel, x, y, w, h, segs)
    local T = ZeD.T
    local bg = T.surf3
    panel:drawRect(x, y, w, h, bg.a, bg.r, bg.g, bg.b)
    local fx = x
    for _, seg in ipairs(segs) do
        if seg.ratio > 0 and seg.color then
            local fw = math.max(T.px(1), math.floor(w * seg.ratio))
            local c = seg.color
            panel:drawRect(fx, y, fw, h, c.a or 0.55, c.r, c.g, c.b)
            fx = fx + fw
        end
    end
    local bc = T.border
    panel:drawRectBorder(x, y, w, h, bc.a, bc.r, bc.g, bc.b)
end

-- ============================================================================
-- 04c. SEGMENTED BAR — K-of-N discrete cells (S115)
-- Different from drawBarSegs above: this draws N independent segment cells
-- left-to-right with a 1px gap between each. The first K are painted in
-- onColor, the remaining (N-K) in offColor. Used by the radio chassis for
-- BATT (4 segs) and VOL (8 segs) readouts on both Premium VFD and ValuTech LCD.
-- ============================================================================

--- Draw N discrete segment cells with K of them lit.
-- @param panel    ISPanel
-- @param x, y     Top-left in panel-local coords
-- @param w, h     Total bar width / height
-- @param n        Total segment count (e.g., 8 for VOL)
-- @param k        Lit segment count, [0..n] (clamped)
-- @param onColor  Color for lit segments — RGBA table (framed: default the accent)
-- @param offColor Color for unlit segments — RGBA table (framed: nil shows the well)
-- @param gap      Pixels between segments (default 1)
-- @param opts     Optional { framed = true }: a meter in the window (cohesion spec 9b), the
--                 fill bar's look: a 1u borderS frame (2u High contrast) round a solid dark
--                 well (T.base), the cells inside it, at least 8u tall whatever h says.
--                 Without it the bare cells, as the radio's printed LCD draws them.
-- @return height  the height drawn (framed: at least 8u)
function ZeD.Atoms.drawSegBar(panel, x, y, w, h, n, k, onColor, offColor, gap, opts)
    local T = ZeD.T
    if n <= 0 then return 0 end
    gap = gap or T.px(1)
    if k < 0 then k = 0 end
    if k > n then k = n end
    local framed = opts and opts.framed
    local fx, fy, fw, fh, bw = x, y, w, h, 0
    if framed then
        fh = math.max(h, T.px(8))
        bw = T.line(T.borderW)
        local bg = T.base
        panel:drawRect(fx, fy, fw, fh, 1, bg.r, bg.g, bg.b)
        x, y, w, h = fx + bw, fy + bw, fw - 2 * bw, fh - 2 * bw
        onColor = onColor or T.accent
    end
    -- Width per segment after subtracting (n-1) gaps. Floor so we never overrun.
    local segW = math.floor((w - gap * (n - 1)) / n)
    if segW < T.px(1) then segW = T.px(1) end
    for i = 1, n do
        local sx = x + (i - 1) * (segW + gap)
        local c  = (i <= k) and onColor or offColor
        if c then
            -- framed: the last cell runs to the frame, so a full meter has no strip of well at its end
            local cw = (framed and i == n) and (x + w - sx) or segW
            panel:drawRect(sx, y, cw, h, framed and 1 or (c.a or 1.0), c.r, c.g, c.b)
        end
    end
    if framed then
        ZeD.Atoms.frame(panel, fx, fy, fw, fh, T.borderS, 1, bw)
        return fh
    end
    return h
end

-- ============================================================================
-- 05. CHECKBOX (draw helper)
-- A square toggle with an X mark when checked. System 6 style.
-- ============================================================================

--- Draw a checkbox
-- @param panel   The parent ISPanel
-- @param x, y    Top-left position
-- @param checked Boolean — is it on?
-- @param hovered Boolean — is the mouse over it?
-- @param disabled Boolean — is it grayed out?
function ZeD.Atoms.drawCheckbox(panel, x, y, checked, hovered, disabled)
    local T = ZeD.T
    local sz = T.checkboxSz
    local alpha = disabled and T.disabledAlpha or 1.0

    -- Background
    if checked then
        local ac = T.accent
        panel:drawRect(x, y, sz, sz, ac.a * alpha, ac.r, ac.g, ac.b)
    else
        local bg = hovered and T.hover or T.surf2
        panel:drawRect(x, y, sz, sz, bg.a * alpha, bg.r, bg.g, bg.b)
    end

    -- Border
    local bc = checked and T.accent or T.borderS
    panel:drawRectBorder(x, y, sz, sz, bc.a * alpha, bc.r, bc.g, bc.b)

    -- X mark when checked (two diagonal lines)
    if checked then
        local tc = T.textOnAccent
        local m = T.px(3)  -- margin from edge for the X
        -- Top-left to bottom-right
        -- PZ doesn't have drawLine, so we draw thin rects at angles
        -- Approximate with a series of 1px rects along the diagonal
        local u = T.px(1)  -- S124 scale: strokes are 1 design px; the loop steps one dot at a time
        for i = 0, sz - m * 2 - u, u do
            local px = x + m + i
            local py = y + m + i
            panel:drawRect(px, py, u, u, tc.a * alpha, tc.r, tc.g, tc.b)
            -- Other diagonal
            local py2 = y + sz - m - u - i
            panel:drawRect(px, py2, u, u, tc.a * alpha, tc.r, tc.g, tc.b)
        end
    end
end

-- ============================================================================
-- 05b. RADIO BUTTON (draw helper)
-- The System 7 round radio button, for one of a few choices: a pixel circle on
-- the hairline grid (12 x 12 cells, each T.hair square), the centre filled when
-- on. Round is right here (and on hardware knobs): it is a real 1993 part.
-- Status marks stay square.
-- ============================================================================

-- per row (0-based from the top): runs { firstCol, count } of the outline, the
-- inside and the centre dot
local RADIO_N = 12
local RADIO_OUT = {
    { {4, 4} }, { {2, 2}, {8, 2} }, { {1, 1}, {10, 1} }, { {1, 1}, {10, 1} },
    { {0, 1}, {11, 1} }, { {0, 1}, {11, 1} }, { {0, 1}, {11, 1} }, { {0, 1}, {11, 1} },
    { {1, 1}, {10, 1} }, { {1, 1}, {10, 1} }, { {2, 2}, {8, 2} }, { {4, 4} },
}
local RADIO_IN = { false, {4, 4}, {2, 8}, {2, 8}, {1, 10}, {1, 10}, {1, 10}, {1, 10}, {2, 8}, {2, 8}, {4, 4}, false }
local RADIO_DOT = { false, false, false, {4, 4}, {3, 6}, {3, 6}, {3, 6}, {3, 6}, {4, 4}, false, false, false }

--- The radio button's size in screen px (it is square).
function ZeD.Atoms.radioSize()
    return RADIO_N * ZeD.T.hair
end

--- Draw a radio button with its top-left at (x, y).
-- @param on    the choice is the current one
-- @param opts  optional { hover = bool, disabled = bool }
-- @return size (px, square)
function ZeD.Atoms.drawRadio(panel, x, y, on, opts)
    local T = ZeD.T
    opts = opts or NO_OPTS
    local u = T.hair
    local a = opts.disabled and T.disabledAlpha or 1
    local inner = (opts.hover and not opts.disabled) and T.hover or T.surf2
    local ia = (inner.a or 1) * a
    for r = 1, RADIO_N do
        local s = RADIO_IN[r]
        if s then panel:drawRect(x + s[1] * u, y + (r - 1) * u, s[2] * u, u, ia, inner.r, inner.g, inner.b) end
    end
    local bc = on and T.accent or T.borderS
    local ba = (bc.a or 1) * a
    for r = 1, RADIO_N do
        for _, s in ipairs(RADIO_OUT[r]) do
            panel:drawRect(x + s[1] * u, y + (r - 1) * u, s[2] * u, u, ba, bc.r, bc.g, bc.b)
        end
    end
    if on then
        local dc = T.accent
        local da = (dc.a or 1) * a
        for r = 1, RADIO_N do
            local s = RADIO_DOT[r]
            if s then panel:drawRect(x + s[1] * u, y + (r - 1) * u, s[2] * u, u, da, dc.r, dc.g, dc.b) end
        end
    end
    return RADIO_N * u
end

-- ============================================================================
-- 06. TAG (draw helper)
-- The one look for a small word that names a state (cohesion spec 9): 16u tall,
-- a 1u borderS outline, F1, sentence case, 5u side padding, and when the state
-- has a status a 6u square mark in its colour before the word. No tinted fill,
-- no coloured words: the mark carries the colour. ZeD.Molecules.drawTag is the
-- public name; A.drawBadge and the card's flag chips draw through this.
-- ============================================================================

-- the tag's size and parts, shared by drawTag and tagW: width, the words as drawn,
-- font, mark size, mark gap, content width
local function tagMeasure(T, text, marked, opts)
    local font = opts.font or T.fontF1
    local s = text and tostring(text) or ""
    if not opts.keepCase then s = textCase(s) end
    local sq = marked and T.px(6) or 0
    local gap = marked and T.px(4) or 0
    local contentW = sq + gap + ZeD.TM:MeasureStringX(font, s)
    return math.max(opts.minW or 0, contentW + T.px(5) * 2), s, font, sq, gap, contentW
end

--- The width drawTag draws for these words (marked = it carries a status mark;
-- opts as drawTag: font, minW, keepCase), so a layout can place a tag before
-- drawing it instead of copying its padding. Its height is 16u (opts.h).
function ZeD.Atoms.tagW(text, marked, opts)
    local w = tagMeasure(ZeD.T, text, marked, opts or NO_OPTS)
    return w
end

--- Draw a tag.
-- @param statusColor  nil (no mark) or the colour of the 6u square mark
-- @param opts  optional { font, h, minW, keepCase, alpha, hollow, textColor }
--   h / minW give a box at least that size (drawBadge keeps the box it always had,
--   so callers that measure it themselves still line up); the content is centred.
--   hollow = the mark as a 1u outline (an "off" state).
-- @return width, height
function ZeD.Atoms.drawTag(panel, x, y, text, statusColor, opts)
    local T = ZeD.T
    opts = opts or NO_OPTS
    local tm = ZeD.TM
    local w, s, font, sq, gap, contentW = tagMeasure(T, text, statusColor ~= nil, opts)
    local h = opts.h or T.px(16)
    local a = opts.alpha or 1
    ZeD.Atoms.frame(panel, x, y, w, h, T.borderS, a)
    local cx = x + math.floor((w - contentW) / 2)
    if statusColor then
        local sy = y + math.floor((h - sq) / 2)
        if opts.hollow then
            ZeD.Atoms.frame(panel, cx, sy, sq, sq, statusColor, a)
        else
            panel:drawRect(cx, sy, sq, sq, (statusColor.a or 1) * a, statusColor.r, statusColor.g, statusColor.b)
        end
        cx = cx + sq + gap
    end
    local tc = opts.textColor or T.text
    panel:drawText(s, cx, y + math.floor((h - tm:getFontHeight(font)) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * a, font)
    return w, h
end

-- a badge variant's status colour (accent and neutral carry no status: no mark)
local function badgeStatus(T, variant)
    if variant == "danger" then return T.danger
    elseif variant == "warning" then return T.warning
    elseif variant == "positive" then return T.positive
    elseif variant == "info" then return T.info end
    return nil
end

--- Draw a badge: now the tag look (drawTag), in the box the old badge took, so
-- the callers that measure that box themselves (text + badgePadX / badgePadY in
-- their font) still line up. The words read in sentence case whatever case they
-- arrive in; the variant becomes the status mark (danger, warning, positive,
-- info), accent and neutral draw none.
-- @return width, height
function ZeD.Atoms.drawBadge(panel, text, x, y, variant, disabled, font, noUpper)
    local T = ZeD.T
    local f = font or T.fontF3
    local s = text and tostring(text) or ""
    local old = noUpper and s or ZeD.upper(s)   -- the words the old box was measured on
    local tm = ZeD.TM
    local minW = tm:MeasureStringX(f, old) + T.sp.badgePadX * 2
    local h = tm:MeasureStringY(f, old) + T.sp.badgePadY * 2
    return ZeD.Atoms.drawTag(panel, x, y, s, badgeStatus(T, variant),
        { font = f, h = h, minW = minW, alpha = disabled and T.disabledAlpha or nil })
end

-- ============================================================================
-- 06b. STATUS MARKS (draw helpers)
-- A status is a 6u square in the status colour (cohesion spec 1.2: no round
-- dots anywhere in the UI), one size everywhere. The `size` the callers pass is
-- the box they laid out for the mark: the square is centred in it, so rows that
-- were measured for a 7u or 8u dot stay lined up.
-- ============================================================================

local function markOrigin(x, y, size, sq)
    if not size then return x, y end
    local off = math.floor((size - sq) / 2)
    return x + off, y + off
end

--- A filled 6u status square.
function ZeD.Atoms.drawStatusDot(panel, x, y, color, size)
    if not color then return end
    local sq = ZeD.T.px(6)
    x, y = markOrigin(x, y, size or ZeD.T.px(7), sq)
    panel:drawRect(x, y, sq, sq, color.a or 1, color.r, color.g, color.b)
end

--- A hollow 6u status square (1u border): a state that is neither go nor stop
-- (a recipe that needs a station), NEEDS lines, unread.
function ZeD.Atoms.drawStatusHollow(panel, x, y, color, size)
    if not color then return end
    local sq = ZeD.T.px(6)
    x, y = markOrigin(x, y, size or ZeD.T.px(7), sq)
    ZeD.Atoms.frame(panel, x, y, sq, sq, color)
end

-- the older name of the hollow mark (it was a ring)
ZeD.Atoms.drawStatusRing = ZeD.Atoms.drawStatusHollow

--- A half status square: the outline with its left half filled (a half-read mark).
function ZeD.Atoms.drawStatusHalf(panel, x, y, color, size)
    if not color then return end
    local sq = ZeD.T.px(6)
    x, y = markOrigin(x, y, size or ZeD.T.px(7), sq)
    ZeD.Atoms.frame(panel, x, y, sq, sq, color)
    panel:drawRect(x, y, math.floor(sq / 2), sq, color.a or 1, color.r, color.g, color.b)
end

-- ============================================================================
-- 06c. LAMP (draw helper)
-- A lamp on a piece of hardware (a plate, a faceplate, the belt) stays round:
-- it is a real bulb, not a status mark. A filled circle made of whole screen-pixel
-- rows, so its edge is crisp at every scale (as the belt's discs); the rows are
-- worked out once per size, equal neighbouring rows merged into one rectangle.
-- ============================================================================

local _lampShapes, _lampN = {}, 0
local function lampShape(d)
    local e = _lampShapes[d]
    if e then return e end
    local rad = d / 2
    local rx, ry, rw, rh, n = {}, {}, {}, {}, 0
    for row = 0, d - 1 do
        local dy = math.abs(row + 0.5 - rad)
        local half = math.sqrt(math.max(0, rad * rad - dy * dy))
        local x0 = math.floor(rad - half + 0.5)
        local w = d - 2 * x0
        if w > 0 then
            if n > 0 and rx[n] == x0 and rw[n] == w and ry[n] + rh[n] == row then
                rh[n] = rh[n] + 1
            else
                n = n + 1
                rx[n], ry[n], rw[n], rh[n] = x0, row, w, 1
            end
        end
    end
    e = { n = n, x = rx, y = ry, w = rw, h = rh }
    -- (a handful of sizes in use; a long walk through the scales starts the table over)
    _lampN = _lampN + 1
    if _lampN > 32 then _lampShapes, _lampN = {}, 1 end
    _lampShapes[d] = e
    return e
end

--- Draw a round lamp in the box (x, y, d x d).
-- @param d      diameter in screen px (default T.px(6)); whole pixels
-- @param color  the lamp's colour
-- @param a      optional alpha (default the colour's own)
function ZeD.Atoms.drawLamp(panel, x, y, d, color, a)
    if not color then return end
    d = math.floor(d or ZeD.T.px(6))
    if d <= 0 then return end
    a = a or color.a or 1
    local e = lampShape(d)
    local ex, ey, ew, eh = e.x, e.y, e.w, e.h
    local r, g, b = color.r, color.g, color.b
    for i = 1, e.n do panel:drawRect(x + ex[i], y + ey[i], ew[i], eh[i], a, r, g, b) end
end

-- ============================================================================
-- 07. TOOLTIP BUBBLE (component factory)
-- A floating panel for hover information. Created as an ISPanel that gets
-- added to UIManager when shown, removed when hidden.
-- ============================================================================

ZeD_Tooltip = ISPanel:derive("ZeD_Tooltip")

function ZeD_Tooltip:new(x, y)
    -- Start with minimal size — it resizes to fit content
    local o = ISPanel:new(x, y, ZeD.T.px(100), ZeD.T.px(40))
    setmetatable(o, self)
    self.__index = self
    o.lines = {}           -- Array of {text=, variant=} where variant is "heading","body","secondary"
    o.maxWidth = 250   -- S124 scale: maxWidth / padX / padY stay design units; wrapped with T.px where used
    o.padX = 10
    o.padY = 6
    o.moveWithMouse = false
    o.visible = false
    return o
end

--- Set tooltip content. Call before showing.
-- @param lines  Array of {text=string, variant="heading"|"body"|"secondary"}
function ZeD_Tooltip:setContent(lines)
    self.lines = lines or {}
    self:recalcSize()
end

function ZeD_Tooltip:recalcSize()
    local T = ZeD.T
    local maxW = 0
    local totalH = 0

    for _, line in ipairs(self.lines) do
        local font
        if line.variant == "heading" then font = T.fontF4
        elseif line.variant == "secondary" then font = T.fontF3
        else font = T.fontF2 end

        local w = ZeD.TM:MeasureStringX(font, line.text)
        local h = ZeD.TM:MeasureStringY(font, line.text)
        maxW = math.max(maxW, w)
        totalH = totalH + h + T.px(2)  -- 2px line spacing
    end

    self:setWidth(math.min(maxW + T.px(self.padX) * 2, T.px(self.maxWidth)))
    self:setHeight(totalH + T.px(self.padY) * 2)
end

-- The detail card's look (ZeD.Molecules.drawDetailCard): surface 1, solid (hover
-- boxes never go see-through), a 1u frame and System 7's hard shadow.
function ZeD_Tooltip:prerender()
    local T = ZeD.T
    local s1 = T.surf1
    ZeD.Atoms.drawHardShadow(self, 0, 0, self.width, self.height)
    self:drawRect(0, 0, self.width, self.height, 1, s1.r, s1.g, s1.b)
    ZeD.Atoms.frame(self, 0, 0, self.width, self.height, T.borderS)
end

function ZeD_Tooltip:render()
    local T = ZeD.T
    local y = T.px(self.padY)

    for _, line in ipairs(self.lines) do
        local font, color
        if line.variant == "heading" then
            font = T.fontF4
            color = T.textHead
        elseif line.variant == "secondary" then
            font = T.fontF3
            color = T.textDim
        else
            font = T.fontF2
            color = T.text
        end

        self:drawText(line.text, T.px(self.padX), y, color.r, color.g, color.b, color.a, font)
        y = y + ZeD.TM:MeasureStringY(font, line.text) + T.px(2)
    end
end

-- Register the tooltip class so it's available globally
ZeD.Atoms.Tooltip = ZeD_Tooltip

-- ============================================================================
-- 07b. HOVER BOXES (cohesion spec 9)
-- Two boxes, one look: the hint (one line of F2, for icon-only buttons) and the
-- detail card (a title in F4, lines in F2 / F3; ZeD.Molecules.drawDetailCard).
-- Both are surface 1, solid, framed in 1u borderS with System 7's hard shadow,
-- shown after ZeD.HINT_DELAY_MS of rest, placed below-right of the pointer and
-- flipped to stay on screen.
--
-- A box must sit above everything in its window, so a control does not draw it
-- itself: it asks for it each frame it is hovered (requestHint /
-- requestDetailCard, keyed by its window) and the window's overlay pass draws it
-- (ZeD.Focus.drawOverlay -> drawPendingHover). A request lives for one frame; the
-- delay restarts whenever the key changes. Surfaces that keep their own hover
-- state can use hoverReady(state, key) for the same delay.
-- ============================================================================

local HOVER_STALE_MS = 150   -- a request older than this is from an earlier frame

--- Where a hover box of w x h goes for an anchor point (the pointer) at (ax, ay)
-- in panel space: below-right, clear of the arrow pointer, flipped left / up when
-- it would leave the screen.
function ZeD.Atoms.hoverBoxPlace(panel, ax, ay, w, h)
    local T = ZeD.T
    local x, y = ax + T.px(12), ay + T.px(18)
    local px0, py0 = panel:getAbsoluteX(), panel:getAbsoluteY()
    local core = getCore and getCore()
    if core then
        local sw, sh = core:getScreenWidth(), core:getScreenHeight()
        if px0 + x + w + T.hair > sw then x = ax - T.px(4) - w end
        if py0 + y + h + T.hair > sh then y = ay - T.px(4) - h end
        if px0 + x < 0 then x = -px0 end
        if py0 + y < 0 then y = -py0 end
    end
    return x, y
end

--- The hover box's shell: shadow, solid surface 1, 1u frame.
function ZeD.Atoms.drawHoverShell(panel, x, y, w, h)
    local T = ZeD.T
    local s1 = T.surf1
    ZeD.Atoms.drawHardShadow(panel, x, y, w, h)
    panel:drawRect(x, y, w, h, 1, s1.r, s1.g, s1.b)
    ZeD.Atoms.frame(panel, x, y, w, h, T.borderS)
end

--- Draw the one-line hint for an anchor point (ax, ay) in panel space.
-- @return x, y, w, h of the box
function ZeD.Atoms.drawHintBox(panel, text, ax, ay)
    if not text or text == "" then return end
    local T = ZeD.T
    local f2 = T.fontF2
    local padX, padY = T.px(8), T.px(4)
    local w = ZeD.TM:MeasureStringX(f2, text) + padX * 2
    local h = ZeD.TM:getFontHeight(f2) + padY * 2
    local x, y = ZeD.Atoms.hoverBoxPlace(panel, ax, ay, w, h)
    ZeD.Atoms.drawHoverShell(panel, x, y, w, h)
    local tc = T.text
    panel:drawText(text, x + padX, y + padY, tc.r, tc.g, tc.b, tc.a or 1, f2)
    return x, y, w, h
end

--- The shared hover delay for a surface that keeps its own state: call it every
-- frame with the hovered thing's key (nil when nothing is hovered); true once the
-- same key has been hovered for ZeD.HINT_DELAY_MS.
function ZeD.Atoms.hoverReady(st, key)
    if not st then return false end
    if key == nil then st.hoverKey = nil; return false end
    local now = getTimestampMs()
    if st.hoverKey ~= key then st.hoverKey, st.hoverSince = key, now; return false end
    return now - (st.hoverSince or now) >= ZeD.HINT_DELAY_MS
end

local _hoverReq = {}   -- [owner] = { kind, key, text, card, t, panel }: this frame's request
local _hoverSt  = {}   -- [owner] = { key, since, lastT }: the delay

local function hoverRequest(owner, key, panel)
    local r = _hoverReq[owner]
    if not r then r = {}; _hoverReq[owner] = r end
    r.key, r.t, r.panel = key, getTimestampMs(), panel
    return r
end

--- Ask for the hint over `owner` (the window, or a HUD panel) this frame.
-- key names the hovered control (its id); panel = the control's panel (lets an
-- overlay of a window the owner sits in find the request).
function ZeD.Atoms.requestHint(owner, key, text, panel)
    if not owner or not text or text == "" then return end
    local r = hoverRequest(owner, key or text, panel)
    r.kind, r.text, r.card = "hint", text, nil
end

--- Ask for a detail card (the ZeD.Molecules.drawDetailCard spec) this frame.
function ZeD.Atoms.requestDetailCard(owner, key, card, panel)
    if not owner or not card then return end
    local r = hoverRequest(owner, key or card.title or "card", panel)
    r.kind, r.text, r.card = "card", nil, card
end

--- Draw the hover box asked for in `win` this frame, at the pointer, once the
-- delay has passed. Called by the window's overlay pass (ZeD.Focus.drawOverlay)
-- and by the windows' hint layers; whichever runs first in a frame draws it.
function ZeD.Atoms.drawPendingHover(ov, win)
    win = win or ov
    local owner, r = win, _hoverReq[win]
    if not r then
        for o, rr in pairs(_hoverReq) do
            if rr.panel and ZeD.Atoms.isAncestor(win, rr.panel) then owner, r = o, rr; break end
        end
    end
    local st = _hoverSt[win]
    if not st then st = {}; _hoverSt[win] = st end
    local now = getTimestampMs()
    if not r then
        if st.lastT and now - st.lastT > HOVER_STALE_MS then st.key = nil end
        return
    end
    _hoverReq[owner] = nil
    if now - (r.t or 0) > HOVER_STALE_MS then st.key = nil; return end
    st.lastT = r.t
    if st.key ~= r.key then st.key, st.since = r.key, now; return end
    if now - (st.since or now) < ZeD.HINT_DELAY_MS then return end
    local mx, my = ov:getMouseX(), ov:getMouseY()
    if r.kind == "card" then
        local M = ZeD.Molecules
        if M and M.drawDetailCard then M.drawDetailCard(ov, mx, my, r.card) end
    else
        ZeD.Atoms.drawHintBox(ov, r.text, mx, my)
    end
end

-- ----------------------------------------------------------------------------
-- Hover hint layer: the hint for controls that sit at a window's edge, where
-- their own panel is too narrow or sits under later siblings. The window keeps a
-- click-through layer as its LAST child; each frame the control's draw code
-- stamps win[field] = { key, text, x, y, w, h, side = "r"|"l" } (window space,
-- the control's rect) while the pointer rests on it, and the layer draws the
-- hint box at the pointer after ZeD.HINT_DELAY_MS. Nothing stamped = no hint
-- (the stamp is consumed). The layer also draws any hover box the library's
-- controls asked for in this window (drawPendingHover).
-- ----------------------------------------------------------------------------

function ZeD.Atoms.newHintLayer(win, field)
    local layer = ISPanel:new(0, 0, 10, 10)
    layer:initialise()
    layer:instantiate()
    layer.background = false
    layer.javaObject:setConsumeMouseEvents(false)
    layer.prerender = function(self) end
    layer.onMouseDown = function() return false end
    layer.onMouseUp = function() return false end
    layer.onMouseWheel = function() return false end
    layer.render = function(self)
        ZeD.Atoms.drawPendingHover(self, win)
        local c = win[field]
        win[field] = nil
        local kf, sf = field .. "Key", field .. "Since"
        if not c then win[kf] = nil; return end
        local now = getTimestampMs()
        if win[kf] ~= c.key then win[kf], win[sf] = c.key, now; return end
        if now - (win[sf] or now) < ZeD.HINT_DELAY_MS then return end
        ZeD.Atoms.drawHintBox(self, c.text, self:getMouseX(), self:getMouseY())
    end
    return layer
end

-- Keeps the layer the size of its window (call from the window's per-frame code,
-- or the strip draw that stamps the hint).
function ZeD.Atoms.syncHintLayer(win, layer)
    if layer and (layer:getWidth() ~= win:getWidth() or layer:getHeight() ~= win:getHeight()) then
        layer:setWidth(win:getWidth())
        layer:setHeight(win:getHeight())
    end
end

-- ============================================================================
-- 08-10. SCROLLBAR (draw helpers for track, thumb, arrow)
-- These are draw helpers that a scrollbar molecule will compose.
-- ============================================================================

--- Draw the scrollbar track (background gutter)
function ZeD.Atoms.drawScrollTrack(panel, x, y, w, h)
    local T = ZeD.T
    -- Track background provided by window body — only draw borders
    local bc = T.borderS
    panel:drawRect(x, y, T.px(1), h, bc.a, bc.r, bc.g, bc.b)         -- left
    panel:drawRect(x + w - T.px(1), y, T.px(1), h, bc.a, bc.r, bc.g, bc.b) -- right
end

--- Draw the scrollbar thumb
-- @param state  "default", "hover", or "dragging"
function ZeD.Atoms.drawScrollThumb(panel, x, y, w, h, state)
    local T = ZeD.T
    local bg
    if state == "dragging" then
        bg = ZeD.colorAlpha(T.accent, T.selectionA)
    elseif state == "hover" then
        bg = T.surf4
    else
        bg = T.surf3
    end
    panel:drawRect(x, y, w, h, bg.a, bg.r, bg.g, bg.b)
    -- Border
    local bc = T.borderS
    panel:drawRectBorder(x, y, w, h, bc.a, bc.r, bc.g, bc.b)
end

--- Draw a scrollbar arrow button
-- @param direction  "up", "down", "left", or "right"
-- @param state      "default", "hover", or "active"
function ZeD.Atoms.drawScrollArrow(panel, x, y, size, direction, state)
    local T = ZeD.T

    -- Background (default = transparent, window body shows through)
    if state == "active" then
        local bg = ZeD.colorAlpha(T.accent, 0.20)
        panel:drawRect(x, y, size, size, bg.a, bg.r, bg.g, bg.b)
    elseif state == "hover" then
        local bg = T.surf3
        panel:drawRect(x, y, size, size, bg.a, bg.r, bg.g, bg.b)
    end

    -- Border
    local bc = T.borderS
    panel:drawRectBorder(x, y, size, size, bc.a, bc.r, bc.g, bc.b)

    -- Arrow triangle (drawn with 1px rects — no font dependency)
    local gc
    if state == "active" then gc = T.accent
    elseif state == "hover" then gc = T.text
    else gc = T.textDim end

    local cx = x + math.floor(size / 2)  -- center x
    local cy = y + math.floor(size / 2)  -- center y
    local arrSz = math.max(T.px(3), math.floor(size / 4))  -- half-height of arrow (S124 scale: size is scaled; 1px rows rasterize at screen res)

    if direction == "up" then
        for row = 0, arrSz - 1 do
            local px = cx - row
            local py = cy - arrSz / 2 + row
            panel:drawRect(px, py, row * 2 + 1, 1, gc.a, gc.r, gc.g, gc.b)
        end
    elseif direction == "down" then
        for row = 0, arrSz - 1 do
            local px = cx - (arrSz - 1 - row)
            local py = cy - arrSz / 2 + row
            panel:drawRect(px, py, (arrSz - 1 - row) * 2 + 1, 1, gc.a, gc.r, gc.g, gc.b)
        end
    elseif direction == "left" then
        for col = 0, arrSz - 1 do
            local px = cx - arrSz / 2 + col
            local py = cy - col
            panel:drawRect(px, py, 1, col * 2 + 1, gc.a, gc.r, gc.g, gc.b)
        end
    else -- right
        for col = 0, arrSz - 1 do
            local px = cx - arrSz / 2 + col
            local py = cy - (arrSz - 1 - col)
            panel:drawRect(px, py, 1, (arrSz - 1 - col) * 2 + 1, gc.a, gc.r, gc.g, gc.b)
        end
    end
end

-- ============================================================================
-- 12. PROGRESS BAND (S120; the library's parts since the cohesion pass)
-- A strip between the back bar and the flag strip on item cards (and on the
-- Vehicle cards) while a timed action runs on the thing. Two modes:
--   "active" — the accent: the status mark and the bar's fill
--   "danger" — the same in danger red (burning)
-- The words are default text after a 6u status square (no coloured words); the
-- bar is the framed fill bar (ZeD.Atoms.drawFillBar); Cancel is an icon button
-- with an X at the right, centred on both rows. A content line closes it.
-- ============================================================================

-- the Cancel key's picture: an X of hairline steps, two hairlines thick
local function drawCrossGlyph(p, x, y, s, c)
    local u = ZeD.T.hair
    local t = 2 * u
    local a = c.a or 1
    for i = 0, s - t, u do
        p:drawRect(x + i, y + i, t, t, a, c.r, c.g, c.b)
        p:drawRect(x + i, y + s - t - i, t, t, a, c.r, c.g, c.b)
    end
end

--- Draw a progress band.
--- Left, two rows: [mark] label ... time ... percent / the fill bar.
--- Right: the Cancel icon button, centred on both rows.
---
--- @param panel    The parent ISPanel
--- @param x, y     Top-left position
--- @param w        Total width of the band
--- @param mode     "active" or "danger"
--- @param label    Label string e.g. "Cooking" / "Burning" (any case: it reads in sentence case)
--- @param percent  0.0 .. 1.0
--- @param timeStr  Optional time string e.g. "2:30 left"; nil to omit
--- @param outRect  Optional table; on return holds {x,y,w,h} of the cancel button hit rect
--- @param compact  If true, 220w sizing preset; otherwise 480w preset
--- @param opts     Optional { focus = the ZeD.Focus.mark opts (or true) when Cancel has the
---                 controller's focus, hover (nil: the pointer is tested here), help (the
---                 help line's words; default "Cancel: stop doing this"), win }
--- @return height  Total vertical pixels consumed (so caller can place the next element)
local _pbCancel = {}
function ZeD.Atoms.drawProgressBand(panel, x, y, w, mode, label, percent, timeStr, outRect, compact, opts)
    local T = ZeD.T
    if mode ~= "active" and mode ~= "danger" then return 0 end
    opts = opts or NO_OPTS
    local A = ZeD.Atoms
    local tm = ZeD.TM

    -- Sizing presets: the card's narrow (220w) and wide (480w) looks
    local padX, padTop, padBot, gapV, barH, btnS
    if compact then
        padX, padTop, padBot, gapV = T.px(8), T.px(5), T.px(6), T.px(4)
        barH, btnS = A.fillBarCompactH(), T.buttonH - T.px(4)
    else
        padX, padTop, padBot, gapV = T.px(12), T.px(6), T.px(7), T.px(5)
        barH, btnS = T.fillBarH, T.buttonH
    end
    local markC = (mode == "danger") and T.danger or T.accent
    local font = T.fontF1
    local labelH = T.fontF1H or tm:getFontHeight(font)

    -- Geometry: the two rows on the left, Cancel on the right, centred on them
    local colH = labelH + gapV + barH
    local innerH = math.max(colH, btnS)
    local totalH = padTop + innerH + padBot
    local btnX = x + w - padX - btnS
    local btnY = y + padTop + math.floor((innerH - btnS) / 2)
    local colX = x + padX
    local colR = btnX - T.px(8)
    local rowY = y + padTop + math.floor((innerH - colH) / 2)

    -- Row 1: the status mark and the words, the percent at the right, the time before it
    local sq = T.px(6)
    A.drawStatusDot(panel, colX, rowY + math.floor((labelH - sq) / 2), markC, sq)
    local lx = colX + sq + T.px(6)
    local tc = T.text
    local pctStr = string.format("%d%%", math.floor((percent or 0) * 100))
    local pctX = colR - tm:MeasureStringX(font, pctStr)
    panel:drawText(pctStr, pctX, rowY, tc.r, tc.g, tc.b, tc.a or 1, font)
    local wordsR = pctX - T.px(8)
    local lab = textCase(label or "")
    local labelW = tm:MeasureStringX(font, lab)
    if timeStr and timeStr ~= "" then
        local timeW = tm:MeasureStringX(font, timeStr)
        local timeX = wordsR - timeW
        if timeX > lx + labelW + T.px(8) then
            local sc = T.textSec
            panel:drawText(timeStr, timeX, rowY, sc.r, sc.g, sc.b, sc.a or 1, font)
            wordsR = timeX - T.px(8)
        end
    end
    if wordsR > lx then
        panel:drawText(A.truncateText(lab, font, wordsR - lx), lx, rowY, tc.r, tc.g, tc.b, tc.a or 1, font)
    end

    -- Row 2: the framed fill bar in the mode's colour
    A.drawFillBar(panel, colX, rowY + labelH + gapV, math.max(T.px(8), colR - colX), percent or 0, false, markC, barH)

    -- Cancel: the icon button with an X (its hint names it; its help says what a press does)
    local o = _pbCancel
    if opts.hover ~= nil then o.hover = opts.hover else o.hover = A.mouseIn(panel, btnX, btnY, btnS, btnS) end
    o.focus, o.win = opts.focus, opts.win
    o.hint, o.id = ZeD.tr("UI_Cancel"), "progressCancel"
    o.help = opts.help or ZeD.tr("UI_ZeD_Progress_CancelHelp")
    o.iconSize = math.max(T.px(6), math.floor(btnS * 0.4))
    ZeD.Molecules.drawIconButton(panel, btnX, btnY, btnS, drawCrossGlyph, o)

    -- A content line under the band
    local lt = T.line(T.borderW)
    A.drawDividerH(panel, x, y + totalH - lt, w, false)

    -- Out-param: cancel button hit rect for caller's mouse/gamepad dispatch
    if outRect then
        outRect.x, outRect.y, outRect.w, outRect.h = btnX, btnY, btnS, btnS
    end

    return totalH
end

-- ============================================================================
-- 13. FLAG CHIP (S120; the tag look since the cohesion pass)
-- A small toggle in the FlagStrip molecule above the item card body, drawn as a
-- tag (A.drawTag): the 1u outline, the words, and a 6u square mark that carries
-- the state, filled in the kind's colour when on, hollow and dim when off:
--   "fav"     accent
--   "nocraft" warning
--   "dispose" danger
-- No tinted fill, no coloured words.
-- ============================================================================

--- Draw a flag chip.
--- @param panel    Parent ISPanel
--- @param x, y     Top-left position
--- @param kind     "fav" | "nocraft" | "dispose"
--- @param on       True = on, false = off
--- @param glyph    Short mark string: drawn only in the compact chip, after the square
--- @param label    The chip's word (any case: it reads in sentence case) - ignored when compact
--- @param outRect  Optional table; on return holds {x,y,w,h} of the chip's hit rect
--- @param compact  If true, a fixed 22x18 chip (square + glyph); else square + label
--- @param opts     Optional { hover = bool (the T.hover wash; nil: none), focus = the
---                 ZeD.Focus.mark opts when the chip has the controller's focus (the mark
---                 goes under the words, which switch to the focus ink when it asks) }
--- @return width   Total horizontal pixels consumed (so the caller can advance its cursor)
local _chipTag = {}
function ZeD.Atoms.drawFlagChip(panel, x, y, kind, on, glyph, label, outRect, compact, opts)
    local T = ZeD.T
    opts = opts or NO_OPTS
    local onC
    if     kind == "nocraft" then onC = T.warning
    elseif kind == "dispose" then onC = T.danger
    else                          onC = T.accent end
    local h = T.px(18)
    local mark = on and onC or T.textDim
    local tc = on and T.text or T.textDim
    -- the chip's width first, so its hover wash and focus mark go under the words
    local tg = _chipTag
    tg.h, tg.minW, tg.hollow = h, T.px(22), not on
    local w = compact and T.px(22) or ZeD.Atoms.tagW(label or "", true, tg)
    if opts.hover then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a or 1, hv.r, hv.g, hv.b)
    end
    if opts.focus and ZeD.Focus and ZeD.Focus.mark then
        if ZeD.Focus.mark(panel, x, y, w, h, opts.focus) then tc = T.textOnFocus end
    end
    if compact then
        ZeD.Atoms.frame(panel, x, y, w, h, T.borderS)
        local font = T.fontF1
        local sq, gap = T.px(6), T.px(3)
        local gw = (glyph and glyph ~= "") and ZeD.TM:MeasureStringX(font, glyph) or 0
        local cw = sq + ((gw > 0) and (gap + gw) or 0)
        local cx = x + math.floor((w - cw) / 2)
        local sy = y + math.floor((h - sq) / 2)
        if on then panel:drawRect(cx, sy, sq, sq, mark.a or 1, mark.r, mark.g, mark.b)
        else ZeD.Atoms.frame(panel, cx, sy, sq, sq, mark) end
        if gw > 0 then
            local fh = T.fontF1H or ZeD.TM:getFontHeight(font)
            panel:drawText(glyph, cx + sq + gap, y + math.floor((h - fh) / 2), tc.r, tc.g, tc.b, tc.a or 1, font)
        end
    else
        tg.textColor = tc
        w = ZeD.Atoms.drawTag(panel, x, y, label or "", mark, tg)
        tg.textColor = nil
    end
    if outRect then
        outRect.x, outRect.y, outRect.w, outRect.h = x, y, w, h
    end
    return w
end

-- ============================================================================
-- ACTION STRIP — shared state logic for icon action buttons
-- The strip is a reusable row of icon-only toggle/action buttons.
-- Plug it into a window footer, tab bar, between organisms, anywhere.
-- DEFS define what actions are available; getState/setState handle the data.
-- Drawing and interaction live in Molecules (drawActionStrip/updateActionStrip).
-- ============================================================================

ZeD.ActionStrip = {}

-- Texture cache (lazy-loaded)
local _toggleTexCache = {}
function ZeD.ActionStrip.getTex(name)
    if not name then return nil end
    if _toggleTexCache[name] == nil then
        _toggleTexCache[name] = getTexture("media/textures/ZeD/icons/" .. name .. ".png") or false
    end
    return _toggleTexCache[name]
end

-- Toggle definitions: key, texture name, theme color key, tooltip text
-- Item toggle definitions (favorite, protect, unwanted)
ZeD.ActionStrip.TOGGLE_DEFS = {
    -- (tip_on / tip_off are vanilla translation keys: read them through ZeD.tr when a tooltip is drawn)
    {key="fav",      tex="essential-collection-128-like", colorKey="accent", tip_on="ContextMenu_Unfavorite",     tip_off="IGUI_CraftUI_Favorite"},
    {key="protect",  tex="text-editor-052-save",          colorKey="info",   tip_on="ContextMenu_UnsetNoRecipes", tip_off="ContextMenu_SetNoRecipes"},
    {key="unwanted", tex="alerts-050-bin",                colorKey="danger", tip_on="ContextMenu_Wanted",         tip_off="ContextMenu_Unwanted"},
}

local _safeGet = ZeD.Atoms.safeGet  -- reuse public helper (line 18)

-- a window's player number (split-screen: never assume player 1)
function ZeD.playerNumOf(w)
    local p = w and w._playerObj
    return p and p:getPlayerNum() or 0
end

-- Oct 19 2026 (the single-path audit): the no-craft chip is vanilla's own
-- "Set to be Unusable in Recipes" (item:setNoRecipes), so vanilla's crafting
-- honours it and the context menu shows it; the old ZeD-only mark
-- (modData.ZeD_noCraft, which nothing read) carries over once. playerNum: the
-- card's player (split-screen), 0 when not given.
local function _markPlayer(playerNum) return getSpecificPlayer(playerNum or 0) end

function ZeD.ActionStrip.getState(item, key, playerNum)
    if key == "fav" then
        return _safeGet(item, "isFavorite") or false
    elseif key == "protect" then
        local p = _markPlayer(playerNum)
        if not p then return false end
        local md = _safeGet(item, "getModData")
        if md and md.ZeD_noCraft == true then
            _safeGet(item, "setNoRecipes", p, true)
            md.ZeD_noCraft = nil
        end
        return _safeGet(item, "isNoRecipes", p) or false
    elseif key == "unwanted" then
        local p = _markPlayer(playerNum)
        if p then return _safeGet(item, "isUnwanted", p) or false end
        return false
    end
    return false
end

-- ============================================================================
-- WORD WRAP (shared utility)
-- Splits text into lines that fit within maxW pixels.
-- Handles paragraph breaks (\n) and returns a table of strings.
-- ============================================================================

function ZeD.Atoms.wrapText(text, font, maxW)
    local lines = {}
    if not text or text == "" then return lines end

    for paragraph in text:gmatch("[^\n]+") do
        local words = {}
        for word in paragraph:gmatch("%S+") do words[#words + 1] = word end
        local line = ""
        for _, word in ipairs(words) do
            local test = line == "" and word or (line .. " " .. word)
            if ZeD.TM:MeasureStringX(font, test) > maxW then
                if line ~= "" then lines[#lines + 1] = line end
                line = word
            else
                line = test
            end
        end
        if line ~= "" then lines[#lines + 1] = line end
    end

    if #lines == 0 then lines[1] = text end
    return lines
end

--- Truncate text with ellipsis ("...") to fit within maxW pixels.
--- Uses binary search for efficiency.
-- The answers are kept per font, width and text while the measures behind them are
-- (ZeD.Text.measureEpoch; Oct 22 2026, the drawing-cost work: every list cuts the same
-- names to the same widths every frame). Past TT_MAX answers the store starts over.
local truncateRaw
local TT_MAX = 4000
local _tt, _ttN, _ttEpoch = {}, 0, nil
function ZeD.Atoms.truncateText(text, font, maxW)
    if maxW <= 0 then return "" end
    local X = ZeD.Text
    local epoch = X and X.measureEpoch and X.measureEpoch() or nil
    if epoch == nil or font == nil or type(text) ~= "string" then return truncateRaw(text, font, maxW) end
    if epoch ~= _ttEpoch or _ttN >= TT_MAX then _tt, _ttN, _ttEpoch = {}, 0, epoch end
    local byF = _tt[font]
    if not byF then byF = {}; _tt[font] = byF end
    local byW = byF[maxW]
    if not byW then byW = {}; byF[maxW] = byW end
    local s = byW[text]
    if s == nil then
        s = truncateRaw(text, font, maxW)
        byW[text] = s
        _ttN = _ttN + 1
    end
    return s
end
truncateRaw = function(text, font, maxW)
    if maxW <= 0 then return "" end
    local tm = ZeD.TM
    if tm:MeasureStringX(font, text) <= maxW then return text end
    local ellW = tm:MeasureStringX(font, "...")
    if maxW <= ellW then return "..." end
    local target = maxW - ellW
    local lo, hi = 1, #text
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if tm:MeasureStringX(font, string.sub(text, 1, mid)) <= target then
            lo = mid
        else
            hi = mid - 1
        end
    end
    return string.sub(text, 1, lo) .. "..."
end

function ZeD.ActionStrip.setState(item, key, value, playerNum)
    if key == "fav" then
        _safeGet(item, "setFavorite", value, true)
    elseif key == "protect" then
        local p = _markPlayer(playerNum)
        if p then _safeGet(item, "setNoRecipes", p, value and true or false) end
        local md = _safeGet(item, "getModData")
        if md then md.ZeD_noCraft = nil end
    elseif key == "unwanted" then
        local p = _markPlayer(playerNum)
        if p then _safeGet(item, "setUnwanted", p, value) end
    end
end
