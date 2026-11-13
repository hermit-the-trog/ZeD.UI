-- ZeD-UI/42/media/lua/client/ZeD/Input/BumperChord.lua
-- ============================================================================
-- BUMPER CHORD — combat zoom on the bumpers while no ZeD window holds the pad.
-- Client. One floor of the controller stack: InputModeDetector says which
-- device is live, this file owns LB / RB while nothing is focused, and
-- FocusManager turns it off (Chord.setEnabled) the moment a window claims
-- focus — the bumpers then pick a window through ActionMap (LB Character,
-- RB World) — and back on at release. It gets no button events: it polls
-- both bumpers every tick with its own edge detection, so it works with no
-- window open and nothing else on the pad.
--
-- THE CHORD:
--   Hold LB, tap RB  -> one zoom-IN  step
--   Hold RB, tap LB  -> one zoom-OUT step
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
-- SPLIT-SCREEN: one chord a local player, each read from that player's own
-- pad and zooming that player's view. Player 1's runs as it always did.
-- Players 2-4 poll only while ZeD's windows are theirs (ZeD.windowsFor) and
-- they are playing (their pad bound to them, their character alive); until
-- then their bumpers stay the game's. A missing pn below means player 1.
--
-- Public interface:
--   ZeD.Input.Chord.setEnabled(bool, pn?)   FocusManager: off at claim, on at release
--   ZeD.Input.Chord.getState(pn?)          -> "IDLE" | "LB_HELD" | "RB_HELD" | "CONSUMED"
--   ZeD.Input.Chord.isActive(pn?)          true while a chord is in progress
--
-- Events consumed:
--   Events.ZeD_InputModeChanged   resets player 1's chord to IDLE on flip away from gamepad
--   Events.OnCreatePlayer, Events.OnPlayerDeath   a player's chord starts over
--
-- Tokens consumed: none. The arming timeout read ZeD.T.gp.chordWindowMs; the
-- token still sits in Tokens.lua with no reader and can go.
--
-- PERF: zero per-tick allocation. All state lives in one small record a
-- player and the dispatch is a plain if/elseif chain. Fine to run at 120fps
-- indefinitely.
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
-- One record a local player (pn 0-3, 0 = player 1), made on first use; player
-- 1's fields are the file locals this module had before split-screen:
--   state    the state machine's position; changes go through _transition()
--            so the debug log stays consistent
--   primary  which bumper started the chord: "LB" zoom-in, "RB" zoom-out;
--            read by CONSUMED re-entry for a multi-tap. Only meaningful when
--            state is not IDLE
--   lbLast, rbLast  both bumpers' levels last tick. B42.17 removed
--            isJoypadPressed(id, const); its replacement,
--            JoypadButton.<n>:isDown(id), is level-triggered (held), so the
--            edges are diffed here: press = down now and not last tick
--   enabled  the kill switch. FocusManager calls setEnabled(false, pn) when a
--            window claims that player's focus (LB / RB swap windows there)
--            and true when it releases. True by default
-- Fresh on every load.
local _rec = {}
local function _C(pn)
    if type(pn) ~= "number" then pn = 0 end
    local c = _rec[pn]
    if c == nil then
        c = { pn = pn, state = Chord.STATE_IDLE, primary = nil, lbLast = false, rbLast = false, enabled = true }
        _rec[pn] = c
    end
    return c
end
_C(0)

