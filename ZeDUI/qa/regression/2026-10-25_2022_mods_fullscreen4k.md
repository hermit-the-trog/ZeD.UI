# ZeD-UI regression - 2026-10-25 20:23 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-25 20:23:20 |
| Finished | 2026-10-25 20:29:02 (5 min 42 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/AppData/Local/Temp/claude/C--Users-danie-Zomboid/989d1212-0f15-49ba-a371-9ee134c38e7f/scratchpad/compat_v2_manifest.txt (4 scripts) |
| Result | **3/4 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 13240 to 13245 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13244, 13245)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_loot_tabs.lua | lt | PASS | 1 |  |  |
| 3 | compat_vehicles_list.lua | cvl | PASS | 1 |  |  |
| 4 | zedqa_compat_vehicles.lua | cv | **FAIL** | 209 | zqa_cv_1_dash.png, zqa_cv_1_tab.png, zqa_cv_2_dash.png, zqa_cv_2_tab.png, zqa_cv_3_dash.png, zqa_cv_3_tab.png, zqa_cv_4_dash.png, zqa_cv_4_tab.png, zqa_cv_5_dash.png, zqa_cv_5_tab.png, zqa_cv_6_dash.png, zqa_cv_6_tab.png | 7 Java exception(s) in the log; 6 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13240 at 20:24:51

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_loot_tabs.lua (`ZEDQA lt`) - PASS, 1 s

- go 13241 at 20:24:55

```text
[ZeD.QA] windows reset (R)
ZEDQA lt start
[ZeD.QA] run #2 ok=true
ZEDQA lt Character loot drawer false | World loot drawer false
ZEDQA lt DONE
```

### 3. compat_vehicles_list.lua (`ZEDQA cvl`) - PASS, 1 s

- go 13242 at 20:24:59

```text
[ZeD.QA] windows reset (R)
ZEDQA cvl 76 vehicles listed
[ZeD.QA] run #3 ok=true
ZEDQA cvl DONE
```

### 4. zedqa_compat_vehicles.lua (`ZEDQA cv`) - FAIL, 209 s

