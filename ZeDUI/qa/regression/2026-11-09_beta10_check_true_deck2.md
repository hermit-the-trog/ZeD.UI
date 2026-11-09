# ZeD-UI regression - 2026-11-09 10:03 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-09 10:03:25 |
| Finished | 2026-11-09 10:07:06 (3 min 41 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta10 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b10_stage_deck2.txt (5 scripts) |
| Result | **3/5 pass**, 2 warn, 0 fail, 0 timeout |
| Go numbers | 10000 to 10006 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 10005, 10006)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_staged_ver.lua | sv | PASS | 1 |  |  |
| 3 | zedqa_b9a_4.lua | b9a4 | WARN | 70 | zqa_b9a4_1280x800_char_1_rolled_in.png, zqa_b9a4_1280x800_char_2_drawer_back.png, zqa_b9a4_1280x800_char_3_held_over_target.png, zqa_b9a4_1280x800_char_4_dropped.png, zqa_b9a4_1280x800_world_1_rolled_in.png, zqa_b9a4_1280x800_world_2_drawer_back.png, zqa_b9a4_1280x800_world_3_held_over_target.png, zqa_b9a4_1280x800_world_4_dropped.png | 1 ERR line(s) |
| 4 | zedqa_dual_pin.lua | dpn | WARN | 35 | zqa_dpn_1280x800_1_pins.png, zqa_dpn_1280x800_2_maps_pinned.png, zqa_dpn_1280x800_4_containers_down.png, zqa_dpn_1280x800_5_char_drawer_down.png, zqa_dpn_1280x800_5_char_drawer_pinned.png, zqa_dpn_1280x800_6_aim.png, zqa_dpn_1280x800_7_rod_pin.png, zqa_dpn_1280x800_2_6b_inventory_part.png, zqa_dpn_1280x800_2_6b_drawer_part.png, zqa_dpn_1280x800_9_pad_down.png | 1 ERR line(s) |
| 5 | zedqa_moodles.lua | mood | PASS | 21 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 10000 at 10:04:21

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

