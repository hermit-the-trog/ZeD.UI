# ZeD-UI regression - 2026-11-17 18:28 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 18:28:25 |
| Finished | 2026-11-17 18:31:03 (2 min 38 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=6 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\gallery_v1_c1_van.txt (9 scripts) |
| Result | **9/9 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 28631 to 28641 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=6 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28640, 28641)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 2 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 3 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 4 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 5 | gallery_v1_c1_common.lua | c1c | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 6 | gallery_v1_c1_van.lua | c1v | PASS | 24 |  | late output from unl (28 line(s), not counted) |
| 7 | gallery_v1_c1_end.lua | c1e | PASS | 7 |  | late output from unl (10 line(s), not counted) |
| 8 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 9 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28631 at 18:29:35

```text
ZEDQA g14l desk menu bar: Debug left out false
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look nil nil nil | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #1 ok=true
ZEDQA g14l DONE
```

### 2. gallery_daylight.lua (`ZEDQA day`) - PASS, 2 s

- go 28632 at 18:29:39

```text
ZEDQA day time 12.39 -> 11.00
[ZeD.QA] run #2 ok=true
ZEDQA day DONE
```

### 3. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28633 at 18:29:45

```text
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #3 ok=true
ZEDQA hcn DONE
```

### 4. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28634 at 18:29:49

```text
ZEDQA unl before: 32.6 of 8 kg, 61 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 35 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #4 ok=true
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (x3)
```

### 5. gallery_v1_c1_common.lua (`ZEDQA c1c`) - PASS, 1 s

- go 28635 at 18:29:53
- late output from unl (4 line(s), not counted)

```text
ZEDQA c1c helpers ready | ZeD loaded false | start 12079,7138 | load 12.3 of 8 kg, 26 items, Heavy Load 1
[ZeD.QA] run #5 ok=true
ZEDQA c1c DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x4)
```

### 6. gallery_v1_c1_van.lua (`ZEDQA c1v`) - PASS, 24 s

- go 28636 at 18:29:58
- late output from unl (28 line(s), not counted)

```text
ZEDQA c1v start (25 steps)
[ZeD.QA] run #6 ok=true
ZEDQA c1v to kitchen: from 12080,7141
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x8)
ZEDQA c1v place kitchen: the kitchen of the house at 12021-12033,7078-7090 (West Point) | square 12029,7081 room kitchen floor floors_interior_tilesandwood_01_1 | 0 zombies within 30 squares taken out of the world
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)
ZEDQA c1v grid power here true
ZEDQA c1v glasses: put on true
ZEDQA c1v build line panels hidden: 1
ZEDQA unl load 12.4 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA c1v moved inventory from 640,0 to 24,0 (left side)
ZEDQA c1v moved loot from 1920,0 to 2536,0 (right side)
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1v shot van_20_ctx_menu at kitchen 12029,7081
ZEDQA c1v load van_20_ctx_menu: 12.6 of 18 kg, 28 items, Heavy Load 0
ZEDQA c1v box van_20_ctx_menu character 1760,776-2080,1196 (zoom 1)
ZEDQA c1v box van_20_ctx_menu SpeedControls 3641,82-3830,110
ZEDQA c1v box van_20_ctx_menu Clock 3674,10-3830,72
ZEDQA c1v box van_20_ctx_menu MoodlesUI 3782,120-3830,2280
ZEDQA c1v box van_20_ctx_menu ISInventoryPage 24,0-1304,720
ZEDQA c1v box van_20_ctx_menu ISInventoryPage 2536,0-3816,720
ZEDQA c1v box van_20_ctx_menu ISHotbar 1739,2078-2101,2160
ZEDQA c1v box van_20_ctx_menu ISContextMenu 561,216-979,466
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA c1v place living: the living room of the house at 12021-12033,7078-7090 (West Point) | square 12027,7080 room livingroom floor floors_interior_tilesandwood_01_50 | 0 zombies within 30 squares taken out of the world
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA c1v grid power here true
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA c1v zoom 0.5
ZEDQA unl load 12.6 of 16 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 13.6 of 16 kg, 29 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1v shot van_32_action_bar_reading at living 12027,7080
ZEDQA c1v load van_32_action_bar_reading: 13.6 of 16 kg, 29 items, Heavy Load 0
ZEDQA c1v box van_32_action_bar_reading character 1600,472-2240,1312 (zoom 0.5)
ZEDQA c1v box van_32_action_bar_reading ActionProgressBar 1904,928-1936,936 COVERS the character
ZEDQA c1v box van_32_action_bar_reading SpeedControls 3641,82-3830,110
ZEDQA c1v box van_32_action_bar_reading Clock 3674,10-3830,72
ZEDQA c1v box van_32_action_bar_reading MoodlesUI 3782,120-3830,2280
ZEDQA c1v box van_32_action_bar_reading ISHotbar 1739,2078-2101,2160
ZEDQA unl load 13.6 of 16 kg, 29 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA c1v zoom 1
ZEDQA c1v put back: the pages, the things given, the stats, the actions, the zoom, the build line, the glasses
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA c1v end: 2 shots, 0 not taken or failed
ZEDQA c1v DONE
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
```

### 7. gallery_v1_c1_end.lua (`ZEDQA c1e`) - PASS, 7 s

- go 28637 at 18:30:25
- late output from unl (10 line(s), not counted)

```text
ZEDQA c1e start (4 steps)
[ZeD.QA] run #7 ok=true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x6)
ZEDQA c1e put back: the place 12079,7138,0, the grid power, the cheats, the speed
ZEDQA c1e end: 0 shots, 0 not taken or failed
ZEDQA c1e DONE
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x4)
```

### 8. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28638 at 18:30:36

```text
ZEDQA rel before: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA rel put back 35 things; after: 32.6 of 18 kg, 61 items, Heavy Load 1 OVER
[ZeD.QA] run #8 ok=true
ZEDQA rel DONE
```

### 9. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 28639 at 18:30:40

```text
ZEDQA g14e put back: menus false, watermark true, column true, options false | look now nil nil
[ZeD.QA] run #9 ok=true
ZEDQA g14e DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    2x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