- go 13243 at 20:25:04
- 7 Java exception(s) in the log
- 6 ERR line(s)
- screenshots: zqa_cv_1_dash.png, zqa_cv_1_tab.png, zqa_cv_2_dash.png, zqa_cv_2_tab.png, zqa_cv_3_dash.png, zqa_cv_3_tab.png, zqa_cv_4_dash.png, zqa_cv_4_tab.png, zqa_cv_5_dash.png, zqa_cv_5_tab.png, zqa_cv_6_dash.png, zqa_cv_6_tab.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cv modded vehicle scripts: 76 to try, from 37 Workshop items
ZEDQA cv start
[ZeD.QA] run #4 ok=true
ZEDQA cv PASS 2409333430 Base.91range: spawns
ZEDQA cv 2409333430 Base.91range: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2409333430 Base.91range: the dashboard shows with a design
ZEDQA cv PASS 2409333430 Base.91range: the dashboard is on screen
ZEDQA cv 2409333430 Base.91range: Vehicle tab true, 61 parts
ZEDQA cv PASS 2409333430 Base.91range: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2409333430 Base.91range2: spawns
ZEDQA cv 2409333430 Base.91range2: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2409333430 Base.91range2: the dashboard shows with a design
ZEDQA cv PASS 2409333430 Base.91range2: the dashboard is on screen
ZEDQA cv 2409333430 Base.91range2: Vehicle tab true, 59 parts
ZEDQA cv PASS 2409333430 Base.91range2: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2478247379 Base.67commando: spawns
ZEDQA cv 2478247379 Base.67commando: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2478247379 Base.67commando: the dashboard shows with a design
ZEDQA cv PASS 2478247379 Base.67commando: the dashboard is on screen
ZEDQA cv 2478247379 Base.67commando: Vehicle tab true, 46 parts
ZEDQA cv PASS 2478247379 Base.67commando: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2478247379 Base.67commandoPolice: spawns
ZEDQA cv 2478247379 Base.67commandoPolice: design police, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2478247379 Base.67commandoPolice: the dashboard shows with a design
ZEDQA cv PASS 2478247379 Base.67commandoPolice: the dashboard is on screen
ZEDQA cv 2478247379 Base.67commandoPolice: Vehicle tab true, 47 parts
ZEDQA cv PASS 2478247379 Base.67commandoPolice: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2566953935 Base.86oshkoshFRTR55: spawns
ZEDQA cv 2566953935 Base.86oshkoshFRTR55: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2566953935 Base.86oshkoshFRTR55: the dashboard shows with a design
ZEDQA cv PASS 2566953935 Base.86oshkoshFRTR55: the dashboard is on screen
ZEDQA cv 2566953935 Base.86oshkoshFRTR55: Vehicle tab true, 61 parts
ZEDQA cv PASS 2566953935 Base.86oshkoshFRTR55: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2566953935 Base.86oshkoshKYFD: spawns
ZEDQA cv 2566953935 Base.86oshkoshKYFD: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2566953935 Base.86oshkoshKYFD: the dashboard shows with a design
ZEDQA cv PASS 2566953935 Base.86oshkoshKYFD: the dashboard is on screen
ZEDQA cv 2566953935 Base.86oshkoshKYFD: Vehicle tab true, 61 parts
ZEDQA cv PASS 2566953935 Base.86oshkoshKYFD: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2618213077 Base.82oshkoshM911: spawns
ZEDQA cv 2618213077 Base.82oshkoshM911: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2618213077 Base.82oshkoshM911: the dashboard shows with a design
ZEDQA cv PASS 2618213077 Base.82oshkoshM911: the dashboard is on screen
ZEDQA cv 2618213077 Base.82oshkoshM911: Vehicle tab true, 51 parts
ZEDQA cv PASS 2618213077 Base.82oshkoshM911: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2618213077 Base.82oshkoshM911B: spawns
ZEDQA cv 2618213077 Base.82oshkoshM911B: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2618213077 Base.82oshkoshM911B: the dashboard shows with a design
ZEDQA cv PASS 2618213077 Base.82oshkoshM911B: the dashboard is on screen
ZEDQA cv 2618213077 Base.82oshkoshM911B: Vehicle tab true, 51 parts
ZEDQA cv PASS 2618213077 Base.82oshkoshM911B: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2642541073 Base.92amgeneralM998: spawns
ZEDQA cv 2642541073 Base.92amgeneralM998: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2642541073 Base.92amgeneralM998: the dashboard shows with a design
ZEDQA cv PASS 2642541073 Base.92amgeneralM998: the dashboard is on screen
ZEDQA cv 2642541073 Base.92amgeneralM998: Vehicle tab true, 55 parts
ZEDQA cv PASS 2642541073 Base.92amgeneralM998: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2642541073 Base.TrailerM101A3cargo: spawns
ERROR: General f:4196 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: setContainerContentAmount of non-table: null
ERROR: General f:4196> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: setContainerContentAmount of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:82)
    Lua(Vanilla).t(spawnpoints.lua:82)
    Lua(Vanilla).tick(spawnpoints.lua:133)
ZEDQA cv 2642541073 Base.TrailerM101A3cargo: Vehicle tab true, 11 parts
ZEDQA cv PASS 2642541073 Base.TrailerM101A3cargo: the World window's Vehicle tab opens beside it
ERROR: General f:4451 at LuaManager.getFunctionObject > no such function "Vehicles.Create.ANTENNA"   (x3)
ERROR: General f:4451 at LuaManager.getFunctionObject > no such function "Vehicles.Create.TORRENTA"
ERROR: General f:4451 at LuaManager.getFunctionObject > no such function "Vehicles.Create.DefaultRAMDOM"
ERROR: General f:4451 at LuaManager.getFunctionObject > no such function "Vehicles.Create.ARMOR"
ERROR: General f:4451 at LuaManager.getFunctionObject > no such function "Vehicles.Create.DefaultRAMDOM"
ERROR: General f:4451 at LuaManager.getFunctionObject > no such function "Vehicles.Init.ANTENNA"   (x3)
ERROR: General f:4451 at LuaManager.getFunctionObject > no such function "Vehicles.Init.TORRENTA"
ERROR: General f:4451 at LuaManager.getFunctionObject > no such function "Vehicles.Init.PC_Default"
ERROR: General f:4451 at LuaManager.getFunctionObject > no such function "Vehicles.Init.ARMOR"
ERROR: General f:4451 at LuaManager.getFunctionObject > no such function "Vehicles.Init.TANKTIRE"   (x4)
ZEDQA cv PASS 2705655822 Base.M113_APC: spawns
ERROR: General f:4451 at LuaManager.getFunctionObject > no such function "Vehicles.Init.PC_Default"
ERROR: General f:4451 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: isDriver of non-table: null
ERROR: General f:4451> Lua(Vanilla).onEnterVehicle> Exception thrown
    java.lang.RuntimeException: attempted index: isDriver of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).onEnterVehicle(ISVehicleDashboard.lua:603)
    Lua(Vanilla).t(spawnpoints.lua:89)
    Lua(Vanilla).tick(spawnpoints.lua:133)
