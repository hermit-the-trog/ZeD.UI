# ZeD-UI regression - 2026-11-17 12:24 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 12:24:47 |
| Finished | 2026-11-17 12:29:21 (4 min 33 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\gallery_b19_menus.txt (19 scripts) |
| Result | **19/19 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 28231 to 28251 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28250, 28251)
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
| 8 | gallery_v3_core.lua | g3c | PASS | 19 |  | late output from unl (19 line(s), not counted) |
| 9 | gallery_v3_reveal.lua | g3r | PASS | 11 |  | late output from unl (14 line(s), not counted) |
| 10 | gallery_v3_stage.lua | g3s | PASS | 9 |  | late output from unl (13 line(s), not counted) |
| 11 | gallery_loadouts.lua | glo | PASS | 10 |  | late output from unl (10 line(s), not counted) |
| 12 | gallery_v3_teardown.lua | g3t | PASS | 10 |  | late output from unl (14 line(s), not counted) |
| 13 | gallery_b19_story05_only.lua | s05 | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 14 | gallery_story_stage.lua | sts | PASS | 32 |  | late output from unl (35 line(s), not counted) |
| 15 | gallery_story_shots.lua | stz | PASS | 13 |  | late output from unl (20 line(s), not counted) |
| 16 | gallery_story_teardown.lua | stt | PASS | 10 |  | late output from unl (15 line(s), not counted) |
| 17 | gallery_b11_look.lua | g14l2 | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 18 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 19 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28231 at 12:25:50

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

- go 28232 at 12:25:55

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28233 at 12:26:00

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

- go 28234 at 12:26:04

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.65 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 28235 at 12:26:10

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls wearing Base.Glasses_Prescription
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28236 at 12:26:16

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28237 at 12:26:20

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 49.8 of 8 kg, 115 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 59 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 8.2 of 8 kg, 56 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #7 ok=true
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (x3)
```

### 8. gallery_v3_core.lua (`ZEDQA g3c`) - PASS, 19 s

- go 28238 at 12:26:24
- late output from unl (19 line(s), not counted)

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3c start (18 steps)
[ZeD.QA] run #8 ok=true
ZEDQA g3c start at 925,13040 zoom 1 | ZeD true
ZEDQA g3c forced spot 13935,5729
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x9)
ZEDQA g3c standing at 13935,5729 floor blends_street_01_102 outside true | cars within 22: 1 | zombies in the cell 0
ZEDQA g3c floors round the spot: blends_street_01=81
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x3)
ZEDQA g3c zoom 1.75
ZEDQA g3c shot g3_scout_wide ok
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x3)
ZEDQA g3c zoom 1
ZEDQA g3c shot g3_scout_mid ok
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)
ZEDQA g3c end: 2 shots ok, 0 errors
ZEDQA g3c DONE
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x3)
```

### 9. gallery_v3_reveal.lua (`ZEDQA g3r`) - PASS, 11 s

- go 28239 at 12:26:47
- late output from unl (14 line(s), not counted)

```text
[ZeD.QA] state #9 speed=1 paused=false player=13935,5729 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3r start (172 steps)
[ZeD.QA] run #9 ok=true
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x10)
ZEDQA g3r toured: 16 stops
ZEDQA g3r end: 0 shots ok, 0 errors
ZEDQA g3r DONE
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x4)
```

### 10. gallery_v3_stage.lua (`ZEDQA g3s`) - PASS, 9 s

- go 28240 at 12:27:01
- late output from unl (13 line(s), not counted)

