# ZeD-UI regression - 2026-10-27 01:05 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-27 01:05:11 |
| Finished | 2026-10-27 01:28:06 (22 min 55 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_full_2b.txt (46 scripts) |
| Result | **33/46 pass**, 2 warn, 3 fail, 0 timeout, 8 not run |
| Go numbers | 14041 to 14080 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- console.txt restarted at 01:27:24 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- stopped after zedqa_dashpx.lua: the game dropped to the main menu during this script
- quit: quit to the main menu, then to the desktop (go 14079, 14080)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 45 |  |  |
| 2 | zedqa_print_fit.lua | pf | PASS | 15 | zqa_pf_1a_KnoxKnews_July1_vanilla.png, zqa_pf_1b_KnoxKnews_July1_fitted.png, zqa_pf_2a_KnoxKnews_July2_vanilla.png, zqa_pf_2b_KnoxKnews_July2_fitted.png, zqa_pf_3a_KentuckyHerald_July6_vanilla.png, zqa_pf_3b_KentuckyHerald_July6_fitted.png, zqa_pf_4a_NationalDispatch_July6_vanilla.png, zqa_pf_4b_NationalDispatch_July6_fitted.png |  |
| 3 | zedqa_print_typeset.lua | ts | PASS | 7 | zqa_ts_1_KnoxKnews_July1.png, zqa_ts_2_KnoxKnews_July2.png, zqa_ts_3_KentuckyHerald_July6.png, zqa_ts_4_NationalDispatch_July6.png |  |
| 4 | zedqa_prompts.lua | pr | PASS | 32 | zqa_pr_01_sleep.png, zqa_pr_02_kill.png, zqa_pr_03_note.png, zqa_pr_04_rename.png, zqa_pr_05_rename_empty.png, zqa_pr_06_keyboard.png, zqa_pr_07_alarm.png, zqa_pr_08_timer.png, zqa_pr_09_help.png, zqa_pr_10_rich_question.png, zqa_pr_11_gp_question.png, zqa_pr_12_gp_question_no.png, zqa_pr_13_gp_kill.png, zqa_pr_14_gp_text.png, zqa_pr_15_gp_keyboard.png, zqa_pr_16_gp_alarm.png |  |
| 5 | zedqa_fishing.lua | fi | PASS | 8 | zqa_fi_1_slack.png, zqa_fi_2_light.png, zqa_fi_3_tight.png, zqa_fi_4_strain.png, zqa_fi_5_limit.png |  |
| 6 | zedqa_props_plates.lua | props | PASS | 3 | zqa_props_1.png, zqa_props_2.png, zqa_props_3.png |  |
| 7 | zedqa_belt_strap.lua | belt | PASS | 2 | zqa_belt_strap_1.png |  |
| 8 | zedqa_straps.lua | straps | PASS | 12 | zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png |  |
| 9 | zedqa_buckle.lua | bk | PASS | 5 | zqa_bk_1.png, zqa_bk_2.png, zqa_bk_3.png |  |
| 10 | zedqa_buckles.lua | bks | PASS | 45 | zqa_bk_01_burgerflipper.png, zqa_bk_02_repairman.png, zqa_bk_03_burglar.png, zqa_bk_04_engineer.png, zqa_bk_05_fisherman.png, zqa_bk_06_policeofficer.png, zqa_bk_07_lumberjack.png, zqa_bk_08_smither.png, zqa_bk_09_farmer.png, zqa_bk_10_electrician.png, zqa_bk_11_fireofficer.png, zqa_bk_12_metalworker.png, zqa_bk_13_fitnessinstructor.png, zqa_bk_14_veteran.png, zqa_bk_15_tailor.png, zqa_bk_16_chef.png, zqa_bk_17_doctor.png, zqa_bk_18_parkranger.png, zqa_bk_19_unemployed.png, zqa_bk_20_nurse.png, zqa_bk_21_securityguard.png, zqa_bk_22_carpenter.png, zqa_bk_23_mechanics.png, zqa_bk_24_rancher.png, zqa_bk_25_constructionworker.png, zqa_bk_26_priest.png, zqa_bk_27_soldier.png, zqa_bk_28_mailman.png, zqa_bk_29_ascetic.png, zqa_bk_30_paramedic.png, zqa_bk_31_hunter.png, zqa_bk_32_convict.png |  |
| 11 | zedqa_beltwatch.lua | bw | PASS | 13 | zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png |  |
| 12 | zedqa_belt_hands.lua | bh | PASS | 4 | zqa_bh_1_left_wrist.png, zqa_bh_2_right_wrist.png |  |
| 13 | zedqa_watches2.lua | watches | PASS | 28 | zqa_watch_day_DigitalBlack.png, zqa_watch_day_DigitalDress.png, zqa_watch_day_DigitalRed.png, zqa_watch_day_DigitalTimez.png, zqa_watch_day_ClassicBlack.png, zqa_watch_day_ClassicGold.png, zqa_watch_day_ClassicBrown.png, zqa_watch_day_ClassicMilitary.png, zqa_watch_day_Expensive.png, zqa_watch_set_DigitalBlack.png, zqa_watch_night_DigitalBlack.png, zqa_watch_night_DigitalTimez.png, zqa_watch_lit_DigitalTimez.png, zqa_watch_night_ClassicBrown.png, zqa_watch_lit_ClassicBrown.png, zqa_watch_night_Expensive.png |  |
| 14 | zedqa_container_bottom.lua | cb | PASS | 11 | zqa_cb_01_rows_at_bottom.png, zqa_cb_02_list_end.png, zqa_cb_03_pad_take_all.png, zqa_cb_04_campfire_ribbon.png |  |
| 15 | zedqa_container_controls.lua | ct | PASS | 20 | zqa_ct_01_rows.png, zqa_ct_02_pad_same_type.png, zqa_ct_03_after_take_all.png, zqa_ct_04_floor_row.png, zqa_ct_05_campfire_row.png, zqa_ct_06_add_fuel_card.png |  |
| 16 | zedqa_container_controls_captures.lua | cc | PASS | 7 | zqa_cc_zed_truckbed.png, zqa_cc_vanilla_truckbed.png |  |
| 17 | zedqa_button_case_game.lua | bg | PASS | 19 | zqa_bg_01_item_card.png, zqa_bg_02_health.png, zqa_bg_03_thermal.png, zqa_bg_04_animals.png, zqa_bg_05_forage.png, zqa_bg_06_craft.png, zqa_bg_07_vehicle.png |  |
| 18 | zedqa_wheel_sizes.lua | ws | PASS | 19 | zqa_ws_a_gun3.png, zqa_ws_b_dright3.png, zqa_ws_c_emotes5.png, zqa_ws_d_signal9.png, zqa_ws_e_back10.png, zqa_ws_g_car11.png, zqa_ws_h_car11pt.png |  |
| 19 | zedqa_wheels.lua | wh | PASS | 31 | zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png |  |
| 20 | zedqa_dpad_wheels.lua | dw | PASS | 53 | zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png |  |
| 21 | zedqa_pad_glyphs.lua | pg | PASS | 36 | zqa_pg_footer_ps.png, zqa_pg_wheel_ps.png, zqa_pg_footer_xbox.png, zqa_pg_wheel_xbox.png, zqa_pg_footer_deck.png, zqa_pg_wheel_deck.png, zqa_pg_footer_nintendo.png, zqa_pg_wheel_nintendo.png, zqa_pg_footer_kbm.png, zqa_pg_wheel_kbm.png, zqa_pg_footer_ps_light.png, zqa_pg_wheel_ps_light.png, zqa_pg_footer_ps_hicon.png, zqa_pg_wheel_ps_hicon.png |  |
| 22 | zedqa_quick_chords.lua | qc | WARN | 25 | zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png | 1 ERR line(s) |
| 23 | zedqa_put_back.lua | pb | PASS | 34 |  |  |
| 24 | zedqa_food_verbs.lua | fv | PASS | 4 | zqa_fv_smoking.png |  |
| 25 | zedqa_messages.lua | msg | WARN | 11 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=); 1 ERR line(s) |
| 26 | zedqa_moodles.lua | mood | PASS | 20 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png |  |
| 27 | zedqa_ring_squares.lua | rs | PASS | 12 | zqa_rs_belt_full.png, zqa_rs_belt_70_45.png, zqa_rs_belt_15.png, zqa_rs_squares_on.png, zqa_rs_squares_off.png |  |
| 28 | zedqa_sandbox_ig.lua | sbx | PASS | 19 | zqa_sbx_pause_line.png, zqa_sbx_time.png, zqa_sbx_world_help.png, zqa_sbx_zombie_changed.png, zqa_sbx_ask_apply.png, zqa_sbx_applied.png, zqa_sbx_history.png, zqa_sbx_pad.png |  |
| 29 | zedqa_twoway.lua | tw | PASS | 52 | zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png |  |
| 30 | zedqa_appliances.lua | ap | PASS | 27 | zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png |  |
| 31 | zedqa_seat_lightbar_vanilla.lua | sl | **FAIL** | 22 | zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png | 2 Java exception(s) in the log |
| 32 | zedqa_car_radio_build.lua | rb | PASS | 35 | zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png |  |
| 33 | zedqa_car_radio_cd.lua | cd | PASS | 16 | zqa_cd_c01_cdlist.png, zqa_cd_c02_cd_playing.png, zqa_cd_c03_ejected.png, zqa_cd_c04_valutech_tape.png |  |
| 34 | zedqa_dash_props_smoke.lua | sm | PASS | 9 | zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png |  |
| 35 | zedqa_tm.lua | tm | PASS | 8 | zedqa_tm_tooltips.png, zedqa_tm_maps.png, zedqa_tm_dash.png |  |
| 36 | zedqa_tour3.lua | t3 | PASS | 19 | zedqa_t3_SmallCar02.png, zedqa_t3_ModernCar.png, zedqa_t3_ModernCar02.png, zedqa_t3_SUV.png, zedqa_t3_Van.png, zedqa_t3_PickUpVan.png, zedqa_t3_OffRoad.png |  |
| 37 | zedqa_dash19.lua | dash | **FAIL** | 106 | zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png | 4 Java exception(s) in the log; 2 ERR line(s) |
| 38 | zedqa_dashpx.lua | dpx | **FAIL** | 102 | zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png | 49 Java exception(s) in the log; 2 ERR line(s); the script ran twice (re-bump); late output from pre (4 line(s), not counted); late output from pf (11 line(s), not counted); late output from ts (6 line(s), not counted); late output from pr (40 line(s), not counted); late output from fi (7 line(s), not counted); late output from props (2 line(s), not counted); late output from belt (2 line(s), not counted); late output from straps (17 line(s), not counted); late output from bk (7 line(s), not counted); late output from bks (35 line(s), not counted); late output from bw (10 line(s), not counted); late output from bh (18 line(s), not counted); late output from watches (20 line(s), not counted); late output from cb (6 line(s), not counted); late output from ct (34 line(s), not counted); late output from cc (8 line(s), not counted); late output from bg (5 line(s), not counted); late output from ws (9 line(s), not counted); late output from wh (17 line(s), not counted); late output from dw (73 line(s), not counted); late output from pg (35 line(s), not counted); late output from qc (57 line(s), not counted); late output from pb (28 line(s), not counted); late output from fv (13 line(s), not counted); late output from msg (27 line(s), not counted); late output from mood (51 line(s), not counted); late output from rs (20 line(s), not counted); late output from sbx (45 line(s), not counted); late output from tw (204 line(s), not counted); late output from ap (34 line(s), not counted); late output from sl (6 line(s), not counted); late output from rb (69 line(s), not counted); late output from cd (17 line(s), not counted); late output from sm (9 line(s), not counted); late output from tm (10 line(s), not counted); late output from t3 (8 line(s), not counted); late output from dash (22 line(s), not counted); no DONE; the game dropped to the main menu during this script |
| 39 | zedqa_exinfo.lua | ex | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 40 | zedqa_charinfo.lua | ci | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 41 | zedqa_equipdrag.lua | eqd | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 42 | zedqa_cazio_light.lua | czl | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 43 | zedqa_dashnight.lua | dnt | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 44 | zedqa_testlang.lua | tlang | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 45 | zedqa_safemode.lua | safe | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 46 | zedqa_soak.lua | soak | SKIP |  |  | not run: the game dropped to the main menu during this script |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 45 s

- go 14041 at 01:08:07

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pre start
:	[ZeD.QA] run #1 ok=true
:	ZEDQA pre char true world true speed 1 ticks 60 frames 61
:	ZEDQA pre search overlay: enabled false, override false, manager false
:	ZEDQA pre DONE
```

### 2. zedqa_print_fit.lua (`ZEDQA pf`) - PASS, 15 s

- go 14042 at 01:08:58
- screenshots: zqa_pf_1a_KnoxKnews_July1_vanilla.png, zqa_pf_1b_KnoxKnews_July1_fitted.png, zqa_pf_2a_KnoxKnews_July2_vanilla.png, zqa_pf_2b_KnoxKnews_July2_fitted.png, zqa_pf_3a_KentuckyHerald_July6_vanilla.png, zqa_pf_3b_KentuckyHerald_July6_fitted.png, zqa_pf_4a_NationalDispatch_July6_vanilla.png, zqa_pf_4b_NationalDispatch_July6_fitted.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pf start
:	[ZeD.QA] run #2 ok=true
:	ZEDQA pf KnoxKnews_July1 element_23 y 470->376 room 509 scale 0.40->0.64 h 247
:	ZEDQA pf KnoxKnews_July1 element_25 y 700->686 room 184 scale 0.40->0.64 h 106 head 0.80->1.09
:	ZEDQA pf KnoxKnews_July2 element_23 y 470->376 room 509 scale 0.40->0.64 h 221
:	ZEDQA pf KnoxKnews_July2 element_25 y 700->686 room 184 scale 0.40->0.64 h 106 head 0.80->1.09
:	ZEDQA pf KnoxKnews_July2 element_27 y 700->686 room 184 scale 0.40->0.64 h 106 head 0.80->1.09
:	ZEDQA pf KentuckyHerald_July6 element_15 y 395->396 room 330 scale 0.45->0.64 h 157
:	ZEDQA pf KentuckyHerald_July6 element_18 y 415->416 room 310 scale 0.45->0.64 h 144
:	ZEDQA pf NationalDispatch_July6 element_16 y 339->322 room 453 scale 0.40->0.64 h 259
:	ZEDQA pf NationalDispatch_July6 element_21 y 240->227 room 573 scale 0.40->0.64 h 323
:	ZEDQA pf DONE
```

### 3. zedqa_print_typeset.lua (`ZEDQA ts`) - PASS, 7 s

- go 14043 at 01:09:19
- screenshots: zqa_ts_1_KnoxKnews_July1.png, zqa_ts_2_KnoxKnews_July2.png, zqa_ts_3_KentuckyHerald_July6.png, zqa_ts_4_NationalDispatch_July6.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA ts start
:	[ZeD.QA] run #3 ok=true
:	ZEDQA ts KnoxKnews_July1 stories 3 body 27.884615384615387 lines 58
:	ZEDQA ts KnoxKnews_July2 stories 3 body 26.884615384615387 lines 53
:	ZEDQA ts KentuckyHerald_July6 stories 2 body 30.153615384615385 lines 43
:	ZEDQA ts NationalDispatch_July6 stories 5 body 23.076923076923077 lines 77
:	ZEDQA ts DONE
```

### 4. zedqa_prompts.lua (`ZEDQA pr`) - PASS, 32 s

- go 14044 at 01:09:32
- screenshots: zqa_pr_01_sleep.png, zqa_pr_02_kill.png, zqa_pr_03_note.png, zqa_pr_04_rename.png, zqa_pr_05_rename_empty.png, zqa_pr_06_keyboard.png, zqa_pr_07_alarm.png, zqa_pr_08_timer.png, zqa_pr_09_help.png, zqa_pr_10_rich_question.png, zqa_pr_11_gp_question.png, zqa_pr_12_gp_question_no.png, zqa_pr_13_gp_kill.png, zqa_pr_14_gp_text.png, zqa_pr_15_gp_keyboard.png, zqa_pr_16_gp_alarm.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pr start
:	[ZeD.QA] run #4 ok=true
:	ZEDQA pr sleep Type=ZeD_Prompt kind=question x=1659 y=965 w=526 h=232 visible=false top=false
:	ZEDQA pr mouse 1922,1081
:	ZEDQA pr answer sleep internal=NO parentKind=question entry=nil
:	ZEDQA pr kill Type=ZeD_Prompt kind=question x=1659 y=965 w=526 h=232 visible=false top=false
:	ZEDQA pr kill costly=true
:	ZEDQA pr kill after No Type=ZeD_Prompt kind=question x=1659 y=965 w=526 h=232 visible=false top=false
:	ZEDQA pr note Type=ZeD_Prompt kind=note x=1578 y=964 w=683 h=232 visible=false top=false
:	ZEDQA pr answer note internal=OK parentKind=note entry=nil
:	ZEDQA pr after Escape: note visible=false pause=false
:	ZEDQA pr rename bag Fanny Pack
:	ZEDQA pr rename Type=ZeD_Prompt kind=text x=1624 y=949 w=595 h=262 visible=false top=false
:	ZEDQA pr empty: yes.enable=false why=Can't be empty.
:	ZEDQA pr long: yes.enable=false why=Character limit: 12
    LOG  : Lua          f:2195> :	ZEDQA pr keyboard Type=ISOnScreenKeyboard zed=true IsVisible=false
    OG  : Lua          f:2195> :	ZEDQA pr keyboard Type=ISOnScreenKeyboard kind=nil x=1429 y=1224 w=984 h=371 visible=false top=false
:	ZEDQA pr rename under keyboard Type=ZeD_Prompt kind=text x=1624 y=948 w=595 h=262 visible=true top=true
:	ZEDQA pr typed: Go Bags! current=Go Bags!
:	ZEDQA pr after keyboard cancel: Go Bag kbVisible=false
:	ZEDQA pr rename OK kept name=true
:	ZEDQA pr alarm Type=ZeD_Prompt kind=alarm x=1657 y=878 w=525 h=402 visible=false top=false
:	ZEDQA pr alarm after pad: 7:20 on=false focus=tick
:	ZEDQA pr alarm synced 7:20 on=false
:	ZEDQA pr timer Type=ZeD_Prompt kind=timer x=1657 y=936 w=525 h=286 visible=false top=false
:	ZEDQA pr timer answer OK time=35
:	ZEDQA pr help Type=ZeD_Prompt kind=rich x=1435 y=755 w=770 h=648 visible=false top=false
:	ZEDQA pr help blocks=5 contentH=486.67578125 maxScroll=0
:	ZEDQA pr help after OK visible=false
:	ZEDQA pr forget Type=ZeD_Prompt kind=rich x=1582 y=965 w=679 h=232 visible=false top=false
:	ZEDQA pr forget costly=false
:	ZEDQA pr answer forget internal=NO parentKind=rich entry=nil
:	ZEDQA pr subclass build ok=true kind=nil Type=ISConfirmMonitorSettings
:	ZEDQA pr open prompts left=0
:	ZEDQA pr gp focus=yes
:	ZEDQA pr gp after left focus=no
:	ZEDQA pr answer gp sleep internal=NO parentKind=question entry=nil
:	ZEDQA pr gp text focus=field
:	ZEDQA pr answer gp rename internal=CANCEL parentKind=text entry=Duffel Bag
:	ZEDQA pr gp open prompts left=0
:	ZEDQA pr DONE
```

