# ZeD-UI regression - 2026-11-18 17:06 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-18 17:06:38 |
| Finished | 2026-11-18 17:10:38 (4 min 0 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\gallery_v1_pitch.txt (15 scripts) |
| Result | **14/15 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 29867 to 29883 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29882, 29883)
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
| 7 | gallery_story_stage.lua | sts | WARN | 59 |  | 1 ERR line(s) |
| 8 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 9 | gallery_v1_a_common.lua | g1c | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 10 | gallery_v1_pitch_only.lua | pto | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 11 | gallery_v1_a_zed.lua | g1z | PASS | 18 |  | late output from unl (22 line(s), not counted) |
| 12 | gallery_reload.lua | rel | PASS | 1 |  | late output from unl (1 line(s), not counted) |
| 13 | gallery_story_teardown.lua | stt | PASS | 11 |  |  |
| 14 | gallery_v1_a_end.lua | g1e | PASS | 1 |  |  |
| 15 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 29867 at 17:07:44

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
ZEDQA pre ZeD version=0.3.0-beta20 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 29868 at 17:07:50

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 29869 at 17:07:54

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

- go 29870 at 17:07:58

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.25 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 29871 at 17:08:04

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls short sighted false, prescription glasses off
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 29872 at 17:08:09

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_story_stage.lua (`ZEDQA sts`) - WARN, 59 s

- go 29873 at 17:08:13
- 1 ERR line(s)

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sts short sighted false
ZEDQA sts start (22 steps)
[ZeD.QA] run #7 ok=true
ZEDQA sts start at 925,13040 | site: Fossoil, West Point | ZeD true
ZEDQA sts at the store: room fossoil, building true
ZEDQA sts stock spot 12053,7121 with 3 shelf containers in reach
ZEDQA sts counter 12054,7123 clerk 12053,7123 queue toward 1,0
ZEDQA sts pump 12066,7147 (location_shop_fossoil_01_13), 8 pump squares round the store
ZEDQA sts ERR no window that can be barricaded from outside
ZEDQA sts windows 9 (smashed 9, barricaded 0) | shelves 19 counters 7 other containers 13 | free floor 81
ZEDQA sts container types: cardboardbox=2 metal_shelves=1 shelves=14 shelvesmag=4 fridge=10 counter=7 cashregister=1
ZEDQA sts blood 12060,7121
ZEDQA sts smoke spot 12073,7130
ZEDQA sts aside: 7 worn, 1 on the belt, 55 items
ZEDQA sts worn: Tshirt_DefaultTEXTURE_TINT Shirt_Lumberjack Jacket_ArmyOliveDrab Vest_Hunting_Khaki Trousers_Denim Socks_Heavy Shoes_ArmyBoots Gloves_LeatherGlovesBlack Hat_BaseballCapGreen Belt2 HolsterSimple_Black Kneepad_Left_Tactical Kneepad_Right_Tactical WristWatch_Left_DigitalBlack Glasses_Aviators Bag_ALICEpack_Army Bag_ChestRig Bag_FannyPackBack Bag_Satchel_Leather
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
ZEDQA sts car Base.CarStationWagon at 12081,7154 facing N: the pump finder sees 12078,7154 | tank area 12079.6,7154.9
ZEDQA sts car fuel 2.3 / 39.0
ZEDQA sts native zombies near the store made useless: 18
ZEDQA sts passive zombies outside: 7
ZEDQA sts blood on 0 squares | stains read back true | blood decals option 10
ZEDQA sts seeds: flyer fossoil2 read (was true) | journal true | note true star true
ZEDQA sts zoom 1.5
ZEDQA sts shot story_00_scout ok
ZEDQA sts staged: car true | zombies 7 outside | blood 0 | carried 44
ZEDQA sts end: 1 shots ok, 0 errors
ZEDQA sts DONE
```

### 8. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 29874 at 17:09:15

```text
[ZeD.QA] state #8 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 32.6 of 8 kg, 61 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 35 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #8 ok=true
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (x3)
```

### 9. gallery_v1_a_common.lua (`ZEDQA g1c`) - PASS, 1 s

- go 29875 at 17:09:20
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #9 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1c the floating XP text muted until gallery_v1_a_end.lua
ZEDQA g1c eyes at the start: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3
ZEDQA g1c helpers ready | ZeD loaded true | story staged true | load 12.3 of 8 kg, 26 items, Heavy Load 1
[ZeD.QA] run #9 ok=true
ZEDQA g1c DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x4)
```

### 10. gallery_v1_pitch_only.lua (`ZEDQA pto`) - PASS, 1 s

