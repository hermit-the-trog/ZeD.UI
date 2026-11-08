# ZeD-UI regression - 2026-11-06 14:58 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-06 14:58:16 |
| Finished | 2026-11-06 15:00:49 (2 min 33 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\gallery_farm_ranch.txt (6 scripts) |
| Result | **4/6 pass**, 0 warn, 2 fail, 0 timeout |
| Go numbers | 22385 to 22392 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 22391, 22392)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_t14_look.lua | g14l | PASS | 1 |  |  |
| 3 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 4 | gallery_farm_pre.lua | gfp | PASS | 1 |  |  |
| 5 | zedqa_animals.lua | an | **FAIL** | 2 |  | 1 Java exception(s) in the log |
| 6 | gallery_farm_ranch.lua | gfr | **FAIL** | 53 |  | 1 Java exception(s) in the log |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 22385 at 14:59:11

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=48 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre clock 1.22 -> 11.00 (daylight)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_t14_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 22386 at 14:59:16

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=48 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark orange small | GAL_LOOK dark orange, GAL_STILL 20
[ZeD.QA] run #2 ok=true
ZEDQA g14l DONE
```

### 3. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 22387 at 14:59:20

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=48 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #3 ok=true
ZEDQA hcn DONE
```

### 4. gallery_farm_pre.lua (`ZEDQA gfp`) - PASS, 1 s

- go 22388 at 14:59:24

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=48 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gfp set
[ZeD.QA] run #4 ok=true
ZEDQA gfp DONE
```

### 5. zedqa_animals.lua (`ZEDQA an`) - FAIL, 2 s

- go 22389 at 14:59:29
- 1 Java exception(s) in the log

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=48 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #5 ok=true
ZEDQA an spawned Base.ChickenHutch at 927,13037
ZEDQA an spawned Base.FeedingTroughDoubleMetal at 922,13043
ZEDQA an spawned Base.ButcherHook at 922,13038
ZEDQA an found hutch=true trough=true hook=true
ZEDQA an hutch birds=3 dirt=46
ERROR: General f:1621 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: addItems of non-table: null
ERROR: General f:1621> Lua(Vanilla).onAddFoodDebug> Exception thrown
    java.lang.RuntimeException: attempted index: addItems of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).onAddFoodDebug(ISFeedingTroughMenu.lua:174)
    Lua(Vanilla).tick(spawnpoints.lua:103)
ZEDQA an trough fed
ZEDQA an zone ok=true
ZEDQA an setup done
```

### 6. gallery_farm_ranch.lua (`ZEDQA gfr`) - FAIL, 53 s

- go 22390 at 14:59:34
- 1 Java exception(s) in the log

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=48 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #6 ok=true
ZEDQA gfr 14 cars out of the yard
ZEDQA gfr crops: Barley, Basil, BellPepper, BlackSage, BroadleafPlantain, Broccoli, Cabbages, Carrots, Cauliflower, Chamomile, Chives, Cilantro, Comfrey, CommonMallow, Corn, Cucumber, Flax, Garlic, Greenpeas, Habanero, Hemp, Hops, Jalapeno, Kale, Lavender, Leek, LemonGrass, Lettuce, Marigold, Mint, Onion, Oregano, Parsley, Poppies, Potatoes, Pumpkin, Radishes, Rosemary, Roses, Rye, Sage, Soybeans, Spinach, Strawberryplant, SugarBeets, Sunflower, SweetPotato, Thyme, Tobacco, Tomato, Turnip, Watermelon, Wheat, WildGarlic, Zucchini
ZEDQA gfr Cabbages row 0: asked 5, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_20
ZEDQA gfr Cabbages row 1: asked 3, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_18
ZEDQA gfr Cabbages row 2: asked 2, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_17
ZEDQA gfr Carrots row 0: asked 5, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_36
ZEDQA gfr Carrots row 1: asked 3, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_34
ZEDQA gfr Carrots row 2: asked 2, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_33
ZEDQA gfr Tomato row 0: asked 6, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_69
ZEDQA gfr Tomato row 1: asked 4, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_67
ZEDQA gfr Tomato row 2: asked 2, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_65
ZEDQA gfr Broccoli row 0: asked 5, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_28
ZEDQA gfr Broccoli row 1: asked 3, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_26
ZEDQA gfr Broccoli row 2: asked 2, grew to 1, state seeded
ZEDQA gfr sprite vegetation_farming_01_25
ZEDQA gfr 12 plots
ERROR: General f:2056> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:99)
    Lua(Vanilla).add(spawnpoints.lua:99)
    Lua(Vanilla).drive(spawnpoints.lua:175)
ZEDQA gfr animals 40, zones 1
ZEDQA gfr shot yard
ZEDQA gfr crop card true on row 2
ZEDQA gfr shot crop_young
ZEDQA gfr crop card 2 true on row 0
ZEDQA gfr shot crop_grown
ZEDQA gfr hutch true
ZEDQA gfr hutch card true
ZEDQA gfr shot hutch_eggs
ZEDQA gfr door true
ZEDQA gfr hatch true
ZEDQA gfr door open true, hatch open true
ZEDQA gfr shot hutch_open
ZEDQA gfr trough card true
ZEDQA gfr shot trough
ZEDQA gfr shot ranch
ZEDQA gfr shot ranch_foot
ZEDQA gfr shot zone
ZEDQA gfr the pasture's animals: 14
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
    2x ERROR: General f:N at KahluaThread.flushErrorMessage > -------------------------------------------------------------  :: attempted index: getLuaObjectOnSquare of non-table: null
    2x ERROR: General f:N> Lua(Vanilla).DoSpecialTooltip> Exception thrown  :: java.lang.RuntimeException: attempted index: getLuaObjectOnSquare of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
```