### 5. zedqa_fishing.lua (`ZEDQA fi`) - PASS, 8 s

- go 14045 at 01:10:10
- screenshots: zqa_fi_1_slack.png, zqa_fi_2_light.png, zqa_fi_3_tight.png, zqa_fi_4_strain.png, zqa_fi_5_limit.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA fi start
:	[ZeD.QA] run #5 ok=true
:	ZEDQA fi 1_slack tension -0.6 vanilla angle -62
:	ZEDQA fi 2_light tension 0.15 vanilla angle -32
:	ZEDQA fi 3_tight tension 0.4 vanilla angle -2
:	ZEDQA fi 4_strain tension 0.72 vanilla angle 36.39999999999999
:	ZEDQA fi 5_limit tension 0.96 vanilla angle 65.19999999999999
:	ZEDQA fi DONE
```

### 6. zedqa_props_plates.lua (`ZEDQA props`) - PASS, 3 s

- go 14046 at 01:10:24
- screenshots: zqa_props_1.png, zqa_props_2.png, zqa_props_3.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #6 ok=true
:	ZEDQA props draw rod true/true slack true clock true/true
:	ZEDQA props DONE
```

### 7. zedqa_belt_strap.lua (`ZEDQA belt`) - PASS, 2 s

- go 14047 at 01:10:33
- screenshots: zqa_belt_strap_1.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #7 ok=true
:	ZEDQA belt textures true
:	ZEDQA belt shot; DONE
```

### 8. zedqa_straps.lua (`ZEDQA straps`) - PASS, 12 s

- go 14048 at 01:10:41
- screenshots: zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #8 ok=true
:	ZEDQA straps put aside 2
:	ZEDQA straps civilian worn HolsterSimple_Brown,Belt2,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,VisionBoost
:	ZEDQA straps civilian slots Back=sling HolsterRight=holster_brown SmallBeltLeft=leather SmallBeltRight=leather Back2=leather BritaBeltFront=leather BritaBeltBack=leather | waist=leather closure=buckle
:	ZEDQA straps civilian shot
:	ZEDQA straps military worn Holster_DuctTape,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICEpack_Army,Bag_ALICE_BeltSus_Camo,VisionBoost
:	ZEDQA straps military slots Back=webbing_olive HolsterRight=holster_tape SmallBeltLeft=webbing_camo SmallBeltRight=webbing_camo Back2=leather BedrollBottomALICE=webbing_olive WebbingRight=webbing_camo WebbingLeft=webbing_camo | waist=webbing_camo closure=clip_black
:	ZEDQA straps military shot
:	ZEDQA straps makeshift worn Holster_Hide,RopeBelt,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_CraftedFramepack_Large,VisionBoost
:	ZEDQA straps makeshift slots Back=rope HolsterRight=holster_hide SmallBeltLeft=rope Back2=leather BedrollBottom=rope | waist=rope closure=knot
:	ZEDQA straps makeshift shot
:	ZEDQA straps firefighter worn Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,SCBA,VisionBoost
:	ZEDQA straps firefighter slots Back=harness SmallBeltLeft=harness Back2=leather SmallBeltRight=harness WebbingLeft=harness | waist=harness closure=clip_black
:	ZEDQA straps firefighter shot
:	ZEDQA straps olive worn Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICE_BeltSus,VisionBoost
:	ZEDQA straps olive slots Back=sling SmallBeltLeft=webbing_olive Back2=leather SmallBeltRight=webbing_olive WebbingLeft=webbing_olive WebbingRight=webbing_olive | waist=webbing_olive closure=clip_brass
:	ZEDQA straps olive shot
:	ZEDQA straps restored; DONE
```

### 9. zedqa_buckle.lua (`ZEDQA bk`) - PASS, 5 s

- go 14049 at 01:10:59
- screenshots: zqa_bk_1.png, zqa_bk_2.png, zqa_bk_3.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA bk start
:	[ZeD.QA] run #9 ok=true
:	ZEDQA bk centre 1920 vs screen 1920 | belt x 1342 w 1141 | delta 0 | bare watch none
:	ZEDQA bk worn zwatchslots:leftwatch
:	ZEDQA bk centre 1920 vs screen 1920 | belt x 1240 w 1243 | delta 0 | cazio watch digital_black wrist left
:	ZEDQA bk worn zwatchslots:rightwatch
:	ZEDQA bk centre 1920 vs screen 1920 | belt x 1342 w 1243 | delta 0 | timez watch timez_easy wrist right
:	ZEDQA bk DONE
```

### 10. zedqa_buckles.lua (`ZEDQA bks`) - PASS, 45 s

- go 14050 at 01:11:10
- screenshots: zqa_bk_01_burgerflipper.png, zqa_bk_02_repairman.png, zqa_bk_03_burglar.png, zqa_bk_04_engineer.png, zqa_bk_05_fisherman.png, zqa_bk_06_policeofficer.png, zqa_bk_07_lumberjack.png, zqa_bk_08_smither.png, zqa_bk_09_farmer.png, zqa_bk_10_electrician.png, zqa_bk_11_fireofficer.png, zqa_bk_12_metalworker.png, zqa_bk_13_fitnessinstructor.png, zqa_bk_14_veteran.png, zqa_bk_15_tailor.png, zqa_bk_16_chef.png, zqa_bk_17_doctor.png, zqa_bk_18_parkranger.png, zqa_bk_19_unemployed.png, zqa_bk_20_nurse.png, zqa_bk_21_securityguard.png, zqa_bk_22_carpenter.png, zqa_bk_23_mechanics.png, zqa_bk_24_rancher.png, zqa_bk_25_constructionworker.png, zqa_bk_26_priest.png, zqa_bk_27_soldier.png, zqa_bk_28_mailman.png, zqa_bk_29_ascetic.png, zqa_bk_30_paramedic.png, zqa_bk_31_hunter.png, zqa_bk_32_convict.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA bks professions 32
:	ZEDQA bks start
:	[ZeD.QA] run #10 ok=true
:	ZEDQA bks 01 burgerflipper buckle=1862,2046,116,80
:	ZEDQA bks 02 repairman buckle=1862,2046,116,80
:	ZEDQA bks 03 burglar buckle=1862,2046,116,80
:	ZEDQA bks 04 engineer buckle=1862,2046,116,80
:	ZEDQA bks 05 fisherman buckle=1862,2046,116,80
:	ZEDQA bks 06 policeofficer buckle=1862,2046,116,80
:	ZEDQA bks 07 lumberjack buckle=1862,2046,116,80
:	ZEDQA bks 08 smither buckle=1862,2046,116,80
:	ZEDQA bks 09 farmer buckle=1862,2046,116,80
:	ZEDQA bks 10 electrician buckle=1862,2046,116,80
:	ZEDQA bks 11 fireofficer buckle=1862,2046,116,80
:	ZEDQA bks 12 metalworker buckle=1862,2046,116,80
:	ZEDQA bks 13 fitnessinstructor buckle=1862,2046,116,80
:	ZEDQA bks 14 veteran buckle=1862,2046,116,80
:	ZEDQA bks 15 tailor buckle=1862,2046,116,80
:	ZEDQA bks 16 chef buckle=1862,2046,116,80
:	ZEDQA bks 17 doctor buckle=1862,2046,116,80
:	ZEDQA bks 18 parkranger buckle=1862,2046,116,80
:	ZEDQA bks 19 unemployed buckle=1862,2046,116,80
:	ZEDQA bks 20 nurse buckle=1862,2046,116,80
:	ZEDQA bks 21 securityguard buckle=1862,2046,116,80
:	ZEDQA bks 22 carpenter buckle=1862,2046,116,80
:	ZEDQA bks 23 mechanics buckle=1862,2046,116,80
:	ZEDQA bks 24 rancher buckle=1862,2046,116,80
:	ZEDQA bks 25 constructionworker buckle=1862,2046,116,80
:	ZEDQA bks 26 priest buckle=1862,2046,116,80
:	ZEDQA bks 27 soldier buckle=1862,2046,116,80
:	ZEDQA bks 28 mailman buckle=1862,2046,116,80
:	ZEDQA bks 29 ascetic buckle=1862,2046,116,80
:	ZEDQA bks 30 paramedic buckle=1862,2046,116,80
:	ZEDQA bks 31 hunter buckle=1862,2046,116,80
:	ZEDQA bks 32 convict buckle=1862,2046,116,80
:	ZEDQA bks DONE (profession back to unemployed)
```

### 11. zedqa_beltwatch.lua (`ZEDQA bw`) - PASS, 13 s

- go 14051 at 01:12:01
- screenshots: zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA bw start
:	[ZeD.QA] run #11 ok=true
:	ZEDQA bw worn zwatchslots:leftwatch
:	ZEDQA bw box digital_black wrist left x 0 w 88 | hands s@102 p@1071 | belt w 1243
:	ZEDQA bw full watch tucked: 0x0
:	ZEDQA bw popped true at 1240,1674 248x352 | mini at 1240,2040
:	ZEDQA bw dragged to 1500,500 saved 857.1428571428571,285.7142857142857
:	ZEDQA bw after idle: popped true size 248
:	ZEDQA bw right wrist: timez_easy wrist right x 1074 | hands s@0 p@969
:	ZEDQA bw corner: box false full watch 3524,10 300x352
:	ZEDQA bw DONE
```

### 12. zedqa_belt_hands.lua (`ZEDQA bh`) - PASS, 4 s

- go 14052 at 01:12:20
- screenshots: zqa_bh_1_left_wrist.png, zqa_bh_2_right_wrist.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA bh start
:	[ZeD.QA] run #12 ok=true
:	ZEDQA bh PASS left wrist: the boxes run left to right (watch@0 OFF@102 #1@232 #2@328 #3@424 #4@520 #5@763 #6@859 #7@955 MAIN@1071 lamp@1176)
:	ZEDQA bh PASS left wrist: the off hand at the left end, the main hand at the right, the slots between
:	ZEDQA bh PASS left wrist: the Messages note is last on the right
:	ZEDQA bh PASS left wrist: the watch is left of the off hand
:	ZEDQA bh PASS left wrist: the full watch pops at the left end (left)
:	ZEDQA bh PASS pad: the belt starts on slot 1 (#1)
:	ZEDQA bh PASS pad: Left from slot 1 is the off hand (OFF)
:	ZEDQA bh PASS right wrist: the boxes run left to right (OFF@0 #1@130 #2@226 #3@322 #4@418 #5@661 #6@757 #7@853 MAIN@969 watch@1074 lamp@1176)
:	ZEDQA bh PASS right wrist: the off hand at the left end, the main hand at the right, the slots between
:	ZEDQA bh PASS right wrist: the Messages note is last on the right
:	ZEDQA bh PASS right wrist: the watch is right of the main hand
:	ZEDQA bh PASS right wrist: the full watch pops at the right end (right)
:	ZEDQA bh PASS as worn: the boxes run left to right (OFF@0 #1@130 #2@226 #3@322 #4@418 #5@661 #6@757 #7@853 MAIN@969 lamp@1074)
:	ZEDQA bh PASS as worn: the off hand at the left end, the main hand at the right, the slots between
:	ZEDQA bh PASS as worn: the Messages note is last on the right
:	ZEDQA bh all checks passed
:	ZEDQA bh DONE
```

### 13. zedqa_watches2.lua (`ZEDQA watches`) - PASS, 28 s

- go 14053 at 01:12:30
- screenshots: zqa_watch_day_DigitalBlack.png, zqa_watch_day_DigitalDress.png, zqa_watch_day_DigitalRed.png, zqa_watch_day_DigitalTimez.png, zqa_watch_day_ClassicBlack.png, zqa_watch_day_ClassicGold.png, zqa_watch_day_ClassicBrown.png, zqa_watch_day_ClassicMilitary.png, zqa_watch_day_Expensive.png, zqa_watch_set_DigitalBlack.png, zqa_watch_night_DigitalBlack.png, zqa_watch_night_DigitalTimez.png, zqa_watch_lit_DigitalTimez.png, zqa_watch_night_ClassicBrown.png, zqa_watch_lit_ClassicBrown.png, zqa_watch_night_Expensive.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #13 ok=true
:	ZEDQA watches own watch nil at nil
:	ZEDQA watches no own watch; location zwatchslots:leftwatch
:	ZEDQA watches item left true right true
:	ZEDQA watches name 'Digital Watch - Steel Sport Style' icon C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\textures\Item_ZeDWatchTimezSteel.png world Base.ZeDDigitalWatchSteel clothing true/WristWatch_Left_DigitalTimez digital true class true
:	ZEDQA watches DigitalBlack plate digital_black size 248x352 at 3576,10 hits alarm,light,set,speed,start
:	ZEDQA watches DigitalDress plate digital_gold size 248x352 at 3576,10 hits alarm,light,set,speed,start
:	ZEDQA watches DigitalRed plate timez_red size 248x352 at 3576,10 hits alarm,light,set,speed,start
:	ZEDQA watches DigitalTimez plate timez_steel size 248x352 at 3576,10 hits alarm,light,set,speed,start
:	ZEDQA watches ClassicBlack plate classic_black size 300x352 at 3524,10 hits alarm,crown,light,set,speed,start
:	ZEDQA watches ClassicGold plate classic_gold size 300x352 at 3524,10 hits alarm,crown,light,set,speed,start
:	ZEDQA watches ClassicBrown plate timez_easy size 300x352 at 3524,10 hits crown,light,speed,start
:	ZEDQA watches ClassicMilitary plate timez_camper size 300x352 at 3524,10 hits crown,light,speed,start
:	ZEDQA watches Expensive plate expensive size 300x352 at 3524,10 hits crown,speed,start
:	ZEDQA watches setting open true hits alarm,light,set,setdn,setup,speed,start
:	ZEDQA watches after + + armed true hour 1
:	ZEDQA watches night dark=true
:	ZEDQA watches DigitalTimez lit=true
:	ZEDQA watches ClassicBrown lit=true
:	ZEDQA watches light out: lit=false dark=true
:	ZEDQA watches restored own watch nil; DONE
```

### 14. zedqa_container_bottom.lua (`ZEDQA cb`) - PASS, 11 s

- go 14054 at 01:13:03
- screenshots: zqa_cb_01_rows_at_bottom.png, zqa_cb_02_list_end.png, zqa_cb_03_pad_take_all.png, zqa_cb_04_campfire_ribbon.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA cb start
:	[ZeD.QA] run #14 ok=true
:	ZEDQA cb no pickup in the loaded cell; spawned one beside the character: true
:	ZEDQA cb bed selected true
:	ZEDQA cb world list 651x664, row 49 at y 615
:	ZEDQA cb campfire selected true
:	ZEDQA cb DONE
```

### 15. zedqa_container_controls.lua (`ZEDQA ct`) - PASS, 20 s

- go 14055 at 01:13:20
- screenshots: zqa_ct_01_rows.png, zqa_ct_02_pad_same_type.png, zqa_ct_03_after_take_all.png, zqa_ct_04_floor_row.png, zqa_ct_05_campfire_row.png, zqa_ct_06_add_fuel_card.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA ct start
:	[ZeD.QA] run #15 ok=true
:	ZEDQA ct no pickup in the loaded cell; spawned one beside the character: true
:	ZEDQA ct pickup true
:	ZEDQA ct bed selected true
:	ZEDQA ct your row: Transfer all, Same type, Same type, all nearby
:	ZEDQA ct world row: Take all, Same type, To floor
:	ZEDQA ct start: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0
:	ZEDQA ct focused worldCtl:same prompt Take the kinds you already carry
:	ZEDQA ct marked rows (things) 7
:	ZEDQA ct no button Same type
:	ZEDQA ct after Same type (take): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0
:	ZEDQA ct no button Same type
:	ZEDQA ct after Same type (back): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0
:	ZEDQA ct no button Take all
:	ZEDQA ct after Take all: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0
:	ZEDQA ct no button Transfer all
:	ZEDQA ct after Transfer all: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0
:	ZEDQA ct no button To floor
:	ZEDQA ct after To floor: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0
:	ZEDQA ct floor selected true
:	ZEDQA ct floor row: Take all(off), Same type(off)
:	ZEDQA ct no button Take all
:	ZEDQA ct after Take all (floor): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0
:	ZEDQA ct no button Transfer all
:	ZEDQA ct after Transfer all (back to the bed): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0
:	ZEDQA ct campfire placed true true
:	ZEDQA ct campfire container true selected true
:	ZEDQA ct campfire row: Take all, Same type(off), To floor, |, Take apart, Light, Add fuel
:	ZEDQA ct no button Add fuel
:	ZEDQA ct after Add fuel: object card false jump nil
:	ZEDQA ct no button Take apart
:	ZEDQA ct after Take apart: campfire still there true
:	ZEDQA ct restored: bag nails 0 planks 0 | bed nails 0 planks 0 beans 0, 2 things | floor -1
:	ZEDQA ct DONE
```

### 16. zedqa_container_controls_captures.lua (`ZEDQA cc`) - PASS, 7 s

- go 14056 at 01:13:47
- screenshots: zqa_cc_zed_truckbed.png, zqa_cc_vanilla_truckbed.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA cc start
:	[ZeD.QA] run #16 ok=true
:	ZEDQA cc no pickup in the loaded cell; spawned one beside the character: true
:	ZEDQA cc pickup true bed part TruckBedOpen
:	ZEDQA cc truck bed true dist 1.0
:	ZEDQA cc world window on the truck bed (1)
:	ZEDQA cc char 1134,0 777x735 world 1929,0 777x735
:	ZEDQA cc vanilla inv 640,0 1280x720 loot 1920,0 1280x720
:	ZEDQA cc DONE
```

