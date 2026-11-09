# Gallery recapture for beta 10 (Nov 9 2026)

Build's list for QA. Take at 4K, 1.75x, Dark + orange unless the spread says otherwise. Put the files in
Screenshots/gallery_t14 under the SAME names (the spreads pick them up by name), and move the old ones to
_before_b10. Build then re-renders with spread.py --only, cover_px and make_upload.

What changed since beta 8, as the pictures show it:
- **Title bars (beta 9 + 10):** the Character and World windows have one pin per half (left and right ends of
  the bar), and the roll boxes are gone. Every picture with either title bar in view is out of date.
- **Balloons (beta 10):** every hover box is a Balloon Help balloon with a tail. The moodle hover is a
  balloon now; the automatic moodle notice keeps the thought bubble.
- **Paper at 70% (beta 10):** the guide book, the reader, notebooks, the Journal, the sticky note and paper maps.
- **Context strip arrows in the accent (beta 10).**
- **Fill bars (beta 10):** equal cells with the extra pixels in the end cells. This is a 1-2 px change, so don't
  retake just for this.
- **Guide bubble (beta 10):** new, with no picture yet (see 34).
- Tattoos and Custom Map Labels aren't pictured in the gallery: skip them.

## Tier 1: the content changed (must retake)

| Spread | Capture names | What each must show |
|---|---|---|
| 25 context menus | zed_20_ctx_strip.png, zed_21_ctx_list.png | Strip: an item's strip with its arrow boxes in the accent, one action named above. List: the same item's menu as a list, with a submenu open. van_20 stays. |
| 32 moodles | zqa_mood_left_hover.png, zqa_mood_bottom_hover.png, zqa_mood_right_hover.png | zedqa_moodles.lua takes these itself (fixed today, so it waits for the balloon): the pointer's moodle with its balloon, tail on the moodle, in each of the three places. |
| 39 reading and writing | zqa_nb_01_page1.png, zqa_rd_01_paper.png | A notebook's first page and the reader on a newspaper, both on the 70% paper. |
| 46 survival guide | gb_1_title.png, gb_2_contents_p1p2.png, gb_3_chapter_opener.png, gb_4_skill_books_rules.png, gb_5_shared_page.png, gw_zqa_g82s_3840x2160_2b_skill_books_rules_full.png, gw_zqa_g82s_3840x2160_4_find_book.png | Same pages as before, on the 70% paper. (The uncommitted Nov 8 render of 46 is stale: it gets redone from these.) |
| 03 the plan | story_02a_journal_entry.png, story_01a_flyer_reader.png | The Journal entry and the flyer in the reader, on the 70% paper. |
| 04 the route | story_03_route_map.png, story_03b_route_note.png | The paper map with the route and the sticky note, both dimmer. |
| 34 messages | zqa_g4_guide_bubble.png (NEW) | The guide bubble out of the Messages icon on the belt, with the director's wording ("New to Knox County? ... Press F1 ..."), mouse wording. zedqa_guide_bubble.lua step 2 frames it (2_bubble_from_belt): copy that frame under this name. Build will put it in as Figure 34-1's second picture. |

## Tier 2: title bars only (retake if the run has time; same framing as before)

Window shots with a Character or World title bar in view:
15 every window (zqa_cw_02_dark_small_window_menu_theme, zqa_cw_01_dark_small_card, zqa_cw_14_focus_hand_inventory_row),
16 see-through (zqa_cw_12b_solid_in_use, zqa_cw_08_seethrough_100, zqa_cw_12_seethrough_60),
17 controller highlight (zqa_cw_14/16/18/20_focus_*_inventory_row),
18 hidden actions (zqa_cw_29_hair_beard_folded, zqa_cw_30_hair_beard_show_all),
19 inventory compare (zed_01_hero_mid; van_01 stays),
20 grid view (zed_13_crafting, zed_53_grid),
21 item cards (zed_18_card_food, zed_19_card_weapon),
22 equip doll (zed_10_equip_doll),
23 health (zed_11_health_exercise; van_11 stays),
24 thermal (zed_70_thermal_insulation, zed_72_thermal_wetness, zed_66_thermal_skin),
27 crafting (zed_13_crafting), 28 building (zed_50_building),
29 foraging and furniture (zed_52_furniture, zed_51_forage),
56 loadouts (zed_70_loadout_save, zed_71_loadout_fold, zed_73_loadout_todo_lines),
02 old job (story_00b_skills_tall, story_00a_identity_tall), 13 keeping count (journal_kills_1: also the paper),
01 hero (zed_02_hero_close).
06, 62 and 63 read from Screenshots/gallery_beta2 by full path: retake them under the same names there, or tell
Build the new place.

Not affected: 31 bubbles (notices keep the thought bubble), 33 watches, 35-38, 40-45, 47-55, 57-61.
