# Next Session Handoff
Generated: May 2, 2026 — Session 118 closing, S119 booting.

## Target
**S119 — REDESIGN equipment-card detail layout from scratch.** S118 shipped the per-zone detail-zone primitives + dispatch into both render sites, but the equipment-card *layout* in `EquipmentTab._drawCardContent` has visible regressions and rough edges. User has explicitly requested a redesign-from-scratch pass with a better prototype before any more code changes there. **Boot with `zed-orchestrator` brainstorm gate to design the new layout in chat → mockup before code.**

Specific layout problems observed at S118h closeout:
- Zone names overlap percentage values (`"Upper Tors100%"` clipping)
- Two different DIRTY flag styles visible at once (badge above stats + DIRTY pill in item-soil row)
- Item name missing from equipment-card detail header (was in inspect window, removed when inspect died)
- Cannot rename item from equipment-card detail (rename was inspect-only feature, now gone)
- Drawer-card `ZeD_ItemCard` also has unspecified "rough edges" — investigate

## Current state
Version `0.1.1180205h` (S118 shipped). Clothing detail zone primitives are LIVE in both `ZeD_ItemCard` (drawer card) and `EquipmentTab` (selected equipment view) via shared `ZeD.ClothingDetail` namespace. Mouse + gamepad-X repair / remove-patch dispatch wired. Material greying reactive. Inspect window concept dead (147 LOC + ~80 LOC rename system purged). Equipment back button compacted to `<`, action buttons in header, coverage figure shows per-zone warning-scale.

## Open decisions
- **Equipment-card layout redesign** (THE main S119 question — see Target above).
- **Where does rename live now?** Inspect window was the only rename surface. Options: re-add inline rename in equipment-card detail header; add to drawer card; right-click context menu only; defer until naming UX is rethought.
- **TOOLTIP_SPEC.md v12 amendment** still pending — correct the per-zone dirt/wet mockup (engine only exposes blood per-zone). Captured in S118 brainstorm gate, never landed in spec doc.
- **Action strip verb side wiring** (Wash / Dry / Repair All / Pad All) — original S118 candidate #2, deferred to its own session.

## Known blockers
None for the redesign target. The dispatch + data layer is solid; only the visual composition needs rework.

## Warm context
- **`ZeD.ClothingDetail` namespace** lives at the bottom of `ItemCard.lua` (~line 1730+). Public API: `getZones(item)`, `buildConfigs(item)` (now sets `dock = nil` for pristine zones, `action = "repair"|"remove-patch"|nil` derived from condIconKey), `buildItemSoil(item)` (returns `{dirt, wet}` or nil), `drawSoilRow(panel, x, y, w, soil)`, `findMaterials(player)` (returns needle, thread, fabric or triple-nil), `dispatchZoneAction(player, item, part, action)`.
- **`getClothingZones` zone tables now include `part` field** (BloodBodyPartType ref) so callers can dispatch without re-walking `getCoveredParts`.
- **M16 `drawZoneRow` 7th param** is optional `outDockRect` — caller passes a fresh table, M16 populates `{x, y, w, h}` of the structural dock BUTTON portion (panel-local) when dock has icon. Used by both render sites for click + gamepad hit-test capture.
- **`EquipmentTab._drawBackBar`** now stamps `_equipActionZones` per frame for the in-header Drop/Unequip buttons. Click routing in `ZeD_CharacterWindow.lua` walks them — same path as before, just rendered in a new spot.
- **`drawer.onRightMouseUp`** at `ZeD_CharacterWindow.lua` (look for `S118: Equipment list RMB`) walks `_equipSlotZones` and calls `ISInventoryPaneContextMenu.createMenu` — equipment list now has the same context menu inv lists do.
- **Detail-zone fold default = OPEN.** `ItemCard:_loadFoldStates` uses a per-key default fallback now: `clothing_zones` and `food_nutrition` default true; `food_ingredients` defaults false.
- **Coverage figure overlay** in `EquipmentTab._drawCoverageFigure` takes the item as 9th arg, walks `getCoveredParts`, calls `getDefForPart(part, false, false)` per part for bite defense, maps via `ZeD.ProtectionTab.PART_TO_FIGURE`, paints with `protectionColorForDef`. Reusable pattern — could lift to a shared helper if any other surface needs it.
- **`_renaming` / `_renameEntry` / rename buttons completely removed** from `ItemCard.lua`. Card has no rename UI at all currently.

## Don't forget
- **BOOT ritual:** first action at S119 boot is `git log --oneline | head -30` cross-checked against PROJECT_STATE.md `Current: 0.1.1180205h`. Drift = halt and reconcile.
- **Pre-flight every test cycle:** grep `C:\Users\danie\Zomboid\Logs\<latest>\*DebugLog.txt` for `ERROR|Kahlua|RadioTab|ItemCard|EquipmentTab|attempt to call.*nil|attempt to index.*nil` before claiming clean. `ERROR: ModelManager` / `ERROR: Translation` are baseline noise.
- **Hot-reload unreliable; full PZ restart for every test cycle.**
- **Version bump format:** `0.1.[session][DDMM]<suffix>`. S119 starts at `0.1.119MMDD`. Suffix walks `c→d→…→z→aa→ab→...`.
- **End-of-session ritual:** `git add . && git commit -m "S[N]: ..." && git push`. Code AND docs in same commit. Boot delta file (`SESSION_NN_DELTA.md`) at session start, flush at closeout — S118 had to reconstruct because boot didn't fire session-docs skill, don't repeat that.
- **Custodian capture is AMBIENT.** Decisions land in `ZeDUI/deltas/SESSION_NN_DELTA.md` as they happen.
- **Equipment-card primitives + namespace from S118 are KEEPERS.** Redesign reuses `ZeD.ClothingDetail.*` — only the visual composition + header/rename layer changes.
