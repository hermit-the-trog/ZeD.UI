# ZeD-UI regression - 2026-11-17 18:18 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 18:18:37 |
| Finished | 2026-11-17 18:22:08 (3 min 31 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=6 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\gallery_v1_a_van.txt (12 scripts) |
| Result | **11/12 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 28606 to 28619 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=6 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28618, 28619)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 2 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 3 | gallery_b10_glasses.lua | gls | PASS | 1 |  |  |
| 4 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 5 | gallery_story_stage.lua | sts | PASS | 40 |  |  |
| 6 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 7 | gallery_v1_a_common.lua | g1c | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 8 | gallery_v1_a_van.lua | g1v | PASS | 18 |  | late output from unl (20 line(s), not counted) |
| 9 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 10 | gallery_story_teardown.lua | stt | **FAIL** | 10 |  | 4 Java exception(s) in the log; 1 ERR line(s) |
| 11 | gallery_v1_a_end.lua | g1e | PASS | 1 |  |  |
| 12 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28606 at 18:19:50

```text
ZEDQA g14l desk menu bar: Debug left out false
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look nil nil nil | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #1 ok=true
ZEDQA g14l DONE
```

### 2. gallery_daylight.lua (`ZEDQA day`) - PASS, 2 s

- go 28607 at 18:19:54

```text
ZEDQA day time 12.39 -> 11.00
[ZeD.QA] run #2 ok=true
ZEDQA day DONE
```

### 3. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 1 s

- go 28608 at 18:19:59

```text
ZEDQA gls wearing Base.Glasses_Prescription
[ZeD.QA] run #3 ok=true
ZEDQA gls DONE
```

### 4. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28609 at 18:20:04

```text
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #4 ok=true
ZEDQA hcn DONE
```

### 5. gallery_story_stage.lua (`ZEDQA sts`) - PASS, 40 s

- go 28610 at 18:20:08

