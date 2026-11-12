# Design review of the tab catalog (Nov 12 2026)

From design, for the director to rule on, then Build and QA. The director, Nov 12: "do design system check, consistency
across tabs. Compare the before and after and make sure those changes were progressive instead of regressive. Empty
space and density review ... open issue from QA's notes."

## What was read

- **Catalog:** `Screenshots/tab_review_20261111`, 50 pictures, 4:50 PM Nov 11, every one opened (39 at full size, 11
  near-empty ones at 71%).
- **Retakes:** `Screenshots/director_review_20261111`, 14 pictures, 8:11 PM (furniture_full 9:56 PM), all opened.
- All 1920 x 1080, UI scale 1x, Dark + PZ Teal, Small text, mouse and keyboard.
- **Limits.** 36 of the 50 tabs have no picture after the fixes, so a finding marked *catalog only* may already be
  fixed. Nothing built after 9:56 PM Nov 11 is in any picture (animals quick actions, tab search, the Lua console).
  Light theme, High contrast, Large text, 4K and the controller highlight were not shot, so none of this speaks to them.

## 1. Before and after: progressive

Nothing went backwards. Every fix QA marked PASS holds in the pictures, and the changes that came with them are gains:

| Change | Where seen | Verdict |
|---|---|---|
| Windows are opaque (no zombies or cars through the lists) | all 14 | better |
| Title bar names the character and the tab ("Angel Cross + Health"), with the health pixel | all 14 | better |
| One view button plus a filter button, in place of the list / grid pair | all 14 | better |
| Search fields carry a magnifier, not a "/" | Equipped, Journal pages | better |
| Equipped gets its own search field; the Restock hint wraps to two lines | equip_list_full | better |
| Thermal: Body Heat Generation and a detail block for the picked region fill the lower half | thermal_empty, _full | better |
| Health with no injuries shows Fitness and Regularity, not a blank panel | health_empty | better |
| Notebook page preview runs the height of the tab | notebooks_full | better |
| "No notebook on you" now lists Writing, Papers on you, Books on you | notebooks_none_full | better |
| Loadouts: picking a list shows its lines, with Rename / Add what I carry / Delete | loadouts_full | better |
| Radio: Channels or Presets, Heard, Power blocks under the device | char_radio_full, world_radio_full | better |
| Furniture card back, no floating tag over the window | furniture_full | better |
| Identity traits carry their icons | identity_empty | better |
| Footer says "48 items" (weight is in the header only) | all 14 | neutral |

Five rough edges came in with the changes. None is a step back, each is a small follow-up:

- **A1. "Belt 2" lost its marker.** Tags are now a square and a word (injuries, "Unread"), but "Belt 2" is bare gray
  text beside the item name and reads as part of the name. Give it the square. (loot_full, every inventory list)
- **A2. Three wordings for one state.** Inventory rows say "Unread", Papers on you says "Not read yet", Books on you
  says "Unread." with a period. Pick one. (notebooks_none_full)
- **A3. Two frequency formats.** The walkie-talkie lists "098.400 / 101.200", the radio set "98.0 / 101.2". The
  walkie's first channel name wraps to three lines. One block is headed "Channels", the other "Presets".
  (char_radio_full, world_radio_full)
- **A4. Trait rows carry two markers.** Icon, then a colored square, then the name. The square says positive or
  negative, which the group heading already says. (identity_empty)
- **A5. Furniture card.** The "Target" button is a teal ring on the teal selected row and is hard to read. The pointer
  label at the lower right sits on the version text. (furniture_full)
- **A6. "RMB" in player text.** "Add what you carry, or RMB an item: Save to loadout." Jargon, and wrong on a
  controller. (loadouts_full)
- **A7. Narrow title bar.** When the window is narrow the level reads "6 | 0/4500 0 / 19", three bare numbers with no
  word. (loot_full, world pictures)

## 2. Design system check

- **D1. Category column truncates with room to spare.** "Tool / ...", "Cooking ...", "Gardeni...", "Communi...",
  "Materia...", "Vehicle ..." in every inventory list, before and after, while the Cond column beside it is empty for
  most rows. Widen the column or let the text run under an empty Cond cell. The card shows the raw name
  "GardeningWeap..." for Kind.
- **D2. Disabled buttons wear the default ring.** "Restock 0:00", "Cut", "Make", "Craft", "Build" are grayed but keep
  the accent double ring, so they read as the focused default. Disabled should be the dim plain keycap.
- **D3. Boxed tags remain** *(catalog only)*: "Known", "25s", "Keep" on recipe cards, "+125% XP" in Skills,
  "Good / Sneaking / Summer / Clear" in Foraging. The retaken tabs moved to the square and word.
- **D4. Item cards repeat themselves** *(catalog only)*. Apple: Hunger +16 and Hunger reduction +16, Thirst +7 twice.
  Machete: Damage twice, Condition 100% and 13 / 13, Reach 1.2 and Range 0.6 - 1.2. Backpack: Capacity twice, Items
  twice, "Weight reduce" and "Weight reduction". The top block should be Kind and Weight only, or go.
- **D5. Weight is written five ways.** "0.0/8kg", "0.0/8.0kg", "5.8/28.0kg", "5.8 / 28 kg", "2.0 kg".
- **D6. Section headings come in four styles.** A disclosure with a large title (Health, Equipped, Loadouts), a mono
  line on a band (Traits, Skin Temperature by region), a mono line over a rule (Hair and beard, Nutrition Facts), and
  a small mono disclosure (Moodles, Fitness, Presets). Two would do: the tab's title and one section style.
- **D7. Group headers in Equipped are cramped.** "Head + face (2)", "Torso (3)" sit in a row about half the height of
  an item row and touch the rows around them. "The belt | keys ... Slot | what gives it" reads as two unrelated labels.
