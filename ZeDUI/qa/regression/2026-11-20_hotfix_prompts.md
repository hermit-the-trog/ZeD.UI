# ZeD-UI regression - 2026-11-20 07:44 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-20 07:44:48 |
| Finished | 2026-11-20 07:48:50 (4 min 1 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\hotfix_prompts.txt (15 scripts) |
| Result | **14/15 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 30976 to 30992 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 30991, 30992)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 4 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 5 | gallery_b10_glasses.lua | gls | PASS | 1 |  |  |
| 6 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 7 | gallery_story_stage.lua | sts | WARN | 42 |  | 2 ERR line(s) |
| 8 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 9 | gallery_v1_a_common.lua | g1c | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 10 | hfr_common.lua | hfrc | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 11 | hfr_prompts.lua | hfp | PASS | 43 |  | late output from unl (33 line(s), not counted) |
| 12 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 13 | gallery_story_teardown.lua | stt | PASS | 10 |  |  |
| 14 | gallery_v1_a_end.lua | g1e | PASS | 1 |  |  |
| 15 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 30976 at 07:45:53

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

- go 30977 at 07:45:59

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 30978 at 07:46:03

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

- go 30979 at 07:46:07

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.23 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 1 s

- go 30980 at 07:46:12

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls short sighted false, prescription glasses off
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 30981 at 07:46:17

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_story_stage.lua (`ZEDQA sts`) - WARN, 42 s

