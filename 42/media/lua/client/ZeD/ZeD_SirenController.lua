-- ZeD-UI/42/media/lua/client/ZeD/ZeD_SirenController.lua
-- ============================================================================
-- THE SIREN CONTROLLER, UP CLOSE — vanilla's ISLightbarUI as a 1993 prop.
-- Client organism (ZeD_SirenController, an ISPanel). The hook is
-- Overrides/Seats.lua (ISLightbarUITimedAction).
--
-- The police dash's own siren controller brought up close, in the dashboards'
-- pixel art (the plate in PhysPx.lua, drawn by the shared plate template
-- ZeD_Plate.lua): two rotary switches, LIGHTS (OFF 1 2 3) and SIREN (STANDBY
-- YELP WAIL ALARM, printed on the panel), their pointers and pilot lamps
-- live. It rises above the dash's console, so the car and its
-- bar stay in view; with no dash it sits above the bottom of the player's
-- screen. The wheel's Lightbar slice opens and closes it; leaving the car,
-- Escape or B puts it away.
--
-- Mouse: click a word to turn the switch there, click the knob to step it,
-- the wheel turns it. Controller: left / right picks a switch (a ring round
-- its knob), up / down turns it, A steps it, B puts it away. Every change is
-- vanilla's own command (setLightbarLightsMode / setLightbarSirenMode) with
-- vanilla's sounds, so it works the same in multiplayer. With the simple dash
-- it is a plain card instead (THE SIMPLE FORM, below).
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
    UI_ZeD_Siren_PromptSwitch = "Switch", UI_ZeD_Siren_PromptTurn = "Turn", UI_ZeD_Siren_Step = "Step", UI_ZeD_Hud_PutAway = "Put away",
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
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance(self.playerNum)
    if dash and dash._s then return dash._s end
    local Sc = ZeD.Scale
    return P.k(((Sc and Sc.root and Sc.root()) or 1) * ((ZeD.Dashboard and ZeD.Dashboard.scale) or 1))
end

function ZeD_SirenController:layout(des)
    local s = self:scale()
    local T = ZeD.T
    local pw, ph = des.w * s, des.h * s
    local stripH = self.joyfocus and ZeD.PadGlyphs.stripH() or 0
    local w, h = pw, ph + (stripH > 0 and (T.px(4) + stripH) or 0)
    self:place(w, h, s)
    self._s, self._pw, self._ph, self._stripH = s, pw, ph, stripH
end

-- w x h placed above the dash's console, its right edge on the console's (the simple dash: the strip's right
-- end), else above the bottom of the player's screen; kept on the screen
function ZeD_SirenController:place(w, h, s)
    local pn = self.playerNum
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance(self.playerNum)
    local x, y
    if dash and dash:isVisible() and dash._consoleRect and dash.playerNum == pn then
        local cs, ds = dash._consoleRect, dash._s or s
        x = dash:getX() + math.floor((cs.x + cs.w) * ds) - w
        y = dash:getY() - h - math.floor(GAP * s)
    else
        x = getPlayerScreenLeft(pn) + math.floor((getPlayerScreenWidth(pn) - w) / 2)
        y = getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) - h - math.floor(220 * s)
    end
    local l, t = getPlayerScreenLeft(pn), getPlayerScreenTop(pn)
    x = math.max(l, math.min(x, l + getPlayerScreenWidth(pn) - w))
    y = math.max(t, math.min(y, t + getPlayerScreenHeight(pn) - h))
    if self.width ~= w then self:setWidth(w) end
    if self.height ~= h then self:setHeight(h) end
    if self.x ~= x then self:setX(x) end
    if self.y ~= y then self:setY(y) end
end

