-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Keyboard.lua
-- ============================================================================
-- THE KEYBOARD — vanilla's on-screen keyboard (a controller on a text field)
-- as a ZeD window. Approved with the prompts (Oct 15 2026; mockup
-- ZeDUI/mockups/zed_dialogs_v1.html, scene Keyboard; HOOK_MAP row 28).
--
-- Vanilla's keys and button map, on ZeD keys: X deletes, Y is a space, LT
-- (held) is shift, L3 caps, RT accepts, B cancels, LB / RB move the caret,
-- the D-pad moves between keys and A presses one. It types straight into the
-- field it was opened for (the field's own rules hold: numbers only, length,
-- masking); Cancel puts the field back as it was.
--
-- Under a prompt's field it docks below the prompt (the field shows the text).
-- For any other field (the menus) it sits at the bottom of the player's part
-- of the screen with its own line showing the field's text.
--
-- OnScreenKeyboard (vanilla's API: Show, IsVisible, Hide, GetCurrentText and
-- .instance) is pointed at this one by Overrides/Prompts.lua.
-- ============================================================================

require "ISUI/ISTextEntryBox"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"

ZeD = ZeD or {}
ZeD.Keyboard = ZeD.Keyboard or {}
local KB = ZeD.Keyboard

-- design units
local U = { KEY_W = 30, KEY_H = 28, GAP = 6, PAD = 10, LINE_H = 30, GAP_TO_PROMPT = 8, BOTTOM = 16, MARGIN = 8, FN_PAD = 8 }

local function clamp(v, lo, hi) if v < lo then return lo end if v > hi then return hi end return v end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UISelectListItem") end) end

