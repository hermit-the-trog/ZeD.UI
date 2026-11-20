# Speed audit: what ZeD costs every frame (Nov 20 2026)

Status: COMPLETE. Report only: no game code was changed, nothing was committed, the game was not run.

## Summary

1. On foot with both windows shut, ZeD is already light. The cost that is left sits in three places: the two windows while they are open, the car dashboard, and a handful of small jobs that run all the time.
2. The biggest single thing: while a window is open, the row of container buttons (Take all, Same type and so on) counts every item in reach again about four times a second, and more often on a fast monitor. This is the likely cause of the stutter on big containers.
3. Next: every item row on screen asks the game for its name, picture, weight and condition again on every frame, and a stack of 50 asks 50 times.
4. In a car, the dashboard reads the whole car and the radio again on every frame, and redraws its needles from scratch on most frames.
5. Do these first, in this order: the container buttons (finding 1), the item rows (2), the dashboard's car reading (3) and needles (4). None of them changes what the player sees, apart from a quarter-second lag on a few slow readouts.

## Method

- The code was read as it stands on Nov 20, after the earlier passes (ZeDUI/qa/archive/perf/PERF_2026-10-22.md, PERF_2026-10-29.md, docs/plans/PERF_REVIEW_20261108.md). Findings those passes fixed are not repeated. Where an earlier lead is only partly fixed, the finding says what is left.
- Every element's prerender / render / update that runs in play was traced, and all 115 per-frame or per-tick event handlers in client/ and shared/ were read (server/ was skipped).
- Costs are counts per frame taken from the code: allocations (tables, closures, strings) and calls into the game ("bridge calls"). They are estimates, not in-game measurements. The dashboard's draw-call counts come from running the real pixel files outside the game with a counting canvas (a throwaway script, not kept in the repo).
- Typical sizes used: 64 items in the main inventory, 25 visible rows per list, a belt with 5 slots and 2 hands, 60 frames a second.
- Paths are under 42/media/lua/client/ZeD/ unless they start with shared/.
- Already sound, checked and left alone: text measuring (ZeD.TM keeps widths), ZeD.tr (kept per phrase), truncateText and wrapText (kept), the lean draw calls (Overrides/TextScale.lua), the window frame and title bar, ZeD_Surface, ZeD_FocusPaint's overlay pass, the Health tab, the pixel text (kept as merged lists), the plate pictures (one texture each).

Before fixing, measure the top five with the tools that exist: perf_now.lua (per-scene costs), perf_census.lua and perf_bench_hdl.lua (handlers), perf_dashprof.lua (the dash). The order below is by expected gain, from the counts; a measurement may reorder neighbors.

## Ranked findings

### 1. The container buttons recount everything in reach every 15 frames (windows open; a spike)

- Where: ContainerControls.lua:787-818 (`refresh`; `CT.REFRESH = 15` at :63 is a frame count), called every frame from `CT.layout` :883-888. The work: `buildChar` :614-659, `buildWorld` :661-739, `transferAllItems` :257-279, `itemsTable` :152-171, `sameTypeItems` :174-187, `nearbyPlan` :305-335.
- Cost: every 15 frames (4 times a second at 60 frames a second, about 10 at 144), whether or not anything changed. With 64 carried items and 5 nearby containers of 20: about 800 to 1,000 bridge calls, 64 closures (`pcall(function() ... end)` per item at :268) and about 200 tables per rebuild, plus the World side's own pass. A 300-item crate is several thousand calls in one frame. This is the likeliest source of punch list 15 ("no stutter opening big containers").
- Also: in Lite, `liteTrim` (:605-612) throws away Same type and Same type nearby after their item walks (:644-655, :699) already ran.
- Fix: rebuild only when the signature the function already keeps changes (containers, sizes, gates, marks), or InventoryRenderer's `_modelGen` moves (a container event), or the other window's container list changes; keep a safety beat of 1,000 ms on the clock, phased per window. Pass a named function to pcall at :268. In Lite skip the two builders. For a button's enabled state, stop at the first match; build the full marked sets only while the button is hovered or focused.
- Risk: what the 15-frame rebuild catches today with no count change: a favorite toggled, an item equipped, room appearing in a nearby container, the nearby list changing as the player walks. The 1 s beat plus `_modelGen` covers them with at most 1 s lag on a button's enabled state. The press itself already recomputes.

### 2. Every visible item row asks the game for the same facts every frame (windows open)

- Where: InventoryRenderer.lua `drawItemRow` :2796-2986. Per visible row: `getTex` :2878, `getName` :2888, `baseName .. suffix` :2912 (a new string even with an empty suffix), `pcall(item.getAttachedSlot, item)` :2934, `rowCondition` :2949 into ItemMeter.lua `IM.of` :43-64 (about 7 pcalls and 7 bridge calls) and `IM.label` :86-89 (a new string per bar), `queueMark` :2954 into `cookState` :1079-1094 (for food a new closure + 4 to 9 bridge calls), `weightText` :2964 into :1387-1398 (getUnequippedWeight + string.format), a new hit zone table :2973.
- A stack's head multiplies it: `IM.ofStack` (ItemMeter.lua:68-76) runs `IM.of` on every item in the stack and `stackWeight` (InventoryRenderer.lua:1377-1381) asks every item's weight, every frame. One row for 50 nails is about 350 pcalls and 400 bridge calls a frame.
- Cost: about 12 bridge calls, 8 pcalls and 5 allocations per visible row. 25 rows in each window: about 600 bridge calls, 400 pcalls and 250 allocations a frame. This is the Oct 29 lead "inventory list rows, 1.6 ms for 64 rows", partly fixed since (the model, sorting, labels and truncation are kept).
- Fix: a record per item on the list model (`M.rec[item] = { name, tex, wtStr, meterKind, meterF, meterLabel, isFood, belt }`), filled on the row's first draw and dropped with the model (which already rebuilds within 1 s and on every container event). The bar and the belt slot refresh on a 250 ms clock per model; the cooking check runs only when `rec.isFood`. Keep `IM.label` per kind and language (two strings in all). A stack's bar and weight are worked out once per model, not per frame.
- Risk: a rename, a worn condition or a drained lighter shows 250 ms to 1 s late (the model already allows 1 s for names). Drop the records with the model, with `ZeD._trGen` (labels), with `ZeD.T` and the measure epoch. The bracketed weight depends on the column width: key the string on the room, or keep the numbers and format on change.

### 3. The dashboard reads the whole car from the game every frame (driving, driver and passenger)