```text
ZEDQA sts start (22 steps)
[ZeD.QA] run #5 ok=true
ZEDQA sts start at 12069,7144 | site: Fossoil, West Point | ZeD false
ZEDQA sts at the store: room fossoil, building true
ZEDQA sts stock spot 12053,7121 with 3 shelf containers in reach
ZEDQA sts counter 12054,7123 clerk 12053,7123 queue toward 1,0
ZEDQA sts pump 12066,7147 (location_shop_fossoil_01_13), 8 pump squares round the store
ZEDQA sts window 12063,7127, barricaded from 12063,7127
ZEDQA sts windows 9 (smashed 3, barricaded 0) | shelves 19 counters 7 other containers 13 | free floor 81
ZEDQA sts container types: cardboardbox=2 metal_shelves=1 shelves=14 shelvesmag=4 fridge=10 counter=7 cashregister=1
ZEDQA sts blood 12060,7121
ZEDQA sts smoke spot 12073,7130
ZEDQA sts aside: 18 worn, 4 on the belt, 45 items
ZEDQA sts worn: Tshirt_DefaultTEXTURE_TINT Shirt_Lumberjack Jacket_ArmyOliveDrab Vest_Hunting_Khaki Trousers_Denim Socks_Heavy Shoes_ArmyBoots Gloves_LeatherGlovesBlack Hat_BaseballCapGreen Belt2 HolsterSimple_Black Kneepad_Left_Tactical Kneepad_Right_Tactical WristWatch_Left_DigitalBlack Glasses_Prescription_Aviators Bag_ALICEpack_Army Bag_ChestRig Bag_FannyPackBack Bag_Satchel_Leather
ZEDQA sts bag back (Base.Bag_ALICEpack_Army): 13 things
ZEDQA sts bag webbing (Base.Bag_ChestRig): 3 things
ZEDQA sts bag fannypackback (Base.Bag_FannyPackBack): 2 things
ZEDQA sts bag satchel (Base.Bag_Satchel_Leather): 2 things
ZEDQA sts loose: 19/19
ZEDQA sts belt: HuntingKnife@smallbeltleft Hammer@smallbeltright Pistol@holsterright Shotgun@back
ZEDQA sts character was: profession base:mechanics, 10 traits on, 42 perks kept
ZEDQA sts profession base:mechanics | traits base:mechanics2 SMOKER SPEED_DEMON STRONG DEXTROUS FAST_READER PRONE_TO_ILLNESS HEARTY_APPETITE SLOW_HEALER PACIFIST | skills Strength=9 Fitness=5 Mechanics=4 MetalWelding=1
ZEDQA sts power: option set true | pump square grid power true, no-power zone false
ZEDQA sts pumps filled: 8 | the pump reads 500
ZEDQA sts car placements to try: 57
ZEDQA sts note: placement 1 (12068,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 2 (12068,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 3 (12067,7149 E) no good: pump false, tank area free false
ZEDQA sts note: placement 4 (12068,7148 N) no good: pump false, tank area free false
ZEDQA sts note: placement 5 (12068,7146 S) no good: pump false, tank area free false
ZEDQA sts note: placement 6 (12066,7150 E) no good: pump false, tank area free false
ZEDQA sts note: placement 7 (12069,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 8 (12066,7150 W) no good: pump false, tank area free false
ZEDQA sts note: placement 9 (12068,7148 S) no good: pump false, tank area free false
ZEDQA sts note: placement 10 (12067,7150 E) no good: pump false, tank area free false
ZEDQA sts note: placement 11 (12065,7150 W) no good: pump false, tank area free false
ZEDQA sts note: placement 12 (12068,7149 N) no good: pump false, tank area free false
ZEDQA sts note: placement 13 (12066,7151 E) no good: pump false, tank area free false
ZEDQA sts note: placement 14 (12069,7148 N) no good: pump false, tank area free false
ZEDQA sts note: placement 15 (12066,7152 E) no good: pump false, tank area free false
ZEDQA sts note: placement 16 (12066,7152 W) no good: pump false, tank area free false
ZEDQA sts note: placement 17 (12068,7154 N) no good: pump false, tank area free false
ZEDQA sts note: placement 18 (12068,7154 S) no good: pump false, tank area free false
ZEDQA sts note: placement 19 (12067,7156 E) no good: pump false, tank area free false
ZEDQA sts note: placement 20 (12068,7155 N) no good: pump false, tank area free false
ZEDQA sts note: placement 21 (12068,7153 S) no good: pump false, tank area free false
ZEDQA sts note: placement 22 (12069,7154 N) no good: pump false, tank area free false
ZEDQA sts note: placement 23 (12066,7151 W) no good: pump false, tank area free false
ZEDQA sts note: placement 24 (12068,7155 S) no good: pump false, tank area free false
ZEDQA sts note: placement 25 (12068,7156 N) no good: pump false, tank area free false
ZEDQA sts note: placement 26 (12069,7155 N) no good: pump false, tank area free false
ZEDQA sts note: placement 27 (12076,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 28 (12076,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 29 (12077,7149 W) no good: pump false, tank area free false
ZEDQA sts note: placement 30 (12078,7150 E) no good: pump false, tank area free false
ZEDQA sts note: placement 31 (12075,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 32 (12078,7150 W) no good: pump false, tank area free false
ZEDQA sts note: placement 33 (12076,7148 N) no good: pump false, tank area free false
ZEDQA sts note: placement 34 (12076,7148 S) no good: pump false, tank area free false
ZEDQA sts note: placement 35 (12079,7150 E) no good: pump false, tank area free false
ZEDQA sts note: placement 36 (12077,7150 W) no good: pump false, tank area free false
ZEDQA sts note: placement 37 (12078,7151 E) no good: pump false, tank area free false
ZEDQA sts note: placement 38 (12075,7148 S) no good: pump false, tank area free false
ZEDQA sts note: placement 39 (12078,7152 E) no good: pump false, tank area free false
ZEDQA sts note: placement 40 (12078,7152 W) no good: pump false, tank area free false
ZEDQA sts note: placement 41 (12080,7154 N) no good: pump false, tank area free false
ZEDQA sts note: placement 42 (12076,7154 N) no good: pump false, tank area free false
ZEDQA sts note: placement 43 (12080,7154 S) no good: pump false, tank area free false
ZEDQA sts note: placement 44 (12076,7154 S) no good: pump false, tank area free false
ZEDQA sts note: placement 45 (12079,7156 E) no good: pump false, tank area free false
ZEDQA sts note: placement 46 (12077,7156 W) no good: pump false, tank area free false
ZEDQA sts note: placement 47 (12080,7155 N) no good: pump false, tank area free false
ZEDQA sts note: placement 48 (12080,7153 S) no good: pump false, tank area free false
ZEDQA sts car Base.CarStationWagon at 12081,7154 facing N: the pump finder sees 12078,7154 | tank area 12079.8,7155.2
ZEDQA sts car fuel 3.5 / 59.0
ZEDQA sts native zombies near the store made useless: 21
ZEDQA sts passive zombies outside: 7
ZEDQA sts blood on 0 squares | stains read back true | blood decals option 10
ZEDQA sts zoom 1.5
ZEDQA sts shot story_00_scout ok
ZEDQA sts staged: car true | zombies 7 outside | blood 0 | carried 44
ZEDQA sts end: 1 shots ok, 0 errors
ZEDQA sts DONE
```

