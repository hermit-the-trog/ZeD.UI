# ZeD-UI regression - 2026-11-17 12:39 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 12:39:55 |
| Finished | 2026-11-17 12:48:39 (8 min 44 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\gallery_b19_light.txt (23 scripts) |
| Result | **22/23 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 28269 to 28293 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28292, 28293)
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
| 8 | zedqa_moodles.lua | mood | PASS | 20 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png | late output from unl (18 line(s), not counted) |
| 9 | gallery_v3_core.lua | g3c | PASS | 19 |  | late output from unl (20 line(s), not counted) |
| 10 | gallery_v3_reveal.lua | g3r | PASS | 11 |  | late output from unl (15 line(s), not counted) |
| 11 | gallery_v3_stage.lua | g3s | PASS | 10 |  | late output from unl (14 line(s), not counted) |
| 12 | gallery_b19_a.lua | gb19a | PASS | 43 |  | late output from unl (39 line(s), not counted) |
| 13 | gallery_v3_teardown.lua | g3t | PASS | 11 |  | late output from unl (16 line(s), not counted) |
| 14 | gallery_b11_look.lua | g14l2 | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 15 | gallery_b19_storybars_only.lua | sbar | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 16 | gallery_story_stage.lua | sts | PASS | 30 |  | late output from unl (34 line(s), not counted) |
| 17 | gallery_story_shots.lua | stz | PASS | 52 |  | late output from unl (56 line(s), not counted) |
| 18 | gallery_story_teardown.lua | stt | PASS | 10 |  | late output from unl (14 line(s), not counted) |
| 19 | gallery_b11_look.lua | g14l3 | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 20 | gallery_b19_a.lua | gb19ah | PASS | 41 | zqa_ap_1_tab_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_4_popout_microwave.png, zqa_b19_speed_bubble.png | late output from unl (34 line(s), not counted) |
| 21 | gallery_b19_b.lua | gb19b | **FAIL** | 103 | zqa_bub_both_dark.png, zqa_g4_guide_bubble.png, zqa_pr_01_sleep.png, zqa_pr_06_keyboard.png, zqa_pr_07_alarm.png, zqa_padmap_options.png, zqa_b19_ask_cancel.png, zqa_b19_window_menu.png, zqa_g4_belt_toast.png, zqa_g4_window_radio.png, zqa_g3_wheel_character_eat.png, zqa_g3_wheel_now_light.png, zqa_g3_wheel_use_smoke.png, zqa_g3_footer_pad.png | 28 Java exception(s) in the log; late output from unl (86 line(s), not counted) |
| 22 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 23 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28269 at 12:41:00

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

- go 28270 at 12:41:05

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28271 at 12:41:09

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

- go 28272 at 12:41:14

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.36 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 28273 at 12:41:19

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls wearing Base.Glasses_Prescription
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28274 at 12:41:24

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28275 at 12:41:28

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 50.0 of 8 kg, 117 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 60 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 8.2 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #7 ok=true
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (x3)
```

### 8. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 20 s

- go 28276 at 12:41:32
- late output from unl (18 line(s), not counted)
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (late output from unl)
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #8 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (late output from unl)
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 5
ZEDQA mood box by itself: TIRED | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA mood right: 5 moodles on (TIRED 2, HUNGRY 3, PANIC 1, STRESS 2, THIRST 2)
ZEDQA mood PASS right: the place is in effect
ZEDQA mood PASS right: at least three moodles are on
ZEDQA mood PASS right: the moodles are shown (layer)
ZEDQA mood right column at 3782,940 size 48, stack 280; visible true
ZEDQA mood PASS right: vanilla's column is visible
ZEDQA mood PASS right: every moodle is on screen
ZEDQA mood PASS right: the column is on the right edge (x 3782)
ZEDQA mood PASS right: ZeD's hover layer lies over the column
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA mood right bubble: moodle 2, cloud -241,71 219x86.19140625, trail balloon from nil,nil
ZEDQA mood PASS right: the bubble is for the moodle under the pointer
ZEDQA mood PASS right: the balloon sits beside its moodle, clear of it
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA mood left: 5 moodles on (TIRED 2, HUNGRY 3, PANIC 1, STRESS 2, THIRST 2)
ZEDQA mood PASS left: the place is in effect
ZEDQA mood PASS left: at least three moodles are on
ZEDQA mood PASS left: the moodles are shown (layer)
ZEDQA mood left column at 10,940 size 48, stack 280; visible true
ZEDQA mood PASS left: vanilla's column is visible
ZEDQA mood PASS left: every moodle is on screen
ZEDQA mood PASS left: the column is on the left edge (x 10)
ZEDQA mood PASS left: ZeD's hover layer lies over the column
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA mood left bubble: moodle 2, cloud 70,71 219x86.19140625, trail balloon from nil,nil
ZEDQA mood PASS left: the bubble is for the moodle under the pointer
ZEDQA mood PASS left: the balloon sits beside its moodle, clear of it
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA mood bottom: 5 moodles on (TIRED 2, HUNGRY 3, PANIC 2, STRESS 2, THIRST 2)
ZEDQA mood PASS bottom: the place is in effect
ZEDQA mood PASS bottom: at least three moodles are on
ZEDQA mood PASS bottom: the moodles are shown (layer)
ZEDQA mood bottom row at 1780,1965 280x48; vanilla's column y -10000
ZEDQA mood PASS bottom: the row is on screen
ZEDQA mood PASS bottom: the row is centred (middle 1920 of 3840)
ZEDQA mood PASS bottom: the row sits above the belt
ZEDQA mood PASS bottom: one slot per moodle
ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA mood bottom bubble: moodle 2, cloud 68,-108.19140625 219x86.19140625, trail balloon from nil,nil
ZEDQA mood PASS bottom: the bubble is for the moodle under the pointer
ZEDQA mood PASS bottom: the balloon sits beside its moodle, clear of it
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA mood PASS with nothing changing the box goes by itself (nil)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA mood notices off: box nil | waiting 2
ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA mood all checks passed
ZEDQA mood DONE
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
```

