-- ZeD-UI/42/media/lua/client/ZeD/TwoWayFull.lua
-- ============================================================================
-- A TWO-WAY RADIO IN FULL VIEW — the radio tab's face on its own over the
-- world, no window frame, like the watch popped from the belt (director, Oct 25
-- 2026: "full view is like the watch, no window frame"; handoff
-- ZeDUI/HANDOFF_twoway_20261025.md, section 3a).
--
-- Opened from the radio tab: the full view button at the header's right end,
-- or a click on any part of the face that is not a control. It is the same
-- plate at the plate scale (TwoWayFace.lua draws it), every control working as
-- in the tab, reading the radio the tab showed. Drag it by any part that is not
-- a control; its place is kept per character (modData ZeD_TwoWayFull, design
-- units). The first time it sits centre right of the play area, clear of the
-- belt.
-- It closes with the tab's button, B or Escape, and by itself when the radio
-- goes out of reach (dropped, taken, walked away from). It does not tuck away
-- on a timer as the watch does: a radio is listened to.
-- Controller: it takes focus while open. The D-pad walks the controls (up /
-- down on a knob turns it), A presses, X stores or names, B closes and gives
-- focus back to the window it was opened from.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Molecules"
require "ZeD/TwoWayFace"

ZeD = ZeD or {}
ZeD.TwoWayFull = ZeD.TwoWayFull or {}
local F = ZeD.TwoWayFull
F.views = F.views or {}
local TW = ZeD.TwoWay
local P = ZeD.Px

local REACH_EVERY = 10         -- frames between the out-of-reach checks
local SHADOW_A = 0.5           -- the face stands up over the world: System 7's hard shadow of its own shape, 1u right and down

local function now() return getTimestampMs() end
local function sound(name) pcall(function() getSoundManager():playUISound(name) end) end
local function zoom() local Sc = ZeD.Scale; return P.k((Sc and Sc.root and Sc.root()) or 1) end

ZeD_TwoWayFull = ISPanel:derive("ZeD_TwoWayFull")

