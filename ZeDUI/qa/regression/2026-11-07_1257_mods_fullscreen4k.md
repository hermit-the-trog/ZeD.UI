# ZeD-UI regression - 2026-11-07 12:57 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-07 12:57:51 |
| Finished | 2026-11-07 12:59:30 (1 min 38 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta7 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r6_ctx.txt (2 scripts) |
| Result | **1/2 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 23074 to 23077 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 23076, 23077)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_ctxlist.lua | cl | **FAIL** | 6 | zqa_cl_1.png, zqa_cl_2.png | 3 Java exception(s) in the log; 3 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 23074 at 12:58:56

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_ctxlist.lua (`ZEDQA cl`) - FAIL, 6 s

- go 23075 at 12:59:01
- 3 Java exception(s) in the log
- 3 ERR line(s)
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #2 ok=true
ZEDQA cl class ZeD_ContextMenu | rows:
ERROR: General f:605 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: 1.0 of non-table: null
ERROR: General f:605> Lua(Vanilla).at> Exception thrown
    java.lang.RuntimeException: attempted index: 1.0 of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).at(spawnpoints.lua:31)
    Lua(Vanilla).onTick(spawnpoints.lua:53)
ZEDQA cl ERR 60 attempted index: 1.0 of non-table: null java.lang.RuntimeException
ERROR: General f:625 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: 2.0 of non-table: null
ERROR: General f:625> Lua(Vanilla).at> Exception thrown
    java.lang.RuntimeException: attempted index: 2.0 of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).at(spawnpoints.lua:40)
    Lua(Vanilla).onTick(spawnpoints.lua:53)
ZEDQA cl ERR 80 attempted index: 2.0 of non-table: null java.lang.RuntimeException
ERROR: General f:635> Lua(Vanilla).at> Exception thrown
    java.lang.RuntimeException: __len not defined for operand at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).at(spawnpoints.lua:41)
    Lua(Vanilla).onTick(spawnpoints.lua:53)
ZEDQA cl ERR 90 __len not defined for operand java.lang.RuntimeException
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
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
