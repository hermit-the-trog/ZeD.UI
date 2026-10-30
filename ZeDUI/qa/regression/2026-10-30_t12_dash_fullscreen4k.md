# ZeD-UI regression - 2026-10-30 00:10 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-30 00:10:37 |
| Finished | 2026-10-30 00:19:36 (8 min 59 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/dash2.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 16275 to 16279 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 16278, 16279)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | zedqa_dash_keys_edge.lua | dke | PASS | 261 | zqa_dke_luxury_off.png, zqa_dke_luxury_start.png, zqa_dke_luxury_on.png, zqa_dke_nyala_off.png, zqa_dke_nyala_start.png, zqa_dke_nyala_on.png, zqa_dke_cossette_off.png, zqa_dke_cossette_start.png, zqa_dke_cossette_on.png, zqa_dke_police_off.png, zqa_dke_police_start.png, zqa_dke_police_on.png, zqa_dke_d6_off.png, zqa_dke_d6_start.png, zqa_dke_d6_on.png, zqa_dke_dashelite_off.png, zqa_dke_dashelite_start.png, zqa_dke_dashelite_on.png, zqa_dke_primani_off.png, zqa_dke_primani_start.png, zqa_dke_primani_on.png, zqa_dke_dart_off.png, zqa_dke_dart_start.png, zqa_dke_dart_on.png, zqa_dke_horizon_off.png, zqa_dke_horizon_start.png, zqa_dke_horizon_on.png, zqa_dke_wagon_off.png, zqa_dke_wagon_start.png, zqa_dke_wagon_on.png, zqa_dke_suv_off.png, zqa_dke_suv_start.png, zqa_dke_suv_on.png, zqa_dke_van_off.png, zqa_dke_van_start.png, zqa_dke_van_on.png, zqa_dke_bulldriver_off.png, zqa_dke_bulldriver_start.png, zqa_dke_bulldriver_on.png, zqa_dke_rancher_off.png, zqa_dke_rancher_start.png, zqa_dke_rancher_on.png, zqa_dke_taxi_off.png, zqa_dke_taxi_start.png, zqa_dke_taxi_on.png, zqa_dke_ambulance_off.png, zqa_dke_ambulance_start.png, zqa_dke_ambulance_on.png, zqa_dke_fire_off.png, zqa_dke_fire_start.png, zqa_dke_fire_on.png, zqa_dke_ranger_off.png, zqa_dke_ranger_start.png, zqa_dke_ranger_on.png, zqa_dke_race_off.png, zqa_dke_race_start.png, zqa_dke_race_on.png |  |
| 3 | zedqa_dash_brands.lua | dbr | PASS | 165 | zqa_dbr_luxury.png, zqa_dbr_nyala.png, zqa_dbr_cossette.png, zqa_dbr_d6.png, zqa_dbr_dashelite.png, zqa_dbr_primani.png, zqa_dbr_dart.png, zqa_dbr_horizon.png, zqa_dbr_wagon.png, zqa_dbr_suv.png, zqa_dbr_van.png, zqa_dbr_bulldriver.png, zqa_dbr_rancher.png, zqa_dbr_stepvan.png, zqa_dbr_modded.png, zqa_dbr_dashelite_night.png, zqa_dbr_cossette_night.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 16275 at 00:11:47

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 909,13015,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_dash_keys_edge.lua (`ZEDQA dke`) - PASS, 261 s

