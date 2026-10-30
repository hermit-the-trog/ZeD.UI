# ZeD-UI regression - 2026-10-29 22:35 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 22:35:46 |
| Finished | 2026-10-29 23:08:18 (32 min 31 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/regression.txt (94 scripts) |
| Result | **72/94 pass**, 5 warn, 2 fail, 0 timeout, 15 not run |
| Go numbers | 16150 to 16230 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- console.txt restarted at 23:07:47 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- stopped after zedqa_dash_props_smoke.lua: the game dropped to the main menu during this script
- quit: quit to the main menu, then to the desktop (go 16229, 16230)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | suite_tabs.lua | tabs | PASS | 9 |  |  |
| 3 | suite_verbs.lua | verbs | PASS | 14 |  |  |
| 4 | suite_gamepad.lua | gp | PASS | 6 |  |  |
| 5 | suite_band.lua | band | PASS | 2 |  |  |
| 6 | suite_perf.lua | perf | PASS | 25 |  |  |
| 7 | zedqa_audit_fixes.lua | af | PASS | 4 |  | 42 expected exception(s) ignored (expect=) |
| 8 | zedqa_card_pad.lua | cp | PASS | 4 | zqa_cp_card.png |  |
| 9 | zedqa_ctxlist.lua | cl | PASS | 5 | zqa_cl_1.png, zqa_cl_2.png |  |
| 10 | zedqa_ctx_icons.lua | cx | PASS | 21 | zqa_cx_grid.png, zqa_cx_strip_apple.png, zqa_cx_strip_pistol.png, zqa_cx_strip_bandage.png, zqa_cx_strip_hammer.png, zqa_cx_strip_floor.png, zqa_cx_list_apple.png, zqa_cx_list_pistol.png, zqa_cx_list_bandage.png, zqa_cx_list_hammer.png, zqa_cx_list_floor.png |  |
| 11 | zedqa_onepath.lua | op | PASS | 17 | zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png |  |
| 12 | zedqa_grid.lua | grid | PASS | 6 | zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png |  |
| 13 | zedqa_sort_groups.lua | sg | PASS | 47 | zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png |  |
| 14 | zedqa_wt_bracket.lua | wtb | PASS | 19 | zqa_wtb_small_list.png, zqa_wtb_open_stack.png, zqa_wtb_narrow_wt.png, zqa_wtb_small_grid.png, zqa_wtb_large_list.png, zqa_wtb_large_grid.png, zqa_wtb_two_columns.png, zqa_wtb_two_columns_large.png |  |
| 15 | zedqa_doll.lua | doll | PASS | 9 | zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png |  |
| 16 | zedqa_doll_v4.lua | dollv4 | PASS | 27 | zqa_dollv4_3840x2160_wide.png, zqa_dollv4_3840x2160_dpad.png, zqa_dollv4_3840x2160_wide_pads.png, zqa_dollv4_3840x2160_card.png, zqa_dollv4_3840x2160_narrow.png |  |
| 17 | zedqa_large.lua | lg | PASS | 9 | zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png |  |
| 18 | zedqa_curtain.lua | cu | WARN | 151 | zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png | 1 ERR line(s) |
| 19 | zedqa_curtain2.lua | cv | PASS | 11 | zqa_cv_1.png, zqa_cv_2.png, zqa_cv_3.png |  |
| 20 | zedqa_navevents.lua | ev | PASS | 5 |  |  |
| 21 | zedqa_navmap.lua | nav | PASS | 9 |  |  |
| 22 | zedqa_loot_tabs.lua | lt | PASS | 1 |  |  |
| 23 | zedqa_world_pad_take.lua | wpt | PASS | 61 |  |  |
| 24 | zedqa_furniture.lua | fu | PASS | 2 |  |  |
| 25 | zedqa_tabicons.lua | ti | PASS | 3 | zqa_tabicons.png |  |
| 26 | zedqa_tabs_lit.lua | tl | PASS | 6 | zqa_tabs_1.png, zqa_tabs_2.png, zqa_tabs_3.png |  |
| 27 | zedqa_win.lua | win | PASS | 5 | zedqa_win_200.png, zedqa_win_100.png |  |
| 28 | zedqa_rootchange.lua | rc | PASS | 6 | zedqa_rc_100.png, zedqa_rc_200.png |  |
| 29 | zedqa_scalewalk.lua | sw | PASS | 58 | zedqa_sw_200_char_loot.png, zedqa_sw_200_char_equip.png, zedqa_sw_200_char_health.png, zedqa_sw_200_char_thermal.png, zedqa_sw_200_char_identity.png, zedqa_sw_200_char_journal.png, zedqa_sw_200_char_skills.png, zedqa_sw_200_world_loot.png, zedqa_sw_200_world_craft.png, zedqa_sw_200_world_build.png, zedqa_sw_200_world_furniture.png, zedqa_sw_200_world_maps.png, zedqa_sw_200_world_forage.png, zedqa_sw_200_world_animals.png, zedqa_sw_200_world_vehicle.png, zedqa_sw_100_char_loot.png, zedqa_sw_100_char_equip.png, zedqa_sw_100_char_health.png, zedqa_sw_100_char_thermal.png, zedqa_sw_100_char_identity.png, zedqa_sw_100_char_journal.png, zedqa_sw_100_char_skills.png, zedqa_sw_100_world_loot.png, zedqa_sw_100_world_craft.png, zedqa_sw_100_world_build.png, zedqa_sw_100_world_furniture.png, zedqa_sw_100_world_maps.png, zedqa_sw_100_world_forage.png, zedqa_sw_100_world_animals.png, zedqa_sw_100_world_vehicle.png |  |
| 30 | zedqa_uiscale.lua | scale | PASS | 12 | zedqa_scale_auto.png, zedqa_scale_x150.png, zedqa_scale_x100.png, zedqa_scale_auto_back.png, zedqa_scale_restored.png |  |
| 31 | zedqa_mapshot.lua | ms | PASS | 4 | zqa_ms_1.png, zqa_ms_2.png |  |
| 32 | zedqa_mapstyles.lua | mst | PASS | 13 | zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png |  |
| 33 | zedqa_flyers.lua | fl | PASS | 6 | zqa_fl_1.png, zqa_fl_2.png |  |
| 34 | zedqa_flyermap.lua | fm | PASS | 11 | zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png |  |
| 35 | zedqa_mapnotes.lua | mnote | PASS | 8 | zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png |  |
| 36 | zedqa_journal_refs.lua | jr | PASS | 4 | zqa_jr_01_diary.png, zqa_jr_02_flyers.png |  |
| 37 | zedqa_journal_readers.lua | jrd | PASS | 18 | zqa_jr_01_papers.png, zqa_jr_02_unread_look.png, zqa_jr_03_read_look.png, zqa_jr_04_notebooks.png, zqa_jr_05_written.png, zqa_jr_06_into.png, zqa_jr_07_logged.png |  |
| 38 | zedqa_lists.lua | ls | PASS | 16 | zqa_ls_01_page_480.png, zqa_ls_02_page_480_lines.png, zqa_ls_03_stepper.png, zqa_ls_04_ask_delete.png, zqa_ls_05_rightclick_list.png, zqa_ls_06_rightclick_strip.png, zqa_ls_07_card_inlists.png, zqa_ls_08_mark_popup.png |  |
| 39 | zedqa_restock.lua | rst | PASS | 60 | zqa_rst_01_bar_ghosts.png, zqa_rst_02_todo.png, zqa_rst_02b_todo_lines.png, zqa_rst_03_ask_band.png, zqa_rst_04_after_hardcore.png, zqa_rst_05_pin_accessible.png, zqa_rst_06_pin_casual.png, zqa_rst_07_long_trip.png, zqa_rst_07b_long_trip_table.png, zqa_rst_08_unpack.png |  |
| 40 | zedqa_reader.lua | rd | PASS | 10 | zqa_rd_01_paper.png, zqa_rd_02_words.png, zqa_rd_03_story2.png, zqa_rd_04_zoomed.png, zqa_rd_05_flier.png, zqa_rd_06_map.png |  |
| 41 | zedqa_reader_refs.lua | rr | PASS | 12 | zqa_rr_01_journal_flyers.png, zqa_rr_02_news_card.png, zqa_rr_03_vanilla_news_paper.png, zqa_rr_04_vanilla_news_words.png, zqa_rr_05_vanilla_flier_paper.png, zqa_rr_06_vanilla_flier_words.png, zqa_rr_07_vanilla_journal.png |  |
| 42 | zedqa_notebook.lua | nb | PASS | 8 | zqa_nb_01_page1.png, zqa_nb_02_erase_asks.png, zqa_nb_03_rail.png, zqa_nb_04_read_only.png, zqa_nb_05_locked_other.png |  |
| 43 | zedqa_print_fit.lua | pf | PASS | 13 | zqa_pf_1a_KnoxKnews_July1_vanilla.png, zqa_pf_1b_KnoxKnews_July1_fitted.png, zqa_pf_2a_KnoxKnews_July2_vanilla.png, zqa_pf_2b_KnoxKnews_July2_fitted.png, zqa_pf_3a_KentuckyHerald_July6_vanilla.png, zqa_pf_3b_KentuckyHerald_July6_fitted.png, zqa_pf_4a_NationalDispatch_July6_vanilla.png, zqa_pf_4b_NationalDispatch_July6_fitted.png |  |
| 44 | zedqa_print_typeset.lua | ts | PASS | 7 | zqa_ts_1_KnoxKnews_July1.png, zqa_ts_2_KnoxKnews_July2.png, zqa_ts_3_KentuckyHerald_July6.png, zqa_ts_4_NationalDispatch_July6.png |  |
| 45 | zedqa_prompts.lua | pr | PASS | 30 | zqa_pr_01_sleep.png, zqa_pr_02_kill.png, zqa_pr_03_note.png, zqa_pr_04_rename.png, zqa_pr_05_rename_empty.png, zqa_pr_06_keyboard.png, zqa_pr_07_alarm.png, zqa_pr_08_timer.png, zqa_pr_09_help.png, zqa_pr_10_rich_question.png, zqa_pr_11_gp_question.png, zqa_pr_12_gp_question_no.png, zqa_pr_13_gp_kill.png, zqa_pr_14_gp_text.png, zqa_pr_15_gp_keyboard.png, zqa_pr_16_gp_alarm.png |  |
| 46 | zedqa_fishing.lua | fi | PASS | 9 | zqa_fi_1_slack.png, zqa_fi_2_light.png, zqa_fi_3_tight.png, zqa_fi_4_strain.png, zqa_fi_5_limit.png |  |
| 47 | zedqa_props_plates.lua | props | PASS | 3 | zqa_props_1.png, zqa_props_2.png, zqa_props_3.png |  |
| 48 | zedqa_belt_strap.lua | belt | PASS | 2 | zqa_belt_strap_1.png |  |
| 49 | zedqa_straps.lua | straps | PASS | 12 | zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png |  |
| 50 | zedqa_buckle.lua | bk | PASS | 6 | zqa_bk_1.png, zqa_bk_2.png, zqa_bk_3.png |  |
| 51 | zedqa_buckles.lua | bks | PASS | 38 | zqa_bk_01_burgerflipper.png, zqa_bk_02_repairman.png, zqa_bk_03_burglar.png, zqa_bk_04_engineer.png, zqa_bk_05_fisherman.png, zqa_bk_06_policeofficer.png, zqa_bk_07_lumberjack.png, zqa_bk_08_smither.png, zqa_bk_09_farmer.png, zqa_bk_10_electrician.png, zqa_bk_11_fireofficer.png, zqa_bk_12_metalworker.png, zqa_bk_13_fitnessinstructor.png, zqa_bk_14_veteran.png, zqa_bk_15_tailor.png, zqa_bk_16_chef.png, zqa_bk_17_doctor.png, zqa_bk_18_parkranger.png, zqa_bk_19_unemployed.png, zqa_bk_20_nurse.png, zqa_bk_21_securityguard.png, zqa_bk_22_carpenter.png, zqa_bk_23_mechanics.png, zqa_bk_24_rancher.png, zqa_bk_25_constructionworker.png |  |
| 52 | zedqa_beltwatch.lua | bw | PASS | 12 | zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png |  |
| 53 | zedqa_hands_together.lua | ht | PASS | 18 | zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png |  |
| 54 | zedqa_watches2.lua | watches | PASS | 29 | zqa_watch_day_DigitalBlack.png, zqa_watch_day_DigitalDress.png, zqa_watch_day_DigitalRed.png, zqa_watch_day_DigitalTimez.png, zqa_watch_day_ClassicBlack.png, zqa_watch_day_ClassicGold.png, zqa_watch_day_ClassicBrown.png, zqa_watch_day_ClassicMilitary.png, zqa_watch_day_Expensive.png, zqa_watch_set_DigitalBlack.png, zqa_watch_night_DigitalBlack.png, zqa_watch_night_DigitalTimez.png, zqa_watch_lit_DigitalTimez.png, zqa_watch_night_ClassicBrown.png, zqa_watch_lit_ClassicBrown.png, zqa_watch_night_Expensive.png |  |
| 55 | zedqa_container_bottom.lua | cb | PASS | 10 | zqa_cb_01_rows_at_bottom.png, zqa_cb_02_list_end.png, zqa_cb_03_pad_take_all.png, zqa_cb_04_campfire_ribbon.png |  |
| 56 | zedqa_container_controls.lua | ct | PASS | 17 | zqa_ct_01_rows.png, zqa_ct_02_pad_same_type.png, zqa_ct_03_after_take_all.png, zqa_ct_04_floor_row.png, zqa_ct_05_campfire_row.png, zqa_ct_06_add_fuel_card.png |  |
| 57 | zedqa_container_controls_captures.lua | cc | PASS | 6 | zqa_cc_zed_truckbed.png, zqa_cc_vanilla_truckbed.png |  |
| 58 | zedqa_px_icons.lua | px | WARN | 5 | zqa_px_panel.png, zqa_px_card.png, zqa_px_rows.png | 1 ERR line(s) |
| 59 | zedqa_button_case_game.lua | bg | PASS | 16 | zqa_bg_01_item_card.png, zqa_bg_02_health.png, zqa_bg_03_thermal.png, zqa_bg_04_animals.png, zqa_bg_05_forage.png, zqa_bg_06_craft.png, zqa_bg_07_vehicle.png |  |
| 60 | zedqa_wheel_sizes.lua | ws | PASS | 15 | zqa_ws_a_gun3.png, zqa_ws_b_dright3.png, zqa_ws_c_emotes5.png, zqa_ws_d_signal9.png, zqa_ws_e_back10.png, zqa_ws_g_car11.png, zqa_ws_h_car11pt.png |  |
| 61 | zedqa_wheel_icons.lua | wi | WARN | 62 | zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png | 2 ERR line(s) |
| 62 | zedqa_wheels.lua | wh | PASS | 28 | zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png |  |
| 63 | zedqa_dpad_wheels.lua | dw | PASS | 49 | zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png |  |
| 64 | zedqa_pad_glyphs.lua | pg | PASS | 30 | zqa_pg_footer_ps.png, zqa_pg_wheel_ps.png, zqa_pg_footer_xbox.png, zqa_pg_wheel_xbox.png, zqa_pg_footer_deck.png, zqa_pg_wheel_deck.png, zqa_pg_footer_nintendo.png, zqa_pg_wheel_nintendo.png, zqa_pg_footer_kbm.png, zqa_pg_wheel_kbm.png, zqa_pg_footer_ps_light.png, zqa_pg_wheel_ps_light.png, zqa_pg_footer_ps_hicon.png, zqa_pg_wheel_ps_hicon.png |  |
| 65 | zedqa_quick_chords.lua | qc | **FAIL** | 25 | zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png | 1 Java exception(s) in the log; 1 ERR line(s) |
| 66 | zedqa_put_back.lua | pb | PASS | 33 |  |  |
| 67 | zedqa_food_verbs.lua | fv | PASS | 4 | zqa_fv_smoking.png |  |
| 68 | zedqa_messages.lua | msg | PASS | 12 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=) |
| 69 | zedqa_moodles.lua | mood | PASS | 20 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png |  |
| 70 | zedqa_ring_squares.lua | rs | PASS | 7 | zqa_rs_belt_full.png, zqa_rs_belt_70_45.png, zqa_rs_belt_15.png |  |
| 71 | zedqa_sandbox_ig.lua | sbx | PASS | 17 | zqa_sbx_pause_line.png, zqa_sbx_time.png, zqa_sbx_world_help.png, zqa_sbx_zombie_changed.png, zqa_sbx_ask_apply.png, zqa_sbx_applied.png, zqa_sbx_history.png, zqa_sbx_pad.png |  |
| 72 | zedqa_twoway.lua | tw | PASS | 47 | zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png |  |
| 73 | zedqa_appliances.lua | ap | PASS | 12 | zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png |  |
| 74 | zedqa_two_widths.lua | tww | WARN | 78 | zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png | 2 ERR line(s) |
| 75 | zedqa_plates_336.lua | p336 | WARN | 116 | zqa_p336_scale175_oven.png, zqa_p336_scale175_microwave.png, zqa_p336_scale175_chrome.png, zqa_p336_scale175_generator.png, zqa_p336_scale175_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png | 2 ERR line(s) |
| 76 | zedqa_seat_lightbar_vanilla.lua | sl | PASS | 22 | zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png |  |
| 77 | zedqa_car_radio_build.lua | rb | PASS | 28 | zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png |  |
| 78 | zedqa_car_radio_cd.lua | cd | PASS | 10 | zqa_cd_c01_cdlist.png, zqa_cd_c02_cd_playing.png, zqa_cd_c03_ejected.png, zqa_cd_c04_valutech_tape.png |  |
| 79 | zedqa_dash_props_smoke.lua | sm | **FAIL** | 6 | zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png | 44 Java exception(s) in the log; the script ran twice (re-bump); late output from pre (4 line(s), not counted); late output from tabs (2 line(s), not counted); late output from verbs (2 line(s), not counted); late output from gp (17 line(s), not counted); late output from band (5 line(s), not counted); late output from perf (15 line(s), not counted); late output from af (9 line(s), not counted); late output from cp (13 line(s), not counted); late output from cl (8 line(s), not counted); late output from cx (59 line(s), not counted); late output from op (20 line(s), not counted); late output from grid (11 line(s), not counted); late output from sg (58 line(s), not counted); late output from wtb (39 line(s), not counted); late output from doll (15 line(s), not counted); late output from dollv4 (71 line(s), not counted); late output from lg (4 line(s), not counted); late output from cu (319 line(s), not counted); late output from cv (14 line(s), not counted); late output from ev (28 line(s), not counted); late output from nav (163 line(s), not counted); late output from lt (3 line(s), not counted); late output from wpt (129 line(s), not counted); late output from fu (10 line(s), not counted); late output from ti (1 line(s), not counted); late output from tl (3 line(s), not counted); late output from win (3 line(s), not counted); late output from rc (4 line(s), not counted); late output from sw (64 line(s), not counted); late output from scale (7 line(s), not counted); late output from ms (3 line(s), not counted); late output from mst (5 line(s), not counted); late output from fl (6 line(s), not counted); late output from fm (9 line(s), not counted); late output from mnote (23 line(s), not counted); late output from jr (2 line(s), not counted); late output from jrd (10 line(s), not counted); late output from ls (63 line(s), not counted); late output from rst (84 line(s), not counted); late output from rd (7 line(s), not counted); late output from rr (3 line(s), not counted); late output from nb (7 line(s), not counted); late output from pf (11 line(s), not counted); late output from ts (6 line(s), not counted); late output from pr (40 line(s), not counted); late output from fi (7 line(s), not counted); late output from props (2 line(s), not counted); late output from belt (2 line(s), not counted); late output from straps (17 line(s), not counted); late output from bk (7 line(s), not counted); late output from bks (28 line(s), not counted); late output from bw (10 line(s), not counted); late output from ht (120 line(s), not counted); late output from watches (20 line(s), not counted); late output from cb (5 line(s), not counted); late output from ct (33 line(s), not counted); late output from cc (7 line(s), not counted); late output from px (12 line(s), not counted); late output from bg (4 line(s), not counted); late output from ws (8 line(s), not counted); late output from wi (96 line(s), not counted); late output from wh (16 line(s), not counted); late output from dw (73 line(s), not counted); late output from pg (35 line(s), not counted); late output from qc (59 line(s), not counted); late output from pb (28 line(s), not counted); late output from fv (13 line(s), not counted); late output from msg (27 line(s), not counted); late output from mood (51 line(s), not counted); late output from rs (12 line(s), not counted); late output from sbx (45 line(s), not counted); late output from tw (204 line(s), not counted); late output from ap (35 line(s), not counted); late output from tww (381 line(s), not counted); late output from p336 (88 line(s), not counted); late output from sl (7 line(s), not counted); late output from rb (68 line(s), not counted); late output from cd (16 line(s), not counted); the game dropped to the main menu during this script |
| 80 | zedqa_tm.lua | tm | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 81 | zedqa_tour3.lua | t3 | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 82 | zedqa_dash19.lua | dash | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 83 | zedqa_dashpx.lua | dpx | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 84 | zedqa_exinfo.lua | ex | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 85 | zedqa_charinfo.lua | ci | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 86 | zedqa_equipdrag.lua | eqd | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 87 | zedqa_cazio_light.lua | czl | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 88 | zedqa_dashnight.lua | dnt | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 89 | zedqa_dash_green.lua | dgr | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 90 | zedqa_dash_keys_edge.lua | dke | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 91 | zedqa_dash_brands.lua | dbr | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 92 | zedqa_testlang.lua | tlang | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 93 | zedqa_safemode.lua | safe | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 94 | zedqa_soak.lua | soak | SKIP |  |  | not run: the game dropped to the main menu during this script |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 16150 at 22:36:57

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. suite_tabs.lua (`ZEDQA tabs`) - PASS, 9 s

- go 16151 at 22:37:01

```text
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
ZEDQA world tabs: loot,craft,build,furniture,maps
ZEDQA tabs armed
[ZeD.QA] run #2 ok=true
ZEDQA char tab=loot active=loot w=777 focusables=0 {}
ZEDQA char tab=equip active=equip w=1617 focusables=36 {el=4 equipbelt=1 equipgroup=5 equippart=17 equipslot=7 equipview=2}
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
ZEDQA tabs done
```

### 3. suite_verbs.lua (`ZEDQA verbs`) - PASS, 14 s

- go 16152 at 22:37:14

```text
[ZeD.QA] windows reset (R)
ZEDQA verbs armed
[ZeD.QA] run #3 ok=true
ZEDQA worn=T-shirt ctx=equipped
ZEDQA fire UNEQUIP ok=true err=nil qhead=ISUnequipAction
ZEDQA after UNEQUIP pEq=false ctx=inventory (expect inventory)
ZEDQA fire EQUIP ok=true err=nil qhead=ISWearClothing
ZEDQA after EQUIP pEq=true ctx=equipped (expect equipped)
ZEDQA fire READ ok=true err=nil qhead=ISReadABook
ZEDQA after READ qhead=ISReadABook (expect ISReadABook)
ZEDQA fire EQUIP ok=true err=nil qhead=ISEquipWeaponAction
ZEDQA after EQUIP bat primary=Baseball Bat ctx=equipped (expect equipped)
ZEDQA fire UNEQUIP ok=true err=nil qhead=ISUnequipAction
ZEDQA after UNEQUIP bat primary=nil (expect nil)
ZEDQA fire EAT ok=true err=nil qhead=ISEatFoodAction
ZEDQA after EAT qhead=ISEatFoodAction (expect ISEatFoodAction)
ZEDQA fire DROP ok=true err=nil qhead=ISInventoryTransferAction
ZEDQA after DROP cont=floor ctx=ground (expect floor/ground)
ZEDQA fire TAKE ok=true err=nil qhead=ISInventoryTransferAction
ZEDQA after TAKE inInv=true ctx=inventory (expect inventory)
ZEDQA verbs done
```

### 4. suite_gamepad.lua (`ZEDQA gp`) - PASS, 6 s

- go 16153 at 22:37:31

