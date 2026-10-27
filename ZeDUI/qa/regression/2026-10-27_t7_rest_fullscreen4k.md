# ZeD-UI regression - 2026-10-27 10:33 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-27 10:33:21 |
| Finished | 2026-10-27 11:01:35 (28 min 13 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/AppData/Local/Temp/claude/C--Users-danie-Zomboid/7395e6f8-af8b-4442-87a0-5848151409de/scratchpad/t7/reg_rest.txt (29 scripts) |
| Result | **29/29 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 14363 to 14393 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 14392, 14393)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_dpad_wheels.lua | dw | PASS | 44 | zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png |  |
| 3 | zedqa_pad_glyphs.lua | pg | PASS | 27 | zqa_pg_footer_ps.png, zqa_pg_wheel_ps.png, zqa_pg_footer_xbox.png, zqa_pg_wheel_xbox.png, zqa_pg_footer_deck.png, zqa_pg_wheel_deck.png, zqa_pg_footer_nintendo.png, zqa_pg_wheel_nintendo.png, zqa_pg_footer_kbm.png, zqa_pg_wheel_kbm.png, zqa_pg_footer_ps_light.png, zqa_pg_wheel_ps_light.png, zqa_pg_footer_ps_hicon.png, zqa_pg_wheel_ps_hicon.png |  |
| 4 | zedqa_quick_chords.lua | qc | PASS | 21 | zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png |  |
| 5 | zedqa_put_back.lua | pb | PASS | 34 |  |  |
| 6 | zedqa_food_verbs.lua | fv | PASS | 4 | zqa_fv_smoking.png |  |
| 7 | zedqa_messages.lua | msg | PASS | 11 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=) |
| 8 | zedqa_moodles.lua | mood | PASS | 19 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png |  |
| 9 | zedqa_ring_squares.lua | rs | PASS | 7 | zqa_rs_belt_full.png, zqa_rs_belt_70_45.png, zqa_rs_belt_15.png |  |
| 10 | zedqa_sandbox_ig.lua | sbx | PASS | 16 | zqa_sbx_pause_line.png, zqa_sbx_time.png, zqa_sbx_world_help.png, zqa_sbx_zombie_changed.png, zqa_sbx_ask_apply.png, zqa_sbx_applied.png, zqa_sbx_history.png, zqa_sbx_pad.png |  |
| 11 | zedqa_twoway.lua | tw | PASS | 41 | zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png |  |
| 12 | zedqa_appliances.lua | ap | PASS | 23 | zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png |  |
| 13 | zedqa_seat_lightbar_vanilla.lua | sl | PASS | 23 | zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png |  |
| 14 | zedqa_car_radio_build.lua | rb | PASS | 34 | zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png |  |
| 15 | zedqa_car_radio_cd.lua | cd | PASS | 12 | zqa_cd_c01_cdlist.png, zqa_cd_c02_cd_playing.png, zqa_cd_c03_ejected.png, zqa_cd_c04_valutech_tape.png |  |
| 16 | zedqa_dash_props_smoke.lua | sm | PASS | 7 | zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png |  |
| 17 | zedqa_tm.lua | tm | PASS | 8 | zedqa_tm_tooltips.png, zedqa_tm_maps.png, zedqa_tm_dash.png |  |
| 18 | zedqa_tour3.lua | t3 | PASS | 17 | zedqa_t3_SmallCar02.png, zedqa_t3_ModernCar.png, zedqa_t3_ModernCar02.png, zedqa_t3_SUV.png, zedqa_t3_Van.png, zedqa_t3_PickUpVan.png, zedqa_t3_OffRoad.png |  |
| 19 | zedqa_dash19.lua | dash | PASS | 77 | zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png |  |
| 20 | zedqa_dashpx.lua | dpx | PASS | 137 | zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_07_primani_keyon.png, zqa_dashpx_07_primani.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png, zqa_dashpx_14_rancher.png, zqa_dashpx_15_taxi_keyon.png, zqa_dashpx_15_taxi.png, zqa_dashpx_16_ambulance_keyon.png, zqa_dashpx_16_ambulance.png, zqa_dashpx_17_fire_keyon.png, zqa_dashpx_17_fire.png, zqa_dashpx_18_ranger_keyon.png, zqa_dashpx_18_ranger.png, zqa_dashpx_19_race_keyon.png, zqa_dashpx_19_race.png, zqa_dashpx_20_knoxvan_keyon.png, zqa_dashpx_20_knoxvan.png, zqa_dashpx_21_fossoild6_keyon.png, zqa_dashpx_21_fossoild6.png, zqa_dashpx_23_meadesheriff_keyon.png, zqa_dashpx_23_meadesheriff.png, zqa_dashpx_24_lcpd_keyon.png, zqa_dashpx_24_lcpd.png |  |
| 21 | zedqa_exinfo.lua | ex | PASS | 5 | zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png |  |
| 22 | zedqa_charinfo.lua | ci | PASS | 9 |  |  |
| 23 | zedqa_equipdrag.lua | eqd | PASS | 11 | zqa_eqd_1.png, zqa_eqd_2.png, zqa_eqd_3.png, zqa_eqd_4.png |  |
| 24 | zedqa_cazio_light.lua | czl | PASS | 29 | zqa_cl_day_DigitalBlack.png, zqa_cl_daylit_DigitalBlack.png, zqa_cl_night_DigitalBlack.png, zqa_cl_nightlit_DigitalBlack.png, zqa_cl_day_DigitalDress.png, zqa_cl_daylit_DigitalDress.png, zqa_cl_night_DigitalDress.png, zqa_cl_nightlit_DigitalDress.png, zqa_cl_day_ClassicBlack.png, zqa_cl_daylit_ClassicBlack.png, zqa_cl_night_ClassicBlack.png, zqa_cl_nightlit_ClassicBlack.png, zqa_cl_day_ClassicGold.png, zqa_cl_daylit_ClassicGold.png, zqa_cl_night_ClassicGold.png, zqa_cl_nightlit_ClassicGold.png, zqa_cl_belt_night.png, zqa_cl_belt_nightlit.png, zqa_cl_belt_day.png, zqa_cl_belt_daylit.png |  |
| 25 | zedqa_dashnight.lua | dnt | PASS | 105 | zqa_dashnight_wagon_real.png, zqa_dashnight_wagon_day.png, zqa_dashnight_wagon_dusk.png, zqa_dashnight_wagon_night.png, zqa_dashnight_wagon_nightoff.png, zqa_dashnight_wagon_real_noon.png, zqa_dashnight_wagon_real_back_on.png, zqa_dashnight_wagon_real_back_off.png, zqa_dashnight_nyala_real.png, zqa_dashnight_nyala_day.png, zqa_dashnight_nyala_dusk.png, zqa_dashnight_nyala_night.png, zqa_dashnight_nyala_nightoff.png, zqa_dashnight_dashelite_real.png, zqa_dashnight_dashelite_day.png, zqa_dashnight_dashelite_dusk.png, zqa_dashnight_dashelite_night.png, zqa_dashnight_dashelite_nightoff.png, zqa_dashnight_luxury_real.png, zqa_dashnight_luxury_day.png, zqa_dashnight_luxury_dusk.png, zqa_dashnight_luxury_night.png, zqa_dashnight_luxury_nightoff.png, zqa_dashnight_ambulance_real.png, zqa_dashnight_ambulance_day.png, zqa_dashnight_ambulance_dusk.png, zqa_dashnight_ambulance_night.png, zqa_dashnight_ambulance_nightoff.png, zqa_dashnight_race_real.png, zqa_dashnight_race_day.png, zqa_dashnight_race_dusk.png, zqa_dashnight_race_night.png, zqa_dashnight_race_nightoff.png, zqa_dashnight_d6_real.png, zqa_dashnight_d6_day.png, zqa_dashnight_d6_dusk.png, zqa_dashnight_d6_night.png, zqa_dashnight_d6_nightoff.png |  |
| 26 | zedqa_testlang.lua | tlang | PASS | 79 | zqa_tl_01_char_loot_list.png, zqa_tl_02_char_loot_grid.png, zqa_tl_03_card_food.png, zqa_tl_04_card_weapon.png, zqa_tl_05_card_bottle.png, zqa_tl_06_card_gun.png, zqa_tl_07_char_equip_list.png, zqa_tl_08_char_equip_doll.png, zqa_tl_09_char_health.png, zqa_tl_10_char_thermal_1.png, zqa_tl_11_char_thermal_2.png, zqa_tl_12_char_thermal_3.png, zqa_tl_13_char_thermal_4.png, zqa_tl_14_char_thermal_5.png, zqa_tl_15_char_thermal_6.png, zqa_tl_16_char_thermal_7.png, zqa_tl_17_char_thermal_figure.png, zqa_tl_18_char_identity.png, zqa_tl_19_char_journal_1.png, zqa_tl_20_char_journal_2.png, zqa_tl_21_char_journal_3.png, zqa_tl_22_char_journal_4.png, zqa_tl_23_char_skills.png, zqa_tl_24_char_radio.png, zqa_tl_25_char_loot_back.png, zqa_tl_26_ctx_strip_food.png, zqa_tl_27_ctx_strip_weapon.png, zqa_tl_28_ctx_list_food.png, zqa_tl_29_ctx_list_submenu.png, zqa_tl_30_world_loot.png, zqa_tl_31_world_craft_list.png, zqa_tl_32_world_craft_recipe.png, zqa_tl_33_world_build_list.png, zqa_tl_34_world_build_recipe.png, zqa_tl_35_world_furniture.png, zqa_tl_36_world_furniture_rotate.png, zqa_tl_37_world_furniture_scrap.png, zqa_tl_38_world_furniture_repair.png, zqa_tl_39_world_furniture_pickup.png, zqa_tl_40_world_maps.png, zqa_tl_41_world_maps_survey.png, zqa_tl_42_world_maps_color.png, zqa_tl_43_world_maps_paper.png, zqa_tl_44_world_forage.png, zqa_tl_45_world_animals.png, zqa_tl_46_belt_watch_tucked.png, zqa_tl_47_belt_watch_popped.png, zqa_tl_48_watch_corner.png, zqa_tl_49_actionbar_reading_verbose.png, zqa_tl_50_actionbar_reading_simple.png, zqa_tl_51_wheel_emotes.png, zqa_tl_52_wheel_vehicle_outside.png, zqa_tl_53_prompt_question.png, zqa_tl_54_prompt_textbox.png, zqa_tl_55_prompt_textbox_empty.png, zqa_tl_56_prompt_keyboard.png, zqa_tl_57_prompt_alarm.png, zqa_tl_58_prompt_timer.png, zqa_tl_59_prompt_help.png, zqa_tl_60_prompt_rich_question.png, zqa_tl_61_safe_note.png, zqa_tl_62_pause_menu.png, zqa_tl_63_options_1_zed.png, zqa_tl_64_options_2_display.png, zqa_tl_65_options_3_graphics.png, zqa_tl_66_options_4_audio.png, zqa_tl_67_options_5_controls.png, zqa_tl_68_options_6_gameplay.png, zqa_tl_69_options_7_interface.png, zqa_tl_70_options_8_access.png, zqa_tl_71_options_9_mods.png, zqa_tl_72_pause_mods.png |  |
| 27 | zedqa_safemode.lua | safe | PASS | 11 | zqa_safe_1.png, zqa_safe_2.png, zqa_safe_3.png |  |
| 28 | zedqa_soak.lua | soak | PASS | 655 |  |  |
| 29 | zedqa_hands_together.lua | ht | PASS | 11 | zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 14363 at 10:34:44

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_dpad_wheels.lua (`ZEDQA dw`) - PASS, 44 s

