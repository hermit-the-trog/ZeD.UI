-- ZeDUI/tools/qa/pad_tips_sim.lua  (Nov 14 2026, punch list 230): the pad's balloons, with no game running. The real
-- Input/FocusManager.lua and Atoms.lua run on Lua 5.1 stubs; the balloon (ZeD.Balloon.draw) is a recorder.
--   REST     Focus.restedMs / padRested: 400 ms on one stop; moving on, or coming back after a while, starts again;
--            a stop list rebuilt with new tables (same id, slot or place) keeps its wait; none while the mouse is in use
--   RECT     Focus.elementRect: the stop's bounds, or its tipRect
--   AUTO     the overlay pass gives the focused stop its own balloon: its tip (words, a card, a function), else the
--            help words its surface stamped for the pad (padHelp); only after the rest, beside the stop; a hint
--            layer's pass (noAuto) gives none; a surface's own request wins
--   REQUEST  a surface's pad request (opts.now / opts.pad) waits the rest, not the mouse's pause, and never shows at
--            once; the mouse's request still waits HINT_DELAY_MS; a HUD panel outside FocusManager waits on its key
--   LAYER    a hint layer's stamp with now = true (the tab strips) waits the rest
-- Run from the repo root:  lua51 ZeDUI/tools/qa/pad_tips_sim.lua
-- It prints FAIL lines and a last line "pad_tips_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]pad_tips_sim%.lua$", "")
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

-- the engine, as little of it as the two files touch here
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
getSoundManager = function() return { playUISound = noop } end
isDebugEnabled = function() return false end
getSpecificPlayer = function() return nil end
getJoypadData = function() return nil end
getMaxActivePlayers = function() return 4 end
getMouseX = function() return 0 end
getMouseY = function() return 0 end
getCore = function() return nil end
JoypadState = { players = {}, joypads = {}, controllers = {} }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5 }
local realPrint = print
print = function(s) if type(s) == "string" and s:sub(1, 5) == "[ZeD." then return end realPrint(s) end

-- ISPanel, just enough for Atoms.lua's load (ZeD_Tooltip derives from it) and newHintLayer
local function newPanel(x, y, w, h)
    local p = { x = x or 0, y = y or 0, w = w or 0, h = h or 0, javaObject = { setConsumeMouseEvents = noop } }
    function p:initialise() end
    function p:instantiate() end
    function p:getAbsoluteX() return self.x end
    function p:getAbsoluteY() return self.y end
    function p:getWidth() return self.w end
    function p:getHeight() return self.h end
    function p:setWidth(v) self.w = v end
    function p:setHeight(v) self.h = v end
    return p
end
ISPanel = { new = function(self, x, y, w, h) return newPanel(x, y, w, h) end }
function ISPanel:derive(name) local c = setmetatable({ Type = name }, { __index = self }); return c end
ISUIElement = ISPanel

ZeD = { Input = {} }
ZeD.Input.Detector = { getMode = function() return "gamepad" end }
ZeD.Input.Action = { fromGamepadButton = function() return nil end }

local okF, errF = pcall(dofile, Z .. "Input/FocusManager.lua")
check("FocusManager.lua loads", okF, errF)
local Focus = ZeD.Input.Focus
local okA, errA = pcall(dofile, Z .. "Atoms.lua")
check("Atoms.lua loads", okA, errA)
local A = ZeD.Atoms

