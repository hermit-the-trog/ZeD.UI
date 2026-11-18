# ZeD-UI regression - 2026-11-18 07:25 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-18 07:25:12 |
| Finished | 2026-11-18 07:29:01 (3 min 49 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\gallery_v1_c2_street.txt (11 scripts) |
| Result | **11/11 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 29250 to 29262 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29261, 29262)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 4 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 5 | gallery_b10_glasses.lua | gls | PASS | 2 |  |  |
| 6 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 7 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 8 | gallery_v1_c2_common.lua | gv1c | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 9 | gallery_v1_c2_street.lua | gv1s | PASS | 99 | zqa_r6p_taxi_extras.png | late output from unl (85 line(s), not counted) |
| 10 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 11 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 29250 at 07:26:14

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta20 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 29251 at 07:26:19

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 29252 at 07:26:23

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #3 ok=true
ZEDQA g14l DONE
```

### 4. gallery_daylight.lua (`ZEDQA day`) - PASS, 2 s

- go 29253 at 07:26:28

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.51 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 29254 at 07:26:33

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls short sighted false, prescription glasses off
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 29255 at 07:26:38

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 29256 at 07:26:42

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 37.9 of 8 kg, 56 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 32 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 8.3 of 8 kg, 24 items, Heavy Load 0
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #7 ok=true
ZEDQA unl load 8.3 of 8 kg, 24 items, Heavy Load 0
ZEDQA unl DONE
ZEDQA unl load 8.3 of 8 kg, 24 items, Heavy Load 0   (x3)
```

### 8. gallery_v1_c2_common.lua (`ZEDQA gv1c`) - PASS, 1 s

- go 29257 at 07:26:47
- late output from unl (4 line(s), not counted)

```text
ZEDQA unl load 8.3 of 8 kg, 24 items, Heavy Load 0   (late output from unl)
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gv1c helpers ready | ZeD true | prelude car helpers true | load 8.3 of 8 kg, 24 items, Heavy Load 0
[ZeD.QA] run #8 ok=true
ZEDQA gv1c DONE
ZEDQA unl load 8.3 of 8 kg, 24 items, Heavy Load 0   (late output from unl)   (x3)
```

### 9. gallery_v1_c2_street.lua (`ZEDQA gv1s`) - PASS, 99 s