- Where: ZeD_Dashboard.lua:209-271 (`_state`), called at :2197.
- Cost: about 58 bridge calls a frame, about 50 of them through pcall: 9 `getPartById` string lookups (Heater twice, :237 and :248), 4 `_partCond` at 5 calls each (:236-239), `chr:getInventory():haveThisKeyId(...)` at :222 (walks the inventory), 10 new closures (:222, :225, :226, :229, :232, :246, :248, :250, :251, :257) plus 2 in prerender (:2195, :2206), a new table of about 75 fields, and `tostring` of the engine state and the gear (:217, :225).
- Fix: split the reading. Every frame: speed, rpm, running, engine state, keys, headlights, gear. Every 150 to 250 ms into a kept table: part conditions, hasKey, locks, trunk, heater, lightbar, fuel, battery, clock, cruise. Force a slow read on a new car, on a seat change and in `_fire` (:2381). ModSupport/VSKDash.lua:205-222 already samples this way. Use `_get`-style calls with no closure for the per-frame part.
- Risk: a lock light or lamp changed by someone else (a passenger, the server) shows up to 0.25 s late. The 500 ms lamp blink has its own clock. `_fire` reads `self._st`, so the forced read must come before the action's result is drawn.

### 4. A moving needle is drawn from scratch on most frames (driving)

