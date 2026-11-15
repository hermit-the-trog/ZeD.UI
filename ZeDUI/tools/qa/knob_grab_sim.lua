-- ZeDUI/tools/qa/knob_grab_sim.lua  (Nov 14 2026, punch list 228k / l, the design lead's "A grabs, D-pad turns"): the
-- controller on a knob, with no game running. The real FocusManager.lua runs on Lua 5.1 stubs; the help line's prompts
-- (Organisms.lua), the car radio's and the two-way full view's controller code (ZeD_CarRadio.lua, TwoWayFull.lua) and
-- the object card's stops (ObjectCards.lua) are cut from their files and run on stubs too.
--   MOVE     a knob is a stop like any other: the D-pad moves onto it and off it and never turns it
--   GRAB     A grabs it; then Right / Up turn it up and Left / Down down, the focus staying; a held D-pad repeats
--   LETGO    A or B lets go; B on a grabbed knob never closes the card (its own B still does when not grabbed);
--            landing on it again starts let go; a knob that cannot turn now lets go and the D-pad moves on
--   PUSH     a knob that also pushes (a radio's power) pushes on X
--   PROMPTS  on a knob: A Grab; grabbed: D-pad Turn, A / B Let go (and no A or B of their own)
--   CAR      the car radio and the two-way full view (their own controller code): the same, face and plain card
--   LOCK     a padlock's number wheel (a card zone with knob): the same through the card's stops
--   STATION  ("Yes, all knobs") the Craft tab's oven / microwave knobs (StationAppliance's stops: B not grabbed still
--            leaves the station), the oven's own window (StationPopout: it keeps the pad, 209) and the siren controller
--   WIRED    the radio tab's faces, plain card and two-way face all make their knobs this way; no knob turns on a
--            bare D-pad any more
-- Run from the repo root: lua51 ZeDUI/tools/qa/knob_grab_sim.lua
-- It prints FAIL lines and a last line "knob_grab_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]knob_grab_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function noop() end
local function slurp(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end
-- the text from `head` to the end of the first line-start `stop` after it ("\nend\n" by default)
local function cut(src, head, stop)
    local a = src and src:find(head, 1, true)
    if not a then return nil end
    stop = stop or "\nend\n"
    local _, b = src:find(stop, a, true)
    return b and src:sub(a, b) or nil
end

-- ---------------------------------------------------------------------------
-- STUBS
-- ---------------------------------------------------------------------------
local now = 100000
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = noop, Remove = noop }
    rawset(t, k, e)
    return e
end })
LuaEventManager = { AddEvent = noop }
triggerEvent = noop
require = noop
getTimestampMs = function() return now end
isDebugEnabled = function() return false end
getText = function(k) return k end
local realPrint = print
print = function(s) if type(s) == "string" and s:sub(1, 5) == "[ZeD." then return end realPrint(s) end

local JD = { id = 0, player = 0, focus = nil }
JoypadState = { players = { JD }, joypads = {}, controllers = {} }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5 }
local DOWN = {}
JoypadButton = setmetatable({}, { __index = function(_, name) return { isDown = function() return DOWN[name] == true end } end })
getJoypadData = function(pn) return pn == 0 and JD or nil end
getJoypadFocus = function(pn) local jd = JoypadState.players[pn + 1]; return jd and jd.focus or nil end
setJoypadFocus = function(pn, f) local jd = JoypadState.players[pn + 1]; if jd then jd.focus = f end end
setJoypadIgnoreAimUntilCentered = noop
isControllerConnected = function() return true end
getControllerCount = function() return 1 end
getControllerAxisValue = function() return 0 end
getCell = function() return { getDrag = function() return nil end } end
local PLAYER = { getPlayerNum = function() return 0 end, isDead = function() return false end }
getSpecificPlayer = function() return PLAYER end

ZeD = { Input = {} }
ZeD.tr = function(k, a) return a ~= nil and (k .. ":" .. tostring(a)) or k end
ZeD.uiSound = noop
ZeD.Input.Detector = { getMode = function() return "gamepad" end }
ZeD.Input.Action = { fromGamepadButton = function(b)
    if b == Joypad.AButton then return { "confirm" } end
    if b == Joypad.XButton then return { "context_menu" } end
    if b == Joypad.BButton then return { "cancel" } end
    return nil
end }

