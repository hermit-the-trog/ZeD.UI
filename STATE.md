# ZeD-UI — STATE

One page. What is true right now. Rewritten at every closeout, never appended to.
History lives in `archive/PROJECT_STATE.md` (through S122) and `ZeDUI/deltas/`.

**Version:** `0.1.1231210e` (S123, Oct 12 2026) · **Game:** Build 42 stable 42.20.2 (vanilla Lua last touched Oct 6 2026) · **Last code change:** Oct 12 2026
**Next session:** S124 — Dude's review of the contact sheet + gap list, then the first unreplaced vanilla surface (design first). See Target.

## What ships

- Character Window: Loot · Equip · Health · Thermal · Identity · Journal (3 sub-tabs) · Skills · Radio (contextual). Drawer = universal detail surface; ItemCard with Progress Band (reading / cooking with burn danger / repairing), cancel, rename, 220w/480w presets.
- World Window: Loot · Craft · Build · Maps · Forage · Animals · Radio. Mirrored chrome, container strip, multi-column inventory.
- Context menu: single horizontal strip, 114 `fi-br-*` icons, first-word fallback, System 7 paper/ink.
- Theme engine: 3 bases (dark, hicon, light) × 9 accents × 2 text sizes (`shared/ZeD/Tokens.lua`). Fonts: Fira Mono + Fira Sans Condensed bitmap `.fnt`.
- Gamepad: S113 flat free-nav, every tab in both windows has a focusable builder. Sub-tab pills (Journal, Animals) now switch on A, not on focus. F9 debug overlay only in gamepad mode.
- **QA bridge (dev, `-debug` only):** `QABridge.lua` polls `Zomboid/Lua/zedqa.go` and runs `Zomboid/Lua/zedqa.lua` in-game. Suites in `ZeDUI/tools/qa/`. Contact sheet in `ZeDUI/qa/S123_contact_sheet/`.

## Gamepad model (locked S113 · design director, confirmed Oct 11 2026)

D-pad = navigate (cone-nav; U/D never leaves the panel, L/R crosses; left-biased like reading). A = left mouse. X = right mouse / context menu (hold = drag). B = contextual cancel only. Y = window-pair toggle (hold = close both). LB = Character window, RB = World window (absolute, not toggle). Tabs and sub-tab pills switch on A, not on focus. Focus paints exactly like mouse hover. Chords welcome where they stay predictable. Full spec: `GAMEPAD_SPEC.md`.

## Verified live on stable 42.20.2 (S123, via the bridge, zero mod errors)

Load · window pair · all 13 tabs + Journal's 3 sub-tabs · every ItemCard header verb (UNEQUIP, EQUIP clothing, EQUIP 2H weapon, READ, EAT, DROP, TAKE) with live verb-context · rename · Progress Band reading + cancel · Progress Band cooking on a real stove with BURNING danger · context-menu organism (open, nav, cancel; KBM anchor at cursor) · Radio tab on equip · multi-container columns · simulated D-pad in both windows · row A/X/B callbacks · activate on representative elements of every tab · theme 3 bases × 2 sizes + 9 accents · pair close/reopen keeps vanilla pages hidden · scroll-follow on Journal Recipes after the perf fix.

Fixed in S123: five dead verb names; stale verb cluster; translator WARNs; Progress Band never lit (queue keyed by character, not playerNum); reading fallback nil window accessor; stale gamepad zone after a mouse tab click; card cancel fallback throwing on unstarted actions; recipe lists rebuilding focusables every frame (Journal Recipes −3.9 ms/frame).

## Known broken / unverified

1. **Nothing was exercised with a physical controller.** A/X/Y hold timers, LB/RB chords and hold-X drag need one. Re-check the S122 context-menu anchor report with the controller attached. Cone pick from the main inventory leftward into the Journal Recipes list landed on an inventory row in simulation — check on hardware.
2. On a fresh world load, before the first ZeD open, the vanilla collapsed inventory/loot strips show at the top (hidden forever after the first open).
3. Container strip lists only equipped bags + key rings; a bag lying in the main inventory has no tab until worn (design question, not changed).
4. Deferred from S113: grid-scroll surfaces (Identity, Forage) keep the `onDpadDir` adapter; hold-X drag has no visual feedback.

## Target — S124 and after

**Playable floor = full gamepad parity.** Dude tests on gamepad only.

1. Dude reviews `ZeDUI/qa/S123_contact_sheet/` and the gap list below; decides the first vanilla surface to replace and whether the container-strip rule changes.
2. Gap list (zero ZeD coverage today, all vanilla chrome in play): B42 entity windows (crafting stations, build), vehicles (dashboard, radial, mechanics), hotbar, moodles/clock (Java), fishing, farming, fluid transfer, camping/BBQ/generator info, printed-media reader, sleeping, moveables, safehouse, trading, survival guide, feeding trough. Recommended order by session frequency: entity crafting stations → hotbar → vehicle dashboard/mechanics → fluid transfer.
3. Controller session on the QA save with the bridge logging (`suite_gamepad` + the F9 overlay).
4. Parked design: rotary menu for the most-used verbs (post-floor).

## Rules that bind every session

No `border-radius`. 1px borders (2px on High Contrast). No surface shadows, no blur. Fira only. No emoji. Atoms → Molecules → Organisms; read `ZeD.T` fresh each frame; no `Tokens.lua` mutation. Hard Rule #11: no L3/R3 bindings, ever. QA only in the zombie-free QA save (`Saves/Sandbox/2026-10-12_10-19-20`). Never skin vanilla. Full rule set: `GLOSSARY.md` and the design-rule sections in `archive/PROJECT_STATE.md`.

## Where things are

`42/media/lua/client/ZeD/` code · `shared/ZeD/Tokens.lua` tokens · `PZAPI-KNOWLEDGE-BANK.md` 131 engine quirks + Q125–Q128 answers (read the Q you need, not the file) · `KAHLUA-JAVA-BACKEND.md` · specs: `GAMEPAD_SPEC.md` `CONTEXT_MENU_SPEC.md` `TOOLTIP_SPEC.md` `CRAFTING_SPEC.md` `FORAGING_SPEC.md` `PROTECTION_SPEC.md` `TYPOGRAPHY_DECISION_PAIRING_D.md` · `ZeDUI/mockups/` (39, equipment card v13/v15/v16 are the ItemCard canon) · `ZeDUI/deltas/` session journals · `ZeDUI/tools/qa/` bridge suites · `ZeDUI/qa/` contact sheets · `reference/` engine research · `archive/` retired docs.
Design system (tokens, components, brand book): the ZeD-UI Design System artifact on claude.ai.
