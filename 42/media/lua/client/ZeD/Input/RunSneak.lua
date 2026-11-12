-- ZeD-UI/42/media/lua/client/ZeD/Input/RunSneak.lua
-- ============================================================================
-- RUN BUTTON ALSO SNEAKS: on a controller, the game's Run button crouches too.
-- Client. One floor of the controller stack, beside BumperChord: it polls the
-- game's own Run binding every tick, for each local player on a pad, and adds
-- one thing to a HOLD of it (400 ms, the game's own limit for a tap):
--   stick at rest      -> crouch, or stand up when crouched
--   moving, crouched   -> stand up; the game's run carries on while it is held
--   moving, standing   -> nothing: the game already runs while Run is held
-- The one thing to know: it never sends or swallows input. A tap, and the run
-- itself, stay the game's (a short run, Toggle to run's toggle, the Sprint
-- button, every stamina cost); the only call it makes is setSneaking, the
-- same one the game's own crouch button makes. Off by default (ZeD setup,
-- Controls), read every tick, so a change applies at once.
--
-- How the game runs on a pad (42.22, from its Java): each frame the character
-- runs while the movement stick is past its dead zone AND the Run binding is
-- down (CharacterInputComponent.isRunButtonDown). Run is a binding, not a
-- fixed button: the game's Original layout (the default) puts it on the right
-- trigger, its Default layout on a full push of the stick. A hold means
-- something here only when Run is a button or a trigger; on the stick, or on a
-- stick click (L3 / R3), this file does nothing.
--
-- Public interface:
--   ZeD.Input.RunSneak.HOLD_MS               how long a press must last to be a hold
--   ZeD.Input.RunSneak.runBindingKind()      "button" | "trigger" | "stickclick" | "stick" | "none"
--   ZeD.Input.RunSneak.getState(pn)          "idle" | "held" | "spent"
--   ZeD.Input.RunSneak.lastAction(pn)        "crouch" | "stand" | "stand-run" | nil, and its time
--   ZeD.Input.RunSneak.qaInput(pn, t)        QA stand-in for the pad (see below)
--   ZeD.Input.RunSneak.tick()                the OnTick handler (sims and QA call it too)
-- ============================================================================

-- Reload-safe: loading this file twice reuses the table instead of wiping it,
-- and guarding every level lets the Input/ files load in any order.
ZeD = ZeD or {}
ZeD.Input = ZeD.Input or {}
ZeD.Input.RunSneak = ZeD.Input.RunSneak or {}
local RS = ZeD.Input.RunSneak

-- The game's own tap limit: a press let go inside 400 ms is a click to it
-- (TimedInputHandler; Toggle to run toggles on one), so a press the game
-- reads as a tap is never also a hold here, and the other way round.
RS.HOLD_MS = 400
-- A gap this long between two ticks is a pause or a load, not a hold: the
-- press it spans does nothing (OnTick stops while the game is paused).
RS.GAP_MS = 1000

-- One record per local player (0-3), never one shared slot: split screen
-- gives each player a pad of their own.
--   down     Run was down at the last look
--   pressMs  when this press began (getTimestampMs, real milliseconds)
--   moved    the stick was past its dead zone at some point in this press
--   spent    this press has done its one thing, or never may (a tap stays a tap)
--   lastMs   the last look; nil means the next look starts fresh
--   act      the last thing done ("crouch", "stand", "stand-run") and actMs when
local _st = {}

-- QA stand-ins for the pad, by player number: { run = bool, moving = bool,
-- pad = bool }. A field left nil reads the real pad. pad = true counts a
-- player with no controller as on one (the QA machine has none).
local _qa = {}

-- Was the switch on at the last tick: turning it off forgets every press.
local _wasOn = false

-- First-failure latch: if a Java call ever throws (a patch renames it), the
-- error is printed once and the tick keeps going.
local _erred = false

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

-- The switch, read live. Off when Settings is missing or can't be read.
local function _on()
    local S = ZeD.Settings
    if not (S and S.runSneakOn) then return false end
    local ok, v = pcall(S.runSneakOn)
    return ok and v == true
