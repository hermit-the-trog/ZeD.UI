# Next Session Handoff
Generated: May 2, 2026 — Session 119 closing (brainstorm only, no code), S120 booting.

## Target
**S120 — BUILD the new ItemCard system, Phases 1–4 (atoms → universal molecules → content molecules → Facts panels).** S119 was a design-only session that locked the universal item card across five item types and three states. Three mockup files in `ZeDUI/mockups/` ARE the spec — no more design questions for this slice. Build to spec; surface anything unclear during execution rather than guessing. **Phase 5 (ItemCard organism) and Phase 6 (Equipment + Inventory integration) deferred to S121.** Don't try to fit them in S120 — that's the Code-stuck-15-minutes-back-to-Chat trap.

## Current state
Version `0.1.1180205h` (no code shipped in S119, no bump). Equipment-card primitives + `ZeD.ClothingDetail` namespace from S118 are still live and intact. S119 produced zero Lua diffs — all output is HTML mockups + this handoff.

## Spec sources (READ FIRST every S120 boot)
The three mockup files ARE the spec. Read them in order, every session boot until ItemCard ships:
- `ZeDUI/mockups/equipment_card_redesign_v13_refinements.html` — clothing canonical case. Chrome rules, no-line-rules-between-zones (padding-as-divider), verb strip text labels, flag strip system. **The chrome rules in v13 govern every card built in S120.**
- `ZeDUI/mockups/equipment_card_redesign_v15_both_widths.html` — five item types × two widths (220w + 480w). Top stats composition per type. Facts panel adapts: Defense / Nutrition / Combat / Container / Reading. **220w is the canonical browsing view — most-used, most-important.**
- `ZeDUI/mockups/equipment_card_redesign_v16_progress_states.html` — Progress Band element. Idle / active / danger states, position between back-bar and flag strip, color-shifts-not-chrome-shifts for danger.

## Build order — atoms up
**Phase 1 — Atoms.** Progress band shell + fill + cancel button. Flag chip with on/off states (3 instances: FAV / NO-CRAFT / DISPOSE). Zone dock action button (3 variants: repair ▲, remove-patch ✂, disabled checkmark ✓ — already shipped in S118). Audit `ZeD.Theme` against mockup tokens; add what's missing.

**Phase 2 — Universal molecules.** `BackBar`, `FlagStrip`, `ProgressBand`, `VerbStrip`. These compose into every card regardless of item type. `BackBar` accepts a verb cluster from caller — verbs adapt to source context (`equipped` / `inventory` / `container` / `ground`).

**Phase 3 — Content molecules.** `TopStatsGrid` (480w, 2x3 with item icon) + `TopStatsList` (220w, single column). Facts primitives: `factsTitle`, `factsRuleThick`, `factsRuleThin`, `factsRow`. Zone primitives stay in `ZeD.ClothingDetail` namespace (S118 work, kept as-is).

**Phase 4 — Facts panels (organisms).** Five panels: `DefenseFacts`, `NutritionFacts`, `CombatFacts`, `ContainerFacts`, `ReadingFacts`. Each is a registered factory `(item) → rows`. Registry in `ItemFactsPanel.lua` dispatches by item type. **ItemCard never branches on item class itself — it queries the registry.**

**Phase 5 (S121) — ItemCard organism.** Width-aware (220w vs 480w branches). State-aware (`idle`/`active`/`danger` drives Progress Band visibility). Item-type dispatch for Facts panel via registry. Source-context-aware verb cluster.

**Phase 6 (S121) — Integration.** Equipment tab wiring. Inventory list wiring. Test matrix: 5 types × 2 widths × 3 states = 30 cells minimum.

## Architecture decisions (locked, S119 closeout — these are dev-side, designer agnostic)
- **Source-context detection:** parent passes `sourceContext` enum into the card. `equipped | inventory | container | ground`. Cleaner contract than walking `item:getContainer()` from inside the card.
- **Progress band reactivity:** custom observer pattern, NOT `Events.OnTick`. Active cards register with the action manager; inactive cards pay zero cost. Action manager fires events on state change only (started, tick, completed, cancelled, danger-transition).
- **`ZeD.ClothingDetail` (S118) fate:** refactor in place. Preserves git history and FocusManager wiring. The namespace structure was always going to generalize — S118's `dispatchZoneAction` becomes the pattern for verb dispatch generally.

