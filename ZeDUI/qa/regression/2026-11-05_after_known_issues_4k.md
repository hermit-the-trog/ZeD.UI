# ZeD-UI regression - 2026-11-05 16:58 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-05 16:58:41 |
| Finished | 2026-11-05 18:11:20 (72 min 38 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\regression_b4.txt (101 scripts) |
| Result | **100/101 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 21298 to 21400 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 21399, 21400)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | suite_tabs.lua | tabs | PASS | 14 |  |  |
| 4 | suite_verbs.lua | verbs | PASS | 19 |  |  |
| 5 | suite_gamepad.lua | gp | PASS | 8 |  |  |
| 6 | suite_band.lua | band | PASS | 3 |  |  |
| 7 | suite_perf.lua | perf | PASS | 40 |  |  |
| 8 | zedqa_audit_fixes.lua | af | PASS | 5 |  | 58 expected exception(s) ignored (expect=) |
| 9 | zedqa_card_pad.lua | cp | PASS | 5 | zqa_cp_card.png |  |
| 10 | zedqa_ctxlist.lua | cl | PASS | 5 | zqa_cl_1.png, zqa_cl_2.png |  |
| 11 | zedqa_ctx_icons.lua | cx | PASS | 23 | zqa_cx_grid.png, zqa_cx_strip_apple.png, zqa_cx_strip_pistol.png, zqa_cx_strip_bandage.png, zqa_cx_strip_hammer.png, zqa_cx_strip_floor.png, zqa_cx_list_apple.png, zqa_cx_list_pistol.png, zqa_cx_list_bandage.png, zqa_cx_list_hammer.png, zqa_cx_list_floor.png |  |
| 12 | zedqa_onepath.lua | op | PASS | 23 | zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png |  |
| 13 | zedqa_grid.lua | grid | PASS | 7 | zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png |  |
| 14 | zedqa_sort_groups.lua | sg | PASS | 52 | zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png |  |
| 15 | zedqa_wt_bracket.lua | wtb | PASS | 23 | zqa_wtb_small_list.png, zqa_wtb_open_stack.png, zqa_wtb_narrow_wt.png, zqa_wtb_small_grid.png, zqa_wtb_large_list.png, zqa_wtb_large_grid.png, zqa_wtb_two_columns.png, zqa_wtb_two_columns_large.png |  |
| 16 | zedqa_doll.lua | doll | PASS | 11 | zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png |  |
| 17 | zedqa_doll_v4.lua | dollv4 | PASS | 36 | zqa_dollv4_3840x2160_wide.png, zqa_dollv4_3840x2160_dpad.png, zqa_dollv4_3840x2160_wide_pads.png, zqa_dollv4_3840x2160_card.png, zqa_dollv4_3840x2160_narrow.png, zqa_dollv4_3840x2160_short.png |  |
| 18 | zedqa_large.lua | lg | PASS | 10 | zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png |  |
| 19 | zedqa_segbars.lua | segb | PASS | 1 |  |  |
| 20 | zedqa_curtain.lua | cu | PASS | 220 | zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png |  |
| 21 | zedqa_curtain2.lua | cv | PASS | 15 | zqa_cv_1.png, zqa_cv_2.png, zqa_cv_3.png |  |
| 22 | zedqa_navevents.lua | ev | PASS | 7 |  |  |
| 23 | zedqa_navmap.lua | nav | PASS | 15 |  |  |
| 24 | zedqa_loot_tabs.lua | lt | PASS | 1 |  |  |
| 25 | zedqa_world_pad_take.lua | wpt | PASS | 92 |  |  |
| 26 | zedqa_furniture.lua | fu | PASS | 2 |  |  |
| 27 | zedqa_tabicons.lua | ti | PASS | 3 | zqa_tabicons.png |  |
| 28 | zedqa_tabs_lit.lua | tl | PASS | 7 | zqa_tabs_1.png, zqa_tabs_2.png, zqa_tabs_3.png |  |
| 29 | zedqa_win.lua | win | PASS | 5 | zedqa_win_200.png, zedqa_win_100.png |  |
| 30 | zedqa_rootchange.lua | rc | PASS | 6 | zedqa_rc_100.png, zedqa_rc_200.png |  |
| 31 | zedqa_scalewalk.lua | sw | PASS | 66 | zedqa_sw_200_char_loot.png, zedqa_sw_200_char_equip.png, zedqa_sw_200_char_health.png, zedqa_sw_200_char_thermal.png, zedqa_sw_200_char_identity.png, zedqa_sw_200_char_journal.png, zedqa_sw_200_char_skills.png, zedqa_sw_200_world_loot.png, zedqa_sw_200_world_craft.png, zedqa_sw_200_world_build.png, zedqa_sw_200_world_furniture.png, zedqa_sw_200_world_maps.png, zedqa_sw_200_world_forage.png, zedqa_sw_200_world_animals.png, zedqa_sw_200_world_vehicle.png, zedqa_sw_100_char_loot.png, zedqa_sw_100_char_equip.png, zedqa_sw_100_char_health.png, zedqa_sw_100_char_thermal.png, zedqa_sw_100_char_identity.png, zedqa_sw_100_char_journal.png, zedqa_sw_100_char_skills.png, zedqa_sw_100_world_loot.png, zedqa_sw_100_world_craft.png, zedqa_sw_100_world_build.png, zedqa_sw_100_world_furniture.png, zedqa_sw_100_world_maps.png, zedqa_sw_100_world_forage.png, zedqa_sw_100_world_animals.png, zedqa_sw_100_world_vehicle.png |  |
| 32 | zedqa_uiscale.lua | scale | PASS | 14 | zedqa_scale_auto.png, zedqa_scale_x150.png, zedqa_scale_x100.png, zedqa_scale_auto_back.png, zedqa_scale_restored.png |  |
| 33 | zedqa_sc_font.lua | scf | PASS | 3 | zqa_scf_draw.png |  |
| 34 | zedqa_mapshot.lua | ms | PASS | 5 | zqa_ms_1.png, zqa_ms_2.png |  |
| 35 | zedqa_mapstyles.lua | mst | PASS | 15 | zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png |  |
| 36 | zedqa_flyers.lua | fl | PASS | 6 | zqa_fl_1.png, zqa_fl_2.png |  |
| 37 | zedqa_flyermap.lua | fm | PASS | 13 | zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png |  |
| 38 | zedqa_mapnotes.lua | mnote | PASS | 9 | zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png |  |
| 39 | zedqa_journal_refs.lua | jr | PASS | 5 | zqa_jr_01_diary.png, zqa_jr_02_flyers.png |  |
| 40 | zedqa_journal_readers.lua | jrd | PASS | 21 | zqa_jr_01_papers.png, zqa_jr_02_unread_look.png, zqa_jr_03_read_look.png, zqa_jr_04_notebooks.png, zqa_jr_05_written.png, zqa_jr_06_into.png, zqa_jr_07_logged.png |  |
| 41 | zedqa_lists.lua | ls | PASS | 17 | zqa_ls_01_page_480.png, zqa_ls_02_page_480_lines.png, zqa_ls_03_stepper.png, zqa_ls_04_ask_delete.png, zqa_ls_05_rightclick_list.png, zqa_ls_06_rightclick_strip.png, zqa_ls_07_card_inlists.png, zqa_ls_08_mark_popup.png |  |
| 42 | zedqa_restock.lua | rst | PASS | 59 | zqa_rst_01_bar_ghosts.png, zqa_rst_02_todo.png, zqa_rst_02b_todo_lines.png, zqa_rst_03_ask_band.png, zqa_rst_04_after_hardcore.png, zqa_rst_05_pin_accessible.png, zqa_rst_06_pin_casual.png, zqa_rst_07_long_trip.png, zqa_rst_07b_long_trip_table.png, zqa_rst_08_unpack.png |  |
| 43 | zedqa_reader.lua | rd | PASS | 11 | zqa_rd_01_paper.png, zqa_rd_02_words.png, zqa_rd_03_story2.png, zqa_rd_04_zoomed.png, zqa_rd_05_flier.png, zqa_rd_06_map.png |  |
| 44 | zedqa_reader_refs.lua | rr | PASS | 14 | zqa_rr_01_journal_flyers.png, zqa_rr_02_news_card.png, zqa_rr_03_vanilla_news_paper.png, zqa_rr_04_vanilla_news_words.png, zqa_rr_05_vanilla_flier_paper.png, zqa_rr_06_vanilla_flier_words.png, zqa_rr_07_vanilla_journal.png |  |
| 45 | zedqa_notebook.lua | nb | PASS | 8 | zqa_nb_01_page1.png, zqa_nb_02_erase_asks.png, zqa_nb_03_rail.png, zqa_nb_04_read_only.png, zqa_nb_05_locked_other.png |  |
| 46 | zedqa_print_fit.lua | pf | PASS | 14 | zqa_pf_1a_KnoxKnews_July1_vanilla.png, zqa_pf_1b_KnoxKnews_July1_fitted.png, zqa_pf_2a_KnoxKnews_July2_vanilla.png, zqa_pf_2b_KnoxKnews_July2_fitted.png, zqa_pf_3a_KentuckyHerald_July6_vanilla.png, zqa_pf_3b_KentuckyHerald_July6_fitted.png, zqa_pf_4a_NationalDispatch_July6_vanilla.png, zqa_pf_4b_NationalDispatch_July6_fitted.png |  |
| 47 | zedqa_print_typeset.lua | ts | PASS | 7 | zqa_ts_1_KnoxKnews_July1.png, zqa_ts_2_KnoxKnews_July2.png, zqa_ts_3_KentuckyHerald_July6.png, zqa_ts_4_NationalDispatch_July6.png |  |
| 48 | zedqa_prompts.lua | pr | PASS | 32 | zqa_pr_01_sleep.png, zqa_pr_02_kill.png, zqa_pr_03_note.png, zqa_pr_04_rename.png, zqa_pr_05_rename_empty.png, zqa_pr_06_keyboard.png, zqa_pr_07_alarm.png, zqa_pr_08_timer.png, zqa_pr_09_help.png, zqa_pr_10_rich_question.png, zqa_pr_11_gp_question.png, zqa_pr_12_gp_question_no.png, zqa_pr_13_gp_kill.png, zqa_pr_14_gp_text.png, zqa_pr_15_gp_keyboard.png, zqa_pr_16_gp_alarm.png |  |
| 49 | zedqa_fishing.lua | fi | PASS | 9 | zqa_fi_1_slack.png, zqa_fi_2_light.png, zqa_fi_3_tight.png, zqa_fi_4_strain.png, zqa_fi_5_limit.png |  |
| 50 | zedqa_props_plates.lua | props | PASS | 3 | zqa_props_1.png, zqa_props_2.png, zqa_props_3.png |  |
| 51 | zedqa_belt_strap.lua | belt | PASS | 2 | zqa_belt_strap_1.png |  |
| 52 | zedqa_straps.lua | straps | PASS | 12 | zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png |  |
| 53 | zedqa_buckle.lua | bk | PASS | 6 | zqa_bk_1.png, zqa_bk_2.png, zqa_bk_3.png |  |
| 54 | zedqa_buckles.lua | bks | PASS | 38 | zqa_bk_01_burgerflipper.png, zqa_bk_02_repairman.png, zqa_bk_03_burglar.png, zqa_bk_04_engineer.png, zqa_bk_05_fisherman.png, zqa_bk_06_policeofficer.png, zqa_bk_07_lumberjack.png, zqa_bk_08_smither.png, zqa_bk_09_farmer.png, zqa_bk_10_electrician.png, zqa_bk_11_fireofficer.png, zqa_bk_12_metalworker.png, zqa_bk_13_fitnessinstructor.png, zqa_bk_14_veteran.png, zqa_bk_15_tailor.png, zqa_bk_16_chef.png, zqa_bk_17_doctor.png, zqa_bk_18_parkranger.png, zqa_bk_19_unemployed.png, zqa_bk_20_nurse.png, zqa_bk_21_securityguard.png, zqa_bk_22_carpenter.png, zqa_bk_23_mechanics.png, zqa_bk_24_rancher.png, zqa_bk_25_constructionworker.png |  |
| 55 | zedqa_beltwatch.lua | bw | PASS | 12 | zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png |  |
| 56 | zedqa_hands_together.lua | ht | PASS | 19 | zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png |  |
| 57 | zedqa_watches2.lua | watches | PASS | 28 | zqa_watch_day_DigitalBlack.png, zqa_watch_day_DigitalDress.png, zqa_watch_day_DigitalRed.png, zqa_watch_day_DigitalTimez.png, zqa_watch_day_ClassicBlack.png, zqa_watch_day_ClassicGold.png, zqa_watch_day_ClassicBrown.png, zqa_watch_day_ClassicMilitary.png, zqa_watch_day_Expensive.png, zqa_watch_set_DigitalBlack.png, zqa_watch_night_DigitalBlack.png, zqa_watch_night_DigitalTimez.png, zqa_watch_lit_DigitalTimez.png, zqa_watch_night_ClassicBrown.png, zqa_watch_lit_ClassicBrown.png, zqa_watch_night_Expensive.png |  |
| 58 | zedqa_container_bottom.lua | cb | PASS | 11 | zqa_cb_01_rows_at_bottom.png, zqa_cb_02_list_end.png, zqa_cb_03_pad_take_all.png, zqa_cb_04_campfire_ribbon.png |  |
| 59 | zedqa_container_controls.lua | ct | PASS | 19 | zqa_ct_01_rows.png, zqa_ct_02_pad_same_type.png, zqa_ct_03_after_take_all.png, zqa_ct_04_floor_row.png, zqa_ct_05_campfire_row.png, zqa_ct_06_add_fuel_card.png |  |
| 60 | zedqa_container_controls_captures.lua | cc | PASS | 6 | zqa_cc_zed_truckbed.png, zqa_cc_vanilla_truckbed.png |  |
| 61 | zedqa_px_icons.lua | px | PASS | 6 | zqa_px_panel.png, zqa_px_card.png, zqa_px_rows.png |  |
| 62 | zedqa_button_case_game.lua | bg | PASS | 20 | zqa_bg_01_item_card.png, zqa_bg_02_health.png, zqa_bg_03_thermal.png, zqa_bg_04_animals.png, zqa_bg_05_forage.png, zqa_bg_06_craft.png, zqa_bg_07_vehicle.png |  |
| 63 | zedqa_immersive_searching.lua | iss | PASS | 4 | zqa_iss_off_a.png |  |
| 64 | zedqa_wheel_sizes.lua | ws | PASS | 20 | zqa_ws_a_gun3.png, zqa_ws_b_dright3.png, zqa_ws_c_emotes5.png, zqa_ws_d_signal9.png, zqa_ws_e_back10.png, zqa_ws_g_car11.png, zqa_ws_h_car11pt.png |  |
| 65 | zedqa_wheel_icons.lua | wi | PASS | 63 | zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png |  |
| 66 | zedqa_wheels.lua | wh | PASS | 31 | zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png |  |
| 67 | zedqa_dpad_wheels.lua | dw | PASS | 50 | zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png |  |
| 68 | zedqa_pad_glyphs.lua | pg | PASS | 34 | zqa_pg_footer_ps.png, zqa_pg_wheel_ps.png, zqa_pg_footer_xbox.png, zqa_pg_wheel_xbox.png, zqa_pg_footer_deck.png, zqa_pg_wheel_deck.png, zqa_pg_footer_nintendo.png, zqa_pg_wheel_nintendo.png, zqa_pg_footer_kbm.png, zqa_pg_wheel_kbm.png, zqa_pg_footer_ps_light.png, zqa_pg_wheel_ps_light.png, zqa_pg_footer_ps_hicon.png, zqa_pg_wheel_ps_hicon.png |  |
| 69 | zedqa_quick_chords.lua | qc | PASS | 25 | zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png |  |
| 70 | zedqa_put_back.lua | pb | PASS | 33 |  |  |
| 71 | zedqa_food_verbs.lua | fv | PASS | 4 | zqa_fv_smoking.png |  |
| 72 | zedqa_messages.lua | msg | PASS | 12 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=) |
| 73 | zedqa_moodles.lua | mood | PASS | 21 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png |  |
| 74 | zedqa_ring_squares.lua | rs | PASS | 8 | zqa_rs_belt_full.png, zqa_rs_belt_70_45.png, zqa_rs_belt_15.png |  |
| 75 | zedqa_sandbox_ig.lua | sbx | PASS | 17 | zqa_sbx_pause_line.png, zqa_sbx_time.png, zqa_sbx_world_help.png, zqa_sbx_zombie_changed.png, zqa_sbx_ask_apply.png, zqa_sbx_applied.png, zqa_sbx_history.png, zqa_sbx_pad.png |  |
| 76 | zedqa_twoway.lua | tw | PASS | 53 | zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png |  |
| 77 | zedqa_rtv.lua | rtv | PASS | 87 | zqa_rtv_1_radio_black.png, zqa_rtv_1_radio_red.png, zqa_rtv_1b_radio_red_list.png, zqa_rtv_1_radio_handbuilt.png, zqa_rtv_1_cd_player.png, zqa_rtv_1b_cd_player_list.png, zqa_rtv_2_pad_cd_player_battery_list.png, zqa_rtv_2_pad_cd_player_phones_list.png, zqa_rtv_2_pad_cd_player_disc_list.png, zqa_rtv_3_simple_card.png, zqa_rtv_4a_radio_red_placed.png, zqa_rtv_4c_tv_black_standby.png, zqa_rtv_4d_tv_black_triple_n_standby.png, zqa_rtv_4d_tv_black_turbo_standby.png, zqa_rtv_4c_tv_black_bars.png, zqa_rtv_4e_tv_black_no_power.png, zqa_rtv_2_pad_tv_black_tape_list.png, zqa_rtv_2_pad_tv_black_phones_list.png, zqa_rtv_4c_tv_widescreen_standby.png, zqa_rtv_4d_tv_widescreen_triple_n_standby.png, zqa_rtv_4d_tv_widescreen_turbo_standby.png, zqa_rtv_4c_tv_widescreen_bars.png, zqa_rtv_4e_tv_widescreen_no_power.png, zqa_rtv_4c_tv_antique_standby.png, zqa_rtv_4d_tv_antique_triple_n_standby.png, zqa_rtv_4d_tv_antique_turbo_standby.png, zqa_rtv_4c_tv_antique_bars.png, zqa_rtv_4e_tv_antique_no_power.png, zqa_rtv_5_house_bare.png, zqa_rtv_5_house_ci_radio.png, zqa_rtv_5_house_ci_tv.png |  |
| 78 | zedqa_appliances.lua | ap | PASS | 12 | zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png |  |
| 79 | zedqa_two_widths.lua | tww | PASS | 105 | zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png |  |
| 80 | zedqa_plates_336.lua | p336 | PASS | 60 | zqa_p336_scale175_oven.png, zqa_p336_scale175_microwave.png, zqa_p336_scale175_chrome.png, zqa_p336_scale175_generator.png, zqa_p336_scale175_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png |  |
| 81 | zedqa_laundry.lua | ldy | PASS | 83 | zqa_ldy_washer_1_open.png, zqa_ldy_washer_1_open_later.png, zqa_ldy_washer_lvl1_water.png, zqa_ldy_washer_lvl2_water.png, zqa_ldy_washer_lvl3_water.png, zqa_ldy_washer_lvl4_water.png, zqa_ldy_washer_lvl5_water.png, zqa_ldy_washer_lvl1_soak.png, zqa_ldy_washer_lvl2_soak.png, zqa_ldy_washer_lvl3_soak.png, zqa_ldy_washer_lvl4_soak.png, zqa_ldy_washer_lvl5_soak.png, zqa_ldy_washer_3_nowater.png, zqa_ldy_washer_3_nopower.png, zqa_ldy_washer_2_running.png, zqa_ldy_dryer_1_open.png, zqa_ldy_dryer_1_open_later.png, zqa_ldy_dryer_3_nopower.png, zqa_ldy_dryer_2_running.png, zqa_ldy_combo_1_open.png, zqa_ldy_combo_1_open_later.png, zqa_ldy_combo_lvl1_water.png, zqa_ldy_combo_lvl2_water.png, zqa_ldy_combo_lvl3_water.png, zqa_ldy_combo_lvl4_water.png, zqa_ldy_combo_lvl5_water.png, zqa_ldy_combo_lvl1_soak.png, zqa_ldy_combo_lvl2_soak.png, zqa_ldy_combo_lvl3_soak.png, zqa_ldy_combo_lvl4_soak.png, zqa_ldy_combo_lvl5_soak.png, zqa_ldy_combo_3_nowater.png, zqa_ldy_combo_3_nopower.png, zqa_ldy_combo_2_running.png |  |
| 82 | zedqa_seat_lightbar_vanilla.lua | sl | PASS | 20 | zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png |  |
| 83 | zedqa_car_radio_build.lua | rb | PASS | 29 | zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png |  |
| 84 | zedqa_car_radio_cd.lua | cd | PASS | 11 | zqa_cd_c01_cdlist.png, zqa_cd_c02_cd_playing.png, zqa_cd_c03_ejected.png, zqa_cd_c04_valutech_tape.png |  |
| 85 | zedqa_dash_props_smoke.lua | sm | PASS | 7 | zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png |  |
| 86 | zedqa_tm.lua | tm | PASS | 7 | zedqa_tm_tooltips.png, zedqa_tm_maps.png, zedqa_tm_dash.png |  |
| 87 | zedqa_tour3.lua | t3 | PASS | 14 | zedqa_t3_SmallCar02.png, zedqa_t3_ModernCar.png, zedqa_t3_ModernCar02.png, zedqa_t3_SUV.png, zedqa_t3_Van.png, zedqa_t3_PickUpVan.png, zedqa_t3_OffRoad.png |  |
| 88 | zedqa_dash19.lua | dash | PASS | 72 | zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png |  |
| 89 | zedqa_dashpx.lua | dpx | PASS | 128 | zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_07_primani_keyon.png, zqa_dashpx_07_primani.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png, zqa_dashpx_14_rancher.png, zqa_dashpx_15_taxi_keyon.png, zqa_dashpx_15_taxi.png, zqa_dashpx_16_ambulance_keyon.png, zqa_dashpx_16_ambulance.png, zqa_dashpx_17_fire_keyon.png, zqa_dashpx_17_fire.png, zqa_dashpx_18_ranger_keyon.png, zqa_dashpx_18_ranger.png, zqa_dashpx_19_race_keyon.png, zqa_dashpx_19_race.png, zqa_dashpx_20_knoxvan_keyon.png, zqa_dashpx_20_knoxvan.png, zqa_dashpx_21_fossoild6_keyon.png, zqa_dashpx_21_fossoild6.png, zqa_dashpx_23_meadesheriff_keyon.png, zqa_dashpx_23_meadesheriff.png, zqa_dashpx_24_lcpd_keyon.png, zqa_dashpx_24_lcpd.png |  |
| 90 | zedqa_exinfo.lua | ex | PASS | 8 | zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_menu.png, zqa_ex_situp.png |  |
| 91 | zedqa_charinfo.lua | ci | PASS | 9 |  |  |
| 92 | zedqa_equipdrag.lua | eqd | PASS | 13 | zqa_eqd_1.png, zqa_eqd_2.png, zqa_eqd_3.png, zqa_eqd_4.png |  |
| 93 | zedqa_cazio_light.lua | czl | PASS | 31 | zqa_cl_day_DigitalBlack.png, zqa_cl_daylit_DigitalBlack.png, zqa_cl_night_DigitalBlack.png, zqa_cl_nightlit_DigitalBlack.png, zqa_cl_day_DigitalDress.png, zqa_cl_daylit_DigitalDress.png, zqa_cl_night_DigitalDress.png, zqa_cl_nightlit_DigitalDress.png, zqa_cl_day_ClassicBlack.png, zqa_cl_daylit_ClassicBlack.png, zqa_cl_night_ClassicBlack.png, zqa_cl_nightlit_ClassicBlack.png, zqa_cl_day_ClassicGold.png, zqa_cl_daylit_ClassicGold.png, zqa_cl_night_ClassicGold.png, zqa_cl_nightlit_ClassicGold.png, zqa_cl_belt_night.png, zqa_cl_belt_nightlit.png, zqa_cl_belt_day.png, zqa_cl_belt_daylit.png |  |
| 94 | zedqa_dashnight.lua | dnt | PASS | 129 | zqa_dashnight_wagon_real.png, zqa_dashnight_wagon_day.png, zqa_dashnight_wagon_dusk.png, zqa_dashnight_wagon_night.png, zqa_dashnight_wagon_nightoff.png, zqa_dashnight_wagon_real_noon.png, zqa_dashnight_wagon_real_back_on.png, zqa_dashnight_wagon_real_back_off.png, zqa_dashnight_nyala_real.png, zqa_dashnight_nyala_day.png, zqa_dashnight_nyala_dusk.png, zqa_dashnight_nyala_night.png, zqa_dashnight_nyala_nightoff.png, zqa_dashnight_dashelite_real.png, zqa_dashnight_dashelite_day.png, zqa_dashnight_dashelite_dusk.png, zqa_dashnight_dashelite_night.png, zqa_dashnight_dashelite_nightoff.png, zqa_dashnight_luxury_real.png, zqa_dashnight_luxury_day.png, zqa_dashnight_luxury_dusk.png, zqa_dashnight_luxury_night.png, zqa_dashnight_luxury_nightoff.png, zqa_dashnight_ambulance_real.png, zqa_dashnight_ambulance_day.png, zqa_dashnight_ambulance_dusk.png, zqa_dashnight_ambulance_night.png, zqa_dashnight_ambulance_nightoff.png, zqa_dashnight_race_real.png, zqa_dashnight_race_day.png, zqa_dashnight_race_dusk.png, zqa_dashnight_race_night.png, zqa_dashnight_race_nightoff.png, zqa_dashnight_d6_real.png, zqa_dashnight_d6_day.png, zqa_dashnight_d6_dusk.png, zqa_dashnight_d6_night.png, zqa_dashnight_d6_nightoff.png |  |
| 95 | zedqa_dash_green.lua | dgr | PASS | 113 | zqa_dgr_d6_parked_day.png, zqa_dgr_d6_parked_day_keyin.png, zqa_dgr_fire_at_speed.png, zqa_dgr_dashelite_night_on.png, zqa_dgr_dashelite_night_off.png, zqa_dgr_primani_night_on.png, zqa_dgr_primani_night_off.png, zqa_dgr_suv_night_on.png, zqa_dgr_suv_night_off.png, zqa_dgr_luxury_night_on.png, zqa_dgr_luxury_night_off.png, zqa_dgr_cossette_night_on.png, zqa_dgr_cossette_night_off.png |  |
| 96 | zedqa_dash_keys_edge.lua | dke | WARN | 269 | zqa_dke_luxury_off.png, zqa_dke_luxury_start.png, zqa_dke_luxury_on.png, zqa_dke_nyala_off.png, zqa_dke_nyala_start.png, zqa_dke_nyala_on.png, zqa_dke_cossette_off.png, zqa_dke_cossette_start.png, zqa_dke_cossette_on.png, zqa_dke_police_off.png, zqa_dke_police_start.png, zqa_dke_police_on.png, zqa_dke_d6_off.png, zqa_dke_d6_start.png, zqa_dke_d6_on.png, zqa_dke_dashelite_off.png, zqa_dke_dashelite_start.png, zqa_dke_dashelite_on.png, zqa_dke_primani_off.png, zqa_dke_primani_start.png, zqa_dke_primani_on.png, zqa_dke_dart_off.png, zqa_dke_dart_start.png, zqa_dke_dart_on.png, zqa_dke_horizon_off.png, zqa_dke_horizon_start.png, zqa_dke_horizon_on.png, zqa_dke_wagon_off.png, zqa_dke_wagon_on.png, zqa_dke_suv_off.png, zqa_dke_suv_on.png, zqa_dke_van_off.png, zqa_dke_van_start.png, zqa_dke_van_on.png, zqa_dke_bulldriver_off.png, zqa_dke_bulldriver_start.png, zqa_dke_bulldriver_on.png, zqa_dke_rancher_off.png, zqa_dke_rancher_start.png, zqa_dke_rancher_on.png, zqa_dke_taxi_off.png, zqa_dke_taxi_on.png, zqa_dke_ambulance_off.png, zqa_dke_ambulance_start.png, zqa_dke_ambulance_on.png, zqa_dke_fire_off.png, zqa_dke_fire_start.png, zqa_dke_fire_on.png, zqa_dke_ranger_off.png, zqa_dke_ranger_start.png, zqa_dke_ranger_on.png, zqa_dke_race_off.png, zqa_dke_race_start.png, zqa_dke_race_on.png | 6 ERR line(s) |
| 97 | zedqa_dash_brands.lua | dbr | PASS | 165 | zqa_dbr_luxury.png, zqa_dbr_nyala.png, zqa_dbr_cossette.png, zqa_dbr_d6.png, zqa_dbr_dashelite.png, zqa_dbr_primani.png, zqa_dbr_dart.png, zqa_dbr_horizon.png, zqa_dbr_wagon.png, zqa_dbr_suv.png, zqa_dbr_van.png, zqa_dbr_bulldriver.png, zqa_dbr_rancher.png, zqa_dbr_stepvan.png, zqa_dbr_modded.png, zqa_dbr_dashelite_night.png, zqa_dbr_cossette_night.png |  |
| 98 | zedqa_testlang.lua | tlang | PASS | 130 | zqa_tl_01_char_loot_list.png, zqa_tl_02_char_loot_grid.png, zqa_tl_03_card_food.png, zqa_tl_04_card_weapon.png, zqa_tl_05_card_bottle.png, zqa_tl_06_card_gun.png, zqa_tl_07_char_equip_list.png, zqa_tl_08_char_equip_doll.png, zqa_tl_09_char_health.png, zqa_tl_10_char_thermal_1.png, zqa_tl_11_char_thermal_2.png, zqa_tl_12_char_thermal_3.png, zqa_tl_13_char_thermal_4.png, zqa_tl_14_char_thermal_5.png, zqa_tl_15_char_thermal_6.png, zqa_tl_16_char_thermal_7.png, zqa_tl_17_char_thermal_figure.png, zqa_tl_18_char_identity.png, zqa_tl_19_char_journal_1.png, zqa_tl_20_char_journal_2.png, zqa_tl_21_char_journal_3.png, zqa_tl_22_char_journal_4.png, zqa_tl_23_char_skills.png, zqa_tl_24_char_radio.png, zqa_tl_25_char_loot_back.png, zqa_tl_26_ctx_strip_food.png, zqa_tl_27_ctx_strip_weapon.png, zqa_tl_28_ctx_list_food.png, zqa_tl_29_ctx_list_submenu.png, zqa_tl_30_world_loot.png, zqa_tl_31_world_craft_list.png, zqa_tl_32_world_craft_recipe.png, zqa_tl_33_world_build_list.png, zqa_tl_34_world_build_recipe.png, zqa_tl_35_world_furniture.png, zqa_tl_36_world_furniture_rotate.png, zqa_tl_37_world_furniture_scrap.png, zqa_tl_38_world_furniture_repair.png, zqa_tl_39_world_furniture_pickup.png, zqa_tl_40_world_maps.png, zqa_tl_41_world_maps_survey.png, zqa_tl_42_world_maps_color.png, zqa_tl_43_world_maps_paper.png, zqa_tl_44_world_forage.png, zqa_tl_45_world_animals.png, zqa_tl_46_belt_watch_tucked.png, zqa_tl_47_belt_watch_popped.png, zqa_tl_48_watch_corner.png, zqa_tl_49_actionbar_reading_verbose.png, zqa_tl_50_actionbar_reading_simple.png, zqa_tl_51_wheel_emotes.png, zqa_tl_52_wheel_vehicle_outside.png, zqa_tl_53_prompt_question.png, zqa_tl_54_prompt_textbox.png, zqa_tl_55_prompt_textbox_empty.png, zqa_tl_56_prompt_keyboard.png, zqa_tl_57_prompt_alarm.png, zqa_tl_58_prompt_timer.png, zqa_tl_59_prompt_help.png, zqa_tl_60_prompt_rich_question.png, zqa_tl_61_safe_note.png, zqa_tl_62_pause_menu.png, zqa_tl_63_options_1_zed.png, zqa_tl_64_options_2_display.png, zqa_tl_65_options_3_graphics.png, zqa_tl_66_options_4_audio.png, zqa_tl_67_options_5_controls.png, zqa_tl_68_options_6_gameplay.png, zqa_tl_69_options_7_interface.png, zqa_tl_70_options_8_access.png, zqa_tl_71_options_9_mods.png, zqa_tl_72_pause_mods.png |  |
| 99 | zedqa_safemode.lua | safe | PASS | 14 | zqa_safe_1.png, zqa_safe_2.png, zqa_safe_3.png |  |
| 100 | zedqa_soak.lua | soak | PASS | 812 |  |  |
| 101 | zedqa_cook80.lua | c80 | PASS | 49 | zqa_c80_3840x2160_1_open.png, zqa_c80_3840x2160_2_stew_plan.png, zqa_c80_3840x2160_2_stew_made.png, zqa_c80_3840x2160_3_count.png, zqa_c80_3840x2160_4_stirfry_full.png, zqa_c80_3840x2160_4_by_kind.png, zqa_c80_3840x2160_5_dish_list.png, zqa_c80_3840x2160_5_use_instead.png, zqa_c80_3840x2160_5_not_in_reach.png, zqa_c80_3840x2160_6_by_kind_pad.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 21298 at 16:59:43

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 21299 at 16:59:49

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. suite_tabs.lua (`ZEDQA tabs`) - PASS, 14 s

- go 21300 at 16:59:53

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals
ZEDQA tabs armed
[ZeD.QA] run #3 ok=true
ZEDQA char tab=loot active=loot w=777 focusables=0 {}
ZEDQA char tab=equip active=equip w=1617 focusables=33 {el=1 equipbelt=1 equipgroup=5 equippart=17 equipslot=7 equipview=2}
ZEDQA char tab=health active=health w=1617 focusables=22 {bodypart=17 health=5}
ZEDQA char tab=thermal active=thermal w=1617 focusables=20 {thermal=3 thermalpart=17}
ZEDQA char tab=identity active=identity w=1617 focusables=15 {hb=4 identity=11}
ZEDQA char tab=journal active=journal w=1617 focusables=4 {journal=3 jpage=1}
ZEDQA char tab=skills active=skills w=1617 focusables=60 {skill=35 skills=1 training=24}
ZEDQA world tab=loot active=loot w=777 focusables=0 {}
ZEDQA world tab=craft active=craft w=1617 focusables=8 {craft=8}
ZEDQA world tab=build active=build w=1617 focusables=4 {build=4}
ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
ZEDQA world tab=maps active=maps w=1617 focusables=19 {map=19}
ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
ZEDQA tabs done
```

### 4. suite_verbs.lua (`ZEDQA verbs`) - PASS, 19 s

- go 21301 at 17:00:10

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA verbs armed
[ZeD.QA] run #4 ok=true
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

### 5. suite_gamepad.lua (`ZEDQA gp`) - PASS, 8 s

- go 21302 at 17:00:33

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gp armed
[ZeD.QA] run #5 ok=true
ZEDQA gp claim zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp down zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false
ZEDQA gp right zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp left zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false
ZEDQA gp loot charTabContent elements=0 (expect 0)
ZEDQA gp right after journal to loot (expect container strip, never jsub) zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp after row2 onActivate (expect card open) zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp after row3 onActivate (expect live swap) zone=charItemCard el=hverb_1 tab=loot drawer=true item=Baseball Bat ctx=false
ZEDQA gp after row3 again (expect closed) zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp after row2 onContextMenu (expect ctx=true) zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=true
ZEDQA gp after ctx B (expect ctx=false) zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp world claim zone=worldMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp world right zone=worldTabBar el=tab:loot tab=loot drawer=false item=nil ctx=false
ZEDQA gp world craft down zone=worldTabBar el=tab:craft tab=craft drawer=true item=nil ctx=false
ZEDQA gp world loot left (stale check) zone=worldMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp done
```

### 6. suite_band.lua (`ZEDQA band`) - PASS, 3 s