- go 14364 at 10:34:50
- screenshots: zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png

```text
[ZeD.QA] windows reset (R)
ZEDQA dw start
[ZeD.QA] run #2 ok=true
ZEDQA dw scene: at 12195,11829, in a car false, health 100
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
ZEDQA dw foot select: 12 slices, crumb ZeD, visible true | 1:Base theme / Dark [>] 2:Accent color / Purple [>] 3:Text size / Small [>] 4:See-through / 90% [>] 5:Controller highlight / Pointing hand [>] 6:UI scale [>] 7:Moodles / Right edge [>] 8:Action bar / Verbose [>] 9:Messages / No messages. [off] 10:Reset windows / Both windows back to where they start 11:ZeD setup / Options, on ZeD's page 12:Safe mode / The game's own interface
ZEDQA dw PASS select: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS select: the slice 'Base theme' is there
ZEDQA dw inner select: 4 slices, crumb ZeD + Base theme, visible true | 1:Dark / In use 2:Light 3:High contrast 4:Back
ZEDQA dw PASS select: the inner wheel ends with Back
ZEDQA dw PASS select: the breadcrumb names the inner wheel
ZEDQA dw PASS select: B from the inner wheel is back on the top level
ZEDQA dw PASS select: B on the top level closes the wheel
ZEDQA dw look back to dark / purple / small
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

### 3. zedqa_pad_glyphs.lua (`ZEDQA pg`) - PASS, 27 s

- go 14365 at 10:35:37
- screenshots: zqa_pg_footer_ps.png, zqa_pg_wheel_ps.png, zqa_pg_footer_xbox.png, zqa_pg_wheel_xbox.png, zqa_pg_footer_deck.png, zqa_pg_wheel_deck.png, zqa_pg_footer_nintendo.png, zqa_pg_wheel_nintendo.png, zqa_pg_footer_kbm.png, zqa_pg_wheel_kbm.png, zqa_pg_footer_ps_light.png, zqa_pg_wheel_ps_light.png, zqa_pg_footer_ps_hicon.png, zqa_pg_wheel_ps_hicon.png

```text
[ZeD.QA] windows reset (R)
ZEDQA pg start
[ZeD.QA] run #3 ok=true
ZEDQA pg scene: glyph setting xbox, the game's style XBOX, input gamepad
ZEDQA pg PASS ps: the setting reads ps
ZEDQA pg PASS ps: the set in use is ps
ZEDQA pg ps: footer pictures drawn in 10 ticks: 36
ZEDQA pg PASS ps: the footer draws its buttons as pictures
ZEDQA pg ps: wheel pictures drawn in 5 ticks: 24
ZEDQA pg PASS ps: the wheel's prompts are pictures
ZEDQA pg PASS xbox: the setting reads xbox
ZEDQA pg PASS xbox: the set in use is xbox
ZEDQA pg xbox: footer pictures drawn in 10 ticks: 30
ZEDQA pg PASS xbox: the footer draws its buttons as pictures
ZEDQA pg xbox: wheel pictures drawn in 5 ticks: 16
ZEDQA pg PASS xbox: the wheel's prompts are pictures
ZEDQA pg PASS deck: the setting reads deck
ZEDQA pg PASS deck: the set in use is deck
ZEDQA pg deck: footer pictures drawn in 10 ticks: 30
ZEDQA pg PASS deck: the footer draws its buttons as pictures
ZEDQA pg deck: wheel pictures drawn in 5 ticks: 16
ZEDQA pg PASS deck: the wheel's prompts are pictures
ZEDQA pg PASS nintendo: the setting reads nintendo
ZEDQA pg PASS nintendo: the set in use is nin
ZEDQA pg nintendo: footer pictures drawn in 10 ticks: 36
ZEDQA pg PASS nintendo: the footer draws its buttons as pictures
ZEDQA pg nintendo: wheel pictures drawn in 5 ticks: 16
ZEDQA pg PASS nintendo: the wheel's prompts are pictures
ZEDQA pg PASS kbm: the setting reads kbm
ZEDQA pg PASS kbm: the set in use is nil
ZEDQA pg kbm: footer pictures drawn in 10 ticks: 0
ZEDQA pg PASS kbm: the footer draws boxed names, no pictures
ZEDQA pg kbm: wheel pictures drawn in 5 ticks: 0
ZEDQA pg no deep-run car within 8 tiles: the dash scene is skipped
ZEDQA pg put back: glyph setting xbox, input lock nil
ZEDQA pg all checks passed
ZEDQA pg DONE
```

### 4. zedqa_quick_chords.lua (`ZEDQA qc`) - PASS, 21 s

- go 14366 at 10:36:08
- screenshots: zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png

```text
[ZeD.QA] windows reset (R)
ZEDQA qc start
[ZeD.QA] run #4 ok=true
ZEDQA qc the torch (added) and water, a cigarette, a lighter, an apple in the main inventory; hands: nil / nil
ZEDQA qc LB + X picks Base.HandTorch in none (brighter than the torch): that light is checked
ZEDQA qc LB+A = character:3 (Character > Eat): Eat
ZEDQA qc PASS LB+A: the default names a slice
ZEDQA qc LB+B = character:4 (Character > Drink): Drink
ZEDQA qc PASS LB+B: the default names a slice
ZEDQA qc LB+X = now:8 (Here and now > Light): Flashlight
ZEDQA qc PASS LB+X: the default names a slice
ZEDQA qc LB+Y = character:8:1 (Character > Use > Smoke): Smoke
ZEDQA qc PASS LB+Y: the default names a slice
ZEDQA qc LB+L3 = now:1:1 (Here and now > Sit > Sit on ground): Sit on ground
ZEDQA qc PASS LB+L3: the default names a slice
ZEDQA qc LB+R3 = social:5 (Social > Shout): Shout
ZEDQA qc PASS LB+R3: the default names a slice
ZEDQA qc RB+A = character:5 (Character > Medicine and first aid): Medicine and first aid [off: Nothing to treat, no medicine on you.]
ZEDQA qc PASS RB+A: the default names a slice
ZEDQA qc RB+B = character:2 (Character > Weapons): Weapons
ZEDQA qc PASS RB+B: the default names a slice
ZEDQA qc RB+X = character:8:2 (Character > Use > Read): Read
ZEDQA qc PASS RB+X: the default names a slice
ZEDQA qc RB+Y = world:2:1 (World > Map > Show/Hide World Map): Show/Hide World Map
ZEDQA qc PASS RB+Y: the default names a slice
ZEDQA qc RB+L3 = now:3 (Here and now > Auto-walk): Auto-walk
ZEDQA qc PASS RB+L3: the default names a slice
ZEDQA qc RB+R3 = now:2 (Here and now > Crouch): Crouch
ZEDQA qc PASS RB+R3: the default names a slice
ZEDQA qc LB + X queued: ISEquipWeaponAction
ZEDQA qc PASS LB + X: the game's prompts never saw X
ZEDQA qc PASS a light for LB + X
ZEDQA qc PASS LB + X: the light is in a hand
ZEDQA qc PASS LB + X: the light is on
ZEDQA qc PASS LB + X again: the light is off
ZEDQA qc LB + X from a bag: skipped, LB + X picks Base.HandTorch in a hand or on the belt first
ZEDQA qc PASS stuffed: Eat says Too full to eat more.
ZEDQA qc LB + A (eat) queued: ISEatFoodAction
ZEDQA qc PASS LB + A (eat): the game queues its action
ZEDQA qc LB + B (drink) queued: ISDrinkFromBottle
ZEDQA qc PASS LB + B (drink): the game queues its action
ZEDQA qc LB + Y (smoke) queued: ISEatFoodAction, ISInventoryTransferAction
ZEDQA qc PASS LB + Y (smoke): the game queues its action
ZEDQA qc said: No QA Gone on you.
ZEDQA qc PASS a gone thing: the character says No QA Gone on you.
ZEDQA qc PASS the Here and now wheel is open
ZEDQA qc PASS RB + Y on Crouch: the chord reads now:2
ZEDQA qc the bubble's note: Now on RB + Y. It replaces Show/Hide World Map.
ZEDQA qc PASS the bubble says what it did
ZEDQA qc PASS opened again: Crouch shows RB + Y
ZEDQA qc PASS ZeD setup is open on the pause screen
ZEDQA qc PASS ZeD setup has the twelve chord rows (12)
ZEDQA qc PASS ZeD setup has Put things back
ZEDQA qc the list for LB+A: 87 items, 79 to choose
ZEDQA qc PASS the chord's list offers the wheels' actions
ZEDQA qc put back: the chords file as it was; RB + Y reads world:2:1 (was world:2:1)
ZEDQA qc PASS the chords are as they were
ZEDQA qc all checks passed
ZEDQA qc DONE
```

### 5. zedqa_put_back.lua (`ZEDQA pb`) - PASS, 34 s

- go 14367 at 10:36:32

```text
[ZeD.QA] windows reset (R)
ZEDQA pb start
[ZeD.QA] run #5 ok=true
ZEDQA pb PASS the switch is on
ZEDQA pb the bag: Small Backpack; hands: nil / nil
ZEDQA pb PASS a worn bag to take things from
ZEDQA pb apple: queue empty true, the apple is in bag; put back queued 0
ZEDQA pb PASS half an apple: the rest went back into the bag
ZEDQA pb PASS half an apple: the game put it back itself, ZeD moved nothing twice
ZEDQA pb smoke: queue empty true, the lighter is in bag, the cigarette in nowhere
ZEDQA pb PASS a cigarette: the lighter went back into the bag
ZEDQA pb drink: thirst 0.40, the bottle holds 0.80
ZEDQA pb drink look 1: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 2: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 3: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 4: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 5: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 6: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 7: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 8: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink: queue empty true, the bottle is in bag
ZEDQA pb PASS a drink: the bottle went back into the bag
ZEDQA pb no deep-run car within 10 tiles: the tire scene is skipped
ZEDQA pb stopped: the apple is in main
ZEDQA pb PASS stopped halfway: the apple stays on you
ZEDQA pb switch off: the bottle is in main
ZEDQA pb PASS the switch off: the bottle stays on you
ZEDQA pb put back: the switch 1 (was 1)
ZEDQA pb all checks passed
ZEDQA pb DONE
```

### 6. zedqa_food_verbs.lua (`ZEDQA fv`) - PASS, 4 s

- go 14368 at 10:37:09
- screenshots: zqa_fv_smoking.png

```text
[ZeD.QA] windows reset (R)
ZEDQA fv start
[ZeD.QA] run #6 ok=true
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

