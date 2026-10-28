# ZeD-UI regression - 2026-10-28 08:29 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-28 08:29:56 |
| Finished | 2026-10-28 08:35:06 (5 min 9 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/icons_cleanup_manifest.txt (9 scripts) |
| Result | **9/9 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 14843 to 14853 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 14852, 14853)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 4 |  |  |
| 2 | suite_tabs.lua | tabs | PASS | 11 |  |  |
| 3 | zedqa_ctx_icons.lua | cx | PASS | 22 | zqa_cx_grid.png, zqa_cx_strip_apple.png, zqa_cx_strip_pistol.png, zqa_cx_strip_bandage.png, zqa_cx_strip_hammer.png, zqa_cx_strip_floor.png, zqa_cx_list_apple.png, zqa_cx_list_pistol.png, zqa_cx_list_bandage.png, zqa_cx_list_hammer.png, zqa_cx_list_floor.png |  |
| 4 | zedqa_px_icons.lua | px | PASS | 5 | zqa_px_panel.png, zqa_px_card.png, zqa_px_rows.png |  |
| 5 | zedqa_uiscale.lua | scale | PASS | 11 | zedqa_scale_auto.png, zedqa_scale_x150.png, zedqa_scale_x100.png, zedqa_scale_auto_back.png, zedqa_scale_restored.png |  |
| 6 | zedqa_button_case_game.lua | bg | PASS | 16 | zqa_bg_01_item_card.png, zqa_bg_02_health.png, zqa_bg_03_thermal.png, zqa_bg_04_animals.png, zqa_bg_05_forage.png, zqa_bg_06_craft.png, zqa_bg_07_vehicle.png |  |
| 7 | zedqa_grid.lua | grid | PASS | 6 | zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png |  |
| 8 | zedqa_wheel_icons.lua | wi | PASS | 55 | zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png |  |
| 9 | zedqa_dpad_wheels.lua | dw | PASS | 45 | zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 4 s

- go 14843 at 08:31:11

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 914,13038,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. suite_tabs.lua (`ZEDQA tabs`) - PASS, 11 s

- go 14844 at 08:31:19

```text
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals,vehicle
ZEDQA tabs armed
[ZeD.QA] run #2 ok=true
ZEDQA char tab=loot active=loot w=777 focusables=0 {}
ZEDQA char tab=equip active=equip w=1617 focusables=31 {equipgroup=5 equippart=17 equipslot=7 equipview=2}
ZEDQA char tab=health active=health w=1617 focusables=27 {bodypart=17 exercise=9 health=1}
ZEDQA char tab=thermal active=thermal w=1617 focusables=26 {thermal=9 thermalpart=17}
ZEDQA char tab=identity active=identity w=1617 focusables=31 {hb=2 identity=29}
ZEDQA char tab=journal active=journal w=1617 focusables=8 {journal=4 jsub=4}
ZEDQA char tab=skills active=skills w=1617 focusables=60 {skill=35 skills=1 training=24}
ZEDQA world tab=loot active=loot w=777 focusables=0 {}
ZEDQA world tab=craft active=craft w=1617 focusables=10 {craft=10}
ZEDQA world tab=build active=build w=1617 focusables=8 {build=8}
ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
ZEDQA world tab=maps active=maps w=1694 focusables=17 {map=17}
ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
ZEDQA world tab=vehicle active=vehicle w=1617 focusables=1 {mech=1}
ZEDQA tabs done
```

### 3. zedqa_ctx_icons.lua (`ZEDQA cx`) - PASS, 22 s

