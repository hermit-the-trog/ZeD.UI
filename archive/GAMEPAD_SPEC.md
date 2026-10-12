# GAMEPAD_SPEC

**Status:** LOCKED — ring model (S97 pivot, S98 wiring complete)
**Implements:** Flat-ring focus navigation across both ZeD windows. LB/RB cycle zones; D-pad does spatial nav within the focused zone; A confirms; X opens context menu; right stick magnitude escapes to gameplay.
**Supersedes:** S89-locked stack model (`pushContext` / `popContext` / `max depth 3`). The stack API was removed in S98 after both windows opted into the ring.
**Source design:** `S94_GAMEPAD_RING_NAVIGATION_SPEC.md` (April 16, 2026 design pivot — Downloads, not in tree).
**Audit reference:** `GAMEPAD_AUDIT.md` — 127 interactables catalogued with proposed ring zones per window.

---

## §1. Overview & Rationale

### What the ring model is

Each ZeD window owns a flat ordered list of focusable zones (`win._focusRing`). The user navigates between zones with the bumpers (LB previous / RB next, wrapping), and within the active zone with the D-pad (spatial cone nav). The A button confirms a zone-dependent action; X opens a context menu on the focused element. Right-stick escape and B/Y window controls are global.

```
LB -----[ tabBar ]----- RB ----[ containerStrip ]---- RB ----[ tabContent ]---- RB ----[ equipDrawer ]----- wraps
            ^                          ^                            ^                            ^
          D-pad                      D-pad                        D-pad                        D-pad
        (within zone)              (within zone)                (within zone)                (within zone)
```

### Why ring over stack

The stack model (S89-S96) required users to think in terms of nested context: enter a tab, enter a panel, enter inventory rows, press B repeatedly to back out. Each level was its own focus frame. Mental model overhead grew with depth. Stack mutations during async UI updates (container rebuilds, tab switches) required pop-helper functions to keep frames consistent.

The ring model treats the window as a flat space with named regions. There are no levels, no nesting, no depth counter. To get to the inventory rows, press RB twice from tabBar. To get back, press LB twice. Mutations are local — `setRingZoneElements` swaps a zone's element array without disturbing other zones. There is no concept of "the wrong frame is on top."

### Cycle order matters

Zone order in `_focusRing` is the LB/RB cycle order. Bumpers skip zones with `focusable = false`, wrapping around. Order should reflect the natural reading flow of the window: tab selector first, secondary controls next, primary content last. See §6 for the per-window order.

### Locked decisions

1. **Zone granularity.** One zone per tab's primary content cluster, plus tabBar plus drawer-like zones that toggle focusable. Not one-zone-per-element-cluster (too granular) and not one-zone-per-tab (too coarse).
2. **A on tabBar at a different tab.** Switches the active tab; focus stays on the tabBar zone. No auto-jump into the new tab's content. User must press RB to enter content.
3. **Closed drawer behavior.** `setZoneFocusable(false)` keeps the zone in the ring array but excludes it from cycle. Re-expand toggles the flag back. No mid-session ring mutation.
4. **moodleBar wiring.** Deferred to S99+. Reserved as a future ring slot in both windows.

---

## §2. ActionMap Reference

Source of truth: `42/media/lua/client/ZeD/Input/ActionMap.lua`.

Bindings the ring consumes via `Action.fromGamepadButton(button)` lookup:

| Action | Gamepad | KBM | Hold semantics |
|---|---|---|---|
| `confirm` | A | Return | — |
| `cancel` | B | Escape | tap = `shade_all`, hold (≥400ms) = `close_all` |
| `nav_up` / `nav_down` / `nav_left` / `nav_right` | D-pad | Up/Down/Left/Right | — |
| `zone_prev` | LB | — | — |
| `zone_next` | RB | — | — |
| `window_control` | Y | — | tap = `open_or_cycle`, hold (≥400ms) = `shade_focused` |
| `layout_mode` | Back | — | — |
| `context_menu` | X | MouseRight | — |
| `strip_hotbar` / `strip_social` / `strip_contextual` / `strip_favorites` | D-pad | — | only when no window focused |
| `inspect` | — | I | — |

### Bumper dual role

LB and RB serve two roles based on focus state. When **no ZeD window is focused**, BumperChord owns them (camera zoom chord — `LB+RB` zooms in, etc.). When **a ZeD window IS focused**, FocusManager calls `Chord.setEnabled(false)` and the bumpers route to `zone_prev` / `zone_next`. On `releaseFocus`, the chord is re-enabled. Single physical button, two roles, gated by focus.

