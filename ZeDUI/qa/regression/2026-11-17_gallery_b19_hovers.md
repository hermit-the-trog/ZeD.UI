# ZeD-UI regression - 2026-11-17 12:31 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 12:31:05 |
| Finished | 2026-11-17 12:34:44 (3 min 38 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\gallery_b19_hovers.txt (15 scripts) |
| Result | **15/15 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 28252 to 28268 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28267, 28268)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 4 | gallery_daylight.lua | day | PASS | 3 |  |  |
| 5 | gallery_b10_glasses.lua | gls | PASS | 2 |  |  |
| 6 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 7 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 8 | zedqa_moodles.lua | mood | PASS | 20 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png | late output from unl (19 line(s), not counted) |
| 9 | gallery_b19_story11_only.lua | s11 | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 10 | gallery_story_stage.lua | sts | PASS | 32 |  | late output from unl (37 line(s), not counted) |
| 11 | gallery_story_shots.lua | stz | PASS | 8 |  | late output from unl (9 line(s), not counted) |
| 12 | gallery_story_teardown.lua | stt | PASS | 10 |  | late output from unl (14 line(s), not counted) |
| 13 | gallery_b11_look.lua | g14l2 | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 14 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 15 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28252 at 12:32:10

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
ZEDQA pre ZeD version=0.3.0-beta19 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 28253 at 12:32:16

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28254 at 12:32:20

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

### 4. gallery_daylight.lua (`ZEDQA day`) - PASS, 3 s

- go 28255 at 12:32:24

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.35 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 28256 at 12:32:30

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls wearing Base.Glasses_Prescription
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28257 at 12:32:36

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28258 at 12:32:40

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 49.9 of 8 kg, 116 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 60 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 8.1 of 8 kg, 56 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #7 ok=true
ZEDQA unl load 8.1 of 8 kg, 56 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 8.1 of 8 kg, 56 items, Heavy Load 1   (x3)
```

### 8. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 20 s

- go 28259 at 12:32:44
- late output from unl (19 line(s), not counted)
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #8 ok=true
ZEDQA unl load 8.1 of 8 kg, 56 items, Heavy Load 1   (late output from unl)
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA unl load 8.1 of 8 kg, 56 items, Heavy Load 1   (late output from unl)
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 5
ZEDQA mood box by itself: TIRED | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)
ZEDQA mood right: 5 moodles on (TIRED 2, HUNGRY 3, PANIC 1, STRESS 2, THIRST 2)
ZEDQA mood PASS right: the place is in effect
ZEDQA mood PASS right: at least three moodles are on
ZEDQA mood PASS right: the moodles are shown (layer)
ZEDQA mood right column at 3782,940 size 48, stack 280; visible true
ZEDQA mood PASS right: vanilla's column is visible
ZEDQA mood PASS right: every moodle is on screen
ZEDQA mood PASS right: the column is on the right edge (x 3782)
ZEDQA mood PASS right: ZeD's hover layer lies over the column
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)
ZEDQA mood right bubble: moodle 2, cloud -241,71 219x86.19140625, trail balloon from nil,nil
ZEDQA mood PASS right: the bubble is for the moodle under the pointer
ZEDQA mood PASS right: the balloon sits beside its moodle, clear of it
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA mood left: 5 moodles on (TIRED 2, HUNGRY 3, PANIC 1, STRESS 2, THIRST 2)
ZEDQA mood PASS left: the place is in effect
ZEDQA mood PASS left: at least three moodles are on
ZEDQA mood PASS left: the moodles are shown (layer)
ZEDQA mood left column at 10,940 size 48, stack 280; visible true
ZEDQA mood PASS left: vanilla's column is visible
ZEDQA mood PASS left: every moodle is on screen
ZEDQA mood PASS left: the column is on the left edge (x 10)
ZEDQA mood PASS left: ZeD's hover layer lies over the column
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)
ZEDQA mood left bubble: moodle 2, cloud 70,71 219x86.19140625, trail balloon from nil,nil
ZEDQA mood PASS left: the bubble is for the moodle under the pointer
ZEDQA mood PASS left: the balloon sits beside its moodle, clear of it
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA mood bottom: 5 moodles on (TIRED 2, HUNGRY 3, PANIC 2, STRESS 2, THIRST 2)
ZEDQA mood PASS bottom: the place is in effect
ZEDQA mood PASS bottom: at least three moodles are on
ZEDQA mood PASS bottom: the moodles are shown (layer)
ZEDQA mood bottom row at 1780,1965 280x48; vanilla's column y -10000
ZEDQA mood PASS bottom: the row is on screen
ZEDQA mood PASS bottom: the row is centred (middle 1920 of 3840)
ZEDQA mood PASS bottom: the row sits above the belt
ZEDQA mood PASS bottom: one slot per moodle
ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)
ZEDQA mood bottom bubble: moodle 2, cloud 68,-108.19140625 219x86.19140625, trail balloon from nil,nil
ZEDQA mood PASS bottom: the bubble is for the moodle under the pointer
ZEDQA mood PASS bottom: the balloon sits beside its moodle, clear of it
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)
ZEDQA mood PASS with nothing changing the box goes by itself (nil)
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)
ZEDQA mood notices off: box nil | waiting 2
ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)
ZEDQA mood all checks passed
ZEDQA mood DONE
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)   (x4)
```

