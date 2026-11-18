# ZeD-UI regression - 2026-11-17 16:26 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 16:26:32 |
| Finished | 2026-11-17 16:31:00 (4 min 28 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\gallery_v1_c1_zed.txt (15 scripts) |
| Result | **15/15 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 28448 to 28464 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28463, 28464)
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
| 7 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 8 | gallery_v1_c1_common.lua | c1c | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 9 | gallery_v1_c1_house.lua | c1h | PASS | 56 | zqa_cw_01_dark_small_card.png, zqa_cw_02_dark_small_window_menu_theme.png, zqa_cw_14_focus_hand_inventory_row.png | late output from unl (58 line(s), not counted) |
| 10 | gallery_b11_look.lua | g14l2 | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 11 | gallery_v1_c1_street.lua | c1s | PASS | 47 | zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_g4_belt_toast.png, zqa_g4_window_radio.png, zqa_g4_guide_bubble.png | late output from unl (59 line(s), not counted) |
| 12 | gallery_v1_c1_store.lua | c1x | PASS | 8 | zqa_sbx_pause_line.png, zqa_sbx_world_help.png | late output from unl (13 line(s), not counted) |
| 13 | gallery_v1_c1_end.lua | c1e | PASS | 7 |  | late output from unl (10 line(s), not counted) |
| 14 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 15 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28448 at 16:27:38

```text
[ZeD.QA] state #1 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
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

- go 28449 at 16:27:43

```text
[ZeD.QA] state #2 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28450 at 16:27:48

```text
[ZeD.QA] state #3 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #3 ok=true
ZEDQA g14l DONE
```

### 4. gallery_daylight.lua (`ZEDQA day`) - PASS, 2 s

- go 28451 at 16:27:52

```text
[ZeD.QA] state #4 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 13.86 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 28452 at 16:27:57

```text
[ZeD.QA] state #5 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls wearing Base.Glasses_Prescription
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28453 at 16:28:02

