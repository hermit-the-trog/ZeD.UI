-- ZeD-UI/42/media/lua/client/ZeD/StationPopout.lua
-- ============================================================================
-- AN APPLIANCE IN ITS OWN WINDOW (director, Oct 25 2026: the appliance faces
-- should "have option to pop out on their own centered panel")
--
-- The Craft tab's oven or microwave view (StationAppliance.render, without its
-- station select) in a ZeD window centred on the screen, at the largest whole zoom
-- that fits (never smaller than the tab's), so the knobs and keys are bigger. The
-- tab shows "In its own window" and Bring it back meanwhile. The window closes
-- with its close box, B or Escape, and by itself when the station is no longer
-- the one in use (walking away releases it, as in the tab).
-- Mouse: as in the tab (a knob's left half turns it down, the right half up; the
-- wheel turns it). Controller: up / down walk the controls in reading order, left /
-- right turn a knob (or walk), A presses, B closes.
-- ============================================================================
require "ZeD/StationAppliance"
ZeD.StationPopout = ZeD.StationPopout or {}
local SP = ZeD.StationPopout
local SA = ZeD.StationAppliance
SP.windows = SP.windows or {}

local MAX_W_SHARE, MAX_H_SHARE = 0.45, 0.8  -- of the screen: the plate's zoom stops where it would pass these (a third or so of a 4K screen at 3x)

local function stubScroll()
    return { visible = false, scrollPos = 0, setScrollPos = function() end, setBarSize = function() end, draw = function() end }
end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

ZeD_StationPopout = ZeD_Window:derive("ZeD_StationPopout")

function ZeD_StationPopout:new(playerNum)
    local o = ZeD_Window.new(self, 0, 0, 100, 100, "")
    o.resizable = false
    o.themeFooter = false
    o.pin = true
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o.moveWithMouse = false
    o.playerNum = playerNum or 0
    o.state = { zones = {}, scroll = stubScroll() }
    o.fi = 1             -- controller: the focused control, in reading order
    o._down = nil
    o:setWantKeyEvents(true)
    return o
end

function ZeD_StationPopout:createChildren()
    ZeD_Window.createChildren(self)
    self.minimumWidth, self.minimumHeight = 0, 0
end

function ZeD_StationPopout:close()
    SA.popped[self.playerNum] = nil
    self:setVisible(false)
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum + 1] and JoypadState.players[self.playerNum + 1].focus == self then
        setJoypadFocus(self.playerNum, nil)
    end
end

-- the largest whole zoom for this plate that fits the screen share, at least the screen's own
function ZeD_StationPopout:zoomFor(des)
    local Sc = ZeD.Scale
    local k0 = ZeD.Px.k((Sc and Sc.root and Sc.root()) or 1)
    if not des then return k0 end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local k = k0
    while des.w * (k + 1) <= sw * MAX_W_SHARE and des.h * (k + 1) <= sh * MAX_H_SHARE * 0.6 do k = k + 1 end
    return k
end

