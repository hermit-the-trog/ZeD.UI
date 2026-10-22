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
function ZeD.Atoms.drawFillBar(panel, x, y, w, percent, graduated, fillColor)
    local T = ZeD.T
    local h = T.fillBarH
    local bw = T.line(T.borderW)  -- T.borderW is design units (1, HC 2): that many hairlines; the HC test below reads the raw token

    -- Clamp percent
    percent = math.max(0.0, math.min(1.0, percent))

    -- Track background (the empty portion)
    local bg = T.surf1
    panel:drawRect(x, y, w, h, bg.a, bg.r, bg.g, bg.b)

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
        -- Minimum visible width of 2px so tiny values still show
        fillW = math.max(T.px(2), fillW)
        panel:drawRect(x + bw, y + bw, fillW, h - bw * 2, (fc.a or 1.0) * 0.5, fc.r, fc.g, fc.b)
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
    local segW = w / numSegs

    for si = 1, numSegs do
        local c1 = stops[si]
        local c2 = stops[si + 1]
        local sx = x + (si - 1) * segW
        local halfW = segW / 2
        panel:drawRect(sx, y, halfW, h, 0.5, c1.r, c1.g, c1.b)
        local mr = (c1.r + c2.r) / 2
        local mg = (c1.g + c2.g) / 2
        local mb = (c1.b + c2.b) / 2
        panel:drawRect(sx + halfW, y, halfW, h, 0.5, mr, mg, mb)
    end

    local bc = T.borderS
    panel:drawRectBorder(x, y, w, h, bc.a, bc.r, bc.g, bc.b)

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
-- @param onColor  Color for lit segments — RGBA table
-- @param offColor Color for unlit segments — RGBA table
-- @param gap      Pixels between segments (default 1)
function ZeD.Atoms.drawSegBar(panel, x, y, w, h, n, k, onColor, offColor, gap)
    local T = ZeD.T
    if n <= 0 then return end
    gap = gap or T.px(1)
    if k < 0 then k = 0 end
    if k > n then k = n end
    -- Width per segment after subtracting (n-1) gaps. Floor so we never overrun.
    local segW = math.floor((w - gap * (n - 1)) / n)
    if segW < T.px(1) then segW = T.px(1) end
    for i = 1, n do
        local sx = x + (i - 1) * (segW + gap)
        local c  = (i <= k) and onColor or offColor
        if c then
            panel:drawRect(sx, y, segW, h, c.a or 1.0, c.r, c.g, c.b)
        end
    end
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
-- 06. BADGE (draw helper)
-- A small colored chip for status/category display. Uppercase monospace.
-- ============================================================================

--- Draw a badge
-- @param panel   The parent ISPanel
-- @param text    Badge text (will be uppercased)
-- @param x, y    Top-left position
-- @param variant One of: "danger", "warning", "positive", "info", "accent", "neutral"
-- @param disabled Boolean
-- @return width  The total width of the badge (for layout math)
function ZeD.Atoms.drawBadge(panel, text, x, y, variant, disabled, font, noUpper)
    local T = ZeD.T
    local alpha = disabled and T.disabledAlpha or 1.0
    local padX = T.sp.badgePadX
    local padY = T.sp.badgePadY
    local bdFont = font or T.fontF3

    -- Uppercase the text (unless caller opts out)
    if not noUpper then text = ZeD.upper(text) end

    -- Measure text width
    local tw = ZeD.TM:MeasureStringX(bdFont, text)
    local totalW = tw + padX * 2
    local totalH = ZeD.TM:MeasureStringY(bdFont, text) + padY * 2

    -- Pick colors based on variant
    -- (the fill and border keep the plain colour; the words use its text variant)
    local fgColor, txColor
    if variant == "danger" then
        fgColor, txColor = T.danger, T.dangerText
    elseif variant == "warning" then
        fgColor, txColor = T.warning, T.warningText
    elseif variant == "positive" then
        fgColor, txColor = T.positive, T.positiveText
    elseif variant == "info" then
        fgColor, txColor = T.info, T.infoText
    elseif variant == "accent" then
        fgColor, txColor = T.accent, T.accentText
    else  -- neutral
        fgColor, txColor = T.borderS, T.textDim
    end

    -- Background (tinted fill using badgeBgA token)
    panel:drawRect(x, y, totalW, totalH,
        T.badgeBgA * alpha, fgColor.r, fgColor.g, fgColor.b)

    -- Border
    panel:drawRectBorder(x, y, totalW, totalH,
        fgColor.a * alpha, fgColor.r, fgColor.g, fgColor.b)

    -- Text
    panel:drawText(text, x + padX, y + padY,
        txColor.r, txColor.g, txColor.b, txColor.a * alpha, bdFont)

    return totalW
