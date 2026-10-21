-- ZeD-UI/42/media/lua/client/ZeD/ZeD_SirenController.lua
-- ============================================================================
-- THE SIREN CONTROLLER, UP CLOSE — vanilla's ISLightbarUI as a 1993 prop
-- Mockup ZeDUI/mockups/zed_seats_lightbar_v1.html (director, Oct 15 2026:
-- "lightbar is cool, better than the plain version", then "build both").
-- HOOK_MAP row 4; the hook is Overrides/Seats.lua (ISLightbarUITimedAction).
--
-- The police dash's own siren controller brought up close, in the dashboards'
-- pixel art (director, Oct 16 2026; the plate in PhysPx.lua, drawn by the
-- shared plate template ZeD_Plate.lua): two rotary switches, LIGHTS (OFF 1 2
-- 3) and SIREN (STANDBY YELP WAIL ALARM, printed on the panel), their pointers
-- and pilot lamps live. It rises above the dash's console, so the car and its
-- bar stay in view; with no dash it sits above the bottom of the player's
-- screen. The wheel's Lightbar slice opens and closes it; leaving the car,
-- Escape or B puts it away.
--
-- Mouse: click a word to turn the switch there, click the knob to step it,
-- the wheel turns it. Controller: left / right picks a switch (a ring round
-- its knob), up / down turns it, A steps it, B puts it away. Every change is
-- vanilla's own command (setLightbarLightsMode / setLightbarSirenMode) with
-- vanilla's sounds, so it works the same in multiplayer.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"

ZeD = ZeD or {}
ZeD.Siren = ZeD.Siren or {}
local S = ZeD.Siren
S.props = S.props or {}
local P = ZeD.Px
local PL = ZeD.Plate

local GAP = 6                    -- plate pixels between the prop and the dash
local GROUPS = { "lights", "siren" }
ZeD.trDefaults({
    UI_ZeD_Siren_Dpad = "D-PAD Left / Right: switch   Up / Down: turn", UI_ZeD_Siren_Step = "Step", UI_ZeD_Hud_PutAway = "Put away",
})

local function plate() local X = ZeD.PhysPx; return X and X.plates.siren or nil end
local function plateTex(name) return P.tex(ZeD.PhysPx.texdir .. name .. ".png") end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name) end) end

-- ---------------------------------------------------------------------------
-- ZeD_SirenController
-- ---------------------------------------------------------------------------
ZeD_SirenController = ISPanel:derive("ZeD_SirenController")

function ZeD_SirenController:new(character)
    local o = ISPanel:new(0, 0, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o.moveWithMouse = false
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.focus = 1          -- the controller's switch: 1 lights, 2 siren
    o._hits = {}
    o._hover = nil
    return o
end

function ZeD_SirenController:vehicle()
    local v = self.character and self.character:getVehicle()
    if v and v:hasLightbar() then return v end
    return nil
end

function ZeD_SirenController:modes()
    local v = self:vehicle()
    if not v then return 0, 0 end
    return v:getLightbarLightsMode(), v:getLightbarSirenMode()
end

-- vanilla's commands and sounds
function ZeD_SirenController:set(groupId, mode)
    local v = self:vehicle()
    if not v then return end
    mode = math.max(0, math.min(3, mode))
    local lights, siren = self:modes()
    if groupId == "lights" then
        if mode == lights then return end
        sound("VehicleSetLights")
        sendClientCommand(self.character, "vehicle", "setLightbarLightsMode", { mode = mode })
    else
        if mode == siren then return end
        sound("VehicleSetSiren")
        sendClientCommand(self.character, "vehicle", "setLightbarSirenMode", { mode = mode })
    end
end

function ZeD_SirenController:step(groupId, dir)
    local lights, siren = self:modes()
    local cur = groupId == "lights" and lights or siren
    if dir == 0 then self:set(groupId, (cur + 1) % 4) else self:set(groupId, cur + dir) end
end

function ZeD_SirenController:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum + 1] and JoypadState.players[self.playerNum + 1].focus == self then
        setJoypadFocus(self.playerNum, nil)
    end
