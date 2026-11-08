# ZeD-UI regression - 2026-11-06 22:14 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-06 22:14:28 |
| Finished | 2026-11-06 22:18:32 (4 min 3 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b6a_misses.txt (6 scripts) |
| Result | **4/6 pass**, 1 warn, 1 fail, 0 timeout |
| Go numbers | 22736 to 22743 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 22742, 22743)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_ctx_icons.lua | cx | **FAIL** | 23 | zqa_cx_grid.png, zqa_cx_strip_apple.png, zqa_cx_strip_pistol.png, zqa_cx_strip_bandage.png, zqa_cx_strip_hammer.png, zqa_cx_strip_floor.png, zqa_cx_list_apple.png, zqa_cx_list_pistol.png, zqa_cx_list_bandage.png, zqa_cx_list_hammer.png, zqa_cx_list_floor.png | 12 Java exception(s) in the log |
| 4 | zedqa_world_pad_take.lua | wpt | WARN | 97 |  | 1 ERR line(s) |
| 5 | zedqa_food_verbs.lua | fv | PASS | 4 | zqa_fv_smoking.png |  |
| 6 | zedqa_seat_lightbar_vanilla.lua | sl | PASS | 23 | zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 22736 at 22:15:22

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 22737 at 22:15:28

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_ctx_icons.lua (`ZEDQA cx`) - FAIL, 23 s

