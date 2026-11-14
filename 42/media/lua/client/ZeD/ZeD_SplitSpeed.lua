-- ============================================================================
-- ZeD_SplitSpeed.lua: the game's time controls in split view
-- ============================================================================
-- In split view the game draws its own speed controls against the first player's part of the screen, the middle of
-- the screen when two play, and re-places them sideways every frame, so they can't be moved. The director, Nov 13
-- 2026: "Screen's corner", ZeD's own. So while more than one local player is on (and split view is on), the game's
-- buttons are parked off screen (as ZeD_Watch parks them) and this strip draws Play/Pause, the two fast speeds and
-- Wait at the bottom right of the whole screen. The game's speed controls stay the authority: every press goes
-- through their ButtonClicked, the same as the D-pad wheel's Game speed. Not on a server (the server sets the time)
-- and not in safe mode. One player: nothing changes, the strip stays hidden.
-- ============================================================================

ZeD = ZeD or {}
ZeD.SplitSpeed = ZeD.SplitSpeed or {}
local S = ZeD.SplitSpeed

-- the buttons, left to right: the ZeD pixel icon, the game's words for it (the wheel's), what it presses
local BUTTONS = {
    { id = "play",  key = "IGUI_BackButton_Play", press = "Play" },   -- (Play or Pause by the current speed: see below)
    { id = "ff1",   key = "IGUI_BackButton_FF1",  press = "Fast Forward x 1", mult = 5 },
    { id = "ff2",   key = "IGUI_BackButton_FF2",  press = "Fast Forward x 2", mult = 20 },
    { id = "wait",  key = "IGUI_BackButton_FF3",  press = "Wait",             mult = 40 },
}

-- more than one local player on this machine
local function _splitPlayers()
    for pn = 1, 3 do if getSpecificPlayer(pn) then return true end end
    return false
end

--- Whether the strip shows now: split view on, two or more local players, single player (not a server), not safe mode.
function S.wanted()
    if ZeD.splitWindows ~= true then return false end
    if isClient and isClient() then return false end
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on("watch") then return false end
    return _splitPlayers()
end

local function _speedNow()
    local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
    local cur = sc and sc:getCurrentGameSpeed() or 1
    local ok, mult = pcall(function() return getGameTime():getTrueMultiplier() end)
    return cur, (ok and mult) or 1
end

local function _press(name)
    local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
    if sc then pcall(sc.ButtonClicked, sc, name) end
end

ZeD_SplitSpeed = ISPanel:derive("ZeD_SplitSpeed")

function ZeD_SplitSpeed:new()
    local o = ISPanel:new(0, 0, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o._hover = nil
    o._down = nil
    o._opts = {}
    return o
end

-- size and place: the buttons in a row at the whole screen's bottom right, a small margin in
function ZeD_SplitSpeed:_layout()
    local T = ZeD.T
    local size = T.buttonH
    local gap = T.px(4)
    local pad = T.px(4)
    local w = #BUTTONS * size + (#BUTTONS - 1) * gap + pad * 2
    local h = size + pad * 2
    local core = getCore()
    local x = core:getScreenWidth() - w - T.px(8)
    local y = core:getScreenHeight() - h - T.px(8)
    if self:getWidth() ~= w then self:setWidth(w) end
    if self:getHeight() ~= h then self:setHeight(h) end
    if self:getX() ~= x then self:setX(x) end
    if self:getY() ~= y then self:setY(y) end
    self._size, self._gap, self._pad = size, gap, pad
end

-- the button under a point in the strip, or nil
function ZeD_SplitSpeed:_at(mx, my)
    local size, gap, pad = self._size or 0, self._gap or 0, self._pad or 0
    if my < pad or my >= pad + size then return nil end
    for i = 1, #BUTTONS do
        local bx = pad + (i - 1) * (size + gap)
        if mx >= bx and mx < bx + size then return i end
    end
    return nil
end

function ZeD_SplitSpeed:prerender()
    if not S.wanted() then return end
    local T = ZeD.T
    self:_layout()
    -- the game's own buttons parked off screen while this strip stands in (their flag kept on: Pause on Focus Loss
    -- reads it; ZeD_Watch.parkSpeed). Java keeps their X; Y is the axis that parks them.
    local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
    if sc then
        local sy = sc:getY()
        if sy >= 0 then S._gameY = sy; pcall(sc.setY, sc, -4000) end
    end
    -- a backing so the strip reads over any scene
    -- (square corners and a 1px border, the System 7 container: no rounding on a surface)
    local bg, bd = T.base, T.border
    self:drawRect(0, 0, self.width, self.height, ZeD.surfaceAlpha or 0.92, bg.r, bg.g, bg.b)
    self:drawRectBorder(0, 0, self.width, self.height, bd.a or 1, bd.r, bd.g, bd.b)
    local cur, mult = _speedNow()
    local o = self._opts
    for i, b in ipairs(BUTTONS) do
        local icon, hintKey, active = b.id, b.key, false
        if i == 1 then
            -- Play while paused, Pause while running (the wheel's first slice)
            if cur == 0 then icon, hintKey = "play", "IGUI_BackButton_Play" else icon, hintKey = "pause", "UI_optionscreen_binding_Pause" end
            active = cur ~= 0 and mult <= 1
        else
            active = cur ~= 0 and mult == b.mult
        end
        o.hover = (self._hover == i)
        o.pressed = (self._down == i)
        o.active = active
        o.hint = getText(hintKey)
        o.id = "splitspeed_" .. b.id
        o.win = self
        ZeD.Molecules.drawIconButton(self, self._pad + (i - 1) * (self._size + self._gap), self._pad, self._size, icon, o)
    end
end

function ZeD_SplitSpeed:render() end

function ZeD_SplitSpeed:onMouseMove(dx, dy)
    self._hover = self:_at(self:getMouseX(), self:getMouseY())
end
function ZeD_SplitSpeed:onMouseMoveOutside(dx, dy)
    self._hover = nil
end
function ZeD_SplitSpeed:onMouseDown(x, y)
    self._down = self:_at(x, y)
    return true
end
function ZeD_SplitSpeed:onMouseUp(x, y)
    local i = self:_at(x, y)
    if i and i == self._down then
        if i == 1 then
            local cur, mult = _speedNow()
            -- (paused, or running fast: Play; running at 1x: Pause, as the wheel does)
            if cur == 0 or mult > 1 then _press("Play") else _press("Pause") end
        else
            _press(BUTTONS[i].press)
        end
    end
    self._down = nil
    return true
end
function ZeD_SplitSpeed:onMouseUpOutside(x, y) self._down = nil end

-- the strip: made once a game is on, shown only while wanted; the game's buttons put back when it goes away
local function _tick()
    local want = S.wanted()
    local inst = S._instance
    if want and not inst then
        inst = ZeD_SplitSpeed:new()
        inst:initialise()
        inst:addToUIManager()
        S._instance = inst
    end
    if inst then
        if inst:isVisible() ~= want then inst:setVisible(want) end
        if want then inst:bringToTop() end
        if not want and S._gameY then
            -- (back to one player, or split view off: the game's buttons where they were, unless ZeD's watch parks them)
            local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
            if sc and sc:getY() < 0 then pcall(sc.setY, sc, S._gameY) end
            S._gameY = nil
        end
    end
end
Events.OnTick.Add(_tick)
if Events.OnTickEvenPaused then Events.OnTickEvenPaused.Add(_tick) end
Events.OnMainMenuEnter.Add(function()
    local inst = S._instance
    if inst then pcall(inst.removeFromUIManager, inst) end
    S._instance, S._gameY = nil, nil
end)
