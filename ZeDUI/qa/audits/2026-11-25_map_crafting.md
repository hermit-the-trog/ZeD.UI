# Crafting tab: map for the gamut sweep (QA, Nov 25 2026)

A read-only map of the World window's Crafting tab against the game's own crafting window (B42, ISHandcraftWindow and its widgets), written before the cr_ sweep scripts. Line refs are as read on Nov 25 (main at e63cecf30). Nothing was run.
Short names: CT CraftingTab.lua, CC CraftingCore.lua, WW ZeD_WorldWindow.lua, OS Overrides/Stations.lua, ST Stations.lua, RI RecipeIndex.lua, FM Input/FocusManager.lua.
The game's files (media/lua): EUI client/Entity/ISEntityUI.lua, HA shared/Entity/TimedActions/ISHandcraftAction.lua, HCC client/Entity/ISUI/CraftRecipe/ISWidgetHandCraftControl.lua, WI .../CraftRecipe/ISWidgetInput.lua, RFP .../CraftRecipe/ISWidgetRecipeFilterPanel.lua, IPCM client/ISUI/ISInventoryPaneContextMenu.lua.
FEATURE_MAP rows 243-248 and 362 cite old lines (CC about 250 to 600 lines off), and row 243 still says a second click shuts the card.
Out of scope here: the bound machine, oven and general station views (StationMachine, StationAppliance, StationGeneral); only the switch to them is mapped.

## 1. What the tab does

**Getting there:**
- The tab strip, tab id "craft", named with the game's IGUI_CraftingWindow_Title (WW:132). The drawer is 480 (WW:74, 1870).
- The game's crafting key (XpUpdate.lua:132-140), the sidebar button (ISEquippedItem:439-442), the pad's back-button wheel (ISBackButtonWheel:149), a recipe in a book or magazine (ISLiteratureUI:571): all call ISEntityUI.OpenHandcraftWindow, which OS:113-132 routes to openTab(pn, "craft") (WW:7003-7046). A plain open toggles: the same key again closes a window it opened, or only leaves the tab (WW:7019-7025).
- The item menu: "Show craft recipes used" rows open the recipe (IPCM:1230-1290); "craft with this item" puts the item's name in the search (IPCM:1297-1300, OS:28-73, Category set to All). A recipe asked for unbinds a bench that does not make it (OS:118-121).
- The Journal's Open in Craft (KISS #55) and the item card's recipe list (RI:229-243), both through the same hook.
- The world menu's station option or the pad's Interact prompt on a station: OS:82-96, ST.open (ST:508-520) binds it and opens the tab.
- The D-pad Right wheel: "Craft and build", then Crafting (always by hand) or the nearest station's own slice (ZeD_DpadWheels.lua:1162-1172).
- Stove settings opens the oven view or its pop-out face (OS:153-172), not the recipe list.
- Safe mode: the game's own window (OS:84, 115).
- Not routed (as in the game): the item menu's direct crafts (IPCM:3338-3383 to OnNewCraft 3401-3448), the open-and-eat and open-and-drink recipes, and the item card's Sharpen (ItemCard.lua:530-548). They run the game's craft with no window.

**Views (CT:542-563):** the recipe view (CC.render CC:3401-3647); a bound machine, oven, microwave or general station replaces it. In the recipe view the list fills 480 alone and splits 240 + 240 with the card open, eased over 0.28 s (CC:41-48, 3531-3543). The alternatives list takes the list's place (CC:3546-3550).