### 7. zedqa_messages.lua (`ZEDQA msg`) - PASS, 11 s

- go 14369 at 10:37:17
- 1 expected exception(s) ignored (expect=)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
[ZeD.QA] windows reset (R)
ZEDQA msg start
[ZeD.QA] run #7 ok=true
ZEDQA msg PASS nothing kept: no envelope on the belt
ZEDQA msg PASS the three notes are not on screen
ZEDQA msg PASS the three notes are kept in Messages
ZEDQA msg PASS the source has three messages (3)
ZEDQA msg PASS three are new (3)
ZEDQA msg PASS a toast names the mod
ZEDQA msg PASS the game runs on after the mod paused it for its note (speed 1)
ZEDQA msg PASS the envelope is on the belt
ZEDQA msg PASS a question still asks at once
ZEDQA msg PASS the mod got its answer (YES)
ZEDQA msg PASS a copy of the question, already read, is in Messages
ERROR: General f:10741 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:10741> Lua(Vanilla).boom> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaMessagesError of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom(spawnpoints.lua:99)
ZEDQA msg PASS the one error is filed in Messages, counted once (0 -> 1)
ZEDQA msg PASS Messages opens on the mod
ZEDQA msg PASS opening it marks the mod's messages read
ZEDQA msg PASS four cards: three notes and the question (4)
ZEDQA msg PASS three OK buttons, one per note (3)
ZEDQA msg PASS OK ran that mod's callback once (1/0/0)
ZEDQA msg PASS A on the next card's OK ran its callback
ZEDQA msg PASS the controller is in the cards
ZEDQA msg PASS the window lists an error source
ZEDQA msg PASS the bug report text names the errors (1437 characters)
ZEDQA msg PASS with the switch on, the mod's note shows as a pop-up
ZEDQA msg PASS Clear removes the mod's messages
ZEDQA msg PASS the last unanswered note got its OK as it left
ZEDQA msg all checks passed
ZEDQA msg DONE
```

### 8. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 19 s

- go 14370 at 10:37:31
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #8 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 4
ZEDQA mood box by itself: STRESS | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA mood right: 4 moodles on (STRESS 2, TIRED 2, THIRST 2, HUNGRY 2)
ZEDQA mood PASS right: the place is in effect
ZEDQA mood PASS right: at least three moodles are on
ZEDQA mood PASS right: the moodles are shown (layer)
ZEDQA mood right column at 3782,969 size 48, stack 222; visible true
ZEDQA mood PASS right: vanilla's column is visible
ZEDQA mood PASS right: every moodle is on screen
ZEDQA mood PASS right: the column is on the right edge (x 3782)
ZEDQA mood PASS right: ZeD's hover layer lies over the column
ZEDQA mood right bubble: moodle 2, cloud -500,19 442x126, trail right from -56,82
ZEDQA mood PASS right: the bubble is for the moodle under the pointer
ZEDQA mood PASS right: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS right: the trail ends at the moodle, level with it
ZEDQA mood left: 4 moodles on (STRESS 2, TIRED 2, THIRST 2, HUNGRY 2)
ZEDQA mood PASS left: the place is in effect
ZEDQA mood PASS left: at least three moodles are on
ZEDQA mood PASS left: the moodles are shown (layer)
ZEDQA mood left column at 10,969 size 48, stack 222; visible true
ZEDQA mood PASS left: vanilla's column is visible
ZEDQA mood PASS left: every moodle is on screen
ZEDQA mood PASS left: the column is on the left edge (x 10)
ZEDQA mood PASS left: ZeD's hover layer lies over the column
ZEDQA mood left bubble: moodle 2, cloud 106,19 442x126, trail left from 104,82
ZEDQA mood PASS left: the bubble is for the moodle under the pointer
ZEDQA mood PASS left: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS left: the trail ends at the moodle, level with it
ZEDQA mood bottom: 4 moodles on (STRESS 2, TIRED 2, THIRST 2, HUNGRY 2)
ZEDQA mood PASS bottom: the place is in effect
ZEDQA mood PASS bottom: at least three moodles are on
ZEDQA mood PASS bottom: the moodles are shown (layer)
ZEDQA mood bottom row at 1809,1965 222x48; vanilla's column y -10000
ZEDQA mood PASS bottom: the row is on screen
ZEDQA mood PASS bottom: the row is centred (middle 1920 of 3840)
ZEDQA mood PASS bottom: the row sits above the belt
ZEDQA mood PASS bottom: one slot per moodle
ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
ZEDQA mood bottom bubble: moodle 2, cloud -133,-184 442x126, trail down from 82,-56
ZEDQA mood PASS bottom: the bubble is for the moodle under the pointer
ZEDQA mood PASS bottom: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS bottom: the trail ends at the moodle, level with it
ZEDQA mood PASS with nothing changing the box goes by itself (nil)
ZEDQA mood notices off: box nil | waiting 2
ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
ZEDQA mood all checks passed
ZEDQA mood DONE
```

### 9. zedqa_ring_squares.lua (`ZEDQA rs`) - PASS, 7 s

- go 14371 at 10:37:53
- screenshots: zqa_rs_belt_full.png, zqa_rs_belt_70_45.png, zqa_rs_belt_15.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rs start
[ZeD.QA] run #9 ok=true
ZEDQA rs belt at 1343,2034, hands: s 0,10 77 | p 88,0 98
ZEDQA rs PASS full: both hands on the belt
ZEDQA rs PASS full: the conditions read 1.00 / 1.00
ZEDQA rs belt at 1343,2034, hands: s 0,10 77 | p 88,0 98
ZEDQA rs PASS 70_45: both hands on the belt
ZEDQA rs PASS 70_45: the conditions read 0.70 / 0.50
ZEDQA rs belt at 1343,2034, hands: s 0,10 77 | p 88,0 98
ZEDQA rs PASS 15: both hands on the belt
ZEDQA rs PASS 15: the conditions read 0.20 / 0.20
ZEDQA rs all checks passed
ZEDQA rs DONE
```

### 10. zedqa_sandbox_ig.lua (`ZEDQA sbx`) - PASS, 16 s

- go 14372 at 10:38:04
- screenshots: zqa_sbx_pause_line.png, zqa_sbx_time.png, zqa_sbx_world_help.png, zqa_sbx_zombie_changed.png, zqa_sbx_ask_apply.png, zqa_sbx_applied.png, zqa_sbx_history.png, zqa_sbx_pad.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sbx start
[ZeD.QA] run #10 ok=true
ZEDQA sbx PASS the pause window is up
ZEDQA sbx PASS switch off: no Sandbox options line
ZEDQA sbx PASS switch on: the Sandbox options line is there
ZEDQA sbx PASS the window is open over the paused game
ZEDQA sbx pages: Time, Zombie, Loot, World, Nature, Meta, Character, Vehicles, Livestock, ZeD-GUI, Changed, History
ZEDQA sbx PASS vanilla's pages plus Changed and History (12)
ZEDQA sbx PASS every setting has a row (261)
ZEDQA sbx PASS nothing marked changed on opening
ZEDQA sbx PASS the help band has room
ZEDQA sbx PASS Start Month is fixed (locked)
ZEDQA sbx PASS a fixed setting does not change
ZEDQA sbx PASS the World page starts with the world's day
ZEDQA sbx world line: This world is on day 5 of the count the shut-offs use. Water: on until day 14. Power: on until day 14.
ZEDQA sbx PASS Zombie Count and Population Multiplier rows
ZEDQA sbx PASS Zombie Count Low sets Population Multiplier to 0.15 (0.15)
ZEDQA sbx PASS two settings marked changed (2)
ZEDQA sbx PASS Undo changes puts both back
ZEDQA sbx PASS four changes marked (4)
ZEDQA sbx PASS nothing applied before Apply
ZEDQA sbx PASS Apply asks first
ZEDQA sbx PASS the question shows the Changed page
ZEDQA sbx ask: nil
ZEDQA sbx PASS FoodRotSpeed applied (3 > 4)
ZEDQA sbx PASS HoursForCorpseRemoval applied (216.0 > 100.0)
ZEDQA sbx PASS FireSpread applied (true > false)
ZEDQA sbx PASS DayLength applied (4 > 5)
ZEDQA sbx PASS SandboxVars has the new number (100)
ZEDQA sbx PASS the clock took the new day length (90 > 120)
ZEDQA sbx PASS History has the apply
ZEDQA sbx PASS nothing marked changed after Apply
ZEDQA sbx strip: nil
ZEDQA sbx PASS History lists the four with Put back (4)
ZEDQA sbx PASS Put back marks four changes (4)
ZEDQA sbx PASS FoodRotSpeed back to 3
ZEDQA sbx PASS HoursForCorpseRemoval back to 216.0
ZEDQA sbx PASS FireSpread back to true
ZEDQA sbx PASS DayLength back to 4
ZEDQA sbx PASS the day's length back (90)
ZEDQA sbx PASS the D-pad lands on a row
ZEDQA sbx prompts: <> A LB RB B
ZEDQA sbx PASS the footer shows the pad's buttons
ZEDQA sbx PASS History as it was
ZEDQA sbx all checks passed
ZEDQA sbx DONE
```

### 11. zedqa_twoway.lua (`ZEDQA tw`) - PASS, 41 s