```text
[ZeD.QA] state #10 speed=1 paused=false player=13935,5729 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3s start (15 steps)
[ZeD.QA] run #10 ok=true
ZEDQA g3s aside: 7 worn, 0 on the belt, 56 items, hands nil / nil
ZEDQA unl load 0.0 of 8 kg, 0 items, Heavy Load 0   (late output from unl)
ZEDQA g3s worn: Tshirt_DefaultTEXTURE_TINT Shirt_Lumberjack Jacket_ArmyOliveDrab Vest_Hunting_Khaki Trousers_Denim Socks_Heavy Shoes_ArmyBoots Gloves_LeatherGlovesBlack Hat_BaseballCapGreen Belt2 HolsterSimple_Black Kneepad_Left_Tactical Kneepad_Right_Tactical WristWatch_Left_DigitalBlack Glasses_Prescription_Aviators Bag_ALICEpack_Army Bag_ChestRig Bag_FannyPackBack Bag_Satchel_Leather
ZEDQA g3s bag back (Base.Bag_ALICEpack_Army): 13 things
ZEDQA g3s bag webbing (Base.Bag_ChestRig): 3 things
ZEDQA g3s bag fannypackback (Base.Bag_FannyPackBack): 2 things
ZEDQA g3s bag satchel (Base.Bag_Satchel_Leather): 3 things
ZEDQA unl load 12.5 of 8 kg, 43 items, Heavy Load 1   (late output from unl)
ZEDQA g3s belt: HuntingKnife@smallbeltleft Hammer@smallbeltright Pistol@holsterright Shotgun@back
ZEDQA g3s hotbar slots: Back* HolsterRight* SmallBeltLeft* SmallBeltRight* BedrollBottomALICE
ZEDQA unl load 21.1 of 8 kg, 48 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA g3s trunk lid: open
ZEDQA g3s trunk: 11 things
ZEDQA g3s trunk area centre 13936.2,5729.0: the character goes to 13936.15,5729.42
ZEDQA unl load 21.1 of 8 kg, 49 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA g3s at 13936,5729: in the trunk area true, trunk reachable true
ZEDQA g3s duffel on the ground: 9 things
ZEDQA g3s parked cars spawned: 4 | cars within 22 now: 2
ZEDQA g3s background zombies: 8 | in the cell 8
ZEDQA unl load 21.1 of 8 kg, 49 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA g3s zombies still there after 150 frames: 8/8 | in the cell 8
ZEDQA unl load 21.1 of 8 kg, 49 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA g3s zoom 1
ZEDQA g3s shot g3_stage_mid ok
ZEDQA unl load 21.1 of 8 kg, 49 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA g3s end: 1 shots ok, 0 errors
ZEDQA g3s DONE
ZEDQA unl load 21.1 of 8 kg, 49 items, Heavy Load 1 OVER   (late output from unl)   (x3)
```

### 11. gallery_loadouts.lua (`ZEDQA glo`) - PASS, 10 s

- go 28241 at 12:27:13
- late output from unl (10 line(s), not counted)

```text
[ZeD.QA] state #11 speed=1 paused=false player=13936,5729 grid=19 inCar=false vehicles=20 missing=get
[ZeD.QA] windows reset (R)
ZEDQA glo start
[ZeD.QA] run #11 ok=true
ZEDQA glo machete true, apple true
ZEDQA unl load 21.1 of 8 kg, 49 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA glo shot zed_70_loadout_save
ZEDQA unl load 21.1 of 8 kg, 49 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA glo ready 1 of 5
ZEDQA glo shot zed_71_loadout_fold
ZEDQA unl load 21.1 of 8 kg, 49 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA glo shot zed_72_loadout_todo
ZEDQA unl load 21.1 of 8 kg, 49 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA glo shot zed_73_loadout_todo_lines
ZEDQA unl load 21.1 of 8 kg, 49 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA glo put back
ZEDQA glo DONE
ZEDQA unl load 21.1 of 8 kg, 49 items, Heavy Load 1 OVER   (late output from unl)   (x3)
```

### 12. gallery_v3_teardown.lua (`ZEDQA g3t`) - PASS, 10 s

- go 28242 at 12:27:27
- late output from unl (14 line(s), not counted)

```text
[ZeD.QA] state #12 speed=1 paused=false player=13936,5729 grid=19 inCar=false vehicles=20 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3t start (13 steps)
[ZeD.QA] run #12 ok=true
ZEDQA g3t removed 8 zombies, 4 ground things, 5 cars | zombies left in the cell 0
ZEDQA g3t kit off: 18 worn, 31 items removed
ZEDQA unl load 0.0 of 8 kg, 0 items, Heavy Load 0   (late output from unl)
ZEDQA g3t back: 56 items, 7 worn, hands nil / nil
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)
ZEDQA g3t belt back: 0/0
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)
ERROR: General f:7536 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x7)
ZEDQA g3t zoom 1
ZEDQA g3t back at 925,13040 (was 925,13040) | carried 56 | zombies in the cell 0
ZEDQA g3t end: 0 shots ok, 0 errors
ZEDQA g3t DONE
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x4)
```