ZEDQA cv 2705655822 Base.M113_APC: design nyala, dashboard false at 1120,1804 1600x344
ZEDQA cv FAIL 2705655822 Base.M113_APC: the dashboard shows with a design
ZEDQA cv FAIL 2705655822 Base.M113_APC: the dashboard is on screen
ZEDQA cv 2705655822 Base.M113_APC: Vehicle tab true, 36 parts
ZEDQA cv PASS 2705655822 Base.M113_APC: the World window's Vehicle tab opens beside it
ERROR: General f:4706 at LuaManager.getFunctionObject > no such function "Vehicles.Create.ANTENNA"   (x3)
ERROR: General f:4706 at LuaManager.getFunctionObject > no such function "Vehicles.Create.TORRENTA"
ERROR: General f:4706 at LuaManager.getFunctionObject > no such function "Vehicles.Create.DefaultRAMDOM"
ERROR: General f:4706 at LuaManager.getFunctionObject > no such function "Vehicles.Create.ARMOR"
ERROR: General f:4706 at LuaManager.getFunctionObject > no such function "Vehicles.Create.DefaultRAMDOM"
ERROR: General f:4706 at LuaManager.getFunctionObject > no such function "Vehicles.Init.ANTENNA"   (x3)
ERROR: General f:4706 at LuaManager.getFunctionObject > no such function "Vehicles.Init.TORRENTA"
ERROR: General f:4706 at LuaManager.getFunctionObject > no such function "Vehicles.Init.PC_Default"
ERROR: General f:4706 at LuaManager.getFunctionObject > no such function "Vehicles.Init.ARMOR"
ERROR: General f:4706 at LuaManager.getFunctionObject > no such function "Vehicles.Init.TANKTIRE"   (x4)
ZEDQA cv PASS 2705655822 Base.M113_Police: spawns
ERROR: General f:4706 at LuaManager.getFunctionObject > no such function "Vehicles.Init.PC_Default"
ERROR: General f:4706 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: isDriver of non-table: null
ERROR: General f:4706> Lua(Vanilla).onEnterVehicle> Exception thrown
    java.lang.RuntimeException: attempted index: isDriver of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).onEnterVehicle(ISVehicleDashboard.lua:603)
    Lua(Vanilla).t(spawnpoints.lua:89)
    Lua(Vanilla).tick(spawnpoints.lua:133)
