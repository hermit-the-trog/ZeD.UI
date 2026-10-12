# Session 123 Delta — Oct 12, 2026

Boot version: `0.1.1220305j` (last commit `85313e9a` — S122, May 3 2026)
Baseline commit: `85313e9a` — S122 ItemCard dynamic state layer + cancel + rename + 480w polish
Close version: `0.1.1231210f` (session closed 12:50; see the commit log for the S123 commits)

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

## Loop phase (11:10 → 14:00, autonomous)

### QABridge.lua shipped (dev module)
`42/media/lua/client/ZeD/QABridge.lua`: when `isDebugEnabled()`, polls `Zomboid/Lua/zedqa.go` every 30 ticks and runs `Zomboid/Lua/zedqa.lua` through `loadstring` when the trigger text changes. Installed into the running session via `zq()`; loads at boot from now on. No more console typing.

### Batch 1 (bridge-driven)
- Journal sub-tabs: 3 zones; switching 1→2→3 renders without error. PASS
- ItemCard rename: `_startRename` seeds the input with the current name, `_commitRename("QA Book")` sets name + custom flag, blank commit keeps the name, cancel leaves state clean. PASS
- Context-menu organism on an Apple: 6 items (Eat, Place Item, Favorite, Set Unwanted, Set Unusable in Recipes, Drop); next/prev/nextGroup/prevGroup/cancel all run without error. PASS (note: `isVisible()` still true right after `cancel()`; check whether close is deferred)
- **Progress Band: FAIL.** READ queued `ISReadABook` but `ItemActionManager.getActiveAction(book)` stayed nil for 120+ ticks, and the cancel fallback left the queue at 1. Investigating `ItemActionHooks` queue polling.
- **Container strip: FAIL?** A spawned `Base.Bag_Schoolbag` in the main inventory did not appear in `win._containers` (only Inventory* and Key Ring) after 100 ticks. Investigating `buildContainers`.

### Fix: Progress Band never lit (ItemActionHooks + ItemCard cancel fallback)
Root cause: vanilla keys `ISTimedActionQueue.queues` by the **character object** (`ISTimedActionQueue.lua:144`), but the S122 poller read `queues[playerNum]` → always nil → no start/tick ever reached `ItemActionManager`. Same bug in `ZeD_ItemCard:_dispatchProgressCancel`'s last-resort queue walk. Both now use `ISTimedActionQueue.getTimedActionQueue(p)`. Two more in the reading fallback: it referenced `ZeD_CharacterWindow.instance` (never existed; the accessor is `getWindow()`), and with two Literature items that both report -1 pages (novels, ID card) the "best pages" tie left `book` nil. Hot-loaded the fixed file through the bridge and re-ran: `head=ISReadABook active=true kind=reading label=READING pct=0.03 hasAction=true`; cancel via the card → queue 0, manager cleared. PASS.
Design note for Dude: the container strip lists only *equipped* bags plus key rings (`buildContainers`). A bag lying in the main inventory has no tab until it is worn. Vanilla shows every container item in the main inventory. Flagging, not changing.

### Simulated gamepad (FocusManager driven, detector locked to gamepad)
Claim → `charMainInv invrow:1`; down ×2 → `invrow:3`; right → `charTabContent journal:__kills`; right → `charContainerStrip container:1`; up stays; left → tab content; left ×2 → `jsub:3`, `jsub:2`. A/B/X/Y dispatch without error; Y tap kept the pair open (hide/unhide by state). Zero Lua errors.
**BUG found: stale charTabContent zone after a mouse tab click back to Loot.** The strip handler's loot branch (and same-tab toggle) never called `_syncRingZonesToActiveTab`; only the gamepad path (`_switchTabForNav`) did, and the per-frame catch-up rebuild is gated to non-loot tabs. Result: after Journal → Loot by mouse (or any non-gamepad switch), D-pad right from the inventory lands on invisible Journal pills. Fixed: both window strip handlers now sync after every click (`_syncRingZonesToActiveTab` / `_syncWorldRingZones`). Compile-checked via the bridge; live verification after the next restart (window constructors cannot be hot-loaded safely).

