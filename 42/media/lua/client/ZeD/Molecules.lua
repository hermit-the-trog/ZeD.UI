-- ZeD-UI/42/media/lua/client/ZeD/Molecules.lua
-- ============================================================================
-- MOLECULE FACTORIES & COMPONENTS
-- Each molecule is composed of atoms. They are either:
--   - Draw functions (called inside a parent's render/prerender)
--   - ISPanel subclasses (created and added as children)
--
-- All molecules read from ZeD.T (the active palette).
-- ============================================================================

require "ISUI/ISPanel"

-- Make sure atoms are loaded
require "ZeD/Atoms"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.Molecules = ZeD.Molecules or {}

-- ============================================================================
-- 01. BUTTON
-- A clickable rectangle with a label. Three variants: default, primary, danger.
-- This is a factory that returns a configured ISButton.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- SYSTEM 7 BUTTON CHROME (draw helper)
-- The classic outset look: 1px outer border, 1px inner highlight (top+left),
-- 1px inner shadow (bottom+right). Creates that raised-plastic feel.
-- For pressed state: highlight and shadow swap (inset).
-- ---------------------------------------------------------------------------

--- Draw a System 7 style button at (x, y) with dimensions (w, h)
-- @param panel    The parent ISPanel
-- @param x, y     Position
-- @param w, h     Dimensions
-- @param text     Button label
-- @param variant  "default", "primary", "danger", or "flat" (S115 — chassis flat-bordered)
-- @param pressed  Is the button currently pressed?
-- @param colors   Optional override for "flat" variant — { bg, border, text, font? }.
--                 Each value is an RGBA table. font is optional UIFont reference
--                 (defaults to fontF3). Required only for variant == "flat".
--                 The other variants read two optional fields: fill (an RGBA drawn
--                 under the chrome: the 0.55 focus or 0.22 hover accent) and text
--                 (the label colour, e.g. T.text over a focus fill, where a red or
--                 accent label would sink into the accent). keepCase = true draws
--                 the label as given instead of in sentence case (a key's name).
-- @param opts     Optional (the cohesion pass; the push button's states, spec 5 and 7):
--                   hover    = bool: the T.hover wash under the outline
--                   disabled = bool: the whole control at T.disabledAlpha (no pulse)
--                   compact  = bool: height T.buttonH - T.px(4) (inside a list row),
--                              centred in the h given
--                   focus    = the ZeD.Focus.mark opts ({ win = win, ... }), or true
--                              (= { win = opts.win }), when this button has the
--                              controller's focus: the mark is drawn under the words
--                   help     = the plain-words help the window's footer line shows
--                              while the pointer is over it (ZeD.Help.set)
--                   win      = the window, for help (default: the window the panel is in)
--                   font     = the label's font (default F3)
-- @return x, y, w, h  the rect drawn (compact moves and shortens it)
local NO_OPTS = {}
local _focusOpts = {}

-- the focus mark opts for a control's opts.focus
local function focusOptsOf(opts)
    local f = opts.focus
    if f == true then
        _focusOpts.win = opts.win
        return _focusOpts
    end
    return f
end

-- The focus mark opts for one part of a strip that draws several (a sort strip's choices, a
-- stepper's keys, a card's chips), from the strip's opts:
--   focusId    = the id of the part that has the controller's focus (the id of the zone or
--                rect the strip hands back), with focus = its mark opts (default { win })
--   focusParts = { [id] = mark opts or true, ... } (a caller that asks per part)
-- nil when that part does not have the focus. (The table is reused: use it at once.)
local _partFocus = {}
local function partFocus(opts, id)
    if not opts or id == nil then return nil end
    local f
    if opts.focusId ~= nil and opts.focusId == id then
        f = opts.focus or true
    elseif opts.focusParts then
        f = opts.focusParts[id]
    end
    if not f then return nil end
    if f == true then
        _partFocus.win = opts.win
        return _partFocus
    end
    return f
end

-- the window footer's help line for a hovered control (ZeD.Help, the window builder's)
local function giveHelp(panel, opts)
    if not opts.help then return end
    local H = ZeD.Help
    if H and H.set then H.set(opts.win or panel, opts.help) end
end

-- a colour with its alpha scaled, in a reused table (one per call site that needs it)
local function withAlpha(out, c, a)
    out.r, out.g, out.b, out.a = c.r, c.g, c.b, (c.a or 1) * a
    return out
end

function ZeD.Molecules.drawButton(panel, x, y, w, h, text, variant, pressed, colors, opts)
    local T = ZeD.T
    local A = ZeD.Atoms
    variant = variant or "default"
    pressed = pressed or false

    -- Flat variant short-circuits the System 7 chrome — solid fill + 1px square
    -- border, no rounded corners, no bevel. Drives chassis buttons (radio
    -- power/seek/vol/preset/transport) where the silver or black plastic look
    -- needs to be flat against the recessed panel.
    if variant == "flat" then
        local c = colors or {}
        local bg     = c.bg     or T.surf3
        local border = c.border or T.borderS
        local txt    = c.text   or T.text
        local font   = c.font   or T.fontF3
        panel:drawRect(x, y, w, h, bg.a or 1.0, bg.r, bg.g, bg.b)
        panel:drawRectBorder(x, y, w, h, border.a or 1.0, border.r, border.g, border.b)
        local tw = ZeD.TM:MeasureStringX(font, text)
        local th = ZeD.TM:getFontHeight(font)
        local tx = x + math.floor((w - tw) / 2)
        local ty = y + math.floor((h - th) / 2)
        if pressed then tx = tx + T.px(1); ty = ty + T.px(1) end
        panel:drawText(text, tx, ty, txt.r, txt.g, txt.b, txt.a or 1, font)
        return x, y, w, h
    end

    opts = opts or NO_OPTS
    if opts.compact then
        local ch = T.buttonH - T.px(4)
        if h and h > ch then y = y + math.floor((h - ch) / 2) end
        h = ch
    end
    local alpha = opts.disabled and T.disabledAlpha or 1

    -- Button words read in sentence case (ZeD.btnCase); the flat variant above is
    -- printed hardware (radio chassis keys) and keeps what it is given, as does a
    -- label passed with colors.keepCase (a key's name: SPACE, LSHIFT)
    if not (colors and colors.keepCase) then text = ZeD.btnCase(text) end
    local font = opts.font or T.fontF3

    -- Hover: the T.hover wash, under the outline
    if opts.hover and not opts.disabled then
        local hv = T.hover
        A.fillRounded(panel, x, y, w, h, hv.r, hv.g, hv.b, hv.a or 1)
    end

    -- Optional fill under the chrome (a caller's own focus / hover / active fill)
    if colors and colors.fill then
        local f = colors.fill
        A.fillRounded(panel, x, y, w, h, f.r, f.g, f.b, (f.a or 1) * alpha)
    end

    -- Variant determines border, fill, and text color.
    -- Danger pulses a red fill to signal destructive action (not while disabled).
    local borderColor, textColor
    if variant == "primary" then
        borderColor = T.accent
        textColor = T.accentText
    elseif variant == "danger" then
        borderColor = T.danger
        textColor = T.dangerText
        if not opts.disabled then
            local pulse = math.sin((getTimestampMs() or 0) / 400) * 0.5 + 0.5
            local fillA = T.dangerPulseMin + pulse * (T.dangerPulseMax - T.dangerPulseMin)
            A.fillRounded(panel, x, y, w, h, T.danger.r, T.danger.g, T.danger.b, fillA)
        end
    else
        borderColor = T.borderS
        textColor = T.text
    end

    -- The controller's focus mark, under the words (ZeD_FocusPaint.lua)
    local onFocus = false
    if opts.focus and ZeD.Focus and ZeD.Focus.mark then
        onFocus = ZeD.Focus.mark(panel, x, y, w, h, focusOptsOf(opts), true)
    end

    if colors and colors.text then
        textColor = colors.text
    elseif onFocus or (colors and colors.fill and (colors.fill.a or 1) >= 0.5) then
        -- a wash of 0.5 or more: the label is the focus ink, whatever the variant's own colour
        textColor = T.textOnFocus
    end
    if onFocus then borderColor = T.textOnFocus end

    -- Rounded border (colored per variant)
    A.borderDoubleRounded(panel, x, y, w, h, borderColor.r, borderColor.g, borderColor.b, (borderColor.a or 1) * alpha)

    -- Centered label (K22 Xanthus — instrument chrome)
    local tw = ZeD.TM:MeasureStringX(font, text)
    local th = ZeD.TM:getFontHeight(font)
    local tx = x + math.floor((w - tw) / 2)
    local ty = y + math.floor((h - th) / 2)
    if pressed then tx = tx + T.px(1); ty = ty + T.px(1) end
    panel:drawText(text, tx, ty, textColor.r, textColor.g, textColor.b, (textColor.a or 1) * alpha, font)

    if opts.hover then giveHelp(panel, opts) end
    return x, y, w, h
end

--- A push button's natural width for a label: the label as it draws (sentence
-- case, F3 unless a font is given) plus T.sp.buttonPadX each side, at least 60u.
function ZeD.Molecules.buttonW(text, font)
    local T = ZeD.T
    local s = ZeD.btnCase(text or "")
    local w = ZeD.TM:MeasureStringX(font or T.fontF3, s) + T.sp.buttonPadX * 2
    return math.max(w, T.px(60))
end

-- ============================================================================
-- 01b. ICON BUTTON (cohesion spec 7)
-- A square button holding a picture: the push button's rounded outline (single),
-- a 16u icon centred, the T.hover wash on hover, solid accent when active (an
-- icon toggle that is on: the List of List / Grid), the whole control at
-- T.disabledAlpha when disabled, and a hint (its name) after ZeD.HINT_DELAY_MS.
-- Icon buttons have no words, so they are the buttons that get hints.
-- ============================================================================

--- Draw an icon button.
-- @param size  side in px (default T.buttonH)
-- @param icon  a Texture, a ZeD pixel icon's id (a string: ZeD.PxIcon, drawn
--              pixel for pixel), or a function(panel, x, y, size, color)
--              drawing the picture in (x, y, size) in `color` (alpha applied)
-- @param opts  optional { hover, active, disabled, pressed, focus (mark opts or
--              true), hint = its name (shown after the delay), id = a key for the
--              hint, help, win, iconSize (default 16u), tint }
-- @return x, y, w, h
local _icC, _icFocus = {}, {}
function ZeD.Molecules.drawIconButton(panel, x, y, size, icon, opts)
    local T = ZeD.T
    local A = ZeD.Atoms
    opts = opts or NO_OPTS
    size = size or T.buttonH
    local alpha = opts.disabled and T.disabledAlpha or 1
    local active = opts.active and true or false
    if active then
        local ac = T.accent
        A.fillRounded(panel, x, y, size, size, ac.r, ac.g, ac.b, (ac.a or 1) * alpha)
    elseif opts.hover and not opts.disabled then
        local hv = T.hover
        A.fillRounded(panel, x, y, size, size, hv.r, hv.g, hv.b, hv.a or 1)
    end
    local onFocus = false
    if opts.focus and ZeD.Focus and ZeD.Focus.mark then
        local f = focusOptsOf(opts)
        if f then
            -- the caller's opts plus solid = active (an active icon button is solid accent)
            local m = _icFocus
            m.win, m.zone, m.focused, m.pad, m.solid = f.win, f.zone, f.focused, f.pad, active or f.solid
            onFocus = ZeD.Focus.mark(panel, x, y, size, size, m, true)
        end
    end
    local bc = active and T.accent or (onFocus and T.textOnFocus or T.borderS)
    A.borderRounded(panel, x, y, size, size, bc.r, bc.g, bc.b, (bc.a or 1) * alpha)

    local ic = active and T.textOnAccent or (onFocus and T.textOnFocus or (opts.tint or T.text))
    local isz = math.min(opts.iconSize or T.px(16), size - T.px(4))
    local ix = x + math.floor((size - isz) / 2)
    local iy = y + math.floor((size - isz) / 2)
    if opts.pressed then ix = ix + T.px(1); iy = iy + T.px(1) end
    if type(icon) == "function" then
        icon(panel, ix, iy, isz, withAlpha(_icC, ic, alpha))
    elseif type(icon) == "string" then
        -- a ZeD pixel icon by its id: its drawing for this box, pixel for pixel
        A.drawPxIcon(panel, icon, ix, iy, isz, (ic.a or 1) * alpha, ic)
    elseif icon then
        A.drawIcon(panel, icon, ix, iy, isz, (ic.a or 1) * alpha, ic)
    end

    if opts.hover then
        giveHelp(panel, opts)
        if opts.hint and A.requestHint then
            A.requestHint(opts.win or A.windowOf(panel), opts.id or opts.hint, opts.hint, panel)
        end
    end
    return x, y, size, size
end

-- the back key's picture: a left triangle
local function drawBackGlyph(p, x, y, s, c)
    local t = math.max(ZeD.T.px(6), math.floor(s * 0.6))
    ZeD.Atoms.drawTriangleLeft(p, x + math.floor((s - t) / 2), y + math.floor((s - t) / 2), t, c)
end

--- The back key, the same on every card and drawer: an icon button with a left
-- triangle (cohesion spec 7). opts as drawIconButton; its hint defaults to "Back".
local _backOpts = {}
function ZeD.Molecules.drawBackButton(panel, x, y, size, opts)
    opts = opts or NO_OPTS
    local b = _backOpts
    b.hover, b.active, b.disabled, b.pressed = opts.hover, opts.active, opts.disabled, opts.pressed
    b.focus, b.help, b.win, b.tint = opts.focus, opts.help, opts.win, opts.tint
    b.hint = opts.hint or ZeD.tr("UI_ZeD_Prompt_Back")
    b.id = opts.id or "back"
    return ZeD.Molecules.drawIconButton(panel, x, y, size, drawBackGlyph, b)
end

-- ============================================================================
-- ZeD_Button — ISPanel-based button (no ISButton dependency)
-- Delegates all rendering to Molecules.drawButton() draw helper.
-- ============================================================================

ZeD_Button = ISPanel:derive("ZeD_Button")

function ZeD_Button:new(x, y, w, h, text, target, onclick)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0}
    o.borderColor     = {r = 0, g = 0, b = 0, a = 0}
    o.text = text or ""
    o.target = target
    o.onclick = onclick
    o._zedVariant = "default"
    o._hovered = false
    o._pressed = false
    return o
end

function ZeD_Button:prerender()
    -- Hover detection
    local mx, my = self:getMouseX(), self:getMouseY()
    self._hovered = mx >= 0 and mx < self.width and my >= 0 and my < self.height

    -- Draw using existing molecule draw helper
    self._zedOpts = self._zedOpts or {}
    self._zedOpts.hover = self._hovered
    ZeD.Molecules.drawButton(self, 0, 0, self.width, self.height,
        self.text, self._zedVariant, self._pressed, nil, self._zedOpts)
end

function ZeD_Button:render()
    -- All drawing in prerender
end

function ZeD_Button:onMouseDown(x, y)
    self._pressed = true
    return true
end

function ZeD_Button:onMouseUp(x, y)
    if self._pressed and self._hovered then
        if self.onclick then
            self.onclick(self.target, self)
        end
    end
    self._pressed = false
    return true
end

function ZeD_Button:onMouseUpOutside(x, y)
    self._pressed = false
end

--- Create a ZeD-styled button (ISPanel-based, no vanilla ISButton)
-- @param x, y      Position
-- @param w         Width (optional — if nil, sizes to text + padding)
-- @param text      Button label
-- @param target    Callback target (usually self/parent)
-- @param onclick   Click callback function
-- @param variant   "default", "primary", or "danger" (optional, defaults to "default")
-- @return ZeD_Button  A fully styled button ready to initialise() and addChild()
function ZeD.Molecules.Button(x, y, w, text, target, onclick, variant)
    local T = ZeD.T
    local sp = T.sp
    variant = variant or "default"

    -- Auto-width if not specified
    if not w then
        w = ZeD.TM:MeasureStringX(T.fontF3, text) + sp.buttonPadX * 2
        w = math.max(w, T.px(60)) -- minimum width
    end

    local btn = ZeD_Button:new(x, y, w, T.buttonH, text, target, onclick)
    btn._zedVariant = variant
    return btn
end


-- ============================================================================
-- 02. LIST ROW (draw helper)
-- A single row in a list. Drawn by the parent list organism.
-- This is a draw function, not a component — the list organism calls it
-- for each visible row during render().
-- ============================================================================

--- Draw a list row
-- @param panel     The parent ISPanel doing the drawing
-- @param x, y      Top-left position of the row
-- @param w         Row width
-- @param item      Table: {text=, meta=, icon=, selected=, disabled=}
-- @param hovered   Is this row currently hovered?
function ZeD.Molecules.drawListRow(panel, x, y, w, item, hovered)
    local T = ZeD.T
    local A = ZeD.Atoms
    local sp = T.sp
    local h = T.rowH
    local selected = item.selected or false
    local disabled = item.disabled or false
    local alpha = disabled and T.disabledAlpha or 1.0

    -- Background: selected = the one accent wash (T.selectionA); hover = T.hover,
    -- over it when both (cohesion spec 5)
    if selected then
        local ac = T.accent
        panel:drawRect(x, y, w, h, (T.selectionA or 0.30) * alpha, ac.r, ac.g, ac.b)
    end
    if hovered and not disabled then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end

    -- Content positioning
    local cx = x + sp.sm  -- left padding

    -- Icon (optional)
    if item.icon then
        local iconY = y + (h - T.iconSm) / 2
        A.drawIcon(panel, item.icon, cx, iconY, T.iconSm, alpha)
        cx = cx + T.iconSm + sp.iconGap
    end

    -- Primary text (the washes are light: the words keep their colours)
    local textColor = ZeD.colorAlpha(T.text, alpha)

    local textY = y + (h - ZeD.TM:MeasureStringY(T.fontF2, item.text or "")) / 2
    panel:drawText(item.text or "", cx, textY,
        textColor.r, textColor.g, textColor.b, textColor.a, T.fontF2)

    -- Metadata text (right-aligned)
    if item.meta then
        local metaColor = ZeD.colorAlpha(T.textSec, alpha)
        A.drawTextRight(panel, item.meta, x + w - sp.sm, textY, T.fontF1, metaColor)
    end

    -- Bottom divider (soft)
    A.drawDividerH(panel, x, y + h - T.px(1), w, false)
end


-- ============================================================================
-- 03. TAB BUTTON (draw helper)
-- A single tab in a tab strip. Drawn by the tab panel organism.
-- System 6 style: active tab has no bottom border, connecting to content.
-- ============================================================================

--- Draw a tab button
-- @param panel    The parent ISPanel
-- @param x, y     Top-left position
-- @param text     Tab label
-- @param active   Is this the active tab?
-- @param hovered  Is this tab hovered?
-- @param disabled Is this tab disabled?
-- @param opts     Optional { font (default F2), focus (the ZeD.Focus.mark opts) }
-- @return width   Total width of the drawn tab (for laying out the next one)
-- The one sub-tab strip (cohesion spec 9; Journal and Animals move onto it): the
-- active tab is surface 2 open at the bottom into its content, its words bright;
-- the others surface 1 with dim words; hover is the T.hover wash. Words read in
-- sentence case.
function ZeD.Molecules.drawTab(panel, x, y, text, active, hovered, disabled, opts)
    local T = ZeD.T
    local A = ZeD.Atoms
    local sp = T.sp
    local h = T.tabH
    local alpha = disabled and T.disabledAlpha or 1.0
    opts = opts or NO_OPTS
    local font = opts.font or T.fontF2
    text = A.textCase(text)

    -- Measure text to determine tab width
    local tw = ZeD.TM:MeasureStringX(font, text)
    local w = tw + sp.tabPadX * 2

    -- Background (a window surface: no stacking over the body)
    A.surfaceFill(panel, x, y, w, h, active and "surf2" or "surf1")
    if hovered and not disabled and not active then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end
    local onFocus = false
    if opts.focus and ZeD.Focus and ZeD.Focus.mark then
        onFocus = ZeD.Focus.mark(panel, x, y, w, h, opts.focus)
    end

    -- Borders: top, left, right always. Bottom only if inactive.
    local bc = T.borderS
    local bw = T.line(T.borderW)  -- T.borderW is design units (1, HC 2): that many hairlines
    -- Top
    panel:drawRect(x, y, w, bw, bc.a * alpha, bc.r, bc.g, bc.b)
    -- Left
    panel:drawRect(x, y, bw, h, bc.a * alpha, bc.r, bc.g, bc.b)
    -- Right
    panel:drawRect(x + w - bw, y, bw, h, bc.a * alpha, bc.r, bc.g, bc.b)
    -- Bottom — only on inactive tabs
    if not active then
        panel:drawRect(x, y + h - bw, w, bw, bc.a * alpha, bc.r, bc.g, bc.b)
    end

    -- Label: the active tab's words bright, the others dim
    local textColor
    if onFocus then
        textColor = ZeD.colorAlpha(T.textOnFocus, alpha)
    elseif active then
        textColor = ZeD.colorAlpha(T.textHead, alpha)
    elseif hovered and not disabled then
        textColor = ZeD.colorAlpha(T.text, alpha)
    else
        textColor = ZeD.colorAlpha(T.textDim, alpha)
    end
    local textY = y + math.floor((h - ZeD.TM:getFontHeight(font)) / 2)
    panel:drawText(text, x + sp.tabPadX, textY,
        textColor.r, textColor.g, textColor.b, textColor.a, font)

    return w
end


-- ============================================================================
-- 04. TEXT INPUT FIELD
-- An editable text box. ISPanel subclass with keyboard focus handling.
-- ============================================================================

ZeD_TextInput = ISPanel:derive("ZeD_TextInput")

function ZeD_TextInput:new(x, y, w, placeholder)
    local T = ZeD.T
    local h = T.inputH
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.placeholder = placeholder or ""
    o.text = ""
    o.focused = false
    o.cursorBlink = 0   -- timer for cursor blinking
    o.cursorVisible = true
    o.onTextChange = nil  -- callback: function(self, text)
    o.onSubmit = nil      -- callback: function(self, text) — fires on Enter
    o.disabled = false
    o.borderEdges = nil  -- nil = all edges, or {top=, right=, bottom=, left=}
    return o
end

function ZeD_TextInput:prerender()
    local T = ZeD.T
    local alpha = self.disabled and T.disabledAlpha or 1.0

    -- Background (recessed)
    local bg = T.surf1
    self:drawRect(0, 0, self.width, self.height, bg.a * alpha, bg.r, bg.g, bg.b)

    -- Border (respects edge flags)
    ZeD.Atoms.drawBorder(self, 0, 0, self.width, self.height, self.borderEdges)
end

function ZeD_TextInput:render()
    local T = ZeD.T
    local sp = T.sp
    local alpha = self.disabled and T.disabledAlpha or 1.0

    local textY = (self.height - ZeD.TM:MeasureStringY(T.fontF2, "X")) / 2

    if #self.text > 0 then
        -- Draw actual text
        local tc = ZeD.colorAlpha(T.text, alpha)
        self:drawText(self.text, sp.inputPadX, textY,
            tc.r, tc.g, tc.b, tc.a, T.fontF2)

        -- Cursor after text
        if self.focused and self.cursorVisible then
            local tw = ZeD.TM:MeasureStringX(T.fontF2, self.text)
            local cursorX = sp.inputPadX + tw + T.px(1)
            local cursorH = ZeD.TM:MeasureStringY(T.fontF2, "X")
            local ac = T.accent
            self:drawRect(cursorX, textY, T.px(1), cursorH, ac.a, ac.r, ac.g, ac.b)
        end
    else
        -- Placeholder text
        local pc = ZeD.colorAlpha(T.textSec, alpha)
        self:drawText(self.placeholder, sp.inputPadX, textY,
            pc.r, pc.g, pc.b, pc.a, T.fontF2)

        -- Cursor at start
        if self.focused and self.cursorVisible then
            local cursorH = ZeD.TM:MeasureStringY(T.fontF2, "X")
            local ac = T.accent
            self:drawRect(sp.inputPadX, textY, T.px(1), cursorH, ac.a, ac.r, ac.g, ac.b)
        end
    end
end

function ZeD_TextInput:update()
    ISPanel.update(self)
    -- Blink cursor every 500ms
    if self.focused then
        self.cursorBlink = self.cursorBlink + (1000 / 60)  -- approx per-frame ms
        if self.cursorBlink > 500 then
            self.cursorVisible = not self.cursorVisible
            self.cursorBlink = 0
        end
    end
end

function ZeD_TextInput:onMouseDown(x, y)
    if self.disabled then return end
    self.focused = true
    self.cursorVisible = true
    self.cursorBlink = 0
    return true
end

function ZeD_TextInput:onOtherBodyClick()
    self.focused = false
end

function ZeD_TextInput:onKeyPress(key)
    if not self.focused or self.disabled then return end
    -- Visual-only stub. Real text input uses ZeD_TextEntry (ISTextEntryBox wrapper).
end

function ZeD_TextInput:setText(text)
    self.text = text or ""
    if self.onTextChange then
        self.onTextChange(self, self.text)
    end
end

function ZeD_TextInput:getText()
    return self.text
end

ZeD.Molecules.TextInput = ZeD_TextInput


-- ============================================================================
-- 05. SEARCH FIELD
-- A text input with a search icon on the left.
-- ============================================================================

ZeD_SearchField = ISPanel:derive("ZeD_SearchField")

function ZeD_SearchField:new(x, y, w, placeholder)
    local T = ZeD.T
    local h = T.inputH
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    o.placeholder = placeholder or ZeD.tr("IGUI_FilterSearch")
    o.iconAreaW = 24   -- reserved width for the search icon (S124 scale: design units, wrapped with T.px where used)
    o.onFilter = nil   -- callback: function(self, text) — fires on each keystroke
    o.onSubmit = nil   -- callback: function(self, text) — fires on Enter
    o.borderEdges = nil
    return o
end

function ZeD_SearchField:createChildren()
    ISPanel.createChildren(self)

    -- Real ISTextEntryBox captures keyboard focus and suppresses game keybinds
    local T = ZeD.T
    local inputW = self.width - T.px(self.iconAreaW)
    local entry = ISTextEntryBox:new("", T.px(self.iconAreaW), 0, inputW, self.height)
    entry:initialise()
    entry:instantiate()
    -- Typed text and the placeholder follow the UI scale (ZeD.Text.fitEntry
    -- swaps in the baked face each frame; Overrides/TextScale.lua)
    entry.zedEntry = true
    entry.javaObject:setCentreVertically(true)
    entry:setPlaceholderText(self.placeholder or "")
    self._shownPlaceholder = self.placeholder or ""
    entry.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    entry.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    entry.onCommandEntered = function()
        local text = entry:getText() or ""
        if self.onSubmit then self.onSubmit(self, text) end
    end
    self:addChild(entry)
    self.input = entry
    self._lastText = ""
end

