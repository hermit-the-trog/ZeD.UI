-- ZeD-UI/42/media/lua/client/ZeD/Input/ActionMap.lua
-- ============================================================================
-- ACTION MAP — every pad button and key as a named action, in one table.
-- Client. The lookup floor of the controller stack: UI code asks "what action
-- is this button?", never "is this the A button?", so a future rebinding
-- screen touches this file alone and components never change. FocusManager's
-- dispatchJoypadDown is the one caller today (fromGamepadButton); fromKey,
-- getBinding and getHoldConfig are public but wait for callers.
--
-- Public interface:
--   ZeD.Input.Action.fromGamepadButton(button)   -> {actionId, ...} | nil
--   ZeD.Input.Action.fromKey(keyCode, mods)      -> {actionId, ...} | nil
--   ZeD.Input.Action.getBinding(actionId, mode)  -> binding value | nil
--   ZeD.Input.Action.getHoldConfig(actionId)     -> hold fields | nil
--
-- Notes on the return shape:
--   fromGamepadButton and fromKey return LISTS because some buttons are
--   shared (DPad directions serve both nav_* and strip_*). The caller —
--   FocusManager — disambiguates by current focus state. For uniquely-bound
--   buttons (A, B, X, Y, Back) the list has exactly one element; callers can
--   just index [1].
-- ============================================================================

-- Namespace setup. Matches the shape InputModeDetector establishes;
-- reload-safe, and the guards let the Input/ files load in any order.
ZeD = ZeD or {}
ZeD.Input = ZeD.Input or {}
ZeD.Input.Action = ZeD.Input.Action or {}

local Action = ZeD.Input.Action

-- ---------------------------------------------------------------------------
-- ACTION TABLE — the source of truth. Every binding flows from here.
--
-- Shape of each entry:
--   { kbm = <keyName|"MouseRight"|nil>, gamepad = <buttonName|nil>,
--     holdMs = <int>?, tapAction = <string>?, holdAction = <string>? }
--
-- Hold semantics (only window_control carries them today):
--   holdMs      — threshold in ms
--   tapAction   — fires on release BEFORE threshold; the string is informational
--   holdAction  — fires once AT threshold with the button still down
-- FocusManager keeps its own hold timers and thresholds; nothing reads these
-- fields yet (getHoldConfig serves them when something does).
-- ---------------------------------------------------------------------------
ZeD.Input.Actions = {
    -- ----- NAVIGATION (universal) --------------------------------------------
    confirm = {
        kbm = "Return",
        gamepad = "A",
    },

    -- `cancel` is purely contextual — it fires the focused element's onCancel
    -- if defined, else NO-OP. No shade-all fallback, no hold variant; closing
    -- the window pair is Y-hold's job.
    cancel = {
        kbm = "Escape",
        gamepad = "B",
    },

    -- D-pad = flat spatial nav (SpatialNav) across ALL focusable zones in the
    -- focused window. Bumpers do not cycle zones; they pick one of the two
    -- paired windows. The engine fires a direction callback as well as the
    -- button for one D-pad press; FocusManager moves on the direction and
    -- ignores these ids, or every press would step twice.
    nav_up    = { kbm = "Up",    gamepad = "DPadUp"    },
    nav_down  = { kbm = "Down",  gamepad = "DPadDown"  },
    nav_left  = { kbm = "Left",  gamepad = "DPadLeft"  },
    nav_right = { kbm = "Right", gamepad = "DPadRight" },

    -- ----- WINDOW SELECT ----------------------------------------------------
    -- LB = Character, RB = World (absolute — pressing LB while already on
    -- Character is a no-op, not a toggle). Always-paired on gamepad so the
    -- target window is guaranteed to exist. Only dispatched while a ZeD window
    -- is focused; BumperChord is disabled during focus so LB/RB route here.
    -- When no window is focused, BumperChord reclaims bumpers for zoom chord.
    -- The names date from an older symmetric prev/next toggle semantic and
    -- stay for reverse-map continuity.
    window_prev = { kbm = nil, gamepad = "LB" },  -- LB → Character
    window_next = { kbm = nil, gamepad = "RB" },  -- RB → World

    -- ----- WINDOW CONTROL (paired semantics) ---------------------------------
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
    -- Reserved: a modal layout-edit toggle on the focused window. Nothing
    -- dispatches it yet. KBM has no binding; layout editing is a gamepad UX.
    layout_mode = {
        kbm = nil,
        gamepad = "Back",
    },

    -- ----- CONTEXT MENU ------------------------------------------------------
    -- X on gamepad, RMB on KBM. Y was weighed for this and rejected for good —
    -- Y is the pair control. FocusManager fires the focused element's
    -- onContextMenu or onReset (tap) and its hold hooks (hold: a drag, or a
    -- one-shot quick use).
    context_menu = {
        kbm = "MouseRight",
        gamepad = "X",
    },

    -- ----- D-PAD STRIP MENUS -------------------------------------------------
    -- Quick-access strips meant to fire ONLY when no ZeD window has focus;
    -- when a window IS focused, the DPad* buttons route to nav_* above
    -- instead. The bindings are declared flat — DPadUp on both nav_up and
    -- strip_hotbar is deliberate, and is the reason fromGamepadButton()
    -- returns a list. No dispatcher reads the strip ids yet; the D-pad wheels
    -- (ZeD_DpadWheels) cover the no-focus D-pad today without this table.
    -- strip_contextual was sketched as Vehicle-or-Animal; strip_favorites'
    -- content was never settled.
    strip_hotbar     = { kbm = nil, gamepad = "DPadUp"    },
    strip_social     = { kbm = nil, gamepad = "DPadDown"  },
    strip_contextual = { kbm = nil, gamepad = "DPadLeft"  },
    strip_favorites  = { kbm = nil, gamepad = "DPadRight" },

    -- ----- LIST SORT / VIEW (L3 / R3) ----------------------------------------
    -- Stick clicks misfire under combat tension, so they carry view-only jobs
    -- and nothing else (see the LS / RS note below). Dispatched by
    -- FocusManager only for the focused window; never in the world. L3 steps
    -- the sort of the list the pad is on, R3 flips its container between List
    -- and Grid (InventoryRenderer.padSort / padView).
    list_sort = { kbm = nil, gamepad = "LStick" },
    list_view = { kbm = nil, gamepad = "RStick" },

    -- ----- INSPECT (KBM only) ------------------------------------------------
    -- Declared for a keyboard inspect key; the gamepad binding is nil on
    -- purpose. Nothing reads it yet — it sits here so the KBM binding has
    -- one home when an inspect hook arrives.
    inspect = {
        kbm = "I",
        gamepad = nil,
    },
}

