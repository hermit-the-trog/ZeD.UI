# Gallery recapture for beta 11 (Nov 11 2026)

Build's list for QA (punch list 129, with 128). It replaces B10_RECAPTURE.md: the beta 10 retakes were never taken,
so they are folded in here. One full pass, then one full re-render of all 70 pictures.

**How to take them.** 4K (3840 x 2160), UI scale 1.75x, the Dark theme and the **PZ Teal** accent, the list view,
unless a spread says otherwise below. The game's own **Font Size at 19px** (`fontSize=2` in options.ini; the director's
setting, Nov 11), never "Scale with window height": the prelude's `vanilla: font size` line should read 2. Same framing, window places, blur and belt in view as the gallery_t14 set, so
each picture drops into its spread's crop. Put the files in `~/Zomboid/Screenshots/gallery_t14` under the **same
names** (the spreads pick them up by name), and first move the old ones to `gallery_t14/_before_b11`. Spreads 06, 62
and 63 read from `~/Zomboid/Screenshots/gallery_beta2` by full path: retake those under the same names there.

**What changed since the gallery was taken**, as the pictures show it:
- **The accent:** PZ Teal is the default (127). Every ZeD picture with the accent in view is out of date. The
  walkthrough's own colors stay: spread 09 is Light + Blue, spread 14 is Dark + Blue (the Fossoil's colors in the
  story), and spread 45 shows each theme and accent by its file name.
- **Title bars (beta 9 and 10):** one pin at each end of the bar, no roll boxes.
- **Balloons (beta 10):** every hover box is a balloon with a tail.
- **Paper at 70% (beta 10):** the guide book, the reader, notebooks, the Journal, paper maps.
- **Cond / Amt (152):** the inventory column's heading reads "Cond / Amt", at the column's left. Each row shows one
  bar: a liquid's level in ten blue cells, something that runs down (a lighter, a battery) in ten light neutral
  cells, a worn or wielded item's condition in five status cells, and no bar for things that do neither. The grid's
  strips, the belt and the Equipment tab follow the same rule.
- **Condition bars (143):** five cells, rounded up. Skill bars keep ten, evenly spread (141).
- **The belt (149, 152):** the hand rings are cut into five cells like a clock face (ten blue for a liquid).
- **Menus (138, 140):** blue and red marks on paired actions; new Eat, Sneak, Safehouse, outfit and loadout icons.
- **The ID card (145):** a camera button in the photo's corner (the portrait studio).
- **The desk (142):** the single sticky note is gone; the Pasties icon heads the desktop's left column.
- **The item card (152, 153):** a liquid container shows Liquid Facts with its litres; "Used to make" sits flush left.

## Tier 1: the content changed (retake, and check what each shows)

