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
1. The Vehicle tab throws on every frame once a car is in view: 108 exceptions (52 in navmap, 56 in mech79). Lines: `ERROR: General f:27184> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown`, `java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).`, `Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)`, `Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)`, `Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)`. Line 400 is `local sc = v:getScript()`: the tab holds a car that is gone from the world (the helper's "took away a car" removal; the same would happen to a car that is destroyed or unloaded), so the tab should drop it. mech79 passed one check and then read nil (`zedqa_mechp79 ... FAIL` lines; 35 of its checks). Pictures: p2/zqa_m79_3840x2160_*.png.

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