- go 14845 at 08:31:33
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
[ZeD.QA] run #3 ok=true
ZEDQA cx drawings not ready yet: 273
ZEDQA cx drawings not ready after 69 frames: 0
ZEDQA cx ok every drawing on the panel loaded
ZEDQA cx shot zqa_cx_grid
ZEDQA cx ok the test panel drew
ZEDQA cx strip apple: ZeD_ContextMenu | pixel 12, licensed 0, item pictures 0, none 0
ZEDQA cx ok strip apple opened with pixel icons
ZEDQA cx ok strip apple: no licensed picture left
ZEDQA cx shot zqa_cx_strip_apple
ZEDQA cx strip pistol: ZeD_ContextMenu | pixel 14, licensed 0, item pictures 0, none 0
ZEDQA cx ok strip pistol opened with pixel icons
ZEDQA cx ok strip pistol: no licensed picture left
ZEDQA cx shot zqa_cx_strip_pistol
ZEDQA cx strip bandage: ZeD_ContextMenu | pixel 11, licensed 0, item pictures 0, none 0
ZEDQA cx ok strip bandage opened with pixel icons
ZEDQA cx ok strip bandage: no licensed picture left
ZEDQA cx shot zqa_cx_strip_bandage
ZEDQA cx strip hammer: ZeD_ContextMenu | pixel 13, licensed 0, item pictures 0, none 2 (Belt Left, Belt Right)
ZEDQA cx ok strip hammer opened with pixel icons
ZEDQA cx ok strip hammer: no licensed picture left
ZEDQA cx shot zqa_cx_strip_hammer
ZEDQA cx strip floor: ZeD_ContextMenu | pixel 4, licensed 0, item pictures 0, none 0
ZEDQA cx ok strip floor opened with pixel icons
ZEDQA cx ok strip floor: no licensed picture left
ZEDQA cx shot zqa_cx_strip_floor
ZEDQA cx list apple: ZeD_ContextList | pixel 12, licensed 0, item pictures 0, none 0
ZEDQA cx ok list apple opened with pixel icons
ZEDQA cx ok list apple: no licensed picture left
ZEDQA cx shot zqa_cx_list_apple
ZEDQA cx list pistol: ZeD_ContextList | pixel 14, licensed 0, item pictures 0, none 0
ZEDQA cx ok list pistol opened with pixel icons
ZEDQA cx ok list pistol: no licensed picture left
ZEDQA cx shot zqa_cx_list_pistol
ZEDQA cx list bandage: ZeD_ContextList | pixel 11, licensed 0, item pictures 0, none 0
ZEDQA cx ok list bandage opened with pixel icons
ZEDQA cx ok list bandage: no licensed picture left
ZEDQA cx shot zqa_cx_list_bandage
ZEDQA cx list hammer: ZeD_ContextList | pixel 13, licensed 0, item pictures 0, none 2 (Belt Left, Belt Right)
ZEDQA cx ok list hammer opened with pixel icons
ZEDQA cx ok list hammer: no licensed picture left
ZEDQA cx shot zqa_cx_list_hammer
ZEDQA cx list floor: ZeD_ContextList | pixel 4, licensed 0, item pictures 0, none 0
ZEDQA cx ok list floor opened with pixel icons
ZEDQA cx ok list floor: no licensed picture left
ZEDQA cx shot zqa_cx_list_floor
ZEDQA cx DONE 0 failed
```

### 4. zedqa_px_icons.lua (`ZEDQA px`) - PASS, 5 s

- go 14846 at 08:31:59
- screenshots: zqa_px_panel.png, zqa_px_card.png, zqa_px_rows.png

```text
[ZeD.QA] windows reset (R)
ZEDQA px scale 1.75: the 16-unit icon box is 28 px, the drawing for it 24
ZEDQA px ok 29 icons, four drawings each, the box picks 24
ZEDQA px ok a licensed name is no pixel icon (the row falls back to words, not a picture)
ZEDQA px ok the wheels use the same lookup
[ZeD.QA] run #4 ok=true
ZEDQA px shot zqa_px_panel
ZEDQA px ok the test panel drew
ZEDQA px ok the card opened on Belt
ZEDQA px shot zqa_px_card
ZEDQA px card toggle rects nil
ZEDQA px shot zqa_px_rows
ZEDQA px ok Fav put back
ZEDQA px DONE 0 failed
```

### 5. zedqa_uiscale.lua (`ZEDQA scale`) - PASS, 11 s

- go 14847 at 08:32:07
- screenshots: zedqa_scale_auto.png, zedqa_scale_x150.png, zedqa_scale_x100.png, zedqa_scale_auto_back.png, zedqa_scale_restored.png

```text
[ZeD.QA] windows reset (R)
ZEDQA scale armed
[ZeD.QA] run #5 ok=true
ZEDQA scale auto option=7 userScale=1.75 root=1.75 iconDrawn=28 iconTex=24x24 char=777x735 world=777x735
ZEDQA scale x150 option=6 userScale=1.5 root=1.5 iconDrawn=24 iconTex=24x24 char=666x630 world=666x630
ZEDQA scale x100 option=4 userScale=1 root=1 iconDrawn=16 iconTex=16x16 char=444x420 world=444x420
ZEDQA scale auto_back option=1 userScale=nil root=2 iconDrawn=32 iconTex=32x32 char=888x840 world=888x840
ZEDQA scale restored option=7 userScale=1.75 root=1.75 iconDrawn=28 iconTex=24x24 char=777x735 world=777x735
ZEDQA scale done
```

### 6. zedqa_button_case_game.lua (`ZEDQA bg`) - PASS, 16 s

- go 14848 at 08:32:22
- screenshots: zqa_bg_01_item_card.png, zqa_bg_02_health.png, zqa_bg_03_thermal.png, zqa_bg_04_animals.png, zqa_bg_05_forage.png, zqa_bg_06_craft.png, zqa_bg_07_vehicle.png

```text
[ZeD.QA] windows reset (R)
ZEDQA bg start
[ZeD.QA] run #6 ok=true
ZEDQA bg pickup true shirt true
ZEDQA bg card open true
ZEDQA bg DONE
```

### 7. zedqa_grid.lua (`ZEDQA grid`) - PASS, 6 s

- go 14849 at 08:32:41
- screenshots: zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA grid start
[ZeD.QA] run #7 ok=true
ZEDQA grid grid on: cell 91 | cells placed 14 | toggle rects 2
ZEDQA grid first target: invrow:1 at 18,107 size 91x91
ZEDQA grid first cell: zone=charMainInv el=invrow:1 item=Angel Cross's Key Ring
ZEDQA grid right (expect the next cell): zone=charMainInv el=invrow:2 item=Apple (Fresh)
ZEDQA grid down (expect the cell below): zone=charMainInv el=invrow:8 item=Fanny Pack
ZEDQA grid up: zone=charMainInv el=invrow:2 item=Apple (Fresh)
ZEDQA grid up again (expect the toggle): zone=charMainInv el=view:list:player item=nil
ZEDQA grid card open true item Angel Cross's Key Ring
ZEDQA grid after A on List: grid false cell nil
ZEDQA grid DONE
```

