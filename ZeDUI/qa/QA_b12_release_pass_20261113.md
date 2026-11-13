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
