# QA 175e: the tab catalog rerun (Nov 12 2026)

Rerun of the design review's tab catalog on today's main, to see which findings are already gone. No mod code was changed.

## What was run

- **Setup, same as the Nov 11 run:** 1920 x 1080 window, UI scale 1x, Dark theme, PZ Teal accent, Small text (the ZeD text size option), game font size 2, mouse and keyboard, ZeD-QA save, no Steam (the DebugLog says "SteamUtils started without Steam").
- **Part 1:** the original manifest (tab_review.txt), all three passes. 50 of 50 pictures, in `%USERPROFILE%\Zomboid\Screenshots\tab_review_20261112`. Every picture was opened at full size: no half-drawn window, no wrong tab. (The Character window is narrower in the empty pass and in Radio; that is by design, not a half-drawn window.)
- **Part 2:** a short pass of 8 views (Inventory, Equipped list, Health with injuries, Crafting, Radio, Furniture, Papers, an Apple item card), in four setups, 32 pictures:
  - `%USERPROFILE%\Zomboid\Screenshots\tab_review_20261112\light` (8): Light theme
  - `%USERPROFILE%\Zomboid\Screenshots\tab_review_20261112\hicon` (8): High Contrast theme
  - `%USERPROFILE%\Zomboid\Screenshots\tab_review_20261112\large` (8): Large text, Dark
  - `%USERPROFILE%\Zomboid\Screenshots\tab_review_20261112\pad` (8): Dark with the controller on (pad mode locked, focus on a list row or the first control of the tab, the pad hint strip shows)
- The pad pass was run twice. The first try put focus on the wrong zone in some tabs (the container strip), so it was redone with focus in the tab body and the first try was thrown away. In Equipped and Health the focus lands on the section header, in Inventory and the item card on the Apple row, in Crafting on the Station dropdown, in Furniture next to the "8 items" label, in Radio on the PWR button.
- Papers and Books are one view in the tab (the Papers page), so Papers stands for both.
- Picture names below are given as the file name inside the folders above (Part 1 files are in the folder root, Part 2 files in their subfolder).

## Verdicts

STILL THERE, GONE or CAN'T TELL, one line each.

### Section 1: rough edges that came with the fixes

| # | Verdict | Picture and note |
|---|---|---|
| A1 | STILL THERE | tabs_char_loot_full.png: "M9 Pistol  Belt 2" is bare gray text beside the name. Also in every Part 2 inventory picture, and at Large text it still shows. |
| A2 | STILL THERE | Inventory rows say "Unread" (tabs_char_loot_full.png), Papers says "Not read yet" (tabs_char_journal_papers_full.png), Notebooks says "Nothing to read on you" (tabs_char_journal_notebooks_empty.png). "Books on you" was not on any picture. Two wordings still differ. |
| A3 | CAN'T TELL | tabs_world_radio_full.png shows the radio set in one-decimal form (98.4, 93.2, headed "Presets"). The walkie-talkie (tabs_char_radio_full.png) shows a "098.000" display and no channel list at all, so the two formats and the wrapped channel name cannot be compared. The two block headings differ only if the walkie has channels. |
| A4 | STILL THERE | tabs_char_identity_empty.png and _full: icon, then a colored square, then the name, on every trait row. |
| A5 | STILL THERE | tabs_world_furniture_full.png: the "Target" button is a teal ring on the teal selected row. The pointer label ("Outdoor Bench  Cannot pick up") still sits on the version text at the lower right, in every theme (light and hicon furniture pictures too). |
| A6 | STILL THERE | tabs_char_journal_loadouts_empty.png and _full: "Add what you carry, or RMB an item: Save to loadout." |
| A7 | STILL THERE | tabs_char_loot_empty.png and every World picture: the title bar reads "6 | 0/4500  0 / 8" (three bare numbers) when the window is narrow. |

### Section 2: design system check

| # | Verdict | Picture and note |
|---|---|---|
| D1 | STILL THERE | tabs_char_loot_full.png: "Tool / ...", "Cooking ...", "Gardeni...", "Communi..." while Cond is empty for most rows. The weapon card still shows Kind "GardeningWeap..." (tabs_char_loot_card_weapon_full.png). At Large text the Cond column drops out and Category still truncates. |
| D2 | STILL THERE | Disabled buttons still wear the ring: "Restock 0:00" (tabs_char_equip_list_empty.png), "Make" (tabs_char_cooking_full.png), "Craft" (tabs_world_craft_list_empty.png), "Build" (tabs_world_build_list_empty.png). In High Contrast the disabled label is nearly invisible (hicon\tabs_hicon_equipped.png). |
| D3 | GONE | Recipe card tags are a square and a word ("Known", "Surface", "50s" in tabs_world_craft_recipe_full.png and tabs_world_build_recipe_full.png; "Known" on the weapon card). Skills "+125% XP" has a square, no box (tabs_char_skills_full.png). Foraging "Fair / Walking / Summer / Clear" has a square and plain words (tabs_world_forage_empty.png). The "25s" and "Keep" tags were not on any picture. |
| D4 | STILL THERE | Apple (tabs_char_loot_card_food_full.png): Hunger +16 and Hunger reduction +16, Thirst +7 twice. Machete (_card_weapon_full): Damage twice, Condition 100% and 13 / 13, Reach 1.2 and Range 0.6 - 1.2. Backpack (_card_container_full): Capacity twice, Items twice, "Weight reduce" and "Weight reduction". |
| D5 | STILL THERE | "0.0/8kg", "0.0/19kg", "5.8/28.0kg", "38.1/45.0kg" in the headers, "5.8 / 28 kg" and "2.0 kg" on the card (tabs_char_loot_card_container_full.png). |
| D6 | STILL THERE | Four heading styles on one picture set: large disclosure (Health, Equipped), mono band (Traits, Skin Temperature by region), mono over a rule (Hair and beard, Nutrition Facts), small mono disclosure (Moodles, Fitness, Presets). tabs_char_identity_empty.png, tabs_char_health_full.png. |
| D7 | STILL THERE | tabs_char_equip_list_full.png: "Head + face (2)", "Torso (3)" are half-height rows touching the rows around them; "The belt | keys ... Slot | what gives it" reads as two labels. |
| D8 | STILL THERE | tabs_world_forage_empty.png: lowercase "unemployed" among capitalized modifiers. |