### 13. gallery_b19_story05_only.lua (`ZEDQA s05`) - PASS, 1 s

- go 28243 at 12:27:40
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #13 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA s05 beats: 05
[ZeD.QA] run #13 ok=true
ZEDQA s05 DONE
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x4)
```

### 14. gallery_story_stage.lua (`ZEDQA sts`) - PASS, 32 s

- go 28244 at 12:27:45
- late output from unl (35 line(s), not counted)

```text
[ZeD.QA] state #14 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sts start (22 steps)
[ZeD.QA] run #14 ok=true
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)
ZEDQA sts start at 925,13040 | site: Fossoil, West Point | ZeD true
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x8)
ZEDQA sts at the store: room fossoil, building true
ZEDQA sts stock spot 12053,7121 with 3 shelf containers in reach
ZEDQA sts counter 12054,7123 clerk 12053,7123 queue toward 1,0
ZEDQA sts pump 12066,7147 (location_shop_fossoil_01_13), 8 pump squares round the store
ZEDQA sts window 12063,7127, barricaded from 12063,7127
ZEDQA sts windows 9 (smashed 2, barricaded 0) | shelves 19 counters 7 other containers 13 | free floor 81
ZEDQA sts container types: cardboardbox=2 metal_shelves=1 shelves=14 shelvesmag=4 fridge=10 counter=7 cashregister=1
ZEDQA sts blood 12060,7121
ZEDQA sts smoke spot 12073,7130
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x10)
ZEDQA sts aside: 7 worn, 0 on the belt, 56 items
ZEDQA unl load 0.0 of 8 kg, 0 items, Heavy Load 0   (late output from unl)
ZEDQA sts worn: Tshirt_DefaultTEXTURE_TINT Shirt_Lumberjack Jacket_ArmyOliveDrab Vest_Hunting_Khaki Trousers_Denim Socks_Heavy Shoes_ArmyBoots Gloves_LeatherGlovesBlack Hat_BaseballCapGreen Belt2 HolsterSimple_Black Kneepad_Left_Tactical Kneepad_Right_Tactical WristWatch_Left_DigitalBlack Glasses_Prescription_Aviators Bag_ALICEpack_Army Bag_ChestRig Bag_FannyPackBack Bag_Satchel_Leather
ZEDQA sts bag back (Base.Bag_ALICEpack_Army): 13 things
ZEDQA sts bag webbing (Base.Bag_ChestRig): 3 things
ZEDQA sts bag fannypackback (Base.Bag_FannyPackBack): 2 things
ZEDQA sts bag satchel (Base.Bag_Satchel_Leather): 2 things
ZEDQA sts loose: 19/19
ZEDQA sts belt: HuntingKnife@smallbeltleft Hammer@smallbeltright Pistol@holsterright Shotgun@back
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts character was: profession base:unemployed, 28 traits on, 42 perks kept
ZEDQA sts profession base:mechanics | traits base:mechanics2 SMOKER SPEED_DEMON STRONG DEXTROUS FAST_READER PRONE_TO_ILLNESS HEARTY_APPETITE SLOW_HEALER PACIFIST | skills Strength=9 Fitness=5 Mechanics=4 MetalWelding=1
ZEDQA sts power: option set true | pump square grid power true, no-power zone false
ZEDQA sts pumps filled: 8 | the pump reads 500
ZEDQA sts car placements to try: 80
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 1 (12068,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 2 (12064,7147 N) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 3 (12068,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 4 (12064,7147 S) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 5 (12067,7149 E) no good: pump false, tank area free false
ZEDQA sts note: placement 6 (12065,7149 W) no good: pump false, tank area free false
ZEDQA sts note: placement 7 (12068,7148 N) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 8 (12068,7146 S) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 9 (12066,7150 E) no good: pump false, tank area free false
ZEDQA sts note: placement 10 (12069,7147 N) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts car Base.CarStationWagon at 12063,7147 facing S: the pump finder sees 12066,7147 | tank area 12064.2,7145.9
ZEDQA sts car fuel 2.3 / 39.0
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts native zombies near the store made useless: 0
ZEDQA sts passive zombies outside: 7
ZEDQA sts blood on 1 squares | stains read back true | blood decals option 10
ZEDQA sts seeds: flyer fossoil2 read (was true) | journal true | note true star true
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA sts zoom 1.5
ZEDQA sts shot story_00_scout ok
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts staged: car true | zombies 7 outside | blood 1 | carried 44
ZEDQA sts end: 1 shots ok, 0 errors
ZEDQA sts DONE
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x3)
```

### 15. gallery_story_shots.lua (`ZEDQA stz`) - PASS, 13 s

- go 28245 at 12:28:19
- late output from unl (20 line(s), not counted)

```text
[ZeD.QA] state #15 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stz start (16 steps)
[ZeD.QA] run #15 ok=true
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz theme dark teal | profession base:mechanics
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA stz zoom 0.75
ZEDQA stz world menu: Window | Clean Stains | Sit on ground | Walk to
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz window submenu true: < Back | Smash Window | Barricade (Planks) | barricade picked true
ZEDQA stz shot story_05a_barricade_menu ok
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA unl load 29.4 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA unl load 26.3 of 8 kg, 58 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz story_05b_barricade_bar: ISBarricadeAction at 40% (2 of that type queued)
ZEDQA stz shot story_05b_barricade_bar ok
ZEDQA unl load 26.3 of 8 kg, 58 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA unl load 25.3 of 8 kg, 55 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA unl load 23.2 of 8 kg, 55 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA unl load 22.2 of 8 kg, 52 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz planks on the window: 3
ZEDQA unl load 23.3 of 8 kg, 52 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz theme now dark teal (the teardown re-applies the options)
ZEDQA stz end: 2 shots ok, 0 errors
ZEDQA stz DONE
ZEDQA unl load 23.3 of 8 kg, 52 items, Heavy Load 1 OVER   (late output from unl)   (x3)
```

### 16. gallery_story_teardown.lua (`ZEDQA stt`) - PASS, 10 s

- go 28246 at 12:28:36
- late output from unl (15 line(s), not counted)

```text
[ZeD.QA] state #16 speed=1 paused=false player=12063,7127 grid=19 inCar=false vehicles=10 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stt start (17 steps)
[ZeD.QA] run #16 ok=true
ZEDQA unl load 23.3 of 8 kg, 52 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 0 native zombies' flag back
ZEDQA stt planks off 3 | blood cleaned on 1 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 35 items removed
ZEDQA unl load 0.0 of 8 kg, 0 items, Heavy Load 0   (late output from unl)
ZEDQA stt back: 56 items, 7 worn
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)
ZEDQA stt belt back: 0/0
ZEDQA stt character back: profession base:unemployed | 97 traits | 42 perks
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 2
ZEDQA stt ZeD back: dark teal small (was dark teal small)
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)
ERROR: General f:13233 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x7)
ZEDQA stt zoom 1
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)
ZEDQA stt back at 925,13040 (was 925,13040) | carried 56 | zombies in the cell 0
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x3)
```

### 17. gallery_b11_look.lua (`ZEDQA g14l2`) - PASS, 1 s

- go 28247 at 12:28:49
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #17 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l2 desk menu bar: Debug left out true
ZEDQA g14l2 position readout and cheat lines off true
ZEDQA g14l2 left-edge column hidden true
ZEDQA g14l2 look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #17 ok=true
ZEDQA g14l2 DONE
ZEDQA unl load 8.2 of 8 kg, 56 items, Heavy Load 1   (late output from unl)   (x4)
```

### 18. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28248 at 12:28:53

```text
[ZeD.QA] state #18 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.2 of 8 kg, 56 items, Heavy Load 1
ZEDQA rel put back 59 things; after: 49.8 of 8 kg, 115 items, Heavy Load 1 OVER
[ZeD.QA] run #18 ok=true
ZEDQA rel DONE
```

### 19. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 28249 at 12:28:58

```text
[ZeD.QA] state #19 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #19 ok=true
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