### Vanilla surfaces ZeD has NOT replaced (gap inventory for the design director)
Zero references in the mod to any of these; they appear as stock vanilla chrome during play:
- **B42 entity windows** (`ISEntityWindow`, `ISCraftBenchPanel`, `ISHandCraftPanel`, build/craft logic panels) — every crafting station, furnace, generator, and B42 build UI. Highest frequency in a long session.
- **Vehicles**: `ISVehicleDashboard`, `ISVehicleMenu` (radial), mechanics UI, seat/AC/lightbar panels.
- **Hotbar** (`ISHotbar`), **Moodles** (Java `MoodleUI`), clock/speed controls (Java).
- **Fishing** `TensionUI`, **Farming** `ISFarmingWindow`, **Fluid transfer** `ISFluidTransferUI` / `ISFluidContainerPanel`, **Camping/BBQ/Generator** info windows, `ISLiteratureUI` (printed media reader), `ISSleepingUI`, `ISMoveableInfoWindow`, `ISSafehouseUI`, `ISTradingUI`, `ISSurvivalGuide`, `ISFeedingTroughUI`.
Rule in force: never skin vanilla; each is a from-scratch build. Recommend ordering by session frequency: entity crafting stations → hotbar → vehicle dashboard/mechanics → fluid transfer → the rest.

### Batch 2 (bridge-driven, zero errors)
- World window gamepad: claim → `worldContainerStrip container:1`; right → `worldTabBar tab:loot`; after a strip click to Craft, D-pad down walks the tab bar (`tab:craft`, `tab:build`); back on Loot, left returns to the container strip — no stale zone. PASS
- Radio tab: equipping `Base.RadioRed` adds the contextual `radio` tab; focusables `radio:browsePrev → browseNext → seek-` reachable by D-pad. PASS
- Multi-container: wearing the schoolbag adds it to the strip (`cnt:3`); clicking `cnt:3` then `cnt:2` opens two MC columns (window 444 → 544 → 796), ring gains `charMC1(1)`/`charMC2(1)` (empty-column placeholders), D-pad right walks MC2 → container strip. PASS

### Batch 3 (gamepad A/X without a controller)
`Focus.dispatchJoypadDown` arms the A/X tap-vs-hold timers, but the OnTick resolver returns early when `getJoypadData(0)` is nil, so without a physical controller A/X never resolve. Not a bug — the resolver is engine glue. Element callbacks (`onActivate`, `onContextMenu`, `onCancel`) are driven directly in batch 4 instead. Hold-X drag is likewise untestable without a controller (needs `JoypadButton.X:isDown` over time).

### Batch 4 (element callbacks = what A/X fire; zero errors)
MC toggle-off by re-clicking `cnt:2`/`cnt:3` → window back to 444. `invrow:2.onActivate` opens the card (Apple, w=664); `invrow:3.onActivate` live-swaps (ID Card); again closes (444). `invrow:2.onContextMenu` spawns the ZeD strip with 6 items at the row; the strip's `onJoypadDown(B)` closes it. PASS

### Q125–Q128 probed (answers in PZAPI-KNOWLEDGE-BANK)
Insulation = `item:getInsulation()`; wind = `item:getWindresistance()` (lowercase r); cooking = `getCookingTime / getMinutesToCook / getMinutesToBurn / isCooked / isBurnt`; cooked/burnt flags only flip inside an activated heat container; cooking is not a TimedAction.

### Implemented: sub-tab pills switch on A (GAMEPAD_SPEC open item)
Journal `jsub:n` and Animals `animals:submode:*` focusables: `onFocus` is now a no-op (cue paint only), the switch moved to `onActivate`. Matches "tabs switch on A, never on focus".

### Implemented: cooking → Progress Band with danger state (S122 #3c)
`ItemActionHooks._pollCooking` watches each window's `_drawerItem`; when it is cookable Food inside an activated heat container it drives the Band: `active/COOKING` with minutes-to-cooked, then `danger/BURNING` with minutes-to-burnt once cooked (or past minutesToCook), `complete` on burnt or when the item leaves the card/heat. Emits "danger" on the mode flip so observers get `onDanger`.
Live stove test (microwave found as `IsoStove`): with the steak carded in the World window and the heat source activated, the Band reported `mode=danger label=BURNING time=26m` (the probe had left the steak flagged cooked); when the microwave deactivated itself the poller sent `complete` and the Band cleared. Cooking time did not advance in a microwave without its timer — real-stove progression untested but uses the same path. PASS for the plumbing.