end

-- ---------------------------------------------------------------------------
-- LAYOUT: the dash's own whole multiple; the right edge on the dash console's right edge
-- ---------------------------------------------------------------------------
function ZeD_SirenController:scale()
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance()
    if dash and dash._s then return dash._s end
    local Sc = ZeD.Scale
    return P.k(((Sc and Sc.root and Sc.root()) or 1) * ((ZeD.Dashboard and ZeD.Dashboard.scale) or 1))
end

function ZeD_SirenController:layout(des)
    local s = self:scale()
    local T = ZeD.T
    local pw, ph = des.w * s, des.h * s
    local stripH = self.joyfocus and T.sp.scrollbarW or 0
    local w, h = pw, ph + (stripH > 0 and (T.px(4) + stripH) or 0)
    local pn = self.playerNum
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance()
    local x, y
    if dash and dash:isVisible() and dash._consoleRect and dash.playerNum == pn then
        local cs, ds = dash._consoleRect, dash._s or s
        x = dash:getX() + math.floor((cs.x + cs.w) * ds) - des.w * s
        y = dash:getY() - h - math.floor(GAP * s)
    else
        x = getPlayerScreenLeft(pn) + math.floor((getPlayerScreenWidth(pn) - pw) / 2)
        y = getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) - h - math.floor(220 * s)
    end
    local l, t = getPlayerScreenLeft(pn), getPlayerScreenTop(pn)
    x = math.max(l, math.min(x, l + getPlayerScreenWidth(pn) - w))
    y = math.max(t, math.min(y, t + getPlayerScreenHeight(pn) - h))
    if self.width ~= w then self:setWidth(w) end
    if self.height ~= h then self:setHeight(h) end
    if self.x ~= x then self:setX(x) end
    if self.y ~= y then self:setY(y) end
    self._s, self._pw, self._ph, self._stripH = s, pw, ph, stripH
end

-- ---------------------------------------------------------------------------
-- DRAWING: the plate and its live parts (the template), then the cues
-- ---------------------------------------------------------------------------
function ZeD_SirenController:prerender()
    local T = ZeD.T
    local des = plate()
    if not (T and des) then return end
    if not self:vehicle() then self:close(); return end
    self:layout(des)
    local s = self._s
    local lights, siren = self:modes()
    local cv = P.canvas(self, 0, 0, s)
    PL.draw(cv, des, { lightsMode = lights, sirenMode = siren, lightsOn = lights > 0, sirenOn = siren > 0 }, { tex = plateTex, now = getTimestampMs() })
    -- the click areas: a word turns its switch there ("lights:2"), a knob steps it ("siren:knob")
    local ac = T.accent
    local hits = {}
    local focusKnob = self.joyfocus and (GROUPS[self.focus] .. ":knob") or nil
    for _, c in ipairs(PL.controls(des, {})) do
        local group, what = c.id:match("^(%a+):(%w+)$")
        local knob = what == "knob"
        local cue = knob and { x = c.x, y = c.y, w = c.w, h = c.h, kind = "turn" } or c   -- a knob's cue is a ring round it
        hits[#hits + 1] = { id = c.id, x = c.x * s, y = c.y * s, w = c.w * s, h = c.h * s, group = group, knob = knob,
                            mode = (not knob) and tonumber(what) or nil }
        if c.id == focusKnob then PL.cue(cv, cue, ac, 0.55)
        elseif self._hover == c.id and not self.joyfocus then PL.cue(cv, cue, ac, knob and 0.30 or 0.22) end
    end
    self._hits = hits
    -- the controller's strip under the faceplate
    if self._stripH > 0 then
        local y = self.height - self._stripH
        local s2, bs = T.surf2, T.borderS
        self:drawRect(0, y, self.width, self._stripH, 1, s2.r, s2.g, s2.b)
        self:drawRectBorder(0, y, self.width, self._stripH, bs.a or 1, bs.r, bs.g, bs.b)
        ZeD.Molecules.drawGlyphPrompts(self, T.sp.sm, y, self._stripH, {
            ZeD.tr("UI_ZeD_Siren_Dpad"), { glyph = "A", label = ZeD.tr("UI_ZeD_Siren_Step") }, { glyph = "B", label = ZeD.tr("UI_ZeD_Hud_PutAway") } })
    end