- go 30982 at 07:46:21
- 2 ERR line(s)

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
ZEDQA sts aside: 18 worn, 4 on the belt, 25 items
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
ZEDQA sts car placements to try: 35
ZEDQA sts note: placement 1 (12068,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 2 (12068,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 3 (12068,7148 N) no good: pump false, tank area free false
ZEDQA sts note: placement 4 (12068,7146 S) no good: pump false, tank area free false
ZEDQA sts note: placement 5 (12069,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 6 (12068,7148 S) no good: pump false, tank area free false
ZEDQA sts note: placement 7 (12068,7149 N) no good: pump false, tank area free false
ZEDQA sts note: placement 8 (12069,7148 N) no good: pump false, tank area free false
ZEDQA sts note: placement 9 (12068,7154 N) no good: pump false, tank area free false
ZEDQA sts note: placement 10 (12068,7154 S) no good: pump false, tank area free false
ZEDQA sts note: placement 11 (12067,7156 E) no good: pump false, tank area free false
ZEDQA sts note: placement 12 (12068,7155 N) no good: pump false, tank area free false
ZEDQA sts note: placement 13 (12068,7153 S) no good: pump false, tank area free false
ZEDQA sts note: placement 14 (12069,7154 N) no good: pump false, tank area free false
ZEDQA sts note: placement 15 (12068,7155 S) no good: pump false, tank area free false
ZEDQA sts note: placement 16 (12068,7156 N) no good: pump false, tank area free false
ZEDQA sts note: placement 17 (12069,7155 N) no good: pump false, tank area free false
ZEDQA sts note: placement 18 (12076,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 19 (12076,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 20 (12077,7149 W) no good: pump false, tank area free false
ZEDQA sts note: placement 21 (12078,7150 E) no good: pump false, tank area free false
ZEDQA sts note: placement 22 (12075,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 23 (12078,7150 W) no good: pump false, tank area free false
ZEDQA sts note: placement 24 (12076,7148 N) no good: pump false, tank area free false
ZEDQA sts note: placement 25 (12076,7148 S) no good: pump false, tank area free false
ZEDQA sts note: placement 26 (12079,7150 E) no good: pump false, tank area free false
ZEDQA sts note: placement 27 (12077,7150 W) no good: pump false, tank area free false
ZEDQA sts note: placement 28 (12075,7148 S) no good: pump false, tank area free false
ZEDQA sts note: placement 29 (12076,7154 N) no good: pump false, tank area free false
ZEDQA sts note: placement 30 (12076,7154 S) no good: pump false, tank area free false
ZEDQA sts note: placement 31 (12077,7156 W) no good: pump false, tank area free false
ZEDQA sts note: placement 32 (12075,7154 S) no good: pump false, tank area free false
ZEDQA sts note: placement 33 (12076,7155 N) no good: pump false, tank area free false
ZEDQA sts note: placement 34 (12076,7155 S) no good: pump false, tank area free false
ZEDQA sts note: placement 35 (12075,7155 S) no good: pump false, tank area free false
ZEDQA sts ERR no car placement reached the pump: the car goes on the first clear square near the pump
ZEDQA sts car fuel 3.5 / 59.0
ZEDQA sts native zombies near the store made useless: 0
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

- go 30983 at 07:47:06

```text
[ZeD.QA] state #8 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=23 missing=get
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

- go 30984 at 07:47:10
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #9 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=23 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1c the floating XP text muted until gallery_v1_a_end.lua
ZEDQA g1c eyes at the start: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3
ZEDQA g1c helpers ready | ZeD loaded true | story staged true | load 12.3 of 8 kg, 26 items, Heavy Load 1
[ZeD.QA] run #9 ok=true
ZEDQA g1c DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x4)
```

### 10. hfr_common.lua (`ZEDQA hfrc`) - PASS, 1 s

- go 30985 at 07:47:14
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #10 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=23 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hfrc helpers ready
[ZeD.QA] run #10 ok=true
ZEDQA hfrc DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x4)
```

### 11. hfr_prompts.lua (`ZEDQA hfp`) - PASS, 43 s

- go 30986 at 07:47:19
- late output from unl (33 line(s), not counted)

```text
[ZeD.QA] state #11 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=23 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hfp start (64 steps)
[ZeD.QA] run #11 ok=true
ZEDQA hfp bottom-right element UIElement / WaterMarkUI at 3602,2127 228x22
ZEDQA hfp hid the game's build line (WaterMarkUI)
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp start at 12073,7130 | screen 3840x2160 | Style 1
ZEDQA hfp zombies taken away near the store: 7
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA hfp zoom 1
ZEDQA hfp B_prompt_rename_mouse built true, pad false
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_prompt_rename_mouse
ZEDQA hfp load hfr_B_prompt_rename_mouse: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_prompt_rename_mouse: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_prompt_rename_mouse character 1760,776-2080,1196
ZEDQA hfp box hfr_B_prompt_rename_mouse belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp B_prompt_alarm_mouse built true, pad false
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_prompt_alarm_mouse
ZEDQA hfp load hfr_B_prompt_alarm_mouse: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_prompt_alarm_mouse: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_prompt_alarm_mouse character 1760,776-2080,1196
ZEDQA hfp box hfr_B_prompt_alarm_mouse belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp B_prompt_timer_mouse built true, pad false
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_prompt_timer_mouse
ZEDQA hfp load hfr_B_prompt_timer_mouse: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_prompt_timer_mouse: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_prompt_timer_mouse character 1760,776-2080,1196
ZEDQA hfp box hfr_B_prompt_timer_mouse belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp B_prompt_question_mouse built true, pad false
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_prompt_question_mouse
ZEDQA hfp load hfr_B_prompt_question_mouse: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_prompt_question_mouse: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_prompt_question_mouse character 1760,776-2080,1196
ZEDQA hfp box hfr_B_prompt_question_mouse belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp B_prompt_rename_pad built true, pad true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp B_prompt_rename_pad focus field
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_prompt_rename_pad
ZEDQA hfp load hfr_B_prompt_rename_pad: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_prompt_rename_pad: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_prompt_rename_pad character 1760,776-2080,1196
ZEDQA hfp box hfr_B_prompt_rename_pad belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp B_prompt_alarm_pad built true, pad true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp B_prompt_alarm_pad focus hour
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_prompt_alarm_pad
ZEDQA hfp load hfr_B_prompt_alarm_pad: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_prompt_alarm_pad: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_prompt_alarm_pad character 1760,776-2080,1196
ZEDQA hfp box hfr_B_prompt_alarm_pad belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp B_prompt_timer_pad built true, pad true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp B_prompt_timer_pad focus value
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_prompt_timer_pad
ZEDQA hfp load hfr_B_prompt_timer_pad: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_prompt_timer_pad: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_prompt_timer_pad character 1760,776-2080,1196
ZEDQA hfp box hfr_B_prompt_timer_pad belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp B_prompt_question_pad built true, pad true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp B_prompt_question_pad focus yes
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_prompt_question_pad
ZEDQA hfp load hfr_B_prompt_question_pad: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_prompt_question_pad: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_prompt_question_pad character 1760,776-2080,1196
ZEDQA hfp box hfr_B_prompt_question_pad belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp keyboard up true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_keyboard_mouse
ZEDQA hfp load hfr_B_keyboard_mouse: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_keyboard_mouse: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_keyboard_mouse character 1760,776-2080,1196
ZEDQA hfp box hfr_B_keyboard_mouse belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_keyboard_pad
ZEDQA hfp load hfr_B_keyboard_pad: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_keyboard_pad: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_keyboard_pad character 1760,776-2080,1196
ZEDQA hfp box hfr_B_keyboard_pad belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA hfp moved the Keyboard map from x 1500 to x 21 (left side): it covered the character
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_kbmap_legend
ZEDQA hfp load hfr_B_kbmap_legend: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_kbmap_legend: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_kbmap_legend character 1760,776-2080,1196
ZEDQA hfp box hfr_B_kbmap_legend belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp picked E; listening Interact
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_kbmap_listening
ZEDQA hfp load hfr_B_kbmap_listening: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_kbmap_listening: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_kbmap_listening character 1760,776-2080,1196
ZEDQA hfp box hfr_B_kbmap_listening belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp pause window up true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp changed rows 1
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_sandbox_ingame_changed
ZEDQA hfp load hfr_B_sandbox_ingame_changed: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_sandbox_ingame_changed: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_sandbox_ingame_changed character 1760,776-2080,1196
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp short sighted false, prescription glasses off
ZEDQA hfp shot hfr_B_sandbox_ingame_time
ZEDQA hfp load hfr_B_sandbox_ingame_time: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hfp eyes hfr_B_sandbox_ingame_time: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hfp box hfr_B_sandbox_ingame_time character 1760,776-2080,1196
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hfp glasses put on by the script taken off again: 0, worn ones put back: 0
ZEDQA hfp rot speed now 3 (was 3)
ZEDQA hfp end: 14 shots, 0 not taken or failed
ZEDQA hfp DONE
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x4)
```

### 12. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 30987 at 07:48:05

```text
[ZeD.QA] state #12 speed=1 paused=false player=12053,7121 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA rel put back 35 things; after: 32.6 of 18 kg, 61 items, Heavy Load 1 OVER
[ZeD.QA] run #12 ok=true
ZEDQA rel DONE
```

### 13. gallery_story_teardown.lua (`ZEDQA stt`) - PASS, 10 s

- go 30988 at 07:48:09

```text
[ZeD.QA] state #13 speed=1 paused=false player=12053,7121 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stt start (17 steps)
[ZeD.QA] run #13 ok=true
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 0 native zombies' flag back
ZEDQA stt planks off 0 | blood cleaned on 0 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 44 items removed
ZEDQA stt back: 25 items, 18 worn
ZEDQA stt belt back: 4/4
ZEDQA stt character back: profession base:mechanics | 97 traits | 42 perks
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 3
ZEDQA stt ZeD back: dark teal small (was dark teal small)
ERROR: General f:10933 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA stt zoom 1
ZEDQA stt back at 925,13040 (was 925,13040) | carried 25 | zombies in the cell 0
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
```

### 14. gallery_v1_a_end.lua (`ZEDQA g1e`) - PASS, 1 s

- go 30989 at 07:48:22

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

- go 30990 at 07:48:27

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