end

-- Call a no-argument getter on a Java object. The game's Java side can
-- throw; pcall turns a crash into a nil we can test.
local function _call(o, name)
    local f = o[name]
    if not f then return nil end
    local ok, v = pcall(f, o)
    if ok then return v end
    return nil
end

local function _btnDown(btn, bind)
    if not btn then return false end
    local ok, v = pcall(btn.isDown, btn, bind)
    return ok and v == true
end

-- The game's Run binding, down on this controller (a trigger counts past the
-- binding's own threshold, as the game reads it).
local function _runDown(bind)
    local b = CharacterJoypadButtonBinding and CharacterJoypadButtonBinding.Run
    if not b or bind < 0 then return false end
    local ok, v = pcall(b.isDown, b, bind)
    return ok and v == true
end

-- "Moving" is the game's own test: the movement stick past the dead zone the
-- player set for that controller (JoypadManager.isMovementAxisBeingApplied),
-- through the Movement binding, so swapped sticks are honored.
local function _moving(p, bind)
    local m = CharacterJoypadAxis2dBinding and CharacterJoypadAxis2dBinding.Movement
    if m and bind >= 0 then
        local ok, v = pcall(m.isApplied, m, bind)
        if ok then return v == true end
    end
    return _call(p, "isPlayerMoving") == true
end

-- True while the pad drives this character and nothing else claims the
-- button: no window or menu holds the pad (ZeD's windows and the game's take
-- it the same way, setJoypadFocus), not paused, on foot, awake, not sitting,
-- climbing or aiming (in the Original layout Run is the trigger that attacks
-- while aiming), and no bumper held (a bumper with a face button is one of
-- ZeD's quick chords, which may sit on Run's button).
local function _free(pn, p, bind)
    if isGamePaused and isGamePaused() then return false end
    if getJoypadFocus and getJoypadFocus(pn) ~= nil then return false end
    if JoypadState and JoypadState.disableMovement then return false end
    if _call(p, "getVehicle") then return false end
    if _call(p, "isAsleep") or _call(p, "getIgnoreMovement") or _call(p, "isSitOnGround") then return false end
    if _call(p, "isClimbing") or _call(p, "isAiming") then return false end
    if bind >= 0 and JoypadButton and (_btnDown(JoypadButton.LeftBump, bind) or _btnDown(JoypadButton.RightBump, bind)) then
        return false
    end
    return true
end

