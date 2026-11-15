-- ZeDUI/tools/qa/face_popouts_sim.lua  (Nov 15 2026, pop-outs, Build): Design's handoff part 1, faces as pop-outs, with
-- no game running. It loads the real ZeD/TwoWayFull.lua (the one pop-out) and ZeD/FacePop.lua (which face, and the ways
-- in) over a fake panel, fake drivers, a fake player and fake machines, and reads the routes' sources.
--   STRIP    the controller strip: A and the control's name, then B Close; a knob A Grab (X Power on a knob that
--            pushes); a grabbed knob the up / down picture and its name, A / B Let go; the two-way sets keep theirs
--   HELP     the mouse strip: the control's help, else its name, else "Click a control.  Esc closes."
--   REACH    a machine in the world: 3 tiles, or the distance it opened from, tightening; gone, another floor: shut
--   PLACE    the first place beside the player on the side with more room, clear of player and machine
--   PAD      X pushes the knob the driver names; A on a key presses it with where its list opens
--   ONE      opening another face replaces the one open; showingObj finds a driver's target by its machine
--   CARD     an object card's face: its zones become controls, a press runs the zone, the primary control first
--   ON       faces off (Simple) or safe mode: nothing pops out
--   CLICK    a world click: not while aiming, within 3 tiles; the radio route the game's click sets off is taken
--   PROMPT   A at a machine: its name, Close when it shows; takes the oven's Turn on, never a door's prompt
--   WIRED    the ways in: Device Options, Stove settings, Turn on, Generator info, the cards' buttons and faces
-- Run from the repo root:  lua51 ZeDUI/tools/qa/face_popouts_sim.lua
-- It prints FAIL lines and a last line "face_popouts_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]face_popouts_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function readFile(p)
    local f = assert(io.open(p, "rb"))
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r", ""))
end

-- ---------------------------------------------------------------------------
-- THE GAME, FAKED
-- ---------------------------------------------------------------------------
local CLASSES = {
    Tv = { IsoWaveSignal = true, IsoObject = true },
    Stove = { IsoStove = true, IsoObject = true },
    Gen = { IsoGenerator = true, IsoObject = true },
    Item = { InventoryItem = true },
    Plain = { IsoObject = true },
}
-- (machines are userdata in the game; here tables with _cls, so FacePop's "a Lua table is not a world object" rule is
-- lifted for them below)
function instanceof(o, cls)
    local c = type(o) == "table" and o._cls and CLASSES[o._cls]
    return c ~= nil and c[cls] == true
end
local nowMs = 100000
function getTimestampMs() return nowMs end
function getText(k) return "[" .. k .. "]" end
function require() end
Keyboard = { KEY_ESCAPE = 1 }
Joypad = { AButton = 0, BButton = 1, XButton = 2 }
JoypadState = { players = {} }
local padFocus = {}
function setJoypadFocus(pn, v) padFocus[pn] = v end
local SW, SH = 1000, 600
function getCore() return { getScreenWidth = function() return SW end, getScreenHeight = function() return SH end,
    getZoom = function() return 1 end } end
function getPlayerScreenLeft() return 0 end
function getPlayerScreenTop() return 0 end
function getPlayerScreenWidth() return SW end
function getPlayerScreenHeight() return SH end
-- one tile is 10 screen px across, the world's x is the screen's x
function isoToScreenX(pn, x, y, z) return x * 10 end
function isoToScreenY(pn, x, y, z) return y * 10 end
local mouse = { x = 0, y = 0 }
function getMouseX() return mouse.x end
function getMouseY() return mouse.y end
UIManager = { getSpeedControls = function() return { getCurrentGameSpeed = function() return 1 end } end }
Events = { OnGameBoot = { Add = function() end }, OnGameStart = { Add = function() end } }

