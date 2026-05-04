# Next Session Handoff
Generated: May 3, 2026 — Session 121 closing, S122 booting.

## Target
**S122 — Wire B2 (ItemActionManager → real PZ TimedActions) + rename + matrix walk + closeout polish.** S121 shipped the universal v15 ItemCard organism end-to-end (220w + 480w, anatomical zone groups, flag column, seg-bar, header verb dispatch, EquipmentTab integration, padding-pass for text-size scaling). The card now visually matches the mockup at both widths. **What's left to make it fully functional:** Progress Band must light up during real cooking/reading/repairing → wire ItemActionManager to ISCookFood / ISReadABook / ISRepairClothing lifecycle. Plus: rename-on-click for the name row, gamepad-X cancel for the band, 30-cell matrix walk verification, Q125-Q128 probe + log to PZAPI-KB, and delete the `_legacy_render` archive in ItemCard.lua.

## Current state
Version `0.1.1210305n`. S121 commit shipped Phases 5+6 of the v13/v15/v16 spec rebuild. NEW `ItemCardOrganism.lua` (~900 LOC) extends `ZeD_ItemCard`. `ItemCard.lua` `render()` delegates to `:renderBody(ctx)`; legacy 336-LOC body archived in `if false then ... end end` block (delete in S122 once stable). Both 220w (drawer browsing) and 480w (full-width detail) layouts render to spec — anatomical group headers, seg-bar, adaptive flag column, font-scaled padding. EquipmentTab card mode is a child `ZeD_ItemCard` (`panel._equipCard`). Header verb cluster (EQUIP/UNEQUIP/DROP/TAKE/EAT/READ/USE) dispatches via `_dispatchHeaderVerb(label)` → vanilla `ISInventoryPaneContextMenu` handlers. Per-zone dock click + disclosure toggle hit rects fixed (absolute coords). MC eviction calibrated so card-open-in-MC caps window at user's `_baseInvW` and FIFO-evicts oldest col rather than collapsing MC entirely.

## Spec sources (READ FIRST every S122 boot)
- `ZeDUI/mockups/equipment_card_redesign_v13_refinements.html` — chrome rules (no rules between zone groups, padding-as-divider).
- `ZeDUI/mockups/equipment_card_redesign_v15_both_widths.html` — five item types × two widths. **220w is the canonical browsing view.**
- `ZeDUI/mockups/equipment_card_redesign_v16_progress_states.html` — Progress Band element (idle/active/danger; cooking → burning).

## Open decisions
- **Q125-Q128 PZ probes still open**, blocking proper Defense Facts ★ rows + Progress Band cooking/burning state. Test against equipped clothing (Q125 `getInsulation` / Q126 `getWindResistance`) and during a real cooking action (Q127 cooking-time getters / Q128 burning state path) at the start of S122.
- **Auto-refresh sourceContext after action complete:** currently after EQUIP fires, the user has to re-select the item for the verb cluster to flip to UNEQUIP. The `_updateDrawer` path runs on selection change, not on action completion. Decision: hook `Events.OnEquipPrimary` / `OnClothingUpdated` etc to call updateDrawer when the currently-displayed item's state changes? Simpler: just refresh sourceContext per-frame in card prerender.
- **Fira font glyph live-verify status:** ASCII placeholders shipped (`<` back, `*`/`o`/`x` flags, `v` checkmark, `+` repair, `x` rmpatch, `*` probe star). Decision: keep ASCII or attempt `★`/`⊘`/`✕`/`✓`/`▲`/`✂`/`★`? Designer can call.

## Known blockers
None for B2. Q125-Q128 should land at the start of B2 work since they affect what the Progress Band can show.

## Build order — S122 work items
**Wire-up (priority):**
- **B2** Subscribe `ItemActionManager` to PZ TimedAction lifecycle. Hook `Events.OnObjectAdded`/`OnTick`-equivalent OR override `ISCookFood:start/update/stop`, `ISReadABook:start/update/stop`, `ISRepairClothing:start/update/stop`. Each calls `ZeD.ItemActionManager.notify(item, "start"/"tick"/"complete"/"cancel"/"danger", action)` with `{kind, label, percent, timeStr}`. Cooking → burning transition is danger event when `getCookingTime` exceeds `getBurnTime` (Q127/Q128 probe).
- **B9** Gamepad-X cancel for Progress Band. Add `_cancelRect` as a 4th focusable kind in the gamepad ring (alongside toggle/verb/dock); card-zone X press fires the cancel hit rect.
- **rename input** on `_nameRowRect` click. update() detects mouse over `_nameRowRect`, on click swaps in a `ZeD_TextInput` overlaying the row. Commit on Enter, cancel on Esc.

**Polish (lower priority):**
- **480w inline DIRTY/WET chips** in the ZONES disclosure header (mockup has them right of the seg-bar; current impl renders a soil row below).
- **Auto-refresh sourceContext** so the verb cluster flips automatically when an action completes.
- **`_legacy_render` archive** in ItemCard.lua: delete the `if false then local function _legacy_render(self) ... end end` block now that the new organism has been verified across both widths + Equipment tab + Char + World drawer.

