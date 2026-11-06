# ZeD-UI regression - 2026-11-05 18:24 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-05 18:24:31 |
| Finished | 2026-11-05 18:26:25 (1 min 53 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/ranch_pad.txt (3 scripts) |
| Result | **2/3 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 21418 to 21422 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 21421, 21422)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_animals.lua | an | **FAIL** | 2 |  | 1 Java exception(s) in the log |
| 3 | zedqa_ranch_pad.lua | rpd | PASS | 11 | zqa_rpd_totals.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 21418 at 18:25:36

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=46 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre clock 1.00 -> 11.00 (daylight)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_animals.lua (`ZEDQA an`) - FAIL, 2 s

- go 21419 at 18:25:41
- 1 Java exception(s) in the log

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=46 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA an spawned Base.ChickenHutch at 927,13037
ZEDQA an spawned Base.FeedingTroughDoubleMetal at 922,13043
ZEDQA an spawned Base.ButcherHook at 922,13038
ZEDQA an found hutch=true trough=true hook=true
ZEDQA an hutch birds=3 dirt=46
ERROR: General f:470 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: addItems of non-table: null
ERROR: General f:470> Lua(Vanilla).onAddFoodDebug> Exception thrown
    java.lang.RuntimeException: attempted index: addItems of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).onAddFoodDebug(ISFeedingTroughMenu.lua:174)
    Lua(Vanilla).tick(spawnpoints.lua:103)
ZEDQA an trough fed
ZEDQA an cow killed
ZEDQA an zone ok=true
ZEDQA an setup done
```

### 3. zedqa_ranch_pad.lua (`ZEDQA rpd`) - PASS, 11 s

- go 21420 at 18:25:46
- screenshots: zqa_rpd_totals.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=46 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ZEDQA rpd 34 presses of Down: scroll 1.000 (0 top, 1 foot), cues true
ZEDQA rpd PASS the page followed the walk down
ZEDQA rpd DONE
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
