# Next Session Handoff
Generated: May 3, 2026 — Session 122 closing, S123 booting.

## Target
**S123 — verification + danger states + context menu fix + carryover polish.** S121-S122 shipped the full ItemCard chrome + dynamic state layer (Progress Band lights up during real reading/cooking/repairing, mouse + gamepad cancel works, rename input on name row, 480w inline DIRTY/WET chips in ZONES disclosure). What's left:

1. **30-cell test matrix walk** (5 types × 2 widths × 3 states) — primary verification.
2. **Q125-Q128 PZ probes** → PZAPI-KB entries (insulation / wind / cooking-time / burning-state).
3. **Cooking → burning danger transition** in the Progress Band (depends on Q127/Q128).
4. **Context menu mispositioning** regression — was spawned as a side task, should be addressed.
5. **Auto-refresh sourceContext** after action complete (verb cluster currently flips only on next manual selection).

## Current state
Version `0.1.1220305j`. S122 commit shipped the dynamic state layer atop S121's static chrome. Reading the comic in the in-game test session triggered the Progress Band correctly via the IsoPlayer:isReading() + inventory-scan fallback path (the canonical `ISTimedActionQueue` head poll missed because Build 42's read action queues with empty Lua-side fields — Java userdata behavior).

`ItemActionHooks.lua` has TWO parallel paths:
- **Queue polling:** OnTick scan of `ISTimedActionQueue.queues[pn].queue[1]` with multi-strategy classifier. Used for cooking + repairing (and any future TimedAction with proper Lua fields).
- **isReading fallback:** OnTick scan of `IsoPlayer:isReading()` + inventory-scan for Literature items, ranked unique → carded → highest-already-read-pages. Used because the read action's Lua fields don't survive the queue.

The fallback's robustness is unverified for cooking + repairing — those actions might need similar fallbacks if their fields are also empty. Investigate during the 30-cell matrix walk.

## Spec sources (READ FIRST every S123 boot)
- `ZeDUI/mockups/equipment_card_redesign_v13_refinements.html`
- `ZeDUI/mockups/equipment_card_redesign_v15_both_widths.html`
- `ZeDUI/mockups/equipment_card_redesign_v16_progress_states.html` — danger transition spec for cooking → burning.

## Open decisions
- **Q125-Q128 PZ probes** — finally land them at the start of S123 to unblock danger transitions in the Progress Band and ★ probe-badge resolution in Defense Facts.
- **Cancel via fallback path** — when book is resolved via inventory-scan, the descriptor's `_action` is nil. Cancel falls through to per-queue forceStop (works but bigger hammer). Need to backfill the action ref by hooking ISReadABook directly (if it exists in Build 42) or live with the fallback.
- **30-cell matrix worst-3 documentation** — record per cell which fail and why.

## Known blockers
None for the matrix walk. Q125-Q128 probes block the Progress Band danger transition + Defense Facts probe-badge accuracy.

## Build order — S123 work items

**Verification (priority):**
- **30-cell matrix walk:** 5 types (Clothing / Food / Weapon / Book / Container) × 2 widths (220 / 480) × 3 states (Idle / Active / Danger). Open card for each type at each width, trigger the relevant action for Active/Danger. Acceptable: ≥27/30 pass; document worst 3 in delta with screenshots.

**Wire-up:**
- **Q125-Q128 probes** — Equip clothing → check `getInsulation` / `getWindResistance` (vs Q24 baseline). Cook food → probe `getCookingTime` / `isCooked` / `getCookedTime` permutations. Let cooking go past completion → probe `isBurnt` + heat/time threshold for the cooked → burning transition.
- **Cooking → burning danger transition:** when `isCooked()` AND time-past-cooked > burn-threshold (Q127/Q128) → the queue poll's tick descriptor flips `mode = "danger"` (band re-renders in red). Q127/Q128 must land first.
- **Context menu mispositioning fix** (spawned as side task in `~/.claude` — pull it forward into S123 if not already done): `ISInventoryPaneContextMenu` anchor logic for kbm right-click should use `(getMouseX(), getMouseY())` not the gamepad-derived position.
- **Auto-refresh sourceContext** — currently after EQUIP fires, user must re-select the item for verb cluster to flip to UNEQUIP. Either hook OnEquipPrimary/OnClothingUpdated to call updateDrawer, or refresh per-frame in card prerender. Prefer the latter — simpler, no Java event surface dependencies.

