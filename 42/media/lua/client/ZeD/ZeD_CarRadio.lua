-- ZeD-UI/42/media/lua/client/ZeD/ZeD_CarRadio.lua
-- ============================================================================
-- THE CAR RADIO, UP CLOSE — vanilla's Device Options window (ISRadioWindow on
-- a car's radio part) as the radio itself. Mockup ZeDUI/mockups/
-- zed_car_radio_v1.html (director, Oct 15 2026: "lose the handset/mic", then
-- "love it, build it, yes match the dash to the radio"). HOOK_MAP row 4; the
-- hook is Overrides/CarRadio.lua (ISVehicleMenu.onSignalDevice).
--
-- The fitted radio's face rises above the dash's console, the road still in
-- view, the way the siren controller does (only one of the two is up at a
-- time). Six faces in the dashboards' pixel art (director, Oct 16 2026; the
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
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/ZeD_RadioOps"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"

ZeD = ZeD or {}
ZeD.CarRadio = ZeD.CarRadio or {}
local R = ZeD.CarRadio
R.props = R.props or {}
local O = ZeD.RadioOps
local P = ZeD.Px
local PL = ZeD.Plate

local GAP = 6                     -- plate pixels between the radio and the dash
local PRESS_SHADE = 0.35          -- a held button's shade

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
local LABEL_A = {
    vol = "Power", tune = "Tune", eject = "Eject", scan = "Scan", seek = "Seek", mute = "Mute", play = "Play / Stop",
    slot = "Insert a CD", pwr = "Power", chup = "Channel up", chdn = "Channel down", mem = "Store channel", mic = "Microphone",
}
for i = 1, 6 do LABEL_A["p" .. i] = "Listen" end

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
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance()
    if dash and dash._s then return dash._s end
    local Sc = ZeD.Scale
    return P.k(((Sc and Sc.root and Sc.root()) or 1) * ((ZeD.Dashboard and ZeD.Dashboard.scale) or 1))
end