- **D8. Lowercase "unemployed"** among capitalized modifiers in Foraging *(catalog only)*.

## 3. Consistency across tabs

- **C1. Tab headers.** Most tabs open with a title ("Health", "Equipped", "Identity"). Journal opens with
  "Page: Journal" and a search; Cooking with two dropdowns and no title; Crafting, Building, Maps, Animals and
  Furniture with controls only. The title bar now names the tab, which helps, but the body header differs tab to tab.
- **C2. Dropdown labels, four formats.** "Sort: Craftable" and "Show: Ready" (label, colon), "Station Hand" (label, no
  colon), "Category -- ALL --" (dashes), "-- ALL --" in Building (no label). Use "Label: Value" everywhere.
- **C3. Empty states.** Lists say "Nothing here."; Animals "No animal zones yet."; Papers "Nothing to read on you";
  Furniture "Point at furniture."; Foraging "Recent finds will appear here." Crafting and Building show
  "All Recipes (0)" and no sentence at all. Each empty tab should say what it is waiting for.
- **C4. Sub-tabs.** Animals (Ranch | Butcher) and Furniture (Pick up | Place | ...) use a tab strip found nowhere
  else; Radio and Vehicle use the "< Secondary (1) >" pager; Journal uses a "Page:" dropdown. Three ways to pick a
  sub-page. In Animals the "Zones (1)" heading touches the strip.
- **C5. Footers.** The Character window's footer is a status line; action buttons sit above it at the right in most
  tabs (Start, Save, Write, Craft), which is consistent. Loadouts carries three (Save loadout, Save outfit, New
  list) with none marked default.
- **C6. Maps has two rows of unlabeled icon buttons**, and six of the first row's symbols repeat in the second
  *(catalog only)*. The help band, or a label on focus, has to carry them.
- **C7. Empty inventory counts one item.** Bare character: header "1 item", list "Nothing here." (the worn glasses
  are counted but not shown).

## 4. Empty space and density

At 1056 px tall, how much of the tab's body is blank (by eye):

| Tab | Blank | What could go there |
|---|---|---|
| Item cards (food, weapon, container) | about 55% | once D4 is fixed, the room goes to "Used to make" and "Where it fits" |
| Character Radio | about 30% after the fix (was 60%) | fine now |
| World Radio | about 50% | the Heard log grows into it; fine once something is heard |
| Notebooks, none carried | about 60% | fine: it is an empty state and now says why |
| Papers | about 90% with one flier | a preview of the picked paper, as Notebooks has |
| Loadouts, list picked | about 65% | fine: grows with the list |
| Cooking, nothing to cook | about 85% | name what is missing ("needs water: none in reach") rather than a blank column |
| Crafting, Building lists | about 75% when few recipes are ready | the recipe card could take the free width at once, not on a pick |
| Vehicle, not inspected | about 60% | fine: Inspect fills it |
| Animals | about 85% with one zone | fine at this herd size |
| Furniture, nothing targeted | about 95% | list furniture in reach, so the tab works without pointing first |
| Health, injured | a blank band between the figure and the first injury | close it up; put the exercise text with the exercise picker, not beside the health bar |
| Thermal | about 20% after the fix (was 55%) | fine now |

The other way round, three tabs run out of room: **Equipped** (grade panel and "Best zone" cut off in both views),
**Skills** (Training Materials cut off), **Identity** (Traits cut off). Each scrolls, so it works, but the grade panel
is the summary of the tab and is the part hidden.

## 5. Open issues from QA's notes

Still showing in the newest picture of each tab:

| # | Tab | Issue | Newest picture |
|---|---|---|---|
| Q1 | Item card, container | "Capacity -1" in the top block (the facts below say 5.8 / 28 kg) | catalog only |
| Q2 | Building, recipe card | the Advanced Forge description overlaps the first Required row | catalog only |
| Q3 | Animals | zone says 0 animals, Totals says 1 Hen | catalog only (animals work landed after) |
| Q4 | Building list | "All Recipes (0)" beside a recipe card | catalog only |
| Q5 | Crafting | the card shows "Add Cigarette to Pack", which is not in the six rows listed | catalog only |
| Q6 | Equipped | "Worst zone: Head (uncovered)" while wearing a Baseball Cap | still there after |
| Q7 | Equipped | "Restock 0:00" in a narrow box with the ring (see D2) | still there after |
| Q8 | Identity | "Hair (24)" and "Choose a row to see what it needs", but no rows show | still there after |
| Q9 | Identity | "80 kg +", the plus unexplained | catalog only |
| Q10 | Health | "Overall 100%" over "6 of 17 injured" with Severe Bleeding | still there after |
| Q11 | Thermal | 91.4 F in every region, dressed or bare | still there after (may be the QA scene) |
| Q12 | Loot | two windows 5 px apart show the game's trunk prompt in the gap | after |
| Q13 | all | the version button at the lower right, in the player's view | after |
| Q14 | Skills | Training Materials not in alphabetical order; "Blacksmith..." cut with room | catalog only |

Closed by the retakes: the half-hidden moodle note, the Restock hint, the tooltip left behind, see-through windows,
the blank "No notebook" page, the missing furniture card.

## Suggested order

1. Rulings: A2 (one word for unread), C2 (dropdown labels), D6 (section styles), C4 (sub-page picker), D4 (card top block).
2. Build, small: A1, A3, A5, A6, A7, D1, D2, D5, D7, D8, C3, C7.
3. Build, bugs: Q1, Q2, Q5, Q6, Q8, Q10.
4. QA: rerun the full catalog on today's main, so the 36 *catalog only* tabs get an after picture; add Light, High
   contrast, Large text and the controller highlight for a few tabs.
