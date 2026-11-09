# ZeD-UI regression - 2026-11-09 09:27 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-09 09:27:16 |
| Finished | 2026-11-09 09:43:30 (16 min 13 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta10 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b10_stage.txt (19 scripts) |
| Result | **13/19 pass**, 5 warn, 1 fail, 0 timeout |
| Go numbers | 10000 to 10020 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 10019, 10020)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_staged_ver.lua | sv | PASS | 1 |  |  |
| 3 | zedqa_b9a_1.lua | b9a1 | PASS | 91 | zqa_b9a1_1280x800_char_1_rolled.png, zqa_b9a1_1280x800_char_2_down.png, zqa_b9a1_1280x800_char_3_dropped.png, zqa_b9a1_1280x800_char_4_drawer_rolled.png, zqa_b9a1_1280x800_char_5_drawer_out.png, zqa_b9a1_1280x800_world_1_rolled.png, zqa_b9a1_1280x800_world_2_down.png, zqa_b9a1_1280x800_world_3_dropped.png, zqa_b9a1_1280x800_world_4_drawer_rolled.png, zqa_b9a1_1280x800_world_5_drawer_out.png |  |
| 4 | zedqa_b9a_2.lua | b9a2 | WARN | 68 | zqa_b9a2_1280x800_1_floor_stack.png, zqa_b9a2_1280x800_2_in_inventory.png, zqa_b9a2_1280x800_3_on_floor.png, zqa_b9a2_1280x800_4_grid.png, zqa_b9a2_1280x800_5_open_stack.png, zqa_b9a2_1280x800_6_one_moved.png | 3 ERR line(s) |
| 5 | zedqa_b9a_3.lua | b9a3 | PASS | 43 | zqa_b9a3_1280x800_char_inventory.png, zqa_b9a3_1280x800_char_drawer.png, zqa_b9a3_1280x800_world_inventory.png, zqa_b9a3_1280x800_world_drawer.png |  |
| 6 | zedqa_b9a_4.lua | b9a4 | WARN | 69 | zqa_b9a4_1280x800_char_1_rolled_in.png, zqa_b9a4_1280x800_char_2_drawer_back.png, zqa_b9a4_1280x800_char_3_held_over_target.png, zqa_b9a4_1280x800_char_4_dropped.png, zqa_b9a4_1280x800_world_1_rolled_in.png, zqa_b9a4_1280x800_world_2_drawer_back.png, zqa_b9a4_1280x800_world_3_held_over_target.png, zqa_b9a4_1280x800_world_4_dropped.png | 1 ERR line(s) |
| 7 | zedqa_b9a_5.lua | b9a5 | PASS | 67 | zqa_b9a5_1280x800_1_doll.png, zqa_b9a5_1280x800_inventory_to_the_doll_s_Back.png, zqa_b9a5_1280x800_floor_to_the_Back_box_under_the_doll.png, zqa_b9a5_1280x800_2_list.png, zqa_b9a5_1280x800_inventory_to_the_Back_row_of_the_list.png |  |
| 8 | zedqa_b9a_6.lua | b9a6 | PASS | 44 | zqa_b9a6_1280x800_char_1_rolled_in.png, zqa_b9a6_1280x800_char_2_back.png, zqa_b9a6_1280x800_char_3_loot.png, zqa_b9a6_1280x800_world_1_rolled_in.png, zqa_b9a6_1280x800_world_2_back.png, zqa_b9a6_1280x800_world_3_loot.png |  |
| 9 | zedqa_b9a_7.lua | b9a7 | PASS | 36 | zqa_b9a7_1280x800_1_card.png, zqa_b9a7_1280x800_the_220_card.png, zqa_b9a7_1280x800_2_equip_card.png, zqa_b9a7_1280x800_the_Equip_card.png |  |
| 10 | zedqa_b9a_8.lua | b9a8 | WARN | 15 | zqa_b9a8_1280x800_1_pin.png, zqa_b9a8_1280x800_2_unpin.png | 2 ERR line(s) |
| 11 | zedqa_b9a_9.lua | b9a9 | PASS | 38 | zqa_b9a9_1280x800_char_1_bar.png, zqa_b9a9_1280x800_char_2_rolled.png, zqa_b9a9_1280x800_char_3_tab_folds.png, zqa_b9a9_1280x800_world_1_bar.png, zqa_b9a9_1280x800_world_2_rolled.png, zqa_b9a9_1280x800_world_3_tab_folds.png |  |
| 12 | zedqa_dual_pin.lua | dpn | WARN | 34 | zqa_dpn_1280x800_1_pins.png, zqa_dpn_1280x800_2_maps_pinned.png, zqa_dpn_1280x800_4_containers_down.png, zqa_dpn_1280x800_5_char_drawer_down.png, zqa_dpn_1280x800_5_char_drawer_pinned.png, zqa_dpn_1280x800_6_aim.png, zqa_dpn_1280x800_7_rod_pin.png, zqa_dpn_1280x800_2_6b_inventory_part.png, zqa_dpn_1280x800_2_6b_drawer_part.png, zqa_dpn_1280x800_9_pad_down.png | 1 ERR line(s) |
| 13 | zedqa_doll_v4.lua | dollv4 | PASS | 23 | zqa_dollv4_1280x800_wide.png, zqa_dollv4_1280x800_dpad.png, zqa_dollv4_1280x800_wide_pads.png, zqa_dollv4_1280x800_card.png, zqa_dollv4_1280x800_narrow.png, zqa_dollv4_1280x800_short.png |  |
| 14 | zedqa_curtain.lua | cu | WARN | 155 | zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png | 1 ERR line(s) |
| 15 | zedqa_segbars.lua | segb | PASS | 1 |  |  |
| 16 | zedqa_world_pad_take.lua | wpt | PASS | 63 |  |  |
| 17 | zedqa_moodles.lua | mood | **FAIL** | 23 | zqa_mood_right.png, zqa_mood_left.png, zqa_mood_bottom.png, zqa_mood_notices_off.png | 3 Java exception(s) in the log; 3 ERR line(s) |
| 18 | b10_guide_open_frames.lua | gframes | PASS | 5 | zqa_gframes_1280x800_open.png, zqa_gframes_1280x800_bubble.png, zqa_gframes_1280x800_f1.png |  |
| 19 | zedqa_guide_bubble.lua | gbub | PASS | 58 | zqa_gbub_1280x800_2_bubble_from_belt.png, zqa_gbub_1280x800_3_guide_opened.png, zqa_gbub_1280x800_7_controller_variant.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 10000 at 09:28:13

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_staged_ver.lua (`ZEDQA sv`) - PASS, 1 s

- go 10001 at 09:28:18

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sv version=0.3.0-beta10 dir=C:\Users\you\ZomboidStaged\mods\ZeD-UI
[ZeD.QA] run #2 ok=true
ZEDQA sv DONE
```

### 3. zedqa_b9a_1.lua (`ZEDQA b9a1`) - PASS, 91 s

- go 10002 at 09:28:22
- screenshots: zqa_b9a1_1280x800_char_1_rolled.png, zqa_b9a1_1280x800_char_2_down.png, zqa_b9a1_1280x800_char_3_dropped.png, zqa_b9a1_1280x800_char_4_drawer_rolled.png, zqa_b9a1_1280x800_char_5_drawer_out.png, zqa_b9a1_1280x800_world_1_rolled.png, zqa_b9a1_1280x800_world_2_down.png, zqa_b9a1_1280x800_world_3_dropped.png, zqa_b9a1_1280x800_world_4_drawer_rolled.png, zqa_b9a1_1280x800_world_5_drawer_out.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a1 screen 1280x800
ZEDQA b9a1 start
[ZeD.QA] run #3 ok=true
ZEDQA b9a1 PASS char: (staged) drawer pinned on equip, the inventory rolled under its rod
ZEDQA b9a1 shot char_1_rolled
ZEDQA b9a1 PASS char to the rod: the row to drag is on screen
ZEDQA b9a1 PASS char to the rod: the item is held (the drag object is active)
ZEDQA b9a1 PASS char: held over the rod, the rolled inventory comes down at once (0.7 s)
ZEDQA b9a1 PASS char: ... the pinned drawer still open
ZEDQA b9a1 shot char_2_down
ZEDQA b9a1 PASS char: held over its list 2.5 s, nothing rolls up
ZEDQA b9a1 PASS char: the drop landed in that list
ZEDQA b9a1 shot char_3_dropped
ZEDQA b9a1 PASS char: (staged) inventory pinned, the drawer rolled in
ZEDQA b9a1 PASS char: ... its tab still selected (no switch to Loot)
ZEDQA b9a1 shot char_4_drawer_rolled
ZEDQA b9a1 PASS char to the tab strip: the row to drag is on screen
ZEDQA b9a1 PASS char to the tab strip: the item is held (the drag object is active)
ZEDQA b9a1 PASS char: held over the tab strip, the drawer comes out at once (0.7 s)
ZEDQA b9a1 shot char_5_drawer_out
ZEDQA b9a1 PASS world: (staged) drawer pinned on maps, the inventory rolled under its rod
ZEDQA b9a1 shot world_1_rolled
ZEDQA b9a1 PASS world to the rod: the row to drag is on screen
ZEDQA b9a1 PASS world to the rod: the item is held (the drag object is active)
ZEDQA b9a1 PASS world: held over the rod, the rolled inventory comes down at once (0.7 s)
ZEDQA b9a1 PASS world: ... the pinned drawer still open
ZEDQA b9a1 shot world_2_down
ZEDQA b9a1 PASS world: held over its list 2.5 s, nothing rolls up
ZEDQA b9a1 PASS world: the drop landed in that list
ZEDQA b9a1 shot world_3_dropped
ZEDQA b9a1 PASS world: (staged) inventory pinned, the drawer rolled in
ZEDQA b9a1 PASS world: ... its tab still selected (no switch to Loot)
ZEDQA b9a1 shot world_4_drawer_rolled
ZEDQA b9a1 PASS world to the tab strip: the row to drag is on screen
ZEDQA b9a1 PASS world to the tab strip: the item is held (the drag object is active)
ZEDQA b9a1 PASS world: held over the tab strip, the drawer comes out at once (0.7 s)
ZEDQA b9a1 shot world_5_drawer_out
ZEDQA b9a1 RESULT 24 pass, 0 fail
ZEDQA b9a1 DONE
```

### 4. zedqa_b9a_2.lua (`ZEDQA b9a2`) - WARN, 68 s

