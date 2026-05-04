# Session 121 Delta — May 3, 2026

Boot version: `0.1.1200205c` (last commit `c257108a` — S120)
Baseline commit: `c257108a` — S120 ItemCard atoms/molecules/facts foundation
Close version: TBD (first S121 commit will bump to `0.1.121<DDMM>c`)

> **Boot mode active.** Ambient capture as decisions land. Custodian flushes to canon at closeout.
> **NB:** S120 closeout flush did not run at end of S120 — reconciled retroactively at S121 boot. PROJECT_STATE.md + NEXT_SESSION_HANDOFF.md were brought up to date as the first action of S121, before any code work.

## Session target

S121 — BUILD ItemCard organism (Phase 5) + integrate at Equipment tab and Inventory drawer card sites (Phase 6). Walk 30-cell test matrix (5 types × 2 widths × 3 progress states).

Mockups locked S119 ARE the spec — unchanged from S120:
- `ZeDUI/mockups/equipment_card_redesign_v13_refinements.html` — chrome rules, padding-as-divider
- `ZeDUI/mockups/equipment_card_redesign_v15_both_widths.html` — five types × two widths
- `ZeDUI/mockups/equipment_card_redesign_v16_progress_states.html` — Progress Band element

Complexity flag: 16 tasks, 2 specialists (zed-modding + zed-java-backend). Recommended split — Phase A (reconcile, done) + Phase B (organism build) this session; Phase C (integration + 30-cell matrix) next session if energy gives out.

## User decisions captured at boot

- **Drift handling:** reconcile docs FIRST, then plan S121 (vs. forging ahead with stale docs). Retroactive S120 flush executed before any new code.
- **Phase split:** S121 covers Phase 5 + 6 per S119 plan; Phase 6's 30-cell matrix in particular benefits from a fresh head — soft cap on ambition.

## Locked decisions

- **B1 audit complete.** Phase B sequencing reordered: B3→B4→B5→B6→B8 first (visual organism + hit testing) so we can verify v13 chrome at idle state; then B2 (real PZ TimedAction → ItemActionManager.notify wiring); then B7+B9 (state mirroring + gamepad-X cancel) which depend on B2's data source. Reason: ItemActionManager.getActiveAction returns nil for everything until B2 wires; the Progress Band molecule short-circuits to height=0 — so the rest of the organism works fine without B2 for static-state verification.
- **`renderBody(ctx)` stamps existing field names.** Gamepad ring APIs at lines 1395-1592 (`getActionStripElements` / `getZoneDockElements` / `_drawGpFocusOutline` / `getDisclosureYs` / `scrollToContentY` / `scrollToNextDisclosure` / `scrollToPrevDisclosure`) read from `self.toggleRects[i]`, `self.verbRects[i]`, `self._verbDefs`, `self._zoneDockRects`, `self._foldHitRects`, `self._gpFocusedBtnId`. New organism populates the SAME fields each render — gamepad ring stays green without changes to the API surface.
- **B9 adds `self._cancelRect` field.** New Progress Band cancel button registered as a 4th focusable kind alongside toggle/verb/dock — id namespace `cancel_band`. `_drawGpFocusOutline` extended with one more lookup branch.

## Rejected approaches

- ~~Big-bang rewrite of ItemCard.lua in one Edit.~~ Per memory `feedback_incremental_build`, building each piece in sequence. New organism methods added alongside old, render() switches to renderBody(ctx) only after each B-task verifies independently.
- ~~Replacing the gamepad ring API as part of B-rewrite.~~ Field-shape contract (rect tables w/ `x,y,w,h,id` per element) preserved exactly. Only the values change, not the consumers.

## Engine quirks discovered

(populated as work happens — Q125-Q128 PZ probes live cycle work this session)

## Design rules added or updated

(populated as work happens)

## Milestones / shipped work

### Phase A — Retroactive S120 flush (DONE)