-- ---------------------------------------------------------------------------
-- DRAWING: the plate and its live parts (the template), then the cues
-- ---------------------------------------------------------------------------
function ZeD_SirenController:prerender()
    local T = ZeD.T
    local des = plate()
    if not (T and des) then return end
    if not self:vehicle() then self:close(); return end
    -- the simple dash (ZeD setup's "Dashboard" row) brings the controller up as a plain card
    self._plainOn = S.simple()
    if self._plainOn then
        local ok, e = pcall(self._plain, self)
        if not ok then ZeD.logOnce("siren plain", e) end
        return
    end
    self:layout(des)
    local s = self._s
    local lights, siren = self:modes()
    local cv = P.canvas(self, 0, 0, s)
    PL.draw(cv, des, { lightsMode = lights, sirenMode = siren, lightsOn = lights > 0, sirenOn = siren > 0 }, { tex = plateTex, now = getTimestampMs() })
    -- the click areas: a word turns its switch there ("lights:2"), a knob steps it ("siren:knob"). The
    -- controller is only ever on a knob: its ring is the knob's own light and stays; the pointer on a
    -- word wears the library's hover wash
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
        elseif self._hover == c.id and not self.joyfocus then
            if knob then PL.cue(cv, cue, ac, 0.30) else PL.hoverKey(cv, c) end
        end
    end
    self._hits = hits
    -- the controller's strip under the faceplate: the help line's look (pictures at 14u, F2 words)
    if self._stripH > 0 then
        ZeD.PadGlyphs.drawStrip(self, 0, self.height - self._stripH, self.width, {
            { glyph = "<>", label = ZeD.tr("UI_ZeD_Siren_PromptSwitch") },
            { glyph = "^v", pad = { "DUD" }, label = ZeD.tr("UI_ZeD_Siren_PromptTurn") },
            { glyph = "A", label = ZeD.tr("UI_ZeD_Siren_Step") }, { glyph = "B", label = ZeD.tr("UI_ZeD_Hud_PutAway") } })
    end
end

-- ---------------------------------------------------------------------------
-- THE SIMPLE FORM: with the simple dash (ZeD setup's "Dashboard" row), a plain card in ZeD's own parts where the
-- prop rises. The two switches side by side, LIGHTS left and SIREN
-- right as on the panel: each its name as a button (the knob: a press steps it), then its four positions as buttons
-- with the highest at the top (up turns it up), the one it is at in the primary look. The click areas carry the
-- plate's ids ("lights:knob", "siren:2"), so the mouse, the wheel and the controller work as on the prop; the
-- controller's mark sits on the chosen switch's name.
-- ---------------------------------------------------------------------------
function S.simple() return ZeD.Settings and ZeD.Settings.dashSimple and ZeD.Settings.dashSimple() or false end

local SIREN_KEYS = { [0] = "IGUI_VehicleLightbar_STANDBY", "IGUI_VehicleLightbar_YELP", "IGUI_VehicleLightbar_WAIL", "IGUI_VehicleLightbar_ALARM" }
local SWITCH_KEYS = { lights = "UI_ZeD_DashPlain_Lights", siren = "UI_ZeD_Dash_PromptSiren" }
local function modeWord(group, m)
    if group == "lights" then return (m == 0) and ZeD.tr("UI_Off") or tostring(m) end
    return ZeD.textCase(ZeD.tr(SIREN_KEYS[m] or SIREN_KEYS[0]))
end
S.modeWord = modeWord   -- (for the test scripts' probes)

local PLAIN_COL_W, PLAIN_PAD, PLAIN_GAP = 104, 8, 4
local _btnO, _markO = {}, { focused = true }
function ZeD_SirenController:_plain()
    local T = ZeD.T
    local px = T.px
    local pad, gap, bh = px(PLAIN_PAD), px(PLAIN_GAP), T.buttonH
    local f1 = T.fontF1
    local fh1 = ZeD.TM:getFontHeight(f1)
    local colW = px(PLAIN_COL_W)
    local stripH = self.joyfocus and ZeD.PadGlyphs.stripH() or 0
    local w = pad * 2 + colW * 2 + px(8)
    local bodyH = pad + fh1 + gap + 5 * bh + 4 * gap + pad
    local h = bodyH + stripH
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance(self.playerNum)
    self:place(w, h, (dash and dash._s) or 1)
    self._s, self._stripH = 1, stripH
    ZeD.Surface.fill(self, 0, 0, w, bodyH, "surf2")
    local b = T.borderS
    self:drawRectBorder(0, 0, w, bodyH, b.a or 1, b.r, b.g, b.b)
    local th = T.textHead or T.text
    self:drawText(ZeD.tr("IGUI_VehicleLightbar_Title"), pad, pad, th.r, th.g, th.b, th.a or 1, f1)
    local lights, siren = self:modes()
    local hits = {}
    _markO.win = self
    for gi, group in ipairs(GROUPS) do
        local x = pad + (gi - 1) * (colW + px(8))
        local y = pad + fh1 + gap
        local cur = (group == "lights") and lights or siren
        -- the switch's name: a press steps it, as the knob does; the controller's mark is here
        local kid = group .. ":knob"
        local o = _btnO
        o.hover = (self._hover == kid and not self.joyfocus) and true or false
        o.focus = (self.joyfocus and self.focus == gi) and _markO or nil
        ZeD.Molecules.drawButton(self, x, y, colW, bh, ZeD.tr(SWITCH_KEYS[group]), "default", o.hover and isMouseButtonDown(0), nil, o)
        hits[#hits + 1] = { id = kid, x = x, y = y, w = colW, h = bh, group = group, knob = true }
        for m = 3, 0, -1 do
            y = y + bh + gap
            local id = group .. ":" .. m
            o.hover = (self._hover == id and not self.joyfocus) and true or false
            o.focus = nil
            ZeD.Molecules.drawButton(self, x, y, colW, bh, modeWord(group, m), (m == cur) and "primary" or "default", o.hover and isMouseButtonDown(0), nil, o)
            hits[#hits + 1] = { id = id, x = x, y = y, w = colW, h = bh, group = group, knob = false, mode = m }
        end
    end
    self._hits = hits
    if stripH > 0 then
        ZeD.PadGlyphs.drawStrip(self, 0, bodyH, w, {
            { glyph = "<>", label = ZeD.tr("UI_ZeD_Siren_PromptSwitch") },
            { glyph = "^v", pad = { "DUD" }, label = ZeD.tr("UI_ZeD_Siren_PromptTurn") },
            { glyph = "A", label = ZeD.tr("UI_ZeD_Siren_Step") }, { glyph = "B", label = ZeD.tr("UI_ZeD_Hud_PutAway") } })
    end
end

-- the controller's mark (the hand, corners or ants) over the plain card, drawn last
function ZeD_SirenController:render()
    if self._plainOn and ZeD.Focus and ZeD.Focus.drawOverlay then ZeD.Focus.drawOverlay(self, self) end
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
    if S.qaJoy then jf = S.qaJoy end   -- (for the test scripts: the controller look without a controller)
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
--- bring the controller up for the character's car, or put it away when it is up; nothing in a car without a lightbar
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

--- Escape (the prompts' key hook asks): the controller on screen goes away; true when one did
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
