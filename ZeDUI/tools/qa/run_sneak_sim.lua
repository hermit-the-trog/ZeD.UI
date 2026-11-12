-- ZeDUI/tools/qa/run_sneak_sim.lua (Nov 12 2026, punch list 121): the run button that also sneaks, with no game
-- running. ZeD's REAL Settings.lua and Input/RunSneak.lua on Lua 5.1 stubs of the game. The pad is a table per
-- controller (Run held, the movement stick, the bumpers, its dead zone); the game's own rules are modeled from its
-- 42.22 Java (javap): Run:isDown reads the binding, Movement:isApplied is x*x + y*y >= dzX * dzY, and the character
-- runs while the stick is applied AND Run is down (CharacterInputComponent.isRunButtonDown).
--   SETTING   a "runSneak" switch, Off and On, Off for a new player, read live; its name key; a checkbox in ZeD setup's
--             Controls group; not an addition (no preset sets it)
--   OFF       off by default does nothing: a long hold standing still never crouches
--   STILL     a hold with the stick at rest crouches at 400 ms (not before), once per hold; a second hold stands
--   MOVING    a hold while moving runs (the game's own run) for as long as it is held, stops on release; no crouch
--   CROUCHED  crouched and moving, a hold stands up at 400 ms and the run carries on standing (a sneak run before)
--   TAP       a tap still, moving or crouched changes nothing; the game's short run happens and stops
--   DEAD ZONE a push inside the controller's own dead zone is "still", outside it is "moving"
--   GATES     a window holding the pad, aiming, a car, a bumper (chords), a pause gap, a press already held when the
--             switch turned on, a stick let go part way, a dead player: nothing
--   BINDINGS  Run on a button or a trigger works; on the stick (the game's Default layout) or on L3 / R3: nothing
--   PLAYERS   split screen: two players on two pads keep their own timing; a keyboard player 1 is left alone
--   SOURCE    ASCII only, no next(), the only state it changes is setSneaking, hold timed with getTimestampMs, one
--             tick handler after a reload
--   WORDS     both keys in all 28 languages, the English exact, AR in Spanish letters
-- Run from the repo root:  lua51 ZeDUI/tools/qa/run_sneak_sim.lua
-- It prints FAIL lines and a last line "run_sneak_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]run_sneak_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local LUA = ROOT .. "42/media/lua/"
next = nil      -- (Kahlua has no next(): a file that calls it fails here as in the game)

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- ---------------------------------------------------------------------------
-- THE WORDS
-- ---------------------------------------------------------------------------
local function loadJson(path)
    local s = readFile(path)
    if not s then return nil end
    local t = {}
    for k, v in s:gmatch('"([%w_%.]+)"%s*:%s*"(.-[^\\])",?%s*\r?\n') do
        t[k] = v:gsub('\\"', '"'):gsub("\\\\", "\\")
    end
    return t
end
local LANGS = { "EN", "AR", "CA", "CH", "CN", "CS", "DA", "DE", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP",
                "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
local UI = {}
for _, l in ipairs(LANGS) do UI[l] = loadJson(LUA .. "shared/Translate/" .. l .. "/UI.json") end
local EN = UI.EN or {}
local GAME = { UI_Off = "Off", UI_On = "On", Sandbox_Custom = "Custom" }
function getText(k) return GAME[k] or EN[k] or k end
getTextOrNull = getText
ZeD = { tr = function(k) return getText(k) end }

-- ---------------------------------------------------------------------------
-- THE GAME: events, clock, options
-- ---------------------------------------------------------------------------
local CLOCK = 5000000
function getTimestampMs() return CLOCK end
local tickFns = {}
Events = setmetatable({}, { __index = function(t, k)
    local e = {
        Add = function(f) if k == "OnTick" then tickFns[#tickFns + 1] = f end end,
        Remove = function(f)
            if k ~= "OnTick" then return end
            for i = #tickFns, 1, -1 do if tickFns[i] == f then table.remove(tickFns, i) end end
        end,
    }
    rawset(t, k, e)
    return e
end })
function getFileReader() return nil end
function getFileWriter() return { write = noop, close = noop } end
local function newOption(id)
    local o = { id = id, values = {}, selected = 1 }
    function o:addItem(name, isDefault)
        self.values[#self.values + 1] = name
        if isDefault then self.selected = #self.values end
    end
    function o:getValue() return self.selected end
    function o:setValue(v) self.selected = v end
    return o
end
local function newOpts()
    local opts = { dict = {} }
    local function add(self, id)
        local o = newOption(id)
        self.dict[id] = o
        return o
    end
    return setmetatable(opts, { __index = function(t, k)
        if k == "addComboBox" or k == "addTickBox" or k == "addMultipleTickBox" or k == "addSlider" then return add end
        return noop
    end })
end
local lastOpts
PZAPI = { ModOptions = { create = function() lastOpts = newOpts(); return lastOpts end, save = noop, load = noop } }
require = function() end
getCore = function() return { getOptionClock24Hour = function() return true end } end
isClient = function() return false end

-- ---------------------------------------------------------------------------
-- THE PAD AND THE GAME'S BINDINGS (one table per controller id)
-- ---------------------------------------------------------------------------
local PAD = {}
local function pad(id)
    PAD[id] = PAD[id] or { run = false, x = 0, y = 0, lb = false, rb = false, l3 = false, dz = 0.2 }
    return PAD[id]
end
local function enum(name, isDown) return { name = name, isDown = isDown or function() return false end } end
JoypadButton = {
    A = enum("A"), B = enum("B"),
    LeftStick = enum("LeftStick", function(_, id) return PAD[id] ~= nil and PAD[id].l3 end),
    RightStick = enum("RightStick"),
    LeftBump = enum("LeftBump", function(_, id) return PAD[id] ~= nil and PAD[id].lb end),
    RightBump = enum("RightBump", function(_, id) return PAD[id] ~= nil and PAD[id].rb end),
}
JoypadAxis1d = { LeftTrigger = enum("LeftTrigger"), RightTrigger = enum("RightTrigger"), LeftStickY = enum("LeftStickY") }
JoypadAxis2d = { LeftStick = enum("LeftStick2d"), RightStick = enum("RightStick2d") }
-- what the game's Run is bound to: "trigger" (the Original layout, RT), "button" (B), "stick" (the Default layout: a
-- full push of the movement stick, 0.975), "stickclick" (L3), "stickaxis" (one axis of a stick)
local KIND = "trigger"
local Run = {}
function Run:getJoypadButton()
    if KIND == "button" then return JoypadButton.B elseif KIND == "stickclick" then return JoypadButton.LeftStick end
    return nil
end
function Run:getJoypadAxis1d()
    if KIND == "trigger" then return JoypadAxis1d.RightTrigger elseif KIND == "stickaxis" then return JoypadAxis1d.LeftStickY end
    return nil
end
function Run:getJoypadAxis2d() if KIND == "stick" then return JoypadAxis2d.LeftStick end return nil end
function Run:isDown(id)
    local p = PAD[id]
    if not p then return false end
    if KIND == "stick" then return (p.x * p.x + p.y * p.y) >= 0.975 * 0.975 end
    if KIND == "stickclick" then return p.l3 end
    return p.run
end
CharacterJoypadButtonBinding = { Run = Run }
-- the game's dead zone test (JoypadManager$Joypad.isMovementInsideDeadZone): inside while x*x + y*y < dzX * dzY
local Movement = {}
function Movement:isApplied(id)
    local p = PAD[id]
    if not p then return false end
    return not ((p.x * p.x + p.y * p.y) < p.dz * p.dz)
end
CharacterJoypadAxis2dBinding = { Movement = Movement }

-- ---------------------------------------------------------------------------
-- THE PLAYERS (split screen: up to four, each with its own controller id; -1 is keyboard and mouse)
-- ---------------------------------------------------------------------------
local function newPlayer(bind)
    local p = { bind = bind, sneaking = false, dead = false, vehicle = nil, aiming = false, asleep = false,
                sitting = false, climbing = false, ignoreMove = false, calls = {}, running = false, runFrames = 0 }
    function p:getJoypadBind() return self.bind end
    function p:isSneaking() return self.sneaking end
    function p:setSneaking(v) self.calls[#self.calls + 1] = v; self.sneaking = v end
    function p:isDead() return self.dead end
    function p:getVehicle() return self.vehicle end
    function p:isAsleep() return self.asleep end
    function p:getIgnoreMovement() return self.ignoreMove end
    function p:isSitOnGround() return self.sitting end
    function p:isClimbing() return self.climbing end
    function p:isAiming() return self.aiming end
    function p:isPlayerMoving() return false end
    return p
end
local PLAYERS = {}
local NUM = 1
function getSpecificPlayer(n) return PLAYERS[n] end
function getPlayer() return PLAYERS[0] end
function getNumActivePlayers() return NUM end
local FOCUS = {}
function getJoypadFocus(pn) return FOCUS[pn] end
local PAUSED = false
function isGamePaused() return PAUSED end
JoypadState = { disableMovement = false }

-- the game, after ZeD's tick: each player runs while the stick is applied and Run is down (no car, not aiming)
local function game()
    for pn = 0, NUM - 1 do
        local p = PLAYERS[pn]
        if p then
            local b = p.bind
            p.running = b >= 0 and not p.vehicle and not p.aiming and Movement:isApplied(b) and Run:isDown(b) or false
            if p.running then p.runFrames = p.runFrames + 1 end
        end
    end
end
local function frame(ms)
    CLOCK = CLOCK + (ms or 16)
    for _, f in ipairs(tickFns) do f() end
    game()
end
-- ms of play in 16 ms frames
local function play(ms)
    local t = 0
    while t < ms do frame(16); t = t + 16 end
end

-- ---------------------------------------------------------------------------
-- SETTINGS
-- ---------------------------------------------------------------------------
section("Settings: the switch")
local nTickBefore = #tickFns
ZeD.Settings = nil
local chunk, err = loadfile(LUA .. "client/ZeD/Settings.lua")
local opts
if chunk then
    local ok, e = pcall(chunk)
    if ok then opts = lastOpts else err = e end
end
check("Settings.lua loads", opts ~= nil, err)
opts = opts or newOpts()
local S = ZeD.Settings or {}
local o = opts.dict.runSneak
check("a runSneak option", o ~= nil)
check("its items: Off, On", o and o.values[1] == "Off" and o.values[2] == "On" and #o.values == 2,
      o and table.concat(o.values, "/"))
check("Off for a new player", o and o:getValue() == 1)
check("runSneakOn() false by default", S.runSneakOn and S.runSneakOn() == false)
check("its name key noted", o and o.zedNameKey == "UI_ZeD_Settings_RunSneak")
local inIds = false
for _, id in ipairs(S.ADDITION_IDS or {}) do if id == "runSneak" then inIds = true end end
check("not an addition (no preset sets it)", not inIds)
for i, set in ipairs(S.ADDITION_PRESETS or {}) do check("preset " .. i .. " leaves it alone", set.runSneak == nil) end
local groups = readFile(LUA .. "client/ZeD/ZeD_MainMenuOptionGroups.lua") or ""
local ctl = groups:match('"UI_ZeD_Options_ZedControls".-}%s*}%s*},')
check("a checkbox in ZeD setup's Controls group", ctl and ctl:find('{ "runSneak", "onoff" }', 1, true) ~= nil)
if o then
    o:setValue(2)
    check("runSneakOn() reads the switch live (On)", S.runSneakOn() == true)
    o:setValue(1)
    check("runSneakOn() reads the switch live (Off)", S.runSneakOn() == false)
end

-- ---------------------------------------------------------------------------
-- THE MODULE
-- ---------------------------------------------------------------------------
local nTickSettings = #tickFns
local okLoad, loadErr = pcall(dofile, LUA .. "client/ZeD/Input/RunSneak.lua")
check("RunSneak.lua loads", okLoad, loadErr)
local RS = ZeD.Input and ZeD.Input.RunSneak or {}
check("one tick handler added", #tickFns == nTickSettings + 1, #tickFns - nTickSettings)
pcall(dofile, LUA .. "client/ZeD/Input/RunSneak.lua")
check("a reload keeps one tick handler", #tickFns == nTickSettings + 1, #tickFns - nTickSettings)
check("HOLD_MS is the game's 400 ms tap limit", RS.HOLD_MS == 400, RS.HOLD_MS)

local P0, P1 = newPlayer(0), newPlayer(1)
PLAYERS[0] = P0
pad(0); pad(1)
local function reset()
    for _, p in pairs(PLAYERS) do p.sneaking = false; p.calls = {}; p.aiming = false; p.vehicle = nil; p.dead = false; p.runFrames = 0 end
    for _, d in pairs(PAD) do d.run = false; d.x = 0; d.y = 0; d.lb = false; d.rb = false; d.l3 = false; d.dz = 0.2 end
    FOCUS = {}; PAUSED = false; KIND = "trigger"
    play(64)   -- a few frames with Run up, so the next press is a fresh one
    for _, p in pairs(PLAYERS) do p.calls = {}; p.runFrames = 0 end
end

section("Off by default does nothing")
reset()
pad(0).run = true
play(1500)
check("off: a long hold standing still never crouches", #P0.calls == 0 and P0.sneaking == false, #P0.calls)
pad(0).x = 1.0
play(500)
check("off: the game still runs on its own", P0.running == true)
reset()
P0.sneaking = true
pad(0).x = 1.0; pad(0).run = true
play(1000)
check("off: crouched and moving, the hold stays the game's sneak run", P0.sneaking == true and P0.running == true and #P0.calls == 0)
o:setValue(2)

section("Still: hold to crouch, hold again to stand")
reset()
pad(0).run = true
play(352)
check("no crouch before 400 ms", #P0.calls == 0 and P0.sneaking == false, #P0.calls)
check("state: held", RS.getState(0) == "held", RS.getState(0))
play(64)
check("a hold of 400 ms crouches", P0.sneaking == true and #P0.calls == 1, #P0.calls)
check("lastAction: crouch", RS.lastAction(0) == "crouch", RS.lastAction(0))
check("state: spent", RS.getState(0) == "spent", RS.getState(0))
play(2000)
check("one thing per hold (two more seconds held: still one)", #P0.calls == 1, #P0.calls)
check("standing still the game never runs", P0.runFrames == 0, P0.runFrames)
pad(0).run = false
play(48)
check("released: idle, still crouched", RS.getState(0) == "idle" and P0.sneaking == true)
pad(0).run = true
play(448)
check("a second hold stands up", P0.sneaking == false and #P0.calls == 2, #P0.calls)
check("lastAction: stand", RS.lastAction(0) == "stand", RS.lastAction(0))
pad(0).run = false
play(48)

section("Moving: the hold runs while held and stops on release")
reset()
pad(0).x = 1.0
play(32)
pad(0).run = true
play(48)
check("running from the first frames (the game's own run)", P0.running == true)
play(1500)
check("still running after 1.5 s held", P0.running == true)
check("no crouch, no setSneaking at all", #P0.calls == 0 and P0.sneaking == false, #P0.calls)
pad(0).run = false
play(32)
check("let go: running stops", P0.running == false)
check("let go: still standing", P0.sneaking == false and #P0.calls == 0)
pad(0).x = 0

section("Crouched and moving: the hold stands and runs")
reset()
P0.sneaking = true
pad(0).x = 0.8; pad(0).y = 0.4
play(32)
pad(0).run = true
play(208)
check("under 400 ms: still crouched (the game's sneak run)", P0.sneaking == true and P0.running == true)
play(240)
check("at 400 ms: stood up", P0.sneaking == false and #P0.calls == 1 and P0.calls[1] == false, #P0.calls)
check("lastAction: stand-run", RS.lastAction(0) == "stand-run", RS.lastAction(0))
check("and running, standing", P0.running == true)
play(800)
check("one thing per hold", #P0.calls == 1, #P0.calls)
pad(0).run = false
play(32)
check("let go: the run stops, the character stays standing", P0.running == false and P0.sneaking == false)

section("A tap passes through")
reset()
pad(0).run = true; play(208); pad(0).run = false; play(48)
check("a tap standing still: nothing", #P0.calls == 0 and P0.sneaking == false)
pad(0).run = true; play(384); pad(0).run = false; play(48)
check("a tap of 384 ms (just under the limit): nothing", #P0.calls == 0 and P0.sneaking == false)
pad(0).x = 1.0
pad(0).run = true; play(208)
check("a moving tap: the game's short run", P0.running == true)
pad(0).run = false; play(48)
check("a moving tap: stops, nothing changed", P0.running == false and #P0.calls == 0)
P0.sneaking = true
pad(0).run = true; play(208); pad(0).run = false; play(48)
check("a crouched moving tap: still crouched", P0.sneaking == true and #P0.calls == 0)
pad(0).x = 0
P0.sneaking = true
pad(0).run = true; play(208); pad(0).run = false; play(48)
check("a crouched still tap: still crouched", P0.sneaking == true and #P0.calls == 0)

section("Dead zone: the controller's own")
reset()
pad(0).x = 0.15            -- inside 0.2
pad(0).run = true; play(448); pad(0).run = false; play(48)
check("a push inside the dead zone is still: the hold crouches", P0.sneaking == true and #P0.calls == 1, #P0.calls)
reset()
pad(0).x = 0.3             -- outside 0.2
pad(0).run = true; play(448)
check("a push past the dead zone is moving: no crouch", P0.sneaking == false and #P0.calls == 0)
check("and the game runs", P0.running == true)
pad(0).run = false; play(48)
reset()
pad(0).dz = 0.4; pad(0).x = 0.3   -- the same push, a wider dead zone set for this controller
pad(0).run = true; play(448); pad(0).run = false; play(48)
check("the same push inside a wider dead zone is still: crouches", P0.sneaking == true and #P0.calls == 1)

section("Gates")
reset()
FOCUS[0] = { name = "a window" }
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("a window holding the pad: nothing", #P0.calls == 0)
pad(0).run = true; play(160)
FOCUS[0] = nil
play(800)
check("a press begun in a window, the window closed mid-hold: nothing", #P0.calls == 0)
pad(0).run = false; play(48)
pad(0).run = true; play(448); pad(0).run = false; play(48)
check("the next press after it works", #P0.calls == 1)
reset()
P0.aiming = true
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("aiming (Run is the attack trigger then): nothing", #P0.calls == 0)
reset()
pad(0).run = true; play(160)
P0.aiming = true; play(400); P0.aiming = false
pad(0).run = false; play(48)
check("aiming begun mid-hold: nothing", #P0.calls == 0)
reset()
P0.vehicle = { name = "car" }
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("in a car: nothing", #P0.calls == 0)
reset()
pad(0).lb = true
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("a bumper held (a quick chord): nothing", #P0.calls == 0)
reset()
pad(0).run = true; play(160)
frame(1500)                -- the game paused 1.5 s with Run held (OnTick stops while paused)
play(400); pad(0).run = false; play(48)
check("a press that spans a pause: nothing", #P0.calls == 0)
reset()
o:setValue(1)
pad(0).run = true; play(200)
o:setValue(2)
play(1000)
check("a press already held when the switch turned on: nothing", #P0.calls == 0)
pad(0).run = false; play(48)
pad(0).run = true; play(448); pad(0).run = false; play(48)
check("the next press works", #P0.calls == 1)
reset()
pad(0).x = 1.0; pad(0).run = true; play(160)
pad(0).x = 0; play(400); pad(0).run = false; play(48)
check("moving, then the stick let go before 400 ms: nothing", #P0.calls == 0)
reset()
P0.dead = true
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("a dead player: nothing", #P0.calls == 0)
P0.dead = false
reset()
PAUSED = true
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("paused: nothing", #P0.calls == 0)

section("Bindings: what the game's Run is on")
reset()
check("runBindingKind: trigger (Original layout, RT)", RS.runBindingKind() == "trigger", RS.runBindingKind())
KIND = "button"
check("runBindingKind: button", RS.runBindingKind() == "button", RS.runBindingKind())
pad(0).run = true; play(448); pad(0).run = false; play(48)
check("Run on a button: the hold crouches", #P0.calls == 1, #P0.calls)
reset()
KIND = "stick"
check("runBindingKind: stick (Default layout)", RS.runBindingKind() == "stick", RS.runBindingKind())
P0.sneaking = true
pad(0).x = 1.0
play(1000)
check("Run on the stick: a full push crouched stays the game's sneak run", P0.sneaking == true and P0.running == true and #P0.calls == 0)
reset()
KIND = "stickclick"
check("runBindingKind: stickclick (L3)", RS.runBindingKind() == "stickclick", RS.runBindingKind())
pad(0).l3 = true; play(1000); pad(0).l3 = false; play(48)
check("Run on L3: holding L3 changes nothing", #P0.calls == 0)
reset()
KIND = "stickaxis"
check("runBindingKind: one axis of a stick is a stick", RS.runBindingKind() == "stick", RS.runBindingKind())
KIND = "trigger"

section("Players: split screen")
reset()
NUM = 2
PLAYERS[1] = P1
reset()
pad(0).run = true
play(208)
pad(1).x = 1.0; P1.sneaking = true
pad(1).run = true
play(208)
check("at 416 ms: player 1 crouched (its own hold)", P0.sneaking == true and #P0.calls == 1, #P0.calls)
check("at 416 ms: player 2 untouched (its hold is 208 ms old)", P1.sneaking == true and #P1.calls == 0, #P1.calls)
play(208)
check("at 624 ms: player 2 stood up and runs", P1.sneaking == false and #P1.calls == 1 and P1.running == true, #P1.calls)
check("player 1 got one thing only", #P0.calls == 1, #P0.calls)
check("their states are their own", RS.getState(0) == "spent" and RS.getState(1) == "spent")
pad(0).run = false; play(48)
check("player 1 let go: idle; player 2 still holding: spent", RS.getState(0) == "idle" and RS.getState(1) == "spent")
pad(1).run = false; pad(1).x = 0; play(48)
reset()
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("player 1's pad never moves player 2", #P1.calls == 0 and #P0.calls == 1)
reset()
P0.bind = -1                 -- player 1 on keyboard and mouse, player 2 on pad 1
pad(1).run = true; play(448); pad(1).run = false; play(48)
check("a keyboard player 1 is left alone", #P0.calls == 0)
check("player 2 on pad 1 still works", #P1.calls == 1)
P0.bind = 0
NUM = 1
PLAYERS[1] = nil

section("QA stand-in")
reset()
P0.bind = -1
RS.qaInput(0, { pad = true, run = true, moving = false })
play(448)
check("qaInput drives a player with no controller", #P0.calls == 1 and P0.sneaking == true)
RS.qaInput(0, { pad = true, run = false })
play(48)
RS.qaInput(0, nil)
play(48)
check("qaInput nil hands the player back (keyboard: idle)", RS.getState(0) == "idle")
P0.bind = 0

-- ---------------------------------------------------------------------------
-- SOURCE
-- ---------------------------------------------------------------------------
section("Source")
local src = readFile(LUA .. "client/ZeD/Input/RunSneak.lua") or ""
check("the file is there", #src > 0)
check("ASCII only (Kahlua drops high bytes in literals)", not src:find("[\128-\255]"))
local code = src:gsub("%-%-[^\n]*", "")
check("no next()", not code:find("[^%w_%.:]next%s*%("))
check("the only state it changes is setSneaking", code:find("setSneaking", 1, true) ~= nil
      and not code:find("setRunning", 1, true) and not code:find("setForceRun", 1, true)
      and not code:find("setSprinting", 1, true) and not code:find("setForceSprint", 1, true)
      and not code:find("setAllowRun", 1, true) and not code:find("setAllowSprint", 1, true))
check("timed with getTimestampMs", code:find("getTimestampMs()", 1, true) ~= nil)
check("never polls L3 or R3", not code:find("LeftStick:isDown", 1, true) and not code:find("RightStick:isDown", 1, true))

-- ---------------------------------------------------------------------------
-- WORDS
-- ---------------------------------------------------------------------------
section("Words")
check("English name", EN.UI_ZeD_Settings_RunSneak == "Run button also sneaks", EN.UI_ZeD_Settings_RunSneak)
check("English help names the hold and the tap", EN.UI_ZeD_Settings_RunSneakTip ~= nil
      and EN.UI_ZeD_Settings_RunSneakTip:find("hold Run to crouch", 1, true) ~= nil
      and EN.UI_ZeD_Settings_RunSneakTip:find("A quick tap", 1, true) ~= nil)
for _, l in ipairs(LANGS) do
    local t = UI[l] or {}
    check(l .. ": both keys", t.UI_ZeD_Settings_RunSneak ~= nil and t.UI_ZeD_Settings_RunSneakTip ~= nil)
end
local ar = (UI.AR or {}).UI_ZeD_Settings_RunSneakTip or ""
check("AR is Argentine Spanish (no Arabic letters)", not ar:find("\216[\128-\191]") and not ar:find("\217[\128-\191]"))
check("AR: voseo (mantene with its accent)", ar:find("manten\195\169", 1, true) ~= nil)

print(string.format("run_sneak_sim: %d checks, %d failed", checks, failed))
os.exit(failed == 0 and 0 or 1)