- go 14373 at 10:38:23
- screenshots: zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tw start
[ZeD.QA] run #11 ok=true
ZEDQA tw screen 3840x2160, root scale 1.75, plate zoom 2
ZEDQA tw PASS walkie_valutech: the Character window's Radio tab opens
ZEDQA tw PASS walkie_valutech: its own face, walkie_valutech (got walkie_valutech)
ZEDQA tw PASS walkie_valutech: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_valutech: centred in its panel (x 20, want 20)
ZEDQA tw PASS walkie_valutech: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
ZEDQA tw PASS walkie_valutech: all 6 controls on the face (6)
ZEDQA tw PASS walkie_valutech: the full view button in the header
ZEDQA tw PASS walkie_valutech: VOL pressed turns it on
ZEDQA tw PASS walkie_valutech: the display reads while on
ZEDQA tw walkie_valutech: display 151.200 | | BAT 3
ZEDQA tw PASS walkie_valutech: BAT with 3 bars at 60% charge
ZEDQA tw valutech: body 585 px tall, the face's body needs 799 (window 735)
ZEDQA tw PASS valutech: at the default height the body scrolls
ZEDQA tw PASS valutech: the wheel off the knobs scrolls the body (0 -> 0.05)
ZEDQA tw PASS valutech: the grown window shows the whole face, no scrollbar
ZEDQA tw PASS VOL: the wheel turns the volume up (0.50 -> 0.60)
ZEDQA tw PASS TUNE: a click on its right half tunes up a step (151200 -> 151400)
ZEDQA tw PASS TUNE: its left half tunes down a step
ZEDQA tw PASS TUNE: a right-click turns it down
ZEDQA tw PASS MEM: stores the frequency as channel 01 (1 stored)
ZEDQA tw PASS the display shows CH 01 (01)
ZEDQA tw PASS MEM: a second channel stored
ZEDQA tw PASS CH down walks to channel 01
ZEDQA tw PASS CH up walks to channel 02
ZEDQA tw PASS the mic starts muted
ZEDQA tw PASS the TX lamp is dark while the mic is muted
ZEDQA tw PASS PUSH TO TALK latches the mic live
ZEDQA tw PASS the TX lamp lights and the display says TX OK (TX OK)
ZEDQA tw PASS pressed again it mutes the mic (MIC OFF)
ZEDQA tw PASS MEM held (right-click): the naming box opens
ZEDQA tw PASS naming it: channel 02 is QA Farm
ZEDQA tw PASS the header button opens full view on the radio
ZEDQA tw PASS full view is the face alone, no window frame
ZEDQA tw PASS full view is the plate at the plate scale, room for its 1u hard shadow (402x722)
ZEDQA tw PASS the first time it sits centre right of the play area (centre x 2880)
ZEDQA tw PASS every control is on it (6)
ZEDQA tw PASS a control in full view works (CH down)
ZEDQA tw PASS MEM held in full view opens the naming box
ZEDQA tw PASS the face's edge is not a control
ZEDQA tw PASS dragging the face moves full view (2679 -> 2279)
ZEDQA tw PASS the place is kept on the character
ZEDQA tw PASS the header button closes full view
ZEDQA tw PASS the point between the knobs is no control
ZEDQA tw PASS a click on the face away from the controls opens full view
ZEDQA tw PASS it opens where it was dragged to
ZEDQA tw PASS B closes full view
ZEDQA tw PASS Escape closes full view
ZEDQA tw PASS full view closes when the radio leaves the hands
ZEDQA tw PASS pad: the face's VOL is a stop in the tab
ZEDQA tw PASS pad: up on VOL turns it up
ZEDQA tw PASS pad: right from VOL walks to TUNE (radio:tw:tune)
ZEDQA tw PASS pad: A on CH up steps the channel
ZEDQA tw PASS pad: X on MEM opens the naming box
ZEDQA tw PASS pad: A on the full view button opens it
ZEDQA tw PASS pad: full view shows its controller strip
ZEDQA tw PASS pad: full view lands on a control (vol)
ZEDQA tw PASS pad: down on VOL in full view turns it down
ZEDQA tw PASS pad: right walks to TUNE in full view (tune)
ZEDQA tw PASS pad: A on PUSH TO TALK in full view latches the mic
ZEDQA tw PASS pad: B closes full view
ZEDQA tw PASS walkie_toy: the Character window's Radio tab opens
ZEDQA tw PASS walkie_toy: its own face, walkie_toy (got walkie_toy)
ZEDQA tw PASS walkie_toy: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_toy: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_toy: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
ZEDQA tw PASS walkie_toy: all 3 controls on the face (3)
ZEDQA tw PASS walkie_toy: the full view button in the header
ZEDQA tw PASS walkie_toy: VOL pressed turns it on
ZEDQA tw PASS walkie_toy: the display reads while on
ZEDQA tw walkie_toy: display 138.60 MHZ | nil | nil nil
ZEDQA tw PASS toy: no memories, its TALK button
ZEDQA tw PASS toy: the drum shows the frequency
ZEDQA tw PASS walkie_premium: the Character window's Radio tab opens
ZEDQA tw PASS walkie_premium: its own face, walkie_premium (got walkie_premium)
ZEDQA tw PASS walkie_premium: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_premium: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_premium: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
ZEDQA tw PASS walkie_premium: all 6 controls on the face (6)
ZEDQA tw PASS walkie_premium: the full view button in the header
ZEDQA tw PASS walkie_premium: VOL pressed turns it on
ZEDQA tw PASS walkie_premium: the display reads while on
ZEDQA tw walkie_premium: display 101.200 | KNOXTALK RADIO | BAT 3
ZEDQA tw PASS walkie_premium: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_tactical: the Character window's Radio tab opens
ZEDQA tw PASS walkie_tactical: its own face, walkie_tactical (got walkie_tactical)
ZEDQA tw PASS walkie_tactical: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_tactical: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_tactical: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
ZEDQA tw PASS walkie_tactical: all 9 controls on the face (9)
ZEDQA tw PASS walkie_tactical: the full view button in the header
ZEDQA tw PASS walkie_tactical: VOL pressed turns it on
ZEDQA tw PASS walkie_tactical: the display reads while on
ZEDQA tw walkie_tactical: display 290.200 | | BAT 3
ZEDQA tw PASS walkie_tactical: BAT with 3 bars at 60% charge
ZEDQA tw PASS Tactical: MUTE silences it
ZEDQA tw PASS Tactical: MUTE again gives the sound back
ZEDQA tw PASS Tactical: SCAN runs
ZEDQA tw PASS Tactical: SCAN again stops it
ZEDQA tw PASS Tactical: LAMP lights the display
ZEDQA tw PASS Tactical: the lamp goes out after 5 s
ZEDQA tw PASS walkie_army: the Character window's Radio tab opens
ZEDQA tw PASS walkie_army: its own face, walkie_army (got walkie_army)
ZEDQA tw PASS walkie_army: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_army: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_army: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
ZEDQA tw PASS walkie_army: all 9 controls on the face (9)
ZEDQA tw PASS walkie_army: the full view button in the header
ZEDQA tw PASS walkie_army: VOL pressed turns it on
ZEDQA tw PASS walkie_army: the display reads while on
ZEDQA tw walkie_army: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | BAT 3
ZEDQA tw PASS walkie_army: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_makeshift: the Character window's Radio tab opens
ZEDQA tw PASS walkie_makeshift: its own face, walkie_makeshift (got walkie_makeshift)
ZEDQA tw PASS walkie_makeshift: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_makeshift: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_makeshift: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
ZEDQA tw PASS walkie_makeshift: all 6 controls on the face (6)
ZEDQA tw PASS walkie_makeshift: the full view button in the header
ZEDQA tw PASS walkie_makeshift: VOL pressed turns it on
ZEDQA tw PASS walkie_makeshift: the display reads while on
ZEDQA tw walkie_makeshift: display CH-- 98.40 | AUTOMATED EMERGENCY BROADCAST SYSTEM | nil nil
ZEDQA tw PASS makeshift: its character display reads CH.. (CH-- 98.40)
ZEDQA tw PASS walkie_manpack: the Character window's Radio tab opens
ZEDQA tw PASS walkie_manpack: its own face, walkie_manpack (got walkie_manpack)
ZEDQA tw PASS walkie_manpack: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_manpack: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_manpack: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
ZEDQA tw PASS walkie_manpack: all 7 controls on the face (7)
ZEDQA tw PASS walkie_manpack: the full view button in the header
ZEDQA tw PASS walkie_manpack: VOL pressed turns it on
ZEDQA tw PASS walkie_manpack: the display reads while on
ZEDQA tw walkie_manpack: display 098.000 | NNR RADIO | BAT 3
ZEDQA tw PASS walkie_manpack: BAT with 3 bars at 60% charge
ZEDQA tw PASS ManPack: on the back
ZEDQA tw PASS an AM/FM radio still shows the chassis
ZEDQA tw 7 free squares in reach
ZEDQA tw placed 3 ham sets
ZEDQA tw PASS the World window's Radio tab opens on the placed sets
ZEDQA tw PASS ham_civilian: its own face, ham_civilian (got ham_civilian)
ZEDQA tw PASS ham_civilian: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_civilian: centred across the drawer (x 20, want 20)
ZEDQA tw PASS ham_civilian: the drawer holds the whole set (840 px for 800)
ZEDQA tw PASS ham_civilian: all 8 controls on the face (8)
ZEDQA tw PASS ham_civilian: the full view button in the header
ZEDQA tw PASS ham_civilian: VOL pressed turns it on
ZEDQA tw ham_civilian: display 101.200 | KNOXTALK RADIO | range RANGE 7.5 KM
ZEDQA tw PASS ham_civilian: the display reads while on
ZEDQA tw PASS the drawer's clip is set and cleared in pairs with a ham showing (12 sets, 12 clears)
ZEDQA tw PASS civilian ham: RANGE matches its transmit range (RANGE 7.5 KM)
ZEDQA tw PASS civilian ham: the band marker follows the frequency up
ZEDQA tw PASS civilian ham: full view opens
ZEDQA tw PASS ham_civilian on a small screen: its narrow face (ham_civilian_n)
ZEDQA tw PASS ham_civilian: the tab is a walkie's width (465 px, want 465)
ZEDQA tw PASS ham_civilian: the narrow face at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_civilian: every control of the wide set on the narrow face (8)
ZEDQA tw PASS ham_civilian: VOL on the narrow face turns it on
ZEDQA tw PASS ham_civilian: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_civilian: the narrow face's display reads
ZEDQA tw PASS ham_army on a small screen: its narrow face (ham_army_n)
ZEDQA tw PASS ham_army: the tab is a walkie's width (465 px, want 465)
ZEDQA tw PASS ham_army: the narrow face at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_army: every control of the wide set on the narrow face (14)
ZEDQA tw PASS ham_army: VOL on the narrow face turns it on
ZEDQA tw PASS ham_army: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_army: the narrow face's display reads
ZEDQA tw PASS ham_makeshift on a small screen: its narrow face (ham_makeshift_n)
ZEDQA tw PASS ham_makeshift: the tab is a walkie's width (465 px, want 465)
ZEDQA tw PASS ham_makeshift: the narrow face at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_makeshift: every control of the wide set on the narrow face (7)
ZEDQA tw PASS ham_makeshift: VOL on the narrow face turns it on
ZEDQA tw PASS ham_makeshift: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_makeshift: the narrow face's display reads
ZEDQA tw PASS narrow makeshift ham: TALK / LISTEN flips with the mic
ZEDQA tw PASS with room again the wide set is back
ZEDQA tw PASS ham_army: its own face, ham_army (got ham_army)
ZEDQA tw PASS ham_army: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_army: centred across the drawer (x 20, want 20)
ZEDQA tw PASS ham_army: the drawer holds the whole set (840 px for 800)
ZEDQA tw PASS ham_army: all 14 controls on the face (14)
ZEDQA tw PASS ham_army: the full view button in the header
ZEDQA tw PASS ham_army: VOL pressed turns it on
ZEDQA tw ham_army: display 094.400 | | range RANGE 20 KM
ZEDQA tw PASS ham_army: the display reads while on
ZEDQA tw PASS army ham: tuned away
ZEDQA tw PASS army ham: 1 goes straight to memory 1
ZEDQA tw PASS army ham on the grid: AC, the bars dark (AC)
ZEDQA tw PASS ham_makeshift: its own face, ham_makeshift (got ham_makeshift)
ZEDQA tw PASS ham_makeshift: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_makeshift: centred across the drawer (x 20, want 20)
ZEDQA tw PASS ham_makeshift: the drawer holds the whole set (840 px for 800)
ZEDQA tw PASS ham_makeshift: all 7 controls on the face (7)
ZEDQA tw PASS ham_makeshift: the full view button in the header
ZEDQA tw PASS ham_makeshift: VOL pressed turns it on
ZEDQA tw ham_makeshift: display CH-- 042.200 MHZ | | range RANGE 6 KM
ZEDQA tw PASS ham_makeshift: the display reads while on
ZEDQA tw PASS makeshift ham: the TALK / LISTEN toggle flips with the mic
ZEDQA tw PASS makeshift ham: full view opens
ZEDQA tw PASS full view closes when the set is taken away
ZEDQA tw cleanup: 3 sets and 8 items taken away
ZEDQA tw 185 passed, 0 failed
ZEDQA tw all checks passed
ZEDQA tw DONE
```

### 12. zedqa_appliances.lua (`ZEDQA ap`) - PASS, 23 s

- go 14374 at 10:39:07
- screenshots: zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ap start
[ZeD.QA] run #12 ok=true
ZEDQA ap no room in reach of 12195,11828: to the Fossoil at West Point
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
ZEDQA ap pop-out 1208,756 1424x647, zoom 3 (the screen's 2)
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
ZEDQA ap back at 12195,11828
ZEDQA ap all checks passed
ZEDQA ap DONE
```