-- Cached detector mode (player 1's: players 2-4 are always on a pad). Updated
-- on ZeD_InputModeChanged + snapshotted at boot (in case the first event fired
-- before we registered). Player 1's chord early-outs unless this is
-- "gamepad": no point polling bumpers in KBM mode.
local _mode = "unknown"

-- First-failure latch for the zoom dispatch pcall. If getCore():doZoomScroll
-- ever throws (PZ patch signature drift), we log the error ONCE and keep
-- going — follow-up attempts still fire silently. This prevents log spam
-- when a broken build is mashing bumpers.
local _fireErroredOnce = false

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

-- "" for player 1, so player 1's log lines read word for word as before
local function _who(pn)
    if pn == 0 then return "" end
    return " (player " .. tostring(pn + 1) .. ")"
end

-- Resolve a player's active controller slot. Returns -1 if no controller is
-- connected to that player. Re-read EVERY TICK, never cache at boot — hot-swap
-- (Steam Deck docking, USB reseat, pad swap) changes the .id mid-session and
-- we'd poll a stale slot otherwise.
local function _padIdx(pn)
    if not getJoypadData then return -1 end
    local data = getJoypadData(pn)
    if not data then return -1 end
    local id = data.id
    if id == nil then return -1 end
    return id
end

-- A fresh record starts from the bumpers' levels as they are, so a bumper
-- already held (through a respawn, say) is no new press.
local function _seed(c)
    local id = _padIdx(c.pn)
    if id >= 0 and JoypadButton then
        c.lbLast = JoypadButton.LeftBump:isDown(id) and true or false
        c.rbLast = JoypadButton.RightBump:isDown(id) and true or false
    else
        c.lbLast, c.rbLast = false, false
    end
end

-- Whether player pn (1-3) is playing: their pad's slot is bound to them and
-- their character is alive. The game keeps the slot through the post-death
-- screen and binds it again before the new character exists, so the slot
-- alone is not enough.
local function _playing(pn)
    local P = JoypadState and JoypadState.players
    local jd = P and P[pn + 1]
    if not (jd and jd.player == pn) then return false end
    local p = getSpecificPlayer and getSpecificPlayer(pn)
    return p ~= nil and not p:isDead()
end

-- Log + swap state. One source of truth so every transition shows up in
-- console.txt in the same greppable format.
local function _transition(c, newState)
    if newState == c.state then return end
    local oldState = c.state
    c.state = newState
    print(string.format("[ZeD.Input] chord: %s -> %s", tostring(oldState), tostring(newState)) .. _who(c.pn))
end

-- Cancel any in-progress chord and clear the direction memory. Called on
-- single-bumper release, mode flip away from gamepad, and both-bumpers-
-- released-after-CONSUMED.
local function _reset(c)
    c.primary = nil
    _transition(c, Chord.STATE_IDLE)
end

-- Fire one zoom step for the chord's player. direction is the engine's own:
-- +1 = zoom-out (getZoom rises, wider view), -1 = zoom-in. Vanilla precedent:
-- ISBackButtonWheel's ZoomOut.png slice sends +1 ("ZoomPlus") and its
-- ZoomIn.png slice sends -1 ("ZoomMinus"); the ZoomedIn and ZoomedOut steps in
-- Tutorial/Steps.lua check getZoom against its min and max.
-- The game's Java side can throw if a future PZ patch renames or removes the
-- API; pcall turns that crash into a logged miss instead of a dead tick handler.
local function _fire(c, direction)
    local label = (direction > 0) and "zoom-out" or "zoom-in"
    print(string.format("[ZeD.Input] chord fire: %s", label) .. _who(c.pn))
    local pn = c.pn
    local ok, err = pcall(function()
        getCore():doZoomScroll(pn, direction)
    end)
    if (not ok) and (not _fireErroredOnce) then
        _fireErroredOnce = true
        print(string.format("[ZeD.Input] chord fire FAILED: %s", tostring(err)))
    end
end

-- ---------------------------------------------------------------------------
-- TICK DISPATCHER — called every tick by Events.OnTick, once a playing player
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
local function _tickPad(c)
    -- Gate 1: the kill switch (a focused window owns the bumpers).
    if not c.enabled then return end

    -- Gate 2: player 1 only in gamepad mode. KBM players use mouse wheel to
    -- zoom; running this dispatcher on their session wastes cycles and risks
    -- accidentally firing if they happen to have a pad plugged in. Players
    -- 2-4 are always on a pad.
    if c.pn == 0 and _mode ~= "gamepad" then return end

    -- Gate 3: Need a controller on the player's slot. Re-read every tick —
    -- see _padIdx() doc for hot-swap reasoning.
    local joypadIdx = _padIdx(c.pn)
    if joypadIdx < 0 then return end

    -- Read current level-triggered state for both bumpers (B42.17: poll via
    -- the JoypadButton.<n>:isDown(id) object API). Name-drift trap:
    -- LBumper/RBumper -> LeftBump/RightBump (not "LBump"/"RBump" which
    -- silently no-op).
    local lbDown = JoypadButton.LeftBump:isDown(joypadIdx)
    local rbDown = JoypadButton.RightBump:isDown(joypadIdx)

    -- Edge detection: compare current vs last-tick state.
    local lbPressEdge   = lbDown and (not c.lbLast)
    local rbPressEdge   = rbDown and (not c.rbLast)
    local lbReleaseEdge = (not lbDown) and c.lbLast
    local rbReleaseEdge = (not rbDown) and c.rbLast

    local state = c.state
    if state == Chord.STATE_IDLE then
        -- Simultaneous LB+RB press on the same tick: resolve as LB-first,
        -- RB-arrived-same-frame -> fire zoom-in (LB primary). Matches the
        -- feel of "the chord fired" without a ghost tick in LB_HELD.
        -- Deterministic either way — direction just picked by rule.
        if lbPressEdge and rbPressEdge then
            c.primary = "LB"
            _fire(c, -1) -- LB primary = zoom-in
            _transition(c, Chord.STATE_CONSUMED)
        elseif lbPressEdge then
            c.primary = "LB"
            _transition(c, Chord.STATE_LB_HELD)
        elseif rbPressEdge then
            c.primary = "RB"
            _transition(c, Chord.STATE_RB_HELD)
        end

    elseif state == Chord.STATE_LB_HELD then
        -- Order matters here (see function header): rbPressEdge first so
        -- thumb-roll-off doesn't lose the fire when LB release lands on the
        -- same tick as RB press.
        if rbPressEdge then
            _fire(c, -1) -- LB-then-RB = zoom-in
            _transition(c, Chord.STATE_CONSUMED)
        elseif lbReleaseEdge then
            _reset(c) -- LB released without an RB tap — unowned single-tap
        end

    elseif state == Chord.STATE_RB_HELD then
        -- Mirror of LB_HELD.
        if lbPressEdge then
            _fire(c, 1) -- RB-then-LB = zoom-out
            _transition(c, Chord.STATE_CONSUMED)
        elseif rbReleaseEdge then
            _reset(c)
        end

    elseif state == Chord.STATE_CONSUMED then
        -- CONSUMED re-entry for multi-tap: a fresh opposite-bumper edge fires
        -- another step while the first bumper remains held; stay in CONSUMED.
        -- Only exit when BOTH bumpers are fully released (clean slate).
        if c.primary == "LB" and lbDown and rbPressEdge then
            _fire(c, -1) -- LB-primary = zoom-in
        elseif c.primary == "RB" and rbDown and lbPressEdge then
            _fire(c, 1)  -- RB-primary = zoom-out
        elseif (not lbDown) and (not rbDown) then
            _reset(c)
        end
    end

    -- Save last-tick state for next tick's edge detection. Must be the LAST
    -- thing the dispatcher does so that early returns above don't poison the
    -- edge computation for the next tick they run.
    c.lbLast = lbDown
    c.rbLast = rbDown
end

-- Player 1 first, as always; then each other local player while ZeD's
-- windows are theirs (the gate is read every tick, so a later stage can open
-- it). A player who is not playing (dead, or the slot not theirs yet) loses
-- the record: the next character starts over from the bumpers as they are.
local function onTick()
    _tickPad(_C(0))
    local W = ZeD.windowsFor
    if not W then return end
    for pn = 1, 3 do
        if W(pn) == true then
            if _playing(pn) then
                local c = _rec[pn]
                if c == nil then
                    c = _C(pn)
                    _seed(c)
                end
                _tickPad(c)
            else
                _rec[pn] = nil
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------------

--- Enable / disable a player's chord dispatcher (pn missing: player 1's).
--- FocusManager calls this with false when a window claims that player's
--- focus (LB / RB become the window swap there) and true when focus
--- releases. Also callable from console for QA, e.g.
---   ZeD.Input.Chord.setEnabled(false)
function Chord.setEnabled(flag, pn)
    local c = _C(pn)
    -- Normalize truthy/falsy to strict bool for the gate check in the tick.
    c.enabled = flag and true or false
    -- Cleanliness: if we're turning off mid-chord, reset so re-enable starts
    -- from a known-good IDLE state instead of an orphaned LB_HELD / RB_HELD.
    if not c.enabled and c.state ~= Chord.STATE_IDLE then
        _reset(c)
    end