### 17. zedqa_button_case_game.lua (`ZEDQA bg`) - PASS, 19 s

- go 14057 at 01:14:00
- screenshots: zqa_bg_01_item_card.png, zqa_bg_02_health.png, zqa_bg_03_thermal.png, zqa_bg_04_animals.png, zqa_bg_05_forage.png, zqa_bg_06_craft.png, zqa_bg_07_vehicle.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA bg start
:	[ZeD.QA] run #17 ok=true
:	ZEDQA bg no pickup in the loaded cell; spawned one beside the character: true
:	ZEDQA bg pickup true shirt true
:	ZEDQA bg card open true
:	ZEDQA bg DONE
```

### 18. zedqa_wheel_sizes.lua (`ZEDQA ws`) - PASS, 19 s

- go 14058 at 01:14:25
- screenshots: zqa_ws_a_gun3.png, zqa_ws_b_dright3.png, zqa_ws_c_emotes5.png, zqa_ws_d_signal9.png, zqa_ws_e_back10.png, zqa_ws_g_car11.png, zqa_ws_h_car11pt.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA ws no pickup within 20 tiles; spawned one beside the character: true
:	[ZeD.QA] run #18 ok=true
:	ZEDQA ws a_gun3 n=3 r=49 w=600
:	ZEDQA ws b_dright3 n=8 r=74 w=650
:	ZEDQA ws c_emotes5 n=6 r=57 w=616
:	ZEDQA ws d_signal9 n=9 r=83 w=668
:	ZEDQA ws e_back10 n=10 r=92 w=686
:	ZEDQA ws g_car11 n=12 r=110 w=722
:	ZEDQA ws h_car11pt n=12 r=110 w=722
:	ZEDQA ws done
```

### 19. zedqa_wheels.lua (`ZEDQA wh`) - PASS, 31 s

- go 14059 at 01:14:50
- screenshots: zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA wh no pickup within 20 tiles; spawned one beside the character: true
:	ZEDQA wh start car=BaseVehicle{ Name:null, ID:11 } pistol=nil torch=Base.HandTorch:zombie.inventory.types.DrainableComboItem@5bd6f104
:	[ZeD.QA] run #19 ok=true
:	ZEDQA wh outside zed=true java=UIElement n=0 x=1559 y=719 w=722 vis=false point=-1 title=nil |
:	ZEDQA wh inside zed=true java=UIElement n=11 x=1568 y=728 w=704 vis=false point=-1 title=nil | 1:Switch Seat 2:Turn Headlights on 3:Turn AC/Heater on 4:Horn 5:Device Options 6:Open Window 7:Lock all doors 8:Vehicle Mechanics 9:Not tired enough to sleep.[off] 10:Exit Vehicle 11:Use Cassette Player
:	ZEDQA wh pick test slice3 from mouse -> 3
:	ZEDQA wh emotes zed=true java=UIElement n=6 x=1612 y=772 w=616 vis=false point=-1 title=nil | 1:Friendly 2:Hostile 3:Group 4:Signal 5:Shout 6:Dance
:	ZEDQA wh press towards 4 (Signal)
:	ZEDQA wh signal zed=true java=UIElement n=9 x=1586 y=746 w=668 vis=true point=-1 title=Signal | 1:Cease Fire 2:Ok 3:Move Out 4:Freeze 5:Follow Behind 6:Fire 7:Come 8:Salute 9:Back
:	ZEDQA wh gun zed=true java=UIElement n=9 x=1586 y=746 w=668 vis=false point=2 title=Signal | 1:Cease Fire 2:Ok 3:Move Out 4:Freeze 5:Follow Behind 6:Fire 7:Come 8:Salute 9:Back
:	ZEDQA wh light zed=true java=UIElement n=2 x=1620 y=780 w=600 vis=false point=-1 title=nil | 1:Flashlight/Unequip 2:Flashlight/Turn on
:	ZEDQA wh back zed=true java=UIElement n=10 x=1577 y=737 w=686 vis=false point=-1 title=nil | 1:Base theme/Dark 2:Accent color/Purple 3:Text size/Small 4:UI scale 5:Moodles/Right edge 6:Action bar/Verbose 7:Messages/3 new 8:Reset windows/Both windows, as the footer's R 9:ZeD setup/Options, on ZeD's page 10:Safe mode/The game's own interface
:	ZEDQA wh dright zed=true java=UIElement n=8 x=1595 y=755 w=650 vis=false point=-1 title=nil | 1:Tabs/World window 2:Map 3:Vehicle/No vehicle in reach.[off] 4:Animal/No tame animal in reach.[off] 5:Craft and build 6:Search 7:Lights and power/No lights or power in reach.[off] 8:Designated Zones/Animals
:	ZEDQA wh zone route: world=true vanillaZone=false
:	ZEDQA wh zone tab showing=true
:	ZEDQA wh search route: forage showing=true vanillaSearch=false
:	ZEDQA wh player info route: char=true vanillaInfo=false
:	ZEDQA wh DONE
```

### 20. zedqa_dpad_wheels.lua (`ZEDQA dw`) - PASS, 53 s

- go 14060 at 01:15:27
- screenshots: zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA dw start
:	[ZeD.QA] run #20 ok=true
:	ZEDQA dw scene: at 12031,11756, in a car false, health 100
:	ZEDQA dw foot left: 8 slices, crumb Character, visible false | 1:Tabs / Character window [>] 2:Weapons [>] 3:Eat [>] 4:Drink / Nothing to drink on you. [off] 5:Medicine and first aid / Nothing to treat, no medicine on you. [off] 6:Sleep / Not tired enough to sleep. [off] 7:Clothing / Nothing you wear can change. [off] 8:Use / Smoke | Read | Watch | Radio [>]
:	ZEDQA dw PASS left: the top level has its slices (8, 9 on ZeD)
:	ZEDQA dw PASS left: the slice 'Tabs' is there
:	ZEDQA dw inner left: 9 slices, crumb Character › Tabs, visible true | 1:Loot 2:Equipment 3:Health 4:Thermal 5:Identity 6:Journal 7:Skills 8:Radio / No radio in your hands or on your back. [off] 9:Back
:	ZEDQA dw PASS left: the inner wheel ends with Back
:	ZEDQA dw PASS left: the breadcrumb names the inner wheel
:	ZEDQA dw PASS left: B from the inner wheel is back on the top level
:	ZEDQA dw PASS left: B on the top level closes the wheel
:	ZEDQA dw foot right: 8 slices, crumb World, visible false | 1:Tabs / World window [>] 2:Map [>] 3:Vehicle / No vehicle in reach. [off] 4:Animal / No tame animal in reach. [off] 5:Craft and build [>] 6:Search [>] 7:Lights and power / No lights or power in reach. [off] 8:Designated Zones / Animals
:	ZEDQA dw PASS right: the top level has its slices (8, 9 on ZeD)
:	ZEDQA dw PASS right: the slice 'Map' is there
:	ZEDQA dw inner right: 4 slices, crumb World › Map, visible true | 1:Show/Hide World Map 2:Show/Hide Mini-Map / The mini-map is off in this game. [off] 3:Focus Mini Map / The mini-map is off in this game. [off] 4:Back
:	ZEDQA dw PASS right: the inner wheel ends with Back
:	ZEDQA dw PASS right: the breadcrumb names the inner wheel
:	ZEDQA dw PASS right: B from the inner wheel is back on the top level
:	ZEDQA dw PASS right: B on the top level closes the wheel
:	ZEDQA dw foot up: 8 slices, crumb Social, visible false | 1:Friendly [>] 2:Hostile [>] 3:Group [>] 4:Signal [>] 5:Shout 6:Chat / On a server only. [off] 7:Safety / On a server only. [off] 8:Players / On a server only. [off]
:	ZEDQA dw PASS up: the top level has its slices (8, 9 on ZeD)
:	ZEDQA dw PASS up: the slice 'Friendly' is there
:	ZEDQA dw inner up: 6 slices, crumb Social › Friendly, visible true | 1:Wave Hi 2:Bye 3:Clap 4:Thumbs Up 5:Thank You 6:Back
:	ZEDQA dw PASS up: the inner wheel ends with Back
:	ZEDQA dw PASS up: the breadcrumb names the inner wheel
:	ZEDQA dw PASS up: B from the inner wheel is back on the top level
:	ZEDQA dw PASS up: B on the top level closes the wheel
:	ZEDQA dw foot down: 8 slices, crumb Here and now, visible false | 1:Sit [>] 2:Crouch / Off 3:Auto-walk / Off 4:Game speed [>] 5:Zoom [>] 6:View / Interface and windows [>] 7:Help [>] 8:Flashlight / Turn on
:	ZEDQA dw PASS down: the top level has its slices (8, 9 on ZeD)
:	ZEDQA dw PASS down: the slice 'Zoom' is there
:	ZEDQA dw inner down: 3 slices, crumb Here and now › Zoom, visible true | 1:Zoom 75% 2:Zoom 125% 3:Back
:	ZEDQA dw PASS down: the inner wheel ends with Back
:	ZEDQA dw PASS down: the breadcrumb names the inner wheel
:	ZEDQA dw PASS down: B from the inner wheel is back on the top level
:	ZEDQA dw PASS down: B on the top level closes the wheel
:	ZEDQA dw foot select: 10 slices, crumb ZeD, visible false | 1:Base theme / Dark [>] 2:Accent color / Purple [>] 3:Text size / Small [>] 4:UI scale [>] 5:Moodles / Right edge [>] 6:Action bar / Verbose [>] 7:Messages / 3 new 8:Reset windows / Both windows, as the footer's R 9:ZeD setup / Options, on ZeD's page 10:Safe mode / The game's own interface
:	ZEDQA dw PASS select: the top level has its slices (8, 9 on ZeD)
:	ZEDQA dw PASS select: the slice 'Base theme' is there
:	ZEDQA dw inner select: 4 slices, crumb ZeD › Base theme, visible true | 1:Dark / In use 2:Light 3:High contrast 4:Back
:	ZEDQA dw PASS select: the inner wheel ends with Back
:	ZEDQA dw PASS select: the breadcrumb names the inner wheel
:	ZEDQA dw PASS select: B from the inner wheel is back on the top level
:	ZEDQA dw PASS select: B on the top level closes the wheel
:	ZEDQA dw look back to dark / purple / small
:	ZEDQA dw PASS Character > Tabs has Health
:	ZEDQA dw PASS Character > Tabs > Health opened the Character window on Health
:	ZEDQA dw World > Map > Mini-map is off: The mini-map is off in this game.
:	ZEDQA dw no mini-map in this game (sandbox): the slice is off, as it should be
:	ZEDQA dw PASS Social > Shout is live
:	ZEDQA dw PASS Here and now > Zoom > in changed the zoom (1.00 -> 0.75)
:	ZEDQA dw PASS ZeD > Text size marks the size in use
:	ZEDQA dw PASS ZeD > Text size > the size in use keeps it (small)
:	ZEDQA dw PASS the game pauses for the paused checks
:	ZEDQA dw PASS paused: left stays closed
:	ZEDQA dw PASS paused: right stays closed
:	ZEDQA dw PASS paused: up stays closed
:	ZEDQA dw PASS paused: down opens
:	ZEDQA dw PASS paused: select opens
:	ZEDQA dw PASS the game runs again after the paused checks
:	ZEDQA dw PASS with a window holding the pad, D-pad Left stays in the window (no wheel)
:	ZEDQA dw PASS L3 steps the sort (name, cat, cond)
:	ZEDQA dw PASS R3 flips the bag between List and Grid (false -> true)
:	ZEDQA dw PASS R3 again flips it back
:	ZEDQA dw PASS the footer names L3 and R3 while the pad is on the list
:	ZEDQA dw no deep-run car within 8 tiles: the car scene is skipped
:	ZEDQA dw 0 animals in the cell, none tame within 15 tiles: a tame cow spawned beside the character (true)
:	ZEDQA dw beside a tame animal (2.0 tiles away before)
:	ZEDQA dw the game's usable animal: nil
:	ZEDQA dw animal right: 8 slices, crumb World, visible false | 1:Tabs / World window [>] 2:Map [>] 3:Vehicle / No vehicle in reach. [off] 4:Animal [>] 5:Craft and build [>] 6:Search [>] 7:Lights and power / No lights or power in reach. [off] 8:Designated Zones / Animals
:	ZEDQA dw PASS beside a tame animal: World > Animal is live
:	ZEDQA dw animal wheel: 5 slices, crumb World › Animal, visible false | 1:Kill Animal 2:Pick up Angus Cow 3:Pet 4:Animal Info 5:Back
:	ZEDQA dw PASS the animal wheel ends with Back
:	ZEDQA dw 0 failed
:	ZEDQA dw DONE
```

### 21. zedqa_pad_glyphs.lua (`ZEDQA pg`) - PASS, 36 s

- go 14061 at 01:16:26
- screenshots: zqa_pg_footer_ps.png, zqa_pg_wheel_ps.png, zqa_pg_footer_xbox.png, zqa_pg_wheel_xbox.png, zqa_pg_footer_deck.png, zqa_pg_wheel_deck.png, zqa_pg_footer_nintendo.png, zqa_pg_wheel_nintendo.png, zqa_pg_footer_kbm.png, zqa_pg_wheel_kbm.png, zqa_pg_footer_ps_light.png, zqa_pg_wheel_ps_light.png, zqa_pg_footer_ps_hicon.png, zqa_pg_wheel_ps_hicon.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pg start
:	[ZeD.QA] run #21 ok=true
:	ZEDQA pg scene: glyph setting xbox, the game's style XBOX, input gamepad
:	ZEDQA pg PASS ps: the setting reads ps
:	ZEDQA pg PASS ps: the set in use is ps
:	ZEDQA pg ps: footer pictures drawn in 10 ticks: 60
:	ZEDQA pg PASS ps: the footer draws its buttons as pictures
:	ZEDQA pg ps: wheel pictures drawn in 5 ticks: 40
:	ZEDQA pg PASS ps: the wheel's prompts are pictures
:	ZEDQA pg PASS xbox: the setting reads xbox
:	ZEDQA pg PASS xbox: the set in use is xbox
:	ZEDQA pg xbox: footer pictures drawn in 10 ticks: 60
:	ZEDQA pg PASS xbox: the footer draws its buttons as pictures
:	ZEDQA pg xbox: wheel pictures drawn in 5 ticks: 40
:	ZEDQA pg PASS xbox: the wheel's prompts are pictures
:	ZEDQA pg PASS deck: the setting reads deck
:	ZEDQA pg PASS deck: the set in use is deck
:	ZEDQA pg deck: footer pictures drawn in 10 ticks: 60
:	ZEDQA pg PASS deck: the footer draws its buttons as pictures
:	ZEDQA pg deck: wheel pictures drawn in 5 ticks: 40
:	ZEDQA pg PASS deck: the wheel's prompts are pictures
:	ZEDQA pg PASS nintendo: the setting reads nintendo
:	ZEDQA pg PASS nintendo: the set in use is nin
:	ZEDQA pg nintendo: footer pictures drawn in 10 ticks: 60
:	ZEDQA pg PASS nintendo: the footer draws its buttons as pictures
:	ZEDQA pg nintendo: wheel pictures drawn in 5 ticks: 32
:	ZEDQA pg PASS nintendo: the wheel's prompts are pictures
:	ZEDQA pg PASS kbm: the setting reads kbm
:	ZEDQA pg PASS kbm: the set in use is nil
:	ZEDQA pg kbm: footer pictures drawn in 10 ticks: 0
:	ZEDQA pg PASS kbm: the footer draws boxed names, no pictures
:	ZEDQA pg kbm: wheel pictures drawn in 5 ticks: 0
:	ZEDQA pg no deep-run car within 8 tiles: the dash scene is skipped
:	ZEDQA pg put back: glyph setting xbox, input lock nil
:	ZEDQA pg all checks passed
:	ZEDQA pg DONE
```

### 22. zedqa_quick_chords.lua (`ZEDQA qc`) - WARN, 25 s

- go 14062 at 01:17:07
- 1 ERR line(s)
- screenshots: zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA qc start
:	[ZeD.QA] run #22 ok=true
:	ZEDQA qc the torch (added) and water, a cigarette, a lighter, an apple in the main inventory; hands: nil / nil
:	ZEDQA qc LB + X picks Base.HandTorch in none (brighter than the torch): that light is checked
:	ZEDQA qc LB+A = character:3 (Character > Eat): Eat
:	ZEDQA qc PASS LB+A: the default names a slice
:	ZEDQA qc LB+B = character:4 (Character > Drink): Drink
:	ZEDQA qc PASS LB+B: the default names a slice
:	ZEDQA qc LB+X = now:8 (Here and now > Light): Flashlight
:	ZEDQA qc PASS LB+X: the default names a slice
:	ZEDQA qc LB+Y = character:8:1 (Character > Use > Smoke): Smoke
:	ZEDQA qc PASS LB+Y: the default names a slice
:	ZEDQA qc LB+L3 = now:1:1 (Here and now > Sit > Sit on ground): Sit on ground
:	ZEDQA qc PASS LB+L3: the default names a slice
:	ZEDQA qc LB+R3 = social:5 (Social > Shout): Shout
:	ZEDQA qc PASS LB+R3: the default names a slice
:	ZEDQA qc RB+A = character:5 (Character > Medicine and first aid): Medicine and first aid [off: Nothing to treat, no medicine on you.]
:	ZEDQA qc PASS RB+A: the default names a slice
:	ZEDQA qc RB+B = character:2 (Character > Weapons): Weapons
:	ZEDQA qc PASS RB+B: the default names a slice
:	ZEDQA qc RB+X = character:8:2 (Character > Use > Read): Read
:	ZEDQA qc PASS RB+X: the default names a slice
:	ZEDQA qc RB+Y = world:2:1 (World > Map > Show/Hide World Map): Show/Hide World Map
:	ZEDQA qc PASS RB+Y: the default names a slice
:	ZEDQA qc RB+L3 = now:3 (Here and now > Auto-walk): Auto-walk
:	ZEDQA qc PASS RB+L3: the default names a slice
:	ZEDQA qc RB+R3 = now:2 (Here and now > Crouch): Crouch
:	ZEDQA qc PASS RB+R3: the default names a slice
:	ZEDQA qc LB + X queued: ISEquipWeaponAction
:	ZEDQA qc PASS LB + X: the game's prompts never saw X
:	ZEDQA qc PASS a light for LB + X
:	ZEDQA qc PASS LB + X: the light is in a hand
:	ZEDQA qc PASS LB + X: the light is on
:	ZEDQA qc PASS LB + X again: the light is off
:	ZEDQA qc LB + X from a bag: skipped, LB + X picks Base.HandTorch in a hand or on the belt first
:	ZEDQA qc PASS stuffed: Eat says Too full to eat more.
:	ZEDQA qc LB + A (eat) queued: ISEatFoodAction
:	ZEDQA qc PASS LB + A (eat): the game queues its action
:	ZEDQA qc LB + B (drink) queued: ISDrinkFromBottle
:	ZEDQA qc PASS LB + B (drink): the game queues its action
:	ZEDQA qc LB + Y (smoke) queued: ISEatFoodAction, ISInventoryTransferAction
:	ZEDQA qc PASS LB + Y (smoke): the game queues its action
:	ZEDQA qc said: No QA Gone on you.
:	ZEDQA qc PASS a gone thing: the character says No QA Gone on you.
:	ZEDQA qc PASS the Here and now wheel is open
:	ZEDQA qc PASS RB + Y on Crouch: the chord reads now:2
:	ZEDQA qc the bubble's note: Now on RB + Y. It replaces Show/Hide World Map.
:	ZEDQA qc PASS the bubble says what it did
:	ZEDQA qc PASS opened again: Crouch shows RB + Y
:	ZEDQA qc PASS ZeD setup is open on the pause screen
:	ZEDQA qc PASS ZeD setup has the twelve chord rows (12)
:	ZEDQA qc FAIL ZeD setup has Put things back
:	ZEDQA qc the list for LB+A: 89 items, 81 to choose
:	ZEDQA qc PASS the chord's list offers the wheels' actions
:	ZEDQA qc put back: the chords file as it was; RB + Y reads world:2:1 (was world:2:1)
:	ZEDQA qc PASS the chords are as they were
:	ZEDQA qc 1 failed
:	ZEDQA qc DONE
```

