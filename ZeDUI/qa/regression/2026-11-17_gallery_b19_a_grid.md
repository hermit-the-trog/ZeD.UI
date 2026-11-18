# ZeD-UI regression - 2026-11-17 11:26 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 11:26:52 |
| Finished | 2026-11-17 11:33:09 (6 min 16 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\gallery_b19_a.txt (17 scripts) |
| Result | **17/17 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 28174 to 28192 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28191, 28192)
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
| 7 | gallery_v3_core.lua | g3c | PASS | 19 |  |  |
| 8 | gallery_v3_reveal.lua | g3r | PASS | 11 |  |  |
| 9 | gallery_v3_stage.lua | g3s | PASS | 9 |  |  |
| 10 | gallery_b19_a.lua | gb19a | PASS | 42 |  |  |
| 11 | gallery_v3_teardown.lua | g3t | PASS | 10 |  |  |
| 12 | gallery_b11_look.lua | g14l2 | PASS | 1 |  |  |
| 13 | gallery_b19_a.lua | gb19ah | PASS | 41 | zqa_ap_1_tab_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_4_popout_microwave.png, zqa_b19_speed_bubble.png |  |
| 14 | gallery_t14_radios.lua | g14r | PASS | 23 |  |  |
| 15 | zedqa_twoway.lua | tw | PASS | 51 | zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png |  |
| 16 | zedqa_hands_together.lua | ht | PASS | 18 | zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png |  |
| 17 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28174 at 11:27:57

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

- go 28175 at 11:28:02

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28176 at 11:28:07

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

- go 28177 at 11:28:11

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.57 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 28178 at 11:28:16

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls wearing Base.Glasses_Prescription
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28179 at 11:28:21

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_v3_core.lua (`ZEDQA g3c`) - PASS, 19 s

