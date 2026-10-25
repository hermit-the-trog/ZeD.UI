# ZeD-UI regression - 2026-10-24 23:10 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-24 23:10:55 |
| Finished | 2026-10-24 23:26:57 (16 min 1 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\dash_r6.txt (3 scripts) |
| Result | **1/3 pass**, 1 warn, 1 fail, 0 timeout |
| Go numbers | 12386 to 12390 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 12389, 12390)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_dash_r6_keys.lua | r6k | WARN | 531 | zqa_r6k_site.png, zqa_r6_01_luxury_run_k2.png, zqa_r6_01_luxury_run_k1.png, zqa_r6_01_luxury_tray_shut.png, zqa_r6_01_luxury_tray_open.png, zqa_r6_01_luxury_key_start.png, zqa_r6_03_cossette_run_k2.png, zqa_r6_03_cossette_run_k1.png, zqa_r6_03_cossette_tray_shut.png, zqa_r6_03_cossette_tray_open.png, zqa_r6_03_cossette_key_start.png, zqa_r6_05_d6_run_k2.png, zqa_r6_05_d6_run_k1.png, zqa_r6_05_d6_tray_open.png, zqa_r6_05_d6_key_start.png, zqa_r6_07_primani_run_k2.png, zqa_r6_07_primani_run_k1.png, zqa_r6_07_primani_tray_open.png, zqa_r6_07_primani_key_start.png, zqa_r6_08_dart_run_k2.png, zqa_r6_08_dart_run_k1.png, zqa_r6_08_dart_tray_shut.png, zqa_r6_08_dart_tray_open.png, zqa_r6_08_dart_key_start.png, zqa_r6_09_horizon_run_k2.png, zqa_r6_09_horizon_run_k1.png, zqa_r6_09_horizon_tray_shut.png, zqa_r6_09_horizon_tray_open.png, zqa_r6_09_horizon_key_start.png, zqa_r6_10_wagon_run_k2.png, zqa_r6_10_wagon_run_k1.png, zqa_r6_10_wagon_tray_open.png, zqa_r6_10_wagon_key_start.png, zqa_r6_11_suv_run_k2.png, zqa_r6_11_suv_run_k1.png, zqa_r6_11_suv_tray_open.png, zqa_r6_11_suv_key_start.png, zqa_r6_12_van_run_k2.png, zqa_r6_12_van_run_k1.png, zqa_r6_12_van_tray_shut.png, zqa_r6_12_van_tray_open.png, zqa_r6_12_van_key_start.png, zqa_r6_14_rancher_run_k2.png, zqa_r6_14_rancher_run_k1.png, zqa_r6_14_rancher_tray_open.png, zqa_r6_14_rancher_key_start.png, zqa_r6_19_race_run_k2.png, zqa_r6_19_race_run_k1.png, zqa_r6_19_race_key_start.png | 26 expected exception(s) ignored (expect=); 24 ERR line(s) |
| 3 | zedqa_dash_r6_parts.lua | r6p | **FAIL** | 319 | zqa_r6p_site.png, zqa_r6p_van_spiffo.png, zqa_r6p_van_mechanic.png, zqa_r6p_van_stepvan.png, zqa_r6p_van_stepvan_open.png, zqa_r6p_taxi_extras.png, zqa_r6p_taxi_waited.png, zqa_r6p_taxi_night_lit.png, zqa_r6p_taxi_night_dark.png, zqa_r6p_night_van_lit.png, zqa_r6p_night_van_dark.png, zqa_r6p_night_ambulance_lit.png, zqa_r6p_night_ambulance_dark.png, zqa_r6p_keep_untouched.png | 1 Java exception(s) in the log; 16 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 12386 at 23:12:06

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre DONE
```

### 2. zedqa_dash_r6_keys.lua (`ZEDQA r6k`) - WARN, 531 s

- go 12387 at 23:12:12
- 26 expected exception(s) ignored (expect=)
- 24 ERR line(s)
- screenshots: zqa_r6k_site.png, zqa_r6_01_luxury_run_k2.png, zqa_r6_01_luxury_run_k1.png, zqa_r6_01_luxury_tray_shut.png, zqa_r6_01_luxury_tray_open.png, zqa_r6_01_luxury_key_start.png, zqa_r6_03_cossette_run_k2.png, zqa_r6_03_cossette_run_k1.png, zqa_r6_03_cossette_tray_shut.png, zqa_r6_03_cossette_tray_open.png, zqa_r6_03_cossette_key_start.png, zqa_r6_05_d6_run_k2.png, zqa_r6_05_d6_run_k1.png, zqa_r6_05_d6_tray_open.png, zqa_r6_05_d6_key_start.png, zqa_r6_07_primani_run_k2.png, zqa_r6_07_primani_run_k1.png, zqa_r6_07_primani_tray_open.png, zqa_r6_07_primani_key_start.png, zqa_r6_08_dart_run_k2.png, zqa_r6_08_dart_run_k1.png, zqa_r6_08_dart_tray_shut.png, zqa_r6_08_dart_tray_open.png, zqa_r6_08_dart_key_start.png, zqa_r6_09_horizon_run_k2.png, zqa_r6_09_horizon_run_k1.png, zqa_r6_09_horizon_tray_shut.png, zqa_r6_09_horizon_tray_open.png, zqa_r6_09_horizon_key_start.png, zqa_r6_10_wagon_run_k2.png, zqa_r6_10_wagon_run_k1.png, zqa_r6_10_wagon_tray_open.png, zqa_r6_10_wagon_key_start.png, zqa_r6_11_suv_run_k2.png, zqa_r6_11_suv_run_k1.png, zqa_r6_11_suv_tray_open.png, zqa_r6_11_suv_key_start.png, zqa_r6_12_van_run_k2.png, zqa_r6_12_van_run_k1.png, zqa_r6_12_van_tray_shut.png, zqa_r6_12_van_tray_open.png, zqa_r6_12_van_key_start.png, zqa_r6_14_rancher_run_k2.png, zqa_r6_14_rancher_run_k1.png, zqa_r6_14_rancher_tray_open.png, zqa_r6_14_rancher_key_start.png, zqa_r6_19_race_run_k2.png, zqa_r6_19_race_run_k1.png, zqa_r6_19_race_key_start.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA r6k at the speedway 925,13040 (home 10985,11301)
ZEDQA r6k 01_luxury staged design=luxury script=Base.CarLuxury keyPos=nil keyId=27834436 rect=1120,1804,1600,344 k=2
ZEDQA r6k 01_luxury insert key: nil@0 off@12 | engine: Idle@12
ZEDQA r6k 01_luxury start key: off@0 on@4 start@142 on@1527 | engine: Idle@4 StartingSuccess@25 Running+run@1527
ZEDQA r6k 01_luxury start ON step 2 held 138 ms
ZEDQA r6k 01_luxury run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 01_luxury run_k1 1520,1982,800,172 k=1
ZEDQA r6k 01_luxury tray default open=true level=2 md=nil
ZEDQA r6k 01_luxury tray click1 open=false level=0 md=false
ZEDQA r6k 01_luxury tray click2 open=true level=2
ZEDQA r6k 01_luxury shutoff key: on@0 off@154 | engine: Running+run@4 ShuttingDown@17
ZEDQA r6k 01_luxury shutoff ON after the engine stopped 137 ms
ZEDQA r6k 01_luxury dry start key: off@0 on@5 start@143 on@1542 off@1677 | engine: Idle@5 StartingFailed@23 Idle@1542
ZEDQA r6k 01_luxury dry start ON step 2 held 138 ms
ZEDQA r6k 01_luxury dry start ON step 4 held 135 ms
ZEDQA r6k 01_luxury key out key: off@0 nil@4 | engine: Idle@4
ZEDQA r6k ERR 02_nyala car not settled at the seat step; not entered
ZEDQA r6k ERR 02_nyala engine never ran
ZEDQA r6k 02_nyala start key: nil@0 | engine:
ZEDQA r6k ERR 02_nyala start key went nil, want off on start on
ZEDQA r6k 03_cossette staged design=cossette script=Base.SportsCar keyPos=nil keyId=84104304 rect=1120,1804,1600,344 k=2
ZEDQA r6k 03_cossette insert key: nil@0 off@2 | engine: Idle@2
ERROR: General f:6791> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -1 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6792> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -1 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6793> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -1 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6794> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -1 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6795> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -1 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6796> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -1 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6797> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -2 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6798> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -2 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6799> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -2 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6800> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -2 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6801> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -2 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6802> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -2 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6803> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -2 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6804> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -2 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6805> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -2 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6806> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -3 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6807> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -3 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6808> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -3 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6809> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -3 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6810> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -3 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6811> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -3 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6812> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -3 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6813> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -3 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6814> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -3 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6815> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -3 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ERROR: General f:6816> FBORenderCell.renderInternal> Exception thrown   (expected)
    java.lang.ArrayIndexOutOfBoundsException: Index -4 out of bounds for length 32 at FBORenderLevels.getNLevels(FBORenderLevels.java:139).
ZEDQA r6k 03_cossette start key: off@0 on@2 start@135 on@1540 | engine: Idle@2 StartingSuccess@18 Running+run@1540
ZEDQA r6k 03_cossette start ON step 2 held 133 ms
ZEDQA r6k 03_cossette run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 03_cossette run_k1 1520,1982,800,172 k=1
ZEDQA r6k 03_cossette tray default open=true level=2 md=nil
ZEDQA r6k 03_cossette tray click1 open=false level=0 md=false
ZEDQA r6k 03_cossette tray click2 open=true level=2
ZEDQA r6k 03_cossette shutoff key: on@0 off@143 | engine: Running+run@0 ShuttingDown@13
ZEDQA r6k 03_cossette shutoff ON after the engine stopped 130 ms
ZEDQA r6k 03_cossette dry start key: off@0 on@2 start@136 on@1534 off@1665 | engine: Idle@2 StartingFailed@19 Idle@1534
ZEDQA r6k 03_cossette dry start ON step 2 held 134 ms
ZEDQA r6k 03_cossette dry start ON step 4 held 131 ms
ERROR: General f:7502 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA r6k 03_cossette key out key: off@0 nil@2 | engine: Idle@2
ZEDQA r6k ERR 04_police car not settled at the seat step; not entered
ZEDQA r6k ERR 04_police engine never ran
ZEDQA r6k 04_police start key: nil@0 | engine:
ZEDQA r6k ERR 04_police start key went nil, want off on start on
ZEDQA r6k 05_d6 staged design=d6 script=Base.PickUpTruck keyPos=nil keyId=39449375 rect=1120,1804,1600,344 k=2
ZEDQA r6k 05_d6 insert key: nil@0 off@3 | engine: Idle@3
ZEDQA r6k 05_d6 start key: off@0 on@4 start@140 on@1540 | engine: Idle@4 StartingSuccess@22 Running+run@1540
ZEDQA r6k 05_d6 start ON step 2 held 136 ms
ZEDQA r6k 05_d6 run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 05_d6 run_k1 1520,1982,800,172 k=1
ZEDQA r6k 05_d6 tray default open=false level=0 md=nil
ZEDQA r6k 05_d6 tray click1 open=true level=3 md=true
ZEDQA r6k 05_d6 tray click2 open=false level=0
ZEDQA r6k 05_d6 shutoff key: on@0 off@153 | engine: Running+run@3 ShuttingDown@21
ZEDQA r6k 05_d6 shutoff ON after the engine stopped 132 ms
ZEDQA r6k 05_d6 dry start key: off@0 on@3 start@133 on@1739 off@1869 | engine: Idle@3 StartingFailed@19 Idle@1739
ZEDQA r6k 05_d6 dry start ON step 2 held 130 ms
ZEDQA r6k 05_d6 dry start ON step 4 held 130 ms
ZEDQA r6k 05_d6 key out key: off@0 nil@9 | engine: Idle@9
ZEDQA r6k ERR 06_dashelite car not settled at the seat step; not entered
ZEDQA r6k ERR 06_dashelite engine never ran
ZEDQA r6k 06_dashelite start key: nil@0 | engine:
ZEDQA r6k ERR 06_dashelite start key went nil, want off on start on
ZEDQA r6k 07_primani staged design=primani script=Base.ModernCar02 keyPos=nil keyId=56470854 rect=1120,1804,1600,344 k=2
ZEDQA r6k 07_primani insert key: nil@0 off@5 | engine: Idle@5
ZEDQA r6k 07_primani start key: off@0 on@3 start@138 on@1533 | engine: Idle@3 StartingSuccess@24 Running+run@1533
ZEDQA r6k 07_primani start ON step 2 held 135 ms
ZEDQA r6k 07_primani run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 07_primani run_k1 1520,1982,800,172 k=1
ZEDQA r6k 07_primani tray default open=false level=0 md=nil
ZEDQA r6k 07_primani tray click1 open=true level=1 md=true
ZEDQA r6k 07_primani tray click2 open=false level=0
ZEDQA r6k 07_primani shutoff key: on@0 off@127 | engine: ShuttingDown@7
ZEDQA r6k 07_primani dry start key: off@0 on@3 start@123 on@1730 off@1866 | engine: Idle@3 StartingFailed@19 Idle@1730
ZEDQA r6k 07_primani dry start ON step 2 held 120 ms
ZEDQA r6k 07_primani dry start ON step 4 held 136 ms
ZEDQA r6k 07_primani key out key: off@0 nil@4 | engine: Idle@4
ZEDQA r6k 08_dart staged design=dart script=Base.SmallCar keyPos=nil keyId=95535047 rect=1120,1804,1600,344 k=2
ZEDQA r6k 08_dart insert key: nil@0 off@1 | engine: Idle@1
ZEDQA r6k 08_dart start key: off@0 on@3 start@139 on@1520 | engine: Idle@3 StartingSuccess@20 Running+run@1520
ZEDQA r6k 08_dart start ON step 2 held 136 ms
ZEDQA r6k 08_dart run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 08_dart run_k1 1520,1982,800,172 k=1
ZEDQA r6k 08_dart tray default open=true level=1 md=nil
ZEDQA r6k 08_dart tray click1 open=false level=0 md=false
ZEDQA r6k 08_dart tray click2 open=true level=1
ZEDQA r6k 08_dart shutoff key: on@0 off@144 | engine: Running+run@4 ShuttingDown@15
ZEDQA r6k 08_dart shutoff ON after the engine stopped 129 ms
ZEDQA r6k 08_dart dry start key: off@0 on@5 start@141 on@1760 off@1891 | engine: Idle@5 Starting@20 StartingFailed@42 Idle@1760
ZEDQA r6k 08_dart dry start ON step 2 held 136 ms
ZEDQA r6k 08_dart dry start ON step 4 held 131 ms
ZEDQA r6k 08_dart key out key: off@0 nil@8 | engine: Idle@8
ZEDQA r6k 09_horizon staged design=horizon script=Base.SmallCar02 keyPos=nil keyId=32244752 rect=1120,1804,1600,344 k=2
ZEDQA r6k 09_horizon insert key: nil@0 off@9 | engine: Idle@9
ZEDQA r6k 09_horizon start key: off@0 on@4 start@136 on@1555 | engine: Idle@4 Starting@26 StartingSuccess@42 Running+run@1555
ZEDQA r6k 09_horizon start ON step 2 held 132 ms
ZEDQA r6k 09_horizon run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 09_horizon run_k1 1520,1982,800,172 k=1
ZEDQA r6k 09_horizon tray default open=true level=1 md=nil
ZEDQA r6k 09_horizon tray click1 open=false level=0 md=false
ZEDQA r6k 09_horizon tray click2 open=true level=1
ZEDQA r6k 09_horizon shutoff key: on@0 off@152 | engine: Running+run@5 ShuttingDown@19
ZEDQA r6k 09_horizon shutoff ON after the engine stopped 133 ms
ZEDQA r6k 09_horizon dry start key: off@0 on@4 start@139 on@1714 off@1847 | engine: Idle@4 Starting@17 StartingFailed@37 Idle@1714
ZEDQA r6k 09_horizon dry start ON step 2 held 135 ms
ZEDQA r6k 09_horizon dry start ON step 4 held 133 ms
ZEDQA r6k 09_horizon key out key: off@0 nil@3 | engine: Idle@3
ZEDQA r6k 10_wagon staged design=wagon script=Base.CarStationWagon keyPos=nil keyId=24543336 rect=1120,1804,1600,344 k=2
ZEDQA r6k 10_wagon insert key: nil@0 off@4 | engine: Idle@4
ZEDQA r6k 10_wagon start key: off@0 on@4 start@131 on@1536 | engine: Idle@4 Starting@17 StartingSuccess@35 Running+run@1536
ZEDQA r6k 10_wagon start ON step 2 held 127 ms
ZEDQA r6k 10_wagon run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 10_wagon run_k1 1520,1982,800,172 k=1
ZEDQA r6k 10_wagon tray default open=false level=0 md=nil
ZEDQA r6k 10_wagon tray click1 open=true level=1 md=true
ZEDQA r6k 10_wagon tray click2 open=false level=0
ZEDQA r6k 10_wagon shutoff key: on@0 off@148 | engine: Running+run@4 ShuttingDown@28
ZEDQA r6k 10_wagon shutoff ON after the engine stopped 120 ms
ZEDQA r6k 10_wagon dry start key: off@0 on@2 start@132 on@1724 off@1854 | engine: Idle@2 Starting@15 StartingFailed@34 Idle@1724
ZEDQA r6k 10_wagon dry start ON step 2 held 130 ms
ZEDQA r6k 10_wagon dry start ON step 4 held 130 ms
ZEDQA r6k 10_wagon key out key: off@0 nil@4 | engine: Idle@4
ZEDQA r6k 11_suv staged design=suv script=Base.SUV keyPos=nil keyId=18481320 rect=1120,1804,1600,344 k=2
ZEDQA r6k 11_suv insert key: nil@0 off@5 | engine: Idle@5
ZEDQA r6k 11_suv start key: off@0 on@3 start@143 on@1519 | engine: Idle@3 StartingSuccess@18 Running+run@1519
ZEDQA r6k 11_suv start ON step 2 held 140 ms
ZEDQA r6k 11_suv run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 11_suv run_k1 1520,1982,800,172 k=1
ZEDQA r6k 11_suv tray default open=false level=0 md=nil
ZEDQA r6k 11_suv tray click1 open=true level=2 md=true
ZEDQA r6k 11_suv tray click2 open=false level=0
ZEDQA r6k 11_suv shutoff key: on@0 off@150 | engine: Running+run@4 ShuttingDown@23
ZEDQA r6k 11_suv shutoff ON after the engine stopped 127 ms
ZEDQA r6k 11_suv dry start key: off@0 on@3 start@135 on@1723 off@1853 | engine: Idle@3 StartingFailed@21 Idle@1723
ZEDQA r6k 11_suv dry start ON step 2 held 132 ms
ZEDQA r6k 11_suv dry start ON step 4 held 130 ms
ZEDQA r6k 11_suv key out key: off@0 nil@8 | engine: Idle@8
ZEDQA r6k 12_van staged design=van script=Base.Van keyPos=nil keyId=90735744 rect=1120,1804,1600,344 k=2
ZEDQA r6k 12_van insert key: nil@0 off@4 | engine: Idle@4
ZEDQA r6k 12_van start key: off@0 on@6 start@128 on@1525 | engine: Idle@6 StartingSuccess@19 Running+run@1525
ZEDQA r6k 12_van start ON step 2 held 122 ms
ZEDQA r6k 12_van run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 12_van run_k1 1520,1982,800,172 k=1
ZEDQA r6k 12_van tray default open=true level=1 md=nil
ZEDQA r6k 12_van tray click1 open=false level=0 md=false
ZEDQA r6k 12_van tray click2 open=true level=1
ZEDQA r6k 12_van shutoff key: on@0 off@145 | engine: Running+run@2 ShuttingDown@19
ZEDQA r6k 12_van shutoff ON after the engine stopped 126 ms
ZEDQA r6k 12_van dry start key: off@0 on@8 start@144 on@1732 off@1856 | engine: StartingFailed@8 Idle@1732
ZEDQA r6k 12_van dry start ON step 2 held 136 ms
ZEDQA r6k 12_van dry start ON step 4 held 124 ms
ZEDQA r6k 12_van key out key: off@0 nil@12 | engine: Idle@12
ZEDQA r6k ERR 13_bulldriver car not settled at the seat step; not entered
ZEDQA r6k ERR 13_bulldriver engine never ran
ZEDQA r6k 13_bulldriver start key: nil@0 | engine:
ZEDQA r6k ERR 13_bulldriver start key went nil, want off on start on
ZEDQA r6k 14_rancher staged design=rancher script=Base.OffRoad keyPos=nil keyId=2580475 rect=1120,1804,1600,344 k=2
ZEDQA r6k 14_rancher insert key: nil@0 off@3 | engine: Idle@3
ZEDQA r6k 14_rancher start key: off@0 on@9 start@140 on@1528 | engine: Starting@9 StartingSuccess@29 Running+run@1528
ZEDQA r6k 14_rancher start ON step 2 held 131 ms
ZEDQA r6k 14_rancher run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 14_rancher run_k1 1520,1982,800,172 k=1
ZEDQA r6k 14_rancher tray default open=false level=0 md=nil
ZEDQA r6k 14_rancher tray click1 open=true level=1 md=true
ZEDQA r6k 14_rancher tray click2 open=false level=0
ZEDQA r6k 14_rancher shutoff key: on@0 off@141 | engine: ShuttingDown@8
ZEDQA r6k 14_rancher dry start key: off@0 on@11 start@144 on@1757 off@1888 | engine: Starting@11 StartingFailed@22 Idle@1757
ZEDQA r6k 14_rancher dry start ON step 2 held 133 ms
ZEDQA r6k 14_rancher dry start ON step 4 held 131 ms
ZEDQA r6k 14_rancher key out key: off@0 nil@4 | engine: Idle@4
ZEDQA r6k ERR 15_taxi car not settled at the seat step; not entered
ZEDQA r6k ERR 15_taxi engine never ran
ZEDQA r6k 15_taxi start key: nil@0 | engine:
ZEDQA r6k ERR 15_taxi start key went nil, want off on start on
ZEDQA r6k ERR 16_ambulance car not settled at the seat step; not entered
ZEDQA r6k ERR 16_ambulance engine never ran
ZEDQA r6k 16_ambulance start key: nil@0 | engine:
ZEDQA r6k ERR 16_ambulance start key went nil, want off on start on
ZEDQA r6k ERR 17_fire car not settled at the seat step; not entered
ZEDQA r6k ERR 17_fire engine never ran
ZEDQA r6k 17_fire start key: nil@0 | engine:
ZEDQA r6k ERR 17_fire start key went nil, want off on start on
ZEDQA r6k ERR 18_ranger car not settled at the seat step; not entered
ZEDQA r6k ERR 18_ranger engine never ran
ZEDQA r6k 18_ranger start key: nil@0 | engine:
ZEDQA r6k ERR 18_ranger start key went nil, want off on start on
ERROR: General f:50485 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:50669 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA r6k 19_race staged design=race script=Base.RaceCar12 keyPos=nil keyId=10941202 rect=1120,1804,1600,344 k=2
ZEDQA r6k 19_race insert key: nil@0 off@4 | engine: Idle@4
ZEDQA r6k 19_race start key: off@0 on@8 start@139 on@1525 | engine: Starting@8 StartingSuccess@25 Running+run@1525
ZEDQA r6k 19_race start ON step 2 held 131 ms
ZEDQA r6k 19_race run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 19_race run_k1 1520,1982,800,172 k=1
ZEDQA r6k 19_race no tray (hit=false ashOpen=0)
ZEDQA r6k 19_race shutoff key: on@0 off@148 | engine: ShuttingDown@8
ZEDQA r6k 19_race dry start key: off@0 on@3 start@134 on@1720 off@1850 | engine: Idle@3 StartingFailed@22 Idle@1720
ZEDQA r6k 19_race dry start ON step 2 held 131 ms
ZEDQA r6k 19_race dry start ON step 4 held 130 ms
ZEDQA r6k 19_race key out key: off@0 nil@4 | engine: Idle@4
ZEDQA r6k back home 10985,11301
ZEDQA r6k errors=24
ZEDQA r6k DONE
```