### Post-boot verification (fresh Lua load of the QA save, zero errors)
QABridge armed itself at `OnGameStart`. Journal `jsub:2`: `onFocus` leaves the sub-tab at 1, `onActivate` switches to 2. Loot strip click → `charTabContent` empty, D-pad right → container strip (stale-zone bug gone). Real stove (`appliances_cooking_01_14`): Band `active/COOKING 50m` → after `setCookingTime(49)` `pct=0.98 time=1m`. Context menu opened post-boot with zero new translator warnings. F9 overlay now gated to gamepad mode.

### Focusable census (elements in the tab-content zone per tab)
Character: equip 30 · health 25 · thermal 26 · identity 2 · journal 1180 (1177 recipe rows on sub-tab 2 + 3 pills) · skills 60 · loot 0 (rows live in `charMainInv`).
World: craft 541 · build 77 · maps 14 · forage 3 · animals 6 · loot 0.
Identity/forage/animals are the S113 "grid-scroll via onDpadDir adapter" surfaces. Journal Recipes and World Craft register every recipe row and Journal Recipes is on an always-rebuild path — measuring frame cost next.

### Perf: frame cost of the recipe lists (bridge-measured, ms per tick, 180-tick windows)
loot 8.9 · journal sub-tab 1 8.4 · **journal Recipes 15.1** · skills 9.0 · **world Craft 10.8** · world loot 8.3. Attribution: `CC.buildFocusables` alone = 3.07 ms for 1177 Journal recipe rows, 2.07 ms for 541 Craft rows, and the S107 "always rebuild" gates ran it (plus `setRingZoneElements` and the 1177-element preserve-idx search) every frame. Off-screen rows must stay focusable (cone-nav needs targets below the viewport, CraftingCore.lua:1310), so the fix keys the rebuild on `scroll.scrollPos` + list geometry + dropdown state instead of every frame (both windows). Re-measured after the next reload.
After reload (same windows, noisier baseline right after world load): loot 10.4 · journal Recipes 13.1 (+2.8 vs +6.7 before) · world Craft 11.1 (+0.8 vs +2.5). Scroll-follow intact: forced focus on `jrecipe:catDrop`, D-pad down walks sort pills → rows; +30 presses lands on `ChopLog y=973`, scroll-follow moves the list (scrollPos 0 → 0.022), the next press goes to the correct neighbour (`churn_butter`), and after the keyed rebuild the row reports its new on-screen y (997 → 380). PASS
Observation for S124: from the main inventory, D-pad left on the Journal Recipes sub-tab landed on the next inventory row instead of a recipe row (cone pick), while the pills were reachable earlier. Needs a controller check; coordinates dumped in console.

### Batch 6 (A on representative elements of every tab, zero mod errors)
Health bodypart + exercise, Thermal pill + part, Identity disclosure, Skills header / pin / unpin / training row, Journal Flyers thumb (138 focusables on sub-tab 3), Journal kills disclosure, Maps disclosure + tools, Forage search stance on/off (`isSearchMode` back to false), Animals submode, Craft category dropdown open → pick `all` → 541 rows → row activate (opens the craft drawer). All `ok=true`. The only `tried to call nil` came from the harness calling a missing `onActivate` on `identity:__gridscroll` (A is a documented no-op there) — not a mod bug.

### Fix: card cancel fallback could throw (found via the debugger break)
The harness's old queue clear called `forceStop` on a queued-but-unstarted `ISWaitWhileGettingUp`; vanilla `ISBaseTimedAction:forceStop` does `self.action:forceStop()` and `self.action` is nil before `start()` → `attempted index: forceStop of non-table: null`, and with the debugger's **Break On Error** on, the game halts. `ZeD_ItemCard:_dispatchProgressCancel` had the same forceStop-everything fallback; it now calls vanilla `ISTimedActionQueue:clearQueue()` instead. Note for Dude: I unchecked *Break On Error* in the Lua debugger toolbar so automated runs do not halt the game; re-check it if you want halts during play.