```text
[ZeD.QA] windows reset (R)
ZEDQA gp armed
[ZeD.QA] run #4 ok=true
ZEDQA gp claim zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp down zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false
ZEDQA gp right zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp left zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false
ZEDQA gp loot charTabContent elements=0 (expect 0)
ZEDQA gp right after journal to loot (expect container strip, never jsub) zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp after row2 onActivate (expect card open) zone=charItemCard el=hverb_1 tab=loot drawer=true item=Baseball Bat ctx=false
ZEDQA gp after row3 onActivate (expect live swap) zone=charItemCard el=hverb_1 tab=loot drawer=true item=Book: "The Omega Department Guide (Unofficial)", by Napoleon Trejo ctx=false
ZEDQA gp after row3 again (expect closed) zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false
ZEDQA gp after row2 onContextMenu (expect ctx=true) zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=true
ZEDQA gp after ctx B (expect ctx=false) zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false
ZEDQA gp world claim zone=worldContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp world right zone=worldCtl el=worldCtl:take tab=loot drawer=false item=nil ctx=false
ZEDQA gp world craft down zone=worldCtl el=worldCtl:take tab=craft drawer=true item=nil ctx=false
ZEDQA gp world loot left (stale check) zone=worldContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp done
```

### 5. suite_band.lua (`ZEDQA band`) - PASS, 2 s

- go 16154 at 22:37:40

```text
[ZeD.QA] windows reset (R)
ZEDQA band armed
[ZeD.QA] run #5 ok=true
ZEDQA band reading active=true kind=reading mode=nil label=Reading pct=0.03846567124128342 time=nil (expect active reading)
ZEDQA band after cancel active=false kind=nil mode=nil label=nil pct=nil time=nil qlen=0 (expect inactive, 0)
ZEDQA band: no real stove within 20 tiles; cooking skipped
ZEDQA band done
```

### 6. suite_perf.lua (`ZEDQA perf`) - PASS, 25 s

- go 16155 at 22:37:46

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #6 ok=true
ZEDQA perf char loot avg=8.62ms/tick max=35ms
ZEDQA perf char equip avg=10.01ms/tick max=20ms
ZEDQA perf char health avg=8.89ms/tick max=26ms
ZEDQA perf char thermal avg=9.31ms/tick max=19ms
ZEDQA perf char identity avg=9.18ms/tick max=32ms
ZEDQA perf char journal avg=8.56ms/tick max=17ms
ZEDQA perf char skills avg=8.88ms/tick max=36ms
ZEDQA perf world craft avg=9.06ms/tick max=25ms
ZEDQA perf world build avg=8.67ms/tick max=36ms
ZEDQA perf world maps avg=8.73ms/tick max=20ms
ZEDQA perf world forage avg=8.73ms/tick max=35ms
ZEDQA perf world animals avg=8.58ms/tick max=16ms
ZEDQA perf world loot avg=8.60ms/tick max=35ms
ZEDQA perf world craft build: 11 elements, 0.07 ms per build
ZEDQA perf done
```

### 7. zedqa_audit_fixes.lua (`ZEDQA af`) - PASS, 4 s

- go 16156 at 22:38:14
- 42 expected exception(s) ignored (expect=)

```text
[ZeD.QA] windows reset (R)
ZEDQA af start
[ZeD.QA] run #7 ok=true
ERROR: General f:9020> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9021> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9022> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9023> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9024> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9025> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9026> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9027> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9028> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9029> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9030> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9031> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9032> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9033> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9034> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9035> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9036> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9037> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9038> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9039> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9040> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9041> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9042> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9043> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9045> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9048> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9049> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9051> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9053> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9055> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9057> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9060> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9061> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9063> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9065> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9067> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9069> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9071> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9074> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9075> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9076> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9078> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ZEDQA af tab draws again: zones 5
ZEDQA af equip slots 6
ZEDQA af equip card shown on Equip: true
ZEDQA af equip card on Journal (expect false): false
ZEDQA af card item set: true mode item
ZEDQA af after the apple left: drawer item nil mode nil (expect nil, nil)
ZEDQA af weight 0
ZEDQA af DONE
```

### 8. zedqa_card_pad.lua (`ZEDQA cp`) - PASS, 4 s

- go 16157 at 22:38:22
- screenshots: zqa_cp_card.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cp start
[ZeD.QA] run #8 ok=true
ZEDQA cp selected the apple row 6
ZEDQA cp card open true | card buttons 7 {hverb_1,hverb_2,name_row,toggle_fav,toggle_protect,toggle_unwanted,toggle_lists}
ZEDQA cp fav chip rect on the card (mouse): true
ZEDQA cp before left: zone=charItemCard el=hverb_1
ZEDQA cp after left (expect charItemCard): zone=charTabBar el=tab:loot
ZEDQA cp right 1: zone=charItemCard el=hverb_1
ZEDQA cp right 2: zone=charItemCard el=hverb_2
ZEDQA cp left: zone=charItemCard el=hverb_1
ZEDQA cp after B: card item nil (expect nil)
ZEDQA cp health: inv then left (expect charTabContent): zone=charTabContent el=bodypart:Head
ZEDQA cp health: right: zone=charMainInv el=invrow:1
ZEDQA cp DONE
```

### 9. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 5 s

- go 16158 at 22:38:29
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #9 ok=true
ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Set Unwanted, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Save to loadout, |, Rename
ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
ZEDQA cl down: sub sel 2
ZEDQA cl B: levels 1
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

### 10. zedqa_ctx_icons.lua (`ZEDQA cx`) - PASS, 21 s

- go 16159 at 22:38:37
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
[ZeD.QA] run #10 ok=true
ZEDQA cx drawings not ready yet: 260
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

### 11. zedqa_onepath.lua (`ZEDQA op`) - PASS, 17 s

- go 16160 at 22:39:02
- screenshots: zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png

```text
[ZeD.QA] windows reset (R)
ZEDQA op start
[ZeD.QA] run #11 ok=true
ZEDQA op crate ItemContainer:[type:crate, parent:null:carpentry_01_16:carpentry_01_16:zombie.iso.IsoObject@2b0deac2] type crate
ZEDQA op world select crate true
ZEDQA op apple menu: Eat, |, Place Item, Favorite, Set Unwanted, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Save to loadout, |, Rename
ZEDQA op move to: Crate, Floor
ZEDQA op picked Crate
ZEDQA op apple now in crate
ZEDQA op hammer menu: Attach, Dismantle Bladed Item, Place Item, Put in Container (Crate), Favorite, Set Unwanted, Move to, |, Craft, Set to be Unusable in Recipes, Show Build Recipes Used In, |, Equip Primary, Equip Secondary, |, Drop, |, Save to loadout, |, Rename
ZEDQA op prompt true entry Claw Hammer
ZEDQA op hammer name: Old Faithful custom true
ZEDQA op card els: hverb_1, hverb_2, name_row, toggle_fav, toggle_protect, toggle_unwanted, toggle_lists
ZEDQA op dbl: first false second true
ZEDQA op primary: true
ZEDQA op crate menu: Sit on ground, Walk to, |, Disassemble, |, Take All
ZEDQA op take all pressed
ZEDQA op crate left: 0 apple home true
ZEDQA op bottle verbs: Drink, More
ZEDQA op knife maint: sharp 0.4000000059604645
ZEDQA op nocraft on true off false
ZEDQA op DONE
```

### 12. zedqa_grid.lua (`ZEDQA grid`) - PASS, 6 s

- go 16161 at 22:39:23
- screenshots: zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA grid start
[ZeD.QA] run #12 ok=true
ZEDQA grid grid on: cell 91 | cells placed 12 | toggle rects 2
ZEDQA grid first target: invrow:1 at 18,107 size 91x91
ZEDQA grid first cell: zone=charMainInv el=invrow:1 item=Apple (Fresh)
ZEDQA grid right (expect the next cell): zone=charMainInv el=invrow:2 item=Baseball Bat
ZEDQA grid down (expect the cell below): zone=charMainInv el=invrow:8 item=Flier: Fossoil (West Point): Fossoil (West Point)
ZEDQA grid up: zone=charMainInv el=invrow:2 item=Baseball Bat
ZEDQA grid up again (expect the toggle): zone=charMainInv el=view:list:player item=nil
ZEDQA grid card open true item Baseball Bat
ZEDQA grid after A on List: grid false cell nil
ZEDQA grid DONE
```

### 13. zedqa_sort_groups.lua (`ZEDQA sg`) - PASS, 47 s

- go 16162 at 22:39:32
- screenshots: zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sg start
[ZeD.QA] run #13 ok=true
ZEDQA sg pack worn at base:back: true
ZEDQA sg given: bag 23, pack 8, bed 19, floor 11
ZEDQA sg floor container things 33 | char window true world window true
ZEDQA sg columns at start: char 0 world 0
ZEDQA sg mode single:
ZEDQA sg single list cat char: columns 1 rows 27 headers 5 order ok pad 27 (charMainInv=27) grid false sort cat/true
ZEDQA sg single list cat world: columns 1 rows 15 headers 4 order ok pad 15 (worldMainInv=15) grid false sort cat/true
ZEDQA sg single list name char: columns 1 rows 27 headers 0 order ok pad 27 (charMainInv=27) grid false sort name/true
ZEDQA sg single list name world: columns 1 rows 15 headers 0 order ok pad 15 (worldMainInv=15) grid false sort name/true
ZEDQA sg single list cond char: columns 1 rows 27 headers 0 order ok pad 27 (charMainInv=27) grid false sort cond/true
ZEDQA sg single list cond world: columns 1 rows 15 headers 0 order ok pad 15 (worldMainInv=15) grid false sort cond/true
ZEDQA sg single list wt char: columns 1 rows 27 headers 0 order ok pad 27 (charMainInv=27) grid false sort wt/true
ZEDQA sg single list wt world: columns 1 rows 15 headers 0 order ok pad 15 (worldMainInv=15) grid false sort wt/true
ZEDQA sg single list name rev char: columns 1 rows 27 headers 0 order ok pad 27 (charMainInv=27) grid false sort name/false
ZEDQA sg single list name rev world: columns 1 rows 15 headers 0 order ok pad 15 (worldMainInv=15) grid false sort name/false
ZEDQA sg fold char: Accessory folded, rows 25 of 27, its header true
ZEDQA sg fold world: FirstAid folded, rows 14 of 15, its header true
ZEDQA sg fold char on Name: rows 27 headers 0
ZEDQA sg fold world on Name: rows 15 headers 0
ZEDQA sg fold char back on Category: still folded true rows 25
ZEDQA sg fold world back on Category: still folded true rows 14
ZEDQA sg stack char: Base.Apple x9 open, rows 35 of 27 (+8 expected), children follow true, headers 0
ZEDQA sg stack world: Base.Apple x2 open, rows 16 of 15 (+1 expected), children follow true, headers 0
ZEDQA sg single grid cat char: columns 1 rows 27 headers 5 order ok pad 27 (charMainInv=27) grid true sort cat/true
ZEDQA sg single grid cat world: columns 1 rows 15 headers 5 order ok pad 15 (worldMainInv=15) grid true sort cat/true
ZEDQA sg single grid name char: columns 1 rows 27 headers 0 order ok pad 27 (charMainInv=27) grid true sort name/true
ZEDQA sg single grid name world: columns 1 rows 15 headers 0 order ok pad 15 (worldMainInv=15) grid true sort name/true
ZEDQA sg single grid cond char: columns 1 rows 27 headers 0 order ok pad 27 (charMainInv=27) grid true sort cond/true
ZEDQA sg single grid cond world: columns 1 rows 15 headers 0 order ok pad 15 (worldMainInv=15) grid true sort cond/true
ZEDQA sg single grid wt char: columns 1 rows 27 headers 0 order ok pad 27 (charMainInv=27) grid true sort wt/true
ZEDQA sg single grid wt world: columns 1 rows 15 headers 0 order ok pad 15 (worldMainInv=15) grid true sort wt/true
ZEDQA sg single grid name rev char: columns 1 rows 27 headers 0 order ok pad 27 (charMainInv=27) grid true sort name/false
ZEDQA sg single grid name rev world: columns 1 rows 15 headers 0 order ok pad 15 (worldMainInv=15) grid true sort name/false
ZEDQA sg mode multi: char:true world:true
ZEDQA sg multi list cat char: columns 2 rows 8+27 headers 11 order ok pad 35 (charMC1=8,charMainInv=27) grid false sort cat/true
ZEDQA sg multi list cat world: columns 2 rows 14+15 headers 8 order ok pad 29 (worldMC1=14,worldMainInv=15) grid false sort cat/true
ZEDQA sg multi list name char: columns 2 rows 8+27 headers 0 order ok pad 35 (charMC1=8,charMainInv=27) grid false sort name/true
ZEDQA sg multi list name world: columns 2 rows 14+15 headers 0 order ok pad 29 (worldMC1=14,worldMainInv=15) grid false sort name/true
ZEDQA sg multi list cond char: columns 2 rows 8+27 headers 0 order ok pad 35 (charMC1=8,charMainInv=27) grid false sort cond/true
ZEDQA sg multi list cond world: columns 2 rows 14+15 headers 0 order ok pad 29 (worldMC1=14,worldMainInv=15) grid false sort cond/true
ZEDQA sg multi list wt char: columns 2 rows 8+27 headers 0 order ok pad 35 (charMC1=8,charMainInv=27) grid false sort wt/true
ZEDQA sg multi list wt world: columns 2 rows 14+15 headers 0 order ok pad 29 (worldMC1=14,worldMainInv=15) grid false sort wt/true
ZEDQA sg multi list name rev char: columns 2 rows 8+27 headers 0 order ok pad 35 (charMC1=8,charMainInv=27) grid false sort name/false
ZEDQA sg multi list name rev world: columns 2 rows 14+15 headers 0 order ok pad 29 (worldMC1=14,worldMainInv=15) grid false sort name/false
ZEDQA sg multi grid cat char: columns 2 rows 8+27 headers 10 order ok pad 35 (charMC1=8,charMainInv=27) grid true sort cat/true
ZEDQA sg multi grid cat world: columns 2 rows 14+15 headers 10 order ok pad 29 (worldMC1=14,worldMainInv=15) grid true sort cat/true
ZEDQA sg multi grid name char: columns 2 rows 8+27 headers 0 order ok pad 35 (charMC1=8,charMainInv=27) grid true sort name/true
ZEDQA sg multi grid name world: columns 2 rows 14+15 headers 0 order ok pad 29 (worldMC1=14,worldMainInv=15) grid true sort name/true
ZEDQA sg multi grid cond char: columns 2 rows 8+27 headers 0 order ok pad 35 (charMC1=8,charMainInv=27) grid true sort cond/true
ZEDQA sg multi grid cond world: columns 2 rows 14+15 headers 0 order ok pad 29 (worldMC1=14,worldMainInv=15) grid true sort cond/true
ZEDQA sg multi grid wt char: columns 2 rows 8+27 headers 0 order ok pad 35 (charMC1=8,charMainInv=27) grid true sort wt/true
ZEDQA sg multi grid wt world: columns 2 rows 14+15 headers 0 order ok pad 29 (worldMC1=14,worldMainInv=15) grid true sort wt/true
ZEDQA sg multi grid name rev char: columns 2 rows 8+27 headers 0 order ok pad 35 (charMC1=8,charMainInv=27) grid true sort name/false
ZEDQA sg multi grid name rev world: columns 2 rows 14+15 headers 0 order ok pad 29 (worldMC1=14,worldMainInv=15) grid true sort name/false
ZEDQA sg columns off: char:true world:true
ZEDQA sg restored: bag things 30 (were 30), bed 2, world things on the square 0, floor container 22
ZEDQA sg all checks held; DONE
```

### 14. zedqa_wt_bracket.lua (`ZEDQA wtb`) - PASS, 19 s

- go 16163 at 22:40:22
- screenshots: zqa_wtb_small_list.png, zqa_wtb_open_stack.png, zqa_wtb_narrow_wt.png, zqa_wtb_small_grid.png, zqa_wtb_large_list.png, zqa_wtb_large_grid.png, zqa_wtb_two_columns.png, zqa_wtb_two_columns_large.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wtb start
[ZeD.QA] run #14 ok=true
ZEDQA wtb given: bag 5 x Base.Orange + Base.Saucepan, ground 5 x Base.Apple + Base.Saucepan (6 / 6)
ZEDQA wtb extra columns: char 0 world 0
ZEDQA wtb small list char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)") at x 537..590 of 651, name ends 239, columns 1
ZEDQA wtb small list char headers: cat true, cond true
ZEDQA wtb small list world stack Apple (Stale) x5: drew "(1.0)" (expect "(1.0)") at x 562..615 of 651, name ends 258, columns 1
ZEDQA wtb small list world headers: cat true, cond true
ZEDQA wtb small list char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb small list world single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb open stack char: the row "(1.0)", 4 rows under it, 4 with their own weight
ZEDQA wtb open stack world: the row "(1.0)", 4 rows under it, 4 with their own weight
ZEDQA wtb char WT column 101 -> 81
ZEDQA wtb narrow WT char stack Orange (Fresh) x5: drew "(1)" (expect "(1.0)" or "(1)" / "0.2") at x 559..590 of 651, name ends 248, columns 1
ZEDQA wtb narrow WT char headers: cat true, cond true
ZEDQA wtb narrow WT char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb small grid char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)") at x 76..104 of 109, name ends nil, columns 1
ZEDQA wtb small grid world stack Apple (Stale) x5: drew "(1.0)" (expect "(1.0)") at x 76..104 of 109, name ends nil, columns 1
ZEDQA wtb small grid char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb small grid world single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb large list char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)") at x 502..565 of 633, name ends 284, columns 1
ZEDQA wtb large list char headers: cat true, cond false
ZEDQA wtb large list world stack Apple (Stale) x5: drew "(1.0)" (expect "(1.0)") at x 502..565 of 633, name ends 290, columns 1
ZEDQA wtb large list world headers: cat true, cond false
ZEDQA wtb large list char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb large list world single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb large grid char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)" or "(1)" / "0.2") at x 311..345 of 351, name ends nil, columns 1
ZEDQA wtb large grid world stack Apple (Stale) x5: drew "(1.0)" (expect "(1.0)" or "(1)" / "0.2") at x 85..119 of 125, name ends nil, columns 1
ZEDQA wtb large grid char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb large grid world single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb pack column on: true
ZEDQA wtb char columns 2
ZEDQA wtb two columns char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)" or "(1)" / "0.2") at x 712..765 of 826, name ends 680, columns 2
ZEDQA wtb two columns char headers: cat false, cond false
ZEDQA wtb two columns char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb two columns large char stack Orange (Fresh) x5: drew "(1)" (expect "(1.0)" or "(1)" / "0.2") at x 704..740 of 808, name ends 653, columns 2
ZEDQA wtb two columns large char headers: cat false, cond false
ZEDQA wtb two columns large char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb size back to small | bag Base.Orange left 0
ZEDQA wtb all checks held; DONE
```

### 15. zedqa_doll.lua (`ZEDQA doll`) - PASS, 9 s

- go 16164 at 22:40:45
- screenshots: zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA doll start
[ZeD.QA] run #15 ok=true
ZEDQA doll doll shown true | slots 7 {doll:torso,doll:outer,doll:hands,doll:belt,doll:legs,doll:feet,doll:belt1} | belt empties 2 | photo 307,210 217x828 | lines 11 | model visible true | layer visible true
ZEDQA doll pad targets: equipslot:__disclosure,equipview:list,equipview:doll,el:outfit,el:loadout,el:days,el:save,equipslot:doll:torso,equipslot:doll:outer,equipslot:doll:hands,equipslot:doll:belt,equipslot:doll:legs,equipslot:doll:feet,equipslot:doll:belt1,equipbelt:2,equipbelt:3,equipslot:doll:head,equipslot:doll:eyes,equipslot:doll:neck,equipslot:doll:back,equipslot:doll:arms,equipslot:doll:ears,equipslot:doll:eartop,equipslot:doll:nose,equipslot:doll:necklace,equipslot:doll:necklacelong,equipslot:doll:gorget,equipslot:doll:belly,equipslot:doll:holster,equipslot:doll:lmiddle,equipslot:doll:lring,equipslot:doll:rmiddle,equipslot:doll:rring,equipslot:doll:satchel,equipslot:doll:airtank,equipslot:doll:tail,equipslot:doll:padl,equipslot:doll:padr,equipslot:doll:padsport,equipslot:doll:elbowl,equipslot:doll:elbowr,equipslot:doll:wristl,equipslot:doll:wristr,equipslot:doll:forearml,equipslot:doll:forearmr,equipslot:doll:fpfront,equipslot:doll:fpback,equipslot:doll:webbing,equipslot:doll:ammo,equipslot:doll:beltholster,equipslot:doll:kneel,equipslot:doll:kneer,equipslot:doll:thighl,equipslot:doll:thighr,equipslot:doll:shinl,equipslot:doll:shinr,equipslot:doll:gaiterl,equipslot:doll:gaiterr,equipslot:doll:ankleholster,equipslot:doll:main,equipslot:doll:off
ZEDQA doll focus torso: zone=charTabContent el=equipslot:doll:torso sel=nil layer=1
ZEDQA doll card targets: equipcard:hverb_1,equipcard:hverb_2,equipcard:hverb_3,equipcard:name_row,equipcard:more_row,equipcard:toggle_fav,equipcard:toggle_protect,equipcard:toggle_unwanted,equipcard:toggle_lists,equipcard:back,equipcard:__layer_1,equipcard:__layer_-1
ZEDQA doll card open: zone=charTabContent el=equipcard:hverb_1 sel=doll:torso layer=1
ZEDQA doll focus Inner: zone=charTabContent el=equipcard:__layer_1 sel=doll:torso layer=1
ZEDQA doll after Inner (expect layer 2): zone=charTabContent el=equipcard:__layer_1 sel=doll:torso layer=2
ZEDQA doll after B (expect sel=nil, el=equipslot:doll:torso): zone=charTabContent el=equipslot:doll:torso sel=nil layer=1
ZEDQA doll head then down: zone=charTabContent el=equipslot:doll:eyes sel=nil layer=1
ZEDQA doll then right (expect back): zone=charTabContent el=equipslot:doll:back sel=nil layer=1
ZEDQA doll then down (expect belt): zone=charTabContent el=equipslot:doll:arms sel=nil layer=1
ZEDQA doll then left (expect neck): zone=charTabContent el=equipslot:doll:neck sel=nil layer=1
ZEDQA doll then left (into the left band when the bands show, else leaves the doll): zone=charTabContent el=equipslot:doll:gorget sel=nil layer=1
ZEDQA doll view restored to list | DONE
```

### 16. zedqa_doll_v4.lua (`ZEDQA dollv4`) - PASS, 27 s

- go 16165 at 22:40:57
- screenshots: zqa_dollv4_3840x2160_wide.png, zqa_dollv4_3840x2160_dpad.png, zqa_dollv4_3840x2160_wide_pads.png, zqa_dollv4_3840x2160_card.png, zqa_dollv4_3840x2160_narrow.png

```text
[ZeD.QA] windows reset (R)
ZEDQA dollv4 start
[ZeD.QA] run #16 ok=true
ZEDQA dollv4 round 1: wearing 21 of 21
ZEDQA dollv4 PASS 38 small slots defined | 38
ZEDQA dollv4 PASS wide: bands show | drawer 840px = 480 units, screen 3840x2160
ZEDQA dollv4 PASS wide: 49 slot boxes (11 big + 38 small) | 49
ZEDQA dollv4 PASS wide: no slot overlaps another
ZEDQA dollv4 PASS wide: every box inside the drawer's width | 840
ZEDQA dollv4 PASS wide: the drawer is no wider than the full card (480 units) | 480.0 units
ZEDQA dollv4 PASS wide: a small slot is 18 units or more on screen | 18.3 units
ZEDQA dollv4 PASS wide: 11 leader lines, none crossing another | 11 lines, 0 crossings
ZEDQA dollv4 PASS wide: Back, Arms, Belt in that order down the right | 224,483,612
ZEDQA dollv4 PASS wide: arms' line is one straight run, belt's turns up | 4/8
ZEDQA dollv4 PASS every group name and place name has its words |
ZEDQA dollv4 PASS round 1 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS round 1 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 1 folded (data): every worn thing lands in its big slot (21 on) |
ZEDQA dollv4 PASS belly button ring, air tank, tail in their small slots
ZEDQA dollv4 empties 25, slots with things 27
ZEDQA dollv4 PASS charTabContent zone exists with the doll's stops | 81
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
ZEDQA dollv4 PASS a cap dropped on Head is taken | rect 160,199 82x82 clip 0,199 815x451 | loc base:hat
ZEDQA dollv4 PASS a cap dropped on a small slot that is not its place is refused
ZEDQA dollv4 PASS a ring dropped on the wrong small slot is refused
ZEDQA dollv4 PASS a ring dropped on its slot is taken | rect 43,597 32x32 clip 0,199 815x451
ZEDQA dollv4 PASS the ring was put on (vanilla's wear action ran)
ZEDQA dollv4 PASS the cap was put on
ZEDQA dollv4 PASS narrow: bands folded | drawer 385px = 220 units, screen 3840x2160
ZEDQA dollv4 PASS narrow: 11 big slot boxes, no small ones | 11
ZEDQA dollv4 PASS narrow: no slot overlaps another
ZEDQA dollv4 PASS narrow: every box inside the drawer's width | 385
ZEDQA dollv4 PASS narrow: the drawer is no wider than the full card (480 units) | 220.0 units
ZEDQA dollv4 PASS narrow: 11 leader lines, none crossing another | 11 lines, 0 crossings
ZEDQA dollv4 PASS narrow: Back, Arms, Belt in that order down the right | 3,185,276
ZEDQA dollv4 PASS narrow: arms' line is one straight run, belt's turns up | 4/8
ZEDQA dollv4 PASS narrow: every worn thing lands in its big slot (20 on) |
ZEDQA dollv4 PASS narrow: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS narrow: no small-slot zone left | 0
ZEDQA dollv4 narrow: Arms layers 3, Back 2, Legs 5, Belt 4, Hands 4
ZEDQA dollv4 PASS narrow: Back's card shows the folded layers (tail, satchel) | layers 2
ZEDQA dollv4 passed 59, failed 0 | DONE
```

