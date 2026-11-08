# ZeD-UI performance review: shipping Lua (read-only)

Scope: `/home/user/ZeD.UI/42/media/lua` (B42, Kahlua). I traced every finding from its caller to its cadence.
All paths below are relative to `42/media/lua/client/ZeD/` unless noted otherwise.
"Bridge call" means a Lua-to-Java method call. Each `pcall(function() ... end)` also allocates a closure.

## Already fine (checked, no action)
- **AnimalsAlertPoller.lua.** It already uses `cell:getAnimals()` once a game minute (lines 48-73). The 151x151 square walk is gone.
- **Measuring.** `ZeD.TM:MeasureStringX` / `getFontHeight` are memoized per font+string (`shared/ZeD/Scale.lua:718-797`). `ZeD.tr` is memoized (`shared/ZeD/Tr.lua:425-450`). `Atoms.truncateText` is memoized (`Atoms.lua:1574`). `catLabel` is cached. Plate colours, needles and rect merging are cached (`ZeD_PixelParts.lua`).
- **Overrides/TextScale.lua.** The lean draw calls are sound. One small leftover: `drawTextRight` and `drawTextCentre` measure through the raw `X.roleWidth`, not the cached `ZeD.TM`. Only 3 call sites use them, so it is not worth changing.
- **ZeD_Belt.lua.** Ammo is cached for 250 ms, slot names and key names are cached, the layout is cached. No hot issue.
- **ZeD_MainMenuMods.lua / ZeD_ModScan.lua.** Rows, counts and diffs are cached at 150 ms / 1 s, the scan is time-sliced at 6 ms, and the Workshop poll is throttled. Fine.
- **OnTick / OnRenderTick / OnPreUIDraw handlers.** All of them are cheap or already throttled: Bubbles, ItemActionHooks, FocusManager, InputModeDetector, Messages, RadioOps, Stations watchdog, KillTracker, Chat, Claims, Mail, Trade, MiniMap, Prompts, FlyerMap (1 s), Dashboard lux (250 ms).
- **Craft recipe rows / focusables.** Zone and element tables are reused (`CraftingCore.lua:1865-1920`, `3283-3312`).

---

## Findings, ranked by likely impact

### 1. Restock walks every square of the building once a second while a loadout is applied (HIGH, conditional)
- **Where.**
  - `ZeD_Restock.lua:265-290` (`R.scan`): it loops `x/y/z` over the whole `BuildingDef`. For each square it calls `getGridSquare` and `getBuilding`, then `scanSquare` (`:164-188`).
  - `scanSquare` does a lot per square: a `lootAllowed` pcall closure, `R.inReach` (4-6 calls), `getObjects`, and per object `getContainerCount`, `call(hasWater)` and more.
- **How often.**
  - `EL.plan` (`ZeD_EquipLoadout.lua:161-199`) recomputes `R.plan -> R.scan` once a second. It is called from `foldSummary` / `barParts` / `EL.drawSection` (`:525-549`, `:384-414`), so it runs every frame the Equipment tab shows with a loadout applied. That includes when the fold is closed.
  - `ZeD_RestockPin.lua:61-80` does the same once a second during a run.
  - `R.scan`'s own cache is keyed on the player's square string (`:271-272`). Any movement therefore forces a full rescan at the next once-a-second plan.
- **Why it costs.** A 20x20x2 house is about 800 squares at about 10-20 bridge calls each, roughly 10k calls in one frame. That is a 10-40 ms hitch every second in a large building.
- **Cheapest fix.**
  - Split the scan in two:
    - **The building's containers and taps.** Cache them per `R.bkey(b)` for about 10 s, or until `OnContainerUpdate` / `OnObjectAdded` / `OnObjectAboutToBeRemoved` fires.
    - **The reach part.** `scanReach`, 3x3 squares, is the only part that should follow the player's square.
  - Alternatively, time-slice the building walk with a coroutine, as `MS.step` does.