end

-- ============================================================================
-- 06b. STATUS DOT (draw helper)
-- A small filled square used as a color-coded status indicator.
-- Pass a color table {r, g, b, a} directly, or use with tierColor().
-- ============================================================================

function ZeD.Atoms.drawStatusDot(panel, x, y, color, size)
    local sz = size or ZeD.T.px(7)  -- S124 scale: size is screen px; the 1px rows below rasterize the circle at screen resolution
    local a = color.a or 1
    local r, g, b = color.r, color.g, color.b
    local rad = sz / 2
    for row = 0, sz - 1 do
        local dist = math.abs(row - rad + 0.5)
        local halfW = math.floor(math.sqrt(rad * rad - dist * dist) + 0.5)
        if halfW > 0 then
            panel:drawRect(x + math.floor(rad) - halfW, y + row, halfW * 2, 1, a, r, g, b)
        end
    end
end

-- Hollow variant of the status dot: a ring one design pixel thick. Marks a
-- state that is neither go nor stop (a recipe that needs a station).
function ZeD.Atoms.drawStatusRing(panel, x, y, color, size)
    local sz = size or ZeD.T.px(7)
    local a = color.a or 1
    local r, g, b = color.r, color.g, color.b
    local rad = sz / 2
    local inner = math.max(0, rad - math.max(1, ZeD.T.px(1)))
    for row = 0, sz - 1 do
        local dist = math.abs(row - rad + 0.5)
        local halfW = math.floor(math.sqrt(math.max(0, rad * rad - dist * dist)) + 0.5)
        if halfW > 0 then
            local innerW = 0
            if dist < inner then
                innerW = math.floor(math.sqrt(inner * inner - dist * dist) + 0.5)
            end
            local cx = x + math.floor(rad)
            if innerW <= 0 then
                panel:drawRect(cx - halfW, y + row, halfW * 2, 1, a, r, g, b)
            else
                panel:drawRect(cx - halfW, y + row, halfW - innerW, 1, a, r, g, b)
                panel:drawRect(cx + innerW, y + row, halfW - innerW, 1, a, r, g, b)
            end
        end
    end
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
        elseif line.variant == "secondary" then font = T.fontF1
        else font = T.fontF2 end

        local w = ZeD.TM:MeasureStringX(font, line.text)
        local h = ZeD.TM:MeasureStringY(font, line.text)
        maxW = math.max(maxW, w)
        totalH = totalH + h + T.px(2)  -- 2px line spacing
    end

    self:setWidth(math.min(maxW + T.px(self.padX) * 2, T.px(self.maxWidth)))
    self:setHeight(totalH + T.px(self.padY) * 2)
end

function ZeD_Tooltip:prerender()
    local T = ZeD.T
    -- Background — uses token surface opacity (no hardcoded override)
    ZeD.Molecules.drawBodyBg(self, 0, 0, self.width, self.height, "surf2")
    -- Border
    local bc = T.borderS
    self:drawRectBorder(0, 0, self.width, self.height, bc.a, bc.r, bc.g, bc.b)
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
            font = T.fontF1
            color = T.textSec
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

