# ZeD-UI regression - 2026-10-29 23:31 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 23:31:32 |
| Finished | 2026-10-29 23:56:14 (24 min 41 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/t12_last.txt (7 scripts) |
| Result | **4/7 pass**, 3 warn, 0 fail, 0 timeout |
| Go numbers | 16254 to 16262 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 16261, 16262)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | zedqa_dash_green.lua | dgr | WARN | 146 | zqa_dgr_d6_parked_day.png, zqa_dgr_d6_parked_day_keyin.png, zqa_dgr_suv_night_on.png, zqa_dgr_suv_night_off.png | 11 ERR line(s) |
| 3 | zedqa_dash_keys_edge.lua | dke | WARN | 313 | zqa_dke_luxury_off.png, zqa_dke_luxury_start.png, zqa_dke_luxury_on.png, zqa_dke_suv_off.png, zqa_dke_suv_start.png, zqa_dke_suv_on.png | 17 ERR line(s) |
| 4 | zedqa_dash_brands.lua | dbr | WARN | 277 |  | 17 ERR line(s) |
| 5 | zedqa_testlang.lua | tlang | PASS | 126 | zqa_tl_01_char_loot_list.png, zqa_tl_02_char_loot_grid.png, zqa_tl_03_card_food.png, zqa_tl_04_card_weapon.png, zqa_tl_05_card_bottle.png, zqa_tl_06_card_gun.png, zqa_tl_07_char_equip_list.png, zqa_tl_08_char_equip_doll.png, zqa_tl_09_char_health.png, zqa_tl_10_char_thermal_1.png, zqa_tl_11_char_thermal_2.png, zqa_tl_12_char_thermal_3.png, zqa_tl_13_char_thermal_4.png, zqa_tl_14_char_thermal_5.png, zqa_tl_15_char_thermal_6.png, zqa_tl_16_char_thermal_7.png, zqa_tl_17_char_thermal_figure.png, zqa_tl_18_char_identity.png, zqa_tl_19_char_journal_1.png, zqa_tl_20_char_journal_2.png, zqa_tl_21_char_journal_3.png, zqa_tl_22_char_journal_4.png, zqa_tl_23_char_skills.png, zqa_tl_24_char_radio.png, zqa_tl_25_char_loot_back.png, zqa_tl_26_ctx_strip_food.png, zqa_tl_27_ctx_strip_weapon.png, zqa_tl_28_ctx_list_food.png, zqa_tl_29_ctx_list_submenu.png, zqa_tl_30_world_loot.png, zqa_tl_31_world_craft_list.png, zqa_tl_32_world_craft_recipe.png, zqa_tl_33_world_build_list.png, zqa_tl_34_world_build_recipe.png, zqa_tl_35_world_furniture.png, zqa_tl_36_world_furniture_rotate.png, zqa_tl_37_world_furniture_scrap.png, zqa_tl_38_world_furniture_repair.png, zqa_tl_39_world_furniture_pickup.png, zqa_tl_40_world_maps.png, zqa_tl_41_world_maps_survey.png, zqa_tl_42_world_maps_color.png, zqa_tl_43_world_maps_paper.png, zqa_tl_44_world_forage.png, zqa_tl_45_world_animals.png, zqa_tl_46_belt_watch_tucked.png, zqa_tl_47_belt_watch_popped.png, zqa_tl_48_watch_corner.png, zqa_tl_49_actionbar_reading_verbose.png, zqa_tl_50_actionbar_reading_simple.png, zqa_tl_51_wheel_emotes.png, zqa_tl_52_wheel_vehicle_outside.png, zqa_tl_53_prompt_question.png, zqa_tl_54_prompt_textbox.png, zqa_tl_55_prompt_textbox_empty.png, zqa_tl_56_prompt_keyboard.png, zqa_tl_57_prompt_alarm.png, zqa_tl_58_prompt_timer.png, zqa_tl_59_prompt_help.png, zqa_tl_60_prompt_rich_question.png, zqa_tl_61_safe_note.png, zqa_tl_62_pause_menu.png, zqa_tl_63_options_1_zed.png, zqa_tl_64_options_2_display.png, zqa_tl_65_options_3_graphics.png, zqa_tl_66_options_4_audio.png, zqa_tl_67_options_5_controls.png, zqa_tl_68_options_6_gameplay.png, zqa_tl_69_options_7_interface.png, zqa_tl_70_options_8_access.png, zqa_tl_71_options_9_mods.png, zqa_tl_72_pause_mods.png |  |
| 6 | zedqa_safemode.lua | safe | PASS | 12 | zqa_safe_1.png, zqa_safe_2.png, zqa_safe_3.png |  |
| 7 | zedqa_soak.lua | soak | PASS | 474 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 16254 at 23:32:43

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 960,13080,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_dash_green.lua (`ZEDQA dgr`) - WARN, 146 s

