# ZeD-UI — STATE

One page. What is true right now. Rewritten at every closeout, never appended to.
History lives in `archive/PROJECT_STATE.md` (through S122) and `ZeDUI/deltas/`.

**Version:** `0.1.1231210d` (S123, Oct 12 2026) · **Game:** Build 42 stable 42.20.2 (vanilla Lua last touched Oct 6 2026) · **Last code change:** Oct 12 2026
**Next session:** S124 — the test loop (bridge → in-mod harness → gamepad drive). See Target.

## What ships

- Character Window: Loot · Equip · Health · Thermal · Identity · Journal (3 sub-tabs) · Skills · Radio (contextual). Drawer = universal detail surface; ItemCard with Progress Band (reading / cooking / repairing), cancel, rename, 220w/480w presets.
- World Window: Loot · Craft · Build · Maps · Forage · Animals · Radio. Mirrored chrome, container strip, multi-column inventory.
- Context menu: single horizontal strip, 114 `fi-br-*` icons, first-word fallback, System 7 paper/ink.
- Theme engine: 3 bases × 9 accents × 2 text sizes (`shared/ZeD/Tokens.lua`). Fonts: Fira Mono + Fira Sans Condensed bitmap `.fnt`.
- Gamepad: S113 flat free-nav, every tab in both windows has a focusable builder (`_buildPanelFocusables` / `_buildWorldPanelFocusables`). Joypad API migration complete (`JoypadButton.<n>:isDown`).

## Gamepad model (locked S113 · design director, confirmed Oct 11 2026)

D-pad = navigate (cone-nav; U/D never leaves the panel, L/R crosses; left-biased like reading). A = left mouse. X = right mouse / context menu (hold = drag). B = contextual cancel only. Y = window-pair toggle (hold = close both). LB = Character window, RB = World window (absolute, not toggle). Tabs switch on A, not on focus. Focus paints exactly like mouse hover. Chords welcome where they stay predictable. Full spec: `GAMEPAD_SPEC.md`.

## Verified live on stable (S123, first run since the Oct 6 update)

Mod loads clean: zero Lua/Java errors through world load, window pair, all 13 tabs (7 Character + 6 World, walked through the real strip click handlers), and every ItemCard header verb (UNEQUIP, EQUIP clothing, EQUIP 2H weapon, READ, EAT, DROP, TAKE) firing real TimedActions. Verb cluster re-derives its context after a verb (`ZeD_ItemCard:_effectiveContext`). Keyboard-and-mouse context-menu anchor is correct (cursor mode, live `getMouseX/Y`). Only vanilla map/asset errors remain in the log.

**How it was verified — the bridge (Q130):** `-debug` Lua Command Line + a one-line `zq()` that `loadstring`s `Zomboid/Lua/zedqa.lua`. Write the file from the shell, type `zq()`, grep `ZEDQA` in `console.txt`. Recipes for driving the fullscreen game (focus restore, click pattern, key names) are in the S123 delta and Claude's memory. **QA save:** `Saves/Sandbox/2026-10-12_10-19-20` — zombie population None. Never QA in Rising/Apocalypse: S123 killed the Rising character (zombie adjacent when the game unpaused). Dude decides what happens to that save.

## Known broken / unverified

1. Not exercised live yet: Journal sub-tabs, Radio tab (no radio in the QA save), ItemCard rename, Progress Band under real cooking/reading, multi-container columns, context-menu organism A/X interaction, hold-X drag.
2. **Nothing gamepad-side has been exercised on stable.** No controller was attached during S123. The S122 context-menu mispositioning report is most likely `InputModeDetector.getMode()` reading `gamepad` with the controller attached — re-check with it plugged in.
3. Carried from S122: cooking→burning danger state needs Q125–Q128 probes.
4. Deferred from S113, still open: Journal/Animals sub-tab pills live-switch on focus (should need A); grid-scroll surfaces (Thermal, Identity, Journal flyers, Forage) use the `onDpadDir` adapter, not real row focusables; hold-X drag has no visual feedback.

## Target — S124 and after

**Playable floor = full gamepad parity.** Dude tests on gamepad only; keyboard-and-mouse is not a real-world test.

1. S124 (Code): fold the bridge into the mod as a dev module (`QABridge.lua`: tick-poll `Zomboid/Lua/zedqa.lua`, run, write pass/fail to a results file, no console bootstrap). Then a self-test script that walks both windows, every tab and sub-tab, every verb, the rename input and the Progress Band, and drives `ZeD.Input.Focus` directly to simulate D-pad/A/X/B/Y so gamepad parity is checked without a controller. Claude drives the game; Dude reviews a contact sheet.
2. Then the "Known broken" list above, in order, until a multi-hour gamepad play session is worth Dude's time.
3. Parked design: rotary menu for the most-used verbs (post-floor).

## Rules that bind every session

No `border-radius`. 1px borders (2px on High Contrast). No surface shadows, no blur. Fira only. No emoji. Atoms → Molecules → Organisms; read `ZeD.T` fresh each frame; no `Tokens.lua` mutation. Hard Rule #11: no L3/R3 bindings, ever. QA only in the zombie-free QA save. Full rule set: `GLOSSARY.md` and the design-rule sections in `archive/PROJECT_STATE.md`.

## Where things are

`42/media/lua/client/ZeD/` code · `shared/ZeD/Tokens.lua` tokens · `PZAPI-KNOWLEDGE-BANK.md` 131 engine quirks (read the Q you need, not the file) · `KAHLUA-JAVA-BACKEND.md` · specs: `GAMEPAD_SPEC.md` `CONTEXT_MENU_SPEC.md` `TOOLTIP_SPEC.md` `CRAFTING_SPEC.md` `FORAGING_SPEC.md` `PROTECTION_SPEC.md` `TYPOGRAPHY_DECISION_PAIRING_D.md` · `ZeDUI/mockups/` (39, equipment card v13/v15/v16 are the ItemCard canon) · `ZeDUI/deltas/` session journals · `reference/` engine research · `archive/` retired docs.
Design system (tokens, components, brand book): the ZeD-UI Design System artifact on claude.ai.