- Where: ZeD_PixelParts.lua:346-376 (`needleSets`), :322-345 (`needleSamples`), :284-312 (`needleRuns`), :255-273 (`runsOf`).
- Why: the per-angle cache is keyed on the exact angle, a fraction that changes every frame. `D.derive` (ZeD_Dashboard.lua:350-357) eases every reading toward its target and never lands on it, so a resting fuel or temperature needle also gets a new angle each frame for minutes. The cache almost never hits: this is the one cache in the audit that is keyed so it misses.
- Cost per needle per frame (outside-the-game run): 4.8 KB of new tables while settling, 19 KB cruising, 39 KB sweeping; a full pass is 3 hash sets, 3 sorts (the game's sort is written in Lua) and about 100 small tables. A whole dash with moving needles: 47 to 102 KB a frame against 3 to 5 KB parked.
- Fix: (a) in `D.derive`, set `cur = target` once they are within 1e-4, so resting needles hit the cache; (b) in `needleSets`, while the angle is within 0.25 degrees of the last one drawn and still moving, reuse the last set; (c) fill `needleSamples` into one reused table.
- Risk: (a) and (c) change nothing visible. (b) lets a moving needle trail its true angle by under 0.25 degrees (0.2 pixel at the tip of the longest needle); it must still draw the exact angle once the value stops, or a needle could rest one pixel off.

### 5. A clothing item's card rebuilds every body zone from the game every frame (card open)

- Where: ItemCardOrganism.lua:823-824 calls `ZeD.ItemDetail.buildConfigs(item)` each frame; ItemCard.lua:1543-1578 (`buildZoneConfigs`) into `getClothingZones` :572-670. The card's kept model does not cover it.
- Cost: per covered body part: tostring + gsub, a new closure + pcall for `getHole` (:595), `getPatchType`, `getBloodlevelForPart`, and 5 or 6 new tables. A jacket over 9 parts: about 45 pcalls, 45 bridge calls, 9 closures and 60 tables a frame, for as long as the card is open (the Equip tab's card too).
- Fix: build the zone configs inside `buildModel` (ItemCardOrganism.lua:690-714) as `m.zones`, and add `getHolesNumber`, `getPatchesNumber`, `getBloodLevel`, `getDirtiness` and `getWetness` to `liveProbe` for clothing so a new hole, patch or stain rebuilds at once.
- Risk: a repair, a patch or blood must show promptly: the probes plus `ItemActionManager.gen` (already a model key) cover them. Wetness drifts: round it in the probe.

### 6. The item list's fixed overhead per list per frame (windows open)

- Where: InventoryRenderer.lua :2353-3061.
  - 9 closures every call: the eight draw wrappers :2364-2387 and `drawItemRow` :2796.
  - `colDefs` :2606-2619 (5 tables); id strings `"hdr:" .. key` twice per column (:2647, :2768), `"cat:" .. cat` twice per category whether drawn or not (:3009, :3013), `"stack:" .. key` per stack head (:2971).
  - `gridState` :1242-1252 (2 tables per call), `drawViewToggle` :1277-1338 (2 tables, 2 strings), `_gv.xmap = {}` :2977.
  - `isGridKey` :374-380 runs twice per list per frame (:2501, :1245): `getModData()` plus a new closure each.
  - `itemRenderYMap = {}` :2742, then one write per row of the model, visible or not (:2866 sits before the cull at :2868): the loop is over all rows, not the visible ones.
  - `clearHitZones` (ZeD_Panel.lua:145) makes a new table per panel per frame; each `addHitZone` (:152) a new table.
- Cost: 45 to 60 allocations, 2 closures + pcalls and 2 getModData per list per frame before any row draws, plus one call and one table write per row in the container (500 rows: 500 a frame while 25 draw).
- Fix: move the wrappers to file-level functions that take `(self, xOff, ...)`; keep `colDefs`, the grid state and the id strings on the panel, keyed by what they depend on (columns shown, widths, language, container); read `isGridKey` once a frame with a direct guarded call. Reuse the hit zone array and its entries (cut the tail). Keep row offsets per model and draw from the first visible row by arithmetic.
- Risk: `hitZoneAt` hands back the zone table itself, so nothing may hold one across frames. The controller's stops read `_itemRenderYMap` and each column keeps its own copy (:3443), so a reused map must be per column and must be restamped on fold, stack open, filter bar and resize.

### 7. The dashboard rebuilds every control every frame for the driver, mouse players too (driving)

- Where: ZeD_Dashboard.lua:794-805 (`_control`), :809-825 (`_element`), :830-849 (`_volKnob`), :2251, :2263, :2268-2271; ZeD_Plate.lua:320-328; Input/FocusManager.lua:982-1042 (`knobStop`, about 10 closures).
- Cost: with about 25 controls: about 70 tables, 85 closures (three per element) and 50 `"dash:" .. id` strings a frame, then the list is handed to the focus manager.
- Fix: keep one element and one hit record per id on the dash (`self._elPool[id]`), with its three closures made once; each frame update only x, y, w, h, enabled and the prompt words. Reuse the arrays by resetting a count. A cheaper first step: skip `_element` unless the dash holds the controller (`self._reg` or `self._wantFocus`).
- Risk: `knobStop` and `_volKnob` rewrite fields on the element, so a reused element must have them reset each frame. For the cheaper step, the ring must be filled in the same frame the dash claims the pad (`_claim`, :2424), or the focus manager sees an empty zone.

### 8. The radio is fully re-read every frame, twice with its close-up open (driving)

- Where: ZeD_RadioOps.lua:185-225 (`O.read`), :171-181 (`presetList`), :105-119 (`keyOf`), :123-129 (`chanName`); called from ZeD_Dashboard.lua:259 and again from ZeD_CarRadio.lua:262.
- Cost: about 50 bridge calls a frame, radio on or off: a new 25-field table, a new table per stored preset with `tostring(getName)`, a key string built through a closure and two tostring, a closure plus an upper-cased station name. The Oct 22 profile had this at 0.12 ms.
- Fix: keep the reading per radio part, refresh every 100 to 150 ms and at once after any `RO.*` action (a dirty flag in `run`, `flash`, `store`, `setChannel`). Read the cheap live fields every frame (`flash`, `scanning`, `cdMs`). Share one reading between the dash and the close-up.
- Risk: a channel or volume changed by another player or by SCAN shows up to 150 ms late. Drop the preset list on store, clear and a radio swap.

### 9. The item card's other per-frame work (card open)

- Where: ItemCardOrganism.lua `renderBody` :1320-1508. Still per frame after the kept model: about 12 rect tables (:1337-1342, :1412, :1432); `stampGamepadFields` :753-793 (a closure at :761, up to 6 tables, a table per verb); `careVerbs` :1174-1183 into `maintenanceVerbsForItem` :474-499 (about 8 guarded asks, new verb tables); `drawMakes` :1266-1314 (a closure at :1290 and, per recipe row, a press closure at :1308 / :1312, a table and an id string: up to 16 closures); `drawInLists` :1239-1257 (walks the loadouts every frame); `liveProbe` :636-671 (3 to 12 pcalls); the context table at ItemCard.lua:1592.
- On top, the whole model is rebuilt every 250 ms regardless (`MODEL_MS`, :632), although the live probes and generation counters already catch real changes.
- Fix: keep care verbs, the makes rows (with their closures and ids) and the lists hits on the model; reuse the rect tables; raise `MODEL_MS` to 1,000.
- Risk: the pointer poll and the controller read these rect tables by reference (`toggleRects`, `verbRects`, `_makeRects`): a reused table must be fully rewritten each frame. A loadout edited elsewhere must bump `Lists.gen` (already a model key).

### 10. The belt makes about 30 small objects and asks about 70 item questions every frame (always on, on foot)

- Where: ZeD_Belt.lua `_prerender` :2048-2264 and what it calls.
  - `B.slots` :719-733: a new list and a new 7-field table per slot every frame, with `chr:isEquipped(item)` and `getCore():getKey(...)` per slot.
  - `_extrasNow` :957-970: 2 new tables every frame even when no other mod adds a box.
  - `local o = {}` at :2123: a new table per box per frame (about 9).
  - `_drawBox` :1635-1746: `local function fill` at :1642 is a new closure per box per frame (about 9).
  - Per held or attached item: `B.meter` :593 into `IM.of` (7 pcalls and 7 bridge calls), `call(o.item, "getTex")` :1656, `canBeActivated` / `isActivated` and `instanceof` (:2144, :2152): about 11 bridge calls per item, so 50 to 80 a frame with a full belt.
  - `wanted()` :894-902 runs twice a frame (from `_prerender` and from `visibilityTick` :2715) and each time does `tostring(getCore():getGameMode()) == "Tutorial"` (2 bridge calls and a string).
  - The mini watch: `W.miniState` (ZeD_Watch.lua:386-398) makes a closure a frame for the 24-hour option; WatchMini.lua:134-149 draws analog hands one texel at a time (2 new tables, about 45 writes and 40 to 45 one-texel rects a frame) for hands that move once a game minute; the digital face formats its time string every frame (:193).
- Cost: about 30 allocations and 60 to 90 bridge calls a frame, in all play. The Oct 29 profile had the belt at 0.29 ms, the largest HUD part.
- Fix: keep the slot records and one scratch `o` table on the HUD and rewrite their fields in place; make `fill` a file-level function taking `(self, b, round, a, c)`; return early from `_extrasNow` when `#B._extras == 0`; keep per item `{ tex, meterF, meterKind, lit }` on the box, refreshed every 250 ms and at once when the box's item changes (as `_ammoState` already does for ammo); read the game mode once at game start; keep the mini watch's hands as a merged run list per minute and its time string per minute and format.
- Risk: a condition ring, a fluid strip or a flashlight's lamp shows up to 250 ms late; an item swap must refresh at once (compare the item reference each frame, which is free). Other mods' meters (`B.addMeter`) are called 4 times a second, not every frame: say so in the add-on guide.

### 11. The Character window's title stats are rebuilt every frame; an item pin searches the whole inventory every frame (window open)

- Where: ZeD_CharacterWindow.lua:6297-6306 (`win.titleStats = {}`, `ZeD.Pins.skillNames`, `ZeD.Pins.stats`, `ZeD.Atoms.loadText`); ZeD_Pins.lua:161-195: per pin per frame, two `shortName` runs (match + up to 3 gsub), two `pinForm` runs (a three-argument `ZeD.tr` is never kept: shared/ZeD/Tr.lua:440 keeps at most two text arguments), an `alts` table and an entry table. An item pin calls `getItemWithIDRecursiv` (ZeD_Pins.lua:47), a search of everything carried, every frame. A skill pin: SkillsTab.lua:250-272, about 7 bridge calls and a table.
- Cost: no pins: about 8 allocations a frame. Three pins (the cap): 80 to 100 allocations, 20 or more bridge calls and up to three whole-inventory searches a frame.
- Fix: refresh `Pins.stats` and `skillNames` every 250 ms, keep the tables on the window, and reuse the weight stat's table (the World window already does at ZeD_WorldWindow.lua:4983-4992).
- Risk: a pin toggled must show at once: bump a `Pins.gen` in `P.toggle` and compare it. XP gained shows up to 250 ms late.

### 12. Safe mode and the translation test read the clock from the game on every call (always on)

- Where: SafeMode.lua:126 (`S.on`), :108 (`S.pieceOff`), :149 (`sync`, on OnTickEvenPaused and OnFETick, :399-401); shared/ZeD/Tr.lua:86 (`testOn`, called at the top of every `ZeD.tr`, before the kept-phrase lookup).
- Cost: `S.on(name)` is 1 or 2 `getTimestampMs` bridge calls per call and has 174 call sites, many in frame paths (belt, moodles, loot-page watch 3 times, bubbles, run-sneak, watch, every `M.rect`). `sync` adds about 10 a frame. HUD only: 25 to 40 clock reads a frame. With windows open, every `ZeD.tr` adds one more (the file's own comment says the windows ask for hundreds of phrases a frame), so several hundred bridge calls a frame go to reading the clock.
- Fix: one frame stamp, set in an OnPreUIDraw / OnFETick / OnTickEvenPaused handler (`ZeD._nowMs = getTimestampMs()`), read by `S.on`, `S.pieceOff` and `testOn` (falling back to the real clock while it is nil). Better still: read the options only inside `sync` on a 250 ms gate and store plain fields, so `S.on(name)` is two table reads.
- Risk: `S.on` is called before the first sync (file load, game boot): seed the fields with one direct read at load and in `S.reread`. The watchdog trip (`st.tripped`) is already a plain field.

### 13. Weights are asked and worded several times a frame (windows open)

- Where: `getCapacityWeight()` on the same container at ZeD_CharacterWindow.lua:6295 (title), :6352 (heading) and InventoryRenderer.lua:2220 (the model); ZeD_WorldWindow.lua:4950 plus the model; per column again at InventoryRenderer.lua:3391. To check against the game's jar: whether the game sums every item on each call (the fork's read says it does). `ZeD.Atoms.loadText` (Atoms.lua:500-507): 2 string.format, a sub and a two-argument `ZeD.tr` (which builds its key string on every call, Tr.lua:442), 2 times a frame in the Character window and once per column elsewhere. `ZeD.tr(key, n)` with a number builds its key each call (ZeD_CharacterWindow.lua:6362, ZeD_WorldWindow.lua:4957, InventoryRenderer.lua:3396). `self._containerInfo = {...}` is a new table per list per frame (ZeD_CharacterWindow.lua:6358, ZeD_WorldWindow.lua:4953, InventoryRenderer.lua:3410).
- Cost: 2 or 3 whole-container sums per container per frame, about 15 short-lived strings and a table per list.
- Fix: one weight read per container per frame, shared (`InventoryRenderer.weightOf(inv)` keyed on a frame counter); `loadText` keeps its last answer per (load to a tenth, capacity); reuse `_containerInfo` and reword the count only when the number changes.
- Risk: none for the shared read. `loadText`'s kept answer must drop on `ZeD._trGen`.

### 14. ItemActionHooks polls three things every tick, with new tables each time (always on)

- Where: ItemActionHooks.lua:367-379 (the wrapper on OnTick), `_pollPlayer` :87, `_pollReadingFallback` :162, `_cardedItems` :298, `_pollCooking` :317.
- Cost idle: 2 new tables a tick (`seen = {}` at :318, `out = {}` in `_cardedItems`), 8 window lookups, 3 pcalls and about 6 bridge calls. While any timed action heads the queue (walking to a container, moving items, eating): `_classifyAction` :40 runs each tick, one `string.lower` and up to 4 finds plus `instanceof`. While reading or cooking: a description table per tick and, in the cooking branch, 5 closures per tick (:325-329).
- Fix: `_pollCooking` returns before any allocation unless a window has a card open (`_drawerItem`), runs every 10 ticks and reuses `seen`. Keep the classification on the head action (reuse it while `head == last.action`). One local helper in place of the inline closures.
- Risk: `ItemActionManager.notify` may keep the description table: check before reusing one.

### 15. The container buttons build a signature string and a dozen tables every frame (windows open)

- Where: ContainerControls.lua `CT.syncFocus` :1165-1185 (a `parts` table and, per button, `h.key .. "@" .. h.x .. "," .. h.y .. "," .. h.w`, then `table.concat`, :1181-1183, mouse mode too); `CT.layout` :889 and `layRow` :848-880 (new `hits`, `arrows`, `strips`, `rects`, a rect and a hit table per button, `"cc:" .. key` per button).
- Cost: about 40 strings and 20 tables per window per frame.
- Fix: compare the hits to the last ones field by field (count, then key, x, y, w), as `_charMCColumnDirty` does; skip `syncFocus` while `Focus.stopsMayWait(win)`; lay the row out only when the buttons, the column width or the scale changed.
- Risk: the ribbon's scroll offset (`cc.sx`) and the Delete question change the layout: put them in the key.

### 16. The windows' focus refresh runs every frame for mouse players (windows open)

- Where: `content._focusRefresh`, ZeD_CharacterWindow.lua:6575-6747, and its twin in ZeD_WorldWindow.lua (about :5240-5330). Only the tab stops wait for the controller (`Focus.stopsMayWait`, :6716). Still per frame with a mouse: the main list's `geo` string (7 tostring and concatenations of a fractional scroll position, ZeD_CharacterWindow.lua:6625-6627, ZeD_WorldWindow.lua:5285-5287); `_buildCardActionFocusables(win)` and `setRingZoneElementsKeepId` every frame while a card shows (:6741-6746).
- Cost: about 12 strings per window per frame, plus the card's stop tables and closures while a card is open.
- Fix: compare the geo fields one by one; put the whole refresh behind the `stopsMayWait` gate, with the stale flag `win._focusFresh` already honors.
- Risk: the focus manager must call `win._focusFresh` before any pad press reads the main list or the card zone (it does for tab stops today); `_gpFocusedRowItem` must be reseeded on the first pad frame.

### 17. The action bar over the head builds its words twice a frame while an action runs, and polls with closures when idle (always on)

- Where: ZeD_ActionBar.lua `prerender` :739-801 and `render` :836-853; ZeD_Bubbles.lua `speedNow` :532-541, `B.poll` :845.
  - Idle, every frame: `speedNow` makes 2 closures and 2 pcalls (through `Bb.notes`, :619); `pcall(Bb.poll, pn, chr)` (:762) asks `getSayLine` again although ZeD_Bubbles.lua:883-894 already polls it every tick.
  - While an action runs (walking to a container, a transfer, eating: much of play): a new 11-field state table in `AB.state` (:444 or :465), a closure in `delta` (:397), a closure in `AB.k` (:727), a closure for `screenR` (:777), `AB.verboseText` twice (once in `verboseWidth` from prerender, once in `drawVerboseBody` from render; each builds 2 to 4 strings with tostring / string.format / a `ZeD.tr` with an argument), a `txt` closure (:643), and 4 pixel-text key strings (ZeD_PixelParts.lua:729: 2 tostring and 6 concatenations each).
- Cost: idle 2 closures and about 10 bridge calls a frame; during an action about 5 closures, 3 tables and 40 to 50 short strings a frame.
- Fix: `pcall(isGamePaused)` and `pcall(getGameSpeed)` with no closure, or read both once in the tick poll; drop the prerender's `Bb.poll` (the tick already did it this frame) or keep only one of the two. Fill one kept state table per player in place. Work out the four words once in prerender, keep them on the state (`st.L1 .. st.R2`), and rebuild only when the label, the item, the count or the whole percent changes. Hoist `txt` to a file-level function. Read the progress bar size option once every 500 ms.
- Risk: `AB._last` / `AB._ends` keep the state table for the end fade: a reused table must be copied at the moment an action ends (it is small). The percent must still tick every whole percent.

### 18. The Equip tab's doll asks each slot's picture and condition every frame (Equip tab open)

- Where: EquipDoll.lua `D.draw` :618-800 and `drawBox` :435-506: two closures per frame (:641, :654); per slot a key string `"doll:" .. id` (:688, :720); per filled box `itemTex` (:388), `condOf` (:392, 2 pcalls + 2 bridge calls), `tostring(n)` (:420). EquipmentTab.lua list mode: `_equipSlotYMap = {}`, zone tables and `"__group_" .. id` / `"__part_" .. name` strings each frame (:1480-1560).
- Cost: about 30 slots: 30 strings, up to 90 pcalls and bridge calls, 2 closures and about 10 tables a frame. The Oct 29 lead "Equip tab, 1.5 ms" is partly fixed (the slot data is gathered every 250 ms, the doll's every 15 frames).
- Fix: store the texture and the condition share on the gathered slot data; put the key string on each slot definition at file load; make the two closures plain functions.
- Risk: move the doll's 15-frame gather to the clock at the same time (see the bug list), so the kept picture is never older than 250 ms.

### 19. The dashboard builds 40 to 60 strings a frame only to look things up (driving)

- Where: ZeD_Dashboard.lua:64 (`tex(name)` does `TEXDIR .. name .. ".png"` for the plate, the night overlay, every sprite, tab and the radio face: 6 to 10 lookups a frame; ZeD_CarRadio.lua:71 and ZeD_SirenController.lua:47 do the same); ZeD_PixelParts.lua:348 (the needle key: 6 tostring and 5 concatenations per needle, pointer and clock hand, 5 to 9 times a frame); ZeD_PixelParts.lua:729 (the text cache key: 2 tostring and 6 concatenations per text, used by the action bar and bubbles too); ZeD_PixelParts.lua:48 (`P.shade`); ZeD_Dashboard.lua:2206-2207 and :2238 (the script name lowered and `"key_acc_" .. designId` every frame).
- Fix: a `name -> texture` table; keep the needle record on the part (`p._nr`); nested tables `_tc[font][scale][style][str]` for text; do the badge-key strings inside the block that already runs once per car (:2216-2230).
- Risk: none; the inputs are constants or already part of a cache key.

### 20. The odometer and the seven-segment figures are rebuilt every frame (driving)

- Where: ZeD_PixelParts.lua:912-936 (`P.drums`), :865-880, :893-908; ZeD_Dashboard.lua:952-969 (`D.odoShow`); ZeD_PixelParts.lua:473-506 (`P.digits`); ZeD_Plate.lua:249-301 (`headDisplay`), :637-645, :730-744.
- Cost: the odometer: 2 to 4 tostring, a `string.rep`, a sub per wheel, 59 unmerged rects and at night a light lookup per run, for figures that change once per tenth of a mile. The digits: a list plus a table per character, a sub per character and a find per segment, 1 to 4 times a frame; the head unit's lines add string.format and concatenations for a frequency that changes on a button press.
- Fix: keep a flat rect-and-color list on the part, keyed by `math.floor(v * 10)`, the roll offset in whole pixels and, at night, the light state; build the digits' list only when the text changes (as `badgeFit` does at ZeD_Plate.lua:556).
- Risk: the key must hold the roll offset (or the tenths wheel will not turn smoothly), the units option and the night light state; the STORE flash blink must stay in the head unit's key.

### 21. Rebuild beats that fire more often than needed (windows open, during transfers)

- InventoryRenderer.lua:1950-1952: `dirtyModels` bumps one number for every list in both windows, so during a run of transfers every open column re-sorts every 500 ms, containers the transfer never touched included. The count and weight test at :2244 already catches the ones that changed. Fix: let OnContainerUpdate mark only lists whose count or weight changed, and keep the shared number for clothing changes and drops.
- ZeD_WorldWindow.lua:6392 with :3068-3078: any OnContainerUpdate makes the World window rescan its nine squares 200 ms after the last scan (5 times a second during a bulk move), although a transfer does not change which containers are in reach. Fix: on the event, refresh the floor only, unless the player's square changed.
- InventoryRenderer.lua:1943: each column's model rebuilds every 1,000 ms: about 3 tables and 6 bridge calls per item (a 300-item crate: about 900 tables a second). Fix: when the rebuilt rows equal the old ones row for row, keep the old model object, so the filter, grid layout and pad stops keyed on it do not rebuild either.
- Risk: a container whose items change with the count and weight equal waits for the 1 s beat, as a rename does today.

### 22. The belt's hold-key handler runs for every held key every frame, walking included (always on)

- Where: Overrides/Belt.lua:40 (`holdKeepPressed`), registered at :143 on OnKeyKeepPressed in place of the game's own.
- Cost: per held key per frame, about 15 to 18 bridge calls (two clock reads, the player, `isDead`, the speed controls twice, `isAttacking`, then the game's `hb:getSlotForKey(key)`, which reads five key bindings). W plus Shift held is 30 or more a frame. The game's own handler cost about the same, so this is no worse than vanilla; it is listed because the fix is small.
- Fix: keep a small set of the hotbar key codes (ZeD_Belt.lua has `HOTBAR_KEY` at :319), refreshed every 500 ms, and return at the top when `key` is not in it.
- Risk: a key rebound in Options is picked up within the refresh window.

### 23. Four OnPlayerUpdate handlers do controller work for a keyboard player (always on)

- Where: Input/RunSneak.lua:301 (registered :347), Overrides/PlaceItemPad.lua:60 (:87) and :133 (:168), FlyerMap.lua:91.
- Cost per local player update on keyboard and mouse: 5 pcalls and about 14 bridge calls (RunSneak makes 4 pcalls and reads the pad bind before finding it is -1); PlaceItemPad's `guardContext` calls `getCell()` at :65 before it knows a pad exists. In multiplayer each remote player's update pays the entry checks too.
- Fix: one dispatcher that reads `isLocalPlayer` and the player number once and returns when `JoypadState.players[pn + 1] == nil` and nothing is held; move `getCell()` after the pad test; FlyerMap counts ticks before touching the player.
- Risk: QA's run-sneak hook (`_qa[pn].pad`) drives it with no pad bound: keep that exception.

### 24. The full watch face rebuilds its whole readout every frame (Lite, the corner watch, or a popped belt watch)

- Where: ZeD_Watch.lua `_reading` :205-250, called from `prerender` :784.
- Cost per frame: a new 12-entry `MON` table (:236, a table constructor inside the function), `"UI_ZeD_MainMenu_Month" .. name`, 2 or 3 string.format, 4 tostring, `_thermo` :177-185 (2 closures, 2 pcalls, 4 bridge calls, a tostring), a closure for the 24-hour option (:220), and `_lcd` (:163) for the day, PAUSE and ALM words: each runs `ZeD.trPlain` and then `_lcdCan` (:154), a per-character loop with `sub` and `string.upper`. About 4 closures, 1 table and 25 to 30 strings a frame. With the watch tucked on the belt (the Full default) this does not run; in Lite it runs in all play.
- Fix: move `MON` to file level. Keep the readout and rebuild the slow fields only when the game minute, the day, the speed, the alarm or the language changes; the seconds field alone changes each frame. Keep `_lcd` answers per key and language. Sample the temperature every 500 ms. Read the 24-hour option with `pcall(core.getOptionClock24Hour, core)`.
- Risk: the 24-hour and Celsius options apply up to 500 ms late; `ZeD._trGen` must drop the kept words.

### 25. Moodle placement makes a table and about 14 bridge calls a frame (always on)

- Where: ZeD_Moodles.lua:723 (`preDraw`, on OnPreUIDraw), `_place` :306, a new `_rect` at :335 and :370, `M.place` :82 (a pcall'd option read each frame); in the bottom row, `tex` :221 builds `size .. "/" .. name` per moodle per frame.
- Fix: reuse one `_rect` table per layer; read the placement option on the same 100 ms clock as the active list; key the texture cache by `[size][name]`.
- Risk: `M.rect()` hands the table to other code (the hint strip, stand-in mods): a reused table is safe as long as nobody keeps it across frames (not checked for add-ons).

### 26. Controller only: prompts and tab stops are rebuilt every frame

- Organisms.lua `_promptsFor` :919-948 and `_footerPrompts` :953-976 (from `_drawHelpLine` :1107): `pairs(PROMPT_LABELS)` with `id:sub(1, #prefix)` is about 20 substrings a frame, plus a new list and 3 to 6 prompt tables. Fix: keep the prefix match per id; reuse the list; rebuild when the focused element, its words or the lock state change. Risk: prompt words can be functions read each frame (:910): keep calling those.
- ZeD_CharacterWindow.lua:6419 (`_buildPanelFocusables` runs before the dirty test) and ZeD_WorldWindow.lua:5018; the `scrollKey` strings (up to 9 tostring each, ZeD_CharacterWindow.lua:6455-6498, ZeD_WorldWindow.lua:5066-5085). On Equip, Health, Skills, Journal and Craft the full stop list (a table and usually closures per stop) is built every frame and thrown away when nothing changed. Fix: work out a cheap key first (the scroll fields compared one by one, plus a per-tab counter the tab bumps when its zones change). Risk: each tab must bump the counter wherever it rewrites its zones.
- Input/InputModeDetector.lua:271 (on OnTick, :443): with any controller connected (a Steam Deck always has one), each tick reads 4 stick axes, 2 triggers and up to 12 buttons, about 20 bridge calls per pad, also while the player is on the keyboard. Fix: when the mode is already "gamepad" and no key or mouse button was pressed this tick, skip the probe.
- Input/FocusManager.lua:2989 (on OnTick, :3170): on a pad, each tick makes one closure in `Focus.pauseMenuUp` :140 plus 20 to 30 bridge calls. Fix: `pcall(m.isReallyVisible, m)`; read the clock once per tick.

### 27. Small always-on leftovers (each tiny; one pass clears them)

- ZeD_Messages.lua:833: `safe(function() return getGameSpeed() end)` is a closure every frame. Use `safe(getGameSpeed)`.
- shared/ZeD/Scale.lua:918-920 (`mcFrame`): a closure every frame for the font-size option. Use a file-level function.
- ZeD_MessagesWindow.lua:1149-1157: with no toasts, the toast layer still makes 3 tables a frame (`W.toastsFor` :1126 returns a new list; `self._boxes, self._list = {}, {}`). Return early on `#MS.toasts == 0` and keep empty tables.
- ZeD_WorldWindow.lua:6509-6511: the loot-page watch runs three times a frame (OnTick, OnTickEvenPaused, OnPreUIDraw), about 20 bridge calls in all, windows open or shut. The comment at :6447 explains why all three exist; the OnTick copy can return at once unless that player has a timed action running. Risk: the trunk case (ISOpenVehicleDoor) must still be caught the same tick.
- ZeD_Belt.lua:2715 (`visibilityTick`): about 9 bridge calls a tick, mostly `wanted()` (see finding 10).
- Multiplayer and debug upkeep that runs in every single-player game: `isClient()` once a tick each in ZeD_Tickets.lua:919, ZeD_Claims.lua:940, ZeD_Chat.lua:1205, ZeD_Watch.lua:1141; `pcall(isDebugEnabled)` every frame in ZeD_DebugConsole.lua:2691; a pcall + `getCell` + `getDrag` every tick in FurnitureTab.lua:1193. Fix: read `isClient()` and `isDebugEnabled()` once at each OnGameStart (not at file load: the same Lua state can join a server later, Overrides/Respawn.lua:167) and skip those handlers when false.
- ZeD_SplitSpeed.lua:180-181: `_tick` is on both OnTick and OnTickEvenPaused, so it runs twice a frame unpaused (it returns at once while split view is off). Keep the OnTickEvenPaused one.
- ZeD_HintStrip.lua:107-112 and :65-80: while a prompt shows, `keyName` makes 2 closures a frame and, in the "first uses" mode, `spent` walks all of `ISButtonPrompt` with `pairs` per prompt per frame (:66). Keep the key name per binding for 500 ms and the function-to-name map once.
- Lite only: Molecules.lua:139-146 (`coreRGB`) makes 2 closures and about 5 bridge calls per good or bad button per frame. Keep the two colors and re-read them every 500 ms (as ZeD_Moodles.lua `hlColours` does).
- ZeD_Dashboard.lua:338, :2261, :769-780; ZeD_CarRadio.lua:235-255, :278, :283-285; ZeD_SirenController.lua:179, :185-190: about 5 tables a frame on the dash and 20 to 30 while a close-up is open that could be kept and refilled. `self._hits` is read by the mouse handlers between frames, so refill in place.

### 28. Only while paused, or near a horde

- ZeD_PausedNotice.lua:32 (from the tick at :105): each paused frame walks the whole UI list with a closure + pcall and about 6 bridge calls per element; ZeD_PausedLook.lua:231 counts both windows' children each paused frame. Fix: run the walk every 10th frame. Risk: the notice shows or hides up to 10 frames late.
- InventoryRenderer.lua:1956 and EquipDoll.lua:792 (OnClothingUpdated) fire for every zombie that gets dressed: a closure + pcall each. Fix: `if not instanceof(chr, "IsoPlayer") then return end` as the first line.
- ZeD_SeatPopout.lua:652-690: `readSeats`, `plan` (a new sorted list) and `layout` every frame while the seat pop-out is open. Fix: re-plan when the seat occupancy changes.

### 29. Pixel text as pictures (the open lead from Oct 22 and Oct 29): leave it

- Where: ZeD_PixelParts.lua:793-808. Today 20 to 126 rects a frame on a dash, already kept as merged lists (the Oct 22 figure was 250). One picture per glyph would save about 0.01 to 0.06 ms a frame at the repo's own per-call cost. Not worth doing before findings 3, 4, 7, 8, 19 and 20.

### Earlier leads, as the code is now

- Inventory list rows (Oct 29, 1.6 ms for 64 rows): partly fixed. What is left is findings 2 and 6.
- Item card (Oct 29, 1.5 ms): partly fixed. What is left is findings 5 and 9.
- Equip tab (Oct 29, 1.5 ms): partly fixed. What is left is finding 18.
- Dashboard built from many small tinted parts (Oct 22): mostly fixed (colors per light level, lamp lists and needle colors are kept). Still per frame: findings 3, 4, 19, 20.
- The Nov 8 review's window findings (list model re-sorted every 30 frames, the World window's 30-frame container refresh, the card's whole model per frame, wrapText not kept, the World window's focus list per frame): fixed or reduced to what is listed above. Its Craft / Build, Restock and Animals findings were outside this audit's slice and were not re-checked.

## Event handlers (per frame / per tick)

115 registrations in client/ and shared/: OnTick 62, OnPreUIDraw 19, OnRenderTick 10, OnFETick 6, OnPlayerUpdate 5, OnTickEvenPaused 4, OnPostUIDraw 3, OnKeyKeepPressed 1, plus a few added through a local alias. Always live in single player on foot: about 35 OnTick, 15 OnPreUIDraw, 8 OnRenderTick, 4 OnTickEvenPaused, 4 OnPlayerUpdate, 3 OnPostUIDraw. Format: where | event | what it does | throttle or early out | cost.

Always on in a game:

- SafeMode.lua:399 | OnTickEvenPaused (+ OnFETick :401) | options sync over 20 hooks | options read every 500 ms, clock read about 10 times a frame | medium (finding 12)
- ItemActionHooks.lua:379 | OnTick | action queue, cooking and reading polls | none | medium (finding 14)
- Overrides/Belt.lua:143 | OnKeyKeepPressed | belt slot hold menu | none before the bridge calls | medium while keys are held (finding 22)
- Input/RunSneak.lua:347 | OnPlayerUpdate | run-sneak press | returns after 4 pcalls on keyboard | small (finding 23)
- Overrides/PlaceItemPad.lua:87 | OnPlayerUpdate | place-item A guard | getCell before the pad test | small (finding 23)
- Overrides/PlaceItemPad.lua:168 | OnPlayerUpdate | door press release | returns when nothing is held | small (finding 23)
- FlyerMap.lua:91 | OnPlayerUpdate | flyer places visited | 1 s gate after 3 bridge calls | small (finding 23)
- ZeD_Moodles.lua:728 | OnPreUIDraw | place the moodle layer | list every 100 ms, placement every frame | small to medium (finding 25)
- ZeD_Messages.lua:856 | OnRenderTick | errors every 2 s, toasts, speed watch | 1 closure a frame | small (finding 27)
- shared/ZeD/Scale.lua:950 | OnPreUIDraw | font-size option for the measure cache | none; 1 closure a frame | small (finding 27)
- ZeD_WorldWindow.lua:6509 / :6510 / :6511 | OnTick / OnTickEvenPaused / OnPreUIDraw | hide the game's loot page, route to ZeD | none | small each (finding 27)
- ZeD_Belt.lua:2741 | OnTick | belt shown or hidden | none | small (findings 10, 27)
- ZeD_Bubbles.lua:894 | OnTick | say-line poll | none | small; duplicated by the action bar's prerender (finding 17)
- ZeD_Tickets.lua:919, ZeD_Claims.lua:940, ZeD_Chat.lua:1205, ZeD_Watch.lua:1141 | OnTick | multiplayer upkeep | isClient() first | trivial in single player (finding 27)
- ZeD_DebugConsole.lua:2691 | OnPreUIDraw | Lua console follow | pcall(isDebugEnabled) first | trivial, every frame (finding 27)
- FurnitureTab.lua:1193 | OnTick | furniture cursor watch | none | small (finding 27)
- Input/FocusManager.lua:3170 | OnTick | pad holds, aim escape, D-pad repeat | mode gate first | trivial on keyboard, medium on pad (finding 26)
- Input/FocusManager.lua:3175 / :3180 / :3211 / :3239 | OnRenderTick | paused pad tick, cue hide, pointer hide, hide-lag line | 1 or 2 reads each or an early return | trivial (could be one handler)
- Input/FocusManager.lua:2659 | OnTick | deferred focus requests | returns when empty | trivial
- Input/InputModeDetector.lua:443 | OnTick | keyboard or pad detection | none | trivial with no pad, medium with one (finding 26)
- Input/InputModeDetector.lua:446 | OnRenderTick | mouse button edges | 3 reads | trivial
- Input/BumperChord.lua:417 | OnTick | LB + RB chord | enabled and mode gates | trivial on keyboard
- ZeD_Watch.lua:305 / :306 | OnPreUIDraw / OnPostUIDraw | worn-watch memo cleared | n/a | trivial
- ZeD_Surface.lua:113 / :114 | OnPreUIDraw / OnPostUIDraw | clip counter reset | n/a | trivial
- ZeD_MouseTick.lua:32 | OnPreUIDraw | left button sample | 1 read | trivial
- PlayerTheme.lua:228 | OnPreUIDraw | shared token table restored | n/a | trivial
- ContainerGates.lua:139 | OnPreUIDraw | frame counter | added once a gate registers | trivial
- ZeD_InvTip.lua:272 | OnPreUIDraw | hover tooltip follow | returns unless a row asked | trivial
- ZeD_HairBeard.lua:909 | OnPreUIDraw | avatar model pools | open states only | trivial
- ZeD_MessagesWindow.lua:1060 | OnPreUIDraw | Messages note above the dash | returns with no note or dash | trivial on foot
- ZeD_PausedLook.lua:240 | OnPreUIDraw | paused glass, pad hold | 3 pcall'd speed reads | trivial unpaused, small paused (finding 28)
- ZeD_PausedNotice.lua:105 | OnRenderTick | paused notice | isGamePaused first | trivial unpaused, medium paused (finding 28)
- ZeD_WheelGesture.lua:575 | OnRenderTick | wheel gesture | 4 table reads with no wheel | trivial
- Overrides/MiniMap.lua:55 | OnPreUIDraw | hide the mini-map | 500 ms gate | trivial
- Overrides/Prompts.lua:261 / :262 | OnTick / OnFETick | re-wrap prompt classes | 7 Lua compares | trivial
- Overrides/ItemMenu.lua:283, ObjectCardMedic.lua:77, PaperMap.lua:305, MapsTab.lua:2322 | OnTick | rename box, medic check, paper map, map pad | each returns on nil or mode | trivial
- Stations.lua:499 | OnTick | bench lock watchdog | 250 ms gate | trivial
- KillTracker.lua:416 | OnTick | stale log cleanup | every 300 ticks | trivial
- ZeD_PutBack.lua:48 | OnTick | tick counter | n/a | trivial
- ZeD_SplitSpeed.lua:180 / :181 / :193 | OnTick / OnTickEvenPaused / OnPreUIDraw | split-view speed strip | returns when split view is off | trivial (on two events: finding 27)
- ZeD_StepAside.lua:611 | OnTickEvenPaused | hand-back check | every 60 ticks | trivial
- ZeD_GuideBubble.lua:166 | OnTick | F1 guide bubble | returns once done | trivial (never removed)
- ZeD_Restock.lua:1365 | OnTick | restock runs, home check | 167 ms and 500 ms gates | trivial
- ZeD_RestockPin.lua:202 | OnTick | pinned list panel | 250 ms gate | trivial
- ZeD_Trade.lua:513, ZeD_TicketCards.lua:2770, ZeD_AdminTools.lua:778, ZeD_Admin.lua:966, ZeD_Community.lua:223, ZeD_Mail.lua:297, ZeD_ServerLink.lua:141, ZeD_RadioOps.lua:359 | OnTick | multiplayer sessions, queues, radio scan | each returns on an empty table or nil field | trivial
- ZeD_Studio.lua:457 | OnPostUIDraw | portrait shot | returns unless shooting | trivial
- shared/ZeD/Scale.lua:282 and :1161 | OnTick | root scale, theme re-apply | every 30 ticks | trivial
- AnimalsAlertPoller.lua:395 | EveryOneMinute | animals cache refresh | once a game minute | not costed
- QABridge.lua:156 / :160 / :216 | OnFETick / OnRenderTick | QA go-file poll | added only with -debug | none for players

One-shots that remove themselves (all fine): ZeD_CharacterWindow.lua:4150 and :7629; ZeD_WorldWindow.lua:6289 and :6337; ZeD_DpadWheels.lua:723, :740, :878, :1586; ZeD_QuickWheel.lua:225; ZeD_SandboxInGame.lua:909; ZeD_MainMenu.lua:1063; ZeD_Tutorial.lua:359; MechanicsTab.lua:2473; MapsTab.lua:745; WorldRoutes.lua:93 and :169 (the second only while a device is pinned); Overrides/Belt.lua:342; Overrides/CharacterInfo.lua:102 and :192; Overrides/ItemMenu.lua:205; Overrides/Stations.lua:70; Overrides/WorldMap.lua:71 and :94; SafeMode.lua:389; AnimalsQuick.lua:859 (only during a run); ZeD_Extras.lua:215 (only once the server's log is on); ZeD_MainMenuOptionGroups.lua:542 and ZeD_ModPicks.lua:382 (main menu); ModSupport/SPNCC.lua:1210 and CustomMapLabels.lua:50.

Only with their mod on (each returns at the top otherwise): ModSupport/SPNCC.lua:1250 and :1259, AutoHideHotbar.lua:164 (every 15 ticks), ResponsiveUI.lua:160, MaskaradsSummerCar.lua:697.

Not per frame but bursty: InventoryRenderer.lua:1954 and ZeD_WorldWindow.lua:6392 (OnContainerUpdate, a flag only; see finding 21), InventoryRenderer.lua:1956 and EquipDoll.lua:792 (finding 28), ZeD_Restock.lua:1416-1417 (one new table per object added or removed).

On foot: the dashboard has no tick handler and is hidden, so nothing in the driving findings runs. As a passenger everything but the controls runs.

## Bugs passed on the way

- BUG (memory, slow growth): weak tables do nothing in the game's Lua (the repo's own docs/reference/KAHLUA-JAVA-BACKEND.md:49 says `__mode` is ignored), so three "weak" caches never drop anything: ZeD_LootCard.lua:274 (`_cache`, keyed by item, filled from the frame path on every hover through ZeD_InvTip.lua:55), ModSupport/ImmersiveSearching.lua:88, :139, :245 (keyed by container), RecipeIndex.lua:120 (keyed by script item; bounded by item kinds, harmless). Scenario: a long looting session; every item ever hovered stays referenced with its facts tables, eaten and despawned items included, until the game exits. Fix: count the entries and start over past a few hundred, as `_modelCache` does.

- BUG (controller, rare): the main list's pad stops can keep old row places after the rows reorder. ZeD_CharacterWindow.lua:6610-6630 and ZeD_WorldWindow.lua:5262-5290 call the list dirty only when the count, the first row, the last row, the scroll, the view or the container changed. Scenario: a list at scroll 0 sorted by condition; an item in the middle wears down and the 1 s model rebuild moves it past its neighbors. Count, edges and geometry are equal, so the stops keep the old places; D-pad Down from a row lands on the row that used to be below it, not the one drawn below it, until the list scrolls. The side-by-side columns do not have this (`_charMCColumnDirty` compares every row, :1930-1936). Fix: compare every row as the columns do. The comment at :6608 ("renderer creates a new flatItems table each frame") is out of date.

- BUG (minor): a progress band can stay on an item after its action ended. ItemActionHooks.lua:108: `if not item then return end` sits before the transition logic. Scenario: the player queues "read a book", then an action whose class name contains "fix", "repair", "read" or "cook" but has no item field (fixing a generator, say). When the book ends, the function returns early every tick, so the book never gets its "complete" and its card keeps the reading band until the second action also ends. Fix: `if not item then head = nil end`, so the else branch sends the complete.

- BUG (a flash, not a crash): a dash plate still loading does not skip the frame. ZeD_Dashboard.lua:2264-2265 with ZeD_Plate.lua:773: `PL.draw` returns false while the picture loads, but the dash only tests the pcall status and carries on to draw the focus cues, the word PASSENGER, the gamepad hint tape and the lamp hover, and registers the controls. Scenario: get into a car whose dash design has not been shown this session, as a passenger or with a controller: PASSENGER or the dark hint strip shows at the foot of the screen with no dash under it for a frame or two (how long was not confirmed in game). Fix: `if eD == false then self:_ring(Focus); return end` after the status test.

- BUG (rate, not a crash): frame-count throttles run faster on fast monitors. ContainerControls.lua:63 (`CT.REFRESH = 15`) and EquipDoll.lua:624 count frames, so their walks run 2.4 times as often at 144 Hz as at 60 (finding 1 is the costly one). The other throttles moved to the clock on Nov 8; these two and the two `_goneTick` counters (ZeD_CharacterWindow.lua:6276, ZeD_WorldWindow.lua:3530) were missed.

- BUG (a cache keyed so it misses): the needle cache, ZeD_PixelParts.lua:346-352, keyed on an angle that never repeats (finding 4).

- Unguarded, not confirmed as a bug: KillTracker.lua:408-421 adds OnHitZombie, OnZombieDead, OnTick and OnPlayerDeath inside its OnGameStart with no "already hooked" flag (Restock, Bubbles, Trade and Medic all use one). If OnGameStart ever fires twice in one Lua state, every kill counts twice. Whether the game rebuilds Lua between games was not checked against the game. A one-line `_hooked` guard removes the question.

- Latent, not live: ZeD_Plate.lua:191-207 (`headRows`) keeps the night shading rows on the head unit keyed only by the light maps, not by the face's width and height. All six faces are 178 x 46 today, so nothing shows; a radio face of another size would get the previous face's rows at night.

- Never removed after its job: ZeD_GuideBubble.lua:166 stays on OnTick for the session after the bubble is done (one nil test a tick; harmless).

- Dead code: ZeD_Dashboard.lua:1470-2157 (`_plain`) and the siren's `_plain` cannot run since beta 21, because Settings.lua:658 `dashSimple()` always answers false (Lite draws the pixel Dash Elite). Not a cost; about 700 lines to retire.

- Note (split view, on hold): ReadMarks.lua:201-203 keeps one cache for one player; two players' windows asking in the same frame empty it on every call, so with read marks on every row recomputes every frame for both.

- No nil that can throw was found in an unprotected frame or tick path. The draw hooks run under `ZeD.Safe.guard`; the unprotected handlers (Messages frame, belt visibilityTick, SafeMode sync, the loot-page watch) read fields that are always set where they are made.

## Suggested order of work

1. Finding 1 (container buttons), with the frame-count bug: one file, removes the periodic spike.
2. Finding 2 (row records) and 6 (list overhead): one file, InventoryRenderer.lua, the largest steady cost with windows open.
3. Findings 3, 4 and 8 (dash state, needles, radio): the driving frame.
4. Findings 12 and 27 (the clock reads and the small leftovers): an hour's work, in all play.
5. Findings 10 and 17 (belt and action bar): the always-on HUD.
6. Findings 5 and 9 (item card), 11 (pins), 13 (weights), 15 and 16 (buttons' strings, focus refresh).
7. The rest as files are touched.

Each fix has a covering check already in the repo to run before and after: perf_now.lua for the scenes (HUD, both windows, the card, the tabs), perf_dashprof.lua for the dash, hud_perf_sim.lua for the moodles and the watch (same picture before and after, no game needed), and the release test for behavior.
