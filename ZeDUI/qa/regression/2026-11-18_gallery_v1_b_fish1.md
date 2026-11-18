# ZeD-UI regression - 2026-11-18 07:21 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-18 07:21:18 |
| Finished | 2026-11-18 07:25:11 (3 min 53 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\gallery_v1_b_fish.txt (12 scripts) |
| Result | **11/12 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 29236 to 29249 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29248, 29249)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 4 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 5 | gallery_b10_glasses.lua | gls | PASS | 1 |  |  |
| 6 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 7 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 8 | gallery_v1_b_lib.lua | g1lib | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 9 | gallery_v1_b_place.lua | g1pl | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 10 | gallery_v1_b_fish.lua | g1bf | WARN | 61 |  | 1 ERR line(s); late output from unl (68 line(s), not counted) |
| 11 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 12 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 29236 at 07:22:57

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

- go 29237 at 07:23:03

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 29238 at 07:23:07

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

- go 29239 at 07:23:11

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 14.21 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 1 s

- go 29240 at 07:23:16

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls short sighted false, prescription glasses off
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 29241 at 07:23:21

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 29242 at 07:23:25

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

### 8. gallery_v1_b_lib.lua (`ZEDQA g1lib`) - PASS, 1 s

- go 29243 at 07:23:29
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1lib GV1 defined (gallery_v1_b helpers)
[ZeD.QA] run #8 ok=true
ZEDQA g1lib DONE
ZEDQA unl load 8.3 of 8 kg, 24 items, Heavy Load 0   (late output from unl)   (x4)
```

### 9. gallery_v1_b_place.lua (`ZEDQA g1pl`) - PASS, 1 s

- go 29244 at 07:23:34
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1pl GV1P defined (the West Point kitchen)
[ZeD.QA] run #9 ok=true
ZEDQA g1pl DONE
ZEDQA unl load 8.3 of 8 kg, 24 items, Heavy Load 0   (late output from unl)   (x4)
```

### 10. gallery_v1_b_fish.lua (`ZEDQA g1bf`) - WARN, 61 s

- go 29245 at 07:23:38
- 1 ERR line(s)
- late output from unl (68 line(s), not counted)

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1bf start
[ZeD.QA] run #10 ok=true
ZEDQA g1bf hidden: ZeD_MessagesToasts, ZeD_MessagesToasts, ZeD_MessagesToasts, ZeD_MessagesToasts
ZEDQA g1bf trying West Point, north at 11700,6620
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x4)
ZEDQA g1bf found at 11716,6604 (West Point, north) facing N
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x16)
ZEDQA g1bf at the shore 11716,6604 (West Point, north) facing N, the target 11716.5,6599.5, fish in front 24
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 9.3 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1bf rod in hand true, manager None
ZEDQA unl load 9.3 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 10.0 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 9.3 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x4)
ZEDQA unl load 9.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf bait Base.Worm
ZEDQA g1bf the real pointer asked onto the water at 2240,875
ZEDQA unl load 9.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1bf the mouse helper answered (the game in front, the pointer on the water)
ZEDQA unl load 9.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf aim 1: 11716.5,6599.5 (target 11716.5,6599.5), on water true, aiming true, state None, player state IdleState
ZEDQA g1bf aim 3: 11716.5,6599.5 (target 11716.5,6599.5), on water true, aiming true, state None, player state IdleState
ZEDQA unl load 9.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf aim 6: 11716.5,6599.5 (target 11716.5,6599.5), on water true, aiming true, state None, player state IdleState
ZEDQA unl load 9.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf aim 9: 11716.5,6599.5 (target 11716.5,6599.5), on water true, aiming true, state None, player state IdleState
ZEDQA unl load 9.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf aim 12: 11716.5,6599.5 (target 11716.5,6599.5), on water true, aiming true, state None, player state IdleState
ZEDQA g1bf ERR the manager is not Idle (None): the cast may not go
ZEDQA unl load 9.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x20)
ZEDQA g1bf after the cast: state None (120 polls)
ZEDQA g1bf not taken: g1_59_fishing (the line did not go out (state None))
ZEDQA unl load 9.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x4)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA unl load 9.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf taken 0:
ZEDQA g1bf not taken 1: g1_59_fishing
ZEDQA g1bf put back: the line in, aiming off, the hands, rod and worms out (0 other new things out), the place
ZEDQA g1bf DONE
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)
ERROR: General f:10435 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA unl load 8.3 of 18 kg, 24 items, Heavy Load 0   (late output from unl)   (x3)
```

### 11. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 29246 at 07:24:42

```text
[ZeD.QA] state #11 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.3 of 18 kg, 24 items, Heavy Load 0
ZEDQA rel put back 32 things; after: 37.9 of 18 kg, 56 items, Heavy Load 1 OVER
[ZeD.QA] run #11 ok=true
ZEDQA rel DONE
```

### 12. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 29247 at 07:24:46

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
