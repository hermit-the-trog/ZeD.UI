# Session 122 Delta — May 3, 2026

Boot version: `0.1.1210305n` (last commit `88cfc56f` — S121)
Baseline commit: `88cfc56f` — S121 ItemCard organism + EquipmentTab + v15 alignment shipped
Close version: TBD (first S122 commit will bump to `0.1.122<DDMM>c`)

> **Boot mode active.** Ambient capture as decisions land. Custodian flushes to canon at closeout.

## Session target

S122 — Wire B2 (ItemActionManager → real PZ TimedActions) + rename input + 30-cell matrix walk + Q125-Q128 probes + S121 deferred polish.

Primary deliverable: **Progress Band lights up during real cooking / reading / repairing.** Card chrome + body composition is shipped (S121); only the dynamic state-machine layer is missing.

Mockups stay locked S119 — same v13/v15/v16 spec.

## User decisions captured at boot

(populated as work happens)

## Locked decisions

(populated as work happens)

## Rejected approaches

(populated as work happens)

## Engine quirks discovered

(populated as work happens — Q125-Q128 PZ probes expected here)

## Design rules added or updated

(populated as work happens)

## Milestones / shipped work

### Phase B2 — ItemActionManager → real PZ TimedAction observers (DONE — pending live verify)

NEW file `42/media/lua/client/ZeD/ItemActionHooks.lua` (~120 LOC). Hooks `ISBaseTimedAction.start / perform / stop / update` at the BASE class so every TimedAction subclass routes through one set of overrides. Each override:
1. Calls the original method first.
2. Classifies the action via `self.Type` substring (`"cook"` → cooking, `"read"`/`"readab"`/`"readbook"` → reading, `"repair"` → repairing). Class names are stable across PZ patches; field shapes are not.
3. Resolves the affected item via `self.item` / `self.clothing` / `self.book` / `self.weapon` (multi-field probe — TimedAction subclasses store target under different names).
4. Calls `ZeD.ItemActionManager.notify(item, event, {kind, label, percent, timeStr})` with the event mapped to start/tick/complete/cancel.

`update()` ticks the percent via `self:getJobDelta()` (canonical) with fallback to `self.jobTime / self.maxTime`. All notify calls are pcall-guarded — missing fields or unrecognized PZ classes degrade gracefully (Band stays at height=0, no crash).

Hooks install via `Events.OnGameStart` to dodge load-order issues with the vanilla class declaration. Idempotent install flag (`ISBaseTimedAction._zedActionHooksInstalled`) prevents double-wrap on `/lua reload`. File-level inline call after Events registration handles the in-game reload case (`getCore():isInGame()`).

Still missing: cooking-specific danger transition (cooked → burning) — Q127/Q128 probes still pending. The hook fires "tick" with kind="cooking" throughout; mode flips to "danger" require detecting `isCooked() && (... over-cook threshold ...)` which depends on the unprobed getters.

### Phase rename input on _nameRowRect (DONE — pending live verify)

ItemCard.lua gains three rename-state methods (`:_startRename` / `:_commitRename(text)` / `:_cancelRename`) plus a lazy `self._renameInput` child (instance of existing `ZeD_TextInput` molecule). Click the name row → renderBody overlays the input across the row, populated with the item's current name. `onSubmit` (Enter) commits via `item:setName(text); item:setCustomName(true)`. Click outside the input commits with current text. `setItem` cancels any in-progress rename when the displayed item swaps out. Esc handling via the TextInput's own keypress logic. Empty text after trim → cancel without renaming. `_renameInput.setVisible(false)` when not renaming so the child stays alive across re-renders without ghost-rendering on top of the name text.

### Phase B9 partial — Progress Band cancel button click (DONE — pending live verify)