ZEDQA cv 2705655822 Base.M113_Police: design nyala, dashboard false at 1120,1804 1600x344
ZEDQA cv FAIL 2705655822 Base.M113_Police: the dashboard shows with a design
ZEDQA cv FAIL 2705655822 Base.M113_Police: the dashboard is on screen
ZEDQA cv 2705655822 Base.M113_Police: Vehicle tab true, 37 parts
ZEDQA cv PASS 2705655822 Base.M113_Police: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2772575623 Base.59ambulance: spawns
ZEDQA cv 2772575623 Base.59ambulance: design ambulance, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2772575623 Base.59ambulance: the dashboard shows with a design
ZEDQA cv PASS 2772575623 Base.59ambulance: the dashboard is on screen
ZEDQA cv 2772575623 Base.59ambulance: Vehicle tab true, 52 parts
ZEDQA cv PASS 2772575623 Base.59ambulance: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2772575623 Base.59meteor: spawns
ZEDQA cv 2772575623 Base.59meteor: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2772575623 Base.59meteor: the dashboard shows with a design
ZEDQA cv PASS 2772575623 Base.59meteor: the dashboard is on screen
ZEDQA cv 2772575623 Base.59meteor: Vehicle tab true, 51 parts
ZEDQA cv PASS 2772575623 Base.59meteor: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2799152995 Base.78amgeneralM35A2: spawns
ZEDQA cv 2799152995 Base.78amgeneralM35A2: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2799152995 Base.78amgeneralM35A2: the dashboard shows with a design
ZEDQA cv PASS 2799152995 Base.78amgeneralM35A2: the dashboard is on screen
ZEDQA cv 2799152995 Base.78amgeneralM35A2: Vehicle tab true, 49 parts
ZEDQA cv PASS 2799152995 Base.78amgeneralM35A2: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2799152995 Base.78amgeneralM49A2C: spawns
ZEDQA cv 2799152995 Base.78amgeneralM49A2C: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2799152995 Base.78amgeneralM49A2C: the dashboard shows with a design
ZEDQA cv PASS 2799152995 Base.78amgeneralM49A2C: the dashboard is on screen
ZEDQA cv 2799152995 Base.78amgeneralM49A2C: Vehicle tab true, 48 parts
ZEDQA cv PASS 2799152995 Base.78amgeneralM49A2C: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2805630347 Base.84mercLWB2: spawns
ZEDQA cv 2805630347 Base.84mercLWB2: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2805630347 Base.84mercLWB2: the dashboard shows with a design
ZEDQA cv PASS 2805630347 Base.84mercLWB2: the dashboard is on screen
ZEDQA cv 2805630347 Base.84mercLWB2: Vehicle tab true, 48 parts
ZEDQA cv PASS 2805630347 Base.84mercLWB2: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2805630347 Base.84mercLWB4: spawns
ZEDQA cv 2805630347 Base.84mercLWB4: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2805630347 Base.84mercLWB4: the dashboard shows with a design
ZEDQA cv PASS 2805630347 Base.84mercLWB4: the dashboard is on screen
ZEDQA cv 2805630347 Base.84mercLWB4: Vehicle tab true, 60 parts
ZEDQA cv PASS 2805630347 Base.84mercLWB4: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2811383142 Base.83amgeneralM923: spawns
ZEDQA cv 2811383142 Base.83amgeneralM923: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2811383142 Base.83amgeneralM923: the dashboard shows with a design
ZEDQA cv PASS 2811383142 Base.83amgeneralM923: the dashboard is on screen
ZEDQA cv 2811383142 Base.83amgeneralM923: Vehicle tab true, 59 parts
ZEDQA cv PASS 2811383142 Base.83amgeneralM923: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2846036306 Base.92nissanGTR: spawns
ZEDQA cv 2846036306 Base.92nissanGTR: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2846036306 Base.92nissanGTR: the dashboard shows with a design
ZEDQA cv PASS 2846036306 Base.92nissanGTR: the dashboard is on screen
ZEDQA cv 2846036306 Base.92nissanGTR: Vehicle tab true, 52 parts
ZEDQA cv PASS 2846036306 Base.92nissanGTR: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2846036306 Base.92nissanGTRlhd: spawns
ZEDQA cv 2846036306 Base.92nissanGTRlhd: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2846036306 Base.92nissanGTRlhd: the dashboard shows with a design
ZEDQA cv PASS 2846036306 Base.92nissanGTRlhd: the dashboard is on screen
ZEDQA cv 2846036306 Base.92nissanGTRlhd: Vehicle tab true, 52 parts
ZEDQA cv PASS 2846036306 Base.92nissanGTRlhd: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2870394916 Base.86fordE150: spawns
ZEDQA cv 2870394916 Base.86fordE150: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2870394916 Base.86fordE150: the dashboard shows with a design
ZEDQA cv PASS 2870394916 Base.86fordE150: the dashboard is on screen
ZEDQA cv 2870394916 Base.86fordE150: Vehicle tab true, 49 parts
ZEDQA cv PASS 2870394916 Base.86fordE150: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2870394916 Base.86fordE150dnd: spawns
ZEDQA cv 2870394916 Base.86fordE150dnd: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2870394916 Base.86fordE150dnd: the dashboard shows with a design
ZEDQA cv PASS 2870394916 Base.86fordE150dnd: the dashboard is on screen
ZEDQA cv 2870394916 Base.86fordE150dnd: Vehicle tab true, 55 parts
ZEDQA cv PASS 2870394916 Base.86fordE150dnd: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2870394916 Base.86fordE150LBMWradio: spawns
ZEDQA cv 2870394916 Base.86fordE150LBMWradio: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2870394916 Base.86fordE150LBMWradio: the dashboard shows with a design
ZEDQA cv PASS 2870394916 Base.86fordE150LBMWradio: the dashboard is on screen
ZEDQA cv 2870394916 Base.86fordE150LBMWradio: Vehicle tab true, 50 parts
ZEDQA cv PASS 2870394916 Base.86fordE150LBMWradio: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2870394916 Base.86fordE150LVairportShuttle: spawns
ZEDQA cv 2870394916 Base.86fordE150LVairportShuttle: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2870394916 Base.86fordE150LVairportShuttle: the dashboard shows with a design
ZEDQA cv PASS 2870394916 Base.86fordE150LVairportShuttle: the dashboard is on screen
ZEDQA cv 2870394916 Base.86fordE150LVairportShuttle: Vehicle tab true, 62 parts
ZEDQA cv PASS 2870394916 Base.86fordE150LVairportShuttle: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2873290424 Base.70dodgeBG: spawns
ZEDQA cv 2873290424 Base.70dodgeBG: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2873290424 Base.70dodgeBG: the dashboard shows with a design
ZEDQA cv PASS 2873290424 Base.70dodgeBG: the dashboard is on screen
ZEDQA cv 2873290424 Base.70dodgeBG: Vehicle tab true, 49 parts
ZEDQA cv PASS 2873290424 Base.70dodgeBG: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2873290424 Base.70dodgeOP: spawns
ZEDQA cv 2873290424 Base.70dodgeOP: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2873290424 Base.70dodgeOP: the dashboard shows with a design
ZEDQA cv PASS 2873290424 Base.70dodgeOP: the dashboard is on screen
ZEDQA cv 2873290424 Base.70dodgeOP: Vehicle tab true, 49 parts
ZEDQA cv PASS 2873290424 Base.70dodgeOP: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2886832257 Base.82jeepJ10: spawns
ZEDQA cv 2886832257 Base.82jeepJ10: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2886832257 Base.82jeepJ10: the dashboard shows with a design
ZEDQA cv PASS 2886832257 Base.82jeepJ10: the dashboard is on screen
ZEDQA cv 2886832257 Base.82jeepJ10: Vehicle tab true, 47 parts
ZEDQA cv PASS 2886832257 Base.82jeepJ10: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2886832257 Base.82jeepJ10pd: spawns
ZEDQA cv 2886832257 Base.82jeepJ10pd: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2886832257 Base.82jeepJ10pd: the dashboard shows with a design
ZEDQA cv PASS 2886832257 Base.82jeepJ10pd: the dashboard is on screen
ZEDQA cv 2886832257 Base.82jeepJ10pd: Vehicle tab true, 49 parts
ZEDQA cv PASS 2886832257 Base.82jeepJ10pd: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2886832936 Base.88chevyS10: spawns
ZEDQA cv 2886832936 Base.88chevyS10: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2886832936 Base.88chevyS10: the dashboard shows with a design
ZEDQA cv PASS 2886832936 Base.88chevyS10: the dashboard is on screen
ZEDQA cv 2886832936 Base.88chevyS10: Vehicle tab true, 47 parts
ZEDQA cv PASS 2886832936 Base.88chevyS10: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2886833398 Base.89fordBronco: spawns
ZEDQA cv 2886833398 Base.89fordBronco: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2886833398 Base.89fordBronco: the dashboard shows with a design
ZEDQA cv PASS 2886833398 Base.89fordBronco: the dashboard is on screen
ZEDQA cv 2886833398 Base.89fordBronco: Vehicle tab true, 53 parts
ZEDQA cv PASS 2886833398 Base.89fordBronco: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2886833398 Base.89fordBroncoPD: spawns
ZEDQA cv 2886833398 Base.89fordBroncoPD: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2886833398 Base.89fordBroncoPD: the dashboard shows with a design
ZEDQA cv PASS 2886833398 Base.89fordBroncoPD: the dashboard is on screen
ZEDQA cv 2886833398 Base.89fordBroncoPD: Vehicle tab true, 55 parts
ZEDQA cv PASS 2886833398 Base.89fordBroncoPD: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2897390033 Base.97bushAmbulance: spawns
ZEDQA cv 2897390033 Base.97bushAmbulance: design ambulance, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2897390033 Base.97bushAmbulance: the dashboard shows with a design
ZEDQA cv PASS 2897390033 Base.97bushAmbulance: the dashboard is on screen
ZEDQA cv 2897390033 Base.97bushAmbulance: Vehicle tab true, 67 parts
ZEDQA cv PASS 2897390033 Base.97bushAmbulance: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2897390033 Base.97bushmaster: spawns
ZEDQA cv 2897390033 Base.97bushmaster: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2897390033 Base.97bushmaster: the dashboard shows with a design
ZEDQA cv PASS 2897390033 Base.97bushmaster: the dashboard is on screen
ZEDQA cv 2897390033 Base.97bushmaster: Vehicle tab true, 71 parts
ZEDQA cv PASS 2897390033 Base.97bushmaster: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2900580391 Base.49powerWagon: spawns
ZEDQA cv 2900580391 Base.49powerWagon: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2900580391 Base.49powerWagon: the dashboard shows with a design
ZEDQA cv PASS 2900580391 Base.49powerWagon: the dashboard is on screen
ZEDQA cv 2900580391 Base.49powerWagon: Vehicle tab true, 58 parts
ZEDQA cv PASS 2900580391 Base.49powerWagon: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2900580391 Base.49powerWagonMP: spawns
ZEDQA cv 2900580391 Base.49powerWagonMP: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2900580391 Base.49powerWagonMP: the dashboard shows with a design
ZEDQA cv PASS 2900580391 Base.49powerWagonMP: the dashboard is on screen
ZEDQA cv 2900580391 Base.49powerWagonMP: Vehicle tab true, 59 parts
ZEDQA cv PASS 2900580391 Base.49powerWagonMP: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2913633066 Base.70barracuda: spawns
ZEDQA cv 2913633066 Base.70barracuda: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2913633066 Base.70barracuda: the dashboard shows with a design
ZEDQA cv PASS 2913633066 Base.70barracuda: the dashboard is on screen
ZEDQA cv 2913633066 Base.70barracuda: Vehicle tab true, 49 parts
ZEDQA cv PASS 2913633066 Base.70barracuda: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2913633066 Base.70barracudaAAR: spawns
ZEDQA cv 2913633066 Base.70barracudaAAR: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2913633066 Base.70barracudaAAR: the dashboard shows with a design
ZEDQA cv PASS 2913633066 Base.70barracudaAAR: the dashboard is on screen
ZEDQA cv 2913633066 Base.70barracudaAAR: Vehicle tab true, 49 parts
ZEDQA cv PASS 2913633066 Base.70barracudaAAR: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2932547723 Base.93townCar: spawns
ZEDQA cv 2932547723 Base.93townCar: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2932547723 Base.93townCar: the dashboard shows with a design
ZEDQA cv PASS 2932547723 Base.93townCar: the dashboard is on screen
ZEDQA cv 2932547723 Base.93townCar: Vehicle tab true, 52 parts
ZEDQA cv PASS 2932547723 Base.93townCar: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2932547723 Base.93townCarLimo: spawns
ZEDQA cv 2932547723 Base.93townCarLimo: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2932547723 Base.93townCarLimo: the dashboard shows with a design
ZEDQA cv PASS 2932547723 Base.93townCarLimo: the dashboard is on screen
ZEDQA cv 2932547723 Base.93townCarLimo: Vehicle tab true, 62 parts
ZEDQA cv PASS 2932547723 Base.93townCarLimo: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2932549988 Base.89trooper: spawns
ZEDQA cv 2932549988 Base.89trooper: design police, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2932549988 Base.89trooper: the dashboard shows with a design
ZEDQA cv PASS 2932549988 Base.89trooper: the dashboard is on screen
ZEDQA cv 2932549988 Base.89trooper: Vehicle tab true, 58 parts
ZEDQA cv PASS 2932549988 Base.89trooper: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2932549988 Base.89trooperOP: spawns
ZEDQA cv 2932549988 Base.89trooperOP: design police, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2932549988 Base.89trooperOP: the dashboard shows with a design
ZEDQA cv PASS 2932549988 Base.89trooperOP: the dashboard is on screen
ZEDQA cv 2932549988 Base.89trooperOP: Vehicle tab true, 61 parts
ZEDQA cv PASS 2932549988 Base.89trooperOP: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2937786633 Base.69mini: spawns
ZEDQA cv 2937786633 Base.69mini: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2937786633 Base.69mini: the dashboard shows with a design
ZEDQA cv PASS 2937786633 Base.69mini: the dashboard is on screen
ZEDQA cv 2937786633 Base.69mini: Vehicle tab true, 50 parts
ZEDQA cv PASS 2937786633 Base.69mini: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2937786633 Base.69miniIJ: spawns
ZEDQA cv 2937786633 Base.69miniIJ: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2937786633 Base.69miniIJ: the dashboard shows with a design
ZEDQA cv PASS 2937786633 Base.69miniIJ: the dashboard is on screen
ZEDQA cv 2937786633 Base.69miniIJ: Vehicle tab true, 50 parts
ZEDQA cv PASS 2937786633 Base.69miniIJ: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2942793445 Base.90pierceArrow: spawns
ZEDQA cv 2942793445 Base.90pierceArrow: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2942793445 Base.90pierceArrow: the dashboard shows with a design
ZEDQA cv PASS 2942793445 Base.90pierceArrow: the dashboard is on screen
ZEDQA cv 2942793445 Base.90pierceArrow: Vehicle tab true, 66 parts
ZEDQA cv PASS 2942793445 Base.90pierceArrow: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2942793445 Base.90pierceArrowQuint: spawns
ZEDQA cv 2942793445 Base.90pierceArrowQuint: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2942793445 Base.90pierceArrowQuint: the dashboard shows with a design
ZEDQA cv PASS 2942793445 Base.90pierceArrowQuint: the dashboard is on screen
ZEDQA cv 2942793445 Base.90pierceArrowQuint: Vehicle tab true, 68 parts
ZEDQA cv PASS 2942793445 Base.90pierceArrowQuint: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2952802178 Base.90fordF350ambulance: spawns
ZEDQA cv 2952802178 Base.90fordF350ambulance: design ambulance, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2952802178 Base.90fordF350ambulance: the dashboard shows with a design
ZEDQA cv PASS 2952802178 Base.90fordF350ambulance: the dashboard is on screen
ZEDQA cv 2952802178 Base.90fordF350ambulance: Vehicle tab true, 61 parts
ZEDQA cv PASS 2952802178 Base.90fordF350ambulance: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2952802178 Base.90fordF350SWAT: spawns
ZEDQA cv 2952802178 Base.90fordF350SWAT: design police, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2952802178 Base.90fordF350SWAT: the dashboard shows with a design
ZEDQA cv PASS 2952802178 Base.90fordF350SWAT: the dashboard is on screen
ZEDQA cv 2952802178 Base.90fordF350SWAT: Vehicle tab true, 61 parts
ZEDQA cv PASS 2952802178 Base.90fordF350SWAT: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2962175696 Base.92fordCV: spawns
ZEDQA cv 2962175696 Base.92fordCV: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2962175696 Base.92fordCV: the dashboard shows with a design
ZEDQA cv PASS 2962175696 Base.92fordCV: the dashboard is on screen
ZEDQA cv 2962175696 Base.92fordCV: Vehicle tab true, 51 parts
ZEDQA cv PASS 2962175696 Base.92fordCV: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2962175696 Base.92fordCVPI: spawns
ZEDQA cv 2962175696 Base.92fordCVPI: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2962175696 Base.92fordCVPI: the dashboard shows with a design
ZEDQA cv PASS 2962175696 Base.92fordCVPI: the dashboard is on screen
ZEDQA cv 2962175696 Base.92fordCVPI: Vehicle tab true, 55 parts
ZEDQA cv PASS 2962175696 Base.92fordCVPI: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2991201484 Base.69camaroRS: spawns
ZEDQA cv 2991201484 Base.69camaroRS: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2991201484 Base.69camaroRS: the dashboard shows with a design
ZEDQA cv PASS 2991201484 Base.69camaroRS: the dashboard is on screen
ZEDQA cv 2991201484 Base.69camaroRS: Vehicle tab true, 49 parts
ZEDQA cv PASS 2991201484 Base.69camaroRS: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 2991201484 Base.69camaroSS: spawns
ZEDQA cv 2991201484 Base.69camaroSS: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 2991201484 Base.69camaroSS: the dashboard shows with a design
ZEDQA cv PASS 2991201484 Base.69camaroSS: the dashboard is on screen
ZEDQA cv 2991201484 Base.69camaroSS: Vehicle tab true, 49 parts
ZEDQA cv PASS 2991201484 Base.69camaroSS: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 3001592312 Base.93mustangGT: spawns
ZEDQA cv 3001592312 Base.93mustangGT: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 3001592312 Base.93mustangGT: the dashboard shows with a design
ZEDQA cv PASS 3001592312 Base.93mustangGT: the dashboard is on screen
ZEDQA cv 3001592312 Base.93mustangGT: Vehicle tab true, 52 parts
ZEDQA cv PASS 3001592312 Base.93mustangGT: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 3001592312 Base.93mustangSSP: spawns
ZEDQA cv 3001592312 Base.93mustangSSP: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 3001592312 Base.93mustangSSP: the dashboard shows with a design
ZEDQA cv PASS 3001592312 Base.93mustangSSP: the dashboard is on screen
ZEDQA cv 3001592312 Base.93mustangSSP: Vehicle tab true, 51 parts
ZEDQA cv PASS 3001592312 Base.93mustangSSP: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 3005903549 Base.63beetle: spawns
ZEDQA cv 3005903549 Base.63beetle: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 3005903549 Base.63beetle: the dashboard shows with a design
ZEDQA cv PASS 3005903549 Base.63beetle: the dashboard is on screen
ZEDQA cv 3005903549 Base.63beetle: Vehicle tab true, 53 parts
ZEDQA cv PASS 3005903549 Base.63beetle: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 3005903549 Base.63beetleBuggy: spawns
ZEDQA cv 3005903549 Base.63beetleBuggy: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 3005903549 Base.63beetleBuggy: the dashboard shows with a design
ZEDQA cv PASS 3005903549 Base.63beetleBuggy: the dashboard is on screen
ZEDQA cv 3005903549 Base.63beetleBuggy: Vehicle tab true, 53 parts
ZEDQA cv PASS 3005903549 Base.63beetleBuggy: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 3026723485 Base.67gt500: spawns
ZEDQA cv 3026723485 Base.67gt500: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 3026723485 Base.67gt500: the dashboard shows with a design
ZEDQA cv PASS 3026723485 Base.67gt500: the dashboard is on screen
ZEDQA cv 3026723485 Base.67gt500: Vehicle tab true, 46 parts
ZEDQA cv PASS 3026723485 Base.67gt500: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 3026723485 Base.67gt500e: spawns
ZEDQA cv 3026723485 Base.67gt500e: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 3026723485 Base.67gt500e: the dashboard shows with a design
ZEDQA cv PASS 3026723485 Base.67gt500e: the dashboard is on screen
ZEDQA cv 3026723485 Base.67gt500e: Vehicle tab true, 46 parts
ZEDQA cv PASS 3026723485 Base.67gt500e: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 3041122351 Base.63Type2Van: spawns
ZEDQA cv 3041122351 Base.63Type2Van: design nyala, dashboard true at 1120,1804 1600x344
ZEDQA cv PASS 3041122351 Base.63Type2Van: the dashboard shows with a design
ZEDQA cv PASS 3041122351 Base.63Type2Van: the dashboard is on screen
ZEDQA cv 3041122351 Base.63Type2Van: Vehicle tab true, 66 parts
ZEDQA cv PASS 3041122351 Base.63Type2Van: the World window's Vehicle tab opens beside it
ZEDQA cv PASS 3041122351 Base.63Type2VanApocalypse: spawns
ZEDQA cv 3041122351 Base.63Type2VanApocalypse: design nyala, dashboard true at 1120,1804 1600x344
... (119 more lines; see console.txt)
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    3x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Body"
```
