# ZeD-UI regression - 2026-11-06 23:46 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-06 23:46:14 |
| Finished | 2026-11-06 23:48:04 (1 min 50 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta6a |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\release_check_staged.txt (4 scripts) |
| Result | **4/4 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 10000 to 10005 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam -cachedir=%USERPROFILE%\ZomboidStaged (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 10004, 10005)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_release_check.lua | rel | PASS | 17 | zqa_rel_4_card.png, zqa_rel_3_menu.png, zqa_rel_5_watch.png |  |
| 4 | zedqa_staged_ver.lua | sv | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 10000 at 23:47:11

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 10001 at 23:47:16

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_release_check.lua (`ZEDQA rel`) - PASS, 17 s

- go 10002 at 23:47:20
- screenshots: zqa_rel_4_card.png, zqa_rel_3_menu.png, zqa_rel_5_watch.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel start
[ZeD.QA] run #3 ok=true
ZEDQA rel PASS the windows start shut
ZEDQA rel PASS 1: both windows open
ZEDQA rel the test item: Base.Spiffo
ZEDQA rel PASS 2: the test item is in the Character window's list
ZEDQA rel PASS 2: the test item went to the floor (the game's transfer)
ZEDQA rel PASS 2: the World window lists it
ZEDQA rel PASS 2: it came back to the inventory
ZEDQA rel PASS 2: the Character window lists it again
ZEDQA rel PASS 4: the controller's focus is on the test item's row
ZEDQA rel 4: after A: charItemCard:hverb_1
ZEDQA rel PASS 4: A on the row opens its card, focus on its primary action (charItemCard:hverb_1)
ZEDQA rel 4: after B: invrow:22
ZEDQA rel PASS 4: B goes back to the row
ZEDQA rel PASS 3: the test item's row has a place on screen
ZEDQA rel PASS 3: the row is in the list's view (y 533 of 650)
ZEDQA rel 3: row invrow:22 at 0,533 350x53 in the window; the window at 1197,46
ZEDQA rel asked the helper for a right-click at 1257,605
ZEDQA rel PASS 3: the helper made the real right-click
ZEDQA rel 3: menu open true (ZeD_ContextMenu)
ZEDQA rel PASS 3: a real right-click on the row opens the item menu for that item (1 items)
ZEDQA rel PASS 5: the worn watch shows (belt true, corner true)
ZEDQA rel PASS 5: its face reads the game's time (16:45, the game 16:45)
ZEDQA rel RESULT PASS: all 16 checks
ZEDQA rel DONE
```

### 4. zedqa_staged_ver.lua (`ZEDQA sv`) - PASS, 1 s

- go 10003 at 23:47:41

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sv version=0.3.0-beta6a dir=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI
[ZeD.QA] run #4 ok=true
ZEDQA sv DONE
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