end

--- A player's state-machine position (pn missing: player 1's). Returns one of
--- STATE_IDLE / STATE_LB_HELD / STATE_RB_HELD / STATE_CONSUMED. Useful from
--- console: "did we terminate in IDLE after that rapid input?"
function Chord.getState(pn)
    if type(pn) ~= "number" then pn = 0 end
    local c = _rec[pn]
    return c and c.state or Chord.STATE_IDLE
end

--- True while a player's chord is in progress (pn missing: player 1's).
--- Equivalent to getState(pn) ~= "IDLE" but reads nicer at call sites that
--- don't care which phase the chord is in.
function Chord.isActive(pn)
    return Chord.getState(pn) ~= Chord.STATE_IDLE
end

-- ---------------------------------------------------------------------------
-- EVENT HANDLERS
-- ---------------------------------------------------------------------------

-- InputModeDetector flipped modes (player 1's mode). Cache the new mode so the
-- tick's gate check runs against fresh data. If we're leaving gamepad mode
-- mid-chord (user grabbed the mouse), reset — otherwise the bumpers'
-- level-triggered state would leak into the next gamepad session.
local function onModeChanged(newMode, _oldMode)
    _mode = newMode or "unknown"
    local c = _C(0)
    if _mode ~= "gamepad" and c.state ~= Chord.STATE_IDLE then
        _reset(c)
    end
end

-- A player's number can come back with another pad and another character (a
-- respawn, or a new player in a dead player's number). Players 2-4 start
-- over; player 1 keeps the kill switch, as it always did, and drops only a
-- chord in progress. Either way a bumper held through it is no new press.
local function onSeatChanged(pn)
    if type(pn) ~= "number" then return end
    if pn ~= 0 then
        _rec[pn] = nil
        return
    end
    local c = _C(0)
    _reset(c)
    _seed(c)
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
-- (guarded: a sim's stub game may not have these events)
if Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(pn) onSeatChanged(pn) end)
end
if Events.OnPlayerDeath then
    Events.OnPlayerDeath.Add(function(p)
        local ok, pn = pcall(function() return p:getPlayerNum() end)
        if ok and pn ~= 0 then onSeatChanged(pn) end
    end)
end

-- One greppable line so the console confirms the module loaded.
print("[ZeD.Input] BumperChord loaded - no arming timeout, hold-and-tap model")
