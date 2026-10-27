# ZeD-UI regression - 2026-10-26 20:20 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 20:20:33 |
| Finished | 2026-10-26 20:29:57 (9 min 23 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_D.txt (8 scripts) |
| Result | **6/8 pass**, 0 warn, 2 fail, 0 timeout |
| Go numbers | 13751 to 13760 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- console.txt restarted at 20:25:14 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:25:19 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:25:22 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:25:26 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:25:29 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:25:34 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:25:38 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:25:41 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:25:45 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:25:49 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:25:53 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:25:55 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:26:01 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:26:04 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 20:26:08 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- quit: quit to the main menu, then to the desktop (go 13759, 13760)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_r3_D.lua | r3D | **FAIL** | 37 | zqa_r3D_1_loot.png, zqa_r3D_2_menu_apple.png, zqa_r3D_3_menu_world.png, zqa_r3D_4_tip_shirt_zed.png, zqa_r3D_5_tip_shirt_safe.png, zqa_r3D_4_tip_book_zed.png, zqa_r3D_5_tip_book_safe.png, zqa_r3D_4_tip_vhs_zed.png, zqa_r3D_5_tip_vhs_safe.png, zqa_r3D_4_tip_seed_zed.png, zqa_r3D_5_tip_seed_safe.png, zqa_r3D_6_char_equip.png, zqa_r3D_6_char_health.png, zqa_r3D_6_char_skills.png, zqa_r3D_6_char_identity.png, zqa_r3D_7_world_craft.png, zqa_r3D_7_world_build.png, zqa_r3D_7_world_maps.png, zqa_r3D_8_moodles.png | 9 Java exception(s) in the log |
| 3 | zedqa_r3_D_cars.lua | cv | **FAIL** | 180 | zqa_r3D_cv_1_dash.png, zqa_r3D_cv_1_tab.png, zqa_r3D_cv_2_dash.png, zqa_r3D_cv_2_tab.png, zqa_r3D_cv_3_dash.png, zqa_r3D_cv_3_tab.png, zqa_r3D_cv_4_dash.png, zqa_r3D_cv_4_tab.png, zqa_r3D_cv_5_dash.png, zqa_r3D_cv_5_tab.png, zqa_r3D_cv_6_dash.png, zqa_r3D_cv_6_tab.png, zqa_r3D_cv_7_dash.png, zqa_r3D_cv_7_tab.png, zqa_r3D_cv_8_tab.png, zqa_r3D_cv_9_tab.png, zqa_r3D_cv_10_dash.png, zqa_r3D_cv_10_tab.png, zqa_r3D_cv_11_dash.png, zqa_r3D_cv_11_tab.png, zqa_r3D_cv_12_dash.png, zqa_r3D_cv_12_tab.png, zqa_r3D_cv_13_dash.png, zqa_r3D_cv_13_tab.png, zqa_r3D_cv_14_dash.png, zqa_r3D_cv_14_tab.png, zqa_r3D_cv_15_dash.png, zqa_r3D_cv_15_tab.png, zqa_r3D_cv_16_dash.png, zqa_r3D_cv_16_tab.png, zqa_r3D_cv_17_dash.png, zqa_r3D_cv_17_tab.png, zqa_r3D_cv_18_dash.png, zqa_r3D_cv_18_tab.png, zqa_r3D_cv_19_dash.png, zqa_r3D_cv_19_tab.png, zqa_r3D_cv_20_dash.png, zqa_r3D_cv_20_tab.png | 8 Java exception(s) in the log; 8 ERR line(s) |
| 4 | suite_tabs.lua | tabs | PASS | 9 |  |  |
| 5 | zedqa_seat_lightbar_vanilla.lua | sl | PASS | 21 | zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png |  |
| 6 | zedqa_car_radio_build.lua | rb | PASS | 34 | zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png |  |
| 7 | zedqa_car_radio_cd.lua | cd | PASS | 13 | zqa_cd_c01_cdlist.png, zqa_cd_c02_cd_playing.png, zqa_cd_c03_ejected.png, zqa_cd_c04_valutech_tape.png |  |
| 8 | zedqa_tm.lua | tm | PASS | 7 | zedqa_tm_tooltips.png, zedqa_tm_maps.png, zedqa_tm_dash.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 13751 at 20:22:26

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pre start
:	[ZeD.QA] run #1 ok=true
:	ZEDQA pre char true world true speed 1 ticks 60 frames 61
:	ZEDQA pre search overlay: enabled false, override false, manager false
:	ZEDQA pre DONE
```

### 2. zedqa_r3_D.lua (`ZEDQA r3D`) - FAIL, 37 s

- go 13752 at 20:22:32
- 9 Java exception(s) in the log
- screenshots: zqa_r3D_1_loot.png, zqa_r3D_2_menu_apple.png, zqa_r3D_3_menu_world.png, zqa_r3D_4_tip_shirt_zed.png, zqa_r3D_5_tip_shirt_safe.png, zqa_r3D_4_tip_book_zed.png, zqa_r3D_5_tip_book_safe.png, zqa_r3D_4_tip_vhs_zed.png, zqa_r3D_5_tip_vhs_safe.png, zqa_r3D_4_tip_seed_zed.png, zqa_r3D_5_tip_seed_safe.png, zqa_r3D_6_char_equip.png, zqa_r3D_6_char_health.png, zqa_r3D_6_char_skills.png, zqa_r3D_6_char_identity.png, zqa_r3D_7_world_craft.png, zqa_r3D_7_world_build.png, zqa_r3D_7_world_maps.png, zqa_r3D_8_moodles.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA r3D start
:	[ZeD.QA] run #2 ok=true
:	ZEDQA r3D shot zqa_r3D_1_loot.png
:	ZEDQA r3D ui loot: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA r3D vanilla loot: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3D menu apple: Eat, Drop, Place Item, More, Move to, Rename
:	ZEDQA r3D shot zqa_r3D_2_menu_apple.png
:	ZEDQA r3D menu shirt: Wear, Rip Clothing, Craft, Inspect, Drop, Place Item, More, Move to, Rename
:	ZEDQA r3D menu book: Equip Primary, Equip Secondary, Read, Craft, Drop, Place Item, More, Move to, Rename
:	ZEDQA r3D menu bag: Wear, Equip Primary, Equip Secondary, Drop, Place Item, More, Move to
WARN : General f:1199> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.MissingFormatArgumentException: Format specifier '%1$s' at Formatter.format(null:-1). Message: ERROR: Missing arguments for "IGUI_bikinitools_A_RemovePlantsInArea"   (x3)
WARN : General f:1199> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.MissingFormatArgumentException: Format specifier '%1$s' at Formatter.format(null:-1). Message: ERROR: Missing arguments for "IGUI_bikinitools_A_RemoveGrassInArea"   (x3)
WARN : General f:1199> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.MissingFormatArgumentException: Format specifier '%1$s' at Formatter.format(null:-1). Message: ERROR: Missing arguments for "IGUI_bikinitools_A_RemoveShrubsInArea"   (x3)
:	ZEDQA r3D world menu: Claimed Vehicles Manager, Sit on ground, Walk to, bikinitools, |, Admin [Mods]
:	ZEDQA r3D shot zqa_r3D_3_menu_world.png
:	ZEDQA r3D shot zqa_r3D_4_tip_shirt_zed.png
:	ZEDQA r3D tip shirt zed 238x96
:	ZEDQA r3D shot zqa_r3D_5_tip_shirt_safe.png
:	ZEDQA r3D tip shirt safe 238x96
:	ZEDQA r3D shot zqa_r3D_4_tip_book_zed.png
:	ZEDQA r3D tip book zed 297x79
:	ZEDQA r3D shot zqa_r3D_5_tip_book_safe.png
:	ZEDQA r3D tip book safe 297x79
:	ZEDQA r3D shot zqa_r3D_4_tip_vhs_zed.png
:	ZEDQA r3D tip vhs zed 189x45
:	ZEDQA r3D shot zqa_r3D_5_tip_vhs_safe.png
:	ZEDQA r3D tip vhs safe 189x45
:	ZEDQA r3D shot zqa_r3D_4_tip_seed_zed.png
:	ZEDQA r3D tip seed zed 202x79
:	ZEDQA r3D shot zqa_r3D_5_tip_seed_safe.png
:	ZEDQA r3D tip seed safe 202x79
:	ZEDQA r3D ui after safe mode: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA r3D vanilla after safe mode: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3D shot zqa_r3D_6_char_equip.png
:	ZEDQA r3D shot zqa_r3D_6_char_health.png
:	ZEDQA r3D shot zqa_r3D_6_char_skills.png
:	ZEDQA r3D shot zqa_r3D_6_char_identity.png
:	ZEDQA r3D shot zqa_r3D_7_world_craft.png
:	ZEDQA r3D shot zqa_r3D_7_world_build.png
:	ZEDQA r3D shot zqa_r3D_7_world_maps.png
:	ZEDQA r3D ui tabs walked: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA r3D vanilla tabs walked: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3D ui moodles: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA r3D vanilla moodles: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3D shot zqa_r3D_8_moodles.png
:	ZEDQA r3D ui end: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA r3D vanilla end: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3D DONE
```

### 3. zedqa_r3_D_cars.lua (`ZEDQA cv`) - FAIL, 180 s

- go 13753 at 20:23:12
- 8 Java exception(s) in the log
- 8 ERR line(s)
- screenshots: zqa_r3D_cv_1_dash.png, zqa_r3D_cv_1_tab.png, zqa_r3D_cv_2_dash.png, zqa_r3D_cv_2_tab.png, zqa_r3D_cv_3_dash.png, zqa_r3D_cv_3_tab.png, zqa_r3D_cv_4_dash.png, zqa_r3D_cv_4_tab.png, zqa_r3D_cv_5_dash.png, zqa_r3D_cv_5_tab.png, zqa_r3D_cv_6_dash.png, zqa_r3D_cv_6_tab.png, zqa_r3D_cv_7_dash.png, zqa_r3D_cv_7_tab.png, zqa_r3D_cv_8_tab.png, zqa_r3D_cv_9_tab.png, zqa_r3D_cv_10_dash.png, zqa_r3D_cv_10_tab.png, zqa_r3D_cv_11_dash.png, zqa_r3D_cv_11_tab.png, zqa_r3D_cv_12_dash.png, zqa_r3D_cv_12_tab.png, zqa_r3D_cv_13_dash.png, zqa_r3D_cv_13_tab.png, zqa_r3D_cv_14_dash.png, zqa_r3D_cv_14_tab.png, zqa_r3D_cv_15_dash.png, zqa_r3D_cv_15_tab.png, zqa_r3D_cv_16_dash.png, zqa_r3D_cv_16_tab.png, zqa_r3D_cv_17_dash.png, zqa_r3D_cv_17_tab.png, zqa_r3D_cv_18_dash.png, zqa_r3D_cv_18_tab.png, zqa_r3D_cv_19_dash.png, zqa_r3D_cv_19_tab.png, zqa_r3D_cv_20_dash.png, zqa_r3D_cv_20_tab.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA cv modded vehicle scripts: 20 to try, from 11 Workshop items
:	ZEDQA cv start
:	[ZeD.QA] run #3 ok=true
ERROR: General f:2874 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:2881 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
:	ZEDQA cv PASS vanilla Base.CarNormal: spawns
:	ZEDQA cv vanilla Base.CarNormal: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS vanilla Base.CarNormal: the dashboard shows with a design
:	ZEDQA cv PASS vanilla Base.CarNormal: the dashboard is on screen
:	ZEDQA cv ui Base.CarNormal seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv vanilla Base.CarNormal: Vehicle tab true, 59 parts
:	ZEDQA cv PASS vanilla Base.CarNormal: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.CarNormal vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv PASS 2791656602 Base.fhqH1: spawns
:	ZEDQA cv 2791656602 Base.fhqH1: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 2791656602 Base.fhqH1: the dashboard shows with a design
:	ZEDQA cv PASS 2791656602 Base.fhqH1: the dashboard is on screen
:	ZEDQA cv ui Base.fhqH1 seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv 2791656602 Base.fhqH1: Vehicle tab true, 41 parts
:	ZEDQA cv PASS 2791656602 Base.fhqH1: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.fhqH1 vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv PASS 2791656602 Base.fhqAZ1: spawns
:	ZEDQA cv 2791656602 Base.fhqAZ1: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 2791656602 Base.fhqAZ1: the dashboard shows with a design
:	ZEDQA cv PASS 2791656602 Base.fhqAZ1: the dashboard is on screen
:	ZEDQA cv ui Base.fhqAZ1 seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv 2791656602 Base.fhqAZ1: Vehicle tab true, 37 parts
:	ZEDQA cv PASS 2791656602 Base.fhqAZ1: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.fhqAZ1 vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv PASS 2843855721 Base.U1550L: spawns
:	ZEDQA cv 2843855721 Base.U1550L: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 2843855721 Base.U1550L: the dashboard shows with a design
:	ZEDQA cv PASS 2843855721 Base.U1550L: the dashboard is on screen
:	ZEDQA cv ui Base.U1550L seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv 2843855721 Base.U1550L: Vehicle tab true, 49 parts
:	ZEDQA cv PASS 2843855721 Base.U1550L: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.U1550L vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv PASS 2843855721 Base.U1550LOffRoad: spawns
:	ZEDQA cv 2843855721 Base.U1550LOffRoad: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 2843855721 Base.U1550LOffRoad: the dashboard shows with a design
:	ZEDQA cv PASS 2843855721 Base.U1550LOffRoad: the dashboard is on screen
:	ZEDQA cv ui Base.U1550LOffRoad seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv 2843855721 Base.U1550LOffRoad: Vehicle tab true, 40 parts
:	ZEDQA cv PASS 2843855721 Base.U1550LOffRoad: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.U1550LOffRoad vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv PASS 3404737883 Base.AMC_quad: spawns
:	ZEDQA cv 3404737883 Base.AMC_quad: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3404737883 Base.AMC_quad: the dashboard shows with a design
:	ZEDQA cv PASS 3404737883 Base.AMC_quad: the dashboard is on screen
:	ZEDQA cv ui Base.AMC_quad seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv 3404737883 Base.AMC_quad: Vehicle tab true, 27 parts
:	ZEDQA cv PASS 3404737883 Base.AMC_quad: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.AMC_quad vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv PASS 3404737883 Base.AMC_harley: spawns
:	ZEDQA cv 3404737883 Base.AMC_harley: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3404737883 Base.AMC_harley: the dashboard shows with a design
:	ZEDQA cv PASS 3404737883 Base.AMC_harley: the dashboard is on screen
:	ZEDQA cv ui Base.AMC_harley seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv 3404737883 Base.AMC_harley: Vehicle tab true, 27 parts
:	ZEDQA cv PASS 3404737883 Base.AMC_harley: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.AMC_harley vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv PASS 3402493701 Base.TrailerHome: spawns
:	ZEDQA cv 3402493701 Base.TrailerHome: Vehicle tab false, 37 parts
:	ZEDQA cv FAIL 3402493701 Base.TrailerHome: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.TrailerHome vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv PASS 3402493701 Base.TrailerKbac: spawns
ERROR: General f:5277 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: setContainerContentAmount of non-table: null
ERROR: General f:5277> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: setContainerContentAmount of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(worldmap-annotations.lua:116)
    Lua(Vanilla).t(worldmap-annotations.lua:116)
    Lua(Vanilla).tick(worldmap-annotations.lua:171)
:	ZEDQA cv 3402493701 Base.TrailerKbac: Vehicle tab false, 7 parts
:	ZEDQA cv FAIL 3402493701 Base.TrailerKbac: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.TrailerKbac vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,595x53 ; ISButton@3813,2051,22x22
:	ZEDQA cv PASS 3402812859 Base.ATAArmyBus: spawns
:	ZEDQA cv 3402812859 Base.ATAArmyBus: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3402812859 Base.ATAArmyBus: the dashboard shows with a design
:	ZEDQA cv PASS 3402812859 Base.ATAArmyBus: the dashboard is on screen
:	ZEDQA cv ui Base.ATAArmyBus seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,595x53 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3402812859 Base.ATAArmyBus: Vehicle tab true, 60 parts
:	ZEDQA cv PASS 3402812859 Base.ATAArmyBus: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.ATAArmyBus vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv PASS 3402812859 Base.ATAPrisonBus: spawns
:	ZEDQA cv 3402812859 Base.ATAPrisonBus: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3402812859 Base.ATAPrisonBus: the dashboard shows with a design
:	ZEDQA cv PASS 3402812859 Base.ATAPrisonBus: the dashboard is on screen
:	ZEDQA cv ui Base.ATAPrisonBus seated: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3402812859 Base.ATAPrisonBus: Vehicle tab true, 51 parts
:	ZEDQA cv PASS 3402812859 Base.ATAPrisonBus: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.ATAPrisonBus vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
ERROR: General f:6042 at LuaManager.getFunctionObject > no such function "Vehicles.Create.HeliRocketPodSafe"
:	ZEDQA cv PASS 3409723807 Base.UH1BHuey: spawns
:	ZEDQA cv 3409723807 Base.UH1BHuey: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3409723807 Base.UH1BHuey: the dashboard shows with a design
:	ZEDQA cv PASS 3409723807 Base.UH1BHuey: the dashboard is on screen
:	ZEDQA cv ui Base.UH1BHuey seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ISHelicopterHUD@1644,1918,552x242 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3409723807 Base.UH1BHuey: Vehicle tab true, 33 parts
:	ZEDQA cv PASS 3409723807 Base.UH1BHuey: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.UH1BHuey vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv PASS 3409723807 Base.UH1BHueyBurnt: spawns
ERROR: General f:6297 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: setContainerContentAmount of non-table: null
ERROR: General f:6297> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: setContainerContentAmount of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(worldmap-annotations.lua:116)
    Lua(Vanilla).t(worldmap-annotations.lua:116)
    Lua(Vanilla).tick(worldmap-annotations.lua:171)
ERROR: General f:6297 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: isDriver of non-table: null
ERROR: General f:6297> Lua(Vanilla).onEnterVehicle> Exception thrown
    java.lang.RuntimeException: attempted index: isDriver of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).onEnterVehicle(ISVehicleDashboard.lua:603)
    Lua(Vanilla).t(worldmap-annotations.lua:123)
    Lua(Vanilla).tick(worldmap-annotations.lua:171)