- go 22738 at 22:15:32
- 12 Java exception(s) in the log
- screenshots: zqa_cx_grid.png, zqa_cx_strip_apple.png, zqa_cx_strip_pistol.png, zqa_cx_strip_bandage.png, zqa_cx_strip_hammer.png, zqa_cx_strip_floor.png, zqa_cx_list_apple.png, zqa_cx_list_pistol.png, zqa_cx_list_bandage.png, zqa_cx_list_hammer.png, zqa_cx_list_floor.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cx ok 389 pictures in the menu's table, each with a pixel icon
ZEDQA cx ok each pixel icon has its four drawings
ZEDQA cx scale 1.75: the cell is 39 px, its icon box 28, the drawing 24
ZEDQA cx ok the box rule picks 24 for the menu's icon box
ZEDQA cx ok Walk to: walk (walk)
ZEDQA cx ok ContextMenu_Eat (Eat): apple
ZEDQA cx ok ContextMenu_Drink (Drink): glass
ZEDQA cx ok ContextMenu_Equip_Primary (Equip Primary): hand_main
ZEDQA cx ok ContextMenu_Barricade (Barricade (Planks)): barricade
ZEDQA cx ok a label with a changing part finds its verb's icon: book
ZEDQA cx grid x0=35 y0=35 cell=39 gap=7 per=82 n=291 box=28
ZEDQA cx ids alarm,alarm_off,ammo,ammo_off,apple,arrow_left,arrow_right,backpack,bacon,bandage,bandage_off,barricade,bath,bayonet,bed,beer,berries,blender,blood,book,bookcase,boot,bottle,bowl,box_down,box_open,box_up,brain,bread,bricks,broom,bucket,bug,bulb_off,bulb_on,bulb_remove,burger,butter,cake,campfire,can,candy,cap,car_battery,car_door,car_enter,car_exit,car_x,carrot,chair,cheese,chocolate,cigarette,citrus,climb,climb_window,cocktail,coffee_pot,coffin,comb,combine,compost,cookie,cow,craft,craft_off,crop,cup,curtains,dna,door,drop,drumstick,dumbbell,egg,egg_fried,empty,engine,equip,extinguisher,eye,eyedrop,fabric,feather,fence,fill,filter,fireplace,fish,fist,flag,flame,flask,floor,follow_me,garlic,gas_can,gas_pump,gas_siphon,gauge,gears,generator,glass,glass_empty,glass_half,grater,grill,group,guide,gun,gun_fire,hammer,hand,hand_main,hand_off,hanger,heart,help,holster,holster_left,holster_right,honey,hook,horn,hotdog,hotwire,hutch,icecream,info,jacket,jar,juice,kebab,key_off,knife,ladder,leaf,lightbar,link,lipstick,locker,mag_in,mag_out,magazine,magnifier,map,mask,match,meat,milk,minus,more,mortar,move_down,move_up,mug,mushroom,needle,no,nose,notebook,nut,oil,ointment,one,padlock,padlock_open,paint,paintbrush,pan,pancakes,pasta,patch,peapod,pencil,pepper,pet,pet_bowl,pie,pillow,pills,pin,pipe,pizza,planks,plant,pliers,plug,plus,poison,pot,potato,pour,progress,pulse,push,rack,rain,razor,reinforce,rip,rod,roller,rope,rope_climb,rotate,rounds_out,sack,sad,salad,same_type,sandwich,sauce,saw,scarf,scissors,scope,screwdriver,scythe,seed,seek,shaker,shelves,shield_minus,shield_plain,shirt,shovel,sit_ground,sit_seat,skills,skull,sledge,sleeping_bag,smiley,soup,sparkle,splint,spoon,spray,stairs,stand,star,star_off,steak,stethoscope,suppressor,swap,table,taco,tally,tap,target,tent,tent_down,thermometer,tire,to_floor,toast,toilet,tombstone,tooth,tourniquet,towel,trap,trash,tray_in,tray_out,unequip,unlink,unplug,upgrade,view_grid,view_list,waffle,walk,warning,wash_hands,washer,watch,watering_can,welder,well,whisk,window,wine,wine_glass,wires,wrap,wrench,yarn,yes
ZEDQA cx start
[ZeD.QA] run #3 ok=true
ZEDQA cx drawings not ready yet: 274
ZEDQA cx drawings not ready after 69 frames: 0
ZEDQA cx ok every drawing on the panel loaded
ZEDQA cx shot zqa_cx_grid
ZEDQA cx ok the test panel drew
ZEDQA cx strip apple: ZeD_ContextMenu | pixel 14, licensed 0, item pictures 0, none 0
ZEDQA cx ok strip apple opened with pixel icons
ZEDQA cx ok strip apple: no licensed picture left
ZEDQA cx shot zqa_cx_strip_apple
ZEDQA cx strip pistol: ZeD_ContextMenu | pixel 15, licensed 0, item pictures 0, none 1 (Pin to title bar)
ZEDQA cx ok strip pistol opened with pixel icons
ZEDQA cx ok strip pistol: no licensed picture left
ZEDQA cx shot zqa_cx_strip_pistol
ZEDQA cx strip bandage: ZeD_ContextMenu | pixel 13, licensed 0, item pictures 0, none 0
ZEDQA cx ok strip bandage opened with pixel icons
ZEDQA cx ok strip bandage: no licensed picture left
ZEDQA cx shot zqa_cx_strip_bandage
ZEDQA cx strip hammer: ZeD_ContextMenu | pixel 15, licensed 0, item pictures 0, none 3 (Belt Left, Belt Right, Pin to title bar)
ZEDQA cx ok strip hammer opened with pixel icons
ZEDQA cx ok strip hammer: no licensed picture left
ZEDQA cx shot zqa_cx_strip_hammer
ERROR: General f:1293> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ERROR: General f:1293> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ERROR: General f:1293> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ERROR: General f:1293> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ERROR: General f:1293> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ERROR: General f:1293> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ZEDQA cx strip floor: ZeD_ContextMenu | pixel 11, licensed 0, item pictures 2, none 7 (Apple, Hay, Animal Feed Bag, Feed, Apple, Hay, Animal Feed Bag)
ZEDQA cx ok strip floor opened with pixel icons
ZEDQA cx ok strip floor: no licensed picture left
ZEDQA cx shot zqa_cx_strip_floor
ZEDQA cx list apple: ZeD_ContextList | pixel 14, licensed 0, item pictures 0, none 0
ZEDQA cx ok list apple opened with pixel icons
ZEDQA cx ok list apple: no licensed picture left
ZEDQA cx shot zqa_cx_list_apple
ZEDQA cx list pistol: ZeD_ContextList | pixel 15, licensed 0, item pictures 0, none 1 (Pin to title bar)
ZEDQA cx ok list pistol opened with pixel icons
ZEDQA cx ok list pistol: no licensed picture left
ZEDQA cx shot zqa_cx_list_pistol
ZEDQA cx list bandage: ZeD_ContextList | pixel 13, licensed 0, item pictures 0, none 0
ZEDQA cx ok list bandage opened with pixel icons
ZEDQA cx ok list bandage: no licensed picture left
ZEDQA cx shot zqa_cx_list_bandage
ZEDQA cx list hammer: ZeD_ContextList | pixel 15, licensed 0, item pictures 0, none 3 (Belt Left, Belt Right, Pin to title bar)
ZEDQA cx ok list hammer opened with pixel icons
ZEDQA cx ok list hammer: no licensed picture left
ZEDQA cx shot zqa_cx_list_hammer
ERROR: General f:1523> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ERROR: General f:1523> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ERROR: General f:1523> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ERROR: General f:1523> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ERROR: General f:1523> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ERROR: General f:1523> Lua(Vanilla).createMenu> Exception thrown
    java.lang.NullPointerException: Cannot invoke "String.equals(Object)" because "spriteName" is null at ISWorldObjectContextMenuLogic.fetch(ISWorldObjectContextMenuLogic.java:474).
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:187)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).n(spawnpoints.lua:150)
    Lua(Vanilla).tick(spawnpoints.lua:181)
