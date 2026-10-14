-- ZeD-UI/42/media/lua/client/ZeD/Input/InputModeDetector.lua
-- ============================================================================
-- LAYER 1 — InputModeDetector (S91 — Gamepad Phase 1 Infrastructure)
--
-- A singleton that polls raw input every tick and emits a single event when
-- the active input device changes between keyboard/mouse (KBM) and gamepad.
--
-- CORE RULE (Jibb Smart rule — see PZAPI-KB Q81): mouse MOVEMENT does NOT
-- count as KBM activity. Only mouse CLICKS and keyboard presses register.
-- Without this, the cursor drifting across the screen would constantly kick
-- us out of gamepad mode.
--
-- Do NOT use the vanilla helper wasMouseActiveMoreRecentlyThanJoypad() — it's
-- unreliable (returns stale values, doesn't distinguish click from move).
-- Every detection rule in this file is implemented from scratch.
--
-- Public interface (see GAMEPAD_SPEC.md §5):
--   ZeD.Input.Detector.getMode()             -> "kbm" | "gamepad" | "unknown"
--   ZeD.Input.Detector.getControllerType(i)  -> "xbox" | "playstation" | "nintendo" | "unknown"
--   ZeD.Input.Detector.setLockedMode(mode)   -> nil | "kbm" | "gamepad"
--
-- Event emitted (Add listener via standard PZ pattern):
--   Events.ZeD_InputModeChanged.Add(function(newMode, oldMode) ... end)
--
-- Tokens consumed (ZeD.T.gp — mirrored so they can be hot-tweaked via console):
--   stickThresh    radial deadzone for stick magnitude (default 0.20)
--   triggerThresh  abs threshold for triggers          (default 0.15)
--   cooldownMs     minimum ms between mode switches    (default 200)
-- ============================================================================

-- Tokens must be loaded before we poll so ZeD.T.gp is populated.
-- require is idempotent in PZ's Kahlua2, so this is safe even if Tokens.lua
-- was already pulled in by another file.
require "ZeD/Tokens"

-- Namespace: ZeD.Input.Detector
-- Guard all levels so this file can load in any order relative to siblings.
ZeD = ZeD or {}
ZeD.Input = ZeD.Input or {}
ZeD.Input.Detector = ZeD.Input.Detector or {}

local Detector = ZeD.Input.Detector

-- ---------------------------------------------------------------------------
-- MODE CONSTANTS (public)
-- ---------------------------------------------------------------------------
Detector.MODE_KBM     = "kbm"
Detector.MODE_GAMEPAD = "gamepad"
Detector.MODE_UNKNOWN = "unknown"

-- ---------------------------------------------------------------------------
-- INTERNAL STATE (file-local, not part of public API)
-- ---------------------------------------------------------------------------
-- Current active mode. Starts unknown until we see any input, then sticks
-- with whichever side spoke first.
local _mode = Detector.MODE_UNKNOWN

-- Manual lock from ModOptions. When set, getMode() returns this directly
-- and the polling tick keeps _mode in sync with the lock.
-- Values: nil (auto-detect) | "kbm" | "gamepad"
local _lockedMode = nil

-- Timestamp (ms since epoch) of the last mode switch. Used by the cooldown
-- logic in switchMode() so we don't thrash between devices that are both
-- active in the same 200ms window.
local _lastSwitchMs = 0

-- Edge-triggered KBM activity flags. Event listeners set these to true the
-- instant a keypress or mouse click lands; the polling tick reads and clears
-- them. This way "one click" counts as one event regardless of how long the
-- button is held, and we never see stale "true" values.
local _mouseClickedThisTick = false
local _keyPressedThisTick   = false

-- ---------------------------------------------------------------------------
-- SDL STANDARD CONTROLLER AXIS INDICES
-- PZ's getControllerAxisValue(controller, axisIdx) exposes the raw SDL axis
-- layout, which is standard across Xbox / PlayStation / Switch / Steam Deck.
-- Values are in [-1, 1] for sticks, [0, 1] (or [-1, 1] on some drivers) for
-- triggers — we abs() trigger reads defensively so both conventions work.
-- ---------------------------------------------------------------------------
local AXIS_LSTICK_X = 0
local AXIS_LSTICK_Y = 1
local AXIS_RSTICK_X = 2
local AXIS_RSTICK_Y = 3
local AXIS_LTRIGGER = 4
local AXIS_RTRIGGER = 5

-- ---------------------------------------------------------------------------
-- GAMEPAD BUTTONS WE CHECK FOR INTENT
-- Any press of any of these counts as "gamepad active". Stick clicks
-- (LeftStick, RightStick) are EXCLUDED — they fire accidentally under
-- combat tension (Hard Rule #11) and we don't want them kicking us out of
-- KBM mode.
--
-- Q109 (B42.17): was a list of Joypad.* integer constants paired with the
-- now-removed isJoypadPressed(id, const) global. Switched to JoypadButton.*
-- objects (polled below via :isDown(id)). Name-drift traps:
--   Joypad.AButton       -> JoypadButton.A        (drops "Button")
--   Joypad.LBumper       -> JoypadButton.LeftBump (NOT "LBump" — no-ops)
--   Joypad.RBumper       -> JoypadButton.RightBump
-- DPad* and Back/Start transfer 1:1.
-- ---------------------------------------------------------------------------
local _gamepadButtonsToCheck = {
    JoypadButton.A,        JoypadButton.B,         JoypadButton.X,        JoypadButton.Y,
    JoypadButton.LeftBump, JoypadButton.RightBump,
    JoypadButton.Back,     JoypadButton.Start,
    JoypadButton.DPadLeft, JoypadButton.DPadRight, JoypadButton.DPadUp,   JoypadButton.DPadDown,
}

-- ---------------------------------------------------------------------------
-- DETECTION PROBES
-- Each returns true if the corresponding device is active RIGHT NOW.
-- Probes are pure reads — no side effects. Mode decisions are made higher up.
-- ---------------------------------------------------------------------------

-- True if either stick is pushed past the radial deadzone.
-- Using sqrt(lx² + ly²) > threshold (radial) instead of per-axis thresholds:
-- diagonal drift on a worn stick can cleanly trip one axis at 0.18 while the
-- magnitude is still well under 0.20. Radial filters that cleanly.
local function stickActive(controllerIdx)
    local thresh = (ZeD.T and ZeD.T.gp and ZeD.T.gp.stickThresh) or 0.20
    -- Left stick
    local lx = getControllerAxisValue(controllerIdx, AXIS_LSTICK_X)
    local ly = getControllerAxisValue(controllerIdx, AXIS_LSTICK_Y)
    if math.sqrt(lx * lx + ly * ly) > thresh then return true end
    -- Right stick
    local rx = getControllerAxisValue(controllerIdx, AXIS_RSTICK_X)
    local ry = getControllerAxisValue(controllerIdx, AXIS_RSTICK_Y)
    if math.sqrt(rx * rx + ry * ry) > thresh then return true end
    return false
end

-- True if either trigger is held past threshold.
-- Drivers disagree on the released value: [0, 1] pads rest at 0, XInput pads
-- through GLFW rest at -1 (abs() of that reads as fully pressed and pinned
-- the mode to gamepad). So a pull is measured from each trigger's resting
-- value, the lowest it has read, over that trigger's full travel.
local _triggerRest = {}
local function triggerPulled(controllerIdx, axis, thresh)
    local v = getControllerAxisValue(controllerIdx, axis)
    local key = controllerIdx * 8 + axis
    local rest = _triggerRest[key]
    if rest == nil or v < rest then rest = v; _triggerRest[key] = v end
    local travel = (rest < -0.5) and 2 or 1
    return (v - rest) > thresh * travel
end
local function triggerActive(controllerIdx)
    local thresh = (ZeD.T and ZeD.T.gp and ZeD.T.gp.triggerThresh) or 0.15
    return triggerPulled(controllerIdx, AXIS_LTRIGGER, thresh) or triggerPulled(controllerIdx, AXIS_RTRIGGER, thresh)
end

-- True if any of our tracked gamepad buttons is currently held. Q109: the
-- table entries are JoypadButton objects now, so we dispatch via the colon
-- method. Dot-call (JoypadButton.A.isDown(id)) silently no-ops.
local function gamepadButtonActive(controllerIdx)
    for i = 1, #_gamepadButtonsToCheck do
        if _gamepadButtonsToCheck[i]:isDown(controllerIdx) then
            return true
        end
    end
    return false
end

-- True if ANY connected controller shows any kind of input activity.
-- We iterate all slots because a Steam Deck controller could be in slot 2
-- while a phantom in slot 0 sits idle.
local function anyGamepadActive()
    local n = getControllerCount()
    for i = 0, n - 1 do
        if isControllerConnected(i) then
            if stickActive(i) or triggerActive(i) or gamepadButtonActive(i) then
                return true
            end
        end
    end
    return false
end

-- True if a keyboard key or mouse BUTTON was pressed since last tick.
-- Edge-triggered via event listeners (set true in handlers, cleared in tick).
-- Mouse MOVEMENT does not set these flags — that's the Jibb Smart rule.
local function anyKBMActive()
    return _mouseClickedThisTick or _keyPressedThisTick
end

-- ---------------------------------------------------------------------------
-- MODE SWITCHING
-- Central gate: applies the 200ms cooldown and emits the public event.
-- All callers (onTick, setLockedMode, onGamepadDisconnect) route through here.
-- ---------------------------------------------------------------------------
local function switchMode(newMode)
    -- No-op if we're already in that mode.
    if newMode == _mode then return end
    -- Cooldown: ignore switch requests within cooldownMs of the last one.
    -- Handles the "both devices fire in the same 200ms window" case — the
    -- winner sticks and rapid alternation doesn't thrash. Note: first-ever
    -- switch always passes because _lastSwitchMs starts at 0.
    local cooldown = (ZeD.T and ZeD.T.gp and ZeD.T.gp.cooldownMs) or 200
    local t = getTimestampMs() or 0
    if (t - _lastSwitchMs) < cooldown then return end

    local oldMode = _mode
    _mode = newMode
    _lastSwitchMs = t

    -- Single-line, greppable debug trace. This is the ONLY user-visible
    -- signal of Phase 1 per the handoff — intentional, matches GAMEPAD_SPEC.
    print(string.format("[ZeD.Input] mode: %s -> %s", tostring(oldMode), tostring(newMode)))

    -- Fire the public event. Listeners registered via
    --   Events.ZeD_InputModeChanged.Add(fn)  get (newMode, oldMode).
    if triggerEvent then
        triggerEvent("ZeD_InputModeChanged", newMode, oldMode)
    end
end

-- ---------------------------------------------------------------------------
-- TICK POLL — called every frame by Events.OnTick
-- Evaluates detection probes and requests a mode switch. The manual lock
-- short-circuits auto-detection but still consumes edge flags so they don't
-- leak into auto mode when the lock is released later.
-- ---------------------------------------------------------------------------
local function onTick()
    -- Manual lock takes precedence. Keep _mode in sync so public getters
    -- return the locked value without going through the auto-detect path.
    if _lockedMode then
        if _mode ~= _lockedMode then
            switchMode(_lockedMode)
        end
        _mouseClickedThisTick = false
        _keyPressedThisTick   = false
        return
    end

    local gamepadNow = anyGamepadActive()
    local kbmNow     = anyKBMActive()

    -- Both active same frame: spec says last-event-wins. Our KBM flags are
    -- edge-triggered (set by handlers THIS tick), while gamepad probes are
    -- level-triggered (sticks/buttons can be held for many ticks). So if the
    -- KBM flag is set, that's a brand-new event this tick and wins over a
    -- held gamepad state. The 200ms cooldown in switchMode() still prevents
    -- rapid oscillation in pathological alternation cases.
    if gamepadNow and kbmNow then
        switchMode(Detector.MODE_KBM)
    elseif gamepadNow then
        switchMode(Detector.MODE_GAMEPAD)
    elseif kbmNow then
        switchMode(Detector.MODE_KBM)
    end

    -- Clear edge-triggered flags after this tick's consumption.
    _mouseClickedThisTick = false
    _keyPressedThisTick   = false
end

-- ---------------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------------

-- Current effective mode. Respects manual lock if one is set.
-- Returns "kbm" | "gamepad" | "unknown".
function Detector.getMode()
    return _lockedMode or _mode
end

-- Controller type string derived from the OS-reported device name.
-- Inspects getControllerName(joypadIdx) and matches known vendor keywords.
-- Returns "xbox" | "playstation" | "nintendo" | "unknown".
-- Unknown gracefully includes disconnected slots and generic devices that
-- don't self-identify cleanly (cheap Chinese knockoffs, Switch Pro clones).
function Detector.getControllerType(joypadIdx)
    joypadIdx = joypadIdx or 0
    if not isControllerConnected(joypadIdx) then return "unknown" end
    local name = getControllerName(joypadIdx)
    if not name then return "unknown" end
    -- Case-insensitive plain-text search. string.find with the `plain` arg
    -- (the 4th `true`) skips Lua pattern parsing — faster and avoids false
    -- matches on punctuation in odd device names.
    local lower = string.lower(name)
    if string.find(lower, "xbox", 1, true)
       or string.find(lower, "xinput", 1, true)
       or string.find(lower, "microsoft", 1, true) then
        return "xbox"
    end
    if string.find(lower, "dualsense", 1, true)
       or string.find(lower, "dualshock", 1, true)
       or string.find(lower, "playstation", 1, true)
       or string.find(lower, "sony", 1, true)
       or string.find(lower, "ps4", 1, true)
       or string.find(lower, "ps5", 1, true) then
        return "playstation"
    end
    if string.find(lower, "nintendo", 1, true)
       or string.find(lower, "switch", 1, true)
       or string.find(lower, "joy-con", 1, true)
       or string.find(lower, "joycon", 1, true)
       or string.find(lower, "pro controller", 1, true) then
        return "nintendo"
    end
    return "unknown"
end

-- Set a manual lock overriding auto-detection.
-- Pass nil (or false) to clear the lock and return to auto-detect.
-- Accepted values: nil | false | "kbm" | "gamepad".
-- Any other value is ignored with a warning so typos fail loudly.
function Detector.setLockedMode(mode)
    if mode == nil or mode == false then
        _lockedMode = nil
        return
    end
    if mode == Detector.MODE_KBM or mode == Detector.MODE_GAMEPAD then
        _lockedMode = mode
    else
        print(string.format("[ZeD.Input] WARNING: invalid locked mode '%s' ignored",
                            tostring(mode)))
    end
end

-- ---------------------------------------------------------------------------
-- EVENT LISTENERS
-- ---------------------------------------------------------------------------

-- Keyboard activity — any key press. Edge-triggered via OnKeyPressed so this
-- fires once per discrete press, not every frame the key is held. We don't
-- care which key — any keyboard input is a KBM signal.
local function onKeyPressed(_keyCode)
    _keyPressedThisTick = true
end

-- Mouse CLICK activity only. OnMouseDown fires exactly when a mouse button
-- goes down — movement doesn't trigger it. That's the whole point of using
-- this event instead of polling mouse position (see PZAPI-KB Q81).
local function onMouseDown(_x, _y)
    _mouseClickedThisTick = true
end

-- Controller disconnected: fall back to KBM IF no other controllers remain.
-- We don't force KBM if the user still has another controller plugged in.
-- Don't touch mode when a manual lock is active — the user's explicit.
local function onGamepadDisconnect(_index)
    if _lockedMode then return end
    if _mode ~= Detector.MODE_GAMEPAD then return end
    local n = getControllerCount()
    for i = 0, n - 1 do
        if isControllerConnected(i) then
            return -- still have at least one gamepad; stay in gamepad mode
        end
    end
    switchMode(Detector.MODE_KBM)
end

-- Controller connected: intentional no-op. We don't switch to gamepad mode
-- just because a controller was plugged in — wait for actual input (stick
-- nudge / button press) so a connect doesn't steal focus from a KBM session.
local function onGamepadConnect(_index)
    -- no-op by design
end

-- ---------------------------------------------------------------------------
-- BOOTSTRAP — declare event, wire listeners, announce ready.
-- This file is client-only (loaded from client/ZeD/Input/), so no isServer()
-- guard is needed. LuaEventManager.AddEvent is idempotent — safe to call.
-- ---------------------------------------------------------------------------
if LuaEventManager and LuaEventManager.AddEvent then
    LuaEventManager.AddEvent("ZeD_InputModeChanged")
end

Events.OnTick.Add(onTick)
Events.OnKeyPressed.Add(onKeyPressed)
Events.OnMouseDown.Add(onMouseDown)
Events.OnGamepadConnect.Add(onGamepadConnect)
Events.OnGamepadDisconnect.Add(onGamepadDisconnect)

-- Diagnostic one-liner so we can confirm the module loaded in-console.
print("[ZeD.Input] InputModeDetector loaded - awaiting first input event")