### 23. zedqa_put_back.lua (`ZEDQA pb`) - PASS, 34 s

- go 14063 at 01:17:38

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pb start
:	[ZeD.QA] run #23 ok=true
:	ZEDQA pb PASS the switch is on
:	ZEDQA pb the bag: Small Backpack; hands: nil / nil
:	ZEDQA pb PASS a worn bag to take things from
:	ZEDQA pb apple: queue empty true, the apple is in bag; put back queued 0
:	ZEDQA pb PASS half an apple: the rest went back into the bag
:	ZEDQA pb PASS half an apple: the game put it back itself, ZeD moved nothing twice
:	ZEDQA pb smoke: queue empty true, the lighter is in bag, the cigarette in nowhere
:	ZEDQA pb PASS a cigarette: the lighter went back into the bag
:	ZEDQA pb drink: thirst 0.40, the bottle holds 0.80
:	ZEDQA pb drink look 1: ISDrinkFromBottle; the bottle in main, holds 0.80
:	ZEDQA pb drink look 2: ISDrinkFromBottle; the bottle in main, holds 0.80
:	ZEDQA pb drink look 3: ISDrinkFromBottle; the bottle in main, holds 0.80
:	ZEDQA pb drink look 4: ISDrinkFromBottle; the bottle in main, holds 0.80
:	ZEDQA pb drink look 5: ISDrinkFromBottle; the bottle in main, holds 0.80
:	ZEDQA pb drink look 6: ISDrinkFromBottle; the bottle in main, holds 0.80
:	ZEDQA pb drink look 7: ISDrinkFromBottle; the bottle in main, holds 0.80
:	ZEDQA pb drink look 8: ISDrinkFromBottle; the bottle in main, holds 0.80
:	ZEDQA pb drink: queue empty true, the bottle is in bag
:	ZEDQA pb PASS a drink: the bottle went back into the bag
:	ZEDQA pb no deep-run car within 10 tiles: the tire scene is skipped
:	ZEDQA pb stopped: the apple is in main
:	ZEDQA pb PASS stopped halfway: the apple stays on you
:	ZEDQA pb switch off: the bottle is in main
:	ZEDQA pb PASS the switch off: the bottle stays on you
:	ZEDQA pb put back: the switch 1 (was 1)
:	ZEDQA pb all checks passed
:	ZEDQA pb DONE
```

### 24. zedqa_food_verbs.lua (`ZEDQA fv`) - PASS, 4 s

- go 14064 at 01:18:17
- screenshots: zqa_fv_smoking.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA fv start
:	[ZeD.QA] run #24 ok=true
:	ZEDQA fv Cigarette: the card's main button reads Smoke (id EAT)
:	ZEDQA fv PASS Cigarette: the card says Smoke
:	ZEDQA fv Apple: the card's main button reads Eat (id EAT)
:	ZEDQA fv PASS Apple: the card says Eat
:	ZEDQA fv Canned Evaporated Milk (Open): the card's main button reads Drink (id EAT)
:	ZEDQA fv PASS Canned Evaporated Milk (Open): the card says Drink
:	ZEDQA fv smoking: the action is ISEatFoodAction, the bar reads SMOKING
:	ZEDQA fv PASS smoking: the bar says SMOKING
:	ZEDQA fv eating: the action is ISEatFoodAction, the bar reads EATING
:	ZEDQA fv PASS an apple: the bar still says EATING
:	ZEDQA fv all checks passed
:	ZEDQA fv DONE
```

### 25. zedqa_messages.lua (`ZEDQA msg`) - WARN, 11 s

- go 14065 at 01:18:27
- 1 expected exception(s) ignored (expect=)
- 1 ERR line(s)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA msg start
:	[ZeD.QA] run #25 ok=true
:	ZEDQA msg FAIL nothing kept: no envelope on the belt
:	ZEDQA msg PASS the three notes are not on screen
:	ZEDQA msg PASS the three notes are kept in Messages
:	ZEDQA msg PASS the source has three messages (3)
:	ZEDQA msg PASS three are new (3)
:	ZEDQA msg PASS a toast names the mod
:	ZEDQA msg PASS the game runs on after the mod paused it for its note (speed 1)
:	ZEDQA msg PASS the envelope is on the belt
:	ZEDQA msg PASS a question still asks at once
:	ZEDQA msg PASS the mod got its answer (YES)
:	ZEDQA msg PASS a copy of the question, already read, is in Messages
ERROR: General f:28173 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:28173> Lua(Vanilla).boom> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaMessagesError of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom(worldmap-annotations.lua:99)
:	ZEDQA msg PASS the one error is filed in Messages, counted once (0 -> 1)
:	ZEDQA msg PASS Messages opens on the mod
:	ZEDQA msg PASS opening it marks the mod's messages read
:	ZEDQA msg PASS four cards: three notes and the question (4)
:	ZEDQA msg PASS three OK buttons, one per note (3)
:	ZEDQA msg PASS OK ran that mod's callback once (1/0/0)
:	ZEDQA msg PASS A on the next card's OK ran its callback
:	ZEDQA msg PASS the controller is in the cards
:	ZEDQA msg PASS the window lists an error source
:	ZEDQA msg PASS the bug report text names the errors (1446 characters)
:	ZEDQA msg PASS with the switch on, the mod's note shows as a pop-up
:	ZEDQA msg PASS Clear removes the mod's messages
:	ZEDQA msg PASS the last unanswered note got its OK as it left
:	ZEDQA msg 1 failed
:	ZEDQA msg DONE
```

### 26. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 20 s

- go 14066 at 01:18:44
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA mood start
:	[ZeD.QA] run #26 ok=true
:	ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
:	ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
:	ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 4
:	ZEDQA mood box by itself: THIRST | waiting 3
:	ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
:	ZEDQA mood right: 4 moodles on (THIRST 2, TIRED 2, STRESS 2, HUNGRY 2)
:	ZEDQA mood PASS right: the place is in effect
:	ZEDQA mood PASS right: at least three moodles are on
:	ZEDQA mood PASS right: the moodles are shown (layer)
:	ZEDQA mood right column at 3782,969 size 48, stack 222; visible true
:	ZEDQA mood PASS right: vanilla's column is visible
:	ZEDQA mood PASS right: every moodle is on screen
:	ZEDQA mood PASS right: the column is on the right edge (x 3782)
:	ZEDQA mood PASS right: ZeD's hover layer lies over the column
:	ZEDQA mood right bubble: moodle 2, cloud -500,19 442x126, trail right from -56,82
:	ZEDQA mood PASS right: the bubble is for the moodle under the pointer
:	ZEDQA mood PASS right: the trail leaves the cloud on the moodle's side
:	ZEDQA mood PASS right: the trail ends at the moodle, level with it
:	ZEDQA mood left: 4 moodles on (THIRST 2, TIRED 2, STRESS 2, HUNGRY 2)
:	ZEDQA mood PASS left: the place is in effect
:	ZEDQA mood PASS left: at least three moodles are on
:	ZEDQA mood PASS left: the moodles are shown (layer)
:	ZEDQA mood left column at 10,969 size 48, stack 222; visible true
:	ZEDQA mood PASS left: vanilla's column is visible
:	ZEDQA mood PASS left: every moodle is on screen
:	ZEDQA mood PASS left: the column is on the left edge (x 10)
:	ZEDQA mood PASS left: ZeD's hover layer lies over the column
:	ZEDQA mood left bubble: moodle 2, cloud 106,19 442x126, trail left from 104,82
:	ZEDQA mood PASS left: the bubble is for the moodle under the pointer
:	ZEDQA mood PASS left: the trail leaves the cloud on the moodle's side
:	ZEDQA mood PASS left: the trail ends at the moodle, level with it
:	ZEDQA mood bottom: 4 moodles on (THIRST 2, TIRED 2, STRESS 2, HUNGRY 2)
:	ZEDQA mood PASS bottom: the place is in effect
:	ZEDQA mood PASS bottom: at least three moodles are on
:	ZEDQA mood PASS bottom: the moodles are shown (layer)
:	ZEDQA mood bottom row at 1809,1972 222x48; vanilla's column y -20000
:	ZEDQA mood PASS bottom: the row is on screen
:	ZEDQA mood PASS bottom: the row is centred (middle 1920 of 3840)
:	ZEDQA mood PASS bottom: the row sits above the belt
:	ZEDQA mood PASS bottom: one slot per moodle
:	ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
:	ZEDQA mood bottom bubble: moodle 2, cloud -133,-184 442x126, trail down from 82,-56
:	ZEDQA mood PASS bottom: the bubble is for the moodle under the pointer
:	ZEDQA mood PASS bottom: the trail leaves the cloud on the moodle's side
:	ZEDQA mood PASS bottom: the trail ends at the moodle, level with it
:	ZEDQA mood PASS with nothing changing the box goes by itself (nil)
:	ZEDQA mood notices off: box nil | waiting 2
:	ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
:	ZEDQA mood all checks passed
:	ZEDQA mood DONE
```

### 27. zedqa_ring_squares.lua (`ZEDQA rs`) - PASS, 12 s

- go 14067 at 01:19:11
- screenshots: zqa_rs_belt_full.png, zqa_rs_belt_70_45.png, zqa_rs_belt_15.png, zqa_rs_squares_on.png, zqa_rs_squares_off.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA rs start
:	[ZeD.QA] run #27 ok=true
:	ZEDQA rs belt at 1342,2041, hands: s 0,0 91 | p 969,0 91
:	ZEDQA rs PASS full: both hands on the belt
:	ZEDQA rs PASS full: the conditions read 1.00 / 1.00
:	ZEDQA rs belt at 1342,2041, hands: s 0,0 91 | p 969,0 91
:	ZEDQA rs PASS 70_45: both hands on the belt
:	ZEDQA rs PASS 70_45: the conditions read 0.70 / 0.50
:	ZEDQA rs belt at 1342,2041, hands: s 0,0 91 | p 969,0 91
:	ZEDQA rs PASS 15: both hands on the belt
:	ZEDQA rs PASS 15: the conditions read 0.20 / 0.20
:	ZEDQA rs window at 294,0 1617x735
:	ZEDQA rs PASS on: theme, accent, text and R squares in the footer
:	ZEDQA rs PASS off: the switch reads off
:	ZEDQA rs PASS off: no theme, accent or text square
:	ZEDQA rs PASS off: R stays, at the left where the theme square was
:	ZEDQA rs PASS off: the pointer over R lights R (hover 4)
:	ZEDQA rs PASS off: a press on R puts the windows back (1 press)
:	ZEDQA rs PASS on: the pointer over the theme square lights it (hover 1)
:	ZEDQA rs all checks passed
:	ZEDQA rs DONE
```

### 28. zedqa_sandbox_ig.lua (`ZEDQA sbx`) - PASS, 19 s

- go 14068 at 01:19:29
- screenshots: zqa_sbx_pause_line.png, zqa_sbx_time.png, zqa_sbx_world_help.png, zqa_sbx_zombie_changed.png, zqa_sbx_ask_apply.png, zqa_sbx_applied.png, zqa_sbx_history.png, zqa_sbx_pad.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA sbx start
:	[ZeD.QA] run #28 ok=true
:	ZEDQA sbx PASS the pause window is up
:	ZEDQA sbx PASS switch off: no Sandbox options line
:	ZEDQA sbx PASS switch on: the Sandbox options line is there
:	ZEDQA sbx PASS the window is open over the paused game
:	ZEDQA sbx pages: Time, Zombie, Loot, World, Nature, Meta, Character, Vehicles, Livestock, More Builds, Military Grid Reference System (FMCCYAYFGLE), Spawn Selector, PZ TrueMoozic, PZ True Moozic Debug, PZ TrueMoozic - Holiday, Neat Lockpicking, Radio Frequency Manager, More Item Information, Better Safehouse, Better Safehouse - Custom, Better Safehouse - Extra, Better Safehouse - Expansion, GPS Companion (projectzomboidmap.com), Pager Network, Pager Tower (Only Applies to Ultra Realistic), Civil Defense Sirens, Plysken Attachments Reborn, Mod Auto Tailoring, Place Anywhere, Washing Menus Improved, More menu options, True Music Jukebox, Jukebox Therapy, Jukebox Nutrition, True Music Radio, Auto All, Better Corpse Burning, Whose Key Is This?, Area Tasks, Palm Pilots, Night Vision Chucked, Sandbox_Advanced_trajectory, Sandbox_Advanced_trajectory_debug, Sandbox_Advanced_trajectory_damage, Sandbox_Advanced_trajectory_XP, Sandbox_Advanced_trajectory_hitOrMiss, Sandbox_Advanced_trajectory_recoil, Sandbox_Advanced_trajectory_movement, Sandbox_Advanced_trajectory_shotgun, Sandbox_Advanced_trajectory_moodles, Sandbox_Advanced_trajectory_crosshair, Common Sense, Helicopter Events, World Ping System, TooltipLib - Shared Tooltip Library, Bushcraft Gear - Rare Weapons, Undead Survivor, Military Ponchos - Aky, KATTAJ1 Military Pack, Guns of Marz, Sandbox_MWPWeapons, Gun Stock Attack Options, Legendary Backpack, Sandbox_TheyKnew, Better Flashlights, Zombies Drop Ammo, Vanilla Firearms Expansion, VFE - Attachments, VFE - Ammo, Mod TchernoLib, Video Game Consoles, Sandbox_sts, KYR Real Weather, [B42] Survival, Bandits General, Plysken Solar Revolution, Immersive Blackouts: Settings, Immersive Blackouts: Water, Immersive Blackouts: Electricity, SaucedCarts - Pushable Carts, Extended Electricity, Immersive Solar Arrays, Playable Pool, Over the Shoulder, Stay With Me, Roaming Survivors, Sandbox_SleepWithFriends, Items Renaming Options, Skully's Zombie Collision, MFS 1 - Firearm Spawn Switches (Off Removes Type from New Loot), MFS 2 - Individual Firearm Rates (0 = Off, 1 = Default), MFS 3 - Firearm and Attachment Loot, MFS 4 - Gameplay Settings, CDDA Zombies' Spawn Rate, Skateboard, Companion Dogs, Brita Armor - Compatibility, Night Vision Framework, Zombie Dismemberment, Blood Pools & Footprints, Wash or Rot, ZeD-GUI, Changed, History
:	ZEDQA sbx PASS vanilla's pages plus Changed and History (104)
:	ZEDQA sbx PASS every setting has a row (1628)
:	ZEDQA sbx PASS nothing marked changed on opening
:	ZEDQA sbx PASS the help band has room
:	ZEDQA sbx PASS Start Month is fixed (locked)
:	ZEDQA sbx PASS a fixed setting does not change
:	ZEDQA sbx PASS the World page starts with the world's day
:	ZEDQA sbx world line: This world is on day 5 of the count the shut-offs use. Water: on until day 23. Power: on until day 26.
:	ZEDQA sbx PASS Zombie Count and Population Multiplier rows
:	ZEDQA sbx PASS Zombie Count Low sets Population Multiplier to 0.15 (0.15)
:	ZEDQA sbx PASS two settings marked changed (2)
:	ZEDQA sbx PASS Undo changes puts both back
:	ZEDQA sbx PASS four changes marked (4)
:	ZEDQA sbx PASS nothing applied before Apply
:	ZEDQA sbx PASS Apply asks first
:	ZEDQA sbx PASS the question shows the Changed page
:	ZEDQA sbx ask: Apply 4 changes to this save? Can't be undone: 1.
:	ZEDQA sbx PASS FoodRotSpeed applied (3 > 4)
:	ZEDQA sbx PASS HoursForCorpseRemoval applied (216.0 > 100.0)
:	ZEDQA sbx PASS FireSpread applied (true > false)
:	ZEDQA sbx PASS DayLength applied (4 > 5)
:	ZEDQA sbx PASS SandboxVars has the new number (100)
:	ZEDQA sbx PASS the clock took the new day length (90 > 120)
:	ZEDQA sbx PASS History has the apply
:	ZEDQA sbx PASS nothing marked changed after Apply
:	ZEDQA sbx strip: Apply 4 changes to this save? Can't be undone: 1.
:	ZEDQA sbx PASS History lists the four with Put back (4)
:	ZEDQA sbx PASS Put back marks four changes (4)
:	ZEDQA sbx PASS FoodRotSpeed back to 3
:	ZEDQA sbx PASS HoursForCorpseRemoval back to 216.0
:	ZEDQA sbx PASS FireSpread back to true
:	ZEDQA sbx PASS DayLength back to 4
:	ZEDQA sbx PASS the day's length back (90)
:	ZEDQA sbx PASS the D-pad lands on a row
:	ZEDQA sbx prompts: <> A LB RB B
:	ZEDQA sbx PASS the footer shows the pad's buttons
:	ZEDQA sbx PASS History as it was
:	ZEDQA sbx all checks passed
:	ZEDQA sbx DONE
```