- go 21303 at 17:00:44

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA band armed
[ZeD.QA] run #6 ok=true
ZEDQA band reading active=true kind=reading mode=nil label=Reading pct=0 time=nil (expect active reading)
ZEDQA band after cancel active=true kind=reading mode=nil label=Reading pct=0 time=nil qlen=0 (expect inactive, 0)
ZEDQA band: no real stove within 20 tiles; cooking skipped
ZEDQA band done
```

### 7. suite_perf.lua (`ZEDQA perf`) - PASS, 40 s

- go 21304 at 17:00:50

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #7 ok=true
ZEDQA perf char loot avg=11.08ms/tick max=21ms
ZEDQA perf char equip avg=17.77ms/tick max=26ms
ZEDQA perf char health avg=15.66ms/tick max=24ms
ZEDQA perf char thermal avg=16.87ms/tick max=24ms
ZEDQA perf char identity avg=16.54ms/tick max=27ms
ZEDQA perf char journal avg=12.14ms/tick max=27ms
ZEDQA perf char skills avg=17.22ms/tick max=45ms
ZEDQA perf world craft avg=14.09ms/tick max=32ms
ZEDQA perf world build avg=11.95ms/tick max=22ms
ZEDQA perf world maps avg=13.06ms/tick max=22ms
ZEDQA perf world forage avg=15.58ms/tick max=24ms
ZEDQA perf world animals avg=11.90ms/tick max=20ms
ZEDQA perf world loot avg=10.43ms/tick max=25ms
ZEDQA perf world craft build: 8 elements, 0.00 ms per build
ZEDQA perf done
```

### 8. zedqa_audit_fixes.lua (`ZEDQA af`) - PASS, 5 s

- go 21305 at 17:01:33
- 58 expected exception(s) ignored (expect=)

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA af start
[ZeD.QA] run #8 ok=true
ERROR: General f:8795> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8796> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8797> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8798> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8799> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8800> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8801> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8802> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8803> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8804> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8805> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8806> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8807> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8808> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8809> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8810> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8811> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8812> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8813> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8814> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8815> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8816> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8817> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8818> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8819> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8820> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8821> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8822> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8824> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8825> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8826> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8827> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8829> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8830> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8831> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8832> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8833> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8834> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8835> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8836> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8837> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8838> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8839> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8840> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8841> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8842> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8843> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8844> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8845> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8846> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8847> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8848> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8849> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8850> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8851> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8852> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4889)
    Lua((MOD:ZeD-GUI)).pcall(QABridge.lua:37)
ERROR: General f:8853> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1380)
... (18 more lines; see console.txt)
```

### 9. zedqa_card_pad.lua (`ZEDQA cp`) - PASS, 5 s

- go 21306 at 17:01:42
- screenshots: zqa_cp_card.png

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cp start
[ZeD.QA] run #9 ok=true
ZEDQA cp selected the apple row 24
ZEDQA cp card open true | card buttons 7 {hverb_1,hverb_2,name_row,toggle_fav,toggle_protect,toggle_unwanted,toggle_lists}
ZEDQA cp fav chip rect on the card (mouse): true
ZEDQA cp before left: zone=charItemCard el=hverb_1
ZEDQA cp after left (expect charItemCard): zone=charTabBar el=tab:loot
ZEDQA cp right 1: zone=charItemCard el=hverb_1
ZEDQA cp right 2: zone=charItemCard el=hverb_2
ZEDQA cp left: zone=charItemCard el=hverb_1
ZEDQA cp after B: card item nil (expect nil)
ZEDQA cp health: inv then left (expect charTabContent): zone=charTabContent el=health:__disclosure
ZEDQA cp health: right: zone=charMainInv el=invrow:1
ZEDQA cp DONE
```

### 10. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 5 s

- go 21307 at 17:01:50
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #10 ok=true
ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Set Unwanted, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Save to loadout, |, Rename
ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
ZEDQA cl down: sub sel 2
ZEDQA cl B: levels 1
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

### 11. zedqa_ctx_icons.lua (`ZEDQA cx`) - PASS, 23 s

- go 21308 at 17:01:59
- screenshots: zqa_cx_grid.png, zqa_cx_strip_apple.png, zqa_cx_strip_pistol.png, zqa_cx_strip_bandage.png, zqa_cx_strip_hammer.png, zqa_cx_strip_floor.png, zqa_cx_list_apple.png, zqa_cx_list_pistol.png, zqa_cx_list_bandage.png, zqa_cx_list_hammer.png, zqa_cx_list_floor.png

```text
[ZeD.QA] state #11 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
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
[ZeD.QA] run #11 ok=true
ZEDQA cx drawings not ready yet: 261
ZEDQA cx drawings not ready after 67 frames: 0
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
ZEDQA cx strip floor: ZeD_ContextMenu | pixel 4, licensed 0, item pictures 0, none 0
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
ZEDQA cx list floor: ZeD_ContextList | pixel 4, licensed 0, item pictures 0, none 0
ZEDQA cx ok list floor opened with pixel icons
ZEDQA cx ok list floor: no licensed picture left
ZEDQA cx shot zqa_cx_list_floor
ZEDQA cx DONE 0 failed
```

### 12. zedqa_onepath.lua (`ZEDQA op`) - PASS, 23 s

- go 21309 at 17:02:25
- screenshots: zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png

```text
[ZeD.QA] state #12 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA op start
[ZeD.QA] run #12 ok=true
ZEDQA op crate ItemContainer:[type:crate, parent:null:carpentry_01_16:carpentry_01_16:zombie.iso.IsoObject@39fa5b30] type crate
ZEDQA op world select crate true
ZEDQA op apple menu: Eat, |, Place Item, Favorite, Set Unwanted, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Save to loadout, |, Rename
ZEDQA op move to: Crate, Floor
ZEDQA op picked Crate
ZEDQA op apple now in crate
ZEDQA op hammer menu: Attach, Dismantle Bladed Item, Place Item, Put in Container (Crate), Favorite, Set Unwanted, Move to, Pin to title bar, |, Craft, Set to be Unusable in Recipes, Show Build Recipes Used In, |, Equip Primary, Equip Secondary, |, Drop, |, Save to loadout, |, Rename
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

### 13. zedqa_grid.lua (`ZEDQA grid`) - PASS, 7 s

- go 21310 at 17:02:52
- screenshots: zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png

```text
[ZeD.QA] state #13 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA grid start
[ZeD.QA] run #13 ok=true
ZEDQA grid grid on: cell 91 | cells placed 16 | toggle rects 2
ZEDQA grid first target: invrow:1 at 18,107 size 91x91
ZEDQA grid first cell: zone=charMainInv el=invrow:1 item=Apple (Fresh)
ZEDQA grid right (expect the next cell): zone=charMainInv el=invrow:2 item=Baseball Bat
ZEDQA grid down (expect the cell below): zone=charMainInv el=invrow:24 item=Digital Watch
ZEDQA grid up: zone=charMainInv el=invrow:2 item=Baseball Bat
ZEDQA grid up again (expect the toggle): zone=charMainInv el=view:list:player item=nil
ZEDQA grid card open true item Baseball Bat
ZEDQA grid after A on List: grid false cell nil
ZEDQA grid DONE
```

### 14. zedqa_sort_groups.lua (`ZEDQA sg`) - PASS, 52 s

- go 21311 at 17:03:02
- screenshots: zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png

```text
[ZeD.QA] state #14 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sg start
[ZeD.QA] run #14 ok=true
ZEDQA sg pack worn at base:back: true
ZEDQA sg given: bag 23, pack 8, bed 19, floor 11
ZEDQA sg floor container things 56 | char window true world window true
ZEDQA sg columns at start: char 0 world 0
ZEDQA sg mode single:
ZEDQA sg single list cat char: columns 1 rows 31 headers 6 order ok pad 31 (charMainInv=31) grid false sort cat/true
ZEDQA sg single list cat world: columns 1 rows 16 headers 5 order ok pad 16 (worldMainInv=16) grid false sort cat/true
ZEDQA sg single list name char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort name/true
ZEDQA sg single list name world: columns 1 rows 16 headers 0 order ok pad 16 (worldMainInv=16) grid false sort name/true
ZEDQA sg single list cond char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort cond/true
ZEDQA sg single list cond world: columns 1 rows 16 headers 0 order ok pad 16 (worldMainInv=16) grid false sort cond/true
ZEDQA sg single list wt char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort wt/true
ZEDQA sg single list wt world: columns 1 rows 16 headers 0 order ok pad 16 (worldMainInv=16) grid false sort wt/true
ZEDQA sg single list name rev char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort name/false
ZEDQA sg single list name rev world: columns 1 rows 16 headers 0 order ok pad 16 (worldMainInv=16) grid false sort name/false
ZEDQA sg fold char: Accessory folded, rows 29 of 31, its header true
ZEDQA sg fold world: Bag folded, rows 15 of 16, its header true
ZEDQA sg fold char on Name: rows 31 headers 0
ZEDQA sg fold world on Name: rows 16 headers 0
ZEDQA sg fold char back on Category: still folded true rows 29
ZEDQA sg fold world back on Category: still folded true rows 15
ZEDQA sg stack char: Base.Apple x23 open, rows 53 of 31 (+22 expected), children follow true, headers 0
ZEDQA sg stack world: Base.Apple x2 open, rows 17 of 16 (+1 expected), children follow true, headers 0
ZEDQA sg single grid cat char: columns 1 rows 31 headers 5 order ok pad 31 (charMainInv=31) grid true sort cat/true
ZEDQA sg single grid cat world: columns 1 rows 16 headers 5 order ok pad 16 (worldMainInv=16) grid true sort cat/true
ZEDQA sg single grid name char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort name/true
ZEDQA sg single grid name world: columns 1 rows 16 headers 0 order ok pad 16 (worldMainInv=16) grid true sort name/true
ZEDQA sg single grid cond char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort cond/true
ZEDQA sg single grid cond world: columns 1 rows 16 headers 0 order ok pad 16 (worldMainInv=16) grid true sort cond/true
ZEDQA sg single grid wt char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort wt/true
ZEDQA sg single grid wt world: columns 1 rows 16 headers 0 order ok pad 16 (worldMainInv=16) grid true sort wt/true
ZEDQA sg single grid name rev char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort name/false
ZEDQA sg single grid name rev world: columns 1 rows 16 headers 0 order ok pad 16 (worldMainInv=16) grid true sort name/false
ZEDQA sg mode multi: char:true world:true
ZEDQA sg multi list cat char: columns 2 rows 8+31 headers 12 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort cat/true
ZEDQA sg multi list cat world: columns 2 rows 14+16 headers 9 order ok pad 30 (worldMC1=14,worldMainInv=16) grid false sort cat/true
ZEDQA sg multi list name char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort name/true
ZEDQA sg multi list name world: columns 2 rows 14+16 headers 0 order ok pad 30 (worldMC1=14,worldMainInv=16) grid false sort name/true
ZEDQA sg multi list cond char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort cond/true
ZEDQA sg multi list cond world: columns 2 rows 14+16 headers 0 order ok pad 30 (worldMC1=14,worldMainInv=16) grid false sort cond/true
ZEDQA sg multi list wt char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort wt/true
ZEDQA sg multi list wt world: columns 2 rows 14+16 headers 0 order ok pad 30 (worldMC1=14,worldMainInv=16) grid false sort wt/true
ZEDQA sg multi list name rev char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort name/false
ZEDQA sg multi list name rev world: columns 2 rows 14+16 headers 0 order ok pad 30 (worldMC1=14,worldMainInv=16) grid false sort name/false
ZEDQA sg multi grid cat char: columns 2 rows 8+31 headers 10 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort cat/true
ZEDQA sg multi grid cat world: columns 2 rows 14+16 headers 10 order ok pad 30 (worldMC1=14,worldMainInv=16) grid true sort cat/true
ZEDQA sg multi grid name char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort name/true
ZEDQA sg multi grid name world: columns 2 rows 14+16 headers 0 order ok pad 30 (worldMC1=14,worldMainInv=16) grid true sort name/true
ZEDQA sg multi grid cond char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort cond/true
ZEDQA sg multi grid cond world: columns 2 rows 14+16 headers 0 order ok pad 30 (worldMC1=14,worldMainInv=16) grid true sort cond/true
ZEDQA sg multi grid wt char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort wt/true
ZEDQA sg multi grid wt world: columns 2 rows 14+16 headers 0 order ok pad 30 (worldMC1=14,worldMainInv=16) grid true sort wt/true
ZEDQA sg multi grid name rev char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort name/false
ZEDQA sg multi grid name rev world: columns 2 rows 14+16 headers 0 order ok pad 30 (worldMC1=14,worldMainInv=16) grid true sort name/false
ZEDQA sg columns off: char:true world:true
ZEDQA sg restored: bag things 109 (were 109), bed 2, world things on the square 1, floor container 45
ZEDQA sg all checks held; DONE
```

### 15. zedqa_wt_bracket.lua (`ZEDQA wtb`) - PASS, 23 s

- go 21312 at 17:03:58
- screenshots: zqa_wtb_small_list.png, zqa_wtb_open_stack.png, zqa_wtb_narrow_wt.png, zqa_wtb_small_grid.png, zqa_wtb_large_list.png, zqa_wtb_large_grid.png, zqa_wtb_two_columns.png, zqa_wtb_two_columns_large.png

```text
[ZeD.QA] state #15 speed=1 paused=false player=869,13025 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wtb start
[ZeD.QA] run #15 ok=true
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
ZEDQA wtb small grid char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)") at x 272..300 of 305, name ends nil, columns 1
ZEDQA wtb small grid world stack Apple (Stale) x5: drew "(1.0)" (expect "(1.0)") at x 76..104 of 109, name ends nil, columns 1
ZEDQA wtb small grid char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb small grid world single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb large list char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)") at x 502..565 of 633, name ends 284, columns 1
ZEDQA wtb large list char headers: cat true, cond false
ZEDQA wtb large list world stack Apple (Stale) x5: drew "(1.0)" (expect "(1.0)") at x 502..565 of 633, name ends 290, columns 1
ZEDQA wtb large list world headers: cat true, cond false
ZEDQA wtb large list char single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb large list world single Empty Saucepan: drew "0.7" (expect "0.7")
ZEDQA wtb large grid char stack Orange (Fresh) x5: drew "(1.0)" (expect "(1.0)" or "(1)" / "0.2") at x 537..571 of 577, name ends nil, columns 1
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

### 16. zedqa_doll.lua (`ZEDQA doll`) - PASS, 11 s

- go 21313 at 17:04:24
- screenshots: zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png

```text
[ZeD.QA] state #16 speed=1 paused=false player=869,13025 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA doll start
[ZeD.QA] run #16 ok=true
ZEDQA doll doll shown true | slots 7 {doll:torso,doll:outer,doll:hands,doll:belt,doll:legs,doll:feet,doll:belt1} | belt empties 2 | photo 376,74 168x643 | lines 0 | model visible true | layer visible true
ZEDQA doll pad targets: equipslot:__disclosure,equipview:list,equipview:doll,equipslot:doll:torso,equipslot:doll:outer,equipslot:doll:hands,equipslot:doll:belt,equipslot:doll:legs,equipslot:doll:feet,equipslot:doll:belt1,equipbelt:2,equipbelt:3,equipslot:doll:head,equipslot:doll:eyes,equipslot:doll:neck,equipslot:doll:back,equipslot:doll:arms,equipslot:doll:ears,equipslot:doll:eartop,equipslot:doll:nose,equipslot:doll:necklace,equipslot:doll:necklacelong,equipslot:doll:gorget,equipslot:doll:padl,equipslot:doll:padr,equipslot:doll:padsport,equipslot:doll:elbowl,equipslot:doll:elbowr,equipslot:doll:wristl,equipslot:doll:wristr,equipslot:doll:forearml,equipslot:doll:forearmr,equipslot:doll:belly,equipslot:doll:holster,equipslot:doll:lmiddle,equipslot:doll:lring,equipslot:doll:rmiddle,equipslot:doll:rring,equipslot:doll:satchel,equipslot:doll:airtank,equipslot:doll:tail,equipslot:doll:fpfront,equipslot:doll:fpback,equipslot:doll:webbing,equipslot:doll:ammo,equipslot:doll:beltholster,equipslot:doll:kneel,equipslot:doll:kneer,equipslot:doll:thighl,equipslot:doll:thighr,equipslot:doll:shinl,equipslot:doll:shinr,equipslot:doll:gaiterl,equipslot:doll:gaiterr,equipslot:doll:ankleholster,equipslot:doll:main,equipslot:doll:off,el:fold
ZEDQA doll focus torso: zone=charTabContent el=equipslot:doll:torso sel=nil layer=1
ZEDQA doll card targets: equipcard:hverb_1,equipcard:hverb_2,equipcard:hverb_3,equipcard:name_row,equipcard:more_row,equipcard:toggle_fav,equipcard:toggle_protect,equipcard:toggle_unwanted,equipcard:toggle_lists,equipcard:back,equipcard:__layer_1,equipcard:__layer_-1
ZEDQA doll card open: zone=charTabContent el=equipcard:hverb_1 sel=doll:torso layer=1
ZEDQA doll focus Inner: zone=charTabContent el=equipcard:__layer_1 sel=doll:torso layer=1
ZEDQA doll after Inner (expect layer 2): zone=charTabContent el=equipcard:__layer_1 sel=doll:torso layer=2
ZEDQA doll after B (expect sel=nil, el=equipslot:doll:torso): zone=charTabContent el=equipslot:doll:torso sel=nil layer=1
ZEDQA doll head then down: zone=charTabContent el=equipslot:doll:neck sel=nil layer=1
ZEDQA doll then right (expect back): zone=charTabContent el=equipslot:doll:arms sel=nil layer=1
ZEDQA doll then down (expect belt): zone=charTabContent el=equipslot:doll:outer sel=nil layer=1
ZEDQA doll then left (expect neck): zone=charTabContent el=equipslot:doll:torso sel=nil layer=1
ZEDQA doll then left (into the left band when the bands show, else leaves the doll): zone=charTabContent el=equipslot:doll:forearmr sel=nil layer=1
ZEDQA doll view restored to list | DONE
```

### 17. zedqa_doll_v4.lua (`ZEDQA dollv4`) - PASS, 36 s

- go 21314 at 17:04:39
- screenshots: zqa_dollv4_3840x2160_wide.png, zqa_dollv4_3840x2160_dpad.png, zqa_dollv4_3840x2160_wide_pads.png, zqa_dollv4_3840x2160_card.png, zqa_dollv4_3840x2160_narrow.png, zqa_dollv4_3840x2160_short.png

```text
[ZeD.QA] state #17 speed=1 paused=false player=869,13025 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA dollv4 start
[ZeD.QA] run #17 ok=true
ZEDQA dollv4 round 1: wearing 21 of 21
ZEDQA dollv4 PASS 38 small slots defined | 38
ZEDQA dollv4 PASS wide: bands show | drawer 840px = 480 units, screen 3840x2160
ZEDQA dollv4 PASS wide: 49 slot boxes (11 big + 38 small) | 49
ZEDQA dollv4 PASS wide: no slot overlaps another
ZEDQA dollv4 PASS wide: every box inside the drawer's width | 840
ZEDQA dollv4 PASS wide: the drawer is no wider than the full card (480 units) | 480.0 units
ZEDQA dollv4 PASS wide: a small slot is 14 units or more on screen | 14.3 units
ZEDQA dollv4 PASS wide: no leader lines | 0 lines
ZEDQA dollv4 PASS wide: Back at the top right above Belt, Arms on the left with Head | 588,85 267 588,386
ZEDQA dollv4 PASS every group name and place name has its words |
ZEDQA dollv4 PASS round 1 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS round 1 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 1 folded (data): every worn thing lands in its big slot (21 on) |
ZEDQA dollv4 PASS belly button ring, air tank, tail in their small slots
ZEDQA dollv4 empties 25, slots with things 27
ZEDQA dollv4 PASS charTabContent zone exists with the doll's stops | 78
ZEDQA dollv4 PASS Left from Neck steps into the left band | doll:padsport
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
ZEDQA dollv4 PASS a cap dropped on Head is taken | rect 161,65 64x64 clip 0,65 815x585 | loc base:hat
ZEDQA dollv4 PASS a cap dropped on a small slot that is not its place is refused
ZEDQA dollv4 PASS a ring dropped on the wrong small slot is refused
ZEDQA dollv4 PASS a ring dropped on its slot is taken | rect 2,571 25x25 clip 0,65 815x585
ZEDQA dollv4 PASS the ring was put on (vanilla's wear action ran)
ZEDQA dollv4 PASS the cap was put on
ZEDQA dollv4 PASS narrow: bands folded | drawer 385px = 220 units, screen 3840x2160
ZEDQA dollv4 PASS narrow: 11 big slot boxes, no small ones | 11
ZEDQA dollv4 PASS narrow: no slot overlaps another
ZEDQA dollv4 PASS narrow: every box inside the drawer's width | 385
ZEDQA dollv4 PASS narrow: the drawer is no wider than the full card (480 units) | 220.0 units
ZEDQA dollv4 PASS narrow: no leader lines | 0 lines
ZEDQA dollv4 PASS narrow: Back, Arms, Belt in that order down the right | 65,247,338
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
ZEDQA dollv4 passed 62, failed 0 | DONE
```

### 18. zedqa_large.lua (`ZEDQA lg`) - PASS, 10 s

- go 21315 at 17:05:18
- screenshots: zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png

```text
[ZeD.QA] state #18 speed=1 paused=false player=869,13025 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA lg start
[ZeD.QA] run #18 ok=true
ZEDQA lg small: rowH 53 buttonH 46 titleBarH 46 | cat 151 wt 101 | equip slot col 140
ZEDQA lg large: rowH 60 buttonH 53 titleBarH 53 | cat 176 wt 117 | equip slot col 163
ZEDQA lg size back to small | DONE
```

### 19. zedqa_segbars.lua (`ZEDQA segb`) - PASS, 1 s

- go 21316 at 17:05:31

```text
[ZeD.QA] state #19 speed=1 paused=false player=869,13025 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA segb 0.640 -> 6 lit, 4 dark
ZEDQA segb 0.040 -> 0 lit, 10 dark
ZEDQA segb 1.000 -> 10 lit, 0 dark
ZEDQA segb 0.000 -> 0 lit, 10 dark
ZEDQA segb 0.700 -> 7 lit, 3 dark
ZEDQA segb 0.300 -> 3 lit, 7 dark
ZEDQA segb 0.999 -> 9 lit, 1 dark
ZEDQA segb narrowest 42 px (scale 1.75): 10 cells, 2 to 2 px wide
ZEDQA segb skill help: Fitness 5, 40% to level 6 | Fitness 10
ZEDQA segb hover checks skipped: the controller's cues are showing
[ZeD.QA] run #19 ok=true
ZEDQA segb PASS
ZEDQA segb DONE
```

### 20. zedqa_curtain.lua (`ZEDQA cu`) - PASS, 220 s

- go 21317 at 17:05:35
- screenshots: zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png

```text
[ZeD.QA] state #20 speed=1 paused=false player=869,13025 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cu start
[ZeD.QA] run #20 ok=true
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

### 21. zedqa_curtain2.lua (`ZEDQA cv`) - PASS, 15 s

- go 21318 at 17:09:19
- screenshots: zqa_cv_1.png, zqa_cv_2.png, zqa_cv_3.png

```text
[ZeD.QA] state #21 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cv start
[ZeD.QA] run #21 ok=true
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

### 22. zedqa_navevents.lua (`ZEDQA ev`) - PASS, 7 s

- go 21319 at 17:09:37

```text
[ZeD.QA] state #22 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ev start
[ZeD.QA] run #22 ok=true
ZEDQA ev 1 on the hammer row: Char charMainInv:invrow:8 (Claw Hammer)
ZEDQA ev 1 after A (expect the card's primary action): Char charItemCard:hverb_1
ZEDQA ev 1 after B (expect back on the hammer row): Char charMainInv:invrow:8 (Claw Hammer)
ZEDQA ev 2 Right (expect the strip): Char charContainerStrip:container:1
ZEDQA ev 2 Left (expect back on the hammer row): Char charMainInv:invrow:8 (Claw Hammer)
ZEDQA ev 3 on the screwdriver: Char charMainInv:invrow:17 (Screwdriver)
ZEDQA ev 3 Left (expect the active tab): Char charTabBar:tab:loot
ZEDQA ev 3 Down: Char charTabBar:tab:equip
ZEDQA ev 3 A on: Char charTabBar:tab:equip
ZEDQA ev 3 after A on the tab (expect still on it): Char charTabBar:tab:equip
ZEDQA ev 3 Right (expect the tab's first control): Char charTabContent:equipgroup:head
ZEDQA ev 3 Left (expect back on the tab): Char charTabBar:tab:equip
ZEDQA ev 4 on the screwdriver: Char charMainInv:invrow:17 (Screwdriver)
ZEDQA ev 4 after RB (World): World worldMainInv:invrow:1 (Military Backpack)
ZEDQA ev 4 after LB (expect back on the screwdriver): Char charMainInv:invrow:17 (Screwdriver)
ZEDQA ev 5 on the hammer: Char charMainInv:invrow:8 (Claw Hammer)
ZEDQA ev 5 after the hammer went (expect a neighbouring row): Char charMainInv:invrow:8 (Digital Watch)
ZEDQA ev 6 on the star tool: World worldTabContent:map:tool:star
ZEDQA ev 6 Down (expect the map): World worldTabContent:map:canvas:cursor
ZEDQA ev 6 Up (expect back on the star tool): World worldTabContent:map:tool:star
ZEDQA ev 6 Down, Left: World worldMainInv:invrow:1 (Military Backpack)
ZEDQA ev 6 Right (expect back on the map): World worldTabContent:map:canvas:cursor
ZEDQA ev 6 Right again: World worldTabBar:tab:maps
ZEDQA ev 7 on unfold: World worldTabContent:map:popout
ZEDQA ev 7 after unfold (expect the big map's window): Map popMapContent:map:canvas:cursor
ZEDQA ev 7 after B (expect the World window's map or unfold): World worldTabContent:map:popout
ZEDQA ev DONE
```

### 23. zedqa_navmap.lua (`ZEDQA nav`) - PASS, 15 s

- go 21320 at 17:09:48