-- ---------------------------------------------------------------------------
-- the keys (vanilla's layout)
-- ---------------------------------------------------------------------------
local function chars(lo, up)
    local row = {}
    for i = 1, #lo do row[#row + 1] = { lo = lo:sub(i, i), up = up:sub(i, i) } end
    return row
end
local function fn(id, label, glyph, opts)
    local k = { id = id, label = label, glyph = glyph }
    if opts then for kk, v in pairs(opts) do k[kk] = v end end
    return k
end
local function append(row, ...)
    for _, k in ipairs({ ... }) do row[#row + 1] = k end
    return row
end
local function appendAll(row, list)
    for _, k in ipairs(list) do row[#row + 1] = k end
    return row
end

local function buildRows(multi, masked)
    local r1 = append(chars("`1234567890-=", "~!@#$%^&*()_+"), fn("delete", getText("IGUI_Keyboard_Delete"), "X"))
    local r2 = chars("qwertyuiop[]\\", "QWERTYUIOP{}|")
    local r3 = { fn("caps", getText("IGUI_Keyboard_Caps"), "L3") }
    appendAll(r3, chars("asdfghjkl;'", "ASDFGHJKL:\""))
    append(r3, fn("accept", multi and getText("IGUI_Keyboard_Enter") or getText("IGUI_Keyboard_Accept"), "RT", { primary = true }))
    local r4 = { fn("shift", getText("IGUI_Keyboard_Shift"), "LT") }
    appendAll(r4, chars("zxcvbnm,./", "ZXCVBNM<>?"))
    append(r4, fn("shift", getText("IGUI_Keyboard_Shift"), "LT"))
    local r5 = {}
    if masked then r5[#r5 + 1] = fn("show", ZeD.tr("UI_ZeD_Keyboard_Show"), nil) end
    append(r5, fn("space", getText("IGUI_Keyboard_Space"), "Y", { wide = true }), fn("left", "<", "LB"), fn("right", ">", "RB"),
        fn("cancel", getText("IGUI_Keyboard_Cancel"), "B"))
    return { r1, r2, r3, r4, r5 }
end

-- ---------------------------------------------------------------------------
-- THE CLASS
-- ---------------------------------------------------------------------------
ZeD_Keyboard = ZeD_Window:derive("ZeD_Keyboard")
-- vanilla's text field keeps its caret while the keyboard holds the controller,
-- by this name (ISTextEntryBox:setJoypadFocused)
ZeD_Keyboard.Type = "ISOnScreenKeyboard"

function ZeD_Keyboard:new()
    local o = ZeD_Window.new(self, 0, 0, 100, 100, "")
    o.resizable = false
    o.noResetControl = true   -- (it docks itself under its prompt or at the screen's foot every frame)
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.9 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.keepOnScreen = false
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o._focus = { 3, 6 }   -- vanilla's first key: g
    return o
end

function ZeD_Keyboard:createChildren()
    ZeD_Window.createChildren(self)
    self._closeBtnRect = nil   -- no close box: Cancel is a key
    self.minimumWidth, self.minimumHeight = 0, 0
end

-- the field this keyboard types into belongs to a ZeD prompt?
function ZeD_Keyboard:prompt()
    local e = self.textEntryBox
    local p = e and e.parent
    if p and p.kind and p.entry == e then return p end
    return nil
end

function ZeD_Keyboard:upperOn()
    return self.capsLock or self.shiftDown
end

-- ---------------------------------------------------------------------------
-- vanilla's instance API (OnScreenKeyboard.Show / Hide / GetCurrentText call these)
-- ---------------------------------------------------------------------------
function ZeD_Keyboard:show(playerNum, textEntryBox, joypadData)
    self.playerNum = playerNum
    self.textEntryBox = textEntryBox
    self.joypadData = joypadData
    self._orig = textEntryBox and textEntryBox:getInternalText() or ""
    self._masked = textEntryBox and textEntryBox.javaObject and textEntryBox:isMasked() or false
    self._showPlain = false
    self._multi = textEntryBox and textEntryBox.javaObject and textEntryBox:isMultipleLine() or false
    self._rows = buildRows(self._multi, self._masked)
    self._focus = { 3, 6 }
    self.capsLock, self.shiftDown = false, false
    self.isRTPressed = joypadData and (joypadData.id or -1) >= 0 and isJoypadRTPressed and isJoypadRTPressed(joypadData.id) or false
    if textEntryBox then textEntryBox:focus() end
    self:setVisible(true)
    self:addToUIManager()
    self:setAlwaysOnTop(true)
    self:layout()
    -- in game, the character stands still while typing (vanilla)
    self.setBlockMovement = false
    local ms = MainScreen and MainScreen.instance
    if ms and ms.inGame then
        local p = playerNum and getSpecificPlayer(playerNum)
        if p and not p:isBlockMovement() then
            self.setBlockMovement = true
            p:setBlockMovement(true)
        end
    end
    return self
end

function ZeD_Keyboard:getCurrentText()
    local e = self.textEntryBox
    return e and e:getInternalText() or ""
end

function ZeD_Keyboard:accept()
    local e = self.textEntryBox
    if e and e.javaObject then e.javaObject:onTextChange() end
    self:hide()
end

function ZeD_Keyboard:cancel()
    local e = self.textEntryBox
    if e and self._orig ~= nil then e:setText(self._orig) end
    self:hide()
end

function ZeD_Keyboard:hide()
    local ms = MainScreen and MainScreen.instance
    if ms and ms.inGame and self.setBlockMovement then
        local p = self.playerNum and getSpecificPlayer(self.playerNum)
        if p then p:setBlockMovement(false) end
    end
    self.setBlockMovement = false
    self:setVisible(false)
    self:removeFromUIManager()
    local e = self.textEntryBox
    if e then e:focus() end
    local jd = self.joyfocus or self.joypadData
    if jd and jd.focus == self then
        jd.focus = self.prevFocus or e
        if updateJoypadFocus then updateJoypadFocus(jd) end
    end
    self.joyfocus = nil
    self.textEntryBox = nil
end

-- ---------------------------------------------------------------------------
-- typing: straight into the field (its own rules apply)
-- ---------------------------------------------------------------------------
function ZeD_Keyboard:typeChar(ch)
    local e = self.textEntryBox
    if not e then return end
    if not e:isFocused() then e:focus() end
    queueCharEvent(ch)
end

function ZeD_Keyboard:keyCode(code)
    local e = self.textEntryBox
    if not e then return end
    if not e:isFocused() then e:focus() end
    queueKeyEvent(code)
end

function ZeD_Keyboard:enter()
    if self._multi and not (self.capsLock or self.shiftDown) then
        self:keyCode(Keyboard.KEY_RETURN)
        return
    end
    self:accept()
end

function ZeD_Keyboard:pressKey(k)
    if not k then return end
    sound("UISelectListItem")
    if k.lo then
        self:typeChar(self:upperOn() and k.up or k.lo)
        -- a shift pressed from the keys lasts one letter
        if self._shiftOnce then self._shiftOnce = false; self.shiftDown = false end
        return
    end
    local id = k.id
    if id == "delete" then return self:keyCode(Keyboard.KEY_BACK) end
    if id == "caps" then self.capsLock = not self.capsLock; return end
    if id == "shift" then self._shiftOnce = not self._shiftOnce; self.shiftDown = self._shiftOnce; return end
    if id == "accept" then return self:enter() end
    if id == "space" then return self:typeChar(" ") end
    if id == "left" then return self:keyCode(Keyboard.KEY_LEFT) end
    if id == "right" then return self:keyCode(Keyboard.KEY_RIGHT) end
    if id == "cancel" then return self:cancel() end
    if id == "show" then self._showPlain = not self._showPlain; return end
end

-- ---------------------------------------------------------------------------
-- LAYOUT
-- ---------------------------------------------------------------------------
-- a key's controller button as ZeD's pixel picture (ZeD_PadGlyphs), or nil for the boxed name
local function padRoles(k)
    local PG = ZeD.PadGlyphs
    if not (PG and PG.set()) then return PG, nil end
    return PG, PG.roles(k.glyph)
end
local function glyphW(k)
    local T = ZeD.T
    local PG, roles = padRoles(k)
    if roles then return PG.width(roles, PG.k(T.px(12))) end
    return math.max(T.px(12), ZeD.TM:MeasureStringX(T.fontF5, k.glyph) + T.px(4))
end

local function keyWidth(k)
    local T = ZeD.T
    if k.lo then return T.px(U.KEY_W) end
    local f = T.fontF3
    local w = ZeD.TM:MeasureStringX(f, ZeD.btnCase(k.label or "")) + T.px(U.FN_PAD) * 2
    if k.glyph then w = w + glyphW(k) + T.px(5) end
    if k.wide then w = math.max(w, T.px(U.KEY_W) * 6) end
    return math.max(w, T.px(U.KEY_W))
end

function ZeD_Keyboard:layout()
    local T = ZeD.T
    if not (T and self._rows) then return end
    local pad, gap, kh = T.px(U.PAD), T.px(U.GAP), T.px(U.KEY_H)
    local rowsW = {}
    local maxRow = 0
    for i, row in ipairs(self._rows) do
        local w = 0
        for j, k in ipairs(row) do w = w + keyWidth(k) + (j > 1 and gap or 0) end
        rowsW[i] = w
        maxRow = math.max(maxRow, w)
    end
    local w = maxRow + pad * 2
    local tbH = T.titleBarH
    local own = self:prompt() == nil   -- a menu field: show its text on our own line
    local y = tbH + pad
    local g = { keys = {} }
    if own then
        g.line = { x = pad, y = y, w = w - pad * 2, h = T.px(U.LINE_H) }
        y = y + g.line.h + gap
    end
    for i, row in ipairs(self._rows) do
        local x = math.floor((w - rowsW[i]) / 2)
        g.keys[i] = {}
        for j, k in ipairs(row) do
            local kw = keyWidth(k)
            g.keys[i][j] = { x = x, y = y, w = kw, h = kh, k = k }
            x = x + kw + gap
        end
        y = y + kh + gap
    end
    local h = y - gap + pad + self:footerHeight()   -- (the help line under the keys)
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    self._g = g
    -- where it sits: under the prompt (moving the prompt up if it must), else the screen's foot
    local m = T.px(U.MARGIN)
    local l, t, sw, sh = 0, 0, getCore():getScreenWidth(), getCore():getScreenHeight()
    if type(self.playerNum) == "number" and getPlayerScreenWidth then
        local ok, a, b, c, d = pcall(function()
            return getPlayerScreenLeft(self.playerNum), getPlayerScreenTop(self.playerNum), getPlayerScreenWidth(self.playerNum), getPlayerScreenHeight(self.playerNum)
        end)
        if ok and c and c > 0 then l, t, sw, sh = a, b, c, d end
    end
    local x, ky
    local p = self:prompt()
    if p then
        local pg = T.px(U.GAP_TO_PROMPT)
        x = p.x + math.floor((p.width - w) / 2)
        ky = p.y + p.height + pg
        if ky + h > t + sh - m then
            local py = t + sh - m - h - pg - p.height
            if py >= t + m then
                p:setY(py)
                ky = py + p.height + pg
            else
                ky = p.y - pg - h
            end
        end
    else
        x = l + math.floor((sw - w) / 2)
        ky = t + sh - h - T.px(U.BOTTOM)
    end
    x = clamp(x, l + m, math.max(l + m, l + sw - w - m))
    ky = clamp(ky, t + m, math.max(t + m, t + sh - h - m))
    if self.x ~= x then self:setX(x) end
    if self.y ~= ky then self:setY(ky) end
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
-- The keyboard holds the controller itself (it is not under FocusManager), so its marks
-- say what has the focus (focused) and that a controller holds it (pad).
local _fo, _keyOpts = {}, {}
local function focusOpts(self)
    _fo.win, _fo.focused, _fo.pad = self, true, true
    return _fo
end

-- what the help line says while the pointer is on a key
local KEY_HELP = {
    delete = "UI_ZeD_Keyboard_HelpDelete", caps = "UI_ZeD_Keyboard_HelpCaps", shift = "UI_ZeD_Keyboard_HelpShift",
    space = "UI_ZeD_Keyboard_HelpSpace", left = "UI_ZeD_Keyboard_HelpLeft", right = "UI_ZeD_Keyboard_HelpRight",
    cancel = "UI_ZeD_Keyboard_HelpCancel", show = "UI_ZeD_Keyboard_HelpShow",
}
local function keyHelp(self, k, up)
    if k.lo then return ZeD.tr("UI_ZeD_Keyboard_HelpChar", up and k.up or k.lo) end
    if k.id == "accept" then return ZeD.tr(self._multi and "UI_ZeD_Keyboard_HelpEnter" or "UI_ZeD_Keyboard_HelpAccept") end
    local key = KEY_HELP[k.id]
    return key and ZeD.tr(key) or nil
end

function ZeD_Keyboard:prerender()
    local T = ZeD.T
    local e = self.textEntryBox
    if not (e and e:isReallyVisible()) then self:hide(); return end
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    self._accentKey = cw and cw._accentKey or nil
    self.minimumWidth, self.minimumHeight = 0, 0   -- see ZeD_Prompt:prerender
    self:layout()
    self:bringToTop()
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    local g = self._g
    if not g then return end
    local A, M = ZeD.Atoms, ZeD.Molecules
    local tc = T.text
    -- the field's text, for a field the keyboard may cover (a typed line: solid, so the text reads)
    if g.line then
        local r = g.line
        local b, bs = T.base, T.borderS
        self:drawRect(r.x, r.y, r.w, r.h, 1, b.r, b.g, b.b)
        self:drawRectBorder(r.x, r.y, r.w, r.h, bs.a or 1, bs.r, bs.g, bs.b)
        self:drawRect(r.x + T.px(1), r.y + T.px(1), r.w - 2 * T.px(1), T.px(1), 0.45, 0, 0, 0)
        self:drawRect(r.x + T.px(1), r.y + T.px(1), T.px(1), r.h - 2 * T.px(1), 0.45, 0, 0, 0)
        local text = e:getInternalText() or ""
        if self._masked and not self._showPlain then text = string.rep("*", #text) end
        local cur = clamp(e:getCursorPos() or #text, 0, #text)
        local f = T.fontF2
        local fhh = ZeD.TM:getFontHeight(f)
        local ty = r.y + math.floor((r.h - fhh) / 2)
        local tx = r.x + T.px(8)
        local maxW = r.w - T.px(16)
        -- keep the caret in view: show the tail when the text is longer than the line
        local shown, offset = text, 0
        while ZeD.TM:MeasureStringX(f, shown) > maxW and #shown > 0 and offset < cur do
            offset = offset + 1
            shown = text:sub(offset + 1)
        end
        shown = A.truncateText(shown, f, maxW)
        self:drawText(shown, tx, ty, tc.r, tc.g, tc.b, tc.a or 1, f)
        local cx = tx + ZeD.TM:MeasureStringX(f, text:sub(offset + 1, cur))
        if math.floor((getTimestampMs() or 0) / 500) % 2 == 0 then
            self:drawRect(cx, ty, T.px(1), fhh, tc.a or 1, tc.r, tc.g, tc.b)
        end
    end
    -- keys: push buttons, the controller's mark on the focused one, the pointed one's help
    local focusOn = self.joyfocus ~= nil
    local up = self:upperOn()
    local wash = focusOn and ZeD.Focus.style() == "wash"   -- (that style puts the words on the focus ink)
    for i, row in ipairs(g.keys) do
        for j, r in ipairs(row) do
            local k = r.k
            local focused = focusOn and self._focus[1] == i and self._focus[2] == j
            local hover = (not focusOn) and self._hover == r
            local down = self._down == r and hover
            local on = (k.id == "caps" and self.capsLock) or (k.id == "shift" and self.shiftDown and not self.capsLock)
            local variant = (k.primary or on) and "primary" or "default"
            local o = _keyOpts
            o.hover, o.focus, o.win = hover, focused and focusOpts(self) or nil, self
            o.help = hover and keyHelp(self, k, up) or nil
            if k.lo then
                M.drawButton(self, r.x, r.y, r.w, r.h, up and k.up or k.lo, variant, down, nil, o)
            else
                M.drawButton(self, r.x, r.y, r.w, r.h, "", variant, down, nil, o)
                -- the button's glyph, then its name
                local f3, f5 = T.fontF3, T.fontF5
                local label = ZeD.btnCase(k.label or "")
                local lw = ZeD.TM:MeasureStringX(f3, label)
                local gw = k.glyph and glyphW(k) or 0
                local total = lw + (k.glyph and (gw + T.px(5)) or 0)
                local x = r.x + math.floor((r.w - total) / 2)
                local ry = r.y
                if down then x = x + T.px(1); ry = ry + T.px(1) end
                local lc = (focused and wash) and T.textOnFocus or ((variant == "primary") and T.accentText or tc)
                if k.glyph then
                    local gh = T.px(12)
                    local gy = ry + math.floor((r.h - gh) / 2)
                    local PG, roles = padRoles(k)
                    if roles then
                        PG.draw(self, roles, x, ry, r.h, PG.k(gh))
                    else
                        local bs = T.borderS
                        self:drawRectBorder(x, gy, gw, gh, bs.a or 1, bs.r, bs.g, bs.b)
                        local gfw = ZeD.TM:MeasureStringX(f5, k.glyph)
                        self:drawText(k.glyph, x + math.floor((gw - gfw) / 2), gy + math.floor((gh - ZeD.TM:getFontHeight(f5)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f5)
                    end
                    x = x + gw + T.px(5)
                end
                self:drawText(label, x, ry + math.floor((r.h - ZeD.TM:getFontHeight(f3)) / 2), lc.r, lc.g, lc.b, lc.a or 1, f3)
            end
        end
    end
end

function ZeD_Keyboard:render()
    ZeD_Window.render(self)
end

-- ---------------------------------------------------------------------------
-- MOUSE
-- ---------------------------------------------------------------------------
function ZeD_Keyboard:keyAt(x, y)
    local g = self._g
    if not g then return nil end
    for _, row in ipairs(g.keys) do
        for _, r in ipairs(row) do if inRect(r, x, y) then return r end end
    end
    return nil
end

function ZeD_Keyboard:onMouseDown(x, y)
    if y < self:titleBarHeight() then self.moving = false; return true end
    self._down = self:keyAt(x, y)
    return true
end

function ZeD_Keyboard:onMouseUp(x, y)
    local d = self._down
    self._down = nil
    if d and self:keyAt(x, y) == d then self:pressKey(d.k) end
    return true
end

function ZeD_Keyboard:onMouseUpOutside() self._down = nil end
function ZeD_Keyboard:onMouseMove() end
function ZeD_Keyboard:onMouseMoveOutside() end

function ZeD_Keyboard:update()
    if ZeD.Prompt and ZeD.Prompt.updateChrome then ZeD.Prompt.updateChrome(self) else ISPanel.update(self) end   -- (the window box)
    self._hover = self:keyAt(self:getMouseX(), self:getMouseY())
    local jd = self.joyfocus or self.joypadData
    if not jd or (jd.id or -1) < 0 then return end
    if JoypadState.controllers and JoypadState.controllers[jd.id] and not JoypadState.controllers[jd.id].connected then
        self:hide(); return
    end
    -- LT held is shift (vanilla)
    local lt = isJoypadLTPressed and isJoypadLTPressed(jd.id) or false
    if not self._shiftOnce then self.shiftDown = lt end
    -- RT: single line accepts on release, several lines on press (vanilla)
    local rt = isJoypadRTPressed and isJoypadRTPressed(jd.id) or false
    if rt and not self.isRTPressed then
        self.isRTPressed = true
        if self._multi then self:enter() end
    elseif not rt and self.isRTPressed then
        self.isRTPressed = false
        if not self._multi then self:accept() end
    end
end

-- ---------------------------------------------------------------------------
-- CONTROLLER
-- ---------------------------------------------------------------------------
-- the help line's prompts while a controller holds the keyboard (the keys name the rest)
function ZeD_Keyboard:getFooterPrompts()
    if not self.joyfocus then return nil end
    local P = ZeD.Prompt
    local move = P and P.padNote and P.padNote(ZeD.tr("UI_ZeD_Prompt_DPadMove")) or ZeD.tr("UI_ZeD_Prompt_DPadMove")
    return { move,
        { glyph = "A", label = ZeD.tr("UI_ZeD_Prompt_Press") },
        { glyph = "RT", label = ZeD.btnCase(getText(self._multi and "IGUI_Keyboard_Enter" or "IGUI_Keyboard_Accept")) },
        { glyph = "B", label = ZeD.btnCase(getText("IGUI_Keyboard_Cancel")) } }
end

function ZeD_Keyboard:onGainJoypadFocus(joypadData) self.joyfocus = joypadData end
function ZeD_Keyboard:onLoseJoypadFocus(joypadData) end

function ZeD_Keyboard:onJoypadDown(button, joypadData)
    self.joyfocus = self.joyfocus or joypadData
    if button == Joypad.AButton then
        local row = self._rows and self._rows[self._focus[1]]
        self:pressKey(row and row[self._focus[2]])
        return
    end
    if button == Joypad.BButton then return self:cancel() end
    if button == Joypad.XButton then sound(); return self:keyCode(Keyboard.KEY_BACK) end
    if button == Joypad.YButton then sound(); return self:typeChar(" ") end
    if button == Joypad.LBumper then return self:keyCode(Keyboard.KEY_LEFT) end
    if button == Joypad.RBumper then return self:keyCode(Keyboard.KEY_RIGHT) end
    if button == Joypad.LStickButton then self.capsLock = not self.capsLock; sound(); return end
end

-- up / down land on the key nearest the same spot in the next row
local function moveRow(self, dr)
    local g = self._g
    if not g then return end
    local r, c = self._focus[1], self._focus[2]
    local nr = clamp(r + dr, 1, #g.keys)
    if nr == r then return end
    local from = g.keys[r][c]
    local cx = from.x + from.w / 2
    local best, bestD = 1, nil
    for j, k in ipairs(g.keys[nr]) do
        local d = math.abs(k.x + k.w / 2 - cx)
        if not bestD or d < bestD then best, bestD = j, d end
    end
    self._focus = { nr, best }
    sound()
end

function ZeD_Keyboard:onJoypadDirUp() moveRow(self, -1) end
function ZeD_Keyboard:onJoypadDirDown() moveRow(self, 1) end
function ZeD_Keyboard:onJoypadDirLeft()
    local row = self._rows[self._focus[1]]
    local c = clamp(self._focus[2] - 1, 1, #row)
    if c ~= self._focus[2] then self._focus[2] = c; sound() end
end
function ZeD_Keyboard:onJoypadDirRight()
    local row = self._rows[self._focus[1]]
    local c = clamp(self._focus[2] + 1, 1, #row)
    if c ~= self._focus[2] then self._focus[2] = c; sound() end
end

-- ---------------------------------------------------------------------------
-- module: one keyboard, made on first use
-- ---------------------------------------------------------------------------
function KB.get()
    if not KB.instance then
        local k = ZeD_Keyboard:new()
        k:initialise()
        k:instantiate()
        KB.instance = k
    end
    return KB.instance
end

function KB.isVisible()
    local k = KB.instance
    return k ~= nil and k.textEntryBox ~= nil and k:isReallyVisible()
end

-- is the keyboard up for this prompt's field?
function KB.isFor(prompt)
    local k = KB.instance
    return k ~= nil and k.textEntryBox ~= nil and prompt ~= nil and k.textEntryBox == prompt.entry
end

function KB.hide()
    if KB.isVisible() then KB.instance:hide() end
end