local okN, errN = pcall(dofile, Z .. "Input/SpatialNav.lua")   -- (the D-pad's picker)
check("SpatialNav.lua loads", okN, errN)
local okF, errF = pcall(dofile, Z .. "Input/FocusManager.lua")
check("FocusManager.lua loads", okF, errF)
local Focus = ZeD.Input.Focus
check("WIRED: Focus.knobStop is there", type(Focus.knobStop) == "function")

-- the help line's prompts, cut from Organisms.lua
local promptsFor
do
    local src = slurp(Z .. "Organisms.lua") or ""
    local parts = { cut(src, "local PROMPT_LABELS = {", "\n}\n"), cut(src, "local function _pv(v, win, el)"),
                    cut(src, "local function _promptsFor(el, win)") }
    local body = ""
    for i = 1, 3 do
        check("WIRED: the help line's piece " .. i .. " is found", parts[i] ~= nil)
        body = body .. (parts[i] or "")
    end
    local fn, e = loadstring(body .. "\nreturn _promptsFor\n", "prompts")
    check("the help line's prompts compile", fn ~= nil, e)
    if fn then promptsFor = fn() end
end
local function promptText(el, win)
    local out = {}
    for _, p in ipairs(promptsFor and promptsFor(el, win) or {}) do out[#out + 1] = p.glyph .. "=" .. tostring(p.label) end
    return table.concat(out, ",")
end

-- ---------------------------------------------------------------------------
-- A WINDOW WITH A KNOB ABOVE A KEY
-- ---------------------------------------------------------------------------
local log = {}
local function logged(kind) local n = 0; for _, e in ipairs(log) do if e == kind then n = n + 1 end end return n end
local win = { _zedLabel = "World", playerNum = 0, windowShaded = false }
function win:isVisible() return true end
function win:isReallyVisible() return true end
local turns = {}
local function knobEl(push)
    local el = { id = "radio:tw:vol", x = 0, y = 0, w = 20, h = 20,
                 onFocus = function() log[#log + 1] = "focus" end,
                 onCancel = function() log[#log + 1] = "close" end, promptB = "UI_ZeD_ObjCard_CloseCard" }
    local opts = {}
    if push then opts.press = function() log[#log + 1] = "power" end; opts.pressWord = "IGUI_RadioPower" end
    opts.canTurn = function() return not win.busy end
    return Focus.knobStop(el, function(w, e, d) turns[#turns + 1] = d end, opts)
end
local function keyEl()
    return { id = "radio:tw:p1", x = 0, y = 60, w = 20, h = 20, onActivate = function() log[#log + 1] = "press" end }
end
local function build(push)
    win._focusRing = { { zone = "worldTabContent", focusable = true, elements = { knobEl(push), keyEl() }, focusedElementIdx = 1 } }
    win._focusIdx = 1
end
build(true)
Focus.registerWindow(win)
Focus.claimFocus(win)
local function tick(ms) now = now + (ms or 16); Focus.tick() end
local function focused() local e = Focus.getFocusedElement(win); return e and e.id end
local BTN = { [Joypad.AButton] = "A", [Joypad.XButton] = "X", [Joypad.BButton] = "B" }
local function tap(b)
    Focus.qaButton(BTN[b], true); Focus.dispatchJoypadDown(win, b, { player = 0 }); tick()
    Focus.qaButton(BTN[b], false); tick(); Focus.qaButton(BTN[b], nil)
end
local function dir(d) Focus.dispatchJoypadDir(win, d, { player = 0, id = 0 }); tick() end
local function knob() return win._focusRing[1].elements[1] end

-- MOVE
check("MOVE: the pad starts on the knob", focused() == "radio:tw:vol", focused())
turns = {}
dir("down")
check("MOVE: Down on a knob not grabbed moves on to the key below", focused() == "radio:tw:p1", focused())
check("MOVE: ... and turns nothing", #turns == 0)
dir("up")
check("MOVE: Up comes back onto the knob", focused() == "radio:tw:vol", focused())
check("PROMPTS: on a knob, A says Grab (and its push is on X, B is the card's own)",
    promptText(knob(), win) == "A=UI_ZeD_Prompt_KnobGrab,X=IGUI_RadioPower,B=UI_ZeD_ObjCard_CloseCard,Y=UI_ZeD_Prompt_Windows",
    promptText(knob(), win))

-- GRAB
tap(Joypad.AButton)
check("GRAB: A grabs the knob", win._knobGrab == "radio:tw:vol", win._knobGrab)
check("GRAB: ... Focus.knobGrabbed says so (the face draws it held)", Focus.knobGrabbed(win, "radio:tw:vol"))
check("PROMPTS: grabbed: D-pad Turn, A / B Let go, and no A or B of their own",
    promptText(knob(), win) == "X=IGUI_RadioPower,D-PAD=UI_ZeD_Looks_PromptTurn,A B=UI_ZeD_Prompt_KnobLetGo,Y=UI_ZeD_Prompt_Windows",
    promptText(knob(), win))
turns = {}
dir("right"); dir("up"); dir("left"); dir("down")
check("GRAB: Right and Up turn it up, Left and Down down", table.concat(turns, ",") == "1,1,-1,-1", table.concat(turns, ","))
check("GRAB: ... and the focus stays on the knob", focused() == "radio:tw:vol", focused())
-- a held D-pad repeats (the D-pad's own hold-to-repeat)
turns = {}
Focus.dispatchJoypadDir(win, "up", { player = 0, id = 0 })
DOWN.DPadUp = true
for _ = 1, 40 do tick(16) end
DOWN.DPadUp = false
tick()
check("GRAB: a held Up keeps turning it (the D-pad's repeat)", #turns >= 3, #turns)
check("GRAB: ... every one of them up", (function() for _, d in ipairs(turns) do if d ~= 1 then return false end end return true end)())

-- LETGO
log = {}
tap(Joypad.BButton)
check("LETGO: B lets go", win._knobGrab == nil)
check("LETGO: ... and never closes the card", logged("close") == 0)
tap(Joypad.BButton)
check("LETGO: B on a knob not grabbed is the card's own B (it closes)", logged("close") == 1)
tap(Joypad.AButton); tap(Joypad.AButton)
check("LETGO: A again lets go", win._knobGrab == nil)
tap(Joypad.AButton)
build(true)    -- (the tab builds its stops again each frame; the grab stays with the window)
check("LETGO: the grab outlives the stops being built again", Focus.knobGrabbed(win, "radio:tw:vol"))
-- (Nov 15 2026, punch list 228k: a landing announced again on the knob held keeps it held; a move off and back lets go)
win._knobGrab = "radio:tw:vol"
Focus.focusWhere(win, "worldTabContent", function(e) return e.id == "radio:tw:vol" end)
check("LETGO: the same landing announced again keeps the grab", win._knobGrab == "radio:tw:vol", win._knobGrab)
Focus.focusWhere(win, "worldTabContent", function(e) return e.id == "radio:tw:p1" end)
Focus.focusWhere(win, "worldTabContent", function(e) return e.id == "radio:tw:vol" end)
check("LETGO: landing on the knob again starts let go", win._knobGrab == nil)
tap(Joypad.AButton)
win.busy = true
turns = {}
dir("down")
check("LETGO: a knob that cannot turn now lets go", win._knobGrab == nil and #turns == 0)
check("LETGO: ... and the D-pad moves on", focused() == "radio:tw:p1", focused())
win.busy = false
dir("up")

-- PUSH
log = {}
tap(Joypad.XButton)
check("PUSH: X pushes a knob that pushes (power)", logged("power") == 1)
check("PUSH: ... and grabs nothing", win._knobGrab == nil)
build(false)
check("PUSH: a knob that only turns has no X", promptText(knob(), win):find("X=", 1, true) == nil, promptText(knob(), win))

-- ---------------------------------------------------------------------------
-- CAR: the car radio's and the two-way full view's own controller code
-- ---------------------------------------------------------------------------
local function prop(kind, plain)
    local self = { kind = kind, _plain = plain, focusId = "vol", _grab = false, log = {} }
    self._hits = { { id = "vol", c = { knob = true } }, { id = "p1", c = { knob = false } } }
    return self
end
local CR_HEADS = { "local function hasPwrButton(kind)", "function ZeD_CarRadio:onJoypadDown(button, joypadData)",
    "function ZeD_CarRadio:isKnobFocused()", "function ZeD_CarRadio:knobGrabbed()", "function ZeD_CarRadio:pushKnob()",
    "local function dirPad(self, dx, dy, d)", "function ZeD_CarRadio:onJoypadDirLeft()", "function ZeD_CarRadio:onJoypadDirRight()",
    "function ZeD_CarRadio:onJoypadDirUp()", "function ZeD_CarRadio:onJoypadDirDown()" }
do
    local src = slurp(Z .. "ZeD_CarRadio.lua") or ""
    local body = ""
    for i, h in ipairs(CR_HEADS) do
        local piece = cut(src, h, "\n")
        if piece and not piece:find("\nend\n", 1, true) and not piece:match("end\n$") then piece = cut(src, h) end
        check("WIRED: the car radio's piece " .. i .. " is found", piece ~= nil, h)
        body = body .. (piece or "")
    end
    ZeD_CarRadio = {}
    local fn, e = loadstring("local function sound() end\n" .. body, "car radio")
    check("CAR: the car radio's controller code compiles", fn ~= nil, e)
    if fn then
        fn()
        local function car(kind, plain)
            local o = setmetatable(prop(kind, plain), { __index = ZeD_CarRadio })
            function o:focused() for _, h in ipairs(self._hits) do if h.id == self.focusId then return h end end end
            function o:moveFocus(dx, dy) self.log[#self.log + 1] = "move"; self.focusId = (dy > 0) and "p1" or "vol"; self._grab = false end
            function o:dirTurn(d) self.log[#self.log + 1] = "turn" .. d end
            function o:press(id) self.log[#self.log + 1] = "press:" .. id end
            function o:close() self.log[#self.log + 1] = "close" end
            function o:plainJoypad(b) self.log[#self.log + 1] = "plain" end
            function o:secondary(id) self.log[#self.log + 1] = "secondary:" .. id end
            return o
        end
        for _, plain in ipairs({ false, true }) do
            local tag = plain and "CAR (plain card): " or "CAR (face): "
            local c = car("standard", plain)
            c:onJoypadDirDown()
            check(tag .. "Down on a knob not grabbed moves on", c.log[1] == "move" and c.focusId == "p1")
            c:onJoypadDirUp()
            c.log = {}
            c:onJoypadDown(Joypad.AButton)
            check(tag .. "A grabs the knob", c:knobGrabbed())
            c:onJoypadDirRight(); c:onJoypadDirUp(); c:onJoypadDirLeft(); c:onJoypadDirDown()
            check(tag .. "grabbed: Right / Up turn up, Left / Down down", table.concat(c.log, ",") == "turn1,turn1,turn-1,turn-1",
                table.concat(c.log, ","))
            c.log = {}
            c:onJoypadDown(Joypad.BButton)
            check(tag .. "B lets go and never closes", not c:knobGrabbed() and #c.log == 0)
            c:onJoypadDown(Joypad.BButton)
            check(tag .. "B not grabbed puts it away", c.log[1] == "close")
        end
        local c = car("standard", false)
        c:onJoypadDown(Joypad.XButton)
        check("CAR: X on the volume knob pushes it (power)", c.log[1] == "press:vol", c.log[1])
        c = car("makeshift", false)
        c:onJoypadDown(Joypad.XButton)
        check("CAR: ... not on a makeshift set's (its power is a button)", c.log[1] == nil, c.log[1])
        c.focusId = "p1"
        c:onJoypadDown(Joypad.AButton)
        check("CAR: A on a key still presses it", c.log[#c.log] ~= nil and c._grab ~= true)
    end
end

do
    local src = slurp(Z .. "TwoWayFull.lua") or ""
    local heads = { "function ZeD_TwoWayFull:onJoypadDown(button, joypadData)", "function ZeD_TwoWayFull:isKnobFocused()",
        "function ZeD_TwoWayFull:knobGrabbed()", "local function dirPad(self, dx, dy, d)" }
    local body = ""
    for i, h in ipairs(heads) do
        local piece = cut(src, h)
        if i == 2 or i == 3 then piece = cut(src, h, "\n") end
        check("WIRED: the two-way full view's piece " .. i .. " is found", piece ~= nil, h)
        body = body .. (piece or "")
    end
    for _, d in ipairs({ "Left", "Right", "Up", "Down" }) do
        local piece = cut(src, "function ZeD_TwoWayFull:onJoypadDir" .. d .. "()", "\n")
        check("WIRED: the two-way full view's " .. d, piece ~= nil)
        body = body .. (piece or "")
    end
    ZeD_TwoWayFull = {}
    local TWlog = {}
    local fn, e = loadstring("local TW = ...\nlocal function sound() end\n" .. body, "two-way full")
    check("CAR: the two-way full view's controller code compiles", fn ~= nil, e)
    if fn then
        fn({ press = function(_, _, id) TWlog[#TWlog + 1] = "press:" .. id end, labelX = function() return nil end,
             secondary = noop })
        local o = setmetatable({ focusId = "vol", _grab = false, log = {} }, { __index = ZeD_TwoWayFull })
        o._hits = { { id = "vol", knob = true }, { id = "mem", knob = false } }
        function o:focused() for _, h in ipairs(self._hits) do if h.id == self.focusId then return h end end end
        function o:moveFocus() self.log[#self.log + 1] = "move" end
        function o:dirTurn(d) self.log[#self.log + 1] = "turn" .. d end
        function o:close() self.log[#self.log + 1] = "close" end
        o:onJoypadDirUp()
        check("CAR (two-way full view): Up on a knob not grabbed moves", o.log[1] == "move")
        o.log = {}
        o:onJoypadDown(Joypad.AButton)
        o:onJoypadDirUp(); o:onJoypadDirLeft()
        check("CAR (two-way full view): A grabs, then the D-pad turns", table.concat(o.log, ",") == "turn1,turn-1", table.concat(o.log, ","))
        check("CAR (two-way full view): A on the knob no longer pushes it", #TWlog == 0)
        o:onJoypadDown(Joypad.XButton)
        check("CAR (two-way full view): X pushes the volume knob (power)", TWlog[1] == "press:vol")
        o.log = {}
        o:onJoypadDown(Joypad.BButton)
        check("CAR (two-way full view): B lets go, the view stays", not o:knobGrabbed() and #o.log == 0)
    end
end

-- ---------------------------------------------------------------------------
-- LOCK: a padlock's number wheel through the object card's stops
-- ---------------------------------------------------------------------------
do
    local src = slurp(Z .. "ObjectCards.lua") or ""
    local piece = cut(src, "function ZeD_ObjectCard:buildFocusables(win)")
    check("WIRED: the object card's stops are found", piece ~= nil)
    ZeD_ObjectCard = {}
    local fn, e = loadstring(piece or "", "card stops")
    check("LOCK: the object card's stops compile", fn ~= nil, e)
    if fn then
        fn()
        local spun, busy, ran, closed = {}, false, 0, 0
        local card = setmetatable({ entry = {}, _off = 0, _zones = {
            { fid = "lk:wheel:1", x = 0, y = 0, w = 10, h = 30, body = true, run = function() ran = ran + 1 end,
              knob = function(d) spun[#spun + 1] = d end, canTurn = function() return not busy end },
            { fid = "lk:verb", x = 0, y = 50, w = 40, h = 10, run = function() ran = ran + 10 end } } },
            { __index = ZeD_ObjectCard })
        function card:close() closed = closed + 1 end
        local els = card:buildFocusables(win)
        local wheel = els[1]
        check("LOCK: the wheel is a knob stop", wheel and wheel.isKnob == true)
        local cw = { }
        check("LOCK: not grabbed, the D-pad moves on", wheel.onDpadDir(cw, wheel, "up") == false and #spun == 0)
        wheel.onActivate(cw, wheel)
        check("LOCK: A grabs the wheel (the card keeps the grab, for its drawing)", card._knobGrab == "lk:wheel:1")
        check("LOCK: ... and presses no LOCK", ran == 0)
        wheel.onDpadDir(cw, wheel, "up"); wheel.onDpadDir(cw, wheel, "left")
        check("LOCK: grabbed, Up turns it up and Left down", table.concat(spun, ",") == "1,-1", table.concat(spun, ","))
        wheel.onCancel(cw, wheel)
        check("LOCK: B lets go and leaves the card open", card._knobGrab == nil and closed == 0)
        wheel.onCancel(cw, wheel)
        check("LOCK: B not grabbed closes the card, as before", closed == 1)
        wheel.onActivate(cw, wheel)
        busy = true
        check("LOCK: while the lock is busy it lets go and the D-pad moves on", wheel.onDpadDir(cw, wheel, "down") == false and card._knobGrab == nil)
        check("LOCK: the card's other stops are untouched", els[2] and els[2].isKnob == nil)
    end
    local lock = slurp(Z .. "ObjectCardLock.lua") or ""
    check("WIRED: the lock's wheel is a knob zone, not a bare D-pad", lock:find("knob = function(d) turn(t, ii, d) end", 1, true) ~= nil
        and lock:find('if dir == "up" then turn(t, ii, 1)', 1, true) == nil)
end

-- WIRED: the radio tab's three builders
do
    local rt = slurp(Z .. "RadioTab.lua") or ""
    local _, n = rt:gsub("_knob%(el, %u", "")   -- (the calls: R, D, TW; not the helper's own drv)
    check("WIRED: the radio tab's face, plain card and two-way face make their knobs with _knob", n == 3, n)
    check("WIRED: no knob in the radio tab turns on a bare D-pad", rt:find('if dir ~= "up" and dir ~= "down" then return false end', 1, true) == nil
        and rt:find('if dir ~= "left" and dir ~= "right" then return false end', 1, true) == nil)
    check("WIRED: the radio tab tells the face which knob is grabbed", rt:find("grabId = (fid and win._knobGrab == fid) and fctl or nil", 1, true) ~= nil)
    for _, f in ipairs({ "RtvFace.lua", "TwoWayFace.lua" }) do
        local s = slurp(Z .. f) or ""
        check("WIRED: " .. f .. " draws a grabbed knob held", s:find("face.grabId == c.id", 1, true) ~= nil and s:find("PL.grabCue", 1, true) ~= nil)
    end
    check("WIRED: the plain card draws a grabbed stepper pressed", (slurp(Z .. "PlainFace.lua") or ""):find("local held = face.grabId ~= nil and face.grabId == c.id", 1, true) ~= nil)
end


-- ---------------------------------------------------------------------------
-- STATION: the Craft tab's appliance stops, the pop-out window, the siren controller
-- ---------------------------------------------------------------------------
do
    local src = slurp(Z .. "StationAppliance.lua") or ""
    local piece = cut(src, "function SA.buildFocusables(win, state, st)")
    check("WIRED: the appliance's stops are found", piece ~= nil)
    local acts, left = {}, 0
    local ST = {
        selectFocusable = function() return nil end,
        dropdownFocusables = function() return {} end,
        addLeaveCancel = function(out)
            for _, el in ipairs(out) do
                if not el.onCancel then el.onCancel = function() left = left + 1 end; el.promptB = "UI_ZeD_Station_Leave" end
            end
        end }
    local act = function(p, st, z, d) acts[#acts + 1] = z.id .. ":" .. tostring(d) end
    local fn, e = loadstring("local SA, ST, act = ...\n" .. (piece or ""), "appliance stops")
    check("STATION: the appliance's stops compile", fn ~= nil, e)
    if fn then
        local SA = {}
        fn(SA, ST, act)
        local w = { _playerObj = PLAYER }
        local state = { zones = {
            { type = "plate", fid = "craft:a:heat", id = "heat", kind = "turn", x = 0, y = 0, w = 10, h = 10 },
            { type = "plate", fid = "craft:a:start", id = "start", kind = "press", x = 0, y = 20, w = 10, h = 10 } } }
        local els = SA.buildFocusables(w, state, {})
        local knob, key = els[1], els[2]
        check("STATION: the oven's knob is a knob stop, its key is not", knob.isKnob == true and key.isKnob == nil)
        check("STATION: not grabbed, the D-pad moves on", knob.onDpadDir(w, knob, "right") == false and #acts == 0)
        knob.onActivate(w, knob)
        check("STATION: A grabs the knob (no turn on the press)", w._knobGrab == "craft:a:heat" and #acts == 0)
        knob.onDpadDir(w, knob, "up"); knob.onDpadDir(w, knob, "left")
        check("STATION: grabbed, Up turns it up and Left down", table.concat(acts, ",") == "heat:1,heat:-1", table.concat(acts, ","))
        knob.onCancel(w, knob)
        check("STATION: B lets go and stays at the station", w._knobGrab == nil and left == 0)
        knob.onCancel(w, knob)
        check("STATION: B not grabbed leaves the station, as before", left == 1)
        acts = {}
        key.onActivate(w, key)
        check("STATION: A on a key still presses it", acts[1] == "start:1")
    end

    -- the pop-out window
    local ps = slurp(Z .. "StationPopout.lua") or ""
    local heads = { "function ZeD_StationPopout:focusedZone()", "function ZeD_StationPopout:knobGrabbed()",
        "function ZeD_StationPopout:dirPad(dir, d)", "function ZeD_StationPopout:onJoypadDown(button, joypadData)",
        "function ZeD_StationPopout:getFooterPrompts()" }
    local body = ""
    for i, h in ipairs(heads) do
        local pc = cut(ps, h)
        check("WIRED: the pop-out's piece " .. i .. " is found", pc ~= nil, h)
        body = body .. (pc or "")
    end
    for _, d in ipairs({ "Up", "Down", "Left", "Right" }) do
        local pc = cut(ps, "function ZeD_StationPopout:onJoypadDir" .. d .. "()", "\n")
        check("WIRED: the pop-out's " .. d, pc ~= nil)
        body = body .. (pc or "")
    end
    ZeD_StationPopout = {}
    local pacts = {}
    local fn2, e2 = loadstring("local SA = ...\n" .. body, "pop-out")
    check("STATION: the pop-out's controller code compiles", fn2 ~= nil, e2)
    if fn2 then
        fn2({ act = function(p, st, z, d) pacts[#pacts + 1] = z.id .. ":" .. tostring(d) end })
        local o = setmetatable({ fi = 1, _grab = false, joyfocus = true, log = {} }, { __index = ZeD_StationPopout })
        local zs = { { id = "heat", kind = "turn", fid = "craft:a:heat" }, { id = "start", kind = "press", fid = "craft:a:start" } }
        function o:controls() return zs end
        function o:moveDir(dir) self.log[#self.log + 1] = "move:" .. dir end
        function o:close() self.log[#self.log + 1] = "close" end
        o:onJoypadDirRight()
        check("STATION (pop-out): Right on a knob not grabbed moves (209's walk), turns nothing", o.log[1] == "move:right" and #pacts == 0)
        local function labels(ps2) local t = {}; for _, p in ipairs(ps2 or {}) do t[#t + 1] = p.glyph .. "=" .. p.label end; return table.concat(t, ",") end
        check("STATION (pop-out): on a knob the line says A Grab", labels(o:getFooterPrompts()) == "A=UI_ZeD_Prompt_KnobGrab,B=UI_ZeD_Close", labels(o:getFooterPrompts()))
        o.log = {}
        o:onJoypadDown(Joypad.AButton)
        o:onJoypadDirUp(); o:onJoypadDirLeft(); o:onJoypadDirRight(); o:onJoypadDirDown()
        check("STATION (pop-out): A grabs, then Up / Right up and Left / Down down", table.concat(pacts, ",") == "heat:1,heat:-1,heat:1,heat:-1"
            and #o.log == 0, table.concat(pacts, ","))
        check("STATION (pop-out): grabbed, the line says D-pad Turn, A / B Let go",
            labels(o:getFooterPrompts()) == "D-PAD=UI_ZeD_Looks_PromptTurn,A B=UI_ZeD_Prompt_KnobLetGo", labels(o:getFooterPrompts()))
        o:onJoypadDown(Joypad.BButton)
        check("STATION (pop-out): B lets go, the window stays", not o:knobGrabbed() and #o.log == 0)
        o:onJoypadDown(Joypad.BButton)
        check("STATION (pop-out): B not grabbed closes it", o.log[1] == "close")
        pacts = {}
        o.fi = 2
        o:onJoypadDown(Joypad.AButton)
        check("STATION (pop-out): A on a key still presses it", pacts[1] == "start:1" and not o:knobGrabbed())
    end
    check("WIRED: the appliance's face draws a grabbed knob held", src:find("PL.grabCue(cv, c, T.accent, 0.30)", 1, true) ~= nil
        and src:find('x.grab == "craft:a:" .. id', 1, true) ~= nil)

    -- the siren controller
    local ss = slurp(Z .. "ZeD_SirenController.lua") or ""
    local sh = { "function ZeD_SirenController:padItems()", "function ZeD_SirenController:onJoypadDown(button, joypadData)",
        "local function moveTo(self, i)" }
    local sbody = ""
    for i, h in ipairs(sh) do
        local pc = cut(ss, h)
        check("WIRED: the siren's piece " .. i .. " is found", pc ~= nil, h)
        sbody = sbody .. (pc or "")
    end
    for _, d in ipairs({ "Left", "Right", "Up", "Down" }) do
        local pc = cut(ss, "function ZeD_SirenController:onJoypadDir" .. d .. "()", "\n")
        check("WIRED: the siren's " .. d, pc ~= nil)
        sbody = sbody .. (pc or "")
    end
    ZeD_SirenController = {}
    local fn3, e3 = loadstring('local GROUPS = { "lights", "siren" }\nlocal function sound() end\nlocal function gid(self) return GROUPS[self.focus] end\n' .. sbody, "siren")
    check("STATION (siren): the controller code compiles", fn3 ~= nil, e3)
    if fn3 then
        fn3()
        local o = setmetatable({ focus = 1, _grab = false, log = {} }, { __index = ZeD_SirenController })
        function o:step(g, d) self.log[#self.log + 1] = g .. ":" .. d end
        function o:close() self.log[#self.log + 1] = "close" end
        o:onJoypadDirUp()
        check("STATION (siren): Up on a knob not grabbed turns nothing", #o.log == 0)
        o:onJoypadDirRight()
        check("STATION (siren): Right moves to the siren's knob", o.focus == 2 and #o.log == 0)
        o:onJoypadDown(Joypad.AButton)
        o:onJoypadDirUp(); o:onJoypadDirRight(); o:onJoypadDirLeft(); o:onJoypadDirDown()
        check("STATION (siren): A grabs, then Up / Right up and Left / Down down, the focus staying",
            table.concat(o.log, ",") == "siren:1,siren:1,siren:-1,siren:-1" and o.focus == 2, table.concat(o.log, ","))
        o.log = {}
        o:onJoypadDown(Joypad.BButton)
        check("STATION (siren): B lets go, the controller stays up", o._grab == false and #o.log == 0)
        o:onJoypadDown(Joypad.XButton)
        check("STATION (siren): X steps it (the old A)", o.log[1] == "siren:0")
        o:onJoypadDown(Joypad.BButton)
        check("STATION (siren): B not grabbed puts it away", o.log[2] == "close")
        local items = o:padItems()
        check("STATION (siren): the strip says Switch, A Grab, X Step, B Put away",
            items[2].glyph == "A" and items[2].label == "UI_ZeD_Prompt_KnobGrab" and items[3].glyph == "X")
    end
end

print("knob_grab_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
