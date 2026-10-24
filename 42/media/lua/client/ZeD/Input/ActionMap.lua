-- ZeD-UI/42/media/lua/client/ZeD/Input/ActionMap.lua
-- ============================================================================
-- LAYER 6 — ActionMap (S91 — Gamepad Phase 1 Infrastructure)
--
-- Logical action layer that decouples UI components from raw input. Every
-- interaction is a logical action with KBM and gamepad bindings; UI code
-- queries actions, never raw buttons. Future rebinding touches this file
-- only — components never change.
--
-- This file ships the Phase 1 SCHEMA. Consumers (FocusManager, BumperChord,
-- StripMenus) arrive in later phases and read from the table defined here.
-- Hold-variant fields (holdMs, tapAction, holdAction) are declared on B and
-- Y even though Phase 1 has no hold-detection layer — Phase 3's FocusManager
-- will read them without us needing to revisit this file.
--
-- Public interface (see GAMEPAD_SPEC.md §10):
--   ZeD.Input.Action.fromGamepadButton(button)   -> {actionId, ...} | {}
--   ZeD.Input.Action.fromKey(keyCode, mods)      -> {actionId, ...} | {}
--   ZeD.Input.Action.getBinding(actionId, mode)  -> binding value | nil
--
-- Notes on the return shape:
--   fromGamepadButton and fromKey return LISTS because some buttons are
--   shared (DPad directions serve both nav_* and strip_*). The caller —
--   typically FocusManager — disambiguates by current focus state. For
--   uniquely-bound buttons (A, B, X, Y, Back) the list has exactly one
--   element; callers can just index [1].
-- ============================================================================

-- Namespace setup. Matches the shape InputModeDetector establishes.
ZeD = ZeD or {}
ZeD.Input = ZeD.Input or {}
ZeD.Input.Action = ZeD.Input.Action or {}

local Action = ZeD.Input.Action

