# ZeD-UI — STATE

One page. What is true right now. Rewritten at every closeout, never appended to.
History lives in `archive/PROJECT_STATE.md` (through S122) and `ZeDUI/deltas/`.

**Version:** `0.1.1231210f` (S123, Oct 12 2026) · **Game:** Build 42 stable 42.20.2 (vanilla Lua last touched Oct 6 2026) · **Last code change:** Oct 12 2026
**Next session:** S124 — mockups for the four planned surfaces (screen icons, CaZio watch, dashboard, mechanics) + the UI scale axis. See Target.

## What ships

- Character Window: Loot · Equip · Health · Thermal · Identity · Journal (3 sub-tabs) · Skills · Radio (contextual). Drawer = universal detail surface; ItemCard with Progress Band (reading / cooking with burn danger / repairing), cancel, rename, 220w/480w presets.
- World Window: Loot · Craft · Build · Maps · Forage · Animals · Radio. Mirrored chrome, container strip, multi-column inventory. **Maps unfold** into a centred pop-out (toolbar button, A on the fold placeholder, B folds; the Map key / mini-map / D-pad wheel / HUD button all open it — `Overrides/WorldMap.lua`).
- Context menu: single horizontal strip, 114 `fi-br-*` icons, first-word fallback, System 7 paper/ink.
- Theme engine: 3 bases (dark, hicon, light) × 9 accents × 2 text sizes (`shared/ZeD/Tokens.lua`). Fonts: Fira Mono + Fira Sans Condensed bitmap `.fnt` (1x–4x sets shipped).
- Gamepad: S113 flat free-nav; every tab in both windows has a focusable builder; sub-tab pills switch on A; **capability-driven button prompts** in every window footer (derived from the focused element's callbacks); UI sounds on focus / A / B; F9 overlay gamepad-only.
- Dev: `QABridge.lua` (`-debug` only) runs `Zomboid/Lua/zedqa.lua` on a trigger file; suites in `ZeDUI/tools/qa/`; contact sheets in `ZeDUI/qa/`; `HOOK_MAP.md` lists every vanilla UI entry point with its status.

## Gamepad model (locked S113 · design director, confirmed Oct 11 2026)

D-pad = navigate (cone-nav; U/D never leaves the panel, L/R crosses; left-biased like reading). A = left mouse. X = right mouse / context menu (hold = drag). B = contextual cancel only. Y = window-pair toggle (hold = close both). LB = Character window, RB = World window (absolute, not toggle). Tabs and sub-tab pills switch on A, not on focus. Focus paints exactly like mouse hover. Chords welcome where they stay predictable. Full spec: `GAMEPAD_SPEC.md`.

## Verified live on stable 42.20.2 (S123, via the bridge, zero mod errors)

Load · pair · all 13 tabs + Journal sub-tabs · every ItemCard header verb with live verb-context · rename · Progress Band reading + cancel + cooking danger on a real stove · context-menu organism · Radio tab on equip · multi-container columns · simulated D-pad in both windows · row A/X/B callbacks · activation on representative elements of every tab · 3 bases × 2 sizes × 9 accents · pair close keeps vanilla hidden · scroll-follow on Journal Recipes after the perf fix · **map pop-out open / pan / fold by B / fold by click / open via `ISWorldMap.ToggleWorldMap`** · body figure fits its box for a female character.

Fixed in S123 (18 commits): five dead verb names; stale verb cluster; translator WARNs; Progress Band never lit (queue keyed by character); reading fallback nil accessor; stale gamepad zone after mouse tab clicks; card cancel fallback throwing on unstarted actions; recipe lists rebuilding focusables every frame; **oversized body silhouette (female atlas scaled on the male canvas)**; missing dash glyphs and "-1" level range on cards; "17 of 17 injured" for a merely hungry character.

## Known broken / unverified / design items

1. **Nothing was exercised with a physical controller.** A/X/Y hold timers, LB/RB chords, hold-X drag, the S122 context-menu anchor report, and the real feel of the prompt strip + sounds need one.
2. **No female skeleton asset** — `fig-bg-*.png` is male; the female figure shows a dim `f-body.png` silhouette instead (design asset needed).
3. **Resolution scaling (open).** The engine ships ZeD fonts at 1x–4x and exposes a font-size option (`getCore():getOptionFontSize()` — **2 on Dude's 3840×2160 rig**); ZeD text already follows it, ZeD layout tokens do not, which is why the windows look tight at 4K. `T.scale` (1.0 / 1.15) is read in only 9 places; window widths (372 + 36 + 36), strip sizes and most row metrics are file constants. Plan: (a) add an `xlarge` TextSize preset for ≥1440p/4K using the 2x fonts, (b) make every window constant token-derived (`T.scale`), (c) auto-pick by screen height when nothing is persisted. Multi-session; audit = numeric literals in the two window files.
4. On a fresh world load before the first ZeD open, the vanilla collapsed inventory strips show at the top.
5. Container strip lists only equipped bags + key rings (design question).
6. Deferred from S113: grid-scroll surfaces (Identity, Forage) keep the `onDpadDir` adapter; hold-X drag has no visual feedback.

## Target — S124 and after

**Playable floor = full gamepad parity.** Dude tests on gamepad only.

1. Mockups first (the ItemCard rule), then build, in this order unless Dude reorders: **screen icons** (`ISEquippedItem`), **CaZio watch** (Java clock replacement + weather/speed), **vehicle dashboard** (`ISPlayerDataObject.vehicleDashboard`), **vehicle mechanics** (`ISOpenMechanicsUIAction`). Entry points and design targets in `HOOK_MAP.md`.
2. UI scale axis (item 3 above).
3. Controller session on the QA save with the bridge logging.
4. Then the rest of the HOOK_MAP gaps by session frequency: entity crafting stations → hotbar → fluid transfer → the info cards.

## Rules that bind every session

No `border-radius`. 1px borders (2px on High Contrast). No surface shadows, no blur. Fira only. No emoji. Atoms → Molecules → Organisms; read `ZeD.T` fresh each frame; no `Tokens.lua` mutation. Hard Rule #11: no L3/R3 bindings, ever. QA only in the zombie-free QA save (`Saves/Sandbox/2026-10-12_10-19-20`). Never skin vanilla. **Any vanilla script that shows UI gets hooked at its entry point and designed for** (`HOOK_MAP.md`). Full rule set: `GLOSSARY.md` and the design-rule sections in `archive/PROJECT_STATE.md`.

## Where things are

`42/media/lua/client/ZeD/` code (`Overrides/` = vanilla hooks) · `shared/ZeD/Tokens.lua` tokens · `HOOK_MAP.md` vanilla UI ledger · `PZAPI-KNOWLEDGE-BANK.md` 131 engine quirks + Q125–Q128 answers · `KAHLUA-JAVA-BACKEND.md` · specs: `GAMEPAD_SPEC.md` `CONTEXT_MENU_SPEC.md` `TOOLTIP_SPEC.md` `CRAFTING_SPEC.md` `FORAGING_SPEC.md` `PROTECTION_SPEC.md` `TYPOGRAPHY_DECISION_PAIRING_D.md` · `ZeDUI/mockups/` (39) · `ZeDUI/deltas/` session journals · `ZeDUI/tools/qa/` bridge suites · `ZeDUI/qa/` contact sheets · `reference/` engine research · `archive/` retired docs.
Design system (tokens, components, brand book): the ZeD-UI Design System artifact on claude.ai.