### 9. gallery_b19_story11_only.lua (`ZEDQA s11`) - PASS, 1 s

- go 28260 at 12:33:08
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA s11 beats: 11
[ZeD.QA] run #9 ok=true
ZEDQA s11 DONE
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)   (x4)
```

### 10. gallery_story_stage.lua (`ZEDQA sts`) - PASS, 32 s

- go 28261 at 12:33:12
- late output from unl (37 line(s), not counted)

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sts start (22 steps)
[ZeD.QA] run #10 ok=true
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)
ZEDQA sts start at 925,13040 | site: Fossoil, West Point | ZeD true
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)   (x9)
ZEDQA sts at the store: room fossoil, building true
ZEDQA sts stock spot 12053,7121 with 3 shelf containers in reach
ZEDQA sts counter 12054,7123 clerk 12053,7123 queue toward 1,0
ZEDQA sts pump 12066,7147 (location_shop_fossoil_01_13), 8 pump squares round the store
ZEDQA sts window 12063,7127, barricaded from 12063,7127
ZEDQA sts windows 9 (smashed 2, barricaded 0) | shelves 19 counters 7 other containers 13 | free floor 81
ZEDQA sts container types: cardboardbox=2 metal_shelves=1 shelves=14 shelvesmag=4 fridge=10 counter=7 cashregister=1
ZEDQA sts blood 12060,7121
ZEDQA sts smoke spot 12073,7130
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)   (x10)
ZEDQA sts aside: 7 worn, 0 on the belt, 56 items
ZEDQA unl load 0.0 of 17 kg, 0 items, Heavy Load 0   (late output from unl)
ZEDQA sts worn: Tshirt_DefaultTEXTURE_TINT Shirt_Lumberjack Jacket_ArmyOliveDrab Vest_Hunting_Khaki Trousers_Denim Socks_Heavy Shoes_ArmyBoots Gloves_LeatherGlovesBlack Hat_BaseballCapGreen Belt2 HolsterSimple_Black Kneepad_Left_Tactical Kneepad_Right_Tactical WristWatch_Left_DigitalBlack Glasses_Prescription_Aviators Bag_ALICEpack_Army Bag_ChestRig Bag_FannyPackBack Bag_Satchel_Leather
ZEDQA sts bag back (Base.Bag_ALICEpack_Army): 13 things
ZEDQA sts bag webbing (Base.Bag_ChestRig): 3 things
ZEDQA sts bag fannypackback (Base.Bag_FannyPackBack): 2 things
ZEDQA sts bag satchel (Base.Bag_Satchel_Leather): 2 things
ZEDQA sts loose: 19/19
ZEDQA sts belt: HuntingKnife@smallbeltleft Hammer@smallbeltright Pistol@holsterright Shotgun@back
ZEDQA unl load 32.5 of 17 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts character was: profession base:unemployed, 28 traits on, 42 perks kept
ZEDQA sts profession base:mechanics | traits base:mechanics2 SMOKER SPEED_DEMON STRONG DEXTROUS FAST_READER PRONE_TO_ILLNESS HEARTY_APPETITE SLOW_HEALER PACIFIST | skills Strength=9 Fitness=5 Mechanics=4 MetalWelding=1
ZEDQA sts power: option set true | pump square grid power true, no-power zone false
ZEDQA sts pumps filled: 8 | the pump reads 500
ZEDQA sts car placements to try: 80
ZEDQA unl load 32.5 of 17 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 1 (12068,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 2 (12064,7147 N) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 17 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 3 (12068,7147 S) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 17 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 4 (12064,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 5 (12067,7149 E) no good: pump false, tank area free false
ZEDQA sts note: placement 6 (12065,7149 W) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 17 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 7 (12068,7148 N) no good: pump false, tank area free false
ZEDQA sts note: placement 8 (12068,7146 S) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 17 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 9 (12066,7150 E) no good: pump false, tank area free false
ZEDQA sts note: placement 10 (12069,7147 N) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 17 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts car Base.CarStationWagon at 12063,7147 facing S: the pump finder sees 12066,7147 | tank area 12064.3,7145.9
ZEDQA sts car fuel 3.5 / 59.0
ZEDQA unl load 32.6 of 17 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts native zombies near the store made useless: 0
ZEDQA sts passive zombies outside: 7
ZEDQA sts blood on 1 squares | stains read back true | blood decals option 10
ZEDQA sts seeds: flyer fossoil2 read (was true) | journal true | note true star true
ZEDQA unl load 32.6 of 17 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA sts zoom 1.5
ZEDQA unl load 32.6 of 17 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts shot story_00_scout ok
ZEDQA unl load 32.6 of 17 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts staged: car true | zombies 7 outside | blood 1 | carried 44
ZEDQA sts end: 1 shots ok, 0 errors
ZEDQA sts DONE
ZEDQA unl load 32.6 of 17 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x3)
```