- go 10003 at 09:29:57
- 3 ERR line(s)
- screenshots: zqa_b9a2_1280x800_1_floor_stack.png, zqa_b9a2_1280x800_2_in_inventory.png, zqa_b9a2_1280x800_3_on_floor.png, zqa_b9a2_1280x800_4_grid.png, zqa_b9a2_1280x800_5_open_stack.png, zqa_b9a2_1280x800_6_one_moved.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a2 screen 1280x800
ZEDQA b9a2 start
[ZeD.QA] run #4 ok=true
ZEDQA b9a2 nails held before: 12
ZEDQA b9a2 shot 1_floor_stack
ZEDQA b9a2 PASS World to Character: the row to drag is on screen
ZEDQA b9a2 PASS World to Character: the row is held (the drag object is active)
ZEDQA b9a2 PASS a closed stack dragged from the World list: all six nails moved (12 to 19)
ZEDQA b9a2 shot 2_in_inventory
ZEDQA b9a2 PASS Character to the floor: the row to drag is on screen
ZEDQA b9a2 PASS Character to the floor: the row is held (the drag object is active)
ZEDQA b9a2 PASS a closed stack dragged out over the world: all six dropped (19 to 0)
ZEDQA b9a2 shot 3_on_floor
ZEDQA b9a2 floor key type:floor
ZEDQA b9a2 shot 4_grid
ZEDQA b9a2 PASS grid cell to Character: the row to drag is on screen
ZEDQA b9a2 PASS grid cell to Character: the row is held (the drag object is active)
ZEDQA b9a2 PASS a grid cell (the grid opens no stacks): all six moved (0 to 19)
ZEDQA b9a2 the player's list: grid (player)
ZEDQA b9a2 PASS the nails stack's chevron is on screen
ZEDQA b9a2 FAIL the chevron opens the stack (a second nails row)
ZEDQA b9a2 shot 5_open_stack
ZEDQA b9a2 FAIL one row of an open stack: the row to drag is on screen
ZEDQA b9a2 FAIL an open stack's row moves only its own nail (18 to 18)
ZEDQA b9a2 shot 6_one_moved
ZEDQA b9a2 RESULT 10 pass, 3 fail
ZEDQA b9a2 DONE
```

### 5. zedqa_b9a_3.lua (`ZEDQA b9a3`) - PASS, 43 s

- go 10004 at 09:31:08
- screenshots: zqa_b9a3_1280x800_char_inventory.png, zqa_b9a3_1280x800_char_drawer.png, zqa_b9a3_1280x800_world_inventory.png, zqa_b9a3_1280x800_world_drawer.png

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a3 screen 1280x800
ZEDQA b9a3 start
[ZeD.QA] run #5 ok=true
ZEDQA b9a3 PASS char inventory: (staged) down and whole on equip, pinned
ZEDQA b9a3 PASS char inventory: (staged) both halves unpinned, the whole window rolled up on equip, the drawer not folded first
ZEDQA b9a3 char inventory: its part of the rolled bar at 480,10 (the halves meet at 320 of 640)
ZEDQA b9a3 char inventory: the pointer is at 480,9 (asked 480,10)
ZEDQA b9a3 PASS char inventory: resting on its part of the bar brings the window down
ZEDQA b9a3 PASS char: ... with only the inventory: the drawer still rolled in
ZEDQA b9a3 PASS char: ... and the window still on equip (not Loot)
ZEDQA b9a3 PASS char: ... the title still names the tab (Angel Cross + Equipment)
ZEDQA b9a3 shot char_inventory
ZEDQA b9a3 PASS char drawer: (staged) down and whole on equip, pinned
ZEDQA b9a3 PASS char drawer: (staged) both halves unpinned, the whole window rolled up on equip, the drawer not folded first
ZEDQA b9a3 char drawer: its part of the rolled bar at 160,10 (the halves meet at 320 of 640)
ZEDQA b9a3 char drawer: the pointer is at 160,9 (asked 160,10)
ZEDQA b9a3 PASS char drawer: resting on its part of the bar brings the window down
ZEDQA b9a3 PASS char: ... with only the drawer: the inventory under its rod
ZEDQA b9a3 shot char_drawer
ZEDQA b9a3 PASS world inventory: (staged) down and whole on maps, pinned
ZEDQA b9a3 PASS world inventory: (staged) both halves unpinned, the whole window rolled up on maps, the drawer not folded first
ZEDQA b9a3 world inventory: its part of the rolled bar at 800,10 (the halves meet at 320 of 640)
ZEDQA b9a3 world inventory: the pointer is at 800,9 (asked 800,10)
ZEDQA b9a3 PASS world inventory: resting on its part of the bar brings the window down
ZEDQA b9a3 PASS world: ... with only the inventory: the drawer still rolled in
ZEDQA b9a3 PASS world: ... and the window still on maps (not Loot)
ZEDQA b9a3 PASS world: ... the title still names the tab (Ground + Maps)
ZEDQA b9a3 shot world_inventory
ZEDQA b9a3 PASS world drawer: (staged) down and whole on maps, pinned
ZEDQA b9a3 PASS world drawer: (staged) both halves unpinned, the whole window rolled up on maps, the drawer not folded first
ZEDQA b9a3 world drawer: its part of the rolled bar at 1120,10 (the halves meet at 320 of 640)
ZEDQA b9a3 world drawer: the pointer is at 1120,9 (asked 1120,10)
ZEDQA b9a3 PASS world drawer: resting on its part of the bar brings the window down
ZEDQA b9a3 PASS world: ... with only the drawer: the inventory under its rod
ZEDQA b9a3 shot world_drawer
ZEDQA b9a3 RESULT 20 pass, 0 fail
ZEDQA b9a3 DONE
```

### 6. zedqa_b9a_4.lua (`ZEDQA b9a4`) - WARN, 69 s

- go 10005 at 09:31:54
- 1 ERR line(s)
- screenshots: zqa_b9a4_1280x800_char_1_rolled_in.png, zqa_b9a4_1280x800_char_2_drawer_back.png, zqa_b9a4_1280x800_char_3_held_over_target.png, zqa_b9a4_1280x800_char_4_dropped.png, zqa_b9a4_1280x800_world_1_rolled_in.png, zqa_b9a4_1280x800_world_2_drawer_back.png, zqa_b9a4_1280x800_world_3_held_over_target.png, zqa_b9a4_1280x800_world_4_dropped.png

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a4 screen 1280x800
ZEDQA b9a4 start
[ZeD.QA] run #6 ok=true
ZEDQA b9a4 PASS char: the item's row is on screen
ZEDQA b9a4 PASS char: (staged) looking through the list, the drawer rolled in
ZEDQA b9a4 PASS char: (staged) the other window rolled up meanwhile
ZEDQA b9a4 shot char_1_rolled_in
ZEDQA b9a4 char: after the press: pending false, card false, tab equip, the pointer at 540,252 over nil, the list at 330,20
ZEDQA b9a4 FAIL char: the item is held (the drag object is active)
ZEDQA b9a4 shot char_2_drawer_back
ZEDQA b9a4 shot char_3_held_over_target
ZEDQA b9a4 shot char_4_dropped
ZEDQA b9a4 PASS world: the item's row is on screen
ZEDQA b9a4 PASS world: (staged) looking through the list, the drawer rolled in
ZEDQA b9a4 PASS world: (staged) the other window rolled up meanwhile
ZEDQA b9a4 shot world_1_rolled_in
ZEDQA b9a4 world: after the press: pending true, card true, tab loot, the pointer at 837,165 over Base.Nails, the list at 675,20
ZEDQA b9a4 PASS world: the item is held (the drag object is active)
ZEDQA b9a4 PASS world: the item picked up: the drawer is back on maps
ZEDQA b9a4 shot world_2_drawer_back
ZEDQA b9a4 PASS world: carried over its own list 4 s: both halves stay open
ZEDQA b9a4 PASS world: over the other window's rolled bar, it comes down
ZEDQA b9a4 PASS world: held over the other window's list 3 s, it stays down
ZEDQA b9a4 PASS world: ... and the source window's drawer stays too
ZEDQA b9a4 shot world_3_held_over_target
ZEDQA b9a4 shot world_4_dropped
ZEDQA b9a4 RESULT 12 pass, 1 fail
ZEDQA b9a4 DONE
```

### 7. zedqa_b9a_5.lua (`ZEDQA b9a5`) - PASS, 67 s

- go 10006 at 09:33:06
- screenshots: zqa_b9a5_1280x800_1_doll.png, zqa_b9a5_1280x800_inventory_to_the_doll_s_Back.png, zqa_b9a5_1280x800_floor_to_the_Back_box_under_the_doll.png, zqa_b9a5_1280x800_2_list.png, zqa_b9a5_1280x800_inventory_to_the_Back_row_of_the_list.png

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a5 screen 1280x800
ZEDQA b9a5 start
[ZeD.QA] run #7 ok=true
ZEDQA b9a5 PASS (staged) the back is empty, the Equip tab on the doll
ZEDQA b9a5 shot 1_doll
ZEDQA b9a5 inventory to the doll's Back: the target at 291,69 (the Character window's foot at 315)
ZEDQA b9a5 PASS inventory to the doll's Back: the bat's row is on screen
ZEDQA b9a5 PASS inventory to the doll's Back: the bat is held (the drag object is active)
ZEDQA b9a5 PASS inventory to the doll's Back: the target is on screen
ZEDQA b9a5 inventory to the doll's Back: released at 291,69 (the game sees the pointer at 291,68)
ZEDQA b9a5 PASS inventory to the doll's Back: the bat is attached to the back (Base.BaseballBat)
ZEDQA b9a5 shot inventory_to_the_doll_s_Back
ZEDQA b9a5 PASS inventory to the doll's Back: (put back) the back is empty again
ZEDQA b9a5 floor to the Back box under the doll: the target at 177,270 (the Character window's foot at 315)
ZEDQA b9a5 PASS floor to the Back box under the doll: the bat's row is on screen
ZEDQA b9a5 PASS floor to the Back box under the doll: the bat is held (the drag object is active)
ZEDQA b9a5 PASS floor to the Back box under the doll: the target is on screen
ZEDQA b9a5 floor to the Back box under the doll: released at 177,270 (the game sees the pointer at 177,269)
ZEDQA b9a5 PASS floor to the Back box under the doll: the bat is attached to the back (Base.BaseballBat)
ZEDQA b9a5 shot floor_to_the_Back_box_under_the_doll
ZEDQA b9a5 PASS floor to the Back box under the doll: (put back) the back is empty again
ZEDQA b9a5 shot 2_list
ZEDQA b9a5 inventory to the Back row of the list: the target at 201,265 (the Character window's foot at 315)
ZEDQA b9a5 PASS inventory to the Back row of the list: the bat's row is on screen
ZEDQA b9a5 PASS inventory to the Back row of the list: the bat is held (the drag object is active)
ZEDQA b9a5 PASS inventory to the Back row of the list: the target is on screen
ZEDQA b9a5 inventory to the Back row of the list: released at 201,265 (the game sees the pointer at 201,264)
ZEDQA b9a5 PASS inventory to the Back row of the list: the bat is attached to the back (Base.BaseballBat)
ZEDQA b9a5 shot inventory_to_the_Back_row_of_the_list
ZEDQA b9a5 PASS inventory to the Back row of the list: (put back) the back is empty again
ZEDQA b9a5 RESULT 16 pass, 0 fail
ZEDQA b9a5 DONE
```

