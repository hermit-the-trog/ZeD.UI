# ZeD-UI regression - 2026-11-07 04:21 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-07 04:21:16 |
| Finished | 2026-11-07 04:27:02 (5 min 45 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta6a |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\dash_bulbs.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 22928 to 22932 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 22931, 22932)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 3 | zedqa_dash_keys_edge.lua | dke | PASS | 261 | zqa_dke_luxury_off.png, zqa_dke_luxury_start.png, zqa_dke_luxury_on.png, zqa_dke_nyala_off.png, zqa_dke_nyala_start.png, zqa_dke_nyala_on.png, zqa_dke_cossette_off.png, zqa_dke_cossette_start.png, zqa_dke_cossette_on.png, zqa_dke_police_off.png, zqa_dke_police_start.png, zqa_dke_police_on.png, zqa_dke_d6_off.png, zqa_dke_d6_start.png, zqa_dke_d6_on.png, zqa_dke_dashelite_off.png, zqa_dke_dashelite_start.png, zqa_dke_dashelite_on.png, zqa_dke_primani_off.png, zqa_dke_primani_start.png, zqa_dke_primani_on.png, zqa_dke_dart_off.png, zqa_dke_dart_start.png, zqa_dke_dart_on.png, zqa_dke_horizon_off.png, zqa_dke_horizon_start.png, zqa_dke_horizon_on.png, zqa_dke_wagon_off.png, zqa_dke_wagon_start.png, zqa_dke_wagon_on.png, zqa_dke_suv_off.png, zqa_dke_suv_start.png, zqa_dke_suv_on.png, zqa_dke_van_off.png, zqa_dke_van_start.png, zqa_dke_van_on.png, zqa_dke_bulldriver_off.png, zqa_dke_bulldriver_start.png, zqa_dke_bulldriver_on.png, zqa_dke_rancher_off.png, zqa_dke_rancher_start.png, zqa_dke_rancher_on.png, zqa_dke_taxi_off.png, zqa_dke_taxi_start.png, zqa_dke_taxi_on.png, zqa_dke_ambulance_off.png, zqa_dke_ambulance_start.png, zqa_dke_ambulance_on.png, zqa_dke_fire_off.png, zqa_dke_fire_start.png, zqa_dke_fire_on.png, zqa_dke_ranger_off.png, zqa_dke_ranger_start.png, zqa_dke_ranger_on.png, zqa_dke_race_off.png, zqa_dke_race_start.png, zqa_dke_race_on.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 22928 at 04:22:08

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 22929 at 04:22:14

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #2 ok=true
ZEDQA hcn DONE
```

### 3. zedqa_dash_keys_edge.lua (`ZEDQA dke`) - PASS, 261 s

- go 22930 at 04:22:18
- screenshots: zqa_dke_luxury_off.png, zqa_dke_luxury_start.png, zqa_dke_luxury_on.png, zqa_dke_nyala_off.png, zqa_dke_nyala_start.png, zqa_dke_nyala_on.png, zqa_dke_cossette_off.png, zqa_dke_cossette_start.png, zqa_dke_cossette_on.png, zqa_dke_police_off.png, zqa_dke_police_start.png, zqa_dke_police_on.png, zqa_dke_d6_off.png, zqa_dke_d6_start.png, zqa_dke_d6_on.png, zqa_dke_dashelite_off.png, zqa_dke_dashelite_start.png, zqa_dke_dashelite_on.png, zqa_dke_primani_off.png, zqa_dke_primani_start.png, zqa_dke_primani_on.png, zqa_dke_dart_off.png, zqa_dke_dart_start.png, zqa_dke_dart_on.png, zqa_dke_horizon_off.png, zqa_dke_horizon_start.png, zqa_dke_horizon_on.png, zqa_dke_wagon_off.png, zqa_dke_wagon_start.png, zqa_dke_wagon_on.png, zqa_dke_suv_off.png, zqa_dke_suv_start.png, zqa_dke_suv_on.png, zqa_dke_van_off.png, zqa_dke_van_start.png, zqa_dke_van_on.png, zqa_dke_bulldriver_off.png, zqa_dke_bulldriver_start.png, zqa_dke_bulldriver_on.png, zqa_dke_rancher_off.png, zqa_dke_rancher_start.png, zqa_dke_rancher_on.png, zqa_dke_taxi_off.png, zqa_dke_taxi_start.png, zqa_dke_taxi_on.png, zqa_dke_ambulance_off.png, zqa_dke_ambulance_start.png, zqa_dke_ambulance_on.png, zqa_dke_fire_off.png, zqa_dke_fire_start.png, zqa_dke_fire_on.png, zqa_dke_ranger_off.png, zqa_dke_ranger_start.png, zqa_dke_ranger_on.png, zqa_dke_race_off.png, zqa_dke_race_start.png, zqa_dke_race_on.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ZEDQA vp dke player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=930,13037 dist=5.8 chunk=true inMap=true car=Base.CarLuxury at 930.0,13037.0 dist=5.8 vehicles=35
ZEDQA dke shot luxury_off design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot luxury_start design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot luxury_on design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=928,13037 grid=19 chunks (152 tiles) loaded x 856-1008 y 12960-13112 sq=923,13039 dist=6.0 chunk=true inMap=true car=Base.CarNormal at 923.0,13039.0 dist=6.0 vehicles=24
ZEDQA dke shot nyala_off design=nyala rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot nyala_start design=nyala rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot nyala_on design=nyala rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=921,13038 grid=19 chunks (152 tiles) loaded x 848-1000 y 12960-13112 sq=923,13043 dist=4.2 chunk=true inMap=true car=Base.SportsCar at 923.0,13043.0 dist=4.2 vehicles=35
ZEDQA dke shot cossette_off design=cossette rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot cossette_start design=cossette rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot cossette_on design=cossette rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=922,13043 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=927,13045 dist=4.4 chunk=true inMap=true car=Base.CarLightsKST at 927.0,13045.0 dist=4.4 vehicles=35
ZEDQA dke shot police_off design=police rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot police_start design=police rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot police_on design=police rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=925,13044 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=930,13041 dist=5.5 chunk=true inMap=true car=Base.PickUpTruck at 930.0,13041.0 dist=5.5 vehicles=35
ZEDQA dke shot d6_off design=d6 rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot d6_start design=d6 rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot d6_on design=d6 rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=928,13040 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=923,13042 dist=6.2 chunk=true inMap=true car=Base.ModernCar at 923.0,13042.0 dist=6.2 vehicles=24
ZEDQA dke shot dashelite_off design=dashelite rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot dashelite_start design=dashelite rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot dashelite_on design=dashelite rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=922,13041 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=924,13046 dist=4.6 chunk=true inMap=true car=Base.ModernCar02 at 924.0,13046.0 dist=4.6 vehicles=35
ZEDQA dke shot primani_off design=primani rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot primani_start design=primani rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot primani_on design=primani rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=922,13045 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=927,13047 dist=4.3 chunk=true inMap=true car=Base.SmallCar at 927.0,13047.0 dist=4.3 vehicles=35
ZEDQA dke shot dart_off design=dart rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot dart_start design=dart rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot dart_on design=dart rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=925,13047 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=930,13044 dist=5.1 chunk=true inMap=true car=Base.SmallCar02 at 930.0,13044.0 dist=5.1 vehicles=35
ZEDQA dke shot horizon_off design=horizon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot horizon_start design=horizon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot horizon_on design=horizon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=928,13044 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=923,13046 dist=6.2 chunk=true inMap=true car=Base.CarStationWagon at 923.0,13046.0 dist=6.2 vehicles=24
ZEDQA dke shot wagon_off design=wagon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot wagon_start design=wagon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot wagon_on design=wagon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=922,13045 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=924,13050 dist=4.3 chunk=true inMap=true car=Base.SUV at 924.0,13050.0 dist=4.3 vehicles=35
ZEDQA dke shot suv_off design=suv rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot suv_start design=suv rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot suv_on design=suv rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=922,13049 grid=19 chunks (152 tiles) loaded x 848-1000 y 12976-13128 sq=927,13051 dist=4.4 chunk=true inMap=true car=Base.Van at 927.0,13051.0 dist=4.4 vehicles=35
ZEDQA dke shot van_off design=van rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot van_start design=van rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot van_on design=van rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=925,13050 grid=19 chunks (152 tiles) loaded x 848-1000 y 12976-13128 sq=930,13047 dist=5.3 chunk=true inMap=true car=Base.PickUpVan at 930.0,13047.0 dist=5.3 vehicles=35
ZEDQA dke shot bulldriver_off design=bulldriver rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot bulldriver_start design=bulldriver rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot bulldriver_on design=bulldriver rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=928,13046 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=923,13048 dist=6.0 chunk=true inMap=true car=Base.OffRoad at 923.0,13048.0 dist=6.0 vehicles=24
ZEDQA dke shot rancher_off design=rancher rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot rancher_start design=rancher rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot rancher_on design=rancher rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=921,13047 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=923,13052 dist=4.2 chunk=true inMap=true car=Base.CarTaxi at 923.0,13052.0 dist=4.2 vehicles=35
ZEDQA dke shot taxi_off design=taxi rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot taxi_start design=taxi rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot taxi_on design=taxi rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=921,13051 grid=19 chunks (152 tiles) loaded x 848-1000 y 12976-13128 sq=926,13053 dist=4.3 chunk=true inMap=true car=Base.VanAmbulance at 926.0,13053.0 dist=4.3 vehicles=35
ZEDQA dke shot ambulance_off design=ambulance rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot ambulance_start design=ambulance rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot ambulance_on design=ambulance rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=924,13052 grid=19 chunks (152 tiles) loaded x 848-1000 y 12976-13128 sq=929,13049 dist=5.3 chunk=true inMap=true car=Base.PickUpTruckLightsFire at 929.0,13049.0 dist=5.3 vehicles=35
ZEDQA dke shot fire_off design=fire rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot fire_start design=fire rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot fire_on design=fire rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=927,13048 grid=19 chunks (152 tiles) loaded x 848-1000 y 12976-13128 sq=922,13050 dist=6.0 chunk=true inMap=true car=Base.CarLightsRanger at 922.0,13050.0 dist=6.0 vehicles=35
ZEDQA dke shot ranger_off design=ranger rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot ranger_start design=ranger rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot ranger_on design=ranger rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ERROR: General f:16613 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA vp dke player=920,13049 grid=19 chunks (152 tiles) loaded x 848-1000 y 12976-13128 sq=922,13054 dist=4.2 chunk=true inMap=true car=Base.RaceCar12 at 922.0,13054.0 dist=4.2 vehicles=35
ERROR: General f:16967 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dke shot race_off design=race rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot race_start design=race rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot race_on design=race rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke PASS
ZEDQA dke DONE
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