:	ZEDQA cv 3409723807 Base.UH1BHueyBurnt: design nyala, dashboard false at 1120,1804 1600x344
:	ZEDQA cv FAIL 3409723807 Base.UH1BHueyBurnt: the dashboard shows with a design
:	ZEDQA cv FAIL 3409723807 Base.UH1BHueyBurnt: the dashboard is on screen
:	ZEDQA cv ui Base.UH1BHueyBurnt seated: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3409723807 Base.UH1BHueyBurnt: Vehicle tab false, 0 parts
:	ZEDQA cv FAIL 3409723807 Base.UH1BHueyBurnt: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.UH1BHueyBurnt vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv PASS 3683878228 Base.fr_gr_llv_89: spawns
:	ZEDQA cv 3683878228 Base.fr_gr_llv_89: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3683878228 Base.fr_gr_llv_89: the dashboard shows with a design
:	ZEDQA cv PASS 3683878228 Base.fr_gr_llv_89: the dashboard is on screen
:	ZEDQA cv ui Base.fr_gr_llv_89 seated: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ISVehicleDashboard@1346,1948,1148x212 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3683878228 Base.fr_gr_llv_89: Vehicle tab true, 45 parts
:	ZEDQA cv PASS 3683878228 Base.fr_gr_llv_89: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.fr_gr_llv_89 vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv PASS 3683878228 Base.fr_po_gto_65: spawns
:	ZEDQA cv 3683878228 Base.fr_po_gto_65: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3683878228 Base.fr_po_gto_65: the dashboard shows with a design
:	ZEDQA cv PASS 3683878228 Base.fr_po_gto_65: the dashboard is on screen
:	ZEDQA cv ui Base.fr_po_gto_65 seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3683878228 Base.fr_po_gto_65: Vehicle tab true, 53 parts
:	ZEDQA cv PASS 3683878228 Base.fr_po_gto_65: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.fr_po_gto_65 vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv PASS 3775809123 Base.DashRoamer: spawns
:	ZEDQA cv 3775809123 Base.DashRoamer: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3775809123 Base.DashRoamer: the dashboard shows with a design
:	ZEDQA cv PASS 3775809123 Base.DashRoamer: the dashboard is on screen
:	ZEDQA cv ui Base.DashRoamer seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ISVehicleDashboard@1346,1948,1148x212 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3775809123 Base.DashRoamer: Vehicle tab true, 55 parts
:	ZEDQA cv PASS 3775809123 Base.DashRoamer: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.DashRoamer vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv PASS 3775809123 Base.DashRoamerStellarCommand: spawns
:	ZEDQA cv 3775809123 Base.DashRoamerStellarCommand: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3775809123 Base.DashRoamerStellarCommand: the dashboard shows with a design
:	ZEDQA cv PASS 3775809123 Base.DashRoamerStellarCommand: the dashboard is on screen
:	ZEDQA cv ui Base.DashRoamerStellarCommand seated: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3775809123 Base.DashRoamerStellarCommand: Vehicle tab true, 55 parts
:	ZEDQA cv PASS 3775809123 Base.DashRoamerStellarCommand: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.DashRoamerStellarCommand vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv PASS 3409472393 Base.SemiTruck: spawns
:	ZEDQA cv 3409472393 Base.SemiTruck: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3409472393 Base.SemiTruck: the dashboard shows with a design
:	ZEDQA cv PASS 3409472393 Base.SemiTruck: the dashboard is on screen
:	ZEDQA cv ui Base.SemiTruck seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3409472393 Base.SemiTruck: Vehicle tab true, 59 parts
:	ZEDQA cv PASS 3409472393 Base.SemiTruck: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.SemiTruck vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv PASS 3409472393 Base.SemiTruckBox: spawns
:	ZEDQA cv 3409472393 Base.SemiTruckBox: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3409472393 Base.SemiTruckBox: the dashboard shows with a design
:	ZEDQA cv PASS 3409472393 Base.SemiTruckBox: the dashboard is on screen
:	ZEDQA cv ui Base.SemiTruckBox seated: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3409472393 Base.SemiTruckBox: Vehicle tab true, 55 parts
:	ZEDQA cv PASS 3409472393 Base.SemiTruckBox: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.SemiTruckBox vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
ERROR: General f:8082 at LuaManager.getFunctionObject > no such function "Vehicles.Create.PC_Default"   (x2)
ERROR: General f:8082 at LuaManager.getFunctionObject > no such function "Vehicles.Create.ANTENNA"   (x2)
ERROR: General f:8082 at LuaManager.getFunctionObject > no such function "Vehicles.Create.TORRENTA"
ERROR: General f:8082 at LuaManager.getFunctionObject > no such function "Vehicles.Create.PC_Default"   (x8)
ERROR: General f:8082 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getConditionMax of non-table: null
ERROR: General f:8082> Lua(Vanilla).createPartInventoryItem> Exception thrown
    java.lang.RuntimeException: attempted index: getConditionMax of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).createPartInventoryItem(Vehicles.lua:1180)
    Lua(Vanilla).Tire(Vehicles.lua:394)
    Lua(Vanilla).t(worldmap-annotations.lua:112)
    Lua(Vanilla).tick(worldmap-annotations.lua:171)