## Open PZ API probes (Phase 4 blocking)
Needed before Container Facts and the cooking Progress Band can pull real data. Schedule at top of Phase 4, not earlier:
- `getScriptItem():getInsulation()` — clothing + container thermal stat. Q24 carryover from S118.
- `getScriptItem():getWindResistance()` — same.
- `FoodItem` cooking progress getter. Probe `getCookingTime()` + `isCooked()` + `getCookedTime()` permutations and document the path.
- Burning state transition. `isBurnt()` exists, but the engine path from cooked → burning → burned is unclear. Time-based? Heat-based? Threshold? Probe + document.

## Known blockers
None for Phases 1–3. Phase 4 blocked on the four PZ probes above; do them at the start of Phase 4, not before.

## Warm context
- **Three universal molecules** (`BackBar`, `FlagStrip`, `VerbStrip`) compose every card. The card body content is item-type-specific but the chrome is universal. **Do not introduce per-item-type chrome variants** — that's a regression to pre-S119 architecture.
- **Flag strip data lives in modData.** ★ FAV / ⊘ NO-CRAFT / ✕ DISPOSE toggles persist via `item:getModData()`. Designer named these explicitly — don't rename without asking.
- **Progress Band cancel `[✕]` is the ONLY cancel path.** Back-bar verbs grey out while action active (`opacity: .35`, no cursor pointer). No duplicate cancel surfaces.
- **The relevant top-stat row mirrors the active state.** COOKED → "Cooking…" / "Burning…" while progress active. PROGRESS → mid-value while reading. CONDITION → mid-value while repairing. The stat row's text color matches the band's accent/danger.
- **No rules between zone groups, between sections, or above the verb strip.** Padding only. v13's hard rule, restated by designer with emphasis. The Defense/Nutrition/Combat/Container/Reading Facts panels DO keep their internal thick+thin rules — those are panel identity (Nutrition Facts pattern), not section dividers.
- **Books are the special case** — no maintenance verbs, no verb strip at all. Don't render an empty strip; conditional skip.
- **Defense Facts at 220w gets a disclosure** because zones compete for vertical space. **All other Facts panels at 220w are always-expanded** because no zones are competing. v15 spec; respect it.
- **Color carries urgency, chrome stays still.** Burning band uses the same DOM as cooking band, just `.danger` class flip. Same pattern for any future danger state (weapon failing, clothing tearing critically, etc.).

## Don't forget
- **BOOT ritual:** first action at S120 boot is `git log --oneline | head -30` cross-checked against PROJECT_STATE.md `Current: 0.1.1180205h`. Drift = halt and reconcile.
- **Pre-flight every test cycle:** grep latest `C:\Users\danie\Zomboid\Logs\<latest>\*DebugLog.txt` for `ERROR|Kahlua|ItemCard|EquipmentTab|attempt to call.*nil|attempt to index.*nil` before claiming clean. `ERROR: ModelManager` / `ERROR: Translation` are baseline noise.
- **Hot-reload unreliable; full PZ restart per test cycle.**
- **Version bump format:** `0.1.[session][DDMM]<suffix>`. First S120 commit is `0.1.120DDMMc`. Suffix walks `c→d→…→z→aa→ab→…`.
- **End-of-session ritual:** `git add . && git commit -m "S[N]: ..." && git push`. Code AND docs in same commit. Delta file (`ZeDUI/deltas/SESSION_120_DELTA.md`) opened at boot, flushed at closeout.
- **Custodian capture is AMBIENT** during the session — decisions land in the delta file as they happen, not at closeout.
- **The mockups are the spec.** When in doubt, re-read v13/v15/v16 before improvising. Don't build around what you remember — build around what the file says. The five mockup files (v9 through v16) are the design record; v13/v15/v16 are the LOCKED ones.
- **Phase ambition cap:** S120 stops at end of Phase 4. Even if time remains, write the closeout, tee up S121. Phases 5–6 need a fresh head and the Phase 4 work to be settled before integration begins.
