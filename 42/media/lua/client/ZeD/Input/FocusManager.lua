-- ZeD-UI/42/media/lua/client/ZeD/Input/FocusManager.lua
-- ============================================================================
-- FOCUS MANAGER — which window holds the pad, and what every button does there.
-- Client. The heart of the controller stack: InputModeDetector says the pad
-- is live, BumperChord stands down while a window is focused, ActionMap names
-- each button's action, SpatialNav picks where a D-pad move lands — this file
-- owns the focus itself and dispatches everything in between.
--
-- How a press travels: claimFocus points the engine's joypad focus
-- (setJoypadFocus) at the focused ZeD window, so the engine calls that
-- window's onJoypadDown / onJoypadDir* stubs (ZeD_Window's, in Organisms.lua),
-- which hand the press to dispatchJoypadDown / dispatchJoypadDir here.
-- ActionMap turns a button into an action; a D-pad direction goes to the
-- spatial pick. A, X and Y wait for release or their hold time, and a held
-- D-pad repeats, on the tick poll at the bottom of this file. With no window
-- focused the pad is the game's (BumperChord zooms, the D-pad wheels open);
-- the tick poll still watches Y, which opens the pair.
--
-- Windows store their focusable controls in zones (per-tab builders call
-- setRingZoneElements / setZoneFocusable), but D-pad nav is FLAT across every
-- focusable zone of the focused window. Bumpers don't cycle zones; they pick
-- one of the two always-paired windows (LB Character, RB World).
--
-- NAV MODEL:
--   LB                       — focus the Character window (absolute: on it already, a no-op)
--   RB                       — focus the World window (absolute)
--   D-pad up/down/left/right — spatial nav across ALL focusable zones in the focused window;
--                              with nothing more that way, Left / Right go on to the
--                              other window when it sits that way on screen
--   A tap                    — fire focused element's onActivate (= LMB)
--   A hold (>=350ms)         — fire onHoldActivate if defined (a list row: mark it and
--                              start a painted run); Focus.holdingA(w) stays true until A
--                              comes up, for a key that acts while A is held (Reel in)
--   X tap                    — fire focused element's onContextMenu (= RMB);
--                              else onReset if defined (3-option dialogs only)
--   X hold (>=350ms)         — onHoldContextDrag drag mode (the D-pad drags, release
--                              commits); else onHoldContext once (a list row: quick use)
--   B                        — fire focused element's onCancel if defined; else NO-OP
--                              (no shade-all fallback; purely contextual cancel)
--   Y tap                    — toggle paired visibility (open both/hide both/unhide both)
--   Y hold (>=400ms)         — close every registered window (full lifecycle teardown)
--   L3 / R3                  — the focused list's next sort / list or grid view, nothing else
--   Right stick |v|² > 0.81  — roll up every registered window + release focus (aiming escape)
--
-- WINDOW-PAIR INVARIANT (gamepad mode):
--   Both Character and World are always open as a pair on gamepad. LB/RB rely
--   on this; Y maintains it. ZeD_CharacterWindow.ensureBothOpenForGamepad(0)
--   runs on the flip to gamepad (this file's ZeD_InputModeChanged listener),
--   on Y-tap and on LB / RB, as a safety net.
--
-- PSEUDO-FOCUSABLE D-PAD INTERCEPT (unified contract):
--   Any element may declare onDpadDir(w, el, dir) — a callback that fires
--   BEFORE the spatial pick when D-pad is pressed while that element is
--   focused (only an X-hold drag and an open pop-up list come first). Used
--   by: maps canvas cursor (move cursor in panel pixels), animals zone-draw
--   cursor (move cursor by tile), gridScroll surfaces (scroll the visible
--   region). Returning false from the callback signals "not handled, fall
--   through to the spatial pick" — the false-means-not-handled convention
--   onCancel follows too (for B, false only skips the click sound).
--
-- WINDOW CONTRACT:
--   Each window populates w._focusRing (array of zones) and w._focusIdx (1-based
--   current zone index) on open. Zone shape:
--     w._focusRing = {
--       { zone = "tabBar", focusable = true,
--         elements = { {x, y, w, h, id, onActivate, onContextMenu, onFocus,
--                       onCancel?, onHoldActivate?, onDpadDir?, onReset?,
--                       _zedLabel?, isCanvasCursor?, isZoneDraw?, isGridScroll?,
--                       isDisclosure?, ...}, ... },
--         focusedElementIdx = 1 },
--       ...
--     }
--     w._focusIdx = 1
--   Optional on a zone: covered(w) (drawn over just now, so no stops) and
--   landOn(w, zone, dir) (the element a move into the zone lands on). A
--   zone's renderFn, the old bumper-land hook, is unused: nothing sets or
--   reads one.
--   Optional w:onFocusZoneChanged({new, old}) — fired when a D-pad move
--   crosses a zone boundary, so chrome can refresh.
--
-- BUMPERCHORD INTEGRATION:
--   On claimFocus → Chord.setEnabled(false) so LB/RB pick a window
--   On releaseFocus → Chord.setEnabled(true) so LB/RB route to zoom chord
--
-- SPLIT-SCREEN: one record of focus state a local player (pn 0-3, 0 = player
-- 1): the focused window, the holds, the D-pad repeat, the aiming escape, the
-- focus marks. A pad's press works on its own player's record
-- (joypadData.player), a call about a window on that window's (w.playerNum),
-- and a call that names no player means player 1, so every caller written
-- before split-screen keeps meaning player 1. The mouse and keyboard are
-- player 1's; players 2-4 are always on a pad. Opening ZeD's windows with Y
-- waits for ZeD.windowsFor(pn), the gate in Atoms.lua.
--
-- Public interface (a trailing pn is optional; missing means player 1):
--   ZeD.Input.Focus.registerWindow(w)
--   ZeD.Input.Focus.unregisterWindow(w)
--   ZeD.Input.Focus.claimFocus(w)
--   ZeD.Input.Focus.releaseFocus(pn)
--   ZeD.Input.Focus.getFocusedWindow(pn)
--   ZeD.Input.Focus.isLocked()                            -- always false (the Y-hold lock is gone)
--   ZeD.Input.Focus.getFocusedZone(w)                     -- current zone or nil
--   ZeD.Input.Focus.getFocusedElement(w)                  -- focused element or nil
--   ZeD.Input.Focus.setRingZoneElements(w, zoneRef, elements, preserveIdx?)
--   ZeD.Input.Focus.setZoneFocusable(w, zoneRef, flag)    -- drawer toggling
--   ZeD.Input.Focus.dispatchJoypadDown(w, button, joypadData)
--   ZeD.Input.Focus.dispatchJoypadDir(w, dir, joypadData)
--   ZeD.Input.Focus.reclaimEngineFocus(pn)                -- hand the pad back after a menu or wheel
--   ZeD.Input.Focus.cuesVisible(pn)                       -- the controller's focus mark shows (pad in use)
--   ZeD.Input.Focus.isFocused(w, zoneName?, elementId?)   -- draw a focus mark here? (focused window only)
--   ZeD.Input.Focus.liveZone(w) / liveElement(w)          -- the same as zone / element, nil when not shown
--   Also: isRegistered, held, setRingZoneElementsKeepId, focusWhere,
--   ensureEntry, landOnPrimary, focusSoon / focusByIdSoon / focusPrimarySoon,
--   openSide, tick, toggleDebugOverlay / isDebugOverlay, and the QA hooks
--   previewMove, flatElements and qaButton (each documented where it lives).
--
-- Event emitted:
--   Events.ZeD_FocusChanged(newWindow, oldWindow, pn)
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Input/SpatialNav"

-- Reload-safe: loading this file twice reuses the tables instead of wiping
-- them, and guarding every level lets PZ re-execute files in any order.
ZeD = ZeD or {}
ZeD.Input = ZeD.Input or {}
ZeD.Input.Focus = ZeD.Input.Focus or {}

local Focus = ZeD.Input.Focus

-- ---------------------------------------------------------------------------
-- CONSTANTS
-- ---------------------------------------------------------------------------

-- Grace period after claimFocus during which stick aiming-escape is suppressed.
-- Without this, stick drift or a thumb still resting on the right stick can
-- hide the window the instant it opens.
local WS_GRACE_MS = 600

-- SDL standard controller axis indices. Mirrored from InputModeDetector.
local AXIS_RSTICK_X = 2
local AXIS_RSTICK_Y = 3

-- Token readers. Triple-guard to tolerate T.gp not being populated at
-- file-load time (same pattern as InputModeDetector).
local function _holdInitialMs()     return (ZeD.T and ZeD.T.gp and ZeD.T.gp.holdInitMs)        or 250 end
local function _holdRepeatMs()      return (ZeD.T and ZeD.T.gp and ZeD.T.gp.holdRepeatMs)      or 120 end
local function _holdMs()            return (ZeD.T and ZeD.T.gp and ZeD.T.gp.holdMs)            or 400 end
local function _aimingThresholdSq() return (ZeD.T and ZeD.T.gp and ZeD.T.gp.aimingThresholdSq) or 0.81 end

-- ---------------------------------------------------------------------------
-- FILE-LOCAL STATE
-- ---------------------------------------------------------------------------

local _windowRegistry = {}   -- every window the pads can reach, all players' (each knows its player: w.playerNum)

-- A-button and X-button hold thresholds. A press defers firing until release
-- (tap) or this long held (hold); see the A and X notes in the record below.
local A_HOLD_MS     = 350
local X_HOLD_MS     = 350

-- ---------------------------------------------------------------------------
-- PER-PLAYER STATE (split-screen)
-- One record a local player (pn 0-3, 0 = player 1), made on first use; player
-- 1's is made at load and never replaced. Fields:
--   win                    the window holding this player's pad, or nil
--   dDir, dStart, dLast    D-pad hold-to-repeat: the direction held, when, the last repeat
--   yHeld, yStart, yUsed   Y tap-vs-hold (B has no hold; Y, A and X are the hold-armed buttons)
--   aHeld, aStart, aUsed, aWin   A tap-vs-hold. A press defers firing until release (tap:
--                          onActivate) or A_HOLD_MS (hold: onHoldActivate, when defined). aWin
--                          is the window that had the focus at the press, so the callback fires
--                          on the right window even if the focus moved (defensive)
--   xHeld, xStart, xUsed, xWin, xEl   X tap-vs-hold, A's mirror. A tap fires onContextMenu /
--                          onReset. A hold past X_HOLD_MS fires onHoldContextDrag with no dir
--                          ("drag mode armed"); while X stays held the D-pad fires
--                          onHoldContextDrag(w, el, dir) instead of moving the focus; the release
--                          fires onHoldContextRelease. An element with onHoldContext gets that
--                          once at the threshold instead (no drag). xEl is captured at the press
--                          and locked through the release
--   prevY                  Y's level last tick while no window is focused (the Y that opens the pair)
--   wsLatched, wsGrace     the aiming escape's edge latch, and the end of its grace after a claim
--   cues, cueSince         the focus marks show (CUES below); players 2-4 have no mouse to hide them
--   qa, qaN                Focus.qaButton's held buttons for this player's pad, and how many
--   away                   the player was not playing on the last tick: their next tick starts
--                          from the pad as it is
-- Fresh on every load, like the registry: a kept window would point at one the new registry
-- doesn't hold. Focus._st is read by QA and the sims.
-- ---------------------------------------------------------------------------
local _st = {}
Focus._st = _st

local function _S(pn)
    if type(pn) ~= "number" then pn = 0 end
    local s = _st[pn]
    if s == nil then
        s = { pn = pn, win = nil,
              dDir = nil, dStart = 0, dLast = 0,
              yHeld = false, yStart = 0, yUsed = false,
              aHeld = false, aStart = 0, aUsed = false, aWin = nil,
              xHeld = false, xStart = 0, xUsed = false, xWin = nil, xEl = nil,
              prevY = false,
              wsLatched = false, wsGrace = 0,
              cues = (pn ~= 0), cueSince = 0,
              qa = {}, qaN = 0,
              away = (pn ~= 0) }
        _st[pn] = s
    end
    return s
end
-- player 1's record: made now and never replaced (the per-row focus mark reads it first)
local _st0 = _S(0)

-- D-pad debug overlay toggle (F9, debug builds). Paints the focused
-- element's bbox + the per-direction picks (cyan = lined up, the picker's
-- "cone" pass; magenta = off to the side, "half"). A QA aid — TODO: strip
-- once the spatial nav settles.
local _debugOverlay    = false
-- a dry run of a D-pad move (Focus.previewMove; the QA nav scripts read it)
local _preview = nil
-- Last-pick cache (per direction) so the overlay can highlight what
-- _pickBestWithFallback would choose in that direction without re-running
-- the picker every frame. Refreshed when overlay is on. Bounds in
-- WINDOW-LOCAL coords (already translated via _collectFlat).
local _debugLastPicks  = { up = nil, down = nil, left = nil, right = nil }
local _debugFocusBox   = nil  -- focused element's translated bounds (cached for paint)

-- ---------------------------------------------------------------------------
-- HELPERS (declared up-front so forward references resolve)
-- ---------------------------------------------------------------------------

-- (a zone's source panel; assigned in the FLAT-NAV section below, read by
-- setZoneFocusable above it: Kahlua closures capture a name at creation)
local _zonePanel

-- Stable-label helper: prefer _zedLabel (set once by window) over .title
-- (which mutates mid-session to show player name / container name).
local function _label(w)
    if not w then return "nil" end
    if w._zedLabel and w._zedLabel ~= "" then return w._zedLabel end
    if w.title and w.title ~= "" then return w.title end
    return tostring(w)
end

-- Linear scan of tiny registry.
local function _indexOf(w)
    for i = 1, #_windowRegistry do
        if _windowRegistry[i] == w then return i end
    end
    return nil
end

-- Whose a press or a call is: the pressing pad's player when a joypadData
-- names one, else the window's (w.playerNum, set when the window is built),
-- else player 1. Not ZeD.playerNumOf(w): the World window's restore runs
-- before its _playerObj is set.
local function _pnOf(w, joypadData)
    local pn = (type(joypadData) == "table") and joypadData.player or nil
    if pn == nil and type(w) == "table" then pn = w.playerNum end
    if type(pn) ~= "number" then return 0 end
    return pn