```text
[ZeD.QA] state #23 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA nav start
[ZeD.QA] run #23 ok=true
ZEDQA nav char loot: 29 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char loot STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) invrow:1(U) invrow:16(D) container:1(UD)
ZEDQA nav char loot charTabBar:tab:loot U>- D>tab:equip L>- R>charMainInv:invrow:8
ZEDQA nav char loot charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charMainInv:invrow:8
ZEDQA nav char loot charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charMainInv:invrow:8
ZEDQA nav char loot charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charMainInv:invrow:8
ZEDQA nav char loot charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charMainInv:invrow:8
ZEDQA nav char loot charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charMainInv:invrow:8
ZEDQA nav char loot charTabBar:tab:skills U>tab:journal D>- L>- R>charMainInv:invrow:8
ZEDQA nav char loot charMainInv:invrow:1 U>- D>invrow:2 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabBar:tab:loot R>view:list:player
ZEDQA nav char loot charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabBar:tab:loot R>view:list:player
ZEDQA nav char loot charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:12 U>invrow:11 D>invrow:13 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:13 U>invrow:12 D>invrow:14 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:14 U>invrow:13 D>invrow:15 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:15 U>invrow:14 D>invrow:16 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:16 U>invrow:15 D>- L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:view:list:player U>invrow:4~ D>invrow:5~ L>invrow:5 R>view:grid:player
ZEDQA nav char loot charMainInv:view:grid:player U>invrow:4~ D>invrow:5~ L>view:list:player R>charContainerStrip:container:1
ZEDQA nav char loot charContainerStrip:container:1 U>- D>- L>charMainInv:view:grid:player R>window:World
ZEDQA nav char loot charCtl:charCtl:xfer U>charMainInv:invrow:15 D>charMainInv:invrow:16 L>charTabBar:tab:loot~ R>charMainInv:invrow:16
ZEDQA nav char loot charCtl:charCtl:same U>charMainInv:invrow:15 D>charMainInv:invrow:16 L>charCtl:xfer R>charMainInv:invrow:16
ZEDQA nav char loot charCtl:charCtl:near U>charMainInv:invrow:15 D>charMainInv:invrow:16 L>charCtl:same R>charMainInv:invrow:16
ZEDQA nav char equip: 62 targets | TRAP 6 {equipslot:INR,equipslot:GLV,equipslot:PNT,equipslot:SOC,equipslot:BOT,equipslot:BLT} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char equip STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) equipslot:__disclosure(U) equipview:list(U) equipview:doll(U) equippart:Right Foot(D) equippart:Left Foot(D) invrow:1(U) invrow:16(D) container:1(UD)
ZEDQA nav char equip charTabBar:tab:loot U>- D>tab:equip L>- R>charTabContent:equipslot:__disclosure
ZEDQA nav char equip charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charTabContent:equipgroup:head
ZEDQA nav char equip charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charTabContent:equipgroup:torso
ZEDQA nav char equip charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charTabContent:equipgroup:arms
ZEDQA nav char equip charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charTabContent:equipgroup:legs
ZEDQA nav char equip charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charTabContent:equipslot:PNT
ZEDQA nav char equip charTabBar:tab:skills U>tab:journal D>- L>- R>charTabContent:equipslot:SOC
ZEDQA nav char equip charTabContent:equipslot:__disclosure U>- D>equipgroup:head L>charTabBar:tab:equip R>equipview:list
ZEDQA nav char equip charTabContent:equipview:list U>- D>equipgroup:head L>equipslot:__disclosure R>equipview:doll
ZEDQA nav char equip charTabContent:equipview:doll U>- D>equipgroup:head L>equipslot:__disclosure R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equippart:Head U>el:fold D>equippart:Neck L>equippart:Neck R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equippart:Neck U>equippart:Head D>equippart:Upper Torso L>charTabBar:tab:equip~ R>equippart:Head
ZEDQA nav char equip charTabContent:equippart:Upper Torso U>equippart:Neck D>equippart:Lower Torso L>equippart:Right Upper Arm R>equippart:Left Upper Arm
ZEDQA nav char equip charTabContent:equippart:Right Upper Arm U>equippart:Upper Torso D>equippart:Right Forearm L>equippart:Right Forearm R>equippart:Upper Torso
ZEDQA nav char equip charTabContent:equippart:Left Upper Arm U>equippart:Upper Torso D>equippart:Left Forearm L>equippart:Upper Torso R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Lower Torso U>equippart:Upper Torso D>equippart:Groin L>equippart:Right Upper Arm R>equippart:Groin
ZEDQA nav char equip charTabContent:equippart:Right Forearm U>equippart:Right Upper Arm D>equippart:Right Hand L>equippart:Right Hand R>equippart:Right Upper Leg
ZEDQA nav char equip charTabContent:equippart:Left Forearm U>equippart:Left Upper Arm D>equippart:Left Hand L>equippart:Groin R>equippart:Left Hand
ZEDQA nav char equip charTabContent:equippart:Groin U>equippart:Lower Torso D>equippart:Right Upper Leg L>equippart:Lower Torso R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Right Hand U>equippart:Right Forearm D>equippart:Right Upper Leg~ L>charTabBar:tab:equip~ R>equippart:Right Forearm
ZEDQA nav char equip charTabContent:equippart:Left Hand U>equippart:Left Forearm D>equippart:Left Upper Leg~ L>equippart:Left Forearm R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equippart:Right Upper Leg U>equippart:Groin D>equippart:Right Lower Leg L>equippart:Right Forearm R>equippart:Groin
ZEDQA nav char equip charTabContent:equippart:Left Upper Leg U>equippart:Groin D>equippart:Left Lower Leg L>equippart:Groin R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Right Lower Leg U>equippart:Right Upper Leg D>equippart:Right Foot L>equippart:Right Foot R>equippart:Right Upper Leg
ZEDQA nav char equip charTabContent:equippart:Left Lower Leg U>equippart:Left Upper Leg D>equippart:Left Foot L>equippart:Left Upper Leg R>equippart:Left Foot
ZEDQA nav char equip charTabContent:equippart:Right Foot U>equippart:Right Lower Leg D>- L>charTabBar:tab:equip~ R>equippart:Right Lower Leg
ZEDQA nav char equip charTabContent:equippart:Left Foot U>equippart:Left Lower Leg D>- L>equippart:Left Lower Leg R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipgroup:head U>equipslot:__disclosure D>equipgroup:torso L>charTabBar:tab:equip R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipgroup:torso U>equipgroup:head D>equipslot:INR L>charTabBar:tab:equip R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipgroup:arms U>equipslot:INR D>equipslot:GLV L>charTabBar:tab:equip R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipgroup:legs U>equipslot:GLV D>equipslot:PNT L>charTabBar:tab:equip R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipgroup:held U>equipslot:BOT D>equipslot:BLT L>charTabBar:tab:equip~ R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipslot:INR [OWN D-PAD] U>equipgroup:torso D>equipgroup:arms L>charTabBar:tab:equip R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipslot:GLV [OWN D-PAD] U>equipgroup:arms D>equipgroup:legs L>charTabBar:tab:equip R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipslot:PNT [OWN D-PAD] U>equipgroup:legs D>equipslot:SOC L>charTabBar:tab:equip R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipslot:SOC [OWN D-PAD] U>equipslot:PNT D>equipslot:BOT L>charTabBar:tab:equip R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipslot:BOT [OWN D-PAD] U>equipslot:SOC D>equipgroup:held L>charTabBar:tab:equip R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipslot:BLT [OWN D-PAD] U>equipgroup:held D>equipbelt:1 L>charTabBar:tab:equip~ R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:equipbelt:1 U>equipslot:BLT D>el:fold L>charTabBar:tab:equip~ R>charMainInv:invrow:8
ZEDQA nav char equip charTabContent:el:fold U>equipbelt:1 D>equippart:Head L>charTabBar:tab:equip~ R>charMainInv:invrow:8
ZEDQA nav char equip charMainInv:invrow:1 U>- D>invrow:2 L>charTabContent:equipslot:__disclosure~ R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabContent:equipslot:__disclosure~ R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabContent:equipslot:__disclosure~ R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabContent:equipslot:__disclosure R>view:list:player
ZEDQA nav char equip charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabContent:equipslot:__disclosure R>view:list:player
ZEDQA nav char equip charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabContent:equipgroup:head R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabContent:equipgroup:torso R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabContent:equipgroup:arms R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabContent:equipslot:GLV R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charTabContent:equipslot:PNT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charTabContent:equipslot:SOC R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:12 U>invrow:11 D>invrow:13 L>charTabContent:equipslot:BOT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:13 U>invrow:12 D>invrow:14 L>charTabContent:equipgroup:held R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:14 U>invrow:13 D>invrow:15 L>charTabContent:equipslot:BLT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:15 U>invrow:14 D>invrow:16 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:16 U>invrow:15 D>- L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:view:list:player U>invrow:4~ D>invrow:5~ L>invrow:5 R>view:grid:player
ZEDQA nav char equip charMainInv:view:grid:player U>invrow:4~ D>invrow:5~ L>view:list:player R>charContainerStrip:container:1
ZEDQA nav char equip charContainerStrip:container:1 U>- D>- L>charMainInv:view:grid:player R>window:World
ZEDQA nav char equip charCtl:charCtl:xfer U>charMainInv:invrow:15 D>charMainInv:invrow:16 L>charTabContent:equipbelt:1 R>charMainInv:invrow:16
ZEDQA nav char equip charCtl:charCtl:same U>charMainInv:invrow:15 D>charMainInv:invrow:16 L>charCtl:xfer R>charMainInv:invrow:16
ZEDQA nav char equip charCtl:charCtl:near U>charMainInv:invrow:15 D>charMainInv:invrow:16 L>charCtl:same R>charMainInv:invrow:16
ZEDQA nav char health: 51 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char health STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) health:__disclosure(U) health:exercise(D) health:time:dec(D) health:time:inc(D) health:start(D) invrow:1(U) invrow:16(D) container:1(UD)
ZEDQA nav char thermal: 49 targets | TRAP 1 {thermal:__gridscroll} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char thermal STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) thermal:__disclosure(U) thermal:view(D) invrow:1(U) invrow:16(D) container:1(UD)
ZEDQA nav char identity: 44 targets | TRAP 1 {hb:part} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char identity STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) identity:__disclosure(U) identity:trait:Smoker(D) invrow:1(U) invrow:16(D) container:1(UD)
ZEDQA nav char journal: 33 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char journal STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) jpage(U) journal:__save(D) invrow:1(U) invrow:16(D) container:1(UD)
ZEDQA nav char skills: 89 targets | TRAP 35 {skill:Aiming,skill:Reloading,skill:Blacksmithing,skill:Carpentry,skill:Carving,skill:Cooking,skill:Electrical,skill:Glassmaking,skill:Knapping,skill:Masonry,skill:Mechanics,skill:Pottery,skill:Tailoring,skill:Welding,skill:First Aid,skill:Fishing,skill:Foraging,skill:Tracking,skill:Trapping,skill:Axe,skill:Long Blade,skill:Long Blunt,skill:Maintenance,skill:Short Blade,skill:Short Blunt,skill:Spear,skill:Agriculture,skill:Animal Care,skill:Butchering,skill:Fitness,skill:Lightfooted,skill:Nimble,skill:Running,skill:Sneaking,skill:Strength} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char skills STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) skills:__disclosure(U) training:col1_Foraging(D) training:col2_Trapping(D) invrow:1(U) invrow:16(D) container:1(UD)
ZEDQA nav world loot: 17 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world loot STUCK: container:4(U) container:3(D) view:list:type:floor(U) view:grid:type:floor(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world loot worldContainerStrip:container:4 U>- D>container:1 L>window:Character R>worldMainInv:invrow:1
ZEDQA nav world loot worldContainerStrip:container:1 U>container:4 D>container:2 L>window:Character R>worldMainInv:invrow:1
ZEDQA nav world loot worldContainerStrip:container:2 U>container:1 D>container:3 L>window:Character R>worldMainInv:invrow:1
ZEDQA nav world loot worldContainerStrip:container:3 U>container:2 D>- L>window:Character R>worldMainInv:invrow:1
ZEDQA nav world loot worldMainInv:invrow:1 U>view:list:type:floor~ D>worldCtl:worldCtl:same L>worldContainerStrip:container:4 R>worldTabBar:tab:loot
ZEDQA nav world loot worldMainInv:view:list:type:floor U>- D>invrow:1~ L>worldContainerStrip:container:4 R>view:grid:type:floor
ZEDQA nav world loot worldMainInv:view:grid:type:floor U>- D>invrow:1~ L>view:list:type:floor R>worldTabBar:tab:loot
ZEDQA nav world loot worldTabBar:tab:loot U>- D>tab:craft L>worldMainInv:view:grid:type:floor R>-
ZEDQA nav world loot worldTabBar:tab:craft U>tab:loot D>tab:build L>worldMainInv:invrow:1 R>-
ZEDQA nav world loot worldTabBar:tab:build U>tab:craft D>tab:furniture L>worldMainInv:invrow:1 R>-
ZEDQA nav world loot worldTabBar:tab:furniture U>tab:build D>tab:maps L>worldMainInv:view:grid:type:floor R>-
ZEDQA nav world loot worldTabBar:tab:maps U>tab:furniture D>tab:forage L>worldMainInv:view:grid:type:floor R>-
ZEDQA nav world loot worldTabBar:tab:forage U>tab:maps D>tab:animals L>worldMainInv:view:grid:type:floor~ R>-
ZEDQA nav world loot worldTabBar:tab:animals U>tab:forage D>tab:vehicle L>worldMainInv:view:grid:type:floor~ R>-
ZEDQA nav world loot worldTabBar:tab:vehicle U>tab:animals D>- L>worldCtl:worldCtl:same~ R>-
ZEDQA nav world loot worldCtl:worldCtl:take U>worldMainInv:invrow:1 D>- L>worldContainerStrip:container:4 R>worldCtl:same
ZEDQA nav world loot worldCtl:worldCtl:same U>worldMainInv:invrow:1 D>- L>worldCtl:take R>worldTabBar:tab:loot~
ZEDQA nav world craft: 25 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world craft STUCK: container:4(U) container:3(D) view:list:type:floor(U) view:grid:type:floor(U) craft:stDrop(U) craft:catDrop(U) craft:sortMenu(D) craft:showMenu(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world build: 21 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world build STUCK: container:4(U) container:3(D) view:list:type:floor(U) view:grid:type:floor(U) build:catDrop(U) build:sortMenu(D) build:showMenu(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world furniture: 22 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world furniture STUCK: container:4(U) container:3(D) view:list:type:floor(U) view:grid:type:floor(U) fur:mode:pickup(UD) fur:mode:place(UD) fur:mode:rotate(UD) fur:mode:scrap(UD) fur:mode:repair(UD) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world maps: 36 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world maps STUCK: container:4(U) container:3(D) view:list:type:floor(U) view:grid:type:floor(U) map:disclosure(U) map:tool:house(U) map:tool:target(U) map:tool:skull(U) map:tool:star(U) map:tool:cross(U) map:tool:checkmark(U) map:tool:text(U) map:color:1(U) map:color:2(U) map:color:3(U) map:color:4(U) map:color:5(U) map:popout(U) map:style:survey(D) map:style:color(D) map:style:paper(D) map:ext:key(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world maps worldContainerStrip:container:4 U>- D>container:1 L>window:Character R>worldMainInv:invrow:1
ZEDQA nav world maps worldContainerStrip:container:1 U>container:4 D>container:2 L>window:Character R>worldMainInv:invrow:1
ZEDQA nav world maps worldContainerStrip:container:2 U>container:1 D>container:3 L>window:Character R>worldMainInv:invrow:1
ZEDQA nav world maps worldContainerStrip:container:3 U>container:2 D>- L>window:Character R>worldMainInv:invrow:1
ZEDQA nav world maps worldMainInv:invrow:1 U>view:list:type:floor~ D>worldCtl:worldCtl:same L>worldContainerStrip:container:4 R>worldTabContent:map:canvas:cursor
ZEDQA nav world maps worldMainInv:view:list:type:floor U>- D>invrow:1~ L>worldContainerStrip:container:4 R>view:grid:type:floor
ZEDQA nav world maps worldMainInv:view:grid:type:floor U>- D>invrow:1~ L>view:list:type:floor R>worldTabContent:map:disclosure
ZEDQA nav world maps worldTabContent:map:disclosure U>- D>map:canvas:cursor L>worldMainInv:view:grid:type:floor R>map:tool:house
ZEDQA nav world maps worldTabContent:map:tool:house U>- D>map:canvas:cursor L>map:disclosure R>map:tool:target
ZEDQA nav world maps worldTabContent:map:tool:target U>- D>map:canvas:cursor L>map:tool:house R>map:tool:skull
ZEDQA nav world maps worldTabContent:map:tool:skull U>- D>map:canvas:cursor L>map:tool:target R>map:tool:star
ZEDQA nav world maps worldTabContent:map:tool:star U>- D>map:canvas:cursor L>map:tool:skull R>map:tool:cross
ZEDQA nav world maps worldTabContent:map:tool:cross U>- D>map:canvas:cursor L>map:tool:star R>map:tool:checkmark
ZEDQA nav world maps worldTabContent:map:tool:checkmark U>- D>map:canvas:cursor L>map:tool:cross R>map:tool:text
ZEDQA nav world maps worldTabContent:map:tool:text U>- D>map:canvas:cursor L>map:tool:checkmark R>map:color:1
ZEDQA nav world maps worldTabContent:map:color:1 U>- D>map:canvas:cursor L>map:tool:text R>map:color:2
ZEDQA nav world maps worldTabContent:map:color:2 U>- D>map:canvas:cursor L>map:color:1 R>map:color:3
ZEDQA nav world maps worldTabContent:map:color:3 U>- D>map:canvas:cursor L>map:color:2 R>map:color:4
ZEDQA nav world maps worldTabContent:map:color:4 U>- D>map:canvas:cursor L>map:color:3 R>map:color:5
ZEDQA nav world maps worldTabContent:map:color:5 U>- D>map:canvas:cursor L>map:color:4 R>map:popout
ZEDQA nav world maps worldTabContent:map:popout U>- D>map:canvas:cursor L>map:color:5 R>worldTabBar:tab:maps
ZEDQA nav world maps worldTabContent:map:canvas:cursor U>map:disclosure D>map:style:paper L>worldMainInv:invrow:1 R>worldTabBar:tab:maps
ZEDQA nav world maps worldTabContent:map:style:survey U>map:canvas:cursor D>- L>worldCtl:worldCtl:same R>map:style:color
ZEDQA nav world maps worldTabContent:map:style:color U>map:canvas:cursor D>- L>map:style:survey R>map:style:paper
ZEDQA nav world maps worldTabContent:map:style:paper U>map:canvas:cursor D>- L>map:style:color R>map:ext:key
ZEDQA nav world maps worldTabContent:map:ext:key U>map:canvas:cursor D>- L>map:style:paper R>worldTabBar:tab:maps~
ZEDQA nav world maps worldTabBar:tab:loot U>- D>tab:craft L>worldTabContent:map:popout R>-
ZEDQA nav world maps worldTabBar:tab:craft U>tab:loot D>tab:build L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:build U>tab:craft D>tab:furniture L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:furniture U>tab:build D>tab:maps L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:maps U>tab:furniture D>tab:forage L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:forage U>tab:maps D>tab:animals L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:animals U>tab:forage D>tab:vehicle L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:vehicle U>tab:animals D>- L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldCtl:worldCtl:take U>worldMainInv:invrow:1 D>- L>worldContainerStrip:container:4 R>worldCtl:same
ZEDQA nav world maps worldCtl:worldCtl:same U>worldMainInv:invrow:1 D>- L>worldCtl:take R>worldTabContent:map:style:survey
ZEDQA nav world forage: 20 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world forage STUCK: container:4(U) container:3(D) view:list:type:floor(U) view:grid:type:floor(U) forage:dropdown(U) forage:search(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world animals: 20 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world animals STUCK: container:4(U) container:3(D) view:list:type:floor(U) view:grid:type:floor(U) animals:submode:ranch(U) animals:submode:butcher(U) animals:createzone(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world vehicle: 18 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world vehicle STUCK: container:4(U) container:3(D) view:list:type:floor(U) view:grid:type:floor(U) mech:inspect(UD) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav DONE
```

### 24. zedqa_loot_tabs.lua (`ZEDQA lt`) - PASS, 1 s

- go 21321 at 17:10:06

```text
[ZeD.QA] state #24 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA lt start
[ZeD.QA] run #24 ok=true
ZEDQA lt Character loot drawer false | World loot drawer false
ZEDQA lt DONE
```

### 25. zedqa_world_pad_take.lua (`ZEDQA wpt`) - PASS, 92 s

- go 21322 at 17:10:11

```text
[ZeD.QA] state #25 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #25 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Trunk, 3:Garbage Bag, 4:Military Backpack, 5:Ground | stops container:5@0, container:1@100, container:2@163, container:3@226, container:4@289
ZEDQA wpt PASS the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldMainInv:invrow:1 (Military Backpack)
ZEDQA wpt PASS RB lands in the World window on a lit element
ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
ZEDQA wpt 1 Right from the Character window's right edge: World worldMainInv:invrow:1 (Military Backpack)
ZEDQA wpt PASS the D-pad across from the Character window lands in the World window, lit
ZEDQA wpt 2 strip: World worldContainerStrip:container:5
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
ZEDQA wpt 3 timing: card buttons ready after 5 ticks, 4 frames; focus in the card after 5 ticks, 4 frames (watched 5 ticks, 4 frames)
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
ZEDQA wpt 6 after B: Char charMainInv:invrow:4 (Broken Large Handle)
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
ZEDQA wpt 7 tabs: 13 at small and large
ZEDQA wpt PASS 7 Char equip small pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 639 of 650)
ZEDQA wpt PASS 7 Char equip small wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 624 of 650)
ZEDQA wpt PASS 7 Char health small pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 Char health small wheel: the lowest control health:exercise is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char health small Health: scrolled to the end, drawn 616 px in a 521 px view
ZEDQA wpt PASS 7 Char thermal small pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 Char thermal small wheel: the lowest control thermal:view is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char identity small pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 639 of 650)
ZEDQA wpt PASS 7 Char identity small wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 628 of 650)
ZEDQA wpt PASS 7 Char journal small pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 Char journal small wheel: the lowest control journal:__save is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char skills small pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 Char skills small wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 634 of 650)
ZEDQA wpt PASS 7 World craft small pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World craft small wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World build small pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World build small wheel: the lowest control build:sortMenu is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World furniture small pad: Down reaches the lowest control of its column fur:obj:1 and it is in view (bottom 401 of 650)
ZEDQA wpt PASS 7 World furniture small wheel: the lowest control fur:obj:1 is in view at the bottom (bottom 401 of 650)
ZEDQA wpt PASS 7 World maps small pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World maps small wheel: the lowest control map:style:survey is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World forage small pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World forage small wheel: the lowest control forage:search is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World animals small pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World animals small wheel: the lowest control animals:createzone is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World vehicle small pad: Down reaches the lowest control of its column mech:inspect and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World vehicle small wheel: the lowest control mech:inspect is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 620 of 638)
ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 610 of 638)
ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 Char health large wheel: the lowest control health:exercise is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 623 px in a 491 px view
ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:view is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 626 of 638)
ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 614 of 638)
ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:__save is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 620 of 638)
ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World build large wheel: the lowest control build:sortMenu is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control of its column fur:obj:1 and it is in view (bottom 459 of 638)
ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:obj:1 is in view at the bottom (bottom 459 of 638)
ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:style:survey is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:search is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World animals large pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:createzone is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World vehicle large pad: Down reaches the lowest control of its column mech:inspect and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World vehicle large wheel: the lowest control mech:inspect is in view at the bottom (bottom 628 of 638)
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA wpt 93 passed, 0 failed
ZEDQA wpt DONE
```

### 26. zedqa_furniture.lua (`ZEDQA fu`) - PASS, 2 s

- go 21323 at 17:11:46

```text
[ZeD.QA] state #26 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #26 ok=true
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

### 27. zedqa_tabicons.lua (`ZEDQA ti`) - PASS, 3 s

- go 21324 at 17:11:51
- screenshots: zqa_tabicons.png

```text
[ZeD.QA] state #27 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #27 ok=true
ZEDQA ti DONE
```

### 28. zedqa_tabs_lit.lua (`ZEDQA tl`) - PASS, 7 s

- go 21325 at 17:11:57
- screenshots: zqa_tabs_1.png, zqa_tabs_2.png, zqa_tabs_3.png

```text
[ZeD.QA] state #28 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #28 ok=true
ZEDQA tl char true world true TabPx true
ZEDQA tl active loot / loot
ZEDQA tl restored; DONE
```

### 29. zedqa_win.lua (`ZEDQA win`) - PASS, 5 s

- go 21326 at 17:12:08
- screenshots: zedqa_win_200.png, zedqa_win_100.png

```text
[ZeD.QA] state #29 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #29 ok=true
ZEDQA win natural root=1.75 T.scale=1.75 rowH=53 sp.md=25 F2H=29.1484375 char=true 1134,0 777x735 world=true 1929,0 777x735
ZEDQA win forced1 root=1 T.scale=1 rowH=30 sp.md=14 F2H=16.65625 char=true 1134,0 777x735 world=true 1929,0 777x735
ZEDQA win done root=1.75
```

### 30. zedqa_rootchange.lua (`ZEDQA rc`) - PASS, 6 s

- go 21327 at 17:12:16
- screenshots: zedqa_rc_100.png, zedqa_rc_200.png

```text
[ZeD.QA] state #30 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #30 ok=true
ZEDQA rc open at natural root=1.75 applied=1.75 char=true 777x735 at 1134,0 world=true 777x735 rowH=53
ZEDQA rc after override 1.0 root=1 applied=1 char=true 444x420 at 648,0 world=true 444x420 rowH=30
ZEDQA rc after override cleared root=1.75 applied=1.75 char=true 777x735 at 1134,0 world=true 777x735 rowH=53
ZEDQA rc done
```

### 31. zedqa_scalewalk.lua (`ZEDQA sw`) - PASS, 66 s

- go 21328 at 17:12:26
- screenshots: zedqa_sw_200_char_loot.png, zedqa_sw_200_char_equip.png, zedqa_sw_200_char_health.png, zedqa_sw_200_char_thermal.png, zedqa_sw_200_char_identity.png, zedqa_sw_200_char_journal.png, zedqa_sw_200_char_skills.png, zedqa_sw_200_world_loot.png, zedqa_sw_200_world_craft.png, zedqa_sw_200_world_build.png, zedqa_sw_200_world_furniture.png, zedqa_sw_200_world_maps.png, zedqa_sw_200_world_forage.png, zedqa_sw_200_world_animals.png, zedqa_sw_200_world_vehicle.png, zedqa_sw_100_char_loot.png, zedqa_sw_100_char_equip.png, zedqa_sw_100_char_health.png, zedqa_sw_100_char_thermal.png, zedqa_sw_100_char_identity.png, zedqa_sw_100_char_journal.png, zedqa_sw_100_char_skills.png, zedqa_sw_100_world_loot.png, zedqa_sw_100_world_craft.png, zedqa_sw_100_world_build.png, zedqa_sw_100_world_furniture.png, zedqa_sw_100_world_maps.png, zedqa_sw_100_world_forage.png, zedqa_sw_100_world_animals.png, zedqa_sw_100_world_vehicle.png

```text
[ZeD.QA] state #31 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sw armed
[ZeD.QA] run #31 ok=true
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

### 32. zedqa_uiscale.lua (`ZEDQA scale`) - PASS, 14 s

- go 21329 at 17:13:35
- screenshots: zedqa_scale_auto.png, zedqa_scale_x150.png, zedqa_scale_x100.png, zedqa_scale_auto_back.png, zedqa_scale_restored.png

```text
[ZeD.QA] state #32 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA scale armed
[ZeD.QA] run #32 ok=true
ZEDQA scale auto option=7 userScale=1.75 root=1.75 iconDrawn=28 iconTex=24x24 char=777x735 world=777x735
ZEDQA scale x150 option=6 userScale=1.5 root=1.5 iconDrawn=24 iconTex=24x24 char=666x630 world=666x630
ZEDQA scale x100 option=4 userScale=1 root=1 iconDrawn=16 iconTex=16x16 char=444x420 world=444x420
ZEDQA scale auto_back option=1 userScale=nil root=2 iconDrawn=32 iconTex=32x32 char=888x840 world=888x840
ZEDQA scale restored option=7 userScale=1.75 root=1.75 iconDrawn=28 iconTex=24x24 char=777x735 world=777x735
ZEDQA scale done
```

### 33. zedqa_sc_font.lua (`ZEDQA scf`) - PASS, 3 s

- go 21330 at 17:13:53
- screenshots: zqa_scf_draw.png

```text
[ZeD.QA] state #33 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #33 ok=true
ZEDQA scf zoom 0.355 fallback false
ZEDQA scf PASS 1 Cred1 draws U+56FE (32)
ZEDQA scf PASS 2 map picks ZeD's face (32)
ZEDQA scf PASS 2/3 map width (45.5)
ZEDQA scf PASS 2/3 map role measure (45.5)
ZEDQA scf PASS 4 map count after name (73.9 vs 45.5 + 26.7)
ZEDQA scf PASS 2 simplified picks ZeD's face (32)
ZEDQA scf PASS 2/3 simplified width (92.4)
ZEDQA scf PASS 2/3 simplified role measure (92.4)
ZEDQA scf PASS 4 simplified count after name (119.4 vs 92.4 + 26.7)
ZEDQA scf PASS 3 cafe stays on Fira (false)
ZEDQA scf PASS 2/3 cafe width (45.5)
ZEDQA scf PASS 2/3 cafe role measure (45.5)
ZEDQA scf PASS 4 cafe count after name (72.2 vs 45.5 + 26.7)
ZEDQA scf PASS 2 map letter two not blank (45.5 / 24.2)
ZEDQA scf PASS 5 kana on the game's Japanese face (23)
ZEDQA scf total all passed
ZEDQA scf DONE
```

### 34. zedqa_mapshot.lua (`ZEDQA ms`) - PASS, 5 s

- go 21331 at 17:13:59
- screenshots: zqa_ms_1.png, zqa_ms_2.png

```text
[ZeD.QA] state #34 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ms start
[ZeD.QA] run #34 ok=true
ZEDQA ms world 1929,0 1617x735 tab maps
ZEDQA ms DONE
```

### 35. zedqa_mapstyles.lua (`ZEDQA mst`) - PASS, 15 s

- go 21332 at 17:14:08
- screenshots: zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png

```text
[ZeD.QA] state #35 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA mst start
[ZeD.QA] run #35 ok=true
ZEDQA mst survey: style survey zoom 13 images 2
ZEDQA mst color: style color zoom 13 images 2
ZEDQA mst paper: style paper zoom 13 images 1
ZEDQA mst DONE
```

### 36. zedqa_flyers.lua (`ZEDQA fl`) - PASS, 6 s

- go 21333 at 17:14:26
- screenshots: zqa_fl_1.png, zqa_fl_2.png

```text
[ZeD.QA] state #36 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA fl start
[ZeD.QA] run #36 ok=true
ZEDQA fl read pieces: 14
ZEDQA fl piece mccoyloggingcorp
ZEDQA fl read now: 15
ZEDQA fl forgot true read 14
ZEDQA fl DONE
```

### 37. zedqa_flyermap.lua (`ZEDQA fm`) - PASS, 13 s

- go 21334 at 17:14:36
- screenshots: zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png

```text
[ZeD.QA] state #37 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA fm start
[ZeD.QA] run #37 ok=true
ZEDQA fm read 16 (added 2)
ZEDQA fm tracker ticked the test place: true
ZEDQA fm pins on paper: muldraughbakesale, fossoil1(done), ustoreitmuldraugh, sunstarmotel(done)
ZEDQA fm hover: sunstarmotel
ZEDQA fm reader open true media sunstarmotel title Angel Cross + Sunstar Motel
ZEDQA fm flash true
ZEDQA fm read back to 14
ZEDQA fm DONE
```

### 38. zedqa_mapnotes.lua (`ZEDQA mnote`) - PASS, 9 s

- go 21335 at 17:14:53
- screenshots: zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png

```text
[ZeD.QA] state #38 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA mnote start
[ZeD.QA] run #38 ok=true
ZEDQA mnote gave 2 (pencil / eraser)
ZEDQA mnote map bound to the world map item: true
ZEDQA mnote before: store marks 8 | vanilla api marks 8 of 71 symbols (the rest are the map's own labels)
ZEDQA mnote text tool armed: true
ZEDQA mnote after note: store 8 -> 9 | vanilla api 8 -> 9 | found in store true | found by vanilla api true
ZEDQA mnote note ink 1 rgb 0.200 0.200 0.200 scale 0.6660000085830688 layer text-note
ZEDQA mnote star tool armed: true
ZEDQA mnote star as vanilla's Star: true ink 1 | store 10
ZEDQA mnote migration: first run added 2 (10 -> 12), second 0 (12), flag cleared 0 (12)
ZEDQA mnote migrated note ink 4 (want 4) | star ink 3 (want 3) | done flag true
ZEDQA mnote cursor finds the note: true
ZEDQA mnote cursor ui 420,260 | engine hit note 'ZEDQA note 62355' at world 809.0,12971.0 ui 420,282 | found note 'ZEDQA note 62355' at world 809.0,12971.0 ui 420,282 | the note note 'ZEDQA note 62355' at world 809.0,12971.0 ui 420,282
ZEDQA mnote menu: delete true | edit note true | change colour true | share false (multiplayer false)
ZEDQA mnote after delete: store 12 -> 11 | vanilla api 12 -> 11 | still found false / false
ZEDQA mnote removal: made a note true and a star true | store 11 -> 13
ZEDQA mnote removal: note true (13 -> 12), star true (-> 11), stale note again false (-> 11)
ZEDQA mnote style paper: map style paper | label layers 8 | strongest label alpha 0 | note hand alpha 255
ZEDQA mnote style survey: map style survey | label layers 8 | strongest label alpha 255 | note hand alpha 255
ZEDQA mnote style color: map style color | label layers 8 | strongest label alpha 255 | note hand alpha 255
ZEDQA mnote style back to color
ZEDQA mnote cleanup: removed 3 marks | store 8 (started 8) | modData back
ZEDQA mnote DONE
```

### 39. zedqa_journal_refs.lua (`ZEDQA jr`) - PASS, 5 s

- go 21336 at 17:15:05
- screenshots: zqa_jr_01_diary.png, zqa_jr_02_flyers.png

```text
[ZeD.QA] state #39 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA jr start
[ZeD.QA] run #39 ok=true
ZEDQA jr DONE
```

### 40. zedqa_journal_readers.lua (`ZEDQA jrd`) - PASS, 21 s

- go 21337 at 17:15:13
- screenshots: zqa_jr_01_papers.png, zqa_jr_02_unread_look.png, zqa_jr_03_read_look.png, zqa_jr_04_notebooks.png, zqa_jr_05_written.png, zqa_jr_06_into.png, zqa_jr_07_logged.png

```text
[ZeD.QA] state #40 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA jrd start
[ZeD.QA] run #40 ok=true
ZEDQA jrd papers 3 books 1 zones 4
ZEDQA jrd unread look zones back,read
ZEDQA jrd read look zones back,full,place:1,words
ZEDQA jrd note field true page 1
ZEDQA jrd light after 1 ticks: tooDark false
ZEDQA jrd ok written line on page 1
ZEDQA jrd log entry saw 3 of them by the gas station around noon | source Supply runs p1
ZEDQA jrd book p1 now day 3. truck still wont start. tried the battery / from the van on 31W, nothing. maybe its the starter / fossoil on the flyer too. go round back / saw 3 of them by the gas station around noon
ZEDQA jrd DONE (newspaper had been read before: false)
```

### 41. zedqa_lists.lua (`ZEDQA ls`) - PASS, 17 s

- go 21338 at 17:15:38
- screenshots: zqa_ls_01_page_480.png, zqa_ls_02_page_480_lines.png, zqa_ls_03_stepper.png, zqa_ls_04_ask_delete.png, zqa_ls_05_rightclick_list.png, zqa_ls_06_rightclick_strip.png, zqa_ls_07_card_inlists.png, zqa_ls_08_mark_popup.png

```text
[ZeD.QA] state #41 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ls start
[ZeD.QA] run #41 ok=true
ZEDQA ls items: crowbar true water 0.800000011920929
ZEDQA ls ok crowbar is gear (inv, any)
ZEDQA ls ok bandages are a fixed supply
ZEDQA ls carry: 20 lines, gear 14 supply 6
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
ZEDQA ls ready 19 of 20
ZEDQA ls ok store is plain values
ZEDQA ls ok round trip 2:20:QA carry
ZEDQA ls page: drawer 840 stacked true zones 72
ZEDQA ls ok the page's buttons, filter and list rows
ZEDQA ls ok the chosen list's Rename / Add / Delete
ZEDQA ls stops 20: jl:sec:loadout,jl:list:1,jl:sec:outfit,jl:list:2,jl:rename,jl:add,jl:delete,jl:lsec:gear,jl:sw:1,jl:line:1,jl:sw:2,jl:amt:2,jl:line:2,jl:sw:4,jl:amt:4,jl:line:4,jl:filter,jl:carry,jl:wear,jl:new
ZEDQA ls ok full card: the panes stack (drawer 840 px, 480u = 840)
ZEDQA ls switch on: Nails
ZEDQA ls ok page: the switch's right half sets This one
ZEDQA ls ok page: the left half sets Any
ZEDQA ls amount on: Nails
ZEDQA ls ok page: the amount opens a stepper
ZEDQA ls ok page: + adds one (2)
ZEDQA ls ok page: the pad's left takes one off (1)
ZEDQA ls ok page: pressing the amount again closes the stepper
ZEDQA ls ok page: Remove takes the line off (19)
ZEDQA ls doomed 4
ZEDQA ls ok Delete asks first
ZEDQA ls ok the question's two answers are the only stops (jl:ask:cancel,jl:ask:verb)
ZEDQA ls ok Delete in the band deletes
ZEDQA ls list look: Attach, Place Item, Put in Container (Crate), Favorite, Set Unwanted, Move to, Pin to title bar, |, Craft, Set to be Unusable in Recipes, |, Equip in Both Hands, Equip Primary, Equip Secondary, |, Drop, |, Save to loadout, |, Rename
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

### 42. zedqa_restock.lua (`ZEDQA rst`) - PASS, 59 s

- go 21339 at 17:15:59
- screenshots: zqa_rst_01_bar_ghosts.png, zqa_rst_02_todo.png, zqa_rst_02b_todo_lines.png, zqa_rst_03_ask_band.png, zqa_rst_04_after_hardcore.png, zqa_rst_05_pin_accessible.png, zqa_rst_06_pin_casual.png, zqa_rst_07_long_trip.png, zqa_rst_07b_long_trip_table.png, zqa_rst_08_unpack.png

```text
[ZeD.QA] state #42 speed=1 paused=false player=868,13024 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home rst moved from 868,13024,0 to the drag strip
ZEDQA rst start
[ZeD.QA] run #42 ok=true
ZEDQA rst the grandstand is loaded
ZEDQA vp rst player=925,13040 grid=19 chunks (152 tiles) loaded x 816-968 y 12952-13104 sq=892,13040 dist=33.5 chunk=true inMap=true car=nil vehicles=41
ZEDQA rst fixture: building 875,12964, standing at 885,13029 (18 from 892,13040)
ERROR: General f:50904 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:50911 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA rst built: crateA true crateB true locker true crateF true
ZEDQA rst set aside: 1 things holding water, 0 katanas
ZEDQA rst the character's load set aside: 76.3 of 18.0 carried (read 8.0 in god mode), now 3.8
ZEDQA rst stocked: hat Base.Hat_Fedora at hat, locker locked true
ZEDQA rst bandages in the building: 3
ZEDQA rst bar zones: fold,outfit,loadout,days:dec,days:inc,days,save,verb,ready
ZEDQA rst ok the bar draws in the Loadouts fold (opened above)
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
ZEDQA rst hardcore ran 3.4 s real for 3.2 s estimated (1.04 real s per estimated s)
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
ZEDQA rst ok casual: done when the list is empty (nil)
ZEDQA rst ok casual: the Fedora worn (and left on)
ZEDQA rst ok casual over the limit: ends with a reason (full)
ZEDQA rst ok casual over the limit: nothing more taken
ZEDQA rst ok casual over the limit: the to-do says why (Stopped: you carry all you can)
ZEDQA rst long haul: 4.6 of 18.0 carried, water 4.5 L a day
ZEDQA rst ok 5 days is over the limit (by 9.9)
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
ZEDQA rst ok stays on you: T-shirt, Jeans, Socks - Heavy, Military Boots, Leather Gloves, Belt, JS-2000 Shotgun, Screwdriver, Water Bottle
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
ZEDQA rst put back: 16 made things removed, 4 built things taken down, 103 set-aside things returned
ZEDQA rst ok nothing the run made is left on the character (0)
ZEDQA rst DONE (0 failed)
```

### 43. zedqa_reader.lua (`ZEDQA rd`) - PASS, 11 s

- go 21340 at 17:17:01
- screenshots: zqa_rd_01_paper.png, zqa_rd_02_words.png, zqa_rd_03_story2.png, zqa_rd_04_zoomed.png, zqa_rd_05_flier.png, zqa_rd_06_map.png

```text
[ZeD.QA] state #43 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rd start
[ZeD.QA] run #43 ok=true
ZEDQA rd light after 3 ticks: tooDark false
ZEDQA rd open true view paper body 0.46153846153846156
ZEDQA rd words blocks 12
ZEDQA rd flier places 1
ZEDQA rd map centre 10687,9831
ZEDQA rd DONE
```

### 44. zedqa_reader_refs.lua (`ZEDQA rr`) - PASS, 14 s

- go 21341 at 17:17:16
- screenshots: zqa_rr_01_journal_flyers.png, zqa_rr_02_news_card.png, zqa_rr_03_vanilla_news_paper.png, zqa_rr_04_vanilla_news_words.png, zqa_rr_05_vanilla_flier_paper.png, zqa_rr_06_vanilla_flier_words.png, zqa_rr_07_vanilla_journal.png

```text
[ZeD.QA] state #44 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rr start
[ZeD.QA] run #44 ok=true
ZEDQA rr items Base.Newspaper:zombie.inventory.types.Literature@bf3a726 Base.Flier:zombie.inventory.types.Literature@7bdd653b Base.Notebook:zombie.inventory.types.Literature@2a57acd9
ZEDQA rr DONE
```

### 45. zedqa_notebook.lua (`ZEDQA nb`) - PASS, 8 s

- go 21342 at 17:17:33
- screenshots: zqa_nb_01_page1.png, zqa_nb_02_erase_asks.png, zqa_nb_03_rail.png, zqa_nb_04_read_only.png, zqa_nb_05_locked_other.png

```text
[ZeD.QA] state #45 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA nb start
[ZeD.QA] run #45 ok=true
ZEDQA nb light after 3 ticks: tooDark false
ZEDQA nb open true mode notebook pages 10 readOnly false
ZEDQA nb after done: name Supply runs p1 day 3. truck still wont start. p2 water: 2 bottles + the pot. ne action false window false
ZEDQA nb read only true
ZEDQA nb other lock true readOnly true
ZEDQA nb DONE
```

### 46. zedqa_print_fit.lua (`ZEDQA pf`) - PASS, 14 s

- go 21343 at 17:17:45
- screenshots: zqa_pf_1a_KnoxKnews_July1_vanilla.png, zqa_pf_1b_KnoxKnews_July1_fitted.png, zqa_pf_2a_KnoxKnews_July2_vanilla.png, zqa_pf_2b_KnoxKnews_July2_fitted.png, zqa_pf_3a_KentuckyHerald_July6_vanilla.png, zqa_pf_3b_KentuckyHerald_July6_fitted.png, zqa_pf_4a_NationalDispatch_July6_vanilla.png, zqa_pf_4b_NationalDispatch_July6_fitted.png

```text
[ZeD.QA] state #46 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pf start
[ZeD.QA] run #46 ok=true
ZEDQA pf KnoxKnews_July1 element_23 y 470->310 room 576 scale 0.40->0.46 h 575
ZEDQA pf KnoxKnews_July1 element_25 y 700->640 room 230 scale 0.40->0.44 h 229
ZEDQA pf KnoxKnews_July1 element_27 y 733->747 room 123 scale 0.40->0.40 h 141 head 0.80->0.83
ZEDQA pf KnoxKnews_July2 element_23 y 470->310 room 576 scale 0.40->0.47 h 575
ZEDQA pf KnoxKnews_July2 element_25 y 700->640 room 230 scale 0.40->0.44 h 229
ZEDQA pf KnoxKnews_July2 element_27 y 700->640 room 230 scale 0.40->0.44 h 229
ZEDQA pf KentuckyHerald_July6 element_15 y 395->396 room 330 scale 0.45->0.45 h 343
ZEDQA pf KentuckyHerald_July6 element_18 y 415->416 room 310 scale 0.45->0.45 h 343
ZEDQA pf NationalDispatch_July6 element_16 y 339->331 room 444 scale 0.40->0.40 h 436
ZEDQA pf NationalDispatch_July6 element_21 y 240->236 room 564 scale 0.40->0.40 h 568
ZEDQA pf NationalDispatch_July6 element_22 y 716->712 room 88 scale 0.40->0.40 h 92
ZEDQA pf NationalDispatch_July6 element_23 y 716->712 room 99 scale 0.40->0.40 h 92
ZEDQA pf NationalDispatch_July6 element_24 y 716->712 room 58 scale 0.40->0.40 h 43
ZEDQA pf DONE
```

### 47. zedqa_print_typeset.lua (`ZEDQA ts`) - PASS, 7 s

- go 21344 at 17:18:02
- screenshots: zqa_ts_1_KnoxKnews_July1.png, zqa_ts_2_KnoxKnews_July2.png, zqa_ts_3_KentuckyHerald_July6.png, zqa_ts_4_NationalDispatch_July6.png

```text
[ZeD.QA] state #47 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ts start
[ZeD.QA] run #47 ok=true
ZEDQA ts KnoxKnews_July1 stories 3 body 0.46153846153846156 lines 43
ZEDQA ts KnoxKnews_July2 stories 3 body -0.4307692307692238 lines 5
ZEDQA ts KentuckyHerald_July6 stories 2 body 12.653615384615385 lines 41
ZEDQA ts NationalDispatch_July6 stories 5 body 11.576923076923077 lines 86
ZEDQA ts DONE
```

### 48. zedqa_prompts.lua (`ZEDQA pr`) - PASS, 32 s

- go 21345 at 17:18:13
- screenshots: zqa_pr_01_sleep.png, zqa_pr_02_kill.png, zqa_pr_03_note.png, zqa_pr_04_rename.png, zqa_pr_05_rename_empty.png, zqa_pr_06_keyboard.png, zqa_pr_07_alarm.png, zqa_pr_08_timer.png, zqa_pr_09_help.png, zqa_pr_10_rich_question.png, zqa_pr_11_gp_question.png, zqa_pr_12_gp_question_no.png, zqa_pr_13_gp_kill.png, zqa_pr_14_gp_text.png, zqa_pr_15_gp_keyboard.png, zqa_pr_16_gp_alarm.png

```text
[ZeD.QA] state #48 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pr start
[ZeD.QA] run #48 ok=true
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

