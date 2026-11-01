# ZeD-UI regression - 2026-11-01 15:32 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-01 15:32:46 |
| Finished | 2026-11-01 15:37:22 (4 min 36 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\AppData\Local\Temp\claude\C--Users-danie--claude-spares-spare-8vLpAQ\8d4042f4-6e83-4cb6-9f64-0a1e0b9a2dae\scratchpad\gallery_six_manifest.txt (15 scripts) |
| Result | **15/15 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 18038 to 18054 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 18053, 18054)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_t14_look.lua | g14l | PASS | 1 |  |  |
| 3 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 4 | gallery_v3_core.lua | g3c | PASS | 19 |  |  |
| 5 | gallery_v3_reveal.lua | g3r | PASS | 10 |  |  |
| 6 | gallery_v3_stage.lua | g3s | PASS | 8 |  |  |
| 7 | gallery_nov1_only_six.lua | n1o6 | PASS | 1 |  |  |
| 8 | gallery_nov1_lot.lua | n1l | PASS | 16 |  |  |
| 9 | gallery_nov1_cohesion.lua | n1c | PASS | 26 | zqa_cw_01_dark_small_card.png, zqa_cw_01b_help_line.png, zqa_cw_02_dark_small_window_menu_theme.png, zqa_cw_08_seethrough_100.png, zqa_cw_12_seethrough_60.png, zqa_cw_12b_solid_in_use.png, zqa_cw_14_focus_hand_inventory_row.png, zqa_cw_16_focus_corners_inventory_row.png, zqa_cw_18_focus_wash_inventory_row.png, zqa_cw_20_focus_ants_inventory_row.png |  |
| 10 | gallery_v3_teardown.lua | g3t | PASS | 10 |  |  |
| 11 | gallery_t14_look.lua | g14l2 | PASS | 1 |  |  |
| 12 | gallery_story_stage.lua | sts | PASS | 33 |  |  |
| 13 | gallery_nov1_story.lua | n1s | PASS | 7 |  |  |
| 14 | gallery_story_teardown.lua | stt | PASS | 10 |  |  |
| 15 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 18038 at 15:33:45

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_t14_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 18039 at 15:33:50

```text
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark orange small | GAL_LOOK dark orange, GAL_STILL 20
[ZeD.QA] run #2 ok=true
ZEDQA g14l DONE
```

### 3. gallery_daylight.lua (`ZEDQA day`) - PASS, 2 s

- go 18040 at 15:33:54

```text
[ZeD.QA] windows reset (R)
ZEDQA day time 12.86 -> 11.00
[ZeD.QA] run #3 ok=true
ZEDQA day DONE
```

### 4. gallery_v3_core.lua (`ZEDQA g3c`) - PASS, 19 s

- go 18041 at 15:34:00

```text
[ZeD.QA] windows reset (R)
ZEDQA g3c start (18 steps)
[ZeD.QA] run #4 ok=true
ZEDQA g3c start at 925,13040 zoom 1 | ZeD true
ZEDQA g3c forced spot 13935,5729
ZEDQA g3c standing at 13935,5729 floor blends_street_01_102 outside true | cars within 22: 2 | zombies in the cell 0
ZEDQA g3c floors round the spot: blends_street_01=81
ZEDQA g3c zoom 1.75
ZEDQA g3c shot g3_scout_wide ok
ZEDQA g3c zoom 1
ZEDQA g3c shot g3_scout_mid ok
ZEDQA g3c end: 2 shots ok, 0 errors
ZEDQA g3c DONE
```

### 5. gallery_v3_reveal.lua (`ZEDQA g3r`) - PASS, 10 s

- go 18042 at 15:34:22

```text
[ZeD.QA] windows reset (R)
ZEDQA g3r start (172 steps)
[ZeD.QA] run #5 ok=true
ZEDQA g3r toured: 16 stops
ZEDQA g3r end: 0 shots ok, 0 errors
ZEDQA g3r DONE
```

### 6. gallery_v3_stage.lua (`ZEDQA g3s`) - PASS, 8 s

- go 18043 at 15:34:35