### D-pad dual role

D-pad directions appear on both `nav_*` (spatial nav within the focused zone) and `strip_*` (quick-access strip menus when no window is focused). FocusManager dispatch checks focus state before routing.

### Stick escape

The right stick's squared magnitude is sampled per tick. When it exceeds `T.gp.aimingThresholdSq` (default `0.81`, ≈ 90% deflection) AND a window is focused AND not within the 600ms `WS_GRACE_MS` claim window AND shade-lock is off, FocusManager shades all registered windows and releases focus. The thresholds are token-tunable at runtime: `ZeD.T.gp.aimingThresholdSq = 0.64` (≈ 80%) for a more relaxed escape.

---

## §3. FocusManager API

Source of truth: `42/media/lua/client/ZeD/Input/FocusManager.lua`. All exports are functions on the `Focus` namespace (`ZeD.Input.Focus`).

### Window lifecycle

```lua
Focus.registerWindow(w)        -- add to registry; idempotent
Focus.unregisterWindow(w)      -- remove; atomic focus transfer to next survivor
Focus.claimFocus(w)            -- claim focus; sets engine joypad focus, disables BumperChord, arms 600ms grace
Focus.releaseFocus()           -- release focus globally; re-enables BumperChord
Focus.getFocusedWindow()       -- → w | nil
Focus.isLocked()               -- → bool (Y-hold shade lock)
```

### Ring inspection

```lua
Focus.getFocusedZone(w)        -- → zone table | nil
Focus.getFocusedElement(w)     -- → element table | nil
```

### Ring mutation

```lua
Focus.setRingZoneElements(w, zoneRef, elements, preserveIdx?)
    -- zoneRef: numeric index into _focusRing OR zone.zone string name
    -- elements: array of element tables (may be empty)
    -- preserveIdx: numeric 1-based (clamped). Pass nil to preserve old idx clamped.

Focus.setZoneFocusable(w, zoneRef, flag)
    -- Toggle the zone's focusable flag. If disabling the currently-focused
    -- zone, _focusIdx auto-rotates forward to the next focusable zone (wraps).
    -- All zones non-focusable → silent no-op on subsequent LB/RB presses.
```

### Dispatch

```lua
Focus.dispatchJoypadDown(w, button, joypadData)
    -- Entry point for A/B/X/Y/LB/RB presses. Maps button → action ID via
    -- ActionMap; A→onActivate, X→onContextMenu, LB/RB→zone cycle, B/Y→hold timer.

Focus.dispatchJoypadDir(w, dir, joypadData)
    -- Entry point for D-pad presses. Triggers spatial nav within current zone.
    -- 'dir' is "up" | "down" | "left" | "right".
```

### Engine focus restore

```lua
Focus.reclaimEngineFocus()
    -- Re-pushes setJoypadFocus(0, focusedWindow) without changing internal state.
    -- Used by ZeD_ContextMenu close path so engine focus snaps back to the
    -- window after the menu closes.
```

### What's gone

`pushContext`, `popContext`, `replaceContext`, `setFocusableElements`, `getFocusDepth`, `getTopFrame` — all removed in S98 after both windows migrated. Any call to them is a Lua error (no longer stubbed).

---

## §4. Zone Shape & Element Shape

### Zone

```lua
{
    zone = "tabBar",                   -- string name; used by zoneRef lookup
    focusable = true,                  -- bool; LB/RB skip when false
    elements = { <element>, ... },     -- array
    focusedElementIdx = 1,             -- 1-based; clamped on element changes
    renderFn = function(w, zone)       -- optional; fires when bumper LANDS on
        -- chrome refresh hooks       -- this zone (not on every tick)
    end,
}
```

### Element

```lua
{
    x = 0, y = 0, w = 0, h = 0,        -- screen-absolute bounds for cone nav.
                                        -- 1-element zones: bounds may be zeros.
                                        -- Multi-element zones: must be real for
                                        -- the cone algorithm to work.
    id = "tabBar:loot",                -- string; diagnostic only
    onActivate    = function(w, el) end,  -- A button
    onContextMenu = function(w, el) end,  -- X button
    onFocus       = function(w, el) end,  -- D-pad lands here (visual cursor seed)
}
```

