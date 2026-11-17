# ZeD-UI regression - 2026-11-17 13:13 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 13:13:24 |
| Finished | 2026-11-17 13:16:47 (3 min 22 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\gallery_b19_tire.txt (10 scripts) |
| Result | **10/10 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 28312 to 28323 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28322, 28323)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_t14_look.lua | g14l | PASS | 1 |  |  |
| 3 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 4 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 5 | gallery_story_only.lua | sto | PASS | 1 |  | late output from unl (3 line(s), not counted) |
| 6 | gallery_story_stage.lua | sts | PASS | 37 |  | late output from unl (36 line(s), not counted) |
| 7 | gallery_story_shots.lua | stz | PASS | 32 |  | late output from unl (34 line(s), not counted) |
| 8 | gallery_story_teardown.lua | stt | PASS | 11 |  | late output from unl (16 line(s), not counted) |
| 9 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 10 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28312 at 13:14:26

```text
[ZeD.QA] state #1 speed=1 paused=false player=924,13040 grid=19 inCar=false vehicles=32 missing=get
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

### 2. gallery_t14_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28313 at 13:14:31

```text
[ZeD.QA] state #2 speed=1 paused=false player=924,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark orange small | GAL_LOOK dark orange, GAL_STILL 20
[ZeD.QA] run #2 ok=true
ZEDQA g14l DONE
```

### 3. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28314 at 13:14:35

```text
[ZeD.QA] state #3 speed=1 paused=false player=924,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #3 ok=true
ZEDQA hcn DONE
```

### 4. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28315 at 13:14:39

```text
[ZeD.QA] state #4 speed=1 paused=false player=924,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 50.0 of 8 kg, 117 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 60 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 8.2 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #4 ok=true
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (x3)
```

### 5. gallery_story_only.lua (`ZEDQA sto`) - PASS, 1 s

- go 28316 at 13:14:44
- late output from unl (3 line(s), not counted)

```text
[ZeD.QA] state #5 speed=1 paused=false player=924,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sto beats: 04, 04b
[ZeD.QA] run #5 ok=true
ZEDQA sto DONE
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (late output from unl)   (x3)
```

### 6. gallery_story_stage.lua (`ZEDQA sts`) - PASS, 37 s

- go 28317 at 13:14:48
- late output from unl (36 line(s), not counted)

```text
[ZeD.QA] state #6 speed=1 paused=false player=924,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sts start (22 steps)
[ZeD.QA] run #6 ok=true
ZEDQA sts start at 924,13040 | site: Fossoil, West Point | ZeD true
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (late output from unl)   (x9)
ZEDQA sts at the store: room fossoil, building true
ZEDQA sts stock spot 12053,7121 with 3 shelf containers in reach
ZEDQA sts counter 12054,7123 clerk 12053,7123 queue toward 1,0
ZEDQA sts pump 12066,7147 (location_shop_fossoil_01_13), 8 pump squares round the store
ZEDQA sts window 12063,7127, barricaded from 12063,7127
ZEDQA sts windows 9 (smashed 2, barricaded 0) | shelves 19 counters 7 other containers 13 | free floor 81
ZEDQA sts container types: cardboardbox=2 metal_shelves=1 shelves=14 shelvesmag=4 fridge=10 counter=7 cashregister=1
ZEDQA sts blood 12060,7121
ZEDQA sts smoke spot 12073,7130
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (late output from unl)   (x10)
ZEDQA sts aside: 7 worn, 0 on the belt, 57 items
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
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 2 (12064,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 3 (12068,7147 S) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 4 (12064,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 5 (12067,7149 E) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 6 (12065,7149 W) no good: pump false, tank area free false
ZEDQA sts note: placement 7 (12068,7148 N) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 8 (12068,7146 S) no good: pump false, tank area free false
ZEDQA sts note: placement 9 (12066,7150 E) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 10 (12069,7147 N) no good: pump false, tank area free false
ZEDQA sts car Base.CarStationWagon at 12063,7147 facing S: the pump finder sees 12066,7147 | tank area 12064.3,7145.9
ZEDQA sts car fuel 2.3 / 39.0
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts native zombies near the store made useless: 0
ZEDQA sts passive zombies outside: 7
ZEDQA sts blood on 1 squares | stains read back true | blood decals option 10
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
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

### 7. gallery_story_shots.lua (`ZEDQA stz`) - PASS, 32 s

- go 28318 at 13:15:28
- late output from unl (34 line(s), not counted)

```text
[ZeD.QA] state #7 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stz start (25 steps)
[ZeD.QA] run #7 ok=true
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz theme dark orange | profession base:mechanics
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA stz zoom 1
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz seat chooser nil pointed nil
ZEDQA stz shot story_04a_seat_chooser ok
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz in the car true
ZEDQA unl load 32.6 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)   (x4)
ZEDQA stz dash low fuel: fuel 2.3/39.0 | dash fuel 0.05823557346622709 lamp true lights false running true
ZEDQA stz shot story_04a_dash_low_fuel ok
ZEDQA unl load 32.5 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz tire off: TireFrontLeft (Base.OldTire1 in the inventory)
ZEDQA unl load 47.5 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x8)
ZEDQA stz shot story_04b_vehicle_tab_tire ok
ZEDQA stz box story_04b_vehicle_tab_tire char 716,0-1493,735
ZEDQA stz box story_04b_vehicle_tab_tire char windowbox 1452,11-1475,34
ZEDQA stz box story_04b_vehicle_tab_tire world 1507,0-3124,735
ZEDQA stz box story_04b_vehicle_tab_tire world windowbox 3083,11-3106,34
ZEDQA unl load 47.5 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz install button true | verb install
ZEDQA unl load 47.5 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA unl load 46.8 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA stz story_04b_tire_install_bar: ISInstallVehiclePart at 35% (1 of that type queued)
ZEDQA stz shot story_04b_tire_install_bar ok
ZEDQA stz box story_04b_tire_install_bar world 1507,0-3124,735
ZEDQA stz box story_04b_tire_install_bar world windowbox 3083,11-3106,34
ZEDQA unl load 46.8 of 8 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x4)
ZEDQA unl load 31.8 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz tire back on: true
ZEDQA stz theme now dark orange (the teardown re-applies the options)
ZEDQA stz end: 4 shots ok, 0 errors
ZEDQA stz DONE
ZEDQA unl load 31.8 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)   (x4)
```

### 8. gallery_story_teardown.lua (`ZEDQA stt`) - PASS, 11 s

- go 28319 at 13:16:03
- late output from unl (16 line(s), not counted)

```text
[ZeD.QA] state #8 speed=1 paused=false player=12064,7148 grid=19 inCar=false vehicles=10 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stt start (17 steps)
[ZeD.QA] run #8 ok=true
ZEDQA unl load 31.8 of 8 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 0 native zombies' flag back
ZEDQA stt planks off 0 | blood cleaned on 1 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 43 items removed
ZEDQA unl load 0.0 of 8 kg, 0 items, Heavy Load 0   (late output from unl)
ZEDQA stt back: 57 items, 7 worn
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (late output from unl)
ZEDQA stt belt back: 0/0
ZEDQA stt character back: profession base:unemployed | 97 traits | 42 perks
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 2
ZEDQA stt ZeD back: dark orange small (was dark orange small)
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (late output from unl)
ERROR: General f:7267 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (late output from unl)   (x8)
ZEDQA stt zoom 1
ZEDQA stt back at 924,13040 (was 924,13040) | carried 57 | zombies in the cell 0
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (late output from unl)   (x4)
```

### 9. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28320 at 13:16:17

```text
[ZeD.QA] state #9 speed=1 paused=false player=924,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.2 of 8 kg, 57 items, Heavy Load 1
ZEDQA rel put back 60 things; after: 50.0 of 8 kg, 117 items, Heavy Load 1 OVER
[ZeD.QA] run #9 ok=true
ZEDQA rel DONE
```

### 10. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 28321 at 13:16:21

```text
[ZeD.QA] state #10 speed=1 paused=false player=924,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #10 ok=true
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