**Polish:**
- **Cancel descriptor `_action` for fallback path** — when isReading-fallback fires the start, action ref is nil. Try resolving via ISReadABook hook (if Build 42 has the class — verify) so cancel can call forceStop directly instead of falling through to per-queue clear.

## Architecture decisions (locked S119+S120+S121+S122, carry forward)
- Source-context detection via parent-passed enum.
- Progress band reactivity via observer pattern, NOT `Events.OnTick` direct subscriber.
- Two presets (`compact:bool`); no intermediate sizes.
- No Tokens.lua mutation; edge-case borders compute via `ZeD.colorBlend`.
- Three universal molecules compose every card; no per-item-type chrome variants.
- Flag strip data in `item:getModData()` — keys named explicitly by designer.
- Progress Band cancel `[✕]` is the only cancel path; back-bar verbs grey out at .35α while action active.
- No rules between zone groups, sections, or above verb strip — padding only.
- Books skip the verb strip entirely.
- Defense Facts at 220w gets disclosure (zones compete); other Facts panels at 220w always-expanded.
- v15 ROW DISPATCH: 220w → `_drawZoneRow220` (NAME/BAR/PCT/DOCK), 480w → `_drawZoneRow480` (NAME/PCT/BAR/FLAG/DOCK with adaptive flag column).
- v15 ANATOMICAL GROUPING: TORSO/UPPER ARM/LOWER ARM/THIGH/SHIN/FOOT/HAND/HEAD/GROIN at both widths.
- HIT RECT CONVENTION: `_foldHitRects`, `_zoneDockRects`, `_cancelRect`, `_nameRowRect` stored as ABSOLUTE coords. update() compares against `getMouseX/Y()`.
- prerender SIZING: in drawer mode, card height = parent height. Scrollbar reads renderBody-stamped `_headH`/`_contentH`/`_verbStripResvH`.
- ITEM ACTION BRIDGE: `ItemActionHooks.lua` runs OnTick. Two parallel paths — queue polling + isReading fallback. Per-player `_lastActive` tracks transitions for synthetic `complete` events.

## Warm context (engine quirks active for S123)
- **Q1** Nested panel mouse events break at 4+ levels → ItemCard hit testing uses absolute-coord rects.
- **Q15b** Bitmap fonts (Fira) lack `▼ ▲ < > ★ ⊘ ✕ ✓ ✂` — ASCII placeholders shipped (`<`, `*`/`o`/`x`, `v`/`+`/`x`, `*` probe star). Live-verify pending.
- **Q24** `getInsulation()` / `getWindResistance()` don't exist on items — Q125/Q126 confirms or documents new path.
- **Q22/Q23/Q25/Q26** Food data quirks for NutritionFacts.
- **Q28/Q29/Q30** Combat stat quirks for CombatFacts.
- **Q44** Virtual `_floorContainer` silent-fail on `ISInventoryTransferAction` — header verb TAKE for ground items uses `transferFromFloor` pre-transfer.
- **Q94/Q95** Stack handling + per-frame builder seed-stomp race.
- **NEW (S122 finding):** PZ Build 42's read action queues with empty Lua fields — `pairs(action)` returns nothing, `action.Type` is nil. Needs IsoPlayer:isReading() fallback for reading detection. Will be Q129 after probe at S123 boot.

## Don't forget
- **BOOT ritual:** first action at S123 boot is `git log --oneline | head -30` cross-checked against PROJECT_STATE.md `Current: 0.1.1220305j`. Drift = halt and reconcile.
- **Pre-flight every test cycle:** grep latest `Logs/<latest>/*DebugLog.txt` for `ERROR|Kahlua|ItemCard|ItemCardOrganism|ItemActionHooks|EquipmentTab|attempt to call.*nil|attempt to index.*nil`. ModelManager / Translation are baseline noise.
- **Hot-reload unreliable; full PZ restart per test cycle.**
- **Version bump format:** `0.1.[session][DDMM]<suffix>`. First S123 commit is `0.1.123<DDMM>c`.
- **End-of-session ritual:** `git add . && git commit -m "S123: ..." && git push`. Code AND docs in same commit. Delta `ZeDUI/deltas/SESSION_123_DELTA.md` opened at boot, flushed at closeout.
- **Custodian capture is AMBIENT** — decisions land in delta as they happen.
- **The mockups are the spec.** v13/v15/v16 govern.
