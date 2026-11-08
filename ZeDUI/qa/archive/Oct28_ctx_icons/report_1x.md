# ZeD-UI regression - 2026-10-28 08:07 - windowed (1920x1080 window)

| | |
|---|---|
| Started | 2026-10-28 08:07:01 |
| Finished | 2026-10-28 08:09:49 (2 min 48 s) |
| Mode | windowed (1920x1080 window) |
| Display | fullScreen=false height=1080 width=1920 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/ctx_icons_manifest.txt (5 scripts) |
| Result | **5/5 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 14836 to 14842 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1080p window) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1920x1080
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 14841, 14842)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 4 |  |  |
| 2 | zedqa_ctx_icons.lua | cx | PASS | 11 | zqa_cx_grid.png, zqa_cx_strip_apple.png, zqa_cx_strip_pistol.png, zqa_cx_strip_bandage.png, zqa_cx_strip_hammer.png, zqa_cx_strip_floor.png, zqa_cx_list_apple.png, zqa_cx_list_pistol.png, zqa_cx_list_bandage.png, zqa_cx_list_hammer.png, zqa_cx_list_floor.png |  |
| 3 | zedqa_ctxlist.lua | cl | PASS | 3 | zqa_cl_1.png, zqa_cl_2.png |  |
| 4 | zedqa_wheel_icons.lua | wi | PASS | 24 | zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png |  |
| 5 | zedqa_wheels.lua | wh | PASS | 11 | zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 4 s

- go 14836 at 08:08:11

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 914,13038,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_ctx_icons.lua (`ZEDQA cx`) - PASS, 11 s

- go 14837 at 08:08:19
- screenshots: zqa_cx_grid.png, zqa_cx_strip_apple.png, zqa_cx_strip_pistol.png, zqa_cx_strip_bandage.png, zqa_cx_strip_hammer.png, zqa_cx_strip_floor.png, zqa_cx_list_apple.png, zqa_cx_list_pistol.png, zqa_cx_list_bandage.png, zqa_cx_list_hammer.png, zqa_cx_list_floor.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cx ok 389 pictures in the menu's table, each with a pixel icon
ZEDQA cx ok each pixel icon has its four drawings
ZEDQA cx scale 1: the cell is 22 px, its icon box 16, the drawing 16
ZEDQA cx ok the box rule picks 16 for the menu's icon box
ZEDQA cx ok Walk to: walk (walk)
ZEDQA cx ok ContextMenu_Eat (Eat): apple
ZEDQA cx ok ContextMenu_Drink (Drink): glass
ZEDQA cx ok ContextMenu_Equip_Primary (Equip Primary): hand_main
ZEDQA cx ok ContextMenu_Barricade (Barricade (Planks)): barricade
ZEDQA cx ok a label with a changing part finds its verb's icon: book
ZEDQA cx grid x0=20 y0=20 cell=22 gap=4 per=72 n=291 box=16
ZEDQA cx ids alarm,alarm_off,ammo,ammo_off,apple,arrow_left,arrow_right,backpack,bacon,bandage,bandage_off,barricade,bath,bayonet,bed,beer,berries,blender,blood,book,bookcase,boot,bottle,bowl,box_down,box_open,box_up,brain,bread,bricks,broom,bucket,bug,bulb_off,bulb_on,bulb_remove,burger,butter,cake,campfire,can,candy,cap,car_battery,car_door,car_enter,car_exit,car_x,carrot,chair,cheese,chocolate,cigarette,citrus,climb,climb_window,cocktail,coffee_pot,coffin,comb,combine,compost,cookie,cow,craft,craft_off,crop,cup,curtains,dna,door,drop,drumstick,dumbbell,egg,egg_fried,empty,engine,equip,extinguisher,eye,eyedrop,fabric,feather,fence,fill,filter,fireplace,fish,fist,flag,flame,flask,floor,follow_me,garlic,gas_can,gas_pump,gas_siphon,gauge,gears,generator,glass,glass_empty,glass_half,grater,grill,group,guide,gun,gun_fire,hammer,hand,hand_main,hand_off,hanger,heart,help,holster,holster_left,holster_right,honey,hook,horn,hotdog,hotwire,hutch,icecream,info,jacket,jar,juice,kebab,key_off,knife,ladder,leaf,lightbar,link,lipstick,locker,mag_in,mag_out,magazine,magnifier,map,mask,match,meat,milk,minus,more,mortar,move_down,move_up,mug,mushroom,needle,no,nose,notebook,nut,oil,ointment,one,padlock,padlock_open,paint,paintbrush,pan,pancakes,pasta,patch,peapod,pencil,pepper,pet,pet_bowl,pie,pillow,pills,pin,pipe,pizza,planks,plant,pliers,plug,plus,poison,pot,potato,pour,progress,pulse,push,rack,rain,razor,reinforce,rip,rod,roller,rope,rope_climb,rotate,rounds_out,sack,sad,salad,same_type,sandwich,sauce,saw,scarf,scissors,scope,screwdriver,scythe,seed,seek,shaker,shelves,shield_minus,shield_plain,shirt,shovel,sit_ground,sit_seat,skills,skull,sledge,sleeping_bag,smiley,soup,sparkle,splint,spoon,spray,stairs,stand,star,star_off,steak,stethoscope,suppressor,swap,table,taco,tally,tap,target,tent,tent_down,thermometer,tire,to_floor,toast,toilet,tombstone,tooth,tourniquet,towel,trap,trash,tray_in,tray_out,unequip,unlink,unplug,upgrade,view_grid,view_list,waffle,walk,warning,wash_hands,washer,watch,watering_can,welder,well,whisk,window,wine,wine_glass,wires,wrap,wrench,yarn,yes
ZEDQA cx start
[ZeD.QA] run #2 ok=true
ZEDQA cx drawings not ready yet: 274
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

