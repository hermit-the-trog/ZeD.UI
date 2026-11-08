-- ZeD-UI/42/media/lua/client/ZeD/ZeD_CarRadio.lua
-- ============================================================================
-- THE CAR RADIO, UP CLOSE — vanilla's Device Options window (ISRadioWindow on
-- a car's radio part) as the radio itself: no window chrome, no handset, the
-- set's own face with working controls. Client organism. The hook is
-- Overrides/CarRadio.lua (ISVehicleMenu.onSignalDevice, the wheel's Device
-- Options slice).
--
-- The fitted radio's face rises above the dash's console, the road still in
-- view, the way the siren controller does (only one of the two is up at a
-- time). Six faces in the dashboards' pixel art, drawn to match the dash (the
-- plates in PhysPx.lua, drawn by the shared plate template ZeD_Plate.lua):
-- Premium Technologies (CD), ValuTech, makeshift, and the two-way sets
-- (Premium Technologies ham, US ARMY COMM., makeshift ham). Live on each: the
-- display in pixel figures (ZeD_RadioOps.displayReading), the knob pointers,
-- the makeshift boards' rocker, the microphone lamp, the CD's edge in the slot,
-- the RANGE line, and the ValuTech's preset names in ballpoint on its tape.
--
-- Mouse: VOL pushes for power (the makeshift boards have a rocker) and the
-- wheel turns it; TUNE / the DIAL turn a step a click (right half up, left
-- half down) or with the wheel (a fast spin goes faster); presets listen on a
-- press and store on a hold (STORE n on the display); on a two-way set CH up /
-- down walks the stored channels, MEM stores and a held MEM names the channel
-- (an empty name forgets it); MIC mutes the microphone (its lamp lit); the CD
-- slot lists the CDs carried, EJECT gives the disc back.
-- Controller: the D-pad walks the controls, up / down on a knob turns it, A
-- presses, X stores (or names), B puts the radio away. Escape or leaving the
-- seat puts it away too. Every change is vanilla's radio code (ZeD_RadioOps).
--
-- SIMPLE (ZeD setup's Devices row, ZeD.Settings.devicesSimple): the plain
-- card in place of the face, the setting read as the card draws, so a switch
-- applies at once. It is the radio tab's plain card
-- (PlainFace.lua) over this radio's driver (R.plainBase below): the heading
-- (the radio's name), the readout (the frequency and station, or the CD's time
-- and title), a row per face control in the face's order (power and volume
-- first), the footer band (the power's state, MEM on a two-way set). Every
-- press goes to the face's own press / secondary, so both do the same. Mouse as
-- the face (a stepper's halves and the wheel turn); controller: up / down move,
-- left / right turn a stepper, A presses, X stores (or names), B puts it away.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/ZeD_RadioOps"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"
require "ZeD/PlainFace"

ZeD = ZeD or {}
ZeD.CarRadio = ZeD.CarRadio or {}
local R = ZeD.CarRadio
R.props = R.props or {}
local O = ZeD.RadioOps
local P = ZeD.Px
local PL = ZeD.Plate

local GAP = 6                     -- plate pixels between the radio and the dash
local PRESS_SHADE = 0.35          -- a held button's shade
local OWN_FOCUS = { focused = true }   -- the radio decides which control the controller is on (ZeD.Focus.mark)

-- the face's plate for a radio kind (nil when there is none)
local function plateFor(kind)
    local X = ZeD.PhysPx
    local id = X and X.radios[kind]
    return id and X.plates[id] or nil
end
R.plateFor = plateFor
local function plateTex(name) return P.tex(ZeD.PhysPx.texdir .. name .. ".png") end
local function now() return getTimestampMs() end
local function sound(name) pcall(function() getSoundManager():playUISound(name) end) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

-- what a button does on a press, and on X / a hold (nil = nothing)
-- (each value is a translation key, read through ZeD.tr when the prompt draws; Power and Microphone are vanilla's words)
local LABEL_A = {
    vol = "IGUI_RadioPower", tune = "UI_ZeD_RadioPrompt_Tune", eject = "UI_ZeD_RadioPrompt_Eject", scan = "UI_ZeD_RadioPrompt_Scan",
    seek = "UI_ZeD_RadioPrompt_Seek", mute = "UI_ZeD_RadioPrompt_Mute", play = "UI_ZeD_RadioPrompt_PlayStop",
    slot = "UI_ZeD_RadioPrompt_InsertCd", pwr = "IGUI_RadioPower", chup = "UI_ZeD_RadioPrompt_ChannelUp",
    chdn = "UI_ZeD_RadioPrompt_ChannelDown", mem = "UI_ZeD_RadioPrompt_StoreChannel", mic = "IGUI_RadioMicrophone",
}
for i = 1, 6 do LABEL_A["p" .. i] = "UI_ZeD_RadioPrompt_Listen" end
ZeD.trDefaults({
    UI_ZeD_RadioPrompt_Tune = "Tune", UI_ZeD_RadioPrompt_Eject = "Eject", UI_ZeD_RadioPrompt_Scan = "Scan",
    UI_ZeD_RadioPrompt_Seek = "Seek", UI_ZeD_RadioPrompt_Mute = "Mute", UI_ZeD_RadioPrompt_PlayStop = "Play / stop",
    UI_ZeD_RadioPrompt_InsertCd = "Insert a CD", UI_ZeD_RadioPrompt_ChannelUp = "Channel up",
    UI_ZeD_RadioPrompt_ChannelDown = "Channel down", UI_ZeD_RadioPrompt_StoreChannel = "Store channel",
    UI_ZeD_RadioPrompt_Listen = "Listen", UI_ZeD_RadioPrompt_Press = "Press", UI_ZeD_RadioPrompt_Store = "Store",
    UI_ZeD_RadioPrompt_NameChannel = "Name channel", UI_ZeD_RadioPrompt_SeekBack = "Seek back",
    UI_ZeD_RadioPrompt_Move = "Move / turn", UI_ZeD_Hud_PutAway = "Put away",
    UI_ZeD_Radio_NameChannel = "Name channel %1 (empty forgets it)", UI_ZeD_Radio_NoCds = "No CDs on you",
    UI_ZeD_PlainCarRadio_PresetNames = "Preset names",
})

-- the face's own first stop for the controller (the plain card's is its power switch)
local function faceFocus(kind) return O.HAM[kind] and "chup" or (kind == "makeshift" and "p1" or "vol") end

-- true while the devices are drawn as plain cards (ZeD setup's Devices row: Simple)
local function simpleOn()
    local S = ZeD.Settings
    return ZeD.PlainFace ~= nil and S ~= nil and S.devicesSimple ~= nil and S.devicesSimple() == true
end
R.simpleOn = simpleOn

-- ---------------------------------------------------------------------------
-- ZeD_CarRadio
-- ---------------------------------------------------------------------------
ZeD_CarRadio = ISPanel:derive("ZeD_CarRadio")

function ZeD_CarRadio:new(character, part)
    local o = ISPanel:new(0, 0, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.moveWithMouse = false
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.part = part
    o.focusId = nil
    o._hits = {}
    o._hover = nil
    o._press = nil         -- { id, t0, fired } while a button is held down
    o._wheel = { t = 0, streak = 0 }
    return o
end

-- the radio this prop belongs to, while the character can still reach it
function ZeD_CarRadio:livePart()
    local p = O.reachable(self.character)
    if p and p == self.part then return p end
    return nil
end

-- the CD list and the naming prompt open over the radio: it steps back from
-- always-on-top while they are up (update() takes it back)
function ZeD_CarRadio:yieldTop(watch)
    self._yieldTo = watch
    self:setAlwaysOnTop(false)
end

-- the CD list this radio opened, if it is still up
function ZeD_CarRadio:openList()
    local ctx = self._list
    local m = ctx and ctx._zedMenu
    if m and m._ctx and m._ctx.open then return m end
    return nil
end

function ZeD_CarRadio:close()
    self._press = nil
    self._yieldTo = nil
    local m = self:openList()
    if m then pcall(function() m:close() end) end
    self._list = nil
    self:setVisible(false)
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum + 1] and JoypadState.players[self.playerNum + 1].focus == self then
        setJoypadFocus(self.playerNum, nil)
    end
end

-- the face's controls (plate pixels, from the plate's click areas): the knobs, the buttons, the CD slot
function ZeD_CarRadio:controls(des)
    if self._ctlKind == self.kind and self._ctl then return self._ctl end
    local list = {}
    for _, h in ipairs(des.hits or {}) do
        local kind = h.kind or "press"
        if kind ~= "look" then
            local c = { id = h.id, x = h.x, y = h.y, w = h.w, h = h.h, kind = kind }
            if kind == "turn" then c.knob, c.cx, c.cy, c.r = true, h.x + h.w / 2, h.y + h.h / 2, h.w / 2 end
            list[#list + 1] = c
        end
    end
    self._ctl, self._ctlKind = list, self.kind
    return list
end

-- ---------------------------------------------------------------------------
-- LAYOUT: the dash's own whole multiple; the right edge on the dash console's right edge
-- ---------------------------------------------------------------------------
function ZeD_CarRadio:scale()
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance(self.playerNum)
    if dash and dash._s then return dash._s end
    local Sc = ZeD.Scale
    return P.k(((Sc and Sc.root and Sc.root()) or 1) * ((ZeD.Dashboard and ZeD.Dashboard.scale) or 1))
end

-- a w x h box (screen px) above the dash's console, its right edge on the console's (s: the dash's multiple)
function ZeD_CarRadio:place(w, h, s)
    local pn = self.playerNum
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance(self.playerNum)
    local x, y
    if dash and dash:isVisible() and dash._consoleRect and dash.playerNum == pn then
        local cs, ds = dash._consoleRect, dash._s or s
        x = dash:getX() + math.floor((cs.x + cs.w) * ds) - math.floor(w)
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

function ZeD_CarRadio:layout(A)
    local s = self:scale()
    local T = ZeD.T
    local pw, ph = A.w * s, A.h * s
    local stripH = self.joyfocus and ZeD.PadGlyphs.stripH() or 0
    self:place(pw, ph + (stripH > 0 and (T.px(4) + stripH) or 0), s)
    self._s, self._pw, self._ph, self._stripH = s, pw, ph, stripH
end

-- ---------------------------------------------------------------------------
-- DRAWING: the plate and its live parts (the template), then the cues
-- ---------------------------------------------------------------------------
local function rangeText(m)
    if not (m and m > 0) then return nil end
    local km = m / 1000
    return ZeD.tr("UI_ZeD_Radio_Range", (km == math.floor(km)) and tostring(math.floor(km)) or string.format("%.1f", km))
end

-- what the face's live parts read
function ZeD_CarRadio:plateState(st, t)
    local ps = {}
    ps.radioOn, ps.power = st.on, st.on
    ps.volF = st.volume or 0
    ps.tuneF = ((((st.channel or 0) / O.STEP) * 12) % 360) / 360       -- an endless tuning knob turns with the frequency
    ps.micMuted = (st.on and st.micMuted) and true or false             -- the lamp: lit while the set is on and the mic muted
    ps.micLive = not st.micMuted                                          -- a talk/listen switch: latched in while the mic is live, on or off
    ps.switchOn = st.switchOn
    ps.hasMedia = st.hasMedia
    ps.display = O.displayReading(st, t)
    ps.range = rangeText(st.range)
    if st.kind == "valutech" then                                         -- the presets' names on the masking tape
        local names = {}
        for i = 1, 6 do
            local p = st.presets[i]
            names[i] = p and O.tapeName(p.name) or ""
        end
        ps.tapeNames = names
    end
    return ps
end

function ZeD_CarRadio:prerender()
    local T = ZeD.T
    if not T then return end
    local part = self:livePart()
    if not part then self:close(); return end
    local st = O.read(part)
    if not st then self:close(); return end
    self.st = st
    self.kind = st.kind
    local des = plateFor(st.kind)
    if not des then self:close(); return end
    if simpleOn() then
        self._plain = true
        local ok, err = pcall(self.prerenderPlain, self, part, st)
        R.endFrame()
        if not ok then print("[ZeD] CarRadio: the plain card failed: " .. tostring(err)) end
        return
    end
    self._plain = false
    self:layout(des)
    local s = self._s
    local t = now()
    local cv = P.canvas(self, 0, 0, s)
    PL.draw(cv, des, self:plateState(st, t), { tex = plateTex, now = t })

    -- controls: a held key's shade, hover and focus. A key wears the library's looks (the pointer's wash,
    -- the controller's focus mark); a knob keeps its ring, which is the knob's own light
    local ac = T.accent
    local hits = {}
    local joy = self.joyfocus ~= nil
    for _, c in ipairs(self:controls(des)) do
        hits[#hits + 1] = { id = c.id, x = c.x * s, y = c.y * s, w = c.w * s, h = c.h * s, c = c }
        local focused = joy and self.focusId == c.id
        local hovered = (not joy) and self._hover == c.id
        if not c.knob and self._press and self._press.id == c.id then PL.cue(cv, c, P.BLACK, PRESS_SHADE) end
        if focused then
            if c.knob then PL.cue(cv, c, ac, 0.55) else PL.markKey(self, c, 0, 0, s, OWN_FOCUS) end
        elseif hovered then
            if c.knob then PL.cue(cv, c, ac, 0.30) else PL.hoverKey(cv, c) end
        end
    end
    self._hits = hits
    if joy and not self:hasHit(self.focusId) then self.focusId = faceFocus(self.kind) end   -- (back from the plain card)

    self:drawPadStrip()
    -- the controller's mark on a key, drawn last so no neighbour covers it
    ZeD.Focus.drawOverlay(self, self)
end

-- the controller's strip under the radio: the help line's look (pictures at 14u, F2 words)
function ZeD_CarRadio:drawPadStrip()
    if not (self._stripH and self._stripH > 0) then return end
    local items = { { glyph = "D-PAD", label = ZeD.tr("UI_ZeD_RadioPrompt_Move") } }
    local la = self:labelA()
    if la then items[#items + 1] = { glyph = "A", label = la } end
    local lx = self:labelX()
    if lx then items[#items + 1] = { glyph = "X", label = lx } end
    items[#items + 1] = { glyph = "B", label = ZeD.tr("UI_ZeD_Hud_PutAway") }
    ZeD.PadGlyphs.drawStrip(self, 0, self.height - self._stripH, self.width, items)
end

function ZeD_CarRadio:hasHit(id)
    if id == nil then return false end
    for _, h in ipairs(self._hits or {}) do if h.id == id then return true end end
    return false
end

function ZeD_CarRadio:labelA()
    if self._plain then return self:plainLabelA() end
    local id = self.focusId or "vol"
    if id == "tune" or (id == "vol" and (self.kind == "makeshift" or self.kind == "hammake")) then return nil end   -- a knob only turns
    if id == "slot" and self.st and self.st.hasMedia then return ZeD.tr("UI_ZeD_RadioPrompt_Eject") end
    return ZeD.tr(LABEL_A[id] or "UI_ZeD_RadioPrompt_Press")
end
function ZeD_CarRadio:labelX()
    if self._plain then return self:plainLabelX() end
    local id = self.focusId or ""
    if id:match("^p%d$") then return ZeD.tr("UI_ZeD_RadioPrompt_Store") end
    if id == "mem" then return ZeD.tr("UI_ZeD_RadioPrompt_NameChannel") end
    if id == "seek" then return ZeD.tr("UI_ZeD_RadioPrompt_SeekBack") end
    return nil
end

-- ---------------------------------------------------------------------------
-- ACTIONS
-- ---------------------------------------------------------------------------
local function hasPwrButton(kind) return kind == "makeshift" or kind == "hammake" end

-- a knob turned one click (dir +1 / -1); mult = the fast-turn multiplier
function ZeD_CarRadio:turn(id, dir, mult)
    local part = self:livePart(); if not part then return end
    if id == "vol" then O.volStep(self.character, part, dir, false)
    else O.tuneStep(self.character, part, dir, mult or 1) end
end

-- the press (A, a click, the end of a short press); at = { x, y } on the screen where the CD list opens (the plain card)
function ZeD_CarRadio:press(id, x, at)
    local part = self:livePart(); if not part then return end
    local chr, st = self.character, self.st or O.read(part)
    if id == "vol" then
        if hasPwrButton(self.kind) then self:turn("vol", (x and x < 0) and -1 or 1) else O.power(chr, part) end
    elseif id == "tune" then self:turn("tune", (x and x < 0) and -1 or 1)
    elseif id == "pwr" then O.power(chr, part)
    elseif id:match("^p%d$") then
        local i = tonumber(id:sub(2))
        if st.on and not O.recall(chr, part, i) then O.flash(part, ZeD.tr("UI_ZeD_Radio_Empty"), 900) end
    elseif id == "seek" then if st.on then O.seek(chr, part, 1) end
    elseif id == "scan" then if st.on then O.scanToggle(chr, part) end
    elseif id == "mute" then O.mute(chr, part)
    elseif id == "play" then O.playStop(chr, part)
    elseif id == "eject" then O.eject(chr, part)
    elseif id == "slot" then if st.hasMedia then O.eject(chr, part) else self:cdList(at) end
    elseif id == "chup" then if st.on then O.chStep(chr, part, 1) end
    elseif id == "chdn" then if st.on then O.chStep(chr, part, -1) end
    elseif id == "mem" then if st.on then O.memAdd(chr, part) end
    elseif id == "mic" then O.mic(chr, part) end
end

-- the second meaning (X, a hold, a right-click)
function ZeD_CarRadio:secondary(id)
    local part = self:livePart(); if not part then return end
    local chr, st = self.character, self.st or O.read(part)
    if id:match("^p%d$") then if st.on then O.store(chr, part, tonumber(id:sub(2))) end
    elseif id == "mem" then if st.on then self:nameChannel() end
    elseif id == "seek" then if st.on then O.seek(chr, part, -1) end
    elseif id == "tune" or id == "vol" then self:turn(id, -1) end
end

local function holdable(id) return id:match("^p%d$") ~= nil or id == "mem" end
-- the slot opens a list: it acts on the release, or the release would close the list it opened
local function onRelease(id) return holdable(id) or id == "slot" end

-- MEM held: name the channel (stored first if it is not yet); vanilla's text box (the ZeD prompt)
function ZeD_CarRadio:nameChannel()
    local part = self:livePart(); if not part then return end
    local st = O.read(part); if not st then return end
    local idx = st.presetIdx
    if not idx then
        idx = O.memAdd(self.character, part)
        if not idx then return end
        st = O.read(part)                                   -- the new channel's stored name
    end
    local cur = (st and st.presets[idx] and st.presets[idx].name) or ""
    local box = ISTextBox:new(0, 0, 280, 180, ZeD.tr("UI_ZeD_Radio_NameChannel", string.format("%02d", idx)), cur, self, ZeD_CarRadio.onNamed, self.playerNum, idx)
    box:initialise()
    box:addToUIManager()
    box.prevFocus = self
    self:yieldTop(function() return box:isReallyVisible() end)
    if JoypadState.players[self.playerNum + 1] then setJoypadFocus(self.playerNum, box) end
end
function ZeD_CarRadio:onNamed(button, idx)
    if not (button and button.internal == "OK") then return end
    local part = self:livePart(); if not part then return end
    local text = button.parent and button.parent.entry and button.parent.entry:getText() or ""
    O.rename(self.character, part, idx, text)
end

-- the empty slot: the CDs carried, as the belt's list (at: where the plain card's key asks it to open)
function ZeD_CarRadio:cdList(at)
    local part = self:livePart(); if not part then return end
    local des = plateFor(self.kind)
    if not des then return end
    local x, y
    if at then
        x, y = at.x, at.y
    else
        local slot = PL.find(self:controls(des), "slot")
        local s = self._s or 1
        -- over the slot, on the radio's top edge: the list stands above the radio, its display left clear
        x = self:getAbsoluteX() + math.floor(((slot and (slot.x + slot.w / 2)) or des.w / 2) * s)
        y = self:getAbsoluteY()
    end
    local context = ISContextMenu.get(self.playerNum, x, y)
    self._list = context
    local cds = O.cds(self.character, part)
    for _, item in ipairs(cds) do
        local opt = context:addOption(item:getDisplayName(), self, ZeD_CarRadio.onPickCD, item)
        opt.itemForTexture = item
    end
    if #cds == 0 then
        local o = context:addOption(ZeD.tr("UI_ZeD_Radio_NoCds"))
        o.notAvailable = true
    end
    self:yieldTop(function()
        local m = context._zedMenu
        if m and m._ctx then return m._ctx.open == true end
        return context:isReallyVisible() and context:getX() > -1000
    end)
    if JoypadState.players[self.playerNum + 1] then
        context.origin = self
        context.mouseOver = 1
        setJoypadFocus(self.playerNum, context)
    end
end
function ZeD_CarRadio:onPickCD(item)
    local part = self:livePart(); if not part then return end
    O.insert(self.character, part, item)
end

-- ---------------------------------------------------------------------------
-- MOUSE
-- ---------------------------------------------------------------------------
function ZeD_CarRadio:hitAt(x, y)
    for _, h in ipairs(self._hits or {}) do if inRect(h, x, y) then return h end end
    return nil
end

function ZeD_CarRadio:onMouseDown(x, y)
    local h = self:hitAt(x, y)
    if not h then return true end
    if self._plain then return self:plainDown(h, x) end
    if onRelease(h.id) then
        self._press = { id = h.id, t0 = now(), fired = false }
    elseif h.c.knob then
        -- the right half turns it up, the left half down; VOL is pushed
        self:press(h.id, x - (h.x + h.w / 2))
    else
        self._press = { id = h.id, t0 = now(), fired = true }   -- shaded while held; it acts on the press
        self:press(h.id)
    end
    return true
end

function ZeD_CarRadio:onMouseUp(x, y)
    local p = self._press
    self._press = nil
    if p and not p.fired then
        local h = self:hitAt(x, y)
        if h and h.id == p.id then
            if self._plain then self:plainPress(h) else self:press(p.id) end
        end
    end
    return true
end
function ZeD_CarRadio:onMouseUpOutside(x, y) self._press = nil; return true end

function ZeD_CarRadio:onRightMouseDown(x, y)
    local h = self:hitAt(x, y)
    if h then
        if self._plain then self:plainSecondary(h.id) else self:secondary(h.id) end
    end
    return true
end
function ZeD_CarRadio:onRightMouseUp(x, y) return true end

-- the wheel turns the knob under the pointer (a positive delta is the wheel turned down);
-- a fast spin goes further per click
function ZeD_CarRadio:onMouseWheel(del)
    local h = self:hitAt(self:getMouseX(), self:getMouseY())
    if h and h.c.knob then
        local t = now()
        if t - self._wheel.t < 110 then self._wheel.streak = self._wheel.streak + 1 else self._wheel.streak = 0 end
        self._wheel.t = t
        local mult = 1
        if h.id == "tune" then
            local k = self._wheel.streak
            if O.HAM[self.kind] then mult = (k >= 8 and 25) or (k >= 3 and 5) or 1 else mult = (k >= 4 and 5) or 1 end
        end
        self:turnAny(h.id, del > 0 and -1 or 1, mult)
    end
    return true
end

-- a knob (or the plain card's stepper) turned one click, whichever the radio shows
function ZeD_CarRadio:turnAny(id, dir, mult)
    if not self._plain then return self:turn(id, dir, mult) end
    local part = self:livePart(); if not part then return end
    R.plainDriver().turn(self.character, part, id, dir, mult)
end

function ZeD_CarRadio:update()
    ISPanel.update(self)
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    local jf = (jd and jd.focus == self) and jd or nil
    if R.qaJoy then jf = R.qaJoy end
    self.joyfocus = jf
    local h = self:hitAt(self:getMouseX(), self:getMouseY())
    if R.qaPoint then h = { id = R.qaPoint } end
    self._hover = h and h.id or nil
    -- the list / prompt gone: back on top
    if self._yieldTo then
        local ok, up = pcall(self._yieldTo)
        if not (ok and up) then self._yieldTo = nil; self:setAlwaysOnTop(true) end
    end
    -- a held preset / MEM: the hold stores (or names) once
    local p = self._press
    if p and not p.fired and self._plain then
        local part = self:livePart()
        if part then R.plainDriver().holdTick(p, self.character, part, self) end
    elseif p and not p.fired and holdable(p.id) and now() - p.t0 >= O.HOLD_MS then
        p.fired = true
        self:secondary(p.id)
    end
end

-- ---------------------------------------------------------------------------
-- CONTROLLER (the D-pad as onJoypadDir* only; buttons in onJoypadDown)
-- ---------------------------------------------------------------------------
function ZeD_CarRadio:onGainJoypadFocus(joypadData) self.joyfocus = joypadData end
function ZeD_CarRadio:onLoseJoypadFocus(joypadData) self.joyfocus = nil end

function ZeD_CarRadio:focused()
    for _, h in ipairs(self._hits or {}) do if h.id == self.focusId then return h end end
    return self._hits and self._hits[1] or nil
end

-- the nearest control in a direction (centre to centre, straight lines preferred)
function ZeD_CarRadio:moveFocus(dx, dy)
    local cur = self:focused(); if not cur then return end
    local cx, cy = cur.x + cur.w / 2, cur.y + cur.h / 2
    local best, bestScore = nil, nil
    for _, h in ipairs(self._hits) do
        if h ~= cur then
            local hx, hy = h.x + h.w / 2, h.y + h.h / 2
            local along = (hx - cx) * dx + (hy - cy) * dy
            local across = math.abs((hx - cx) * dy) + math.abs((hy - cy) * dx)
            if along > 2 then
                local score = along + across * 2.5
                if not bestScore or score < bestScore then best, bestScore = h, score end
            end
        end
    end
    if best then self.focusId = best.id; sound("UISelectListItem") end
end

-- up / down on a knob turns it (held, the DIAL speeds up)
function ZeD_CarRadio:dirTurn(dir)
    local t = now()
    local k = self._padTurn or { t = 0, streak = 0 }
    if t - k.t < 260 then k.streak = k.streak + 1 else k.streak = 0 end
    k.t = t
    self._padTurn = k
    local mult = 1
    if self.focusId == "tune" then
        if O.HAM[self.kind] then mult = (k.streak >= 10 and 25) or (k.streak >= 4 and 5) or 1 else mult = (k.streak >= 8 and 5) or 1 end
    end
    self:turnAny(self.focusId, dir, mult)
end

function ZeD_CarRadio:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then self:close()
    elseif self._plain then self:plainJoypad(button)
    elseif button == Joypad.AButton then
        local id = self.focusId or "vol"
        if id == "vol" and hasPwrButton(self.kind) then return end
        if id == "tune" then return end
        self:press(id)
    elseif button == Joypad.XButton then
        local id = self.focusId or ""
        if id:match("^p%d$") or id == "mem" or id == "seek" then self:secondary(id) end
    end
end
function ZeD_CarRadio:isKnobFocused() local f = self:focused(); return f and f.c and f.c.knob end
-- (the plain card is a column: up / down move on, left / right turn a stepper)
function ZeD_CarRadio:onJoypadDirLeft() if self._plain and self:isKnobFocused() then self:dirTurn(-1) else self:moveFocus(-1, 0) end end
function ZeD_CarRadio:onJoypadDirRight() if self._plain and self:isKnobFocused() then self:dirTurn(1) else self:moveFocus(1, 0) end end
function ZeD_CarRadio:onJoypadDirUp() if not self._plain and self:isKnobFocused() then self:dirTurn(1) else self:moveFocus(0, -1) end end
function ZeD_CarRadio:onJoypadDirDown() if not self._plain and self:isKnobFocused() then self:dirTurn(-1) else self:moveFocus(0, 1) end end

-- ---------------------------------------------------------------------------
-- THE PLAIN CARD (Devices: Simple): the radio tab's plain card (PlainFace.lua) over this radio's driver
-- ---------------------------------------------------------------------------
-- the radio kind behind a face's plate id
local _kindOfPid = nil
local function kindOfPid(pid)
    if not _kindOfPid then
        _kindOfPid = {}
        for k, id in pairs(ZeD.PhysPx.radios) do _kindOfPid[id] = k end
    end
    return _kindOfPid[pid]
end

-- the driver PlainFace forwards to (read, plateId, press, turn, secondary, holdable, onRelease, holdTick, turnMult,
-- plainSpec). A press goes to the prop's own press / secondary, so the card and the face do the same things.
local CB = {}
R.plainBase = CB
local _frame = {}                -- this frame's reading while the card draws (the radio read once a frame)
function R.endFrame() _frame.part, _frame.st = nil, nil end

function CB.read(part)
    if part ~= nil and _frame.part == part then return _frame.st end
    local st = O.read(part)
    if st then st.dev, st.clockMs = part, st.cdMs end        -- (the card's names: the radio, the CD's clock)
    return st
end

function CB.plateId(part)
    local ok, item = pcall(function() return part:getInventoryItem() end)
    local ok2, dd = pcall(function() return part:getDeviceData() end)
    local kind = O.kindOf(ok and item or nil, ok2 and dd or nil)
    return kind and ZeD.PhysPx.radios[kind] or nil
end

local function propOf(chr) return chr and R.props[chr:getPlayerNum()] or nil end
-- the power switch's face control: VOL pushed (the CD radio, the ValuTech, the ham sets) or the power rocker
local POWER_IDS = { power = true, volpwr = true, pwr = true, vol = true }

function CB.press(chr, part, id, dx, at)
    if not (chr and part and id) then return end
    if POWER_IDS[id] then O.power(chr, part); return end
    local p = propOf(chr)
    if not p then return end
    if id == "seekdn" then p:secondary("seek")                -- (SEEK's second meaning: the face's X)
    else p:press(id, nil, at) end
end
function CB.turn(chr, part, id, dir, mult)
    if id == "vol" then O.volStep(chr, part, dir, false)
    elseif id == "tune" then O.tuneStep(chr, part, dir, mult or 1) end
end
function CB.secondary(chr, part, id, owner)
    local p = propOf(chr)
    if p then p:secondary(id) end
end
CB.holdable = holdable
CB.onRelease = onRelease
function CB.holdTick(hold, chr, part, owner)
    if hold and not hold.fired and holdable(hold.id) and now() - hold.t0 >= O.HOLD_MS then
        hold.fired = true
        CB.secondary(chr, part, hold.id, owner)
    end
end
function CB.turnMult(pid, streak)
    if O.HAM[kindOfPid(pid)] then return (streak >= 10 and 25) or (streak >= 4 and 5) or 1 end
    return (streak >= 8 and 5) or 1
end

-- the ValuTech's preset names (its masking tape): "1 Knox | 2 Aebs", the keys with nothing stored left out
local function tapeNames(x)
    local st, s = x.st, nil
    for i = 1, 6 do
        local p = st.presets and st.presets[i]
        local nm = p and O.tapeName(p.name) or ""
        if nm ~= "" then
            local one = tostring(i) .. " " .. nm
            s = s and (s .. " | " .. one) or one
        end
    end
    return s or "--"
end
local NAMES_ROW = { id = "names", kind = "read", wrap = true, label = "UI_ZeD_PlainCarRadio_PresetNames", val = tapeNames }

-- the face's controls in reading order, the power key and the volume first (as on every plain radio card)
local function carOrder(hits)
    local out = ZeD.TwoWay.readingOrder(hits, 1)
    local pw, vol = nil, nil
    for i = #out, 1, -1 do
        local id = out[i].id
        if id == "pwr" then pw = table.remove(out, i) elseif id == "vol" then vol = table.remove(out, i) end
    end
    if vol then table.insert(out, 1, vol) end
    if pw then table.insert(out, 1, pw) end
    return out
end

local _spec = {}
function CB.plainSpec(pid)
    local sp = _spec[pid]
    if sp then return sp end
    local kind = kindOfPid(pid)
    sp = { tw = O.HAM[kind] == true, volPower = (kind == "premium" or kind == "valutech"), order = carOrder, noBattery = true }
    if kind == "valutech" then sp.after = { presets = NAMES_ROW } end
    _spec[pid] = sp
    return sp
end

-- PlainFace's driver over this one (PlainFace keeps it)
function R.plainDriver() return ZeD.PlainFace.wrap(CB) end

-- the card: the box and its heading (the radio's name), then PlainFace's readout, rows and footer band; it stands
-- where the face stands, its right edge on the dash console's
local _plainFace = {}
function ZeD_CarRadio:prerenderPlain(part, st)
    local T, tm, PF, A = ZeD.T, ZeD.TM, ZeD.PlainFace, ZeD.Atoms
    st.dev, st.clockMs = part, st.cdMs
    _frame.part, _frame.st = part, st
    local pid = ZeD.PhysPx.radios[st.kind]
    local w = math.min(T.px(PF.FULL_W), getPlayerScreenWidth(self.playerNum))
    local f1 = T.fontF1
    local pad = T.px(10)
    local headH = T.px(8) + tm:getFontHeight(f1) + T.px(6)
    local bodyH = headH + PF.height(CB, part, pid, w)
    local stripH = self.joyfocus and ZeD.PadGlyphs.stripH() or 0
    self:place(w, bodyH + (stripH > 0 and (T.px(4) + stripH) or 0), self:scale())
    self._stripH = stripH
    ZeD.Surface.fill(self, 0, 0, w, bodyH, "surf2")
    local b = T.borderS
    self:drawRectBorder(0, 0, w, bodyH, b.a or 1, b.r, b.g, b.b)
    local th = T.textHead or T.text
    local name = st.item and st.item:getDisplayName() or ""
    self:drawText(A.truncateText(name, f1, w - 2 * pad), pad, T.px(8), th.r, th.g, th.b, th.a or 1, f1)
    A.drawDividerH(self, 0, headH - T.line(T.borderW), w)
    local joy = self.joyfocus ~= nil
    local face = _plainFace
    face.dev, face.pid, face.des, face.w, face.minH = part, pid, PF.des(CB, pid), w, 0
    face.focusId = joy and self.focusId or nil
    face.hoverId = (not joy) and self._hover or nil
    face.pressId = self._press and self._press.id or nil
    face.win, face.ownFocus = self, true
    local hits = PF.draw(CB, self, 0, headH, face)
    for _, h in ipairs(hits) do h.c = h end                   -- (the face's walk and wheel read h.c.knob)
    self._hits = hits
    if joy and not self:hasHit(self.focusId) and hits[1] then self.focusId = hits[1].id end
    self:drawPadStrip()
    ZeD.Focus.drawOverlay(self, self)
end

-- where a list opens for a key on the card (screen px: under the key)
function ZeD_CarRadio:atOf(h)
    return { x = self:getAbsoluteX() + h.x, y = self:getAbsoluteY() + h.y + h.h }
end

function ZeD_CarRadio:plainPress(h)
    local part = self:livePart(); if not part then return end
    R.plainDriver().press(self.character, part, h.id, nil, self:atOf(h))
end
function ZeD_CarRadio:plainSecondary(id)
    local part = self:livePart(); if not part then return end
    R.plainDriver().secondary(self.character, part, id, self)
end

-- a press on the card: a stepper turns by the half pressed; a key that may be held (a preset, MEM) or opens a list
-- (the disc) acts on the release; the rest on the press
function ZeD_CarRadio:plainDown(h, x)
    local part = self:livePart(); if not part then return true end
    local D = R.plainDriver()
    if h.knob then
        D.press(self.character, part, h.id, x - (h.x + h.w / 2))
    elseif D.onRelease(h.id) then
        self._press = { id = h.id, t0 = now(), fired = false }
    else
        self._press = { id = h.id, t0 = now(), fired = true }   -- shaded while held; it acts on the press
        self:plainPress(h)
    end
    return true
end

-- A presses (a stepper turns with left / right instead), X stores a preset or names the channel
function ZeD_CarRadio:plainJoypad(button)
    local h = self:focused()
    if not h then return end
    if button == Joypad.AButton then
        if not h.knob then self:plainPress(h) end
    elseif button == Joypad.XButton then
        if R.plainDriver().holdable(h.id) then self:plainSecondary(h.id) end
    end
end

function ZeD_CarRadio:plainLabelA()
    local h = self:focused()
    if not h or h.knob then return nil end
    if h.id == "power" then return ZeD.tr("IGUI_RadioPower") end
    if h.id == "media" then
        return ZeD.tr((self.st and self.st.hasMedia) and "UI_ZeD_RadioPrompt_Eject" or "UI_ZeD_RadioPrompt_InsertCd")
    end
    return ZeD.tr(LABEL_A[h.id] or "UI_ZeD_RadioPrompt_Press")
end
function ZeD_CarRadio:plainLabelX()
    local h = self:focused()
    local id = h and h.id or ""
    if id:match("^p%d$") then return ZeD.tr("UI_ZeD_RadioPrompt_Store") end
    if id == "mem" then return ZeD.tr("UI_ZeD_RadioPrompt_NameChannel") end
    return nil
end

-- ---------------------------------------------------------------------------
-- ENTRY (the wheel's Device Options slice; the dash's display)
-- ---------------------------------------------------------------------------
function R.closeFor(pn)
    local p = R.props[pn]
    if p and p:isReallyVisible() then p:close(); return true end
    return false
end

function R.toggle(character, part)
    if not character then return end
    local pn = character:getPlayerNum()
    local prop = R.props[pn]
    if prop and prop:isReallyVisible() then prop:close(); return end
    part = part or O.reachable(character)
    if not (part and part == O.reachable(character)) then return end
    local st = O.read(part)
    if not (st and plateFor(st.kind)) then error("no face for this radio") end
    if ZeD.Siren and ZeD.Siren.props and ZeD.Siren.props[pn] and ZeD.Siren.props[pn]:isReallyVisible() then ZeD.Siren.props[pn]:close() end
    if not prop or prop.character ~= character then
        prop = ZeD_CarRadio:new(character, part)
        prop:initialise()
        prop:instantiate()
        R.props[pn] = prop
    end
    prop.part = part
    prop.kind = st.kind
    prop.focusId = simpleOn() and "power" or faceFocus(st.kind)    -- (the plain card's first row: its power switch)
    prop:setVisible(true)
    prop:addToUIManager()
    prop:setAlwaysOnTop(true)
    if JoypadState.players[pn + 1] then setJoypadFocus(pn, prop) end
end

-- Escape (the prompts' key hook asks): the radio's CD list goes first, then the radio
function R.takeEscape()
    for _, p in pairs(R.props) do
        if p and p:isReallyVisible() then
            local m = p:openList()
            if m then pcall(function() m:close() end)
            else p:close() end
            return true
        end
    end
    return false
end

-- leaving the car (or its front seats) puts it away
if Events and Events.OnExitVehicle then
    Events.OnExitVehicle.Add(function(character)
        local pn = character and character.getPlayerNum and character:getPlayerNum()
        if pn then R.closeFor(pn) end
    end)
end
if Events and Events.OnSwitchVehicleSeat then
    Events.OnSwitchVehicleSeat.Add(function(character)
        local pn = character and character.getPlayerNum and character:getPlayerNum()
        if pn and not O.reachable(character) then R.closeFor(pn) end
    end)
end

function R.get(pn) return R.props[pn or 0] end
