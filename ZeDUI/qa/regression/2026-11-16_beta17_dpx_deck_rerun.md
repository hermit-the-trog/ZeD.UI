# ZeD-UI regression - 2026-11-16 14:02 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-16 14:02:29 |
| Finished | 2026-11-16 14:07:18 (4 min 49 s) |
| Mode | windowed (1280x800 window) |
| Display | fontSize=2 fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta17 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\AppData\Local\Temp\claude\927f5331f6a7940b\8d4042f4-6e83-4cb6-9f64-0a1e0b9a2dae\scratchpad\dpx_only.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 27987 to 27990 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1920,1080) of 3840x2160; pointer parked at (3836,2156)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 27989, 27990)
- pzrestorewin.ps1: fullScreen=false height=2160 width=3840
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_dashpx.lua | dpx | PASS | 198 | zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_07_primani_keyon.png, zqa_dashpx_07_primani.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png, zqa_dashpx_14_rancher.png, zqa_dashpx_15_taxi_keyon.png, zqa_dashpx_15_taxi.png, zqa_dashpx_16_ambulance_keyon.png, zqa_dashpx_16_ambulance.png, zqa_dashpx_17_fire_keyon.png, zqa_dashpx_17_fire.png, zqa_dashpx_18_ranger_keyon.png, zqa_dashpx_18_ranger.png, zqa_dashpx_19_race_keyon.png, zqa_dashpx_19_race.png, zqa_dashpx_20_knoxvan_keyon.png, zqa_dashpx_20_knoxvan.png, zqa_dashpx_21_fossoild6_keyon.png, zqa_dashpx_21_fossoild6.png, zqa_dashpx_23_meadesheriff_keyon.png, zqa_dashpx_23_meadesheriff.png, zqa_dashpx_24_lcpd_keyon.png, zqa_dashpx_24_lcpd.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 27987 at 14:03:32