ISPanel = {}
ISPanel.__index = ISPanel
function ISPanel:derive(name) local c = {}; setmetatable(c, { __index = ISPanel }); c.Type = name; return c end
function ISPanel:new(x, y, w, h) return { x = x, y = y, width = w, height = h, visible = false } end
function ISPanel:initialise() end
function ISPanel:instantiate() end
function ISPanel:update() end
function ISPanel:setVisible(v) self.visible = v end
function ISPanel:isReallyVisible() return self.visible end
function ISPanel:addToUIManager() end
function ISPanel:removeFromUIManager() end
function ISPanel:setAlwaysOnTop() end
function ISPanel:setWantKeyEvents() end
function ISPanel:setWidth(w) self.width = w end
function ISPanel:setHeight(h) self.height = h end
function ISPanel:setX(x) self.x = x end
function ISPanel:setY(y) self.y = y end
function ISPanel:getX() return self.x end
function ISPanel:getY() return self.y end
function ISPanel:getAbsoluteX() return self.x end
function ISPanel:getAbsoluteY() return self.y end
function ISPanel:getMouseX() return mouse.x - self.x end
function ISPanel:getMouseY() return mouse.y - self.y end
function ISPanel:setCapture() end
function ISPanel:drawTextureScaled() end
function ISPanel:drawRect() end