### Section 3: consistency across tabs

| # | Verdict | Picture and note |
|---|---|---|
| C1 | STILL THERE | Journal opens with "Page: Journal" (tabs_char_journal_journal_full.png); Crafting, Building, Maps, Animals, Furniture open with controls only. |
| C2 | STILL THERE (part) | Cooking now says "Dish: Pasta", "In: ...", "Sort: Name" (tabs_char_cooking_full.png), so it follows "Label: Value". Crafting still has "Station Hand" (no colon) and "Category -- ALL --" (tabs_world_craft_list_full.png); Building still has a bare "-- ALL --" (tabs_world_build_list_full.png); Recipes in the Journal "Category -- ALL --". |
| C3 | STILL THERE (part) | Building now says "Nothing is ready to make with what is in reach." (tabs_world_build_list_full.png) and a search with no match says "Nothing matches ...". Still unchanged: "Nothing here.", "No animal zones yet.", "Nothing to read on you", "Point at furniture.", "Recent finds will appear here.". The heading "All Recipes (0)" is still shown above the new sentence. |
| C4 | STILL THERE | Animals (Ranch | Butcher) and Furniture (Pick up | Place | Rotate | Disassemble | Repair) tab strips; Radio and Vehicle pager "< Floor (1) >"; Journal "Page:" dropdown. The "Zones (0)" and "Zones (1)" headings still touch the strip (tabs_world_animals_empty.png, _full). |
| C5 | STILL THERE | Loadouts footer: Save loadout, Save outfit, New list, none marked default (tabs_char_journal_loadouts_empty.png). |
| C6 | STILL THERE | tabs_world_maps_empty.png: two rows of unlabeled icon buttons, the first six symbols repeat in the second row. |
| C7 | STILL THERE | tabs_char_loot_empty.png: header and footer "1 item", list "Nothing here.". |

### Section 4 and 5: the QA notes (Q1 to Q14)

| # | Verdict | Picture and note |
|---|---|---|
| Q1 | GONE | Container card top block: Kind Bag, Weight 2.0 kg, Capacity 5.8 / 28 kg, Items 13, Weight reduce 85% (tabs_char_loot_card_container_full.png). No "-1". Build's claim is confirmed. |
| Q2 | GONE | Advanced Forge card: the description is one clipped line, "Required (0/7)" starts below it, nothing overlaps (tabs_world_build_recipe_full.png). Not a listed Build claim; it is gone anyway. |
| Q3 | STILL THERE | tabs_world_animals_zone_full.png: "QA Pen 64 sq.  0 animals" and "Animals (0)"; the overview (tabs_world_animals_full.png) says zone 0 and "Totals (1): 1 Hen". Build's claim that Q3 was fixed is contradicted: the QA script spawns the hen inside the pen's bounds, and it is counted in Totals but not in the zone's own count. (The scene could be at fault if the hen is outside the zone's squares; the zone row still disagrees with Totals.) |
| Q4 | GONE | Building with nothing ready shows the heading "All Recipes (0)" and now the sentence "Nothing is ready to make with what is in reach." (tabs_world_build_list_full.png). With a search that matches nothing it says "Nothing matches" under "Results (0)". Build's claim is confirmed, though the "(0)" heading still sits beside a recipe card when one is opened (tabs_world_build_recipe_full.png). |
| Q5 | STILL THERE | tabs_world_craft_recipe_full.png: the card shows "Add Timer to Bomb", which is not one of the six rows listed (Make Duct Tape Holster, Make Magazine Limb Armor, Make Newspaper Hat, Remove Battery, Saw Off Shotgun, Tie Rope Belt). |
| Q6 | STILL THERE | tabs_char_equip_list_full.png and tabs_char_equip_doll_full.png: "Worst zone: Head (uncovered)" while a Baseball Cap is worn. |
| Q7 | STILL THERE | "Restock 0:00" in a narrow box with the ring (same as D2). |
| Q8 | STILL THERE | tabs_char_identity_empty.png and _full: "Hair (24)" and "Choose a row to see what it needs", no rows shown. |
| Q9 | GONE | tabs_char_identity_empty.png: "80 kg", no plus. |
| Q10 | STILL THERE | tabs_char_health_full.png: "Overall 100%" over "6 of 17 injured" with Severe Bleeding in the moodle list. (The Part 2 pictures read "5 of 17 injured" with the same 100%.) |
| Q11 | CAN'T TELL | Thermal bare (tabs_char_thermal_empty.png) and dressed (tabs_char_thermal_full.png): every one of the 17 regions reads 91.4 F in both. Insulation does differ (33% bare, 100% dressed) and Body Heat, Wind Resistance change, so the tab reads live data. The pictures cannot say whether the equal skin temperature is the scene (steady 71.5 F air) or a fault. Not a layout fault either way; Build's "it is the scene" is plausible but not proven by the pictures. |
| Q12 | STILL THERE | The game's "Close Trunk | Right Click More" prompt shows at the bottom center in every full picture, between and under the windows; when the windows are wider it is cut by the world window ("Mo|re", tabs_char_equip_doll_full.png). |
| Q13 | STILL THERE | The version text at the lower right is in every picture. When the world window is wide it is overlapped and cut ("ullet(1.0.0.28)", tabs_char_equip_list_full.png). |
| Q14 | STILL THERE | tabs_char_skills_full.png: Training Materials runs A, B, B, C, C, C, E, then restarts at A (Agriculture, First Aid) down the left column and at G (Glassmaking, Animal Care, Long Blade, ...) in the right; "Blacksmith..." is cut with room to spare. |

