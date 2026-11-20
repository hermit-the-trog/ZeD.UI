# ZeD-UI regression - 2026-11-20 08:37 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-20 08:37:35 |
| Finished | 2026-11-20 08:40:31 (2 min 55 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\hotfix_veh.txt (12 scripts) |
| Result | **11/12 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 31158 to 31171 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 31170, 31171)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 4 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 5 | gallery_b10_glasses.lua | gls | PASS | 2 |  |  |
| 6 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 7 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 8 | gallery_v1_a_common.lua | g1c | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 9 | hfr_common.lua | hfrc | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 10 | hfr_veh.lua | hfv | **FAIL** | 34 |  | 5 Java exception(s) in the log; late output from unl (34 line(s), not counted) |
| 11 | gallery_reload.lua | rel | PASS | 1 |  | late output from unl (1 line(s), not counted) |
| 12 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 31158 at 08:38:42

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta21 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 31159 at 08:38:48

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 31160 at 08:38:52

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

- go 31161 at 08:38:56

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.24 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 31162 at 08:39:01

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls short sighted false, prescription glasses off
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 31163 at 08:39:07

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 31164 at 08:39:11

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl taken out of the inventory for the run: 0 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #7 ok=true
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (x3)
```

### 8. gallery_v1_a_common.lua (`ZEDQA g1c`) - PASS, 1 s

- go 31165 at 08:39:15
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1c the floating XP text muted until gallery_v1_a_end.lua
ZEDQA g1c eyes at the start: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3
ZEDQA g1c helpers ready | ZeD loaded true | story staged false | load 12.3 of 8 kg, 26 items, Heavy Load 1
[ZeD.QA] run #8 ok=true
ZEDQA g1c DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x4)
```

### 9. hfr_common.lua (`ZEDQA hfrc`) - PASS, 1 s