### Suites saved: `ZeDUI/tools/qa/` (verbs, tabs, gamepad, band, perf + README)
All compile under the game's `loadstring`; `suite_gamepad` re-ran green after the reload. Caveat learned while re-running: a row that is a stack representative (two Steaks) toggles expand/collapse on A instead of opening the card (S113 design), so suites that index rows by position must avoid stacks.

### Pair closed → vanilla chrome check
With the ZeD pair closed (`toggleBothPaired`), the vanilla inventory/loot pages stay hidden (`isVisible()` false, collapsed). Only on a fresh world load *before the first ZeD open* do the vanilla collapsed strips show at the top of the screen — design note for Dude: hide them at `OnGameStart` or open the pair automatically on gamepad.

### Theme and text-size sweep (live `ZeD.applyTheme`, zero errors)
Bases `dark`, `hicon`, `light` × sizes `large`, `small` all applied and rendered (frames 19–22 in the contact sheet); accents available: blue, green, mono, orange, pink, purple, red, teal, yellow. Restored dark/orange/small.

### Contact sheet: `ZeDUI/qa/S123_contact_sheet/` (22 frames + README)
Every tab in both windows, the ItemCard with a live READING band, craft recipe card, and the theme sweep, captured at 4K through the bridge for review without a play session.

### Post-reload regressions
`suite_verbs` green on every expectation (worn Bandeau UNEQUIP → inventory → EQUIP → equipped; READ, 2H bat EQUIP/UNEQUIP, EAT, DROP → ground, TAKE → inventory). Accent sweep: all 9 accents applied live without error, restored orange.

## Max-effort block (12:05 → 14:00, director present)

### Director input captured
- Body silhouette behind the skeleton was far too large (contact sheet frames 01/02).
- Resolution scaling is still an open problem.
- Rule: if a vanilla script performs an action that shows UI, hook it and design for it.
- Map: an option to pop the map out into a larger centred, unfolded map, gamepad-compatible.
- Planned surfaces to add to the roadmap: vehicle dashboard, vehicle mechanics, CaZio watch, screen icons.
- Asked for UX suggestions; delivered seven (capability-driven prompts, UI scale axis, UI sounds, card data hygiene, last-action footer line, map pop-out as a mode, published hook map). Director: "those all sound great".

### Fixed: body figure scale (`ZeD_BodyFigure.lua`)
Root cause: the female part atlas is a 240×590 canvas while every fit / hit-test used the male 220×260 constants, and the skeleton backdrop was drawn into the raw panel rect instead of the fitted canvas rect. Female parts therefore spilled far outside the box. Now `_canvasFor(fig)` drives fit, `getDrawParams`, `hitTest` and `hitTestAt`; the male skeleton backdrop is drawn into the fitted rect (exact alignment); the female figure uses `f-body.png` as a dim base. **Design item:** there is no female skeleton asset — `fig-bg-*.png` is male only.

### Shipped: map pop-out (`MapsTab.lua`, FocusManager zone `popMapContent`)
Toolbar UNFOLD button (right end, `map:popout` focusable) opens a centred `ZeD_Window` at 72% × 78% of the screen holding a fresh `UIWorldMap`; the drawer's map is parked and the drawer shows "MAP UNFOLDED · A or click here to fold it back" (`map:fold` focusable). Same toolbar, tools, pins, colours, annotations, text tool and gamepad cursor; every focusable is re-bound to the World window; B folds from anywhere; closes with the World window. Verified through the bridge: open → focus on `map:canvas:cursor` → D-pad pans → B folds and focus returns to World → button click unfolds again. Fixed a race where the pop-out's render cleared the drawer's fold zone each frame.

### Shipped: vanilla map entry points hooked (`Overrides/WorldMap.lua`)
`ISWorldMap.ShowWorldMap / HideWorldMap / ToggleWorldMap` (the Map key, mini-map click, D-pad wheel slice, equipped-item HUD button) now open the ZeD World window on the Maps tab and unfold it; vanilla only when ZeD cannot serve. First concrete row of HOOK_MAP.md.

