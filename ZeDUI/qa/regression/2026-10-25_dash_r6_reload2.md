# ZeD-UI regression - 2026-10-25 00:24 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-25 00:24:59 |
| Finished | 2026-10-25 00:31:18 (6 min 18 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/dash_r6_reload.txt (3 scripts) |
| Result | **2/3 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 12418 to 12422 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 12421, 12422)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_dash_r6_persist.lua | r6r | PASS | 14 | zqa_r6r_site.png, zqa_r6r_untouched.png, zqa_r6r_clicked.png |  |
| 3 | zedqa_dash_r6_parts.lua | r6p | WARN | 237 | zqa_r6p_site.png, zqa_r6p_van_spiffo.png, zqa_r6p_van_fossoil.png, zqa_r6p_van_mccoy.png, zqa_r6p_van_johnmccoy.png, zqa_r6p_van_mechanic.png, zqa_r6p_van_mail.png, zqa_r6p_van_plain.png, zqa_r6p_van_plain_open.png, zqa_r6p_van_creature.png, zqa_r6p_van_creature_shut.png, zqa_r6p_van_stepvan.png, zqa_r6p_van_stepvan_open.png, zqa_r6p_taxi_flag_up.png, zqa_r6p_taxi_flag_down.png, zqa_r6p_taxi_extras.png, zqa_r6p_taxi_waited.png, zqa_r6p_taxi_hula2_first.png, zqa_r6p_taxi_hula2.png, zqa_r6p_taxi_hula1_first.png, zqa_r6p_taxi_stopped.png, zqa_r6p_taxi_night_lit.png, zqa_r6p_taxi_night_dark.png, zqa_r6p_taxi_keyout.png, zqa_r6p_night_van_lit.png, zqa_r6p_night_van_dark.png, zqa_r6p_night_ambulance_lit.png, zqa_r6p_night_ambulance_dark.png | 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 12418 at 00:26:08

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre DONE
```

### 2. zedqa_dash_r6_persist.lua (`ZEDQA r6r`) - PASS, 14 s

- go 12419 at 00:26:12
- screenshots: zqa_r6r_site.png, zqa_r6r_untouched.png, zqa_r6r_clicked.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ERROR: General f:901 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:911 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA r6r at the speedway 925,13040 (home 10985,11301)
ZEDQA r6r untouched key=81630613 after reload: open=false level=0 md=nil (before: open=false level=0)
ZEDQA r6r clicked key=25304096 after reload: open=true level=3 md=true (before: open=true level=3)
ZEDQA r6r removed a leftover test car (speedway): Base.CarNormal key 55693800
ZEDQA r6r back home 10985,11301
ZEDQA r6r removed a leftover test car (home): Base.CarNormal key 13773838
ZEDQA r6r removed a leftover test car (home): Base.CarNormal key 32702477
ZEDQA r6r errors=0
ZEDQA r6r DONE
```

### 3. zedqa_dash_r6_parts.lua (`ZEDQA r6p`) - WARN, 237 s