```text
[ZeD.QA] state #6 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28454 at 16:28:07

```text
[ZeD.QA] state #7 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 8.3 of 8 kg, 58 items, Heavy Load 1
ZEDQA unl taken out of the inventory for the run: 1 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 8.1 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #7 ok=true
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1   (x3)
```

### 8. gallery_v1_c1_common.lua (`ZEDQA c1c`) - PASS, 1 s

- go 28455 at 16:28:11
- late output from unl (4 line(s), not counted)

```text
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1   (late output from unl)
[ZeD.QA] state #8 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA c1c helpers ready | ZeD loaded true | start 926,13040 | load 8.1 of 8 kg, 57 items, Heavy Load 1
[ZeD.QA] run #8 ok=true
ZEDQA c1c DONE
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1   (late output from unl)   (x3)
```

### 9. gallery_v1_c1_house.lua (`ZEDQA c1h`) - PASS, 56 s

- go 28456 at 16:28:15
- late output from unl (58 line(s), not counted)
- screenshots: zqa_cw_01_dark_small_card.png, zqa_cw_02_dark_small_window_menu_theme.png, zqa_cw_14_focus_hand_inventory_row.png

```text
[ZeD.QA] state #9 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA c1h start (63 steps)
[ZeD.QA] run #9 ok=true
ZEDQA c1h to kitchen: from 926,13040
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1   (late output from unl)   (x8)
ZEDQA c1h place kitchen: the kitchen of the house at 12021-12033,7078-7090 (West Point) | square 12029,7081 room kitchen floor floors_interior_tilesandwood_01_1 | 0 zombies within 30 squares taken out of the world
ZEDQA unl load 8.1 of 8 kg, 57 items, Heavy Load 1   (late output from unl)
ZEDQA c1h grid power here false
ZEDQA layout c1h default
ZEDQA c1h look dark teal size small | screen 3840x2160
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1h shot zed_18_card_food at kitchen 12029,7081
ZEDQA c1h load zed_18_card_food: 8.1 of 20 kg, 57 items, Heavy Load 0
ZEDQA c1h box zed_18_card_food character 1760,776-2080,1196 (zoom 1)
ZEDQA c1h box zed_18_card_food ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1h box zed_18_card_food SpeedControls 3641,-4000-3830,-3972
ZEDQA c1h box zed_18_card_food MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1h box zed_18_card_food ISHotbar -10000,-10000--9806,-9918
ZEDQA c1h box zed_18_card_food WaterMarkUI 3602,2127-3830,2149
ZEDQA c1h box zed_18_card_food ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1h box zed_18_card_food ZeD_Watch 3596,10-3824,62
ZEDQA c1h box zed_18_card_food ZeD_Window 21,0-798,735
ZEDQA c1h box zed_18_card_food ZeD_Window 2657,0-3819,735
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1h shot zed_19_card_weapon at kitchen 12029,7081
ZEDQA c1h load zed_19_card_weapon: 8.1 of 20 kg, 57 items, Heavy Load 0
ZEDQA c1h box zed_19_card_weapon character 1760,776-2080,1196 (zoom 1)
ZEDQA c1h box zed_19_card_weapon ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1h box zed_19_card_weapon SpeedControls 3641,-4000-3830,-3972
ZEDQA c1h box zed_19_card_weapon MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1h box zed_19_card_weapon ISHotbar -10000,-10000--9806,-9918
ZEDQA c1h box zed_19_card_weapon WaterMarkUI 3602,2127-3830,2149
ZEDQA c1h box zed_19_card_weapon ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1h box zed_19_card_weapon ZeD_Watch 3596,10-3824,62
ZEDQA c1h box zed_19_card_weapon ZeD_Window 21,0-798,735
ZEDQA c1h box zed_19_card_weapon ZeD_Window 2657,0-3819,735
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 8.3 of 20 kg, 58 items, Heavy Load 0   (late output from unl)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1h shot zed_20_ctx_strip at kitchen 12029,7081
ZEDQA c1h load zed_20_ctx_strip: 8.3 of 20 kg, 58 items, Heavy Load 0
ZEDQA c1h box zed_20_ctx_strip character 1760,776-2080,1196 (zoom 1)
ZEDQA c1h box zed_20_ctx_strip ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1h box zed_20_ctx_strip SpeedControls 3641,-4000-3830,-3972
ZEDQA c1h box zed_20_ctx_strip MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1h box zed_20_ctx_strip ISHotbar -10000,-10000--9806,-9918
ZEDQA c1h box zed_20_ctx_strip WaterMarkUI 3602,2127-3830,2149
ZEDQA c1h box zed_20_ctx_strip ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1h box zed_20_ctx_strip ZeD_Watch 3596,10-3824,62
ZEDQA c1h box zed_20_ctx_strip ZeD_Window 21,0-798,735
ZEDQA c1h box zed_20_ctx_strip ZeD_Window 819,0-1596,735
ZEDQA c1h box zed_20_ctx_strip ISContextMenu 0,0-226,232
ZEDQA c1h box zed_20_ctx_strip ZeD_ContextMenu 1572,745-2272,1084 COVERS the character
ZEDQA unl load 8.3 of 20 kg, 58 items, Heavy Load 0   (late output from unl)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1h shot zed_21_ctx_list at kitchen 12029,7081
ZEDQA c1h load zed_21_ctx_list: 8.3 of 20 kg, 58 items, Heavy Load 0
ZEDQA c1h box zed_21_ctx_list character 1760,776-2080,1196 (zoom 1)
ZEDQA c1h box zed_21_ctx_list ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1h box zed_21_ctx_list SpeedControls 3641,-4000-3830,-3972
ZEDQA c1h box zed_21_ctx_list MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1h box zed_21_ctx_list ISHotbar -10000,-10000--9806,-9918
ZEDQA c1h box zed_21_ctx_list WaterMarkUI 3602,2127-3830,2149
ZEDQA c1h box zed_21_ctx_list ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1h box zed_21_ctx_list ZeD_Watch 3596,10-3824,62
ZEDQA c1h box zed_21_ctx_list ZeD_Window 21,0-798,735
ZEDQA c1h box zed_21_ctx_list ZeD_Window 819,0-1596,735
ZEDQA c1h box zed_21_ctx_list ISContextMenu 0,0-226,232
ZEDQA c1h box zed_21_ctx_list ZeD_ContextList 0,0-3840,2160 (full-screen layer)
ZEDQA unl load 8.3 of 20 kg, 58 items, Heavy Load 0   (late output from unl)
ZEDQA c1h recipe open: AddACigarette
ZEDQA unl load 8.3 of 20 kg, 58 items, Heavy Load 0   (late output from unl)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1h shot zed_13_crafting at kitchen 12029,7081
ZEDQA c1h load zed_13_crafting: 8.3 of 20 kg, 58 items, Heavy Load 0
ZEDQA c1h box zed_13_crafting character 1760,776-2080,1196 (zoom 1)
ZEDQA c1h box zed_13_crafting ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1h box zed_13_crafting SpeedControls 3641,-4000-3830,-3972
ZEDQA c1h box zed_13_crafting MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1h box zed_13_crafting ISHotbar -10000,-10000--9806,-9918
ZEDQA c1h box zed_13_crafting WaterMarkUI 3602,2127-3830,2149
ZEDQA c1h box zed_13_crafting ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1h box zed_13_crafting ZeD_Watch 3596,10-3824,62
ZEDQA c1h box zed_13_crafting ZeD_Window 21,0-798,735
ZEDQA c1h box zed_13_crafting ZeD_Window 2202,0-3819,735
ZEDQA unl load 8.3 of 20 kg, 58 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 16.5 of 20 kg, 74 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1h shot zed_53b_grid_tinted at kitchen 12029,7081
ZEDQA c1h load zed_53b_grid_tinted: 16.5 of 20 kg, 74 items, Heavy Load 0
ZEDQA c1h box zed_53b_grid_tinted character 1760,776-2080,1196 (zoom 1)
ZEDQA c1h box zed_53b_grid_tinted ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1h box zed_53b_grid_tinted SpeedControls 3641,-4000-3830,-3972
ZEDQA c1h box zed_53b_grid_tinted MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1h box zed_53b_grid_tinted ISHotbar -10000,-10000--9806,-9918
ZEDQA c1h box zed_53b_grid_tinted WaterMarkUI 3602,2127-3830,2149
ZEDQA c1h box zed_53b_grid_tinted ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1h box zed_53b_grid_tinted ZeD_Watch 3596,10-3824,62
ZEDQA c1h box zed_53b_grid_tinted ZeD_Window 21,0-798,735
ZEDQA c1h box zed_53b_grid_tinted ZeD_Window 819,0-1596,735
ZEDQA unl load 16.5 of 20 kg, 74 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 8.3 of 20 kg, 58 items, Heavy Load 0   (late output from unl)
ZEDQA c1h place living: the living room of the house at 12021-12033,7078-7090 (West Point) | square 12027,7080 room livingroom floor floors_interior_tilesandwood_01_50 | 0 zombies within 30 squares taken out of the world
ZEDQA unl load 8.3 of 20 kg, 58 items, Heavy Load 0   (late output from unl)
ZEDQA c1h grid power here true
ZEDQA unl load 10.2 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1h shot zqa_cw_01_dark_small_card at living 12027,7080
ZEDQA c1h load zqa_cw_01_dark_small_card: 10.2 of 20 kg, 61 items, Heavy Load 0
ZEDQA c1h box zqa_cw_01_dark_small_card character 1760,776-2080,1196 (zoom 1)
ZEDQA c1h box zqa_cw_01_dark_small_card ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1h box zqa_cw_01_dark_small_card SpeedControls 3641,-4000-3830,-3972
ZEDQA c1h box zqa_cw_01_dark_small_card MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1h box zqa_cw_01_dark_small_card ISHotbar -10000,-10000--9806,-9918
ZEDQA c1h box zqa_cw_01_dark_small_card WaterMarkUI 3602,2127-3830,2149
ZEDQA c1h box zqa_cw_01_dark_small_card ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1h box zqa_cw_01_dark_small_card ZeD_Watch 3596,10-3824,62
ZEDQA c1h box zqa_cw_01_dark_small_card ZeD_Window 21,0-1183,735
ZEDQA c1h box zqa_cw_01_dark_small_card ZeD_Window 3042,0-3819,735
ZEDQA unl load 10.2 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA c1h shot zqa_cw_02_dark_small_window_menu_theme at living 12027,7080
ZEDQA c1h load zqa_cw_02_dark_small_window_menu_theme: 10.2 of 20 kg, 61 items, Heavy Load 0
ZEDQA c1h box zqa_cw_02_dark_small_window_menu_theme character 1760,776-2080,1196 (zoom 1)
ZEDQA c1h box zqa_cw_02_dark_small_window_menu_theme ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1h box zqa_cw_02_dark_small_window_menu_theme SpeedControls 3641,-4000-3830,-3972
ZEDQA c1h box zqa_cw_02_dark_small_window_menu_theme MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1h box zqa_cw_02_dark_small_window_menu_theme ISHotbar -10000,-10000--9806,-9918
ZEDQA c1h box zqa_cw_02_dark_small_window_menu_theme WaterMarkUI 3602,2127-3830,2149
ZEDQA c1h box zqa_cw_02_dark_small_window_menu_theme ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1h box zqa_cw_02_dark_small_window_menu_theme ZeD_Watch 3596,10-3824,62
ZEDQA c1h box zqa_cw_02_dark_small_window_menu_theme ZeD_Window 3042,0-3819,735
ZEDQA c1h box zqa_cw_02_dark_small_window_menu_theme ZeD_Window 21,0-1183,735
ZEDQA c1h box zqa_cw_02_dark_small_window_menu_theme ZeD_WindowMenu 0,0-3840,2160 (full-screen layer)
ZEDQA unl load 10.2 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1h shot zqa_cw_14_focus_hand_inventory_row at living 12027,7080
ZEDQA c1h load zqa_cw_14_focus_hand_inventory_row: 10.2 of 20 kg, 61 items, Heavy Load 0
ZEDQA c1h box zqa_cw_14_focus_hand_inventory_row character 1760,776-2080,1196 (zoom 1)
ZEDQA c1h box zqa_cw_14_focus_hand_inventory_row ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1h box zqa_cw_14_focus_hand_inventory_row SpeedControls 3641,-4000-3830,-3972
ZEDQA c1h box zqa_cw_14_focus_hand_inventory_row MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1h box zqa_cw_14_focus_hand_inventory_row ISHotbar -10000,-10000--9806,-9918
ZEDQA c1h box zqa_cw_14_focus_hand_inventory_row WaterMarkUI 3602,2127-3830,2149
ZEDQA c1h box zqa_cw_14_focus_hand_inventory_row ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1h box zqa_cw_14_focus_hand_inventory_row ZeD_Watch 3596,10-3824,62
ZEDQA c1h box zqa_cw_14_focus_hand_inventory_row ZeD_Window 819,0-1596,735
ZEDQA c1h box zqa_cw_14_focus_hand_inventory_row ZeD_Window 21,0-798,735
ZEDQA unl load 10.2 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA c1h zoom 0.5
ZEDQA unl load 10.2 of 18 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 11.2 of 18 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1h shot zed_32_action_bar_reading at living 12027,7080
ZEDQA c1h load zed_32_action_bar_reading: 11.2 of 18 kg, 62 items, Heavy Load 0
ZEDQA c1h box zed_32_action_bar_reading character 1600,472-2240,1312 (zoom 0.5)
ZEDQA c1h box zed_32_action_bar_reading ZeD_ActionBarLayer 1838,847-2030,951 COVERS the character
ZEDQA c1h box zed_32_action_bar_reading ZeD_HintStripHUD 1833,1915-2006,1954
ZEDQA c1h box zed_32_action_bar_reading SpeedControls 3641,-4000-3830,-3972
ZEDQA c1h box zed_32_action_bar_reading MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1h box zed_32_action_bar_reading ISHotbar -10000,-10000--9806,-9918
ZEDQA c1h box zed_32_action_bar_reading WaterMarkUI 3602,2127-3830,2149
ZEDQA c1h box zed_32_action_bar_reading ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1h box zed_32_action_bar_reading ZeD_MoodleLayer 1867,1965-1973,2013
ZEDQA c1h box zed_32_action_bar_reading ZeD_Watch 3596,10-3824,62
ZEDQA unl load 11.2 of 18 kg, 62 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA c1h endless: current action ISRestAction, maxTime -1
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1h shot zed_32b_action_endless at living 12027,7080
ZEDQA c1h load zed_32b_action_endless: 11.2 of 18 kg, 62 items, Heavy Load 0
ZEDQA c1h box zed_32b_action_endless character 1600,472-2240,1312 (zoom 0.5)
ZEDQA c1h box zed_32b_action_endless ZeD_HintStripHUD 1833,1915-2006,1954
ZEDQA c1h box zed_32b_action_endless ZeD_ActionBarLayer 1858,847-2010,951 COVERS the character
ZEDQA c1h box zed_32b_action_endless SpeedControls 3641,-4000-3830,-3972
ZEDQA c1h box zed_32b_action_endless MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1h box zed_32b_action_endless ISHotbar -10000,-10000--9806,-9918
ZEDQA c1h box zed_32b_action_endless WaterMarkUI 3602,2127-3830,2149
ZEDQA c1h box zed_32b_action_endless ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1h box zed_32b_action_endless ZeD_MoodleLayer 1838,1965-2002,2013
ZEDQA c1h box zed_32b_action_endless ZeD_Watch 3596,10-3824,62
ZEDQA unl load 11.2 of 18 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 11.2 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA c1h zoom 1
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA layout c1h put back
ZEDQA c1h put back: options, theme, List | Grid, sorts, things given and on the floor, input mode, zoom, stats, window layout
ZEDQA c1h end: 11 shots, 0 not taken or failed
ZEDQA c1h DONE
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
```

### 10. gallery_b11_look.lua (`ZEDQA g14l2`) - PASS, 1 s

- go 28457 at 16:29:14
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #10 speed=1 paused=false player=12027,7080 grid=19 inCar=false vehicles=8 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l2 desk menu bar: Debug left out true
ZEDQA g14l2 position readout and cheat lines off true
ZEDQA g14l2 left-edge column hidden true
ZEDQA g14l2 look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #10 ok=true
ZEDQA g14l2 DONE
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x4)
```