ERROR: General f:8082 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getConditionMax of non-table: null
ERROR: General f:8082> Lua(Vanilla).createPartInventoryItem> Exception thrown
    java.lang.RuntimeException: attempted index: getConditionMax of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).createPartInventoryItem(Vehicles.lua:1180)
    Lua(Vanilla).Tire(Vehicles.lua:394)
    Lua(Vanilla).t(worldmap-annotations.lua:112)
    Lua(Vanilla).tick(worldmap-annotations.lua:171)
ERROR: General f:8082 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getConditionMax of non-table: null
ERROR: General f:8082> Lua(Vanilla).createPartInventoryItem> Exception thrown
    java.lang.RuntimeException: attempted index: getConditionMax of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).createPartInventoryItem(Vehicles.lua:1180)
    Lua(Vanilla).Tire(Vehicles.lua:394)
    Lua(Vanilla).t(worldmap-annotations.lua:112)
    Lua(Vanilla).tick(worldmap-annotations.lua:171)
ERROR: General f:8082 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getConditionMax of non-table: null
ERROR: General f:8082> Lua(Vanilla).createPartInventoryItem> Exception thrown
    java.lang.RuntimeException: attempted index: getConditionMax of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).createPartInventoryItem(Vehicles.lua:1180)
    Lua(Vanilla).Tire(Vehicles.lua:394)
    Lua(Vanilla).t(worldmap-annotations.lua:112)
    Lua(Vanilla).tick(worldmap-annotations.lua:171)
