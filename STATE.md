# ZeD-UI — STATE

One page. What is true right now. Rewritten at every closeout, never appended to.
History lives in `archive/PROJECT_STATE.md` (through S122) and `ZeDUI/deltas/`.

**Version:** `0.1.1220305j` (S122, May 3 2026) · **Game:** Build 42 stable (vanilla Lua last touched Oct 6 2026) · **Last code change:** May 4 2026
**Next session:** S123 — stable-42 recovery, then the test harness. See Target.

## What ships

- Character Window: Loot · Equip · Health · Thermal · Identity · Journal (3 sub-tabs) · Skills · Radio (contextual). Drawer = universal detail surface; ItemCard with Progress Band (reading / cooking / repairing), cancel, rename, 220w/480w presets.
- World Window: Loot · Craft · Build · Maps · Forage · Animals · Radio. Mirrored chrome, container strip, multi-column inventory.
- Context menu: single horizontal strip, 114 `fi-br-*` icons, first-word fallback, System 7 paper/ink.
- Theme engine: 3 bases × 9 accents × 2 text sizes (`shared/ZeD/Tokens.lua`). Fonts: Fira Mono + Fira Sans Condensed bitmap `.fnt`.
- Gamepad: S113 flat free-nav, every tab in both windows has a focusable builder (`_buildPanelFocusables` / `_buildWorldPanelFocusables`). Joypad API migration complete (`JoypadButton.<n>:isDown`).

## Gamepad model (locked S113 · design director, confirmed Oct 11 2026)

D-pad = navigate (cone-nav; U/D never leaves the panel, L/R crosses; left-biased like reading). A = left mouse. X = right mouse / context menu (hold = drag). B = contextual cancel only. Y = window-pair toggle (hold = close both). LB = Character window, RB = World window (absolute, not toggle). Tabs switch on A, not on focus. Focus paints exactly like mouse hover. Chords welcome where they stay predictable. Full spec: `GAMEPAD_SPEC.md`.

## Known broken (Oct 11 2026 audit, code-level — not yet run on stable)

1. **ItemCard EQUIP and READ verbs are dead on stable.** `ItemCard.lua:748–795` dispatches to `ISInventoryPaneContextMenu.onWear`, `.onEquipPrimary`, `.onEquipWeapon`, `.OnReadBook`, `.OnRead` — none exist in stable. Stable names: `onWearItems`, `OnPrimaryWeapon`, `onLiteratureItems`. The `if CM.x then` guards make this a silent no-op, not an error.
2. Seven vanilla classes the mod hooks changed in the Oct 6 update: `ISInventoryPaneContextMenu`, `ISInventoryPane`, `ISInventoryPage`, `ISWorldObjectContextMenu`, `ISSearchManager`, `ISUnequipAction`, `ISFitnessUI`. Every other member the mod calls on them still exists; behaviour inside the wrapped `createMenu` / `prerender` / `render` is unverified until the game runs.
3. Carried from S122: context-menu mispositioning on keyboard right-click (anchor uses gamepad-derived position; should be `getMouseX(), getMouseY()`); verb cluster doesn't refresh after EQUIP until re-select; cooking→burning danger state needs Q125–Q128 probes.
4. Deferred from S113, still open: Journal/Animals sub-tab pills live-switch on focus (should need A); grid-scroll surfaces (Thermal, Identity, Journal flyers, Forage) use the `onDpadDir` adapter, not real row focusables; hold-X drag has no visual feedback.

## Target — S123 and after

**Playable floor = full gamepad parity.** Dude tests on gamepad only; keyboard-and-mouse is not a real-world test.

1. S123 (Code): fix the four dead verbs; run the mod on stable; fix what `console.txt` and the context-menu override show. Flip `ZeD.ContextMenu.Registry.DEBUG_LOG_UNKNOWN_ICONS` to `false` if the log is noisy.
2. S124 (Code): the test loop — a debug save + self-test module (seed: `TestInventory.lua`) that walks both windows, every tab, every verb, writes pass/fail to `console.txt` and captures frames; Claude drives the game on the PC; Dude reviews a contact sheet, not a play session.
3. Then the S122 carryover list and the S113 deferred list, in that order, until a multi-hour play session is worth Dude's time.
4. Parked design: rotary menu for the most-used verbs (post-floor).

## Rules that bind every session

No `border-radius`. 1px borders (2px on High Contrast). No surface shadows, no blur. Fira only. No emoji. Atoms → Molecules → Organisms; read `ZeD.T` fresh each frame; no `Tokens.lua` mutation. Hard Rule #11: no L3/R3 bindings, ever. Full rule set: `GLOSSARY.md` and the design-rule sections in `archive/PROJECT_STATE.md`.

## Where things are

`42/media/lua/client/ZeD/` code · `shared/ZeD/Tokens.lua` tokens · `PZAPI-KNOWLEDGE-BANK.md` 128 engine quirks (read the Q you need, not the file) · `KAHLUA-JAVA-BACKEND.md` · specs: `GAMEPAD_SPEC.md` `CONTEXT_MENU_SPEC.md` `TOOLTIP_SPEC.md` `CRAFTING_SPEC.md` `FORAGING_SPEC.md` `PROTECTION_SPEC.md` `TYPOGRAPHY_DECISION_PAIRING_D.md` · `ZeDUI/mockups/` (39, equipment card v13/v15/v16 are the ItemCard canon) · `ZeDUI/deltas/` session journals · `reference/` engine research · `archive/` retired docs.
Design system (tokens, components, brand book): the ZeD-UI Design System artifact on claude.ai.
