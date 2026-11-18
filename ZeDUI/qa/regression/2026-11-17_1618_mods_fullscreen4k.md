# ZeD-UI regression - 2026-11-17 16:19 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 16:19:22 |
| Finished | 2026-11-17 16:21:37 (2 min 14 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\gallery_v1_b_setup.txt (10 scripts) |
| Result | **10/10 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 28425 to 28436 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28435, 28436)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 3 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 4 | gallery_b10_glasses.lua | gls | PASS | 2 |  |  |
| 5 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 6 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 7 | gallery_v1_b_lib.lua | g1lib | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 8 | gallery_v1_b_setup.lua | g1bs | PASS | 5 |  | late output from unl (9 line(s), not counted) |
| 9 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 10 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28425 at 16:20:26

```text
[ZeD.QA] state #1 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta19 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28426 at 16:20:31

```text
[ZeD.QA] state #2 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #2 ok=true
ZEDQA g14l DONE
```

### 3. gallery_daylight.lua (`ZEDQA day`) - PASS, 2 s

- go 28427 at 16:20:35

```text
[ZeD.QA] state #3 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 13.84 -> 11.00
[ZeD.QA] run #3 ok=true
ZEDQA day DONE
```

### 4. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 28428 at 16:20:41

```text
[ZeD.QA] state #4 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls wearing Base.Glasses_Prescription
[ZeD.QA] run #4 ok=true
ZEDQA gls DONE
```

### 5. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28429 at 16:20:46

```text
[ZeD.QA] state #5 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #5 ok=true
ZEDQA hcn DONE
```

### 6. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28430 at 16:20:50

```text
[ZeD.QA] state #6 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 8.3 of 8 kg, 58 items, Heavy Load 1
ZEDQA unl taken out of the inventory for the run: 1 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 8.1 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #6 ok=true
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1   (x3)
```

### 7. gallery_v1_b_lib.lua (`ZEDQA g1lib`) - PASS, 1 s

- go 28431 at 16:20:54
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #7 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1lib GV1 defined (gallery_v1_b helpers)
[ZeD.QA] run #7 ok=true
ZEDQA g1lib DONE
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1   (late output from unl)   (x4)
```

### 8. gallery_v1_b_setup.lua (`ZEDQA g1bs`) - PASS, 5 s

- go 28432 at 16:20:59
- late output from unl (9 line(s), not counted)

```text
[ZeD.QA] state #8 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1bs start
[ZeD.QA] run #8 ok=true
ZEDQA g1bs hidden: ZeD_MessagesToasts, ZeD_MessagesToasts, ZeD_MessagesToasts, ZeD_MessagesToasts
ZEDQA g1bs add-on groups on ZeD setup: none
ZEDQA g1bs ZeD Multi-Slot loaded: false
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1   (late output from unl)   (x2)
ZEDQA g1bs headers (page 5465.33203125 tall, window 1225 tall): Look @0 | Immersive or simple @621.9296875 | Additions @1003.9296875 | Windows @2086.89453125 | HUD @2580.89453125 | Controls @2794.89453125 | Quick actions (controller) @3324.859375 | Troubleshooting @4042.859375 | Game settings ZeD uses @4909.54296875
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA g1bs not taken: g1_05_setup_top (over the load limit: 8.1 of 8 kg, 57 items, Heavy Load 1)
ZEDQA g1bs not taken: g1_05_setup_multislot (no Multi-slot inventory group on ZeD setup (ZeD Multi-Slot not loaded))
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1   (late output from unl)
ZEDQA g1bs trouble: the Troubleshooting header at 4042.859375, scroll 4031.859375
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1   (late output from unl)
ZEDQA g1bs not taken: g1_05_setup_trouble (over the load limit: 8.1 of 8 kg, 57 items, Heavy Load 1)
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA g1bs taken 0:
ZEDQA g1bs not taken 3: g1_05_setup_top g1_05_setup_multislot g1_05_setup_trouble
ZEDQA g1bs put back: setup shut at the top, the pause screen shut (true)
ZEDQA g1bs DONE
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
```

### 9. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28433 at 16:21:07

```text
[ZeD.QA] state #9 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.1 of 20 kg, 57 items, Heavy Load 0
ZEDQA rel put back 1 things; after: 8.3 of 20 kg, 58 items, Heavy Load 0
[ZeD.QA] run #9 ok=true
ZEDQA rel DONE
```

### 10. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 28434 at 16:21:11

```text
[ZeD.QA] state #10 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #10 ok=true
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
