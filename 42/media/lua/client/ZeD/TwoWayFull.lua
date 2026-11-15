-- ZeD-UI/42/media/lua/client/ZeD/TwoWayFull.lua
-- ============================================================================
-- A MACHINE'S FACE AS A POP-OUT (client; organism — an ISPanel subclass) — a
-- face on its own over the world, no window frame, like the watch popped from
-- the belt. Born as the two-way radio's full view (Oct 26); since Nov 15 2026
-- (pop-outs) it is the one pop-out every machine face opens in: the two-way
-- sets, the ordinary radios, the CD player and the TVs, the ovens, microwaves
-- and the fryer, the propane grill, the generators and the laundry.
--
-- One thing to know: the view draws and drives a face through a DRIVER, a table
-- with the two-way faces' interface (TwoWayFace.lua: drawFace, hitAt, press,
-- secondary, turn, holdable, holdTick, turnMult, labelA, labelX, inReach), and
-- `dev`, the thing the driver works on. ZeD.TwoWay and ZeD.Rtv are drivers
-- themselves; FacePop.lua makes drivers for the appliances and the object
-- cards' faces. The view never knows which machine it shows. A driver may add:
--   popFace(dev, k) -> pid, des, k   the plate this machine pops out with (the
--                                    full card's width pick), else the plate
--                                    plateId names at the plate scale
--   focusOrder(hits, k)              where the controller lands first (else
--                                    reading order)
--   objOf(dev)                       the machine in the world: the view then
--                                    keeps the reach itself (below)
--   help(dev, id, hit)               the help line for a control (mouse)
--   onRelease(id)                    keys that act on the release
--   knobPush(id)                     a knob X pushes (power)
--   refresh(dev)                     called each frame before drawing
--
-- What it does: the face at the plate scale, System 7's hard shadow under it
-- (1u right and down, black at 0.5, the face's own shape), then 3u down the
-- strip at the face's width: with the controller the focused control's prompt
-- and B Close (the two-way sets keep their own longer strip); with the mouse the
-- help line for the control under the pointer, else "Click a control.  Esc
-- closes.". Drag it by any part that is not a control; its place is kept per
-- character (modData ZeD_TwoWayFull, design units), one place for every face.
-- The first time it sits beside the player, on the side with more room, clear
-- of the player and the machine.
-- It closes with B or Escape, with the card's button or the machine clicked
-- again, when another face opens (one at a time), and by itself when the
-- machine goes out of reach: a radio dropped or taken, a machine picked up or
-- gone from its tile, or the player walking away (past ISEntityUI's
-- isoPanelWalkToDist, 3 tiles, or the distance it was opened from, which
-- tightens as the player comes closer, as the stations' leash does). It does
-- not tuck away on a timer as the watch does: a machine is used.
-- Controller: it takes focus while open (the left stick still walks). Focus
-- lands on the machine's main control, the D-pad walks the controls, A presses,
-- X stores or names, B closes and gives focus back to the window it was opened
-- from. A knob is grabbed with A, then the D-pad turns it; A or B lets go, and
-- a volume knob's push (power) is X (punch list 228k).
-- The drawing and every verb live in the drivers; this file places the face,
-- passes input to it and closes it.
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
F.REACH = 3                    -- tiles: vanilla's ISEntityUI.isoPanelWalkToDist, the distance a machine's panel stays open at

local function now() return getTimestampMs() end
local function sound(name) pcall(function() ZeD.uiSound(name) end) end
local function zoom() local Sc = ZeD.Scale; return P.k((Sc and Sc.root and Sc.root()) or 1) end
local OWN_FOCUS = { focused = true }   -- the view keeps its own focus: the mark takes the control as focused (pad only)

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
    o._zedLabel = "TwoWayFull"   -- the name the focus manager and safe mode call this panel by
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

-- (Nov 15 2026, pop-outs) the first place, worked out once per opening: beside the player on the side of the play
-- area with more room, its near edge past both the player and the machine (with a tile's width to spare), its middle
-- at the player's chest; screen px. Nil when the player can't be placed on the screen (the caller then uses centre right).
function ZeD_TwoWayFull:besidePlayer(w, h)
    local pn, chr = self.playerNum, self.character
    local ok, px, py = pcall(function()
        return isoToScreenX(pn, chr:getX(), chr:getY(), chr:getZ()), isoToScreenY(pn, chr:getX(), chr:getY(), chr:getZ() + 0.6)
    end)
    if not (ok and px and py) then return nil end
    local lo, hi = px, px
    local obj = self.obj
    if obj then
        local okM, mx = pcall(function() return isoToScreenX(pn, obj:getX() + 0.5, obj:getY() + 0.5, obj:getZ()) end)
        if okM and mx then lo, hi = math.min(lo, mx), math.max(hi, mx) end
    end
    local okZ, z = pcall(function() return getCore():getZoom(pn) end)
    local spare = math.floor(64 / ((okZ and z and z > 0) and z or 1))   -- a tile's width on the screen at this zoom
    lo, hi = lo - spare, hi + spare
    local l, sw = getPlayerScreenLeft(pn), getPlayerScreenWidth(pn)
    local x = ((l + sw) - hi >= lo - l) and hi or (lo - w)
    return x, py - math.floor(h / 2)
end

-- where it sits: where the player dragged it (kept per character, design units), else beside the player (worked out
-- when it opened), else centre right of the play area; always whole on the screen
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
            if not self._home then
                local hx, hy = self:besidePlayer(w, h)
                if hx then self._home = { x = hx, y = hy } end
            end
            if self._home then
                x, y = self._home.x, self._home.y
            else
                local l, t = getPlayerScreenLeft(pn), getPlayerScreenTop(pn)
                local sw, sh = getPlayerScreenWidth(pn), getPlayerScreenHeight(pn)
                x = l + math.floor(sw * 0.75 - w / 2)
                y = t + math.floor((sh - h) / 2) - T.px(60)
            end
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
-- REACH
-- ---------------------------------------------------------------------------
-- (Nov 15 2026, pop-outs) a machine in the world (self.obj, F.open): still on its tile, on the player's floor and
-- within the leash: 3 tiles (ISEntityUI.isoPanelWalkToDist) or, opened from further away (a TV's Device Options
-- across the room), that distance and a tile, tightening as the player comes closer. Anything else (a radio
-- carried) asks the driver.
function ZeD_TwoWayFull:inReach()
    local D = self.drv or TW
    local obj = self.obj
    if not obj then return D.inReach(self.character, self.dev) end
    local ok, gone = pcall(function() return obj:getSquare() == nil or obj:getObjectIndex() < 0 end)
    if not ok or gone then return false end
    local chr = self.character
    local okD, d, floor = pcall(function()
        local dx, dy = obj:getX() + 0.5 - chr:getX(), obj:getY() + 0.5 - chr:getY()
        return math.sqrt(dx * dx + dy * dy), math.floor(obj:getZ()) == math.floor(chr:getZ())
    end)
    if not (okD and d and floor) then return false end
    if chr:getVehicle() or chr:isDead() then return false end
    self._leash = math.max(F.REACH + 0.5, math.min(self._leash or (d + 1), d + 1))
    return d <= self._leash
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
-- the plate this machine pops out with: the driver's pick, else the one plateId names at the plate scale
local function popFace(D, dev, k)
    if D.popFace then return D.popFace(dev, k) end
    local pid = D.plateId(dev)
    return pid, pid and ZeD.PhysPx.plates[pid], k
end

-- the name of a control, for the prompt and the help line
local function nameOf(D, id)
    return (D.labelA and D.labelA(id)) or ZeD.tr("UI_ZeD_RadioPrompt_Press")
end

-- the strip's items: the two-way sets keep the strip they passed QA with (D-pad Move, A, X, B); every other face the
-- design's: the focused control's prompt (A and its name; a grabbed knob the up / down picture and its name, A / B
-- Let go), then B Close
function ZeD_TwoWayFull:padItems()
    local D = self.drv or TW
    local Focus = ZeD.Input.Focus
    if D == TW then
        if self:knobGrabbed() then return Focus.knobPrompts() end   -- (Nov 14 2026, punch list 228k: D-pad Turn, A / B Let go)
        local items = { { glyph = "D-PAD", label = ZeD.tr("UI_ZeD_Map_PadMove") } }
        local la = TW.labelA(self.focusId)
        if self:isKnobFocused() then la = ZeD.tr("UI_ZeD_Prompt_KnobGrab") end
        if la then items[#items + 1] = { glyph = "A", label = la } end
        local lx = TW.labelX(self.focusId)
        if self:isKnobFocused() and self.focusId == "vol" then lx = getText("IGUI_RadioPower") end
        if lx then items[#items + 1] = { glyph = "X", label = lx } end
        items[#items + 1] = { glyph = "B", label = ZeD.tr("UI_ZeD_Close") }
        return items
    end
    local id = self.focusId
    if self:knobGrabbed() then
        return { { pad = { "DU", "DD" }, label = nameOf(D, id) }, { glyph = "A B", label = ZeD.tr("UI_ZeD_Prompt_KnobLetGo") } }
    end
    local items = {}
    if id then
        if self:isKnobFocused() then
            items[1] = { glyph = "A", label = ZeD.tr("UI_ZeD_Prompt_KnobGrab") }
            if D.knobPush and D.knobPush(id) then items[2] = { glyph = "X", label = getText("IGUI_RadioPower") } end
        else
            items[1] = { glyph = "A", label = nameOf(D, id) }
            local lx = D.labelX and D.labelX(id)
            if lx then items[2] = { glyph = "X", label = lx } end
        end
    end
    items[#items + 1] = { glyph = "B", label = ZeD.tr("UI_ZeD_Close") }
    return items
end

-- the mouse's strip: the help line for the control under the pointer, else how to use it
function ZeD_TwoWayFull:mouseLine()
    local D = self.drv or TW
    local id = self._hover
    if id then
        local h = TW.hitAt(self._hits, self:getMouseX(), self:getMouseY())
        local line = D.help and D.help(self.dev, id, h) or nil
        if line then return line end
        if D ~= TW or TW.labelA(id) then return nameOf(D, id) end
    end
    return ZeD.tr("UI_ZeD_FacePop_Hint")
end

function ZeD_TwoWayFull:prerender()
    local T = ZeD.T
    if not T then return end
    local D = self.drv or TW
    self._tick = self._tick + 1
    if self._tick % REACH_EVERY == 1 and not self:inReach() then self:close(); return end
    if D.refresh and not D.refresh(self.dev, self.character) then self:close(); return end
    local pid, des, k = popFace(D, self.dev, zoom())
    if not des then self:close(); return end
    k = k or zoom()
    self.pid, self.des = pid, des
    self._k = k
    local sh = T.hair                                           -- room for the shadow
    local PG = ZeD.PadGlyphs
    local stripH = PG.stripH()
    local gap = T.px(3)                                         -- (the design: 3u between the face and its strip)
    local fw, fh = des.w * k, des.h * k
    local w = fw + sh
    local h = fh + sh + gap + stripH
    self:place(w, h)
    local tex = des.plate and TW.plateTex(des.plate)
    if tex then self:drawTextureScaled(tex, sh, sh, fw, fh, SHADOW_A, 0, 0, 0)
    else self:drawRect(sh, sh, fw, fh, SHADOW_A, 0, 0, 0) end
    local joy = self.joyfocus ~= nil
    self._fid = joy and self.focusId or nil          -- (the object cards' faces ask card._fid and card:focusOf)
    self._hoverFid = (not joy) and self._hover or nil
    local hits, st = D.drawFace(self, 0, 0, k, { dev = self.dev, pid = pid, des = des, focusId = joy and self.focusId or nil,
        hoverId = (not joy) and self._hover or nil, pressId = self._press and self._press.id or nil, own = true,
        grabId = (joy and self:knobGrabbed()) and self.focusId or nil })
    self._hits = hits or {}
    self.st = st
    -- (the controller starts on the machine's main control: power first on a radio or a TV, as the cards)
    if joy and not self:focused() and self._hits[1] then
        local order = D.focusOrder and D.focusOrder(self._hits, k) or TW.readingOrder(self._hits, k)
        if order[1] then self.focusId = order[1].id end
    end
    local sy = fh + sh + gap
    if joy then PG.drawStrip(self, 0, sy, fw, self:padItems())
    else PG.drawStrip(self, 0, sy, fw, { self:mouseLine() }) end
    -- the controller's mark on a key, drawn last so no neighbour covers it
    ZeD.Focus.drawOverlay(self, self)
end

function ZeD_TwoWayFull:update()
    ISPanel.update(self)
    local D = self.drv or TW
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    -- (F.qaJoy: the controller look without a controller, for testing)
    self.joyfocus = (jd and jd.focus == self) and jd or (F.qaJoy and {} or nil)
    local h = TW.hitAt(self._hits, self:getMouseX(), self:getMouseY())
    self._hover = h and h.id or nil
    if self._yieldTo then
        local ok, up = pcall(self._yieldTo)
        if not (ok and up) then self._yieldTo = nil; self:setAlwaysOnTop(true) end
    end
    D.holdTick(self._press, self.character, self.dev, self)
end

function ZeD_TwoWayFull:focused()
    for _, h in ipairs(self._hits or {}) do if h.id == self.focusId then return h end end
    return nil
end

-- (Nov 15 2026, pop-outs) the object cards' faces draw on a card: the view stands in for one while they draw
-- (FacePop.lua's card drivers). A control's stamped zone, and the controller's mark for one.
function ZeD_TwoWayFull:zone(z) local l = self._zones; if l then l[#l + 1] = z end end
function ZeD_TwoWayFull:focusOf(fid)
    if fid and self._fid == fid then return OWN_FOCUS end
    return nil
end

-- where a control's list opens (screen px): under the control
function ZeD_TwoWayFull:menuAt(id)
    for _, h in ipairs(self._hits or {}) do
        if h.id == id then return { x = self:getAbsoluteX() + h.x, y = self:getAbsoluteY() + h.y + h.h } end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- MOUSE: a control is pressed (a knob's left half turns it down); anything else drags the face
-- ---------------------------------------------------------------------------
function ZeD_TwoWayFull:onMouseDown(x, y)
    local D = self.drv or TW
    local h = TW.hitAt(self._hits, x, y)
    if h then
        -- (a key that opens a list, as a held one, acts on the release: RtvFace.onRelease)
        if (D.onRelease or D.holdable)(h.id) then
            self._press = { id = h.id, t0 = now(), fired = false }
        elseif h.knob then
            D.press(self.character, self.dev, h.id, x - (h.x + h.w / 2), self:menuAt(h.id))
        else
            self._press = { id = h.id, t0 = now(), fired = true }     -- shaded while held; it acts on the press
            D.press(self.character, self.dev, h.id, nil, self:menuAt(h.id))
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
        -- a real drag (2 px or more) keeps the new place, in design units (one place for every face)
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
        local D = self.drv or TW
        if h and h.id == p.id then D.press(self.character, self.dev, p.id, nil, self:menuAt(p.id)) end
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
    if h then (self.drv or TW).secondary(self.character, self.dev, h.id, self) end
    return true
end
function ZeD_TwoWayFull:onRightMouseUp(x, y) return true end

-- the wheel turns the knob under the pointer (a fast spin goes further per click:
-- clicks under 110 ms apart build the streak the driver's turnMult reads)
function ZeD_TwoWayFull:onMouseWheel(del)
    local D = self.drv or TW
    local h = TW.hitAt(self._hits, self:getMouseX(), self:getMouseY())
    if h and h.knob then
        local t = now()
        if t - self._wheel.t < 110 then self._wheel.streak = self._wheel.streak + 1 else self._wheel.streak = 0 end
        self._wheel.t = t
        local mult = (h.id == "tune") and D.turnMult(self.pid, self._wheel.streak) or 1
        D.turn(self.character, self.dev, h.id, del > 0 and -1 or 1, mult)
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
    if best then self.focusId = best.id; self._grab = false; sound("UISelectListItem") end
end

-- a grabbed knob turned one click: presses under 260 ms apart build a streak, so a held
-- D-pad spins the tuning knob faster
function ZeD_TwoWayFull:dirTurn(dir)
    local D = self.drv or TW
    local t = now()
    local k = self._padTurn or { t = 0, streak = 0 }
    if t - k.t < 260 then k.streak = k.streak + 1 else k.streak = 0 end
    k.t = t
    self._padTurn = k
    local mult = (self.focusId == "tune") and D.turnMult(self.pid, k.streak) or 1
    D.turn(self.character, self.dev, self.focusId, dir, mult)
end

-- (Nov 14 2026, punch list 228k, the design lead's "A grabs, D-pad turns": A on a knob grabs it, A or B lets go (B on
-- a grabbed knob only lets go, the view stays); a volume knob's push (power) is X: the two-way's "vol", or the
-- knob the driver names (knobPush: the antique TV's "volpwr"))
function ZeD_TwoWayFull:onJoypadDown(button, joypadData)
    local D = self.drv or TW
    if button == Joypad.BButton then
        if self:knobGrabbed() then self._grab = false; sound("UISelectListItem"); return end
        self:close()
    elseif button == Joypad.AButton and self:isKnobFocused() then
        self._grab = not self._grab
        sound("UISelectListItem")
    elseif button == Joypad.AButton then
        local id = self.focusId
        if id then D.press(self.character, self.dev, id, nil, self.menuAt and self:menuAt(id) or nil) end
    elseif button == Joypad.XButton then
        local id = self.focusId or ""
        local push = (D.knobPush and D.knobPush(id)) or ((not D.knobPush) and id == "vol")
        if self:isKnobFocused() and push then D.press(self.character, self.dev, id)
        elseif D.labelX and D.labelX(id) then D.secondary(self.character, self.dev, id, self) end
    end
end
function ZeD_TwoWayFull:isKnobFocused() local f = self:focused(); return (f and f.knob) and true or false end
--- The focused knob is grabbed (A): the D-pad turns it.
function ZeD_TwoWayFull:knobGrabbed() return self._grab == true and self:isKnobFocused() end
-- the D-pad: a grabbed knob turns (Left / Down down, Right / Up up); anything else moves on
local function dirPad(self, dx, dy, d)
    if self:knobGrabbed() then self:dirTurn(d) else self:moveFocus(dx, dy) end
end
function ZeD_TwoWayFull:onJoypadDirLeft() dirPad(self, -1, 0, -1) end
function ZeD_TwoWayFull:onJoypadDirRight() dirPad(self, 1, 0, 1) end
function ZeD_TwoWayFull:onJoypadDirUp() dirPad(self, 0, -1, 1) end
function ZeD_TwoWayFull:onJoypadDirDown() dirPad(self, 0, 1, -1) end

-- ---------------------------------------------------------------------------
-- ENTRY
-- ---------------------------------------------------------------------------
function F.get(pn) return F.views[pn or 0] end

--- The radio's driver: a two-way set's (TwoWayFace.lua), an ordinary radio's, the CD player's or a TV's (RtvFace.lua),
--- nil for a device with no face (a modded one: the plain card has no pop-out).
function F.radioDriver(dev)
    if not dev then return nil end
    if TW.plateId(dev) then return TW end
    local R = ZeD.Rtv
    if R and R.plateId(dev) then return R end
    return nil
end

--- The machine popped out for this player (its dev), nil when none.
function F.showing(pn)
    local v = F.views[pn or 0]
    if v and v:isReallyVisible() then return v.dev end
    return nil
end

--- True when the pop-out shows this machine: dev itself, or a driver's target whose obj is this world object.
function F.showingObj(pn, obj)
    local d = F.showing(pn)
    if d == nil or obj == nil then return false end
    if d == obj then return true end
    return type(d) == "table" and d.obj == obj
end

--- Pop a face out (win: the window whose tab or card opened it, for the controller's way back). drv: the face's
--- driver; nil for a radio (F.radioDriver). Another face open is replaced: one at a time.
function F.open(character, dev, win, drv)
    drv = drv or F.radioDriver(dev)
    if not (character and dev and drv) then return nil end
    local pn = character:getPlayerNum()
    local v = F.views[pn]
    if not v or v.character ~= character then
        if v and v:isReallyVisible() then v:close() end
        v = ZeD_TwoWayFull:new(character)
        v:initialise()
        v:instantiate()
        F.views[pn] = v
    end
    v.dev, v.drv, v.returnWin, v._tick, v.focusId = dev, drv, win, 0, nil
    v._grab, v._leash, v._home, v._press = false, nil, nil, nil
    -- the machine in the world, whose reach the view keeps: the driver's, else a radio set in the world (a two-way
    -- ham set's too); nil for a radio carried
    if drv.objOf then v.obj = drv.objOf(dev)
    else v.obj = (instanceof(dev, "IsoObject") and not instanceof(dev, "InventoryItem")) and dev or nil end
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

--- The tab's button: this face popped out, or put away when it already shows.
function F.toggle(character, dev, win, drv)
    if not character then return end
    local pn = character:getPlayerNum()
    if F.showing(pn) == dev then F.close(pn) else F.open(character, dev, win, drv) end
end

--- Escape from anywhere (the prompts' key hook asks): the pop-out closes.
function F.takeEscape()
    for _, v in pairs(F.views) do
        if v and v:isReallyVisible() then v:close(); return true end
    end
    return false
end
ZeD.EscapeTakers = ZeD.EscapeTakers or {}
ZeD.EscapeTakers.twoWayFull = F.takeEscape

return F