| Spread | Capture names | What each must show |
|---|---|---|
| 01 hero | zed_02_hero_close.png | The Character window close: the Cond / Amt column, the title bar's pins, the belt's segmented rings. |
| 02 old job | story_00b_skills_tall.png, story_00a_identity_tall.png | Skills: ten evenly spread cells. Identity: the camera button in the photo's corner. |
| 03 the plan | story_02a_journal_entry.png, story_01a_flyer_reader.png | The Journal entry and the flyer in the reader, on the 70% paper. |
| 04 the route | story_03_route_map.png, story_03b_route_note.png | The paper map with the route and its note, on the dimmer paper. |
| 07 barricading | story_05a_barricade_menu.png, story_05b_barricade_bar.png | The barricade menu with its marks; the action bar. |
| 08 stocking shelves | story_07b_drag_to_shelf.png | The drag to the shelf: the Cond / Amt column; if the shot catches it, rows waiting to move say so. |
| 10 pumping gas | story_09b_gas_can_card.png, story_09c_dash_fuel_full.png | The gas can's item card: Liquid Facts, Gasoline's litres and "Amount ... / ... L" (the game's red Tainted on gasoline is expected). The dash's full tank. |
| 11 customers | story_10_customers_queue.png, zqa_ht_06_rightwatch_pistol.png | The queue in the rows; the belt with the pistol: its ring in five cells. |
| 12 smoke break | story_11_smoke_break.png | The smoke break with the lighter's bar in light neutral cells wherever it shows. |
| 15 every window | zqa_cw_02_dark_small_window_menu_theme.png, zqa_cw_01_dark_small_card.png, zqa_cw_14_focus_hand_inventory_row.png | Windows with the new title bars and the Cond / Amt column. |
| 16 see-through | zqa_cw_12b_solid_in_use.png, zqa_cw_08_seethrough_100.png, zqa_cw_12_seethrough_60.png | The same three see-through levels, with the new columns. |
| 17 controller highlight | zqa_cw_14/16/18/20_focus_*_inventory_row.png | The four highlight styles on an inventory row, in Teal. |
| 19 inventory compare | zed_01_hero_mid.png (van_01 stays) | The Character window mid: Cond / Amt with a water bottle (blue level) and a worn or wielded item (five cells). |
| 20 grid view | zed_13_crafting.png, zed_53_grid.png | The list with "Cond / Amt" heading at the left; the grid, its strips the same as the list's bars. |
| 21 item cards | zed_18_card_food.png, zed_19_card_weapon.png | The food and weapon cards; if the card has "Used to make", flush left. |
| 22 equip doll | zed_10_equip_doll.png | The Equipment tab: the Equipped list's bars by the one-bar rule; a hooded top under Torso, Outer if worn. |
| 23 health | zed_11_health_exercise.png (van_11 stays) | The Health tab with its five-cell bars; injury rows' percents whole. |
| 25 context menus | zed_20_ctx_strip.png, zed_21_ctx_list.png (van_20 stays) | The strip with its arrow boxes in the accent and blue/red marks, one action named above; the list with a submenu open. |
| 30 belt | zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_06_rightwatch_pistol.png | The belt: hand rings in five cells; one hand holding a water bottle (ten blue cells) if the layout allows. |
| 31 bubbles | zqa_ht_01_two.png, zqa_ht_02_both.png (shared with 30), zqa_bub_both_dark.png | As 30; the bubbles keep the thought bubble. |
| 32 moodles | zqa_mood_left_hover.png, zqa_mood_bottom_hover.png, zqa_mood_right_hover.png | zedqa_moodles.lua takes these: the pointer's moodle with its balloon, in the three places. |
| 34 messages | zqa_g4_belt_toast.png, zqa_g4_window_radio.png, zqa_g4_guide_bubble.png (new in beta 10) | The guide bubble out of the Messages icon (zedqa_guide_bubble.lua step 2, "2_bubble_from_belt", copied under this name). |
| 39 reading and writing | zqa_nb_01_page1.png, zqa_rd_01_paper.png | A notebook's first page and the reader on a newspaper, on the 70% paper. |
| 43 controller | zqa_g3_wheel_character_eat.png, zqa_g3_wheel_now_light.png, zqa_g3_wheel_use_smoke.png, zqa_g3_footer_pad.png | The wheels with the new Eat icon (the figure with a fork) and the blue/red marks. |
| 45 themes | theme_dark_orange.png, theme_dark_green.png, theme_light_blue.png, theme_light_red.png, theme_hicon_teal.png, theme_hicon_purple.png, zqa_cw_02_dark_small_window_menu_theme.png | **Each in the theme and accent its name says** (not Teal throughout), with the new title bars and columns. |
| 46 survival guide | gb_1_title.png, gb_2_contents_p1p2.png, gb_3_chapter_opener.png, gb_4_skill_books_rules.png, gb_5_shared_page.png, gw_zqa_g82s_3840x2160_2b_skill_books_rules_full.png, gw_zqa_g82s_3840x2160_4_find_book.png | The same pages, on the 70% paper. |
| 47 desk | desk_05_trash_computer.png | The desk with the Pasties icon at the top of the left column, no old sticky note. |
| 48 options menu | mm4_01_options_zed.png, mm4_03_options_hidden.png, mm4_02_options_interface.png | ZeD setup; if the Look page is in view, its new Status colors row. |
| 56 loadouts | zed_70_loadout_save.png, zed_71_loadout_fold.png, zed_73_loadout_todo_lines.png | The new outfit and loadout icons (the hanger and the clipboard). |
| 61 full or simple | gb_forms_setup.png, gb_simple_watch.png, gb_simple_belt.png, gb_plain_radio.png, gb_plain_dash.png | The Simple belt's strips by the one-bar rule. |
| 62 vehicle tab | zqa_m79_3840x2160_2_hover_row.png, zqa_m79_3840x2160_6_card_brake_step.png (in gallery_beta2) | The parts list's condition bars in five cells. |

## Tier 2: the accent and title bars only (retake in Teal, same framing)

| Spread | Capture names |
|---|---|
| 05 driving in | story_04a_dash_low_fuel.png, story_04a_seat_chooser.png |
| 06 fixing the car | story_04b_vehicle_tab_tire.png, story_04b_tire_install_bar.png (in gallery_beta2) |
| 09 open for business | story_08c_footer_blue.png, story_08b_footer_light.png, story_08d_open_light_blue.png: **Light + Blue**, as the story has it |
| 13 keeping count | journal_kills_1.png (the 70% paper too) |
| 14 night shift | story_12b_dash_night.png, story_12c_watch_light.png, story_12d_windows_night.png: **Dark + Blue**, as the story has it |
| 18 hidden actions | zqa_cw_29_hair_beard_folded.png, zqa_cw_30_hair_beard_show_all.png |
| 24 thermal | zed_70_thermal_insulation.png, zed_72_thermal_wetness.png, zed_66_thermal_skin.png |
| 26 action bar | zed_32_action_bar_reading.png (van_32 stays) |
| 27 crafting | zed_13_crafting.png (shared with 20) |
| 28 building | zed_50_building.png |
| 29 foraging and furniture | zed_52_furniture.png, zed_51_forage.png |
| 35 car radio | g5_car_radio.png |
| 36 dashboards | zqa_r6p_taxi_extras.png |
| 37 two-way radios | zqa_tw_5_ham_civilian_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_1b_valutech_tab.png |
| 38 ovens | zqa_ap_1_tab_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_4_popout_microwave.png |
| 40 fishing | zqa_fi_1_slack.png, zqa_fi_3_tight.png, zqa_fi_5_limit.png |
| 41 questions | zqa_pr_01_sleep.png, zqa_pr_07_alarm.png, zqa_pr_06_keyboard.png |
| 44 quick actions | zqa_g3_setup_chords.png, zqa_g3_setup_putback.png, zqa_g3_setup_list.png |
| 49 sandbox in game | zqa_sbx_pause_line.png, zqa_sbx_world_help.png |
| 50 mod manager | mm4_03_mods_conflict.png, mm4_04_mods_conflicts_tab.png, mm4_06_mods_problem_missing.png, mm4_07_mods_problem_version.png |
| 51 mod settings | zqa_mp_r1_reset_files.png, zqa_mp_5_srm_sandbox.png, zqa_mp_r2_reset_confirm.png |
| 52 multiplayer | mps_01 to mps_11 (the eight in the spread) |
| 53 turn off | zqa_mp_12_turnoff_items.png, zqa_mp_14_ask_off.png |
| 54 load order | mm4_08_profiles.png, mm4_09_load_order.png |
| 55 uploader | mm4_15_upload_ready.png, mm4_16_upload_ask.png, mm4_12_editor.png |
| 57 radios | g14_radio_handbuilt.png, g14_radio_cd.png, g14_radio_red.png, g14_radio_black.png (the preset "+" follows the accent) |
| 58 farming | gfr_yard.png, gfr_crop_grown.png |
| 59 ranching | gfr_zone.png, gfr_hutch_open.png, gfr_ranch.png, gfr_animal.png, gfr_butcher.png |
| 60 laundry | g14_ldy_combo.png, g14_ldy_washer.png, g14_ldy_dryer.png |
| 63 cooking | zqa_c80_3840x2160_2_stew_plan.png, zqa_c80_3840x2160_5_dish_list.png (in gallery_beta2) |

## Keep (don't retake)

- The vanilla pictures: van_01_hero_mid, van_11_health, van_20_ctx_menu, van_32_action_bar_reading.
  They were taken on the Windows rig before the font size was pinned; the director keeps them as they are (Nov 11).
- 33 watches (gbw_* plates) and 42 the controller map (drawn from the repo's controller_pad_px.png).
- If a Tier 2 picture shows no accent and no title bar at all, it can stay; say which in the report.

## The text (Build's, done)

- **128:** every left running head reads "Bitchin' znix Programs - Doidbros & Buzzlord" (a hyphen, not a middle dot).
- **20 grid view:** the column heads are now *Name*, *Cat*, *Cond / Amt* and *Wt*, and a row shows "its condition or
  how full it is".
- **To check (QA):** spread 09 says the Accent submenu holds "eight colors or None"; count them in the game and tell
  Build if it is nine (the Workshop page says nine).

## Not pictured yet (the director's call)

New in beta 11 with no picture in the book: the portrait studio, Pasties, the loot card, Status colors. Adding a
picture means a new spread or a changed one, so it waits for the director.

## Render and deliver

From `ZeDUI/workshop/gallery` (`python3` on the Mac, `py` on Windows):

    python3 spread.py spreads out_spread                     every spread; prints CHECK lines (a clean set prints none)
    python3 title_spread.py out_spread/00_title.png
    python3 cover_px.py znix_01_cover.png
    python3 make_upload.py                                   out_spread + the cover -> upload/*.jpg, each under 1 MB
    python3 review_tools.py sheet out_spread b11_sheet.png   the contact sheet, every spread at a third

Commit `upload/` and send the director the contact sheet. The director uploads to Steam by hand, one image at a time.
