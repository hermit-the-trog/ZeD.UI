# ZeD-UI regression - 2026-11-12 23:42 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-12 23:42:08 |
| Finished | 2026-11-12 23:58:51 (16 min 43 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta12 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/_b13_rest.txt (31 scripts) |
| Result | **29/31 pass**, 1 warn, 1 fail, 0 timeout |
| Go numbers | 26125 to 26157 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 26156, 26157)
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_mapstyles.lua | mst | PASS | 15 | zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png |  |
| 3 | zedqa_flyers.lua | fl | PASS | 6 | zqa_fl_1.png, zqa_fl_2.png |  |
| 4 | zedqa_flyermap.lua | fm | PASS | 12 | zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png |  |
| 5 | zedqa_mapnotes.lua | mnote | PASS | 9 | zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png |  |
| 6 | zedqa_journal_refs.lua | jr | PASS | 5 | zqa_jr_01_diary.png, zqa_jr_02_flyers.png |  |
| 7 | zedqa_journal_readers.lua | jrd | PASS | 22 | zqa_jr_01_papers.png, zqa_jr_02_unread_look.png, zqa_jr_03_read_look.png, zqa_jr_04_notebooks.png, zqa_jr_05_written.png, zqa_jr_06_into.png, zqa_jr_07_logged.png |  |
| 8 | zedqa_reader.lua | rd | PASS | 11 | zqa_rd_01_paper.png, zqa_rd_02_words.png, zqa_rd_03_story2.png, zqa_rd_04_zoomed.png, zqa_rd_05_flier.png, zqa_rd_06_map.png |  |
| 9 | zedqa_reader_refs.lua | rr | PASS | 14 | zqa_rr_01_journal_flyers.png, zqa_rr_02_news_card.png, zqa_rr_03_vanilla_news_paper.png, zqa_rr_04_vanilla_news_words.png, zqa_rr_05_vanilla_flier_paper.png, zqa_rr_06_vanilla_flier_words.png, zqa_rr_07_vanilla_journal.png |  |
| 10 | zedqa_notebook.lua | nb | PASS | 8 | zqa_nb_01_page1.png, zqa_nb_02_erase_asks.png, zqa_nb_03_rail.png, zqa_nb_04_read_only.png, zqa_nb_05_locked_other.png |  |
| 11 | zedqa_print_fit.lua | pf | PASS | 14 | zqa_pf_1a_KnoxKnews_July1_vanilla.png, zqa_pf_1b_KnoxKnews_July1_fitted.png, zqa_pf_2a_KnoxKnews_July2_vanilla.png, zqa_pf_2b_KnoxKnews_July2_fitted.png, zqa_pf_3a_KentuckyHerald_July6_vanilla.png, zqa_pf_3b_KentuckyHerald_July6_fitted.png, zqa_pf_4a_NationalDispatch_July6_vanilla.png, zqa_pf_4b_NationalDispatch_July6_fitted.png |  |
| 12 | zedqa_print_typeset.lua | ts | PASS | 7 | zqa_ts_1_KnoxKnews_July1.png, zqa_ts_2_KnoxKnews_July2.png, zqa_ts_3_KentuckyHerald_July6.png, zqa_ts_4_NationalDispatch_July6.png |  |
| 13 | zedqa_props_plates.lua | props | PASS | 3 | zqa_props_1.png, zqa_props_2.png, zqa_props_3.png |  |
| 14 | zedqa_belt_strap.lua | belt | PASS | 2 | zqa_belt_strap_1.png |  |
| 15 | zedqa_straps.lua | straps | PASS | 12 | zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png |  |
| 16 | zedqa_buckle.lua | bk | PASS | 6 | zqa_bk_1.png, zqa_bk_2.png, zqa_bk_3.png |  |
| 17 | zedqa_buckles.lua | bks | PASS | 41 | zqa_bk_01_burgerflipper.png, zqa_bk_02_repairman.png, zqa_bk_03_burglar.png, zqa_bk_04_engineer.png, zqa_bk_05_fisherman.png, zqa_bk_06_policeofficer.png, zqa_bk_07_lumberjack.png, zqa_bk_08_smither.png, zqa_bk_09_farmer.png, zqa_bk_10_electrician.png, zqa_bk_11_fireofficer.png, zqa_bk_12_metalworker.png, zqa_bk_13_fitnessinstructor.png, zqa_bk_14_veteran.png, zqa_bk_15_tailor.png, zqa_bk_16_chef.png, zqa_bk_17_doctor.png, zqa_bk_18_parkranger.png, zqa_bk_19_unemployed.png, zqa_bk_20_nurse.png, zqa_bk_21_securityguard.png, zqa_bk_22_carpenter.png, zqa_bk_23_mechanics.png, zqa_bk_24_rancher.png, zqa_bk_25_constructionworker.png |  |
| 18 | zedqa_beltwatch.lua | bw | PASS | 13 | zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png |  |
| 19 | zedqa_hands_together.lua | ht | PASS | 19 | zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png |  |
| 20 | zedqa_watches2.lua | watches | PASS | 31 | zqa_watch_day_DigitalBlack.png, zqa_watch_day_DigitalDress.png, zqa_watch_day_DigitalRed.png, zqa_watch_day_DigitalTimez.png, zqa_watch_day_ClassicBlack.png, zqa_watch_day_ClassicGold.png, zqa_watch_day_ClassicBrown.png, zqa_watch_day_ClassicMilitary.png, zqa_watch_day_Expensive.png, zqa_watch_set_DigitalBlack.png, zqa_watch_night_DigitalBlack.png, zqa_watch_night_DigitalTimez.png, zqa_watch_lit_DigitalTimez.png, zqa_watch_night_ClassicBrown.png, zqa_watch_lit_ClassicBrown.png, zqa_watch_night_Expensive.png |  |
| 21 | zedqa_food_verbs.lua | fv | PASS | 4 | zqa_fv_smoking.png |  |
| 22 | zedqa_moodles.lua | mood | PASS | 21 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png |  |
| 23 | zedqa_twoway.lua | tw | **FAIL** | 52 | zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png | 7 Java exception(s) in the log; 13 ERR line(s) |
| 24 | zedqa_rtv.lua | rtv | PASS | 83 | zqa_rtv_1_radio_black.png, zqa_rtv_1_radio_red.png, zqa_rtv_1b_radio_red_list.png, zqa_rtv_1_radio_handbuilt.png, zqa_rtv_1_cd_player.png, zqa_rtv_1b_cd_player_list.png, zqa_rtv_2_pad_cd_player_battery_list.png, zqa_rtv_2_pad_cd_player_phones_list.png, zqa_rtv_2_pad_cd_player_disc_list.png, zqa_rtv_3_simple_card.png, zqa_rtv_4a_radio_red_placed.png, zqa_rtv_4c_tv_black_standby.png, zqa_rtv_4d_tv_black_triple_n_standby.png, zqa_rtv_4d_tv_black_turbo_standby.png, zqa_rtv_4c_tv_black_bars.png, zqa_rtv_4e_tv_black_no_power.png, zqa_rtv_2_pad_tv_black_tape_list.png, zqa_rtv_2_pad_tv_black_phones_list.png, zqa_rtv_4c_tv_widescreen_standby.png, zqa_rtv_4d_tv_widescreen_triple_n_standby.png, zqa_rtv_4d_tv_widescreen_turbo_standby.png, zqa_rtv_4c_tv_widescreen_bars.png, zqa_rtv_4e_tv_widescreen_no_power.png, zqa_rtv_4c_tv_antique_standby.png, zqa_rtv_4d_tv_antique_triple_n_standby.png, zqa_rtv_4d_tv_antique_turbo_standby.png, zqa_rtv_4c_tv_antique_bars.png, zqa_rtv_4e_tv_antique_no_power.png, zqa_rtv_5_house_bare.png, zqa_rtv_5_house_ci_radio.png, zqa_rtv_5_house_ci_tv.png |  |
| 25 | zedqa_appliances.lua | ap | PASS | 11 | zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png |  |
| 26 | zedqa_plates_336.lua | p336 | PASS | 68 | zqa_p336_scale175_oven.png, zqa_p336_scale175_microwave.png, zqa_p336_scale175_chrome.png, zqa_p336_scale175_generator.png, zqa_p336_scale175_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png |  |
| 27 | zedqa_laundry.lua | ldy | PASS | 72 | zqa_ldy_washer_1_open.png, zqa_ldy_washer_1_open_later.png, zqa_ldy_washer_lvl1_water.png, zqa_ldy_washer_lvl2_water.png, zqa_ldy_washer_lvl3_water.png, zqa_ldy_washer_lvl4_water.png, zqa_ldy_washer_lvl5_water.png, zqa_ldy_washer_lvl1_soak.png, zqa_ldy_washer_lvl2_soak.png, zqa_ldy_washer_lvl3_soak.png, zqa_ldy_washer_lvl4_soak.png, zqa_ldy_washer_lvl5_soak.png, zqa_ldy_washer_3_nowater.png, zqa_ldy_washer_3_nopower.png, zqa_ldy_washer_2_running.png, zqa_ldy_dryer_1_open.png, zqa_ldy_dryer_1_open_later.png, zqa_ldy_dryer_3_nopower.png, zqa_ldy_dryer_2_running.png, zqa_ldy_combo_1_open.png, zqa_ldy_combo_1_open_later.png, zqa_ldy_combo_lvl1_water.png, zqa_ldy_combo_lvl2_water.png, zqa_ldy_combo_lvl3_water.png, zqa_ldy_combo_lvl4_water.png, zqa_ldy_combo_lvl5_water.png, zqa_ldy_combo_lvl1_soak.png, zqa_ldy_combo_lvl2_soak.png, zqa_ldy_combo_lvl3_soak.png, zqa_ldy_combo_lvl4_soak.png, zqa_ldy_combo_lvl5_soak.png, zqa_ldy_combo_3_nowater.png, zqa_ldy_combo_3_nopower.png, zqa_ldy_combo_2_running.png |  |
| 28 | zedqa_cazio_light.lua | czl | PASS | 38 | zqa_cl_day_DigitalBlack.png, zqa_cl_daylit_DigitalBlack.png, zqa_cl_night_DigitalBlack.png, zqa_cl_nightlit_DigitalBlack.png, zqa_cl_day_DigitalDress.png, zqa_cl_daylit_DigitalDress.png, zqa_cl_night_DigitalDress.png, zqa_cl_nightlit_DigitalDress.png, zqa_cl_day_ClassicBlack.png, zqa_cl_daylit_ClassicBlack.png, zqa_cl_night_ClassicBlack.png, zqa_cl_nightlit_ClassicBlack.png, zqa_cl_day_ClassicGold.png, zqa_cl_daylit_ClassicGold.png, zqa_cl_night_ClassicGold.png, zqa_cl_nightlit_ClassicGold.png, zqa_cl_belt_night.png, zqa_cl_belt_nightlit.png, zqa_cl_belt_day.png, zqa_cl_belt_daylit.png |  |
| 29 | zedqa_guide_bubble.lua | gbub | PASS | 62 | zqa_gbub_3840x2160_2_bubble_from_belt.png, zqa_gbub_3840x2160_3_guide_opened.png, zqa_gbub_3840x2160_7_controller_variant.png |  |
| 30 | zedqa_safemode.lua | safe | WARN | 14 | zqa_safe_1.png, zqa_safe_2.png, zqa_safe_3.png | 1 ERR line(s) |
| 31 | zedqa_soak.lua | soak | PASS | 147 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 26125 at 23:43:02

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre clock 22.63 -> 11.00 (daylight)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta12 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_mapstyles.lua (`ZEDQA mst`) - PASS, 15 s

