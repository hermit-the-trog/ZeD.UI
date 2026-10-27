-- ZeD-UI/42/media/lua/client/ZeD/Input/FocusManager.lua
-- ============================================================================
-- LAYER 3 — FocusManager (S113 — FLAT FREE-NAV model)
--
-- Replaces the S97 RING model. Per-window zones still exist as a STORAGE
-- abstraction (per-tab builders still call setRingZoneElements / setZoneFocusable
-- — no churn) but D-pad nav is now FLAT across every focusable zone of the
-- focused window. Bumpers no longer cycle zones; they swap between the two
-- always-paired Character/World windows.
--
-- NAV MODEL (design director ruling, locked S113b brainstorm):
--   LB                       — swap focus to other window (Char ↔ World)
--   RB                       — swap focus to other window (Char ↔ World)
--   D-pad up/down/left/right — cone-nav across ALL focusable zones in the focused window
--   A tap                    — fire focused element's onActivate (= LMB)
--   A hold (>=350ms)         — fire onHoldActivate if defined (= double-LMB)
--   X                        — fire focused element's onContextMenu (= RMB);
--                              else onReset if defined (3-option dialogs only)
--   B                        — fire focused element's onCancel if defined; else NO-OP
--                              (no shade-all fallback; pure contextual cancel)
--   Y tap                    — toggle paired visibility (open both/hide both/unhide both)
--   Y hold (>=400ms)         — close BOTH windows (full lifecycle teardown)
--   Right stick |v|² > 0.81  — instant hide both + focus release (aiming escape)
--
-- WINDOW-PAIR INVARIANT (gamepad mode):
--   Both Character and World are always open as a pair on gamepad. LB/RB rely
--   on this; Y maintains it. ZeD_CharacterWindow.ensureBothOpenForGamepad(0)
--   is called by InputModeDetector mode-flip and by Y-tap as a safety net.
--
-- PSEUDO-FOCUSABLE D-PAD INTERCEPT (unified contract):
--   Any element may declare onDpadDir(w, el, dir) — a callback that fires
--   BEFORE generic cone-nav when D-pad is pressed while that element is
--   focused. Used by: maps canvas cursor (move cursor in panel pixels),
--   animals zone-draw cursor (move cursor by tile), gridScroll surfaces
--   (scroll the visible region). Returning false from the callback signals
--   "not handled, fall through to cone-nav" — matches the Q107 onCancel
--   pass-through contract.
--
-- WINDOW CONTRACT:
--   Each window populates w._focusRing (array of zones) and w._focusIdx (1-based
--   current zone index) on open. Zone shape unchanged from S97:
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
--   Optional renderFn(w, zone) on each zone (per-zone bumper-land hook;
--   harmless under flat nav since bumpers no longer cycle zones, but kept
--   so old code doesn't have to be cleaned up).
--   Optional w:onFocusZoneChanged({new, old}) — fired when cone-nav crosses
--   a zone boundary, so chrome can refresh.
--
-- BUMPERCHORD INTEGRATION (unchanged from S97):
--   On claimFocus → Chord.setEnabled(false) so LB/RB route to window swap
--   On releaseFocus → Chord.setEnabled(true) so LB/RB route to zoom chord
--
-- Public interface:
--   ZeD.Input.Focus.registerWindow(w)
--   ZeD.Input.Focus.unregisterWindow(w)
--   ZeD.Input.Focus.claimFocus(w)
--   ZeD.Input.Focus.releaseFocus()
--   ZeD.Input.Focus.getFocusedWindow()
--   ZeD.Input.Focus.isLocked()                            -- always false post-S113 (Y-lock retired)
--   ZeD.Input.Focus.getFocusedZone(w)                     -- current zone or nil
--   ZeD.Input.Focus.getFocusedElement(w)                  -- focused element or nil
--   ZeD.Input.Focus.setRingZoneElements(w, zoneRef, elements, preserveIdx?)
--   ZeD.Input.Focus.setZoneFocusable(w, zoneRef, flag)    -- drawer toggling
--   ZeD.Input.Focus.dispatchJoypadDown(w, button, joypadData)
--   ZeD.Input.Focus.dispatchJoypadDir(w, dir, joypadData)
--   ZeD.Input.Focus.reclaimEngineFocus()                  -- context-menu close path
--   ZeD.Input.Focus.cuesVisible()                         -- the controller's focus mark shows (pad in use)
--   ZeD.Input.Focus.isFocused(w, zoneName?, elementId?)   -- draw a focus mark here? (focused window only)
--   ZeD.Input.Focus.liveZone(w) / liveElement(w)          -- the same as zone / element, nil when not shown
--
-- Event emitted:
--   Events.ZeD_FocusChanged(newWindow, oldWindow)
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Input/SpatialNav"

-- Namespace (triple-guard per Q21 — PZ can re-execute files in any order).
ZeD = ZeD or {}
ZeD.Input = ZeD.Input or {}
ZeD.Input.Focus = ZeD.Input.Focus or {}

local Focus = ZeD.Input.Focus

-- ---------------------------------------------------------------------------
-- CONSTANTS
-- ---------------------------------------------------------------------------

-- Grace period after claimFocus during which stick aiming-escape is suppressed.
-- Without this, resting-finger trigger pressure (Q83) or stick drift can hide
-- the window the instant it opens.
local WS_GRACE_MS = 600

-- SDL standard controller axis indices. Mirrored from InputModeDetector.
local AXIS_RSTICK_X = 2
local AXIS_RSTICK_Y = 3

-- Token readers. Triple-guard to tolerate T.gp not being populated at
-- file-load time (same pattern as InputModeDetector / BumperChord).
local function _holdInitialMs()     return (ZeD.T and ZeD.T.gp and ZeD.T.gp.holdInitMs)        or 250 end
local function _holdRepeatMs()      return (ZeD.T and ZeD.T.gp and ZeD.T.gp.holdRepeatMs)      or 120 end
local function _holdMs()            return (ZeD.T and ZeD.T.gp and ZeD.T.gp.holdMs)            or 400 end
local function _aimingThresholdSq() return (ZeD.T and ZeD.T.gp and ZeD.T.gp.aimingThresholdSq) or 0.81 end

-- ---------------------------------------------------------------------------
-- FILE-LOCAL STATE
-- ---------------------------------------------------------------------------

local _focusedWindow = nil
local _windowRegistry = {}

-- D-pad hold-to-repeat tracking.
local _dpadHoldDir    = nil
local _dpadHoldStart  = 0
local _dpadLastRepeat = 0

-- Y hold-timer state (B no longer uses hold). Y is the only hold-armed button.
local _yHeld         = false
local _yStartMs      = 0
local _yConsumed     = false

-- S99: A-button tap-vs-hold state. Press defers firing until release (tap →
-- onActivate) or threshold (hold → onHoldActivate, when defined). `_aWindow`
-- captures which window owned focus at press time so the callback fires on
-- the correct window even if focus moved (defensive).
local _aHeld        = false
local _aStartMs     = 0
local _aConsumed    = false
local _aWindow      = nil
local A_HOLD_MS     = 350

-- S113c: X-button tap-vs-hold state, mirror of A's. Tap (release before
-- threshold) fires onContextMenu / onReset. Hold past threshold fires
-- onHoldContextDrag with no dir on entry (signal "drag mode armed"); while
-- X stays held, D-pad presses fire onHoldContextDrag(w, el, dir) instead
-- of generic cone-nav so the element can mutate its position. Release
-- after hold fires onHoldContextRelease (commit / exit drag).
local _xHeld         = false
local _xStartMs      = 0
local _xConsumed     = false
local _xWindow       = nil
local _xElement      = nil  -- captured at press time; locked through release
local X_HOLD_MS      = 350

