# Mechanics (Vehicle) tab: map for the gamut sweep (QA, Nov 26 2026)

A read-only map of ZeD's Vehicle tab (the mechanics tab) against the game's own vehicle mechanics (B42: the mechanics window ISVehicleMechanics, its part menu, ISVehiclePartMenu and the vehicle timed actions), written before the sweep scripts. It also maps the surfaces the tab hands off to (the animal trailer page, a server's vehicle claims) only as far as the tab reaches them. Line refs are as read on Nov 26. Nothing was run.

**The tab is on the World window, not the Character window.** ZeD_WorldWindow.lua declares it in WORLD_TABS as id "vehicle", ZeD's key UI_ZeD_World_TabVehicle, group 2, after Radio (WW:155-161); MechanicsTab.lua has no addTab and registers its renderer in the World window's dispatch table (MT:2382-2385, WW:1909). Its focus zone is worldTabContent (MT:957, 965). The game's mechanics window never shows while ZeD runs (VM:24-35).

Short names: MT MechanicsTab.lua, VM Overrides/VehicleMechanics.lua, TA Overrides/TrailerAnimals.lua, TR MechTrailer.lua, WW ZeD_WorldWindow.lua, CC CraftingCore.lua, MO Molecules.lua (ZeD.Disclose), EX ZeD_Extras.lua, EC ZeD_ExtrasCards.lua, SX server/ZeD/ZeD_ServerExtras.lua, FM Input/FocusManager.lua, DW ZeD_DpadWheels.lua, ZUI shared/Translate/EN/UI.json (ZeD's words).
The game's files (media/lua unless noted): ISVM client/Vehicles/ISUI/ISVehicleMechanics.lua, ISVPM client/Vehicles/ISUI/ISVehiclePartMenu.lua, ISVMN client/Vehicles/ISUI/ISVehicleMenu.lua, OMUA client/Vehicles/TimedActions/ISOpenMechanicsUIAction.lua, VEH server/Vehicles/Vehicles.lua, IVP shared/Vehicles/TimedActions/ISInstallVehiclePart.lua, UVP .../ISUninstallVehiclePart.lua, TEP .../ISTakeEngineParts.lua, FVP shared/TimedActions/ISFixVehiclePartAction.lua, BTA shared/TimedActions/ISBaseTimedAction.lua, TAQ client/TimedActions/ISTimedActionQueue.lua, IPCM client/ISUI/ISInventoryPaneContextMenu.lua, TT shared/Translate/EN/Tooltip.json, VS media/scripts/generated/vehicles/template_*.txt.
FEATURE_MAP rows 269-270 and 605-606 cite old MT lines (about 124 lines off: openFromAction is MT:2556, isVisible MT:291, isInspected MT:2602, onClick MT:2390, onRightClick MT:2422, buildFocusables MT:2459, openTrailer MT:2608; row 1280's addExtras is MT:579, not 508). Row 270 names `"mech:sort:<key>"`; the stops are `mech:sortMenu` and `mech:sortRow:<id>` (MT:2159, 2200). VM:24 and VM:40 are still right.

## 1. What the tab does

**Getting there:**
- The World window's tab strip, tab "vehicle" (V), shown while a vehicle is in reach or an inspected or pinned one is within six tiles (MT.isVisible MT:291-294, buildVehicles MT:211-247: 4.5 tiles from the car's center on the same floor, 6 for a looked-at or pinned car, always the car he sits in; a car and its trailer come as a pair, MT:230-244). Drawer 480 (WW:1878), the half card 220 when held in (WW:2241-2245, 2265-2269).
- When it hides while open, the window falls back to Loot and the look ends (WW:2165, 7070-7074).
- The game's every way into its mechanics window ends in ISOpenMechanicsUIAction: the V radial's Mechanics slice (ISVMN:186-188, 299), the U key, the hood (Vehicles.Use.EngineDoor). Its perform is hooked to MT.openFromAction (VM:21-36, MT:2556-2600): the car is marked looked at (INSP), its mechanic flag and physics set (MT:143-149), the World window opened, unrolled and moved to the tab.
- ISVehicleMenu.onMechanic is wrapped: on a car already looked at, on foot, the tab opens at once; U with the tab up closes the whole World window (VM:37-58).
- KISS #60: the car's right-click gets Enter Vehicle and Vehicle Mechanics (the game's world menu has no mechanics entry, ISVMN:607 is commented out) (VM:62-84).
- E at an open hood on a looked-at car shuts the hood and ends the look instead of looking again (VM:87-100, MT:199-209).
- The D-pad World wheel's Tabs slice lists Vehicle, "No vehicle" when buildVehicles finds none (DW:1144-1146).
- The trailer's Check Animals (world menu and wheel) opens the tab on the trailer, pinned, scrolled to its animals; it skips the walk when the trailer is already in reach (TA:36-65, MT:2608-2628).
- Safe mode: every hook hands back to the game (VM:25, 41, 67, 91; TA:40, 58).

**Data (MT):**
- Vehicles: every car in the cell, read with the tab open, else every 1 s (WW:3449-3452, WREF WW:66); sorted by distance (MT:245).
- Looks: INSP[vehicle id] = { vehicle, hood }, kept across the window's closes in a module table (MT:77-80). A look ends past six tiles, when the car is gone (isRemovedFromWorld or no square, MT:159-164), when the World window closes (WW:3914-3916) or when the window leaves the Vehicle tab (WW:2522, 2538, 2568, 5079 call _tabLeft, which ends every look, WW:7070-7074, MT:186-195). Ending a look clears the car's mechanic flag and queues the hood shut when he stands at it (MT:167-182).
- Parts (cachedParts MT:409-424, 250 ms): every part not in category "nodisplay", with its translated name (IGUI_VehiclePart<id>), category, condition (0 when missing), missing (an item type, no item and an install table, MT:299-302), smashed (a destroyed window, MT:303-306), a state line (MT:308-340: battery charge, tire psi, fluid amount, door open or locked, seat occupied, container weight), the part it sits under (parentOf MT:367-390, from the install and uninstall tables' requireUninstalled and requireInstalled; the engine bay under the hood).
- Items in reach (itemsFor MT:496-504, 700 ms): the game's VehicleUtils.getItems (VEH:1026-1053): the inventory, every bag in it and every container the game's (hidden) loot page lists, only items above 0 condition.
- Overall condition (MT:427-438): the game's recalculGeneralCondition (ISVM:104-120): every part, missing ones as 0, rounded to a whole number (the game: two places).
- The key line (keyState MT:470-491): On you, Key in ignition, Hotwired, Not needed (VehicleEasyUse) or No key; the engine rows use the hood's rule (VEH:1380-1389).

**The view (MT.render MT:2354-2380, renderSplit MT:2211-2337):**
- Row 1: one tab per vehicle in reach (two of one name carry their place, "Nyala (2)") and the shown car's mechanic type as a tag (MT:2216-2242, 992-1009).
- The progress band, only on a looked-at car: the running vehicle job's name and bar, a Cancel; then a "Done" or "Failed" flash for 1.6 s from OnMechanicActionDone (MT:1253-1280, 2631-2641). A trailer's band shows its animal job instead (TR:495-512).
- Left, the part list, a fixed 240 units (CC.PANE_W_SPLIT, CC:43; MT:2285):
  - By section: the game's categories in CAT_ORDER, a brake and a suspension under their tire, a window under its door, the engine bay under the hood (MT:70-73, 1473-1530). By condition: worst first, missing and smashed at the top, earned at Mechanics 4 (MT:1466-1486).
  - A row: a status dot, the name (indented under its parent), "Locked" for a locked door, then the percent, or a red Missing or Smashed tag (MT:1670-1726). Category rows fold (MT:1658-1668).
  - Before a look: the list's head and "Inspect the <car> to read its parts." (MT:1729-1735).
  - A trailer's animals come before its parts (TR.drawSections, MT:1649-1652).
- Right, no part chosen: the car figure (MechFigs, tinted per part by condition, wear baked in, missing and smashed parts as a pulsing red rim, MT:1063-1189), then the summary: Overall with bar, "n missing, n worn" (worn = 60 or less), engine power, quality and loudness, weight, fuel, battery charge, key, tow link, a server's claim row (MT:1290-1368). Before a look: Overall "?", Not inspected, type, distance, key (MT:1779-1796).
- Right, a part chosen (renderCardBody MT:1807-2032):
  - icon, name, category;
  - the step before: "Take off first:" or "Put on first:" and a button to that part's card (stepBefore MT:1534-1552, 1854-1876);
  - for each greyed verb shown, its NEEDS line; the folded "With ... you could ..." row for the verbs you can't do yet (MT:1878-1893);
  - the readings (cardStats MT:1373-1418): condition, item, engine quality, loudness, power and key, weight, remaining, pressure, fluid, capacity or seat, braking, muffler, door open and locked, broken lock, window open, temperature, friction, type; the work place (the part's area) unless it repeats the name (MT:1895-1902); the condition bar;
  - Install picked: "From your bags and nearby", one row per item in reach that fits, best condition first, with where it is; then each fitting type with none near (installPicks MT:696-719, 1933-1967);
  - Repair picked: one row per fixing and fixer, "+N% | N% success", the skill, why it is grey (fixRows MT:722-770, 1969-1996);
  - Install or uninstall picked: the success and failure bar when failure is above 0 (MT:1998-2012);
  - About: the game's IGUI_Vehicle_CondInfo<id> (MT:2014-2025).
- The footer (renderFooter MT:2053-2165): Sort at the left (Category, Condition greyed below Mechanics 4); the part's verbs at the right, the main one last; with no part chosen, Inspect before a look and Close hood while the hood is open, plus a server's Claim or Release (MT:2253-2270, EC:378-406). Short of room, greyed verbs leave first, then the first ones; the main one stays (MT:2121-2131).
- A destructive verb (Smash, Take engine parts) asks in the footer first (MT:545, 1621-1626, 2063-2076).

**Verbs (verbsFor MT:590-620, needsCompute MT:796-891, runVerb MT:896-922), each through the game's own handler:**
- Install: the picked item, ISVehiclePartMenu.onInstallPart (ISVPM:163-199): out of the car, the item and the table's tools to the inventory, the walk to the area, tools equipped, the hood opened and shut around ISInstallVehiclePart. Lit when a pick exists and the game's canInstallPart (VEH:894-918) passes.
- Uninstall: onUninstallPart (ISVPM:201-232), lit on canUninstallPart (VEH:921-957). A server's vehicle claims grey it on another's car (MT:882-887, EX:98-103; the server refuses the same, SX:323-324).
- Repair: the picked fixing and fixer, ISInventoryPaneContextMenu.onFix with the part (IPCM:2512-2529): the materials moved, ISFixVehiclePartAction; no walk (the game's too). Offered when the part is repairable on the car and the item has fixes (MT:599-602), as the game (ISVM:220-229).
- Inflate and Deflate: onInflateTire and onDeflateTire (ISVPM:290-312). Inflate gone when the tire is at its capacity + 5, Deflate when empty (MT:1454-1459).
- Open and Close window: only while he sits in a car (MT:606-609), onOpenCloseWindow (ISVPM:346-358).
- Smash window: onSmashWindow (ISVPM:367-378), asks first.
- Repair engine and Take engine parts: ISVehicleMechanics.onRepairEngine and onTakeEngineParts (ISVM:418-449, 463-493); Mechanics at the car's engine repair level, a wrench, engine parts for the repair, the hood's key rule (MT:833-853). Take engine parts asks first.
- Repair the lightbar: onRepairLightbar (ISVM:451-461).
- Inspect: ISVehicleMenu.onMechanic, the game's walk to the hood and look (MT:2257-2259, ISVMN:962-1003, OMUA:46: 200 ticks less 13.3 per Mechanics level).
- Close hood: the walk to the hood and ISCloseVehicleDoor (MT:2260-2267).
- X or right-click on a part: the game's own part menu (doPartContextMenu, on the hidden mechanics window) rendered by ZeD's context-menu hook (MT:925-936, 2422-2435).
- Extras: another mod's support file can add verbs and follow the part menu (MT:550-588); today only ModSupport/MaskaradsSummerCar.lua.
- After each verb the item, needs, fix and part caches drop (MT:920-921).

**Settings:** the hidden-actions setting (ZeD.Settings.hiddenActions): folded (default: verbs you can't do fold into one row), all (shown greyed with NEEDS lines) or hide (MO:5262-5293, MT:1602). Sort, folds, scrolls, chosen car, card and picks live on the window for the session (MT:125-135). Also: UI scale, text size, theme (the figure's alphas per theme, MT:1096-1104), the player's Mechanics level (By condition, the needs rows, the chances).

**Lite:** no branch in MT or TR.

**Pad (MT:2459-2551, focus zone worldTabContent):**
- Row 1: mech:veh:<i>, only with more than one car (MT:2238-2242).
- List: mech:cat:<cat> (A folds), mech:row:<part id> (A opens or closes the card; X the game's part menu, MT:2482-2486).
- Card: mech:step, mech:more (A opens the folded row), mech:pick:<i> (only owned items), mech:fix:<i> (grey ones too).
- Footer: mech:sortMenu, then with the list open only mech:sortRow:area and mech:sortRow:cond and the box (MT:2464-2467); mech:verb:<id> (X the part menu, MT:2487-2491), mech:inspect, mech:closehood, mech:xclaim, mech:xrelease; mech:confirm:no and mech:confirm:yes (focus lands on No, MT:1624); mech:cancel on the band.
- Trailer page: mech:an:, mech:load:, mech:open:, mech:lid, mech:tow, and on an animal mech:av:, mech:back, mech:feed:, mech:water:, mech:openlid, mech:more (TR:630-1279).
- B: shuts the Sort list, the question, the card or the animal (MT:2471-2481). With none open there is no onCancel, so FocusManager stops the running action (FM:1696-1703). The comment at MT:2457 ("B with neither leaves the tab as before") is not what happens.
- A card opened lands focus on the first lit verb stop, else the first verb, else the step, a pick or a fix row (MT:2523-2551).
- A grey verb is a stop; A on it picks it (its picks and needs show) and runs nothing (MT:1621-1623).
- The right column is one scrolled view; focus follows once per stop (MT:2313-2333, 2493-2504).

**Small screens:** the list is a fixed 240 units and the right column takes what is left (MT:2285-2287). The tab gets the half card, 220, whenever the drawer is held in (WW:2265-2269, 2241-2245): at 1280 wide that is any UI scale with the inventory open. Names are cut with "..." (MT:1718, 1835, 1949). The figure is a whole zoom, at least 1x, clipped by the column (MT:1086-1090).

**Related surfaces (reached from the tab):**
- The animal trailer page (TR): the animals before the parts, Load from here (the game's Add Animal list), Take out and Grab (walkAdj to the back, then ISRemoveAnimalFromTrailer, TR:438-443), the lid, a container's Open (walks, then selects it in Loot, TR:421-428), Info (opens the Animals tab, TR:430-436), feed and water, the tow link that flips between car and trailer (TR:446-460, 664-677).
- A server's vehicle claims: the owner row, Claim and Release with a question (EC:354-420).
- The dash (ZeD_Dashboard.lua): not reached from the tab; the key line borrows its "No key" words (MT:490).

## 2. Against the game (steps)

| Job | Game | ZeD Vehicle tab |
| --- | --- | --- |
| Look the car over | U, or V and Mechanics (1-2), the walk and look | The same, or right-click Vehicle Mechanics (2); the tab opens |
| Come back to a car looked at | U opens the window again; it stays open while the inventory is used | The tab while it is up; leaving the tab or the window ends the look: Inspect again (M7) |
| Take a tire off | Right-click its row (1), Uninstall (1) | Its row (1), Uninstall (1) |
| Put a tire on | Right-click (1), Install (1), the type (1), the item (1) | Its row (1), a pick if not the best (1), Install (1) |
| Repair a part | Right-click (1), Repair (1), the fixer (1) | Its row (1), Repair if not focused (1), a recipe row if not the first (1), Repair (1) |
| Inflate a tire | Right-click (1), Inflate (1) | Its row (1), Inflate (1) |
| Repair the engine | Right-click (1), Repair engine (1) | Engine (1), Repair engine (1) |
| Take engine parts | Right-click (1), Take engine parts (1) | Engine (1), Take engine parts (1), Yes (1) |
| Smash a window | Right-click (1), Smash (1); or the car's world menu (2) | Its row (1), Smash (1), Yes (1) |
| See why a verb is grey | Hover the greyed option's tooltip | The NEEDS line on the card; folded by default (1 to open) |
| Find the worst part | Read both columns | Sort (1), Condition (1), at Mechanics 4 |
| Know what to take off first | The tooltip's red line | The step-before row and its button (1) |
| Siphon, add gas, refuel | V, the gas tank slice, the option (3) | None in the tab |
| Lock doors or the trunk, open a door or the hood | The radial (2) | None; Close hood only |
| Radio part's Device Options | V, Device Options (2) | None in the tab |

ZeD has, the game doesn't: the car figure with wear, the overall and per-part readings in one column, By condition, the step-before button, the install list with where each spare is, a question before Smash and Take engine parts, several cars side by side, the trailer's animals in the same page, the key line, a server's claims.

The game has, ZeD doesn't: its part menu works only on foot and not while paused; "Can be repaired once uninstalled." (ISVM:846-853, TT:209); the fitting types listed under Install while no spare is near (the tab folds Install away, MT:809-811); the fuel and lock verbs (ISVMN:179-181, 1056-1103, 1122); the window staying up while the inventory is used.

## 3. States to sweep

- **Cars:** a sedan, a pickup, a van, a step van, a sports car, a police car (lightbar, radio), a burnt car, a smashed wreck; an animal trailer, a covered trailer; a car towing a trailer; two cars of one model; a modded car (Summer Car add-on loaded and not).
- **Looks:** not looked at; looked at; looked at, then the Loot tab, another tab, the window closed, a walk past six tiles; two cars looked at; E at the open hood; U with the tab up; looked at from inside the car (the game's exit first).
- **Parts:** every category at 100, 61, 60, 21, 20, 1 and 0; missing; smashed window; a locked door, a broken lock; a seat occupied; a trunk with items; a gas tank with fuel (requireEmpty); a battery with the engine running; a tire at 0 psi, low, full, over.
- **Install:** no spare near; one spare in the bag, on the floor, in a crate, in the trunk of the same car; two spares of one type and condition in two places; two types for one part (Normal and Regular tires); a spare at 0 condition; without the jack, the lug wrench, the recipe (Basic Mechanics); Mechanics below the skill (the chance bar); a brake with its tire on.
- **Uninstall:** each category; with the hood locked and no key, with a door open (the hood's rule); at Mechanics 0 against a skill 5 part (the failure roll); a claimed car on a server.
- **Repair:** a part at 100 with materials; a part at 40 with one material, with a partial material (uses short), without the skill; the fixer in a bag, on the floor; twice in a row.
- **Engine:** Repair engine at 100, at 50 with and without parts, below the engine repair level, no wrench; Take engine parts at 11 and at 10.
- **Presses:** each verb pressed twice (mouse, pad A A), during the walk and during the action; B and the band's Cancel mid-chain; the window shut mid-chain; the tab left mid-chain; a verb while paused; a verb while seated, while driving.
- **Changes while open:** a part taken by another player; the spare picked up by someone else; the car driven off past six tiles; the car removed (admin, torch); the trailer unhitched; a new car parked closer (the strip reorders).
- **Pad:** every stop; A on a row then A again; X on a row and on a verb; B with and without a card, list, question.
- **Layout:** 1280x720 and 1280x800 at UI scale 1 and 2 with Large text, the inventory drawer open and shut (the half card); 4K; a long part and car name; a car with every footer verb at once.
- **Settings:** hidden actions folded, all, hide.
- **Languages:** EN, DE, ES, FR, RU, JP: the part and category names (the game's), the step-before words, the questions, the NEEDS lines.
- **Themes:** Dark, Light, High contrast (the figure's alphas).
- **MP:** claims on and off; another player working on the same car; the flash after a server action.

## 4. What the tests check already

| Script | What it checks |
| --- | --- |
| rt_vehicles (420-470) | The game's Vehicle Mechanics inspects the car and opens the tab; the tab lists every displayed part; rows drawn; a click on a row opens its card, again closes it |
| rt_vehicles (471-501) | Check Animals opens the tab on the trailer's page |
| bx_vehicles (1305-1349) | After a crash: the wreck's tab, every part's condition against the game's getCondition, the worst part's card |
| bx_vehicles (1413-1487) | The car removed with its tab and card open: the look ends, the car drops, the card closes, nothing throws, the window stays |
| zedqa_mech79 (98-122) | By section order (brake and suspension under the tire, window under the door), the missing tire's row, no back arrow, rows inside the column |
| zedqa_mech79 (156-220) | Hover lights the part and never opens the card; Sort: Condition greyed at 3, usable at 4; open, keep on wheel, close, swap cards |
| zedqa_mech79 (237-278) | A click on the figure picks a part; the brake's step before and its button; a real Uninstall and Install of a tire from the footer |
| zedqa_mech79 (290-299, 318-390) | A opens a card, B closes it; a tour of car scripts; the trailer's rows fit the column |
| vk1_world (1604-1677) | K1-11: the key line: No key, Not needed with easy use, On you, Key in ignition |
| vk1_world (1700-1764) | K1-9: U with the tab up closes the window; E at the open hood shuts it; closing the window shuts the hood |
| zedqa_b17_scroll (377-430) | The card's scroll, a part with About text |
| sb_edges (903-969) | The list's scrollbar |
| pp_close (683-686), popups_close_sim (315) | The Sort list shuts by the Popups rules |
| pad_scroll_sim (288-289), subpage_tabs_sim (303-304, 375-376), vehicle_tab_strip_sim (24-49) | Source and stub checks: the right column's scroll view, one stop per car tab, the strip's names |
| world_refresh_sim (299) | Vehicles read with the lists while the tab is open |
| extras_cards_sim (758, 913-921), extras_sim | Claims: the Release question and its focus |
| summercar_sim, summercar_contract_sim, zedqa_summercar, zedqa_msc_run1 | The Summer Car add-on's extras on the Engine (verbs, part menu) |
| zedqa_r3_D_cars, hfr_veh, gallery_v1_c2_garage, gallery_story_shots | Pictures of the tab on modded cars, rows, a tire's card, the step before |

**Gaps:**
- Which item Install used out of several in reach; a pick while the list changes.
- A second press during the walk or the action (any verb); Repair twice.
- Repair, Inflate, Deflate, Smash, Repair engine, Take engine parts, Repair lightbar, Open and Close window: none pressed in any script; their NEEDS rows never compared with the game's own options (notAvailable) part by part.
- The battery with the engine running; requireEmpty on a gas tank with fuel; a recipe not known.
- Verbs while seated, while driving, while paused.
- The look ended by leaving the tab, then the time to look again.
- B and Cancel mid-chain: what is left (hood, tools in hand).
- The half card (220) layout; the footer's dropped verbs.
- The pad end to end: focus after A on a row, X's menu and back, the question.
- Hidden actions all and hide.
- Languages other than EN; Light and High contrast; MP with another player on the same car.
- Test drift: zedqa_mech79 presses mech:confirm:yes after Uninstall and Install (262, 274), steps that no longer meet a question (only Smash and Take engine parts ask, MT:545); mech79 was last edited Nov 13. FEATURE_MAP rows 269-270, 605-606 and 1280 cite old lines.

## 5. Suspicions (to prove in the game)

Ordered by what they can cost: a broken car or a lost part first, then wasted items, then time.

- **M1:** Take engine parts is worded as a small loss; the game sets the engine to 0. The question says "Take engine parts? The engine loses condition." (ZUI:2819), the help "it loses condition" (ZUI:3581) and the soft NEEDS row "Lowers the engine's condition" (ZUI:2860, MT:853). The game's action sets the engine's condition to 0 (TEP:52) and its own tooltip says "This will set engine condition to 0." (TT:344, ISVM:662). A player who reads the question as a dent gets a car that will not run. Prove the engine at 0 after Yes on a 90% engine.
- **M2:** The tab is not busy for most of a chain, so a second press queues the whole chain again. busy reads only the first queued action, and only one with a jobType and a vehicle or part field (MT:1243-1250, 1617, 2089): the walk (ISPathFindAction has no jobType), the item moves, the equip and the hood are not busy, and ISFixVehiclePartAction is never busy (it holds vehiclePart only, FVP:56-68), nor is ISSmashWindow (window only). So:
  - Repair pressed twice queues two repairs; the second still starts (FVP:5-7 only asks that a fixer is in the inventory) and spends a second set of materials and a second repair on the part;
  - Install or Uninstall pressed twice: when the first roll fails, the second tries again, and each failed uninstall takes 5 to 10 off the part (UVP:62, 84-85: ZombRand(failure) < 100 is always true, so every failed uninstall damages, not the shown failure share); each failed install takes 5 to 10 off the item at the failure odds (IVP:93-104);
  - when the first succeeds, the second stops as invalid and resets the queue (BTA:63-64), dropping the first chain's hood close.
  The band shows nothing during the walk, so the verbs look lit and idle (MT:1253-1274).
- **M3:** Install may put on a different item than the one picked. The pick is an index (s.pick) into a list rebuilt on every frame and again at the press (MT:899-901, 1935), from items re-read every 700 ms (MT:68, 496-504), sorted by condition alone (MT:709). Ties have no stable order, so two tires of one condition (one in the bag, one in a crate) can swap rows between the frame you saw and the press; a spare picked up, dropped or newly in reach shifts every index after it. s.pick only resets when a card opens (MT:1564) and is clamped to the owned count (MT:1938). The game names the exact item in its submenu (ISVM:263-267). Prove with two equal tires in two places and a third brought near after the pick.
- **M4:** Repair is the main button on a part that needs none. Repair stays sensible at any condition (verbSensible MT:1454-1459 checks only the engine, lightbar and tires) and comes second in PRIMARY_ORDER, ahead of Uninstall and Inflate (MT:547-548). A 100% part with materials in reach gets a lit, accented Repair with "+N%" (MT:757-760). The game offers Repair at 100 too (ISVM:220-229) but does not promote it. Prove what a repair at 100 does: the materials spent and the part's repaired count (later repairs give less).
- **M5:** On a pad, A on a row then A again runs a secondary verb. Opening a card sends focus to the first lit verb stop (MT:2529-2537); the footer draws the main verb last (MT:2081-2086), so the first lit stop is a secondary one. A damaged tire with materials: focus lands on Uninstall, not Repair; a full tire: on Deflate; the Engine: on Take engine parts (the question catches that one). Prove A A on a 60% tire.
- **M6:** Verbs run while he sits in a car, and while driving. The game's part menu refuses anyone seated who is not staff (ISVM:212). The tab lists the car he sits in (MT:225) and its look survives getting in (distance 0), so Install, Uninstall, Repair, Smash and the rest stay pressable from the seat; their handlers exit first (ISVPM:164-167, 202-205), and a driver at speed gets ISStopVehicle, then the exit (ISVMN:1554-1591). Window verbs are offered for any car's windows while he sits in any car (MT:607: chr:getVehicle(), not this car). Smash from the seat of the same car smashes from inside (ISVPM:368-369). Prove Uninstall pressed at 60 km/h, and Open window on a second car.
- **M7:** Leaving the tab ends every look. _tabLeft runs on every tab switch, fold and Loot, and ends all looks, not only the shown car's (WW:7070-7074, 2522, 2538, 2568, 5079; MT:186-195); the trailer page's Open (selects the container in Loot, TR:421-428) and Info (opens Animals, TR:430-436) leave the tab too. Back on the tab the car reads "Not inspected" and needs the walk and the look again (OMUA:46: 200 ticks at Mechanics 0), and the hood is shut behind him (MT:174-181). The game's window stays open while the inventory is used. Prove: look, Loot to fetch the jack from the trunk, back: how long to work on the car again.
- **M8:** Small screens. With the half card (220 units) the fixed 240 list leaves the right column a negative width (MT:2285-2287, CC:43, WW:2241-2245, 2265-2269), and the list itself runs past the drawer, so its percent column, Missing tags and scrollbar (MT:1656, 1697-1707, 1741) fall outside. The figure, the summary, the card, the install picks, the repair recipes, the chance bar and the NEEDS lines draw nowhere, while the footer's verbs still work on the hidden pick (s.pick 1, the best condition). At 1280 wide this is the normal case with the inventory open. The footer then drops greyed verbs and then lit ones to fit (MT:2121-2131); a dropped verb is reachable only through X's game menu.
- **M9:** B and the band's Cancel stop the whole chain. B with no card, list or question stops the running action (FM:1696-1703, MT:2471-2481), and Cancel clears the queue (MT:1266-1268); a stop resets the queue (BTA:63-64). The rest of the chain goes: the hood stays open, tools stay in hand, items brought from a crate stay in the bags. The comment at MT:2457 says B leaves the tab.
- **M10:** The NEEDS rows don't match the game's checks everywhere.
  - Uninstall the battery with the engine running: the game refuses (VEH:921-930); ZeD greys it with no failing row, so the line reads "Uninstall is not possible right now." with no reason (MT:1592-1598, ZUI NotNow).
  - Professions and traits in an install or uninstall table (VEH:907, 911, 942, 946) grey the verb with no row (tableNeeds MT:623-689 lists items, recipes, requireUninstalled, requireEmpty, requireInstalled, skills).
  - A brake's or a suspension's install table names its tire in requireUninstalled (VS template_brake.txt:9-12, template_suspension.txt:9-12), which the game's InstallTest ignores (VEH:894-918): with the tire on and the brake missing, Install is lit while the card says "Take off first: Tire" and shows a red row (MT:653-659, 1537-1542).
  - Repair: a fixer with fewer uses than it needs greys the row (MT:745); the game greys only a missing fixer, a missing global item or a low skill (IPCM:2420, 2486, 2502), not uses short.
  - Only one item counts per items row ("1/1", MT:644); the game counts none either (VEH:1095-1117).
  - A part repairable only off the car gets no word (the game: "Can be repaired once uninstalled.", ISVM:846-853).
  - With hidden actions folded, Install without a spare in reach folds away (MT:809-811, 1602), so the fitting types (MT:710-717) show only with "all".
- **M11:** The game's part menu on a pad. X calls the game's doPartContextMenu on the hidden mechanics window, placed at the mouse pointer (MT:930-931), and the game hands the pad's focus to the menu with the hidden window as its origin (ISVM:410-414). Prove where the menu opens with the pointer hidden and where focus goes after B. Seated or paused, the game's menu returns at once (ISVM:209, 212): X and right-click do nothing and say nothing.
- **M12:** Verbs run while paused. The game's part menu refuses at speed 0 (ISVM:209, 187); the tab's verbs and the question's Yes queue the game's handlers at any speed (MT:1621-1626, 2071-2074).
- **M13:** A car that changes while the tab is open.
  - Parts read every 250 ms, needs and repair rows every 300 ms, items every 700 ms (MT:412, 778, 791, 68): a press in that time acts on a part, spare or fixer already gone; the game's start check then stops it and resets the queue (IVP:5-16, UVP:5-8, BTA:63-64), with no word.
  - The car tabs are sorted by distance every refresh (MT:245) and "Nyala (2)" is a place, not a name (MT:1003): walking between two cars of one model renames and swaps their tabs under the pointer.
  - Several cars can be looked at at once, each with its mechanic flag and physics on until the look ends (MT:143-149, 2562-2563); the game's window holds one car. Prove what the flag does to a car another player gets into.
  - Driven off by another player within six tiles, the look and the hood state stay (MT:266-271).
- **M14:** MP. A claimed car greys only Uninstall and Take engine parts (MT:882-887), as the server refuses (SX:323-324); Install, Repair, Smash and Deflate on another's car stay open on both sides. The flash comes from OnMechanicActionDone for the character's own window (MT:2631-2641); prove it fires on the client after a server-side install, and that a part taken by another player redraws the card within the cache time.
- **M15:** Trailers. Check Animals skips the walk when the trailer is in reach (TA:60), then Take out walks to the back (TR:440-442); a trailer is pinned, not looked at, so its parts need Inspect (MT:2611, 1729-1735); the tow link flips pages (TR:446-460). The trailer's Open and Info leave the tab (M7). Prove an unhitched trailer drops from the pair (MT:230-244) and its pinned look ends past six tiles (MT:272-274).
- **M16:** Readings.
  - Overall is whole-number, the game two places (MT:437, ISVM:118); both count nodisplay parts and missing ones as 0 (MT:427-438, ISVM:104-120), so Overall can read lower than the rows shown.
  - A part with an item type and no item but no install table reads its condition in the row (MT:299-302, 347) and 0 in Overall (MT:433).
  - The failure share beside the success bar is the game's second roll (VEH:1463-1483; IVP:102), not the odds of damage; for an uninstall any failure damages (M2).
  - Worn is 60 or less in the summary (MT:1334) against the five-segment color bands of the rows (MT:1689); prove they agree at 60.
- **M17:** Words.
  - UI_ZeD_Veh_TakeOffFirst and UI_ZeD_Veh_PutOnFirst are in EN only (ZUI:2847-2848; 176 of 178 vehicle keys in the other 27 languages).
  - The Smash question lowercases the part name (MT:2066) and the NEEDS kicker is lowercased (MT:1445): German nouns lose their capitals.
  - "Uninstall is not possible right now." (M10) names no reason.
  - The flash words: the game's "Done" (UI_mods_Done) and ZeD's "Failed" (MT:1277).
- **M18:** Test drift: FEATURE_MAP rows 269-270, 605-606 and 1280 are about 124 lines off and row 270 names a sort stop that no longer exists; zedqa_mech79:262 and 274 press a question that Uninstall and Install no longer ask.