- go 29258 at 07:26:51
- late output from unl (85 line(s), not counted)
- screenshots: zqa_r6p_taxi_extras.png

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gv1s start (80 steps)
[ZeD.QA] run #9 ok=true
ZEDQA gv1s start at 925,13040,0 | 8.3 of 8 kg, 24 items, Heavy Load 0 | look dark teal
ZEDQA gv1s to West Point: the Fossoil's street
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gv1s West Point loaded round the store: true
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gv1s street spot 12075,7135 (blends_street_01_103)
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gv1s thermal: 7 worn things wet, 2 C, wind 0.6
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA gv1s shot zed_70_thermal_insulation
ZEDQA gv1s load zed_70_thermal_insulation: 8.3 of 18 kg, 24 items, Heavy Load 0
ZEDQA gv1s overflow zed_70_thermal_insulation: none
ZEDQA gv1s where zed_70_thermal_insulation: 12075,7135,0 the street in front of the Fossoil, West Point
ZEDQA gv1s box zed_70_thermal_insulation character 1760,776-2080,1196
ZEDQA gv1s box zed_70_thermal_insulation char 21,0-1638,735
ZEDQA gv1s box zed_70_thermal_insulation world 3042,0-3819,735
ZEDQA gv1s box zed_70_thermal_insulation belt 1535,2034-2197,2132
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gv1s shot zed_72_thermal_wetness
ZEDQA gv1s load zed_72_thermal_wetness: 8.3 of 18 kg, 24 items, Heavy Load 0
ZEDQA gv1s overflow zed_72_thermal_wetness: none
ZEDQA gv1s where zed_72_thermal_wetness: 12075,7135,0 the street in front of the Fossoil, West Point
ZEDQA gv1s box zed_72_thermal_wetness character 1760,776-2080,1196
ZEDQA gv1s box zed_72_thermal_wetness char 21,0-1638,735
ZEDQA gv1s box zed_72_thermal_wetness world 3042,0-3819,735
ZEDQA gv1s box zed_72_thermal_wetness belt 1535,2034-2197,2132
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gv1s shot zed_66_thermal_skin
ZEDQA gv1s load zed_66_thermal_skin: 8.3 of 18 kg, 24 items, Heavy Load 0
ZEDQA gv1s overflow zed_66_thermal_skin: none
ZEDQA gv1s where zed_66_thermal_skin: 12075,7135,0 the street in front of the Fossoil, West Point
ZEDQA gv1s box zed_66_thermal_skin character 1760,776-2080,1196
ZEDQA gv1s box zed_66_thermal_skin char 21,0-1638,735
ZEDQA gv1s box zed_66_thermal_skin world 3042,0-3819,735
ZEDQA gv1s box zed_66_thermal_skin belt 1535,2034-2197,2132
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)
ZEDQA gv1s thermal put back: wetness and weather
ZEDQA gv1s recipe open: Advanced_Forge
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)
ZEDQA gv1s shot zed_50_building
ZEDQA gv1s load zed_50_building: 8.3 of 18 kg, 24 items, Heavy Load 0
ZEDQA gv1s overflow zed_50_building: none
ZEDQA gv1s where zed_50_building: 12075,7135,0 the street in front of the Fossoil, West Point
ZEDQA gv1s box zed_50_building character 1760,776-2080,1196
ZEDQA gv1s box zed_50_building char 21,0-798,735
ZEDQA gv1s box zed_50_building world 2202,0-3819,735
ZEDQA gv1s box zed_50_building moodles 1896,1965-1944,2013
ZEDQA gv1s box zed_50_building belt 1535,2034-2197,2132
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)
ZEDQA gv1s forage: search mode true (was false) | finds listed 0 | More detail open
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x8)
ZEDQA gv1s forage: zone nil | radius 3 | icons 0 (0 active) | finds 0 by the search itself
ZEDQA gv1s note: search mode went off: on again
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x39)
ZEDQA gv1s forage: finds staged (4): the search gave none in time
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gv1s forage: searching false | finds: Scrap Metal, Old Newspaper, Pop Can, Tin Can
ZEDQA gv1s shot zed_51_forage
ZEDQA gv1s load zed_51_forage: 8.3 of 18 kg, 24 items, Heavy Load 0
ZEDQA gv1s overflow zed_51_forage: none
ZEDQA gv1s where zed_51_forage: 12103,7146,0 the street in front of the Fossoil, West Point
ZEDQA gv1s box zed_51_forage character 1760,776-2080,1196
ZEDQA gv1s box zed_51_forage char 21,0-798,735
ZEDQA gv1s box zed_51_forage world 2202,0-3819,735
ZEDQA gv1s box zed_51_forage moodles 1896,1965-1944,2013
ZEDQA gv1s box zed_51_forage belt 1535,2034-2197,2132
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)
ZEDQA gv1s forage put back: search mode false, the finds list as it was
ZEDQA gv1s furniture: the pointer's square 12103,7145 (isoToScreen named 12106,7144)
ZEDQA gv1s furniture: furniture_seating_outdoor_01_0 (Park Bench) placed at 12103,7145
ZEDQA gv1s note: step 57 waited 300 frames, went on
ZEDQA gv1s furniture: the tab reads nil at 12108,7147
ZEDQA gv1s not taken: zed_52_furniture (the tab read no piece under the pointer)
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)
ZEDQA gv1s furniture put back: the piece removed
ZEDQA gv1s taxi spot 12075,7135 (5 of 5 paved)
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)
ZEDQA gv1s taxi spawned at 12075,7135
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 8.3 of 18 kg, 25 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA gv1s taxi: running true, lights true, meter true, fare 1.5, extras 1
ZEDQA gv1s shot zqa_r6p_taxi_extras
ZEDQA gv1s load zqa_r6p_taxi_extras: 8.3 of 18 kg, 24 items, Heavy Load 0
ZEDQA gv1s overflow zqa_r6p_taxi_extras: none
ZEDQA gv1s where zqa_r6p_taxi_extras: 12073,7134,0 the street in front of the Fossoil, West Point
ZEDQA gv1s box zqa_r6p_taxi_extras character 1760,799-2080,1219
ZEDQA gv1s box zqa_r6p_taxi_extras char 21,0-798,735
ZEDQA gv1s box zqa_r6p_taxi_extras world 3042,0-3819,735
ZEDQA gv1s box zqa_r6p_taxi_extras moodles 1896,1735-1944,1783
ZEDQA gv1s box zqa_r6p_taxi_extras dash 1120,1804-2720,2160
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA layout gv1s put back
ZEDQA gv1s put back: 0 things given taken away, 0 light switches off, power and weather as they were, windows, place 925,13040
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)
ERROR: General f:10019 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA gv1s end: 6 shots, 1 not taken or failed
ZEDQA gv1s DONE
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x3)
```

### 10. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 29259 at 07:28:34

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.3 of 18 kg, 24 items, Heavy Load 0
ZEDQA rel put back 32 things; after: 37.9 of 18 kg, 56 items, Heavy Load 1 OVER
[ZeD.QA] run #10 ok=true
ZEDQA rel DONE
```

### 11. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 29260 at 07:28:38

```text
[ZeD.QA] state #11 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #11 ok=true
ZEDQA g14e DONE
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