function ZeD_CarRadio:layout(A)
    local s = self:scale()
    local T = ZeD.T
    local pw, ph = A.w * s, A.h * s
    local stripH = self.joyfocus and T.sp.scrollbarW or 0
    local w, h = pw, ph + (stripH > 0 and (T.px(4) + stripH) or 0)
    local pn = self.playerNum
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance()
    local x, y
    if dash and dash:isVisible() and dash._consoleRect and dash.playerNum == pn then
        local cs, ds = dash._consoleRect, dash._s or s
        x = dash:getX() + math.floor((cs.x + cs.w) * ds) - math.floor(A.w * s)
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
local function rangeText(m)
    if not (m and m > 0) then return nil end
    local km = m / 1000
    return "RANGE " .. ((km == math.floor(km)) and tostring(math.floor(km)) or string.format("%.1f", km)) .. " KM"
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
    self:layout(des)
    local s = self._s
    local t = now()
    local cv = P.canvas(self, 0, 0, s)
    PL.draw(cv, des, self:plateState(st, t), { tex = plateTex, now = t })

    -- controls: a held key's shade, hover and focus (a ring round a knob, a fill over a key)
    local ac = T.accent
    local hits = {}
    local joy = self.joyfocus ~= nil
    for _, c in ipairs(self:controls(des)) do
        hits[#hits + 1] = { id = c.id, x = c.x * s, y = c.y * s, w = c.w * s, h = c.h * s, c = c }
        local focused = joy and self.focusId == c.id
        local hovered = (not joy) and self._hover == c.id
        if not c.knob and self._press and self._press.id == c.id then PL.cue(cv, c, P.BLACK, PRESS_SHADE) end
        if focused then PL.cue(cv, c, ac, 0.55)
        elseif hovered then PL.cue(cv, c, ac, c.knob and 0.30 or 0.22) end
    end
    self._hits = hits

    -- the controller's strip under the radio
    if self._stripH > 0 then
        local y = self.height - self._stripH
        local s2, bs = T.surf2, T.borderS
        self:drawRect(0, y, self.width, self._stripH, 1, s2.r, s2.g, s2.b)
        self:drawRectBorder(0, y, self.width, self._stripH, bs.a or 1, bs.r, bs.g, bs.b)
        local items = { "D-PAD Move / Turn" }
        local la = self:labelA()
        if la then items[#items + 1] = { glyph = "A", label = la } end
        local lx = self:labelX()
        if lx then items[#items + 1] = { glyph = "X", label = lx } end
        items[#items + 1] = { glyph = "B", label = "Put away" }
        ZeD.Molecules.drawGlyphPrompts(self, T.sp.sm, y, self._stripH, items)
    end
end

function ZeD_CarRadio:labelA()
    local id = self.focusId or "vol"
    if id == "tune" or (id == "vol" and (self.kind == "makeshift" or self.kind == "hammake")) then return nil end   -- a knob only turns
    if id == "slot" and self.st and self.st.hasMedia then return "Eject" end
    return LABEL_A[id] or "Press"
end
function ZeD_CarRadio:labelX()
    local id = self.focusId or ""
    if id:match("^p%d$") then return "Store" end
    if id == "mem" then return "Name channel" end
    if id == "seek" then return "Seek back" end
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

-- the press (A, a click, the end of a short press)
function ZeD_CarRadio:press(id, x)
    local part = self:livePart(); if not part then return end
    local chr, st = self.character, self.st or O.read(part)
    if id == "vol" then
        if hasPwrButton(self.kind) then self:turn("vol", (x and x < 0) and -1 or 1) else O.power(chr, part) end
    elseif id == "tune" then self:turn("tune", (x and x < 0) and -1 or 1)
    elseif id == "pwr" then O.power(chr, part)
    elseif id:match("^p%d$") then
        local i = tonumber(id:sub(2))
        if st.on and not O.recall(chr, part, i) then O.flash(part, "EMPTY", 900) end
    elseif id == "seek" then if st.on then O.seek(chr, part, 1) end
    elseif id == "scan" then if st.on then O.scanToggle(chr, part) end
    elseif id == "mute" then O.mute(chr, part)
    elseif id == "play" then O.playStop(chr, part)
    elseif id == "eject" then O.eject(chr, part)
    elseif id == "slot" then if st.hasMedia then O.eject(chr, part) else self:cdList() end
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
    local box = ISTextBox:new(0, 0, 280, 180, "Name channel " .. string.format("%02d", idx) .. " (empty forgets it)", cur, self, ZeD_CarRadio.onNamed, self.playerNum, idx)
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

-- the empty slot: the CDs carried, as the belt's list
function ZeD_CarRadio:cdList()
    local part = self:livePart(); if not part then return end
    local des = plateFor(self.kind)
    if not des then return end
    local slot = PL.find(self:controls(des), "slot")
    local s = self._s or 1
    -- over the slot, on the radio's top edge: the list stands above the radio, its display left clear
    local x = self:getAbsoluteX() + math.floor(((slot and (slot.x + slot.w / 2)) or des.w / 2) * s)
    local y = self:getAbsoluteY()
    local context = ISContextMenu.get(self.playerNum, x, y)
    self._list = context
    local cds = O.cds(self.character, part)
    for _, item in ipairs(cds) do
        local opt = context:addOption(item:getDisplayName(), self, ZeD_CarRadio.onPickCD, item)
        opt.itemForTexture = item
    end
    if #cds == 0 then
        local o = context:addOption("No CDs on you")
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
        if h and h.id == p.id then self:press(p.id) end
    end
    return true
end
function ZeD_CarRadio:onMouseUpOutside(x, y) self._press = nil; return true end

function ZeD_CarRadio:onRightMouseDown(x, y)
    local h = self:hitAt(x, y)
    if h then self:secondary(h.id) end
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
        self:turn(h.id, del > 0 and -1 or 1, mult)
    end
    return true
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
    if p and not p.fired and holdable(p.id) and now() - p.t0 >= O.HOLD_MS then
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
    self:turn(self.focusId, dir, mult)
end

function ZeD_CarRadio:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then self:close()
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
function ZeD_CarRadio:onJoypadDirLeft() self:moveFocus(-1, 0) end
function ZeD_CarRadio:onJoypadDirRight() self:moveFocus(1, 0) end
function ZeD_CarRadio:onJoypadDirUp() if self:isKnobFocused() then self:dirTurn(1) else self:moveFocus(0, -1) end end
function ZeD_CarRadio:onJoypadDirDown() if self:isKnobFocused() then self:dirTurn(-1) else self:moveFocus(0, 1) end end

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
    prop.focusId = O.HAM[st.kind] and "chup" or (st.kind == "makeshift" and "p1" or "vol")
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
