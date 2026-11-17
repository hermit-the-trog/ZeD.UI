# ZeD-UI regression - 2026-11-17 15:33 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-17 15:33:15 |
| Finished | 2026-11-17 15:39:57 (6 min 41 s) |
| Mode | windowed (1280x800 window) |
| Display | fontSize=2 fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\zedqa_b19_light_popups.txt (4 scripts) |
| Result | **3/4 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 28360 to 28365 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1920,1080) of 3840x2160; pointer parked at (3836,2156)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28364, 28365)
- pzrestorewin.ps1: fullScreen=false height=2160 width=3840
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 7 |  |  |
| 2 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 3 | zedqa_b19_light_popups.lua | lpp | **FAIL** | 292 |  | 18 Java exception(s) in the log; 45 ERR line(s); late output from unl (243 line(s), not counted) |
| 4 | gallery_reload.lua | rel | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 7 s

- go 28360 at 15:34:21

```text
[ZeD.QA] state #1 speed=1 paused=false player=928,13040 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 928,13040,0 to the drag strip
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1022,0 888x840 rolled false pinned true/true
ZEDQA pre layout world 1930,0 888x840 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta19 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28361 at 15:34:32

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 50.0 of 8 kg, 117 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 60 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 8.2 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #2 ok=true
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (x3)
```

### 3. zedqa_b19_light_popups.lua (`ZEDQA lpp`) - FAIL, 292 s

