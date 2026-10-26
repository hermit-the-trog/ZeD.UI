# ZeD-UI regression - 2026-10-25 19:58 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-25 19:58:23 |
| Finished | 2026-10-25 20:11:35 (13 min 11 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/AppData/Local/Temp/claude/C--Users-danie-Zomboid/989d1212-0f15-49ba-a371-9ee134c38e7f/scratchpad/batch_a_tail.txt (12 scripts) |
| Result | **12/12 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 13215 to 13228 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13227, 13228)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_loot_tabs.lua | lt | PASS | 1 |  |  |
| 3 | zedqa_appliances.lua | ap | PASS | 23 | zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png |  |
| 4 | zedqa_tour3.lua | t3 | PASS | 17 | zedqa_t3_SmallCar02.png, zedqa_t3_ModernCar.png, zedqa_t3_ModernCar02.png, zedqa_t3_SUV.png, zedqa_t3_Van.png, zedqa_t3_PickUpVan.png, zedqa_t3_OffRoad.png |  |
| 5 | zedqa_dash19.lua | dash | PASS | 95 | zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png |  |
| 6 | zedqa_dashpx.lua | dpx | PASS | 151 | zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_07_primani_keyon.png, zqa_dashpx_07_primani.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png, zqa_dashpx_14_rancher.png, zqa_dashpx_15_taxi_keyon.png, zqa_dashpx_15_taxi.png, zqa_dashpx_16_ambulance_keyon.png, zqa_dashpx_16_ambulance.png, zqa_dashpx_17_fire_keyon.png, zqa_dashpx_17_fire.png, zqa_dashpx_18_ranger_keyon.png, zqa_dashpx_18_ranger.png, zqa_dashpx_19_race_keyon.png, zqa_dashpx_19_race.png, zqa_dashpx_20_knoxvan_keyon.png, zqa_dashpx_20_knoxvan.png, zqa_dashpx_21_fossoild6_keyon.png, zqa_dashpx_21_fossoild6.png, zqa_dashpx_23_meadesheriff_keyon.png, zqa_dashpx_23_meadesheriff.png, zqa_dashpx_24_lcpd_keyon.png, zqa_dashpx_24_lcpd.png |  |
| 7 | zedqa_exinfo.lua | ex | PASS | 7 | zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png |  |
| 8 | zedqa_equipdrag.lua | eqd | PASS | 13 | zqa_eqd_1.png, zqa_eqd_2.png, zqa_eqd_3.png, zqa_eqd_4.png |  |
| 9 | zedqa_cazio_light.lua | czl | PASS | 37 | zqa_cl_day_DigitalBlack.png, zqa_cl_daylit_DigitalBlack.png, zqa_cl_night_DigitalBlack.png, zqa_cl_nightlit_DigitalBlack.png, zqa_cl_day_DigitalDress.png, zqa_cl_daylit_DigitalDress.png, zqa_cl_night_DigitalDress.png, zqa_cl_nightlit_DigitalDress.png, zqa_cl_day_ClassicBlack.png, zqa_cl_daylit_ClassicBlack.png, zqa_cl_night_ClassicBlack.png, zqa_cl_nightlit_ClassicBlack.png, zqa_cl_day_ClassicGold.png, zqa_cl_daylit_ClassicGold.png, zqa_cl_night_ClassicGold.png, zqa_cl_nightlit_ClassicGold.png, zqa_cl_belt_night.png, zqa_cl_belt_nightlit.png, zqa_cl_belt_day.png, zqa_cl_belt_daylit.png |  |
| 10 | zedqa_dashnight.lua | dnt | PASS | 107 | zqa_dashnight_wagon_real.png, zqa_dashnight_wagon_day.png, zqa_dashnight_wagon_dusk.png, zqa_dashnight_wagon_night.png, zqa_dashnight_wagon_nightoff.png, zqa_dashnight_wagon_real_noon.png, zqa_dashnight_wagon_real_back_on.png, zqa_dashnight_wagon_real_back_off.png, zqa_dashnight_nyala_real.png, zqa_dashnight_nyala_day.png, zqa_dashnight_nyala_dusk.png, zqa_dashnight_nyala_night.png, zqa_dashnight_nyala_nightoff.png, zqa_dashnight_dashelite_real.png, zqa_dashnight_dashelite_day.png, zqa_dashnight_dashelite_dusk.png, zqa_dashnight_dashelite_night.png, zqa_dashnight_dashelite_nightoff.png, zqa_dashnight_luxury_real.png, zqa_dashnight_luxury_day.png, zqa_dashnight_luxury_dusk.png, zqa_dashnight_luxury_night.png, zqa_dashnight_luxury_nightoff.png, zqa_dashnight_ambulance_real.png, zqa_dashnight_ambulance_day.png, zqa_dashnight_ambulance_dusk.png, zqa_dashnight_ambulance_night.png, zqa_dashnight_ambulance_nightoff.png, zqa_dashnight_race_real.png, zqa_dashnight_race_day.png, zqa_dashnight_race_dusk.png, zqa_dashnight_race_night.png, zqa_dashnight_race_nightoff.png, zqa_dashnight_d6_real.png, zqa_dashnight_d6_day.png, zqa_dashnight_d6_dusk.png, zqa_dashnight_d6_night.png, zqa_dashnight_d6_nightoff.png |  |
| 11 | zedqa_testlang.lua | tlang | PASS | 130 | zqa_tl_01_char_loot_list.png, zqa_tl_02_char_loot_grid.png, zqa_tl_03_card_food.png, zqa_tl_04_card_weapon.png, zqa_tl_05_card_bottle.png, zqa_tl_06_card_gun.png, zqa_tl_07_char_equip_list.png, zqa_tl_08_char_equip_doll.png, zqa_tl_09_char_health.png, zqa_tl_10_char_thermal_1.png, zqa_tl_11_char_thermal_2.png, zqa_tl_12_char_thermal_3.png, zqa_tl_13_char_thermal_4.png, zqa_tl_14_char_thermal_5.png, zqa_tl_15_char_thermal_6.png, zqa_tl_16_char_thermal_7.png, zqa_tl_17_char_thermal_figure.png, zqa_tl_18_char_identity.png, zqa_tl_19_char_journal_1.png, zqa_tl_20_char_journal_2.png, zqa_tl_21_char_journal_3.png, zqa_tl_22_char_journal_4.png, zqa_tl_23_char_skills.png, zqa_tl_24_char_radio.png, zqa_tl_25_char_loot_back.png, zqa_tl_26_ctx_strip_food.png, zqa_tl_27_ctx_strip_weapon.png, zqa_tl_28_ctx_list_food.png, zqa_tl_29_ctx_list_submenu.png, zqa_tl_30_world_loot.png, zqa_tl_31_world_craft_list.png, zqa_tl_32_world_craft_recipe.png, zqa_tl_33_world_build_list.png, zqa_tl_34_world_build_recipe.png, zqa_tl_35_world_furniture.png, zqa_tl_36_world_furniture_rotate.png, zqa_tl_37_world_furniture_scrap.png, zqa_tl_38_world_furniture_repair.png, zqa_tl_39_world_furniture_pickup.png, zqa_tl_40_world_maps.png, zqa_tl_41_world_maps_survey.png, zqa_tl_42_world_maps_color.png, zqa_tl_43_world_maps_paper.png, zqa_tl_44_world_forage.png, zqa_tl_45_world_animals.png, zqa_tl_46_belt_watch_tucked.png, zqa_tl_47_belt_watch_popped.png, zqa_tl_48_watch_corner.png, zqa_tl_49_actionbar_reading_verbose.png, zqa_tl_50_actionbar_reading_simple.png, zqa_tl_51_wheel_emotes.png, zqa_tl_52_wheel_vehicle_outside.png, zqa_tl_53_prompt_question.png, zqa_tl_54_prompt_textbox.png, zqa_tl_55_prompt_textbox_empty.png, zqa_tl_56_prompt_keyboard.png, zqa_tl_57_prompt_alarm.png, zqa_tl_58_prompt_timer.png, zqa_tl_59_prompt_help.png, zqa_tl_60_prompt_rich_question.png, zqa_tl_61_safe_note.png, zqa_tl_62_pause_menu.png, zqa_tl_63_options_1_zed.png, zqa_tl_64_options_2_display.png, zqa_tl_65_options_3_graphics.png, zqa_tl_66_options_4_audio.png, zqa_tl_67_options_5_controls.png, zqa_tl_68_options_6_gameplay.png, zqa_tl_69_options_7_interface.png, zqa_tl_70_options_8_access.png, zqa_tl_71_options_9_mods.png, zqa_tl_72_pause_mods.png |  |
| 12 | zedqa_safemode.lua | safe | PASS | 13 | zqa_safe_1.png, zqa_safe_2.png, zqa_safe_3.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13215 at 20:00:23

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_loot_tabs.lua (`ZEDQA lt`) - PASS, 1 s