- go 26126 at 23:43:08
- screenshots: zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA mst start
[ZeD.QA] run #2 ok=true
ZEDQA mst survey: style survey zoom 13 images 2
ZEDQA mst color: style color zoom 13 images 2
ZEDQA mst paper: style paper zoom 13 images 1
ZEDQA mst DONE
```

### 3. zedqa_flyers.lua (`ZEDQA fl`) - PASS, 6 s

- go 26127 at 23:43:26
- screenshots: zqa_fl_1.png, zqa_fl_2.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA fl start
[ZeD.QA] run #3 ok=true
ZEDQA fl read pieces: 18
ZEDQA fl piece mccoyloggingcorp
ZEDQA fl read now: 19
ZEDQA fl forgot true read 18
ZEDQA fl DONE
```

### 4. zedqa_flyermap.lua (`ZEDQA fm`) - PASS, 12 s

- go 26128 at 23:43:36
- screenshots: zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA fm start
[ZeD.QA] run #4 ok=true
ZEDQA fm read 20 (added 2)
ZEDQA fm tracker ticked the test place: false
ZEDQA fm pins on paper: muldraughbakesale, fossoil1(done), ustoreitmuldraugh, sunstarmotel
ZEDQA fm hover: sunstarmotel
ZEDQA fm reader open true media sunstarmotel title Angel Cross + Sunstar Motel
ZEDQA fm flash true
ZEDQA fm read back to 18
ZEDQA fm DONE
```

### 5. zedqa_mapnotes.lua (`ZEDQA mnote`) - PASS, 9 s

- go 26129 at 23:43:51
- screenshots: zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA mnote start
[ZeD.QA] run #5 ok=true
ZEDQA mnote gave 1 (pencil / eraser)
ZEDQA mnote map bound to the world map item: true
ZEDQA mnote before: store marks 0 | vanilla api marks 0 of 63 symbols (the rest are the map's own labels)
ZEDQA mnote text tool armed: true
ZEDQA mnote after note: store 0 -> 1 | vanilla api 0 -> 1 | found in store true | found by vanilla api true
ZEDQA mnote note ink 1 rgb 0.200 0.200 0.200 scale 0.6660000085830688 layer text-note
ZEDQA mnote star tool armed: true
ZEDQA mnote star as vanilla's Star: true ink 1 | store 2
ZEDQA mnote migration: first run added 2 (2 -> 4), second 0 (4), flag cleared 0 (4)
ZEDQA mnote migrated note ink 4 (want 4) | star ink 3 (want 3) | done flag true
ZEDQA mnote cursor finds the note: true
ZEDQA mnote cursor ui 420,228 | engine hit note 'ZEDQA note 73364' at world 865.5,12988.3 ui 420,251 | found note 'ZEDQA note 73364' at world 865.5,12988.3 ui 420,251 | the note note 'ZEDQA note 73364' at world 865.5,12988.3 ui 420,251
ZEDQA mnote menu: delete true | edit note true | change colour true | share false (multiplayer false)
ZEDQA mnote after delete: store 4 -> 3 | vanilla api 4 -> 3 | still found false / false
ZEDQA mnote removal: made a note true and a star true | store 3 -> 5
ZEDQA mnote removal: note true (5 -> 4), star true (-> 3), stale note again false (-> 3)
ZEDQA mnote style paper: map style paper | label layers 8 | strongest label alpha 0 | note hand alpha 255
ZEDQA mnote style survey: map style survey | label layers 8 | strongest label alpha 255 | note hand alpha 255
ZEDQA mnote style color: map style color | label layers 8 | strongest label alpha 255 | note hand alpha 255
ZEDQA mnote style back to survey
ZEDQA mnote cleanup: removed 3 marks | store 0 (started 0) | modData back
ZEDQA mnote DONE
```