```text
[ZeD.QA] state #1 speed=1 paused=false player=928,13038 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre clock 1.73 -> 11.00 (daylight)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1022,0 888x840 rolled false pinned true/true
ZEDQA pre layout world 1930,0 888x840 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta17 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_dashpx.lua (`ZEDQA dpx`) - PASS, 198 s

- go 27988 at 14:03:37
- screenshots: zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_07_primani_keyon.png, zqa_dashpx_07_primani.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png, zqa_dashpx_14_rancher.png, zqa_dashpx_15_taxi_keyon.png, zqa_dashpx_15_taxi.png, zqa_dashpx_16_ambulance_keyon.png, zqa_dashpx_16_ambulance.png, zqa_dashpx_17_fire_keyon.png, zqa_dashpx_17_fire.png, zqa_dashpx_18_ranger_keyon.png, zqa_dashpx_18_ranger.png, zqa_dashpx_19_race_keyon.png, zqa_dashpx_19_race.png, zqa_dashpx_20_knoxvan_keyon.png, zqa_dashpx_20_knoxvan.png, zqa_dashpx_21_fossoild6_keyon.png, zqa_dashpx_21_fossoild6.png, zqa_dashpx_23_meadesheriff_keyon.png, zqa_dashpx_23_meadesheriff.png, zqa_dashpx_24_lcpd_keyon.png, zqa_dashpx_24_lcpd.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=928,13038 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA vp dpx player=928,13038 grid=19 chunks (152 tiles) loaded x 856-1008 y 12960-13112 sq=917,13030 dist=13.8 chunk=true inMap=true car=Base.CarLuxury at 917.0,13030.0 dist=13.8 vehicles=21
ZEDQA car dpx Base.CarLuxury spawned on spot 11 (917,13030)
ZEDQA dpx 01_luxury design=luxury rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=MERCIA LANG 4000 livery= make=MERCIA model=LANG 4000 unit=MERCIA - UNIT 64 hits=28 screen=3840x2160
ZEDQA dpx PASS 01_luxury: the character is in the car
ZEDQA dpx PASS 01_luxury: the key is in the ignition
ZEDQA dpx PASS 01_luxury: the engine is running
ZEDQA dpx PASS 01_luxury: the dash has a design (luxury)
ZEDQA dpx PASS 01_luxury: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA vp dpx player=915,13030 grid=19 chunks (152 tiles) loaded x 840-992 y 12952-13104 sq=910,13037 dist=9.0 chunk=true inMap=true car=Base.CarNormal at 910.0,13037.0 dist=9.0 vehicles=40
ZEDQA car dpx Base.CarNormal spawned on spot 12 (910,13037)
ZEDQA dpx 02_nyala design=nyala rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER NYALA livery= make=CHEVALIER model=NYALA unit=CHEVALIER - UNIT 64 hits=23 screen=3840x2160
ZEDQA dpx PASS 02_nyala: the character is in the car
ZEDQA dpx PASS 02_nyala: the key is in the ignition
ZEDQA dpx PASS 02_nyala: the engine is running
ZEDQA dpx PASS 02_nyala: the dash has a design (nyala)
ZEDQA dpx PASS 02_nyala: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 908,13036,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 832-984 y 12960-13112 sq=917,13024 dist=18.6 chunk=true inMap=true car=Base.SportsCar at 917.0,13024.0 dist=18.6 vehicles=44
ZEDQA car dpx Base.SportsCar spawned on spot 13 (917,13024)
ZEDQA dpx 03_cossette design=cossette rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER COSSETTE livery= make=CHEVALIER model=COSSETTE unit=CHEVALIER - UNIT 64 hits=23 screen=3840x2160
ZEDQA dpx PASS 03_cossette: the character is in the car
ZEDQA dpx PASS 03_cossette: the key is in the ignition
ZEDQA dpx PASS 03_cossette: the engine is running
ZEDQA dpx PASS 03_cossette: the dash has a design (cossette)
ZEDQA dpx PASS 03_cossette: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 915,13024,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 840-992 y 12952-13104 sq=917,13030 dist=13.5 chunk=true inMap=true car=Base.CarLightsKST at 917.0,13030.0 dist=13.5 vehicles=40
ZEDQA car dpx Base.CarLightsPolice spawned on spot 11 (917,13030)
ZEDQA dpx 04_police design=police rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=STATE TROOPER CHEVALIER NYALA livery=STATE TROOPER make=CHEVALIER model=NYALA unit=TROOPER - UNIT 64 hits=20 screen=3840x2160
ZEDQA dpx PASS 04_police: the character is in the car
ZEDQA dpx PASS 04_police: the key is in the ignition
ZEDQA dpx PASS 04_police: the engine is running
ZEDQA dpx PASS 04_police: the dash has a design (police)
ZEDQA dpx PASS 04_police: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA vp dpx player=916,13029 grid=19 chunks (152 tiles) loaded x 840-992 y 12952-13104 sq=910,13037 dist=9.6 chunk=true inMap=true car=Base.PickUpTruck at 910.0,13037.0 dist=9.6 vehicles=40
ZEDQA car dpx Base.PickUpTruck spawned on spot 12 (910,13037)
ZEDQA dpx 05_d6 design=d6 rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER D6 livery= make=CHEVALIER model=D6 unit=CHEVALIER - UNIT 64 hits=23 screen=3840x2160
ZEDQA dpx PASS 05_d6: the character is in the car
ZEDQA dpx PASS 05_d6: the key is in the ignition
ZEDQA dpx PASS 05_d6: the engine is running
ZEDQA dpx PASS 05_d6: the dash has a design (d6)
ZEDQA dpx PASS 05_d6: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 908,13036,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 832-984 y 12960-13112 sq=917,13024 dist=18.6 chunk=true inMap=true car=Base.ModernCar at 917.0,13024.0 dist=18.6 vehicles=44
ZEDQA car dpx Base.ModernCar spawned on spot 13 (917,13024)
ZEDQA dpx 06_dashelite design=dashelite rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=DASH ELITE livery= make=DASH model=ELITE unit=DASH - UNIT 64 hits=30 screen=3840x2160
ZEDQA dpx PASS 06_dashelite: the character is in the car
ZEDQA dpx PASS 06_dashelite: the key is in the ignition
ZEDQA dpx PASS 06_dashelite: the engine is running
ZEDQA dpx PASS 06_dashelite: the dash has a design (dashelite)
ZEDQA dpx PASS 06_dashelite: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 915,13023,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 840-992 y 12944-13096 sq=917,13030 dist=13.5 chunk=true inMap=true car=Base.ModernCar02 at 917.0,13030.0 dist=13.5 vehicles=37
ZEDQA car dpx Base.ModernCar02 spawned on spot 11 (917,13030)
ZEDQA dpx 07_primani design=primani rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=CHEVALIER PRIMANI livery= make=CHEVALIER model=PRIMANI unit=CHEVALIER - UNIT 64 hits=27 screen=3840x2160
ZEDQA dpx PASS 07_primani: the character is in the car
ZEDQA dpx PASS 07_primani: the key is in the ignition
ZEDQA dpx PASS 07_primani: the engine is running
ZEDQA dpx PASS 07_primani: the dash has a design (primani)
ZEDQA dpx PASS 07_primani: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA vp dpx player=915,13029 grid=19 chunks (152 tiles) loaded x 840-992 y 12952-13104 sq=910,13037 dist=9.4 chunk=true inMap=true car=Base.SmallCar at 910.0,13037.0 dist=9.4 vehicles=40
ZEDQA car dpx Base.SmallCar spawned on spot 12 (910,13037)
ZEDQA dpx 08_dart design=dart rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER DART livery= make=CHEVALIER model=DART unit=CHEVALIER - UNIT 64 hits=22 screen=3840x2160
ZEDQA dpx PASS 08_dart: the character is in the car
ZEDQA dpx PASS 08_dart: the key is in the ignition
ZEDQA dpx PASS 08_dart: the engine is running
ZEDQA dpx PASS 08_dart: the dash has a design (dart)
ZEDQA dpx PASS 08_dart: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 908,13036,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 832-984 y 12960-13112 sq=917,13024 dist=18.6 chunk=true inMap=true car=Base.SmallCar02 at 917.0,13024.0 dist=18.6 vehicles=44
ZEDQA car dpx Base.SmallCar02 spawned on spot 13 (917,13024)
ZEDQA dpx 09_horizon design=horizon rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=MASTERSON HORIZON livery= make=MASTERSON model=HORIZON unit=MASTERSON - UNIT 64 hits=22 screen=3840x2160
ZEDQA dpx PASS 09_horizon: the character is in the car
ZEDQA dpx PASS 09_horizon: the key is in the ignition
ZEDQA dpx PASS 09_horizon: the engine is running
ZEDQA dpx PASS 09_horizon: the dash has a design (horizon)
ZEDQA dpx PASS 09_horizon: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 915,13024,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 840-992 y 12952-13104 sq=917,13030 dist=13.5 chunk=true inMap=true car=Base.CarStationWagon at 917.0,13030.0 dist=13.5 vehicles=40
ZEDQA car dpx Base.CarStationWagon spawned on spot 11 (917,13030)
ZEDQA dpx 10_wagon design=wagon rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER CERISE WAGON livery= make=CHEVALIER model=CERISE WAGON unit=CHEVALIER - UNIT 64 hits=23 screen=3840x2160
ZEDQA dpx PASS 10_wagon: the character is in the car
ZEDQA dpx PASS 10_wagon: the key is in the ignition
ZEDQA dpx PASS 10_wagon: the engine is running
ZEDQA dpx PASS 10_wagon: the dash has a design (wagon)
ZEDQA dpx PASS 10_wagon: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA vp dpx player=915,13029 grid=19 chunks (152 tiles) loaded x 840-992 y 12952-13104 sq=910,13037 dist=9.3 chunk=true inMap=true car=Base.SUV at 910.0,13037.0 dist=9.3 vehicles=40
ZEDQA car dpx Base.SUV spawned on spot 12 (910,13037)
ZEDQA dpx 11_suv design=suv rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=FRANKLIN ALL-TERRAIN livery= make=FRANKLIN model=ALL-TERRAIN unit=FRANKLIN - UNIT 64 hits=23 screen=3840x2160
ZEDQA dpx PASS 11_suv: the character is in the car
ZEDQA dpx PASS 11_suv: the key is in the ignition
ZEDQA dpx PASS 11_suv: the engine is running
ZEDQA dpx PASS 11_suv: the dash has a design (suv)
ZEDQA dpx PASS 11_suv: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 908,13036,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 832-984 y 12960-13112 sq=917,13024 dist=18.6 chunk=true inMap=true car=Base.VanSpiffo at 917.0,13024.0 dist=18.6 vehicles=44
ZEDQA car dpx Base.VanSpiffo spawned on spot 13 (917,13024)
ZEDQA dpx 12_van design=van rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=SPIFFO VAN livery=SPIFFO VAN make=FRANKLIN model=VALULINE unit=SPIFFO - UNIT 64 hits=22 screen=3840x2160
ZEDQA dpx PASS 12_van: the character is in the car
ZEDQA dpx PASS 12_van: the key is in the ignition
ZEDQA dpx PASS 12_van: the engine is running
ZEDQA dpx PASS 12_van: the dash has a design (van)
ZEDQA dpx PASS 12_van: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 916,13022,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 840-992 y 12944-13096 sq=917,13030 dist=13.5 chunk=true inMap=true car=Base.PickUpVan at 917.0,13030.0 dist=13.5 vehicles=37
ZEDQA car dpx Base.PickUpVan spawned on spot 11 (917,13030)
ZEDQA dpx 13_bulldriver design=bulldriver rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=DASH BULLDRIVER livery= make=DASH model=BULLDRIVER unit=DASH - UNIT 64 hits=23 screen=3840x2160
ZEDQA dpx PASS 13_bulldriver: the character is in the car
ZEDQA dpx PASS 13_bulldriver: the key is in the ignition
ZEDQA dpx PASS 13_bulldriver: the engine is running
ZEDQA dpx PASS 13_bulldriver: the dash has a design (bulldriver)
ZEDQA dpx PASS 13_bulldriver: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA vp dpx player=915,13029 grid=19 chunks (152 tiles) loaded x 840-992 y 12952-13104 sq=910,13037 dist=9.4 chunk=true inMap=true car=Base.OffRoad at 910.0,13037.0 dist=9.4 vehicles=40
ZEDQA car dpx Base.OffRoad spawned on spot 12 (910,13037)
ZEDQA dpx 14_rancher design=rancher rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=DASH RANCHER livery= make=DASH model=RANCHER unit=DASH - UNIT 64 hits=22 screen=3840x2160
ZEDQA dpx PASS 14_rancher: the character is in the car
ZEDQA dpx PASS 14_rancher: the key is in the ignition
ZEDQA dpx PASS 14_rancher: the engine is running
ZEDQA dpx PASS 14_rancher: the dash has a design (rancher)
ZEDQA dpx PASS 14_rancher: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 908,13037,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 832-984 y 12960-13112 sq=917,13024 dist=18.6 chunk=true inMap=true car=Base.CarTaxi at 917.0,13024.0 dist=18.6 vehicles=44
ZEDQA car dpx Base.CarTaxi spawned on spot 13 (917,13024)
ZEDQA dpx 15_taxi design=taxi rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=TAXI livery=TAXI make=CHEVALIER model=NYALA unit=TAXI - CAB 64 hits=27 screen=3840x2160
ZEDQA dpx PASS 15_taxi: the character is in the car
ZEDQA dpx PASS 15_taxi: the key is in the ignition
ZEDQA dpx PASS 15_taxi: the engine is running
ZEDQA dpx PASS 15_taxi: the dash has a design (taxi)
ZEDQA dpx PASS 15_taxi: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 915,13023,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 840-992 y 12944-13096 sq=917,13030 dist=13.5 chunk=true inMap=true car=Base.VanAmbulance at 917.0,13030.0 dist=13.5 vehicles=37
ZEDQA car dpx Base.VanAmbulance spawned on spot 11 (917,13030)
ZEDQA dpx 16_ambulance design=ambulance rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=AMBULANCE livery=AMBULANCE make=FRANKLIN model=VALULINE unit=AMBULANCE - UNIT 64 hits=20 screen=3840x2160
ZEDQA dpx PASS 16_ambulance: the character is in the car
ZEDQA dpx PASS 16_ambulance: the key is in the ignition
ZEDQA dpx PASS 16_ambulance: the engine is running
ZEDQA dpx PASS 16_ambulance: the dash has a design (ambulance)
ZEDQA dpx PASS 16_ambulance: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA vp dpx player=915,13029 grid=19 chunks (152 tiles) loaded x 840-992 y 12952-13104 sq=910,13037 dist=9.5 chunk=true inMap=true car=Base.PickUpTruckLightsFire at 910.0,13037.0 dist=9.5 vehicles=40
ZEDQA car dpx Base.PickUpTruckLightsFire spawned on spot 12 (910,13037)
ZEDQA dpx 17_fire design=fire rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=FIRE DEPARTMENT CHEVALIER D6 livery=FIRE DEPARTMENT make=CHEVALIER model=D6 unit=FIRE - ENGINE 64 hits=20 screen=3840x2160
ZEDQA dpx PASS 17_fire: the character is in the car
ZEDQA dpx PASS 17_fire: the key is in the ignition
ZEDQA dpx PASS 17_fire: the engine is running
ZEDQA dpx PASS 17_fire: the dash has a design (fire)
ZEDQA dpx PASS 17_fire: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 908,13036,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 832-984 y 12960-13112 sq=917,13024 dist=18.6 chunk=true inMap=true car=Base.CarLightsRanger at 917.0,13024.0 dist=18.6 vehicles=44
ZEDQA car dpx Base.CarLightsRanger spawned on spot 13 (917,13024)
ZEDQA dpx 18_ranger design=ranger rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=RANGER CHEVALIER NYALA livery=RANGER make=CHEVALIER model=NYALA unit=RANGER - UNIT 64 hits=20 screen=3840x2160
ZEDQA dpx PASS 18_ranger: the character is in the car
ZEDQA dpx PASS 18_ranger: the key is in the ignition
ZEDQA dpx PASS 18_ranger: the engine is running
ZEDQA dpx PASS 18_ranger: the dash has a design (ranger)
ZEDQA dpx PASS 18_ranger: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 915,13023,0 to the drag strip
ERROR: General f:7571 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 840-992 y 12944-13096 sq=917,13030 dist=13.5 chunk=true inMap=true car=Base.RaceCar12 at 917.0,13030.0 dist=13.5 vehicles=37
ZEDQA car dpx Base.RaceCar12 spawned on spot 11 (917,13030)
ERROR: General f:7574 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dpx 19_race design=race rect=1120,1804,1600,356 k=2 running=true radio=false/nil heat=true lights=true name=RACE CAR livery=RACE CAR make=RACE model=CAR unit=RACE - UNIT 64 hits=5 screen=3840x2160
ZEDQA dpx PASS 19_race: the character is in the car
ZEDQA dpx PASS 19_race: the key is in the ignition
ZEDQA dpx PASS 19_race: the engine is running
ZEDQA dpx PASS 19_race: the dash has a design (race)
ZEDQA dpx PASS 19_race: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA vp dpx player=916,13029 grid=19 chunks (152 tiles) loaded x 840-992 y 12952-13104 sq=910,13037 dist=9.4 chunk=true inMap=true car=Base.Van_KnoxDisti at 910.0,13037.0 dist=9.4 vehicles=40
ZEDQA car dpx Base.Van_KnoxDisti spawned on spot 12 (910,13037)
ZEDQA dpx 20_knoxvan design=van rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=KNOX DISTILLERY FRANKLIN VALULINE livery=KNOX DISTILLERY make=FRANKLIN model=VALULINE unit=KNOX - UNIT 64 hits=26 screen=3840x2160
ZEDQA dpx PASS 20_knoxvan: the character is in the car
ZEDQA dpx PASS 20_knoxvan: the key is in the ignition
ZEDQA dpx PASS 20_knoxvan: the engine is running
ZEDQA dpx PASS 20_knoxvan: the dash has a design (van)
ZEDQA dpx PASS 20_knoxvan: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 908,13036,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 832-984 y 12960-13112 sq=917,13024 dist=18.6 chunk=true inMap=true car=Base.PickUpTruckLightsFossoil at 917.0,13024.0 dist=18.6 vehicles=44
ZEDQA car dpx Base.PickUpTruckLightsFossoil spawned on spot 13 (917,13024)
ZEDQA dpx 21_fossoild6 design=d6 rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=CHEVALIER D6 livery= make=CHEVALIER model=D6 unit=CHEVALIER - UNIT 64 hits=20 screen=3840x2160
ZEDQA dpx PASS 21_fossoild6: the character is in the car
ZEDQA dpx PASS 21_fossoild6: the key is in the ignition
ZEDQA dpx PASS 21_fossoild6: the engine is running
ZEDQA dpx PASS 21_fossoild6: the dash has a design (d6)
ZEDQA dpx PASS 21_fossoild6: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 915,13023,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 840-992 y 12944-13096 sq=917,13030 dist=13.5 chunk=true inMap=true car=Base.CarNormalSmashedFront at 917.0,13030.0 dist=13.5 vehicles=37
ZEDQA car dpx Base.CarNormalSmashedFront spawned on spot 11 (917,13030)
ZEDQA dpx 22_wreckednyala could not enter Base.CarNormalSmashedFront (enter=false seat0 installed=false)
ZEDQA car dpx took away a car an earlier spawn left behind
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=910,13037 dist=15.9 chunk=true inMap=true car=Base.ModernCarLightsMeadeSheriff at 910.0,13037.0 dist=15.9 vehicles=32
ZEDQA car dpx Base.ModernCarLightsMeadeSheriff spawned on spot 12 (910,13037)
ZEDQA dpx 23_meadesheriff design=police rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=MEADE SHERIFF DASH ELITE livery=MEADE SHERIFF make=DASH model=ELITE unit=SHERIFF - UNIT 64 hits=20 screen=3840x2160
ZEDQA dpx PASS 23_meadesheriff: the character is in the car
ZEDQA dpx PASS 23_meadesheriff: the key is in the ignition
ZEDQA dpx PASS 23_meadesheriff: the engine is running
ZEDQA dpx PASS 23_meadesheriff: the dash has a design (police)
ZEDQA dpx PASS 23_meadesheriff: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA home dpx moved from 908,13036,0 to the drag strip
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 832-984 y 12960-13112 sq=917,13024 dist=18.6 chunk=true inMap=true car=Base.CarLightsLouisvilleCounty at 917.0,13024.0 dist=18.6 vehicles=44
ZEDQA car dpx Base.CarLightsLouisvilleCounty spawned on spot 13 (917,13024)
ZEDQA dpx 24_lcpd design=police rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=LCPD CHEVALIER NYALA livery=LCPD make=CHEVALIER model=NYALA unit=LCPD - UNIT 64 hits=20 screen=3840x2160
ZEDQA dpx PASS 24_lcpd: the character is in the car
ZEDQA dpx PASS 24_lcpd: the key is in the ignition
ZEDQA dpx PASS 24_lcpd: the engine is running
ZEDQA dpx PASS 24_lcpd: the dash has a design (police)
ZEDQA dpx PASS 24_lcpd: the dash is drawn wholly on the screen (1120,1804 1600x356)
ZEDQA dpx 115 passed, 0 failed
ZEDQA dpx DONE
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
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