### 2. `CC.logicScan` hitch every 1.2 s on the Craft and Build tabs (HIGH while those tabs show)
- **Where.** `CraftingCore.lua:309-372`.
  - It rebuilds containers with `CC.buildContainers` (`:111-134`): per item, a pcall closure plus `getCategory` and `isEquipped`.
  - It builds a new Java `ArrayList` of every recipe whenever `win[dKey] ~= data`. Because of finding 3, `data` is a new object every 30 frames, so the list is in effect re-added on every scan, about 541 `list:add` calls.
  - It calls `logic:setRecipes(list)`. Java then recomputes the cached info for every recipe against the containers.
  - It then loops every recipe with `pcall(function() info = logic:getCachedRecipeInfo(r) end)`, which allocates a closure per recipe.
- **How often.** Every 1.2 s while Craft (hand or bench) or Build renders. The tab calls it from `CraftingTab.lua:541` and `BuildingTab.lua:401`.
- **Why it costs.** It is one large frame of Lua plus Java work, a periodic hitch that grows with recipe count and inventory size.
- **Cheapest fix.**
  - Key the `ArrayList` on the recipe source (`_flatRecipes` or the bench source), not on the per-refresh `data` table.
  - Only call `setContainers` / `setRecipes` when a cheap signature changes: the container count, each container's item count and `getCapacityWeight`, the bench, and the perk levels. Otherwise skip the scan.
  - Use `pcall(logic.getCachedRecipeInfo, logic, r)` instead of a closure.

### 3. Craft and Build rebuild every recipe row table every 30 frames (MEDIUM-HIGH)
- **Where.**
  - `CraftingTab.lua:215-283` (`gatherData`). For each of about 541 recipes it calls `getPerkLevel`, `pcall(function() isRecipeKnown end)` and `ZeD.textCase` up to 2 times, then allocates a new rd table. `CC.carryStatus` then builds a name map of all of them (`CraftingCore.lua:378-389`).
  - `BuildingTab.lua:206-243` does the same for Build.
  - `CraftingTab.lua:550-557` also does a linear search for the selected recipe by name every frame.
- **How often.** Every 30 frames: 2 times a second at 60 fps, 5-8 times at 144-240 fps.
- **Why it costs.** About 1,000+ bridge calls, 541 closures and 541+ tables per refresh, plus GC churn.
- **Cheapest fix.**
  - Mutate the rd tables in place, as `JournalTab.gatherRecipeData` already does (`JournalTab.lua:420-440`).
  - Read each perk level once per refresh into a `{skillName -> level}` map. There are about 10 perks, not 541 lookups.
  - Cache `stationTag` / `boundShort` on the entry, since they are constant.
  - Use an ms-based interval of 1-2 s.
  - Keep a `name -> rd` index for the selected lookup.

### 4. The inventory list model is forcibly rebuilt and re-sorted every 30 frames, per open column (MEDIUM-HIGH for big containers)
- **Where.** `InventoryRenderer.lua:1097` (`MODEL_REFRESH = 30`) and `:1261-1265`. The rebuild is `buildItemModel` (`:1117-1236`).
  - Per item, `heldByPlayer` runs 2 pcall closures (`:1110-1115`), plus `ContainerGroups.groupOf` and `catKey` (2 Java calls).
  - The sort comparators (`makeSorter`, `:70-121`) call `getName`, `string.lower`, `catKey` and `getUnequippedWeight` inside every comparison.
- **How often.** Every 30 drawn frames for each visible column, even when nothing changed. Multi-column view draws up to 4 or more columns.
- **Why it costs.** A 300-item crate takes about 2,500 comparisons at 2-4 bridge calls each, plus about 600 closure pcalls, about twice a second per column. The columns refresh on the same cadence, so they can hitch together.
- **Cheapest fix.**
  - Decorate-sort-undecorate: compute `{item, nameLower, cat, cond, wt}` once per item, then sort on those keys.
  - Build an equipped/worn set once per build (both hands plus `getWornItems`) instead of 2 pcalls per item.
  - Make the forced refresh time-based (about 1000 ms), and stagger it per column (offset by column index).

### 5. World window container refresh every 30 frames, with radios and vehicles bundled in (MEDIUM)
- **Where.** `ZeD_WorldWindow.lua:2817-2905`.
  - `buildWorldContainers` (`:2544+`) calls `_floorContainer:clear()` and then `AddItem`s every ground item on the 9 squares.
  - It also runs per-square `canReachTo` and the safehouse check, and handles corpses: `getText` plus 2 pcall closures each.
  - The same tick also runs `RadioTab.buildWorldRadios` (`RadioTab.lua:149-208`) and `MechanicsTab.refresh`. The latter iterates every vehicle in the cell (`MechanicsTab.lua:166-202`, 2 pcall closures per in-reach vehicle) even when those tabs are not open.