### 6. zedqa_journal_refs.lua (`ZEDQA jr`) - PASS, 5 s

- go 26130 at 23:44:03
- screenshots: zqa_jr_01_diary.png, zqa_jr_02_flyers.png

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA jr start
[ZeD.QA] run #6 ok=true
ZEDQA jr DONE
```

### 7. zedqa_journal_readers.lua (`ZEDQA jrd`) - PASS, 22 s

- go 26131 at 23:44:12
- screenshots: zqa_jr_01_papers.png, zqa_jr_02_unread_look.png, zqa_jr_03_read_look.png, zqa_jr_04_notebooks.png, zqa_jr_05_written.png, zqa_jr_06_into.png, zqa_jr_07_logged.png

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA jrd start
[ZeD.QA] run #7 ok=true
ZEDQA jrd papers 2 books 2 zones 3
ZEDQA jrd unread look zones back,read
ZEDQA jrd read look zones back,full,place:1,words
ZEDQA jrd note field false page 1
ZEDQA jrd light after 1 ticks: tooDark false
ZEDQA jrd ok written line on page 1
ZEDQA jrd log entry saw 3 of them by the gas station around noon | source Supply runs p1
ZEDQA jrd book p1 now day 3. truck still wont start. tried the battery / from the van on 31W, nothing. maybe its the starter / fossoil on the flyer too. go round back / saw 3 of them by the gas station around noon
ZEDQA jrd DONE (newspaper had been read before: false)
```

### 8. zedqa_reader.lua (`ZEDQA rd`) - PASS, 11 s

- go 26132 at 23:44:37
- screenshots: zqa_rd_01_paper.png, zqa_rd_02_words.png, zqa_rd_03_story2.png, zqa_rd_04_zoomed.png, zqa_rd_05_flier.png, zqa_rd_06_map.png

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rd start
[ZeD.QA] run #8 ok=true
ZEDQA rd light after 3 ticks: tooDark false
ZEDQA rd open true view paper body 11.5
ZEDQA rd words blocks 12
ZEDQA rd flier places 1
ZEDQA rd map centre 10687,9831
ZEDQA rd DONE
```

### 9. zedqa_reader_refs.lua (`ZEDQA rr`) - PASS, 14 s

- go 26133 at 23:44:52
- screenshots: zqa_rr_01_journal_flyers.png, zqa_rr_02_news_card.png, zqa_rr_03_vanilla_news_paper.png, zqa_rr_04_vanilla_news_words.png, zqa_rr_05_vanilla_flier_paper.png, zqa_rr_06_vanilla_flier_words.png, zqa_rr_07_vanilla_journal.png

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rr start
[ZeD.QA] run #9 ok=true
ZEDQA rr items Base.Newspaper:zombie.inventory.types.Literature@70c02504 Base.Flier:zombie.inventory.types.Literature@3b467e44 Base.Notebook:zombie.inventory.types.Literature@652126ee
ZEDQA rr DONE
```

### 10. zedqa_notebook.lua (`ZEDQA nb`) - PASS, 8 s

- go 26134 at 23:45:09
- screenshots: zqa_nb_01_page1.png, zqa_nb_02_erase_asks.png, zqa_nb_03_rail.png, zqa_nb_04_read_only.png, zqa_nb_05_locked_other.png

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA nb start
[ZeD.QA] run #10 ok=true
ZEDQA nb light after 3 ticks: tooDark false
ZEDQA nb open true mode notebook pages 10 readOnly false
ZEDQA nb after done: name Supply runs p1 day 3. truck still wont start. p2 water: 2 bottles + the pot. ne action false window false
ZEDQA nb read only true
ZEDQA nb other lock true readOnly true
ZEDQA nb DONE
```

### 11. zedqa_print_fit.lua (`ZEDQA pf`) - PASS, 14 s

- go 26135 at 23:45:21
- screenshots: zqa_pf_1a_KnoxKnews_July1_vanilla.png, zqa_pf_1b_KnoxKnews_July1_fitted.png, zqa_pf_2a_KnoxKnews_July2_vanilla.png, zqa_pf_2b_KnoxKnews_July2_fitted.png, zqa_pf_3a_KentuckyHerald_July6_vanilla.png, zqa_pf_3b_KentuckyHerald_July6_fitted.png, zqa_pf_4a_NationalDispatch_July6_vanilla.png, zqa_pf_4b_NationalDispatch_July6_fitted.png

```text
[ZeD.QA] state #11 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pf start
[ZeD.QA] run #11 ok=true
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

### 12. zedqa_print_typeset.lua (`ZEDQA ts`) - PASS, 7 s

- go 26136 at 23:45:38
- screenshots: zqa_ts_1_KnoxKnews_July1.png, zqa_ts_2_KnoxKnews_July2.png, zqa_ts_3_KentuckyHerald_July6.png, zqa_ts_4_NationalDispatch_July6.png

```text
[ZeD.QA] state #12 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ts start
[ZeD.QA] run #12 ok=true
ZEDQA ts KnoxKnews_July1 stories 3 body 0.46153846153846156 lines 43
ZEDQA ts KnoxKnews_July2 stories 3 body -0.4307692307692238 lines 5
ZEDQA ts KentuckyHerald_July6 stories 2 body 12.653615384615385 lines 41
ZEDQA ts NationalDispatch_July6 stories 5 body 11.576923076923077 lines 86
ZEDQA ts DONE
```

### 13. zedqa_props_plates.lua (`ZEDQA props`) - PASS, 3 s

- go 26137 at 23:45:48
- screenshots: zqa_props_1.png, zqa_props_2.png, zqa_props_3.png

```text
[ZeD.QA] state #13 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #13 ok=true
ZEDQA props draw rod true/true slack true clock true/true
ZEDQA props DONE
```

### 14. zedqa_belt_strap.lua (`ZEDQA belt`) - PASS, 2 s

- go 26138 at 23:45:55
- screenshots: zqa_belt_strap_1.png

```text
[ZeD.QA] state #14 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #14 ok=true
ZEDQA belt textures true
ZEDQA belt shot; DONE
```

### 15. zedqa_straps.lua (`ZEDQA straps`) - PASS, 12 s

- go 26139 at 23:46:00
- screenshots: zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png

```text
[ZeD.QA] state #15 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #15 ok=true
ZEDQA straps put aside 1
ZEDQA straps civilian worn HolsterSimple_Brown,Belt2,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim
ZEDQA straps civilian slots Back=sling SmallBeltLeft=leather SmallBeltRight=leather HolsterRight=holster_brown | waist=leather closure=buckle
ZEDQA straps civilian shot
ZEDQA straps military worn Holster_DuctTape,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICE_BeltSus_Camo,Bag_ALICEpack_Army
ZEDQA straps military slots Back=webbing_olive SmallBeltLeft=webbing_camo SmallBeltRight=webbing_camo HolsterRight=holster_tape WebbingRight=webbing_camo WebbingLeft=webbing_camo BedrollBottomALICE=webbing_olive | waist=webbing_camo closure=clip_black
ZEDQA straps military shot
ZEDQA straps makeshift worn Holster_Hide,RopeBelt,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_CraftedFramepack_Large
ZEDQA straps makeshift slots Back=rope SmallBeltLeft=rope HolsterRight=holster_hide BedrollBottom=rope | waist=rope closure=knot
ZEDQA straps makeshift shot
ZEDQA straps firefighter worn Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,SCBA
ZEDQA straps firefighter slots Back=harness SmallBeltLeft=harness SmallBeltRight=harness WebbingLeft=harness | waist=harness closure=clip_black
ZEDQA straps firefighter shot
ZEDQA straps olive worn Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICE_BeltSus
ZEDQA straps olive slots Back=sling SmallBeltLeft=webbing_olive SmallBeltRight=webbing_olive WebbingLeft=webbing_olive WebbingRight=webbing_olive | waist=webbing_olive closure=clip_brass
ZEDQA straps olive shot
ZEDQA straps restored; DONE
```

