# KISS test: the Cooking tab (QA, Nov 25 2026)

The director, Nov 23 2026: "With every one of these micro QA passes, also do a KISS test." This covers the Cooking sweep (ck.txt: ck_tab, run at 4K and 1280x800 on 7a2458c89, 35c95115a and 7dc79b244, green at both sizes on 7dc79b244 with ck_tab e156e7420). The map is 2026-11-25_map_cooking.md (K1-K24).

## Steps for the common jobs, the game against ZeD

| Job | The game | ZeD, Cooking tab |
| --- | --- | --- |
| Start a stew | Right-click the pot, Create Stew from, the ingredient (3) | The tab, the ingredient (2); Dish first if another shows (4) |
| Four ingredients | The menu 4 times, 3 each (12) | 4 presses and Make (5) |
| Two stews | 24 | 5, then + and Make (7) |
| The same dish next time | 12 again | Save once; later Dish, the saved row, Make (3) |
| Season a stew | After the first ingredient, the spice (3) | The spice row (1) (fixed in this pass: a started dish is a base) |
| A random one of a kind | Add random Vegetables (3) | None |
| Add to a dish already made (omelette, pizza, toast, bagel) | The menu on the dish (3) | Not in the tab; the game's menu still works |
| See what one adds | "(n)" on each option | "(n)" on each row and a Hunger line |
| See why one can't | The grayed option's tooltip | Mouse hover only; nothing on a pad |
| Pick the state (raw or cooked, frozen, stale) | One option per type and number | One row per state (fixed in this pass) |
| See the time left | The oven's timer; nothing per food | Per food on the oven, fire and item card: a percent for about 8 game minutes, then minutes |

ZeD has, the game doesn't: a plan you see before anything is used, saved dishes, several dishes in one press, the ingredient count against the dish's limit, Use <same kind> for a saved dish, minutes left per food.

## Bugs (to Build, with evidence; every one seen at both sizes)

The first run proved 9:
- **K1:** Make could put in the stale tomato when the game's menu offers the fresh one at a better number.
- **K3:** berries and mushrooms named "Berries" for a character who doesn't know them (the game says Unknown Berry); with Herbalist the poisonous and safe ones shared one row; the item card showed poison and hidden nutrition the game's tooltip doesn't.
- **K7:** five planned on a saucepan that takes four kept Make lit.
- **K8:** no salt or pepper for a stew or soup (the game offers them after the first ingredient).
- **K9:** Make pressed twice (mouse or pad A A) made two stews.
- **K11:** on the half card (220) the dish pane had a negative width: the plan, Remove and the Hunger line drew off the tab.
- **K12:** the minutes left on the oven, fire and card were the food's cooking units, not game minutes.
- **K17:** calories showed without Nutritionist.

Build fixed them in fix/cooking (7a2458c89), fix/cooking2 (35c95115a: K8, rows by the item's own name, K12) and fix/cookclock3 (7dc79b244: K12, a figure only once the rate is steady). QA's own test faults found on the way (K2's merged menu option, a frozen carrot the game never lists, the 300 oven leg reading the first steak's burn countdown) were fixed in ck_tab.

ck.txt on 7dc79b244 with ck_tab e156e7420: 188 pass, 0 fail at both sizes. One known SKIP: a gas range after the gas shutoff (the QA world has no gas shutoff setting).

**K12 timing, game minutes (1280x800 on 7dc79b244):**

| Where | ZeD's first figure | Came after hot | Really took | 8 minutes later ZeD said | Really took |
| --- | --- | --- | --- | --- | --- |
| Campfire | 29 | 10.2 | 27.6 | 21 | 19.6 |
| Range at 100 | 32 | 8.5 | 29.2 | 22 | 21.2 |
| Range at 300 | 18 | 8.2 | 16.4 | 10 | 8.4 |

## Proved, matching the game (no change)

- **K5:** B during Make stops the queue and leaves a crate's tomato in the bags. The game's own add does the same on its B.
- **K13:** a steak just off the heat reads BURNING on its card while it is still hot, as the game's inventory pane does.
- **K1 poison and favorite:** a poisoned carrot and a favorite tomato go in like a clean one; the game's menu offers one option for the two and tells neither apart.

## Design calls for the director

Asked as numbered choices in chat. Option 1 is QA's pick in each. **Decided Nov 25 2026:** the director picked option 1 on all eight ("1 on all"), and QA relayed them to Build. Calls 1 to 6 are build work; 7 and 8 keep what ships.

1. **The Hunger line.** It adds only the ingredients' numbers and leaves out the base's own food. A sandwich of one cooked steak read 5; the made sandwich takes 15 off hunger. The card calls the same number "Hunger reduction". Options: the dish's whole total with the card's words, or keep.
2. **Why a row is grey, on a pad.** The reason ("Must be cooked", "The dish is full") shows on mouse hover only. Options: the reason in the help line when the pad is on a grey row, or keep.
3. **Where an ingredient is.** Make takes from crates, the floor and corpses in reach; the rows don't say where (the base list does). Options: an aside on rows not on him ("crate", "floor"), or keep.
4. **Add to a dish already made** (omelette, pizza, toast, bagel, a second round of soup). The tab makes dishes from scratch only; the game's menu does the rest. Options: list them in the tab with the dish as the base, or keep.
5. **A pot not on him.** The tab shows only while a base is on him, so a pot on the stove or in a crate can't be planned. Options: show the tab while a base is in reach, or keep.
6. **The opening dish.** A pot of water opens on Soup, the first by name. Options: open on the last dish made, or keep.
7. **Cooking minutes, the first 8 game minutes.** Build's last change shows a percent until the rate is steady, then minutes. Before it, the first figure was already within about 10 percent on the campfire and the range at 100. Options: keep the percent first, or minutes from the first reading.
8. **Random of a kind.** The game's "Add random Vegetables" has no match. Options: keep (rows by type say what goes in), or an "Any vegetable" row per kind.

## Not staged

- A gas range after the gas shutoff (no sandbox setting in the QA world).
- MP: another player taking an ingredient mid-Make, a fire put out by another player, the 10 s wait under lag.
- Languages other than EN (key coverage only).
- Cooking levels other than the QA character's.