-- ---------------------------------------------------------------------------
-- ACTION TABLE (GAMEPAD_SPEC §10, locked S90)
-- The source of truth. Every binding flows from here.
--
-- Shape of each entry:
--   { kbm = <keyName|"MouseRight"|nil>, gamepad = <buttonName|nil>,
--     holdMs = <int>?, tapAction = <string>?, holdAction = <string>? }
--
-- Hold semantics (only on `cancel` and `window_control` in Phase 1 schema):
--   holdMs      — threshold in ms; FocusManager's hold timer consumes this
--   tapAction   — fires on release BEFORE threshold; string is informational
--   holdAction  — fires once AT threshold with button still down
-- ---------------------------------------------------------------------------
ZeD.Input.Actions = {
    -- ----- NAVIGATION (universal) --------------------------------------------
    confirm = {
        kbm = "Return",
        gamepad = "A",
    },

    -- `cancel` is pure contextual post-S113 — fires the focused element's
    -- onCancel if defined, else NO-OP. No shade-all fallback, no hold variant.
    -- The Y-hold pair-close path supersedes the old B-hold close-all.
    cancel = {
        kbm = "Escape",
        gamepad = "B",
    },

    -- D-pad = flat cone-nav across ALL focusable zones in the focused window
    -- (S113 FLAT FREE-NAV model). Bumpers no longer cycle zones; they swap
    -- between the two paired windows.
    nav_up    = { kbm = "Up",    gamepad = "DPadUp"    },
    nav_down  = { kbm = "Down",  gamepad = "DPadDown"  },
    nav_left  = { kbm = "Left",  gamepad = "DPadLeft"  },
    nav_right = { kbm = "Right", gamepad = "DPadRight" },

    -- ----- WINDOW SELECT (S113 — replaces S97 zone cycling) ----------------
    -- LB = Character, RB = World (absolute — pressing LB while already on
    -- Character is a no-op, not a toggle). Always-paired on gamepad so the
    -- target window is guaranteed to exist. Only dispatched while a ZeD window
    -- is focused; BumperChord is disabled during focus so LB/RB route here.
    -- When no window focused, BumperChord reclaims bumpers for zoom chord.
    -- Action names retained for reverse-map continuity (window_prev/next was
    -- the symmetric naming under the original toggle semantic).
    window_prev = { kbm = nil, gamepad = "LB" },  -- LB → Character
    window_next = { kbm = nil, gamepad = "RB" },  -- RB → World

    -- ----- WINDOW CONTROL (S113 paired semantics) ----------------------------
    -- Single button serves four roles based on state and tap/hold:
    --   tap + no windows open  → open pair (Character + World, Character focus)
    --   tap + pair visible     → hide pair (windowshade both, release focus)
    --   tap + pair shaded      → unhide pair (Character focus)
    --   hold (~400ms)          → close BOTH windows (full lifecycle teardown)
    -- No KBM binding — paired-window control is gamepad-only ergonomics.
    window_control = {
        kbm = nil,
        gamepad = "Y",
        holdMs = 400,
        tapAction = "toggle_pair_visibility",
        holdAction = "close_pair",
    },

    -- ----- LAYOUT MODE (View/Share/Select button) ---------------------------
    -- Modal toggle: press to enter layout-edit mode on focused window, press
    -- again to exit. KBM has no binding; layout editing is a gamepad UX.
    layout_mode = {
        kbm = nil,
        gamepad = "Back",
    },

    -- ----- CONTEXT MENU (D12 RESOLVED S90) -----------------------------------
    -- X on gamepad, RMB on KBM. Y was considered and permanently rejected
    -- (see GAMEPAD_SPEC D12). Dispatch is handled by the S88 ZeD_ContextMenu
    -- organism via the inputMode parameter.
    context_menu = {
        kbm = "MouseRight",
        gamepad = "X",
    },

    -- ----- D-PAD STRIP MENUS (new §12, S90) ---------------------------------
    -- Quick-access strips dispatched ONLY when no ZeD window has focus.
    -- When a window IS focused, the DPad* buttons route to nav_* above
    -- instead. Focus-state gating happens at dispatch time (Phase 3 concern).
    -- ActionMap just declares the raw bindings flat — the fact that DPadUp
    -- appears on both nav_up and strip_hotbar is intentional and is the
    -- reason fromGamepadButton() returns a list.
    strip_hotbar     = { kbm = nil, gamepad = "DPadUp"    },
    strip_social     = { kbm = nil, gamepad = "DPadDown"  },
    strip_contextual = { kbm = nil, gamepad = "DPadLeft"  },  -- Vehicle OR Animal
    strip_favorites  = { kbm = nil, gamepad = "DPadRight" },  -- content TBD

    -- ----- LIST SORT / VIEW (Oct 23 2026, director: view-only toggles while a
    -- window holds the pad; GAMEPAD_SPEC L3 / R3, Hard Rule #11 as amended) --
    -- Dispatched by FocusManager only for the focused window; never in the
    -- world. L3 steps the sort of the list the pad is on, R3 flips its
    -- container between List and Grid (InventoryRenderer.padSort / padView).
    list_sort = { kbm = nil, gamepad = "LStick" },
    list_view = { kbm = nil, gamepad = "RStick" },

    -- ----- INSPECT (KBM only) ------------------------------------------------
    -- Gamepad reaches Inspect via context_menu (X -> strip -> Inspect cell),
    -- so the gamepad binding is intentionally nil. Keeping the action in the
    -- table so ItemCard's inspect hook can still use ZeD.Input.Action to look
    -- up its KBM binding.
    inspect = {
        kbm = "I",
        gamepad = nil,
    },
}

-- ===========================================================================
-- INTENTIONALLY NOT IN ACTIONMAP (documented here so future sessions don't
-- wonder where these went):
--   * LB / RB (no-focus) — owned by BumperChord (Layer 2, zoom chord) when
--                          NO ZeD window has focus. When a window IS focused,
--                          FocusManager calls Chord.setEnabled(false) and the
--                          bumpers route here as window_prev / window_next above
--                          (S113: swap focus between Char + World pair).
--                          Single physical button, two roles, gated by focus.
--   * LS / RS click  — Hard Rule #11 (no L3/R3 for state-changing ops). Stick
--                      clicks fire too readily under combat tension and the
--                      cost of a phantom press in a zombie crowd is death.
--                      Amended Oct 23 2026: list_sort / list_view above, the
--                      view of a list while a window holds the pad, and nothing else.
--   * next_window /
--     prev_window    — Window ring killed S89. Paired-window semantics now
--                      live in `window_control` (Y) above.
--   * next_tab /
--     prev_tab       — Tab cycling is D-pad up/down AT THE TAB BAR ONLY and
--                      is handled inline by FocusManager when focus is on
--                      the tab bar. Not exposed as a separate logical action.
--   * "secondary" /
--     "tertiary"     — Removed S90. No ZeD-UI surface ever referenced them;
--                      the Y and X buttons they claimed are now allocated to
--                      window_control and context_menu respectively. Their
--                      removal resolved both the Y-double-booking
--                      (secondary vs inspect) and the X-double-booking
--                      (tertiary vs context_menu).
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- GAMEPAD BUTTON -> SPEC-STRING MAP
-- The ActionMap table uses human-readable strings ("A", "DPadUp") while PZ's
-- onJoypadDown(button) dispatch callback delivers a JoypadButton object.
-- This table bridges object -> string.
--
-- Q109 (B42.17): shared/JoyPad/JoyPadSetup.lua aliases every Joypad.*Button
-- name to its corresponding JoypadButton.* object:
--     Joypad.AButton = JoypadButton.A
--     Joypad.LBumper = JoypadButton.LeftBump    (rename trap — see KB)
--     ...
-- Because those are literally the same reference, keying the table by
-- Joypad.* still works: a lookup with a JoypadButton object resolves to the
-- same slot the Joypad.* alias seeded. We keep the Joypad.* keys below for
-- readability, but the table is effectively JoypadButton-keyed post-42.17.
-- Polling moved to JoypadButton.<n>:isDown(id); dispatch callbacks arrive as
-- objects from JoypadButton.fromIndex(n) — see KB Q109 for the full story.
-- ---------------------------------------------------------------------------
local _gpButtonIntToName = {
    [Joypad.AButton]      = "A",
    [Joypad.BButton]      = "B",
    [Joypad.XButton]      = "X",
    [Joypad.YButton]      = "Y",
    [Joypad.LBumper]      = "LB",
    [Joypad.RBumper]      = "RB",
    [Joypad.Back]         = "Back",
    [Joypad.Start]        = "Start",
    [Joypad.LStickButton] = "LStick",
    [Joypad.RStickButton] = "RStick",
    [Joypad.DPadUp]       = "DPadUp",
    [Joypad.DPadDown]     = "DPadDown",
    [Joypad.DPadLeft]     = "DPadLeft",
    [Joypad.DPadRight]    = "DPadRight",
}

-- Reverse of the above — not used at runtime but handy for getBinding's
-- sanity checks and for debug tooling. Tiny table; zero-cost to ship.
local _gpNameToButtonInt = {}
for btnInt, btnName in pairs(_gpButtonIntToName) do
    _gpNameToButtonInt[btnName] = btnInt
end

-- ---------------------------------------------------------------------------
-- KBM KEY-NAME -> KEYCODE MAP
-- KBM bindings in the Action table are spec strings like "Return" or "I".
-- Events.OnKeyPressed hands us a numeric keyCode from Keyboard.KEY_*.
-- This table bridges the two. "MouseRight" is deliberately absent — mouse
-- buttons don't go through the keyboard event pipeline, and the context
-- menu hook routes mouse RMB directly without going through fromKey.
-- ---------------------------------------------------------------------------
local _kbmNameToKeyCode = {
    ["Return"] = Keyboard.KEY_RETURN,
    ["Escape"] = Keyboard.KEY_ESCAPE,
    ["Up"]     = Keyboard.KEY_UP,
    ["Down"]   = Keyboard.KEY_DOWN,
    ["Left"]   = Keyboard.KEY_LEFT,
    ["Right"]  = Keyboard.KEY_RIGHT,
    ["I"]      = Keyboard.KEY_I,
}

-- Reverse map for fromKey lookups (built once, reused on every call).
local _keyCodeToKbmName = {}
for keyName, keyCode in pairs(_kbmNameToKeyCode) do
    _keyCodeToKbmName[keyCode] = keyName
end

-- ---------------------------------------------------------------------------
-- REVERSE-LOOKUP TABLES (BINDING -> ACTION IDS)
-- Built lazily on first call so any edit to ZeD.Input.Actions is picked up
-- if a mod / future phase mutates the table. Keyed by the binding STRING
-- ("A", "DPadUp", "Return"), value is an array of action-id strings so we
-- can return the full list when multiple actions share a button.
-- ---------------------------------------------------------------------------
local _gamepadReverseMap = nil  -- built on first fromGamepadButton
local _kbmReverseMap     = nil  -- built on first fromKey

-- Rebuild reverse maps from the current ZeD.Input.Actions table.
-- Cheap enough to regenerate on demand; kept lazy so a debug console tweak
-- to the table takes effect without module reload.
local function rebuildReverseMaps()
    local gp = {}
    local kb = {}
    for actionId, binding in pairs(ZeD.Input.Actions) do
        if binding.gamepad then
            gp[binding.gamepad] = gp[binding.gamepad] or {}
            table.insert(gp[binding.gamepad], actionId)
        end
        if binding.kbm then
            kb[binding.kbm] = kb[binding.kbm] or {}
            table.insert(kb[binding.kbm], actionId)
        end
    end
    _gamepadReverseMap = gp
    _kbmReverseMap     = kb
end

-- Public: force a rebuild. Consumers that mutate ZeD.Input.Actions at
-- runtime should call this afterwards to invalidate the cached reverse maps.
function Action.rebuild()
    rebuildReverseMaps()
end

-- ---------------------------------------------------------------------------
-- PUBLIC: fromGamepadButton(button)
-- button is either the numeric Joypad.* constant (preferred) OR the spec
-- string ("A", "DPadUp"). Returns a list of action-id strings bound to that
-- button, or nil if unbound (AC-A2: "returns nil for unbound buttons").
--
-- The list shape covers shared-binding cases where one button maps to
-- multiple actions (DPadUp → nav_up AND strip_hotbar). Phase 3 dispatcher
-- picks which one fires based on focus state. For uniquely-bound buttons
-- the list has exactly one element; callers can just index [1].
--
-- Example:
--   fromGamepadButton(Joypad.AButton) -> {"confirm"}
--   fromGamepadButton("DPadUp")       -> {"nav_up", "strip_hotbar"}
--   fromGamepadButton(Joypad.LBumper) -> nil (owned by BumperChord)
-- ---------------------------------------------------------------------------
function Action.fromGamepadButton(button)
    if _gamepadReverseMap == nil then rebuildReverseMaps() end
    -- Normalize the input to a spec-string name. Callers may hand us either
    -- a JoypadButton object (runtime dispatch — type "userdata" post-42.17)
    -- or a spec-string handle ("A", "DPadUp" — debug/binding code).
    --
    -- Q109 (B42.17): pre-42.17 this branch gated on `type(button) ==
    -- "number"` because Joypad.AButton was an integer. Engine now aliases
    -- Joypad.AButton to JoypadButton.A (a Java userdata), so the number
    -- branch never matched and EVERY gamepad dispatch silently dropped
    -- through — no bumpers, no A/B/X/Y, no context menu. The unconditional
    -- table lookup below handles the object case; the string fallback
    -- handles direct spec handles.
    local name = _gpButtonIntToName[button]
    if not name and type(button) == "string" then
        name = button
    end
    if not name then return nil end
    local hit = _gamepadReverseMap[name]
    if not hit then return nil end
    -- Return a shallow copy so callers can mutate without corrupting the map.
    local out = {}
    for i = 1, #hit do out[i] = hit[i] end
    return out
end

-- ---------------------------------------------------------------------------
-- PUBLIC: fromKey(keyCode, mods)
-- keyCode is the numeric Keyboard.KEY_* value from OnKeyPressed events.
-- mods is an optional modifier string (reserved — no current binding uses
-- modifiers, but we keep the API shape so Phase 2+ bindings like "Shift+I"
-- can be added without a signature break).
-- Returns a list of action-id strings, or nil if unbound.
-- ---------------------------------------------------------------------------
function Action.fromKey(keyCode, _mods)
    if _kbmReverseMap == nil then rebuildReverseMaps() end
    if type(keyCode) ~= "number" then return nil end
    local name = _keyCodeToKbmName[keyCode]
    if not name then return nil end
    local hit = _kbmReverseMap[name]
    if not hit then return nil end
    local out = {}
    for i = 1, #hit do out[i] = hit[i] end
    return out
end

-- ---------------------------------------------------------------------------
-- PUBLIC: getBinding(actionId, mode)
-- Returns the raw binding value for a given action and input mode.
--   mode = "kbm"     -> returns the KBM binding string ("Return", "MouseRight") or nil
--   mode = "gamepad" -> returns the gamepad binding string ("A", "DPadUp")    or nil
-- Handy for glyph rendering: "show me the button the player should press for
-- `confirm`" without touching the Actions table directly.
-- ---------------------------------------------------------------------------
function Action.getBinding(actionId, mode)
    local entry = ZeD.Input.Actions[actionId]
    if not entry then return nil end
    if mode == "kbm"     then return entry.kbm     end
    if mode == "gamepad" then return entry.gamepad end
    return nil
end

-- ---------------------------------------------------------------------------
-- PUBLIC: getHoldConfig(actionId)
-- Returns the hold-variant fields for an action, or nil if the action has
-- no hold behavior. FocusManager's hold-timer (Phase 3) consumes this.
-- Shape: { holdMs = <int>, tapAction = <string>, holdAction = <string> }
-- ---------------------------------------------------------------------------
function Action.getHoldConfig(actionId)
    local entry = ZeD.Input.Actions[actionId]
    if not entry or not entry.holdMs then return nil end
    return {
        holdMs     = entry.holdMs,
        tapAction  = entry.tapAction,
        holdAction = entry.holdAction,
    }
end

-- ---------------------------------------------------------------------------
-- BOOTSTRAP — eager reverse-map build, diagnostic line.
-- Eager build is safe: Tokens.lua / Joypad.* / Keyboard.KEY_* are all ready
-- by the time this file is loaded by PZ's client autoloader.
-- ---------------------------------------------------------------------------
rebuildReverseMaps()

-- Count actions for the diagnostic line (pairs() is the only way to count
-- a hash-keyed table in Lua — `#` only works on array-like integer keys).
local _actionCount = 0
for _ in pairs(ZeD.Input.Actions) do _actionCount = _actionCount + 1 end
print(string.format("[ZeD.Input] ActionMap loaded - %d actions registered", _actionCount))
