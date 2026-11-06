# ZeD-UI regression - 2026-11-05 14:45 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-05 14:45:33 |
| Finished | 2026-11-05 14:53:03 (7 min 30 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/after_4ec5.txt (7 scripts) |
| Result | **4/7 pass**, 0 warn, 1 fail, 0 timeout, 2 not run |
| Go numbers | 21107 to 21113 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after zedqa_animals.lua: no DONE within 120 s; the script may still be running in the game
- quit: quit to the main menu, then to the desktop (go 21112, 21113)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | perf_spikes.lua | pks | PASS | 193 |  |  |
| 3 | zedqa_wt_bracket.lua | wtb | PASS | 19 | zqa_wtb_small_list.png, zqa_wtb_open_stack.png, zqa_wtb_narrow_wt.png, zqa_wtb_small_grid.png, zqa_wtb_large_list.png, zqa_wtb_large_grid.png, zqa_wtb_two_columns.png, zqa_wtb_two_columns_large.png |  |
| 4 | zedqa_headers_lang.lua | hdl | PASS | 7 | zqa_hdl_normal.png, zqa_hdl_test.png |  |
| 5 | zedqa_animals.lua | an | **FAIL** | 120 |  | 1 Java exception(s) in the log; no DONE within 120 s; the script may still be running in the game |
| 6 | zedqa_animals_list.lua | anl | SKIP |  |  | not run: no DONE within 120 s; the script may still be running in the game |
| 7 | zedqa_world_pad_take.lua | wpt | SKIP |  |  | not run: no DONE within 120 s; the script may still be running in the game |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 21107 at 14:46:43

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. perf_spikes.lua (`ZEDQA pks`) - PASS, 193 s

- go 21108 at 14:46:49

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA pks scene shut, 787 elements timed
ZEDQA pks RES shut frames=7198 spikes=0 worst=20
ZEDQA pks scene open, 821 elements timed
ZEDQA pks SPK open t=880313 frame=27 lua=15 | ZeD_Panel:prerender=8, ISInventoryPage:update=2, ISLabel:update=1, ISComboBox:update=1, WaterMarkUI:prerender=1, ZeD_Window:prerender=1
ZEDQA pks SPK open t=880338 frame=25 lua=16 | ZeD_Panel:prerender=8, ISButton:prerender=2, OnRenderTick closure 0x1596438447=2, ZeD_WindowOverlay:render=2, ZeD_Window:prerender=2
ZEDQA pks SPK open t=880429 frame=31 lua=22 | ZeD_Panel:prerender=14, ISButton:update=3, ISInventoryPage:update=2, ZeD_Window:prerender=2, ZeD_BeltHUD:prerender=1
ZEDQA pks SPK open t=880635 frame=26 lua=15 | ZeD_Panel:prerender=5, ZeD_WindowOverlay:render=3, OnRenderTick closure 0x1596438447=2, ISCharacterInfoWindow:update=1, ZeD_Watch:prerender=1, ZeD_MMOptions:update=1
ZEDQA pks SPK open t=880971 frame=29 lua=17 | ZeD_Panel:prerender=14, ZeD_BeltHUD:prerender=2, ISLabel:update=1
ZEDQA pks SPK open t=883167 frame=28 lua=18 | ZeD_Panel:prerender=9, ISComboBox:update=3, OnRenderTick closure 0x1596438447=2, ZeD_BeltHUD:prerender=1, ZeD_Window:prerender=1, ISButton:render=1
ZEDQA pks SPK open t=883265 frame=25 lua=15 | ZeD_Panel:prerender=6, ZeD_WindowOverlay:render=2, ISButtonPrompt:prerender=2, ISButton:update=2, ISInventoryPage:update=1, ISMegaVolumeControl:update=1
ZEDQA pks SPK open t=883290 frame=25 lua=15 | ZeD_Panel:prerender=11, ZeD_BeltHUD:prerender=2, ZeD_Window:prerender=2
ZEDQA pks RES open frames=5948 spikes=8 worst=31
ZEDQA pks scene shut2, 821 elements timed
ZEDQA pks RES shut2 frames=7200 spikes=0 worst=20
ZEDQA pks DONE
```

### 3. zedqa_wt_bracket.lua (`ZEDQA wtb`) - PASS, 19 s

- go 21109 at 14:50:05
- screenshots: zqa_wtb_small_list.png, zqa_wtb_open_stack.png, zqa_wtb_narrow_wt.png, zqa_wtb_small_grid.png, zqa_wtb_large_list.png, zqa_wtb_large_grid.png, zqa_wtb_two_columns.png, zqa_wtb_two_columns_large.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wtb start
[ZeD.QA] run #3 ok=true
ZEDQA wtb given: bag 5 x Base.Orange + Base.Saucepan, ground 5 x Base.Apple + Base.Saucepan (6 / 6)
ZEDQA wtb extra columns: char 0 world 0
ZEDQA wtb small list char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)") at x 537..590 of 651, name ends 239, columns 1
ZEDQA wtb small list char headers: cat true, cond true
ZEDQA wtb small list world stack Apple (Stale) x5: drew "(1.0)" (expect "(1.0)") at x 562..615 of 651, name ends 258, columns 1
ZEDQA wtb small list world headers: cat true, cond true
ZEDQA wtb small list char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb small list world single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb open stack char: the row "(1.0)", 4 rows under it, 4 with their own weight
ZEDQA wtb open stack world: the row "(1.0)", 4 rows under it, 4 with their own weight
ZEDQA wtb char WT column 101 -> 81
ZEDQA wtb narrow WT char stack Orange (Fresh) x5: drew "(1)" (expect "(1.0)" or "(1)" / "0.2") at x 559..590 of 651, name ends 248, columns 1
ZEDQA wtb narrow WT char headers: cat true, cond true
ZEDQA wtb narrow WT char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb small grid char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)") at x 272..300 of 305, name ends nil, columns 1
ZEDQA wtb small grid world stack Apple (Stale) x5: drew "(1.0)" (expect "(1.0)") at x 76..104 of 109, name ends nil, columns 1
ZEDQA wtb small grid char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb small grid world single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb large list char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)") at x 502..565 of 633, name ends 284, columns 1
ZEDQA wtb large list char headers: cat true, cond false
ZEDQA wtb large list world stack Apple (Stale) x5: drew "(1.0)" (expect "(1.0)") at x 530..593 of 633, name ends 295, columns 1
ZEDQA wtb large list world headers: cat true, cond false
ZEDQA wtb large list char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb large list world single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb large grid char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)" or "(1)" / "0.2") at x 537..571 of 577, name ends nil, columns 1
ZEDQA wtb large grid world stack Apple (Stale) x5: drew "(1.0)" (expect "(1.0)" or "(1)" / "0.2") at x 85..119 of 125, name ends nil, columns 1
ZEDQA wtb large grid char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb large grid world single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb pack column on: true
ZEDQA wtb char columns 2
ZEDQA wtb two columns char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)" or "(1)" / "0.2") at x 712..765 of 826, name ends 680, columns 2
ZEDQA wtb two columns char headers: cat false, cond false
ZEDQA wtb two columns char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb two columns large char stack Orange (Fresh) x5: drew "(1)" (expect "(1.0)" or "(1)" / "0.2") at x 704..740 of 808, name ends 653, columns 2
ZEDQA wtb two columns large char headers: cat false, cond false
ZEDQA wtb two columns large char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb size back to small | bag Base.Orange left 0
ZEDQA wtb all checks held; DONE
```

### 4. zedqa_headers_lang.lua (`ZEDQA hdl`) - PASS, 7 s

- go 21110 at 14:50:28
- screenshots: zqa_hdl_normal.png, zqa_hdl_test.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #4 ok=true
ZEDQA hdl test language on: true, Weight reads [Ŵťť], Condition reads [Ĉôôôñď]
ZEDQA hdl DONE
```

### 5. zedqa_animals.lua (`ZEDQA an`) - FAIL, 120 s

- go 21111 at 14:50:39
- 1 Java exception(s) in the log
- no DONE within 120 s; the script may still be running in the game

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #5 ok=true
ZEDQA an spawned Base.ChickenHutch at 927,13037
ZEDQA an spawned Base.FeedingTroughDoubleMetal at 922,13043
ZEDQA an spawned Base.ButcherHook at 922,13038
ZEDQA an found hutch=true trough=true hook=true
ZEDQA an hutch birds=3 dirt=46
ERROR: General f:25023 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: addItems of non-table: null
ERROR: General f:25023> Lua(Vanilla).onAddFoodDebug> Exception thrown
    java.lang.RuntimeException: attempted index: addItems of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).onAddFoodDebug(ISFeedingTroughMenu.lua:174)
    Lua(Vanilla).tick(spawnpoints.lua:103)
ZEDQA an trough fed
ZEDQA an cow killed
ZEDQA an zone ok=true
ZEDQA an setup done
```

### 6. zedqa_animals_list.lua (`ZEDQA anl`) - SKIP, not run

- not run: no DONE within 120 s; the script may still be running in the game

### 7. zedqa_world_pad_take.lua (`ZEDQA wpt`) - SKIP, not run

- not run: no DONE within 120 s; the script may still be running in the game

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N> Lua((MOD:ZeD-GUI)).onDetails> Exception thrown  :: java.lang.RuntimeException: attempted index of non-table at KahluaUtil.fail(KahluaUtil.java:100).
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at KahluaThread.pcall > Lua code called from the wrong thread, owner=GameLoadingThread current=MainThread
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