- **How often.** Every 30 frames while the World window's container strip draws.
- **Why it costs.** Clearing and refilling a Java container with a large floor pile, plus the vehicle-list iteration, gives a periodic hitch that scales with FPS.
- **Cheapest fix.**
  - Use an ms interval of 300-500 ms, and rebuild at once on a square change or `OnContainerUpdate`.
  - Skip the floor clear and refill when the per-square world-object counts are unchanged (a signature check).
  - Refresh radios and vehicles only while their tab is active, or at a slower 1-2 s.

### 6. Animals ranch zone view: per frame and per row, nothing cached (MEDIUM)
- **Where.**
  - `AnimalsTab.lua:2130-2135`, every frame:
    - `getZoneByName` (`:190-201`) walks all designation zones with a pcall per zone.
    - It then calls `player:setSeeDesignationZone(true)`, `resetSelectedZonesForHighlight()` and `addSelectedZoneForHighlight(id)`.
  - `drawAnimalRow` (`:1628-1710`), for every visible row:
    - `AD.getConditionTags`, which makes 7 Java checks and allocates the tags table plus tag tables.
    - `AD.resolvePortrait`, which does `string.lower`, `gsub` and Java getters, then `getTexture(path)`.
    - `getAgeText` (a pcall), `getHealth/Hunger/Thirst`, 3 `getText` calls and string concatenation.
    - `tagWidth` and `MeasureStringX`.
- **How often.** Every frame while a zone is open.
- **Why it costs.** About 25-30 bridge calls and about 5 tables per row; with about 10 visible rows, about 300 calls and 50 tables per frame.
- **Cheapest fix.**
  - Cache a row model per animal: name, texture object, tags with widths, the info line and the three dot values.
  - Refresh it on the `SORT_CACHE_MS` (500 ms) cadence that `sortedRoster` (`:343-359`) already uses.
  - Look the zone up with the Java `DesignationZoneAnimal.getZoneByName` (already used at `:499`), or cache it by name.
  - Re-highlight only when `state.zoneName` changes.

### 7. Animals `hooksNear`: a 41x41 square scan every 2 s (MEDIUM hitch)
- **Where.** `AnimalsTab.lua:1890-1918`. It covers 1,681 squares, calling `getObjects` and then `instanceof` per object. The sort comparator then calls `o:getSquare()` and the player's x and y in every comparison.
- **How often.** Every 2 s while the butcher hooks section draws (`drawHooks`, `:1920`).
- **Why it costs.** About 5-8k bridge calls in one frame, a visible hitch every 2 s.
- **Cheapest fix.**
  - Precompute the distance once per hook before sorting.
  - Spread the walk over frames (a few rows per frame), or shrink the radius. Only the 4 nearest hooks are shown, so a widening ring search can stop early.
  - Alternatively, refresh on `OnObjectAdded` / `OnObjectAboutToBeRemoved`.

### 8. `ZeD.Atoms.wrapText` is not memoized (MEDIUM, broad)
- **Where.** `Atoms.lua:1542-1564`. Each call runs `gmatch`, builds a words table, and builds a fresh prefix string per word (O(n^2) characters), measuring each prefix.
- **Who calls it every frame.**
  - `Molecules.drawDetailCard` (`Molecules.lua:5020/5030`), the hover cards.
  - `drawNeedsLine` / `drawEmptyLine` (`:4954/4973`) and the help balloon (`:4405`).
  - The Moodle note (`ZeD_Moodles.lua` `_drawChip`), `ZeD_RestockPin:prerender`, `ZeD_Belt:_cardH`.
  - About 128 call sites in all.
- **Why it costs.** Allocations plus measures every frame. Every prefix string also becomes a key in the measure cache (`MC_MAX = 3000`, `shared/ZeD/Scale.lua:732`). That fills the cache with throwaway strings and forces generation turnover, which costs real measures elsewhere.
- **Cheapest fix.**
  - Add the same two-generation memo that `truncateText` has: key `font -> maxW -> text`, cleared on `ZeD.Text.measureEpoch()`.
  - Return the cached table as read-only. Callers only iterate it.