**Verification:**
- **C5** 30-cell matrix walk: 5 types (Clothing/Food/Weapon/Book/Container) × 2 widths (220/480) × 3 states (Idle/Active/Danger). Acceptable: ≥27/30 pass; document worst 3 in delta. Active/Danger requires B2 to land first.
- **C6** Q125-Q128 → PZAPI-KB entries (or "still nil per Q24" confirmations).

## Architecture decisions (locked S119+S120+S121, carry forward)
- Source-context detection via parent-passed enum, not by walking `item:getContainer()` from inside the card.
- Progress band reactivity via observer pattern (ItemActionManager), NOT `Events.OnTick`.
- Two presets only (`compact:bool`) for 220w/480w; no intermediate sizes.
- No Tokens.lua mutation; edge-case borders compute via `ZeD.colorBlend` at draw time.
- Three universal molecules (`drawCardBackBar`, `drawCardFlagStrip`, `drawCardVerbStrip`) compose every card; per-item-type chrome variants are a regression.
- Flag strip data in `item:getModData()`: ★ FAV / ⊘ NO-CRAFT / ✕ DISPOSE keys named explicitly.
- Progress Band cancel `[✕]` is the ONLY cancel path; back-bar verbs grey out at .35α while action active.
- No rules between zone groups, between sections, or above the verb strip — padding only.
- Books skip the verb strip entirely (`drawCardVerbStrip` empty list = no render).
- Defense Facts at 220w gets a disclosure (zones compete); other Facts panels at 220w always-expanded.
- v15 ROW DISPATCH: 220w → `_drawZoneRow220` (NAME/BAR/PCT/DOCK), 480w → `_drawZoneRow480` (NAME/PCT/BAR/FLAG/DOCK). Adaptive flag column at 480w.
- v15 ANATOMICAL GROUPING: render group header (orange mono caps) on group transition. `ZONE_GROUP_MAP` table in ItemCardOrganism.lua.
- HIT RECT CONVENTION: `_foldHitRects` and `_zoneDockRects` stored as ABSOLUTE coords (add `card:getAbsoluteX/Y()` at stamp time). update() compares against `getMouseX/Y()` directly.
- prerender SIZING: in drawer mode, card height = parent height (not legacy `_calcBodyH`). Scrollbar uses renderBody-stamped `_headH`/`_contentH`/`_verbStripResvH`.

## Warm context (engine quirks active for S122)
- **Q1** Nested panel mouse events break at 4+ levels → ItemCard hit testing uses absolute-coord rects in update().
- **Q15b** Bitmap fonts (Fira) lack `▼ ▲ < > ★ ⊘ ✕ ✓ ✂` glyphs — ASCII placeholders shipped, live-verify pending.
- **Q24** `getInsulation()` / `getWindResistance()` don't exist on items — DefenseFacts factory uses `safeGet` + `needsProbe = true` ★ badge fallback. Q125/Q126 confirm or document new path.
- **Q22/Q23/Q25/Q26** Food data quirks for NutritionFacts.
- **Q28/Q29/Q30** Combat stat quirks for CombatFacts.
- **Q44** Virtual `_floorContainer` silent-fail on `ISInventoryTransferAction` → header verb TAKE for ground items uses `transferFromFloor` pre-transfer.
- **Q94/Q95** Stack handling + per-frame builder seed-stomp race — relevant for any per-frame element registration.

## Don't forget
- **BOOT ritual:** first action at S122 boot is `git log --oneline | head -30` cross-checked against PROJECT_STATE.md `Current: 0.1.1210305n`. Drift = halt and reconcile.
- **Pre-flight every test cycle:** grep latest `Logs/<latest>/*DebugLog.txt` for `ERROR|Kahlua|ItemCard|ItemCardOrganism|EquipmentTab|attempt to call.*nil|attempt to index.*nil` before claiming clean. `ERROR: ModelManager` / `ERROR: Translation` are baseline noise.
- **Hot-reload unreliable; full PZ restart per test cycle.**
- **Version bump format:** `0.1.[session][DDMM]<suffix>`. First S122 commit is `0.1.122<DDMM>c`. Suffix walks `c→d→…→z→aa→…`.
- **End-of-session ritual:** `git add . && git commit -m "S122: ..." && git push`. Code AND docs in same commit. Delta `ZeDUI/deltas/SESSION_122_DELTA.md` opened at boot, flushed at closeout.
- **Custodian capture is AMBIENT** — decisions land in delta as they happen.
- **The mockups are the spec.** v13/v15/v16 govern; re-read them before improvising.
- **Legacy archive deletion:** S122 should remove the `if false then local function _legacy_render(self) ... end end` block in ItemCard.lua (around line 1039-1373) once the matrix walk passes.
