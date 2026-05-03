# Session 120 Delta — May 2, 2026

Boot version: `0.1.1180205h` (last commit `bbe3d6ba` — S118)
Baseline commit: `5a475c62` — S119 design artifacts pushed clean before S120 code starts
Close version: TBD (first S120 commit will bump to `0.1.120DDMMc`)

> **Boot mode active.** Ambient capture as decisions land. Custodian flushes to canon at closeout.

## Session target

S120 — BUILD ItemCard atoms → universal molecules → content molecules → Facts panel organisms (Phases 1–4).

Mockups locked S119 ARE the spec. Three files:
- `ZeDUI/mockups/equipment_card_redesign_v13_refinements.html` — chrome rules, padding-as-divider
- `ZeDUI/mockups/equipment_card_redesign_v15_both_widths.html` — five types × two widths
- `ZeDUI/mockups/equipment_card_redesign_v16_progress_states.html` — Progress Band element

Phases 5–6 (organism assembly + Equipment/Inventory integration) explicitly deferred to S121. Hard cap.

## User decisions captured at boot

- **Git tracking:** standard ritual — S119 artifacts committed clean before S120 code starts (this delta file is the only untracked thing now). End-of-session: single S120 code+docs commit + push.
- **Namespace:** `ZeD.ClothingDetail` → `ZeD.ItemDetail`. Refactor in place across `ItemCard.lua` + `EquipmentTab.lua`. All 6 exports keep their names. `dispatchZoneAction` generalizes to verb-dispatch beyond clothing.

## Locked decisions

- **T1.1 — no Tokens.lua mutation.** All v13 mockup CSS vars map to existing `T.*` tokens. Edge-case dark border variants for primary CTA chrome + flag chip on-state borders compute at draw time via existing `ZeD.colorBlend(color, T.base, 0.55)`. Avoids token bloat — same approach the radio chassis took (PT/CD/VT/LCD inlined as tier-specific). Z-condition gradient reuses `ZeD.ProtectionTab.protectionColorForDef` (S118).
- **T1.2/T1.3 — atoms take a `compact:bool` flag for 220w / 480w sizing presets** instead of explicit dimensions. Two presets correspond to two locked mockup designs; intermediate sizes are not a valid use case. Pattern matches how `drawSegBar` accepts discrete `n,k` rather than free pixel dimensions.
- **T1.2 ProgressBand — System-7 raised cancel button** uses `T.surf4` (top/left highlight) + `T.borderS` (bottom/right shadow) per v16 mockup `#4a4a4a` / `#000` — softer than the all-or-nothing `T.chromeHi` / `T.chromeSh` (which are full white/black for stronger contexts).
- **T1.3 FlagChip — glyph param is text, not texture.** Caller composes the chip with a unicode glyph string (e.g. `★`). If Fira font set lacks the glyph (memory `feedback Fira font glyph gaps`), molecule layer (T2.2) can swap to texture pathway later without changing the atom.
- **T1.4 — drawZoneRow / outDockRect kept as-is.** Confirmed at `Molecules.lua:1933` with `outDockRect` 7th param working. No reimplementation. Phase 3 zone list reuses existing primitive.

## Rejected approaches

(populated as work happens)

## Engine quirks discovered

(populated as work happens — Phase 4 PZ probes Q125–Q128 expected)

## Design rules added or updated

(populated as work happens)

## Milestones / shipped work

### Phase 1 — Atoms (DONE)

- **T0** Git baseline `5a475c62` (S119 design artifacts: handoff + 10 mockup HTMLs); `SESSION_120_DELTA.md` opened at `ZeDUI/deltas/`.
- **T1.1** Token audit complete. No `Tokens.lua` mutation. Decision logged above.
- **T1.2** `ZeD.Atoms.drawProgressBand` shipped to `Atoms.lua` §12 (line 699). Two-row band: label/time/percent/cancel + horizontal fill + mode-colored bottom separator. Modes: `active` / `danger` (idle = caller skips). Returns total height. Out-param for cancel hit rect. `compact:bool` for 220w / 480w sizing.
- **T1.3** `ZeD.Atoms.drawFlagChip` shipped to `Atoms.lua` §13 (line 820). Three kinds (`fav` / `nocraft` / `dispose`) drive on-state color family. Off-state uniform. Border darkens via `ZeD.colorBlend(onBg, T.base, 0.55)`. Returns chip width. `compact:bool` for 22-icon-only / padded-label preset.
- **T1.4** `Molecules.drawZoneRow` (line 1933) + `outDockRect` 7th param confirmed intact. No code. Ready for Phase 3 zone-list reuse.

