# ZeD-UI regression - 2026-11-09 12:42 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-09 12:42:28 |
| Finished | 2026-11-09 12:49:24 (6 min 55 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta11 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b11_deck_reruns.txt (4 scripts) |
| Result | **2/4 pass**, 2 warn, 0 fail, 0 timeout |
| Go numbers | 24508 to 24513 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 24512, 24513)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_b9a_2.lua | b9a2 | PASS | 75 | zqa_b9a2_1280x800_1_floor_stack.png, zqa_b9a2_1280x800_2_in_inventory.png, zqa_b9a2_1280x800_3_on_floor.png, zqa_b9a2_1280x800_4_grid.png, zqa_b9a2_1280x800_5_open_stack.png, zqa_b9a2_1280x800_6_one_moved.png |  |
| 3 | zedqa_b9a_4.lua | b9a4 | WARN | 160 | zqa_b9a4_1280x800_char_1_rolled_in.png, zqa_b9a4_1280x800_char_2_drawer_back.png, zqa_b9a4_1280x800_char_3_held_over_target.png, zqa_b9a4_1280x800_char_4_dropped.png, zqa_b9a4_1280x800_world_1_rolled_in.png, zqa_b9a4_1280x800_world_2_drawer_back.png, zqa_b9a4_1280x800_world_3_held_over_target.png, zqa_b9a4_1280x800_world_4_dropped.png | 19 ERR line(s) |
| 4 | zedqa_dual_pin.lua | dpn | WARN | 80 | zqa_dpn_1280x800_1_pins.png, zqa_dpn_1280x800_2_maps_pinned.png, zqa_dpn_1280x800_4_containers_down.png, zqa_dpn_1280x800_5_char_drawer_down.png, zqa_dpn_1280x800_5_char_drawer_pinned.png, zqa_dpn_1280x800_6_aim.png, zqa_dpn_1280x800_7_rod_pin.png, zqa_dpn_1280x800_2_6b_inventory_part.png, zqa_dpn_1280x800_2_6b_drawer_part.png, zqa_dpn_1280x800_9_pad_down.png | 13 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 24508 at 12:43:21

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_b9a_2.lua (`ZEDQA b9a2`) - PASS, 75 s

- go 24509 at 12:43:25
- screenshots: zqa_b9a2_1280x800_1_floor_stack.png, zqa_b9a2_1280x800_2_in_inventory.png, zqa_b9a2_1280x800_3_on_floor.png, zqa_b9a2_1280x800_4_grid.png, zqa_b9a2_1280x800_5_open_stack.png, zqa_b9a2_1280x800_6_one_moved.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=16 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b9a2 screen 1280x800
ZEDQA b9a2 start
[ZeD.QA] run #2 ok=true
ZEDQA b9a2 nails held before: 18
ZEDQA b9a2 shot 1_floor_stack
ZEDQA b9a2 PASS World to Character: the row to drag is on screen
ZEDQA b9a2 PASS World to Character: the row is held (the drag object is active)
ZEDQA b9a2 PASS a closed stack dragged from the World list: all six nails moved (18 to 24)
ZEDQA b9a2 shot 2_in_inventory
ZEDQA b9a2 PASS Character to the floor: the row to drag is on screen
ZEDQA b9a2 PASS Character to the floor: the row is held (the drag object is active)
ZEDQA b9a2 PASS a closed stack dragged out over the world: all six dropped (24 to 4)
ZEDQA b9a2 shot 3_on_floor
ZEDQA b9a2 floor key type:floor
ZEDQA b9a2 shot 4_grid
ZEDQA b9a2 PASS grid cell to Character: the row to drag is on screen
ZEDQA b9a2 PASS grid cell to Character: the row is held (the drag object is active)
ZEDQA b9a2 PASS a grid cell (the grid opens no stacks): all six moved (4 to 20)
ZEDQA b9a2 the player's list: grid (player)
ZEDQA b9a2 the chevron click at 351,268: rolled nil, shaded false, list 330,20 279x278 shown true
ZEDQA b9a2 PASS the nails stack's chevron is on screen
ZEDQA b9a2 PASS the chevron opens the stack (a second nails row)
ZEDQA b9a2 shot 5_open_stack
ZEDQA b9a2 PASS one row of an open stack: the row to drag is on screen
ZEDQA b9a2 PASS one row of an open stack: the row is held (the drag object is active)
ZEDQA b9a2 PASS an open stack's row moves only its own nail (24 to 23)
ZEDQA b9a2 shot 6_one_moved
ZEDQA b9a2 RESULT 14 pass, 0 fail
ZEDQA b9a2 DONE
```

### 3. zedqa_b9a_4.lua (`ZEDQA b9a4`) - WARN, 160 s

- go 24510 at 12:44:43
- 19 ERR line(s)
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
ZEDQA b9a4 char: the press point 399,211 (row found true, list 330,20 279x278) over Base.Spoon
ZEDQA b9a4 ERR the mouse helper never answered: down 399 211
ZEDQA b9a4 char: after the press: pending true, card true, tab loot, the pointer at 399,210 over Base.Spoon, the list at 330,20
ZEDQA b9a4 ERR the mouse helper never answered: move 411 221
ZEDQA b9a4 ERR the mouse helper never answered: move 439 241
ZEDQA b9a4 ERR the mouse helper never answered: move 479 271
ZEDQA b9a4 FAIL char: the item is held (the drag object is active)
ZEDQA b9a4 shot char_2_drawer_back
ZEDQA b9a4 ERR the mouse helper never answered: move 810 10
ZEDQA b9a4 ERR the mouse helper never answered: move 810 20
ZEDQA b9a4 shot char_3_held_over_target
ZEDQA b9a4 ERR the mouse helper never answered: up 810 20
ZEDQA b9a4 shot char_4_dropped
ZEDQA b9a4 PASS world: the item's row is on screen
ZEDQA b9a4 ERR the mouse helper never answered: move 841 166
ZEDQA b9a4 FAIL world: (staged) looking through the list, the drawer rolled in
ZEDQA b9a4 FAIL world: (staged) the other window rolled up meanwhile
ZEDQA b9a4 shot world_1_rolled_in
ZEDQA b9a4 world: the press point 837,166 (row found true, list 667,20 226x278) over Base.Nails
ZEDQA b9a4 ERR the mouse helper never answered: down 837 166
ZEDQA b9a4 world: after the press: pending false, card false, tab maps, the pointer at 399,210 over nil, the list at 667,20
ZEDQA b9a4 ERR the mouse helper never answered: move 849 176
ZEDQA b9a4 ERR the mouse helper never answered: move 877 196
ZEDQA b9a4 ERR the mouse helper never answered: move 917 226
ZEDQA b9a4 FAIL world: the item is held (the drag object is active)
ZEDQA b9a4 shot world_2_drawer_back
ZEDQA b9a4 ERR the mouse helper never answered: move 387 10
ZEDQA b9a4 ERR the mouse helper never answered: move 469 159
ZEDQA b9a4 shot world_3_held_over_target
ZEDQA b9a4 ERR the mouse helper never answered: up 469 159
ZEDQA b9a4 shot world_4_dropped
ZEDQA b9a4 RESULT 4 pass, 19 fail
ZEDQA b9a4 DONE
```

