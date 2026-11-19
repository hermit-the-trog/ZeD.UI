# ZeD-UI regression - 2026-11-18 16:36 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-18 16:36:16 |
| Finished | 2026-11-18 16:40:20 (4 min 3 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\gallery_v1_route.txt (12 scripts) |
| Result | **11/12 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 29787 to 29800 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29799, 29800)
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
| 7 | gallery_v1_route_only.lua | rto | PASS | 1 |  |  |
| 8 | gallery_story_stage.lua | sts | WARN | 57 |  | 1 ERR line(s) |
| 9 | gallery_nov1_story.lua | n1s | PASS | 12 |  |  |
| 10 | gallery_story_teardown.lua | stt | PASS | 10 |  |  |
| 11 | gallery_b11_look.lua | g14l2 | PASS | 1 |  |  |
| 12 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 29787 at 16:37:48

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

- go 29788 at 16:37:54

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 29789 at 16:37:58

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

- go 29790 at 16:38:02

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 14.88 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 29791 at 16:38:08

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls short sighted false, prescription glasses off
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 29792 at 16:38:13

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_v1_route_only.lua (`ZEDQA rto`) - PASS, 1 s

- go 29793 at 16:38:17

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rto beats: 03
[ZeD.QA] run #7 ok=true
ZEDQA rto DONE
```

### 8. gallery_story_stage.lua (`ZEDQA sts`) - WARN, 57 s

- go 29794 at 16:38:21
- 1 ERR line(s)

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sts short sighted false
ZEDQA sts start (22 steps)
[ZeD.QA] run #8 ok=true
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
ZEDQA sts car Base.CarStationWagon at 12081,7154 facing N: the pump finder sees 12078,7154 | tank area 12079.8,7155.2
ZEDQA sts car fuel 2.9 / 49.0
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

### 9. gallery_nov1_story.lua (`ZEDQA n1s`) - PASS, 12 s

- go 29795 at 16:39:22

```text
[ZeD.QA] state #9 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA n1s start (18 steps)
[ZeD.QA] run #9 ok=true
ZEDQA n1s theme dark teal | options kept: 1 6
ZEDQA n1s zoom 1
ZEDQA n1s map: flyer place 12084,7154 | the store 12060,7121 | note true (the stage's)
ZEDQA n1s map zoom 14 | pin true | key open true
ZEDQA n1s hover card on fossoil2
ZEDQA n1s map on screen: panel 2221,197 840x1839 | pin 2637,1127 26x32 | note 2632,1099 | zoom 14
ZEDQA n1s shot story_03_route_map ok
ZEDQA n1s box story_03_route_map char 716,21-1493,2139
ZEDQA n1s box story_03_route_map char windowbox 1452,32-1475,55
ZEDQA n1s box story_03_route_map char drawer 779,67-779,2100
ZEDQA n1s box story_03_route_map world 1507,21-3124,2139
ZEDQA n1s box story_03_route_map world windowbox 3083,32-3106,55
ZEDQA n1s box story_03_route_map world drawer 2221,67-3061,2100
ZEDQA n1s map on screen: panel 2221,197 840x1839 | pin 2637,1127 26x32 | note 2632,1099 | zoom 14
ZEDQA n1s shot story_03b_route_note ok
ZEDQA n1s box story_03b_route_note char 716,21-1493,2139
ZEDQA n1s box story_03b_route_note char windowbox 1452,32-1475,55
ZEDQA n1s box story_03b_route_note char drawer 779,67-779,2100
ZEDQA n1s box story_03b_route_note world 1507,21-3124,2139
ZEDQA n1s box story_03b_route_note world windowbox 3083,32-3106,55
ZEDQA n1s box story_03b_route_note world drawer 2221,67-3061,2100
ZEDQA n1s map put back: key nil, hover hooks off
ZEDQA n1s put back: heights, tabs, theme options | theme dark teal
ZEDQA n1s end: 2 shots ok, 0 errors
ZEDQA n1s DONE
```

### 10. gallery_story_teardown.lua (`ZEDQA stt`) - PASS, 10 s

- go 29796 at 16:39:37

```text
[ZeD.QA] state #10 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stt start (17 steps)
[ZeD.QA] run #10 ok=true
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 18 native zombies' flag back
ZEDQA stt planks off 0 | blood cleaned on 0 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 44 items removed
ZEDQA stt back: 55 items, 7 worn
ZEDQA stt belt back: 1/1
ZEDQA stt character back: profession base:mechanics | 97 traits | 42 perks
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 2
ZEDQA stt ZeD back: dark teal small (was dark teal small)
ERROR: General f:8125 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA stt zoom 1
ZEDQA stt back at 925,13040 (was 925,13040) | carried 55 | zombies in the cell 0
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
```

### 11. gallery_b11_look.lua (`ZEDQA g14l2`) - PASS, 1 s

- go 29797 at 16:39:50

```text
[ZeD.QA] state #11 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l2 desk menu bar: Debug left out true
ZEDQA g14l2 position readout and cheat lines off true
ZEDQA g14l2 left-edge column hidden true
ZEDQA g14l2 look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #11 ok=true
ZEDQA g14l2 DONE
```

### 12. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 29798 at 16:39:55

```text
[ZeD.QA] state #12 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
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