### 8. zedqa_wheel_icons.lua (`ZEDQA wi`) - PASS, 55 s

- go 14850 at 08:32:51
- screenshots: zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wi start car=BaseVehicle{ Name:null, ID:13 }
[ZeD.QA] run #8 ok=true
ZEDQA wi scene: screen 3840x2160, scale option 7, icon box 28 at rest, 42 pointed
ZEDQA wi PASS all 151 icons load at 16, 24, 32 and 48, each its own file (0 problems)
ZEDQA wi PASS the drawing for each box: the largest that fits, at its own size; under 16 the 16 scaled down
ZEDQA wi at this scale: box 28 draws the 24, box 42 draws the 32
ZEDQA wi PASS vanilla's words: 29 of 30 give their icon over vanilla's picture
ZEDQA wi NOTE no words in this language for ContextMenu_Vehicle_AttachVehicle (vanilla shows the key itself; nothing to match)
ZEDQA wi PASS vanilla's pictures by name, in order: 95 of 95
ZEDQA wi PASS items, traits and the controller's glyphs keep their pictures
ZEDQA wi PASS headlights on / a light source on share a picture and come out id:headlight_on / id:bulb_on
ZEDQA wi PASS headlights off / a light source off share a picture and come out id:headlight_off / id:bulb_off
ZEDQA wi PASS get in / change seats share a picture and come out id:car_enter / id:seat
ZEDQA wi PASS get out / a door share a picture and come out id:car_exit / id:car_door
ZEDQA wi PASS lock / unlock share a picture and come out id:padlock / id:padlock_open
ZEDQA wi PASS hitch / unhitch share a picture and come out id:link / id:unlink
ZEDQA wi PASS zoom in / plus share a picture and come out id:zoom_in / id:plus
ZEDQA wi PASS zoom out / minus share a picture and come out id:zoom_out / id:minus
ZEDQA wi PASS the tab icons, and every tab of both windows has one
ZEDQA wi PASS left: the wheel builds
ZEDQA wi PASS right: the wheel builds
ZEDQA wi PASS up: the wheel builds
ZEDQA wi PASS down: the wheel builds
ZEDQA wi PASS select: the wheel builds
ZEDQA wi PASS 138 slices on ZeD's five wheels, 123 with a wheel icon, the rest items, glyphs or colours
ZEDQA wi PASS the ZeD wheel's pickers give their choices the setting's icon
ZEDQA wi PASS the map's slices on ZeD's wheels: 79 with their icon
ZEDQA wi NOTE not on the wheels now (the state decides): the wounds (no wound now); character > Watch / UI_ZeD_Wheel_OpenWatch; character > Watch / UI_ZeD_Wheel_WatchLight; character > Watch / UI_ZeD_Wheel_WatchAlarm; character > Radio / UI_ZeD_Wheel_NextStation; world > Search / UI_disable_search_mode; world > Vehicle / IGUI_VehiclePartCatdashboard
ZEDQA wi PASS Crouch and Auto-walk show what the slice does now: sneak, autowalk
ZEDQA wi dpad_left: 8 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid/Nothing to treat, no medicine on you.=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack
ZEDQA wi PASS dpad_left: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_right: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_up: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Flashlight/Turn on=bulb_on
ZEDQA wi PASS dpad_down: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_select: 12 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/No messages.=inbox 10:Reset windows/Both windows back to where they start=rotate 11:ZeD setup/Options, on ZeD's page=gears 12:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select: 11 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_left_use: 5 slices | 1:Smoke/Nothing to smoke, or nothing to light it.=cigarette 2:Read=book 3:Watch/No watch on your wrist.=watch 4:Radio/No radio in your hands or on your back.=walkie
ZEDQA wi PASS dpad_left_use: 4 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down_speed: 5 slices | 1:Pause/In use=pause 2:FF x 1=ff1 3:FF x 2=ff2 4:FF x 3=wait
ZEDQA wi PASS dpad_down_speed: 4 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down_view: 5 slices | 1:Hide the interface/Until you take this again=eye_off 2:Reset windows/Both windows back to where they start=rotate 3:Text size=textsize 4:OPTIONS/Options, on ZeD's page=gears
ZEDQA wi PASS dpad_down_view: 4 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_select_theme: 4 slices | 1:Dark/In use=theme 2:Light=theme 3:High contrast=theme
ZEDQA wi PASS dpad_select_theme: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes: 5 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_friendly: 6 slices | 1:Wave Hi=wave 2:Bye=wave_bye 3:Clap=clap 4:Thumbs Up=thumbs_up 5:Thank You=bow
ZEDQA wi PASS emotes_friendly: 5 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_hostile: 5 slices | 1:Insult=insult 2:Stop=hand 3:Surrender=surrender 4:Thumbs Down=thumbs_down
ZEDQA wi PASS emotes_hostile: 4 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_group: 7 slices | 1:Follow Me=follow_me 2:Come Here=come_here 3:Yes=yes 4:No=no 5:Shrug=shrug 6:Undecided=undecided
ZEDQA wi PASS emotes_group: 6 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_signal: 9 slices | 1:Cease Fire=target_off 2:Ok=yes 3:Move Out=move_out 4:Freeze=freeze 5:Follow Behind=follow_behind 6:Fire=target 7:Come=come_here 8:Salute=salute
ZEDQA wi PASS emotes_signal: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi gun: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi light: 2 slices | 1:Flashlight/Unequip=minus 2:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi stick: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi vanilla_back: 10 slices | 1:Player Info=heart 2:Crafting=craft 3:Building=bricks 4:Zoom 75%=zoom_in 5:Pause=pause 6:FF x 1=ff1 7:Zoom 125%=zoom_out 8:Move furniture=chair 9:Enable Search Mode=eye 10:Investigate This Area=magnifier
ZEDQA wi PASS vanilla_back: 10 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi vanilla_dright: 3 slices | 1:Show/Hide World Map=map 2:Designated Zones=fence 3:Toggle Survival Guide=guide
ZEDQA wi PASS vanilla_dright: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi car_outside: 3 slices | 1:Vehicle Mechanics=engine 2:Enter Vehicle=car_enter 3:Smash Rear Windshield=window_smash
ZEDQA wi PASS car_outside: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi PASS in the car: the dashboard slice has the gauge (gauge)
ZEDQA wi car_inside: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Unlock all doors=padlock_open 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside: 13 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi PASS vanilla's radials and ZeD's wheels, live: 121 slices, 121 wheel icons, 0 kept pictures
ZEDQA wi now at 1x (text size small): icon box 16 at rest, 24 pointed
ZEDQA wi dpad_left_1x: 8 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid/Nothing to treat, no medicine on you.=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack
ZEDQA wi PASS dpad_left_1x: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_right_1x: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right_1x: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_up_1x: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up_1x: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down_1x: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Flashlight/Turn on=bulb_on
ZEDQA wi PASS dpad_down_1x: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_select_1x: 12 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/No messages.=inbox 10:Reset windows/Both windows back to where they start=rotate 11:ZeD setup/Options, on ZeD's page=gears 12:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select_1x: 11 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_1x: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes_1x: 5 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi gun_1x: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun_1x: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi light_1x: 2 slices | 1:Flashlight/Unequip=minus 2:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light_1x: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi stick_1x: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick_1x: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi car_inside_1x: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Unlock all doors=padlock_open 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside_1x: 12 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi scale back to option 7: icon box 28
ZEDQA wi 0 failed, 2 notes
ZEDQA wi DONE
```

### 9. zedqa_dpad_wheels.lua (`ZEDQA dw`) - PASS, 45 s

- go 14851 at 08:33:49
- screenshots: zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png

```text
[ZeD.QA] windows reset (R)
ZEDQA dw start
[ZeD.QA] run #9 ok=true
ZEDQA dw scene: at 868,13026, in a car false, health 100
ZEDQA dw foot left: 8 slices, crumb Character, visible false | 1:Tabs / Character window [>] 2:Weapons [>] 3:Eat [>] 4:Drink / Nothing to drink on you. [off] 5:Medicine and first aid / Nothing to treat, no medicine on you. [off] 6:Sleep / Not tired enough to sleep. [off] 7:Clothing / Nothing you wear can change. [off] 8:Use / Smoke | Read | Watch | Radio [>]
ZEDQA dw PASS left: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS left: the slice 'Tabs' is there
ZEDQA dw inner left: 9 slices, crumb Character + Tabs, visible true | 1:Loot 2:Equipment 3:Health 4:Thermal 5:Identity 6:Journal 7:Skills 8:Radio / No radio in your hands or on your back. [off] 9:Back
ZEDQA dw PASS left: the inner wheel ends with Back
ZEDQA dw PASS left: the breadcrumb names the inner wheel
ZEDQA dw PASS left: B from the inner wheel is back on the top level
ZEDQA dw PASS left: B on the top level closes the wheel
ZEDQA dw foot right: 8 slices, crumb World, visible false | 1:Tabs / World window [>] 2:Map [>] 3:Vehicle / No vehicle in reach. [off] 4:Animal / No tame animal in reach. [off] 5:Craft and build [>] 6:Search [>] 7:Lights and power / No lights or power in reach. [off] 8:Designated Zones / Animals
ZEDQA dw PASS right: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS right: the slice 'Map' is there
ZEDQA dw inner right: 4 slices, crumb World + Map, visible true | 1:Show/Hide World Map 2:Show/Hide Mini-Map / The mini-map is off in this game. [off] 3:Focus Mini Map / The mini-map is off in this game. [off] 4:Back
ZEDQA dw PASS right: the inner wheel ends with Back
ZEDQA dw PASS right: the breadcrumb names the inner wheel
ZEDQA dw PASS right: B from the inner wheel is back on the top level
ZEDQA dw PASS right: B on the top level closes the wheel
ZEDQA dw foot up: 8 slices, crumb Social, visible false | 1:Friendly [>] 2:Hostile [>] 3:Group [>] 4:Signal [>] 5:Shout 6:Chat / On a server only. [off] 7:Safety / On a server only. [off] 8:Players / On a server only. [off]
ZEDQA dw PASS up: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS up: the slice 'Friendly' is there
ZEDQA dw inner up: 6 slices, crumb Social + Friendly, visible true | 1:Wave Hi 2:Bye 3:Clap 4:Thumbs Up 5:Thank You 6:Back
ZEDQA dw PASS up: the inner wheel ends with Back
ZEDQA dw PASS up: the breadcrumb names the inner wheel
ZEDQA dw PASS up: B from the inner wheel is back on the top level
ZEDQA dw PASS up: B on the top level closes the wheel
ZEDQA dw foot down: 8 slices, crumb Here and now, visible false | 1:Sit [>] 2:Crouch / Off 3:Auto-walk / Off 4:Game speed [>] 5:Zoom [>] 6:View / Interface and windows [>] 7:Help [>] 8:Flashlight / Turn on
ZEDQA dw PASS down: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS down: the slice 'Zoom' is there
ZEDQA dw inner down: 3 slices, crumb Here and now + Zoom, visible true | 1:Zoom 75% 2:Zoom 125% 3:Back
ZEDQA dw PASS down: the inner wheel ends with Back
ZEDQA dw PASS down: the breadcrumb names the inner wheel
ZEDQA dw PASS down: B from the inner wheel is back on the top level
ZEDQA dw PASS down: B on the top level closes the wheel
ZEDQA dw foot select: 12 slices, crumb ZeD, visible false | 1:Base theme / Dark [>] 2:Accent color / PZ Teal [>] 3:Text size / Small [>] 4:See-through / 90% [>] 5:Controller highlight / Pointing hand [>] 6:UI scale [>] 7:Moodles / Right edge [>] 8:Action bar / Verbose [>] 9:Messages / No messages. [off] 10:Reset windows / Both windows back to where they start 11:ZeD setup / Options, on ZeD's page 12:Safe mode / The game's own interface
ZEDQA dw PASS select: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS select: the slice 'Base theme' is there
ZEDQA dw inner select: 4 slices, crumb ZeD + Base theme, visible true | 1:Dark / In use 2:Light 3:High contrast 4:Back
ZEDQA dw PASS select: the inner wheel ends with Back
ZEDQA dw PASS select: the breadcrumb names the inner wheel
ZEDQA dw PASS select: B from the inner wheel is back on the top level
ZEDQA dw PASS select: B on the top level closes the wheel
ZEDQA dw look back to dark / teal / small
ZEDQA dw PASS Character > Tabs has Health
ZEDQA dw PASS Character > Tabs > Health opened the Character window on Health
ZEDQA dw World > Map > Mini-map is off: The mini-map is off in this game.
ZEDQA dw no mini-map in this game (sandbox): the slice is off, as it should be
ZEDQA dw PASS Social > Shout is live
ZEDQA dw PASS Here and now > Zoom > in changed the zoom (1.00 -> 0.75)
ZEDQA dw PASS ZeD > Text size marks the size in use
ZEDQA dw PASS ZeD > Text size > the size in use keeps it (small)
ZEDQA dw PASS the game pauses for the paused checks
ZEDQA dw PASS paused: left stays closed
ZEDQA dw PASS paused: right stays closed
ZEDQA dw PASS paused: up stays closed
ZEDQA dw PASS paused: down opens
ZEDQA dw PASS paused: select opens
ZEDQA dw PASS the game runs again after the paused checks
ZEDQA dw PASS with a window holding the pad, D-pad Left stays in the window (no wheel)
ZEDQA dw PASS L3 steps the sort (name, cat, cond)
ZEDQA dw PASS R3 flips the bag between List and Grid (false -> true)
ZEDQA dw PASS R3 again flips it back
ZEDQA dw PASS the footer names L3 and R3 while the pad is on the list
ZEDQA dw no deep-run car within 8 tiles: the car scene is skipped
ZEDQA dw 0 animals in the cell, none tame within 15 tiles: a tame cow spawned beside the character (true)
ZEDQA dw beside a tame animal (2.0 tiles away before)
ZEDQA dw the game's usable animal: nil
ZEDQA dw animal right: 8 slices, crumb World, visible false | 1:Tabs / World window [>] 2:Map [>] 3:Vehicle / No vehicle in reach. [off] 4:Animal [>] 5:Craft and build [>] 6:Search [>] 7:Lights and power / No lights or power in reach. [off] 8:Designated Zones / Animals
ZEDQA dw PASS beside a tame animal: World > Animal is live
ZEDQA dw animal wheel: 5 slices, crumb World + Animal, visible false | 1:Kill Animal 2:Pick up Angus Cow 3:Pet 4:Animal Info 5:Back
ZEDQA dw PASS the animal wheel ends with Back
ZEDQA dw 0 failed
ZEDQA dw DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
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
