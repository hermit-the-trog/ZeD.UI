# ZeD-UI regression - 2026-10-30 09:05 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-30 09:05:22 |
| Finished | 2026-10-30 09:15:30 (10 min 7 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | mouse_pass.txt (11 scripts) |
| Result | **10/11 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 16320 to 16330 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- -KeepOpen: the game was left running
- -KeepOpen: ZeD settings are still the test's; the director's file is C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-10-30_mouse_pass_fullscreen4k.md.modoptions.ini

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | suite_tabs.lua | tabs | PASS | 11 |  |  |
| 3 | zedqa_ctxlist.lua | cl | PASS | 4 | zqa_cl_1.png, zqa_cl_2.png |  |
| 4 | zedqa_ctx_icons.lua | cx | PASS | 21 | zqa_cx_grid.png, zqa_cx_strip_apple.png, zqa_cx_strip_pistol.png, zqa_cx_strip_bandage.png, zqa_cx_strip_hammer.png, zqa_cx_strip_floor.png, zqa_cx_list_apple.png, zqa_cx_list_pistol.png, zqa_cx_list_bandage.png, zqa_cx_list_hammer.png, zqa_cx_list_floor.png |  |
| 5 | zedqa_doll_v4.lua | dollv4 | PASS | 29 | zqa_dollv4_3840x2160_wide.png, zqa_dollv4_3840x2160_dpad.png, zqa_dollv4_3840x2160_wide_pads.png, zqa_dollv4_3840x2160_card.png, zqa_dollv4_3840x2160_narrow.png, zqa_dollv4_3840x2160_short.png |  |
| 6 | zedqa_curtain.lua | cu | PASS | 133 | zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png |  |
| 7 | zedqa_lists.lua | ls | PASS | 14 | zqa_ls_01_page_480.png, zqa_ls_02_page_480_lines.png, zqa_ls_03_stepper.png, zqa_ls_04_ask_delete.png, zqa_ls_05_rightclick_list.png, zqa_ls_06_rightclick_strip.png, zqa_ls_07_card_inlists.png, zqa_ls_08_mark_popup.png |  |
| 8 | zedqa_restock.lua | rst | PASS | 54 | zqa_rst_01_bar_ghosts.png, zqa_rst_02_todo.png, zqa_rst_02b_todo_lines.png, zqa_rst_03_ask_band.png, zqa_rst_04_after_hardcore.png, zqa_rst_05_pin_accessible.png, zqa_rst_06_pin_casual.png, zqa_rst_07_long_trip.png, zqa_rst_07b_long_trip_table.png, zqa_rst_08_unpack.png |  |
| 9 | zedqa_reader.lua | rd | PASS | 10 | zqa_rd_01_paper.png, zqa_rd_02_words.png, zqa_rd_03_story2.png, zqa_rd_04_zoomed.png, zqa_rd_05_flier.png, zqa_rd_06_map.png |  |
| 10 | zedqa_two_widths.lua | tww | PASS | 70 | zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png |  |
| 11 | zedqa_hairbeard.lua | hb | WARN | 150 | zqa_hb_list_no_tools.png, zqa_hb_no_tools.png, zqa_hb_tall.png, zqa_hb_greyed_hover.png, zqa_hb_heads_cut.png, zqa_hb_ready.png, zqa_hb_hair_list.png, zqa_hb_cutting.png, zqa_hb_done.png, zqa_hb_tied.png, zqa_hb_pad_beard_folded.png, zqa_hb_pad_beard_greyed.png, zqa_hb_pad_beard_show_all.png, zqa_hb_pad_beard.png, zqa_hb_beard_cut.png, zqa_hb_beard_list.png, zqa_hb_out_of_reach.png, zqa_hb_trait_focus.png, zqa_hb_trait_hover.png, zqa_hb_large.png, zqa_hb_light.png, zqa_hb_female_heads.png, zqa_hb_female_list.png | 19 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 16320 at 09:06:35

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. suite_tabs.lua (`ZEDQA tabs`) - PASS, 11 s

- go 16321 at 09:06:39

```text
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals,vehicle
ZEDQA tabs armed
[ZeD.QA] run #2 ok=true
ZEDQA char tab=loot active=loot w=777 focusables=0 {}
ZEDQA char tab=equip active=equip w=1617 focusables=33 {el=1 equipbelt=1 equipgroup=5 equippart=17 equipslot=7 equipview=2}
ZEDQA char tab=health active=health w=1617 focusables=27 {bodypart=17 exercise=9 health=1}
ZEDQA char tab=thermal active=thermal w=1617 focusables=26 {thermal=9 thermalpart=17}
ZEDQA char tab=identity active=identity w=1617 focusables=13 {hb=2 identity=11}
ZEDQA char tab=journal active=journal w=1617 focusables=7 {journal=2 jsub=5}
ZEDQA char tab=skills active=skills w=1617 focusables=60 {skill=35 skills=1 training=24}
ZEDQA world tab=loot active=loot w=777 focusables=0 {}
ZEDQA world tab=craft active=craft w=1617 focusables=11 {craft=11}
ZEDQA world tab=build active=build w=1617 focusables=8 {build=8}
ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
ZEDQA world tab=maps active=maps w=1617 focusables=19 {map=19}
ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
ZEDQA world tab=vehicle active=vehicle w=1617 focusables=1 {mech=1}
ZEDQA tabs done
```

### 3. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 4 s

- go 16322 at 09:06:54
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #3 ok=true
ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Set Unwanted, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Save to loadout, |, Rename
ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
ZEDQA cl down: sub sel 2
ZEDQA cl B: levels 1
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

### 4. zedqa_ctx_icons.lua (`ZEDQA cx`) - PASS, 21 s

- go 16323 at 09:07:01
- screenshots: zqa_cx_grid.png, zqa_cx_strip_apple.png, zqa_cx_strip_pistol.png, zqa_cx_strip_bandage.png, zqa_cx_strip_hammer.png, zqa_cx_strip_floor.png, zqa_cx_list_apple.png, zqa_cx_list_pistol.png, zqa_cx_list_bandage.png, zqa_cx_list_hammer.png, zqa_cx_list_floor.png

```text
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
[ZeD.QA] run #4 ok=true
ZEDQA cx drawings not ready yet: 267
ZEDQA cx drawings not ready after 67 frames: 0
ZEDQA cx ok every drawing on the panel loaded
ZEDQA cx shot zqa_cx_grid
ZEDQA cx ok the test panel drew
ZEDQA cx strip apple: ZeD_ContextMenu | pixel 14, licensed 0, item pictures 0, none 0
ZEDQA cx ok strip apple opened with pixel icons
ZEDQA cx ok strip apple: no licensed picture left
ZEDQA cx shot zqa_cx_strip_apple
ZEDQA cx strip pistol: ZeD_ContextMenu | pixel 15, licensed 0, item pictures 0, none 0
ZEDQA cx ok strip pistol opened with pixel icons
ZEDQA cx ok strip pistol: no licensed picture left
ZEDQA cx shot zqa_cx_strip_pistol
ZEDQA cx strip bandage: ZeD_ContextMenu | pixel 13, licensed 0, item pictures 0, none 0
ZEDQA cx ok strip bandage opened with pixel icons
ZEDQA cx ok strip bandage: no licensed picture left
ZEDQA cx shot zqa_cx_strip_bandage
ZEDQA cx strip hammer: ZeD_ContextMenu | pixel 15, licensed 0, item pictures 0, none 2 (Belt Left, Belt Right)
ZEDQA cx ok strip hammer opened with pixel icons
ZEDQA cx ok strip hammer: no licensed picture left
ZEDQA cx shot zqa_cx_strip_hammer
ZEDQA cx strip floor: ZeD_ContextMenu | pixel 4, licensed 0, item pictures 0, none 0
ZEDQA cx ok strip floor opened with pixel icons
ZEDQA cx ok strip floor: no licensed picture left
ZEDQA cx shot zqa_cx_strip_floor
ZEDQA cx list apple: ZeD_ContextList | pixel 14, licensed 0, item pictures 0, none 0
ZEDQA cx ok list apple opened with pixel icons
ZEDQA cx ok list apple: no licensed picture left
ZEDQA cx shot zqa_cx_list_apple
ZEDQA cx list pistol: ZeD_ContextList | pixel 15, licensed 0, item pictures 0, none 0
ZEDQA cx ok list pistol opened with pixel icons
ZEDQA cx ok list pistol: no licensed picture left
ZEDQA cx shot zqa_cx_list_pistol
ZEDQA cx list bandage: ZeD_ContextList | pixel 13, licensed 0, item pictures 0, none 0
ZEDQA cx ok list bandage opened with pixel icons
ZEDQA cx ok list bandage: no licensed picture left
ZEDQA cx shot zqa_cx_list_bandage
ZEDQA cx list hammer: ZeD_ContextList | pixel 15, licensed 0, item pictures 0, none 2 (Belt Left, Belt Right)
ZEDQA cx ok list hammer opened with pixel icons
ZEDQA cx ok list hammer: no licensed picture left
ZEDQA cx shot zqa_cx_list_hammer
ZEDQA cx list floor: ZeD_ContextList | pixel 4, licensed 0, item pictures 0, none 0
ZEDQA cx ok list floor opened with pixel icons
ZEDQA cx ok list floor: no licensed picture left
ZEDQA cx shot zqa_cx_list_floor
ZEDQA cx DONE 0 failed
```

### 5. zedqa_doll_v4.lua (`ZEDQA dollv4`) - PASS, 29 s

- go 16324 at 09:07:26
- screenshots: zqa_dollv4_3840x2160_wide.png, zqa_dollv4_3840x2160_dpad.png, zqa_dollv4_3840x2160_wide_pads.png, zqa_dollv4_3840x2160_card.png, zqa_dollv4_3840x2160_narrow.png, zqa_dollv4_3840x2160_short.png

```text
[ZeD.QA] windows reset (R)
ZEDQA dollv4 start
[ZeD.QA] run #5 ok=true
ZEDQA dollv4 round 1: wearing 21 of 21
ZEDQA dollv4 PASS 38 small slots defined | 38
ZEDQA dollv4 PASS wide: bands show | drawer 840px = 480 units, screen 3840x2160
ZEDQA dollv4 PASS wide: 49 slot boxes (11 big + 38 small) | 49
ZEDQA dollv4 PASS wide: no slot overlaps another
ZEDQA dollv4 PASS wide: every box inside the drawer's width | 840
ZEDQA dollv4 PASS wide: the drawer is no wider than the full card (480 units) | 480.0 units
ZEDQA dollv4 PASS wide: a small slot is 14 units or more on screen | 14.3 units
ZEDQA dollv4 PASS wide: 11 leader lines, none crossing another | 11 lines, 0 crossings
ZEDQA dollv4 PASS wide: Back, Arms, Belt in that order down the right | 85,286,386
ZEDQA dollv4 PASS wide: arms' line is one straight run, belt's turns up | 4/8
ZEDQA dollv4 PASS every group name and place name has its words |
ZEDQA dollv4 PASS round 1 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS round 1 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 1 folded (data): every worn thing lands in its big slot (21 on) |
ZEDQA dollv4 PASS belly button ring, air tank, tail in their small slots
ZEDQA dollv4 empties 25, slots with things 27
ZEDQA dollv4 PASS charTabContent zone exists with the doll's stops | 78
ZEDQA dollv4 PASS Left from Neck steps into the left band | doll:gorget
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
ZEDQA dollv4 PASS a cap dropped on Head is taken | rect 215,65 64x64 clip 0,65 815x585 | loc base:hat
ZEDQA dollv4 PASS a cap dropped on a small slot that is not its place is refused
ZEDQA dollv4 PASS a ring dropped on the wrong small slot is refused
ZEDQA dollv4 PASS a ring dropped on its slot is taken | rect 124,583 25x25 clip 0,65 815x585
ZEDQA dollv4 PASS the ring was put on (vanilla's wear action ran)
ZEDQA dollv4 PASS the cap was put on
ZEDQA dollv4 PASS narrow: bands folded | drawer 385px = 220 units, screen 3840x2160
ZEDQA dollv4 PASS narrow: 11 big slot boxes, no small ones | 11
ZEDQA dollv4 PASS narrow: no slot overlaps another
ZEDQA dollv4 PASS narrow: every box inside the drawer's width | 385
ZEDQA dollv4 PASS narrow: the drawer is no wider than the full card (480 units) | 220.0 units
ZEDQA dollv4 PASS narrow: 11 leader lines, none crossing another | 11 lines, 0 crossings
ZEDQA dollv4 PASS narrow: Back, Arms, Belt in that order down the right | 65,247,338
ZEDQA dollv4 PASS narrow: arms' line is one straight run, belt's turns up | 4/8
ZEDQA dollv4 PASS narrow: every worn thing lands in its big slot (20 on) |
ZEDQA dollv4 PASS narrow: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS narrow: no small-slot zone left | 0
ZEDQA dollv4 narrow: Arms layers 3, Back 2, Legs 5, Belt 4, Hands 4
ZEDQA dollv4 PASS narrow: Back's card shows the folded layers (tail, satchel) | layers 2
ZEDQA dollv4 short: window 735 -> 1126 px (view 585, doll at full size 1221)
ZEDQA dollv4 PASS short: the bands still show
ZEDQA dollv4 PASS short: the small slots shrank (under 18 units, 14 or more) | 16.0 units
ZEDQA dollv4 PASS short: the doll fits its view, no scrolling to reach it | 976 in 976
ZEDQA dollv4 PASS short: no slot overlaps another
ZEDQA dollv4 PASS short: 49 slot boxes | 49
ZEDQA dollv4 passed 64, failed 0 | DONE
```

### 6. zedqa_curtain.lua (`ZEDQA cu`) - PASS, 133 s

- go 16325 at 09:07:58
- screenshots: zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cu start
[ZeD.QA] run #6 ok=true
ZEDQA cu loaded: Character 1134,0 777x735 rolled nil (saved -) | World 1929,0 777x735 rolled nil (saved -)
ZEDQA cu scale 1.75 root 1.75 screen 3840x2160
ZEDQA cu reset: ZeD_Window.resetLayout
ZEDQA cu reset: Character 1134,0 777x735 rolled nil (saved -) | World 1929,0 777x735 rolled nil (saved -)
ZEDQA cu before: x 1929 w 1617 title Ground + Maps button 244.94140625,11 23
ZEDQA cu rolled true: x 2643 w 903 (sum 3546 was 3546) rod 1929,0 714x46 content false title Maps
ZEDQA cu pad stops: worldContainerStrip:curtain:unroll
ZEDQA cu A on the tab
ZEDQA cu unrolled true: x 1929 w 1617 content true rod false
ZEDQA cu ok first roll World 1929,0 1617x735
ZEDQA cu rolled again true
ZEDQA cu tab closed: rolled false x 1929 w 777 content true drawer false
ZEDQA cu ok tab closed while rolled World 1929,0 777x735
ZEDQA cu World before: 1929,0 1617x735 (other 1134,0 777x735) drawer true tab tab maps
ZEDQA cu cycle1 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World rollW 714
ZEDQA cu ok cycle1 rolled World rod flush at 1929,0 714x46
ZEDQA cu ok cycle1 rolled World 2643,0 903x735
ZEDQA cu ok cycle1 while rolled: other Character 1134,0 777x735
ZEDQA cu cycle1 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle1 World 1929,0 1617x735
ZEDQA cu ok cycle1 other (Character) 1134,0 777x735
ZEDQA cu ok cycle1 World saved 1102.286,0.000 444.000x420.000
ZEDQA cu cycle2 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World rollW 714
ZEDQA cu ok cycle2 rolled World rod flush at 1929,0 714x46
ZEDQA cu ok cycle2 rolled World 2643,0 903x735
ZEDQA cu ok cycle2 while rolled: other Character 1134,0 777x735
ZEDQA cu cycle2 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle2 World 1929,0 1617x735
ZEDQA cu ok cycle2 other (Character) 1134,0 777x735
ZEDQA cu ok cycle2 World saved 1102.286,0.000 444.000x420.000
ZEDQA cu moved by rod World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World rollW 714
ZEDQA cu ok moved by rod rolled World rod flush at 1929,0 714x46
ZEDQA cu ok moved by rod rolled World 2643,0 903x735
ZEDQA cu ok moved by rod while rolled: other Character 1134,0 777x735
ZEDQA cu moved by rod World moved by 200,200 (rod) to 2843,200 903x735
ZEDQA cu ok moved by rod moved World rod flush at 2129,200 714x46
ZEDQA cu moved by rod World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2843,200 903x735 rolled true (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2129,200 1617x735 rolled false (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by rod World 2129,200 1617x735
ZEDQA cu ok moved by rod other (Character) 1134,0 777x735
ZEDQA cu ok moved by rod World saved 1216.571,114.286 444.000x420.000
ZEDQA cu moved by title World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2129,200 1617x735 rolled false (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2843,200 903x735 rolled true (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World rollW 714
ZEDQA cu ok moved by title rolled World rod flush at 2129,200 714x46
ZEDQA cu ok moved by title rolled World 2843,200 903x735
ZEDQA cu ok moved by title while rolled: other Character 1134,0 777x735
ZEDQA cu moved by title World moved by -200,200 (title) to 2643,400 903x735
ZEDQA cu ok moved by title moved World rod flush at 1929,400 714x46
ZEDQA cu moved by title World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 903x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by title World 1929,400 1617x735
ZEDQA cu ok moved by title other (Character) 1134,0 777x735
ZEDQA cu ok moved by title World saved 1102.286,228.571 444.000x420.000
ZEDQA cu cycle5 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 903x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World rollW 714
ZEDQA cu ok cycle5 rolled World rod flush at 1929,400 714x46
ZEDQA cu ok cycle5 rolled World 2643,400 903x735
ZEDQA cu ok cycle5 while rolled: other Character 1134,0 777x735
ZEDQA cu cycle5 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 903x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle5 World 1929,400 1617x735
ZEDQA cu ok cycle5 other (Character) 1134,0 777x735
ZEDQA cu ok cycle5 World saved 1102.286,228.571 444.000x420.000
ZEDQA cu character health tab true
ZEDQA cu Character before: 294,0 1617x735 (other 1929,400 1617x735) drawer true tab tab health
ZEDQA cu cycle1 Character before roll: Character 294,0 1617x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character rollW 714
ZEDQA cu ok cycle1 rolled Character rod flush at 1197,0 714x46
ZEDQA cu ok cycle1 rolled Character 294,0 903x735
ZEDQA cu ok cycle1 while rolled: other World 1929,400 1617x735
ZEDQA cu cycle1 Character rolled, before unroll: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character unrolled: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle1 Character 294,0 1617x735
ZEDQA cu ok cycle1 other (World) 1929,400 1617x735
ZEDQA cu ok cycle1 Character saved 648.000,0.000 444.000x420.000
ZEDQA cu cycle2 Character before roll: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character rollW 714
ZEDQA cu ok cycle2 rolled Character rod flush at 1197,0 714x46
ZEDQA cu ok cycle2 rolled Character 294,0 903x735
ZEDQA cu ok cycle2 while rolled: other World 1929,400 1617x735
ZEDQA cu cycle2 Character rolled, before unroll: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character unrolled: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle2 Character 294,0 1617x735
ZEDQA cu ok cycle2 other (World) 1929,400 1617x735
ZEDQA cu ok cycle2 Character saved 648.000,0.000 444.000x420.000
ZEDQA cu moved by rod Character before roll: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character rollW 714
ZEDQA cu ok moved by rod rolled Character rod flush at 1197,0 714x46
ZEDQA cu ok moved by rod rolled Character 294,0 903x735
ZEDQA cu ok moved by rod while rolled: other World 1929,400 1617x735
ZEDQA cu moved by rod Character moved by 200,200 (rod) to 494,200 903x735
ZEDQA cu ok moved by rod moved Character rod flush at 1397,200 714x46
ZEDQA cu moved by rod Character rolled, before unroll: Character 494,200 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character unrolled: Character 494,200 1617x735 rolled false (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by rod Character 494,200 1617x735
ZEDQA cu ok moved by rod other (World) 1929,400 1617x735
ZEDQA cu ok moved by rod Character saved 762.286,114.286 444.000x420.000
ZEDQA cu moved by title Character before roll: Character 494,200 1617x735 rolled false (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character rolled: Character 494,200 903x735 rolled true (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character rollW 714
ZEDQA cu ok moved by title rolled Character rod flush at 1397,200 714x46
ZEDQA cu ok moved by title rolled Character 494,200 903x735
ZEDQA cu ok moved by title while rolled: other World 1929,400 1617x735
ZEDQA cu moved by title Character moved by 200,200 (title) to 694,400 903x735
ZEDQA cu ok moved by title moved Character rod flush at 1597,400 714x46
ZEDQA cu moved by title Character rolled, before unroll: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by title Character 694,400 1617x735
ZEDQA cu ok moved by title other (World) 1929,400 1617x735
ZEDQA cu ok moved by title Character saved 876.571,228.571 444.000x420.000
ZEDQA cu cycle5 Character before roll: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character rolled: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character rollW 714
ZEDQA cu ok cycle5 rolled Character rod flush at 1597,400 714x46
ZEDQA cu ok cycle5 rolled Character 694,400 903x735
ZEDQA cu ok cycle5 while rolled: other World 1929,400 1617x735
ZEDQA cu cycle5 Character rolled, before unroll: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle5 Character 694,400 1617x735
ZEDQA cu ok cycle5 other (World) 1929,400 1617x735
ZEDQA cu ok cycle5 Character saved 876.571,228.571 444.000x420.000
ZEDQA cu closed rolled (inventory key) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) reference back on its tab World 1929,400 1617x735
ZEDQA cu closed rolled (inventory key) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (inventory key) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (inventory key) World window closed
ZEDQA cu ok closed rolled (inventory key) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (inventory key) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (inventory key) reopened as unrolled World 1929,400 777x735
ZEDQA cu ok closed rolled (inventory key) reopened: other Character 694,400 1617x735
ZEDQA cu closed rolled (rod close box) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (rod close box) reference back on its tab World 1929,400 1617x735
ZEDQA cu closed rolled (rod close box) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (rod close box) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (rod close box) World window closed
ZEDQA cu ok closed rolled (rod close box) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (rod close box) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (rod close box) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (rod close box) reopened as unrolled World 1929,400 777x735
ZEDQA cu ok closed rolled (rod close box) reopened: other Character 694,400 1617x735
ZEDQA cu closed rolled (controller Y hold) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab World 1929,400 1617x735
ZEDQA cu closed rolled (controller Y hold) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (controller Y hold) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (controller Y hold) World window closed
ZEDQA cu ok closed rolled (controller Y hold) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (controller Y hold) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled World 1929,400 777x735
ZEDQA cu ok closed rolled (controller Y hold) reopened: other Character 694,400 1617x735
ZEDQA cu closed rolled (inventory key) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) reference back on its tab Character 694,400 1617x735
ZEDQA cu closed rolled (inventory key) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (inventory key) Character window closed
ZEDQA cu ok closed rolled (inventory key) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (inventory key) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (inventory key) reopened as unrolled Character 694,400 1617x735
ZEDQA cu ok closed rolled (inventory key) reopened: other World 1929,400 777x735
ZEDQA cu closed rolled (close box) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) reference back on its tab Character 694,400 1617x735
ZEDQA cu closed rolled (close box) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (close box) Character window closed
ZEDQA cu ok closed rolled (close box) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (close box) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (close box) reopened as unrolled Character 694,400 1617x735
ZEDQA cu ok closed rolled (close box) reopened: other World 1929,400 777x735
ZEDQA cu closed rolled (controller Y hold) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab Character 694,400 1617x735
ZEDQA cu closed rolled (controller Y hold) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (controller Y hold) Character window closed
ZEDQA cu ok closed rolled (controller Y hold) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (controller Y hold) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled Character 694,400 1617x735
ZEDQA cu ok closed rolled (controller Y hold) reopened: other World 1929,400 777x735
ZEDQA cu World tabs: on maps 1929,400 1617x735 (other 694,400 1617x735)
ZEDQA cu ok tab forage reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab forage World rolled before the press
ZEDQA cu ok tab forage World still rolled on the tab (tab forage)
ZEDQA cu ok tab forage rolled World 2643,400 903x735
ZEDQA cu ok tab forage World unrolled (rods in UI 0)
ZEDQA cu ok tab forage unrolled World 1929,400 1617x735
ZEDQA cu ok tab forage unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab forage back on maps World 1929,400 1617x735
ZEDQA cu ok tab craft reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab craft World rolled before the press
ZEDQA cu ok tab craft World still rolled on the tab (tab craft)
ZEDQA cu ok tab craft rolled World 2643,400 903x735
ZEDQA cu ok tab craft World unrolled (rods in UI 0)
ZEDQA cu ok tab craft unrolled World 1929,400 1617x735
ZEDQA cu ok tab craft unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab craft back on maps World 1929,400 1617x735
ZEDQA cu ok tab build reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab build World rolled before the press
ZEDQA cu ok tab build World still rolled on the tab (tab build)
ZEDQA cu ok tab build rolled World 2643,400 903x735
ZEDQA cu ok tab build World unrolled (rods in UI 0)
ZEDQA cu ok tab build unrolled World 1929,400 1617x735
ZEDQA cu ok tab build unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab build back on maps World 1929,400 1617x735
ZEDQA cu ok tab furniture reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab furniture World rolled before the press
ZEDQA cu ok tab furniture World still rolled on the tab (tab furniture)
ZEDQA cu ok tab furniture rolled World 2643,400 903x735
ZEDQA cu ok tab furniture World unrolled (rods in UI 0)
ZEDQA cu ok tab furniture unrolled World 1929,400 1617x735
ZEDQA cu ok tab furniture unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab furniture back on maps World 1929,400 1617x735
ZEDQA cu ok tab animals reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab animals World rolled before the press
ZEDQA cu ok tab animals World still rolled on the tab (tab animals)
ZEDQA cu ok tab animals rolled World 2643,400 903x735
ZEDQA cu ok tab animals World unrolled (rods in UI 0)
ZEDQA cu ok tab animals unrolled World 1929,400 1617x735
ZEDQA cu ok tab animals unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab animals back on maps World 1929,400 1617x735
ZEDQA cu tab radio World: not shown here, skipped
ZEDQA cu ok tab vehicle reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab vehicle World rolled before the press
ZEDQA cu ok tab vehicle World still rolled on the tab (tab vehicle)
ZEDQA cu ok tab vehicle rolled World 2643,400 903x735
ZEDQA cu ok tab vehicle World unrolled (rods in UI 0)
ZEDQA cu ok tab vehicle unrolled World 1929,400 1617x735
ZEDQA cu ok tab vehicle unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab vehicle back on maps World 1929,400 1617x735
ZEDQA cu ok forage and back World still rolled (tab maps)
ZEDQA cu ok forage and back rolled World 2643,400 903x735
ZEDQA cu ok forage and back, unrolled World 1929,400 1617x735
ZEDQA cu World Loot (unrolled) 1929,400 777x735
ZEDQA cu ok Loot reference, back on maps World 1929,400 1617x735
ZEDQA cu ok Loot World rolled before the press
ZEDQA cu World Loot press not delivered by the window's update after 10 ticks; checked 30 ticks later
ZEDQA cu ok Loot World side down with the press (rolled false tab loot rods in UI 0)
ZEDQA cu ok Loot while rolled World 1929,400 777x735
ZEDQA cu ok Loot while rolled: other Character 694,400 1617x735
ZEDQA cu ok Loot while rolled, back on maps World 1929,400 1617x735
ZEDQA cu ok maps again World rolled before the press
ZEDQA cu ok maps again World side down (rolled false)
ZEDQA cu ok maps pressed again while rolled World 1929,400 777x735
ZEDQA cu ok maps again, back on maps World 1929,400 1617x735
ZEDQA cu Character tabs: on health 694,400 1617x735 (other 1929,400 1617x735)
ZEDQA cu ok tab skills reference, back on health Character 694,400 1617x735
ZEDQA cu ok tab skills Character rolled before the press
ZEDQA cu ok tab skills Character still rolled on the tab (tab skills)
ZEDQA cu ok tab skills rolled Character 694,400 903x735
ZEDQA cu ok tab skills Character unrolled (rods in UI 0)
ZEDQA cu ok tab skills unrolled Character 694,400 1617x735
ZEDQA cu ok tab skills unrolled: other World 1929,400 1617x735
ZEDQA cu ok tab skills back on health Character 694,400 1617x735
ZEDQA cu ok tab equip reference, back on health Character 694,400 1617x735
ZEDQA cu ok tab equip Character rolled before the press
ZEDQA cu ok tab equip Character still rolled on the tab (tab equip)
ZEDQA cu ok tab equip rolled Character 694,400 903x735
ZEDQA cu ok tab equip Character unrolled (rods in UI 0)
ZEDQA cu ok tab equip unrolled Character 694,400 1617x735
ZEDQA cu ok tab equip unrolled: other World 1929,400 1617x735
ZEDQA cu ok tab equip back on health Character 694,400 1617x735
ZEDQA cu ok tab thermal reference, back on health Character 694,400 1617x735
ZEDQA cu ok tab thermal Character rolled before the press
ZEDQA cu ok tab thermal Character still rolled on the tab (tab thermal)
ZEDQA cu ok tab thermal rolled Character 694,400 903x735
ZEDQA cu ok tab thermal Character unrolled (rods in UI 0)
ZEDQA cu ok tab thermal unrolled Character 694,400 1617x735
ZEDQA cu ok tab thermal unrolled: other World 1929,400 1617x735
ZEDQA cu ok tab thermal back on health Character 694,400 1617x735
ZEDQA cu ok tab identity reference, back on health Character 694,400 1617x735
ZEDQA cu ok tab identity Character rolled before the press
ZEDQA cu ok tab identity Character still rolled on the tab (tab identity)
ZEDQA cu ok tab identity rolled Character 694,400 903x735
ZEDQA cu ok tab identity Character unrolled (rods in UI 0)
ZEDQA cu ok tab identity unrolled Character 694,400 1617x735
ZEDQA cu ok tab identity unrolled: other World 1929,400 1617x735
ZEDQA cu ok tab identity back on health Character 694,400 1617x735
ZEDQA cu ok tab journal reference, back on health Character 694,400 1617x735
ZEDQA cu ok tab journal Character rolled before the press
ZEDQA cu ok tab journal Character still rolled on the tab (tab journal)
ZEDQA cu ok tab journal rolled Character 694,400 903x735
ZEDQA cu ok tab journal Character unrolled (rods in UI 0)
ZEDQA cu ok tab journal unrolled Character 694,400 1617x735
ZEDQA cu ok tab journal unrolled: other World 1929,400 1617x735
ZEDQA cu ok tab journal back on health Character 694,400 1617x735
ZEDQA cu tab radio Character: not shown here, skipped
ZEDQA cu ok skills and back Character still rolled (tab health)
ZEDQA cu ok skills and back rolled Character 694,400 903x735
ZEDQA cu ok skills and back, unrolled Character 694,400 1617x735
ZEDQA cu Character Loot (unrolled) 1534,400 777x735
ZEDQA cu ok Loot reference, back on health Character 694,400 1617x735
ZEDQA cu ok Loot Character rolled before the press
ZEDQA cu ok Loot Character side down with the press (rolled false tab loot rods in UI 0)
ZEDQA cu ok Loot while rolled Character 1534,400 777x735
ZEDQA cu ok Loot while rolled: other World 1929,400 1617x735
ZEDQA cu ok Loot while rolled, back on health Character 694,400 1617x735
ZEDQA cu ok health again Character rolled before the press
ZEDQA cu ok health again Character side down (rolled false)
ZEDQA cu ok health pressed again while rolled Character 1534,400 777x735
ZEDQA cu ok health again, back on health Character 694,400 1617x735
ZEDQA cu geometry checks 222, differences 0
ZEDQA cu at quit, unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu at quit, rolled: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 2643,400 903x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu DONE
```

### 7. zedqa_lists.lua (`ZEDQA ls`) - PASS, 14 s

- go 16326 at 09:10:14
- screenshots: zqa_ls_01_page_480.png, zqa_ls_02_page_480_lines.png, zqa_ls_03_stepper.png, zqa_ls_04_ask_delete.png, zqa_ls_05_rightclick_list.png, zqa_ls_06_rightclick_strip.png, zqa_ls_07_card_inlists.png, zqa_ls_08_mark_popup.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ls start
[ZeD.QA] run #7 ok=true
ZEDQA ls items: crowbar true water 0.800000011920929
ZEDQA ls ok crowbar is gear (inv, any)
ZEDQA ls ok bandages are a fixed supply
ZEDQA ls carry: 17 lines, gear 12 supply 5
ZEDQA ls ok save what I carry: the crowbar
ZEDQA ls ok save what I carry: bandages grouped (3)
ZEDQA ls ok save what I carry: water in litres (1)
ZEDQA ls ok save what I wear: 6 lines for 6 worn non-bags
ZEDQA ls ok outfit lines: worn, any, at their location
ZEDQA ls ok create
ZEDQA ls ok rename
ZEDQA ls ok toggle on: one line
ZEDQA ls ok listsWith: the crowbar is in 2 lists
ZEDQA ls ok toggle off: no lines
ZEDQA ls ok outfits: wearables only
ZEDQA ls ok delete
ZEDQA ls ok This one
ZEDQA ls ok Any
ZEDQA ls ok A day
ZEDQA ls ok amount 2
ZEDQA ls ok resolve: bandages on you for 1 day (have 3)
ZEDQA ls ok resolve: 3 days need 6, not ready
ZEDQA ls ok resolve: the crowbar in its place (inv)
ZEDQA ls ready 16 of 17
ZEDQA ls ok store is plain values
ZEDQA ls ok round trip 2:17:QA carry
ZEDQA ls page: drawer 840 stacked true zones 63
ZEDQA ls ok the page's buttons, filter and list rows
ZEDQA ls ok the chosen list's Rename / Add / Delete
ZEDQA ls stops 14: jl:filter,jl:carry,jl:wear,jl:new,jl:sec:loadout,jl:list:1,jl:sec:outfit,jl:list:2,jl:rename,jl:add,jl:delete,jl:lsec:gear,jl:sw:1,jl:line:1
ZEDQA ls ok full card: the panes stack (drawer 840 px, 480u = 840)
ZEDQA ls switch on: Digital Watch
ZEDQA ls ok page: the switch's right half sets This one
ZEDQA ls ok page: the left half sets Any
ZEDQA ls amount on: Digital Watch
ZEDQA ls ok page: the amount opens a stepper
ZEDQA ls ok page: + adds one (2)
ZEDQA ls ok page: the pad's left takes one off (1)
ZEDQA ls ok page: pressing the amount again closes the stepper
ZEDQA ls ok page: Remove takes the line off (16)
ZEDQA ls doomed 4
ZEDQA ls ok Delete asks first
ZEDQA ls ok the question's two answers are the only stops (jl:ask:cancel,jl:ask:verb)
ZEDQA ls ok Delete in the band deletes
ZEDQA ls list look: Attach, Place Item, Favorite, Set Unwanted, Move to, |, Craft, Set to be Unusable in Recipes, |, Equip in Both Hands, Equip Primary, Equip Secondary, |, Drop, |, Save to loadout, |, Rename
ZEDQA ls ok list look: Save to loadout
ZEDQA ls submenu: QA carry [x], |, New loadout...
ZEDQA ls ok list look: QA carry checked (the crowbar is on it)
ZEDQA ls ok list look: picking a checked list takes the item out
ZEDQA ls ok strip: Save to loadout drills into the names
ZEDQA ls ok strip: QA carry unchecked now
ZEDQA ls ok strip: picking it puts the item back on
ZEDQA ls ok Save to outfit only for wearables
ZEDQA ls card open true
ZEDQA ls ok mark strip: Lists lit (in 1 loadout)
ZEDQA ls ok mark strip: the Lists button is drawn
ZEDQA ls ok mark strip: the Lists button is a pad stop
ZEDQA ls pop-up: Loadouts (head), QA carry [x], |, New loadout with it..., |, Outfits: only for things you wear (head)
ZEDQA ls ok mark strip: the pop-up opens
ZEDQA ls ok pop-up: a tick takes it off and stays open
ZEDQA ls ok pop-up: ticked again, back on
ZEDQA ls DONE (0 failed)
```

### 8. zedqa_restock.lua (`ZEDQA rst`) - PASS, 54 s

- go 16327 at 09:10:32
- screenshots: zqa_rst_01_bar_ghosts.png, zqa_rst_02_todo.png, zqa_rst_02b_todo_lines.png, zqa_rst_03_ask_band.png, zqa_rst_04_after_hardcore.png, zqa_rst_05_pin_accessible.png, zqa_rst_06_pin_casual.png, zqa_rst_07_long_trip.png, zqa_rst_07b_long_trip_table.png, zqa_rst_08_unpack.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rst start
[ZeD.QA] run #8 ok=true
ZEDQA rst fixture: building 875,12964, standing at 885,13029 (18 from 892,13040)
ZEDQA rst built: crateA true crateB true locker true crateF true
ZEDQA rst set aside: 1 things holding water, 0 katanas
ZEDQA rst stocked: hat Base.Hat_Fedora at hat, locker locked true
ZEDQA rst bandages in the building: 3
ZEDQA rst bar zones: fold,outfit,loadout,days:dec,days:inc,days,save,verb,ready
ZEDQA rst ok the bar draws in the Loadouts fold (opened above)
ZEDQA rst ok ready 1 of 6 (the screwdriver on you, of 6 lines)
ZEDQA rst ok outfit worn 0 of 1
ZEDQA rst ghosts: head,main
ZEDQA rst ok a ghost in the main hand (the axe)
ZEDQA rst ok a ghost at head (the hat)
ZEDQA rst states: Fedora=take@Crate | Hatchet=take@Crate | Screwdriver=on@nil | Bandage=ask@Cupboard | Water=fill@Sink | Katana=none@nil | Crowbar=take@Crate
ZEDQA rst ok on you: on
ZEDQA rst ok take from a container: take
ZEDQA rst ok fill at a tap: fill
ZEDQA rst ok ask first: the last bandages in the building: ask
ZEDQA rst ok none in the building (the katana is only in the locked locker): none
ZEDQA rst ok the axe is taken from crate A (Crate)
ZEDQA rst ok the to-do is open in the drawer
ZEDQA rst ok the drawer stays the full card (840 <= 840)
ZEDQA rst ok one bandage left behind: no question (take)
ZEDQA rst ok pressing the ask line puts the question in the band
ZEDQA rst ok the question's two answers are the only stops: el:ask:cancel,el:ask:verb
ZEDQA rst ok answered Take it: the bandages are to take (take)
ZEDQA rst ok the setting: Hardcore
ZEDQA rst hardcore queued 6: ISInventoryTransferAction,ISWearClothing,ISInventoryTransferAction,ISEquipWeaponAction,ISInventoryTransferAction,ISInventoryTransferAction
ZEDQA rst ok the time on the button 0:03 is the queued actions' 0:03
ZEDQA rst ok hardcore queued the takes in reach
ZEDQA rst hardcore ran 3.2 s real for 3.2 s estimated (1.00 real s per estimated s)
ZEDQA rst ok the axe in the main hand
ZEDQA rst ok the Fedora worn
ZEDQA rst ok the katana is still in the locked locker
ZEDQA rst ok the far crate's crowbar was not taken (not in reach)
ZEDQA rst ok a key stops the run (key)
ZEDQA rst ok the queue is cancelled
ZEDQA rst zombie spawned true
ZEDQA rst ok a zombie coming into view stops the run (zombie, visible 1)
ZEDQA rst ok getting hurt stops the run (hurt)
ZEDQA rst accessible: 2 stops, 8 actions
ZEDQA rst ok the route goes to crate A and the far crate
ZEDQA rst walking line: Walking to 2 of 2 | 0:09 left
ZEDQA rst ok the pinned list says where it walks
ZEDQA rst ok the to-do is pinned at the screen edge
ZEDQA rst ok the walk finished (nil)
ZEDQA rst ok the far crate's crowbar taken on the walk
ZEDQA rst ok back where it was pressed (0.0 squares off)
ZEDQA rst ok the katana is still in the locked locker
ZEDQA rst ok casual: the far crate's crowbar waits until it is in reach
ZEDQA rst ok casual: the to-do is pinned
ZEDQA rst notice: Crowbar from the Crate
ZEDQA rst ok casual: a notice names the crowbar and where from
ZEDQA rst ok casual: done when the list is empty
ZEDQA rst long haul: 13.1 of 18.0 carried, water 1.5 L a day
ZEDQA rst ok 5 days is over the limit (by 2.9)
ZEDQA rst ok the heaviest supply named: Water
ZEDQA rst ok the most days that fit: 3
ZEDQA rst ok Make it N days is offered
ZEDQA rst ok Make it 3 days fits
ZEDQA rst ok home: the building where you last restocked (875,12964)
ZEDQA rst loot: beans x2, odd Base.Harmonica (Instrument)
ZEDQA rst ok back home with things from a trip: Unpack is offered
ZEDQA rst ok loot goes where its kind lives: beans to Crate
ZEDQA rst ok a kind with no home asks for a place (pick)
ZEDQA rst ok leftover food that spoils within 2 days goes back (put)
ZEDQA rst ok leftover supplies stay packed (stay)
ZEDQA rst ok stays on you: T-shirt, Jeans, Socks - Heavy, Military Boots, Leather Gloves, Belt, Digital Watch, Prescription Aviator Glasses, Nails, Cigarette Pack, JS-2000 Shotgun, Flier: Fossoil (West Point): Fossoil (West Point), Water Bottle, Book: "The Omega Department Guide (Unofficial)", by Napoleon Trejo, Baseball Bat, CD, CD: Moon Madness, Screwdriver, Fedora, Hatchet, Crowbar
ZEDQA rst ok the to-do's first button is Unpack, live
ZEDQA rst ok the kind's place is kept: Crate
ZEDQA rst ok a second of that kind goes there without asking
ZEDQA rst ok unpack put both in crate A
ZEDQA rst ok the gear stays on you
ZEDQA rst ok the Character wheel has a live Loadouts ring
ZEDQA rst ok one slice per loadout: QA restock, QA long haul
ZEDQA rst ok a slice sets the loadout and opens its to-do
ZEDQA rst ok the to-do's Restock is a stop with A and B
ZEDQA rst ok the focus lands on Restock (the primary): el:v1
ZEDQA rst ok A restocks
ZEDQA rst ok B goes back
ZEDQA rst ok the focus is back on ready n of m (where the to-do came from): el:ready
ZEDQA rst put back: 16 made things removed, 4 built things taken down, 1 set-aside things returned
ZEDQA rst ok nothing the run made is left on the character (0)
ZEDQA rst DONE (0 failed)
```

### 9. zedqa_reader.lua (`ZEDQA rd`) - PASS, 10 s

- go 16328 at 09:11:29
- screenshots: zqa_rd_01_paper.png, zqa_rd_02_words.png, zqa_rd_03_story2.png, zqa_rd_04_zoomed.png, zqa_rd_05_flier.png, zqa_rd_06_map.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rd start
[ZeD.QA] run #9 ok=true
ZEDQA rd light after 3 ticks: tooDark false
ZEDQA rd open true view paper body 27.884615384615387
ZEDQA rd words blocks 12
ZEDQA rd flier places 1
ZEDQA rd map centre 10687,9831
ZEDQA rd DONE
```

### 10. zedqa_two_widths.lua (`ZEDQA tww`) - PASS, 70 s

- go 16329 at 09:11:42
- screenshots: zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tww start
[ZeD.QA] run #10 ok=true
ZEDQA tww screen 3840x2160, root 1.75, half card 385 px, full card 840 px
ZEDQA tww to the deep run's home, 10608,11151
ZEDQA tww the pair at the start: Character 1134,0 777x735, World 1929,0 777x735
ZEDQA tww PASS the pair starts apart
ZEDQA tww 13 tab cases
ZEDQA tww Character equip: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character equip: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character equip: it is the full card (full)
ZEDQA tww PASS Character equip: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character equip: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character equip: both windows are on the screen
ZEDQA tww PASS Character equip: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character equip: closed, the other window is where it was
ZEDQA tww Character health: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character health: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character health: it is the full card (full)
ZEDQA tww PASS Character health: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character health: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character health: both windows are on the screen
ZEDQA tww PASS Character health: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character health: closed, the other window is where it was
ZEDQA tww Character thermal: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character thermal: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character thermal: it is the full card (full)
ZEDQA tww PASS Character thermal: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character thermal: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character thermal: both windows are on the screen
ZEDQA tww PASS Character thermal: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character thermal: closed, the other window is where it was
ZEDQA tww Character identity: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character identity: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character identity: it is the full card (full)
ZEDQA tww PASS Character identity: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character identity: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character identity: both windows are on the screen
ZEDQA tww PASS Character identity: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character identity: closed, the other window is where it was
ZEDQA tww Character journal: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character journal: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character journal: it is the full card (full)
ZEDQA tww PASS Character journal: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character journal: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character journal: both windows are on the screen
ZEDQA tww PASS Character journal: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character journal: closed, the other window is where it was
ZEDQA tww Character skills: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character skills: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character skills: it is the full card (full)
ZEDQA tww PASS Character skills: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character skills: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character skills: both windows are on the screen
ZEDQA tww PASS Character skills: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character skills: closed, the other window is where it was
ZEDQA tww World craft: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World craft: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World craft: it is the full card (full)
ZEDQA tww PASS World craft: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World craft: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World craft: both windows are on the screen
ZEDQA tww PASS World craft: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World craft: closed, the other window is where it was
ZEDQA tww World build: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World build: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World build: it is the full card (full)
ZEDQA tww PASS World build: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World build: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World build: both windows are on the screen
ZEDQA tww PASS World build: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World build: closed, the other window is where it was
ZEDQA tww World furniture: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World furniture: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World furniture: it is the full card (full)
ZEDQA tww PASS World furniture: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World furniture: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World furniture: both windows are on the screen
ZEDQA tww PASS World furniture: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World furniture: closed, the other window is where it was
ZEDQA tww World maps: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World maps: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World maps: it is the full card (full)
ZEDQA tww PASS World maps: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World maps: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World maps: both windows are on the screen
ZEDQA tww PASS World maps: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World maps: closed, the other window is where it was
ZEDQA tww World forage: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World forage: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World forage: it is the full card (full)
ZEDQA tww PASS World forage: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World forage: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World forage: both windows are on the screen
ZEDQA tww PASS World forage: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World forage: closed, the other window is where it was
ZEDQA tww World animals: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World animals: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World animals: it is the full card (full)
ZEDQA tww PASS World animals: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World animals: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World animals: both windows are on the screen
ZEDQA tww PASS World animals: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World animals: closed, the other window is where it was
ZEDQA tww World vehicle: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World vehicle: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World vehicle: it is the full card (full)
ZEDQA tww PASS World vehicle: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World vehicle: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World vehicle: both windows are on the screen
ZEDQA tww PASS World vehicle: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World vehicle: closed, the other window is where it was
ZEDQA tww an oven placed: true
ZEDQA tww a generator placed: true
ZEDQA tww a ham set placed: true
ZEDQA tww 25 more cases
ZEDQA tww Character Equip to-do: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Equip to-do: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Equip to-do: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Equip to-do: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Equip to-do: both windows are on the screen
ZEDQA tww PASS Character Equip to-do: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Equip to-do: closed, the other window is where it was
ZEDQA tww Character Journal Loadouts page: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal Loadouts page: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal Loadouts page: it is the full card (full)
ZEDQA tww PASS Character Journal Loadouts page: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal Loadouts page: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal Loadouts page: both windows are on the screen
ZEDQA tww PASS Character Journal Loadouts page: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal Loadouts page: closed, the other window is where it was
ZEDQA tww Character Journal page 1: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal page 1: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal page 1: it is the full card (full)
ZEDQA tww PASS Character Journal page 1: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal page 1: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal page 1: both windows are on the screen
ZEDQA tww PASS Character Journal page 1: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal page 1: closed, the other window is where it was
ZEDQA tww Character Journal page 2: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal page 2: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal page 2: it is the full card (full)
ZEDQA tww PASS Character Journal page 2: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal page 2: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal page 2: both windows are on the screen
ZEDQA tww PASS Character Journal page 2: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal page 2: closed, the other window is where it was
ZEDQA tww Character Journal page 3: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal page 3: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal page 3: it is the full card (full)
ZEDQA tww PASS Character Journal page 3: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal page 3: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal page 3: both windows are on the screen
ZEDQA tww PASS Character Journal page 3: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal page 3: closed, the other window is where it was
ZEDQA tww Character Journal page 4: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal page 4: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal page 4: it is the full card (full)
ZEDQA tww PASS Character Journal page 4: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal page 4: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal page 4: both windows are on the screen
ZEDQA tww PASS Character Journal page 4: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal page 4: closed, the other window is where it was
ZEDQA tww Character Journal page 5: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal page 5: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal page 5: it is the full card (full)
ZEDQA tww PASS Character Journal page 5: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal page 5: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal page 5: both windows are on the screen
ZEDQA tww PASS Character Journal page 5: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal page 5: closed, the other window is where it was
ZEDQA tww World item card: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1162x735
ZEDQA tww PASS World item card: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS World item card: it is the half card (half)
ZEDQA tww PASS World item card: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World item card: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World item card: both windows are on the screen
ZEDQA tww PASS World item card: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World item card: closed, the other window is where it was
ZEDQA tww Character item card: drawer 385 px = half | Character 749,0 1162x735 | World 1929,0 777x735
ZEDQA tww PASS Character item card: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS Character item card: it is the half card (half)
ZEDQA tww PASS Character item card: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character item card: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character item card: both windows are on the screen
ZEDQA tww PASS Character item card: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character item card: closed, the other window is where it was
ZEDQA tww World object card fluid: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World object card fluid: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World object card fluid: it is the full card (full)
ZEDQA tww PASS World object card fluid: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World object card fluid: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World object card fluid: both windows are on the screen
ZEDQA tww PASS World object card fluid: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World object card fluid: closed, the other window is where it was
ZEDQA tww World object card generator: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World object card generator: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World object card generator: it is the full card (full)
ZEDQA tww PASS World object card generator: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World object card generator: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World object card generator: both windows are on the screen
ZEDQA tww PASS World object card generator: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World object card generator: closed, the other window is where it was
ZEDQA tww World object card place3d: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World object card place3d: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World object card place3d: it is the full card (full)
ZEDQA tww PASS World object card place3d: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World object card place3d: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World object card place3d: both windows are on the screen
ZEDQA tww PASS World object card place3d: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World object card place3d: closed, the other window is where it was
ZEDQA tww World Craft at an oven: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World Craft at an oven: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World Craft at an oven: it is the full card (full)
ZEDQA tww PASS World Craft at an oven: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World Craft at an oven: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World Craft at an oven: both windows are on the screen
ZEDQA tww PASS World Craft at an oven: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World Craft at an oven: closed, the other window is where it was
ZEDQA tww World Craft (no station): drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World Craft (no station): the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World Craft (no station): it is the full card (full)
ZEDQA tww PASS World Craft (no station): the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World Craft (no station): the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World Craft (no station): both windows are on the screen
ZEDQA tww PASS World Craft (no station): closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World Craft (no station): closed, the other window is where it was
ZEDQA tww Character Radio (a walkie): drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Radio (a walkie): the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Radio (a walkie): the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Radio (a walkie): the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Radio (a walkie): both windows are on the screen
ZEDQA tww PASS Character Radio (a walkie): closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Radio (a walkie): closed, the other window is where it was
ZEDQA tww World Radio (a ham set): drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World Radio (a ham set): the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World Radio (a ham set): the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World Radio (a ham set): the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World Radio (a ham set): both windows are on the screen
ZEDQA tww PASS World Radio (a ham set): closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World Radio (a ham set): closed, the other window is where it was
ZEDQA tww World Maps: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World Maps: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World Maps: it is the full card (full)
ZEDQA tww PASS World Maps: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World Maps: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World Maps: both windows are on the screen
ZEDQA tww PASS World Maps: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World Maps: closed, the other window is where it was
ZEDQA tww World Maps pop-out: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World Maps pop-out: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World Maps pop-out: it is the full card (full)
ZEDQA tww PASS World Maps pop-out: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World Maps pop-out: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World Maps pop-out: both windows are on the screen
ZEDQA tww the pop-out 538,238 2764x1684: over the Character window true, over the World window true (it is a window of its own, centred)
ZEDQA tww PASS World Maps pop-out: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World Maps pop-out: closed, the other window is where it was
ZEDQA tww 15 held-in cases
ZEDQA tww held in: Character equip: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character equip: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character equip: it is the half card (half)
ZEDQA tww PASS held in: Character equip: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character equip: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character equip: both windows are on the screen
ZEDQA tww PASS held in: Character equip: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character equip: closed, the other window is where it was
ZEDQA tww held in: Character health: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character health: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character health: it is the half card (half)
ZEDQA tww PASS held in: Character health: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character health: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character health: both windows are on the screen
ZEDQA tww PASS held in: Character health: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character health: closed, the other window is where it was
ZEDQA tww held in: Character thermal: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character thermal: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character thermal: it is the half card (half)
ZEDQA tww PASS held in: Character thermal: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character thermal: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character thermal: both windows are on the screen
ZEDQA tww PASS held in: Character thermal: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character thermal: closed, the other window is where it was
ZEDQA tww held in: Character identity: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character identity: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character identity: it is the half card (half)
ZEDQA tww PASS held in: Character identity: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character identity: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character identity: both windows are on the screen
ZEDQA tww PASS held in: Character identity: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character identity: closed, the other window is where it was
ZEDQA tww held in: Character journal: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character journal: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character journal: it is the half card (half)
ZEDQA tww PASS held in: Character journal: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character journal: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character journal: both windows are on the screen
ZEDQA tww PASS held in: Character journal: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character journal: closed, the other window is where it was
ZEDQA tww held in: Character skills: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character skills: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character skills: it is the half card (half)
ZEDQA tww PASS held in: Character skills: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character skills: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character skills: both windows are on the screen
ZEDQA tww PASS held in: Character skills: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character skills: closed, the other window is where it was
ZEDQA tww held in: Character radio: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character radio: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character radio: it is the half card (half)
ZEDQA tww PASS held in: Character radio: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character radio: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character radio: both windows are on the screen
ZEDQA tww PASS held in: Character radio: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character radio: closed, the other window is where it was
ZEDQA tww held in: World craft: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World craft: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World craft: it is the half card (half)
ZEDQA tww PASS held in: World craft: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World craft: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World craft: both windows are on the screen
ZEDQA tww PASS held in: World craft: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World craft: closed, the other window is where it was
ZEDQA tww held in: World build: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World build: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World build: it is the half card (half)
ZEDQA tww PASS held in: World build: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World build: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World build: both windows are on the screen
ZEDQA tww PASS held in: World build: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World build: closed, the other window is where it was
ZEDQA tww held in: World furniture: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World furniture: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World furniture: it is the half card (half)
ZEDQA tww PASS held in: World furniture: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World furniture: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World furniture: both windows are on the screen
ZEDQA tww PASS held in: World furniture: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World furniture: closed, the other window is where it was
ZEDQA tww held in: World maps: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World maps: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World maps: it is the half card (half)
ZEDQA tww PASS held in: World maps: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World maps: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World maps: both windows are on the screen
ZEDQA tww PASS held in: World maps: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World maps: closed, the other window is where it was
ZEDQA tww held in: World forage: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World forage: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World forage: it is the half card (half)
ZEDQA tww PASS held in: World forage: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World forage: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World forage: both windows are on the screen
ZEDQA tww PASS held in: World forage: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World forage: closed, the other window is where it was
ZEDQA tww held in: World animals: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World animals: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World animals: it is the half card (half)
ZEDQA tww PASS held in: World animals: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World animals: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World animals: both windows are on the screen
ZEDQA tww PASS held in: World animals: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World animals: closed, the other window is where it was
ZEDQA tww held in: World radio: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World radio: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World radio: it is the half card (half)
ZEDQA tww PASS held in: World radio: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World radio: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World radio: both windows are on the screen
ZEDQA tww PASS held in: World radio: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World radio: closed, the other window is where it was
ZEDQA tww held in: World vehicle: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World vehicle: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World vehicle: it is the half card (half)
ZEDQA tww PASS held in: World vehicle: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World vehicle: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World vehicle: both windows are on the screen
ZEDQA tww PASS held in: World vehicle: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World vehicle: closed, the other window is where it was
ERROR: General f:29598 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:29607 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA tww PASS after the whole run both windows are where and as big as they were (1134,0 777x735 / 1929,0 777x735 -> 1134,0 777x735 / 1929,0 777x735)
ZEDQA tww skipped, the thing was not there to open: World object card fire, World object card hook, World object card hutch, World object card lock, World object card plant, World object card track, World object card trough
ZEDQA tww ALL PASS
ZEDQA tww DONE
```

### 11. zedqa_hairbeard.lua (`ZEDQA hb`) - WARN, 150 s

- go 16330 at 09:12:56
- 19 ERR line(s)
- screenshots: zqa_hb_list_no_tools.png, zqa_hb_no_tools.png, zqa_hb_tall.png, zqa_hb_greyed_hover.png, zqa_hb_heads_cut.png, zqa_hb_ready.png, zqa_hb_hair_list.png, zqa_hb_cutting.png, zqa_hb_done.png, zqa_hb_tied.png, zqa_hb_pad_beard_folded.png, zqa_hb_pad_beard_greyed.png, zqa_hb_pad_beard_show_all.png, zqa_hb_pad_beard.png, zqa_hb_beard_cut.png, zqa_hb_beard_list.png, zqa_hb_out_of_reach.png, zqa_hb_trait_focus.png, zqa_hb_trait_hover.png, zqa_hb_large.png, zqa_hb_light.png, zqa_hb_female_heads.png, zqa_hb_female_list.png

```text
[ZeD.QA] windows reset (R)
ZEDQA hb start
[ZeD.QA] run #11 ok=true
ZEDQA hb tools taken away for the test: 0 | female false | was Grungey /
ZEDQA hb Hidden actions was 1 (folded); hint rows open: hair false, beard false
ZEDQA hb PASS Hidden actions is a ZeD setting (ZeD.Settings.hiddenActionsOption)
ZEDQA hb FAIL the Character window is on Identity
ZEDQA hb FAIL hair rows from the game's menu: 0
ZEDQA hb groups: tie nil shave nil cut nil style nil
ZEDQA hb FAIL Tie and Cut groups
ZEDQA hb FAIL a cut with no scissors is greyed with the game's reason: nil
ZEDQA hb FAIL tying needs no tool
ZEDQA hb PASS no debug rows
ZEDQA hb FAIL Out of reach holds what the hair cannot become: 0
ZEDQA hb PASS the windows are still
ZEDQA hb FAIL timed out: every hair row in view shows its figure, and Now
ZEDQA hb PASS Hidden actions is at Folded (folded)
ZEDQA hb FAIL folded: the hint row is there: nil
ZEDQA hb FAIL folded: the hint row speaks for the hidden verbs (0 kinds): 0 more with the right things
ZEDQA hb PASS folded: no greyed row in the list (0)
ZEDQA hb PASS folded: only the rows the character can do show (0 of 0, 0 can be done)
ZEDQA hb FAIL folded: the cut row is not in the list and has no click zone
ZEDQA hb FAIL folded: the cut and style rows are no controller stops
ZEDQA hb FAIL folded: the hint row is a controller stop (hb:more)
ZEDQA hb PASS folded: the hint row is shut
ZEDQA hb PASS Hide: the hint row is gone
ZEDQA hb PASS hide: no hint row, no greyed row, no stop for them (hide)
ZEDQA hb PASS hide: only the rows the character can do show (0)
ZEDQA hb FAIL timed out: Show all: the greyed rows show
ZEDQA hb PASS Hidden actions is at Show all (all)
ZEDQA hb PASS show all: no hint row
ZEDQA hb PASS show all: every row shows, Out of reach too (0 of 0 + 0)
ZEDQA hb PASS show all: the rows that cannot be done show greyed (0)
ZEDQA hb FAIL show all: the greyed cut row is in the list and a controller stop
ZEDQA hb FAIL timed out: the list scrolled: every row in view shows its figure
ZEDQA hb shot zqa_hb_list_no_tools.png
ZEDQA hb PASS no drawn heads and no Pictures window left in the section
ZEDQA hb FAIL the figures are a stand-in, not the player's own model
ZEDQA hb FAIL a row's figure wears that row's style: nil -> nil
ZEDQA hb shot zqa_hb_no_tools.png
ZEDQA hb FAIL timed out: figures with Out of reach shown
ZEDQA hb perf list: mean 8.4 ms, 95th 16 ms, worst 26 ms over 240 frames
ZEDQA hb PASS frame time sampled with the list open
ZEDQA hb PASS the tall window is still
ZEDQA hb FAIL timed out: the tall window: every row in view with its figure
ZEDQA hb shot zqa_hb_tall.png
ZEDQA hb perf list_tall: mean 8.4 ms, 95th 15 ms, worst 28 ms over 240 frames
ZEDQA hb PASS frame time sampled with the tall window
ZEDQA hb perf tall window: 0 figures showing
ZEDQA hb PASS the window back to its height
ZEDQA hb PASS the real character is unchanged while the figures show (Fabian|Full|nil|103246260|2114309842|1202646939|547541912|1774172218|1490752081)
ZEDQA hb tab for the release check: loot
ZEDQA hb PASS another tab: the figures leave the window (pool 0, children 0)
ZEDQA hb perf other_tab: mean 8.4 ms, 95th 15 ms, worst 37 ms over 240 frames
ZEDQA hb PASS frame time sampled on another tab
ZEDQA hb perf the figures cost -0.0 ms a frame on the mean (list 8.4, other tab 8.4)
ZEDQA hb perf tall window costs -0.0 ms a frame on the mean (8.4)
ZEDQA hb figures back on Identity: 1 rows in view, 2 figures showing, pool 2
ZEDQA hb PASS back on Identity, the figures come back
ZEDQA hb PASS folded: the hint row has a click zone
ZEDQA hb PASS folded: the cut row has no click zone (it is under the hint row)
ZEDQA hb PASS a click on the hint row opens it
ZEDQA hb PASS opened: the greyed rows show under the hint row
ZEDQA hb PASS opened: the hint row keeps its place and every hidden row follows it (37 of 34 + 3)
ZEDQA hb PASS opened: the greyed cut row is there, a controller stop
ZEDQA hb PASS opened: the hint row is in view with its click zone (the fold stays open until shut: HB.onClick -> DS.toggle)
ZEDQA hb PASS a second click shuts the hint row
ZEDQA hb PASS shut: the greyed rows go again
ZEDQA hb PASS Show all: the greyed rows show again
ZEDQA hb PASS show all: the cut row has a click zone
ZEDQA hb PASS a click picks the row
ZEDQA hb PASS the strip's button is greyed for a greyed row
ZEDQA hb PASS pressing the greyed button does nothing
ZEDQA hb PASS the mouse is over a row (its hint shows)
ZEDQA hb shot zqa_hb_greyed_hover.png
ZEDQA hb PASS Folded again: the greyed rows are gone
ZEDQA hb PASS with scissors the cut can be done: Cut Hair into Short
ZEDQA hb head item: Baseball Cap
ZEDQA hb figures scissors and a cap: 3 rows in view, 3 figures showing, pool 6
ZEDQA hb figures scissors and a cap: 1 rows in view, 4 figures showing, pool 6
ZEDQA hb PASS every row in view with its figure, and the Now / After heads
ZEDQA hb PASS the After head wears the picked style: false|2|MaleBody03|0.584,0.251,0.251|0.584,0.251,0.251|-1|103246260|1839323323|2114309842|1202646939|547541912|1774172218|1490752081#Short/Full
ZEDQA hb PASS the Now head wears the hair now: false|2|MaleBody03|0.584,0.251,0.251|0.584,0.251,0.251|-1|103246260|1839323323|2114309842|1202646939|547541912|1774172218|1490752081#Fabian/Full
ZEDQA hb PASS the cap is still on the real character (only the figures go without it)
ZEDQA hb PASS the heads half out of the view: Now and After show the part inside it
ZEDQA hb PASS hair: Now and After cut by the view's edge, not left empty (cut 64.4375 px)
ZEDQA hb shot zqa_hb_heads_cut.png
ZEDQA hb rect heads_cut list 357 111 815 473
ZEDQA hb rect heads_cut heads 375 45 779 157
ZEDQA hb shot zqa_hb_ready.png
ZEDQA hb rect ready list 357 111 815 473
ZEDQA hb rect ready heads 375 181 779 157
ZEDQA hb figures with scissors: 4 rows in view, 4 figures showing, pool 6
ZEDQA hb PASS with scissors, the list: every row in view with its figure
ZEDQA hb shot zqa_hb_hair_list.png
ZEDQA hb rect hair_list list 357 111 815 473
ZEDQA hb rect hair_list heads 375 -121 779 157
ZEDQA hb PASS the strip's button is live
ZEDQA hb PASS the cut is running
ZEDQA hb PASS the game's ISCutHair is queued
ZEDQA hb shot zqa_hb_cutting.png
ZEDQA hb PASS the cut ends
ZEDQA hb PASS the hair is now Short: Short
ZEDQA hb PASS the strip says done: Done: hair is now Short
ZEDQA hb PASS the cap came off first
ZEDQA hb PASS the license's Hair style line follows: Short
ZEDQA hb shot zqa_hb_done.png
ZEDQA hb PASS a tie row after growing it back
ZEDQA hb PASS the tie row is a controller stop
ZEDQA hb PASS the tie ends
ZEDQA hb PASS tied: the loose style is kept (Fabian)
ZEDQA hb PASS tied: Untie Hair is the only row (1)
ZEDQA hb shot zqa_hb_tied.png
ZEDQA hb PASS the untie ends
ZEDQA hb PASS untied: back to Fabian (Fabian)
ZEDQA hb PASS focus on the tab's disclosure
ZEDQA hb PASS down from the disclosure lands on the Hair | Beard switch (hb:part)
ZEDQA hb PASS right flips to Beard and stays on the switch
ZEDQA hb PASS folded: down from the switch lands on the hint row (hb:more)
ZEDQA hb PASS folded: focus on the hint row picks nothing (nil)
ZEDQA hb PASS folded: no beard row can be done, only the hint row shows (0 rows)
ZEDQA hb shot zqa_hb_pad_beard_folded.png
ZEDQA hb PASS folded: A on the hint row opens it
ZEDQA hb PASS opened: the greyed beard rows show under the hint row
ZEDQA hb PASS opened: down walks into the beard rows (hb:row:b:)
ZEDQA hb PASS opened: the strip follows focus with no press
ZEDQA hb PASS opened: greyed with the game's reason: Requires a Razor or Scissors.
ZEDQA hb PASS opened: A on a greyed row does nothing
ZEDQA hb shot zqa_hb_pad_beard_greyed.png
ZEDQA hb PASS opened: the hint row is a stop
ZEDQA hb PASS A on the hint row shuts it
ZEDQA hb PASS shut: the greyed beard rows go again
ZEDQA hb PASS Show all: the greyed beard rows show
ZEDQA hb PASS show all: no hint row to walk through
ZEDQA hb PASS show all: down walks into the beard rows (hb:row:b:)
ZEDQA hb PASS show all: the strip follows focus with no press
ZEDQA hb PASS show all: greyed with the game's reason: Requires a Razor or Scissors.
ZEDQA hb PASS show all: A on a greyed row does nothing
ZEDQA hb shot zqa_hb_pad_beard_show_all.png
ZEDQA hb PASS Folded again: the greyed beard rows are gone
ZEDQA hb PASS with scissors the trim can be done: Trim Beard into Mustache
ZEDQA hb figures beard: 3 rows in view, 4 figures showing, pool 6
ZEDQA hb figures beard: 1 rows in view, 4 figures showing, pool 6
ZEDQA hb PASS every beard row in view with its figure, and the Now / After heads
ZEDQA hb PASS the beard list runs on the character's own hair: Grungey
ZEDQA hb PASS beard, under the heads: every beard row's figure keeps the character's hair (Grungey, 1 rows)
ZEDQA hb PASS beard, under the heads: every beard row's figure wears that row's beard (1 rows)
ZEDQA hb PASS beard: Now shows the character as they are: #Grungey/Full@S
ZEDQA hb PASS the focused row is the picked one (b:Moustache)
ZEDQA hb PASS beard: After shows the picked row's result: #Grungey/Moustache@S
ZEDQA hb shot zqa_hb_pad_beard.png
ZEDQA hb rect pad_beard list 357 111 815 473
ZEDQA hb rect pad_beard heads 375 181 779 157
ZEDQA hb PASS beard: the heads half out of the view, Now and After show the part inside it
ZEDQA hb PASS beard: Now and After cut by the view's edge, not left empty
ZEDQA hb shot zqa_hb_beard_cut.png
ZEDQA hb rect beard_cut list 357 111 815 473
ZEDQA hb rect beard_cut heads 375 45 779 157
ZEDQA hb fig b: y 316 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Chops y 438 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig after y 111 h 66 cut 64 zoom 20.935 yoff -0.7730
ZEDQA hb fig now y 111 h 66 cut 64 zoom 20.935 yoff -0.7730
ZEDQA hb fig b:Moustache y 534 h 50 cut 21 zoom 20.467 yoff -0.8735
ZEDQA hb figures beard rows: 4 rows in view, 5 figures showing, pool 6
ZEDQA hb PASS beard: the list scrolled, every row in view with its figure
ZEDQA hb PASS beard, the list: every beard row's figure keeps the character's hair (Grungey, 4 rows)
ZEDQA hb PASS beard, the list: every beard row's figure wears that row's beard (4 rows)
ZEDQA hb PASS the picked beard row's figure wears that beard: #Grungey/Moustache@S
ZEDQA hb shot zqa_hb_beard_list.png
ZEDQA hb rect beard_list list 357 111 815 473
ZEDQA hb rect beard_list heads 375 -121 779 157
ZEDQA hb fig b: y 149 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Chops y 271 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Moustache y 367 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Goatee y 463 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:BeardOnly y 559 h 25 cut 46 zoom 22.724 yoff -0.9233
ZEDQA hb PASS the trim ends
ZEDQA hb PASS the beard is now Moustache: Moustache
ZEDQA hb PASS the hint row alone, shut
ZEDQA hb PASS the hint row names the styles out of reach: choose from more styles
ZEDQA hb PASS Out of reach is a stop (the hint row, hb:more)
ZEDQA hb PASS A folds Out of reach open (the hint row opens)
ZEDQA hb PASS an out-of-reach row can be focused and says why
ZEDQA hb shot zqa_hb_out_of_reach.png
ZEDQA hb PASS a trait is a controller stop: identity:trait:Dextrous
ZEDQA hb PASS focus shows the description at once (no hover timer): Dextrous
ZEDQA hb shot zqa_hb_trait_focus.png
ZEDQA hb PASS trait zones are kept for hover
ZEDQA hb PASS hover on a trait shows its description: Dextrous
ZEDQA hb PASS the trait's card is drawn after the shared pause
ZEDQA hb shot zqa_hb_trait_hover.png
ZEDQA hb figures Large text: 1 rows in view, 2 figures showing, pool 6
ZEDQA hb PASS Large text: every row in view with its figure
ZEDQA hb shot zqa_hb_large.png
ZEDQA hb rect large list 240 127 938 491
ZEDQA hb rect large heads 260 -141 898 183
ZEDQA hb figures Light: 1 rows in view, 3 figures showing, pool 6
ZEDQA hb PASS Light: every row in view with its figure
ZEDQA hb shot zqa_hb_light.png
ZEDQA hb rect light list 357 111 815 521
ZEDQA hb rect light heads 375 -121 779 157
ZEDQA hb Spongie's Hairstyle Unlocker on: false
ZEDQA hb PASS no Traits tab without Traits As Skills
ZEDQA hb figures after Large and Light: 4 rows in view, 5 figures showing, pool 6
ZEDQA hb PASS every row in view with its figure
ZEDQA hb PASS Spongie's tagged row in view with its figure
ZEDQA hb PASS the window closed: the figures left it (children 0)
ZEDQA hb figures reopened: 1 rows in view, 3 figures showing, pool 3
ZEDQA hb PASS reopened: the figures come back
ZEDQA hb made a woman for the check: true, skin FemaleBody03
ZEDQA hb figures a woman: 2 rows in view, 4 figures showing, pool 4
ZEDQA hb PASS a woman: her hair rows and Now show
ZEDQA hb PASS a woman: no beard half (0 beard rows)
ZEDQA hb PASS a woman: the figures' stand-in is a woman
ZEDQA hb PASS a woman: every row is one of the game's women's styles (39 rows)
ZEDQA hb PASS a woman: Now wears her hair: #Long2/
ZEDQA hb PASS a woman: After shows the picked cut
ZEDQA hb PASS a woman: After wears the picked cut: #Bob/
ZEDQA hb shot zqa_hb_female_heads.png
ZEDQA hb rect female_heads list 357 111 815 521
ZEDQA hb rect female_heads heads 375 181 779 157
ZEDQA hb figures a woman's list: 4 rows in view, 5 figures showing, pool 5
ZEDQA hb PASS a woman's list: every row in view with its figure
ZEDQA hb shot zqa_hb_female_list.png
ZEDQA hb rect female_list list 357 111 815 521
ZEDQA hb rect female_list heads 375 -121 779 157
ZEDQA hb PASS the QA character is put back: female false, skin MaleBody03
ZEDQA hb put back: Grungey / , 0 tools returned
ZEDQA hb PASS Hidden actions is back as it was found: 1 (was 1)
ZEDQA hb 19 failed
ZEDQA hb DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    1x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
