# Test audit: Character and World windows, inventory, containers, loot, cards, tabs, pinning

Read only (Nov 12 2026). Sources: ZeDUI/tools/qa/zedqa_*.lua and regression.txt, git history of each script, and every
results table in ZeDUI/qa/regression/*.md (1,286 reports). "Recent" = runs since Nov 3; "all" = since Oct 20.
Results are P(ass) / W(arn) / F(ail) / T(imeout). "Edits" = commits to the script; "test fixes" = commits whose message
says the test, not the mod, was changed (QA rig, "in the tests", "script expectations", "caught up", "waits", "guards").
Time = average seconds per run in the reports.

Two facts behind many rows:

- **The QA home is the Irvington drag strip (925,13040), open asphalt.** Good for windows, cards and crates. But the
  deep-run fixture (zedqa_deep_run.lua: the car, hens, cow, trough, farm plots, padlocked door, campfire, generator)
  sits at the QA save's first spot, **10608,11151**. The prelude's own note says that spot was thick woods. Scripts that
  need the deep run's things either jump to the woods or quietly skip them.
- **The four container scripts make their own pickup truck in every run.** The line "no pickup in the loaded cell;
  spawned one beside the character" appears about 30 times each for cb, ct, cc and sg. The truck goes 4 tiles west of
  wherever the last script left the character, which has been the grandstand (indoors) at times. They never call
  ZEDQA_HOME. The truck is only used as a box with a lot of things in it. A crate does the same job.

## Table A: in the unattended run (regression.txt)

| Script | What it checks | Where / how it stages; does the place fit? | Time | Results (recent; all) and what the FAILs were | Duplicates | Edits (test fixes) | Verdict |
|---|---|---|---:|---|---|---|---|
| zedqa_pin_windows (pnw) | Pins both windows so they do not roll up during the run | No scene. A setup step, not a test | 1 | 110/110; 112/112 | Prelude's job | 2 (1) | **MERGE** into the prelude |
| zedqa_loot_tabs (lt) | Puts both windows back on Loot with drawers shut | No scene. Exists only because doll/curtain leave a drawer open and wpt then fails its first moves | 1 | 6/6; 57/57 | Prelude / each script's put-back | 1 (0) | **MERGE** into the prelude; scripts put back their own state |
| suite_tabs | Clicks every tab of both windows; prints focusable counts | No scene; no PASS/FAIL checks, it fails only on a thrown error | 13 | 12/12; 91/95. 4 FAILs were whole-run crash runs (Oct 24-25 mod runs, Oct 30: 50 exceptions): real mod errors | tabicons, tabs_lit, scalewalk, navmap, two_widths, soak all walk the tabs | 1 (1) | **KEEP** (cheap crash smoke); fold tabicons/tabs_lit's pictures in |
| suite_verbs | Fires each item-card verb on a book, bat and apple | Gives the items; the manifest says it **leaves them** | 19 | 7/7; 59/61. 2 FAILs = the same crash runs | onepath (card verbs) | 1 (1) | **KEEP**; take its items back |
| zedqa_audit_fixes (af) | Throwing tab logs once; equip card hides; card closes when item leaves; title weight | No scene | 5 | 7/7; 57/58 | none | 1 (1) | **KEEP** |
| zedqa_card_pad (cp) | Pad into the item card and back; Health tab drawer reach | Gives a hammer | 5 | 12/12; 83/85 | wpt steps 3 and 6, navevents | 1 (0) | **KEEP** (cheap); wpt drops its copy |
| zedqa_ctxlist (cl) | Right-click menu as a list, submenu, back | No scene | 5 | 19/23 recent; 90/96. FAILs: Nov 7 mod-list runs (3 Java exceptions each, other mods loaded) and crash runs: mod/compat, not the test | ctx_icons strip/list part | 1 (0) | **KEEP** |
| zedqa_ctx_icons (cx) | Every picture name has an icon; strip and list on four things and the floor | Items on the floor of the strip | 23 | 8/11 recent; 29/32. 3 FAILs Nov 6: **the test** handed the game's world menu the dropped items and the game threw (spriteName null); floor_rclick was written to prove a real click does not | ctxlist | 2 (1) | **SHRINK**: the name-to-icon table is data, **MOVE TO SIM**; keep the live strip/list on one thing |
| zedqa_onepath (op) | Move To, Rename, double-click equip, crate Take all, Drink / Sharpen verbs | Builds a crate beside the character on the strip. Fits | 22 | 7/7; 55/60. 5 FAILs Oct 22-26: crash runs and one real exception | suite_verbs (verbs) | 1 (0) | **KEEP** |
| zedqa_grid (grid) | Grid view, cell card, pad walk, List / Grid toggle | Character's bag | 9 (one 301 s timeout) | 9/10 recent; 87/89. Nov 11 TIMEOUT: List and Grid became one button that day (design change; the test was behind) | view_toggle, sort_groups grid half | 2 (0) | **KEEP**; merge view_toggle in |
| zedqa_sort_groups (sg) | Category headers only under Sort by Category; order for name / cond / weight; list + grid, single + multi, both windows | 24 things in the bag, a pack, **a spawned pickup's bed** and the ground beside it (spawned ~29 times) | 51 | 7/7; 53/57. Nov 11 WARNs logged as "script expectations, not game bugs" | inv_model_sort_sim covers the ordering; grid; wt_bracket | 4 (1) | **RESTAGE** (a crate on the strip, no truck) and **SHRINK**: ordering to the sim; in game keep "headers only under Category" once in list and once in grid (now 32 combos, 24 pictures) |
| zedqa_wt_bracket (wtb) | A stack's total weight in brackets; open rows own weight; Small / Large; two columns; narrow WT | Bag + ground. Fits | 23 | 8/8; 20/24. WARNs Oct 29-30 while the feature was being built | large (Large size) | 2 (1) | **KEEP** |
| zedqa_doll (doll) | Equip doll: layers, a slot's card by pad | Wears cap, jacket, shirt | 10 | 6/6; 67/68 | doll_v4 does all of it and more | 2 (0) | **MERGE** into doll_v4 (drop) |
| zedqa_doll_v4 (dollv4) | 38 small slots, no overlap, worn things land, pad in/out, drop wears, half / full card | Dresses the character from every slot. Fits | 33 | 8/8; 28/29 | doll | 7 (2: test caught up with design) | **KEEP** |
| zedqa_large (lg) | Large text: Loot and Equip rows, column widths (pictures + row height) | No scene; almost no checks | 9 | 6/6; 66/67 | wt_bracket Large, wpt step 7 at Large, scalewalk | 1 (0) | **MERGE** into scalewalk |
| zedqa_curtain (cu) | Roll / unroll geometry to the pixel; close while rolled; tab presses while rolled | No scene. Skips the Radio and Vehicle tabs every run ("not shown here", 72 + 28 lines) | **203** (max 314) | 7/8 recent; 67/91, **22 WARN**. Oct 21-22 FAILs were real (restore size, Loot while rolled: fixed in the mod). Later WARNs mostly 1 ERR line of timing | curtain2, dual_pin, faiv's roll part | 7 (3) | **SHRINK**: round trips on 3 tabs, not every tab twice; drop the "leave both rolled at quit" step (it breaks the next script); merge curtain2. Longest script in this area |
| zedqa_curtain2 (cv) | Character window curtain; tab switches while rolled | No scene | 14 | 6/6; 59/60 | curtain step 5 | 1 (1) | **MERGE** into curtain |
| zedqa_navevents (ev) | Where pad focus lands after cards, strips, tabs, bumpers, map | No scene | 6 | 6/6; 66/67 | card_pad | 2 (0) | **KEEP** |
| zedqa_navmap (nav) | Cone-nav audit of every tab: traps, islands, stuck | No scene | 14 | 8/8; 73/79. FAILs: mod-list runs and crash runs | wpt step 7, padmap | 1 (0) | **KEEP** |
| zedqa_world_pad_take (wpt) | Pad into the World window, containers, card on its primary verb, Take, object card, Character parity, belt, **every tab's bottom at two text sizes** | Builds a crate with nails, bandage, hammer, apple beside the character (or uses the deep run's crate). The crate fits. Step 7 depends on whatever is nearby (animals, objects) | **91** (max 781) | 7/14 recent; **29/75, 43 WARN**. Oct 23 FAILs were real (the director's pad report; fixed that day). Since then all test-side: Oct 27 card focus (fixed "in the tests"); Nov 2-5 "hold A moved the hammer" x7: the control became hold X on Nov 1, test 4 days behind; Nov 5-6 Animals tab bottom: 43 animal alerts from **other scripts' leftover animals** at the QA home; Nov 9 "Right from a row": another script left the bag in grid | card_pad, navevents, navmap, scalewalk | 9 (5) | **SHRINK**: cut step 7 (every tab's bottom: navmap + scalewalk do it); set its own start state (list view, Loot, drawers shut) instead of relying on lt; never read the Animals tab here |
| zedqa_furniture (fu) | Furniture tab cursor and its five modes | Looks for furniture "within 8 tiles". The log shows it found 875,13017 and read **name=nil can=false**: the pickup check reads nothing on the asphalt and still passes. Prints no DONE | 2 | 7/7; 54/56 | none | 1 (1) | **RESTAGE**: build a chair beside the character, and make the pickup capture a real check |
| zedqa_tabicons (ti) | Picture of both tab strips | No checks | 3 | 7/7; 58/59 | suite_tabs | 2 (0) | **DROP** from the run (a gallery capture) |
| zedqa_tabs_lit (tl) | Pictures of lit tabs | No checks | 7 | 6/6; 54/55 | suite_tabs | 2 (0) | **DROP** from the run (a gallery capture) |
| zedqa_win (win) | Pair at natural root and forced 1.0 | No checks (prints and 2 pictures) | 5 | 6/6; 56/57 | scalewalk, rootchange | 1 (1) | **MERGE** into scalewalk |
| zedqa_rootchange (rc) | A root change re-derives geometry | 13 lines; prints only | 6 | 6/6; 54/55 | win, scalewalk | 1 (1) | **MERGE** into scalewalk |
| zedqa_scalewalk (sw) | Main tabs of both windows at natural and 1.0 | No scene | 64 | 6/6; 58/59 | win, rc, large, suite_tabs | 2 (1) | **KEEP** as the one scale script (absorbs win, rc, large) |
| zedqa_two_widths (tww) | Every tab, card and pop-out is the half or full card; the other window never moves | **Teleports to the deep run's home 10608,11151 (the woods)** for object cards, then back. Still skips 6+ object cards every run (fire, hook, hutch, laundry, lock, plant ...; 39 "skipped" lines) | **94** | 6/7 recent; 33/40. FAILs: Nov 2 720 state run, Nov 6 a run that went twice (re-bump): rig | suite_tabs, scalewalk; drawer widths are numbers | 4 (1) | **RESTAGE + SHRINK**: drop the object-card leg (it mostly skips and needs the woods); check tabs and item cards at home. The width rule (half 220 / full 480, room rule) is arithmetic: **MOVE TO SIM** |
| zedqa_container_bottom (cb) | Container button row at the bottom; campfire ribbon | **Spawns a pickup** beside wherever the character is; a campfire beside it | 11 | 6/6; 59/62. FAILs: Oct 20, Oct 24 crash run, Nov 2 720 state run (rig) | container_controls | 2 (1) | **MERGE** into container_controls |
| zedqa_container_controls (ct) | Same type, Take all, Transfer all, To floor; campfire buttons | **Spawns a pickup**; a campfire | 19 | 6/6; 60/63. Same three rig/crash runs | cb, cc, sg's truck | 3 (1) | **RESTAGE**: a crate on the strip (one call to ZEDQA_HOME first); keep the campfire. Absorbs cb |
| zedqa_container_controls_captures (cc) | Backdrops for a mockup, ZeD and vanilla windows on a truck bed | **Spawns a pickup** | 6 | 6/6; 56/58 | ct | 2 (1) | **DROP** from the run (design captures, not a test) |
| zedqa_immersive_searching (iss) | With the mod off nothing changes; with it on the search chip and gates | Three duffel bags on the floor. Fits | 4 | 6/6; 15/17 | isearch | 2 (2) | **KEEP** for the compat run only; the "mod off" half is a no-op in the main run, drop it there |
| zedqa_put_back (pb) | Things go back into the bag after eat / smoke / drink; jack and wrench back after a tire | Needs the deep run's car within 10 tiles. **"no deep-run car within 10 tiles: the tire scene is skipped" in 47 runs**: the car is in the woods 2 km away, so a third of the script never runs and it still PASSes | 32 | 6/6; 45/48 | none | 1 (0) | **RESTAGE** the tire scene: its own pickup parked on the strip lot, or drop that leg; never pass on a skip |
| zedqa_lists (ls) | Loadouts and outfits data, Journal Loadouts page, right-click save | Gives crowbar, bandages, water, cap. Fits | 17 | 6/6; 20/21 | restock (Equip bar) | 1 (0) | **KEEP**; the data round trip could be a sim |
| zedqa_restock (rst) | Equip loadout bar, to-do states, restock 3 ways, stops, unpack | The grandstand beside the strip: crates, a locked locker, a far crate, a tap; spawns one zombie for the stop. **The place fits** (a building with water and storage) | 58 (one 730) | 6/6; 16/26. FAILs Oct 29-Nov 2: the grandstand not loaded at 720 (rig, 4 rig commits on one day); "Make it N days" x5 during the build | lists | **10 (8)** | **KEEP**, the one with the best scene; **SHRINK** the "Make it N days" and to-do math into restock_scan_sim |
| zedqa_equipdrag (eqd) | Equip rows and doll slots as drag sources (fake mouse) | Wears cap and jacket, holds a hammer. Fits | 14 | 5/5; 46/49. 3 FAILs Oct 20, first day | faiv ROLL, drag_real | 1 (0) | **KEEP** |
| zedqa_faiv (fav) | The game's loot page never drawn; a rolled window takes a drag; list is the selection | ZEDQA_HOME, crates. Fits | **120** | 1/2 (own manifest) | loot_click, loot_paths, drag_real, dual_pin | 5 (3) | **SHRINK**: keep FLASH (the reported bug); the ROLL part overlaps equipdrag and dual_pin |
| zedqa_charinfo (ci) | The game's Character window keys land on ZeD's tabs | No scene | 9 | 5/5; 36/36 | none | 2 (0) | **KEEP** |
| zedqa_exinfo (ex) | Health tab exercise info | No scene | 8 | 7/10; 63/71. WARNs Nov 7: run with Wounds Overhaul on (its text differs): compat, not a bug | none | 3 (0) | **KEEP** |
| zedqa_b11_notes (b11n) | Beta 11 notes: belt hand icons, Loot drawer fold, "Nothing here.", stack bar | ZEDQA_HOME, then hunts a bare 3x3 tile nearby (the QA spot's floor is cluttered by other scripts) | 42 | **0/2, run 3 times as copies (_r2, _r3) with the same FAIL**. "162 stack bar" = the test read bars before the rows were revealed; plus a first-run-after-load exception (#165). 3 test fixes the same day | item_meter_sim, fold_slide_sim | 3 (3) | **SHRINK** to the notes not covered by sims (155, 157); the 162 bar to item_meter_sim |
| zedqa_cov_objcards (cov_objcards) | Seven object cards (tracks, placement, fluid, campfire, trough, hen house, farm plot) | **Puts a trough, a hen house with hens and eggs and two farm plots on the drag strip asphalt** at 925,13040. Animals and plots on a racetrack. Two FAILs and an error are written in as expected | not run yet | none yet | two_widths object-card leg, deep run | 3 (3 before its first run) | **RESTAGE**: the hen house, trough and plots at a real farm; the campfire and placement can stay on the strip |
| zedqa_ctx_overlap (ctxov) | A submenu over its parent stays open | No scene | 11 | 1/1 | ctx_overlap_sim | 2 (0) | **MOVE TO SIM** (the sim exists); drop the in-game copy |

## Table B: in this area but outside the unattended run

| Script | What it checks | Staging / place | Time | Results | Duplicates | Edits (test fixes) | Verdict |
|---|---|---|---:|---|---|---|---|
| zedqa_dual_pin (dpn) | Each half of both windows rolls and pins on its own (real mouse) | No scene; real pointer | 45 (max 80) | **3/9, 5 WARN, 1 FAIL**. Fixes were timing: "away 3 s waits 3.5 s on the clock, not 200 frames (the Deck draws faster)", held item, press points | dual_pin_sim; curtain; faiv | **9 (7)** | **MOVE TO SIM** (the state rules); keep 2 real-mouse checks by hand in the release check. Do not add to the unattended run as the coverage audit suggested |
| zedqa_autocollapse | Windows roll up when the pointer leaves (beta 3a) | Real mouse | 54 | 0/2 (WARN) | dual_pin replaced it | 3 (2) | **DROP** |
| zedqa_pins | Title-bar pins (Nov 4) | none | - | not in reports | dual_pin | 3 (2) | **DROP** |
| zedqa_tab_search | Find on Skills and Equipment tabs | "The deep-run character" (its gear) | 24 | **0/6** (5 FAIL, 1 WARN). Nov 11: mostly real (the Find fixes landed that day) | tab_search_sim | 2 (1) | **MOVE TO SIM** (text matching); one in-game smoke step in suite_tabs |
| zedqa_inventory_filter | The inventory Filter, one per window | Things on the floor of the drag strip | 16 | **0/5, all WARN** "the floor narrowed to the metal 4 of 26": it counts the QA spot's floor, which holds other scripts' leftovers | inventory_filter_sim | 2 (1) | **MOVE TO SIM**; in game, a bare tile and only its own things |
| zedqa_window_saved_pos (wsp) | Save position / Go to saved position | none | 65 (one 300 s timeout) | 2/5. "guide back" off by 165 px was real (self-centering windows; fixed Nov 11) | window_saved_pos_sim | 1 (0) | **MOVE TO SIM** |
| zedqa_view_toggle | The one List/Grid button | Floor items | 12 | 1/2 | view_toggle_sim, grid | 1 (0) | **MERGE** into grid |
| zedqa_footer_picked | Footer "3 of 48 picked" | none | 8 | 2/2 | footer_picked_sim | 1 (0) | **MOVE TO SIM** (it exists); drop |
| zedqa_tab_sweep | Every tab's clip and footer | **"after zedqa_animals.lua built the pen"**: needs the animal pen | 86 | 0/2 (one with 89 exceptions) | suite_tabs, tab_review | 2 (2) | **DROP** |
| zedqa_tab_review, zedqa_recheck_tabs | Picture review of every tab, empty and full; rechecks | recheck_tabs **spawns a hen at the strip**; the "Close Trunk" car prompt shows in every picture | 38 | 1/2 | each other, suite_tabs | 1-1 | **KEEP as picture tools only**, not tests; the pen and hen go to a farm |
| zedqa_tab_cost | Ms per tick per tab | none | - | probe | suite_perf | 1 (0) | **DROP** from tests (a perf tool) |
| zedqa_capacity, zedqa_dropnloot, zedqa_nested, zedqa_isearch | Other mods' support in the container row | capacity and dropnloot **spawn a pickup** | 6-13 | 1/1, 1/1, 1/1, 3/3 | immersive_searching | 1-2 | **KEEP** for compat runs; **RESTAGE** to a crate |
| zedqa_loot_click, zedqa_loot_paths, zedqa_drag_real, zedqa_card_real, zedqa_floor_rclick, zedqa_b6a_left, zedqa_b8_cards, zedqa_b8_windows, zedqa_morerow | One-time confirmations of a single fix (FAIV's reports, beta 6a-8 notes) | various | 8-70 | 1-3 runs each; drag_real 1/3, loot_click 0/1 (WARN) | faiv FLASH covers loot_click / loot_paths | 1-3 each | **DROP** (the fixes are confirmed; faiv keeps the lasting check) |
| zedqa_container_v2, zedqa_container_ribbon, zedqa_container_controls_mouse | Oct 16 real-mouse step scripts; ribbon leaves a campfire and needs a second run to clean up | pickup / campfire | - | not in reports | container_controls | 1-2 | **DROP** |
| zedqa_padlock | Setup builder: crates and a locked locker that stay | beside the character | 1 | 3/3 | restock builds its own locker | 1 (0) | **DROP** |
| zedqa_qa_pickup, zedqa_inv_cleanup, zedqa_move_to, zedqa_grid_off, zedqa_doll_view_on, zedqa_restock_probe, zedqa_world_widths | Save upkeep and probes; inv_cleanup exists only to clear what animals_quick left in the bags | - | - | qa_pickup 0/1 (timeout) | - | 1 each | **DROP** as tests (keep only grid_off as a one-time save setting) |
| zedqa_deep_run (fixture) | Stocks the QA character and builds a scene of every object | **At 10608,11151, the save's first spot (woods)**, not the QA home | 180 | by hand | - | 4 | **RESTAGE**: the near scene (crate, fridge, shelves, a car with its trunk) on the drag strip lot; animals, trough and plots at a farm |

## The worst offenders

1. **zedqa_world_pad_take**: 75 runs, 43 WARN, 9 edits. After its first day every failure was the test: a control
   change it lagged behind for four days; another script leaving the bag in grid; and leftover animals at the QA home
   making the Animals tab long. Its step 7 (every tab's bottom) repeats navmap and scalewalk. Cutting it removes most
   of the noise and most of the 91 s.
2. **The deep-run scene in the woods**: put_back's tire check was skipped in 47 runs while the script passed.
   two_widths jumps 2 km into the woods for object cards and still skips six or more each run. tab_search counts on the
   deep-run character. This is the "car in a forest" problem in this area. Things that need a car go on the strip lot;
   animals, troughs and plots go to a farm.
3. **Four pickups per run**: cb, ct, cc and sg each spawn a truck beside wherever the character stands, only to use
   its bed as a box. A crate on the strip does the same, loads at once and cannot land indoors.
4. **zedqa_curtain**: 203 s, the longest script here, with 22 WARNs over time. It runs every tab twice and leaves both
   windows rolled for the next script. That is why zedqa_loot_tabs exists.
5. **Rerun loops on new checks**: zedqa_b11_notes ran three times as copies with the same FAIL (the test read bars
   before the rows were drawn). zedqa_dual_pin had 7 timing edits for 3 passes in 9 runs. zedqa_inventory_filter
   failed 5 of 5 counting a floor that other scripts clutter. In each case a sim already exists (item_meter,
   dual_pin, inventory_filter, tab_search, window_saved_pos, view_toggle). The logic belongs there, with at most one
   in-game step.
6. **Hollow passes**: zedqa_furniture reads `name=nil can=false` on the asphalt and passes. tabicons, tabs_lit, win
   and rootchange check nothing; they only take pictures. suite_tabs only fails on a crash. These are cheap and harmless,
   but they should not count as coverage.

Time: this area takes about 15 minutes of each full run. curtain, world_pad_take, two_widths, faiv, sort_groups and
scalewalk together take about 9 of them. Making the changes above (merges, drops, the step-7 cut, curtain on 3 tabs,
sort order in the sim) should take roughly 6 minutes off and remove nearly every WARN that was not a mod bug.