ERROR: General f:8082 at LuaManager.getFunctionObject > no such function "Vehicles.Create.DefaultRAMDOM"   (x3)
ERROR: General f:8082 at LuaManager.getFunctionObject > no such function "Vehicles.Init.PC_Default"   (x2)
ERROR: General f:8082 at LuaManager.getFunctionObject > no such function "Vehicles.Init.ItemANTENNA"   (x2)
ERROR: General f:8082 at LuaManager.getFunctionObject > no such function "Vehicles.Init.TORRENTA"
ERROR: General f:8082 at LuaManager.getFunctionObject > no such function "Vehicles.Init.PC_Default"   (x8)
:	ZEDQA cv PASS 3554424111 Base.M998_Humvee: spawns
ERROR: General f:8082 at LuaManager.getFunctionObject > no such function "Vehicles.Init.PC_Default"   (x10)
ERROR: General f:8082 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: isDriver of non-table: null
ERROR: General f:8082> Lua(Vanilla).onEnterVehicle> Exception thrown
    java.lang.RuntimeException: attempted index: isDriver of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).onEnterVehicle(ISVehicleDashboard.lua:603)
    Lua(Vanilla).t(worldmap-annotations.lua:123)
    Lua(Vanilla).tick(worldmap-annotations.lua:171)