```text
[ZeD.QA] windows reset (R)
ZEDQA g3s start (15 steps)
[ZeD.QA] run #6 ok=true
ZEDQA g3s aside: 6 worn, 1 on the belt, 71 items, hands nil / nil
ZEDQA g3s worn: Tshirt_DefaultTEXTURE_TINT Shirt_Lumberjack Jacket_ArmyOliveDrab Vest_Hunting_Khaki Trousers_Denim Socks_Heavy Shoes_ArmyBoots Gloves_LeatherGlovesBlack Hat_BaseballCapGreen Belt2 HolsterSimple_Black Kneepad_Left_Tactical Kneepad_Right_Tactical WristWatch_Left_DigitalBlack Glasses_Prescription_Aviators Bag_ALICEpack_Army Bag_ChestRig Bag_FannyPackBack Bag_Satchel_Leather
ZEDQA g3s bag back (Base.Bag_ALICEpack_Army): 13 things
ZEDQA g3s bag webbing (Base.Bag_ChestRig): 3 things
ZEDQA g3s bag fannypackback (Base.Bag_FannyPackBack): 2 things
ZEDQA g3s bag satchel (Base.Bag_Satchel_Leather): 3 things
ZEDQA g3s belt: HuntingKnife@smallbeltleft Hammer@smallbeltright Pistol@holsterright Shotgun@back
ZEDQA g3s hotbar slots: Back* HolsterRight* SmallBeltLeft* SmallBeltRight* BedrollBottomALICE
ZEDQA g3s trunk lid: open
ZEDQA g3s trunk: 11 things
ZEDQA g3s trunk area centre 13936.2,5729.2: the character goes to 13936.16,5729.63
ZEDQA g3s at 13936,5729: in the trunk area true, trunk reachable true
ZEDQA g3s duffel on the ground: 9 things
ZEDQA g3s parked cars spawned: 2 | cars within 22 now: 3
ZEDQA g3s background zombies: 8 | in the cell 8
ZEDQA g3s zombies still there after 150 frames: 8/8 | in the cell 8
ZEDQA g3s zoom 1
ZEDQA g3s shot g3_stage_mid ok
ZEDQA g3s end: 1 shots ok, 0 errors
ZEDQA g3s DONE
```

### 7. gallery_nov1_only_six.lua (`ZEDQA n1o6`) - PASS, 1 s

- go 18044 at 15:34:47

```text
[ZeD.QA] windows reset (R)
ZEDQA n1o6 sections: health, furniture; story 02
[ZeD.QA] run #7 ok=true
ZEDQA n1o6 DONE
```

### 8. gallery_nov1_lot.lua (`ZEDQA n1l`) - PASS, 16 s

- go 18045 at 15:34:51

```text
[ZeD.QA] windows reset (R)
ZEDQA n1l start (40 steps)
[ZeD.QA] run #8 ok=true
ZEDQA n1l theme dark orange size small | scale nil
ZEDQA n1l zoom 1
ZEDQA n1l tall: char 777x2118 at 1136,21 | world 777x2118 at 1927,21 | screen 3840x2160
ZEDQA n1l health pop-up: settled (7 rows 14,1733 334x245)
ZEDQA n1l health: the pointer to Upper Torso at 601,300 (17 parts) | pop-up open true
ZEDQA n1l note: zed_11: the tab did not read the pointer's part (hovered nil): set by hand
ZEDQA n1l note: step 16 timed out
ZEDQA n1l health pop-up, before the shot: settled (7 rows 14,1733 334x245)
ZEDQA n1l health: hovered Upper Torso active Upper Torso | pop-up true 7 rows 14,1733 334x245 | pick pushups
ZEDQA n1l shot zed_11_health_exercise ok
ZEDQA n1l rect zed_11_health_exercise char drawer 359 67 840 2033 window 296 21 1617 2118 header 65 footer 39 tab health
ZEDQA n1l rect zed_11_health_exercise world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1l health: hovered Upper Torso active Upper Torso | pop-up open false
ZEDQA n1l shot zed_11b_health_hover ok
ZEDQA n1l rect zed_11b_health_hover char drawer 359 67 840 2033 window 296 21 1617 2118 header 65 footer 39 tab health
ZEDQA n1l rect zed_11b_health_hover world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1l furniture: the pointer's square 13935,5728 (isoToScreen named 13929,5736)
ZEDQA n1l furniture: furniture_seating_outdoor_01_0 (Park Bench) placed at 13935,5728 | movable for the game true
ZEDQA n1l furniture: mode pickup | the tab reads Park Bench at 13935,5728
ZEDQA n1l shot zed_52_furniture ok
ZEDQA n1l rect zed_52_furniture char drawer 1199 67 0 2033 window 1136 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1l rect zed_52_furniture world drawer 2641 67 840 2033 window 1927 21 1617 2118 header 65 footer 39 tab furniture
ZEDQA n1l furniture put back: the piece removed
ZEDQA n1l put back: heights, places, tabs, options | theme dark orange
ZEDQA n1l end: 3 shots ok, 0 errors
ZEDQA n1l DONE
```

