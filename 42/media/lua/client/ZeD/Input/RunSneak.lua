-- ZeD-UI/42/media/lua/client/ZeD/Input/RunSneak.lua
-- ============================================================================
-- RUN AND SNEAK ON ONE BUTTON: on a controller, one button runs and crouches.
-- Client. One floor of the controller stack, beside BumperChord. Which button
-- follows the game's controller layout (Options > Controller):
--   Run on a button or trigger (the Original layout, the game's default: RT)
--       -> the Run button. The game already runs while it is held with the
--          stick pushed; this adds the crouch.
--   Run on a full push of the stick (the Default layout)
--       -> the game's Crouch button (L3). A tap is still the game's crouch
--          toggle; a hold while moving runs, on the game's own run flag.
-- A HOLD is 400 ms, the game's own limit for a tap, so a press is one or the
-- other, never both:
--   stick at rest      -> crouch, or stand up when crouched
--   moving, crouched   -> stand up, and run while it is held
--   moving, standing   -> run while it is held (on the Run button the game is
--                         already running: nothing to do)
-- The one thing to know: it never sends or swallows a press, and the only
-- state it changes is the stance (setSneaking, as the game's crouch does) and,
-- on the Default layout, the game's run flag (setForceRun, the flag the game's
-- "Toggle to run" drives). Speed, stamina and Sprint stay the game's. Off by
-- default (ZeD setup, Controls); Safe mode turns it off too.
--
-- WHY OnPlayerUpdate, not OnTick (42.22, from its Java): every frame the game
-- first steps each player's input (CharacterInputComponent.frameStep, which
-- clears the run flag whenever "Toggle to run" is off), then updates the
-- player: OnPlayerUpdate fires, then the input is read (UpdateInputState:
-- running is the stick past its dead zone with Run down, OR the run flag). A
-- flag set on OnTick, at the end of the frame, is cleared before the next
-- read; one set on OnPlayerUpdate holds for that frame's read. So the run is
-- set again on every frame the button is held, and can't outlast it: with
-- "Toggle to run" off the game clears it on the next frame by itself; with it
-- on (the game keeps the flag then) the release puts back what was there.
--
-- Public interface:
--   ZeD.Input.RunSneak.HOLD_MS               how long a press must last to be a hold
--   ZeD.Input.RunSneak.holdMode()            "run" | "crouch" | nil, and that binding
--   ZeD.Input.RunSneak.runBindingKind()      "button" | "trigger" | "stickclick" | "stick" | "none"
--   ZeD.Input.RunSneak.ownsHold(pn, btn)     true while a hold of btn is this file's for player pn
--   ZeD.Input.RunSneak.getState(pn)          "idle" | "held" | "spent" | "running"
--   ZeD.Input.RunSneak.lastAction(pn)        "crouch" | "stand" | "stand-run" | "run" | nil, and its time
--   ZeD.Input.RunSneak.qaInput(pn, t)        QA stand-in for the pad (see below)
--   ZeD.Input.RunSneak.onPlayerUpdate(p)     the OnPlayerUpdate handler (sims and QA call it too)
-- ============================================================================

require "ISUI/ISJoystickButtonRadialMenu"

-- Reload-safe: loading this file twice reuses the table instead of wiping it,
-- and guarding every level lets the Input/ files load in any order.
ZeD = ZeD or {}
ZeD.Input = ZeD.Input or {}
ZeD.Input.RunSneak = ZeD.Input.RunSneak or {}
local RS = ZeD.Input.RunSneak

-- The game's own tap limit: a press let go inside 400 ms is a click to it
-- (TimedInputHandler: the Crouch button's toggle, Toggle to run's toggle), so a
-- press the game reads as a tap is never also a hold here, and the other way
-- round. Both read the same clock (getTimestampMs is System.currentTimeMillis).
RS.HOLD_MS = 400
-- A gap this long between two looks is a pause or a load, not a hold: the press
-- it spans does nothing (player updates stop while the game is paused).
RS.GAP_MS = 1000

-- One record per local player (0-3), never one shared slot: split screen gives
-- each player a pad of their own. Kept on the module, so a reload still knows
-- which run it is holding.
--   down     the hold button was down at the last look
--   pressMs  when this press began (getTimestampMs, real milliseconds)
--   moved    the stick was past its dead zone at some point in this press
--   spent    this press has had its turn, or never may (a tap stays a tap)
--   mode     the layout's mode when the press began ("run" or "crouch")
--   forcing  the run flag is being held for this press, on forceOn (the
--            character it was set on); forceWas is the flag before the hold
--   lastMs   the last look; nil means the next look starts fresh
--   act      the last thing done and actMs when
RS._st = RS._st or {}
local _st = RS._st

-- QA stand-ins for the pad, by player number: { held = bool, moving = bool,
-- pad = bool, mode = "run" | "crouch" }. A field left nil reads the real pad or
-- layout; pad = true counts a player with no controller as on one.
RS._qa = RS._qa or {}
local _qa = RS._qa