-- the controls the controller walks (the plate's, in drawing order = reading order)
function ZeD_StationPopout:controls()
    local out = {}
    for _, z in ipairs(self.state.zones or {}) do if z.type == "plate" then out[#out + 1] = z end end
    return out
end

function ZeD_StationPopout:focusId()
    if not self.joyfocus then return nil end
    local c = self:controls()
    local z = c[math.max(1, math.min(#c, self.fi))]
    return z and z.fid or nil
end

function ZeD_StationPopout:prerender()
    local T = ZeD.T
    if not T then return end
    local p = getSpecificPlayer(self.playerNum)
    local cur = p and ZeD.Stations and ZeD.Stations.current(p)
    if not (cur and self.st and cur.obj == self.st.obj and (cur.kind == "oven" or cur.kind == "micro")) then self:close(); return end
    self.st = cur
    self.title = cur.name or ""
    local des = SA.plateFor(cur)
    local k = self:zoomFor(des)
    local margin = T.px(16)
    local tbH = self:titleBarHeight()
    local w = (des and des.w * k or T.px(400)) + 2 * margin
    local bodyH = self._bodyH or (des and des.h * k + T.px(160)) or T.px(300)
    local h = tbH + bodyH
    if self.width ~= w or self.height ~= h then
        self:setWidth(w); self:setHeight(h)
        self:setX(math.floor((getCore():getScreenWidth() - w) / 2))
        self:setY(math.floor((getCore():getScreenHeight() - h) / 2))
    end
    self.minimumWidth, self.minimumHeight = 0, 0
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    local ok, total = pcall(SA.render, self, { _playerObj = p }, margin, tbH, w - 2 * margin, bodyH, self.state, cur,
        { noHeader = true, k = k, fid = self:focusId() })
    if not ok then ZeD.logOnce("station pop-out", total); self:close(); return end
    if total and total ~= self._bodyH then self._bodyH = total end
end

function ZeD_StationPopout:render() ZeD_Window.render(self) end

function ZeD_StationPopout:update()
    ISPanel.update(self)
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    self.joyfocus = (jd and jd.focus == self) and jd or (SP.qaJoy and self or nil)
end

-- ---------------------------------------------------------------------------
-- MOUSE
-- ---------------------------------------------------------------------------
function ZeD_StationPopout:hitAt(x, y)
    for _, z in ipairs(self.state.zones or {}) do if z.type == "plate" and inRect(z, x, y) then return z end end
    return nil
end

function ZeD_StationPopout:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then self._down = "close"; return true end
    local z = self:hitAt(x, y)
    if z then
        local p = getSpecificPlayer(self.playerNum)
        SA.act(p, self.st, z, (x < z.x + z.w / 2) and -1 or 1)
    end
    return true
end

function ZeD_StationPopout:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    if down == "close" then
        local cb = self:closeRect()
        if cb and inRect(cb, x, y) then getSoundManager():playUISound("UIActivateButton"); self:close() end
    end
    return true
end
function ZeD_StationPopout:onMouseUpOutside(x, y) self._down = nil end

function ZeD_StationPopout:onMouseWheel(del)
    local z = self:hitAt(self:getMouseX(), self:getMouseY())
    if z and z.kind == "turn" then SA.act(getSpecificPlayer(self.playerNum), self.st, z, del > 0 and -1 or 1) end
    return true
end

-- ---------------------------------------------------------------------------
-- KEYS AND CONTROLLER
-- ---------------------------------------------------------------------------
function ZeD_StationPopout:isKeyConsumed(key) return key == Keyboard.KEY_ESCAPE end
function ZeD_StationPopout:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then self:close(); GameKeyboard.eatKeyPress(key) end
end

function ZeD_StationPopout:onGainJoypadFocus(joypadData) self.joyfocus = joypadData end
function ZeD_StationPopout:onLoseJoypadFocus(joypadData) self.joyfocus = nil end

function ZeD_StationPopout:move(d)
    local n = #self:controls()
    if n == 0 then return end
    self.fi = ((math.max(1, math.min(n, self.fi)) - 1 + d) % n) + 1
    getSoundManager():playUISound("UISelectListItem")
end

function ZeD_StationPopout:turnOrMove(d)
    local c = self:controls()
    local z = c[math.max(1, math.min(#c, self.fi))]
    if z and z.kind == "turn" then SA.act(getSpecificPlayer(self.playerNum), self.st, z, d) else self:move(d) end
end

function ZeD_StationPopout:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then self:close(); return end
    if button ~= Joypad.AButton then return end
    local c = self:controls()
    local z = c[math.max(1, math.min(#c, self.fi))]
    if z then SA.act(getSpecificPlayer(self.playerNum), self.st, z, 1) end
end
function ZeD_StationPopout:onJoypadDirUp() self:move(-1) end
function ZeD_StationPopout:onJoypadDirDown() self:move(1) end
function ZeD_StationPopout:onJoypadDirLeft() self:turnOrMove(-1) end
function ZeD_StationPopout:onJoypadDirRight() self:turnOrMove(1) end

-- ---------------------------------------------------------------------------
-- ENTRY
-- ---------------------------------------------------------------------------
function SP.open(player, st)
    if not (player and st) then return nil end
    local pn = player:getPlayerNum()
    local win = SP.windows[pn]
    if not win then
        win = ZeD_StationPopout:new(pn)
        win:initialise()
        win:instantiate()
        SP.windows[pn] = win
    end
    win.st, win.fi, win._bodyH = st, 1, nil
    SA.popped[pn] = st
    if not win:isReallyVisible() then
        win:setVisible(true)
        win:addToUIManager()
        win:setAlwaysOnTop(true)
    end
    local jd = JoypadState.players[pn + 1]
    if jd then jd.focus = win; updateJoypadFocus(jd) end
    return win
end

function SP.close(player)
    local pn = player and player:getPlayerNum() or 0
    local win = SP.windows[pn]
    if win and win:isReallyVisible() then win:close() else SA.popped[pn] = nil end
end

function SP.get(pn) return SP.windows[pn or 0] end

-- Escape from anywhere (the prompts' key hook asks): the pop-out on screen closes
function SP.takeEscape()
    for _, win in pairs(SP.windows) do
        if win and win:isReallyVisible() then win:close(); return true end
    end
    return false
end
ZeD.EscapeTakers = ZeD.EscapeTakers or {}
ZeD.EscapeTakers.stationPopout = SP.takeEscape

return SP