### 9. gallery_nov1_cohesion.lua (`ZEDQA n1c`) - PASS, 26 s

- go 18046 at 15:35:10
- screenshots: zqa_cw_01_dark_small_card.png, zqa_cw_01b_help_line.png, zqa_cw_02_dark_small_window_menu_theme.png, zqa_cw_08_seethrough_100.png, zqa_cw_12_seethrough_60.png, zqa_cw_12b_solid_in_use.png, zqa_cw_14_focus_hand_inventory_row.png, zqa_cw_16_focus_corners_inventory_row.png, zqa_cw_18_focus_wash_inventory_row.png, zqa_cw_20_focus_ants_inventory_row.png

```text
[ZeD.QA] windows reset (R)
ZEDQA n1c start (86 steps)
[ZeD.QA] run #9 ok=true
ZEDQA n1c start: theme dark/orange/small, see-through index 2, solid false, highlight hand, grid key false
ZEDQA n1c added: apples true, hammer true
ZEDQA n1c shot zqa_cw_01_dark_small_card | both windows: Character on its inventory with the apple's card open (card item Apple), World on Loot | theme dark, accent orange, size small | see-through 90 | solid while in use off | highlight hand | input mode kbm | grid false
ZEDQA n1c shot zqa_cw_01_dark_small_card ok
ZEDQA n1c rect zqa_cw_01_dark_small_card char drawer 814 67 385 2033 window 751 21 1162 2118 header 65 footer 39 tab loot
ZEDQA n1c rect zqa_cw_01_dark_small_card world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c note: cw_01b: the window box hover: not reached
ZEDQA n1c note: step 15 timed out
ZEDQA n1c note: cw_01b: no hover on the window box (pointer on the window false, above it: nothing)
ZEDQA n1c shot zqa_cw_01b_help_line | the pointer resting on the Character window's window box (1872,32-1895,55): its hover false, pointer on the window false; the footer help line shows the box's plain-words help | theme dark, accent orange, size small | see-through 90 | solid while in use off | highlight hand | input mode kbm | grid false
ZEDQA n1c shot zqa_cw_01b_help_line ok
ZEDQA n1c rect zqa_cw_01b_help_line char drawer 814 67 385 2033 window 751 21 1162 2118 header 65 footer 39 tab loot
ZEDQA n1c rect zqa_cw_01b_help_line world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c shot zqa_cw_02_dark_small_window_menu_theme | the Character window's window box menu pulled down, its Theme submenu open, the pointer on the theme in use | theme dark, accent orange, size small | see-through 90 | solid while in use off | highlight hand | input mode kbm | grid false
ZEDQA n1c shot zqa_cw_02_dark_small_window_menu_theme ok
ZEDQA n1c rect zqa_cw_02_dark_small_window_menu_theme char drawer 814 67 385 2033 window 751 21 1162 2118 header 65 footer 39 tab loot
ZEDQA n1c rect zqa_cw_02_dark_small_window_menu_theme world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c shot zqa_cw_08_seethrough_100 | both windows with the apple's card open at see-through 100, the world behind them | theme dark, accent orange, size small | see-through 100 | solid while in use off | highlight hand | input mode kbm | grid false
ZEDQA n1c shot zqa_cw_08_seethrough_100 ok
ZEDQA n1c rect zqa_cw_08_seethrough_100 char drawer 814 67 385 2033 window 751 21 1162 2118 header 65 footer 39 tab loot
ZEDQA n1c rect zqa_cw_08_seethrough_100 world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c shot zqa_cw_12_seethrough_60 | both windows with the apple's card open at see-through 60, the world behind them | theme dark, accent orange, size small | see-through 60 | solid while in use off | highlight hand | input mode kbm | grid false
ZEDQA n1c shot zqa_cw_12_seethrough_60 ok
ZEDQA n1c rect zqa_cw_12_seethrough_60 char drawer 814 67 385 2033 window 751 21 1162 2118 header 65 footer 39 tab loot
ZEDQA n1c rect zqa_cw_12_seethrough_60 world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c note: cw_12b: the Character window solid under the pointer: not reached
ZEDQA n1c note: step 43 timed out
ZEDQA n1c note: cw_12b: the pointer did not count (pointer on the window false, above it: nothing); the controller's focus instead
ZEDQA n1c shot zqa_cw_12b_solid_in_use | see-through 60 with Solid while in use on, the Character window in use by the controller's focus (its surface alpha 1), the World window see-through (0.6) | theme dark, accent orange, size small | see-through 60 | solid while in use on | highlight hand | input mode gamepad | grid false
ZEDQA n1c shot zqa_cw_12b_solid_in_use ok
ZEDQA n1c rect zqa_cw_12b_solid_in_use char drawer 814 67 385 2033 window 751 21 1162 2118 header 65 footer 39 tab loot
ZEDQA n1c rect zqa_cw_12b_solid_in_use world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c shot zqa_cw_14_focus_hand_inventory_row | pad focus on an inventory row of the Character window, list view (row Apple at y 100) | pad on zone charMainInv, element invrow:1, cues true | theme dark, accent orange, size small | see-through 90 | solid while in use off | highlight hand | input mode gamepad | grid false
ZEDQA n1c shot zqa_cw_14_focus_hand_inventory_row ok
ZEDQA n1c rect zqa_cw_14_focus_hand_inventory_row char drawer 1199 67 0 2033 window 1136 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c rect zqa_cw_14_focus_hand_inventory_row world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c shot zqa_cw_16_focus_corners_inventory_row | pad focus on an inventory row of the Character window, list view (row Apple at y 100) | pad on zone charMainInv, element invrow:1, cues true | theme dark, accent orange, size small | see-through 90 | solid while in use off | highlight corners | input mode gamepad | grid false
ZEDQA n1c shot zqa_cw_16_focus_corners_inventory_row ok
ZEDQA n1c rect zqa_cw_16_focus_corners_inventory_row char drawer 1199 67 0 2033 window 1136 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c rect zqa_cw_16_focus_corners_inventory_row world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c shot zqa_cw_18_focus_wash_inventory_row | pad focus on an inventory row of the Character window, list view (row Apple at y 100) | pad on zone charMainInv, element invrow:1, cues true | theme dark, accent orange, size small | see-through 90 | solid while in use off | highlight wash | input mode gamepad | grid false
ZEDQA n1c shot zqa_cw_18_focus_wash_inventory_row ok
ZEDQA n1c rect zqa_cw_18_focus_wash_inventory_row char drawer 1199 67 0 2033 window 1136 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c rect zqa_cw_18_focus_wash_inventory_row world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c shot zqa_cw_20_focus_ants_inventory_row | pad focus on an inventory row of the Character window, list view (row Apple at y 100) | pad on zone charMainInv, element invrow:1, cues true | theme dark, accent orange, size small | see-through 90 | solid while in use off | highlight ants | input mode gamepad | grid false
ZEDQA n1c shot zqa_cw_20_focus_ants_inventory_row ok
ZEDQA n1c rect zqa_cw_20_focus_ants_inventory_row char drawer 1199 67 0 2033 window 1136 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c rect zqa_cw_20_focus_ants_inventory_row world drawer 2641 67 0 2033 window 1927 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1c put back: the settings, the options file, the windows, the added items
ZEDQA n1c end: 10 shots ok, 0 errors
ZEDQA n1c DONE
```