### 16. zedqa_buckle.lua (`ZEDQA bk`) - PASS, 6 s

- go 26140 at 23:46:15
- screenshots: zqa_bk_1.png, zqa_bk_2.png, zqa_bk_3.png

```text
[ZeD.QA] state #16 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA bk start
[ZeD.QA] run #16 ok=true
ZEDQA bk centre 1920 vs screen 1920 | belt x 1535 w 662 | delta 0 | bare watch none
ZEDQA bk worn base:leftwrist
ZEDQA bk centre 1920 vs screen 1920 | belt x 1433 w 764 | delta 0 | cazio watch digital_black wrist left
ZEDQA bk worn base:rightwrist
ZEDQA bk centre 1920 vs screen 1920 | belt x 1433 w 764 | delta 0 | timez watch timez_easy wrist right
ZEDQA bk DONE
```

### 17. zedqa_buckles.lua (`ZEDQA bks`) - PASS, 41 s

- go 26141 at 23:46:25
- screenshots: zqa_bk_01_burgerflipper.png, zqa_bk_02_repairman.png, zqa_bk_03_burglar.png, zqa_bk_04_engineer.png, zqa_bk_05_fisherman.png, zqa_bk_06_policeofficer.png, zqa_bk_07_lumberjack.png, zqa_bk_08_smither.png, zqa_bk_09_farmer.png, zqa_bk_10_electrician.png, zqa_bk_11_fireofficer.png, zqa_bk_12_metalworker.png, zqa_bk_13_fitnessinstructor.png, zqa_bk_14_veteran.png, zqa_bk_15_tailor.png, zqa_bk_16_chef.png, zqa_bk_17_doctor.png, zqa_bk_18_parkranger.png, zqa_bk_19_unemployed.png, zqa_bk_20_nurse.png, zqa_bk_21_securityguard.png, zqa_bk_22_carpenter.png, zqa_bk_23_mechanics.png, zqa_bk_24_rancher.png, zqa_bk_25_constructionworker.png

```text
[ZeD.QA] state #17 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA bks professions 25
ZEDQA bks start
[ZeD.QA] run #17 ok=true
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
ZEDQA bks DONE (profession back to unemployed)
```

### 18. zedqa_beltwatch.lua (`ZEDQA bw`) - PASS, 13 s

- go 26142 at 23:47:09
- screenshots: zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png

```text
[ZeD.QA] state #18 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA bw start
[ZeD.QA] run #18 ok=true
ZEDQA bw worn base:leftwrist
ZEDQA bw box digital_black wrist left x 0 w 88 | hands s@102 p@190 | belt w 764
ZEDQA bw full watch tucked: 0x0
ZEDQA bw popped true at 1433,1671 248x352 | mini at 1433,2037
ZEDQA bw dragged to 1500,500 saved 857.1428571428571,285.7142857142857
ZEDQA bw after idle: popped true size 248
ZEDQA bw right wrist: timez_easy wrist right x 200 | hands s@0 p@88
ZEDQA bw corner: box false full watch 3524,10 300x352
ZEDQA bw DONE
```

### 19. zedqa_hands_together.lua (`ZEDQA ht`) - PASS, 19 s

- go 26143 at 23:47:25
- screenshots: zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png

```text
[ZeD.QA] state #19 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ht start
[ZeD.QA] run #19 ok=true
ZEDQA ht 01 two items | OFF@0/77 MAIN@88/98 #1@225/77 #2@468/77 #3@564/77 | dark small | belt x1535 y2034 w662 h98
ZEDQA ht PASS 01 two items: both hands are on the belt
ZEDQA ht PASS 01 two items: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 01 two items: the off hand comes before the main hand
ZEDQA ht PASS 01 two items: the hands sit before the slots (the left end)
ZEDQA ht PASS 01 two items: the boxes run left to right
ZEDQA ht PASS 01 two items: the hands are 6 units apart (11 px)
ZEDQA ht PASS 01 two items: a click at the off hand's right edge finds the off hand
ZEDQA ht 02 both hands | off(peek)@0/77 MAIN@25/98 #1@162/77 #2@405/77 #3@501/77 | dark small | belt x1598 y2034 w599 h98
ZEDQA ht PASS 02 both hands: both hands are on the belt
ZEDQA ht PASS 02 both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 02 both hands: the off hand comes before the main hand
ZEDQA ht PASS 02 both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 02 both hands: the boxes run left to right
ZEDQA ht PASS 02 both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 02 both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 02 both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 02 both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 02 both hands: slot 1 stays in place on screen (1760, was 1760)
ZEDQA ht 03 both, high contrast | off(peek)@0/77 MAIN@25/98 #1@162/77 #2@405/77 #3@501/77 | hicon small | belt x1598 y2034 w599 h98
ZEDQA ht PASS 03 both, high contrast: both hands are on the belt
ZEDQA ht PASS 03 both, high contrast: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 03 both, high contrast: the off hand comes before the main hand
ZEDQA ht PASS 03 both, high contrast: the hands sit before the slots (the left end)
ZEDQA ht PASS 03 both, high contrast: the boxes run left to right
ZEDQA ht PASS 03 both, high contrast: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 03 both, high contrast: the crescent's mark is 44 px wide
ZEDQA ht PASS 03 both, high contrast: a click at the crescent finds the off hand
ZEDQA ht PASS 03 both, high contrast: a click where the two overlap finds the main hand
ZEDQA ht 04 both, large | off(peek)@0/89 MAIN@28/113 #1@185/89 #2@446/89 #3@557/89 | dark large | belt x1560 y2015 w670 h113
ZEDQA ht PASS 04 both, large: both hands are on the belt
ZEDQA ht PASS 04 both, large: the main hand is 56 units, the off hand 44 (113, 89 px; 56u = 113)
ZEDQA ht PASS 04 both, large: the off hand comes before the main hand
ZEDQA ht PASS 04 both, large: the hands sit before the slots (the left end)
ZEDQA ht PASS 04 both, large: the boxes run left to right
ZEDQA ht PASS 04 both, large: the off hand peeks 14 units from under the main hand (28 px)
ZEDQA ht PASS 04 both, large: the crescent's mark is 50 px wide
ZEDQA ht PASS 04 both, large: a click at the crescent finds the off hand
ZEDQA ht PASS 04 both, large: a click where the two overlap finds the main hand
ZEDQA ht pad two items | OFF@0/77 MAIN@88/98 #1@225/77 #2@468/77 #3@564/77 | dark small | belt x1535 y2034 w662 h98
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
ZEDQA ht 05 left wrist, both hands | watch@0/88 off(peek)@102/77 MAIN@127/98 #1@264/77 #2@507/77 #3@603/77 | dark small | belt x1496 y2034 w701 h98
ZEDQA ht PASS 05 left wrist, both hands: both hands are on the belt
ZEDQA ht PASS 05 left wrist, both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 05 left wrist, both hands: the off hand comes before the main hand
ZEDQA ht PASS 05 left wrist, both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 05 left wrist, both hands: the boxes run left to right
ZEDQA ht PASS 05 left wrist, both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 05 left wrist, both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 05 left wrist, both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 05 left wrist, both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 05 left wrist, both hands: slot 1 stays in place on screen (1760, was 1760)
ZEDQA ht PASS 05: the left-wrist watch sits beside the peeking off hand
ZEDQA ht 06 right wrist, pistol | OFF@0/77 MAIN@88/98 ammo@137/255 watch@406/88 #1@533/77 #2@776/77 #3@872/77 | dark small | belt x1227 y2034 w970 h98
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
ZEDQA ht 08 empty pistol | OFF@0/77 MAIN@88/98 ammo@137/255 #1@431/77 #2@674/77 #3@770/77 | dark small | belt x1329 y2034 w868 h98
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
ZEDQA ht 09 shotgun, both hands | off(peek)@0/77 MAIN@25/98 ammo@74/255 #1@368/77 #2@611/77 #3@707/77 | dark small | belt x1392 y2034 w805 h98
ZEDQA ht PASS 09 shotgun, both hands: both hands are on the belt
ZEDQA ht PASS 09 shotgun, both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 09 shotgun, both hands: the off hand comes before the main hand
ZEDQA ht PASS 09 shotgun, both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 09 shotgun, both hands: the boxes run left to right
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

### 20. zedqa_watches2.lua (`ZEDQA watches`) - PASS, 31 s

- go 26144 at 23:47:48
- screenshots: zqa_watch_day_DigitalBlack.png, zqa_watch_day_DigitalDress.png, zqa_watch_day_DigitalRed.png, zqa_watch_day_DigitalTimez.png, zqa_watch_day_ClassicBlack.png, zqa_watch_day_ClassicGold.png, zqa_watch_day_ClassicBrown.png, zqa_watch_day_ClassicMilitary.png, zqa_watch_day_Expensive.png, zqa_watch_set_DigitalBlack.png, zqa_watch_night_DigitalBlack.png, zqa_watch_night_DigitalTimez.png, zqa_watch_lit_DigitalTimez.png, zqa_watch_night_ClassicBrown.png, zqa_watch_lit_ClassicBrown.png, zqa_watch_night_Expensive.png

```text
[ZeD.QA] state #20 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #20 ok=true
ZEDQA watches own watch nil at nil
ZEDQA watches no own watch; location base:leftwrist
ZEDQA watches item left true right true
ZEDQA watches name 'Digital Watch - Steel Sport Style' icon %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\Item_ZeDWatchTimezSteel.png world Base.ZeDDigitalWatchSteel clothing true/WristWatch_Left_DigitalTimez digital true class true
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