### Shipped: capability-driven button prompts (`Organisms.lua`)
Window footer (gamepad mode, focused window) draws A / hold-A / X / B / Y prompts derived from the focused element's callbacks, with labels from `promptA/promptX/promptB` or an id-prefix table. Never hand-authored, never stale.

### Shipped: UI sounds, card hygiene, health wording
FocusManager plays the vanilla list-select tick on focus moves, button sound on A, tick-box sound on B. ItemFactsPanel / ItemCardOrganism: em/en dashes replaced with ASCII (the bitmap Fira export lacks the glyphs — they rendered as blanks, e.g. "Level Range -1  -1"); skill-less books show "Any". HealthTab: "N of 17 injured" now counts wounds; uniform low health (QA character at 22% from hunger) reads "No injuries, low body health".

### New doc: `HOOK_MAP.md`
Every vanilla script that puts UI on screen, with exact entry points, owned / pass-through / gap status, and design targets. Includes the director's four planned surfaces (dashboard `ISPlayerDataObject.lua:124`, mechanics `:119` + `ISOpenMechanicsUIAction`, CaZio watch = Java clock replacement, screen icons = `ISEquippedItem.lua:1270`).

### QA character starved
Elma Forman (QA save) was at 22% body health from hunger/thirst after hours of 3x-speed test runs and died between reloads; PLAY on the save goes to new-character creation. Replaced with a new character in the same world; the final verification script turns on debug god mode so this cannot recur. Rule added to memory: QA characters get god mode at the start of every session.

### Fix: per-frame error after a death (`ZeD_WorldWindow.buildWorldContainers`)
When the QA character died, every frame logged `Object tried to call nil in buildWorldContainers` (line ~2020): the corpse block calls `desc:getForename()` on whatever `IsoDeadBody:getDescription()` returns, and the player's own body (B42) does not expose those. Now pcall-guarded and method-checked; the corpse falls back to the "Dead Person" title. Found only because the final verification scanned the log after the death.

### Final verification (new character, fresh load)
`Overrides/WorldMap` loads at boot · god mode on for the QA character · Health: injured 0 / wounded 0 / overall 100 · `ISWorldMap.ToggleWorldMap(0)` → pop-out open on Maps, focus on `map:canvas:cursor` · B folds, focus back to World. Contact sheet frames 26–27 show the pop-out opened through the vanilla toggle.

### Fix: vanilla strips on a fresh load
`ZeD_CharacterWindow.lua` now hides the vanilla inventory/loot pages at `OnGameStart` (OnTick retry until the pages exist) instead of only after the first ZeD open. Verified on a fresh load: top strip empty before pressing the inventory key.

### Also this block
Remaining drawn em dashes (Animals "Pregnant — N%", card dock flag, location pill, Protection best/worst) replaced with ASCII — the 2x bitmap export has no U+2014. `suite_gamepad` re-run green on the new character (row 3 expectations are N/A with a two-item inventory).

## Closeout (12:50)

Built: QA bridge + suites + contact sheet; map pop-out + vanilla Map hook; capability-driven prompts; UI sounds; cooking Band danger; pills on A; F9 gating; HOOK_MAP.md.
Fixed: dead verbs, verb context, translator WARNs, Band plumbing, stale gamepad zones, cancel-fallback crash, recipe-list perf, body-figure scale, dash glyphs, health wording, corpse-title crash, fresh-load vanilla strips.
Decided (director): hook every vanilla UI entry point; next surfaces are screen icons, CaZio watch, dashboard, mechanics; map unfolds into a centred pop-out that must work on gamepad.
Discovered: Q129–Q131 + Q125–Q128 answers; engine font-size option is 2 on the 4K rig; female skeleton asset missing.
Deferred: UI scale axis (scoped in STATE), controller session, the HOOK_MAP gaps.
Next: S124 mockups for the four planned surfaces, then builds.

## Loop 2 (13:00 →) — vehicle dashboards + CaZio watch (director: "plan and execute")