### Phase 2 — Universal Molecules (DONE)

- **T2.1** `Molecules.drawCardBackBar` shipped at `Molecules.lua:2072`. 37px (480w) / 30px (220w) header strip: raised back btn `<` + ellipsis-truncated name + verb cluster. Verbs render right-to-left, primary uses `T.accent` + `accentBright`/`colorBlend(accent,base,.55)` chrome; secondary uses surf2 + surf4/borderS. `progressActive=true` greys verbs to .35α.
- **T2.2** `Molecules.drawCardFlagStrip` shipped at `Molecules.lua:2182`. 28px (480w) / 24px (220w) bar: dim "MARKED" label + 3 chips composed via `Atoms.drawFlagChip`. ASCII glyphs `*` / `o` / `x` (placeholders for `★` / `⊘` / `✕` if Fira supports them at molecule layer).
- **T2.3** `Molecules.drawCardProgressBand` shipped at `Molecules.lua:2244` + new file `ItemActionManager.lua` (123 LOC). Molecule queries `ZeD.ItemActionManager.getActiveAction(item)` — returns 0 when idle (zero per-frame cost). Manager exports `registerObserver / unregisterObserver / getActiveAction / notify / clear`. Real PZ TimedAction wiring deferred to S121 organism.
- **T2.4** `Molecules.drawCardVerbStrip` shipped at `Molecules.lua:2268`. Right-aligned text-label buttons with optional small glyph prefix at 480w; glyph hidden at 220w. **Returns `{h, leftEdge}`** so caller can position other content to its left. **Empty list = no render** (books skip strip entirely per locked rule). Existing icon-only `drawVerbStrip` (M16, S118) kept intact for zone-dock use.

**Naming choice:** prefixed all four with `drawCard*` to coexist with the S118 `drawVerbStrip` (icon-only zone-dock variant). Avoids rename churn on S118 callers.

### Phase 3 — Content Molecules + Namespace Rename (DONE)

- **T3.x** `Molecules.drawCardStatRow` shipped — single key:value row in v13 voice (T.fontF1 mono accent label, T.fontF2 sans value, optional cond-dot, optional fixed-width label column for 220w 80px gutter spec).
- **T3.1** `Molecules.drawTopStatsGrid` shipped — 56px item icon + 2-col grid (16px col gap, 4px row gap). Composes `drawCardStatRow` per cell.
- **T3.2** `Molecules.drawTopStatsList` shipped — single column with fixed 80px label gutter. Iterates `drawCardStatRow` with `fixedLabelW=80`.
- **T3.3** Four facts primitives shipped: `drawFactsTitle` (sans 14/12, weight 600), `drawFactsRuleThick` (2px text), `drawFactsRuleThin` (1px border), `drawFactsRow` (label + mono-bold value + optional sub-indent + value class).
- **T3.4** `ZeD.ClothingDetail` → `ZeD.ItemDetail` complete. Mod-wide grep returned zero `ClothingDetail` references; 12 `ZeD.ItemDetail` refs intact across 3 files (`ItemCard.lua`:8 [definition], `EquipmentTab.lua`:2, `ZeD_CharacterWindow.lua`:2). Explore agent had missed CharacterWindow consumer; live grep caught it. FocusManager wiring untouched (rename was string-only at the call sites).

### Phase 4 — PZ Probes + Facts Panels (DONE — probes deferred to live cycle)