## Part 2: what the other setups show

- **Light theme (light\).** Everything is readable. Problems: the window bodies are see-through in the empty areas, and the street, car and zombies show through (most of Inventory and Crafting below the last row, light\tabs_light_crafting.png). Dimmed rows are low contrast: the unread flier row in Papers (light\tabs_light_papers.png) is pale gray on pale gray and hard to read; "Wrench" and a few dimmed rows in the trunk list are faded. The pointer label at lower right still sits on the version text. The "Restock 0:00" and "Craft" disabled labels are very faint (they read as disabled, which is right, but the label is almost gone).
- **High Contrast (hicon\).** Readable and bright. Disabled "Restock" and "Craft" labels nearly vanish (hicon\tabs_hicon_equipped.png, tabs_hicon_crafting.png). The empty parts of the Papers panel show zombies clearly through the window (hicon\tabs_hicon_papers.png): in a theme meant for legibility the body should be solid.
- **Large text (large\).** Nothing is clipped off the screen, and the windows grow to fit. At Large the Cond / Amt column drops out of the list and Name truncates early: the Unread tag shrinks to a bare square with no word ("Book: "Piano ... [square]", large\tabs_large_inventory.png). Category text truncates the same ("Tool / ...", "Gardeni..."). Equipped and Health scroll; the grade panel is below the fold, as before. Title bar shows the three bare numbers again.
- **Controller focus (pad\).** Pad mode is on (glyph hint strip at the bottom: Sort, Grid, Card, Mark, Menu, Windows). In Inventory and the item card the focused Apple row is filled with the accent and a hand marks it, which reads well. In Equipped and Health the focus is on the section header (a faint fill and the hand at the tab icon). In Crafting and Furniture the focus shows only the hand next to a control (the Station dropdown, the "8 items" label); no control is filled (pad\tabs_pad_furniture.png). In Radio the hand sits on the PWR button of the picture. The focus cue is much weaker outside the lists.

## New problems (not in the review)

1. **Window bodies are see-through in the empty areas, in every theme.** Zombies, cars and fences show through blank panel space (Light and High Contrast the worst: light\tabs_light_crafting.png, hicon\tabs_hicon_papers.png). The review's "windows are opaque" holds for the rows, not for the blank part under them.
2. **A moodle hover note is left at the right edge of the Health pictures** ("Alarmed, Nervous and jumpy" or "Severe Bleeding" with its icon), over the world window area, in all four setups (tabs_char_health_full.png, hicon\tabs_hicon_health.png, large\tabs_large_health.png, pad\tabs_pad_health.png). It may be the moodle hover text staying open after the mouse is parked; Nov 11's "tooltip left behind" fix may not cover this path.
3. **Large text turns the Unread tag into a bare square** (see Large text above). Name before tag, so the tag loses its word.
4. **Low-contrast dimmed rows** (the unread flier in Papers) in Light theme.
5. **The pad focus cue is faint or missing on Crafting and Furniture** (see Controller focus above).
6. **The world window's QA pen overlay (blue square) and zone** stay on the ground in the Radio and Vehicle pictures (tabs_world_radio_full.png, tabs_world_vehicle_full.png). This is the QA scene (the "QA Pen" zone), not ZeD, so it is noted only so nobody files it.

## Not covered

Server and Admin tabs (server only), 4K, Deck / 720p sizes, and the "Books on you" block. The 14 retakes in `director_review_20261111` were used only for comparison and were not rerun separately: their tabs are inside the 50.
