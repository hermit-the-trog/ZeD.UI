-- ZeDUI/tools/qa/run_sneak_sim.lua (Nov 12 2026, punch list 121): the Run button that also sneaks, with no game
-- running. ZeD's REAL Settings.lua and Input/RunSneak.lua on Lua 5.1 stubs of the game. The pad is a table per
-- controller (the trigger, L3, the movement stick, the bumpers, its dead zone). The game's frame is modeled from its
-- 42.22 Java (javap):
--   1. the input step (CharacterInputComponent.frameStep): the "Toggle to run" timer runs on Run with the stick
--      (isToggleRunButtonDown; a click toggles the run flag), and with the option off it is muted and clears the run
--      flag every frame; the Crouch button's click timer runs (TimedInputHandler: a release within 400 ms is a click)
--   2. the player update (IsoPlayer.updateInternal2): OnPlayerUpdate fires, then a Crouch click toggles the stance
--      (updateSneakKey), then a move direction of zero on the last frame clears the run flag, then the movement is
--      read (the stick, else the auto-walk direction; a path walks the character too: isPlayerMoving, read by the
--      next frame), then the input is read (UpdateInputState): running = the stick past its dead zone with Run down
--      and Run allowed (isRunButtonDown), or the run flag
--   3. the prompts' update: L3 held 250 ms opens the game's left joystick radial menu (ISJoystickButtonRadialMenu)
--   4. OnTick, at the end of the frame
-- The layouts: Original (the game's default) has Run on RT; Default has Run on a full push of the stick (0.975), no
-- Run button; both have Crouch on L3.
--   SETTING   "runSneak": Off and On, Off for a new player, read live; its name key; a checkbox in ZeD setup's Controls
--             group; not an addition
--   ORIGINAL  off does nothing; still hold crouches at 400 ms (not before), once per hold, again stands; moving runs
--             (the game's own run) while held and stops on release; crouched and moving stands and runs; taps pass;
--             the dead zone is the controller's own; a hold that moves is timed from the stick's push (the game's own
--             run press is Run with the stick); a press that moved waits while the stick is at rest (let go, or the
--             game's auto-walk), and a later push, however late, stands up 400 ms after it; one thing per press
--   TOGGLE    the game's "Toggle to run" on: a press is the game's tap (its run toggled) or a hold here, never both,
--             over a sweep of stick pushes and let-gos; a long hold stands up and toggles nothing; the same over an
--             auto-walk sweep, a let-go-and-push-again sweep and a seeded random sweep, where every stand-up also
--             lands exactly 400 ms into the game's run press, every crouch or stand lands with the character still,
--             a press acts once, and a crouched character whose run press reaches 400 ms always stands (unless that
--             press already acted)
--   DEFAULT   the switch on, nothing at all: no stance change from any hold of L3, RT or the stick, L3's tap stays the
--             game's crouch toggle, L3's hold opens the game's radial menu at 250 ms, the stick's full push is the
--             game's run, the module's state never leaves idle; the radial menu's code is never wrapped
--   EVERYWHERE the run flag is never set, L3 is never read; the run is always the game's
--   GATES     a window holding the pad, aiming, a car, a bumper (chords), a pause, a press already held when the switch
--             turned on, a stick let go part way, a dead player, Safe mode, sitting on a seat or on the ground (and
--             getting up with Run held), a walk the game does on its own (a path): nothing
--   AUTO-WALK the game's auto-walk with the stick at rest is moving: no crouch, no stand-up (the game's Run does
--             nothing there), however long Run is held; a push of the stick then stands up 400 ms after the push, a
--             push long after Run went down too; an auto-walk that starts mid-press is no still hold; auto-walk with
--             no direction yet is standing still
--   BINDINGS  any layout with Run on a button or a trigger works (RT in Original, or B in a player's own layout:
--             crouch, stand, tap, stand-run); Run on the stick (Default), on L3, on R3, on LB or on RB: refused,
--             nothing of ZeD's (a bumper is never even read: it stays ZeD's quick actions)
--   PLAYERS   split screen: two players on two pads keep their own timing; a keyboard player 1 is left alone
--   SOURCE    ASCII only, no next(), the only state it changes is setSneaking, OnPlayerUpdate, getTimestampMs, nothing of
--             L3, the Crouch binding or the radial menu; one handler after a reload; isSitting, hasPath, isAutoWalk
--   WORDS     both keys in all 28 languages, the English exact (Run on a button works, as in Original on RT; a full
--             stick push, the Default layout, or LB / RB does nothing), every language names LB and RB, AR with voseo
--   QA STEPS  zedqa_run_sneak.lua: part A pushes again long after Run in a press that moved; part B steps 6 and 10
--             push the stick within about a quarter second of RT, step 8 holds RT a second or more before the push
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
local L3_READS = 0     -- every read of L3 by anyone but the game's own model below
local BUMP_READS = 0   -- every read of LB or RB by anyone but the game's own model below
local function pad(id)
    PAD[id] = PAD[id] or { run = false, l3 = false, r3 = false, x = 0, lb = false, rb = false, dz = 0.2 }
    return PAD[id]
end
local function enum(name, isDown) return { name = name, isDown = isDown or function() return false end } end
JoypadButton = {
    A = enum("A"), B = enum("B"),
    LeftStick = enum("LeftStick", function(_, id) L3_READS = L3_READS + 1; return PAD[id] ~= nil and PAD[id].l3 end),
    RightStick = enum("RightStick", function(_, id) L3_READS = L3_READS + 1; return PAD[id] ~= nil and PAD[id].r3 end),
    LeftBump = enum("LeftBump", function(_, id) BUMP_READS = BUMP_READS + 1; return PAD[id] ~= nil and PAD[id].lb end),
    RightBump = enum("RightBump", function(_, id) BUMP_READS = BUMP_READS + 1; return PAD[id] ~= nil and PAD[id].rb end),
}
JoypadAxis1d = { LeftTrigger = enum("LeftTrigger"), RightTrigger = enum("RightTrigger"), LeftStickY = enum("LeftStickY") }
JoypadAxis2d = { LeftStick = enum("LeftStick2d"), RightStick = enum("RightStick2d") }
-- what the game's Run is on: "trigger" (Original: RT), "stick" (Default: a full push, 0.975), "button" (B, a
-- player's own layout), "stickclick" (L3), "stickclickR" (R3), "stickaxis" (one axis of a stick), "bumperL" (LB),
-- "bumperR" (RB)
local KIND_RUN = "trigger"
-- the game's "Toggle to run" option (off for a new player)
local TOGGLE_RUN = false
local function len2(p) return p.x * p.x end
local Run = {}
function Run:getJoypadButton()
    if KIND_RUN == "button" then return JoypadButton.B
    elseif KIND_RUN == "stickclick" then return JoypadButton.LeftStick
    elseif KIND_RUN == "stickclickR" then return JoypadButton.RightStick
    elseif KIND_RUN == "bumperL" then return JoypadButton.LeftBump
    elseif KIND_RUN == "bumperR" then return JoypadButton.RightBump end
    return nil
end
function Run:getJoypadAxis1d()
    if KIND_RUN == "trigger" then return JoypadAxis1d.RightTrigger elseif KIND_RUN == "stickaxis" then return JoypadAxis1d.LeftStickY end
    return nil
end
function Run:getJoypadAxis2d() if KIND_RUN == "stick" then return JoypadAxis2d.LeftStick end return nil end
local function runIsDown(id)
    local p = PAD[id]
    if not p then return false end
    if KIND_RUN == "stick" then return len2(p) >= 0.975 * 0.975 end
    if KIND_RUN == "stickclick" then return p.l3 end
    if KIND_RUN == "stickclickR" then return p.r3 end
    if KIND_RUN == "stickaxis" then return false end
    if KIND_RUN == "bumperL" then return p.lb end
    if KIND_RUN == "bumperR" then return p.rb end
    return p.run
end
function Run:isDown(id)
    if KIND_RUN == "stickclick" or KIND_RUN == "stickclickR" then L3_READS = L3_READS + 1 end
    if KIND_RUN == "bumperL" or KIND_RUN == "bumperR" then BUMP_READS = BUMP_READS + 1 end
    return runIsDown(id)
end
-- the Crouch binding is the game's (L3); the module must never read it
local CROUCH_READS = 0
local Crouch = {}
function Crouch:getJoypadButton() CROUCH_READS = CROUCH_READS + 1; return JoypadButton.LeftStick end
function Crouch:isDown() CROUCH_READS = CROUCH_READS + 1; return false end
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
-- TimedInputHandler.updateState: a click is a release within 400 ms of the press (clickFrom: when that press began)
local function stepTimer(t, keyDown)
    local pressed = keyDown and t.downMs == 0
    local released = (not keyDown) and t.downMs ~= 0
    t.clicked = released and (CLOCK - t.downMs) < 400
    if t.clicked then t.clickFrom = t.downMs end
    if pressed then t.downMs = CLOCK elseif released then t.downMs = 0 end
end
local FORCE_SETS = 0   -- every setForceRun call, by anyone
-- sitting is on the ground (isSitOnGround), seated on a chair, sofa or bed (isSittingOnFurniture: a flag of its own,
-- PlayerSitOnFurnitureState never sets the ground one); isSitting is either. autoWalk and autoDir: the game's
-- auto-walk and whether it has a direction yet; path: a walk the game does on its own (hasPath); moveDir: the move
-- direction was not zero on the last frame; playerMoving: the game's isPlayerMoving, set late in the last frame
local function newPlayer(pn, bind)
    local p = { pn = pn, bind = bind, sneaking = false, dead = false, vehicle = nil, aiming = false, asleep = false,
                sitting = false, seated = false, climbing = false, ignoreMove = false, allowRun = true, forceRun = false,
                running = false, runFrames = 0, calls = {}, gameToggles = 0, tCrouch = newTimer(), tRun = newTimer(),
                gameClicks = 0, autoWalk = false, autoDir = false, path = nil, moveDir = false, playerMoving = false }
    function p:getPlayerNum() return self.pn end
    function p:getJoypadBind() return self.bind end
    function p:isSneaking() return self.sneaking end
    function p:setSneaking(v) self.calls[#self.calls + 1] = v; self.sneaking = v end
    function p:isDead() return self.dead end
    function p:getVehicle() return self.vehicle end
    function p:isAsleep() return self.asleep end
    function p:getIgnoreMovement() return self.ignoreMove end
    function p:isSitOnGround() return self.sitting end
    function p:isSittingOnFurniture() return self.seated end
    function p:isSitting() return self.sitting or self.seated end
    function p:isClimbing() return self.climbing end
    function p:isAiming() return self.aiming end
    function p:isAutoWalk() return self.autoWalk end
    function p:hasPath() return self.path ~= nil end
    function p:isPlayerMoving() return self.playerMoving end
    function p:isAllowRun() return self.allowRun end
    function p:isForceRun() return self.forceRun end
    function p:setForceRun(v) FORCE_SETS = FORCE_SETS + 1; self.forceRun = v end
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

-- the game's left joystick radial menu: L3 held 250 ms opens it (it takes the pad); let go closes it
local RADIAL = {}
ISJoystickButtonRadialMenu = {}
function ISJoystickButtonRadialMenu.onRepeatLeftStickButton(joypadData)
    local r = RADIAL[joypadData.player]
    if not r or not r.pressedMs or r.open then return end
    if CLOCK - r.pressedMs >= 250 then
        r.open, r.opens = true, r.opens + 1
        FOCUS[joypadData.player] = "radial"
    end
end
local VANILLA_REPEAT = ISJoystickButtonRadialMenu.onRepeatLeftStickButton

-- one frame of the game, each local player in turn (its own reads of the pad go straight to the table)
local function frame(ms)
    CLOCK = CLOCK + (ms or 16)
    for pn = 0, NUM - 1 do
        local p = PLAYERS[pn]
        if p then
            local b = p.bind
            local onPad = b >= 0
            local d = onPad and pad(b) or nil
            local moving = onPad and Movement:isApplied(b) or false
            local runDown = onPad and p.allowRun and moving and runIsDown(b) or false
            -- 1. the input step: the Toggle to run timer keys on Run with the stick, so its press starts at the push
            stepTimer(p.tRun, TOGGLE_RUN and runDown or false)
            if not TOGGLE_RUN then
                p.forceRun = false              -- (muted: "Toggle to run" off, the game's default)
            elseif p.tRun.clicked then
                p.forceRun = not p.forceRun     -- (toggleForceRun)
                p.gameClicks = p.gameClicks + 1
                p.tappedFrom = p.tRun.clickFrom
            end
            local active = FOCUS[pn] == nil and not JoypadState.disableMovement
            stepTimer(p.tCrouch, onPad and active and d.l3 or false)
            -- 2. the player update
            for _, f in ipairs(updFns) do f(p) end
            if p.tCrouch.clicked and active then p.sneaking = not p.sneaking; p.gameToggles = p.gameToggles + 1 end
            if not p.moveDir then p.forceRun = false end   -- (the last frame's move direction zero clears the run flag)
            -- the movement: the stick, else the auto-walk direction (the stick sets it; at rest it stays while auto-walk
            -- is on); a path walks the character on its own
            if moving then p.autoDir = true elseif not p.autoWalk then p.autoDir = false end
            p.moveDir = moving or (p.autoWalk and p.autoDir) or false
            p.playerMoving = p.moveDir or p.path ~= nil
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
check("the game's radial menu code is untouched", ISJoystickButtonRadialMenu.onRepeatLeftStickButton == VANILLA_REPEAT)
pcall(dofile, LUA .. "client/ZeD/Input/RunSneak.lua")
check("a reload keeps one handler", #updFns == 1, #updFns)
check("HOLD_MS is the game's 400 ms tap limit", RS.HOLD_MS == 400, RS.HOLD_MS)

local P0, P1 = newPlayer(0, 0), newPlayer(1, 1)
PLAYERS[0] = P0
pad(0); pad(1)
local function reset()
    for _, p in pairs(PLAYERS) do
        p.sneaking = false; p.aiming = false; p.vehicle = nil; p.dead = false; p.allowRun = true
        p.sitting = false; p.seated = false; p.autoWalk = false; p.autoDir = false; p.path = nil
    end
    for _, d in pairs(PAD) do d.run = false; d.l3 = false; d.r3 = false; d.x = 0; d.lb = false; d.rb = false; d.dz = 0.2 end
    FOCUS = {}; PAUSED = false; SAFE = false
    play(64)   -- a few frames with everything up, so the next press is a fresh one
    for _, p in pairs(PLAYERS) do
        p.calls = {}; p.runFrames = 0; p.gameToggles = 0; p.gameClicks = 0; p.forceRun = false; p.tappedFrom = nil
    end
    for _, r in pairs(RADIAL) do r.opens = 0 end
end
local function radialOpens(pn) return RADIAL[pn] and RADIAL[pn].opens or 0 end

-- =========================================================================
section("Original layout (Run on RT): off by default does nothing")
KIND_RUN = "trigger"
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
local before = P0.runFrames
play(1504)
check("running on every frame of 1.5 s held", P0.runFrames - before == 94, P0.runFrames - before)
check("no crouch, no setSneaking at all", #P0.calls == 0 and P0.sneaking == false, #P0.calls)
pad(0).run = false
frame(16)
check("let go: running stops on the next frame", P0.running == false)
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
check("and running, standing, in the same frame", P0.running == true)
play(800)
check("one thing per hold", #P0.calls == 1, #P0.calls)
pad(0).run = false
play(32)
check("let go: the run stops, the character stays standing", P0.running == false and P0.sneaking == false)

section("Original: a hold that moves is timed from the stick's push (the game's run press is Run with the stick)")
reset()
P0.sneaking = true
pad(0).run = true; play(144)       -- Run down standing still: the game sees no run press yet
pad(0).x = 1.0; play(352)          -- the stick pushed 144 ms in; now 480 ms after Run, 336 after the push
check("crouched, Run then the stick: no stand-up 400 ms after Run (the game's run press is 336 ms old)",
      P0.sneaking == true and #P0.calls == 0, #P0.calls)
check("state: still held", RS.getState(0) == "held", RS.getState(0))
play(64)
check("400 ms after the push: stood up and running", P0.sneaking == false and #P0.calls == 1 and P0.running == true
      and RS.lastAction(0) == "stand-run", #P0.calls)
pad(0).run = false; pad(0).x = 0; play(48)
reset()
P0.sneaking = true
pad(0).x = 1.0; play(32)
pad(0).run = true; play(160)
pad(0).x = 0; play(96)             -- the stick let go with Run held: the game's run press is over
pad(0).x = 1.0; play(336)          -- pushed again 256 ms in; now 576 ms after Run, 320 after the second push
check("pushed, let go, pushed again: timed from the second push (not yet at 320 ms)", #P0.calls == 0 and P0.sneaking == true,
      #P0.calls)
play(80)
check("400 ms after the second push: stood up", #P0.calls == 1 and P0.sneaking == false, #P0.calls)
pad(0).run = false; pad(0).x = 0; play(48)

section("Original: a press that moved waits while the stick is at rest; a later push is timed from the push")
reset()
P0.sneaking = true
pad(0).x = 1.0; play(32)
pad(0).run = true; play(160)
pad(0).x = 0; play(400)            -- the stick let go 160 ms in, Run held: 544 ms after Run, past the old 400 ms mark
check("crouched, moving, the stick let go 160 ms in: nothing by 544 ms", #P0.calls == 0 and P0.sneaking == true, #P0.calls)
check("the press waits for the stick (held, not spent)", RS.getState(0) == "held", RS.getState(0))
pad(0).x = 1.0; play(352)          -- pushed again 560 ms in; now 336 ms after the push
check("pushed again 560 ms in: no stand-up 336 ms after the push", #P0.calls == 0 and P0.sneaking == true, #P0.calls)
play(64)
check("400 ms after the push: stood up and running", #P0.calls == 1 and P0.sneaking == false and P0.running == true
      and RS.lastAction(0) == "stand-run", #P0.calls)
-- one thing per press: crouch again with the game's L3, let the stick go and push it again, Run held all along
pad(0).l3 = true; play(48); pad(0).l3 = false; play(48)
check("crouched again by the game's L3 tap, Run still held", P0.sneaking == true and P0.gameToggles == 1, P0.gameToggles)
pad(0).x = 0; play(96)
pad(0).x = 1.0; play(800)
check("a press acts once: another push in the same press does nothing", #P0.calls == 1 and P0.sneaking == true,
      #P0.calls)
pad(0).run = false; pad(0).x = 0; play(48)
reset()
P0.sneaking = true
pad(0).run = true; play(64)
pad(0).x = 1.0; play(96)           -- pushed 64 ms in, let go 160 ms in
pad(0).x = 0; play(1040)
pad(0).x = 1.0; play(352)          -- pushed again 1200 ms in
check("crouched and still at Run, a push and a let-go, a second push 1200 ms in: nothing 336 ms after it",
      #P0.calls == 0 and P0.sneaking == true, #P0.calls)
play(64)
check("then stood up, 400 ms after the second push", #P0.calls == 1 and P0.sneaking == false and P0.running == true,
      #P0.calls)
pad(0).run = false; pad(0).x = 0; play(48)
reset()
pad(0).x = 1.0; play(32)
pad(0).run = true; play(160)
pad(0).x = 0; play(400)
pad(0).x = 1.0; play(608)
check("standing, the stick let go and pushed again: the game runs, the stance is left alone", #P0.calls == 0
      and P0.sneaking == false and P0.running == true, #P0.calls)
check("and that press is spent", RS.getState(0) == "spent", RS.getState(0))
pad(0).run = false; pad(0).x = 0; play(48)
reset()
pad(0).x = 1.0; play(32)
pad(0).run = true; play(160)
pad(0).x = 0; play(1504)           -- the stick let go, the character still, Run held 1.5 s more
check("moved, then still with Run held on: no crouch (a press that moved never crouches or stands still)",
      #P0.calls == 0 and P0.sneaking == false, #P0.calls)
pad(0).run = false; play(48)

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
P0.sneaking = true
pad(0).run = true; play(208); pad(0).run = false; play(48)
check("a crouched moving tap: still crouched", P0.sneaking == true and #P0.calls == 0)
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

section("Original: L3 stays the game's")
reset()
pad(0).l3 = true; play(208); pad(0).l3 = false; play(48)
check("an L3 tap: the game's crouch toggle, nothing of ZeD's", P0.sneaking == true and P0.gameToggles == 1 and #P0.calls == 0)
pad(0).l3 = true; play(400)
check("an L3 hold: the game's radial menu opens at 250 ms", radialOpens(0) == 1, radialOpens(0))
pad(0).l3 = false; play(48)
check("and nothing of ZeD's", #P0.calls == 0)

-- =========================================================================
section("Original, the game's Toggle to run on: a press is the game's tap or this hold, never both")
TOGGLE_RUN = true
reset()
P0.sneaking = true
pad(0).run = true; play(144)       -- crouched, still: Run down, then the stick 144 ms in (to get up and flee)
pad(0).x = 1.0; play(320)
pad(0).run = false; frame(16)      -- Run let go 464 ms after it went down, 320 after the push
check("Run, then the stick, let go 320 ms after the push: the game's tap toggles its run", P0.gameClicks == 1
      and P0.forceRun == true, P0.gameClicks)
check("and no stand-up here: the same press is never also a hold", P0.sneaking == true and #P0.calls == 0, #P0.calls)
play(160)
check("the stick still pushed: the game's toggled run carries on, crouched (its sneak run)", P0.running == true
      and P0.sneaking == true)
pad(0).x = 0; play(48)
check("the stick at rest: the game drops its toggled run", P0.forceRun == false and P0.running == false)
reset()
P0.sneaking = true
pad(0).x = 0.8; play(32)
pad(0).run = true; play(608)
check("crouched and moving, a hold: stood up at 400 ms", P0.sneaking == false and #P0.calls == 1, #P0.calls)
pad(0).run = false; frame(16)
check("let go past 400 ms: not the game's tap, its run is not toggled", P0.gameClicks == 0 and P0.forceRun == false,
      P0.gameClicks)
play(32)
check("and the run stops with the button", P0.running == false)
pad(0).x = 0; play(48)
reset()
pad(0).x = 1.0; play(32)
pad(0).run = true; play(208); pad(0).run = false; frame(16)
check("a moving tap: the game toggles its run on, nothing here", P0.gameClicks == 1 and P0.forceRun == true and #P0.calls == 0)
play(160)
check("and keeps running with the button up", P0.running == true)
pad(0).run = true; play(208); pad(0).run = false; frame(16)
check("a second tap toggles it off", P0.gameClicks == 2 and P0.forceRun == false and #P0.calls == 0)
pad(0).x = 0
-- every way one press can go, crouched and still at the start: the stick pushed at 0 to 448 ms or never, Run let go
-- at 208 to 1200 ms. "Both" is a hold here that lands inside a run press the game then reads as a tap. (A still
-- hold that lands before the stick moves is not: the game's run press only begins at the push.)
local both, holds, taps, presses = 0, 0, 0, 0
for _, at in ipairs({ 0, 64, 144, 256, 384, 448, -1 }) do
    for _, upAt in ipairs({ 208, 384, 416, 464, 544, 560, 800, 1200 }) do
        reset()
        P0.sneaking = true
        pad(0).run = true
        local t = 0
        while t < upAt do
            if at >= 0 and t >= at then pad(0).x = 1.0 end
            frame(16); t = t + 16
        end
        pad(0).run = false; frame(16)
        presses = presses + 1
        local _, actMs = RS.lastAction(0)
        local held, tapped = #P0.calls > 0, P0.tappedFrom ~= nil
        if held then holds = holds + 1 end
        if tapped then taps = taps + 1 end
        if held and tapped and actMs >= P0.tappedFrom then
            both = both + 1
            print("  both: the stick at " .. at .. " ms, Run let go at " .. upAt .. " ms")
        end
        pad(0).x = 0; play(48)
    end
end
check("over " .. presses .. " presses none is both the game's tap and a hold here", both == 0, both)
check("and the sweep has both kinds", holds > 0 and taps > 0, holds .. " holds / " .. taps .. " taps")
TOGGLE_RUN = false

-- =========================================================================
section("Default layout (Run on a full stick push, no Run button): nothing at all")
KIND_RUN = "stick"
reset()
check("the switch is on", S.runSneakOn() == true)
check("runBindingKind: stick", RS.runBindingKind() == "stick", RS.runBindingKind())
pad(0).l3 = true; play(1000)
check("an L3 hold standing still: no stance change from ZeD", #P0.calls == 0 and P0.sneaking == false)
check("an L3 hold: the game's radial menu opens at 250 ms, as always", radialOpens(0) == 1, radialOpens(0))
pad(0).l3 = false; play(48)
pad(0).l3 = true; play(208); pad(0).l3 = false; play(48)
check("an L3 tap: the game's crouch toggle", P0.sneaking == true and P0.gameToggles == 1 and #P0.calls == 0)
reset()
pad(0).x = 0.5; pad(0).l3 = true; play(1000); pad(0).l3 = false; play(48)
check("moving with L3 held: no run, nothing of ZeD's", P0.runFrames == 0 and #P0.calls == 0)
reset()
pad(0).x = 1.0
play(1000)
check("a full push: the game's own run", P0.running == true and #P0.calls == 0)
P0.sneaking = true
play(1000)
check("crouched, a full push held 1 s: the game's sneak run, no stand-up", P0.sneaking == true and P0.running == true and #P0.calls == 0)
pad(0).x = 0
reset()
pad(0).run = true; play(1000); pad(0).run = false; play(48)
check("RT held standing still (not Run here): nothing", #P0.calls == 0 and P0.sneaking == false)
check("the module's state never left idle", RS.getState(0) == "idle", RS.getState(0))
KIND_RUN = "trigger"

-- =========================================================================
section("Gates (Original)")
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
frame(1500)                -- the game paused 1.5 s with Run held (player updates stop while paused)
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
SAFE = true
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("Safe mode: nothing", #P0.calls == 0)
SAFE = false
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
local old = P0
local fresh = newPlayer(0, 0)
pad(0).run = true; play(160)
PLAYERS[0] = fresh
play(800); pad(0).run = false; play(48)
check("a new character in the seat mid-hold: nothing for either", #old.calls == 0 and #fresh.calls == 0)
PLAYERS[0] = old

section("Gates: sitting, on a seat or on the ground")
reset()
P0.seated = true                  -- on a chair, a sofa, a bed (the game's own flag for it, not the ground one)
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("seated, a still hold: nothing", #P0.calls == 0 and P0.sneaking == false, #P0.calls)
reset()
P0.seated = true
pad(0).run = true; play(160)
P0.seated = false; pad(0).x = 1.0   -- getting up with Run still held, the stick pushed to flee
play(800)
check("got up with Run held: no crouch, no stand-up (the press began seated)", #P0.calls == 0 and P0.sneaking == false,
      #P0.calls)
check("and the game runs, standing", P0.running == true)
pad(0).run = false; pad(0).x = 0; play(48)
reset()
P0.sitting = true
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("sitting on the ground, a still hold: nothing", #P0.calls == 0)
reset()
pad(0).run = true; play(160)
P0.seated = true; play(600); P0.seated = false
pad(0).run = false; play(48)
check("sat down mid-hold: nothing", #P0.calls == 0)

section("Gates: the game's auto-walk is moving, not standing still")
reset()
P0.autoWalk = true; P0.autoDir = true   -- walking on its own, the stick at rest (the L3 menu's Auto walk)
play(48)
check("auto-walk walks with the stick at rest", P0:isPlayerMoving() == true and pad(0).x == 0)
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("auto-walking, a hold with the stick at rest: no crouch", #P0.calls == 0 and P0.sneaking == false, #P0.calls)
check("and no run either (the game's Run needs the stick)", P0.runFrames == 0, P0.runFrames)
P0.sneaking = true
pad(0).run = true; play(600); pad(0).run = false; play(48)
check("auto-walking crouched, a hold with the stick at rest: still crouched (the game does nothing there)",
      #P0.calls == 0 and P0.sneaking == true, #P0.calls)
pad(0).run = true; play(144)
pad(0).x = 1.0; play(352)          -- 336 ms after the push
check("auto-walking crouched, Run then the stick: no stand-up before 400 ms from the push", #P0.calls == 0
      and P0.sneaking == true, #P0.calls)
play(64)
check("then stood up and running", #P0.calls == 1 and P0.sneaking == false and P0.running == true, #P0.calls)
pad(0).run = false; pad(0).x = 0; play(48)
reset()
P0.autoWalk = true; P0.autoDir = true; P0.sneaking = true
play(48)
pad(0).run = true; play(800)       -- Run held 800 ms with the stick at rest: past the old 400 ms mark
check("auto-walking crouched, Run held 800 ms with the stick at rest: still crouched", #P0.calls == 0
      and P0.sneaking == true, #P0.calls)
check("and the press waits for the stick (held, not spent)", RS.getState(0) == "held", RS.getState(0))
pad(0).x = 1.0; play(352)          -- the stick pushed 800 ms in; now 336 ms after the push
check("then the stick, 800 ms in: no stand-up 336 ms after the push", #P0.calls == 0 and P0.sneaking == true, #P0.calls)
play(64)
check("400 ms after the push: stood up and running", #P0.calls == 1 and P0.sneaking == false and P0.running == true
      and RS.lastAction(0) == "stand-run", #P0.calls)
play(400)                          -- Run and the stick held 800 ms past the push in all
check("and one thing for the press", #P0.calls == 1, #P0.calls)
pad(0).run = false; pad(0).x = 0; play(48)
reset()
P0.autoWalk = true; P0.autoDir = true
play(48)
pad(0).run = true; play(800)
pad(0).x = 1.0; play(800)
check("auto-walking standing, Run held 800 ms, then the stick: the game's run, the stance left alone", #P0.calls == 0
      and P0.sneaking == false and P0.running == true, #P0.calls)
pad(0).run = false; pad(0).x = 0; play(48)
reset()
pad(0).run = true; play(160)
P0.autoWalk = true; P0.autoDir = true   -- the auto-walk walking from 160 ms in, the stick at rest
play(1200)
check("still at Run, walking on its own from 160 ms: no crouch at 400 ms or after (not still then)", #P0.calls == 0
      and P0.sneaking == false, #P0.calls)
pad(0).run = false; play(48)
reset()
P0.autoWalk = true                  -- switched on standing still: no direction yet, so not walking
play(48)
pad(0).run = true; play(448); pad(0).run = false; play(48)
check("auto-walk on with no direction yet is standing still: a hold crouches", #P0.calls == 1 and P0.sneaking == true,
      #P0.calls)

section("Gates: a walk the game does on its own (a path) is not standing still")
reset()
P0.path = { to = "a car seat" }     -- a walk-to (Enter from a few tiles away): the game walks, the stick at rest
play(48)
pad(0).run = true; play(600)
check("walking a path, a hold: nothing (Run did nothing there before)", #P0.calls == 0 and P0.sneaking == false, #P0.calls)
check("the press is spent", RS.getState(0) == "spent", RS.getState(0))
P0.path = nil                       -- the walk ends, Run still held
play(600); pad(0).run = false; play(48)
check("the walk over, the same press still does nothing", #P0.calls == 0)
pad(0).run = true; play(448); pad(0).run = false; play(48)
check("the next press works", #P0.calls == 1 and P0.sneaking == true, #P0.calls)
reset()
pad(0).run = true; play(160)
P0.path = { to = "a door" }         -- a walk begun mid-hold
play(600); P0.path = nil
pad(0).run = false; play(48)
check("a walk begun mid-hold: nothing", #P0.calls == 0)

-- =========================================================================
section("Toggle to run on, a press that waits for the stick: the game's tap or this hold, never both")
TOGGLE_RUN = true
reset()
P0.autoWalk = true; P0.autoDir = true; P0.sneaking = true
play(48)
pad(0).run = true; play(800)
pad(0).x = 1.0; play(320)
pad(0).run = false; frame(16)      -- Run let go 320 ms after the push
check("auto-walking crouched, Run 800 ms, then the stick, Run let go 320 ms after the push: the game's tap",
      P0.gameClicks == 1, P0.gameClicks)
check("and no stand-up here", #P0.calls == 0 and P0.sneaking == true, #P0.calls)
pad(0).x = 0; play(48)
reset()
P0.autoWalk = true; P0.autoDir = true; P0.sneaking = true
play(48)
pad(0).run = true; play(800)
pad(0).x = 1.0; play(608)
pad(0).run = false; frame(16)
check("the same, Run held 608 ms past the push: stood up, and not the game's tap", #P0.calls == 1
      and P0.sneaking == false and P0.gameClicks == 0, P0.gameClicks)
pad(0).x = 0; play(48)

-- One press, frame by frame: Run down from 0 ms to upAt, the stick set at the times in moves ({ ms, x }, in order).
-- Returns what this module did (acts: when, what, when the game's run press began, whether the stick or the
-- auto-walk moved the character), the game's taps (each run press it read as one: from, to), and the frames that
-- were due: the game's run press turning 400 ms old, crouched, in a press that had not acted (it must stand up in
-- that very frame), with how many of those it missed.
local function onePress(moves, upAt)
    local acts, taps, due, missed = {}, {}, 0, 0
    local mi = 1
    pad(0).run = true
    local t = 0
    while t <= upAt do
        while moves[mi] and moves[mi][1] <= t do pad(0).x = moves[mi][2]; mi = mi + 1 end
        if t == upAt then pad(0).run = false end
        local n, before, crouched = #P0.calls, #acts, P0.sneaking
        local moving = Movement:isApplied(0) or (P0.autoWalk and P0.autoDir)
        frame(16)
        if P0.tRun.clicked then taps[#taps + 1] = { from = P0.tRun.clickFrom, to = CLOCK } end
        local acted = #P0.calls > n
        if acted then
            acts[#acts + 1] = { ms = CLOCK, what = RS.lastAction(0), runFrom = P0.tRun.downMs, moving = moving }
        end
        if crouched and before == 0 and P0.tRun.downMs ~= 0 and CLOCK - P0.tRun.downMs == 400 then
            due = due + 1
            if not acted then missed = missed + 1 end
        end
        t = t + 16
    end
    return acts, taps, due, missed
end
local function newTally()
    return { presses = 0, both = 0, late = 0, unstill = 0, twice = 0, due = 0, missed = 0, holds = 0, taps = 0 }
end
-- both: an act inside a run press the game read as a tap; late: a stand-up not exactly 400 ms into the game's run
-- press; unstill: a crouch or a stand while the stick or the auto-walk moved the character; twice: a press that acted
-- more than once
local function tally(acc, acts, taps, due, missed)
    acc.presses, acc.due, acc.missed = acc.presses + 1, acc.due + due, acc.missed + missed
    if #acts > 1 then acc.twice = acc.twice + 1 end
    if #acts > 0 then acc.holds = acc.holds + 1 end
    if #taps > 0 then acc.taps = acc.taps + 1 end
    for _, a in ipairs(acts) do
        for _, tp in ipairs(taps) do if tp.from <= a.ms and a.ms < tp.to then acc.both = acc.both + 1 end end
        if a.what == "stand-run" and (a.runFrom == 0 or a.ms - a.runFrom ~= 400) then acc.late = acc.late + 1 end
        if (a.what == "crouch" or a.what == "stand") and a.moving then acc.unstill = acc.unstill + 1 end
    end
end
local function report(name, acc)
    check(name .. ": over " .. acc.presses .. " presses none is both the game's tap and a hold here", acc.both == 0, acc.both)
    check(name .. ": every stand-up exactly 400 ms into the game's run press", acc.late == 0, acc.late)
    check(name .. ": every crouch or stand with the character still", acc.unstill == 0, acc.unstill)
    check(name .. ": one thing per press", acc.twice == 0, acc.twice)
    check(name .. ": a crouched run press held 400 ms stands up, unless its Run press already acted", acc.missed == 0,
          acc.missed .. " of " .. acc.due .. " missed")
    check(name .. ": the sweep has holds, taps and run presses due", acc.holds > 0 and acc.taps > 0 and acc.due > 0,
          acc.holds .. " holds / " .. acc.taps .. " taps / " .. acc.due .. " due")
end
-- auto-walking (the stick at rest), crouched or standing: the stick pushed at 0 to 1200 ms or never, Run let go at
-- 208 to 2000 ms
local acc = newTally()
for _, crouch in ipairs({ true, false }) do
    for _, at in ipairs({ 0, 144, 384, 448, 800, 1200, -1 }) do
        for _, upAt in ipairs({ 208, 464, 800, 1008, 1264, 1600, 2000 }) do
            reset()
            P0.autoWalk = true; P0.autoDir = true; P0.sneaking = crouch
            play(48)
            tally(acc, onePress(at >= 0 and { { at, 1.0 } } or {}, upAt))
            pad(0).x = 0; play(48)
        end
    end
end
report("auto-walk sweep", acc)
-- moving at Run (the stick pushed first), crouched or standing: the stick let go at 64 to 640 ms and pushed again
-- 96 ms later, at 560 ms or at 1000 ms; Run let go at 464 to 1400 ms
acc = newTally()
for _, crouch in ipairs({ true, false }) do
    for _, off in ipairs({ 64, 160, 384, 448, 640 }) do
        for _, again in ipairs({ off + 96, 560, 1000 }) do
            if again > off then
                for _, upAt in ipairs({ 464, 800, 1008, 1400 }) do
                    reset()
                    P0.sneaking = crouch
                    pad(0).x = 1.0; play(32)
                    tally(acc, onePress({ { off, 0 }, { again, 1.0 } }, upAt))
                    pad(0).x = 0; play(48)
                end
            end
        end
    end
end
report("let go and push again sweep", acc)
-- seeded random presses, the same on every machine: crouched or standing; still, moving by the stick, auto-walking,
-- or auto-walk on with no direction yet; up to four stick changes; Run let go at 16 to 2000 ms
local seed = 20261112
local function rnd(n)   -- 0 to n - 1 (Park-Miller, exact in doubles)
    seed = (seed * 16807) % 2147483647
    return seed % n
end
acc = newTally()
for _ = 1, 1500 do
    reset()
    P0.sneaking = rnd(2) == 0
    local walk = rnd(4)
    if walk == 2 then P0.autoWalk = true; P0.autoDir = true elseif walk == 3 then P0.autoWalk = true end
    pad(0).x = (walk == 1) and 1.0 or 0
    play(48)
    local moves, t, x = {}, 0, pad(0).x
    for _ = 1, rnd(5) do
        t = t + 16 * (1 + rnd(50))
        x = (x == 0) and 1.0 or 0
        moves[#moves + 1] = { t, x }
    end
    tally(acc, onePress(moves, 16 * (1 + rnd(125))))
    pad(0).x = 0; play(48)
end
report("random sweep", acc)
TOGGLE_RUN = false

section("Bindings: any layout with Run on a button or a trigger works; a stick, a stick click or a bumper does not")
reset()
check("runBindingKind: trigger (Original, RT)", RS.runBindingKind() == "trigger", RS.runBindingKind())
KIND_RUN = "button"
check("runBindingKind: button (a player's own layout, Run on B)", RS.runBindingKind() == "button", RS.runBindingKind())
pad(0).run = true; play(352)
check("Run on B: no crouch before 400 ms", #P0.calls == 0)
play(96); pad(0).run = false; play(48)
check("Run on B: a still hold crouches", #P0.calls == 1 and P0.sneaking == true, #P0.calls)
pad(0).run = true; play(448); pad(0).run = false; play(48)
check("Run on B: a second hold stands", #P0.calls == 2 and P0.sneaking == false, #P0.calls)
pad(0).run = true; play(208); pad(0).run = false; play(48)
check("Run on B: a tap passes", #P0.calls == 2)
P0.sneaking = true
pad(0).x = 0.6; play(32)
pad(0).run = true; play(448)
check("Run on B: crouched and moving, the hold stands and the game runs", P0.sneaking == false and P0.running == true
      and #P0.calls == 3 and RS.lastAction(0) == "stand-run")
pad(0).run = false; play(32)
check("Run on B: let go, the game's run stops", P0.running == false)
pad(0).x = 0
reset()
KIND_RUN = "stickclick"
check("runBindingKind: stickclick (Run on L3)", RS.runBindingKind() == "stickclick", RS.runBindingKind())
pad(0).l3 = true; play(1000); pad(0).l3 = false; play(48)
check("Run on L3: refused, holding L3 changes nothing of ZeD's", #P0.calls == 0 and RS.getState(0) == "idle")
pad(0).x = 0.6; P0.sneaking = true; play(32)
pad(0).l3 = true; play(1000); pad(0).l3 = false; play(48)
check("Run on L3: crouched and moving, a hold stays the game's", P0.sneaking == true and #P0.calls == 0)
pad(0).x = 0
reset()
KIND_RUN = "stickclickR"
check("runBindingKind: stickclick (Run on R3)", RS.runBindingKind() == "stickclick", RS.runBindingKind())
pad(0).r3 = true; play(1000); pad(0).r3 = false; play(48)
check("Run on R3: refused, holding R3 changes nothing of ZeD's", #P0.calls == 0 and RS.getState(0) == "idle")
pad(0).x = 0.6; P0.sneaking = true; play(32)
pad(0).r3 = true; play(1000); pad(0).r3 = false; play(48)
check("Run on R3: crouched and moving, a hold stays the game's", P0.sneaking == true and #P0.calls == 0)
pad(0).x = 0
KIND_RUN = "stickaxis"
check("runBindingKind: one axis of a stick is a stick", RS.runBindingKind() == "stick", RS.runBindingKind())
-- a bumper held is the start of one of ZeD's quick actions, however long before the second button: Run there is
-- never a hold of this file's
reset()
KIND_RUN = "bumperR"
check("runBindingKind: bumper (Run on RB, a player's own layout)", RS.runBindingKind() == "bumper", RS.runBindingKind())
local bumpReads = BUMP_READS
pad(0).rb = true; play(1000); pad(0).rb = false; play(48)
check("Run on RB: refused, a long hold standing still changes nothing", #P0.calls == 0 and P0.sneaking == false
      and RS.getState(0) == "idle", RS.getState(0))
pad(0).x = 0.6; P0.sneaking = true; play(32)
pad(0).rb = true; play(1000)
check("Run on RB: crouched and moving, a hold stays the game's (its sneak run)", P0.sneaking == true and #P0.calls == 0
      and P0.running == true)
pad(0).rb = false; pad(0).x = 0; play(48)
KIND_RUN = "bumperL"
check("runBindingKind: bumper (Run on LB)", RS.runBindingKind() == "bumper", RS.runBindingKind())
P0.sneaking = false
pad(0).lb = true; play(1000); pad(0).lb = false; play(48)
check("Run on LB: refused", #P0.calls == 0 and RS.getState(0) == "idle", RS.getState(0))
check("Run on a bumper: the module never read LB, RB or Run", BUMP_READS == bumpReads, BUMP_READS - bumpReads)
KIND_RUN = "trigger"

section("Players: split screen")
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
RS.qaInput(0, { pad = true, held = true, moving = false })
play(448)
check("qaInput drives a player with no controller", #P0.calls == 1 and P0.sneaking == true)
RS.qaInput(0, { pad = true, held = false })
play(48)
RS.qaInput(0, nil)
play(48)
check("qaInput nil hands the player back (keyboard: idle)", RS.getState(0) == "idle")
P0.bind = 0

section("Everywhere")
check("the run flag was never set, in any section", FORCE_SETS == 0, FORCE_SETS)
check("the module never read L3, R3 or the Crouch binding", L3_READS == 0 and CROUCH_READS == 0, L3_READS .. "/" .. CROUCH_READS)
check("the game's radial menu code still untouched", ISJoystickButtonRadialMenu.onRepeatLeftStickButton == VANILLA_REPEAT)

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
      and not code:find("setForceRun", 1, true) and not code:find("setRunning", 1, true)
      and not code:find("setSprinting", 1, true) and not code:find("setForceSprint", 1, true)
      and not code:find("setAllowRun", 1, true) and not code:find("setAllowSprint", 1, true))
check("nothing of L3: no Crouch binding, no radial menu", not code:find("Crouch", 1, true)
      and not code:find("ISJoystickButtonRadialMenu", 1, true) and not code:find("LeftStick:isDown", 1, true)
      and not code:find("RightStick:isDown", 1, true))
check("the hook is OnPlayerUpdate, not OnTick", code:find("Events.OnPlayerUpdate.Add", 1, true) ~= nil
      and not code:find("Events.OnTick", 1, true))
check("timed with getTimestampMs", code:find("getTimestampMs()", 1, true) ~= nil)
check("sitting is the game's isSitting (the ground and a seat)", code:find('"isSitting"', 1, true) ~= nil)
check("a walk the game does on its own: hasPath", code:find('"hasPath"', 1, true) ~= nil)
check("the game's auto-walk: isAutoWalk with isPlayerMoving", code:find('"isAutoWalk"', 1, true) ~= nil
      and code:find('"isPlayerMoving"', 1, true) ~= nil)
check("Run on LB or RB is a kind of its own", code:find("btn == JoypadButton.LeftBump or btn == JoypadButton.RightBump", 1, true)
      ~= nil and code:find('return "bumper"', 1, true) ~= nil)

-- ---------------------------------------------------------------------------
-- WORDS
-- ---------------------------------------------------------------------------
section("Words")
check("English name", EN.UI_ZeD_Settings_RunSneak == "Run button also sneaks", EN.UI_ZeD_Settings_RunSneak)
local tip = EN.UI_ZeD_Settings_RunSneakTip or ""
check("English help: Run on a button works, as in Original (RT)", tip:find("Works when the game's Run is on a button", 1, true) ~= nil
      and tip:find("as in the Original controller layout (Run on the right trigger, RT)", 1, true) ~= nil)
check("English help: a full stick push (Default) does nothing", tip:find("does nothing when Run is a full push of the stick (the Default layout)", 1, true) ~= nil)
check("English help: Run on LB or RB does nothing, kept for the quick actions",
      tip:find("(the Default layout) or on LB or RB, which ZeD keeps for its quick actions.", 1, true) ~= nil)
check("English help: the hold and the tap", tip:find("hold Run to crouch", 1, true) ~= nil and tip:find("A quick tap", 1, true) ~= nil)
for _, l in ipairs(LANGS) do
    local t = UI[l] or {}
    local lt = t.UI_ZeD_Settings_RunSneakTip or ""
    check(l .. ": both keys", t.UI_ZeD_Settings_RunSneak ~= nil and t.UI_ZeD_Settings_RunSneakTip ~= nil)
    check(l .. ": names RT, never L3", lt:find("RT", 1, true) ~= nil and not lt:find("L3", 1, true))
    check(l .. ": names LB and RB", lt:find("LB", 1, true) ~= nil and lt:find("RB", 1, true) ~= nil)
end
local ar = (UI.AR or {}).UI_ZeD_Settings_RunSneakTip or ""
check("AR is Argentine Spanish (no Arabic letters)", not ar:find("\216[\128-\191]") and not ar:find("\217[\128-\191]"))
check("AR: voseo (mantene with its accent)", ar:find("manten\195\169", 1, true) ~= nil)

-- ---------------------------------------------------------------------------
-- QA STEPS
-- ---------------------------------------------------------------------------
section("QA steps (zedqa_run_sneak.lua)")
local qa = readFile(ROOT .. "ZeDUI/tools/qa/zedqa_run_sneak.lua") or ""
check("the QA script is there", #qa > 0)
-- a step of part B, by number: the text after "ORIGINAL n. "
local function handStep(n) return qa:match('"ORIGINAL ' .. n .. '%. ([^\n]*)"') or "" end
local QUARTER = "push the stick within about a quarter second of pressing RT"
check("B6: push the stick within about a quarter second of RT (a later push lets the still hold stand up first)",
      handStep(6):find(QUARTER, 1, true) ~= nil and handStep(6):find("stands up about half a second after the push", 1, true)
      ~= nil, handStep(6))
check("B10: the same quarter second before the game's tap", handStep(10):find(QUARTER, 1, true) ~= nil, handStep(10))
check("B8: RT held a second or more with the stick at rest, then the push: stands up half a second after the push",
      handStep(8):find("Keep holding RT a second or more, then push the stick", 1, true) ~= nil
      and handStep(8):find("stands up about half a second after the push", 1, true) ~= nil, handStep(8))
check("part A: a press that moved waits with the stick at rest, then a push long after Run stands up",
      qa:find("the stick let go 150 ms in: still crouched 600 ms after Run, the press waiting", 1, true) ~= nil
      and qa:find("and stood up by 700 ms after the second push", 1, true) ~= nil)

print(string.format("run_sneak_sim: %d checks, %d failed", checks, failed))
os.exit(failed == 0 and 0 or 1)