- **A1** PROJECT_STATE.md `## Last updated` header bumped to S120 with full S120 summary chained above existing S118 chain.
- **A2** PROJECT_STATE.md version row added: `0.1.1200205c` row above the `0.1.1180205h` row, full closeout summary distilled from SESSION_120_DELTA.md.
- **A3** NEXT_SESSION_HANDOFF.md fully rewritten for S121 boot — Target = Phase 5 + 6, build order, architecture decisions carry-forward, open Q125-Q128 probes, warm-context engine quirks (Q1, Q15b, Q24, Q22-Q26, Q28-Q30, Q44, Q94/Q95).
- **A4** SESSION_120_DELTA.md preserved as canonical historical record (untouched).
- **A5** This file (SESSION_121_DELTA.md) opened.

### Phase B — ItemCard organism (PARTIAL — ready for live PZ verify)

- **B1** Audit complete (ItemCard.lua 1627 LOC, render method 1021-1357 = 336 LOC, format helpers 76-273, gamepad ring API 1395-1592 PRESERVED, ZeD.ItemDetail namespace 1602-1627 PRESERVED).
- **B3+B4+B5+B6+B7** NEW FILE `ItemCardOrganism.lua` (665 LOC) — clean extension that adds `:renderBody(ctx)` + `_renderClothingBody` + `_renderGenericBody` + 5 module-level helpers (`headerVerbsForContext`, `maintenanceVerbsForItem`, `topStatsForItem`, `readMarks`, `categoryOf`) + `mirrorActiveStateOnRows` for state coloring + `stampGamepadFields` to keep the S99 gamepad ring API contract green. Loads alphabetically after ItemCard.lua, before ItemFactsPanel.lua.
- **B-switch** ItemCard.lua render() (1021-1357) replaced with 10-line delegation `self:renderBody({sourceContext = self.sourceContext})`. Legacy 336-LOC body wrapped in `if false then local function _legacy_render(self) ... end end` so it parses but never executes — kept transitionally as reference for layout intent + field-stamping conventions, **DELETE in S122 after 30-cell matrix passes**.
- **drawFactsRow extended** Molecules.lua line 2536 — added 9th param `needsProbe`. When true, renders the v13 `★` probe badge (currently ASCII `*` per S120 Fira font glyph caution; live-verify swap to `★` per Q15b). Mono `T.warning` after the label with 4px margin. Single touch to S120 code; only callsites are my new ItemCardOrganism.lua calls.

**Bug found and fixed during B-switch:** `M.drawZoneRow` is a 7-param function (panel, x, y, w, zone, hovered, outDockRect); my first draft was passing 8 args which slotted `outDockRect` into ignored position 8 with `nil` at position 7 — would have silently dropped all clothing zone-dock hit rects. Fixed to pass 7 args correctly.

**Bug found and fixed during B-switch:** `ZeD.ItemDetail.buildItemSoil(item)` returns nil when nothing to display, but `drawSoilRow` indexes `soil.wet` directly — would crash on non-soiled clothing. Added nil guard at the buildItemSoil callsite.

**Bug caught at first PZ load + fixed:** the legacy-archive trailer at ItemCard.lua:1373 had `end end end` (4 ends total at close, counting the inner-if `end` on the previous line) — one extra. Lua/Kahlua silently parse-failed the entire file, so `ZeD_ItemCard` global never got defined, and ZeD_CharacterWindow.lua:3689 (`ZeD_ItemCard:new(...)`) hit `attempted index: new of non-table: null` once gamepad input mode kicked in. Required ends at close: 3 (inner if-block + `_legacy_render` + `if false then` wrapper). Fixed to `end end` on the trailer line, total 3.

**Live-load gate cleared at 0.1.1200205c+local. ItemCard.lua now parses, gamepad-mode crash gone.**

**Visual verify pass 1 (4 screenshots from user):**
- Inventory drawer chrome RENDERS for clothing / weapon / book / container at both 220w and 480w. Back-bar `<` + name + EQUIP/DROP, MARKED `*`/`o`/`x` chips, top-stats grid (480w) / list (220w), Facts panel via registry, maintenance verb strip (REPAIR/SHARPEN for weapons; WASH/REPAIR/PAD for clothing). Phase B chrome composition is functionally correct.
- **EquipmentTab still uses old code path** — selected-equipped-item view shows S118 `_drawCardContent` (BITE/SCRATCH/BULLET stat panels, full-protection figure, DETAIL ZONES). Expected — Phase C1 work.
- **Ground-item drawer shows EQUIP/DROP, not TAKE** — World drawer's `sourceContext` not yet set; `verbsForContext` defaults to "inventory" path. Expected — Phase C3 work.

