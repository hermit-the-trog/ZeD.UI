# Session 123 Delta — Oct 12, 2026

Boot version: `0.1.1220305j` (last commit `85313e9a` — S122, May 3 2026)
Baseline commit: `85313e9a` — S122 ItemCard dynamic state layer + cancel + rename + 480w polish
Close version: `0.1.1231210d` (commits: `3fbb621d` verbs + doc reorg, final closeout commit below)

> **Boot mode active.** Ambient capture as decisions land. Custodian flushes to canon at closeout.
> **NB:** The Oct 11 2026 doc reorg (STATE.md replaces PROJECT_STATE.md; retired docs → `archive/`) was never committed. Staged and committed as the first act of S123.

## Session target

S123 — stable-42 recovery. Fix the dead ItemCard verbs, run the mod on stable (42.20.2, vanilla Lua last touched Oct 6 2026) for the first time, fix what `console.txt` shows. Goal behind the goal: QA-ready for a long gamepad play session.

## Boot audit (code vs stable sources)

Every member the mod calls on the seven vanilla classes changed in the Oct 6 update was checked against `E:\...\media\lua`, including through the `local CM = ISInventoryPaneContextMenu` alias in ItemCard. Result: exactly five dead references, all in `ZeD_ItemCard:_dispatchHeaderVerb`:

| Dead (never existed in stable) | Stable name |
|---|---|
| `CM.onWear` | `onWearItems(items, player)` |
| `CM.onEquipWeapon`, `CM.onEquipPrimary` | `OnPrimaryWeapon(items, player)`, `OnTwoHandsEquip(items, player)`, `equipWeapon(weapon, primary, twoHands, player)` |
| `CM.OnReadBook`, `CM.OnRead` | `onLiteratureItems(items, player)`, `readItem(item, player)` |

Everything else resolves. Audit lesson: a plain `ISInventoryPaneContextMenu\.\w+` grep misses alias references — audit `local X = Class` aliases too.

## Milestones / shipped work

### Dead verbs fixed (ItemCard.lua `_dispatchHeaderVerb`) — pending live verify
- EQUIP clothing → `onWearItems`. EQUIP weapon → `OnTwoHandsEquip` when `isTwoHandWeapon()`, else `OnPrimaryWeapon`, fallback `equipWeapon`.
- UNEQUIP → `unequipItem` (extinguishes lit candle/lantern first), fallback raw `ISUnequipAction`.
- READ → `onLiteratureItems` (illiterate / skill-level / tag guards), fallback `readItem`.

### Verb cluster refresh after verb fires (S122 carryover) — pending live verify
New `ZeD_ItemCard:_effectiveContext()` re-derives sourceContext each render from item state: equipped → `"equipped"`; container is player inventory → `"inventory"`; container type `"floor"` → `"ground"`; other container → `"container"`; unreadable → stored stamp. `render()` passes it to `renderBody` instead of the stored stamp. Fixes "EQUIP still shows after equipping until re-select".

### Debug noise
`ZeD.ContextMenu.Registry.DEBUG_LOG_UNKNOWN_ICONS` → `false`.

## User decisions captured at boot

(none yet — target was pre-approved at S122 closeout)

## Incident — Rising character died during the first live run

Loaded the Rising save (Aug 6 2026) via CONTINUE for the stable smoke test. The game auto-paused on focus loss while desktop control stole focus between actions; a zombie closed in during an unpaused burst and killed the character the moment the speed was set back to Play. PZ saved the death. Did NOT press "Continue with new character" — that is Dude's call. Quit to menu and built a dedicated zombie-free Sandbox QA save instead. Rule going forward: QA only ever runs in the QA save.


## Engine quirks discovered

(populated as the live run surfaces them)

## Open questions / probes

- Context-menu mispositioning on keyboard RMB (S122 carryover): anchor code already uses `getMouseX/Y`; suspect `InputModeDetector.getMode()` reporting `"gamepad"` during a KBM right-click (Q99 oscillation). Verify live.
- Q125–Q128 cooking/insulation probes still pending.

## Deferred

(populated at closeout)

## Live verification on stable 42.20.2 (Oct 12 2026, QA save `Saves/Sandbox/2026-10-12_10-19-20`)

Mod loads with zero Lua/Java errors through world load, window-pair open, and verb dispatch. First live run since the Oct 6 vanilla update.

### Lua bridge (the S124 harness seed, working today)
Debug mode is on (`-debug` Steam launch option) so the in-game Command Console has a Lua line. Typed once per game session (key-by-key; clipboard paste does not reach the LWJGL text field):
```
function zq() local r=getFileReader('zedqa.lua',false) local s='' local l=r:readLine() while l do s=s..l..string.char(10) l=r:readLine() end r:close() print('zedqa',pcall(loadstring(s))) end
```
Then any test is: write `C:\Users\danie\Zomboid\Lua\zedqa.lua` from the shell → type `zq()` in the console → grep `ZEDQA` in `console.txt` (strip NULs with `tr -d '\000'`). Scripts schedule follow-up checks with an `Events.OnTick` counter so one `zq()` covers a whole sequence. `loadstring` exists in PZ's Kahlua.