- **T4.0** PZ probes deferred to live PZ test cycle. The four blocking probes (Q125 `getInsulation`, Q126 `getWindResistance`, Q127 food cooking-time getters, Q128 burning-state path) couldn't be run from the editor — they need a live engine. Defense factory handles probe-nil gracefully via `safeGet` + per-row `needsProbe = true` flag (the v13 `★ needs-probe` badge convention). Q127/Q128 concern Progress Band runtime state, not the static facts panel — they belong with the S121 organism wiring. **PZAPI-KB Q125-Q128 entries pending — to be filled at live cycle.**
- **T4.1-T4.5** Five factories shipped to new file `ItemFactsPanel.lua` (380 LOC):
  - `DefenseFacts` (clothing) — bite/scratch/bullet + insulation/wind/water/neck + cond loss. `hasDisclosure = true` for 220w (zones compete). Lines 67-131.
  - `NutritionFacts` (food) — hunger/thirst + calories/protein/fat/carbs + sickness/boredom/happiness. Lines 133-186.
  - `CombatFacts` (HandWeapon) — damage range + reach + swing + knockback/crit + condition + ammo. Lines 188-241.
  - `ContainerFacts` (`item:getInventory() ~= nil`) — capacity + item count + weight reduction. Lines 243-281.
  - `ReadingFacts` (Literature) — skill + level range + page progress + read state + recipe count. Lines 283-335.
- **T4.6** Registry at line 337, `factsFor(item)` dispatcher at line 348, late-register hook `register(key, factory, priority)` at line 366. Priority order is most-specific first: reading → nutrition → combat → defense → container (so a bag-of-food shows the food's nutrition, not the bag's container stats).

### Closeout

- **Atoms.lua** 778 → 1002 (+224)
- **Molecules.lua** 3453 → 3976 (+523)
- **NEW ItemActionManager.lua** 123 LOC (T2.3 scaffold — S121 organism wires real PZ TimedActions)
- **NEW ItemFactsPanel.lua** 380 LOC (T4 registry + 5 factories)
- **3 files renamed** (`ClothingDetail` → `ItemDetail`): ItemCard.lua / EquipmentTab.lua / ZeD_CharacterWindow.lua. 12 refs intact, FocusManager wiring preserved.
- **Version bump**: `0.1.1180205h` → `0.1.1200205c` in `42/mod.info`.

**Phase 5 (organism) + Phase 6 (integration) deferred to S121** — hard cap honored. Test matrix (5 types × 2 widths × 3 states = 30 cells) is S121's verification work.

## Engine quirks discovered

(none new in S120 — Phase 4 PZ probes Q125-Q128 still pending live cycle)

## Open questions / probes

- **Q125-Q128 still open** — see Phase 4 closeout. Each Facts row that depends on a probed value uses `needsProbe = true` so the renderer can show the v13 `★` placeholder.
- **Live cycle items to verify after this commit lands:**
  - ProgressBand atom renders correctly in active + danger at both widths
  - FlagChip border-darkening via `colorBlend` reads cleanly against each kind's bg
  - `x` ASCII fallback for cancel button — if Fira renders `✕` (U+2715) cleanly, swap glyph at the molecule call site
  - ASCII flag glyphs `* / o / x` — same: swap to `★` / `⊘` / `✕` if Fira covers them
  - ItemDetail rename: gamepad-X dispatch on equipment slot still triggers repair / remove-patch
  - No `Kahlua | error loading | unexpected symbol | attempt to call.*nil` lines in latest `Logs/<DDMM>/*DebugLog.txt`

## Deferred to S121

- Phase 5 — ItemCard organism assembly (width-aware dispatch, state-aware Progress Band, item-type Facts dispatch via registry, source-context verb cluster)
- Phase 6 — Integration. Equipment tab card site + Inventory list card site. Test matrix: 5 types × 2 widths × 3 states = 30 cells

## Open questions / probes

- Q125: `getScriptItem():getInsulation()` — does it exist? type? range? per-frame stable? (Phase 4)
- Q126: `getScriptItem():getWindResistance()` — same (Phase 4)
- Q127: Food cooking time getters — probe `getCookingTime()` + `isCooked()` + `getCookedTime()` permutations (Phase 4)
- Q128: Burning state path — probe `isBurnt()` + heat/time threshold (Phase 4)