### 6. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28611 at 18:20:51

```text
ZEDQA unl before: 32.6 of 8 kg, 61 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 35 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #6 ok=true
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (x3)
```

### 7. gallery_v1_a_common.lua (`ZEDQA g1c`) - PASS, 1 s

- go 28612 at 18:20:55
- late output from unl (4 line(s), not counted)

```text
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)
ZEDQA g1c eyes at the start: glasses Base.Glasses_Prescription_Aviators, short sighted false, visual aid true, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3
ZEDQA g1c helpers ready | ZeD loaded false | story staged true | load 12.3 of 8 kg, 26 items, Heavy Load 1
[ZeD.QA] run #7 ok=true
ZEDQA g1c DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x3)
```

### 8. gallery_v1_a_van.lua (`ZEDQA g1v`) - PASS, 18 s

- go 28613 at 18:20:59
- late output from unl (20 line(s), not counted)

```text
ZEDQA g1v start (24 steps)
[ZeD.QA] run #8 ok=true
ZEDQA g1v bottom-right element UIElement / WaterMarkUI at 3380,2106 450x43
ZEDQA g1v hid the game's build line (WaterMarkUI)
ZEDQA g1v start at 12073,7130 | screen 3840x2160 | font size 6, inventory font Small, moodles 2
ZEDQA g1v shelf shelves at 12052,7121: 9 things it held set aside, 10 of 10 put in | capacity 50
ZEDQA g1v apples given: 3
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1v zoom 1
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA g1v apple group Apple (Fresh) opened: 4
ZEDQA g1v box default_pages character 1760,776-2080,1196
ZEDQA g1v box default_pages inventory 640,0-1920,720
ZEDQA g1v box default_pages loot 1920,0-3200,720
ZEDQA g1v box default_pages moodlesV 3782,120-3830,2280
ZEDQA g1v loot page shows the shelf true
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA g1v shot g1_17_vanilla
ZEDQA g1v load g1_17_vanilla: 12.9 of 18 kg, 29 items, Heavy Load 0
ZEDQA g1v eyes g1_17_vanilla: glasses Base.Glasses_Prescription_Aviators, short sighted false, visual aid true, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.04, view cone 3 | errors so far 0
ZEDQA g1v box g1_17_vanilla character 1760,776-2080,1196
ZEDQA g1v box g1_17_vanilla inventory 640,0-1920,720
ZEDQA g1v box g1_17_vanilla loot 1920,0-3200,720
ZEDQA g1v box g1_17_vanilla moodlesV 3782,120-3830,2280
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1v zoom 0.75
ZEDQA g1v moved the inventory page from x 640 to x 24 (left side): it covered the character
ZEDQA g1v moved the loot page from x 1920 to x 2536 (right side): it covered the character
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA g1v 01: the same moment as g1_17_vanilla, closer (zoom 0.75); if g1_17 reads at 116 x 65, 01 = 17's pair
ZEDQA g1v shot g1_01_vanilla
ZEDQA g1v load g1_01_vanilla: 12.9 of 18 kg, 29 items, Heavy Load 0
ZEDQA g1v eyes g1_01_vanilla: glasses Base.Glasses_Prescription_Aviators, short sighted false, visual aid true, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.06, view cone 3 | errors so far 0
ZEDQA g1v box g1_01_vanilla character 1706,675-2133,1235
ZEDQA g1v box g1_01_vanilla inventory 24,0-1304,720
ZEDQA g1v box g1_01_vanilla loot 2536,0-3816,720
ZEDQA g1v box g1_01_vanilla moodlesV 3782,120-3830,2280
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1v zoom 1
ZEDQA g1v apples taken back: 3
ZEDQA g1v shelf back: 9 things it held, 10 taken out
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1v left forearm: scratched false, bandaged true
ZEDQA unl load 12.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1v box default_info character 1760,776-2080,1196
ZEDQA g1v box default_info info 300,100-863,1227
ZEDQA g1v box default_info moodlesV 3782,120-3830,2280
ZEDQA g1v shot g1_26_vanilla
ZEDQA g1v load g1_26_vanilla: 12.3 of 18 kg, 28 items, Heavy Load 0
ZEDQA g1v eyes g1_26_vanilla: glasses Base.Glasses_Prescription_Aviators, short sighted false, visual aid true, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.08, view cone 3 | errors so far 0
ZEDQA g1v box g1_26_vanilla character 1760,776-2080,1196
ZEDQA g1v box g1_26_vanilla info 300,100-863,1227
ZEDQA g1v box g1_26_vanilla moodlesV 3782,120-3830,2280
ZEDQA unl load 12.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA g1v left forearm: scratched false, bandaged false
ZEDQA g1v apples taken back: 0
ZEDQA g1v glasses put on by the script taken off again: 0
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1v box put_back character 1760,776-2080,1196
ZEDQA g1v box put_back moodlesV 3782,120-3830,2280
ZEDQA g1v end: 3 shots, 0 not taken or failed
ZEDQA g1v DONE
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
```