### 13. zedqa_seat_lightbar_vanilla.lua (`ZEDQA sl`) - PASS, 23 s

- go 14375 at 10:39:34
- screenshots: zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sl start
[ZeD.QA] run #13 ok=true
ZEDQA sl pickup=BaseVehicle{ Name:null, ID:18 } police=BaseVehicle{ Name:null, ID:19 } van=BaseVehicle{ Name:null, ID:20 }
ZEDQA sl enter Base.PickUpTruck dist=4.7 physics=true
ZEDQA sl enter Base.CarLightsKST dist=8.2 physics=false
ZEDQA sl lightbar x=1705 y=940 w=430 h=280
ZEDQA sl enter Base.VanSeats dist=8.0 physics=true
ZEDQA sl DONE
```

### 14. zedqa_car_radio_build.lua (`ZEDQA rb`) - PASS, 34 s

- go 14376 at 10:40:00
- screenshots: zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rb start
[ZeD.QA] run #14 ok=true
ZEDQA rb spawned Base.PickUpTruck beside the character
ZEDQA rb spawned Base.CarLightsPolice beside the character
ZEDQA rb Base.PickUpTruck radio=Base.RadioBlack
ZEDQA rb Base.CarLightsKST radio=Base.HamRadio1
ZEDQA rb dash only kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=93200 vol=1 preset=1 name=LBMW - Kentucky Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=89.4 Hitz FM; 5=94.2 USR]
ZEDQA rb prop visible=nil at nil,nil nilxnil vanilla window=false
ZEDQA rb premium off kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=93200 vol=1 preset=1 name=LBMW - Kentucky Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=89.4 Hitz FM; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb premium power via vanilla's action ok=true canBePoweredHere=true battery=0.8235299587249756
ZEDQA rb premium on kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=89.4 Hitz FM; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb store 4 -> 4
ZEDQA rb premium stored kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=STORE 4 mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb cds carried: 0
ZEDQA rb insert ok=true
ZEDQA rb cd in kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb play ok=false
ZEDQA rb cd playing kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb eject ok=false
ZEDQA rb ejected kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb fit Base.RadioBlack ok=true nil
ZEDQA rb valutech kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=98000 vol=0.6000000238418579 preset=2 name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb fit Base.RadioMakeShift ok=true nil
ZEDQA rb makeshift kind=makeshift item=Base.RadioMakeShift on=true switch=true powered=true ch=89400 vol=0.6000000238418579 preset=nil name=Hitz FM signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1536 880x256 vanilla window=false
ZEDQA rb fit Base.RadioBlack ok=true nil
ZEDQA rb pickup restored kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=89400 vol=0.6000000238418579 preset=nil name=Hitz FM signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=false at 1828,1536 880x256 vanilla window=false
ZEDQA rb ham power via vanilla's action ok=true canBePoweredHere=true battery=1
ZEDQA rb ham kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=2 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=107.6 Unknown Frequency; 2=98.4 Automated Emergency Broadcast System]
ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
ZEDQA rb ham mic off kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=2 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=true
ZEDQA rb presets [1=107.6 Unknown Frequency; 2=98.4 Automated Emergency Broadcast System]
ZEDQA rb prop visible=true at 1708,1466 1000x326 vanilla window=false
ZEDQA rb mem -> 3
ZEDQA rb ham mem kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=146600 vol=1 preset=3 name=nil signal=false media=false playing=false title=nil flash=CH 03 STORED mic=false
ZEDQA rb presets [1=107.6 Unknown Frequency; 2=98.4 Automated Emergency Broadcast System; 3=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
ZEDQA rb siren opened; radio still up = false
ZEDQA rb fit Base.HamRadio2 ok=true nil
ZEDQA rb army kind=army item=Base.HamRadio2 on=true switch=true powered=true ch=98400 vol=1 preset=2 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=107.6 Unknown Frequency; 2=98.4 Automated Emergency Broadcast System; 3=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1492 1000x300 vanilla window=false
ZEDQA rb fit Base.HamRadioMakeShift ok=true nil
ZEDQA rb hammake kind=hammake item=Base.HamRadioMakeShift on=true switch=true powered=true ch=98000 vol=1 preset=nil name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=107.6 Unknown Frequency; 2=98.4 Automated Emergency Broadcast System; 3=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1516 1000x276 vanilla window=false
ZEDQA rb fit Base.HamRadio1 ok=true nil
ZEDQA rb police restored kind=ham item=Base.HamRadio1 on=false switch=false powered=true ch=91200 vol=1 preset=nil name=Civilian Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=107.6 Unknown Frequency; 2=98.4 Automated Emergency Broadcast System]
ZEDQA rb prop visible=false at 1708,1516 1000x276 vanilla window=false
ZEDQA rb DONE
```

### 15. zedqa_car_radio_cd.lua (`ZEDQA cd`) - PASS, 12 s

- go 14377 at 10:40:37
- screenshots: zqa_cd_c01_cdlist.png, zqa_cd_c02_cd_playing.png, zqa_cd_c03_ejected.png, zqa_cd_c04_valutech_tape.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cd start
[ZeD.QA] run #15 ok=true
ZEDQA cd spawned Base.PickUpTruck beside the character
ZEDQA cd pickup BaseVehicle{ Name:null, ID:23 } radio=Base.RadioBlack
ZEDQA cd hand font height 17
ZEDQA cd vanilla CD recordings: 69
ZEDQA cd cd isRecordedMedia=true mediaType=0 name=CD: Philosophical Quotes - The Buddha
ZEDQA cd cds carried: 0
ZEDQA cd inserted kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
ZEDQA cd play ok=false
ZEDQA cd playing kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
ZEDQA cd eject ok=false
ZEDQA cd ejected kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
ZEDQA cd disc back in inventory: true
ZEDQA cd fit Base.RadioBlack
ZEDQA cd valutech kind=valutech on=false ch=98400 media=false playing=false title=nil cdMs=nil
ZEDQA cd fit Base.RadioRed
ZEDQA cd DONE
```

### 16. zedqa_dash_props_smoke.lua (`ZEDQA sm`) - PASS, 7 s

- go 14378 at 10:40:53
- screenshots: zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sm start
[ZeD.QA] run #16 ok=true
ZEDQA sm spawned Base.PickUpTruck beside the character
ZEDQA sm spawned Base.CarLightsPolice beside the character
ZEDQA sm pickup=true police=true
ZEDQA sm dash visible=true design=d6
ZEDQA sm radio up=true
ZEDQA sm siren up=true dash design=police
ZEDQA sm ham radio up=true
ZEDQA sm DONE
```

### 17. zedqa_tm.lua (`ZEDQA tm`) - PASS, 8 s

- go 14379 at 10:41:03
- screenshots: zedqa_tm_tooltips.png, zedqa_tm_maps.png, zedqa_tm_dash.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tm armed
[ZeD.QA] run #17 ok=true
ZEDQA tm root=1.75 proxy=true realTM=true
ZEDQA tm tip1 462.78125x223.7421875 at 300,300 desc=349.78125x136.59375 lines=4 font=MainMenu1
ZEDQA tm tip2 420x194.890625 at 300,620 desc=367x194.890625 lines=6 font=MainMenu1
ZEDQA tm watch family=nil size=228x52 at 3596,10
ZEDQA tm maps tab clicked maps
ZEDQA tm world tabs loot,craft,build,furniture,maps,forage,animals
ZEDQA tm maps shot active=maps win=1929,0 1694x735
ZEDQA tm dash design=horizon visible=true size=1600x344 at 1120,1804
ZEDQA tm done
```

### 18. zedqa_tour3.lua (`ZEDQA t3`) - PASS, 17 s

- go 14380 at 10:41:14
- screenshots: zedqa_t3_SmallCar02.png, zedqa_t3_ModernCar.png, zedqa_t3_ModernCar02.png, zedqa_t3_SUV.png, zedqa_t3_Van.png, zedqa_t3_PickUpVan.png, zedqa_t3_OffRoad.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #18 ok=true
ZEDQA t3 SmallCar02 design=horizon visible=true hits=21 badge=nil/nil cluster=nil
ZEDQA t3 ModernCar design=dashelite visible=true hits=29 badge=nil/nil cluster=nil
ZEDQA t3 ModernCar02 design=primani visible=true hits=26 badge=nil/nil cluster=nil
ZEDQA t3 SUV design=suv visible=true hits=22 badge=nil/nil cluster=nil
ZEDQA t3 Van design=van visible=true hits=21 badge=nil/nil cluster=nil
ZEDQA t3 PickUpVan design=bulldriver visible=true hits=22 badge=nil/nil cluster=nil
ZEDQA t3 OffRoad design=rancher visible=true hits=21 badge=nil/nil cluster=nil
ZEDQA t3 done
```

### 19. zedqa_dash19.lua (`ZEDQA dash`) - PASS, 77 s