-- First-failure latch: a throw is printed once, and every frame it happens the
-- run flag is still let go.
local _erred = false

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

-- The switch, read live. Off while ZeD's Safe mode holds, and when Settings is
-- missing or can't be read.
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

-- A game binding down on this controller (a trigger counts past the binding's
-- own threshold, as the game reads it).
local function _isDown(b, bind)
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

-- What a game binding is on: "button", "trigger", "stickclick" (L3 or R3),
-- "stick" (a stick push, or one axis of a stick) or "none".
local function _kind(b)
    if not b then return "none" end
    local ok, btn = pcall(b.getJoypadButton, b)
    if ok and btn ~= nil then
        if JoypadButton and (btn == JoypadButton.LeftStick or btn == JoypadButton.RightStick) then return "stickclick" end
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

--- What the game's Run is bound to (see _kind).
function RS.runBindingKind()
    return _kind(CharacterJoypadButtonBinding and CharacterJoypadButtonBinding.Run)
end

--- Which button a hold is read on, from the game's controller layout:
---   "run", Run      Run is on a button or a trigger (the Original layout: RT)
---   "crouch", Crouch Run is a push of the stick or a stick click (the Default
---                   layout): the game's Crouch button (L3 there)
---   nil             neither is on a button
function RS.holdMode()
    local C = CharacterJoypadButtonBinding
    if not C then return nil, nil end
    local rk = _kind(C.Run)
    if rk == "button" or rk == "trigger" then return "run", C.Run end
    local ck = _kind(C.Crouch)
    if ck == "button" or ck == "trigger" or ck == "stickclick" then return "crouch", C.Crouch end
    return nil, nil
end