- go 28180 at 11:28:26

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3c start (18 steps)
[ZeD.QA] run #7 ok=true
ZEDQA g3c start at 925,13040 zoom 1 | ZeD true
ZEDQA g3c forced spot 13935,5729
ZEDQA g3c standing at 13935,5729 floor blends_street_01_102 outside true | cars within 22: 1 | zombies in the cell 0
ZEDQA g3c floors round the spot: blends_street_01=81
ZEDQA g3c zoom 1.75
ZEDQA g3c shot g3_scout_wide ok
ZEDQA g3c zoom 1
ZEDQA g3c shot g3_scout_mid ok
ZEDQA g3c end: 2 shots ok, 0 errors
ZEDQA g3c DONE
```

### 8. gallery_v3_reveal.lua (`ZEDQA g3r`) - PASS, 11 s

- go 28181 at 11:28:48

```text
[ZeD.QA] state #8 speed=1 paused=false player=13935,5729 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3r start (172 steps)
[ZeD.QA] run #8 ok=true
ZEDQA g3r toured: 16 stops
ZEDQA g3r end: 0 shots ok, 0 errors
ZEDQA g3r DONE
```

### 9. gallery_v3_stage.lua (`ZEDQA g3s`) - PASS, 9 s

- go 28182 at 11:29:02

```text
[ZeD.QA] state #9 speed=1 paused=false player=13935,5729 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3s start (15 steps)
[ZeD.QA] run #9 ok=true
ZEDQA g3s aside: 7 worn, 0 on the belt, 112 items, hands nil / nil
ZEDQA g3s worn: Tshirt_DefaultTEXTURE_TINT Shirt_Lumberjack Jacket_ArmyOliveDrab Vest_Hunting_Khaki Trousers_Denim Socks_Heavy Shoes_ArmyBoots Gloves_LeatherGlovesBlack Hat_BaseballCapGreen Belt2 HolsterSimple_Black Kneepad_Left_Tactical Kneepad_Right_Tactical WristWatch_Left_DigitalBlack Glasses_Prescription_Aviators Bag_ALICEpack_Army Bag_ChestRig Bag_FannyPackBack Bag_Satchel_Leather
ZEDQA g3s bag back (Base.Bag_ALICEpack_Army): 13 things
ZEDQA g3s bag webbing (Base.Bag_ChestRig): 3 things
ZEDQA g3s bag fannypackback (Base.Bag_FannyPackBack): 2 things
ZEDQA g3s bag satchel (Base.Bag_Satchel_Leather): 3 things
ZEDQA g3s belt: HuntingKnife@smallbeltleft Hammer@smallbeltright Pistol@holsterright Shotgun@back
ZEDQA g3s hotbar slots: Back* HolsterRight* SmallBeltLeft* SmallBeltRight* BedrollBottomALICE
ZEDQA g3s trunk lid: open
ZEDQA g3s trunk: 11 things
ZEDQA g3s trunk area centre 13936.2,5729.5: the character goes to 13936.20,5729.95
ZEDQA g3s at 13936,5729: in the trunk area true, trunk reachable true
ZEDQA g3s duffel on the ground: 9 things
ZEDQA g3s parked cars spawned: 4 | cars within 22 now: 2
ZEDQA g3s background zombies: 8 | in the cell 8
ZEDQA g3s zombies still there after 150 frames: 8/8 | in the cell 8
ZEDQA g3s zoom 1
ZEDQA g3s shot g3_stage_mid ok
ZEDQA g3s end: 1 shots ok, 0 errors
ZEDQA g3s DONE
```

### 10. gallery_b19_a.lua (`ZEDQA gb19a`) - PASS, 42 s

- go 28183 at 11:29:15

```text
[ZeD.QA] state #10 speed=1 paused=false player=13936,5729 grid=19 inCar=false vehicles=20 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gb19a start (the mall lot, 58 steps)
[ZeD.QA] run #10 ok=true
ZEDQA gb19a start: the mall lot at 13936,5729
ZEDQA gb19a look dark teal size small | scale 1.75 | font size option 2 | screen 3840x2160
ZEDQA gb19a zoom 1
ZEDQA gb19a set aside 8 things for the grid shots, load now about 13.9 kg
ZEDQA gb19a shot zed_53_grid
ZEDQA gb19a box zed_53_grid char 1136,0-1913,735
ZEDQA gb19a box zed_53_grid world 1927,0-2704,735
ZEDQA gb19a zed_53b_grid_tinted: inventory 19.8 of 50.0 kg
ZEDQA gb19a shot zed_53b_grid_tinted
ZEDQA gb19a box zed_53b_grid_tinted char 1136,0-1913,735
ZEDQA gb19a box zed_53b_grid_tinted world 1927,0-2704,735
ZEDQA gb19a put back 8 things set aside for the grid shots
ZEDQA gb19a apples given: inventory 19.3 of 50.0 kg
ZEDQA gb19a the apple stack opened: 5
ZEDQA gb19a zed_01_hero_mid: inventory 19.3 of 50.0 kg
ZEDQA gb19a open stack: Apple (5)
ZEDQA gb19a shot zed_01_hero_mid
ZEDQA gb19a box zed_01_hero_mid char 1136,0-1913,735
ZEDQA gb19a box zed_01_hero_mid world 1927,0-2704,735
ZEDQA gb19a shot zed_18_card_food
ZEDQA gb19a box zed_18_card_food char 1136,21-1913,2139
ZEDQA gb19a box zed_18_card_food world 1927,21-3089,2139
ZEDQA gb19a shot zed_19_card_weapon
ZEDQA gb19a box zed_19_card_weapon char 1136,21-1913,2139
ZEDQA gb19a box zed_19_card_weapon world 1927,21-3089,2139
ZEDQA gb19a shot zed_20_ctx_strip
ZEDQA gb19a box zed_20_ctx_strip char 1136,0-1913,735
ZEDQA gb19a box zed_20_ctx_strip world 1927,0-2704,735
ZEDQA gb19a shot zed_21_ctx_list
ZEDQA gb19a box zed_21_ctx_list char 1136,0-1913,735
ZEDQA gb19a box zed_21_ctx_list world 1927,0-2704,735
ZEDQA gb19a not taken: the Install / Uninstall / Take apart list variant (optional; the apple's menu is the spread's frame)
ZEDQA gb19a zoom 0.5
ZEDQA gb19a shot zed_32_action_bar_reading
ZEDQA gb19a endless: current action ISRestAction, maxTime -1
ZEDQA gb19a shot zed_32b_action_endless
ZEDQA gb19a zoom 1
ZEDQA layout gb19a put back
ZEDQA gb19a put back: options, theme, grid views, sorts, tint, given things, ground things, window places, speed, god mode
ZEDQA gb19a DONE
```

### 11. gallery_v3_teardown.lua (`ZEDQA g3t`) - PASS, 10 s

- go 28184 at 11:30:00

```text
[ZeD.QA] state #11 speed=1 paused=false player=13936,5729 grid=19 inCar=false vehicles=20 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3t start (13 steps)
[ZeD.QA] run #11 ok=true
ZEDQA g3t removed 8 zombies, 6 ground things, 5 cars | zombies left in the cell 0
ZEDQA g3t kit off: 18 worn, 31 items removed
ZEDQA g3t back: 112 items, 7 worn, hands nil / nil
ZEDQA g3t belt back: 0/0
ERROR: General f:9707 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA g3t zoom 1
ZEDQA g3t back at 925,13040 (was 925,13040) | carried 112 | zombies in the cell 0
ZEDQA g3t end: 0 shots ok, 0 errors
ZEDQA g3t DONE
```

### 12. gallery_b11_look.lua (`ZEDQA g14l2`) - PASS, 1 s

- go 28185 at 11:30:13

```text
[ZeD.QA] state #12 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l2 desk menu bar: Debug left out true
ZEDQA g14l2 position readout and cheat lines off true
ZEDQA g14l2 left-edge column hidden true
ZEDQA g14l2 look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #12 ok=true
ZEDQA g14l2 DONE
```

### 13. gallery_b19_a.lua (`ZEDQA gb19ah`) - PASS, 41 s

- go 28186 at 11:30:17
- screenshots: zqa_ap_1_tab_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_4_popout_microwave.png, zqa_b19_speed_bubble.png

```text
[ZeD.QA] state #13 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gb19ah start (the QA home, 57 steps)
[ZeD.QA] run #13 ok=true
ZEDQA gb19ah indoors at 892,13007: 5 room squares round, 3 sides
ZEDQA gb19ah look dark teal size small | scale 1.75 | font size option 2 | screen 3840x2160
ZEDQA gb19ah grid power here true | faces on true
ZEDQA gb19ah placed: oven true, microwave true
ZEDQA gb19ah the Craft tab's pop-out button: true
ZEDQA gb19ah shot zqa_ap_1_tab_stove
ZEDQA gb19ah box zqa_ap_1_tab_stove char 1134,0-1911,735
ZEDQA gb19ah box zqa_ap_1_tab_stove world 1929,0-3546,735
ZEDQA gb19ah oven on true
ZEDQA gb19ah shot zqa_ap_2b_popout_stove_on
ZEDQA gb19ah box zqa_ap_2b_popout_stove_on char 1134,0-1911,735
ZEDQA gb19ah box zqa_ap_2b_popout_stove_on world 1929,0-3546,735
ZEDQA gb19ah box zqa_ap_2b_popout_stove_on popout 1984,862-2770,1180
ZEDQA gb19ah shot zqa_ap_4_popout_microwave
ZEDQA gb19ah box zqa_ap_4_popout_microwave char 1134,0-1911,735
ZEDQA gb19ah box zqa_ap_4_popout_microwave world 1929,0-2706,735
ZEDQA gb19ah box zqa_ap_4_popout_microwave popout 1984,830-2770,1212
ZEDQA gb19ah machines placed 3
ZEDQA gb19ah shot g14_ldy_washer
ZEDQA gb19ah box g14_ldy_washer char 1134,0-1911,735
ZEDQA gb19ah box g14_ldy_washer world 1929,0-2706,735
ZEDQA gb19ah box g14_ldy_washer popout 1984,749-2524,1407
ZEDQA gb19ah shot g14_ldy_dryer
ZEDQA gb19ah box g14_ldy_dryer char 1134,0-1911,735
ZEDQA gb19ah box g14_ldy_dryer world 1929,0-2706,735
ZEDQA gb19ah box g14_ldy_dryer popout 1984,749-2524,1407
ZEDQA gb19ah shot g14_ldy_combo
ZEDQA gb19ah box g14_ldy_combo char 1134,0-1911,735
ZEDQA gb19ah box g14_ldy_combo world 1929,0-2706,735
ZEDQA gb19ah box g14_ldy_combo popout 1316,749-1856,1407
ZEDQA gb19ah placed: radio true, TV true
ZEDQA gb19ah shot g19_radio_popout
ZEDQA gb19ah box g19_radio_popout char 1134,0-1911,735
ZEDQA gb19ah box g19_radio_popout world 1929,0-2706,735
ZEDQA gb19ah box g19_radio_popout popout 1984,814-2770,1228
ZEDQA gb19ah shot g19_tv_tab
ZEDQA gb19ah box g19_tv_tab char 1134,0-1911,735
ZEDQA gb19ah box g19_tv_tab world 1929,0-3546,735
ERROR: General f:12486 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA ff speed 2: time multiplier 5, true multiplier 5
ZEDQA gb19ah shot zqa_b19_speed_bubble
ZEDQA layout gb19ah put back
ZEDQA gb19ah put back: things taken away, grid and water, options, theme, speed, god mode, window places; at 925,13040
ZEDQA gb19ah DONE
```

### 14. gallery_t14_radios.lua (`ZEDQA g14r`) - PASS, 23 s

- go 28187 at 11:31:01

```text
[ZeD.QA] state #14 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14r start
[ZeD.QA] run #14 ok=true
ZEDQA g14r look dark teal, scale 1.75
ZEDQA g14r g14_radio_black: face radio_black, card 265 px, on true
ZEDQA g14r shot g14_radio_black
ZEDQA g14r box g14_radio_black char 749,0-1911,735
ZEDQA g14r box g14_radio_black face radio_black at 20,85 (window) k 2
ZEDQA g14r box g14_radio_black window origin 749,0
ZEDQA g14r g14_radio_red: face radio_red, card 385 px, on true
ZEDQA g14r shot g14_radio_red
ZEDQA g14r box g14_radio_red char 749,0-1911,735
ZEDQA g14r box g14_radio_red face radio_red at 20,85 (window) k 2
ZEDQA g14r box g14_radio_red window origin 749,0
ZEDQA g14r g14_radio_handbuilt: face radio_handbuilt, card 385 px, on true
ZEDQA g14r shot g14_radio_handbuilt
ZEDQA g14r box g14_radio_handbuilt char 749,0-1911,735
ZEDQA g14r box g14_radio_handbuilt face radio_handbuilt at 20,85 (window) k 2
ZEDQA g14r box g14_radio_handbuilt window origin 749,0
ZEDQA g14r g14_radio_cd: face cd_player, card 385 px, on true
ZEDQA g14r WARN step 23: waited 600 frames, went on
ZEDQA g14r shot g14_radio_cd
ZEDQA g14r box g14_radio_cd char 749,0-1911,735
ZEDQA g14r box g14_radio_cd face cd_player at 20,85 (window) k 2
ZEDQA g14r box g14_radio_cd window origin 749,0
ZEDQA g14r put back: hands, 4 items taken away
ZEDQA g14r DONE
```

### 15. zedqa_twoway.lua (`ZEDQA tw`) - PASS, 51 s

- go 28188 at 11:31:28
- screenshots: zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png

```text
[ZeD.QA] state #15 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA tw start
[ZeD.QA] run #15 ok=true
ZEDQA tw screen 3840x2160, root scale 1.75, plate zoom 2
ZEDQA tw PASS walkie_valutech: the Character window's Radio tab opens
ZEDQA tw PASS walkie_valutech: its own face, walkie_valutech (got walkie_valutech@180)
ZEDQA tw PASS walkie_valutech: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_valutech: centred in its panel (x 20, want 20)
ZEDQA tw PASS walkie_valutech: the width that fills the half card (want walkie_valutech@180, got walkie_valutech@180)
ZEDQA tw PASS walkie_valutech: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_valutech: all 6 controls on the face (6)
ZEDQA tw PASS walkie_valutech: the full view button in the header
ZEDQA tw PASS walkie_valutech: VOL pressed turns it on
ZEDQA tw PASS walkie_valutech: the display reads while on
ZEDQA tw walkie_valutech: display 093.200 | LBMW - KENTUCKY RADIO | BAT 3
ZEDQA tw PASS walkie_valutech: BAT with 3 bars at 60% charge
ZEDQA tw valutech: body 585 px tall, the face's body needs 799 (window 735)
ZEDQA tw PASS valutech: at the default height the body scrolls
ZEDQA tw PASS valutech: the wheel off the knobs scrolls the body (0 -> 0.05)
ZEDQA tw valutech: the face and footer need 1190 px with 380 px of fill blocks (body 585)
ZEDQA tw PASS valutech: the grown window shows the whole face, no scrollbar
ZEDQA tw PASS VOL: the wheel turns the volume up (0.50 -> 0.60)
ZEDQA tw PASS TUNE: a click on its right half tunes up a step (93200 -> 93400)
ZEDQA tw PASS TUNE: its left half tunes down a step
ZEDQA tw PASS TUNE: a right-click turns it down
ZEDQA tw PASS MEM: stores the frequency as channel 01 (1 stored)
ZEDQA tw PASS the display shows CH 01 (01)
ZEDQA tw PASS MEM: a second channel stored
ZEDQA tw PASS CH down walks to channel 01
ZEDQA tw PASS CH up walks to channel 02
ZEDQA tw PASS the mic starts muted
ZEDQA tw PASS the TX lamp is dark while the mic is muted
ZEDQA tw PASS PUSH TO TALK latches the mic live
ZEDQA tw PASS the TX lamp lights and the display says TX OK (TX OK)
ZEDQA tw PASS pressed again it mutes the mic (MIC OFF)
ZEDQA tw PASS MEM held (right-click): the naming box opens
ZEDQA tw PASS naming it: channel 02 is QA Farm
ZEDQA tw PASS the header button opens full view on the radio
ZEDQA tw PASS full view is the face alone, no window frame
ZEDQA tw PASS full view is the plate at the plate scale, room for its 1u hard shadow (402x766)
ZEDQA tw PASS the first time it sits beside the player, clear of them (x 1984, player 1920)
ZEDQA tw PASS every control is on it (6)
ZEDQA tw PASS a control in full view works (CH down)
ZEDQA tw PASS MEM held in full view opens the naming box
ZEDQA tw PASS the face's edge is not a control
ZEDQA tw PASS dragging the face moves full view (1984 -> 1584)
ZEDQA tw PASS the place is kept on the character
ZEDQA tw PASS the header button closes full view
ZEDQA tw PASS the point between the knobs is no control
ZEDQA tw PASS a click on the face away from the controls opens full view
ZEDQA tw PASS it opens where it was dragged to
ZEDQA tw PASS B closes full view
ZEDQA tw PASS Escape closes full view
ZEDQA tw PASS full view closes when the radio leaves the hands
ZEDQA tw PASS pad: the face's VOL is a stop in the tab
ZEDQA tw PASS pad: up on VOL turns it up
ZEDQA tw PASS pad: right from VOL walks to TUNE (radio:tw:tune)
ZEDQA tw PASS pad: A on CH up steps the channel
ZEDQA tw PASS pad: X on MEM opens the naming box
ZEDQA tw PASS pad: A on the full view button opens it
ZEDQA tw PASS pad: full view shows its controller strip
ZEDQA tw PASS pad: full view lands on a control (vol)
ZEDQA tw PASS pad: down on VOL in full view turns it down
ZEDQA tw PASS pad: right walks to TUNE in full view (tune)
ZEDQA tw PASS pad: A on PUSH TO TALK in full view latches the mic
ZEDQA tw PASS pad: B closes full view
ZEDQA tw PASS walkie_toy: the Character window's Radio tab opens
ZEDQA tw PASS walkie_toy: its own face, walkie_toy (got walkie_toy@180)
ZEDQA tw PASS walkie_toy: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_toy: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_toy: the width that fills the half card (want walkie_toy@180, got walkie_toy@180)
ZEDQA tw PASS walkie_toy: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_toy: all 3 controls on the face (3)
ZEDQA tw PASS walkie_toy: the full view button in the header
ZEDQA tw PASS walkie_toy: VOL pressed turns it on
ZEDQA tw PASS walkie_toy: the display reads while on
ZEDQA tw walkie_toy: display 99.00 MHZ | nil | nil nil
ZEDQA tw PASS toy: no memories, its TALK button
ZEDQA tw PASS toy: the drum shows the frequency
ZEDQA tw PASS walkie_premium: the Character window's Radio tab opens
ZEDQA tw PASS walkie_premium: its own face, walkie_premium (got walkie_premium@180)
ZEDQA tw PASS walkie_premium: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_premium: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_premium: the width that fills the half card (want walkie_premium@180, got walkie_premium@180)
ZEDQA tw PASS walkie_premium: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_premium: all 6 controls on the face (6)
ZEDQA tw PASS walkie_premium: the full view button in the header
ZEDQA tw PASS walkie_premium: VOL pressed turns it on
ZEDQA tw PASS walkie_premium: the display reads while on
ZEDQA tw walkie_premium: display 083.800 | | BAT 3
ZEDQA tw PASS walkie_premium: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_tactical: the Character window's Radio tab opens
ZEDQA tw PASS walkie_tactical: its own face, walkie_tactical (got walkie_tactical@180)
ZEDQA tw PASS walkie_tactical: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_tactical: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_tactical: the width that fills the half card (want walkie_tactical@180, got walkie_tactical@180)
ZEDQA tw PASS walkie_tactical: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_tactical: all 9 controls on the face (9)
ZEDQA tw PASS walkie_tactical: the full view button in the header
ZEDQA tw PASS walkie_tactical: VOL pressed turns it on
ZEDQA tw PASS walkie_tactical: the display reads while on
ZEDQA tw walkie_tactical: display 460.600 | | BAT 3
ZEDQA tw PASS walkie_tactical: BAT with 3 bars at 60% charge
ZEDQA tw PASS Tactical: MUTE silences it
ZEDQA tw PASS Tactical: MUTE again gives the sound back
ZEDQA tw PASS Tactical: SCAN runs
ZEDQA tw PASS Tactical: SCAN again stops it
ZEDQA tw PASS Tactical: LAMP lights the display
ZEDQA tw PASS Tactical: the lamp goes out after 5 s
ZEDQA tw PASS walkie_army: the Character window's Radio tab opens
ZEDQA tw PASS walkie_army: its own face, walkie_army (got walkie_army@180)
ZEDQA tw PASS walkie_army: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_army: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_army: the width that fills the half card (want walkie_army@180, got walkie_army@180)
ZEDQA tw PASS walkie_army: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_army: all 9 controls on the face (9)
ZEDQA tw PASS walkie_army: the full view button in the header
ZEDQA tw PASS walkie_army: VOL pressed turns it on
ZEDQA tw PASS walkie_army: the display reads while on
ZEDQA tw walkie_army: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | BAT 3
ZEDQA tw PASS walkie_army: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_makeshift: the Character window's Radio tab opens
ZEDQA tw PASS walkie_makeshift: its own face, walkie_makeshift (got walkie_makeshift@180)
ZEDQA tw PASS walkie_makeshift: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_makeshift: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_makeshift: the width that fills the half card (want walkie_makeshift@180, got walkie_makeshift@180)
ZEDQA tw PASS walkie_makeshift: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_makeshift: all 6 controls on the face (6)
ZEDQA tw PASS walkie_makeshift: the full view button in the header
ZEDQA tw PASS walkie_makeshift: VOL pressed turns it on
ZEDQA tw PASS walkie_makeshift: the display reads while on
ZEDQA tw walkie_makeshift: display CH-- 79.20 | | nil nil
ZEDQA tw PASS makeshift: its character display reads CH.. (CH-- 79.20)
ZEDQA tw PASS walkie_manpack: the Character window's Radio tab opens
ZEDQA tw PASS walkie_manpack: its own face, walkie_manpack (got walkie_manpack@180)
ZEDQA tw PASS walkie_manpack: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_manpack: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_manpack: the width that fills the half card (want walkie_manpack@180, got walkie_manpack@180)
ZEDQA tw PASS walkie_manpack: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_manpack: all 7 controls on the face (7)
ZEDQA tw PASS walkie_manpack: the full view button in the header
ZEDQA tw PASS walkie_manpack: VOL pressed turns it on
ZEDQA tw PASS walkie_manpack: the display reads while on
ZEDQA tw walkie_manpack: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | BAT 3
ZEDQA tw PASS walkie_manpack: BAT with 3 bars at 60% charge
ZEDQA tw PASS ManPack: on the back
ZEDQA tw PASS an AM/FM radio shows its own face (or plain card), not a two-way set's
ZEDQA tw 8 free squares in reach
ZEDQA tw placed 3 ham sets
ZEDQA tw PASS the World window's Radio tab opens on the placed sets
ZEDQA tw PASS ham_civilian: its own face, ham_civilian (got ham_civilian@392)
ZEDQA tw PASS ham_civilian: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_civilian: centred across the drawer (x 28, want 28)
ZEDQA tw PASS ham_civilian: the drawer holds the whole set (840 px for 784)
ZEDQA tw PASS ham_civilian: all 8 controls on the face (8)
ZEDQA tw PASS ham_civilian: the full view button in the header
ZEDQA tw PASS ham_civilian: VOL pressed turns it on
ZEDQA tw ham_civilian: display 101.200 | KNOXTALK RADIO | range RANGE 7.5 KM
ZEDQA tw PASS ham_civilian: the display reads while on
ZEDQA tw PASS the drawer's clip is set and cleared in pairs with a ham showing (20 sets, 20 clears)
ZEDQA tw PASS civilian ham: RANGE matches its transmit range (RANGE 7.5 KM)
ZEDQA tw PASS civilian ham: the band marker follows the frequency up (0.18612244897959185 -> 0.28816326530612246)
ZEDQA tw PASS civilian ham: full view opens
ZEDQA tw PASS ham_civilian on a small screen: its narrow face (ham_civilian_n)
ZEDQA tw PASS ham_civilian: the tab is the half card (385 px, want 385)
ZEDQA tw PASS ham_civilian: the narrow face at a whole zoom that fits the half card (1 of the screen's 2)
ZEDQA tw PASS ham_civilian: every control of the wide set on the narrow face (8)
ZEDQA tw PASS ham_civilian: VOL on the narrow face turns it on
ZEDQA tw PASS ham_civilian: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_civilian: the narrow face's display reads
ZEDQA tw PASS ham_army on a small screen: its narrow face (ham_army_n)
ZEDQA tw PASS ham_army: the tab is the half card (385 px, want 385)
ZEDQA tw PASS ham_army: the narrow face at a whole zoom that fits the half card (1 of the screen's 2)
ZEDQA tw PASS ham_army: every control of the wide set on the narrow face (14)
ZEDQA tw PASS ham_army: VOL on the narrow face turns it on
ZEDQA tw PASS ham_army: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_army: the narrow face's display reads
ZEDQA tw PASS ham_makeshift on a small screen: its narrow face (ham_makeshift_n)
ZEDQA tw PASS ham_makeshift: the tab is the half card (385 px, want 385)
ZEDQA tw PASS ham_makeshift: the narrow face at a whole zoom that fits the half card (1 of the screen's 2)
ZEDQA tw PASS ham_makeshift: every control of the wide set on the narrow face (7)
ZEDQA tw PASS ham_makeshift: VOL on the narrow face turns it on
ZEDQA tw PASS ham_makeshift: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_makeshift: the narrow face's display reads
ZEDQA tw PASS narrow makeshift ham: TALK / LISTEN flips with the mic
ZEDQA tw PASS with room again the wide set is back
ZEDQA tw PASS ham_army: its own face, ham_army (got ham_army@392)
ZEDQA tw PASS ham_army: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_army: centred across the drawer (x 28, want 28)
ZEDQA tw PASS ham_army: the drawer holds the whole set (840 px for 784)
ZEDQA tw PASS ham_army: all 14 controls on the face (14)
ZEDQA tw PASS ham_army: the full view button in the header
ZEDQA tw PASS ham_army: VOL pressed turns it on
ZEDQA tw ham_army: display 094.400 | | range RANGE 20 KM
ZEDQA tw PASS ham_army: the display reads while on
ZEDQA tw PASS army ham: tuned away
ZEDQA tw PASS army ham: 1 goes straight to memory 1
ZEDQA tw PASS army ham on the grid: AC, the bars dark (AC)
ZEDQA tw PASS ham_makeshift: its own face, ham_makeshift (got ham_makeshift@392)
ZEDQA tw PASS ham_makeshift: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_makeshift: centred across the drawer (x 28, want 28)
ZEDQA tw PASS ham_makeshift: the drawer holds the whole set (840 px for 784)
ZEDQA tw PASS ham_makeshift: all 7 controls on the face (7)
ZEDQA tw PASS ham_makeshift: the full view button in the header
ZEDQA tw PASS ham_makeshift: VOL pressed turns it on
ZEDQA tw ham_makeshift: display CH-- 059.000 MHZ | | range RANGE 6 KM
ZEDQA tw PASS ham_makeshift: the display reads while on
ZEDQA tw PASS makeshift ham: the TALK / LISTEN toggle flips with the mic
ZEDQA tw PASS makeshift ham: full view opens
ZEDQA tw PASS full view closes when the set is taken away
ZEDQA tw cleanup: 3 sets and 8 items taken away
ZEDQA tw 192 passed, 0 failed
ZEDQA tw all checks passed
ZEDQA tw DONE
```

### 16. zedqa_hands_together.lua (`ZEDQA ht`) - PASS, 18 s

- go 28189 at 11:32:22
- screenshots: zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png

```text
[ZeD.QA] state #16 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ht start
[ZeD.QA] run #16 ok=true
ZEDQA ht 01 two items | OFF@0/77 MAIN@88/98 #1@225/77 #2@468/77 #3@564/77 | dark small | belt x1535 y2034 w662 h98
ZEDQA ht PASS 01 two items: both hands are on the belt
ZEDQA ht PASS 01 two items: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 01 two items: the off hand comes before the main hand
ZEDQA ht PASS 01 two items: the hands sit before the slots (the left end)
ZEDQA ht PASS 01 two items: the boxes run left to right
ZEDQA ht PASS 01 two items: the hands are 6 units apart (11 px)
ZEDQA ht PASS 01 two items: a click at the off hand's right edge finds the off hand
ZEDQA ht 02 both hands | off(peek)@0/77 MAIN@25/98 #1@162/77 #2@405/77 #3@501/77 | dark small | belt x1598 y2034 w599 h98
ZEDQA ht PASS 02 both hands: both hands are on the belt
ZEDQA ht PASS 02 both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 02 both hands: the off hand comes before the main hand
ZEDQA ht PASS 02 both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 02 both hands: the boxes run left to right
ZEDQA ht PASS 02 both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 02 both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 02 both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 02 both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 02 both hands: slot 1 stays in place on screen (1760, was 1760)
ZEDQA ht 03 both, high contrast | off(peek)@0/77 MAIN@25/98 #1@162/77 #2@405/77 #3@501/77 | hicon small | belt x1598 y2034 w599 h98
ZEDQA ht PASS 03 both, high contrast: both hands are on the belt
ZEDQA ht PASS 03 both, high contrast: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 03 both, high contrast: the off hand comes before the main hand
ZEDQA ht PASS 03 both, high contrast: the hands sit before the slots (the left end)
ZEDQA ht PASS 03 both, high contrast: the boxes run left to right
ZEDQA ht PASS 03 both, high contrast: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 03 both, high contrast: the crescent's mark is 44 px wide
ZEDQA ht PASS 03 both, high contrast: a click at the crescent finds the off hand
ZEDQA ht PASS 03 both, high contrast: a click where the two overlap finds the main hand
ZEDQA ht 04 both, large | off(peek)@0/89 MAIN@28/113 #1@185/89 #2@446/89 #3@557/89 | dark large | belt x1560 y2015 w670 h113
ZEDQA ht PASS 04 both, large: both hands are on the belt
ZEDQA ht PASS 04 both, large: the main hand is 56 units, the off hand 44 (113, 89 px; 56u = 113)
ZEDQA ht PASS 04 both, large: the off hand comes before the main hand
ZEDQA ht PASS 04 both, large: the hands sit before the slots (the left end)
ZEDQA ht PASS 04 both, large: the boxes run left to right
ZEDQA ht PASS 04 both, large: the off hand peeks 14 units from under the main hand (28 px)
ZEDQA ht PASS 04 both, large: the crescent's mark is 50 px wide
ZEDQA ht PASS 04 both, large: a click at the crescent finds the off hand
ZEDQA ht PASS 04 both, large: a click where the two overlap finds the main hand
ZEDQA ht pad two items | OFF@0/77 MAIN@88/98 #1@225/77 #2@468/77 #3@564/77 | dark small | belt x1535 y2034 w662 h98
ZEDQA ht PASS pad two items: both hands are on the belt
ZEDQA ht PASS pad two items: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS pad two items: the off hand comes before the main hand
ZEDQA ht PASS pad two items: the hands sit before the slots (the left end)
ZEDQA ht PASS pad two items: the boxes run left to right
ZEDQA ht PASS pad two items: the hands are 6 units apart (11 px)
ZEDQA ht PASS pad two items: a click at the off hand's right edge finds the off hand
ZEDQA ht PASS pad: the belt starts on slot 1 (#1)
ZEDQA ht PASS pad: Left from slot 1 is the main hand (MAIN)
ZEDQA ht PASS pad: Left again is the off hand (OFF)
ZEDQA ht 05 left wrist, both hands | watch@0/88 off(peek)@102/77 MAIN@127/98 #1@264/77 #2@507/77 #3@603/77 | dark small | belt x1496 y2034 w701 h98
ZEDQA ht PASS 05 left wrist, both hands: both hands are on the belt
ZEDQA ht PASS 05 left wrist, both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 05 left wrist, both hands: the off hand comes before the main hand
ZEDQA ht PASS 05 left wrist, both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 05 left wrist, both hands: the boxes run left to right
ZEDQA ht PASS 05 left wrist, both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 05 left wrist, both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 05 left wrist, both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 05 left wrist, both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 05 left wrist, both hands: slot 1 stays in place on screen (1760, was 1760)
ZEDQA ht PASS 05: the left-wrist watch sits beside the peeking off hand
ZEDQA ht 06 right wrist, pistol | OFF@0/77 MAIN@88/98 ammo@137/255 watch@406/88 #1@533/77 #2@776/77 #3@872/77 | dark small | belt x1227 y2034 w970 h98
ZEDQA ht PASS 06 right wrist, pistol: both hands are on the belt
ZEDQA ht PASS 06 right wrist, pistol: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 06 right wrist, pistol: the off hand comes before the main hand
ZEDQA ht PASS 06 right wrist, pistol: the hands sit before the slots (the left end)
ZEDQA ht PASS 06 right wrist, pistol: the boxes run left to right
ZEDQA ht PASS 06 right wrist, pistol: the hands are 6 units apart (11 px)
ZEDQA ht PASS 06 right wrist, pistol: a click at the off hand's right edge finds the off hand
ZEDQA ht PASS 06: the ammo tab comes after the main hand
ZEDQA ht PASS 06: the tab starts under the main hand's middle, its words at the circle's edge (x137 cx186)
ZEDQA ht PASS 06: no strap under the ammo tab
ZEDQA ht PASS 06: a click on the circle over the tab finds the main hand
ZEDQA ht PASS 06: a click on the tab's words finds the tab
ZEDQA ht PASS 06: the right-wrist watch is outside the tab, before the strap
ZEDQA ht PASS 06: the full watch opens to the right of the small one (left)
ZEDQA ht 06 ammo 12/15 chambered true | 12+1
ZEDQA ht 08 empty pistol | OFF@0/77 MAIN@88/98 ammo@137/255 #1@431/77 #2@674/77 #3@770/77 | dark small | belt x1329 y2034 w868 h98
ZEDQA ht PASS 08 empty pistol: both hands are on the belt
ZEDQA ht PASS 08 empty pistol: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 08 empty pistol: the off hand comes before the main hand
ZEDQA ht PASS 08 empty pistol: the hands sit before the slots (the left end)
ZEDQA ht PASS 08 empty pistol: the boxes run left to right
ZEDQA ht PASS 08 empty pistol: the hands are 6 units apart (11 px)
ZEDQA ht PASS 08 empty pistol: a click at the off hand's right edge finds the off hand
ZEDQA ht PASS 08: the ammo tab comes after the main hand
ZEDQA ht PASS 08: the tab starts under the main hand's middle, its words at the circle's edge (x137 cx186)
ZEDQA ht PASS 08: no strap under the ammo tab
ZEDQA ht PASS 08: a click on the circle over the tab finds the main hand
ZEDQA ht PASS 08: a click on the tab's words finds the tab
ZEDQA ht 09 shotgun, both hands | off(peek)@0/77 MAIN@25/98 ammo@74/255 #1@368/77 #2@611/77 #3@707/77 | dark small | belt x1392 y2034 w805 h98
ZEDQA ht PASS 09 shotgun, both hands: both hands are on the belt
ZEDQA ht PASS 09 shotgun, both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 09 shotgun, both hands: the off hand comes before the main hand
ZEDQA ht PASS 09 shotgun, both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 09 shotgun, both hands: the boxes run left to right
ZEDQA ht PASS 09 shotgun, both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 09 shotgun, both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 09 shotgun, both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 09 shotgun, both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 09 shotgun, both hands: slot 1 stays in place on screen (1760, was 1760)
ZEDQA ht PASS 09: the ammo tab comes after the main hand
ZEDQA ht PASS 09: the tab starts under the main hand's middle, its words at the circle's edge (x74 cx123)
ZEDQA ht PASS 09: no strap under the ammo tab
ZEDQA ht PASS 09: a click on the circle over the tab finds the main hand
ZEDQA ht PASS 09: a click on the tab's words finds the tab
ZEDQA ht 07 off hand x1598 y2044 s77 peekW 44
ZEDQA ht all checks passed
ZEDQA ht DONE
```

### 17. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 28190 at 11:32:44

```text
[ZeD.QA] state #17 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #17 ok=true
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