### 8. zedqa_b9a_6.lua (`ZEDQA b9a6`) - PASS, 44 s

- go 10007 at 09:34:16
- screenshots: zqa_b9a6_1280x800_char_1_rolled_in.png, zqa_b9a6_1280x800_char_2_back.png, zqa_b9a6_1280x800_char_3_loot.png, zqa_b9a6_1280x800_world_1_rolled_in.png, zqa_b9a6_1280x800_world_2_back.png, zqa_b9a6_1280x800_world_3_loot.png

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a6 screen 1280x800
ZEDQA b9a6 start
[ZeD.QA] run #8 ok=true
ZEDQA b9a6 PASS char: (staged) down and whole on equip, the pointer in the list
ZEDQA b9a6 PASS char: looking around the inventory: the drawer half rolled in
ZEDQA b9a6 PASS char: ... the tab strip still on equip (no switch to Loot)
ZEDQA b9a6 PASS char: ... the title unchanged (Angel Cross + Equipment)
ZEDQA b9a6 shot char_1_rolled_in
ZEDQA b9a6 char: the pointer at 38,9 in the window; the halves meet at 44; on the drawer's bar: true
ZEDQA b9a6 PASS char: resting on the drawer's part of the bar: back on equip
ZEDQA b9a6 shot char_2_back
ZEDQA b9a6 PASS char: (staged) rolled in again
ZEDQA b9a6 PASS char: the Loot tab is on the strip
ZEDQA b9a6 PASS char: Loot pressed while rolled in: Loot, the fold forgotten
ZEDQA b9a6 PASS char: ... the bar no longer brings equip back
ZEDQA b9a6 shot char_3_loot
ZEDQA b9a6 PASS world: (staged) down and whole on maps, the pointer in the list
ZEDQA b9a6 PASS world: looking around the inventory: the drawer half rolled in
ZEDQA b9a6 PASS world: ... the tab strip still on maps (no switch to Loot)
ZEDQA b9a6 PASS world: ... the title unchanged (Ground + Maps)
ZEDQA b9a6 shot world_1_rolled_in
ZEDQA b9a6 world: the pointer at 295,9 in the window; the halves meet at 289; on the drawer's bar: true
ZEDQA b9a6 PASS world: resting on the drawer's part of the bar: back on maps
ZEDQA b9a6 shot world_2_back
ZEDQA b9a6 PASS world: (staged) rolled in again
ZEDQA b9a6 PASS world: the Loot tab is on the strip
ZEDQA b9a6 PASS world: Loot pressed while rolled in: Loot, the fold forgotten
ZEDQA b9a6 PASS world: ... the bar no longer brings maps back
ZEDQA b9a6 shot world_3_loot
ZEDQA b9a6 RESULT 18 pass, 0 fail
ZEDQA b9a6 DONE
```

### 9. zedqa_b9a_7.lua (`ZEDQA b9a7`) - PASS, 36 s

- go 10008 at 09:35:03
- screenshots: zqa_b9a7_1280x800_1_card.png, zqa_b9a7_1280x800_the_220_card.png, zqa_b9a7_1280x800_2_equip_card.png, zqa_b9a7_1280x800_the_Equip_card.png

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a7 screen 1280x800, text size nil
ZEDQA b9a7 start
[ZeD.QA] run #9 ok=true
ZEDQA b9a7 PASS the Base.BaseballBat row is on screen
ZEDQA b9a7 PASS a click on the row opens its card (Base.BaseballBat)
ZEDQA b9a7 shot 1_card
ZEDQA b9a7 PASS the 220 card: the card has a scrollbar (165 wide)
ZEDQA b9a7 the 220 card: width 165, band 0, scroll 182 of 182.609375
ZEDQA b9a7 PASS the 220 card: the scroll reaches the end of the body (182 of 182.609375)
ZEDQA b9a7 the 220 card: (this card has no care verbs' band: the end is the card's foot)
ZEDQA b9a7 PASS the 220 card: the last "Used to make" row clears the band (288.609375 <= 298)
ZEDQA b9a7 shot the_220_card
ZEDQA b9a7 PASS a worn thing's slot on the Equip tab
ZEDQA b9a7 PASS the Equip tab's card opens (doll:torso, 360 wide)
ZEDQA b9a7 shot 2_equip_card
ZEDQA b9a7 PASS the Equip card: the card has a scrollbar (360 wide)
ZEDQA b9a7 the Equip card: width 360, band 28, scroll 448 of 448.625
ZEDQA b9a7 PASS the Equip card: the scroll reaches the end of the body (448 of 448.625)
ZEDQA b9a7 PASS the Equip card: the last "Used to make" row clears the band (202.640625 <= 244)
ZEDQA b9a7 shot the_Equip_card
ZEDQA b9a7 RESULT 10 pass, 0 fail
ZEDQA b9a7 DONE
```

### 10. zedqa_b9a_8.lua (`ZEDQA b9a8`) - WARN, 15 s