### 29. zedqa_twoway.lua (`ZEDQA tw`) - PASS, 52 s

- go 14069 at 01:19:54
- screenshots: zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA tw start
:	[ZeD.QA] run #29 ok=true
:	ZEDQA tw screen 3840x2160, root scale 1.75, plate zoom 2
:	ZEDQA tw PASS walkie_valutech: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_valutech: its own face, walkie_valutech (got walkie_valutech)
:	ZEDQA tw PASS walkie_valutech: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_valutech: centred in its panel (x 20, want 20)
:	ZEDQA tw PASS walkie_valutech: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_valutech: all 6 controls on the face (6)
:	ZEDQA tw PASS walkie_valutech: the full view button in the header
:	ZEDQA tw PASS walkie_valutech: VOL pressed turns it on
:	ZEDQA tw PASS walkie_valutech: the display reads while on
:	ZEDQA tw walkie_valutech: display 092.600 | TRUE MUSIC RADIO | BAT 3
:	ZEDQA tw PASS walkie_valutech: BAT with 3 bars at 60% charge
:	ZEDQA tw valutech: body 599 px tall, the face's body needs 799 (window 735)
:	ZEDQA tw PASS valutech: at the default height the body scrolls
:	ZEDQA tw PASS valutech: the wheel off the knobs scrolls the body (0 -> 0.05)
:	ZEDQA tw PASS valutech: the grown window shows the whole face, no scrollbar
:	ZEDQA tw PASS VOL: the wheel turns the volume up (0.50 -> 0.60)
:	ZEDQA tw PASS TUNE: a click on its right half tunes up a step (92600 -> 92800)
:	ZEDQA tw PASS TUNE: its left half tunes down a step
:	ZEDQA tw PASS TUNE: a right-click turns it down
:	ZEDQA tw PASS MEM: stores the frequency as channel 01 (1 stored)
:	ZEDQA tw PASS the display shows CH 01 (01)
:	ZEDQA tw PASS MEM: a second channel stored
:	ZEDQA tw PASS CH down walks to channel 01
:	ZEDQA tw PASS CH up walks to channel 02
:	ZEDQA tw PASS the mic starts muted
:	ZEDQA tw PASS the TX lamp is dark while the mic is muted
:	ZEDQA tw PASS PUSH TO TALK latches the mic live
:	ZEDQA tw PASS the TX lamp lights and the display says TX OK (TX OK)
:	ZEDQA tw PASS pressed again it mutes the mic (MIC OFF)
:	ZEDQA tw PASS MEM held (right-click): the naming box opens
:	ZEDQA tw PASS naming it: channel 02 is QA Farm
:	ZEDQA tw PASS the header button opens full view on the radio
:	ZEDQA tw PASS full view is the face alone, no window frame
:	ZEDQA tw PASS full view is the plate at the plate scale (408x728)
:	ZEDQA tw PASS the first time it sits centre right of the play area (centre x 2880)
:	ZEDQA tw PASS every control is on it (6)
:	ZEDQA tw PASS a control in full view works (CH down)
:	ZEDQA tw PASS MEM held in full view opens the naming box
:	ZEDQA tw PASS the face's edge is not a control
:	ZEDQA tw PASS dragging the face moves full view (2676 -> 2276)
:	ZEDQA tw PASS the place is kept on the character
:	ZEDQA tw PASS the header button closes full view
:	ZEDQA tw PASS the point between the knobs is no control
:	ZEDQA tw PASS a click on the face away from the controls opens full view
:	ZEDQA tw PASS it opens where it was dragged to
:	ZEDQA tw PASS B closes full view
:	ZEDQA tw PASS Escape closes full view
:	ZEDQA tw PASS full view closes when the radio leaves the hands
:	ZEDQA tw PASS pad: the face's VOL is a stop in the tab
:	ZEDQA tw PASS pad: up on VOL turns it up
:	ZEDQA tw PASS pad: right from VOL walks to TUNE (radio:tw:tune)
:	ZEDQA tw PASS pad: A on CH up steps the channel
:	ZEDQA tw PASS pad: X on MEM opens the naming box
:	ZEDQA tw PASS pad: A on the full view button opens it
:	ZEDQA tw PASS pad: full view shows its controller strip
:	ZEDQA tw PASS pad: full view lands on a control (vol)
:	ZEDQA tw PASS pad: down on VOL in full view turns it down
:	ZEDQA tw PASS pad: right walks to TUNE in full view (tune)
:	ZEDQA tw PASS pad: A on PUSH TO TALK in full view latches the mic
:	ZEDQA tw PASS pad: B closes full view
:	ZEDQA tw PASS walkie_toy: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_toy: its own face, walkie_toy (got walkie_toy)
:	ZEDQA tw PASS walkie_toy: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_toy: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_toy: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_toy: all 3 controls on the face (3)
:	ZEDQA tw PASS walkie_toy: the full view button in the header
:	ZEDQA tw PASS walkie_toy: VOL pressed turns it on
:	ZEDQA tw PASS walkie_toy: the display reads while on
:	ZEDQA tw walkie_toy: display 94.20 MHZ | nil | nil nil
:	ZEDQA tw PASS toy: no memories, its TALK button
:	ZEDQA tw PASS toy: the drum shows the frequency
:	ZEDQA tw PASS walkie_premium: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_premium: its own face, walkie_premium (got walkie_premium)
:	ZEDQA tw PASS walkie_premium: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_premium: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_premium: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_premium: all 6 controls on the face (6)
:	ZEDQA tw PASS walkie_premium: the full view button in the header
:	ZEDQA tw PASS walkie_premium: VOL pressed turns it on
:	ZEDQA tw PASS walkie_premium: the display reads while on
:	ZEDQA tw walkie_premium: display 089.400 | HITZ FM | BAT 3
:	ZEDQA tw PASS walkie_premium: BAT with 3 bars at 60% charge
:	ZEDQA tw PASS walkie_tactical: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_tactical: its own face, walkie_tactical (got walkie_tactical)
:	ZEDQA tw PASS walkie_tactical: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_tactical: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_tactical: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_tactical: all 9 controls on the face (9)
:	ZEDQA tw PASS walkie_tactical: the full view button in the header
:	ZEDQA tw PASS walkie_tactical: VOL pressed turns it on
:	ZEDQA tw PASS walkie_tactical: the display reads while on
:	ZEDQA tw walkie_tactical: display 094.200 | USR | BAT 3
:	ZEDQA tw PASS walkie_tactical: BAT with 3 bars at 60% charge
:	ZEDQA tw PASS Tactical: MUTE silences it
:	ZEDQA tw PASS Tactical: MUTE again gives the sound back
:	ZEDQA tw PASS Tactical: SCAN runs
:	ZEDQA tw PASS Tactical: SCAN again stops it
:	ZEDQA tw PASS Tactical: LAMP lights the display
:	ZEDQA tw PASS Tactical: the lamp goes out after 5 s
:	ZEDQA tw PASS walkie_army: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_army: its own face, walkie_army (got walkie_army)
:	ZEDQA tw PASS walkie_army: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_army: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_army: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_army: all 9 controls on the face (9)
:	ZEDQA tw PASS walkie_army: the full view button in the header
:	ZEDQA tw PASS walkie_army: VOL pressed turns it on
:	ZEDQA tw PASS walkie_army: the display reads while on
:	ZEDQA tw walkie_army: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | BAT 3
:	ZEDQA tw PASS walkie_army: BAT with 3 bars at 60% charge
:	ZEDQA tw PASS walkie_makeshift: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_makeshift: its own face, walkie_makeshift (got walkie_makeshift)
:	ZEDQA tw PASS walkie_makeshift: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_makeshift: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_makeshift: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_makeshift: all 6 controls on the face (6)
:	ZEDQA tw PASS walkie_makeshift: the full view button in the header
:	ZEDQA tw PASS walkie_makeshift: VOL pressed turns it on
:	ZEDQA tw PASS walkie_makeshift: the display reads while on
:	ZEDQA tw walkie_makeshift: display CH-- 92.80 | TRUE MUSIC RADIO | nil nil
:	ZEDQA tw PASS makeshift: its character display reads CH.. (CH-- 92.80)
:	ZEDQA tw PASS walkie_manpack: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_manpack: its own face, walkie_manpack (got walkie_manpack)
:	ZEDQA tw PASS walkie_manpack: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_manpack: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_manpack: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_manpack: all 7 controls on the face (7)
:	ZEDQA tw PASS walkie_manpack: the full view button in the header
:	ZEDQA tw PASS walkie_manpack: VOL pressed turns it on
:	ZEDQA tw PASS walkie_manpack: the display reads while on
:	ZEDQA tw walkie_manpack: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | BAT 3
:	ZEDQA tw PASS walkie_manpack: BAT with 3 bars at 60% charge
:	ZEDQA tw PASS ManPack: on the back
:	ZEDQA tw PASS an AM/FM radio still shows the chassis
:	ZEDQA tw 7 free squares in reach
:	ZEDQA tw placed 3 ham sets
:	ZEDQA tw PASS the World window's Radio tab opens on the placed sets
:	ZEDQA tw PASS ham_civilian: its own face, ham_civilian (got ham_civilian)
:	ZEDQA tw PASS ham_civilian: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_civilian: centred across the drawer (x 20, want 20)
:	ZEDQA tw PASS ham_civilian: the drawer holds the whole set (840 px for 800)
:	ZEDQA tw PASS ham_civilian: all 8 controls on the face (8)
:	ZEDQA tw PASS ham_civilian: the full view button in the header
:	ZEDQA tw PASS ham_civilian: VOL pressed turns it on
:	ZEDQA tw ham_civilian: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | range RANGE 7.5 KM
:	ZEDQA tw PASS ham_civilian: the display reads while on
:	ZEDQA tw PASS the drawer's clip is set and cleared in pairs with a ham showing (20 sets, 20 clears)
:	ZEDQA tw PASS civilian ham: RANGE matches its transmit range (RANGE 7.5 KM)
:	ZEDQA tw PASS civilian ham: the band marker follows the frequency up
:	ZEDQA tw PASS civilian ham: full view opens
:	ZEDQA tw PASS ham_civilian on a small screen: its narrow face (ham_civilian_n)
:	ZEDQA tw PASS ham_civilian: the tab is a walkie's width (465 px, want 465)
:	ZEDQA tw PASS ham_civilian: the narrow face at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_civilian: every control of the wide set on the narrow face (8)
:	ZEDQA tw PASS ham_civilian: VOL on the narrow face turns it on
:	ZEDQA tw PASS ham_civilian: TUNE on the narrow face tunes up a step
:	ZEDQA tw PASS ham_civilian: the narrow face's display reads
:	ZEDQA tw PASS ham_army on a small screen: its narrow face (ham_army_n)
:	ZEDQA tw PASS ham_army: the tab is a walkie's width (465 px, want 465)
:	ZEDQA tw PASS ham_army: the narrow face at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_army: every control of the wide set on the narrow face (14)
:	ZEDQA tw PASS ham_army: VOL on the narrow face turns it on
:	ZEDQA tw PASS ham_army: TUNE on the narrow face tunes up a step
:	ZEDQA tw PASS ham_army: the narrow face's display reads
:	ZEDQA tw PASS ham_makeshift on a small screen: its narrow face (ham_makeshift_n)
:	ZEDQA tw PASS ham_makeshift: the tab is a walkie's width (465 px, want 465)
:	ZEDQA tw PASS ham_makeshift: the narrow face at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_makeshift: every control of the wide set on the narrow face (7)
:	ZEDQA tw PASS ham_makeshift: VOL on the narrow face turns it on
:	ZEDQA tw PASS ham_makeshift: TUNE on the narrow face tunes up a step
:	ZEDQA tw PASS ham_makeshift: the narrow face's display reads
:	ZEDQA tw PASS narrow makeshift ham: TALK / LISTEN flips with the mic
:	ZEDQA tw PASS with room again the wide set is back
:	ZEDQA tw PASS ham_army: its own face, ham_army (got ham_army)
:	ZEDQA tw PASS ham_army: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_army: centred across the drawer (x 20, want 20)
:	ZEDQA tw PASS ham_army: the drawer holds the whole set (840 px for 800)
:	ZEDQA tw PASS ham_army: all 14 controls on the face (14)
:	ZEDQA tw PASS ham_army: the full view button in the header
:	ZEDQA tw PASS ham_army: VOL pressed turns it on
:	ZEDQA tw ham_army: display 098.600 | | range RANGE 20 KM
:	ZEDQA tw PASS ham_army: the display reads while on
:	ZEDQA tw PASS army ham: tuned away
:	ZEDQA tw PASS army ham: 1 goes straight to memory 1
:	ZEDQA tw PASS army ham on the grid: AC, the bars dark (AC)
:	ZEDQA tw PASS ham_makeshift: its own face, ham_makeshift (got ham_makeshift)
:	ZEDQA tw PASS ham_makeshift: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_makeshift: centred across the drawer (x 20, want 20)
:	ZEDQA tw PASS ham_makeshift: the drawer holds the whole set (840 px for 800)
:	ZEDQA tw PASS ham_makeshift: all 7 controls on the face (7)
:	ZEDQA tw PASS ham_makeshift: the full view button in the header
:	ZEDQA tw PASS ham_makeshift: VOL pressed turns it on
:	ZEDQA tw ham_makeshift: display CH-- 092.600 MHZ | TRUE MUSIC RADIO | range RANGE 6 KM
:	ZEDQA tw PASS ham_makeshift: the display reads while on
:	ZEDQA tw PASS makeshift ham: the TALK / LISTEN toggle flips with the mic
:	ZEDQA tw PASS makeshift ham: full view opens
:	ZEDQA tw PASS full view closes when the set is taken away
:	ZEDQA tw cleanup: 3 sets and 8 items taken away
:	ZEDQA tw 185 passed, 0 failed
:	ZEDQA tw all checks passed
:	ZEDQA tw DONE
```

### 30. zedqa_appliances.lua (`ZEDQA ap`) - PASS, 27 s

- go 14070 at 01:20:52
- screenshots: zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA ap start
:	[ZeD.QA] run #30 ok=true
:	ZEDQA ap no room in reach of 12031,11756: to the Fossoil at West Point
:	ZEDQA ap indoors at 12059,7122
:	ZEDQA ap placed: stove true, microwave true
:	ZEDQA ap PASS the stove opens in the Craft tab
:	ZEDQA ap stove powered true (grid power on the square true, object index 1, world power true)
:	ZEDQA ap PASS stove: the station is the one opened
:	ZEDQA ap PASS stove: the World window is on its Craft tab
:	ZEDQA ap stove: plate oven_modern 456x128, tab 941 px, want 941, zoom in the tab 2 (the screen's 2)
:	ZEDQA ap PASS stove: the plate draws at the screen's whole zoom in the tab
:	ZEDQA ap PASS stove: the tab has the pop-out button
:	ZEDQA ap PASS the pop-out window is up
:	ZEDQA ap pop-out 1208,782 1424x594, zoom 3 (the screen's 2)
:	ZEDQA ap PASS the pop-out is centred on the screen
:	ZEDQA ap PASS the pop-out's plate is at least the tab's size
:	ZEDQA ap PASS the pop-out is on screen
:	ZEDQA ap PASS the pop-out has the plate's controls (15)
:	ZEDQA ap PASS the tab says it is in its own window and offers it back
:	ZEDQA ap pressed broil
:	ZEDQA ap stove heat 200 -> 300
:	ZEDQA ap PASS a control pressed in the pop-out moves the stove's own setting
:	ZEDQA ap PASS Bring it back closes the window
:	ZEDQA ap PASS the plate is back in the tab
:	ZEDQA ap PASS the microwave opens in the Craft tab
:	ZEDQA ap PASS microwave: the station is the one opened
:	ZEDQA ap PASS microwave: the World window is on its Craft tab
:	ZEDQA ap microwave: plate mw_white 456x168, tab 941 px, want 941, zoom in the tab 2 (the screen's 2)
:	ZEDQA ap PASS microwave: the plate draws at the screen's whole zoom in the tab
:	ZEDQA ap PASS microwave: the tab has the pop-out button
:	ZEDQA ap PASS the microwave pops out too
:	ZEDQA ap cleanup: 2 appliances removed, station released
:	ZEDQA ap back at 12031,11756
:	ZEDQA ap all checks passed
:	ZEDQA ap DONE
```

### 31. zedqa_seat_lightbar_vanilla.lua (`ZEDQA sl`) - FAIL, 22 s

- go 14071 at 01:21:24
- 2 Java exception(s) in the log
- screenshots: zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA sl start
:	[ZeD.QA] run #31 ok=true
ERROR: General f:35837> Lua(Vanilla).CheckSwap> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.inventory.InventoryItem.setAlcoholPower(float)" because "item" is null at Item.InstanceItem(Item.java:1849).
    Lua(Vanilla).CheckSwap(ProfessionVehicles.lua:314)
    Lua(Vanilla).spawn(Apocalypse.lua:30)
    Lua(Vanilla).at(Apocalypse.lua:65)
    Lua(Vanilla).t(Apocalypse.lua:120)
ERROR: General f:35837> Lua(Vanilla).spawn> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.inventory.InventoryItem.setAlcoholPower(float)" because "item" is null at Item.InstanceItem(Item.java:1849).
    Lua(Vanilla).spawn(Apocalypse.lua:30)
    Lua(Vanilla).at(Apocalypse.lua:66)
    Lua(Vanilla).t(Apocalypse.lua:120)