### 9. The item card rebuilds its whole model every frame (MEDIUM while a card is open, which is often)
- **Where.**
  - `ItemCard.lua:1513-1522` calls `ItemCardOrganism.lua:1199+` (`renderBody`).
  - That calls `ItemFactsPanel.factsFor(item)` at `:990` and `:1068` (`ItemFactsPanel.lua:395-405`). Factories run dozens of `safeGet` pcall bridge calls, `string.format` and `ZeD.tr`, and allocate group and row tables.
  - It also calls `headerVerbsForContext`, `readMarks` and `topStatsForItem`.
- **How often.** Every frame the card is visible (the Character or World drawer, the Equipment card).
- **Cheapest fix.** Memoize the card model per item for about 250-500 ms. Invalidate it on `setItem`, on an action start or complete (`ItemActionManager`), and on a fold toggle.

### 10. Always-on HUD: the Moodles layer (LOW-MEDIUM, but always running)
- **Where.** `ZeD_Moodles.lua:532-536` (`OnPreUIDraw`) calls `_place` (`:249-320`), which calls `M.active` (`:150-165`).
  - `M.active` makes about 26 `MoodleType[...]` lookups and 26 pcall'd `getMoodleLevel` calls, plus a table per active moodle, every frame and per player.
  - In bottom mode, `M.backing` (`:167-183`) re-reads `getCore():getGood/BadHighlitedColor()` with 4 pcalls per moodle per frame.
  - `_noticeTick` (`:422-458`) allocates a `cur` table every frame.
- **Cheapest fix.**
  - Compute `M.active` on `OnTick`, or every 100-250 ms, into a reused list.
  - Cache the two highlight colours. They only change with the options.

### 11. Always-on HUD: the Watch (LOW-MEDIUM, always running)
- **Where.** `ZeD_Watch.lua:547-650` (`prerender`).
  - `_wornWatch` (`:247-262`) walks the worn items through a `_safe` closure. It runs at `:581` and again through `W.beltWatch` (`:276-283`) at `:594`, and the belt's layout asks too. That is 2-3 walks per frame.
  - The `_safe(function() ... end)` closures for `isAlarmSet` / `getHour` allocate every frame.
  - `_hitsFrom` (`:529-540`) allocates new hit tables every frame.
- **Cheapest fix.** Cache the worn watch per player, keyed on the frame or refreshed on `OnClothingUpdated`. Reuse the hit tables.

### 12. Frame-count throttles scale with FPS and line up on the same frame (SYSTEMIC, LOW-MEDIUM each)
- **Where.**
  - `CraftingTab` / `BuildingTab` / `JournalTab` recipes: 30 frames.
  - `InventoryRenderer` `MODEL_REFRESH`: 30.
  - World and Character container timers: 30 (`ZeD_WorldWindow.lua:2817`, `ZeD_CharacterWindow.lua:3356`).
  - `Stations.SCAN_EVERY`: 30 (`Stations.lua:34`).
  - `ObjectCards` `REFRESH` 15 / `BROWSE_EVERY` 60 (`ObjectCards.lua:55-56`).
  - Health, Skills, Equipment and Journal data: 15 (`HealthTab.lua:1359`, `SkillsTab.lua:962`, `EquipmentTab.lua:1236/1344`, `JournalTab.lua:597`).
  - Skills training: 30 (`SkillsTab.lua:1037`).
  - `CC.gatherDetail` `CONTAINER_INTERVAL`: 90 (`CraftingCore.lua:50`).
- **Why it costs.**
  - At 144-240 Hz all of these run 2.4-4 times more often than designed, for the same data.
  - Counters that start together, such as several 30-frame timers created when a window opens, fire on the same frame, so their costs stack into one hitch.
- **Cheapest fix.**
  - Replace the counters with `getTimestampMs()` deltas.
  - Add a per-window phase offset so heavy refreshes land on different frames.
- **Notes.**
  - `SkillsTab.gatherTrainingData` (`SkillsTab.lua:402-447`) walks the whole main inventory plus about 100+ books (`getAlreadyReadPages` and `getAlreadyReadBook():contains`). It runs unconditionally, even with the training section folded. Gate it on that section being open.
  - `HealthTab.gatherData` (`:446-534`) makes about 17 parts x about 20 getters per refresh.