- go 13216 at 20:00:28

```text
[ZeD.QA] windows reset (R)
ZEDQA lt start
[ZeD.QA] run #2 ok=true
ZEDQA lt Character loot drawer false | World loot drawer false
ZEDQA lt DONE
```

### 3. zedqa_appliances.lua (`ZEDQA ap`) - PASS, 23 s

- go 13217 at 20:00:33
- screenshots: zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ap start
[ZeD.QA] run #3 ok=true
ZEDQA ap no room in reach of 11479,11497: to the Fossoil at West Point
ZEDQA ap indoors at 12059,7122
ZEDQA ap placed: stove true, microwave true
ZEDQA ap PASS the stove opens in the Craft tab
ZEDQA ap stove powered true (grid power on the square true, object index 1, world power true)
ZEDQA ap PASS stove: the station is the one opened
ZEDQA ap PASS stove: the World window is on its Craft tab
ZEDQA ap stove: plate oven_modern 456x128, tab 941 px, want 941, zoom in the tab 2 (the screen's 2)
ZEDQA ap PASS stove: the plate draws at the screen's whole zoom in the tab
ZEDQA ap PASS stove: the tab has the pop-out button
ZEDQA ap PASS the pop-out window is up
ZEDQA ap pop-out 1208,782 1424x594, zoom 3 (the screen's 2)
ZEDQA ap PASS the pop-out is centred on the screen
ZEDQA ap PASS the pop-out's plate is at least the tab's size
ZEDQA ap PASS the pop-out is on screen
ZEDQA ap PASS the pop-out has the plate's controls (15)
ZEDQA ap PASS the tab says it is in its own window and offers it back
ZEDQA ap pressed broil
ZEDQA ap stove heat 200 -> 300
ZEDQA ap PASS a control pressed in the pop-out moves the stove's own setting
ZEDQA ap PASS Bring it back closes the window
ZEDQA ap PASS the plate is back in the tab
ZEDQA ap PASS the microwave opens in the Craft tab
ZEDQA ap PASS microwave: the station is the one opened
ZEDQA ap PASS microwave: the World window is on its Craft tab
ZEDQA ap microwave: plate mw_white 456x168, tab 941 px, want 941, zoom in the tab 2 (the screen's 2)
ZEDQA ap PASS microwave: the plate draws at the screen's whole zoom in the tab
ZEDQA ap PASS microwave: the tab has the pop-out button
ZEDQA ap PASS the microwave pops out too
ZEDQA ap cleanup: 2 appliances removed, station released
ZEDQA ap back at 11479,11497
ZEDQA ap all checks passed
ZEDQA ap DONE
```

### 4. zedqa_tour3.lua (`ZEDQA t3`) - PASS, 17 s

- go 13218 at 20:01:01
- screenshots: zedqa_t3_SmallCar02.png, zedqa_t3_ModernCar.png, zedqa_t3_ModernCar02.png, zedqa_t3_SUV.png, zedqa_t3_Van.png, zedqa_t3_PickUpVan.png, zedqa_t3_OffRoad.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #4 ok=true
ZEDQA t3 SmallCar02 design=horizon visible=true hits=21 badge=nil/nil cluster=nil
ZEDQA t3 ModernCar design=dashelite visible=true hits=29 badge=nil/nil cluster=nil
ZEDQA t3 ModernCar02 design=primani visible=true hits=26 badge=nil/nil cluster=nil
ZEDQA t3 SUV design=suv visible=true hits=22 badge=nil/nil cluster=nil
ZEDQA t3 Van design=van visible=true hits=25 badge=nil/nil cluster=nil
ZEDQA t3 PickUpVan design=bulldriver visible=true hits=22 badge=nil/nil cluster=nil
ZEDQA t3 OffRoad design=rancher visible=true hits=21 badge=nil/nil cluster=nil
ZEDQA t3 done
```

### 5. zedqa_dash19.lua (`ZEDQA dash`) - PASS, 95 s

- go 13219 at 20:01:22
- screenshots: zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #5 ok=true
ZEDQA dash 01_luxury design=luxury rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 02_nyala design=nyala rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 03_cossette design=cossette rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 04_police design=police rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 05_d6 design=d6 rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 06_dashelite design=dashelite rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 07_primani design=primani rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 08_dart design=dart rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 09_horizon design=horizon rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 10_wagon design=wagon rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 11_suv design=suv rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 12_van design=van rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 13_bulldriver design=bulldriver rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 14_rancher design=rancher rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 15_taxi design=taxi rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 16_ambulance design=ambulance rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 17_fire design=fire rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 18_ranger design=ranger rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ERROR: General f:10343 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"   (x2)
ZEDQA dash 19_race design=race rect=1120,1804,1600,344 running=true radio=false heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash DONE
```

### 6. zedqa_dashpx.lua (`ZEDQA dpx`) - PASS, 151 s

- go 13220 at 20:03:01
- screenshots: zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_07_primani_keyon.png, zqa_dashpx_07_primani.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png, zqa_dashpx_14_rancher.png, zqa_dashpx_15_taxi_keyon.png, zqa_dashpx_15_taxi.png, zqa_dashpx_16_ambulance_keyon.png, zqa_dashpx_16_ambulance.png, zqa_dashpx_17_fire_keyon.png, zqa_dashpx_17_fire.png, zqa_dashpx_18_ranger_keyon.png, zqa_dashpx_18_ranger.png, zqa_dashpx_19_race_keyon.png, zqa_dashpx_19_race.png, zqa_dashpx_20_knoxvan_keyon.png, zqa_dashpx_20_knoxvan.png, zqa_dashpx_21_fossoild6_keyon.png, zqa_dashpx_21_fossoild6.png, zqa_dashpx_23_meadesheriff_keyon.png, zqa_dashpx_23_meadesheriff.png, zqa_dashpx_24_lcpd_keyon.png, zqa_dashpx_24_lcpd.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #6 ok=true
ZEDQA dpx 01_luxury design=luxury rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=MERCIA LANG 4000 livery= make=MERCIA model=LANG 4000 unit=MERCIA - UNIT 84 hits=27 screen=3840x2160
ZEDQA dpx 02_nyala design=nyala rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER NYALA livery= make=CHEVALIER model=NYALA unit=CHEVALIER - UNIT 84 hits=22 screen=3840x2160
ZEDQA dpx 03_cossette design=cossette rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER COSSETTE livery= make=CHEVALIER model=COSSETTE unit=CHEVALIER - UNIT 84 hits=22 screen=3840x2160
ZEDQA dpx 04_police design=police rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=STATE TROOPER CHEVALIER NYALA livery=STATE TROOPER make=CHEVALIER model=NYALA unit=TROOPER - UNIT 84 hits=19 screen=3840x2160
ZEDQA dpx 05_d6 design=d6 rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER D6 livery= make=CHEVALIER model=D6 unit=CHEVALIER - UNIT 84 hits=22 screen=3840x2160
ZEDQA dpx 06_dashelite design=dashelite rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=DASH ELITE livery= make=DASH model=ELITE unit=DASH - UNIT 84 hits=29 screen=3840x2160
ZEDQA dpx 07_primani design=primani rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=CHEVALIER PRIMANI livery= make=CHEVALIER model=PRIMANI unit=CHEVALIER - UNIT 84 hits=26 screen=3840x2160
ZEDQA dpx 08_dart design=dart rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER DART livery= make=CHEVALIER model=DART unit=CHEVALIER - UNIT 84 hits=21 screen=3840x2160
ZEDQA dpx 09_horizon design=horizon rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=MASTERSON HORIZON livery= make=MASTERSON model=HORIZON unit=MASTERSON - UNIT 84 hits=21 screen=3840x2160
ZEDQA dpx 10_wagon design=wagon rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=CHEVALIER CERISE WAGON livery= make=CHEVALIER model=CERISE WAGON unit=CHEVALIER - UNIT 84 hits=26 screen=3840x2160
ZEDQA dpx 11_suv design=suv rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=FRANKLIN ALL-TERRAIN livery= make=FRANKLIN model=ALL-TERRAIN unit=FRANKLIN - UNIT 84 hits=22 screen=3840x2160
ZEDQA dpx 12_van design=van rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=SPIFFO VAN livery=SPIFFO VAN make=FRANKLIN model=VALULINE unit=SPIFFO - UNIT 84 hits=21 screen=3840x2160
ZEDQA dpx 13_bulldriver design=bulldriver rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=DASH BULLDRIVER livery= make=DASH model=BULLDRIVER unit=DASH - UNIT 84 hits=22 screen=3840x2160
ZEDQA dpx 14_rancher design=rancher rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=DASH RANCHER livery= make=DASH model=RANCHER unit=DASH - UNIT 84 hits=21 screen=3840x2160
ZEDQA dpx 15_taxi design=taxi rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=TAXI livery=TAXI make=CHEVALIER model=NYALA unit=TAXI - CAB 84 hits=22 screen=3840x2160
ZEDQA dpx 16_ambulance design=ambulance rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=AMBULANCE livery=AMBULANCE make=FRANKLIN model=VALULINE unit=AMBULANCE - UNIT 84 hits=19 screen=3840x2160
ZEDQA dpx 17_fire design=fire rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=FIRE DEPARTMENT CHEVALIER D6 livery=FIRE DEPARTMENT make=CHEVALIER model=D6 unit=FIRE - ENGINE 84 hits=19 screen=3840x2160
ZEDQA dpx 18_ranger design=ranger rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=RANGER CHEVALIER NYALA livery=RANGER make=CHEVALIER model=NYALA unit=RANGER - UNIT 84 hits=19 screen=3840x2160
ERROR: General f:18083 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"   (x2)
ZEDQA dpx 19_race design=race rect=1120,1804,1600,344 k=2 running=true radio=false/nil heat=true lights=true name=RACE CAR livery=RACE CAR make=RACE model=CAR unit=RACE - UNIT 84 hits=5 screen=3840x2160
ZEDQA dpx 20_knoxvan design=van rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=KNOX DISTILLERY FRANKLIN VALULINE livery=KNOX DISTILLERY make=FRANKLIN model=VALULINE unit=KNOX - UNIT 84 hits=21 screen=3840x2160
ZEDQA dpx 21_fossoild6 design=d6 rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=CHEVALIER D6 livery= make=CHEVALIER model=D6 unit=CHEVALIER - UNIT 84 hits=19 screen=3840x2160
ZEDQA dpx 22_wreckednyala could not enter Base.CarNormalSmashedFront (enter=false seat0 installed=false)
ZEDQA dpx 23_meadesheriff design=police rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=MEADE SHERIFF DASH ELITE livery=MEADE SHERIFF make=DASH model=ELITE unit=SHERIFF - UNIT 84 hits=19 screen=3840x2160
ZEDQA dpx 24_lcpd design=police rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=LCPD CHEVALIER NYALA livery=LCPD make=CHEVALIER model=NYALA unit=LCPD - UNIT 84 hits=19 screen=3840x2160
ZEDQA dpx DONE
```

### 7. zedqa_exinfo.lua (`ZEDQA ex`) - PASS, 7 s

- go 13221 at 20:05:36
- screenshots: zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ex start
[ZeD.QA] run #7 ok=true
ZEDQA ex ok squats desc is vanilla's tooltip
ZEDQA ex ok squats legs line
ZEDQA ex ok pushups: arms line only (chest has none)
ZEDQA ex ok burpees: legs and arms
ZEDQA ex ok situp abs line
ZEDQA ex ok regularity in 0..1
ZEDQA ex regularity squats 0
ZEDQA ex ok barbell curl without a barbell warns '(Requires Barbell)'
ZEDQA ex ok squats has no item warning
ZEDQA ex ok with a barbell the warning clears
ZEDQA ex ok unknown exercise gives nil
ZEDQA ex ok sitonground shows Stand up before exercising
ZEDQA ex ok reason gone after standing
ZEDQA ex tab health true | shown squats | reserved 450.86328125 used 282.48828125 w 329
ZEDQA ex ok block follows the focused pill (squats)
ZEDQA ex ok room reserved
ZEDQA ex ok block follows the focused pill (barbell curl)
ZEDQA ex ok same reserved height for another exercise
ZEDQA ex ok time buttons keep the last started exercise
ZEDQA ex ok time buttons start nothing and change no choice
ZEDQA ex ok block follows the focused pill (burpees)
ZEDQA ex DONE
```

### 8. zedqa_equipdrag.lua (`ZEDQA eqd`) - PASS, 13 s

- go 13222 at 20:05:47
- screenshots: zqa_eqd_1.png, zqa_eqd_2.png, zqa_eqd_3.png, zqa_eqd_4.png

```text
[ZeD.QA] windows reset (R)
ZEDQA eqd start
[ZeD.QA] run #8 ok=true
ZEDQA eqd list slots {HAT,OUT,INR,GLV,PNT,SOC,BOT,PRI,BLT}
ZEDQA eqd worn {base:beltextra=HolsterSimple,base:belt=Belt2,base:hat=Hat_BaseballCapBlue,base:tanktop=Vest_DefaultTEXTURE_TINT,base:tshirt=Tshirt_DefaultTEXTURE,base:hands=Gloves_LeatherGloves,base:socks=Socks_Ankle,base:shoes=Shoes_ArmyBoots,base:pants=Trousers_Denim,base:jacket=Jacket_Varsity} cap Clothing{ clothingItemName="Hat_BaseballCapBlue" } jacket Clothing{ clothingItemName="Jacket_Varsity" } pri Base.Hammer:zombie.inventory.types.HandWeapon@6f35a102 | tab equip listExp true view list
ZEDQA eqd PASS rows for cap, jacket, hammer
ZEDQA eqd PASS press waits (pending, nothing selected yet)
ZEDQA eqd PASS click selects the row | HAT
ZEDQA eqd PASS moved press is the drag
ZEDQA eqd PASS ISMouseDrag carries the item
ZEDQA eqd PASS draggedItem names it
ZEDQA eqd PASS release on the Equip tab: drag over, nothing queued, cap still worn | queue 0
ZEDQA eqd PASS drag started on the jacket
ZEDQA eqd PASS right press cancels it
ZEDQA eqd doll slots {doll:head,doll:torso,doll:outer,doll:hands,doll:belt,doll:legs,doll:feet,doll:main}
ZEDQA eqd PASS doll slots for the cap and the hammer
ZEDQA eqd PASS doll click selects the slot | doll:head
ZEDQA eqd PASS doll slot drags
ZEDQA eqd PASS doll drag cancelled
ZEDQA eqd PASS cap release queued vanilla's transfer | queue 1
ZEDQA eqd PASS cap in the bag and off the head
ZEDQA eqd PASS hammer release queued | queue 1
ZEDQA eqd PASS hammer in the bag and out of the hand
ZEDQA eqd PASS jacket onto its own container does nothing | queue 0
ZEDQA eqd PASS floor release queued vanilla's drop | queue 2
ZEDQA eqd PASS jacket on the floor and off the body
ZEDQA eqd PASS jacket picked back up
ZEDQA eqd DONE
```

### 9. zedqa_cazio_light.lua (`ZEDQA czl`) - PASS, 37 s

- go 13223 at 20:06:05
- screenshots: zqa_cl_day_DigitalBlack.png, zqa_cl_daylit_DigitalBlack.png, zqa_cl_night_DigitalBlack.png, zqa_cl_nightlit_DigitalBlack.png, zqa_cl_day_DigitalDress.png, zqa_cl_daylit_DigitalDress.png, zqa_cl_night_DigitalDress.png, zqa_cl_nightlit_DigitalDress.png, zqa_cl_day_ClassicBlack.png, zqa_cl_daylit_ClassicBlack.png, zqa_cl_night_ClassicBlack.png, zqa_cl_nightlit_ClassicBlack.png, zqa_cl_day_ClassicGold.png, zqa_cl_daylit_ClassicGold.png, zqa_cl_night_ClassicGold.png, zqa_cl_nightlit_ClassicGold.png, zqa_cl_belt_night.png, zqa_cl_belt_nightlit.png, zqa_cl_belt_day.png, zqa_cl_belt_daylit.png

```text
[ZeD.QA] windows reset (R)
ZEDQA czl start
[ZeD.QA] run #9 ok=true
ZEDQA czl own watch nil at base:leftwrist
ZEDQA czl DigitalBlack plate digital_black light at 0,76 lit=false bulb=false dark=false
ZEDQA czl DigitalBlack day pressed: lit=false bulb=true dark=false
ZEDQA czl DigitalBlack night: lit=false bulb=false dark=true
ZEDQA czl DigitalBlack night pressed: lit=false bulb=true dark=true
ZEDQA czl DigitalDress plate digital_gold light at 0,76 lit=false bulb=false dark=false
ZEDQA czl DigitalDress day pressed: lit=false bulb=true dark=false
ZEDQA czl DigitalDress night: lit=false bulb=false dark=true
ZEDQA czl DigitalDress night pressed: lit=false bulb=true dark=true
ZEDQA czl ClassicBlack plate classic_black light at 24,160 lit=false bulb=false dark=false
ZEDQA czl ClassicBlack day pressed: lit=false bulb=true dark=false
ZEDQA czl ClassicBlack night: lit=false bulb=false dark=true
ZEDQA czl ClassicBlack night pressed: lit=false bulb=true dark=true
ZEDQA czl ClassicGold plate classic_gold light at 24,160 lit=false bulb=false dark=false
ZEDQA czl ClassicGold day pressed: lit=false bulb=true dark=false
ZEDQA czl ClassicGold night: lit=false bulb=false dark=true
ZEDQA czl ClassicGold night pressed: lit=false bulb=true dark=true
ZEDQA czl timer pressed at 1792983991605
ZEDQA czl light out after 3013 ms; lit=false bulb=false dark=true
ZEDQA czl Expensive light control false
ZEDQA czl Expensive after a stray light press: lit=false bulb=false dark=true
ZEDQA czl belt watch box 1
ZEDQA czl belt mini after Y: lit=true night=true dark=false
ZEDQA czl restored own watch nil
ZEDQA czl DONE
```

### 10. zedqa_dashnight.lua (`ZEDQA dnt`) - PASS, 107 s

- go 13224 at 20:06:45
- screenshots: zqa_dashnight_wagon_real.png, zqa_dashnight_wagon_day.png, zqa_dashnight_wagon_dusk.png, zqa_dashnight_wagon_night.png, zqa_dashnight_wagon_nightoff.png, zqa_dashnight_wagon_real_noon.png, zqa_dashnight_wagon_real_back_on.png, zqa_dashnight_wagon_real_back_off.png, zqa_dashnight_nyala_real.png, zqa_dashnight_nyala_day.png, zqa_dashnight_nyala_dusk.png, zqa_dashnight_nyala_night.png, zqa_dashnight_nyala_nightoff.png, zqa_dashnight_dashelite_real.png, zqa_dashnight_dashelite_day.png, zqa_dashnight_dashelite_dusk.png, zqa_dashnight_dashelite_night.png, zqa_dashnight_dashelite_nightoff.png, zqa_dashnight_luxury_real.png, zqa_dashnight_luxury_day.png, zqa_dashnight_luxury_dusk.png, zqa_dashnight_luxury_night.png, zqa_dashnight_luxury_nightoff.png, zqa_dashnight_ambulance_real.png, zqa_dashnight_ambulance_day.png, zqa_dashnight_ambulance_dusk.png, zqa_dashnight_ambulance_night.png, zqa_dashnight_ambulance_nightoff.png, zqa_dashnight_race_real.png, zqa_dashnight_race_day.png, zqa_dashnight_race_dusk.png, zqa_dashnight_race_night.png, zqa_dashnight_race_nightoff.png, zqa_dashnight_d6_real.png, zqa_dashnight_d6_day.png, zqa_dashnight_d6_dusk.png, zqa_dashnight_d6_night.png, zqa_dashnight_d6_nightoff.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #10 ok=true
ZEDQA dnt wagon real design=wagon lux=1.000 smooth=1.000 n8=0 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=12.27
ZEDQA dnt wagon day design=wagon lux=1.000 smooth=1.000 n8=0 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=12.27
ZEDQA dnt wagon dusk design=wagon lux=1.000 smooth=1.000 n8=4 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=12.28
ZEDQA dnt wagon night design=wagon lux=1.000 smooth=1.000 n8=8 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=12.28
ZEDQA dnt wagon nightoff design=wagon lux=1.000 smooth=1.000 n8=8 lit=false over=dash_wagon_dark lights=true dashLit=true k=2 hour=12.28
ZEDQA dnt wagon real_noon design=wagon lux=1.000 smooth=1.000 n8=0 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=13.02
ZEDQA dnt wagon real_back_on design=wagon lux=1.000 smooth=1.000 n8=0 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=12.28
ZEDQA dnt wagon real_back_off design=wagon lux=1.000 smooth=1.000 n8=0 lit=false over=dash_wagon_dark lights=false dashLit=false k=2 hour=12.28
ZEDQA dnt nyala real design=nyala lux=0.667 smooth=0.680 n8=0 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=12.30
ZEDQA dnt nyala day design=nyala lux=0.667 smooth=0.674 n8=0 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=12.30
ZEDQA dnt nyala dusk design=nyala lux=0.667 smooth=0.671 n8=4 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=12.31
ZEDQA dnt nyala night design=nyala lux=0.667 smooth=0.669 n8=8 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=12.31
ZEDQA dnt nyala nightoff design=nyala lux=0.667 smooth=0.668 n8=8 lit=false over=dash_nyala_dark lights=true dashLit=true k=2 hour=12.31
ZEDQA dnt dashelite real design=dashelite lux=1.000 smooth=0.958 n8=0 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=12.33
ZEDQA dnt dashelite day design=dashelite lux=1.000 smooth=0.977 n8=0 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=12.33
ZEDQA dnt dashelite dusk design=dashelite lux=1.000 smooth=0.988 n8=4 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=12.34
ZEDQA dnt dashelite night design=dashelite lux=1.000 smooth=0.993 n8=8 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=12.34
ZEDQA dnt dashelite nightoff design=dashelite lux=1.000 smooth=0.997 n8=8 lit=false over=dash_dashelite_dark lights=true dashLit=true k=2 hour=12.34
ZEDQA dnt luxury real design=luxury lux=1.000 smooth=1.000 n8=0 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=12.36
ZEDQA dnt luxury day design=luxury lux=1.000 smooth=1.000 n8=0 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=12.36
ZEDQA dnt luxury dusk design=luxury lux=1.000 smooth=1.000 n8=4 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=12.36
ZEDQA dnt luxury night design=luxury lux=1.000 smooth=1.000 n8=8 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=12.37
ZEDQA dnt luxury nightoff design=luxury lux=1.000 smooth=1.000 n8=8 lit=false over=dash_luxury_dark lights=true dashLit=true k=2 hour=12.37
ZEDQA dnt ambulance real design=ambulance lux=1.000 smooth=1.000 n8=0 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=12.39
ZEDQA dnt ambulance day design=ambulance lux=1.000 smooth=1.000 n8=0 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=12.39
ZEDQA dnt ambulance dusk design=ambulance lux=1.000 smooth=1.000 n8=4 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=12.39
ZEDQA dnt ambulance night design=ambulance lux=1.000 smooth=1.000 n8=8 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=12.39
ZEDQA dnt ambulance nightoff design=ambulance lux=1.000 smooth=1.000 n8=8 lit=false over=dash_ambulance_dark lights=true dashLit=true k=2 hour=12.40
ERROR: General f:29418 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:29421 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dnt race real design=race lux=1.000 smooth=1.000 n8=0 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=12.42
ZEDQA dnt race day design=race lux=1.000 smooth=1.000 n8=0 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=12.42
ZEDQA dnt race dusk design=race lux=1.000 smooth=1.000 n8=4 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=12.42
ZEDQA dnt race night design=race lux=1.000 smooth=1.000 n8=8 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=12.42
ZEDQA dnt race nightoff design=race lux=1.000 smooth=1.000 n8=8 lit=false over=dash_race_dark lights=true dashLit=true k=2 hour=12.43
ZEDQA dnt d6 real design=d6 lux=1.000 smooth=1.000 n8=0 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=12.44
ZEDQA dnt d6 day design=d6 lux=1.000 smooth=1.000 n8=0 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=12.45
ZEDQA dnt d6 dusk design=d6 lux=1.000 smooth=1.000 n8=4 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=12.45
ZEDQA dnt d6 night design=d6 lux=1.000 smooth=1.000 n8=8 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=12.45
ZEDQA dnt d6 nightoff design=d6 lux=1.000 smooth=1.000 n8=8 lit=false over=dash_d6_dark lights=true dashLit=true k=2 hour=12.45
ZEDQA dnt DONE
```

### 11. zedqa_testlang.lua (`ZEDQA tlang`) - PASS, 130 s

- go 13225 at 20:08:36
- screenshots: zqa_tl_01_char_loot_list.png, zqa_tl_02_char_loot_grid.png, zqa_tl_03_card_food.png, zqa_tl_04_card_weapon.png, zqa_tl_05_card_bottle.png, zqa_tl_06_card_gun.png, zqa_tl_07_char_equip_list.png, zqa_tl_08_char_equip_doll.png, zqa_tl_09_char_health.png, zqa_tl_10_char_thermal_1.png, zqa_tl_11_char_thermal_2.png, zqa_tl_12_char_thermal_3.png, zqa_tl_13_char_thermal_4.png, zqa_tl_14_char_thermal_5.png, zqa_tl_15_char_thermal_6.png, zqa_tl_16_char_thermal_7.png, zqa_tl_17_char_thermal_figure.png, zqa_tl_18_char_identity.png, zqa_tl_19_char_journal_1.png, zqa_tl_20_char_journal_2.png, zqa_tl_21_char_journal_3.png, zqa_tl_22_char_journal_4.png, zqa_tl_23_char_skills.png, zqa_tl_24_char_radio.png, zqa_tl_25_char_loot_back.png, zqa_tl_26_ctx_strip_food.png, zqa_tl_27_ctx_strip_weapon.png, zqa_tl_28_ctx_list_food.png, zqa_tl_29_ctx_list_submenu.png, zqa_tl_30_world_loot.png, zqa_tl_31_world_craft_list.png, zqa_tl_32_world_craft_recipe.png, zqa_tl_33_world_build_list.png, zqa_tl_34_world_build_recipe.png, zqa_tl_35_world_furniture.png, zqa_tl_36_world_furniture_rotate.png, zqa_tl_37_world_furniture_scrap.png, zqa_tl_38_world_furniture_repair.png, zqa_tl_39_world_furniture_pickup.png, zqa_tl_40_world_maps.png, zqa_tl_41_world_maps_survey.png, zqa_tl_42_world_maps_color.png, zqa_tl_43_world_maps_paper.png, zqa_tl_44_world_forage.png, zqa_tl_45_world_animals.png, zqa_tl_46_belt_watch_tucked.png, zqa_tl_47_belt_watch_popped.png, zqa_tl_48_watch_corner.png, zqa_tl_49_actionbar_reading_verbose.png, zqa_tl_50_actionbar_reading_simple.png, zqa_tl_51_wheel_emotes.png, zqa_tl_52_wheel_vehicle_outside.png, zqa_tl_53_prompt_question.png, zqa_tl_54_prompt_textbox.png, zqa_tl_55_prompt_textbox_empty.png, zqa_tl_56_prompt_keyboard.png, zqa_tl_57_prompt_alarm.png, zqa_tl_58_prompt_timer.png, zqa_tl_59_prompt_help.png, zqa_tl_60_prompt_rich_question.png, zqa_tl_61_safe_note.png, zqa_tl_62_pause_menu.png, zqa_tl_63_options_1_zed.png, zqa_tl_64_options_2_display.png, zqa_tl_65_options_3_graphics.png, zqa_tl_66_options_4_audio.png, zqa_tl_67_options_5_controls.png, zqa_tl_68_options_6_gameplay.png, zqa_tl_69_options_7_interface.png, zqa_tl_70_options_8_access.png, zqa_tl_71_options_9_mods.png, zqa_tl_72_pause_mods.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tlang start (209 steps)
[ZeD.QA] run #11 ok=true
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
ZEDQA tlang recipe open in craft: 000***Buy Brown Skin
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

### 12. zedqa_safemode.lua (`ZEDQA safe`) - PASS, 13 s

- go 13226 at 20:10:51
- screenshots: zqa_safe_1.png, zqa_safe_2.png, zqa_safe_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA safe start
[ZeD.QA] run #12 ok=true
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
ZEDQA safe option On picked up by the poll: picked up after 385 ms
ZEDQA safe ok option On picked up by the poll
ZEDQA safe option on: on true | pair false/false | vanilla inv true | hotbar vanilla | clock y 10 visible false | speed y 10 | moodle layer false
ZEDQA safe ok option on
ZEDQA safe option Off picked up by the poll: picked up after 443 ms
ZEDQA safe ok option Off picked up by the poll
ZEDQA safe option off: on false | pair false/false | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok option off
ZEDQA safe burst: 5 ticks, still off after 2508 ms
ZEDQA safe ok watchdog: a five-frame burst leaves ZeD on
ZEDQA safe streak: tripped after 2003 ms, 239 frames, longest gap 33 ms
ZEDQA safe ok watchdog: below two seconds of failures ZeD stays on
ZEDQA safe ok watchdog: two seconds of failures every frame trip it
ZEDQA safe ok watchdog note shows and closes
ZEDQA safe restored: on false | pair true/true | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok restored
ZEDQA safe DONE
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
    1x ERROR: General f:N at KahluaThread.flushErrorMessage > expected argument of type ItemBodyLocation, got String
    1x ERROR: General f:N> Lua((MOD:Cosplay商店(B42))).CosShopBodyLocations.lua> Exception thrown  :: java.lang.RuntimeException: expected argument of type ItemBodyLocation, got String at MethodArguments.assertValid(MethodArguments.java:128).
    6x ERROR: General f:N> Lua((MOD:Better Sorting)).BSdynamicCats> Exception thrown  :: java.lang.NullPointerException: Cannot invoke "zombie.inventory.InventoryItem.setAlcoholPower(float)" because "item" is null at Item.InstanceItem(Item.java:1849).
    4x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateWeaponWithStock"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateM4"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateM9"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreate1911"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateDEagle"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateM16"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateAKM"
    1x ERROR: General f:N at KahluaThread.flushErrorMessage > -------------------------------------------------------------  :: attempted index: setAutoFixModOrder of non-table: null
    1x ERROR: General f:N> Lua((MOD:ZombieBuddy)).applySettings> Exception thrown  :: java.lang.RuntimeException: attempted index: setAutoFixModOrder of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    3x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Body"
```
