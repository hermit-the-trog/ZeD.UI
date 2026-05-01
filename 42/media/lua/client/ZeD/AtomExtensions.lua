-- ZeD-UI/42/media/lua/client/ZeD/AtomExtensions.lua
-- ============================================================================
-- ATOM EXTENSIONS
-- Additional draw helpers needed by organisms. These were added during
-- the System 7.1 refinement pass — disclosure triangles, groove dividers.
-- Require this AFTER Atoms.lua.
-- ============================================================================

ZeD = ZeD or {}
ZeD.Atoms = ZeD.Atoms or {}

-- ---------------------------------------------------------------------------
-- ROUNDED RECT HELPERS — shared by all button-like elements
-- System 7 corner: 2 inset rows per corner.
-- Row 0: 2px inset, Row 1: 1px inset, then full width.
-- ---------------------------------------------------------------------------
local ROUND_RADIUS = {2, 1}

--- Draw a filled rounded rectangle
function ZeD.Atoms.fillRounded(panel, x, y, w, h, r, g, b, a)
    for i, inset in ipairs(ROUND_RADIUS) do
        panel:drawRect(x + inset, y + (i - 1), w - inset * 2, 1, a, r, g, b)
        panel:drawRect(x + inset, y + h - i,   w - inset * 2, 1, a, r, g, b)
    end
    local midTop = #ROUND_RADIUS
    local midH   = h - midTop * 2
    if midH > 0 then
        panel:drawRect(x, y + midTop, w, midH, a, r, g, b)
    end
end

--- Draw a 1px rounded border outline
function ZeD.Atoms.borderRounded(panel, x, y, w, h, r, g, b, a)
    for i, inset in ipairs(ROUND_RADIUS) do
        local row = i - 1
        panel:drawRect(x + inset,         y + row,         w - inset * 2, 1, a, r, g, b)
        panel:drawRect(x + inset,         y + h - 1 - row, w - inset * 2, 1, a, r, g, b)
    end
    local midTop = #ROUND_RADIUS
    local midH   = h - midTop * 2
    if midH > 0 then
        panel:drawRect(x,         y + midTop, 1, midH, a, r, g, b)
        panel:drawRect(x + w - 1, y + midTop, 1, midH, a, r, g, b)
    end
end

--- System 7 double border: outer 1px + 1px gap + inner 1px
-- ROUND_RADIUS {2,1} means outer top rows at y+0..y+1, sides start at y+2.
-- Inner offset: x+2 keeps 1px side gap; y+3 keeps 1px gap after outer's y+1 row.
function ZeD.Atoms.borderDoubleRounded(panel, x, y, w, h, r, g, b, a)
    ZeD.Atoms.borderRounded(panel, x, y, w, h, r, g, b, a)
    ZeD.Atoms.borderRounded(panel, x + 2, y + 3, w - 4, h - 6, r, g, b, a)
end

-- ---------------------------------------------------------------------------
-- BEVEL PANELS (S115 — radio chassis)
-- recessedPanel = inset look. Top + left painted in `hi` (the DARK bevel — a
-- shadow cast by the chassis edge above the recess); bottom + right in `sh`
-- (the LIGHT bevel — light catching the lower lip of the recess). Mirrors
-- the dark-grey control panels carved into the silver Premium chassis.
--
-- raisedPanel = inverted bevel. Top + left = light, bottom + right = dark.
-- For chassis areas that sit PROUD of the surrounding surface (the brand-bar
-- silver pill, optional control groups). Same call shape so callers can swap
-- one for the other without rearguments.
--
-- Both atoms paint solid bg + 1px four-edge bevel. Caller provides the colors;
-- typical usage `ZeD.Atoms.recessedPanel(p, x, y, w, h, T.radio.pt.recessedBg,
-- T.radio.pt.recessedHi, T.radio.pt.recessedSh)`.
-- ---------------------------------------------------------------------------