end

-- "" for player 1, so player 1's log lines read word for word as before
local function _who(pn)
    if pn == 0 then return "" end
    return " (player " .. tostring(pn + 1) .. ")"
end

-- A player's input mode: player 1's follows the detector, players 2-4 are always on a pad
local function _modeOf(pn)
    local D = ZeD.Input.Detector
    if not (D and D.getMode) then return nil end
    if pn == 0 then return D.getMode() end
    return D.getMode(pn)
end

-- Whether ZeD's windows are this player's (read at call time, so a later
-- split-screen stage can open the gate). Player 1's always are.
local function _ownsWindows(pn)
    if pn == 0 then return true end
    local W = ZeD.windowsFor
    return W ~= nil and W(pn) == true
end

-- The registered windows of one player: how many, and the last one
local function _countOf(pn)
    local n = 0
    for i = 1, #_windowRegistry do
        if _pnOf(_windowRegistry[i]) == pn then n = n + 1 end
    end
    return n
end
local function _lastOf(pn)
    for i = #_windowRegistry, 1, -1 do
        local o = _windowRegistry[i]
        if _pnOf(o) == pn then return o end
    end
    return nil
end

-- Push engine-level joypad focus so PZ's onJoypad* dispatch reaches our
-- window's shims, on player pn's pad slot. setJoypadFocus is the engine's
-- canonical setter; `nil` is valid and clears engine focus. The game's Java
-- side can throw, so pcall turns a crash into a miss.
local function _pushEngineFocus(control, pn)
    if not setJoypadFocus then return end
    pcall(setJoypadFocus, pn or 0, control)
end

-- Tell the engine to ignore aim input until sticks recenter — prevents stick
-- pressure at the moment of claim from leaking into aiming. Only meaningful
-- in gamepad mode.
local function _maybeIgnoreAim(pn)
    if _modeOf(pn) ~= "gamepad" then return end
    -- (the setter is the game's global, by player number; getJoypadData is a plain Lua table without it)
    if setJoypadIgnoreAimUntilCentered and getSpecificPlayer(pn) then
        pcall(setJoypadIgnoreAimUntilCentered, pn, true)
    end
end

-- Enable/disable a player's BumperChord. Wrapped in a helper because the
-- module may not be loaded yet (load-order-agnostic) and we don't want a
-- nil-index crash to break focus claim.
local function _setBumperChordEnabled(flag, pn)
    if ZeD.Input.Chord and ZeD.Input.Chord.setEnabled then
        if pn == nil or pn == 0 then ZeD.Input.Chord.setEnabled(flag)
        else ZeD.Input.Chord.setEnabled(flag, pn) end
    end
end

-- Fire a callback wrapped in pcall. A bug in zone.onActivate shouldn't wedge
-- the dispatch loop — log and continue. `fnName` is a string tag for the log.
local function _fireCb(fnName, fn, w, arg)
    if not fn then return end
    local ok, err = pcall(fn, w, arg)
    if not ok then
        print("[ZeD.Input] Focus: " .. fnName .. " failed: " .. tostring(err))
    end
end

-- Fire a callback that may return a value (e.g., onCancel "false = pass through").
-- Returns the callback's return value, or nil on error.
local function _fireCbR(fnName, fn, w, ...)
    if not fn then return nil end
    local ok, result = pcall(fn, w, ...)
    if not ok then
        print("[ZeD.Input] Focus: " .. fnName .. " failed: " .. tostring(result))
        return nil
    end
    return result
end

-- A window whose tab stops wait while the mouse is in use (Focus.stopsMayWait)
-- brings them up to date through w._focusFresh before anything here reads them: a press, a landing, the stop list
local function _fresh(w)
    local fn = w and w._focusFresh
    if fn then _fireCb("window.focusFresh", fn, w) end
end

-- ---------------------------------------------------------------------------
-- CUES: does the controller's focus mark show?
-- The focus marks (ZeD.Focus, ZeD_FocusPaint.lua) show only while the pad is in
-- use. The detector's mode is not used for that on its own: with a drifting
-- stick and the mouse both live it swaps kbm <-> gamepad every cooldown (the
-- scroll-pin note in InventoryRenderer.lua), and moving the mouse never changes
-- it. So the cues go on with a pad press that reaches a ZeD window (or a window
-- claimed in gamepad mode) and off as soon as the mouse is used: moved more than
-- a few units, clicked, or the mode turning to kbm. Nothing is forgotten: the
-- focused zone and element stay, so the next pad press carries on from them.
-- ---------------------------------------------------------------------------
local CUE_MOUSE_U = 8          -- mouse travel (design units) that counts as using it
local _cueMouseX, _cueMouseY = nil, nil   -- (the mouse is player 1's: only their marks watch it)

local function _showCues(s)
    s.cues = true
    s.cueSince = getTimestampMs() or 0
    if s.pn == 0 and getMouseX then _cueMouseX, _cueMouseY = getMouseX(), getMouseY() end
end

local function _hideCues(s)
    s.cues = false
end

-- once per rendered frame (it also runs while the game is paused); player 1's marks only
local function _watchCueMouse()
    local s = _st0
    if not s.cues or not getMouseX then return end
    local mx, my = getMouseX(), getMouseY()
    if _cueMouseX == nil then _cueMouseX, _cueMouseY = mx, my; return end
    local T = ZeD.T
    local th = (T and T.px) and T.px(CUE_MOUSE_U) or CUE_MOUSE_U
    if math.abs(mx - _cueMouseX) > th or math.abs(my - _cueMouseY) > th then _hideCues(s); return end
    local D = ZeD.Input.Detector
    if D and D.msSinceMouseClick and D.msSinceMouseClick() < (getTimestampMs() or 0) - s.cueSince then
        _hideCues(s)
    end
end

--- True while player pn's focus mark shows (pn missing: player 1): the last
--- pad press that reached a ZeD window is newer than the last use of the
--- mouse. Players 2-4 have no mouse, so theirs always show.
function Focus.cuesVisible(pn)
    if type(pn) ~= "number" then pn = 0 end
    local s = _st[pn]
    if s == nil then return pn ~= 0 end
    return s.cues
end

-- ---------------------------------------------------------------------------
-- REGISTRY API
-- ---------------------------------------------------------------------------

--- Whether w is still registered (a window kept to hand focus back to may have closed).
function Focus.isRegistered(w)
    return w ~= nil and _indexOf(w) ~= nil
end

--- Add w to the windows the pad can reach (once; a second call does nothing).
function Focus.registerWindow(w)
    if not w then return end
    if _indexOf(w) then return end
    _windowRegistry[#_windowRegistry + 1] = w
    local pn = _pnOf(w)
    print("[ZeD.Input] Focus: register: " .. _label(w)
       .. " (" .. tostring(_countOf(pn)) .. " registered)" .. _who(pn))
end

--- Atomic focus transfer on unregister: if the removed window was focused and
--- another of its player's survives, hand off in a SINGLE ZeD_FocusChanged
--- event so subscribers can diff cleanly. If no survivors, degrades to regular
--- release (new = nil). Focus never passes to another player's window.
function Focus.unregisterWindow(w)
    if not w then return end
    local pn = _pnOf(w)
    local s = _S(pn)
    local wasFocused = (s.win == w)
    local idx = _indexOf(w)
    if idx then
        table.remove(_windowRegistry, idx)
        print("[ZeD.Input] Focus: unregister: " .. _label(w)
           .. " (" .. tostring(_countOf(pn)) .. " registered)" .. _who(pn))
    end
    if not wasFocused then return end

    local old = s.win
    -- a second player who died or left: their pad's slot is the post-death
    -- screen's now, so nothing is handed on or pushed there (the windows'
    -- death handler may close them before this file hears of the death)
    if pn ~= 0 then
        local p = getSpecificPlayer and getSpecificPlayer(pn)
        if p == nil or p:isDead() then
            s.win = nil
            s.dDir = nil
            _setBumperChordEnabled(true, pn)
            print("[ZeD.Input] Focus: release: " .. _label(old) .. " -> nil" .. _who(pn))
            triggerEvent("ZeD_FocusChanged", nil, old, pn)
            return
        end
    end

    local nextW = _lastOf(pn)
    s.win  = nextW
    s.dDir = nil

    if nextW then
        print("[ZeD.Input] Focus: transfer: " .. _label(old)
           .. " -> " .. _label(nextW) .. _who(pn))
        _pushEngineFocus(nextW, pn)
        _maybeIgnoreAim(pn)
        -- BumperChord stays disabled — a ZeD window is still focused.
    else
        print("[ZeD.Input] Focus: release: " .. _label(old) .. " -> nil" .. _who(pn))
        _pushEngineFocus(nil, pn)
        -- No more focused windows: hand bumpers back to the zoom chord.
        _setBumperChordEnabled(true, pn)
    end

    triggerEvent("ZeD_FocusChanged", nextW, old, pn)
end

-- ---------------------------------------------------------------------------
-- FOCUS CLAIM / RELEASE / READ
-- ---------------------------------------------------------------------------

--- A window that keeps the pad to itself is up (the join screen,
--- ZeD_CommunityCards.lua): nothing here opens a window or takes the pad under
--- it. It holds the pad itself (ZeD_JoinWindow:update) and hands it back when it closes.
function Focus.held()
    local CM = ZeD.CommunityCards
    return CM ~= nil and CM.joinWin ~= nil
end

--- Give w the pad of its player (w.playerNum): it becomes that player's
--- focused window, lands on something lit (Focus.ensureEntry), takes the
--- engine's joypad focus on that player's slot, and their bumpers leave the
--- zoom chord for the window pair; ZeD_FocusChanged fires.
--- Does nothing while Focus.held().
function Focus.claimFocus(w)
    if not w then return end
    local pn = _pnOf(w)
    local s = _S(pn)
    if s.win == w then return end
    if Focus.held() then return end

    local old = s.win
    s.win = w
    print("[ZeD.Input] Focus: claim: " .. _label(old) .. " -> " .. _label(w) .. _who(pn))
    -- a window the pad opened shows where its focus is at once
    if _modeOf(pn) == "gamepad" then _showCues(s) end
    -- land on something lit (the last focused element, else the list's first
    -- row); see Focus.ensureEntry
    if Focus.ensureEntry then
        local ok, err = pcall(Focus.ensureEntry, w)
        if not ok then print("[ZeD.Input] Focus: ensureEntry failed: " .. tostring(err)) end
    end

    _pushEngineFocus(w, pn)
    _maybeIgnoreAim(pn)

    -- Bumpers become window-swap while we hold focus. Disable the zoom chord.
    _setBumperChordEnabled(false, pn)

    -- Start grace window against stick-drift / trigger-pressure aiming-escape.
    s.wsGrace   = getTimestampMs() + WS_GRACE_MS
    s.wsLatched = false

    triggerEvent("ZeD_FocusChanged", w, old, pn)
end

--- Let player pn's pad go (pn missing: player 1's): no window is focused, the
--- engine's joypad focus clears (the pad is the game's again) and the bumpers
--- return to the zoom chord.
function Focus.releaseFocus(pn)
    if type(pn) ~= "number" then pn = 0 end
    local s = _st[pn]
    if not (s and s.win) then return end
    local old = s.win
    s.win  = nil
    s.dDir = nil

    _pushEngineFocus(nil, pn)
    _setBumperChordEnabled(true, pn)

    print("[ZeD.Input] Focus: release: " .. _label(old) .. " -> nil" .. _who(pn))
    triggerEvent("ZeD_FocusChanged", nil, old, pn)
end

--- The window holding player pn's pad (pn missing: player 1's), or nil.
function Focus.getFocusedWindow(pn)
    if type(pn) ~= "number" then pn = 0 end
    local s = _st[pn]
    return s and s.win
end

--- Always false: Y-hold closes the pair now instead of toggling a windowshade
--- lock. The reader stays so an old caller can't blow up.
function Focus.isLocked()
    return false
end

-- ---------------------------------------------------------------------------
-- ZONE STORAGE API
--
-- Zones are a per-window STORAGE abstraction, kept so the per-tab builder
-- code that fills them never had to be rewritten when nav went flat: D-pad
-- nav runs across ALL focusable zones in the focused window, and bumpers
-- never hop between zones.
-- ---------------------------------------------------------------------------

-- Resolve a zone reference (index or name) to its array index inside w._focusRing.
local function _resolveZoneIdx(w, zoneRef)
    if not w or not w._focusRing then return nil end
    if type(zoneRef) == "number" then
        if zoneRef >= 1 and zoneRef <= #w._focusRing then return zoneRef end
        return nil
    end
    if type(zoneRef) == "string" then
        for i = 1, #w._focusRing do
            if w._focusRing[i].zone == zoneRef then return i end
        end
    end
    return nil
end