### 10. gallery_v3_teardown.lua (`ZEDQA g3t`) - PASS, 10 s

- go 18047 at 15:35:40

```text
[ZeD.QA] windows reset (R)
ZEDQA g3t start (13 steps)
[ZeD.QA] run #10 ok=true
ZEDQA g3t removed 8 zombies, 4 ground things, 3 cars | zombies left in the cell 0
ZEDQA g3t kit off: 18 worn, 31 items removed
ZEDQA g3t back: 71 items, 6 worn, hands nil / nil
ZEDQA g3t belt back: 1/1
ERROR: General f:10239 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:10247 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA g3t zoom 1
ZEDQA g3t back at 925,13040 (was 925,13040) | carried 71 | zombies in the cell 0
ZEDQA g3t end: 0 shots ok, 0 errors
ZEDQA g3t DONE
```

### 11. gallery_t14_look.lua (`ZEDQA g14l2`) - PASS, 1 s

- go 18048 at 15:35:53

```text
[ZeD.QA] windows reset (R)
ZEDQA g14l2 desk menu bar: Debug left out true
ZEDQA g14l2 position readout and cheat lines off true
ZEDQA g14l2 left-edge column hidden true
ZEDQA g14l2 look dark orange small | GAL_LOOK dark orange, GAL_STILL 20
[ZeD.QA] run #11 ok=true
ZEDQA g14l2 DONE
```