ZEDQA cx list floor: ZeD_ContextList | pixel 11, licensed 0, item pictures 2, none 7 (Apple, Hay, Animal Feed Bag, Feed, Apple, Hay, Animal Feed Bag)
ZEDQA cx ok list floor opened with pixel icons
ZEDQA cx ok list floor: no licensed picture left
ZEDQA cx shot zqa_cx_list_floor
ZEDQA cx DONE 0 failed
```

### 4. zedqa_world_pad_take.lua (`ZEDQA wpt`) - WARN, 97 s

- go 22739 at 22:15:59
- 1 ERR line(s)

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #4 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Ground | stops container:2@0, container:1@100
ZEDQA wpt PASS the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldMainInv:invrow:1 (Nails)
ZEDQA wpt PASS RB lands in the World window on a lit element
ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
ZEDQA wpt 1 Right from the Character window's right edge: World worldMainInv:invrow:1 (Nails)
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
ZEDQA wpt PASS 6 A on a row: focus is on the card's primary action (USE)
ZEDQA wpt 6 after B: Char charMainInv:invrow:1 (Animal Feed Bag)
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
ZEDQA wpt PASS 7 Char equip small pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 639 of 650)
ZEDQA wpt PASS 7 Char equip small wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 624 of 650)
ZEDQA wpt PASS 7 Char health small pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 Char health small wheel: the lowest control health:exercise is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char health small Health: scrolled to the end, drawn 616 px in a 521 px view
ZEDQA wpt PASS 7 Char thermal small pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 Char thermal small wheel: the lowest control thermal:view is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char identity small pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 639 of 650)
ZEDQA wpt PASS 7 Char identity small wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 625 of 650)
ZEDQA wpt PASS 7 Char journal small pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 Char journal small wheel: the lowest control journal:__save is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char skills small pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 Char skills small wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 634 of 650)
ZEDQA wpt PASS 7 World craft small pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World craft small wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World build small pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World build small wheel: the lowest control build:sortMenu is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World furniture small pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 65 of 650)
ZEDQA wpt PASS 7 World furniture small wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 65 of 650)
ZEDQA wpt PASS 7 World maps small pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World maps small wheel: the lowest control map:style:survey is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World forage small pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World forage small wheel: the lowest control forage:search is in view at the bottom (bottom 641 of 650)
ZEDQA wpt FAIL 7 World animals small pad: Down reaches the lowest control of its column animals:alert:43 and it is in view (bottom 523 of 650)
ZEDQA wpt PASS 7 World animals small wheel: the lowest control animals:disclosure:totalsExpanded is in view at the bottom (bottom 398 of 650)
ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 620 of 638)
ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 610 of 638)
ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 Char health large wheel: the lowest control health:exercise is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 623 px in a 491 px view
ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:view is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 626 of 638)
ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 610 of 638)
ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:__save is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 620 of 638)
ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World build large wheel: the lowest control build:sortMenu is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 75 of 638)
ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 75 of 638)
ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:style:survey is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:search is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World animals large pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:createzone is in view at the bottom (bottom 628 of 638)
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA wpt 88 passed, 1 failed
ZEDQA wpt DONE
```

### 5. zedqa_food_verbs.lua (`ZEDQA fv`) - PASS, 4 s

- go 22740 at 22:17:39
- screenshots: zqa_fv_smoking.png

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA fv start
[ZeD.QA] run #5 ok=true
ZEDQA fv Cigarette: the card's main button reads Smoke (id EAT)
ZEDQA fv PASS Cigarette: the card says Smoke
ZEDQA fv Apple: the card's main button reads Eat (id EAT)
ZEDQA fv PASS Apple: the card says Eat
ZEDQA fv Canned Evaporated Milk (Open): the card's main button reads Drink (id EAT)
ZEDQA fv PASS Canned Evaporated Milk (Open): the card says Drink
ZEDQA fv smoking: the action is ISEatFoodAction, the bar reads SMOKING
ZEDQA fv PASS smoking: the bar says SMOKING
ZEDQA fv eating: the action is ISEatFoodAction, the bar reads EATING
ZEDQA fv PASS an apple: the bar still says EATING
ZEDQA fv all checks passed
ZEDQA fv DONE
```

### 6. zedqa_seat_lightbar_vanilla.lua (`ZEDQA sl`) - PASS, 23 s

- go 22741 at 22:17:46
- screenshots: zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sl start
[ZeD.QA] run #6 ok=true
ZEDQA vp sl player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=921,13040 dist=4.5 chunk=true inMap=true car=Base.PickUpTruck at 921.0,13040.0 dist=4.5 vehicles=35
ZEDQA vp sl player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=929,13040 dist=3.6 chunk=true inMap=true car=Base.CarLightsKST at 929.0,13040.0 dist=3.6 vehicles=35
ZEDQA vp sl player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=925,13035 dist=5.5 chunk=true inMap=true car=Base.VanSeats at 925.0,13035.0 dist=5.5 vehicles=35
ZEDQA sl pickup=BaseVehicle{ Name:null, ID:104 } police=BaseVehicle{ Name:null, ID:105 } van=BaseVehicle{ Name:null, ID:106 }
ZEDQA sl enter Base.PickUpTruck dist=4.9 physics=true
ZEDQA sl enter Base.CarLightsKST dist=10.4 physics=false
ZEDQA sl lightbar x=1705 y=940 w=430 h=280
ZEDQA sl enter Base.VanSeats dist=8.6 physics=false
ZEDQA sl DONE
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
