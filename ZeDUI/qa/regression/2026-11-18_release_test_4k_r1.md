# ZeD-UI regression - 2026-11-18 11:43 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-18 11:43:49 |
| Finished | 2026-11-18 11:46:19 (2 min 30 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\release_test.txt (12 scripts) |
| Result | **1/12 pass**, 0 warn, 0 fail, 1 timeout, 10 not run |
| Go numbers | 29512 to 29515 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after rt_kit.lua: no DONE within 60 s; the script may still be running in the game
- quit: quit to the main menu, then to the desktop (go 29514, 29515)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | rt_kit.lua | rtk | **TIMEOUT** | 61 |  | no DONE within 60 s; the script may still be running in the game |
| 3 | rt_windows.lua | rt_win | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 4 | rt_inventory.lua | rt_inv | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 5 | rt_menus.lua | rt_menu | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 6 | rt_cards.lua | rt_cards | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 7 | rt_hud.lua | rt_hud | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 8 | rt_pad.lua | rt_pad | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 9 | rt_media.lua | rt_media | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 10 | rt_vehicles.lua | rt_veh | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 11 | rt_addon.lua | rt_addon | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |
| 12 | rt_system.lua | rt_sys | SKIP |  |  | not run: no DONE within 60 s; the script may still be running in the game |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 29512 at 11:44:51

```text
[ZeD.QA] state #1 speed=1 paused=false player=924,13037 grid=19 inCar=false vehicles=32 missing=get
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

### 2. rt_kit.lua (`ZEDQA rtk`) - TIMEOUT, 61 s

- go 29513 at 11:44:56
- no DONE within 60 s; the script may still be running in the game

```text
[ZeD.QA] state #2 speed=1 paused=false player=924,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtk kit ready: player 0, screen 3840x2160
ZEDQA rtk DONE
[ZeD.QA] run #2 ok=true
```

### 3. rt_windows.lua (`ZEDQA rt_win`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 4. rt_inventory.lua (`ZEDQA rt_inv`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 5. rt_menus.lua (`ZEDQA rt_menu`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 6. rt_cards.lua (`ZEDQA rt_cards`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 7. rt_hud.lua (`ZEDQA rt_hud`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 8. rt_pad.lua (`ZEDQA rt_pad`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 9. rt_media.lua (`ZEDQA rt_media`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 10. rt_vehicles.lua (`ZEDQA rt_veh`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 11. rt_addon.lua (`ZEDQA rt_addon`) - SKIP, not run

- not run: no DONE within 60 s; the script may still be running in the game

### 12. rt_system.lua (`ZEDQA rt_sys`) - SKIP, not run

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
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
