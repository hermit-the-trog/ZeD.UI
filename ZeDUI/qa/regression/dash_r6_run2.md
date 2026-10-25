# ZeD-UI regression - 2026-10-24 23:48 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-24 23:48:05 |
| Finished | 2026-10-25 00:01:50 (13 min 44 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\AppData\Local\Temp\claude\C--Users-danie-Zomboid\d3e9a295-adeb-47b4-88d5-bd1f2dd63aba\scratchpad\m_keys.txt (2 scripts) |
| Result | **1/2 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 12396 to 12399 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 12398, 12399)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_dash_r6_keys.lua | r6k | WARN | 713 | zqa_r6k_site.png, zqa_r6_07_primani_run_k2.png, zqa_r6_07_primani_run_k1.png, zqa_r6_07_primani_tray_shut.png, zqa_r6_07_primani_tray_open.png, zqa_r6_07_primani_key_start.png | 54 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 12396 at 23:49:20

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre DONE
```

### 2. zedqa_dash_r6_keys.lua (`ZEDQA r6k`) - WARN, 713 s

- go 12397 at 23:49:26
- 54 ERR line(s)
- screenshots: zqa_r6k_site.png, zqa_r6_07_primani_run_k2.png, zqa_r6_07_primani_run_k1.png, zqa_r6_07_primani_tray_shut.png, zqa_r6_07_primani_tray_open.png, zqa_r6_07_primani_key_start.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ERROR: General f:635 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:643 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA r6k at the speedway 925,13040 (home 10985,11301)
ZEDQA r6k ERR 01_luxury car not settled at the seat step; not entered (square=true chunk=true physics=false dist=8.0 removed=false hold=nil)
ZEDQA r6k ERR 01_luxury engine never ran
ZEDQA r6k 01_luxury start key: nil@0 | engine:
ZEDQA r6k ERR 01_luxury start key went nil, want off on start on
ZEDQA r6k ERR 02_nyala car not settled at the seat step; not entered (square=true chunk=true physics=false dist=8.1 removed=false hold=nil)
ZEDQA r6k ERR 02_nyala engine never ran
ZEDQA r6k 02_nyala start key: nil@0 | engine:
ZEDQA r6k ERR 02_nyala start key went nil, want off on start on
ZEDQA r6k ERR 03_cossette car not settled at the seat step; not entered (square=true chunk=true physics=false dist=6.0 removed=false hold=nil)
ZEDQA r6k ERR 03_cossette engine never ran
ZEDQA r6k 03_cossette start key: nil@0 | engine:
ZEDQA r6k ERR 03_cossette start key went nil, want off on start on
ZEDQA r6k ERR 04_police car not settled at the seat step; not entered (square=true chunk=true physics=false dist=8.0 removed=false hold=nil)
ZEDQA r6k ERR 04_police engine never ran
ZEDQA r6k 04_police start key: nil@0 | engine:
ZEDQA r6k ERR 04_police start key went nil, want off on start on
ZEDQA r6k ERR 05_d6 car not settled at the seat step; not entered (square=true chunk=true physics=false dist=8.0 removed=false hold=nil)
ZEDQA r6k ERR 05_d6 engine never ran
ZEDQA r6k 05_d6 start key: nil@0 | engine:
ZEDQA r6k ERR 05_d6 start key went nil, want off on start on
ZEDQA r6k ERR 06_dashelite car not settled at the seat step; not entered (square=true chunk=true physics=false dist=8.5 removed=false hold=nil)
ZEDQA r6k ERR 06_dashelite engine never ran
ZEDQA r6k 06_dashelite start key: nil@0 | engine:
ZEDQA r6k ERR 06_dashelite start key went nil, want off on start on
ZEDQA r6k 07_primani staged design=primani script=Base.ModernCar02 keyPos=nil keyId=47399135 rect=1120,1804,1600,344 k=2
ZEDQA r6k 07_primani insert key: nil@0 off@11 | engine: Idle@11
ZEDQA r6k 07_primani start key: off@0 on@4 start@140 on@1527 | engine: Idle@4 StartingSuccess@24 Running+run@1527
ZEDQA r6k 07_primani start ON step 2 held 136 ms
ZEDQA r6k 07_primani run_k2 1120,1804,1600,344 k=2
ZEDQA r6k 07_primani run_k1 1520,1982,800,172 k=1
ZEDQA r6k 07_primani tray default open=true level=3 md=nil
ZEDQA r6k 07_primani tray click1 open=false level=0 md=false
ZEDQA r6k 07_primani tray click2 open=true level=3
ZEDQA r6k 07_primani shutoff key: on@0 off@154 | engine: Running+run@4 ShuttingDown@18
ZEDQA r6k 07_primani shutoff ON after the engine stopped 136 ms
ZEDQA r6k 07_primani dry start key: off@0 on@6 start@138 on@1556 off@1686 | engine: Idle@6 Starting@23 StartingFailed@41 Idle@1556
ZEDQA r6k 07_primani dry start ON step 2 held 132 ms
ZEDQA r6k 07_primani dry start ON step 4 held 130 ms
ZEDQA r6k 07_primani key out key: off@0 nil@10 | engine: Idle@10
ZEDQA r6k ERR 08_dart car not settled at the seat step; not entered (square=true chunk=true physics=false dist=5.5 removed=false hold=nil)
ZEDQA r6k ERR 08_dart engine never ran
ZEDQA r6k 08_dart start key: nil@0 | engine:
ZEDQA r6k ERR 08_dart start key went nil, want off on start on
ZEDQA r6k ERR 09_horizon car not settled at the seat step; not entered (square=true chunk=true physics=false dist=7.3 removed=false hold=nil)
ZEDQA r6k ERR 09_horizon engine never ran
ZEDQA r6k 09_horizon start key: nil@0 | engine:
ZEDQA r6k ERR 09_horizon start key went nil, want off on start on
ZEDQA r6k ERR 10_wagon car not settled at the seat step; not entered (square=true chunk=true physics=false dist=7.3 removed=false hold=nil)
ZEDQA r6k ERR 10_wagon engine never ran
ZEDQA r6k 10_wagon start key: nil@0 | engine:
ZEDQA r6k ERR 10_wagon start key went nil, want off on start on
ZEDQA r6k ERR 11_suv car not settled at the seat step; not entered (square=true chunk=true physics=false dist=5.5 removed=false hold=nil)
ZEDQA r6k ERR 11_suv engine never ran
ZEDQA r6k 11_suv start key: nil@0 | engine:
ZEDQA r6k ERR 11_suv start key went nil, want off on start on
ZEDQA r6k ERR 12_van car not settled at the seat step; not entered (square=true chunk=true physics=false dist=7.6 removed=false hold=nil)
ZEDQA r6k ERR 12_van engine never ran
ZEDQA r6k 12_van start key: nil@0 | engine:
ZEDQA r6k ERR 12_van start key went nil, want off on start on
ZEDQA r6k ERR 13_bulldriver car not settled at the seat step; not entered (square=true chunk=true physics=false dist=7.4 removed=false hold=nil)
ZEDQA r6k ERR 13_bulldriver engine never ran
ZEDQA r6k 13_bulldriver start key: nil@0 | engine:
ZEDQA r6k ERR 13_bulldriver start key went nil, want off on start on
ZEDQA r6k ERR 14_rancher car not settled at the seat step; not entered (square=true chunk=true physics=false dist=7.3 removed=false hold=nil)
ZEDQA r6k ERR 14_rancher engine never ran
ZEDQA r6k 14_rancher start key: nil@0 | engine:
ZEDQA r6k ERR 14_rancher start key went nil, want off on start on
ZEDQA r6k ERR 15_taxi car not settled at the seat step; not entered (square=true chunk=true physics=false dist=5.5 removed=false hold=nil)
ZEDQA r6k ERR 15_taxi engine never ran
ZEDQA r6k 15_taxi start key: nil@0 | engine:
ZEDQA r6k ERR 15_taxi start key went nil, want off on start on
ZEDQA r6k ERR 16_ambulance car not settled at the seat step; not entered (square=true chunk=true physics=false dist=7.6 removed=false hold=nil)
ZEDQA r6k ERR 16_ambulance engine never ran
ZEDQA r6k 16_ambulance start key: nil@0 | engine:
ZEDQA r6k ERR 16_ambulance start key went nil, want off on start on
ZEDQA r6k ERR 17_fire car not settled at the seat step; not entered (square=true chunk=true physics=false dist=7.3 removed=false hold=nil)
ZEDQA r6k ERR 17_fire engine never ran
ZEDQA r6k 17_fire start key: nil@0 | engine:
ZEDQA r6k ERR 17_fire start key went nil, want off on start on
ZEDQA r6k ERR 18_ranger car not settled at the seat step; not entered (square=true chunk=true physics=false dist=7.3 removed=false hold=nil)
ZEDQA r6k ERR 18_ranger engine never ran
ZEDQA r6k 18_ranger start key: nil@0 | engine:
ZEDQA r6k ERR 18_ranger start key went nil, want off on start on
ERROR: General f:77026 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:77209 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA r6k ERR 19_race car not settled at the seat step; not entered (square=true chunk=true physics=false dist=5.5 removed=false hold=nil)
ZEDQA r6k ERR 19_race engine never ran
ZEDQA r6k 19_race start key: nil@0 | engine:
ZEDQA r6k ERR 19_race start key went nil, want off on start on
ZEDQA r6k back home 10985,11301
ZEDQA r6k errors=54
ZEDQA r6k DONE
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
```