### 21. zedqa_food_verbs.lua (`ZEDQA fv`) - PASS, 4 s

- go 26145 at 23:48:21
- screenshots: zqa_fv_smoking.png

```text
[ZeD.QA] state #21 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA fv start
[ZeD.QA] run #21 ok=true
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

### 22. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 21 s

- go 26146 at 23:48:29
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
[ZeD.QA] state #22 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #22 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 5
ZEDQA mood box by itself: TIRED | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA mood right: 5 moodles on (TIRED 2, HUNGRY 2, PANIC 1, STRESS 2, THIRST 2)
ZEDQA mood PASS right: the place is in effect
ZEDQA mood PASS right: at least three moodles are on
ZEDQA mood PASS right: the moodles are shown (layer)
ZEDQA mood right column at 3782,940 size 48, stack 280; visible true
ZEDQA mood PASS right: vanilla's column is visible
ZEDQA mood PASS right: every moodle is on screen
ZEDQA mood PASS right: the column is on the right edge (x 3782)
ZEDQA mood PASS right: ZeD's hover layer lies over the column
ZEDQA mood right bubble: moodle 2, cloud -517,71 495x86.19140625, trail balloon from nil,nil
ZEDQA mood PASS right: the bubble is for the moodle under the pointer
ZEDQA mood PASS right: the balloon sits beside its moodle, clear of it
ZEDQA mood left: 5 moodles on (TIRED 2, HUNGRY 2, PANIC 2, STRESS 2, THIRST 2)
ZEDQA mood PASS left: the place is in effect
ZEDQA mood PASS left: at least three moodles are on
ZEDQA mood PASS left: the moodles are shown (layer)
ZEDQA mood left column at 10,940 size 48, stack 280; visible true
ZEDQA mood PASS left: vanilla's column is visible
ZEDQA mood PASS left: every moodle is on screen
ZEDQA mood PASS left: the column is on the left edge (x 10)
ZEDQA mood PASS left: ZeD's hover layer lies over the column
ZEDQA mood left bubble: moodle 2, cloud 70,71 495x86.19140625, trail balloon from nil,nil
ZEDQA mood PASS left: the bubble is for the moodle under the pointer
ZEDQA mood PASS left: the balloon sits beside its moodle, clear of it
ZEDQA mood bottom: 5 moodles on (TIRED 2, HUNGRY 2, PANIC 2, STRESS 2, THIRST 2)
ZEDQA mood PASS bottom: the place is in effect
ZEDQA mood PASS bottom: at least three moodles are on
ZEDQA mood PASS bottom: the moodles are shown (layer)
ZEDQA mood bottom row at 1780,1965 280x48; vanilla's column y -10000
ZEDQA mood PASS bottom: the row is on screen
ZEDQA mood PASS bottom: the row is centred (middle 1920 of 3840)
ZEDQA mood PASS bottom: the row sits above the belt
ZEDQA mood PASS bottom: one slot per moodle
ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
ZEDQA mood bottom bubble: moodle 2, cloud 68,-108.19140625 495x86.19140625, trail balloon from nil,nil
ZEDQA mood PASS bottom: the bubble is for the moodle under the pointer
ZEDQA mood PASS bottom: the balloon sits beside its moodle, clear of it
ZEDQA mood PASS with nothing changing the box goes by itself (nil)
ZEDQA mood notices off: box nil | waiting 3
ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
ZEDQA mood all checks passed
ZEDQA mood DONE
```

### 23. zedqa_twoway.lua (`ZEDQA tw`) - FAIL, 52 s

- go 26147 at 23:48:53
- 7 Java exception(s) in the log
- 13 ERR line(s)
- screenshots: zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png