--- Filled rectangle with 4-edge inset bevel (top+left dark, bottom+right light).
function ZeD.Atoms.recessedPanel(panel, x, y, w, h, bgColor, hiColor, shColor)
    if w <= 0 or h <= 0 then return end
    if bgColor then
        panel:drawRect(x, y, w, h, bgColor.a or 1.0, bgColor.r, bgColor.g, bgColor.b)
    end
    if hiColor then
        -- Top edge (1px across full width)
        panel:drawRect(x, y, w, 1, hiColor.a or 1.0, hiColor.r, hiColor.g, hiColor.b)
        -- Left edge (1px down full height — overlaps top corner harmlessly)
        panel:drawRect(x, y, 1, h, hiColor.a or 1.0, hiColor.r, hiColor.g, hiColor.b)
    end
    if shColor then
        -- Bottom edge
        panel:drawRect(x, y + h - 1, w, 1, shColor.a or 1.0, shColor.r, shColor.g, shColor.b)
        -- Right edge
        panel:drawRect(x + w - 1, y, 1, h, shColor.a or 1.0, shColor.r, shColor.g, shColor.b)
    end
end

--- Filled rectangle with 4-edge outset bevel (top+left light, bottom+right dark).
function ZeD.Atoms.raisedPanel(panel, x, y, w, h, bgColor, hiColor, shColor)
    if w <= 0 or h <= 0 then return end
    if bgColor then
        panel:drawRect(x, y, w, h, bgColor.a or 1.0, bgColor.r, bgColor.g, bgColor.b)
    end
    if hiColor then
        -- Top edge in LIGHT bevel
        panel:drawRect(x, y, w, 1, hiColor.a or 1.0, hiColor.r, hiColor.g, hiColor.b)
        -- Left edge in LIGHT bevel
        panel:drawRect(x, y, 1, h, hiColor.a or 1.0, hiColor.r, hiColor.g, hiColor.b)
    end
    if shColor then
        -- Bottom edge in DARK bevel
        panel:drawRect(x, y + h - 1, w, 1, shColor.a or 1.0, shColor.r, shColor.g, shColor.b)
        -- Right edge in DARK bevel
        panel:drawRect(x + w - 1, y, 1, h, shColor.a or 1.0, shColor.r, shColor.g, shColor.b)
    end
end