- go 16255 at 23:32:52
- 11 ERR line(s)
- screenshots: zqa_dgr_d6_parked_day.png, zqa_dgr_d6_parked_day_keyin.png, zqa_dgr_suv_night_on.png, zqa_dgr_suv_night_off.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA dgr d6 speedometer pivot 240,96 r1=60 a0=210 a1=330
ZEDQA dgr shot d6_parked_day design=d6 rect=1120,1804,1600,356 k=2 n8=0 lit=false tmap=false needleOwn=nil lights=false running=false kmh=0.0 mph=0.0
ZEDQA dgr shot d6_parked_day_keyin design=d6 rect=1120,1804,1600,356 k=2 n8=0 lit=false tmap=false needleOwn=nil lights=false running=false kmh=0.0 mph=0.0
ZEDQA dgr ERR fire car not settled at the seat step; not entered
ZEDQA dgr ERR fire design d6, want fire
ZEDQA dgr fire drove: max 0.0 km/h
ZEDQA dgr ERR fire never reached 64 km/h (max 0.0)
ZEDQA dgr ERR dashelite car not settled at the seat step; not entered
ZEDQA dgr ERR dashelite design d6, want dashelite
ZEDQA dgr ERR primani car not settled at the seat step; not entered
ZEDQA dgr ERR primani design d6, want primani
ZEDQA dgr shot suv_night_on design=suv rect=1120,1804,1600,356 k=2 n8=8 lit=true tmap=true needleOwn=true lights=true running=true kmh=0.0 mph=0.0
ZEDQA dgr shot suv_night_off design=suv rect=1120,1804,1600,356 k=2 n8=8 lit=false tmap=true needleOwn=true lights=false running=true kmh=0.0 mph=0.0
ZEDQA dgr ERR luxury car not settled at the seat step; not entered
ZEDQA dgr ERR luxury design suv, want luxury
ZEDQA dgr ERR cossette car not settled at the seat step; not entered
ZEDQA dgr ERR cossette design suv, want cossette
ZEDQA dgr errors 11
ZEDQA dgr DONE
```

### 3. zedqa_dash_keys_edge.lua (`ZEDQA dke`) - WARN, 313 s

- go 16256 at 23:35:21
- 17 ERR line(s)
- screenshots: zqa_dke_luxury_off.png, zqa_dke_luxury_start.png, zqa_dke_luxury_on.png, zqa_dke_suv_off.png, zqa_dke_suv_start.png, zqa_dke_suv_on.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ZEDQA dke shot luxury_off design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot luxury_start design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot luxury_on design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke ERR nyala car not settled at the seat step; not entered
ZEDQA dke ERR cossette car not settled at the seat step; not entered
ZEDQA dke ERR police car not settled at the seat step; not entered
ZEDQA dke ERR d6 car not settled at the seat step; not entered
ZEDQA dke ERR dashelite car not settled at the seat step; not entered
ZEDQA dke ERR primani car not settled at the seat step; not entered
ZEDQA dke ERR dart car not settled at the seat step; not entered
ZEDQA dke ERR horizon car not settled at the seat step; not entered
ZEDQA dke ERR wagon car not settled at the seat step; not entered
ZEDQA dke shot suv_off design=suv rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot suv_start design=suv rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot suv_on design=suv rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke ERR van car not settled at the seat step; not entered
ZEDQA dke ERR bulldriver car not settled at the seat step; not entered
ZEDQA dke ERR rancher car not settled at the seat step; not entered
ZEDQA dke ERR taxi car not settled at the seat step; not entered
ZEDQA dke ERR ambulance car not settled at the seat step; not entered
ZEDQA dke ERR fire car not settled at the seat step; not entered
ZEDQA dke ERR ranger car not settled at the seat step; not entered
ERROR: General f:52518 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:52699 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dke ERR race car not settled at the seat step; not entered
ZEDQA dke errors 17
ZEDQA dke DONE
```