```text
[ZeD.QA] state #23 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA tw start
[ZeD.QA] run #23 ok=true
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
ZEDQA tw walkie_valutech: display 107.600 | | BAT 3
ZEDQA tw PASS walkie_valutech: BAT with 3 bars at 60% charge
ZEDQA tw valutech: body 585 px tall, the face's body needs 799 (window 735)
ZEDQA tw PASS valutech: at the default height the body scrolls
ZEDQA tw PASS valutech: the wheel off the knobs scrolls the body (0 -> 0.05)
ZEDQA tw valutech: the face and footer need 1190 px with 380 px of fill blocks (body 585)
ZEDQA tw PASS valutech: the grown window shows the whole face, no scrollbar
ZEDQA tw PASS VOL: the wheel turns the volume up (0.50 -> 0.60)
ZEDQA tw PASS TUNE: a click on its right half tunes up a step (107600 -> 107800)
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
ZEDQA tw FAIL the header button opens full view on the radio
ERROR: General f:17178 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: _hits of non-table: null
ERROR: General f:17178> Lua(Vanilla).vclick> Exception thrown
    java.lang.RuntimeException: attempted index: _hits of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).vclick(worldmap-annotations.lua:114)
    Lua(Vanilla).step(worldmap-annotations.lua:342)
    Lua(Vanilla).tick(worldmap-annotations.lua:797)
ZEDQA tw ERR step 25: attempted index: _hits of non-table: null java.lang.RuntimeException
ZEDQA tw FAIL a control in full view works (CH down)
ERROR: General f:17183 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: _hits of non-table: null
ERROR: General f:17183> Lua(Vanilla).step> Exception thrown
    java.lang.RuntimeException: attempted index: _hits of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).step(worldmap-annotations.lua:347)
    Lua(Vanilla).tick(worldmap-annotations.lua:797)
ZEDQA tw ERR step 26: attempted index: _hits of non-table: null java.lang.RuntimeException
ZEDQA tw ERR step 27: waited 120 frames
ZEDQA tw FAIL MEM held in full view opens the naming box
ERROR: General f:17307 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: onMouseUp of non-table: null
ERROR: General f:17307> Lua(Vanilla).isReallyVisible> Exception thrown
    java.lang.RuntimeException: attempted index: onMouseUp of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).isReallyVisible(worldmap-annotations.lua:353)
    Lua(Vanilla).tick(worldmap-annotations.lua:797)
ZEDQA tw ERR step 27: attempted index: onMouseUp of non-table: null java.lang.RuntimeException
ERROR: General f:17312 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getHeight of non-table: null
ERROR: General f:17312> Lua(Vanilla).step> Exception thrown
    java.lang.RuntimeException: attempted index: getHeight of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).step(worldmap-annotations.lua:365)
    Lua(Vanilla).tick(worldmap-annotations.lua:797)
ZEDQA tw ERR step 28: attempted index: getHeight of non-table: null java.lang.RuntimeException
ERROR: General f:17315 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: onMouseMove of non-table: null
ERROR: General f:17315> Lua(Vanilla).step> Exception thrown
    java.lang.RuntimeException: attempted index: onMouseMove of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).step(worldmap-annotations.lua:372)
    Lua(Vanilla).tick(worldmap-annotations.lua:797)
ZEDQA tw ERR step 29: attempted index: onMouseMove of non-table: null java.lang.RuntimeException
ERROR: General f:17318 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: onMouseUp of non-table: null
ERROR: General f:17318> Lua(Vanilla).step> Exception thrown
    java.lang.RuntimeException: attempted index: onMouseUp of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).step(worldmap-annotations.lua:373)
    Lua(Vanilla).tick(worldmap-annotations.lua:797)
ZEDQA tw ERR step 30: attempted index: onMouseUp of non-table: null java.lang.RuntimeException
ERROR: General f:17323 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: getX of non-table: null
ERROR: General f:17323> Lua(Vanilla).step> Exception thrown
    java.lang.RuntimeException: attempted index: getX of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).step(worldmap-annotations.lua:376)
    Lua(Vanilla).tick(worldmap-annotations.lua:797)
ZEDQA tw ERR step 31: attempted index: getX of non-table: null java.lang.RuntimeException
ZEDQA tw PASS the header button closes full view
ZEDQA tw PASS the point between the knobs is no control
ZEDQA tw PASS a click on the face away from the controls opens full view
ZEDQA tw FAIL it opens where it was dragged to
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
ZEDQA tw walkie_toy: display 129.00 MHZ | nil | nil nil
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
ZEDQA tw walkie_premium: display 041.400 | | BAT 3
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
ZEDQA tw walkie_tactical: display 385.000 | | BAT 3
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
ZEDQA tw walkie_army: display 098.000 | NNR RADIO | BAT 3
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
ZEDQA tw walkie_makeshift: display CH-- 125.80 | | nil nil
ZEDQA tw PASS makeshift: its character display reads CH.. (CH-- 125.80)
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
ZEDQA tw walkie_manpack: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | BAT 3
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
ZEDQA tw ham_civilian: display 310.600 | | range RANGE 7.5 KM
ZEDQA tw PASS ham_civilian: the display reads while on
ZEDQA tw PASS the drawer's clip is set and cleared in pairs with a ham showing (20 sets, 20 clears)
ZEDQA tw PASS civilian ham: RANGE matches its transmit range (RANGE 7.5 KM)
ZEDQA tw PASS civilian ham: the band marker follows the frequency down (0.6134693877551021 -> 0.5114285714285715)
ZEDQA tw FAIL civilian ham: full view opens
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
ZEDQA tw ham_makeshift: display CH-- 219.600 MHZ | | range RANGE 6 KM
ZEDQA tw PASS ham_makeshift: the display reads while on
ZEDQA tw PASS makeshift ham: the TALK / LISTEN toggle flips with the mic
ZEDQA tw PASS makeshift ham: full view opens
ZEDQA tw PASS full view closes when the set is taken away
ZEDQA tw cleanup: 3 sets and 8 items taken away
ZEDQA tw 180 passed, 5 failed
ZEDQA tw 5 failed
ZEDQA tw DONE
```

### 24. zedqa_rtv.lua (`ZEDQA rtv`) - PASS, 83 s

- go 26148 at 23:49:49
- screenshots: zqa_rtv_1_radio_black.png, zqa_rtv_1_radio_red.png, zqa_rtv_1b_radio_red_list.png, zqa_rtv_1_radio_handbuilt.png, zqa_rtv_1_cd_player.png, zqa_rtv_1b_cd_player_list.png, zqa_rtv_2_pad_cd_player_battery_list.png, zqa_rtv_2_pad_cd_player_phones_list.png, zqa_rtv_2_pad_cd_player_disc_list.png, zqa_rtv_3_simple_card.png, zqa_rtv_4a_radio_red_placed.png, zqa_rtv_4c_tv_black_standby.png, zqa_rtv_4d_tv_black_triple_n_standby.png, zqa_rtv_4d_tv_black_turbo_standby.png, zqa_rtv_4c_tv_black_bars.png, zqa_rtv_4e_tv_black_no_power.png, zqa_rtv_2_pad_tv_black_tape_list.png, zqa_rtv_2_pad_tv_black_phones_list.png, zqa_rtv_4c_tv_widescreen_standby.png, zqa_rtv_4d_tv_widescreen_triple_n_standby.png, zqa_rtv_4d_tv_widescreen_turbo_standby.png, zqa_rtv_4c_tv_widescreen_bars.png, zqa_rtv_4e_tv_widescreen_no_power.png, zqa_rtv_4c_tv_antique_standby.png, zqa_rtv_4d_tv_antique_triple_n_standby.png, zqa_rtv_4d_tv_antique_turbo_standby.png, zqa_rtv_4c_tv_antique_bars.png, zqa_rtv_4e_tv_antique_no_power.png, zqa_rtv_5_house_bare.png, zqa_rtv_5_house_ci_radio.png, zqa_rtv_5_house_ci_tv.png