### 49. zedqa_fishing.lua (`ZEDQA fi`) - PASS, 9 s

- go 21346 at 17:18:48
- screenshots: zqa_fi_1_slack.png, zqa_fi_2_light.png, zqa_fi_3_tight.png, zqa_fi_4_strain.png, zqa_fi_5_limit.png

```text
[ZeD.QA] state #49 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA fi start
[ZeD.QA] run #49 ok=true
ZEDQA fi 1_slack tension -0.6 vanilla angle -62
ZEDQA fi 2_light tension 0.15 vanilla angle -32
ZEDQA fi 3_tight tension 0.4 vanilla angle -2
ZEDQA fi 4_strain tension 0.72 vanilla angle 36.39999999999999
ZEDQA fi 5_limit tension 0.96 vanilla angle 65.19999999999999
ZEDQA fi DONE
```

### 50. zedqa_props_plates.lua (`ZEDQA props`) - PASS, 3 s

- go 21347 at 17:19:00
- screenshots: zqa_props_1.png, zqa_props_2.png, zqa_props_3.png

```text
[ZeD.QA] state #50 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #50 ok=true
ZEDQA props draw rod true/true slack true clock true/true
ZEDQA props DONE
```

### 51. zedqa_belt_strap.lua (`ZEDQA belt`) - PASS, 2 s

- go 21348 at 17:19:07
- screenshots: zqa_belt_strap_1.png

```text
[ZeD.QA] state #51 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #51 ok=true
ZEDQA belt textures true
ZEDQA belt shot; DONE
```

### 52. zedqa_straps.lua (`ZEDQA straps`) - PASS, 12 s

- go 21349 at 17:19:12
- screenshots: zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png

```text
[ZeD.QA] state #52 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #52 ok=true
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

### 53. zedqa_buckle.lua (`ZEDQA bk`) - PASS, 6 s

- go 21350 at 17:19:28
- screenshots: zqa_bk_1.png, zqa_bk_2.png, zqa_bk_3.png

```text
[ZeD.QA] state #53 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA bk start
[ZeD.QA] run #53 ok=true
ZEDQA bk centre 1920 vs screen 1920 | belt x 1535 w 747 | delta 0 | bare watch none
ZEDQA bk worn base:leftwrist
ZEDQA bk centre 1920 vs screen 1920 | belt x 1433 w 849 | delta 0 | cazio watch digital_black wrist left
ZEDQA bk worn base:rightwrist
ZEDQA bk centre 1920 vs screen 1920 | belt x 1433 w 849 | delta 0 | timez watch timez_easy wrist right
ZEDQA bk DONE
```

### 54. zedqa_buckles.lua (`ZEDQA bks`) - PASS, 38 s

- go 21351 at 17:19:37
- screenshots: zqa_bk_01_burgerflipper.png, zqa_bk_02_repairman.png, zqa_bk_03_burglar.png, zqa_bk_04_engineer.png, zqa_bk_05_fisherman.png, zqa_bk_06_policeofficer.png, zqa_bk_07_lumberjack.png, zqa_bk_08_smither.png, zqa_bk_09_farmer.png, zqa_bk_10_electrician.png, zqa_bk_11_fireofficer.png, zqa_bk_12_metalworker.png, zqa_bk_13_fitnessinstructor.png, zqa_bk_14_veteran.png, zqa_bk_15_tailor.png, zqa_bk_16_chef.png, zqa_bk_17_doctor.png, zqa_bk_18_parkranger.png, zqa_bk_19_unemployed.png, zqa_bk_20_nurse.png, zqa_bk_21_securityguard.png, zqa_bk_22_carpenter.png, zqa_bk_23_mechanics.png, zqa_bk_24_rancher.png, zqa_bk_25_constructionworker.png

```text
[ZeD.QA] state #54 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA bks professions 25
ZEDQA bks start
[ZeD.QA] run #54 ok=true
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

### 55. zedqa_beltwatch.lua (`ZEDQA bw`) - PASS, 12 s

- go 21352 at 17:20:18
- screenshots: zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png

```text
[ZeD.QA] state #55 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA bw start
[ZeD.QA] run #55 ok=true
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

### 56. zedqa_hands_together.lua (`ZEDQA ht`) - PASS, 19 s

- go 21353 at 17:20:34
- screenshots: zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png

```text
[ZeD.QA] state #56 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ht start
[ZeD.QA] run #56 ok=true
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

### 57. zedqa_watches2.lua (`ZEDQA watches`) - PASS, 28 s

- go 21354 at 17:20:56
- screenshots: zqa_watch_day_DigitalBlack.png, zqa_watch_day_DigitalDress.png, zqa_watch_day_DigitalRed.png, zqa_watch_day_DigitalTimez.png, zqa_watch_day_ClassicBlack.png, zqa_watch_day_ClassicGold.png, zqa_watch_day_ClassicBrown.png, zqa_watch_day_ClassicMilitary.png, zqa_watch_day_Expensive.png, zqa_watch_set_DigitalBlack.png, zqa_watch_night_DigitalBlack.png, zqa_watch_night_DigitalTimez.png, zqa_watch_lit_DigitalTimez.png, zqa_watch_night_ClassicBrown.png, zqa_watch_lit_ClassicBrown.png, zqa_watch_night_Expensive.png

```text
[ZeD.QA] state #57 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #57 ok=true
ZEDQA watches own watch nil at nil
ZEDQA watches no own watch; location base:leftwrist
ZEDQA watches item left true right true
ZEDQA watches name 'Digital Watch - Steel Sport Style' icon C:\Users\you\Zomboid\mods\ZeD-UI\42\media\textures\Item_ZeDWatchTimezSteel.png world Base.ZeDDigitalWatchSteel clothing true/WristWatch_Left_DigitalTimez digital true class true
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

### 58. zedqa_container_bottom.lua (`ZEDQA cb`) - PASS, 11 s

- go 21355 at 17:21:28
- screenshots: zqa_cb_01_rows_at_bottom.png, zqa_cb_02_list_end.png, zqa_cb_03_pad_take_all.png, zqa_cb_04_campfire_ribbon.png

```text
[ZeD.QA] state #58 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cb start
[ZeD.QA] run #58 ok=true
ZEDQA cb bed selected true
ZEDQA cb world list 651x650, row 64 at y 586
ZEDQA cb campfire selected true
ZEDQA cb DONE
```

### 59. zedqa_container_controls.lua (`ZEDQA ct`) - PASS, 19 s

- go 21356 at 17:21:43
- screenshots: zqa_ct_01_rows.png, zqa_ct_02_pad_same_type.png, zqa_ct_03_after_take_all.png, zqa_ct_04_floor_row.png, zqa_ct_05_campfire_row.png, zqa_ct_06_add_fuel_card.png

```text
[ZeD.QA] state #59 speed=1 paused=false player=869,13025 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ct start
[ZeD.QA] run #59 ok=true
ZEDQA ct pickup true
ZEDQA ct bed selected true
ZEDQA ct your row: Transfer all, Same type, Same type, all nearby
ZEDQA ct world row: Take all, Same type, To floor
ZEDQA ct start: bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 46
ZEDQA ct focused worldCtl:same prompt Take the kinds you already carry
ZEDQA ct marked rows (things) 7
ZEDQA ct no button Same type
ZEDQA ct after Same type (take): bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 46
ZEDQA ct no button Same type
ZEDQA ct after Same type (back): bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 46
ZEDQA ct no button Take all
ZEDQA ct after Take all: bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 46
ZEDQA ct no button Transfer all
ZEDQA ct after Transfer all: bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 46
ZEDQA ct no button To floor
ZEDQA ct after To floor: bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 46
ZEDQA ct floor selected true
ZEDQA ct floor row: Take all, Same type(off)
ZEDQA ct no button Take all
ZEDQA ct after Take all (floor): bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 46
ZEDQA ct no button Transfer all
ZEDQA ct after Transfer all (back to the bed): bag nails 8 planks 1 | bed nails 3 planks 4 beans 2, 13 things | floor 46
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

### 60. zedqa_container_controls_captures.lua (`ZEDQA cc`) - PASS, 6 s

- go 21357 at 17:22:05
- screenshots: zqa_cc_zed_truckbed.png, zqa_cc_vanilla_truckbed.png

```text
[ZeD.QA] state #60 speed=1 paused=false player=869,13025 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cc start
[ZeD.QA] run #60 ok=true
ZEDQA cc pickup true bed part TruckBedOpen
ZEDQA cc truck bed true dist 1.1
ZEDQA cc world window on the truck bed (1)
ZEDQA cc char 1134,0 777x735 world 1929,0 777x735
ZEDQA cc vanilla inv 640,0 1280x720 loot 1920,0 1280x720
ZEDQA cc DONE
```

### 61. zedqa_px_icons.lua (`ZEDQA px`) - PASS, 6 s

- go 21358 at 17:22:15
- screenshots: zqa_px_panel.png, zqa_px_card.png, zqa_px_rows.png

```text
[ZeD.QA] state #61 speed=1 paused=false player=869,13025 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA px scale 1.75: the 16-unit icon box is 28 px, the drawing for it 24
ZEDQA px ok 29 icons, four drawings each, the box picks 24
ZEDQA px ok a licensed name is no pixel icon (the row falls back to words, not a picture)
ZEDQA px ok the wheels use the same lookup
[ZeD.QA] run #61 ok=true
ZEDQA px shot zqa_px_panel
ZEDQA px ok the test panel drew
ZEDQA px selected by its row
ZEDQA px ok the card opened on Screwdriver
ZEDQA px shot zqa_px_card
ZEDQA px card toggle rects 3, on the card 3
ZEDQA px ok the card shows the screwdriver (Screwdriver)
ZEDQA px ok the card's three marks are drawn on it (3, 3 on the card)
ZEDQA px shot zqa_px_rows
ZEDQA px ok Fav put back
ZEDQA px DONE 0 failed
```

### 62. zedqa_button_case_game.lua (`ZEDQA bg`) - PASS, 20 s

- go 21359 at 17:22:24
- screenshots: zqa_bg_01_item_card.png, zqa_bg_02_health.png, zqa_bg_03_thermal.png, zqa_bg_04_animals.png, zqa_bg_05_forage.png, zqa_bg_06_craft.png, zqa_bg_07_vehicle.png

```text
[ZeD.QA] state #62 speed=1 paused=false player=869,13025 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA bg start
[ZeD.QA] run #62 ok=true
ZEDQA bg pickup true shirt true
ZEDQA bg card open true
ZEDQA bg DONE
```

### 63. zedqa_immersive_searching.lua (`ZEDQA iss`) - PASS, 4 s

- go 21360 at 17:22:48
- screenshots: zqa_iss_off_a.png

```text
[ZeD.QA] state #63 speed=1 paused=false player=870,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #63 ok=true
ZEDQA iss start off: mod loaded false, support false, sandbox SearchAll nil
ZEDQA iss bags on the floor 3, A holds 6
ZEDQA iss PASS the three bags are on the World strip (3)
ZEDQA iss PASS no gate registered for the mod (0)
ZEDQA iss PASS no pick hook registered (0)
ZEDQA iss PASS no strip decorator for the mod
ZEDQA iss PASS no band provider for the mod
ZEDQA iss PASS bag A counts six with no gate (6)
ZEDQA iss PASS A on show lists six, Take all in the band (m:take,m:same,m:floor)
ZEDQA iss PASS picking A queued nothing ()
ZEDQA iss PASS no empty-line or weight words from a gate
ZEDQA iss bags taken away
ZEDQA iss RESULT PASS
ZEDQA iss DONE
```

### 64. zedqa_wheel_sizes.lua (`ZEDQA ws`) - PASS, 20 s

- go 21361 at 17:22:56
- screenshots: zqa_ws_a_gun3.png, zqa_ws_b_dright3.png, zqa_ws_c_emotes5.png, zqa_ws_d_signal9.png, zqa_ws_e_back10.png, zqa_ws_g_car11.png, zqa_ws_h_car11pt.png

```text
[ZeD.QA] state #64 speed=1 paused=false player=870,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #64 ok=true
ZEDQA ws a_gun3 n=3 r=49 w=600
ZEDQA ws b_dright3 n=3 r=49 w=600
ZEDQA ws c_emotes5 n=5 r=49 w=600
ZEDQA ws d_signal9 n=9 r=83 w=668
ZEDQA ws e_back10 n=13 r=119 w=740
ZEDQA ws g_car11 n=11 r=101 w=704
ZEDQA ws h_car11pt n=11 r=101 w=704
ZEDQA ws done
```

### 65. zedqa_wheel_icons.lua (`ZEDQA wi`) - PASS, 63 s

- go 21362 at 17:23:19
- screenshots: zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png

```text
[ZeD.QA] state #65 speed=1 paused=false player=867,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wi start car=BaseVehicle{ Name:null, ID:24 }
[ZeD.QA] run #65 ok=true
ZEDQA wi scene: screen 3840x2160, scale option 7, icon box 28 at rest, 42 pointed
ZEDQA wi PASS all 154 icons load at 16, 24, 32 and 48, each its own file (0 problems)
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
ZEDQA wi PASS 142 slices on ZeD's five wheels, 125 with a wheel icon, the rest items, glyphs or colours
ZEDQA wi PASS the ZeD wheel's pickers give their choices the setting's icon
ZEDQA wi PASS the map's slices on ZeD's wheels: 80 with their icon
ZEDQA wi NOTE not on the wheels now (the state decides): the wounds (no wound now); character > Watch / UI_ZeD_Wheel_OpenWatch; character > Watch / UI_ZeD_Wheel_WatchLight; character > Watch / UI_ZeD_Wheel_WatchAlarm; character > Radio / UI_ZeD_Wheel_NextStation; world > Search / UI_disable_search_mode; world > Vehicle / IGUI_VehiclePartCatdashboard
ZEDQA wi PASS Crouch and Auto-walk show what the slice does now: sneak, autowalk
ZEDQA wi dpad_left: 9 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack 9:Loadouts/No loadouts saved=view_list
ZEDQA wi PASS dpad_left: 9 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_right: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_up: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Light/No light on you.=bulb_on
ZEDQA wi PASS dpad_down: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_select: 13 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/1 new=inbox 10:Bug report/Copy every error for a bug report=bullhorn 11:Reset windows/Both windows back to where they start=rotate 12:ZeD setup/Options, on ZeD's page=gears 13:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select: 12 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_left_use: 5 slices | 1:Smoke/Nothing to smoke, or nothing to light it.=cigarette 2:Read=book 3:Watch/No watch on your wrist.=watch 4:Radio/No radio in your hands or on your back.=walkie
ZEDQA wi PASS dpad_left_use: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down_speed: 5 slices | 1:Pause/In use=pause 2:FF x 1=ff1 3:FF x 2=ff2 4:FF x 3=wait
ZEDQA wi PASS dpad_down_speed: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down_view: 5 slices | 1:Hide the interface/Until you take this again=eye_off 2:Reset windows/Both windows back to where they start=rotate 3:Text size=textsize 4:OPTIONS/Options, on ZeD's page=gears
ZEDQA wi PASS dpad_down_view: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_select_theme: 4 slices | 1:Dark/In use=theme 2:Light=theme 3:High contrast=theme
ZEDQA wi PASS dpad_select_theme: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes: 5 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_friendly: 6 slices | 1:Wave Hi=wave 2:Bye=wave_bye 3:Clap=clap 4:Thumbs Up=thumbs_up 5:Thank You=bow
ZEDQA wi PASS emotes_friendly: 5 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_hostile: 5 slices | 1:Insult=insult 2:Stop=hand 3:Surrender=surrender 4:Thumbs Down=thumbs_down
ZEDQA wi PASS emotes_hostile: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_group: 7 slices | 1:Follow Me=follow_me 2:Come Here=come_here 3:Yes=yes 4:No=no 5:Shrug=shrug 6:Undecided=undecided
ZEDQA wi PASS emotes_group: 6 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_signal: 9 slices | 1:Cease Fire=target_off 2:Ok=yes 3:Move Out=move_out 4:Freeze=freeze 5:Follow Behind=follow_behind 6:Fire=target 7:Come=come_here 8:Salute=salute
ZEDQA wi PASS emotes_signal: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi gun: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi light: 4 slices | 1:Lighter/Equip Primary=keep?item_lighter 2:Lighter/Equip Secondary=keep?item_lighter 3:Flashlight/Unequip=minus 4:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi stick: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi vanilla_back: 10 slices | 1:Player Info=heart 2:Crafting=craft 3:Building=bricks 4:Zoom 75%=zoom_in 5:Pause=pause 6:FF x 1=ff1 7:Zoom 125%=zoom_out 8:Move furniture=chair 9:Enable Search Mode=eye 10:Investigate This Area=magnifier
ZEDQA wi PASS vanilla_back: 10 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi vanilla_dright: 3 slices | 1:Show/Hide World Map=map 2:Designated Zones=fence 3:Toggle Survival Guide=guide
ZEDQA wi PASS vanilla_dright: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi car_outside: 0 slices |
ZEDQA wi NOTE car_outside: the wheel is empty here
ZEDQA wi PASS in the car: the dashboard slice has the gauge (gauge)
ZEDQA wi car_inside: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Unlock all doors=padlock_open 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside: 12 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi PASS vanilla's radials and ZeD's wheels, live: 122 slices, 120 wheel icons, 2 kept pictures
ZEDQA wi now at 1x (text size small): icon box 16 at rest, 24 pointed
ZEDQA wi dpad_left_1x: 9 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack 9:Loadouts/No loadouts saved=view_list
ZEDQA wi PASS dpad_left_1x: 10 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_right_1x: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_up_1x: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down_1x: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Flashlight/Turn on=bulb_on
ZEDQA wi PASS dpad_down_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_select_1x: 13 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/1 new=inbox 10:Bug report/Copy every error for a bug report=bullhorn 11:Reset windows/Both windows back to where they start=rotate 12:ZeD setup/Options, on ZeD's page=gears 13:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select_1x: 12 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_1x: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes_1x: 5 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi gun_1x: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun_1x: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi light_1x: 4 slices | 1:Lighter/Equip Primary=keep?item_lighter 2:Lighter/Equip Secondary=keep?item_lighter 3:Flashlight/Unequip=minus 4:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light_1x: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi stick_1x: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick_1x: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi car_inside_1x: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Unlock all doors=padlock_open 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside_1x: 12 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi scale back to option 7: icon box 28
ZEDQA wi 0 failed, 3 notes
ZEDQA wi DONE
```

### 66. zedqa_wheels.lua (`ZEDQA wh`) - PASS, 31 s

- go 21363 at 17:24:26
- screenshots: zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png

```text
[ZeD.QA] state #66 speed=1 paused=false player=867,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wh start car=BaseVehicle{ Name:null, ID:24 } pistol=nil torch=nil
[ZeD.QA] run #66 ok=true
ZEDQA wh outside zed=true java=UIElement n=0 x=1716 y=876 w=408 vis=false point=-1 title=nil |
ZEDQA wh inside zed=true java=UIElement n=11 x=1568 y=728 w=704 vis=false point=-1 title=nil | 1:Switch Seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.[off] 3:Turn Headlights on 4:Turn AC/Heater on 5:Horn 6:Device Options 7:Open Window 8:Unlock all doors 9:Vehicle Mechanics 10:Not tired enough to sleep.[off] 11:Exit Vehicle
ZEDQA wh pick test slice3 from mouse -> 3
ZEDQA wh emotes zed=true java=UIElement n=5 x=1620 y=780 w=600 vis=false point=-1 title=nil | 1:Friendly 2:Hostile 3:Group 4:Signal 5:Shout
ZEDQA wh press towards 4 (Signal)
ZEDQA wh signal zed=true java=UIElement n=9 x=1586 y=746 w=668 vis=true point=-1 title=Signal | 1:Cease Fire 2:Ok 3:Move Out 4:Freeze 5:Follow Behind 6:Fire 7:Come 8:Salute 9:Back
ZEDQA wh gun zed=true java=UIElement n=0 x=1586 y=746 w=668 vis=false point=-1 title=nil |
ZEDQA wh light zed=true java=UIElement n=2 x=1620 y=780 w=600 vis=false point=-1 title=nil | 1:Lighter/Equip Primary 2:Lighter/Equip Secondary
ZEDQA wh back zed=true java=UIElement n=13 x=1550 y=710 w=740 vis=false point=-1 title=nil | 1:Base theme/Dark 2:Accent color/PZ Teal 3:Text size/Small 4:See-through/90% 5:Controller highlight/Pointing hand 6:UI scale 7:Moodles/Right edge 8:Action bar/Verbose 9:Messages/1 new 10:Bug report/Copy every error for a bug report 11:Reset windows/Both windows back to where they start 12:ZeD setup/Options, on ZeD's page 13:Safe mode/The game's own interface
ZEDQA wh dright zed=true java=UIElement n=2 x=1620 y=780 w=600 vis=false point=2 title=nil | 1:Lighter/Equip Primary 2:Lighter/Equip Secondary
ZEDQA wh zone route: world=true vanillaZone=false
ZEDQA wh zone tab showing=true
ZEDQA wh search route: forage showing=true vanillaSearch=false
ZEDQA wh player info route: char=true vanillaInfo=false
ZEDQA wh DONE
```

### 67. zedqa_dpad_wheels.lua (`ZEDQA dw`) - PASS, 50 s

- go 21364 at 17:25:00
- screenshots: zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png

```text
[ZeD.QA] state #67 speed=1 paused=false player=867,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA dw start
[ZeD.QA] run #67 ok=true
ZEDQA dw scene: at 867,13026, in a car false, health 100
ZEDQA dw foot left: 9 slices, crumb Character, visible false | 1:Tabs / Character window [>] 2:Weapons [>] 3:Eat [>] 4:Drink / Nothing to drink on you. [off] 5:Medicine and first aid [>] 6:Sleep / Not tired enough to sleep. [off] 7:Clothing / Nothing you wear can change. [off] 8:Use / Smoke | Read | Watch | Radio [>] 9:Loadouts / No loadouts saved [off]
ZEDQA dw PASS left: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS left: the slice 'Tabs' is there
ZEDQA dw inner left: 10 slices, crumb Character + Tabs, visible true | 1:Loot 2:Equipment 3:Health 4:Thermal 5:Cooking / Not now. [off] 6:Identity 7:Journal 8:Skills 9:Radio / No radio in your hands or on your back. [off] 10:Back
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
ZEDQA dw foot down: 8 slices, crumb Here and now, visible false | 1:Sit [>] 2:Crouch / Off 3:Auto-walk / Off 4:Game speed [>] 5:Zoom [>] 6:View / Interface and windows [>] 7:Help [>] 8:Light / No light on you. [off]
ZEDQA dw PASS down: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS down: the slice 'Zoom' is there
ZEDQA dw inner down: 3 slices, crumb Here and now + Zoom, visible true | 1:Zoom 75% 2:Zoom 125% 3:Back
ZEDQA dw PASS down: the inner wheel ends with Back
ZEDQA dw PASS down: the breadcrumb names the inner wheel
ZEDQA dw PASS down: B from the inner wheel is back on the top level
ZEDQA dw PASS down: B on the top level closes the wheel
ZEDQA dw foot select: 13 slices, crumb ZeD, visible false | 1:Base theme / Dark [>] 2:Accent color / PZ Teal [>] 3:Text size / Small [>] 4:See-through / 90% [>] 5:Controller highlight / Pointing hand [>] 6:UI scale [>] 7:Moodles / Right edge [>] 8:Action bar / Verbose [>] 9:Messages / 1 new 10:Bug report / Copy every error for a bug report 11:Reset windows / Both windows back to where they start 12:ZeD setup / Options, on ZeD's page 13:Safe mode / The game's own interface
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
ZEDQA dw 25 animals in the cell, none tame within 15 tiles: a tame cow spawned beside the character (true)
ZEDQA dw beside a tame animal (2.0 tiles away before)
ZEDQA dw the game's usable animal: nil
ZEDQA dw animal right: 8 slices, crumb World, visible false | 1:Tabs / World window [>] 2:Map [>] 3:Vehicle / No vehicle in reach. [off] 4:Animal [>] 5:Craft and build [>] 6:Search [>] 7:Lights and power / No lights or power in reach. [off] 8:Designated Zones / Animals
ZEDQA dw PASS beside a tame animal: World > Animal is live
ZEDQA dw animal wheel: 4 slices, crumb World + Animal, visible false | 1:Pick up Angus Cow 2:Pet 3:Animal Info 4:Back
ZEDQA dw PASS the animal wheel ends with Back
ZEDQA dw 0 failed
ZEDQA dw DONE
```

### 68. zedqa_pad_glyphs.lua (`ZEDQA pg`) - PASS, 34 s

- go 21365 at 17:25:53
- screenshots: zqa_pg_footer_ps.png, zqa_pg_wheel_ps.png, zqa_pg_footer_xbox.png, zqa_pg_wheel_xbox.png, zqa_pg_footer_deck.png, zqa_pg_wheel_deck.png, zqa_pg_footer_nintendo.png, zqa_pg_wheel_nintendo.png, zqa_pg_footer_kbm.png, zqa_pg_wheel_kbm.png, zqa_pg_footer_ps_light.png, zqa_pg_wheel_ps_light.png, zqa_pg_footer_ps_hicon.png, zqa_pg_wheel_ps_hicon.png

```text
[ZeD.QA] state #68 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pg start
[ZeD.QA] run #68 ok=true
ZEDQA pg scene: glyph setting xbox, the game's style XBOX, input gamepad
ZEDQA pg PASS ps: the setting reads ps
ZEDQA pg PASS ps: the set in use is ps
ZEDQA pg ps: footer pictures drawn in 10 ticks: 48
ZEDQA pg PASS ps: the footer draws its buttons as pictures
ZEDQA pg ps: wheel pictures drawn in 5 ticks: 32
ZEDQA pg PASS ps: the wheel's prompts are pictures
ZEDQA pg PASS xbox: the setting reads xbox
ZEDQA pg PASS xbox: the set in use is xbox
ZEDQA pg xbox: footer pictures drawn in 10 ticks: 42
ZEDQA pg PASS xbox: the footer draws its buttons as pictures
ZEDQA pg xbox: wheel pictures drawn in 5 ticks: 16
ZEDQA pg PASS xbox: the wheel's prompts are pictures
ZEDQA pg PASS deck: the setting reads deck
ZEDQA pg PASS deck: the set in use is deck
ZEDQA pg deck: footer pictures drawn in 10 ticks: 48
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

### 69. zedqa_quick_chords.lua (`ZEDQA qc`) - PASS, 25 s

- go 21366 at 17:26:30
- screenshots: zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png

```text
[ZeD.QA] state #69 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA qc start
[ZeD.QA] run #69 ok=true
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
ZEDQA qc the list for LB+A: 93 items, 85 to choose
ZEDQA qc PASS the chord's list offers the wheels' actions
ZEDQA qc put back: the chords file as it was; RB + Y reads world:2:1 (was world:2:1)
ZEDQA qc PASS the chords are as they were
ZEDQA qc all checks passed
ZEDQA qc DONE
```

### 70. zedqa_put_back.lua (`ZEDQA pb`) - PASS, 33 s

- go 21367 at 17:26:59

```text
[ZeD.QA] state #70 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pb start
[ZeD.QA] run #70 ok=true
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
ZEDQA pb put back: the switch 2 (was 2)
ZEDQA pb all checks passed
ZEDQA pb DONE
```

### 71. zedqa_food_verbs.lua (`ZEDQA fv`) - PASS, 4 s

- go 21368 at 17:27:35
- screenshots: zqa_fv_smoking.png

```text
[ZeD.QA] state #71 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA fv start
[ZeD.QA] run #71 ok=true
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

### 72. zedqa_messages.lua (`ZEDQA msg`) - PASS, 12 s

- go 21369 at 17:27:42
- 1 expected exception(s) ignored (expect=)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
[ZeD.QA] state #72 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA msg start
[ZeD.QA] run #72 ok=true
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
ERROR: General f:84755 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:84755> Lua(Vanilla).boom> Exception thrown   (expected)
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
ZEDQA msg PASS the bug report text names the errors (1867 characters)
ZEDQA msg PASS with the switch on, the mod's note shows as a pop-up
ZEDQA msg PASS Clear removes the mod's messages
ZEDQA msg PASS the last unanswered note got its OK as it left
ZEDQA msg all checks passed
ZEDQA msg DONE
```

### 73. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 21 s

- go 21370 at 17:27:58
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
[ZeD.QA] state #73 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #73 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 4
ZEDQA mood box by itself: TIRED | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA mood right: 4 moodles on (TIRED 2, HUNGRY 2, STRESS 2, THIRST 2)
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
ZEDQA mood left: 4 moodles on (TIRED 2, HUNGRY 2, STRESS 2, THIRST 2)
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
ZEDQA mood bottom: 4 moodles on (TIRED 2, HUNGRY 2, STRESS 2, THIRST 2)
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

### 74. zedqa_ring_squares.lua (`ZEDQA rs`) - PASS, 8 s

- go 21371 at 17:28:22
- screenshots: zqa_rs_belt_full.png, zqa_rs_belt_70_45.png, zqa_rs_belt_15.png

```text
[ZeD.QA] state #74 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rs start
[ZeD.QA] run #74 ok=true
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

### 75. zedqa_sandbox_ig.lua (`ZEDQA sbx`) - PASS, 17 s

- go 21372 at 17:28:34
- screenshots: zqa_sbx_pause_line.png, zqa_sbx_time.png, zqa_sbx_world_help.png, zqa_sbx_zombie_changed.png, zqa_sbx_ask_apply.png, zqa_sbx_applied.png, zqa_sbx_history.png, zqa_sbx_pad.png