function ZeD_SearchField:update()
    ISPanel.update(self)
    -- Poll text changes (ISTextEntryBox has no per-keystroke callback)
    if self.input then
        local text = self.input:getText() or ""
        if text ~= self._lastText then
            self._lastText = text
            if self.onFilter then self.onFilter(self, text) end
        end
    end
end

function ZeD_SearchField:prerender()
    local T = ZeD.T
    -- Sync input size to parent (toolbar resizes dynamically)
    if self.input then
        self.input:setX(T.px(self.iconAreaW))
        self.input:setWidth(self.width - T.px(self.iconAreaW))
        self.input:setHeight(self.height)
        -- The owner may swap the placeholder by mode ("Filter alternatives...")
        local ph = self.placeholder or ""
        if self._shownPlaceholder ~= ph then
            self._shownPlaceholder = ph
            self.input:setPlaceholderText(ph)
        end
    end
    -- Background matches input
    local bg = T.surf1
    self:drawRect(0, 0, self.width, self.height, bg.a, bg.r, bg.g, bg.b)
    -- 1px border
    local bc = T.borderS
    self:drawRectBorder(0, 0, self.width, self.height, bc.a, bc.r, bc.g, bc.b)
end

function ZeD_SearchField:render()
    local T = ZeD.T
    -- Search icon (/ character as a simple glyph)
    local iconColor = T.textDim
    local iconY = (self.height - ZeD.TM:MeasureStringY(T.fontF1, "/")) / 2
    self:drawText("/", T.px(8), iconY,
        iconColor.r, iconColor.g, iconColor.b, iconColor.a, T.fontF1)
end

function ZeD_SearchField:getText()
    return self.input and self.input:getText() or ""
end

function ZeD_SearchField:clear()
    if self.input then
        self.input:setText("")
        self._lastText = ""
    end
end

ZeD.Molecules.SearchField = ZeD_SearchField


-- ============================================================================
-- 05b. TEXT ENTRY (component — ISTextEntryBox wrapper with ZeD styling)
-- Multi-line text input with real keyboard handling. Embeds a vanilla
-- ISTextEntryBox as a child and applies ZeD token colors on each frame.
-- ============================================================================

require "ISUI/ISTextEntryBox"

ZeD_TextEntry = ISPanel:derive("ZeD_TextEntry")

function ZeD_TextEntry:new(x, y, w, h, placeholder)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.placeholder = placeholder or ""
    o.onSubmit = nil     -- callback: function(self, text) — fires on Ctrl+Enter
    o.maxLines = 3
    o.maxLength = 500
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

function ZeD_TextEntry:createChildren()
    ISPanel.createChildren(self)
    local T = ZeD.T
    local entry = ISTextEntryBox:new("", 0, 0, self.width, self.height)
    entry:initialise()
    entry:instantiate()
    entry:setMultipleLine(true)
    entry.javaObject:setMaxLines(self.maxLines)
    entry.javaObject:setMaxTextLength(self.maxLength)
    entry.zedEntry = true   -- typed text follows the UI scale (ZeD.Text.fitEntry)
    -- Apply ZeD token colors to vanilla component
    entry.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    entry.borderColor = { r = T.borderS.r, g = T.borderS.g, b = T.borderS.b, a = T.borderS.a }
    self:addChild(entry)
    self._entry = entry
end

function ZeD_TextEntry:prerender()
    -- Sync size if parent repositions us
    if self._entry then
        self._entry:setWidth(self.width)
        self._entry:setHeight(self.height)
    end
end

function ZeD_TextEntry:render()
    -- Placeholder text when empty and not focused
    if self._entry and self._entry:getText() == "" and not self._entry:isFocused() then
        local T = ZeD.T
        local pc = T.textDim
        local py = T.px(4)
        self:drawText(self.placeholder, T.sp.inputPadX or T.px(6), py,
            pc.r, pc.g, pc.b, pc.a or 0.5, T.fontF2)
    end
end

function ZeD_TextEntry:getText()
    return self._entry and self._entry:getText() or ""
end

function ZeD_TextEntry:setText(text)
    if self._entry then self._entry:setText(text or "") end
end

function ZeD_TextEntry:clear()
    if self._entry then self._entry:setText("") end
end

function ZeD_TextEntry:focus()
    if self._entry then self._entry:focus() end
end

ZeD.Molecules.TextEntry = ZeD_TextEntry


-- ============================================================================
-- 06. STAT CHIP (draw helper)
-- A compact icon + value pair for the title bar.
-- ============================================================================

--- Draw a stat chip
-- @param panel   The parent ISPanel
-- @param x, y    Position
-- @param icon    Optional icon texture (or nil for text-only)
-- @param value   Display value string (e.g., "12.4/20")
-- @param state   "default", "warning", or "danger"
-- @return width  Total width of the chip (for layout math)
function ZeD.Molecules.drawStatChip(panel, x, y, icon, value, state)
    local T = ZeD.T
    local cx = x

    -- Pick value color based on state
    local valueColor
    if state == "danger" then
        valueColor = T.dangerText
    elseif state == "warning" then
        valueColor = T.warningText
    else
        valueColor = T.textSec
    end

    -- Icon (optional)
    if icon then
        local iconY = y + (T.titleBarH - T.statIconSz) / 2
        ZeD.Atoms.drawIcon(panel, icon, cx, iconY, T.statIconSz)
        cx = cx + T.statIconSz + T.sp.statIconGap  -- tight gap between icon and value
    end

    -- Value text (K22 Xanthus — chrome data voice)
    local textY = y + (T.titleBarH - ZeD.TM:MeasureStringY(T.fontF3, value)) / 2
    panel:drawText(value, cx, textY,
        valueColor.r, valueColor.g, valueColor.b, valueColor.a, T.fontF3)
    cx = cx + ZeD.TM:MeasureStringX(T.fontF3, value)

    return cx - x  -- total width consumed
end


-- ============================================================================
-- 07. SCROLLBAR (assembled component)
-- The full scrollbar: track + thumb + arrows. ISPanel subclass that
-- manages scroll state and fires callbacks.
-- ============================================================================

-- ZeD_ScrollbarState: Pure state + draw object (NOT an ISPanel).
-- The parent list owns all interaction and calls draw/handle methods directly.
-- This avoids Java child event dispatch issues entirely.

ZeD_ScrollbarState = {}
ZeD_ScrollbarState.__index = ZeD_ScrollbarState

function ZeD_ScrollbarState:new()
    local o = {}
    setmetatable(o, self)
    local T = ZeD.T
    o.x = 0
    o.y = 0
    o.width = T.sp.scrollbarW
    o.height = T.px(100)
    o.arrowH = T.sp.scrollbarW    -- arrows are square
    o.reserveBottom = 0           -- pixels to leave empty at the bottom
                                  -- (for grow box / resize grip integration)
    o.scrollPos = 0               -- 0.0 to 1.0
    o.barSizeRatio = 1.0          -- visible / total
    o.dragging = false
    o.dragStartY = 0
    o.dragStartPos = 0
    o.thumbHover = false
    o.upHover = false
    o.downHover = false
    o.upPressed = false
    o.downPressed = false
    o.visible = false
    o.onScroll = nil              -- callback(scrollPos)
    return o
end

function ZeD_ScrollbarState:getTrackHeight()
    -- Usable height minus up arrow, down arrow, and reserved bottom space
    return self.height - self.arrowH * 2 - self.reserveBottom
end

function ZeD_ScrollbarState:getThumbHeight()
    local T = ZeD.T
    local trackH = self:getTrackHeight()
    if trackH <= 0 then return 0 end
    local thumbH = math.floor(trackH * self.barSizeRatio)
    return math.max(T.px(20), math.min(thumbH, trackH))
end

function ZeD_ScrollbarState:getThumbY()
    local trackH = self:getTrackHeight()
    local thumbH = self:getThumbHeight()
    local scrollRange = trackH - thumbH
    if scrollRange <= 0 then return self.arrowH end
    return self.arrowH + math.floor(scrollRange * self.scrollPos)
end

function ZeD_ScrollbarState:setBarSize(ratio)
    self.barSizeRatio = math.max(0.0, math.min(1.0, ratio))
end

function ZeD_ScrollbarState:setScrollPos(pos)
    pos = math.max(0.0, math.min(1.0, pos))
    if pos == self.scrollPos then return end
    self.scrollPos = pos
    if self.onScroll then
        self.onScroll(self.scrollPos)
    end
end

--- Draw the scrollbar onto a parent panel at (self.x, self.y)
function ZeD_ScrollbarState:draw(panel)
    if not self.visible then return end
    local T = ZeD.T
    local A = ZeD.Atoms
    local ox = self.x
    local oy = self.y
    local w = self.width

    -- Clear stale hover states when mouse is outside the scrollbar rect
    if not self.dragging then
        local pmx = panel:getMouseX()
        local pmy = panel:getMouseY()
        local inSB = pmx >= ox and pmx < ox + w
            and pmy >= oy and pmy < oy + self.height
        if not inSB then
            self.thumbHover = false
            self.upHover    = false
            self.downHover  = false
        end
    end

    -- Track — extends from below up arrow to above the reserved bottom (grow box)
    local trackH = self:getTrackHeight()
    A.drawScrollTrack(panel, ox, oy + self.arrowH, w, trackH)

    -- Up arrow
    local upState = self.upPressed and "active" or (self.upHover and "hover" or "default")
    A.drawScrollArrow(panel, ox, oy, self.arrowH, "up", upState)

    -- Down arrow — sits flush against the top of the reserved area (grow box)
    local downY = oy + self.arrowH + trackH
    local downState = self.downPressed and "active" or (self.downHover and "hover" or "default")
    A.drawScrollArrow(panel, ox, downY, self.arrowH, "down", downState)

    -- Thumb
    if self.barSizeRatio < 1.0 then
        local thumbY = self:getThumbY()
        local thumbH = self:getThumbHeight()
        local bg
        if self.dragging then
            bg = T.accent
        elseif self.thumbHover then
            bg = T.accentBright
        else
            bg = T.surf4
        end
        -- Full width thumb — same width as arrow buttons (System 7.1)
        panel:drawRect(ox, oy + thumbY, w, thumbH, bg.a, bg.r, bg.g, bg.b)
        local bc = T.borderS
        panel:drawRectBorder(ox, oy + thumbY, w, thumbH, bc.a, bc.r, bc.g, bc.b)
        -- Grip lines (centered horizontal ridges)
        local gripY = oy + thumbY + math.floor(thumbH / 2) - T.sp.scrollGripOff
        local gripX = ox + T.sp.scrollGripOff
        local gripW = w - T.sp.scrollGripMar
        if gripW > T.px(2) and thumbH > T.px(16) then
            local gc = T.textDim
            for i = 0, 2 do
                panel:drawRect(gripX, gripY + i * T.sp.scrollGripOff, gripW, T.px(1), gc.a, gc.r, gc.g, gc.b)
            end
        end
    end
end

--- Handle mouse down. localY is relative to scrollbar top.
function ZeD_ScrollbarState:handleMouseDown(localY)
    if self.barSizeRatio >= 1.0 then return end

    if localY < self.arrowH then
        self.upPressed = true
        self:setScrollPos(self.scrollPos - 0.05)
        return
    end
    local downTop = self.arrowH + self:getTrackHeight()
    if localY >= downTop and localY < downTop + self.arrowH then
        self.downPressed = true
        self:setScrollPos(self.scrollPos + 0.05)
        return
    end
    local thumbY = self:getThumbY()
    local thumbH = self:getThumbHeight()
    if localY >= thumbY and localY <= thumbY + thumbH then
        self.dragging = true
        self.dragStartY = localY
        self.dragStartPos = self.scrollPos
        return
    end
    if localY < thumbY then
        self:setScrollPos(self.scrollPos - 0.2)
    else
        self:setScrollPos(self.scrollPos + 0.2)
    end
end

function ZeD_ScrollbarState:handleMouseUp()
    self.dragging = false
    self.upPressed = false
    self.downPressed = false
end

--- Handle mouse move. localY is relative to scrollbar top.
function ZeD_ScrollbarState:handleMouseMove(localY)
    self.upHover = localY >= 0 and localY < self.arrowH
    local downTop = self.arrowH + self:getTrackHeight()
    self.downHover = localY >= downTop and localY < downTop + self.arrowH
    local thumbY = self:getThumbY()
    local thumbH = self:getThumbHeight()
    self.thumbHover = localY >= thumbY and localY <= thumbY + thumbH

    if self.dragging then
        local trackH = self:getTrackHeight()
        local scrollRange = trackH - self:getThumbHeight()
        if scrollRange > 0 then
            local delta = (localY - self.dragStartY) / scrollRange
            self:setScrollPos(self.dragStartPos + delta)
        end
    end
end

function ZeD_ScrollbarState:handleMouseWheel(del)
    self:setScrollPos(self.scrollPos + del * 0.05)
end

ZeD.Molecules.ScrollbarState = ZeD_ScrollbarState


-- ============================================================================
-- 08b. DRAG STATE
-- Pure state machine for item drag-and-drop.
-- Same pattern as ZeD_ScrollbarState — caller owns interaction, calls handle*.
-- Bridges to ISMouseDrag so vanilla panes accept our drops.
-- ============================================================================

require "ISUI/ISMouseDrag"

local ZeD_DragState = {}
ZeD_DragState.__index = ZeD_DragState

function ZeD_DragState:new()
    local o = setmetatable({}, self)
    o.active     = false   -- drag in progress (threshold exceeded)
    o.pending    = false   -- mouseDown happened, awaiting threshold
    o.items      = nil     -- flat table of InventoryItem objects
    o.ghostItem  = nil     -- representative item for icon/name
    o.ghostCount = 0       -- count for badge
    o.ghostX     = 0       -- screen-absolute cursor X
    o.ghostY     = 0       -- screen-absolute cursor Y
    o.startX     = 0       -- screen-absolute mouseDown X
    o.startY     = 0       -- screen-absolute mouseDown Y
    o.threshold  = 4       -- px before drag activates (S124 scale: design units, wrapped with T.px in checkThreshold)
    return o
end

function ZeD_DragState:beginPending(items, ghostItem, screenX, screenY)
    self.pending    = true
    self.active     = false
    self.items      = items
    self.ghostItem  = ghostItem
    self.ghostCount = #items
    self.startX     = screenX
    self.startY     = screenY
    self.ghostX     = screenX
    self.ghostY     = screenY
end

function ZeD_DragState:checkThreshold(screenX, screenY)
    local T = ZeD.T
    if not self.pending then return false end
    local dx = math.abs(screenX - self.startX)
    local dy = math.abs(screenY - self.startY)
    if dx >= T.px(self.threshold) or dy >= T.px(self.threshold) then
        self:activate()
        self.ghostX = screenX
        self.ghostY = screenY
        return true
    end
    return false
end

function ZeD_DragState:activate()
    self.pending = false
    self.active  = true
    -- Bridge to vanilla — lets ISInventoryPane.onMouseUp accept our drops
    ISMouseDrag.dragging      = self.items
    ISMouseDrag.draggingFocus = nil
end

function ZeD_DragState:updateGhostPos(screenX, screenY)
    self.ghostX = screenX
    self.ghostY = screenY
end

function ZeD_DragState:drawGhost(panel)
    if not self.active then return end
    local T = ZeD.T
    local item = self.ghostItem
    if not item then return end

    local iconSz = T.px(36)
    local pad    = T.px(5)
    local fontH  = ZeD.TM:MeasureStringY(T.fontF3, "0")
    local gw     = T.px(58)
    local gh     = T.px(48) + fontH + pad

    -- Convert screen coords to panel-local, offset so cursor is top-left
    local lx = self.ghostX - panel:getAbsoluteX() + T.px(12)
    local ly = self.ghostY - panel:getAbsoluteY() - T.px(8)

    -- Background + border
    local bg = T.surf2
    panel:drawRect(lx, ly, gw, gh, 0.85, bg.r, bg.g, bg.b)
    local bc = T.accent
    panel:drawRectBorder(lx, ly, gw, gh, 0.9, bc.r, bc.g, bc.b)

    -- Icon (centered horizontally)
    local tex = item:getTex()
    if tex then
        local ix = lx + math.floor((gw - iconSz) / 2)
        panel:drawTextureScaledAspect(tex, ix, ly + pad, iconSz, iconSz, 0.9, 1, 1, 1)
    end

    -- Weight (right) and quantity (left) below icon
    local ty = ly + pad + iconSz + pad
    local tc = T.textSec
    local wt = string.format("%.1f", item:getUnequippedWeight())
    panel:drawText(wt, lx + gw - pad - ZeD.TM:MeasureStringX(T.fontF3, wt), ty, tc.r, tc.g, tc.b, 0.85, T.fontF3)
    if self.ghostCount > 1 then
        local qty = "x" .. tostring(self.ghostCount)
        panel:drawText(qty, lx + pad, ty, tc.r, tc.g, tc.b, 0.85, T.fontF3)
    end
end

function ZeD_DragState:cancel()
    self.active     = false
    self.pending    = false
    self.items      = nil
    self.ghostItem  = nil
    self.ghostCount = 0
    ISMouseDrag.dragging      = nil
    ISMouseDrag.draggingFocus = nil
end

function ZeD_DragState:complete()
    if not self.active then return nil end
    local items = self.items
    self.active     = false
    self.pending    = false
    self.items      = nil
    self.ghostItem  = nil
    self.ghostCount = 0
    ISMouseDrag.dragging      = nil
    ISMouseDrag.draggingFocus = nil
    return items
end

function ZeD_DragState:isActive()  return self.active  end
function ZeD_DragState:isPending() return self.pending end

ZeD.Molecules.DragState = ZeD_DragState


-- ============================================================================
-- 09. DROPDOWN / SELECT
-- A compact selector that opens a list of options.
-- ============================================================================

ZeD_Dropdown = ISPanel:derive("ZeD_Dropdown")

function ZeD_Dropdown:new(x, y, w, options, selected)
    local T = ZeD.T
    local h = T.inputH
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    -- options is an array of {id=, label=}
    o.options = options or {}
    o.selectedId = selected or (options and options[1] and options[1].id)
    o.isOpen = false
    o.hoveredIndex = -1
    o.scrollOffset = 0       -- scroll offset for overflow lists
    o.maxVisibleItems = nil  -- nil = auto-compute from available space
    o.onChange = nil          -- callback: function(self, selectedId)
    o.disabled = false
    o.background = false
    o.borderEdges = nil
    return o
end

function ZeD_Dropdown:getSelectedLabel()
    for _, opt in ipairs(self.options) do
        if opt.id == self.selectedId then return opt.label end
    end
    return ""
end

function ZeD_Dropdown:prerender()
    local T = ZeD.T
    local alpha = self.disabled and T.disabledAlpha or 1.0

    -- Closed state background
    local bg = T.surf2
    self:drawRect(0, 0, self.width, T.inputH, bg.a * alpha, bg.r, bg.g, bg.b)

    -- Border (respects edge flags)
    ZeD.Atoms.drawBorder(self, 0, 0, self.width, T.inputH, self.borderEdges)
end