### Spatial nav cone

When D-pad fires within a multi-element zone, FocusManager iterates `zone.elements`, computes element centers, and picks the cheapest candidate within a 90° cone in the requested direction:

```
cost = |dominant-axis displacement| + 2 * |off-axis displacement|
qualifier: |off-axis| ≤ |dominant-axis|  (90° cone)
no-wrap: nil result → silent no-op
```

A 2× off-axis weight biases toward axis-aligned moves. No wraparound — pressing D-pad up from the topmost element does nothing.

### Hold-to-repeat

D-pad hold for 250ms (initial) then every 120ms (repeat) re-fires `_handleSpatialNav` on the current direction. Tunable via `T.gp.holdInitMs` and `T.gp.holdRepeatMs`.

---

## §5. Window Contract

Both `ZeD_CharacterWindow` and `ZeD_WorldWindow` derive from `ZeD_Window` (which derives from `ISPanel`, NOT from `ZeD_Panel` — see Q86). The contract is:

### Required fields

```lua
w._focusRing = { <zone>, <zone>, ... }   -- set BEFORE claimFocus
w._focusIdx  = 1                         -- starting zone index (1-based)
w._zedLabel  = "Character"               -- string; stable diagnostic label for logs
```

### Required dispatch shims (already on ZeD_Window via Organisms.lua)

```lua
function ZeD_Window:onJoypadDown(button, joypadData)
    if ZeD.Input and ZeD.Input.Focus then
        ZeD.Input.Focus.dispatchJoypadDown(self, button, joypadData)
    end
end

function ZeD_Window:onJoypadDirUp(joypadData)    -- and Down/Left/Right variants
    if ZeD.Input and ZeD.Input.Focus then
        ZeD.Input.Focus.dispatchJoypadDir(self, "up", joypadData)
    end
end
```

These are defined once in `Organisms.lua` (lines 758–789) and inherited by every ZeD_Window subclass. ZeD_Panel mirrors them (lines 148–179) for the same dispatch surface on its derivatives (`ZeD_ContextMenu`).

### Optional window hook

```lua
function w:onFocusZoneChanged(delta)   -- delta = { new = newZone, old = oldZone }
    -- chrome refresh, sound effects, etc.
end
```

Fires once per LB/RB landing. Not used in S98 (chrome reads UI state directly), but the hook is available for future panels.

### Lifecycle order

```lua
-- Window open:
Focus.registerWindow(w)
w._focusRing = { ... }      -- build the ring
w._focusIdx  = 1
Focus.claimFocus(w)         -- triggers engine focus, disables BumperChord, arms grace

-- Window close:
Focus.unregisterWindow(w)   -- internally calls releaseFocus if w held focus
```

`registerWindow` MUST come before assigning `_focusRing`. `claimFocus` MUST come after `_focusRing` is populated, otherwise the first dispatch fires on an empty ring and no-ops.

---

## §6. Per-Window Zone Breakdown

### Character Window — 4 zones

```
ring[1] charTabBar          focusable=true always           7 tab elements
ring[2] charContainerStrip  focusable=true on Loot tab      container buttons
ring[3] charTabContent      focusable=true if #els>0        per-tab elements
ring[4] charEquipDrawer     focusable=true on Equip tab     1 element (defense disclosure)
                                          AND _equipDefenseExpanded
```

`charTabContent` element source per active tab:
- **loot** → `_buildInvRowFocusables(win)` (inventory rows of active container)
- **equip** → `_buildEquipmentFocusables(win)` (filled slots only)
- **health** → `_buildHealthFocusables(win)` (exercise buttons)
- **thermal** → `_buildThermalFocusables(win)` (view-mode pills)
- **skills** → `_buildSkillsFocusables(win)` (skill rows)
- **identity, journal** → `{}` → setZoneFocusable("charTabContent", false)

### World Window — 4 zones

```
ring[1] worldTabBar          focusable=true always              tab elements (visibility-filtered)
ring[2] worldContainerStrip  focusable=true on Loot tab         container buttons
ring[3] worldTabContent      focusable=true if #els>0           per-tab elements
ring[4] worldLootMCColumns   focusable=true on Loot+MC active   MC columns (S99 stub — currently empty)
```