```text
[ZeD.QA] state #75 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sbx start
[ZeD.QA] run #75 ok=true
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
ZEDQA sbx world line: This world is on day 5 of the count the shut-offs use. Water: on until day 14. Power: off since day 0.
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

### 76. zedqa_twoway.lua (`ZEDQA tw`) - PASS, 53 s

- go 21373 at 17:28:55
- screenshots: zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png

```text
[ZeD.QA] state #76 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA tw start
[ZeD.QA] run #76 ok=true
ZEDQA tw screen 3840x2160, root scale 1.75, plate zoom 2
ZEDQA tw PASS walkie_valutech: the Character window's Radio tab opens
ZEDQA tw PASS walkie_valutech: its own face, walkie_valutech (got walkie_valutech@180)
ZEDQA tw PASS walkie_valutech: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_valutech: centred in its panel (x 20, want 20)
ZEDQA tw PASS walkie_valutech: the width that fills the half card (want walkie_valutech@180, got walkie_valutech@180)
ZEDQA tw PASS walkie_valutech: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_valutech: all 6 controls on the face (6)
ZEDQA tw PASS walkie_valutech: the full view button in the header
ZEDQA tw PASS walkie_valutech: VOL pressed turns it on
ZEDQA tw PASS walkie_valutech: the display reads while on
ZEDQA tw walkie_valutech: display 101.200 | KNOXTALK RADIO | BAT 3
ZEDQA tw PASS walkie_valutech: BAT with 3 bars at 60% charge
ZEDQA tw valutech: body 585 px tall, the face's body needs 799 (window 735)
ZEDQA tw PASS valutech: at the default height the body scrolls
ZEDQA tw PASS valutech: the wheel off the knobs scrolls the body (0 -> 0.05)
ZEDQA tw PASS valutech: the grown window shows the whole face, no scrollbar
ZEDQA tw PASS VOL: the wheel turns the volume up (0.50 -> 0.60)
ZEDQA tw PASS TUNE: a click on its right half tunes up a step (101200 -> 101400)
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
ZEDQA tw PASS walkie_toy: its own face, walkie_toy (got walkie_toy@180)
ZEDQA tw PASS walkie_toy: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_toy: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_toy: the width that fills the half card (want walkie_toy@180, got walkie_toy@180)
ZEDQA tw PASS walkie_toy: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_toy: all 3 controls on the face (3)
ZEDQA tw PASS walkie_toy: the full view button in the header
ZEDQA tw PASS walkie_toy: VOL pressed turns it on
ZEDQA tw PASS walkie_toy: the display reads while on
ZEDQA tw walkie_toy: display 101.20 MHZ | nil | nil nil
ZEDQA tw PASS toy: no memories, its TALK button
ZEDQA tw PASS toy: the drum shows the frequency
ZEDQA tw PASS walkie_premium: the Character window's Radio tab opens
ZEDQA tw PASS walkie_premium: its own face, walkie_premium (got walkie_premium@180)
ZEDQA tw PASS walkie_premium: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_premium: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_premium: the width that fills the half card (want walkie_premium@180, got walkie_premium@180)
ZEDQA tw PASS walkie_premium: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_premium: all 6 controls on the face (6)
ZEDQA tw PASS walkie_premium: the full view button in the header
ZEDQA tw PASS walkie_premium: VOL pressed turns it on
ZEDQA tw PASS walkie_premium: the display reads while on
ZEDQA tw walkie_premium: display 094.200 | USR | BAT 3
ZEDQA tw PASS walkie_premium: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_tactical: the Character window's Radio tab opens
ZEDQA tw PASS walkie_tactical: its own face, walkie_tactical (got walkie_tactical@180)
ZEDQA tw PASS walkie_tactical: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_tactical: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_tactical: the width that fills the half card (want walkie_tactical@180, got walkie_tactical@180)
ZEDQA tw PASS walkie_tactical: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_tactical: all 9 controls on the face (9)
ZEDQA tw PASS walkie_tactical: the full view button in the header
ZEDQA tw PASS walkie_tactical: VOL pressed turns it on
ZEDQA tw PASS walkie_tactical: the display reads while on
ZEDQA tw walkie_tactical: display 107.600 | | BAT 3
ZEDQA tw PASS walkie_tactical: BAT with 3 bars at 60% charge
ZEDQA tw PASS Tactical: MUTE silences it
ZEDQA tw PASS Tactical: MUTE again gives the sound back
ZEDQA tw PASS Tactical: SCAN runs
ZEDQA tw PASS Tactical: SCAN again stops it
ZEDQA tw PASS Tactical: LAMP lights the display
ZEDQA tw PASS Tactical: the lamp goes out after 5 s
ZEDQA tw PASS walkie_army: the Character window's Radio tab opens
ZEDQA tw PASS walkie_army: its own face, walkie_army (got walkie_army@180)
ZEDQA tw PASS walkie_army: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_army: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_army: the width that fills the half card (want walkie_army@180, got walkie_army@180)
ZEDQA tw PASS walkie_army: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_army: all 9 controls on the face (9)
ZEDQA tw PASS walkie_army: the full view button in the header
ZEDQA tw PASS walkie_army: VOL pressed turns it on
ZEDQA tw PASS walkie_army: the display reads while on
ZEDQA tw walkie_army: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | BAT 3
ZEDQA tw PASS walkie_army: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_makeshift: the Character window's Radio tab opens
ZEDQA tw PASS walkie_makeshift: its own face, walkie_makeshift (got walkie_makeshift@180)
ZEDQA tw PASS walkie_makeshift: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_makeshift: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_makeshift: the width that fills the half card (want walkie_makeshift@180, got walkie_makeshift@180)
ZEDQA tw PASS walkie_makeshift: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_makeshift: all 6 controls on the face (6)
ZEDQA tw PASS walkie_makeshift: the full view button in the header
ZEDQA tw PASS walkie_makeshift: VOL pressed turns it on
ZEDQA tw PASS walkie_makeshift: the display reads while on
ZEDQA tw walkie_makeshift: display CH-- 107.60 | | nil nil
ZEDQA tw PASS makeshift: its character display reads CH.. (CH-- 107.60)
ZEDQA tw PASS walkie_manpack: the Character window's Radio tab opens
ZEDQA tw PASS walkie_manpack: its own face, walkie_manpack (got walkie_manpack@180)
ZEDQA tw PASS walkie_manpack: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_manpack: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_manpack: the width that fills the half card (want walkie_manpack@180, got walkie_manpack@180)
ZEDQA tw PASS walkie_manpack: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_manpack: all 7 controls on the face (7)
ZEDQA tw PASS walkie_manpack: the full view button in the header
ZEDQA tw PASS walkie_manpack: VOL pressed turns it on
ZEDQA tw PASS walkie_manpack: the display reads while on
ZEDQA tw walkie_manpack: display 091.200 | CIVILIAN RADIO | BAT 3
ZEDQA tw PASS walkie_manpack: BAT with 3 bars at 60% charge
ZEDQA tw PASS ManPack: on the back
ZEDQA tw PASS an AM/FM radio with faces off shows the chassis (the simple card)
ZEDQA tw 8 free squares in reach
ZEDQA tw placed 3 ham sets
ZEDQA tw PASS the World window's Radio tab opens on the placed sets
ZEDQA tw PASS ham_civilian: its own face, ham_civilian (got ham_civilian@392)
ZEDQA tw PASS ham_civilian: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_civilian: centred across the drawer (x 28, want 28)
ZEDQA tw PASS ham_civilian: the drawer holds the whole set (840 px for 784)
ZEDQA tw PASS ham_civilian: all 8 controls on the face (8)
ZEDQA tw PASS ham_civilian: the full view button in the header
ZEDQA tw PASS ham_civilian: VOL pressed turns it on
ZEDQA tw ham_civilian: display 378.400 | | range RANGE 7.5 KM
ZEDQA tw PASS ham_civilian: the display reads while on
ZEDQA tw PASS the drawer's clip is set and cleared in pairs with a ham showing (14 sets, 14 clears)
ZEDQA tw PASS civilian ham: RANGE matches its transmit range (RANGE 7.5 KM)
ZEDQA tw PASS civilian ham: the band marker follows the frequency up (0.7518367346938776 -> 0.8538775510204082)
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
ZEDQA tw PASS ham_army: its own face, ham_army (got ham_army@392)
ZEDQA tw PASS ham_army: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_army: centred across the drawer (x 28, want 28)
ZEDQA tw PASS ham_army: the drawer holds the whole set (840 px for 784)
ZEDQA tw PASS ham_army: all 14 controls on the face (14)
ZEDQA tw PASS ham_army: the full view button in the header
ZEDQA tw PASS ham_army: VOL pressed turns it on
ZEDQA tw ham_army: display 098.600 | | range RANGE 20 KM
ZEDQA tw PASS ham_army: the display reads while on
ZEDQA tw PASS army ham: tuned away
ZEDQA tw PASS army ham: 1 goes straight to memory 1
ZEDQA tw PASS army ham on the grid: AC, the bars dark (AC)
ZEDQA tw PASS ham_makeshift: its own face, ham_makeshift (got ham_makeshift@392)
ZEDQA tw PASS ham_makeshift: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_makeshift: centred across the drawer (x 28, want 28)
ZEDQA tw PASS ham_makeshift: the drawer holds the whole set (840 px for 784)
ZEDQA tw PASS ham_makeshift: all 7 controls on the face (7)
ZEDQA tw PASS ham_makeshift: the full view button in the header
ZEDQA tw PASS ham_makeshift: VOL pressed turns it on
ZEDQA tw ham_makeshift: display CH-- 107.800 MHZ | | range RANGE 6 KM
ZEDQA tw PASS ham_makeshift: the display reads while on
ZEDQA tw PASS makeshift ham: the TALK / LISTEN toggle flips with the mic
ZEDQA tw PASS makeshift ham: full view opens
ZEDQA tw PASS full view closes when the set is taken away
ZEDQA tw cleanup: 3 sets and 8 items taken away
ZEDQA tw 192 passed, 0 failed
ZEDQA tw all checks passed
ZEDQA tw DONE
```

### 77. zedqa_rtv.lua (`ZEDQA rtv`) - PASS, 87 s

- go 21374 at 17:29:51
- screenshots: zqa_rtv_1_radio_black.png, zqa_rtv_1_radio_red.png, zqa_rtv_1b_radio_red_list.png, zqa_rtv_1_radio_handbuilt.png, zqa_rtv_1_cd_player.png, zqa_rtv_1b_cd_player_list.png, zqa_rtv_2_pad_cd_player_battery_list.png, zqa_rtv_2_pad_cd_player_phones_list.png, zqa_rtv_2_pad_cd_player_disc_list.png, zqa_rtv_3_simple_card.png, zqa_rtv_4a_radio_red_placed.png, zqa_rtv_4c_tv_black_standby.png, zqa_rtv_4d_tv_black_triple_n_standby.png, zqa_rtv_4d_tv_black_turbo_standby.png, zqa_rtv_4c_tv_black_bars.png, zqa_rtv_4e_tv_black_no_power.png, zqa_rtv_2_pad_tv_black_tape_list.png, zqa_rtv_2_pad_tv_black_phones_list.png, zqa_rtv_4c_tv_widescreen_standby.png, zqa_rtv_4d_tv_widescreen_triple_n_standby.png, zqa_rtv_4d_tv_widescreen_turbo_standby.png, zqa_rtv_4c_tv_widescreen_bars.png, zqa_rtv_4e_tv_widescreen_no_power.png, zqa_rtv_4c_tv_antique_standby.png, zqa_rtv_4d_tv_antique_triple_n_standby.png, zqa_rtv_4d_tv_antique_turbo_standby.png, zqa_rtv_4c_tv_antique_bars.png, zqa_rtv_4e_tv_antique_no_power.png, zqa_rtv_5_house_bare.png, zqa_rtv_5_house_ci_radio.png, zqa_rtv_5_house_ci_tv.png

```text
[ZeD.QA] state #77 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtv start
[ZeD.QA] run #77 ok=true
ZEDQA rtv screen 3840x2160, root scale 1.75, plate zoom 2
ZEDQA rtv PASS radio_black: the Character window's Radio tab opens
ZEDQA rtv PASS radio_black: its own face, radio_black (got radio_black)
ZEDQA rtv PASS radio_black: the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS radio_black: the width that fills the half card (radio_black, got radio_black)
ZEDQA rtv PASS radio_black: centred, its margins its own (x 32, want 32)
ZEDQA rtv PASS radio_black: no full view button (a two-way set's)
ZEDQA rtv PASS radio_black: every control on the face (11 of 11)
ZEDQA rtv PASS radio_black: POWER turns it on
ZEDQA rtv PASS radio_black: the display reads and the lamp lights while on
ZEDQA rtv radio_black: display 98.0 | NNR RADIO | batt 3
ZEDQA rtv PASS radio_black: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS radio_black: TUNE's right half tunes up a step
ZEDQA rtv PASS radio_black: tuned away
ZEDQA rtv PASS radio_black: P1 pressed goes back to the stored station
ZEDQA rtv PASS radio_black: the battery key queues vanilla's battery action
ZEDQA rtv PASS radio_black: the headphone jack queues vanilla's action
ZEDQA rtv PASS radio_red: the Character window's Radio tab opens
ZEDQA rtv PASS radio_red: its own face, radio_red (got radio_red)
ZEDQA rtv PASS radio_red: the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS radio_red: the width that fills the half card (radio_red, got radio_red)
ZEDQA rtv PASS radio_red: centred, its margins its own (x 32, want 32)
ZEDQA rtv PASS radio_red: no full view button (a two-way set's)
ZEDQA rtv PASS radio_red: every control on the face (14 of 14)
ZEDQA rtv PASS radio_red: POWER turns it on
ZEDQA rtv PASS radio_red: the display reads and the lamp lights while on
ZEDQA rtv radio_red: display 98.0 | NNR RADIO | batt 3
ZEDQA rtv PASS radio_red: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS radio_red: TUNE's right half tunes up a step
ZEDQA rtv PASS radio_red: tuned away
ZEDQA rtv PASS radio_red: P1 pressed goes back to the stored station
ZEDQA rtv PASS radio_red: the battery key queues vanilla's battery action
ZEDQA rtv PASS radio_red: the slot opens the list of discs carried
ZEDQA rtv PASS radio_red: the headphone jack queues vanilla's action
ZEDQA rtv PASS radio_handbuilt: the Character window's Radio tab opens
ZEDQA rtv PASS radio_handbuilt: its own face, radio_handbuilt (got radio_handbuilt)
ZEDQA rtv PASS radio_handbuilt: the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS radio_handbuilt: the width that fills the half card (radio_handbuilt, got radio_handbuilt)
ZEDQA rtv PASS radio_handbuilt: centred, its margins its own (x 32, want 32)
ZEDQA rtv PASS radio_handbuilt: no full view button (a two-way set's)
ZEDQA rtv PASS radio_handbuilt: every control on the face (10 of 10)
ZEDQA rtv PASS radio_handbuilt: POWER turns it on
ZEDQA rtv PASS radio_handbuilt: the display reads and the lamp lights while on
ZEDQA rtv radio_handbuilt: display FM 98.0 MHZ | NNR RADIO | batt 3
ZEDQA rtv PASS radio_handbuilt: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS radio_handbuilt: TUNE's right half tunes up a step
ZEDQA rtv PASS radio_handbuilt: tuned away
ZEDQA rtv PASS radio_handbuilt: P1 pressed goes back to the stored station
ZEDQA rtv PASS radio_handbuilt: the battery key queues vanilla's battery action
ZEDQA rtv PASS radio_handbuilt: the headphone jack queues vanilla's action
ZEDQA rtv PASS cd_player: the Character window's Radio tab opens
ZEDQA rtv PASS cd_player: its own face, cd_player (got cd_player)
ZEDQA rtv PASS cd_player: the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS cd_player: the width that fills the half card (cd_player, got cd_player)
ZEDQA rtv PASS cd_player: centred, its margins its own (x 32, want 32)
ZEDQA rtv PASS cd_player: no full view button (a two-way set's)
ZEDQA rtv PASS cd_player: every control on the face (9 of 9)
ZEDQA rtv PASS cd_player: POWER turns it on
ZEDQA rtv PASS cd_player: the display reads and the lamp lights while on
ZEDQA rtv cd_player: display -:-- | NO DISC | batt 3
ZEDQA rtv PASS cd_player: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS cd_player: the battery key queues vanilla's battery action
ZEDQA rtv PASS cd_player: the slot opens the list of discs carried
ZEDQA rtv PASS cd_player: the headphone jack queues vanilla's action
ZEDQA rtv PASS controller: POWER is the first stop on the face (got radio:tw:power)
ZEDQA rtv PASS controller: every control is a stop (9)
ZEDQA rtv PASS cd_player: the pad lands on power when it enters the tab (radio:tw:power)
ZEDQA rtv PASS cd_player: the pad's A on battery opens its list
ZEDQA rtv PASS cd_player: the list closed: the pad is back on battery (radio:tw:battery)
ZEDQA rtv PASS cd_player: the pad's A on phones opens its list
ZEDQA rtv PASS cd_player: the list closed: the pad is back on phones (radio:tw:phones)
ZEDQA rtv PASS cd_player: the pad's A on slot opens its list
ZEDQA rtv PASS cd_player: the list closed: the pad is back on slot (radio:tw:slot)
ZEDQA rtv PASS faces off: the simple card (the chassis) through drawSimple
ZEDQA rtv PASS faces on again: the face is back
ZEDQA rtv indoors at 875,13018 (4 free room squares round it)
ZEDQA rtv grid: world power true, this square haveElectricity false, hasGridPower true, in a room true
ZEDQA rtv PASS the staging square has grid power
ZEDQA rtv placed 4 sets (round the character, on their squares)
ZEDQA rtv PASS the World window lists the placed sets (4)
ZEDQA rtv PASS the World window's Radio tab opens on the placed sets
ZEDQA rtv PASS radio_red (placed, by its tile): its own face, radio_red (got radio_red)
ZEDQA rtv PASS radio_red (placed, by its tile): the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS radio_red (placed, by its tile): the width that fills the half card (radio_red, got radio_red)
ZEDQA rtv PASS radio_red (placed, by its tile): centred, its margins its own (x 32, want 32)
ZEDQA rtv PASS radio_red (placed, by its tile): no full view button (a two-way set's)
ZEDQA rtv PASS radio_red (placed, by its tile): every control on the face (14 of 14)
ZEDQA rtv PASS tv_black (placed, by its tile): its own face, tv_black (got tv_black@392)
ZEDQA rtv PASS tv_black (placed, by its tile): the full card (840 px)
ZEDQA rtv PASS tv_black (placed, by its tile): no full view button (a two-way set's)
ZEDQA rtv PASS tv_black (placed, by its tile): every control on the face (10 of 10)
ZEDQA rtv PASS tv_black: the set has grid power (true)
ZEDQA rtv PASS tv_black: NO POWER dark on the grid
ZEDQA rtv PASS tv_black: off to start with
ZEDQA rtv PASS tv_black: power turns it on
ZEDQA rtv PASS tv_black: the power lamp lights
ZEDQA rtv PASS tv_black: the channel display reads (10)
ZEDQA rtv PASS tv_black: on the first stop (1)
ZEDQA rtv PASS tv_black: CH up: the second stop (2)
ZEDQA rtv PASS tv_black: CH down: back to the first (1)
ZEDQA rtv PASS tv_black: CH down from the first wraps to the twelfth (12)
ZEDQA rtv PASS tv_black: CH up from the twelfth wraps to the first (1)
ZEDQA rtv PASS tv_black: VOL up raises the volume
ZEDQA rtv PASS tv_black: VOL down lowers it again
ZEDQA rtv PASS tv_black: just changed channel: snow (snow)
ZEDQA rtv tv_black: channel 2 (triple_n): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 3 (wbln): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 4 (life): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 5 (turbo): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 6 (paws): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 7 (kpa): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 8 (mvc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 9 (nst): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 10 (bmc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 11 (gbc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 12 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_black: channel 12: the signal light bad on the bars
ZEDQA rtv PASS tv_black: channel 12: the display reads it
ZEDQA rtv tv_black: channel 13 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_black: channel 13: the signal light bad on the bars
ZEDQA rtv PASS tv_black: channel 13: the display reads it
ZEDQA rtv PASS tv_black: 12 and 13 have no station: the bars (bars, bars)
ZEDQA rtv PASS tv_black: the ten stations each show picture, sign-off or standby (10 of 10)
ZEDQA rtv tv_black: screens seen across the dial: snow x0, bars x2, picture x0, signoff x0, standby x10
ZEDQA rtv tv_black: NOT REACHED at this hour: picture (the game's broadcast clock decides)
ZEDQA rtv tv_black: NOT REACHED at this hour: signoff (the game's broadcast clock decides)
ZEDQA rtv PASS tv_black: a frequency off the dial: snow (snow)
ZEDQA rtv PASS tv_black: power again turns it off
ZEDQA rtv PASS tv_black: with the grid off the set reports no power
ZEDQA rtv PASS tv_black: NO POWER lit without the grid
ZEDQA rtv PASS tv_black: the power key without the grid leaves the screen dark
ZEDQA rtv PASS tv_black: the grid back on: the set has power again
ZEDQA rtv PASS tv_black: the pad lands on power when it enters the tab (radio:tw:power)
ZEDQA rtv PASS tv_black: the pad's A on slot opens its list
ZEDQA rtv PASS tv_black: the list closed: the pad is back on slot (radio:tw:slot)
ZEDQA rtv PASS tv_black: the pad's A on phones opens its list
ZEDQA rtv PASS tv_black: the list closed: the pad is back on phones (radio:tw:phones)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): its own face, tv_widescreen (got tv_widescreen@392)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): the full card (840 px)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): no full view button (a two-way set's)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): every control on the face (10 of 10)
ZEDQA rtv PASS tv_widescreen: the set has grid power (true)
ZEDQA rtv PASS tv_widescreen: NO POWER dark on the grid
ZEDQA rtv PASS tv_widescreen: off to start with
ZEDQA rtv PASS tv_widescreen: power turns it on
ZEDQA rtv PASS tv_widescreen: the power lamp lights
ZEDQA rtv PASS tv_widescreen: the channel display reads (02)
ZEDQA rtv PASS tv_widescreen: on the first stop (1)
ZEDQA rtv PASS tv_widescreen: CH up: the second stop (2)
ZEDQA rtv PASS tv_widescreen: CH down: back to the first (1)
ZEDQA rtv PASS tv_widescreen: CH down from the first wraps to the twelfth (12)
ZEDQA rtv PASS tv_widescreen: CH up from the twelfth wraps to the first (1)
ZEDQA rtv PASS tv_widescreen: VOL up raises the volume
ZEDQA rtv PASS tv_widescreen: VOL down lowers it again
ZEDQA rtv PASS tv_widescreen: just changed channel: snow (snow)
ZEDQA rtv tv_widescreen: channel 2 (triple_n): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 3 (wbln): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 4 (life): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 5 (turbo): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 6 (paws): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 7 (kpa): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 8 (mvc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 9 (nst): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 10 (bmc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 11 (gbc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 12 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_widescreen: channel 12: the signal light bad on the bars
ZEDQA rtv PASS tv_widescreen: channel 12: the display reads it
ZEDQA rtv tv_widescreen: channel 13 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_widescreen: channel 13: the signal light bad on the bars
ZEDQA rtv PASS tv_widescreen: channel 13: the display reads it
ZEDQA rtv PASS tv_widescreen: 12 and 13 have no station: the bars (bars, bars)
ZEDQA rtv PASS tv_widescreen: the ten stations each show picture, sign-off or standby (10 of 10)
ZEDQA rtv tv_widescreen: screens seen across the dial: snow x0, bars x2, picture x0, signoff x0, standby x10
ZEDQA rtv tv_widescreen: NOT REACHED at this hour: picture (the game's broadcast clock decides)
ZEDQA rtv tv_widescreen: NOT REACHED at this hour: signoff (the game's broadcast clock decides)
ZEDQA rtv PASS tv_widescreen: a frequency off the dial: snow (snow)
ZEDQA rtv PASS tv_widescreen: power again turns it off
ZEDQA rtv PASS tv_widescreen: with the grid off the set reports no power
ZEDQA rtv PASS tv_widescreen: NO POWER lit without the grid
ZEDQA rtv PASS tv_widescreen: the power key without the grid leaves the screen dark
ZEDQA rtv PASS tv_widescreen: the grid back on: the set has power again
ZEDQA rtv PASS tv_antique (placed, by its tile): its own face, tv_antique (got tv_antique@392)
ZEDQA rtv PASS tv_antique (placed, by its tile): the full card (840 px)
ZEDQA rtv PASS tv_antique (placed, by its tile): no full view button (a two-way set's)
ZEDQA rtv PASS tv_antique (placed, by its tile): every control on the face (4 of 4)
ZEDQA rtv PASS tv_antique: the volume knob is one control (volpwr), the channel dial another
ZEDQA rtv PASS tv_antique: the set has grid power (true)
ZEDQA rtv PASS tv_antique: NO POWER dark on the grid
ZEDQA rtv PASS tv_antique: off to start with
ZEDQA rtv PASS tv_antique: power turns it on
ZEDQA rtv PASS tv_antique: the power lamp lights
ZEDQA rtv PASS tv_antique: the channel display reads (10)
ZEDQA rtv PASS tv_antique: eleven clicks up the dial: the twelfth stop (12)
ZEDQA rtv PASS tv_antique: the dial's pointer is on the twelfth mark (11)
ZEDQA rtv PASS tv_antique: the dial stops at its upper end (12)
ZEDQA rtv PASS tv_antique: eleven clicks down: the first stop (1)
ZEDQA rtv PASS tv_antique: the dial stops at its lower end (1)
ZEDQA rtv PASS tv_antique: a click on the dial's right half: up a stop (2)
ZEDQA rtv PASS tv_antique: its left half: down a stop (1)
ZEDQA rtv PASS tv_antique: the knob turned: the volume rises
ZEDQA rtv PASS tv_antique: the knob turned: still on
ZEDQA rtv PASS tv_antique: the knob pulled: off
ZEDQA rtv PASS tv_antique: the knob pushed: on again
ZEDQA rtv PASS tv_antique: just changed channel: snow (snow)
ZEDQA rtv tv_antique: channel 2 (triple_n): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 3 (wbln): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 4 (life): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 5 (turbo): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 6 (paws): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 7 (kpa): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 8 (mvc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 9 (nst): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 10 (bmc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 11 (gbc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 12 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_antique: channel 12: the signal light bad on the bars
ZEDQA rtv PASS tv_antique: channel 12: the display reads it
ZEDQA rtv tv_antique: channel 13 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_antique: channel 13: the signal light bad on the bars
ZEDQA rtv PASS tv_antique: channel 13: the display reads it
ZEDQA rtv PASS tv_antique: 12 and 13 have no station: the bars (bars, bars)
ZEDQA rtv PASS tv_antique: the ten stations each show picture, sign-off or standby (10 of 10)
ZEDQA rtv tv_antique: screens seen across the dial: snow x0, bars x2, picture x0, signoff x0, standby x10
ZEDQA rtv tv_antique: NOT REACHED at this hour: picture (the game's broadcast clock decides)
ZEDQA rtv tv_antique: NOT REACHED at this hour: signoff (the game's broadcast clock decides)
ZEDQA rtv PASS tv_antique: a frequency off the dial: snow (snow)
ZEDQA rtv PASS tv_antique: power again turns it off
ZEDQA rtv PASS tv_antique: with the grid off the set reports no power
ZEDQA rtv PASS tv_antique: NO POWER lit without the grid
ZEDQA rtv PASS tv_antique: the power key without the grid leaves the screen dark
ZEDQA rtv PASS tv_antique: the grid back on: the set has power again
ZEDQA rtv PASS tv_antique: the pad lands on power when it enters the tab (radio:tw:volpwr)
ZEDQA rtv PASS tv_antique: pad: A on the knob powers it
ZEDQA rtv PASS tv_antique: pad: up on the knob turns the volume, the set stays on
ZEDQA rtv PASS tv_antique: pad: up on the dial: a stop up (4)
ZEDQA rtv PASS tv_antique: pad: A on the knob again: off
ZEDQA rtv PASS every off-air screen's texture loads (0 missing)
ZEDQA rtv PASS the game's own logo loads: triple_n
ZEDQA rtv PASS the game's own logo loads: turbo
ZEDQA rtv PASS controller: the set's power is the first stop (radio:tw:volpwr)
ZEDQA rtv house tiles: bare radio appliances_radio_01_20; CustomItem radio appliances_radio_01_3 (radio_black); CustomItem TV appliances_television_01_3 (tv_widescreen)
ZEDQA rtv PASS house radio tile appliances_radio_01_20: no face of its own without a dropped item
ZEDQA rtv PASS house radio dropped as an item (RadioItemID): the item's face (radio_black)
ZEDQA rtv PASS house radio tile appliances_radio_01_3 (CustomItem): radio_black (radio_black)
ZEDQA rtv PASS house TV tile appliances_television_01_3 (CustomItem): tv_widescreen (tv_widescreen)
ZEDQA rtv PASS the World window lists the house sets (3)
ZEDQA rtv PASS house_bare in the Radio tab: its own face, radio_black (got radio_black)
ZEDQA rtv PASS house_bare in the Radio tab: the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS house_bare in the Radio tab: the width that fills the half card (radio_black, got radio_black)
ZEDQA rtv PASS house_bare in the Radio tab: centred, its margins its own (x 32, want 32)
ZEDQA rtv PASS house_bare in the Radio tab: no full view button (a two-way set's)
ZEDQA rtv PASS house_bare in the Radio tab: every control on the face (11 of 11)
ZEDQA rtv PASS house_bare: on the grid (true)
ZEDQA rtv PASS house_ci_radio in the Radio tab: its own face, radio_black (got radio_black)
ZEDQA rtv PASS house_ci_radio in the Radio tab: the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS house_ci_radio in the Radio tab: the width that fills the half card (radio_black, got radio_black)
ZEDQA rtv PASS house_ci_radio in the Radio tab: centred, its margins its own (x 32, want 32)
ZEDQA rtv PASS house_ci_radio in the Radio tab: no full view button (a two-way set's)
ZEDQA rtv PASS house_ci_radio in the Radio tab: every control on the face (11 of 11)
ZEDQA rtv PASS house_ci_radio: on the grid (true)
ZEDQA rtv PASS house_ci_tv in the Radio tab: its own face, tv_widescreen (got tv_widescreen@392)
ZEDQA rtv PASS house_ci_tv in the Radio tab: the full card (840 px)
ZEDQA rtv PASS house_ci_tv in the Radio tab: no full view button (a two-way set's)
ZEDQA rtv PASS house_ci_tv in the Radio tab: every control on the face (10 of 10)
ZEDQA rtv PASS house_ci_tv: on the grid (true)
ZEDQA rtv cleanup: sets, house sets and 7 items taken away
ZEDQA rtv back at 866,13026
ZEDQA rtv 212 passed, 0 failed
ZEDQA rtv all checks passed
ZEDQA rtv DONE
```

### 78. zedqa_appliances.lua (`ZEDQA ap`) - PASS, 12 s

- go 21375 at 17:31:22
- screenshots: zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png

```text
[ZeD.QA] state #78 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ap start
[ZeD.QA] run #78 ok=true
ZEDQA ap indoors at 876,13017
ZEDQA ap placed: stove true, microwave true
ZEDQA ap PASS the stove opens in the Craft tab
ZEDQA ap stove powered true (grid power on the square true, object index 3, world power true)
ZEDQA ap PASS stove: the station is the one opened
ZEDQA ap PASS stove: the World window is on its Craft tab
ZEDQA ap stove: plate oven_modern@392 392x136, tab 840 px, zoom in the tab 2 (the screen's 2)
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
ZEDQA ap microwave: plate mw_white@392 392x168, tab 840 px, zoom in the tab 2 (the screen's 2)
ZEDQA ap PASS microwave: the tab is the full card
ZEDQA ap PASS microwave: the plate draws at a whole zoom that fits the card
ZEDQA ap PASS microwave: the tab has the pop-out button
ZEDQA ap PASS the microwave pops out too
ZEDQA ap cleanup: 2 appliances removed, station released
ZEDQA ap back at 866,13026
ZEDQA ap all checks passed
ZEDQA ap DONE
```

### 79. zedqa_two_widths.lua (`ZEDQA tww`) - PASS, 105 s

- go 21376 at 17:31:37
- screenshots: zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png

```text
[ZeD.QA] state #79 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA tww start
[ZeD.QA] run #79 ok=true
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
ZEDQA tww 27 more cases
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
ZEDQA tww Character Radio (a walkie): drawer 385 px = half | Character 749,0 1162x735 | World 1929,0 777x735
ZEDQA tww PASS Character Radio (a walkie): the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS Character Radio (a walkie): it is the half card (half)
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
ZEDQA tww PASS after the whole run both windows are where and as big as they were (1134,0 777x735 / 1929,0 777x735 -> 1134,0 777x735 / 1929,0 777x735)
ZEDQA tww skipped, the thing was not there to open: World object card fire, World object card hook, World object card hutch, World object card laundry, World object card lock, World object card plant, World object card preview, World object card track, World object card trough
ZEDQA tww ALL PASS
ZEDQA tww DONE
```

### 80. zedqa_plates_336.lua (`ZEDQA p336`) - PASS, 60 s

- go 21377 at 17:33:26
- screenshots: zqa_p336_scale175_oven.png, zqa_p336_scale175_microwave.png, zqa_p336_scale175_chrome.png, zqa_p336_scale175_generator.png, zqa_p336_scale175_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png

```text
[ZeD.QA] state #80 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA p336 start
[ZeD.QA] run #80 ok=true
ZEDQA p336 indoors at 876,13022
ZEDQA p336 placed: oven true, microwave true, chrome true, generator true, grill true
ZEDQA p336 phase A: root 1.75 (the run's own scale)
ZEDQA p336 PASS oven opens in the Craft tab
ZEDQA p336 PASS oven: the station is the one opened
ZEDQA p336 oven [scale175, root 1.75, zoom 2]: plate oven_modern, drawn oven_modern@392, tab 840 px (half 385, full 840); controls bake d1 d2 d3 d4 d5 timer broil d6 d7 d8 d9 d0 cancel start
ZEDQA p336 PASS oven: the tab is the half card or the full card
ZEDQA p336 PASS oven: the face has its controls (15)
ZEDQA p336 PASS oven: the face that fills the card is drawn (want oven_modern@392, drawn oven_modern@392)
ZEDQA p336 PASS oven: it sits inside the card at the whole zoom (784 of 815 px)
ZEDQA p336 PASS oven: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS oven: BAKE 175 START heats it and runs it (on true, 100)
ZEDQA p336 PASS oven: TIMER 0:30 START sets the timer (1800)
ZEDQA p336 PASS oven: CANCEL turns it off
ZEDQA p336 PASS microwave opens in the Craft tab
ZEDQA p336 PASS microwave: the station is the one opened
ZEDQA p336 microwave [scale175, root 1.75, zoom 2]: plate mw_white, drawn mw_white@392, tab 840 px (half 385, full 840); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS microwave: the tab is the half card or the full card
ZEDQA p336 PASS microwave: the face has its controls (14)
ZEDQA p336 PASS microwave: the face that fills the card is drawn (want mw_white@392, drawn mw_white@392)
ZEDQA p336 PASS microwave: it sits inside the card at the whole zoom (784 of 815 px)
ZEDQA p336 PASS microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS microwave: STOP twice turns it off
ZEDQA p336 PASS chrome microwave opens in the Craft tab
ZEDQA p336 PASS chrome microwave: the station is the one opened
ZEDQA p336 chrome microwave [scale175, root 1.75, zoom 2]: plate mw_chrome, drawn mw_chrome@392, tab 840 px (half 385, full 840); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS chrome microwave: the tab is the half card or the full card
ZEDQA p336 PASS chrome microwave: the face has its controls (14)
ZEDQA p336 PASS chrome microwave: the face that fills the card is drawn (want mw_chrome@392, drawn mw_chrome@392)
ZEDQA p336 PASS chrome microwave: it sits inside the card at the whole zoom (784 of 815 px)
ZEDQA p336 PASS chrome microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS chrome microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS chrome microwave: STOP twice turns it off
ZEDQA p336 generator [scale175, root 1.75]: card 840 px wide; controls gen:engine gen:outlet
ZEDQA p336 PASS generator: the card is the full card
ZEDQA p336 generator: plate room 804 px, the face for it gen_red@392
ZEDQA p336 PASS generator: the face has its controls
ZEDQA p336 PASS generator: the engine switch starts it (it runs)
ZEDQA p336 PASS generator: the engine switch stops it
ZEDQA p336 grill [scale175, root 1.75]: card 840 px wide; controls bbq:tank bbq:burner bbq:ignite
ZEDQA p336 PASS grill: the card is the full card
ZEDQA p336 grill: plate room 804 px, the face for it grill_propane@392
ZEDQA p336 PASS grill: the face has its controls
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 878.5,13023.5 (grill 878,13024)
ZEDQA p336 PASS grill: the burner knob lights it (lit)
ZEDQA p336 phase B: forced root 0.50
ZEDQA p336 PASS oven opens in the Craft tab
ZEDQA p336 PASS oven: the station is the one opened
ZEDQA p336 oven [scale050, root 0.50, zoom 1]: plate oven_modern, drawn oven_modern_n, tab 240 px (half 110, full 240); controls bake d1 d2 d3 d4 d5 timer broil d6 d7 d8 d9 d0 cancel start
ZEDQA p336 PASS oven: the tab is the half card or the full card
ZEDQA p336 PASS oven: the face has its controls (15)
ZEDQA p336 PASS oven: the face that fills the card is drawn (want oven_modern_n, drawn oven_modern_n)
ZEDQA p336 PASS oven: it sits inside the card at the whole zoom (200 of 233 px)
ZEDQA p336 PASS oven: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS oven: BAKE 175 START heats it and runs it (on true, 100)
ZEDQA p336 PASS oven: TIMER 0:30 START sets the timer (1800)
ZEDQA p336 PASS oven: CANCEL turns it off
ZEDQA p336 PASS microwave opens in the Craft tab
ZEDQA p336 PASS microwave: the station is the one opened
ZEDQA p336 microwave [scale050, root 0.50, zoom 1]: plate mw_white, drawn mw_white_n, tab 240 px (half 110, full 240); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS microwave: the tab is the half card or the full card
ZEDQA p336 PASS microwave: the face has its controls (14)
ZEDQA p336 PASS microwave: the face that fills the card is drawn (want mw_white_n, drawn mw_white_n)
ZEDQA p336 PASS microwave: it sits inside the card at the whole zoom (200 of 233 px)
ZEDQA p336 PASS microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS microwave: STOP twice turns it off
ZEDQA p336 PASS chrome microwave opens in the Craft tab
ZEDQA p336 PASS chrome microwave: the station is the one opened
ZEDQA p336 chrome microwave [scale050, root 0.50, zoom 1]: plate mw_chrome, drawn mw_chrome_n, tab 240 px (half 110, full 240); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS chrome microwave: the tab is the half card or the full card
ZEDQA p336 PASS chrome microwave: the face has its controls (14)
ZEDQA p336 PASS chrome microwave: the face that fills the card is drawn (want mw_chrome_n, drawn mw_chrome_n)
ZEDQA p336 PASS chrome microwave: it sits inside the card at the whole zoom (200 of 233 px)
ZEDQA p336 PASS chrome microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS chrome microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS chrome microwave: STOP twice turns it off
ZEDQA p336 generator [scale050, root 0.50]: card 240 px wide; controls gen:engine gen:outlet
ZEDQA p336 PASS generator: the card is the full card
ZEDQA p336 generator: plate room 230 px, the face for it gen_red_n
ZEDQA p336 PASS generator: the face has its controls
ZEDQA p336 PASS generator: the engine switch starts it (it runs)
ZEDQA p336 PASS generator: the engine switch stops it
ZEDQA p336 grill [scale050, root 0.50]: card 240 px wide; controls bbq:tank bbq:burner bbq:ignite
ZEDQA p336 PASS grill: the card is the full card
ZEDQA p336 grill: plate room 230 px, the face for it grill_propane_n
ZEDQA p336 PASS grill: the face has its controls
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 878.5,13023.5 (grill 878,13024)
ZEDQA p336 PASS grill: the burner knob lights it (lit)
ZEDQA p336 cleanup done: 5 things removed
ZEDQA p336 all checks passed
ZEDQA p336 DONE
```

### 81. zedqa_laundry.lua (`ZEDQA ldy`) - PASS, 83 s

- go 21378 at 17:34:29
- screenshots: zqa_ldy_washer_1_open.png, zqa_ldy_washer_1_open_later.png, zqa_ldy_washer_lvl1_water.png, zqa_ldy_washer_lvl2_water.png, zqa_ldy_washer_lvl3_water.png, zqa_ldy_washer_lvl4_water.png, zqa_ldy_washer_lvl5_water.png, zqa_ldy_washer_lvl1_soak.png, zqa_ldy_washer_lvl2_soak.png, zqa_ldy_washer_lvl3_soak.png, zqa_ldy_washer_lvl4_soak.png, zqa_ldy_washer_lvl5_soak.png, zqa_ldy_washer_3_nowater.png, zqa_ldy_washer_3_nopower.png, zqa_ldy_washer_2_running.png, zqa_ldy_dryer_1_open.png, zqa_ldy_dryer_1_open_later.png, zqa_ldy_dryer_3_nopower.png, zqa_ldy_dryer_2_running.png, zqa_ldy_combo_1_open.png, zqa_ldy_combo_1_open_later.png, zqa_ldy_combo_lvl1_water.png, zqa_ldy_combo_lvl2_water.png, zqa_ldy_combo_lvl3_water.png, zqa_ldy_combo_lvl4_water.png, zqa_ldy_combo_lvl5_water.png, zqa_ldy_combo_lvl1_soak.png, zqa_ldy_combo_lvl2_soak.png, zqa_ldy_combo_lvl3_soak.png, zqa_ldy_combo_lvl4_soak.png, zqa_ldy_combo_lvl5_soak.png, zqa_ldy_combo_3_nowater.png, zqa_ldy_combo_3_nopower.png, zqa_ldy_combo_2_running.png

```text
[ZeD.QA] state #81 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ldy start
[ZeD.QA] run #81 ok=true
ZEDQA ldy indoors at 875,13018 (3 free room sides)
ZEDQA ldy placed IsoClothingWasher (appliances_laundry_01_4) at 876,13018 (one square from the character at 875,13018): in a room true, container clothingwasher, powered true, tile piped true
ZEDQA ldy placed IsoClothingDryer (appliances_laundry_01_12) at 875,13017 (one square from the character at 875,13018): in a room true, container clothingdryer, powered true, tile piped false
ZEDQA ldy placed IsoCombinationWasherDryer (appliances_laundry_01_0) at 875,13019 (one square from the character at 875,13018): in a room true, container clothingwasher, powered true, tile piped true
ZEDQA ldy PASS synthetic half-full, powered: the drum and the meter both read 3 (3, 3)
ZEDQA ldy PASS synthetic half-full, no power: the drum still reads 3, the meter is dark (3, 0)
ZEDQA ldy PASS synthetic: the no-power lamp follows the power
ZEDQA ldy PASS synthetic piped supply (no capacity): five bars
ZEDQA ldy washer: water to start with 10000 (the machine reports it)
ZEDQA ldy PASS washer: the test could give the machine water (10000)
ZEDQA ldy PASS washer: the class picks the washer face (washer)
ZEDQA ldy PASS washer: the face shows (LD.useFace)
ZEDQA ldy PASS washer: the machine is in the World window's container list
ZEDQA ldy washer: row take same floor obj:ZeDLaundry
ZEDQA ldy PASS washer: the container row has the gears button
ZEDQA ldy PASS washer: vanilla's laundry buttons give way to it
ZEDQA ldy PASS washer: the gears button opens the laundry card on it
ZEDQA ldy PASS washer: the card is the full card
ZEDQA ldy washer [root 1.75]: plate room 804, face washer@392 at 2x (want washer@392)
ZEDQA ldy PASS washer: the face that fills the card is drawn
ZEDQA ldy PASS washer: it sits inside the card at a whole zoom
ZEDQA ldy washer: controls ldy:power ldy:door
ZEDQA ldy PASS washer: power and door are on the face
ZEDQA ldy PASS washer: power is the primary stop
ZEDQA ldy PASS washer: the controller lands on power
ZEDQA ldy PASS washer: every click area is a controller stop (2 of 2)
ZEDQA ldy PASS washer: stopped: phase lamps dark, the dial at 0
ZEDQA ldy washer: a second after opening: face washer@392
ZEDQA ldy washer: level 1 empty: water 1 waterLoad 0 waterBare 1 | clothes false | face washer@392
ZEDQA ldy PASS washer: water level 1 in the empty tub draws its water1 picture
ZEDQA ldy washer: level 2 empty: water 2 waterLoad 0 waterBare 2 | clothes false | face washer@392
ZEDQA ldy PASS washer: water level 2 in the empty tub draws its water2 picture
ZEDQA ldy washer: level 3 empty: water 3 waterLoad 0 waterBare 3 | clothes false | face washer@392
ZEDQA ldy PASS washer: water level 3 in the empty tub draws its water3 picture
ZEDQA ldy washer: level 4 empty: water 4 waterLoad 0 waterBare 4 | clothes false | face washer@392
ZEDQA ldy PASS washer: water level 4 in the empty tub draws its water4 picture
ZEDQA ldy washer: level 5 empty: water 5 waterLoad 0 waterBare 5 | clothes false | face washer@392
ZEDQA ldy PASS washer: water level 5 in the empty tub draws its water5 picture
ZEDQA ldy washer: level 1 with clothes: water 1 waterLoad 1 waterBare 0 | clothes true | face washer@392
ZEDQA ldy PASS washer: water level 1 with clothes draws its soak1 picture
ZEDQA ldy washer: level 2 with clothes: water 2 waterLoad 2 waterBare 0 | clothes true | face washer@392
ZEDQA ldy PASS washer: water level 2 with clothes draws its soak2 picture
ZEDQA ldy washer: level 3 with clothes: water 3 waterLoad 3 waterBare 0 | clothes true | face washer@392
ZEDQA ldy PASS washer: water level 3 with clothes draws its soak3 picture
ZEDQA ldy washer: level 4 with clothes: water 4 waterLoad 4 waterBare 0 | clothes true | face washer@392
ZEDQA ldy PASS washer: water level 4 with clothes draws its soak4 picture
ZEDQA ldy washer: level 5 with clothes: water 5 waterLoad 5 waterBare 0 | clothes true | face washer@392
ZEDQA ldy PASS washer: water level 5 with clothes draws its soak5 picture
ZEDQA ldy PASS washer: the clothes show with a shirt inside
ZEDQA ldy PASS washer: the door shows its contents in the Loot pane
ZEDQA ldy PASS washer [power, water]: the machine reports power
ZEDQA ldy PASS washer [power, water]: the no-power lamp is dark
ZEDQA ldy PASS washer [power, water]: the face has a meter (1) and a drum (10) reading the water
ZEDQA ldy PASS washer [power, water]: the drum shows the water (5 of 5)
ZEDQA ldy PASS washer [power, water]: the meter reads the water (5)
ZEDQA ldy PASS washer [power, water]: FILL is dark
ZEDQA ldy PASS washer [power, water]: the switch acts
ZEDQA ldy washer [power, water]: band nil
ZEDQA ldy PASS washer [power, water]: the band is quiet
ZEDQA ldy PASS washer [power, NO WATER]: the machine reports power
ZEDQA ldy PASS washer [power, NO WATER]: the no-power lamp is dark
ZEDQA ldy PASS washer [power, NO WATER]: the face has a meter (1) and a drum (10) reading the water
ZEDQA ldy PASS washer [power, NO WATER]: drum and meter read nothing (0, 0)
ZEDQA ldy PASS washer [power, NO WATER]: FILL is lit
ZEDQA ldy PASS washer [power, NO WATER]: the switch does nothing
ZEDQA ldy washer [power, NO WATER]: band Requires a source of water
ZEDQA ldy PASS washer [power, NO WATER]: the band says what it needs
ZEDQA ldy PASS washer [NO POWER, water]: the machine reports no power
ZEDQA ldy PASS washer [NO POWER, water]: the no-power lamp is lit
ZEDQA ldy PASS washer [NO POWER, water]: the face has a meter (1) and a drum (10) reading the water
ZEDQA ldy PASS washer [NO POWER, water]: the drum shows the water (5 of 5)
ZEDQA ldy PASS washer [NO POWER, water]: the meter reads nothing: dark without power (0)
ZEDQA ldy PASS washer [NO POWER, water]: FILL is dark
ZEDQA ldy PASS washer [NO POWER, water]: the switch does nothing
ZEDQA ldy washer [NO POWER, water]: band No power
ZEDQA ldy PASS washer [NO POWER, water]: the band says what it needs
ZEDQA ldy PASS washer [NO POWER, NO WATER]: the machine reports no power
ZEDQA ldy PASS washer [NO POWER, NO WATER]: the no-power lamp is lit
ZEDQA ldy PASS washer [NO POWER, NO WATER]: the face has a meter (1) and a drum (10) reading the water
ZEDQA ldy PASS washer [NO POWER, NO WATER]: drum and meter read nothing (0, 0)
ZEDQA ldy PASS washer [NO POWER, NO WATER]: FILL is lit
ZEDQA ldy PASS washer [NO POWER, NO WATER]: the switch does nothing
ZEDQA ldy washer [NO POWER, NO WATER]: band No power
ZEDQA ldy PASS washer [NO POWER, NO WATER]: the band says what it needs
ZEDQA ldy PASS washer [power, water]: the machine reports power
ZEDQA ldy PASS washer [power, water]: the no-power lamp is dark
ZEDQA ldy PASS washer [power, water]: the face has a meter (1) and a drum (10) reading the water
ZEDQA ldy PASS washer [power, water]: the drum shows the water (5 of 5)
ZEDQA ldy PASS washer [power, water]: the meter reads the water (5)
ZEDQA ldy PASS washer [power, water]: FILL is dark
ZEDQA ldy PASS washer [power, water]: the switch acts
ZEDQA ldy washer [power, water]: band nil
ZEDQA ldy PASS washer [power, water]: the band is quiet
ZEDQA ldy PASS washer: power starts it (vanilla's action)
ZEDQA ldy washer: running, lamps phWash, dial 0.00732421875, drum 0.21650000000000008
ZEDQA ldy PASS washer: the run lamp lights
ZEDQA ldy PASS washer: one phase lamp, the first (phWash)
ZEDQA ldy PASS washer: the next phase lamp a phase later (phRinse)
ZEDQA ldy PASS washer: the cycle dial moves (0.41177978515625)
ZEDQA ldy PASS washer: the drum turns
ZEDQA ldy PASS washer: power stops it
ZEDQA ldy PASS washer: stopped again: lamps dark, the dial at 0
ZEDQA ldy washer: plain row take same floor obj:ISLootWindowObjectControlHandler_ClothingWasherToggle
ZEDQA ldy PASS washer: LD.useFace false: no gears button
ZEDQA ldy PASS washer: LD.useFace false: vanilla's own laundry buttons are back
ZEDQA ldy PASS dryer: the class picks the dryer face (dryer)
ZEDQA ldy PASS dryer: the face shows (LD.useFace)
ZEDQA ldy PASS dryer: the machine is in the World window's container list
ZEDQA ldy dryer: row take same floor obj:ZeDLaundry
ZEDQA ldy PASS dryer: the container row has the gears button
ZEDQA ldy PASS dryer: vanilla's laundry buttons give way to it
ZEDQA ldy PASS dryer: the gears button opens the laundry card on it
ZEDQA ldy PASS dryer: the card is the full card
ZEDQA ldy dryer [root 1.75]: plate room 804, face dryer@392 at 2x (want dryer@392)
ZEDQA ldy PASS dryer: the face that fills the card is drawn
ZEDQA ldy PASS dryer: it sits inside the card at a whole zoom
ZEDQA ldy dryer: controls ldy:power ldy:door
ZEDQA ldy PASS dryer: power and door are on the face
ZEDQA ldy PASS dryer: power is the primary stop
ZEDQA ldy PASS dryer: the controller lands on power
ZEDQA ldy PASS dryer: every click area is a controller stop (2 of 2)
ZEDQA ldy PASS dryer: stopped: phase lamps dark, the dial at 0
ZEDQA ldy dryer: a second after opening: face dryer@392
ZEDQA ldy PASS dryer: the clothes show with a shirt inside
ZEDQA ldy PASS dryer: the door shows its contents in the Loot pane
ZEDQA ldy PASS dryer [power]: the machine reports power
ZEDQA ldy PASS dryer [power]: the no-power lamp is dark
ZEDQA ldy PASS dryer [power]: the switch acts
ZEDQA ldy dryer [power]: band nil
ZEDQA ldy PASS dryer [power]: the band is quiet
ZEDQA ldy PASS dryer [NO POWER]: the machine reports no power
ZEDQA ldy PASS dryer [NO POWER]: the no-power lamp is lit
ZEDQA ldy PASS dryer [NO POWER]: the switch does nothing
ZEDQA ldy dryer [NO POWER]: band No power
ZEDQA ldy PASS dryer [NO POWER]: the band says what it needs
ZEDQA ldy PASS dryer [power]: the machine reports power
ZEDQA ldy PASS dryer [power]: the no-power lamp is dark
ZEDQA ldy PASS dryer [power]: the switch acts
ZEDQA ldy dryer [power]: band nil
ZEDQA ldy PASS dryer [power]: the band is quiet
ZEDQA ldy PASS dryer: power starts it (vanilla's action)
ZEDQA ldy dryer: running, lamps phDry, dial 0.0084228515625, drum 0.16600000000000006
ZEDQA ldy PASS dryer: the run lamp lights
ZEDQA ldy PASS dryer: one phase lamp, the first (phDry)
ZEDQA ldy PASS dryer: the next phase lamp a phase later (phCool)
ZEDQA ldy PASS dryer: the cycle dial moves (0.616571044921875)
ZEDQA ldy PASS dryer: the drum turns
ZEDQA ldy PASS dryer: power stops it
ZEDQA ldy PASS dryer: stopped again: lamps dark, the dial at 0
ZEDQA ldy dryer: plain row take same floor obj:ISLootWindowObjectControlHandler_ClothingDryerToggle
ZEDQA ldy PASS dryer: LD.useFace false: no gears button
ZEDQA ldy PASS dryer: LD.useFace false: vanilla's own laundry buttons are back
ZEDQA ldy combo: water to start with 10000 (the machine reports it)
ZEDQA ldy PASS combo: the test could give the machine water (10000)
ZEDQA ldy PASS combo: the class picks the washer_dryer face (washer_dryer)
ZEDQA ldy PASS combo: the face shows (LD.useFace)
ZEDQA ldy PASS combo: the machine is in the World window's container list
ZEDQA ldy combo: row take same floor obj:ZeDLaundry
ZEDQA ldy PASS combo: the container row has the gears button
ZEDQA ldy PASS combo: vanilla's laundry buttons give way to it
ZEDQA ldy PASS combo: the gears button opens the laundry card on it
ZEDQA ldy PASS combo: the card is the full card
ZEDQA ldy combo [root 1.75]: plate room 804, face washer_dryer@392 at 2x (want washer_dryer@392)
ZEDQA ldy PASS combo: the face that fills the card is drawn
ZEDQA ldy PASS combo: it sits inside the card at a whole zoom
ZEDQA ldy combo: controls ldy:mode_wash ldy:mode_dry ldy:power ldy:door
ZEDQA ldy PASS combo: power and door are on the face
ZEDQA ldy PASS combo: power is the primary stop
ZEDQA ldy PASS combo: WASH and DRY are on the face
ZEDQA ldy PASS combo: the controller lands on power
ZEDQA ldy PASS combo: every click area is a controller stop (4 of 4)
ZEDQA ldy PASS combo: stopped: phase lamps dark, the dial at 0
ZEDQA ldy combo: a second after opening: face washer_dryer@392
ZEDQA ldy combo: level 1 empty: water 1 waterLoad 0 waterBare 1 | clothes false | face washer_dryer@392
ZEDQA ldy PASS combo: water level 1 empty
ZEDQA ldy combo: level 2 empty: water 2 waterLoad 0 waterBare 2 | clothes false | face washer_dryer@392
ZEDQA ldy PASS combo: water level 2 empty
ZEDQA ldy combo: level 3 empty: water 3 waterLoad 0 waterBare 3 | clothes false | face washer_dryer@392
ZEDQA ldy PASS combo: water level 3 empty
ZEDQA ldy combo: level 4 empty: water 4 waterLoad 0 waterBare 4 | clothes false | face washer_dryer@392
ZEDQA ldy PASS combo: water level 4 empty
ZEDQA ldy combo: level 5 empty: water 5 waterLoad 0 waterBare 5 | clothes false | face washer_dryer@392
ZEDQA ldy PASS combo: water level 5 empty
ZEDQA ldy combo: level 1 with clothes: water 1 waterLoad 1 waterBare 0 | clothes true | face washer_dryer@392
ZEDQA ldy PASS combo: water level 1 with clothes
ZEDQA ldy combo: level 2 with clothes: water 2 waterLoad 2 waterBare 0 | clothes true | face washer_dryer@392
ZEDQA ldy PASS combo: water level 2 with clothes
ZEDQA ldy combo: level 3 with clothes: water 3 waterLoad 3 waterBare 0 | clothes true | face washer_dryer@392
ZEDQA ldy PASS combo: water level 3 with clothes
ZEDQA ldy combo: level 4 with clothes: water 4 waterLoad 4 waterBare 0 | clothes true | face washer_dryer@392
ZEDQA ldy PASS combo: water level 4 with clothes
ZEDQA ldy combo: level 5 with clothes: water 5 waterLoad 5 waterBare 0 | clothes true | face washer_dryer@392
ZEDQA ldy PASS combo: water level 5 with clothes
ZEDQA ldy PASS combo: the clothes show with a shirt inside
ZEDQA ldy PASS combo: the door shows its contents in the Loot pane
ZEDQA ldy PASS combo [power, water]: the machine reports power
ZEDQA ldy PASS combo [power, water]: the no-power lamp is dark
ZEDQA ldy PASS combo [power, water]: the face has a meter (1) and a drum (5) reading the water
ZEDQA ldy PASS combo [power, water]: the drum shows the water (5 of 5)
ZEDQA ldy PASS combo [power, water]: the meter reads the water (5)
ZEDQA ldy PASS combo [power, water]: FILL is dark
ZEDQA ldy PASS combo [power, water]: the switch acts
ZEDQA ldy PASS combo [power, water]: the DRY key acts
ZEDQA ldy combo [power, water]: band nil
ZEDQA ldy PASS combo [power, water]: the band is quiet
ZEDQA ldy PASS combo [power, NO WATER]: the machine reports power
ZEDQA ldy PASS combo [power, NO WATER]: the no-power lamp is dark
ZEDQA ldy PASS combo [power, NO WATER]: the face has a meter (1) and a drum (5) reading the water
ZEDQA ldy PASS combo [power, NO WATER]: drum and meter read nothing (0, 0)
ZEDQA ldy PASS combo [power, NO WATER]: FILL is lit
ZEDQA ldy PASS combo [power, NO WATER]: the switch does nothing
ZEDQA ldy PASS combo [power, NO WATER]: the DRY key acts
ZEDQA ldy combo [power, NO WATER]: band Requires a source of water
ZEDQA ldy PASS combo [power, NO WATER]: the band says what it needs
ZEDQA ldy PASS combo [NO POWER, water]: the machine reports no power
ZEDQA ldy PASS combo [NO POWER, water]: the no-power lamp is lit
ZEDQA ldy PASS combo [NO POWER, water]: the face has a meter (1) and a drum (5) reading the water
ZEDQA ldy PASS combo [NO POWER, water]: the drum shows the water (5 of 5)
ZEDQA ldy PASS combo [NO POWER, water]: the meter reads nothing: dark without power (0)
ZEDQA ldy PASS combo [NO POWER, water]: FILL is dark
ZEDQA ldy PASS combo [NO POWER, water]: the switch does nothing
ZEDQA ldy PASS combo [NO POWER, water]: the DRY key does nothing
ZEDQA ldy combo [NO POWER, water]: band No power
ZEDQA ldy PASS combo [NO POWER, water]: the band says what it needs
ZEDQA ldy PASS combo [NO POWER, NO WATER]: the machine reports no power
ZEDQA ldy PASS combo [NO POWER, NO WATER]: the no-power lamp is lit
ZEDQA ldy PASS combo [NO POWER, NO WATER]: the face has a meter (1) and a drum (5) reading the water
ZEDQA ldy PASS combo [NO POWER, NO WATER]: drum and meter read nothing (0, 0)
ZEDQA ldy PASS combo [NO POWER, NO WATER]: FILL is lit
ZEDQA ldy PASS combo [NO POWER, NO WATER]: the switch does nothing
ZEDQA ldy PASS combo [NO POWER, NO WATER]: the DRY key does nothing
ZEDQA ldy combo [NO POWER, NO WATER]: band No power
ZEDQA ldy PASS combo [NO POWER, NO WATER]: the band says what it needs
ZEDQA ldy PASS combo [power, water]: the machine reports power
ZEDQA ldy PASS combo [power, water]: the no-power lamp is dark
ZEDQA ldy PASS combo [power, water]: the face has a meter (1) and a drum (5) reading the water
ZEDQA ldy PASS combo [power, water]: the drum shows the water (5 of 5)
ZEDQA ldy PASS combo [power, water]: the meter reads the water (5)
ZEDQA ldy PASS combo [power, water]: FILL is dark
ZEDQA ldy PASS combo [power, water]: the switch acts
ZEDQA ldy PASS combo [power, water]: the DRY key acts
ZEDQA ldy combo [power, water]: band nil
ZEDQA ldy PASS combo [power, water]: the band is quiet
ZEDQA ldy PASS combo: DRY sets dryer mode
ZEDQA ldy PASS combo: the DRY lamp lights
ZEDQA ldy PASS combo: dryer mode needs no water: FILL dark
ZEDQA ldy PASS combo: WASH sets washer mode
ZEDQA ldy PASS combo: power starts it (vanilla's action)
ZEDQA ldy combo: running, lamps phWash, dial 0.001708984375, drum 0.057
ZEDQA ldy PASS combo: the run lamp lights
ZEDQA ldy PASS combo: one phase lamp, the first (phWash)
ZEDQA ldy PASS combo: the next phase lamp a phase later (phRinse)
ZEDQA ldy PASS combo: the cycle dial moves (0.40616455078125)
ZEDQA ldy PASS combo: the drum turns
ZEDQA ldy PASS combo: power stops it
ZEDQA ldy PASS combo: stopped again: lamps dark, the dial at 0
ZEDQA ldy combo: plain row take same floor obj:ISLootWindowObjectControlHandler_CombinationWasherDryerSetMode obj:ISLootWindowObjectControlHandler_CombinationWasherDryerToggle
ZEDQA ldy PASS combo: LD.useFace false: no gears button
ZEDQA ldy PASS combo: LD.useFace false: vanilla's own laundry buttons are back
ZEDQA ldy cleanup done: 3 machines removed, 5 items taken back
ZEDQA ldy back at 866,13026
ZEDQA ldy all checks passed
ZEDQA ldy DONE
```

### 82. zedqa_seat_lightbar_vanilla.lua (`ZEDQA sl`) - PASS, 20 s

- go 21379 at 17:35:56
- screenshots: zqa_sl_bg_pickup.png, zqa_sl_v01_pickup.png, zqa_sl_v02_pickup_point.png, zqa_sl_v03_pickup_items.png, zqa_sl_bg_police.png, zqa_sl_v04_police.png, zqa_sl_v05_police_point.png, zqa_sl_v06_lightbar.png, zqa_sl_v07_lightbar_on.png, zqa_sl_v08_van_point.png, zqa_sl_v09_outside.png

```text
[ZeD.QA] state #82 speed=1 paused=false player=866,13026 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home sl moved from 866,13026,0 to the drag strip
ZEDQA sl start
[ZeD.QA] run #82 ok=true
ZEDQA vp sl player=925,13040 grid=19 chunks (152 tiles) loaded x 832-984 y 12952-13104 sq=921,13040 dist=4.5 chunk=true inMap=true car=Base.PickUpTruck at 921.0,13040.0 dist=4.5 vehicles=41
ZEDQA vp sl player=925,13040 grid=19 chunks (152 tiles) loaded x 832-984 y 12952-13104 sq=929,13040 dist=3.5 chunk=true inMap=true car=Base.CarLightsKST at 929.0,13040.0 dist=3.5 vehicles=41
ZEDQA vp sl player=925,13040 grid=19 chunks (152 tiles) loaded x 832-984 y 12952-13104 sq=925,13035 dist=5.5 chunk=true inMap=true car=Base.VanSeats at 925.0,13035.0 dist=5.5 vehicles=41
ZEDQA sl pickup=BaseVehicle{ Name:null, ID:275 } police=BaseVehicle{ Name:null, ID:276 } van=BaseVehicle{ Name:null, ID:277 }
ERROR: General f:111282 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA sl enter Base.PickUpTruck dist=4.6 physics=true
ERROR: General f:111286 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA sl enter Base.CarLightsKST dist=9.0 physics=false
ZEDQA sl lightbar x=1705 y=940 w=430 h=280
ZEDQA sl enter Base.VanSeats dist=7.4 physics=true
ZEDQA sl DONE
```

### 83. zedqa_car_radio_build.lua (`ZEDQA rb`) - PASS, 29 s

- go 21380 at 17:36:20
- screenshots: zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png

```text
[ZeD.QA] state #83 speed=1 paused=false player=924,13034 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home rb moved from 924,13034,0 to the drag strip
ZEDQA rb start
[ZeD.QA] run #83 ok=true
ZEDQA vp rb player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=921,13040 dist=4.5 chunk=true inMap=true car=Base.PickUpTruck at 921.0,13040.0 dist=4.5 vehicles=45
ZEDQA rb spawned Base.PickUpTruck beside the character
ZEDQA vp rb player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=929,13040 dist=3.5 chunk=true inMap=true car=Base.CarLightsKST at 929.0,13040.0 dist=3.5 vehicles=45
ZEDQA rb spawned Base.CarLightsPolice beside the character
ZEDQA rb Base.PickUpTruck radio=Base.RadioBlack
ZEDQA rb Base.CarLightsKST radio=Base.HamRadio1
ZEDQA rb dash only kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=93200 vol=1 preset=1 name=LBMW - Kentucky Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=89.4 Hitz FM; 5=94.2 USR]
ZEDQA rb prop visible=nil at nil,nil nilxnil vanilla window=false
ZEDQA rb premium off kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=93200 vol=1 preset=1 name=LBMW - Kentucky Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=89.4 Hitz FM; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb premium power via vanilla's action ok=true canBePoweredHere=true battery=0.8912599682807922
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
ZEDQA rb pickup restored kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=98400 vol=0.6000000238418579 preset=nil name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=false at 1828,1536 880x256 vanilla window=false
ZEDQA rb ham power via vanilla's action ok=true canBePoweredHere=true battery=0.9280699491500854
ZEDQA rb ham kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=1 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System; 2=93.2 LBMW - Kentucky Radio; 3=91.2 Civilian Radio]
ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
ZEDQA rb ham mic off kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=1 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=true
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System; 2=93.2 LBMW - Kentucky Radio; 3=91.2 Civilian Radio]
ZEDQA rb prop visible=true at 1708,1466 1000x326 vanilla window=false
ZEDQA rb mem -> 4
ZEDQA rb ham mem kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=146600 vol=1 preset=4 name=nil signal=false media=false playing=false title=nil flash=CH 04 STORED mic=false
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System; 2=93.2 LBMW - Kentucky Radio; 3=91.2 Civilian Radio; 4=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
ZEDQA rb siren opened; radio still up = false
ZEDQA rb fit Base.HamRadio2 ok=true nil
ZEDQA rb army kind=army item=Base.HamRadio2 on=true switch=true powered=true ch=98400 vol=1 preset=1 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System; 2=93.2 LBMW - Kentucky Radio; 3=91.2 Civilian Radio; 4=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1492 1000x300 vanilla window=false
ZEDQA rb fit Base.HamRadioMakeShift ok=true nil
ZEDQA rb hammake kind=hammake item=Base.HamRadioMakeShift on=true switch=true powered=true ch=98000 vol=1 preset=nil name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System; 2=93.2 LBMW - Kentucky Radio; 3=91.2 Civilian Radio; 4=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1516 1000x276 vanilla window=false
ZEDQA rb fit Base.HamRadio1 ok=true nil
ZEDQA rb police restored kind=ham item=Base.HamRadio1 on=false switch=false powered=true ch=107600 vol=1 preset=nil name=nil signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=98.4 Automated Emergency Broadcast System; 2=93.2 LBMW - Kentucky Radio; 3=91.2 Civilian Radio]
ZEDQA rb prop visible=false at 1708,1516 1000x276 vanilla window=false
ZEDQA rb DONE
```

### 84. zedqa_car_radio_cd.lua (`ZEDQA cd`) - PASS, 11 s

- go 21381 at 17:36:52
- screenshots: zqa_cd_c01_cdlist.png, zqa_cd_c02_cd_playing.png, zqa_cd_c03_ejected.png, zqa_cd_c04_valutech_tape.png

```text
[ZeD.QA] state #84 speed=1 paused=false player=927,13039 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cd start
[ZeD.QA] run #84 ok=true
ZEDQA cd spawned Base.PickUpTruck beside the character
ZEDQA cd pickup BaseVehicle{ Name:null, ID:294 } radio=Base.RadioBlack
ZEDQA cd hand font height 40
ZEDQA cd vanilla CD recordings: 69
ZEDQA cd cd isRecordedMedia=true mediaType=0 name=CD: Bible Readings - Revelation
ZEDQA cd cds carried: 0
ZEDQA cd inserted kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
ZEDQA cd play ok=false
ZEDQA cd playing kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
ZEDQA cd eject ok=false
ZEDQA cd ejected kind=valutech on=true ch=93200 media=false playing=false title=nil cdMs=nil
ZEDQA cd disc back in inventory: true
ZEDQA cd fit Base.RadioBlack
ZEDQA cd valutech kind=valutech on=false ch=101200 media=false playing=false title=nil cdMs=nil
ZEDQA cd fit Base.RadioRed
ZEDQA cd DONE
```

### 85. zedqa_dash_props_smoke.lua (`ZEDQA sm`) - PASS, 7 s

- go 21382 at 17:37:07
- screenshots: zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png

```text
[ZeD.QA] state #85 speed=1 paused=false player=921,13038 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home sm moved from 921,13038,0 to the drag strip
ZEDQA sm start
[ZeD.QA] run #85 ok=true
ZEDQA vp sm player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=929,13040 dist=3.5 chunk=true inMap=true car=Base.CarLightsKST at 929.0,13040.0 dist=3.5 vehicles=45
ZEDQA sm spawned Base.CarLightsPolice beside the character
ZEDQA sm pickup=true police=true
ZEDQA sm dash visible=true design=d6
ZEDQA sm radio up=true
ERROR: General f:114866 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:114872 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA sm siren up=true dash design=police
ZEDQA sm ham radio up=true
ZEDQA sm DONE
```

### 86. zedqa_tm.lua (`ZEDQA tm`) - PASS, 7 s

- go 21383 at 17:37:17
- screenshots: zedqa_tm_tooltips.png, zedqa_tm_maps.png, zedqa_tm_dash.png

```text
[ZeD.QA] state #86 speed=1 paused=false player=927,13039 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA tm armed
[ZeD.QA] run #86 ok=true
ZEDQA tm root=1.75 proxy=true realTM=true
ZEDQA tm tip1 462.78125x223.7421875 at 300,300 desc=349.78125x136.59375 lines=4 font=MainMenu1
ZEDQA tm tip2 420x194.890625 at 300,620 desc=367x194.890625 lines=6 font=MainMenu1
ZEDQA tm watch family=nil size=228x52 at 3596,10
ZEDQA tm maps tab clicked maps
ZEDQA tm world tabs loot,craft,build,furniture,maps,forage,animals,vehicle
ZEDQA tm maps shot active=maps win=1929,0 1617x735
ZEDQA vp tm player=927,13039 grid=19 chunks (152 tiles) loaded x 848-1000 y 12960-13112 sq=932,13041 dist=4.2 chunk=true inMap=true car=Base.SmallCar02 at 932.0,13041.0 dist=4.2 vehicles=45
ZEDQA tm dash design=horizon visible=true size=1600x356 at 1120,1804
ZEDQA tm done
```

### 87. zedqa_tour3.lua (`ZEDQA t3`) - PASS, 14 s

- go 21384 at 17:37:28
- screenshots: zedqa_t3_SmallCar02.png, zedqa_t3_ModernCar.png, zedqa_t3_ModernCar02.png, zedqa_t3_SUV.png, zedqa_t3_Van.png, zedqa_t3_PickUpVan.png, zedqa_t3_OffRoad.png

```text
[ZeD.QA] state #87 speed=1 paused=false player=930,13041 grid=19 inCar=false vehicles=34 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home t3 moved from 930,13041,0 to the drag strip
[ZeD.QA] run #87 ok=true
ZEDQA vp t3 player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=930,13042 dist=4.7 chunk=true inMap=true car=Base.SmallCar02 at 930.0,13042.0 dist=4.7 vehicles=45
ZEDQA t3 SmallCar02 design=horizon visible=true hits=21 badge=nil/nil cluster=nil
ZEDQA vp t3 player=928,13042 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=933,13044 dist=4.4 chunk=true inMap=true car=Base.ModernCar at 933.0,13044.0 dist=4.4 vehicles=34
ZEDQA t3 ModernCar design=dashelite visible=true hits=29 badge=nil/nil cluster=nil
ZEDQA vp t3 player=931,13043 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=936,13045 dist=4.3 chunk=true inMap=true car=Base.ModernCar02 at 936.0,13045.0 dist=4.3 vehicles=34
ZEDQA t3 ModernCar02 design=primani visible=true hits=26 badge=nil/nil cluster=nil
ZEDQA vp t3 player=934,13044 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=939,13046 dist=4.3 chunk=true inMap=true car=Base.SUV at 939.0,13046.0 dist=4.3 vehicles=34
ZEDQA t3 SUV design=suv visible=true hits=22 badge=nil/nil cluster=nil
ZEDQA vp t3 player=937,13045 grid=19 chunks (152 tiles) loaded x 864-1016 y 12968-13120 sq=942,13047 dist=4.4 chunk=true inMap=true car=Base.Van at 942.0,13047.0 dist=4.4 vehicles=25
ZEDQA t3 Van design=van visible=true hits=21 badge=nil/nil cluster=nil
ZEDQA vp t3 player=940,13046 grid=19 chunks (152 tiles) loaded x 864-1016 y 12968-13120 sq=945,13048 dist=4.5 chunk=true inMap=true car=Base.PickUpVan at 945.0,13048.0 dist=4.5 vehicles=25
ZEDQA t3 PickUpVan design=bulldriver visible=true hits=22 badge=nil/nil cluster=nil
ZEDQA vp t3 player=943,13047 grid=19 chunks (152 tiles) loaded x 864-1016 y 12968-13120 sq=948,13049 dist=4.3 chunk=true inMap=true car=Base.OffRoad at 948.0,13049.0 dist=4.3 vehicles=25
ZEDQA t3 OffRoad design=rancher visible=true hits=21 badge=nil/nil cluster=nil
ZEDQA t3 done
```

### 88. zedqa_dash19.lua (`ZEDQA dash`) - PASS, 72 s

- go 21385 at 17:37:45
- screenshots: zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png

```text
[ZeD.QA] state #88 speed=1 paused=false player=946,13049 grid=19 inCar=false vehicles=18 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home dash moved from 946,13049,0 to the drag strip
[ZeD.QA] run #88 ok=true
ZEDQA vp dash player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=930,13042 dist=4.7 chunk=true inMap=true car=Base.CarLuxury at 930.0,13042.0 dist=4.7 vehicles=28
ZEDQA dash 01_luxury design=luxury rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=928,13042 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=933,13044 dist=4.7 chunk=true inMap=true car=Base.CarNormal at 933.0,13044.0 dist=4.7 vehicles=34
ZEDQA dash 02_nyala design=nyala rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=931,13043 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=936,13045 dist=4.3 chunk=true inMap=true car=Base.SportsCar at 936.0,13045.0 dist=4.3 vehicles=34
ZEDQA dash 03_cossette design=cossette rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=934,13045 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=939,13047 dist=4.4 chunk=true inMap=true car=Base.CarLightsKST at 939.0,13047.0 dist=4.4 vehicles=34
ZEDQA dash 04_police design=police rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=937,13046 grid=19 chunks (152 tiles) loaded x 864-1016 y 12968-13120 sq=942,13048 dist=4.2 chunk=true inMap=true car=Base.PickUpTruck at 942.0,13048.0 dist=4.2 vehicles=25
ZEDQA dash 05_d6 design=d6 rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=940,13047 grid=19 chunks (152 tiles) loaded x 864-1016 y 12968-13120 sq=945,13049 dist=4.3 chunk=true inMap=true car=Base.ModernCar at 945.0,13049.0 dist=4.3 vehicles=25
ZEDQA dash 06_dashelite design=dashelite rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=943,13048 grid=19 chunks (152 tiles) loaded x 864-1016 y 12976-13128 sq=948,13050 dist=4.3 chunk=true inMap=true car=Base.ModernCar02 at 948.0,13050.0 dist=4.3 vehicles=25
ZEDQA dash 07_primani design=primani rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=946,13049 grid=19 chunks (152 tiles) loaded x 872-1024 y 12976-13128 sq=951,13051 dist=4.3 chunk=true inMap=true car=Base.SmallCar at 951.0,13051.0 dist=4.3 vehicles=18
ZEDQA dash 08_dart design=dart rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=949,13051 grid=19 chunks (152 tiles) loaded x 872-1024 y 12976-13128 sq=954,13053 dist=4.5 chunk=true inMap=true car=Base.SmallCar02 at 954.0,13053.0 dist=4.5 vehicles=18
ZEDQA dash 09_horizon design=horizon rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=952,13053 grid=19 chunks (152 tiles) loaded x 880-1032 y 12976-13128 sq=957,13055 dist=4.5 chunk=true inMap=true car=Base.CarStationWagon at 957.0,13055.0 dist=4.5 vehicles=19
ZEDQA dash 10_wagon design=wagon rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=955,13054 grid=19 chunks (152 tiles) loaded x 880-1032 y 12976-13128 sq=960,13056 dist=4.3 chunk=true inMap=true car=Base.SUV at 960.0,13056.0 dist=4.3 vehicles=19
ZEDQA dash 11_suv design=suv rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=958,13055 grid=19 chunks (152 tiles) loaded x 880-1032 y 12976-13128 sq=963,13057 dist=4.4 chunk=true inMap=true car=Base.Van at 963.0,13057.0 dist=4.4 vehicles=19
ZEDQA dash 12_van design=van rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=961,13056 grid=19 chunks (152 tiles) loaded x 888-1040 y 12984-13136 sq=966,13053 dist=5.4 chunk=true inMap=true car=Base.PickUpVan at 966.0,13053.0 dist=5.4 vehicles=26
ZEDQA dash 13_bulldriver car not ready in 36 ticks; removed, next square
ZEDQA vp dash player=961,13056 grid=19 chunks (152 tiles) loaded x 888-1040 y 12984-13136 sq=956,13058 dist=6.0 chunk=true inMap=true car=Base.PickUpVan at 956.0,13058.0 dist=6.0 vehicles=26
ZEDQA dash 13_bulldriver design=bulldriver rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=954,13057 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=959,13059 dist=4.2 chunk=true inMap=true car=Base.OffRoad at 959.0,13059.0 dist=4.2 vehicles=25
ZEDQA dash 14_rancher design=rancher rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=957,13059 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=962,13061 dist=4.3 chunk=true inMap=true car=Base.CarTaxi at 962.0,13061.0 dist=4.3 vehicles=25
ZEDQA dash 15_taxi design=taxi rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=960,13060 grid=19 chunks (152 tiles) loaded x 888-1040 y 12984-13136 sq=965,13062 dist=4.3 chunk=true inMap=true car=Base.VanAmbulance at 965.0,13062.0 dist=4.3 vehicles=26
ZEDQA dash 16_ambulance car not ready in 36 ticks; removed, next square
ZEDQA vp dash player=960,13060 grid=19 chunks (152 tiles) loaded x 888-1040 y 12984-13136 sq=955,13062 dist=6.1 chunk=true inMap=true car=Base.VanAmbulance at 955.0,13062.0 dist=6.1 vehicles=26
ZEDQA dash 16_ambulance design=ambulance rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=954,13061 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=959,13063 dist=4.9 chunk=true inMap=true car=Base.PickUpTruckLightsFire at 959.0,13063.0 dist=4.9 vehicles=25
ZEDQA dash 17_fire design=fire rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=957,13062 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=962,13064 dist=4.3 chunk=true inMap=true car=Base.CarLightsRanger at 962.0,13064.0 dist=4.3 vehicles=25
ZEDQA dash 18_ranger design=ranger rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA vp dash player=960,13063 grid=19 chunks (152 tiles) loaded x 888-1040 y 12984-13136 sq=965,13065 dist=4.2 chunk=true inMap=true car=Base.RaceCar12 at 965.0,13065.0 dist=4.2 vehicles=26
ZEDQA dash 19_race car not ready in 36 ticks; removed, next square
ERROR: General f:122810 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA vp dash player=960,13063 grid=19 chunks (152 tiles) loaded x 888-1040 y 12984-13136 sq=956,13059 dist=6.9 chunk=true inMap=true car=Base.RaceCar12 at 956.0,13059.0 dist=6.9 vehicles=26
ERROR: General f:122813 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dash 19_race design=race rect=1120,1804,1600,356 running=false radio=false heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash DONE
```

### 89. zedqa_dashpx.lua (`ZEDQA dpx`) - PASS, 128 s

- go 21386 at 17:39:01
- screenshots: zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_07_primani_keyon.png, zqa_dashpx_07_primani.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png, zqa_dashpx_14_rancher.png, zqa_dashpx_15_taxi_keyon.png, zqa_dashpx_15_taxi.png, zqa_dashpx_16_ambulance_keyon.png, zqa_dashpx_16_ambulance.png, zqa_dashpx_17_fire_keyon.png, zqa_dashpx_17_fire.png, zqa_dashpx_18_ranger_keyon.png, zqa_dashpx_18_ranger.png, zqa_dashpx_19_race_keyon.png, zqa_dashpx_19_race.png, zqa_dashpx_20_knoxvan_keyon.png, zqa_dashpx_20_knoxvan.png, zqa_dashpx_21_fossoild6_keyon.png, zqa_dashpx_21_fossoild6.png, zqa_dashpx_23_meadesheriff_keyon.png, zqa_dashpx_23_meadesheriff.png, zqa_dashpx_24_lcpd_keyon.png, zqa_dashpx_24_lcpd.png

```text
[ZeD.QA] state #89 speed=1 paused=false player=955,13059 grid=19 inCar=false vehicles=25 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home dpx moved from 955,13059,0 to the drag strip
[ZeD.QA] run #89 ok=true
ZEDQA vp dpx player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=930,13042 dist=4.7 chunk=true inMap=true car=Base.CarLuxury at 930.0,13042.0 dist=4.7 vehicles=16
ZEDQA dpx 01_luxury design=luxury rect=1120,1804,1600,356 k=2 running=false radio=true/premium heat=true lights=true name=MERCIA LANG 4000 livery= make=MERCIA model=LANG 4000 unit=MERCIA - UNIT 25 hits=27 screen=3840x2160
ZEDQA vp dpx player=928,13042 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=933,13044 dist=4.6 chunk=true inMap=true car=Base.CarNormal at 933.0,13044.0 dist=4.6 vehicles=34
ZEDQA dpx 02_nyala design=nyala rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=CHEVALIER NYALA livery= make=CHEVALIER model=NYALA unit=CHEVALIER - UNIT 25 hits=26 screen=3840x2160
ZEDQA vp dpx player=931,13043 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=936,13045 dist=4.3 chunk=true inMap=true car=Base.SportsCar at 936.0,13045.0 dist=4.3 vehicles=34
ZEDQA dpx 03_cossette design=cossette rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER COSSETTE livery= make=CHEVALIER model=COSSETTE unit=CHEVALIER - UNIT 25 hits=22 screen=3840x2160
ZEDQA vp dpx player=934,13045 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=939,13047 dist=4.4 chunk=true inMap=true car=Base.ModernCarLightsMeadeSheriff at 939.0,13047.0 dist=4.4 vehicles=34
ZEDQA dpx 04_police design=police rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=MEADE SHERIFF DASH ELITE livery=MEADE SHERIFF make=DASH model=ELITE unit=SHERIFF - UNIT 25 hits=19 screen=3840x2160
ZEDQA vp dpx player=937,13046 grid=19 chunks (152 tiles) loaded x 864-1016 y 12968-13120 sq=942,13048 dist=4.3 chunk=true inMap=true car=Base.PickUpTruck at 942.0,13048.0 dist=4.3 vehicles=25
ZEDQA dpx 05_d6 design=d6 rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER D6 livery= make=CHEVALIER model=D6 unit=CHEVALIER - UNIT 25 hits=22 screen=3840x2160
ZEDQA vp dpx player=940,13047 grid=19 chunks (152 tiles) loaded x 864-1016 y 12968-13120 sq=945,13049 dist=4.3 chunk=true inMap=true car=Base.ModernCar at 945.0,13049.0 dist=4.3 vehicles=25
ZEDQA dpx 06_dashelite design=dashelite rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=DASH ELITE livery= make=DASH model=ELITE unit=DASH - UNIT 25 hits=29 screen=3840x2160
ZEDQA vp dpx player=943,13048 grid=19 chunks (152 tiles) loaded x 864-1016 y 12976-13128 sq=948,13050 dist=4.3 chunk=true inMap=true car=Base.ModernCar02 at 948.0,13050.0 dist=4.3 vehicles=25
ZEDQA dpx 07_primani design=primani rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=CHEVALIER PRIMANI livery= make=CHEVALIER model=PRIMANI unit=CHEVALIER - UNIT 25 hits=26 screen=3840x2160
ZEDQA vp dpx player=946,13049 grid=19 chunks (152 tiles) loaded x 872-1024 y 12976-13128 sq=951,13051 dist=4.4 chunk=true inMap=true car=Base.SmallCar at 951.0,13051.0 dist=4.4 vehicles=18
ZEDQA dpx 08_dart design=dart rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER DART livery= make=CHEVALIER model=DART unit=CHEVALIER - UNIT 25 hits=21 screen=3840x2160
ZEDQA vp dpx player=949,13051 grid=19 chunks (152 tiles) loaded x 872-1024 y 12976-13128 sq=954,13053 dist=4.4 chunk=true inMap=true car=Base.SmallCar02 at 954.0,13053.0 dist=4.4 vehicles=18
ZEDQA dpx 09_horizon design=horizon rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=MASTERSON HORIZON livery= make=MASTERSON model=HORIZON unit=MASTERSON - UNIT 25 hits=21 screen=3840x2160
ZEDQA vp dpx player=952,13052 grid=19 chunks (152 tiles) loaded x 880-1032 y 12976-13128 sq=957,13054 dist=4.2 chunk=true inMap=true car=Base.CarStationWagon at 957.0,13054.0 dist=4.2 vehicles=19
ZEDQA dpx 10_wagon design=wagon rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER CERISE WAGON livery= make=CHEVALIER model=CERISE WAGON unit=CHEVALIER - UNIT 25 hits=22 screen=3840x2160
ZEDQA vp dpx player=955,13053 grid=19 chunks (152 tiles) loaded x 880-1032 y 12976-13128 sq=960,13055 dist=4.3 chunk=true inMap=true car=Base.SUV at 960.0,13055.0 dist=4.3 vehicles=19
ZEDQA dpx 11_suv design=suv rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=FRANKLIN ALL-TERRAIN livery= make=FRANKLIN model=ALL-TERRAIN unit=FRANKLIN - UNIT 25 hits=22 screen=3840x2160
ZEDQA vp dpx player=958,13054 grid=19 chunks (152 tiles) loaded x 880-1032 y 12976-13128 sq=963,13056 dist=4.4 chunk=true inMap=true car=Base.VanSpiffo at 963.0,13056.0 dist=4.4 vehicles=19
ZEDQA dpx 12_van design=van rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=SPIFFO VAN livery=SPIFFO VAN make=FRANKLIN model=VALULINE unit=SPIFFO - UNIT 25 hits=21 screen=3840x2160
ZEDQA vp dpx player=961,13055 grid=19 chunks (152 tiles) loaded x 888-1040 y 12976-13128 sq=966,13052 dist=5.3 chunk=true inMap=true car=Base.PickUpVan at 966.0,13052.0 dist=5.3 vehicles=20
ZEDQA dpx 13_bulldriver car not ready in 36 ticks; removed, next square
ZEDQA vp dpx player=961,13055 grid=19 chunks (152 tiles) loaded x 888-1040 y 12976-13128 sq=956,13057 dist=6.1 chunk=true inMap=true car=Base.PickUpVan at 956.0,13057.0 dist=6.1 vehicles=20
ZEDQA dpx 13_bulldriver design=bulldriver rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=DASH BULLDRIVER livery= make=DASH model=BULLDRIVER unit=DASH - UNIT 25 hits=22 screen=3840x2160
ZEDQA vp dpx player=954,13056 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=959,13058 dist=4.3 chunk=true inMap=true car=Base.OffRoad at 959.0,13058.0 dist=4.3 vehicles=25
ZEDQA dpx 14_rancher design=rancher rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=DASH RANCHER livery= make=DASH model=RANCHER unit=DASH - UNIT 25 hits=21 screen=3840x2160
ZEDQA vp dpx player=957,13058 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=962,13060 dist=4.5 chunk=true inMap=true car=Base.CarTaxi at 962.0,13060.0 dist=4.5 vehicles=25
ZEDQA dpx 15_taxi design=taxi rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=TAXI livery=TAXI make=CHEVALIER model=NYALA unit=TAXI - CAB 25 hits=22 screen=3840x2160
ZEDQA vp dpx player=960,13059 grid=19 chunks (152 tiles) loaded x 888-1040 y 12984-13136 sq=965,13061 dist=4.3 chunk=true inMap=true car=Base.VanAmbulance at 965.0,13061.0 dist=4.3 vehicles=26
ZEDQA dpx 16_ambulance car not ready in 36 ticks; removed, next square
ZEDQA vp dpx player=960,13059 grid=19 chunks (152 tiles) loaded x 888-1040 y 12984-13136 sq=955,13061 dist=5.9 chunk=true inMap=true car=Base.VanAmbulance at 955.0,13061.0 dist=5.9 vehicles=26
ZEDQA dpx 16_ambulance design=ambulance rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=AMBULANCE livery=AMBULANCE make=FRANKLIN model=VALULINE unit=AMBULANCE - UNIT 25 hits=19 screen=3840x2160
ZEDQA vp dpx player=953,13060 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=958,13057 dist=5.2 chunk=true inMap=true car=Base.PickUpTruckLightsFire at 958.0,13057.0 dist=5.2 vehicles=25
ZEDQA dpx 17_fire design=fire rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=FIRE DEPARTMENT CHEVALIER D6 livery=FIRE DEPARTMENT make=CHEVALIER model=D6 unit=FIRE - ENGINE 25 hits=19 screen=3840x2160
ZEDQA vp dpx player=956,13056 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=961,13058 dist=4.3 chunk=true inMap=true car=Base.CarLightsRanger at 961.0,13058.0 dist=4.3 vehicles=25
ZEDQA dpx 18_ranger design=ranger rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=RANGER CHEVALIER NYALA livery=RANGER make=CHEVALIER model=NYALA unit=RANGER - UNIT 25 hits=19 screen=3840x2160
ZEDQA vp dpx player=959,13057 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=964,13059 dist=4.2 chunk=true inMap=true car=Base.RaceCar12 at 964.0,13059.0 dist=4.2 vehicles=25
ZEDQA dpx 19_race car not ready in 36 ticks; removed, next square
ZEDQA vp dpx player=959,13057 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=964,13054 dist=5.4 chunk=true inMap=true car=Base.RaceCar12 at 964.0,13054.0 dist=5.4 vehicles=25
ZEDQA dpx 19_race car not ready in 36 ticks; removed, next square
ERROR: General f:130526 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA vp dpx player=959,13057 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=961,13062 dist=4.4 chunk=true inMap=true car=Base.RaceCar12 at 961.0,13062.0 dist=4.4 vehicles=25
ERROR: General f:130529 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dpx 19_race design=race rect=1120,1804,1600,356 k=2 running=true radio=false/nil heat=true lights=true name=RACE CAR livery=RACE CAR make=RACE model=CAR unit=RACE - UNIT 25 hits=5 screen=3840x2160
ZEDQA vp dpx player=960,13061 grid=19 chunks (152 tiles) loaded x 888-1040 y 12984-13136 sq=965,13063 dist=5.0 chunk=true inMap=true car=Base.Van_KnoxDisti at 965.0,13063.0 dist=5.0 vehicles=26
ZEDQA dpx 20_knoxvan car not ready in 36 ticks; removed, next square
ZEDQA vp dpx player=960,13061 grid=19 chunks (152 tiles) loaded x 888-1040 y 12984-13136 sq=962,13066 dist=4.6 chunk=true inMap=true car=Base.Van_KnoxDisti at 962.0,13066.0 dist=4.6 vehicles=26
ZEDQA dpx 20_knoxvan design=van rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=KNOX DISTILLERY FRANKLIN VALULINE livery=KNOX DISTILLERY make=FRANKLIN model=VALULINE unit=KNOX - UNIT 25 hits=25 screen=3840x2160
ZEDQA vp dpx player=960,13064 grid=19 chunks (152 tiles) loaded x 888-1040 y 12992-13144 sq=965,13066 dist=4.4 chunk=true inMap=true car=Base.PickUpTruckLightsFossoil at 965.0,13066.0 dist=4.4 vehicles=32
ZEDQA dpx 21_fossoild6 car not ready in 36 ticks; removed, next square
ZEDQA vp dpx player=960,13064 grid=19 chunks (152 tiles) loaded x 888-1040 y 12992-13144 sq=965,13061 dist=5.8 chunk=true inMap=true car=Base.PickUpTruckLightsFossoil at 965.0,13061.0 dist=5.8 vehicles=32
ZEDQA dpx 21_fossoild6 car not ready in 36 ticks; removed, next square
ZEDQA vp dpx player=960,13064 grid=19 chunks (152 tiles) loaded x 888-1040 y 12992-13144 sq=956,13060 dist=6.9 chunk=true inMap=true car=Base.PickUpTruckLightsFossoil at 956.0,13060.0 dist=6.9 vehicles=32
ZEDQA dpx 21_fossoild6 design=d6 rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=CHEVALIER D6 livery= make=CHEVALIER model=D6 unit=CHEVALIER - UNIT 25 hits=19 screen=3840x2160
ZEDQA vp dpx player=954,13059 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=959,13061 dist=4.3 chunk=true inMap=true car=Base.CarNormalSmashedFront at 959.0,13061.0 dist=4.3 vehicles=25
ZEDQA dpx 22_wreckednyala could not enter Base.CarNormalSmashedFront (enter=false seat0 installed=false)
ZEDQA vp dpx player=954,13059 grid=19 chunks (152 tiles) loaded x 880-1032 y 12984-13136 sq=959,13056 dist=5.6 chunk=true inMap=true car=Base.ModernCarLightsMeadeSheriff at 959.0,13056.0 dist=5.6 vehicles=26
ZEDQA dpx 23_meadesheriff design=police rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=MEADE SHERIFF DASH ELITE livery=MEADE SHERIFF make=DASH model=ELITE unit=SHERIFF - UNIT 71 hits=19 screen=3840x2160
ZEDQA vp dpx player=957,13055 grid=19 chunks (152 tiles) loaded x 880-1032 y 12976-13128 sq=962,13057 dist=4.3 chunk=true inMap=true car=Base.CarLightsLouisvilleCounty at 962.0,13057.0 dist=4.3 vehicles=20
ZEDQA dpx 24_lcpd design=police rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=LCPD CHEVALIER NYALA livery=LCPD make=CHEVALIER model=NYALA unit=LCPD - UNIT 71 hits=19 screen=3840x2160
ZEDQA dpx DONE
```

### 90. zedqa_exinfo.lua (`ZEDQA ex`) - PASS, 8 s

- go 21387 at 17:41:13
- screenshots: zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_menu.png, zqa_ex_situp.png

```text
[ZeD.QA] state #90 speed=1 paused=false player=960,13056 grid=19 inCar=false vehicles=27 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ex start
[ZeD.QA] run #90 ok=true
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
ZEDQA ex ok block describes the picked exercise (squats)
ZEDQA ex ok room reserved
ZEDQA ex ok block follows the pick (barbell curl)
ZEDQA ex ok same reserved height for another exercise
ZEDQA ex ok band stops: exercise box
ZEDQA ex ok band stops: - and +
ZEDQA ex ok band stops: Start
ZEDQA ex ok no exercise-button stops left
ZEDQA ex ok pop-up open
ZEDQA ex ok pop-up lists the seven exercises
ZEDQA ex ok rows are the stops while open
ZEDQA ex ok the list opens on the chosen row (barbell curl; on health:menuRow:barbellcurl)
ZEDQA ex ok the list outlives the screenshot
ZEDQA ex ok the open list is modal (its rows alone, marked)
ZEDQA ex ok Up stops on the first row (health:menuRow:squats)
ZEDQA ex ok Down stops on the last row, the list still open (health:menuRow:bicepscurl)
ZEDQA ex ok Left and Right do nothing in the list
ZEDQA ex ok nothing below the last row (the preview stays in the list)
ZEDQA ex ok B shuts the list, the choice unchanged
ZEDQA ex ok B: the focus is back on the box (health:exercise)
ZEDQA ex ok open again
ZEDQA ex ok pick shut the list and changed the choice
ZEDQA ex ok focus is back on the box
ZEDQA ex ok block follows the pick (burpees)
ZEDQA ex ok + steps the time by 10
ZEDQA ex ok - steps it back
ZEDQA ex ok time keys change no choice
ZEDQA ex ok block follows the pick (situp)
ZEDQA ex DONE
```

### 91. zedqa_charinfo.lua (`ZEDQA ci`) - PASS, 9 s

- go 21388 at 17:41:24

```text
[ZeD.QA] state #91 speed=1 paused=false player=960,13056 grid=19 inCar=false vehicles=27 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ci start
[ZeD.QA] run #91 ok=true
ZEDQA ci PASS the game's Character Info window is hidden at 3840x2160 (as the game started)
ZEDQA ci PASS its saved layout says hidden while ZeD is on (visible=false)
ZEDQA ci PASS its start-up flag is off (false)
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

### 92. zedqa_equipdrag.lua (`ZEDQA eqd`) - PASS, 13 s

- go 21389 at 17:41:37
- screenshots: zqa_eqd_1.png, zqa_eqd_2.png, zqa_eqd_3.png, zqa_eqd_4.png

```text
[ZeD.QA] state #92 speed=1 paused=false player=960,13056 grid=19 inCar=false vehicles=27 missing=get
[ZeD.QA] windows reset (R)
ZEDQA eqd start
[ZeD.QA] run #92 ok=true
ZEDQA eqd list slots {HAT,OUT,INR,GLV,PNT,SOC,BOT,PRI,BLT}
ZEDQA eqd worn {base:belt=Belt2,base:hat=Hat_BaseballCapBlue,base:tshirt=Tshirt_DefaultTEXTURE_TINT,base:hands=Gloves_LeatherGlovesBlack,base:socks=Socks_Heavy,base:shoes=Shoes_ArmyBoots,base:pants=Trousers_Denim,base:jacket=Jacket_Varsity} cap Clothing{ clothingItemName="Hat_BaseballCapBlue" } jacket Clothing{ clothingItemName="Jacket_Varsity" } pri Base.Hammer:zombie.inventory.types.HandWeapon@21e5622b | tab equip listExp true view list
ZEDQA eqd PASS rows for cap, jacket, hammer
ZEDQA eqd PASS press waits (pending, nothing selected yet)
ZEDQA eqd PASS click selects the row | HAT
ZEDQA eqd PASS moved press is the drag
ZEDQA eqd PASS ISMouseDrag carries the item
ZEDQA eqd PASS draggedItem names it
ZEDQA eqd PASS release on the Equip tab: drag over, nothing queued, cap still worn | queue 0
ZEDQA eqd PASS drag started on the jacket
ZEDQA eqd PASS right press cancels it
ZEDQA eqd doll slots {doll:head,doll:torso,doll:outer,doll:hands,doll:belt,doll:legs,doll:feet,doll:main,doll:belt1}
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

### 93. zedqa_cazio_light.lua (`ZEDQA czl`) - PASS, 31 s

- go 21390 at 17:41:54
- screenshots: zqa_cl_day_DigitalBlack.png, zqa_cl_daylit_DigitalBlack.png, zqa_cl_night_DigitalBlack.png, zqa_cl_nightlit_DigitalBlack.png, zqa_cl_day_DigitalDress.png, zqa_cl_daylit_DigitalDress.png, zqa_cl_night_DigitalDress.png, zqa_cl_nightlit_DigitalDress.png, zqa_cl_day_ClassicBlack.png, zqa_cl_daylit_ClassicBlack.png, zqa_cl_night_ClassicBlack.png, zqa_cl_nightlit_ClassicBlack.png, zqa_cl_day_ClassicGold.png, zqa_cl_daylit_ClassicGold.png, zqa_cl_night_ClassicGold.png, zqa_cl_nightlit_ClassicGold.png, zqa_cl_belt_night.png, zqa_cl_belt_nightlit.png, zqa_cl_belt_day.png, zqa_cl_belt_daylit.png

```text
[ZeD.QA] state #93 speed=1 paused=false player=960,13056 grid=19 inCar=false vehicles=27 missing=get
[ZeD.QA] windows reset (R)
ZEDQA czl start
[ZeD.QA] run #93 ok=true
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
ZEDQA czl timer pressed at 1793929334471
ZEDQA czl light out after 3017 ms; lit=false bulb=false dark=true
ZEDQA czl Expensive light control false
ZEDQA czl Expensive after a stray light press: lit=false bulb=false dark=true
ZEDQA czl belt watch box 1
ZEDQA czl belt mini after Y: lit=true night=true dark=false
ZEDQA czl restored own watch nil
ZEDQA czl DONE
```

### 94. zedqa_dashnight.lua (`ZEDQA dnt`) - PASS, 129 s

- go 21391 at 17:42:27
- screenshots: zqa_dashnight_wagon_real.png, zqa_dashnight_wagon_day.png, zqa_dashnight_wagon_dusk.png, zqa_dashnight_wagon_night.png, zqa_dashnight_wagon_nightoff.png, zqa_dashnight_wagon_real_noon.png, zqa_dashnight_wagon_real_back_on.png, zqa_dashnight_wagon_real_back_off.png, zqa_dashnight_nyala_real.png, zqa_dashnight_nyala_day.png, zqa_dashnight_nyala_dusk.png, zqa_dashnight_nyala_night.png, zqa_dashnight_nyala_nightoff.png, zqa_dashnight_dashelite_real.png, zqa_dashnight_dashelite_day.png, zqa_dashnight_dashelite_dusk.png, zqa_dashnight_dashelite_night.png, zqa_dashnight_dashelite_nightoff.png, zqa_dashnight_luxury_real.png, zqa_dashnight_luxury_day.png, zqa_dashnight_luxury_dusk.png, zqa_dashnight_luxury_night.png, zqa_dashnight_luxury_nightoff.png, zqa_dashnight_ambulance_real.png, zqa_dashnight_ambulance_day.png, zqa_dashnight_ambulance_dusk.png, zqa_dashnight_ambulance_night.png, zqa_dashnight_ambulance_nightoff.png, zqa_dashnight_race_real.png, zqa_dashnight_race_day.png, zqa_dashnight_race_dusk.png, zqa_dashnight_race_night.png, zqa_dashnight_race_nightoff.png, zqa_dashnight_d6_real.png, zqa_dashnight_d6_day.png, zqa_dashnight_d6_dusk.png, zqa_dashnight_d6_night.png, zqa_dashnight_d6_nightoff.png

```text
[ZeD.QA] state #94 speed=1 paused=false player=960,13056 grid=19 inCar=false vehicles=27 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home dnt moved from 960,13056,0 to the drag strip
[ZeD.QA] run #94 ok=true
ZEDQA vp dnt player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=930,13042 dist=4.7 chunk=true inMap=true car=Base.CarStationWagon at 930.0,13042.0 dist=4.7 vehicles=39
ZEDQA dnt wagon real design=wagon lux=1.000 smooth=1.000 n8=0 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=18.83
ZEDQA dnt wagon day design=wagon lux=1.000 smooth=1.000 n8=0 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=18.84
ZEDQA dnt wagon dusk design=wagon lux=1.000 smooth=1.000 n8=4 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=18.84
ZEDQA dnt wagon night design=wagon lux=1.000 smooth=1.000 n8=8 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=18.85
ZEDQA dnt wagon nightoff design=wagon lux=1.000 smooth=1.000 n8=8 lit=false over=dash_wagon_dark lights=true dashLit=true k=2 hour=18.85
ZEDQA dnt wagon real_noon design=wagon lux=1.000 smooth=1.000 n8=0 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=13.03
ZEDQA dnt wagon real_back_on design=wagon lux=1.000 smooth=1.000 n8=0 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=18.84
ZEDQA dnt wagon real_back_off design=wagon lux=1.000 smooth=1.000 n8=0 lit=false over=dash_wagon_dark lights=false dashLit=false k=2 hour=18.85
ZEDQA vp dnt player=928,13041 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=933,13043 dist=4.3 chunk=true inMap=true car=Base.CarNormal at 933.0,13043.0 dist=4.3 vehicles=35
ZEDQA dnt nyala real design=nyala lux=1.000 smooth=1.000 n8=0 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=18.88
ZEDQA dnt nyala day design=nyala lux=1.000 smooth=1.000 n8=0 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=18.88
ZEDQA dnt nyala dusk design=nyala lux=1.000 smooth=1.000 n8=4 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=18.88
ZEDQA dnt nyala night design=nyala lux=1.000 smooth=1.000 n8=8 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=18.89
ZEDQA dnt nyala nightoff design=nyala lux=1.000 smooth=1.000 n8=8 lit=false over=dash_nyala_dark lights=true dashLit=true k=2 hour=18.89
ZEDQA vp dnt player=931,13042 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=936,13044 dist=4.3 chunk=true inMap=true car=Base.ModernCar at 936.0,13044.0 dist=4.3 vehicles=35
ZEDQA dnt dashelite real design=dashelite lux=1.000 smooth=1.000 n8=0 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=18.92
ZEDQA dnt dashelite day design=dashelite lux=1.000 smooth=1.000 n8=0 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=18.92
ZEDQA dnt dashelite dusk design=dashelite lux=1.000 smooth=1.000 n8=4 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=18.93
ZEDQA dnt dashelite night design=dashelite lux=1.000 smooth=1.000 n8=8 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=18.93
ZEDQA dnt dashelite nightoff design=dashelite lux=1.000 smooth=1.000 n8=8 lit=false over=dash_dashelite_dark lights=true dashLit=true k=2 hour=18.94
ZEDQA vp dnt player=934,13043 grid=19 chunks (152 tiles) loaded x 856-1008 y 12968-13120 sq=939,13045 dist=4.3 chunk=true inMap=true car=Base.CarLuxury at 939.0,13045.0 dist=4.3 vehicles=35
ZEDQA dnt luxury real design=luxury lux=1.000 smooth=1.000 n8=0 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=18.96
ZEDQA dnt luxury day design=luxury lux=1.000 smooth=1.000 n8=0 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=18.96
ZEDQA dnt luxury dusk design=luxury lux=1.000 smooth=1.000 n8=4 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=18.97
ZEDQA dnt luxury night design=luxury lux=1.000 smooth=1.000 n8=8 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=18.97
ZEDQA dnt luxury nightoff design=luxury lux=1.000 smooth=1.000 n8=8 lit=false over=dash_luxury_dark lights=true dashLit=true k=2 hour=18.97
ZEDQA vp dnt player=937,13045 grid=19 chunks (152 tiles) loaded x 864-1016 y 12968-13120 sq=942,13047 dist=4.5 chunk=true inMap=true car=Base.VanAmbulance at 942.0,13047.0 dist=4.5 vehicles=26
ZEDQA dnt ambulance real design=ambulance lux=1.000 smooth=1.000 n8=0 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=19.00
ZEDQA dnt ambulance day design=ambulance lux=1.000 smooth=1.000 n8=0 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=19.01
ZEDQA dnt ambulance dusk design=ambulance lux=1.000 smooth=1.000 n8=4 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=19.01
ZEDQA dnt ambulance night design=ambulance lux=1.000 smooth=1.000 n8=8 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=19.01
ZEDQA dnt ambulance nightoff design=ambulance lux=1.000 smooth=1.000 n8=8 lit=false over=dash_ambulance_dark lights=true dashLit=true k=2 hour=19.02
ERROR: General f:142029 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA vp dnt player=940,13046 grid=19 chunks (152 tiles) loaded x 864-1016 y 12968-13120 sq=945,13048 dist=4.5 chunk=true inMap=true car=Base.RaceCar12 at 945.0,13048.0 dist=4.5 vehicles=26
ERROR: General f:142032 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dnt race real design=race lux=1.000 smooth=1.000 n8=0 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=19.05
ZEDQA dnt race day design=race lux=1.000 smooth=1.000 n8=0 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=19.05
ZEDQA dnt race dusk design=race lux=1.000 smooth=1.000 n8=4 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=19.05
ZEDQA dnt race night design=race lux=1.000 smooth=1.000 n8=8 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=19.06
ZEDQA dnt race nightoff design=race lux=1.000 smooth=1.000 n8=8 lit=false over=dash_race_dark lights=true dashLit=true k=2 hour=19.06
ZEDQA vp dnt player=944,13047 grid=19 chunks (152 tiles) loaded x 872-1024 y 12968-13120 sq=949,13049 dist=5.0 chunk=true inMap=true car=Base.PickUpTruck at 949.0,13049.0 dist=5.0 vehicles=18
ZEDQA dnt d6 real design=d6 lux=1.000 smooth=1.000 n8=0 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=19.09
ZEDQA dnt d6 day design=d6 lux=1.000 smooth=1.000 n8=0 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=19.10
ZEDQA dnt d6 dusk design=d6 lux=1.000 smooth=1.000 n8=4 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=19.10
ZEDQA dnt d6 night design=d6 lux=1.000 smooth=1.000 n8=8 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=19.10
ZEDQA dnt d6 nightoff design=d6 lux=1.000 smooth=1.000 n8=8 lit=false over=dash_d6_dark lights=true dashLit=true k=2 hour=19.11
ZEDQA dnt DONE
```

### 95. zedqa_dash_green.lua (`ZEDQA dgr`) - PASS, 113 s

- go 21392 at 17:44:40
- screenshots: zqa_dgr_d6_parked_day.png, zqa_dgr_d6_parked_day_keyin.png, zqa_dgr_fire_at_speed.png, zqa_dgr_dashelite_night_on.png, zqa_dgr_dashelite_night_off.png, zqa_dgr_primani_night_on.png, zqa_dgr_primani_night_off.png, zqa_dgr_suv_night_on.png, zqa_dgr_suv_night_off.png, zqa_dgr_luxury_night_on.png, zqa_dgr_luxury_night_off.png, zqa_dgr_cossette_night_on.png, zqa_dgr_cossette_night_off.png

```text
[ZeD.QA] state #95 speed=1 paused=false player=947,13048 grid=19 inCar=false vehicles=19 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home dgr moved from 947,13048,0 to the drag strip
[ZeD.QA] run #95 ok=true
ZEDQA vp dgr player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=920,13042 dist=5.7 chunk=true inMap=true car=Base.PickUpTruck at 920.0,13042.0 dist=5.7 vehicles=46
ZEDQA dgr d6 speedometer pivot 240,96 r1=60 a0=210 a1=330
ZEDQA dgr shot d6_parked_day design=d6 rect=1120,1804,1600,356 k=2 n8=0 lit=false tmap=false needleOwn=nil lights=false running=false kmh=0.0 mph=0.0
ZEDQA dgr shot d6_parked_day_keyin design=d6 rect=1120,1804,1600,356 k=2 n8=0 lit=false tmap=false needleOwn=nil lights=false running=false kmh=0.0 mph=0.0
ZEDQA vp dgr player=918,13041 grid=19 chunks (152 tiles) loaded x 840-992 y 12968-13120 sq=913,13043 dist=5.2 chunk=true inMap=true car=Base.PickUpTruckLightsFire at 913.0,13043.0 dist=5.2 vehicles=56
ZEDQA dgr fire drive t=1 push=100 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=2 push=200 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=3 push=400 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=4 push=800 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=5 push=1600 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=6 push=3200 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=7 push=6400 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=8 push=12800 kmh=2.0 mph=1.3
ZEDQA dgr fire drive t=9 push=25600 kmh=12.3 mph=7.7
ZEDQA dgr fire drive t=10 push=25600 kmh=36.6 mph=22.8
ZEDQA dgr fire drive t=11 push=25600 kmh=62.0 mph=38.6
ZEDQA dgr shot fire_at_speed design=fire rect=1120,1804,1600,356 k=2 n8=0 lit=false tmap=false needleOwn=nil lights=false running=true kmh=63.4 mph=39.4
ZEDQA dgr fire drove: max 63.4 km/h
ZEDQA vp dgr player=912,13003 grid=19 chunks (152 tiles) loaded x 840-992 y 12928-13080 sq=914,13008 dist=4.7 chunk=true inMap=true car=Base.ModernCar at 914.0,13008.0 dist=4.7 vehicles=39
ZEDQA dgr shot dashelite_night_on design=dashelite rect=1120,1804,1600,356 k=2 n8=8 lit=true tmap=true needleOwn=true lights=true running=true kmh=0.0 mph=0.0
ZEDQA dgr shot dashelite_night_off design=dashelite rect=1120,1804,1600,356 k=2 n8=8 lit=false tmap=true needleOwn=true lights=false running=true kmh=0.0 mph=0.0
ZEDQA vp dgr player=912,13007 grid=19 chunks (152 tiles) loaded x 840-992 y 12928-13080 sq=917,13009 dist=4.3 chunk=true inMap=true car=Base.ModernCar02 at 917.0,13009.0 dist=4.3 vehicles=39
ERROR: General f:147437 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dgr shot primani_night_on design=primani rect=1120,1804,1600,356 k=2 n8=8 lit=true tmap=true needleOwn=true lights=true running=true kmh=0.0 mph=0.0
ZEDQA dgr shot primani_night_off design=primani rect=1120,1804,1600,356 k=2 n8=8 lit=false tmap=true needleOwn=true lights=false running=true kmh=0.0 mph=0.0
ZEDQA vp dgr player=915,13008 grid=19 chunks (152 tiles) loaded x 840-992 y 12936-13088 sq=920,13005 dist=5.6 chunk=true inMap=true car=Base.SUV at 920.0,13005.0 dist=5.6 vehicles=46
ZEDQA dgr shot suv_night_on design=suv rect=1120,1804,1600,356 k=2 n8=8 lit=true tmap=true needleOwn=true lights=true running=true kmh=0.0 mph=0.0
ZEDQA dgr shot suv_night_off design=suv rect=1120,1804,1600,356 k=2 n8=8 lit=false tmap=true needleOwn=true lights=false running=true kmh=0.0 mph=0.0
ZEDQA vp dgr player=917,13005 grid=19 chunks (152 tiles) loaded x 840-992 y 12928-13080 sq=912,13007 dist=5.9 chunk=true inMap=true car=Base.CarLuxury at 912.0,13007.0 dist=5.9 vehicles=39
ZEDQA dgr shot luxury_night_on design=luxury rect=1120,1804,1600,356 k=2 n8=8 lit=true tmap=true needleOwn=true lights=true running=true kmh=0.0 mph=0.0
ZEDQA dgr shot luxury_night_off design=luxury rect=1120,1804,1600,356 k=2 n8=8 lit=false tmap=true needleOwn=true lights=false running=true kmh=0.0 mph=0.0
ZEDQA vp dgr player=910,13007 grid=19 chunks (152 tiles) loaded x 832-984 y 12928-13080 sq=912,13012 dist=4.7 chunk=true inMap=true car=Base.SportsCar at 912.0,13012.0 dist=4.7 vehicles=41
ERROR: General f:150416 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dgr shot cossette_night_on design=cossette rect=1120,1804,1600,356 k=2 n8=8 lit=true tmap=true needleOwn=nil lights=true running=true kmh=0.0 mph=0.0
ZEDQA dgr shot cossette_night_off design=cossette rect=1120,1804,1600,356 k=2 n8=8 lit=false tmap=true needleOwn=nil lights=false running=true kmh=0.0 mph=0.0
ZEDQA dgr PASS
ZEDQA dgr DONE
```

### 96. zedqa_dash_keys_edge.lua (`ZEDQA dke`) - WARN, 269 s

- go 21393 at 17:46:37
- 6 ERR line(s)
- screenshots: zqa_dke_luxury_off.png, zqa_dke_luxury_start.png, zqa_dke_luxury_on.png, zqa_dke_nyala_off.png, zqa_dke_nyala_start.png, zqa_dke_nyala_on.png, zqa_dke_cossette_off.png, zqa_dke_cossette_start.png, zqa_dke_cossette_on.png, zqa_dke_police_off.png, zqa_dke_police_start.png, zqa_dke_police_on.png, zqa_dke_d6_off.png, zqa_dke_d6_start.png, zqa_dke_d6_on.png, zqa_dke_dashelite_off.png, zqa_dke_dashelite_start.png, zqa_dke_dashelite_on.png, zqa_dke_primani_off.png, zqa_dke_primani_start.png, zqa_dke_primani_on.png, zqa_dke_dart_off.png, zqa_dke_dart_start.png, zqa_dke_dart_on.png, zqa_dke_horizon_off.png, zqa_dke_horizon_start.png, zqa_dke_horizon_on.png, zqa_dke_wagon_off.png, zqa_dke_wagon_on.png, zqa_dke_suv_off.png, zqa_dke_suv_on.png, zqa_dke_van_off.png, zqa_dke_van_start.png, zqa_dke_van_on.png, zqa_dke_bulldriver_off.png, zqa_dke_bulldriver_start.png, zqa_dke_bulldriver_on.png, zqa_dke_rancher_off.png, zqa_dke_rancher_start.png, zqa_dke_rancher_on.png, zqa_dke_taxi_off.png, zqa_dke_taxi_on.png, zqa_dke_ambulance_off.png, zqa_dke_ambulance_start.png, zqa_dke_ambulance_on.png, zqa_dke_fire_off.png, zqa_dke_fire_start.png, zqa_dke_fire_on.png, zqa_dke_ranger_off.png, zqa_dke_ranger_start.png, zqa_dke_ranger_on.png, zqa_dke_race_off.png, zqa_dke_race_start.png, zqa_dke_race_on.png

```text
[ZeD.QA] state #96 speed=1 paused=false player=911,13012 grid=19 inCar=false vehicles=48 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home dke moved from 911,13012,0 to the drag strip
[ZeD.QA] run #96 ok=true
ZEDQA vp dke player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=920,13042 dist=5.7 chunk=true inMap=true car=Base.CarLuxury at 920.0,13042.0 dist=5.7 vehicles=46
ZEDQA dke shot luxury_off design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot luxury_start design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot luxury_on design=luxury rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=917,13042 grid=19 chunks (152 tiles) loaded x 840-992 y 12968-13120 sq=912,13044 dist=6.0 chunk=true inMap=true car=Base.CarNormal at 912.0,13044.0 dist=6.0 vehicles=56
ZEDQA dke shot nyala_off design=nyala rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot nyala_start design=nyala rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot nyala_on design=nyala rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=910,13043 grid=19 chunks (152 tiles) loaded x 832-984 y 12968-13120 sq=912,13048 dist=4.2 chunk=true inMap=true car=Base.SportsCar at 912.0,13048.0 dist=4.2 vehicles=58
ZEDQA dke shot cossette_off design=cossette rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot cossette_start design=cossette rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot cossette_on design=cossette rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=911,13048 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=916,13050 dist=5.2 chunk=true inMap=true car=Base.CarLightsKST at 916.0,13050.0 dist=5.2 vehicles=58
ZEDQA dke shot police_off design=police rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot police_start design=police rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot police_on design=police rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=915,13049 grid=19 chunks (152 tiles) loaded x 840-992 y 12976-13128 sq=920,13046 dist=6.1 chunk=true inMap=true car=Base.PickUpTruck at 920.0,13046.0 dist=6.1 vehicles=56
ZEDQA dke shot d6_off design=d6 rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot d6_start design=d6 rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot d6_on design=d6 rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=918,13045 grid=19 chunks (152 tiles) loaded x 840-992 y 12968-13120 sq=913,13047 dist=5.3 chunk=true inMap=true car=Base.ModernCar at 913.0,13047.0 dist=5.3 vehicles=56
ZEDQA dke shot dashelite_off design=dashelite rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot dashelite_start design=dashelite rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot dashelite_on design=dashelite rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=911,13046 grid=19 chunks (152 tiles) loaded x 832-984 y 12968-13120 sq=913,13051 dist=4.2 chunk=true inMap=true car=Base.ModernCar02 at 913.0,13051.0 dist=4.2 vehicles=58
ZEDQA dke shot primani_off design=primani rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot primani_start design=primani rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot primani_on design=primani rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=911,13050 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=916,13052 dist=4.3 chunk=true inMap=true car=Base.SmallCar at 916.0,13052.0 dist=4.3 vehicles=58
ZEDQA dke shot dart_off design=dart rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot dart_start design=dart rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot dart_on design=dart rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=914,13052 grid=19 chunks (152 tiles) loaded x 840-992 y 12976-13128 sq=919,13049 dist=5.1 chunk=true inMap=true car=Base.SmallCar02 at 919.0,13049.0 dist=5.1 vehicles=56
ZEDQA dke shot horizon_off design=horizon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot horizon_start design=horizon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot horizon_on design=horizon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=917,13049 grid=19 chunks (152 tiles) loaded x 840-992 y 12976-13128 sq=912,13051 dist=6.2 chunk=true inMap=true car=Base.CarStationWagon at 912.0,13051.0 dist=6.2 vehicles=56
ZEDQA dke ERR wagon key reads start with the key in, engine off; want off
ZEDQA dke shot wagon_off design=wagon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke ERR wagon the key never read START while the starter turned
ZEDQA dke shot wagon_on design=wagon rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=910,13050 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=912,13055 dist=4.5 chunk=true inMap=true car=Base.SUV at 912.0,13055.0 dist=4.5 vehicles=58
ZEDQA dke ERR suv key reads start with the key in, engine off; want off
ZEDQA dke shot suv_off design=suv rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke ERR suv the key never read START while the starter turned
ZEDQA dke shot suv_on design=suv rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=910,13054 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=915,13056 dist=4.4 chunk=true inMap=true car=Base.Van at 915.0,13056.0 dist=4.4 vehicles=58
ZEDQA dke shot van_off design=van rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot van_start design=van rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot van_on design=van rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=913,13055 grid=19 chunks (152 tiles) loaded x 840-992 y 12976-13128 sq=918,13052 dist=5.3 chunk=true inMap=true car=Base.PickUpVan at 918.0,13052.0 dist=5.3 vehicles=56
ZEDQA dke shot bulldriver_off design=bulldriver rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot bulldriver_start design=bulldriver rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot bulldriver_on design=bulldriver rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=916,13051 grid=19 chunks (152 tiles) loaded x 840-992 y 12976-13128 sq=911,13053 dist=6.1 chunk=true inMap=true car=Base.OffRoad at 911.0,13053.0 dist=6.1 vehicles=56
ZEDQA dke shot rancher_off design=rancher rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot rancher_start design=rancher rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot rancher_on design=rancher rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=909,13053 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=911,13058 dist=5.0 chunk=true inMap=true car=Base.CarTaxi at 911.0,13058.0 dist=5.0 vehicles=58
ZEDQA dke ERR taxi key reads start with the key in, engine off; want off
ZEDQA dke shot taxi_off design=taxi rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke ERR taxi the key never read START while the starter turned
ZEDQA dke shot taxi_on design=taxi rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=909,13057 grid=19 chunks (152 tiles) loaded x 832-984 y 12984-13136 sq=914,13059 dist=4.3 chunk=true inMap=true car=Base.VanAmbulance at 914.0,13059.0 dist=4.3 vehicles=62
ZEDQA dke shot ambulance_off design=ambulance rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot ambulance_start design=ambulance rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot ambulance_on design=ambulance rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=912,13058 grid=19 chunks (152 tiles) loaded x 840-992 y 12984-13136 sq=917,13055 dist=5.4 chunk=true inMap=true car=Base.PickUpTruckLightsFire at 917.0,13055.0 dist=5.4 vehicles=60
ZEDQA dke shot fire_off design=fire rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot fire_start design=fire rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot fire_on design=fire rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA vp dke player=915,13054 grid=19 chunks (152 tiles) loaded x 840-992 y 12976-13128 sq=910,13056 dist=6.2 chunk=true inMap=true car=Base.CarLightsRanger at 910.0,13056.0 dist=6.2 vehicles=56
ZEDQA dke shot ranger_off design=ranger rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot ranger_start design=ranger rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot ranger_on design=ranger rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ERROR: General f:165824 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA vp dke player=908,13055 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=910,13060 dist=4.2 chunk=true inMap=true car=Base.RaceCar12 at 910.0,13060.0 dist=4.2 vehicles=58
ERROR: General f:166053 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dke shot race_off design=race rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=off running=false kmh=0.0
ZEDQA dke shot race_start design=race rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=start running=false kmh=0.0
ZEDQA dke shot race_on design=race rect=1120,1804,1600,356 bottom=2160 screenBottom=2160 k=2 keyPos=on running=true kmh=0.0
ZEDQA dke errors 6
ZEDQA dke DONE
```

### 97. zedqa_dash_brands.lua (`ZEDQA dbr`) - PASS, 165 s

- go 21394 at 17:51:09
- screenshots: zqa_dbr_luxury.png, zqa_dbr_nyala.png, zqa_dbr_cossette.png, zqa_dbr_d6.png, zqa_dbr_dashelite.png, zqa_dbr_primani.png, zqa_dbr_dart.png, zqa_dbr_horizon.png, zqa_dbr_wagon.png, zqa_dbr_suv.png, zqa_dbr_van.png, zqa_dbr_bulldriver.png, zqa_dbr_rancher.png, zqa_dbr_stepvan.png, zqa_dbr_modded.png, zqa_dbr_dashelite_night.png, zqa_dbr_cossette_night.png

```text
[ZeD.QA] state #97 speed=1 paused=false player=909,13059 grid=19 inCar=false vehicles=62 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home dbr moved from 909,13059,0 to the drag strip
[ZeD.QA] run #97 ok=true
ZEDQA vp dbr player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=920,13042 dist=5.7 chunk=true inMap=true car=Base.CarLuxury at 920.0,13042.0 dist=5.7 vehicles=46
ZEDQA dbr shot luxury design=luxury brand=mercia make=MERCIA model=LANG 4000 tag= rect=1120,1804,1600,356 k=2 sprite=brand_mercia_luxury@610,33 71x22 tex=true line=model@635,46 w56 l
ZEDQA vp dbr player=917,13042 grid=19 chunks (152 tiles) loaded x 840-992 y 12968-13120 sq=912,13044 dist=5.9 chunk=true inMap=true car=Base.CarNormal at 912.0,13044.0 dist=5.9 vehicles=56
ZEDQA dbr shot nyala design=nyala brand=chevalier make=CHEVALIER model=NYALA tag= rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_nyala@603,31 84x22 tex=true line=model@627,44 w64 l
ZEDQA vp dbr player=910,13043 grid=19 chunks (152 tiles) loaded x 832-984 y 12968-13120 sq=912,13048 dist=4.4 chunk=true inMap=true car=Base.SportsCar at 912.0,13048.0 dist=4.4 vehicles=58
ZEDQA dbr shot cossette design=cossette brand=chevalier make=CHEVALIER model=COSSETTE tag=5.0 rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_cossette@603,31 83x22 tex=true line=model@627,44 w64 l
ZEDQA vp dbr player=910,13048 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=915,13050 dist=4.4 chunk=true inMap=true car=Base.PickUpTruck at 915.0,13050.0 dist=4.4 vehicles=58
ZEDQA dbr shot d6 design=d6 brand=chevalier make=CHEVALIER model=D6 tag= rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_d6@603,31 84x22 tex=true line=model@627,44 w117 l
ZEDQA vp dbr player=913,13049 grid=19 chunks (152 tiles) loaded x 840-992 y 12976-13128 sq=918,13046 dist=5.3 chunk=true inMap=true car=Base.ModernCar at 918.0,13046.0 dist=5.3 vehicles=56
ZEDQA dbr shot dashelite design=dashelite brand=dash make=DASH model=ELITE tag=EFI rect=1120,1804,1600,356 k=2 sprite=brand_dash_dashelite@616,36 63x21 tex=true line=model@640,51 w39 l
ZEDQA vp dbr player=916,13045 grid=19 chunks (152 tiles) loaded x 840-992 y 12968-13120 sq=911,13047 dist=6.0 chunk=true inMap=true car=Base.ModernCar02 at 911.0,13047.0 dist=6.0 vehicles=56
ZEDQA dbr shot primani design=primani brand=chevalier make=CHEVALIER model=PRIMANI tag=EFI rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_primani@606,40 84x22 tex=true line=model@630,53 w61 l
ZEDQA vp dbr player=909,13046 grid=19 chunks (152 tiles) loaded x 832-984 y 12968-13120 sq=911,13051 dist=4.5 chunk=true inMap=true car=Base.SmallCar at 911.0,13051.0 dist=4.5 vehicles=58
ZEDQA dbr shot dart design=dart brand=chevalier make=CHEVALIER model=DART tag= rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_dart@603,30 84x22 tex=true line=model@627,43 w117 l
ZEDQA vp dbr player=909,13051 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=914,13053 dist=4.5 chunk=true inMap=true car=Base.SmallCar02 at 914.0,13053.0 dist=4.5 vehicles=58
ZEDQA dbr shot horizon design=horizon brand=masterson make=MASTERSON model=HORIZON tag= rect=1120,1804,1600,356 k=2 sprite=brand_masterson_horizon@603,32 84x20 tex=true line=-
ZEDQA vp dbr player=912,13053 grid=19 chunks (152 tiles) loaded x 840-992 y 12976-13128 sq=917,13050 dist=5.2 chunk=true inMap=true car=Base.CarStationWagon at 917.0,13050.0 dist=5.2 vehicles=56
ZEDQA dbr shot wagon design=wagon brand=chevalier make=CHEVALIER model=CERISE WAGON tag= rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_wagon@602,33 85x21 tex=true line=-
ZEDQA vp dbr player=915,13049 grid=19 chunks (152 tiles) loaded x 840-992 y 12976-13128 sq=910,13051 dist=5.9 chunk=true inMap=true car=Base.SUV at 910.0,13051.0 dist=5.9 vehicles=56
ZEDQA dbr shot suv design=suv brand=franklin make=FRANKLIN model=ALL-TERRAIN tag=4X4 rect=1120,1804,1600,356 k=2 sprite=brand_franklin_suv@612,34 72x17 tex=true line=model@613,52 w70 c
ZEDQA vp dbr player=908,13050 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=910,13055 dist=4.7 chunk=true inMap=true car=Base.Van at 910.0,13055.0 dist=4.7 vehicles=58
ZEDQA dbr shot van design=van brand=franklin make=FRANKLIN model=VALULINE tag= rect=1120,1804,1600,356 k=2 sprite=brand_franklin_van@610,28 70x18 tex=true line=model@599,47 w92 c
ZEDQA vp dbr player=908,13054 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=913,13056 dist=4.5 chunk=true inMap=true car=Base.PickUpVan at 913.0,13056.0 dist=4.5 vehicles=58
ZEDQA dbr shot bulldriver design=bulldriver brand=dash make=DASH model=BULLDRIVER tag=V8 rect=1120,1804,1600,356 k=2 sprite=brand_dash_bulldriver@607,31 62x20 tex=true line=model@631,45 w113 l
ZEDQA vp dbr player=911,13055 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=916,13052 dist=5.4 chunk=true inMap=true car=Base.OffRoad at 916.0,13052.0 dist=5.4 vehicles=58
ZEDQA dbr shot rancher design=rancher brand=dash make=DASH model=RANCHER tag=4X4 rect=1120,1804,1600,356 k=2 sprite=brand_dash_rancher@613,31 62x20 tex=true line=model@637,45 w109 l
ZEDQA vp dbr player=914,13052 grid=19 chunks (152 tiles) loaded x 840-992 y 12976-13128 sq=909,13054 dist=6.3 chunk=true inMap=true car=Base.StepVan at 909.0,13054.0 dist=6.3 vehicles=56
ZEDQA dbr shot stepvan design=van brand=chevalier make=CHEVALIER model=STEP VAN tag= rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_van@603,30 84x22 tex=true line=model@627,43 w64 l
ZEDQA vp dbr player=907,13053 grid=19 chunks (152 tiles) loaded x 832-984 y 12976-13128 sq=909,13058 dist=4.9 chunk=true inMap=true car=Base.CarNormal at 909.0,13058.0 dist=4.9 vehicles=58
ZEDQA dbr shot modded design=nyala brand=plaque make=FORD model=BRONCO tag= rect=1120,1804,1600,356 k=2 sprite=brand_plaque_nyala@603,31 84x20 tex=true line=make@605,38 w80 c
ZEDQA vp dbr player=907,13057 grid=19 chunks (152 tiles) loaded x 832-984 y 12984-13136 sq=912,13059 dist=4.3 chunk=true inMap=true car=Base.ModernCar at 912.0,13059.0 dist=4.3 vehicles=62
ZEDQA dbr shot dashelite_night design=dashelite brand=dash make=DASH model=ELITE tag=EFI rect=1120,1804,1600,356 k=2 sprite=brand_dash_dashelite@616,36 63x21 tex=true line=model@640,51 w39 l
ZEDQA vp dbr player=910,13058 grid=19 chunks (152 tiles) loaded x 832-984 y 12984-13136 sq=915,13055 dist=5.7 chunk=true inMap=true car=Base.SportsCar at 915.0,13055.0 dist=5.7 vehicles=62
ZEDQA dbr shot cossette_night design=cossette brand=chevalier make=CHEVALIER model=COSSETTE tag=5.0 rect=1120,1804,1600,356 k=2 sprite=brand_chevalier_cossette@603,31 83x22 tex=true line=model@627,44 w64 l
ZEDQA dbr PASS
ZEDQA dbr DONE
```

### 98. zedqa_testlang.lua (`ZEDQA tlang`) - PASS, 130 s

- go 21395 at 17:53:58
- screenshots: zqa_tl_01_char_loot_list.png, zqa_tl_02_char_loot_grid.png, zqa_tl_03_card_food.png, zqa_tl_04_card_weapon.png, zqa_tl_05_card_bottle.png, zqa_tl_06_card_gun.png, zqa_tl_07_char_equip_list.png, zqa_tl_08_char_equip_doll.png, zqa_tl_09_char_health.png, zqa_tl_10_char_thermal_1.png, zqa_tl_11_char_thermal_2.png, zqa_tl_12_char_thermal_3.png, zqa_tl_13_char_thermal_4.png, zqa_tl_14_char_thermal_5.png, zqa_tl_15_char_thermal_6.png, zqa_tl_16_char_thermal_7.png, zqa_tl_17_char_thermal_figure.png, zqa_tl_18_char_identity.png, zqa_tl_19_char_journal_1.png, zqa_tl_20_char_journal_2.png, zqa_tl_21_char_journal_3.png, zqa_tl_22_char_journal_4.png, zqa_tl_23_char_skills.png, zqa_tl_24_char_radio.png, zqa_tl_25_char_loot_back.png, zqa_tl_26_ctx_strip_food.png, zqa_tl_27_ctx_strip_weapon.png, zqa_tl_28_ctx_list_food.png, zqa_tl_29_ctx_list_submenu.png, zqa_tl_30_world_loot.png, zqa_tl_31_world_craft_list.png, zqa_tl_32_world_craft_recipe.png, zqa_tl_33_world_build_list.png, zqa_tl_34_world_build_recipe.png, zqa_tl_35_world_furniture.png, zqa_tl_36_world_furniture_rotate.png, zqa_tl_37_world_furniture_scrap.png, zqa_tl_38_world_furniture_repair.png, zqa_tl_39_world_furniture_pickup.png, zqa_tl_40_world_maps.png, zqa_tl_41_world_maps_survey.png, zqa_tl_42_world_maps_color.png, zqa_tl_43_world_maps_paper.png, zqa_tl_44_world_forage.png, zqa_tl_45_world_animals.png, zqa_tl_46_belt_watch_tucked.png, zqa_tl_47_belt_watch_popped.png, zqa_tl_48_watch_corner.png, zqa_tl_49_actionbar_reading_verbose.png, zqa_tl_50_actionbar_reading_simple.png, zqa_tl_51_wheel_emotes.png, zqa_tl_52_wheel_vehicle_outside.png, zqa_tl_53_prompt_question.png, zqa_tl_54_prompt_textbox.png, zqa_tl_55_prompt_textbox_empty.png, zqa_tl_56_prompt_keyboard.png, zqa_tl_57_prompt_alarm.png, zqa_tl_58_prompt_timer.png, zqa_tl_59_prompt_help.png, zqa_tl_60_prompt_rich_question.png, zqa_tl_61_safe_note.png, zqa_tl_62_pause_menu.png, zqa_tl_63_options_1_zed.png, zqa_tl_64_options_2_display.png, zqa_tl_65_options_3_graphics.png, zqa_tl_66_options_4_audio.png, zqa_tl_67_options_5_controls.png, zqa_tl_68_options_6_gameplay.png, zqa_tl_69_options_7_interface.png, zqa_tl_70_options_8_access.png, zqa_tl_71_options_9_mods.png, zqa_tl_72_pause_mods.png

```text
[ZeD.QA] state #98 speed=1 paused=false player=913,13055 grid=19 inCar=false vehicles=56 missing=get
[ZeD.QA] windows reset (R)
ZEDQA tlang start (209 steps)
[ZeD.QA] run #98 ok=true
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
ZEDQA tlang recipe open in craft: AddTimerToBomb
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

### 99. zedqa_safemode.lua (`ZEDQA safe`) - PASS, 14 s

- go 21396 at 17:56:11
- screenshots: zqa_safe_1.png, zqa_safe_2.png, zqa_safe_3.png

```text
[ZeD.QA] state #99 speed=1 paused=false player=913,13055 grid=19 inCar=false vehicles=56 missing=get
[ZeD.QA] windows reset (R)
ZEDQA safe start
[ZeD.QA] run #99 ok=true
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
ZEDQA safe option On picked up by the poll: picked up after 502 ms
ZEDQA safe ok option On picked up by the poll
ZEDQA safe option on: on true | pair false/false | vanilla inv true | hotbar vanilla | clock y 10 visible false | speed y 10 | moodle layer false
ZEDQA safe ok option on
ZEDQA safe option Off picked up by the poll: picked up after 674 ms
ZEDQA safe ok option Off picked up by the poll
ZEDQA safe option off: on false | pair false/false | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok option off
ZEDQA safe burst: 5 ticks, still off after 2502 ms
ZEDQA safe ok watchdog: a five-frame burst leaves ZeD on
ZEDQA safe streak: tripped after 2028 ms, 241 frames, longest gap 11 ms
ZEDQA safe ok watchdog: below two seconds of failures ZeD stays on
ZEDQA safe ok watchdog: two seconds of failures every frame trip it
ZEDQA safe ok watchdog note shows and closes
ZEDQA safe restored: on false | pair true/true | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok restored
ZEDQA safe DONE
```

### 100. zedqa_soak.lua (`ZEDQA soak`) - PASS, 812 s

- go 21397 at 17:56:29

```text
[ZeD.QA] state #100 speed=1 paused=false player=913,13055 grid=19 inCar=false vehicles=56 missing=get
[ZeD.QA] windows reset (R)
ZEDQA soak start ui 38
[ZeD.QA] run #100 ok=true
ZEDQA soak round 1 avg 16.39 ms worst 111 ms ui 39 (start 38) hours 0.3
ZEDQA soak round 2 avg 16.35 ms worst 38 ms ui 39 (start 38) hours 0.6
ZEDQA soak round 3 avg 16.86 ms worst 38 ms ui 39 (start 38) hours 0.9
ZEDQA soak round 4 avg 16.65 ms worst 47 ms ui 39 (start 38) hours 1.2
ZEDQA soak round 5 avg 16.66 ms worst 41 ms ui 39 (start 38) hours 1.5
ZEDQA soak round 6 avg 16.67 ms worst 41 ms ui 39 (start 38) hours 1.8
ZEDQA soak round 7 avg 16.65 ms worst 160 ms ui 39 (start 38) hours 2.1
ZEDQA soak round 8 avg 16.64 ms worst 45 ms ui 39 (start 38) hours 2.4
ZEDQA soak round 9 avg 16.31 ms worst 48 ms ui 39 (start 38) hours 2.7
ZEDQA soak round 10 avg 16.22 ms worst 38 ms ui 39 (start 38) hours 3.0
ZEDQA soak round 11 avg 16.45 ms worst 36 ms ui 39 (start 38) hours 3.3
ZEDQA soak round 12 avg 16.11 ms worst 37 ms ui 39 (start 38) hours 3.6
ZEDQA soak DONE
```

### 101. zedqa_cook80.lua (`ZEDQA c80`) - PASS, 49 s

- go 21398 at 18:10:04
- screenshots: zqa_c80_3840x2160_1_open.png, zqa_c80_3840x2160_2_stew_plan.png, zqa_c80_3840x2160_2_stew_made.png, zqa_c80_3840x2160_3_count.png, zqa_c80_3840x2160_4_stirfry_full.png, zqa_c80_3840x2160_4_by_kind.png, zqa_c80_3840x2160_5_dish_list.png, zqa_c80_3840x2160_5_use_instead.png, zqa_c80_3840x2160_5_not_in_reach.png, zqa_c80_3840x2160_6_by_kind_pad.png

```text
[ZeD.QA] state #101 speed=1 paused=false player=913,13055 grid=19 inCar=false vehicles=56 missing=get
[ZeD.QA] windows reset (R)
ZEDQA home c80 moved from 913,13055,0 to the drag strip
ZEDQA c80 start
[ZeD.QA] run #101 ok=true
ZEDQA c80 before: tab shown false (the character's own bags)
ZEDQA c80 own bags: carrots 0, potatoes 0, cabbage 0, stews 0, pots 0
ZEDQA c80 pot water: 1.5
ZEDQA c80 PASS a pot of water, a carrot and a potato on the character: the Cooking tab is in the strip
ZEDQA c80 PASS the Cooking tab opens
ZEDQA c80 dish Soup; dishes: Soup, Stew
ZEDQA c80 shot 1_open
ZEDQA c80 PASS the pot taken away: the tab goes (carrot and potato still there)
ZEDQA c80 PASS the window leaves the tab when it goes (now loot)
ZEDQA c80 PASS the Dish list picks Stew (now Stew)
ZEDQA c80 PASS three vegetables in the dish (Base.Carrots, Base.Potato, Base.Cabbage)
ZEDQA c80 PASS all three count as ingredients, none as seasoning (0 as seasoning; the hunger total adds them)
ZEDQA c80 PASS Make is lit
ZEDQA c80 PASS no count for one pot
ZEDQA c80 shot 2_stew_plan
ZEDQA c80 PASS one pot of stew made (1)
ZEDQA c80 PASS it holds all three (3): Vegetable Stew
ZEDQA c80 PASS the carrot and the potato went in (cabbage left: 1, part used)
ZEDQA c80 PASS no empty pot left behind
ZEDQA c80 shot 2_stew_made
ZEDQA c80 PASS the Dish list picks Stew (now Stew)
ZEDQA c80 two pots: dish Stew, bases [Base.Pot ok mine, Base.Pot ok mine], in reach [Base.Potato x2, Base.Carrots x2], plan Base.Carrots, Base.Potato
ZEDQA c80 PASS two pots and enough for two: the count shows
ZEDQA c80 PASS the count goes to 2 (2)
ZEDQA c80 PASS and stops at 2 (2)
ZEDQA c80 shot 3_count
ZEDQA c80 PASS two pots of stew made (2)
ZEDQA c80 PASS each holds a carrot and a potato (2, 2)
ZEDQA c80 Base.Broccoli frozen true; Base.Carrots frozen true
ZEDQA c80 dishes now: Stir fry
ZEDQA c80 PASS the Dish list picks Stir-fry (now Stir fry)
ZEDQA c80 stir-fry: recipe Stir fry, max 4, base Base.Pan; the game offers [Base.Onion, Base.Cabbage, Base.Carrots, Base.BellPepper, Base.Tomato, Base.Potato]; frozen now [Base.Broccoli, Base.Carrots]
ZEDQA c80 stir-fry four in: dish Stir fry, bases [Base.Pan ok mine], in reach [Base.Onion x1, Base.Cabbage x1, Base.Carrots x1, Base.BellPepper x1, Base.Tomato x1, Base.Potato x1], plan Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion
ZEDQA c80 PASS four in the stir-fry (Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion)
ZEDQA c80 PASS the four are ingredients (Ingredients 4 / 4), none seasoning
ZEDQA c80 PASS a fifth greys (bell pepper)
ZEDQA c80 PASS a press on it adds nothing
ZEDQA c80 PASS no seasoning offered to a new stir-fry (as the game)
ZEDQA c80 PASS still four (Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion)
ZEDQA c80 PASS frozen broccoli is not offered (as the game)
ZEDQA c80 carrots: 1 usable, why nil
ZEDQA c80 stir-fry full: dish Stir fry, bases [Base.Pan ok mine], in reach [Base.Onion x1, Base.Cabbage x1, Base.Carrots x1, Base.BellPepper x1, Base.Tomato x1, Base.Potato x1], plan Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion
ZEDQA c80 PASS a frozen carrot beside a good one: the good one still goes in
ZEDQA c80 shot 4_stirfry_full
ZEDQA c80 shot 4_by_kind
ZEDQA c80 PASS the Dish list picks Stew (now Stew)
ZEDQA c80 PASS Save is in the band
ZEDQA c80 PASS the dish is saved (1)
ZEDQA c80 PASS Save turns to Forget
ZEDQA c80 PASS the saved dish heads the Dish list
ZEDQA c80 shot 5_dish_list
ZEDQA c80 PASS the saved dish loads (Base.Carrots, Base.Potato)
ZEDQA c80 PASS the potato not in reach: Use <same kind> is offered
ZEDQA c80 PASS Make waits while an ingredient is missing
ZEDQA c80 shot 5_use_instead
ZEDQA c80 PASS Use takes the cabbage (Base.Carrots, Base.Cabbage)
ZEDQA c80 PASS nothing of the same kind: no Use offered
ZEDQA c80 shot 5_not_in_reach
ZEDQA c80 PASS Forget takes it off the list (0)
ZEDQA c80 PASS A on an ingredient: a stop for it
ZEDQA c80 PASS A adds it (Base.Carrots)
ZEDQA c80 PASS A on the dish's row takes it out
ZEDQA c80 PASS A on Sort opens its list
ZEDQA c80 PASS with the list open, only its choices and the boxes are stops
ZEDQA c80 PASS A picks By category and shuts the list
ZEDQA c80 PASS B shuts an open list
ZEDQA c80 PASS the list is shut
ZEDQA c80 shot 6_by_kind_pad
ZEDQA c80 put back: 26 items taken away, the saved dishes as they were
ZEDQA c80 RESULT 47 pass, 0 fail
ZEDQA c80 DONE
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
