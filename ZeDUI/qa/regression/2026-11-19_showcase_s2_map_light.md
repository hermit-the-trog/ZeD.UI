# ZeD-UI regression - 2026-11-19 13:38 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-19 13:38:23 |
| Finished | 2026-11-19 13:40:51 (2 min 27 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\showcase_s2_map_light.txt (12 scripts) |
| Result | **12/12 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 30345 to 30358 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 30357, 30358)
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
| 9 | showcase_s2_map_light.lua | s2l | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 10 | showcase_s2.lua | sc2 | PASS | 8 |  | late output from unl (11 line(s), not counted) |
| 11 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 12 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 30345 at 13:39:28

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
ZEDQA pre ZeD version=0.3.0-beta21 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 30346 at 13:39:34

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 30347 at 13:39:38

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

- go 30348 at 13:39:42

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.24 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 30349 at 13:39:47

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls short sighted false, prescription glasses off
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 30350 at 13:39:53

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 30351 at 13:39:57

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 26.6 of 8 kg, 55 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 39 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 8.7 of 8 kg, 16 items, Heavy Load 0
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #7 ok=true
ZEDQA unl load 8.7 of 8 kg, 16 items, Heavy Load 0
ZEDQA unl DONE
ZEDQA unl load 8.7 of 8 kg, 16 items, Heavy Load 0   (x3)
```

### 8. gallery_v1_c2_common.lua (`ZEDQA gv1c`) - PASS, 1 s

- go 30352 at 13:40:01
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gv1c helpers ready | ZeD true | prelude car helpers true | load 8.7 of 8 kg, 16 items, Heavy Load 0
[ZeD.QA] run #8 ok=true
ZEDQA gv1c DONE
ZEDQA unl load 8.7 of 8 kg, 16 items, Heavy Load 0   (late output from unl)   (x4)
```

### 9. showcase_s2_map_light.lua (`ZEDQA s2l`) - PASS, 1 s

- go 30353 at 13:40:06
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA s2l map only: the Fossoil 12060,7121, Light, zoom 15.75
[ZeD.QA] run #9 ok=true
ZEDQA s2l DONE
ZEDQA unl load 8.7 of 8 kg, 16 items, Heavy Load 0   (late output from unl)   (x4)
```

### 10. showcase_s2.lua (`ZEDQA sc2`) - PASS, 8 s

- go 30354 at 13:40:10
- late output from unl (11 line(s), not counted)

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sc2 start (16 steps)
[ZeD.QA] run #10 ok=true
ZEDQA sc2 start at 925,13040,0 | 8.7 of 8 kg, 16 items, Heavy Load 0 | look dark teal
ZEDQA sc2 at 931,13045 (the drag strip, east of the shed), noon; search mode was false; find type Base.MushroomGeneric1; options kept
ZEDQA unl load 8.7 of 18 kg, 16 items, Heavy Load 0   (late output from unl)
ZEDQA sc2 the map's ground revealed true
ZEDQA sc2 look for the map: light
ZEDQA sc2 the Maps tab open true
ZEDQA unl load 8.7 of 18 kg, 16 items, Heavy Load 0   (late output from unl)
ZEDQA sc2 World window widened for the map: 1617 to 2380
ZEDQA sc2 map style survey, on Irvington 12060,7121 at zoom 15.75
ZEDQA unl load 8.7 of 18 kg, 16 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA sc2 map on screen: panel 2916,197 840x1449
ZEDQA sc2 shot sc2_map_light
ZEDQA sc2 load sc2_map_light: 8.7 of 18 kg, 16 items, Heavy Load 0
ZEDQA sc2 overflow sc2_map_light: none
ZEDQA sc2 where sc2_map_light: 931,13045,0 nil
ZEDQA sc2 box sc2_map_light character 1760,776-2080,1196
ZEDQA sc2 box sc2_map_light char 21,21-798,1749
ZEDQA sc2 box sc2_map_light world 1899,21-3819,1749 COVERS the character
ZEDQA sc2 box sc2_map_light belt 1535,2034-2197,2132
ZEDQA unl load 8.7 of 18 kg, 16 items, Heavy Load 0   (late output from unl)
ZEDQA sc2 map put back: style survey, window heights, look dark
ZEDQA sc2 put back: finds, radio, watch given and taken away, options, stats, scratch, map style, car
ZEDQA layout sc2 put back
ZEDQA sc2 put back: 0 things given taken away, 0 light switches off, power and weather as they were, windows, place 925,13040
ZEDQA unl load 8.7 of 18 kg, 16 items, Heavy Load 0   (late output from unl)
ZEDQA sc2 end: 1 shots, 0 not taken or failed
ZEDQA sc2 DONE
ZEDQA unl load 8.7 of 18 kg, 16 items, Heavy Load 0   (late output from unl)   (x4)
```

### 11. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 30355 at 13:40:21

```text
[ZeD.QA] state #11 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.7 of 18 kg, 16 items, Heavy Load 0
ZEDQA rel put back 39 things; after: 26.6 of 18 kg, 55 items, Heavy Load 1 OVER
[ZeD.QA] run #11 ok=true
ZEDQA rel DONE
```

### 12. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 30356 at 13:40:26

```text
[ZeD.QA] state #12 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #12 ok=true
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