`worldTabContent` element source per active tab:
- **loot** → `_buildWorldInvRowFocusables(win)` (inventory rows of active container)
- **forage** → `_buildForageFocusables(win)` (stance toggle)
- **animals** → `_buildAnimalsFocusables(win)` (submode tabs)
- **craft, build, maps** → `{}` → setZoneFocusable("worldTabContent", false) (S99+ wiring)

### Future zones (deferred to S99+)

- **moodleBar** (Character window, shared across tabs) — title-bar moodle icons
- **worldLootMCColumns** real elements (currently stub returning `{}`)
- Per-tab deeper navigation: Health injury list, Skills training materials, Foraging categories/modifiers grid, Animals roster rows, Maps canvas/tools, Journal sub-tabs, Identity traits read-only
- Craft/Build recipe rows (the largest remaining unwired surface — 40+ elements per tab)

---

## §7. Acceptance Criteria (live QA)

These are the verification gates for any session that touches the ring. Each AC is a single user action with a binary pass criterion. Run on real hardware with a controller connected.

| AC | Action | Pass criterion |
|---|---|---|
| **F1** focus claim indicator | Open window with Y-tap (gamepad) or `I` key. | Visual focus on `tabBar` (active tab highlighted via existing chrome). |
| **F2** D-pad switches tab live on tabBar | Bump to tabBar zone. D-pad up/down across tabs. | Active tab switches live on each D-pad press. A is NOT used for zone activation. |
| **F3** D-pad spatial nav within zone | RB to a content zone with 2+ elements. D-pad up/down/left/right. | Focus moves cleanly within zone; never crosses zone boundary on D-pad. |
| **F4** D-pad hold-to-repeat | Hold D-pad in any direction. | After ~250ms, focus auto-advances every ~120ms. |
| **F5** LB cycles to prev zone | From any non-first zone, press LB. | Lands on previous focusable zone; skips non-focusable. |
| **F6** RB cycles to next zone | From any non-last zone, press RB. | Lands on next focusable zone; skips non-focusable. |
| **F7** Ring wraps both directions | Press RB from last focusable zone. Press LB from first. | Wraps both directions cleanly. |
| **F8** Closed drawer skipped | Equipment tab, defense drawer expanded. RB to equipDrawer. Mouse-collapse drawer. RB cycle. | Cycle skips equipDrawer. Re-expand → reachable again. |
| **F9** X opens context menu | Focus an inventory row in Loot tab, press X. | ZeD_ContextMenu opens at gamepad dock (bottom-center). |
| **F10** Right stick aim escape | Window focused, push right stick fully right. | Window shades; focus releases; aim cursor active in-game. (Wait 600ms after open if just claimed — grace window.) |
| **F11** Windowshade preserves ring state | After F10, press Y-tap. | Window restores. LB/RB resumes from same zone as before F10. |

Run the full sweep across BOTH windows. Document any failure inline; fix before re-running.

---

## §8. Engine Quirks (inline reference)

These are quirks discovered during S91-S98 ring/stack development. Full entries with reproductions live in `PZAPI-KNOWLEDGE-BANK.md`.

### Q86 — `ZeD_Window` does NOT derive from `ZeD_Panel`

Both classes derive from `ISPanel` independently. Any "ZeD UI surface contract" method (joypad shims, future lifecycle hooks) must be duplicated on both, or `ZeD_Window` must be refactored to `ZeD_Panel:derive(...)`. The S98 ring shims live on both; no work needed for new windows that derive from `ZeD_Window`.

### Q87 — `setJoypadFocus(playerID, control)` is mandatory

PZ engine dispatches `joypadData.focus:onJoypadDown(button, joypadData)`. Internal Lua state tracking ("my window has focus") is invisible to the engine unless `setJoypadFocus(0, w)` is called. FocusManager calls it from `claimFocus` (push), `releaseFocus` (clear), and `unregisterWindow` (transfer to survivor or clear). Player ID is hardcoded to 0; split-screen will need per-window `playerNum` threading.

### Q88 — `ISButtonPrompt:onYPress` override

Vanilla gamepad Y-press routes through `ISButtonPrompt.onYPress` which calls `cmdShowInventory` (cached function reference). Overriding `cmdShowInventory` does NOT take effect because the prompt cached the OLD reference. Override `ISButtonPrompt.onYPress = function(self) end` directly on the class table — method lookup is live.

### Q89 — `joypadData.controller` is a Lua table, not a numeric index

`getControllerAxisValue(ctlIdx, axisIdx)` expects integers. `joypadData.controller` is a `JoypadControllerData` table — passing it crashes. Iterate via `getControllerCount()` and use the integer index directly.