-- ===========================================================================
-- INTENTIONALLY NOT IN ACTIONMAP (documented so a reader doesn't wonder
-- where these went):
--   * LB / RB (no-focus) — owned by BumperChord (the zoom chord) when
--                          NO ZeD window has focus. When a window IS focused,
--                          FocusManager calls Chord.setEnabled(false) and the
--                          bumpers route here as window_prev / window_next above
--                          (LB the Character window, RB the World window).
--                          Single physical button, two roles, gated by focus.
--   * LS / RS click  — no state-changing jobs on stick clicks. They fire too
--                      readily under combat tension and the cost of a phantom
--                      press in a zombie crowd is death. The one amendment is
--                      list_sort / list_view above — the view of a list while
--                      a window holds the pad, and nothing else.
--   * next_window /
--     prev_window    — the old window-cycling ring is gone. Paired-window
--                      semantics live in `window_control` (Y) above.
--   * next_tab /
--     prev_tab       — tabs are controls like any other: D-pad up/down walk
--                      the tab column, A opens the focused tab, and a move
--                      into the column lands on the active tab (FocusManager).
--                      Not exposed as a separate logical action.
--   * "secondary" /
--     "tertiary"     — removed: no ZeD-UI surface ever referenced them, and
--                      the Y and X buttons they claimed went to
--                      window_control and context_menu. Their removal ended
--                      Y and X each being double-booked.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- GAMEPAD BUTTON -> SPEC-STRING MAP
-- The Actions table uses human-readable strings ("A", "DPadUp") while PZ's
-- onJoypadDown(button) dispatch callback delivers a JoypadButton object.
-- This table bridges object -> string.
--
-- B42.17: shared/JoyPad/JoyPadSetup.lua aliases every Joypad.*Button name to
-- its corresponding JoypadButton.* object:
--     Joypad.AButton = JoypadButton.A
--     Joypad.LBumper = JoypadButton.LeftBump    (rename trap — not "LBump")
--     ...
-- Because those are literally the same reference, keying the table by
-- Joypad.* still works: a lookup with a JoypadButton object resolves to the
-- same slot the Joypad.* alias seeded. We keep the Joypad.* keys below for
-- readability, but the table is effectively JoypadButton-keyed post-42.17.
-- Polling moved to JoypadButton.<n>:isDown(id); dispatch callbacks arrive as
-- objects from JoypadButton.fromIndex(n).
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