:	ZEDQA cv 3554424111 Base.M998_Humvee: design nyala, dashboard false at 1120,1804 1600x344
:	ZEDQA cv FAIL 3554424111 Base.M998_Humvee: the dashboard shows with a design
:	ZEDQA cv FAIL 3554424111 Base.M998_Humvee: the dashboard is on screen
:	ZEDQA cv ui Base.M998_Humvee seated: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3554424111 Base.M998_Humvee: Vehicle tab false, 54 parts
:	ZEDQA cv FAIL 3554424111 Base.M998_Humvee: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.M998_Humvee vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv back home 12057,11756
:	ZEDQA cv 76 checks, 8 failed
:	ZEDQA cv 8 failed
:	ZEDQA cv DONE
```

### 4. suite_tabs.lua (`ZEDQA tabs`) - PASS, 9 s

- go 13754 at 20:27:14

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
:	ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals
:	ZEDQA tabs armed
:	[ZeD.QA] run #4 ok=true
:	ZEDQA char tab=loot active=loot w=777 focusables=0 {}
:	ZEDQA char tab=equip active=equip w=1617 focusables=31 {equipgroup=5 equippart=17 equipslot=7 equipview=2}
:	ZEDQA char tab=health active=health w=1617 focusables=27 {bodypart=17 exercise=9 health=1}
:	ZEDQA char tab=thermal active=thermal w=1617 focusables=26 {thermal=9 thermalpart=17}
:	ZEDQA char tab=identity active=identity w=1617 focusables=55 {hb=26 identity=29}
:	ZEDQA char tab=journal active=journal w=1617 focusables=8 {journal=4 jsub=4}
:	ZEDQA char tab=skills active=skills w=1617 focusables=60 {skill=35 skills=1 training=24}
:	ZEDQA world tab=loot active=loot w=777 focusables=0 {}
:	ZEDQA world tab=craft active=craft w=1617 focusables=10 {craft=10}
:	ZEDQA world tab=build active=build w=1617 focusables=8 {build=8}
:	ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
:	ZEDQA world tab=maps active=maps w=1682 focusables=19 {map=19}
:	ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
:	ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
:	ZEDQA tabs done
```