### Shipped first cuts (commit 223c9cbf)
- `ZeD_Dashboard.lua` — bottom-centre strip replacing `ISVehicleDashboard` (parked every frame). Speed + gear chip, RPM/FUEL/BATT bars, status-dot toggles (ENGINE, KEY, LIGHTS, DOORS, TRUNK*, HEATER*, RADIO, CRUISE), trim band from the paint HSV, family emphasis (normal / sport / utility / emergency / luxury), actions via `ISVehicleMenu` / `ISVehiclePartMenu`, FocusManager window when seated (claims only if no ZeD window owns focus; B releases). Mockup `zed_dashboard_v1.html` (5 variants).
- `ZeD_Watch.lua` — the clock in the Java clock's footprint, only while a wrist watch is worn; CaZio LCD (Black green / Red / Dress) · analog Classic (Black / Brown / Gold / Military) · Expensive ivory with date window; 24h/12h per option; Zeller day-of-week; alarm square. Mockup `zed_cazio_watch_v1.html`.
- `DASHBOARD_WATCH_SPEC.md` — spec + open questions for the director; HOOK_MAP rows #2 and #7 flipped to Owned.

### Verified by bridge
Compile + hot-load clean. `addVehicleDebug("Base.CarNormal")` (paint hue .15 / sat .05 / val .76, mechanicType 1), `vehicle:enter(0, player)` + `OnEnterVehicle`: strip visible at 1640,2060 (4K), vanilla dashboard invisible, 8 tiles / 6 enabled (no key on a debug car → KEY disabled; CRUISE display-only), focus left with the open World window as designed. Worn `WristWatch_Right_DigitalBlack` → Java clock parked, watch instance live. Toggle actions with a created key: see next entry.

### Loop 2, pass 2 (13:05-13:25) - interior variants, brand names, lightbar tiles
- Toggle actions verified through the element callbacks on a keyed Nyala: KEY -> keysIn, ENGINE -> running, LIGHTS, DOORS unlock, TRUNK unlock, ENGINE shut off (console lines `ZEDQA dash after ...`). Java clock confirmed parked (`javaClockVisible now=false`).
- `ZeD_Dashboard.lua`: `INTERIORS` (18 cabins) + `MODEL_INTERIOR` (vanilla models, longest prefix) + `LIVERY_INTERIOR` (police / sheriff / trooper / swat / kst / pd / ambulance / hosp / fire / ranger / taxi / race override); chassis = `_mix(T.surf1, cabin, 0.35)`, tiles = `_mix(T.surf2, cabin, 0.28)`, 2 px cabin-accent piping along the bottom, paint trim band unchanged. `_brandName` = `getTextOrNull("IGUI_VehicleName" .. carModelName or name)` (vanilla ISVehicleMechanics lookup, burnt -> unburnt). `_family` no longer treats "lights" alone as emergency (the civilian Nyala body is `CarLights`). LIGHTBAR + SIREN tiles when `vehicle:hasLightbar()`, through the same `vehicle` client commands as `ISLightbarUI`. `_layout(nToggles)`: two rows always, columns = ceil(n/2) (min 3), so the strip is 498 / 560 / 622 px. Generic `tg.value(st)` tile value (cruise speed, lightbar mode, siren mode).
- Mockup `zed_dashboard_v1.html` section 4 renders the 18 cabins from the same numbers; spec gained the interior table, brand rule and lightbar tiles.
- Bridge tour (6 vehicles + 6 watch faces, each a fresh spawn, key, full tank, engine started from the tiles): Nyala slate 560 px, police Nyala patrol 622 px with LIGHTBAR cycling the real lightbar (mode 1 lit in the scene), Mercia Lang saddle, Cerise Wagon walnut running, Ambulance medic 622 px, Cossette red leather with paint-blue trim, Taxi black vinyl, Chevalier D6 cocoa 7 tiles. Watches: DigitalBlack / Expensive / ClassicGold / ClassicMilitary / DigitalRed / ClassicBrown / DigitalDress / ClassicBlack all drew their face. Zero mod errors (last STACK TRACE in the log is still the old probe at line 36550). Frames 28-45 in `ZeDUI/qa/S123_contact_sheet/`.
