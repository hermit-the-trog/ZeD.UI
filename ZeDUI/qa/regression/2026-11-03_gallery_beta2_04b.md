# ZeD-UI regression - 2026-11-03 14:45 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-03 14:45:24 |
| Finished | 2026-11-03 14:48:35 (3 min 11 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/gallery_beta2_story04b.txt (7 scripts) |
| Result | **7/7 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 19681 to 19689 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 19688, 19689)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | gallery_t14_look.lua | g14l | PASS | 1 |  |  |
| 3 | gallery_story_only.lua | sto | PASS | 1 |  |  |
| 4 | gallery_story_stage.lua | sts | PASS | 39 |  |  |
| 5 | gallery_story_shots.lua | stz | PASS | 32 |  |  |
| 6 | gallery_story_teardown.lua | stt | PASS | 10 |  |  |
| 7 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 19681 at 14:46:22

```text
[ZeD.QA] state #1 speed=1 paused=false player=928,13043 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 928,13043,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_t14_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 19682 at 14:46:31

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark orange small | GAL_LOOK dark orange, GAL_STILL 20
[ZeD.QA] run #2 ok=true
ZEDQA g14l DONE
```

### 3. gallery_story_only.lua (`ZEDQA sto`) - PASS, 1 s

- go 19683 at 14:46:35

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sto beats: 04, 04b
[ZeD.QA] run #3 ok=true
ZEDQA sto DONE
```

### 4. gallery_story_stage.lua (`ZEDQA sts`) - PASS, 39 s

- go 19684 at 14:46:39

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sts start (22 steps)
[ZeD.QA] run #4 ok=true
ZEDQA sts start at 925,13040 | site: Fossoil, West Point | ZeD true
ZEDQA sts at the store: room fossoil, building true
ZEDQA sts stock spot 12053,7121 with 3 shelf containers in reach
ZEDQA sts counter 12054,7123 clerk 12053,7123 queue toward 1,0
ZEDQA sts pump 12066,7147 (location_shop_fossoil_01_13), 8 pump squares round the store
ZEDQA sts window 12063,7127, barricaded from 12063,7127
ZEDQA sts windows 9 (smashed 2, barricaded 0) | shelves 19 counters 7 other containers 13 | free floor 81
ZEDQA sts container types: cardboardbox=2 metal_shelves=1 shelves=14 shelvesmag=4 fridge=10 counter=7 cashregister=1
ZEDQA sts blood 12060,7121
ZEDQA sts smoke spot 12073,7130
ZEDQA sts aside: 6 worn, 1 on the belt, 98 items
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
ZEDQA sts car placements to try: 73
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
ZEDQA sts note: placement 18 (12064,7154 N) no good: pump false, tank area free false
ZEDQA sts note: placement 19 (12068,7154 S) no good: pump false, tank area free false
ZEDQA sts note: placement 20 (12064,7154 S) no good: pump false, tank area free false
ZEDQA sts note: placement 21 (12067,7156 E) no good: pump false, tank area free false
ZEDQA sts note: placement 22 (12065,7156 W) no good: pump false, tank area free false
ZEDQA sts note: placement 23 (12068,7155 N) no good: pump false, tank area free false
ZEDQA sts note: placement 24 (12068,7153 S) no good: pump false, tank area free false
ZEDQA sts note: placement 25 (12069,7154 N) no good: pump false, tank area free false
ZEDQA sts note: placement 26 (12066,7151 W) no good: pump false, tank area free false
ZEDQA sts car Base.CarStationWagon at 12063,7154 facing S: the pump finder sees 12066,7154 | tank area 12064.2,7152.9
ZEDQA sts car fuel 2.3 / 39.0
ZEDQA sts native zombies near the store made useless: 0
ZEDQA sts passive zombies outside: 7
ZEDQA sts blood on 1 squares | stains read back true | blood decals option 10
ZEDQA sts seeds: flyer fossoil2 read (was true) | journal true | note true star true
ZEDQA sts zoom 1.5
ZEDQA sts shot story_00_scout ok
ZEDQA sts staged: car true | zombies 7 outside | blood 1 | carried 44
ZEDQA sts end: 1 shots ok, 0 errors
ZEDQA sts DONE
```

### 5. gallery_story_shots.lua (`ZEDQA stz`) - PASS, 32 s

- go 19685 at 14:47:21

```text
[ZeD.QA] state #5 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=14 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stz start (25 steps)
[ZeD.QA] run #5 ok=true
ZEDQA stz theme dark orange | profession base:mechanics
ZEDQA stz zoom 1
ZEDQA stz seat chooser true pointed 1
ZEDQA stz box story_04a seats 1631,622-2209,1538
ZEDQA stz box story_04a seats windowbox 2168,633-2191,656
ZEDQA stz shot story_04a_seat_chooser ok
ZEDQA stz in the car true
ZEDQA stz dash low fuel: fuel 2.3/39.0 | dash fuel 0.05805814354720449 lamp true lights false running true
ZEDQA stz shot story_04a_dash_low_fuel ok
ZEDQA stz tire off: TireFrontLeft (Base.OldTire1 in the inventory)
ZEDQA stz shot story_04b_vehicle_tab_tire ok
ZEDQA stz box story_04b_vehicle_tab_tire char 716,0-1493,735
ZEDQA stz box story_04b_vehicle_tab_tire char windowbox 1452,11-1475,34
ZEDQA stz box story_04b_vehicle_tab_tire world 1507,0-3124,735
ZEDQA stz box story_04b_vehicle_tab_tire world windowbox 3083,11-3106,34
ZEDQA stz install button true | verb install
ZEDQA stz story_04b_tire_install_bar: ISInstallVehiclePart at 35% (1 of that type queued)
ZEDQA stz shot story_04b_tire_install_bar ok
ZEDQA stz box story_04b_tire_install_bar world 1507,0-3124,735
ZEDQA stz box story_04b_tire_install_bar world windowbox 3083,11-3106,34
ZEDQA stz tire back on: true
ZEDQA stz theme now dark orange (the teardown re-applies the options)
ZEDQA stz end: 4 shots ok, 0 errors
ZEDQA stz DONE
```

### 6. gallery_story_teardown.lua (`ZEDQA stt`) - PASS, 10 s

- go 19686 at 14:47:56

```text
[ZeD.QA] state #6 speed=1 paused=false player=12064,7155 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stt start (17 steps)
[ZeD.QA] run #6 ok=true
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 0 native zombies' flag back
ZEDQA stt planks off 0 | blood cleaned on 1 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 43 items removed
ZEDQA stt back: 98 items, 6 worn
ZEDQA stt belt back: 1/1
ZEDQA stt character back: profession base:mechanics | 97 traits | 42 perks
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 2
ZEDQA stt ZeD back: dark orange small (was dark orange small)
ERROR: General f:7834 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:7842 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA stt zoom 1
ZEDQA stt back at 925,13040 (was 925,13040) | carried 98 | zombies in the cell 0
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
```

### 7. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 19687 at 14:48:09

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now dark teal
[ZeD.QA] run #7 ok=true
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
