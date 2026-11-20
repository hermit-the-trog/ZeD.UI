# ZeD-UI regression - 2026-11-20 08:40 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-20 08:40:32 |
| Finished | 2026-11-20 08:45:20 (4 min 47 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\hotfix_tabs.txt (15 scripts) |
| Result | **14/15 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 31172 to 31188 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 31187, 31188)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back
- ZeD_tutorial.txt removed (there was none before the run)

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 6 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 4 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 5 | gallery_b10_glasses.lua | gls | PASS | 2 |  |  |
| 6 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 7 | gallery_story_stage.lua | sts | WARN | 44 |  | 2 ERR line(s) |
| 8 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 9 | gallery_v1_a_common.lua | g1c | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 10 | hfr_common.lua | hfrc | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 11 | hfr_tabs.lua | hft | PASS | 77 |  | late output from unl (64 line(s), not counted) |
| 12 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 13 | gallery_story_teardown.lua | stt | PASS | 10 |  |  |
| 14 | gallery_v1_a_end.lua | g1e | PASS | 1 |  |  |
| 15 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 6 s

- go 31172 at 08:41:38

```text
[ZeD.QA] state #1 speed=1 paused=false player=919,13030 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 919,13030,0 to the drag strip
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta21 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 31173 at 08:41:48

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 31174 at 08:41:52

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

- go 31175 at 08:41:57

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.39 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 31176 at 08:42:02

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls short sighted false, prescription glasses off
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 31177 at 08:42:07

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_story_stage.lua (`ZEDQA sts`) - WARN, 44 s

- go 31178 at 08:42:11
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
ZEDQA sts note: placement 7 (12067,7150 E) no good: pump false, tank area free false
ZEDQA sts note: placement 8 (12068,7149 N) no good: pump false, tank area free false
ZEDQA sts note: placement 9 (12069,7148 N) no good: pump false, tank area free false
ZEDQA sts note: placement 10 (12068,7154 N) no good: pump false, tank area free false
ZEDQA sts note: placement 11 (12068,7154 S) no good: pump false, tank area free false
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
ZEDQA sts car fuel 2.3 / 39.0
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

- go 31179 at 08:42:58

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

- go 31180 at 08:43:03
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

- go 31181 at 08:43:07
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #10 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=23 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hfrc helpers ready
[ZeD.QA] run #10 ok=true
ZEDQA hfrc DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x4)
```

### 11. hfr_tabs.lua (`ZEDQA hft`) - PASS, 77 s

- go 31182 at 08:43:11
- late output from unl (64 line(s), not counted)