### 11. gallery_story_shots.lua (`ZEDQA stz`) - PASS, 8 s

- go 28262 at 12:33:47
- late output from unl (9 line(s), not counted)

```text
[ZeD.QA] state #11 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stz start (13 steps)
[ZeD.QA] run #11 ok=true
ZEDQA stz theme dark teal | profession base:mechanics
ZEDQA unl load 32.6 of 17 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA stz zoom 0.5
ZEDQA unl load 32.6 of 17 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA stz moodles: HUNGRY STRESS THIRST | hover on 2
ZEDQA stz shot story_11_smoke_break ok
ZEDQA unl load 32.6 of 17 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz theme now dark teal (the teardown re-applies the options)
ZEDQA stz end: 1 shots ok, 0 errors
ZEDQA stz DONE
ZEDQA unl load 32.6 of 17 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x3)
```

### 12. gallery_story_teardown.lua (`ZEDQA stt`) - PASS, 10 s

- go 28263 at 12:33:59
- late output from unl (14 line(s), not counted)

```text
[ZeD.QA] state #12 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stt start (17 steps)
[ZeD.QA] run #12 ok=true
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 0 native zombies' flag back
ZEDQA stt planks off 0 | blood cleaned on 1 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 44 items removed
ZEDQA unl load 0.0 of 17 kg, 0 items, Heavy Load 0   (late output from unl)
ZEDQA stt back: 56 items, 7 worn
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)
ZEDQA stt belt back: 0/0
ZEDQA stt character back: profession base:unemployed | 97 traits | 42 perks
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 2
ZEDQA stt ZeD back: dark teal small (was dark teal small)
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)
ERROR: General f:8622 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)   (x7)
ZEDQA stt zoom 1
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)
ZEDQA stt back at 925,13040 (was 925,13040) | carried 56 | zombies in the cell 0
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)   (x3)
```

### 13. gallery_b11_look.lua (`ZEDQA g14l2`) - PASS, 1 s

- go 28264 at 12:34:12
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #13 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l2 desk menu bar: Debug left out true
ZEDQA g14l2 position readout and cheat lines off true
ZEDQA g14l2 left-edge column hidden true
ZEDQA g14l2 look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #13 ok=true
ZEDQA g14l2 DONE
ZEDQA unl load 8.1 of 17 kg, 56 items, Heavy Load 0   (late output from unl)   (x4)
```

### 14. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28265 at 12:34:16

```text
[ZeD.QA] state #14 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.1 of 17 kg, 56 items, Heavy Load 0
ZEDQA rel put back 60 things; after: 49.9 of 17 kg, 116 items, Heavy Load 1 OVER
[ZeD.QA] run #14 ok=true
ZEDQA rel DONE
```

### 15. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 28266 at 12:34:20

```text
[ZeD.QA] state #15 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #15 ok=true
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