**Visual verify pass 1 — bugs found and fixed:**
- **Verb strip overlap.** Maintenance verb strip drawn at `getHeight()-28` was sitting on top of the body's stencil region (which extended to full card height). Body content (Knockback / Critical % / Defense Facts) rendered UNDER the strip and got obscured. Fix in `renderBody`: pre-compute maintenance verbs once, reserve 34px (verbStripH + 6px top-pad) at the bottom of `bodyH` before setting the stencil. Body now stops cleanly above the strip.
- **Zone names overflow at 220w.** S118 `drawZoneRow` (Molecules.lua:1933) uses a 50/50 column split where left column holds NAME + PCT side-by-side. At 220w innerW≈200, colW≈98 — full anatomical names like "Upper Torso" (~62px in fontF2) collide with right-aligned "100%" → visible "Upper Tors100%" run-on. v15 spec ultimately wants a 38/1fr/26/18 single-row layout (S122 new molecule), but until then, added `ZONE_SHORT_NAME` lookup in ItemCardOrganism.lua to swap to short forms (`U.Torso`, `L.U.Arm`, `R.Fore`, etc.) at compact widths only. zCfg flat-copied per-row so the shared zones table stays untouched.

**Visual verify pass 2 — bug found and fixed:**
- **Duplicate "Defense Facts" title at 220w.** When clothing's Defense Facts panel renders behind a disclosure (220w only, per v15 spec — zones compete for vertical space), my code drew the disclosure header (`v Defense Facts`) AND then `M.drawFactsTitle(...)` ALSO drew "Defense Facts" inside the body. Two titles stacked. Fix in `renderClothingBody`: skip `drawFactsTitle` when `hasDisc` is true — the disclosure header already provides the panel title.

### Phase C2 + C3 — sourceContext wiring (DONE)

- **C2** ZeD_CharacterWindow.lua:4450+ — after `setItem(singleItem)`, resolve and set `win._itemCard.sourceContext`:
  - `safeGet(item, "isEquipped") == true` → `"equipped"` (UNEQUIP/DROP cluster)
  - `_activeContainer == playerInv`     → `"inventory"` (EQUIP/EAT/READ/USE + DROP)
  - else                                → `"container"` (TAKE/EQUIP)
- **C3** ZeD_WorldWindow.lua:3515+ — after `setItem(singleItem)`, resolve and set `win._itemCard.sourceContext`:
  - `_activeContainer == _floorContainer` → `"ground"` (TAKE only — Q44 virtual floor)
  - else                                  → `"container"` (TAKE/EQUIP)