- go 16276 at 00:11:56
- screenshots: zqa_dke_luxury_off.png, zqa_dke_luxury_start.png, zqa_dke_luxury_on.png, zqa_dke_nyala_off.png, zqa_dke_nyala_start.png, zqa_dke_nyala_on.png, zqa_dke_cossette_off.png, zqa_dke_cossette_start.png, zqa_dke_cossette_on.png, zqa_dke_police_off.png, zqa_dke_police_start.png, zqa_dke_police_on.png, zqa_dke_d6_off.png, zqa_dke_d6_start.png, zqa_dke_d6_on.png, zqa_dke_dashelite_off.png, zqa_dke_dashelite_start.png, zqa_dke_dashelite_on.png, zqa_dke_primani_off.png, zqa_dke_primani_start.png, zqa_dke_primani_on.png, zqa_dke_dart_off.png, zqa_dke_dart_start.png, zqa_dke_dart_on.png, zqa_dke_horizon_off.png, zqa_dke_horizon_start.png, zqa_dke_horizon_on.png, zqa_dke_wagon_off.png, zqa_dke_wagon_start.png, zqa_dke_wagon_on.png, zqa_dke_suv_off.png, zqa_dke_suv_start.png, zqa_dke_suv_on.png, zqa_dke_van_off.png, zqa_dke_van_start.png, zqa_dke_van_on.png, zqa_dke_bulldriver_off.png, zqa_dke_bulldriver_start.png, zqa_dke_bulldriver_on.png, zqa_dke_rancher_off.png, zqa_dke_rancher_start.png, zqa_dke_rancher_on.png, zqa_dke_taxi_off.png, zqa_dke_taxi_start.png, zqa_dke_taxi_on.png, zqa_dke_ambulance_off.png, zqa_dke_ambulance_start.png, zqa_dke_ambulance_on.png, zqa_dke_fire_off.png, zqa_dke_fire_start.png, zqa_dke_fire_on.png, zqa_dke_ranger_off.png, zqa_dke_ranger_start.png, zqa_dke_ranger_on.png, zqa_dke_race_off.png, zqa_dke_race_start.png, zqa_dke_race_on.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA dke shot luxury_off design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot luxury_start design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot luxury_on design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot nyala_off design=nyala rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot nyala_start design=nyala rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot nyala_on design=nyala rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot cossette_off design=cossette rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot cossette_start design=cossette rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot cossette_on design=cossette rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot police_off design=police rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot police_start design=police rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot police_on design=police rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot d6_off design=d6 rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot d6_start design=d6 rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot d6_on design=d6 rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot dashelite_off design=dashelite rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot dashelite_start design=dashelite rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot dashelite_on design=dashelite rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot primani_off design=primani rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot primani_start design=primani rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot primani_on design=primani rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot dart_off design=dart rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot dart_start design=dart rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot dart_on design=dart rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot horizon_off design=horizon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot horizon_start design=horizon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot horizon_on design=horizon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot wagon_off design=wagon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot wagon_start design=wagon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot wagon_on design=wagon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot suv_off design=suv rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot suv_start design=suv rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot suv_on design=suv rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot van_off design=van rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot van_start design=van rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot van_on design=van rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot bulldriver_off design=bulldriver rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot bulldriver_start design=bulldriver rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot bulldriver_on design=bulldriver rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot rancher_off design=rancher rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot rancher_start design=rancher rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot rancher_on design=rancher rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot taxi_off design=taxi rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot taxi_start design=taxi rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot taxi_on design=taxi rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot ambulance_off design=ambulance rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot ambulance_start design=ambulance rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot ambulance_on design=ambulance rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot fire_off design=fire rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot fire_start design=fire rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot fire_on design=fire rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke shot ranger_off design=ranger rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot ranger_start design=ranger rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot ranger_on design=ranger rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ERROR: General f:20703 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:21065 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dke shot race_off design=race rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot race_start design=race rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot race_on design=race rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke PASS
ZEDQA dke DONE
```

### 3. zedqa_dash_brands.lua (`ZEDQA dbr`) - PASS, 165 s

- go 16277 at 00:16:20
- screenshots: zqa_dbr_luxury.png, zqa_dbr_nyala.png, zqa_dbr_cossette.png, zqa_dbr_d6.png, zqa_dbr_dashelite.png, zqa_dbr_primani.png, zqa_dbr_dart.png, zqa_dbr_horizon.png, zqa_dbr_wagon.png, zqa_dbr_suv.png, zqa_dbr_van.png, zqa_dbr_bulldriver.png, zqa_dbr_rancher.png, zqa_dbr_stepvan.png, zqa_dbr_modded.png, zqa_dbr_dashelite_night.png, zqa_dbr_cossette_night.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ZEDQA dbr shot luxury design=luxury brand=mercia make=MERCIA model=LANG 4000 tag= rect=1120,1804,1600,356 k=2 sprite=brand_mercia_luxury@610,33 71x22 tex=true line=model@635,46 w56 l
ZEDQA dbr shot nyala design=nyala brand=chevalier make=CHEVALIER model=NYALA tag= rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_nyala@603,31 84x22 tex=true line=model@627,44 w64 l
ZEDQA dbr shot cossette design=cossette brand=chevalier make=CHEVALIER model=COSSETTE tag=5.0 rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_cossette@603,31 83x22 tex=true line=model@627,44 w64 l
ZEDQA dbr shot d6 design=d6 brand=chevalier make=CHEVALIER model=D6 tag= rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_d6@603,31 84x22 tex=true line=model@627,44 w117 l
ZEDQA dbr shot dashelite design=dashelite brand=dash make=DASH model=ELITE tag=EFI rect=1120,1804,1600,356 k=2 sprite=brand_dash_dashelite@616,36 63x21 tex=true line=model@640,51 w39 l
ZEDQA dbr shot primani design=primani brand=chevalier make=CHEVALIER model=PRIMANI tag=EFI rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_primani@606,40 84x22 tex=true line=model@630,53 w61 l
ZEDQA dbr shot dart design=dart brand=chevalier make=CHEVALIER model=DART tag= rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_dart@603,30 84x22 tex=true line=model@627,43 w117 l
ZEDQA dbr shot horizon design=horizon brand=masterson make=MASTERSON model=HORIZON tag= rect=1120,1804,1600,356 k=2 sprite=brand_masterson_horizon@603,32 84x20 tex=true line=-
ZEDQA dbr shot wagon design=wagon brand=chevalier make=CHEVALIER model=CERISE WAGON tag= rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_wagon@602,33 85x21 tex=true line=-
ZEDQA dbr shot suv design=suv brand=franklin make=FRANKLIN model=ALL-TERRAIN tag=4X4 rect=1120,1804,1600,356 k=2 sprite=brand_franklin_suv@612,34 72x17 tex=true line=model@613,52 w70 c
ZEDQA dbr shot van design=van brand=franklin make=FRANKLIN model=VALULINE tag= rect=1120,1804,1600,356 k=2 sprite=brand_franklin_van@610,28 70x18 tex=true line=model@599,47 w92 c
ZEDQA dbr shot bulldriver design=bulldriver brand=dash make=DASH model=BULLDRIVER tag=V8 rect=1120,1804,1600,356 k=2 sprite=brand_dash_bulldriver@607,31 62x20 tex=true line=model@631,45 w113 l
ZEDQA dbr shot rancher design=rancher brand=dash make=DASH model=RANCHER tag=4X4 rect=1120,1804,1600,356 k=2 sprite=brand_dash_rancher@613,31 62x20 tex=true line=model@637,45 w109 l
ZEDQA dbr shot stepvan design=van brand=chevalier make=CHEVALIER model=STEP VAN tag= rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_van@603,30 84x22 tex=true line=model@627,43 w64 l
ZEDQA dbr shot modded design=nyala brand=plaque make=FORD model=BRONCO tag= rect=1120,1804,1600,356 k=2 sprite=brand_plaque_nyala@603,31 84x20 tex=true line=make@605,38 w80 c
ZEDQA dbr shot dashelite_night design=dashelite brand=dash make=DASH model=ELITE tag=EFI rect=1120,1804,1600,356 k=2 sprite=brand_dash_dashelite@616,36 63x21 tex=true line=model@640,51 w39 l
ZEDQA dbr shot cossette_night design=cossette brand=chevalier make=CHEVALIER model=COSSETTE tag=5.0 rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_cossette@603,31 83x22 tex=true line=model@627,44 w64 l
ZEDQA dbr PASS
ZEDQA dbr DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
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