- go 10001 at 10:04:27

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sv version=0.3.0-beta10 dir=C:\Users\danie\ZomboidStaged\mods\ZeD-UI
[ZeD.QA] run #2 ok=true
ZEDQA sv DONE
```

### 3. zedqa_b9a_4.lua (`ZEDQA b9a4`) - WARN, 70 s

- go 10002 at 10:04:31
- 1 ERR line(s)
- screenshots: zqa_b9a4_1280x800_char_1_rolled_in.png, zqa_b9a4_1280x800_char_2_drawer_back.png, zqa_b9a4_1280x800_char_3_held_over_target.png, zqa_b9a4_1280x800_char_4_dropped.png, zqa_b9a4_1280x800_world_1_rolled_in.png, zqa_b9a4_1280x800_world_2_drawer_back.png, zqa_b9a4_1280x800_world_3_held_over_target.png, zqa_b9a4_1280x800_world_4_dropped.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a4 screen 1280x800
ZEDQA b9a4 start
[ZeD.QA] run #3 ok=true
ZEDQA b9a4 PASS char: the item's row is on screen
ZEDQA b9a4 PASS char: (staged) looking through the list, the drawer rolled in
ZEDQA b9a4 PASS char: (staged) the other window rolled up meanwhile
ZEDQA b9a4 shot char_1_rolled_in
ZEDQA b9a4 char: the press point 540,253 (row found true, list 387,20 226x278) over Base.Spoon
ZEDQA b9a4 char: after the press: pending false, card false, tab equip, the pointer at 540,252 over nil, the list at 330,20
ZEDQA b9a4 FAIL char: the item is held (the drag object is active)
ZEDQA b9a4 shot char_2_drawer_back
ZEDQA b9a4 shot char_3_held_over_target
ZEDQA b9a4 shot char_4_dropped
ZEDQA b9a4 PASS world: the item's row is on screen
ZEDQA b9a4 PASS world: (staged) looking through the list, the drawer rolled in
ZEDQA b9a4 PASS world: (staged) the other window rolled up meanwhile
ZEDQA b9a4 shot world_1_rolled_in
ZEDQA b9a4 world: the press point 837,166 (row found true, list 667,20 226x278) over Base.Nails
ZEDQA b9a4 world: after the press: pending true, card true, tab maps, the pointer at 837,165 over Base.Nails, the list at 671,20
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

### 4. zedqa_dual_pin.lua (`ZEDQA dpn`) - WARN, 35 s

- go 10003 at 10:05:44
- 1 ERR line(s)
- screenshots: zqa_dpn_1280x800_1_pins.png, zqa_dpn_1280x800_2_maps_pinned.png, zqa_dpn_1280x800_4_containers_down.png, zqa_dpn_1280x800_5_char_drawer_down.png, zqa_dpn_1280x800_5_char_drawer_pinned.png, zqa_dpn_1280x800_6_aim.png, zqa_dpn_1280x800_7_rod_pin.png, zqa_dpn_1280x800_2_6b_inventory_part.png, zqa_dpn_1280x800_2_6b_drawer_part.png, zqa_dpn_1280x800_9_pad_down.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA dpn start
[ZeD.QA] run #4 ok=true
ZEDQA dpn PASS both windows have halves (WindowHalves)
ZEDQA dpn PASS pins saved per half
ZEDQA dpn PASS Character on Health, World on Maps
ZEDQA dpn Character pins: drawer (left) 26,5 10x10, inventory (right) 604,5 10x10, window box 622,5 10x10
ZEDQA dpn World pins: containers (left) 26,5 10x10, drawer (right) 604,5 10x10, window box 622,5 10x10
ZEDQA dpn PASS Character: one pin at each end of the bar, the right one before the window box
ZEDQA dpn shot 1_pins
ZEDQA dpn FAIL away 3 s: the Character window rolled to its title bar
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
ZEDQA dpn Character rod pin 288,5 10x10
ZEDQA dpn PASS a real click on the pin on the Character's rod pins the inventory
ZEDQA dpn PASS ... and the pinned inventory comes down
ZEDQA dpn shot 7_rod_pin
ZEDQA dpn PASS a real click on the open tab still folds the drawer (pinned or not)
ZEDQA dpn PASS ... by hand: not the half's fold
ZEDQA dpn PASS 2.2b: the Character window rolled for the drag test
ZEDQA dpn PASS 2.2b: an item held over the rolled title bar brings the window down within 0.25 s
ZEDQA dpn PASS 2.2c: (staged) drawer pinned, the inventory rolled under its rod
ZEDQA dpn PASS 2.2c: an item held over the rod brings the inventory down within 0.25 s, the drawer pinned
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

### 5. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 21 s

- go 10004 at 10:06:22
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #5 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 4
ZEDQA mood box by itself: TIRED | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA mood right: 5 moodles on (TIRED 2, HUNGRY 2, PANIC 1, STRESS 2, THIRST 2)
ZEDQA mood PASS right: the place is in effect
ZEDQA mood PASS right: at least three moodles are on
ZEDQA mood PASS right: the moodles are shown (layer)
ZEDQA mood right column at 1222,260 size 48, stack 280; visible true
ZEDQA mood PASS right: vanilla's column is visible
ZEDQA mood PASS right: every moodle is on screen
ZEDQA mood PASS right: the column is on the right edge (x 1222)
ZEDQA mood PASS right: ZeD's hover layer lies over the column
ZEDQA mood right bubble: moodle 2, cloud -223,77 212x37.08203125, trail balloon from nil,nil
ZEDQA mood PASS right: the bubble is for the moodle under the pointer
ZEDQA mood PASS right: the balloon sits beside its moodle, clear of it
ZEDQA mood left: 5 moodles on (TIRED 2, HUNGRY 2, PANIC 2, STRESS 2, THIRST 2)
ZEDQA mood PASS left: the place is in effect
ZEDQA mood PASS left: at least three moodles are on
ZEDQA mood PASS left: the moodles are shown (layer)
ZEDQA mood left column at 10,260 size 48, stack 280; visible true
ZEDQA mood PASS left: vanilla's column is visible
ZEDQA mood PASS left: every moodle is on screen
ZEDQA mood PASS left: the column is on the left edge (x 10)
ZEDQA mood PASS left: ZeD's hover layer lies over the column
ZEDQA mood left bubble: moodle 2, cloud 59,77 212x37.08203125, trail balloon from nil,nil
ZEDQA mood PASS left: the bubble is for the moodle under the pointer
ZEDQA mood PASS left: the balloon sits beside its moodle, clear of it
ZEDQA mood bottom: 5 moodles on (TIRED 2, HUNGRY 2, PANIC 2, STRESS 2, THIRST 2)
ZEDQA mood PASS bottom: the place is in effect
ZEDQA mood PASS bottom: at least three moodles are on
ZEDQA mood PASS bottom: the moodles are shown (layer)
ZEDQA mood bottom row at 500,689 280x48; vanilla's column y -10000
ZEDQA mood PASS bottom: the row is on screen
ZEDQA mood PASS bottom: the row is centred (middle 640 of 1280)
ZEDQA mood PASS bottom: the row sits above the belt
ZEDQA mood PASS bottom: one slot per moodle
ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
ZEDQA mood bottom bubble: moodle 2, cloud 62,-48.08203125 212x37.08203125, trail balloon from nil,nil
ZEDQA mood PASS bottom: the bubble is for the moodle under the pointer
ZEDQA mood PASS bottom: the balloon sits beside its moodle, clear of it
ZEDQA mood PASS with nothing changing the box goes by itself (nil)
ZEDQA mood notices off: box nil | waiting 2
ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
ZEDQA mood all checks passed
ZEDQA mood DONE
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