### 17. zedqa_large.lua (`ZEDQA lg`) - PASS, 9 s

- go 16166 at 22:41:28
- screenshots: zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png

```text
[ZeD.QA] windows reset (R)
ZEDQA lg start
[ZeD.QA] run #17 ok=true
ZEDQA lg small: rowH 53 buttonH 46 titleBarH 46 | cat 151 wt 101 | equip slot col 140
ZEDQA lg large: rowH 60 buttonH 53 titleBarH 53 | cat 176 wt 117 | equip slot col 163
ZEDQA lg size back to small | DONE
```

### 18. zedqa_curtain.lua (`ZEDQA cu`) - WARN, 151 s

- go 16167 at 22:41:40
- 1 ERR line(s)
- screenshots: zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cu start
[ZeD.QA] run #18 ok=true
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
ZEDQA cu moved by rod World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2843,200 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
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
ZEDQA cu moved by rod Character rolled, before unroll: Character 494,200 903x735 rolled true (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
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
ZEDQA cu FAIL Loot World side down with the press: rolled false tab loot rods in UI 1
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
ZEDQA cu geometry checks 222, differences 1
ZEDQA cu at quit, unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu at quit, rolled: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 2643,400 903x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu DONE
```

### 19. zedqa_curtain2.lua (`ZEDQA cv`) - PASS, 11 s

- go 16168 at 22:44:14
- screenshots: zqa_cv_1.png, zqa_cv_2.png, zqa_cv_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cv start
[ZeD.QA] run #19 ok=true
ZEDQA cv health tab true
ZEDQA cv char before rolled false x 294 w 1617 right 1911 tab health content true rod - button true
ZEDQA cv roll true
ZEDQA cv char rolled rolled true x 294 w 903 right 1197 tab health content false rod 1197+714
ZEDQA cv skills tab true
ZEDQA cv char after switch rolled true x 294 w 903 right 1197 tab skills content false rod 1197+714
ZEDQA cv A on the tab (charContainerStrip)
ZEDQA cv char unrolled rolled false x 294 w 1617 right 1911 tab skills content true rod - (was x 294 w 1617)
ZEDQA cv world roll true
ZEDQA cv world rolled rolled true x 2643 w 903 right 3546 tab maps content false rod 1929+714
ZEDQA cv world after switch rolled true x 2643 w 903 right 3546 tab forage content false rod 1929+714
ZEDQA cv world unrolled rolled false x 1929 w 1617 right 3546 tab forage content true rod -
ZEDQA cv DONE
```

### 20. zedqa_navevents.lua (`ZEDQA ev`) - PASS, 5 s

- go 16169 at 22:44:28

```text
[ZeD.QA] windows reset (R)
ZEDQA ev start
[ZeD.QA] run #20 ok=true
ZEDQA ev 1 on the hammer row: Char charMainInv:invrow:6 (Claw Hammer)
ZEDQA ev 1 after A (expect the card's primary action): Char charItemCard:hverb_1
ZEDQA ev 1 after B (expect back on the hammer row): Char charMainInv:invrow:6 (Claw Hammer)
ZEDQA ev 2 Right (expect the strip): Char charTabContent:skill:Carving
ZEDQA ev 2 Left (expect back on the hammer row): Char charMainInv:invrow:6 (Claw Hammer)
ZEDQA ev 3 on the screwdriver: Char charMainInv:invrow:14 (Screwdriver)
ZEDQA ev 3 Left (expect the active tab): Char charTabBar:tab:loot
ZEDQA ev 3 Down: Char charTabBar:tab:equip
ZEDQA ev 3 A on: Char charTabBar:tab:equip
ZEDQA ev 3 after A on the tab (expect still on it): Char charTabBar:tab:equip
ZEDQA ev 3 Right (expect the tab's first control): Char charTabContent:equipslot:__disclosure
ZEDQA ev 3 Left (expect back on the tab): Char charTabBar:tab:equip
ZEDQA ev 4 on the screwdriver: Char charMainInv:invrow:14 (Screwdriver)
ZEDQA ev 4 after RB (World): World worldCtl:worldCtl:take
ZEDQA ev 4 after LB (expect back on the screwdriver): Char charMainInv:invrow:14 (Screwdriver)
ZEDQA ev 5 on the hammer: Char charMainInv:invrow:6 (Claw Hammer)
ZEDQA ev 5 after the hammer went (expect a neighbouring row): Char charMainInv:invrow:6 (Digital Watch)
ZEDQA ev 6 on the star tool: World worldTabContent:map:tool:star
ZEDQA ev 6 Down (expect the map): World worldTabContent:map:canvas:cursor
ZEDQA ev 6 Up (expect back on the star tool): World worldTabContent:map:tool:star
ZEDQA ev 6 Down, Left: World worldCtl:worldCtl:same
ZEDQA ev 6 Right (expect back on the map): World worldTabContent:map:canvas:cursor
ZEDQA ev 6 Right again: World worldTabBar:tab:maps
ZEDQA ev 7 on unfold: World worldTabContent:map:popout
ZEDQA ev 7 after unfold (expect the big map's window): Map popMapContent:map:canvas:cursor
ZEDQA ev 7 after B (expect the World window's map or unfold): World worldTabContent:map:popout
ZEDQA ev DONE
```

### 21. zedqa_navmap.lua (`ZEDQA nav`) - PASS, 9 s

- go 16170 at 22:44:37

```text
[ZeD.QA] windows reset (R)
ZEDQA nav start
[ZeD.QA] run #21 ok=true
ZEDQA nav char loot: 25 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav char loot STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:1(U) charCtl:xfer(D) charCtl:same(D) charCtl:near(D)
ZEDQA nav char loot charTabBar:tab:loot U>charMainInv:invrow:1~ D>tab:equip L>- R>charMainInv:invrow:6
ZEDQA nav char loot charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charMainInv:invrow:6
ZEDQA nav char loot charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charMainInv:invrow:6
ZEDQA nav char loot charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charMainInv:invrow:6
ZEDQA nav char loot charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charMainInv:invrow:6
ZEDQA nav char loot charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charMainInv:invrow:6
ZEDQA nav char loot charTabBar:tab:skills U>tab:journal D>charMainInv:invrow:10~ L>- R>charMainInv:invrow:6
ZEDQA nav char loot charMainInv:invrow:1 U>- D>invrow:2 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabBar:tab:loot R>view:list:player
ZEDQA nav char loot charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:12 U>invrow:11 D>charCtl:charCtl:near L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:view:list:player U>invrow:2~ D>invrow:3~ L>invrow:2 R>view:grid:player
ZEDQA nav char loot charMainInv:view:grid:player U>invrow:2~ D>invrow:3~ L>view:list:player R>charContainerStrip:container:1
ZEDQA nav char loot charContainerStrip:container:1 U>charMainInv:invrow:1~ D>charMainInv:invrow:3~ L>charMainInv:view:grid:player R>window:World
ZEDQA nav char loot charCtl:charCtl:xfer U>charMainInv:invrow:12 D>- L>charTabBar:tab:loot~ R>charCtl:same
ZEDQA nav char loot charCtl:charCtl:same U>charMainInv:invrow:12 D>- L>charCtl:xfer R>charCtl:near
ZEDQA nav char loot charCtl:charCtl:near U>charMainInv:invrow:12 D>- L>charCtl:same R>charContainerStrip:container:1
ZEDQA nav char equip: 61 targets | TRAP 7 {el:days,equipslot:INR,equipslot:GLV,equipslot:PNT,equipslot:SOC,equipslot:BOT,equipslot:BLT} | ISLAND 0 {}
ZEDQA nav char equip STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) equippart:Right Foot(D) equippart:Left Foot(D) invrow:1(U)
ZEDQA nav char equip charTabBar:tab:loot U>charMainInv:invrow:1~ D>tab:equip L>- R>charTabContent:equipslot:__disclosure
ZEDQA nav char equip charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charTabContent:equipslot:__disclosure
ZEDQA nav char equip charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charTabContent:el:save
ZEDQA nav char equip charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charTabContent:equipgroup:head
ZEDQA nav char equip charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charTabContent:equipgroup:torso
ZEDQA nav char equip charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charTabContent:equipgroup:arms
ZEDQA nav char equip charTabBar:tab:skills U>tab:journal D>charTabContent:equipgroup:legs~ L>- R>charTabContent:equipslot:GLV
ZEDQA nav char equip charTabContent:equipslot:__disclosure U>charTabBar:tab:equip~ D>el:loadout L>charTabBar:tab:equip R>equipview:list
ZEDQA nav char equip charTabContent:equipview:list U>charMainInv:invrow:2~ D>el:save L>equipslot:__disclosure R>equipview:doll
ZEDQA nav char equip charTabContent:equipview:doll U>charMainInv:invrow:2~ D>el:save L>equipslot:__disclosure R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:el:outfit U>equipslot:__disclosure D>equipgroup:head L>charTabBar:tab:equip R>el:loadout
ZEDQA nav char equip charTabContent:el:loadout U>equipslot:__disclosure D>equipgroup:head L>el:outfit R>el:days
ZEDQA nav char equip charTabContent:el:days [OWN D-PAD] U>equipslot:__disclosure D>equipgroup:head L>el:loadout R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:el:save U>equipslot:__disclosure D>equipgroup:head L>charTabBar:tab:equip R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:equippart:Head U>equipbelt:1 D>equippart:Neck L>equippart:Neck R>charCtl:charCtl:xfer~
ZEDQA nav char equip charTabContent:equippart:Neck U>equippart:Head D>equippart:Upper Torso L>charTabBar:tab:equip~ R>equippart:Head
ZEDQA nav char equip charTabContent:equippart:Upper Torso U>equippart:Neck D>equippart:Lower Torso L>equippart:Right Upper Arm R>equippart:Left Upper Arm
ZEDQA nav char equip charTabContent:equippart:Right Upper Arm U>equippart:Upper Torso D>equippart:Right Forearm L>equippart:Right Forearm R>equippart:Upper Torso
ZEDQA nav char equip charTabContent:equippart:Left Upper Arm U>equippart:Upper Torso D>equippart:Left Forearm L>equippart:Upper Torso R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Lower Torso U>equippart:Upper Torso D>equippart:Groin L>equippart:Right Upper Arm R>equippart:Groin
ZEDQA nav char equip charTabContent:equippart:Right Forearm U>equippart:Right Upper Arm D>equippart:Right Hand L>equippart:Right Hand R>equippart:Right Upper Leg
ZEDQA nav char equip charTabContent:equippart:Left Forearm U>equippart:Left Upper Arm D>equippart:Left Hand L>equippart:Groin R>equippart:Left Hand
ZEDQA nav char equip charTabContent:equippart:Groin U>equippart:Lower Torso D>equippart:Right Upper Leg L>equippart:Lower Torso R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Right Hand U>equippart:Right Forearm D>equippart:Right Upper Leg~ L>charTabBar:tab:equip~ R>equippart:Right Forearm
ZEDQA nav char equip charTabContent:equippart:Left Hand U>equippart:Left Forearm D>equippart:Left Upper Leg~ L>equippart:Left Forearm R>charCtl:charCtl:xfer~
ZEDQA nav char equip charTabContent:equippart:Right Upper Leg U>equippart:Groin D>equippart:Right Lower Leg L>equippart:Right Forearm R>equippart:Groin
ZEDQA nav char equip charTabContent:equippart:Left Upper Leg U>equippart:Groin D>equippart:Left Lower Leg L>equippart:Groin R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Right Lower Leg U>equippart:Right Upper Leg D>equippart:Right Foot L>equippart:Right Foot R>equippart:Right Upper Leg
ZEDQA nav char equip charTabContent:equippart:Left Lower Leg U>equippart:Left Upper Leg D>equippart:Left Foot L>equippart:Left Upper Leg R>equippart:Left Foot
ZEDQA nav char equip charTabContent:equippart:Right Foot U>equippart:Right Lower Leg D>- L>charTabBar:tab:equip~ R>equippart:Right Lower Leg
ZEDQA nav char equip charTabContent:equippart:Left Foot U>equippart:Left Lower Leg D>- L>equippart:Left Lower Leg R>charCtl:charCtl:xfer~
ZEDQA nav char equip charTabContent:equipgroup:head U>el:save D>equipgroup:torso L>charTabBar:tab:equip R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:equipgroup:torso U>equipgroup:head D>equipslot:INR L>charTabBar:tab:equip R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:equipgroup:arms U>equipslot:INR D>equipslot:GLV L>charTabBar:tab:equip R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:equipgroup:legs U>equipslot:GLV D>equipslot:PNT L>charTabBar:tab:equip R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:equipgroup:held U>equipslot:BOT D>equipslot:BLT L>charTabBar:tab:equip~ R>charCtl:charCtl:xfer
ZEDQA nav char equip charTabContent:equipslot:INR [OWN D-PAD] U>equipgroup:torso D>equipgroup:arms L>charTabBar:tab:equip R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:equipslot:GLV [OWN D-PAD] U>equipgroup:arms D>equipgroup:legs L>charTabBar:tab:equip R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:equipslot:PNT [OWN D-PAD] U>equipgroup:legs D>equipslot:SOC L>charTabBar:tab:equip~ R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:equipslot:SOC [OWN D-PAD] U>equipslot:PNT D>equipslot:BOT L>charTabBar:tab:equip~ R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:equipslot:BOT [OWN D-PAD] U>equipslot:SOC D>equipgroup:held L>charTabBar:tab:equip~ R>charMainInv:invrow:6
ZEDQA nav char equip charTabContent:equipslot:BLT [OWN D-PAD] U>equipgroup:held D>equipbelt:1 L>charTabBar:tab:equip~ R>charCtl:charCtl:xfer
ZEDQA nav char equip charTabContent:equipbelt:1 U>equipslot:BLT D>equippart:Head L>charTabBar:tab:equip~ R>charCtl:charCtl:xfer~
ZEDQA nav char equip charMainInv:invrow:1 U>- D>invrow:2 L>charTabContent:equipslot:__disclosure R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabContent:equipslot:__disclosure R>view:list:player
ZEDQA nav char equip charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabContent:equipslot:__disclosure R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabContent:el:save R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabContent:el:save R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabContent:equipgroup:head R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabContent:equipslot:INR R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabContent:equipgroup:arms R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabContent:equipslot:GLV R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charTabContent:equipslot:PNT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charTabContent:equipslot:SOC R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:12 U>invrow:11 D>charCtl:charCtl:near L>charTabContent:equipslot:BOT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:view:list:player U>invrow:2~ D>invrow:3~ L>invrow:2 R>view:grid:player
ZEDQA nav char equip charMainInv:view:grid:player U>invrow:2~ D>invrow:3~ L>view:list:player R>charContainerStrip:container:1
ZEDQA nav char equip charContainerStrip:container:1 U>charMainInv:invrow:1~ D>charMainInv:invrow:3~ L>charMainInv:view:grid:player R>window:World
ZEDQA nav char equip charCtl:charCtl:xfer U>charMainInv:invrow:12 D>charTabContent:equipslot:BLT~ L>charTabContent:equipgroup:held R>charCtl:same
ZEDQA nav char equip charCtl:charCtl:same U>charMainInv:invrow:12 D>charTabContent:equipslot:BLT~ L>charCtl:xfer R>charCtl:near
ZEDQA nav char equip charCtl:charCtl:near U>charMainInv:invrow:12 D>charTabContent:equipslot:BLT~ L>charCtl:same R>charContainerStrip:container:1
ZEDQA nav char health: 52 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav char health STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:1(U) charCtl:xfer(D) charCtl:same(D) charCtl:near(D)
ZEDQA nav char thermal: 51 targets | TRAP 1 {thermal:__gridscroll} | ISLAND 0 {}
ZEDQA nav char thermal STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) thermal:__gridscroll(D) invrow:1(U)
ZEDQA nav char identity: 38 targets | TRAP 1 {hb:part} | ISLAND 0 {}
ZEDQA nav char identity STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) identity:trait:Smoker(D) invrow:1(U)
ZEDQA nav char journal: 32 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav char journal STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:1(U) charCtl:xfer(D) charCtl:same(D) charCtl:near(D)
ZEDQA nav char skills: 85 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav char skills STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) training:col1_Foraging(D) training:col2_Trapping(D) invrow:1(U)
ZEDQA nav world loot: 13 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world loot STUCK: container:3(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world loot worldContainerStrip:container:3 U>- D>container:1 L>window:Character R>worldCtl:worldCtl:take
ZEDQA nav world loot worldContainerStrip:container:1 U>container:3 D>container:2 L>window:Character R>worldCtl:worldCtl:take
ZEDQA nav world loot worldContainerStrip:container:2 U>container:1 D>worldCtl:worldCtl:take~ L>window:Character R>worldCtl:worldCtl:take
ZEDQA nav world loot worldTabBar:tab:loot U>- D>tab:craft L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:craft U>tab:loot D>tab:build L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:build U>tab:craft D>tab:furniture L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:furniture U>tab:build D>tab:maps L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:maps U>tab:furniture D>tab:forage L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:forage U>tab:maps D>tab:animals L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:animals U>tab:forage D>tab:vehicle L>worldCtl:worldCtl:same~ R>-
ZEDQA nav world loot worldTabBar:tab:vehicle U>tab:animals D>worldCtl:worldCtl:same~ L>worldCtl:worldCtl:same~ R>-
ZEDQA nav world loot worldCtl:worldCtl:take U>worldContainerStrip:container:3 D>- L>worldContainerStrip:container:3 R>worldCtl:same
ZEDQA nav world loot worldCtl:worldCtl:same U>worldContainerStrip:container:3 D>- L>worldCtl:take R>worldTabBar:tab:loot~
ZEDQA nav world craft: 24 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world craft STUCK: container:3(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world build: 21 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world build STUCK: container:3(U) build:catDrop(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world furniture: 18 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world furniture STUCK: container:3(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world maps: 32 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world maps STUCK: container:3(U) map:tool:house(U) map:tool:target(U) map:tool:skull(U) map:tool:star(U) map:tool:cross(U) map:tool:checkmark(U) map:tool:text(U) map:popout(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world maps worldContainerStrip:container:3 U>- D>container:1 L>window:Character R>worldCtl:worldCtl:take
ZEDQA nav world maps worldContainerStrip:container:1 U>container:3 D>container:2 L>window:Character R>worldCtl:worldCtl:take
ZEDQA nav world maps worldContainerStrip:container:2 U>container:1 D>worldCtl:worldCtl:take~ L>window:Character R>worldCtl:worldCtl:take
ZEDQA nav world maps worldTabContent:map:disclosure U>worldContainerStrip:container:3 D>map:ext:key L>worldCtl:worldCtl:same R>map:tool:house
ZEDQA nav world maps worldTabContent:map:tool:house U>- D>map:ext:key L>map:disclosure R>map:tool:target
ZEDQA nav world maps worldTabContent:map:tool:target U>- D>map:canvas:cursor L>map:tool:house R>map:tool:skull
ZEDQA nav world maps worldTabContent:map:tool:skull U>- D>map:canvas:cursor L>map:tool:target R>map:tool:star
ZEDQA nav world maps worldTabContent:map:tool:star U>- D>map:canvas:cursor L>map:tool:skull R>map:tool:cross
ZEDQA nav world maps worldTabContent:map:tool:cross U>- D>map:canvas:cursor L>map:tool:star R>map:tool:checkmark
ZEDQA nav world maps worldTabContent:map:tool:checkmark U>- D>map:canvas:cursor L>map:tool:cross R>map:tool:text
ZEDQA nav world maps worldTabContent:map:tool:text U>- D>map:canvas:cursor L>map:tool:checkmark R>map:color:1
ZEDQA nav world maps worldTabContent:map:color:1 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:tool:text R>map:color:2
ZEDQA nav world maps worldTabContent:map:color:2 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:color:1 R>map:color:3
ZEDQA nav world maps worldTabContent:map:color:3 U>worldTabBar:tab:maps~ D>map:style:survey L>map:color:2 R>map:color:4
ZEDQA nav world maps worldTabContent:map:color:4 U>worldTabBar:tab:maps~ D>map:style:survey L>map:color:3 R>map:color:5
ZEDQA nav world maps worldTabContent:map:color:5 U>worldTabBar:tab:maps~ D>map:style:survey L>map:color:4 R>map:popout
ZEDQA nav world maps worldTabContent:map:style:survey U>map:color:5 D>map:canvas:cursor L>map:ext:key R>map:style:color
ZEDQA nav world maps worldTabContent:map:style:color U>map:color:5~ D>map:canvas:cursor L>map:style:survey R>map:style:paper
ZEDQA nav world maps worldTabContent:map:style:paper U>map:popout D>map:canvas:cursor L>map:style:color R>worldTabBar:tab:maps
ZEDQA nav world maps worldTabContent:map:popout U>- D>map:style:paper L>map:color:5 R>worldTabBar:tab:maps
ZEDQA nav world maps worldTabContent:map:ext:key U>map:disclosure D>map:canvas:cursor L>worldCtl:worldCtl:same R>map:style:survey
ZEDQA nav world maps worldTabContent:map:canvas:cursor U>map:style:survey D>worldTabBar:tab:maps~ L>worldCtl:worldCtl:same R>worldTabBar:tab:maps
ZEDQA nav world maps worldTabBar:tab:loot U>- D>tab:craft L>worldTabContent:map:popout R>-
ZEDQA nav world maps worldTabBar:tab:craft U>tab:loot D>tab:build L>worldTabContent:map:style:paper R>-
ZEDQA nav world maps worldTabBar:tab:build U>tab:craft D>tab:furniture L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:furniture U>tab:build D>tab:maps L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:maps U>tab:furniture D>tab:forage L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:forage U>tab:maps D>tab:animals L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:animals U>tab:forage D>tab:vehicle L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:vehicle U>tab:animals D>worldCtl:worldCtl:same~ L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldCtl:worldCtl:take U>worldContainerStrip:container:3 D>- L>worldContainerStrip:container:3 R>worldCtl:same
ZEDQA nav world maps worldCtl:worldCtl:same U>worldContainerStrip:container:3 D>- L>worldCtl:take R>worldTabContent:map:canvas:cursor
ZEDQA nav world forage: 16 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world forage STUCK: container:3(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world animals: 16 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world animals STUCK: container:3(U) animals:createzone(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world vehicle: 14 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world vehicle STUCK: container:3(U) mech:inspect(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav DONE
```

### 22. zedqa_loot_tabs.lua (`ZEDQA lt`) - PASS, 1 s

- go 16171 at 22:44:49

```text
[ZeD.QA] windows reset (R)
ZEDQA lt start
[ZeD.QA] run #22 ok=true
ZEDQA lt Character loot drawer false | World loot drawer false
ZEDQA lt DONE
```

### 23. zedqa_world_pad_take.lua (`ZEDQA wpt`) - PASS, 61 s

- go 16172 at 22:44:54

```text
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #23 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Trunk, 3:Garbage Bag, 4:Ground | stops container:4@0, container:1@100, container:2@163, container:3@226
ZEDQA wpt PASS the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldTabBar:tab:maps
ZEDQA wpt PASS RB lands in the World window on a lit element
ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
ZEDQA wpt 1 Right from the Character window's right edge: World worldTabBar:tab:maps
ZEDQA wpt PASS the D-pad across from the Character window lands in the World window, lit
ZEDQA wpt 2 strip: World worldContainerStrip:container:4
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
ZEDQA wpt 3 timing: card buttons ready after 7 ticks, 6 frames; focus in the card after 7 ticks, 6 frames (watched 7 ticks, 6 frames)
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
ZEDQA wpt PASS 6 A on a row: focus is on the card's primary action (EQUIP)
ZEDQA wpt 6 after B: Char charMainInv:invrow:2 (Baseball Bat)
ZEDQA wpt PASS B on the Character window's card goes back to the row
ZEDQA wpt PASS 8 X on a row opens the context menu
ZEDQA wpt 8 after the menu's B: World worldMainInv:invrow:2 (Corkscrew)
ZEDQA wpt PASS 8 the menu closed: focus is back on the same row, lit
ZEDQA wpt 8 after hold A: World worldMainInv:invrow:2 (Tweezers)
ZEDQA wpt PASS 8 hold A moved the hammer out of the crate
ZEDQA wpt 8 a moment later: World worldMainInv:invrow:2 (Tweezers)
ZEDQA wpt PASS 8 after the transfer focus is on a neighbour in the same panel, lit
ZEDQA wpt PASS 8 a stray Left with a window open stays in the window (no way into the belt)
ZEDQA wpt PASS 8 with the windows put away, Left opens the Character wheel (not the belt)
ZEDQA wpt PASS 8 B leaves the belt in one press
ZEDQA wpt PASS 8 Right past the belt's last box leaves it
ZEDQA wpt PASS 8 Down (the screen's edge) leaves the belt
ZEDQA wpt 7 tabs: 13 at small and large
ZEDQA wpt PASS 7 Char equip small pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 639 of 650)
ZEDQA wpt PASS 7 Char equip small wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 624 of 650)
ZEDQA wpt PASS 7 Char health small pad: Down reaches the lowest control of its column exercise:time:dec and it is in view (bottom 526 of 650)
ZEDQA wpt PASS 7 Char health small wheel: the lowest control exercise:time:dec is in view at the bottom (bottom 526 of 650)
ZEDQA wpt PASS 7 Char health small Health: scrolled to the end, drawn 958 px in a 585 px view
ZEDQA wpt PASS 7 Char thermal small pad: Down reaches the lowest control of its column thermal:__gridscroll and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 Char thermal small wheel: the lowest control thermal:__gridscroll is in view at the bottom (bottom 650 of 650)
ZEDQA wpt PASS 7 Char identity small pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 564 of 650)
ZEDQA wpt PASS 7 Char identity small wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 564 of 650)
ZEDQA wpt PASS 7 Char journal small pad: Down reaches the lowest control of its column journal:group:6_1993 and it is in view (bottom 443 of 650)
ZEDQA wpt PASS 7 Char journal small wheel: the lowest control journal:group:6_1993 is in view at the bottom (bottom 443 of 650)
ZEDQA wpt PASS 7 Char skills small pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 Char skills small wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 634 of 650)
ZEDQA wpt PASS 7 World craft small pad: Down reaches the lowest control of its column craft:row:UnpackCigarettes and it is in view (bottom 270 of 650)
ZEDQA wpt PASS 7 World craft small wheel: the lowest control craft:row:UnpackCigarettes is in view at the bottom (bottom 270 of 650)
ZEDQA wpt PASS 7 World build small pad: Down reaches the lowest control of its column build:section:all and it is in view (bottom 126 of 650)
ZEDQA wpt PASS 7 World build small wheel: the lowest control build:section:all is in view at the bottom (bottom 126 of 650)
ZEDQA wpt PASS 7 World furniture small pad: Down reaches the lowest control of its column fur:obj:1 and it is in view (bottom 468 of 650)
ZEDQA wpt PASS 7 World furniture small wheel: the lowest control fur:obj:1 is in view at the bottom (bottom 468 of 650)
ZEDQA wpt PASS 7 World maps small pad: Down reaches the lowest control of its column map:canvas:cursor and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 World maps small wheel: the lowest control map:canvas:cursor is in view at the bottom (bottom 650 of 650)
ZEDQA wpt PASS 7 World forage small pad: Down reaches the lowest control of its column forage:disclosure and it is in view (bottom 344 of 650)
ZEDQA wpt PASS 7 World forage small wheel: the lowest control forage:disclosure is in view at the bottom (bottom 344 of 650)
ZEDQA wpt PASS 7 World animals small pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World animals small wheel: the lowest control animals:createzone is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World vehicle small pad: Down reaches the lowest control of its column mech:inspect and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World vehicle small wheel: the lowest control mech:inspect is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 620 of 638)
ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 610 of 638)
ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control of its column bodypart:Left Foot and it is in view (bottom 149 of 638)
ZEDQA wpt PASS 7 Char health large wheel: the lowest control exercise:time:dec is in view at the bottom (bottom 152 of 638)
ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 1013 px in a 564 px view
ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control of its column thermal:__gridscroll and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:__gridscroll is in view at the bottom (bottom 638 of 638)
ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 553 of 638)
ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 541 of 638)
ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control of its column journal:group:6_1993 and it is in view (bottom 504 of 638)
ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:group:6_1993 is in view at the bottom (bottom 476 of 638)
ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 620 of 638)
ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control of its column craft:row:UnpackCigarettes and it is in view (bottom 308 of 638)
ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:row:UnpackCigarettes is in view at the bottom (bottom 308 of 638)
ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control of its column build:section:all and it is in view (bottom 144 of 638)
ZEDQA wpt PASS 7 World build large wheel: the lowest control build:section:all is in view at the bottom (bottom 144 of 638)
ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control of its column fur:obj:1 and it is in view (bottom 534 of 638)
ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:obj:1 is in view at the bottom (bottom 534 of 638)
ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control of its column map:canvas:cursor and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:canvas:cursor is in view at the bottom (bottom 638 of 638)
ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control of its column forage:disclosure and it is in view (bottom 393 of 638)
ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:disclosure is in view at the bottom (bottom 393 of 638)
ZEDQA wpt PASS 7 World animals large pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:createzone is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World vehicle large pad: Down reaches the lowest control of its column mech:inspect and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World vehicle large wheel: the lowest control mech:inspect is in view at the bottom (bottom 628 of 638)
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA wpt 93 passed, 0 failed
ZEDQA wpt DONE
```

### 24. zedqa_furniture.lua (`ZEDQA fu`) - PASS, 2 s

- go 16173 at 22:45:58

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #24 ok=true
ZEDQA fu tab=true cursor=true mode=pickup
ZEDQA fu furniture square=875,13017
ZEDQA fu pickup capture name=nil can=false facts=nil notes=nil
ZEDQA fu mode place -> cursor mode=place target=false can=false
ZEDQA fu mode rotate -> cursor mode=rotate target=false can=false
ZEDQA fu mode scrap -> cursor mode=scrap target=false can=false
ZEDQA fu mode repair -> cursor mode=repair target=false can=false
ZEDQA fu mode pickup -> cursor mode=pickup target=false can=false
ZEDQA fu zones fur:mode:pickup,fur:mode:place,fur:mode:rotate,fur:mode:scrap,fur:mode:repair
ZEDQA fu after leaving tab=false cursor=false active=false
```

### 25. zedqa_tabicons.lua (`ZEDQA ti`) - PASS, 3 s

- go 16174 at 22:46:03
- screenshots: zqa_tabicons.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #25 ok=true
ZEDQA ti DONE
```

### 26. zedqa_tabs_lit.lua (`ZEDQA tl`) - PASS, 6 s

- go 16175 at 22:46:10
- screenshots: zqa_tabs_1.png, zqa_tabs_2.png, zqa_tabs_3.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #26 ok=true
ZEDQA tl char true world true TabPx true
ZEDQA tl active loot / loot
ZEDQA tl restored; DONE
```

### 27. zedqa_win.lua (`ZEDQA win`) - PASS, 5 s

- go 16176 at 22:46:19
- screenshots: zedqa_win_200.png, zedqa_win_100.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #27 ok=true
ZEDQA win natural root=1.75 T.scale=1.75 rowH=53 sp.md=25 F2H=29.1484375 char=true 1134,0 777x735 world=true 1929,0 777x735
ZEDQA win forced1 root=1 T.scale=1 rowH=30 sp.md=14 F2H=16.65625 char=true 1134,0 777x735 world=true 1929,0 777x735
ZEDQA win done root=1.75
```

### 28. zedqa_rootchange.lua (`ZEDQA rc`) - PASS, 6 s

- go 16177 at 22:46:27
- screenshots: zedqa_rc_100.png, zedqa_rc_200.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #28 ok=true
ZEDQA rc open at natural root=1.75 applied=1.75 char=true 777x735 at 1134,0 world=true 777x735 rowH=53
ZEDQA rc after override 1.0 root=1 applied=1 char=true 444x420 at 648,0 world=true 444x420 rowH=30
ZEDQA rc after override cleared root=1.75 applied=1.75 char=true 777x735 at 1134,0 world=true 777x735 rowH=53
ZEDQA rc done
```

### 29. zedqa_scalewalk.lua (`ZEDQA sw`) - PASS, 58 s

- go 16178 at 22:46:37
- screenshots: zedqa_sw_200_char_loot.png, zedqa_sw_200_char_equip.png, zedqa_sw_200_char_health.png, zedqa_sw_200_char_thermal.png, zedqa_sw_200_char_identity.png, zedqa_sw_200_char_journal.png, zedqa_sw_200_char_skills.png, zedqa_sw_200_world_loot.png, zedqa_sw_200_world_craft.png, zedqa_sw_200_world_build.png, zedqa_sw_200_world_furniture.png, zedqa_sw_200_world_maps.png, zedqa_sw_200_world_forage.png, zedqa_sw_200_world_animals.png, zedqa_sw_200_world_vehicle.png, zedqa_sw_100_char_loot.png, zedqa_sw_100_char_equip.png, zedqa_sw_100_char_health.png, zedqa_sw_100_char_thermal.png, zedqa_sw_100_char_identity.png, zedqa_sw_100_char_journal.png, zedqa_sw_100_char_skills.png, zedqa_sw_100_world_loot.png, zedqa_sw_100_world_craft.png, zedqa_sw_100_world_build.png, zedqa_sw_100_world_furniture.png, zedqa_sw_100_world_maps.png, zedqa_sw_100_world_forage.png, zedqa_sw_100_world_animals.png, zedqa_sw_100_world_vehicle.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sw armed
[ZeD.QA] run #29 ok=true
ZEDQA sw char tabs loot,equip,health,thermal,identity,journal,skills
ZEDQA sw shot 200 char loot active=loot win=1134,0 777x735
ZEDQA sw shot 200 char equip active=equip win=294,0 1617x735
ZEDQA sw fit 200 equip: strip ends 63, drawer 63-903, inventory starts 903
ZEDQA sw shot 200 char health active=health win=294,0 1617x735
ZEDQA sw fit 200 health: strip ends 63, drawer 63-903, inventory starts 903
ZEDQA sw shot 200 char thermal active=thermal win=294,0 1617x735
ZEDQA sw fit 200 thermal: strip ends 63, drawer 63-903, inventory starts 903
ZEDQA sw shot 200 char identity active=identity win=294,0 1617x735
ZEDQA sw fit 200 identity: strip ends 63, drawer 63-903, inventory starts 903
ZEDQA sw shot 200 char journal active=journal win=294,0 1617x735
ZEDQA sw fit 200 journal: strip ends 63, drawer 63-903, inventory starts 903
ZEDQA sw shot 200 char skills active=skills win=294,0 1617x735
ZEDQA sw fit 200 skills: strip ends 63, drawer 63-903, inventory starts 903
ZEDQA sw world tabs loot,craft,build,furniture,maps,forage,animals,vehicle
ZEDQA sw shot 200 world loot active=loot win=1929,0 777x735
ZEDQA sw fit 200 loot: container strip ends 63, list starts 63, drawer 714-714, tab strip 714-777, window 777
ZEDQA sw shot 200 world craft active=craft win=1929,0 1617x735
ZEDQA sw fit 200 craft: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
ZEDQA sw shot 200 world build active=build win=1929,0 1617x735
ZEDQA sw fit 200 build: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
ZEDQA sw shot 200 world furniture active=furniture win=1929,0 1617x735
ZEDQA sw fit 200 furniture: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
ZEDQA sw shot 200 world maps active=maps win=1929,0 1617x735
ZEDQA sw fit 200 maps: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
ZEDQA sw shot 200 world forage active=forage win=1929,0 1617x735
ZEDQA sw fit 200 forage: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
ZEDQA sw shot 200 world animals active=animals win=1929,0 1617x735
ZEDQA sw fit 200 animals: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
ZEDQA sw shot 200 world vehicle active=vehicle win=1929,0 1617x735
ZEDQA sw fit 200 vehicle: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
ZEDQA sw char tabs loot,equip,health,thermal,identity,journal,skills
ZEDQA sw shot 100 char loot active=loot win=1134,0 777x735
ZEDQA sw shot 100 char equip active=equip win=654,0 1257x735
ZEDQA sw fit 100 equip: strip ends 36, drawer 36-516, inventory starts 516
ZEDQA sw shot 100 char health active=health win=654,0 1257x735
ZEDQA sw fit 100 health: strip ends 36, drawer 36-516, inventory starts 516
ZEDQA sw shot 100 char thermal active=thermal win=654,0 1257x735
ZEDQA sw fit 100 thermal: strip ends 36, drawer 36-516, inventory starts 516
ZEDQA sw shot 100 char identity active=identity win=654,0 1257x735
ZEDQA sw fit 100 identity: strip ends 36, drawer 36-516, inventory starts 516
ZEDQA sw shot 100 char journal active=journal win=654,0 1257x735
ZEDQA sw fit 100 journal: strip ends 36, drawer 36-516, inventory starts 516
ZEDQA sw shot 100 char skills active=skills win=654,0 1257x735
ZEDQA sw fit 100 skills: strip ends 36, drawer 36-516, inventory starts 516
ZEDQA sw world tabs loot,craft,build,furniture,maps,forage,animals,vehicle
ZEDQA sw shot 100 world loot active=loot win=1929,0 777x735
ZEDQA sw fit 100 loot: container strip ends 36, list starts 36, drawer 741-741, tab strip 741-777, window 777
ZEDQA sw shot 100 world craft active=craft win=1929,0 1257x735
ZEDQA sw fit 100 craft: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
ZEDQA sw shot 100 world build active=build win=1929,0 1257x735
ZEDQA sw fit 100 build: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
ZEDQA sw shot 100 world furniture active=furniture win=1929,0 1257x735
ZEDQA sw fit 100 furniture: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
ZEDQA sw shot 100 world maps active=maps win=1929,0 1257x735
ZEDQA sw fit 100 maps: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
ZEDQA sw shot 100 world forage active=forage win=1929,0 1257x735
ZEDQA sw fit 100 forage: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
ZEDQA sw shot 100 world animals active=animals win=1929,0 1257x735
ZEDQA sw fit 100 animals: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
ZEDQA sw shot 100 world vehicle active=vehicle win=1929,0 1257x735
ZEDQA sw fit 100 vehicle: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
ZEDQA sw done root=1.75
```

### 30. zedqa_uiscale.lua (`ZEDQA scale`) - PASS, 12 s

- go 16179 at 22:47:38
- screenshots: zedqa_scale_auto.png, zedqa_scale_x150.png, zedqa_scale_x100.png, zedqa_scale_auto_back.png, zedqa_scale_restored.png

```text
[ZeD.QA] windows reset (R)
ZEDQA scale armed
[ZeD.QA] run #30 ok=true
ZEDQA scale auto option=7 userScale=1.75 root=1.75 iconDrawn=28 iconTex=24x24 char=777x735 world=777x735
ZEDQA scale x150 option=6 userScale=1.5 root=1.5 iconDrawn=24 iconTex=24x24 char=666x630 world=666x630
ZEDQA scale x100 option=4 userScale=1 root=1 iconDrawn=16 iconTex=16x16 char=444x420 world=444x420
ZEDQA scale auto_back option=1 userScale=nil root=2 iconDrawn=32 iconTex=32x32 char=888x840 world=888x840
ZEDQA scale restored option=7 userScale=1.75 root=1.75 iconDrawn=28 iconTex=24x24 char=777x735 world=777x735
ZEDQA scale done
```

### 31. zedqa_mapshot.lua (`ZEDQA ms`) - PASS, 4 s

- go 16180 at 22:47:53
- screenshots: zqa_ms_1.png, zqa_ms_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ms start
[ZeD.QA] run #31 ok=true
ZEDQA ms world 1929,0 1617x735 tab maps
ZEDQA ms DONE
```

### 32. zedqa_mapstyles.lua (`ZEDQA mst`) - PASS, 13 s

- go 16181 at 22:48:01
- screenshots: zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png

```text
[ZeD.QA] windows reset (R)
ZEDQA mst start
[ZeD.QA] run #32 ok=true
ZEDQA mst survey: style survey zoom 13 images 2
ZEDQA mst color: style color zoom 13 images 2
ZEDQA mst paper: style paper zoom 13 images 1
ZEDQA mst DONE
```

### 33. zedqa_flyers.lua (`ZEDQA fl`) - PASS, 6 s

- go 16182 at 22:48:17
- screenshots: zqa_fl_1.png, zqa_fl_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA fl start
[ZeD.QA] run #33 ok=true
ZEDQA fl read pieces: 14
ZEDQA fl piece mccoyloggingcorp
ZEDQA fl read now: 15
ZEDQA fl forgot true read 14
ZEDQA fl DONE
```

### 34. zedqa_flyermap.lua (`ZEDQA fm`) - PASS, 11 s

- go 16183 at 22:48:27
- screenshots: zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png

```text
[ZeD.QA] windows reset (R)
ZEDQA fm start
[ZeD.QA] run #34 ok=true
ZEDQA fm read 16 (added 2)
ZEDQA fm tracker ticked the test place: true
ZEDQA fm pins on paper: muldraughbakesale, fossoil1(done), ustoreitmuldraugh, sunstarmotel(done)
ZEDQA fm hover: sunstarmotel
ZEDQA fm reader open true media sunstarmotel title Angel Cross + Sunstar Motel
ZEDQA fm flash true
ZEDQA fm read back to 14
ZEDQA fm DONE
```

### 35. zedqa_mapnotes.lua (`ZEDQA mnote`) - PASS, 8 s

- go 16184 at 22:48:41
- screenshots: zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png

```text
[ZeD.QA] windows reset (R)
ZEDQA mnote start
[ZeD.QA] run #35 ok=true
ZEDQA mnote gave 2 (pencil / eraser)
ZEDQA mnote map bound to the world map item: true
ZEDQA mnote before: store marks 9 | vanilla api marks 9 of 72 symbols (the rest are the map's own labels)
ZEDQA mnote text tool armed: true
ZEDQA mnote after note: store 9 -> 10 | vanilla api 9 -> 10 | found in store true | found by vanilla api true
ZEDQA mnote note ink 1 rgb 0.200 0.200 0.200 scale 0.6660000085830688 layer text-note
ZEDQA mnote star tool armed: true
ZEDQA mnote star as vanilla's Star: true ink 1 | store 11
ZEDQA mnote migration: first run added 2 (11 -> 13), second 0 (13), flag cleared 0 (13)
ZEDQA mnote migrated note ink 4 (want 4) | star ink 3 (want 3) | done flag true
ZEDQA mnote cursor finds the note: true
ZEDQA mnote cursor ui 420,260 | engine hit note 'ZEDQA note 40163' at world 809.0,12971.3 ui 420,282 | found note 'ZEDQA note 40163' at world 809.0,12971.3 ui 420,282 | the note note 'ZEDQA note 40163' at world 809.0,12971.3 ui 420,282
ZEDQA mnote menu: delete true | edit note true | change colour true | share false (multiplayer false)
ZEDQA mnote after delete: store 13 -> 12 | vanilla api 13 -> 12 | still found false / false
ZEDQA mnote removal: made a note true and a star true | store 12 -> 14
ZEDQA mnote removal: note true (14 -> 13), star true (-> 12), stale note again false (-> 12)
ZEDQA mnote style paper: map style paper | label layers 8 | strongest label alpha 0 | note hand alpha 255
ZEDQA mnote style survey: map style survey | label layers 8 | strongest label alpha 255 | note hand alpha 255
ZEDQA mnote style color: map style color | label layers 8 | strongest label alpha 255 | note hand alpha 255
ZEDQA mnote style back to survey
ZEDQA mnote cleanup: removed 3 marks | store 9 (started 9) | modData back
ZEDQA mnote DONE
```

### 36. zedqa_journal_refs.lua (`ZEDQA jr`) - PASS, 4 s

- go 16185 at 22:48:52
- screenshots: zqa_jr_01_diary.png, zqa_jr_02_flyers.png

```text
[ZeD.QA] windows reset (R)
ZEDQA jr start
[ZeD.QA] run #36 ok=true
ZEDQA jr DONE
```

### 37. zedqa_journal_readers.lua (`ZEDQA jrd`) - PASS, 18 s

- go 16186 at 22:49:00
- screenshots: zqa_jr_01_papers.png, zqa_jr_02_unread_look.png, zqa_jr_03_read_look.png, zqa_jr_04_notebooks.png, zqa_jr_05_written.png, zqa_jr_06_into.png, zqa_jr_07_logged.png

```text
[ZeD.QA] windows reset (R)
ZEDQA jrd start
[ZeD.QA] run #37 ok=true
ZEDQA jrd papers 3 books 1 zones 7
ZEDQA jrd unread look zones back,read
ZEDQA jrd read look zones back,full,place:1,words
ZEDQA jrd note field true page 1
ZEDQA jrd light after 1 ticks: tooDark false
ZEDQA jrd ok written line on page 1
ZEDQA jrd log entry saw 3 of them by the gas station around noon | source Supply runs p1
ZEDQA jrd book p1 now day 3. truck still wont start. tried the battery / from the van on 31W, nothing. maybe its the starter / fossoil on the flyer too. go round back / saw 3 of them by the gas station around noon
ZEDQA jrd DONE (newspaper had been read before: false)
```

### 38. zedqa_lists.lua (`ZEDQA ls`) - PASS, 16 s

- go 16187 at 22:49:21
- screenshots: zqa_ls_01_page_480.png, zqa_ls_02_page_480_lines.png, zqa_ls_03_stepper.png, zqa_ls_04_ask_delete.png, zqa_ls_05_rightclick_list.png, zqa_ls_06_rightclick_strip.png, zqa_ls_07_card_inlists.png, zqa_ls_08_mark_popup.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ls start
[ZeD.QA] run #38 ok=true
ZEDQA ls items: crowbar true water 0.800000011920929
ZEDQA ls ok crowbar is gear (inv, any)
ZEDQA ls ok bandages are a fixed supply
ZEDQA ls carry: 16 lines, gear 11 supply 5
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
ZEDQA ls ready 15 of 16
ZEDQA ls ok store is plain values
ZEDQA ls ok round trip 2:16:QA carry
ZEDQA ls page: drawer 840 stacked true zones 60
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
ZEDQA ls ok page: Remove takes the line off (15)
ZEDQA ls doomed 4
ZEDQA ls ok Delete asks first
ZEDQA ls ok the question's two answers are the only stops (jl:ask:cancel,jl:ask:verb)
ZEDQA ls ok Delete in the band deletes
ZEDQA ls list look: Attach, Place Item, Put in Container (Crate), Favorite, Set Unwanted, Move to, |, Craft, Set to be Unusable in Recipes, |, Equip in Both Hands, Equip Primary, Equip Secondary, |, Drop, |, Save to loadout, |, Rename
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

### 39. zedqa_restock.lua (`ZEDQA rst`) - PASS, 60 s

- go 16188 at 22:49:41
- screenshots: zqa_rst_01_bar_ghosts.png, zqa_rst_02_todo.png, zqa_rst_02b_todo_lines.png, zqa_rst_03_ask_band.png, zqa_rst_04_after_hardcore.png, zqa_rst_05_pin_accessible.png, zqa_rst_06_pin_casual.png, zqa_rst_07_long_trip.png, zqa_rst_07b_long_trip_table.png, zqa_rst_08_unpack.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rst start
[ZeD.QA] run #39 ok=true
ZEDQA rst fixture: building 875,12964, standing at 885,13029 (18 from 892,13040)
ERROR: General f:53257 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:53262 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA rst built: crateA true crateB true locker true crateF true
ZEDQA rst set aside: 1 things holding water, 0 katanas
ZEDQA rst stocked: hat Base.Hat_Fedora at hat, locker locked true
ZEDQA rst bandages in the building: 3
ZEDQA rst bar zones: outfit,loadout,days:dec,days:inc,days,save,verb,ready
ZEDQA rst ok the bar draws under Equipped
ZEDQA rst ok ready 1 of 6 (the screwdriver on you, of 6 lines)
ZEDQA rst ok outfit worn 0 of 1
ZEDQA rst ghosts: head,main
ZEDQA rst ok a ghost in the main hand (the axe)
ZEDQA rst ok a ghost at head (the hat)
ZEDQA rst states: Fedora=take@Crate | Hatchet=take@Crate | Screwdriver=on@nil | Bandage=ask@Crate | Water=fill@Sink | Katana=none@nil | Crowbar=take@Crate
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
ZEDQA rst hardcore ran 3.2 s real for 3.2 s estimated (0.99 real s per estimated s)
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
ZEDQA rst walking line: Walking to 2 of 2 | 0:08 left
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
ZEDQA rst long haul: 12.5 of 18.0 carried, water 2.0 L a day
ZEDQA rst ok 5 days is over the limit (by 4.8)
ZEDQA rst ok the heaviest supply named: Water
ZEDQA rst ok the most days that fit: 2
ZEDQA rst ok Make it N days is offered
ZEDQA rst ok Make it 2 days fits
ZEDQA rst ok home: the building where you last restocked (875,12964)
ZEDQA rst loot: beans x2, odd Base.Harmonica (Instrument)
ZEDQA rst ok back home with things from a trip: Unpack is offered
ZEDQA rst ok loot goes where its kind lives: beans to Crate
ZEDQA rst ok a kind with no home asks for a place (pick)
ZEDQA rst ok leftover food that spoils within 2 days goes back (put)
ZEDQA rst ok leftover supplies stay packed (stay)
ZEDQA rst ok stays on you: T-shirt, Jeans, Socks - Heavy, Military Boots, Leather Gloves, Belt, Digital Watch, Prescription Aviator Glasses, Nails, Cigarette Pack, JS-2000 Shotgun, Flier: Fossoil (West Point): Fossoil (West Point), Water Bottle, Book: "The Omega Department Guide (Unofficial)", by Napoleon Trejo, Baseball Bat, Screwdriver, Fedora, Hatchet, Crowbar
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

### 40. zedqa_reader.lua (`ZEDQA rd`) - PASS, 10 s

- go 16189 at 22:50:44
- screenshots: zqa_rd_01_paper.png, zqa_rd_02_words.png, zqa_rd_03_story2.png, zqa_rd_04_zoomed.png, zqa_rd_05_flier.png, zqa_rd_06_map.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rd start
[ZeD.QA] run #40 ok=true
ZEDQA rd light after 3 ticks: tooDark false
ZEDQA rd open true view paper body 27.884615384615387
ZEDQA rd words blocks 12
ZEDQA rd flier places 1
ZEDQA rd map centre 10687,9831
ZEDQA rd DONE
```

### 41. zedqa_reader_refs.lua (`ZEDQA rr`) - PASS, 12 s

- go 16190 at 22:50:58
- screenshots: zqa_rr_01_journal_flyers.png, zqa_rr_02_news_card.png, zqa_rr_03_vanilla_news_paper.png, zqa_rr_04_vanilla_news_words.png, zqa_rr_05_vanilla_flier_paper.png, zqa_rr_06_vanilla_flier_words.png, zqa_rr_07_vanilla_journal.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rr start
[ZeD.QA] run #41 ok=true
ZEDQA rr items Base.Newspaper:zombie.inventory.types.Literature@601b0911 Base.Flier:zombie.inventory.types.Literature@1a4df486 Base.Notebook:zombie.inventory.types.Literature@34677ea0
ZEDQA rr DONE
```

### 42. zedqa_notebook.lua (`ZEDQA nb`) - PASS, 8 s

- go 16191 at 22:51:13
- screenshots: zqa_nb_01_page1.png, zqa_nb_02_erase_asks.png, zqa_nb_03_rail.png, zqa_nb_04_read_only.png, zqa_nb_05_locked_other.png

```text
[ZeD.QA] windows reset (R)
ZEDQA nb start
[ZeD.QA] run #42 ok=true
ZEDQA nb light after 3 ticks: tooDark false
ZEDQA nb open true mode notebook pages 10 readOnly false
ZEDQA nb after done: name Supply runs p1 day 3. truck still wont start. p2 water: 2 bottles + the pot. ne action false window false
ZEDQA nb read only true
ZEDQA nb other lock true readOnly true
ZEDQA nb DONE
```

### 43. zedqa_print_fit.lua (`ZEDQA pf`) - PASS, 13 s

- go 16192 at 22:51:24
- screenshots: zqa_pf_1a_KnoxKnews_July1_vanilla.png, zqa_pf_1b_KnoxKnews_July1_fitted.png, zqa_pf_2a_KnoxKnews_July2_vanilla.png, zqa_pf_2b_KnoxKnews_July2_fitted.png, zqa_pf_3a_KentuckyHerald_July6_vanilla.png, zqa_pf_3b_KentuckyHerald_July6_fitted.png, zqa_pf_4a_NationalDispatch_July6_vanilla.png, zqa_pf_4b_NationalDispatch_July6_fitted.png

```text
[ZeD.QA] windows reset (R)
ZEDQA pf start
[ZeD.QA] run #43 ok=true
ZEDQA pf KnoxKnews_July1 element_23 y 470->376 room 509 scale 0.40->0.64 h 247
ZEDQA pf KnoxKnews_July1 element_25 y 700->686 room 184 scale 0.40->0.64 h 106 head 0.80->1.09
ZEDQA pf KnoxKnews_July2 element_23 y 470->376 room 509 scale 0.40->0.64 h 221
ZEDQA pf KnoxKnews_July2 element_25 y 700->686 room 184 scale 0.40->0.64 h 106 head 0.80->1.09
ZEDQA pf KnoxKnews_July2 element_27 y 700->686 room 184 scale 0.40->0.64 h 106 head 0.80->1.09
ZEDQA pf KentuckyHerald_July6 element_15 y 395->396 room 330 scale 0.45->0.64 h 157
ZEDQA pf KentuckyHerald_July6 element_18 y 415->416 room 310 scale 0.45->0.64 h 144
ZEDQA pf NationalDispatch_July6 element_16 y 339->322 room 453 scale 0.40->0.64 h 259
ZEDQA pf NationalDispatch_July6 element_21 y 240->227 room 573 scale 0.40->0.64 h 323
ZEDQA pf DONE
```

### 44. zedqa_print_typeset.lua (`ZEDQA ts`) - PASS, 7 s

- go 16193 at 22:51:41
- screenshots: zqa_ts_1_KnoxKnews_July1.png, zqa_ts_2_KnoxKnews_July2.png, zqa_ts_3_KentuckyHerald_July6.png, zqa_ts_4_NationalDispatch_July6.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ts start
[ZeD.QA] run #44 ok=true
ZEDQA ts KnoxKnews_July1 stories 3 body 27.884615384615387 lines 58
ZEDQA ts KnoxKnews_July2 stories 3 body 26.884615384615387 lines 53
ZEDQA ts KentuckyHerald_July6 stories 2 body 30.153615384615385 lines 43
ZEDQA ts NationalDispatch_July6 stories 5 body 23.076923076923077 lines 77
ZEDQA ts DONE
```

### 45. zedqa_prompts.lua (`ZEDQA pr`) - PASS, 30 s

- go 16194 at 22:51:51
- screenshots: zqa_pr_01_sleep.png, zqa_pr_02_kill.png, zqa_pr_03_note.png, zqa_pr_04_rename.png, zqa_pr_05_rename_empty.png, zqa_pr_06_keyboard.png, zqa_pr_07_alarm.png, zqa_pr_08_timer.png, zqa_pr_09_help.png, zqa_pr_10_rich_question.png, zqa_pr_11_gp_question.png, zqa_pr_12_gp_question_no.png, zqa_pr_13_gp_kill.png, zqa_pr_14_gp_text.png, zqa_pr_15_gp_keyboard.png, zqa_pr_16_gp_alarm.png

```text
[ZeD.QA] windows reset (R)
ZEDQA pr start
[ZeD.QA] run #45 ok=true
ZEDQA pr sleep Type=ZeD_Prompt kind=question x=1659 y=948 w=526 h=265 visible=false top=false
ZEDQA pr mouse 1922,1081
ZEDQA pr answer sleep internal=NO parentKind=question entry=nil
ZEDQA pr kill Type=ZeD_Prompt kind=question x=1659 y=948 w=526 h=265 visible=false top=false
ZEDQA pr kill costly=true
ZEDQA pr kill after No Type=ZeD_Prompt kind=question x=1659 y=948 w=526 h=265 visible=false top=false
ZEDQA pr note Type=ZeD_Prompt kind=note x=1578 y=947 w=683 h=265 visible=false top=false
ZEDQA pr answer note internal=OK parentKind=note entry=nil
ZEDQA pr after Escape: note visible=false pause=false
ZEDQA pr rename: no bag, plain box
ZEDQA pr rename Type=ZeD_Prompt kind=text x=1624 y=933 w=595 h=295 visible=false top=false
ZEDQA pr empty: yes.enable=false why=Can't be empty.
ZEDQA pr long: yes.enable=false why=Character limit: 12
ZEDQA pr keyboard Type=ISOnScreenKeyboard zed=true IsVisible=false
ZEDQA pr keyboard Type=ISOnScreenKeyboard kind=nil x=1428 y=1241 w=985 h=410 visible=false top=false
ZEDQA pr rename under keyboard Type=ZeD_Prompt kind=text x=1624 y=932 w=595 h=295 visible=true top=true
ZEDQA pr typed: Go Bags! current=Go Bags!
ZEDQA pr after keyboard cancel: Go Bag kbVisible=false
ZEDQA pr answer rename internal=OK parentKind=text entry=Go Bag
ZEDQA pr alarm Type=ZeD_Prompt kind=alarm x=1657 y=862 w=525 h=435 visible=false top=false
ZEDQA pr alarm after pad: 7:20 on=false focus=tick
ZEDQA pr alarm synced 7:20 on=false
ZEDQA pr timer Type=ZeD_Prompt kind=timer x=1657 y=920 w=525 h=319 visible=false top=false
ZEDQA pr timer answer OK time=35
ZEDQA pr help Type=ZeD_Prompt kind=rich x=1435 y=739 w=770 h=681 visible=false top=false
ZEDQA pr help blocks=5 contentH=486.67578125 maxScroll=0
ZEDQA pr help after OK visible=false
ZEDQA pr forget Type=ZeD_Prompt kind=rich x=1582 y=948 w=679 h=265 visible=false top=false
ZEDQA pr forget costly=false
ZEDQA pr answer forget internal=NO parentKind=rich entry=nil
ZEDQA pr subclass build ok=true kind=nil Type=ISConfirmMonitorSettings
ZEDQA pr open prompts left=0
ZEDQA pr gp focus=yes
ZEDQA pr gp after left focus=no
ZEDQA pr answer gp sleep internal=NO parentKind=question entry=nil
ZEDQA pr gp text focus=field
ZEDQA pr answer gp rename internal=CANCEL parentKind=text entry=Duffel Bag
ZEDQA pr gp open prompts left=0
ZEDQA pr DONE
```

### 46. zedqa_fishing.lua (`ZEDQA fi`) - PASS, 9 s

- go 16195 at 22:52:25
- screenshots: zqa_fi_1_slack.png, zqa_fi_2_light.png, zqa_fi_3_tight.png, zqa_fi_4_strain.png, zqa_fi_5_limit.png

```text
[ZeD.QA] windows reset (R)
ZEDQA fi start
[ZeD.QA] run #46 ok=true
ZEDQA fi 1_slack tension -0.6 vanilla angle -62
ZEDQA fi 2_light tension 0.15 vanilla angle -32
ZEDQA fi 3_tight tension 0.4 vanilla angle -2
ZEDQA fi 4_strain tension 0.72 vanilla angle 36.39999999999999
ZEDQA fi 5_limit tension 0.96 vanilla angle 65.19999999999999
ZEDQA fi DONE
```

### 47. zedqa_props_plates.lua (`ZEDQA props`) - PASS, 3 s

- go 16196 at 22:52:37
- screenshots: zqa_props_1.png, zqa_props_2.png, zqa_props_3.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #47 ok=true
ZEDQA props draw rod true/true slack true clock true/true
ZEDQA props DONE
```

### 48. zedqa_belt_strap.lua (`ZEDQA belt`) - PASS, 2 s

- go 16197 at 22:52:44
- screenshots: zqa_belt_strap_1.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #48 ok=true
ZEDQA belt textures true
ZEDQA belt shot; DONE
```

### 49. zedqa_straps.lua (`ZEDQA straps`) - PASS, 12 s

- go 16198 at 22:52:49
- screenshots: zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #49 ok=true
ZEDQA straps put aside 1
ZEDQA straps civilian worn HolsterSimple_Brown,Belt2,Tshirt_DefaultTEXTURE_TINT,Gloves_LeatherGlovesBlack,Socks_Heavy,Shoes_ArmyBoots,Trousers_Denim
ZEDQA straps civilian slots Back=sling SmallBeltLeft=leather SmallBeltRight=leather HolsterRight=holster_brown | waist=leather closure=buckle
ZEDQA straps civilian shot
ZEDQA straps military worn Holster_DuctTape,Tshirt_DefaultTEXTURE_TINT,Gloves_LeatherGlovesBlack,Socks_Heavy,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICE_BeltSus_Camo,Bag_ALICEpack_Army
ZEDQA straps military slots Back=webbing_olive SmallBeltLeft=webbing_camo SmallBeltRight=webbing_camo HolsterRight=holster_tape WebbingRight=webbing_camo WebbingLeft=webbing_camo BedrollBottomALICE=webbing_olive | waist=webbing_camo closure=clip_black
ZEDQA straps military shot
ZEDQA straps makeshift worn Holster_Hide,RopeBelt,Tshirt_DefaultTEXTURE_TINT,Gloves_LeatherGlovesBlack,Socks_Heavy,Shoes_ArmyBoots,Trousers_Denim,Bag_CraftedFramepack_Large
ZEDQA straps makeshift slots Back=rope SmallBeltLeft=rope HolsterRight=holster_hide BedrollBottom=rope | waist=rope closure=knot
ZEDQA straps makeshift shot
ZEDQA straps firefighter worn Tshirt_DefaultTEXTURE_TINT,Gloves_LeatherGlovesBlack,Socks_Heavy,Shoes_ArmyBoots,Trousers_Denim,SCBA
ZEDQA straps firefighter slots Back=harness SmallBeltLeft=harness SmallBeltRight=harness WebbingLeft=harness | waist=harness closure=clip_black
ZEDQA straps firefighter shot
ZEDQA straps olive worn Tshirt_DefaultTEXTURE_TINT,Gloves_LeatherGlovesBlack,Socks_Heavy,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICE_BeltSus
ZEDQA straps olive slots Back=sling SmallBeltLeft=webbing_olive SmallBeltRight=webbing_olive WebbingLeft=webbing_olive WebbingRight=webbing_olive | waist=webbing_olive closure=clip_brass
ZEDQA straps olive shot
ZEDQA straps restored; DONE
```

### 50. zedqa_buckle.lua (`ZEDQA bk`) - PASS, 6 s

- go 16199 at 22:53:04
- screenshots: zqa_bk_1.png, zqa_bk_2.png, zqa_bk_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA bk start
[ZeD.QA] run #50 ok=true
ZEDQA bk centre 1920 vs screen 1920 | belt x 1535 w 747 | delta 0 | bare watch none
ZEDQA bk worn base:leftwrist
ZEDQA bk centre 1920 vs screen 1920 | belt x 1433 w 849 | delta 0 | cazio watch digital_black wrist left
ZEDQA bk worn base:rightwrist
ZEDQA bk centre 1920 vs screen 1920 | belt x 1433 w 849 | delta 0 | timez watch timez_easy wrist right
ZEDQA bk DONE
```

### 51. zedqa_buckles.lua (`ZEDQA bks`) - PASS, 38 s

- go 16200 at 22:53:14
- screenshots: zqa_bk_01_burgerflipper.png, zqa_bk_02_repairman.png, zqa_bk_03_burglar.png, zqa_bk_04_engineer.png, zqa_bk_05_fisherman.png, zqa_bk_06_policeofficer.png, zqa_bk_07_lumberjack.png, zqa_bk_08_smither.png, zqa_bk_09_farmer.png, zqa_bk_10_electrician.png, zqa_bk_11_fireofficer.png, zqa_bk_12_metalworker.png, zqa_bk_13_fitnessinstructor.png, zqa_bk_14_veteran.png, zqa_bk_15_tailor.png, zqa_bk_16_chef.png, zqa_bk_17_doctor.png, zqa_bk_18_parkranger.png, zqa_bk_19_unemployed.png, zqa_bk_20_nurse.png, zqa_bk_21_securityguard.png, zqa_bk_22_carpenter.png, zqa_bk_23_mechanics.png, zqa_bk_24_rancher.png, zqa_bk_25_constructionworker.png

```text
[ZeD.QA] windows reset (R)
ZEDQA bks professions 25
ZEDQA bks start
[ZeD.QA] run #51 ok=true
ZEDQA bks 01 burgerflipper buckle=1862,2043,116,80
ZEDQA bks 02 repairman buckle=1862,2043,116,80
ZEDQA bks 03 burglar buckle=1862,2043,116,80
ZEDQA bks 04 engineer buckle=1862,2043,116,80
ZEDQA bks 05 fisherman buckle=1862,2043,116,80
ZEDQA bks 06 policeofficer buckle=1862,2043,116,80
ZEDQA bks 07 lumberjack buckle=1862,2043,116,80
ZEDQA bks 08 smither buckle=1862,2043,116,80
ZEDQA bks 09 farmer buckle=1862,2043,116,80
ZEDQA bks 10 electrician buckle=1862,2043,116,80
ZEDQA bks 11 fireofficer buckle=1862,2043,116,80
ZEDQA bks 12 metalworker buckle=1862,2043,116,80
ZEDQA bks 13 fitnessinstructor buckle=1862,2043,116,80
ZEDQA bks 14 veteran buckle=1862,2043,116,80
ZEDQA bks 15 tailor buckle=1862,2043,116,80
ZEDQA bks 16 chef buckle=1862,2043,116,80
ZEDQA bks 17 doctor buckle=1862,2043,116,80
ZEDQA bks 18 parkranger buckle=1862,2043,116,80
ZEDQA bks 19 unemployed buckle=1862,2043,116,80
ZEDQA bks 20 nurse buckle=1862,2043,116,80
ZEDQA bks 21 securityguard buckle=1862,2043,116,80
ZEDQA bks 22 carpenter buckle=1862,2043,116,80
ZEDQA bks 23 mechanics buckle=1862,2043,116,80
ZEDQA bks 24 rancher buckle=1862,2043,116,80
ZEDQA bks 25 constructionworker buckle=1862,2043,116,80
ZEDQA bks DONE (profession back to mechanics)
```

### 52. zedqa_beltwatch.lua (`ZEDQA bw`) - PASS, 12 s

- go 16201 at 22:53:55
- screenshots: zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png

```text
[ZeD.QA] windows reset (R)
ZEDQA bw start
[ZeD.QA] run #52 ok=true
ZEDQA bw worn base:leftwrist
ZEDQA bw box digital_black wrist left x 0 w 88 | hands s@102 p@190 | belt w 849
ZEDQA bw full watch tucked: 0x0
ZEDQA bw popped true at 1433,1671 248x352 | mini at 1433,2037
ZEDQA bw dragged to 1500,500 saved 857.1428571428571,285.7142857142857
ZEDQA bw after idle: popped true size 248
ZEDQA bw right wrist: timez_easy wrist right x 200 | hands s@0 p@88
ZEDQA bw corner: box false full watch 3524,10 300x352
ZEDQA bw DONE
```

### 53. zedqa_hands_together.lua (`ZEDQA ht`) - PASS, 18 s

- go 16202 at 22:54:10
- screenshots: zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ht start
[ZeD.QA] run #53 ok=true
ZEDQA ht 01 two items | OFF@0/77 MAIN@88/98 #1@225/77 #2@468/77 #3@564/77 lamp@680/67 | dark small | belt x1535 y2034 w747 h98
ZEDQA ht PASS 01 two items: both hands are on the belt
ZEDQA ht PASS 01 two items: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 01 two items: the off hand comes before the main hand
ZEDQA ht PASS 01 two items: the hands sit before the slots (the left end)
ZEDQA ht PASS 01 two items: the boxes run left to right
ZEDQA ht PASS 01 two items: the Messages note is last
ZEDQA ht PASS 01 two items: the hands are 6 units apart (11 px)
ZEDQA ht PASS 01 two items: a click at the off hand's right edge finds the off hand
ZEDQA ht 02 both hands | off(peek)@0/77 MAIN@25/98 #1@162/77 #2@405/77 #3@501/77 lamp@617/67 | dark small | belt x1598 y2034 w684 h98
ZEDQA ht PASS 02 both hands: both hands are on the belt
ZEDQA ht PASS 02 both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 02 both hands: the off hand comes before the main hand
ZEDQA ht PASS 02 both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 02 both hands: the boxes run left to right
ZEDQA ht PASS 02 both hands: the Messages note is last
ZEDQA ht PASS 02 both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 02 both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 02 both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 02 both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 02 both hands: slot 1 stays in place on screen (1760, was 1760)
ZEDQA ht 03 both, high contrast | off(peek)@0/77 MAIN@25/98 #1@162/77 #2@405/77 #3@501/77 lamp@617/67 | hicon small | belt x1598 y2034 w684 h98
ZEDQA ht PASS 03 both, high contrast: both hands are on the belt
ZEDQA ht PASS 03 both, high contrast: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 03 both, high contrast: the off hand comes before the main hand
ZEDQA ht PASS 03 both, high contrast: the hands sit before the slots (the left end)
ZEDQA ht PASS 03 both, high contrast: the boxes run left to right
ZEDQA ht PASS 03 both, high contrast: the Messages note is last
ZEDQA ht PASS 03 both, high contrast: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 03 both, high contrast: the crescent's mark is 44 px wide
ZEDQA ht PASS 03 both, high contrast: a click at the crescent finds the off hand
ZEDQA ht PASS 03 both, high contrast: a click where the two overlap finds the main hand
ZEDQA ht 04 both, large | off(peek)@0/89 MAIN@28/113 #1@185/89 #2@446/89 #3@557/89 lamp@690/76 | dark large | belt x1560 y2015 w766 h113
ZEDQA ht PASS 04 both, large: both hands are on the belt
ZEDQA ht PASS 04 both, large: the main hand is 56 units, the off hand 44 (113, 89 px; 56u = 113)
ZEDQA ht PASS 04 both, large: the off hand comes before the main hand
ZEDQA ht PASS 04 both, large: the hands sit before the slots (the left end)
ZEDQA ht PASS 04 both, large: the boxes run left to right
ZEDQA ht PASS 04 both, large: the Messages note is last
ZEDQA ht PASS 04 both, large: the off hand peeks 14 units from under the main hand (28 px)
ZEDQA ht PASS 04 both, large: the crescent's mark is 50 px wide
ZEDQA ht PASS 04 both, large: a click at the crescent finds the off hand
ZEDQA ht PASS 04 both, large: a click where the two overlap finds the main hand
ZEDQA ht pad two items | OFF@0/77 MAIN@88/98 #1@225/77 #2@468/77 #3@564/77 lamp@680/67 | dark small | belt x1535 y2034 w747 h98
ZEDQA ht PASS pad two items: both hands are on the belt
ZEDQA ht PASS pad two items: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS pad two items: the off hand comes before the main hand
ZEDQA ht PASS pad two items: the hands sit before the slots (the left end)
ZEDQA ht PASS pad two items: the boxes run left to right
ZEDQA ht PASS pad two items: the Messages note is last
ZEDQA ht PASS pad two items: the hands are 6 units apart (11 px)
ZEDQA ht PASS pad two items: a click at the off hand's right edge finds the off hand
ZEDQA ht PASS pad: the belt starts on slot 1 (#1)
ZEDQA ht PASS pad: Left from slot 1 is the main hand (MAIN)
ZEDQA ht PASS pad: Left again is the off hand (OFF)
ZEDQA ht 05 left wrist, both hands | watch@0/88 off(peek)@102/77 MAIN@127/98 #1@264/77 #2@507/77 #3@603/77 lamp@719/67 | dark small | belt x1496 y2034 w786 h98
ZEDQA ht PASS 05 left wrist, both hands: both hands are on the belt
ZEDQA ht PASS 05 left wrist, both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 05 left wrist, both hands: the off hand comes before the main hand
ZEDQA ht PASS 05 left wrist, both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 05 left wrist, both hands: the boxes run left to right
ZEDQA ht PASS 05 left wrist, both hands: the Messages note is last
ZEDQA ht PASS 05 left wrist, both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 05 left wrist, both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 05 left wrist, both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 05 left wrist, both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 05 left wrist, both hands: slot 1 stays in place on screen (1760, was 1760)
ZEDQA ht PASS 05: the left-wrist watch sits beside the peeking off hand
ZEDQA ht 06 right wrist, pistol | OFF@0/77 MAIN@88/98 ammo@137/255 watch@406/88 #1@533/77 #2@776/77 #3@872/77 lamp@988/67 | dark small | belt x1227 y2034 w1055 h98
ZEDQA ht PASS 06 right wrist, pistol: both hands are on the belt
ZEDQA ht PASS 06 right wrist, pistol: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 06 right wrist, pistol: the off hand comes before the main hand
ZEDQA ht PASS 06 right wrist, pistol: the hands sit before the slots (the left end)
ZEDQA ht PASS 06 right wrist, pistol: the boxes run left to right
ZEDQA ht PASS 06 right wrist, pistol: the Messages note is last
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
ZEDQA ht 08 empty pistol | OFF@0/77 MAIN@88/98 ammo@137/255 #1@431/77 #2@674/77 #3@770/77 lamp@886/67 | dark small | belt x1329 y2034 w953 h98
ZEDQA ht PASS 08 empty pistol: both hands are on the belt
ZEDQA ht PASS 08 empty pistol: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 08 empty pistol: the off hand comes before the main hand
ZEDQA ht PASS 08 empty pistol: the hands sit before the slots (the left end)
ZEDQA ht PASS 08 empty pistol: the boxes run left to right
ZEDQA ht PASS 08 empty pistol: the Messages note is last
ZEDQA ht PASS 08 empty pistol: the hands are 6 units apart (11 px)
ZEDQA ht PASS 08 empty pistol: a click at the off hand's right edge finds the off hand
ZEDQA ht PASS 08: the ammo tab comes after the main hand
ZEDQA ht PASS 08: the tab starts under the main hand's middle, its words at the circle's edge (x137 cx186)
ZEDQA ht PASS 08: no strap under the ammo tab
ZEDQA ht PASS 08: a click on the circle over the tab finds the main hand
ZEDQA ht PASS 08: a click on the tab's words finds the tab
ZEDQA ht 09 shotgun, both hands | off(peek)@0/77 MAIN@25/98 ammo@74/255 #1@368/77 #2@611/77 #3@707/77 lamp@823/67 | dark small | belt x1392 y2034 w890 h98
ZEDQA ht PASS 09 shotgun, both hands: both hands are on the belt
ZEDQA ht PASS 09 shotgun, both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 09 shotgun, both hands: the off hand comes before the main hand
ZEDQA ht PASS 09 shotgun, both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 09 shotgun, both hands: the boxes run left to right
ZEDQA ht PASS 09 shotgun, both hands: the Messages note is last
ZEDQA ht PASS 09 shotgun, both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 09 shotgun, both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 09 shotgun, both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 09 shotgun, both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 09 shotgun, both hands: slot 1 stays in place on screen (1760, was 1760)
ZEDQA ht PASS 09: the ammo tab comes after the main hand
ZEDQA ht PASS 09: the tab starts under the main hand's middle, its words at the circle's edge (x74 cx123)
ZEDQA ht PASS 09: no strap under the ammo tab
ZEDQA ht PASS 09: a click on the circle over the tab finds the main hand
ZEDQA ht PASS 09: a click on the tab's words finds the tab
ZEDQA ht 07 off hand x1598 y2044 s77 peekW 44
ZEDQA ht all checks passed
ZEDQA ht DONE
```

### 54. zedqa_watches2.lua (`ZEDQA watches`) - PASS, 29 s

- go 16203 at 22:54:32
- screenshots: zqa_watch_day_DigitalBlack.png, zqa_watch_day_DigitalDress.png, zqa_watch_day_DigitalRed.png, zqa_watch_day_DigitalTimez.png, zqa_watch_day_ClassicBlack.png, zqa_watch_day_ClassicGold.png, zqa_watch_day_ClassicBrown.png, zqa_watch_day_ClassicMilitary.png, zqa_watch_day_Expensive.png, zqa_watch_set_DigitalBlack.png, zqa_watch_night_DigitalBlack.png, zqa_watch_night_DigitalTimez.png, zqa_watch_lit_DigitalTimez.png, zqa_watch_night_ClassicBrown.png, zqa_watch_lit_ClassicBrown.png, zqa_watch_night_Expensive.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #54 ok=true
ZEDQA watches own watch nil at nil
ZEDQA watches no own watch; location base:leftwrist
ZEDQA watches item left true right true
ZEDQA watches name 'Digital Watch - Steel Sport Style' icon C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\textures\Item_ZeDWatchTimezSteel.png world Base.ZeDDigitalWatchSteel clothing true/WristWatch_Left_DigitalTimez digital true class true
ZEDQA watches DigitalBlack plate digital_black size 248x352 at 3576,10 hits alarm,light,set,speed,start
ZEDQA watches DigitalDress plate digital_gold size 248x352 at 3576,10 hits alarm,light,set,speed,start
ZEDQA watches DigitalRed plate timez_red size 248x352 at 3576,10 hits alarm,light,set,speed,start
ZEDQA watches DigitalTimez plate timez_steel size 248x352 at 3576,10 hits alarm,light,set,speed,start
ZEDQA watches ClassicBlack plate classic_black size 300x352 at 3524,10 hits alarm,crown,light,set,speed,start
ZEDQA watches ClassicGold plate classic_gold size 300x352 at 3524,10 hits alarm,crown,light,set,speed,start
ZEDQA watches ClassicBrown plate timez_easy size 300x352 at 3524,10 hits crown,light,speed,start
ZEDQA watches ClassicMilitary plate timez_camper size 300x352 at 3524,10 hits crown,light,speed,start
ZEDQA watches Expensive plate expensive size 300x352 at 3524,10 hits crown,speed,start
ZEDQA watches setting open true hits alarm,light,set,setdn,setup,speed,start
ZEDQA watches after + + armed true hour 1
ZEDQA watches night dark=true
ZEDQA watches DigitalTimez lit=true
ZEDQA watches ClassicBrown lit=true
ZEDQA watches light out: lit=false dark=true
ZEDQA watches restored own watch nil; DONE
```

### 55. zedqa_container_bottom.lua (`ZEDQA cb`) - PASS, 10 s

- go 16204 at 22:55:05
- screenshots: zqa_cb_01_rows_at_bottom.png, zqa_cb_02_list_end.png, zqa_cb_03_pad_take_all.png, zqa_cb_04_campfire_ribbon.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cb start
[ZeD.QA] run #55 ok=true
ZEDQA cb bed selected true
ZEDQA cb world list 651x650, row 64 at y 586
ZEDQA cb campfire selected true
ZEDQA cb DONE
```

### 56. zedqa_container_controls.lua (`ZEDQA ct`) - PASS, 17 s

- go 16205 at 22:55:18
- screenshots: zqa_ct_01_rows.png, zqa_ct_02_pad_same_type.png, zqa_ct_03_after_take_all.png, zqa_ct_04_floor_row.png, zqa_ct_05_campfire_row.png, zqa_ct_06_add_fuel_card.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ct start
[ZeD.QA] run #56 ok=true
ZEDQA ct pickup true
ZEDQA ct bed selected true
ZEDQA ct your row: Transfer all, Same type, Same type, all nearby
ZEDQA ct world row: Take all, Same type, To floor
ZEDQA ct start: bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 23
ZEDQA ct focused worldCtl:same prompt Take the kinds you already carry
ZEDQA ct marked rows (things) 7
ZEDQA ct no button Same type
ZEDQA ct after Same type (take): bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 23
ZEDQA ct no button Same type
ZEDQA ct after Same type (back): bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 23
ZEDQA ct no button Take all
ZEDQA ct after Take all: bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 23
ZEDQA ct no button Transfer all
ZEDQA ct after Transfer all: bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 23
ZEDQA ct no button To floor
ZEDQA ct after To floor: bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 23
ZEDQA ct floor selected true
ZEDQA ct floor row: Take all, Same type(off)
ZEDQA ct no button Take all
ZEDQA ct after Take all (floor): bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 23
ZEDQA ct no button Transfer all
ZEDQA ct after Transfer all (back to the bed): bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 23
ZEDQA ct campfire placed true true
ZEDQA ct campfire container true selected true
ZEDQA ct campfire row: Take all, Same type(off), To floor, |, Take apart, Light, Add fuel
ZEDQA ct no button Add fuel
ZEDQA ct after Add fuel: object card false jump nil
ZEDQA ct no button Take apart
ZEDQA ct after Take apart: campfire still there true
ZEDQA ct restored: bag nails 6 planks 0 | bed nails 0 planks 0 beans 0, 2 things | floor -1
ZEDQA ct DONE
```

### 57. zedqa_container_controls_captures.lua (`ZEDQA cc`) - PASS, 6 s

- go 16206 at 22:55:39
- screenshots: zqa_cc_zed_truckbed.png, zqa_cc_vanilla_truckbed.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cc start
[ZeD.QA] run #57 ok=true
ZEDQA cc pickup true bed part TruckBedOpen
ZEDQA cc truck bed true dist 1.1
ZEDQA cc world window on the truck bed (1)
ZEDQA cc char 1134,0 777x735 world 1929,0 777x735
ZEDQA cc vanilla inv 640,0 1280x720 loot 1920,0 1280x720
ZEDQA cc DONE
```

### 58. zedqa_px_icons.lua (`ZEDQA px`) - WARN, 5 s

- go 16207 at 22:55:48
- 1 ERR line(s)
- screenshots: zqa_px_panel.png, zqa_px_card.png, zqa_px_rows.png

```text
[ZeD.QA] windows reset (R)
ZEDQA px scale 1.75: the 16-unit icon box is 28 px, the drawing for it 24
ZEDQA px ok 29 icons, four drawings each, the box picks 24
ZEDQA px ok a licensed name is no pixel icon (the row falls back to words, not a picture)
ZEDQA px ok the wheels use the same lookup
[ZeD.QA] run #58 ok=true
ZEDQA px shot zqa_px_panel
ZEDQA px ok the test panel drew
ZEDQA px ERR the card opened on Digital Watch
ZEDQA px shot zqa_px_card
ZEDQA px card toggle rects nil
ZEDQA px shot zqa_px_rows
ZEDQA px ok Fav put back
ZEDQA px DONE 1 failed
```

### 59. zedqa_button_case_game.lua (`ZEDQA bg`) - PASS, 16 s

- go 16208 at 22:55:57
- screenshots: zqa_bg_01_item_card.png, zqa_bg_02_health.png, zqa_bg_03_thermal.png, zqa_bg_04_animals.png, zqa_bg_05_forage.png, zqa_bg_06_craft.png, zqa_bg_07_vehicle.png

```text
[ZeD.QA] windows reset (R)
ZEDQA bg start
[ZeD.QA] run #59 ok=true
ZEDQA bg pickup true shirt true
ZEDQA bg card open true
ZEDQA bg DONE
```

### 60. zedqa_wheel_sizes.lua (`ZEDQA ws`) - PASS, 15 s

- go 16209 at 22:56:16
- screenshots: zqa_ws_a_gun3.png, zqa_ws_b_dright3.png, zqa_ws_c_emotes5.png, zqa_ws_d_signal9.png, zqa_ws_e_back10.png, zqa_ws_g_car11.png, zqa_ws_h_car11pt.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #60 ok=true
ZEDQA ws a_gun3 n=3 r=49 w=600
ZEDQA ws b_dright3 n=8 r=74 w=650
ZEDQA ws c_emotes5 n=5 r=49 w=600
ZEDQA ws d_signal9 n=9 r=83 w=668
ZEDQA ws e_back10 n=12 r=110 w=722
ZEDQA ws g_car11 n=11 r=101 w=704
ZEDQA ws h_car11pt n=11 r=101 w=704
ZEDQA ws done
```

### 61. zedqa_wheel_icons.lua (`ZEDQA wi`) - WARN, 62 s

- go 16210 at 22:56:35
- 2 ERR line(s)
- screenshots: zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wi start car=BaseVehicle{ Name:null, ID:16 }
[ZeD.QA] run #61 ok=true
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
ZEDQA wi FAIL 141 slices on ZeD's five wheels, 124 with a wheel icon, the rest items, glyphs or colours: left > Loadouts: view_list is no icon
ZEDQA wi PASS the ZeD wheel's pickers give their choices the setting's icon
ZEDQA wi PASS the map's slices on ZeD's wheels: 79 with their icon
ZEDQA wi NOTE not on the wheels now (the state decides): the wounds (no wound now); character > Watch / UI_ZeD_Wheel_OpenWatch; character > Watch / UI_ZeD_Wheel_WatchLight; character > Watch / UI_ZeD_Wheel_WatchAlarm; character > Radio / UI_ZeD_Wheel_NextStation; world > Search / UI_disable_search_mode; world > Vehicle / IGUI_VehiclePartCatdashboard
ZEDQA wi PASS Crouch and Auto-walk show what the slice does now: sneak, autowalk
ZEDQA wi dpad_left: 9 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack 9:Loadouts/No loadouts saved=view_list
ZEDQA wi PASS dpad_left: 9 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_right: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_up: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Lighter/Turn on=bulb_on
ZEDQA wi PASS dpad_down: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_select: 12 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/1 new=inbox 10:Reset windows/Both windows back to where they start=rotate 11:ZeD setup/Options, on ZeD's page=gears 12:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select: 11 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_left_use: 5 slices | 1:Smoke=cigarette 2:Read=book 3:Watch/No watch on your wrist.=watch 4:Radio/No radio in your hands or on your back.=walkie
ZEDQA wi PASS dpad_left_use: 4 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down_speed: 5 slices | 1:Pause/In use=pause 2:FF x 1=ff1 3:FF x 2=ff2 4:FF x 3=wait
ZEDQA wi PASS dpad_down_speed: 4 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down_view: 5 slices | 1:Hide the interface/Until you take this again=eye_off 2:Reset windows/Both windows back to where they start=rotate 3:Text size=textsize 4:OPTIONS/Options, on ZeD's page=gears
ZEDQA wi PASS dpad_down_view: 4 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_select_theme: 4 slices | 1:Dark/In use=theme 2:Light=theme 3:High contrast=theme
ZEDQA wi PASS dpad_select_theme: 4 wheel icons drawn pixel for pixel at the box's size
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
ZEDQA wi PASS gun: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi light: 4 slices | 1:Lighter/Equip Primary=keep?item_lighter 2:Lighter/Equip Secondary=keep?item_lighter 3:Flashlight/Unequip=minus 4:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi stick: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi vanilla_back: 10 slices | 1:Player Info=heart 2:Crafting=craft 3:Building=bricks 4:Zoom 75%=zoom_in 5:Pause=pause 6:FF x 1=ff1 7:Zoom 125%=zoom_out 8:Move furniture=chair 9:Enable Search Mode=eye 10:Investigate This Area=magnifier
ZEDQA wi PASS vanilla_back: 11 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi vanilla_dright: 3 slices | 1:Show/Hide World Map=map 2:Designated Zones=fence 3:Toggle Survival Guide=guide
ZEDQA wi PASS vanilla_dright: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi car_outside: 0 slices |
ZEDQA wi NOTE car_outside: the wheel is empty here
ZEDQA wi PASS in the car: the dashboard slice has the gauge (gauge)
ZEDQA wi car_inside: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Unlock all doors=padlock_open 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside: 12 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi FAIL vanilla's radials and ZeD's wheels, live: 121 slices, 119 wheel icons, 2 kept pictures, left over: dpad_left 9: id:view_list is no icon
ZEDQA wi now at 1x (text size small): icon box 16 at rest, 24 pointed
ZEDQA wi dpad_left_1x: 9 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack 9:Loadouts/No loadouts saved=view_list
ZEDQA wi PASS dpad_left_1x: 9 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_right_1x: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right_1x: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_up_1x: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up_1x: 9 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down_1x: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Flashlight/Turn on=bulb_on
ZEDQA wi PASS dpad_down_1x: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_select_1x: 12 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/1 new=inbox 10:Reset windows/Both windows back to where they start=rotate 11:ZeD setup/Options, on ZeD's page=gears 12:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select_1x: 11 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_1x: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes_1x: 5 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi gun_1x: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun_1x: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi light_1x: 4 slices | 1:Lighter/Equip Primary=keep?item_lighter 2:Lighter/Equip Secondary=keep?item_lighter 3:Flashlight/Unequip=minus 4:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light_1x: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi stick_1x: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick_1x: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi car_inside_1x: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Unlock all doors=padlock_open 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside_1x: 12 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi scale back to option 7: icon box 28
ZEDQA wi 2 failed, 3 notes
ZEDQA wi DONE
```

### 62. zedqa_wheels.lua (`ZEDQA wh`) - PASS, 28 s

- go 16211 at 22:57:40
- screenshots: zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wh start car=BaseVehicle{ Name:null, ID:16 } pistol=nil torch=nil
[ZeD.QA] run #62 ok=true
ZEDQA wh outside zed=true java=UIElement n=0 x=1716 y=876 w=408 vis=false point=-1 title=nil |
ZEDQA wh inside zed=true java=UIElement n=11 x=1568 y=728 w=704 vis=false point=-1 title=nil | 1:Switch Seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.[off] 3:Turn Headlights on 4:Turn AC/Heater on 5:Horn 6:Device Options 7:Open Window 8:Unlock all doors 9:Vehicle Mechanics 10:Not tired enough to sleep.[off] 11:Exit Vehicle
ZEDQA wh pick test slice3 from mouse -> 3
ZEDQA wh emotes zed=true java=UIElement n=5 x=1620 y=780 w=600 vis=false point=-1 title=nil | 1:Friendly 2:Hostile 3:Group 4:Signal 5:Shout
ZEDQA wh press towards 4 (Signal)
ZEDQA wh signal zed=true java=UIElement n=9 x=1586 y=746 w=668 vis=true point=-1 title=Signal | 1:Cease Fire 2:Ok 3:Move Out 4:Freeze 5:Follow Behind 6:Fire 7:Come 8:Salute 9:Back
ZEDQA wh gun zed=true java=UIElement n=0 x=1586 y=746 w=668 vis=false point=-1 title=nil |
ZEDQA wh light zed=true java=UIElement n=2 x=1620 y=780 w=600 vis=false point=-1 title=nil | 1:Lighter/Equip Primary 2:Lighter/Equip Secondary
ZEDQA wh back zed=true java=UIElement n=12 x=1559 y=719 w=722 vis=false point=-1 title=nil | 1:Base theme/Dark 2:Accent color/PZ Teal 3:Text size/Small 4:See-through/90% 5:Controller highlight/Pointing hand 6:UI scale 7:Moodles/Right edge 8:Action bar/Verbose 9:Messages/1 new 10:Reset windows/Both windows back to where they start 11:ZeD setup/Options, on ZeD's page 12:Safe mode/The game's own interface
ZEDQA wh dright zed=true java=UIElement n=8 x=1595 y=755 w=650 vis=false point=-1 title=nil | 1:Tabs/World window 2:Map 3:Vehicle/No vehicle in reach.[off] 4:Animal/No tame animal in reach.[off] 5:Craft and build 6:Search 7:Lights and power/No lights or power in reach.[off] 8:Designated Zones/Animals
ZEDQA wh zone route: world=true vanillaZone=false
ZEDQA wh zone tab showing=true
ZEDQA wh search route: forage showing=true vanillaSearch=false
ZEDQA wh player info route: char=true vanillaInfo=false
ZEDQA wh DONE
```

### 63. zedqa_dpad_wheels.lua (`ZEDQA dw`) - PASS, 49 s

- go 16212 at 22:58:12
- screenshots: zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png

```text
[ZeD.QA] windows reset (R)
ZEDQA dw start
[ZeD.QA] run #63 ok=true
ZEDQA dw scene: at 868,13026, in a car false, health 100
ZEDQA dw foot left: 9 slices, crumb Character, visible false | 1:Tabs / Character window [>] 2:Weapons [>] 3:Eat [>] 4:Drink / Nothing to drink on you. [off] 5:Medicine and first aid [>] 6:Sleep / Not tired enough to sleep. [off] 7:Clothing / Nothing you wear can change. [off] 8:Use / Smoke | Read | Watch | Radio [>] 9:Loadouts / No loadouts saved [off]
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
ZEDQA dw foot down: 8 slices, crumb Here and now, visible false | 1:Sit [>] 2:Crouch / Off 3:Auto-walk / Off 4:Game speed [>] 5:Zoom [>] 6:View / Interface and windows [>] 7:Help [>] 8:Lighter / Turn on
ZEDQA dw PASS down: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS down: the slice 'Zoom' is there
ZEDQA dw inner down: 3 slices, crumb Here and now + Zoom, visible true | 1:Zoom 75% 2:Zoom 125% 3:Back
ZEDQA dw PASS down: the inner wheel ends with Back
ZEDQA dw PASS down: the breadcrumb names the inner wheel
ZEDQA dw PASS down: B from the inner wheel is back on the top level
ZEDQA dw PASS down: B on the top level closes the wheel
ZEDQA dw foot select: 12 slices, crumb ZeD, visible false | 1:Base theme / Dark [>] 2:Accent color / PZ Teal [>] 3:Text size / Small [>] 4:See-through / 90% [>] 5:Controller highlight / Pointing hand [>] 6:UI scale [>] 7:Moodles / Right edge [>] 8:Action bar / Verbose [>] 9:Messages / 1 new 10:Reset windows / Both windows back to where they start 11:ZeD setup / Options, on ZeD's page 12:Safe mode / The game's own interface
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
ZEDQA dw animal wheel: 4 slices, crumb World + Animal, visible false | 1:Pick up Angus Cow 2:Pet 3:Animal Info 4:Back
ZEDQA dw PASS the animal wheel ends with Back
ZEDQA dw 0 failed
ZEDQA dw DONE
```

### 64. zedqa_pad_glyphs.lua (`ZEDQA pg`) - PASS, 30 s

- go 16213 at 22:59:04
- screenshots: zqa_pg_footer_ps.png, zqa_pg_wheel_ps.png, zqa_pg_footer_xbox.png, zqa_pg_wheel_xbox.png, zqa_pg_footer_deck.png, zqa_pg_wheel_deck.png, zqa_pg_footer_nintendo.png, zqa_pg_wheel_nintendo.png, zqa_pg_footer_kbm.png, zqa_pg_wheel_kbm.png, zqa_pg_footer_ps_light.png, zqa_pg_wheel_ps_light.png, zqa_pg_footer_ps_hicon.png, zqa_pg_wheel_ps_hicon.png

```text
[ZeD.QA] windows reset (R)
ZEDQA pg start
[ZeD.QA] run #64 ok=true
ZEDQA pg scene: glyph setting xbox, the game's style XBOX, input gamepad
ZEDQA pg PASS ps: the setting reads ps
ZEDQA pg PASS ps: the set in use is ps
ZEDQA pg ps: footer pictures drawn in 10 ticks: 30
ZEDQA pg PASS ps: the footer draws its buttons as pictures
ZEDQA pg ps: wheel pictures drawn in 5 ticks: 16
ZEDQA pg PASS ps: the wheel's prompts are pictures
ZEDQA pg PASS xbox: the setting reads xbox
ZEDQA pg PASS xbox: the set in use is xbox
ZEDQA pg xbox: footer pictures drawn in 10 ticks: 36
ZEDQA pg PASS xbox: the footer draws its buttons as pictures
ZEDQA pg xbox: wheel pictures drawn in 5 ticks: 24
ZEDQA pg PASS xbox: the wheel's prompts are pictures
ZEDQA pg PASS deck: the setting reads deck
ZEDQA pg PASS deck: the set in use is deck
ZEDQA pg deck: footer pictures drawn in 10 ticks: 30
ZEDQA pg PASS deck: the footer draws its buttons as pictures
ZEDQA pg deck: wheel pictures drawn in 5 ticks: 24
ZEDQA pg PASS deck: the wheel's prompts are pictures
ZEDQA pg PASS nintendo: the setting reads nintendo
ZEDQA pg PASS nintendo: the set in use is nin
ZEDQA pg nintendo: footer pictures drawn in 10 ticks: 42
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

### 65. zedqa_quick_chords.lua (`ZEDQA qc`) - FAIL, 25 s

- go 16214 at 22:59:38
- 1 Java exception(s) in the log
- 1 ERR line(s)
- screenshots: zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png

```text
[ZeD.QA] windows reset (R)
ZEDQA qc start
[ZeD.QA] run #65 ok=true
ZEDQA qc the torch (added) and water, a cigarette, a lighter, an apple in the main inventory; hands: nil / nil
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
ZEDQA qc RB+A = character:5 (Character > Medicine and first aid): Medicine and first aid
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
ZEDQA qc LB + X from a bag queued: ISInventoryTransferAction, ISEquipWeaponAction
ZEDQA qc PASS LB + X from a bag: the light is out of the bag
ZEDQA qc PASS LB + X from a bag: the light is in a hand
ZEDQA qc PASS LB + X from a bag: the light is on
ZEDQA qc PASS stuffed: Eat says Too full to eat more.
ZEDQA qc LB + A (eat) queued: ISEatFoodAction
ZEDQA qc PASS LB + A (eat): the game queues its action
ZEDQA qc LB + B (drink) queued: ISDrinkFromBottle
ZEDQA qc PASS LB + B (drink): the game queues its action
ERROR: General f:80758> Lua(Vanilla).getDuration> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getDuration at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).getDuration(ISEatFoodAction.lua:208)
    Lua(Vanilla).new(ISEatFoodAction.lua:321)
    Lua(Vanilla).eatItem(ISInventoryPaneContextMenu.lua:3607)
    Lua(Vanilla).onEatItems(ISInventoryPaneContextMenu.lua:3753)
    Lua((MOD:ZeD-GUI)).smoke(ZeD_QuickWheel.lua:181)
ZEDQA qc LB + Y (smoke) queued:
ZEDQA qc FAIL LB + Y (smoke): the game queues its action
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
ZEDQA qc the list for LB+A: 89 items, 81 to choose
ZEDQA qc PASS the chord's list offers the wheels' actions
ZEDQA qc put back: the chords file as it was; RB + Y reads world:2:1 (was world:2:1)
ZEDQA qc PASS the chords are as they were
ZEDQA qc 1 failed
ZEDQA qc DONE
```

### 66. zedqa_put_back.lua (`ZEDQA pb`) - PASS, 33 s

- go 16215 at 23:00:06

```text
[ZeD.QA] windows reset (R)
ZEDQA pb start
[ZeD.QA] run #66 ok=true
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

### 67. zedqa_food_verbs.lua (`ZEDQA fv`) - PASS, 4 s

- go 16216 at 23:00:42
- screenshots: zqa_fv_smoking.png

```text
[ZeD.QA] windows reset (R)
ZEDQA fv start
[ZeD.QA] run #67 ok=true
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

### 68. zedqa_messages.lua (`ZEDQA msg`) - PASS, 12 s

- go 16217 at 23:00:50
- 1 expected exception(s) ignored (expect=)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
[ZeD.QA] windows reset (R)
ZEDQA msg start
[ZeD.QA] run #68 ok=true
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
ERROR: General f:86739 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:86739> Lua(Vanilla).boom> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaMessagesError of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom(worldmap-annotations.lua:103)
ZEDQA msg PASS the one error is filed in Messages, counted once (0 -> 1)
ZEDQA msg PASS Messages opens on the mod
ZEDQA msg PASS opening it marks the mod's messages read
ZEDQA msg PASS four cards: three notes and the question (4)
ZEDQA msg PASS three OK buttons, one per note (3)
ZEDQA msg PASS OK ran that mod's callback once (1/0/0)
ZEDQA msg PASS A on the next card's OK ran its callback
ZEDQA msg PASS the controller is in the cards
ZEDQA msg PASS the window lists an error source
ZEDQA msg PASS the bug report text names the errors (1447 characters)
ZEDQA msg PASS with the switch on, the mod's note shows as a pop-up
ZEDQA msg PASS Clear removes the mod's messages
ZEDQA msg PASS the last unanswered note got its OK as it left
ZEDQA msg all checks passed
ZEDQA msg DONE
```

### 69. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 20 s

- go 16218 at 23:01:05
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #69 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 4
ZEDQA mood box by itself: STRESS | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA mood right: 4 moodles on (STRESS 2, THIRST 2, HUNGRY 2, TIRED 2)
ZEDQA mood PASS right: the place is in effect
ZEDQA mood PASS right: at least three moodles are on
ZEDQA mood PASS right: the moodles are shown (layer)
ZEDQA mood right column at 3782,969 size 48, stack 222; visible true
ZEDQA mood PASS right: vanilla's column is visible
ZEDQA mood PASS right: every moodle is on screen
ZEDQA mood PASS right: the column is on the right edge (x 3782)
ZEDQA mood PASS right: ZeD's hover layer lies over the column
ZEDQA mood right bubble: moodle 2, cloud -500,33 442x98, trail right from -56,82
ZEDQA mood PASS right: the bubble is for the moodle under the pointer
ZEDQA mood PASS right: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS right: the trail ends at the moodle, level with it
ZEDQA mood left: 4 moodles on (STRESS 2, THIRST 2, HUNGRY 2, TIRED 2)
ZEDQA mood PASS left: the place is in effect
ZEDQA mood PASS left: at least three moodles are on
ZEDQA mood PASS left: the moodles are shown (layer)
ZEDQA mood left column at 10,969 size 48, stack 222; visible true
ZEDQA mood PASS left: vanilla's column is visible
ZEDQA mood PASS left: every moodle is on screen
ZEDQA mood PASS left: the column is on the left edge (x 10)
ZEDQA mood PASS left: ZeD's hover layer lies over the column
ZEDQA mood left bubble: moodle 2, cloud 106,33 442x98, trail left from 104,82
ZEDQA mood PASS left: the bubble is for the moodle under the pointer
ZEDQA mood PASS left: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS left: the trail ends at the moodle, level with it
ZEDQA mood bottom: 4 moodles on (STRESS 2, THIRST 2, HUNGRY 2, TIRED 2)
ZEDQA mood PASS bottom: the place is in effect
ZEDQA mood PASS bottom: at least three moodles are on
ZEDQA mood PASS bottom: the moodles are shown (layer)
ZEDQA mood bottom row at 1809,1965 222x48; vanilla's column y -10000
ZEDQA mood PASS bottom: the row is on screen
ZEDQA mood PASS bottom: the row is centred (middle 1920 of 3840)
ZEDQA mood PASS bottom: the row sits above the belt
ZEDQA mood PASS bottom: one slot per moodle
ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
ZEDQA mood bottom bubble: moodle 2, cloud -133,-156 442x98, trail down from 82,-56
ZEDQA mood PASS bottom: the bubble is for the moodle under the pointer
ZEDQA mood PASS bottom: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS bottom: the trail ends at the moodle, level with it
ZEDQA mood PASS with nothing changing the box goes by itself (nil)
ZEDQA mood notices off: box nil | waiting 2
ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
ZEDQA mood all checks passed
ZEDQA mood DONE
```

### 70. zedqa_ring_squares.lua (`ZEDQA rs`) - PASS, 7 s

- go 16219 at 23:01:29
- screenshots: zqa_rs_belt_full.png, zqa_rs_belt_70_45.png, zqa_rs_belt_15.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rs start
[ZeD.QA] run #70 ok=true
ZEDQA rs belt at 1535,2034, hands: s 0,10 77 | p 88,0 98
ZEDQA rs PASS full: both hands on the belt
ZEDQA rs PASS full: the conditions read 1.00 / 1.00
ZEDQA rs belt at 1535,2034, hands: s 0,10 77 | p 88,0 98
ZEDQA rs PASS 70_45: both hands on the belt
ZEDQA rs PASS 70_45: the conditions read 0.70 / 0.50
ZEDQA rs belt at 1535,2034, hands: s 0,10 77 | p 88,0 98
ZEDQA rs PASS 15: both hands on the belt
ZEDQA rs PASS 15: the conditions read 0.20 / 0.20
ZEDQA rs all checks passed
ZEDQA rs DONE
```

### 71. zedqa_sandbox_ig.lua (`ZEDQA sbx`) - PASS, 17 s

- go 16220 at 23:01:39
- screenshots: zqa_sbx_pause_line.png, zqa_sbx_time.png, zqa_sbx_world_help.png, zqa_sbx_zombie_changed.png, zqa_sbx_ask_apply.png, zqa_sbx_applied.png, zqa_sbx_history.png, zqa_sbx_pad.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sbx start
[ZeD.QA] run #71 ok=true
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
ZEDQA sbx world line: This world is on day 5 of the count the shut-offs use. Water: on until day 14. Power: on until day 99999.
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

### 72. zedqa_twoway.lua (`ZEDQA tw`) - PASS, 47 s

- go 16221 at 23:02:00
- screenshots: zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tw start
[ZeD.QA] run #72 ok=true
ZEDQA tw screen 3840x2160, root scale 1.75, plate zoom 2
ZEDQA tw PASS walkie_valutech: the Character window's Radio tab opens
ZEDQA tw PASS walkie_valutech: its own face, walkie_valutech (got walkie_valutech)
ZEDQA tw PASS walkie_valutech: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_valutech: centred in its panel (x 207, want 207)
ZEDQA tw PASS walkie_valutech: the tab is the card the face's 220 panel fits (840 px; panel and scrollbar 465, card 840)
ZEDQA tw PASS walkie_valutech: all 6 controls on the face (6)
ZEDQA tw PASS walkie_valutech: the full view button in the header
ZEDQA tw PASS walkie_valutech: VOL pressed turns it on
ZEDQA tw PASS walkie_valutech: the display reads while on
ZEDQA tw walkie_valutech: display 098.000 | NNR RADIO | BAT 3
ZEDQA tw PASS walkie_valutech: BAT with 3 bars at 60% charge
ZEDQA tw valutech: body 585 px tall, the face's body needs 799 (window 735)
ZEDQA tw PASS valutech: at the default height the body scrolls
ZEDQA tw PASS valutech: the wheel off the knobs scrolls the body (0 -> 0.05)
ZEDQA tw PASS valutech: the grown window shows the whole face, no scrollbar
ZEDQA tw PASS VOL: the wheel turns the volume up (0.50 -> 0.60)
ZEDQA tw PASS TUNE: a click on its right half tunes up a step (98000 -> 98200)
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
ZEDQA tw PASS walkie_toy: centred in its panel (x 220, want 220)
ZEDQA tw PASS walkie_toy: the tab is the card the face's 220 panel fits (840 px; panel and scrollbar 465, card 840)
ZEDQA tw PASS walkie_toy: all 3 controls on the face (3)
ZEDQA tw PASS walkie_toy: the full view button in the header
ZEDQA tw PASS walkie_toy: VOL pressed turns it on
ZEDQA tw PASS walkie_toy: the display reads while on
ZEDQA tw walkie_toy: display 89.40 MHZ | nil | nil nil
ZEDQA tw PASS toy: no memories, its TALK button
ZEDQA tw PASS toy: the drum shows the frequency
ZEDQA tw PASS walkie_premium: the Character window's Radio tab opens
ZEDQA tw PASS walkie_premium: its own face, walkie_premium (got walkie_premium)
ZEDQA tw PASS walkie_premium: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_premium: centred in its panel (x 220, want 220)
ZEDQA tw PASS walkie_premium: the tab is the card the face's 220 panel fits (840 px; panel and scrollbar 465, card 840)
ZEDQA tw PASS walkie_premium: all 6 controls on the face (6)
ZEDQA tw PASS walkie_premium: the full view button in the header
ZEDQA tw PASS walkie_premium: VOL pressed turns it on
ZEDQA tw PASS walkie_premium: the display reads while on
ZEDQA tw walkie_premium: display 256.200 | | BAT 3
ZEDQA tw PASS walkie_premium: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_tactical: the Character window's Radio tab opens
ZEDQA tw PASS walkie_tactical: its own face, walkie_tactical (got walkie_tactical)
ZEDQA tw PASS walkie_tactical: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_tactical: centred in its panel (x 220, want 220)
ZEDQA tw PASS walkie_tactical: the tab is the card the face's 220 panel fits (840 px; panel and scrollbar 465, card 840)
ZEDQA tw PASS walkie_tactical: all 9 controls on the face (9)
ZEDQA tw PASS walkie_tactical: the full view button in the header
ZEDQA tw PASS walkie_tactical: VOL pressed turns it on
ZEDQA tw PASS walkie_tactical: the display reads while on
ZEDQA tw walkie_tactical: display 156.400 | | BAT 3
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
ZEDQA tw PASS walkie_army: centred in its panel (x 220, want 220)
ZEDQA tw PASS walkie_army: the tab is the card the face's 220 panel fits (840 px; panel and scrollbar 465, card 840)
ZEDQA tw PASS walkie_army: all 9 controls on the face (9)
ZEDQA tw PASS walkie_army: the full view button in the header
ZEDQA tw PASS walkie_army: VOL pressed turns it on
ZEDQA tw PASS walkie_army: the display reads while on
ZEDQA tw walkie_army: display 998.800 | | BAT 3
ZEDQA tw PASS walkie_army: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_makeshift: the Character window's Radio tab opens
ZEDQA tw PASS walkie_makeshift: its own face, walkie_makeshift (got walkie_makeshift)
ZEDQA tw PASS walkie_makeshift: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_makeshift: centred in its panel (x 220, want 220)
ZEDQA tw PASS walkie_makeshift: the tab is the card the face's 220 panel fits (840 px; panel and scrollbar 465, card 840)
ZEDQA tw PASS walkie_makeshift: all 6 controls on the face (6)
ZEDQA tw PASS walkie_makeshift: the full view button in the header
ZEDQA tw PASS walkie_makeshift: VOL pressed turns it on
ZEDQA tw PASS walkie_makeshift: the display reads while on
ZEDQA tw walkie_makeshift: display CH-- 94.20 | USR | nil nil
ZEDQA tw PASS makeshift: its character display reads CH.. (CH-- 94.20)
ZEDQA tw PASS walkie_manpack: the Character window's Radio tab opens
ZEDQA tw PASS walkie_manpack: its own face, walkie_manpack (got walkie_manpack)
ZEDQA tw PASS walkie_manpack: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_manpack: centred in its panel (x 220, want 220)
ZEDQA tw PASS walkie_manpack: the tab is the card the face's 220 panel fits (840 px; panel and scrollbar 465, card 840)
ZEDQA tw PASS walkie_manpack: all 7 controls on the face (7)
ZEDQA tw PASS walkie_manpack: the full view button in the header
ZEDQA tw PASS walkie_manpack: VOL pressed turns it on
ZEDQA tw PASS walkie_manpack: the display reads while on
ZEDQA tw walkie_manpack: display 783.800 | | BAT 3
ZEDQA tw PASS walkie_manpack: BAT with 3 bars at 60% charge
ZEDQA tw PASS ManPack: on the back
ZEDQA tw PASS an AM/FM radio still shows the chassis
ZEDQA tw 8 free squares in reach
ZEDQA tw placed 3 ham sets
ZEDQA tw PASS the World window's Radio tab opens on the placed sets
ZEDQA tw PASS ham_civilian: its own face, ham_civilian (got ham_civilian)
ZEDQA tw PASS ham_civilian: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_civilian: centred across the drawer (x 84, want 84)
ZEDQA tw PASS ham_civilian: the drawer holds the whole set (840 px for 672)
ZEDQA tw PASS ham_civilian: all 8 controls on the face (8)
ZEDQA tw PASS ham_civilian: the full view button in the header
ZEDQA tw PASS ham_civilian: VOL pressed turns it on
ZEDQA tw ham_civilian: display 420.800 | | range RANGE 7.5 KM
ZEDQA tw PASS ham_civilian: the display reads while on
ZEDQA tw PASS the drawer's clip is set and cleared in pairs with a ham showing (14 sets, 14 clears)
ZEDQA tw PASS civilian ham: RANGE matches its transmit range (RANGE 7.5 KM)
ZEDQA tw PASS civilian ham: the band marker follows the frequency up (0.8383673469387755 -> 0.9404081632653061)
ZEDQA tw PASS civilian ham: full view opens
ZEDQA tw PASS ham_civilian on a small screen: its narrow face (ham_civilian_n)
ZEDQA tw PASS ham_civilian: the tab is the half card (385 px, want 385)
ZEDQA tw PASS ham_civilian: the narrow face at a whole zoom that fits the half card (1 of the screen's 2)
ZEDQA tw PASS ham_civilian: every control of the wide set on the narrow face (8)
ZEDQA tw PASS ham_civilian: VOL on the narrow face turns it on
ZEDQA tw PASS ham_civilian: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_civilian: the narrow face's display reads
ZEDQA tw PASS ham_army on a small screen: its narrow face (ham_army_n)
ZEDQA tw PASS ham_army: the tab is the half card (385 px, want 385)
ZEDQA tw PASS ham_army: the narrow face at a whole zoom that fits the half card (1 of the screen's 2)
ZEDQA tw PASS ham_army: every control of the wide set on the narrow face (14)
ZEDQA tw PASS ham_army: VOL on the narrow face turns it on
ZEDQA tw PASS ham_army: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_army: the narrow face's display reads
ZEDQA tw PASS ham_makeshift on a small screen: its narrow face (ham_makeshift_n)
ZEDQA tw PASS ham_makeshift: the tab is the half card (385 px, want 385)
ZEDQA tw PASS ham_makeshift: the narrow face at a whole zoom that fits the half card (1 of the screen's 2)
ZEDQA tw PASS ham_makeshift: every control of the wide set on the narrow face (7)
ZEDQA tw PASS ham_makeshift: VOL on the narrow face turns it on
ZEDQA tw PASS ham_makeshift: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_makeshift: the narrow face's display reads
ZEDQA tw PASS narrow makeshift ham: TALK / LISTEN flips with the mic
ZEDQA tw PASS with room again the wide set is back
ZEDQA tw PASS ham_army: its own face, ham_army (got ham_army)
ZEDQA tw PASS ham_army: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_army: centred across the drawer (x 84, want 84)
ZEDQA tw PASS ham_army: the drawer holds the whole set (840 px for 672)
ZEDQA tw PASS ham_army: all 14 controls on the face (14)
ZEDQA tw PASS ham_army: the full view button in the header
ZEDQA tw PASS ham_army: VOL pressed turns it on
ZEDQA tw ham_army: display 098.200 | | range RANGE 20 KM
ZEDQA tw PASS ham_army: the display reads while on
ZEDQA tw PASS army ham: tuned away
ZEDQA tw PASS army ham: 1 goes straight to memory 1
ZEDQA tw PASS army ham on the grid: AC, the bars dark (AC)
ZEDQA tw PASS ham_makeshift: its own face, ham_makeshift (got ham_makeshift)
ZEDQA tw PASS ham_makeshift: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_makeshift: centred across the drawer (x 84, want 84)
ZEDQA tw PASS ham_makeshift: the drawer holds the whole set (840 px for 672)
ZEDQA tw PASS ham_makeshift: all 7 controls on the face (7)
ZEDQA tw PASS ham_makeshift: the full view button in the header
ZEDQA tw PASS ham_makeshift: VOL pressed turns it on
ZEDQA tw ham_makeshift: display CH-- 133.200 MHZ | | range RANGE 6 KM
ZEDQA tw PASS ham_makeshift: the display reads while on
ZEDQA tw PASS makeshift ham: the TALK / LISTEN toggle flips with the mic
ZEDQA tw PASS makeshift ham: full view opens
ZEDQA tw PASS full view closes when the set is taken away
ZEDQA tw cleanup: 3 sets and 8 items taken away
ZEDQA tw 185 passed, 0 failed
ZEDQA tw all checks passed
ZEDQA tw DONE
```

### 73. zedqa_appliances.lua (`ZEDQA ap`) - PASS, 12 s

- go 16222 at 23:02:50
- screenshots: zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ap start
[ZeD.QA] run #73 ok=true
ZEDQA ap indoors at 876,13017
ZEDQA ap placed: stove true, microwave true
ZEDQA ap PASS the stove opens in the Craft tab
ZEDQA ap stove powered true (grid power on the square true, object index 3, world power true)
ZEDQA ap PASS stove: the station is the one opened
ZEDQA ap PASS stove: the World window is on its Craft tab
ZEDQA ap stove: plate oven_modern 336x136, tab 840 px, zoom in the tab 2 (the screen's 2)
ZEDQA ap PASS stove: the tab is the full card
ZEDQA ap PASS stove: the plate draws at a whole zoom that fits the card
ZEDQA ap PASS stove: the tab has the pop-out button
ZEDQA ap PASS the pop-out window is up
ZEDQA ap pop-out 1052,608 1736x943, zoom 5 (the screen's 2)
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
ZEDQA ap microwave: plate mw_white 336x168, tab 840 px, zoom in the tab 2 (the screen's 2)
ZEDQA ap PASS microwave: the tab is the full card
ZEDQA ap PASS microwave: the plate draws at a whole zoom that fits the card
ZEDQA ap PASS microwave: the tab has the pop-out button
ZEDQA ap PASS the microwave pops out too
ZEDQA ap cleanup: 2 appliances removed, station released
ZEDQA ap back at 867,13026
ZEDQA ap all checks passed
ZEDQA ap DONE
```

### 74. zedqa_two_widths.lua (`ZEDQA tww`) - WARN, 78 s

- go 16223 at 23:03:06
- 2 ERR line(s)
- screenshots: zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tww start
[ZeD.QA] run #74 ok=true
ZEDQA tww screen 3840x2160, root 1.75, half card 385 px, full card 840 px
ZEDQA tww to the deep run's home, 10608,11151
ZEDQA tww the pair at the start: Character 749,0 1162x735, World 1929,0 777x735
ZEDQA tww PASS the pair starts apart
ZEDQA tww 13 tab cases
ZEDQA tww Character equip: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character equip: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character equip: it is the full card (full)
ZEDQA tww PASS Character equip: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character equip: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character equip: both windows are on the screen
ZEDQA tww FAIL Character equip: closed, the window is back where and as wide as it was (749,0 1162x735 -> 1134,0 777x735)
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
ZEDQA tww FAIL after the whole run both windows are where and as big as they were (749,0 1162x735 / 1929,0 777x735 -> 1134,0 777x735 / 1929,0 777x735)
ZEDQA tww skipped, the thing was not there to open: World object card fire, World object card hook, World object card hutch, World object card lock, World object card plant, World object card track, World object card trough
ZEDQA tww 2 FAILED
ZEDQA tww DONE
```

### 75. zedqa_plates_336.lua (`ZEDQA p336`) - WARN, 116 s

- go 16224 at 23:04:28
- 2 ERR line(s)
- screenshots: zqa_p336_scale175_oven.png, zqa_p336_scale175_microwave.png, zqa_p336_scale175_chrome.png, zqa_p336_scale175_generator.png, zqa_p336_scale175_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png

```text
[ZeD.QA] windows reset (R)
ZEDQA p336 start
[ZeD.QA] run #75 ok=true
ZEDQA p336 indoors at 876,13018
ZEDQA p336 placed: oven true, microwave true, chrome true, generator true, grill true
ZEDQA p336 phase A: root 1.75 (the run's own scale)
ZEDQA p336 PASS oven opens in the Craft tab
ZEDQA p336 PASS oven: the station is the one opened
ZEDQA p336 oven [scale175, root 1.75, zoom 2]: plate oven_modern, drawn oven_modern, tab 840 px (half 385, full 840); controls bake d1 d2 d3 d4 d5 timer broil d6 d7 d8 d9 d0 cancel start
ZEDQA p336 PASS oven: the tab is the half card or the full card
ZEDQA p336 PASS oven: the face has its controls (15)
ZEDQA p336 PASS oven: the main face fits at the whole zoom, and is drawn (oven_modern)
ZEDQA p336 PASS oven: at the run's own scale the main face is drawn
ZEDQA p336 PASS oven: BAKE 175 START heats it and runs it (on true, 100)
ZEDQA p336 PASS oven: TIMER 0:30 START sets the timer (1800)
ZEDQA p336 PASS oven: CANCEL turns it off
ZEDQA p336 PASS microwave opens in the Craft tab
ZEDQA p336 PASS microwave: the station is the one opened
ZEDQA p336 microwave [scale175, root 1.75, zoom 2]: plate mw_white, drawn mw_white, tab 840 px (half 385, full 840); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS microwave: the tab is the half card or the full card
ZEDQA p336 PASS microwave: the face has its controls (14)
ZEDQA p336 PASS microwave: the main face fits at the whole zoom, and is drawn (mw_white)
ZEDQA p336 PASS microwave: at the run's own scale the main face is drawn
ZEDQA p336 PASS microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS microwave: STOP twice turns it off
ZEDQA p336 PASS chrome microwave opens in the Craft tab
ZEDQA p336 PASS chrome microwave: the station is the one opened
ZEDQA p336 chrome microwave [scale175, root 1.75, zoom 2]: plate mw_chrome, drawn mw_chrome, tab 840 px (half 385, full 840); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS chrome microwave: the tab is the half card or the full card
ZEDQA p336 PASS chrome microwave: the face has its controls (14)
ZEDQA p336 PASS chrome microwave: the main face fits at the whole zoom, and is drawn (mw_chrome)
ZEDQA p336 PASS chrome microwave: at the run's own scale the main face is drawn
ZEDQA p336 PASS chrome microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS chrome microwave: STOP twice turns it off
ZEDQA p336 generator [scale175, root 1.75]: card 840 px wide; controls gen:engine gen:outlet
ZEDQA p336 PASS generator: the card is the full card
ZEDQA p336 PASS generator: the face has its controls
ERROR: General f:102642 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:102650 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA p336 WARN step 60: waited 3000 frames, the condition never held
ZEDQA p336 FAIL generator: the engine switch starts it (the start was queued and never finished)
ZEDQA p336 PASS generator: the engine switch stops it
ZEDQA p336 grill [scale175, root 1.75]: card 840 px wide; controls bbq:tank bbq:burner bbq:ignite
ZEDQA p336 PASS grill: the card is the full card
ZEDQA p336 PASS grill: the face has its controls
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 879.5,13020.5 (grill 878,13020)
ZEDQA p336 PASS grill: the burner knob lights it (lit)
ZEDQA p336 phase B: forced root 0.50
ZEDQA p336 PASS oven opens in the Craft tab
ZEDQA p336 PASS oven: the station is the one opened
ZEDQA p336 oven [scale050, root 0.50, zoom 1]: plate oven_modern, drawn oven_modern_n, tab 240 px (half 110, full 240); controls bake d1 d2 d3 d4 d5 timer broil d6 d7 d8 d9 d0 cancel start
ZEDQA p336 PASS oven: the tab is the half card or the full card
ZEDQA p336 PASS oven: the face has its controls (15)
ZEDQA p336 PASS oven: the main face does not fit, the narrow face is drawn (oven_modern_n)
ZEDQA p336 PASS oven: at the run's own scale the main face is drawn
ZEDQA p336 PASS oven: BAKE 175 START heats it and runs it (on true, 100)
ZEDQA p336 PASS oven: TIMER 0:30 START sets the timer (1800)
ZEDQA p336 PASS oven: CANCEL turns it off
ZEDQA p336 PASS microwave opens in the Craft tab
ZEDQA p336 PASS microwave: the station is the one opened
ZEDQA p336 microwave [scale050, root 0.50, zoom 1]: plate mw_white, drawn mw_white_n, tab 240 px (half 110, full 240); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS microwave: the tab is the half card or the full card
ZEDQA p336 PASS microwave: the face has its controls (14)
ZEDQA p336 PASS microwave: the main face does not fit, the narrow face is drawn (mw_white_n)
ZEDQA p336 PASS microwave: at the run's own scale the main face is drawn
ZEDQA p336 PASS microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS microwave: STOP twice turns it off
ZEDQA p336 PASS chrome microwave opens in the Craft tab
ZEDQA p336 PASS chrome microwave: the station is the one opened
ZEDQA p336 chrome microwave [scale050, root 0.50, zoom 1]: plate mw_chrome, drawn mw_chrome_n, tab 240 px (half 110, full 240); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS chrome microwave: the tab is the half card or the full card
ZEDQA p336 PASS chrome microwave: the face has its controls (14)
ZEDQA p336 PASS chrome microwave: the main face does not fit, the narrow face is drawn (mw_chrome_n)
ZEDQA p336 PASS chrome microwave: at the run's own scale the main face is drawn
ZEDQA p336 PASS chrome microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS chrome microwave: STOP twice turns it off
ZEDQA p336 generator [scale050, root 0.50]: card 240 px wide; controls gen:engine gen:outlet
ZEDQA p336 PASS generator: the card is the full card
ZEDQA p336 PASS generator: the face has its controls
ERROR: General f:108450 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:108459 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA p336 WARN step 129: waited 3000 frames, the condition never held
ZEDQA p336 FAIL generator: the engine switch starts it (the start was queued and never finished)
ZEDQA p336 PASS generator: the engine switch stops it
ZEDQA p336 grill [scale050, root 0.50]: card 240 px wide; controls bbq:tank bbq:burner bbq:ignite
ZEDQA p336 PASS grill: the card is the full card
ZEDQA p336 PASS grill: the face has its controls
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 879.5,13020.5 (grill 878,13020)
ZEDQA p336 PASS grill: the burner knob lights it (lit)
ZEDQA p336 cleanup done: 5 things removed
ZEDQA p336 2 failed
ZEDQA p336 DONE
```

### 76. zedqa_seat_lightbar_vanilla.lua (`ZEDQA sl`) - PASS, 22 s

- go 16225 at 23:06:27
- screenshots: zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sl start
[ZeD.QA] run #76 ok=true
ZEDQA sl pickup=BaseVehicle{ Name:null, ID:156 } police=BaseVehicle{ Name:null, ID:207 } van=BaseVehicle{ Name:null, ID:208 }
ZEDQA sl enter Base.PickUpTruck dist=1.3 physics=true
ZEDQA sl enter Base.CarLightsKST dist=3.7 physics=true
ZEDQA sl lightbar x=1705 y=940 w=430 h=280
ZEDQA sl enter Base.VanSeats dist=7.8 physics=true
ZEDQA sl DONE
```

### 77. zedqa_car_radio_build.lua (`ZEDQA rb`) - PASS, 28 s

- go 16226 at 23:06:52
- screenshots: zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rb start
[ZeD.QA] run #77 ok=true
ZEDQA rb spawned Base.CarLightsPolice beside the character
ZEDQA rb Base.PickUpTruck radio=Base.RadioRed
ZEDQA rb Base.ModernCarLightsMeadeSheriff radio=Base.HamRadio1
ZEDQA rb dash only kind=premium item=Base.RadioRed on=false switch=false powered=true ch=94200 vol=0.6000000238418579 preset=nil name=USR signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=101.2 KnoxTalk Radio; 3=89.4 Hitz FM; 4=101.2 KnoxTalk Radio]
ZEDQA rb prop visible=nil at nil,nil nilxnil vanilla window=false
ZEDQA rb premium off kind=premium item=Base.RadioRed on=false switch=false powered=true ch=94200 vol=0.6000000238418579 preset=nil name=USR signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=101.2 KnoxTalk Radio; 3=89.4 Hitz FM; 4=101.2 KnoxTalk Radio]
ZEDQA rb prop visible=true at 1748,1492 960x300 vanilla window=false
ZEDQA rb premium power via vanilla's action ok=true canBePoweredHere=true battery=0.8595799803733826
ZEDQA rb premium on kind=premium item=Base.RadioRed on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=2 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=101.2 KnoxTalk Radio; 3=89.4 Hitz FM; 4=101.2 KnoxTalk Radio]
ZEDQA rb prop visible=true at 1748,1492 960x300 vanilla window=false
ZEDQA rb store 4 -> 4
ZEDQA rb premium stored kind=premium item=Base.RadioRed on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=2 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=STORE 4 mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=101.2 KnoxTalk Radio; 3=89.4 Hitz FM; 4=101.2 KnoxTalk Radio]
ZEDQA rb prop visible=true at 1748,1492 960x300 vanilla window=false
ZEDQA rb cds carried: 0
ZEDQA rb insert ok=true
ZEDQA rb cd in kind=premium item=Base.RadioRed on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=2 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=101.2 KnoxTalk Radio; 3=89.4 Hitz FM; 4=101.2 KnoxTalk Radio]
ZEDQA rb prop visible=true at 1748,1492 960x300 vanilla window=false
ZEDQA rb play ok=false
ZEDQA rb cd playing kind=premium item=Base.RadioRed on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=2 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=101.2 KnoxTalk Radio; 3=89.4 Hitz FM; 4=101.2 KnoxTalk Radio]
ZEDQA rb prop visible=true at 1748,1492 960x300 vanilla window=false
ZEDQA rb eject ok=false
ZEDQA rb ejected kind=premium item=Base.RadioRed on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=2 name=KnoxTalk Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=101.2 KnoxTalk Radio; 3=89.4 Hitz FM; 4=101.2 KnoxTalk Radio]
ZEDQA rb prop visible=true at 1748,1492 960x300 vanilla window=false
ZEDQA rb fit Base.RadioBlack ok=true nil
ZEDQA rb valutech kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=98000 vol=0.6000000238418579 preset=nil name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=101.2 KnoxTalk Radio; 3=89.4 Hitz FM; 4=101.2 KnoxTalk Radio]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb fit Base.RadioMakeShift ok=true nil
ZEDQA rb makeshift kind=makeshift item=Base.RadioMakeShift on=true switch=true powered=true ch=89400 vol=0.6000000238418579 preset=3 name=Hitz FM signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=101.2 KnoxTalk Radio; 3=89.4 Hitz FM; 4=101.2 KnoxTalk Radio]
ZEDQA rb prop visible=true at 1828,1536 880x256 vanilla window=false
ZEDQA rb fit Base.RadioRed ok=true nil
ZEDQA rb pickup restored kind=premium item=Base.RadioRed on=false switch=false powered=true ch=89400 vol=0.6000000238418579 preset=3 name=Hitz FM signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=101.2 KnoxTalk Radio; 3=89.4 Hitz FM; 4=101.2 KnoxTalk Radio]
ZEDQA rb prop visible=false at 1828,1536 880x256 vanilla window=false
ZEDQA rb ham power via vanilla's action ok=true canBePoweredHere=true battery=1
ZEDQA rb ham kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=1 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System]
ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
ZEDQA rb ham mic off kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=1 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=true
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System]
ZEDQA rb prop visible=true at 1708,1466 1000x326 vanilla window=false
ZEDQA rb mem -> 2
ZEDQA rb ham mem kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=146600 vol=1 preset=2 name=nil signal=false media=false playing=false title=nil flash=CH 02 STORED mic=false
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System; 2=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
ZEDQA rb siren opened; radio still up = false
ZEDQA rb fit Base.HamRadio2 ok=true nil
ZEDQA rb army kind=army item=Base.HamRadio2 on=true switch=true powered=true ch=98400 vol=1 preset=1 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System; 2=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1492 1000x300 vanilla window=false
ZEDQA rb fit Base.HamRadioMakeShift ok=true nil
ZEDQA rb hammake kind=hammake item=Base.HamRadioMakeShift on=true switch=true powered=true ch=98000 vol=1 preset=nil name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System; 2=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1516 1000x276 vanilla window=false
ZEDQA rb fit Base.HamRadio1 ok=true nil
ZEDQA rb police restored kind=ham item=Base.HamRadio1 on=false switch=false powered=true ch=98400 vol=1 preset=1 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System]
ZEDQA rb prop visible=false at 1708,1516 1000x276 vanilla window=false
ZEDQA rb DONE
```

### 78. zedqa_car_radio_cd.lua (`ZEDQA cd`) - PASS, 10 s

- go 16227 at 23:07:24
- screenshots: zqa_cd_c01_cdlist.png, zqa_cd_c02_cd_playing.png, zqa_cd_c03_ejected.png, zqa_cd_c04_valutech_tape.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cd start
[ZeD.QA] run #78 ok=true
ZEDQA cd pickup BaseVehicle{ Name:null, ID:156 } radio=Base.RadioRed
ZEDQA cd hand font height 17
ZEDQA cd vanilla CD recordings: 69
ZEDQA cd cd isRecordedMedia=true mediaType=0 name=CD: Moon Madness
ZEDQA cd cds carried: 1
ZEDQA cd inserted kind=premium on=true ch=93200 media=true playing=false title=Moon Madness cdMs=nil
ZEDQA cd play ok=true
ZEDQA cd playing kind=premium on=true ch=93200 media=true playing=true title=Moon Madness cdMs=1822
ZEDQA cd eject ok=true
ZEDQA cd ejected kind=premium on=true ch=93200 media=false playing=false title=nil cdMs=nil
ZEDQA cd disc back in inventory: false
ZEDQA cd fit Base.RadioBlack
ZEDQA cd valutech kind=valutech on=false ch=98400 media=false playing=false title=nil cdMs=nil
ZEDQA cd fit Base.RadioRed
ZEDQA cd DONE
```

### 79. zedqa_dash_props_smoke.lua (`ZEDQA sm`) - FAIL, 6 s

- go 16228 at 23:07:38
- 44 Java exception(s) in the log
- the script ran twice (re-bump)
- late output from pre (4 line(s), not counted)
- late output from tabs (2 line(s), not counted)
- late output from verbs (2 line(s), not counted)
- late output from gp (17 line(s), not counted)
- late output from band (5 line(s), not counted)
- late output from perf (15 line(s), not counted)
- late output from af (9 line(s), not counted)
- late output from cp (13 line(s), not counted)
- late output from cl (8 line(s), not counted)
- late output from cx (59 line(s), not counted)
- late output from op (20 line(s), not counted)
- late output from grid (11 line(s), not counted)
- late output from sg (58 line(s), not counted)
- late output from wtb (39 line(s), not counted)
- late output from doll (15 line(s), not counted)
- late output from dollv4 (71 line(s), not counted)
- late output from lg (4 line(s), not counted)
- late output from cu (319 line(s), not counted)
- late output from cv (14 line(s), not counted)
- late output from ev (28 line(s), not counted)
- late output from nav (163 line(s), not counted)
- late output from lt (3 line(s), not counted)
- late output from wpt (129 line(s), not counted)
- late output from fu (10 line(s), not counted)
- late output from ti (1 line(s), not counted)
- late output from tl (3 line(s), not counted)
- late output from win (3 line(s), not counted)
- late output from rc (4 line(s), not counted)
- late output from sw (64 line(s), not counted)
- late output from scale (7 line(s), not counted)
- late output from ms (3 line(s), not counted)
- late output from mst (5 line(s), not counted)
- late output from fl (6 line(s), not counted)
- late output from fm (9 line(s), not counted)
- late output from mnote (23 line(s), not counted)
- late output from jr (2 line(s), not counted)
- late output from jrd (10 line(s), not counted)
- late output from ls (63 line(s), not counted)
- late output from rst (84 line(s), not counted)
- late output from rd (7 line(s), not counted)
- late output from rr (3 line(s), not counted)
- late output from nb (7 line(s), not counted)
- late output from pf (11 line(s), not counted)
- late output from ts (6 line(s), not counted)
- late output from pr (40 line(s), not counted)
- late output from fi (7 line(s), not counted)
- late output from props (2 line(s), not counted)
- late output from belt (2 line(s), not counted)
- late output from straps (17 line(s), not counted)
- late output from bk (7 line(s), not counted)
- late output from bks (28 line(s), not counted)
- late output from bw (10 line(s), not counted)
- late output from ht (120 line(s), not counted)
- late output from watches (20 line(s), not counted)
- late output from cb (5 line(s), not counted)
- late output from ct (33 line(s), not counted)
- late output from cc (7 line(s), not counted)
- late output from px (12 line(s), not counted)
- late output from bg (4 line(s), not counted)
- late output from ws (8 line(s), not counted)
- late output from wi (96 line(s), not counted)
- late output from wh (16 line(s), not counted)
- late output from dw (73 line(s), not counted)
- late output from pg (35 line(s), not counted)
- late output from qc (59 line(s), not counted)
- late output from pb (28 line(s), not counted)
- late output from fv (13 line(s), not counted)
- late output from msg (27 line(s), not counted)
- late output from mood (51 line(s), not counted)
- late output from rs (12 line(s), not counted)
- late output from sbx (45 line(s), not counted)
- late output from tw (204 line(s), not counted)
- late output from ap (35 line(s), not counted)
- late output from tww (381 line(s), not counted)
- late output from p336 (88 line(s), not counted)
- late output from sl (7 line(s), not counted)
- late output from rb (68 line(s), not counted)
- late output from cd (16 line(s), not counted)
- the game dropped to the main menu during this script
- screenshots: zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sm start
[ZeD.QA] run #79 ok=true
ZEDQA sm pickup=true police=true
ZEDQA sm dash visible=true design=d6
ZEDQA sm radio up=true
ZEDQA sm siren up=true dash design=ambulance
ZEDQA sm ham radio up=true
    LOG  : Lua          f:116768> ZEDQA sm DONE
[ZeD.QA] bridge armed (main menu, poll every 30 ticks)
[ZeD.QA] autoload: continuing the latest save
ERROR: Lua f:0 at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
ERROR: General f:0 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"   (x2)
[ZeD.QA] bridge armed (in game, poll every 30 ticks)
[ZeD.QA] ZeD-QA: the whole map known (0,0 to 20000,17000) true
[ZeD.QA] windows reset (R)
ZEDQA pre start   (late output from pre)
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61   (late output from pre)
ZEDQA pre search overlay: enabled false, override false, manager false   (late output from pre)
ZEDQA pre DONE   (late output from pre)
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
ZEDQA world tabs: loot,craft,build,furniture,maps
ZEDQA tabs armed   (late output from tabs)
[ZeD.QA] run #2 ok=true
ZEDQA char tab=loot active=loot w=777 focusables=0 {}
ZEDQA char tab=equip active=equip w=1617 focusables=36 {el=4 equipbelt=1 equipgroup=5 equippart=17 equipslot=7 equipview=2}
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
ZEDQA tabs done   (late output from tabs)
[ZeD.QA] windows reset (R)
ZEDQA verbs armed   (late output from verbs)
[ZeD.QA] run #3 ok=true
ZEDQA worn=T-shirt ctx=equipped
ZEDQA fire UNEQUIP ok=true err=nil qhead=ISUnequipAction
ZEDQA after UNEQUIP pEq=false ctx=inventory (expect inventory)
ZEDQA fire EQUIP ok=true err=nil qhead=ISWearClothing
ZEDQA after EQUIP pEq=true ctx=equipped (expect equipped)
ZEDQA fire READ ok=true err=nil qhead=ISReadABook
ZEDQA after READ qhead=ISReadABook (expect ISReadABook)
ZEDQA fire EQUIP ok=true err=nil qhead=ISEquipWeaponAction
ZEDQA after EQUIP bat primary=Baseball Bat ctx=equipped (expect equipped)
ZEDQA fire UNEQUIP ok=true err=nil qhead=ISUnequipAction
ZEDQA after UNEQUIP bat primary=nil (expect nil)
ZEDQA fire EAT ok=true err=nil qhead=ISEatFoodAction
ZEDQA after EAT qhead=ISEatFoodAction (expect ISEatFoodAction)
ZEDQA fire DROP ok=true err=nil qhead=ISInventoryTransferAction
ZEDQA after DROP cont=floor ctx=ground (expect floor/ground)
ZEDQA fire TAKE ok=true err=nil qhead=ISInventoryTransferAction
ZEDQA after TAKE inInv=true ctx=inventory (expect inventory)
ZEDQA verbs done   (late output from verbs)
[ZeD.QA] windows reset (R)
ZEDQA gp armed   (late output from gp)
[ZeD.QA] run #4 ok=true
ZEDQA gp claim zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false   (late output from gp)
ZEDQA gp down zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false   (late output from gp)
ZEDQA gp right zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false   (late output from gp)
ZEDQA gp left zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false   (late output from gp)
ZEDQA gp loot charTabContent elements=0 (expect 0)   (late output from gp)
ZEDQA gp right after journal to loot (expect container strip, never jsub) zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false   (late output from gp)
ZEDQA gp after row2 onActivate (expect card open) zone=charItemCard el=hverb_1 tab=loot drawer=true item=Baseball Bat ctx=false   (late output from gp)
ZEDQA gp after row3 onActivate (expect live swap) zone=charItemCard el=hverb_1 tab=loot drawer=true item=Book: "The Omega Department Guide (Unofficial)", by Napoleon Trejo ctx=false   (late output from gp)
ZEDQA gp after row3 again (expect closed) zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false   (late output from gp)
ZEDQA gp after row2 onContextMenu (expect ctx=true) zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=true   (late output from gp)
ZEDQA gp after ctx B (expect ctx=false) zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false   (late output from gp)
ZEDQA gp world claim zone=worldContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false   (late output from gp)
ZEDQA gp world right zone=worldCtl el=worldCtl:take tab=loot drawer=false item=nil ctx=false   (late output from gp)
ZEDQA gp world craft down zone=worldCtl el=worldCtl:take tab=craft drawer=true item=nil ctx=false   (late output from gp)
ZEDQA gp world loot left (stale check) zone=worldContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false   (late output from gp)
ZEDQA gp done   (late output from gp)
[ZeD.QA] windows reset (R)
ZEDQA band armed   (late output from band)
[ZeD.QA] run #5 ok=true
ZEDQA band reading active=true kind=reading mode=nil label=Reading pct=0.03846567124128342 time=nil (expect active reading)   (late output from band)
ZEDQA band after cancel active=false kind=nil mode=nil label=nil pct=nil time=nil qlen=0 (expect inactive, 0)   (late output from band)
ZEDQA band: no real stove within 20 tiles; cooking skipped   (late output from band)
ZEDQA band done   (late output from band)
[ZeD.QA] windows reset (R)
[ZeD.QA] run #6 ok=true
ZEDQA perf char loot avg=8.62ms/tick max=35ms   (late output from perf)
ZEDQA perf char equip avg=10.01ms/tick max=20ms   (late output from perf)
ZEDQA perf char health avg=8.89ms/tick max=26ms   (late output from perf)
ZEDQA perf char thermal avg=9.31ms/tick max=19ms   (late output from perf)
ZEDQA perf char identity avg=9.18ms/tick max=32ms   (late output from perf)
ZEDQA perf char journal avg=8.56ms/tick max=17ms   (late output from perf)
ZEDQA perf char skills avg=8.88ms/tick max=36ms   (late output from perf)
ZEDQA perf world craft avg=9.06ms/tick max=25ms   (late output from perf)
ZEDQA perf world build avg=8.67ms/tick max=36ms   (late output from perf)
ZEDQA perf world maps avg=8.73ms/tick max=20ms   (late output from perf)
ZEDQA perf world forage avg=8.73ms/tick max=35ms   (late output from perf)
ZEDQA perf world animals avg=8.58ms/tick max=16ms   (late output from perf)
ZEDQA perf world loot avg=8.60ms/tick max=35ms   (late output from perf)
ZEDQA perf world craft build: 11 elements, 0.07 ms per build   (late output from perf)
ZEDQA perf done   (late output from perf)
[ZeD.QA] windows reset (R)
ZEDQA af start   (late output from af)
[ZeD.QA] run #7 ok=true
ERROR: General f:9020> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9021> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9022> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9023> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9024> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9025> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9026> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9027> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9028> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9029> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9030> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9031> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9032> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9033> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9034> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9035> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9036> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9037> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9038> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9039> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9040> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9041> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9042> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9043> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9045> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9048> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9049> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9051> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9053> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9055> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9057> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9060> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9061> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9063> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9065> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9067> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9069> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9071> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9074> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9075> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9076> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9078> Lua(Vanilla).renderPapers> Exception thrown
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1146)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4664)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
... (3038 more lines; see console.txt)
```

### 80. zedqa_tm.lua (`ZEDQA tm`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 81. zedqa_tour3.lua (`ZEDQA t3`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 82. zedqa_dash19.lua (`ZEDQA dash`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 83. zedqa_dashpx.lua (`ZEDQA dpx`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 84. zedqa_exinfo.lua (`ZEDQA ex`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 85. zedqa_charinfo.lua (`ZEDQA ci`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 86. zedqa_equipdrag.lua (`ZEDQA eqd`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 87. zedqa_cazio_light.lua (`ZEDQA czl`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 88. zedqa_dashnight.lua (`ZEDQA dnt`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 89. zedqa_dash_green.lua (`ZEDQA dgr`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 90. zedqa_dash_keys_edge.lua (`ZEDQA dke`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 91. zedqa_dash_brands.lua (`ZEDQA dbr`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 92. zedqa_testlang.lua (`ZEDQA tlang`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 93. zedqa_safemode.lua (`ZEDQA safe`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 94. zedqa_soak.lua (`ZEDQA soak`) - SKIP, not run

- not run: the game dropped to the main menu during this script

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