```text
[ZeD.QA] state #24 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtv start
[ZeD.QA] run #24 ok=true
ZEDQA rtv screen 3840x2160, root scale 1.75, plate zoom 2
ZEDQA rtv PASS radio_black: the Character window's Radio tab opens
ZEDQA rtv PASS radio_black: its own face, radio_black (got radio_black)
ZEDQA rtv PASS radio_black: the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS radio_black: the width that fills the half card (radio_black, got radio_black)
ZEDQA rtv PASS radio_black: centred in the card, left gap 20, right gap 20
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
ZEDQA rtv PASS radio_red: centred in the card, left gap 20, right gap 20
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
ZEDQA rtv PASS radio_handbuilt: centred in the card, left gap 20, right gap 20
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
ZEDQA rtv PASS cd_player: centred in the card, left gap 20, right gap 20
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
ZEDQA rtv indoors at 892,13007 (5 free room squares round it)
ZEDQA rtv grid: world power true, this square haveElectricity false, hasGridPower true, in a room true
ZEDQA rtv PASS the staging square has grid power
ZEDQA rtv placed 4 sets (round the character, on their squares)
ZEDQA rtv PASS the World window lists the placed sets (4)
ZEDQA rtv PASS the World window's Radio tab opens on the placed sets
ZEDQA rtv PASS radio_red (placed, by its tile): its own face, radio_red (got radio_red)
ZEDQA rtv PASS radio_red (placed, by its tile): the World window's full card (the half card only held in) (840 px, want 840)
ZEDQA rtv PASS radio_red (placed, by its tile): centred in the card, left gap 247, right gap 248
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
ZEDQA rtv PASS tv_black: the channel display reads (04)
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
ZEDQA rtv PASS tv_widescreen: the channel display reads (04)
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
ZEDQA rtv PASS tv_antique: the channel display reads (09)
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
ZEDQA rtv PASS house_bare in the Radio tab: the World window's full card (the half card only held in) (840 px, want 840)
ZEDQA rtv PASS house_bare in the Radio tab: centred in the card, left gap 247, right gap 248
ZEDQA rtv PASS house_bare in the Radio tab: no full view button (a two-way set's)
ZEDQA rtv PASS house_bare in the Radio tab: every control on the face (11 of 11)
ZEDQA rtv PASS house_bare: on the grid (true)
ZEDQA rtv PASS house_ci_radio in the Radio tab: its own face, radio_black (got radio_black)
ZEDQA rtv PASS house_ci_radio in the Radio tab: the World window's full card (the half card only held in) (840 px, want 840)
ZEDQA rtv PASS house_ci_radio in the Radio tab: centred in the card, left gap 247, right gap 248
ZEDQA rtv PASS house_ci_radio in the Radio tab: no full view button (a two-way set's)
ZEDQA rtv PASS house_ci_radio in the Radio tab: every control on the face (11 of 11)
ZEDQA rtv PASS house_ci_radio: on the grid (true)
ZEDQA rtv PASS house_ci_tv in the Radio tab: its own face, tv_widescreen (got tv_widescreen@392)
ZEDQA rtv PASS house_ci_tv in the Radio tab: the full card (840 px)
ZEDQA rtv PASS house_ci_tv in the Radio tab: no full view button (a two-way set's)
ZEDQA rtv PASS house_ci_tv in the Radio tab: every control on the face (10 of 10)
ZEDQA rtv PASS house_ci_tv: on the grid (true)
ZEDQA rtv cleanup: sets, house sets and 7 items taken away
ZEDQA rtv back at 925,13040
ZEDQA rtv 209 passed, 0 failed
ZEDQA rtv all checks passed
ZEDQA rtv DONE
ERROR: General f:21466 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```

### 25. zedqa_appliances.lua (`ZEDQA ap`) - PASS, 11 s

- go 26149 at 23:51:15
- screenshots: zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png

```text
[ZeD.QA] state #25 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ap start
[ZeD.QA] run #25 ok=true
ZEDQA ap indoors at 891,13006
ZEDQA ap placed: stove true, microwave true
ZEDQA ap PASS the stove opens in the Craft tab
ZEDQA ap stove powered true (grid power on the square true, object index 4, world power true)
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
ZEDQA ap back at 925,13040
ZEDQA ap all checks passed
ZEDQA ap DONE
ERROR: General f:22276 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```

### 26. zedqa_plates_336.lua (`ZEDQA p336`) - PASS, 68 s

- go 26150 at 23:51:30
- screenshots: zqa_p336_scale175_oven.png, zqa_p336_scale175_microwave.png, zqa_p336_scale175_chrome.png, zqa_p336_scale175_generator.png, zqa_p336_scale175_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png

```text
[ZeD.QA] state #26 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA p336 start
[ZeD.QA] run #26 ok=true
ZEDQA p336 indoors at 891,13006
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
ERROR: General f:24657 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 894.5,13007.5 (grill 893,13008)
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
ERROR: General f:27596 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 894.5,13007.5 (grill 893,13008)
ZEDQA p336 PASS grill: the burner knob lights it (lit)
ZEDQA p336 cleanup done: 5 things removed
ZEDQA p336 all checks passed
ZEDQA p336 DONE
ERROR: General f:28544 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```

### 27. zedqa_laundry.lua (`ZEDQA ldy`) - PASS, 72 s

- go 26151 at 23:52:41
- screenshots: zqa_ldy_washer_1_open.png, zqa_ldy_washer_1_open_later.png, zqa_ldy_washer_lvl1_water.png, zqa_ldy_washer_lvl2_water.png, zqa_ldy_washer_lvl3_water.png, zqa_ldy_washer_lvl4_water.png, zqa_ldy_washer_lvl5_water.png, zqa_ldy_washer_lvl1_soak.png, zqa_ldy_washer_lvl2_soak.png, zqa_ldy_washer_lvl3_soak.png, zqa_ldy_washer_lvl4_soak.png, zqa_ldy_washer_lvl5_soak.png, zqa_ldy_washer_3_nowater.png, zqa_ldy_washer_3_nopower.png, zqa_ldy_washer_2_running.png, zqa_ldy_dryer_1_open.png, zqa_ldy_dryer_1_open_later.png, zqa_ldy_dryer_3_nopower.png, zqa_ldy_dryer_2_running.png, zqa_ldy_combo_1_open.png, zqa_ldy_combo_1_open_later.png, zqa_ldy_combo_lvl1_water.png, zqa_ldy_combo_lvl2_water.png, zqa_ldy_combo_lvl3_water.png, zqa_ldy_combo_lvl4_water.png, zqa_ldy_combo_lvl5_water.png, zqa_ldy_combo_lvl1_soak.png, zqa_ldy_combo_lvl2_soak.png, zqa_ldy_combo_lvl3_soak.png, zqa_ldy_combo_lvl4_soak.png, zqa_ldy_combo_lvl5_soak.png, zqa_ldy_combo_3_nowater.png, zqa_ldy_combo_3_nopower.png, zqa_ldy_combo_2_running.png

```text
[ZeD.QA] state #27 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ldy start
[ZeD.QA] run #27 ok=true
ZEDQA ldy indoors at 892,13007 (3 free room sides)
ZEDQA ldy placed IsoClothingWasher (appliances_laundry_01_4) at 891,13007 (one square from the character at 892,13007): in a room true, container clothingwasher, powered true, tile piped true
ZEDQA ldy placed IsoClothingDryer (appliances_laundry_01_12) at 892,13006 (one square from the character at 892,13007): in a room true, container clothingdryer, powered true, tile piped false
ZEDQA ldy placed IsoCombinationWasherDryer (appliances_laundry_01_0) at 892,13008 (one square from the character at 892,13007): in a room true, container clothingwasher, powered true, tile piped true
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
ZEDQA ldy washer: running, lamps phWash, dial 0.00555419921875, drum 0.167
ZEDQA ldy PASS washer: the run lamp lights
ZEDQA ldy PASS washer: one phase lamp, the first (phWash)
ZEDQA ldy PASS washer: the next phase lamp a phase later (phRinse)
ZEDQA ldy PASS washer: the cycle dial moves (0.410528564453125)
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
ZEDQA ldy dryer: running, lamps phDry, dial 0.008331298828125, drum 0.16550000000000006
ZEDQA ldy PASS dryer: the run lamp lights
ZEDQA ldy PASS dryer: one phase lamp, the first (phDry)
ZEDQA ldy PASS dryer: the next phase lamp a phase later (phCool)
ZEDQA ldy PASS dryer: the cycle dial moves (0.6150604248046875)
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
ZEDQA ldy combo: running, lamps phWash, dial 0.001953125, drum 0.0665
ZEDQA ldy PASS combo: the run lamp lights
ZEDQA ldy PASS combo: one phase lamp, the first (phWash)
ZEDQA ldy PASS combo: the next phase lamp a phase later (phRinse)
ZEDQA ldy PASS combo: the cycle dial moves (0.4067138671875)
ZEDQA ldy PASS combo: the drum turns
ZEDQA ldy PASS combo: power stops it
ZEDQA ldy PASS combo: stopped again: lamps dark, the dial at 0
ZEDQA ldy combo: plain row take same floor obj:ISLootWindowObjectControlHandler_CombinationWasherDryerSetMode obj:ISLootWindowObjectControlHandler_CombinationWasherDryerToggle
ZEDQA ldy PASS combo: LD.useFace false: no gears button
ZEDQA ldy PASS combo: LD.useFace false: vanilla's own laundry buttons are back
ZEDQA ldy cleanup done: 3 machines removed, 5 items taken back
ZEDQA ldy back at 925,13040
ZEDQA ldy all checks passed
ZEDQA ldy DONE
ERROR: General f:32215 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```

