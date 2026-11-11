# ZeDUI/tools/qa/gallery_b11_collect.ps1  (Nov 11 2026, QA): puts the beta 11 gallery recapture where the spreads read it.
# For each name in B11_RECAPTURE.md that the runs took (a copy in Zomboid/Screenshots written at or after -Since), the old
# file in Screenshots/gallery_t14 (or gallery_beta2 for the six names the spreads read from there) goes to _before_b11
# first, then the new one is copied under the same name. Aliases: the book and guide stills and the guide bubble are
# renamed (see $Alias). Prints COPIED / OLD (no fresh copy) per name. Touches neither the game nor the lock.
param([datetime]$Since = "2026-11-11 12:50")
$Scr = "$($env:USERPROFILE)\Zomboid\Screenshots"
$T14 = Join-Path $Scr "gallery_t14"
$B2 = Join-Path $Scr "gallery_beta2"
$Beta2 = @('story_04b_vehicle_tab_tire', 'story_04b_tire_install_bar', 'zqa_m79_3840x2160_2_hover_row', 'zqa_m79_3840x2160_6_card_brake_step',
    'zqa_c80_3840x2160_2_stew_plan', 'zqa_c80_3840x2160_5_dish_list')
# gallery name = source name in Screenshots
$Alias = @{
    'gb_1_title' = 'zqa_b83_3840x2160_D1_title'; 'gb_2_contents_p1p2' = 'zqa_b83_3840x2160_D2_contents'
    'gb_3_chapter_opener' = 'zqa_b83_3840x2160_D3_chapter_opener_clip'; 'gb_4_skill_books_rules' = 'zqa_b83_3840x2160_D4_skill_books_rules'
    'gb_5_shared_page' = 'zqa_b83_3840x2160_spread_07'
    'gw_zqa_g82s_3840x2160_2b_skill_books_rules_full' = 'zqa_g82s_3840x2160_2b_skill_books_rules_full'
    'gw_zqa_g82s_3840x2160_4_find_book' = 'zqa_g82s_3840x2160_4_find_book'
    'zqa_g4_guide_bubble' = 'zqa_gbub_3840x2160_2_bubble_from_belt'
}
$Names = @(
    'zed_02_hero_close', 'zed_01_hero_mid', 'story_00b_skills_tall', 'story_00a_identity_tall', 'story_02a_journal_entry', 'story_01a_flyer_reader',
    'story_03_route_map', 'story_03b_route_note', 'story_05a_barricade_menu', 'story_05b_barricade_bar', 'story_07b_drag_to_shelf',
    'story_09b_gas_can_card', 'story_09c_dash_fuel_full', 'story_10_customers_queue', 'zqa_ht_06_rightwatch_pistol', 'story_11_smoke_break',
    'zqa_cw_02_dark_small_window_menu_theme', 'zqa_cw_01_dark_small_card', 'zqa_cw_14_focus_hand_inventory_row', 'zqa_cw_12b_solid_in_use',
    'zqa_cw_08_seethrough_100', 'zqa_cw_12_seethrough_60', 'zqa_cw_16_focus_corners_inventory_row', 'zqa_cw_18_focus_wash_inventory_row',
    'zqa_cw_20_focus_ants_inventory_row', 'zed_13_crafting', 'zed_53_grid', 'zed_18_card_food', 'zed_19_card_weapon', 'zed_10_equip_doll',
    'zed_11_health_exercise', 'zed_20_ctx_strip', 'zed_21_ctx_list', 'zqa_ht_01_two', 'zqa_ht_02_both', 'zqa_bub_both_dark',
    'zqa_mood_left_hover', 'zqa_mood_bottom_hover', 'zqa_mood_right_hover', 'zqa_g4_belt_toast', 'zqa_g4_window_radio', 'zqa_g4_guide_bubble',
    'zqa_nb_01_page1', 'zqa_rd_01_paper', 'zqa_g3_wheel_character_eat', 'zqa_g3_wheel_now_light', 'zqa_g3_wheel_use_smoke', 'zqa_g3_footer_pad',
    'theme_dark_orange', 'theme_dark_green', 'theme_light_blue', 'theme_light_red', 'theme_hicon_teal', 'theme_hicon_purple',
    'gb_1_title', 'gb_2_contents_p1p2', 'gb_3_chapter_opener', 'gb_4_skill_books_rules', 'gb_5_shared_page',
    'gw_zqa_g82s_3840x2160_2b_skill_books_rules_full', 'gw_zqa_g82s_3840x2160_4_find_book', 'desk_05_trash_computer',
    'mm4_01_options_zed', 'mm4_03_options_hidden', 'mm4_02_options_interface', 'zed_70_loadout_save', 'zed_71_loadout_fold', 'zed_73_loadout_todo_lines',
    'gb_forms_setup', 'gb_simple_watch', 'gb_simple_belt', 'gb_plain_radio', 'gb_plain_dash',
    'zqa_m79_3840x2160_2_hover_row', 'zqa_m79_3840x2160_6_card_brake_step',
    'story_04a_dash_low_fuel', 'story_04a_seat_chooser', 'story_04b_vehicle_tab_tire', 'story_04b_tire_install_bar',
    'story_08c_footer_blue', 'story_08b_footer_light', 'story_08d_open_light_blue', 'journal_kills_1',
    'story_12b_dash_night', 'story_12c_watch_light', 'story_12d_windows_night', 'zqa_cw_29_hair_beard_folded', 'zqa_cw_30_hair_beard_show_all',
    'zed_70_thermal_insulation', 'zed_72_thermal_wetness', 'zed_66_thermal_skin', 'zed_32_action_bar_reading', 'zed_50_building',
    'zed_52_furniture', 'zed_51_forage', 'g5_car_radio', 'zqa_r6p_taxi_extras', 'zqa_tw_5_ham_civilian_tab', 'zqa_tw_3a_valutech_full_view',
    'zqa_tw_1b_valutech_tab', 'zqa_ap_1_tab_stove', 'zqa_ap_2b_popout_stove_on', 'zqa_ap_4_popout_microwave', 'zqa_fi_1_slack', 'zqa_fi_3_tight',
    'zqa_fi_5_limit', 'zqa_pr_01_sleep', 'zqa_pr_07_alarm', 'zqa_pr_06_keyboard', 'zqa_g3_setup_chords', 'zqa_g3_setup_putback', 'zqa_g3_setup_list',
    'zqa_sbx_pause_line', 'zqa_sbx_world_help', 'mm4_03_mods_conflict', 'mm4_04_mods_conflicts_tab', 'mm4_06_mods_problem_missing',
    'mm4_07_mods_problem_version', 'mm4_08_profiles', 'mm4_09_load_order', 'mm4_15_upload_ready', 'mm4_16_upload_ask', 'mm4_12_editor',
    'g14_radio_handbuilt', 'g14_radio_cd', 'g14_radio_red', 'g14_radio_black', 'gfr_yard', 'gfr_crop_grown', 'gfr_zone', 'gfr_hutch_open',
    'gfr_ranch', 'gfr_animal', 'gfr_butcher', 'g14_ldy_combo', 'g14_ldy_washer', 'g14_ldy_dryer',
    'zqa_c80_3840x2160_2_stew_plan', 'zqa_c80_3840x2160_5_dish_list',
    'van_01_hero_mid', 'van_11_health', 'van_20_ctx_menu', 'van_32_action_bar_reading', 'cin_lau_forage', 'cin_lau_fishing')
$before = @{ $T14 = (Join-Path $T14 "_before_b11"); $B2 = (Join-Path $B2 "_before_b11") }
foreach ($d in $before.Values) { New-Item -ItemType Directory -Force $d | Out-Null }
foreach ($n in $Names) {
    $srcName = $(if ($Alias.ContainsKey($n)) { $Alias[$n] } else { $n })
    $src = Join-Path $Scr "$srcName.png"
    $dir = $(if ($Beta2 -contains $n) { $B2 } else { $T14 })
    if (-not ((Test-Path $src) -and (Get-Item $src).LastWriteTime -ge $Since)) { "OLD     $n"; continue }
    $dst = Join-Path $dir "$n.png"
    # (a rerun keeps the first old file in _before_b11: only a name with nothing there yet is moved)
    if ((Test-Path $dst) -and -not (Test-Path (Join-Path $before[$dir] "$n.png"))) { Move-Item $dst (Join-Path $before[$dir] "$n.png") -Force }
    Copy-Item $src $dst -Force
    "COPIED  $n"
}
