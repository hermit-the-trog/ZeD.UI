# Cooking tab: map for the gamut sweep (QA, Nov 25 2026)

A read-only map of ZeD's Cooking tab against the game's own cooking (B42, the evolved recipe menu and ISAddItemInRecipe), written before the ck_ sweep scripts. It also maps where the food then cooks (the oven view, the fire card) and how a dish reads afterward (the item card's food facts). Line refs are as read on Nov 25. Nothing was run.

**The tab is on the Character window, not the World window.** CookingTab.lua registers it with ZeD_CharacterWindow.addTab, after Temperature (CK:1201-1211). ZeD_WorldWindow.lua has no cooking tab. Its focus zone is charTabContent (CK:553, 559).

Short names: CK CookingTab.lua, CW ZeD_CharacterWindow.lua, CC CraftingCore.lua, SA StationAppliance.lua, OCF ObjectCardFire.lua, OC ObjectCards.lua, IFP ItemFactsPanel.lua, IC ItemCard.lua, IAH ItemActionHooks.lua, OS Overrides/Stations.lua, OIC Overrides/InfoCards.lua, FM Input/FocusManager.lua, DW ZeD_DpadWheels.lua.
The game's files (media/lua unless noted): IPCM client/ISUI/ISInventoryPaneContextMenu.lua, AIR shared/TimedActions/ISAddItemInRecipe.lua, TAQ client/TimedActions/ISTimedActionQueue.lua, BTA shared/TimedActions/ISBaseTimedAction.lua, OVUI client/ISUI/Fireplace/ISOvenUI.lua, IP client/ISUI/ISInventoryPane.lua, ER media/scripts/generated/evolvedrecipes.txt.
FEATURE_MAP rows 236-237 cite old lines (about 21 lines off: visible is CK:1175, addTab CK:1201, onClick CK:1098, firstDish CK:1156, make CK:429).

## 1. What the tab does

**Getting there:**
- The Character window's tab strip, tab id "cooking", named with the game's IGUI_perks_Cooking (CK:1204), drawer 480 (SKILLS_DRAWER_W, CW:156, 964).
- It shows only while a dish's base is on the player (main inventory or a bag in it) and something in reach goes into it (CK.visible CK:1175-1196, cached 1 s). When it goes while open, the window falls back to Loot with the drawer shut (CW:3636-3653).
- LB/RB and the tab strip's pad stops include it only while it shows (CW:1045). The D-pad Character wheel's Tabs slice lists it, "Not now" while hidden (DW:1012-1022).
- ZeD_CharacterWindow.openTab(pn, "cooking") (CW:4423).
- No item-menu route: the game's evolved recipe menu (IPCM:4206-4270) is not hooked and still works. The tab is the "second way" (CK:5-6).
- Safe mode: no branch in CK; the tab is ZeD's own.

**Data (CK):**
- The catalog, read once (CK:69-116): every evolved recipe from getEvolvedRecipes, grouped by its translated name, ContextMenu_EvolvedRecipe_<name> (Stir fry, Stir fry Griddle Pan and Stir fry Forged are one Stir-fry). Kept only "from scratch" recipes: base type not equal to result type (CK:95-96). Left out: Soup2, Burger2, Taco2, Burrito2, Pizza, Pizza2, Omelette, Omelette Forged, Bread, Toast, Oatmeal, the three Bagels, Hotdog, AddBaitToChum (ER).
- The scan, every 1 s (SCAN_MS CK:43, scan CK:183-218): containers are the game's ISInventoryPaneContextMenu.getContainers (CK:138-147): inventory, worn and held bags, floor, crates, corpses and car parts in reach; CC.buildContainers as fallback.
  - Bases: every item in them whose type starts a kept recipe, with its recipe, name, where (CK:150-162), water ok (CK:173-179: getMinimumWater, then hasMinimumWater) and mine (on the player, CK:164-170). Sorted: mine first, ready first, then by name (CK:208-214).
- Ingredients for the chosen base (CK:229-304): the game's getItemsCanBeUse(chr, base, containers) for the base as it is now (empty), grouped by full type.
  - A group: the first item's name, icon, kind (its food type, "_spice" for seasoning, "Other"), kind label (ContextMenu_FoodType_<kind>, else IGUI_ItemCat_Food, CK:257-258), spice (a food's isSpice, else the script's, CK:248-250) and use (the game's getRealEvolvedItemUse at the player's Cooking level, CK:261).
  - The game's refusals: frozen in a recipe that takes no frozen (ContextMenu_CantAddFrozenFood), not cooked where it must be (ContextMenu_NeedCooked) (CK:267-274). Any one refused item sets the group's why.
  - A second pass adds every item of the type in every container in the same rotten, frozen, burnt and cooked state as the group's first item (CK:278-301). Poison, freshness short of rotten, favorite and where it is are not compared.
- How many dishes (CK:322-340): bases of the same type and recipe with water ok, anywhere in reach, capped by each ingredient's count over its need.

**The one view (CK.render CK:1029-1082):**
- Header (CK:585-634): the title row "Cooking" (drawTabHeader), then two pop-up boxes on the strip.
  - "Dish: <name>": saved dishes first (only those a base in reach makes, aside "saved"), then every dish a base in reach starts (CK:608-617).
  - "In: <base>": every base for the dish, aside where it is or "needs water" (disabled) (CK:626-632).
  - Opening on: the dish kept while a base for it is in reach; else CK.firstDish, the first by name with a base on the player that takes something (CK:1040-1042, 1156-1171).
- Left, the ingredient list (CK:639-748), a fixed 240 units (CC.PANE_W_SPLIT, CC:43; CK:1048):
  - Sort "Name" (one group, A to Z) or "Category" (one folding group per food type, seasoning last) (CK:655-685, 889-892).
  - A row: icon, name, the game's "(use)" number for non-seasoning, "xN" left after the plan (CK:717-728).
  - Grey when the game refuses the type (why), none left, a seasoning already in, or the dish full (CK:701-705). Hover help: the game's reason, "The dish is full", or "Add this to the dish" (CK:729-733), mouse only.
  - Empty: "Nothing in reach goes into this dish." (CK:651-654).
- Right, the dish (CK:754-878):
  - A base that needs water: "<base>, needs water" line (CK:773-777).
  - "Ingredients n / max" (max = getMaxItems; seasoning not counted), the rows with a green or red dot; then "Seasoning" and its rows (CK:840-851).
  - A row the reach no longer covers: red dot and "Use <same kind>" (another type of the same kind and seasoning class with some left), else "Not in reach" (CK:802-827).
  - "Hunger" and the sum of the plan's use numbers (CK:853-862).
  - "Cook it afterwards on a stove or a fire." when the recipe is Cookable and the plan isn't empty (CK:865-872).
- Band (CK:894-971): Sort pop-up at the left; at the right Save dish or Forget dish (with a plan), "- n +" (only when more than one can be made and Make is lit), Make.
  - Make is lit when how many is at least 1, no plan row is missing, and the plan isn't empty (CK:900). It doesn't check the plan against the current base's limit.

**Verbs:**
- Add: a press on a lit row appends one of that type (CK:735-738).
- Remove: a press on a dish row takes it out and the count back to 1 (CK:830-834).
- Use <kind>: swaps the missing type for the offered one (CK:817-820).
- Save dish: plan, dish key and base type into mod data ZeD_CookDishes, at most 20, oldest dropped silently (CK:45-46, 514-522). Forget dish removes the match (CK:523-526). A saved dish loads with the saved base type if ready, else the first base (CK:536-543).
- Make (CK:429-494):
  1. bases: the chosen one, then others of the same type and recipe with water, from anywhere in reach, up to the count (CK:436-440);
  2. per dish, per plan entry in the order pressed: pick an item of the type, the main inventory first, then the group's order (bags, floor, crates) (CK:442-452);
  3. anything not in the main inventory (base or item) moved in (CK:453-460);
  4. setChef on every food item (CK:477);
  5. one ZeD_CookAdd per item (single player), chained so each add takes the dish the last one left (CK:347-369); on a server the game's ISAddItemInRecipe, with a ZeD_CookWait between adds that waits up to 10 s for the server's new dish (CK:400-427, 478-484);
  6. ISCraftingUI.ReturnItemsToOriginalContainer for what was moved (CK:490-492);
  7. the scan forced, the count back to 1.
- Each add is the game's: 100 minus 2.5 per Cooking level ticks (AIR:239-244), the dish named by checkName, its heat averaged (AIR:83-88).
- Wheel: scrolls the column under the pointer (CK:1085-1094). A press with a list open answers only the list and its box; elsewhere it shuts it (CK:1098-1111). Lists also shut on a press outside, an action, a walk, Esc (ZeD.Popups, CK:1001-1004).

**Settings:** none of its own. Saved dishes in mod data; dish, base, plan, sort, folds and scrolls on the window for the session (CK:121-136). Also: UI scale, text size, theme, the player's Cooking level (the use numbers, the add time).

**Lite:** no branch in CK. Lite touches only the oven view's on/off row (SA:833-891).

**Pad (CK:1124-1150, focus zone charTabContent):**
- Header: cook:dish, cook:base (A opens the list). With a list open the stops are its rows cook:pop:<id> (saved:<i>, dish:<key>, base:<i>, name, kind) and its box only; B shuts it (CK:1130-1135).
- List: cook:cat:<kind> (A folds, Category sort only), cook:ing:<full type> (A adds).
- Dish: cook:plan:<i> (A removes), cook:alt:<i> (A swaps).
- Band: cook:sort, cook:save or cook:forget, cook:dec, cook:inc, cook:make.
- Grey rows and a grey Make are still stops; A on them does nothing and says nothing.
- X: nothing (no onContextMenu). Y: the window pair. B with no list open: no onCancel, so FocusManager cancels the running action (FM:1696-1703). The comment at CK:1123 ("else it leaves the tab") is not what happens.
- No search, no Max, no amount on a row. The focused row is scrolled into view (CK:1070-1079); stops rebuild on CK.scrollKey (CK:1144-1150).

**Small screens:** the list is a fixed 240 units; the dish pane takes what is left (CK:1048-1050). The tab gets the half card, 220, whenever the drawer is held in (CW:446-469): at 1280 wide that is any UI scale with the inventory open. Names cut with "..." (CK:727, 828).

**Where the food then cooks (not reached from the tab):**
- Oven and microwave: the game's Stove settings (ISOvenUITimedAction) opens the pop-out face or the Craft tab bound to the oven (OS:153-172); ISOvenUI only in safe mode.
  - State (SA:95-108): powered = the container's isPowered, active = Activated, on = both. Line under the plate: "No power" first, then On or Off with heat and timer (SA:433-447).
  - On/off is the game's setOvenParamsAndToggle (SA:211-222); heat and timer set on the object and synced, as OVUI:83-93 does.
  - "In the oven" (SA:452-490): per cookable food, Burnt, Burning (cooked and hot), Cooked, Cooking or Raw, with a bar and minutes from getMinutesToCook, getMinutesToBurn and getCookingTime. Hot = Activated, not frozen and heat above 1.6.
- Campfire, charcoal barbecue, fireplace, propane barbecue: the fire card, opened from the game's Info (OIC:66-77).
  - Fuel as time left to the sandbox maximum; Add fuel, Light with, Put out, Take apart; the propane face with tank gauge = fuel / 1200 min (OCF:39, 182-211, 227-306, 441-450).
  - "On the fire" rows: OC.cookRows (OC:621-678), the same reading as the oven with on = lit.
- The item card (any food): the facts panel IFP.NutritionFacts (IFP:184-279): Hunger and Thirst reduction, Calories, Protein, Fat, Carbs (rounded), Sickness risk (getPoisonPower), Boredom, Happiness, Cooked (Burnt, Cooked, Raw, or -), Fresh (Rotten, Fresh, Stale), Frozen or Freezing %.
  - The progress band while it cooks: IAH:319-367 polls the carded item every tick: cookable, not frozen, heat above 1.6 reads COOKING then BURNING with minutes.
  - The older FDA label and the dish's ingredient list (IC:325-376) are drawn by no live card: only the legacy height sums use them (IC:1302, 1625-1636). A made dish's ingredients show nowhere on the card.

## 2. Against the game (steps)

| Job | Game | ZeD Cooking tab |
| --- | --- | --- |
| Start a stew | Right-click the pot (1), Create Stew from (1), the ingredient (1) | The tab (1), Dish if not the one shown (2), the ingredient (1) |
| Four ingredients | 4 times the menu, 3 each (12) | 4 presses and Make (5) |
| Two stews | 24 | 5, then + (1) and Make |
| The same dish next time | 12 again | Save (1) once; later Dish (1), the saved row (1), Make (1) |
| A random one of a kind | "Add random Vegetables" (3) | None |
| Season a stew | After the first ingredient, the spice (3) | Not offered: the list is asked of the empty pot (K8) |
| Add to a half-made dish, an omelette, a pizza, toast, a bagel | The menu on the dish (3) | Not possible (CK:95-96) |
| See what one adds | "(n)" on each option | "n" on the row and a Hunger total |
| See why one can't | The grayed option's tooltip | Mouse hover only; nothing on a pad |
| Pick the exact item | One option per type and use, so a rotten one is its own option (IPCM:4245-4252) | By type only; Make picks (K1) |
| Cook it | Into the oven or onto the fire, then the oven's window or the fire's menu | A note only; no path from the tab |

ZeD has, the game doesn't: a plan you can see before anything is used, saved dishes, several dishes in one press, the dish's ingredient count against its limit, Use <same kind> for a saved dish.

The game has, ZeD doesn't: adding to a dish already made, the random-of-a-kind option, seasoning a soup or stew, a choice between a rotten and a fresh item of one type, the reason on a pad.

## 3. States to sweep

- **Bases:**
  - a pot full of water, half full (needs water), with tainted water, with a non-water fluid; a forged pot, a bucket;
  - a saucepan and a pot of pasta water (Pasta 4 and 5), the same for rice;
  - a bowl and a clay bowl (Salad and Fruit Salad), bread slices, a baguette, a bun, a taco shell, a tortilla, a pie crust (Savory and Sweet Pie), a cake prep, a muffin tray, a mug, teacup and metal cup with water;
  - each on the player, in a worn bag, on the floor, in a crate, on a lit stove; two of the same base, one in a crate.
- **Ingredients, each alone and beside a plain one of the same type:**
  - fresh, stale, rotten (at Cooking 0, 7 and 8 for the rotten use);
  - frozen, thawing, half frozen; a frozen one in a recipe that allows frozen;
  - raw and cooked of one type in a Sandwich (AddIngredientIfCooked); burnt;
  - poisoned (a foraged poisonous berry and mushroom, with and without Herbalist; a food poisoned in MP);
  - favorited, held in a hand, part eaten;
  - one in the main inventory, a bag, the floor, a crate, a corpse, a car trunk.
- **Seasonings:** salt, pepper and others for Pie, Sandwich, HotDrink and Muffin (CanAddSpicesEmpty) and for Stew, Soup, Stir-fry (not).
- **Limits:** Stir-fry at 4, Salad at 6, Muffin at 1, HotDrink at 3; a saved 5-item pasta loaded on a saucepan; a plan then the base switched.
- **Make:**
  - one dish; two and three at once; more presses than the count allows;
  - Make pressed twice, pad A A on Make;
  - B mid-Make; a walk mid-Make; the window shut mid-Make; the tab left mid-Make;
  - an ingredient taken by another player or dropped mid-Make; a crate item that must come back;
  - MP with lag (the 10 s wait).
- **Saved dishes:** 21 saved; a saved one with an ingredient gone (Use offered, none offered); a saved base type missing.
- **Stale:** an ingredient dropped, eaten, rotting, freezing or thawing while the tab is open; a crate brought beside a still player.
- **Cooking after:** the stew in an oven at 100 and 300 degrees, a microwave, a campfire, a charcoal and a propane barbecue; each with power or fuel, then without; the stew taken out hot.
- **Appliances:** an electric range on generator power, the grid off, the generator off mid-cook; a gas range after the gas shutoff; a propane barbecue with a full, a half and no tank; a campfire lit, smouldering, out.
- **Food facts:** a made stew and a sandwich, against the game's tooltip: hunger, calories, protein, fat, carbs, poison, fresh, cooked, frozen; with and without Nutritionist.
- **Skills:** Cooking 0, 3, 5, 7 and 8 (use numbers, add time, rotten use); Herbalist on and off; Nutritionist on and off.
- **Pad:** every stop; B with and without a list; A on a grey row and a grey Make; the scroll-follow in both columns.
- **Layout:** 1280x720 and 1280x800 at UI scale 1 and 2 with Large text, inventory drawer open and shut (the half card); 4K; a long dish and ingredient name.
- **Languages:** EN, DE, ES, FR, RU, JP: the dish names (the game's), the kind groups, Seasoning, "needs water", the cook note.
- **Themes:** Dark, Light, High contrast.

## 4. What the tests check already

| Script | What it checks |
| --- | --- |
| zedqa_cook80 (93-118) | The tab comes with a pot of water and goes with the pot; the window leaves it |
| zedqa_cook80 (120-177) | A stew of three made whole, nothing left out; two pots, the count shows, stops at 2, two stews of two |
| zedqa_cook80 (179-233) | Stir-fry stops at 4, a fifth greys and adds nothing; no seasoning for a new stir-fry; frozen broccoli not offered; a frozen carrot beside a good one: the good one goes in |
| zedqa_cook80 (235-277) | Save, Forget; a saved dish heads the list and loads; Use <same kind> offered and taken; Make waits while missing; none offered with nothing of the kind |
| zedqa_cook80 (279-301) | Pad A adds, A on a dish row removes, A opens Sort, only the list's stops with it open |
| zedqa_cook_popup | Pictures of the open Dish and Sort lists |
| bx_cook (1539-1712) | The tab against the game's offer for each base (H.ingDiff 699-722); presses past what is carried; in and out two frames apart; a frozen carrot not counted (1571); an ingredient gone, Make waits; Make stopped after 8 frames, then made; the tab left mid-make; a salad pressed past its limit; Save and Forget; the bowl gone, the next dish starts empty |
| bx_cook (846-990) | Oven: knobs clamp, ON three times, the item card's Cooked and Fresh rows for raw, cooked and burnt (H.factsOK); power cut and back; pop-out controls; the stove destroyed while bound |
| bx_cook (994-1097) | Microwave: 99:99 is an hour, the glass reads the time, pause, clear, run out; the leash; both windows shut |
| bx_cook (1099-1165) | Fridge and freezer listed and shown; freezing on fast-forward; the fridge destroyed |
| bx_cook (1450-1537) | Campfire card: no fuel, Light rule, Add fuel stopped, lit behind its back, fuel matches the fire's, Put out offered; the campfire removed with its card open |
| mp_cook, mp_cook_vanilla, mp_verify (59-110) | Make on a server: each add logged; the game's own add on the server for comparison |
| rt_inventory (1537-1553) | The tab joins the strip with a pot and two vegetables, goes when they go |
| vx10_food | B10-3: the Frozen and Freezing row, Stale |
| bxr_inv (1214-1254), vx_inventory (1026-1069) | The cooking band has no Cancel and its cancel path leaves the queue alone (staged, no stove) |
| sb_edges (683-686) | The tab's scrollbars |
| popups_close_sim (193) | The Dish list shuts by the Popups rules |

**Gaps:**
- Which item Make actually used: rotten beside fresh, poisoned beside clean, favorite, from a crate or the floor (bx_cook carries a rotten carrot beside a good one and never asks which went in).
- Raw beside cooked in a Sandwich (one refusal blocking the type).
- Poison anywhere: the tab, the card, against the game's rule.
- The Hunger total against the made dish; the card's numbers against the game's tooltip.
- Make pressed twice; B mid-Make; what comes back to the crate after a stop.
- A plan over the limit after a base switch or a saved dish.
- Seasoning a stew or a soup.
- The half card (220) layout.
- Cook timer minutes against the game clock; a hot dish off the heat; a gas range with no gas; the propane gauge.
- The pad end to end; grey rows on a pad.
- Languages other than EN; Light and High contrast; Lite.
- Test drift: bx_cook's "steak cooks" and "burns" lines are Q.check(true, ...) logs, not checks (bx_cook:915, 927, 1520); FEATURE_MAP rows 236-237 cite old lines.

## 5. Suspicions (to prove in the game)

Ordered by what they can cost: food and health first, then time.

- **K1:** Make picks the item, by type only. A row is one full type (CK:241-266); every item the game lists of that type joins it whatever its state (CK:274), and the second pass adds more matching only rotten, frozen, burnt and cooked (CK:280-298). Poison, stale and favorite are never compared. Make takes the main inventory first, then the group's order (CK:442-452). So:
  - a rotten tomato and a fresh one are one row, and either may go in; the game lists them as two options with different numbers (IPCM:4245-4252, getRealEvolvedItemUse 4085-4099);
  - the row's "(use)" is the first item's (CK:261), so it may read a fresh number for a rotten pick or the reverse;
  - a poisoned and a clean berry of one type are one row (K3);
  - a favorite is not skipped.
- **K2:** One refused item greys the whole type. Any item of the type the game refuses sets the group's why (CK:268-274), and a row with why can't be pressed (CK:703). A raw steak in reach beside a cooked one should grey Steak for a Sandwich (AddIngredientIfCooked, ER:182). zedqa_cook80:226 found a frozen carrot beside a good one does not block it, likely because the game leaves frozen ones out of its list; prove the cooked case and a half-frozen one.
- **K3:** Poison is not shown in the tab, and over-shown on the card.
  - The tab names items with getDisplayName (CK:201, 262). The game's inventory names a wild berry or mushroom by what the character knows: Unknown berry, or Poisonous berries with Herbalist (IP:2107-2124; ZeD_Trade.lua:360-374 copies it). In the tab a poisonous and a safe "Berries" look alike, and K1 picks either.
  - The item card shows getPoisonPower to every character as "Sickness risk +N%" (IFP:194, 222-223) and the recipe preview as "Poison N" (IC:232, ObjectCardPreview.lua:240). Prove whether the game's tooltip shows poison without the knowledge to detect it; if not, ZeD leaks it (keep vanilla stakes).
- **K4:** Make reaches into every container in reach. Ingredients and extra bases come from crates, the floor, corpses and car trunks (CK:138-147, 436-460). The ingredient rows never say where (only the base list does, CK:629). A count of 2 with one pot on the player uses a pot from a crate (CK:328-330, 436-440).
- **K5:** B cancels Make. With no list open the tab's stops have no onCancel (CK:1133-1135), so B stops the running action (FM:1696-1703). A stop resets the whole queue (BTA:63-64): the rest of the dishes go, and so do the moves back (CK:490-492), so items brought from a crate stay in the bags. The same for a walk, a hit, the window shut, or ZeD_CookWait's 10 s limit in MP (CK:422-426). bx_cook stopped Make after 8 frames but did not check what came back.
- **K6:** A failed start clears the queue. TAQ:82-95 resets the queue when an action's isValidStart fails. The game's start check asks that the base is in the inventory and that getItemsCanBeUse still lists the item (AIR:9-18). It can fail on:
  - a plan over the base's limit (K7);
  - an item ZeD's second pass added that the game's own list did not (CK:285-298);
  - the second press of K9;
  - an item gone since the press.

  The rest of Make and the moves back are dropped, with no message.
- **K7:** A plan can exceed its base. Switching the base keeps the plan (CK:1010); loading a saved dish too (CK:536-543); Make's check doesn't compare n with getMaxItems (CK:900). Pasta and Rice merge saucepans (4) and pots (5) (ER), so a saved 5-item pasta loaded on a saucepan queues a fifth add the game refuses (K6).
- **K8:** Seasoning is never offered to a Soup, Stew, Stir-fry, Roast or Salad. The list is asked of the empty base (CK:235), and the game offers seasoning to an empty base only with CanAddSpicesEmpty (Pie, Sandwich, HotDrink, Muffin in ER). The game lets you season a stew after its first ingredient. zedqa_cook80:216 confirmed none for a new stir-fry.
- **K9:** Make stays lit while its own adds run. Counts come from the containers once a second (CK:183-218) and the items stay until each add completes. A second press (mouse or pad A A) queues adds on the same base and items again (taken is per press, CK:441). Likely the second chain's first start fails and clears the queue (K6), possibly ahead of the first press's moves back.
- **K10:** The tab vanishes and hides.
  - It shows only with a base on the player that takes something (CK:1175-1196). A pot on the stove or in a crate can't be planned for.
  - When the last base or ingredient goes, the window falls back to Loot (CW:3636-3653), mid-plan or mid-Make.
  - When the dish's last base turns into a stew, the dish resets and the plan is wiped (CK:1040-1042): fine after Make, a surprise if the player made it by hand.
  - CK.visible counts a base whose only usable item is itself (CK:1189; firstDish excludes it, CK:1164): bread slices alone may show a tab with nothing to add.
- **K11:** Small screens. With the half card (220 units) the fixed 240 list leaves the dish pane a negative width (CK:1048-1050, CW:446-469, CC:43). The plan, Remove, Use <kind>, the Hunger total and the cook note don't draw while Make still works. At 1280 wide this is the normal case with the inventory open.
- **K12:** Cook and burn minutes may not be minutes. The oven rows, fire rows and item card band all show getMinutesToCook or getMinutesToBurn minus getCookingTime as minutes left (SA:463-487, OC:634-652, IAH:335-350). Cooking time accrues at a rate set by the heat, so "5 min" to burn may be much less on a hot oven. Prove against the game clock at 100 and 300 degrees and on a campfire.
- **K13:** A dish reads cooking off the heat. The item card's poll calls any cookable food with heat above 1.6 cooking (IAH:320-323, 332), wherever it is. A stew just taken out reads COOKING or BURNING with a countdown until it cools. The oven and fire rows also ask on (SA:466, OC:638). Also: when getMinutesToBurn is not above getMinutesToCook, the burn span is 1 and "0 min" shows (IAH:341-343).
- **K14:** Appliances shown on or fueled when not.
  - The oven reads powered from the container's isPowered (SA:98). Prove a gas range after the gas shutoff reads "No power", not On.
  - The propane gauge is fuel over 1200 minutes, "a full tank: 20 hours" (OCF:39, 441); the game shows the time only (ISBBQMenu:49). Prove a new tank reads full, and a tank past 20 hours.
  - The campfire's lit and fuel come from the Lua global object after updateFromIsoObject (OCF:231-235): prove in MP that a fire put out by another player reads out.
- **K15:** Water is measured, not judged. A base is ready on the amount alone (CK:173-179); tainted water, or a mug of milk or coffee, may read ready. The base list says where, not what is in it (CK:629). Prove what the game does with tainted water in a stew and whether cooking clears it.
- **K16:** The Hunger total is not the dish's. It sums the menu's numbers for the plan's types, from each type's first item (CK:853-862). It leaves out the base's own food (bread, pie crust), seasoning, rotten picks (K1) and any Cooking-level bonus. Its label "Hunger" with a plus number reads opposite to the card's "Hunger reduction" (IFP:208). Prove against the made dish's getHungerChange.
- **K17:** The card shows what the game may hide. Calories, protein, fat and carbs show for every food (IFP:213-219). Prove whether the game's tooltip shows them only with Nutritionist or for packaged food. "Sickness risk" prints poison power as a percent (IFP:222), which it isn't. The older FDA label and the ingredient list are dead code (IC:325-376); a made dish's ingredients show nowhere.
- **K18:** The default dish. firstDish takes the first by name with a base on the player (CK:1156-1171): a pot of water opens on Soup, not Stew. Switching the dish wipes the plan (CK:1016).
- **K19:** Stale lists. The scan and the visible check run once a second (CK:43, 185, 1180); a dropped, eaten, rotting or thawing item stays up to 1 s, and Make's pick uses the last scan's items (CK:432-433, 442-452). Prove a press in that second.
- **K20:** The pad.
  - Grey rows and a grey Make are stops and A says nothing; the reason is mouse-hover only (CK:729-733, 1128-1137).
  - B: K5.
  - No X or Y verbs, no Max; - and + appear only when more than one can be made (CK:929).
- **K21:** Chef set at the press. setChef runs on every food item at the press (CK:477), carried ones too, and stays if Make is stopped; the game sets it only on items it moves (IPCM:2372-2389). Low cost; check the name in MP.
- **K22:** MP: findDish takes the newest result item not seen before the press (CK:381-398). A stew picked up or made by hand during the wait may be taken for the chain's dish, and the next add goes into it: the wrong dish.
- **K23:** Words.
  - All 18 UI_ZeD_Cook_ keys are in all 28 languages.
  - The cook note says "on a stove or a fire" for every Cookable dish (CK:865), including Sandwich and hot drinks, which need no cooking.
  - A non-food ingredient's kind reads "Food" (CK:257-258).
  - The recipe preview's food facts and the old status alerts are English only ("Hunger", "Poison", "Better hot", "Raw!": IC:144-160, 226-240), shown through ObjectCardPreview.lua:240.
- **K24:** Test drift: FEATURE_MAP rows 236-237 are about 21 lines off; bx_cook:915, 927 and 1520 always pass.
