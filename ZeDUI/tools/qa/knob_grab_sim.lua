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
win._knobGrab = "radio:tw:vol"
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

print("knob_grab_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