### 9. gallery_v3_core.lua (`ZEDQA g3c`) - PASS, 19 s

- go 28277 at 12:41:56
- late output from unl (20 line(s), not counted)

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3c start (18 steps)
[ZeD.QA] run #9 ok=true
ZEDQA g3c start at 925,13040 zoom 1 | ZeD true
ZEDQA g3c forced spot 13935,5729
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x10)
ZEDQA g3c standing at 13935,5729 floor blends_street_01_102 outside true | cars within 22: 1 | zombies in the cell 0
ZEDQA g3c floors round the spot: blends_street_01=81
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g3c zoom 1.75
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA g3c shot g3_scout_wide ok
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g3c zoom 1
ZEDQA g3c shot g3_scout_mid ok
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA g3c end: 2 shots ok, 0 errors
ZEDQA g3c DONE
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
```

### 10. gallery_v3_reveal.lua (`ZEDQA g3r`) - PASS, 11 s

- go 28278 at 12:42:19
- late output from unl (15 line(s), not counted)

```text
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
[ZeD.QA] state #10 speed=1 paused=false player=13935,5729 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3r start (172 steps)
[ZeD.QA] run #10 ok=true
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x11)
ZEDQA g3r toured: 16 stops
ZEDQA g3r end: 0 shots ok, 0 errors
ZEDQA g3r DONE
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
```

### 11. gallery_v3_stage.lua (`ZEDQA g3s`) - PASS, 10 s

- go 28279 at 12:42:33
- late output from unl (14 line(s), not counted)

```text
[ZeD.QA] state #11 speed=1 paused=false player=13935,5729 grid=19 inCar=false vehicles=15 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3s start (15 steps)
[ZeD.QA] run #11 ok=true
ZEDQA g3s aside: 7 worn, 0 on the belt, 57 items, hands nil / nil
ZEDQA unl load 0.0 of 17 kg, 0 items, Heavy Load 0   (late output from unl)
ZEDQA g3s worn: Tshirt_DefaultTEXTURE_TINT Shirt_Lumberjack Jacket_ArmyOliveDrab Vest_Hunting_Khaki Trousers_Denim Socks_Heavy Shoes_ArmyBoots Gloves_LeatherGlovesBlack Hat_BaseballCapGreen Belt2 HolsterSimple_Black Kneepad_Left_Tactical Kneepad_Right_Tactical WristWatch_Left_DigitalBlack Glasses_Prescription_Aviators Bag_ALICEpack_Army Bag_ChestRig Bag_FannyPackBack Bag_Satchel_Leather
ZEDQA g3s bag back (Base.Bag_ALICEpack_Army): 13 things
ZEDQA g3s bag webbing (Base.Bag_ChestRig): 3 things
ZEDQA g3s bag fannypackback (Base.Bag_FannyPackBack): 2 things
ZEDQA g3s bag satchel (Base.Bag_Satchel_Leather): 3 things
ZEDQA unl load 12.5 of 17 kg, 43 items, Heavy Load 0   (late output from unl)
ZEDQA g3s belt: HuntingKnife@smallbeltleft Hammer@smallbeltright Pistol@holsterright Shotgun@back
ZEDQA g3s hotbar slots: Back* HolsterRight* SmallBeltLeft* SmallBeltRight* BedrollBottomALICE
ZEDQA unl load 21.1 of 17 kg, 48 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA g3s trunk lid: open
ZEDQA g3s trunk: 11 things
ZEDQA g3s trunk area centre 13936.2,5729.2: the character goes to 13936.16,5729.69
ZEDQA unl load 21.1 of 17 kg, 49 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA g3s at 13936,5729: in the trunk area true, trunk reachable true
ZEDQA g3s duffel on the ground: 9 things
ZEDQA g3s parked cars spawned: 4 | cars within 22 now: 2
ZEDQA g3s background zombies: 8 | in the cell 8
ZEDQA unl load 21.1 of 17 kg, 49 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA g3s zombies still there after 150 frames: 8/8 | in the cell 8
ZEDQA unl load 21.1 of 17 kg, 49 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA g3s zoom 1
ZEDQA unl load 21.1 of 17 kg, 49 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA g3s shot g3_stage_mid ok
ZEDQA unl load 21.1 of 17 kg, 49 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA g3s end: 1 shots ok, 0 errors
ZEDQA g3s DONE
ZEDQA unl load 21.1 of 17 kg, 49 items, Heavy Load 1 OVER   (late output from unl)   (x3)
```

### 12. gallery_b19_a.lua (`ZEDQA gb19a`) - PASS, 43 s

- go 28280 at 12:42:47
- late output from unl (39 line(s), not counted)

```text
[ZeD.QA] state #12 speed=1 paused=false player=13936,5729 grid=19 inCar=false vehicles=20 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gb19a start (the mall lot, 58 steps)
[ZeD.QA] run #12 ok=true
ZEDQA gb19a start: the mall lot at 13936,5729
ZEDQA unl load 21.1 of 20 kg, 49 items, Heavy Load 0 OVER   (late output from unl)
ZEDQA gb19a look dark teal size small | scale 1.75 | font size option 2 | screen 3840x2160
ZEDQA unl load 21.1 of 20 kg, 49 items, Heavy Load 0 OVER   (late output from unl)   (x2)
ZEDQA gb19a zoom 1
ZEDQA gb19a set aside 8 things for the grid shots, load now about 13.9 kg
ZEDQA gb19a grid filled with light things: inventory 13.3 of 50.0 kg
ZEDQA unl load 15.7 of 20 kg, 53 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gb19a shot zed_53_grid
ZEDQA gb19a box zed_53_grid char 1136,0-1913,735
ZEDQA gb19a box zed_53_grid world 1927,0-2704,735
ZEDQA unl load 15.7 of 20 kg, 53 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 22.0 of 20 kg, 57 items, Heavy Load 0 OVER   (late output from unl)   (x2)
ZEDQA gb19a zed_53b_grid_tinted: inventory 19.6 of 50.0 kg
ZEDQA gb19a shot zed_53b_grid_tinted
ZEDQA gb19a box zed_53b_grid_tinted char 1136,0-1913,735
ZEDQA gb19a box zed_53b_grid_tinted world 1927,0-2704,735
ZEDQA unl load 22.0 of 20 kg, 57 items, Heavy Load 0 OVER   (late output from unl)
ZEDQA gb19a put back 8 things set aside for the grid shots
ZEDQA unl load 21.1 of 20 kg, 49 items, Heavy Load 0 OVER   (late output from unl)
ZEDQA gb19a apples given: inventory 19.3 of 50.0 kg
ZEDQA unl load 21.7 of 20 kg, 52 items, Heavy Load 0 OVER   (late output from unl)
ZEDQA gb19a the apple stack opened: 5
ZEDQA unl load 21.7 of 20 kg, 52 items, Heavy Load 0 OVER   (late output from unl)   (x2)
ZEDQA gb19a zed_01_hero_mid: inventory 19.3 of 50.0 kg
ZEDQA gb19a open stack: Apple (5)
ZEDQA gb19a shot zed_01_hero_mid
ZEDQA gb19a box zed_01_hero_mid char 1136,0-1913,735
ZEDQA gb19a box zed_01_hero_mid world 1927,0-2704,735
ZEDQA unl load 21.7 of 20 kg, 52 items, Heavy Load 0 OVER   (late output from unl)   (x4)
ZEDQA gb19a shot zed_18_card_food
ZEDQA gb19a box zed_18_card_food char 1136,21-1913,2139
ZEDQA gb19a box zed_18_card_food world 1927,21-3089,2139
ZEDQA unl load 21.7 of 20 kg, 52 items, Heavy Load 0 OVER   (late output from unl)   (x3)
ZEDQA gb19a shot zed_19_card_weapon
ZEDQA gb19a box zed_19_card_weapon char 1136,21-1913,2139
ZEDQA gb19a box zed_19_card_weapon world 1927,21-3089,2139
ZEDQA unl load 21.7 of 20 kg, 52 items, Heavy Load 0 OVER   (late output from unl)   (x2)
ZEDQA gb19a shot zed_20_ctx_strip
ZEDQA gb19a box zed_20_ctx_strip char 1136,0-1913,735
ZEDQA gb19a box zed_20_ctx_strip world 1927,0-2704,735
ZEDQA unl load 21.7 of 20 kg, 52 items, Heavy Load 0 OVER   (late output from unl)
ZEDQA gb19a shot zed_21_ctx_list
ZEDQA gb19a box zed_21_ctx_list char 1136,0-1913,735
ZEDQA gb19a box zed_21_ctx_list world 1927,0-2704,735
ZEDQA unl load 21.7 of 20 kg, 52 items, Heavy Load 0 OVER   (late output from unl)
ZEDQA gb19a not taken: the Install / Uninstall / Take apart list variant (optional; the apple's menu is the spread's frame)
ZEDQA unl load 21.7 of 20 kg, 52 items, Heavy Load 0 OVER   (late output from unl)   (x2)
ZEDQA gb19a zoom 0.5
ZEDQA unl load 21.7 of 18 kg, 52 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA gb19a shot zed_32_action_bar_reading
ZEDQA unl load 21.7 of 18 kg, 52 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA gb19a endless: current action ISRestAction, maxTime -1
ZEDQA gb19a shot zed_32b_action_endless
ZEDQA unl load 21.7 of 18 kg, 52 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA unl load 21.7 of 20 kg, 52 items, Heavy Load 0 OVER   (late output from unl)   (x2)
ZEDQA gb19a zoom 1
ZEDQA unl load 21.1 of 20 kg, 49 items, Heavy Load 0 OVER   (late output from unl)
ZEDQA layout gb19a put back
ZEDQA gb19a put back: options, theme, grid views, sorts, tint, given things, ground things, window places, speed, god mode
ZEDQA gb19a DONE
ZEDQA unl load 21.1 of 20 kg, 49 items, Heavy Load 0 OVER   (late output from unl)   (x3)
```

### 13. gallery_v3_teardown.lua (`ZEDQA g3t`) - PASS, 11 s

- go 28281 at 12:43:33
- late output from unl (16 line(s), not counted)

```text
[ZeD.QA] state #13 speed=1 paused=false player=13936,5729 grid=19 inCar=false vehicles=20 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g3t start (13 steps)
[ZeD.QA] run #13 ok=true
ZEDQA unl load 21.1 of 20 kg, 49 items, Heavy Load 0 OVER   (late output from unl)
ZEDQA g3t removed 8 zombies, 6 ground things, 5 cars | zombies left in the cell 0
ZEDQA g3t kit off: 18 worn, 31 items removed
ZEDQA unl load 0.0 of 20 kg, 0 items, Heavy Load 0   (late output from unl)
ZEDQA g3t back: 57 items, 7 worn, hands nil / nil
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA g3t belt back: 0/0
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ERROR: General f:10838 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x7)
ZEDQA g3t zoom 1
ZEDQA g3t back at 925,13040 (was 925,13040) | carried 57 | zombies in the cell 0
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA g3t end: 0 shots ok, 0 errors
ZEDQA g3t DONE
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x4)
```

### 14. gallery_b11_look.lua (`ZEDQA g14l2`) - PASS, 1 s

- go 28282 at 12:43:47
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #14 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l2 desk menu bar: Debug left out true
ZEDQA g14l2 position readout and cheat lines off true
ZEDQA g14l2 left-edge column hidden true
ZEDQA g14l2 look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #14 ok=true
ZEDQA g14l2 DONE
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x4)
```

