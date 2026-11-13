-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ControllerMap.lua
-- ============================================================================
-- THE CONTROLLER MAP — every pad button and what it does, on one page to read. Client organism (a ZeD_Window).
-- The ZeD pad in its pixel art (ZeD_PadFigure: the same drawing as Options > Controls > Button map and test, with
-- the face buttons of the player's button pictures, at the largest whole multiple the window's width holds), then
-- the table of buttons and what each does, every button drawn in the player's own button pictures (ZeD_PadGlyphs:
-- Xbox, PlayStation, Steam Deck, Nintendo), or named in a box when the pictures are off.
--
-- Opened from the controller's quick wheel (Help, Controller map).
-- A full-card-wide window centred on the screen; the body scrolls as one piece when the screen is short (the mouse
-- wheel, the D-pad or the left stick up and down). A or B, Escape or the close box close it, and the controller goes
-- back to the game.
-- ============================================================================
require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ZeD_PadFigure"
ZeD = ZeD or {}
ZeD.ControllerMap = ZeD.ControllerMap or {}
local CM = ZeD.ControllerMap
CM.windows = CM.windows or {}

local W_U = 480            -- the full card's width (design units), the widest a new surface goes
local ROW_GAP_U, PIC_U, NAME_COL_U = 6, 16, 92
local STEP_U = 40          -- one D-pad press of scroll

-- The rows: the button(s), then what it does.
-- roles are ZeD_PadGlyphs roles; key is the translation key of the words.
CM.ROWS = {
    { { "A" },          "UI_ZeD_CMap_A" },
    { { "X" },          "UI_ZeD_CMap_X" },
    { { "B" },          "UI_ZeD_CMap_B" },
    { { "Y" },          "UI_ZeD_CMap_Y" },
    { { "DPAD" },       "UI_ZeD_CMap_DPad" },
    { { "LS" },         "UI_ZeD_CMap_LS" },
    { { "RS" },         "UI_ZeD_CMap_RS" },
    { { "LB" },         "UI_ZeD_CMap_LB" },
    { { "RB" },         "UI_ZeD_CMap_RB" },
    { { "LT", "RT" },   "UI_ZeD_CMap_Triggers" },
    { { "SEL" },        "UI_ZeD_CMap_View" },
    { { "START" },      "UI_ZeD_CMap_Menu" },
}

local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

ZeD_ControllerMap = ZeD_Window:derive("ZeD_ControllerMap")

function ZeD_ControllerMap:new(playerNum)
    local o = ZeD_Window.new(self, 0, 0, 100, 100, "")
    o.resizable = false
    o.pin = true
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o.moveWithMouse = false
    o.playerNum = playerNum or 0
    o.scroll = 0
    o._contentH = 0
    o._down = nil
    o:setWantKeyEvents(true)
    return o
end

function ZeD_ControllerMap:createChildren()
    ZeD_Window.createChildren(self)
    self.minimumWidth, self.minimumHeight = 0, 0
end

function ZeD_ControllerMap:close()
    self:setVisible(false)
    self:removeFromUIManager()
    local jd = JoypadState.players[self.playerNum + 1]
    if jd and jd.focus == self then setJoypadFocus(self.playerNum, nil) end
end

