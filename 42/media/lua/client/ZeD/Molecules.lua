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
function ZeD.Molecules.drawButton(panel, x, y, w, h, text, variant, pressed, colors)
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
        return
    end

    -- Button words read in sentence case (ZeD.btnCase); the flat variant above is
    -- printed hardware (radio chassis keys) and keeps what it is given, as does a
    -- label passed with colors.keepCase (a key's name: SPACE, LSHIFT)
    if not (colors and colors.keepCase) then text = ZeD.btnCase(text) end

    -- Optional fill under the chrome (focus / hover accent)
    if colors and colors.fill then
        local f = colors.fill
        A.fillRounded(panel, x, y, w, h, f.r, f.g, f.b, f.a or 1)
    end

    -- Variant determines border, fill, and text color.
    -- Danger pulses a red fill to signal destructive action.
    local borderColor, textColor
    if variant == "primary" then
        borderColor = T.accent
        textColor = T.accentText
    elseif variant == "danger" then
        borderColor = T.danger
        textColor = T.dangerText
        local pulse = math.sin((getTimestampMs() or 0) / 400) * 0.5 + 0.5
        local fillA = T.dangerPulseMin + pulse * (T.dangerPulseMax - T.dangerPulseMin)
        A.fillRounded(panel, x, y, w, h, T.danger.r, T.danger.g, T.danger.b, fillA)
    else
        borderColor = T.borderS
        textColor = T.text
    end
    if colors and colors.text then
        textColor = colors.text
    elseif colors and colors.fill and (colors.fill.a or 1) >= 0.5 then
        -- the 0.55 accent focus wash: the label is the focus ink, whatever the variant's own colour
        textColor = T.textOnFocus
    end

    -- Rounded border (colored per variant)
    A.borderDoubleRounded(panel, x, y, w, h, borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)

    -- Centered label (K22 Xanthus — instrument chrome)
    local tw = ZeD.TM:MeasureStringX(T.fontF3, text)
    local th = ZeD.TM:getFontHeight(T.fontF3)
    local tx = x + math.floor((w - tw) / 2)
    local ty = y + math.floor((h - th) / 2)
    if pressed then tx = tx + T.px(1); ty = ty + T.px(1) end
    panel:drawText(text, tx, ty, textColor.r, textColor.g, textColor.b, textColor.a or 1, T.fontF3)
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
    ZeD.Molecules.drawButton(self, 0, 0, self.width, self.height,
        self.text, self._zedVariant, self._pressed)
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

    -- Background
    if selected then
        local ac = T.accent
        panel:drawRect(x, y, w, h, ac.a * alpha, ac.r, ac.g, ac.b)
    elseif hovered and not disabled then
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

    -- Primary text
    local textColor
    if selected then
        textColor = ZeD.colorAlpha(T.textOnAccent, alpha)
    elseif hovered and not disabled then
        textColor = ZeD.colorAlpha(T.accentText, alpha)
    else
        textColor = ZeD.colorAlpha(T.text, alpha)
    end

    local textY = y + (h - ZeD.TM:MeasureStringY(T.fontF2, item.text or "")) / 2
    panel:drawText(item.text or "", cx, textY,
        textColor.r, textColor.g, textColor.b, textColor.a, T.fontF2)

    -- Metadata text (right-aligned)
    if item.meta then
        local metaColor
        if selected then
            metaColor = ZeD.colorAlpha(T.textOnAccent, alpha)
        elseif hovered and not disabled then
            metaColor = ZeD.colorAlpha(T.accentText, alpha)
        else
            metaColor = ZeD.colorAlpha(T.textSec, alpha)
        end
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
-- @return width   Total width of the drawn tab (for laying out the next one)
function ZeD.Molecules.drawTab(panel, x, y, text, active, hovered, disabled)
    local T = ZeD.T
    local sp = T.sp
    local h = T.tabH
    local alpha = disabled and T.disabledAlpha or 1.0

    -- Measure text to determine tab width
    local tw = ZeD.TM:MeasureStringX(T.fontF2, text)
    local w = tw + sp.tabPadX * 2

    -- Background
    local bg
    if active then
        bg = T.surf2  -- matches content panel below
    elseif hovered and not disabled then
        bg = T.surf2
    else
        bg = T.surf1
    end
    panel:drawRect(x, y, w, h, bg.a * alpha, bg.r, bg.g, bg.b)

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

    -- Label
    local textColor
    if active then
        textColor = ZeD.colorAlpha(T.accentText, alpha)
    elseif hovered and not disabled then
        textColor = ZeD.colorAlpha(T.text, alpha)
    else
        textColor = ZeD.colorAlpha(T.textDim, alpha)
    end
    local textY = y + (h - ZeD.TM:MeasureStringY(T.fontF2, text)) / 2
    panel:drawText(text, x + sp.tabPadX, textY,
        textColor.r, textColor.g, textColor.b, textColor.a, T.fontF2)

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
                local optColor = isHovered and T.accentText or T.text
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
-- @return height    Total height of the drawn header
function ZeD.Molecules.drawSectionHeader(panel, x, y, w, text, count, expanded, hovered, fontOverride, countInline, bleedLeft, heightOverride, noArrow)
    local T = ZeD.T
    local sp = T.sp
    local textH = T.rowH              -- text/arrow centered in this portion
    local h = heightOverride or textH  -- total strip height (bg + line)
    local font = fontOverride or T.fontF1
    local tm = ZeD.TM
    local bleed = bleedLeft or 0

    -- Background (slightly elevated) — extends left by bleed to reach panel edge
    local bg = hovered and T.hover or T.surf2
    panel:drawRect(x - bleed, y, w + bleed, h, bg.a, bg.r, bg.g, bg.b)

    -- Bottom border (strong — section boundary) — same bleed
    ZeD.Atoms.drawDividerH(panel, x - bleed, y + h - T.px(1), w + bleed, true)

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
    local tc = T.textHead
    panel:drawText(text, titleX, textY, tc.r, tc.g, tc.b, tc.a, font)

    -- Count
    if count then
        local countStr = "(" .. tostring(count) .. ")"
        if countInline then
            local titleW = tm:MeasureStringX(font, text)
            local countX = titleX + titleW + sp.xs
            local dc = T.accentDim
            panel:drawText(countStr, countX, textY, dc.r, dc.g, dc.b, dc.a, T.fontF1)
        else
            ZeD.Atoms.drawTextRight(panel, countStr, x + w - sp.sm, textY, T.fontF1, T.accentDim)
        end
    end

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
-- @param text      Disclosure title (e.g. "Health", "Defense")
-- @param expanded  boolean — disclosure state
-- @param hovered   boolean — mouse over header
-- @return headerH  constant 37
function ZeD.Molecules.drawTabHeader(panel, x, y, w, text, expanded, hovered, noArrow)
    -- Tab headers (Defense / Health / Thermal / Identity / Skills) inherit
    -- the parent drawer panel's background — same rule as the radio drawer
    -- header. No bg paint here; just disclosure arrow + title + bottom rule.
    local T = ZeD.T
    local pad = T.px(TAB_HEADER_PAD)
    local h   = T.px(TAB_HEADER_H)
    local font = T.fontF4
    local tm  = ZeD.TM
    local fullW = panel:getWidth() - x

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
    local tc     = T.textHead
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
-- Label: monospace, uppercase, textSec (chrome voice) — left-aligned
-- Value: sans-serif, T.text or semantic override (content voice) — right-aligned
-- ============================================================================

--- Draw a stat row (key:value pair)
-- @param panel      The parent ISPanel
-- @param x, y       Top-left position of the row
-- @param w          Available width for the row
-- @param label      Label string (will be uppercased, drawn in chrome voice)
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

    -- Label: uppercase, secondary color (chrome voice)
    local lc = T.textSec
    local upperLabel = ZeD.upper(label)
    local labelW = ZeD.TM:MeasureStringX(lblFont, upperLabel)
    panel:drawText(upperLabel, x, labelY,
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
-- @param label      Label string (will be uppercased, drawn in chrome voice)
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
function ZeD.Molecules.drawFillBar(panel, x, y, w, ratio)
    local T = ZeD.T
    local barH = T.fillBarH

    -- Graduated color: green > 60%, amber 30-60%, red < 30%
    ZeD.Atoms.drawFillBar(panel, x, y, w, ratio, true)

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
-- @param stats  Array of {text=, color=} drawn right-to-left (or nil)
-- ============================================================================

function ZeD.Molecules.drawWindowTitleBar(panel, x, y, w, title, stats)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local tbH = T.titleBarH

    -- Background
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
        local statX = x + w - T.sp.sm
        local statFH = ZeD.TM:getFontHeight(T.fontF3)
        local statY = y + math.floor((tbH - statFH) / 2)
        local dotSz = 5 * T.hair   -- 5 x 5 cells of pixel art on the hairline grid (Oct 21 2026)
        local dotGap = T.px(4)
        local tc = T.text
        -- Left boundary: don't overlap title text (reuses titleFont from above)
        local titleEndW = title and ZeD.TM:MeasureStringX(T.fontF3, title) or 0
        local minX = x + T.sp.sm + T.closeBoxSz + T.sp.md + titleEndW + T.sp.titleBoxPad * 2 + T.sp.md
        for i = #stats, 1, -1 do
            local stat = stats[i]
            local sw = ZeD.TM:MeasureStringX(T.fontF3, stat.text)
            local needed = sw + dotGap + dotSz + T.sp.md
            -- Skip this stat if it would overflow past the title
            if statX - needed < minX then break end
            statX = statX - sw
            panel:drawText(stat.text, statX, statY, tc.r, tc.g, tc.b, tc.a or 1, T.fontF3)
            -- Color dot before text
            local dc = stat.color or T.textDim
            statX = statX - dotGap - dotSz
            local dotY = y + math.floor((tbH - dotSz) / 2)
            -- 5x5 pixel-art circle: rows 0,4 = 3px centered; rows 1-3 = 5px
            local da = dc.a or 1
            local p1 = T.hair   -- each cell T.hair square, so the rows are 1, 3, 1 cells at every scale
            local p4 = 4 * p1
            panel:drawRect(statX + p1, dotY,      p4 - p1, p1,         da, dc.r, dc.g, dc.b)
            panel:drawRect(statX,      dotY + p1, dotSz,   p4 - p1,    da, dc.r, dc.g, dc.b)
            panel:drawRect(statX + p1, dotY + p4, p4 - p1, dotSz - p4, da, dc.r, dc.g, dc.b)
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
        local isHov = (hoverIdx == i)

        -- Button background (no border on icon buttons)
        if isOn then
            local c = T[def.colorKey]
            A.fillRounded(panel, bx, y, btnSz, btnSz, c.r, c.g, c.b, 0.2)
        else
            local bg = isHov and T.hover or T.surf2
            A.fillRounded(panel, bx, y, btnSz, btnSz, bg.r, bg.g, bg.b, bg.a)
        end

        -- Icon with 4px padding inside rounded button
        local tex = AS.getTex(def.tex)
        if tex then
            local iconPad = _iconPad(btnSz)
            local iconSz  = btnSz - iconPad * 2
            local iconAlpha = isOn and 1.0 or (isHov and 0.85 or 0.65)
            local iconTint  = isOn and T[def.colorKey] or T.iconTone
            A.drawIcon(panel, tex, bx + iconPad, y + iconPad, iconSz, iconAlpha, iconTint)
        end

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
-- M16: VERB STRIP — right-aligned row of context action buttons
-- Same visual pattern as drawActionStrip but drawn right-to-left from a
-- right edge, and state is driven by verb.active (not a toggle machine).
--
-- @param panel      ISPanel
-- @param rightEdge  Right boundary x (local) — buttons grow leftward
-- @param y          Top y (local)
-- @param verbs      Array of {iconKey, active}
-- @param hoverIdx   Currently hovered index (nil = none)
-- @return rects     Array of {x, y, w, h} in absolute coords
-- ============================================================================
function ZeD.Molecules.drawVerbStrip(panel, rightEdge, y, verbs, hoverIdx)
    local T   = ZeD.T
    local A   = ZeD.Atoms
    local AS  = ZeD.ActionStrip
    local btnSz = T.iconSm + T.px(4)
    local gap   = T.sp.xs
    local absX  = panel:getAbsoluteX()
    local absY  = panel:getAbsoluteY()
    local rects = {}

    local vx = rightEdge
    for i = #verbs, 1, -1 do
        local verb = verbs[i]
        if i < #verbs then vx = vx - gap end
        vx = vx - btnSz
        local bx   = vx
        local isHov = (hoverIdx == i)

        -- No accent shade — active/inactive differ by icon alpha only. No border on icon buttons.
        local bg = isHov and T.hover or T.surf2
        A.fillRounded(panel, bx, y, btnSz, btnSz, bg.r, bg.g, bg.b, bg.a)

        local vtex = AS.getTex(verb.iconKey)
        if vtex then
            local iconPad = _iconPad(btnSz)
            local iconSz  = btnSz - iconPad * 2
            local iconAlpha = verb.active and (isHov and 1.0 or 0.85) or 0.25
            A.drawIcon(panel, vtex, bx + iconPad, y + iconPad, iconSz, iconAlpha, T.iconTone)
        end

        rects[i] = {x = absX + bx, y = absY + y, w = btnSz, h = btnSz}
    end

    return rects
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
        -- Button: rounded, flush right of flag. No border on icon buttons.
        local bx = x + flagW
        local bg = hovered and T.hover or T.surf2
        A.fillRounded(panel, bx, y, btnSz, btnSz, bg.r, bg.g, bg.b, bg.a * dim)

        -- Icon with 4px padding
        local iconPad = _iconPad(btnSz)
        local iconSz  = btnSz - iconPad * 2
        local iAlpha    = greyed and 0.2 or (hovered and 0.85 or 0.65)
        local iconTint  = (not greyed and tint) and tint or T.iconTone
        A.drawIcon(panel, icon, bx + iconPad, y + iconPad, iconSz, iAlpha, iconTint)

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
--     name    string          zone label (will be uppercased)
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
            local lbl    = ZeD.upper(ZeD.tr("Tooltip_clothing_dirty"))
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
-- Note: the existing icon-only drawVerbStrip (M16) is the S118 zone-dock
-- variant and stays intact; S120 introduces the text-label sibling.
-- ============================================================================

-- T2.1 CARD BACK-BAR ---------------------------------------------------------
--- Draw the card's header strip: back btn + name + verb cluster.
--- @param panel ISPanel
--- @param x, y  Top-left
--- @param w     Total width
--- @param name  Item display name (ellipsis-truncated if too wide)
--- @param verbs Array of {label, primary, disabled?, danger?} — drawn right-to-left.
---              `primary=true` paints in accent (CTA); secondary in surf2.
---              `disabled=true` greys that verb to .35 (Vehicle tab: needs unmet);
---              `danger=true` draws danger text over the danger sine-pulse fill.
--- @param progressActive  When true, verbs render at .35 alpha (no cursor)
--- @param compact         220w preset (h=30, btn=20); else 480w (h=37, btn=22)
--- @param outRects        Optional table; on return:
---                          outRects.back = {x,y,w,h}
---                          outRects.verbs[i] = {x,y,w,h}
--- @return height
function ZeD.Molecules.drawCardBackBar(panel, x, y, w, name, verbs, progressActive, compact, outRects)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local font = T.fontF1

    local h, btnSz, padX, gap, btnPadX
    if compact then
        h, btnSz, padX, gap, btnPadX = T.px(30), T.px(20), T.px(3), T.px(4), T.px(7)
    else
        h, btnSz, padX, gap, btnPadX = T.px(37), T.px(22), T.px(4), T.px(6), T.px(8)
    end

    -- Surface bg + bottom separator
    local bg, bs = T.surf2, T.borderS
    panel:drawRect(x, y, w, h, bg.a, bg.r, bg.g, bg.b)
    panel:drawRect(x, y + h - T.px(1), w, T.px(1), bs.a, bs.r, bs.g, bs.b)

    -- Back button (raised System-7 chrome via surf4 highlight + borderS shadow)
    local backX = x + padX
    local backY = y + math.floor((h - btnSz) / 2)
    local hi, sh = T.surf4, T.borderS
    panel:drawRect(backX, backY, btnSz, btnSz, bg.a, bg.r, bg.g, bg.b)
    panel:drawRect(backX, backY, btnSz, T.px(1), hi.a, hi.r, hi.g, hi.b)
    panel:drawRect(backX, backY, T.px(1), btnSz, hi.a, hi.r, hi.g, hi.b)
    panel:drawRect(backX, backY + btnSz - T.px(1), btnSz, T.px(1), sh.a, sh.r, sh.g, sh.b)
    panel:drawRect(backX + btnSz - T.px(1), backY, T.px(1), btnSz, sh.a, sh.r, sh.g, sh.b)

    local labelH = T.fontF1H or ZeD.TM:MeasureStringY(font, "<")
    local backGlyph = "<"
    local bgw = ZeD.TM:MeasureStringX(font, backGlyph)
    local tc = T.text
    panel:drawText(backGlyph, backX + math.floor((btnSz - bgw) / 2),
        backY + math.floor((btnSz - labelH) / 2),
        tc.r, tc.g, tc.b, tc.a, font)

    if outRects then
        outRects.back  = {x = backX, y = backY, w = btnSz, h = btnSz}
        outRects.verbs = outRects.verbs or {}
    end

    -- Verb cluster — right-aligned, drawn right-to-left
    local verbAlpha = progressActive and 0.35 or 1.0
    local cursorR   = x + w - padX
    if verbs and #verbs > 0 then
        for i = #verbs, 1, -1 do
            local v = verbs[i]
            if i < #verbs then cursorR = cursorR - gap end
            local labelStr = ZeD.btnCase(v.label or "")   -- sentence case (draw only: ItemCard dispatches on the caps label)
            local lw   = ZeD.TM:MeasureStringX(font, labelStr)
            local btnW = lw + btnPadX * 2
            cursorR    = cursorR - btnW
            local btnX = cursorR
            local btnY = y + math.floor((h - btnSz) / 2)

            local vAlpha = verbAlpha * (v.disabled and 0.35 or 1.0)
            local btnBg = v.primary and T.accent or T.surf2
            panel:drawRect(btnX, btnY, btnW, btnSz, (btnBg.a or 1) * vAlpha,
                btnBg.r, btnBg.g, btnBg.b)
            if v.danger and not v.primary and not v.disabled then
                local pulse = math.sin((getTimestampMs() or 0) / 400) * 0.5 + 0.5
                local fillA = T.dangerPulseMin + pulse * (T.dangerPulseMax - T.dangerPulseMin)
                panel:drawRect(btnX, btnY, btnW, btnSz, fillA, T.danger.r, T.danger.g, T.danger.b)
            end

            local btnHi = v.primary and T.accentBright or T.surf4
            local btnSh = v.primary and ZeD.colorBlend(T.accent, T.base, 0.55) or T.borderS
            panel:drawRect(btnX, btnY, btnW, T.px(1),
                (btnHi.a or 1) * vAlpha, btnHi.r, btnHi.g, btnHi.b)
            panel:drawRect(btnX, btnY, T.px(1), btnSz,
                (btnHi.a or 1) * vAlpha, btnHi.r, btnHi.g, btnHi.b)
            panel:drawRect(btnX, btnY + btnSz - T.px(1), btnW, T.px(1),
                (btnSh.a or 1) * vAlpha, btnSh.r, btnSh.g, btnSh.b)
            panel:drawRect(btnX + btnW - T.px(1), btnY, T.px(1), btnSz,
                (btnSh.a or 1) * vAlpha, btnSh.r, btnSh.g, btnSh.b)

            local lc = v.primary and T.textOnAccent or (v.danger and T.dangerText or T.text)
            panel:drawText(labelStr, btnX + btnPadX,
                btnY + math.floor((btnSz - labelH) / 2),
                lc.r, lc.g, lc.b, (lc.a or 1) * vAlpha, font)

            if outRects then
                outRects.verbs[i] = {x = btnX, y = btnY, w = btnW, h = btnSz}
            end
        end
    end

    -- Item name — between back button and verb cluster, ellipsis-truncated
    local nameX = backX + btnSz + gap
    local nameW = cursorR - gap - nameX
    if nameW > 0 and name and name ~= "" then
        local nameFont = compact and font or T.fontF4
        local nameStr  = name
        if ZeD.TM:MeasureStringX(nameFont, nameStr) > nameW then
            nameStr = A.truncateText(nameStr, nameFont, nameW)
        end
        local nameH = (compact and (T.fontF1H or labelH))
                       or T.fontF4H
                       or ZeD.TM:MeasureStringY(nameFont, nameStr)
        local nameY = y + math.floor((h - nameH) / 2)
        local nc    = T.text
        panel:drawText(nameStr, nameX, nameY, nc.r, nc.g, nc.b, nc.a, nameFont)
    end

    return h
end

-- T2.2 CARD FLAG STRIP -------------------------------------------------------
--- Draw "MARKED" label + three flag chips (fav, nocraft, dispose).
--- Per-chip on/off read from marks.
--- @param panel    ISPanel
--- @param x, y     Top-left
--- @param w        Total width
--- @param marks    Table {fav=bool, nocraft=bool, dispose=bool}
--- @param compact  220w icon-only chips; else 480w padded label chips
--- @param outRects Optional table; on return: outRects.fav/nocraft/dispose = hit rect
--- @return height
function ZeD.Molecules.drawCardFlagStrip(panel, x, y, w, marks, compact, outRects)
    local T = ZeD.T
    local A = ZeD.Atoms

    local h, padX, gap, lblPadR
    if compact then
        h, padX, gap, lblPadR = T.px(24), T.px(8), T.px(4), T.px(2)
    else
        h, padX, gap, lblPadR = T.px(28), T.px(12), T.px(6), T.px(4)
    end

    -- Surface bg (surf1 — body color) + 1px bottom separator
    local bg, sep = T.surf1, T.border
    panel:drawRect(x, y, w, h, bg.a, bg.r, bg.g, bg.b)
    panel:drawRect(x, y + h - T.px(1), w, T.px(1), sep.a, sep.r, sep.g, sep.b)

    local font   = T.fontF1
    local labelH = T.fontF1H or ZeD.TM:MeasureStringY(font, "M")
    local rowY   = y + math.floor((h - T.px(18)) / 2)  -- chip atom is 18 tall

    -- "MARKED" label (left, dim)
    local lblText  = ZeD.tr("UI_ZeD_Card_Marked")
    local labelTY  = y + math.floor((h - labelH) / 2)
    local labelC   = T.textDim
    panel:drawText(lblText, x + padX, labelTY,
        labelC.r, labelC.g, labelC.b, labelC.a, font)
    local lblW = ZeD.TM:MeasureStringX(font, lblText)

    -- Three chips — composes Atoms.drawFlagChip ×3
    local cursorX = x + padX + lblW + lblPadR

    if outRects then outRects.fav = outRects.fav or {} end
    local cw = A.drawFlagChip(panel, cursorX, rowY, "fav",
        marks and marks.fav or false, "*", ZeD.tr("UI_ZeD_Card_ChipFav"),
        outRects and outRects.fav or nil, compact)
    cursorX = cursorX + cw + gap

    if outRects then outRects.nocraft = outRects.nocraft or {} end
    cw = A.drawFlagChip(panel, cursorX, rowY, "nocraft",
        marks and marks.nocraft or false, "o", ZeD.tr("UI_ZeD_Card_ChipNoCraft"),
        outRects and outRects.nocraft or nil, compact)
    cursorX = cursorX + cw + gap

    if outRects then outRects.dispose = outRects.dispose or {} end
    A.drawFlagChip(panel, cursorX, rowY, "dispose",
        marks and marks.dispose or false, "x", ZeD.tr("UI_ZeD_Card_ChipDispose"),
        outRects and outRects.dispose or nil, compact)

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
--- @return height (0 when idle / no manager / no item)
function ZeD.Molecules.drawCardProgressBand(panel, x, y, w, item, compact, outRect)
    local mgr = ZeD.ItemActionManager
    if not mgr or not item then return 0 end
    local action = mgr.getActiveAction(item)
    if not action then return 0 end
    return ZeD.Atoms.drawProgressBand(panel, x, y, w,
        action.mode    or "active",
        action.label   or "",
        action.percent or 0,
        action.timeStr,
        outRect, compact)
end

-- T2.4 CARD VERB STRIP -------------------------------------------------------
--- Right-aligned row of text-labeled verb buttons.
--- Empty list → no render at all (books have no maintenance verbs).
--- @param panel        ISPanel
--- @param rightEdge    Right boundary x (panel-local) — buttons grow left
--- @param y            Top y
--- @param verbs        Array of {label, glyph}; nil/empty → no render
--- @param progressActive  When true, all buttons grey to .35 alpha
--- @param compact      220w hides glyph; 480w shows glyph + label
--- @param outRects     Optional array of per-verb hit rects
--- @return result      {h = height, leftEdge = leftmost x consumed}
function ZeD.Molecules.drawCardVerbStrip(panel, rightEdge, y, verbs, progressActive, compact, outRects)
    if not verbs or #verbs == 0 then
        return {h = 0, leftEdge = rightEdge}
    end
    local T        = ZeD.T
    local font     = T.fontF1
    local btnH     = T.px(22)
    local padX     = T.px(10)
    local gap      = compact and T.px(3) or T.px(4)
    local glyphGap = T.px(4)
    local alpha    = progressActive and 0.35 or 1.0
    local labelH   = T.fontF1H or ZeD.TM:MeasureStringY(font, "X")

    local cursorR = rightEdge
    for i = #verbs, 1, -1 do
        local v = verbs[i]
        if i < #verbs then cursorR = cursorR - gap end

        local labelStr = ZeD.btnCase(v.label or "")   -- sentence case, never all caps
        local labelW   = ZeD.TM:MeasureStringX(font, labelStr)
        local glyphStr = (not compact) and v.glyph or nil
        local glyphW   = (glyphStr and glyphStr ~= "")
            and ZeD.TM:MeasureStringX(font, glyphStr) or 0
        local interGap = (glyphW > 0) and glyphGap or 0
        local btnW     = padX * 2 + glyphW + interGap + labelW
        cursorR        = cursorR - btnW
        local bx       = cursorR
        local btnY     = y

        local bgC, bdC = T.surf2, T.border
        panel:drawRect(bx, btnY, btnW, btnH,
            (bgC.a or 1) * alpha, bgC.r, bgC.g, bgC.b)
        panel:drawRectBorder(bx, btnY, btnW, btnH,
            (bdC.a or 1) * alpha, bdC.r, bdC.g, bdC.b)

        local textY = btnY + math.floor((btnH - labelH) / 2)
        local cursor = bx + padX
        if glyphW > 0 then
            local gc = T.textSec
            panel:drawText(glyphStr, cursor, textY,
                gc.r, gc.g, gc.b, (gc.a or 1) * alpha, font)
            cursor = cursor + glyphW + interGap
        end
        local lc = T.text
        panel:drawText(labelStr, cursor, textY,
            lc.r, lc.g, lc.b, (lc.a or 1) * alpha, font)

        if outRects then
            outRects[i] = {x = bx, y = btnY, w = btnW, h = btnH}
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

-- Internal helper: resolve a value-class string ("warn"/"bad"/"dim"/"good"/nil)
-- to a color from the active theme. Inline so Phase 4 facts factories don't
-- need to import any extra utility.
local function _resolveStatValColor(valueClass, T)
    if     valueClass == "warn" then return T.warningText
    elseif valueClass == "bad"  then return T.dangerText
    elseif valueClass == "dim"  then return T.textDim
    elseif valueClass == "good" then return T.positiveText
    else                              return T.text
    end
end

-- T3.x  CARD STAT ROW --------------------------------------------------------
--- Draw a single key:value stat row in v13 voice (mono accent label + sans value).
--- Matches the .stat-line-{220,480} CSS in mockups v13/v15.
--- @param panel ISPanel
--- @param x, y  Top-left
--- @param w     Available width
--- @param label String — uppercased automatically
--- @param value String value
--- @param valueClass One of nil/"warn"/"bad"/"dim"/"good" → color
--- @param dotColor   Optional {r,g,b,a} for inline status dot after the value
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

    -- Label: F1 mono bold, the accent as legible text (not toneLo)
    local lblText = ZeD.upper(label or "")
    local lc      = T.accentText
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
    local labelStr = label or ""
    local labelRoom = w - indent - vw - T.px(8)
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
-- A 20px contextual strip (doubles as column header row) with underline-tab
-- sort modes and a right-aligned status-dot toggle.
--
-- modes:        ordered list of {id, label} tables
-- activeMode:   id string of the active sort mode
-- rightToggle:  {label, active} or nil (right-aligned dot toggle)
-- Returns:      stripH (20), zones table for click dispatch
-- ============================================================================

local STRIP_H = 20   -- S124 scale: design units; uses wrap with T.px

function ZeD.Molecules.drawSortStrip(panel, x, y, w, modes, activeMode, rightToggle, hoverZone)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local h  = T.px(STRIP_H)
    local font = T.fontF1

    -- Strip background
    local bg = T.surf2
    panel:drawRect(x, y, w, h, bg.a, bg.r, bg.g, bg.b)

    -- Bottom rule
    A.drawDividerH(panel, x, y + h - T.px(1), w, true)

    -- "SORT" label
    local sortLabel = ZeD.tr("UI_ZeD_Strip_Sort")
    local sc = T.textSec
    local labelW = tm:MeasureStringX(font, sortLabel)
    local textY = y + math.floor((h - tm:getFontHeight(font)) / 2)
    panel:drawText(sortLabel, x + T.px(6), textY, sc.r, sc.g, sc.b, sc.a, font)

    -- The toggle's width is reserved first, so the tabs never run under it
    local togLabel, togW = nil, 0
    if rightToggle then
        togLabel = rightToggle.label or ZeD.tr("UI_All")
        togW = tm:MeasureStringX(font, togLabel) + T.px(14)  -- dot + gap + text
    end
    local tabLimit = x + w - T.px(6)
    if rightToggle then tabLimit = x + w - togW - T.px(6) - T.px(8) end

    -- Mode tabs with underline; a tab that does not fit ends in "...", the ones after it drop
    local tabX = x + T.px(6) + labelW + T.px(8)
    local zones = {}
    for _, mode in ipairs(modes) do
        local label = mode.label
        local tw = tm:MeasureStringX(font, label)
        local room = tabLimit - tabX
        if tw > room then
            if room < T.px(24) then break end
            label = A.truncateText(label, font, room)
            tw = tm:MeasureStringX(font, label)
        end
        local isActive = (mode.id == activeMode)
        local isHover = (hoverZone == mode.id)
        local tc = isActive and T.accentText or (isHover and T.accentText or T.textSec)

        panel:drawText(label, tabX, textY, tc.r, tc.g, tc.b, tc.a or 1, font)

        -- Underline for active mode
        if isActive then
            panel:drawRect(tabX, y + h - T.px(2), tw, T.px(1), T.accent.a, T.accent.r, T.accent.g, T.accent.b)
        end

        zones[#zones + 1] = { id = mode.id, x = tabX, y = y, w = math.min(tw + T.px(8), math.max(tw, tabLimit - tabX)), h = h, type = "sort" }
        tabX = tabX + tw + T.px(12)
    end

    -- Right-aligned toggle (status dot style)
    if rightToggle then
        local togX = x + w - togW - T.px(6)
        local dotSz = T.px(6)
        local dotColor = rightToggle.active and T.accent or T.textDim
        local dotY = y + math.floor((h - dotSz) / 2)
        A.drawStatusDot(panel, togX, dotY, dotColor, dotSz)

        local togTC = rightToggle.active and T.accentText or T.textSec
        panel:drawText(togLabel, togX + dotSz + T.px(4), textY,
            togTC.r, togTC.g, togTC.b, togTC.a or 1, font)

        zones[#zones + 1] = { id = "toggle", x = togX, y = y, w = togW, h = h, type = "toggle" }
    end

    return h, zones
end


-- ============================================================================
-- 19. ALT-BACK STRIP (draw helper)
-- A 24px contextual strip for alt mode: back button, owned stat, filter toggle.
-- Accent-tinted background signals "you are in alt mode".
-- ============================================================================

function ZeD.Molecules.drawAltBackStrip(panel, x, y, w, slotName, ownedCount, totalCount, ownedOnly, hoverZone)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local h  = T.px(STRIP_H)
    local font = T.fontF1

    -- Accent-tinted background
    local ac = T.accent
    panel:drawRect(x, y, w, h, 0.08, ac.r, ac.g, ac.b)

    -- Accent bottom border
    panel:drawRect(x, y + h - T.px(1), w, T.px(1), ac.a * 0.4, ac.r, ac.g, ac.b)

    local textY = y + math.floor((h - tm:getFontHeight(font)) / 2)
    local zones = {}

    -- Left: back affordance "< Recipes"
    local backLabel = ZeD.tr("EC_Recipes")
    local arrowSz = T.px(6)
    local arrowY = y + math.floor((h - arrowSz) / 2)
    A.drawTriangleLeft(panel, x + T.px(6), arrowY, arrowSz, T.accent)
    local isBackHover = (hoverZone == "back")
    local backTC = T.accentText
    local backX = x + T.px(6) + arrowSz + T.px(4)
    panel:drawText(backLabel, backX, textY, backTC.r, backTC.g, backTC.b, backTC.a or 1, font)
    local backW = tm:MeasureStringX(font, backLabel)
    zones[#zones + 1] = { id = "back", x = x, y = y, w = backX + backW + T.px(4) - x, h = h, type = "back" }

    -- Center: "N/total owned" stat
    local statStr = ZeD.tr("UI_ZeD_Strip_OwnedCount", ownedCount, totalCount)
    local statW = tm:MeasureStringX(font, statStr)
    local statX = x + math.floor((w - statW) / 2)
    local nc = T.textSec
    panel:drawText(statStr, statX, textY, nc.r, nc.g, nc.b, nc.a, font)

    -- Right: "Owned only" toggle
    local togLabel = ZeD.tr("UI_ZeD_Strip_OwnedOnly")
    local dotSz = T.px(6)
    local togW = tm:MeasureStringX(font, togLabel) + dotSz + T.px(4)
    local togX = x + w - togW - T.px(6)
    local dotColor = ownedOnly and T.positive or T.textDim
    local dotY = y + math.floor((h - dotSz) / 2)
    A.drawStatusDot(panel, togX, dotY, dotColor, dotSz)

    local togTC = ownedOnly and T.positive or T.textSec
    panel:drawText(togLabel, togX + dotSz + T.px(4), textY,
        togTC.r, togTC.g, togTC.b, togTC.a or 1, font)

    zones[#zones + 1] = { id = "ownedOnly", x = togX, y = y, w = togW + T.px(6), h = h, type = "toggle" }

    return h, zones
end


-- ============================================================================
-- 20. RECIPE ROW (draw helper)
-- A 24px row in the recipe list: selection edge, status dot, icon, name, star.
-- Striped bg, red whisper for missing, accent bg+edge for selected.
--
-- data table: { name, displayName, iconTex, status, craftable, tag }
--   status: "can" (green), "miss" (red), "unknown" (grey),
--           "station" (hollow ring: made at a station, not by hand)
--   tag:    optional short label drawn right (the station: "KILN")
-- ============================================================================

local RECIPE_ROW_H = 24   -- S124 scale: design units; uses wrap with T.px

function ZeD.Molecules.drawRecipeRow(panel, x, y, w, data, selected, hovered, pinned, freqCount, rowIdx)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local h  = T.px(RECIPE_ROW_H)

    -- Stripe background (alternating even rows)
    if rowIdx and rowIdx % 2 == 0 then
        local st = T.stripe
        panel:drawRect(x, y, w, h, st.a, st.r, st.g, st.b)
    end

    -- Status-based background tint
    local status = data.status or "can"
    if status == "unknown" then
        local dg = T.danger
        panel:drawRect(x, y, w, h, 0.06, dg.r, dg.g, dg.b)
    end

    -- Selection highlight
    if selected then
        local ac = T.accent
        panel:drawRect(x, y, w, h, 0.18, ac.r, ac.g, ac.b)
    elseif hovered then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end

    local cx = x

    -- Selection edge (2px accent bar)
    if selected then
        panel:drawRect(cx, y, T.px(2), h, T.accent.a, T.accent.r, T.accent.g, T.accent.b)
    end
    cx = cx + T.px(4)  -- edge space

    -- Status dot (6px): green=craftable, gold=missing ingredients, red=not known
    local dotSz = T.px(6)
    local dotY = y + math.floor((h - dotSz) / 2)
    if status == "station" then
        A.drawStatusRing(panel, cx, dotY, T.textDim, dotSz)
    else
        local dotColor
        if status == "can" then dotColor = T.positive
        elseif status == "miss" then dotColor = T.warningText
        else dotColor = T.danger end
        A.drawStatusDot(panel, cx, dotY, dotColor, dotSz)
    end
    cx = cx + dotSz + T.px(4)

    -- Icon (14px)
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
        tagW = tm:MeasureStringX(T.fontF1, data.tag) + T.px(10)
        nameMaxW = nameMaxW - tagW - T.px(6)
    end

    -- Freq badge eats into name space
    local freqBadgeW = 0
    if freqCount and freqCount > 0 then
        local freqStr = "x" .. tostring(freqCount)
        freqBadgeW = tm:MeasureStringX(T.fontF5, freqStr) + T.px(8)
        nameMaxW = nameMaxW - freqBadgeW
    end

    local displayName = data.displayName or data.name or ""
    -- Unknown recipes get italic styling via dim color
    local nameColor
    if status == "unknown" or status == "station" then
        nameColor = T.textDim
    elseif selected then
        nameColor = T.accent
    else
        nameColor = T.text
    end

    -- Truncate name if needed
    local nameStr = displayName
    local nameW = tm:MeasureStringX(nameFont, nameStr)
    if nameW > nameMaxW then
        -- Binary search truncation
        local lo, hi = 1, #nameStr
        while lo < hi do
            local mid = math.ceil((lo + hi) / 2)
            local test = string.sub(nameStr, 1, mid) .. ".."
            if tm:MeasureStringX(nameFont, test) <= nameMaxW then lo = mid else hi = mid - 1 end
        end
        nameStr = string.sub(nameStr, 1, lo) .. ".."
        nameW = tm:MeasureStringX(nameFont, nameStr)
    end

    panel:drawText(nameStr, cx, textY, nameColor.r, nameColor.g, nameColor.b, nameColor.a or 1, nameFont)
    cx = cx + nameW + T.px(4)

    -- Freq badge (inline, warning color)
    if freqCount and freqCount > 0 then
        local freqStr = "x" .. tostring(freqCount)
        local wc = T.warning
        panel:drawText(freqStr, cx, textY + T.px(1), wc.r, wc.g, wc.b, 0.7, T.fontF5)
    end

    -- Station tag box (dim outline, mono caps)
    if tagW > 0 then
        local th = T.px(14)
        local tx = x + w - T.px(22) - tagW
        local ty = y + math.floor((h - th) / 2)
        local bd = T.border
        panel:drawRectBorder(tx, ty, tagW, th, bd.a or 1, bd.r, bd.g, bd.b)
        local tc = T.textDim
        panel:drawText(data.tag, tx + T.px(5), ty + math.floor((th - tm:getFontHeight(T.fontF1)) / 2),
            tc.r, tc.g, tc.b, tc.a or 1, T.fontF1)
    end

    -- Star (right-aligned, hover-appear, accent when pinned)
    local starX = x + w - T.px(18)
    local starStr = pinned and "*" or "*"
    local starAlpha = pinned and 1.0 or (hovered and 0.5 or 0)
    if starAlpha > 0 then
        local starColor = pinned and T.accent or T.textDim
        local starFont = T.fontF3
        local starY = y + math.floor((h - tm:getFontHeight(starFont)) / 2)
        panel:drawText(starStr, starX, starY,
            starColor.r, starColor.g, starColor.b, starAlpha, starFont)
    end

    return h
end


-- ============================================================================
-- 21. ALT ROW (draw helper)
-- A 24px row in the alternative ingredients list: edge, dot, icon, name, count.
-- Owned items get a positive edge + tint. Non-interactive (read-only).
--
-- data table: { name, displayName, iconTex, have, need }
-- ============================================================================

function ZeD.Molecules.drawAltRow(panel, x, y, w, data, owned, rowIdx)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local h  = T.px(RECIPE_ROW_H)

    -- Stripe
    if rowIdx and rowIdx % 2 == 0 then
        local st = T.stripe
        panel:drawRect(x, y, w, h, st.a, st.r, st.g, st.b)
    end

    -- Owned tint
    if owned then
        local pc = T.positive
        panel:drawRect(x, y, w, h, 0.06, pc.r, pc.g, pc.b)
    end

    local cx = x

    -- Edge indicator (2px, owned = positive, otherwise blank)
    if owned then
        panel:drawRect(cx, y, T.px(2), h, T.positive.a, T.positive.r, T.positive.g, T.positive.b)
    end
    cx = cx + T.px(4)

    -- Status dot (6px)
    local dotSz = T.px(6)
    local dotColor = owned and T.positive or T.textDim
    local dotY = y + math.floor((h - dotSz) / 2)
    A.drawStatusDot(panel, cx, dotY, dotColor, dotSz)
    cx = cx + dotSz + T.px(4)

    -- Icon (16px)
    local iconSz = T.px(16)
    if data.iconTex then
        local iconY = y + math.floor((h - iconSz) / 2)
        panel:drawTextureScaledAspect(data.iconTex, cx, iconY, iconSz, iconSz, 1, 1, 1, 1)
    end
    cx = cx + iconSz + T.px(4)

    -- Name (F2, dim if not owned)
    local nameFont = T.fontF2
    local textY = y + math.floor((h - tm:getFontHeight(nameFont)) / 2)
    local nameColor = owned and T.text or T.textDim
    local nameStr = data.displayName or data.name or ""

    -- Truncate (reserve space for count)
    local countStr = tostring(data.have or 0) .. "/" .. tostring(data.need or 1)
    local countW = tm:MeasureStringX(T.fontF3, countStr) + T.px(8)
    local nameMaxW = w - (cx - x) - countW
    local nameW = tm:MeasureStringX(nameFont, nameStr)
    if nameW > nameMaxW then
        local lo, hi = 1, #nameStr
        while lo < hi do
            local mid = math.ceil((lo + hi) / 2)
            local test = string.sub(nameStr, 1, mid) .. ".."
            if tm:MeasureStringX(nameFont, test) <= nameMaxW then lo = mid else hi = mid - 1 end
        end
        nameStr = string.sub(nameStr, 1, lo) .. ".."
    end

    panel:drawText(nameStr, cx, textY, nameColor.r, nameColor.g, nameColor.b, nameColor.a or 1, nameFont)

    -- Count (right-aligned)
    local countColor = owned and T.positive or T.textDim
    A.drawTextRight(panel, countStr, x + w - T.px(6), textY, T.fontF3, countColor)

    return h
end


-- ============================================================================
-- 22. SLOT ROW (draw helper)
-- A 24px row in the craft card's required items list.
-- Grid: 2px edge | 18px icon | flex name+tag | count | 12px consumable flag
--
-- data table: { name, displayName, iconTex, have, need, altCount, isKeep, isTool, tag }
--   altCount: number of alternatives (nil or 0 = specific item, no alt click)
--   tag: "TOOL", "1 USE", etc. for specific items; nil for alt-backed
-- selected: this slot's alts are being shown in the left pane
-- ============================================================================

function ZeD.Molecules.drawSlotRow(panel, x, y, w, data, selected, hovered)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local h  = T.px(RECIPE_ROW_H)
    local missing = (data.have or 0) < (data.need or 1)

    -- Background: missing = red whisper, selected = accent bg
    if missing then
        local dg = T.danger
        panel:drawRect(x, y, w, h, 0.06, dg.r, dg.g, dg.b)
    end
    if selected then
        local ac = T.accent
        panel:drawRect(x, y, w, h, 0.12, ac.r, ac.g, ac.b)
    elseif hovered and (data.altCount or 0) > 0 then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end

    local cx = x

    -- Selection edge (2px accent when this slot's alts are showing)
    if selected then
        panel:drawRect(cx, y, T.px(2), h, T.accent.a, T.accent.r, T.accent.g, T.accent.b)
    end
    cx = cx + T.px(4)

    -- Icon (18px)
    local iconSz = T.px(18)
    if data.iconTex then
        local iconY = y + math.floor((h - iconSz) / 2)
        panel:drawTextureScaledAspect(data.iconTex, cx, iconY, iconSz, iconSz, 1, 1, 1, 1)
    end
    cx = cx + iconSz + T.px(4)

    -- Name + tag
    local nameFont = T.fontF2
    local textY = y + math.floor((h - tm:getFontHeight(nameFont)) / 2)
    local nameColor = missing and T.danger or T.text
    local nameStr = data.displayName or data.name or ""

    -- Reserve space for count + consumable flag
    local rightReserve = T.px(50)  -- count + flag space
    local nameMaxW = w - (cx - x) - rightReserve

    -- Tag inline (either "N▾" for alt-backed, or text tag for specific items)
    local tagStr, tagW, tagColor
    local extraTag, extraW = nil, 0
    if (data.altCount or 0) > 0 then
        tagStr = tostring(data.altCount) .. "v"  -- ▾ via drawTriangleDown later
        tagW = tm:MeasureStringX(T.fontF5, tagStr) + T.px(2)
        tagColor = T.warning
        nameMaxW = nameMaxW - tagW - T.px(6)
        if data.tag == "FUEL" then
            extraTag = ZeD.tr("UI_ZeD_Recipe_Fuel")
            extraW = tm:MeasureStringX(T.fontF1, extraTag) + T.px(10)
            nameMaxW = nameMaxW - extraW - T.px(6)
        end
    elseif data.tag then
        tagStr = data.tag
        tagW = tm:MeasureStringX(T.fontF5, tagStr)
        tagColor = T.textDim
        nameMaxW = nameMaxW - tagW - T.px(6)
    end

    -- Truncate name
    local nameW = tm:MeasureStringX(nameFont, nameStr)
    if nameW > nameMaxW then
        local lo, hi = 1, #nameStr
        while lo < hi do
            local mid = math.ceil((lo + hi) / 2)
            local test = string.sub(nameStr, 1, mid) .. ".."
            if tm:MeasureStringX(nameFont, test) <= nameMaxW then lo = mid else hi = mid - 1 end
        end
        nameStr = string.sub(nameStr, 1, lo) .. ".."
        nameW = tm:MeasureStringX(nameFont, nameStr)
    end

    panel:drawText(nameStr, cx, textY, nameColor.r, nameColor.g, nameColor.b, nameColor.a or 1, nameFont)
    cx = cx + nameW + T.px(4)

    -- Tag render
    if tagStr then
        local tagFont = T.fontF5
        local tagY = y + math.floor((h - tm:getFontHeight(tagFont)) / 2)
        if (data.altCount or 0) > 0 then
            -- Alt tag: bordered orange pill with N + tiny triangle
            local pillW = tagW + T.px(6)
            local pillH = tm:getFontHeight(tagFont) + T.px(2)
            local pillY = tagY - T.px(1)
            panel:drawRectBorder(cx, pillY, pillW, pillH,
                tagColor.a * 0.6, tagColor.r, tagColor.g, tagColor.b)
            -- Number
            local numStr = tostring(data.altCount)
            panel:drawText(numStr, cx + T.px(3), tagY, tagColor.r, tagColor.g, tagColor.b, 0.9, tagFont)
            -- Tiny down-triangle after number
            local numW = tm:MeasureStringX(tagFont, numStr)
            local triSz = T.px(4)
            local triX = cx + T.px(3) + numW + T.px(1)
            local triY = tagY + math.floor((tm:getFontHeight(tagFont) - triSz) / 2)
            A.drawTriangleDown(panel, triX, triY, triSz, tagColor)
            -- Text tag after the pill (FUEL): dim outline box, mono caps
            if extraTag then
                local bx = cx + pillW + T.px(6)
                local bh = T.px(14)
                local by = y + math.floor((h - bh) / 2)
                local bd = T.border
                panel:drawRectBorder(bx, by, extraW, bh, bd.a or 1, bd.r, bd.g, bd.b)
                local tc = T.textDim
                panel:drawText(extraTag, bx + T.px(5), by + math.floor((bh - tm:getFontHeight(T.fontF1)) / 2),
                    tc.r, tc.g, tc.b, tc.a or 1, T.fontF1)
            end
        else
            panel:drawText(tagStr, cx, tagY, tagColor.r, tagColor.g, tagColor.b, 0.6, tagFont)
        end
    end

    -- Have/need count (right-aligned, before consumable flag)
    local countStr
    if data.isKeep or data.isTool then
        countStr = tostring(data.have or 0)
    else
        countStr = tostring(data.have or 0) .. "/" .. tostring(data.need or 1)
    end
    local countColor = missing and T.danger or T.positive
    local countFont = T.fontF3
    local flagW = T.px(14)  -- space for consumable flag
    A.drawTextRight(panel, countStr, x + w - flagW - T.px(4), textY, countFont, countColor)

    -- Consumable flag (right corner): arrow = returned/kept, dash = consumed
    local flagX = x + w - flagW
    local flagColor = T.textDim
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
            flagColor.r, flagColor.g, flagColor.b, 0.7, T.fontF3)
    end

    return h
end


-- ============================================================================
-- 23. QTY STEPPER (draw helper)
-- [+][qty][-] group with disabled states at min/max.
-- Returns: totalW (width of the stepper group), zones table for clicks
-- ============================================================================

local STEPPER_BTN_W = 22   -- S124 scale: design units (both); uses wrap with T.px
local STEPPER_H     = 22

function ZeD.Molecules.drawQtyStepper(panel, x, y, qty, maxQty)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local h  = T.px(STEPPER_H)
    local bw = T.px(STEPPER_BTN_W)
    local font = T.fontF3
    local zones = {}

    -- [-] button
    local canDec = qty > 1
    local decColor = canDec and T.text or T.textDim
    local decBorder = canDec and T.borderS or T.textDim
    A.borderRounded(panel, x, y, bw, h, decBorder.r, decBorder.g, decBorder.b, decBorder.a * (canDec and 1 or 0.3))
    local minusStr = "-"
    local minusW = tm:MeasureStringX(font, minusStr)
    panel:drawText(minusStr, x + math.floor((bw - minusW) / 2), y + math.floor((h - tm:getFontHeight(font)) / 2),
        decColor.r, decColor.g, decColor.b, decColor.a or 1, font)
    zones[#zones + 1] = { id = "dec", x = x, y = y, w = bw, h = h }

    -- Qty readout (accent bg)
    local qtyStr = tostring(qty)
    local qtyW = math.max(bw, tm:MeasureStringX(font, qtyStr) + T.px(8))
    local qtyX = x + bw + T.px(1)
    local ac = T.accent
    panel:drawRect(qtyX, y, qtyW, h, 0.15, ac.r, ac.g, ac.b)
    panel:drawRectBorder(qtyX, y, qtyW, h, T.borderS.a * 0.5, T.borderS.r, T.borderS.g, T.borderS.b)
    local qtyTW = tm:MeasureStringX(font, qtyStr)
    panel:drawText(qtyStr, qtyX + math.floor((qtyW - qtyTW) / 2), y + math.floor((h - tm:getFontHeight(font)) / 2),
        ac.r, ac.g, ac.b, 1, font)

    -- [+] button
    local incX = qtyX + qtyW + T.px(1)
    local canInc = qty < maxQty
    local incColor = canInc and T.text or T.textDim
    local incBorder = canInc and T.borderS or T.textDim
    A.borderRounded(panel, incX, y, bw, h, incBorder.r, incBorder.g, incBorder.b, incBorder.a * (canInc and 1 or 0.3))
    local plusStr = "+"
    local plusW = tm:MeasureStringX(font, plusStr)
    panel:drawText(plusStr, incX + math.floor((bw - plusW) / 2), y + math.floor((h - tm:getFontHeight(font)) / 2),
        incColor.r, incColor.g, incColor.b, incColor.a or 1, font)
    zones[#zones + 1] = { id = "inc", x = incX, y = y, w = bw, h = h }

    local totalW = incX + bw - x
    return totalW, zones
end


-- ============================================================================
-- 24. CRAFT ACTION STRIP (draw helper)
-- Bottom-pinned 42px strip: [qty stepper] | max readout | [BUILD] button.
-- buildLabel: "CRAFT" or "BUILD" (tab-specific).
-- canCraft: false disables the button (grey, no click).
-- Returns: stripH (42), zones table for click dispatch
-- ============================================================================

local ACT_STRIP_H = 42   -- S124 scale: design units; uses wrap with T.px

function ZeD.Molecules.drawCraftActionStrip(panel, x, y, w, qty, maxQty, canCraft, hoverZone, buildLabel)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local h  = T.px(ACT_STRIP_H)
    local zones = {}

    -- Top rule
    A.drawDividerH(panel, x, y, w, true)

    -- Center vertically in 42px strip
    local innerH = T.px(STEPPER_H)
    local innerY = y + math.floor((h - innerH) / 2)
    local cx = x + T.px(6)

    -- Qty stepper
    local stepW, stepZones = ZeD.Molecules.drawQtyStepper(panel, cx, innerY, qty, maxQty)
    for _, z in ipairs(stepZones) do zones[#zones + 1] = z end
    cx = cx + stepW + T.px(10)

    -- Max readout (bare number)
    local maxStr = tostring(maxQty)
    local maxFont = T.fontF3
    local maxColor = maxQty == 0 and T.danger or T.text
    local maxY = innerY + math.floor((innerH - tm:getFontHeight(maxFont)) / 2)
    panel:drawText(maxStr, cx, maxY, maxColor.r, maxColor.g, maxColor.b, maxColor.a or 1, maxFont)
    local maxW = tm:MeasureStringX(maxFont, maxStr)
    cx = cx + maxW + T.px(10)

    -- BUILD button (fills remaining width)
    local btnX = cx
    local btnW = x + w - T.px(6) - btnX
    local btnH = innerH
    local btnY = innerY
    local label = ZeD.btnCase(buildLabel or ZeD.tr("IGUI_CraftingWindow_Craft"))   -- sentence case, never all caps

    if canCraft then
        -- Accent fill + border — readable label
        local isHover = (hoverZone == "build")
        local fillA = isHover and 0.25 or 0.15
        panel:drawRect(btnX, btnY, btnW, btnH, fillA, T.accent.r, T.accent.g, T.accent.b)
        A.borderRounded(panel, btnX, btnY, btnW, btnH,
            T.accent.r, T.accent.g, T.accent.b, T.accent.a)

        local btnFont = T.fontF4
        local labelW = tm:MeasureStringX(btnFont, label)
        local labelY = btnY + math.floor((btnH - tm:getFontHeight(btnFont)) / 2)
        panel:drawText(label, btnX + math.floor((btnW - labelW) / 2), labelY,
            T.accent.r, T.accent.g, T.accent.b, 1, btnFont)
    else
        -- Disabled — dim but still legible
        local bd = T.textDim
        A.borderRounded(panel, btnX, btnY, btnW, btnH, bd.r, bd.g, bd.b, bd.a * 0.5)
        local btnFont = T.fontF4
        local labelW = tm:MeasureStringX(btnFont, label)
        local labelY = btnY + math.floor((btnH - tm:getFontHeight(btnFont)) / 2)
        panel:drawText(label, btnX + math.floor((btnW - labelW) / 2), labelY,
            bd.r, bd.g, bd.b, bd.a * 0.5, btnFont)
    end

    zones[#zones + 1] = { id = "build", x = btnX, y = btnY, w = btnW, h = btnH }

    return h, zones
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
    -- Active cell gets a 1px accentBright inset border on top of the fill
    -- for extra visual pop so the selected action is unmistakable against
    -- the rest of the strip.
    local bg = flags.isActive and accent or paper
    panel:drawRect(x, y, ctx.cellW, ctx.cellH, bg.a or 1, bg.r, bg.g, bg.b)
    if flags.isActive then
        local ab = accentBright
        panel:drawRectBorder(x, y, ctx.cellW, ctx.cellH, ab.a or 1, ab.r, ab.g, ab.b)
    end

    -- Icon / back glyph / letter fallback
    if flags.isBack then
        A.drawBackGlyph(panel, x, y, ctx.cellW, ctx.cellH, flags.isActive, T)
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
        A.drawIcon(panel, def.iconTexture, iconX, iconY, ctx.iconPx, alpha, tint)
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
--   [◀] N/M [▶] | thin 1px vertical divider | subtitle | spacer | location pill
--
-- - Browse buttons are flat 16x16 squares with mono glyphs (◀/▶).
-- - Counter "N/M" rendered between them in mono font (F.stat).
-- - Subtitle is the current instance's display name (from engine getter).
-- - Location pill paints in T.accent (warm orange) with dark text — anchored
--   to the right edge of the strip.
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
-- ============================================================================
function ZeD.Molecules.drawDrawerInternalHeader(panel, x, y, w, browseState, subtitle, locationTag, rightReserve)
    local T = ZeD.T
    if not T then return end
    local TM = ZeD.TM

    -- ZeD.Spacing.tabHeaderH is the canonical drawer-header strip height
    -- shared across the mod (Health / Equipment-Defense / Thermal / Identity
    -- / Skills / Maps toolbar / Radio drawer header).
    local stripH    = T.px((ZeD.Spacing and ZeD.Spacing.tabHeaderH) or 37)
    local btnSize   = T.px(24)
    local btnGap    = T.px(6)
    local pad       = T.px(10)
    local pillPadX  = T.px(12)
    local pillH     = T.px(24)
    local font      = T.fontF1   -- mono small for counter + arrows
    local fontHead  = T.fontF2   -- sans for subtitle
    local fontPill  = T.fontF1

    -- No bg paint — the drawer panel behind us already provides the surface.
    -- (Project rule: avoid adding redundant backgrounds; use the parent's.)
    -- Just the 1px groove separating the header from the chassis below.
    local groove = T.borderS or { r = 0.22, g = 0.22, b = 0.22, a = 1.0 }
    panel:drawRect(x, y + stripH - T.px(1), w, T.px(1), groove.a or 1.0, groove.r, groove.g, groove.b)

    local btnY = y + math.floor((stripH - btnSize) / 2)
    local pillY = y + math.floor((stripH - pillH) / 2)

    local arrowBtnColors = {
        bg     = T.surf3 or T.surf1,  -- (the fallback named an undefined bg; code audit Oct 17 2026)
        border = T.borderS or groove,
        text   = T.text   or { r = 1, g = 1, b = 1, a = 1 },
        font   = font,
    }

    -- ============ Left edge: [<] [pill: Location (idx)] [>] ============
    -- The location pill now sits BETWEEN the browse arrows. Pill text format
    -- "<location> (<idx>)" e.g. "Primary (1)" or "Floor (2)". The (idx) shows
    -- which radio in the cycle is current; replaces the old N/M counter.
    local idx     = (browseState and browseState.idx) or 1
    local pillText = (locationTag and locationTag ~= "") and locationTag or "-"
    pillText = pillText .. " (" .. tostring(idx) .. ")"

    local pillTextW = TM:MeasureStringX(fontPill, pillText)
    local pillW = pillTextW + pillPadX * 2

    local cursor = x + pad

    -- Left arrow — stash rect for caller's hit testing
    local prevZone = { x = cursor, y = btnY, w = btnSize, h = btnSize }
    ZeD.Molecules.drawButton(panel, cursor, btnY, btnSize, btnSize,
        "<", "flat", false, arrowBtnColors)
    cursor = cursor + btnSize + btnGap

    -- Pill (accent fill, dark text)
    local pillBg = T.accent or { r = 0.83, g = 0.57, b = 0.16, a = 1.0 }
    local pillFg = T.textOnAccent or { r = 0.06, g = 0.06, b = 0.06, a = 1.0 }
    panel:drawRect(cursor, pillY, pillW, pillH,
        pillBg.a or 1.0, pillBg.r, pillBg.g, pillBg.b)
    local pillTxtY = y + math.floor((stripH - TM:getFontHeight(fontPill)) / 2)
    panel:drawText(pillText, cursor + pillPadX, pillTxtY,
        pillFg.r, pillFg.g, pillFg.b, pillFg.a or 1.0, fontPill)
    cursor = cursor + pillW + btnGap

    -- Right arrow — stash rect for caller's hit testing
    local nextZone = { x = cursor, y = btnY, w = btnSize, h = btnSize }
    ZeD.Molecules.drawButton(panel, cursor, btnY, btnSize, btnSize,
        ">", "flat", false, arrowBtnColors)
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