```text
[ZeD.QA] state #11 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=23 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hft start (94 steps)
[ZeD.QA] run #11 ok=true
ZEDQA hft bottom-right element UIElement / WaterMarkUI at 3602,2127 228x22
ZEDQA hft hid the game's build line (WaterMarkUI)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft start at 12073,7130 | screen 3840x2160 | Style 1
ZEDQA hft zombies taken away near the store: 7
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA hft zoom 1
ZEDQA hft tour started true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft tour step 12 of 12
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_tour_last_step
ZEDQA hft load hfr_E_tour_last_step: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_tour_last_step: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_tour_last_step character 1760,776-2080,1196
ZEDQA hft box hfr_E_tour_last_step char 1134,0-1911,735
ZEDQA hft box hfr_E_tour_last_step world 1929,0-2706,735
ZEDQA hft box hfr_E_tour_last_step belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft E_skills: tab skills true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_skills
ZEDQA hft load hfr_E_skills: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_skills: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_skills character 1760,776-2080,1196
ZEDQA hft box hfr_E_skills char 294,0-1911,735
ZEDQA hft box hfr_E_skills world 1929,0-2706,735
ZEDQA hft box hfr_E_skills belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft E_health_uninjured: tab health true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_health_uninjured
ZEDQA hft load hfr_E_health_uninjured: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_health_uninjured: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_health_uninjured character 1760,776-2080,1196
ZEDQA hft box hfr_E_health_uninjured char 294,0-1911,735
ZEDQA hft box hfr_E_health_uninjured world 1929,0-2706,735
ZEDQA hft box hfr_E_health_uninjured belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft left forearm: scratched false, bandaged true
ZEDQA unl load 12.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA hft E_health_wounded: tab health true
ZEDQA unl load 12.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_health_wounded
ZEDQA hft load hfr_E_health_wounded: 12.3 of 18 kg, 28 items, Heavy Load 0
ZEDQA hft eyes hfr_E_health_wounded: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_health_wounded character 1760,776-2080,1196
ZEDQA hft box hfr_E_health_wounded char 294,0-1911,735
ZEDQA hft box hfr_E_health_wounded world 1929,0-2706,735
ZEDQA hft box hfr_E_health_wounded belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA hft left forearm: scratched false, bandaged false
ZEDQA unl load 12.3 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA hft identity: tab identity, hair state true, scroll 0.1503841469211741
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_identity_hair
ZEDQA hft load hfr_E_identity_hair: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_identity_hair: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_identity_hair character 1760,776-2080,1196
ZEDQA hft box hfr_E_identity_hair char 294,0-1911,735
ZEDQA hft box hfr_E_identity_hair world 1929,0-2706,735
ZEDQA hft box hfr_E_identity_hair belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft E_thermal: tab thermal true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_thermal
ZEDQA hft load hfr_E_thermal: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_thermal: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_thermal character 1760,776-2080,1196
ZEDQA hft box hfr_E_thermal char 294,0-1911,735
ZEDQA hft box hfr_E_thermal world 1929,0-2706,735
ZEDQA hft box hfr_E_thermal belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft E_journal_log: tab journal true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_journal_log
ZEDQA hft load hfr_E_journal_log: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_journal_log: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_journal_log character 1760,776-2080,1196
ZEDQA hft box hfr_E_journal_log char 294,0-1911,735
ZEDQA hft box hfr_E_journal_log world 1929,0-2706,735
ZEDQA hft box hfr_E_journal_log belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft Loadouts and outfits on: true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_loadouts
ZEDQA hft load hfr_E_loadouts: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_loadouts: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_loadouts character 1760,776-2080,1196
ZEDQA hft box hfr_E_loadouts char 294,0-1911,735
ZEDQA hft box hfr_E_loadouts world 1929,0-2706,735
ZEDQA hft box hfr_E_loadouts belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft E_doll_rest: tab equip true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_doll_rest
ZEDQA hft load hfr_E_doll_rest: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_doll_rest: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_doll_rest character 1760,776-2080,1196
ZEDQA hft box hfr_E_doll_rest char 294,0-1911,735
ZEDQA hft box hfr_E_doll_rest world 1929,0-2706,735
ZEDQA hft box hfr_E_doll_rest belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 13.8 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_doll_dragging
ZEDQA hft load hfr_E_doll_dragging: 13.8 of 18 kg, 27 items, Heavy Load 0
ZEDQA hft eyes hfr_E_doll_dragging: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_doll_dragging character 1760,776-2080,1196
ZEDQA hft box hfr_E_doll_dragging char 294,0-1911,735
ZEDQA hft box hfr_E_doll_dragging world 1929,0-2706,735
ZEDQA hft box hfr_E_doll_dragging belt 1439,2034-2378,2132
ZEDQA unl load 13.8 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft not taken: E_admin_tab (the Admin tab exists only for an admin on a server (AdminTab.visible needs isClient()); a single-player save cannot show it)
ZEDQA hft not taken: E_admin_world_tab (the Admin tab exists only for an admin on a server (AdminTab.visible needs isClient()))
ZEDQA hft not taken: E_server_tab (the Server tab is on a server only (a single-player save has none))
ZEDQA hft E_crafting_tab: tab craft true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_crafting_tab
ZEDQA hft load hfr_E_crafting_tab: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_crafting_tab: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_crafting_tab character 1760,776-2080,1196
ZEDQA hft box hfr_E_crafting_tab char 1134,0-1911,735
ZEDQA hft box hfr_E_crafting_tab world 1929,0-3546,735
ZEDQA hft box hfr_E_crafting_tab belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft E_building_tab: tab build true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_building_tab
ZEDQA hft load hfr_E_building_tab: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_building_tab: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_building_tab character 1760,776-2080,1196
ZEDQA hft box hfr_E_building_tab char 1134,0-1911,735
ZEDQA hft box hfr_E_building_tab world 1929,0-3546,735
ZEDQA hft box hfr_E_building_tab belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft E_furniture_tab: tab furniture true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_furniture_tab
ZEDQA hft load hfr_E_furniture_tab: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_furniture_tab: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.00, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_furniture_tab character 1760,776-2080,1196
ZEDQA hft box hfr_E_furniture_tab char 1134,0-1911,735
ZEDQA hft box hfr_E_furniture_tab world 1929,0-3546,735
ZEDQA hft box hfr_E_furniture_tab belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft E_foraging_tab: tab forage true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_foraging_tab
ZEDQA hft load hfr_E_foraging_tab: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_foraging_tab: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.01, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_foraging_tab character 1760,776-2080,1196
ZEDQA hft box hfr_E_foraging_tab char 1134,0-1911,735
ZEDQA hft box hfr_E_foraging_tab world 1929,0-3546,735
ZEDQA hft box hfr_E_foraging_tab belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft note added true
ZEDQA hft messages open call true
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft moved Messages from x 1255 to x 21 (left side): it covered the character
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_messages
ZEDQA hft load hfr_E_messages: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_messages: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.01, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_messages character 1760,776-2080,1196
ZEDQA hft box hfr_E_messages belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x4)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_maps_no_tool
ZEDQA hft load hfr_E_maps_no_tool: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA hft eyes hfr_E_maps_no_tool: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.01, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_maps_no_tool character 1760,776-2080,1196
ZEDQA hft box hfr_E_maps_no_tool char 1134,0-1911,735
ZEDQA hft box hfr_E_maps_no_tool world 1929,0-3546,735
ZEDQA hft box hfr_E_maps_no_tool belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.7 of 18 kg, 30 items, Heavy Load 0   (late output from unl)
ZEDQA hft tool zones: house,target,skull,star,cross,checkmark,text
ZEDQA hft tool in hand: house
ZEDQA unl load 12.7 of 18 kg, 30 items, Heavy Load 0   (late output from unl)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_maps_with_tool
ZEDQA hft load hfr_E_maps_with_tool: 12.7 of 18 kg, 30 items, Heavy Load 0
ZEDQA hft eyes hfr_E_maps_with_tool: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.01, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_maps_with_tool character 1760,776-2080,1196
ZEDQA hft box hfr_E_maps_with_tool char 1134,0-1911,735
ZEDQA hft box hfr_E_maps_with_tool world 1929,0-3546,735
ZEDQA hft box hfr_E_maps_with_tool belt 1439,2034-2378,2132
ZEDQA unl load 12.7 of 18 kg, 30 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_map_key
ZEDQA hft load hfr_E_map_key: 12.7 of 18 kg, 30 items, Heavy Load 0
ZEDQA hft eyes hfr_E_map_key: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.01, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_map_key character 1760,776-2080,1196
ZEDQA hft box hfr_E_map_key char 1134,0-1911,735
ZEDQA hft box hfr_E_map_key world 1929,0-3546,735
ZEDQA hft box hfr_E_map_key belt 1439,2034-2378,2132
ZEDQA unl load 12.7 of 18 kg, 30 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA hft map palette (Light map off) dark
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_maps_light_map_off
ZEDQA hft load hfr_E_maps_light_map_off: 12.7 of 18 kg, 30 items, Heavy Load 0
ZEDQA hft eyes hfr_E_maps_light_map_off: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.01, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_maps_light_map_off character 1760,776-2080,1196
ZEDQA hft box hfr_E_maps_light_map_off char 1134,0-1911,735
ZEDQA hft box hfr_E_maps_light_map_off world 1929,0-3546,735
ZEDQA hft box hfr_E_maps_light_map_off belt 1439,2034-2378,2132
ZEDQA unl load 12.7 of 18 kg, 30 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA hft map palette (Light map on) light
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_maps_light_map_on
ZEDQA hft load hfr_E_maps_light_map_on: 12.7 of 18 kg, 30 items, Heavy Load 0
ZEDQA hft eyes hfr_E_maps_light_map_on: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.01, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_maps_light_map_on character 1760,776-2080,1196
ZEDQA hft box hfr_E_maps_light_map_on char 1134,0-1911,735
ZEDQA hft box hfr_E_maps_light_map_on world 1929,0-3546,735
ZEDQA hft box hfr_E_maps_light_map_on belt 1439,2034-2378,2132
ZEDQA unl load 12.7 of 18 kg, 30 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 14.2 of 18 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA hft hammer row true
ZEDQA hft context menu ZeD_ContextList
ZEDQA hft short sighted false, prescription glasses off
ZEDQA hft shot hfr_E_context_list
ZEDQA hft load hfr_E_context_list: 14.2 of 18 kg, 31 items, Heavy Load 0
ZEDQA hft eyes hfr_E_context_list: glasses nil, short sighted false, visual aid false, search overlay false (override false), pain 0.00, panic 0.00, intoxication 0.00, fatigue 0.01, stress 0.00, view cone 3 | errors so far 0
ZEDQA hft box hfr_E_context_list character 1760,776-2080,1196
ZEDQA hft box hfr_E_context_list char 749,0-1911,735
ZEDQA hft box hfr_E_context_list world 1929,0-2706,735
ZEDQA hft box hfr_E_context_list belt 1439,2034-2378,2132
ZEDQA unl load 14.2 of 18 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA hft left forearm: scratched false, bandaged false
ZEDQA hft glasses put on by the script taken off again: 0, worn ones put back: 0
ZEDQA hft put back
ZEDQA hft end: 21 shots, 3 not taken or failed
ZEDQA hft DONE
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x4)
```

### 12. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 31183 at 08:44:32

```text
[ZeD.QA] state #12 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=23 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA rel put back 35 things; after: 32.6 of 18 kg, 61 items, Heavy Load 1 OVER
[ZeD.QA] run #12 ok=true
ZEDQA rel DONE
```

### 13. gallery_story_teardown.lua (`ZEDQA stt`) - PASS, 10 s

- go 31184 at 08:44:36

```text
[ZeD.QA] state #13 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=23 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stt start (17 steps)
[ZeD.QA] run #13 ok=true
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 0 native zombies' flag back
ZEDQA stt planks off 0 | blood cleaned on 0 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 44 items removed
ZEDQA stt back: 25 items, 18 worn
ZEDQA stt belt back: 4/4
ZEDQA stt character back: profession base:mechanics | 97 traits | 42 perks
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 2
ZEDQA stt ZeD back: dark teal small (was dark teal small)
ERROR: General f:13053 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA stt zoom 1
ZEDQA stt back at 925,13040 (was 925,13040) | carried 25 | zombies in the cell 0
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
```

### 14. gallery_v1_a_end.lua (`ZEDQA g1e`) - PASS, 1 s

- go 31185 at 08:44:49

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

- go 31186 at 08:44:54

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