### 11. gallery_v1_c1_street.lua (`ZEDQA c1s`) - PASS, 47 s

- go 28458 at 16:29:19
- late output from unl (59 line(s), not counted)
- screenshots: zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_g4_belt_toast.png, zqa_g4_window_radio.png, zqa_g4_guide_bubble.png

```text
[ZeD.QA] state #11 speed=1 paused=false player=12027,7080 grid=19 inCar=false vehicles=8 missing=get
[ZeD.QA] windows reset (R)
ZEDQA c1s start (47 steps)
[ZeD.QA] run #11 ok=true
ZEDQA c1s to street: from 12027,7080
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
    Nov 17, 2026 4:29:21 PM zombie.iso.IsoCell PlaceLot
    SEVERE: Missing tile definition: overlay_graffiti_wall_02_4
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
    Nov 17, 2026 4:29:22 PM zombie.iso.IsoCell PlaceLot
    SEVERE: Missing tile definition: overlay_graffiti_wall_02_4
    Nov 17, 2026 4:29:22 PM zombie.iso.IsoCell PlaceLot
    SEVERE: Missing tile definition: overlay_graffiti_wall_02_4
    Nov 17, 2026 4:29:22 PM zombie.iso.IsoCell PlaceLot
    SEVERE: Missing tile definition: overlay_graffiti_wall_02_4
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x4)
ZEDQA c1s place street: West Point's main street, outside the cafe, the shops across the road | square 11966,6895 room nil floor blends_street_01_80 | 0 zombies within 30 squares taken out of the world
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA c1s grid power here true
ZEDQA c1s start | look dark teal small | kit watch nil
ZEDQA unl load 8.8 of 20 kg, 59 items, Heavy Load 0   (late output from unl)
ZEDQA c1s 01 two items: belt hand/s hand/p slot slot slot at 1535,2034
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot zqa_ht_01_two at street 11966,6895
ZEDQA c1s load zqa_ht_01_two: 8.8 of 20 kg, 59 items, Heavy Load 0
ZEDQA c1s box zqa_ht_01_two character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box zqa_ht_01_two ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box zqa_ht_01_two ZeD_ActionBarLayer 1858,847-2010,951 COVERS the character
ZEDQA c1s box zqa_ht_01_two SpeedControls 3641,-4000-3830,-3972
ZEDQA c1s box zqa_ht_01_two MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box zqa_ht_01_two ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box zqa_ht_01_two WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box zqa_ht_01_two ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1s box zqa_ht_01_two ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA c1s box zqa_ht_01_two ZeD_Watch 3596,10-3824,62
ZEDQA unl load 8.8 of 20 kg, 59 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.2 of 20 kg, 59 items, Heavy Load 0   (late output from unl)
ZEDQA c1s 02 both hands: belt hand/s(peek) hand/p slot slot slot at 1598,2034
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot zqa_ht_02_both at street 11966,6895
ZEDQA c1s load zqa_ht_02_both: 9.2 of 20 kg, 59 items, Heavy Load 0
ZEDQA c1s box zqa_ht_02_both character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box zqa_ht_02_both ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box zqa_ht_02_both ZeD_ActionBarLayer 1858,847-2010,951 COVERS the character
ZEDQA c1s box zqa_ht_02_both SpeedControls 3641,-4000-3830,-3972
ZEDQA c1s box zqa_ht_02_both MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box zqa_ht_02_both ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box zqa_ht_02_both WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box zqa_ht_02_both ZeD_BeltHUD 1598,2034-2197,2132
ZEDQA c1s box zqa_ht_02_both ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA c1s box zqa_ht_02_both ZeD_Watch 3596,10-3824,62
ZEDQA unl load 9.2 of 20 kg, 59 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 11.6 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA c1s 06 right wrist, pistol: belt hand/s hand/p ammo watch slot slot slot at 1227,2034
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot zqa_ht_06_rightwatch_pistol at street 11966,6895
ZEDQA c1s load zqa_ht_06_rightwatch_pistol: 11.6 of 20 kg, 64 items, Heavy Load 0
ZEDQA c1s box zqa_ht_06_rightwatch_pistol character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box zqa_ht_06_rightwatch_pistol ZeD_ActionBarLayer 1858,847-2010,951 COVERS the character
ZEDQA c1s box zqa_ht_06_rightwatch_pistol ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box zqa_ht_06_rightwatch_pistol SpeedControls 3641,-3928-3830,-3900
ZEDQA c1s box zqa_ht_06_rightwatch_pistol Clock 3674,-4000-3830,-3938
ZEDQA c1s box zqa_ht_06_rightwatch_pistol MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box zqa_ht_06_rightwatch_pistol ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box zqa_ht_06_rightwatch_pistol WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box zqa_ht_06_rightwatch_pistol ZeD_BeltHUD 1227,2034-2197,2132
ZEDQA c1s box zqa_ht_06_rightwatch_pistol ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA unl load 11.6 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 13.5 of 20 kg, 63 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 13.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot gbw_DigitalBlack at street 11966,6895
ZEDQA c1s load gbw_DigitalBlack: 13.5 of 20 kg, 64 items, Heavy Load 0
ZEDQA c1s box gbw_DigitalBlack character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box gbw_DigitalBlack ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box gbw_DigitalBlack ZeD_ActionBarLayer 1858,847-2010,951 COVERS the character
ZEDQA c1s box gbw_DigitalBlack SpeedControls 3641,-3928-3830,-3900
ZEDQA c1s box gbw_DigitalBlack Clock 3674,-4000-3830,-3938
ZEDQA c1s box gbw_DigitalBlack MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box gbw_DigitalBlack ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box gbw_DigitalBlack WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box gbw_DigitalBlack ZeD_BeltHUD 1433,2034-2197,2132
ZEDQA c1s box gbw_DigitalBlack ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA unl load 13.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot gbw_DigitalTimez at street 11966,6895
ZEDQA c1s load gbw_DigitalTimez: 13.5 of 20 kg, 64 items, Heavy Load 0
ZEDQA c1s box gbw_DigitalTimez character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box gbw_DigitalTimez ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box gbw_DigitalTimez ZeD_ActionBarLayer 1858,847-2010,951 COVERS the character
ZEDQA c1s box gbw_DigitalTimez SpeedControls 3641,-3928-3830,-3900
ZEDQA c1s box gbw_DigitalTimez Clock 3674,-4000-3830,-3938
ZEDQA c1s box gbw_DigitalTimez MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box gbw_DigitalTimez ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box gbw_DigitalTimez WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box gbw_DigitalTimez ZeD_BeltHUD 1433,2034-2197,2132
ZEDQA c1s box gbw_DigitalTimez ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA unl load 13.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot gbw_ClassicGold at street 11966,6895
ZEDQA c1s load gbw_ClassicGold: 13.5 of 20 kg, 64 items, Heavy Load 0
ZEDQA c1s box gbw_ClassicGold character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box gbw_ClassicGold ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box gbw_ClassicGold ZeD_ActionBarLayer 1858,847-2010,951 COVERS the character
ZEDQA c1s box gbw_ClassicGold SpeedControls 3641,-3928-3830,-3900
ZEDQA c1s box gbw_ClassicGold Clock 3674,-4000-3830,-3938
ZEDQA c1s box gbw_ClassicGold MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box gbw_ClassicGold ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box gbw_ClassicGold WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box gbw_ClassicGold ZeD_BeltHUD 1433,2034-2197,2132
ZEDQA c1s box gbw_ClassicGold ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA unl load 13.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot gbw_DigitalRed at street 11966,6895
ZEDQA c1s load gbw_DigitalRed: 13.5 of 20 kg, 64 items, Heavy Load 0
ZEDQA c1s box gbw_DigitalRed character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box gbw_DigitalRed ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box gbw_DigitalRed ZeD_ActionBarLayer 1858,847-2010,951 COVERS the character
ZEDQA c1s box gbw_DigitalRed SpeedControls 3641,-3928-3830,-3900
ZEDQA c1s box gbw_DigitalRed Clock 3674,-4000-3830,-3938
ZEDQA c1s box gbw_DigitalRed MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box gbw_DigitalRed ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box gbw_DigitalRed WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box gbw_DigitalRed ZeD_BeltHUD 1433,2034-2197,2132
ZEDQA c1s box gbw_DigitalRed ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA unl load 13.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 13.5 of 20 kg, 63 items, Heavy Load 0   (late output from unl)
ZEDQA ff speed 3: time multiplier 20, true multiplier 20
ZEDQA unl load 14.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA c1s reading: progress 0.30
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot lpp_dark_detailed_read at street 11966,6895
ZEDQA c1s load lpp_dark_detailed_read: 14.5 of 20 kg, 64 items, Heavy Load 0
ZEDQA c1s box lpp_dark_detailed_read character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box lpp_dark_detailed_read ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box lpp_dark_detailed_read ZeD_ActionBarLayer 1836,909-2032,1013 COVERS the character
ZEDQA c1s box lpp_dark_detailed_read SpeedControls 3641,-4000-3830,-3972
ZEDQA c1s box lpp_dark_detailed_read MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box lpp_dark_detailed_read ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box lpp_dark_detailed_read WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box lpp_dark_detailed_read ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1s box lpp_dark_detailed_read ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA c1s box lpp_dark_detailed_read ZeD_Watch 3596,10-3824,62
ZEDQA unl load 14.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot lpp_dark_speech at street 11966,6895
ZEDQA c1s load lpp_dark_speech: 14.5 of 20 kg, 64 items, Heavy Load 0
ZEDQA c1s box lpp_dark_speech character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box lpp_dark_speech ZeD_ActionBarLayer 1836,907-2094,1021 COVERS the character
ZEDQA c1s box lpp_dark_speech ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box lpp_dark_speech SpeedControls 3641,-4000-3830,-3972
ZEDQA c1s box lpp_dark_speech MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box lpp_dark_speech ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box lpp_dark_speech WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box lpp_dark_speech ZeD_BeltHUD 1535,2034-2197,2132
ZEDQA c1s box lpp_dark_speech ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA c1s box lpp_dark_speech ZeD_Watch 3596,10-3824,62
ZEDQA unl load 14.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x7)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot zqa_g4_belt_toast at street 11966,6895
ZEDQA c1s load zqa_g4_belt_toast: 14.5 of 20 kg, 64 items, Heavy Load 0
ZEDQA c1s box zqa_g4_belt_toast character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box zqa_g4_belt_toast ZeD_ActionBarLayer 1836,907-2094,1021 COVERS the character
ZEDQA c1s box zqa_g4_belt_toast ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box zqa_g4_belt_toast SpeedControls 3641,-4000-3830,-3972
ZEDQA c1s box zqa_g4_belt_toast MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box zqa_g4_belt_toast ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box zqa_g4_belt_toast WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box zqa_g4_belt_toast ZeD_BeltHUD 1535,2034-2282,2132
ZEDQA c1s box zqa_g4_belt_toast ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA c1s box zqa_g4_belt_toast ZeD_Watch 3596,10-3824,62
ZEDQA c1s box zqa_g4_belt_toast ZeD_MessagesToasts 2148,1892-2456,2044
ZEDQA unl load 14.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA c1s moved messages from 1255,655 to 21,655 (left side)
ZEDQA unl load 14.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot zqa_g4_window_radio at street 11966,6895
ZEDQA c1s load zqa_g4_window_radio: 14.5 of 20 kg, 64 items, Heavy Load 0
ZEDQA c1s box zqa_g4_window_radio character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box zqa_g4_window_radio ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box zqa_g4_window_radio ZeD_ActionBarLayer 1836,907-2094,1021 COVERS the character
ZEDQA c1s box zqa_g4_window_radio SpeedControls 3641,-4000-3830,-3972
ZEDQA c1s box zqa_g4_window_radio MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box zqa_g4_window_radio ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box zqa_g4_window_radio WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box zqa_g4_window_radio ZeD_BeltHUD 1535,2034-2282,2132
ZEDQA c1s box zqa_g4_window_radio ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA c1s box zqa_g4_window_radio ZeD_Watch 3596,10-3824,62
ZEDQA c1s box zqa_g4_window_radio ZeD_MessagesWindow 21,655-1351,1504
ZEDQA c1s box zqa_g4_window_radio messages 21,655-1351,1504
ZEDQA unl load 14.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x4)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1s shot zqa_g4_guide_bubble at street 11966,6895
ZEDQA c1s load zqa_g4_guide_bubble: 14.5 of 20 kg, 64 items, Heavy Load 0
ZEDQA c1s box zqa_g4_guide_bubble character 1760,776-2080,1196 (zoom 1)
ZEDQA c1s box zqa_g4_guide_bubble ZeD_HintStripHUD 1833,1984-2006,2023
ZEDQA c1s box zqa_g4_guide_bubble ZeD_ActionBarLayer 1836,907-2094,1021 COVERS the character
ZEDQA c1s box zqa_g4_guide_bubble SpeedControls 3641,-4000-3830,-3972
ZEDQA c1s box zqa_g4_guide_bubble MoodlesUI 3782,-10000-3830,-7840
ZEDQA c1s box zqa_g4_guide_bubble ISHotbar -10000,-10000--9806,-9918
ZEDQA c1s box zqa_g4_guide_bubble WaterMarkUI 3602,2127-3830,2149
ZEDQA c1s box zqa_g4_guide_bubble ZeD_BeltHUD 1535,2034-2282,2132
ZEDQA c1s box zqa_g4_guide_bubble ZeD_MoodleLayer 1896,1965-1944,2013
ZEDQA c1s box zqa_g4_guide_bubble ZeD_Watch 3596,10-3824,62
ZEDQA c1s box zqa_g4_guide_bubble ZeD_MessagesToasts 2094,1854-2566,2044
ZEDQA unl load 14.5 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA c1s put back: theme, hands, things given, watches, options, Messages, the guide, time of day, speed, windows
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA c1s end: 12 shots, 0 not taken or failed
ZEDQA c1s DONE
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
```