- go 10009 at 09:35:42
- 2 ERR line(s)
- screenshots: zqa_b9a8_1280x800_1_pin.png, zqa_b9a8_1280x800_2_unpin.png

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a8 screen 1280x800
ZEDQA b9a8 start
[ZeD.QA] run #10 ok=true
ZEDQA b9a8 the bottle's pin kind: fluid
ZEDQA b9a8 PASS the bottle's row is on screen, under its point
ZEDQA b9a8 unpinned option: Debug | icon bug
ZEDQA b9a8 unpinned option: Wear | icon shirt
ZEDQA b9a8 unpinned option: Inspect | icon magnifier
ZEDQA b9a8 unpinned option: Drop | icon to_floor
ZEDQA b9a8 unpinned option: Place Item | icon box_down
ZEDQA b9a8 unpinned option: More | icon more
ZEDQA b9a8 unpinned option: Save to outfit | icon texture
ZEDQA b9a8 unpinned option: Save to loadout | icon texture
ZEDQA b9a8 unpinned option: Move to | icon tray_out
ZEDQA b9a8 unpinned option: Rename | icon pencil
ZEDQA b9a8 FAIL unpinned: the menu has "Pin to title bar"
ZEDQA b9a8 shot 1_pin
ZEDQA b9a8 pinned option: Debug | icon bug
ZEDQA b9a8 pinned option: Wear | icon shirt
ZEDQA b9a8 pinned option: Inspect | icon magnifier
ZEDQA b9a8 pinned option: Drop | icon to_floor
ZEDQA b9a8 pinned option: Place Item | icon box_down
ZEDQA b9a8 pinned option: More | icon more
ZEDQA b9a8 pinned option: Save to outfit | icon texture
ZEDQA b9a8 pinned option: Save to loadout | icon texture
ZEDQA b9a8 pinned option: Move to | icon tray_out
ZEDQA b9a8 pinned option: Rename | icon pencil
ZEDQA b9a8 FAIL pinned: the menu has "Unpin from title bar"
ZEDQA b9a8 shot 2_unpin
ZEDQA b9a8 RESULT 1 pass, 2 fail
ZEDQA b9a8 DONE
```

### 11. zedqa_b9a_9.lua (`ZEDQA b9a9`) - PASS, 38 s

- go 10010 at 09:36:01
- screenshots: zqa_b9a9_1280x800_char_1_bar.png, zqa_b9a9_1280x800_char_2_rolled.png, zqa_b9a9_1280x800_char_3_tab_folds.png, zqa_b9a9_1280x800_world_1_bar.png, zqa_b9a9_1280x800_world_2_rolled.png, zqa_b9a9_1280x800_world_3_tab_folds.png

```text
[ZeD.QA] state #11 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a9 screen 1280x800
ZEDQA b9a9 start
[ZeD.QA] run #11 ok=true
ZEDQA b9a9 PASS char: (staged) on health with the inventory beside the drawer (a roll box would show)
ZEDQA b9a9 PASS char: no roll box after the title
ZEDQA b9a9 PASS char: the title keeps no room for one
ZEDQA b9a9 PASS char: the controller's ring has no roll box stop
ZEDQA b9a9 shot char_1_bar
ZEDQA b9a9 PASS char: a real click where the box was rolls nothing
ZEDQA b9a9 PASS char: the pointer off the inventory: the unpinned inventory rolls, the pinned drawer stays
ZEDQA b9a9 shot char_2_rolled
ZEDQA b9a9 PASS char: resting on its rod brings it down (no roll by hand to keep it up)
ZEDQA b9a9 PASS char: a click on the open tab still folds the drawer by hand
ZEDQA b9a9 shot char_3_tab_folds
ZEDQA b9a9 PASS world: (staged) on maps with the inventory beside the drawer (a roll box would show)
ZEDQA b9a9 PASS world: no roll box after the title
ZEDQA b9a9 PASS world: the title keeps no room for one
ZEDQA b9a9 PASS world: the controller's ring has no roll box stop
ZEDQA b9a9 shot world_1_bar
ZEDQA b9a9 PASS world: a real click where the box was rolls nothing
ZEDQA b9a9 PASS world: the pointer off the inventory: the unpinned inventory rolls, the pinned drawer stays
ZEDQA b9a9 shot world_2_rolled
ZEDQA b9a9 PASS world: resting on its rod brings it down (no roll by hand to keep it up)
ZEDQA b9a9 PASS world: a click on the open tab still folds the drawer by hand
ZEDQA b9a9 shot world_3_tab_folds
ZEDQA b9a9 RESULT 16 pass, 0 fail
ZEDQA b9a9 DONE
```

### 12. zedqa_dual_pin.lua (`ZEDQA dpn`) - WARN, 34 s

- go 10011 at 09:36:42
- 1 ERR line(s)
- screenshots: zqa_dpn_1280x800_1_pins.png, zqa_dpn_1280x800_2_maps_pinned.png, zqa_dpn_1280x800_4_containers_down.png, zqa_dpn_1280x800_5_char_drawer_down.png, zqa_dpn_1280x800_5_char_drawer_pinned.png, zqa_dpn_1280x800_6_aim.png, zqa_dpn_1280x800_7_rod_pin.png, zqa_dpn_1280x800_2_6b_inventory_part.png, zqa_dpn_1280x800_2_6b_drawer_part.png, zqa_dpn_1280x800_9_pad_down.png

```text
[ZeD.QA] state #12 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA dpn start
[ZeD.QA] run #12 ok=true
ZEDQA dpn PASS both windows have halves (WindowHalves)
ZEDQA dpn PASS pins saved per half
ZEDQA dpn PASS Character on Health, World on Maps
ZEDQA dpn Character pins: drawer (left) 26,5 10x10, inventory (right) 604,5 10x10, window box 622,5 10x10
ZEDQA dpn World pins: containers (left) 26,5 10x10, drawer (right) 604,5 10x10, window box 622,5 10x10
ZEDQA dpn PASS Character: one pin at each end of the bar, the right one before the window box
ZEDQA dpn shot 1_pins
ZEDQA dpn PASS away 3 s: the Character window rolled to its title bar
ZEDQA dpn PASS away 3 s: the World containers rolled under their rod
ZEDQA dpn PASS away 3 s: the map still open (pinned)
ZEDQA dpn shot 2_maps_pinned
ZEDQA dpn PASS 2.2a: the Character window is rolled before the sweep
ZEDQA dpn PASS 2.2a: a 0.12 s pass over the rolled title bar leaves it rolled
ZEDQA dpn PASS pointer on the map 3 s: map open, the containers still rolled
ZEDQA dpn PASS pointer on the containers' rod: they come down, the map open
ZEDQA dpn shot 4_containers_down
ZEDQA dpn PASS the drawer's part of the Character bar: the window down, the drawer open
ZEDQA dpn PASS ... the inventory still rolled under its rod
ZEDQA dpn shot 5_char_drawer_down
ZEDQA dpn PASS a real click on the Character's left pin pins its drawer
ZEDQA dpn PASS away 3 s: the pinned drawer stays, the inventory rolled
ZEDQA dpn shot 5_char_drawer_pinned
ZEDQA dpn PASS aiming: the Character's pinned drawer stays open
ZEDQA dpn PASS aiming: the World's pinned map stays open
ZEDQA dpn PASS aiming: both inventory sides rolled
ZEDQA dpn shot 6_aim
ZEDQA dpn Character rod pin 235,5 10x10
ZEDQA dpn PASS a real click on the pin on the Character's rod pins the inventory
ZEDQA dpn PASS ... and the pinned inventory comes down
ZEDQA dpn shot 7_rod_pin
ZEDQA dpn PASS a real click on the open tab still folds the drawer (pinned or not)
ZEDQA dpn PASS ... by hand: not the half's fold
ZEDQA dpn PASS 2.2b: the Character window rolled for the drag test
ZEDQA dpn PASS 2.2b: an item held over the rolled title bar brings the window down within 0.25 s
ZEDQA dpn PASS 2.2c: (staged) drawer pinned, the inventory rolled under its rod
ZEDQA dpn FAIL 2.2c: an item held over the rod brings the inventory down within 0.25 s, the drawer pinned
ZEDQA dpn PASS 2.2c: ... the pinned drawer still open
ZEDQA dpn PASS 2.6b: the inventory's part of the rolled bar: only the inventory comes back, the drawer still rolled in
ZEDQA dpn PASS 2.6b: ... the window still on Health (not Loot)
ZEDQA dpn shot 2_6b_inventory_part
ZEDQA dpn PASS 2.6b: the drawer's part: only the drawer comes back, the inventory under its rod
ZEDQA dpn shot 2_6b_drawer_part
ZEDQA dpn PASS Health open again
ZEDQA dpn pad stops: 2 halfpin:drawer, halfpin:inv
ZEDQA dpn PASS pad: the two pins are the bar's stops, left to right
ZEDQA dpn PASS pad: A on the inventory's pin toggles it
ZEDQA dpn PASS pad aim: the Character drawer (pinned) stays, its inventory rolls
ZEDQA dpn PASS pad aim: the World map (pinned) stays
ZEDQA dpn PASS Y / a bumper (showWin): both windows fully down
ZEDQA dpn shot 9_pad_down
ZEDQA dpn RESULT 35 pass, 1 fail
ZEDQA dpn DONE
```

### 13. zedqa_doll_v4.lua (`ZEDQA dollv4`) - PASS, 23 s

- go 10012 at 09:37:19
- screenshots: zqa_dollv4_1280x800_wide.png, zqa_dollv4_1280x800_dpad.png, zqa_dollv4_1280x800_wide_pads.png, zqa_dollv4_1280x800_card.png, zqa_dollv4_1280x800_narrow.png, zqa_dollv4_1280x800_short.png

```text
[ZeD.QA] state #13 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA dollv4 start
[ZeD.QA] run #13 ok=true
ZEDQA dollv4 round 1: wearing 21 of 21
ZEDQA dollv4 PASS 38 small slots defined | 38
ZEDQA dollv4 PASS wide: bands show | drawer 360px = 480 units, screen 1280x800
ZEDQA dollv4 PASS wide: 49 slot boxes (11 big + 38 small) | 49
ZEDQA dollv4 PASS wide: no slot overlaps another
ZEDQA dollv4 PASS wide: every box inside the drawer's width | 360
ZEDQA dollv4 PASS wide: the drawer is no wider than the full card (480 units) | 480.0 units
ZEDQA dollv4 PASS wide: a small slot is 14 units or more on screen | 14.7 units
ZEDQA dollv4 PASS wide: no leader lines | 0 lines
ZEDQA dollv4 PASS wide: Back at the top right above Belt, Arms on the left with Head | 251,36 115 251,166
ZEDQA dollv4 PASS every group name and place name has its words |
ZEDQA dollv4 PASS round 1 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS round 1 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 1 folded (data): every worn thing lands in its big slot (21 on) |
ZEDQA dollv4 PASS belly button ring, air tank, tail in their small slots
ZEDQA dollv4 empties 25, slots with things 26
ZEDQA dollv4 PASS charTabContent zone exists with the doll's stops | 78
ZEDQA dollv4 PASS Left from Neck steps into the left band | doll:padsport
ZEDQA dollv4 PASS Right from the band's inner edge returns to a big slot | doll:neck
ZEDQA dollv4 PASS Right from Belt steps into the right band | doll:fpfront
ZEDQA dollv4 PASS Left from the right band's inner edge returns to a big slot | doll:belt
ZEDQA dollv4 PASS the doll's moves reach all 38 small slots | 38 missed
ZEDQA dollv4 PASS and all 11 big slots (Up / Down in a column are the cone's) | 11 missed
ZEDQA dollv4 PASS the outer edge of each band row leaves the doll (18 rows)
ZEDQA dollv4 dispatch Right from belt -> equipslot:doll:fpfront
ZEDQA dollv4 then Down -> equipslot:doll:ammo
ZEDQA dollv4 dispatch Left from the left band's outer edge -> tab:equip
ZEDQA dollv4 PASS the real Left at the outer edge does not land on another doll slot | tab:equip
ZEDQA dollv4 round 2: wearing 1 of 1
ZEDQA dollv4 PASS round 2 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS the sport pads worn on top show in their small slot
ZEDQA dollv4 PASS the air tank is gone from its slot
ZEDQA dollv4 PASS a second layer shows as a count (2) | 2
ZEDQA dollv4 PASS pad stop for the filled small slot
ZEDQA dollv4 PASS A opens the small slot's card (outermost first) | doll:padsport item Shoulderpads_FootballOnTop layer 1/2
ZEDQA dollv4 PASS its outermost layer is the pair worn on top | Shoulderpads_FootballOnTop
ZEDQA dollv4 PASS Inner steps to layer 2 | 2
ZEDQA dollv4 round 3: wearing 1 of 1
ZEDQA dollv4 PASS round 3 wide: every worn thing lands in its small slot (20 on) |
ZEDQA dollv4 PASS round 3 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 3 folded (data): every worn thing lands in its big slot (20 on) |
ZEDQA dollv4 round 4: wearing 2 of 2
ZEDQA dollv4 PASS round 4 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS round 4 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 4 folded (data): every worn thing lands in its big slot (21 on) |
ZEDQA dollv4 round 5: wearing 1 of 1
ZEDQA dollv4 PASS round 5 wide: every worn thing lands in its small slot (20 on) |
ZEDQA dollv4 PASS round 5 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 5 folded (data): every worn thing lands in its big slot (20 on) |
ZEDQA dollv4 PASS a cap dropped on Head is taken | rect 69,28 27x27 clip 0,28 349x250 | loc base:hat
ZEDQA dollv4 PASS a cap dropped on a small slot that is not its place is refused
ZEDQA dollv4 PASS a ring dropped on the wrong small slot is refused
ZEDQA dollv4 PASS a ring dropped on its slot is taken | rect 1,245 11x11 clip 0,28 349x250
ZEDQA dollv4 PASS the ring was put on (vanilla's wear action ran)
ZEDQA dollv4 PASS the cap was put on
ZEDQA dollv4 PASS narrow: bands folded | drawer 165px = 220 units, screen 1280x800
ZEDQA dollv4 PASS narrow: 11 big slot boxes, no small ones | 11
ZEDQA dollv4 PASS narrow: no slot overlaps another
ZEDQA dollv4 PASS narrow: every box inside the drawer's width | 165
ZEDQA dollv4 PASS narrow: the drawer is no wider than the full card (480 units) | 220.0 units
ZEDQA dollv4 PASS narrow: no leader lines | 0 lines
ZEDQA dollv4 PASS narrow: Back, Arms, Belt in that order down the right | 29,107,146
ZEDQA dollv4 PASS narrow: every worn thing lands in its big slot (20 on) |
ZEDQA dollv4 PASS narrow: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS narrow: no small-slot zone left | 0
ZEDQA dollv4 narrow: Arms layers 3, Back 2, Legs 5, Belt 4, Hands 4
ZEDQA dollv4 PASS narrow: Back's card shows the folded layers (tail, satchel) | layers 2
ZEDQA dollv4 short: window 315 -> 483 px (view 250, doll at full size 523)
ZEDQA dollv4 PASS short: the bands still show
ZEDQA dollv4 PASS short: the small slots shrank (under 18 units, 14 or more) | 16.0 units
ZEDQA dollv4 PASS short: the doll fits its view, no scrolling to reach it | 418 in 418
ZEDQA dollv4 PASS short: no slot overlaps another
ZEDQA dollv4 PASS short: 49 slot boxes | 49
ZEDQA dollv4 passed 62, failed 0 | DONE
```

### 14. zedqa_curtain.lua (`ZEDQA cu`) - WARN, 155 s

- go 10013 at 09:37:45
- 1 ERR line(s)
- screenshots: zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png

```text
[ZeD.QA] state #14 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cu start
[ZeD.QA] run #14 ok=true
ZEDQA cu loaded: Character 303,0 333x315 rolled false (saved -) | World 644,0 333x315 rolled false (saved -)
ZEDQA cu scale 0.75 root 0.75 screen 1280x800
ZEDQA cu reset: ZeD_Window.resetLayout
ZEDQA cu reset: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 644,0 333x315 rolled false (saved 864.000,0.000 444.000x420.000 tab maps drawer false)
ZEDQA cu before: x 640 w 640 title Ground + Maps button nil
ZEDQA cu rolled true: x 893 w 387 (sum 1280 was 1280) rod 640,0 253x20 content false title Maps
ZEDQA cu pad stops: worldContainerStrip:curtain:unroll
ZEDQA cu A on the tab
ZEDQA cu unrolled true: x 640 w 640 content true rod false
ZEDQA cu ok first roll World 640,0 640x315
ZEDQA cu rolled again true
ZEDQA cu tab closed: rolled false x 648 w 333 content true drawer false
ZEDQA cu FAIL tab closed while rolled World: got 648,0 333x315 want 644,0 333x315 (dx 4 dy 0 dw 0 dh 0)
ZEDQA cu World before: 640,0 640x315 (other 303,0 333x315) drawer true tab tab maps
ZEDQA cu cycle1 World before roll: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,0 640x315 rolled false (saved 864.000,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World rolled: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,0 387x315 rolled true (saved 864.000,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World rollW 253
ZEDQA cu ok cycle1 rolled World rod flush at 640,0 253x20
ZEDQA cu ok cycle1 rolled World 893,0 387x315
ZEDQA cu ok cycle1 while rolled: other Character 303,0 333x315
ZEDQA cu cycle1 World rolled, before unroll: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,0 387x315 rolled true (saved 864.000,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World unrolled: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,0 640x315 rolled false (saved 864.000,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle1 World 640,0 640x315
ZEDQA cu ok cycle1 other (Character) 303,0 333x315
ZEDQA cu ok cycle1 World saved 864.000,0.000 444.000x420.000
ZEDQA cu cycle2 World before roll: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,0 640x315 rolled false (saved 864.000,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World rolled: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,0 387x315 rolled true (saved 864.000,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World rollW 253
ZEDQA cu ok cycle2 rolled World rod flush at 640,0 253x20
ZEDQA cu ok cycle2 rolled World 893,0 387x315
ZEDQA cu ok cycle2 while rolled: other Character 303,0 333x315
ZEDQA cu cycle2 World rolled, before unroll: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,0 387x315 rolled true (saved 864.000,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World unrolled: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,0 640x315 rolled false (saved 864.000,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle2 World 640,0 640x315
ZEDQA cu ok cycle2 other (Character) 303,0 333x315
ZEDQA cu ok cycle2 World saved 864.000,0.000 444.000x420.000
ZEDQA cu moved by rod World before roll: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,0 640x315 rolled false (saved 864.000,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World rolled: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,0 387x315 rolled true (saved 864.000,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World rollW 253
ZEDQA cu ok moved by rod rolled World rod flush at 640,0 253x20
ZEDQA cu ok moved by rod rolled World 893,0 387x315
ZEDQA cu ok moved by rod while rolled: other Character 303,0 333x315
ZEDQA cu moved by rod World moved by -200,200 (rod) to 693,200 387x315
ZEDQA cu ok moved by rod moved World rod flush at 440,200 253x20
ZEDQA cu moved by rod World rolled, before unroll: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 693,200 387x315 rolled true (saved 597.333,266.667 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World unrolled: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 440,200 640x315 rolled false (saved 597.333,266.667 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by rod World 440,200 640x315
ZEDQA cu ok moved by rod other (Character) 303,0 333x315
ZEDQA cu ok moved by rod World saved 597.333,266.667 444.000x420.000
ZEDQA cu moved by title World before roll: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 440,200 640x315 rolled false (saved 597.333,266.667 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World rolled: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 693,200 387x315 rolled true (saved 597.333,266.667 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World rollW 253
ZEDQA cu ok moved by title rolled World rod flush at 440,200 253x20
ZEDQA cu ok moved by title rolled World 693,200 387x315
ZEDQA cu ok moved by title while rolled: other Character 303,0 333x315
ZEDQA cu moved by title World moved by 200,200 (title) to 893,400 387x315
ZEDQA cu ok moved by title moved World rod flush at 640,400 253x20
ZEDQA cu moved by title World rolled, before unroll: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,400 387x315 rolled true (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World unrolled: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by title World 640,400 640x315
ZEDQA cu ok moved by title other (Character) 303,0 333x315
ZEDQA cu ok moved by title World saved 864.000,533.333 444.000x420.000
ZEDQA cu cycle5 World before roll: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World rolled: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,400 387x315 rolled true (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World rollW 253
ZEDQA cu ok cycle5 rolled World rod flush at 640,400 253x20
ZEDQA cu ok cycle5 rolled World 893,400 387x315
ZEDQA cu ok cycle5 while rolled: other Character 303,0 333x315
ZEDQA cu cycle5 World rolled, before unroll: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,400 387x315 rolled true (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World unrolled: Character 303,0 333x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle5 World 640,400 640x315
ZEDQA cu ok cycle5 other (Character) 303,0 333x315
ZEDQA cu ok cycle5 World saved 864.000,533.333 444.000x420.000
ZEDQA cu character health tab true
ZEDQA cu Character before: 0,0 640x315 (other 640,400 640x315) drawer true tab tab health
ZEDQA cu cycle1 Character before roll: Character 0,0 640x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character rolled: Character 0,0 387x315 rolled true (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character rollW 253
ZEDQA cu ok cycle1 rolled Character rod flush at 387,0 253x20
ZEDQA cu ok cycle1 rolled Character 0,0 387x315
ZEDQA cu ok cycle1 while rolled: other World 640,400 640x315
ZEDQA cu cycle1 Character rolled, before unroll: Character 0,0 387x315 rolled true (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character unrolled: Character 0,0 640x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle1 Character 0,0 640x315
ZEDQA cu ok cycle1 other (World) 640,400 640x315
ZEDQA cu ok cycle1 Character saved 404.000,0.000 444.000x420.000
ZEDQA cu cycle2 Character before roll: Character 0,0 640x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character rolled: Character 0,0 387x315 rolled true (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character rollW 253
ZEDQA cu ok cycle2 rolled Character rod flush at 387,0 253x20
ZEDQA cu ok cycle2 rolled Character 0,0 387x315
ZEDQA cu ok cycle2 while rolled: other World 640,400 640x315
ZEDQA cu cycle2 Character rolled, before unroll: Character 0,0 387x315 rolled true (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character unrolled: Character 0,0 640x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle2 Character 0,0 640x315
ZEDQA cu ok cycle2 other (World) 640,400 640x315
ZEDQA cu ok cycle2 Character saved 404.000,0.000 444.000x420.000
ZEDQA cu moved by rod Character before roll: Character 0,0 640x315 rolled false (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character rolled: Character 0,0 387x315 rolled true (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character rollW 253
ZEDQA cu ok moved by rod rolled Character rod flush at 387,0 253x20
ZEDQA cu ok moved by rod rolled Character 0,0 387x315
ZEDQA cu ok moved by rod while rolled: other World 640,400 640x315
ZEDQA cu moved by rod Character moved by 200,200 (rod) to 200,200 387x315
ZEDQA cu ok moved by rod moved Character rod flush at 587,200 253x20
ZEDQA cu moved by rod Character rolled, before unroll: Character 200,200 387x315 rolled true (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character unrolled: Character 200,200 640x315 rolled false (saved 670.667,266.667 444.000x420.000 anchor 1114.667 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by rod Character 200,200 640x315
ZEDQA cu ok moved by rod other (World) 640,400 640x315
ZEDQA cu ok moved by rod Character saved 670.667,266.667 444.000x420.000
ZEDQA cu moved by title Character before roll: Character 200,200 640x315 rolled false (saved 670.667,266.667 444.000x420.000 anchor 1114.667 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character rolled: Character 200,200 387x315 rolled true (saved 670.667,266.667 444.000x420.000 anchor 1114.667 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character rollW 253
ZEDQA cu ok moved by title rolled Character rod flush at 587,200 253x20
ZEDQA cu ok moved by title rolled Character 200,200 387x315
ZEDQA cu ok moved by title while rolled: other World 640,400 640x315
ZEDQA cu moved by title Character moved by 200,200 (title) to 400,400 387x315
ZEDQA cu ok moved by title moved Character rod flush at 787,400 253x20
ZEDQA cu moved by title Character rolled, before unroll: Character 400,400 387x315 rolled true (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character unrolled: Character 400,400 640x315 rolled false (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by title Character 400,400 640x315
ZEDQA cu ok moved by title other (World) 640,400 640x315
ZEDQA cu ok moved by title Character saved 937.333,533.333 444.000x420.000
ZEDQA cu cycle5 Character before roll: Character 400,400 640x315 rolled false (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character rolled: Character 400,400 387x315 rolled true (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character rollW 253
ZEDQA cu ok cycle5 rolled Character rod flush at 787,400 253x20
ZEDQA cu ok cycle5 rolled Character 400,400 387x315
ZEDQA cu ok cycle5 while rolled: other World 640,400 640x315
ZEDQA cu cycle5 Character rolled, before unroll: Character 400,400 387x315 rolled true (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character unrolled: Character 400,400 640x315 rolled false (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle5 Character 400,400 640x315
ZEDQA cu ok cycle5 other (World) 640,400 640x315
ZEDQA cu ok cycle5 Character saved 937.333,533.333 444.000x420.000
ZEDQA cu closed rolled (inventory key) World reference, closed and reopened unrolled: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) reference back on its tab World 640,400 640x315
ZEDQA cu closed rolled (inventory key) World before roll: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 640,400 640x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (inventory key) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (inventory key) World window closed
ZEDQA cu ok closed rolled (inventory key) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (inventory key) World reopened: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (inventory key) reopened as unrolled World 648,400 333x315
ZEDQA cu ok closed rolled (inventory key) reopened: other Character 396,400 640x315
ZEDQA cu closed rolled (rod close box) World reference, closed and reopened unrolled: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (rod close box) reference back on its tab World 640,400 640x315
ZEDQA cu closed rolled (rod close box) World before roll: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 640,400 640x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (rod close box) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (rod close box) World window closed
ZEDQA cu ok closed rolled (rod close box) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (rod close box) World reopened: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (rod close box) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (rod close box) reopened as unrolled World 648,400 333x315
ZEDQA cu ok closed rolled (rod close box) reopened: other Character 396,400 640x315
ZEDQA cu closed rolled (controller Y hold) World reference, closed and reopened unrolled: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab World 640,400 640x315
ZEDQA cu closed rolled (controller Y hold) World before roll: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 640,400 640x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (controller Y hold) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (controller Y hold) World window closed
ZEDQA cu ok closed rolled (controller Y hold) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (controller Y hold) World reopened: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled World 648,400 333x315
ZEDQA cu ok closed rolled (controller Y hold) reopened: other Character 396,400 640x315
ZEDQA cu closed rolled (inventory key) Character reference, closed and reopened unrolled: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) reference back on its tab Character 396,400 640x315
ZEDQA cu closed rolled (inventory key) Character before roll: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (inventory key) Character window closed
ZEDQA cu ok closed rolled (inventory key) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (inventory key) Character reopened: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (inventory key) reopened as unrolled Character 396,400 640x315
ZEDQA cu ok closed rolled (inventory key) reopened: other World 648,400 333x315
ZEDQA cu closed rolled (close box) Character reference, closed and reopened unrolled: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) reference back on its tab Character 396,400 640x315
ZEDQA cu closed rolled (close box) Character before roll: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (close box) Character window closed
ZEDQA cu ok closed rolled (close box) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (close box) Character reopened: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (close box) reopened as unrolled Character 396,400 640x315
ZEDQA cu ok closed rolled (close box) reopened: other World 648,400 333x315
ZEDQA cu closed rolled (controller Y hold) Character reference, closed and reopened unrolled: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab Character 396,400 640x315
ZEDQA cu closed rolled (controller Y hold) Character before roll: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (controller Y hold) Character window closed
ZEDQA cu ok closed rolled (controller Y hold) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (controller Y hold) Character reopened: Character 396,400 640x315 rolled nil (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 648,400 333x315 rolled nil (saved 864.000,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled Character 396,400 640x315
ZEDQA cu ok closed rolled (controller Y hold) reopened: other World 648,400 333x315
ZEDQA cu World tabs: on maps 640,400 640x315 (other 396,400 640x315)
ZEDQA cu ok tab forage reference, back on maps World 640,400 640x315
ZEDQA cu ok tab forage World rolled before the press
ZEDQA cu ok tab forage World still rolled on the tab (tab forage)
ZEDQA cu ok tab forage rolled World 893,400 387x315
ZEDQA cu ok tab forage World unrolled (rods in UI 0)
ZEDQA cu ok tab forage unrolled World 640,400 640x315
ZEDQA cu ok tab forage unrolled: other Character 396,400 640x315
ZEDQA cu ok tab forage back on maps World 640,400 640x315
ZEDQA cu ok tab craft reference, back on maps World 640,400 640x315
ZEDQA cu ok tab craft World rolled before the press
ZEDQA cu ok tab craft World still rolled on the tab (tab craft)
ZEDQA cu ok tab craft rolled World 893,400 387x315
ZEDQA cu ok tab craft World unrolled (rods in UI 0)
ZEDQA cu ok tab craft unrolled World 640,400 640x315
ZEDQA cu ok tab craft unrolled: other Character 396,400 640x315
ZEDQA cu ok tab craft back on maps World 640,400 640x315
ZEDQA cu ok tab build reference, back on maps World 640,400 640x315
ZEDQA cu ok tab build World rolled before the press
ZEDQA cu ok tab build World still rolled on the tab (tab build)
ZEDQA cu ok tab build rolled World 893,400 387x315
ZEDQA cu ok tab build World unrolled (rods in UI 0)
ZEDQA cu ok tab build unrolled World 640,400 640x315
ZEDQA cu ok tab build unrolled: other Character 396,400 640x315
ZEDQA cu ok tab build back on maps World 640,400 640x315
ZEDQA cu ok tab furniture reference, back on maps World 640,400 640x315
ZEDQA cu ok tab furniture World rolled before the press
ZEDQA cu ok tab furniture World still rolled on the tab (tab furniture)
ZEDQA cu ok tab furniture rolled World 893,400 387x315
ZEDQA cu ok tab furniture World unrolled (rods in UI 0)
ZEDQA cu ok tab furniture unrolled World 640,400 640x315
ZEDQA cu ok tab furniture unrolled: other Character 396,400 640x315
ZEDQA cu ok tab furniture back on maps World 640,400 640x315
ZEDQA cu ok tab animals reference, back on maps World 640,400 640x315
ZEDQA cu ok tab animals World rolled before the press
ZEDQA cu ok tab animals World still rolled on the tab (tab animals)
ZEDQA cu ok tab animals rolled World 893,400 387x315
ZEDQA cu ok tab animals World unrolled (rods in UI 0)
ZEDQA cu ok tab animals unrolled World 640,400 640x315
ZEDQA cu ok tab animals unrolled: other Character 396,400 640x315
ZEDQA cu ok tab animals back on maps World 640,400 640x315
ZEDQA cu tab radio World: not shown here, skipped
ZEDQA cu tab vehicle World: not shown here, skipped
ZEDQA cu ok forage and back World still rolled (tab maps)
ZEDQA cu ok forage and back rolled World 893,400 387x315
ZEDQA cu ok forage and back, unrolled World 640,400 640x315
ZEDQA cu World Loot (unrolled) 648,400 333x315
ZEDQA cu ok Loot reference, back on maps World 640,400 640x315
ZEDQA cu ok Loot World rolled before the press
ZEDQA cu ok Loot World side down with the press (rolled false tab loot rods in UI 0)
ZEDQA cu ok Loot while rolled World 648,400 333x315
ZEDQA cu ok Loot while rolled: other Character 396,400 640x315
ZEDQA cu ok Loot while rolled, back on maps World 640,400 640x315
ZEDQA cu ok maps again World rolled before the press
ZEDQA cu ok maps again World side down (rolled false)
ZEDQA cu ok maps pressed again while rolled World 648,400 333x315
ZEDQA cu ok maps again, back on maps World 640,400 640x315
ZEDQA cu Character tabs: on health 396,400 640x315 (other 640,400 640x315)
ZEDQA cu ok tab skills reference, back on health Character 396,400 640x315
ZEDQA cu ok tab skills Character rolled before the press
ZEDQA cu ok tab skills Character still rolled on the tab (tab skills)
ZEDQA cu ok tab skills rolled Character 396,400 387x315
ZEDQA cu ok tab skills Character unrolled (rods in UI 0)
ZEDQA cu ok tab skills unrolled Character 396,400 640x315
ZEDQA cu ok tab skills unrolled: other World 640,400 640x315
ZEDQA cu ok tab skills back on health Character 396,400 640x315
ZEDQA cu ok tab equip reference, back on health Character 396,400 640x315
ZEDQA cu ok tab equip Character rolled before the press
ZEDQA cu ok tab equip Character still rolled on the tab (tab equip)
ZEDQA cu ok tab equip rolled Character 396,400 387x315
ZEDQA cu ok tab equip Character unrolled (rods in UI 0)
ZEDQA cu ok tab equip unrolled Character 396,400 640x315
ZEDQA cu ok tab equip unrolled: other World 640,400 640x315
ZEDQA cu ok tab equip back on health Character 396,400 640x315
ZEDQA cu ok tab thermal reference, back on health Character 396,400 640x315
ZEDQA cu ok tab thermal Character rolled before the press
ZEDQA cu ok tab thermal Character still rolled on the tab (tab thermal)
ZEDQA cu ok tab thermal rolled Character 396,400 387x315
ZEDQA cu ok tab thermal Character unrolled (rods in UI 0)
ZEDQA cu ok tab thermal unrolled Character 396,400 640x315
ZEDQA cu ok tab thermal unrolled: other World 640,400 640x315
ZEDQA cu ok tab thermal back on health Character 396,400 640x315
ZEDQA cu ok tab identity reference, back on health Character 396,400 640x315
ZEDQA cu ok tab identity Character rolled before the press
ZEDQA cu ok tab identity Character still rolled on the tab (tab identity)
ZEDQA cu ok tab identity rolled Character 396,400 387x315
ZEDQA cu ok tab identity Character unrolled (rods in UI 0)
ZEDQA cu ok tab identity unrolled Character 396,400 640x315
ZEDQA cu ok tab identity unrolled: other World 640,400 640x315
ZEDQA cu ok tab identity back on health Character 396,400 640x315
ZEDQA cu ok tab journal reference, back on health Character 396,400 640x315
ZEDQA cu ok tab journal Character rolled before the press
ZEDQA cu ok tab journal Character still rolled on the tab (tab journal)
ZEDQA cu ok tab journal rolled Character 396,400 387x315
ZEDQA cu ok tab journal Character unrolled (rods in UI 0)
ZEDQA cu ok tab journal unrolled Character 396,400 640x315
ZEDQA cu ok tab journal unrolled: other World 640,400 640x315
ZEDQA cu ok tab journal back on health Character 396,400 640x315
ZEDQA cu tab radio Character: not shown here, skipped
ZEDQA cu ok skills and back Character still rolled (tab health)
ZEDQA cu ok skills and back rolled Character 396,400 387x315
ZEDQA cu ok skills and back, unrolled Character 396,400 640x315
ZEDQA cu Character Loot (unrolled) 703,400 333x315
ZEDQA cu ok Loot reference, back on health Character 396,400 640x315
ZEDQA cu ok Loot Character rolled before the press
ZEDQA cu ok Loot Character side down with the press (rolled false tab loot rods in UI 0)
ZEDQA cu ok Loot while rolled Character 703,400 333x315
ZEDQA cu ok Loot while rolled: other World 640,400 640x315
ZEDQA cu ok Loot while rolled, back on health Character 396,400 640x315
ZEDQA cu ok health again Character rolled before the press
ZEDQA cu ok health again Character side down (rolled false)
ZEDQA cu ok health pressed again while rolled Character 703,400 333x315
ZEDQA cu ok health again, back on health Character 396,400 640x315
ZEDQA cu geometry checks 214, differences 1
ZEDQA cu at quit, unrolled: Character 396,400 640x315 rolled false (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu at quit, rolled: Character 396,400 387x315 rolled true (saved 937.333,533.333 444.000x420.000 anchor 1381.333 tab health drawer true) | World 893,400 387x315 rolled true (saved 864.000,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu DONE
```

### 15. zedqa_segbars.lua (`ZEDQA segb`) - PASS, 1 s

- go 10014 at 09:40:23

```text
[ZeD.QA] state #15 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA segb 0.640 -> 6 lit, 4 dark
ZEDQA segb 0.040 -> 0 lit, 10 dark
ZEDQA segb 1.000 -> 10 lit, 0 dark
ZEDQA segb 0.000 -> 0 lit, 10 dark
ZEDQA segb 0.700 -> 7 lit, 3 dark
ZEDQA segb 0.300 -> 3 lit, 7 dark
ZEDQA segb 0.999 -> 9 lit, 1 dark
ZEDQA segb narrowest 21 px (scale 0.75): 10 cells, 1 to 1 px wide
ZEDQA segb skill help: Fitness 5, 40% to level 6 | Fitness 10
ZEDQA segb hover checks skipped: the controller's cues are showing
[ZeD.QA] run #15 ok=true
ZEDQA segb PASS
ZEDQA segb DONE
```

### 16. zedqa_world_pad_take.lua (`ZEDQA wpt`) - PASS, 63 s

- go 10015 at 09:40:27

```text
[ZeD.QA] state #16 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #16 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Ground | stops container:2@0, container:1@43
ZEDQA wpt PASS the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldMainInv:invrow:1 (Apple (Rotten))
ZEDQA wpt PASS RB lands in the World window on a lit element
ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
ZEDQA wpt 1 Right from the Character window's right edge: World worldMainInv:invrow:1 (Apple (Rotten))
ZEDQA wpt PASS the D-pad across from the Character window lands in the World window, lit
ZEDQA wpt 2 strip: World worldContainerStrip:container:2
ZEDQA wpt PASS on the strip, focus is on the container on show (the ground)
ZEDQA wpt 2 Down x1: World worldContainerStrip:container:1
ZEDQA wpt PASS Down from the ground reaches the crate (1 presses)
ZEDQA wpt 2 after A on the crate: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt PASS A on the crate puts focus on its first item, lit
ZEDQA wpt 2 Left: World worldContainerStrip:container:1
ZEDQA wpt PASS Left from the list lands on the crate (the container on show)
ZEDQA wpt 2 Right: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt PASS Right goes back to the same row
ZEDQA wpt 2 Left from a lower row: World worldContainerStrip:container:1
ZEDQA wpt PASS Left from a lower row lands on the crate too
ZEDQA wpt PASS and Right goes back to that row
ZEDQA wpt 3 timing: card buttons ready after 6 ticks, 5 frames; focus in the card after 6 ticks, 5 frames (watched 6 ticks, 5 frames)
ZEDQA wpt 3 A on the bandage: World worldItemCard:hverb_1
ZEDQA wpt PASS 3 A on the bandage: focus is on the card's primary action (TAKE)
ZEDQA wpt 3 Down in the card: World worldItemCard:name_row
ZEDQA wpt PASS Down moves to the card's next control
ZEDQA wpt 3 Up: World worldItemCard:hverb_1
ZEDQA wpt PASS Up from inside the card is back on the primary action in one press
ZEDQA wpt 3 after B: World worldMainInv:invrow:4 (Tweezers)
ZEDQA wpt PASS B closes the card and focus is back on the bandage row, lit
ZEDQA wpt 4 A on the nails: World worldItemCard:hverb_1
ZEDQA wpt PASS 4 A on the nails: focus is on the card's primary action (TAKE)
ZEDQA wpt PASS the nails' card offers Take as its primary action
ZEDQA wpt PASS A on Take moved the nails into the bag (vanilla's transfer, 10 ticks)
ZEDQA wpt 4 after the take: World worldMainInv:invrow:3 (Tweezers)
ZEDQA wpt 5 before the padlock card: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt 5 the padlock card: World worldItemCard:oc:verb:usecombo
ZEDQA wpt PASS the object card opens with focus on its main live verb (oc:verb:usecombo)
ZEDQA wpt PASS A on it ran the verb (the padlock's code wheel shows)
ZEDQA wpt 5 after B: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt PASS B closes the object card and focus is back in the list, lit
ZEDQA wpt 6 Left from the World window's strip: Char charContainerStrip:container:1
ZEDQA wpt PASS the D-pad across from the World window lands in the Character window, lit
ZEDQA wpt 6 LB: Char charContainerStrip:container:1
ZEDQA wpt PASS LB lands in the Character window on a lit element
ZEDQA wpt 6 Right: Char charContainerStrip:container:1
ZEDQA wpt PASS Right from a row lands on the bag on show
ZEDQA wpt PASS Left goes back to the same row
ZEDQA wpt 6 A on the nails: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on the nails: focus is on the card's primary action (DROP)
ZEDQA wpt PASS Down then Up in the Character window's card is back on its primary action
ZEDQA wpt 6 primary is DROP; A runs it
ZEDQA wpt PASS A on the card's primary action (Drop) moved the nails out of the bag (10 ticks)
ZEDQA wpt 6 A on a row: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on a row: focus is on the card's primary action (DROP)
ZEDQA wpt 6 after B: Char charMainInv:invrow:1 (Angel Cross's Key Ring)
ZEDQA wpt PASS B on the Character window's card goes back to the row
ZEDQA wpt PASS 8 X on a row opens the context menu
ZEDQA wpt 8 after the menu's B: World worldMainInv:invrow:2 (Corkscrew)
ZEDQA wpt PASS 8 the menu closed: focus is back on the same row, lit
ZEDQA wpt 8 after hold X: World worldMainInv:invrow:2 (Tweezers)
ZEDQA wpt PASS 8 hold X moved the thing out of the crate
ZEDQA wpt 8 a moment later: World worldMainInv:invrow:2 (Tweezers)
ZEDQA wpt PASS 8 after the transfer focus is on a neighbour in the same panel, lit
ZEDQA wpt PASS 8 a stray Left with a window open stays in the window (no way into the belt)
ZEDQA wpt PASS 8 with the windows put away, Left opens the Character wheel (not the belt)
ZEDQA wpt PASS 8 B leaves the belt in one press
ZEDQA wpt PASS 8 Right past the belt's last box leaves it
ZEDQA wpt PASS 8 Down (the screen's edge) leaves the belt
ZEDQA wpt 7 tabs: 12 at small and large
ZEDQA wpt PASS 7 Char equip small pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 276 of 278)
ZEDQA wpt PASS 7 Char equip small wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 266 of 278)
ZEDQA wpt PASS 7 Char health small pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 Char health small wheel: the lowest control health:exercise is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 Char health small Health: scrolled to the end, drawn 284 px in a 222 px view
ZEDQA wpt PASS 7 Char thermal small pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 Char thermal small wheel: the lowest control thermal:view is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 Char identity small pad: Down reaches the lowest control of its column identity:trait:Weak Stomach and it is in view (bottom 273 of 278)
ZEDQA wpt PASS 7 Char identity small wheel: the lowest control identity:trait:Weak Stomach is in view at the bottom (bottom 267 of 278)
ZEDQA wpt PASS 7 Char journal small pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 Char journal small wheel: the lowest control journal:__save is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 Char skills small pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 278 of 278)
ZEDQA wpt PASS 7 Char skills small wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 271 of 278)
ZEDQA wpt PASS 7 World craft small pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 World craft small wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 World build small pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 World build small wheel: the lowest control build:sortMenu is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 World furniture small pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 28 of 278)
ZEDQA wpt PASS 7 World furniture small wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 28 of 278)
ZEDQA wpt PASS 7 World maps small pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 World maps small wheel: the lowest control map:style:survey is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 World forage small pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 World forage small wheel: the lowest control forage:search is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 World animals small pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 World animals small wheel: the lowest control animals:createzone is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 268 of 273)
ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 260 of 273)
ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 Char health large wheel: the lowest control health:exercise is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 301 px in a 210 px view
ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:view is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control of its column identity:trait:Weak Stomach and it is in view (bottom 268 of 273)
ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:trait:Weak Stomach is in view at the bottom (bottom 261 of 273)
ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:__save is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 273 of 273)
ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 265 of 273)
ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 World build large wheel: the lowest control build:sortMenu is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 32 of 273)
ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 32 of 273)
ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:style:survey is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:search is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 World animals large pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:createzone is in view at the bottom (bottom 269 of 273)
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA wpt 89 passed, 0 failed
ZEDQA wpt DONE
```

### 17. zedqa_moodles.lua (`ZEDQA mood`) - FAIL, 23 s

- go 10016 at 09:41:34
- 3 Java exception(s) in the log
- 3 ERR line(s)
- screenshots: zqa_mood_right.png, zqa_mood_left.png, zqa_mood_bottom.png, zqa_mood_notices_off.png

```text
[ZeD.QA] state #17 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #17 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 4
ZEDQA mood box by itself: TIRED | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA mood right: 4 moodles on (TIRED 2, HUNGRY 2, PANIC 1, STRESS 2)
ZEDQA mood PASS right: the place is in effect
ZEDQA mood PASS right: at least three moodles are on
ZEDQA mood PASS right: the moodles are shown (layer)
ZEDQA mood right column at 1222,289 size 48, stack 222; visible true
ZEDQA mood PASS right: vanilla's column is visible
ZEDQA mood PASS right: every moodle is on screen
ZEDQA mood PASS right: the column is on the right edge (x 1222)
ZEDQA mood PASS right: ZeD's hover layer lies over the column
    Lua fail. Message: __concat not defined for operands: , and null
    se.krka.kahlua.vm.KahluaUtil.fail(KahluaUtil.java:96)
    Lua(Vanilla).balloon(worldmap-annotations.lua:124)
    Lua(Vanilla).tick(worldmap-annotations.lua:201)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:600)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.stdlib.BaseLib.pcall(BaseLib.java:313)
    se.krka.kahlua.stdlib.BaseLib.call(BaseLib.java:111)
    se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:178)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:795)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.vm.KahluaThread.pcallvoid(KahluaThread.java:1572)
    se.krka.kahlua.integration.LuaCaller.pcallvoid(LuaCaller.java:60)
    se.krka.kahlua.integration.LuaCaller.protectedCallVoid(LuaCaller.java:131)
    zombie.Lua.Event.trigger(Event.java:55)
    zombie.Lua.LuaEventManager.triggerEvent(LuaEventManager.java:248)
    zombie.ui.UIManager.render(UIManager.java:329)
    zombie.gameStates.IngameState.renderFrameUI(IngameState.java:1265)
    zombie.gameStates.IngameState.renderframeui(IngameState.java:1254)
    zombie.gameStates.IngameState.renderInternal(IngameState.java:1364)
    zombie.gameStates.IngameState.render(IngameState.java:1322)
    zombie.gameStates.GameStateMachine.render(GameStateMachine.java:24)
    zombie.GameWindow.renderInternal(GameWindow.java:459)
    zombie.GameWindow.frameStep(GameWindow.java:801)
    zombie.GameWindow.mainThreadStep(GameWindow.java:568)
    zombie.MainThread.mainLoop(MainThread.java:69)
    java.base/java.lang.Thread.run(Unknown Source)
ERROR: General f:73143> Lua(Vanilla).balloon> Exception thrown
    java.lang.RuntimeException: __concat not defined for operands: , and null at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).balloon(worldmap-annotations.lua:124)
    Lua(Vanilla).tick(worldmap-annotations.lua:201)
ZEDQA mood ERR step 8: __concat not defined for operands: , and null java.lang.RuntimeException
ZEDQA mood left: 4 moodles on (TIRED 2, HUNGRY 2, PANIC 2, STRESS 2)
ZEDQA mood PASS left: the place is in effect
ZEDQA mood PASS left: at least three moodles are on
ZEDQA mood PASS left: the moodles are shown (layer)
ZEDQA mood left column at 10,289 size 48, stack 222; visible true
ZEDQA mood PASS left: vanilla's column is visible
ZEDQA mood PASS left: every moodle is on screen
ZEDQA mood PASS left: the column is on the left edge (x 10)
ZEDQA mood PASS left: ZeD's hover layer lies over the column
    Lua fail. Message: __concat not defined for operands: , and null
    se.krka.kahlua.vm.KahluaUtil.fail(KahluaUtil.java:96)
    Lua(Vanilla).balloon(worldmap-annotations.lua:124)
    Lua(Vanilla).tick(worldmap-annotations.lua:201)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:600)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.stdlib.BaseLib.pcall(BaseLib.java:313)
    se.krka.kahlua.stdlib.BaseLib.call(BaseLib.java:111)
    se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:178)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:795)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.vm.KahluaThread.pcallvoid(KahluaThread.java:1572)
    se.krka.kahlua.integration.LuaCaller.pcallvoid(LuaCaller.java:60)
    se.krka.kahlua.integration.LuaCaller.protectedCallVoid(LuaCaller.java:131)
    zombie.Lua.Event.trigger(Event.java:55)
    zombie.Lua.LuaEventManager.triggerEvent(LuaEventManager.java:248)
    zombie.ui.UIManager.render(UIManager.java:329)
    zombie.gameStates.IngameState.renderFrameUI(IngameState.java:1265)
    zombie.gameStates.IngameState.renderframeui(IngameState.java:1254)
    zombie.gameStates.IngameState.renderInternal(IngameState.java:1364)
    zombie.gameStates.IngameState.render(IngameState.java:1322)
    zombie.gameStates.GameStateMachine.render(GameStateMachine.java:24)
    zombie.GameWindow.renderInternal(GameWindow.java:459)
    zombie.GameWindow.frameStep(GameWindow.java:801)
    zombie.GameWindow.mainThreadStep(GameWindow.java:568)
    zombie.MainThread.mainLoop(MainThread.java:69)
    java.base/java.lang.Thread.run(Unknown Source)
ERROR: General f:73366> Lua(Vanilla).balloon> Exception thrown
    java.lang.RuntimeException: __concat not defined for operands: , and null at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).balloon(worldmap-annotations.lua:124)
    Lua(Vanilla).tick(worldmap-annotations.lua:201)
ZEDQA mood ERR step 14: __concat not defined for operands: , and null java.lang.RuntimeException
ZEDQA mood bottom: 4 moodles on (TIRED 2, HUNGRY 2, PANIC 2, STRESS 2)
ZEDQA mood PASS bottom: the place is in effect
ZEDQA mood PASS bottom: at least three moodles are on
ZEDQA mood PASS bottom: the moodles are shown (layer)
ZEDQA mood bottom row at 529,689 222x48; vanilla's column y -10000
ZEDQA mood PASS bottom: the row is on screen
ZEDQA mood PASS bottom: the row is centred (middle 640 of 1280)
ZEDQA mood PASS bottom: the row sits above the belt
ZEDQA mood PASS bottom: one slot per moodle
ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
    Lua fail. Message: __concat not defined for operands: , and null
    se.krka.kahlua.vm.KahluaUtil.fail(KahluaUtil.java:96)
    Lua(Vanilla).balloon(worldmap-annotations.lua:124)
    Lua(Vanilla).tick(worldmap-annotations.lua:201)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:600)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.stdlib.BaseLib.pcall(BaseLib.java:313)
    se.krka.kahlua.stdlib.BaseLib.call(BaseLib.java:111)
    se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:178)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:795)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.vm.KahluaThread.pcallvoid(KahluaThread.java:1572)
    se.krka.kahlua.integration.LuaCaller.pcallvoid(LuaCaller.java:60)
    se.krka.kahlua.integration.LuaCaller.protectedCallVoid(LuaCaller.java:131)
    zombie.Lua.Event.trigger(Event.java:55)
    zombie.Lua.LuaEventManager.triggerEvent(LuaEventManager.java:248)
    zombie.ui.UIManager.render(UIManager.java:329)
    zombie.gameStates.IngameState.renderFrameUI(IngameState.java:1265)
    zombie.gameStates.IngameState.renderframeui(IngameState.java:1254)
    zombie.gameStates.IngameState.renderInternal(IngameState.java:1364)
    zombie.gameStates.IngameState.render(IngameState.java:1322)
    zombie.gameStates.GameStateMachine.render(GameStateMachine.java:24)
    zombie.GameWindow.renderInternal(GameWindow.java:459)
    zombie.GameWindow.frameStep(GameWindow.java:801)
    zombie.GameWindow.mainThreadStep(GameWindow.java:568)
    zombie.MainThread.mainLoop(MainThread.java:69)
    java.base/java.lang.Thread.run(Unknown Source)
ERROR: General f:73589> Lua(Vanilla).balloon> Exception thrown
    java.lang.RuntimeException: __concat not defined for operands: , and null at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).balloon(worldmap-annotations.lua:124)
    Lua(Vanilla).tick(worldmap-annotations.lua:201)
ZEDQA mood ERR step 20: __concat not defined for operands: , and null java.lang.RuntimeException
ZEDQA mood PASS with nothing changing the box goes by itself (nil)
ZEDQA mood notices off: box nil | waiting 2
ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
ZEDQA mood all checks passed
ZEDQA mood DONE
```

### 18. b10_guide_open_frames.lua (`ZEDQA gframes`) - PASS, 5 s

- go 10017 at 09:41:59
- screenshots: zqa_gframes_1280x800_open.png, zqa_gframes_1280x800_bubble.png, zqa_gframes_1280x800_f1.png

```text
[ZeD.QA] state #18 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gframes start
[ZeD.QA] run #18 ok=true
ZEDQA gframes open: opening
ZEDQA gframes PASS open: the open returns
ZEDQA gframes PASS open: the game is paused while it is open
ZEDQA gframes PASS open: the guide is open
ZEDQA gframes open: 120 frames with the guide open in 1173 ms (9.8 ms a frame)
ZEDQA gframes PASS open: still open after 120 frames
ZEDQA gframes PASS open: the average frame is under 100 ms
ZEDQA gframes PASS open: F1 closes it
ZEDQA gframes PASS open: the game plays again
ZEDQA gframes bubble: opening
ZEDQA gframes PASS bubble: the open returns
ZEDQA gframes PASS bubble: the game is paused while it is open
ZEDQA gframes PASS bubble: the guide is open
ZEDQA gframes bubble: 120 frames with the guide open in 1233 ms (10.3 ms a frame)
ZEDQA gframes PASS bubble: still open after 120 frames
ZEDQA gframes PASS bubble: the average frame is under 100 ms
ZEDQA gframes PASS bubble: F1 closes it
ZEDQA gframes PASS bubble: the game plays again
ZEDQA gframes f1: opening
ZEDQA gframes PASS f1: the open returns
ZEDQA gframes PASS f1: the game is paused while it is open
ZEDQA gframes PASS f1: the guide is open
ZEDQA gframes f1: 120 frames with the guide open in 1190 ms (9.9 ms a frame)
ZEDQA gframes PASS f1: still open after 120 frames
ZEDQA gframes PASS f1: the average frame is under 100 ms
ZEDQA gframes PASS f1: F1 closes it
ZEDQA gframes PASS f1: the game plays again
ZEDQA gframes RESULT 21 pass, 0 fail
ZEDQA gframes DONE
```

### 19. zedqa_guide_bubble.lua (`ZEDQA gbub`) - PASS, 58 s

- go 10018 at 09:42:08
- screenshots: zqa_gbub_1280x800_2_bubble_from_belt.png, zqa_gbub_1280x800_3_guide_opened.png, zqa_gbub_1280x800_7_controller_variant.png

```text
[ZeD.QA] state #19 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gbub start
[ZeD.QA] run #19 ok=true
ZEDQA gbub PASS 1: a fresh machine arms the clock
ZEDQA gbub PASS 1: the guide is not open 20 s after the start (it used to open full screen)
ZEDQA gbub PASS 1: no bubble before 30 s
ZEDQA gbub PASS 2: the bubble is up at about 30 s of play
ZEDQA gbub PASS 2: the director's wording exactly, with F1
ZEDQA gbub PASS 2: a long bare balloon for player one
ZEDQA gbub PASS 2: the line is in Messages, unread
ZEDQA gbub PASS 2: the flag file says shown
ZEDQA gbub PASS 2: the guide is still closed
ZEDQA gbub shot 2_bubble_from_belt
ZEDQA gbub PASS 3: the balloon has a click
ZEDQA gbub PASS 3: the click opened the guide
ZEDQA gbub PASS 3: the balloon is gone, the line stays in Messages
ZEDQA gbub shot 3_guide_opened
ZEDQA gbub PASS 4: the first showing, one line
ZEDQA gbub PASS 4: it came back and the line is not doubled
ZEDQA gbub PASS 4: a right-click dismisses it
ZEDQA gbub PASS 4: nothing comes back after a dismiss
ZEDQA gbub PASS 4: the line stays
ZEDQA gbub PASS 5: a live offer
ZEDQA gbub PASS 5: F1 by any road ends the offer and takes the balloon off
ZEDQA gbub PASS 5: the line carries its Open
ZEDQA gbub PASS 5: the line's Open opens the guide
ZEDQA gbub PASS 6: a machine that has had its bubble arms nothing
ZEDQA gbub PASS 6: with the flag emptied it arms again
ZEDQA gbub PASS 7: on a controller the key words are the Help wheel's, not F1
ZEDQA gbub PASS 7: the controller's balloon is up
ZEDQA gbub PASS 7: and it names no F1
ZEDQA gbub shot 7_controller_variant
ZEDQA gbub PASS 8: the game's own guide window is not up
ZEDQA gbub PASS 8: no ZeD guide open
ZEDQA gbub RESULT 28 pass, 0 fail
ZEDQA gbub DONE
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
