# ZeD-UI regression - 2026-11-17 17:16 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 17:16:11 |
| Finished | 2026-11-17 17:19:15 (3 min 4 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\gallery_v1_b_zed.txt (13 scripts) |
| Result | **6/13 pass**, 0 warn, 0 fail, 1 timeout, 6 not run |
| Go numbers | 28514 to 28522 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after gallery_unload.lua: no DONE within 60 s; the script may still be running in the game
- quit: quit to the main menu, then to the desktop (go 28521, 28522)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 6 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 4 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 5 | gallery_b10_glasses.lua | gls | PASS | 1 |  |  |
| 6 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 7 | gallery_unload.lua | unl | **TIMEOUT** | 61 |  | no DONE within 60 s; the script may still be running in the game |
| 8 | gallery_v1_b_lib.lua | g1lib | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 9 | gallery_v1_b_craft.lua | g1bc | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 10 | gallery_v1_b_fish.lua | g1bf | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 11 | gallery_v1_b_pad.lua | g1bp | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 12 | gallery_reload.lua | rel | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 13 | gallery_t14_end.lua | g14e | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 6 s

- go 28514 at 17:17:21

```text
[ZeD.QA] state #1 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 12073,7130,0 to the drag strip
ZEDQA pre clock 0.00 -> 11.00 (daylight)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ERROR: General f:327 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta19 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 28515 at 17:17:30

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28516 at 17:17:34

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

- go 28517 at 17:17:39

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.00 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 1 s

- go 28518 at 17:17:44

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls wearing Base.Glasses_Prescription
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28519 at 17:17:48

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_unload.lua (`ZEDQA unl`) - TIMEOUT, 61 s

- go 28520 at 17:17:52
- no DONE within 60 s; the script may still be running in the game

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 32.7 of 8 kg, 62 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 36 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #7 ok=true
```

### 8. gallery_v1_b_lib.lua (`ZEDQA g1lib`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 9. gallery_v1_b_craft.lua (`ZEDQA g1bc`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 10. gallery_v1_b_fish.lua (`ZEDQA g1bf`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 11. gallery_v1_b_pad.lua (`ZEDQA g1bp`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 12. gallery_reload.lua (`ZEDQA rel`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 13. gallery_t14_end.lua (`ZEDQA g14e`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

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
    1x ERROR: General f:N> MapItem.LoadWorldMap> Exception thrown  :: java.io.IOException: %USERPROFILE%\Zomboid\Saves\Sandbox\ZeD-QA\map_symbols.bin does not appear to be map_symbols.bin at MapItem.LoadWorldMap(MapItem.java:103).
```