- World items are never "equipped" or "inventory" by definition (player can't equip from a non-player container directly without transfer).
- Card's renderBody falls back to `"inventory"` when sourceContext is nil, so wiring is forward-only — older code paths still work.

**Visual verify pass 3 — bug found and fixed:**
- **`_activeContainer` is an INDEX, not a reference.** First C2/C3 draft compared `win._activeContainer == pInv` (Char) and `win._activeContainer == _floorContainer` (World). Both always-false because `_activeContainer` is an integer index into `win._containers[]`. Result: every Char inventory item showed `TAKE EQUIP` ("container" cluster) instead of `EQUIP DROP` ("inventory" cluster); World floor items would have shown `TAKE EQUIP` instead of just `TAKE`. Fix: dereference via `win._containers[win._activeContainer]` and check the entry's `.isMain` (Char) / `.isFloor` (World) flags. World containers don't have `.isMain` — that's Char-specific (S118 Q-pattern).

**Visual verify pass 3 — design ruling reversed:**
- **MC eviction on item-select retired.** S108 v2 QA design said "in MC mode, card opening should NOT expand the window — let inv area shrink + FIFO evict the oldest MC col so columns stay readable instead of pushing the window wider." This caused MC to silently collapse the moment user clicked an item to open its card — disorienting after the new ItemCard's larger drawer width became routine. **S121 reversal:** in both Char + World windows, drawer-mode-item open in MC mode now expands the window like tab-mode does (mirrors pre-existing tab-mode behavior). MC selections persist across item-select. The MC eviction safety valve loop (further down each prerender) still fires only if the window literally cannot fit at maxW.

**Visual verify pass 4 — eviction calibration:**
- **First reversal grew window too generously.** Plain `maxW = mcActive and (screenW - 10)` let the window stretch nearly to full screen — eviction never fired even with 3+ MC cols + the card all visible. **Fix:** when MC + drawerMode="item" both active, cap maxW at `_baseInvW + chrome + drawer` (user's preferred inv width plus all the strips and the card's drawer). Window expands enough to host the card alongside MC, but past that the eviction loop fires and FIFO-removes oldest MC col so per-col stays ≥ MIN_COL_W. Restores the "card opens, MC trims to fit" cadence without snapping the entire MC stack closed on first item-click.

**Visual verify pass 5 — v15 220w alignment pass:**
After side-by-side game-vs-mockup compare, the 220w drawer was visually "pretty off" from v15 spec. Applied a focused refactor:
- **NEW `_drawZoneRow220`** in ItemCardOrganism.lua — single-row layout `NAME(38) | gap | BAR(1fr) | PCT(26) | gap | DOCK(18)` per v15 220w spec. Replaces S118 50/50-column drawZoneRow at compact widths only. 480w continues using S118 (v15 480w 5-column layout deferred to S122).
- **NEW `ZONE_GROUP_MAP`** anatomical grouping. Zones now render under section headers (`TORSO`, `UPPER ARM`, `LOWER ARM`, `THIGH`, `SHIN`, `FOOT`, `HAND`, `HEAD`, `GROIN`) in orange mono caps; child name reduces to `Upper`/`Lower`/`Left`/`Right`/etc within the group. 4px pad between groups, 1px breathe between rows.
- **NEW `_drawZoneSegBar`** — multi-segment ZONES bar drawn directly below the disclosure header (220w only). One colored segment per zone via `_zoneSegColor` (TORN→danger, WORN→warning, Leather/Denim/Fabric→patch tint, pristine→ratio-based green/amber/red).
- **ZONES disclosure header** now shows the overall garment condition % (right-aligned, ratio-colored) — matches v15 `62%` summary text.
- **Header verb cluster** at compact widths: drop secondary verbs, keep only primary CTA. v15 220w mockup shows just `UNEQUIP` (or `EQUIP` / `TAKE`) — not `UNEQUIP + DROP`. 480w retains the primary+secondary pair.
- **`SHORT_FACTS_LABEL_220` table** swaps long Defense/Combat labels at compact: `Bite Defense`→`Bite`, `Wind Resistance`→`Wind`, `Water Resistance`→`Water Res.`, `Cond Loss / Hit`→`Cond / Hit`, `1-in-N degrade`→`1-in-N`, etc. Long labels would otherwise truncate awkwardly at 220w. Applied in both `renderClothingBody` and `renderGenericBody` Facts loops.
- **Removed obsolete `compact` param from drawFactsRow calls** — molecule signature is 8 params; the 9th `compact` was being silently dropped. Caller-side label shortening makes the param unnecessary anyway.

Retired: `ZONE_SHORT_NAME` lookup (replaced by `ZONE_GROUP_MAP[name][2]` short within-group names).

Deferred to S122: 480w v15 zone row layout (5-column with flag text + dock); v15 480w segment-bar atop the zones disclosure (currently 220w-only); 480w group headers.

**Visual verify pass 6 — padding pass for text-size scaling:**
First v15 alignment used hardcoded pixel values (rowH=14, gaps=1-4px) that didn't scale with font height — at larger text-size presets, zones clipped and felt cramped. Per memory `feedback_padding_preference` (generous 6-10px default; 2px is nothing, 4px is "a little"), retuned the entire zones block to font-scaled padding.
- **`_drawZoneRow220` row geometry now scales with `T.fontF1H`.** rowH = max(fontH+8, 20), dockH = max(fontH+6, 18), barH = max(fontH*0.55, 7), nameW = max(measure("Right")+6, 40), pctW = max(measure("100%")+4, 28), dockW = dockH+4, gap=6. At default fontH=10 → rowH=20; at large fontH=18 → rowH=26 — text always has 4px vertical breathe, never clips.
- **`scalePad(base) = max(base, fontH*0.6)`** helper applied to inter-row gap (5+), group-pad-above (10+), seg-bar bottom pad (12+), soil-row bottom pad (8+), disclosure-to-segbar pad (8+). Each baseline jumps proportionally as font scales up.
- **ZONES disclosure header** now `fontH+10` tall (min 24); group headers `fontH+8` tall (min 20). seg-bar height = max(fontH*0.8, 12).
- **Body inner padding** (the gap between body content and card edges) scales with fontF1H — at default font ~12px, large fonts ~18-20px.
- **`sectionGap`** between top-stats / zones / facts now `max(14|16, fontF4H*1.0)` so the visual rhythm between sections also breathes at larger sizes. Same change in `renderGenericBody` for consistency across all item types.
- **Inter-row gap was 1px, now 5px+** — biggest visual upgrade. Zones no longer feel jammed together.

**Visual verify pass 7 — Defense Facts clipped after padding pass:**
After the padding pass made the body taller, Defense Facts + the lower zone groups (Lower Arm, Hand, Foot, etc.) disappeared from the screen — clipped without a scrollbar. Root cause: `prerender` was still running the legacy `_calcHeadH` / `_calcBodyH` to size the card. Those legacy calcs used the OLD ItemCard layout's content-height assumptions and returned a height too small for the new v15 body composition, so the card was sized below its actual content and the bottom got cut off. The scrollbar wasn't appearing because `bodyContentH > viewH` evaluated false against the legacy estimate.

**Fix:** in drawer mode, `prerender` now sets the card height to `parent:getHeight()` directly (= the itemDrawer panel's full body height) instead of computing from legacy `_calcBodyH`. Scrollbar setup reads `self._contentH` and `self._headH` stamped by `renderBody` from the previous frame — one-frame lag is invisible. Non-drawer mode still uses the legacy calc (rough-but-working for the inspect path). This retires Phase B-polish (the prerender-uses-renderBody-stamps todo).

**Visual verify pass 8 — scrollbar runs behind verb strip + name truncation:**
- **Scrollbar extended past the verb-strip footer.** Scroll content + scroll thumb visible behind WASH/REPAIR/PAD. Fix: `renderBody` now stamps `self._verbStripResvH` (34px when maintenance verbs present, 0 when not — books, etc); prerender subtracts it from the scrollbar's `viewH` so the thumb ends cleanly above the footer. Body content already reserved that space; this brings the scrollbar in line.
- **Name was truncating in the back-bar.** Designer wants the full item name visible always + future rename hook. Fix: `renderBody` now passes empty name to `drawCardBackBar` and renders a dedicated **full-width name row** below it. Title font (T.fontF4), `nameVPad` & `nameHPad` scale with `T.fontF1H`, surf1 bg, 1px bottom rule. `self._nameRowRect` stamped for click-to-rename in a follow-up. Long names truncate to row width but the row is now drawer-wide so much more fits than before.

**Visual verify pass 9 — verb strip reserve scaling:**
At larger text-size presets the scroll content was still bleeding into the verb strip's bg paint a few pixels. Fix replaces the hardcoded `verbStripResvH = 34` with a font-scaled formula: `vsBtnH(22) + vsTopPad + vsBotPad`, where both pads = `max(8, fontF1H * 0.7)`. At default font (~10) → 22+8+8 = 38; at large font (~18) → 22+13+13 = 48 — proportional buffer. Matched the strip's bg drawRect to `(0, h-verbStripResvH, w, verbStripResvH)` and positioned the button row at `vsBgY + vsTopPad` so the bg band, button position, and scroll-reserve geometry stay in sync at every size.

### Phase C1 + B8-partial — Equipment tab integration + back-button hit (DONE)

- **C1** EquipmentTab.render's card mode (lines 1158-1228 = ~70 LOC) replaced with a single ZeD_ItemCard child (`panel._equipCard`) lazy-created on first selection. Per-frame: setX/setY/setWidth/setHeight match the tab area, setItem(selSlot.item), sourceContext = "equipped", setVisible(true). Skips the legacy `_drawBackBar` + `_drawCardContent` + manual scroll setup — card handles all of it via its own renderBody + scrollbar in prerender. On exit from card mode (or selection cleared), card:setVisible(false) hides it without destroying state.
- **B8 partial — back-bar back arrow click.** Added in `ItemCard:update()`: detect mouse over `_backBarRects.back` (stamped by drawCardBackBar each frame), fire `self:onBackClick()` on click-release if installed. Equipment tab installs the callback to `win._equipSelected = nil` so the back arrow returns to slot-list mode.
- Equipped clothing now shows the universal v15 card (back-bar + UNEQUIP verb + name row + MARKED chips + KIND/WEIGHT/FABRIC/CONDITION/COMBAT/RUN top stats + ZONES disclosure with seg-bar and anatomical groups + Defense Facts behind disclosure + WASH/REPAIR/PAD strip) instead of the S118 BITE/SCRATCH/BULLET + figure layout.
- The header verb cluster's UNEQUIP/DROP click dispatch is still pending (B8 full) — currently those buttons render but no-op on click. Equip tab parity with inv drawer in chrome only.

### Phase B8 full — header verb dispatch (DONE)

ItemCard:update() now extracts hover index over `_backBarRects.verbs[i]`, looks up the verb's label from `_lastHeaderVerbs[hover]` (stamped by renderBody each frame), and on click-release dispatches via new `ZeD_ItemCard:_dispatchHeaderVerb(label)` method:
- **EQUIP**: clothing → `ISInventoryPaneContextMenu.onWear`; weapons/firearms → `onEquipWeapon` (primary, no secondary) or fallback `onEquipPrimary`.
- **UNEQUIP**: queue `ISUnequipAction(player, item, 50)` — canonical 50ms timing matching all vanilla call sites (S99 pattern).
- **DROP**: `CM.onDropItems({item}, playerNum)`.
- **TAKE**: floor items (Q44 virtual `_floorContainer`) use `ZeD_WorldWindow.transferFromFloor` pre-transfer, otherwise `CM.onGrabItems`.
- **EAT**: `CM.eatItem(item, 1, playerNum)`.
- **READ**: Literature → `CM.OnReadBook` for books, fallback `CM.OnRead`.
- **USE**: Drainable / generic → vanilla `ISInventoryPane.doContextualDblClick` (stub pane with `player = playerNum`, S99 pattern).

Item-state-change reactivity: vanilla actions queue ISTimedActions which mutate `isEquipped()` etc. The window's `_updateDrawer` re-runs on selection change so `sourceContext` re-resolves on the next click — verb cluster auto-flips (EQUIP → UNEQUIP) once the queued action completes. Currently the user has to re-select the item; auto-refresh on action complete is a follow-up.

### Phase 480w v15 polish (DONE — pulled from S122)

- **NEW `_drawZoneRow480`** in ItemCardOrganism.lua — v15 480w 5-column layout `NAME(60) | PCT(36 right-aligned) | BAR(1fr) | FLAG-TEXT(76 right-aligned) | DOCK(22)` with 8px gaps. Replaces S118 drawZoneRow at non-compact widths. Flag column maps clothing patch state to display text + theme color: `TORN`→danger, `WORN`→warning, `Leather`→`LEATHER` in matLeather/warning, `Denim`→`DENIM` in matDenim/info, `Fabric`/`Ripped Sheets`→`FABRIC` in matFabric/text, pristine→`—` in textDim. Dock cell shares the v15 spec used at 220w (dim `v` for pristine, `+` for repair, `x` for remove-patch).
- **Anatomical group headers + seg-bar at 480w.** The group-headers + group-pad-above logic that previously gated on `compact` now runs at both widths via a single `rowFn = compact and _drawZoneRow220 or _drawZoneRow480` dispatch. Zone seg-bar (`_drawZoneSegBar`) also drops its compact gate — drawn at both widths below the disclosure header. The mockup spec is uniform across widths for the grouping; only the per-row layout differs.
- **Retired:** S118 `M.drawZoneRow` fallback in renderClothingBody — both widths now go through the new v15 row functions. drawZoneRow remains exported on `Molecules` and is still consumed by EquipmentTab's old code paths until that file is fully migrated (the legacy _drawCardContent dead path).

**Visual verify pass 10 — disclosure clicks dead, zone-dock clicks dead:**
ZONES disclosure was rendering with `>` (collapsed) and clicking the header didn't toggle. Same for the Defense Facts disclosure at 220w and the per-zone dock buttons. Root cause: I was stamping `_foldHitRects` and `_zoneDockRects` with PANEL-LOCAL coords, but `ItemCard:update()` compares them against ABSOLUTE mouse coords (`getMouseX/Y()`). Always-false hit test → no clicks. Legacy renderer stored absolute coords (computed `ay + curY` at draw time); new renderer was missing the offset. Fixed: stamps now add `card:getAbsoluteX/Y()` for the ZONES disclosure header, the Defense Facts disclosure at 220w, and every zone-dock outRect. Disclosure toggling and zone-dock dispatch (repair / remove-patch) both work again.

### Phase B — pending tasks (deferred to follow-up sub-session or S122)

- **B8 hit testing** Existing update() (ItemCard.lua:835) handles flag chips (via S99 ActionStrip M.updateActionStrip — compatible with my flagRects since toggleRects[1..3] map to fav/protect/unwanted DEFS) AND maintenance verb strip (via VERB_DISPATCH for `repair_all`, `pad_all`, `repair`, `sharpen`; `wash`/`clean`/`cook` no-op gracefully — handler nil → skip). NEW clusters need wiring: back-bar verbs (`_backBarRects.back`, `_backBarRects.verbs[i]`), Progress Band cancel (`_cancelRect`). Stub handlers print to log; real dispatch is Phase C work.
- **B2 ItemActionManager wiring** Real PZ TimedAction lifecycle hooks (ISCookFood / ISReadABook / ISRepairClothing → notify(item, "start"/"tick"/"complete")) — Progress Band stays at height=0 until B2 lands. Visible organism verification works WITHOUT B2; B2 is for live progress UX.
- **B9 gamepad-X cancel** Adds `_cancelRect` as a 4th focusable kind in the gamepad ring. Card-zone X press fires cancel hit-rect. Trivial once B8's hit handler is shaped.
- **prerender legacy compat:** prerender (ItemCard.lua:915) still calls legacy `_calcHeadH` + `_calcBodyH` for scrollbar sizing. renderBody overwrites `_headH` and `_contentH` mid-frame, but prerender re-reads legacy values on next frame. Scrollbar may be slightly miscalibrated (under/over-show). Polish: rewrite prerender to use a dry-run measure or read renderBody's stamps. Deferred — not crashy, just cosmetic.

### Phase C — fully deferred

Integration sites (EquipmentTab, Char/World drawer wiring) + 30-cell matrix walk + Q125-Q128 probe + S121 closeout.

## Open questions / probes

- **Q125** `getScriptItem():getInsulation()` — does it exist? type? range? per-frame stable? (Phase C6 — confirm Q24 still holds OR document new path)
- **Q126** `getScriptItem():getWindResistance()` — same (Phase C6)
- **Q127** Food cooking time getters — probe `getCookingTime()` + `isCooked()` + `getCookedTime()` permutations (Phase C5 active state)
- **Q128** Burning state path — probe `isBurnt()` + heat/time threshold (Phase C5 danger state)
- **Fira font glyph live-verify:** does `★` / `⊘` / `✕` render at flag chip layer? `▼` / `▲` at chevron layer? `<` for back-bar already shipped — keep or swap?
- **Source-context verb cluster matrix:** 4 contexts × 5 types = 20 cells. Confirm against PZ contextual-double-click for vanilla parity.

## Mockups touched

(populated if any mockup work happens — none expected for S121 build session)

## Deferred to S122 (if Phase C doesn't fit S121)

- Phase 6 — Integration. Equipment tab card site + Inventory list card site. Test matrix: 5 types × 2 widths × 3 states = 30 cells.
- Q125-Q128 live probe results to PZAPI-KB.