### 3. zedqa_dash_r6_parts.lua (`ZEDQA r6p`) - FAIL, 319 s

- go 12388 at 23:21:06
- 1 Java exception(s) in the log
- 16 ERR line(s)
- screenshots: zqa_r6p_site.png, zqa_r6p_van_spiffo.png, zqa_r6p_van_mechanic.png, zqa_r6p_van_stepvan.png, zqa_r6p_van_stepvan_open.png, zqa_r6p_taxi_extras.png, zqa_r6p_taxi_waited.png, zqa_r6p_taxi_night_lit.png, zqa_r6p_taxi_night_dark.png, zqa_r6p_night_van_lit.png, zqa_r6p_night_van_dark.png, zqa_r6p_night_ambulance_lit.png, zqa_r6p_night_ambulance_dark.png, zqa_r6p_keep_untouched.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ERROR: General f:51912> Lua(Vanilla).act> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in act at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).act(spawnpoints.lua:196)
    Lua(Vanilla).step(spawnpoints.lua:31)
    Lua(Vanilla).tick(spawnpoints.lua:474)
ZEDQA r6p step error: Object tried to call nil in act java.lang.RuntimeException
ERROR: General f:51958 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:51966 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA r6p at the speedway 925,13040 (home 10985,11301)
ZEDQA r6p van_spiffo design=van vanRight=nil vanTray=false logo=media/textures/shirtdecals/Buisness_SpiffosDECAL.png ash=false/0
ZEDQA r6p ERR van_fossoil car not settled at the seat step; not entered
ZEDQA r6p ERR van_mccoy car not settled at the seat step; not entered
ZEDQA r6p ERR van_johnmccoy car not settled at the seat step; not entered
ZEDQA r6p van_mechanic design=van vanRight=nosmoke vanTray=false logo=none ash=false/0
ZEDQA r6p ERR van_mail car not settled at the seat step; not entered
ZEDQA r6p ERR van_plain car not settled at the seat step; not entered
ZEDQA r6p ERR van_creature car not settled at the seat step; not entered
ZEDQA r6p van_stepvan design=van vanRight=ash vanTray=true logo=none ash=false/0
ZEDQA r6p van_stepvan tray clicked: open false -> true level=2
ZEDQA r6p ERR taxi car not settled at the seat step; not entered
ZEDQA r6p taxi riders 2 -> extras 0.00
ZEDQA r6p ERR taxi extras with 2 riders 0.00
ZEDQA r6p taxi riders 3 -> extras 0.00
ZEDQA r6p ERR taxi extras with 3 riders 0.00
ZEDQA r6p taxi riders 1 -> extras 0.00
ZEDQA r6p taxi waiting from fare 0.00
ZEDQA r6p taxi waited 30 s: fare 0.00
ZEDQA r6p taxi waited 61 s: fare 0.00
ZEDQA r6p ERR taxi a minute's wait gave fare 0.00, want 1.75
ZEDQA r6p taxi KEYS
ZEDQA r6p taxi drove: max 0.0 km/h, hula frames , fare -1.00 -> 0.00, fifths -1.000 -> 0.000 mi
ZEDQA r6p ERR taxi never moved
ZEDQA r6p ERR taxi hula did not sway both ways (1=false 2=false)
ZEDQA r6p ERR taxi meter counted no distance while driving
ZEDQA r6p ERR taxi drove less than a fifth of a mile: no distance click to see
ZEDQA r6p keep untouched key=56640713 open=false level=0 md=nil at 898,13045
ZEDQA r6p ERR keep_clicked car not settled at the seat step; not entered
ZEDQA r6p persist file written: 1 cars
ZEDQA r6p back home 10985,11301
ZEDQA r6p errors=15
ZEDQA r6p DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