-- Rising-edge tracker for Y when no window is focused (global Y-to-open).
local _prevYPressedUnfocused = false

-- Aiming-escape edge latch + grace period. (S113: _wsLocked retired since
-- Y-hold no longer toggles a lock.)
local _wsLatched       = false
local _wsGraceUntilMs  = 0

-- S113b: cone-nav debug overlay toggle. F9 toggles on. Paints the focused
-- element's bbox + half-plane regions for U/D/L/R + the per-direction picks
-- (cone winner cyan, half-plane winner magenta if cone missed). Throwaway
-- QA aid — strip after iteration converges.
local _debugOverlay    = false
-- Oct 19 2026: a dry run of a D-pad move (Focus.previewMove; the nav audit reads it)
local _preview = nil
-- Last-pick cache (per direction) so the overlay can highlight what
-- _pickBestWithFallback would choose in that direction without re-running
-- the picker every frame. Refreshed when overlay is on. Bounds in
-- WINDOW-LOCAL coords (already translated via _collectFlat).
local _debugLastPicks  = { up = nil, down = nil, left = nil, right = nil }
local _debugFocusBox   = nil  -- focused element's translated bounds (cached for paint)

-- ---------------------------------------------------------------------------
-- HELPERS (declared up-front so forward refs resolve — common mistake #16)
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

-- Push engine-level joypad focus so PZ's onJoypad* dispatch reaches our
-- window's shims. `nil` is valid — clears engine focus (Q87 canonical setter).
-- pcall-wrapped for Java proxy safety. Hardcoded playerID 0 (single-player);
-- split-screen threading deferred.
local function _pushEngineFocus(control)
    if not setJoypadFocus then return end
    pcall(setJoypadFocus, 0, control)
end

-- Tell the engine to ignore aim input until sticks recenter — prevents stick
-- pressure at the moment of claim from leaking into aiming. Only meaningful
-- in gamepad mode.
local function _maybeIgnoreAim()
    local mode = ZeD.Input.Detector and ZeD.Input.Detector.getMode
                 and ZeD.Input.Detector.getMode()
    if mode ~= "gamepad" then return end
    local jd = getJoypadData and getJoypadData(0)
    if jd and jd.setJoypadIgnoreAimUntilCentered then
        pcall(function() jd:setJoypadIgnoreAimUntilCentered(true) end)
    end
end

-- Enable/disable BumperChord. Wrapped in a helper because the module may not
-- be loaded yet (load-order-agnostic) and we don't want a nil-index crash
-- to break focus claim.
local function _setBumperChordEnabled(flag)
    if ZeD.Input.Chord and ZeD.Input.Chord.setEnabled then
        ZeD.Input.Chord.setEnabled(flag)
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
local _cuesOn = false
local _cueMouseX, _cueMouseY = nil, nil
local _cueSinceMs = 0

local function _showCues()
    _cuesOn = true
    _cueSinceMs = getTimestampMs() or 0
    if getMouseX then _cueMouseX, _cueMouseY = getMouseX(), getMouseY() end
end

local function _hideCues()
    _cuesOn = false
end

-- once per rendered frame (it also runs while the game is paused)
local function _watchCueMouse()
    if not _cuesOn or not getMouseX then return end
    local mx, my = getMouseX(), getMouseY()
    if _cueMouseX == nil then _cueMouseX, _cueMouseY = mx, my; return end
    local T = ZeD.T
    local th = (T and T.px) and T.px(CUE_MOUSE_U) or CUE_MOUSE_U
    if math.abs(mx - _cueMouseX) > th or math.abs(my - _cueMouseY) > th then _hideCues(); return end
    local D = ZeD.Input.Detector
    if D and D.msSinceMouseClick and D.msSinceMouseClick() < (getTimestampMs() or 0) - _cueSinceMs then
        _hideCues()
    end
end

--- True while the controller's focus mark shows: the last pad press that reached
-- a ZeD window is newer than the last use of the mouse.
function Focus.cuesVisible()
    return _cuesOn
end

-- ---------------------------------------------------------------------------
-- REGISTRY API
-- ---------------------------------------------------------------------------

function Focus.registerWindow(w)
    if not w then return end
    if _indexOf(w) then return end
    _windowRegistry[#_windowRegistry + 1] = w
    print("[ZeD.Input] Focus: register: " .. _label(w)
       .. " (" .. tostring(#_windowRegistry) .. " registered)")
end

-- Atomic focus transfer on unregister: if the removed window was focused and
-- another survives, hand off in a SINGLE ZeD_FocusChanged event so subscribers
-- can diff cleanly. If no survivors, degrades to regular release (new = nil).
function Focus.unregisterWindow(w)
    if not w then return end
    local wasFocused = (_focusedWindow == w)
    local idx = _indexOf(w)
    if idx then
        table.remove(_windowRegistry, idx)
        print("[ZeD.Input] Focus: unregister: " .. _label(w)
           .. " (" .. tostring(#_windowRegistry) .. " registered)")
    end
    if not wasFocused then return end

    local nextW = _windowRegistry[#_windowRegistry]
    local old   = _focusedWindow
    _focusedWindow = nextW
    _dpadHoldDir   = nil

    if nextW then
        print("[ZeD.Input] Focus: transfer: " .. _label(old)
           .. " -> " .. _label(nextW))
        _pushEngineFocus(nextW)
        _maybeIgnoreAim()
        -- BumperChord stays disabled — a ZeD window is still focused.
    else
        print("[ZeD.Input] Focus: release: " .. _label(old) .. " -> nil")
        _pushEngineFocus(nil)
        -- No more focused windows: hand bumpers back to the zoom chord.
        _setBumperChordEnabled(true)
    end

    triggerEvent("ZeD_FocusChanged", nextW, old)
end

-- ---------------------------------------------------------------------------
-- FOCUS CLAIM / RELEASE / READ
-- ---------------------------------------------------------------------------

function Focus.claimFocus(w)
    if not w then return end
    if _focusedWindow == w then return end

    local old = _focusedWindow
    _focusedWindow = w
    print("[ZeD.Input] Focus: claim: " .. _label(old) .. " -> " .. _label(w))
    -- a window the pad opened shows where its focus is at once
    do
        local D = ZeD.Input.Detector
        if D and D.getMode and D.getMode() == "gamepad" then _showCues() end
    end
    -- Oct 23 2026: land on something lit (the last focused element, else the
    -- list's first row); see Focus.ensureEntry
    if Focus.ensureEntry then
        local ok, err = pcall(Focus.ensureEntry, w)
        if not ok then print("[ZeD.Input] Focus: ensureEntry failed: " .. tostring(err)) end
    end

    _pushEngineFocus(w)
    _maybeIgnoreAim()

    -- Bumpers become window-swap while we hold focus. Disable the zoom chord.
    _setBumperChordEnabled(false)

    -- Start grace window against stick-drift / trigger-pressure aiming-escape.
    _wsGraceUntilMs = getTimestampMs() + WS_GRACE_MS
    _wsLatched      = false

    triggerEvent("ZeD_FocusChanged", w, old)
end

function Focus.releaseFocus()
    if not _focusedWindow then return end
    local old = _focusedWindow
    _focusedWindow = nil
    _dpadHoldDir   = nil

    _pushEngineFocus(nil)
    _setBumperChordEnabled(true)

    print("[ZeD.Input] Focus: release: " .. _label(old) .. " -> nil")
    triggerEvent("ZeD_FocusChanged", nil, old)
end

function Focus.getFocusedWindow()
    return _focusedWindow
end

-- S113: Y-hold no longer toggles a windowshade lock (Y-hold = close pair now).
-- Public reader retained as a permanent `false` so legacy callers don't blow up.
function Focus.isLocked()
    return false
end

-- ---------------------------------------------------------------------------
-- ZONE STORAGE API (preserved from S97 — per-tab builders unchanged)
--
-- Zones remain as a per-window STORAGE abstraction so existing per-tab builder
-- code (Equipment / Health / Thermal / Skills / Identity / Journal / Forage /
-- Animals / Maps / Craft / Build / InventoryRenderer / ItemCard) doesn't need
-- to be rewritten. The DIFFERENCE from S97: D-pad nav is flat across ALL
-- focusable zones in the focused window — bumpers no longer hop between zones.
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

-- Return the currently-focused ring entry (whole zone table), or nil.
function Focus.getFocusedZone(w)
    if not w or not w._focusRing then return nil end
    local idx = w._focusIdx or 1
    return w._focusRing[idx]
end

-- Return the currently-focused element inside the current zone, or nil.
function Focus.getFocusedElement(w)
    local zone = Focus.getFocusedZone(w)
    if not zone or not zone.elements then return nil end
    local ei = zone.focusedElementIdx or 1
    return zone.elements[ei]
end

-- getFocusedZone / getFocusedElement read a window's stored focus whether or not
-- the window has it (navigation and the windows' own logic need that). A focus
-- MARK needs more: the window is the focused one and the controller is in use.
-- Without that test the unfocused window kept lighting its remembered row
-- (Craft, Build, Journal, Animals, Foraging, Stations, JournalReaders), and
-- the mark stayed lit while the mouse was used. Surfaces draw marks through these:

--- The zone a focus mark may show in, or nil: w is the focused window and the
-- controller is in use.
function Focus.liveZone(w)
    if not w or w ~= _focusedWindow or not _cuesOn then return nil end
    return Focus.getFocusedZone(w)
end

--- The element a focus mark may show on, or nil (see liveZone).
function Focus.liveElement(w)
    if not Focus.liveZone(w) then return nil end
    return Focus.getFocusedElement(w)
end

--- True when a surface should draw the focus mark: w is the focused window, the
-- controller is in use, its focused zone is zoneName (when given) and its
-- focused element has the id elementId (when given).
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

-- Swap a zone's elements array (e.g. inventory row rebuild). Optionally
-- preserve focusedElementIdx at a specific value (else clamp existing).
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

-- Oct 23 2026: the same, keeping the focus on the element with the same id
-- when it is still there (a card's controls rebuilt each frame: a button
-- appearing before the focused one must not move the focus).
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

-- Toggle focusable flag on a zone (e.g. drawer open=true / closed=false).
-- If toggling OFF the currently-focused zone, advance _focusIdx to the next
-- focusable zone so the user doesn't end up stranded in a dead zone.
function Focus.setZoneFocusable(w, zoneRef, flag)
    local idx = _resolveZoneIdx(w, zoneRef)
    if not idx then return end
    w._focusRing[idx].focusable = flag and true or false

    if (not flag) and w._focusIdx == idx then
        -- Oct 23 2026: the window's list emptied under the focus (another
        -- container picked, the last item taken): focus goes back to the list
        -- as soon as it has rows again (Focus.ensureEntry, on the tick)
        if w._focusEntryZone and w._focusRing[idx].zone == w._focusEntryZone then
            w._focusPendingEntry = true
        end
        -- Oct 23 2026 (director: focus goes back to where you started, or its
        -- nearest neighbour in the same panel, "never to another panel or
        -- nowhere"): first a zone in the same panel that still has stops
        -- (the list's container buttons under it), only then the ring order
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
-- reclaimEngineFocus — context-menu close path. Re-push engine focus to the
-- tracked focused window so dispatch resumes after an external consumer
-- released engine focus.
-- ---------------------------------------------------------------------------

function Focus.reclaimEngineFocus()
    if _focusedWindow and setJoypadFocus then
        pcall(setJoypadFocus, 0, _focusedWindow)
    end
end

-- ---------------------------------------------------------------------------
-- WHERE FOCUS LANDS (Oct 23 2026, the director's first hands-on pad test:
-- "missing the selection in cone nav when first navigating to the world
-- window"; "the info cards do not land on the action strip")
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

-- A zone.landOn for cards (FocusManager's landing rule): a move into the
-- card lands on its primary action, the button the player most likely wants.
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
    if not (w and w._focusRing) then return end
    local live = _focusLive(w)
    if live and not w._focusPendingEntry then return end
    local zi = w._focusEntryZone and _resolveZoneIdx(w, w._focusEntryZone)
    local zone = zi and w._focusRing[zi]
    if zone and zone.focusable and zone.elements and #zone.elements > 0 then
        -- the remembered row when focus was last here, else the first row
        -- (rows carry .item; the List | Grid toggle and placeholders do not)
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

-- S113b: zone-name → window-field map. Each zone's element bounds are stamped
-- in the source PANEL'S local coords (e.g. an invrow's x=0 is the LEFT EDGE
-- of the content panel, not of the window). Cone-nav math compares all
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
    -- S123: map pop-out window (ZeD.MapsTab.openPopout) — one content zone
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
--                  to window-local coords (cone-nav math operates on this copy)
--   locator[i]   = { zoneIdx = N, elementIdx = M } for that flat position
-- Skips zones flagged focusable=false and zones with empty elements.
-- Translation: x/y get the source panel's offset added; w/h unchanged.
local function _collectFlat(w)
    local elements, locator = {}, {}
    if not w or not w._focusRing then return elements, locator end
    for zi = 1, #w._focusRing do
        local zone = w._focusRing[zi]
        -- (Oct 23 2026: zone.covered(w) = drawn over just now, e.g. a tab's
        -- controls under an item card that overlays the drawer: no stops)
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

-- Update window state after cone-nav landed on flat position newFlatIdx.
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
    -- S123: audible focus tick (vanilla list-select sound) so D-pad moves
    -- are felt without looking for the cue. Mouse hover never routes here.
    pcall(function() getSoundManager():playUISound("UISelectListItem") end)

    if newZoneIdx ~= oldZoneIdx and w.onFocusZoneChanged then
        _fireCb("window.onFocusZoneChanged", w.onFocusZoneChanged, w,
            { new = newZone, old = w._focusRing[oldZoneIdx] })
    end
end

-- The picker (Oct 15 2026, director: "cone navigation is blocking directions
-- that are logical ... freedom of movement is crucial"): ZeD.SpatialNav, by
-- rectangles: the nearest element LINED UP that way (spans overlapping across
-- the move), else the nearest that way at any angle. The strict 45-degree
-- centre cone above sent Right past a button beside a tall row and made the
-- player go down, over and up. _coneCost / _halfPlaneCost stay for reference.
-- Returns (idx, pass): pass "cone" = lined up, "half" = off to the side (the
-- debug overlay's cyan / magenta), nil when nothing lies that way.
local function _pickBestWithFallback(elements, focusedIdx, dir)
    if not elements or #elements == 0 then return nil, nil end
    if focusedIdx < 1 or focusedIdx > #elements then focusedIdx = 1 end
    local from = elements[focusedIdx]
    local N = ZeD.SpatialNav
    if not (from and N) then return nil, nil end
    local bestIdx, bestTier, bestCost = nil, nil, nil
    for i = 1, #elements do
        if i ~= focusedIdx then
            local tier, c = N.cost(from, elements[i], dir)
            if tier and (bestTier == nil or tier < bestTier or (tier == bestTier and c < bestCost)) then
                bestIdx, bestTier, bestCost = i, tier, c
            end
        end
    end
    if not bestIdx then return nil, nil end
    return bestIdx, (bestTier == 0) and "cone" or "half"
end

-- ---------------------------------------------------------------------------
-- DEBUG OVERLAY (S113b — F11 toggle)
-- ---------------------------------------------------------------------------

-- Public: toggle / read the overlay state from outside (key handler / console).
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
        -- Apply the same same-zone restriction for U/D that dispatch uses
        -- (S113c: vertical never leaves the panel, only horizontal crosses).
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
        local pickIdx, pass = _pickBestWithFallback(searchEls, searchFromIdx, dir)
        if not pickIdx and searchEls ~= elements then   -- nothing more in the panel: the next one over
            searchEls, searchFromIdx = elements, fromIdx
            pickIdx, pass = _pickBestWithFallback(searchEls, searchFromIdx, dir)
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

-- Render the overlay inside the focused window's render cycle. Monkey-patched
-- onto ZeD_Window:render at OnGameStart (see bottom of this file). The hook
-- runs AFTER the original render, in a valid draw context, so panel-local
-- drawRect/drawText work. Wrapped in pcall by the caller — overlay bugs
-- MUST NEVER take down the game.
local function _hasBounds(el)
    return el and type(el.x) == "number" and type(el.y) == "number"
       and type(el.w) == "number" and type(el.h) == "number"
       and el.w > 0 and el.h > 0
end

local function _drawDebugOverlay()
    if not _debugOverlay then return end
    -- S123 (GAMEPAD_SPEC open item): the overlay is a cone-nav aid; keep it
    -- off while the detector says mouse so a stray F9 never paints over KBM play.
    local mode = ZeD.Input.Detector and ZeD.Input.Detector.getMode and ZeD.Input.Detector.getMode()
    if mode ~= "gamepad" then return end
    local w = _focusedWindow
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

    -- Per-direction pick: cyan = strict cone, magenta = half-plane fallback.
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
            -- line primitive — Q12). Walks from focus center to target center.
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

-- LB/RB: claim focus on a specific window (LB = Character, RB = World).
-- Absolute, not toggle — pressing LB while already on Character is a no-op
-- (Focus.claimFocus early-exits when target == _focusedWindow). On gamepad
-- both windows are guaranteed open by the window-pair invariant; if one is
-- somehow missing (transition / boot), call ensureBothOpenForGamepad first.
local function _focusWindow(side)
    local CW = ZeD_CharacterWindow
    local WW = ZeD_WorldWindow
    if not CW or not WW then return end

    -- Enforce invariant first — a closed sibling would make the bumper a no-op.
    if CW.ensureBothOpenForGamepad then
        pcall(CW.ensureBothOpenForGamepad, 0)
    end

    local charWin  = CW.getWindow  and CW.getWindow()
    local worldWin = WW.getWindow  and WW.getWindow()
    if not charWin or not worldWin then return end

    local target = (side == "char") and charWin or worldWin

    -- Unshade the target if it was hidden — bumper means "go look at this one".
    if target.windowShaded and target.setWindowShaded then
        target:setWindowShaded(false)
    end

    Focus.claimFocus(target)
end

-- A button (tap): fire the focused element's onActivate (= LMB).
local function _handleConfirm(w)
    local el = Focus.getFocusedElement(w)
    if not el then return end
    if el.onActivate then pcall(function() getSoundManager():playUISound("UIActivateButton") end) end
    _fireCb("element.onActivate", el.onActivate, w, el)
end

-- A button (hold past A_HOLD_MS): fire onHoldActivate if defined (= double-LMB).
-- Used by invrows for vanilla "use item" (eat/wear/equip/read/consume).
local function _handleHoldConfirm(w)
    local el = Focus.getFocusedElement(w)
    if not el or not el.onHoldActivate then return end
    _fireCb("element.onHoldActivate", el.onHoldActivate, w, el)
end

-- X button: fire onContextMenu (= RMB) if defined; else onReset if defined
-- (3-option dialogs only — A=Yes, B=No, X=Reset). Mutually exclusive.
local function _handleContextOrReset(w)
    local el = Focus.getFocusedElement(w)
    if not el then return end
    if el.onContextMenu then
        _fireCb("element.onContextMenu", el.onContextMenu, w, el)
    elseif el.onReset then
        _fireCb("element.onReset", el.onReset, w, el)
    end
end

-- B button: pure contextual cancel. If focused element has onCancel, fire it.
-- If not, NO-OP (no shade-all fallback). S113 design ruling: B does nothing
-- when there's nothing to cancel; user must press Y to hide / RS to aiming-
-- escape if they want to dismiss the windows.
local function _handleBContextual()
    local w = _focusedWindow
    if not w then return end
    local el = Focus.getFocusedElement(w)
    if not el or not el.onCancel then return end
    pcall(function() getSoundManager():playUISound("UIToggleTickBox") end)
    _fireCbR("element.onCancel", el.onCancel, w, el)
    -- Return value ignored — no fall-through path exists post-S113.
end

-- The registered window lying `dir` of w on screen (visible, not rolled up),
-- nearest first by the same rectangle rule as the controls; nil when none.
local function _windowThatWay(w, dir)
    local N = ZeD.SpatialNav
    if not (N and w and w.getX and w._focusEntryZone) then return nil end
    local from = { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
    local best, bestTier, bestCost
    for i = 1, #_windowRegistry do
        local o = _windowRegistry[i]
        -- (the window pair only: windows with an entry zone, not the dash or the map's pop-out)
        if o ~= w and o._focusEntryZone and o.isVisible and o:isVisible() and not o.windowShaded and o._focusRing then
            local tier, c = N.cost(from, { x = o:getX(), y = o:getY(), w = o:getWidth(), h = o:getHeight() }, dir)
            if tier and (bestTier == nil or tier < bestTier or (tier == bestTier and c < bestCost)) then
                best, bestTier, bestCost = o, tier, c
            end
        end
    end
    return best
end

-- D-pad: pseudo-focusable onDpadDir intercept first (cursor movement, grid
-- scroll), else flat cone-nav across all focusable zones.
local function _handleSpatialNav(w, dir)
    if not w or not w._focusRing then return end

    -- S113c: X-HOLD DRAG INTERCEPT. If X is held past threshold AND the
    -- captured drag element has onHoldContextDrag, route D-pad presses to
    -- the element's drag handler instead of cone-nav. Focus does NOT shift
    -- during drag — the element stays locked under X-hold; D-pad mutates
    -- its position/state via the callback. Fires BEFORE generic onDpadDir
    -- so a drag-capable element can be reordered without conflicting with
    -- its idle-state navigation behavior.
    if not _preview and _xHeld and _xConsumed and _xElement and _xElement.onHoldContextDrag then
        _fireCb("element.onHoldContextDrag(dir)",
            function(ww, ee) _xElement.onHoldContextDrag(ww, ee, dir) end,
            _xWindow or w, _xElement)
        return
    end

    -- Pseudo-focusable intercept (unified contract). Element may consume by
    -- returning anything other than false; returning false falls through to
    -- generic cone-nav.
    local focEl = Focus.getFocusedElement(w)
    if focEl and focEl.onDpadDir then
        if _preview then _preview.custom = true end   -- (a dry run reports it, then picks as if it fell through)
        if not _preview then
            local result = _fireCbR("element.onDpadDir", focEl.onDpadDir, w, focEl, dir)
            if result ~= false then return end
        end
    end

    -- Generic flat cone-nav. Collect every element from focusable zones,
    -- find the focused element's flat position, run two-pass picker.
    local elements, locator = _collectFlat(w)
    if #elements == 0 then return end

    local fromIdx = _findCurrentFlatIdx(w, locator) or 1

    -- Oct 19 2026 (the nav audit): back the way you came. The press opposite
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
                print("[ZeD.Input] Focus: spatial " .. dir .. " -> back to " .. tostring(e.id) .. " [" .. _label(w) .. "]")
                _applyFlatLanding(w, locator, fromIdx, i)
                return
            end
        end
    end

    -- S113c rule (design director): UP/DOWN stays in the current panel while
    -- the panel has anything more that way; Oct 15 2026 ("freedom of movement
    -- is crucial") it then goes on to the next panel instead of stopping.
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

    local newPickIdx, pass = _pickBestWithFallback(searchEls, fromIdx, dir)
    if not newPickIdx and searchEls ~= elements then
        -- Oct 23 2026 (the pad map): then the rest of the same panel before
        -- any other (Down from a list's last row reaches the container
        -- buttons under it, not a control in the drawer beside it)
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
            local pk, ps = _pickBestWithFallback(pEls, pFrom, dir)
            if pk then
                searchEls, searchLoc, newPickIdx, pass = pEls, pLoc, pk, ps
            end
        end
    end
    if not newPickIdx and searchEls ~= elements then
        -- nothing more that way in this panel: the nearest one beyond it
        searchEls, searchLoc = elements, locator
        fromIdx = _findCurrentFlatIdx(w, locator) or 1
        newPickIdx, pass = _pickBestWithFallback(searchEls, fromIdx, dir)
    end
    if not newPickIdx then
        -- Oct 23 2026: nothing more that way in this window: Left / Right go
        -- on to the other window when it sits that way on screen (the pair
        -- side by side), landing where Focus.ensureEntry puts it
        if dir == "left" or dir == "right" then
            local other = _windowThatWay(w, dir)
            if other then
                if _preview then
                    _preview.zone, _preview.id, _preview.pass = "window", _label(other), "window"
                    return
                end
                print("[ZeD.Input] Focus: spatial " .. dir .. " -> window " .. _label(other))
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

    -- Oct 19 2026 (the nav audit): Left / Right with nothing level in this
    -- panel go on to the next panel that way, never to a control above or
    -- below in the same panel. (A row's Left went to the container buttons
    -- under the list, not the tab column; its Right to the List | Grid
    -- toggle over the list, not the container column.)
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

    -- Oct 17 2026: a move never jumps over a whole panel. The picker prefers a
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
                local pick = _pickBestWithFallback(subEls, 1, dir)
                if pick and subIdx[pick] then newFlatIdx, pass = subIdx[pick], "panel" end
            end
        end
    end

    -- S113c: cross-zone landing on a TAB STRIP snaps to the active tab,
    -- not the spatially-closest tab. Rationale: when the user cone-navs
    -- INTO the tab waterfall from another panel, the active tab is the
    -- intuitive starting point — they came here to see "what's open" and
    -- (likely) switch from there. Without this, cone-nav lands on whichever
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

    -- Oct 23 2026: the same rule for any zone that names its landing
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
       .. " [" .. _label(w) .. "]")
    _applyFlatLanding(w, locator, logFromIdx, newFlatIdx)
end

-- Hide every registered window (windowshade) + release focus. Idempotent.
local function _hideAllWindows(reason)
    if #_windowRegistry == 0 then return end
    print("[ZeD.Input] Focus: hideAll (" .. (reason or "?") .. ")")
    for _, w in ipairs(_windowRegistry) do
        if w.setWindowShaded and not w.windowShaded then
            w:setWindowShaded(true)
        end
    end
    Focus.releaseFocus()
end

-- Close every registered window (hard close). Copies registry first because
-- close() re-enters unregisterWindow and mutates the array mid-iteration.
local function _closeAllWindows()
    if #_windowRegistry == 0 then return end
    print("[ZeD.Input] Focus: closeAll")
    local toClose = {}
    for _, w in ipairs(_windowRegistry) do toClose[#toClose + 1] = w end
    for _, w in ipairs(toClose) do
        if w.close then
            pcall(function() w:close() end)
        end
    end
    Focus.releaseFocus()
end

-- Y tap: paired visibility toggle.
--   both closed   → open both (Character focus)
--   both visible  → hide both (windowshade, release focus)
--   both shaded   → unhide both (Character focus)
--   mixed         → normalize via ensureBothOpenForGamepad + unhide all,
--                   focus Character (gamepad invariant: paired)
local function _handleYTap()
    local CW = ZeD_CharacterWindow
    local WW = ZeD_WorldWindow
    if not CW or not WW then return end

    local charOpen  = CW.isOpen and CW.isOpen()
    local worldOpen = WW.isOpen and WW.isOpen()

    -- Both closed: open both.
    if (not charOpen) and (not worldOpen) then
        if CW.ensureBothOpenForGamepad then
            CW.ensureBothOpenForGamepad(0)
        elseif CW.toggleBothPaired then
            CW.toggleBothPaired(0)
        end
        local charWin = CW.getWindow and CW.getWindow()
        if charWin then Focus.claimFocus(charWin) end
        print("[ZeD.Input] Focus: Y tap - opened pair, Character focus")
        return
    end

    -- Mixed (one open, one closed): enforce invariant.
    if charOpen ~= worldOpen then
        if CW.ensureBothOpenForGamepad then CW.ensureBothOpenForGamepad(0) end
        local charWin = CW.getWindow and CW.getWindow()
        if charWin then
            if charWin.windowShaded and charWin.setWindowShaded then
                charWin:setWindowShaded(false)
            end
            Focus.claimFocus(charWin)
        end
        local worldWin = WW.getWindow and WW.getWindow()
        if worldWin and worldWin.windowShaded and worldWin.setWindowShaded then
            worldWin:setWindowShaded(false)
        end
        print("[ZeD.Input] Focus: Y tap - normalized pair, Character focus")
        return
    end

    -- Both open: visibility toggle (paired).
    local charWin  = CW.getWindow  and CW.getWindow()
    local worldWin = WW.getWindow  and WW.getWindow()
    if not charWin or not worldWin then return end

    local charShaded  = charWin.windowShaded
    local worldShaded = worldWin.windowShaded
    local bothShaded  = charShaded and worldShaded
    local bothVisible = (not charShaded) and (not worldShaded)

    if bothVisible then
        if charWin.setWindowShaded  then charWin:setWindowShaded(true)  end
        if worldWin.setWindowShaded then worldWin:setWindowShaded(true) end
        Focus.releaseFocus()
        print("[ZeD.Input] Focus: Y tap - hide pair")
        return
    end

    if bothShaded then
        if charWin.setWindowShaded  then charWin:setWindowShaded(false)  end
        if worldWin.setWindowShaded then worldWin:setWindowShaded(false) end
        Focus.claimFocus(charWin)
        print("[ZeD.Input] Focus: Y tap - unhide pair, Character focus")
        return
    end

    -- One shaded one not: normalize to both-visible.
    if charShaded  and charWin.setWindowShaded  then charWin:setWindowShaded(false)  end
    if worldShaded and worldWin.setWindowShaded then worldWin:setWindowShaded(false) end
    Focus.claimFocus(charWin)
    print("[ZeD.Input] Focus: Y tap - normalized visibility, Character focus")
end

-- Y hold: close BOTH windows (full lifecycle teardown — close() unregisters
-- via FocusManager.unregisterWindow which restores ISButtonPrompt).
local function _handleYHold()
    print("[ZeD.Input] Focus: Y hold - close pair")
    _closeAllWindows()
end

-- ---------------------------------------------------------------------------
-- DISPATCH ENTRY POINTS
-- ---------------------------------------------------------------------------

function Focus.dispatchJoypadDown(w, button, joypadData)
    if not w then return end
    _showCues()
    local actions = ZeD.Input.Action and ZeD.Input.Action.fromGamepadButton
                    and ZeD.Input.Action.fromGamepadButton(button)
    if not actions then return end

    for i = 1, #actions do
        local aid = actions[i]
        if aid == "confirm" then
            -- A = tap-vs-hold. Defer firing until release (tap → onActivate)
            -- or hold threshold (A_HOLD_MS → onHoldActivate). Re-press during
            -- a hold cycle is a noop.
            if not _aHeld then
                _aHeld      = true
                _aStartMs   = getTimestampMs()
                _aConsumed  = false
                _aWindow    = w
            end
            return
        elseif aid == "context_menu" then
            -- S113c: X = tap-vs-hold. Tap (release < X_HOLD_MS) fires
            -- onContextMenu/onReset. Hold past threshold enters drag mode
            -- (onHoldContextDrag fires with no dir; subsequent D-pad presses
            -- fire onHoldContextDrag(dir); release fires onHoldContextRelease).
            -- Defer firing until release/threshold (mirror of A).
            if not _xHeld then
                _xHeld      = true
                _xStartMs   = getTimestampMs()
                _xConsumed  = false
                _xWindow    = w
                _xElement   = Focus.getFocusedElement(w)
            end
            return
        elseif aid == "window_prev" then
            _focusWindow("char"); return    -- LB → Character (absolute)
        elseif aid == "window_next" then
            _focusWindow("world"); return   -- RB → World (absolute)
        elseif aid == "cancel" then
            -- B is now immediate (no hold). Pure contextual cancel.
            _handleBContextual(); return
        elseif aid == "window_control" then
            -- Y press arms hold timer. OnTick decides tap vs hold.
            if not _yHeld then
                _yHeld      = true
                _yStartMs   = getTimestampMs()
                _yConsumed  = false
            end
            return
        elseif aid == "list_sort" or aid == "list_view" then
            -- L3 / R3 (Oct 23 2026, Hard Rule #11 as amended): only here, with a
            -- window holding the pad; a view change of its list, nothing else
            local R = ZeD.InventoryRenderer
            local fn = R and ((aid == "list_sort") and R.padSort or R.padView)
            if fn then pcall(fn, w) end
            return
        end
        -- Other action IDs (layout_mode, strip_*, inspect) not dispatched
        -- here. Strip menus fire when NO window has focus (OnTick path, TBD).
    end
end

-- Put focus on an element by id, in a zone of window w, as soon as it exists
-- (an event that rebuilds a zone, like folding the map back, names where focus
-- should land; the element appears a frame or two later). Tries for ~1 s.
local _focusSoon = {}
function Focus.focusByIdSoon(w, zoneName, id)
    _focusSoon[#_focusSoon + 1] = { w = w, zone = zoneName, pred = function(e) return e.id == id end, tries = 60 }
end
-- Oct 23 2026: the same for any test (pred(el, i)), after `delay` ticks (a
-- view that has to draw once first, like a card swapping to another item)
function Focus.focusSoon(w, zoneName, pred, delay)
    _focusSoon[#_focusSoon + 1] = { w = w, zone = zoneName, pred = pred, tries = 60, delay = delay or 0 }
end
-- A card just opened (A on a row): focus goes to its primary action (the
-- element marked isPrimary, else its first), so A again does it.
function Focus.focusPrimarySoon(w, zoneName, delay)
    _focusSoon[#_focusSoon + 1] = { w = w, zone = zoneName, primary = true, tries = 60, delay = delay or 0 }
end
local function _focusSoonTick()
    if #_focusSoon == 0 then return end
    for i = #_focusSoon, 1, -1 do
        local f = _focusSoon[i]
        local done = false
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

-- Oct 19 2026 (the controller nav audit): where a D-pad press would go from
-- the focused element, without moving focus or running any handler.
-- Returns { zone, id, pass } (nil zone = nothing that way), and custom = true
-- when the element has its own D-pad handler (which would run first).
function Focus.previewMove(w, dir)
    _preview = {}
    local ok = pcall(_handleSpatialNav, w, dir)
    local r = _preview
    _preview = nil
    if not ok then r.err = true end
    return r
end

-- Oct 23 2026 (the pad map, ZeDUI/tools/qa/zedqa_padmap.lua): every stop of
-- the window as the D-pad sees it, window-local: { zone, zi, ei, id, x, y,
-- w, h, el } in flat order.
function Focus.flatElements(w)
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

function Focus.dispatchJoypadDir(w, dir, joypadData)
    if not w then return end
    _showCues()

    -- Track hold-start for auto-repeat. Engine fires onJoypadDir* on initial
    -- press only; OnTick does the repeat work.
    if _dpadHoldDir ~= dir then
        _dpadHoldDir    = dir
        _dpadHoldStart  = getTimestampMs()
        _dpadLastRepeat = _dpadHoldStart
    end

    _handleSpatialNav(w, dir)
end

-- ---------------------------------------------------------------------------
-- ONTICK POLL
--   (A) Mode gate
--   (B) Global Y rising edge (only when no window focused) — opens the pair
--   (C) Y hold-timer release / threshold
--   (C2) A tap-vs-hold resolver
--   (D) Aiming escape (right stick magnitude² > T.gp.aimingThresholdSq)
--   (E) D-pad hold-to-repeat
-- ---------------------------------------------------------------------------

local function _currentDpadDir(joypadData)
    if not joypadData or not joypadData.id then return nil end
    local jid = joypadData.id
    -- Q109 (B42.17): JoypadButton.<n>:isDown(id) replaces removed isJoypadPressed.
    if JoypadButton.DPadUp:isDown(jid)    then return "up"    end
    if JoypadButton.DPadDown:isDown(jid)  then return "down"  end
    if JoypadButton.DPadLeft:isDown(jid)  then return "left"  end
    if JoypadButton.DPadRight:isDown(jid) then return "right" end
    return nil
end

local function _onTick()
    -- (A) Mode gate.
    local mode = ZeD.Input.Detector and ZeD.Input.Detector.getMode
                 and ZeD.Input.Detector.getMode()
    if mode ~= "gamepad" then
        if _dpadHoldDir           then _dpadHoldDir = nil end
        if _yHeld                 then _yHeld = false; _yConsumed = false end
        if _prevYPressedUnfocused then _prevYPressedUnfocused = false end
        if _wsLatched             then _wsLatched = false end
        if _aHeld                 then _aHeld = false; _aConsumed = false; _aWindow = nil end
        if _xHeld                 then _xHeld = false; _xConsumed = false; _xWindow = nil; _xElement = nil end
        return
    end

    -- Oct 23 2026: never focus with nothing lit. A fresh window lands on its
    -- list's first row once the rows exist; focus left on a zone that went
    -- away (a card closed, a tab emptied) moves to the list (Focus.ensureEntry)
    if _focusedWindow and (_focusedWindow._focusPendingEntry or not _focusLive(_focusedWindow)) then
        local ok, err = pcall(Focus.ensureEntry, _focusedWindow)
        if not ok then print("[ZeD.Input] Focus: ensureEntry failed: " .. tostring(err)) end
    end
    -- Oct 23 2026 (director: "it's not properly releasing control and
    -- returning control back to the spot"): a prompt or menu that closed and
    -- left the pad with no focus at all (it goes to the game then: Left was
    -- the belt) hands it back to the focused window, on the element it had
    if _focusedWindow and JoypadState and JoypadState.players and JoypadState.players[1]
       and getJoypadFocus and getJoypadFocus(0) == nil
       and _focusedWindow:isVisible() and not _focusedWindow.windowShaded then
        _pushEngineFocus(_focusedWindow)
    end

    local jd = getJoypadData and getJoypadData(0)
    if not jd or not jd.id then return end
    local jid = jd.id

    -- (B) Global Y rising-edge (only when no ZeD window is focused).
    if not _focusedWindow then
        local yNow = JoypadButton.Y:isDown(jid)
        -- (Oct 24 2026: with a bumper held, Y is a quick action chord, ZeD_QuickChords.lua, never the windows)
        local bumper = JoypadButton.LeftBump:isDown(jid) or JoypadButton.RightBump:isDown(jid)
        if yNow and (not _prevYPressedUnfocused) and (not _yHeld) and not bumper then
            _yHeld      = true
            _yStartMs   = getTimestampMs()
            _yConsumed  = false
        end
        _prevYPressedUnfocused = yNow
    else
        _prevYPressedUnfocused = false
    end

    -- (C) Y hold-timer.
    if _yHeld then
        local stillDown = JoypadButton.Y:isDown(jid)
        if stillDown then
            if (not _yConsumed) and (getTimestampMs() - _yStartMs) >= _holdMs() then
                _handleYHold()
                _yConsumed = true
            end
        else
            if not _yConsumed then _handleYTap() end
            _yHeld     = false
            _yStartMs  = 0
            _yConsumed = false
        end
    end

    -- (C2) A tap-vs-hold resolver. Tap → onActivate on release; hold past
    -- A_HOLD_MS → onHoldActivate (if focused element defines it). Released-
    -- early without a hold target fires onActivate; released-early after
    -- threshold already fired _handleHoldConfirm and is marked consumed.
    if _aHeld then
        local stillDown = JoypadButton.A:isDown(jid)
        if stillDown then
            if (not _aConsumed) and (getTimestampMs() - _aStartMs) >= A_HOLD_MS then
                local targetW = _aWindow or _focusedWindow
                local el = targetW and Focus.getFocusedElement(targetW) or nil
                if el and el.onHoldActivate then
                    _handleHoldConfirm(targetW)
                    _aConsumed = true
                end
            end
        else
            if not _aConsumed then
                local targetW = _aWindow or _focusedWindow
                if targetW then _handleConfirm(targetW) end
            end
            _aHeld     = false
            _aStartMs  = 0
            _aConsumed = false
            _aWindow   = nil
        end
    end

    -- (C3) S113c X tap-vs-hold resolver. Tap → onContextMenu/onReset on
    -- release; hold past X_HOLD_MS → onHoldContextDrag(w, el, nil) (drag-mode
    -- entry, dir == nil signals "armed"). On release after consumption,
    -- fire onHoldContextRelease (commit). _xElement is captured at press to
    -- lock the drag target — focused element may shift if cone-nav fires
    -- mid-hold (defensive, shouldn't happen since D-pad is intercepted).
    if _xHeld then
        local stillDown = JoypadButton.X:isDown(jid)
        if stillDown then
            if (not _xConsumed) and (getTimestampMs() - _xStartMs) >= X_HOLD_MS then
                local el = _xElement
                if el and el.onHoldContextDrag then
                    _fireCb("element.onHoldContextDrag(arm)",
                        function(w, e) el.onHoldContextDrag(w, e, nil) end,
                        _xWindow or _focusedWindow, el)
                    _xConsumed = true
                end
            end
        else
            if _xConsumed then
                -- Was a hold — fire release callback if defined.
                local targetW = _xWindow or _focusedWindow
                local el = _xElement
                if el and el.onHoldContextRelease then
                    _fireCb("element.onHoldContextRelease",
                        el.onHoldContextRelease, targetW, el)
                end
            else
                -- Was a tap — fire normal context-menu / reset path.
                local targetW = _xWindow or _focusedWindow
                if targetW then _handleContextOrReset(targetW) end
            end
            _xHeld     = false
            _xStartMs  = 0
            _xConsumed = false
            _xWindow   = nil
            _xElement  = nil
        end
    end

    -- (D) Aiming escape. Right-stick magnitude² > threshold → hide pair.
    -- No lock state (Y-hold-lock retired S113); always fires when active.
    -- Iterate connected controllers (Q89) and compute right-stick magnitude².
    -- NO math.abs() on axis values (Q90) — we use ax²+ay² which is always >=0.
    local aimThSq = _aimingThresholdSq()
    local maxMagSq = 0
    local n = (getControllerCount and getControllerCount()) or 0
    for ctlIdx = 0, n - 1 do
        if isControllerConnected and isControllerConnected(ctlIdx) then
            local rx = getControllerAxisValue(ctlIdx, AXIS_RSTICK_X) or 0
            local ry = getControllerAxisValue(ctlIdx, AXIS_RSTICK_Y) or 0
            local m2 = rx*rx + ry*ry
            if m2 > maxMagSq then maxMagSq = m2 end
        end
    end

    local aimingActive = (maxMagSq > aimThSq)
    local graceActive  = (getTimestampMs() < _wsGraceUntilMs)
    local canFire = aimingActive and _focusedWindow and (not _wsLatched)
                    and (not graceActive)

    if canFire then
        _wsLatched = true
        print("[ZeD.Input] Focus: aiming-escape magSq=" .. tostring(maxMagSq)
           .. " " .. _label(_focusedWindow))
        _hideAllWindows("aim-RS")
        return
    end

    -- Edge latch bookkeeping: latch when aiming-active, unlatch when in deadzone.
    if aimingActive then
        _wsLatched = true
    else
        _wsLatched = false
    end

    -- (E) D-pad hold-to-repeat (only if still focused after aiming-escape path).
    if not _focusedWindow then
        if _dpadHoldDir then _dpadHoldDir = nil end
        return
    end

    local dir = _currentDpadDir(jd)
    if not dir then
        if _dpadHoldDir then _dpadHoldDir = nil end
        return
    end

    if dir ~= _dpadHoldDir then
        _dpadHoldDir    = dir
        _dpadHoldStart  = getTimestampMs()
        _dpadLastRepeat = _dpadHoldStart
        return
    end

    local now = getTimestampMs()
    if (now - _dpadHoldStart) >= _holdInitialMs()
       and (now - _dpadLastRepeat) >= _holdRepeatMs() then
        _handleSpatialNav(_focusedWindow, dir)
        _dpadLastRepeat = now
    end
end

-- ---------------------------------------------------------------------------
-- EVENT REGISTRATION
-- ---------------------------------------------------------------------------

if LuaEventManager and LuaEventManager.AddEvent then
    LuaEventManager.AddEvent("ZeD_FocusChanged")
    -- S113: AddEvent is idempotent (per InputModeDetector comment) so it's
    -- safe to materialize ZeD_InputModeChanged here too. Mirrors BumperChord's
    -- pattern — file-load order may put us before InputModeDetector, in which
    -- case Events.ZeD_InputModeChanged would not yet exist for our .Add call.
    LuaEventManager.AddEvent("ZeD_InputModeChanged")
end

Events.OnTick.Add(_onTick)
if Events.OnRenderTick then Events.OnRenderTick.Add(_watchCueMouse) end

-- S113: Window-pair invariant. On kbm→gamepad transition, ensure both windows
-- are open as a pair (gamepad-only invariant; mouse mode keeps asymmetric
-- open/closed state). Late-binds ZeD_CharacterWindow because that module
-- loads after this one (Input/* is a separate dir from the windows).
local function _onModeChanged(newMode, oldMode)
    -- the mouse or keyboard took over: the focus marks go (the focus itself stays)
    if newMode == "kbm" then _hideCues() end
    if newMode == "gamepad" and oldMode ~= "gamepad" then
        if ZeD_CharacterWindow and ZeD_CharacterWindow.ensureBothOpenForGamepad then
            pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, 0)
        end
    end
end
Events.ZeD_InputModeChanged.Add(_onModeChanged)

-- S113b: F9 toggles the cone-nav debug overlay. Throwaway QA aid; the draw
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

-- S113b: Overlay paints inside the focused window's render cycle (guaranteed
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
            if _debugOverlay and _focusedWindow == self then
                pcall(_drawDebugOverlay)
            end
        end
    end
    print("[ZeD.Input] FocusManager loaded - S113 FLAT FREE-NAV (LB=Char, RB=World, D-pad=flat cone-nav, Y=pair toggle, F9=debug overlay)")
end)