-- Reverse of the above. Nothing reads it yet — kept for debug tooling.
-- Tiny table; zero-cost to ship.
local _gpNameToButtonInt = {}
for btnInt, btnName in pairs(_gpButtonIntToName) do
    _gpNameToButtonInt[btnName] = btnInt
end

-- ---------------------------------------------------------------------------
-- KBM KEY-NAME -> KEYCODE MAP
-- KBM bindings in the Action table are spec strings like "Return" or "I".
-- Events.OnKeyPressed hands us a numeric keyCode from Keyboard.KEY_*.
-- This table bridges the two. "MouseRight" is deliberately absent — mouse
-- buttons don't go through the keyboard event pipeline, so RMB never passes
-- through fromKey.
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
-- if a mod / console tweak mutates the table. Keyed by the binding STRING
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

--- Force a rebuild. Anything that mutates ZeD.Input.Actions at runtime
--- should call this afterwards to invalidate the cached reverse maps.
function Action.rebuild()
    rebuildReverseMaps()
end

--- The action ids bound to a gamepad button, or nil if unbound. `button` is
--- either the Joypad.* constant (runtime dispatch) or the spec string
--- ("A", "DPadUp" — debug/binding code). A list comes back because one
--- button can map to several actions (DPadUp → nav_up AND strip_hotbar);
--- the dispatcher picks which fires by focus state. Uniquely-bound buttons
--- give a one-element list; callers can just index [1].
---
--- Example:
---   fromGamepadButton(Joypad.AButton) -> {"confirm"}
---   fromGamepadButton("DPadUp")       -> {"nav_up", "strip_hotbar"}
---   fromGamepadButton(Joypad.Start)   -> nil (unbound)
function Action.fromGamepadButton(button)
    if _gamepadReverseMap == nil then rebuildReverseMaps() end
    -- Normalize the input to a spec-string name. Callers may hand us either
    -- a JoypadButton object (runtime dispatch — type "userdata" post-42.17)
    -- or a spec-string handle ("A", "DPadUp" — debug/binding code).
    --
    -- B42.17 trap: pre-42.17 this branch gated on `type(button) == "number"`
    -- because Joypad.AButton was an integer. The engine now aliases
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

--- The action ids bound to a keyboard key, or nil if unbound. keyCode is the
--- numeric Keyboard.KEY_* value from OnKeyPressed events. mods is reserved —
--- no binding uses modifiers yet, but the signature keeps room so bindings
--- like "Shift+I" can arrive without a break.
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

--- The raw binding value for an action in one input mode, or nil.
---   mode = "kbm"     -> the KBM binding string ("Return", "MouseRight") or nil
---   mode = "gamepad" -> the gamepad binding string ("A", "DPadUp")       or nil
--- Handy for glyph rendering: "show me the button the player should press
--- for `confirm`" without touching the Actions table directly.
function Action.getBinding(actionId, mode)
    local entry = ZeD.Input.Actions[actionId]
    if not entry then return nil end
    if mode == "kbm"     then return entry.kbm     end
    if mode == "gamepad" then return entry.gamepad end
    return nil
end

--- The hold-variant fields for an action, or nil if the action has no hold
--- behavior. Shape: { holdMs = <int>, tapAction = <string>, holdAction = <string> }
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
-- Eager build is safe: Joypad.* and Keyboard.KEY_* are all ready by the time
-- this file is loaded by PZ's client autoloader.
-- ---------------------------------------------------------------------------
rebuildReverseMaps()

-- Count actions for the diagnostic line (pairs() is the only way to count
-- a hash-keyed table in Lua — `#` only works on array-like integer keys).
local _actionCount = 0
for _ in pairs(ZeD.Input.Actions) do _actionCount = _actionCount + 1 end
print(string.format("[ZeD.Input] ActionMap loaded - %d actions registered", _actionCount))
