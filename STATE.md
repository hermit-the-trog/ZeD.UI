# ZeD-UI — STATE

One page. What is true right now. Rewritten at every closeout, never appended to.
History lives in `archive/PROJECT_STATE.md` (through S122) and `ZeDUI/deltas/`.

**Version:** `0.1.1242300k` (S124, Oct 13 2026) · **Game:** Build 42 stable 42.20.2 (vanilla Lua last touched Oct 6 2026) · **Last code change:** Oct 13 2026
**Next session:** S125 - director plays the scaled UI on the 4K rig (pair, drawers, cards, HUD props, tooltips, map) + the controller pass; then the **vehicle mechanics tab** (mockup first, HOOK_MAP row 3), then the main menu (plan in `ZeDUI/deltas/SESSION_124_DELTA.md`). See Target.

## What ships

- Character Window: Loot · Equip · Health · Thermal · Identity · Journal (3 sub-tabs) · Skills · Radio (contextual). Drawer = universal detail surface; ItemCard with Progress Band (reading / cooking with burn danger / repairing), cancel, rename, 220w/480w presets.
- World Window: Loot · Craft · Build · Maps · Forage · Animals · Radio · **Vehicle** (contextual: a vehicle within reach; scanline car figure tinted by condition, parts by area, part cards with header verbs, a NEEDS checklist per verb, install pick list, repair recipes, footer confirmations, INSPECT before the vanilla look-over). Mirrored chrome, container strip, multi-column inventory. **Maps unfold** into a centred pop-out (toolbar button, A on the fold placeholder, B folds; the Map key / mini-map / D-pad wheel / HUD button all open it — `Overrides/WorldMap.lua`).
- Context menu: single horizontal strip, 114 `fi-br-*` icons, first-word fallback, System 7 paper/ink.
- Theme engine: 3 bases (dark, hicon, light) × 9 accents × 2 text sizes (`shared/ZeD/Tokens.lua`). Fonts: Fira Mono + Fira Sans Condensed bitmap `.fnt` (1x–4x sets shipped).
- Gamepad: S113 flat free-nav; every tab in both windows has a focusable builder; sub-tab pills switch on A; **capability-driven button prompts** in every window footer (derived from the focused element's callbacks); UI sounds on focus / A / B; F9 overlay gamepad-only.
- HUD: the vanilla left-edge window buttons are hidden (`Overrides/ScreenIcons.lua`, S124); hand slots stay until the screen-icons surface.
- Dev: `QABridge.lua` (`-debug` only) runs `Zomboid/Lua/zedqa.lua` on a trigger file; suites in `ZeDUI/tools/qa/`; contact sheets in `ZeDUI/qa/`; `HOOK_MAP.md` lists every vanilla UI entry point with its status.

## Gamepad model (locked S113 · design director, confirmed Oct 11 2026)

D-pad = navigate (cone-nav; U/D never leaves the panel, L/R crosses; left-biased like reading). A = left mouse. X = right mouse / context menu (hold = drag). B = contextual cancel only. Y = window-pair toggle (hold = close both). LB = Character window, RB = World window (absolute, not toggle). Tabs and sub-tab pills switch on A, not on focus. Focus paints exactly like mouse hover. Chords welcome where they stay predictable. Full spec: `GAMEPAD_SPEC.md`.

## Verified live on stable 42.20.2 (S123, via the bridge, zero mod errors)

Load · pair · all 13 tabs + Journal sub-tabs · every ItemCard header verb with live verb-context · rename · Progress Band reading + cancel + cooking danger on a real stove · context-menu organism · Radio tab on equip · multi-container columns · simulated D-pad in both windows · row A/X/B callbacks · activation on representative elements of every tab · 3 bases × 2 sizes × 9 accents · pair close keeps vanilla hidden · scroll-follow on Journal Recipes after the perf fix · **map pop-out open / pan / fold by B / fold by click / open via `ISWorldMap.ToggleWorldMap`** · body figure fits its box for a female character.

Fixed in S123 (20 commits): five dead verb names; stale verb cluster; translator WARNs; Progress Band never lit (queue keyed by character); reading fallback nil accessor; stale gamepad zone after mouse tab clicks; card cancel fallback throwing on unstarted actions; recipe lists rebuilding focusables every frame; per-frame corpse-title error after a death; **oversized body silhouette (female atlas scaled on the male canvas)**; missing dash glyphs and "-1" level range on cards; "17 of 17 injured" for a merely hungry character; vanilla strips visible on a fresh load before the first open.

## Known broken / unverified / design items

1. **Nothing was exercised with a physical controller.** A/X/Y hold timers, LB/RB chords, hold-X drag, the S122 context-menu anchor report, and the real feel of the prompt strip + sounds need one.
2. **No female skeleton asset** — `fig-bg-*.png` is male; the female figure shows a dim `f-body.png` silhouette instead (design asset needed).
3. **Resolution scaling: done (S124).** Root scale = screen height / 1080 x a mild font-option multiplier; tokens, text (distance-field Fira), borders, the HUD props, both windows, the tooltip frame and the embedded map labels draw in design units through `T.px`; a root change closes and reopens the pair. The global `getTextManager` is the `ZeD.TM` proxy (role fonts measure zoomed; explicit-zoom paths use `ZeD.Text.realTM()`). Left: the Java-drawn item tooltip (`ObjectTooltip`) keeps the engine size.
4. On a fresh world load before the first ZeD open, the vanilla collapsed inventory strips show at the top.
5. Container strip lists only equipped bags + key rings (design question).
5. Deferred from S113: grid-scroll surfaces (Identity, Forage) keep the `onDpadDir` adapter; hold-X drag has no visual feedback.

- **S124 (Oct 13) true UI scaling, phase 1:** `ZeD.Scale.root()` = screen height / 1080 x a mild font-option multiplier (4K rig = 2.0); `ZeD.Text` draws through the engine zoom path; five Fira roles baked as 64 px distance-field atlases (`ZeDUI/tools/fonts/bake_sdf.py`) on spare slots; the dashboard and watch scale from the root with crisp text at 1x and 2x (`ZeDUI/qa/S124_scale/`). The windows still draw at 1x with bitmap fonts until phase 2.
- **Loop 2 (13:00-19:25) shipped the v5 HUD props:** vehicle dashboard and CaZio watch rebuilt as physical props on PNG plates generated from the locked mockups (`ZeDUI/tools/plates/`): 19 dash designs (16 seen live), 8 watch faces + no-watch strip, every control on a vanilla verb, gamepad claim / cue / hint / cone-nav verified, passenger read-only. Java clock + speed controls parked off-screen (B42 ignores setVisible). Spec: `DASHBOARD_WATCH_SPEC.md`; crops: `ZeDUI/qa/S123_contact_sheet/`.


## Target — after S124 (director's order, Oct 13 2026)

**Playable floor = full gamepad parity.** Dude tests on gamepad only. Every surface starts as a mockup in `ZeDUI/mockups/` (the contract), then the build, then live QA on the QA save.

1. **Finish every World window surface** (HOOK_MAP rows, by how often a long session hits them):
   1. Crafting stations — B42 entity windows (row 1) with the oven / microwave timers (row 14): the Craft tab in station mode.
   2. Info cards — generator, campfire, barbecue, farm plot (rows 11, 12): one shared card pattern in the World drawer.
   3. Fluid transfer (row 8).
   4. Furniture info and placement (row 15).
   5. Animals tab additions — hutch, feeding trough, genome, tracks, butcher hook (rows 20-22).
   6. Animals in trailers (row 23) in the Vehicle tab.
   7. Keypad codes (row 25).
2. **Character window: hands and hotbar** — the equipped primary / secondary items move into the Character window (retires the rest of the vanilla left-edge column, row 6) and the hotbar is integrated (row 5).
3. **A home for moodles** (the Java `MoodlesUI`, row 7).
4. **Main menu** — CRT room mockup `ZeDUI/mockups/zed-main-menu-crt-v7_1.html`, plan in the S124 delta.
5. Controller session on the QA save with the bridge logging (any time the director has the pad in hand).

Character-window readers (printed media row 13, journal writing row 24), fishing tension (row 10), fluid info in ItemCard (row 9) and sleeping (row 16) stay queued after these.

## Rules that bind every session

No `border-radius`. 1px borders (2px on High Contrast). No surface shadows, no blur. Fira only. No emoji. Atoms → Molecules → Organisms; read `ZeD.T` fresh each frame; no `Tokens.lua` mutation. Hard Rule #11: no L3/R3 bindings, ever. QA only in the zombie-free QA save (`Saves/Sandbox/2026-10-12_10-19-20`). Never skin vanilla. **Any vanilla script that shows UI gets hooked at its entry point and designed for** (`HOOK_MAP.md`). Full rule set: `GLOSSARY.md` and the design-rule sections in `archive/PROJECT_STATE.md`.

## Where things are

`42/media/lua/client/ZeD/` code (`Overrides/` = vanilla hooks) · `shared/ZeD/Tokens.lua` tokens · `HOOK_MAP.md` vanilla UI ledger · `PZAPI-KNOWLEDGE-BANK.md` 142 engine quirks + Q125–Q142 answers · `KAHLUA-JAVA-BACKEND.md` · specs: `GAMEPAD_SPEC.md` `CONTEXT_MENU_SPEC.md` `TOOLTIP_SPEC.md` `CRAFTING_SPEC.md` `FORAGING_SPEC.md` `PROTECTION_SPEC.md` `TYPOGRAPHY_DECISION_PAIRING_D.md` · `ZeDUI/mockups/` (39) · `ZeDUI/deltas/` session journals · `ZeDUI/tools/qa/` bridge suites · `ZeDUI/qa/` contact sheets · `reference/` engine research · `archive/` retired docs.
Design system (tokens, components, brand book): the ZeD-UI Design System artifact on claude.ai.
