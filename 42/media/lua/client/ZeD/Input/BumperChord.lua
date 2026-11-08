-- ZeD-UI/42/media/lua/client/ZeD/Input/BumperChord.lua
-- ============================================================================
-- BUMPER CHORD — combat zoom on the bumpers while no ZeD window holds the pad.
-- Client. One floor of the controller stack: InputModeDetector says which
-- device is live, this file owns LB / RB while nothing is focused, and
-- FocusManager turns it off (Chord.setEnabled) the moment a window claims
-- focus — the bumpers then swap windows through ActionMap — and back on at
-- release. It sees no events: it polls both bumpers every tick with its own
-- edge detection, so it works with no window open and nothing else on the pad.
--
-- THE CHORD:
--   Hold LB, tap RB  -> one zoom-OUT step
--   Hold RB, tap LB  -> one zoom-IN  step
--   Tap a bumper alone and release it  -> no-op (unowned)
--
-- NO ARMING TIMEOUT: LB_HELD / RB_HELD persist AS LONG AS that bumper is
-- physically held. Tap the opposite bumper any time during the hold — even
-- seconds later — and the chord fires. A 250ms arming window proved too
-- strict for natural thumb timing and made the chord feel unreliable, so it
-- went; the model matches Steam Input's own chords (hold indefinitely, tap
-- opposite to fire).
--
-- Multi-tap: while the first bumper is still held, every fresh tap of the
-- opposite bumper fires another zoom step. That's the CONSUMED-state
-- re-entry rule; see the onTick dispatcher below.
--
-- WHY NATIVE (not Steam Input): vanilla does zoom poorly on a pad, and the
-- mod must work out of the box — players shouldn't need to share Steam Input
-- configs. A player's own bumper bindings will fight the chord and need
-- clearing.
--
-- Public interface:
--   ZeD.Input.Chord.setEnabled(bool)   FocusManager: off at claim, on at release
--   ZeD.Input.Chord.getState()         -> "IDLE" | "LB_HELD" | "RB_HELD" | "CONSUMED"
--   ZeD.Input.Chord.isActive()         true while a chord is in progress
--
-- Events consumed:
--   Events.ZeD_InputModeChanged   resets state to IDLE on flip away from gamepad
--
-- Tokens consumed: none. The arming timeout read ZeD.T.gp.chordWindowMs; the
-- token still sits in Tokens.lua with no reader and can go.
--
-- PERF: zero per-tick allocation. All state lives in file-locals and the
-- dispatch is a plain if/elseif chain. Fine to run at 120fps indefinitely.
-- ============================================================================

-- Nothing here reads a token since the arming timeout left. The require is
-- harmless either way: require is idempotent in PZ's Kahlua2, so it's safe
-- even if Tokens.lua was already pulled in by a sibling in ZeD/Input/.
require "ZeD/Tokens"

-- Namespace: ZeD.Input.Chord
-- Reload-safe: loading this file twice reuses the tables instead of wiping
-- them, and guarding every level lets the Input/ files load in any order.
ZeD = ZeD or {}
ZeD.Input = ZeD.Input or {}
ZeD.Input.Chord = ZeD.Input.Chord or {}

local Chord = ZeD.Input.Chord

-- ---------------------------------------------------------------------------
-- STATE CONSTANTS (public on the namespace table for diagnostics)
-- ---------------------------------------------------------------------------
Chord.STATE_IDLE     = "IDLE"
Chord.STATE_LB_HELD  = "LB_HELD"
Chord.STATE_RB_HELD  = "RB_HELD"
Chord.STATE_CONSUMED = "CONSUMED"

-- ---------------------------------------------------------------------------
-- INTERNAL STATE (file-local, not part of public API)
-- ---------------------------------------------------------------------------
-- Current state-machine position. Transitions always go through _transition()
-- so the debug log stays consistent.
local _state = Chord.STATE_IDLE

-- Which bumper started the currently-tracked chord. "LB" -> zoom-OUT direction,
-- "RB" -> zoom-IN direction. Read by CONSUMED re-entry so we know which way
-- to zoom on a multi-tap. Only meaningful when _state != IDLE.
local _primary = nil

-- Last-tick held state for LB and RB. Edge detection is (down_now AND NOT
-- down_last) for press edges, (NOT down_now AND down_last) for release edges.
-- B42.17 removed isJoypadPressed(id, const); its replacement,
-- JoypadButton.<n>:isDown(id), returns level-triggered (held) state, so we
-- diff it ourselves.
local _lbDownLast = false
local _rbDownLast = false

-- Cached detector mode. Updated on ZeD_InputModeChanged event + snapshotted
-- at boot (in case the first event fired before we registered). We early-out
-- of onTick unless this is "gamepad" — no point polling bumpers in KBM mode.
local _mode = "unknown"

-- The kill switch. FocusManager calls setEnabled(false) when a window claims
-- focus (LB / RB swap windows there) and true when focus releases. Defaults
-- to true — the chord is live unless something turns it off.
local _enabled = true