### 9. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28614 at 18:21:21

```text
ZEDQA rel before: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA rel put back 35 things; after: 32.6 of 18 kg, 61 items, Heavy Load 1 OVER
[ZeD.QA] run #9 ok=true
ZEDQA rel DONE
```

### 10. gallery_story_teardown.lua (`ZEDQA stt`) - FAIL, 10 s

- go 28615 at 18:21:25
- 4 Java exception(s) in the log
- 1 ERR line(s)

```text
ZEDQA stt start (17 steps)
[ZeD.QA] run #10 ok=true
ERROR: General f:10039 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: isOpen of non-table: null
ERROR: General f:10039> Lua(Vanilla).step> Exception thrown
    java.lang.RuntimeException: attempted index: isOpen of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).step(spawnpoints.lua:24)
    Lua(Vanilla).onFrame(spawnpoints.lua:114)
ZEDQA stt ERR step 1 attempted index: isOpen of non-table: null java.lang.RuntimeException
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 21 native zombies' flag back
ZEDQA stt planks off 0 | blood cleaned on 0 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 44 items removed
ZEDQA stt back: 45 items, 18 worn
ZEDQA stt belt back: 4/4
ZEDQA stt character back: profession base:mechanics | 97 traits | 42 perks
ERROR: General f:10124 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getWindow of non-table: null
ERROR: General f:10124> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: getWindow of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:201)
    Lua(Vanilla).step(spawnpoints.lua:198)
    Lua(Vanilla).onFrame(spawnpoints.lua:114)
ERROR: General f:10124 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getWindow of non-table: null
ERROR: General f:10124> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: getWindow of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:207)
    Lua(Vanilla).step(spawnpoints.lua:204)
    Lua(Vanilla).onFrame(spawnpoints.lua:114)
ERROR: General f:10124 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: MapNotes of non-table: null
ERROR: General f:10124> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: MapNotes of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:213)
    Lua(Vanilla).step(spawnpoints.lua:212)
    Lua(Vanilla).onFrame(spawnpoints.lua:114)
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 0
ZEDQA stt zoom 1
ZEDQA stt back at 12069,7144 (was 12069,7144) | carried 45 | zombies in the cell 21
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
```

### 11. gallery_v1_a_end.lua (`ZEDQA g1e`) - PASS, 1 s

- go 28616 at 18:21:39

```text
ZEDQA g1e the game's build line shown again
ZEDQA g1e errors logged in this game: 16
[ZeD.QA] run #11 ok=true
ZEDQA g1e DONE
```

### 12. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 28617 at 18:21:43

```text
ZEDQA g14e put back: menus false, watermark true, column true, options false | look now nil nil
[ZeD.QA] run #12 ok=true
ZEDQA g14e DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    2x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