- go 14381 at 10:41:35
- screenshots: zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #19 ok=true
ZEDQA dash 01_luxury design=luxury rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 02_nyala design=nyala rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 03_cossette design=cossette rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 04_police design=police rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 05_d6 design=d6 rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 06_dashelite design=dashelite rect=1120,1804,1600,344 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
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
ERROR: General f:30054 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"   (x2)
ZEDQA dash 19_race design=race rect=1120,1804,1600,344 running=false radio=false heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash DONE
```

### 20. zedqa_dashpx.lua (`ZEDQA dpx`) - PASS, 137 s

- go 14382 at 10:42:55
- screenshots: zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_07_primani_keyon.png, zqa_dashpx_07_primani.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png, zqa_dashpx_14_rancher.png, zqa_dashpx_15_taxi_keyon.png, zqa_dashpx_15_taxi.png, zqa_dashpx_16_ambulance_keyon.png, zqa_dashpx_16_ambulance.png, zqa_dashpx_17_fire_keyon.png, zqa_dashpx_17_fire.png, zqa_dashpx_18_ranger_keyon.png, zqa_dashpx_18_ranger.png, zqa_dashpx_19_race_keyon.png, zqa_dashpx_19_race.png, zqa_dashpx_20_knoxvan_keyon.png, zqa_dashpx_20_knoxvan.png, zqa_dashpx_21_fossoild6_keyon.png, zqa_dashpx_21_fossoild6.png, zqa_dashpx_23_meadesheriff_keyon.png, zqa_dashpx_23_meadesheriff.png, zqa_dashpx_24_lcpd_keyon.png, zqa_dashpx_24_lcpd.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #20 ok=true
ZEDQA dpx 01_luxury design=luxury rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=MERCIA LANG 4000 livery= make=MERCIA model=LANG 4000 unit=MERCIA - UNIT 84 hits=27 screen=3840x2160
ZEDQA dpx 02_nyala design=nyala rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER NYALA livery= make=CHEVALIER model=NYALA unit=CHEVALIER - UNIT 84 hits=22 screen=3840x2160
ZEDQA dpx 03_cossette design=cossette rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER COSSETTE livery= make=CHEVALIER model=COSSETTE unit=CHEVALIER - UNIT 84 hits=22 screen=3840x2160
ZEDQA dpx 04_police design=police rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=STATE TROOPER CHEVALIER NYALA livery=STATE TROOPER make=CHEVALIER model=NYALA unit=TROOPER - UNIT 84 hits=19 screen=3840x2160
ZEDQA dpx 05_d6 design=d6 rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER D6 livery= make=CHEVALIER model=D6 unit=CHEVALIER - UNIT 84 hits=22 screen=3840x2160
ZEDQA dpx 06_dashelite design=dashelite rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=DASH ELITE livery= make=DASH model=ELITE unit=DASH - UNIT 84 hits=29 screen=3840x2160
ZEDQA dpx 07_primani design=primani rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=CHEVALIER PRIMANI livery= make=CHEVALIER model=PRIMANI unit=CHEVALIER - UNIT 84 hits=26 screen=3840x2160
ZEDQA dpx 08_dart design=dart rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER DART livery= make=CHEVALIER model=DART unit=CHEVALIER - UNIT 84 hits=21 screen=3840x2160
ZEDQA dpx 09_horizon design=horizon rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=MASTERSON HORIZON livery= make=MASTERSON model=HORIZON unit=MASTERSON - UNIT 84 hits=21 screen=3840x2160
ZEDQA dpx 10_wagon design=wagon rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER CERISE WAGON livery= make=CHEVALIER model=CERISE WAGON unit=CHEVALIER - UNIT 84 hits=22 screen=3840x2160
ZEDQA dpx 11_suv design=suv rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=FRANKLIN ALL-TERRAIN livery= make=FRANKLIN model=ALL-TERRAIN unit=FRANKLIN - UNIT 84 hits=22 screen=3840x2160
ZEDQA dpx 12_van design=van rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=SPIFFO VAN livery=SPIFFO VAN make=FRANKLIN model=VALULINE unit=SPIFFO - UNIT 84 hits=21 screen=3840x2160
ZEDQA dpx 13_bulldriver design=bulldriver rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=DASH BULLDRIVER livery= make=DASH model=BULLDRIVER unit=DASH - UNIT 84 hits=22 screen=3840x2160
ZEDQA dpx 14_rancher design=rancher rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=DASH RANCHER livery= make=DASH model=RANCHER unit=DASH - UNIT 84 hits=25 screen=3840x2160
ZEDQA dpx 15_taxi design=taxi rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=TAXI livery=TAXI make=CHEVALIER model=NYALA unit=TAXI - CAB 84 hits=26 screen=3840x2160
ZEDQA dpx 16_ambulance design=ambulance rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=AMBULANCE livery=AMBULANCE make=FRANKLIN model=VALULINE unit=AMBULANCE - UNIT 84 hits=19 screen=3840x2160
ZEDQA dpx 17_fire design=fire rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=FIRE DEPARTMENT CHEVALIER D6 livery=FIRE DEPARTMENT make=CHEVALIER model=D6 unit=FIRE - ENGINE 84 hits=19 screen=3840x2160
ZEDQA dpx 18_ranger design=ranger rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=RANGER CHEVALIER NYALA livery=RANGER make=CHEVALIER model=NYALA unit=RANGER - UNIT 84 hits=19 screen=3840x2160
ERROR: General f:37704 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"   (x2)
ZEDQA dpx 19_race design=race rect=1120,1804,1600,344 k=2 running=true radio=false/nil heat=true lights=true name=RACE CAR livery=RACE CAR make=RACE model=CAR unit=RACE - UNIT 84 hits=5 screen=3840x2160
ZEDQA dpx 20_knoxvan design=van rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=KNOX DISTILLERY FRANKLIN VALULINE livery=KNOX DISTILLERY make=FRANKLIN model=VALULINE unit=KNOX - UNIT 84 hits=25 screen=3840x2160
ZEDQA dpx 21_fossoild6 design=d6 rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=CHEVALIER D6 livery= make=CHEVALIER model=D6 unit=CHEVALIER - UNIT 84 hits=19 screen=3840x2160
ZEDQA dpx 22_wreckednyala could not enter Base.CarNormalSmashedFront (enter=false seat0 installed=false)
ZEDQA dpx 23_meadesheriff design=police rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=MEADE SHERIFF DASH ELITE livery=MEADE SHERIFF make=DASH model=ELITE unit=SHERIFF - UNIT 84 hits=19 screen=3840x2160
ZEDQA dpx 24_lcpd design=police rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=LCPD CHEVALIER NYALA livery=LCPD make=CHEVALIER model=NYALA unit=LCPD - UNIT 84 hits=19 screen=3840x2160
ZEDQA dpx DONE
```

### 21. zedqa_exinfo.lua (`ZEDQA ex`) - PASS, 5 s