-- First-failure latch for the zoom dispatch pcall. If getCore():doZoomScroll
-- ever throws (PZ patch signature drift), we log the error ONCE and keep
-- going — follow-up attempts still fire silently. This prevents log spam
-- when a broken build is mashing bumpers.
local _fireErroredOnce = false

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

-- Resolve player 0's active controller slot. Returns -1 if no controller is
-- connected to player 0. Re-read EVERY TICK, never cache at boot — hot-swap
-- (Steam Deck docking, USB reseat, pad swap) changes the .id mid-session and
-- we'd poll a stale slot otherwise.
local function _getJoypadIdx()
    if not getJoypadData then return -1 end
    local data = getJoypadData(0)
    if not data then return -1 end
    local id = data.id
    if id == nil then return -1 end
    return id
end

-- Log + swap state. One source of truth so every transition shows up in
-- console.txt in the same greppable format.
local function _transition(newState)
    if newState == _state then return end
    local oldState = _state
    _state = newState
    print(string.format("[ZeD.Input] chord: %s -> %s", tostring(oldState), tostring(newState)))
end

-- Cancel any in-progress chord and clear the direction memory. Called on
-- single-bumper release, mode flip away from gamepad, and both-bumpers-
-- released-after-CONSUMED.
local function _reset()
    _primary = nil
    _transition(Chord.STATE_IDLE)
end

-- Fire one zoom step. direction: +1 = zoom-in, -1 = zoom-out. Matches
-- getCore():doZoomScroll(playerIdx, direction) signature exactly; vanilla's
-- Tutorial/Steps.lua and ISBackButtonWheel.lua are the call-site precedent.
-- The game's Java side can throw if a future PZ patch renames or removes the
-- API; pcall turns that crash into a logged miss instead of a dead tick handler.
local function _fire(direction)
    local label = (direction > 0) and "zoom-in" or "zoom-out"
    print(string.format("[ZeD.Input] chord fire: %s", label))
    local ok, err = pcall(function()
        -- Player 0 only. Split-screen zoom would need a chord per player.
        getCore():doZoomScroll(0, direction)
    end)
    if (not ok) and (not _fireErroredOnce) then
        _fireErroredOnce = true
        print(string.format("[ZeD.Input] chord fire FAILED: %s", tostring(err)))
    end
end

-- ---------------------------------------------------------------------------
-- TICK DISPATCHER — called every frame by Events.OnTick
--
-- Ordering inside each state branch matters:
--   1. Fire-chord edge check (wins ties with release)
--   2. Bumper-released-without-chord check
-- Without this order, a user releasing LB on the same tick they tap RB
-- would no-op instead of fire. Thumb-roll users would lose half their
-- intended zooms.
--
-- LB_HELD / RB_HELD persist as long as the bumper is physically held —
-- there is no arming timeout (see the header for why).
-- ---------------------------------------------------------------------------
local function onTick()
    -- Gate 1: the kill switch (a focused window owns the bumpers).
    if not _enabled then return end

    -- Gate 2: Only run in gamepad mode. KBM players use mouse wheel to zoom;
    -- running this dispatcher on their session wastes cycles and risks
    -- accidentally firing if they happen to have a pad plugged in.
    if _mode ~= "gamepad" then return end

    -- Gate 3: Need a controller on slot 0. Re-read every tick — see
    -- _getJoypadIdx() doc for hot-swap reasoning.
    local joypadIdx = _getJoypadIdx()
    if joypadIdx < 0 then return end

    -- Read current level-triggered state for both bumpers (B42.17: poll via
    -- the JoypadButton.<n>:isDown(id) object API). Name-drift trap:
    -- LBumper/RBumper -> LeftBump/RightBump (not "LBump"/"RBump" which
    -- silently no-op).
    local lbDown = JoypadButton.LeftBump:isDown(joypadIdx)
    local rbDown = JoypadButton.RightBump:isDown(joypadIdx)

    -- Edge detection: compare current vs last-tick state.
    local lbPressEdge   = lbDown and (not _lbDownLast)
    local rbPressEdge   = rbDown and (not _rbDownLast)
    local lbReleaseEdge = (not lbDown) and _lbDownLast
    local rbReleaseEdge = (not rbDown) and _rbDownLast

    if _state == Chord.STATE_IDLE then
        -- Simultaneous LB+RB press on the same tick: resolve as LB-first,
        -- RB-arrived-same-frame -> fire zoom-out (LB primary). Matches the
        -- feel of "the chord fired" without a ghost tick in LB_HELD.
        -- Deterministic either way — direction just picked by rule.
        if lbPressEdge and rbPressEdge then
            _primary = "LB"
            _fire(-1) -- LB primary = zoom-out
            _transition(Chord.STATE_CONSUMED)
        elseif lbPressEdge then
            _primary = "LB"
            _transition(Chord.STATE_LB_HELD)
        elseif rbPressEdge then
            _primary = "RB"
            _transition(Chord.STATE_RB_HELD)
        end

    elseif _state == Chord.STATE_LB_HELD then
        -- Order matters here (see function header): rbPressEdge first so
        -- thumb-roll-off doesn't lose the fire when LB release lands on the
        -- same tick as RB press.
        if rbPressEdge then
            _fire(-1) -- LB-then-RB = zoom-out
            _transition(Chord.STATE_CONSUMED)
        elseif lbReleaseEdge then
            _reset() -- LB released without an RB tap — unowned single-tap
        end

    elseif _state == Chord.STATE_RB_HELD then
        -- Mirror of LB_HELD.
        if lbPressEdge then
            _fire(1) -- RB-then-LB = zoom-in
            _transition(Chord.STATE_CONSUMED)
        elseif rbReleaseEdge then
            _reset()
        end

    elseif _state == Chord.STATE_CONSUMED then
        -- CONSUMED re-entry for multi-tap: a fresh opposite-bumper edge fires
        -- another step while the first bumper remains held; stay in CONSUMED.
        -- Only exit when BOTH bumpers are fully released (clean slate).
        if _primary == "LB" and lbDown and rbPressEdge then
            _fire(-1) -- LB-primary = zoom-out
        elseif _primary == "RB" and rbDown and lbPressEdge then
            _fire(1)  -- RB-primary = zoom-in
        elseif (not lbDown) and (not rbDown) then
            _reset()
        end
    end

    -- Save last-tick state for next tick's edge detection. Must be the LAST
    -- thing the dispatcher does so that early returns above don't poison the
    -- edge computation for the next tick they run.
    _lbDownLast = lbDown
    _rbDownLast = rbDown
