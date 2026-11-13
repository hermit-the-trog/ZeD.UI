-- ZeD-UI/42/media/lua/client/ZeD/Input/RunSneak.lua
-- ============================================================================
-- RUN BUTTON ALSO SNEAKS: on a controller, the game's Run button crouches too.
-- Client. One floor of the controller stack, beside BumperChord. It reads the
-- game's own Run binding, for each local player on a pad, and adds one thing
-- to a HOLD of it (400 ms, the game's own limit for a tap):
--   standing still     -> crouch, or stand up when crouched
--   moving, crouched   -> stand up; the game's run carries on while it is held
--   moving, standing   -> nothing: the game already runs while Run is held
-- The one thing to know: it never sends or swallows a press, and the only
-- state it changes is the stance (setSneaking, the call the game's own crouch
-- makes). The run itself, its speed, stamina and Sprint stay the game's. Off
-- by default (ZeD setup, Controls); Safe mode turns it off too.
--
-- Which layouts (42.22, from its Java): Run is a binding, not a fixed button.
-- The game's Original layout (its default) puts Run on the right trigger, RT;
-- on a pad the game runs while the stick is past its dead zone AND Run is down
-- (CharacterInputComponent.isRunButtonDown), so a hold while moving already
-- runs, and standing still Run did nothing before. Any layout with Run on a
-- button or a trigger works the same, the Original one or a player's own,
-- except a stick click or a bumper (below). The Default layout has no Run
-- button (Run is a full push of the stick): there this file does nothing at
-- all. Run bound to L3 or R3 is left alone too: nothing here ever changes
-- state on a stick click, and the game's L3 radial menu is never touched. So
-- is Run on LB or RB: a bumper held is the start of one of ZeD's quick
-- actions (ZeD_QuickChords), however long it is held before the second
-- button, so a hold of one is never this file's.
--
-- Standing still means the character too, not only the stick: the game's
-- auto-walk walks with the stick at rest, and that is moving. Run does nothing
-- there in the game until the stick is pushed, and nothing here either: the
-- push, however long after Run went down, starts the hold as a fresh press
-- would. During a walk the game does on its own (to a door, a seat, a car) a
-- press does nothing here, as Run did nothing there before.
--
-- Public interface:
--   ZeD.Input.RunSneak.HOLD_MS               how long a press must last to be a hold
--   ZeD.Input.RunSneak.runBindingKind()      "button" | "trigger" | "bumper" | "stickclick" | "stick" | "none"
--   ZeD.Input.RunSneak.getState(pn)          "idle" | "held" | "spent"
--   ZeD.Input.RunSneak.lastAction(pn)        "crouch" | "stand" | "stand-run" | nil, and its time
--   ZeD.Input.RunSneak.qaInput(pn, t)        QA stand-in for the pad (see below)
--   ZeD.Input.RunSneak.onPlayerUpdate(p)     the OnPlayerUpdate handler (sims and QA call it too)
-- ============================================================================

-- Reload-safe: loading this file twice reuses the table instead of wiping it,
-- and guarding every level lets the Input/ files load in any order.
ZeD = ZeD or {}
ZeD.Input = ZeD.Input or {}
ZeD.Input.RunSneak = ZeD.Input.RunSneak or {}
local RS = ZeD.Input.RunSneak

-- The game's own tap limit: a press let go inside 400 ms is a click to it
-- (TimedInputHandler; Toggle to run toggles on one), so a press the game reads
-- as a tap is never also a hold here, and the other way round. Both read the
-- same clock (getTimestampMs is System.currentTimeMillis). The game's press
-- is Run AND the stick, though, not Run alone: it begins when the stick
-- leaves its rest with Run down. So a hold that moves is timed from that
-- moment too (see _step), or a Run press made standing still, then a push,
-- could reach 400 ms here while the game still saw a tap. For the same
-- reason a press that moved waits while the stick is at rest: the game has
-- no run press to time then.
RS.HOLD_MS = 400
-- A gap this long between two looks is a pause or a load, not a hold: the
-- press it spans does nothing (player updates stop while the game is paused).
RS.GAP_MS = 1000

-- One record per local player (0-3), never one shared slot: split screen
-- gives each player a pad of their own.
--   down     Run was down at the last look
--   pressMs  when the hold began: the Run press, or the stick's last push
--            during it (the game's own run press starts there)
--   stick    the stick was past its dead zone at the last look
--   moved    the character moved at some point in this press (the stick, or
--            the game's auto-walk): no still hold then, and while the stick
--            is at rest the press waits for its next push
--   spent    this press has done its one thing, or never may (a tap stays a tap)
--   lastMs   the last look; nil means the next look starts fresh
--   player   the character in this seat at the last look
--   act      the last thing done ("crouch", "stand", "stand-run") and actMs when
RS._st = RS._st or {}
local _st = RS._st

-- QA stand-ins for the pad, by player number: { held = bool, moving = bool,
-- pad = bool }. A field left nil reads the real pad (moving stands in for the
-- stick); pad = true counts a player with no controller as on one (the QA
-- machine has none).
RS._qa = RS._qa or {}
local _qa = RS._qa

-- First-failure latch: if a Java call ever throws (a patch renames it), the
-- error is printed once and the handler keeps going.
local _erred = false

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

-- The switch, read live. Off while ZeD's Safe mode holds, and when Settings
-- is missing or can't be read.
local function _on()
    local Safe = ZeD.Safe
    if Safe and Safe.on then
        local okS, safe = pcall(Safe.on)
        if okS and safe then return false end
    end
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

-- The stick is the game's own test: the movement stick past the dead zone the
-- player set for that controller (JoypadManager.isMovementAxisBeingApplied),
-- through the Movement binding, so swapped sticks are honored. It is the half
-- of the game's run press that is not Run.
local function _stick(p, bind)
    local m = CharacterJoypadAxis2dBinding and CharacterJoypadAxis2dBinding.Movement
    if m and bind >= 0 then
        local ok, v = pcall(m.isApplied, m, bind)
        if ok then return v == true end
    end
    return _call(p, "isPlayerMoving") == true
end

-- The game's auto-walk, walking: it moves the character with the stick at
-- rest (IsoPlayer.getInputMoveVector takes the auto-walk direction then).
-- isPlayerMoving is the game's own last-frame answer, so auto-walk switched on
-- with no direction yet still counts as standing still.
local function _autoWalking(p)
    return _call(p, "isAutoWalk") == true and _call(p, "isPlayerMoving") == true
end

-- True while the pad drives this character and nothing else claims the
-- button: no window or menu holds the pad (ZeD's windows and the game's take
-- it the same way, setJoypadFocus), not paused, on foot, awake, not sitting
-- (on the ground or on a seat: isSitting is both), not climbing or aiming (in
-- the Original layout Run is the trigger that attacks while aiming), not on a
-- walk the game does on its own (hasPath: a walk-to, to a seat or a car; Run
-- did nothing there before, the walk is the game's), and no bumper held (a
-- bumper with a face button is one of ZeD's quick chords).
local function _free(pn, p, bind)
    if isGamePaused and isGamePaused() then return false end
    if getJoypadFocus and getJoypadFocus(pn) ~= nil then return false end
    if JoypadState and JoypadState.disableMovement then return false end
    if _call(p, "getVehicle") then return false end
    if _call(p, "isAsleep") or _call(p, "getIgnoreMovement") or _call(p, "isSitting") then return false end
    if _call(p, "isClimbing") or _call(p, "isAiming") or _call(p, "hasPath") then return false end
    if bind >= 0 and JoypadButton and (_btnDown(JoypadButton.LeftBump, bind) or _btnDown(JoypadButton.RightBump, bind)) then
        return false
    end
    return true
end

--- What the game's Run is bound to: "button", "trigger", "bumper" (LB or
--- RB), "stickclick" (L3 or R3), "stick" (a stick push, the game's Default
--- layout, or one axis of a stick) or "none". A hold means something only on
--- "button" or "trigger" (the Original layout: RT).
function RS.runBindingKind()
    local b = CharacterJoypadButtonBinding and CharacterJoypadButtonBinding.Run
    if not b then return "none" end
    local ok, btn = pcall(b.getJoypadButton, b)
    if ok and btn ~= nil then
        if JoypadButton and (btn == JoypadButton.LeftStick or btn == JoypadButton.RightStick) then return "stickclick" end
        if JoypadButton and (btn == JoypadButton.LeftBump or btn == JoypadButton.RightBump) then return "bumper" end
        return "button"
    end
    local ok1, ax = pcall(b.getJoypadAxis1d, b)
    if ok1 and ax ~= nil then
        if JoypadAxis1d and (ax == JoypadAxis1d.LeftTrigger or ax == JoypadAxis1d.RightTrigger) then return "trigger" end
        return "stick"
    end
    local ok2, ax2 = pcall(b.getJoypadAxis2d, b)
    if ok2 and ax2 ~= nil then return "stick" end
    return "none"
end

-- ---------------------------------------------------------------------------
-- ONE PLAYER, ONE FRAME
-- ---------------------------------------------------------------------------
local function _step(p, pn, now)
    local st = _st[pn]
    if not st then
        st = { down = false, pressMs = 0, stick = false, moved = false, spent = false, lastMs = nil, player = nil,
               act = nil, actMs = 0 }
        _st[pn] = st
    end
    if st.player ~= p then
        -- a new character in this seat (a death, a new game): the old one's press is over
        st.player, st.down, st.lastMs = p, false, nil
    end
    local q = _qa[pn]
    local bind = -1
    local okB, b = pcall(p.getJoypadBind, p)
    if okB and type(b) == "number" then bind = b end
    -- Keyboard and mouse (bind -1) or dead: nothing to do, and the next look
    -- at this player starts fresh.
    if (bind < 0 and not (q and q.pad)) or _call(p, "isDead") then
        st.down, st.lastMs = false, nil
        return
    end
    -- No Run button this file uses in this layout (Default: Run is a full push
    -- of the stick; or Run on L3 / R3, or on a bumper): nothing at all, not
    -- even a look at the button.
    local kind = RS.runBindingKind()
    if kind ~= "button" and kind ~= "trigger" then
        st.down, st.lastMs = false, nil
        return
    end
    local down
    if q and q.held ~= nil then down = q.held else down = _runDown(bind) end
    down = down and true or false
    local gap = st.lastMs and (now - st.lastMs) or nil
    st.lastMs = now

    if not down then
        st.down, st.spent, st.moved = false, false, false
        return
    end
    -- a press that has done its one thing (or never may) only waits for the release
    if st.down and st.spent then return end
    local stick
    if q and q.moving ~= nil then stick = q.moving else stick = _stick(p, bind) end
    stick = stick and true or false
    local moving = stick or _autoWalking(p)
    if not st.down then
        -- A fresh press. The first look at a button already held (the switch
        -- just turned on, a pad just joined) is not a press: it does nothing.
        st.down, st.pressMs, st.stick, st.moved = true, now, stick, moving
        st.spent = (gap == nil) or not _free(pn, p, bind)
        return
    end
    if moving then st.moved = true end
    -- The stick just left its rest with Run down: the game's own run press
    -- (and its tap timer) starts now, so the hold starts again with it.
    if stick and not st.stick then st.pressMs = now end
    st.stick = stick
    if (gap ~= nil and gap > RS.GAP_MS) or not _free(pn, p, bind) then
        st.spent = true
        return
    end
    if now - st.pressMs < RS.HOLD_MS then return end
    -- Moved in this press, but the stick is at rest now (let go, or the
    -- game's auto-walk walking on its own): the game has no run press then,
    -- and Run alone does nothing, so the press waits, unspent. The stick's
    -- next push starts the hold again (above), as it starts the game's run.
    if st.moved and not stick then return end

    -- The hold: one thing per press.
    st.spent = true
    local sneaking = _call(p, "isSneaking") == true
    local act = nil
    if not st.moved then
        -- standing still the whole time, the stick and the character: crouch, or stand
        act = sneaking and "stand" or "crouch"
        p:setSneaking(not sneaking)
    elseif stick and sneaking then
        -- crouched, with the game's own run press held past a tap: stand; the
        -- game's run takes the held button from here
        act = "stand-run"
        p:setSneaking(false)
    end
    -- (moving and standing: the game is already running, so nothing)
    if act then
        st.act, st.actMs = act, now
        print(string.format("[ZeD.Input] run-sneak p%d: %s", pn, act))
    end
end

-- ---------------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------------

--- OnPlayerUpdate: each local player's own update, once a frame, before the
--- game reads that player's input, so a stand-up lands in the same frame as
--- the game's run.
function RS.onPlayerUpdate(p)
    if not p then return end
    local okN, pn = pcall(p.getPlayerNum, p)
    if not okN or type(pn) ~= "number" or pn < 0 or getSpecificPlayer(pn) ~= p then return end
    if not _on() then
        -- off (or Safe mode): forget the press, so turning it on mid-hold does nothing
        local st = _st[pn]
        if st then st.down, st.lastMs = false, nil end
        return
    end
    local ok, err = pcall(_step, p, pn, getTimestampMs())
    if not ok and not _erred then
        _erred = true
        print("[ZeD.Input] run-sneak FAILED: " .. tostring(err))
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

--- QA: stand in for the pad. t = { held = bool, moving = bool, pad = bool }
--- (moving stands in for the stick); a field left nil reads the real pad;
--- t = nil hands the player back.
function RS.qaInput(pn, t)
    _qa[pn or 0] = t
end

-- ---------------------------------------------------------------------------
-- BOOTSTRAP
-- ---------------------------------------------------------------------------
-- A reload takes the old handler off before adding the new one, so it never
-- runs twice in a frame.
if RS._updFn then Events.OnPlayerUpdate.Remove(RS._updFn) end
RS._updFn = RS.onPlayerUpdate
Events.OnPlayerUpdate.Add(RS.onPlayerUpdate)