### Verb dispatch results (temp `ZeD_ItemCard` + `_dispatchHeaderVerb`, real TimedActions)
| Verb | Item | Queue head | State after | `_effectiveContext()` |
|---|---|---|---|---|
| UNEQUIP | Bandeau (worn) | ISUnequipAction | pEq=false, worn 5→4 | equipped → inventory |
| EQUIP | Bandeau | (onWearItems) | pEq=true, worn 4→5 | inventory → equipped |
| READ | Base.Book | ISReadABook | — | inventory |
| EQUIP | Base.BaseballBat (2H) | ISEquipWeaponAction | primary = Baseball Bat | inventory → equipped |
| EAT | Base.Apple | ISEatFoodAction | — | inventory |
| DROP | Base.Apple | ISInventoryTransferAction | floor objects 0→1, container=floor | inventory → ground |
| TAKE | Base.Apple (floor) | (transferFromFloor, sync) | back in player inventory | ground → inventory |

Both S123 code changes are confirmed: the four dead verbs fire, and the verb cluster re-derives its context without re-selecting.

### Mouse-driven observations
- Clicking the Equipment tab opens the drawer leftward (right edge anchored), so the tab strip x shifts from ~559 to ~382 (frame coords). Tab-walk by pixel needs a screenshot per tab; the Lua bridge walk is the right tool.
- A mouse UNEQUIP click on the Bandeau card did not fire (the game was paused at that moment; `toggleBothPaired` and TimedActions both need speed > 0). Not a mod bug.

### Tab walk (bridge-driven, real strip click handlers)
Character: loot, equip, health, thermal, identity, journal, skills. World: loot, craft, build, maps, forage, animals. Every tab switched (`_activeTab` matched, drawer opened to w=924 in tab mode, loot snapped back to w=444), zero Lua errors across the whole walk. Radio tab not present (no radio in the QA save); Journal sub-tabs not exercised.

### Context-menu anchor probe (S122 carryover #3a)
`ISInventoryPaneContextMenu.createMenu(0, true, {apple}, 100, 100)` with the mouse at 527,2125: detector mode `kbm`, `_zedAnchorMode=cursor`, anchor = 527,2125 (the passed 100,100 correctly ignored), ZeD strip spawned at 327,1934 (400×193, centred on the cursor and flipped above it). **Not reproducible on keyboard-and-mouse alone.** The S122 report most likely came from `InputModeDetector.getMode()` returning `gamepad` while Dude's controller is attached; re-check with the controller plugged in.

### New noise found: `Translator.reportMissingArgumentsFromPastAbuse`
Six Java WARN lines per context-menu open: `Missing arguments for "Fluid_HoldingNone" / "Fluid_HoldingOneType" / "Fluid_HoldingTwoTypes"`. Something calls `getText` on these format-string keys with no arguments while the menu tree is built. See fix below.

### Fix: translator WARN on registry cache build
`ContextMenuRegistry.buildTranslatedCache` resolves every `ContextMenu_` / `IGUI_` / `Fluid_` icon-map key with `pcall(getText, key)`. Three fluid keys are Java format strings, so `Translator` logged `MissingFormatArgumentException` six times on the first menu open. Now `pcall(getText, key, "", "", "")` — extra args are ignored by keys without specifiers. Both edited files (`ContextMenuRegistry.lua` 767 lines, `ItemCard.lua` 1629 lines) compile-checked through the game's `loadstring` via the bridge: ok.

## Engine quirks discovered

- **Q129** `getText(key)` on a key whose string has `%1$s`-style specifiers throws inside Java; PZ catches it and logs `Translator.reportMissingArgumentsFromPastAbuse` WARN. Pad with blank args when resolving keys generically.
- **Q130** `loadstring` exists in PZ's Kahlua; `getFileReader(name, createIfMissing)` / `getFileWriter` resolve relative to `Zomboid/Lua/`. Together with the `-debug` Lua Command Line this gives a file-driven test bridge with no mod restart.
- **Q131** Stable `ISInventoryPaneContextMenu.unequipItem` returns silently when `isEquipped(item)` is false — including while an `ISEquipWeaponAction` for that item is still in the queue. Verb tests must wait for the equip to land before firing UNEQUIP.

## Deferred to S124

- Journal sub-tabs, Radio tab (needs a radio in the QA save), ItemCard rename input, Progress Band (cooking/reading live), multi-container columns, context-menu organism A/X interaction — none exercised live yet.
- Gamepad parity: nothing gamepad-side was exercised (no controller attached to the session). The bridge can drive `ZeD.Input.Focus` directly in S124.
- Context-menu anchor with the controller attached (S122 #3a re-check).
- S122 #3c cooking→burning danger (Q127/Q128), S113 deferred list.
- Fold the bridge into the mod as a proper dev module (`QABridge.lua`): poll `Zomboid/Lua/zedqa.lua` on a tick counter so the console bootstrap is unnecessary; write pass/fail to a results file; frame capture.