### 4. zedqa_dual_pin.lua (`ZEDQA dpn`) - WARN, 80 s

- go 24511 at 12:47:26
- 13 ERR line(s)
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
ZEDQA dpn FAIL away 3 s: the World containers rolled under their rod
ZEDQA dpn PASS away 3 s: the map still open (pinned)
ZEDQA dpn shot 2_maps_pinned
ZEDQA dpn FAIL 2.2a: the Character window is rolled before the sweep
ZEDQA dpn FAIL 2.2a: a 0.12 s pass over the rolled title bar leaves it rolled
ZEDQA dpn FAIL pointer on the map 3 s: map open, the containers still rolled
ZEDQA dpn PASS pointer on the containers' rod: they come down, the map open
ZEDQA dpn shot 4_containers_down
ZEDQA dpn PASS the drawer's part of the Character bar: the window down, the drawer open
ZEDQA dpn FAIL ... the inventory still rolled under its rod
ZEDQA dpn shot 5_char_drawer_down
ZEDQA dpn FAIL a real click on the Character's left pin pins its drawer
ZEDQA dpn FAIL away 3 s: the pinned drawer stays, the inventory rolled
ZEDQA dpn shot 5_char_drawer_pinned
ZEDQA dpn PASS aiming: the Character's pinned drawer stays open
ZEDQA dpn PASS aiming: the World's pinned map stays open
ZEDQA dpn FAIL aiming: both inventory sides rolled
ZEDQA dpn shot 6_aim
ZEDQA dpn Character rod pin none
ZEDQA dpn FAIL a real click on the pin on the Character's rod pins the inventory
ZEDQA dpn PASS ... and the pinned inventory comes down
ZEDQA dpn shot 7_rod_pin
ZEDQA dpn FAIL a real click on the open tab still folds the drawer (pinned or not)
ZEDQA dpn PASS ... by hand: not the half's fold
ZEDQA dpn PASS 2.2b: the Character window rolled for the drag test
ZEDQA dpn PASS 2.2b: an item held over the rolled title bar brings the window down within 0.25 s
ZEDQA dpn PASS 2.2c: (staged) drawer pinned, the inventory rolled under its rod
ZEDQA dpn PASS 2.2c: an item held over the rod brings the inventory down within 0.25 s, the drawer pinned
ZEDQA dpn PASS 2.2c: ... the pinned drawer still open
ZEDQA dpn FAIL 2.6b: the inventory's part of the rolled bar: only the inventory comes back, the drawer still rolled in
ZEDQA dpn PASS 2.6b: ... the window still on Health (not Loot)
ZEDQA dpn shot 2_6b_inventory_part
ZEDQA dpn FAIL 2.6b: the drawer's part: only the drawer comes back, the inventory under its rod
ZEDQA dpn shot 2_6b_drawer_part
ZEDQA dpn PASS Health open again
ZEDQA dpn pad stops: 2 halfpin:drawer, halfpin:inv
ZEDQA dpn PASS pad: the two pins are the bar's stops, left to right
ZEDQA dpn PASS pad: A on the inventory's pin toggles it
ZEDQA dpn PASS pad aim: the Character drawer (pinned) stays, its inventory rolls
ZEDQA dpn PASS pad aim: the World map (pinned) stays
ZEDQA dpn PASS Y / a bumper (showWin): both windows fully down
ZEDQA dpn shot 9_pad_down
ZEDQA dpn RESULT 23 pass, 13 fail
ZEDQA dpn DONE
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