### 3. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 3 s

- go 14838 at 08:08:33
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #3 ok=true
ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Set Unwanted, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Rename
ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
ZEDQA cl down: sub sel 2
ZEDQA cl B: levels 1
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

### 4. zedqa_wheel_icons.lua (`ZEDQA wi`) - PASS, 24 s

- go 14839 at 08:08:40
- screenshots: zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wi no pickup within 20 tiles; spawned one beside the character: true
ZEDQA wi start car=BaseVehicle{ Name:null, ID:48 }
[ZeD.QA] run #4 ok=true
ZEDQA wi scene: screen 1920x1080, scale option 1, icon box 16 at rest, 24 pointed
ZEDQA wi PASS all 151 icons load at 16, 24, 32 and 48, each its own file (0 problems)
ZEDQA wi PASS the drawing for each box: the largest that fits, at its own size; under 16 the 16 scaled down
ZEDQA wi at this scale: box 16 draws the 16, box 24 draws the 24
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
ZEDQA wi dpad_right: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
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
ZEDQA wi car_outside: 0 slices |
ZEDQA wi NOTE car_outside: the wheel is empty here
ZEDQA wi PASS in the car: the dashboard slice has the gauge (gauge)
ZEDQA wi car_inside: 11 slices | 1:Switch Seat=seat 2:Turn Headlights on=headlight_on 3:Turn AC/Heater on=heat 4:Horn=horn 5:Device Options=speaker 6:Open Window=window_open 7:Lock all doors=padlock 8:Vehicle Mechanics=engine 9:Not tired enough to sleep.=bed 10:Exit Vehicle=car_exit 11:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside: 11 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi PASS vanilla's radials and ZeD's wheels, live: 117 slices, 117 wheel icons, 0 kept pictures
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
ZEDQA wi PASS dpad_select_1x: 12 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_1x: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes_1x: 5 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi gun_1x: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun_1x: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi light_1x: 2 slices | 1:Flashlight/Unequip=minus 2:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light_1x: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi stick_1x: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick_1x: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi car_inside_1x: 11 slices | 1:Switch Seat=seat 2:Turn Headlights on=headlight_on 3:Turn AC/Heater on=heat 4:Horn=horn 5:Device Options=speaker 6:Open Window=window_open 7:Lock all doors=padlock 8:Vehicle Mechanics=engine 9:Not tired enough to sleep.=bed 10:Exit Vehicle=car_exit 11:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside_1x: 11 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi scale back to option 1: icon box 16
ZEDQA wi 0 failed, 3 notes
ZEDQA wi DONE
```

### 5. zedqa_wheels.lua (`ZEDQA wh`) - PASS, 11 s

- go 14840 at 08:09:06
- screenshots: zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wh no pickup within 20 tiles; spawned one beside the character: true
ZEDQA wh start car=BaseVehicle{ Name:null, ID:49 } pistol=nil torch=Base.HandTorch:zombie.inventory.types.DrainableComboItem@3b59f2c1
[ZeD.QA] run #5 ok=true
ZEDQA wh outside zed=true java=UIElement n=0 x=760 y=340 w=400 vis=false point=-1 title=nil |
ZEDQA wh inside zed=true java=UIElement n=11 x=760 y=340 w=400 vis=false point=-1 title=nil | 1:Switch Seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.[off] 3:Turn Headlights on 4:Turn AC/Heater on 5:Horn 6:Device Options 7:Open Window 8:Unlock all doors 9:Vehicle Mechanics 10:Not tired enough to sleep.[off] 11:Exit Vehicle
ZEDQA wh pick test slice3 from mouse -> 3
ZEDQA wh emotes zed=true java=UIElement n=5 x=760 y=340 w=400 vis=false point=-1 title=nil | 1:Friendly 2:Hostile 3:Group 4:Signal 5:Shout
ZEDQA wh press towards 4 (Signal)
ZEDQA wh signal zed=true java=UIElement n=9 x=760 y=340 w=400 vis=true point=-1 title=Signal | 1:Cease Fire 2:Ok 3:Move Out 4:Freeze 5:Follow Behind 6:Fire 7:Come 8:Salute 9:Back
ZEDQA wh gun zed=true java=UIElement n=0 x=760 y=340 w=400 vis=false point=-1 title=nil |
ZEDQA wh light zed=true java=UIElement n=2 x=760 y=340 w=400 vis=false point=-1 title=nil | 1:Flashlight/Unequip 2:Flashlight/Turn on
ZEDQA wh back zed=true java=UIElement n=12 x=756 y=336 w=408 vis=false point=-1 title=nil | 1:Base theme/Dark 2:Accent color/PZ Teal 3:Text size/Small 4:See-through/90% 5:Controller highlight/Pointing hand 6:UI scale 7:Moodles/Right edge 8:Action bar/Verbose 9:Messages/No messages.[off] 10:Reset windows/Both windows back to where they start 11:ZeD setup/Options, on ZeD's page 12:Safe mode/The game's own interface
ZEDQA wh dright zed=true java=UIElement n=2 x=760 y=340 w=400 vis=false point=2 title=nil | 1:Flashlight/Unequip 2:Flashlight/Turn on
ZEDQA wh zone route: world=true vanillaZone=false
ZEDQA wh zone tab showing=true
ZEDQA wh search route: forage showing=true vanillaSearch=false
ZEDQA wh player info route: char=true vanillaInfo=false
ZEDQA wh DONE
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
