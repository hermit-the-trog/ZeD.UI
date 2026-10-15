-- ZeD-UI/42/media/lua/client/ZeD/ZeD_SirenController.lua
-- ============================================================================
-- THE SIREN CONTROLLER, UP CLOSE — vanilla's ISLightbarUI as a 1993 prop
-- Mockup ZeDUI/mockups/zed_seats_lightbar_v1.html (director, Oct 15 2026:
-- "lightbar is cool, better than the plain version", then "build both").
-- HOOK_MAP row 4; the hook is Overrides/Seats.lua (ISLightbarUITimedAction).
--
-- The police dash's own siren controller brought up close: the faceplate
-- (ZeDUI/tools/plates/bake_siren_plate.py, anchors in SirenPlate.lua) with two
-- rotary switches, LIGHTS (OFF 1 2 3) and SIREN (vanilla's STANDBY YELP WAIL
-- ALARM), and their pilot lamps. It rises above the dash's console, so the car
-- and its bar stay in view; with no dash it sits above the bottom of the
-- player's screen. The wheel's Lightbar slice opens and closes it; leaving the
-- car, Escape or B puts it away.
--
-- Mouse: click a word to turn the switch there, click the knob to step it,
-- the wheel turns it. Controller: left / right picks a switch (the accent
-- fill), up / down turns it, A steps it, B puts it away. Every change is
-- vanilla's own command (setLightbarLightsMode / setLightbarSirenMode) with
-- vanilla's sounds, so it works the same in multiplayer.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/SirenPlate"

ZeD = ZeD or {}
ZeD.Siren = ZeD.Siren or {}
local S = ZeD.Siren
S.props = S.props or {}

local TEX = "media/textures/ZeD/dash/"
local GAP = 6                    -- units between the prop and the dash
local LEG_PX = 10                -- the legends' size (units)
local PTR_R0, PTR_R1 = 4, 20     -- the pointer line, from the knob centre (units)
local LIGHTS_WORDS = { "OFF", "1", "2", "3" }
local SIREN_KEYS = { "IGUI_VehicleLightbar_STANDBY", "IGUI_VehicleLightbar_YELP", "IGUI_VehicleLightbar_WAIL", "IGUI_VehicleLightbar_ALARM" }

local _tex = {}
local function tex(name)
    local t = _tex[name]
    if t == nil then t = getTexture(TEX .. name .. ".png") or false; _tex[name] = t end
    return t or nil
end
local function hexc(s)
    s = tostring(s):gsub("#", "")
    return { r = tonumber(s:sub(1, 2), 16) / 255, g = tonumber(s:sub(3, 4), 16) / 255, b = tonumber(s:sub(5, 6), 16) / 255 }
end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name) end) end

local function words(groupId)
    if groupId == "lights" then return LIGHTS_WORDS end
    local t = {}
    for i, k in ipairs(SIREN_KEYS) do t[i] = getTextOrNull(k) and getText(k) or ({ "STANDBY", "YELP", "WAIL", "ALARM" })[i] end
    return t
end

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
-- LAYOUT: the dash's own scale; the right edge on the dash console's right edge
-- ---------------------------------------------------------------------------
function ZeD_SirenController:scale()
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance()
    if dash and dash._s then return dash._s end
    local Sc = ZeD.Scale
    return ((Sc and Sc.root and Sc.root()) or 1) * ((ZeD.Dashboard and ZeD.Dashboard.scale) or 1)
end

