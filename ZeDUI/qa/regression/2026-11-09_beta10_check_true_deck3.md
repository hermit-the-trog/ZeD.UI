# ZeD-UI regression - 2026-11-09 10:07 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-09 10:07:37 |
| Finished | 2026-11-09 10:10:29 (2 min 52 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta10 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b10_stage_deck3.txt (3 scripts) |
| Result | **2/3 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 10000 to 10004 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 10003, 10004)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_staged_ver.lua | sv | PASS | 1 |  |  |
| 3 | zedqa_b9a_2.lua | b9a2 | WARN | 84 | zqa_b9a2_1280x800_1_floor_stack.png, zqa_b9a2_1280x800_2_in_inventory.png, zqa_b9a2_1280x800_3_on_floor.png, zqa_b9a2_1280x800_4_grid.png, zqa_b9a2_1280x800_5_open_stack.png, zqa_b9a2_1280x800_6_one_moved.png | 2 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 10000 at 10:08:32

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_staged_ver.lua (`ZEDQA sv`) - PASS, 1 s

- go 10001 at 10:08:37

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sv version=0.3.0-beta10 dir=C:\Users\danie\ZomboidStaged\mods\ZeD-UI
[ZeD.QA] run #2 ok=true
ZEDQA sv DONE
```

### 3. zedqa_b9a_2.lua (`ZEDQA b9a2`) - WARN, 84 s

- go 10002 at 10:08:41
- 2 ERR line(s)
- screenshots: zqa_b9a2_1280x800_1_floor_stack.png, zqa_b9a2_1280x800_2_in_inventory.png, zqa_b9a2_1280x800_3_on_floor.png, zqa_b9a2_1280x800_4_grid.png, zqa_b9a2_1280x800_5_open_stack.png, zqa_b9a2_1280x800_6_one_moved.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a2 screen 1280x800
ZEDQA b9a2 start
[ZeD.QA] run #3 ok=true
ZEDQA b9a2 nails held before: 11
ZEDQA b9a2 shot 1_floor_stack
ZEDQA b9a2 PASS World to Character: the row to drag is on screen
ZEDQA b9a2 FAIL World to Character: the row is held (the drag object is active)
ZEDQA b9a2 FAIL a closed stack dragged from the World list: all six nails moved (11 to 11)
ZEDQA b9a2 shot 2_in_inventory
ZEDQA b9a2 PASS Character to the floor: the row to drag is on screen
ZEDQA b9a2 PASS Character to the floor: the row is held (the drag object is active)
ZEDQA b9a2 PASS a closed stack dragged out over the world: all six dropped (11 to 0)
ZEDQA b9a2 shot 3_on_floor
ZEDQA b9a2 floor key type:floor
ZEDQA b9a2 shot 4_grid
ZEDQA b9a2 PASS grid cell to Character: the row to drag is on screen
ZEDQA b9a2 PASS grid cell to Character: the row is held (the drag object is active)
ZEDQA b9a2 PASS a grid cell (the grid opens no stacks): all six moved (0 to 17)
ZEDQA b9a2 the player's list: grid (player)
ZEDQA b9a2 the chevron click at 351,295: rolled nil, shaded false, list 330,20 279x278 shown true
ZEDQA b9a2 PASS the nails stack's chevron is on screen
ZEDQA b9a2 PASS the chevron opens the stack (a second nails row)
ZEDQA b9a2 shot 5_open_stack
ZEDQA b9a2 PASS one row of an open stack: the row to drag is on screen
ZEDQA b9a2 PASS one row of an open stack: the row is held (the drag object is active)
ZEDQA b9a2 PASS an open stack's row moves only its own nail (17 to 16)
ZEDQA b9a2 shot 6_one_moved
ZEDQA b9a2 RESULT 12 pass, 2 fail
ZEDQA b9a2 DONE
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
