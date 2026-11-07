# ZeD-UI regression - 2026-11-06 20:38 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-06 20:38:51 |
| Finished | 2026-11-06 20:40:44 (1 min 52 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\animals_clip.txt (4 scripts) |
| Result | **3/4 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 22591 to 22596 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 22595, 22596)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_animals.lua | an | **FAIL** | 2 |  | 1 Java exception(s) in the log |
| 4 | zedqa_animals_clip.lua | acl | PASS | 18 | zqa_acl_01_ranch.png, zqa_acl_02_ranch_foot.png, zqa_acl_03_zone.png, zqa_acl_04_animal.png, zqa_acl_05_butcher.png, zqa_acl_06_item_over_ranch.png, zqa_acl_07_item_closed.png, zqa_acl_08_loot_control.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 22591 at 20:39:48

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=11 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 22592 at 20:39:53

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=11 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_animals.lua (`ZEDQA an`) - FAIL, 2 s

- go 22593 at 20:39:57
- 1 Java exception(s) in the log

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=11 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ZEDQA an found hutch=true trough=true hook=true
ZEDQA an hutch birds=4 dirt=46
ERROR: General f:1125 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: addItems of non-table: null
ERROR: General f:1125> Lua(Vanilla).onAddFoodDebug> Exception thrown
    java.lang.RuntimeException: attempted index: addItems of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).onAddFoodDebug(ISFeedingTroughMenu.lua:174)
    Lua(Vanilla).tick(spawnpoints.lua:103)
ZEDQA an trough fed
ZEDQA an cow killed
ZEDQA an zone ok=true
ZEDQA an setup done
```

### 4. zedqa_animals_clip.lua (`ZEDQA acl`) - PASS, 18 s

- go 22594 at 20:40:03
- screenshots: zqa_acl_01_ranch.png, zqa_acl_02_ranch_foot.png, zqa_acl_03_zone.png, zqa_acl_04_animal.png, zqa_acl_05_butcher.png, zqa_acl_06_item_over_ranch.png, zqa_acl_07_item_closed.png, zqa_acl_08_loot_control.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=11 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #4 ok=true
ZEDQA acl animals 32, zones 2, alerts 36
ZEDQA acl ranch: tab=animals mode=tab view=overview clips left by the tab=0 win 640x315 footer=17 strip vis=true zones=7
ZEDQA acl ranch foot: tab=animals mode=tab view=overview clips left by the tab=0 win 640x315 footer=17 strip vis=true zones=7
ZEDQA acl zone QA Yard
ZEDQA acl zone: tab=animals mode=tab view=zone clips left by the tab=0 win 640x315 footer=17 strip vis=true zones=7
ZEDQA acl animal: tab=animals mode=tab view=animal clips left by the tab=0 win 640x315 footer=17 strip vis=true zones=7
ZEDQA acl butcher: tab=animals mode=tab view=overview clips left by the tab=0 win 640x315 footer=17 strip vis=true zones=7
ZEDQA acl item card over Ranch: T-shirt
ZEDQA acl item card: tab=animals mode=tab view=overview clips left by the tab=0 win 640x315 footer=17 strip vis=true zones=7
ZEDQA acl item closed: tab=animals mode=tab view=overview clips left by the tab=0 win 640x315 footer=17 strip vis=true zones=7
ZEDQA acl loot: tab=loot mode=nil view=overview clips left by the tab=0 win 333x315 footer=17 strip vis=true zones=7
ZEDQA acl DONE
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