**Header (CC:1772-1834):** no title row (KISS #48). The Station select shows only with a station bound or in reach (CC:1764-1770); then Category, then the search field, a ZeD_SearchField child of the drawer (WW:4441-4458), hidden by a station view (WW:4767-4773). Short of room the selects keep their words and the search gives up width (CC:1789-1806). A bound station adds its band under the header (CC:3499-3504).

**Data (CT):**
- The catalog is built once at game start (CT:39-173): every CraftRecipe; category from getCategory, else the first skill's name, else Miscellaneous (CC:940-958).
  - Inputs (CC:775-862): automation-only ones dropped. The amount is the game's item count, but 1 for a uses-based drainable (thread, glue, tape). Tool and Keep tags; Fuel only at a heat station (CC:1347).
  - Outputs (CC:865-906): yield per craft; mapped outputs are named from what is in reach (CC:2757-2803).
  - The station a recipe needs, from its tags (ST:332-372).
- Rows are rebuilt once a second (CT:182, 221-321):
  - RI.visible hides an unlearned must-learn recipe when See Not Known Recipes is off, and one whose OnAddToMenu check fails (RI:136-157).
  - Skills: every required skill via characterHasRequiredSkills (CT:264-273). Learned: isRecipeKnown(recipe, true) (CT:277-282).
  - Status: locked, or "station" (Hand mode, the recipe needs a station: CT:292-293), else the game's own answer.
- The game's answer (CC:445-534): one HandcraftLogic holds the list's recipes; getCachedRecipeInfo gives craftable, missing or locked. It is asked every 1.2 s, set again only when a signature changes (item count and weight per container, known recipes, every skill, the square: CC:418-430) or every 6 s. At a bench it is set in full every time. A locked or unskilled row stays locked whatever the game says (CC:527).
- The quick count (CC:334-348, every 5 s, CT:585-587) answers only rows the game did not.
- At a bench the list is the bench's recipes only (CT:183-211).
- Containers (CC:163-172): the game's ISInventoryPaneContextMenu.getContainers, i.e. the inventory page and the hidden loot page's list (IPCM:2425-2443): the inventory, worn and held bags, key rings, the floor, crates, corpses, car parts in reach; a locked crate is left out. They are gathered again every 1.5 s (CC:51, 1318) and at every scan.

**List (CC:2265-2577):**
- Groups: Pinned, Most used (top 5 by ZeD's own counts, CC:743-766), All recipes ("Results" while searching). A list of one group draws no head (CC:2352).
- A row shows the icon, the name, a status square (can, miss, unknown, station: CC:2500-2505), the station tag, a pin star (18 units at the right) and the use count.
- Every row stamps a zone, off-screen too (the pad walks them).
- An empty list says why (CC:1035-1040, 2558-2560).

**Filter and sort (CC:1103-1265):**
- Search matches the name, the category, every type an input slot takes (CC:1087-1101) and the outputs. It ignores Show (CC:1156) but not Category.
- Show: Ready (the default), Known, All (CC:1008-1032). The open card's recipe and pinned recipes stay under any Show.
- Sort: Craftable (default), Known, Name, Freq; an old "recent" reads Freq (CC:1071-1075). Pins always come first.
- Picking a category or typing so the open recipe leaves the list shuts the card (CC:1602-1612).

**Card (CC:3041-3391):**
- Head: the icon (a click or A opens the recipe preview card, CC:4068-4078), the name, one line of the game's tooltip text.
- Chips: Unknown (only when not known, CC:3181), the time from getTime as seconds (CC:3190-3200), the bound station's short name.
- Hand mode, a station recipe: "Needs a ..." with the nearest one in reach and Use <station>, which binds it (CC:3211-3233, 3863-3867).
- Required n/m (folds):
  - Each row shows have/need from the whole-item count (CC:1330-1352), with the Tool, Keep or Fuel tag.
  - A row with alternatives opens the alternatives list; a chosen type is named on the row (CC:3306-3310).
  - When every row is green but the game says no, the short input reads red (CC.shortInputIdx CC:3015-3039), else a line: "Needs a table or counter nearby." or the bench line (CC:3084-3105).
- Creates (folds): hidden when its one output of one is named in the title (CC:910-924).

**Alternatives (CC:1417-1497, 2890-3005):** the strip has Back, the owned count and Owned only (CC:1845-1880). Groups: Owned (have counts) and Other. A click on an Owned row chooses that type for the slot; again clears it (CC:2604-2613). Other rows can't be chosen. The search field filters this list (WW:4447-4448). Category, Sort and Show are frozen.

**Band (CC:2064-2164):**
- Left: Sort and Show pop-ups, opening upward.
- Right: - n + and Max, shown only when the most is over 1 (KISS #32, CC:1989), then Craft.
- Craft is lit when the row is craftable, learned, the most is above 0 and the start check did not refuse (CC:1972).
- Narrow (1280x720, UI scale 2, Large text): one amount box "< n >" (CC:1995-2008), boxes squeezed down to first letters (CC:2120-2156).

**Verbs:**
- Craft (CC.runStart CC:2881-2884):
  - With chosen types: startPickedCraft (CC:2813-2877), one action per craft from a manual-select logic (CC:2693-2746). The batch stops where the picks run out. With no craft covered it refuses with the game's words (CC:2841-2847).
  - Otherwise startCraft (CT:396-488), in this order:
    1. the bench is checked;
    2. the game's start check (HandcraftLogic canPerformCurrentRecipe and getPossibleCraftCount, CT:344-358, 427-437);
    3. inputs off the floor or out of a crate are moved in (CC:181-208);
    4. the walk to the bench or table (CT:446);
    5. N ISHandcraftAction built field by field with no manual inputs (CT:453-474);
    6. kept items sent back (CT:475);
    7. +1 count, the amount back to 1.
- Pin: a right-click on a row, the star, or pad X (CC:3828-3833, 3930-3945, 4194-4201). At most 8; the oldest goes (CC:708-710). Saved in mod data ZeD_CraftPins.
- Escape shuts the open card, not the pause menu (CC:1556-1572, KISS #47). A second click on the open row leaves it open (CC:1542-1546).
- Wheel: over the card scrolls the card, else the list or the alternatives; over the narrow amount box it steps the amount; with the Category list open it scrolls the list (CC:3954-3990).

**Settings:** none of its own. Sort, Show, Category, search, folds and the open card live on the window for the session (CC:1505-1540); pins and counts are in mod data (ZeD_CraftPins, ZeD_CraftCounts). Also: UI scale, text size, theme, the sandbox's See Not Known Recipes (RI:105-108), Hidden facts (the Journal's How to learn only).

**Lite:** no branch in CT, CC or ST. Lite touches only the oven view (StationAppliance.lua:833-835).

**Pad (CC:4109-4471, focus zone worldTabContent):**
- Header: craft:stDrop, craft:catDrop, then craft:search. A on the search opens the pad keyboard; RT or B gives the pad back (CC:4441-4460).
- List: section heads craft:section:pinned / freq / all (A folds). Rows craft:row:<name>: A opens the card and the focus jumps to Craft (CC:4178-4190, WW:5410-5440); X pins. The star is no stop.
- Card: craft:icon (A opens the preview), craft:stUse, craft:card:req and craft:card:out (A folds), craft:slotAlt:<name> (A opens the alternatives).
- Alternatives: craft:altBack, craft:altOwned, craft:altPick:<full type> (A chooses or clears).
- Band: craft:actDec, craft:actInc, craft:actMax, craft:actBuild. Narrow: one craft:actQty (A steps up and wraps to 1, Left and Right step, CC:4354-4382). craft:sortMenu and craft:showMenu open modal rows craft:sortRow:<id> and craft:showRow:<id> (CC:4043-4063).
- Category list: rows craft:cat:<id>, visible rows only (CC:4002-4039); B shuts it.
- The station list: ST.dropdownFocusables.
- B:
  - with a station bound, every stop without its own cancel unbinds the station (ST:861-872);
  - otherwise B cancels the running action (FM:1696-1703).
- Y toggles the window pair.
- The focused row is scrolled into view (CC:3601-3646). The stops are rebuilt on a key of the scroll, the open lists, the band's shape and the station (WW:5446-5470).

**Small screens:** the card pane is a fixed 240 units, so names and descriptions are cut with "..." (CC:636-652, 3161, 3168). The header and band squeezes above. The Category list shows 14 rows, then scrolls (CC:74-75).

## 2. Against the game (steps)

| Job | Game | ZeD Crafting tab |
| --- | --- | --- |
| Open | Crafting key (1), sidebar (1) | Same key (1); the tab (1); pad wheel (2) |
| Find by name | Type in search, click row (1) | Click search (1), type, click row (1); pad: A, keyboard, rows |
| Recipes that use an item | Item menu (2); filters by input name only | Item menu (2); the name goes in a search that also matches outputs and categories, locked ones too |
| Craft one | Row (1), Craft (1); or the item menu's recipe (2), direct | Row (1), Craft (1); pad A A (2); the item menu's direct craft is the game's own |
| Craft many | Max (1) or type a number, Craft (1) | Max (1), Craft (1); the amount shows only when more than one is possible |
| Choose inputs | Auto off (1), pick each item (n) | Slot (1), type (1), Back (1), Craft (1); by type, never by item; only types already in reach |
| Favorite / pin | Star (1); Favourites category | Right-click or star (1), pad X; ZeD's own list of 8, not the game's favorites |
| Craft at a bench | World menu (2), the bench window | World menu (2), tab bound; Station select (2); Use <station> on a Needs card (1) |
| See progress | Bar on the window; Craft grayed while it runs | None on the card; Craft stays lit |
| Know a tool may wear | Input tooltip: may degrade, sharpness check, worn / not worn | Not shown |
| Sort by use | MostUsed, LastUsed (the game's own record) | Freq (ZeD's count per press) |

ZeD has, the game doesn't: Show Ready, station recipes listed in Hand mode with their station and a Use button, pins with a Most used group, the "why not" line under Required.

The game has, ZeD doesn't: item-level choice, the progress bar and the in-progress lock (HCC:242-262), favorites, the input flags in the tooltip (WI:400-440), filter by input or output only (RFP:126-129).

## 3. States to sweep

- **Hand mode:**
  - one recipe each that is craftable, missing one input, short of skill, not learned (See Not Known Recipes on and off), with a failing OnAddToMenu, and one that needs a station;
  - an any-surface recipe (Drill Plank) with no table, with a table 1 square away and 2 squares away.
- **Recipe at hand:** a recipe the character lacks the skill or the knowledge for, with the book or magazine that teaches it carried.
- **Inputs in each place:** the main inventory, a worn bag, a held bag, a key ring, the floor at the feet, a crate beside, a crate 2 tiles off, a corpse beside, a car trunk beside, a locked crate. Also a crate brought in while the character stands still.
- **Items the game may refuse:**
  - one each favorited, set No-craft (Unusable in Recipes), worn, held in a hand, attached to the belt, broken, rotten;
  - a drainable with too few uses (thread), an empty and a full fluid container.
  - Each alone as the only one of its type, then beside a plain one.
- **Tools:** a tool at condition 1 on a may-degrade recipe (a knife on Make Stake); two of the same tool, one favorited and one worn down.
- **Batches:**
  - Max with materials for 3, 5 and 12;
  - Craft pressed twice with materials for one;
  - pad A held on Craft;
  - a batch with an input taken mid-way;
  - a batch whose tool breaks mid-way;
  - a batch with inputs on the floor where the recipe can't be done from the floor;
  - the World window shut mid-batch, the tab switched mid-batch, the character walked mid-batch.
- **Chosen inputs:** a type chosen that covers 1 of 3, then Craft 3; a chosen type that is also favorited; a choice made, then the item dropped.
- **Benches:**
  - a kiln, forge and pottery wheel bound from 1, 3 and 6 tiles;
  - a batch at each;
  - B pressed mid-batch;
  - the window closed mid-batch;
  - a walk that curves around a wall;
  - another player holding the bench (MP);
  - a drying rack and an oven to prove the view switch.
- **Search and filters:** search with a category set; search, then the alternatives list, then Back; Show Ready with nothing ready; every Sort; the 9th pin; the game's own favorite set in safe mode, then seen in ZeD.
- **Entry points:** each listed in section 1, including the crafting key twice, a recipe from a magazine, "craft with this item" on a plank, the Journal's Open in Craft.
- **Pad:** every stop; the Category list past its 14th row; B on a row, on the card, in the alternatives, at a station; A A on a grayed Craft.
- **Layout:** 1280x720 and 1280x800 at UI scale 2 with Large text (the narrow band, the one amount box), 4K, the 240 card with a long name.
- **Languages:** EN, DE, ES, FR, RU, JP. Look at Max, the bench and surface lines and the station row tags.
- **Themes:** Dark, Light, High contrast.
- **Safe mode** on and off.

## 4. What the tests check already

| Script | What it checks |
| --- | --- |
| rt_windows (717-838) | Sort opens and picks; Show opens and picks; Category opens and filters; right-click pins and unpins, saved in mod data |
| rt_inventory (1350-1352) | openTab(craft) shows the tab |
| rt_cards (873) | Sharpen runs the game's ISHandcraftAction |
| rt_cards (895-951) | A row click opens the card; the icon opens the preview card; another row shuts it |
| rt_cards (1307-1313, 1381-1470) | Stove settings opens ZeD's stove; the oven is bound in the Craft tab with its controls |
| rt_system (1126, 1806) | The soak cycles the tab; the tab pairs |
| bx_craft (whole, 1302 lines) | Search found and nothing found. Clicks on a row (old toggle, 548-549). Pin, Sort. Each row against the game's answer (349-359). A missing input refuses and counts nothing (402-407). Batch: the most against the game within 3 s, + and - at their ends, N actions queued, the run through a tab switch and the windows shut (595-669). Cancel mid-craft uses nothing (673-698). Double press, with materials for two (700-716). An input taken the frame Craft is pressed (720-755). A part, the noise maker. Build and Furniture. Hand mode only |
| vx_crafting | W27 sort speed; W24 amounts on rows and alternatives; W23 a chosen type on an any-surface recipe; W25 floor counts and the moves in and back |
| vx10_craft, vx11_craft | B10-2 yields and Creates; B10-4 the open row keeps its place (old shut-on-second-click, 1182); B11-1 mapped outputs; B11-2 learned flicker; B11-4 scroll |
| bxr_craft | Pictures only, nothing crafted: 1/4 planks, alternatives 1/4, any-surface Ready, a chosen type on the card, floor and crate counts |
| vk3_craft | KISS #17, 32, 35, 47, 48, 55: Show defaults, Max, no Surface badge, the second click and Escape, the Station box, Open in Craft |
| zedqa_picks_check (48-64) | Pad craft:actQty: A, Right, Left |
| zedqa_uncovered21 (145-156) | The focus stays on craft:actBuild after a craft (A pressed) |
| zedqa_b17_inv (216) | The craft:search stop |
| zedqa_stations | The kiln, the wheel and the rack: entry point, bench list, lock hand-over, key toggles |
| sb_edges (343-345) | The list, alternatives and card scrollbars |

**Gaps:**
- Any check at a bench (bx_craft is Hand mode only).
- Over-queueing: Craft twice with materials for one; A held.
- A batch losing an input or a tool mid-way.
- What the craft really consumed: favorite, worn, held, No-craft, condition of the tool used.
- Which container an input came from.
- Recipe at hand.
- A chosen type covering fewer crafts than the amount.
- The surface 2 squares away.
- Closing the window or pressing B mid-batch at a bench.
- The pad end to end (no pad walk of the tab in rt_pad); the Category list past 14 rows on a pad.
- Search in the alternatives list.
- Languages other than EN; Lite; Light and High contrast; small screens beyond the amount box.
- Every entry point except openTab, the stove and the station option.
- Test drift: bx_craft:548-549 and vx10_craft:1182 expect the second click to shut the card. Since KISS #47 it stays open (CC:1542-1546), so both now fail on the current code.

## 5. Suspicions (to prove in the game)

Ordered by what they can cost: items and time first.

- **C1:** Craft can be pressed again while its crafts are queued. The start check reads containers whose inputs aren't used until a craft ends, so a second press with materials for one queues a second craft. That craft has no manual inputs, so its start never asks canPerformCurrentRecipe (HA:96-120, CT:461): it runs its whole time and makes nothing. The game grays Craft while its craft runs (HCC:242-262). The pad makes it easy: the focus stays on Craft after a craft (zedqa_uncovered21:149-156). bx_craft's double press had materials for two (700-716). CT:396-488, CC:3914-3917, 4426-4435.
- **C2:** A batch that loses an input mid-way: a may-degrade tool breaking, thread running out, an item taken. Every later craft runs its full time and makes nothing, for the same reason as C1 (CT:453-474). The game's own batch has the same gap (HA:298-331), so prove both. ZeD shows no progress or count of what is left: the amount goes back to 1 at the press (CT:483).
- **C3:** Recipe at hand. ZeD's skill check (characterHasRequiredSkills, CT:270) and its override (CC:527) mark locked a recipe the game lets you make with its book or magazine carried (the game also counts couldBenefitFromRecipeAtHand, IPCM:1203). The row hides under Ready and Known (CC:1158-1160) and Craft is grayed, yet the grayed Craft still takes a press (C6) and the game's check may pass.
- **C4:** Have counts are not the game's. The card's have/need, the quick count and the alternatives count every item of the type in every container (CC:241-260, 343, 1334, 1417-1447). That includes:
  - worn, held and favorite items;
  - No-craft items (setNoRecipes, Atoms.lua:1990);
  - broken and rotten items, and ones failing an input flag (WI:400-440: not worn, empty, not dull, damaged).

  The card can read 3/3 in green while the game says missing; the "why not" line (CC:3084-3105) covers only an all-green card. The card never says a tool may degrade or needs sharpness, as the game's tooltip does (WI:405-416).
- **C5:** A choice is a type, not an item (CC:2604-2613). fillPickSlot offers items of that type in container order: inventory, then bags, then floor and crates (CC:2651-2665). The craft may take the favorite, the one in hand or the better one; the game's own window picks each item. Only types already in reach can be chosen (CC:2975).
- **C6:** A grayed Craft still takes a press. Its zone is stamped whenever a recipe is open (CC:2058), and the click (CC:3914-3917) and pad A (CC:4432) run it. Usually startCraft's own check refuses it, with no message (CT:429-436). But when the game gives no answer (canStart nil) the batch is queued unchecked (CT:429). At a bench past 3 tiles the fallback asks only getPossibleCraftCount (CT:351-352, CC:2723-2728), which may not weigh knowledge or skill.
- **C7:** Silent shortfalls:
  - a batch larger than the game's count is refused whole: nothing queued, no message, the amount dropped to the most (CT:429-436);
  - with chosen types the batch stops where they run out, silently (CC:2835-2840), and the amount offered came from the automatic count (CT:354, CC:1964-1969), not from the choice.

  "Craft 5" can make 0 or 3 with no word.
- **C8:** The bench's craft is valid only while the bench is held by the player (HA:6-9). ZeD lets go:
  - when the World window closes (ST:483-500);
  - when the player passes the leash, which tightens as he closes in (ST:442-447);
  - when B is pressed on any stop of the tab (ST:861-872, CC:4469).

  So a batch at a bench with the window closed, B pressed, or a walk path bending around a wall likely stops part way. bx_craft proved the window-closed case in Hand mode only.
- **C9:** Inputs moved, no craft. startCraft queues the moves of floor and crate inputs (CT:442) before the walk. If WalkToEntity fails (CT:446) the function returns: the moves stand, no craft is queued, and kept items are never sent back (CT:475 skipped). Same in CC:2851-2860. The game's window has the same order (HCC:340-358).
- **C10:** Inputs from a container the player didn't mean. The list is every container on the hidden loot page (IPCM:2425-2443): a crate, a corpse, a car's trunk, the floor. The card never says where an input comes from. The hidden page takes a new container only when the player turns or steps (bxr_craft:20-23), so a crate brought beside a still player isn't counted, and one walked away from may still be listed until the next gather (CC:51).
- **C11:** Hand mode finds a table within 2 squares (CC:229-233), as the item menu's craft does (IPCM:3405). The game's craft window looks within 1, "only adjacent squares will pass" (EUI:599-603). With a table 2 squares off the row reads Ready, and WalkToEntity's 3 tiles (EUI:17-31) won't walk: does the craft run, fail or waste its time?
- **C12:** The pad can't reach categories past the 14th. The list's stops are its visible rows only (CC:4002-4039, DD_MAX_VIS CC:75), and only the mouse wheel scrolls it (CC:3970-3976). B42 has more than 14 craft categories.
- **C13:** B on the pad:
  - with no station bound, B cancels the running action (FM:1696-1703), that is the craft;
  - it does not shut the card (Escape does, CC:1556-1572) or leave the alternatives (only craft:altBack does);
  - with a station bound, B unbinds it from anywhere (C8).
- **C14:** A on a row moves the focus onto Craft even when Craft is grayed (WW:5410-5440, C6). A A crafts; A A A queues twice (C1).
- **C15:** One search field serves the list and the alternatives (WW:4445-4455). enterAltMode and exitAltMode reset altSearch but never the field's text (CC:1614-1633), so the field can show words that aren't filtering anything, in either direction.
- **C16:** Typing a search or picking a category that leaves out the open recipe shuts its card, and the chosen types go with it (CC:1589-1596, 1602-1612).
- **C17:** Stale answers. The game's answer is set again only when its signature changes (CC:418-430, 500-505). An item's condition, freshness, heat or fluid level is not in it, so a row can be up to 6 s behind (CC:409); the card's counts up to 1.5 s (CC:51). Prove after cooking, after a tool breaks, and after filling a bottle.
- **C18:** The game's recipe favorites are ignored. The game keeps them in mod data (BaseCraftingLogic.getFavouriteModDataString, IPCM:1202-1206) and lists them first in item menus. ZeD's pins are its own (CC:673-715): at most 8, the oldest dropped silently (CC:708-710). The game's favorites don't show, and ZeD's pins don't reach the game's menus.
- **C19:** Use counts (Freq, Most used): one per press, not per craft (CT:478-480, CC:2865-2867). Crafts from the item menu and the item card aren't counted. The game's own MostUsed and LastUsed (RFP:144-146) aren't read.
- **C20:** "Craft with this item" is wider than the game's. The game filters by input name (EUI:613-618); ZeD's search also matches outputs and categories (OS:32-49, CC:1122-1147), and searching shows locked recipes whatever Show says (CC:1156).
- **C21:** Translations:
  - six keys are in English only for 25 languages: UI_ZeD_Craft_Max, NeedsBench, NeedsSurface, OpenInCraft, OpenInBuild, AllStructures (DA lacks the last three only). Prove they fall back to English, not the raw key;
  - CC:3100 hard-codes the English surface line;
  - a station's row tag is the last word of the game's station name (ST:356-357), so "Horno primitivo" tags "primitivo";
  - a category with no IGUI_CraftingCategories_ key, or the skill-name fallback, shows raw (CC:940-958, 976-992).
- **C22:** The action is built by hand (CT:453-474) and misses what the game sets:
  - recipeItem (the at-hand book's progress);
  - force;
  - the instant-actions cheat (HA:258).

  It stops on walk by isCanWalk and All Thumbs or awkward gloves, where the game reads the CanBeDoneWhileWalking tag and hasAwkwardHands (HA:407-414). Prove a walking recipe and All Thumbs match.
- **C23:** OnAddToMenu answers are kept until the known recipes, a level or the sandbox option change (RI:118-133). A check that reads anything else (an item carried, a trait) can stay shown or hidden.
- **C24:** Test drift: bx_craft:548-549 and vx10_craft:1182 assert the old toggle. FEATURE_MAP rows 243-248 and 362 have stale lines; row 243's "again: nil" is wrong since KISS #47.