-- Clamp a 1-based index into a table's [1, #t] range. Empty table → 1 (harmless).
local function _clampIdx(idx, t)
    idx = idx or 1
    if idx < 1 then return 1 end
    local n = (t and #t) or 0
    if n == 0 then return 1 end
    if idx > n then return n end
    return idx
end

--- The currently-focused ring entry (whole zone table), or nil.
function Focus.getFocusedZone(w)
    if not w or not w._focusRing then return nil end
    local idx = w._focusIdx or 1
    return w._focusRing[idx]
end

--- The currently-focused element inside the current zone, or nil.
function Focus.getFocusedElement(w)
    local zone = Focus.getFocusedZone(w)
    if not zone or not zone.elements then return nil end
    local ei = zone.focusedElementIdx or 1
    return zone.elements[ei]
end

-- getFocusedZone / getFocusedElement read a window's stored focus whether or not
-- the window has it (navigation and the windows' own logic need that). A focus
-- MARK needs more: the window is the focused one and the controller is in use.
-- Without that test the unfocused window would keep lighting its remembered
-- row (Craft, Build, Journal, Animals, Foraging, Stations, JournalReaders), and
-- the mark would stay lit while the mouse is used. Surfaces draw marks through these:

--- The zone a focus mark may show in, or nil: w is its player's focused
--- window and that player's controller is in use.
-- (Surfaces ask this for every row on every drawn frame: player 1's focused
-- window is one comparison, any other window one table read, no record made.)
function Focus.liveZone(w)
    if not w then return nil end
    local s = _st0
    if w ~= s.win then
        s = _st[w.playerNum or 0]
        if not s or w ~= s.win then return nil end
    end
    if not s.cues then return nil end
    return Focus.getFocusedZone(w)
end

--- The element a focus mark may show on, or nil (see liveZone).
function Focus.liveElement(w)
    if not Focus.liveZone(w) then return nil end
    return Focus.getFocusedElement(w)
end

--- True when a surface should draw the focus mark: w is the focused window, the
--- controller is in use, its focused zone is zoneName (when given) and its
--- focused element has the id elementId (when given).
function Focus.isFocused(w, zoneName, elementId)
    local z = Focus.liveZone(w)
    if not z then return false end
    if zoneName ~= nil and z.zone ~= zoneName then return false end
    if elementId ~= nil then
        local el = Focus.getFocusedElement(w)
        return el ~= nil and el.id == elementId
    end
    return true
end

--- Marks a list's rows (the stops that carry .item) that lie out of the
--- list's view: el.offscreen = true when the row ends above view.top or
--- starts at or below view.bottom (view = the renderer's _rowView, the same
--- panel space as the rows' y), else nil. Such a row stays a stop for its own
--- zone's moves, never for another zone's (_pickBestWithFallback).
function Focus.markOffscreen(elements, view)
    if not (elements and view and view.top and view.bottom) then return end
    for _, el in ipairs(elements) do
        if el.item and type(el.y) == "number" and type(el.h) == "number" then
            el.offscreen = (el.y + el.h <= view.top or el.y >= view.bottom) or nil
        end
    end
end

--- Swap a zone's elements array (e.g. inventory row rebuild). Optionally
--- preserve focusedElementIdx at a specific value (else clamp existing).
function Focus.setRingZoneElements(w, zoneRef, elements, preserveIdx)
    local idx = _resolveZoneIdx(w, zoneRef)
    if not idx or not elements then return end
    local zone = w._focusRing[idx]
    zone.elements = elements
    if preserveIdx then
        zone.focusedElementIdx = _clampIdx(preserveIdx, elements)
    else
        zone.focusedElementIdx = _clampIdx(zone.focusedElementIdx, elements)
    end
end

--- The same, keeping the focus on the element with the same id when it is
--- still there (a card's controls rebuilt each frame: a button appearing
--- before the focused one must not move the focus).
function Focus.setRingZoneElementsKeepId(w, zoneRef, elements)
    local idx = _resolveZoneIdx(w, zoneRef)
    if not idx or not elements then return end
    local zone = w._focusRing[idx]
    local old = zone.elements and zone.elements[zone.focusedElementIdx or 1]
    local keep
    if old and old.id then
        for i, e in ipairs(elements) do
            if e.id == old.id then keep = i; break end
        end
    end
    Focus.setRingZoneElements(w, zoneRef, elements, keep)
end

--- Toggle focusable flag on a zone (e.g. drawer open=true / closed=false).
--- If toggling OFF the currently-focused zone, advance _focusIdx to the next
--- focusable zone so the user doesn't end up stranded in a dead zone.
function Focus.setZoneFocusable(w, zoneRef, flag)
    local idx = _resolveZoneIdx(w, zoneRef)
    if not idx then return end
    w._focusRing[idx].focusable = flag and true or false

    if (not flag) and w._focusIdx == idx then
        -- the window's list emptied under the focus (another container
        -- picked, the last item taken): focus goes back to the list as soon
        -- as it has rows again (Focus.ensureEntry, on the tick)
        if w._focusEntryZone and w._focusRing[idx].zone == w._focusEntryZone then
            w._focusPendingEntry = true
        end
        -- Focus goes back to where you started or its nearest neighbour in
        -- the same panel, never to another panel or nowhere: first a zone in
        -- the same panel that still has stops (the list's container buttons
        -- under it), only then the ring order.
        local panel = _zonePanel(w, w._focusRing[idx].zone)
        if panel then
            for i, z in ipairs(w._focusRing) do
                if i ~= idx and z.focusable and z.elements and #z.elements > 0 and _zonePanel(w, z.zone) == panel then
                    w._focusIdx = i
                    z.focusedElementIdx = _clampIdx(z.focusedElementIdx, z.elements)
                    return
                end
            end
        end
        local n = #w._focusRing
        for step = 1, n do
            local probe = ((w._focusIdx - 1 + step) % n) + 1
            if w._focusRing[probe].focusable then
                w._focusIdx = probe
                return
            end
        end
        -- All zones non-focusable: leave _focusIdx as-is. Dispatch becomes
        -- silent no-op — right behavior for a fully-empty window.
    end
end

-- ---------------------------------------------------------------------------
-- reclaimEngineFocus — re-push engine focus to a player's tracked focused
-- window, so dispatch resumes after something that borrowed the pad (a context
-- menu, a D-pad wheel, the chat) let it go. pn: the player whose pad it was
-- (missing: player 1); another player closing a menu never pulls player 1's.
-- ---------------------------------------------------------------------------

function Focus.reclaimEngineFocus(pn)
    if type(pn) ~= "number" then pn = 0 end
    local s = _st[pn]
    if s and s.win and setJoypadFocus then
        pcall(setJoypadFocus, pn, s.win)
    end
end

-- ---------------------------------------------------------------------------
-- WHERE FOCUS LANDS — two helpers that keep a window from putting the focus
-- on nothing visible when it is entered, and let an opened info card land
-- it on its action strip.
--
--   Focus.focusWhere(w, zone, pred)  put focus on the first element of the
--                                    zone that pred(el, i) accepts (nil pred
--                                    = the first), now; fires its onFocus
--   Focus.ensureEntry(w)             a window being entered (LB / RB, the
--                                    D-pad from the other window, Y) keeps
--                                    its last focused element while it still
--                                    exists; a fresh window, or one whose
--                                    focus is gone, lands on its entry zone
--                                    (w._focusEntryZone: the item list) on
--                                    its first row; with no rows, on the
--                                    first zone that has something
-- A window sets w._focusEntryZone and w._focusPendingEntry = true when it is
-- built; the pending flag clears on the first landing (a D-pad move, a
-- focusWhere), and comes back when the list empties under the focus.
-- ---------------------------------------------------------------------------

function Focus.focusWhere(w, zoneName, pred)
    _fresh(w)
    if not (w and w._focusRing) then return nil end
    for zi, z in ipairs(w._focusRing) do
        if z.zone == zoneName and z.focusable then
            for ei, e in ipairs(z.elements or {}) do
                if (not pred) or pred(e, ei) then
                    w._focusIdx = zi
                    z.focusedElementIdx = ei
                    w._navLast = nil
                    w._focusPendingEntry = nil
                    if e.onFocus then _fireCb("element.onFocus", e.onFocus, w, e) end
                    return e
                end
            end
        end
    end
    return nil
end

--- A zone.landOn for cards (the windows hand it in when they build zones):
--- a move into the card lands on its primary action, the button the player
--- most likely wants.
function Focus.landOnPrimary(w, z)
    for i, e in ipairs(z and z.elements or {}) do
        if e.isPrimary then return i end
    end
    return nil
end

local function _focusLive(w)
    local z = w._focusRing and w._focusRing[w._focusIdx or 1]
    if z and z.covered and z.covered(w) then return false end
    return z ~= nil and z.focusable and z.elements ~= nil and z.elements[z.focusedElementIdx or 1] ~= nil
end

function Focus.ensureEntry(w)
    _fresh(w)
    if not (w and w._focusRing) then return end
    local live = _focusLive(w)
    if live and not w._focusPendingEntry then return end
    local zi = w._focusEntryZone and _resolveZoneIdx(w, w._focusEntryZone)
    local zone = zi and w._focusRing[zi]
    if zone and zone.focusable and zone.elements and #zone.elements > 0 then
        -- the remembered row when focus was last here, else the first row
        -- (rows carry .item; the view button and placeholders do not)
        local ei = zone.focusedElementIdx or 1
        local el = zone.elements[ei]
        if not (el and el.item) or w._focusPendingEntry then
            for i, e in ipairs(zone.elements) do
                if e.item then ei = i; break end
            end
        end
        w._focusIdx = zi
        zone.focusedElementIdx = _clampIdx(ei, zone.elements)
        w._navLast = nil
        w._focusPendingEntry = nil
        el = zone.elements[zone.focusedElementIdx]
        if el and el.onFocus then _fireCb("element.onFocus", el.onFocus, w, el) end
        return
    end
    if live then return end   -- (the list has no rows yet: keep what is lit)
    for i, z in ipairs(w._focusRing) do
        if z.focusable and not (z.covered and z.covered(w)) and z.elements and #z.elements > 0 then
            w._focusIdx = i
            z.focusedElementIdx = _clampIdx(z.focusedElementIdx, z.elements)
            local e = z.elements[z.focusedElementIdx]
            if e and e.onFocus then _fireCb("element.onFocus", e.onFocus, w, e) end
            return
        end
    end
end

-- ---------------------------------------------------------------------------
-- FLAT-NAV: collect all elements from focusable zones into a single virtual
-- list, keep a parallel table mapping flat-idx → (zoneIdx, elementIdx) so
-- post-pick we can write back to the right zone's focusedElementIdx and to
-- the window's _focusIdx (cross-zone landing).
-- ---------------------------------------------------------------------------

-- Zone-name → window-field map. Each zone's element bounds are stamped
-- in the source PANEL'S local coords (e.g. an invrow's x=0 is the LEFT EDGE
-- of the content panel, not of the window). The spatial picker compares all
-- elements as if they share a single coord space — without translation,
-- two zones with x=0 collide and inventory gets skipped on cross-zone hops.
-- The fix: at _collectFlat, translate each element to WINDOW-local by adding
-- the source panel's getX/getY relative to the window.
local _zonePanelField = {
    -- Character window
    charTabBar         = "_tabStripPanel",
    charTabContent     = "_drawerPanel",
    charMainInv        = "_contentPanel",
    charItemCard       = "_itemDrawerPanel",
    charContainerStrip = "_containerStrip",
    charCtl            = "_contentPanel",   -- the container buttons' row (ContainerControls)
    -- World window (mirrored layout — drawer on right, container on left)
    worldTabBar         = "_actionTabStrip",
    worldTabContent     = "_drawerPanel",
    worldMainInv        = "_contentPanel",
    worldItemCard       = "_itemDrawerPanel",
    worldContainerStrip = "_containerStrip",
    worldCtl            = "_contentPanel",  -- the container buttons' row (ContainerControls)
    -- map pop-out window (ZeD.MapsTab.openPopout) — one content zone
    popMapContent       = "_contentPanel",
    -- charMC<N> / worldMC<N> all share their respective content panel
}

-- Resolve the source panel for a zone. charMC<N> and worldMC<N> are
-- handled via prefix match since they're dynamically named.
_zonePanel = function(w, zoneName)
    if not w or not zoneName then return nil end
    local field = _zonePanelField[zoneName]
    if not field then
        if zoneName:match("^charMC%d+$")  then field = "_contentPanel"
        elseif zoneName:match("^worldMC%d+$") then field = "_contentPanel"
        end
    end
    if not field then return nil end
    return w[field]
end

-- Get a zone's (offsetX, offsetY) in window-local coords. Falls back to
-- (0, 0) if the panel isn't known — pre-translation behavior.
local function _zoneOffset(w, zoneName)
    local panel = _zonePanel(w, zoneName)
    if not panel then return 0, 0 end
    local ok1, ox = pcall(panel.getX, panel)
    local ok2, oy = pcall(panel.getY, panel)
    if not ok1 then ox = 0 end
    if not ok2 then oy = 0 end
    return ox or 0, oy or 0
end

-- Returns (elements, locator) where:
--   elements[i]  = a SHALLOW COPY of the source element with bounds translated
--                  to window-local coords (the picker works on this copy)
--   locator[i]   = { zoneIdx = N, elementIdx = M } for that flat position
-- Skips zones flagged focusable=false and zones with empty elements.
-- Translation: x/y get the source panel's offset added; w/h unchanged.
local function _collectFlat(w)
    local elements, locator = {}, {}
    if not w or not w._focusRing then return elements, locator end
    for zi = 1, #w._focusRing do
        local zone = w._focusRing[zi]
        -- (zone.covered(w) = drawn over just now, e.g. a tab's controls
        -- under an item card that overlays the drawer: no stops)
        local covered = zone.covered and zone.covered(w)
        if zone.focusable and not covered and zone.elements and #zone.elements > 0 then
            local ox, oy = _zoneOffset(w, zone.zone)
            for ei = 1, #zone.elements do
                local el = zone.elements[ei]
                if el and type(el.x) == "number" and type(el.y) == "number" then
                    -- Shallow copy with translated bounds. Other fields
                    -- (id, item, onActivate, etc.) are preserved by reference.
                    local translated = {
                        x = el.x + ox, y = el.y + oy,
                        w = el.w, h = el.h,
                        id = el.id,
                        zi = zi,                    -- (its zone: the picker's offscreen rule)
                        offscreen = el.offscreen,   -- (a list row scrolled out of view: Focus.markOffscreen)
                        _origRef = el,  -- back-pointer for debugging if needed
                    }
                    elements[#elements + 1] = translated
                    locator[#locator + 1]   = { zoneIdx = zi, elementIdx = ei }
                end
            end
        end
    end
    return elements, locator
end

-- Find the flat position of the currently-focused element in the collected
-- list. Returns nil if the focused zone isn't in the flat list (drawer just
-- closed mid-frame), in which case the caller should default to position 1.
local function _findCurrentFlatIdx(w, locator)
    local zi = w._focusIdx or 1
    local zone = w._focusRing and w._focusRing[zi]
    if not zone then return nil end
    local ei = zone.focusedElementIdx or 1
    for fi = 1, #locator do
        local loc = locator[fi]
        if loc.zoneIdx == zi and loc.elementIdx == ei then
            return fi
        end
    end
    return nil
end

-- Update window state after a D-pad move landed on flat position newFlatIdx.
-- Writes back to both w._focusIdx (zone) and the destination zone's
-- focusedElementIdx (intra-zone position). Fires onFocus on landing element.
-- If we crossed a zone boundary, also fires window's onFocusZoneChanged hook.
local function _applyFlatLanding(w, locator, oldFlatIdx, newFlatIdx)
    local newLoc = locator[newFlatIdx]
    if not newLoc then return end
    local oldZoneIdx = w._focusIdx
    local newZoneIdx = newLoc.zoneIdx
    local newZone    = w._focusRing[newZoneIdx]
    if not newZone then return end

    newZone.focusedElementIdx = newLoc.elementIdx
    w._focusIdx               = newZoneIdx
    w._focusPendingEntry      = nil   -- the player put focus somewhere: no entry seed after this

    local newEl = newZone.elements[newLoc.elementIdx]
    if newEl and newEl.onFocus then
        _fireCb("element.onFocus", newEl.onFocus, w, newEl)
    end
    -- Audible focus tick (vanilla list-select sound) so D-pad moves are
    -- felt without looking for the cue. Mouse hover never routes here.
    pcall(function() getSoundManager():playUISound("UISelectListItem") end)

    if newZoneIdx ~= oldZoneIdx and w.onFocusZoneChanged then
        _fireCb("window.onFocusZoneChanged", w.onFocusZoneChanged, w,
            { new = newZone, old = w._focusRing[oldZoneIdx] })
    end
end

-- The picker: ZeD.SpatialNav, by rectangles — the nearest element LINED UP
-- that way (spans overlapping across the move), else the nearest that way at
-- any angle, so no on-screen direction is ever blocked. The strict 45-degree
-- centre cone it replaced sent Right past a button beside a tall row and made
-- the player go down, over and up.
-- Returns (idx, pass): pass "cone" = lined up, "half" = off to the side (the
-- debug overlay's cyan / magenta), nil when nothing lies that way.
-- linedUpOnly: take only a stop that lines up across (tier 0), never one off to the side. Up and
-- Down use it when they look beyond their own zone (on the Deck, a Down past the last Skills row
-- went sideways into the inventory list, because the rest of the window allowed the "half" tier;
-- directions match the screen, so Up and Down leave a zone only for something directly above or
-- below, and at the end of a column Down does nothing).
local function _pickBestWithFallback(elements, focusedIdx, dir, linedUpOnly)
    if not elements or #elements == 0 then return nil, nil end
    if focusedIdx < 1 or focusedIdx > #elements then focusedIdx = 1 end
    local from = elements[focusedIdx]
    local N = ZeD.SpatialNav
    if not (from and N) then return nil, nil end
    local bestIdx, bestTier, bestCost = nil, nil, nil
    for i = 1, #elements do
        local e = elements[i]
        -- A list row scrolled out of view keeps its place as a stop, for its own list's Up and Down (the list
        -- scrolls to it). Another zone's move never picks it: under the list it lay on the container buttons'
        -- line and took their Right (Same type, all nearby was out of reach), above it it took the Filter's Down.
        if i ~= focusedIdx and not (e.offscreen and e.zi ~= from.zi) then
            local tier, c = N.cost(from, e, dir)
            if tier and linedUpOnly and tier ~= 0 then tier = nil end
            if tier and (bestTier == nil or tier < bestTier or (tier == bestTier and c < bestCost)) then
                bestIdx, bestTier, bestCost = i, tier, c
            end
        end
    end
    if not bestIdx then return nil, nil end
    return bestIdx, (bestTier == 0) and "cone" or "half"
end

-- ---------------------------------------------------------------------------
-- DEBUG OVERLAY (F9 toggle, debug builds)
-- ---------------------------------------------------------------------------

--- Toggle / read the overlay state from outside (key handler / console).
function Focus.toggleDebugOverlay()
    _debugOverlay = not _debugOverlay
    print("[ZeD.Input] Focus debug overlay = " .. (_debugOverlay and "ON" or "OFF"))
end
function Focus.isDebugOverlay() return _debugOverlay end

-- Refresh the per-direction picks cache against the current focused element.
-- Called from the focused window's prerender hook below. Stores window-local
-- bounds (post _collectFlat translation) so the overlay paints in the
-- correct coordinate space.
local function _refreshDebugPicks(w)
    if not _debugOverlay then return end
    local elements, locator = _collectFlat(w)
    if #elements == 0 then
        for k in pairs(_debugLastPicks) do _debugLastPicks[k] = nil end
        _debugFocusBox = nil
        return
    end
    local fromIdx = _findCurrentFlatIdx(w, locator) or 1
    -- Cache the focused element's translated bounds for the overlay to paint.
    local focused = elements[fromIdx]
    if focused then
        _debugFocusBox = {
            x = focused.x, y = focused.y, w = focused.w, h = focused.h,
            id = focused.id or "?",
        }
    else
        _debugFocusBox = nil
    end
    for _, dir in ipairs({"up", "down", "left", "right"}) do
        -- Apply the same same-zone-first restriction for U/D that dispatch
        -- uses (vertical stays in its zone while anything more lies that way).
        local searchEls, searchFromIdx = elements, fromIdx
        if dir == "up" or dir == "down" then
            local fromLoc = locator[fromIdx]
            if fromLoc then
                local sameZoneIdx = fromLoc.zoneIdx
                local filteredEls = {}
                local newFromIdx = 1
                for i, loc in ipairs(locator) do
                    if loc.zoneIdx == sameZoneIdx then
                        filteredEls[#filteredEls + 1] = elements[i]
                        if i == fromIdx then newFromIdx = #filteredEls end
                    end
                end
                searchEls, searchFromIdx = filteredEls, newFromIdx
            end
        end
        local pickIdx, pass
        if dir == "left" or dir == "right" then   -- (a ribbon walks its own buttons first, as dispatch does)
            local fromLoc = locator[fromIdx]
            local fz = fromLoc and w._focusRing[fromLoc.zoneIdx]
            if fz and fz.walkLR then
                local zEls, zFrom = {}, 1
                for i, loc in ipairs(locator) do
                    if loc.zoneIdx == fromLoc.zoneIdx then
                        zEls[#zEls + 1] = elements[i]
                        if i == fromIdx then zFrom = #zEls end
                    end
                end
                local pk, ps = _pickBestWithFallback(zEls, zFrom, dir, true)
                if pk then searchEls, searchFromIdx, pickIdx, pass = zEls, zFrom, pk, ps end
            end
        end
        if not pickIdx then pickIdx, pass = _pickBestWithFallback(searchEls, searchFromIdx, dir) end
        if not pickIdx and searchEls ~= elements then   -- nothing more in the panel: the next one over (Up / Down: lined up only)
            searchEls, searchFromIdx = elements, fromIdx
            pickIdx, pass = _pickBestWithFallback(searchEls, searchFromIdx, dir, dir == "up" or dir == "down")
        end
        if pickIdx then
            local el = searchEls[pickIdx]
            _debugLastPicks[dir] = {
                x = el.x, y = el.y, w = el.w, h = el.h,
                pass = pass, id = el.id or "?",
            }
        else
            _debugLastPicks[dir] = nil
        end
    end
end

local function _hasBounds(el)
    return el and type(el.x) == "number" and type(el.y) == "number"
       and type(el.w) == "number" and type(el.h) == "number"
       and el.w > 0 and el.h > 0
end

-- Render the overlay inside the focused window's render cycle. Monkey-patched
-- onto ZeD_Window:render at OnGameStart (see bottom of this file). The hook
-- runs AFTER the original render, in a valid draw context, so panel-local
-- drawRect/drawText work. Wrapped in pcall by the caller — overlay bugs
-- MUST NEVER take down the game.
local function _drawDebugOverlay()
    if not _debugOverlay then return end
    -- The overlay is a D-pad aid; keep it off while the detector says
    -- mouse so a stray F9 never paints over KBM play.
    local mode = ZeD.Input.Detector and ZeD.Input.Detector.getMode and ZeD.Input.Detector.getMode()
    if mode ~= "gamepad" then return end
    local w = _st0.win   -- (F9 is the keyboard's: player 1's focused window)
    if not w or not w.drawRect then return end

    -- Refresh the picks against the current focus state every frame so the
    -- overlay tracks D-pad navigation live. Sets _debugFocusBox + _debugLastPicks.
    _refreshDebugPicks(w)

    if not _hasBounds(_debugFocusBox) then return end

    -- Focused element: yellow bbox + center crosshair. Bounds are window-
    -- local (translated by _collectFlat from source-panel-local).
    local fx, fy, fw, fh = _debugFocusBox.x, _debugFocusBox.y, _debugFocusBox.w, _debugFocusBox.h
    w:drawRect(fx,        fy,        fw, 1,  1.0, 1.0, 0.85, 0.0)
    w:drawRect(fx,        fy + fh-1, fw, 1,  1.0, 1.0, 0.85, 0.0)
    w:drawRect(fx,        fy,        1,  fh, 1.0, 1.0, 0.85, 0.0)
    w:drawRect(fx + fw-1, fy,        1,  fh, 1.0, 1.0, 0.85, 0.0)
    local cx, cy = math.floor(fx + fw * 0.5), math.floor(fy + fh * 0.5)
    w:drawRect(cx - 4, cy,     8, 1, 1.0, 1.0, 0.85, 0.0)
    w:drawRect(cx,     cy - 4, 1, 8, 1.0, 1.0, 0.85, 0.0)

    -- Per-direction pick: cyan = lined up ("cone"), magenta = off to the side ("half").
    -- Draws target bbox + dotted "line" from focus center to target center.
    for _, dir in ipairs({"up", "down", "left", "right"}) do
        local pick = _debugLastPicks[dir]
        if pick and _hasBounds(pick) then
            local r, g, b
            if pick.pass == "cone" then r, g, b = 0.0, 0.85, 0.95
            else                        r, g, b = 0.95, 0.0, 0.85 end
            local px, py, pw, ph = pick.x, pick.y, pick.w, pick.h
            w:drawRect(px,          py,          pw, 1,  0.85, r, g, b)
            w:drawRect(px,          py + ph - 1, pw, 1,  0.85, r, g, b)
            w:drawRect(px,          py,          1,  ph, 0.85, r, g, b)
            w:drawRect(px + pw - 1, py,          1,  ph, 0.85, r, g, b)
            -- Connecting "line" via 32 stamped 2x2 blocks (PZ has no native
            -- line primitive). Walks from focus center to target center.
            local tcx, tcy = px + pw * 0.5, py + ph * 0.5
            for i = 1, 32 do
                local t = i / 32
                local lx = math.floor(cx + (tcx - cx) * t)
                local ly = math.floor(cy + (tcy - cy) * t)
                w:drawRect(lx, ly, 2, 2, 0.65, r, g, b)
            end
        end
    end

    -- HUD legend: focused element id + per-direction pick summary.
    if w.drawText and UIFont and UIFont.Small then
        local hudY = 18
        w:drawText("[F9] cone-nav debug - focus: " .. tostring(_debugFocusBox.id or "?"),
                   4, hudY, 1.0, 0.85, 0.0, 1.0, UIFont.Small)
        for i, dir in ipairs({"up", "down", "left", "right"}) do
            local pick = _debugLastPicks[dir]
            local line, r, g, b
            if pick then
                line = string.format("  %-5s %s -> %s",
                       dir:upper(), pick.pass, tostring(pick.id))
                if pick.pass == "cone" then r, g, b = 0.0, 0.85, 0.95
                else                        r, g, b = 0.95, 0.0, 0.85 end
            else
                line = string.format("  %-5s (no pick)", dir:upper())
                r, g, b = 0.6, 0.6, 0.6
            end
            w:drawText(line, 4, hudY + i * 14, r, g, b, 1.0, UIFont.Small)
        end
    end
end

-- ---------------------------------------------------------------------------
-- DISPATCH HANDLERS
-- ---------------------------------------------------------------------------

-- LB/RB: claim focus on a specific window of player pn (LB = Character, RB = World).
-- Absolute, not toggle — pressing LB while already on Character is a no-op
-- (Focus.claimFocus early-exits when target is already focused). On gamepad
-- both windows are guaranteed open by the window-pair invariant; if one is
-- somehow missing (transition / boot), call ensureBothOpenForGamepad first.
local function _focusWindow(side, pn)
    local CW = ZeD_CharacterWindow
    local WW = ZeD_WorldWindow
    if not CW or not WW then return end

    -- Enforce invariant first — a closed sibling would make the bumper a no-op.
    if CW.ensureBothOpenForGamepad then
        pcall(CW.ensureBothOpenForGamepad, pn)
    end

    local charWin  = CW.getWindow  and CW.getWindow(pn)
    local worldWin = WW.getWindow  and WW.getWindow(pn)
    if not charWin or not worldWin then return end

    local target = (side == "char") and charWin or worldWin

    -- Unshade the target if it was hidden — bumper means "go look at this one".
    Focus.showWin(target)

    Focus.claimFocus(target)
end

--- A window brought back to view: a window with halves (WindowHalves.lua) brings down
--- every half that rolled by itself; any other window comes out of its shade.
function Focus.showWin(w)
    if not w then return end
    if w._halves and ZeD.Halves then ZeD.Halves.showAll(w); return end
    if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end
end

--- True while a window is rolled up, or (a window with halves) has a half rolled by itself.
function Focus.isRolled(w)
    if not w then return false end
    if w.windowShaded then return true end
    return (w._halves and ZeD.Halves and ZeD.Halves.anyRolled(w)) and true or false
end

--- A bumper tapped while a D-pad wheel is up (ZeD_WheelGesture): the bumpers
--- close the wheel and open the windows — the pair open and showing, the pad
--- on that bumper's window. side: "char" or "world"; pn: whose wheel (missing: player 1).
function Focus.openSide(side, pn)
    if type(pn) ~= "number" then pn = 0 end
    if ZeD_CharacterWindow and ZeD_CharacterWindow.ensureBothOpenForGamepad then
        pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, pn)
    end
    for _, M in ipairs({ ZeD_CharacterWindow or {}, ZeD_WorldWindow or {} }) do
        local w = M.getWindow and M.getWindow(pn)
        Focus.showWin(w)
    end
    _focusWindow(side, pn)
end

-- A button (tap): fire the focused element's onActivate (= LMB).
local function _handleConfirm(w)
    local el = Focus.getFocusedElement(w)
    if not el then return end
    -- (the Character window while paused is for looking: ZeD_PausedLook.lua)
    if ZeD.PausedLook and ZeD.PausedLook.blocks(w, el) then return end
    if el.onActivate then pcall(function() getSoundManager():playUISound("UIActivateButton") end) end
    _fireCb("element.onActivate", el.onActivate, w, el)
end

-- A button (hold past A_HOLD_MS): fire onHoldActivate if defined. A list row
-- uses it to mark itself and arm the painted run (InventoryRenderer.padMark);
-- a row's quick use, the double-click's twin, is X held instead.
local function _handleHoldConfirm(w)
    local el = Focus.getFocusedElement(w)
    if not el or not el.onHoldActivate then return end
    if ZeD.PausedLook and ZeD.PausedLook.blocks(w, el) then return end
    _fireCb("element.onHoldActivate", el.onHoldActivate, w, el)
end

-- X button: fire onContextMenu (= RMB) if defined; else onReset if defined
-- (3-option dialogs only — A=Yes, B=No, X=Reset). Mutually exclusive.
local function _handleContextOrReset(w)
    local el = Focus.getFocusedElement(w)
    if not el then return end
    if ZeD.PausedLook and ZeD.PausedLook.blocks(w, el) then return end
    if el.onContextMenu then
        _fireCb("element.onContextMenu", el.onContextMenu, w, el)
    elseif el.onReset then
        _fireCb("element.onReset", el.onReset, w, el)
    end
end

-- B button: purely contextual cancel. If the focused element has onCancel,
-- fire it. If not, NO-OP (no shade-all fallback): B does nothing when there's
-- nothing to cancel; the player presses Y to hide, or flicks the right stick
-- for the aiming escape, to dismiss the windows.
local function _handleBContextual(pn)
    local w = _S(pn).win
    if not w then return end
    local el = Focus.getFocusedElement(w)
    if not el or not el.onCancel then return end
    local took = _fireCbR("element.onCancel", el.onCancel, w, el)
    if took ~= false then pcall(function() getSoundManager():playUISound("UIToggleTickBox") end) end
    -- Beyond the sound, the return value is ignored — B has no fall-through path.
end

-- The registered window of w's player lying `dir` of w on screen (visible,
-- not rolled up), nearest first by the same rectangle rule as the controls;
-- nil when none. Another player's window is never next door.
local function _windowThatWay(w, dir)
    local N = ZeD.SpatialNav
    if not (N and w and w.getX and w._focusEntryZone) then return nil end
    local from = { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
    local pn = _pnOf(w)
    local best, bestTier, bestCost
    for i = 1, #_windowRegistry do
        local o = _windowRegistry[i]
        -- (the window pair only: windows with an entry zone, not the dash or the map's pop-out)
        if o ~= w and o._focusEntryZone and _pnOf(o) == pn and o.isVisible and o:isVisible() and not o.windowShaded and o._focusRing then
            local tier, c = N.cost(from, { x = o:getX(), y = o:getY(), w = o:getWidth(), h = o:getHeight() }, dir)
            if tier and (bestTier == nil or tier < bestTier or (tier == bestTier and c < bestCost)) then
                best, bestTier, bestCost = o, tier, c
            end
        end
    end
    return best
end

-- The open pop-up list. Every pop-up list built
-- on Molecules.drawPopupMenu (Craft and Build's Sort and Show, the Journal's Page
-- and its pages' lists, Health's exercises, Thermal's views, the map's Survey /
-- Color / Paper) hands the window its rows alone while it is open, the elements
-- table marked _menuRows. Up / Down step to the next row that way and stop at the
-- ends (no wrap); Left / Right do nothing; nothing outside the list is reached. A
-- focus left outside the open list (the pointer opened it) goes to its current
-- row on any press. A picks and B shuts, through the rows' own handlers; the
-- list's owner lands the focus back on its box. Returns true when a list is open
-- (the press was its, moving or not).
local function _menuNav(w, dir)
    local ring = w._focusRing
    local zi = nil
    for i = 1, #ring do
        local z = ring[i]
        local els = z.elements
        if z.focusable and els and els._menuRows and #els > 0 and not (z.covered and z.covered(w)) then
            zi = i
            break
        end
    end
    if not zi then return false end
    local z = ring[zi]
    local els = z.elements
    local cur = _clampIdx(z.focusedElementIdx, els)
    local pick = nil
    if w._focusIdx ~= zi then
        pick = cur                                   -- (into the list, on its current row)
    elseif dir == "up" or dir == "down" then
        local from = els[cur]
        local fy = from and type(from.y) == "number" and (from.y + (from.h or 0) * 0.5) or nil
        local best = nil
        for i = 1, #els do
            local e = els[i]
            if fy and i ~= cur and type(e.y) == "number" then
                local d = e.y + (e.h or 0) * 0.5 - fy
                if dir == "up" then d = -d end
                if d > 0.5 and (best == nil or d < best) then best, pick = d, i end
            end
        end
    end
    if _preview then
        _preview.pass = "list"
        if pick then _preview.zone, _preview.id = z.zone, els[pick].id end
        return true
    end
    if not pick then return true end                 -- (an end of the list, or Left / Right)
    local oldZoneIdx = w._focusIdx
    z.focusedElementIdx = pick
    w._focusIdx = zi
    w._focusPendingEntry = nil
    w._navLast = nil
    local el = els[pick]
    if el and el.onFocus then _fireCb("element.onFocus", el.onFocus, w, el) end
    pcall(function() getSoundManager():playUISound("UISelectListItem") end)
    if zi ~= oldZoneIdx and w.onFocusZoneChanged then
        _fireCb("window.onFocusZoneChanged", w.onFocusZoneChanged, w, { new = z, old = ring[oldZoneIdx] })
    end
    print("[ZeD.Input] Focus: list " .. dir .. " -> " .. tostring(el and el.id) .. " [" .. _label(w) .. "]" .. _who(_pnOf(w)))
    return true
end

-- D-pad: an X-hold drag first, then an open pop-up list, then the focused
-- element's own onDpadDir (cursor movement, grid scroll), else the flat
-- spatial pick across all focusable zones.

-- The X-hold drag of w's player, when one is armed: the D-pad goes to the
-- element's drag handler (see the intercept below). True when it did.
local function _xDragMove(w, dir)
    local s = _st[_pnOf(w)]
    if not (s and s.xHeld and s.xUsed and s.xEl and s.xEl.onHoldContextDrag) then return false end
    local el = s.xEl
    _fireCb("element.onHoldContextDrag(dir)",
        function(ww, ee) el.onHoldContextDrag(ww, ee, dir) end,
        s.xWin or w, el)
    return true
end

local function _handleSpatialNav(w, dir)
    _fresh(w)
    if not w or not w._focusRing then return end

    -- X-HOLD DRAG INTERCEPT. If X is held past threshold AND the
    -- captured drag element has onHoldContextDrag, route D-pad presses to
    -- the element's drag handler instead of moving the focus. Focus does NOT shift
    -- during drag — the element stays locked under X-hold; D-pad mutates
    -- its position/state via the callback. Fires BEFORE generic onDpadDir
    -- so a drag-capable element can be reordered without conflicting with
    -- its idle-state navigation behavior.
    if not _preview and _xDragMove(w, dir) then return end

    -- An open pop-up list keeps the controller inside it: the list is modal,
    -- its rows alone are the stops while it is open, and the rest of the
    -- window is out of reach.
    if _menuNav(w, dir) then return end

    -- Pseudo-focusable intercept (unified contract). Element may consume by
    -- returning anything other than false; returning false falls through to
    -- the spatial pick.
    local focEl = Focus.getFocusedElement(w)
    if focEl and focEl.onDpadDir then
        if _preview then   -- (a dry run reports it, then picks as if it fell through)
            _preview.custom = true
            _preview.dpadExits = focEl.dpadExits   -- (the stop says its handler hands the moves it does not hold back)
        end
        if not _preview then
            local result = _fireCbR("element.onDpadDir", focEl.onDpadDir, w, focEl, dir)
            if result ~= false then return end
        end
    end

    -- Generic flat spatial nav. Collect every element from focusable zones,
    -- find the focused element's flat position, then run the two-tier picker
    -- (lined up, else off to the side) through the rules below.
    local elements, locator = _collectFlat(w)
    if #elements == 0 then return end

    local fromIdx = _findCurrentFlatIdx(w, locator) or 1

    -- Back the way you came. The press opposite
    -- to the last move returns to the control that move left, wherever the
    -- picker would go: down from a map tool onto the map and up goes back to
    -- that tool, not to the toolbar's first button; out to the tab column and
    -- back returns to the same row. (Console menus do this.)
    local OPP = { up = "down", down = "up", left = "right", right = "left" }
    local last = w._navLast
    local fromNow = locator[fromIdx] and w._focusRing[locator[fromIdx].zoneIdx]
    local fromNowEl = fromNow and fromNow.elements and fromNow.elements[locator[fromIdx].elementIdx]
    if last and last.dir == OPP[dir] and fromNow and fromNowEl
       and last.toZone == fromNow.zone and last.toId == fromNowEl.id then
        for i, loc in ipairs(locator) do
            local z = w._focusRing[loc.zoneIdx]
            local e = z and z.elements and z.elements[loc.elementIdx]
            if z and e and z.zone == last.fromZone and e.id == last.fromId then
                if _preview then
                    _preview.zone, _preview.id, _preview.pass = z.zone, e.id, "back"
                    return
                end
                w._navLast = { fromZone = fromNow.zone, fromId = fromNowEl.id, dir = dir, toZone = z.zone, toId = e.id }
                print("[ZeD.Input] Focus: spatial " .. dir .. " -> back to " .. tostring(e.id) .. " [" .. _label(w) .. "]" .. _who(_pnOf(w)))
                _applyFlatLanding(w, locator, fromIdx, i)
                return
            end
        end
    end

    -- UP/DOWN stays in the current panel while the panel has anything more
    -- that way, then goes on to the next panel instead of stopping dead.
    -- LEFT/RIGHT remain free to cross panels (that's how users hop between
    -- tab-strip / drawer / inv / container-strip).
    -- Same-zone filter happens AFTER _collectFlat so all the bounds are
    -- already translated to window-local; only the candidate set shrinks.
    local searchEls, searchLoc = elements, locator
    if dir == "up" or dir == "down" then
        local fromLoc = locator[fromIdx]
        if fromLoc then
            local sameZoneIdx = fromLoc.zoneIdx
            local filteredEls, filteredLoc = {}, {}
            local newFromIdx = 1
            for i, loc in ipairs(locator) do
                if loc.zoneIdx == sameZoneIdx then
                    filteredEls[#filteredEls + 1] = elements[i]
                    filteredLoc[#filteredLoc + 1] = loc
                    if i == fromIdx then newFromIdx = #filteredEls end
                end
            end
            searchEls, searchLoc = filteredEls, filteredLoc
            fromIdx = newFromIdx
        end
    end

    -- A ribbon (zone.walkLR: the container buttons under a list) walks its own
    -- buttons first with Left / Right, the next one lined up beside, before
    -- anything else is weighed; past its last one the move goes on as below.
    local newPickIdx, pass
    if dir == "left" or dir == "right" then
        local fromLoc = locator[fromIdx]
        local fz = fromLoc and w._focusRing[fromLoc.zoneIdx]
        if fz and fz.walkLR then
            local zEls, zLoc, zFrom = {}, {}, 1
            for i, loc in ipairs(locator) do
                if loc.zoneIdx == fromLoc.zoneIdx then
                    zEls[#zEls + 1] = elements[i]
                    zLoc[#zLoc + 1] = loc
                    if i == fromIdx then zFrom = #zEls end
                end
            end
            local pk, ps = _pickBestWithFallback(zEls, zFrom, dir, true)
            if pk then searchEls, searchLoc, fromIdx, newPickIdx, pass = zEls, zLoc, zFrom, pk, ps end
        end
    end

    if not newPickIdx then newPickIdx, pass = _pickBestWithFallback(searchEls, fromIdx, dir) end
    if not newPickIdx and searchEls ~= elements then
        -- then the rest of the same panel before any other (Down from a
        -- list's last row reaches the container buttons under it, not a
        -- control in the drawer beside it)
        local fromLoc = locator[_findCurrentFlatIdx(w, locator) or 1]
        local fp = fromLoc and _zonePanel(w, w._focusRing[fromLoc.zoneIdx].zone)
        if fp then
            local pEls, pLoc, pFrom = {}, {}, 1
            for i, loc in ipairs(locator) do
                if _zonePanel(w, w._focusRing[loc.zoneIdx].zone) == fp then
                    pEls[#pEls + 1] = elements[i]
                    pLoc[#pLoc + 1] = loc
                    if loc == fromLoc then pFrom = #pEls end
                end
            end
            -- (Up / Down: only a stop lined up above or below, in this panel's other zones)
            local pk, ps = _pickBestWithFallback(pEls, pFrom, dir, dir == "up" or dir == "down")
            if pk then
                searchEls, searchLoc, newPickIdx, pass = pEls, pLoc, pk, ps
            end
        end
    end
    if not newPickIdx and searchEls ~= elements then
        -- nothing more that way in this panel: the nearest one beyond it (Up / Down: lined up only;
        -- off to the side it is Left's or Right's, so Down at the end of a column does nothing)
        searchEls, searchLoc = elements, locator
        fromIdx = _findCurrentFlatIdx(w, locator) or 1
        newPickIdx, pass = _pickBestWithFallback(searchEls, fromIdx, dir, dir == "up" or dir == "down")
    end
    if not newPickIdx then
        -- nothing more that way in this window: Left / Right go on to the
        -- other window when it sits that way on screen (the pair side by
        -- side), landing where Focus.ensureEntry puts it
        if dir == "left" or dir == "right" then
            local other = _windowThatWay(w, dir)
            if other then
                if _preview then
                    _preview.zone, _preview.id, _preview.pass = "window", _label(other), "window"
                    return
                end
                print("[ZeD.Input] Focus: spatial " .. dir .. " -> window " .. _label(other) .. _who(_pnOf(w)))
                Focus.claimFocus(other)
                pcall(function() getSoundManager():playUISound("UISelectListItem") end)
            end
        end
        return
    end

    -- Translate filtered-list pick back to the original flat list so
    -- _applyFlatLanding writes the correct (zoneIdx, elementIdx).
    local newFlatIdx
    if searchEls == elements then
        newFlatIdx = newPickIdx
    else
        local pickedLoc = searchLoc[newPickIdx]
        for i, loc in ipairs(locator) do
            if loc == pickedLoc then newFlatIdx = i; break end
        end
    end
    if not newFlatIdx then return end

    -- Recover the original fromIdx in the unfiltered list for the log line.
    local logFromIdx = _findCurrentFlatIdx(w, locator) or 1

    -- Left / Right with nothing level in this panel go on to the next panel
    -- that way, never to a control above or below in the same panel. (A
    -- row's Left went to the container buttons under the list, not the tab
    -- column; its Right to the view button over the list, not the
    -- container column.)
    if (dir == "left" or dir == "right") and pass == "half" then
        local fl, tl = locator[logFromIdx], locator[newFlatIdx]
        local fp = fl and _zonePanel(w, w._focusRing[fl.zoneIdx].zone)
        local tp = tl and _zonePanel(w, w._focusRing[tl.zoneIdx].zone)
        if fp and fp == tp then
            local subEls, subIdx = { elements[logFromIdx] }, {}
            for i, loc in ipairs(locator) do
                if _zonePanel(w, w._focusRing[loc.zoneIdx].zone) ~= fp then
                    subEls[#subEls + 1] = elements[i]
                    subIdx[#subEls] = i
                end
            end
            local pick, p2 = _pickBestWithFallback(subEls, 1, dir)
            if pick and subIdx[pick] then newFlatIdx, pass = subIdx[pick], p2 end
        end
    end

    -- A move never jumps over a whole panel. The picker prefers a
    -- control LINED UP with the focused one, so Left from an inventory row went
    -- straight past the open item card (its buttons sit at the card's top and
    -- bottom, rarely level with the row) to the tab column. When a panel with
    -- focusables lies between here and the pick, across the focused control's
    -- span, land on that panel's best control instead (any angle).
    do
        local fromLoc, toLoc = locator[logFromIdx], locator[newFlatIdx]
        local fromEl, toEl = elements[logFromIdx], elements[newFlatIdx]
        if fromLoc and toLoc and fromEl and toEl and fromLoc.zoneIdx ~= toLoc.zoneIdx then
            local horiz = (dir == "left" or dir == "right")
            local fc = horiz and (fromEl.x + fromEl.w * 0.5) or (fromEl.y + fromEl.h * 0.5)
            local tc = horiz and (toEl.x + toEl.w * 0.5) or (toEl.y + toEl.h * 0.5)
            local fromPanel = _zonePanel(w, w._focusRing[fromLoc.zoneIdx].zone)
            local toPanel   = _zonePanel(w, w._focusRing[toLoc.zoneIdx].zone)
            local bestZi, bestDist
            for zi = 1, #w._focusRing do
                local z = w._focusRing[zi]
                local p = (zi ~= fromLoc.zoneIdx and zi ~= toLoc.zoneIdx
                           and z.focusable and z.elements and #z.elements > 0)
                          and _zonePanel(w, z.zone) or nil
                if p and p ~= fromPanel and p ~= toPanel and p:isVisible() then
                    local px, py = _zoneOffset(w, z.zone)
                    local pw, ph = p:getWidth(), p:getHeight()
                    local pc = horiz and (px + pw * 0.5) or (py + ph * 0.5)
                    local spans
                    if horiz then spans = py < fromEl.y + fromEl.h and py + ph > fromEl.y
                    else          spans = px < fromEl.x + fromEl.w and px + pw > fromEl.x end
                    local d = math.abs(pc - fc)
                    if spans and (pc - fc) * (tc - fc) > 0 and d < math.abs(tc - fc)
                       and (not bestDist or d < bestDist) then
                        bestZi, bestDist = zi, d
                    end
                end
            end
            if bestZi then
                local subEls, subIdx = { fromEl }, {}
                for i, loc in ipairs(locator) do
                    if loc.zoneIdx == bestZi then
                        subEls[#subEls + 1] = elements[i]
                        subIdx[#subEls] = i
                    end
                end
                local pick = _pickBestWithFallback(subEls, 1, dir, dir == "up" or dir == "down")
                if pick and subIdx[pick] then newFlatIdx, pass = subIdx[pick], "panel" end
            end
        end
    end

    -- Cross-zone landing on a TAB STRIP snaps to the active tab,
    -- not the spatially-closest tab. Rationale: when the player moves
    -- INTO the tab waterfall from another panel, the active tab is the
    -- intuitive starting point — they came here to see "what's open" and
    -- (likely) switch from there. Without this, the pick lands on whichever
    -- tab is closest to the source y, which is surprising and forces a
    -- second hop. Only fires on cross-zone landings (intra-zone D-pad
    -- navigation through the strip is unaffected).
    do
        local newLoc = locator[newFlatIdx]
        local oldLoc = locator[logFromIdx]
        if newLoc and oldLoc and newLoc.zoneIdx ~= oldLoc.zoneIdx then
            local newZone = w._focusRing[newLoc.zoneIdx]
            local zname   = newZone and newZone.zone
            if (zname == "charTabBar" or zname == "worldTabBar")
               and w._activeTab and newZone.elements then
                for ei, el in ipairs(newZone.elements) do
                    if el.tabId == w._activeTab then
                        for fi, loc in ipairs(locator) do
                            if loc.zoneIdx == newLoc.zoneIdx
                               and loc.elementIdx == ei then
                                newFlatIdx = fi
                                break
                            end
                        end
                        break
                    end
                end
            end
        end
    end

    -- The same rule for any zone that names its landing
    -- (zone.landOn(w, zone, dir) -> an element index, or nil for the spatial
    -- pick): a container column lands on the container on show (like a tab
    -- column on its active tab), a card on its primary action, an item list
    -- on the row focus last had when entered from the side, so going over and
    -- coming back is predictable whatever height the move started from. The
    -- list's own rule says nil for Up / Down (up from the buttons under the
    -- list reaches its last row).
    do
        local newLoc = locator[newFlatIdx]
        local oldLoc = locator[logFromIdx]
        if newLoc and oldLoc and newLoc.zoneIdx ~= oldLoc.zoneIdx then
            local newZone = w._focusRing[newLoc.zoneIdx]
            if newZone and newZone.landOn then
                local okL, ei = pcall(newZone.landOn, w, newZone, dir)
                if okL and type(ei) == "number" and newZone.elements and newZone.elements[ei] then
                    for fi, loc in ipairs(locator) do
                        if loc.zoneIdx == newLoc.zoneIdx and loc.elementIdx == ei then
                            newFlatIdx, pass = fi, "land"
                            break
                        end
                    end
                end
            end
        end
    end

    if _preview then
        local z = w._focusRing[locator[newFlatIdx].zoneIdx]
        local e = z and z.elements and z.elements[locator[newFlatIdx].elementIdx]
        _preview.zone, _preview.id, _preview.pass = z and z.zone, e and e.id, pass
        return
    end
    -- remember this move, for the way back (above)
    do
        local fz = locator[logFromIdx] and w._focusRing[locator[logFromIdx].zoneIdx]
        local fe = fz and fz.elements and fz.elements[locator[logFromIdx].elementIdx]
        local tz = w._focusRing[locator[newFlatIdx].zoneIdx]
        local te = tz and tz.elements and tz.elements[locator[newFlatIdx].elementIdx]
        if fz and fe and tz and te and fe.id and te.id then
            w._navLast = { fromZone = fz.zone, fromId = fe.id, dir = dir, toZone = tz.zone, toId = te.id }
        else
            w._navLast = nil
        end
    end
    print("[ZeD.Input] Focus: spatial " .. dir .. " -> flat[" .. newFlatIdx
       .. "/" .. #elements .. "] (" .. tostring(pass) .. ") zone="
       .. tostring(w._focusRing[locator[newFlatIdx].zoneIdx].zone)
       .. " [" .. _label(w) .. "]" .. _who(_pnOf(w)))
    _applyFlatLanding(w, locator, logFromIdx, newFlatIdx)
end

-- The painted run: while A stays held past its hold and the window has a stroke armed
-- (w._gpPaint, set by a row's onHoldActivate), a D-pad move lands as usual and the row landed on takes
-- the stroke's mark through its onPaint. Letting A go ends the stroke (the release clears w._gpPaint).
local _spatialNavCore = _handleSpatialNav
_handleSpatialNav = function(w, dir)
    _spatialNavCore(w, dir)
    local s = w and _st[_pnOf(w)]
    if (not _preview) and s and s.aHeld and s.aUsed and w._gpPaint then
        local el = Focus.getFocusedElement(w)
        if el and el.onPaint then
            local paint = w._gpPaint
            _fireCb("element.onPaint", function(ww, ee) el.onPaint(ww, ee, paint) end, w, el)
        end
    end
end

-- Hide every registered window of player pn (windowshade) + release their
-- focus: the aiming escape. Idempotent. A window with halves (WindowHalves.lua)
-- rolls only its unpinned halves: a pinned half stays as it is.
local function _hideAllWindows(reason, pn)
    if _countOf(pn) == 0 then return end
    print("[ZeD.Input] Focus: hideAll (" .. (reason or "?") .. ")" .. _who(pn))
    for _, w in ipairs(_windowRegistry) do
        if _pnOf(w) ~= pn then
            -- (another player's window: theirs to roll up)
        elseif w._halves and ZeD.Halves then
            ZeD.Halves.aim(w)
        elseif w.setWindowShaded and not w.windowShaded then
            w:setWindowShaded(true)
        end
    end
    Focus.releaseFocus(pn)
end

-- Close every registered window of player pn (hard close). Copies them first
-- because close() re-enters unregisterWindow and mutates the array mid-iteration.
local function _closeAllWindows(pn)
    if _countOf(pn) == 0 then return end
    print("[ZeD.Input] Focus: closeAll" .. _who(pn))
    local toClose = {}
    for _, w in ipairs(_windowRegistry) do
        if _pnOf(w) == pn then toClose[#toClose + 1] = w end
    end
    for _, w in ipairs(toClose) do
        if w.close then
            pcall(function() w:close() end)
        end
    end
    Focus.releaseFocus(pn)
end

-- Y tap: player pn's paired visibility toggle.
--   both closed   → open both (Character focus)
--   both visible  → hide both (windowshade, release focus)
--   both shaded   → unhide both (Character focus)
--   mixed         → normalize via ensureBothOpenForGamepad + unhide all,
--                   focus Character (gamepad invariant: paired)
local function _handleYTap(pn)
    local CW = ZeD_CharacterWindow
    local WW = ZeD_WorldWindow
    if not CW or not WW then return end

    local charOpen  = CW.isOpen and CW.isOpen(pn)
    local worldOpen = WW.isOpen and WW.isOpen(pn)

    -- Both closed: open both.
    if (not charOpen) and (not worldOpen) then
        if CW.ensureBothOpenForGamepad then
            CW.ensureBothOpenForGamepad(pn)
        elseif CW.toggleBothPaired then
            CW.toggleBothPaired(pn)
        end
        local charWin = CW.getWindow and CW.getWindow(pn)
        if charWin then Focus.claimFocus(charWin) end
        print("[ZeD.Input] Focus: Y tap - opened pair, Character focus" .. _who(pn))
        return
    end

    -- Mixed (one open, one closed): enforce invariant.
    if charOpen ~= worldOpen then
        if CW.ensureBothOpenForGamepad then CW.ensureBothOpenForGamepad(pn) end
        local charWin = CW.getWindow and CW.getWindow(pn)
        if charWin then
            Focus.showWin(charWin)
            Focus.claimFocus(charWin)
        end
        Focus.showWin(WW.getWindow and WW.getWindow(pn))
        print("[ZeD.Input] Focus: Y tap - normalized pair, Character focus" .. _who(pn))
        return
    end

    -- Both open: visibility toggle (paired).
    local charWin  = CW.getWindow  and CW.getWindow(pn)
    local worldWin = WW.getWindow  and WW.getWindow(pn)
    if not charWin or not worldWin then return end

    -- (a window with a half rolled by itself counts as rolled: one Y brings that half
    -- back, and never rolls the pinned half beside it, WindowHalves)
    local charShaded  = Focus.isRolled(charWin)
    local worldShaded = Focus.isRolled(worldWin)
    local bothShaded  = charShaded and worldShaded
    local bothVisible = (not charShaded) and (not worldShaded)

    if bothVisible then
        if charWin.setWindowShaded  then charWin:setWindowShaded(true)  end
        if worldWin.setWindowShaded then worldWin:setWindowShaded(true) end
        Focus.releaseFocus(pn)
        print("[ZeD.Input] Focus: Y tap - hide pair" .. _who(pn))
        return
    end

    if bothShaded then
        Focus.showWin(charWin)
        Focus.showWin(worldWin)
        Focus.claimFocus(charWin)
        print("[ZeD.Input] Focus: Y tap - unhide pair, Character focus" .. _who(pn))
        return
    end

    -- One shaded one not: normalize to both-visible.
    if charShaded  then Focus.showWin(charWin)  end
    if worldShaded then Focus.showWin(worldWin) end
    Focus.claimFocus(charWin)
    print("[ZeD.Input] Focus: Y tap - normalized visibility, Character focus" .. _who(pn))
end

-- Y hold: close every registered window of player pn (full lifecycle teardown
-- — each window's close() unregisters it through Focus.unregisterWindow).
local function _handleYHold(pn)
    print("[ZeD.Input] Focus: Y hold - close pair" .. _who(pn))
    _closeAllWindows(pn)
end

-- ---------------------------------------------------------------------------
-- DISPATCH ENTRY POINTS
-- ---------------------------------------------------------------------------

-- The player a press on w belongs to: w's own. nil when the pad pressing is
-- another local player's (that slot's engine focus left on w): such a press
-- is dropped, never worked on w's player's holds or focus. A press with no
-- joypadData, or a pad not playing yet, counts as w's player's, as before.
local function _pressPn(w, joypadData)
    local pn = _pnOf(w)
    local jp = (type(joypadData) == "table") and joypadData.player or nil
    if type(jp) == "number" and jp ~= pn then return nil end
    return pn
end

--- A pad button went down while w holds the pad (w's onJoypadDown stub calls
--- this). Shows the focus marks, names the button through ActionMap and
--- routes it: A, X and Y arm their tap-vs-hold timers (settled on the tick),
--- LB / RB pick a window, B cancels, L3 / R3 change the list's view.
--- The press is worked on the record of w's player; a press from another
--- player's pad (its slot's engine focus left on w) is dropped.
function Focus.dispatchJoypadDown(w, button, joypadData)
    if not w then return end
    local pn = _pressPn(w, joypadData)
    if pn == nil then return end
    local s = _S(pn)
    _fresh(w)
    _showCues(s)
    -- B also hides the balloon that is up until the focus moves on (B still does its own job)
    if button == Joypad.BButton and ZeD.Balloon and ZeD.Balloon.dismiss then ZeD.Balloon.dismiss() end
    local actions = ZeD.Input.Action and ZeD.Input.Action.fromGamepadButton
                    and ZeD.Input.Action.fromGamepadButton(button)
    if not actions then return end

    for i = 1, #actions do
        local aid = actions[i]
        if aid == "confirm" then
            -- A = tap-vs-hold. Defer firing until release (tap → onActivate)
            -- or hold threshold (A_HOLD_MS → onHoldActivate). Re-press during
            -- a hold cycle is a noop.
            if not s.aHeld then
                s.aHeld  = true
                s.aStart = getTimestampMs()
                s.aUsed  = false
                s.aWin   = w
            end
            return
        elseif aid == "context_menu" then
            -- X = tap-vs-hold. Tap (release < X_HOLD_MS) fires
            -- onContextMenu/onReset. Hold past threshold enters drag mode
            -- (onHoldContextDrag fires with no dir; subsequent D-pad presses
            -- fire onHoldContextDrag(dir); release fires onHoldContextRelease).
            -- Defer firing until release/threshold (mirror of A).
            if not s.xHeld then
                s.xHeld  = true
                s.xStart = getTimestampMs()
                s.xUsed  = false
                s.xWin   = w
                s.xEl    = Focus.getFocusedElement(w)
            end
            return
        elseif aid == "window_prev" then
            _focusWindow("char", pn); return    -- LB → Character (absolute)
        elseif aid == "window_next" then
            _focusWindow("world", pn); return   -- RB → World (absolute)
        elseif aid == "cancel" then
            -- B is immediate (no hold): a purely contextual cancel.
            _handleBContextual(pn); return
        elseif aid == "window_control" then
            -- Y press arms hold timer. OnTick decides tap vs hold.
            if not s.yHeld then
                s.yHeld  = true
                s.yStart = getTimestampMs()
                s.yUsed  = false
            end
            return
        elseif aid == "list_sort" or aid == "list_view" then
            -- L3 / R3: only here, with a window holding the pad, and only a
            -- view change of its list — stick clicks misfire under combat
            -- tension, so they never carry a state-changing job (ActionMap)
            local R = ZeD.InventoryRenderer
            local fn = R and ((aid == "list_sort") and R.padSort or R.padView)
            if fn then pcall(fn, w) end
            return
        end
        -- Other action IDs fall through on purpose. nav_* arrive here too —
        -- the engine fires onJoypadDown AND onJoypadDir* for one D-pad press —
        -- and the D-pad moves only through dispatchJoypadDir, or every press
        -- would step twice. layout_mode and strip_* have no dispatcher yet
        -- (the D-pad wheels, ZeD_DpadWheels, have the unfocused D-pad), and
        -- inspect has no pad binding.
    end
end

-- Focus requests waiting for their element to exist (worked on the tick).
local _focusSoon = {}
--- Put focus on an element by id, in a zone of window w, as soon as it exists
--- (an event that rebuilds a zone, like folding the map back, names where focus
--- should land; the element appears a frame or two later). Tries for ~1 s.
function Focus.focusByIdSoon(w, zoneName, id)
    _focusSoon[#_focusSoon + 1] = { w = w, zone = zoneName, pred = function(e) return e.id == id end, tries = 60 }
end
--- The same for any test (pred(el, i)), after `delay` ticks (a view that has
--- to draw once first, like a card swapping to another item).
function Focus.focusSoon(w, zoneName, pred, delay)
    _focusSoon[#_focusSoon + 1] = { w = w, zone = zoneName, pred = pred, tries = 60, delay = delay or 0 }
end
--- A card just opened (A on a row): focus goes to its primary action (the
--- element marked isPrimary, else its first), so A again does it.
function Focus.focusPrimarySoon(w, zoneName, delay)
    _focusSoon[#_focusSoon + 1] = { w = w, zone = zoneName, primary = true, tries = 60, delay = delay or 0 }
end

-- Whether a landing waits on window w's stops (the calls above)
function Focus.soonPending(w)
    for i = 1, #_focusSoon do
        if _focusSoon[i].w == w then return true end
    end
    return false
end

-- Whether window w's tab stops may wait a frame (the World and Character windows rebuild them every frame): the
-- mouse and keyboard in use (the detector says "kbm", not "unknown"), no focus mark showing, no landing waiting for
-- the stops (focusByIdSoon and the like) and none a tab named for its next rebuild (the card jump on Craft and
-- Build, the new zone and the breadcrumb on Animals, the vehicle's target), so what a rebuild does with those comes
-- on the frame it always did. Anything here that reads the stops brings them up to date first (w._focusFresh).
-- The mouse and keyboard are player 1's: another player's window is always on a pad, so its stops never wait.
function Focus.stopsMayWait(w)
    local D = ZeD.Input.Detector
    if not (w and D and D.getMode and D.getMode() == "kbm") then return false end
    if _pnOf(w) ~= 0 then return false end
    if ZEDQA_FRESH_STOPS then return false end   -- (QA scripts read w._focusRing directly: the QA prelude keeps the stops fresh)
    if _st0.cues or Focus.soonPending(w) then return false end
    if w._mechFocusTarget or w._animalsFocusAfterCreate or w._animalsNavFocusTarget then return false end
    local cs, bs = w._craftState, w._buildState
    if (cs and cs._gpPendingCardJump) or (bs and bs._gpPendingCardJump) then return false end
    return true
end
local function _focusSoonTick()
    if #_focusSoon == 0 then return end
    for i = #_focusSoon, 1, -1 do
        local f = _focusSoon[i]
        local done = false
        _fresh(f.w)
        if f.delay and f.delay > 0 then
            f.delay = f.delay - 1
        else
            local pred = f.pred
            if f.primary then
                pred = nil
                for _, z in ipairs(f.w and f.w._focusRing or {}) do
                    if z.zone == f.zone and z.focusable and z.elements and #z.elements > 0 then
                        pred = function(e, ei) return ei == 1 end
                        for _, e in ipairs(z.elements) do
                            if e.isPrimary then pred = function(e2) return e2.isPrimary end; break end
                        end
                    end
                end
            end
            if pred then done = Focus.focusWhere(f.w, f.zone, pred) ~= nil end
            f.tries = f.tries - 1
        end
        if done or f.tries <= 0 then table.remove(_focusSoon, i) end
    end
end
if Events and Events.OnTick then Events.OnTick.Add(_focusSoonTick) end

--- A dry run for the QA nav scripts: where a D-pad press would go from the
--- focused element, without moving focus or running any handler. Returns
--- { zone, id, pass } (nil zone = nothing that way), custom = true when the
--- element has its own D-pad handler (which would run first), dpadExits =
--- true when that element says its handler returns false for the moves it
--- does not hold (so the pick shown is where those go), and err = true when
--- the dry run threw.
function Focus.previewMove(w, dir)
    _preview = {}
    local ok = pcall(_handleSpatialNav, w, dir)
    local r = _preview
    _preview = nil
    if not ok then r.err = true end
    return r
end

--- Every stop of the window as the D-pad sees it, window-local: { zone, zi,
--- ei, id, x, y, w, h, el } in flat order. The QA pad map
--- (ZeDUI/tools/qa/zedqa_padmap.lua) reads it.
function Focus.flatElements(w)
    _fresh(w)
    local elements, locator = _collectFlat(w)
    local out = {}
    for i, t in ipairs(elements) do
        local loc = locator[i]
        local z = w._focusRing[loc.zoneIdx]
        out[i] = { zone = z.zone, zi = loc.zoneIdx, ei = loc.elementIdx, id = t.id,
                   x = t.x, y = t.y, w = t.w, h = t.h, el = t._origRef }
    end
    return out
end

--- A D-pad press while w holds the pad (w's onJoypadDir* stubs call this;
--- dir is "up" / "down" / "left" / "right"). Shows the focus marks, starts
--- the hold-to-repeat clock and runs the move. A press from another player's
--- pad is dropped, as in dispatchJoypadDown.
function Focus.dispatchJoypadDir(w, dir, joypadData)
    if not w then return end
    local pn = _pressPn(w, joypadData)
    if pn == nil then return end
    local s = _S(pn)
    _showCues(s)

    -- Track hold-start for auto-repeat. Two repeats reach the move while the
    -- D-pad stays down, and both stay: the tick's below (holdInitMs, then
    -- every holdRepeatMs) and the engine's own (it calls onJoypadDir* again
    -- after 300 ms, then faster, JoyPadSetup.lua).
    if s.dDir ~= dir then
        s.dDir   = dir
        s.dStart = getTimestampMs()
        s.dLast  = s.dStart
    end

    _handleSpatialNav(w, dir)
end

-- ---------------------------------------------------------------------------
-- ONTICK POLL — every tick, and every drawn frame while the game is paused;
-- player 1 first, then each other local player who is playing, each on their
-- own pad and record
--   (A) Mode gate (outside gamepad mode, every hold and repeat is dropped;
--       players 2-4 are always on a pad)
--   then: never focus with nothing lit (Focus.ensureEntry), and hand a pad
--         left with no focus back to the focused window
--   (B) Global Y rising edge (only when no window focused) — opens the pair
--   (C) Y hold-timer release / threshold
--   (C2) A tap-vs-hold resolver
--   (C3) X tap-vs-hold resolver
--   (D) Aiming escape (right stick magnitude² > T.gp.aimingThresholdSq)
--   (E) D-pad hold-to-repeat
-- ---------------------------------------------------------------------------

local function _currentDpadDir(joypadData)
    if not joypadData or not joypadData.id then return nil end
    local jid = joypadData.id
    -- B42.17: JoypadButton.<n>:isDown(id) replaces the removed isJoypadPressed.
    if JoypadButton.DPadUp:isDown(jid)    then return "up"    end
    if JoypadButton.DPadDown:isDown(jid)  then return "down"  end
    if JoypadButton.DPadLeft:isDown(jid)  then return "left"  end
    if JoypadButton.DPadRight:isDown(jid) then return "right" end
    return nil
end

--- QA hook: a QA script may hold a pad button on a rig with no pad bound.
--- Focus.qaButton(name, true, pn) holds the button of player pn's pad (pn
--- missing: player 1's), false lets it go, nil hands it back to the pad.
function Focus.qaButton(name, down, pn)
    local s = _S(pn)
    local was = s.qa[name]
    if was == nil and down ~= nil then s.qaN = s.qaN + 1 end
    if was ~= nil and down == nil then s.qaN = s.qaN - 1 end
    s.qa[name] = down
end
local function _btnDown(name, jid, s)
    local o = s.qa[name]
    if o ~= nil then return o end
    if jid == nil then return false end
    return JoypadButton[name]:isDown(jid)
end

--- True while an A press held past its hold on window w is still down: the hold fired the focused element's
--- onHoldActivate (once, at A_HOLD_MS) and A has not come up since. A key that acts for as long as A is held
--- (the Fishing tab's Reel in) reads this every frame. Driven by the same reads as the hold, QA's hook included.
--- Read from the record of w's player (w nil: player 1's), so one player's held A is never another's.
function Focus.holdingA(w)
    local s = _st[_pnOf(w)]
    if not s then return false end
    return (s.aHeld and s.aUsed and (w == nil or (s.aWin or s.win) == w)) and true or false
end

-- Every hold and the D-pad repeat dropped without firing (the mouse took
-- over, or the pad went away mid-hold: a hold cut short is no tap).
local function _dropHolds(s)
    if s.dDir      then s.dDir = nil end
    if s.yHeld     then s.yHeld = false; s.yUsed = false end
    if s.prevY     then s.prevY = false end
    if s.wsLatched then s.wsLatched = false end
    if s.aHeld     then if s.aWin then s.aWin._gpPaint = nil end; s.aHeld = false; s.aUsed = false; s.aWin = nil end
    if s.xHeld     then s.xHeld = false; s.xUsed = false; s.xWin = nil; s.xEl = nil end
end

-- A player's pad id to read, or nil: a slot with no pad, one that lost its
-- pad (id -1, which the engine reads as every pad's A, B, X and Y), or a
-- controller no longer connected (it reads all up).
local function _padOf(pn)
    local jd = getJoypadData and getJoypadData(pn)
    local jid = jd and jd.id or nil
    if type(jid) == "number" and (jid < 0 or (isControllerConnected and not isControllerConnected(jid))) then
        jid = nil
    end
    return jid, jd
end

-- The holds dropped and Y's last level taken from the pad as it is, so a
-- button held through a new character, a respawn or a return to play is no
-- new press. The window and the marks stay.
local function _resume(s, pn)
    _dropHolds(s)
    local jid = _padOf(pn)
    if jid ~= nil and JoypadButton then s.prevY = _btnDown("Y", jid, s) and true or false end
    s.away = false
end

-- the Y, A and X holds of player pn: a tap on release, the hold at its threshold (A and X
-- 350 ms; Y the gp.holdMs token, 400). jid may be nil (no pad bound) only while QA's hook holds
-- a button of this player (Focus.qaButton): a nil pad reads as every button up.
local function _holdTicks(s, jid, pn)
    if Focus.held() then
        s.yHeld, s.yUsed = false, false
        s.prevY = _btnDown("Y", jid, s)
        return
    end
    if not s.win then
        -- (Y opens ZeD's pair only for a player whose windows they are, ZeD.windowsFor: the
        -- others' Y is the game's own inventory)
        if _ownsWindows(pn) then
            local yNow = _btnDown("Y", jid, s)
            -- (with a bumper held, Y is a quick action chord, ZeD_QuickChords.lua, never the windows)
            local bumper = _btnDown("LeftBump", jid, s) or _btnDown("RightBump", jid, s)
            -- (a D-pad wheel up: Y does nothing. This raw poll would read Y straight past the wheel's hold on the pad.)
            local wheel = ZeD.DpadWheels and ZeD.DpadWheels.state and ZeD.DpadWheels.state[pn]
            if yNow and (not s.prevY) and (not s.yHeld) and not bumper and not wheel then
                s.yHeld  = true
                s.yStart = getTimestampMs()
                s.yUsed  = false
            end
            s.prevY = yNow
        end
    else
        s.prevY = false
    end

    -- (C) Y hold-timer.
    if s.yHeld then
        local stillDown = _btnDown("Y", jid, s)
        if stillDown then
            if (not s.yUsed) and (getTimestampMs() - s.yStart) >= _holdMs() then
                _handleYHold(pn)
                s.yUsed = true
            end
        else
            if not s.yUsed then _handleYTap(pn) end
            s.yHeld  = false
            s.yStart = 0
            s.yUsed  = false
        end
    end

    -- (C2) A tap-vs-hold resolver. Tap → onActivate on release; hold past
    -- A_HOLD_MS → onHoldActivate (if focused element defines it). Released-
    -- early without a hold target fires onActivate; released-early after
    -- threshold already fired _handleHoldConfirm and is marked consumed.
    if s.aHeld then
        local stillDown = _btnDown("A", jid, s)
        if stillDown then
            if (not s.aUsed) and (getTimestampMs() - s.aStart) >= A_HOLD_MS then
                local targetW = s.aWin or s.win
                local el = targetW and Focus.getFocusedElement(targetW) or nil
                if el and el.onHoldActivate then
                    _handleHoldConfirm(targetW)
                    s.aUsed = true
                end
            end
        else
            if not s.aUsed then
                local targetW = s.aWin or s.win
                if targetW then _handleConfirm(targetW) end
            end
            if s.aWin then s.aWin._gpPaint = nil end   -- (the painted run ends with the hold)
            s.aHeld  = false
            s.aStart = 0
            s.aUsed  = false
            s.aWin   = nil
        end
    end

    -- (C3) X tap-vs-hold resolver. Tap → onContextMenu/onReset on
    -- release; hold past X_HOLD_MS → onHoldContextDrag(w, el, nil) (drag-mode
    -- entry, dir == nil signals "armed"), else onHoldContext once. On release
    -- after consumption, fire onHoldContextRelease (commit). s.xEl is
    -- captured at press to lock the drag target — focused element may shift
    -- if a D-pad move fires mid-hold (defensive, shouldn't happen since D-pad
    -- is intercepted).
    if s.xHeld then
        local stillDown = _btnDown("X", jid, s)
        if stillDown then
            if (not s.xUsed) and (getTimestampMs() - s.xStart) >= X_HOLD_MS then
                local el = s.xEl
                if el and el.onHoldContextDrag then
                    _fireCb("element.onHoldContextDrag(arm)",
                        function(w, e) el.onHoldContextDrag(w, e, nil) end,
                        s.xWin or s.win, el)
                    s.xUsed = true
                elseif el and el.onHoldContext then
                    -- a one-shot hold with no drag (hold X on a row is the quick use)
                    _fireCb("element.onHoldContext", el.onHoldContext, s.xWin or s.win, el)
                    s.xUsed = true
                end
            end
        else
            if s.xUsed then
                -- Was a hold — fire release callback if defined.
                local targetW = s.xWin or s.win
                local el = s.xEl
                if el and el.onHoldContextRelease then
                    _fireCb("element.onHoldContextRelease",
                        el.onHoldContextRelease, targetW, el)
                end
            else
                -- Was a tap — fire normal context-menu / reset path.
                local targetW = s.xWin or s.win
                if targetW then _handleContextOrReset(targetW) end
            end
            s.xHeld  = false
            s.xStart = 0
            s.xUsed  = false
            s.xWin   = nil
            s.xEl    = nil
        end
    end
end

-- The right stick's strongest push that counts for player pn's aiming escape.
-- Player 1: every connected controller but the ones another local player plays
-- with (a pad nobody plays with still counts, as it always did: the Deck's
-- phantom slot). Players 2-4: their own pad only. Walk the controllers by
-- index: getControllerAxisValue wants the int index, not
-- joypadData.controller (a Lua table). No math.abs() on axis reads — on
-- drivers whose triggers rest at -1 it reads a resting trigger as fully
-- pulled; the stick's ax²+ay² is never negative anyway.
local function _aimMagSq(pn, jid)
    if pn ~= 0 then
        local rx = getControllerAxisValue(jid, AXIS_RSTICK_X) or 0
        local ry = getControllerAxisValue(jid, AXIS_RSTICK_Y) or 0
        return rx * rx + ry * ry
    end
    local D = ZeD.Input.Detector
    local owner = D and D.padOwner
    local maxMagSq = 0
    local n = (getControllerCount and getControllerCount()) or 0
    for ctlIdx = 0, n - 1 do
        if isControllerConnected and isControllerConnected(ctlIdx) then
            local o = owner and owner(ctlIdx) or nil
            if o == nil or o == 0 then
                local rx = getControllerAxisValue(ctlIdx, AXIS_RSTICK_X) or 0
                local ry = getControllerAxisValue(ctlIdx, AXIS_RSTICK_Y) or 0
                local m2 = rx*rx + ry*ry
                if m2 > maxMagSq then maxMagSq = m2 end
            end
        end
    end
    return maxMagSq
end

-- One player's poll; player 1's is the poll this file had before split-screen, step for step.
local function _tickPlayer(pn, s)
    -- (A) Mode gate.
    if _modeOf(pn) ~= "gamepad" then
        _dropHolds(s)
        return
    end

    -- Never focus with nothing lit. A fresh window lands on its
    -- list's first row once the rows exist; focus left on a zone that went
    -- away (a card closed, a tab emptied) moves to the list (Focus.ensureEntry)
    if s.win and (s.win._focusPendingEntry or not _focusLive(s.win)) then
        local ok, err = pcall(Focus.ensureEntry, s.win)
        if not ok then print("[ZeD.Input] Focus: ensureEntry failed: " .. tostring(err)) end
    end
    -- A prompt or menu that closed and left the pad with no focus at all
    -- hands it back to the focused window, on the element it had; left
    -- alone, the pad would go to the game and the next press act in the world
    if s.win and JoypadState and JoypadState.players and JoypadState.players[pn + 1]
       and getJoypadFocus and getJoypadFocus(pn) == nil
       and s.win:isVisible() and not s.win.windowShaded then
        _pushEngineFocus(s.win, pn)
    end

    local jid, jd = _padOf(pn)
    -- no pad to read: the holds go without firing, unless QA's hook is holding
    -- a button (it drives the holds with no pad bound)
    if jid == nil and s.qaN == 0 then
        _dropHolds(s)
        return
    end
    _holdTicks(s, jid, pn)
    if not jid then return end

    -- (D) Aiming escape. Right-stick magnitude² > threshold → roll up every
    -- registered window of this player and release their focus. No lock state
    -- (the Y-hold lock is gone); it fires whenever active, outside the grace
    -- after a claim.
    local maxMagSq = _aimMagSq(pn, jid)
    local aimingActive = (maxMagSq > _aimingThresholdSq())
    local graceActive  = (getTimestampMs() < s.wsGrace)
    local canFire = aimingActive and s.win and (not s.wsLatched)
                    and (not graceActive)

    if canFire then
        s.wsLatched = true
        print("[ZeD.Input] Focus: aiming-escape magSq=" .. tostring(maxMagSq)
           .. " " .. _label(s.win) .. _who(pn))
        _hideAllWindows("aim-RS", pn)
        return
    end

    -- Edge latch bookkeeping: latch when aiming-active, unlatch when in deadzone.
    if aimingActive then
        s.wsLatched = true
    else
        s.wsLatched = false
    end

    -- (E) D-pad hold-to-repeat (only if still focused after aiming-escape path).
    if not s.win then
        if s.dDir then s.dDir = nil end
        return
    end

    local dir = _currentDpadDir(jd)
    if not dir then
        if s.dDir then s.dDir = nil end
        return
    end

    if dir ~= s.dDir then
        s.dDir   = dir
        s.dStart = getTimestampMs()
        s.dLast  = s.dStart
        return
    end

    local now = getTimestampMs()
    if (now - s.dStart) >= _holdInitialMs()
       and (now - s.dLast) >= _holdRepeatMs() then
        _handleSpatialNav(s.win, dir)
        s.dLast = now
    end
end

local MAX_PN = 3   -- the last local player's number (four players at most)

-- Whether player pn (1-3) is playing: their pad's slot is bound to them and
-- their character is alive. The game keeps the slot through the post-death
-- screen and binds it again before the new character exists (character
-- creation's accept), so the slot alone is not enough.
local function _playing(P, pn)
    local jd = P[pn + 1]
    if not (jd and jd.player == pn) then return false end
    local p = getSpecificPlayer and getSpecificPlayer(pn)
    return p ~= nil and not p:isDead()
end

local function _onTick()
    _tickPlayer(0, _st0)
    -- players 2-4, each on their own pad. Theirs run under pcall so one
    -- player's error never stops the others; player 1's errors surface as before.
    local P = JoypadState and JoypadState.players
    if not P then return end
    for pn = 1, MAX_PN do
        if _playing(P, pn) then
            local s = _S(pn)
            if s.away then _resume(s, pn) end
            local ok, err = pcall(_tickPlayer, pn, s)
            if not ok and not s.tickErr then
                s.tickErr = true
                print("[ZeD.Input] Focus: tick failed: " .. tostring(err) .. _who(pn))
            end
        else
            local s = _st[pn]
            if s then s.away = true end
        end
    end
end

-- ---------------------------------------------------------------------------
-- EVENT REGISTRATION
-- ---------------------------------------------------------------------------

if LuaEventManager and LuaEventManager.AddEvent then
    LuaEventManager.AddEvent("ZeD_FocusChanged")
    -- AddEvent is idempotent, so it's safe to materialize ZeD_InputModeChanged
    -- here too. Mirrors BumperChord's pattern — file-load order may put us
    -- before InputModeDetector, in which case Events.ZeD_InputModeChanged
    -- would not yet exist for our .Add call.
    LuaEventManager.AddEvent("ZeD_InputModeChanged")
end

Events.OnTick.Add(_onTick)
-- (a paused game has no ticks: the pad's taps, holds and D-pad repeats are worked on the drawn frames then, so the
-- Character and World windows answer the pad while paused; ZeD_PausedLook.lua holds their actions)
Focus.tick = _onTick
if Events.OnRenderTick then
    Events.OnRenderTick.Add(function()
        local ok, sp = pcall(getGameSpeed)
        if ok and sp == 0 then _onTick() end
    end)
end
if Events.OnRenderTick then Events.OnRenderTick.Add(_watchCueMouse) end

-- A player's number can come back with another pad and another character (a
-- respawn, or a new player in a dead player's number). Players 2-4 start over
-- (their painted run cleared, their next tick starting from the pad as it
-- is); player 1 keeps the window, the marks and QA's held buttons, and drops
-- only the holds. Nothing here touches the engine focus: the post-death
-- screen and character creation own it then.
local function _forget(pn)
    if type(pn) ~= "number" then return end
    if pn == 0 then
        _resume(_st0, 0)
        return
    end
    local old = _st[pn]
    if old and old.aWin then old.aWin._gpPaint = nil end
    _st[pn] = nil
    _S(pn)
end
if Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(pn) _forget(pn) end)
end
if Events.OnPlayerDeath then
    Events.OnPlayerDeath.Add(function(p)
        local ok, pn = pcall(function() return p:getPlayerNum() end)
        if ok and pn ~= 0 then _forget(pn) end
    end)
end

-- Window-pair invariant. On kbm→gamepad transition, ensure both windows
-- are open as a pair (gamepad-only invariant; mouse mode keeps asymmetric
-- open/closed state). Late-binds ZeD_CharacterWindow because that module
-- loads after this one (Input/* is a separate dir from the windows). The
-- mode is player 1's, and so are the marks it hides.
local function _onModeChanged(newMode, oldMode)
    -- the mouse or keyboard took over: the focus marks go (the focus itself stays)
    if newMode == "kbm" then _hideCues(_st0) end
    if newMode == "gamepad" and oldMode ~= "gamepad" then
        if ZeD_CharacterWindow and ZeD_CharacterWindow.ensureBothOpenForGamepad then
            pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, 0)
        end
    end
end
Events.ZeD_InputModeChanged.Add(_onModeChanged)

-- F9 toggles the D-pad debug overlay. Throwaway QA aid; the draw
-- function early-exits when overlay is OFF, so cost is one bool check per
-- focused-window render frame when disabled.
--
-- F9 chosen because it's unbound in vanilla PZ (Keyboard.KEY_F11 is the
-- engine binding for "Toggle Lua Debugger" — using it would pop the debugger
-- on every press; verified in shared/keyBinding.lua).
-- Debug builds only (-debug): players may bind F9 to something of their own.
Events.OnKeyPressed.Add(function(key)
    if key == Keyboard.KEY_F9 and isDebugEnabled() then
        Focus.toggleDebugOverlay()
    end
end)

-- The overlay paints inside the focused window's render cycle (guaranteed
-- valid draw context). Monkey-patch ZeD_Window:render at OnGameStart to call
-- _drawDebugOverlay AFTER the normal render. The hook fires every render but
-- short-circuits when (a) overlay is OFF, (b) self isn't the focused window,
-- or (c) self has no focused element. Wrapped in pcall — overlay bugs MUST
-- NEVER take down the game.
Events.OnGameStart.Add(function()
    if ZeD_Window and ZeD_Window.render then
        local _origRender = ZeD_Window.render
        function ZeD_Window:render()
            _origRender(self)
            if _debugOverlay and _st0.win == self then
                pcall(_drawDebugOverlay)
            end
        end
    end
    print("[ZeD.Input] FocusManager loaded - S113 FLAT FREE-NAV (LB=Char, RB=World, D-pad=flat cone-nav, Y=pair toggle, F9=debug overlay)")
end)