-- True while the pad drives this character and nothing else claims the
-- button: no window or menu holds the pad (ZeD's windows and the game's take
-- it the same way, setJoypadFocus), not paused, on foot, awake, not sitting,
-- climbing or aiming (in the Original layout Run is the trigger that attacks
-- while aiming), and no bumper held (a bumper with a face button or a stick
-- click is one of ZeD's quick chords).
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

-- The game's own conditions on running: Run allowed for this character (the
-- game's run check asks it), and not in the first moments of a climb through
-- a window or over a fence (the game drops its own run flag there,
-- shouldAllowForceRunOrSprint).
local function _canRun(p)
    if _call(p, "isAllowRun") == false then return false end
    local ok1, w = pcall(p.getVariableBoolean, p, "ClimbWindowStarted")
    if ok1 and w then return false end
    local ok2, f = pcall(p.getVariableBoolean, p, "ClimbFenceStarted")
    if ok2 and f then return false end
    return true
end

-- Let go of the run this press held, on the character it was held on. A flag
-- that was already on when the hold began (the player's own Toggle to run) is
-- left on: it is theirs.
local function _release(st)
    if not st.forcing then return end
    st.forcing = false
    local p = st.forceOn
    st.forceOn = nil
    if p and not st.forceWas then pcall(p.setForceRun, p, false) end
end

-- ---------------------------------------------------------------------------
-- ONE PLAYER, ONE FRAME
-- ---------------------------------------------------------------------------
local function _step(p, pn, now)
    local st = _st[pn]
    if not st then
        st = { down = false, pressMs = 0, moved = false, spent = false, mode = nil, forcing = false,
               forceWas = false, forceOn = nil, lastMs = nil, player = nil, act = nil, actMs = 0 }
        _st[pn] = st
    end
    if st.player ~= p then
        -- a new character in this seat (a death, a new game): the old one's press is over
        _release(st)
        st.player, st.down, st.lastMs = p, false, nil
    end
    local q = _qa[pn]
    local bind = -1
    local okB, b = pcall(p.getJoypadBind, p)
    if okB and type(b) == "number" then bind = b end
    -- Keyboard and mouse (bind -1) or dead: nothing to do, and the next look
    -- at this player starts fresh.
    if (bind < 0 and not (q and q.pad)) or _call(p, "isDead") then
        _release(st)
        st.down, st.lastMs = false, nil
        return
    end
    local mode, binding
    if q and q.mode ~= nil then
        local C = CharacterJoypadButtonBinding
        mode = q.mode
        binding = C and ((mode == "run") and C.Run or C.Crouch)
    else
        mode, binding = RS.holdMode()
    end
    local down
    if q and q.held ~= nil then down = q.held else down = _isDown(binding, bind) end
    down = (mode ~= nil and down) and true or false
    local moving
    if q and q.moving ~= nil then moving = q.moving else moving = _moving(p, bind) end
    local gap = st.lastMs and (now - st.lastMs) or nil
    st.lastMs = now

    if not down then
        _release(st)
        st.down, st.spent, st.moved, st.mode = false, false, false, nil
        return
    end
    if not st.down then
        -- A fresh press. The first look at a button already held (the switch
        -- just turned on, a pad just joined) is not a press: it does nothing.
        st.down, st.pressMs, st.moved, st.mode = true, now, moving, mode
        st.spent = (gap == nil) or not _free(pn, p, bind)
        return
    end
    local broke = (gap ~= nil and gap > RS.GAP_MS) or mode ~= st.mode or not _free(pn, p, bind)
    if st.forcing then
        if broke or not _canRun(p) then
            _release(st)
            st.spent = true
            return
        end
        p:setForceRun(true)   -- again every frame: the game's frame step clears it
        return
    end
    if st.spent then return end
    if moving then st.moved = true end
    if broke then
        st.spent = true
        return
    end
    if now - st.pressMs < RS.HOLD_MS then return end

    -- The hold: one decision per press.
    st.spent = true
    local sneaking = _call(p, "isSneaking") == true
    local act = nil
    if not st.moved and not moving then
        -- the stick stayed at rest the whole time: crouch, or stand
        act = sneaking and "stand" or "crouch"
        p:setSneaking(not sneaking)
    elseif moving then
        if sneaking then
            act = "stand-run"
            p:setSneaking(false)
        end
        -- On the Run button the game runs on its own from here. On the Crouch
        -- button the run is the game's own run flag, held while the button is.
        if mode == "crouch" and _canRun(p) then
            st.forceWas = _call(p, "isForceRun") == true
            st.forceOn, st.forcing = p, true   -- (noted before the call, so a failure after it still lets go)
            p:setForceRun(true)
            act = act or "run"
        end
    end
    -- (the stick let go part way through: no clear intent, so nothing)
    if act then
        st.act, st.actMs = act, now
        print(string.format("[ZeD.Input] run-sneak p%d: %s", pn, act))
    end
end

-- ---------------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------------

--- OnPlayerUpdate: each local player, each frame the game runs, after the
--- game's input step and before it reads the input (see the header).
function RS.onPlayerUpdate(p)
    if not p then return end
    local okN, pn = pcall(p.getPlayerNum, p)
    if not okN or type(pn) ~= "number" or pn < 0 or getSpecificPlayer(pn) ~= p then return end
    if not _on() then
        -- off (or Safe mode): let go of any run held, forget the press
        local st = _st[pn]
        if st then
            _release(st)
            st.down, st.lastMs = false, nil
        end
        return
    end
    local ok, err = pcall(_step, p, pn, getTimestampMs())
    if not ok then
        local st = _st[pn]
        if st then
            pcall(_release, st)
            st.spent = true
        end
        if not _erred then
            _erred = true
            print("[ZeD.Input] run-sneak FAILED: " .. tostring(err))
        end
    end
end

--- True while a hold of the controller button btn is this file's for player
--- pn: the switch is on and the layout makes btn the Crouch hold (the Default
--- layout's L3). The game's L3 menu stays shut then (below).
function RS.ownsHold(pn, btn)
    if not btn or not _on() then return false end
    local q = _qa[pn or 0]
    local mode, b
    if q and q.mode ~= nil then
        mode = q.mode
        b = CharacterJoypadButtonBinding and CharacterJoypadButtonBinding.Crouch
    else
        mode, b = RS.holdMode()
    end
    if mode ~= "crouch" or not b then return false end
    local ok, jb = pcall(b.getJoypadButton, b)
    return ok and jb ~= nil and jb == btn
end

--- "idle" (the button up), "held" (a press that may still become a hold),
--- "running" (a hold holding the run flag) or "spent".
function RS.getState(pn)
    local st = _st[pn or 0]
    if not st or not st.down then return "idle" end
    if st.forcing then return "running" end
    return st.spent and "spent" or "held"
end

--- The last thing done for this player and when (getTimestampMs), or nil.
function RS.lastAction(pn)
    local st = _st[pn or 0]
    if not st then return nil, 0 end
    return st.act, st.actMs
end

--- QA: stand in for the pad. t = { held = bool, moving = bool, pad = bool,
--- mode = "run" | "crouch" }; a field left nil reads the real pad or layout;
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

-- The game's left joystick radial menu (crouch, sit, auto-walk) opens after
-- 250 ms of L3 held, before a 400 ms hold could count. While L3 is this file's
-- hold button (the switch on, the Default layout) it stays shut; ZeD's D-pad
-- wheels carry the same three. Keep the vanilla function once, so a Lua reload
-- never wraps the wrapper.
if ISJoystickButtonRadialMenu and ISJoystickButtonRadialMenu.onRepeatLeftStickButton and not RS._zedOrigRepeatLeft then
    RS._zedOrigRepeatLeft = ISJoystickButtonRadialMenu.onRepeatLeftStickButton
    ISJoystickButtonRadialMenu.onRepeatLeftStickButton = function(joypadData)
        local pn = joypadData and joypadData.player
        if pn ~= nil and JoypadButton and RS.ownsHold(pn, JoypadButton.LeftStick) then return end
        return RS._zedOrigRepeatLeft(joypadData)
    end
end
