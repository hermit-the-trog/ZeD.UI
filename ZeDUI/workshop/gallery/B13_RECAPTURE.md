# Gallery recapture for beta 13 (Nov 13 2026)

Build's list for QA. The director, Nov 13 2026: "Yes, retake it" overnight, for the beta 13 upload. The beta 12 set
(`upload_b12`, built Nov 12 09:30) went up unretaken and predates beta 12's look changes, so this is **one full pass
of every capture**, then Build re-renders all spreads and rebuilds the upload set as `upload_b13`.

**How to take them.** The same as B11_RECAPTURE.md: 4K (3840 x 2160), UI scale 1.75x, the **Dark** theme and the
**PZ Teal** accent, the list view, the game's **Font Size at 19px** (`fontSize=2`), unless a row below says otherwise.
Same framing, window places, blur and belt in view as before, so each picture drops into its spread's crop. Put the
files in `~/Zomboid/Screenshots/gallery_t14` under the **same names**; move the old ones to
`gallery_t14/_before_b13` first. Captures named with a `~/Zomboid/Screenshots/gallery_beta2/` path in the table are
retaken there, same names. Split view stays off. Real fast-forward only through ZEDQA_SPEED.

**What changed since the beta 12 pictures** (every capture shows some of it, so none is optional):
- **Tab titles and headings (beta 12):** each tab opens with its title; one small section heading style.
- **The rows under the title bar (178):** two shared sizes in every tab and both windows.
- **The Status column:** the inventory column's heading reads "Status" (was "Cond / Amt").
- **Tags:** a status square and a word, no box; "Unread" everywhere for books and papers.
- **Dropdowns:** "Label: Value" ("Sort: Craftable", "Category: All").
- **The item card's top block:** Kind and Weight only; the other facts once, below.
- **Sub-page tab strips:** Journal (a tab per page), Radio (a tab per radio), Vehicle (a tab per vehicle).
- **Light and High Contrast windows are solid;** see-through works in **Dark only**.
- **One view button** (List / Grid), the pixel magnifier in search boxes, the foot line "48 items" or "3 of 48
  picked | 4.2 kg".
- **The status pixel** before your name in the Character window.
- **Dashboards (beta 12 and 13):** three cabin colors for civilian dashes, picked by the car's paint; printed words in
  the ink that reads best on the cabin (near-white on grey, wood and brown); the D-pad hint on a dark strip.
- **Radios (beta 13):** the round 4 faces (the black radio without its dial, both radios with an aerial, the makeshift
  at 257 with its big speaker and Spiffo cells, the antique TV in chrome); the old orange chassis card is gone.
- **Main menu (beta 12):** the new ZeD-GUI poster; the desk's boombox has no antenna.

## Changed content: retake, and check what each must show

| Spread | Capture names | What each must show |
|---|---|---|
| 04 see-through | zqa_cw_12b_solid_in_use.png, zqa_cw_08_seethrough_100.png, zqa_cw_12_seethrough_60.png | **Dark only** for all three (see-through does nothing in Light or HC now). 100 and 60 visibly different. |
| 14 equip doll | zed_10_equip_doll.png | The Equipment tab with its title, the Status column, trait/protection rows at the new sizes. |
| 19 health compare | zed_11_health_exercise.png (van_11 as before) | Health's title; Overall never 100% with a wound; the damage word on its own line; no percent cut at the drawer's edge. |
| 25 fishing | zqa_fi_1_slack.png, zqa_fi_3_tight.png, zqa_fi_5_limit.png | The **World window's Fishing tab** (rod in hand at water): rod, line and bait, cast and reel, the catch log. Slack, tight, at the limit. |
| 26 radios | g14_radio_handbuilt.png, g14_radio_cd.png, g14_radio_red.png, g14_radio_black.png | The **round 4 faces** in the **half card** (in hand): the black radio with no dial and its aerial, the red with its round speakers and aerial, the makeshift at its widest (big speaker, Spiffo cells), the CD player. The **Radio tab strip** (one tab per radio) above. Not a placed radio (the full-card faces are not drawn yet). |
| 27 two-way radios | zqa_tw_5_ham_civilian_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_1b_valutech_tab.png | The Radio tab strip with two sets; the full view as before. |
| 30 vehicle tab | gallery_beta2/zqa_m79_3840x2160_2_hover_row.png, gallery_beta2/zqa_m79_3840x2160_6_card_brake_step.png | The **Vehicle tab strip** with two vehicles in reach (one tab each); the hovered part row lighting its part on the diagram. |
| 43 dashboards | zqa_r6p_taxi_extras.png | Keep the taxi, and if the spread takes a second picture, a **civilian cabin color** (grey Primani or a tan cabin) showing the new ink and the D-pad hint strip. |
| 44 reading and writing | zqa_nb_01_page1.png, zqa_rd_01_paper.png | The **Journal tab strip** (a tab per page) with an entry carrying a **tag** (Loot or Danger); a book list row showing **Unread**. |
| 45 full or simple | gb_forms_setup.png, gb_simple_watch.png, gb_simple_belt.png, gb_plain_radio.png, gb_plain_dash.png | gb_plain_radio: the **plain card** (Devices: Simple), rows (Power, Volume, Headphones, Battery...), never the old orange chassis. |
| 47 controller map | (new) zqa_padmap_options.png, replacing the repo picture controller_pad_px.png | **Options > Controls > Button map and test**, Xbox set, the drawn pad with its labels and leaders, the live test lighting one button and a trigger at a percent. Build points the spread at the new name. |
| 50 themes | theme_dark_orange.png, theme_dark_green.png, theme_light_blue.png, theme_light_red.png, theme_hicon_teal.png, theme_hicon_purple.png, zqa_cw_02_dark_small_window_menu_theme.png | Light and HC **solid** (no scene through the windows); Dark at the default see-through. |
| 53 desk | desk_05_trash_computer.png | The new poster on the wall and the boombox with **no antenna**. |
| 57 mod manager | mm4_03_mods_conflict.png, mm4_04_mods_conflicts_tab.png, mm4_06_mods_problem_missing.png, mm4_07_mods_problem_version.png | Plus, if the spread has room for one more: **the Files tab** with one file of a mod turned off. Take it as mm4_10_mods_files_tab.png; Build adds it if it fits. |
| 20 farm | gfr_yard.png, gfr_crop_grown.png, gfr_zone.png, gfr_hutch_open.png | At **the director's farm** (zedqa_farm_spot.lua), the zone page with the new scroll (the trough list ending above the band). |

## Every other capture: a straight retake under the same name

All remaining names in the spreads (01-03, 05-13, 15-18, 21-24, 28, 29, 31-42, 46, 48, 49, 51, 52, 54-56, 58-63):
retake as they were framed, so the new rows, headings, Status column, tags and dash/radio art show. The Light-theme
story shots (08b, 08d, 36) and any HC shots are now **solid**: that is expected. Spread 62's three captures live in
`gallery_t14/_before_nov1/`: retake them into `gallery_t14/` under the same names (Build repoints the spread).

## Cinema breaks (`cinema/*.jpg`)

Reshoot the breaks that were in **Light or High Contrast**, so their windows draw solid: `cin_ang_open` (Light +
Blue), `cin_mck_kitchen` (HC + Red), `cin_lau_lake` (Light + Teal), `cin_ang_close` (Light + Blue). Check the other
cinema sources too: any Light or HC one joins this group. The Dark breaks: retake only if their windows show (the new
rows and Status column).

When the pass is done, tell Build the folder and any capture that could not be taken; Build re-renders every spread,
rebuilds `upload_b13` and its contact sheet. Uploading the gallery stays the director's go.