--- Accent ring for focus chrome (S95). Draws a solid rectangular border of the
-- given thickness INSIDE the rect at (x,y,w,h). Four rects = top, bottom, left,
-- right. Used to highlight the window currently holding joypad focus.
--
-- `thickness` in px (typically 2). `color` is a color table {r,g,b,a}. Keeping
-- it a single-arg color rather than r,g,b,a so callers can pass T.accent / T.accentBright
-- directly without unpacking.
function ZeD.Atoms.drawAccentRing(panel, x, y, w, h, thickness, color)
    if not color or w <= 0 or h <= 0 or thickness <= 0 then return end
    local r, g, b, a = color.r, color.g, color.b, color.a
    -- Top edge
    panel:drawRect(x, y, w, thickness, a, r, g, b)
    -- Bottom edge
    panel:drawRect(x, y + h - thickness, w, thickness, a, r, g, b)
    -- Left edge (don't double-draw the corners; inset by thickness top/bottom)
    panel:drawRect(x, y + thickness, thickness, h - thickness * 2, a, r, g, b)
    -- Right edge
    panel:drawRect(x + w - thickness, y + thickness, thickness, h - thickness * 2, a, r, g, b)
end

-- ---------------------------------------------------------------------------
-- ARROW TEXTURES — 16x16 PNGs in ZeD/icons, drawn scaled + tinted.
-- Lazy-loaded once, then cached.
-- ---------------------------------------------------------------------------
local _arrowTex = {}
local function _getArrowTex(name)
    if _arrowTex[name] == nil then
        _arrowTex[name] = getTexture("media/textures/ZeD/icons/" .. name .. ".png") or false
    end
    return _arrowTex[name]
end

-- Shared draw helper: draws the arrow texture scaled to `size` with color tint
local function _drawArrow(panel, name, x, y, size, color)
    local c = color or ZeD.T.textDim
    local tex = _getArrowTex(name)
    if tex then
        panel:drawTextureScaledAspect(tex, x, y, size, size, c.a or 1, c.r, c.g, c.b)
    end
end

-- ---------------------------------------------------------------------------
-- DISCLOSURE TRIANGLE — Right-pointing (collapsed)
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawTriangleRight(panel, x, y, size, color)
    _drawArrow(panel, "rt", x, y, size, color)
end

-- ---------------------------------------------------------------------------
-- DISCLOSURE TRIANGLE — Down-pointing (expanded)
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawTriangleDown(panel, x, y, size, color)
    _drawArrow(panel, "dn", x, y, size, color)
end

-- ---------------------------------------------------------------------------
-- DISCLOSURE TRIANGLE — Up-pointing (scrollbar up arrow)
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawTriangleUp(panel, x, y, size, color)
    _drawArrow(panel, "up", x, y, size, color)
end

-- ---------------------------------------------------------------------------
-- DISCLOSURE TRIANGLE — Left-pointing (back/submenu navigation)
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawTriangleLeft(panel, x, y, size, color)
    _drawArrow(panel, "lf", x, y, size, color)
end

-- ---------------------------------------------------------------------------
-- GROOVE DIVIDER — System 7.1 dark/light line pair
-- Draws at (x, y) across the given width. Total height: 2px.
-- Creates implied depth without drop shadows.
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawGroove(panel, x, y, width)
    local T = ZeD.T
    local dk = T.grooveDark
    local lt = T.grooveLight
    panel:drawRect(x, y, width, 1, dk.a, dk.r, dk.g, dk.b)
    panel:drawRect(x, y + 1, width, 1, lt.a, lt.r, lt.g, lt.b)
end

-- ---------------------------------------------------------------------------
-- SYSTEM 7 RESIZE RIDGES — diagonal ridge pairs for resize grip
-- Draws three diagonal ridge pairs in a square area at (x, y, size).
-- Used in the bottom-right corner of windows, integrated with scrollbar.
-- Each pair is a light line + shadow offset, drawn pixel-by-pixel along
-- the diagonal from lower-left to upper-right.
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawResizeRidges(panel, x, y, size)
    local T = ZeD.T
    local lt = T.textDim  -- light ridge
    local dk = T.base     -- dark ridge
    for i = 0, 2 do
        local offset = i * 4
        local x1 = x + size - 4 - offset
        local y1 = y + size - 2
        local x2 = x + size - 2
        local y2 = y + size - 4 - offset
        local steps = math.max(math.abs(x2 - x1), math.abs(y2 - y1))
        if steps > 0 then
            for s = 0, steps do
                local px = x1 + math.floor((x2 - x1) * s / steps)
                local py = y1 + math.floor((y2 - y1) * s / steps)
                panel:drawRect(px, py, 1, 1, T.ridgeLightA, lt.r, lt.g, lt.b)
            end
            -- Shadow line (1px offset)
            for s = 0, steps do
                local px = x1 + math.floor((x2 - x1) * s / steps) + 1
                local py = y1 + math.floor((y2 - y1) * s / steps) + 1
                if px < x + size - 1 and py < y + size - 1 then
                    panel:drawRect(px, py, 1, 1, T.ridgeDarkA, dk.r, dk.g, dk.b)
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- GROW BOX — System 7.1 resize handle (bg + border + ridges)
-- Composite atom: draws the complete grow box at the given position.
-- Used by ZeD_Window and CharacterWindow in the bottom-right corner.
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawGrowBox(panel, x, y, size)
    local T = ZeD.T
    local bg = T.surf2
    panel:drawRect(x, y, size, size, bg.a, bg.r, bg.g, bg.b)
    panel:drawRectBorder(x, y, size, size, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    ZeD.Atoms.drawResizeRidges(panel, x, y, size)
end

-- ---------------------------------------------------------------------------
-- CLOSE BOX — System 6 close box with X mark
-- Draws a small square button with an X glyph inside.
-- @param panel   ISPanel drawing context
-- @param x, y    Top-left position
-- @param size    Box dimensions (square)
-- @param hovered Boolean — show hover highlight
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawCloseBox(panel, x, y, size, hovered)
    local T = ZeD.T
    -- Background
    local bg = hovered and T.hover or T.surf2
    panel:drawRect(x, y, size, size, 1, bg.r, bg.g, bg.b)
    -- Border
    panel:drawRectBorder(x, y, size, size, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    -- X mark (two 1px diagonals)
    local m = math.max(3, math.floor(size * 0.25))  -- margin from edge
    local tc = T.textDim
    for i = 0, size - m * 2 - 1 do
        local px = x + m + i
        panel:drawRect(px, y + m + i, 1, 1, tc.a, tc.r, tc.g, tc.b)
        panel:drawRect(px, y + size - m - 1 - i, 1, 1, tc.a, tc.r, tc.g, tc.b)
    end
end

-- ---------------------------------------------------------------------------
-- STATUS LABEL — colored text for status indicators (LIT, IDLE, RUNNING)
-- Simple atom wrapping drawText with a semantic color.
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawStatusLabel(panel, text, x, y, color)
    local T = ZeD.T
    local c = color or T.text
    panel:drawText(text, x, y, c.r, c.g, c.b, c.a or 1, T.fontF1)
end

-- NOTE: drawStatusDot lives in Atoms.lua:397 — signature: (panel, x, y, color, size)
-- A string-based version was here previously but shadowed the Atoms version,
-- causing all callers (which pass color tables) to silently render dim/hollow.
-- Removed S65 cleanup. Use Atoms.drawStatusDot with a color table directly.

-- ---------------------------------------------------------------------------
-- 1PX ROUNDED CORNER HELPERS — corner-pixel clip for pill buttons
-- ---------------------------------------------------------------------------
local function fill1px(panel, x, y, w, h, a, r, g, b)
    panel:drawRect(x + 1, y, w - 2, 1, a, r, g, b)
    if h > 2 then
        panel:drawRect(x, y + 1, w, h - 2, a, r, g, b)
    end
    panel:drawRect(x + 1, y + h - 1, w - 2, 1, a, r, g, b)
end

local function border1px(panel, x, y, w, h, a, r, g, b)
    panel:drawRect(x + 1, y, w - 2, 1, a, r, g, b)
    panel:drawRect(x + 1, y + h - 1, w - 2, 1, a, r, g, b)
    panel:drawRect(x, y + 1, 1, h - 2, a, r, g, b)
    panel:drawRect(x + w - 1, y + 1, 1, h - 2, a, r, g, b)
end

-- ---------------------------------------------------------------------------
-- PILL BUTTON — toggle used for exercise/view selectors.
-- 1px rounded corners. Active: accent fill + border. Enabled: subtle accent.
-- Disabled: borderS border + dimmed text.
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawPillButton(panel, x, y, w, h, text, active, enabled, font)
    local T  = ZeD.T
    local sp = T.sp

    -- Base surface (1px rounded)
    local s1 = T.surf1
    fill1px(panel, x, y, w, h, s1.a, s1.r, s1.g, s1.b)

    if active then
        local ac = T.accent
        fill1px(panel, x, y, w, h, 0.15, ac.r, ac.g, ac.b)
        border1px(panel, x, y, w, h, 0.6, ac.r, ac.g, ac.b)
        local nc = T.toneNorm
        panel:drawText(text, x + sp.sm, y + math.floor((h - getTextManager():getFontHeight(font)) / 2),
            nc.r, nc.g, nc.b, nc.a or 1, font)
    elseif enabled then
        local ac = T.accent
        fill1px(panel, x, y, w, h, 0.10, ac.r, ac.g, ac.b)
        border1px(panel, x, y, w, h, 0.4, ac.r, ac.g, ac.b)
        local nc = T.toneNorm
        panel:drawText(text, x + sp.sm, y + math.floor((h - getTextManager():getFontHeight(font)) / 2),
            nc.r, nc.g, nc.b, nc.a or 1, font)
    else
        local bc = T.borderS
        border1px(panel, x, y, w, h, bc.a, bc.r, bc.g, bc.b)
        local lo = T.toneLo
        panel:drawText(text, x + sp.sm, y + math.floor((h - getTextManager():getFontHeight(font)) / 2),
            lo.r, lo.g, lo.b, lo.a, font)
    end
end

-- ---------------------------------------------------------------------------
-- LEGEND SWATCH — 8x14 tall rectangle used as color-coded status indicator
-- in recipe/training-material legends and row chips.
-- ghost: true → low alpha fill + faint border (for "missing"/"unknown").
-- Returns swatch width (8) for layout advancement.
-- ---------------------------------------------------------------------------
local SWATCH_W = 8
local SWATCH_H = 14

function ZeD.Atoms.drawLegendSwatch(panel, x, y, color, ghost)
    local a = ghost and 0.08 or (color.a or 0.85)
    panel:drawRect(x, y, SWATCH_W, SWATCH_H, a, color.r, color.g, color.b)
    if ghost then
        local bd = ZeD.T.border
        panel:drawRectBorder(x, y, SWATCH_W, SWATCH_H, bd.a * 0.3, bd.r, bd.g, bd.b)
    end
    return SWATCH_W
end

ZeD.Atoms.SWATCH_W = SWATCH_W
ZeD.Atoms.SWATCH_H = SWATCH_H

-- ===========================================================================
-- CONTEXT-MENU ATOMS (S88) — primitives for the unified horizontal strip menu.
-- Each atom is self-contained: takes a panel, draws, returns nothing. Uses
-- T.ctx tokens (see Tokens.lua) so geometry stays consistent across the
-- molecule composition layer above.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- drawSteppedShadow — System 7 hard 2px drop shadow offset down-right.
-- Draws an L-shaped ink block along the right and bottom edges of (x, y, w, h).
-- Paint this BEFORE the element itself. Step size from T.ctx.shadowStep.
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawSteppedShadow(panel, x, y, w, h, color)
    local s = (ZeD.T.ctx and ZeD.T.ctx.shadowStep) or 2
    local a = color.a or 1
    -- Right edge column (starts below element's top by shadowStep px so the
    -- shadow reads as a true drop, not a halo)
    panel:drawRect(x + w,     y + s, s, h,     a, color.r, color.g, color.b)
    -- Bottom edge row (starts at element's right shifted by shadowStep)
    panel:drawRect(x + s,     y + h, w,     s, a, color.r, color.g, color.b)
end

-- ---------------------------------------------------------------------------
-- drawDisabledStipple — 45° diagonal 1px dot pattern in (x, y, w, h).
-- Used to overlay disabled context cells. Each row shifts one pixel so the
-- dots line up on a /-direction diagonal. Caller supplies color (typically
-- ZeD.colorAlpha(T.text, 0.35) — dim but readable against paper).
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawDisabledStipple(panel, x, y, w, h, color)
    local a = color.a or 1
    for dy = 0, h - 1 do
        local startX = dy % 2   -- odd rows shift right one pixel → diagonal
        for dx = startX, w - 1, 2 do
            panel:drawRect(x + dx, y + dy, 1, 1, a, color.r, color.g, color.b)
        end
    end
end

-- ---------------------------------------------------------------------------
-- drawCornerTri3x3 — 3x3 right-triangle, hypotenuse facing top-left.
-- Pixels (relative to x,y):
--   . . #        row 0: 1px at far right
--   . # #        row 1: 2px starting at x+1
--   # # #        row 2: 3px full width
-- Use for submenu indicator (bottom-right of a cell with children).
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawCornerTri3x3(panel, x, y, color)
    local a = color.a or 1
    panel:drawRect(x + 2, y,     1, 1, a, color.r, color.g, color.b)
    panel:drawRect(x + 1, y + 1, 2, 1, a, color.r, color.g, color.b)
    panel:drawRect(x,     y + 2, 3, 1, a, color.r, color.g, color.b)
end

-- ---------------------------------------------------------------------------
-- drawCornerSq3x3 — 3x3 solid square. Used for pin indicator (top-right of
-- a pinned cell). One drawRect, sized from T.ctx.pinDotSz in callers.
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawCornerSq3x3(panel, x, y, color)
    local a = color.a or 1
    panel:drawRect(x, y, 3, 3, a, color.r, color.g, color.b)
end

-- ---------------------------------------------------------------------------
-- drawContextPointerDown — outlined triangle pointing DOWN. Used on the
-- floating label above the strip — apex of the pointer touches the selected
-- cell's top edge. x = horizontal center of apex, y = top of pointer block.
-- Renders as a 6x3 ink outer with a 4x2 paper inner cut into rows 0 and 1,
-- leaving row 2 as a solid 2-px ink apex.
--
-- Layout (ink = #, paper = .):
--   #. . . . #       row 0 (top, 6 wide)  — flanks ink, center paper
--   #. . #             row 1 (middle, 4 wide) — flanks ink, center paper
--     # #                 row 2 (apex, 2 wide) — all ink
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawContextPointerDown(panel, x, y, inkColor, paperColor)
    local ia, pa = inkColor.a or 1, paperColor.a or 1
    -- Ink outer (6 -> 4 -> 2 triangle)
    panel:drawRect(x - 3, y,     6, 1, ia, inkColor.r, inkColor.g, inkColor.b)
    panel:drawRect(x - 2, y + 1, 4, 1, ia, inkColor.r, inkColor.g, inkColor.b)
    panel:drawRect(x - 1, y + 2, 2, 1, ia, inkColor.r, inkColor.g, inkColor.b)
    -- Paper inner (4 wide row 0, 2 wide row 1) — carves the cutout
    panel:drawRect(x - 2, y,     4, 1, pa, paperColor.r, paperColor.g, paperColor.b)
    panel:drawRect(x - 1, y + 1, 2, 1, pa, paperColor.r, paperColor.g, paperColor.b)
end

-- ---------------------------------------------------------------------------
-- drawContextPointerUp — outlined triangle pointing UP. Used on the balloon's
-- top edge, pointing at the target card directly above it. x = horizontal
-- center of apex, y = top of apex (widest row is at y+2).
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawContextPointerUp(panel, x, y, inkColor, paperColor)
    local ia, pa = inkColor.a or 1, paperColor.a or 1
    -- Ink outer (2 -> 4 -> 6 inverted triangle)
    panel:drawRect(x - 1, y,     2, 1, ia, inkColor.r, inkColor.g, inkColor.b)
    panel:drawRect(x - 2, y + 1, 4, 1, ia, inkColor.r, inkColor.g, inkColor.b)
    panel:drawRect(x - 3, y + 2, 6, 1, ia, inkColor.r, inkColor.g, inkColor.b)
    -- Paper inner (carves middle + bottom of outline, leaves apex solid ink)
    panel:drawRect(x - 1, y + 1, 2, 1, pa, paperColor.r, paperColor.g, paperColor.b)
    panel:drawRect(x - 2, y + 2, 4, 1, pa, paperColor.r, paperColor.g, paperColor.b)
end

-- ---------------------------------------------------------------------------
-- drawBumper — paper System 7 block with 2px stepped shadow and centered
-- F1-Chrome label. Used at both ends of the context strip for group-jump.
--   label:     text displayed centered (typically « or »)
--   isPressed: bumper renders with shadow collapsed and content shifted 1/1
--              (System 7 "pressed button" convention)
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawBumper(panel, x, y, w, h, label, isPressed, T)
    T = T or ZeD.T
    -- S101: context-menu bumpers use locked paper/ink so they read the same
    -- on every theme (matches drawContextCell + drawContextBalloon).
    local ink   = { r = 0.08, g = 0.08, b = 0.08, a = 1 }
    local paper = { r = 0.95, g = 0.95, b = 0.95, a = 1 }
    local dx, dy = 0, 0
    if isPressed then
        dx, dy = 1, 1   -- shift into the shadow's space to fake the click depress
    else
        ZeD.Atoms.drawSteppedShadow(panel, x, y, w, h, ink)
    end
    -- Paper fill + ink border
    panel:drawRect(x + dx, y + dy, w, h, paper.a or 1, paper.r, paper.g, paper.b)
    panel:drawRectBorder(x + dx, y + dy, w, h, ink.a or 1, ink.r, ink.g, ink.b)
    -- Centered label (F1 chrome — mono bold — matches mockup's Fira Mono weight 700)
    if label and label ~= "" then
        local font = T.fontF1 or T.fontF2
        local tw = getTextManager():MeasureStringX(font, label)
        local th = getTextManager():getFontHeight(font)
        panel:drawText(label,
            x + dx + math.floor((w - tw) / 2),
            y + dy + math.floor((h - th) / 2),
            ink.r, ink.g, ink.b, 1, font)
    end
end

-- ---------------------------------------------------------------------------
-- drawTruncChevron — 12-wide × cellH-tall ink block with a paper triangle
-- glyph centered. Used only when the strip is truncating (N > 10). Uses the
-- existing drawTriangleLeft/Right textures because PZ bitmap fonts lack
-- reliable arrow glyphs (Q15b in PZAPI-KNOWLEDGE-BANK).
--   dir: "left"  → ◂-style (points at start of the list)
--        "right" → ▸-style (points at end of the list)
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawTruncChevron(panel, x, y, dir, T)
    T = T or ZeD.T
    local ctx   = T.ctx
    -- S101: locked context-menu palette so the ink-block chevron + paper
    -- glyph read identically on every theme.
    local ink   = { r = 0.08, g = 0.08, b = 0.08, a = 1 }
    local paper = { r = 0.95, g = 0.95, b = 0.95, a = 1 }
    local w, h  = ctx.chevW, ctx.cellH
    -- Shadow first (reads as depth from below-right)
    ZeD.Atoms.drawSteppedShadow(panel, x, y, w, h, ink)
    -- Solid ink block background
    panel:drawRect(x, y, w, h, ink.a or 1, ink.r, ink.g, ink.b)
    -- Paper glyph centered
    local triSz = 5
    local tx = x + math.floor((w - triSz) / 2)
    local ty = y + math.floor((h - triSz) / 2)
    if dir == "left" or dir == "prev" then
        ZeD.Atoms.drawTriangleLeft(panel, tx, ty, triSz, paper)
    else
        ZeD.Atoms.drawTriangleRight(panel, tx, ty, triSz, paper)
    end
end

-- ---------------------------------------------------------------------------
-- drawBackGlyph — accent-colored ◂ triangle sized to fit a context cell.
-- The cell background is drawn by drawContextCell; this atom only paints the
-- glyph. Per mockup, back cell keeps its accent glyph color whether the cell
-- is active or not (only the cell bg inverts).
-- ---------------------------------------------------------------------------
function ZeD.Atoms.drawBackGlyph(panel, x, y, w, h, isActive, T)
    T = T or ZeD.T
    local triSz = 8   -- larger than the chevron — this is the cell's primary glyph
    local tx = x + math.floor((w - triSz) / 2)
    local ty = y + math.floor((h - triSz) / 2)
    -- When the back cell is selected, the cell bg is accent — switch the glyph
    -- to locked paper so the triangle stays visible. Otherwise accent on paper.
    -- S101: paper locked to near-white for cross-theme consistency.
    local color = isActive and {r = 0.95, g = 0.95, b = 0.95, a = 1} or T.accent
    ZeD.Atoms.drawTriangleLeft(panel, tx, ty, triSz, color)
end