### 15. gallery_b19_storybars_only.lua (`ZEDQA sbar`) - PASS, 1 s

- go 28283 at 12:43:51
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #15 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sbar beats: 04 05 09 11
[ZeD.QA] run #15 ok=true
ZEDQA sbar DONE
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x4)
```

### 16. gallery_story_stage.lua (`ZEDQA sts`) - PASS, 30 s

- go 28284 at 12:43:56
- late output from unl (34 line(s), not counted)

```text
[ZeD.QA] state #16 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sts start (22 steps)
[ZeD.QA] run #16 ok=true
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA sts start at 925,13040 | site: Fossoil, West Point | ZeD true
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x9)
ZEDQA sts at the store: room fossoil, building true
ZEDQA sts stock spot 12053,7121 with 3 shelf containers in reach
ZEDQA sts counter 12054,7123 clerk 12053,7123 queue toward 1,0
ZEDQA sts pump 12066,7147 (location_shop_fossoil_01_13), 8 pump squares round the store
ZEDQA sts window 12063,7127, barricaded from 12063,7127
ZEDQA sts windows 9 (smashed 2, barricaded 0) | shelves 19 counters 7 other containers 13 | free floor 81
ZEDQA sts container types: cardboardbox=2 metal_shelves=1 shelves=14 shelvesmag=4 fridge=10 counter=7 cashregister=1
ZEDQA sts blood 12060,7121
ZEDQA sts smoke spot 12073,7130
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x9)
ZEDQA sts aside: 7 worn, 0 on the belt, 57 items
ZEDQA unl load 0.0 of 20 kg, 0 items, Heavy Load 0   (late output from unl)
ZEDQA sts worn: Tshirt_DefaultTEXTURE_TINT Shirt_Lumberjack Jacket_ArmyOliveDrab Vest_Hunting_Khaki Trousers_Denim Socks_Heavy Shoes_ArmyBoots Gloves_LeatherGlovesBlack Hat_BaseballCapGreen Belt2 HolsterSimple_Black Kneepad_Left_Tactical Kneepad_Right_Tactical WristWatch_Left_DigitalBlack Glasses_Prescription_Aviators Bag_ALICEpack_Army Bag_ChestRig Bag_FannyPackBack Bag_Satchel_Leather
ZEDQA sts bag back (Base.Bag_ALICEpack_Army): 13 things
ZEDQA sts bag webbing (Base.Bag_ChestRig): 3 things
ZEDQA sts bag fannypackback (Base.Bag_FannyPackBack): 2 things
ZEDQA sts bag satchel (Base.Bag_Satchel_Leather): 2 things
ZEDQA sts loose: 19/19
ZEDQA sts belt: HuntingKnife@smallbeltleft Hammer@smallbeltright Pistol@holsterright Shotgun@back
ZEDQA unl load 32.5 of 20 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts character was: profession base:unemployed, 28 traits on, 42 perks kept
ZEDQA sts profession base:mechanics | traits base:mechanics2 SMOKER SPEED_DEMON STRONG DEXTROUS FAST_READER PRONE_TO_ILLNESS HEARTY_APPETITE SLOW_HEALER PACIFIST | skills Strength=9 Fitness=5 Mechanics=4 MetalWelding=1
ZEDQA sts power: option set true | pump square grid power true, no-power zone false
ZEDQA sts pumps filled: 8 | the pump reads 500
ZEDQA sts car placements to try: 80
ZEDQA unl load 32.5 of 20 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 1 (12068,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 2 (12064,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 3 (12068,7147 S) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 20 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 4 (12064,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 5 (12067,7149 E) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 20 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 6 (12065,7149 W) no good: pump false, tank area free false
ZEDQA sts note: placement 7 (12068,7148 N) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 20 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts note: placement 8 (12068,7146 S) no good: pump false, tank area free false
ZEDQA sts note: placement 9 (12066,7150 E) no good: pump false, tank area free false
ZEDQA sts note: placement 10 (12069,7147 N) no good: pump false, tank area free false
ZEDQA unl load 32.5 of 20 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts car Base.CarStationWagon at 12063,7147 facing S: the pump finder sees 12066,7147 | tank area 12064.3,7146.0
ZEDQA sts car fuel 2.3 / 39.0
ZEDQA unl load 32.6 of 20 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts native zombies near the store made useless: 0
ZEDQA sts passive zombies outside: 7
ZEDQA sts blood on 1 squares | stains read back true | blood decals option 10
ZEDQA sts seeds: flyer fossoil2 read (was true) | journal true | note true star true
ZEDQA unl load 32.6 of 20 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA sts zoom 1.5
ZEDQA sts shot story_00_scout ok
ZEDQA unl load 32.6 of 20 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA sts staged: car true | zombies 7 outside | blood 1 | carried 44
ZEDQA sts end: 1 shots ok, 0 errors
ZEDQA sts DONE
ZEDQA unl load 32.6 of 20 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x3)
```

### 17. gallery_story_shots.lua (`ZEDQA stz`) - PASS, 52 s

- go 28285 at 12:44:28
- late output from unl (56 line(s), not counted)

```text
[ZeD.QA] state #17 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stz start (60 steps)
[ZeD.QA] run #17 ok=true
ZEDQA stz theme dark teal | profession base:mechanics
ZEDQA unl load 32.6 of 20 kg, 61 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA stz zoom 1
ZEDQA stz seat chooser nil pointed nil
ZEDQA stz shot story_04a_seat_chooser ok
ZEDQA unl load 32.6 of 20 kg, 61 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz in the car true
ZEDQA unl load 32.5 of 20 kg, 60 items, Heavy Load 1 OVER   (late output from unl)   (x4)
ZEDQA stz dash low fuel: fuel 2.3/39.0 | dash fuel 0.0582894802690271 lamp true lights false running true
ZEDQA stz shot story_04a_dash_low_fuel ok
ZEDQA unl load 32.5 of 20 kg, 60 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA stz zoom 0.75
ZEDQA unl load 32.5 of 20 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz world menu: Window | Clean Stains | Sit on ground | Walk to
ZEDQA stz window submenu true: < Back | Smash Window | Barricade (Planks) | barricade picked true
ZEDQA stz shot story_05a_barricade_menu ok
ZEDQA unl load 32.5 of 20 kg, 60 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA unl load 29.4 of 20 kg, 60 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA unl load 28.4 of 20 kg, 57 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA unl load 26.3 of 20 kg, 57 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz story_05b_barricade_bar: ISBarricadeAction at 40% (2 of that type queued)
ZEDQA stz shot story_05b_barricade_bar ok
ZEDQA unl load 26.3 of 20 kg, 57 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA unl load 23.2 of 20 kg, 54 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA unl load 22.2 of 20 kg, 51 items, Heavy Load 0 OVER   (late output from unl)
ZEDQA stz planks on the window: 3
ZEDQA unl load 23.2 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz refuel: in the gas tank area true | pump true reads 500
ZEDQA unl load 23.2 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA stz zoom 0.75
ZEDQA unl load 23.2 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA stz story_09a_refuel_car_bar: ISRefuelFromGasPump at 15% (1 of that type queued)
ZEDQA stz shot story_09a_refuel_car_bar ok
ZEDQA unl load 23.2 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA unl load 22.1 of 20 kg, 51 items, Heavy Load 0 OVER   (late output from unl)   (x2)
ZEDQA unl load 22.4 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA unl load 22.7 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)   (x2)
ZEDQA unl load 23.0 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz story_09b_gas_can_card: ISTakeFuel at 35% (1 of that type queued)
ZEDQA stz shot story_09b_gas_can_card ok
ZEDQA stz box story_09b_gas_can_card char 751,0-1913,735
ZEDQA stz box story_09b_gas_can_card char windowbox 1872,11-1895,34
ZEDQA stz box story_09b_gas_can_card world 1927,0-2704,735
ZEDQA stz box story_09b_gas_can_card world windowbox 2663,11-2686,34
ZEDQA unl load 23.0 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA unl load 26.2 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA stz zoom 1
ZEDQA unl load 26.2 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)   (x4)
ZEDQA stz dash refuelled: fuel 37.0/39.0 | dash fuel 0.9491738516662147 lamp false lights false running true
ZEDQA stz shot story_09c_dash_fuel_full ok
ZEDQA unl load 26.2 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA stz zoom 0.5
ZEDQA unl load 26.2 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)   (x3)
ZEDQA stz moodles: HUNGRY STRESS THIRST | hover on 2
ZEDQA stz shot story_11_smoke_break ok
ZEDQA unl load 26.2 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)
ZEDQA stz theme now dark teal (the teardown re-applies the options)
ZEDQA stz end: 8 shots ok, 0 errors
ZEDQA stz DONE
ZEDQA unl load 26.2 of 20 kg, 51 items, Heavy Load 1 OVER   (late output from unl)   (x3)
```

### 18. gallery_story_teardown.lua (`ZEDQA stt`) - PASS, 10 s

- go 28286 at 12:45:24
- late output from unl (14 line(s), not counted)

```text
[ZeD.QA] state #18 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stt start (17 steps)
[ZeD.QA] run #18 ok=true
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 0 native zombies' flag back
ZEDQA stt planks off 3 | blood cleaned on 1 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 34 items removed
ZEDQA unl load 0.0 of 20 kg, 0 items, Heavy Load 0   (late output from unl)
ZEDQA stt back: 57 items, 7 worn
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA stt belt back: 0/0
ZEDQA stt character back: profession base:unemployed | 97 traits | 42 perks
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 2
ZEDQA stt ZeD back: dark teal small (was dark teal small)
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ERROR: General f:20082 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x7)
ZEDQA stt zoom 1
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA stt back at 925,13040 (was 925,13040) | carried 57 | zombies in the cell 0
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
```

### 19. gallery_b11_look.lua (`ZEDQA g14l3`) - PASS, 1 s

- go 28287 at 12:45:37
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #19 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l3 desk menu bar: Debug left out true
ZEDQA g14l3 position readout and cheat lines off true
ZEDQA g14l3 left-edge column hidden true
ZEDQA g14l3 look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #19 ok=true
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA g14l3 DONE
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
```