ItemActionHooks.lua now stamps `_action = self` (the raw TimedAction reference) into the descriptor passed to `ItemActionManager.notify` for both "start" and "tick" events. `stampGamepadFields` absolutizes `self._cancelRect` (panel-local from drawProgressBand's outRect → `+ getAbsoluteX/Y`) so the hit test in update() succeeds. `update()` adds cancel-button hover/click detection (mirrors the back-arrow + verb dispatch patterns); on click-release it calls new `ZeD_ItemCard:_dispatchProgressCancel()` which:
1. Reads the active action descriptor via `ItemActionManager.getActiveAction(self.item)`.
2. Prefers `action:forceStop()` (canonical PZ cancel).
3. Falls back to `action:stop()` if forceStop unavailable.
4. Last resort: walks `ISTimedActionQueue.queues[playerNum].queue` and forceStops everything (bigger hammer but explicit-cancel-click justifies it).
5. Defensively calls `notify(item, "cancel")` to clear manager state even if the action's own stop hook doesn't propagate.

**Remaining for B9:** gamepad-X dispatch — needs `_cancelRect` registered as a 4th focusable kind in the gamepad ring's card-zone element list (S99 ring system). Mouse path lands now; gamepad in a follow-up.

### Phase B9 full — gamepad-X cancel registered as ring focusable (DONE)

`ZeD_ItemCard:getActionStripElements()` now prepends a `"cancel_band"` element when `_cancelRect` exists AND `ItemActionManager.getActiveAction(self.item) ~= nil`. The cancel button becomes the FIRST element in the action strip ring while an action is active — gamepad-A on it fires `_dispatchProgressCancel`. `_drawGpFocusOutline` extended with a lookup branch for `id == "cancel_band"` so the focus cue paints on the cancel button too. Element rect derived by subtracting `getAbsoluteX/Y()` from `_cancelRect` (which is stamped absolute for update()'s mouse hit test) — gamepad ring expects panel-local coords.

### Phase legacy-render archive deleted (DONE)

Lines 1283-1624 of ItemCard.lua (the S121 `if false then local function _legacy_render(self) ... end end` archive) deleted. File: 1894 → 1552 LOC. The new organism has been verified across 220w + 480w + EquipmentTab + Char + World drawer surfaces; the legacy reference is no longer needed.

### Phase B2 v2 — switch to OnTick queue polling (DONE)

First B2 draft hooked `ISBaseTimedAction.start/perform/stop/update` at the base class. Live test: Progress Band did NOT appear when reading a book. Root cause: PZ TimedAction subclasses (`ISReadABook`, `ISCookFood`, etc) often override the base methods WITHOUT calling super, so a base-class override is silently bypassed. Many vanilla actions inherit only the slot signature, not behavior.

**Fix:** retired the class-override approach in favor of `Events.OnTick` polling of `ISTimedActionQueue.queues[playerNum].queue`. The head of the queue (`queue[1]`) is the currently-executing action — sniffing it each tick catches every action regardless of subclass override patterns. Per-player `_lastActive` tracking emits a synthetic `complete` event when the head transitions to a different action or the queue empties, so the Manager state stays consistent without requiring stop/perform hooks. Split-screen safe (polls `getNumActivePlayers()`).

Classifier broadened to also match `fix` substring (PZ has `ISFixAction` for non-clothing repair). `_actionItem` adds `self.firearm` probe.

### Phase 480w inline DIRTY/WET chips in ZONES disclosure header (DONE)

renderClothingBody's ZONES disclosure block branches on `compact`:
- **220w (compact):** chevron + `ZONES` + overall % only on the header row, then seg-bar + soil row drawn below when expanded — unchanged.
- **480w (full):** v15-spec inline composition. Header row: `chevron + ZONES` (left), then seg-bar fills the middle, then overall % (right-aligned), then `DIRTY` chip (warning border) and `WET 12%` chip (info border) right-anchored. Chip widths derive from text content (`tm:MeasureStringX(label) + 12`). Right-cursor-walk allocates chips right-to-left; remaining width between label end and % left edge becomes the seg-bar. Soil row below is skipped at 480w to avoid duplicate display. Matches v15 mockup's inline disclosure.

Soil resolved once at the top of the zones block (`buildItemSoil(item)`) and consumed in either the 480w inline path or the 220w soil-row-below path; no double-call.

## Open questions / probes

- **Q125** `getScriptItem():getInsulation()` exists? type? range? per-frame stable?
- **Q126** `getScriptItem():getWindResistance()` — same
- **Q127** Food cooking-time getters — `getCookingTime()` + `isCooked()` + `getCookedTime()` permutations
- **Q128** Burning state path — `isBurnt()` + heat/time threshold
- **Auto-refresh sourceContext after action complete:** hook OnEquip/OnClothingUpdated, OR refresh sourceContext per-frame in card prerender, OR fire updateDrawer from ItemActionManager.notify("complete")?
- **Fira font glyph live-verify:** ASCII placeholders shipped in S121 (`<` back, `*`/`o`/`x` flag chips, `v`/`+`/`x` zone docks, `*` probe star). Designer call: keep ASCII or attempt unicode?

## Mockups touched

(none expected — mockups are spec, not work product)

## Deferred to S123 (if S122 doesn't fit)

- 30-cell matrix walk if B2 + B9 take the whole session
- Legacy `_legacy_render` deletion (no rush)