end

-- ---------------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------------

--- Enable / disable the chord dispatcher. FocusManager calls this with false
--- when a window claims focus (LB / RB become the window swap there) and true
--- when focus releases. Also callable from console for QA, e.g.
---   ZeD.Input.Chord.setEnabled(false)
function Chord.setEnabled(flag)
    -- Normalize truthy/falsy to strict bool for the gate check in onTick.
    _enabled = flag and true or false
    -- Cleanliness: if we're turning off mid-chord, reset so re-enable starts
    -- from a known-good IDLE state instead of an orphaned LB_HELD / RB_HELD.
    if not _enabled and _state ~= Chord.STATE_IDLE then
        _reset()
    end
end

--- Current state-machine position. Returns one of STATE_IDLE / STATE_LB_HELD
--- / STATE_RB_HELD / STATE_CONSUMED. Useful from console: "did we terminate
--- in IDLE after that rapid input?"
function Chord.getState()
    return _state
end

--- True while a chord is in progress. Equivalent to getState() ~= "IDLE" but
--- reads nicer at call sites that don't care which phase the chord is in.
function Chord.isActive()
    return _state ~= Chord.STATE_IDLE
end

-- ---------------------------------------------------------------------------
-- EVENT HANDLERS
-- ---------------------------------------------------------------------------

-- InputModeDetector flipped modes. Cache the new mode so onTick's gate check
-- runs against fresh data. If we're leaving gamepad mode mid-chord (user
-- grabbed the mouse), reset — otherwise the bumpers' level-triggered state
-- would leak into the next gamepad session.
local function onModeChanged(newMode, _oldMode)
    _mode = newMode or "unknown"
    if _mode ~= "gamepad" and _state ~= Chord.STATE_IDLE then
        _reset()
    end
end

-- ---------------------------------------------------------------------------
-- BOOTSTRAP — declare event defensively, wire listeners, announce ready.
-- File loads passively: nothing happens until OnTick starts firing and the
-- detector has had a chance to identify the active input device.
-- ---------------------------------------------------------------------------

-- File load order inside client/ZeD/Input/ is alphabetical, so this file
-- (BumperChord.lua) loads BEFORE InputModeDetector.lua. That means
-- Events.ZeD_InputModeChanged does NOT yet exist when this top-level runs.
-- We mirror InputModeDetector's own AddEvent call here to materialize the
-- event table up front — LuaEventManager.AddEvent is idempotent, so calling
-- it twice is safe; InputModeDetector's later call becomes a no-op.
if LuaEventManager and LuaEventManager.AddEvent then
    LuaEventManager.AddEvent("ZeD_InputModeChanged")
end

-- Snapshot initial mode if the detector is already loaded. If it isn't
-- (our load-order-first case), _mode stays "unknown" and the first
-- ZeD_InputModeChanged event from the detector will catch us up.
if ZeD.Input.Detector and ZeD.Input.Detector.getMode then
    _mode = ZeD.Input.Detector.getMode() or _mode
end

Events.OnTick.Add(onTick)
Events.ZeD_InputModeChanged.Add(onModeChanged)

-- One greppable line so the console confirms the module loaded.
print("[ZeD.Input] BumperChord loaded - no arming timeout, hold-and-tap model")
