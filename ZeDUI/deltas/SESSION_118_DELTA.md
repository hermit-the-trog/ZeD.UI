# Session 118 Delta — May 2, 2026
Boot version: `0.1.1170205g`
Close version: `0.1.1180205h`

> **Note:** Delta reconstructed at closeout — boot did not create file (orchestrator skill ran without invoking session-docs in boot mode). Future sessions: invoke `zed-session-docs boot` alongside the orchestrator boot.

## Locked decisions

- **Equipment drawer's selected-item view IS the inspector.** No separate inspect window. The drawer card (Tier 2, for inv items) + equipment-card view (for equipped items) are the inspection surfaces.
- **Per-zone soiled flags: BLOOD ONLY.** Vanilla only exposes `getBloodlevelForPart(part)` per-zone; `getDirtiness()` and `getWetness()` are item-level. Dirt + wet render as one item-level row ABOVE the per-zone list, not repeated per-zone.
- **Detail-zone disclosure defaults to OPEN** on first encounter. Drawer card IS the inspector — collapsed-by-default would hide the headline content.
- **Pristine + clean zones get NO dock.** Single-line row layout (name + % + bar). The synthetic "OK" filler dock was visual noise costing ~btnSz per pristine zone. Two-line layout reserved for damage / patch / soiled.
- **Equipment back button = just `<`.** No item name in the button label. Compact + fixed-width.
- **Action buttons in back-bar header.** `[< ] [Drop] [Unequip]` right-aligned in same row, no separate strip.
- **Coverage figure overlays per-zone warning-scale.** Uses `ZeD.ProtectionTab.protectionColorForDef` + `PART_TO_FIGURE` map. Replaces flat accent fill.
- **Equipment list RMB + gamepad-X open ZeD context menu.** Parity with inv-row pattern via `ISInventoryPaneContextMenu.createMenu`.

## Rejected approaches

- **Inspect window (Tier 3) as separate UI surface** — killed entirely. The drawer card + equipment-card view ARE the inspector tiers.
- **Inline rename via `_renaming` / `_renameEntry`** — was inspect-window-only feature; deleted along with inspect window.
- **Synthetic "OK" dock for pristine zones** — visual filler that wasted a row per clean zone. Now: no dock = single-line collapse.
- **Original v11 mockup showing per-zone dirt/wet** — engine doesn't expose those per-zone. Spec mockup was a bug; reality matches spec lines 219-222 which already document item-level only.
- **Whole-row hit rect on zone dock clicks** — was clickable anywhere on the row; now scoped to the dock-button rect via M16's new `outDockRect` out-param.
- **ATTACHMENTS section in equipment card** — redundant with detail-zone dock flag colors. Removed.

## Engine quirks discovered

None new this session. Used existing Q116–Q124 patterns (Kahlua pcall log spam, mutate-in-place tokens, ArrayList:get bounds, forward-decl shadow trap, Fira font glyph gaps).

## Design rules added or updated

- **Equipment drawer = inspector.** No separate inspect-window concept. All inspector functionality (full stats, detail zones, actions) lives in either the drawer card (inv items) or equipment-card view (equipped items).
- **Single-line zone rows when nothing to communicate.** drawZoneRow naturally collapses bottom row when both `dock` and `soiled` are nil. Pristine + clean zones use this path.
- **Action buttons live in back-bar header, not separate strip.** Right-aligned, replaces the standalone `_drawActionButtons` pattern.
- **Coverage figure shows per-zone protection via warning-scale.** Reusable across any "how does this clothing protect me" surface.

## Milestones / shipped work

- **Clothing detail zone shipped in BOTH render sites:**
  - `ZeD_ItemCard` drawer card (inv items)
  - `EquipmentTab` selected-item view (equipped items)
  - Shared via new `ZeD.ClothingDetail` public namespace
- **Mouse + gamepad dispatch for repair / remove-patch.** Calls `ISRepairClothing` / `ISRemovePatch` via the existing `_onZonePress` and shared `ZeD.ClothingDetail.dispatchZoneAction`.
- **Material availability cache + reactive greying.** No thread/needle/fabric → dock greys next frame; click is no-op.
- **Item-level soil row** (dirt + wet) above per-zone list.
- **Equipment list RMB + gamepad-X context menu.** Anchored at slot row, uses `ISInventoryPaneContextMenu.createMenu`.
- **Compaction pass:**
  - Top stats 4-row vertical → 2×2 grid
  - Killed full-width condition fill bar
  - Protection stats 3-row vertical → single inline row
  - Coverage figure 100×140 → 80×110
  - Pristine zones single-line
- **Dead code purge:**
  - `Hooks/InspectHook.lua` deleted (147 LOC)
  - Rename system removed from `ItemCard.lua` (~80 LOC: `_renaming`, `_renameEntry`, `_renameSaveBtn/Reset/Cancel`, `_startRename`, `_commitRename`, `_cancelRename`, `_nameHover`, `_nameWasDown`, `_nameHitRect`)
  - Inspect button + handler from `EquipmentTab.lua`
  - Inspect zone from `_equipActionZones` fallback in `ZeD_CharacterWindow.lua`
  - Net ~250 LOC removed

## Open questions parked

- **Equipment item detail layout needs full redesign.** User explicitly requested closeout to come back with a better prototype next session. Issues observed in S118h:
  - Clipping text — zone names overlap percentages (`"Upper Tors100%"`)
  - Two different dirty-flag styles visible simultaneously (DIRTY badge above stats + DIRTY pill in detail-zone item-soil row)
  - Item name missing from equipment detail card header
  - Cannot rename item from equipment detail (rename was inspect-only, now removed; needs re-added at appropriate surface)
  - Drawer card itself has "rough edges" (unspecified — investigate at next session brainstorm)
- **TOOLTIP_SPEC.md v12 amendment** — correct the per-zone dirt/wet mockup (engine only exposes blood per-zone). Captured at S118 brainstorm but never landed in spec doc.
- **Action strip verb side wiring** (Wash / Dry / Repair All / Pad All) — original S118 candidate #2, deferred.

## Mockups touched

None this session.
