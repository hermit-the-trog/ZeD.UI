# QA b12 release pass (Nov 13 2026)

Candidate: main at 9024e32b7 (HEAD contained it; the lock read free at the start). Everything ran with -debug -nosteam on the ZeD-QA save at 4K fullscreen (UI scale 1.75x) unless said otherwise. Pictures: Zomboid/Screenshots/b12_release_20261113/<part> (outside the repo).

## Part 1. The smoke run (release_check.ps1 -Manifest smoke.txt, 4K)

Ran once. Report: ZeDUI/qa/regression/2026-11-13_b12rel_smoke.md. Result: 12 of 12 pass, 0 warn, 0 fail. The release check's own line: `ZEDQA rel RESULT PASS: all 16 checks` (windows open, floor transfer there and back, pad A and B, the real right-click, the watch time).
- Car lines (one car in this run): `ZEDQA car dpx Base.CarNormal spawned on spot 11 (917,13030)`. Spot 11 passed.
- navmap, strict: `ZEDQA nav 14 tabs audited: 0 traps, 0 islands (strict: each one is a failing line)`. No FAIL line.
List A: none. List B: none. Not run: none.

## Part 2. The main run (main_run.txt, 4K)

Ran: zedqa_run.ps1 -Manifest main_run.txt once (report ZeDUI/qa/regression/2026-11-13_b12rel_main_4k.md). It stopped after script 57 of 87 (zedqa_mapshot.lua: no DONE within 180 s, one Java exception), so scripts 58 to 87 did not run in it. They had not run, so I ran them once in a second manifest made of exactly those 30 scripts (report 2026-11-13_b12rel_main_rest_4k.md; nothing was run twice). Pictures: Zomboid/Screenshots/b12_release_20261113/p2.
Totals: first run 44 pass, 7 warn, 6 fail, 30 not run; second run 29 of 31 pass (the prelude counts), 1 warn, 1 fail. soak passed this time (`ZEDQA soak PASS after the run, the reader shut: 38 UI elements (39 at the end of round 1, 36 at the start)`). wheel_icons passed (the rod has its picture now).

### Car lines
All 45 `ZEDQA car ...` lines (first run) are in this file, below. Spots passed: 11 (14 lines), 12 (15) and 13 (15); no spot was refused, none failed with "a car on it". The helper took a leftover car away twice: `ZEDQA car dpx took away a car an earlier spawn left behind` (x2).
```
ZEDQA car wi Base.PickUpTruck spawned on spot 11 (917,13030)
ZEDQA car dw Base.CarNormal spawned on spot 12 (910,13037)
ZEDQA car pg Base.CarNormal spawned on spot 13 (917,13024)
ZEDQA car cov_vehicles Base.CarLightsPolice spawned on spot 11 (917,13030)
ZEDQA car cov_vehicles Base.CarLightsPolice spawned on spot 12 (910,13037)
ZEDQA car dpx Base.CarLuxury spawned on spot 13 (917,13024)
ZEDQA car dpx Base.CarNormal spawned on spot 11 (917,13030)
ZEDQA car dpx Base.SportsCar spawned on spot 12 (910,13037)
ZEDQA car dpx Base.CarLightsPolice spawned on spot 13 (917,13024)
ZEDQA car dpx Base.PickUpTruck spawned on spot 11 (917,13030)
ZEDQA car dpx Base.ModernCar spawned on spot 12 (910,13037)
ZEDQA car dpx Base.ModernCar02 spawned on spot 13 (917,13024)
ZEDQA car dpx Base.SmallCar spawned on spot 11 (917,13030)
ZEDQA car dpx Base.SmallCar02 spawned on spot 12 (910,13037)
ZEDQA car dpx Base.CarStationWagon spawned on spot 13 (917,13024)
ZEDQA car dpx Base.SUV spawned on spot 11 (917,13030)
ZEDQA car dpx Base.VanSpiffo spawned on spot 12 (910,13037)
ZEDQA car dpx Base.PickUpVan spawned on spot 13 (917,13024)
ZEDQA car dpx Base.OffRoad spawned on spot 11 (917,13030)
ZEDQA car dpx Base.CarTaxi spawned on spot 12 (910,13037)
ZEDQA car dpx Base.VanAmbulance spawned on spot 13 (917,13024)
ZEDQA car dpx Base.PickUpTruckLightsFire spawned on spot 11 (917,13030)
ZEDQA car dpx Base.CarLightsRanger spawned on spot 12 (910,13037)
ZEDQA car dpx Base.RaceCar12 spawned on spot 13 (917,13024)
ZEDQA car dpx Base.Van_KnoxDisti spawned on spot 11 (917,13030)
ZEDQA car dpx Base.PickUpTruckLightsFossoil spawned on spot 12 (910,13037)
ZEDQA car dpx Base.CarNormalSmashedFront spawned on spot 13 (917,13024)
ZEDQA car dpx took away a car an earlier spawn left behind
ZEDQA car dpx Base.ModernCarLightsMeadeSheriff spawned on spot 11 (917,13030)
ZEDQA car dpx Base.CarLightsLouisvilleCounty spawned on spot 12 (910,13037)
ZEDQA car m79 Base.CarNormal spawned on spot 13 (917,13024)
ZEDQA car dl Base.ModernCar spawned on spot 12 (910,13037)
ZEDQA car dl Base.ModernCar spawned on spot 13 (917,13024)
ZEDQA car dgr Base.PickUpTruck spawned on spot 11 (917,13030)
ZEDQA car dgr Base.PickUpTruck spawned on spot 12 (910,13037)
ZEDQA car dgr Base.ModernCar spawned on spot 13 (917,13024)
ZEDQA car dgr Base.ModernCar spawned on spot 11 (917,13030)
ZEDQA car dgr Base.ModernCar02 spawned on spot 12 (910,13037)
ZEDQA car dgr Base.ModernCar02 spawned on spot 13 (917,13024)
ZEDQA car dgr Base.SUV spawned on spot 11 (917,13030)
ZEDQA car dgr Base.SUV spawned on spot 12 (910,13037)
ZEDQA car dgr Base.CarLuxury spawned on spot 13 (917,13024)
ZEDQA car dgr Base.CarLuxury spawned on spot 11 (917,13030)
ZEDQA car dgr Base.SportsCar spawned on spot 12 (910,13037)
ZEDQA car dgr Base.SportsCar spawned on spot 13 (917,13024)
```