- go 28362 at 15:34:36
- 18 Java exception(s) in the log
- 45 ERR line(s)
- late output from unl (243 line(s), not counted)

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA lpp start (309 steps)
[ZeD.QA] run #3 ok=true
ZEDQA lpp start: carried 8.2 of 8 kg
ZEDQA lpp theme dark / teal
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_left_note
ZEDQA lpp FAIL dark_mood_left_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_left
ZEDQA lpp FAIL dark_mood_left: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_bottom_note
ZEDQA lpp FAIL dark_mood_bottom_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_bottom
ZEDQA lpp FAIL dark_mood_bottom: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_right_note
ZEDQA lpp FAIL dark_mood_right_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_right
ZEDQA lpp FAIL dark_mood_right: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.2 of 20 kg, 58 items, Heavy Load 0   (late output from unl)
ZEDQA ff speed 3: time multiplier 20, true multiplier 20
ZEDQA lpp dark_simple_read: the bar reads phase work, noend false, bar queue 0/1, progress 0.31, 1 queued
ZEDQA lpp shot lpp_dark_simple_read
ZEDQA lpp dark_simple_read: colors drawn, most area first: 0.26,0.26,0.26 (279360), 0.10,0.10,0.12 (114240), 0.80,0.80,0.80 (101760), 0.20,0.20,0.22 (64000), 0.05,0.05,0.05 (15360), 0.28,0.63,0.55 (6960)
ZEDQA unl load 9.2 of 20 kg, 58 items, Heavy Load 0   (late output from unl)
ZEDQA lpp progress 0.41 (wanted 0.40)
ZEDQA lpp dark_simple_stopped: stopped at progress 0.41
ERROR: General f:2240 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:2240> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp dark_simple_stopped: the bar reads phase stopped, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_dark_simple_stopped
ZEDQA lpp dark_simple_stopped: colors drawn, most area first: 0.26,0.26,0.26 (9540), 0.10,0.10,0.12 (7140), 0.20,0.20,0.22 (4000), 0.54,0.54,0.56 (1600)
ZEDQA unl load 9.2 of 20 kg, 58 items, Heavy Load 0   (late output from unl)   (x6)
ERROR: General f:2866 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:2866> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp dark_simple_rest: the bar reads phase nil, noend nil, bar queue nil/nil, progress -1.00, 0 queued (taken anyway)
ZEDQA lpp shot lpp_dark_simple_rest
ZEDQA lpp dark_simple_rest: colors drawn, most area first: 0.26,0.26,0.26 (3545600), 0.80,0.80,0.80 (3273600), 0.77,0.35,0.16 (7200)
ZEDQA unl load 9.2 of 20 kg, 58 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp dark_simple_walk: the bar reads phase walk, noend true, bar queue 0/1, progress 0.00, 2 queued
ZEDQA lpp shot lpp_dark_simple_walk
ZEDQA lpp dark_simple_walk: colors drawn, most area first: none caught
ZEDQA unl load 9.2 of 20 kg, 58 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark_simple_queue: the bar reads phase work, noend false, bar queue 0/3, progress 0.61, 3 queued
ZEDQA lpp shot lpp_dark_simple_queue
ZEDQA lpp dark_simple_queue: colors drawn, most area first: 0.26,0.26,0.26 (52380), 0.10,0.10,0.12 (21420), 0.80,0.80,0.80 (19080), 0.20,0.20,0.22 (12000), 0.05,0.05,0.05 (2880), 0.28,0.63,0.55 (560)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.7 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark_simple_queue2: the bar reads phase work, noend false, bar queue 1/3, progress 0.50, 2 queued
ZEDQA lpp shot lpp_dark_simple_queue2
ZEDQA lpp dark_simple_queue2: colors drawn, most area first: 0.26,0.26,0.26 (69840), 0.10,0.10,0.12 (28560), 0.80,0.80,0.80 (25440), 0.20,0.20,0.22 (16000), 0.28,0.63,0.55 (4720), 0.05,0.05,0.05 (3840)
ZEDQA unl load 9.7 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 9.9 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x5)
ERROR: General f:3941 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:3941> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp dark_simple_done: the bar reads phase done, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_dark_simple_done
ZEDQA lpp dark_simple_done: colors drawn, most area first: 0.26,0.26,0.26 (553320), 0.10,0.10,0.12 (414120), 0.20,0.20,0.22 (232000), 0.28,0.63,0.55 (104000), 0.36,0.77,0.67 (20800), 0.12,0.49,0.13 (1600)
ZEDQA unl load 9.9 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp dark_detailed_read: the bar reads phase work, noend false, bar queue 0/1, progress 0.31, 1 queued
ZEDQA lpp shot lpp_dark_detailed_read
ZEDQA lpp dark_detailed_read: colors drawn, most area first: 0.80,0.80,0.80 (1060096), 0.26,0.26,0.26 (259456), 0.10,0.10,0.12 (149184), 0.28,0.63,0.55 (52736), 0.05,0.05,0.05 (15360)
ZEDQA unl load 9.9 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA lpp progress 0.40 (wanted 0.40)
ZEDQA lpp dark_detailed_stopped: stopped at progress 0.40
ERROR: General f:4225 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:4225> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp dark_detailed_stopped: the bar reads phase stopped, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_dark_detailed_stopped
ZEDQA lpp dark_detailed_stopped: colors drawn, most area first: 0.80,0.80,0.80 (60780), 0.10,0.10,0.12 (9480), 0.26,0.26,0.26 (8400), 0.54,0.54,0.56 (2480)
ZEDQA unl load 9.9 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x6)
ERROR: General f:4864 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:4864> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp dark_detailed_rest: the bar reads phase nil, noend nil, bar queue nil/nil, progress -1.00, 0 queued (taken anyway)
ZEDQA lpp shot lpp_dark_detailed_rest
ZEDQA lpp dark_detailed_rest: colors drawn, most area first: none caught
ZEDQA unl load 9.9 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp dark_detailed_walk: the bar reads phase walk, noend true, bar queue 0/1, progress 0.00, 2 queued
ZEDQA lpp shot lpp_dark_detailed_walk
ZEDQA lpp dark_detailed_walk: colors drawn, most area first: 0.80,0.80,0.80 (53300), 0.26,0.26,0.26 (4640)
ZEDQA unl load 9.9 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 10.5 of 20 kg, 65 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark_detailed_queue: the bar reads phase work, noend false, bar queue 0/3, progress 0.61, 3 queued
ZEDQA lpp shot lpp_dark_detailed_queue
ZEDQA lpp dark_detailed_queue: colors drawn, most area first: 0.80,0.80,0.80 (162660), 0.26,0.26,0.26 (44400), 0.10,0.10,0.12 (21600), 0.28,0.63,0.55 (6864), 0.05,0.05,0.05 (4800), 0.20,0.20,0.22 (480)
ZEDQA unl load 10.5 of 20 kg, 65 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 10.4 of 20 kg, 65 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark_detailed_queue2: the bar reads phase work, noend false, bar queue 1/3, progress 0.35, 2 queued
ZEDQA lpp shot lpp_dark_detailed_queue2
ZEDQA lpp dark_detailed_queue2: colors drawn, most area first: 0.80,0.80,0.80 (162660), 0.26,0.26,0.26 (44400), 0.10,0.10,0.12 (21600), 0.28,0.63,0.55 (10112), 0.05,0.05,0.05 (4960), 0.20,0.20,0.22 (480)
ZEDQA unl load 10.4 of 20 kg, 65 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 10.6 of 20 kg, 66 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)
ERROR: General f:5925 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:5925> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp dark_detailed_done: the bar reads phase done, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_dark_detailed_done
ZEDQA lpp dark_detailed_done: colors drawn, most area first: 0.80,0.80,0.80 (2775880), 0.10,0.10,0.12 (417600), 0.26,0.26,0.26 (399040), 0.28,0.63,0.55 (241488), 0.12,0.49,0.13 (1204)
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_dark_notice_mod
ZEDQA lpp FAIL dark_notice_mod: the fill is the tooltips' light grey (0.26,0.26,0.26 (1074000), 0.80,0.80,0.80 (990240), 0.77,0.60,0.16 (2160))
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_notice_mod_hover
ZEDQA lpp FAIL dark_notice_mod_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (1074000), 0.80,0.80,0.80 (990240), 0.77,0.60,0.16 (2160))
ZEDQA lpp PASS dark_notice_mod_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_dark_notice_guide
ZEDQA lpp FAIL dark_notice_guide: the fill is the tooltips' light grey (0.26,0.26,0.26 (3060480), 0.80,0.80,0.80 (2961920), 0.77,0.60,0.16 (1440))
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_notice_guide_hover
ZEDQA lpp FAIL dark_notice_guide_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (2295360), 0.80,0.80,0.80 (2221440), 0.77,0.60,0.16 (1080))
ZEDQA lpp PASS dark_notice_guide_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_speech
ZEDQA lpp FAIL dark_speech: the fill is the tooltips' light grey (0.26,0.26,0.26 (877280), 0.80,0.80,0.80 (825120))
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)   (x6)
ZEDQA lpp shot lpp_dark_speed
ZEDQA lpp FAIL dark_speed: the fill is the tooltips' light grey (0.26,0.26,0.26 (49760), 0.80,0.80,0.80 (38880), 0.05,0.05,0.05 (5120))
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark pause: the queue still steps while paused (656 ms on, speed 0)
ZEDQA lpp shot lpp_dark_pause
ZEDQA lpp FAIL dark_pause: the fill is the tooltips' light grey (0.26,0.26,0.26 (41600), 0.80,0.80,0.80 (31680), 0.05,0.05,0.05 (4480))
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_halo_red
ZEDQA lpp FAIL dark_halo_red: the fill is the tooltips' light grey (0.26,0.26,0.26 (183040), 0.80,0.80,0.80 (156480), 0.75,0.11,0.11 (1440))
ZEDQA lpp PASS dark_halo_red: the red note keeps its color (0.75,0.11,0.11 drawn)
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_halo_green
ZEDQA lpp FAIL dark_halo_green: the fill is the tooltips' light grey (0.26,0.26,0.26 (332640), 0.80,0.80,0.80 (288480), 0.12,0.49,0.13 (1440))
ZEDQA lpp PASS dark_halo_green: the green note keeps its color (0.12,0.49,0.13 drawn)
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)
ZEDQA lpp theme light / teal
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 10.5 of 17 kg, 66 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_mood_left_note
ZEDQA lpp FAIL light_mood_left_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.5 of 17 kg, 66 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_left
ZEDQA lpp FAIL light_mood_left: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.5 of 17 kg, 66 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_bottom_note
ZEDQA lpp FAIL light_mood_bottom_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.5 of 17 kg, 66 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_bottom
ZEDQA lpp FAIL light_mood_bottom: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.5 of 17 kg, 66 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_right_note
ZEDQA lpp FAIL light_mood_right_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.5 of 17 kg, 66 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_right
ZEDQA lpp FAIL light_mood_right: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.5 of 17 kg, 66 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light_simple_read: the bar reads phase work, noend false, bar queue 0/1, progress 0.31, 1 queued
ZEDQA lpp shot lpp_light_simple_read
ZEDQA lpp light_simple_read: colors drawn, most area first: 0.26,0.26,0.26 (296820), 0.10,0.10,0.12 (121380), 0.80,0.80,0.80 (108120), 0.20,0.20,0.22 (68000), 0.05,0.05,0.05 (16320), 0.28,0.63,0.55 (7360)
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)
ZEDQA lpp progress 0.41 (wanted 0.40)
ZEDQA lpp light_simple_stopped: stopped at progress 0.41
ERROR: General f:8929 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:8929> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp light_simple_stopped: the bar reads phase stopped, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_light_simple_stopped
ZEDQA lpp light_simple_stopped: colors drawn, most area first: 0.26,0.26,0.26 (9540), 0.10,0.10,0.12 (7140), 0.20,0.20,0.22 (4000), 0.54,0.54,0.56 (1600)
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)   (x6)
ERROR: General f:9572 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:9572> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp light_simple_rest: the bar reads phase nil, noend nil, bar queue nil/nil, progress -1.00, 0 queued (taken anyway)
ZEDQA lpp shot lpp_light_simple_rest
ZEDQA lpp light_simple_rest: colors drawn, most area first: 0.26,0.26,0.26 (3545600), 0.80,0.80,0.80 (3273600), 0.48,0.16,0.07 (7200)
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp light_simple_walk: the bar reads phase walk, noend true, bar queue 0/1, progress 0.00, 2 queued
ZEDQA lpp shot lpp_light_simple_walk
ZEDQA lpp light_simple_walk: colors drawn, most area first: none caught
ZEDQA unl load 10.5 of 20 kg, 66 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 11.1 of 20 kg, 69 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light_simple_queue: the bar reads phase work, noend false, bar queue 0/3, progress 0.52, 3 queued
ZEDQA lpp shot lpp_light_simple_queue
ZEDQA lpp light_simple_queue: colors drawn, most area first: 0.26,0.26,0.26 (52380), 0.10,0.10,0.12 (21420), 0.80,0.80,0.80 (19080), 0.20,0.20,0.22 (12000), 0.05,0.05,0.05 (2880), 0.28,0.63,0.55 (560)
ZEDQA unl load 11.1 of 20 kg, 69 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light_simple_queue2: the bar reads phase work, noend false, bar queue 1/3, progress 0.38, 2 queued
ZEDQA lpp shot lpp_light_simple_queue2
ZEDQA lpp light_simple_queue2: colors drawn, most area first: 0.26,0.26,0.26 (87300), 0.10,0.10,0.12 (35700), 0.80,0.80,0.80 (31800), 0.20,0.20,0.22 (20000), 0.28,0.63,0.55 (5360), 0.05,0.05,0.05 (4800)
ZEDQA unl load 11.1 of 20 kg, 69 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 11.3 of 20 kg, 70 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA unl load 11.2 of 20 kg, 70 items, Heavy Load 0   (late output from unl)
ERROR: General f:10652 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:10652> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp light_simple_done: the bar reads phase done, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_light_simple_done
ZEDQA lpp light_simple_done: colors drawn, most area first: 0.26,0.26,0.26 (553320), 0.10,0.10,0.12 (414120), 0.20,0.20,0.22 (232000), 0.28,0.63,0.55 (104640), 0.36,0.77,0.67 (20928), 0.12,0.49,0.13 (1600)
ZEDQA unl load 11.2 of 20 kg, 70 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp light_detailed_read: the bar reads phase work, noend false, bar queue 0/1, progress 0.31, 1 queued
ZEDQA lpp shot lpp_light_detailed_read
ZEDQA lpp light_detailed_read: colors drawn, most area first: 0.80,0.80,0.80 (1192200), 0.26,0.26,0.26 (291840), 0.10,0.10,0.12 (167760), 0.10,0.40,0.33 (42120), 0.05,0.05,0.05 (17280), 0.28,0.63,0.55 (17008)
ZEDQA unl load 11.2 of 20 kg, 70 items, Heavy Load 0   (late output from unl)
ZEDQA lpp progress 0.42 (wanted 0.40)
ZEDQA lpp light_detailed_stopped: stopped at progress 0.42
ERROR: General f:10948 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:10948> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp light_detailed_stopped: the bar reads phase stopped, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_light_detailed_stopped
ZEDQA lpp light_detailed_stopped: colors drawn, most area first: 0.80,0.80,0.80 (60780), 0.10,0.10,0.12 (9480), 0.26,0.26,0.26 (8400), 0.54,0.54,0.56 (2560)
ZEDQA unl load 11.2 of 20 kg, 70 items, Heavy Load 0   (late output from unl)   (x6)
ERROR: General f:11592 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:11592> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp light_detailed_rest: the bar reads phase nil, noend nil, bar queue nil/nil, progress -1.00, 0 queued (taken anyway)
ZEDQA lpp shot lpp_light_detailed_rest
ZEDQA lpp light_detailed_rest: colors drawn, most area first: none caught
ZEDQA unl load 11.2 of 20 kg, 70 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp light_detailed_walk: the bar reads phase walk, noend true, bar queue 0/1, progress 0.00, 2 queued
ZEDQA lpp shot lpp_light_detailed_walk
ZEDQA lpp light_detailed_walk: colors drawn, most area first: 0.80,0.80,0.80 (53300), 0.26,0.26,0.26 (4640)
ZEDQA unl load 11.2 of 20 kg, 70 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 11.8 of 20 kg, 73 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light_detailed_queue: the bar reads phase work, noend false, bar queue 0/3, progress 0.54, 3 queued
ZEDQA lpp shot lpp_light_detailed_queue
ZEDQA lpp light_detailed_queue: colors drawn, most area first: 0.80,0.80,0.80 (162660), 0.26,0.26,0.26 (44400), 0.10,0.10,0.12 (21600), 0.10,0.40,0.33 (5520), 0.05,0.05,0.05 (4800), 0.28,0.63,0.55 (1264)
ZEDQA unl load 11.8 of 20 kg, 73 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light_detailed_queue2: the bar reads phase work, noend false, bar queue 1/3, progress 0.45, 2 queued
ZEDQA lpp shot lpp_light_detailed_queue2
ZEDQA lpp light_detailed_queue2: colors drawn, most area first: 0.80,0.80,0.80 (271100), 0.26,0.26,0.26 (74000), 0.10,0.10,0.12 (36000), 0.10,0.40,0.33 (9200), 0.05,0.05,0.05 (8240), 0.28,0.63,0.55 (7600)
ZEDQA unl load 11.8 of 20 kg, 73 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 12.0 of 20 kg, 74 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)
ERROR: General f:12681 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:12681> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp light_detailed_done: the bar reads phase done, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_light_detailed_done
ZEDQA lpp light_detailed_done: colors drawn, most area first: 0.80,0.80,0.80 (2775880), 0.10,0.10,0.12 (417600), 0.26,0.26,0.26 (399040), 0.28,0.63,0.55 (135136), 0.10,0.40,0.33 (106352), 0.12,0.49,0.13 (1204)
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_light_notice_mod
ZEDQA lpp FAIL light_notice_mod: the fill is the tooltips' light grey (0.26,0.26,0.26 (1074000), 0.80,0.80,0.80 (990240), 0.42,0.33,0.06 (2160))
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_notice_mod_hover
ZEDQA lpp FAIL light_notice_mod_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (1074000), 0.80,0.80,0.80 (990240), 0.42,0.33,0.06 (2160))
ZEDQA lpp PASS light_notice_mod_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_light_notice_guide
ZEDQA lpp FAIL light_notice_guide: the fill is the tooltips' light grey (0.26,0.26,0.26 (3060480), 0.80,0.80,0.80 (2961920), 0.42,0.33,0.06 (1440))
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_notice_guide_hover
ZEDQA lpp FAIL light_notice_guide_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (2295360), 0.80,0.80,0.80 (2221440), 0.42,0.33,0.06 (1080))
ZEDQA lpp PASS light_notice_guide_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_speech
ZEDQA lpp FAIL light_speech: the fill is the tooltips' light grey (0.26,0.26,0.26 (877280), 0.80,0.80,0.80 (825120))
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)   (x6)
ZEDQA lpp shot lpp_light_speed
ZEDQA lpp FAIL light_speed: the fill is the tooltips' light grey (0.26,0.26,0.26 (49760), 0.80,0.80,0.80 (38880), 0.05,0.05,0.05 (5120))
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light pause: the queue still steps while paused (658 ms on, speed 0)
ZEDQA lpp shot lpp_light_pause
ZEDQA lpp FAIL light_pause: the fill is the tooltips' light grey (0.26,0.26,0.26 (41600), 0.80,0.80,0.80 (31680), 0.05,0.05,0.05 (4480))
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_halo_red
ZEDQA lpp FAIL light_halo_red: the fill is the tooltips' light grey (0.26,0.26,0.26 (183040), 0.80,0.80,0.80 (156480), 0.75,0.11,0.11 (1440))
ZEDQA lpp PASS light_halo_red: the red note keeps its color (0.75,0.11,0.11 drawn)
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_halo_green
ZEDQA lpp FAIL light_halo_green: the fill is the tooltips' light grey (0.26,0.26,0.26 (332640), 0.80,0.80,0.80 (288480), 0.12,0.49,0.13 (1440))
ZEDQA lpp PASS light_halo_green: the green note keeps its color (0.12,0.49,0.13 drawn)
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA lpp theme hicon / teal
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 11.9 of 17 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_mood_left_note
ZEDQA lpp FAIL hicon_mood_left_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 11.9 of 17 kg, 74 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_left
ZEDQA lpp FAIL hicon_mood_left: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 11.9 of 17 kg, 74 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_bottom_note
ZEDQA lpp FAIL hicon_mood_bottom_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 11.9 of 17 kg, 74 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_bottom
ZEDQA lpp FAIL hicon_mood_bottom: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 11.9 of 17 kg, 74 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_right_note
ZEDQA lpp FAIL hicon_mood_right_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 11.9 of 17 kg, 74 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_right
ZEDQA lpp FAIL hicon_mood_right: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 11.9 of 17 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA lpp hicon_simple_read: the bar reads phase work, noend false, bar queue 0/1, progress 0.31, 1 queued
ZEDQA lpp shot lpp_hicon_simple_read
ZEDQA lpp hicon_simple_read: colors drawn, most area first: 0.26,0.26,0.26 (314280), 0.10,0.10,0.12 (128520), 0.80,0.80,0.80 (114480), 0.20,0.20,0.22 (72000), 0.05,0.05,0.05 (17280), 0.28,0.63,0.55 (7440)
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA lpp progress 0.41 (wanted 0.40)
ZEDQA lpp hicon_simple_stopped: stopped at progress 0.41
ERROR: General f:15712 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:15712> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp hicon_simple_stopped: the bar reads phase stopped, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_hicon_simple_stopped
ZEDQA lpp hicon_simple_stopped: colors drawn, most area first: 0.26,0.26,0.26 (9540), 0.10,0.10,0.12 (7140), 0.20,0.20,0.22 (4000), 0.54,0.54,0.56 (1600)
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)   (x6)
ERROR: General f:16356 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: action of non-table: null
ERROR: General f:16356> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: action of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:199)
    Lua(Vanilla).prog(spawnpoints.lua:199)
    Lua(Vanilla).step(spawnpoints.lua:216)
    Lua(Vanilla).tick(spawnpoints.lua:510)
ZEDQA lpp hicon_simple_rest: the bar reads phase nil, noend nil, bar queue nil/nil, progress -1.00, 0 queued (taken anyway)
ZEDQA lpp shot lpp_hicon_simple_rest
ZEDQA lpp hicon_simple_rest: colors drawn, most area first: 0.26,0.26,0.26 (3545600), 0.80,0.80,0.80 (3273600), 1.00,0.33,0.20 (7200)
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp hicon_simple_walk: the bar reads phase walk, noend true, bar queue 0/1, progress 0.00, 2 queued
ZEDQA lpp shot lpp_hicon_simple_walk
ZEDQA lpp hicon_simple_walk: colors drawn, most area first: none caught
ZEDQA unl load 11.9 of 20 kg, 74 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 12.5 of 20 kg, 77 items, Heavy Load 0   (late output from unl)
... (116 more lines; see console.txt)
```

### 4. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28363 at 15:39:31

```text
[ZeD.QA] state #4 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.2 of 20 kg, 57 items, Heavy Load 0
ZEDQA rel put back 60 things; after: 50.0 of 20 kg, 117 items, Heavy Load 1 OVER
[ZeD.QA] run #4 ok=true
ZEDQA rel DONE
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