### 5. zedqa_seat_lightbar_vanilla.lua (`ZEDQA sl`) - PASS, 21 s

- go 13755 at 20:27:31
- screenshots: zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA sl start
:	[ZeD.QA] run #5 ok=true
:	ZEDQA sl pickup=BaseVehicle{ Name:null, ID:122 } police=BaseVehicle{ Name:null, ID:123 } van=BaseVehicle{ Name:null, ID:124 }
:	ZEDQA sl enter Base.PickUpTruck dist=5.8 physics=true
:	ZEDQA sl enter Base.CarLightsKST dist=10.5 physics=false
:	ZEDQA sl lightbar x=1705 y=940 w=430 h=280
:	ZEDQA sl enter Base.VanSeats dist=7.6 physics=true
:	ZEDQA sl DONE
```

### 6. zedqa_car_radio_build.lua (`ZEDQA rb`) - PASS, 34 s

- go 13756 at 20:28:01
- screenshots: zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA rb start
:	[ZeD.QA] run #6 ok=true
:	ZEDQA rb spawned Base.PickUpTruck beside the character
:	ZEDQA rb spawned Base.CarLightsPolice beside the character
:	ZEDQA rb Base.PickUpTruck radio=Base.RadioBlack
:	ZEDQA rb Base.ModernCarLightsMeadeSheriff radio=Base.HamRadio1
:	ZEDQA rb dash only kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=101200 vol=1 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=89.4 Hitz FM]
:	ZEDQA rb prop visible=nil at nil,nil nilxnil vanilla window=false
:	ZEDQA rb premium off kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=101200 vol=1 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=89.4 Hitz FM]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb premium power via vanilla's action ok=true canBePoweredHere=true battery=0.8812800049781799
:	ZEDQA rb premium on kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=89.4 Hitz FM]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb store 4 -> 4
:	ZEDQA rb premium stored kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=STORE 4 mic=false
:	ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb cds carried: 0
:	ZEDQA rb insert ok=true
:	ZEDQA rb cd in kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb play ok=false
:	ZEDQA rb cd playing kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb eject ok=false
:	ZEDQA rb ejected kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb fit Base.RadioBlack ok=true nil
:	ZEDQA rb valutech kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=98000 vol=0.6000000238418579 preset=2 name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb fit Base.RadioMakeShift ok=true nil
:	ZEDQA rb makeshift kind=makeshift item=Base.RadioMakeShift on=true switch=true powered=true ch=89400 vol=0.6000000238418579 preset=nil name=Hitz FM signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio]
:	ZEDQA rb prop visible=true at 1828,1536 880x256 vanilla window=false
:	ZEDQA rb fit Base.RadioBlack ok=true nil
:	ZEDQA rb pickup restored kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=98400 vol=0.6000000238418579 preset=nil name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio]
:	ZEDQA rb prop visible=false at 1828,1536 880x256 vanilla window=false
:	ZEDQA rb ham power via vanilla's action ok=true canBePoweredHere=true battery=0.8916299939155579
:	ZEDQA rb ham kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=2 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=91.2 Civilian Radio; 2=98.4 Automated Emergency Broadcast System]
:	ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
:	ZEDQA rb ham mic off kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=2 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=true
:	ZEDQA rb presets [1=91.2 Civilian Radio; 2=98.4 Automated Emergency Broadcast System]
:	ZEDQA rb prop visible=true at 1708,1480 1000x312 vanilla window=false
:	ZEDQA rb mem -> 3
:	ZEDQA rb ham mem kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=146600 vol=1 preset=3 name=nil signal=false media=false playing=false title=nil flash=CH 03 STORED mic=false
:	ZEDQA rb presets [1=91.2 Civilian Radio; 2=98.4 Automated Emergency Broadcast System; 3=146.6 146.600 MHz]
:	ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
:	ZEDQA rb siren opened; radio still up = false
:	ZEDQA rb fit Base.HamRadio2 ok=true nil
:	ZEDQA rb army kind=army item=Base.HamRadio2 on=true switch=true powered=true ch=98400 vol=1 preset=2 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=91.2 Civilian Radio; 2=98.4 Automated Emergency Broadcast System; 3=146.6 146.600 MHz]
:	ZEDQA rb prop visible=true at 1708,1492 1000x300 vanilla window=false
:	ZEDQA rb fit Base.HamRadioMakeShift ok=true nil
:	ZEDQA rb hammake kind=hammake item=Base.HamRadioMakeShift on=true switch=true powered=true ch=98000 vol=1 preset=nil name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=91.2 Civilian Radio; 2=98.4 Automated Emergency Broadcast System; 3=146.6 146.600 MHz]
:	ZEDQA rb prop visible=true at 1708,1516 1000x276 vanilla window=false
:	ZEDQA rb fit Base.HamRadio1 ok=true nil
:	ZEDQA rb police restored kind=ham item=Base.HamRadio1 on=false switch=false powered=true ch=175400 vol=1 preset=nil name=nil signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=91.2 Civilian Radio; 2=98.4 Automated Emergency Broadcast System]
:	ZEDQA rb prop visible=false at 1708,1516 1000x276 vanilla window=false
:	ZEDQA rb DONE
```