### 12. gallery_story_stage.lua (`ZEDQA sts`) - PASS, 33 s

- go 18049 at 15:35:58

```text
[ZeD.QA] windows reset (R)
ZEDQA sts start (22 steps)
[ZeD.QA] run #12 ok=true
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
ZEDQA sts aside: 6 worn, 1 on the belt, 71 items
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
ZEDQA sts car fuel 3.5 / 59.0
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

### 13. gallery_nov1_story.lua (`ZEDQA n1s`) - PASS, 7 s

- go 18050 at 15:36:33

```text
[ZeD.QA] windows reset (R)
ZEDQA n1s start (16 steps)
[ZeD.QA] run #13 ok=true
ZEDQA n1s theme dark orange | options kept: 1 2
ZEDQA n1s zoom 1
ZEDQA n1s journal: Page pop-up open true with 5 pages (1 2 3 4 5) | 5 rows 11,55 208x175
ZEDQA n1s shot story_02a_journal_entry ok
ZEDQA n1s box story_02a_journal_entry char 716,21-2333,2139
ZEDQA n1s box story_02a_journal_entry char windowbox 2292,32-2315,55
ZEDQA n1s box story_02a_journal_entry char drawer 779,67-1619,2100
ZEDQA n1s box story_02a_journal_entry world 2347,21-3124,2139
ZEDQA n1s box story_02a_journal_entry world windowbox 3083,32-3106,55
ZEDQA n1s box story_02a_journal_entry world drawer 3061,67-3061,2100
ZEDQA n1s put back: heights, tabs, theme options | theme dark orange
ZEDQA n1s end: 1 shots ok, 0 errors
ZEDQA n1s DONE
```

### 14. gallery_story_teardown.lua (`ZEDQA stt`) - PASS, 10 s

- go 18051 at 15:36:44

```text
[ZeD.QA] windows reset (R)
ZEDQA stt start (17 steps)
[ZeD.QA] run #14 ok=true
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 0 native zombies' flag back
ZEDQA stt planks off 0 | blood cleaned on 1 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 44 items removed
ZEDQA stt back: 71 items, 6 worn
ZEDQA stt belt back: 1/1
ZEDQA stt character back: profession base:mechanics | 97 traits | 42 perks
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 2
ZEDQA stt ZeD back: dark orange small (was dark orange small)
ERROR: General f:16784 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:16793 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA stt zoom 1
ZEDQA stt back at 925,13040 (was 925,13040) | carried 71 | zombies in the cell 0
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
```

### 15. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 18052 at 15:36:57

```text
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now dark teal
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