function ZeD_SirenController:layout()
    local P = ZeD.SirenPlate
    local s = self:scale()
    local T = ZeD.T
    local pw, ph = math.floor((P.w + P.shadow) * s), math.floor((P.h + P.shadow) * s)
    local stripH = self.joyfocus and T.sp.scrollbarW or 0
    local w, h = pw, ph + (stripH > 0 and (T.px(4) + stripH) or 0)
    local pn = self.playerNum
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance()
    local x, y
    if dash and dash:isVisible() and dash._consoleRect and dash.playerNum == pn then
        local cs, ds = dash._consoleRect, dash._s or s
        x = dash:getX() + math.floor((cs.x + cs.w) * ds) - math.floor(P.w * s)
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
-- DRAWING
-- ---------------------------------------------------------------------------
-- a straight run of small squares from the knob centre (the dash's knob pointer)
local function pointer(p, cx, cy, deg, r0, r1, s, c)
    local a = (deg - 90) * math.pi / 180
    local ca, sa = math.cos(a), math.sin(a)
    local t = math.max(1, math.floor(2 * s))
    local r = r0
    while r <= r1 do
        p:drawRect(math.floor((cx + ca * r) * s - t / 2), math.floor((cy + sa * r) * s - t / 2), t, t, 1, c.r, c.g, c.b)
        r = r + 1 / s
    end
end

function ZeD_SirenController:prerender()
    local T = ZeD.T
    local P = ZeD.SirenPlate
    if not (T and P) then return end
    if not self:vehicle() then self:close(); return end
    self:layout()
    local s = self._s
    local X, F = ZeD.Text, ZeD.Font
    local lights, siren = self:modes()
    local plate = tex("siren_plate")
    if plate then self:drawTextureScaledAspect(plate, 0, 0, self._pw, self._ph, 1, 1, 1, 1)
    else self:drawRect(0, 0, math.floor(P.w * s), math.floor(P.h * s), 1, 0.11, 0.11, 0.12) end
    local ac = T.accent
    local hits = {}
    for gi, gp in ipairs(P.groups) do
        local mode = gp.id == "lights" and lights or siren
        -- the controller's switch: the accent fill under the knob (the knob is drawn over it)
        if self.joyfocus and self.focus == gi then
            self:drawRect(math.floor(gp.x * s), math.floor(gp.y * s), math.floor(gp.w * s), math.floor(gp.h * s), 0.55, ac.r, ac.g, ac.b)
        end
        -- the words around the knob (the one it points at, lit)
        local f = F and F.sdf and (F.sdf.sec or F.sdf.stat)
        local z = (X and f) and X.zoomFor(f, LEG_PX * s) or 1
        for i, word in ipairs(words(gp.id)) do
            local a = math.rad(P.angles[i])
            local lx, ly = gp.kx + P.legR * math.sin(a), gp.ky - P.legR * math.cos(a)
            local wpx = (X and f) and X.width(f, word, z) or ZeD.TM:MeasureStringX(T.fontF1, word)
            local hpx = (X and f) and X.height(f, z) or ZeD.TM:getFontHeight(T.fontF1)
            local r = { x = math.floor(lx * s - wpx / 2) - math.floor(3 * s), y = math.floor(ly * s - hpx / 2), w = math.floor(wpx) + math.floor(6 * s), h = math.floor(hpx) }
            local id = gp.id .. ":" .. (i - 1)
            hits[#hits + 1] = { id = id, x = r.x, y = r.y, w = r.w, h = r.h, group = gp.id, mode = i - 1 }
            if self._hover == id and not self.joyfocus then self:drawRect(r.x, r.y, r.w, r.h, 0.22, ac.r, ac.g, ac.b) end
            local c = (i - 1 == mode) and { r = 1, g = 1, b = 1 } or { r = 0.78, g = 0.78, b = 0.78 }
            if X and f then X.draw(self, f, word, lx * s, ly * s - hpx / 2, z, c.r, c.g, c.b, 1, "c")
            else self:drawText(word, math.floor(lx * s - wpx / 2), math.floor(ly * s - hpx / 2), c.r, c.g, c.b, 1, T.fontF1) end
        end
        -- the knob, its pointer
        local kb = P.knobBox * s
        local kx0, ky0 = math.floor((gp.kx - P.knobC) * s), math.floor((gp.ky - P.knobC) * s)
        local kid = gp.id .. ":knob"
        hits[#hits + 1] = { id = kid, x = math.floor((gp.kx - P.knobR) * s), y = math.floor((gp.ky - P.knobR) * s), w = math.floor(P.knobR * 2 * s), h = math.floor(P.knobR * 2 * s), group = gp.id, knob = true }
        if self._hover == kid and not self.joyfocus then
            self:drawRect(math.floor((gp.kx - P.knobR - 3) * s), math.floor((gp.ky - P.knobR - 3) * s), math.floor((P.knobR * 2 + 6) * s), math.floor((P.knobR * 2 + 6) * s), 0.22, ac.r, ac.g, ac.b)
        end
        local kt = tex("siren_knob")
        if kt then self:drawTextureScaledAspect(kt, kx0, ky0, math.floor(kb), math.floor(kb), 1, 1, 1, 1) end
        pointer(self, gp.kx, gp.ky, P.angles[1] + mode * 40, PTR_R0, PTR_R1, s, { r = 0.94, g = 0.94, b = 0.94 })
        -- the pilot lamp
        if mode > 0 then
            local lc = hexc(gp.led.c)
            local lcx, lcy = (gp.led.x + gp.led.sz / 2) * s, (gp.led.y + gp.led.sz / 2) * s
            local gl, gsz = tex("siren_glow"), 28 * s
            if gl then self:drawTextureScaledAspect(gl, math.floor(lcx - gsz / 2), math.floor(lcy - gsz / 2), math.floor(gsz), math.floor(gsz), 0.7, lc.r, lc.g, lc.b) end
            local led = tex("siren_led")
            if led then self:drawTextureScaledAspect(led, math.floor(gp.led.x * s), math.floor(gp.led.y * s), math.floor(gp.led.sz * s), math.floor(gp.led.sz * s), 1, lc.r, lc.g, lc.b) end
        end
    end
    self._hits = hits
    -- the controller's strip under the faceplate
    if self._stripH > 0 then
        local y = self.height - self._stripH
        local s2, bs = T.surf2, T.borderS
        self:drawRect(0, y, self.width, self._stripH, 1, s2.r, s2.g, s2.b)
        self:drawRectBorder(0, y, self.width, self._stripH, bs.a or 1, bs.r, bs.g, bs.b)
        ZeD.Molecules.drawGlyphPrompts(self, T.sp.sm, y, self._stripH, {
            "D-PAD Left / Right: switch   Up / Down: turn", { glyph = "A", label = "Step" }, { glyph = "B", label = "Put away" } })
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
local function gid(self) return ZeD.SirenPlate.groups[self.focus].id end
function ZeD_SirenController:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then self:close()
    elseif button == Joypad.AButton then self:step(gid(self), 0) end
end
function ZeD_SirenController:onJoypadDirLeft() if self.focus > 1 then self.focus = self.focus - 1; sound("UISelectListItem") end end
function ZeD_SirenController:onJoypadDirRight() if self.focus < #ZeD.SirenPlate.groups then self.focus = self.focus + 1; sound("UISelectListItem") end end
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
