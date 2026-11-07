# ZeD-UI regression - 2026-11-06 23:42 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-06 23:42:31 |
| Finished | 2026-11-06 23:45:02 (2 min 31 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\gallery_farm_ranch.txt (6 scripts) |
| Result | **4/6 pass**, 0 warn, 2 fail, 0 timeout |
| Go numbers | 22790 to 22797 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 22796, 22797)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_t14_look.lua | g14l | PASS | 1 |  |  |
| 3 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 4 | gallery_farm_pre.lua | gfp | PASS | 1 |  |  |
| 5 | zedqa_animals.lua | an | **FAIL** | 2 |  | 1 Java exception(s) in the log |
| 6 | gallery_farm_ranch.lua | gfr | **FAIL** | 53 |  | 25 Java exception(s) in the log; 12 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 22790 at 23:43:23

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_t14_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 22791 at 23:43:29

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark orange small | GAL_LOOK dark orange, GAL_STILL 20
[ZeD.QA] run #2 ok=true
ZEDQA g14l DONE
```

### 3. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 22792 at 23:43:33

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #3 ok=true
ZEDQA hcn DONE
```

### 4. gallery_farm_pre.lua (`ZEDQA gfp`) - PASS, 1 s

- go 22793 at 23:43:37

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gfp set
[ZeD.QA] run #4 ok=true
ZEDQA gfp DONE
```

### 5. zedqa_animals.lua (`ZEDQA an`) - FAIL, 2 s

- go 22794 at 23:43:42
- 1 Java exception(s) in the log

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #5 ok=true
ZEDQA an found hutch=true trough=true hook=true
ZEDQA an hutch birds=4 dirt=46
ERROR: General f:1737 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: addItems of non-table: null
ERROR: General f:1737> Lua(Vanilla).onAddFoodDebug> Exception thrown
    java.lang.RuntimeException: attempted index: addItems of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).onAddFoodDebug(ISFeedingTroughMenu.lua:174)
    Lua(Vanilla).tick(spawnpoints.lua:103)
ZEDQA an trough fed
ZEDQA an zone ok=true
ZEDQA an setup done
```

### 6. gallery_farm_ranch.lua (`ZEDQA gfr`) - FAIL, 53 s

- go 22795 at 23:43:47
- 25 Java exception(s) in the log
- 12 ERR line(s)

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #6 ok=true
ZEDQA gfr 1 cars out of the yard
ZEDQA gfr crops: Barley, Basil, BellPepper, BlackSage, BroadleafPlantain, Broccoli, Cabbages, Carrots, Cauliflower, Chamomile, Chives, Cilantro, Comfrey, CommonMallow, Corn, Cucumber, Flax, Garlic, Greenpeas, Habanero, Hemp, Hops, Jalapeno, Kale, Lavender, Leek, LemonGrass, Lettuce, Marigold, Mint, Onion, Oregano, Parsley, Poppies, Potatoes, Pumpkin, Radishes, Rosemary, Roses, Rye, Sage, Soybeans, Spinach, Strawberryplant, SugarBeets, Sunflower, SweetPotato, Thyme, Tobacco, Tomato, Turnip, Watermelon, Wheat, WildGarlic, Zucchini
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 930,13039,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 930,13041,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 930,13043,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 932,13039,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 932,13041,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 932,13043,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 934,13039,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 934,13041,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 934,13043,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 936,13039,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 936,13041,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ERROR: General f:2170> Lua(Vanilla).newLuaObjectAt> Exception thrown
    java.lang.IllegalStateException: already an object at 936,13043,0 at GlobalObjectSystem.newObject(GlobalObjectSystem.java:40).
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:82)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
    Lua(Vanilla).add(spawnpoints.lua:65)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ERROR: General f:2170 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getModData of non-table: null
ERROR: General f:2170> Lua(Vanilla).new> Exception thrown
    java.lang.RuntimeException: attempted index: getModData of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).new(SGlobalObject.lua:70)
    Lua(Vanilla).new(SPlantGlobalObject.lua:8)
    Lua(Vanilla).newLuaObjectAt(SGlobalObjectSystem.lua:83)
    Lua(Vanilla).plow(SFarmingSystem.lua:524)
    Lua(Vanilla).pcall(spawnpoints.lua:66)
ZEDQA gfr ERR plot: attempted index: getModData of non-table: null java.lang.RuntimeException
ZEDQA gfr 0 plots
ERROR: General f:2170> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:99)
    Lua(Vanilla).add(spawnpoints.lua:99)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ZEDQA gfr animals 54, zones 2
ZEDQA gfr shot yard
ZEDQA gfr crop card false on row nil
ZEDQA gfr shot crop_young
ZEDQA gfr crop card 2 false on row nil
ZEDQA gfr shot crop_grown
ZEDQA gfr hutch true
ZEDQA gfr hutch card true
ZEDQA gfr shot hutch_eggs
ZEDQA gfr door true
ZEDQA gfr hatch true
ZEDQA gfr door open false, hatch open false
ZEDQA gfr shot hutch_open
ZEDQA gfr trough card true
ZEDQA gfr shot trough
ZEDQA gfr shot ranch
ZEDQA gfr shot ranch_foot
ZEDQA gfr shot zone
ZEDQA gfr the pasture's animals: 0
ZEDQA gfr shot animal
ZEDQA gfr shot butcher
ZEDQA gfr DONE
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
    2x ERROR: General f:N at KahluaThread.flushErrorMessage > -------------------------------------------------------------  :: attempted index: getLuaObjectOnSquare of non-table: null
    2x ERROR: General f:N> Lua(Vanilla).DoSpecialTooltip> Exception thrown  :: java.lang.RuntimeException: attempted index: getLuaObjectOnSquare of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
```