### 4. zedqa_dash_brands.lua (`ZEDQA dbr`) - WARN, 277 s

- go 16257 at 23:40:38
- 17 ERR line(s)

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #4 ok=true
ZEDQA dbr ERR luxury car not settled at the seat step; not entered
ZEDQA dbr ERR nyala car not settled at the seat step; not entered
ZEDQA dbr ERR cossette car not settled at the seat step; not entered
ZEDQA dbr ERR d6 car not settled at the seat step; not entered
ZEDQA dbr ERR dashelite car not settled at the seat step; not entered
ZEDQA dbr ERR primani car not settled at the seat step; not entered
ZEDQA dbr ERR dart car not settled at the seat step; not entered
ZEDQA dbr ERR horizon car not settled at the seat step; not entered
ZEDQA dbr ERR wagon car not settled at the seat step; not entered
ZEDQA dbr ERR suv car not settled at the seat step; not entered
ZEDQA dbr ERR van car not settled at the seat step; not entered
ZEDQA dbr ERR bulldriver car not settled at the seat step; not entered
ZEDQA dbr ERR rancher car not settled at the seat step; not entered
ZEDQA dbr ERR stepvan car not settled at the seat step; not entered
ZEDQA dbr ERR modded car not settled at the seat step; not entered
ZEDQA dbr ERR dashelite_night car not settled at the seat step; not entered
ZEDQA dbr ERR cossette_night car not settled at the seat step; not entered
ZEDQA dbr errors 17
ZEDQA dbr DONE
```

### 5. zedqa_testlang.lua (`ZEDQA tlang`) - PASS, 126 s

- go 16258 at 23:45:18
- screenshots: zqa_tl_01_char_loot_list.png, zqa_tl_02_char_loot_grid.png, zqa_tl_03_card_food.png, zqa_tl_04_card_weapon.png, zqa_tl_05_card_bottle.png, zqa_tl_06_card_gun.png, zqa_tl_07_char_equip_list.png, zqa_tl_08_char_equip_doll.png, zqa_tl_09_char_health.png, zqa_tl_10_char_thermal_1.png, zqa_tl_11_char_thermal_2.png, zqa_tl_12_char_thermal_3.png, zqa_tl_13_char_thermal_4.png, zqa_tl_14_char_thermal_5.png, zqa_tl_15_char_thermal_6.png, zqa_tl_16_char_thermal_7.png, zqa_tl_17_char_thermal_figure.png, zqa_tl_18_char_identity.png, zqa_tl_19_char_journal_1.png, zqa_tl_20_char_journal_2.png, zqa_tl_21_char_journal_3.png, zqa_tl_22_char_journal_4.png, zqa_tl_23_char_skills.png, zqa_tl_24_char_radio.png, zqa_tl_25_char_loot_back.png, zqa_tl_26_ctx_strip_food.png, zqa_tl_27_ctx_strip_weapon.png, zqa_tl_28_ctx_list_food.png, zqa_tl_29_ctx_list_submenu.png, zqa_tl_30_world_loot.png, zqa_tl_31_world_craft_list.png, zqa_tl_32_world_craft_recipe.png, zqa_tl_33_world_build_list.png, zqa_tl_34_world_build_recipe.png, zqa_tl_35_world_furniture.png, zqa_tl_36_world_furniture_rotate.png, zqa_tl_37_world_furniture_scrap.png, zqa_tl_38_world_furniture_repair.png, zqa_tl_39_world_furniture_pickup.png, zqa_tl_40_world_maps.png, zqa_tl_41_world_maps_survey.png, zqa_tl_42_world_maps_color.png, zqa_tl_43_world_maps_paper.png, zqa_tl_44_world_forage.png, zqa_tl_45_world_animals.png, zqa_tl_46_belt_watch_tucked.png, zqa_tl_47_belt_watch_popped.png, zqa_tl_48_watch_corner.png, zqa_tl_49_actionbar_reading_verbose.png, zqa_tl_50_actionbar_reading_simple.png, zqa_tl_51_wheel_emotes.png, zqa_tl_52_wheel_vehicle_outside.png, zqa_tl_53_prompt_question.png, zqa_tl_54_prompt_textbox.png, zqa_tl_55_prompt_textbox_empty.png, zqa_tl_56_prompt_keyboard.png, zqa_tl_57_prompt_alarm.png, zqa_tl_58_prompt_timer.png, zqa_tl_59_prompt_help.png, zqa_tl_60_prompt_rich_question.png, zqa_tl_61_safe_note.png, zqa_tl_62_pause_menu.png, zqa_tl_63_options_1_zed.png, zqa_tl_64_options_2_display.png, zqa_tl_65_options_3_graphics.png, zqa_tl_66_options_4_audio.png, zqa_tl_67_options_5_controls.png, zqa_tl_68_options_6_gameplay.png, zqa_tl_69_options_7_interface.png, zqa_tl_70_options_8_access.png, zqa_tl_71_options_9_mods.png, zqa_tl_72_pause_mods.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tlang start (209 steps)
[ZeD.QA] run #5 ok=true
ZEDQA tlang start: safe mode on=false | test language option=1 | windows char true world true | tabs loot / loot
ZEDQA tlang test language: Close=[Ĉĺôôšéé] Search=[Šéééàààŕĉĥ...] bracketed=true
ZEDQA tlang 01 char tab loot -> zqa_tl_01_char_loot_list.png
ZEDQA tlang 02 Loot as a grid -> zqa_tl_02_char_loot_grid.png
ZEDQA tlang 03 item card on a food (apple) -> zqa_tl_03_card_food.png
ZEDQA tlang 04 item card on a weapon (baseball bat) -> zqa_tl_04_card_weapon.png
ZEDQA tlang 05 item card on a water bottle -> zqa_tl_05_card_bottle.png
ZEDQA tlang 06 item card on a pistol -> zqa_tl_06_card_gun.png
ZEDQA tlang 07 char tab equip -> zqa_tl_07_char_equip_list.png
ZEDQA tlang 08 Equip as a doll -> zqa_tl_08_char_equip_doll.png
ZEDQA tlang 09 char tab health -> zqa_tl_09_char_health.png
ZEDQA tlang 10 char tab thermal -> zqa_tl_10_char_thermal_1.png
ZEDQA tlang 11 Thermal view 2 -> zqa_tl_11_char_thermal_2.png
ZEDQA tlang 12 Thermal view 3 -> zqa_tl_12_char_thermal_3.png
ZEDQA tlang 13 Thermal view 4 -> zqa_tl_13_char_thermal_4.png
ZEDQA tlang 14 Thermal view 5 -> zqa_tl_14_char_thermal_5.png
ZEDQA tlang 15 Thermal view 6 -> zqa_tl_15_char_thermal_6.png
ZEDQA tlang 16 Thermal view 7 -> zqa_tl_16_char_thermal_7.png
ZEDQA tlang 17 Thermal figure opened -> zqa_tl_17_char_thermal_figure.png
ZEDQA tlang 18 char tab identity -> zqa_tl_18_char_identity.png
ZEDQA tlang 19 char tab journal -> zqa_tl_19_char_journal_1.png
ZEDQA tlang 20 Journal sub-tab 2 -> zqa_tl_20_char_journal_2.png
ZEDQA tlang 21 Journal sub-tab 3 -> zqa_tl_21_char_journal_3.png
ZEDQA tlang 22 Journal sub-tab 4 -> zqa_tl_22_char_journal_4.png
ZEDQA tlang 23 char tab skills -> zqa_tl_23_char_skills.png
ZEDQA tlang 24 char tab radio -> zqa_tl_24_char_radio.png
ZEDQA tlang 25 char tab loot -> zqa_tl_25_char_loot_back.png
ZEDQA tlang 26 context menu strip on a food -> zqa_tl_26_ctx_strip_food.png
ZEDQA tlang 27 context menu strip on a weapon -> zqa_tl_27_ctx_strip_weapon.png
ZEDQA tlang 28 context menu as a list on a food -> zqa_tl_28_ctx_list_food.png
ZEDQA tlang 29 context menu list, a submenu -> zqa_tl_29_ctx_list_submenu.png
ZEDQA tlang 30 world tab loot -> zqa_tl_30_world_loot.png
ZEDQA tlang 31 world tab craft -> zqa_tl_31_world_craft_list.png
ZEDQA tlang recipe open in craft: AddACigarette
ZEDQA tlang 32 Crafting with a recipe open -> zqa_tl_32_world_craft_recipe.png
ZEDQA tlang 33 world tab build -> zqa_tl_33_world_build_list.png
ZEDQA tlang recipe open in build: Advanced_Forge
ZEDQA tlang 34 Building with a recipe open -> zqa_tl_34_world_build_recipe.png
ZEDQA tlang 35 world tab furniture -> zqa_tl_35_world_furniture.png
ZEDQA tlang 36 Furniture mode rotate -> zqa_tl_36_world_furniture_rotate.png
ZEDQA tlang 37 Furniture mode scrap -> zqa_tl_37_world_furniture_scrap.png
ZEDQA tlang 38 Furniture mode repair -> zqa_tl_38_world_furniture_repair.png
ZEDQA tlang 39 Furniture mode pickup -> zqa_tl_39_world_furniture_pickup.png
ZEDQA tlang 40 world tab maps -> zqa_tl_40_world_maps.png
ZEDQA tlang 41 Maps, style survey -> zqa_tl_41_world_maps_survey.png
ZEDQA tlang 42 Maps, style color -> zqa_tl_42_world_maps_color.png
ZEDQA tlang 43 Maps, style paper -> zqa_tl_43_world_maps_paper.png
ZEDQA tlang 44 world tab forage -> zqa_tl_44_world_forage.png
ZEDQA tlang 45 world tab animals -> zqa_tl_45_world_animals.png
ZEDQA tlang MISSING World tab radio (not reachable here)
ZEDQA tlang MISSING World tab vehicle (not reachable here)
ZEDQA tlang 46 the belt with the mini watch, hammer and walkie-talkie in hand -> zqa_tl_46_belt_watch_tucked.png
ZEDQA tlang 47 the popped watch -> zqa_tl_47_belt_watch_popped.png
ZEDQA tlang 48 the watch in the corner (Corner mode) -> zqa_tl_48_watch_corner.png
ZEDQA tlang 49 action bar while reading (Verbose) -> zqa_tl_49_actionbar_reading_verbose.png
ZEDQA tlang 50 action bar while reading (Simple) -> zqa_tl_50_actionbar_reading_simple.png
ZEDQA tlang 51 the emote wheel -> zqa_tl_51_wheel_emotes.png
ZEDQA tlang 52 the vehicle wheel outside a vehicle -> zqa_tl_52_wheel_vehicle_outside.png
ZEDQA tlang 53 prompt: a question (sleep) -> zqa_tl_53_prompt_question.png
ZEDQA tlang 54 prompt: a text box (rename) -> zqa_tl_54_prompt_textbox.png
ZEDQA tlang 55 prompt: text box emptied (reason shown) -> zqa_tl_55_prompt_textbox_empty.png
ZEDQA tlang 56 on-screen keyboard over the text box -> zqa_tl_56_prompt_keyboard.png
ZEDQA tlang 57 prompt: the alarm clock -> zqa_tl_57_prompt_alarm.png
ZEDQA tlang 58 prompt: the trap timer -> zqa_tl_58_prompt_timer.png
ZEDQA tlang 59 prompt: a long help note -> zqa_tl_59_prompt_help.png
ZEDQA tlang 60 prompt: a rich question (forget map) -> zqa_tl_60_prompt_rich_question.png
ZEDQA tlang safe mode free before the trip: on=false
ZEDQA tlang tripped: note true | pair open char false world false
ZEDQA tlang 61 safe mode: the game's own note after a trip -> zqa_tl_61_safe_note.png
ZEDQA tlang safe mode free after the trip: on=false
ZEDQA tlang pause menu up: true | ZeD pause window true
ZEDQA tlang 62 the pause menu -> zqa_tl_62_pause_menu.png
ZEDQA tlang options up: true | groups 9
ZEDQA tlang 63 Options, group zed -> zqa_tl_63_options_1_zed.png
ZEDQA tlang 64 Options, group display -> zqa_tl_64_options_2_display.png
ZEDQA tlang 65 Options, group graphics -> zqa_tl_65_options_3_graphics.png
ZEDQA tlang 66 Options, group audio -> zqa_tl_66_options_4_audio.png
ZEDQA tlang 67 Options, group controls -> zqa_tl_67_options_5_controls.png
ZEDQA tlang 68 Options, group gameplay -> zqa_tl_68_options_6_gameplay.png
ZEDQA tlang 69 Options, group interface -> zqa_tl_69_options_7_interface.png
ZEDQA tlang 70 Options, group access -> zqa_tl_70_options_8_access.png
ZEDQA tlang 71 Options, group mods -> zqa_tl_71_options_9_mods.png
ZEDQA tlang 72 the pause menu, Mods page -> zqa_tl_72_pause_mods.png
ZEDQA tlang resumed: pause menu visible=false speed 1
ZEDQA tlang test language back: Close=Close
ZEDQA tlang safe mode free at the end: on=false | test language option=1 | windows char true world true | 72 screenshots
ZEDQA tlang DONE
```

