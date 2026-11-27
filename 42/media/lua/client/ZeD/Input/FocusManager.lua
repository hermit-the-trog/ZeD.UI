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
-- focusable zone of the focused window. Bumpers don't cycle zones; LB steps
-- the Character window's tabs and RB the World window's, the pad going with them.
--
-- NAV MODEL:
--   LB tap                   — the Character window's next shown tab, on release (the last wraps to
--                              the first); from the World window the pad moves over and steps too
--   RB tap                   — the same for the World window's tabs (Radio and Vehicle only when shown)
--   LB / RB hold (>=350ms)   — one tab back, then one more every 400 ms while held
--                              (both bumpers down: no step)
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
--   Y tap                    — open both, or close both (KISS #25); rolled ones come down
--   Y hold (>=400ms)         — close every registered window (full lifecycle teardown)
--   L3 / R3                  — the focused list's next sort / list or grid view, nothing else
--   Right stick |v|² > 0.81  — roll up every registered window + release focus (aiming escape)
--
-- WINDOW-PAIR INVARIANT (gamepad mode):
--   On a pad, Character and World open and close as a pair. LB/RB rely
--   on this; Y maintains it. ZeD_CharacterWindow.ensureBothOpenForGamepad(pn)
--   runs on Y-tap and on LB / RB, as a safety net; the flip to a pad opens
--   nothing (KISS #14).
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
--   On claimFocus → Chord.setEnabled(false) so LB/RB step the windows' tabs
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

local STALL_MS, STALL_QUIET_MS = 120, 400   -- (punch list 191: a tick gap this long is a stall, not a hold)

--- The game's pause menu is up over a game in progress (Start): ZeD leaves the pad to it (punch list 188).
function Focus.pauseMenuUp()
    local m = MainScreen and MainScreen.instance
    if not m or not m.inGame then return false end
    local ok, vis = pcall(function() return m:isReallyVisible() end)
    return ok and vis == true
end

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
local function _aimingThresholdSq() return (ZeD.T and ZeD.T.gp and ZeD.T.gp.aimingThresholdSq) or 0.45 end   -- (Nov 14 2026, punch list 205: matches the token)

-- ---------------------------------------------------------------------------
-- FILE-LOCAL STATE
-- ---------------------------------------------------------------------------

local _windowRegistry = {}   -- every window the pads can reach, all players' (each knows its player: w.playerNum)

-- A-button and X-button hold thresholds. A press defers firing until release
-- (tap) or this long held (hold); see the A and X notes in the record below.
local A_HOLD_MS     = 350
local X_HOLD_MS     = 350
-- (Nov 14 2026, punch list 212: a bumper held this long steps its window's tabs back, then again every BUMP_REPEAT_MS)
local BUMP_HOLD_MS, BUMP_REPEAT_MS = 350, 400

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
--   bHeld, bStart, bLast, bCancel   a bumper down ("char" LB, "world" RB): a tap steps on release,
--                          a hold steps back (bLast: the last step, 0 none yet); bCancel: both
--                          bumpers went down, no step (punch list 212)
--   prevY                 Y's level last tick while no window is focused (the Y that opens the pair)
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
              bHeld = nil, bStart = 0, bLast = 0, bCancel = false,
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
    -- (Nov 15 2026, punch list 228k: every landing is noted, the one before it kept, so a knob can tell a landing
    -- announced again from a move back onto it)
    if fnName == "element.onFocus" and type(w) == "table" and type(arg) == "table" then
        w._landPrevId, w._landId = w._landId, arg.id
    end
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
    -- (Nov 14 2026, punch list 194: the first player too. The game hands the pad to its death screen before ZeD's
    -- death handler closes the windows, and handing focus on from here took it back, so the pad could not use it.)
    do
        local p = getSpecificPlayer and getSpecificPlayer(pn)
        if (pn ~= 0 and p == nil) or (p ~= nil and p:isDead()) then
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

-- whether ui is up on screen (a holder the game forgot to clear is not)
local function _shown(ui)
    if type(ui) ~= "table" or not ui.isReallyVisible then return false end
    local ok, vis = pcall(function() return ui:isReallyVisible() end)
    return ok and vis == true
end

--- What holds player pn's pad (pn missing: player 1's) that is not one of ZeD's registered windows nor a part of
--- one, while it is up: the keyboard, a ZeD menu (strip or list), the oven's pop-out, the reader, the seat chooser,
--- the car radio, the siren, the two-way's full view, Messages, chat, the controller map, the guide, the paper
--- map, the belt, a prompt, the game's own menus and dialogs. nil when the pad is a ZeD window's or the game's.
--- (Nov 14 2026, punch list 228a: the engine's joypad focus says who holds it; the registry says whose it is)
function Focus.foreignHolder(pn)
    if type(pn) ~= "number" then pn = 0 end
    if not getJoypadFocus then return nil end
    local ok, f = pcall(getJoypadFocus, pn)
    if not (ok and _shown(f)) then return nil end
    local o, n = f, 0
    while type(o) == "table" and n < 32 do
        if _indexOf(o) then return nil end
        o, n = o.parent, n + 1
    end
    return f
end

-- the join screen or a ZeD prompt holding a pad: nothing takes the pad from these, not even a window opening
-- (the old Focus.held, which claimFocus and the pair's opening still read)
function Focus.modalUp()
    local CM = ZeD.CommunityCards
    if CM ~= nil and CM.joinWin ~= nil then return true end
    local P = JoypadState and JoypadState.players
    if P then
        for i = 1, 4 do
            local f = P[i] and P[i].focus
            if f and f.Type == "ZeD_Prompt" and _shown(f) then return true end
        end
    end
    return false
end

--- A window that keeps the pad to itself is up (the join screen,
--- ZeD_CommunityCards.lua): nothing here opens a window or takes the pad under
--- it. It holds the pad itself (ZeD_JoinWindow:update) and hands it back when it closes.
--- (Nov 14 2026, punch list 228a: and anything else holding player pn's pad that is not a ZeD window, Focus.foreignHolder:
--- Y opened the pair over the keyboard, a menu, the oven's pop-out, the reader ... and left them up with no pad.
--- pn missing: any player's. claimFocus and ensureBothOpenForGamepad read Focus.modalUp instead, so a window a menu
--- option or a wheel opens still takes the pad as the menu lets it go.)
function Focus.held(pn)
    if type(pn) == "number" then
        if Focus.foreignHolder(pn) then return true end
    else
        for i = 0, 3 do if Focus.foreignHolder(i) then return true end end
    end
    local CM = ZeD.CommunityCards
    if CM ~= nil and CM.joinWin ~= nil then return true end
    -- (Nov 14 2026, punch list 196: a ZeD dialog (the Safe mode question and every other ZeD_Prompt) holding a pad
    -- keeps it until it is answered or closed with B: Y read from the pad here took the pad to the Character
    -- window and left the dialog up with nothing on it)
    local P = JoypadState and JoypadState.players
    if P then
        for i = 1, 4 do
            local f = P[i] and P[i].focus
            if f and f.Type == "ZeD_Prompt" then
                local ok, vis = pcall(function() return f:isReallyVisible() end)
                if ok and vis then return true end
            end
        end
    end
    return false
end

--- Give w the pad of its player (w.playerNum): it becomes that player's
--- focused window, lands on something lit (Focus.ensureEntry), takes the
--- engine's joypad focus on that player's slot, and their bumpers leave the
--- zoom chord for the window pair; ZeD_FocusChanged fires.
--- Does nothing while Focus.modalUp() (the join screen, a ZeD prompt).
function Focus.claimFocus(w)
    if not w then return end
    if Focus.pauseMenuUp() then return end   -- (punch list 188: never take the pad from the pause menu)
    local pn = _pnOf(w)
    local s = _S(pn)
    if s.win == w then return end
    if Focus.modalUp() then return end   -- (punch list 228a: Focus.held's wider test is for the pad's own Y)

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

    -- Bumpers step the windows' tabs while we hold focus (punch list 212). Disable the zoom chord.
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

    -- (Nov 14 2026, punch list 228b: the engine's focus clears only when it is not on something else that holds the
    -- pad, a prompt, the keyboard, the oven's pop-out: clearing it left them up with no pad)
    if not Focus.foreignHolder(pn) then _pushEngineFocus(nil, pn) end
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

--- A card opened in the other window by a press (the Admin tab's Open safehouse, a ticket's Player card, View
--- safehouse, the PvP marker): on a controller the pad goes with it to w, so the card's landing is where the pad is.
--- Only when another of the player's windows holds the pad (fromPad: the press was the pad's, whatever holds it).
--- Nothing on the mouse and keyboard.
function Focus.follow(w, fromPad)
    if not w then return end
    local pn = _pnOf(w)
    local s = _st[pn]
    if s and s.win == w then return end
    if not (fromPad or (s and s.win)) then return end
    if _modeOf(pn) ~= "gamepad" then return end
    Focus.claimFocus(w)
end

--- The window a pad press that reached w (one of its stubs) is for, or nil: w itself while it holds the pad.
--- (Nov 14 2026, punch list 212 playtest: the engine's joypad focus went back to the Character window while ZeD's
--- was on the World window, and every press after, the bumpers too, reached the Character window and was dropped.)
--- A press on another of the same player's windows while one of theirs holds the pad is the focused window's: the
--- engine's focus goes back on it, and the press is handed to it.
function Focus.padTarget(w, joypadData)
    local pn = joypadData and joypadData.player
    local fw = Focus.getFocusedWindow(pn)
    if fw == nil or fw == w then return fw end
    if _pnOf(w) ~= _pnOf(fw) or not fw:isVisible() or not _indexOf(w) then return nil end
    print("[ZeD.Input] Focus: pad resync: " .. _label(w) .. " -> " .. _label(fw) .. _who(_pnOf(fw)))
    _pushEngineFocus(fw, _pnOf(fw))
    return fw
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

-- ---------------------------------------------------------------------------
-- THE PAD'S REST: how long the controller has stayed on one stop
-- (Nov 14 2026, punch list 230, the director: a trait on the ID card, and "pretty much everything" that shows the
-- pointer a balloon, showed the pad nothing.) One rule for every surface: a stop whose surface shows the pointer a
-- balloon (or help words) shows the same one once the pad has rested on it PAD_TIP_MS, beside the stop. The wait is
-- read here, as the marks read the focus: a stop is "the same" while its zone and its id (its item or slot, else its
-- place) stay; a stop nobody asked about for REST_GAP_MS (the mouse took over, the window was hidden, the pad came back)
-- starts its wait again. ZeD.Atoms.drawPendingHover asks it each frame for the pad's balloons.
-- ---------------------------------------------------------------------------
Focus.PAD_TIP_MS = 400
local REST_GAP_MS = 250

--- How many ms player w.playerNum's pad has rested on w's focused stop, or nil when no focus mark shows in w
--- (w is not the focused window, or the mouse is in use).
function Focus.restedMs(w)
    local z = Focus.liveZone(w)
    if not z then return nil end
    local el = Focus.getFocusedElement(w)
    if not el then return nil end
    local s = (w == _st0.win) and _st0 or _st[w.playerNum or 0]
    if not s then return nil end
    -- (a stop list rebuilt as its tab scrolls makes new tables: the key is what names the stop, else where it is)
    local key = el.id
    if key == nil then key = el.item or el.slotType end
    if key == nil then key = tostring(el.x) .. ":" .. tostring(el.y) end
    local t = getTimestampMs() or 0
    if s.restWin ~= w or s.restZone ~= z.zone or s.restKey ~= key or t - (s.restSeen or -1e9) > REST_GAP_MS then
        s.restWin, s.restZone, s.restKey, s.restSince = w, z.zone, key, t
    end
    s.restSeen = t
    return t - (s.restSince or t)
end

--- True once the pad has rested on w's focused stop PAD_TIP_MS (with id: on the stop with that id).
function Focus.padRested(w, id)
    if id ~= nil and not Focus.isFocused(w, nil, id) then return false end
    local ms = Focus.restedMs(w)
    return ms ~= nil and ms >= Focus.PAD_TIP_MS
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
    -- (Nov 16 2026, QA's beta 17 run: the Journal's delete question opened on Delete.) A stop marked land = true
    -- (a question's Cancel) takes the focus when the stops are swapped and the focused one is gone, never a clamped
    -- index that may be the answer that acts.
    if not preserveIdx then
        local old = zone.elements and zone.elements[zone.focusedElementIdx or 1]
        local oldId = old and old.id
        local stays, landAt = false, nil
        for i, e in ipairs(elements) do
            if oldId ~= nil and e.id == oldId then stays = true end
            if e.land and not landAt then landAt = i end
        end
        if landAt and not stays then preserveIdx = landAt end
    end
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

--- A ZeD menu (ZeD_ContextMenu, the strip; ZeD_ContextList, the list) of player pn has closed: the pad goes back
--- where it came from, as the game's own menu does (ISContextMenu:closeAll): to the menu's origin (the game's menu
--- it stood in for carries it: the belt, the car radio's CD list, a radio face, a mod's panel) while that is still up,
--- else to the focused ZeD window. An option that handed the pad on (a prompt, the keyboard, another menu) keeps it.
--- (Nov 14 2026, punch list 228c: the menus let the pad go to nothing, or to the window, never to the belt; the
--- origin is used once: the game's menu is one per player and keeps the field from one opening to the next)
function Focus.menuClosed(menu, pn)
    if type(pn) ~= "number" then pn = 0 end
    local vm = menu and menu.vanillaMenu
    local origin = (menu and menu.origin) or (vm and vm.origin) or nil
    if menu then menu.origin = nil end
    if vm then vm.origin = nil end
    -- (no pad on this player: the mouse's menu, as before)
    if not (JoypadState and JoypadState.players and JoypadState.players[pn + 1]) then
        Focus.reclaimEngineFocus(pn)
        return
    end
    local holder = nil
    if getJoypadFocus then
        local ok, f = pcall(getJoypadFocus, pn)
        if ok then holder = f end
    end
    if holder ~= nil and holder ~= menu and holder ~= vm and _shown(holder) then return end
    if origin ~= nil and origin ~= menu and origin ~= vm and _shown(origin) then
        _pushEngineFocus(origin, pn)
        return
    end
    if holder == menu or holder == vm then _pushEngineFocus(nil, pn) end
    Focus.reclaimEngineFocus(pn)
end

-- ---------------------------------------------------------------------------
-- KNOBS (Nov 14 2026, punch list 228k / l, the design lead's "A grabs, D-pad turns")
-- A knob or a dial is a stop like any other: the D-pad moves onto it and off it, never turns it. A grabs it (its
-- holder's _knobGrab names it: the face draws it held), then Left / Down turn it down and Right / Up up, with the
-- D-pad's own hold-repeat; A or B lets go (B only lets go, it never leaves the card). Landing on it again starts
-- with it let go. A knob that also pushes (a radio's power on its volume knob) pushes on X. The mouse is untouched:
-- these are the controller's stops only.
-- ---------------------------------------------------------------------------
local _knobPrompts = nil
--- The prompts a grabbed knob adds to the help line: D-pad Turn, A / B Let go.
function Focus.knobPrompts()
    if not _knobPrompts then
        _knobPrompts = { { glyph = "D-PAD", label = ZeD.tr("UI_ZeD_Looks_PromptTurn") },
                         { glyph = "A B", label = ZeD.tr("UI_ZeD_Prompt_KnobLetGo") } }
    end
    return _knobPrompts
end

--- Make el (a stop) a knob. turn(w, e, delta) turns it one step (delta +1 up, -1 down). opts (all optional):
---   holder(w, e)   the table that keeps the grab (_knobGrab = the stop's id): w itself when missing
---   canTurn(w, e)  false: it lets go, and the D-pad moves on (a lock busy with its action)
---   press(w, e)    a knob that also pushes: X pushes it; pressWord its X prompt
--- The stop's own onFocus, onCancel and promptB still answer when it is not grabbed. Returns el.
function Focus.knobStop(el, turn, opts)
    if not el then return el end
    opts = opts or {}
    local holderOf = opts.holder or function(w) return w end
    local function grabbed(w, e)
        local h = holderOf(w, e)
        return h ~= nil and h._knobGrab ~= nil and h._knobGrab == e.id
    end
    local function letGo(w, e)
        local h = holderOf(w, e)
        if h then h._knobGrab = nil end
    end
    local prevFocus, prevCancel, prevB = el.onFocus, el.onCancel, el.promptB
    el.isKnob = true
    el.onFocus = function(w, e)
        -- (landing on it again: let go. Nov 15 2026, punch list 228k: but not when the landing is only announced again
        -- on the knob already held; the director's TV let go between A and the D-pad on a real pad.)
        local h = holderOf(w, e)
        if h and h._knobGrab ~= nil and not (h._knobGrab == e.id and w._landPrevId == e.id) then letGo(w, e) end
        if prevFocus then return prevFocus(w, e) end
    end
    el.onActivate = function(w, e)
        local h = holderOf(w, e)
        if not h then return end
        if h._knobGrab == e.id then h._knobGrab = nil else h._knobGrab = e.id end
        print("[ZeD.Input] Focus: knob " .. tostring(e.id) .. (h._knobGrab and " grabbed" or " let go"))
    end
    el.promptA = function(w, e)
        if grabbed(w, e) then return false end   -- (A / B Let go is one prompt, below)
        return ZeD.tr("UI_ZeD_Prompt_KnobGrab")
    end
    el.onCancel = function(w, e)
        if grabbed(w, e) then letGo(w, e); print("[ZeD.Input] Focus: knob " .. tostring(e.id) .. " let go (B)"); return true end
        if prevCancel then return prevCancel(w, e) end
        return false
    end
    el.promptB = function(w, e)
        if grabbed(w, e) or not prevCancel then return false end
        if type(prevB) == "function" then return prevB(w, e) end
        return prevB
    end
    el.onDpadDir = function(w, e, dir)
        if not grabbed(w, e) then
            local h = holderOf(w, e)
            if h then   -- (what the holder keeps, for the next playtest: nil, or a grab on another stop)
                print("[ZeD.Input] Focus: knob " .. tostring(e.id) .. " not held (held: " .. tostring(h._knobGrab) .. ", " .. tostring(h.Type or h) .. ")")
            end
            return false
        end
        if opts.canTurn and not opts.canTurn(w, e) then letGo(w, e); return false end
        turn(w, e, (dir == "up" or dir == "right") and 1 or -1)
        return true
    end
    el.extraPrompts = function(w, e)
        if grabbed(w, e) then return Focus.knobPrompts() end
        return nil
    end
    if opts.press then
        el.onContextMenu = opts.press
        el.promptX = opts.pressWord
    end
    return el
end

--- Whether the stop id is grabbed in holder (a face drawing its knob held).
function Focus.knobGrabbed(holder, id)
    return holder ~= nil and id ~= nil and holder._knobGrab == id
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
                    _fireCb("element.onFocus", e.onFocus, w, e)
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
        if el then _fireCb("element.onFocus", el.onFocus, w, el) end
        return
    end
    if live then return end   -- (the list has no rows yet: keep what is lit)
    for i, z in ipairs(w._focusRing) do
        if z.focusable and not (z.covered and z.covered(w)) and z.elements and #z.elements > 0 then
            w._focusIdx = i
            z.focusedElementIdx = _clampIdx(z.focusedElementIdx, z.elements)
            local e = z.elements[z.focusedElementIdx]
            if e then _fireCb("element.onFocus", e.onFocus, w, e) end
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

--- (Nov 14 2026, punch list 230) The focused stop's rectangle in w's own space, for the pad's balloon beside it:
--- el.tipRect (already window-local) when the stop names one, else its bounds moved by its zone's panel. Or nil.
local _elRect = {}
function Focus.elementRect(w, el)
    local z = Focus.getFocusedZone(w)
    el = el or Focus.getFocusedElement(w)
    if not (z and el) then return nil end
    local r = el.tipRect
    if type(r) == "function" then r = r(w, el) end
    if type(r) == "table" and type(r.x) == "number" then return r end
    if type(el.x) ~= "number" or type(el.y) ~= "number" then return nil end
    local ox, oy = _zoneOffset(w, z.zone)
    _elRect.x, _elRect.y, _elRect.w, _elRect.h = el.x + ox, el.y + oy, el.w or 1, el.h or 1
    return _elRect
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
    -- (KISS #18) a zone can name the element the D-pad lands on when it comes in from another zone (the container
    -- band: Loot all, never the button that happens to sit under the row it left)
    if oldZoneIdx ~= newZoneIdx and newZone.entryElementIdx and newZone.elements[newZone.entryElementIdx] then
        newZone.focusedElementIdx = newZone.entryElementIdx
    end
    w._focusIdx               = newZoneIdx
    w._focusPendingEntry      = nil   -- the player put focus somewhere: no entry seed after this

    local newEl = newZone.elements[newLoc.elementIdx]
    if newEl then   -- (every landing, a handler or not: the landing note, punch list 228k)
        _fireCb("element.onFocus", newEl.onFocus, w, newEl)
    end
    -- Audible focus tick (vanilla list-select sound) so D-pad moves are
    -- felt without looking for the cue. Mouse hover never routes here.
    pcall(function() ZeD.uiSound("UISelectListItem") end)

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

--- A move that crossed from window w into window other lands on other's nearest stop that way from src (one of
--- w's flat stops), then that stop's zone's own landing rule (zone.landOn), as a move inside a window does.
function Focus._landFrom(w, other, src, dir)
    -- (Nov 15 2026, the director: a window may name its own landing from the side, the World window its containers)
    if other._padLandFromSide then
        local okH, done = pcall(other._padLandFromSide, other, dir)
        if okH and done then return end
    end
    local els, loc = _collectFlat(other)
    if #els == 0 then return end
    local dx, dy = w:getX() - other:getX(), w:getY() - other:getY()
    local probe = { x = src.x + dx, y = src.y + dy, w = src.w, h = src.h, zi = -1 }
    els[#els + 1] = probe
    local pick = _pickBestWithFallback(els, #els, dir, false)
    els[#els] = nil
    if not pick or not loc[pick] then
        print("[ZeD.Input] Focus: landing found nothing that way in " .. _label(other) .. " (" .. #els .. " stops)")
        return
    end
    local zone = other._focusRing[loc[pick].zoneIdx]
    if zone and zone.landOn then
        local okL, ei = pcall(zone.landOn, other, zone, dir)
        if okL and type(ei) == "number" and zone.elements and zone.elements[ei] then
            for fi, l in ipairs(loc) do
                if l.zoneIdx == loc[pick].zoneIdx and l.elementIdx == ei then pick = fi; break end
            end
        end
    end
    _applyFlatLanding(other, loc, nil, pick)
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

-- Claim focus on a specific window of player pn ("char" = Character, "world" = World): LB / RB's
-- tab step (_stepTab below) and a bumper tapped on a D-pad wheel (Focus.openSide).
-- Absolute, not toggle — on that window already, a no-op
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

-- (Nov 14 2026, punch list 212, the director: LB cycles the Character window's tabs and RB the World window's,
-- replacing LB = go to Character, RB = go to World.) The pad goes to that window and its tab delta (1 next, -1
-- back) opens, wrapping at either end. Only the tabs on the strip count: the window's tab-bar stops are its shown
-- tabs (Radio and Vehicle only while there), and each stop's onActivate is A on that tab. The pad lands on the tab.
local TAB_ZONE = { char = "charTabBar", world = "worldTabBar" }
local function _stepTab(side, pn, delta)
    _focusWindow(side, pn)
    local M = (side == "char") and ZeD_CharacterWindow or ZeD_WorldWindow
    local w = M and M.getWindow and M.getWindow(pn)
    if not w then return end
    _fresh(w)
    local tabs = nil
    for _, z in ipairs(w._focusRing or {}) do
        if z.zone == TAB_ZONE[side] then tabs = z.elements; break end
    end
    local n = tabs and #tabs or 0
    if n == 0 then return end
    local at = 0
    for i = 1, n do
        if tabs[i].tabId == w._activeTab then at = i; break end
    end
    local pick
    if at == 0 then pick = (delta > 0) and 1 or n
    else pick = ((at - 1 + delta + n) % n) + 1 end   -- (never negative: Kahlua's % keeps the sign)
    local el = tabs[pick]
    if not el or pick == at then return end   -- (one tab shown: nothing to step to)
    pcall(function() ZeD.uiSound("UIActivateButton") end)
    _fireCb("tab.onActivate", el.onActivate, w, el)
    Focus.focusByIdSoon(w, TAB_ZONE[side], el.id)
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
    if el.onActivate then pcall(function() ZeD.uiSound("UIActivateButton") end) end
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
--- (Nov 14 2026, punch list 232, the director: "B at the top cancels") True when player pn is doing something the
--- game's B would cancel (its own test, as its button prompt reads it).
function Focus.actionToCancel(pn)
    local p = getSpecificPlayer and getSpecificPlayer(pn or 0)
    if not (p and isPlayerDoingActionThatCanBeCancelled) then return false end
    local ok, yes = pcall(isPlayerDoingActionThatCanBeCancelled, p)
    return ok and yes == true
end

-- B with nothing left to back out of: the running action stops, as the game's B with no panel open does
local function _cancelAction(pn)
    if not Focus.actionToCancel(pn) then return false end
    local p = getSpecificPlayer(pn or 0)
    local ok = pcall(stopDoingActionThatCanBeCancelled, p)
    if ok then pcall(function() ZeD.uiSound("UIToggleTickBox") end) end
    return ok
end

local function _handleBContextual(pn)
    local w = _S(pn).win
    if not w then return end
    local el = Focus.getFocusedElement(w)
    -- (QA TK3 hunt, Nov 26 2026: B on an object card's stop says where it landed; to come out once found)
    if el and type(el.id) == "string" and string.sub(el.id, 1, 3) == "oc:" then
        print("[ZeD] Focus: B with a card to come back to: stop " .. tostring(el and el.id) .. ", its own B "
            .. tostring(el and el.onCancel ~= nil) .. ", the way back " .. tostring(el and el._zedReturnB == true))
    end
    if not el or not el.onCancel then _cancelAction(pn); return end
    local took = _fireCbR("element.onCancel", el.onCancel, w, el)
    if took ~= false then pcall(function() ZeD.uiSound("UIToggleTickBox") end)
    else _cancelAction(pn) end
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
    if el then _fireCb("element.onFocus", el.onFocus, w, el) end
    pcall(function() ZeD.uiSound("UISelectListItem") end)
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
    -- (Nov 15 2026, add-on hooks: s.xDrag, only once the hold armed a drag; a hold that became the quick use, holdDragIf
    -- said no, leaves the D-pad to move the focus as before)
    if not (s and s.xHeld and s.xUsed and s.xDrag and s.xEl and s.xEl.onHoldContextDrag) then return false end
    local el = s.xEl
    _fireCb("element.onHoldContextDrag(dir)",
        function(ww, ee) el.onHoldContextDrag(ww, ee, dir) end,
        s.xWin or w, el)
    return true
end

-- ---------------------------------------------------------------------------
-- PAD SCROLL (Nov 16 2026, punch list 258): the shared rule for a scrolled view.
-- Scrolling used to follow the focus only, so words above a view's first stop or
-- below its last (a long item card, a letter, a part card's lines) never came
-- into view by pad. The rule, the one Messages, the Reader and the Prompt kept:
-- Up or Down from a stop inside a scrolled view with more of it that way moves
-- to the next stop when that stop shows or is one step away; else the view
-- scrolls one step and the focus stays. The move leaves the view only once its
-- end shows. A surface opts in by giving its stops a scrollView (a table, or a
-- function (w, el) that returns one), made by Focus.scrollView:
--   { key, y, h, off, span, set = function(newOff), step? }
-- key names the view (stops with the same key are in it); y / h are its shown
-- part in the same space as its stops' y; off the scroll now and span the most
-- it can scroll (px); set scrolls it. A stop that scrolls with the view and has
-- gone out of sight moves as if at the view's edge; one fixed outside the view
-- that reads it too (a card's back key, a band's verb) says scrollFixed = true.
-- The main menu's windows use the same rule through Focus.padScroll.
-- ---------------------------------------------------------------------------

--- A scrolled view for stops' scrollView (see PAD SCROLL above). Nil when it does not scroll.
function Focus.scrollView(key, y, h, off, span, set, step)
    if not (type(span) == "number" and span > 0.5 and type(set) == "function") then return nil end
    return { key = key, y = y or 0, h = h or 0, off = off or 0, span = span, set = set, step = step }
end

--- Give every stop in els that has no view of its own the view v (nil v: nothing). Returns els.
function Focus.tagScroll(els, v)
    if type(els) ~= "table" or type(v) ~= "table" then return els end
    for _, el in ipairs(els) do
        if type(el) == "table" and el.scrollView == nil then el.scrollView = v end
    end
    return els
end

-- the step of a view: its own, else 60 (scaled), never more than half the view
local function _scrollStep(v)
    if type(v.step) == "number" and v.step > 0 then return v.step end
    local s = (ZeD.T and ZeD.T.px) and ZeD.T.px(60) or 60
    local half = math.floor((v.h or 0) / 2)
    if half > 0 and s > half then s = half end
    return math.max(1, s)
end

--- The rule itself: v the view of the stop the move starts from, dir the D-pad's way, tv the view of the stop the
--- move would land on (nil: none, or outside any view), tr its rectangle ({ y, h }, in v's space; nil: none). Scrolls
--- v a step and returns true when the view keeps the press; false lets the move go on.
function Focus.padScroll(v, dir, tv, tr)
    if type(v) ~= "table" or type(v.set) ~= "function" or not (dir == "up" or dir == "down") then return false end
    local off, span = v.off or 0, v.span or 0
    if span <= 0.5 then return false end
    local more = (dir == "down" and off < span - 0.5) or (dir == "up" and off > 0.5)
    if not more then return false end
    local step = _scrollStep(v)
    if type(tv) == "table" and tv.key ~= nil and tv.key == v.key and type(tr) == "table"
       and type(tr.y) == "number" then
        -- the next stop in the same view, in sight or a step away: the move goes there (its follow brings it in)
        local th = tr.h or 0
        if dir == "down" and tr.y + th <= v.y + v.h + step then return false end
        if dir == "up" and tr.y >= v.y - step then return false end
    end
    local n = off + ((dir == "down") and step or -step)
    if n < 0 then n = 0 elseif n > span then n = span end
    local ok, err = pcall(v.set, n)
    if not ok then print("[ZeD.Input] Focus: padScroll set failed: " .. tostring(err)); return false end
    pcall(function() ZeD.uiSound("UISelectListItem") end)
    return true
end

-- a stop's scrollView, read (a function gives it fresh)
local function _viewOf(w, el)
    local v = el and el.scrollView
    if type(v) == "function" then
        local ok, r = pcall(v, w, el)
        v = ok and r or nil
    end
    if type(v) == "table" then return v end
    return nil
end

-- (Transfer in the footer, the director, Nov 22 2026: "Transfer buttons, always in the footer. Selection buttons,
-- always in the header.") Down past a list's last row lands on its footer's first move: a Loot column's own Take all
-- (its foot, InventoryRenderer.drawColumnFoot, a "lootall" stop in the column's zone, matched by the column's
-- container key), else the window's band entry, the World window's Take all or the Character window's Transfer all
-- ("take" / "xfer"), never To floor or Same type. fromFlat: the focused stop; toFlat: the spatial pick, nil when
-- there was none. Returns a flat index, or nil to keep the pick. A pick in the same zone is another row (or the
-- column's own foot): no wrap. Only from a row (an item's stop). (Kept on Focus, not a file local: this file is large.)
function Focus._lootAllWrap(w, locator, fromFlat, toFlat)
    local fl = fromFlat and locator[fromFlat]
    if not fl then return nil end
    local ring = w._focusRing
    local fz = ring[fl.zoneIdx]
    local fe = fz and fz.elements and fz.elements[fl.elementIdx]
    if not fe or fe.isViewToggle or not fe.item or Focus._BAND_ZONES[fz.zone] then return nil end
    -- a row of a Loot column (fe.colIdx): its own column's Take all, matched by the toggle's key
    local key
    local cnt = w._mainContent
    local cs = fe.colIdx and cnt and cnt._colStates and cnt._colStates[fe.colIdx]
    if cs and cs.inventory and ZeD.InventoryRenderer and ZeD.InventoryRenderer.containerKey then
        key = ZeD.InventoryRenderer.containerKey(cs.inventory, cnt._playerObj)
    end
    local tl = toFlat and locator[toFlat]
    if tl and tl.zoneIdx == fl.zoneIdx then
        -- (another row, or this column's own foot: kept; another column's Take all, never)
        local te = fz.elements[tl.elementIdx]
        if not (te and te.view == "lootall" and key and te.key ~= key) then return nil end
    end
    local first, band
    for fi = 1, #locator do
        local loc = locator[fi]
        local z = ring[loc.zoneIdx]
        local e = z and z.elements and z.elements[loc.elementIdx]
        if e and loc.zoneIdx == fl.zoneIdx and e.isViewToggle and e.view == "lootall" then
            if not key or e.key == key then return fi end
            first = first or fi
        elseif e and not band and Focus._BAND_ZONES[z.zone] and (e.ccKey == "take" or e.ccKey == "xfer") then
            band = fi
        end
    end
    return first or band
end

-- (Header order, the director, Nov 22 2026; Transfer in the footer, the same day) The loop round a list: Up with
-- nothing above it in the window (from the title bar, or a heading with no bar over it) wraps on round to the band's
-- first button, and Down from the band goes to the list's first row on show (no row: the heading's Pick all). The
-- loop both ways: rows, Down, the band's Take all / Transfer all, Down, rows; rows, Up, the heading's Pick all, Up,
-- title bar, Up, band. Only where the list has a heading with Pick all and a band, in both windows.
-- fromFlat: the focused stop; toFlat: the spatial pick (nil: none). Returns a flat index, or nil to keep the pick.
Focus._BAND_ZONES = { charCtl = true, worldCtl = true }   -- (on Focus, not a file local: this file is large)
function Focus._bandWrap(w, locator, fromFlat, toFlat, dir)
    local fl = fromFlat and locator[fromFlat]
    if not fl or (dir ~= "up" and dir ~= "down") then return nil end
    local ring = w._focusRing
    local fz = ring[fl.zoneIdx]
    local fromBand = fz and Focus._BAND_ZONES[fz.zone] or false
    -- the heading's Pick all (its zone is the list's) and the band's first button
    local lootFi, bandFi
    for fi = 1, #locator do
        local loc = locator[fi]
        local z = ring[loc.zoneIdx]
        local e = z and z.elements and z.elements[loc.elementIdx]
        if e then
            if not lootFi and e.isViewToggle and e.view == "all" then lootFi = fi end
            if Focus._BAND_ZONES[z.zone] and (not bandFi or loc.elementIdx < locator[bandFi].elementIdx) then bandFi = fi end
        end
    end
    if not (lootFi and bandFi) then return nil end
    local lz = locator[lootFi].zoneIdx
    -- the list's top (or, with last, bottom) row on show: an item's row
    local function edgeRow(last)
        local best, bestY
        for fi = 1, #locator do
            local loc = locator[fi]
            local e = loc.zoneIdx == lz and ring[lz].elements[loc.elementIdx]
            if e and e.item and not e.offscreen and type(e.y) == "number"
                and (not bestY or (last and e.y > bestY) or (not last and e.y < bestY)) then
                best, bestY = fi, e.y
            end
        end
        return best
    end
    if dir == "up" then
        if not fromBand then
            if toFlat then return nil end   -- (something above: kept)
            return bandFi
        end
        -- (QA PAD 3, Nov 22 2026) Up from the band: the list's last row on show, not the heading's Pick all the
        -- spatial pick may land on (the buttons at the right end line up); a pick that is already a row is kept
        local te = toFlat and locator[toFlat]
        local tz = te and ring[te.zoneIdx]
        local tel = tz and tz.elements and tz.elements[te.elementIdx]
        if tel and te.zoneIdx == lz and tel.item then return nil end
        return edgeRow(true) or lootFi
    end
    if not fromBand then return nil end
    -- Down from the band: the list's top row on show (an item's row), else its heading's Pick all
    return edgeRow(false) or lootFi
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

    -- PAD SCROLL (punch list 258, above): a stop in a scrolled view with more of it this way scrolls the view a
    -- step unless the move lands on a stop of the same view in sight or a step away. (The dry run below finds where
    -- the move would land; it sees _preview set, so it never comes back in here.)
    if not _preview and (dir == "up" or dir == "down") and focEl and focEl.scrollView then
        local v = _viewOf(w, focEl)
        if v then
            local r = Focus.previewMove(w, dir)
            local te = r and r.el
            local tv = te and _viewOf(w, te) or nil
            local tr = te and type(te.y) == "number" and { y = te.y, h = te.h or 0 } or nil
            if Focus.padScroll(v, dir, tv, tr) then
                print("[ZeD.Input] Focus: pad scroll " .. dir .. " (" .. tostring(v.key) .. ") [" .. _label(w) .. "]" .. _who(_pnOf(w)))
                return
            end
        end
    end

    -- Generic flat spatial nav. Collect every element from focusable zones,
    -- find the focused element's flat position, then run the two-tier picker
    -- (lined up, else off to the side) through the rules below.
    local elements, locator = _collectFlat(w)
    if #elements == 0 then return end

    local fromIdx = _findCurrentFlatIdx(w, locator) or 1

    -- (PAD SCROLL, punch list 258) A stop its view has scrolled out of sight (the pad scroll read on past it) moves
    -- as if it sat at the view's edge it went out by: Down at the end of a long card then reaches the foot under it,
    -- not the header the stop now lies above. Only the picker's copy moves. (A stop fixed outside the view that
    -- reads it too, a card's back key or a band's verb, says scrollFixed: it moves from where it is.)
    if focEl and focEl.scrollView and not focEl.scrollFixed and elements[fromIdx] and type(focEl.y) == "number" then
        local v = _viewOf(w, focEl)
        local fe = elements[fromIdx]
        if v and fe._origRef == focEl then
            local oy = fe.y - focEl.y
            local top, bot, fh = v.y + oy, v.y + v.h + oy, fe.h or 0
            if fe.y + fh <= top then fe.y = top
            elseif fe.y >= bot then fe.y = math.max(top, bot - fh) end
        end
    end

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
                    _preview.el = e
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
        -- (Nov 14 2026, punch list 202, the other way: with the list empty, Down from its header's buttons (Filter,
        -- the view button) found nothing lined up under them, so the controls at the window's foot (the oven's)
        -- could not be reached. Up / Down from a list header's button take the nearest stop that way at any angle.)
        if not newPickIdx and (dir == "up" or dir == "down") then
            local fe = elements[fromIdx]
            if fe and (fe.isViewToggle or (fe._origRef and fe._origRef.isViewToggle)) then   -- (the flat copy keeps only bounds and id: punch list 202, QA's stop dump)
                -- (not the side columns, the tab bar and the bag strip: lying lower beside the list, they are nearer
                -- than the foot's controls but are Left's or Right's)
                local subEls, subLoc, subFrom = { searchEls[fromIdx] }, { searchLoc[fromIdx] }, 1
                for i, loc in ipairs(searchLoc) do
                    local zn = w._focusRing[loc.zoneIdx] and w._focusRing[loc.zoneIdx].zone or ""
                    if i ~= fromIdx and zn:sub(-6) ~= "TabBar" and zn:sub(-14) ~= "ContainerStrip" and zn:sub(-9) ~= "TitlePins" then
                        subEls[#subEls + 1] = searchEls[i]
                        subLoc[#subLoc + 1] = loc
                    end
                end
                local pk, ps = _pickBestWithFallback(subEls, subFrom, dir, false)
                if pk then
                    local picked = subLoc[pk]
                    for i, loc in ipairs(searchLoc) do if loc == picked then newPickIdx, pass = i, ps; break end end
                end
            end
        end
    end
    -- (Nov 14 2026, punch list 186 again: once the window box became a stop (214), Right from the Character window's
    -- bag strip went up into the title bar, off to the side, instead of across to the World window's Ground. The
    -- title bar's stops are reached by Up or lined up only; off to the side, Left / Right go on past them.)
    if newPickIdx and pass == "half" and (dir == "left" or dir == "right") then
        local tl, fl = searchLoc[newPickIdx], locator[_findCurrentFlatIdx(w, locator) or 0]
        local tz = tl and w._focusRing[tl.zoneIdx] and w._focusRing[tl.zoneIdx].zone
        local fz = fl and w._focusRing[fl.zoneIdx] and w._focusRing[fl.zoneIdx].zone
        if type(tz) == "string" and tz:sub(-9) == "TitlePins" and tz ~= fz then newPickIdx = nil end
    end
    -- (Transfer in the footer, Nov 22 2026) Down from a list's last row with nothing under it: the footer's Take all
    if not newPickIdx and dir == "down" then
        local wrap = Focus._lootAllWrap(w, locator, _findCurrentFlatIdx(w, locator), nil)
        if wrap then searchEls, searchLoc, newPickIdx, pass = elements, locator, wrap, "wrap" end
    end
    -- (Header order, Nov 22 2026) Up with nothing above: on round to the footer band; Down from the band with
    -- nothing under it: the list's first row (Focus._bandWrap)
    if not newPickIdx and (dir == "up" or dir == "down") then
        local wrap = Focus._bandWrap(w, locator, _findCurrentFlatIdx(w, locator), nil, dir)
        if wrap then searchEls, searchLoc, newPickIdx, pass = elements, locator, wrap, "wrap" end
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
                -- (Nov 14 2026, punch list 186: land by position, the nearest stop that way from where the move
                -- started, then that zone's own landing rule; the window's last focus could be Take all when its
                -- list had emptied under it. Where the move started, in the other window's frame:)
                local src = elements[_findCurrentFlatIdx(w, locator) or 0]
                Focus.claimFocus(other)
                -- (punch list 210: a landing plays its own click (_applyFlatLanding); a second one here made two at once)
                local landed = false
                if src and Focus.getFocusedWindow(_pnOf(other)) == other then
                    local okL, errL = pcall(Focus._landFrom, w, other, src, dir)
                    landed = okL
                    if not okL then print("[ZeD.Input] Focus: landing failed: " .. tostring(errL)) end
                end
                if not landed then pcall(function() ZeD.uiSound("UISelectListItem") end) end
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

    -- (KISS #18; Selection in the header, the director, Nov 22 2026) Up from a list row onto the list's heading lands
    -- on its first button, Pick all, whatever heading button sits nearest the row (the heading's Take all went to
    -- the footer: Up never lands on a move)
    if dir == "up" and locator[logFromIdx] then
        local fz = w._focusRing[locator[logFromIdx].zoneIdx]
        local fe = fz and fz.elements and fz.elements[locator[logFromIdx].elementIdx]
        local tzi = locator[newFlatIdx].zoneIdx
        local tz = w._focusRing[tzi]
        local te = tz and tz.elements and tz.elements[locator[newFlatIdx].elementIdx]
        if fe and not fe.isViewToggle and te and te.isViewToggle and te.view ~= "all" and te.view ~= "lootall" then
            for fi = 1, #locator do
                local loc = locator[fi]
                local e = loc.zoneIdx == tzi and tz.elements[loc.elementIdx]
                if e and e.view == "all" and e.key == te.key then newFlatIdx = fi; break end
            end
        end
    end
    -- (Transfer in the footer, Nov 22 2026) Down from a list's last row onto anything outside the list (the drawer's
    -- foot, a band button that is not its first move): the footer's Take all or Transfer all instead
    if dir == "down" and newFlatIdx ~= logFromIdx then
        local wrap = Focus._lootAllWrap(w, locator, logFromIdx, newFlatIdx)
        if wrap then newFlatIdx, pass = wrap, "wrap" end
    end
    -- (Header order, Nov 22 2026) Down from the footer band onto anything (the drawer's foot beside it): the list's
    -- first row on show instead
    if (dir == "down" or dir == "up") and newFlatIdx ~= logFromIdx then   -- (up: QA PAD 3, the band's Up)
        local wrap = Focus._bandWrap(w, locator, logFromIdx, newFlatIdx, dir)
        if wrap then newFlatIdx, pass = wrap, "wrap" end
    end
    if _preview then
        local z = w._focusRing[locator[newFlatIdx].zoneIdx]
        local e = z and z.elements and z.elements[locator[newFlatIdx].elementIdx]
        _preview.zone, _preview.id, _preview.pass = z and z.zone, e and e.id, pass
        _preview.el = e   -- (the stop itself: the pad scroll's dry run reads its view and place)
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

-- (Nov 15 2026, punch list 237, the director: every window hides when the player aims, the Messages window too, not
-- only while a ZeD window holds the pad.) What aiming hides for player pn: true when something was up to hide.
local function _aimHide(pn, held, note)
    -- the windows to roll up: player pn's registered ones, and the pair by name (QA, Nov 15 2026: with no window
    -- holding the pad the pair may be up and not counted, and the roll-up below it returned at once)
    local list, seen = {}, {}
    for _, w in ipairs(_windowRegistry) do
        if _pnOf(w) == pn and not seen[w] then seen[w] = true; list[#list + 1] = w end
    end
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getInstance and ZeD_CharacterWindow.getInstance(pn)
    local ww = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(pn)
    if cw and not seen[cw] then seen[cw] = true; list[#list + 1] = cw end
    if ww and not seen[ww] then seen[ww] = true; list[#list + 1] = ww end
    local hid = held == true   -- (a ZeD window holding the pad: as before, it always rolls up)
    for _, w in ipairs(list) do
        local up = _shown(w) or (w.isVisible ~= nil and w:isVisible() == true)
        if up and not w.windowShaded then hid = true end
    end
    local MW = ZeD.MessagesWindow
    local mw = MW and MW.get and MW.get(pn)
    local msg = mw ~= nil and _shown(mw) and not mw.guestJoy
    if (hid or msg) and note then print(note) end
    if hid then
        _hideAllWindows("aim-RS", pn)
        for _, w in ipairs(list) do   -- (any the registry did not hold)
            if _indexOf(w) == nil then
                if w._halves and ZeD.Halves then ZeD.Halves.aim(w)
                elseif w.setWindowShaded and not w.windowShaded then w:setWindowShaded(true) end
            end
        end
    end
    if msg then pcall(mw.close, mw) end
    return hid or msg
end

--- Player pn has a game cursor up that is not the Furniture tab's (Place item, a build, paint): the cursor, or nil.
function Focus.gameCursor(pn)
    local cell = getCell and getCell()
    local d = cell and cell:getDrag(pn or 0)
    -- (Nov 14 2026, punch list 228o: the Furniture tab drives player 1's furniture cursor only (it opens itself for
    -- one a menu's Pick up / Place / Rotate / Scrap starts, FurnitureTab.lua's watch); another player's is the game's)
    if d and (d.Type ~= "ISMoveableCursor" or (pn or 0) ~= 0) then return d end
    return nil
end

--- (punch list 184) A pad press reached a ZeD window while a game cursor is up: roll the windows up, let the pad go,
--- and hand this same press to the game as a press with no focus, which gives it to the cursor (A places).
function Focus.passToCursor(pn, button, joypadData)
    if not Focus.gameCursor(pn) then return false end
    _hideAllWindows("cursor", pn)
    local s = _S(pn)
    s.dragSeen = Focus.gameCursor(pn)
    local c = joypadData and joypadData.controller
    if c and c.onPressButtonNoFocus then c:onPressButtonNoFocus(button) end
    return true
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

-- (KISS #8) Where a Y lands: near a container the World window's Loot, on that container's first row, and after a Y
-- that hid the pair the row it left (ZeD_WorldWindow.padYLand); else the Character window, as before. A field on
-- Focus, not a local (this file is near Kahlua's local limit).
function Focus.yLand(pn, charWin, back)
    local WW = ZeD_WorldWindow
    local ok, took = false, false
    if WW and WW.padYLand then ok, took = pcall(WW.padYLand, pn, back) end
    if not (ok and took) and charWin then Focus.claimFocus(charWin) end
end

-- Y tap: player pn's paired visibility toggle.
--   both closed   → open both (Character focus)
--   both visible  → close both, release focus (KISS #25)
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
        Focus.yLand(pn, charWin, true)   -- (KISS #8: a Y that closed the pair kept its row; KISS #25)
        print("[ZeD.Input] Focus: Y tap - opened pair, Character focus" .. _who(pn))
        return
    end

    -- Mixed (one open, one closed): enforce invariant.
    if charOpen ~= worldOpen then
        if CW.ensureBothOpenForGamepad then CW.ensureBothOpenForGamepad(pn) end
        local charWin = CW.getWindow and CW.getWindow(pn)
        if charWin then Focus.showWin(charWin) end
        Focus.showWin(WW.getWindow and WW.getWindow(pn))
        Focus.yLand(pn, charWin, true)   -- (KISS #8; after both show, so the World window can take it)
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
        local t0 = getTimestampMs()   -- (217: the hide's timing, Focus.lagClose)
        -- (the row the pad is on, for the next Y to return to: KISS #8)
        if WW.padYRemember then pcall(WW.padYRemember, pn) end
        -- A tap of Y closes both, as the game's Y puts its inventory away; they used to roll to two bars that only a
        -- hold cleared. (KISS #25)
        if WW.close then pcall(WW.close, pn) end
        if CW.isOpen and CW.isOpen(pn) and CW.toggle then pcall(CW.toggle, pn) end
        Focus.releaseFocus(pn)
        print("[ZeD.Input] Focus: Y tap - close pair" .. _who(pn))
        Focus.lagClose(t0)
        return
    end

    if bothShaded then
        Focus.showWin(charWin)
        Focus.showWin(worldWin)
        Focus.yLand(pn, charWin, true)   -- (KISS #8)
        print("[ZeD.Input] Focus: Y tap - unhide pair, Character focus" .. _who(pn))
        return
    end

    -- One shaded one not: normalize to both-visible.
    if charShaded  then Focus.showWin(charWin)  end
    if worldShaded then Focus.showWin(worldWin) end
    Focus.yLand(pn, charWin, true)   -- (KISS #8)
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

-- (KISS #34) In a window, a bumper held with A, B, X, Y, L3 or R3 runs that quick action (ZeD_QuickChords), as it
-- does in the world, and never turns a tab: the bumper's step is called off, and any step back its hold already made
-- is undone. The face button does nothing else. True when the press was a chord. A field, not a local (this file is
-- near Kahlua's local limit).
function Focus.padChord(pn, s, button)
    -- (one bumper down: both down are the zoom's, and the second bumper called the step off without a chord)
    if not s.bHeld or (s.bCancel and not s.bChord) then return false end
    local face = nil
    for k, f in pairs({ AButton = "A", BButton = "B", XButton = "X", YButton = "Y", LStickButton = "L3", RStickButton = "R3" }) do
        if Joypad[k] ~= nil and Joypad[k] == button then face = f end
    end
    if not face then return false end
    s.bCancel, s.bChord = true, true
    local steps = s.bSteps or 0
    s.bSteps = 0
    for _ = 1, steps do _stepTab(s.bHeld, pn, 1) end
    local Q = ZeD.QuickChords
    local p = getSpecificPlayer(pn)
    -- (as in the world: not paused, not dead, not in safe mode)
    if Q and Q.run and p and not p:isDead() and getGameSpeed() > 0 and not (ZeD.Safe and ZeD.Safe.on()) then
        local chord = ((s.bHeld == "char") and "LB" or "RB") .. "+" .. face
        local ok, err = pcall(Q.run, p, chord)
        if not ok then print("[ZeD.Input] Focus: chord " .. chord .. ": " .. tostring(err)) end
        Q.lastChord = chord
    end
    return true
end

--- A pad button went down while w holds the pad (w's onJoypadDown stub calls
--- this). Shows the focus marks, names the button through ActionMap and
--- routes it: A, X and Y arm their tap-vs-hold timers (settled on the tick),
--- LB / RB arm their tab steps (settled on the tick), B cancels, L3 / R3 change the list's view.
--- The press is worked on the record of w's player; a press from another
--- player's pad (its slot's engine focus left on w) is dropped.
function Focus.dispatchJoypadDown(w, button, joypadData)
    if not w then return end
    local pn = _pressPn(w, joypadData)
    if pn == nil then return end
    local s = _S(pn)
    _fresh(w)
    _showCues(s)
    -- (Nov 15 2026, add-on hooks: while X holds a thing in place mode, GridLayout.lua, A turns it and B cancels;
    -- nothing else sees those presses. Nothing without an add-on's grid layout)
    if ZeD.GridLayout and ZeD.GridLayout.padButton(pn, button) then return end
    -- B also hides the balloon that is up until the focus moves on (B still does its own job)
    if button == Joypad.BButton and ZeD.Balloon and ZeD.Balloon.dismiss then ZeD.Balloon.dismiss() end
    if Focus.padChord(pn, s, button) then return end   -- (a bumper held: the quick action, KISS #34)
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
        elseif aid == "window_prev" or aid == "window_next" then
            -- LB (window_prev) the Character window's tabs, RB the World window's: tap-vs-hold, settled
            -- on the tick (C4). The other bumper going down as well cancels the step (punch list 212).
            local side = (aid == "window_prev") and "char" or "world"
            if s.bHeld then
                if s.bHeld ~= side then s.bCancel = true end
            else
                s.bHeld, s.bStart, s.bLast, s.bCancel, s.bChord, s.bSteps = side, getTimestampMs(), 0, false, nil, 0
            end
            return
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
    if not (w and D and D.getMode and D.getMode(_pnOf(w)) == "kbm") then return false end
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
    elseif s.dStall and getTimestampMs() - s.dStall < STALL_QUIET_MS then
        -- (punch list 191: the engine's own repeat of a press held through a slow frame is not a second move)
        return
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
--   (C4) LB / RB tab step: tap forward, hold back and repeat
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
    -- (Nov 15 2026, add-on hooks: a place mode cut short places nothing, GridLayout.lua)
    if s.xDrag     then s.xDrag = nil; if ZeD.GridLayout then ZeD.GridLayout.padCancel(s.pn) end end
    if s.bHeld     then s.bHeld = nil; s.bLast = 0; s.bCancel = false end
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
    -- (Nov 14 2026, punch list 184, the director's playtest: with a game cursor up, Y is the cursor's (Place item's
    -- fine aim), never ZeD's windows; a tap hid the pair and a hold closed it while the game took the same press)
    if Focus.held(pn) or (not s.win and Focus.gameCursor(pn)) then
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
                -- (Nov 15 2026, add-on hooks: an element may say at the hold whether it drags, holdDragIf(w, el): an
                -- item cell with an add-on's grid layout places, GridLayout.padCan; where it says no the hold falls
                -- to onHoldContext, the quick use. Elements without holdDragIf drag as before)
                if el and el.onHoldContextDrag and (not el.holdDragIf or el.holdDragIf(s.xWin or s.win, el)) then
                    _fireCb("element.onHoldContextDrag(arm)",
                        function(w, e) el.onHoldContextDrag(w, e, nil) end,
                        s.xWin or s.win, el)
                    s.xUsed = true
                    s.xDrag = true
                elseif el and el.onHoldContext then
                    -- a one-shot hold with no drag (hold X on a row is the quick use); paused, only where it is a
                    -- move into his inventory (ZeD_PausedLook.blocksUse, KISS #41)
                    local PL = ZeD.PausedLook
                    if not (PL and PL.blocksUse and PL.blocksUse(s.xWin or s.win, el)) then
                        _fireCb("element.onHoldContext", el.onHoldContext, s.xWin or s.win, el)
                    end
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
            s.xDrag  = nil
            s.xWin   = nil
            s.xEl    = nil
        end
    end

    -- (C4) LB / RB tap-vs-hold (Nov 14 2026, punch list 212). Tap: the bumper's window, its next tab, on release.
    -- Hold past BUMP_HOLD_MS: a tab back, then another every BUMP_REPEAT_MS while held. Both bumpers down: no step.
    -- Only while a window still has this player's pad: windows hidden or closed mid-press stay that way.
    if s.bHeld then
        local side = s.bHeld
        if _btnDown((side == "char") and "RightBump" or "LeftBump", jid, s) then s.bCancel = true end
        if _btnDown((side == "char") and "LeftBump" or "RightBump", jid, s) then
            local t = getTimestampMs()
            if s.win and not s.bCancel and t - s.bStart >= BUMP_HOLD_MS
               and (s.bLast == 0 or t - s.bLast >= BUMP_REPEAT_MS) then
                s.bLast = t
                _stepTab(side, pn, -1)
                s.bSteps = (s.bSteps or 0) + 1   -- (a chord after it undoes it: Focus.padChord, KISS #34)
            end
        else
            if s.win and not s.bCancel and s.bLast == 0 then
                -- (loot KISS call 2, the director, Nov 24 2026) RB tapped on the World window's rows goes to the next
                -- container, as the game's RB does; anywhere else it turns the tabs
                local WW = ZeD_WorldWindow
                local took = side == "world" and WW and WW.padNextContainer and WW.padNextContainer(pn)
                if not took then _stepTab(side, pn, 1) end
            end
            s.bHeld, s.bStart, s.bLast, s.bCancel, s.bChord, s.bSteps = nil, 0, 0, false, nil, 0
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
    -- (Nov 14 2026, punch list 188: the pause menu is the game's. Y read straight from the pad here unrolled the
    -- windows and took the pad from the menu; a Y still down when the menu closes is not a new press)
    if Focus.pauseMenuUp() then
        _dropHolds(s)
        s.prevY = true
        return
    end
    -- (Nov 14 2026, punch list 184: a game cursor started (Place item, a build, paint) while a ZeD window held the
    -- pad, so A went to the window and ended in the world's interact (a chair, a window) instead of placing. The
    -- game lets go of the pad only for its own inventory; ZeD rolls its windows up and lets go too, once per
    -- cursor, as the right stick's aim does. The Furniture tab's cursor is driven from the open window: not that one.)
    do
        local d = Focus.gameCursor(pn)
        if d then
            -- (Nov 14 2026, punch list 228b, then QA's regression on it: the roll-up always runs once a cursor is up,
            -- as before. Waiting for no other holder kept the pad on the Character window after Place item from a menu
            -- (184 again): the menu that started the cursor still counted as one. What 228b needed is releaseFocus's:
            -- something else that holds the pad, a prompt or the keyboard, keeps it while the windows roll up.)
            if s.win and s.dragSeen ~= d then
                s.dragSeen = d
                _hideAllWindows("cursor", pn)
                return
            end
        else
            s.dragSeen = nil
        end
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
    -- (punch list 237: the game's own aiming too, the trigger held, as well as the right stick)
    local aimP = getSpecificPlayer and getSpecificPlayer(pn)
    local aimingActive = (maxMagSq > _aimingThresholdSq()) or (aimP ~= nil and aimP.isAiming ~= nil and aimP:isAiming() == true)
    local graceActive  = (getTimestampMs() < s.wsGrace)
    -- (Nov 14 2026, punch list 228b: only while a ZeD window holds the pad, not the keyboard, a prompt or a pop-out
    -- over it, which the escape left up with no pad)
    -- (punch list 237: with or without the pad on a window; the Messages window holding it counts as no holder, it hides)
    local holder = Focus.foreignHolder(pn)
    if holder and ZeD.MessagesWindow and ZeD.MessagesWindow.get and holder == ZeD.MessagesWindow.get(pn) then holder = nil end
    local canFire = aimingActive and (not s.wsLatched)
                    and (not graceActive) and not holder

    if canFire then
        s.wsLatched = true
        if _aimHide(pn, s.win ~= nil, "[ZeD.Input] Focus: aiming-escape magSq=" .. tostring(maxMagSq)
               .. " " .. _label(s.win) .. _who(pn)) then
            return
        end
    end

    -- Edge latch bookkeeping: latch when aiming-active, unlatch when in deadzone.
    -- (Nov 14 2026, punch list 205: latch only outside the grace, so a stick held through
    -- the grace after a claim still fires once when the grace ends)
    if aimingActive then
        if not graceActive then s.wsLatched = true end
    else
        s.wsLatched = false
    end

    -- (E) D-pad hold-to-repeat (only if still focused after aiming-escape path).
    -- (Nov 14 2026, punch list 209: nor when something else holds the pad, the oven's controls pop-out: a held
    -- Right on its dial walked the World window behind it and then took the pad to the Character window)
    if not s.win or (getJoypadFocus and getJoypadFocus(pn) ~= s.win) then
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
        s.dTick  = s.dStart
        return
    end

    local now = getTimestampMs()
    -- (Nov 14 2026, punch list 191: a slow frame (a Journal page building on its first show) let a tap still be
    -- down past the hold's start, and the repeat walked on past the wanted tab into the inventory. A gap between
    -- ticks is not holding: the hold starts again from now.)
    local gap = now - (s.dTick or now)
    s.dTick = now
    if gap > STALL_MS then
        s.dStart, s.dLast, s.dStall = now, now, now
        return
    end
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

-- (Nov 15 2026, punch list 240, the director: "can the cursor hide?") The mouse pointer hides while player 1 plays
-- with the controller: from the moment the input turns to the pad or a pad press reaches a ZeD window, until the mouse
-- moves or clicks. Shown, it is the game's own setting (Display cursor). Player 1's only: the others have no mouse.
local PTR = { hidden = false, mode = nil, x = nil, y = nil, since = 0 }
local function _watchPointer()
    if not (Mouse and Mouse.setCursorVisible and getMouseX) then return end
    local D = ZeD.Input.Detector
    local mode = D and D.getMode and D.getMode(0) or "kbm"
    local mx, my = getMouseX(), getMouseY()
    local hide = PTR.hidden
    if mode == "gamepad" and (PTR.mode ~= "gamepad" or (_st0.cues and (_st0.cueSince or 0) > PTR.since)) then
        hide = true
        PTR.since = _st0.cueSince or 0
    end
    if mode ~= "gamepad" then hide = false end
    if hide and PTR.x ~= nil then
        local T = ZeD.T
        local th = (T and T.px) and T.px(CUE_MOUSE_U) or CUE_MOUSE_U
        if math.abs(mx - PTR.x) > th or math.abs(my - PTR.y) > th then hide = false end
        if D and D.msSinceMouseClick and D.msSinceMouseClick() < 250 then hide = false end
    end
    PTR.mode = mode
    if hide ~= PTR.hidden or not hide then PTR.x, PTR.y = mx, my end
    if hide == PTR.hidden then return end
    PTR.hidden = hide
    local show = true
    pcall(function() show = getCore():isDisplayCursor() end)
    pcall(Mouse.setCursorVisible, (not hide) and show)
end
if Events.OnRenderTick then Events.OnRenderTick.Add(_watchPointer) end

-- ---------------------------------------------------------------------------
-- THE Y TAP'S HIDE, TIMED (punch list 217 (beta 19, Nov 16 2026): timing only, no fix yet). The director saw one large
-- hitch as the windows close. Each hide prints one line: what the hide itself cost (rolling both windows up and
-- letting go of the pad) and the gaps to the next few frames, so QA sees whether the hitch is in the hide or after it.
-- grep "[ZeD.LagClose]". Not behind a flag: ZeD has no debug switch of its own, and it is one line a hide, as the
-- Y tap's own "[ZeD.Input]" lines are. (Fields on Focus, not locals: this file is near Kahlua's local limit.)
-- ---------------------------------------------------------------------------
Focus.LAG_FRAMES = 5
Focus._lag = nil
--- The hide began at t0 (getTimestampMs) and has just ended: time the frames after it.
function Focus.lagClose(t0)
    local now = getTimestampMs()
    Focus._lag = { t0 = t0, cost = now - t0, last = now, gaps = {} }
end
--- Each frame (OnRenderTick): the gap since the last; the line once LAG_FRAMES are in.
function Focus.lagCloseTick()
    local L = Focus._lag
    if not L then return end
    local now = getTimestampMs()
    L.gaps[#L.gaps + 1] = tostring(now - L.last)
    L.last = now
    if #L.gaps < Focus.LAG_FRAMES then return end
    Focus._lag = nil
    print("[ZeD.LagClose] hide " .. tostring(L.cost) .. " ms | next frames " .. table.concat(L.gaps, " ")
        .. " ms | hide to last frame " .. tostring(now - L.t0) .. " ms")
end
if Events.OnRenderTick then Events.OnRenderTick.Add(function() Focus.lagCloseTick() end) end

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

-- The input switching. The mode is player 1's, and so are the marks it hides. The switch to a pad opens nothing:
-- a touch of the screen or a key and then the stick used to pop both windows open over the game mid-walk; Y opens
-- them when he wants them (and LB / RB, the wheels, still open the pair as before). (KISS #14)
local function _onModeChanged(newMode, oldMode)
    -- the mouse or keyboard took over: the focus marks go (the focus itself stays)
    if newMode == "kbm" then _hideCues(_st0) end
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
    print("[ZeD.Input] FocusManager loaded - S113 FLAT FREE-NAV (LB=Char tabs, RB=World tabs, D-pad=flat cone-nav, Y=pair toggle, F9=debug overlay)")
end)