-- the balloon: a recorder (one balloon at a time is Balloon.lua's business, not this sim's)
local drawn = {}
ZeD.Balloon = {
    draw = function(p, c, a, pref, opts)
        drawn[#drawn + 1] = { panel = p, c = c, x = a.x, y = a.y, w = a.w, h = a.h, pref = pref, key = opts and opts.key }
        return 0, 0, 10, 10
    end,
    warm = function() return true end,   -- (a balloon was just up: the mouse's next shows at once, the pad's never)
    redrawHeld = function() return false end,
}
ZeD.Molecules = { cardContent = function(card) return { kind = "rich", title = card.title, lines = card.lines } end }
A.windowOf = function(p) return p._win or p end
A.isAncestor = function(win, p) return p == win or p._win == win end

-- a window at (100, 50) with one zone of three stops (no zone panel: its stops are window-local)
local win = newPanel(100, 50, 400, 300)
win._zedLabel, win.playerNum = "Sim", 0
function win:isVisible() return true end
local function stops()
    return {
        { id = "trait:a", x = 10, y = 20, w = 80, h = 16, tip = "Brave: fears less" },
        { id = "trait:b", x = 10, y = 40, w = 80, h = 16 },
        { slotType = "doll:hat", x = 10, y = 60, w = 30, h = 30, tip = function(w, el) return { title = "Hat", lines = { "Worn" } } end },
    }
end
local zone = { zone = "simZone", focusable = true, elements = stops(), focusedElementIdx = 1 }
win._focusRing = { zone }
win._focusIdx = 1
Focus.claimFocus(win)
local s0 = Focus._st[0]
s0.cues = true

local function step(ms) now = now + (ms or 16) end
local function focusOn(i) zone.focusedElementIdx = i end
-- one frame of the window's overlay pass (the drawn list holds what it drew)
local function overlay(noAuto)
    drawn = {}
    A.drawPendingHover(win, win, noAuto)
    return drawn[1]
end
-- ms of frames (16 ms each, as the game draws them), each running fn; the last frame's result
local function frames(ms, fn)
    local out
    for _ = 1, math.floor(ms / 16) do step(16); out = fn() end
    return out
end

-- REST
check("REST: the window holds the pad", Focus.getFocusedWindow(0) == win)
check("REST: a stop just landed on has rested 0 ms", Focus.restedMs(win) == 0, Focus.restedMs(win))
step(200); check("REST: 200 ms on", Focus.restedMs(win) == 200, Focus.restedMs(win))
check("REST: ... not rested yet", not Focus.padRested(win))
step(150); Focus.restedMs(win); step(50)
check("REST: 400 ms on, rested", Focus.padRested(win))
check("REST: ... on that stop's id", Focus.padRested(win, "trait:a"))
check("REST: ... not on another id", not Focus.padRested(win, "trait:b"))
focusOn(2)
check("REST: a move to the next stop starts the wait again", Focus.restedMs(win) == 0, Focus.restedMs(win))
for _ = 1, 30 do step(16); Focus.restedMs(win) end
zone.elements = stops()   -- (the tab rebuilt its stops: new tables, the same ids)
check("REST: a rebuilt stop list keeps the wait", Focus.padRested(win), Focus.restedMs(win))
focusOn(3)
Focus.restedMs(win)
for _ = 1, 30 do step(16); Focus.restedMs(win) end
zone.elements = stops()
check("REST: a stop with no id keeps its wait by its slot", Focus.padRested(win), Focus.restedMs(win))
step(300)
check("REST: a stop nobody asked about for 300 ms starts again (the pad came back)", Focus.restedMs(win) == 0,
    Focus.restedMs(win))
s0.cues = false
check("REST: no wait while the mouse is in use", Focus.restedMs(win) == nil and not Focus.padRested(win))
s0.cues = true
local other = newPanel(0, 0, 10, 10); other.playerNum = 0; other._focusRing = { zone }; other._focusIdx = 1
check("REST: a window without the pad has no wait", Focus.restedMs(other) == nil)

-- RECT
focusOn(1)
local r = Focus.elementRect(win)
check("RECT: the stop's own bounds, window-local", r and r.x == 10 and r.y == 20 and r.w == 80 and r.h == 16,
    r and (r.x .. "," .. r.y .. "," .. r.w .. "," .. r.h))
zone.elements[1].tipRect = { x = 5, y = 6, w = 7, h = 8 }
r = Focus.elementRect(win)
check("RECT: the stop's tipRect when it names one", r and r.x == 5 and r.h == 8)
zone.elements[1].tipRect = nil

-- AUTO
zone.elements = stops(); focusOn(1)
step(300)   -- (a fresh wait)
check("AUTO: nothing at once", overlay() == nil)
step(200)
check("AUTO: nothing at 200 ms", overlay() == nil)
step(220)
local d = overlay()
check("AUTO: the stop's tip after the rest", d and d.c and d.c.title == "Brave: fears less", d and d.c and d.c.title)
check("AUTO: ... beside the stop (its screen rectangle)", d and d.x == 110 and d.y == 70 and d.w == 80 and d.h == 16,
    d and (d.x .. "," .. d.y))
check("AUTO: ... keyed by the stop", d and d.key == "pad:trait:a", d and d.key)
check("AUTO: a hint layer's pass gives no balloon of its own", overlay(true) == nil)
focusOn(3)
d = frames(416, overlay)
check("AUTO: a tip function's card", d and d.c and d.c.kind == "rich" and d.c.title == "Hat", d and d.c and d.c.title)
focusOn(2)
check("AUTO: a stop with no tip and no help words: nothing", frames(416, overlay) == nil)
d = frames(32, function()
    A.padHelp(win, "Pin Strength to the belt", { x = 12, y = 40, w = 60, h = 16 }, "right")
    return overlay()
end)
check("AUTO: the help words its surface stamped for the pad", d and d.c and d.c.title == "Pin Strength to the belt",
    d and d.c and d.c.title)
check("AUTO: ... pointing where the surface said", d and d.x == 112 and d.y == 90 and d.pref == "right")
step(200)
check("AUTO: help words not stamped again are gone", overlay() == nil)
focusOn(1)
local own = { title = "Own card" }
d = frames(416, function()
    A.requestDetailCard(win, "trait:a", own, win, { x = 1, y = 2, w = 3, h = 4 }, { side = "right", pad = true })
    return overlay()
end)
check("AUTO: the surface's own request wins over the stop's tip", d and d.c and d.c.title == "Own card",
    d and d.c and d.c.title)
s0.cues = false
step(400)
check("AUTO: no pad balloon while the mouse is in use", overlay() == nil)
s0.cues = true

-- REQUEST
local function ask(key, opts) A.requestHint(win, key, "Words", win, { x = 0, y = 0, w = 5, h = 5 }, opts) end
focusOn(2)
step(300)
ask("btn", { now = true })
check("REQUEST: the pad's request never shows at once (no warm hand-on either)", overlay() == nil)
check("REQUEST: ... nor at 384 ms", frames(384, function() ask("btn", { now = true }); return overlay() end) == nil)
check("REQUEST: ... and shows once the pad has rested", frames(32, function() ask("btn", { now = true }); return overlay() end) ~= nil)
s0.cues = false
step(200); overlay()
ask("mouse"); ZeD.Balloon.warm = function() return false end
check("REQUEST: the mouse's request waits its pause", overlay() == nil)
step(420); ask("mouse")
check("REQUEST: ... still waiting at 420 ms", overlay() == nil)
step(40); ask("mouse")
check("REQUEST: ... and shows at HINT_DELAY_MS", overlay() ~= nil)
-- a HUD panel outside FocusManager (the belt): its pad request waits on its key
local belt = newPanel(0, 600, 300, 40)
local function beltAsk(key) A.requestHint(belt, key, "Main hand", belt, { x = 0, y = 0, w = 5, h = 5 }, { now = true }) end
local function beltPass() drawn = {}; A.drawPendingHover(belt, belt); return drawn[1] end
step(300); beltAsk("hand"); beltPass()
step(300); beltAsk("hand")
check("REQUEST: a HUD panel's pad request waits", beltPass() == nil)
step(120); beltAsk("hand")
check("REQUEST: ... and shows after 400 ms on its key", beltPass() ~= nil)
beltAsk("slot1")
check("REQUEST: ... a new key waits again", beltPass() == nil)
s0.cues = true

-- LAYER
local layer = A.newHintLayer(win, "_simCand")
local function stamp() win._simCand = { key = "tab:loot", text = "Loot", x = 0, y = 0, w = 30, h = 20, side = "r", now = true } end
local function layerPass() drawn = {}; layer.render(layer); return drawn[1] end
focusOn(1)
step(300)
stamp(); check("LAYER: a focused tab's name never shows at once", layerPass() == nil)
d = frames(416, function() stamp(); overlay(); return layerPass() end)
check("LAYER: ... and shows once the pad has rested", d and d.c and d.c.title == "Loot", d and d.c and d.c.title)

print("pad_tips_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