### 7. zedqa_car_radio_cd.lua (`ZEDQA cd`) - PASS, 13 s

- go 13757 at 20:28:44
- screenshots: zqa_cd_c01_cdlist.png, zqa_cd_c02_cd_playing.png, zqa_cd_c03_ejected.png, zqa_cd_c04_valutech_tape.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA cd start
:	[ZeD.QA] run #7 ok=true
:	ZEDQA cd spawned Base.PickUpTruck beside the character
:	ZEDQA cd pickup BaseVehicle{ Name:null, ID:127 } radio=Base.RadioBlack
:	ZEDQA cd hand font height 17
:	ZEDQA cd vanilla CD recordings: 69
:	ZEDQA cd cd isRecordedMedia=true mediaType=0 name=CD: My Boy Asked Me...
:	ZEDQA cd cds carried: 0
:	ZEDQA cd inserted kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
:	ZEDQA cd play ok=false
:	ZEDQA cd playing kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
:	ZEDQA cd eject ok=false
:	ZEDQA cd ejected kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
:	ZEDQA cd disc back in inventory: true
:	ZEDQA cd fit Base.RadioBlack
:	ZEDQA cd valutech kind=valutech on=false ch=89400 media=false playing=false title=nil cdMs=nil
:	ZEDQA cd fit Base.RadioRed
:	ZEDQA cd DONE
```

### 8. zedqa_tm.lua (`ZEDQA tm`) - PASS, 7 s

- go 13758 at 20:29:07
- screenshots: zedqa_tm_tooltips.png, zedqa_tm_maps.png, zedqa_tm_dash.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA tm armed
:	[ZeD.QA] run #8 ok=true
:	ZEDQA tm root=1.75 proxy=true realTM=true
:	ZEDQA tm tip1 462.78125x223.7421875 at 300,300 desc=349.78125x136.59375 lines=4 font=MainMenu1
:	ZEDQA tm tip2 420x194.890625 at 300,620 desc=367x194.890625 lines=6 font=MainMenu1
:	ZEDQA tm watch family=nil size=228x52 at 3596,10
:	ZEDQA tm maps tab clicked maps
:	ZEDQA tm world tabs loot,craft,build,furniture,maps,forage,animals
:	ZEDQA tm maps shot active=maps win=1929,0 1682x735
:	ZEDQA tm dash design=horizon visible=true size=1600x344 at 1120,1804
:	ZEDQA tm done
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Jet Fuel Barrel', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    3x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Body"
```
