-- ZeDUI/tools/qa/run_sneak_sim.lua (Nov 12 2026, punch list 121): run and sneak on one button, with no game running.
-- ZeD's REAL Settings.lua and Input/RunSneak.lua on Lua 5.1 stubs of the game. The pad is a table per controller (the
-- trigger, L3, the movement stick, the bumpers, its dead zone). The game's frame is modeled from its 42.22 Java (javap):
--   1. the input step (CharacterInputComponent.frameStep): "Toggle to run" off clears the run flag (setForceRun false)
--      every frame; on, a click of Run toggles it; the Crouch button's click timer runs (TimedInputHandler, 400 ms)
--   2. the player update (IsoPlayer.updateInternal2): OnPlayerUpdate fires, then the Crouch click toggles the stance
--      (updateSneakKey), then the input is read (UpdateInputState): running = the stick past its dead zone with Run
--      down and Run allowed (isRunButtonDown), OR the run flag
--   3. the prompts' update: L3 held 250 ms opens the left joystick radial menu (ISJoystickButtonRadialMenu)
--   4. OnTick, at the end of the frame
-- The bindings: Original (the game's default) has Run on RT; Default has Run on a full push of the stick (0.975);
-- both have Crouch on L3.
--   SETTING   "runSneak": Off and On, Off for a new player, read live; its name key; a checkbox in ZeD setup's Controls
--             group; not an addition
--   ORIGINAL  the Run button: off does nothing; still hold crouches at 400 ms, again stands; moving runs (the game's
--             own) while held and stops on release; crouched and moving stands and runs; taps pass; the dead zone is
--             the controller's; never touches the run flag; L3's radial menu stays the game's
--   DEFAULT   the Crouch button (L3): still hold crouches / stands, no game toggle on release; a tap is the game's crouch
--             toggle; moving, the hold runs from 400 ms for as long as it is held, then stops; crouched and moving
--             stands and runs; a full push without L3 is the game's run; L3's radial menu stays shut while it's ours
--   NOT STUCK the run flag let go on release, on the switch turned off, Safe mode, a window, a car, a pause, aiming,
--             a climb, a new character, a pad unplugged, a reload, an error; with "Toggle to run" on too, where the
--             game keeps the flag (and the player's own toggled run is left on)
--   HOOK      the same flag set on OnTick never makes anyone run (the game clears it first); on OnPlayerUpdate it does
--   STAKES    Run not allowed: no run; the run is the game's (running only through the game's flag)
--   PLAYERS   two players on two pads keep their own timing and runs; a keyboard player 1 is left alone
--   SOURCE    ASCII only, no next(), only setSneaking and setForceRun change state, OnPlayerUpdate (not OnTick),
--             getTimestampMs; one handler and one radial wrap after a reload
--   WORDS     both keys in all 28 languages, the English exact, AR in Spanish letters with voseo
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
local tickFns, updFns = {}, {}
local function listFor(k) if k == "OnTick" then return tickFns elseif k == "OnPlayerUpdate" then return updFns end return nil end
Events = setmetatable({}, { __index = function(t, k)
    local e = {
        Add = function(f) local l = listFor(k); if l then l[#l + 1] = f end end,
        Remove = function(f)
            local l = listFor(k)
            if not l then return end
            for i = #l, 1, -1 do if l[i] == f then table.remove(l, i) end end
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
local SAFE = false

-- ---------------------------------------------------------------------------
-- THE PAD AND THE GAME'S BINDINGS (one table per controller id)
-- ---------------------------------------------------------------------------
local PAD = {}
local function pad(id)
    PAD[id] = PAD[id] or { run = false, l3 = false, y = false, x = 0, lb = false, rb = false, dz = 0.2 }
    return PAD[id]
end
local function enum(name, isDown) return { name = name, isDown = isDown or function() return false end } end
JoypadButton = {
    A = enum("A"), B = enum("B"),
    Y = enum("Y", function(_, id) return PAD[id] ~= nil and PAD[id].y end),
    LeftStick = enum("LeftStick", function(_, id) return PAD[id] ~= nil and PAD[id].l3 end),
    RightStick = enum("RightStick"),
    LeftBump = enum("LeftBump", function(_, id) return PAD[id] ~= nil and PAD[id].lb end),
    RightBump = enum("RightBump", function(_, id) return PAD[id] ~= nil and PAD[id].rb end),
}
JoypadAxis1d = { LeftTrigger = enum("LeftTrigger"), RightTrigger = enum("RightTrigger"), LeftStickY = enum("LeftStickY") }
JoypadAxis2d = { LeftStick = enum("LeftStick2d"), RightStick = enum("RightStick2d") }
-- what the game's Run is on: "trigger" (Original: RT), "stick" (Default: a full push, 0.975), "button" (B),
-- "stickclick" (L3), "stickaxis" (one axis of a stick); and Crouch: "stickclick" (L3, both layouts), "button" (Y)
local KIND_RUN, KIND_CROUCH = "trigger", "stickclick"
local function len2(p) return p.x * p.x end
local Run = {}
function Run:getJoypadButton()
    if KIND_RUN == "button" then return JoypadButton.B elseif KIND_RUN == "stickclick" then return JoypadButton.LeftStick end
    return nil
end
function Run:getJoypadAxis1d()
    if KIND_RUN == "trigger" then return JoypadAxis1d.RightTrigger elseif KIND_RUN == "stickaxis" then return JoypadAxis1d.LeftStickY end
    return nil
end
function Run:getJoypadAxis2d() if KIND_RUN == "stick" then return JoypadAxis2d.LeftStick end return nil end
function Run:isDown(id)
    local p = PAD[id]
    if not p then return false end
    if KIND_RUN == "stick" then return len2(p) >= 0.975 * 0.975 end
    if KIND_RUN == "stickclick" then return p.l3 end
    if KIND_RUN == "stickaxis" then return false end
    return p.run
end
local Crouch = {}
function Crouch:getJoypadButton()
    if KIND_CROUCH == "stickclick" then return JoypadButton.LeftStick elseif KIND_CROUCH == "button" then return JoypadButton.Y end
    return nil
end
function Crouch:getJoypadAxis1d() return nil end
function Crouch:getJoypadAxis2d() return nil end
function Crouch:isDown(id)
    local p = PAD[id]
    if not p then return false end
    if KIND_CROUCH == "stickclick" then return p.l3 end
    if KIND_CROUCH == "button" then return p.y end
    return false
end
CharacterJoypadButtonBinding = { Run = Run, Crouch = Crouch }
-- the game's dead zone test (JoypadManager$Joypad.isMovementInsideDeadZone): inside while x*x + y*y < dzX * dzY
local Movement = {}
function Movement:isApplied(id)
    local p = PAD[id]
    if not p then return false end
    return not (len2(p) < p.dz * p.dz)
end
CharacterJoypadAxis2dBinding = { Movement = Movement }

-- ---------------------------------------------------------------------------
-- THE PLAYERS (split screen: up to four, each with its own controller id; -1 is keyboard and mouse)
-- ---------------------------------------------------------------------------
local function newTimer() return { downMs = 0, clicked = false } end
-- TimedInputHandler.updateState: a click is a release within 400 ms of the press
local function stepTimer(t, keyDown)
    local pressed = keyDown and t.downMs == 0
    local released = (not keyDown) and t.downMs ~= 0
    t.clicked = released and (CLOCK - t.downMs) < 400
    if pressed then t.downMs = CLOCK elseif released then t.downMs = 0 end
end
local function newPlayer(pn, bind)
    local p = { pn = pn, bind = bind, sneaking = false, dead = false, vehicle = nil, aiming = false, asleep = false,
                sitting = false, climbing = false, ignoreMove = false, allowRun = true, climbStart = false,
                forceRun = false, running = false, runFrames = 0, stillRunFrames = 0, calls = {}, forceSets = 0,
                gameToggles = 0, tRun = newTimer(), tCrouch = newTimer() }
    function p:getPlayerNum() return self.pn end
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
    function p:isAllowRun() return self.allowRun end
    function p:getVariableBoolean(name)
        return (name == "ClimbFenceStarted" or name == "ClimbWindowStarted") and self.climbStart or false
    end
    function p:isForceRun() return self.forceRun end
    function p:setForceRun(v) self.forceSets = self.forceSets + 1; self.forceRun = v end
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
local TOGGLE_TO_RUN = false     -- the game's "Toggle to run" option (off by default)
local RADIAL_OPTION = true      -- the game's "Enable left joystick radial menu" (on by default)

-- the game's left joystick radial menu: L3 held 250 ms opens it (it takes the pad); let go closes it
local RADIAL = {}
ISJoystickButtonRadialMenu = {}
function ISJoystickButtonRadialMenu.onRepeatLeftStickButton(joypadData)
    local r = RADIAL[joypadData.player]
    if not RADIAL_OPTION or not r or not r.pressedMs or r.open then return end
    if CLOCK - r.pressedMs >= 250 then
        r.open, r.opens = true, r.opens + 1
        FOCUS[joypadData.player] = "radial"
    end
end
local VANILLA_REPEAT = ISJoystickButtonRadialMenu.onRepeatLeftStickButton

-- one frame of the game, each local player in turn
local function frame(ms)
    CLOCK = CLOCK + (ms or 16)
    for pn = 0, NUM - 1 do
        local p = PLAYERS[pn]
        if p then
            local b = p.bind
            local onPad = b >= 0
            local d = onPad and pad(b) or nil
            local moving = onPad and Movement:isApplied(b) or false
            local runDown = onPad and p.allowRun and moving and Run:isDown(b) or false
            -- 1. the input step
            stepTimer(p.tRun, TOGGLE_TO_RUN and runDown)
            if not TOGGLE_TO_RUN then p.forceRun = false
            elseif p.climbStart then p.forceRun = false
            elseif p.tRun.clicked then p.forceRun = not p.forceRun end
            local active = FOCUS[pn] == nil and not JoypadState.disableMovement
            stepTimer(p.tCrouch, onPad and active and Crouch:isDown(b) or false)
            -- 2. the player update
            for _, f in ipairs(updFns) do f(p) end
            if p.tCrouch.clicked and active then p.sneaking = not p.sneaking; p.gameToggles = p.gameToggles + 1 end
            p.running = (not p.vehicle) and (runDown or p.forceRun) or false
            if p.running and moving then p.runFrames = p.runFrames + 1 end
            -- 3. the prompts: L3 held opens the radial menu
            if onPad then
                RADIAL[pn] = RADIAL[pn] or { opens = 0 }
                local r = RADIAL[pn]
                if d.l3 and not r.l3 then r.pressedMs = CLOCK end
                if not d.l3 and r.l3 then
                    r.pressedMs = nil
                    if r.open then r.open = false; FOCUS[pn] = nil end
                end
                r.l3 = d.l3
                if d.l3 and not r.open then ISJoystickButtonRadialMenu.onRepeatLeftStickButton({ player = pn, id = b }) end
            end
        end
    end
    -- 4. the end of the frame
    for _, f in ipairs(tickFns) do f() end
end
local function play(ms)
    local t = 0
    while t < ms do frame(16); t = t + 16 end
end

-- ---------------------------------------------------------------------------
-- SETTINGS
-- ---------------------------------------------------------------------------
section("Settings: the switch")
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
ZeD.Safe = { on = function() return SAFE end }

-- ---------------------------------------------------------------------------
-- THE MODULE
-- ---------------------------------------------------------------------------
local okLoad, loadErr = pcall(dofile, LUA .. "client/ZeD/Input/RunSneak.lua")
check("RunSneak.lua loads", okLoad, loadErr)
local RS = ZeD.Input and ZeD.Input.RunSneak or {}
check("one OnPlayerUpdate handler, no OnTick handler", #updFns == 1 and #tickFns == 0, #updFns .. "/" .. #tickFns)
local WRAPPED = ISJoystickButtonRadialMenu.onRepeatLeftStickButton
check("the game's L3 radial step is wrapped, the original kept", WRAPPED ~= VANILLA_REPEAT and RS._zedOrigRepeatLeft == VANILLA_REPEAT)
pcall(dofile, LUA .. "client/ZeD/Input/RunSneak.lua")
check("a reload keeps one handler", #updFns == 1, #updFns)
check("a reload never wraps the wrapper", ISJoystickButtonRadialMenu.onRepeatLeftStickButton == WRAPPED
      and RS._zedOrigRepeatLeft == VANILLA_REPEAT)
check("HOLD_MS is the game's 400 ms tap limit", RS.HOLD_MS == 400, RS.HOLD_MS)

local P0, P1 = newPlayer(0, 0), newPlayer(1, 1)
PLAYERS[0] = P0
pad(0); pad(1)
local function reset()
    for _, p in pairs(PLAYERS) do
        p.sneaking = false; p.aiming = false; p.vehicle = nil; p.dead = false; p.allowRun = true; p.climbStart = false
        p.forceRun = false
    end
    for _, d in pairs(PAD) do d.run = false; d.l3 = false; d.y = false; d.x = 0; d.lb = false; d.rb = false; d.dz = 0.2 end
    FOCUS = {}; PAUSED = false; SAFE = false; TOGGLE_TO_RUN = false; RADIAL_OPTION = true
    play(64)   -- a few frames with everything up, so the next press is a fresh one
    for _, p in pairs(PLAYERS) do p.calls = {}; p.runFrames = 0; p.forceSets = 0; p.gameToggles = 0 end
    for _, r in pairs(RADIAL) do r.opens = 0 end
end
local function radialOpens(pn) return RADIAL[pn] and RADIAL[pn].opens or 0 end

-- =========================================================================
section("Original layout (Run on RT): off by default does nothing")
KIND_RUN = "trigger"
reset()
check("holdMode: run", RS.holdMode() == "run", RS.holdMode())
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

section("Original: still, hold to crouch, hold again to stand")
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

section("Original: moving, the hold runs while held and stops on release")
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
pad(0).x = 0

section("Original: crouched and moving, the hold stands and runs")
reset()
P0.sneaking = true
pad(0).x = 0.8
play(32)
pad(0).run = true
play(208)
check("under 400 ms: still crouched (the game's sneak run)", P0.sneaking == true and P0.running == true)
play(240)
check("at 400 ms: stood up", P0.sneaking == false and #P0.calls == 1 and P0.calls[1] == false, #P0.calls)
check("lastAction: stand-run", RS.lastAction(0) == "stand-run", RS.lastAction(0))
check("and running, standing", P0.running == true)
pad(0).run = false
play(32)
check("let go: the run stops, the character stays standing", P0.running == false and P0.sneaking == false)

section("Original: taps pass, the dead zone is the controller's")
reset()
pad(0).run = true; play(208); pad(0).run = false; play(48)
check("a tap standing still: nothing", #P0.calls == 0 and P0.sneaking == false)
pad(0).run = true; play(384); pad(0).run = false; play(48)
check("a tap just under the limit: nothing", #P0.calls == 0 and P0.sneaking == false)
pad(0).x = 1.0
pad(0).run = true; play(208)
check("a moving tap: the game's short run", P0.running == true)
pad(0).run = false; play(48)
check("a moving tap: stops, nothing changed", P0.running == false and #P0.calls == 0)
reset()
pad(0).x = 0.15            -- inside 0.2
pad(0).run = true; play(448); pad(0).run = false; play(48)
check("a push inside the dead zone is still: the hold crouches", P0.sneaking == true and #P0.calls == 1, #P0.calls)
reset()
pad(0).x = 0.3             -- outside 0.2
pad(0).run = true; play(448)
check("a push past the dead zone is moving: no crouch, the game runs", P0.sneaking == false and #P0.calls == 0 and P0.running == true)
pad(0).run = false; play(48)
reset()
pad(0).dz = 0.4; pad(0).x = 0.3   -- the same push, a wider dead zone set for this controller
pad(0).run = true; play(448); pad(0).run = false; play(48)
check("the same push inside a wider dead zone is still: crouches", P0.sneaking == true and #P0.calls == 1)

section("Original: the run flag and L3 stay the game's")
reset()
pad(0).x = 1.0; pad(0).run = true; play(1000); pad(0).run = false; pad(0).x = 0; play(48)
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("the Run button never touches the run flag", P0.forceSets == 0, P0.forceSets)
pad(0).l3 = true; play(400)
check("L3 held: the game's radial menu opens (L3 is not this layout's hold)", radialOpens(0) == 1, radialOpens(0))
pad(0).l3 = false; play(48)
check("ownsHold(L3) false on Original", RS.ownsHold(0, JoypadButton.LeftStick) == false)

-- =========================================================================
section("Default layout (Run on a full stick push): the Crouch button, L3")
KIND_RUN = "stick"
reset()
check("holdMode: crouch", RS.holdMode() == "crouch", RS.holdMode())
check("ownsHold(L3) true while the switch is on", RS.ownsHold(0, JoypadButton.LeftStick) == true)
pad(0).l3 = true
play(352)
check("no crouch before 400 ms", #P0.calls == 0 and P0.sneaking == false)
play(64)
check("a still hold of L3 crouches at 400 ms", P0.sneaking == true and #P0.calls == 1, #P0.calls)
play(1000)
pad(0).l3 = false
play(48)
check("released after the hold: the game does not toggle it back", P0.sneaking == true and P0.gameToggles == 0, P0.gameToggles)
check("the radial menu never opened", radialOpens(0) == 0, radialOpens(0))
pad(0).l3 = true; play(448); pad(0).l3 = false; play(48)
check("a second still hold stands up", P0.sneaking == false and #P0.calls == 2 and P0.gameToggles == 0)
reset()
pad(0).l3 = true; play(208); pad(0).l3 = false; play(48)
check("a tap of L3: the game's crouch toggle", P0.sneaking == true and P0.gameToggles == 1 and #P0.calls == 0)
pad(0).l3 = true; play(208); pad(0).l3 = false; play(48)
check("a second tap: the game stands", P0.sneaking == false and P0.gameToggles == 2 and #P0.calls == 0)
check("taps never open the radial menu", radialOpens(0) == 0)

section("Default: moving, the hold runs for as long as it is held")
reset()
pad(0).x = 0.5          -- a partial push: walking (the game's run needs a full push here)
play(64)
check("a partial push walks", P0.running == false)
pad(0).l3 = true
play(352)
check("under 400 ms: still walking", P0.running == false and P0.runFrames == 0, P0.runFrames)
play(64)
check("at 400 ms: running", P0.running == true)
check("lastAction: run", RS.lastAction(0) == "run", RS.lastAction(0))
check("state: running", RS.getState(0) == "running", RS.getState(0))
local before = P0.runFrames
play(2400)
check("running every frame of 2.4 s held", P0.runFrames - before == 150, P0.runFrames - before)
check("on the game's own flag, set each frame", P0.forceRun == true and P0.forceSets >= 150, P0.forceSets)
pad(0).l3 = false
frame(16)
check("let go: running stops on the next frame", P0.running == false and P0.forceRun == false)
play(500)
check("and stays stopped", P0.running == false and P0.runFrames - before == 150)
check("no crouch toggle at the release (a hold is not a tap)", P0.sneaking == false and P0.gameToggles == 0)
check("the radial menu never opened", radialOpens(0) == 0)
pad(0).x = 0

section("Default: crouched and moving, the hold stands and runs")
reset()
P0.sneaking = true
pad(0).x = 0.5
play(32)
pad(0).l3 = true
play(208)
check("under 400 ms: still crouched, not running", P0.sneaking == true and P0.running == false)
play(240)
check("at 400 ms: stood up and running", P0.sneaking == false and P0.running == true and #P0.calls == 1)
check("lastAction: stand-run", RS.lastAction(0) == "stand-run", RS.lastAction(0))
pad(0).l3 = false
play(32)
check("let go: standing, not running", P0.sneaking == false and P0.running == false and P0.gameToggles == 0)

section("Default: taps and the game's own run")
reset()
pad(0).x = 0.5
pad(0).l3 = true; play(208); pad(0).l3 = false; play(48)
check("a moving tap: the game's crouch toggle, no run", P0.sneaking == true and P0.gameToggles == 1 and P0.runFrames == 0)
reset()
pad(0).x = 1.0
play(500)
check("a full push without L3: the game's own run", P0.running == true and P0.forceSets == 0)
pad(0).x = 0
o:setValue(1)
reset()
pad(0).x = 0.5; pad(0).l3 = true; play(1000)
check("switched off: an L3 hold while moving never runs", P0.runFrames == 0 and P0.forceSets == 0)
check("switched off: the radial menu is the game's again (opens at 250 ms)", radialOpens(0) == 1, radialOpens(0))
pad(0).l3 = false; play(48)
o:setValue(2)

-- =========================================================================
section("Never stuck: every way a run ends")
local function startRun()
    reset()
    pad(0).x = 0.5
    play(32)
    pad(0).l3 = true
    play(448)
    return P0.running == true
end
local function stopsNow(name)
    frame(16)
    check(name .. ": not running on the next frame", P0.running == false and P0.forceRun == false,
          tostring(P0.running) .. "/" .. tostring(P0.forceRun))
    play(400)
    check(name .. ": still not running, held or not", P0.running == false and P0.forceRun == false)
end
for _, ttr in ipairs({ false, true }) do
    local tag = ttr and "Toggle to run on" or "Toggle to run off"
    local function arm() local ok = startRun(); TOGGLE_TO_RUN = ttr; play(32); return ok end
    check(tag .. ": a run starts", arm())
    pad(0).l3 = false
    stopsNow(tag .. ", release")
    check(tag .. ": a run starts again", arm())
    o:setValue(1)
    stopsNow(tag .. ", the switch turned off mid-run")
    o:setValue(2)
    pad(0).l3 = false; play(48)
    check(tag .. ": a run", arm())
    SAFE = true
    stopsNow(tag .. ", Safe mode mid-run")
    SAFE = false
    check(tag .. ": a run", arm())
    FOCUS[0] = "a window"
    stopsNow(tag .. ", a window takes the pad")
    FOCUS[0] = nil
    play(400)
    check(tag .. ": the window gone, still held: no run until a new hold", P0.running == false)
    check(tag .. ": a run", arm())
    P0.vehicle = "a car"
    stopsNow(tag .. ", in a car")
    P0.vehicle = nil
    check(tag .. ": a run", arm())
    P0.aiming = true
    stopsNow(tag .. ", aiming")
    P0.aiming = false
    check(tag .. ": a run", arm())
    P0.climbStart = true
    stopsNow(tag .. ", a climb starts")
    P0.climbStart = false
    check(tag .. ": a run", arm())
    P0.allowRun = false
    stopsNow(tag .. ", Run no longer allowed")
    P0.allowRun = true
    check(tag .. ": a run", arm())
    P0.bind = -1
    stopsNow(tag .. ", the pad unplugged")
    P0.bind = 0
    check(tag .. ": a run", arm())
    frame(1500)                     -- a pause: the game stopped 1.5 s with L3 held
    play(16)
    check(tag .. ", a pause: not running after it", P0.running == false and P0.forceRun == false)
    check(tag .. ": a run", arm())
    local old = P0
    local fresh = newPlayer(0, 0)
    PLAYERS[0] = fresh
    play(32)
    check(tag .. ", a new character in the seat: the old one's flag let go", old.forceRun == false, old.forceRun)
    check(tag .. ", a new character: not running", fresh.running == false and fresh.forceRun == false)
    PLAYERS[0] = old
    pad(0).l3 = false; play(48)
    check(tag .. ": a run", arm())
    -- (a throw from a call the step makes directly, every frame; the getters go through their own pcall)
    local realFocus = getJoypadFocus
    getJoypadFocus = function() error("a broken call") end
    stopsNow(tag .. ", an error every frame")
    getJoypadFocus = realFocus
    pad(0).l3 = false; play(48)
    check(tag .. ": a run", arm())
    pcall(dofile, LUA .. "client/ZeD/Input/RunSneak.lua")
    check(tag .. ", a reload mid-run: still running", P0.running == true)
    pad(0).l3 = false
    stopsNow(tag .. ", a reload, then release")
    TOGGLE_TO_RUN = false
end
reset()
TOGGLE_TO_RUN = true
P0.forceRun = true              -- the player's own Toggle to run is on
pad(0).x = 0.5; play(32)
check("the player's own toggled run: running before the hold", P0.running == true)
pad(0).l3 = true; play(448); pad(0).l3 = false; play(48)
check("the player's own toggled run is still on after a hold", P0.forceRun == true and P0.running == true)
TOGGLE_TO_RUN = false

section("The hook: the game clears the flag before OnTick could matter")
reset()
local function setOnTick() P0:setForceRun(true) end
tickFns[#tickFns + 1] = setOnTick
pad(0).x = 0.5
play(1000)
check("the flag set on OnTick (end of frame) never makes the player run", P0.runFrames == 0, P0.runFrames)
table.remove(tickFns, #tickFns)
local function setOnUpdate(p) p:setForceRun(true) end
updFns[#updFns + 1] = setOnUpdate
play(160)
check("the same flag set on OnPlayerUpdate does", P0.runFrames >= 9, P0.runFrames)
table.remove(updFns, #updFns)
pad(0).x = 0; play(32)

section("Stakes and gates")
reset()
P0.allowRun = false
pad(0).x = 0.5; pad(0).l3 = true; play(1000); pad(0).l3 = false; play(48)
check("Run not allowed (the game's own check): an L3 hold never runs", P0.runFrames == 0 and P0.forceSets == 0)
reset()
pad(0).lb = true
pad(0).x = 0.5; pad(0).l3 = true; play(1000); pad(0).l3 = false; play(48)
check("a bumper held (LB + L3 is a quick chord): nothing", P0.runFrames == 0 and #P0.calls == 0)
reset()
pad(0).x = 1.0; pad(0).l3 = true; play(160)
pad(0).x = 0; play(400); pad(0).l3 = false; play(48)
check("moving, then the stick let go before 400 ms: nothing", #P0.calls == 0 and P0.forceSets == 0)
reset()
KIND_CROUCH = "button"
check("Crouch rebound to Y: holdMode crouch on Y", RS.holdMode() == "crouch" and RS.ownsHold(0, JoypadButton.LeftStick) == false)
pad(0).y = true; play(448); pad(0).y = false; play(48)
check("Crouch on Y: a still hold crouches", P0.sneaking == true and #P0.calls == 1)
pad(0).l3 = true; play(400); pad(0).l3 = false; play(48)
check("Crouch on Y: L3's radial menu is the game's again", radialOpens(0) == 1, radialOpens(0))
KIND_CROUCH = "none"
check("no button for Run or Crouch: holdMode nil", RS.holdMode() == nil)
KIND_CROUCH = "stickclick"
KIND_RUN = "stickclick"
check("Run on L3: no Run button, the hold is Crouch", RS.holdMode() == "crouch")
KIND_RUN = "stickaxis"
check("runBindingKind: one axis of a stick is a stick", RS.runBindingKind() == "stick", RS.runBindingKind())
KIND_RUN = "button"
check("Run on a face button: holdMode run", RS.holdMode() == "run")
KIND_RUN = "stick"

section("Players: split screen on the Default layout")
NUM = 2
PLAYERS[1] = P1
reset()
pad(0).x = 0.5
pad(0).l3 = true
play(208)
pad(1).l3 = true
play(208)
check("at 416 ms: player 1 runs (its own hold)", P0.running == true and P0.forceRun == true)
check("at 416 ms: player 2 untouched (its hold is 208 ms old)", P1.sneaking == false and #P1.calls == 0 and P1.forceRun == false)
play(208)
check("at 624 ms: player 2 crouched (standing still)", P1.sneaking == true and #P1.calls == 1)
check("player 2 never runs", P1.runFrames == 0 and P1.forceSets == 0)
pad(0).l3 = false; frame(16)
check("player 1 let go: stops; player 2 still holding: spent", P0.running == false and RS.getState(1) == "spent")
pad(1).l3 = false; play(48)
reset()
P0.bind = -1                 -- player 1 on keyboard and mouse, player 2 on pad 1
pad(1).x = 0.5; pad(1).l3 = true; play(448)
check("player 2 on pad 1 runs", P1.running == true)
check("a keyboard player 1 is left alone", P0.forceSets == 0 and #P0.calls == 0)
pad(1).l3 = false; play(48)
P0.bind = 0
NUM = 1
PLAYERS[1] = nil

section("QA stand-in")
reset()
P0.bind = -1
RS.qaInput(0, { pad = true, held = true, moving = false, mode = "run" })
play(448)
check("qaInput, Run mode: a still hold crouches a player with no controller", #P0.calls == 1 and P0.sneaking == true)
RS.qaInput(0, { pad = true, held = false, moving = true, mode = "crouch" }); play(48)
RS.qaInput(0, { pad = true, held = true, moving = true, mode = "crouch" }); play(448)
check("qaInput, Crouch mode: crouched and moving stands and holds the run flag", P0.sneaking == false and P0.forceRun == true)
RS.qaInput(0, nil)
play(48)
check("qaInput nil hands the player back: the flag let go", RS.getState(0) == "idle" and P0.forceRun == false)
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
check("the state it changes: the stance and the game's run flag only", code:find("setSneaking", 1, true) ~= nil
      and code:find("setForceRun", 1, true) ~= nil
      and not code:find("setRunning", 1, true) and not code:find("setSprinting", 1, true)
      and not code:find("setForceSprint", 1, true) and not code:find("setAllowRun", 1, true)
      and not code:find("setAllowSprint", 1, true) and not code:find("getStats", 1, true)
      and not code:find("Endurance", 1, true) and not code:find("setVariable", 1, true))
check("the hook is OnPlayerUpdate, not OnTick", code:find("Events.OnPlayerUpdate.Add", 1, true) ~= nil
      and not code:find("Events.OnTick", 1, true))
check("timed with getTimestampMs", code:find("getTimestampMs()", 1, true) ~= nil)
check("never polls a stick click itself", not code:find("LeftStick:isDown", 1, true) and not code:find("RightStick:isDown", 1, true))

-- ---------------------------------------------------------------------------
-- WORDS
-- ---------------------------------------------------------------------------
section("Words")
check("English name", EN.UI_ZeD_Settings_RunSneak == "Run and sneak on one button", EN.UI_ZeD_Settings_RunSneak)
local tip = EN.UI_ZeD_Settings_RunSneakTip or ""
check("English help names each layout's button", tip:find("RT in Original", 1, true) ~= nil and tip:find("L3 in Default", 1, true) ~= nil)
check("English help names the hold, the run and the tap", tip:find("hold it to crouch", 1, true) ~= nil
      and tip:find("hold it to run", 1, true) ~= nil and tip:find("A tap", 1, true) ~= nil)
check("English help says the L3 hold leaves the radial menu", tip:find("left joystick radial menu", 1, true) ~= nil)
for _, l in ipairs(LANGS) do
    local t = UI[l] or {}
    check(l .. ": both keys", t.UI_ZeD_Settings_RunSneak ~= nil and t.UI_ZeD_Settings_RunSneakTip ~= nil)
    check(l .. ": names RT and L3", (t.UI_ZeD_Settings_RunSneakTip or ""):find("RT", 1, true) ~= nil
          and (t.UI_ZeD_Settings_RunSneakTip or ""):find("L3", 1, true) ~= nil)
end
local ar = (UI.AR or {}).UI_ZeD_Settings_RunSneakTip or ""
check("AR is Argentine Spanish (no Arabic letters)", not ar:find("\216[\128-\191]") and not ar:find("\217[\128-\191]"))
check("AR: voseo (mantenelo)", ar:find("mantenelo", 1, true) ~= nil)

print(string.format("run_sneak_sim: %d checks, %d failed", checks, failed))
os.exit(failed == 0 and 0 or 1)