- go 31166 at 08:39:19
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hfrc helpers ready
[ZeD.QA] run #9 ok=true
ZEDQA hfrc DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x4)
```

### 10. hfr_veh.lua (`ZEDQA hfv`) - FAIL, 34 s

- go 31167 at 08:39:24
- 5 Java exception(s) in the log
- late output from unl (34 line(s), not counted)

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hfv start (30 steps)
[ZeD.QA] run #10 ok=true
ZEDQA hfv bottom-right element UIElement / WaterMarkUI at 3602,2127 228x22
ZEDQA hfv hid the game's build line (WaterMarkUI)
ZEDQA hfv short sighted false, prescription glasses off
ERROR: General f:3738 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: noSearch of non-table: null
ERROR: General f:3738> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: noSearch of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:121)
    Lua(Vanilla).clean(spawnpoints.lua:121)
    Lua(Vanilla).start0(spawnpoints.lua:124)
    Lua(Vanilla).step(spawnpoints.lua:15)
    Lua(Vanilla).tick(spawnpoints.lua:91)
ZEDQA hfv start at 925,13040 | screen 3840x2160 | Style 1
ZEDQA hfv zombies taken away near the store: 0
ZEDQA vp hfv player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=917,13030 dist=13.5 chunk=true inMap=true car=Base.PickUpTruck at 917.0,13030.0 dist=13.5 vehicles=32
ZEDQA car hfv Base.PickUpTruck spawned on spot 11 (917,13030)
ZEDQA unl load 12.3 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA hfv zoom 1
ZEDQA hfv car ready true nil
ZEDQA unl load 13.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)   (x13)
ZEDQA hfv Vehicle tab open true
ZEDQA unl load 13.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA hfv short sighted false, prescription glasses off
ERROR: General f:4874 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: noSearch of non-table: null
ERROR: General f:4874> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: noSearch of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:121)
    Lua(Vanilla).clean(spawnpoints.lua:121)
    Lua(Vanilla).shot(spawnpoints.lua:55)
    Lua(Vanilla).shot(spawnpoints.lua:56)
    Lua(Vanilla).still(spawnpoints.lua:42)
ZEDQA hfv shot hfr_D_vehicle_tab_rows
ZEDQA hfv load hfr_D_vehicle_tab_rows: 13.3 of 18 kg, 28 items, Heavy Load 0
ZEDQA hfv eyes hfr_D_vehicle_tab_rows: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 8
ZEDQA hfv box hfr_D_vehicle_tab_rows character 1760,776-2080,1196
ZEDQA hfv box hfr_D_vehicle_tab_rows char 1134,0-1911,735
ZEDQA hfv box hfr_D_vehicle_tab_rows world 1929,0-3546,735
ZEDQA hfv box hfr_D_vehicle_tab_rows belt 1439,2034-2378,2132
ZEDQA unl load 13.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA hfv D_tire_card row true of 33
ZEDQA hfv D_tire_card: card set directly on TireRearLeft (row y 815)
ZEDQA unl load 13.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA hfv short sighted false, prescription glasses off
ERROR: General f:4965 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: noSearch of non-table: null
ERROR: General f:4965> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: noSearch of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:121)
    Lua(Vanilla).clean(spawnpoints.lua:121)
    Lua(Vanilla).shot(spawnpoints.lua:55)
    Lua(Vanilla).shot(spawnpoints.lua:56)
    Lua(Vanilla).still(spawnpoints.lua:65)
ZEDQA hfv shot hfr_D_tire_card
ZEDQA hfv load hfr_D_tire_card: 13.3 of 18 kg, 28 items, Heavy Load 0
ZEDQA hfv eyes hfr_D_tire_card: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 12
ZEDQA hfv box hfr_D_tire_card character 1760,776-2080,1196
ZEDQA hfv box hfr_D_tire_card char 1134,0-1911,735
ZEDQA hfv box hfr_D_tire_card world 1929,0-3546,735
ZEDQA hfv box hfr_D_tire_card belt 1439,2034-2378,2132
ZEDQA unl load 13.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA hfv D_part_take_off_first row true of 33
ZEDQA hfv D_part_take_off_first: card set directly on BrakeRearLeft (row y 857)
ZEDQA unl load 13.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA hfv short sighted false, prescription glasses off
ERROR: General f:5066 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: noSearch of non-table: null
ERROR: General f:5066> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: noSearch of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:121)
    Lua(Vanilla).clean(spawnpoints.lua:121)
    Lua(Vanilla).shot(spawnpoints.lua:55)
    Lua(Vanilla).shot(spawnpoints.lua:56)
    Lua(Vanilla).still(spawnpoints.lua:65)
ZEDQA hfv shot hfr_D_part_take_off_first
ZEDQA hfv load hfr_D_part_take_off_first: 13.3 of 18 kg, 28 items, Heavy Load 0
ZEDQA hfv eyes hfr_D_part_take_off_first: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 16
ZEDQA hfv box hfr_D_part_take_off_first character 1760,776-2080,1196
ZEDQA hfv box hfr_D_part_take_off_first char 1134,0-1911,735
ZEDQA hfv box hfr_D_part_take_off_first world 1929,0-3546,735
ZEDQA hfv box hfr_D_part_take_off_first belt 1439,2034-2378,2132
ZEDQA unl load 13.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA hfv uninstall tire asked true
ZEDQA unl load 13.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA hfv queue head ISUninstallVehiclePart, reached true
ZEDQA hfv queue head at the shot none
ZEDQA hfv not taken: D_install_band_no_percent (no install action running (head none))
ZEDQA hfv seat key true nil
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA hfv short sighted false, prescription glasses off
ERROR: General f:5435 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: noSearch of non-table: null
ERROR: General f:5435> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: noSearch of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:121)
    Lua(Vanilla).clean(spawnpoints.lua:121)
    Lua(Vanilla).shot(spawnpoints.lua:55)
    Lua(Vanilla).shot(spawnpoints.lua:56)
    Lua(Vanilla).step(spawnpoints.lua:120)
ZEDQA hfv shot hfr_D_seat_free_hover
ZEDQA hfv load hfr_D_seat_free_hover: 12.6 of 18 kg, 28 items, Heavy Load 0
ZEDQA hfv eyes hfr_D_seat_free_hover: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 20
ZEDQA hfv box hfr_D_seat_free_hover character 1760,776-2080,1196
ZEDQA hfv box hfr_D_seat_free_hover belt 1439,2034-2378,2132
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA hfv glasses put on by the script taken off again: 0, worn ones put back: 0
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfv put back
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfv end: 4 shots, 1 not taken or failed
ZEDQA hfv DONE
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
```

### 11. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 31168 at 08:40:01
- late output from unl (1 line(s), not counted)

```text
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
[ZeD.QA] state #11 speed=1 paused=false player=919,13030 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA rel put back 0 things; after: 12.3 of 18 kg, 26 items, Heavy Load 0
[ZeD.QA] run #11 ok=true
ZEDQA rel DONE
```

### 12. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 31169 at 08:40:05

```text
[ZeD.QA] state #12 speed=1 paused=false player=919,13030 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #12 ok=true
ZEDQA g14e DONE
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