### 12. gallery_v1_c1_store.lua (`ZEDQA c1x`) - PASS, 8 s

- go 28459 at 16:30:09
- late output from unl (13 line(s), not counted)
- screenshots: zqa_sbx_pause_line.png, zqa_sbx_world_help.png

```text
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
[ZeD.QA] state #12 speed=1 paused=false player=11966,6895 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA c1x start (12 steps)
[ZeD.QA] run #12 ok=true
ZEDQA c1x place grocery: inside the grocery on West Point's main street | square 11985,6913 room grocery floor floors_interior_tilesandwood_01_36 | 0 zombies within 30 squares taken out of the world
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA c1x grid power here true
ZEDQA c1x the Sandbox window will be 1855 px wide from x 21; the character's rect starts at x 1760
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1x shot zqa_sbx_pause_line at grocery 11985,6913
ZEDQA c1x load zqa_sbx_pause_line: 8.1 of 20 kg, 57 items, Heavy Load 0
ZEDQA c1x box zqa_sbx_pause_line character 1760,776-2080,1196 (zoom 1)
ZEDQA c1x box zqa_sbx_pause_line MainScreen 0,0-3840,2160 (full-screen layer)
ZEDQA c1x box zqa_sbx_pause_line pause 21,811-651,1349
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA c1x page World, help on true
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA c1x shot zqa_sbx_world_help at grocery 11985,6913
ZEDQA c1x load zqa_sbx_world_help: 8.1 of 20 kg, 57 items, Heavy Load 0
ZEDQA c1x box zqa_sbx_world_help character 1760,776-2080,1196 (zoom 1)
ZEDQA c1x box zqa_sbx_world_help MainScreen 0,0-3840,2160 (full-screen layer)
ZEDQA c1x box zqa_sbx_world_help sandbox 21,327-1876,1832 COVERS the character
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA c1x put back: the Sandbox switch, the window wraps, the pause menu, the window pair
ZEDQA c1x end: 2 shots, 0 not taken or failed
ZEDQA c1x DONE
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x4)
```

### 13. gallery_v1_c1_end.lua (`ZEDQA c1e`) - PASS, 7 s

- go 28460 at 16:30:20
- late output from unl (10 line(s), not counted)

```text
[ZeD.QA] state #13 speed=1 paused=false player=11985,6913 grid=19 inCar=false vehicles=11 missing=get
[ZeD.QA] windows reset (R)
ZEDQA c1e start (4 steps)
[ZeD.QA] run #13 ok=true
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ERROR: General f:10294 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA c1e put back: the place 926,13040,0, the grid power, the cheats, the speed
ZEDQA c1e end: 0 shots, 0 not taken or failed
ZEDQA c1e DONE
ZEDQA unl load 8.1 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x4)
```

### 14. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28461 at 16:30:31

```text
[ZeD.QA] state #14 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.1 of 20 kg, 57 items, Heavy Load 0
ZEDQA rel put back 1 things; after: 8.3 of 20 kg, 58 items, Heavy Load 0
[ZeD.QA] run #14 ok=true
ZEDQA rel DONE
```

### 15. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 28462 at 16:30:35

```text
[ZeD.QA] state #15 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
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