### navmap (strict)
`ZEDQA nav` found 0 traps and 0 islands on all 14 tabs (no LIST line). It still reads FAIL: 52 Java exceptions in its window, all the one in List A below.

### List A (real mod bugs)
1. The Vehicle tab throws on every frame once a car is in view: 108 exceptions (52 in navmap, 56 in mech79). Lines: `ERROR: General f:27184> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown`, `java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).`, `Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)`, `Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)`, `Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)`. Line 400 is `local sc = v:getScript()`: the tab holds a car that is gone from the world (the helper's "took away a car" removal; the same would happen to a car that is destroyed or unloaded), so the tab should drop it. mech79 passed one check and then read nil (`the rest of its checks read nil). Pictures: p2/zqa_m79_3840x2160_*.png.

### List B (test trouble)
- cov_input: `ZEDQA cov_input FAIL input mode: a pad unplugged with none left goes back to mouse and keys (not checked: 1 real pad(s) connected ...)`: a real pad is plugged in.
- cov_vehicles, dl, dgr: the car was not settled when the script sat in it: `ZEDQA cov_vehicles FAIL the police car settled beside the character before seating (... 19.0 away, physics seen true vs ... held 1.5 s)`, `ZEDQA dl ERR elite car not settled at the seat step; not entered (square=true chunk=true physics=false dist=25.0 ...)`, `ZEDQA dgr ERR d6 car not settled at the seat step; not entered (...)` (six cars; each then reads the police car's design). cov_vehicles' five sections "never came up" follow from it. The settle wait is too short for a car placed 19 to 25 tiles away: unclear whether the helper's new spots sit too far.
- dpx: `ZEDQA dpx FAIL 01_luxury: the engine is running` (its own line says running=false; the first car after a leftover was taken away): unclear. `22_wreckednyala could not enter Base.CarNormalSmashedFront`.
- dl lamp-chip lines (`the pointer over the batt lamp shows its chip (nil: Battery | table ...)`): the chip exists; the check reads another shape: unclear.
- After mech79 the later scripts read an empty or safe-mode world: `ZEDQA cov_objcards FAIL ZeD is out of safe mode (the game's own windows would open on the script's things) (safe mode vs off)`; padfig (`the in-game Options window is open`, then `attempted index: box of non-table`), cov_equipfurn (`the Equip tab opens (nil vs equip/tab)` and 25 more), cov_reading (`the Journal (skipped: no Character window)`), cov_b9to11 (`step 2: the window pair did not open`) and mapshot (no DONE). Most likely a cascade of the safe-mode trip after the 108 exceptions above, not separate faults; unclear until the Vehicle bug is fixed. They are "not judged".
- tw (the second run): `ZEDQA tw FAIL the header button opens full view on the radio` and the steps after it (`attempted index: _hits of non-table`). The Radio page changed to a tab strip since the script was written; unclear whether the header button is a real fault.
- safe: `ZEDQA safe FAIL option on` (the rest of safe mode passes: tripped, note, inventory key, reset, reopen). Unclear.

### Not run
Nothing is skipped by the runner now; the scripts the first run judged "not judged" above did run but their results are untrustworthy.

## Part 3. 1280x800 windowed spot checks (Small and Large text)

Ran: a short bridge script of my own (kept out of the repo) after the prelude, at 1280x800 windowed (UI scale 0.75, Auto): for Small and for Large, Loot + Crafting, Journal, an item card, Papers in the Light theme, Light and High Contrast pictures of both windows; plus a second small script for Radio and Vehicle (a walkie in the bag, a car spawned by the helper). Reports: 2026-11-13_b12rel_p3_deck.md and _p3b_deck.md (both WARN from my own "press" lines for the two tabs that were not on the strip). Pictures: Zomboid/Screenshots/b12_release_20261113/p3 (zqa_r3_*, zqa_r3b_*).
One line per picture (S = Small, L = Large):
- Loot + Crafting, S and L (zqa_r3_small_dark_loot_craft.png, zqa_r3_large_dark_loot_craft.png): text fits; names are cut with ellipses by design in the 276 px Character window ("Angel Cross's K...", "Baseball B... x6"); at L the Status column goes (Name and Wt only) and the last list row is cut by the scroll, as designed. Header rows line up across the windows.
- Journal tab strip, S and L (zqa_r3_*_dark_journal.png): the five pages (Journal, Notebooks, Papers, Recipes, Loadouts) show as a tab strip under the heading, all five whole at S; at L the Papers picture shows the five whole too. No "Page:" pop-up. Text fits; the entry text at S is clipped only by the list's own scroll.
- Item card, S and L (zqa_r3_*_dark_itemcard.png, a Broom): the top block reads Kind and Weight only ("Kind Household / ..." and "Weight 2.0 kg"), with the Marked row above it; the Kind value is cut ("Household / ...") at both sizes. Combat Facts follow below, cut by the card's scroll only.
- Papers in Light, S and L (zqa_r3_*_light_papers.png): list, Show: All and the two papers read clearly; text fits; Read / Unread tags whole.
- Light, both windows (zqa_r3_*_light_both.png, small only drawn Crafting; large Light is in the papers picture): solid, not see-through; the scene does not show through either window. Text fits.
- High Contrast, both windows, S and L (zqa_r3_*_hicon_both.png, *_hicon_health.png): solid black, not see-through; text fits, bar and tab icons whole. High Contrast Health at S: the heading and the Exercise row fit.
- Chat idle in Light: not checked: needs a multiplayer server (the chat is on a server only).
- Radio, S and L: not checked: needs staging. A walkie in the bag did not put a Radio tab on the Character strip (`ZEDQA r3b ERR press radio=false loot=true`; the tab needs a radio in hand or in reach).
- Vehicle, S and L: not checked: needs staging. A car spawned beside the character by the helper did not put a Vehicle tab on the World strip (`ZEDQA r3b ERR press loot=true vehicle=false`; the tab appears when you sit in or inspect a car).
List A: none. List B: the two press lines above (staging).

## Part 4. Dash interior colors (4K)

Ran: no separate run. zedqa_dashpx.lua (the 24-car pass, inside Part 2's main run) already draws every car's dash with the key on at 4K and pictures each, so one car per group came from it (running a second time would have been a repeat). Pictures (the dash strip cropped from the 4K picture, 1600 x 356): Zomboid/Screenshots/b12_release_20261113/p4 (dash_<car>.png; the full pictures are in p2/zqa_dashpx_<n>_<car>_keyon.png).
Cars by group, each dash drawn whole (`ZEDQA dpx` line per car with rect=1120,1804,1600,356 on the screen): station wagon: 10_wagon (olive green cabin, wood trim); 70s: 03_cossette (orange-tan leather) and 02_nyala (tan); 80s: 09_horizon (maroon); 90s late models: 07_primani (grey); sports and luxury leather: 01_luxury (brown leather, wood); police: 04_police (black). The picture count is 114 passed and 1 failed in dpx (the fail is `ZEDQA dpx FAIL 01_luxury: the engine is running`, a start timing line, see Part 2).
Legend text that is hard to read on its plate:
- 07_primani (grey): the small "TEMP" and "FAN" captions and the "ACC LOCK ON ST" ring around the ignition are pale grey on mid grey, thin; the heater's "TEMP" caption sits tight under the radio.
- 02_nyala and 03_cossette (tan and orange-brown): the small captions under the buttons ("LIGHTS", "LOCK", "TRUNK", "WIPER", "ON SET") and the scale words "COLD / WARM / OFF / VENT / HEAT / DEF" are light grey on tan: readable, but the lowest contrast of the set.
- 10_wagon: the "COLD WARM / OFF VENT HEAT DEF" words on the dark wood strip are small and thin; "CERISE WAGON" reads fine.
- 04_police: all legends read well on black.
- The "D-PAD RIGHT: VEHICLE / DASHBOARD" hint at the top right of every dash is small pixel text over the cabin colour, thin on all of them (worst on the wood and tan ones).
List A: none for colors (no dash drawn wrongly, none cut). List B: the cars not entered in dgr and cov_vehicles (Part 2).

## Part 5. Summer Car with the mod on (4K)

Ran: zedqa_mods_run.ps1 with summercar_mods.txt and summercar_manifest.txt once, 4K, ZeD last, real-mouse helper beside it (stopped after); the mod copied from SteamCMD's download for the run and removed after; the save restored (its mods.txt lists only ZeD_UI). Report: ZeDUI/qa/regression/2026-11-13_0004_mods_fullscreen4k.md (prelude pass; summercar FAIL, 216 s). Pictures: Zomboid/Screenshots/b12_release_20261113/p5 (zqa_sc_C..N, 8 files).
Result: not judged. The script printed `ZEDQA sc cars true true` and then nothing; the engine window never opened, so there are no positions or sizes to report (the expected free side at about x=626, and open by itself on inspect, were not seen). In the same 216 s the log took 112 Java exceptions, all the Vehicle tab bug of Part 2: `ERROR: General f:1076> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown`, `java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).`, `Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)`, `Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)`, `Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)`. It began on the first frame the Vehicle tab drew with a fresh car in a fresh game, so it is not the stale car of Part 2: a method vehicleName calls (the car script's `getCarModelName` or `getScript` on this build, 42.22.2) is nil. Pictures show the game's own windows (vanilla Inventory and "Vehicle Mechanics" in the pictures), which fits ZeD having stepped aside to safe mode after the exceptions.
List A: the vehicleName exception above (the same bug as Part 2; it blocks Part 5). List B: none. Not run: every step of the script after "cars" (B to O).

## Part 6. Lua Console 93 Professional Edition (CHECK_luaconsole93.md, products/LuaConsole93)

Setup as in round 2: the ZeD-QA save only (zedqa_mods_run.ps1 writes its mod list for the run and restores it; its mods.txt lists only ZeD_UI now); the dev-only ZeDQAShim stood in for the alone pass (no ZeD-GUI); the main menu's default.txt was LuaConsole93 and the shim, then ZeD_UI and LuaConsole93 in each order, and was put back (reads ZeD_UI as before). The console opened through its own flag and lines went through its Run (the same ProcessCommand the box's Enter uses); no keys typed, so the sheet's key-driven steps are listed below as not checked. Reports: ZeDUI/qa/regression/2026-11-13_0011_ (alone), _0013_ (ZeD-GUI first), _0015_ (ZeD-GUI second) mods_fullscreen4k.md. Pictures and each run's console.txt: Zomboid/Screenshots/b12_release_20261113/p6 (run1, run2a, run2b). The staged mod in Zomboid/mods/LuaConsole93 is the rebuilt product (`--stage`; it changed no tracked file); it stays, as the sheet says.

### Build and release list (Run 3)
- `build_luaconsole93.py --check`: `CHECK: products/LuaConsole93 is what the sources build (61 files)`. PASS (round 2's 3-file difference is gone).
- luaconsole93_sim: 272 checks, 0 failed. kahlua_guard on products/LuaConsole93: RESULT: PASS. (Both run on this same product earlier in the pass.)
- mod.info: name Lua Console 93 Professional Edition, id LuaConsole93, modversion 1.0.0, versionMin 42.17.0, url empty; poster.png, icon.png and LICENSE.txt beside it. The workshop text file is skipped, as asked.

### Run 1: alone (4K, -debug -nosteam): PASS on every item that ran
- The window opens in -debug, titled "Lua Console 93", on the Log page.
- `print(LC93 ~= nil, ZeD == nil)` gave `true true`.
- Error row: PASS. `local x = nil; x.y = 1` three times gave ONE row: `ZEDQA lc errrow n=3 box=3 f11=3 mod=Lua Console 93 Professional Edition msg=attempted index of non-table stack=73`, `ZEDQA lc error rows=1 (expect 1, count 3)`; it opens to its stack (`stack opened=true`).
- Print row: FAIL against the expected one row (List A): `ZEDQA lc print rows 'hello' = 2 (expect 1)`, `ZEDQA lc print(a,b) rows = 2 (expect 1)` (each row reads `a b` with whitespace collapsed; the scratchpad's prints: `scratch print rows a=2 b=2`).
- Export: first line `Lua Console 93 | 2026-11-13_001231 | 42 of 42 | errors 1`, last line says the user name is taken out, 0 lines name a Users folder. PASS.
- Scratchpad: a two-line snippet ran and Save snippet wrote the snippets file (ok=1). Commands and Help pages open (pictures p6/run1/zqa_lc_x_4k_commands.png, _help.png).
- Nothing refers to ZeD-GUI: console.txt of the alone run has no `[ZeD]` line, no ZeD-GUI and no `ZeD_UI` load line; the only ZeD-named lines are the dev shim's `[ZeD.QA]` bridge lines (the test's bridge). No `[Lua Console 93]` failure line.
- Not checked (needs keys, a pad or another screen): suggestions as you type, Tab and Esc; the filters and search by hand; Up recalling the line; the Deck-size look; the controller (Back wheel, on-screen keyboard); the hand-back switch file; Russian and Polish; picking /godmode; the Help folds; right-click snippet rename.

### Run 2: both installed
- ZeD-GUI first: ZeD-GUI's console opens (title "Lua console"), LC93 is nil and ZeD is there (`globals: LC93=false ZeD=true`); the export file is `ZeD-GUI Lua console | ...`; console.txt holds `[Lua Console 93] ZeD-GUI is on: its console is used` exactly twice and no other `[Lua Console 93]` line. PASS.
- ZeD-GUI second (Lua Console 93 first): the same answers, the line twice. PASS.
- In ZeD-GUI's console: one error row with count 3 (`ZEDQA lc errrow n=3 box=3 f11=3 mod=ZeD-GUI msg=attempted index of non-table stack=73`), PASS; but the print rows are doubled the same way (`print rows 'hello' = 2`, `print(a,b) rows = 2`), List A.
- Not checked: the controller wheel (no pad); ZeD-GUI's snippets file.

### List A (real mod bugs), Part 6
1. A print shows as two rows in both consoles (Lua Console 93 and ZeD-GUI's), not one: `ZEDQA lc print rows 'hello' = 2 (expect 1)` and `ZEDQA lc print(a,b) rows = 2 (expect 1)` in all three runs. Pictures: p6/run1/zqa_lc_x_4k_prints.png and zqa_lc_x_4k_print_ab.png. Caveat: the lines went through the console's Run route, not typed keys; if a typed line gives one row the route is the difference, but it is the same call the box's Enter makes.
### List B: none. Not run: see the "not checked" items.

## Part 7. hairbeard and tab_search (neither is in main_run.txt)

Ran once each in one manifest at 4K (report ZeDUI/qa/regression/2026-11-13_b12rel_p7_4k.md; pictures Zomboid/Screenshots/b12_release_20261113/p7).
- zedqa_hairbeard.lua: WARN, 156 PASS lines, 1 FAIL: `ZEDQA hb FAIL the trait's card is drawn after the shared pause`. It now reaches the Identity tab (round 2's first-step failure is gone) and every hair, beard, folded and Show-all check passed. The one fail reads as a timing line: List B, unclear.
- zedqa_tab_search.lua: WARN, the same result as round 2: the pad lines pass (`A on the field: the pad keyboard opens`, `under the keyboard: the hand on the field`, `X on the field clears`, `the field is a stop in the tab's zone`), the cook / foot / doll lines pass, and these fail: `Skills 'bla': some kept, the rest dimmed`, `Skills 'bla': no row hidden | 35`, `Skills 'combat': a group name matched, its skills all kept | 0`, `Skills 'piloting': nothing matches`, `Skills 'piloting': the empty result's Clear shows`, `Clear empties the field`, `after Clear: nothing dimmed`, `Equipment 'hand': slot words match ...`, `Equipment 'hand': the Defense block hides`, `Equipment cleared: the Defense block is back`, `RT: the hand lands on the first match | skill:Blacksmithing`. They drive the field with script text, so List B, unclear (tab_search_sim is the logic check; the sims were not rerun in this pass).
List A: none sure. Not run: "B leaves" and A on doors afterwards (the script has no such step; needs a pad).

## End state confirmation
options.ini restored whole from my backup (fullScreen=true, 3840x2160, fontSize=2, language=EN); ModOptions.ini matches its backup; zedqa.autoload reads 0; zedqa.lock free; the game is closed; the ZeD-QA save's mods.txt lists only ZeD_UI; the main menu's default.txt is back to ZeD_UI; Summer Car's copy removed from Zomboid/mods (Lua Console 93 stays staged, as the sheet says); the real-mouse helper stopped with its stop file; no background task left. Committed: the runners' reports and this file only, no pictures. My scratch scripts (_b13_*) were deleted from the checkout, not committed. The checkout still shows Design's two modified files (d_rtv.py, d_rtv_make.py), not mine.

## Rerun after 98961a2c0

HEAD contained 98961a2c0 and the lock was free at the start. Pictures: Zomboid/Screenshots/b12_release_20261113/rerun/<part>.

### Rerun 1. What the Vehicle bug spoiled (4K, one manifest)
Ran once: the prelude, navmap, mech79, dash_lamps, dash_green, pad_figure, cov_equipfurn, cov_reading, cov_b9to11, cov_objcards, mapshot (report ZeDUI/qa/regression/2026-11-13_b12rerun_p1_4k.md). Not rerun: scripts that already gave a trustworthy result (the 30 of the second manifest, seat_lightbar, car_radio_build, car_radio_cd, dash_props_smoke, cov_vehicles, dpx).
First answer: `vehicleName` in console.txt: NO (0). "Exception thrown" from ZeD-GUI in console.txt: YES, 9 (8 in `_lampZones` and 1 in `lampText`, all in ZeD_Dashboard.lua, all raised while dash_lamps ran; see List B). Nothing else threw.
Results: navmap PASS, `ZEDQA nav 14 tabs audited: 0 traps, 0 islands (strict: each one is a failing line)`; mech79 WARN, `ZEDQA m79 summary: 7 of 45 checks FAIL` (38 PASS, up from 1: the Vehicle tab draws now); pad_figure PASS; mapshot PASS; cov_objcards 82 pass, 0 fail, 0 step errors (PASS-level, WARN only by an ERR line); cov_reading `RESULT 146 pass, 3 fail`; cov_b9to11 `RESULT 251 pass, 1 fail`; cov_equipfurn `RESULT 69 pass, 10 fail`; dash_lamps FAIL; dash_green WARN. The windows are there again in every script (the safe-mode cascade is gone).
List A (real mod bugs): none sure. The three that stay are the same lines as round 2 and may be real: `ZEDQA cov_reading FAIL a click on Category opens its list (false vs true)` with `a click on a category in the list picks it (all vs armor)` and `the category keeps its own recipes only (1167 rows, 1151 from elsewhere vs 16 rows, 0)` (the Journal's Recipes Category list); and mech79's `ZEDQA m79 FAIL hover on a row lights its part on the diagram (Muffler, lit nil)`, repeated on the pickup, van, sports car and trailer, with `ZEDQA m79 FAIL Base.PickUpTruck: inspected, its tab on it` and `a click on the diagram picks a part (nil)`. Pictures: rerun/p1/zqa_covrd_*.png, zqa_m79_3840x2160_2_hover_row.png. Unclear whether the test or the mod is wrong; the director should look at the Category list by hand.
List B (test trouble): dl and dgr: `ZEDQA dl ERR elite car not settled at the seat step; not entered (square=true chunk=true physics=false dist=19.0 ...)` and six `ZEDQA dgr ERR <car> car not settled at the seat step` lines (19 to 25 tiles away): the car never got a driver, so no dash existed; dl then called ZeD's dash helpers on nothing (`attempted index: _lampZones of non-table`, `hlL of non-table`), which is the 9 exceptions. cov_equipfurn: the furniture lines (`Rotate: the S button picks the south face for this tile (nil on none, cursor 4 vs 3 ...)`, Repair and Pick up "ON THIS TILE" rows, Disassemble) read a tile one off the cursor, as in round 2; unclear. cov_b9to11: `#134 color: a map mod's label ... (isVisible false (PlaceNames false ...))`, the same line as round 2; unclear.
Not run: nothing skipped.

### Rerun 2. Summer Car with the mod on (4K)
Ran once with zedqa_mods_run.ps1 (summercar_mods.txt, summercar_manifest.txt), the real-mouse helper beside it, the mod copied in for the run and removed after, the save restored (mods.txt: ZeD_UI only). Report: ZeDUI/qa/regression/2026-11-13_0049_mods_fullscreen4k.md (WARN, 93 s: one ERR line). Pictures: rerun/p2 (zqa_sc_B..N).
- Opens by itself on inspect: YES. `ZEDQA sc engine window true 193 ms after the inspection`, `PASS B: anchored to the tab, for this car`.
- Position and size at the default layout: `ZEDQA sc B opened: engine window 624,10 500x631 anchored=true vehicle=v | World window 2643,0 903x735`: x=624, y=10, 500 x 631, on the free side (left of the World window, about the expected x=626), not over the Character window; 10 px below the World window's top; the 10 px gap to the World window holds (`PASS B: no horizontal overlap with the World window, the mod's gap`). The World window itself was 903 wide at 2643 at that moment (the tab's narrow layout), so the gap line reads against its full-width place.
- Stays open 5 s (C), holds with the pointer and goes with a fold (D), the player's close lasts through Loot and back (E), Inspect from the menu and the footer opens it beside (F, G), a shut hood closes it with the mod's sentence and an open hood reopens it (H), one window for a second car at the same x=624 (I), rolled closes and unrolled brings it back (J), closing the World window closes it and reopening brings it back (K), and with the World window dragged to x=1111 it opens on the right at x=2738, y=10 (L). All PASS.
List A: none. List B: `ZEDQA sc ERR B: the World window not moved (1929)`: the check expects the World window at 1929 but it stood at 2643 (narrow tab layout); unclear, a test expectation. Not run: step M (`M outside wheel:` printed no result) and O (`skipped: no pad`).

### Rerun 3. Print rows in both consoles (4K, one launch each)
Ran: a short bridge script of my own (not committed) through the console's Run route, once in Lua Console 93 alone (`build_luaconsole93.py --check` still passes; the rebuilt product staged; the shim in the list for the bridge, default.txt = LuaConsole93 and the shim) and once in ZeD-GUI's console. Reports: ZeDUI/qa/regression/2026-11-13_0053_mods_fullscreen4k.md (alone) and 2026-11-13_b12rerun_lc_zed_4k.md (ZeD-GUI). Pictures: rerun/p3/lc93 and rerun/p3/zed.
Both consoles: PASS. `print("hello")`: `ZEDQA lc print(hello): print rows = 1 (expect 1); ran rows holding the line = 1 (expect 1)`, the one "ran" row is `> print("hello")` (no second `> - "..."` echo row); `print("a","b")`: `ZEDQA lc print(a,b): print rows = 1 (expect 1)`, the row reads `a b`; a scratchpad run of `print("s1")`: `print rows = 1 (expect 1); ran rows holding it = 1`.
List A: none (the doubled print rows of the release pass are fixed). List B: none. Not run: typed keys (same route as before). The default.txt is back to ZeD_UI and the export/snippet files this run made were removed.

### Rerun 4. Radio, Vehicle and a long Kind at 1280x800 (Small text)
Ran: a bridge script of my own (not committed) after the prelude: a ValuTech walkie in the hand and turned on, then a car spawned beside the character and inspected through the game's own Vehicle Mechanics call. Report: ZeDUI/qa/regression/2026-11-13_b12rerun_p4_deck.md (2/2 pass). Pictures: Zomboid/Screenshots/b12_release_20261113/rerun/p4 (zqa_r4_radio_tab.png, zqa_r4_vehicle_tab.png, zqa_r4_vehicle_tab_later.png, zqa_r4_card_long_kind.png).
- Radio tab: shows now (`char tabs: loot,equip,health,thermal,identity,journal,skills,radio`). The walkie's face fills the left drawer (ValuTech, dial, yellow display, M and arrow buttons), its name above it, full-screen box at the top right; text fits. It is one device, so there is no sub-page strip to see; with more devices the strip would show.
- Vehicle tab: it came up after the inspection finished, not at once (the first picture, taken 300 ticks after the call, still had `inspected=false` and no tab; `world tabs later: ...,animals,vehicle`). Once up (zqa_r4_vehicle_tab_later.png) it reads "Chevalier Nyala | Standard", the "Parts (40)" strip, the Inspect button, then (zqa_r4_card_long_kind.png, same tab inspected) the parts list "Under Hood (9)", Muffler, Hood, Battery, Engine... with condition bars, the car diagram and "Close Hood" in the footer. Text fits.
- Item card with a long Kind (a Broom): `Kind` sits on its own line with `Household / Weapon` wrapped beneath it, whole, not cut; `Weight 2.0 kg` below. PASS.
List A: none. List B: the Vehicle tab needed about 300+ ticks to appear after the call; my first picture was too early (staging timing, not a mod fault). Not run: Large text for these pictures (one picture each was asked).

### End state (rerun)
options.ini restored whole from my backup (fullScreen=true, 3840x2160, fontSize=2, language=EN); ModOptions.ini matches its backup; zedqa.autoload 0; lock free; game closed; ZeD-QA mods.txt lists only ZeD_UI; default.txt is ZeD_UI; Summer Car's copy removed; Lua Console 93 stays staged (the rebuilt product); the mouse helper stopped; no background task left; scratch files (_b14_*) deleted from the checkout; only reports and this file committed, no pictures.

## Rerun after 14aec8ff3

HEAD contained 14aec8ff3; the lock was free. One 4K launch with the real-mouse helper (release_check_mouse.ps1) running beside it: the prelude, cov_reading, twoway, mech79. Report: ZeDUI/qa/regression/2026-11-13_b12rerun2_4k.md (3 of 4 pass, 1 warn).
1. cov_reading: PASS, `ZEDQA cov_reading RESULT 149 pass, 0 fail`. `ZEDQA cov_reading PASS a click on Category opens its list`, `PASS a click on a category in the list picks it`, `PASS the category keeps its own recipes only`.
2. twoway: PASS, `ZEDQA tw PASS the header button opens full view on the radio` (and `PASS the header button closes full view`); `ZEDQA tw 192 passed, 0 failed`.
3. mech79: WARN, `ZEDQA m79 summary: 7 of 45 checks FAIL` (the same 7 as before). Each FAIL with the WARN before it: `ZEDQA m79 WARN step 2: waited 3600 frames, went on` then `ZEDQA m79 FAIL hover on a row lights its part on the diagram (Muffler, lit nil)`; `ZEDQA m79 WARN step 40: waited 3600 frames, went on` then `FAIL Base.PickUpTruck: inspected, its tab on it`, `FAIL Base.PickUpTruck: hover on a row lights its part (Muffler, lit nil)`, `FAIL Base.PickUpTruck: a click on the diagram picks a part (nil)`; and with no WARN before them: `FAIL Base.Van: hover on a row lights its part (Muffler, lit nil)`, `FAIL Base.SportsCar: ...` and `FAIL Base.Trailer: ...` (same wording). No "move" wait timed out; the two WARNs are "waited 3600 frames" waits (the first the car and tab coming up, the second the pickup's inspection). The mouse helper was running this time and the hover failures are the same, so the helper is not the cause. During the earlier rerun on 98961a2c0 the mouse helper was NOT running (that rerun used zedqa_run.ps1 alone). List A: unclear, the hover-on-a-row lighting `lit nil` repeats on all five bodies with the helper running; List B: the two waits timing out.
4. "Exception thrown" from ZeD-GUI in console.txt: none (0; no "Exception thrown" at all).

End state: options.ini restored whole (fullScreen=true, 3840x2160, fontSize=2, language=EN); ModOptions.ini matches its backup; zedqa.autoload 0; lock free; game closed; ZeD-QA mods.txt lists only ZeD_UI; the mouse helper stopped with its stop file; no background task left; scratch manifest deleted; only the report and this file committed, no pictures.