### 28. zedqa_cazio_light.lua (`ZEDQA czl`) - PASS, 38 s

- go 26152 at 23:53:57
- screenshots: zqa_cl_day_DigitalBlack.png, zqa_cl_daylit_DigitalBlack.png, zqa_cl_night_DigitalBlack.png, zqa_cl_nightlit_DigitalBlack.png, zqa_cl_day_DigitalDress.png, zqa_cl_daylit_DigitalDress.png, zqa_cl_night_DigitalDress.png, zqa_cl_nightlit_DigitalDress.png, zqa_cl_day_ClassicBlack.png, zqa_cl_daylit_ClassicBlack.png, zqa_cl_night_ClassicBlack.png, zqa_cl_nightlit_ClassicBlack.png, zqa_cl_day_ClassicGold.png, zqa_cl_daylit_ClassicGold.png, zqa_cl_night_ClassicGold.png, zqa_cl_nightlit_ClassicGold.png, zqa_cl_belt_night.png, zqa_cl_belt_nightlit.png, zqa_cl_belt_day.png, zqa_cl_belt_daylit.png

```text
[ZeD.QA] state #28 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA czl start
[ZeD.QA] run #28 ok=true
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
ZEDQA czl timer pressed at 1794556463496
ZEDQA czl light out after 3012 ms; lit=false bulb=false dark=true
ZEDQA czl Expensive light control false
ZEDQA czl Expensive after a stray light press: lit=false bulb=false dark=true
ZEDQA czl belt watch box 1
ZEDQA czl belt mini after Y: lit=true night=true dark=false
ZEDQA czl restored own watch nil
ZEDQA czl DONE
```

### 29. zedqa_guide_bubble.lua (`ZEDQA gbub`) - PASS, 62 s

- go 26153 at 23:54:37
- screenshots: zqa_gbub_3840x2160_2_bubble_from_belt.png, zqa_gbub_3840x2160_3_guide_opened.png, zqa_gbub_3840x2160_7_controller_variant.png

```text
[ZeD.QA] state #29 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gbub start
[ZeD.QA] run #29 ok=true
ZEDQA gbub PASS 1: a fresh machine arms the clock
ZEDQA gbub PASS 1: the guide is not open 20 s after the start (it used to open full screen)
ZEDQA gbub PASS 1: no bubble before 30 s
ZEDQA gbub PASS 2: the bubble is up at about 30 s of play
ZEDQA gbub PASS 2: the director's wording exactly, with F1
ZEDQA gbub PASS 2: a long bare balloon for player one
ZEDQA gbub PASS 2: the line is in Messages, unread
ZEDQA gbub PASS 2: the flag file says shown
ZEDQA gbub PASS 2: the guide is still closed
ZEDQA gbub shot 2_bubble_from_belt
ZEDQA gbub PASS 3: the balloon has a click
ZEDQA gbub PASS 3: the click opened the guide
ZEDQA gbub PASS 3: the balloon is gone, the line stays in Messages
ZEDQA gbub shot 3_guide_opened
ZEDQA gbub PASS 4: the first showing, one line
ZEDQA gbub PASS 4: it came back and the line is not doubled
ZEDQA gbub PASS 4: a right-click dismisses it
ZEDQA gbub PASS 4: nothing comes back after a dismiss
ZEDQA gbub PASS 4: the line stays
ZEDQA gbub PASS 5: a live offer
ZEDQA gbub PASS 5: F1 by any road ends the offer and takes the balloon off
ZEDQA gbub PASS 5: the line carries its Open
ZEDQA gbub PASS 5: the line's Open opens the guide
ZEDQA gbub PASS 6: a machine that has had its bubble arms nothing
ZEDQA gbub PASS 6: with the flag emptied it arms again
ZEDQA gbub PASS 7: on a controller the key words are the Help wheel's, not F1
ZEDQA gbub PASS 7: the controller's balloon is up
ZEDQA gbub PASS 7: and it names no F1
ZEDQA gbub shot 7_controller_variant
ZEDQA gbub PASS 8: the game's own guide window is not up
ZEDQA gbub PASS 8: no ZeD guide open
ZEDQA gbub RESULT 28 pass, 0 fail
ZEDQA gbub DONE
```

### 30. zedqa_safemode.lua (`ZEDQA safe`) - WARN, 14 s

- go 26154 at 23:55:43
- 1 ERR line(s)
- screenshots: zqa_safe_1.png, zqa_safe_2.png, zqa_safe_3.png

```text
[ZeD.QA] state #30 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA safe start
[ZeD.QA] run #30 ok=true
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
ZEDQA safe option On picked up by the poll: picked up after 214 ms
ZEDQA safe ok option On picked up by the poll
ZEDQA safe option on: on true | pair false/false | vanilla inv true | hotbar vanilla | clock y 10 visible false | speed y 10 | moodle layer false
ZEDQA safe FAIL option on
ZEDQA safe option Off picked up by the poll: picked up after 459 ms
ZEDQA safe ok option Off picked up by the poll
ZEDQA safe option off: on false | pair false/true | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok option off
ZEDQA safe burst: 5 ticks, still off after 2504 ms
ZEDQA safe ok watchdog: a five-frame burst leaves ZeD on
ZEDQA safe streak: tripped after 2026 ms, 242 frames, longest gap 13 ms
ZEDQA safe ok watchdog: below two seconds of failures ZeD stays on
ZEDQA safe ok watchdog: two seconds of failures every frame trip it
ZEDQA safe ok watchdog note shows and closes
ZEDQA safe restored: on false | pair false/false | vanilla inv false | hotbar replaced | clock y -4000 visible false | speed y -4000 | moodle layer true
ZEDQA safe ok restored
ZEDQA safe DONE
```

### 31. zedqa_soak.lua (`ZEDQA soak`) - PASS, 147 s

- go 26155 at 23:56:00

```text
[ZeD.QA] state #31 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA soak start ui 36, 2 rounds
[ZeD.QA] run #31 ok=true
ZEDQA soak round 1 avg 17.63 ms worst 294 ms ui 39 (start 36) hours 0.3
ZEDQA soak round 2 avg 17.53 ms worst 45 ms ui 39 (start 36) hours 0.6
ZEDQA soak PASS nothing piles up: 39 UI elements at the end of round 2, 39 at the end of round 1
ZEDQA soak PASS no slowdown: round 2 averaged 17.53 ms a frame, round 1 17.63 ms
ZEDQA soak PASS after the run, the reader shut: 38 UI elements (39 at the end of round 1, 36 at the start)
ZEDQA soak 3 passed, 0 failed (2 rounds)
ZEDQA soak DONE
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
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