-- ----------------------------------------------------------------------------
-- Hover hint layer: the icon-only hint (surf2, the strong border, F2, shown
-- after HINT_MS of rest) for controls that sit at a window's edge, where their
-- own panel is too narrow or sits under later siblings. The window keeps a
-- click-through layer as its LAST child; each frame the control's draw code
-- stamps win[field] = { key, text, x, y, w, h, side = "r"|"l" } (window space,
-- the control's rect) while the pointer rests on it, and the layer draws the
-- box beside the control. Nothing stamped = no hint (the stamp is consumed).
-- ----------------------------------------------------------------------------
ZeD.Atoms.HINT_MS = 450

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
        local c = win[field]
        win[field] = nil
        local kf, sf = field .. "Key", field .. "Since"
        if not c then win[kf] = nil; return end
        local now = getTimestampMs()
        if win[kf] ~= c.key then win[kf], win[sf] = c.key, now; return end
        if now - (win[sf] or now) < ZeD.Atoms.HINT_MS then return end
        local T = ZeD.T
        local f2 = T.fontF2
        local padX, padY = T.px(10), T.px(4)
        local w = ZeD.TM:MeasureStringX(f2, c.text) + padX * 2
        local h = ZeD.TM:getFontHeight(f2) + padY * 2
        local ww, wh = win:getWidth(), win:getHeight()
        local x = (c.side == "l") and (c.x - w - T.px(4)) or (c.x + c.w + T.px(4))
        x = math.max(T.px(2), math.min(x, ww - w - T.px(2)))
        local y = c.y + math.floor((c.h - h) / 2)
        y = math.max(T.px(2), math.min(y, wh - h - T.px(2)))
        local s2, bs, tc = T.surf2, T.borderS, T.text
        self:drawRect(x + T.px(2), y + T.px(2), w, h, 0.5, 0, 0, 0)
        self:drawRect(x, y, w, h, 1, s2.r, s2.g, s2.b)
        self:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
        self:drawText(c.text, x + padX, y + padY, tc.r, tc.g, tc.b, tc.a or 1, f2)
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
        bg = ZeD.colorAlpha(T.accent, 0.30)
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
-- 11. FOCUS INDICATOR (draw helper)
-- A dashed border around the focused element for keyboard/gamepad navigation.
-- ============================================================================

--- Draw a focus ring around an element
-- @param panel  The parent ISPanel
-- @param x, y   Top-left of the element to focus
-- @param w, h   Dimensions of the element
function ZeD.Atoms.drawFocusRing(panel, x, y, w, h)
    local T = ZeD.T
    local offset = T.px(2)  -- pixels outside the element
    local fx = x - offset
    local fy = y - offset
    local fw = w + offset * 2
    local fh = h + offset * 2

    if T.borderW >= 2 then
        -- High Contrast: solid 2px border
        local rc = T.accentText   -- the ring is a mark: the accent moved only as far as it needs to read
        panel:drawRectBorder(fx, fy, fw, fh, rc.a, rc.r, rc.g, rc.b)
        do local i = (panel.zedScaled and T.px(1)) or 1; panel:drawRectBorder(fx + i, fy + i, fw - 2 * i, fh - 2 * i, rc.a, rc.r, rc.g, rc.b) end  -- HC: inset by the border's own thickness
    else
        -- Standard: dashed border using small rect segments
        local dashLen = T.px(4)
        local gapLen = T.px(3)
        local ac = T.accentText

        -- Top edge
        local cx = fx
        while cx < fx + fw do
            local segW = math.min(dashLen, fx + fw - cx)
            panel:drawRect(cx, fy, segW, T.px(1), ac.a, ac.r, ac.g, ac.b)
            cx = cx + dashLen + gapLen
        end
        -- Bottom edge
        cx = fx
        while cx < fx + fw do
            local segW = math.min(dashLen, fx + fw - cx)
            panel:drawRect(cx, fy + fh - T.px(1), segW, T.px(1), ac.a, ac.r, ac.g, ac.b)
            cx = cx + dashLen + gapLen
        end
        -- Left edge
        local cy = fy
        while cy < fy + fh do
            local segH = math.min(dashLen, fy + fh - cy)
            panel:drawRect(fx, cy, T.px(1), segH, ac.a, ac.r, ac.g, ac.b)
            cy = cy + dashLen + gapLen
        end
        -- Right edge
        cy = fy
        while cy < fy + fh do
            local segH = math.min(dashLen, fy + fh - cy)
            panel:drawRect(fx + fw - T.px(1), cy, T.px(1), segH, ac.a, ac.r, ac.g, ac.b)
            cy = cy + dashLen + gapLen
        end
    end
end

-- ============================================================================
-- 12. PROGRESS BAND (S120)
-- A two-row strip used between the back-bar and flag strip on item cards
-- whenever a timed action is in progress on the item. Three modes:
--   "idle"   — caller skips this atom entirely (no render)
--   "active" — accent label + accent fill + neutral bottom-border separator
--   "danger" — danger label + danger fill + danger bottom-border separator
-- Mode is the only thing that flips between active/danger; chrome stays still
-- so the visual delta is pure color (per S119 v16 mockup design rule).
-- ============================================================================

--- Draw a progress band.
--- Row 1: label (left) ... time-str ... percent ... cancel-button (right)
--- Row 2: full-width thin progress bar
--- Bottom: 1px separator (color carries mode)
---
--- @param panel    The parent ISPanel
--- @param x, y     Top-left position
--- @param w        Total width of the band
--- @param mode     "active" or "danger"
--- @param label    Label string e.g. "COOKING" / "BURNING" — caller composes
--- @param percent  0.0 .. 1.0
--- @param timeStr  Optional time string e.g. "2:30 LEFT"; nil to omit
--- @param outRect  Optional table; on return holds {x,y,w,h} of the cancel button hit rect
--- @param compact  If true, 220w sizing preset; otherwise 480w preset
--- @return height  Total vertical pixels consumed (so caller can place the next element)
function ZeD.Atoms.drawProgressBand(panel, x, y, w, mode, label, percent, timeStr, outRect, compact)
    local T = ZeD.T
    if mode ~= "active" and mode ~= "danger" then return 0 end

    -- Sizing presets — match v16 mockup dimensions
    local padX, padTop, padBot, gapV, barH, btnW, btnH
    if compact then
        padX, padTop, padBot, gapV = T.px(8), T.px(5), T.px(6), T.px(4)
        barH    = T.px(6)
        btnW, btnH = T.px(16), T.px(14)
    else
        padX, padTop, padBot, gapV = T.px(12), T.px(6), T.px(7), T.px(5)
        barH    = T.px(8)
        btnW, btnH = T.px(18), T.px(18)
    end

    -- Mode-driven colors
    local isDanger = (mode == "danger")
    local accentC  = isDanger and T.danger or T.accent
    local labelC   = accentC
    local pctC     = isDanger and T.danger or T.text
    local timeC    = T.textSec
    local fillC    = accentC
    local sepC     = isDanger and T.danger or T.border
    local font     = T.fontF1
    local labelH   = T.fontF1H or ZeD.TM:MeasureStringY(font, "X")

    -- Geometry
    local row1H  = math.max(labelH, btnH)
    local totalH = padTop + row1H + gapV + barH + padBot

    -- ROW 1: label, time, percent, cancel button
    local rowY   = y + padTop
    local textY  = rowY + math.floor((row1H - labelH) / 2)
    local btnX   = x + w - padX - btnW
    local btnY   = rowY + math.floor((row1H - btnH) / 2)

    -- Label (left)
    panel:drawText(label or "", x + padX, textY,
        labelC.r, labelC.g, labelC.b, labelC.a, font)

    -- Cancel button (right) — raised System-7 chrome via surf4 (light) + borderS (dark)
    local bg, hi, sh = T.surf2, T.surf4, T.borderS
    panel:drawRect(btnX, btnY, btnW, btnH, bg.a, bg.r, bg.g, bg.b)
    panel:drawRect(btnX, btnY, btnW, T.px(1), hi.a, hi.r, hi.g, hi.b)              -- top
    panel:drawRect(btnX, btnY, T.px(1), btnH, hi.a, hi.r, hi.g, hi.b)              -- left
    panel:drawRect(btnX, btnY + btnH - T.px(1), btnW, T.px(1), sh.a, sh.r, sh.g, sh.b)    -- bottom
    panel:drawRect(btnX + btnW - T.px(1), btnY, T.px(1), btnH, sh.a, sh.r, sh.g, sh.b)    -- right
    -- "x" glyph centered
    local glyph = "x"
    local gw = ZeD.TM:MeasureStringX(font, glyph)
    local gh = ZeD.TM:MeasureStringY(font, glyph)
    local tc = T.text
    panel:drawText(glyph, btnX + math.floor((btnW - gw) / 2),
        btnY + math.floor((btnH - gh) / 2),
        tc.r, tc.g, tc.b, tc.a, font)

    -- Percent (right of time, left of cancel button, right-aligned)
    local pctStr = string.format("%d%%", math.floor((percent or 0) * 100))
    local pctW = ZeD.TM:MeasureStringX(font, pctStr)
    local gapBeforeBtn = T.px(8)
    local pctX = btnX - gapBeforeBtn - pctW
    panel:drawText(pctStr, pctX, textY,
        pctC.r, pctC.g, pctC.b, pctC.a, font)

    -- Time (between label and percent, only if room remains)
    if timeStr and timeStr ~= "" then
        local timeW  = ZeD.TM:MeasureStringX(font, timeStr)
        local labelW = ZeD.TM:MeasureStringX(font, label or "")
        local timeX  = pctX - gapBeforeBtn - timeW
        if timeX > (x + padX + labelW + gapBeforeBtn) then
            panel:drawText(timeStr, timeX, textY,
                timeC.r, timeC.g, timeC.b, timeC.a, font)
        end
    end

    -- ROW 2: progress bar
    local barX, barY = x + padX, rowY + row1H + gapV
    local barW = w - padX * 2
    local barBg = T.surf2
    panel:drawRect(barX, barY, barW, barH, barBg.a, barBg.r, barBg.g, barBg.b)
    local fillW = math.floor(barW * math.max(0, math.min(1, percent or 0)))
    if fillW > 0 then
        panel:drawRect(barX, barY, fillW, barH, fillC.a, fillC.r, fillC.g, fillC.b)
    end
    local bbc = T.borderS
    panel:drawRectBorder(barX, barY, barW, barH, bbc.a, bbc.r, bbc.g, bbc.b)

    -- Bottom 1px separator (mode-colored — danger reads through chrome)
    panel:drawRect(x, y + totalH - T.px(1), w, T.px(1), sepC.a, sepC.r, sepC.g, sepC.b)

    -- Out-param: cancel button hit rect for caller's mouse/gamepad dispatch
    if outRect then
        outRect.x, outRect.y, outRect.w, outRect.h = btnX, btnY, btnW, btnH
    end

    return totalH
end

-- ============================================================================
-- 13. FLAG CHIP (S120)
-- A small chip used in the FlagStrip molecule above the item card body.
-- Three semantic kinds drive distinct on-state color families:
--   "fav"     — accent (positive intent)
--   "nocraft" — warning (cautionary intent)
--   "dispose" — danger (negative intent)
-- Off state is uniform across kinds: dim text on neutral surface.
-- Border darkens to a hue-matched darker variant on activation
-- (computed via ZeD.colorBlend so no new theme tokens are required).
-- ============================================================================

--- Draw a flag chip.
--- @param panel    Parent ISPanel
--- @param x, y     Top-left position
--- @param kind     "fav" | "nocraft" | "dispose"
--- @param on       True = on-state colors, false = off-state
--- @param glyph    Short icon string drawn left of label (or alone in compact); nil to omit
--- @param label    Uppercase label text (e.g. "FAV") — ignored when compact=true
--- @param outRect  Optional table; on return holds {x,y,w,h} of the chip's hit rect
--- @param compact  If true, fixed 22x18 icon-only chip (220w preset); else padded label chip
--- @return width   Total horizontal pixels consumed (so the caller can advance its cursor)
function ZeD.Atoms.drawFlagChip(panel, x, y, kind, on, glyph, label, outRect, compact)
    local T = ZeD.T

    -- Kind selects the on-state base color
    local onBg
    if     kind == "fav"     then onBg = T.accent
    elseif kind == "nocraft" then onBg = T.warning
    elseif kind == "dispose" then onBg = T.danger
    else                          onBg = T.accent
    end

    -- Resolve fg/bg/border for current state
    local bgC, fgC, brC
    if on then
        bgC = onBg
        -- ink or paper, whichever reads on this fill (the status fills are not the accent)
        if     onBg == T.warning then fgC = T.textOnWarning
        elseif onBg == T.danger  then fgC = T.textOnDanger
        else                          fgC = T.textOnAccent end
        brC = ZeD.colorBlend(onBg, T.base, 0.55)  -- hue-matched darker border
    else
        bgC = T.surf2
        fgC = T.textDim
        brC = T.border
    end

    -- Sizing
    local h        = T.px(18)
    local padX     = compact and 0 or T.px(8)
    local gapInner = (compact or not (glyph and label)) and 0 or T.px(4)
    local font     = T.fontF1

    -- Width computation
    local w
    if compact then
        w = T.px(22)
    else
        local labelW = label and ZeD.TM:MeasureStringX(font, label) or 0
        local glyphW = glyph and ZeD.TM:MeasureStringX(font, glyph) or 0
        w = padX * 2 + glyphW + gapInner + labelW
        if w < T.px(22) then w = T.px(22) end
    end

    -- Background + border
    panel:drawRect(x, y, w, h, bgC.a, bgC.r, bgC.g, bgC.b)
    panel:drawRectBorder(x, y, w, h, brC.a, brC.r, brC.g, brC.b)

    -- Content (vertically centered)
    local labelH = T.fontF1H or ZeD.TM:MeasureStringY(font, "X")
    local textY  = y + math.floor((h - labelH) / 2)

    if compact then
        -- Icon-only: glyph centered within the 22-wide chip
        if glyph then
            local gw = ZeD.TM:MeasureStringX(font, glyph)
            panel:drawText(glyph, x + math.floor((w - gw) / 2), textY,
                fgC.r, fgC.g, fgC.b, fgC.a, font)
        end
    else
        -- Padded label chip: glyph + gap + label, both left-aligned
        local cursor = x + padX
        if glyph then
            panel:drawText(glyph, cursor, textY,
                fgC.r, fgC.g, fgC.b, fgC.a, font)
            cursor = cursor + ZeD.TM:MeasureStringX(font, glyph) + gapInner
        end
        if label then
            panel:drawText(label, cursor, textY,
                fgC.r, fgC.g, fgC.b, fgC.a, font)
        end
    end

    -- Out-param hit rect
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