- go 12420 at 00:26:30
- 1 ERR line(s)
- screenshots: zqa_r6p_site.png, zqa_r6p_van_spiffo.png, zqa_r6p_van_fossoil.png, zqa_r6p_van_mccoy.png, zqa_r6p_van_johnmccoy.png, zqa_r6p_van_mechanic.png, zqa_r6p_van_mail.png, zqa_r6p_van_plain.png, zqa_r6p_van_plain_open.png, zqa_r6p_van_creature.png, zqa_r6p_van_creature_shut.png, zqa_r6p_van_stepvan.png, zqa_r6p_van_stepvan_open.png, zqa_r6p_taxi_flag_up.png, zqa_r6p_taxi_flag_down.png, zqa_r6p_taxi_extras.png, zqa_r6p_taxi_waited.png, zqa_r6p_taxi_hula2_first.png, zqa_r6p_taxi_hula2.png, zqa_r6p_taxi_hula1_first.png, zqa_r6p_taxi_stopped.png, zqa_r6p_taxi_night_lit.png, zqa_r6p_taxi_night_dark.png, zqa_r6p_taxi_keyout.png, zqa_r6p_night_van_lit.png, zqa_r6p_night_van_dark.png, zqa_r6p_night_ambulance_lit.png, zqa_r6p_night_ambulance_dark.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ERROR: General f:2069 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:2116 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA r6p at the speedway 925,13040 (home 10985,11301)
ZEDQA r6p van_spiffo design=van vanRight=nil vanTray=false logo=media/textures/shirtdecals/Buisness_SpiffosDECAL.png ash=false/0
ZEDQA r6p van_fossoil design=van vanRight=nil vanTray=false logo=media/textures/shirtdecals/Buisness_FossoilDECAL.png ash=false/0
ZEDQA r6p van_mccoy design=van vanRight=nil vanTray=false logo=media/textures/shirtdecals/Buisness_McCoysDECAL.png ash=false/0
ZEDQA r6p van_johnmccoy design=van vanRight=nil vanTray=false logo=media/textures/shirtdecals/Buisness_McCoysDECAL.png ash=false/0
ZEDQA r6p van_mechanic design=van vanRight=nosmoke vanTray=false logo=none ash=false/0
ZEDQA r6p van_mail design=van vanRight=nosmoke vanTray=false logo=none ash=false/0
ZEDQA r6p van_plain design=van vanRight=ash vanTray=true logo=none ash=false/0
ZEDQA r6p van_plain tray clicked: open false -> true level=3
ZEDQA r6p van_creature design=van vanRight=ash vanTray=true logo=none ash=true/3
ZEDQA r6p van_creature tray clicked: open true -> false level=0
ZEDQA r6p van_stepvan design=van vanRight=ash vanTray=true logo=none ash=false/0
ZEDQA r6p van_stepvan tray clicked: open false -> true level=3
ZEDQA r6p taxi sandbox ZeD: true flag=1.5 fifth=0.25 minute=0.25 extra=0.5
ZEDQA r6p taxi key in, engine off: meter hit enabled=true meterOn=false
ZEDQA r6p taxi running: unit="TAXI - CAB 66" hula=0 meterOn=false fare=0.00 rect=1120,1804,1600,344 k=2
ZEDQA r6p taxi flag down: meterOn=true fare=1.50 extras=0.00 riders(real)=driver only
ZEDQA r6p taxi sandbox flag drop 2.00 -> fare 2.00
ZEDQA r6p taxi riders 2 -> extras 0.50
ZEDQA r6p taxi riders 3 -> extras 1.00
ZEDQA r6p taxi riders 1 -> extras 0.00
ZEDQA r6p taxi waiting from fare 1.50
ZEDQA r6p taxi waited 30 s: fare 1.50
ZEDQA r6p taxi waited 61 s: fare 1.75
ZEDQA r6p taxi QA seed: the meter's distance set to 0.19 mi, fare 1.75
ZEDQA r6p taxi drive left t=1 push=100 fwd=-0.07,0.01,-1.00 kmh=0.1 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=64s heading=nil
ZEDQA r6p taxi drive left t=2 push=200 fwd=-0.07,0.01,-1.00 kmh=0.1 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=65s heading=nil
ZEDQA r6p taxi drive left t=3 push=400 fwd=-0.07,0.01,-1.00 kmh=0.1 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=66s heading=nil
ZEDQA r6p taxi drive left t=4 push=800 fwd=-0.07,0.01,-1.00 kmh=0.1 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=67s heading=nil
ZEDQA r6p taxi drive left t=5 push=1600 fwd=-0.07,0.01,-1.00 kmh=0.1 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=68s heading=nil
ZEDQA r6p taxi drive left t=6 push=3200 fwd=-0.07,0.01,-1.00 kmh=0.0 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=69s heading=nil
ZEDQA r6p taxi drive left t=7 push=6400 fwd=-0.07,0.00,-1.00 kmh=0.8 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=70s heading=-1.7359450042095235
ZEDQA r6p taxi drive left t=8 push=6400 fwd=-0.07,0.00,-1.00 kmh=5.0 yaw=-1.20 hula=2 fare=1.75 miles=0.190 wait=71s heading=-1.7359450042095235
ZEDQA r6p taxi drive left t=9 push=12800 fwd=-0.07,0.00,-1.00 kmh=4.4 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=71s heading=-1.633215136790854
ZEDQA r6p taxi drive left t=11 push=12800 fwd=-0.07,0.01,-1.00 kmh=20.3 yaw=0.01 hula=2 fare=1.75 miles=0.193 wait=71s heading=-1.633215136790854
ZEDQA r6p taxi drive left t=12 push=12800 fwd=-0.10,0.00,-0.99 kmh=26.0 yaw=-0.07 hula=0 fare=1.75 miles=0.197 wait=71s heading=-1.6814535479687924
ZEDQA r6p taxi drive left t=13 push=25600 fwd=-0.20,0.05,-0.98 kmh=0.3 yaw=0.00 hula=0 fare=1.75 miles=0.200 wait=71s heading=-1.4056476493802699
ZEDQA r6p taxi drive left t=14 push=50000 fwd=-0.28,0.06,-0.96 kmh=0.4 yaw=0.00 hula=0 fare=1.75 miles=0.200 wait=72s heading=-0.7853981633974483
ZEDQA r6p taxi drive left t=15 push=50000 fwd=-0.47,0.06,-0.88 kmh=1.1 yaw=0.00 hula=0 fare=1.75 miles=0.200 wait=73s heading=-0.7853981633974483
ZEDQA r6p taxi drive left t=16 push=50000 fwd=-0.57,0.07,-0.82 kmh=0.4 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=74s heading=-0.7853981633974483
ZEDQA r6p taxi drive left t=17 push=50000 fwd=-0.62,0.07,-0.78 kmh=0.4 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=75s heading=-0.7853981633974483
ZEDQA r6p taxi drive left t=18 push=50000 fwd=-0.66,0.07,-0.75 kmh=0.2 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=76s heading=-0.7853981633974483
ZEDQA r6p taxi drive left t=19 push=50000 fwd=-0.69,0.07,-0.72 kmh=0.4 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=77s heading=-0.7853981633974483
ZEDQA r6p taxi drive left t=20 push=50000 fwd=-0.71,0.07,-0.70 kmh=0.3 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=78s heading=-0.7853981633974483
ZEDQA r6p taxi drive left t=21 push=50000 fwd=-0.74,0.07,-0.67 kmh=0.2 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=79s heading=-0.982793723247329
ZEDQA r6p taxi drive left t=22 push=50000 fwd=-0.76,0.07,-0.65 kmh=0.2 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=80s heading=-0.7853981633974483
ZEDQA r6p taxi drive left t=23 push=50000 fwd=-0.77,0.07,-0.63 kmh=0.2 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=81s heading=nil
ZEDQA r6p taxi drive left t=24 push=50000 fwd=-0.79,0.07,-0.61 kmh=0.2 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=82s heading=nil
ZEDQA r6p taxi drive right t=1 push=50000 fwd=-0.80,0.07,-0.59 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=83s heading=nil
ZEDQA r6p taxi drive right t=2 push=50000 fwd=-0.81,0.07,-0.58 kmh=0.2 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=84s heading=nil
ZEDQA r6p taxi drive right t=3 push=50000 fwd=-0.82,0.07,-0.56 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=85s heading=nil
ZEDQA r6p taxi drive right t=4 push=50000 fwd=-0.83,0.07,-0.55 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=86s heading=nil
ZEDQA r6p taxi drive right t=5 push=50000 fwd=-0.84,0.07,-0.53 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.200 wait=87s heading=nil
ZEDQA r6p taxi drive right t=6 push=50000 fwd=-0.85,0.07,-0.52 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=88s heading=nil
ZEDQA r6p taxi drive right t=7 push=50000 fwd=-0.86,0.07,-0.51 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=89s heading=nil
ZEDQA r6p taxi drive right t=8 push=50000 fwd=-0.86,0.07,-0.50 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=90s heading=nil
ZEDQA r6p taxi drive right t=9 push=50000 fwd=-0.87,0.07,-0.49 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=91s heading=nil
ZEDQA r6p taxi drive right t=10 push=50000 fwd=-0.88,0.07,-0.48 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=92s heading=nil
ZEDQA r6p taxi drive right t=11 push=50000 fwd=-0.88,0.07,-0.47 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=93s heading=nil
ZEDQA r6p taxi drive right t=12 push=50000 fwd=-0.89,0.07,-0.46 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=94s heading=nil
ZEDQA r6p taxi drive right t=13 push=50000 fwd=-0.89,0.07,-0.45 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=95s heading=nil
ZEDQA r6p taxi drive right t=14 push=50000 fwd=-0.89,0.07,-0.44 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=96s heading=nil
ZEDQA r6p taxi drive right t=15 push=50000 fwd=-0.90,0.07,-0.43 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=97s heading=nil
ZEDQA r6p taxi drive right t=16 push=50000 fwd=-0.90,0.07,-0.43 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=98s heading=nil
ZEDQA r6p taxi drive right t=17 push=50000 fwd=-0.91,0.07,-0.42 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=100s heading=nil
ZEDQA r6p taxi drive right t=18 push=50000 fwd=-0.91,0.07,-0.41 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=101s heading=nil
ZEDQA r6p taxi drive right t=19 push=50000 fwd=-0.91,0.07,-0.41 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=102s heading=nil
ZEDQA r6p taxi drive right t=20 push=50000 fwd=-0.91,0.07,-0.40 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=103s heading=nil
ZEDQA r6p taxi drive right t=21 push=50000 fwd=-0.92,0.07,-0.39 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=104s heading=nil
ZEDQA r6p taxi drive right t=22 push=50000 fwd=-0.92,0.07,-0.39 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=105s heading=nil
ZEDQA r6p taxi drive right t=23 push=50000 fwd=-0.92,0.07,-0.38 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=106s heading=nil
ZEDQA r6p taxi drive right t=24 push=50000 fwd=-0.92,0.07,-0.38 kmh=0.1 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=107s heading=nil
ZEDQA r6p taxi drive brake t=1 push=50000 fwd=-0.93,0.07,-0.37 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=108s heading=nil
ZEDQA r6p taxi drive brake t=2 push=50000 fwd=-0.93,0.07,-0.37 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=109s heading=nil
ZEDQA r6p taxi drive brake t=3 push=50000 fwd=-0.93,0.07,-0.37 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=110s heading=nil
ZEDQA r6p taxi drive brake t=4 push=50000 fwd=-0.93,0.07,-0.37 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=111s heading=nil
ZEDQA r6p taxi drive brake t=5 push=50000 fwd=-0.93,0.07,-0.37 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.201 wait=112s heading=nil
ZEDQA r6p taxi drove: max 26.2 km/h, hula frames 0,2,0,2,0,2,1,2,0,2,0,1,0,2,1,2,0, fare 1.75 -> 2.00, fifths 0.190 -> 0.201 mi
ZEDQA r6p ERR taxi hula did not sway both ways (1=false 2=true)
ZEDQA r6p taxi PASS the first fifth of a mile clicked: fare 1.75 -> 2.00
ZEDQA r6p taxi stopped: hula=0
ZEDQA r6p taxi key out: keysIn=false meterOn=false fare=0.00 extras=0.00
ZEDQA r6p keep: skipped (the reload check ran in this game)
ZEDQA r6p back home 10985,11301
ZEDQA r6p errors=1
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
```