:	ZEDQA sl pickup=BaseVehicle{ Name:null, ID:29 } police=BaseVehicle{ Name:null, ID:30 } van=nil
:	ZEDQA sl enter Base.PickUpTruck dist=4.2 physics=true
:	ZEDQA sl enter Base.CarLightsKST dist=8.6 physics=true
:	ZEDQA sl lightbar x=1705 y=940 w=430 h=280
:	ZEDQA sl DONE
```

### 32. zedqa_car_radio_build.lua (`ZEDQA rb`) - PASS, 35 s

- go 14072 at 01:21:53
- screenshots: zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA rb start
:	[ZeD.QA] run #32 ok=true
:	ZEDQA rb spawned Base.PickUpTruck beside the character
:	ZEDQA rb spawned Base.CarLightsPolice beside the character
:	ZEDQA rb Base.PickUpTruck radio=Base.RadioBlack
:	ZEDQA rb Base.ModernCarLightsMeadeSheriff radio=Base.HamRadio1
:	ZEDQA rb dash only kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=89200 vol=1 preset=1 name=KERS Infrastructure signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=89.2 KERS Infrastructure; 2=93.2 LBMW - Kentucky Radio; 3=98.0 NNR Radio; 4=101.2 KnoxTalk Radio; 5=92.8 True Music Radio; 6=89.4 Hitz FM; 7=94.2 USR]
:	ZEDQA rb prop visible=nil at nil,nil nilxnil vanilla window=false
:	ZEDQA rb premium off kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=89200 vol=1 preset=1 name=KERS Infrastructure signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=89.2 KERS Infrastructure; 2=93.2 LBMW - Kentucky Radio; 3=98.0 NNR Radio; 4=101.2 KnoxTalk Radio; 5=92.8 True Music Radio; 6=89.4 Hitz FM; 7=94.2 USR]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb premium power via vanilla's action ok=true canBePoweredHere=true battery=0.8569599986076355
:	ZEDQA rb premium on kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=4 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=89.2 KERS Infrastructure; 2=93.2 LBMW - Kentucky Radio; 3=98.0 NNR Radio; 4=101.2 KnoxTalk Radio; 5=92.8 True Music Radio; 6=89.4 Hitz FM; 7=94.2 USR]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb store 4 -> 4
:	ZEDQA rb premium stored kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=4 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=STORE 4 mic=false
:	ZEDQA rb presets [1=89.2 KERS Infrastructure; 2=93.2 LBMW - Kentucky Radio; 3=98.0 NNR Radio; 4=101.2 KnoxTalk Radio; 5=92.8 True Music Radio; 6=89.4 Hitz FM; 7=94.2 USR]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb cds carried: 0
:	ZEDQA rb insert ok=true
:	ZEDQA rb cd in kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=4 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=89.2 KERS Infrastructure; 2=93.2 LBMW - Kentucky Radio; 3=98.0 NNR Radio; 4=101.2 KnoxTalk Radio; 5=92.8 True Music Radio; 6=89.4 Hitz FM; 7=94.2 USR]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb play ok=false
:	ZEDQA rb cd playing kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=4 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=89.2 KERS Infrastructure; 2=93.2 LBMW - Kentucky Radio; 3=98.0 NNR Radio; 4=101.2 KnoxTalk Radio; 5=92.8 True Music Radio; 6=89.4 Hitz FM; 7=94.2 USR]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb eject ok=false
:	ZEDQA rb ejected kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=4 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=89.2 KERS Infrastructure; 2=93.2 LBMW - Kentucky Radio; 3=98.0 NNR Radio; 4=101.2 KnoxTalk Radio; 5=92.8 True Music Radio; 6=89.4 Hitz FM; 7=94.2 USR]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb fit Base.RadioBlack ok=true nil
:	ZEDQA rb valutech kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=98000 vol=0.6000000238418579 preset=3 name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=89.2 KERS Infrastructure; 2=93.2 LBMW - Kentucky Radio; 3=98.0 NNR Radio; 4=101.2 KnoxTalk Radio; 5=92.8 True Music Radio; 6=89.4 Hitz FM; 7=94.2 USR]
:	ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
:	ZEDQA rb fit Base.RadioMakeShift ok=true nil
:	ZEDQA rb makeshift kind=makeshift item=Base.RadioMakeShift on=true switch=true powered=true ch=89400 vol=0.6000000238418579 preset=6 name=Hitz FM signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=89.2 KERS Infrastructure; 2=93.2 LBMW - Kentucky Radio; 3=98.0 NNR Radio; 4=101.2 KnoxTalk Radio; 5=92.8 True Music Radio; 6=89.4 Hitz FM; 7=94.2 USR]
:	ZEDQA rb prop visible=true at 1828,1536 880x256 vanilla window=false
:	ZEDQA rb fit Base.RadioBlack ok=true nil
:	ZEDQA rb pickup restored kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=98000 vol=0.6000000238418579 preset=3 name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=89.2 KERS Infrastructure; 2=93.2 LBMW - Kentucky Radio; 3=98.0 NNR Radio; 4=101.2 KnoxTalk Radio; 5=92.8 True Music Radio; 6=89.4 Hitz FM; 7=94.2 USR]
:	ZEDQA rb prop visible=false at 1828,1536 880x256 vanilla window=false
:	ZEDQA rb ham power via vanilla's action ok=true canBePoweredHere=true battery=0.983989953994751
:	ZEDQA rb ham kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=3 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=112.2 Unseasonal Weather Network; 2=89.4 Hitz FM; 3=98.4 Automated Emergency Broadcast System; 4=89.2 KERS Infrastructure]
:	ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
:	ZEDQA rb ham mic off kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=3 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=true
:	ZEDQA rb presets [1=112.2 Unseasonal Weather Network; 2=89.4 Hitz FM; 3=98.4 Automated Emergency Broadcast System; 4=89.2 KERS Infrastructure]
:	ZEDQA rb prop visible=true at 1708,1480 1000x312 vanilla window=false
:	ZEDQA rb mem -> 5
:	ZEDQA rb ham mem kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=146600 vol=1 preset=5 name=nil signal=false media=false playing=false title=nil flash=CH 05 STORED mic=false
:	ZEDQA rb presets [1=112.2 Unseasonal Weather Network; 2=89.4 Hitz FM; 3=98.4 Automated Emergency Broadcast System; 4=89.2 KERS Infrastructure; 5=146.6 146.600 MHz]
:	ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
:	ZEDQA rb siren opened; radio still up = false
:	ZEDQA rb fit Base.HamRadio2 ok=true nil
:	ZEDQA rb army kind=army item=Base.HamRadio2 on=true switch=true powered=true ch=98400 vol=1 preset=3 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=112.2 Unseasonal Weather Network; 2=89.4 Hitz FM; 3=98.4 Automated Emergency Broadcast System; 4=89.2 KERS Infrastructure; 5=146.6 146.600 MHz]
:	ZEDQA rb prop visible=true at 1708,1492 1000x300 vanilla window=false
:	ZEDQA rb fit Base.HamRadioMakeShift ok=true nil
:	ZEDQA rb hammake kind=hammake item=Base.HamRadioMakeShift on=true switch=true powered=true ch=98000 vol=1 preset=nil name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=112.2 Unseasonal Weather Network; 2=89.4 Hitz FM; 3=98.4 Automated Emergency Broadcast System; 4=89.2 KERS Infrastructure; 5=146.6 146.600 MHz]
:	ZEDQA rb prop visible=true at 1708,1516 1000x276 vanilla window=false
:	ZEDQA rb fit Base.HamRadio1 ok=true nil
:	ZEDQA rb police restored kind=ham item=Base.HamRadio1 on=false switch=false powered=true ch=107600 vol=1 preset=nil name=nil signal=false media=false playing=false title=nil flash=nil mic=false
:	ZEDQA rb presets [1=112.2 Unseasonal Weather Network; 2=89.4 Hitz FM; 3=98.4 Automated Emergency Broadcast System; 4=89.2 KERS Infrastructure]
:	ZEDQA rb prop visible=false at 1708,1516 1000x276 vanilla window=false
:	ZEDQA rb DONE
```

### 33. zedqa_car_radio_cd.lua (`ZEDQA cd`) - PASS, 16 s

- go 14073 at 01:22:33
- screenshots: zqa_cd_c01_cdlist.png, zqa_cd_c02_cd_playing.png, zqa_cd_c03_ejected.png, zqa_cd_c04_valutech_tape.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA cd start
:	[ZeD.QA] run #33 ok=true
:	ZEDQA cd spawned Base.PickUpTruck beside the character
:	ZEDQA cd pickup BaseVehicle{ Name:null, ID:35 } radio=Base.RadioBlack
:	ZEDQA cd hand font height 17
:	ZEDQA cd vanilla CD recordings: 69
:	ZEDQA cd cd isRecordedMedia=true mediaType=0 name=CD: I Need You More
:	ZEDQA cd cds carried: 0
:	ZEDQA cd inserted kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
:	ZEDQA cd play ok=false
:	ZEDQA cd playing kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
:	ZEDQA cd eject ok=false
:	ZEDQA cd ejected kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
:	ZEDQA cd disc back in inventory: true
:	ZEDQA cd fit Base.RadioBlack
:	ZEDQA cd valutech kind=valutech on=false ch=101200 media=false playing=false title=nil cdMs=nil
:	ZEDQA cd fit Base.RadioRed
:	ZEDQA cd DONE
```

### 34. zedqa_dash_props_smoke.lua (`ZEDQA sm`) - PASS, 9 s

- go 14074 at 01:22:56
- screenshots: zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA sm start
:	[ZeD.QA] run #34 ok=true
:	ZEDQA sm spawned Base.PickUpTruck beside the character
:	ZEDQA sm spawned Base.CarLightsPolice beside the character
:	ZEDQA sm pickup=true police=true
:	ZEDQA sm dash visible=true design=d6
:	ZEDQA sm radio up=true
:	ZEDQA sm siren up=true dash design=police
:	ZEDQA sm ham radio up=true
:	ZEDQA sm DONE
```

### 35. zedqa_tm.lua (`ZEDQA tm`) - PASS, 8 s

- go 14075 at 01:23:11
- screenshots: zedqa_tm_tooltips.png, zedqa_tm_maps.png, zedqa_tm_dash.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA tm armed
:	[ZeD.QA] run #35 ok=true
:	ZEDQA tm root=1.75 proxy=true realTM=true
:	ZEDQA tm tip1 462.78125x223.7421875 at 300,300 desc=349.78125x136.59375 lines=4 font=MainMenu1
:	ZEDQA tm tip2 420x194.890625 at 300,620 desc=367x194.890625 lines=6 font=MainMenu1
:	ZEDQA tm watch family=nil size=228x52 at 3596,10
:	ZEDQA tm maps tab clicked maps
:	ZEDQA tm world tabs loot,craft,build,furniture,maps,forage,animals,vehicle
:	ZEDQA tm maps shot active=maps win=1929,0 1682x735
:	ZEDQA tm dash design=horizon visible=true size=1600x344 at 1120,1804
:	ZEDQA tm done
```

### 36. zedqa_tour3.lua (`ZEDQA t3`) - PASS, 19 s

- go 14076 at 01:23:25
- screenshots: zedqa_t3_SmallCar02.png, zedqa_t3_ModernCar.png, zedqa_t3_ModernCar02.png, zedqa_t3_SUV.png, zedqa_t3_Van.png, zedqa_t3_PickUpVan.png, zedqa_t3_OffRoad.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #36 ok=true
:	ZEDQA t3 SmallCar02 design=horizon visible=true hits=21 badge=nil/nil cluster=nil
:	ZEDQA t3 ModernCar design=dashelite visible=true hits=29 badge=nil/nil cluster=nil
:	ZEDQA t3 ModernCar02 design=primani visible=true hits=26 badge=nil/nil cluster=nil
:	ZEDQA t3 SUV design=suv visible=true hits=22 badge=nil/nil cluster=nil
:	ZEDQA t3 Van design=van visible=true hits=21 badge=nil/nil cluster=nil
:	ZEDQA t3 PickUpVan design=bulldriver visible=true hits=22 badge=nil/nil cluster=nil
:	ZEDQA t3 OffRoad design=rancher visible=true hits=25 badge=nil/nil cluster=nil
:	ZEDQA t3 done
```

### 37. zedqa_dash19.lua (`ZEDQA dash`) - FAIL, 106 s

- go 14077 at 01:23:50
- 4 Java exception(s) in the log
- 2 ERR line(s)
- screenshots: zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #37 ok=true
:	ZEDQA dash 01_luxury design=luxury rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 02_nyala design=nyala rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 03_cossette design=cossette rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 04_police design=police rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 05_d6 design=d6 rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 06_dashelite design=dashelite rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 07_primani design=primani rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 08_dart design=dart rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 09_horizon design=horizon rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 10_wagon design=wagon rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 11_suv design=suv rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 12_van design=van rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 13_bulldriver design=bulldriver rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 14_rancher design=rancher rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 15_taxi design=taxi rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash 16_ambulance design=ambulance rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ERROR: General f:46892> Lua(Vanilla).t> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.inventory.InventoryItem.setAlcoholPower(float)" because "item" is null at Item.InstanceItem(Item.java:1849).
    Lua(Vanilla).t(Apocalypse.lua:31)
    Lua(Vanilla).tick(Apocalypse.lua:73)
:	ZEDQA dash 17_fire spawn failed Base.PickUpTruckLightsFire
ERROR: General f:47152 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: isEngineRunning of non-table: null
ERROR: General f:47152> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: isEngineRunning of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(Apocalypse.lua:59)
    Lua(Vanilla).t(Apocalypse.lua:59)
    Lua(Vanilla).tick(Apocalypse.lua:73)
:	ZEDQA dash 17_fire design=ambulance rect=1120,1804,1600,344 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ERROR: General f:47197> Lua(Vanilla).t> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.inventory.InventoryItem.setAlcoholPower(float)" because "item" is null at Item.InstanceItem(Item.java:1849).
    Lua(Vanilla).t(Apocalypse.lua:31)
    Lua(Vanilla).tick(Apocalypse.lua:73)
:	ZEDQA dash 18_ranger spawn failed Base.CarLightsRanger
ERROR: General f:47457 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: isEngineRunning of non-table: null
ERROR: General f:47457> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: isEngineRunning of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(Apocalypse.lua:59)
    Lua(Vanilla).t(Apocalypse.lua:59)
    Lua(Vanilla).tick(Apocalypse.lua:73)
