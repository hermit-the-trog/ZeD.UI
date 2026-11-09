-- ZeDUI/tools/qa/guide_bubble_sim.lua (Nov 8 2026, punch list 122): the survival guide as a belt bubble, with no game
-- running. Lua 5.1 stubs of the game; ZeD's REAL ZeD_Messages.lua (the notice and its balloon), ZeD_GuideBubble.lua
-- (the clock) and ZeD_SurvivalGuide.lua (its start-up handler and its device-aware key name, loaded over inert
-- stand-ins for the drawing files it requires).
--   TIMING   the clock starts when player one is playable; nothing before 30 s, a bubble at 30 s; held back while
--            the game is paused or the guide is open; the next one 12 minutes after, again and again inside the
--            first hour, none after the hour; a repeat toasts the line it has and adds no second line
--   STOPS    a click on the bubble opens the guide and ends the offer; a right-click dismisses it and ends the offer;
--            the guide opened by any road ends it; the line cleared from Messages ends it; the line's Open opens
--            the guide
--   ONCE     the first showing writes the flag file; a game that finds it never starts the clock; a game that ended
--            before the bubble showed leaves no flag, so the next one still offers it
--   GATES    server, the tutorial, the game's "Show the guide on startup" off, balloons off in ZeD setup, a split-screen
--            partner (player two), a dead player: no bubble
--   TEXT     the director's wording exactly, in the balloon, with the key following the device: F1 (or the
--            player's own key) on a keyboard, the Help wheel's words on a controller
--   START    the guide does not open when a game starts: ZeD's start handler opens nothing, the game's handler is
--            off the event, a visible game window is closed and its pause given back
--   SOURCE   the Messages window's toast code carries the click, the right-click and the bare long balloon
-- Run from the repo root:  lua51 ZeDUI/tools/qa/guide_bubble_sim.lua
-- It prints FAIL lines and a last line "guide_bubble_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]guide_bubble_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"
next = nil      -- (Kahlua has no next(): a file that calls it fails here as in the game)

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- the game ---------------------------------------------------------------------------------
local CLOCK = 1000000
function getTimestampMs() return CLOCK end
local SERVER, GAMEMODE, OPTION_GUIDE, SPEED, DEAD = false, "Sandbox", true, 1, false
local KEYCODE = 59
local PLAYER0 = { isDead = function() return DEAD end }
local HAVE_P0 = true
function isServer() return SERVER end
function isClient() return false end
function getSpecificPlayer(n) if n == 0 and HAVE_P0 then return PLAYER0 end return nil end
function getPlayer() return getSpecificPlayer(0) end
function getGameSpeed() return SPEED end
local SPEEDS = {}
function setGameSpeed(n) SPEEDS[#SPEEDS + 1] = n; SPEED = n end
function getGameTime() return nil end
function getKeyName(code) if code == 59 then return "F1" elseif code == 60 then return "F2" end return tostring(code) end
KeybindId = { TOGGLE_SURVIVAL_GUIDE = "Toggle Survival Guide" }
function getCore()
    return {
        getGameMode = function() return GAMEMODE end,
        getOptionShowSurvivalGuide = function() return OPTION_GUIDE end,
        getKey = function() return KEYCODE end,
    }
end
JoypadState = { players = {} }
MainScreen = nil

-- Zomboid/Lua files, in memory
local FILES = {}
function getFileReader(name)
    local s = FILES[name]
    if not s then return nil end
    local lines, i = {}, 0
    for l in string.gmatch(s, "([^\n]*)\n") do lines[#lines + 1] = l end
    return { readLine = function() i = i + 1; return lines[i] end, close = function() end }
end
function getFileWriter(name)
    local buf = {}
    return { write = function(_, s) buf[#buf + 1] = s end, close = function() FILES[name] = table.concat(buf) end }
end

local EVENTS = setmetatable({}, { __index = function(t, k)
    local e = { list = {} }
    e.Add = function(fn) e.list[#e.list + 1] = fn end
    e.Remove = function(fn) for i = #e.list, 1, -1 do if e.list[i] == fn then table.remove(e.list, i) end end end
    rawset(t, k, e)
    return e
end })
Events = EVENTS

-- the words: the real English file
local TEXT = {}
do
    local f = assert(io.open(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", "rb"))
    local s = f:read("*a")
    f:close()
    for k, v in s:gmatch('"([%w_]+)": "(.-)",?%s*\r?\n') do TEXT[k] = v end
end
local function fill(s, ...)
    local a = { ... }
    s = s:gsub("\\\"", "\""):gsub("%%(%d)", function(d) return tostring(a[tonumber(d)] or "") end)
    return s
end
function getText(k, ...) return fill(TEXT[k] or k, ...) end

ZeD = {}
ZeD.logOnce = function(k, e) print("FAIL logged: " .. tostring(k) .. ": " .. tostring(e)); failed = failed + 1 end
function ZeD.tr(k, ...) return fill(TEXT[k] or k, ...) end
local TOAST_ON = true
ZeD.Settings = { messagesToastOn = function() return TOAST_ON end, messagesCatchOn = function() return false end }
ZeD.Safe = { on = function() return false end }

function require() end

-- ZeD_Messages.lua, the real one -------------------------------------------------------------
assert(loadfile(CLIENT .. "ZeD_Messages.lua"))()
local MS = ZeD.Messages
check("Messages loads with the notice path", MS and MS.notice and MS.dropToast)

-- ZeD_SurvivalGuide.lua, the real one, over inert stand-ins for the drawing files it requires
local ghost
ghost = setmetatable({}, { __index = function() return ghost end, __call = function() return ghost end })
ZeD.T, ZeD.Atoms, ZeD.Molecules, ZeD.Organisms, ZeD.Px, ZeD.TM, ZeD.PadGlyphs = ghost, ghost, ghost, ghost, ghost, ghost, ghost
ZeD_Panel = ghost
ZeD_Window = ghost
ISPanel = ghost
Translator = { getLanguage = function() return { name = function() return "EN" end } end }
SurvivalGuide = {}
local VANILLA_START = function() end
SurvivalGuide.OnGameStart = VANILLA_START
SurvivalGuide.onKeyPressed = function() end
Events.OnGameStart.Add(VANILLA_START)
Events.OnKeyPressed.Add(SurvivalGuide.onKeyPressed)
local okSG, errSG = pcall(function() assert(loadfile(CLIENT .. "ZeD_SurvivalGuide.lua"))() end)
check("the real ZeD_SurvivalGuide.lua loads over stand-ins", okSG, errSG)
local W = ZeD.Guide
check("the guide has its device-aware key name", W and W.bubbleKey)

-- the guide's opens, counted
local OPENS = 0
local realOpen = W and W.open
if W then
    W.open = function(pn, want)
        OPENS = OPENS + 1
        if ZeD.GuideBubble and ZeD.GuideBubble.done then ZeD.GuideBubble.done("opened") end
    end
end

-- ZeD_GuideBubble.lua, the real one
assert(loadfile(CLIENT .. "ZeD_GuideBubble.lua"))()
local G = ZeD.GuideBubble
check("the bubble driver loads", G and G.tick and G.start)

local EXACT = "New to Knox County? Check out this handy survival guide. Stop alt-tabbing for information: click this bubble or press F1 instead. You can dismiss this bubble at any time."
local SHOW = G.FIRST_MS

local function reset(opts)
    opts = opts or {}
    MS.sources, MS.toasts, MS.seq = {}, {}, 0
    FILES = opts.keepFiles and FILES or {}
    SERVER, GAMEMODE, OPTION_GUIDE, SPEED, DEAD, HAVE_P0, TOAST_ON = false, "Sandbox", true, 1, false, true, true
    JoypadState.players = {}
    OPENS = 0
    CLOCK = 5000000
    G.start()
end
local function lineCount()
    local s = MS.sources[G.head()]
    return s and #s.items or 0
end
local function toastCount() return #MS.toasts end
local function advance(ms) CLOCK = CLOCK + ms; G.tick(CLOCK) end

-- TIMING ---------------------------------------------------------------------------------------
reset()
check("armed on a fresh machine", G.st ~= nil)
G.tick(CLOCK)
check("the clock starts at the first playable tick: nothing yet", toastCount() == 0 and lineCount() == 0)
advance(G.FIRST_MS - 1000)
check("nothing before 30 s", toastCount() == 0)
advance(1000)
check("a bubble at 30 s", toastCount() == 1 and lineCount() == 1, toastCount())
local t1 = MS.toasts[1]
check("it is a bare, long balloon from the belt's note for player one", t1 and t1.bare and t1.long and (t1.pn or 0) == 0)
check("its head is the Survival guide name, its text the director's wording exactly", t1 and t1.head == "Survival guide" and t1.text == EXACT, t1 and t1.text)
check("a click and a right-click are wired", t1 and type(t1.run) == "function" and type(t1.dismiss) == "function")
check("it stays long enough to read", t1 and t1.untilMs - CLOCK >= 15000, t1 and (t1.untilMs - CLOCK))
check("the line is kept unread in Messages", MS.unread() == 1)
check("the flag is written at the first showing", FILES["ZeD_guidebubble.txt"] == "shown=1\n")
-- the balloon runs out; the line stays
CLOCK = CLOCK + 30000
for i = #MS.toasts, 1, -1 do if MS.toasts[i].untilMs <= CLOCK then table.remove(MS.toasts, i) end end
G.tick(CLOCK)
check("after the balloon expires only the line is left, no second bubble yet", toastCount() == 0 and lineCount() == 1)
-- repeats inside the first hour
local shows = 1
local last = CLOCK
for step = 1, 200 do
    advance(30000)
    if toastCount() > 0 then
        shows = shows + 1
        MS.toasts = {}
    end
    if CLOCK - 5000000 >= G.HOUR_MS + 60000 then break end
end
check("it comes back inside the first hour, now and then (5 showings: 0:30, 12:30, 24:30, 36:30, 48:30)", shows == 5, shows)
check("a repeat adds no second line", lineCount() == 1, lineCount())
advance(G.EVERY_MS + 5000)
check("nothing after the first hour", toastCount() == 0 and G.st.done and G.st.why == "hour")

-- held back while paused or while the guide is up
reset()
G.tick(CLOCK)
SPEED = 0
advance(G.FIRST_MS + 1000)
check("held while the game is paused", toastCount() == 0)
SPEED = 1
advance(G.RETRY_MS + 100)
check("and shown at the next try once it runs", toastCount() == 1)
reset()
ZeD.Guide.windows = { [0] = { isReallyVisible = function() return true end } }
G.tick(CLOCK)
advance(G.FIRST_MS + 1000)
check("held while the guide window is open", toastCount() == 0)
ZeD.Guide.windows = {}

-- not playable yet: no clock
reset()
HAVE_P0 = false
advance(G.FIRST_MS * 3)
check("no player one yet: the clock has not started", toastCount() == 0 and G.st.t0 == nil)
HAVE_P0 = true
G.tick(CLOCK)
advance(G.FIRST_MS - 1000)
check("30 s count from the first playable tick, not from the game start", toastCount() == 0)
advance(1000)
check("then it shows", toastCount() == 1)

-- STOPS ----------------------------------------------------------------------------------------
reset()
G.tick(CLOCK); advance(G.FIRST_MS)
local tb = MS.toasts[1]
MS.dropToast(tb); tb.run()
-- (the Messages window's click does dropToast then run; the guide's open ends the offer)
check("a click opens the guide", OPENS == 1)
check("it ends the offer: no bubble comes back", (function() advance(G.EVERY_MS + 1000); return toastCount() == 0 end)())
check("the line stays in Messages", lineCount() == 1)

reset()
G.tick(CLOCK); advance(G.FIRST_MS)
tb = MS.toasts[1]
MS.dropToast(tb); tb.dismiss()
check("a right-click dismisses without opening the guide", OPENS == 0 and G.st.done and G.st.why == "dismissed")
advance(G.EVERY_MS + 1000)
check("a dismissed bubble does not come back", toastCount() == 0)
check("and the line stays in Messages", lineCount() == 1)

reset()
G.tick(CLOCK); advance(G.FIRST_MS)
W.open(0)
check("the guide opened by any road (F1) takes the toast away and ends the offer", toastCount() == 0 and G.st.done and G.st.why == "opened")
advance(G.EVERY_MS + 1000)
check("no bubble comes back after F1", toastCount() == 0)

reset()
G.tick(CLOCK); advance(G.FIRST_MS)
MS.toasts = {}
MS.clear(G.head())
advance(1000)
check("the line cleared from Messages ends the offer", G.st.done and G.st.why == "cleared")
advance(G.EVERY_MS + 1000)
check("and nothing comes back", toastCount() == 0)

reset()
G.tick(CLOCK); advance(G.FIRST_MS)
local it = MS.sources[G.head()].items[1]
check("the line's Open runs the guide", it.k == "notice" and type(it.run) == "function" and (it.run() or true) and OPENS == 1)

-- ONCE -----------------------------------------------------------------------------------------
reset()
G.tick(CLOCK); advance(G.FIRST_MS)
check("first game: shown", toastCount() == 1)
MS.sources, MS.toasts = {}, {}
CLOCK = CLOCK + 5000
G.start()
check("a later game on this machine is not armed", G.st == nil)
advance(G.FIRST_MS * 4)
check("and shows nothing", toastCount() == 0 and lineCount() == 0)
-- a game that ended before the bubble
reset()
G.tick(CLOCK); advance(10000)
check("quit at 10 s: no flag written", FILES["ZeD_guidebubble.txt"] == nil and toastCount() == 0)
G.start()
check("the next game is armed again", G.st ~= nil)
-- a file the machine already holds
reset({ })
FILES["ZeD_guidebubble.txt"] = "shown=1\n"
G.start()
check("a flag from an earlier install is honored", G.st == nil)

-- GATES ----------------------------------------------------------------------------------------
reset(); SERVER = true; G.start()
check("a server never arms it", G.st == nil)
reset(); GAMEMODE = "Tutorial"; G.start()
check("the tutorial never arms it", G.st == nil)
reset(); OPTION_GUIDE = false; G.start()
check("the game's Show the guide on startup, unticked, keeps the bubble away", G.st == nil)
reset(); TOAST_ON = false; G.tick(CLOCK); advance(G.FIRST_MS)
check("balloons off in ZeD setup: no balloon, the offer ends, and the flag is not spent", toastCount() == 0 and G.st.done and FILES["ZeD_guidebubble.txt"] == nil)
reset(); DEAD = true; G.tick(CLOCK); advance(G.FIRST_MS * 2)
check("a dead player one waits (no clock, no bubble)", toastCount() == 0 and G.st.t0 == nil)
reset()
G.tick(CLOCK); advance(G.FIRST_MS)
local t2 = MS.toasts[1]
check("split-screen: the bubble is player one's alone (pn 0)", (t2.pn or 0) == 0)
local before = #MS.toasts
check("player two's toasts list does not get it", (function()
    local n = 0
    for _, t in ipairs(MS.toasts) do if (t.pn or 0) == 1 then n = n + 1 end end
    return n == 0
end)())

-- TEXT -----------------------------------------------------------------------------------------
reset()
check("keyboard: F1 as the guide's key", W.bubbleKey(0) == "F1", W.bubbleKey(0))
KEYCODE = 60
check("a rebound key shows as the player's own", W.bubbleKey(0) == "F2", W.bubbleKey(0))
KEYCODE = 59
JoypadState.players = { { } }
check("controller: the Help wheel words, not F1", W.bubbleKey(0) == TEXT.UI_ZeD_Guide_BubblePad and W.bubbleKey(0) ~= "F1", W.bubbleKey(0))
local padText = G.text(0)
check("the controller bubble swaps only the key", padText == string.gsub(EXACT, "F1", (string.gsub(TEXT.UI_ZeD_Guide_BubblePad, "%%", "%%%%"))), padText)
check("and the controller bubble has no F1", not string.find(padText, "F1", 1, true))
JoypadState.players = {}
check("the keyboard text is the director's wording exactly", G.text(0) == EXACT, G.text(0))

-- START ----------------------------------------------------------------------------------------
local starts = EVENTS.OnGameStart.list
local gameHandlerOn = false
for _, fn in ipairs(starts) do if fn == VANILLA_START then gameHandlerOn = true end end
check("the game's own start handler is off the event", not gameHandlerOn)
local onStart = nil
for _, fn in ipairs(starts) do
    if fn ~= VANILLA_START and fn ~= G.start then onStart = fn end
end
check("ZeD has a start handler left (for the stray window)", onStart ~= nil)
OPENS = 0
local winVisible = false
SurvivalGuide.instance = nil
if onStart then onStart() end
check("ZeD's start handler opens nothing", OPENS == 0)
W.open = realOpen
local realOpened = 0
W.windows = {}
-- a game window left visible: closed, the pause it made given back
local hidden = false
SurvivalGuide.instance = { isVisible = function() return not hidden end, setVisible = function(_, v) hidden = not v end }
SPEED = 0; SPEEDS = {}
if onStart then onStart() end
check("a visible game window at the start is closed and the speed given back", hidden and SPEEDS[#SPEEDS] == 1)
SurvivalGuide.instance = nil
GAMEMODE = "Tutorial"
hidden = false
SurvivalGuide.instance = { isVisible = function() return not hidden end, setVisible = function(_, v) hidden = not v end }
if onStart then onStart() end
check("the tutorial's own guide step is left alone", not hidden)
GAMEMODE = "Sandbox"
SurvivalGuide.instance = nil

-- SOURCE: the window code ----------------------------------------------------------------------
local function slurp(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end
local win = slurp(CLIENT .. "ZeD_MessagesWindow.lua")
check("source: a toast's click runs its run and drops it", string.find(win, "if t and t.run then", 1, true) and string.find(win, "MS.dropToast(t)", 1, true))
check("source: a right-click dismisses a dismissable balloon", string.find(win, "function ZeD_MessagesToasts:onRightMouseDown", 1, true) and string.find(win, "b.toast.dismiss", 1, true))
check("source: the bare long balloon", string.find(win, "t.bare and tostring(t.text or \"\")", 1, true) and string.find(win, "Bb.noticeLines(t.head, body, t.long)", 1, true))
check("source: the Open button on a notice with a run", string.find(win, "it.k == \"notice\" and it.run", 1, true) and string.find(win, "b.noticeRun", 1, true))
local sg = slurp(CLIENT .. "ZeD_SurvivalGuide.lua")
local a0 = string.find(sg, "local function onGameStart", 1, true)
local a1 = string.find(sg, "local function hook", 1, true)
local body = (a0 and a1) and string.sub(sg, a0, a1 - 1) or ""
check("source: ZeD's start handler has no open call in it", #body > 0 and not string.find(body, "open", 1, true) and not string.find(body, "toggle", 1, true), #body)

-- the 28 files carry the wording, none a duplicate
local langs = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
for _, l in ipairs(langs) do
    local s = slurp(ROOT .. "42/media/lua/shared/Translate/" .. l .. "/UI.json")
    for _, k in ipairs({ "UI_ZeD_Guide_Bubble", "UI_ZeD_Guide_BubblePad", "UI_ZeD_Adm_BanProtected" }) do
        local _, n = string.gsub(s, '"' .. k .. '":', "")
        check(l .. " carries " .. k .. " once", n == 1, n)
    end
    local b = string.match(s, '"UI_ZeD_Guide_Bubble": "(.-)",\r?\n')
    check(l .. " bubble keeps its %1", b and string.find(b, "%1", 1, true) ~= nil)
end

print("guide_bubble_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
