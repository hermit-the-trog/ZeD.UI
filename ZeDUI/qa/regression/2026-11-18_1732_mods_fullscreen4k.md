# ZeD-UI regression - 2026-11-18 17:33 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-18 17:33:25 |
| Finished | 2026-11-18 17:35:55 (2 min 30 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=6 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\gallery_v1_b_van.txt (10 scripts) |
| Result | **10/10 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 29955 to 29966 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=6 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29965, 29966)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 2 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 3 | gallery_b10_glasses.lua | gls | PASS | 1 |  |  |
| 4 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 5 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 6 | gallery_v1_b_lib.lua | g1lib | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 7 | gallery_v1_b_place.lua | g1pl | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 8 | gallery_v1_b_van.lua | g1bv | PASS | 16 |  | late output from unl (20 line(s), not counted) |
| 9 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 10 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 29955 at 17:34:37

```text
ZEDQA g14l desk menu bar: Debug left out false
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look nil nil nil | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #1 ok=true
ZEDQA g14l DONE
```

### 2. gallery_daylight.lua (`ZEDQA day`) - PASS, 2 s

- go 29956 at 17:34:42

```text
ZEDQA day time 11.30 -> 11.00
[ZeD.QA] run #2 ok=true
ZEDQA day DONE
```

### 3. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 1 s

- go 29957 at 17:34:47

```text
ZEDQA gls short sighted false, prescription glasses off
[ZeD.QA] run #3 ok=true
ZEDQA gls DONE
```

### 4. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 29958 at 17:34:51

```text
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #4 ok=true
ZEDQA hcn DONE
```

### 5. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 29959 at 17:34:55

```text
ZEDQA unl before: 26.6 of 8 kg, 55 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 28 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 9.6 of 8 kg, 27 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #5 ok=true
ZEDQA unl load 9.6 of 8 kg, 27 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 9.6 of 8 kg, 27 items, Heavy Load 1   (x3)
```

### 6. gallery_v1_b_lib.lua (`ZEDQA g1lib`) - PASS, 1 s

- go 29960 at 17:35:00
- late output from unl (4 line(s), not counted)

```text
ZEDQA g1lib GV1 defined (gallery_v1_b helpers)
[ZeD.QA] run #6 ok=true
ZEDQA g1lib DONE
ZEDQA unl load 9.6 of 8 kg, 27 items, Heavy Load 1   (late output from unl)   (x4)
```

### 7. gallery_v1_b_place.lua (`ZEDQA g1pl`) - PASS, 1 s

- go 29961 at 17:35:04
- late output from unl (4 line(s), not counted)

```text
ZEDQA g1pl GV1P defined (the West Point kitchen)
[ZeD.QA] run #7 ok=true
ZEDQA g1pl DONE
ZEDQA unl load 9.6 of 8 kg, 27 items, Heavy Load 1   (late output from unl)   (x4)
```

### 8. gallery_v1_b_van.lua (`ZEDQA g1bv`) - PASS, 16 s

- go 29962 at 17:35:08
- late output from unl (20 line(s), not counted)

```text
ZEDQA g1bv start
[ZeD.QA] run #8 ok=true
ZEDQA unl load 9.6 of 8 kg, 27 items, Heavy Load 1   (late output from unl)
ZEDQA g1bv recipe MakeMolotovCocktail
ZEDQA g1bv short sighted false, prescription glasses off (took off 0)
ZEDQA g1bv short sighted false, prescription glasses off
ZEDQA g1bv build line hidden true
ZEDQA g1bv fluid holders taken out for the run: 0
ZEDQA unl load 11.2 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA g1bv to the West Point kitchen (12029,7080)
ZEDQA unl load 11.2 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x8)
ZEDQA g1bv place: the kitchen of the house at 12021-12033,7078-7090 (West Point), square 12028,7081 room kitchen | 0 zombies within 30 squares taken out | grid power on true
ZEDQA unl load 11.2 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1bv isDebugEnabled for the window: false
ZEDQA unl load 11.2 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1bv the window at the game's place: 0,0 1794x950
ZEDQA g1bv selected recipe MakeMolotovCocktail, can make false
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA g1bv short sighted false, prescription glasses off (took off 0)
ZEDQA g1bv short sighted false, prescription glasses off
ZEDQA g1bv debug lines cut from the title: 0
ZEDQA g1bv short sighted false, prescription glasses off (took off 0)
ZEDQA g1bv shot g1_46_craft_van | load 11.2 of 18 kg, 29 items, Heavy Load 0
ZEDQA g1bv boxes ISHandcraftWindow@0,0 1794x950
ZEDQA g1bv character at 1920,1136 clear
ZEDQA unl load 11.2 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA g1bv isDebugEnabled for the window: true   (x2)
ZEDQA g1bv the grid power put back
ZEDQA g1bv fluid holders put back: 0
ZEDQA g1bv taken 1: g1_46_craft_van
ZEDQA g1bv not taken 0:
ZEDQA g1bv put back: the window shut at its own place, given things out, fluid holders back, the place
ZEDQA g1bv DONE
ZEDQA unl load 9.6 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ERROR: General f:5311 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA unl load 9.6 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x3)
```

### 9. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 29963 at 17:35:28

```text
ZEDQA rel before: 9.6 of 18 kg, 27 items, Heavy Load 0
ZEDQA rel put back 28 things; after: 26.6 of 18 kg, 55 items, Heavy Load 1 OVER
[ZeD.QA] run #9 ok=true
ZEDQA rel DONE
```

### 10. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 29964 at 17:35:32

```text
ZEDQA g14e put back: menus false, watermark true, column true, options false | look now nil nil
[ZeD.QA] run #10 ok=true
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
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