function ZeD_Dropdown:render()
    local T = ZeD.T
    local sp = T.sp
    local alpha = self.disabled and T.disabledAlpha or 1.0

    -- Current value label
    local label = self:getSelectedLabel()
    local textY = (T.inputH - ZeD.TM:MeasureStringY(T.fontF2, label)) / 2
    local tc = ZeD.colorAlpha(T.text, alpha)
    self:drawText(label, sp.inputPadX, textY, tc.r, tc.g, tc.b, tc.a, T.fontF2)

    -- Disclosure arrow (geometric)
    local arrowColor = ZeD.colorAlpha(T.textDim, alpha)
    local arrowSz = T.px(5)
    local arrowX = self.width - sp.inputPadX - arrowSz
    local arrowY = (T.inputH - arrowSz) / 2
    ZeD.Atoms.drawTriangleDown(self, arrowX, arrowY, arrowSz, arrowColor)

    -- Open dropdown list
    if self.isOpen then
        local listY = T.inputH
        local rowH = T.rowH

        -- Compute max visible items (clamp to available space)
        local maxVis = self.maxVisibleItems
        if not maxVis then
            local parent = self:getParent()
            if parent then
                local avail = parent:getHeight() - self:getY() - T.inputH
                maxVis = math.max(1, math.floor(avail / rowH))
            else
                maxVis = #self.options
            end
        end
        maxVis = math.min(maxVis, #self.options)

        -- Clamp scroll offset
        local maxScroll = math.max(0, #self.options - maxVis)
        self.scrollOffset = math.max(0, math.min(self.scrollOffset, maxScroll))

        -- Stencil clip the list area
        local listH = maxVis * rowH
        self:setStencilRect(0, listY, self.width, listH)

        -- Solid opaque backdrop — blocks underlying panel content bleeding through semi-transparent row colors
        local base = T.surf1
        self:drawRect(0, listY, self.width, listH, 1.0, base.r, base.g, base.b)

        for i = 1, #self.options do
            local vi = i - self.scrollOffset  -- visible index (1-based)
            if vi >= 1 and vi <= maxVis then
                local opt = self.options[i]
                local ry = listY + (vi - 1) * rowH
                local isSelected = opt.id == self.selectedId
                local isHovered = i == self.hoveredIndex

                -- Row background (drawn over solid backdrop so semi-transparency tints cleanly)
                local bg = isHovered and T.hover or T.surf2
                self:drawRect(0, ry, self.width, rowH, bg.a, bg.r, bg.g, bg.b)

                -- Row border
                self:drawRectBorder(0, ry, self.width, rowH,
                    T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)

                -- Option label
                local optColor = T.text   -- the hover wash marks the row; the words keep their colour
                local optY = ry + (rowH - ZeD.TM:MeasureStringY(T.fontF2, opt.label)) / 2
                self:drawText(opt.label, sp.inputPadX, optY,
                    optColor.r, optColor.g, optColor.b, optColor.a, T.fontF2)

                -- Check mark for selected
                if isSelected then
                    local checkColor = T.accent
                    ZeD.Atoms.drawTextRight(self, "x", self.width - sp.inputPadX, optY, T.fontF1, checkColor)
                end
            end
        end

        self:clearStencilRect()

        -- the list pops up over the window: the 1u frame and System 7's hard shadow
        ZeD.Atoms.frame(self, 0, listY, self.width, listH, T.borderS)
        ZeD.Atoms.drawHardShadow(self, 0, listY, self.width, listH)

        -- Scroll indicator arrows when list overflows
        if #self.options > maxVis then
            local ac = T.textDim
            if self.scrollOffset > 0 then
                ZeD.Atoms.drawTriangleUp(self, self.width - T.px(12), listY + T.px(2), T.px(5), ac)
            end
            if self.scrollOffset < maxScroll then
                ZeD.Atoms.drawTriangleDown(self, self.width - T.px(12), listY + listH - T.px(8), T.px(5), ac)
            end
        end
    end
end

function ZeD_Dropdown:onMouseDown(x, y)
    if self.disabled then return true end

    if self.isOpen then
        -- Check if click is on a list item (account for scroll offset)
        local listY = ZeD.T.inputH
        local rowH = ZeD.T.rowH
        local visIdx = math.floor((y - listY) / rowH) + 1
        local idx = visIdx + self.scrollOffset
        if idx >= 1 and idx <= #self.options then
            self.selectedId = self.options[idx].id
            if self.onChange then self.onChange(self, self.selectedId) end
        end
        self.isOpen = false
        self.scrollOffset = 0
        self:setHeight(ZeD.T.inputH)
    else
        self.isOpen = true
        -- Expand: clamp to available space
        local rowH = ZeD.T.rowH
        local maxVis = self.maxVisibleItems
        if not maxVis then
            local parent = self:getParent()
            if parent then
                local avail = parent:getHeight() - self:getY() - ZeD.T.inputH
                maxVis = math.max(1, math.floor(avail / rowH))
            else
                maxVis = #self.options
            end
        end
        maxVis = math.min(maxVis, #self.options)
        self:setHeight(ZeD.T.inputH + rowH * maxVis)
    end
    return true
end

function ZeD_Dropdown:onMouseMove(dx, dy)
    if self.isOpen then
        local my = self:getMouseY()
        local listY = ZeD.T.inputH
        local rowH = ZeD.T.rowH
        local visIdx = math.floor((my - listY) / rowH) + 1
        self.hoveredIndex = visIdx + self.scrollOffset
        if self.hoveredIndex < 1 or self.hoveredIndex > #self.options then
            self.hoveredIndex = -1
        end
    end
end

function ZeD_Dropdown:onMouseWheel(del)
    if self.isOpen and #self.options > 0 then
        local rowH = ZeD.T.rowH
        local maxVis = self.maxVisibleItems
        if not maxVis then
            local parent = self:getParent()
            if parent then
                local avail = parent:getHeight() - self:getY() - ZeD.T.inputH
                maxVis = math.max(1, math.floor(avail / rowH))
            else
                maxVis = #self.options
            end
        end
        maxVis = math.min(maxVis, #self.options)
        local maxScroll = math.max(0, #self.options - maxVis)
        self.scrollOffset = math.max(0, math.min(self.scrollOffset + del, maxScroll))
        return true
    end
    return false
end

function ZeD_Dropdown:onOtherBodyClick()
    if self.isOpen then
        self.isOpen = false
        self.scrollOffset = 0
        self:setHeight(ZeD.T.inputH)
    end
end

ZeD.Molecules.Dropdown = ZeD_Dropdown


-- ============================================================================
-- 10. COLLAPSIBLE SECTION HEADER (draw helper + state)
-- A clickable row that shows/hides child content.
-- This is a draw helper — the parent organism manages the collapsed state
-- and which children to show/hide.
-- ============================================================================

--- Draw a collapsible section header
-- @param panel      The parent ISPanel
-- @param x, y       Position
-- @param w          Width
-- @param text       Section title
-- @param count      Number of items in this section (shown as "(N)")
-- @param expanded   Is the section currently expanded?
-- @param hovered    Is this header hovered?
-- @param opts       Optional { focus = the ZeD.Focus.mark opts }
-- @return height    Total height of the drawn header
-- The section head (cohesion spec 9): 20u unless heightOverride says otherwise,
-- the triangle atom, F1 in sentence case, the count "(4)" in T.textDim, a content
-- line (T.border) under it. The strip is surface 2 drawn without stacking on the
-- body; hover is the T.hover wash over it.
local SECTION_H = 20   -- design units
function ZeD.Molecules.drawSectionHeader(panel, x, y, w, text, count, expanded, hovered, fontOverride, countInline, bleedLeft, heightOverride, noArrow, opts)
    local T = ZeD.T
    local sp = T.sp
    local h = heightOverride or T.px(SECTION_H)  -- total strip height (bg + line)
    local font = fontOverride or T.fontF1
    local tm = ZeD.TM
    local bleed = bleedLeft or 0
    opts = opts or NO_OPTS
    text = ZeD.Atoms.textCase(text)

    -- Background (slightly elevated) — extends left by bleed to reach panel edge
    ZeD.Atoms.surfaceFill(panel, x - bleed, y, w + bleed, h, "surf2")
    if hovered then
        local hv = T.hover
        panel:drawRect(x - bleed, y, w + bleed, h, hv.a, hv.r, hv.g, hv.b)
    end
    local onFocus = false
    if opts.focus and ZeD.Focus and ZeD.Focus.mark then
        onFocus = ZeD.Focus.mark(panel, x - bleed, y, w + bleed, h, opts.focus)
    end

    -- Bottom content line — same bleed
    ZeD.Atoms.drawDividerH(panel, x - bleed, y + h - T.px(1), w + bleed, false)

    -- Disclosure indicator (geometric) — centered in full header height
    -- Arrow at x (caller owns horizontal inset)
    local discSz = math.max(T.px(8), math.floor(tm:getFontHeight(font) * 0.5))
    local discX = x
    local discY = y + math.floor((h - discSz) / 2)
    if not noArrow then
        local discColor = T.arrow
        if expanded then
            ZeD.Atoms.drawTriangleDown(panel, discX, discY, discSz, discColor)
        else
            ZeD.Atoms.drawTriangleRight(panel, discX, discY, discSz, discColor)
        end
    end
    local textY = y + (h - tm:getFontHeight(font)) / 2

    -- Section title
    local titleX = noArrow and discX or (discX + discSz + T.px(6))
    local tc = onFocus and T.textOnFocus or T.textHead
    panel:drawText(text, titleX, textY, tc.r, tc.g, tc.b, tc.a, font)

    -- Count
    if count then
        local countStr = "(" .. tostring(count) .. ")"
        local dc = onFocus and T.textOnFocus or T.textDim
        if countInline then
            local titleW = tm:MeasureStringX(font, text)
            local countX = titleX + titleW + sp.xs
            panel:drawText(countStr, countX, textY, dc.r, dc.g, dc.b, dc.a, T.fontF1)
        else
            ZeD.Atoms.drawTextRight(panel, countStr, x + w - sp.sm, textY, T.fontF1, dc)
        end
    end

    return h
end

-- ============================================================================
-- 10a. CATEGORY ROW (draw helper)
-- The list's group row, "v Weapons (4)" (cohesion spec 9): 15u, the triangle
-- atom (down when open), F1 in T.toneLo, sentence case, the count in brackets
-- after the name, a content line under it. No fill: it sits on the list.
-- The inventory list, the Equipment groups and Animals move onto it.
-- ============================================================================

local CATEGORY_H = 15   -- design units

--- Draw a category row.
-- @param count     number (or text) shown as "(n)", nil for none
-- @param expanded  the group is open (triangle down) or folded (triangle right)
-- @param opts      Optional { hover, noArrow, bleedLeft, h (px), focus (mark opts), inset (text inset px) }
-- @return height
function ZeD.Molecules.drawCategoryRow(panel, x, y, w, text, count, expanded, opts)
    local T = ZeD.T
    local A = ZeD.Atoms
    opts = opts or NO_OPTS
    local h = opts.h or T.px(CATEGORY_H)
    local bleed = opts.bleedLeft or 0
    local font = T.fontF1
    local tm = ZeD.TM
    if opts.hover then
        local hv = T.hover
        panel:drawRect(x - bleed, y, w + bleed, h, hv.a, hv.r, hv.g, hv.b)
    end
    local onFocus = false
    if opts.focus and ZeD.Focus and ZeD.Focus.mark then
        onFocus = ZeD.Focus.mark(panel, x - bleed, y, w + bleed, h, opts.focus)
    end
    local tc = onFocus and T.textOnFocus or (T.toneLo or T.textDim)
    local cx = x + (opts.inset or T.px(6))
    if not opts.noArrow then
        local tri = math.min(T.px(8), h - T.px(4))
        local ty = y + math.floor((h - tri) / 2)
        if expanded then A.drawTriangleDown(panel, cx, ty, tri, tc)
        else A.drawTriangleRight(panel, cx, ty, tri, tc) end
        cx = cx + tri + T.px(4)
    end
    local s = A.textCase(text)
    if count ~= nil then s = s .. " (" .. tostring(count) .. ")" end
    s = A.truncateText(s, font, x + w - T.px(6) - cx)
    panel:drawText(s, cx, y + math.floor((h - tm:getFontHeight(font)) / 2), tc.r, tc.g, tc.b, tc.a or 1, font)
    A.drawDividerH(panel, x - bleed, y + h - T.hair, w + bleed, false)
    return h
end


-- ============================================================================
-- 10b. TAB DRAWER HEADER (pinned disclosure strip)
-- Standard 37px header for tab drawers. Draws a disclosure arrow + title,
-- bg and line rules extending full window width (edge-to-edge continuity
-- with the inventory header on the other side). Text vertically centered.
--
-- Returns: headerH (constant 37)
-- Caller uses this to position scroll area: scrollY = y + headerH
-- ============================================================================

-- Sourced from ZeD.Spacing.tabHeaderH so the value lives in one place. Read
-- at module load (ZeD.Spacing is the static table defined in Tokens.lua, not
-- the per-theme T.sp which only exists after applyTheme).
local TAB_HEADER_H     = (ZeD.Spacing and ZeD.Spacing.tabHeaderH) or 37  -- S124 scale: these four stay design units; every use wraps T.px
local TAB_HEADER_PAD   = 8    -- outer left/right pad (drawer sides → content edge)
local TAB_HEADER_PAD_T = 8    -- content inset from top of scroll area
local TAB_COL_GAP      = 10   -- gap between figure column and content column in Zone A

--- Draw a pinned tab drawer header and return its height.
-- @param panel     Parent ISPanel
-- @param x, y      Top-left of the tab content area (drawer edge)
-- @param w         Tab content width (drawer width)
-- @param text      Disclosure title (e.g. "Health", "Defense"; sentence case)
-- @param expanded  boolean — disclosure state
-- @param hovered   boolean — mouse over header: the T.hover wash across it
-- @param opts      Optional { focus = the ZeD.Focus.mark opts }
-- @return headerH  constant 37
function ZeD.Molecules.drawTabHeader(panel, x, y, w, text, expanded, hovered, noArrow, opts)
    -- Tab headers (Defense / Health / Thermal / Identity / Skills) inherit
    -- the parent drawer panel's background — same rule as the radio drawer
    -- header. No bg paint here; just disclosure arrow + title + bottom rule
    -- (and the hover wash, the one look of anything that can be pressed).
    local T = ZeD.T
    local pad = T.px(TAB_HEADER_PAD)
    local h   = T.px(TAB_HEADER_H)
    local font = T.fontF4
    local tm  = ZeD.TM
    local fullW = panel:getWidth() - x
    opts = opts or NO_OPTS
    text = ZeD.Atoms.textCase(text)
    if hovered then
        local hv = T.hover
        panel:drawRect(x, y, fullW, h - T.px(1), hv.a, hv.r, hv.g, hv.b)
    end
    local onFocus = false
    if opts.focus and ZeD.Focus and ZeD.Focus.mark then
        onFocus = ZeD.Focus.mark(panel, x, y, fullW, h - T.px(1), opts.focus)
    end

    -- Disclosure arrow centered vertically in the strip.
    local discSz = math.max(T.px(8), math.floor(tm:getFontHeight(font) * 0.5))
    local discX  = x + pad
    local discY  = y + math.floor((h - discSz) / 2)
    if not noArrow then
        local discColor = T.arrow
        if expanded then
            ZeD.Atoms.drawTriangleDown(panel, discX, discY, discSz, discColor)
        else
            ZeD.Atoms.drawTriangleRight(panel, discX, discY, discSz, discColor)
        end
    end

    -- Title text.
    local titleX = noArrow and discX or (discX + discSz + T.px(6))
    local textY  = y + math.floor((h - tm:getFontHeight(font)) / 2)
    local tc     = onFocus and T.textOnFocus or T.textHead
    panel:drawText(text, titleX, textY, tc.r, tc.g, tc.b, tc.a or 1.0, font)

    -- Bottom 1px rule extending edge-to-edge with the inventory column header
    -- on the opposite panel — same divider line, no bg fill.
    ZeD.Atoms.drawDividerH(panel, x, y + h - T.px(1), fullW, true)

    return h
end

--- Return the standard tab header height (for measurement functions).
function ZeD.Molecules.getTabHeaderH()
    return ZeD.T.px(TAB_HEADER_H)  -- S124 scale: the getters return screen px
end

--- Return the standard tab content side padding.
function ZeD.Molecules.getTabPad()
    return ZeD.T.px(TAB_HEADER_PAD)
end

--- Return the standard tab content top padding (below header).
function ZeD.Molecules.getTabPadTop()
    return ZeD.T.px(TAB_HEADER_PAD_T)
end

--- Compute Zone A two-column layout (figure left, stats right).
-- Call once per frame. Returns a table of pixel positions.
-- @param x, y   Top-left of the content area (y should include padTop)
-- @param w      Full tab content width
-- @param figW   Body figure width
-- @param figH   Body figure height
-- @return table { figX, figY, rightX, rightY, rightW, leftW }
function ZeD.Molecules.layoutZoneA(x, y, w, figW, figH)
    local T = ZeD.T
    -- Pass contentW (post-scroll) as w so rightW is correct with or without scrollbar.
    -- Layout: [8px] [220px figure] [10px gap] [rightW] [8px right pad]
    -- With scroll (w=466):    rightW = 466-238-8 = 220
    -- Without scroll (w=480): rightW = 480-238-8 = 234
    local leftX  = x + T.px(TAB_HEADER_PAD)          -- 8px outer left pad
    local leftW  = T.sp.figureW                      -- the figure column: the figure at its whole zoom (Oct 21 2026)
    local rightX = leftX + leftW + T.px(TAB_COL_GAP) -- +10px column gap
    local rightW = w - T.px(TAB_HEADER_PAD) - rightX + x  -- fills to 8px from right edge
    return {
        figX   = leftX + math.floor((leftW - figW) / 2),  -- figure centered in 220px column
        figY   = y,
        leftX  = leftX,
        leftW  = leftW,
        rightX = rightX,
        rightY = y,
        rightW = rightW,
    }
end

-- ============================================================================
-- 11. STAT ROW (draw helper)
-- A horizontal key:value pair for the item card. The workhorse of the
-- About This Macintosh layout — every stat line uses this molecule.
--
-- Label: monospace, sentence case, textSec (chrome voice) — left-aligned
-- Value: sans-serif, T.text or semantic override (content voice) — right-aligned
-- ============================================================================

--- Draw a stat row (key:value pair)
-- @param panel      The parent ISPanel
-- @param x, y       Top-left position of the row
-- @param w          Available width for the row
-- @param label      Label string (drawn in sentence case, chrome voice: ZeD.textCase)
-- @param value      Value string (drawn in content voice)
-- @param valueColor Optional color override for the value (defaults to T.text)
-- @return height    Row height consumed (for stacking the next row below)
function ZeD.Molecules.drawStatRow(panel, x, y, w, label, value, valueColor, labelFont)
    local T = ZeD.T
    local lblFont = labelFont or T.fontF1

    local labelH = ZeD.TM:getFontHeight(lblFont)
    local valueH = ZeD.TM:getFontHeight(T.fontF3)
    local breathe = math.max(T.px(2), math.floor(math.max(labelH, valueH) * 0.15))
    local rowH = math.max(labelH, valueH) + breathe

    local labelY = y + math.floor((rowH - labelH) / 2)
    local valueY = y + math.floor((rowH - valueH) / 2)

    -- Label: sentence case (a caps string from upstream reads in sentence case), secondary color
    local lc = T.textSec
    local caseLabel = ZeD.textCase(label or "")
    local labelW = ZeD.TM:MeasureStringX(lblFont, caseLabel)
    panel:drawText(caseLabel, x, labelY,
        lc.r, lc.g, lc.b, lc.a or 1, lblFont)

    -- Value: K22 Xanthus, right-aligned, truncated with "..." if too wide
    local vc = valueColor or T.text
    local gap = T.px(8) -- minimum gap between label and value
    local maxValueW = w - labelW - gap
    local displayValue = value
    local valueW = ZeD.TM:MeasureStringX(T.fontF3, displayValue)

    if valueW > maxValueW and maxValueW > 0 then
        -- Truncate with ellipsis
        local ellipsis = "..."
        local ellipsisW = ZeD.TM:MeasureStringX(T.fontF3, ellipsis)
        local targetW = maxValueW - ellipsisW
        if targetW > 0 then
            -- Binary search for the right character count
            local len = #displayValue
            while len > 0 and ZeD.TM:MeasureStringX(T.fontF3, string.sub(displayValue, 1, len)) > targetW do
                len = len - 1
            end
            displayValue = string.sub(displayValue, 1, len) .. ellipsis
            valueW = ZeD.TM:MeasureStringX(T.fontF3, displayValue)
        else
            displayValue = ellipsis
            valueW = ellipsisW
        end
    end

    local rightPad = T.sp.sm
    panel:drawText(displayValue, x + w - valueW - rightPad, valueY,
        vc.r, vc.g, vc.b, vc.a or 1, T.fontF3)

    return rowH
end

--- Draw a stat row with a status dot instead of colored value text.
-- The dot carries the semantic color; the value renders in default T.text.
-- @param panel      The parent ISPanel
-- @param x, y       Top-left position of the row
-- @param w          Available width for the row
-- @param label      Label string (sentence case, drawn in chrome voice)
-- @param value      Value string (drawn in content voice, always T.text)
-- @param dotColor   Color table {r, g, b, a} for the status dot
-- @return height    Row height consumed (for stacking the next row below)
function ZeD.Molecules.drawStatRowDot(panel, x, y, w, label, value, dotColor)
    local T = ZeD.T
    local A = ZeD.Atoms
    local dotSz = T.px(6)
    local dotGap = T.px(4)
    local labelH = ZeD.TM:getFontHeight(T.fontF1)
    local valueH = ZeD.TM:getFontHeight(T.fontF3)
    local rowH = math.max(labelH, valueH) + math.max(T.px(2), math.floor(math.max(labelH, valueH) * 0.15))
    local dotY = y + math.floor((rowH - dotSz) / 2)
    A.drawStatusDot(panel, x, dotY, dotColor, dotSz)
    return ZeD.Molecules.drawStatRow(panel, x + dotSz + dotGap, y, w - dotSz - dotGap, label, value)
end



-- ============================================================================
-- 12. FILL BAR (draw helper)
-- A standalone fill bar for the item card's bottom section. Wraps the
-- atom-level drawFillBar with item-card-specific graduated color logic.
--
-- Used in the right column of the bottom section, paired with a stat row
-- in the left column showing the label and percentage.
-- ============================================================================

--- Draw a fill bar with graduated color
-- @param panel   The parent ISPanel
-- @param x, y    Top-left position
-- @param w       Available width for the bar
-- @param ratio   Fill ratio 0.0 to 1.0
-- @return height Bar height consumed (for stacking alignment with stat rows)
function ZeD.Molecules.drawFillBar(panel, x, y, w, ratio, h)
    local T = ZeD.T
    local barH = h or T.fillBarH

    -- Graduated color: green > 60%, amber 30-60%, red < 30%
    ZeD.Atoms.drawFillBar(panel, x, y, w, ratio, true, nil, barH)

    return barH
end


-- ============================================================================
-- 12b. STAT BAR ROW (draw helper)
-- Matches the SkillsTab row pattern exactly: fixed-width value badge on the
-- left, label text after, fill bar as background layer. Same font (fontF1),
-- same row height (secH + 8), no border, no surface fill.
--
-- fillRatio:  0.0 to 1.0 — controls the width of the colored background fill.
-- fillColor:  {r, g, b, a} — the color of the fill bar. Alpha is dimmed
--             automatically (×0.6) so text remains legible.
-- valueColor: optional override for the value text color. Defaults to fillColor.
-- ============================================================================

function ZeD.Molecules.drawStatBarRow(panel, x, y, w, value, label, fillRatio, fillColor, valueColor)
    local T = ZeD.T
    local valFont = T.fontF3
    local lblFont = T.fontF2
    local valH = ZeD.TM:getFontHeight(valFont)
    local lblH = ZeD.TM:getFontHeight(lblFont)
    local rowH = math.max(valH, lblH) + T.px(8)

    fillRatio = math.max(0, math.min(1, fillRatio or 0))

    -- 0. Dark inset background (always darker than surrounding surface)
    local base = T.base
    panel:drawRect(x, y, w, rowH, base.a, base.r, base.g, base.b)

    -- 1. Fill bar (colored overlay on dark base — dimmed to keep white text legible)
    if fillRatio > 0 and fillColor then
        local fillW = math.floor(w * fillRatio)
        if fillW > 0 then
            panel:drawRect(x, y, fillW, rowH,
                (fillColor.a or 1.0) * 0.5, fillColor.r, fillColor.g, fillColor.b)
        end
    end

    -- 2. Value badge (K22 Xanthus — data readout)
    local vc = valueColor or T.toneNorm
    local bg = T.surf3
    local valW = ZeD.TM:MeasureStringX(valFont, value)
    local badgeW = valW + T.px(10)
    panel:drawRect(x, y, badgeW, rowH, T.badgeBgA, bg.r, bg.g, bg.b)
    local valX = x + math.floor((badgeW - valW) / 2)
    local textY = y + math.floor((rowH - valH) / 2)
    panel:drawText(value, valX, textY,
        vc.r, vc.g, vc.b, vc.a, valFont)

    -- 3. Label text (after badge — Lekton, metadata voice)
    local labelX = x + badgeW + T.px(6)
    local tc = T.text
    local lblY = y + math.floor((rowH - lblH) / 2)
    panel:drawText(label, labelX, lblY,
        tc.r, tc.g, tc.b, tc.a, lblFont)

    return rowH
end


-- ============================================================================
-- 13. BODY BACKGROUND (draw helper)
-- Standardized surface fill for panel body areas.
-- One function, one truth — every organism and content panel calls this
-- instead of ad-hoc drawRect or backgroundColor hacks.
--
-- surfaceKey:
--   "surf1" (default) — window body, content areas, panels
--   "surf2"           — title bars, elevated surfaces, context menus
--
-- alphaOverride: optional float to force a specific alpha (e.g. 0.95 for
--   context menus). When nil, uses the token's baked-in alpha.
-- ============================================================================

--- Draw a standardized body background fill.
-- @param panel          The parent ISPanel
-- @param x, y           Top-left of fill area
-- @param w, h           Dimensions of fill area
-- @param surfaceKey     "surf1" or "surf2" (default "surf1")
-- @param alphaOverride  Optional alpha override (nil = use token alpha)
function ZeD.Molecules.drawBodyBg(panel, x, y, w, h, surfaceKey, alphaOverride)
    local T = ZeD.T
    local surf = (surfaceKey == "surf2") and T.surf2 or T.surf1
    local a = alphaOverride or surf.a
    panel:drawRect(x, y, w, h, a, surf.r, surf.g, surf.b)
end

-- ============================================================================
-- M14: WINDOW TITLE BAR — striped bar with title + stat cluster
-- ============================================================================
-- Draws the complete ZeD window title bar: surf2 bg, stripe lines,
-- title text with bg box, right-aligned stat cluster, bottom border.
-- Used by ZeD_Window and ISInventoryPage (CharacterWindow).
--
-- @param panel  ISPanel drawing context
-- @param x, y   Top-left
-- @param w      Full width
-- @param title  Title string (or nil to skip)
-- @param stats  Array of {text=, color=, noMark=} drawn right-to-left (or nil):
--               each a 6u status square in `color` then its words; noMark = words
--               only (the older way, a colour with alpha 0, still keeps the room)
-- @param opts   Optional { rightReserve = px kept clear at the right end (the
--               window box) }
-- ============================================================================

function ZeD.Molecules.drawWindowTitleBar(panel, x, y, w, title, stats, opts)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local tbH = T.titleBarH
    opts = opts or NO_OPTS

    -- Background (the window's own top surface: its see-through is the window's)
    M.drawBodyBg(panel, x, y, w, tbH, "surf2")

    -- Stripe lines
    local stripeA = T.stripe.a
    if stripeA > 0 then
        for sy = y + T.px(2), y + tbH - T.px(2), T.px(4) do
            panel:drawRect(x, sy, w, T.px(1), stripeA, T.stripe.r, T.stripe.g, T.stripe.b)
        end
    end

    -- Bottom border
    panel:drawRect(x, y + tbH - T.px(1), w, T.px(1), T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)

    -- Title text with background box (K22 Xanthus — chrome voice)
    if title and title ~= "" then
        local titleFont = T.fontF3
        local titleX = x + T.sp.sm + T.closeBoxSz + T.sp.md
        local titleY = y + math.floor((tbH - ZeD.TM:getFontHeight(titleFont)) / 2)
        local tbp = T.sp.titleBoxPad
        -- Truncate title to available width (leave room for stat cluster)
        local maxTitleW = w - (titleX - x) - T.sp.sm - tbp * 2
        local displayTitle = A.truncateText(title, titleFont, maxTitleW)
        local titleW = ZeD.TM:MeasureStringX(titleFont, displayTitle)
        M.drawBodyBg(panel, titleX - tbp, y + T.px(1), titleW + tbp * 2, tbH - tbp, "surf2")
        panel:drawText(displayTitle, titleX, titleY, T.textHead.r, T.textHead.g, T.textHead.b, T.textHead.a, titleFont)
    end

    -- Right-aligned stat cluster (truncated to available chrome width)
    if stats and #stats > 0 then
        local statX = x + w - T.sp.sm - (opts.rightReserve or 0)
        local statFH = ZeD.TM:getFontHeight(T.fontF3)
        local statY = y + math.floor((tbH - statFH) / 2)
        local dotSz = T.px(6)   -- the one status square (cohesion spec 1.2)
        local dotGap = T.px(4)
        local tc = T.text
        -- Left boundary: don't overlap title text (reuses titleFont from above)
        local titleEndW = title and ZeD.TM:MeasureStringX(T.fontF3, title) or 0
        local minX = x + T.sp.sm + T.closeBoxSz + T.sp.md + titleEndW + T.sp.titleBoxPad * 2 + T.sp.md
        for i = #stats, 1, -1 do
            local stat = stats[i]
            local sw = ZeD.TM:MeasureStringX(T.fontF3, stat.text)
            local markW = stat.noMark and 0 or (dotGap + dotSz)
            local needed = sw + markW + T.sp.md
            -- Skip this stat if it would overflow past the title
            if statX - needed < minX then break end
            statX = statX - sw
            panel:drawText(stat.text, statX, statY, tc.r, tc.g, tc.b, tc.a or 1, T.fontF3)
            -- Status square before the words
            if not stat.noMark then
                local dc = stat.color or T.textDim
                statX = statX - dotGap - dotSz
                if (dc.a or 1) > 0 then
                    A.drawStatusDot(panel, statX, y + math.floor((tbH - dotSz) / 2), dc, dotSz)
                end
            end
            statX = statX - T.sp.md
        end
    end
end

-- ============================================================================
-- M15: DATA ROW — dim label + bright value on one line
-- ============================================================================
-- Draws a label (fontF4, dimmed) + value (fontF2, full alpha) pair.
-- Used by LootContextPanel for FUEL, TIME, ITEMS, WATER readouts.
--
-- @param panel      ISPanel drawing context
-- @param label      Label text (e.g. "FUEL")
-- @param value      Value text (e.g. "47%") — or nil to draw label only
-- @param x, y       Top-left position
-- @param labelColor Optional override for label color
-- @param valueColor Optional override for value color
-- @return height    Total row height (for layout stacking)
-- ============================================================================

function ZeD.Molecules.drawDataRow(panel, label, value, x, y, labelColor, valueColor)
    local T = ZeD.T
    local lc = labelColor or ZeD.colorAlpha(T.textHead, 0.6)
    local vc = valueColor or T.text
    local fh = ZeD.TM:getFontHeight(T.fontF4)

    panel:drawText(label, x, y, lc.r, lc.g, lc.b, lc.a or 0.6, T.fontF4)

    if value then
        local lw = ZeD.TM:MeasureStringX(T.fontF4, label)
        panel:drawText(value, x + lw + T.sp.sm, y, vc.r, vc.g, vc.b, vc.a or 1, T.fontF2)
    end

    return fh
end

-- ============================================================================
-- M16: ACTION STRIP — reusable row of icon toggle/action buttons
-- ============================================================================
-- Renders a horizontal strip of icon buttons. Each def in the array is:
-- Icon padding inside rounded button — 20% of button size, min 4px
local function _iconPad(btnSz)
    local T = ZeD.T
    return math.max(T.px(4), math.floor(btnSz * 0.2))
end

--   {key, tex, colorKey, tip_on, tip_off}
-- Returns a table of hit rects in absolute coords for use with updateActionStrip.
--
-- @param panel      The ISPanel to draw on
-- @param x, y       Top-left of the first button (local coords)
-- @param defs       Array of action definitions (e.g. ZeD.ActionStrip.TOGGLE_DEFS)
-- @param item       The InventoryItem for state queries
-- @param hoverIdx   Index of currently hovered button (nil = none)
-- @return rects     Array of {x, y, w, h} in absolute coords
local _stripOpts = {}
function ZeD.Molecules.drawActionStrip(panel, x, y, defs, item, hoverIdx)
    local T = ZeD.T
    local A = ZeD.Atoms
    local AS = ZeD.ActionStrip
    local sp = T.sp
    local btnSz = T.iconSm + T.px(4)
    local gap = sp.xs
    local absX = panel:getAbsoluteX()
    local absY = panel:getAbsoluteY()
    local rects = {}

    for i, def in ipairs(defs) do
        local bx = x + (i - 1) * (btnSz + gap)
        local isOn = AS.getState(item, def.key)
        -- an icon toggle: solid accent when on, the hover wash, its name as the hint
        local o = _stripOpts
        o.active, o.hover, o.id = isOn, (hoverIdx == i), def.key
        o.hint = ZeD.tr(isOn and def.tip_on or def.tip_off)
        ZeD.Molecules.drawIconButton(panel, bx, y, btnSz, def.tex, o)

        rects[i] = {x = absX + bx, y = absY + y, w = btnSz, h = btnSz}
    end

    return rects
end

--- Process mouse interaction for an action strip.
-- Call from update(). Returns updated hover index and wasDown state.
-- @param rects      Hit rects from drawActionStrip (absolute coords)
-- @param defs       Same defs array passed to drawActionStrip
-- @param item       The InventoryItem
-- @param hoverIdx   Previous hover index
-- @param wasDown    Previous wasDown state
-- @return newHover, newWasDown
function ZeD.Molecules.updateActionStrip(rects, defs, item, hoverIdx, wasDown, playerNum)
    local mx = getMouseX()
    local my = getMouseY()
    local down = isMouseButtonDown(0)

    local newHover = nil
    for i, rect in ipairs(rects) do
        if mx >= rect.x and mx < rect.x + rect.w and my >= rect.y and my < rect.y + rect.h then
            newHover = i
            break
        end
    end

    -- Click-on-release
    if wasDown and not down and newHover then
        local def = defs[newHover]
        local cur = ZeD.ActionStrip.getState(item, def.key, playerNum)
        ZeD.ActionStrip.setState(item, def.key, not cur, playerNum)
    end

    return newHover, (down and newHover ~= nil)
end


-- ============================================================================
-- M15: DOCK — button with flag
-- A rounded action button with a flat flag label attached to its left edge.
-- The flag spans only the button's straight section (excluding bevel rows).
-- Flag: background color + text, no outline. Button: standard rounded.
--
-- When icon is nil: flag-only mode (no button).
--
-- @param panel     ISPanel
-- @param x, y      Top-left (local coords)
-- @param totalW    (unused, kept for signature compat)
-- @param label     Flag text (e.g. "TORN", "23%")
-- @param fillSegs  (unused, kept for signature compat)
-- @param tint      {r,g,b,a} — flag bg + label color
-- @param icon      Texture for button (nil = flag-only)
-- @param hovered   bool — highlight button
-- @param greyed    bool — dim entire dock to 0.45 opacity
-- @return width    Total width consumed
-- ============================================================================
local function dockLabelColor(T, tint)
    -- the flag's wash keeps the plain colour; its words use the text variant of the same hue
    if not tint or tint == T.textSec then return T.text end
    if tint == T.soiledWet then return T.soiledWetText end
    if tint == T.soiledBlood then return T.soiledBloodText end
    if tint == T.soiledDirt then return T.soiledDirtText end
    if tint == T.danger then return T.dangerText end
    if tint == T.warning then return T.warningText end
    if tint == T.positive then return T.positiveText end
    if tint == T.info then return T.infoText end
    return tint
end

local _dockOpts = {}
function ZeD.Molecules.drawDock(panel, x, y, totalW, label, fillSegs, tint, icon, hovered, greyed)
    local T   = ZeD.T
    local A   = ZeD.Atoms
    local btnSz    = T.iconSm + T.px(4)
    local bevel    = T.px(2)  -- matches ROUND_RADIUS = {2, 1}
    local dim      = greyed and 0.45 or 1.0

    -- Flag dimensions: height = button's straight section
    local flagH = btnSz - bevel * 2
    local flagY = y + bevel
    local padX  = T.px(4)
    local textW = 0
    if label and label ~= "" then
        textW = ZeD.TM:MeasureStringX(T.fontF1, label)
    end
    local flagW = math.max(T.px(4), textW + padX * 2)

    -- Flag background: tint color, no outline
    local bgC = tint or T.textSec
    panel:drawRect(x, flagY, flagW, flagH, 0.20 * dim, bgC.r, bgC.g, bgC.b)

    -- Flag label: centered vertically in flag
    if label and label ~= "" then
        local fontH = ZeD.TM:getFontHeight(T.fontF1)
        local ly    = flagY + math.floor((flagH - fontH) / 2)
        local lc    = dockLabelColor(T, tint)
        panel:drawText(label, x + padX, ly, lc.r, lc.g, lc.b, (lc.a or 1) * dim, T.fontF1)
    end

    if icon then
        -- Button: the icon button look (single rounded outline, hover wash), flush
        -- right of the flag, at the size the dock always had
        local o = _dockOpts
        o.hover, o.disabled = hovered and not greyed, greyed and true or false
        o.iconSize = btnSz - _iconPad(btnSz) * 2
        o.tint = (not greyed and tint) and tint or nil
        ZeD.Molecules.drawIconButton(panel, x + flagW, y, btnSz, icon, o)

        return flagW + btnSz
    else
        -- Flag-only: no button
        return flagW
    end
end


-- ============================================================================
-- M16: ZONE ROW — one body-part zone, two lines
-- ============================================================================
-- Data-driven draw helper for ZeD_ZoneList (O09) and any future organism
-- that needs per-zone condition readout (vehicle parts, body health, etc.).
--
-- Line 1 (top):  ZONE NAME   Pct%  |  fill bar + structural dock
-- Line 2 (bot):  blood%  dirt%  wet%  (soiled flags, flag-only, left-aligned)
--
-- @param panel  ISPanel to draw on
-- @param x, y   Top-left of the row (local coords, already offset for scroll)
-- @param w      Available width
-- @param zone   Config table:
--   {
--     name    string          zone label (drawn as given)
--     pct     0..100          condition percentage
--     bar     bool            draw fill bar on top line right col
--     dock    table|nil       structural dock config (nil = no dock)
--       .flag   string        flag label text
--       .color  {r,g,b,a}     flag + button tint
--       .icon   texture|nil   already-resolved texture (not a key)
--       .state  "active"|"grey"
--     soiled  table|nil       nil = clean
--       .blood  0..100|nil
--       .dirt   0..100|nil
--       .wet    0..100|nil
--   }
-- @return height  Total pixel height consumed (for cursor advance in caller)
-- ============================================================================
-- @param outDockRect  optional table; if passed, the structural dock BUTTON rect
--                     (panel-local coords, button portion only — flag is non-
--                     interactive) is written to .x/.y/.w/.h. Caller decides
--                     whether to register it as a click target / focusable
--                     based on dock state and material availability.
function ZeD.Molecules.drawZoneRow(panel, x, y, w, zone, hovered, outDockRect)
    local T     = ZeD.T
    local A     = ZeD.Atoms
    local M     = ZeD.Molecules
    local sp    = T.sp
    local bodyH = ZeD.TM:getFontHeight(T.fontF2)
    local btnSz = T.iconSm + T.px(4)
    local barH  = T.fillBarH

    -- Top-line height: tallest of text+breathing, bar, dock
    local topH = math.max(bodyH + T.px(4), barH + T.px(4), btnSz)

    -- Two-column split mirrors the card's layout
    local colW   = math.floor((w - T.colGap) / 2)
    local leftX  = x
    local rightX = x + colW + T.colGap

    -- ---- TOP LINE ----
    local textY = y + math.floor((topH - bodyH) / 2)

    -- Zone name — left col, left edge (400wt Title Case)
    local nameStr = zone.name or ""
    panel:drawText(nameStr, leftX, textY,
        T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)

    -- Pct — left col, right-aligned (K22 Xanthus — data readout)
    local pctStr = tostring(math.floor(zone.pct or 0)) .. "%"
    local pctW   = ZeD.TM:MeasureStringX(T.fontF3, pctStr)
    local pctY   = y + math.floor((topH - ZeD.TM:getFontHeight(T.fontF3)) / 2)
    panel:drawText(pctStr, leftX + colW - pctW, pctY,
        T.text.r, T.text.g, T.text.b, T.text.a, T.fontF3)

    -- Right col: fill bar spans full width — dock lives on bottom line only
    if zone.bar then
        local barY  = y + math.floor((topH - barH) / 2)
        local ratio = math.max(0, math.min(1, (zone.pct or 0) / 100))
        A.drawFillBar(panel, rightX, barY, colW, ratio, true)
    end

    local totalH = topH

    -- ---- BOTTOM LINE: soiled docks + structural dock, right-to-left from right edge ----
    -- Layout (right edge → left): [structural dock] [wet] [blood] [dirty]
    -- All docks have buttons. Right edge is x + w.
    local soiled = zone.soiled
    local hasDock = zone.dock ~= nil
    local hasSoiled = soiled and (
        (soiled.blood and soiled.blood > 0) or
        (soiled.dirt) or
        (soiled.wet   and soiled.wet   > 0)
    )
    if hasDock or hasSoiled then
        local botY  = y + topH
        local botH  = btnSz
        local rx    = x + w   -- right cursor, grows leftward

        -- Structural dock (rightmost)
        if hasDock then
            local d     = zone.dock
            local greyd = (d.state == "grey")
            -- Pre-measure width
            local sTextW = d.flag and ZeD.TM:MeasureStringX(T.fontF1, d.flag) or 0
            local flagW  = math.max(T.px(4), sTextW + T.px(4) * 2)  -- S124 scale: + 2 x drawDock padX, so the pre-measure matches drawDock
            local dockW  = d.icon and (flagW + btnSz) or flagW
            rx = rx - dockW
            M.drawDock(panel, rx, botY, nil, d.flag, nil, d.color, d.icon, hovered and not greyd, greyd)
            -- Expose button-portion rect for hit testing (caller filters on state)
            if outDockRect and d.icon then
                outDockRect.x = rx + flagW
                outDockRect.y = botY
                outDockRect.w = btnSz
                outDockRect.h = btnSz
            end
            rx = rx - sp.xs
        end

        -- Wet (blue) — flag only, no button
        if soiled and soiled.wet and soiled.wet > 0 then
            local lbl    = math.floor(soiled.wet) .. "%"
            local sTextW = ZeD.TM:MeasureStringX(T.fontF1, lbl)
            local flagW  = math.max(T.px(4), sTextW + T.px(4) * 2)
            rx = rx - flagW
            M.drawDock(panel, rx, botY, nil, lbl, nil, T.soiledWet, nil, false, false)
            rx = rx - sp.xs
        end

        -- Blood (red) — flag only, no button
        if soiled and soiled.blood and soiled.blood > 0 then
            local lbl    = math.floor(soiled.blood) .. "%"
            local sTextW = ZeD.TM:MeasureStringX(T.fontF1, lbl)
            local flagW  = math.max(T.px(4), sTextW + T.px(4) * 2)
            rx = rx - flagW
            M.drawDock(panel, rx, botY, nil, lbl, nil, T.soiledBlood, nil, false, false)
            rx = rx - sp.xs
        end

        -- Dirty (brown) — flag only, no button
        if soiled and soiled.dirt then
            local lbl    = ZeD.textCase(ZeD.tr("Tooltip_clothing_dirty"))
            local sTextW = ZeD.TM:MeasureStringX(T.fontF1, lbl)
            local flagW  = math.max(T.px(4), sTextW + T.px(4) * 2)
            rx = rx - flagW
            M.drawDock(panel, rx, botY, nil, lbl, nil, T.soiledDirt, nil, false, false)
        end

        totalH = topH + botH
    end

    return totalH
end

-- ============================================================================
-- ITEM CARD UNIVERSAL MOLECULES (S120 — Phase 2)
-- The four chrome strips that compose every item card regardless of item type:
--   drawCardBackBar      header strip with back btn, name, primary+sec verbs
--   drawCardFlagStrip    "MARKED" + 3 flag chips (fav/nocraft/dispose)
--   drawCardProgressBand observer wrapper around Atoms.drawProgressBand
--   drawCardVerbStrip    right-aligned text-label verb buttons
-- All accept compact:bool to switch between 220w (browsing) and 480w (detail)
-- presets locked in S119 mockups v13/v15. Verbs grey out under progressActive
-- so the Progress Band's [x] becomes the only cancel surface (locked rule).
-- Back keys and verbs are the library's icon and push buttons.
-- ============================================================================

-- T2.1 CARD BACK-BAR ---------------------------------------------------------
--- Draw the card's header strip: back key + name + verb cluster.
--- The back key is the icon button with a left triangle (the same on every card
--- and drawer); the verbs are push buttons (cohesion spec 7: keys only on the
--- hardware), the primary one accent, a danger one red.
--- @param panel ISPanel
--- @param x, y  Top-left
--- @param w     Total width
--- @param name  Item display name (ellipsis-truncated if too wide)
--- @param verbs Array of {label, primary, disabled?, danger?, hover?, focus?, help?} — drawn right-to-left.
---              `disabled=true` greys that verb (Vehicle tab: needs unmet);
---              `danger=true` = the danger push button (red, the slow pulse);
---              hover = the caller's hover state (nil: the pointer is tested here);
---              focus = the ZeD.Focus.mark opts when the verb has the controller's focus.
--- @param progressActive  When true, the verbs are disabled (the Progress Band's [x]
---                        is then the only cancel surface)
--- @param compact         220w preset (h=30, list-row button height); else 480w (h=37, T.buttonH)
--- @param outRects        Optional table; on return:
---                          outRects.back = {x,y,w,h}
---                          outRects.verbs[i] = {x,y,w,h}
--- @param opts            Optional { focusId = "back" (with focus = its mark opts) or
---                          focusParts = { back = mark opts }: the back key has the
---                          controller's focus (the mark goes under its triangle);
---                          backHelp = its help line words (default "Back: close this
---                          card"); backHover (nil: the pointer is tested here); win }
--- @return height
local _bbOpts, _bbBack = {}, {}
function ZeD.Molecules.drawCardBackBar(panel, x, y, w, name, verbs, progressActive, compact, outRects, opts)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules

    local h, btnH, padX, gap, btnPadX
    if compact then
        h, btnH, padX, gap, btnPadX = T.px(30), T.buttonH - T.px(4), T.px(4), T.px(4), T.px(8)
    else
        h, btnH, padX, gap, btnPadX = T.px(37), T.buttonH, T.px(6), T.px(6), T.px(10)
    end
    local btnY = y + math.floor((h - btnH) / 2)

    -- Surface + bottom structure line
    A.surfaceFill(panel, x, y, w, h, "surf2")
    A.drawDividerH(panel, x, y + h - T.hair, w, true)

    -- Back key: its hover, its help line words and, when it has the controller, the mark under it
    opts = opts or NO_OPTS
    local backX = x + padX
    if opts.backHover ~= nil then _bbBack.hover = opts.backHover
    else _bbBack.hover = A.mouseIn(panel, backX, btnY, btnH, btnH) end
    _bbBack.focus = partFocus(opts, "back")
    _bbBack.help = opts.backHelp or ZeD.tr("UI_ZeD_Card_HelpBack")
    _bbBack.win = opts.win
    M.drawBackButton(panel, backX, btnY, btnH, _bbBack)

    if outRects then
        outRects.back  = {x = backX, y = btnY, w = btnH, h = btnH}
        outRects.verbs = outRects.verbs or {}
    end

    -- Verb cluster — right-aligned, drawn right-to-left
    local cursorR = x + w - padX
    local font = T.fontF3
    if verbs and #verbs > 0 then
        for i = #verbs, 1, -1 do
            local v = verbs[i]
            if i < #verbs then cursorR = cursorR - gap end
            local labelStr = ZeD.btnCase(v.label or "")   -- sentence case (draw only: ItemCard dispatches on the caps label)
            local btnW = ZeD.TM:MeasureStringX(font, labelStr) + btnPadX * 2
            cursorR    = cursorR - btnW
            local btnX = cursorR
            local o = _bbOpts
            o.disabled = (progressActive or v.disabled) and true or false
            if v.hover ~= nil then o.hover = v.hover else o.hover = A.mouseIn(panel, btnX, btnY, btnW, btnH) end
            o.focus, o.help, o.win = v.focus, v.help, opts.win
            local variant = v.primary and "primary" or (v.danger and "danger" or "default")
            M.drawButton(panel, btnX, btnY, btnW, btnH, labelStr, variant, false, nil, o)
            if outRects then
                outRects.verbs[i] = {x = btnX, y = btnY, w = btnW, h = btnH}
            end
        end
    end

    -- Item name — between back key and verb cluster, ellipsis-truncated
    local nameX = backX + btnH + gap
    local nameW = cursorR - gap - nameX
    if nameW > 0 and name and name ~= "" then
        local nameFont = compact and T.fontF1 or T.fontF4
        local nameStr  = name
        if ZeD.TM:MeasureStringX(nameFont, nameStr) > nameW then
            nameStr = A.truncateText(nameStr, nameFont, nameW)
        end
        local nameH = ZeD.TM:getFontHeight(nameFont)
        local nameY = y + math.floor((h - nameH) / 2)
        local nc    = T.text
        panel:drawText(nameStr, nameX, nameY, nc.r, nc.g, nc.b, nc.a, nameFont)
    end

    return h
end

-- T2.2 CARD FLAG STRIP -------------------------------------------------------
--- Draw the "Marked" label + three flag chips (fav, nocraft, dispose): each its
--- pixel icon (star, the craft tools struck through, the bin) and its word; the
--- narrow card's chips the icon alone.
--- Per-chip on/off read from marks. No fill of its own (the card's surface is
--- under it, one layer); a content line closes it.
--- @param panel    ISPanel
--- @param x, y     Top-left
--- @param w        Total width
--- @param marks    Table {fav=bool, nocraft=bool, dispose=bool}
--- @param compact  220w icon-only chips; else 480w padded label chips
--- @param outRects Optional table; on return: outRects.fav/nocraft/dispose = hit rect
--- @param opts     Optional { focusId = "fav" / "nocraft" / "dispose" (with focus = its mark
---                 opts) or focusParts = { fav = mark opts, ... }: the chip with the
---                 controller's focus (the mark goes under its words); hover = { fav = bool,
---                 ... } (a chip left out: the pointer is tested here); win }
--- @return height
local FLAG_CHIPS = {
    { kind = "fav",     glyph = "*", key = "UI_ZeD_Card_ChipFav" },
    { kind = "nocraft", glyph = "o", key = "UI_ZeD_Card_ChipNoCraft" },
    { kind = "dispose", glyph = "x", key = "UI_ZeD_Card_ChipDispose" },
}
local _chipOpts = {}
function ZeD.Molecules.drawCardFlagStrip(panel, x, y, w, marks, compact, outRects, opts)
    local T = ZeD.T
    local A = ZeD.Atoms
    opts = opts or NO_OPTS

    local h, padX, gap, lblPadR
    if compact then
        h, padX, gap, lblPadR = T.px(24), T.px(8), T.px(4), T.px(2)
    else
        h, padX, gap, lblPadR = T.px(28), T.px(12), T.px(6), T.px(4)
    end

    -- The content line under it (no fill: the card's own surface is the one layer)
    local lt = T.line(T.borderW)
    A.drawDividerH(panel, x, y + h - lt, w, false)

    local font   = T.fontF1
    local labelH = T.fontF1H or ZeD.TM:MeasureStringY(font, "M")
    local chipH  = T.px(A.FLAG_CHIP_H)
    local rowY   = y + math.floor((h - chipH) / 2)

    -- "Marked" label (left, dim)
    local lblText  = A.textCase(ZeD.tr("UI_ZeD_Card_Marked"))
    local labelTY  = y + math.floor((h - labelH) / 2)
    local labelC   = T.textDim
    panel:drawText(lblText, x + padX, labelTY,
        labelC.r, labelC.g, labelC.b, labelC.a, font)
    local lblW = ZeD.TM:MeasureStringX(font, lblText)

    -- Three chips — composes Atoms.drawFlagChip ×3, each with its hover and focus
    local cursorX = x + padX + lblW + lblPadR
    local hov = opts.hover
    for _, c in ipairs(FLAG_CHIPS) do
        local k = c.kind
        local label = ZeD.tr(c.key)
        local cw = A.flagChipW(label, compact)
        local o = _chipOpts
        if hov and hov[k] ~= nil then o.hover = hov[k]
        else o.hover = A.mouseIn(panel, cursorX, rowY, cw, chipH) end
        o.focus = partFocus(opts, k)
        if outRects then outRects[k] = outRects[k] or {} end
        cw = A.drawFlagChip(panel, cursorX, rowY, k, marks and marks[k] or false, c.glyph, label,
            outRects and outRects[k] or nil, compact, o)
        cursorX = cursorX + cw + gap
    end

    -- The fourth mark (Oct 29 2026, loadouts B3): Lists, lit in the accent when the item
    -- is on any loadout or outfit (marks.lists; nil: no button), its words after it
    -- (marks.listsText, "in 1 loadout", in T.textDim while there is room: the lit icon is the status)
    if marks and marks.lists ~= nil then
        local label = ZeD.tr("UI_ZeD_Lists_Lists")
        local cw = A.flagChipW(label, compact)
        local o = _chipOpts
        if hov and hov.lists ~= nil then o.hover = hov.lists
        else o.hover = A.mouseIn(panel, cursorX, rowY, cw, chipH) end
        o.focus = partFocus(opts, "lists")
        if outRects then outRects.lists = outRects.lists or {} end
        cw = A.drawFlagChip(panel, cursorX, rowY, "lists", marks.lists and true or false, nil, label,
            outRects and outRects.lists or nil, compact, o)
        if o.hover and marks.listsHint and ZeD.Help and ZeD.Help.set then ZeD.Help.set(opts.win or panel, marks.listsHint) end
        cursorX = cursorX + cw + gap
        local s = marks.listsText
        if s and s ~= "" then
            local room = x + w - padX - cursorX
            if ZeD.TM:MeasureStringX(font, s) <= room then
                local dc = T.textDim
                panel:drawText(s, cursorX, labelTY, dc.r, dc.g, dc.b, dc.a or 1, font)
            end
        end
    end

    return h
end

-- T2.3 CARD PROGRESS BAND (observer wrapper) ---------------------------------
--- Wrapper around Atoms.drawProgressBand. Reads observer state from
--- ZeD.ItemActionManager — registered-observer pattern, NOT Events.OnTick.
--- Idle items pay zero per-frame cost (manager returns nil → no draw).
--- @param panel ISPanel
--- @param x, y  Top-left
--- @param w     Total width
--- @param item  PZ inventory item — looked up via ItemActionManager
--- @param compact bool
--- @param outRect Optional cancel-button hit rect (forwarded from atom)
--- @param opts    Optional, passed on to the band: { focus (Cancel's mark opts), hover, help, win }
--- @return height (0 when idle / no manager / no item)
function ZeD.Molecules.drawCardProgressBand(panel, x, y, w, item, compact, outRect, opts)
    local mgr = ZeD.ItemActionManager
    if not mgr or not item then return 0 end
    local action = mgr.getActiveAction(item)
    if not action then return 0 end
    return ZeD.Atoms.drawProgressBand(panel, x, y, w,
        action.mode    or "active",
        action.label   or "",
        action.percent or 0,
        action.timeStr,
        outRect, compact, opts)
end

-- T2.4 CARD VERB STRIP -------------------------------------------------------
--- Right-aligned row of verb push buttons at the list-row height
--- (T.buttonH - T.px(4)). Empty list → no render at all (books have no
--- maintenance verbs).
--- @param panel        ISPanel
--- @param rightEdge    Right boundary x (panel-local) — buttons grow left
--- @param y            Top y
--- @param verbs        Array of {label, glyph?, disabled?, hover?, focus?, help?}; nil/empty → no render
---                     (glyph is no longer drawn: push buttons carry words only)
--- @param progressActive  When true, all buttons are disabled
--- @param compact      220w: tighter gaps
--- @param outRects     Optional array of per-verb hit rects
--- @return result      {h = height, leftEdge = leftmost x consumed}
local _vsOpts = {}
function ZeD.Molecules.drawCardVerbStrip(panel, rightEdge, y, verbs, progressActive, compact, outRects)
    if not verbs or #verbs == 0 then
        return {h = 0, leftEdge = rightEdge}
    end
    local T        = ZeD.T
    local A        = ZeD.Atoms
    local font     = T.fontF3
    local btnH     = T.buttonH - T.px(4)
    local padX     = T.px(10)
    local gap      = compact and T.px(4) or T.px(6)

    local cursorR = rightEdge
    for i = #verbs, 1, -1 do
        local v = verbs[i]
        if i < #verbs then cursorR = cursorR - gap end
        local labelStr = ZeD.btnCase(v.label or "")   -- sentence case, never all caps
        local btnW     = ZeD.TM:MeasureStringX(font, labelStr) + padX * 2
        cursorR        = cursorR - btnW
        local bx       = cursorR
        local o = _vsOpts
        o.disabled = (progressActive or v.disabled) and true or false
        if v.hover ~= nil then o.hover = v.hover else o.hover = A.mouseIn(panel, bx, y, btnW, btnH) end
        o.focus, o.help = v.focus, v.help
        ZeD.Molecules.drawButton(panel, bx, y, btnW, btnH, labelStr, "default", false, nil, o)
        if outRects then
            outRects[i] = {x = bx, y = y, w = btnW, h = btnH}
        end
    end

    return {h = btnH, leftEdge = cursorR}
end

-- ============================================================================
-- ITEM CARD CONTENT MOLECULES (S120 — Phase 3)
-- Top-of-body composables that sit below the FlagStrip:
--   drawCardStatRow    — single key:value row (mono accent label + sans value)
--   drawTopStatsList   — 220w single-column stat list (fixed 80px label column)
--   drawTopStatsGrid   — 480w 2-column stat grid with 56px item icon left
-- Plus the Facts panel primitives (composed by Phase 4 panels):
--   drawFactsTitle     — "Defense Facts" / "Nutrition Facts" heading
--   drawFactsRuleThick — 2px text-color rule (above first row)
--   drawFactsRuleThin  — 1px border-color rule (between sub-blocks)
--   drawFactsRow       — label/value row, optional sub-indent + value class
--
-- Distinct from existing M11 drawStatRow: v13/v15 mockup uses Fira Sans for
-- values (T.fontF2) instead of Fira Mono (T.fontF3), and the mono label is
-- full-opacity T.accent rather than 50%-α toneLo. Sibling function avoids
-- breaking S118 callers that depend on the established voice.
-- ============================================================================

-- Internal helpers: a value class ("warn"/"bad"/"dim"/"good"/nil) is drawn as default
-- words and a 6u status square in the class's colour (cohesion spec: status as a
-- square, no coloured words). "dim" is not a status: dim words, no square.
local function _resolveStatValColor(valueClass, T)
    if valueClass == "dim" then return T.textDim end
    return T.text
end
local function _statClassMark(valueClass, T)
    if     valueClass == "warn" then return T.warning
    elseif valueClass == "bad"  then return T.danger
    elseif valueClass == "good" then return T.positive
    end
    return nil
end

-- T3.x  CARD STAT ROW --------------------------------------------------------
--- Draw a single key:value stat row in v13 voice (mono accent label + sans value).
--- Matches the .stat-line-{220,480} CSS in mockups v13/v15.
--- @param panel ISPanel
--- @param x, y  Top-left
--- @param w     Available width
--- @param label String — drawn in sentence case (ZeD.textCase)
--- @param value String value — default words ("dim": dim words)
--- @param valueClass One of nil/"warn"/"bad"/"dim"/"good" → the status square after the value
--- @param dotColor   Optional {r,g,b,a} for the status square after the value (wins over the class's)
--- @param fixedLabelW Optional pixel width for left-aligned label column (220w spec uses 80)
--- @return height
function ZeD.Molecules.drawCardStatRow(panel, x, y, w, label, value, valueClass, dotColor, fixedLabelW)
    local T = ZeD.T
    local A = ZeD.Atoms
    local lblFont = T.fontF1
    local valFont = T.fontF2

    local labelH = T.fontF1H or ZeD.TM:getFontHeight(lblFont)
    local valueH = T.fontF2H or ZeD.TM:getFontHeight(valFont)
    local rowH   = math.max(labelH, valueH) + T.px(2)  -- 2px breathe (matches mockup padding:1px 0)
    local labelY = y + math.floor((rowH - labelH) / 2)
    local valueY = y + math.floor((rowH - valueH) / 2)

    -- Label: F1 mono bold in sentence case, the accent as legible text (not toneLo)
    local lblText = ZeD.textCase(label or "")
    local lc      = T.accentText
    -- the status: the caller's square, else the value class's (default words either way)
    dotColor = dotColor or _statClassMark(valueClass, T)
    panel:drawText(lblText, x, labelY,
        lc.r, lc.g, lc.b, lc.a or 1, lblFont)

    local lblWMeasured = ZeD.TM:MeasureStringX(lblFont, lblText)
    local lblColW = fixedLabelW or lblWMeasured

    -- Value column starts after the label column + 6px gap (mockup `gap:6px`)
    local valX     = x + lblColW + T.px(6)
    local maxValW  = w - (valX - x)

    -- Optional status dot — reserves space at the right edge before value
    local dotSz   = T.px(7)
    local dotGap  = T.px(5)
    local dotResW = dotColor and (dotSz + dotGap) or 0
    local valSlotW = maxValW - dotResW

    -- Value text (right-aligned, ellipsis if too wide)
    local valStr = value or ""
    local vc     = _resolveStatValColor(valueClass, T)
    local valW   = ZeD.TM:MeasureStringX(valFont, valStr)
    if valSlotW > 0 and valW > valSlotW then
        valStr = A.truncateText(valStr, valFont, valSlotW)
        valW   = ZeD.TM:MeasureStringX(valFont, valStr)
    end
    local valDrawX = x + w - dotResW - valW
    panel:drawText(valStr, valDrawX, valueY,
        vc.r, vc.g, vc.b, vc.a or 1, valFont)

    -- Status dot (right of value)
    if dotColor then
        local dotY = y + math.floor((rowH - dotSz) / 2)
        A.drawStatusDot(panel, x + w - dotSz, dotY, dotColor, dotSz)
    end

    return rowH
end

-- T3.2 TOP STATS LIST (220w preset) -----------------------------------------
--- Single-column stat list with fixed 80px label gutter (per v15 220w spec).
--- @param panel ISPanel
--- @param x, y  Top-left
--- @param w     Available width
--- @param statRows Array of {label, value, valueClass, dotColor}
--- @return height (sum of all row heights)
function ZeD.Molecules.drawTopStatsList(panel, x, y, w, statRows)
    local T = ZeD.T
    if not statRows or #statRows == 0 then return 0 end
    local rowGap = T.px(2)
    local cy = y
    for i, r in ipairs(statRows) do
        local rowH = ZeD.Molecules.drawCardStatRow(panel, x, cy, w,
            r.label, r.value, r.valueClass, r.dotColor, T.px(80))
        cy = cy + rowH + (i < #statRows and rowGap or 0)
    end
    return cy - y
end

-- T3.1 TOP STATS GRID (480w preset) -----------------------------------------
--- 56px item icon (left) + 2-column stat grid (right). Per v13 480w spec.
--- statRows fills column-major: row1L, row1R, row2L, row2R, ...
--- @param panel ISPanel
--- @param x, y  Top-left
--- @param w     Total available width (icon + gap + grid)
--- @param iconTexture  PZ texture for the item icon (or nil for placeholder square)
--- @param statRows     Array of {label, value, valueClass, dotColor}
--- @param iconGhost    Optional: draw the icon at .3 alpha in a danger-bordered,
---                     empty box (Vehicle tab: a missing part shows what fits)
--- @return height
function ZeD.Molecules.drawTopStatsGrid(panel, x, y, w, iconTexture, statRows, iconGhost)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local iconSz   = T.px(56)
    local iconGap  = T.px(10)
    local colGap   = T.px(16)
    local rowGap   = T.px(4)

    local gridX = x + iconSz + iconGap
    local gridW = w - iconSz - iconGap
    local colW  = math.floor((gridW - colGap) / 2)

    -- Item icon: 56x56 surf2 box, ZeD.Atoms.drawIcon if texture present
    local bg, bd = T.surf2, T.borderS
    if iconGhost then bd = T.danger else panel:drawRect(x, y, iconSz, iconSz, bg.a, bg.r, bg.g, bg.b) end
    panel:drawRectBorder(x, y, iconSz, iconSz, bd.a or 1, bd.r, bd.g, bd.b)
    if iconTexture then
        local pad = T.px(4)
        A.drawIcon(panel, iconTexture, x + pad, y + pad, iconSz - pad * 2, iconGhost and 0.3 or 1.0, T.iconWhite)
    end

    -- Grid: pair rows from statRows[2k-1], statRows[2k]
    local rows = statRows or {}
    local n    = #rows
    local rowCount = math.ceil(n / 2)
    local cy = y
    for r = 1, rowCount do
        local lIdx, rIdx = r * 2 - 1, r * 2
        local rowH1 = 0
        local rowH2 = 0
        if rows[lIdx] then
            local sr = rows[lIdx]
            rowH1 = ZeD.Molecules.drawCardStatRow(panel, gridX, cy, colW,
                sr.label, sr.value, sr.valueClass, sr.dotColor)
        end
        if rows[rIdx] then
            local sr = rows[rIdx]
            rowH2 = ZeD.Molecules.drawCardStatRow(panel,
                gridX + colW + colGap, cy, colW,
                sr.label, sr.value, sr.valueClass, sr.dotColor)
        end
        cy = cy + math.max(rowH1, rowH2)
        if r < rowCount then cy = cy + rowGap end
    end

    -- Total height = max(icon height, grid height)
    return math.max(iconSz, cy - y)
end

-- T3.3 FACTS PANEL PRIMITIVES ----------------------------------------------
--- "Defense Facts" / "Nutrition Facts" / etc. title — sans, 14/12px, weight 600.
--- @return height
function ZeD.Molecules.drawFactsTitle(panel, x, y, w, text, compact)
    local T = ZeD.T
    local font = compact and T.fontF2 or T.fontF4
    local h = (compact and T.fontF2H) or T.fontF4H
        or ZeD.TM:getFontHeight(font)
    local c = T.text
    panel:drawText(text or "", x, y,
        c.r, c.g, c.b, c.a or 1, font)
    return h + T.px(2)  -- mockup margin-bottom:2px
end

--- 2px thick text-color rule (above first facts row).
function ZeD.Molecules.drawFactsRuleThick(panel, x, y, w)
    local T = ZeD.T
    local c = T.text
    -- mockup margin:4px 0 (480w) or 2px 0 (220w) — caller manages outer spacing;
    -- molecule renders just the rule itself
    local t = T.line(2)   -- two hairlines (Oct 21 2026: T.px(2) was 3 px beside 2 px hairlines at 1.5)
    panel:drawRect(x, y, w, t, c.a, c.r, c.g, c.b)
    return t
end

--- 1px thin border-color rule (between facts sub-blocks).
function ZeD.Molecules.drawFactsRuleThin(panel, x, y, w)
    local T = ZeD.T
    local c = T.border
    panel:drawRect(x, y, w, T.px(1), c.a, c.r, c.g, c.b)
    return T.px(1)
end

--- Single facts row: bold label (left, sans 600) + mono bold value (right).
--- Optional sub mode for indented secondary rows ("1-in-N degrade", etc.).
--- @param panel ISPanel
--- @param x, y  Top-left
--- @param w     Available width
--- @param label String
--- @param value String
--- @param valueClass One of nil/"warn"/"bad"/"dim"/"good"
--- @param isSub  bool — sub-row gets indent + smaller font + textSec label
--- @param needsProbe bool — when true, append a small "*" badge in T.warning
---                          color after the label per v13 mockup convention
---                          (signals a value sourced from an unprobed Java getter
---                          that may resolve to a real number once Q125–Q128 land)
--- @return height
function ZeD.Molecules.drawFactsRow(panel, x, y, w, label, value, valueClass, isSub, needsProbe)
    local T = ZeD.T

    -- v13: label is sans-serif weight 600 (~T.fontF4 small) for main, fontF2 for sub
    -- v13: value is mono bold (T.fontF1)
    local labelFont = isSub and T.fontF2 or T.fontF4
    local valueFont = T.fontF1

    local labelH = isSub and T.fontF2H or T.fontF4H
        or ZeD.TM:getFontHeight(labelFont)
    local valueH = T.fontF1H or ZeD.TM:getFontHeight(valueFont)
    local rowH   = math.max(labelH, valueH) + T.px(2)  -- mockup padding:2px 0

    local indent = isSub and T.px(14) or 0
    local labelC = isSub and T.textSec or T.text
    local labelY = y + math.floor((rowH - labelH) / 2)
    local valueY = y + math.floor((rowH - valueH) / 2)

    -- The value is measured first: the label gets the room left of it (minus a gap),
    -- and ends in "..." when it does not fit
    local vStr = value or ""
    local vw   = ZeD.TM:MeasureStringX(valueFont, vStr)
    -- a status class shows as a 6u square before the value (the words stay default)
    local markC = _statClassMark(valueClass, T)
    local markSq, markGap = T.px(6), T.px(5)
    local markW = markC and (markSq + markGap) or 0
    local labelStr = label or ""
    local labelRoom = w - indent - vw - markW - T.px(8)
    if needsProbe then labelRoom = labelRoom - T.px(10) end   -- the "*" badge after the label
    labelStr = ZeD.Atoms.truncateText(labelStr, labelFont, labelRoom)
    panel:drawText(labelStr, x + indent, labelY,
        labelC.r, labelC.g, labelC.b, labelC.a or 1, labelFont)

    -- v13 ★ probe badge — small mono-warning suffix after the label.
    -- Uses ASCII "*" until Fira live-verify confirms "★" (U+2605) renders
    -- (Q15b — Fira font glyph gaps).
    if needsProbe then
        local lblW    = ZeD.TM:MeasureStringX(labelFont, labelStr)
        local badgeC  = T.warning
        local badgeFont = T.fontF1
        local badgeH  = T.fontF1H or ZeD.TM:getFontHeight(badgeFont)
        local badgeY  = y + math.floor((rowH - badgeH) / 2)
        panel:drawText("*", x + indent + lblW + T.px(4), badgeY,
            badgeC.r, badgeC.g, badgeC.b, badgeC.a or 1, badgeFont)
    end

    local vc   = _resolveStatValColor(valueClass, T)
    panel:drawText(vStr, x + w - vw, valueY,
        vc.r, vc.g, vc.b, vc.a or 1, valueFont)
    if markC then
        ZeD.Atoms.drawStatusDot(panel, x + w - vw - markW, y + math.floor((rowH - markSq) / 2), markC, markSq)
    end

    return rowH
end

-- ============================================================================
-- 17. PROTECTION ZONE PAIR (draw helper)
-- Two-column compact layout for body part defense rows.
-- Each column: fill bar on top, zone name + stats below.
-- zoneR may be nil for odd-count parts (renders left column only).
-- ============================================================================

function ZeD.Molecules.drawProtZonePair(panel, x, y, w, zoneL, zoneR)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local font = T.fontF1
    local secH = ZeD.TM:getFontHeight(font)
    local barH = T.fillBarH
    local colGap = T.sp.sm
    local colW = math.floor((w - colGap) / 2)

    local rightX = x + colW + colGap

    -- Row 1: Fill bars
    local function drawZoneBar(zx, zone)
        if not zone then return end
        local pct = (zone.pct or 0) / 100
        A.drawFillBar(panel, zx, y, colW, pct, true)
    end

    drawZoneBar(x, zoneL)
    drawZoneBar(rightX, zoneR)

    -- Row 2: Zone name + stats
    local statsY = y + barH + T.px(2)

    local function drawZoneStats(zx, zw, zone)
        if not zone then return end
        local name = zone.name or ""
        local pctStr = tostring(math.floor(zone.pct or 0)) .. "%"

        -- Parse S:xx B:xx from dock flag
        local dockStr = ""
        if zone.dock and zone.dock.flag then
            dockStr = zone.dock.flag
        end

        -- Name left-aligned
        local tc = T.text
        panel:drawText(name, zx, statsY, tc.r, tc.g, tc.b, tc.a, font)

        -- Stats right-aligned: "15%  S:0 B:0"
        local statsText = pctStr .. "  " .. dockStr
        local statsW = ZeD.TM:MeasureStringX(font, statsText)
        local dc = T.textDim
        panel:drawText(statsText, zx + zw - statsW, statsY, dc.r, dc.g, dc.b, dc.a, font)
    end

    drawZoneStats(x, colW, zoneL)
    drawZoneStats(rightX, colW, zoneR)

    -- Total height: bar + gap + stats line + pair gap
    return barH + T.px(2) + secH + T.sp.xs
end


-- ============================================================================
-- 18. SORT STRIP (draw helper)
-- A 20u strip over the recipe list (it doubles as its column header row): the
-- sort choices as System 7 radio buttons and, at the right, a checkbox toggle.
-- When the choices do not all fit and the caller opens menus (opts.menuOpen
-- given), they fold into a System 7 pop-up menu: a framed box naming the current
-- choice with a down triangle; on its "sortMenu" zone the caller opens the list
-- (ZeD.Molecules.drawSortMenuList, drawn last so nothing covers it). A caller
-- that passes no opts gets the radio buttons that fit (the rest drop, as before).
--
-- modes:        ordered list of {id, label} tables
-- activeMode:   id string of the active sort mode
-- rightToggle:  {label, active} or nil (right-aligned checkbox toggle)
-- hoverZone:    the zone id under the pointer (a mode id, "toggle", "menu") or nil
-- opts:         optional { focusId = the zone id with the controller's focus (with
--               focus = its mark opts) or focusParts = { [id] = mark opts }, win,
--               menuOpen = true / false (the caller handles the pop-up; false = shut),
--               menu = true (the pop-up even when the radio buttons would fit) }
-- Returns:      stripH (20u), zones { {id, x, y, w, h, type = "sort" | "toggle" | "sortMenu"} }
-- ============================================================================

local STRIP_H = 20   -- S124 scale: design units; uses wrap with T.px
local RADIO_GAP, CHOICE_GAP = 4, 10   -- design units: a radio to its words, between choices

-- the focus mark under a part's words; true when the words switch to the focus ink
local function markPart(panel, x, y, w, h, f)
    if not f or not (ZeD.Focus and ZeD.Focus.mark) then return false end
    return ZeD.Focus.mark(panel, x, y, w, h, f) and true or false
end

-- the closed pop-up menu: the hover wash, a 1u frame, the choice's words and a down triangle
local function drawPopupBox(panel, x, y, w, h, label, hover, focus)
    local T, A, tm = ZeD.T, ZeD.Atoms, ZeD.TM
    if hover then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a or 1, hv.r, hv.g, hv.b)
    end
    local onFocus = markPart(panel, x, y, w, h, focus)
    local font = T.fontF1
    local pad, tri = T.px(6), T.px(5)
    local tc = onFocus and T.textOnFocus or T.text
    local s = A.truncateText(label or "", font, math.max(0, w - pad * 2 - tri - T.px(4)))
    panel:drawText(s, x + pad, y + math.floor((h - tm:getFontHeight(font)) / 2), tc.r, tc.g, tc.b, tc.a or 1, font)
    A.drawTriangleDown(panel, x + w - pad - tri, y + math.floor((h - tri) / 2), tri, onFocus and T.textOnFocus or T.textDim)
    A.frame(panel, x, y, w, h, T.borderS)
end

local _sortRadio = {}
function ZeD.Molecules.drawSortStrip(panel, x, y, w, modes, activeMode, rightToggle, hoverZone, opts)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    opts = opts or NO_OPTS
    local h  = T.px(STRIP_H)
    local font = T.fontF1
    local textY = y + math.floor((h - tm:getFontHeight(font)) / 2)
    local zones = {}

    -- Strip background (a window surface: no stacking over the body) and the structure line under it
    A.surfaceFill(panel, x, y, w, h, "surf2")
    A.drawDividerH(panel, x, y + h - T.line(T.borderW), w, true)

    -- "Sort" label
    local sortLabel = A.textCase(ZeD.tr("UI_ZeD_Strip_Sort"))
    local sc = T.textSec
    panel:drawText(sortLabel, x + T.px(6), textY, sc.r, sc.g, sc.b, sc.a or 1, font)
    local left = x + T.px(6) + tm:MeasureStringX(font, sortLabel) + T.px(8)

    -- The toggle's width is reserved first, so the choices never run under it
    local togLabel, togW = nil, 0
    if rightToggle then
        togLabel = rightToggle.label or ZeD.tr("UI_All")
        togW = tm:MeasureStringX(font, togLabel) + T.checkboxSz + T.px(4)  -- checkbox + gap + text
    end
    local limit = x + w - T.px(6)
    if rightToggle then limit = limit - togW - T.px(8) end

    -- Radio buttons when they all fit; the pop-up when they don't and the caller opens menus
    local rs = A.radioSize()
    local total = 0
    for i, mode in ipairs(modes) do
        total = total + rs + T.px(RADIO_GAP) + tm:MeasureStringX(font, mode.label) + ((i > 1) and T.px(CHOICE_GAP) or 0)
    end
    if opts.menuOpen ~= nil and (opts.menu or left + total > limit) then
        local act = modes[1]
        for _, m in ipairs(modes) do if m.id == activeMode then act = m; break end end
        local label = act and act.label or ""
        local bw = math.min(limit - left, tm:MeasureStringX(font, label) + T.px(6) * 2 + T.px(5) + T.px(4))
        if bw >= T.px(24) then
            drawPopupBox(panel, left, y + T.px(2), bw, h - T.px(4), label,
                hoverZone == "menu" or opts.menuOpen == true, partFocus(opts, "menu"))
            zones[#zones + 1] = { id = "menu", x = left, y = y, w = bw, h = h, type = "sortMenu" }
        end
    else
        -- each choice: the radio, its words; one that does not fit ends in "...", the ones after it drop
        local ry = y + math.floor((h - rs) / 2)
        local cx = left
        for _, mode in ipairs(modes) do
            local label = mode.label
            local room = limit - cx - rs - T.px(RADIO_GAP)
            local tw = tm:MeasureStringX(font, label)
            if tw > room then
                if room < T.px(24) then break end
                label = A.truncateText(label, font, room)
                tw = tm:MeasureStringX(font, label)
            end
            local cw = rs + T.px(RADIO_GAP) + tw
            local isHover = (hoverZone == mode.id)
            local onFocus = markPart(panel, cx - T.px(2), y + T.px(2), cw + T.px(4), h - T.px(4), partFocus(opts, mode.id))
            _sortRadio.hover = isHover
            A.drawRadio(panel, cx, ry, mode.id == activeMode, _sortRadio)
            local tc = onFocus and T.textOnFocus or T.text
            panel:drawText(label, cx + rs + T.px(RADIO_GAP), textY, tc.r, tc.g, tc.b, tc.a or 1, font)
            zones[#zones + 1] = { id = mode.id, x = cx, y = y, w = cw, h = h, type = "sort" }
            cx = cx + cw + T.px(CHOICE_GAP)
        end
    end

    -- Right-aligned on/off: a System 7 checkbox and its words (cohesion spec 1.3)
    if rightToggle then
        local togX = x + w - togW - T.px(6)
        local cb = T.checkboxSz
        local onFocus = markPart(panel, togX - T.px(2), y + T.px(2), togW + T.px(4), h - T.px(4), partFocus(opts, "toggle"))
        A.drawCheckbox(panel, togX, y + math.floor((h - cb) / 2), rightToggle.active, hoverZone == "toggle")
        local togTC = onFocus and T.textOnFocus or T.text
        panel:drawText(togLabel, togX + cb + T.px(4), textY,
            togTC.r, togTC.g, togTC.b, togTC.a or 1, font)

        zones[#zones + 1] = { id = "toggle", x = togX, y = y, w = togW, h = h, type = "toggle" }
    end

    return h, zones
end

--- The sort strip's pop-up list, open: draw it last (over the rows) with its top-left at the
-- "sortMenu" zone's bottom-left. Solid surface 1, a 1u frame and the hard shadow (it pops up);
-- the current choice carries the selected wash, the pointed one the hover wash.
-- opts: optional { focusId / focus / focusParts (a mode id), minW (px), win }
-- @return w, h, zones { {id = mode id, x, y, w, h, type = "sort"} }
function ZeD.Molecules.drawSortMenuList(panel, x, y, modes, activeMode, hoverZone, opts)
    local T, A, tm = ZeD.T, ZeD.Atoms, ZeD.TM
    opts = opts or NO_OPTS
    local font = T.fontF1
    local rowH = T.px(STRIP_H)
    local padX = T.px(8)
    local w = opts.minW or 0
    for _, m in ipairs(modes) do w = math.max(w, tm:MeasureStringX(font, m.label) + padX * 2) end
    local h = rowH * #modes
    local s1 = T.surf1
    panel:drawRect(x, y, w, h, 1, s1.r, s1.g, s1.b)
    local fh = tm:getFontHeight(font)
    local zones = {}
    for i, m in ipairs(modes) do
        local ry = y + (i - 1) * rowH
        if m.id == activeMode then
            local ac = T.accent
            panel:drawRect(x, ry, w, rowH, T.selectionA or 0.30, ac.r, ac.g, ac.b)
        end
        if hoverZone == m.id then
            local hv = T.hover
            panel:drawRect(x, ry, w, rowH, hv.a or 1, hv.r, hv.g, hv.b)
        end
        local onFocus = markPart(panel, x, ry, w, rowH, partFocus(opts, m.id))
        local tc = onFocus and T.textOnFocus or T.text
        panel:drawText(m.label, x + padX, ry + math.floor((rowH - fh) / 2), tc.r, tc.g, tc.b, tc.a or 1, font)
        zones[#zones + 1] = { id = m.id, x = x, y = ry, w = w, h = rowH, type = "sort" }
    end
    A.frame(panel, x, y, w, h, T.borderS)
    A.drawHardShadow(panel, x, y, w, h)
    return w, h, zones
end


-- ============================================================================
-- 19. ALT-BACK STRIP (draw helper)
-- The 20u strip over the alternatives list: the back key and where it goes
-- back to, the owned count, and an "Owned only" checkbox.
-- opts: optional { focusId = "back" / "ownedOnly" (with focus = its mark opts) or
--       focusParts, win }: the part with the controller's focus (the mark goes
--       under its words; the back key and its words are one stop)
-- Returns: stripH, zones { back, ownedOnly }
-- ============================================================================

local _altBack = {}
function ZeD.Molecules.drawAltBackStrip(panel, x, y, w, slotName, ownedCount, totalCount, ownedOnly, hoverZone, opts)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    opts = opts or NO_OPTS
    local h  = T.px(STRIP_H)
    local font = T.fontF1

    -- Surface 2 (no stacking) and the structure line under it
    A.surfaceFill(panel, x, y, w, h, "surf2")
    A.drawDividerH(panel, x, y + h - T.line(T.borderW), w, true)

    local textY = y + math.floor((h - tm:getFontHeight(font)) / 2)
    local zones = {}

    -- Left: the back key, then where it goes back to ("Recipes"): one stop, the mark under both
    local backLabel = ZeD.tr("EC_Recipes")
    local keySz = h - T.px(4)
    local keyY = y + math.floor((h - keySz) / 2)
    local backX = x + T.px(4) + keySz + T.px(4)
    local backW = tm:MeasureStringX(font, backLabel)
    local zoneW = backX + backW + T.px(4) - x
    local onBack = markPart(panel, x, y, zoneW, h, partFocus(opts, "back"))
    _altBack.hover = (hoverZone == "back")
    _altBack.hint = backLabel
    _altBack.tint = onBack and T.textOnFocus or nil
    _altBack.win = opts.win
    ZeD.Molecules.drawBackButton(panel, x + T.px(4), keyY, keySz, _altBack)
    local backTC = onBack and T.textOnFocus or T.text
    panel:drawText(backLabel, backX, textY, backTC.r, backTC.g, backTC.b, backTC.a or 1, font)
    zones[#zones + 1] = { id = "back", x = x, y = y, w = zoneW, h = h, type = "back" }

    -- Center: "N/total owned" stat
    local statStr = ZeD.tr("UI_ZeD_Strip_OwnedCount", ownedCount, totalCount)
    local statW = tm:MeasureStringX(font, statStr)
    local statX = x + math.floor((w - statW) / 2)
    local nc = T.textSec
    panel:drawText(statStr, statX, textY, nc.r, nc.g, nc.b, nc.a or 1, font)

    -- Right: "Owned only", a System 7 checkbox and its words (cohesion spec 1.3)
    local togLabel = ZeD.tr("UI_ZeD_Strip_OwnedOnly")
    local cb = T.checkboxSz
    local togW = tm:MeasureStringX(font, togLabel) + cb + T.px(4)
    local togX = x + w - togW - T.px(6)
    local onTog = markPart(panel, togX - T.px(2), y + T.px(2), togW + T.px(4), h - T.px(4), partFocus(opts, "ownedOnly"))
    A.drawCheckbox(panel, togX, y + math.floor((h - cb) / 2), ownedOnly, hoverZone == "ownedOnly")

    local togTC = onTog and T.textOnFocus or T.text
    panel:drawText(togLabel, togX + cb + T.px(4), textY,
        togTC.r, togTC.g, togTC.b, togTC.a or 1, font)

    zones[#zones + 1] = { id = "ownedOnly", x = togX, y = y, w = togW + T.px(6), h = h, type = "toggle" }

    return h, zones
end


-- ============================================================================
-- 20. RECIPE ROW (draw helper)
-- A 24u row in the recipe list: status square, icon, name, station tag, star.
-- Striped background; selected = the one accent wash (T.selectionA), hover =
-- T.hover over it; the words stay default text on both (dim for a recipe not
-- known or made at a station). The status square carries the state.
--
-- data table: { name, displayName, iconTex, status, craftable, tag }
--   status: "can" (green), "miss" (gold: missing things), "unknown" (red),
--           "station" (hollow square: made at a station, not by hand)
--   tag:    optional short label drawn right as a tag (the station: "Kiln")
-- opts:     optional { focus = the ZeD.Focus.mark opts (or true) when the row has
--           the controller's focus: the mark goes under the words, which switch to
--           the focus ink when it asks; win }
-- ============================================================================

local RECIPE_ROW_H = 24   -- S124 scale: design units; uses wrap with T.px

-- a name cut to maxW with ".." (the recipe lists' own short ellipsis)
local function cutName(tm, font, s, maxW)
    if tm:MeasureStringX(font, s) <= maxW then return s end
    local lo, hi = 1, #s
    while lo < hi do
        local mid = math.ceil((lo + hi) / 2)
        if tm:MeasureStringX(font, string.sub(s, 1, mid) .. "..") <= maxW then lo = mid else hi = mid - 1 end
    end
    return string.sub(s, 1, lo) .. ".."
end

local _recTag = {}
function ZeD.Molecules.drawRecipeRow(panel, x, y, w, data, selected, hovered, pinned, freqCount, rowIdx, opts)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    opts = opts or NO_OPTS
    local h  = T.px(RECIPE_ROW_H)

    -- Stripe background (alternating even rows)
    if rowIdx and rowIdx % 2 == 0 then
        local st = T.stripe
        panel:drawRect(x, y, w, h, st.a, st.r, st.g, st.b)
    end

    -- Selected: the one accent wash (T.selectionA, no side bar); hover: T.hover over it
    local status = data.status or "can"
    if selected then
        local ac = T.accent
        panel:drawRect(x, y, w, h, T.selectionA or 0.30, ac.r, ac.g, ac.b)
    end
    if hovered then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end
    -- the controller's mark, under the words
    local onFocus = false
    if opts.focus and ZeD.Focus and ZeD.Focus.mark then
        onFocus = ZeD.Focus.mark(panel, x, y, w, h, focusOptsOf(opts)) and true or false
    end

    local cx = x + T.px(4)  -- edge space

    -- Status square (6u): green = craftable, gold = missing things, red = not known; hollow = at a station
    local dotSz = T.px(6)
    local dotY = y + math.floor((h - dotSz) / 2)
    if status == "station" then
        A.drawStatusHollow(panel, cx, dotY, T.textDim, dotSz)
    else
        local dotColor
        if status == "can" then dotColor = T.positive
        elseif status == "miss" then dotColor = T.warning
        else dotColor = T.danger end
        A.drawStatusDot(panel, cx, dotY, dotColor, dotSz)
    end
    cx = cx + dotSz + T.px(4)

    -- Icon (14u)
    local iconSz = T.px(14)
    if data.iconTex then
        local iconY = y + math.floor((h - iconSz) / 2)
        panel:drawTextureScaledAspect(data.iconTex, cx, iconY, iconSz, iconSz, 1, 1, 1, 1)
    end
    cx = cx + iconSz + T.px(4)

    -- Name (F2, ellipsis if needed)
    local nameFont = T.fontF2
    local textY = y + math.floor((h - tm:getFontHeight(nameFont)) / 2)
    local nameMaxW = w - (cx - x) - T.px(24)  -- reserve space for star

    -- Station tag (right, before the star): eats into name space
    local tagW = 0
    if data.tag and data.tag ~= "" then
        tagW = A.tagW(data.tag, false)
        nameMaxW = nameMaxW - tagW - T.px(6)
    end

    -- Freq count eats into name space
    local freqStr = nil
    if freqCount and freqCount > 0 then
        freqStr = "x" .. tostring(freqCount)
        nameMaxW = nameMaxW - tm:MeasureStringX(T.fontF5, freqStr) - T.px(8)
    end

    -- Words: default text (on the selected wash too), dim for a recipe not known or made at a station
    local nameColor
    if onFocus then nameColor = T.textOnFocus
    elseif status == "unknown" or status == "station" then nameColor = T.textDim
    else nameColor = T.text end

    local nameStr = cutName(tm, nameFont, data.displayName or data.name or "", nameMaxW)
    panel:drawText(nameStr, cx, textY, nameColor.r, nameColor.g, nameColor.b, nameColor.a or 1, nameFont)
    cx = cx + tm:MeasureStringX(nameFont, nameStr) + T.px(4)

    -- Freq count (inline, dim: a count, not a status)
    if freqStr then
        local fc = onFocus and T.textOnFocus or T.textDim
        panel:drawText(freqStr, cx, textY + T.px(1), fc.r, fc.g, fc.b, fc.a or 1, T.fontF5)
    end

    -- Station tag: the library tag (outline, F1, sentence case)
    if tagW > 0 then
        local tg = _recTag
        tg.textColor = onFocus and T.textOnFocus or nil
        A.drawTag(panel, x + w - T.px(22) - tagW, y + math.floor((h - T.px(16)) / 2), data.tag, nil, tg)
    end

    -- Star (right-aligned, hover-appear, accent when pinned)
    local starX = x + w - T.px(18)
    local starAlpha = pinned and 1.0 or (hovered and 0.5 or 0)
    if starAlpha > 0 then
        local starColor = pinned and T.accent or T.textDim
        if onFocus then starColor = T.textOnFocus end
        local starFont = T.fontF3
        local starY = y + math.floor((h - tm:getFontHeight(starFont)) / 2)
        panel:drawText("*", starX, starY,
            starColor.r, starColor.g, starColor.b, starAlpha, starFont)
    end

    return h
end


-- ============================================================================
-- 21. ALT ROW (draw helper)
-- A 24u row in the alternative ingredients list: status square, icon, name,
-- count. Owned shows in the square (filled green; hollow when not owned) and
-- the words (default text; dim when not owned). No tint. Read-only.
--
-- data table: { name, displayName, iconTex, have, need }
-- opts:       optional { selected (the one accent wash), hover (T.hover), focus
--             (the ZeD.Focus.mark opts or true), win }
-- ============================================================================

function ZeD.Molecules.drawAltRow(panel, x, y, w, data, owned, rowIdx, opts)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    opts = opts or NO_OPTS
    local h  = T.px(RECIPE_ROW_H)

    -- Stripe
    if rowIdx and rowIdx % 2 == 0 then
        local st = T.stripe
        panel:drawRect(x, y, w, h, st.a, st.r, st.g, st.b)
    end
    if opts.selected then
        local ac = T.accent
        panel:drawRect(x, y, w, h, T.selectionA or 0.30, ac.r, ac.g, ac.b)
    end
    if opts.hover then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end
    local onFocus = false
    if opts.focus and ZeD.Focus and ZeD.Focus.mark then
        onFocus = ZeD.Focus.mark(panel, x, y, w, h, focusOptsOf(opts)) and true or false
    end

    local cx = x + T.px(4)

    -- Status square (6u): owned = filled green, not owned = hollow
    local dotSz = T.px(6)
    local dotY = y + math.floor((h - dotSz) / 2)
    if owned then A.drawStatusDot(panel, cx, dotY, T.positive, dotSz)
    else A.drawStatusHollow(panel, cx, dotY, T.textDim, dotSz) end
    cx = cx + dotSz + T.px(4)

    -- Icon (16u)
    local iconSz = T.px(16)
    if data.iconTex then
        local iconY = y + math.floor((h - iconSz) / 2)
        panel:drawTextureScaledAspect(data.iconTex, cx, iconY, iconSz, iconSz, 1, 1, 1, 1)
    end
    cx = cx + iconSz + T.px(4)

    -- Name (F2; dim when not owned)
    local nameFont = T.fontF2
    local textY = y + math.floor((h - tm:getFontHeight(nameFont)) / 2)
    local tc = onFocus and T.textOnFocus or (owned and T.text or T.textDim)

    -- Truncate (reserve space for count)
    local countStr = tostring(data.have or 0) .. "/" .. tostring(data.need or 1)
    local countW = tm:MeasureStringX(T.fontF3, countStr) + T.px(8)
    local nameStr = cutName(tm, nameFont, data.displayName or data.name or "", w - (cx - x) - countW)
    panel:drawText(nameStr, cx, textY, tc.r, tc.g, tc.b, tc.a or 1, nameFont)

    -- Count (right-aligned, the same words colour)
    A.drawTextRight(panel, countStr, x + w - T.px(6), textY, T.fontF3, tc)

    return h
end


-- ============================================================================
-- 22. SLOT ROW (draw helper)
-- A 24u row in the craft card's required items list.
-- Grid: edge | 18u icon | name + tags | square + count | 14u consumable flag
-- The words are default text; the count's status square says have (green) or
-- missing (red). Alternatives show as a tag with a warning square and the count
-- ("[■ 3] v": press the row to see them); a text tag ("Tool", "1 use", "Fuel")
-- is the library tag.
--
-- data table: { name, displayName, iconTex, have, need, altCount, isKeep, isTool, tag }
--   altCount: number of alternatives (nil or 0 = specific item, no alt click)
--   tag: "TOOL", "1 USE", etc. for specific items; nil for alt-backed
-- selected: this slot's alts are being shown in the left pane
-- opts:     optional { focus = the ZeD.Focus.mark opts (or true) when the row has the
--           controller's focus; win }
-- ============================================================================

local _slotTag = {}
function ZeD.Molecules.drawSlotRow(panel, x, y, w, data, selected, hovered, opts)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    opts = opts or NO_OPTS
    local h  = T.px(RECIPE_ROW_H)
    local missing = (data.have or 0) < (data.need or 1)
    local alts = (data.altCount or 0) > 0

    -- Selected: the one accent wash; hover: T.hover (only a row that opens its alternatives)
    if selected then
        local ac = T.accent
        panel:drawRect(x, y, w, h, T.selectionA or 0.30, ac.r, ac.g, ac.b)
    end
    if hovered and alts then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end
    local onFocus = false
    if opts.focus and ZeD.Focus and ZeD.Focus.mark then
        onFocus = ZeD.Focus.mark(panel, x, y, w, h, focusOptsOf(opts)) and true or false
    end
    local tc = onFocus and T.textOnFocus or T.text

    local cx = x + T.px(4)  -- edge space (selection is the wash; no side bar)

    -- Icon (18u)
    local iconSz = T.px(18)
    if data.iconTex then
        local iconY = y + math.floor((h - iconSz) / 2)
        panel:drawTextureScaledAspect(data.iconTex, cx, iconY, iconSz, iconSz, 1, 1, 1, 1)
    end
    cx = cx + iconSz + T.px(4)

    -- the right end first: the consumable flag, the count and its status square
    local countStr
    if data.isKeep or data.isTool then
        countStr = tostring(data.have or 0)
    else
        countStr = tostring(data.have or 0) .. "/" .. tostring(data.need or 1)
    end
    local countFont = T.fontF3
    local flagW = T.px(14)  -- space for consumable flag
    local countR = x + w - flagW - T.px(4)
    local countW = tm:MeasureStringX(countFont, countStr)
    local sq, sqGap = T.px(6), T.px(5)
    local rightReserve = flagW + T.px(4) + countW + sqGap + sq + T.px(6)

    -- Name + tags
    local nameFont = T.fontF2
    local textY = y + math.floor((h - tm:getFontHeight(nameFont)) / 2)
    local nameMaxW = w - (cx - x) - rightReserve
    local tagStr, tagW, extraTag, extraW = nil, 0, nil, 0
    local tri = T.px(5)
    if alts then
        tagStr = tostring(data.altCount)
        tagW = A.tagW(tagStr, true) + T.px(3) + tri
        nameMaxW = nameMaxW - tagW - T.px(6)
        if data.tag == "FUEL" then
            extraTag = ZeD.tr("UI_ZeD_Recipe_Fuel")
            extraW = A.tagW(extraTag, false)
            nameMaxW = nameMaxW - extraW - T.px(6)
        end
    elseif data.tag then
        tagStr = data.tag
        tagW = A.tagW(tagStr, false)
        nameMaxW = nameMaxW - tagW - T.px(6)
    end

    local nameStr = cutName(tm, nameFont, data.displayName or data.name or "", nameMaxW)
    panel:drawText(nameStr, cx, textY, tc.r, tc.g, tc.b, tc.a or 1, nameFont)
    cx = cx + tm:MeasureStringX(nameFont, nameStr) + T.px(6)

    -- Tags: the alternatives (a warning square and how many, then a small down triangle),
    -- the fuel tag after them, or a specific item's text tag
    if tagStr then
        local tg = _slotTag
        tg.textColor = onFocus and T.textOnFocus or nil
        local ty = y + math.floor((h - T.px(16)) / 2)
        if alts then
            local tw = A.drawTag(panel, cx, ty, tagStr, T.warning, tg)
            A.drawTriangleDown(panel, cx + tw + T.px(3), y + math.floor((h - tri) / 2), tri, onFocus and T.textOnFocus or T.textDim)
            if extraTag then
                A.drawTag(panel, cx + tagW + T.px(6), ty, extraTag, nil, tg)
            end
        else
            A.drawTag(panel, cx, ty, tagStr, nil, tg)
        end
    end

    -- Have/need count (right-aligned, before the consumable flag) after its status square
    local cy = y + math.floor((h - sq) / 2)
    A.drawStatusDot(panel, countR - countW - sqGap - sq, cy, missing and T.danger or T.positive, sq)
    A.drawTextRight(panel, countStr, countR, textY, countFont, tc)

    -- Consumable flag (right corner): arrow = returned/kept, dash = consumed
    local flagX = x + w - flagW
    local flagColor = onFocus and T.textOnFocus or T.textDim
    if data.isKeep or data.isTool then
        -- Return arrow (left-pointing)
        local arrSz = T.px(5)
        local arrY = y + math.floor((h - arrSz) / 2)
        A.drawTriangleLeft(panel, flagX + T.px(4), arrY, arrSz, flagColor)
    else
        -- Consumed indicator: "-" dash
        local dashStr = "-"
        local dashW = tm:MeasureStringX(T.fontF3, dashStr)
        panel:drawText(dashStr, flagX + math.floor((flagW - dashW) / 2), textY,
            flagColor.r, flagColor.g, flagColor.b, flagColor.a or 1, T.fontF3)
    end

    return h
end


-- ============================================================================
-- 23. QTY STEPPER (draw helper)
-- [-] n [+]: a readout between two square push buttons (cohesion spec 7), each
-- disabled at its end of the range. Returns: totalW (width of the group), zones
-- table for clicks ("dec", "inc").
-- ============================================================================

local STEPPER_GAP = 4   -- design units between the keys and the readout

--- @param h         button height in px (default T.buttonH - T.px(4), the list-row height)
--- @param hoverZone "dec" / "inc" / nil (nil: the pointer is tested here)
--- @param opts      optional { focusId = "dec" / "inc" (with focus = its mark opts) or
---                  focusParts, win }: the key with the controller's focus
local _stepOpts = {}
function ZeD.Molecules.drawQtyStepper(panel, x, y, qty, maxQty, h, hoverZone, opts)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local M  = ZeD.Molecules
    local tm = ZeD.TM
    opts = opts or NO_OPTS
    h = h or (T.buttonH - T.px(4))
    local bw = h
    local gap = T.px(STEPPER_GAP)
    local font = T.fontF3
    local zones = {}
    local o = _stepOpts
    o.win = opts.win

    -- [-]
    o.disabled = not (qty > 1)
    if hoverZone ~= nil then o.hover = (hoverZone == "dec") else o.hover = A.mouseIn(panel, x, y, bw, h) end
    o.focus = partFocus(opts, "dec")
    M.drawButton(panel, x, y, bw, h, "-", "default", false, nil, o)
    zones[#zones + 1] = { id = "dec", x = x, y = y, w = bw, h = h }

    -- the readout
    local qtyStr = tostring(qty)
    local qtyTW = tm:MeasureStringX(font, qtyStr)
    local qtyW = math.max(bw, qtyTW + T.px(8))
    local qtyX = x + bw + gap
    local tc = T.text
    panel:drawText(qtyStr, qtyX + math.floor((qtyW - qtyTW) / 2), y + math.floor((h - tm:getFontHeight(font)) / 2),
        tc.r, tc.g, tc.b, tc.a or 1, font)

    -- [+]
    local incX = qtyX + qtyW + gap
    o.disabled = not (qty < maxQty)
    if hoverZone ~= nil then o.hover = (hoverZone == "inc") else o.hover = A.mouseIn(panel, incX, y, bw, h) end
    o.focus = partFocus(opts, "inc")
    M.drawButton(panel, incX, y, bw, h, "+", "default", false, nil, o)
    zones[#zones + 1] = { id = "inc", x = incX, y = y, w = bw, h = h }

    local totalW = incX + bw - x
    return totalW, zones
end


-- ============================================================================
-- 24. CRAFT ACTION STRIP (draw helper)
-- The band at the foot of the craft card (ZeD.Molecules.drawBand: its height,
-- surface 2 with no stacking, the structure line on top), holding the stepper
-- the band has no slot for: [qty stepper] | max readout | the Craft / Build push
-- button (primary, filling the rest; disabled when it cannot run).
-- buildLabel: "CRAFT" or "BUILD" (tab-specific; drawn in sentence case).
-- canCraft: false disables the button (grey, no click).
-- opts: optional {
--   h        = the height the caller reserved for it at the pane's foot (default the
--              older 42u); the band sits at the bottom of it. Reserve
--              ZeD.Molecules.craftActionStripH() (the band's height) to lose the slack.
--   focusId  = "dec" / "inc" / "build" (with focus = its mark opts) or focusParts:
--              the part with the controller's focus (the mark goes under its words)
--   buildHelp = the Craft button's help line words; win }
-- Returns: the height used (the reserved height), zones ("dec", "inc", "build")
-- ============================================================================

local ACT_STRIP_H = 42   -- design units: what callers reserved before the strip became a band

--- The craft action strip's height: the band's.
function ZeD.Molecules.craftActionStripH()
    return ZeD.Molecules.bandH()
end

local _ctaBtns = { {} }
local _ctaSpec = { buttons = _ctaBtns }
local _ctaStep = {}
function ZeD.Molecules.drawCraftActionStrip(panel, x, y, w, qty, maxQty, canCraft, hoverZone, buildLabel, opts)
    local T  = ZeD.T
    local M  = ZeD.Molecules
    local tm = ZeD.TM
    opts = opts or NO_OPTS
    local H = M.bandH()
    local reserved = math.max(H, opts.h or T.px(ACT_STRIP_H))
    local by = y + reserved - H
    local zones = {}

    -- the left part's width first (the stepper, the max readout), so the button takes the rest
    local innerH = T.buttonH
    local innerY = by + T.px(5)
    local cx = x + T.px(8)
    local font = T.fontF3
    local qtyW = math.max(innerH, tm:MeasureStringX(font, tostring(qty)) + T.px(8))
    local stepW = innerH * 2 + qtyW + 2 * T.px(STEPPER_GAP)
    local maxStr = tostring(maxQty)
    local btnX = cx + stepW + T.px(10) + tm:MeasureStringX(font, maxStr) + T.px(10)

    -- the band: surface 2, the structure line, the Craft / Build push button (primary) at the right
    local b = _ctaBtns[1]
    b.label = buildLabel or ZeD.tr("IGUI_CraftingWindow_Craft")
    b.variant, b.disabled, b.id = "primary", not canCraft, "build"
    b.w = math.max(T.px(24), x + w - T.px(8) - btnX)
    if hoverZone ~= nil then b.hover = (hoverZone == "build") else b.hover = nil end
    b.focus, b.help = partFocus(opts, "build"), opts.buildHelp
    _ctaSpec.win = opts.win
    local _, out = M.drawBand(panel, x, by, w, _ctaSpec)
    local r = out.buttons[1]
    if r then zones[#zones + 1] = { id = "build", x = r.x, y = r.y, w = r.w, h = r.h } end

    -- the stepper and the max readout (a bare number) over the band's left part
    local so = _ctaStep
    so.focusId, so.focus, so.focusParts, so.win = opts.focusId, opts.focus, opts.focusParts, opts.win
    local sw, stepZones = M.drawQtyStepper(panel, cx, innerY, qty, maxQty, innerH, hoverZone, so)
    for _, z in ipairs(stepZones) do zones[#zones + 1] = z end
    cx = cx + sw + T.px(10)
    local mc = T.textDim
    panel:drawText(maxStr, cx, innerY + math.floor((innerH - tm:getFontHeight(font)) / 2), mc.r, mc.g, mc.b, mc.a or 1, font)

    return reserved, zones
end

-- ============================================================================
-- CONTEXT MENU MOLECULES (S88)
-- Composed entirely from atoms in AtomExtensions.lua (Tasks 2-9) +
-- T.ctx tokens. No inline draw that duplicates an atom (DESIGN RULE #10).
-- Rendered by ZeD_ContextMenu organism; each molecule is side-effect-free
-- except for registering hit zones on the panel (the convention for
-- click-target tracking, avoids PZ nested-panel mouse bugs Q1/Q4/Q5b).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- drawContextCell — single 22×22 strip cell.
--   def:   ActionDef from ContextMenuRegistry (may carry iconTexture)
--   flags: { isActive, isBack, isPinned, hasSub, isDisabled }
-- States map to spec §3 cell table. Caller positions (x,y); cell has no
-- external margin (gaps are produced by the ink strip background showing
-- through 1px between cells).
-- ---------------------------------------------------------------------------
function ZeD.Molecules.drawContextCell(panel, x, y, def, flags, T)
    local ctx = T.ctx
    local A = ZeD.Atoms
    -- S101: context menu uses LOCKED System 7 paper/ink palette (matches
    -- drawContextBalloon) so cells stand out identically on every theme.
    -- Active cell still uses the theme accent so selection feedback adapts.
    local ink    = { r = 0.08, g = 0.08, b = 0.08, a = 1 }
    local paper  = { r = 0.95, g = 0.95, b = 0.95, a = 1 }
    local accent = T.accent
    local accentBright = T.accentBright or T.accent

    -- Cell background — theme accent for the active cell, paper otherwise.
    -- Active cell gets a hairline (1u) accentBright frame inside its edge on top
    -- of the fill for extra visual pop so the selected action is unmistakable
    -- against the rest of the strip (a frame of design units, not one screen
    -- pixel, so it keeps its weight at every scale).
    local bg = flags.isActive and accent or paper
    panel:drawRect(x, y, ctx.cellW, ctx.cellH, bg.a or 1, bg.r, bg.g, bg.b)
    if flags.isActive then
        A.frame(panel, x, y, ctx.cellW, ctx.cellH, accentBright, 1, T.hair)
    end

    -- Icon / back glyph / letter fallback
    if flags.isBack then
        A.drawBackGlyph(panel, x, y, ctx.cellW, ctx.cellH, flags.isActive, T)
    elseif def.check ~= nil then
        -- a choice that is on or off (a list the item is in): its checkbox, centred
        local cs = T.checkboxSz
        local on = def.check
        if type(on) == "function" then local ok, v = pcall(on); on = ok and v end
        A.drawCheckbox(panel, x + math.floor((ctx.cellW - cs) / 2), y + math.floor((ctx.cellH - cs) / 2), on and true or false, false, flags.isDisabled)
    elseif def.iconTexture then
        -- Centered 16×16 icon
        local iconX = x + math.floor((ctx.cellW - ctx.iconPx) / 2)
        local iconY = y + math.floor((ctx.cellH - ctx.iconPx) / 2)
        local alpha = flags.isDisabled and 0.45 or 1.0
        -- iconTintable (ZeD mapping): white-alpha shape — tint to match
        -- cell foreground so it reads on locked paper / accent. Parallels
        -- the letter-fallback tint rule below.
        -- Vanilla iconTexture / itemForTexture: colored sprite — draw neutral
        -- white tint (identity multiply) so the sprite's own colors survive.
        local tint
        if def.iconTintable then
            tint = flags.isActive and (T.textOnAccent or T.text) or ink
        else
            tint = T.iconWhite
        end
        -- def.pxIcon (ZeD's pixel icon's id): its drawing that fits the box, at its own size
        if def.pxIcon then
            A.drawPxIcon(panel, def.pxIcon, iconX, iconY, ctx.iconPx, alpha, tint)
        else
            A.drawIcon(panel, def.iconTexture, iconX, iconY, ctx.iconPx, alpha, tint)
        end
    else
        -- S99: no-icon fallback — draw first letter(s) in a box. Uses the
        -- first two letters of def.name (stripping non-letters) in F1 (mono).
        -- Text colors tuned for max contrast: primary `text` on inactive
        -- cells, `textOnAccent` on active cells (the theme's high-contrast
        -- pair designed for readable text on the accent background).
        local name = def.name or "?"
        local clean = tostring(name):gsub("[^%w]+", "")
        local letters = ZeD.upper(clean:sub(1, 2))
        if letters == "" then letters = "?" end
        local font = T.fontF1 or T.fontF3
        local tm = ZeD.TM
        local textW = tm:MeasureStringX(font, letters)
        local textH = tm:getFontHeight(font)
        local tx = x + math.floor((ctx.cellW - textW) / 2)
        local ty = y + math.floor((ctx.cellH - textH) / 2)
        -- S101: inactive cells now always render ink-on-paper for readability
        -- on locked near-white cell bg. Active cells keep theme textOnAccent.
        local lc = flags.isActive and (T.textOnAccent or T.text) or ink
        local alpha = flags.isDisabled and 0.45 or (lc.a or 1)
        panel:drawText(letters, tx, ty, lc.r, lc.g, lc.b, alpha, font)
    end

    -- Disabled stipple overlay (drawn OVER the icon so stipple is visible)
    if flags.isDisabled then
        local stipAlpha = flags.isActive and 0.7 or 0.55
        local stipColor = flags.isActive
            and {r = paper.r, g = paper.g, b = paper.b, a = stipAlpha}
            or  {r = ink.r,   g = ink.g,   b = ink.b,   a = stipAlpha}
        A.drawDisabledStipple(panel, x, y, ctx.cellW, ctx.cellH, stipColor)
    end

    -- Submenu indicator (3×3 corner triangle bottom-right)
    if flags.hasSub then
        local triColor = flags.isActive and paper or ink
        A.drawCornerTri3x3(panel, x + ctx.cellW - ctx.submenuTriSz - T.px(1),
                                   y + ctx.cellH - ctx.submenuTriSz - T.px(1), triColor)
    end

    -- Pin indicator (3×3 corner square top-right)
    if flags.isPinned then
        local pinColor = flags.isActive and paper or ink
        A.drawCornerSq3x3(panel, x + ctx.cellW - ctx.pinDotSz - T.px(1), y + T.px(1), pinColor)
    end
end

-- ---------------------------------------------------------------------------
-- drawContextStrip — the main strip housing + cells + hit zones.
-- state carries the whole _ctx table from the organism:
--   state.items, state.selected, state.pos, state.truncating,
--   state.trackItems (1 or 3 copies), state.trackOriginX (animated offset),
--   state.path, state.target, state.pinnedIds
-- Returns the housing's width/height so the organism can position sibling
-- elements (bumpers, chevrons, label) relative to the strip.
-- ---------------------------------------------------------------------------
function ZeD.Molecules.drawContextStrip(panel, x, y, state, T)
    local ctx = T.ctx
    local A = ZeD.Atoms
    -- S101: strip housing uses LOCKED ink so the 1px gridlines between
    -- paper-white cells read dark-on-white on every theme.
    local ink    = { r = 0.08, g = 0.08, b = 0.08, a = 1 }

    local items = state.items
    local N = #items
    local visibleCount = math.min(N, ctx.maxVisible)
    local innerW = visibleCount * ctx.cellW + math.max(0, visibleCount - 1) * ctx.gap
    local drilled = state.path and #state.path > 0
    local topBorder = drilled and ctx.drilledBorderTop or T.px(1)
    -- Housing = inner (cell row) + 1px left/right + top border + 1px bottom
    local housingW = innerW + T.px(1) * 2
    local housingH = ctx.cellH + topBorder + T.px(1)

    -- Shadow behind everything
    A.drawSteppedShadow(panel, x, y, housingW, housingH, ink)
    -- Ink block fill — this is what makes the 1px gaps between cells appear
    -- as black gridlines "for free" (cells are painted on top with 1px gap)
    panel:drawRect(x, y, housingW, housingH, ink.a or 1, ink.r, ink.g, ink.b)

    -- Interior starts 1px in from left, topBorder px down from top
    local innerX = x + T.px(1)
    local innerY = y + topBorder
    local originX = state.trackOriginX or 0
    local track = state.trackItems or items

    -- Stencil clip to interior so cells sliding past the ends don't leak.
    -- setStencilRect takes panel-LOCAL coordinates (same space innerX/Y live in).
    panel:setStencilRect(innerX, innerY, innerW, ctx.cellH)

    for i, def in ipairs(track) do
        local cx = innerX + originX + (i - 1) * (ctx.cellW + ctx.gap)
        -- Cull cells that fall entirely outside the visible window.
        -- S103: extend the RIGHT buffer to match the LEFT (+cellW) so cells
        -- animating IN from the right edge are drawn during the slide instead
        -- of popping into existence after they reach the viewport. Previously
        -- a bare `cx <= innerX + innerW` check left a cellW-wide blank strip
        -- on the right every time the carousel advanced. Symmetric buffer
        -- also covers slide-out from the left without regressing anything
        -- (stencil clips to [innerX, innerX+innerW] anyway).
        if cx + ctx.cellW >= innerX - ctx.cellW
           and cx <= innerX + innerW + ctx.cellW then
            -- S103: highlight tracks `selected` (mouse-hovered / keyboard
            -- cursor) in BOTH modes. In truncating mode three copies of the
            -- same item exist in the track; matching by (i-1) mod N gives
            -- every visible copy the highlight (only one is ever in the
            -- viewport at a time in practice). Previously tracked `pos`
            -- in truncating mode, but pos is now the carousel scroll offset
            -- (chev / key / bumper advanced only), not the hover target.
            local N_track = #items
            local isActive = (N_track > 0) and (((i - 1) % N_track) + 1 == state.selected) or false
            local flags = {
                isActive   = isActive,
                isBack     = def.isBack,
                isPinned   = def.pinned
                              or (state.pinnedIds and state.pinnedIds[def.id]) or false,
                hasSub     = (def.children ~= nil) and (#def.children > 0),
                isDisabled = def.disabled and def.disabled(state.target) or false,
            }
            ZeD.Molecules.drawContextCell(panel, cx, innerY, def, flags, T)

            -- Hit zones are PANEL-LOCAL (ZeD_Panel convention). Each DOM index
            -- gets its own key so a click maps back to the track position for
            -- precise pos updates (mirrors mockup JS behavior).
            panel:addHitZone("ctxcell_" .. i, cx, innerY, ctx.cellW, ctx.cellH)
        end
    end

    panel:clearStencilRect()

    return housingW, housingH
end

-- ---------------------------------------------------------------------------
-- drawContextBumpers — group-jump bumpers flanking the strip, plus the
-- conditional truncation chevrons. Strip is NOT drawn here — caller draws
-- the strip first and passes its rect in. This molecule paints the chrome
-- on both sides and registers hit zones.
-- Returns {leftEdgeX, rightEdgeX} absolute positions of outermost chrome.
-- ---------------------------------------------------------------------------
function ZeD.Molecules.drawContextBumpers(panel, stripX, stripY, stripW, stripH,
                                          truncating, pressedId, T)
    -- When the strip isn't truncating (≤ 10 items, no carousel scrolling),
    -- there's no need for ANY edge chrome: every cell is directly clickable
    -- in the visible window, and group-jump on a short list with at most one
    -- or two categories is more noise than signal. Bare strip → cleanest.
    if not truncating then
        return stripX, stripX + stripW
    end

    local ctx = T.ctx
    local A = ZeD.Atoms
    local gutter = ctx.gutter
    local chevW = ctx.chevW

    -- S103: outer `<<` / `>>` bumpers removed per design direction — the
    -- single chevrons already handle carousel scrolling; the double-bumper
    -- group-jump was redundant chrome for typical inventory menus. Hit
    -- zones (ctxbump_l / ctxbump_r) removed alongside rendering; any
    -- callers that still reference those ids will no-op silently.
    local leftChevX  = stripX - gutter - chevW
    local rightChevX = stripX + stripW + gutter

    -- Left chev (hit zones are panel-local per ZeD_Panel convention)
    A.drawTruncChevron(panel, leftChevX, stripY, "left", T)
    panel:addHitZone("ctxchev_l", leftChevX, stripY, chevW, stripH)

    -- Right chev
    A.drawTruncChevron(panel, rightChevX, stripY, "right", T)
    panel:addHitZone("ctxchev_r", rightChevX, stripY, chevW, stripH)

    return leftChevX, (rightChevX + chevW)
end

-- ---------------------------------------------------------------------------
-- drawContextFloatingLabel — paper pill floating above the strip. Tracks
-- selected cell X via centerX parameter (computed by organism _layout).
--   text:        current action name (leaf)
--   parentChain: array of parent names for breadcrumb (empty/nil = top level)
-- Renders top-level as single-color, submenu as "Parent > Child > Current"
-- with parents+separators muted, current in full ink.
-- ---------------------------------------------------------------------------
function ZeD.Molecules.drawContextFloatingLabel(panel, centerX, topY,
                                                 text, parentChain, T)
    local A = ZeD.Atoms
    local ink   = T.borderS or T.border
    local paper = T.surf1
    local muted = T.textSec
    local textC = T.text
    local font  = T.fontF1  -- F1 Chrome: Fira Mono Bold
    local tm    = ZeD.TM

    -- Build segments (text + color pairs) — multi-color draw via multiple drawText
    local segments = {}
    if parentChain and #parentChain > 0 then
        for _, pname in ipairs(parentChain) do
            segments[#segments + 1] = {text = pname, color = muted}
            segments[#segments + 1] = {text = " > ", color = muted}
        end
        segments[#segments + 1] = {text = text or "", color = textC}
    else
        segments[#segments + 1] = {text = text or "", color = textC}
    end

    -- Measure total text width
    local totalW = 0
    for _, seg in ipairs(segments) do
        totalW = totalW + tm:MeasureStringX(font, seg.text)
    end

    -- Pill dimensions
    local padH  = T.sp.md  -- 14px horizontal padding inside pill
    local padV  = T.px(3)
    local textH = tm:getFontHeight(font)
    local pillW = totalW + padH * 2
    local pillH = textH + padV * 2
    local pillX = centerX - math.floor(pillW / 2)
    local pillY = topY

    -- Shadow + fill + border
    A.drawSteppedShadow(panel, pillX, pillY, pillW, pillH, ink)
    panel:drawRect(pillX, pillY, pillW, pillH, paper.a or 1, paper.r, paper.g, paper.b)
    panel:drawRectBorder(pillX, pillY, pillW, pillH, ink.a or 1, ink.r, ink.g, ink.b)

    -- Draw segments left-to-right
    local cursorX = pillX + padH
    local textY = pillY + padV
    for _, seg in ipairs(segments) do
        panel:drawText(seg.text, cursorX, textY,
            seg.color.r, seg.color.g, seg.color.b, 1, font)
        cursorX = cursorX + tm:MeasureStringX(font, seg.text)
    end

    -- Downward pointer at pill bottom center
    A.drawContextPointerDown(panel, centerX, pillY + pillH, ink, paper)

    return pillW, pillH
end

-- ---------------------------------------------------------------------------
-- drawContextTargetCard — the static anchor between strip and balloon.
-- Shows item icon tile + name + optional meta field (×count, freshness,
-- condition, etc. — from Registry.getMetaFor). Does NOT track selection X.
-- Caller supplies centerX (mid of the assembly) and topY.
-- ---------------------------------------------------------------------------
function ZeD.Molecules.drawContextTargetCard(panel, centerX, topY,
                                              iconTex, name, meta, T)
    local ctx = T.ctx
    local A = ZeD.Atoms
    local ink   = T.borderS or T.border
    local paper = T.surf1
    local muted = T.textSec
    local textC = T.text
    local nameFont = T.fontF2   -- F2 Body
    local metaFont = T.fontF5   -- F5 Micro
    local tm = ZeD.TM

    local iconSz = ctx.targetIconPx
    local padL, padR, padV = T.px(2), T.px(6), T.px(2)
    local iconToName = T.px(5)
    local nameToSep  = T.px(4)
    local sepToMeta  = T.px(4)

    local nameStr = name or ""
    local metaStr = meta or ""
    local hasMeta = metaStr ~= ""

    local nameW = tm:MeasureStringX(nameFont, nameStr)
    local metaW = hasMeta and tm:MeasureStringX(metaFont, metaStr) or 0

    local contentH = math.max(iconSz, tm:getFontHeight(nameFont))
    local cardH = contentH + padV * 2
    local cardW = padL + iconSz + iconToName + nameW
        + (hasMeta and (nameToSep + T.px(1) + sepToMeta + metaW) or 0) + padR
    local cardX = centerX - math.floor(cardW / 2)
    local cardY = topY

    -- Chrome
    A.drawSteppedShadow(panel, cardX, cardY, cardW, cardH, ink)
    panel:drawRect(cardX, cardY, cardW, cardH, paper.a or 1, paper.r, paper.g, paper.b)
    panel:drawRectBorder(cardX, cardY, cardW, cardH, ink.a or 1, ink.r, ink.g, ink.b)

    -- Icon tile (neutral background + ink border + icon inset)
    local iconX = cardX + padL
    local iconY = cardY + math.floor((cardH - iconSz) / 2)
    local tileBg = T.surf3 or T.surf2
    panel:drawRect(iconX, iconY, iconSz, iconSz,
        tileBg.a or 1, tileBg.r, tileBg.g, tileBg.b)
    panel:drawRectBorder(iconX, iconY, iconSz, iconSz,
        ink.a or 1, ink.r, ink.g, ink.b)
    if iconTex then
        A.drawIcon(panel, iconTex, iconX + T.px(1), iconY + T.px(1), iconSz - T.px(1) * 2, 1, T.iconWhite)
    end

    -- Name
    local nameX = iconX + iconSz + iconToName
    local nameY = cardY + math.floor((cardH - tm:getFontHeight(nameFont)) / 2)
    panel:drawText(nameStr, nameX, nameY,
        textC.r, textC.g, textC.b, 1, nameFont)

    -- Meta (optional, separated by 1px vertical line)
    if hasMeta then
        local sepX = nameX + nameW + nameToSep
        local sepY = cardY + T.px(3)
        local sepH = cardH - T.px(3) * 2
        local sepC = T.border or muted
        panel:drawRect(sepX, sepY, T.px(1), sepH,
            sepC.a or 1, sepC.r, sepC.g, sepC.b)
        local metaX = sepX + sepToMeta
        local metaY = cardY + math.floor((cardH - tm:getFontHeight(metaFont)) / 2)
        panel:drawText(metaStr, metaX, metaY,
            muted.r, muted.g, muted.b, 1, metaFont)
    end

    return cardW, cardH
end

-- ---------------------------------------------------------------------------
-- drawContextBalloon — 230-wide panel under the target card. Upward pointer
-- connects to the card above. Does NOT track selection X — static-centered.
-- state:
--   categoryLabel: "USE" / "CRAFT" / parent name uppercased (if submenu)
--   selectedIdx, itemCount: for "N / Total" readout
--   bodyText: description
--   stateText: availability reason
--   stateKind: "ok" | "bad" — drives dot color
--   isSubmenu: category header accent tint
-- ---------------------------------------------------------------------------
-- Combined info bubble — sits ABOVE the icon strip with a downward pointer
-- toward the strip's selected cell. Subsumes what was previously a separate
-- floating label (action name) AND a balloon (body/state). One piece of chrome,
-- adaptive height: shows the action name always (with breadcrumb in submenus),
-- plus optional body and state rows that collapse when empty.
--   centerX:    horizontal center of the bubble + pointer apex
--   apexY:      where the pointer apex touches the strip top
--   state:      { labelText, parentChain, bodyText, stateText, stateKind,
--                 isSubmenu }
function ZeD.Molecules.drawContextBalloon(panel, centerX, apexY, state, T)
    local A = ZeD.Atoms
    -- The info bubble uses LOCKED System 7 chrome — paper white fill, ink
    -- black border + text — regardless of active theme. Matches the locked
    -- mockup intent (balloon is always white-on-black, like the mockup's
    -- :root --paper / --ink). Theme-driven body text is hard to read on a
    -- forced-white pill, so we hardcode for legibility.
    local ink    = { r = 0,    g = 0,    b = 0,    a = 1 }
    local paper  = { r = 1,    g = 1,    b = 1,    a = 1 }
    local muted  = { r = 0.42, g = 0.42, b = 0.42, a = 1 }
    local textC  = ink                                   -- primary text
    local good   = { r = 0.16, g = 0.49, b = 0.16, a = 1 }   -- darker green readable on white
    local bad    = { r = 0.76, g = 0.16, b = 0.16, a = 1 }   -- darker red readable on white
    local labelFont = T.fontF1   -- F1 Chrome — mono bold (was the floating label font)
    local bodyFont  = T.fontF2   -- F2 Body
    local stateFont = T.fontF5   -- F5 Micro
    local tm = ZeD.TM

    -- Build label segments for breadcrumb support. Top-level: just the action
    -- name in full ink. Submenu: "Parent > Child > Current" with parents and
    -- separators muted, current in full ink.
    local labelText  = state.labelText or ""
    local parentChain = state.parentChain or {}
    local segments = {}
    if #parentChain > 0 then
        for _, pname in ipairs(parentChain) do
            segments[#segments + 1] = { text = pname, color = muted }
            segments[#segments + 1] = { text = " > ", color = muted }
        end
    end
    segments[#segments + 1] = { text = labelText, color = textC }

    -- Decide which extra sections show. Body only renders when it's present
    -- AND differs from labelText (otherwise it'd just duplicate the action
    -- name). State row only renders when there's a reason — gated actions
    -- get a "● Missing X" line, available actions get nothing.
    local rawBody  = state.bodyText
    local hasBody  = rawBody and rawBody ~= "" and rawBody ~= labelText
    local rawState = state.stateText
    local hasState = rawState and rawState ~= ""

    -- Sizing
    local padH       = T.px(10)
    local padV       = T.px(5)
    local rowGap     = T.px(3)
    local dividerGap = T.px(5)
    local maxW       = T.px(250)
    local minW       = T.px(80)

    local labelH = tm:getFontHeight(labelFont)
    local bodyH  = tm:getFontHeight(bodyFont)
    local stateH = tm:getFontHeight(stateFont)

    -- (state.labelPads, the wheels: a quick action chord's two buttons after
    -- the name, as ZeD's pictures, ZeD_PadGlyphs; as words "LB + X" when the
    -- glyph setting draws no pictures)
    local pads = state.labelPads
    local PG = ZeD.PadGlyphs
    local padSet = pads and PG and PG.set()
    local padK = padSet and PG.k(tm:getFontHeight(labelFont)) or 1
    local plusW = tm:MeasureStringX(labelFont, "+")
    local padW = 0
    if pads and padSet then
        padW = T.px(8) + PG.width({ pads[1] }, padK, padSet) + T.px(3) + plusW + T.px(3) + PG.width({ pads[2] }, padK, padSet)
    elseif pads then
        segments[#segments + 1] = { text = "  " .. pads[1] .. " + " .. pads[2], color = muted }
    end

    -- Total label width across all segments
    local labelW = padW
    for _, seg in ipairs(segments) do
        labelW = labelW + tm:MeasureStringX(labelFont, seg.text)
    end

    -- Bubble width: fits label snugly when no extras, expands toward maxW
    -- when body/state need wrapping room.
    local needsWideContent = hasBody or hasState
    local balW
    if needsWideContent and state.snug then
        -- (state.snug, the wheels: as wide as the words, up to maxW; the
        -- strip's descriptions keep the full width)
        local w = labelW
        if hasBody then w = math.max(w, tm:MeasureStringX(bodyFont, rawBody)) end
        if hasState then w = math.max(w, tm:MeasureStringX(stateFont, rawState) + T.px(12)) end
        balW = math.max(minW, math.min(maxW, w + padH * 2))
    elseif needsWideContent then
        balW = maxW
    else
        balW = math.max(minW, math.min(maxW, labelW + padH * 2))
    end
    local innerW = balW - padH * 2

    -- Wrap body and state to inner width
    local wrap = ZeD.Atoms.wrapText
    local bodyLines, stateLines, bodyTotalH, stateTotalH = {}, {}, 0, 0
    if hasBody then
        bodyLines = (wrap and wrap(rawBody, bodyFont, innerW)) or { rawBody }
        bodyTotalH = #bodyLines * bodyH
    end
    if hasState then
        stateLines = (wrap and wrap(rawState, stateFont, innerW - T.px(10))) or { rawState }
        stateTotalH = #stateLines * stateH
    end

    -- Compute height — label always shown, body/state appended conditionally
    local balH = padV + labelH + padV
    if hasBody then
        balH = balH + rowGap + bodyTotalH
    end
    if hasState then
        balH = balH + dividerGap + T.px(1) + rowGap + stateTotalH
    end

    -- Position — direction set by state.pointerDir ("down" = default; bubble
    -- ABOVE strip with downward tail. "up" = bubble BELOW strip with upward
    -- tail; used when there isn't enough room above the cursor).
    local pointerH = T.px(3)
    local pointerDir = state.pointerDir or "down"
    local balX = centerX - math.floor(balW / 2)
    local balY
    if pointerDir == "up" then
        balY = apexY + pointerH       -- bubble starts pointerH below the apex
    else
        balY = apexY - pointerH - balH    -- bubble extends UP from apexY
    end

    -- Chrome — shadow, fill, border
    A.drawSteppedShadow(panel, balX, balY, balW, balH, ink)
    panel:drawRect(balX, balY, balW, balH, paper.a or 1, paper.r, paper.g, paper.b)
    panel:drawRectBorder(balX, balY, balW, balH, ink.a or 1, ink.r, ink.g, ink.b)

    -- Pointer — at the apex side of the bubble (top for "up", bottom for "down")
    if pointerDir == "up" then
        A.drawContextPointerUp(panel, centerX, balY - pointerH, ink, paper)
    else
        A.drawContextPointerDown(panel, centerX, balY + balH, ink, paper)
    end

    local y = balY + padV

    -- Label row (centered horizontally, multi-segment for breadcrumb)
    local cursorX = balX + math.floor((balW - labelW) / 2)
    for _, seg in ipairs(segments) do
        panel:drawText(seg.text, cursorX, y,
            seg.color.r, seg.color.g, seg.color.b, 1, labelFont)
        cursorX = cursorX + tm:MeasureStringX(labelFont, seg.text)
    end
    if padW > 0 then
        cursorX = cursorX + T.px(8)
        cursorX = cursorX + PG.draw(panel, { pads[1] }, cursorX, y, labelH, padK, padSet) + T.px(3)
        panel:drawText("+", cursorX, y, muted.r, muted.g, muted.b, 1, labelFont)
        cursorX = cursorX + plusW + T.px(3)
        PG.draw(panel, { pads[2] }, cursorX, y, labelH, padK, padSet)
    end
    y = y + labelH

    -- Body (left-aligned, wrapped)
    if hasBody then
        y = y + rowGap
        for _, line in ipairs(bodyLines) do
            panel:drawText(line, balX + padH, y,
                textC.r, textC.g, textC.b, 1, bodyFont)
            y = y + bodyH
        end
    end

    -- State row (preceded by dashed divider)
    if hasState then
        y = y + dividerGap
        local dashX, dashEndX = balX + padH, balX + balW - padH
        while dashX < dashEndX do
            local dashW = math.min(T.px(4), dashEndX - dashX)
            panel:drawRect(dashX, y, dashW, T.px(1),
                muted.a or 0.6, muted.r, muted.g, muted.b)
            dashX = dashX + T.px(6)
        end
        y = y + T.px(1) + rowGap

        local dotC = (state.stateKind == "bad") and bad or good
        local dotSz = T.px(4)
        local dotY = y + math.floor((stateH - dotSz) / 2)
        A.drawStatusDot(panel, balX + padH, dotY, dotC, dotSz)
        local textOffset = dotSz + T.px(6)
        for _, line in ipairs(stateLines) do
            panel:drawText(line, balX + padH + textOffset, y,
                muted.r, muted.g, muted.b, 1, stateFont)
            y = y + stateH
        end
    end

    return balW, balH + pointerH
end

-- ============================================================================
-- STATUS CHIP (S115 — radio chassis VFD/LCD)
-- Text-only on/off chip drawn directly onto a chassis display surface.
-- "● TEXT" when on, "○ TEXT" when off — the bullet glyph carries the state and
-- the text label says what the state is ABOUT (SIG, 2W, AM, FM). No bg, no
-- border — the display substrate (T.radio.vfd.bg or T.radio.lcd.bg) shows
-- through. Caller positions x, y; molecule advances no internal cursor.
--
-- Used inside radioMainDisplay (status chip row above the BATT/VOL bars).
-- Per feedback_status_dot_over_color.md: prefer ●/○ over color-only signaling
-- so colorblind users can still read state from glyph shape alone.
--
-- @return widthDrawn (px) so caller can lay out a chip row left-to-right.
-- ============================================================================
function ZeD.Molecules.drawStatusChip(panel, x, y, text, on, onColor, offColor, font)
    local T = ZeD.T
    font = font or T.fontF1
    local color = on and onColor or offColor
    if not color then return 0 end

    -- The Fira font set in this mod doesn't carry the Unicode bullet glyphs
    -- ●/○ — they render as `?` placeholders. Paint a real square via drawRect
    -- aligned to the text baseline so the chip is font-independent.
    local TM   = ZeD.TM
    local fh   = TM:getFontHeight(font)
    local sqSz = math.max(T.px(6), math.floor(fh * 0.55))
    local sqY  = y + math.floor((fh - sqSz) / 2)
    local sqX  = x

    if on then
        panel:drawRect(sqX, sqY, sqSz, sqSz, color.a or 1.0, color.r, color.g, color.b)
    else
        -- 1px outlined square (off state) — transparent center.
        panel:drawRectBorder(sqX, sqY, sqSz, sqSz, color.a or 1.0, color.r, color.g, color.b)
    end

    -- Label follows the indicator with a 4px gap.
    local labelX = sqX + sqSz + T.px(4)
    panel:drawText(text, labelX, y, color.r, color.g, color.b, color.a or 1.0, font)
    local labelW = TM:MeasureStringX(font, text)
    return (sqSz + T.px(4) + labelW)
end

-- ============================================================================
-- DRAWER INTERNAL HEADER (S115 — first contextual drawer header pattern)
-- A 22px-tall strip at the top of a contextual drawer containing browse
-- controls + subtitle + location tag. First appearance of this pattern;
-- explicitly designed to be reused by every future contextual drawer
-- (washer, generator, oven, sink — anything with N reachable instances).
--
-- Layout left-to-right:
--   [<] [tag: Location (idx)] [>]  subtitle
--
-- - Browse keys are icon buttons with left / right triangles (cohesion spec 7),
--   their names as hints.
-- - The location is a tag (the one look for a small word naming a state).
-- - Subtitle is the current instance's display name (from engine getter).
--
-- This molecule is RENDER-ONLY this session (S115a). Browse arrow click
-- handlers are S115b — caller does NOT need to wire them yet, the buttons
-- paint as visually-clickable but no-op. browseState.idx and .total are read
-- to render the counter; nothing in this draw path mutates them.
--
-- @param panel       ISPanel
-- @param x, y        Top-left of the 22px strip in panel-local coords
-- @param w           Total width
-- @param browseState { idx, total } — current instance index (1-based) + count
-- @param subtitle    String — current instance display name
-- @param locationTag String — "Floor" / "Primary" / "Back" / etc.
-- @param rightReserve px kept clear at the strip's right end for the caller's own button (the subtitle stops short)
-- @param opts        optional { focusId = "prev" / "next" (with focus = its mark opts) or
--                    focusParts = { prev = ..., next = ... }: the browse key with the
--                    controller's focus (the mark goes under its triangle); prevHover /
--                    nextHover (nil: the pointer is tested here); win }
-- ============================================================================
local _drawerPrev, _drawerNext = { id = "drawerPrev" }, { id = "drawerNext" }
local function drawPrevGlyph(p, x, y, s, c)
    local t = math.max(ZeD.T.px(6), math.floor(s * 0.6))
    ZeD.Atoms.drawTriangleLeft(p, x + math.floor((s - t) / 2), y + math.floor((s - t) / 2), t, c)
end
local function drawNextGlyph(p, x, y, s, c)
    local t = math.max(ZeD.T.px(6), math.floor(s * 0.6))
    ZeD.Atoms.drawTriangleRight(p, x + math.floor((s - t) / 2), y + math.floor((s - t) / 2), t, c)
end
function ZeD.Molecules.drawDrawerInternalHeader(panel, x, y, w, browseState, subtitle, locationTag, rightReserve, opts)
    local T = ZeD.T
    if not T then return end
    local TM = ZeD.TM
    opts = opts or NO_OPTS

    -- ZeD.Spacing.tabHeaderH is the canonical drawer-header strip height
    -- shared across the mod (Health / Equipment-Defense / Thermal / Identity
    -- / Skills / Maps toolbar / Radio drawer header).
    local stripH    = T.px((ZeD.Spacing and ZeD.Spacing.tabHeaderH) or 37)
    local btnSize   = math.min(T.buttonH, stripH - T.px(6))
    local btnGap    = T.px(6)
    local pad       = T.px(10)
    local pillH     = T.px(16)    -- the tag's height
    local fontHead  = T.fontF2   -- sans for subtitle

    -- No bg paint — the drawer panel behind us already provides the surface.
    -- (Project rule: avoid adding redundant backgrounds; use the parent's.)
    -- Just the 1px groove separating the header from the chassis below.
    local groove = T.borderS or { r = 0.22, g = 0.22, b = 0.22, a = 1.0 }
    panel:drawRect(x, y + stripH - T.px(1), w, T.px(1), groove.a or 1.0, groove.r, groove.g, groove.b)

    local btnY = y + math.floor((stripH - btnSize) / 2)
    local pillY = y + math.floor((stripH - pillH) / 2)

    -- ============ Left edge: [<] [pill: Location (idx)] [>] ============
    -- The location pill now sits BETWEEN the browse arrows. Pill text format
    -- "<location> (<idx>)" e.g. "Primary (1)" or "Floor (2)". The (idx) shows
    -- which radio in the cycle is current; replaces the old N/M counter.
    local idx     = (browseState and browseState.idx) or 1
    local pillText = (locationTag and locationTag ~= "") and locationTag or "-"
    pillText = pillText .. " (" .. tostring(idx) .. ")"

    local A = ZeD.Atoms
    local cursor = x + pad

    -- Left arrow — stash rect for caller's hit testing
    local prevZone = { x = cursor, y = btnY, w = btnSize, h = btnSize }
    if opts.prevHover ~= nil then _drawerPrev.hover = opts.prevHover
    else _drawerPrev.hover = A.mouseIn(panel, cursor, btnY, btnSize, btnSize) end
    _drawerPrev.hint = ZeD.tr("UI_ZeD_Drawer_Prev")
    _drawerPrev.focus, _drawerPrev.win = partFocus(opts, "prev"), opts.win
    ZeD.Molecules.drawIconButton(panel, cursor, btnY, btnSize, drawPrevGlyph, _drawerPrev)
    cursor = cursor + btnSize + btnGap

    -- The location: a tag
    local pillW = ZeD.Molecules.drawTag(panel, cursor, pillY, pillText, nil)
    cursor = cursor + pillW + btnGap

    -- Right arrow — stash rect for caller's hit testing
    local nextZone = { x = cursor, y = btnY, w = btnSize, h = btnSize }
    if opts.nextHover ~= nil then _drawerNext.hover = opts.nextHover
    else _drawerNext.hover = A.mouseIn(panel, cursor, btnY, btnSize, btnSize) end
    _drawerNext.hint = ZeD.tr("UI_ZeD_Drawer_Next")
    _drawerNext.focus, _drawerNext.win = partFocus(opts, "next"), opts.win
    ZeD.Molecules.drawIconButton(panel, cursor, btnY, btnSize, drawNextGlyph, _drawerNext)
    cursor = cursor + btnSize + pad

    -- ============ Subtitle (item display name, free-form text) ============
    -- Sans body color, title-case as engine returns it (no upper-casing —
    -- it's the item's display name, not branding).
    local subStr = subtitle or ""
    local subY = y + math.floor((stripH - TM:getFontHeight(fontHead)) / 2)
    local subColor = T.text or { r = 1, g = 1, b = 1, a = 1 }
    local subMaxW = (x + w - pad - (rightReserve or 0)) - cursor
    if subMaxW > 0 and subStr ~= "" then
        local subW = TM:MeasureStringX(fontHead, subStr)
        if subW > subMaxW then
            local ell = "…"
            local ellW = TM:MeasureStringX(fontHead, ell)
            local trimmed = subStr
            while #trimmed > 1 and (TM:MeasureStringX(fontHead, trimmed) + ellW) > subMaxW do
                trimmed = trimmed:sub(1, #trimmed - 1)
            end
            subStr = trimmed .. ell
        end
        panel:drawText(subStr, cursor, subY,
            subColor.r, subColor.g, subColor.b, subColor.a or 1.0, fontHead)
    end

    -- Return browse-button rects so the contextual-drawer caller can hit-test
    -- them in its onClick handler. The molecule itself stays click-agnostic
    -- so any future contextual drawer can reuse it identically.
    return prevZone, nextZone
end

-- ============================================================================
-- GLYPH PROMPTS — a controller legend: each button's name boxed, then what it
-- does (the window footers' prompt look, ZeD_Window:render). Used by the
-- prompt (ZeD_Prompt.lua) and the keyboard (ZeD_Keyboard.lua).
-- prompts = { "D-PAD Move", { glyph = "A", label = "Press" }, ... }: a plain
-- string is a dim note. Draws left to right from x, centred in a strip of
-- height h at y. Returns the right edge.
-- A button is drawn as ZeD's pixel picture of it (ZeD_PadGlyphs; director,
-- Oct 24 2026) when the glyph names one (or `pad` gives its roles), and as
-- the boxed name when the glyph setting is Keyboard/mouse or Off.
-- ============================================================================
function ZeD.Molecules.drawGlyphPrompts(panel, x, y, h, prompts)
    local T = ZeD.T
    local tm = ZeD.TM
    local font = T.fontF5
    local fh = tm:getFontHeight(font)
    local box = h - T.px(4)
    local textY = y + math.floor((h - fh) / 2)
    local bs, tc, td = T.borderS, T.text, T.textDim
    local PG = ZeD.PadGlyphs
    local set = PG and PG.set()
    local k = PG and PG.k(box) or 1
    for _, p in ipairs(prompts or {}) do
        local roles = (type(p) == "table" and set) and (p.pad or PG.roles(p.glyph)) or nil
        if type(p) == "string" then
            panel:drawText(p, x, textY, td.r, td.g, td.b, td.a or 1, font)
            x = x + tm:MeasureStringX(font, p) + T.sp.sm * 2
        elseif roles then
            local gw = PG.width(roles, k, set)
            if panel.drawRect then PG.draw(panel, roles, x, y, h, k, set) end
            panel:drawText(p.label, x + gw + T.px(3), textY, td.r, td.g, td.b, td.a or 1, font)
            x = x + gw + T.px(3) + tm:MeasureStringX(font, p.label) + T.sp.sm * 2
        else
            local gw = tm:MeasureStringX(font, p.glyph)
            local bw = math.max(box, gw + T.px(4))
            panel:drawRectBorder(x, y + T.px(2), bw, box, bs.a or 1, bs.r, bs.g, bs.b)
            panel:drawText(p.glyph, x + math.floor((bw - gw) / 2), textY, tc.r, tc.g, tc.b, tc.a or 1, font)
            panel:drawText(p.label, x + bw + T.px(3), textY, td.r, td.g, td.b, td.a or 1, font)
            x = x + bw + T.px(3) + tm:MeasureStringX(font, p.label) + T.sp.sm * 2
        end
    end
    return x
end

-- ============================================================================
-- COHESION PIECES (cohesion spec 8 and 9)
-- The shared parts every surface moves onto: the tag, the band at the foot of a
-- pane (and the question it asks before an act that cannot be undone), the
-- NEEDS line, the empty-list line, and the detail card.
-- ============================================================================

--- A tag: 16u, a 1u borderS outline, F1, sentence case, 5u side padding, and a
-- 6u square status mark inside before the word when statusColor is given.
-- opts as ZeD.Atoms.drawTag ({ font, h, minW, keepCase, alpha, hollow, textColor }).
-- @return width, height
function ZeD.Molecules.drawTag(panel, x, y, text, statusColor, opts)
    return ZeD.Atoms.drawTag(panel, x, y, text, statusColor, opts)
end

-- ----------------------------------------------------------------------------
-- THE BAND
-- At the foot of a pane: the screen's own actions (Create zone, Mark all read,
-- Transfer all...) and every answer to a question. Surface 2 drawn without
-- stacking on the body, a 1u structure line on top. Left: a status or question
-- line (a square mark and F2 words); icon actions, when it carries them, also sit
-- at the left. Right: the push buttons, the main one last, T.px(8) apart and
-- from the edges.
-- ----------------------------------------------------------------------------

--- The band's height: T.buttonH + 2 x T.px(5).
function ZeD.Molecules.bandH()
    local T = ZeD.T
    return T.buttonH + 2 * T.px(5)
end

--- Draw the band with its top-left at (x, y) (y = the pane's bottom - M.bandH()).
-- spec = {
--   status   = { text = "...", color = T.positive } -- the left line: square mark + F2 words
--   question = "Take the campfire apart? The fire is lost." -- the left line with a red mark
--   buttons  = { { label = "Cancel" }, { label = "Take apart", variant = "danger" } }
--              each: label, variant ("primary" / "danger" / nil), disabled, pressed,
--              hover (nil: the pointer is tested here), focus (ZeD.Focus.mark opts,
--              when it has the controller's focus), help, id, minW (px), w (px: exactly
--              this wide, a button that fills the room left); main one LAST
--   icons    = { { icon = <Texture or draw fn>, active, disabled, hover, focus, hint, help, id } }
--   check    = { label, on, hover (nil: tested here), focus (mark opts), disabled, help, id }:
--              a System 7 checkbox and its words at the left, after the icons ("Show popups")
--   win      = the window (help and hints; default: the window the panel is in)
--   noLine   = true leaves out the structure line (a band right under another line)
-- }
-- @return height, rects = { buttons = { [i] = {x, y, w, h, id} }, icons = { ... }, check = {x, y, w, h, id} }
local _bandBtn, _bandIcon = {}, {}

-- the band's checkbox and its words from x; returns its rect
local function drawBandCheck(panel, x, by, bh, c, win)
    local T, A, tm = ZeD.T, ZeD.Atoms, ZeD.TM
    local f2 = T.fontF2
    local cb = T.checkboxSz
    local label = tostring(c.label or "")
    local cw = cb + T.px(6) + tm:MeasureStringX(f2, label)
    local hover = c.hover
    if hover == nil then hover = A.mouseIn(panel, x, by, cw, bh) end
    hover = hover and not c.disabled
    local onFocus = false
    if c.focus and ZeD.Focus and ZeD.Focus.mark then
        local f = c.focus
        if f == true then _partFocus.win = win; f = _partFocus end
        onFocus = ZeD.Focus.mark(panel, x - T.px(2), by, cw + T.px(4), bh, f) and true or false
    end
    A.drawCheckbox(panel, x, by + math.floor((bh - cb) / 2), c.on and true or false, hover, c.disabled)
    local tc = onFocus and T.textOnFocus or T.text
    local a = (tc.a or 1) * (c.disabled and T.disabledAlpha or 1)
    panel:drawText(label, x + cb + T.px(6), by + math.floor((bh - tm:getFontHeight(f2)) / 2), tc.r, tc.g, tc.b, a, f2)
    if hover and c.help then
        local H = ZeD.Help
        if H and H.set then H.set(win or panel, c.help) end
    end
    return { x = x, y = by, w = cw, h = bh, id = c.id }
end
function ZeD.Molecules.drawBand(panel, x, y, w, spec)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    spec = spec or NO_OPTS
    local H = M.bandH()
    local edge, gap = T.px(8), T.px(8)
    local bh = T.buttonH
    local by = y + T.px(5)
    local out = { buttons = {}, icons = {} }

    A.surfaceFill(panel, x, y, w, H, "surf2")
    if not spec.noLine then A.drawDividerH(panel, x, y, w, true) end

    -- the push buttons, right to left (the main one, last in the list, at the right)
    local right = x + w - edge
    local buttons = spec.buttons
    if buttons then
        for i = #buttons, 1, -1 do
            local b = buttons[i]
            local bw = b.w or math.max(M.buttonW(b.label), b.minW or 0)
            right = right - bw
            local o = _bandBtn
            o.disabled, o.focus, o.help, o.win = b.disabled, b.focus, b.help, spec.win
            if b.hover ~= nil then o.hover = b.hover else o.hover = A.mouseIn(panel, right, by, bw, bh) end
            M.drawButton(panel, right, by, bw, bh, b.label, b.variant or "default", b.pressed, nil, o)
            out.buttons[i] = { x = right, y = by, w = bw, h = bh, id = b.id }
            right = right - gap
        end
    end

    -- the icon actions, left to right
    local left = x + edge
    local icons = spec.icons
    if icons then
        for i, ic in ipairs(icons) do
            local o = _bandIcon
            o.active, o.disabled, o.focus, o.hint, o.help, o.id, o.win =
                ic.active, ic.disabled, ic.focus, ic.hint, ic.help, ic.id, spec.win
            if ic.hover ~= nil then o.hover = ic.hover else o.hover = A.mouseIn(panel, left, by, bh, bh) end
            M.drawIconButton(panel, left, by, bh, ic.icon, o)
            out.icons[i] = { x = left, y = by, w = bh, h = bh, id = ic.id }
            left = left + bh + T.px(4)
        end
        if #icons > 0 then left = left - T.px(4) + gap end
    end

    -- the checkbox and its words, after the icons
    if spec.check then
        local r = drawBandCheck(panel, left, by, bh, spec.check, spec.win)
        out.check = r
        left = left + r.w + gap
    end

    -- the status / question line, in the room between
    local line, mark = nil, nil
    if spec.question then
        line, mark = spec.question, T.danger
    elseif spec.status then
        line, mark = spec.status.text, spec.status.color
    end
    if line and line ~= "" then
        local f2 = T.fontF2
        local sq = T.px(6)
        local tx = left
        if mark then
            A.drawStatusDot(panel, left, y + math.floor((H - sq) / 2), mark, sq)
            tx = left + sq + T.px(6)
        end
        local room = right - tx
        if room > 0 then
            local s = A.truncateText(line, f2, room)
            local tc = T.text
            panel:drawText(s, tx, y + math.floor((H - ZeD.TM:getFontHeight(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        end
    end
    return H, out
end

--- The question before an act that cannot be undone, as a band (cohesion spec 9):
-- "<Verb> the <thing>? <What is lost>." with a red square mark, then Cancel and
-- the verb's own word (danger when it can't be undone, primary otherwise).
-- opts = { danger = true (default) / false, cancelFocus / verbFocus (mark opts),
--          cancelHelp, verbHelp, win }
-- @return height, cancelRect, verbRect
local _qButtons = { {}, {} }
local _qSpec = { buttons = _qButtons }
function ZeD.Molecules.drawQuestionBand(panel, x, y, w, question, verb, opts)
    opts = opts or NO_OPTS
    local c, v = _qButtons[1], _qButtons[2]
    c.label, c.variant, c.focus, c.help, c.id = ZeD.tr("UI_Cancel"), "default", opts.cancelFocus, opts.cancelHelp, "cancel"
    v.label, v.focus, v.help, v.id = verb, opts.verbFocus, opts.verbHelp, "verb"
    v.variant = (opts.danger == false) and "primary" or "danger"
    _qSpec.question, _qSpec.win = question, opts.win
    local H, out = ZeD.Molecules.drawBand(panel, x, y, w, _qSpec)
    return H, out.buttons[1], out.buttons[2]
end

-- ----------------------------------------------------------------------------
-- NEEDS LINE and EMPTY LINE
-- ----------------------------------------------------------------------------

-- the lines of a paragraph wrapped to w (a fresh table; these draw while shown)
local function wrapped(text, font, w)
    return ZeD.Atoms.wrapText(text or "", font, math.max(1, w))
end

--- One NEEDS line under the verb row: a hollow 6u square, then
-- "<Verb> needs <what>." in F2 (T.text), wrapped to the width.
-- @return height
function ZeD.Molecules.drawNeedsLine(panel, x, y, w, text)
    local T = ZeD.T
    local A = ZeD.Atoms
    local f2 = T.fontF2
    local fh = ZeD.TM:getFontHeight(f2)
    local sq = T.px(6)
    local tx = x + sq + T.px(6)
    A.drawStatusHollow(panel, x, y + math.floor((fh - sq) / 2), T.textDim, sq)
    local lines = wrapped(text, f2, x + w - tx)
    local tc = T.text
    local step = fh + T.px(2)
    for i, s in ipairs(lines) do
        panel:drawText(s, tx, y + (i - 1) * step, tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
    return math.max(0, #lines * step - T.px(2))
end

--- The line an empty list shows: F2 in T.textDim, left-aligned, wrapped to the
-- width (a full sentence: "No animal zones yet."). The caller places it at the
-- list's text inset, 8u below its header.
-- @return height
function ZeD.Molecules.drawEmptyLine(panel, x, y, w, text)
    local T = ZeD.T
    local f2 = T.fontF2
    local fh = ZeD.TM:getFontHeight(f2)
    local tc = T.textDim
    local step = fh + T.px(2)
    local lines = wrapped(text, f2, w)
    for i, s in ipairs(lines) do
        panel:drawText(s, x, y + (i - 1) * step, tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
    return math.max(0, #lines * step - T.px(2))
end

-- ----------------------------------------------------------------------------
-- HOVER BOXES: the hint (ZeD.Atoms.drawHintBox) and the detail card
-- ----------------------------------------------------------------------------

--- The one-line hint for an anchor point (the pointer) in panel space.
function ZeD.Molecules.drawHint(panel, text, ax, ay)
    return ZeD.Atoms.drawHintBox(panel, text, ax, ay)
end

-- a detail card line's font
local function cardFont(T, f)
    if f == "F3" then return T.fontF3 end
    if f == "F1" then return T.fontF1 end
    if f ~= nil and type(f) ~= "string" then return f end
    return T.fontF2
end

--- The detail card: a title in F4, then lines in F2 (words) or F3 (figures), on
-- surface 1, solid, with a 1u frame and the hard shadow, wrapped to its width.
-- card = {
--   title = "Baseball Bat",
--   lines = { "Two-handed, pushes zombies back.", { text = "2.0 kg", font = "F3", color = T.textDim }, ... },
--   maxW  = the widest it gets, in design units (default 260),
--   exact = true: (ax, ay) is the card's top-left; else it is the pointer and the
--           card goes below-right of it, flipped to stay on screen
-- }
-- Usually asked for with ZeD.Atoms.requestDetailCard(win, key, card) (shown after
-- the shared delay by the window's overlay pass); this draws it now.
-- @return x, y, w, h
function ZeD.Molecules.drawDetailCard(panel, ax, ay, card)
    if not card then return end
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local padX, padY, lgap = T.px(10), T.px(8), T.px(2)
    local maxW = T.px(card.maxW or 260)
    local innerMax = maxW - padX * 2
    local f4 = T.fontF4
    local rows, widest, h = {}, 0, padY * 2
    if card.title and card.title ~= "" then
        for _, s in ipairs(wrapped(card.title, f4, innerMax)) do
            rows[#rows + 1] = { s = s, f = f4, c = T.textHead }
            widest = math.max(widest, tm:MeasureStringX(f4, s))
            h = h + tm:getFontHeight(f4) + lgap
        end
        if card.lines and #card.lines > 0 then h = h + T.px(4); rows[#rows + 1] = { gap = T.px(4) } end
    end
    for _, ln in ipairs(card.lines or NO_OPTS) do
        local text, f, c = ln, T.fontF2, T.text
        if type(ln) == "table" then text, f, c = ln.text, cardFont(T, ln.font), ln.color or T.text end
        for _, s in ipairs(wrapped(text, f, innerMax)) do
            rows[#rows + 1] = { s = s, f = f, c = c }
            widest = math.max(widest, tm:MeasureStringX(f, s))
            h = h + tm:getFontHeight(f) + lgap
        end
    end
    h = h - lgap
    local w = math.min(maxW, widest + padX * 2)
    local x, y = ax, ay
    if not card.exact then x, y = A.hoverBoxPlace(panel, ax, ay, w, h) end
    A.drawHoverShell(panel, x, y, w, h)
    local cy = y + padY
    for _, r in ipairs(rows) do
        if r.gap then
            cy = cy + r.gap
        else
            local c = r.c
            panel:drawText(r.s, x + padX, cy, c.r, c.g, c.b, c.a or 1, r.f)
            cy = cy + tm:getFontHeight(r.f) + lgap
        end
    end
    return x, y, w, h
end

-- ============================================================================
-- CONDITIONAL DISCLOSURE (director, Oct 26 2026)
-- Actions the player cannot do yet are folded away so the verb row stays short,
-- with one folded row after the verbs that keeps them discoverable:
--   "With scissors you could cut your hair."   (one hidden action)
--   "3 more with the right things"              (several)
-- Opening it (a click, or A on it: it is a focus stop) shows the hidden actions
-- greyed, each with its NEEDS line. Open / closed is remembered per key for the
-- session. ZeD setup's hiddenActions picks the behaviour: "folded" (default),
-- "all" (every sensible action shown, the ones you cannot do greyed with their
-- NEEDS lines) or "hide" (no folded row at all).
--
-- A hint must only ever name things the game itself would show the player (a
-- recipe they know, an entry of the game's own menus): never a recipe they have
-- not learned or an action the game keeps secret. Choosing what goes in `needs`
-- and `hint` is the caller's job.
-- ============================================================================

ZeD.Disclose = ZeD.Disclose or {}
local DS = ZeD.Disclose
DS.open = DS.open or {}   -- [key] = true: that folded row is open (this session only)

--- The hiddenActions setting: "folded" (default), "all" or "hide".
function DS.setting()
    local S = ZeD.Settings
    local v = S and S.hiddenActions and S.hiddenActions() or "folded"
    if v ~= "all" and v ~= "hide" then v = "folded" end
    return v
end

--- Sort a surface's verbs. Each verb: { label, canDo = bool, needs = "scissors"
-- (plain words), sensible = false when it makes no sense now (Put out on a dead
-- fire), hint = "cut your hair" (the "you could ..." words), ... }.
-- Not-sensible verbs are dropped. Returns shown, hidden:
--   "folded": shown = the ones you can do, hidden = the rest
--   "all":    shown = every sensible one (draw the ones with canDo false greyed,
--             each with its NEEDS line), hidden = {}
--   "hide":   shown = the ones you can do, hidden = {}
-- setting: optional, default DS.setting().
function DS.split(verbs, setting)
    setting = setting or DS.setting()
    local shown, hidden = {}, {}
    for _, v in ipairs(verbs or NO_OPTS) do
        if v.sensible ~= false then
            if v.canDo or setting == "all" then
                shown[#shown + 1] = v
            elseif setting == "folded" then
                hidden[#hidden + 1] = v
            end
        end
    end
    return shown, hidden
end

function DS.isOpen(key) return key ~= nil and DS.open[key] == true end
function DS.setOpen(key, open) if key ~= nil then DS.open[key] = open and true or nil end end
--- Open / fold the row for key (its click and its A press call this).
function DS.toggle(key) DS.setOpen(key, not DS.isOpen(key)) end

--- A verb's NEEDS line: its own needsLine when it has one, else "<Verb> needs <needs>."
function DS.needsLine(v)
    if v.needsLine then return v.needsLine end
    return ZeD.tr("UI_ZeD_Disclose_Needs", ZeD.btnCase(v.label or ""), v.needs or "")
end

--- The folded row's words: one hidden action names what it needs ("With scissors you
-- could cut your hair."); several, or one whose needs are not given, say how many.
function DS.rowText(hidden)
    if #hidden == 1 then
        local v = hidden[1]
        local needs = v.needs and tostring(v.needs) or ""
        if needs ~= "" then
            return ZeD.tr("UI_ZeD_Disclose_One", needs, v.hint or ZeD.btnCase(v.label or ""))
        end
    end
    return ZeD.tr("UI_ZeD_Disclose_Many", #hidden)
end

-- the height of a NEEDS line wrapped to w (as drawNeedsLine draws it)
local function needsLineH(x, w, text)
    local T = ZeD.T
    local f2 = T.fontF2
    local fh = ZeD.TM:getFontHeight(f2)
    local tx = x + T.px(6) + T.px(6)
    local n = #wrapped(text, f2, x + w - tx)
    return math.max(0, n * (fh + T.px(2)) - T.px(2))
end

--- The folded row after the verbs, and when open the hidden actions under it.
-- @param hidden  the hidden list from ZeD.Disclose.split (nothing drawn when empty)
-- @param key     remembers open / closed for the session (e.g. "campfire")
-- @param opts    optional { hover (nil: the pointer is tested here), focus (the
--                ZeD.Focus.mark opts when the row has the controller's focus),
--                inset (text inset px, default 0), win,
--                closedOnly = true: only the row itself (its triangle still shows
--                open or shut; a caller that lays out the open block itself),
--                measure = true: nothing drawn, only the sizes (as measureMoreRow) }
--                Each hidden verb may carry hover / focus / help for its greyed
--                push button, as the band's buttons do.
-- @return height, rowRect {x, y, w, h} (the click / focus stop), verbRects
--         ({ [i] = {x, y, w, h} } of the greyed buttons; empty when folded)
local _moreBtn = {}
function ZeD.Molecules.drawMoreRow(panel, x, y, w, hidden, key, opts)
    if not hidden or #hidden == 0 then return 0, nil, {} end
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    opts = opts or NO_OPTS
    local draw = not opts.measure
    local f2 = T.fontF2
    local fh = ZeD.TM:getFontHeight(f2)
    local rowH = math.max(T.px(20), fh + T.px(6))
    local open = DS.isOpen(key)
    local cx = x + (opts.inset or 0)
    local tri = T.px(8)
    if draw then
        local hover = opts.hover
        if hover == nil then hover = A.mouseIn(panel, x, y, w, rowH) end
        if hover then
            local hv = T.hover
            panel:drawRect(x, y, w, rowH, hv.a, hv.r, hv.g, hv.b)
        end
        local onFocus = false
        if opts.focus and ZeD.Focus and ZeD.Focus.mark then
            onFocus = ZeD.Focus.mark(panel, x, y, w, rowH, opts.focus)
        end
        local tc = onFocus and T.textOnFocus or T.textDim
        local ty = y + math.floor((rowH - tri) / 2)
        if open then A.drawTriangleDown(panel, cx, ty, tri, tc) else A.drawTriangleRight(panel, cx, ty, tri, tc) end
        local text = A.truncateText(DS.rowText(hidden), f2, x + w - (cx + tri + T.px(6)))
        panel:drawText(text, cx + tri + T.px(6), y + math.floor((rowH - fh) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
    cx = cx + tri + T.px(6)
    local rowRect = { x = x, y = y, w = w, h = rowH }
    local verbRects = {}
    if not open or opts.closedOnly then return rowH, rowRect, verbRects end

    -- open: the hidden verbs as greyed push buttons, then one NEEDS line each
    local h = rowH + T.px(4)
    local bh = T.buttonH - T.px(4)
    local bx = cx
    for i, v in ipairs(hidden) do
        local bw = M.buttonW(v.label)
        if bx + bw > x + w and bx > cx then bx = cx; h = h + bh + T.px(4) end
        if draw then
            local o = _moreBtn
            o.disabled, o.focus, o.help, o.win = true, v.focus, v.help, opts.win
            if v.hover ~= nil then o.hover = v.hover else o.hover = A.mouseIn(panel, bx, y + h, bw, bh) end
            M.drawButton(panel, bx, y + h, bw, bh, v.label, v.danger and "danger" or "default", false, nil, o)
        end
        verbRects[i] = { x = bx, y = y + h, w = bw, h = bh }
        bx = bx + bw + T.px(8)
    end
    h = h + bh + T.px(6)
    for _, v in ipairs(hidden) do
        local line = DS.needsLine(v)
        if draw then
            h = h + M.drawNeedsLine(panel, cx, y + h, x + w - cx, line) + T.px(4)
        else
            h = h + needsLineH(cx, x + w - cx, line) + T.px(4)
        end
    end
    return h, rowRect, verbRects
end

--- The height drawMoreRow takes at width w (open or shut as its key is now; opts.closedOnly
-- for the row alone), without drawing: a layout can size the block before it draws.
-- @return height, rowRect, verbRects (rects at y = 0 unless y is given in opts.y)
local _measureOpts = {}
function ZeD.Molecules.measureMoreRow(w, hidden, key, opts)
    opts = opts or NO_OPTS
    local m = _measureOpts
    m.measure, m.closedOnly, m.inset = true, opts.closedOnly, opts.inset
    return ZeD.Molecules.drawMoreRow(nil, opts.x or 0, opts.y or 0, w, hidden, key, m)
end