:	ZEDQA dash 18_ranger design=ambulance rect=1120,1804,1600,344 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ERROR: General f:47502 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"   (x2)
:	ZEDQA dash 19_race design=race rect=1120,1804,1600,344 running=true radio=false heat=true lights=true badge=nil/nil screen=3840x2160
:	ZEDQA dash DONE
```

### 38. zedqa_dashpx.lua (`ZEDQA dpx`) - FAIL, 102 s

- go 14078 at 01:25:42
- 49 Java exception(s) in the log
- 2 ERR line(s)
- the script ran twice (re-bump)
- late output from pre (4 line(s), not counted)
- late output from pf (11 line(s), not counted)
- late output from ts (6 line(s), not counted)
- late output from pr (40 line(s), not counted)
- late output from fi (7 line(s), not counted)
- late output from props (2 line(s), not counted)
- late output from belt (2 line(s), not counted)
- late output from straps (17 line(s), not counted)
- late output from bk (7 line(s), not counted)
- late output from bks (35 line(s), not counted)
- late output from bw (10 line(s), not counted)
- late output from bh (18 line(s), not counted)
- late output from watches (20 line(s), not counted)
- late output from cb (6 line(s), not counted)
- late output from ct (34 line(s), not counted)
- late output from cc (8 line(s), not counted)
- late output from bg (5 line(s), not counted)
- late output from ws (9 line(s), not counted)
- late output from wh (17 line(s), not counted)
- late output from dw (73 line(s), not counted)
- late output from pg (35 line(s), not counted)
- late output from qc (57 line(s), not counted)
- late output from pb (28 line(s), not counted)
- late output from fv (13 line(s), not counted)
- late output from msg (27 line(s), not counted)
- late output from mood (51 line(s), not counted)
- late output from rs (20 line(s), not counted)
- late output from sbx (45 line(s), not counted)
- late output from tw (204 line(s), not counted)
- late output from ap (34 line(s), not counted)
- late output from sl (6 line(s), not counted)
- late output from rb (69 line(s), not counted)
- late output from cd (17 line(s), not counted)
- late output from sm (9 line(s), not counted)
- late output from tm (10 line(s), not counted)
- late output from t3 (8 line(s), not counted)
- late output from dash (22 line(s), not counted)
- no DONE
- the game dropped to the main menu during this script
- screenshots: zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #38 ok=true
:	ZEDQA dpx 01_luxury design=luxury rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=MERCIA LANG 4000 livery= make=MERCIA model=LANG 4000 unit=MERCIA - UNIT 82 hits=27 screen=3840x2160
:	ZEDQA dpx 02_nyala design=nyala rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER NYALA livery= make=CHEVALIER model=NYALA unit=CHEVALIER - UNIT 82 hits=22 screen=3840x2160
:	ZEDQA dpx 03_cossette design=cossette rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER COSSETTE livery= make=CHEVALIER model=COSSETTE unit=CHEVALIER - UNIT 82 hits=22 screen=3840x2160
:	ZEDQA dpx 04_police design=police rect=1120,1804,1600,344 k=2 running=true radio=true/ham heat=true lights=true name=MEADE SHERIFF DASH ELITE livery=MEADE SHERIFF make=DASH model=ELITE unit=SHERIFF - UNIT 82 hits=19 screen=3840x2160
:	ZEDQA dpx 05_d6 design=d6 rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=CHEVALIER D6 livery= make=CHEVALIER model=D6 unit=CHEVALIER - UNIT 82 hits=26 screen=3840x2160
:	ZEDQA dpx 06_dashelite design=dashelite rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=DASH ELITE livery= make=DASH model=ELITE unit=DASH - UNIT 82 hits=29 screen=3840x2160
ERROR: General f:50772> Lua(Vanilla).t> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.inventory.InventoryItem.setAlcoholPower(float)" because "item" is null at Item.InstanceItem(Item.java:1849).
    Lua(Vanilla).t(Apocalypse.lua:39)
    Lua(Vanilla).tick(Apocalypse.lua:95)
:	ZEDQA dpx 07_primani spawn failed Base.ModernCar02
:	ZEDQA dpx 08_dart design=dart rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER DART livery= make=CHEVALIER model=DART unit=CHEVALIER - UNIT 85 hits=21 screen=3840x2160
:	ZEDQA dpx 09_horizon design=horizon rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=MASTERSON HORIZON livery= make=MASTERSON model=HORIZON unit=MASTERSON - UNIT 85 hits=25 screen=3840x2160
:	ZEDQA dpx 10_wagon design=wagon rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER CERISE WAGON livery= make=CHEVALIER model=CERISE WAGON unit=CHEVALIER - UNIT 85 hits=22 screen=3840x2160
:	ZEDQA dpx 11_suv design=suv rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=FRANKLIN ALL-TERRAIN livery= make=FRANKLIN model=ALL-TERRAIN unit=FRANKLIN - UNIT 85 hits=22 screen=3840x2160
:	ZEDQA dpx 12_van design=van rect=1120,1804,1600,344 k=2 running=true radio=true/premium heat=true lights=true name=SPIFFO VAN livery=SPIFFO VAN make=FRANKLIN model=VALULINE unit=SPIFFO - UNIT 85 hits=25 screen=3840x2160
    LOG  : Lua          f:53387> :	ZEDQA dpx 13_bulldriver design=bulldriver rect=1120,1804,1600,344 k=2 running=true radio=true/valutech heat=true lights=true name=DASH BULLDRIVER livery= make=DASH model=BULLDRIVER unit=DASH - UNIT 85 hits=22 screen=3840x2160
[ZeD.QA] bridge armed (main menu, poll every 30 ticks)
[ZeD.QA] autoload: continuing the latest save
ERROR: General f:0 at KahluaThread.flushErrorMessage > expected argument of type ItemBodyLocation, got String
ERROR: General f:0> Lua((MOD:They Knew [B42])).TheyKnew_BodyLocations.lua> Exception thrown
    java.lang.RuntimeException: expected argument of type ItemBodyLocation, got String at MethodArguments.assertValid(MethodArguments.java:128).
    Lua((MOD:They Knew [B42])).TheyKnew_BodyLocations.lua(TheyKnew_BodyLocations.lua:3)
ERROR: General f:0> 20 | 贝雷塔护甲全修复版)).verifyValue> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in verifyValue at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Brita's Armor Pack B42.20 | 贝雷塔护甲全修复版)).verifyValue(BritasArmorPackB42Fix.lua:37)
    Lua((MOD:Brita's Armor Pack B42.20 | 贝雷塔护甲全修复版)).verifyContainerInstance(BritasArmorPackB42Fix.lua:52)
    Lua((MOD:Brita's Armor Pack B42.20 | 贝雷塔护甲全修复版)).setContainerSlot(BritasArmorPackB42Fix.lua:152)
    Lua((MOD:Brita's Armor Pack B42.20 | 贝雷塔护甲全修复版)).BritasArmorPackB42Fix.lua(BritasArmorPackB42Fix.lua:506)
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_InitialWaterPercent"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_SkypeRingChance"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_CassetteSpawnRate"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_CassetteSpawnRate_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_CDSpawnRate"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_CDSpawnRate_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_CDScratchCleanChance_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_CassetteCaseSpawnRate"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_CassetteCaseSpawnRate_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_VinylSpawn"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_VinylSpawn_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_VinylPlayerSpawn"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_VinylPlayerSpawn_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_WalkmanSpawn"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_WalkmanSpawn_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_BoomboxSpawn"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_BoomboxSpawn_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_PZTrueMusicSandbox_ZombieWalkmanSpawnRate"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_NeatLockpicking_ReinforcedYellowHitValue"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = '.' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_NeatLockpicking_ReinforcedYellowHitValue_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_NeatLockpicking_ReinforcedGreenHitValue"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = '.' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_NeatLockpicking_ReinforcedGreenHitValue_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_NeatLockpicking_CrowbarProgressDecayAmount"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = '.' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_NeatLockpicking_CrowbarProgressDecayAmount_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = 'l' at Formatter$FormatSpecifier.conversion(null:-1). Message: ERROR: Formatting "Sandbox_NeatLockpicking_PinResistanceEnabled_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_CivilDefenseSirens_StormChance"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "Sandbox_CivilDefenseSirens_GlobalMinVolume"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.MissingFormatArgumentException: Format specifier '% f' at Formatter.format(null:-1). Message: ERROR: Missing arguments for "Sandbox_SleepGasRadius_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = 'i' at Formatter$FormatSpecifier.conversion(null:-1). Message: ERROR: Formatting "Sandbox_ISA_solarPanelEfficiency_tooltip"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "IGUI_CivilDefenseSirens_Volume"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "IGUI_HTT_Opt_EventVolume"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "IGUI_HTT_Opt_RotorVolume"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "IGUI_HTT_Opt_EffectVolume"
:	[ZeD.QA] bridge armed (main menu, poll every 30 ticks)
ERROR: General f:0> Lua((MOD:Voiced Radio and Tvs)).Init> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in Init at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Voiced Radio and Tvs)).Init(ISWeatherChannel.lua:62)
    Lua((MOD:Voiced Radio and Tvs)).OnLoadRadioScripts(ISWeatherChannel.lua:92)
ERROR: Lua f:0 at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "IGUI_CivilDefenseSirens_Volume"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "IGUI_HTT_Opt_EventVolume"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "IGUI_HTT_Opt_RotorVolume"
WARN : General f:0> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1). Message: ERROR: Formatting "IGUI_HTT_Opt_EffectVolume"
:	[ZeD.QA] bridge armed (in game, poll every 30 ticks)
:	[ZeD.QA] ZeD-QA: the whole map known (0,0 to 20000,17000) true
:	[ZeD.QA] windows reset (R)
:	ZEDQA pre start   (late output from pre)
:	[ZeD.QA] run #1 ok=true
:	ZEDQA pre char true world true speed 1 ticks 60 frames 61   (late output from pre)
:	ZEDQA pre search overlay: enabled false, override false, manager false   (late output from pre)
:	ZEDQA pre DONE   (late output from pre)
:	[ZeD.QA] windows reset (R)
:	ZEDQA pf start   (late output from pf)
:	[ZeD.QA] run #2 ok=true
:	ZEDQA pf KnoxKnews_July1 element_23 y 470->376 room 509 scale 0.40->0.64 h 247   (late output from pf)
:	ZEDQA pf KnoxKnews_July1 element_25 y 700->686 room 184 scale 0.40->0.64 h 106 head 0.80->1.09   (late output from pf)
:	ZEDQA pf KnoxKnews_July2 element_23 y 470->376 room 509 scale 0.40->0.64 h 221   (late output from pf)
:	ZEDQA pf KnoxKnews_July2 element_25 y 700->686 room 184 scale 0.40->0.64 h 106 head 0.80->1.09   (late output from pf)
:	ZEDQA pf KnoxKnews_July2 element_27 y 700->686 room 184 scale 0.40->0.64 h 106 head 0.80->1.09   (late output from pf)
:	ZEDQA pf KentuckyHerald_July6 element_15 y 395->396 room 330 scale 0.45->0.64 h 157   (late output from pf)
:	ZEDQA pf KentuckyHerald_July6 element_18 y 415->416 room 310 scale 0.45->0.64 h 144   (late output from pf)
:	ZEDQA pf NationalDispatch_July6 element_16 y 339->322 room 453 scale 0.40->0.64 h 259   (late output from pf)
:	ZEDQA pf NationalDispatch_July6 element_21 y 240->227 room 573 scale 0.40->0.64 h 323   (late output from pf)
:	ZEDQA pf DONE   (late output from pf)
:	[ZeD.QA] windows reset (R)
:	ZEDQA ts start   (late output from ts)
:	[ZeD.QA] run #3 ok=true
:	ZEDQA ts KnoxKnews_July1 stories 3 body 27.884615384615387 lines 58   (late output from ts)
:	ZEDQA ts KnoxKnews_July2 stories 3 body 26.884615384615387 lines 53   (late output from ts)
:	ZEDQA ts KentuckyHerald_July6 stories 2 body 30.153615384615385 lines 43   (late output from ts)
:	ZEDQA ts NationalDispatch_July6 stories 5 body 23.076923076923077 lines 77   (late output from ts)
:	ZEDQA ts DONE   (late output from ts)
:	[ZeD.QA] windows reset (R)
:	ZEDQA pr start   (late output from pr)
:	[ZeD.QA] run #4 ok=true
:	ZEDQA pr sleep Type=ZeD_Prompt kind=question x=1659 y=965 w=526 h=232 visible=false top=false   (late output from pr)
:	ZEDQA pr mouse 1922,1081   (late output from pr)
:	ZEDQA pr answer sleep internal=NO parentKind=question entry=nil   (late output from pr)
:	ZEDQA pr kill Type=ZeD_Prompt kind=question x=1659 y=965 w=526 h=232 visible=false top=false   (late output from pr)
:	ZEDQA pr kill costly=true   (late output from pr)
:	ZEDQA pr kill after No Type=ZeD_Prompt kind=question x=1659 y=965 w=526 h=232 visible=false top=false   (late output from pr)
:	ZEDQA pr note Type=ZeD_Prompt kind=note x=1578 y=964 w=683 h=232 visible=false top=false   (late output from pr)
:	ZEDQA pr answer note internal=OK parentKind=note entry=nil   (late output from pr)
:	ZEDQA pr after Escape: note visible=false pause=false   (late output from pr)
:	ZEDQA pr rename bag Fanny Pack   (late output from pr)
:	ZEDQA pr rename Type=ZeD_Prompt kind=text x=1624 y=949 w=595 h=262 visible=false top=false   (late output from pr)
:	ZEDQA pr empty: yes.enable=false why=Can't be empty.   (late output from pr)
:	ZEDQA pr long: yes.enable=false why=Character limit: 12   (late output from pr)
:	ZEDQA pr keyboard Type=ISOnScreenKeyboard zed=true IsVisible=false   (late output from pr)
:	ZEDQA pr keyboard Type=ISOnScreenKeyboard kind=nil x=1429 y=1224 w=984 h=371 visible=false top=false   (late output from pr)
:	ZEDQA pr rename under keyboard Type=ZeD_Prompt kind=text x=1624 y=948 w=595 h=262 visible=true top=true   (late output from pr)
:	ZEDQA pr typed: Go Bags! current=Go Bags!   (late output from pr)
:	ZEDQA pr after keyboard cancel: Go Bag kbVisible=false   (late output from pr)
:	ZEDQA pr rename OK kept name=true   (late output from pr)
:	ZEDQA pr alarm Type=ZeD_Prompt kind=alarm x=1657 y=878 w=525 h=402 visible=false top=false   (late output from pr)
:	ZEDQA pr alarm after pad: 7:20 on=false focus=tick   (late output from pr)
:	ZEDQA pr alarm synced 7:20 on=false   (late output from pr)
:	ZEDQA pr timer Type=ZeD_Prompt kind=timer x=1657 y=936 w=525 h=286 visible=false top=false   (late output from pr)
:	ZEDQA pr timer answer OK time=35   (late output from pr)
:	ZEDQA pr help Type=ZeD_Prompt kind=rich x=1435 y=755 w=770 h=648 visible=false top=false   (late output from pr)
:	ZEDQA pr help blocks=5 contentH=486.67578125 maxScroll=0   (late output from pr)
:	ZEDQA pr help after OK visible=false   (late output from pr)
:	ZEDQA pr forget Type=ZeD_Prompt kind=rich x=1582 y=965 w=679 h=232 visible=false top=false   (late output from pr)
:	ZEDQA pr forget costly=false   (late output from pr)
:	ZEDQA pr answer forget internal=NO parentKind=rich entry=nil   (late output from pr)
:	ZEDQA pr subclass build ok=true kind=nil Type=ISConfirmMonitorSettings   (late output from pr)
:	ZEDQA pr open prompts left=0   (late output from pr)
:	ZEDQA pr gp focus=yes   (late output from pr)
:	ZEDQA pr gp after left focus=no   (late output from pr)
:	ZEDQA pr answer gp sleep internal=NO parentKind=question entry=nil   (late output from pr)
:	ZEDQA pr gp text focus=field   (late output from pr)
:	ZEDQA pr answer gp rename internal=CANCEL parentKind=text entry=Duffel Bag   (late output from pr)
:	ZEDQA pr gp open prompts left=0   (late output from pr)
:	ZEDQA pr DONE   (late output from pr)
:	[ZeD.QA] windows reset (R)
:	ZEDQA fi start   (late output from fi)
:	[ZeD.QA] run #5 ok=true
:	ZEDQA fi 1_slack tension -0.6 vanilla angle -62   (late output from fi)
:	ZEDQA fi 2_light tension 0.15 vanilla angle -32   (late output from fi)
:	ZEDQA fi 3_tight tension 0.4 vanilla angle -2   (late output from fi)
:	ZEDQA fi 4_strain tension 0.72 vanilla angle 36.39999999999999   (late output from fi)
:	ZEDQA fi 5_limit tension 0.96 vanilla angle 65.19999999999999   (late output from fi)
:	ZEDQA fi DONE   (late output from fi)
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #6 ok=true
:	ZEDQA props draw rod true/true slack true clock true/true   (late output from props)
:	ZEDQA props DONE   (late output from props)
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #7 ok=true
:	ZEDQA belt textures true   (late output from belt)
:	ZEDQA belt shot; DONE   (late output from belt)
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #8 ok=true
:	ZEDQA straps put aside 2   (late output from straps)
:	ZEDQA straps civilian worn HolsterSimple_Brown,Belt2,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,VisionBoost   (late output from straps)
:	ZEDQA straps civilian slots Back=sling HolsterRight=holster_brown SmallBeltLeft=leather SmallBeltRight=leather Back2=leather BritaBeltFront=leather BritaBeltBack=leather | waist=leather closure=buckle   (late output from straps)
:	ZEDQA straps civilian shot   (late output from straps)
:	ZEDQA straps military worn Holster_DuctTape,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICEpack_Army,Bag_ALICE_BeltSus_Camo,VisionBoost   (late output from straps)
:	ZEDQA straps military slots Back=webbing_olive HolsterRight=holster_tape SmallBeltLeft=webbing_camo SmallBeltRight=webbing_camo Back2=leather BedrollBottomALICE=webbing_olive WebbingRight=webbing_camo WebbingLeft=webbing_camo | waist=webbing_camo closure=clip_black   (late output from straps)
:	ZEDQA straps military shot   (late output from straps)
:	ZEDQA straps makeshift worn Holster_Hide,RopeBelt,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_CraftedFramepack_Large,VisionBoost   (late output from straps)
:	ZEDQA straps makeshift slots Back=rope HolsterRight=holster_hide SmallBeltLeft=rope Back2=leather BedrollBottom=rope | waist=rope closure=knot   (late output from straps)
:	ZEDQA straps makeshift shot   (late output from straps)
:	ZEDQA straps firefighter worn Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,SCBA,VisionBoost   (late output from straps)
:	ZEDQA straps firefighter slots Back=harness SmallBeltLeft=harness Back2=leather SmallBeltRight=harness WebbingLeft=harness | waist=harness closure=clip_black   (late output from straps)
:	ZEDQA straps firefighter shot   (late output from straps)
:	ZEDQA straps olive worn Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICE_BeltSus,VisionBoost   (late output from straps)
:	ZEDQA straps olive slots Back=sling SmallBeltLeft=webbing_olive Back2=leather SmallBeltRight=webbing_olive WebbingLeft=webbing_olive WebbingRight=webbing_olive | waist=webbing_olive closure=clip_brass   (late output from straps)
:	ZEDQA straps olive shot   (late output from straps)
:	ZEDQA straps restored; DONE   (late output from straps)
:	[ZeD.QA] windows reset (R)
:	ZEDQA bk start   (late output from bk)
:	[ZeD.QA] run #9 ok=true
:	ZEDQA bk centre 1920 vs screen 1920 | belt x 1342 w 1141 | delta 0 | bare watch none   (late output from bk)
:	ZEDQA bk worn zwatchslots:leftwatch   (late output from bk)
:	ZEDQA bk centre 1920 vs screen 1920 | belt x 1240 w 1243 | delta 0 | cazio watch digital_black wrist left   (late output from bk)
:	ZEDQA bk worn zwatchslots:rightwatch   (late output from bk)
:	ZEDQA bk centre 1920 vs screen 1920 | belt x 1342 w 1243 | delta 0 | timez watch timez_easy wrist right   (late output from bk)
:	ZEDQA bk DONE   (late output from bk)
:	[ZeD.QA] windows reset (R)
:	ZEDQA bks professions 32   (late output from bks)
:	ZEDQA bks start   (late output from bks)
:	[ZeD.QA] run #10 ok=true
:	ZEDQA bks 01 burgerflipper buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 02 repairman buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 03 burglar buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 04 engineer buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 05 fisherman buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 06 policeofficer buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 07 lumberjack buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 08 smither buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 09 farmer buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 10 electrician buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 11 fireofficer buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 12 metalworker buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 13 fitnessinstructor buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 14 veteran buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 15 tailor buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 16 chef buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 17 doctor buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 18 parkranger buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 19 unemployed buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 20 nurse buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 21 securityguard buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 22 carpenter buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 23 mechanics buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 24 rancher buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 25 constructionworker buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 26 priest buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 27 soldier buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 28 mailman buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 29 ascetic buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 30 paramedic buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 31 hunter buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks 32 convict buckle=1862,2046,116,80   (late output from bks)
:	ZEDQA bks DONE (profession back to unemployed)   (late output from bks)
:	[ZeD.QA] windows reset (R)
:	ZEDQA bw start   (late output from bw)
:	[ZeD.QA] run #11 ok=true
:	ZEDQA bw worn zwatchslots:leftwatch   (late output from bw)
:	ZEDQA bw box digital_black wrist left x 0 w 88 | hands s@102 p@1071 | belt w 1243   (late output from bw)
:	ZEDQA bw full watch tucked: 0x0   (late output from bw)
:	ZEDQA bw popped true at 1240,1674 248x352 | mini at 1240,2040   (late output from bw)
:	ZEDQA bw dragged to 1500,500 saved 857.1428571428571,285.7142857142857   (late output from bw)
:	ZEDQA bw after idle: popped true size 248   (late output from bw)
:	ZEDQA bw right wrist: timez_easy wrist right x 1074 | hands s@0 p@969   (late output from bw)
:	ZEDQA bw corner: box false full watch 3524,10 300x352   (late output from bw)
:	ZEDQA bw DONE   (late output from bw)
:	[ZeD.QA] windows reset (R)
:	ZEDQA bh start   (late output from bh)
:	[ZeD.QA] run #12 ok=true
:	ZEDQA bh PASS left wrist: the boxes run left to right (watch@0 OFF@102 #1@232 #2@328 #3@424 #4@520 #5@763 #6@859 #7@955 MAIN@1071 lamp@1176)   (late output from bh)
:	ZEDQA bh PASS left wrist: the off hand at the left end, the main hand at the right, the slots between   (late output from bh)
:	ZEDQA bh PASS left wrist: the Messages note is last on the right   (late output from bh)
:	ZEDQA bh PASS left wrist: the watch is left of the off hand   (late output from bh)
:	ZEDQA bh PASS left wrist: the full watch pops at the left end (left)   (late output from bh)
:	ZEDQA bh PASS pad: the belt starts on slot 1 (#1)   (late output from bh)
:	ZEDQA bh PASS pad: Left from slot 1 is the off hand (OFF)   (late output from bh)
:	ZEDQA bh PASS right wrist: the boxes run left to right (OFF@0 #1@130 #2@226 #3@322 #4@418 #5@661 #6@757 #7@853 MAIN@969 watch@1074 lamp@1176)   (late output from bh)
:	ZEDQA bh PASS right wrist: the off hand at the left end, the main hand at the right, the slots between   (late output from bh)
:	ZEDQA bh PASS right wrist: the Messages note is last on the right   (late output from bh)
:	ZEDQA bh PASS right wrist: the watch is right of the main hand   (late output from bh)
:	ZEDQA bh PASS right wrist: the full watch pops at the right end (right)   (late output from bh)
:	ZEDQA bh PASS as worn: the boxes run left to right (OFF@0 #1@130 #2@226 #3@322 #4@418 #5@661 #6@757 #7@853 MAIN@969 lamp@1074)   (late output from bh)
:	ZEDQA bh PASS as worn: the off hand at the left end, the main hand at the right, the slots between   (late output from bh)
:	ZEDQA bh PASS as worn: the Messages note is last on the right   (late output from bh)
:	ZEDQA bh all checks passed   (late output from bh)
:	ZEDQA bh DONE   (late output from bh)
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #13 ok=true
:	ZEDQA watches own watch nil at nil   (late output from watches)
:	ZEDQA watches no own watch; location zwatchslots:leftwatch   (late output from watches)
:	ZEDQA watches item left true right true   (late output from watches)
:	ZEDQA watches name 'Digital Watch - Steel Sport Style' icon C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\textures\Item_ZeDWatchTimezSteel.png world Base.ZeDDigitalWatchSteel clothing true/WristWatch_Left_DigitalTimez digital true class true   (late output from watches)
:	ZEDQA watches DigitalBlack plate digital_black size 248x352 at 3576,10 hits alarm,light,set,speed,start   (late output from watches)
:	ZEDQA watches DigitalDress plate digital_gold size 248x352 at 3576,10 hits alarm,light,set,speed,start   (late output from watches)
:	ZEDQA watches DigitalRed plate timez_red size 248x352 at 3576,10 hits alarm,light,set,speed,start   (late output from watches)
:	ZEDQA watches DigitalTimez plate timez_steel size 248x352 at 3576,10 hits alarm,light,set,speed,start   (late output from watches)
:	ZEDQA watches ClassicBlack plate classic_black size 300x352 at 3524,10 hits alarm,crown,light,set,speed,start   (late output from watches)
:	ZEDQA watches ClassicGold plate classic_gold size 300x352 at 3524,10 hits alarm,crown,light,set,speed,start   (late output from watches)
:	ZEDQA watches ClassicBrown plate timez_easy size 300x352 at 3524,10 hits crown,light,speed,start   (late output from watches)
:	ZEDQA watches ClassicMilitary plate timez_camper size 300x352 at 3524,10 hits crown,light,speed,start   (late output from watches)
:	ZEDQA watches Expensive plate expensive size 300x352 at 3524,10 hits crown,speed,start   (late output from watches)
:	ZEDQA watches setting open true hits alarm,light,set,setdn,setup,speed,start   (late output from watches)
:	ZEDQA watches after + + armed true hour 1   (late output from watches)
:	ZEDQA watches night dark=true   (late output from watches)
:	ZEDQA watches DigitalTimez lit=true   (late output from watches)
:	ZEDQA watches ClassicBrown lit=true   (late output from watches)
:	ZEDQA watches light out: lit=false dark=true   (late output from watches)
:	ZEDQA watches restored own watch nil; DONE   (late output from watches)
:	[ZeD.QA] windows reset (R)
:	ZEDQA cb start   (late output from cb)
:	[ZeD.QA] run #14 ok=true
:	ZEDQA cb no pickup in the loaded cell; spawned one beside the character: true   (late output from cb)
:	ZEDQA cb bed selected true   (late output from cb)
:	ZEDQA cb world list 651x664, row 49 at y 615   (late output from cb)
:	ZEDQA cb campfire selected true   (late output from cb)
:	ZEDQA cb DONE   (late output from cb)
:	[ZeD.QA] windows reset (R)
:	ZEDQA ct start   (late output from ct)
:	[ZeD.QA] run #15 ok=true
:	ZEDQA ct no pickup in the loaded cell; spawned one beside the character: true   (late output from ct)
:	ZEDQA ct pickup true   (late output from ct)
:	ZEDQA ct bed selected true   (late output from ct)
:	ZEDQA ct your row: Transfer all, Same type, Same type, all nearby   (late output from ct)
:	ZEDQA ct world row: Take all, Same type, To floor   (late output from ct)
:	ZEDQA ct start: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0   (late output from ct)
:	ZEDQA ct focused worldCtl:same prompt Take the kinds you already carry   (late output from ct)
:	ZEDQA ct marked rows (things) 7   (late output from ct)
:	ZEDQA ct no button Same type   (late output from ct)
:	ZEDQA ct after Same type (take): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0   (late output from ct)
:	ZEDQA ct no button Same type   (late output from ct)
:	ZEDQA ct after Same type (back): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0   (late output from ct)
:	ZEDQA ct no button Take all   (late output from ct)
:	ZEDQA ct after Take all: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0   (late output from ct)
:	ZEDQA ct no button Transfer all   (late output from ct)
:	ZEDQA ct after Transfer all: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0   (late output from ct)
:	ZEDQA ct no button To floor   (late output from ct)
:	ZEDQA ct after To floor: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0   (late output from ct)
:	ZEDQA ct floor selected true   (late output from ct)
:	ZEDQA ct floor row: Take all(off), Same type(off)   (late output from ct)
:	ZEDQA ct no button Take all   (late output from ct)
:	ZEDQA ct after Take all (floor): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0   (late output from ct)
:	ZEDQA ct no button Transfer all   (late output from ct)
:	ZEDQA ct after Transfer all (back to the bed): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 0   (late output from ct)
:	ZEDQA ct campfire placed true true   (late output from ct)
:	ZEDQA ct campfire container true selected true   (late output from ct)
:	ZEDQA ct campfire row: Take all, Same type(off), To floor, |, Take apart, Light, Add fuel   (late output from ct)
:	ZEDQA ct no button Add fuel   (late output from ct)
:	ZEDQA ct after Add fuel: object card false jump nil   (late output from ct)
:	ZEDQA ct no button Take apart   (late output from ct)
:	ZEDQA ct after Take apart: campfire still there true   (late output from ct)
:	ZEDQA ct restored: bag nails 0 planks 0 | bed nails 0 planks 0 beans 0, 2 things | floor -1   (late output from ct)
:	ZEDQA ct DONE   (late output from ct)
:	[ZeD.QA] windows reset (R)
:	ZEDQA cc start   (late output from cc)
:	[ZeD.QA] run #16 ok=true
:	ZEDQA cc no pickup in the loaded cell; spawned one beside the character: true   (late output from cc)
:	ZEDQA cc pickup true bed part TruckBedOpen   (late output from cc)
:	ZEDQA cc truck bed true dist 1.0   (late output from cc)
:	ZEDQA cc world window on the truck bed (1)   (late output from cc)
:	ZEDQA cc char 1134,0 777x735 world 1929,0 777x735   (late output from cc)
:	ZEDQA cc vanilla inv 640,0 1280x720 loot 1920,0 1280x720   (late output from cc)
:	ZEDQA cc DONE   (late output from cc)
:	[ZeD.QA] windows reset (R)
:	ZEDQA bg start   (late output from bg)
:	[ZeD.QA] run #17 ok=true
:	ZEDQA bg no pickup in the loaded cell; spawned one beside the character: true   (late output from bg)
:	ZEDQA bg pickup true shirt true   (late output from bg)
:	ZEDQA bg card open true   (late output from bg)
:	ZEDQA bg DONE   (late output from bg)
:	[ZeD.QA] windows reset (R)
:	ZEDQA ws no pickup within 20 tiles; spawned one beside the character: true   (late output from ws)
:	[ZeD.QA] run #18 ok=true
:	ZEDQA ws a_gun3 n=3 r=49 w=600   (late output from ws)
:	ZEDQA ws b_dright3 n=8 r=74 w=650   (late output from ws)
:	ZEDQA ws c_emotes5 n=6 r=57 w=616   (late output from ws)
:	ZEDQA ws d_signal9 n=9 r=83 w=668   (late output from ws)
:	ZEDQA ws e_back10 n=10 r=92 w=686   (late output from ws)
:	ZEDQA ws g_car11 n=12 r=110 w=722   (late output from ws)
:	ZEDQA ws h_car11pt n=12 r=110 w=722   (late output from ws)
:	ZEDQA ws done   (late output from ws)
:	[ZeD.QA] windows reset (R)
:	ZEDQA wh no pickup within 20 tiles; spawned one beside the character: true   (late output from wh)
:	ZEDQA wh start car=BaseVehicle{ Name:null, ID:11 } pistol=nil torch=Base.HandTorch:zombie.inventory.types.DrainableComboItem@5bd6f104   (late output from wh)
:	[ZeD.QA] run #19 ok=true
:	ZEDQA wh outside zed=true java=UIElement n=0 x=1559 y=719 w=722 vis=false point=-1 title=nil |   (late output from wh)
:	ZEDQA wh inside zed=true java=UIElement n=11 x=1568 y=728 w=704 vis=false point=-1 title=nil | 1:Switch Seat 2:Turn Headlights on 3:Turn AC/Heater on 4:Horn 5:Device Options 6:Open Window 7:Lock all doors 8:Vehicle Mechanics 9:Not tired enough to sleep.[off] 10:Exit Vehicle 11:Use Cassette Player   (late output from wh)
:	ZEDQA wh pick test slice3 from mouse -> 3   (late output from wh)
:	ZEDQA wh emotes zed=true java=UIElement n=6 x=1612 y=772 w=616 vis=false point=-1 title=nil | 1:Friendly 2:Hostile 3:Group 4:Signal 5:Shout 6:Dance   (late output from wh)
:	ZEDQA wh press towards 4 (Signal)   (late output from wh)
:	ZEDQA wh signal zed=true java=UIElement n=9 x=1586 y=746 w=668 vis=true point=-1 title=Signal | 1:Cease Fire 2:Ok 3:Move Out 4:Freeze 5:Follow Behind 6:Fire 7:Come 8:Salute 9:Back   (late output from wh)
:	ZEDQA wh gun zed=true java=UIElement n=9 x=1586 y=746 w=668 vis=false point=2 title=Signal | 1:Cease Fire 2:Ok 3:Move Out 4:Freeze 5:Follow Behind 6:Fire 7:Come 8:Salute 9:Back   (late output from wh)
:	ZEDQA wh light zed=true java=UIElement n=2 x=1620 y=780 w=600 vis=false point=-1 title=nil | 1:Flashlight/Unequip 2:Flashlight/Turn on   (late output from wh)
:	ZEDQA wh back zed=true java=UIElement n=10 x=1577 y=737 w=686 vis=false point=-1 title=nil | 1:Base theme/Dark 2:Accent color/Purple 3:Text size/Small 4:UI scale 5:Moodles/Right edge 6:Action bar/Verbose 7:Messages/3 new 8:Reset windows/Both windows, as the footer's R 9:ZeD setup/Options, on ZeD's page 10:Safe mode/The game's own interface   (late output from wh)
:	ZEDQA wh dright zed=true java=UIElement n=8 x=1595 y=755 w=650 vis=false point=-1 title=nil | 1:Tabs/World window 2:Map 3:Vehicle/No vehicle in reach.[off] 4:Animal/No tame animal in reach.[off] 5:Craft and build 6:Search 7:Lights and power/No lights or power in reach.[off] 8:Designated Zones/Animals   (late output from wh)
:	ZEDQA wh zone route: world=true vanillaZone=false   (late output from wh)
:	ZEDQA wh zone tab showing=true   (late output from wh)
:	ZEDQA wh search route: forage showing=true vanillaSearch=false   (late output from wh)
:	ZEDQA wh player info route: char=true vanillaInfo=false   (late output from wh)
:	ZEDQA wh DONE   (late output from wh)
:	[ZeD.QA] windows reset (R)
:	ZEDQA dw start   (late output from dw)
:	[ZeD.QA] run #20 ok=true
:	ZEDQA dw scene: at 12031,11756, in a car false, health 100   (late output from dw)
:	ZEDQA dw foot left: 8 slices, crumb Character, visible false | 1:Tabs / Character window [>] 2:Weapons [>] 3:Eat [>] 4:Drink / Nothing to drink on you. [off] 5:Medicine and first aid / Nothing to treat, no medicine on you. [off] 6:Sleep / Not tired enough to sleep. [off] 7:Clothing / Nothing you wear can change. [off] 8:Use / Smoke | Read | Watch | Radio [>]   (late output from dw)
:	ZEDQA dw PASS left: the top level has its slices (8, 9 on ZeD)   (late output from dw)
:	ZEDQA dw PASS left: the slice 'Tabs' is there   (late output from dw)
:	ZEDQA dw inner left: 9 slices, crumb Character › Tabs, visible true | 1:Loot 2:Equipment 3:Health 4:Thermal 5:Identity 6:Journal 7:Skills 8:Radio / No radio in your hands or on your back. [off] 9:Back   (late output from dw)
:	ZEDQA dw PASS left: the inner wheel ends with Back   (late output from dw)
:	ZEDQA dw PASS left: the breadcrumb names the inner wheel   (late output from dw)
:	ZEDQA dw PASS left: B from the inner wheel is back on the top level   (late output from dw)
:	ZEDQA dw PASS left: B on the top level closes the wheel   (late output from dw)
:	ZEDQA dw foot right: 8 slices, crumb World, visible false | 1:Tabs / World window [>] 2:Map [>] 3:Vehicle / No vehicle in reach. [off] 4:Animal / No tame animal in reach. [off] 5:Craft and build [>] 6:Search [>] 7:Lights and power / No lights or power in reach. [off] 8:Designated Zones / Animals   (late output from dw)
:	ZEDQA dw PASS right: the top level has its slices (8, 9 on ZeD)   (late output from dw)
:	ZEDQA dw PASS right: the slice 'Map' is there   (late output from dw)
:	ZEDQA dw inner right: 4 slices, crumb World › Map, visible true | 1:Show/Hide World Map 2:Show/Hide Mini-Map / The mini-map is off in this game. [off] 3:Focus Mini Map / The mini-map is off in this game. [off] 4:Back   (late output from dw)
:	ZEDQA dw PASS right: the inner wheel ends with Back   (late output from dw)
:	ZEDQA dw PASS right: the breadcrumb names the inner wheel   (late output from dw)
:	ZEDQA dw PASS right: B from the inner wheel is back on the top level   (late output from dw)
:	ZEDQA dw PASS right: B on the top level closes the wheel   (late output from dw)
:	ZEDQA dw foot up: 8 slices, crumb Social, visible false | 1:Friendly [>] 2:Hostile [>] 3:Group [>] 4:Signal [>] 5:Shout 6:Chat / On a server only. [off] 7:Safety / On a server only. [off] 8:Players / On a server only. [off]   (late output from dw)
:	ZEDQA dw PASS up: the top level has its slices (8, 9 on ZeD)   (late output from dw)
:	ZEDQA dw PASS up: the slice 'Friendly' is there   (late output from dw)
:	ZEDQA dw inner up: 6 slices, crumb Social › Friendly, visible true | 1:Wave Hi 2:Bye 3:Clap 4:Thumbs Up 5:Thank You 6:Back   (late output from dw)
:	ZEDQA dw PASS up: the inner wheel ends with Back   (late output from dw)
:	ZEDQA dw PASS up: the breadcrumb names the inner wheel   (late output from dw)
:	ZEDQA dw PASS up: B from the inner wheel is back on the top level   (late output from dw)
:	ZEDQA dw PASS up: B on the top level closes the wheel   (late output from dw)
... (794 more lines; see console.txt)
```