### 6. zedqa_safemode.lua (`ZEDQA safe`) - PASS, 12 s

- go 16259 at 23:47:27
- screenshots: zqa_safe_1.png, zqa_safe_2.png, zqa_safe_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA safe start
[ZeD.QA] run #6 ok=true
ZEDQA safe baseline: on false | pair true/true | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok baseline
ZEDQA safe tripped: on true | pair false/false | vanilla inv true | hotbar vanilla | clock y 10 visible false | speed y 10 | moodle layer false | note true
ZEDQA safe ok tripped
ZEDQA safe ok the note shows and closes
ZEDQA safe inventory key (23): vanilla page true -> false -> true | pair false/false
ZEDQA safe ok inventory key goes to vanilla
ZEDQA safe before reset: vanilla inv true
ZEDQA safe reset: on false | pair false/false | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok reset
ZEDQA safe ok reset hides vanilla's page again
ZEDQA safe reopened: pair true/true | vanilla inv false
ZEDQA safe ok reopened
ZEDQA safe option On picked up by the poll: picked up after 279 ms
ZEDQA safe ok option On picked up by the poll
ZEDQA safe option on: on true | pair false/false | vanilla inv true | hotbar vanilla | clock y 10 visible false | speed y 10 | moodle layer false
ZEDQA safe ok option on
ZEDQA safe option Off picked up by the poll: picked up after 469 ms
ZEDQA safe ok option Off picked up by the poll
ZEDQA safe option off: on false | pair false/false | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok option off
ZEDQA safe burst: 5 ticks, still off after 2500 ms
ZEDQA safe ok watchdog: a five-frame burst leaves ZeD on
ZEDQA safe streak: tripped after 2011 ms, 240 frames, longest gap 33 ms
ZEDQA safe ok watchdog: below two seconds of failures ZeD stays on
ZEDQA safe ok watchdog: two seconds of failures every frame trip it
ZEDQA safe ok watchdog note shows and closes
ZEDQA safe restored: on false | pair true/true | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok restored
ZEDQA safe DONE
```

### 7. zedqa_soak.lua (`ZEDQA soak`) - PASS, 474 s

- go 16260 at 23:47:42

```text
[ZeD.QA] windows reset (R)
ZEDQA soak start ui 38
[ZeD.QA] run #7 ok=true
ZEDQA soak round 1 avg 9.73 ms worst 94 ms ui 39 (start 38) hours 0.2
ZEDQA soak round 2 avg 9.64 ms worst 47 ms ui 39 (start 38) hours 0.4
ZEDQA soak round 3 avg 9.63 ms worst 40 ms ui 39 (start 38) hours 0.5
ZEDQA soak round 4 avg 9.65 ms worst 39 ms ui 39 (start 38) hours 0.7
ZEDQA soak round 5 avg 9.56 ms worst 42 ms ui 39 (start 38) hours 0.9
ZEDQA soak round 6 avg 9.67 ms worst 39 ms ui 39 (start 38) hours 1.0
ZEDQA soak round 7 avg 9.57 ms worst 37 ms ui 39 (start 38) hours 1.2
ZEDQA soak round 8 avg 9.65 ms worst 41 ms ui 39 (start 38) hours 1.4
ZEDQA soak round 9 avg 9.58 ms worst 54 ms ui 39 (start 38) hours 1.6
ZEDQA soak round 10 avg 9.65 ms worst 41 ms ui 39 (start 38) hours 1.7
ZEDQA soak round 11 avg 9.68 ms worst 42 ms ui 39 (start 38) hours 1.9
ZEDQA soak round 12 avg 9.63 ms worst 45 ms ui 39 (start 38) hours 2.1
ZEDQA soak DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
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