### 20. gallery_b19_a.lua (`ZEDQA gb19ah`) - PASS, 41 s

- go 28288 at 12:45:41
- late output from unl (34 line(s), not counted)
- screenshots: zqa_ap_1_tab_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_4_popout_microwave.png, zqa_b19_speed_bubble.png

```text
[ZeD.QA] state #20 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gb19ah start (the QA home, 57 steps)
[ZeD.QA] run #20 ok=true
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA gb19ah indoors at 892,13007: 5 room squares round, 3 sides
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA gb19ah look dark teal size small | scale 1.75 | font size option 2 | screen 3840x2160
ZEDQA gb19ah grid power here true | faces on true
ZEDQA gb19ah placed: oven true, microwave true
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA gb19ah the Craft tab's pop-out button: true
ZEDQA gb19ah shot zqa_ap_1_tab_stove
ZEDQA gb19ah box zqa_ap_1_tab_stove char 1134,0-1911,735
ZEDQA gb19ah box zqa_ap_1_tab_stove world 1929,0-3546,735
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gb19ah oven on true
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gb19ah shot zqa_ap_2b_popout_stove_on
ZEDQA gb19ah box zqa_ap_2b_popout_stove_on char 1134,0-1911,735
ZEDQA gb19ah box zqa_ap_2b_popout_stove_on world 1929,0-3546,735
ZEDQA gb19ah box zqa_ap_2b_popout_stove_on popout 1984,862-2770,1180
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gb19ah shot zqa_ap_4_popout_microwave
ZEDQA gb19ah box zqa_ap_4_popout_microwave char 1134,0-1911,735
ZEDQA gb19ah box zqa_ap_4_popout_microwave world 1929,0-2706,735
ZEDQA gb19ah box zqa_ap_4_popout_microwave popout 1984,830-2770,1212
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA gb19ah machines placed 3
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA gb19ah shot g14_ldy_washer
ZEDQA gb19ah box g14_ldy_washer char 1134,0-1911,735
ZEDQA gb19ah box g14_ldy_washer world 1929,0-2706,735
ZEDQA gb19ah box g14_ldy_washer popout 1984,749-2524,1407
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gb19ah shot g14_ldy_dryer
ZEDQA gb19ah box g14_ldy_dryer char 1134,0-1911,735
ZEDQA gb19ah box g14_ldy_dryer world 1929,0-2706,735
ZEDQA gb19ah box g14_ldy_dryer popout 1984,749-2524,1407
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gb19ah shot g14_ldy_combo
ZEDQA gb19ah box g14_ldy_combo char 1134,0-1911,735
ZEDQA gb19ah box g14_ldy_combo world 1929,0-2706,735
ZEDQA gb19ah box g14_ldy_combo popout 1316,749-1856,1407
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA gb19ah placed: radio true, TV true
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gb19ah shot g19_radio_popout
ZEDQA gb19ah box g19_radio_popout char 1134,0-1911,735
ZEDQA gb19ah box g19_radio_popout world 1929,0-2706,735
ZEDQA gb19ah box g19_radio_popout popout 1984,814-2770,1228
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gb19ah shot g19_tv_tab
ZEDQA gb19ah box g19_tv_tab char 1134,0-1911,735
ZEDQA gb19ah box g19_tv_tab world 1929,0-3546,735
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ERROR: General f:22672 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA ff speed 2: time multiplier 5, true multiplier 5
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA gb19ah shot zqa_b19_speed_bubble
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA layout gb19ah put back
ZEDQA gb19ah put back: things taken away, grid and water, options, theme, speed, god mode, window places; at 925,13040
ZEDQA gb19ah DONE
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x4)
```