- go 29876 at 17:09:24
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #10 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pto beats: 01, 26; look dark teal
[ZeD.QA] run #10 ok=true
ZEDQA pto DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x4)
```

### 11. gallery_v1_a_zed.lua (`ZEDQA g1z`) - PASS, 18 s

- go 29877 at 17:09:28
- late output from unl (22 line(s), not counted)

```text
[ZeD.QA] state #11 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1z start (29 steps)
[ZeD.QA] run #11 ok=true
ZEDQA g1z bottom-right element UIElement / WaterMarkUI at 3602,2127 228x22
ZEDQA g1z hid the game's build line (WaterMarkUI)
ZEDQA g1z short sighted false, prescription glasses off
ZEDQA g1z start at 12073,7130 | screen 3840x2160 | font size option 2 | ZeD dark teal small | pair open false
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1z look dark teal | the list view | default boxes logged next
ZEDQA g1z box default character 1813,877-2026,1157
ZEDQA g1z box default char 1134,0-1911,735
ZEDQA g1z box default world 1929,0-2706,735
ZEDQA g1z box default belt 1439,2034-2378,2132
ZEDQA g1z shelf shelves at 12052,7121: 9 things it held set aside, 10 of 10 put in | capacity 50
ZEDQA g1z apples given: 3
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1z apple stack opened: 3
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA g1z World window shows the shelf true
ZEDQA g1z open stack: Apple (3)
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1z zoom 0.75
ZEDQA g1z moved the Character window from x 1134 to x 21 (left side): it covered the character
ZEDQA g1z moved the World window from x 1929 to x 3042 (right side): it covered the character
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA g1z 01: the same moment as g1_17_zed, closer (zoom 0.75), for the before-and-after spread; if g1_17 reads at 116 x 65, 01 = 17's pair
ZEDQA g1z short sighted false, prescription glasses off
ZEDQA g1z shot g1_01_zed
ZEDQA g1z load g1_01_zed: 12.9 of 18 kg, 29 items, Heavy Load 0
ZEDQA g1z eyes g1_01_zed: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.02, view cone 3 | errors so far 0
ZEDQA g1z box g1_01_zed character 1706,675-2133,1235
ZEDQA g1z box g1_01_zed char 21,0-798,735
ZEDQA g1z box g1_01_zed world 3042,0-3819,735
ZEDQA g1z box g1_01_zed belt 1439,2034-2378,2132
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1z zoom 1
ZEDQA g1z apples taken back: 3
ZEDQA g1z shelf back: 9 things it held, 10 taken out
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1z left forearm: scratched false, bandaged true
ZEDQA unl load 12.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1z short sighted false, prescription glasses off
ZEDQA g1z shot g1_26_zed
ZEDQA g1z load g1_26_zed: 12.3 of 18 kg, 28 items, Heavy Load 0
ZEDQA g1z eyes g1_26_zed: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.03, view cone 3 | errors so far 0
ZEDQA g1z box g1_26_zed character 1760,776-2080,1196
ZEDQA g1z box g1_26_zed char 0,0-1617,735
ZEDQA g1z box g1_26_zed world 3042,0-3819,735
ZEDQA g1z box g1_26_zed belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA g1z left forearm: scratched false, bandaged false
ZEDQA unl load 12.3 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1z left forearm: scratched false, bandaged false
ZEDQA g1z apples taken back: 0
ZEDQA g1z glasses put on by the script taken off again: 0, worn ones put back: 0
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1z box put_back character 1760,776-2080,1196
ZEDQA g1z box put_back belt 1439,2034-2378,2132
ZEDQA g1z put back: look dark teal (was dark teal)
ZEDQA g1z end: 2 shots, 0 not taken or failed
ZEDQA g1z DONE
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
```

### 12. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 29878 at 17:09:50
- late output from unl (1 line(s), not counted)

```text
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
[ZeD.QA] state #12 speed=1 paused=false player=12053,7121 grid=19 inCar=false vehicles=13 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA rel put back 35 things; after: 32.6 of 18 kg, 61 items, Heavy Load 1 OVER
[ZeD.QA] run #12 ok=true
ZEDQA rel DONE
```

### 13. gallery_story_teardown.lua (`ZEDQA stt`) - PASS, 11 s

- go 29879 at 17:09:54

```text
[ZeD.QA] state #13 speed=1 paused=false player=12053,7121 grid=19 inCar=false vehicles=13 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stt start (17 steps)
[ZeD.QA] run #13 ok=true
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 18 native zombies' flag back
ZEDQA stt planks off 0 | blood cleaned on 0 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 44 items removed
ZEDQA stt back: 55 items, 7 worn
ZEDQA stt belt back: 1/1
ZEDQA stt character back: profession base:mechanics | 97 traits | 42 perks
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 2
ZEDQA stt ZeD back: dark teal small (was dark teal small)
ERROR: General f:9606 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA stt zoom 1
ZEDQA stt back at 925,13040 (was 925,13040) | carried 55 | zombies in the cell 0
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
```

### 14. gallery_v1_a_end.lua (`ZEDQA g1e`) - PASS, 1 s

- go 29880 at 17:10:08

```text
[ZeD.QA] state #14 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1e the floating XP text is back
ZEDQA g1e the game's build line shown again
ZEDQA g1e errors logged in this game: 0
[ZeD.QA] run #14 ok=true
ZEDQA g1e DONE
```

### 15. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 29881 at 17:10:13

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