-- a button's picture (or its name in a box when the pictures are off), returns its width
local function drawButton(panel, roles, x, y, h)
    local T = ZeD.T
    local PG = ZeD.PadGlyphs
    local set = PG and PG.set()
    if PG and set then
        local k = PG.k(h)
        return PG.draw(panel, roles, x, y, h, k, set)
    end
    -- the pictures are off (Keyboard/mouse or Off): the names, each in a box
    local f = T.fontF1
    local tm = ZeD.TM
    local cx = x
    for i, r in ipairs(roles) do
        local name = (PG and PG.name) and PG.name(r, "xbox") or r
        if r == "DPAD" then name = "D-pad" elseif r == "LS" then name = "L-stick" elseif r == "RS" then name = "R-stick" end
        local tw = tm:MeasureStringX(f, name) + T.px(8)
        local bh = math.min(h, T.px(16))
        local by = y + math.floor((h - bh) / 2)
        local b = T.border
        panel:drawRectBorder(cx, by, tw, bh, b.a or 1, b.r, b.g, b.b)
        local fh = tm:getFontHeight(f)
        panel:drawText(name, cx + T.px(4), by + math.floor((bh - fh) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f)
        cx = cx + tw + ((i < #roles) and T.px(4) or 0)
    end
    return cx - x
end

function ZeD_ControllerMap:prerender()
    local T = ZeD.T
    if not T then return end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local w = math.min(T.px(W_U), sw - T.px(20))
    local margin = T.px(14)
    local tbH = self:titleBarHeight()
    local fH = self:footerHeight()
    local inner = w - 2 * margin
    -- the body's height: the pad picture, a gap, the table
    local f2 = T.fontF2
    local fh2 = T.fontF2H or ZeD.TM:getFontHeight(f2)
    local nameW = T.px(NAME_COL_U)
    local textW = inner - nameW
    -- the pad: whole multiples only (k screen px to an art pixel), the largest the inner width holds
    local PF = ZeD.PadFigure
    local padK = PF.k(inner)
    local padW, padH = PF.CW * padK, PF.CH * padK
    local rows = {}
    local total = margin + padH + T.px(10)
    for _, r in ipairs(CM.ROWS) do
        local lines = ZeD.Atoms.wrapText(ZeD.tr(r[2]), f2, textW)
        local rh = math.max(T.px(PIC_U + 4), #lines * (fh2 + T.px(2)))
        rows[#rows + 1] = { roles = r[1], lines = lines, h = rh }
        total = total + rh + T.px(ROW_GAP_U)
    end
    total = total + margin
    self._contentH = total
    local maxBody = sh - tbH - fH - T.px(40)
    local bodyH = math.min(total, maxBody)
    local h = tbH + bodyH + fH
    if self.width ~= w or self.height ~= h then
        self:setWidth(w); self:setHeight(h)
        self:setX(math.floor((sw - w) / 2))
        self:setY(math.floor((sh - h) / 2))
    end
    self.title = ZeD.tr("UI_ZeD_Wheel_ControllerMap")
    self._bodyH = bodyH
    self.scroll = math.max(0, math.min(self.scroll or 0, total - bodyH))
    self.minimumWidth, self.minimumHeight = 0, 0
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    ZeD.Help.set(self, ZeD.tr("UI_ZeD_CMap_Help"))

    -- the body, clipped and scrolled as one piece
    self:setStencilRect(0, tbH, w, bodyH)
    local y = tbH + margin - self.scroll
    local PG = ZeD.PadGlyphs
    PF.draw(self, margin + math.floor((inner - padW) / 2), y, padK, (PG and PG.set()) or "xbox", nil)
    y = y + padH + T.px(10)
    local A = ZeD.Atoms
    if A and A.drawDividerH then A.drawDividerH(self, margin, y - T.px(5), inner, false) end
    local tc = T.text
    for _, r in ipairs(rows) do
        drawButton(self, r.roles, margin, y, T.px(PIC_U + 4))
        local ty = y + math.floor((math.max(T.px(PIC_U + 4), fh2) - fh2) / 2)
        for i, l in ipairs(r.lines) do
            self:drawText(l, margin + nameW, ty + (i - 1) * (fh2 + T.px(2)), tc.r, tc.g, tc.b, tc.a or 1, f2)
        end
        y = y + r.h + T.px(ROW_GAP_U)
    end
    self:clearStencilRect()
    -- a scroll mark at the right edge while the body runs past the window
    if total > bodyH then
        local ac = T.accent
        local th = math.max(T.px(20), math.floor(bodyH * bodyH / total))
        local ty = tbH + math.floor((bodyH - th) * self.scroll / (total - bodyH))
        self:drawRect(w - T.px(4), ty, T.px(2), th, 0.8, ac.r, ac.g, ac.b)
    end
end

function ZeD_ControllerMap:render() ZeD_Window.render(self) end

-- always solid: a page to read, whatever See-through says (with the shared alpha the game showed through the table's words)
function ZeD_ControllerMap:_surfaceAlpha(T)
    local base = (T.surf1 and T.surf1.a) or 1
    if base >= 0.999 then return nil end
    return 1
end

function ZeD_ControllerMap:getFooterPrompts()
    if not self.joyfocus then return nil end
    local out = {}
    if (self._contentH or 0) > (self._bodyH or 0) then out[#out + 1] = { glyph = "D-PAD", label = ZeD.tr("UI_ZeD_CMap_Scroll") } end
    out[#out + 1] = { glyph = "B", label = ZeD.tr("UI_ZeD_Close") }
    return out
end

function ZeD_ControllerMap:update()
    ZeD_Window.update(self)
    if not self:getIsVisible() then return end
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    self.joyfocus = (jd and jd.focus == self) and jd or (CM.qaJoy and self or nil)
end

function ZeD_ControllerMap:scrollBy(d)
    local maxS = math.max(0, (self._contentH or 0) - (self._bodyH or 0))
    self.scroll = math.max(0, math.min(maxS, (self.scroll or 0) + d))
end

-- ---------------------------------------------------------------------------
-- MOUSE, KEYS AND CONTROLLER
-- ---------------------------------------------------------------------------
function ZeD_ControllerMap:onMouseDown(x, y)
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then self._down = "close" end
    return true
end
function ZeD_ControllerMap:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    if down == "close" then
        local cb = self:closeRect()
        if cb and inRect(cb, x, y) then getSoundManager():playUISound("UIActivateButton") end
    end
    return true
end
function ZeD_ControllerMap:onMouseUpOutside() self._down = nil end
function ZeD_ControllerMap:onMouseWheel(del) self:scrollBy(del * ZeD.T.px(STEP_U)); return true end

function ZeD_ControllerMap:isKeyConsumed(key) return key == Keyboard.KEY_ESCAPE end
function ZeD_ControllerMap:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then self:close(); GameKeyboard.eatKeyPress(key) end
end

function ZeD_ControllerMap:onGainJoypadFocus(jd) self.joyfocus = jd end
function ZeD_ControllerMap:onLoseJoypadFocus() self.joyfocus = nil end
function ZeD_ControllerMap:onJoypadDown(button)
    if button == Joypad.BButton then self:close() end   -- (B only, as the foot says: A has no job here)
end
function ZeD_ControllerMap:onJoypadDirUp() self:scrollBy(-ZeD.T.px(STEP_U)) end
function ZeD_ControllerMap:onJoypadDirDown() self:scrollBy(ZeD.T.px(STEP_U)) end

-- ---------------------------------------------------------------------------
-- ENTRY
-- ---------------------------------------------------------------------------
function CM.open(pn)
    pn = pn or 0
    local win = CM.windows[pn]
    if not win then
        win = ZeD_ControllerMap:new(pn)
        win:initialise()
        win:instantiate()
        CM.windows[pn] = win
    end
    win.scroll = 0
    if not win:isReallyVisible() then
        win:setVisible(true)
        win:addToUIManager()
        win:setAlwaysOnTop(true)
    end
    local jd = JoypadState.players[pn + 1]
    if jd then jd.focus = win; updateJoypadFocus(jd) end
    return win
end

function CM.close(pn)
    local win = CM.windows[pn or 0]
    if win and win:isReallyVisible() then win:close() end
end

-- Escape from anywhere: the map on screen closes
function CM.takeEscape()
    for _, win in pairs(CM.windows) do
        if win and win:isReallyVisible() then win:close(); return true end
    end
    return false
end
ZeD.EscapeTakers = ZeD.EscapeTakers or {}
ZeD.EscapeTakers.controllerMap = CM.takeEscape

return CM