local strips = {}
ZeD = {
    tr = function(k) return "<" .. k .. ">" end,
    T = { hair = 1, scale = 1, px = function(n) return n end, sp = { scrollbarW = 13 } },
    Px = { k = function() return 2 end, kFit = function(s, w, room) return 2 end,
           pick = function(pid, room) return { w = 100, h = 50, plate = pid }, pid .. "@full" end },
    PhysPx = { plates = {}, fallback = { propane = "grill_propane" } },
    PadGlyphs = { stripH = function() return 20 end, drawStrip = function(p, x, y, w, items) strips[#strips + 1] = items end },
    Focus = { drawOverlay = function() end },
    Input = { Focus = { knobPrompts = function() return { { glyph = "D-PAD", label = "turn" } } end, claimFocus = function() end } },
    logOnce = function(l, e) print("LOG " .. tostring(l) .. " " .. tostring(e)) end,
    Settings = { devicesSimple = function() return ZeD._simple == true end },
    Safe = { on = function() return ZeD._safe == true end },
    ObjectCards = { CARD_W = 480 },
}
-- the two-way driver as TwoWayFace.lua's (only what the view asks of it)
local function hitAt(hits, x, y)
    for _, h in ipairs(hits or {}) do if x >= h.x and x < h.x + h.w and y >= h.y and y < h.y + h.h then return h end end
    return nil
end
ZeD.TwoWay = {
    hitAt = hitAt,
    readingOrder = function(hits) local o = {}; for i, h in ipairs(hits) do o[i] = h end; return o end,
    nearest = function() return nil end,
    plateTex = function() return nil end,
    labelA = function(id) if id == "tune" then return nil end; return "tw:" .. tostring(id) end,
    labelX = function() return nil end,
    plateId = function(dev) return dev and dev._tw and "walkie" or nil end,
    inReach = function() return true end,
    holdTick = function() end, holdable = function() return false end, press = function() end,
}
ZeD.PhysPx.plates.walkie = { w = 60, h = 120, plate = "walkie" }

local function load(path)
    local fn, err = loadfile(path)
    check("LOAD " .. path, fn ~= nil, err)
    if fn then fn() end
end
load(Z .. "TwoWayFull.lua")
local F = ZeD.TwoWayFull

-- a fake face driver: two keys (power, mute) and a knob (vol, pushes for power); the log of what it was asked
local log = {}
local function fakeDriver(extra)
    local D = {
        popFace = function(dev, k) return "fake", { w = 100, h = 50, plate = "fake" }, k end,
        drawFace = function(panel, x, y, k, face)
            return { { id = "mute", x = 60, y = 0, w = 10, h = 10 }, { id = "power", x = 0, y = 0, w = 10, h = 10 },
                     { id = "vol", x = 30, y = 0, w = 10, h = 10, knob = true } }, nil
        end,
        focusOrder = function(hits) local o = {}; for _, h in ipairs(hits) do if h.id == "power" then table.insert(o, 1, h) else o[#o + 1] = h end end; return o end,
        hitAt = hitAt,
        press = function(chr, dev, id, dx, at) log[#log + 1] = "press:" .. id .. (at and ":at" or "") end,
        secondary = function(chr, dev, id) log[#log + 1] = "second:" .. id end,
        turn = function(chr, dev, id, d) log[#log + 1] = "turn:" .. id .. ":" .. d end,
        holdable = function() return false end, holdTick = function() end, turnMult = function() return 1 end,
        labelA = function(id) return "name:" .. tostring(id) end,
        knobPush = function(id) return id == "vol" end,
        help = function(dev, id, h) if id == "mute" then return "help:mute" end; return nil end,
        inReach = function() return true end,
    }
    for k, v in pairs(extra or {}) do D[k] = v end
    return D
end

local player = { x = 10, y = 10, z = 0, md = {} }
function player:getPlayerNum() return 0 end
function player:getModData() return self.md end
function player:getX() return self.x end
function player:getY() return self.y end
function player:getZ() return self.z end
function player:getVehicle() return nil end
function player:isDead() return false end
function player:isAiming() return self.aiming == true end
function getSpecificPlayer() return player end

local function machine(cls, x, y, z)
    local m = { _cls = cls, x = x, y = y, z = z or 0, idx = 3, sq = {} }
    function m:getX() return self.x end
    function m:getY() return self.y end
    function m:getZ() return self.z end
    function m:getSquare() return self.idx >= 0 and self.sq or nil end
    function m:getObjectIndex() return self.idx end
    function m.sq:isSeen() return true end
    return m
end

-- ---------------------------------------------------------------------------
-- STRIP, HELP
-- ---------------------------------------------------------------------------
do
    local D = fakeDriver()
    local dev = { obj = nil }
    JoypadState.players[1] = {}
    local v = F.open(player, dev, nil, D)
    check("ONE the pop-out opens with a driver", v ~= nil and v.drv == D and padFocus[0] == v)
    JoypadState.players[1].focus = v
    v:update()
    v:prerender()
    check("STRIP focus lands on the main control (the driver's order)", v.focusId == "power", v.focusId)
    local s = strips[#strips]
    check("STRIP A and the control's name, then B Close", s and s[1].glyph == "A" and s[1].label == "name:power"
        and s[#s].glyph == "B" and s[#s].label == "<UI_ZeD_Close>", s and s[1] and s[1].label)
    check("STRIP no D-pad item on a machine's strip (the design's)", s and s[1].glyph ~= "D-PAD")
    v.focusId = "vol"
    v:prerender()
    s = strips[#strips]
    check("STRIP a knob: A Grab, X Power where it pushes", s[1].label == "<UI_ZeD_Prompt_KnobGrab>" and s[2].glyph == "X", s[1].label)
    v:onJoypadDown(Joypad.AButton)
    v:prerender()
    s = strips[#strips]
    check("STRIP a grabbed knob: the up / down picture and its name, A / B Let go",
        s[1].pad and s[1].pad[1] == "DU" and s[1].pad[2] == "DD" and s[1].label == "name:vol" and s[2].glyph == "A B")
    v:onJoypadDirUp()
    check("PAD a grabbed knob turns with the D-pad", log[#log] == "turn:vol:1", log[#log])
    v:onJoypadDown(Joypad.BButton)
    check("PAD B lets the knob go, the pop-out stays", v.visible and not v:knobGrabbed())
    v:onJoypadDown(Joypad.XButton)
    check("PAD X pushes the knob the driver names", log[#log] == "press:vol", log[#log])
    v.focusId = "mute"
    v:onJoypadDown(Joypad.AButton)
    check("PAD A on a key presses it, its list under it", log[#log] == "press:mute:at", log[#log])
    -- the mouse
    JoypadState.players[1].focus = nil
    mouse.x, mouse.y = v.x + 62, v.y + 2
    v:update()
    v:prerender()
    s = strips[#strips]
    check("HELP the control's help line under the pointer", s[1] == "help:mute", s[1])
    mouse.x, mouse.y = v.x + 2, v.y + 2
    v:update(); v:prerender()
    check("HELP no help: the control's name", strips[#strips][1] == "name:power", strips[#strips][1])
    mouse.x, mouse.y = v.x + 90, v.y + 40
    v:update(); v:prerender()
    check("HELP off the controls: how to use it", strips[#strips][1] == "<UI_ZeD_FacePop_Hint>", strips[#strips][1])
    check("PLACE the face, 3u, then the strip", v.height == 50 * 2 + 1 + 3 + 20, v.height)
    -- Escape
    check("ESC Escape closes it first", F.takeEscape() == true and not v.visible)
end

-- the two-way sets keep their strip
do
    JoypadState.players[1] = {}
    local dev = { _tw = true }
    local v = F.open(player, dev, nil, nil)
    check("ONE a two-way set opens with its own driver", v and v.drv == ZeD.TwoWay)
    JoypadState.players[1].focus = v
    ZeD.TwoWay.drawFace = function() return { { id = "mem", x = 0, y = 0, w = 5, h = 5 } }, nil end
    v:update(); v:prerender()
    local s = strips[#strips]
    check("STRIP the two-way keeps D-pad Move first", s and s[1].glyph == "D-PAD")
    F.close(0)
end

-- ---------------------------------------------------------------------------
-- REACH, PLACE, ONE
-- ---------------------------------------------------------------------------
do
    local tv = machine("Tv", 12, 10)
    local D = fakeDriver({ objOf = function(dev) return dev.obj end })
    local dev = { obj = tv }
    local v = F.open(player, dev, nil, D)
    check("REACH the machine is kept", v.obj == tv)
    check("REACH 2 tiles: in reach", v:inReach())
    tv.x = 13.0
    check("REACH 3.5 tiles: in reach (3 and the tile's half)", v:inReach())
    tv.x = 14
    check("REACH 4.5 tiles: out of reach", not v:inReach())
    -- opened from 8 tiles: the leash starts there and tightens
    v = F.open(player, dev, nil, D)
    tv.x = 17.5
    check("REACH opened from 8: in reach", v:inReach())
    tv.x = 14.5
    check("REACH walked in to 5", v:inReach())
    tv.x = 17.5
    check("REACH back out to 8: the leash tightened", not v:inReach())
    tv.x = 11
    v = F.open(player, dev, nil, D)
    tv.z = 1
    check("REACH another floor: out of reach", not v:inReach())
    tv.z = 0
    tv.idx = -1
    check("REACH gone from its tile: out of reach", not v:inReach())
    tv.idx = 3
    -- the first place: the player at 100 px on a 1000 px screen, the TV at 115: the right has more room
    player.md.ZeD_TwoWayFull = nil
    v = F.open(player, dev, nil, D)
    v:prerender()
    check("PLACE right of the player and the machine", v.x >= 115 + 64, v.x)
    player.x = 80
    tv.x = 78
    v = F.open(player, dev, nil, D)
    v:prerender()
    check("PLACE left when the left has more room", v.x + v.width <= 785 - 64, v.x)
    -- a drag keeps the place, one for every face
    v._drag = { mx = 0, my = 0, x = v.x, y = v.y, nx = 300, ny = 200 }
    v:prerender()                      -- (the frames of the drag move it)
    v:onMouseUp(0, 0)
    check("PLACE a drag is kept on the character", player.md.ZeD_TwoWayFull and player.md.ZeD_TwoWayFull.x ~= nil)
    local other = { obj = machine("Gen", 79, 80) }
    local v2 = F.open(player, other, nil, D)
    v2:prerender()
    check("ONE another face replaces the first, in the same place", v2 == v and v.dev == other and v.x == 300, v.x)
    check("ONE showingObj finds a target by its machine", F.showingObj(0, other.obj) and not F.showingObj(0, tv))
    F.close(0)
    player.x, player.md.ZeD_TwoWayFull = 10, nil
end

-- ---------------------------------------------------------------------------
-- FACEPOP: the card drivers, the switch, the click, the prompt
-- ---------------------------------------------------------------------------
local OPEN_CALLS = {}
ZeD.Stations = { entryFor = function(p, o) return { obj = o, kind = "oven", key = "k" } end }
ZeD.StationAppliance = { plateFor = function() return { w = 1, h = 1 }, "oven_green" end,
    drawPlate = function(panel, x, y, k, st, des, pid, zones) zones[1] = { fid = "craft:a:heat", kind = "turn", x = 0, y = 0, w = 5, h = 5 }; return zones end,
    act = function(p, st, z, d) OPEN_CALLS[#OPEN_CALLS + 1] = "act:" .. z.fid .. ":" .. d end,
    controlName = function(id) return "sa:" .. tostring(id) end }
local laundryT = nil
ZeD.ObjectCardLaundry = {
    plateId = function(o) return o._laundry and "washer" or nil end,
    def = { resolve = function(p, o) laundryT = { obj = o, pid = "washer" }; return laundryT end,
            valid = function(t) return t.obj.idx >= 0 end, refresh = function(t) t.d = { n = 1 } end },
    face = function(card, px0, y, k, des, t)
        card:zone({ fid = "ldy:door", x = 0, y = 0, w = 5, h = 5, run = function(cc, p) OPEN_CALLS[#OPEN_CALLS + 1] = "door" end })
        card:zone({ fid = "ldy:power", x = 10, y = 0, w = 5, h = 5, primary = true, help = "h:power",
            run = function(cc, p) OPEN_CALLS[#OPEN_CALLS + 1] = "power:" .. tostring(p == player) end })
    end,
}
ZeD.ObjectCardPower = { def = { resolve = function() return nil end } }
ZeD.ObjectCardFire = { def = { resolve = function() return nil end } }
ZeD.Rtv = { plateId = function(dev) return dev and dev._rtv and "tv_black" or nil end }
ISWorldObjectContextMenu = { getMoveableDisplayName = function(o) return "Machine" end }
ISButtonPrompt = { cmdToggleStove = function() end, testInteractButtonAction = function(self, dir) end,
    setAPrompt = function(self, s, f, a) self.aPrompt, self.aFunc, self.aParams = s, f, { a } end }
ISObjectClickHandler = { doClick = function(o) OPEN_CALLS[#OPEN_CALLS + 1] = "vanilla" end }
do
    local src = readFile(Z .. "FacePop.lua")
    -- (the game's machines are userdata: here they are tables, so the "a Lua table is no world object" guard steps aside)
    src = src:gsub('type%(o%) == "table"', 'false'):gsub('type%(obj%) == "table"', 'false')
    local fn, err = loadstring(src, "FacePop.lua")
    check("LOAD FacePop.lua", fn ~= nil, err)
    if fn then fn() end
end
local FP = ZeD.FacePop

do
    local washer = machine("Plain", 11, 10)
    washer._laundry = true
    check("ON faces on by default", FP.on())
    ZeD._simple = true
    check("ON Simple: nothing pops out", not FP.on() and not FP.open(player, washer))
    ZeD._simple = nil
    ZeD._safe = true
    check("ON safe mode: nothing pops out", not FP.open(player, washer))
    ZeD._safe = nil
    check("CARD the washer pops out", FP.open(player, washer) and F.showingObj(0, washer))
    local v = F.get(0)
    check("CARD the card's data read before the first frame", laundryT.d ~= nil)
    JoypadState.players[1] = { focus = v }
    v:update(); v:prerender()
    check("CARD its zones are the controls", #v._hits == 2 and v._hits[1].id == "ldy:door")
    check("CARD the primary control first (the card's first stop)", v.focusId == "ldy:power", v.focusId)
    v:onJoypadDown(Joypad.AButton)
    check("CARD A runs the zone with the player", OPEN_CALLS[#OPEN_CALLS] == "power:true", OPEN_CALLS[#OPEN_CALLS])
    check("CARD the strip names it", strips[#strips][1].label == "<IGUI_RadioPower>", strips[#strips][1].label)
    check("CARD the zones are gone after the draw (the view is no card)", v._zones == nil)
    check("ONE toggle on the same machine puts it away", FP.toggle(player, washer) and not F.showing(0))
    washer.idx = -1
    FP.open(player, washer)
    v = F.get(0)
    v:prerender()
    check("CARD a machine gone closes it", not v.visible)
    washer.idx = 3
    -- an oven: the Craft tab's plate
    local oven = machine("Stove", 11, 11)
    check("CARD an oven pops out over its plate", FP.open(player, oven) and F.get(0).drv == FP.appliance)
    v = F.get(0)
    v:prerender()
    check("CARD the oven's knob is a knob", v._hits[1] and v._hits[1].knob == true)
    v.focusId = "craft:a:heat"
    v:onJoypadDown(Joypad.AButton)
    v:onJoypadDirRight()
    check("CARD the oven's knob turns through SA.act", OPEN_CALLS[#OPEN_CALLS] == "act:craft:a:heat:1", OPEN_CALLS[#OPEN_CALLS])
    F.close(0)

    -- CLICK
    OPEN_CALLS = {}
    ISObjectClickHandler.doClick(washer)
    check("CLICK a click pops the washer out, then the game's own click runs", F.showingObj(0, washer) and OPEN_CALLS[1] == "vanilla")
    ISObjectClickHandler.doClick(washer)
    check("CLICK the same machine again puts it away", not F.showing(0))
    player.aiming = true
    ISObjectClickHandler.doClick(washer)
    check("CLICK not while aiming", not F.showing(0))
    player.aiming = nil
    washer.x = 15
    ISObjectClickHandler.doClick(washer)
    check("CLICK not past 3 tiles", not F.showing(0))
    washer.x = 11
    local plain = machine("Plain", 11, 10)
    ISObjectClickHandler.doClick(plain)
    check("CLICK a thing with no face: nothing", not F.showing(0))
    -- the radio route the game's click sets off
    local tv = machine("Tv", 11, 10)
    tv._rtv = true
    FP._click.obj, FP._click.at = tv, nowMs
    check("CLICK the game's radio route after the click is taken, nothing more", FP.takeRadio(player, tv) == true and not F.showing(0))
    nowMs = nowMs + 1000

    -- PROMPT
    local sq2 = { objs = { washer } }
    local sq1 = { objs = {} }
    function sq1:getAdjacentSquare() return sq2 end
    function sq1:isSomethingTo() return false end
    local function objs(sq) return { size = function() return #sq.objs end, get = function(_, i) return sq.objs[i + 1] end } end
    function sq1:getObjects() return objs(sq1) end
    function sq2:getObjects() return objs(sq2) end
    function player:getCurrentSquare() return sq1 end
    local bp = { player = 0 }
    setmetatable(bp, { __index = ISButtonPrompt })
    bp:testInteractButtonAction("N")
    check("PROMPT A at the washer names it", bp.aPrompt == "Machine" and bp.aFunc == ISButtonPrompt.zedFacePop)
    bp:aFunc(bp.aParams[1])
    check("PROMPT A opens it", F.showingObj(0, washer))
    bp.aPrompt = nil
    bp:testInteractButtonAction("N")
    check("PROMPT A while it shows: Close", bp.aPrompt == "<UI_ZeD_Close>", bp.aPrompt)
    F.close(0)
    bp.aPrompt, bp.aFunc = "[ContextMenu_Turn_On]", ISButtonPrompt.cmdToggleStove
    bp:testInteractButtonAction("N")
    check("PROMPT it takes the oven's Turn on", bp.aFunc == ISButtonPrompt.zedFacePop)
    bp.aPrompt, bp.aFunc = "[ContextMenu_Open_door]", nil
    bp:testInteractButtonAction("N")
    check("PROMPT never a door's prompt", bp.aPrompt == "[ContextMenu_Open_door]")
    ZeD._simple = true
    bp.aPrompt, bp.aFunc = nil, nil
    bp:testInteractButtonAction("N")
    check("PROMPT faces off: no prompt", bp.aPrompt == nil)
    ZeD._simple = nil
end

-- ---------------------------------------------------------------------------
-- WIRED: the ways in, in the sources
-- ---------------------------------------------------------------------------
do
    local wr = readFile(Z .. "WorldRoutes.lua")
    check("WIRED Device Options on a set in the world asks the pop-out first", wr:find("FPm.takeRadio(chr, dev)", 1, true) ~= nil)
    local st = readFile(Z .. "Overrides/Stations.lua")
    local _, n = st:gsub("ZeD.FacePop.open%(", "")
    check("WIRED Stove settings and Turn on ask the pop-out first", n >= 2, n)
    local ic = readFile(Z .. "Overrides/InfoCards.lua")
    check("WIRED Generator info and the grill's info ask the pop-out first", ic:find("ZeD.FacePop.open, player, obj", 1, true) ~= nil)
    local rt = readFile(Z .. "RadioTab.lua")
    check("WIRED every radio face has the button (not the plain card)", rt:find("local canPop = twDes ~= nil and not fDrv.plain", 1, true) ~= nil)
    check("WIRED a click on the face toggles it", rt:find("if canPop and _hitZone(tw.face, x, y) then ZeD.TwoWayFull.toggle", 1, true) ~= nil)
    local sa = readFile(Z .. "StationAppliance.lua")
    check("WIRED the oven's button pops the face out with faces on", sa:find('z.type == "popout" and not devicesSimple() and ZeD.FacePop', 1, true) ~= nil)
    check("WIRED a click on the oven's plate away from its controls", sa:find("pr and hit(pr, x, y) and not devicesSimple()", 1, true) ~= nil)
    local oc = readFile(Z .. "ObjectCards.lua")
    check("WIRED the cards' header button", oc:find('fid = "oc:pop"', 1, true) ~= nil)
    for _, f in ipairs({ "ObjectCardLaundry.lua", "ObjectCardPower.lua", "ObjectCardFire.lua" }) do
        local s = readFile(Z .. f)
        check("WIRED " .. f .. ": the face zone and the button", s:find("OC.faceZone(card", 1, true) ~= nil and s:find("function def.popOut", 1, true) ~= nil)
    end
end

print("face_popouts_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