end

-- ---------------------------------------------------------------------------
-- MOUSE
-- ---------------------------------------------------------------------------
function ZeD_SirenController:hitAt(x, y)
    for _, h in ipairs(self._hits or {}) do if inRect(h, x, y) then return h end end
    return nil
end

function ZeD_SirenController:onMouseDown(x, y)
    local h = self:hitAt(x, y)
    if h then
        if h.knob then self:step(h.group, 0) else self:set(h.group, h.mode) end
    end
    return true
end
function ZeD_SirenController:onMouseUp(x, y) return true end

-- the wheel turns the switch under the pointer (a positive delta is the wheel turned down)
function ZeD_SirenController:onMouseWheel(del)
    local h = self:hitAt(self:getMouseX(), self:getMouseY())
    if h then self:step(h.group, del > 0 and -1 or 1) end
    return true
end

function ZeD_SirenController:update()
    ISPanel.update(self)
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    local jf = (jd and jd.focus == self) and jd or nil
    if S.qaJoy then jf = S.qaJoy end
    self.joyfocus = jf
    local h = self:hitAt(self:getMouseX(), self:getMouseY())
    if S.qaPoint then h = { id = S.qaPoint } end
    self._hover = h and h.id or nil
end

-- ---------------------------------------------------------------------------
-- CONTROLLER (the D-pad as onJoypadDir* only; buttons in onJoypadDown)
-- ---------------------------------------------------------------------------
function ZeD_SirenController:onGainJoypadFocus(joypadData) self.joyfocus = joypadData end
function ZeD_SirenController:onLoseJoypadFocus(joypadData) self.joyfocus = nil end
local function gid(self) return GROUPS[self.focus] end
function ZeD_SirenController:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then self:close()
    elseif button == Joypad.AButton then self:step(gid(self), 0) end
end
function ZeD_SirenController:onJoypadDirLeft() if self.focus > 1 then self.focus = self.focus - 1; sound("UISelectListItem") end end
function ZeD_SirenController:onJoypadDirRight() if self.focus < #GROUPS then self.focus = self.focus + 1; sound("UISelectListItem") end end
function ZeD_SirenController:onJoypadDirUp() self:step(gid(self), 1) end
function ZeD_SirenController:onJoypadDirDown() self:step(gid(self), -1) end

-- ---------------------------------------------------------------------------
-- ENTRY (the wheel's Lightbar slice, through vanilla's timed action)
-- ---------------------------------------------------------------------------
function S.toggle(character)
    if not character then return end
    local pn = character:getPlayerNum()
    local prop = S.props[pn]
    if prop and prop:isReallyVisible() then prop:close(); return end
    local v = character:getVehicle()
    if not (v and v:hasLightbar()) then return end
    if ZeD.CarRadio and ZeD.CarRadio.closeFor then ZeD.CarRadio.closeFor(pn) end   -- one prop up close at a time
    if not prop or prop.character ~= character then
        prop = ZeD_SirenController:new(character)
        prop:initialise()
        prop:instantiate()
        S.props[pn] = prop
    end
    prop.focus = 1
    prop:setVisible(true)
    prop:addToUIManager()
    prop:setAlwaysOnTop(true)
    if JoypadState.players[pn + 1] then setJoypadFocus(pn, prop) end
end

-- Escape (the prompts' key hook asks): the controller on screen goes away
function S.takeEscape()
    for _, p in pairs(S.props) do
        if p and p:isReallyVisible() then p:close(); return true end
    end
    return false
end

-- leaving the car puts it away
if Events and Events.OnExitVehicle then
    Events.OnExitVehicle.Add(function(character)
        local pn = character and character.getPlayerNum and character:getPlayerNum()
        local p = pn and S.props[pn]
        if p and p:isReallyVisible() then p:close() end
    end)
end

function S.get(pn) return S.props[pn or 0] end
