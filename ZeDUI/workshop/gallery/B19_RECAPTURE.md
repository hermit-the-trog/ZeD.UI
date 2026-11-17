# Gallery recapture for beta 19 (Nov 17 2026)

Build's list for QA. The director, Nov 17 2026: "Update ZeD-GUI gallery with any updated visuals." The last set on the
page is `upload_b13` (taken for v0.3.0-beta13a), so nothing from betas 14 to 19 is in it. This is **not** a full pass:
retake the spreads below and take the new captures; every other spread keeps its beta 13 picture. Then Build
re-renders the changed spreads and rebuilds the upload set as `upload_b19`.

**How to take them.** As B13_RECAPTURE.md: 4K (3840 x 2160), UI scale 1.75x, the **Dark** theme and the **PZ Teal**
accent, the list view, the game's **Font Size at 19px** (`fontSize=2`), unless a row says otherwise. Same framing,
window places, blur and belt in view as the beta 13 pictures, so each drops into its spread's crop. Files go in
`~/Zomboid/Screenshots/gallery_t14` under the **same names**; move the old ones to `gallery_t14/_before_b19` first.
New captures take the names given below. Split view stays off. Real fast-forward only through ZEDQA_SPEED.
Item-colored tiles stay **off** except where a row turns them on (the setting's default is off).

**What changed since the beta 13 pictures:**
- **Icons (beta 18):** 26 menu icons redrawn (Place, Pick up, Put in, Take, Drop, Move to, Favorite, Wanted and
  Unwanted, recipes, Rename, Chop, Slice, Dice, Peel, Install, Uninstall, Take apart, Destroy, Dig, Light), one accent
  each (blue, red or gold); the Character wheel's Weapons, Drink, Medicine and Sleep.
- **Pop-outs (beta 16):** radios, TVs, two-ways, ovens, microwaves, washers, dryers, generators and grills pop out
  beside the character as the real thing, each face with a pop-out button top right; the seat picker shows the car's
  cabin from above (Simple keeps the seat window); the espresso machine (Additional appliance support).
- **Radios (beta 14):** the full card shows the full-size faces; a TV's tab says Television with a TV icon.
- **Inventory (beta 15):** an open stack lists every item under a header; counts read "Rag (3)".
- **Item card (beta 14):** its buttons are Grab, the main action, then More.
- **Look (beta 16):** tooltips light in every theme; bubbles in Fira Mono (speech) and Fira Sans (notes); a game speed
  or pause shows in a bubble over the character; an action with no end shows its icon, not a bar.
- **Controller (betas 14 to 19):** the Belt slice on the Character wheel (beta 17); every question opens on Cancel;
  the window menu has Controller map and Hide interface (beta 19), and Bug report (beta 17).
- **Setup (betas 14, 16, 19):** Windows > UI sounds; Additional appliance support; Look > Item-colored tiles.

## Changed content: retake, and check what each must show

| Spread | Capture names | What each must show |
|---|---|---|
| 07 grid view | zed_53_grid.png, plus (new) zed_53b_grid_tinted.png | zed_53_grid as before (tiles off). The new one: the same grid with **Item-colored tiles on**, Dark, items of clearly different colors (a red axe, a blue CD, tan bats, a gray wrench). Build adds it beside the first. |
| 09 inventory compare | zed_01_hero_mid.png (van_01 as before) | One **open stack** in the list: its header row and each item on its own row; counts reading "Rag (3)" style. |
| 11 item cards | zed_18_card_food.png, zed_19_card_weapon.png | The card's foot buttons **Grab** (take it from a container, not your own inventory), the main action, **More**. |
| 12 laundry | g14_ldy_washer.png, g14_ldy_dryer.png, g14_ldy_combo.png | The machines as **pop-outs** beside the character, with the pop-out button top right; windows clear of them. |
| 22 ovens | zqa_ap_1_tab_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_4_popout_microwave.png | Pop-outs open **clear of the windows**, the pop-out button top right; the stove's controls on. |
| 26 radios | g14_radio_black.png, g14_radio_cd.png, g14_radio_handbuilt.png, g14_radio_red.png, plus (new) g19_radio_popout.png, g19_tv_tab.png | The half-card faces as before; the CD player in the half card. New: a **placed radio popped out** beside the character (the full-size face); a **TV in the World window**: its tab and title say **Television** with the TV icon. |
| 27 two-way radios | zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_5_ham_civilian_tab.png | The pop-out button top right of each face; otherwise as before. |
| 32 context menus | zed_20_ctx_strip.png, zed_21_ctx_list.png (van_20 as before) | The **round 1b icons**: an item's menu showing Favorite, Drop, Move to, Place, Rename and Wanted / Unwanted; on food, Slice or Peel if it has them. The list menu on a car part or furniture for Install / Uninstall / Take apart if it frames. |
| 33 action bar | zed_32_action_bar_reading.png (van_32 as before), plus (new) zed_32b_action_endless.png | Reading's bar as before. New: an action with **no end** (fishing, or resting) showing its **icon**, not a cycling bar. |
| 34 belt | zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_06_rightwatch_pistol.png | Straight retake (light tooltips if one shows). |
| 35 bubbles | zqa_bub_both_dark.png, plus (new) zqa_b19_speed_bubble.png | Speech in **Fira Mono**, a note in **Fira Sans**. New: fast-forward on, the **speed bubble** over the character. |
| 38 watches | gbw_ClassicGold.png, gbw_DigitalBlack.png, gbw_DigitalRed.png, gbw_DigitalTimez.png | Straight retake. |
| 39 messages | zqa_g4_belt_toast.png, zqa_g4_guide_bubble.png, zqa_g4_window_radio.png | Straight retake (the Messages window has its window box). |
| 40 questions | zqa_pr_01_sleep.png, zqa_pr_06_keyboard.png, zqa_pr_07_alarm.png, plus (new) zqa_b19_ask_cancel.png | As before. New: on the **controller**, the trash can's Remove all question opened **on Cancel** (the pointing hand on Cancel). |
| 42 car radio | g5_car_radio.png | Its pop-out button; the volume knob. |
| 45 full or simple | gb_forms_setup.png, gb_plain_dash.png, gb_plain_radio.png, gb_simple_belt.png, gb_simple_watch.png, plus (new) gb_seat_cabin.png, gb_simple_seat.png | New pair: choosing a seat in a car, **Full** (the cabin from above) and **Simple** (the seat window). Build adds the pair if the spread has room, else spread 18's page. |
| 47 controller map | zqa_padmap_options.png, plus (new) zqa_b19_window_menu.png | New: a ZeD window's **menu** opened on the controller, showing **Bug report, Controller map, Hide interface**. |
| 48 controller | zqa_g3_wheel_character_eat.png, zqa_g3_wheel_now_light.png, zqa_g3_wheel_use_smoke.png, zqa_g3_footer_pad.png | The Character wheel with the **new Weapons, Drink, Medicine, Sleep** pictures and the **Belt** slice; the other wheels' icons as drawn now. |
| 53 desk | desk_05_trash_computer.png | Straight retake (light tooltips; any icon changes). |
| 54 options menu | mm4_01_options_zed.png, mm4_02_options_interface.png, mm4_03_options_hidden.png | ZeD setup's **Look** group with **Item-colored tiles** and the **Windows** group with **UI sounds**; Additional appliance support where it frames. |

## New captures for a page of their own (Build places them)

| Capture name | What it must show |
|---|---|
| g19_espresso_popout.png | **Additional appliance support** on, the espresso machine popped out beside the character, in a kitchen with power. Build places it in spread 21 (cooking) or 22 (ovens). |
| g19_generator_popout.png | A generator popped out beside the character, running, its Info card closed. Build places it with 22 or 23. |

## Every other spread

Keep the beta 13 picture. If one of them shows a **tooltip** (now light in every theme) or a **menu icon** from the
redrawn set where it reads clearly, tell Build its name and retake it the same way.

## Cinema breaks

No change unless a break shows a tooltip or a menu; then retake it as above.

When the pass is done, tell Build the folder and any capture that could not be taken; Build re-renders the changed
spreads, rebuilds `upload_b19` and its contact sheet. Uploading the gallery stays the director's go (SteamCMD cannot
add gallery pictures; they go up by hand on the item's Add/edit images page).