### Q90 — `math.abs()` on trigger axis is wrong

Some Xbox/PS drivers report trigger axes in `[-1, 1]` (rest = -1, pulled = +1). `math.abs(-1) = 1` reads as "always pulled" at rest. Pull detection: just `lt > threshold` (works on both `[0,1]` and `[-1,1]` driver conventions). Stick magnitude (`sqrt(x²+y²)`) is unaffected.

### Q91 — Java items reject arbitrary Lua field assignment

`item._zedRenderY = y` crashes with "attempted index of non-table". Java objects work as table KEYS for identity-based lookup but NOT as Lua-table-style field-write targets. Use a Lua-side map: `local map = {}; map[item] = y`. Inventory row Y coords use this pattern (`_itemRenderYMap`).

### Q53 — Drawer `_drawerEffW` must animate, never instant-set

Setting `_drawerEffW = targetW` directly causes a single-frame width delta that PZ's anchor system mishandles. Always let the per-frame animation lerp toward `targetW` via `DRAWER_PX_SPEED * dt`. Drawer-related ring focusability toggles (e.g., `setZoneFocusable("charEquipDrawer", _equipDefenseExpanded)`) are LOGICAL state flips — safe to call once per click; they don't interact with the animated width.

### Common mistake #16 — forward-local

Lua locals are visible only AFTER their declaration line. Functions defined before a `local x = ...` line can't capture `x` in their closure (resolves to global, usually nil). Pattern: forward-declare with `local x` near the top, then `x = function ... end` later. Both windows use this pattern for `_buildPanelFocusables`, `_buildLootFocusables`, `_clearGpFocusState`, `_syncRingZonesToActiveTab` (Character) / `_syncWorldRingZones` (World).

---

## §9. Implementation Files

| File | Purpose |
|---|---|
| `42/media/lua/client/ZeD/Input/FocusManager.lua` | Ring state machine, dispatch, cone nav, hold-to-repeat, aim escape, BumperChord integration |
| `42/media/lua/client/ZeD/Input/ActionMap.lua` | Action bindings (gamepad ↔ KBM); reverse-lookup tables |
| `42/media/lua/client/ZeD/Input/InputModeDetector.lua` | Mouse/KBM vs gamepad mode detection (used by glyph rendering, not by FocusManager directly) |
| `42/media/lua/client/ZeD/Input/BumperChord.lua` | LB+RB zoom chord (disabled while a ZeD window is focused) |
| `42/media/lua/client/ZeD/Organisms.lua` | `ZeD_Window` base class + dispatch shims |
| `42/media/lua/client/ZeD/ZeD_Panel.lua` | `ZeD_Panel` base class + dispatch shims (mirror of Window's) |
| `42/media/lua/client/ZeD/ZeD_CharacterWindow.lua` | Character window ring construction (4 zones) |
| `42/media/lua/client/ZeD/ZeD_WorldWindow.lua` | World window ring construction (4 zones) |
| `42/media/lua/client/ZeD/ZeD_ContextMenu.lua` | Context menu organism with its own joypad shims (D-pad up/down through items, A to confirm, B to close → reclaimEngineFocus) |
| `42/media/lua/shared/ZeD/Tokens.lua` | `T.gp.*` tunables (`stickThresh`, `triggerThresh`, `cooldownMs`, `aimingThresholdSq`, `holdInitMs`, `holdRepeatMs`) |

---

## §10. Out-of-Scope (deferred to S99+)

- moodleBar wiring (build helper, title-bar render hook, focus chrome)
- worldLootMCColumns real elements (S98 ships a `{}` stub)
- Craft/Build recipe rows (40+ unwired elements per tab — largest remaining surface)
- Maps interactive canvas (Q44/Q45 in play — `UIWorldMap` rendering quirks)
- Health injury list deeper interaction (~20 unwired)
- Skills training materials disclosure (10–30 unwired)
- Foraging categories/modifiers grid (12+ unwired)
- Animals roster rows + butcher actions (15+ unwired)
- Journal sub-tabs + entries (5–15 unwired)
- Identity traits (read-only — may stay deferred indefinitely)
- Hold-A double-click equivalent (per-component semantics — still TBD)
- Y-hold "always-show" lock state visual (no design yet)
- Split-screen `playerNum` threading through `setJoypadFocus`