--- What the game's Run is bound to: "button", "trigger", "stickclick" (L3 or
--- R3), "stick" (a stick push, the game's Default layout) or "none". A hold
--- means something only on "button" or "trigger"; a stick click is left alone
--- so nothing here ever changes state on L3 or R3.
function RS.runBindingKind()
    local b = CharacterJoypadButtonBinding and CharacterJoypadButtonBinding.Run
    if not b then return "none" end
    local ok, btn = pcall(b.getJoypadButton, b)
    if ok and btn ~= nil then
        if JoypadButton and (btn == JoypadButton.LeftStick or btn == JoypadButton.RightStick) then return "stickclick" end
        return "button"
    end
    local ok1, ax = pcall(b.getJoypadAxis1d, b)
    if ok1 and ax ~= nil then
        if JoypadAxis1d and (ax == JoypadAxis1d.LeftTrigger or ax == JoypadAxis1d.RightTrigger) then return "trigger" end
        return "stick"   -- (one axis of a stick)
    end
    local ok2, ax2 = pcall(b.getJoypadAxis2d, b)
    if ok2 and ax2 ~= nil then return "stick" end
    return "none"
end

-- ---------------------------------------------------------------------------
-- ONE PLAYER, ONE TICK
-- ---------------------------------------------------------------------------
local function _step(pn, now, usable)
    local st = _st[pn]
    if not st then
        st = { down = false, pressMs = 0, moved = false, spent = false, lastMs = nil, act = nil, actMs = 0 }
        _st[pn] = st
    end
    local p = getSpecificPlayer(pn)
    local q = _qa[pn]
    local bind = -1
    if p then
        local ok, b = pcall(p.getJoypadBind, p)
        if ok and type(b) == "number" then bind = b end
    end
    -- Keyboard and mouse (bind -1), nobody in that seat, or dead: nothing to
    -- do, and the next look at this player starts fresh.
    if not p or (bind < 0 and not (q and q.pad)) or _call(p, "isDead") then
        st.down, st.lastMs = false, nil
        return
    end
    local down
    if q and q.run ~= nil then down = q.run else down = _runDown(bind) end
    down = (down and usable) and true or false
    local moving
    if q and q.moving ~= nil then moving = q.moving else moving = _moving(p, bind) end
    local gap = st.lastMs and (now - st.lastMs) or nil
    st.lastMs = now

    if not down then
        st.down, st.spent, st.moved = false, false, false
        return
    end
    if not st.down then
        -- A fresh press. The first look at a button already held (the switch
        -- just turned on, a pad just joined) is not a press: it does nothing.
        st.down, st.pressMs, st.moved = true, now, moving
        st.spent = (gap == nil) or not _free(pn, p, bind)
        return
    end
    if st.spent then return end
    if moving then st.moved = true end
    if (gap and gap > RS.GAP_MS) or not _free(pn, p, bind) then
        st.spent = true
        return
    end
    if now - st.pressMs < RS.HOLD_MS then return end

    -- The hold: one thing per press.
    st.spent = true
    local sneaking = _call(p, "isSneaking") == true
    local act = nil
    if not st.moved and not moving then
        -- the stick stayed at rest the whole time: crouch, or stand
        act = sneaking and "stand" or "crouch"
        p:setSneaking(not sneaking)
    elseif moving and sneaking then
        -- crouched and moving: stand; the game's run takes the held button from here
        act = "stand-run"
        p:setSneaking(false)
    end
    -- (moving and standing: the game is already running; the stick let go
    -- part way through: no clear intent, so nothing)
    if act then
        st.act, st.actMs = act, now
        print(string.format("[ZeD.Input] run-sneak p%d: %s", pn, act))
    end
end

-- ---------------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------------

--- The tick: every local player, every frame the game runs. Events.OnTick
--- calls it; sims and QA scripts call it too.
function RS.tick()
    if not _on() then
        if _wasOn then _st = {} end
        _wasOn = false
        return
    end
    _wasOn = true
    local now = getTimestampMs()
    local kind = RS.runBindingKind()
    local usable = (kind == "button" or kind == "trigger")
    local n = (getNumActivePlayers and getNumActivePlayers()) or 1
    for pn = 0, n - 1 do
        local ok, err = pcall(_step, pn, now, usable)
        if not ok and not _erred then
            _erred = true
            print("[ZeD.Input] run-sneak FAILED: " .. tostring(err))
        end
    end
end

--- "idle" (Run up), "held" (a press that may still become a hold) or "spent"
--- (a hold that has done its thing, or a press that may not).
function RS.getState(pn)
    local st = _st[pn or 0]
    if not st or not st.down then return "idle" end
    return st.spent and "spent" or "held"
end

--- The last thing done for this player and when (getTimestampMs), or nil.
function RS.lastAction(pn)
    local st = _st[pn or 0]
    if not st then return nil, 0 end
    return st.act, st.actMs
end

--- QA: stand in for the pad. t = { run = bool, moving = bool, pad = bool };
--- a field left nil reads the real pad; t = nil hands the player back.
function RS.qaInput(pn, t)
    _qa[pn or 0] = t
end

-- ---------------------------------------------------------------------------
-- BOOTSTRAP
-- ---------------------------------------------------------------------------
-- A reload takes the old handler off before adding the new one, so the tick
-- never runs twice.
if RS._tickFn then Events.OnTick.Remove(RS._tickFn) end
RS._tickFn = RS.tick
Events.OnTick.Add(RS.tick)
