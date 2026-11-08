-- ZeD-UI/42/media/lua/client/ZeD/ZeD_FormCard.lua
-- ============================================================================
-- THE FORM CARD: a small ZeD window for a game window that is a short form (ZeDUI/VANILLA_WINDOWS_20261107.md: C5 map
-- mark sharing, C15 the admin item editor; ZeD_MpLeftovers.lua builds both). The striped title bar with its close box,
-- an optional head (a picture, a name, a line under it), rows, the band at the foot with the answers (the main one
-- last, at the right) and the window's help line. Like ZeD_Prompt it is a top-level window that hit-tests its own
-- clicks, and the controller holds it directly (setJoypadFocus): Up and Down step through the rows and the band, Left
-- and Right along the band, A presses, B is the card's cancel.
--
-- spec = {
--   title, head = { tex = Texture, name, sub }, help (the help line's words), width (design units),
--   rows(card)  -> the rows, rebuilt each frame:
--     { k = "label", text }                      a heading
--     { k = "line", text }                       dim words, wrapped
--     { k = "fact", label, value }               read-only
--     { k = "radio", id, text, on, run, disabled, help }
--     { k = "check", id, text, on, run, disabled, help, ind (design units in) }
--     { k = "field", id, label, value (the first text), numbers, disabled, help }   a text field; card:text(id) reads it
--     { k = "swatch", id, label, color = { r, g, b }, run, help }
--   band(card)  -> { buttons = { { id, text, run, variant, disabled, help } }, ask (a question with its red square) }
--   cancel(card)   B, Escape and the close box
--   playerNum
-- }
-- ============================================================================

require "ISUI/ISTextEntryBox"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"

ZeD = ZeD or {}
ZeD.FormCard = ZeD.FormCard or {}
local FC = ZeD.FormCard

local U = { W = 360, PAD = 12, ROW_GAP = 6, HEAD_ICON = 32, IND = 18, FIELD_H = 26, MAX_H = 0.75 }

local function px(n) return ZeD.T.px(n) end
local function fh(f) return ZeD.TM:getFontHeight(f) end
local function tw(f, s) return ZeD.TM:MeasureStringX(f, s) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(n) pcall(function() getSoundManager():playUISound(n or "UIActivateButton") end) end
local function stoppable(r) return (r.k == "radio" or r.k == "check" or r.k == "field" or r.k == "swatch") and not r.disabled end

ZeD_FormCard = ZeD_Window:derive("ZeD_FormCard")

function ZeD_FormCard:new(spec)
    local o = ZeD_Window.new(self, 0, 0, 100, 100, spec.title or "")
    o.spec = spec
    o.resizable = false
    o.pin = true
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o.moveWithMouse = false
    o.playerNum = spec.playerNum or 0
    o._fields = {}
    o._scroll = 0
    o._focus = 1
    return o
end

function ZeD_FormCard:createChildren()
    ZeD_Window.createChildren(self)
    self.minimumWidth, self.minimumHeight = 0, 0
end

-- the text in a field (its first text until the field is made)
function ZeD_FormCard:text(id)
    local e = self._fields[id]
    if e and e.javaObject then return e:getInternalText() end
    for _, r in ipairs(self._rows or {}) do if r.k == "field" and r.id == id then return tostring(r.value or "") end end
    return ""
end

function ZeD_FormCard:field(r)
    local e = self._fields[r.id]
    if e then return e end
    e = ISTextEntryBox:new(tostring(r.value or ""), 0, 0, 100, 24)
    e:initialise()
    e:instantiate()
    e.zedEntry = true
    e.font = (ZeD.Text and ZeD.Text.entryFont) and ZeD.Text.entryFont() or UIFont.Small
    if r.numbers then e:setOnlyNumbers(true) end
    e.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    e.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self:addChild(e)
    self._fields[r.id] = e
    return e
end

-- ---------------------------------------------------------------------------
-- LAYOUT (every frame, from the live tokens)
-- ---------------------------------------------------------------------------
local function rowH(r, w)
    local T = ZeD.T
    if r.k == "label" then return fh(T.fontF1) + px(4) end
    if r.k == "line" then
        r._lines = ZeD.Atoms.wrapText(tostring(r.text or ""), T.fontF2, math.max(1, w))
        return #r._lines * fh(T.fontF2)
    end
    if r.k == "fact" then return math.max(fh(T.fontF1), fh(T.fontF2)) + px(2) end
    if r.k == "field" then return px(U.FIELD_H) end
    return math.max(T.buttonH - px(4), fh(T.fontF2) + px(6))
end

function ZeD_FormCard:layout()
    local T = ZeD.T
    local spec = self.spec
    local w = px(spec.width or U.W)
    local pad = px(U.PAD)
    local tb = self:titleBarHeight()
    local rows = spec.rows(self) or {}
    self._rows = rows
    -- the label column (fields, facts and swatches line up on it)
    local lw = 0
    for _, r in ipairs(rows) do
        if (r.k == "field" or r.k == "fact" or r.k == "swatch") and r.label then lw = math.max(lw, tw(T.fontF1, r.label)) end
    end
    lw = math.min(lw, math.floor((w - pad * 2) * 0.5))
    self._lw = lw
    local headH = 0
    if spec.head then headH = px(U.HEAD_ICON) + pad end
    local y = 0
    for i, r in ipairs(rows) do
        if r.k == "label" and i > 1 then y = y + px(8) end
        local ind = r.ind and px(r.ind) or 0
        r._x, r._w = pad + ind, w - pad * 2 - ind
        r._h = rowH(r, r._w)
        r._y = y
        y = y + r._h + px(U.ROW_GAP)
    end
    local bodyH = math.max(0, y - px(U.ROW_GAP))
    local band = spec.band(self) or {}
    self._band = band
    local fixed = tb + headH + pad * 2 + ZeD.Molecules.bandH() + self:footerHeight()
    local maxBody = math.floor(getCore():getScreenHeight() * U.MAX_H) - fixed
    local viewH = math.max(px(60), math.min(bodyH, maxBody))
    self._view = { x = 0, y = tb + headH + pad, w = w, h = viewH, total = bodyH }
    self._maxScroll = math.max(0, bodyH - viewH)
    self._scroll = math.max(0, math.min(self._scroll, self._maxScroll))
    local h = fixed + viewH
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    -- placed once: centered on the spec's point (or the screen), kept on screen
    if not self._placed then
        self._placed = true
        local cx = spec.cx or math.floor(getCore():getScreenWidth() / 2)
        local cy = spec.cy or math.floor(getCore():getScreenHeight() / 2)
        local x = math.max(0, math.min(cx - math.floor(w / 2), getCore():getScreenWidth() - w))
        local yy = math.max(0, math.min(cy - math.floor(h / 2), getCore():getScreenHeight() - h))
        self:setX(x); self:setY(yy)
    end
end

-- the controller's stops: the rows that take a press, then the band's live buttons
function ZeD_FormCard:stops()
    local out = {}
    for _, r in ipairs(self._rows or {}) do if stoppable(r) then out[#out + 1] = { row = r } end end
    for i, b in ipairs((self._band and self._band.buttons) or {}) do
        if not b.disabled then out[#out + 1] = { btn = b, i = i } end
    end
    return out
end

function ZeD_FormCard:focused()
    if not self.joyfocus then return nil end
    local s = self:stops()
    if #s == 0 then return nil end
    self._focus = math.max(1, math.min(self._focus or 1, #s))
    return s[self._focus]
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
local function insetBox(p, x, y, w, h)
    local T = ZeD.T
    local b, bs = T.base, T.borderS
    p:drawRect(x, y, w, h, 1, b.r, b.g, b.b)
    p:drawRectBorder(x, y, w, h, bs.a or 1, bs.r, bs.g, bs.b)
    p:drawRect(x + px(1), y + px(1), w - 2 * px(1), px(1), 0.45, 0, 0, 0)
    p:drawRect(x + px(1), y + px(1), px(1), h - 2 * px(1), 0.45, 0, 0, 0)
end

local _fo = {}
local function focusOpts(self) _fo.win, _fo.pad, _fo.focused = self, true, true; return _fo end

function ZeD_FormCard:prerender()
    local T = ZeD.T
    self.minimumWidth, self.minimumHeight = 0, 0
    self:layout()
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    local A, M = ZeD.Atoms, ZeD.Molecules
    local spec = self.spec
    local w = self.width
    local pad = px(U.PAD)
    local tb = self:titleBarHeight()
    local mx, my = self:getMouseX(), self:getMouseY()
    local mouse = not self.joyfocus and self:isMouseOver()
    local foc = self:focused()
    local hits = {}
    self._hits = hits
    if spec.help then ZeD.Help.set(self, spec.help) end
    -- the head: the picture, the name, the line under it (an item card's head)
    if spec.head then
        local hd = spec.head
        local s = px(U.HEAD_ICON)
        local x = pad
        if hd.tex then pcall(function() self:drawTextureScaledAspect(hd.tex, x, tb + pad, s, s, 1, 1, 1, 1) end); x = x + s + px(10) end
        local tc, dc = T.textHead or T.text, T.textDim
        local room = w - pad - x
        self:drawText(A.truncateText(tostring(hd.name or ""), T.fontF4, room), x, tb + pad, tc.r, tc.g, tc.b, tc.a or 1, T.fontF4)
        if hd.sub then self:drawText(A.truncateText(tostring(hd.sub), T.fontF3, room), x, tb + pad + fh(T.fontF4), dc.r, dc.g, dc.b, dc.a or 1, T.fontF3) end
        A.drawDividerH(self, 0, tb + pad + s + math.floor(pad / 2), w, false)
    end
    -- the rows, scrolled inside the view
    local v = self._view
    self:setStencilRect(0, v.y, w, v.h)
    for _, r in ipairs(self._rows) do
        local y = v.y + r._y - self._scroll
        local inView = y >= v.y and y + r._h <= v.y + v.h
        local x, rw, h = r._x, r._w, r._h
        local hot = mouse and inView and mx >= x and mx < x + rw and my >= y and my < y + h and not r.disabled
        local onF = foc and foc.row == r
        local tc = T.text
        if r.k == "label" then
            local c = T.textHead or T.text
            self:drawText(tostring(r.text or ""), x, y, c.r, c.g, c.b, c.a or 1, T.fontF1)
        elseif r.k == "line" then
            local d = T.textDim
            for i, s in ipairs(r._lines or {}) do self:drawText(s, x, y + (i - 1) * fh(T.fontF2), d.r, d.g, d.b, d.a or 1, T.fontF2) end
        elseif r.k == "fact" then
            local lc = T.textHead or T.text
            self:drawText(A.truncateText(tostring(r.label or ""), T.fontF1, self._lw), x, y, lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
            local vx = x + self._lw + px(10)
            self:drawText(A.truncateText(tostring(r.value or ""), T.fontF2, x + rw - vx), vx, y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        elseif r.k == "radio" or r.k == "check" then
            if hot then local hv = T.hover; self:drawRect(x, y, rw, h, hv.a or 1, hv.r, hv.g, hv.b) end
            local swap = onF and ZeD.Focus.mark(self, x, y, rw, h, focusOpts(self)) or false
            local sz = (r.k == "radio") and A.radioSize() or T.checkboxSz
            local sy = y + math.floor((h - sz) / 2)
            if r.k == "radio" then A.drawRadio(self, x + px(3), sy, r.on, { hover = hot, disabled = r.disabled })
            else A.drawCheckbox(self, x + px(3), sy, r.on, hot, r.disabled) end
            local c = swap and T.textOnFocus or T.text
            self:drawText(A.truncateText(tostring(r.text or ""), T.fontF2, rw - sz - px(12)), x + px(3) + sz + px(6), y + math.floor((h - fh(T.fontF2)) / 2),
                c.r, c.g, c.b, (c.a or 1) * (r.disabled and T.disabledAlpha or 1), T.fontF2)
            if inView then hits[#hits + 1] = { x = x, y = y, w = rw, h = h, row = r } end
        elseif r.k == "field" or r.k == "swatch" then
            local lc = T.textHead or T.text
            local fx = x + self._lw + px(10)
            local fw = x + rw - fx
            self:drawText(A.truncateText(tostring(r.label or ""), T.fontF1, self._lw), x, y + math.floor((h - fh(T.fontF1)) / 2), lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
            if onF then ZeD.Focus.mark(self, fx - px(2), y - px(2), (r.k == "swatch" and h or fw) + px(4), h + px(4), focusOpts(self)) end
            if r.k == "field" then
                insetBox(self, fx, y, fw, h)
                local e = self:field(r)
                local eh = fh(e.font or UIFont.Small) + px(2)
                local ex, ey, ew = fx + px(6), y + math.floor((h - eh) / 2), fw - px(12)
                if e.x ~= ex or e.y ~= ey then e:setX(ex); e:setY(ey) end
                if e.width ~= ew or e.height ~= eh then e:setWidth(ew); e:setHeight(eh) end
                local show = inView and not r.disabled
                if e:isVisible() ~= show then e:setVisible(show) end
                if r.disabled then
                    local d = T.textDim
                    self:drawText(A.truncateText(tostring(r.value or ""), T.fontF2, fw - px(12)), fx + px(6), y + math.floor((h - fh(T.fontF2)) / 2), d.r, d.g, d.b, d.a or 1, T.fontF2)
                end
                if inView then hits[#hits + 1] = { x = fx, y = y, w = fw, h = h, row = r } end
            else
                local c = r.color or { r = 1, g = 1, b = 1 }
                self:drawRect(fx, y, h, h, 1, c.r, c.g, c.b)
                A.frame(self, fx, y, h, h, T.borderS)
                if hot then local hv = T.hover; self:drawRect(fx, y, h, h, hv.a or 1, hv.r, hv.g, hv.b) end
                if inView then hits[#hits + 1] = { x = fx, y = y, w = h, h = h, row = r } end
            end
        end
        if hot and r.help then ZeD.Help.set(self, r.help) end
    end
    self:clearStencilRect()
    self:setStencilRect(0, 0, w, self.height)
    -- the scroll, as a thin bar at the right of the view
    if self._maxScroll > 0 then
        local bw = px(4)
        local th = math.max(px(20), math.floor(v.h * v.h / math.max(1, v.total)))
        local ty = v.y + math.floor((v.h - th) * self._scroll / self._maxScroll)
        local d = T.textDim
        self:drawRect(w - bw - px(2), ty, bw, th, 0.6, d.r, d.g, d.b)
    end
    -- the band: the answers, the main one last
    local by = self.height - self:footerHeight() - M.bandH()
    local list = {}
    for i, b in ipairs(self._band.buttons or {}) do
        local f = foc and foc.btn == b
        local hv = nil                          -- (nil: the band tests the pointer itself)
        if not mouse or b.disabled then hv = false end
        list[i] = { label = b.text, variant = b.variant, disabled = b.disabled, id = b.id, help = b.help,
            hover = hv, focus = f and focusOpts(self) or nil }
    end
    local _, out = M.drawBand(self, 0, by, w, { buttons = list, question = self._band.ask, win = self })
    for i, b in ipairs(self._band.buttons or {}) do
        local rr = out.buttons[i]
        if rr then hits[#hits + 1] = { x = rr.x, y = rr.y, w = rr.w, h = rr.h, btn = b } end
    end
    self:clearStencilRect()
end

function ZeD_FormCard:render() ZeD_Window.render(self) end

function ZeD_FormCard:getFooterPrompts()
    if not self.joyfocus then return nil end
    local f = self:focused()
    local a = ZeD.tr("UI_ZeD_Prompt_Press")
    if f and f.row and f.row.k == "field" then a = ZeD.tr("UI_ZeD_Prompt_Keyboard") end
    return { { glyph = "A", label = a }, { glyph = "B", label = ZeD.tr("UI_Cancel") } }
end

-- ---------------------------------------------------------------------------
-- ACTING
-- ---------------------------------------------------------------------------
function ZeD_FormCard:pressRow(r)
    if not r or r.disabled then return end
    if r.k == "field" then
        local e = self:field(r)
        if self.joyfocus then return self:openKeyboard(e) end
        e:focus()
        return
    end
    sound(r.k == "check" and "UIToggleTickBox" or "UIActivateButton")
    if r.run then r.run(self, r) end
end

function ZeD_FormCard:pressButton(b)
    if not b or b.disabled then return end
    sound("UIActivateButton")
    if b.run then b.run(self) end
end

function ZeD_FormCard:openKeyboard(e)
    local jd = self.joyfocus
    if not (e and jd and OnScreenKeyboard and OnScreenKeyboard.Show) then return end
    local osk = OnScreenKeyboard.Show(jd.player or self.playerNum, e, jd)
    if osk then
        osk.prevFocus = self
        jd.focus = osk
        updateJoypadFocus(jd)
    end
end

-- closes the card: its fields let go of the keyboard, the controller goes back where it was
function ZeD_FormCard:finish()
    if self._done then return end
    self._done = true
    for _, e in pairs(self._fields) do
        if e and e.javaObject and e:isFocused() then e:unfocus() end
    end
    self:setVisible(false)
    self:removeFromUIManager()
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    if jd and jd.focus == self then
        jd.focus = self.prevFocus
        updateJoypadFocus(jd)
    end
    if self.spec.onFinish then pcall(self.spec.onFinish, self) end
end

function ZeD_FormCard:cancel()
    if self.spec.cancel then self.spec.cancel(self) else self:finish() end
end

-- the close box (ZeD_Window:update)
function ZeD_FormCard:close() self:cancel() end

-- ---------------------------------------------------------------------------
-- MOUSE
-- ---------------------------------------------------------------------------
function ZeD_FormCard:hitAt(x, y)
    for _, h in ipairs(self._hits or {}) do if inRect(h, x, y) then return h end end
    return nil
end

function ZeD_FormCard:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then return true end
    if y < self:titleBarHeight() then self.moving = true; self:bringToTop(); return true end
    self._down = self:hitAt(x, y)
    return true
end

function ZeD_FormCard:onMouseUp(x, y)
    self.moving = false
    local d = self._down
    self._down = nil
    local h = self:hitAt(x, y)
    if d and h and ((d.row and d.row == h.row) or (d.btn and d.btn == h.btn)) then
        if h.row then self:pressRow(h.row) else self:pressButton(h.btn) end
    end
    return true
end

function ZeD_FormCard:onMouseUpOutside(x, y) self.moving = false; self._down = nil; return true end

function ZeD_FormCard:onMouseMove(dx, dy)
    if self.moving then self:setX(self:getX() + dx); self:setY(self:getY() + dy) end
    return true
end
function ZeD_FormCard:onMouseMoveOutside(dx, dy)
    if self.moving then self:setX(self:getX() + dx); self:setY(self:getY() + dy) end
end

function ZeD_FormCard:onMouseWheel(del)
    if (self._maxScroll or 0) > 0 then
        self._scroll = math.max(0, math.min(self._maxScroll, self._scroll + ((del > 0) and 1 or -1) * px(40)))
    end
    return true
end

function ZeD_FormCard:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then self:cancel(); return true end
    return false
end

function ZeD_FormCard:update()
    ZeD_Window.update(self)
    if self._done then return end
    local jf = nil
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    if jd and jd.focus == self then jf = jd end
    if FC.qaJoy then jf = FC.qaJoy end
    self.joyfocus = jf
end

-- ---------------------------------------------------------------------------
-- CONTROLLER
-- ---------------------------------------------------------------------------
function ZeD_FormCard:onGainJoypadFocus(jd) self.joyfocus = jd end
function ZeD_FormCard:onLoseJoypadFocus(jd) self.joyfocus = nil end

-- keep the focused row in the view
function ZeD_FormCard:showFocus()
    local f = self:focused()
    local r = f and f.row
    local v = self._view
    if not (r and v) then return end
    if r._y < self._scroll then self._scroll = r._y
    elseif r._y + r._h > self._scroll + v.h then self._scroll = r._y + r._h - v.h end
end

function ZeD_FormCard:step(d)
    local s = self:stops()
    if #s == 0 then return end
    local n = math.max(1, math.min((self._focus or 1) + d, #s))
    if n ~= self._focus then self._focus = n; sound("UISelectListItem") end
    self:showFocus()
end

function ZeD_FormCard:onJoypadDown(button, jd)
    self.joyfocus = self.joyfocus or jd
    if button == Joypad.AButton then
        local f = self:focused()
        if f and f.row then self:pressRow(f.row) elseif f and f.btn then self:pressButton(f.btn) end
    elseif button == Joypad.BButton then
        self:cancel()
    end
end
function ZeD_FormCard:onJoypadDirUp() self:step(-1) end
function ZeD_FormCard:onJoypadDirDown() self:step(1) end
function ZeD_FormCard:onJoypadDirLeft()
    local f = self:focused()
    if f and f.btn then self:step(-1) end
end
function ZeD_FormCard:onJoypadDirRight()
    local f = self:focused()
    if f and f.btn then self:step(1) end
end

-- ---------------------------------------------------------------------------
-- OPENING ONE
-- ---------------------------------------------------------------------------
function FC.open(spec)
    local card = ZeD_FormCard:new(spec)
    card:initialise()
    card:instantiate()
    card:addToUIManager()
    card:setAlwaysOnTop(true)
    card:layout()
    local jd = JoypadState and JoypadState.players and JoypadState.players[card.playerNum + 1]
    if jd then
        card.prevFocus = jd.focus
        setJoypadFocus(card.playerNum, card)
    end
    return card
end

return FC