### 21. gallery_b19_b.lua (`ZEDQA gb19b`) - FAIL, 103 s

- go 28289 at 12:46:25
- 28 Java exception(s) in the log
- late output from unl (86 line(s), not counted)
- screenshots: zqa_bub_both_dark.png, zqa_g4_guide_bubble.png, zqa_pr_01_sleep.png, zqa_pr_06_keyboard.png, zqa_pr_07_alarm.png, zqa_padmap_options.png, zqa_b19_ask_cancel.png, zqa_b19_window_menu.png, zqa_g4_belt_toast.png, zqa_g4_window_radio.png, zqa_g3_wheel_character_eat.png, zqa_g3_wheel_now_light.png, zqa_g3_wheel_use_smoke.png, zqa_g3_footer_pad.png

```text
[ZeD.QA] state #21 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gb19b start
[ZeD.QA] run #21 ok=true
ZEDQA gb19b start at 925,13040 | look dark teal | kit watch nil
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ERROR: General f:23376> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).lighten(spawnpoints.lua:181)
    Lua(Vanilla).step(spawnpoints.lua:277)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b load: 0 things taken out of the inventory for the run (kept by the script, put back at the end); now 8.2 kg, 57 items, Heavy Load -1
ZEDQA unl load 8.8 of 20 kg, 60 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:23685> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:287)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_bub_both_dark (8.8 of 20 kg, 60 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 8.8 of 20 kg, 60 items, Heavy Load 0   (late output from unl)   (x6)
ZEDQA unl load 8.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:24500> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:299)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot gbw_DigitalBlack (8.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 8.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:24699> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:299)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot gbw_DigitalTimez (8.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 8.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:24897> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:299)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot gbw_ClassicGold (8.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 8.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:25097> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:299)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot gbw_DigitalRed (8.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 8.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 8.8 of 20 kg, 60 items, Heavy Load 0   (late output from unl)   (x4)
ERROR: General f:25535> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:337)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_g4_guide_bubble (8.8 of 20 kg, 60 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 8.8 of 20 kg, 60 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:25681> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:367)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_pr_01_sleep (8.8 of 20 kg, 60 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 8.8 of 20 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA gb19b typed: Go Bag
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ERROR: General f:25794> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:389)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_pr_06_keyboard (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:25902> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:401)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_pr_07_alarm (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x4)
ERROR: General f:25926> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:426)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_padmap_options (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA gb19b generator running true, faces on true
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ERROR: General f:26152> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:459)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot g19_generator_popout (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA vp gb19b player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=917,13030 dist=13.6 chunk=true inMap=true car=Base.CarNormal at 917.0,13030.0 dist=13.6 vehicles=32
ZEDQA car gb19b Base.CarNormal spawned on spot 11 (917,13030)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ERROR: General f:26340> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:495)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot gb_seat_cabin (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ERROR: General f:26459> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:511)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot gb_simple_seat (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA gb19b engine running true
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x3)
ERROR: General f:27092> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:549)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot gb_plain_dash (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x4)
ERROR: General f:27530> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:580)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot g5_car_radio (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA gb19b note: g5_car_radio is a sedan at the drag strip (the beta 13 picture: the station wagon in the mall lot)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x4)
ERROR: General f:27912> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:676)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_b19_ask_cancel (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA gb19b window menu: Theme | Accent | Text size | See-through | Controller highlight | Reset this window | Reset both windows | Save position | Go to saved position | Bug report | Controller map | Hide the interface | ZeD setup...
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ERROR: General f:28019> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:714)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_b19_window_menu (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x4)
ZEDQA gb19b away 70,0 open true
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ERROR: General f:28586> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:767)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_g4_belt_toast (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:28785> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:771)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_g4_window_radio (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:28963> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:805)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_g3_wheel_character_eat (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ERROR: General f:29052> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:808)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_g3_wheel_now_light (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ERROR: General f:29141> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:818)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_g3_wheel_use_smoke (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:29313> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:822)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot zqa_g3_footer_pad (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ERROR: General f:29466> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:832)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot gb_simple_watch (9.8 of 20 kg, 62 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ERROR: General f:29555> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:840)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot gb_simple_belt (9.8 of 20 kg, 61 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 9.8 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 10.2 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:29700> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:872)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot gb_plain_radio (10.2 of 20 kg, 62 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 10.2 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 11.3 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ERROR: General f:29728> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.Moodles.Moodle.getLevel()" because the return value of "java.util.Map.get(Object)" is null at Moodles.getMoodleLevel(Moodles.java:40).
    Lua(Vanilla).pcall(spawnpoints.lua:116)
    Lua(Vanilla).heavy(spawnpoints.lua:116)
    Lua(Vanilla).shot(spawnpoints.lua:121)
    Lua(Vanilla).step(spawnpoints.lua:895)
    Lua(Vanilla).tick(spawnpoints.lua:948)
ZEDQA gb19b shot gb_forms_setup (11.3 of 20 kg, 62 items, Heavy Load -1; pointer at 3837,1080, hidden)
ZEDQA unl load 11.3 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA gb19b load put back: 0 things; now 8.2 kg, 57 items
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA layout gb19b put back
ZEDQA gb19b taken 27: zqa_bub_both_dark gbw_DigitalBlack gbw_DigitalTimez gbw_ClassicGold gbw_DigitalRed zqa_g4_guide_bubble zqa_pr_01_sleep zqa_pr_06_keyboard zqa_pr_07_alarm zqa_padmap_options g19_generator_popout gb_seat_cabin gb_simple_seat gb_plain_dash g5_car_radio zqa_b19_ask_cancel zqa_b19_window_menu zqa_g4_belt_toast zqa_g4_window_radio zqa_g3_wheel_character_eat zqa_g3_wheel_now_light zqa_g3_wheel_use_smoke zqa_g3_footer_pad gb_simple_watch gb_simple_belt gb_plain_radio gb_forms_setup
ZEDQA gb19b not taken 0:
ZEDQA gb19b not here (main menu only, gallery_b11_menus_run.ps1): desk_05_trash_computer mm4_01_options_zed mm4_02_options_interface mm4_03_options_hidden
ZEDQA gb19b put back: look dark teal, options, items, objects, car, layout, time, speed, cheats
ZEDQA gb19b DONE
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x4)
```

### 22. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28290 at 12:48:12

```text
[ZeD.QA] state #22 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.2 of 20 kg, 57 items, Heavy Load 0
ZEDQA rel put back 60 things; after: 50.0 of 20 kg, 117 items, Heavy Load 1 OVER
[ZeD.QA] run #22 ok=true
ZEDQA rel DONE
```

### 23. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 28291 at 12:48:16

```text
[ZeD.QA] state #23 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #23 ok=true
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