function ZeD_TwoWayFull:new(character)
    local o = ISPanel:new(0, 0, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.moveWithMouse = false
    o.character = character
    o.playerNum = character:getPlayerNum()
    o._zedLabel = "TwoWayFull"
    o.focusId = nil
    o._hits = {}
    o._press = nil         -- { id, t0, fired } while a key is held down
    o._wheel = { t = 0, streak = 0 }
    o._tick = 0
    o:setWantKeyEvents(true)
    return o
end

-- the naming box opens over the face: it steps back from always-on-top while it is up (update() takes it back)
function ZeD_TwoWayFull:yieldTop(watch)
    self._yieldTo = watch
    self:setAlwaysOnTop(false)
end

function ZeD_TwoWayFull:close()
    self._press, self._drag, self._yieldTo = nil, nil, nil
    self:setVisible(false)
    self:removeFromUIManager()
    local pn = self.playerNum
    local jd = JoypadState.players[pn + 1]
    if jd and jd.focus == self then
        -- focus goes back where it came from (the window whose tab opened it)
        local Focus = ZeD.Input and ZeD.Input.Focus
        local back = self.returnWin
        if back and back:isReallyVisible() and Focus and Focus.claimFocus then Focus.claimFocus(back)
        else setJoypadFocus(pn, nil) end
    end
end

-- where it sits: where the player dragged it (kept per character, design units), else centre right of the play
-- area, clear of the belt; always whole on the screen
function ZeD_TwoWayFull:place(w, h)
    local T = ZeD.T
    local sc = (T and T.scale) or 1
    local pn = self.playerNum
    local x, y
    if self._drag then
        x, y = self._drag.nx, self._drag.ny
    else
        local saved = self.character:getModData().ZeD_TwoWayFull
        if saved and saved.x then
            x, y = saved.x * sc, saved.y * sc
        else
            local l, t = getPlayerScreenLeft(pn), getPlayerScreenTop(pn)
            local sw, sh = getPlayerScreenWidth(pn), getPlayerScreenHeight(pn)
            x = l + math.floor(sw * 0.75 - w / 2)
            y = t + math.floor((sh - h) / 2) - T.px(60)
        end
    end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    x = math.max(0, math.min(x, sw - w)); y = math.max(0, math.min(y, sh - h))
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    if self.width ~= w then self:setWidth(w) end
    if self.height ~= h then self:setHeight(h) end
    if self.x ~= x then self:setX(x) end
    if self.y ~= y then self:setY(y) end
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
function ZeD_TwoWayFull:prerender()
    local T = ZeD.T
    if not T then return end
    self._tick = self._tick + 1
    if self._tick % REACH_EVERY == 1 and not TW.inReach(self.character, self.dev) then self:close(); return end
    local pid = TW.plateId(self.dev)
    local des = pid and ZeD.PhysPx.plates[pid]
    if not des then self:close(); return end
    self.pid, self.des = pid, des
    local k = zoom()
    self._k = k
    local sh = T.hair                                           -- room for the shadow
    local PG = ZeD.PadGlyphs
    local stripH = self.joyfocus and PG.stripH() or 0
    local w = des.w * k + sh
    local h = des.h * k + sh + (stripH > 0 and (T.px(4) + stripH) or 0)
    self:place(w, h)
    local tex = TW.plateTex(des.plate)
    if tex then self:drawTextureScaled(tex, sh, sh, des.w * k, des.h * k, SHADOW_A, 0, 0, 0) end
    local joy = self.joyfocus ~= nil
    local hits, st = TW.drawFace(self, 0, 0, k, { dev = self.dev, pid = pid, des = des, focusId = joy and self.focusId or nil,
        hoverId = (not joy) and self._hover or nil, pressId = self._press and self._press.id or nil, own = true })
    self._hits = hits
    self.st = st
    if joy and not self:focused() and hits[1] then self.focusId = TW.readingOrder(hits, k)[1].id end
    if stripH > 0 then
        local items = { { glyph = "D-PAD", label = ZeD.tr("UI_ZeD_RadioPrompt_Move") } }
        local la = TW.labelA(self.focusId)
        if la then items[#items + 1] = { glyph = "A", label = la } end
        local lx = TW.labelX(self.focusId)
        if lx then items[#items + 1] = { glyph = "X", label = lx } end
        items[#items + 1] = { glyph = "B", label = ZeD.tr("UI_ZeD_Close") }
        PG.drawStrip(self, 0, self.height - stripH, des.w * k, items)
    end
    -- the controller's mark on a key, drawn last so no neighbour covers it
    ZeD.Focus.drawOverlay(self, self)
end

function ZeD_TwoWayFull:update()
    ISPanel.update(self)
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    self.joyfocus = (jd and jd.focus == self) and jd or (F.qaJoy and {} or nil)
    local h = TW.hitAt(self._hits, self:getMouseX(), self:getMouseY())
    self._hover = h and h.id or nil
    if self._yieldTo then
        local ok, up = pcall(self._yieldTo)
        if not (ok and up) then self._yieldTo = nil; self:setAlwaysOnTop(true) end
    end
    TW.holdTick(self._press, self.character, self.dev, self)
end

function ZeD_TwoWayFull:focused()
    for _, h in ipairs(self._hits or {}) do if h.id == self.focusId then return h end end
    return nil
end

-- ---------------------------------------------------------------------------
-- MOUSE: a control is pressed (a knob's left half turns it down); anything else drags the face
-- ---------------------------------------------------------------------------
function ZeD_TwoWayFull:onMouseDown(x, y)
    local h = TW.hitAt(self._hits, x, y)
    if h then
        if TW.holdable(h.id) then
            self._press = { id = h.id, t0 = now(), fired = false }
        elseif h.knob then
            TW.press(self.character, self.dev, h.id, x - (h.x + h.w / 2))
        else
            self._press = { id = h.id, t0 = now(), fired = true }     -- shaded while held; it acts on the press
            TW.press(self.character, self.dev, h.id)
        end
        return true
    end
    self._drag = { mx = getMouseX(), my = getMouseY(), x = self:getX(), y = self:getY(), nx = self:getX(), ny = self:getY() }
    self:setCapture(true)
    return true
end

function ZeD_TwoWayFull:onMouseMove(dx, dy)
    local d = self._drag
    if not d then return end
    d.nx = d.x + (getMouseX() - d.mx)
    d.ny = d.y + (getMouseY() - d.my)
end
function ZeD_TwoWayFull:onMouseMoveOutside(dx, dy) self:onMouseMove(dx, dy) end

function ZeD_TwoWayFull:onMouseUp(x, y)
    local d = self._drag
    if d then
        self._drag = nil
        self:setCapture(false)
        if math.abs(d.nx - d.x) + math.abs(d.ny - d.y) >= 2 then
            local sc = (ZeD.T and ZeD.T.scale) or 1
            self.character:getModData().ZeD_TwoWayFull = { x = self:getX() / sc, y = self:getY() / sc }
        end
        return true
    end
    local p = self._press
    self._press = nil
    if p and not p.fired then
        local h = TW.hitAt(self._hits, x, y)
        if h and h.id == p.id then TW.press(self.character, self.dev, p.id) end
    end
    return true
end
function ZeD_TwoWayFull:onMouseUpOutside(x, y)
    if self._drag then return self:onMouseUp(x, y) end
    self._press = nil
    return true
end

function ZeD_TwoWayFull:onRightMouseDown(x, y)
    local h = TW.hitAt(self._hits, x, y)
    if h then TW.secondary(self.character, self.dev, h.id, self) end
    return true
end
function ZeD_TwoWayFull:onRightMouseUp(x, y) return true end

-- the wheel turns the knob under the pointer (a fast spin goes further per click)
function ZeD_TwoWayFull:onMouseWheel(del)
    local h = TW.hitAt(self._hits, self:getMouseX(), self:getMouseY())
    if h and h.knob then
        local t = now()
        if t - self._wheel.t < 110 then self._wheel.streak = self._wheel.streak + 1 else self._wheel.streak = 0 end
        self._wheel.t = t
        local mult = (h.id == "tune") and TW.turnMult(self.pid, self._wheel.streak) or 1
        TW.turn(self.character, self.dev, h.id, del > 0 and -1 or 1, mult)
    end
    return true
end

-- ---------------------------------------------------------------------------
-- KEYS AND CONTROLLER (the D-pad as onJoypadDir* only; buttons in onJoypadDown)
-- ---------------------------------------------------------------------------
function ZeD_TwoWayFull:isKeyConsumed(key) return key == Keyboard.KEY_ESCAPE end
function ZeD_TwoWayFull:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then self:close(); GameKeyboard.eatKeyPress(key) end
end

function ZeD_TwoWayFull:onGainJoypadFocus(joypadData) self.joyfocus = joypadData end
function ZeD_TwoWayFull:onLoseJoypadFocus(joypadData) self.joyfocus = nil end

function ZeD_TwoWayFull:moveFocus(dx, dy)
    local best = TW.nearest(self._hits, self:focused(), dx, dy)
    if best then self.focusId = best.id; sound("UISelectListItem") end
end

function ZeD_TwoWayFull:dirTurn(dir)
    local t = now()
    local k = self._padTurn or { t = 0, streak = 0 }
    if t - k.t < 260 then k.streak = k.streak + 1 else k.streak = 0 end
    k.t = t
    self._padTurn = k
    local mult = (self.focusId == "tune") and TW.turnMult(self.pid, k.streak) or 1
    TW.turn(self.character, self.dev, self.focusId, dir, mult)
end

function ZeD_TwoWayFull:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then self:close()
    elseif button == Joypad.AButton then
        local id = self.focusId
        if id and id ~= "tune" then TW.press(self.character, self.dev, id) end
    elseif button == Joypad.XButton then
        local id = self.focusId or ""
        if TW.labelX(id) then TW.secondary(self.character, self.dev, id, self) end
    end
end
function ZeD_TwoWayFull:isKnobFocused() local f = self:focused(); return f and f.knob end
function ZeD_TwoWayFull:onJoypadDirLeft() self:moveFocus(-1, 0) end
function ZeD_TwoWayFull:onJoypadDirRight() self:moveFocus(1, 0) end
function ZeD_TwoWayFull:onJoypadDirUp() if self:isKnobFocused() then self:dirTurn(1) else self:moveFocus(0, -1) end end
function ZeD_TwoWayFull:onJoypadDirDown() if self:isKnobFocused() then self:dirTurn(-1) else self:moveFocus(0, 1) end end

-- ---------------------------------------------------------------------------
-- ENTRY
-- ---------------------------------------------------------------------------
function F.get(pn) return F.views[pn or 0] end

-- the radio in full view for this player, nil when none
function F.showing(pn)
    local v = F.views[pn or 0]
    if v and v:isReallyVisible() then return v.dev end
    return nil
end

-- open full view on a radio (win: the window whose tab opened it, for the controller's way back)
function F.open(character, dev, win)
    if not (character and dev and TW.plateId(dev)) then return nil end
    local pn = character:getPlayerNum()
    local v = F.views[pn]
    if not v or v.character ~= character then
        if v and v:isReallyVisible() then v:close() end
        v = ZeD_TwoWayFull:new(character)
        v:initialise()
        v:instantiate()
        F.views[pn] = v
    end
    v.dev, v.returnWin, v._tick, v.focusId = dev, win, 0, nil
    if not v:isReallyVisible() then
        v:setVisible(true)
        v:addToUIManager()
    end
    v:setAlwaysOnTop(true)
    local jd = JoypadState.players[pn + 1]
    if jd then setJoypadFocus(pn, v) end
    return v
end

function F.close(pn)
    local v = F.views[pn or 0]
    if v and v:isReallyVisible() then v:close(); return true end
    return false
end

-- the tab's button: full view on this radio, or off when it already shows it
function F.toggle(character, dev, win)
    if not character then return end
    local pn = character:getPlayerNum()
    if F.showing(pn) == dev then F.close(pn) else F.open(character, dev, win) end
end

-- Escape from anywhere (the prompts' key hook asks): full view closes
function F.takeEscape()
    for _, v in pairs(F.views) do
        if v and v:isReallyVisible() then v:close(); return true end
    end
    return false
end
ZeD.EscapeTakers = ZeD.EscapeTakers or {}
ZeD.EscapeTakers.twoWayFull = F.takeEscape

return F