### 39. zedqa_exinfo.lua (`ZEDQA ex`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 40. zedqa_charinfo.lua (`ZEDQA ci`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 41. zedqa_equipdrag.lua (`ZEDQA eqd`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 42. zedqa_cazio_light.lua (`ZEDQA czl`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 43. zedqa_dashnight.lua (`ZEDQA dnt`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 44. zedqa_testlang.lua (`ZEDQA tlang`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 45. zedqa_safemode.lua (`ZEDQA safe`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 46. zedqa_soak.lua (`ZEDQA soak`) - SKIP, not run

- not run: the game dropped to the main menu during this script

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
    1x ERROR: General f:N> Lua((MOD:They Knew [B42])).TheyKnew_BodyLocations.lua> Exception thrown  :: java.lang.RuntimeException: expected argument of type ItemBodyLocation, got String at MethodArguments.assertValid(MethodArguments.java:128).
    1x ERROR: General f:N> 20 | 贝雷塔护甲全修复版)).verifyValue> Exception thrown  :: java.lang.RuntimeException: Object tried to call nil in verifyValue at KahluaUtil.fail(KahluaUtil.java:100).
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Mod f:N at ZomboidFileSystem.loadModTileDefPropertyStrings> tiledef fileNumber 575 used by more than one mod
    1x ERROR: Mod f:N at ZomboidFileSystem.loadModTileDefs > tiledef fileNumber 575 used by more than one mod
    1x ERROR: General f:N> Lua((MOD:Voiced Radio and Tvs)).Init> Exception thrown  :: java.lang.RuntimeException: Object tried to call nil in Init at KahluaUtil.fail(KahluaUtil.java:100).
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Cube"
    2x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "MP5_Rack.X_Dummy01"
    1x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Root"
    1x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "MP5_Aim_Rack.X_Dummy01"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Bip01_Root"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Bip01_Prop2_end"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Bip01_Prop1_end"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "HLPR=RemapSpace"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "HLPR-ChestTransform"
    2x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Body"
```