- go 14383 at 10:45:16
- screenshots: zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ex start
[ZeD.QA] run #21 ok=true
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
ZEDQA ex tab health true | shown squats | reserved 434.44921875 used 290.85546875 w 329
ZEDQA ex ok block follows the focused pill (squats)
ZEDQA ex ok room reserved
ZEDQA ex ok block follows the focused pill (barbell curl)
ZEDQA ex ok same reserved height for another exercise
ZEDQA ex ok time buttons keep the last started exercise
ZEDQA ex ok time buttons start nothing and change no choice
ZEDQA ex ok block follows the focused pill (burpees)
ZEDQA ex DONE
```

### 22. zedqa_charinfo.lua (`ZEDQA ci`) - PASS, 9 s

- go 14384 at 10:45:24

```text
[ZeD.QA] windows reset (R)
ZEDQA ci start
[ZeD.QA] run #22 ok=true
ZEDQA ci ZeD's Character window hook on: true | Mini Health Panel on: false
ZEDQA ci PASS the game's TOGGLE_HEALTH_PANEL key opens ZeD's health tab (tab health, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_SKILL_PANEL key opens ZeD's skills tab (tab skills, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_INFO_PANEL key opens ZeD's identity tab (tab identity, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_CLOTHING_PROTECTION_PANEL key opens ZeD's equip tab (tab equip, the game's window shown false)
ZEDQA ci PASS the same key again folds the tab (tab loot)
ZEDQA ci Mini Health Panel is off: its click is not checked
ZEDQA ci PASS with the windows shut, the click opens them on Health
ZEDQA ci PASS the windows are still
ZEDQA ci all checks passed
ZEDQA ci DONE
```

### 23. zedqa_equipdrag.lua (`ZEDQA eqd`) - PASS, 11 s

- go 14385 at 10:45:37
- screenshots: zqa_eqd_1.png, zqa_eqd_2.png, zqa_eqd_3.png, zqa_eqd_4.png

```text
[ZeD.QA] windows reset (R)
ZEDQA eqd start
[ZeD.QA] run #23 ok=true
ZEDQA eqd list slots {HAT,OUT,INR,GLV,PNT,SOC,BOT,PRI,BLT}
ZEDQA eqd worn {base:beltextra=HolsterSimple,base:belt=Belt2,base:hat=Hat_BaseballCapBlue,base:tanktop=Vest_DefaultTEXTURE_TINT,base:tshirt=Tshirt_DefaultTEXTURE,base:hands=Gloves_LeatherGloves,base:socks=Socks_Ankle,base:shoes=Shoes_ArmyBoots,base:pants=Trousers_Denim,base:jacket=Jacket_Varsity} cap Clothing{ clothingItemName="Hat_BaseballCapBlue" } jacket Clothing{ clothingItemName="Jacket_Varsity" } pri Base.Hammer:zombie.inventory.types.HandWeapon@42829348 | tab equip listExp true view list
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

### 24. zedqa_cazio_light.lua (`ZEDQA czl`) - PASS, 29 s

- go 14386 at 10:45:51
- screenshots: zqa_cl_day_DigitalBlack.png, zqa_cl_daylit_DigitalBlack.png, zqa_cl_night_DigitalBlack.png, zqa_cl_nightlit_DigitalBlack.png, zqa_cl_day_DigitalDress.png, zqa_cl_daylit_DigitalDress.png, zqa_cl_night_DigitalDress.png, zqa_cl_nightlit_DigitalDress.png, zqa_cl_day_ClassicBlack.png, zqa_cl_daylit_ClassicBlack.png, zqa_cl_night_ClassicBlack.png, zqa_cl_nightlit_ClassicBlack.png, zqa_cl_day_ClassicGold.png, zqa_cl_daylit_ClassicGold.png, zqa_cl_night_ClassicGold.png, zqa_cl_nightlit_ClassicGold.png, zqa_cl_belt_night.png, zqa_cl_belt_nightlit.png, zqa_cl_belt_day.png, zqa_cl_belt_daylit.png

```text
[ZeD.QA] windows reset (R)
ZEDQA czl start
[ZeD.QA] run #24 ok=true
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
ZEDQA czl timer pressed at 1793123171198
ZEDQA czl light out after 3020 ms; lit=false bulb=false dark=true
ZEDQA czl Expensive light control false
ZEDQA czl Expensive after a stray light press: lit=false bulb=false dark=true
ZEDQA czl belt watch box 1
ZEDQA czl belt mini after Y: lit=true night=true dark=false
ZEDQA czl restored own watch nil
ZEDQA czl DONE
```

### 25. zedqa_dashnight.lua (`ZEDQA dnt`) - PASS, 105 s

- go 14387 at 10:46:23
- screenshots: zqa_dashnight_wagon_real.png, zqa_dashnight_wagon_day.png, zqa_dashnight_wagon_dusk.png, zqa_dashnight_wagon_night.png, zqa_dashnight_wagon_nightoff.png, zqa_dashnight_wagon_real_noon.png, zqa_dashnight_wagon_real_back_on.png, zqa_dashnight_wagon_real_back_off.png, zqa_dashnight_nyala_real.png, zqa_dashnight_nyala_day.png, zqa_dashnight_nyala_dusk.png, zqa_dashnight_nyala_night.png, zqa_dashnight_nyala_nightoff.png, zqa_dashnight_dashelite_real.png, zqa_dashnight_dashelite_day.png, zqa_dashnight_dashelite_dusk.png, zqa_dashnight_dashelite_night.png, zqa_dashnight_dashelite_nightoff.png, zqa_dashnight_luxury_real.png, zqa_dashnight_luxury_day.png, zqa_dashnight_luxury_dusk.png, zqa_dashnight_luxury_night.png, zqa_dashnight_luxury_nightoff.png, zqa_dashnight_ambulance_real.png, zqa_dashnight_ambulance_day.png, zqa_dashnight_ambulance_dusk.png, zqa_dashnight_ambulance_night.png, zqa_dashnight_ambulance_nightoff.png, zqa_dashnight_race_real.png, zqa_dashnight_race_day.png, zqa_dashnight_race_dusk.png, zqa_dashnight_race_night.png, zqa_dashnight_race_nightoff.png, zqa_dashnight_d6_real.png, zqa_dashnight_d6_day.png, zqa_dashnight_d6_dusk.png, zqa_dashnight_d6_night.png, zqa_dashnight_d6_nightoff.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #25 ok=true
ZEDQA dnt wagon real design=wagon lux=0.200 smooth=0.206 n8=8 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=23.81
ZEDQA dnt wagon day design=wagon lux=0.192 smooth=0.202 n8=0 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=23.82
ZEDQA dnt wagon dusk design=wagon lux=0.192 smooth=0.197 n8=4 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=23.82
ZEDQA dnt wagon night design=wagon lux=0.192 smooth=0.194 n8=8 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=23.82
ZEDQA dnt wagon nightoff design=wagon lux=0.184 smooth=0.190 n8=8 lit=false over=dash_wagon_dark lights=true dashLit=true k=2 hour=23.83
ZEDQA dnt wagon real_noon design=wagon lux=1.000 smooth=0.998 n8=0 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=13.03
ZEDQA dnt wagon real_back_on design=wagon lux=0.192 smooth=0.198 n8=8 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=23.82
ZEDQA dnt wagon real_back_off design=wagon lux=0.184 smooth=0.190 n8=8 lit=false over=dash_wagon_dark lights=false dashLit=false k=2 hour=23.83
ZEDQA dnt nyala real design=nyala lux=0.090 smooth=0.091 n8=8 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=23.85
ZEDQA dnt nyala day design=nyala lux=0.090 smooth=0.091 n8=0 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=23.86
ZEDQA dnt nyala dusk design=nyala lux=0.082 smooth=0.090 n8=4 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=23.86
ZEDQA dnt nyala night design=nyala lux=0.082 smooth=0.086 n8=8 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=23.86
ZEDQA dnt nyala nightoff design=nyala lux=0.082 smooth=0.084 n8=8 lit=false over=dash_nyala_dark lights=true dashLit=true k=2 hour=23.87
ZEDQA dnt dashelite real design=dashelite lux=0.165 smooth=0.164 n8=8 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=23.89
ZEDQA dnt dashelite day design=dashelite lux=0.165 smooth=0.164 n8=0 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=23.90
ZEDQA dnt dashelite dusk design=dashelite lux=0.165 smooth=0.165 n8=4 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=23.90
ZEDQA dnt dashelite night design=dashelite lux=0.165 smooth=0.165 n8=8 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=23.90
ZEDQA dnt dashelite nightoff design=dashelite lux=0.165 smooth=0.165 n8=8 lit=false over=dash_dashelite_dark lights=true dashLit=true k=2 hour=23.91
ZEDQA dnt luxury real design=luxury lux=0.161 smooth=0.159 n8=8 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=23.93
ZEDQA dnt luxury day design=luxury lux=0.161 smooth=0.160 n8=0 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=23.93
ZEDQA dnt luxury dusk design=luxury lux=0.161 smooth=0.160 n8=4 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=23.94
ZEDQA dnt luxury night design=luxury lux=0.161 smooth=0.161 n8=8 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=23.94
ZEDQA dnt luxury nightoff design=luxury lux=0.161 smooth=0.161 n8=8 lit=false over=dash_luxury_dark lights=true dashLit=true k=2 hour=23.95
ZEDQA dnt ambulance real design=ambulance lux=0.161 smooth=0.160 n8=8 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=23.97
ZEDQA dnt ambulance day design=ambulance lux=0.161 smooth=0.160 n8=0 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=23.98
ZEDQA dnt ambulance dusk design=ambulance lux=0.161 smooth=0.161 n8=4 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=23.98
ZEDQA dnt ambulance night design=ambulance lux=0.161 smooth=0.161 n8=8 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=23.98
ZEDQA dnt ambulance nightoff design=ambulance lux=0.161 smooth=0.161 n8=8 lit=false over=dash_ambulance_dark lights=true dashLit=true k=2 hour=23.99
ERROR: General f:49729 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:49732 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dnt race real design=race lux=0.161 smooth=0.161 n8=8 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=0.02
ZEDQA dnt race day design=race lux=0.161 smooth=0.161 n8=0 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=0.02
ZEDQA dnt race dusk design=race lux=0.161 smooth=0.161 n8=4 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=0.02
ZEDQA dnt race night design=race lux=0.161 smooth=0.161 n8=8 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=0.03
ZEDQA dnt race nightoff design=race lux=0.161 smooth=0.161 n8=8 lit=false over=dash_race_dark lights=true dashLit=true k=2 hour=0.03
ZEDQA dnt d6 real design=d6 lux=0.161 smooth=0.161 n8=8 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=0.06
ZEDQA dnt d6 day design=d6 lux=0.161 smooth=0.161 n8=0 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=0.06
ZEDQA dnt d6 dusk design=d6 lux=0.161 smooth=0.161 n8=4 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=0.07
ZEDQA dnt d6 night design=d6 lux=0.161 smooth=0.161 n8=8 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=0.07
ZEDQA dnt d6 nightoff design=d6 lux=0.161 smooth=0.161 n8=8 lit=false over=dash_d6_dark lights=true dashLit=true k=2 hour=0.07
ZEDQA dnt DONE
```

### 26. zedqa_testlang.lua (`ZEDQA tlang`) - PASS, 79 s

- go 14388 at 10:48:11
- screenshots: zqa_tl_01_char_loot_list.png, zqa_tl_02_char_loot_grid.png, zqa_tl_03_card_food.png, zqa_tl_04_card_weapon.png, zqa_tl_05_card_bottle.png, zqa_tl_06_card_gun.png, zqa_tl_07_char_equip_list.png, zqa_tl_08_char_equip_doll.png, zqa_tl_09_char_health.png, zqa_tl_10_char_thermal_1.png, zqa_tl_11_char_thermal_2.png, zqa_tl_12_char_thermal_3.png, zqa_tl_13_char_thermal_4.png, zqa_tl_14_char_thermal_5.png, zqa_tl_15_char_thermal_6.png, zqa_tl_16_char_thermal_7.png, zqa_tl_17_char_thermal_figure.png, zqa_tl_18_char_identity.png, zqa_tl_19_char_journal_1.png, zqa_tl_20_char_journal_2.png, zqa_tl_21_char_journal_3.png, zqa_tl_22_char_journal_4.png, zqa_tl_23_char_skills.png, zqa_tl_24_char_radio.png, zqa_tl_25_char_loot_back.png, zqa_tl_26_ctx_strip_food.png, zqa_tl_27_ctx_strip_weapon.png, zqa_tl_28_ctx_list_food.png, zqa_tl_29_ctx_list_submenu.png, zqa_tl_30_world_loot.png, zqa_tl_31_world_craft_list.png, zqa_tl_32_world_craft_recipe.png, zqa_tl_33_world_build_list.png, zqa_tl_34_world_build_recipe.png, zqa_tl_35_world_furniture.png, zqa_tl_36_world_furniture_rotate.png, zqa_tl_37_world_furniture_scrap.png, zqa_tl_38_world_furniture_repair.png, zqa_tl_39_world_furniture_pickup.png, zqa_tl_40_world_maps.png, zqa_tl_41_world_maps_survey.png, zqa_tl_42_world_maps_color.png, zqa_tl_43_world_maps_paper.png, zqa_tl_44_world_forage.png, zqa_tl_45_world_animals.png, zqa_tl_46_belt_watch_tucked.png, zqa_tl_47_belt_watch_popped.png, zqa_tl_48_watch_corner.png, zqa_tl_49_actionbar_reading_verbose.png, zqa_tl_50_actionbar_reading_simple.png, zqa_tl_51_wheel_emotes.png, zqa_tl_52_wheel_vehicle_outside.png, zqa_tl_53_prompt_question.png, zqa_tl_54_prompt_textbox.png, zqa_tl_55_prompt_textbox_empty.png, zqa_tl_56_prompt_keyboard.png, zqa_tl_57_prompt_alarm.png, zqa_tl_58_prompt_timer.png, zqa_tl_59_prompt_help.png, zqa_tl_60_prompt_rich_question.png, zqa_tl_61_safe_note.png, zqa_tl_62_pause_menu.png, zqa_tl_63_options_1_zed.png, zqa_tl_64_options_2_display.png, zqa_tl_65_options_3_graphics.png, zqa_tl_66_options_4_audio.png, zqa_tl_67_options_5_controls.png, zqa_tl_68_options_6_gameplay.png, zqa_tl_69_options_7_interface.png, zqa_tl_70_options_8_access.png, zqa_tl_71_options_9_mods.png, zqa_tl_72_pause_mods.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tlang start (209 steps)
[ZeD.QA] run #26 ok=true
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

### 27. zedqa_safemode.lua (`ZEDQA safe`) - PASS, 11 s

- go 14389 at 10:49:33
- screenshots: zqa_safe_1.png, zqa_safe_2.png, zqa_safe_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA safe start
[ZeD.QA] run #27 ok=true
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
ZEDQA safe option On picked up by the poll: picked up after 361 ms
ZEDQA safe ok option On picked up by the poll
ZEDQA safe option on: on true | pair false/false | vanilla inv true | hotbar vanilla | clock y 10 visible false | speed y 10 | moodle layer false
ZEDQA safe ok option on
ZEDQA safe option Off picked up by the poll: picked up after 471 ms
ZEDQA safe ok option Off picked up by the poll
ZEDQA safe option off: on false | pair false/false | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok option off
ZEDQA safe burst: 5 ticks, still off after 2502 ms
ZEDQA safe ok watchdog: a five-frame burst leaves ZeD on
ZEDQA safe streak: tripped after 2007 ms, 238 frames, longest gap 14 ms
ZEDQA safe ok watchdog: below two seconds of failures ZeD stays on
ZEDQA safe ok watchdog: two seconds of failures every frame trip it
ZEDQA safe ok watchdog note shows and closes
ZEDQA safe restored: on false | pair true/true | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok restored
ZEDQA safe DONE
```

### 28. zedqa_soak.lua (`ZEDQA soak`) - PASS, 655 s

- go 14390 at 10:49:47

```text
[ZeD.QA] windows reset (R)
ZEDQA soak start ui 37
[ZeD.QA] run #28 ok=true
ZEDQA soak round 1 avg 13.30 ms worst 83 ms ui 38 (start 37) hours 0.2
ZEDQA soak round 2 avg 13.38 ms worst 52 ms ui 38 (start 37) hours 0.5
ZEDQA soak round 3 avg 13.09 ms worst 50 ms ui 38 (start 37) hours 0.7
ZEDQA soak round 4 avg 13.02 ms worst 46 ms ui 38 (start 37) hours 1.0
ZEDQA soak round 5 avg 12.83 ms worst 48 ms ui 38 (start 37) hours 1.2
ZEDQA soak round 6 avg 13.05 ms worst 49 ms ui 38 (start 37) hours 1.4
ZEDQA soak round 7 avg 12.80 ms worst 44 ms ui 38 (start 37) hours 1.7
ZEDQA soak round 8 avg 12.74 ms worst 44 ms ui 38 (start 37) hours 1.9
ZEDQA soak round 9 avg 12.69 ms worst 43 ms ui 38 (start 37) hours 2.1
ZEDQA soak round 10 avg 12.70 ms worst 47 ms ui 38 (start 37) hours 2.3
ZEDQA soak round 11 avg 16.51 ms worst 70 ms ui 38 (start 37) hours 2.6
ZEDQA soak round 12 avg 13.92 ms worst 134 ms ui 38 (start 37) hours 2.9
ZEDQA soak DONE
```

### 29. zedqa_hands_together.lua (`ZEDQA ht`) - PASS, 11 s

- go 14391 at 11:00:46
- screenshots: zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ht start
[ZeD.QA] run #29 ok=true
ZEDQA ht 01 two items | OFF@0/77 MAIN@88/98 #1@204/77 #2@300/77 #3@396/77 #4@639/77 | dark small | belt x1343 y2034 w737 h98
ZEDQA ht PASS 01 two items: both hands are on the belt
ZEDQA ht PASS 01 two items: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 01 two items: the off hand comes before the main hand
ZEDQA ht PASS 01 two items: the hands sit before the slots (the left end)
ZEDQA ht PASS 01 two items: the boxes run left to right
ZEDQA ht PASS 01 two items: the hands are 6 units apart (11 px)
ZEDQA ht PASS 01 two items: a click at the off hand's right edge finds the off hand
ZEDQA ht 02 both hands | off(peek)@0/77 MAIN@25/98 #1@141/77 #2@237/77 #3@333/77 #4@576/77 | dark small | belt x1406 y2034 w674 h98
ZEDQA ht PASS 02 both hands: both hands are on the belt
ZEDQA ht PASS 02 both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 02 both hands: the off hand comes before the main hand
ZEDQA ht PASS 02 both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 02 both hands: the boxes run left to right
ZEDQA ht PASS 02 both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 02 both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 02 both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 02 both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 02 both hands: slot 1 stays in place on screen (1547, was 1547)
ZEDQA ht 03 both, high contrast | off(peek)@0/77 MAIN@25/98 #1@141/77 #2@237/77 #3@333/77 #4@576/77 | hicon small | belt x1406 y2034 w674 h98
ZEDQA ht PASS 03 both, high contrast: both hands are on the belt
ZEDQA ht PASS 03 both, high contrast: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 03 both, high contrast: the off hand comes before the main hand
ZEDQA ht PASS 03 both, high contrast: the hands sit before the slots (the left end)
ZEDQA ht PASS 03 both, high contrast: the boxes run left to right
ZEDQA ht PASS 03 both, high contrast: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 03 both, high contrast: the crescent's mark is 44 px wide
ZEDQA ht PASS 03 both, high contrast: a click at the crescent finds the off hand
ZEDQA ht PASS 03 both, high contrast: a click where the two overlap finds the main hand
ZEDQA ht 04 both, large | off(peek)@0/89 MAIN@28/113 #1@161/89 #2@272/89 #3@383/89 #4@644/89 | dark large | belt x1338 y2015 w757 h113
ZEDQA ht PASS 04 both, large: both hands are on the belt
ZEDQA ht PASS 04 both, large: the main hand is 56 units, the off hand 44 (113, 89 px; 56u = 113)
ZEDQA ht PASS 04 both, large: the off hand comes before the main hand
ZEDQA ht PASS 04 both, large: the hands sit before the slots (the left end)
ZEDQA ht PASS 04 both, large: the boxes run left to right
ZEDQA ht PASS 04 both, large: the off hand peeks 14 units from under the main hand (28 px)
ZEDQA ht PASS 04 both, large: the crescent's mark is 50 px wide
ZEDQA ht PASS 04 both, large: a click at the crescent finds the off hand
ZEDQA ht PASS 04 both, large: a click where the two overlap finds the main hand
ZEDQA ht pad two items | OFF@0/77 MAIN@88/98 #1@204/77 #2@300/77 #3@396/77 #4@639/77 | dark small | belt x1343 y2034 w737 h98
ZEDQA ht PASS pad two items: both hands are on the belt
ZEDQA ht PASS pad two items: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS pad two items: the off hand comes before the main hand
ZEDQA ht PASS pad two items: the hands sit before the slots (the left end)
ZEDQA ht PASS pad two items: the boxes run left to right
ZEDQA ht PASS pad two items: the hands are 6 units apart (11 px)
ZEDQA ht PASS pad two items: a click at the off hand's right edge finds the off hand
ZEDQA ht PASS pad: the belt starts on slot 1 (#1)
ZEDQA ht PASS pad: Left from slot 1 is the main hand (MAIN)
ZEDQA ht PASS pad: Left again is the off hand (OFF)
ZEDQA ht 05 left wrist, both hands | watch@0/88 off(peek)@102/77 MAIN@127/98 #1@243/77 #2@339/77 #3@435/77 #4@678/77 | dark small | belt x1304 y2034 w776 h98
ZEDQA ht PASS 05 left wrist, both hands: both hands are on the belt
ZEDQA ht PASS 05 left wrist, both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 05 left wrist, both hands: the off hand comes before the main hand
ZEDQA ht PASS 05 left wrist, both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 05 left wrist, both hands: the boxes run left to right
ZEDQA ht PASS 05 left wrist, both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 05 left wrist, both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 05 left wrist, both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 05 left wrist, both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 05 left wrist, both hands: slot 1 stays in place on screen (1547, was 1547)
ZEDQA ht PASS 05: the left-wrist watch sits beside the peeking off hand
ZEDQA ht 06 right wrist, pistol | OFF@0/77 MAIN@88/98 ammo@137/255 watch@406/88 #1@512/77 #2@608/77 #3@704/77 #4@947/77 | dark small | belt x1035 y2034 w1045 h98
ZEDQA ht PASS 06 right wrist, pistol: both hands are on the belt
ZEDQA ht PASS 06 right wrist, pistol: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 06 right wrist, pistol: the off hand comes before the main hand
ZEDQA ht PASS 06 right wrist, pistol: the hands sit before the slots (the left end)
ZEDQA ht PASS 06 right wrist, pistol: the boxes run left to right
ZEDQA ht PASS 06 right wrist, pistol: the hands are 6 units apart (11 px)
ZEDQA ht PASS 06 right wrist, pistol: a click at the off hand's right edge finds the off hand
ZEDQA ht PASS 06: the ammo tab comes after the main hand
ZEDQA ht PASS 06: the tab starts under the main hand's middle, its words at the circle's edge (x137 cx186)
ZEDQA ht PASS 06: no strap under the ammo tab
ZEDQA ht PASS 06: a click on the circle over the tab finds the main hand
ZEDQA ht PASS 06: a click on the tab's words finds the tab
ZEDQA ht PASS 06: the right-wrist watch is outside the tab, before the strap
ZEDQA ht PASS 06: the full watch opens to the right of the small one (left)
ZEDQA ht 06 ammo 12/15 chambered true | 12+1
ZEDQA ht 08 empty pistol | OFF@0/77 MAIN@88/98 ammo@137/255 #1@410/77 #2@506/77 #3@602/77 #4@845/77 | dark small | belt x1137 y2034 w943 h98
ZEDQA ht PASS 08 empty pistol: both hands are on the belt
ZEDQA ht PASS 08 empty pistol: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 08 empty pistol: the off hand comes before the main hand
ZEDQA ht PASS 08 empty pistol: the hands sit before the slots (the left end)
ZEDQA ht PASS 08 empty pistol: the boxes run left to right
ZEDQA ht PASS 08 empty pistol: the hands are 6 units apart (11 px)
ZEDQA ht PASS 08 empty pistol: a click at the off hand's right edge finds the off hand
ZEDQA ht PASS 08: the ammo tab comes after the main hand
ZEDQA ht PASS 08: the tab starts under the main hand's middle, its words at the circle's edge (x137 cx186)
ZEDQA ht PASS 08: no strap under the ammo tab
ZEDQA ht PASS 08: a click on the circle over the tab finds the main hand
ZEDQA ht PASS 08: a click on the tab's words finds the tab
ZEDQA ht 09 shotgun, both hands | off(peek)@0/77 MAIN@25/98 ammo@74/255 #1@347/77 #2@443/77 #3@539/77 #4@782/77 | dark small | belt x1200 y2034 w880 h98
ZEDQA ht PASS 09 shotgun, both hands: both hands are on the belt
ZEDQA ht PASS 09 shotgun, both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 09 shotgun, both hands: the off hand comes before the main hand
ZEDQA ht PASS 09 shotgun, both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 09 shotgun, both hands: the boxes run left to right
ZEDQA ht PASS 09 shotgun, both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 09 shotgun, both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 09 shotgun, both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 09 shotgun, both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 09 shotgun, both hands: slot 1 stays in place on screen (1547, was 1547)
ZEDQA ht PASS 09: the ammo tab comes after the main hand
ZEDQA ht PASS 09: the tab starts under the main hand's middle, its words at the circle's edge (x74 cx123)
ZEDQA ht PASS 09: no strap under the ammo tab
ZEDQA ht PASS 09: a click on the circle over the tab finds the main hand
ZEDQA ht PASS 09: a click on the tab's words finds the tab
ZEDQA ht 07 off hand x1406 y2044 s77 peekW 44
ZEDQA ht all checks passed
ZEDQA ht DONE
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
```