### 13. `Stations.scan` every 30 frames in some craft views (LOW-MEDIUM)
- **Where.** `Stations.lua:194-247`. It covers 81 squares; per object it calls `getMasterObject` plus `ST.classify` (up to 4 pcall'd `getComponent` calls) and `CanOpenWindowFor`.
- **When.** Every 30 frames while a Hand-mode station recipe's detail draws (`CraftingCore.lua:2317` `nearestFor`) or the station dropdown is open. `ST.entryFor` forces a scan (`:457`).
- **Cheapest fix.** Use an ms interval of about 1 s, and rescan when the player's square changes.

### 14. The World window rebuilds its focus list every frame, even with mouse and keyboard (LOW-MEDIUM)
- **Where.** `ZeD_WorldWindow.lua:4898-4925`. `_buildWorldPanelFocusables` (`:1013`) runs every frame for Craft, Build, Animals, Maps, Radio, Vehicle and Furniture. For Craft it walks every recipe zone (about 541+) and allocates `occRow` / `occSec` tables (`CraftingCore.lua:3283-3312`).
- **Why it costs.** This is controller-only work, but it runs while the mouse is in use.
- **Cheapest fix.** Skip the catch-up while input mode is kbm. Rebuild once on the switch to gamepad (the `ZeD_InputModeChanged` event already exists). Check whether the Character window has the same pattern.

### 15. Low-priority notes
- `CookingTab.lua:653/664` re-groups and `table.sort`s the cached ingredient rows every frame. It is Lua-only and small; sort once when `ingCache` changes.
- `ZeD_Pins.stats` (`ZeD_Pins.lua:124+`) runs from both windows' `prerender`. It allocates 2 closures per pin per frame plus `getItemWithIDRecursiv`. There are few pins, so the cost is small.
- `FlyerMap.checkVisits` (`FlyerMap.lua:47-70`) iterates all `PrintMediaDefinitions.MiscDetails` with string concatenation once a second. It could precompute a flat list of rectangles.
- `Atoms.truncateText` keys on the fractional `maxW`. During drawer and resize animation every frame misses, and each miss's binary-search prefixes also flood the measure cache. Rounding `maxW` with `math.floor` before the lookup would fix this.

---

## Top 10, short list
1. **Restock walks the whole building.** `ZeD_Restock.lua:265-290`, about once a second while a loadout is applied: split the building cache from the reach part.
2. **`CC.logicScan` hitch.** `CraftingCore.lua:309-372`, every 1.2 s on Craft and Build: rebuilds the ArrayList and calls Java `setRecipes`. Gate it on a signature and key the list on the recipe source.
3. **Craft and Build rebuild every rd table.** `CraftingTab.lua:215-283` and `BuildingTab.lua:206-243`, every 30 frames, about 541 tables plus closures. Mutate in place and map perk levels once.
4. **Inventory model rebuild every 30 frames.** `InventoryRenderer.lua:1097/1261`: comparators call Java and `lower()` per comparison, plus 2 closure pcalls per item. Precompute keys and use an ms interval.
5. **World container refresh every 30 frames.** `ZeD_WorldWindow.lua:2817-2905`: floor clear and refill, radios and all cell vehicles. Use ms, a signature check and per-tab gating.
6. **Animals zone view per frame.** `AnimalsTab.lua:2130` and `:1628`: zone walk, re-highlighting and about 25 calls per roster row. Cache row models for 500 ms.
7. **Animals `hooksNear`.** `AnimalsTab.lua:1890`: a 1,681-square scan every 2 s. Slice it or shrink it; precompute sort distances.
8. **`wrapText` is not memoized.** `Atoms.lua:1542`: per frame in cards, help and notes, and it pollutes the measure cache. Memoize it like `truncateText`.
9. **Item card rebuilt every frame.** `ItemCardOrganism.lua:990/1068` (`factsFor`): memoize the card model for about 300 ms.
10. **Always-on HUD.** Moodles `M.active` makes about 26 pcalls per frame (`ZeD_Moodles.lua:150`), and the Watch walks the worn items 2-3 times per frame (`ZeD_Watch.lua:247/581/594`). Throttle both or drive them by events.

Plus, systemically: convert the frame-count throttles to ms and stagger them (finding 12).
