# Farm plot, trough, hutch and butcher hook cards: map for the gamut sweep (QA, Nov 26 2026)

A read-only map of four of ZeD's object cards against the game's own farming and animal UI and actions (B42: ISFarmingMenu, ISFarmingInfo and the farming timed actions; ISFeedingTroughMenu and ISFeedingTroughUI; ISHutchMenu and ISHutchUI; ISButcherHookUI and the butchering actions), written before the sweep scripts. It maps the shared frame (ObjectCards.lua) only as far as these four use it. Line refs are as read on Nov 26. Nothing was run.

**All four are object cards in the World window's card drawer, never the half card.** Each kind registers with OC.register (FC:658, TC:320, HC:499, KC:529); none sets def.half, so the drawer is OBJECT_CARD_W, 480 units, over whatever tab is up (WW:79, 2224-2228, 2284-2288). The game's own windows never show while ZeD runs, except in safe mode (IC:38, 51; AN:53, 69, 82).

Short names: OC ObjectCards.lua, FC ObjectCardFarm.lua, TC ObjectCardTrough.lua, HC ObjectCardHutch.lua, KC ObjectCardHook.lua, IC Overrides/InfoCards.lua, AN Overrides/Animals.lua, AT AnimalsTab.lua, WW ZeD_WorldWindow.lua, MO Molecules.lua (ZeD.Disclose), ZUI shared/Translate/EN/UI.json (ZeD's words).
The game's files (media/lua unless noted): FM client/Farming/ISUI/ISFarmingMenu.lua, FI client/Farming/ISUI/ISFarmingInfo.lua, CPG client/Farming/CPlantGlobalObject.lua, SPG server/Farming/SPlantGlobalObject.lua, SFS server/Farming/SFarmingSystem.lua, VC server/Farming/farming_vegetableconf.lua, VV server/Farming/farming_vegetableconf_vegetables.lua, FZA shared/Farming/TimedActions/ISFertilizeAction.lua, CPA .../ISCurePlantAction.lua, SHA .../ISShovelAction.lua, FTM client/FeedingTrough/ISUI/ISFeedingTroughMenu.lua, FTU .../ISFeedingTroughUI.lua, STG server/FeedingTrough/SFeedingTroughGlobalObject.lua, AWT shared/FeedingTrough/TimedActions/ISAddWaterToTrough.lua, EWT .../ISEmptyWaterInTrough.lua, WOCM client/ISUI/ISWorldObjectContextMenu.lua, HM client/ISUI/Hutch/ISHutchMenu.lua, HUI client/ISUI/Hutch/ISHutchUI.lua, HGE shared/TimedActions/Animals/ISHutchGrabEgg.lua, HCF .../ISHutchCleanFloor.lua, BHU client/ISUI/Animal/ISButcherHookUI.lua, BU shared/Definitions/animal/ButcheringUtil.lua, OBH shared/TimedActions/Animals/ISOpenButcherHookUI.lua, PAH .../ISPutAnimalOnHook.lua, RAH .../ISRemoveAnimalFromHook.lua, RMA .../ISRemoveMeatFromAnimal.lua, RLA .../ISRemoveLeatherFromAnimal.lua.
FEATURE_MAP rows 366-369 still read "not checkable" or "not yet: no farm on the QA save" though bx_farm, vx_world and zedqa_cov_farmcards now stage a farm; row 366 cites InfoCards:59-62 for the hooks, which are IC:80-85.

## The shared frame (OC, as far as these four use it)

- OC.open: resolve the object, then ZeD_WorldWindow.openObjectCard (OC:152-159, WW:6576-6598); OC.openNear walks next to the square first when it is past the kind's leash less half a tile, then opens with a one-tick action (OC:164-194).
- Leash: OC.LEASH 6 tiles (OC:57); hutch 5 from the entry square (HC:36, 47), hook 4 (KC:109). Closes past leash + 0.5 or on another floor, except while an action the player started with the card open is still queued (OC:279-288). Closes in a vehicle or when dead (OC:272).
- Data: def.refresh every 15/60 s, 250 ms (OC:63, 289-295); a press asks for one 50 ms later (OC:958, 1532). The browse list (header arrows, "n / m") is def.nearby every second (OC:64, 296-304), in reading order (OC:125-131).
- keepOnLoss (farm only): when the shown object is gone the card steps to the next live one in reach instead of closing (OC:254-271).
- Verbs: drawn in order primary, others, danger last (OC:1191-1201). Hidden actions (MO:5262-5293): folded (default; verbs you can't do fold into one row), all (grayed with NEEDS lines), hide; sensible = false drops a verb in every setting. A verb with confirm asks in the foot band, focus on Cancel (OC:943-947); jump moves the view and focus to a list (OC:949-953). There is no busy gate: a press runs whenever the button is lit (OC:938-960).
- Pad: focus zone worldItemCard. Every zone with a fid is a stop (OC:1683-1709). The card opens on def.openFocus, else the primary verb, else the first lit verb, else the back button (OC:1408-1414, 1217-1226); a D-pad move into the card lands on the same verb (isPrimary, OC:1690). B cancels a question, else closes the card (OC:1693-1695). Header stops: oc:back, oc:prev, oc:next (OC:1089, 1139, 1150); verbs oc:verb:<id>, oc:more, oc:hv:<id>; question oc:confirm:no, oc:confirm:yes.
- onClose runs only when setEntry changes the entry (OC:886-903); OC.browse swaps e.t with no onClose (OC:309-317).
- Lite: no branch in OC or in any of the four cards.
- Small screens: the drawer width for these four is always 480 units. The held-in rule that drops a tab to the half card beside the inventory (WW:2267-2271) does not apply to object cards (WW:2284-2288); the window is capped at half the screen (WW:2806, 4616-4635), so at 1280 wide with the inventory open the inventory gets what is left (about 640 - 36 - 36 - 480 = 88 px at scale 1, under its 180-unit minimum, WW:78).

## Farm plot card (kind plant)

### 1. What the card does

**Getting there:**
- The game's world menu on a plot: the crop's name, Info (FM:276-296). ISFarmingMenu.onInfo is wrapped: the card opens at once, no walk and no info cursor (IC:33-43, 80-84). ISPlantInfoAction:perform is wrapped for any other caller, such as the game's info cursor (IC:46-58, 85; FM:931-940).
- Plowed land has no Info in the game's menu (FM:254-257): an empty furrow's card is reached only by the garden strip, the header arrows or the card stepping on (keepOnLoss).
- Seated in a car, the game's farming menu is not built (FM:119-121) and an open card closes (OC:272).
- No D-pad wheel slice. Safe mode hands every path back to the game (IC:38, 51).

**Data (def.refresh FC:215-329, every 250 ms):**
- The plot is the farming system's client object on the square (CFarmingSystem getLuaObjectOnSquare, FC:143-159); updateFromIsoObject in a pcall before each read (FC:157).
- Skill: CFarmingSystem getXp; pests read at skill + 2 with a magnifier in either hand (FC:219-220, 60-63), as the game (FM:53-63).
- State, phase (FC:84-93: Seedling, Young, Almost ready, Ready, In bloom, Rotten; the game's getObjectPhase order, VC:168-186), water level, waterNeeded, waterNeededMax (100 when none; no live crop sets one, VV comments only), first stage (nbOfGrow 1), compost.
- Next stage at Farming 6: the game's ISFarmingInfo.getNextGrowingPhase (Hours, Days, Weeks, Months), lowercased into "in %1" (FC:234-237, FI:524-562).
- Pests: mildew, flies, aphids, slugs with the spray each needs, found in hand or bags with one use left (FC:29-34, 54-58, 238-241).
- Seeds: every crop's seed types counted with the game's good-seed rule (FC:40-50, 178-213; FM:24-51); season tags only when PlantGrowingSeasons is on and the player is Farming 6 or knows the crop's season recipe (FC:181, 199-206).
- Water sources: the item in hand if it has water uses, else every top-level inventory item with uses, most uses first (FC:65-79). Shovel: the game's getShovel (FC:244, FM:126-135). Fertilizer: type Fertilizer or tag Fertilizer; compost: CompostBag or tag Compost, anywhere in the bags (FC:247-248).
- Not read: health, fertilizer count, weeds, last watered (FC:6-9). The client has them (SFS:30-34).

**The view (def.body FC:528-656):**
- Head: the crop icon or the furrow tile (FC:332-340), the title "Plot", the game's object name ("Young Carrots"), "Farming n" (FC:556). The tag shows only Empty, Rotten, Dead or Harvested; a living plant has none (FC:342-352, audit 31).
- Plowed: "Sow from your bags" with the month, one row per seed type and its count, a season tag, Sow (FC:535-554).
- Planted: a dim "More at Farming 2, 3, 4 and 6" line (FC:559-571); the six-step phase strip from Farming 2 (FC:377-413); Next stage and Compost (FC:575-581); Water: the game's word with a dot, the bar with the needed zone from Farming 4 (FC:583-599); Pests and disease: four rows with a word from Farming 3 (+2 magnifier) and a Treat per row when the spray is carried (FC:602-650).
- Garden in reach: every plot within 6 tiles on the floor, eight to a row, the crop's first three letters and an urgency dot; a summary "n dry, n thirsty" (FC:441-526).

**Verbs (FC:252-327), each the game's own timed action queued directly (the game's handlers skip pad players and arm a cursor, FM:649, 653):**
- Sow (plowed): jumps to the seed list; a row's Sow: the walk, the seed moved to the inventory, ISSeedActionNew (FC:254-255, 541-551), as FM:1192-1199.
- Water: the first source, equipped, the walk, ISWaterPlantAction with min(uses, missing / 10, 10) uses (FC:264-276); gone when the plant is dead or full; main verb at 60 or less and not ripe.
- Fertilize: the walk, the fertilizer equipped, ISFertilizeAction (FC:277-285). Compost: only while compost is carried, same action (FC:286-296).
- Treat: jumps to the first pest row with a spray (FC:297-312); a row's Treat: the walk, the spray equipped, ISCurePlantAction with 1 use, 100 ticks (FC:621-630).
- Harvest: only when ripe; the walk, ISHarvestPlantAction (FC:313-317).
- Dig up: asks first, "Dig up the <crop>? The crop is lost." or "Clear the <name>?" (FC:318-325, ZUI:986-987); the walk, the shovel equipped, ISShovelAction.
- The garden cells pick that plot (FC:494-504).

**Settings:** hidden actions (MO:5262-5293; a Treat row with no spray shows grayed only under all, FC:607, 621, 644-647); PlantGrowingSeasons (the tags); FarmingSpeedNew through the game's next-stage words; the Farming level and a magnifier; UI scale, text size, theme.

**Lite:** no branch.

**Pad:** oc:verb:sow, water, fert, compost, treat, harvest, dig; farm:sow:<i> (seed rows), farm:treat:1..4 (pest rows), farm:g:<i> (garden cells); oc:prev, oc:next. No openFocus: the card opens on the primary verb, else the first lit one (OC:1217-1226).

**Small screens:** 480 units always (see the frame). Garden cells are (w - 28) / 8, about 54 units at 460 (FC:446-449); labels are cut to three letters, not measured (FC:477).

### 2. Against the game (steps)

| Job | Game | ZeD farm card |
| --- | --- | --- |
| Read a plot | Right-click (1), the crop (1), Info (1), walk and look | The same three; the card opens at once |
| Check every plot's water | Info per plot (3 each) | The garden strip and its summary (0) |
| Water a plot | Right-click (1), crop (1), Water (1), the source (1), the amount (1) | Water (1) |
| Water a row of 8 | 5, then the cursor: one click per plot (7) = 12 | Per plot: its cell (1), Water (1) = 15 |
| Sow | Right-click (1), crop (1), Sow seed (1), the seed (1); the cursor for more | Sow (1) and the seed row (1); or the row alone (1) |
| Fertilize | Right-click (1), crop (1), Fertilize (1) | Fertilize (1) |
| Treat heavy aphids (30+) | Right-click (1), crop (1), Treat (1), Aphids (1), 1-10 uses (1) | The row's Treat (1) per use, a walk and an equip each (3+) |
| Harvest | Right-click (1), crop (1), Harvest (1) | Harvest (1) |
| Dig up | Right-click (1), crop (1), Remove (1) | Dig up (1), Yes (1) |
| See the next stage | Info at Farming 6 | The card at Farming 6 |

ZeD has, the game doesn't: the phase strip, the garden strip with urgency dots, the season tag per seed row, a question before digging up, the readings and verbs in one place, a pad path with no cursor.

The game has, ZeD doesn't: the choice of water source and amount (FM:348-370), 1-10 aphid sprays at once (FM:436-446), the click-another-square cursor after every verb, the word colored by the crop's own need from Farming 3 (FI:468-491), the vanilla Info window's distance close at 6 by DistTo (FI:238-246; ZeD: 6.5 from the square's center).

### 3. States to sweep

- **Plots:** plowed; seeded at nbOfGrow 0, 1, 2; young; almost ready; ready; in bloom; rotten; dead (dry); dead (disease); destroyed (trampled); harvested; a growBack crop after harvest; a plot on an upper floor (PlaceDirtAboveground).
- **Water:** 0, 20, 25, 26, 50, 51, 60, 61, 80, 81, 100; a crop needing 70 and one needing 80 at 65 and at 60; first stage under its need.
- **Pests:** each at 0, 9, 10, 29, 30, 60; seen at Farming 2, 3, 5 and with a magnifier; a spray with one use; two sprays of one kind.
- **Fertilizer:** none, one dose, two, three; compost on, compost twice; Fertilize and Compost on a dead plot.
- **Seeds:** none; one; five of one type; two seed types of one crop; rotten or cut seeds (the good-seed rule); every season tag (best, risky, in season, bad) with seasons on and off; Farming 5 without the recipe and 6.
- **Sources:** a bottle in hand, none in hand, several in the bags, tainted water, a bucket in a bag (not top level).
- **Presses:** each verb twice (mouse, pad A A), during the walk and the action; the window shut mid-walk; the Animals tab mid-action.
- **Changes while open:** the plot dug up, harvested, dried, rotted, watered by rain or another player; a new plot plowed in reach; a field of 100+ plots in 6 tiles.
- **Pad:** every stop; the opening focus on a ripe plot, a thirsty one with and without water, a watered one with fertilizer carried; B with and without the question.
- **Layout:** 1280x720 and 1280x800 at UI scale 1 and 2, Large text, the inventory open and shut; 4K; long crop names in the garden.
- **Settings:** hidden actions folded, all, hide.
- **Languages:** EN, DE, FR, ES, RU, JP: the garden labels, the "More at" line, the next-stage words, the Dig question.
- **MP:** another player waters, digs or harvests the shown plot; the Dig question open while another player removes the plot.

### 4. What the tests check already

| Script | What it checks |
| --- | --- |
| bx_farm (611-956) | A dig stopped half way; Info opens the card; plowed: Empty, only Sow; one seed and five seeds, Sow twice in one frame; water 20, Water waits, a bottle makes it live, a tab pressed mid-watering, the level after; Fertilize runs the game's action; Harvest live exactly when the game says, main verb; a rotten plant: no Water, Dig up asks, Cancel, Yes; < and > 30 times; every plot taken away under the card |
| zedqa_cov_farmcards (1056-1184) | Plowed: Empty, only Sow; the strip and arrows; Sow jumps and sows; Parched tag at 20; Water live with a source and the main verb; Dig up names the crop; > steps, a garden cell picks, < wraps; keepOnLoss. In no run list (regression.txt:210) |
| hfr_farm (148-160), gallery_farm_ranch | Pictures of the card at two stages |
| zedqa_deep_run (380-392) | Stages plots at four stages for the pad map |

**Gaps:**
- Fertilize twice, three times; Compost on a composted plot; either on a dead plot (none checks the plant's health or fertilizer after).
- Treat: no script presses a pest row or checks the pest words against getDiseaseString at Farming 2, 3 and with a magnifier.
- The water word and dot against the game's calcWater for a crop needing 70 or 80; the garden summary's counts.
- Next stage at Farming 6 against the game's words; the phase strip against getObjectPhase.
- Season tags; seed rows with two seed types.
- The pad's opening focus on each state; A A on a plot.
- The Dig question when the plot changes under it.
- Hidden actions all and hide; Large text; 1280 wide with the inventory; languages other than EN; MP.
- Test drift: zedqa_cov_farmcards:1104 expects the tag "Parched" on a living plant, which FC:349-351 no longer draws (audit 31, Nov 20); its comment at 70-74 expects the < wrap to FAIL, fixed in OC:313; FEATURE_MAP:366 (see the head).

### 5. Suspicions (to prove in the game)

Ordered by what they can cost: a dead crop first, then wasted seed, fertilizer or spray, then time.

- **FA1:** Fertilize is one press with no reading of the dose already given, and nothing stops a second press. The game's second dose takes 25 health and a third curses the plant and takes 25 more, killing it at 0 (SPG:530-561); a dose wears off by one per growth step (VC:278-280). The client holds plant.fertilizer (SFS:30), but the card never reads it (FC:6-9, 247, 277-285) and Fertilize stays lit at any count with no question. There is no busy gate (OC:938-960), so Fertilize pressed twice during the walk queues two doses. The game's menu is as silent (FM:238-241, 301) but each dose costs three clicks and a cursor. Prove: two presses on a plant at 60 health, read health after (60 + 10 - 25).
- **FA2:** The water word's dot, the garden strip's dot and the summary use fixed bands for every crop: 50 or less red, 60 or less amber, above green (FC:96-103, 114-132, 510-526, 584). The game grows a plant only at its waterNeeded, stops it below need / 1.1 and takes 4 health per missed step below need / 1.3 (VC:130-148, 340-373). Most crops need 70 or 80 (VV waterLvl: 69 entries at 70, 14 at 80). A crop needing 80 at 65 reads "Fine" with a green dot and does not grow; at 60 it loses health and reads amber "Thirsty". The game colors the word by calcWater from Farming 3 (FI:468-491); the card colors only the bar, from Farming 4 (FC:585-594), and the summary never. Prove: a stage-2 crop needing 80 set to 65 and to 60 at Farming 3.
- **FA3:** On a pad, the card can open on Fertilize. With no openFocus the focus lands on the primary verb, else the first lit one in draw order (OC:1191-1201, 1217-1226, 1408-1414). A watered, unripe plant with no water carried (Water folded away) and fertilizer in the bags opens with focus on Fertilize; a second A gives a dose (FA1). Prove: Info from the pad on such a plant, then A.
- **FA4:** The Dig question can act on another plot. When the shown plot is gone, keepOnLoss swaps e.t for the next plot in reach (OC:254-271) and leaves card._confirm open; Yes runs the verb on e.t as it is then (OC:1525-1533). With "Dig up the carrots?" open and the plot removed by another player (MP) or dug from the game's menu, Yes digs up the next plot, which may hold a different crop. The header arrows and garden cells clear the question (OC:1139, 1150; FC:501); the step does not. Prove in MP, or with the game's own Remove on the shown plot while the question is up.
- **FA5:** Harvest becomes the main verb at Ready, where the harvest gives no seeds: seeds come only from a plant In bloom (SFS:354-359; VC:285-291). The card makes Harvest primary as soon as canHarvest (FC:313) and the pad lands on it; nothing says that waiting gives seed. The game offers Harvest the same way (FM:309-315). A player who harvests every crop at Ready runs out of seed. Prove the seed count from a Ready and an In bloom harvest.
- **FA6:** Fertilize and Compost are offered on dead, rotten and harvested plots and Compost on a plot already composted (FC:247-248, 277-296: no sensible check; the body even reads "Compost: Yes", FC:575-580). The game's fertilize does nothing on a plant that is not alive (SPG:523) and compost nothing when compost is on (SPG:571), but the action spends the item anyway (FZA:59-67). The game's menu has the same waste (FM:238-245). Prove one use gone on a dead plot.
- **FA7:** Treat spends spray on a pest at None. Every pest row's Treat shows when its spray is carried (FC:621-630), also at Farming 3 and up where the row itself reads None (FC:634-640); the game spends a use per spray whatever the level (CPA:72-78; SPG:436-497). Heavy aphids take one press per use, each with a walk and an equip (FC:626-629), where the game sprays up to 10 at once (FM:436-446).
- **FA8:** Water has no choice of source or amount: the item in hand, else the one with the most uses (FC:65-79, 268), always filled to 100 (FC:271). The game lists every source by name and 10 to 100 (FM:348-370). Carrying a jug of purified drinking water and a smaller bottle, the card pours the jug. Prove which item loses water.
- **FA9:** Sowing in a month outside the crop's season curses the plant (lower health, double bad-care loss, no bonus yield; SPG:725-745, VC:365-367) with no question; the tag shows only at Farming 6 or with the recipe (FC:199-206), as the game's tooltip (FM:543-560).
- **FA10:** Small screens. The card is always 480 units (see the frame): at 1280x800 with the inventory open the inventory is squeezed to about 88 px at scale 1 and the card may run past the cap at UI scale 2. The garden labels are not measured (FC:477): at Large text three letters may overrun a 54-unit cell. Prove at 1280x800, scale 1 and 2, Large text.
- **FA11:** Words.
  - UI_ZeD_Farm_MoreAt and UI_ZeD_Farm_ListAnd are in EN only (ZUI:993-994; 0 of 27 languages), so every plant card below Farming 6 shows an English line.
  - The garden's three letters collide (FC:477): EN Bro (Broccoli, Broadleaf Plantain), Ros (Rosemary, Roses), Chi (Chives, Chinese Evergreen); DE Kar (Karotten, Kartoffeln); FR Cho (Cabbages, Cauliflower, Kale); ES Ceb (Barley, Chives, Onions).
  - The game's next-stage word and the crop and plot names are lowercased into ZeD's lines (FC:236, 320): German nouns lose their capitals.
  - A trampled (destroyed) plant's tag says Dead; the game's name says Destroyed (FC:348, VC:194).
- **FA12:** Changes while open and MP. The garden calls updateFromIsoObject on every listed plot every 250 ms (FC:419-432); a large field in 6 tiles is many calls per refresh. The game's own window rereads mod data on an MP client "because the client does not have an up-to-date list of plants" (FI:33-39); prove the card's water and pests follow another player's watering and spraying. The shovel is checked at refresh, not at Yes (FC:244, 318-325): a shovel dropped between the press and Yes queues ISShovelAction with no item, which throws at start (SHA:26-27).
- **FA13:** Test drift: see section 4.

## Feeding trough card (kind trough)

### 1. What the card does

**Getting there:**
- The game's world menu on a trough: its name, Feeding Trough Info (FTM:41-51). ISFeedingTroughMenu.onInfo is wrapped: OC.openNear on the trough's square, walking first when it is 5.5 tiles or more away (AN:77-86, OC:183-194).
- The Animals tab's zone page lists the zone's troughs; a row opens the card the same way (AT:2023-2030, 2112-2113).
- Safe mode: the game's window (AN:82).

**Data (def.refresh TC:133-216):**
- The master trough (getMasterTrough, TC:33-37); valid while it has an object index (TC:45-48), as the game's window (FTU:59-65).
- Name: the moveable's display name (TC:136-137). Items lying in it, grouped by type (TC:139-145, 86-99). Feed: getCurrentFeedAmount (TC:147). Water: getWater, getMaxWater, the fluid's color and name, tainted by the game's tooltip rule and EnableTaintedWaterText (TC:148-155, 67-77).
- Zone: DesignationZoneAnimal.getZone at the master's square and its name; linked animals: getLinkedAnimals (TC:158-163), as FTU:70-77.
- Feed you carry: every unequipped item in the bags the trough's container allows (isItemAllowedInContainer), grouped, with where it is (TC:166-176).
- Water you carry (only while no food is in it): every item with fluid FluidContainer.CanTransfer allows into the trough, with its liters (TC:179-193).

**The view (def.body TC:257-318):**
- The tag: Food (green), Water (in the water's color) or Tainted (red), Empty (TC:222-232).
- A warning when it stands outside any animal zone (TC:264-266).
- Food: the feed amount, large (TC:267-268). Water: liters of max, the strip in the water's color with its name (TC:269-273).
- In the trough: one row per kind with Take (TC:276-285).
- Zone: Linked to, Animals "n use it" (TC:288-291).
- Your feed (unless water is in it): one row per kind with Add, or "Nothing to add" (TC:294-306).
- Your containers (unless food is in it): one row per container with Transfer (TC:309-316).

**Verbs (TC:199-215):**
- Add food: jumps to the feed list; gone while water is in it (TC:202-204).
- Add water: opens the fluid card aimed at the trough; gone while food is in it (TC:205-207, 120-128).
- Empty (water only): asks "Empty the trough? <liters> of <fluid> is lost." (ZUI:4028), then the game's generic ISWorldObjectContextMenu.onFluidEmpty: the walk, ISFluidEmptyAction (TC:208-214; WOCM:2856-2868).
- A row's Add or Take: the walk to the trough, one ISInventoryTransferAction per item of that kind (TC:104-118, 280-282, 301-303).
- A container's Transfer: the fluid card from that container into the trough (TC:313-314).

**Settings:** hidden actions; EnableTaintedWaterText (TC:74); UI scale, text size, theme.

**Lite:** no branch.

**Pad:** oc:verb:food, water, empty; trough:take:<i>, trough:feed:<i>, trough:pour:<i>. No openFocus: the primary verb (Add food when no water, Add water when water is in it) if lit.

**Small screens:** 480 units always.

### 2. Against the game (steps)

| Job | Game | ZeD trough card |
| --- | --- | --- |
| Read the trough | Right-click (1), its name (1), Info (1) | The same three; or its row on the Animals tab (1) |
| Put feed in | Open the trough in the loot window (1-2), drag the item (1) | Add food (1) and the row's Add (1); or the row alone (1) |
| Put one bag of three in | The loot window (2), drag one (1) | Not possible: Add moves all three |
| Take feed out | The loot window (2), drag (1) | Take (1) |
| Add water | The fluid menu or the loot window's fluid panel (2-3), the source and amount (2) | Add water (1), then the fluid card (2+) |
| Empty water | The fluid menu (2), Empty (1) | Empty (1), Yes (1) |
| See the zone and animals | Info | The card |

ZeD has, the game doesn't: the tag, the water strip in its color, the no-zone warning, feed and water you carry listed with where each is, a question before Empty.

The game has, ZeD doesn't: moving one item of a stack, the game's own trough water actions (ISAddWaterToTrough, ISEmptyWaterInTrough, FTM:180-192).

### 3. States to sweep

- **Troughs:** single and double, wood and metal; north and west; inside a zone, outside any, straddling a zone's edge; two troughs side by side.
- **Contents:** empty; feed bag full, half, at 0; hay; grain; a mixed load; water clean, tainted, mixed; a fluid other than water if any can go in; full to max.
- **Carried:** no feed; one bag; three bags; feed in a backpack; an equipped bag; bottles of water, tainted water, bleach, gasoline, milk.
- **Presses:** Add, Take, Empty, Transfer twice; mid-walk; the window shut mid-walk.
- **Changes while open:** animals eating the feed to nothing; drinking the water out; rain; the trough picked up; food taken out by another player.
- **Pad:** every stop; the opening focus with food, with water, empty.
- **Layout:** 1280x800 with the inventory; Large text; long item names.
- **Languages:** the fluid names in the question.
- **MP:** linked animals and the zone on a client; Add from one client while another looks.

### 4. What the tests check already

| Script | What it checks |
| --- | --- |
| bx_farm (1076-1171) | Opened from the Animals tab row: Empty; the zone line; filled: the liters; Empty asks and empties; a feed bag added by its row; the card says Food exactly when the game holds some; taken away under the card: it closes |
| zedqa_cov_farmcards (721-822) | Info opens the card; Empty tag; the zone line; water: liters, tag, no Add food, Add water main, Empty asks with the liters, queues ISFluidEmptyAction, empties; Add water opens the fluid card; feed: tag Food, rows, no Add water or Empty; Take; Add food jumps; Add moves feed in. In no run list |
| hfr_farm (180-184) | A picture of the card |

**Gaps:**
- Pour from each container type; which fluids the trough takes; the fluid card's return.
- Add with several items of one kind (all move); a bag in a backpack.
- The Food tag with feed at 0; feed eaten while the card is open.
- Water added after food is taken out (the fluid container's return).
- The no-zone warning; a trough straddling a zone edge; linked animals against the game's count.
- The pad; Large text; 1280 wide; MP; languages.

### 5. Suspicions (to prove in the game)

Ordered by cost: a dead or sick animal first, then a starving or thirsty one, then wasted feed, then time.

- **TG1:** Transfer lists every fluid FluidContainer.CanTransfer lets into the trough (TC:179-193), not only water; the game's own trough path pours water sources only (AWT:46-60 relaunch: getAllWaterFluidSources). If the trough's fluid container has no whitelist, bleach, gasoline or alcohol can be poured where animals drink; the tag then reads Tainted only if the fluid is poisonous (TC:67-77, 228). Prove with a bottle of bleach and one of gasoline: are they listed, and does the transfer go through?
- **TG2:** The Food tag counts items, not feed: hasFood = any item in the container (TC:146, 226); the big number is the feed amount (TC:147, 268). An item with no feed left (an emptied bag, anything the container allows that is not eaten) keeps a green Food tag while the animals starve; the Animals tab's row uses the same count (AT:1979-1981). Prove: let the animals empty a bag; read the tag and the feed.
- **TG3:** Add water can be grayed with no reason. It needs the trough's fluid container (TC:201, 148), which the game removes when food goes in (FTM:169, debug path) and makes again when food is taken out (FTM:143-145, debug path); the verb has no needs text (TC:205-207), so under folded it is hidden and under all it reads a bare NEEDS line. Prove: food in, Take all, then Add water.
- **TG4:** The zone and linked count. The zone is read at the master's square only (TC:158-161), as the game's window (FTU:72); a double trough with one tile in a zone may read "No zone" while animals use it, or the reverse. getLinkedAnimals (TC:162-163) is prove-on-client in MP. Prove both.
- **TG5:** Add and Take move every item of a kind (TC:280-282, 301-303, 104-118): three feed bags, or every carrot the trough allows, go in at one press, with no amount. The game's loot window moves one or a chosen stack. Prove with ten carrots carried.
- **TG6:** Empty uses the generic fluid empty on the trough's container (TC:213; WOCM:2856-2868), not the trough's own ISEmptyWaterInTrough (FTM:180-184, EWT:34-40), which updates the trough's server object (STG:84-91). Prove in MP that the server and other clients read 0 after the card's Empty.
- **TG7:** Add water and Transfer open the fluid card in the trough card's place (TC:120-128); prove whether the trough card comes back after the pour (extra steps to check the level).
- **TG8:** Small screens: as FA10.
- **TG9:** Words: the fluid's name is lowercased in the Empty question (TC:209); "L" is written into the numbers (TC:28, 270).
- **TG10:** Test drift: FEATURE_MAP:367 "not yet"; zedqa_cov_farmcards is in no run list.

## Hutch card (kind hutch)

### 1. What the card does

**Getting there:**
- The game's world menu on a hutch: Hutch, Info (HM:20-24). ISHutchMenu.onInfo is wrapped: OC.openNear from the entry square, walking first when it is 4.5 tiles or more away (AN:64-74). The game walks onto the entry square every time (HM:96-101).
- ISGetHutchInfo:perform is wrapped (AN:75).
- The Animals tab lists hutches on its Ranch and zone pages (AT:2240, 4089; WW:1003 for the pad).
- Safe mode: the game's window (AN:69).

**Data (def.refresh HC:186-285):**
- The master hutch (getHutch, HC:38-41); the leash from the entry square (HC:47).
- Doors: isOpen, isEggHatchDoorOpen, isAllDoorClosed; boxes covered only with both shut, perches with the main door shut (HC:192-196), as HUI:72, 299-318, 386, 626-640.
- Nest boxes: getMaxNestBox + 1 boxes, each its eggs and the hen sitting in it; free boxes are those with eggs and no hen (HC:199-210), as HUI:238; full: haveRoomForNewEggs false (HC:211).
- Perches: getAnimal(0..max-1), dead or alive, the dead body (HC:213-223).
- Floor: getHutchDirt; water, mop and bleach as the game's Clean finds them (HC:226-231; HUI:614-617, 801-808).
- A bird in the primary hand that canBePutInHutch (HC:234-238); the count from getAnimalInside (HC:239-240).
- A box chain for Grab eggs (HC:85-119): the first box queued, the rest one at a time from the refresh when idle; dropped when the last box still holds eggs at idle (a cancel) or when another verb runs.

**The view (def.body HC:436-497):**
- The tag: Shut (dim) or Open (green) (HC:292-298).
- Egg laying boxes, "n eggs": a hatched plate "both shut", else one panel per box: its number and count, ten egg slots or the sitting hen with her name, Grab on a box with free eggs; "the boxes are full" note (HC:448-463, 337-383).
- Birds "n / max": a plate "door shut", else "No birds inside.", else a row per bird with a portrait, name, sub-line, Dead tag, Grab and Info (HC:469-479, 385-416).
- Floor: dirtiness % on a strip (40 amber, 70 red, as HUI:660-664), then water, mop and optional bleach marks while dirty (HC:482-495).

**Verbs (HC:244-284), the game's own actions as its window queues them:**
- Both doors shut: Open door (main), Open hatch. Otherwise Grab eggs (main while a free box has eggs: the walk to the entry, empty hands, ISHutchGrabEgg per box), then the door and hatch toggles (ISHutchMenu.onToggleDoor and onToggleEggHatchDoor: the walk, the toggle).
- Clean: shown while dirty; needs water and a mop; the walk, the mop equipped, ISHutchCleanFloor (HC:131-139, 270-272), as HUI:801-808.
- Put in: only with a bird in hand; grayed with both doors shut; gone when the hutch is full (HC:277-283); ISHutchMenu.onPutAnimalInsideHutch.
- A box's Grab: that box only (HC:372-381). A bird's Grab: the walk, empty hands, ISHutchGrabCorpseAction for a dead one with a body, else ISHutchGrabAnimal (HC:121-129), as HUI:416-438. A bird's Info: closes the card and opens the Animals tab on the bird (HC:142-151).

**Settings:** hidden actions; UI scale, text size, theme.

**Lite:** no branch.

**Pad:** oc:verb:door, hatch, eggs, clean, putin; hutch:box:<i> (0-based, only on a box with free eggs, HC:340, 373-381); hutch:bird:<i>:grab and :info (0-based, two per bird, up to 40 stops, HC:396). openFocus: the first free box when the boxes show (HC:301-305), else the primary verb.

**Small screens:** 480 units; four boxes are about 110 units each (HC:454-457), the egg slots up to 14 units (HC:361); a box's Grab is cut to the box (HC:375).

### 2. Against the game (steps)

| Job | Game | ZeD hutch card |
| --- | --- | --- |
| Open the hutch's view | Right-click (1), Hutch (1), Info (1), the walk to the entry | The same three (walk only from 4.5 tiles); or its row on the Animals tab (1) |
| Open the door | Right-click (1), Hutch (1), Open door (1); or in the window (1) | Open door (1) |
| Take every egg (4 boxes) | Per box: right-click it (1), Grab eggs (1) = 8 | Grab eggs (1) |
| Take one bird | Coop tab (1), right-click the perch (1), Grab (1) | Its Grab (1) |
| A bird's details | Right-click (1), Info (1) | Info (1) |
| Clean the floor | Coop tab (1), Clean (1) | Clean (1) |
| Put a bird in | Right-click (1), Hutch (1), Put in (1) | Put in (1) with the card up |

ZeD has, the game doesn't: one Grab eggs for every free box, the egg and bird counts on one page, the checklist for cleaning, the hutch reachable from the Animals tab.

The game has, ZeD doesn't: the 3D birds; a grayed Put in with "Hutch full" (HM:57-62); hutch:reforceUpdate on open (HUI:971-972); the egg panel's Info on a sitting hen (HUI:152-153; ZeD shows her name only).

### 3. States to sweep

- **Hutches:** Henhouse and Turkeyhouse (HutchDefinitions), two hutches in reach, a hutch on another floor.
- **Doors:** both shut, hatch only, main only, both open; toggled by another player while the card is open.
- **Boxes:** all empty; 1, 9, 10 eggs; a hen sitting on eggs; boxes full; a box with eggs and a hen arriving mid-chain.
- **Birds:** none; one; 20 (full); a dead one with a body and without; a chick; named birds; birds walking out at day.
- **Floor:** 0, 1, 41, 71, 100; water only, mop only, both, with bleach; a broken mop; tainted water.
- **Carried:** a hen in hand; a turkey into a henhouse; a hen with the hutch full; with both doors shut.
- **Presses:** Grab eggs on 4 boxes and the pointer moved off the window; stopped mid-walk; Grab eggs twice; Clean twice; Put in twice.
- **Changes while open:** a hen lays; a hen sits; a bird dies; the hutch picked up; another player takes eggs.
- **Pad:** every stop; openFocus with and without free eggs; Info and the way back.
- **Layout:** Large text with four boxes; 1280x800 with the inventory.
- **Languages:** the hutch names, Birds, n eggs.
- **MP:** Grab eggs with the server's counts; two players at one hutch.

### 4. What the tests check already

| Script | What it checks |
| --- | --- |
| bx_farm (1411-1482) | Info opens the card; it counts the hen; the doors read as the game has them; the hen taken out under the card: the count follows; the house taken away: the card closes |
| zedqa_cov_farmcards (852-1027) | Shut: tag, plates, Open door main, no Grab eggs; Open hatch: boxes only; a sitting hen: egg count, Grab only on the free box, Grab eggs main, the pad lands on the free box, takes only the free box's eggs; Open door: perches, Grab and Info per bird, Info shows the bird; Clean waits naming both, live with both, cleans, shows only while dirty. In no run list |
| vx_world W33 (1088-1240) | Grab eggs on three boxes stopped in the walk: nothing restarts, the rest forgotten; the next box walked to from the entry after the character is moved 4 squares |
| hfr_farm (164-178) | Pictures with eggs and with the doors open |
| zedqa_deep_run (470-489) | Stages hutches for the pad map |

**Gaps:**
- The chain with the window rolled up or the card closed between boxes.
- Put in (any state); a full hutch.
- A dead bird's Grab (corpse); a turkey house.
- The boxes full note; ten eggs.
- The pad beyond the opening focus: the box buttons vanishing as they empty; Info and back.
- Large text; 1280 wide; MP; languages.

### 5. Suspicions (to prove in the game)

Ordered by cost: a lost or starving animal first, then lost eggs, then time.

- **HU1:** Grab eggs stops after the first box whenever the card stops drawing. The chain runs only inside def.refresh (HC:188, 97-119), and refresh runs only in the card's prerender (OC:1374-1388, 289-295). An unpinned World window rolls up about 2 s after the pointer leaves it (the run scripts hold it down for this reason, zedqa_cov_farmcards:22-25), and a rolled or closed card does not draw. A player who presses Grab eggs and moves the pointer to watch the character gets one box; the rest wait until the card draws again, then start from wherever he stands (a walk back, HC:112). Eggs left in full boxes stop the laying (d.full, HC:211, 459-462). Prove: four boxes, Grab eggs, pointer off the window.
- **HU2:** In MP the chain may end after one box. It treats "idle while the last box still holds eggs" as the player's cancel (HC:103); on a server the eggs leave in the server's animEvent and reach the client with hutch:sync (HGE:51-60), so the client can read eggs for a moment after the grab ends. Prove on a server with three boxes.
- **HU3:** The game's window calls hutch:reforceUpdate when it opens, "just in case ... the hutch isn't updating anymore" (HUI:971-972); the card never does (no reforceUpdate in ZeD). With ZeD the game's window never opens (AN:64-75), so a hutch that stops updating (no laying, no dirt) is never kicked. Prove on a long save: dirt and eggs over days with the card only.
- **HU4:** Put in vanishes when the hutch is full (sensible = not full, HC:279-282) with no reason; the game grays it out with "Hutch full" (HM:57-62). A player carrying a hen sees no verb and no word. With both doors shut the verb is grayed and folded away by default (HC:280; MO:5279-5293).
- **HU5:** Pad and leaving. A box's Grab is a stop only while it has free eggs (HC:373-381): after it empties, prove where focus goes. A bird's Info closes the card and opens the Animals tab (HC:142-151); there is no way back but the Info again. Up to 40 bird stops before the floor and verbs (HC:396).
- **HU6:** Small screens and Large text: a box's Grab is cut to the box width (HC:375) and the hen's name and "Sitting | n" to the box (HC:353-357); prove at Large text with four boxes. The card is 480 units at 1280x800 (FA10).
- **HU7:** Words: UI_ZeD_Hutch_Birds and UI_ZeD_Hutch_Eggs are in EN only (ZUI:1285, 1294; 0 of 27 languages): the two section heads read English. "%1 eggs" reads "1 eggs" (ZUI:1294, HC:449).
- **HU8:** The leash is 5.5 tiles from the entry square's center while nothing is queued (HC:36, 47; OC:285); the game closes past 5 by DistToProper (HUI:738-740). A card held open by a long walk (OC:279-284) closes as soon as the queue empties if he stands past 5.5.
- **HU9:** Test drift: FEATURE_MAP:368 "not yet"; zedqa_cov_farmcards is in no run list.

## Butcher hook card (kind hook)

### 1. What the card does

**Getting there:**
- Every game path ends in ISOpenButcherHookUI (WOCM:1397, client/ContextMenuCode.lua:78, client/TimedActions/ISContextualActions.lua:81), valid within 2 tiles (OBH:3-5). Its perform is wrapped: the card opens and the action finishes (AN:47-61, 88-89).
- The Animals tab's Butcher rows open the card with OC.openNear (AT:2230, 2023-2030).
- Opening makes a Bridge (the surface the game's actions expect of their window) and sets it as the hook's luaHook (KC:51-104, 116-123).
- Safe mode: the game's window (AN:53).

**Data (def.refresh KC:239-293):**
- The carcass on the hook (getAnimal); when it changes (another player, split screen), the bridge rereads it (KC:248-252).
- Parts through the game's ButcheringUtil.updateCorpseDatas into the bridge: leather, blood (BloodQty), head (not headless), meat (parts) (KC:68-76; BU:621-681). When nothing is left the game's helper takes the carcass off the hook through the bridge (BU:644-678, KC:87-95).
- Knife: the first unbroken Butcher Animal item (KC:256); bleeding: isRemovingBlood; the using player and whether it is another (KC:257-260); Butchering level (KC:261); blood containers: ButcheringUtil.getBuckets (KC:262-271).
- No carcass: dead animals carried (type CorpseAnimal) and on the ground within 2 tiles of the player, each checked by the game's rule (not frozen, a hook animal, size 0.4 and up, not a skeleton) (KC:146-192; BHU:567-604).

**The view (def.body KC:431-527):**
- The tag: In use (amber), Empty, Bleeding (amber), On hook (green) (KC:303-311); "in use by another player" note (KC:438).
- Empty hook: Dead animals nearby "within 2 tiles", one row per corpse with where it is, a "not for the hook" tag, Hang; or the game's two empty lines (KC:440-460).
- A carcass: the band while working: the action's name, a bar, the percent, Stop for your own action (KC:464, 369-404); the game's 3D carcass (an ISCharacterScreenAvatar child, hidden when not wholly in view, KC:327-366); Leather, Blood (liters), Head, Meat rows with a mark, Yes, Taken or No and Gather; Knife and Butchering (KC:467-503); a warning when blood is still in and meat or head would spill it (KC:506-510); Collect into: each container with Into, then None (Bleed on the ground) (KC:513-525).

**Verbs and buttons (KC:200-220, 275-292), the game's own actions as its window queues them, each after the walk to the hook:**
- Add corpse (empty hook): jumps to the list; a row's Hang: ISPutAnimalOnHook (KC:200-202).
- Remove corpse: ISRemoveAnimalFromHook, no question (KC:203-205, 283-286).
- Gather (no knife): never pressed, it carries the knife as the NEEDS line (KC:279-282).
- A part's Gather: the knife equipped, ISRemoveLeatherFromAnimal, ISRemoveHeadFromAnimal or ISRemoveMeatFromAnimal (KC:206-213).
- Blood: with containers its Gather jumps to Collect into; without, Bleed: ISCutAnimalOnHook, then the game bleeds it onto the ground (KC:482-492, 214-220). Into: ISCutAnimalOnHook and ISGatherBloodFromAnimal into that container (KC:516-521), as BHU:691-697. While the game bleeds it onto the ground, Into stays live to switch to a container (KC:482, 515), as BHU:186-189.
- Stop: forceStop on the running action that carries a luaHook (KC:223-228, 384-393).
- Closing the card clears the hook's luaHook and takes the 3D child away (KC:314-320).

**Settings:** hidden actions (a part's Gather without a knife shows grayed only under all, KC:419); UI scale, text size, theme; Butchering level shown.

**Lite:** no branch.

**Pad:** oc:verb:add, remove, gather; hook:hang:<i>; hook:leather, hook:blood, hook:head, hook:meat; hook:into:<i>, hook:bleed; hook:stop. No openFocus: the primary verb (Add corpse) on an empty hook, else the first lit verb, which with a carcass is Remove corpse.

**Small screens:** 480 units; the carcass figure 118 x 176 (KC:46); part rows put the value at a fixed 84 units past the row's start (KC:416-418).

### 2. Against the game (steps)

| Job | Game | ZeD hook card |
| --- | --- | --- |
| Open the hook | Right-click (1), the hook (1), the walk | The same; or its row on the Animals tab (1) |
| Hang a carcass | Add corpse (1), the corpse (1) | Add corpse (1) and Hang (1); or Hang alone (1) |
| Take leather, head or meat | Its button (1) | Its Gather (1) |
| Blood into a bucket | Gather (1), the bucket (1) | Blood's Gather (1) and Into (1); or Into alone (1) |
| Bleed onto the ground | Bleed (1); or Gather (1) and None (1) | Bleed (1) |
| Stop the work | Esc or a move | Stop (1) |
| Take the carcass down | Remove corpse (1) | Remove corpse (1) |

ZeD has, the game doesn't: the corpses listed with where each lies and why one cannot hang, the warning that meat or head spills the blood, Stop, the card from the Animals tab.

The game has, ZeD doesn't: Add corpse disabled while the player is doing another action (BHU:31-35); the bleed's progress and blood read every frame (BHU:180-184); the pad starting on the parts (BHU:72-78).

### 3. States to sweep

- **Animals:** cow, bull, calf, ewe, ram, lamb, sow, boar, piglet, buck, doe, fawn; a roadkill; a skeleton; a frozen carcass item; a corpse under size 0.4; a named animal.
- **Sources:** a carcass in the inventory, in a bag, on the ground 1 and 2 tiles off, 3 tiles off; two corpses.
- **Parts:** all in; leather taken; head taken; meat taken with blood in; blood gathered; blood bled out; the last part taken (the carcass comes down).
- **Tools:** no knife; a broken knife; a knife in a bag; no container; one bucket; a bucket half full of water; two containers.
- **Presses:** Hang twice; Hang on row 1 then row 2 before the first lands; each Gather twice; Remove twice; Into while bleeding on the ground; Stop mid-action and mid-bleed.
- **Changes while open:** another player (or split screen) hangs, takes a part, takes it down; the hook picked up.
- **Pad:** every stop; the opening focus with and without a carcass; A on it.
- **Layout:** Large text with the part rows; 1280x800 with the inventory; the figure scrolled half out.
- **Languages:** the part labels (the game's, with the colon cut), Taken, the corpse names.
- **MP:** In use; the last part taken by another player; two players at one hook.

### 4. What the tests check already

| Script | What it checks |
| --- | --- |
| zedqa_animals (60-127) | Stages a hook and a dead cow beside it; nothing opened or pressed |
| hfr_farm (211-212), gallery_farm_ranch (167-168) | Pictures of the Animals tab's Butcher page, not the card |
| animals_speed_sim (432-488) | Hook stubs for the Animals tab's scan |
| zedqa_deep_run (470-489) | Stages a hook for the pad map |

**Gaps:** every behavior of the card. No script opens it, hangs, gathers, bleeds, stops or removes; none checks the parts against the game's mod data, the progress band, the bridge's callbacks, the pad or any size or language.

### 5. Suspicions (to prove in the game)

Ordered by cost: wasted meat first, then wasted blood and leather, then time.

- **HK1:** Hang can be pressed again before the first carcass lands, and the game's put does not check that the hook is empty. Hang stays lit while busy is false (KC:449, 260); the put sets no doingAction, so it stays lit through the walk and the 250-tick action (PAH:96-101). ISPutAnimalOnHook only asks for a body (PAH:5-11) and refuses a ground body already on a hook (PAH:76-83), not an inventory item or a second body. Hang on row 1 then row 2, or A A on a carried carcass, queues two puts: the second calls onAddedCorpse, which makes a new hook animal and sets it on the hook (KC:78-85; BU:531-583). Prove what happens to the first carcass (lost, orphaned or duplicated). The game disables Add corpse while any cancelable action runs (BHU:31-35).
- **HK2:** While the game bleeds the carcass onto the ground, the card's progress and blood stay frozen. The game's window pulls getRemovingBloodProgress and rereads the parts every frame while isRemovingBlood (BHU:180-184); the card rereads only when the hook's animal changes (KC:248-252) and draws br.progressBar, which nothing updates during a ground bleed (KC:381; only the actions call updateProgressBar). The band sits at 0% and the Blood row and the spill warning keep the starting liters until the game's onStopBleedingAnimal (BHU:644-649). Prove: Bleed with no bucket, watch the band and the Blood row.
- **HK3:** A bridge can be left without the game's callbacks and the card stays busy. Only one luaHook per hook (KC:121, 244); a card closing clears it (KC:314-315) even when another card (split screen) is open on the same hook, and OC.browse makes a new bridge without clearing the old hook's (OC:309-317; KC:241-245). A bridge that misses onStopBleedingAnimal keeps doingAction true (KC:72-73), so busy stays true (KC:260): every Gather, Into and Remove stays grayed until the card is reopened. Prove in split screen: both on one hook, bleed, close one.
- **HK4:** On a pad the card opens on Remove corpse. With a carcass and a knife the only verb is Remove (KC:275-286), so the opening focus and every D-pad move into the card land on it (OC:1217-1226, 1408-1414), and A takes the carcass down with no question (KC:283). The game's pad starts on the part buttons with Remove on X (BHU:72-78). The carcass can be hung again, but it costs the walk, the 250-tick put and the carcass on the ground meanwhile. Prove: the Animals tab's hook row, A, A.
- **HK5:** Meat and Head stay one press while blood is still in; the game spills it onto the ground (RMA:105-110, 125). The card warns (KC:506-510) but asks nothing; with HK2 the warning's liters are stale during a bleed. The game's window is as silent. Prove the liters lost.
- **HK6:** A part the animal never had reads "Taken" with a lit Gather. The game stores leather and parts as booleans, false when the breed has none (BU:19, 35); the card lights Gather on `~= nil` (KC:480, 498) and reads Taken for false (KC:479, 497). Gather then walks, equips the knife and fails the action's check (RLA:16). The game shows No and no button (BHU:113-119, 263). Prove on a calf and a fawn.
- **HK7:** Add corpse is lit when every corpse in reach is invalid and jumps to hook:hang:1 even when that row cannot hang (KC:289, 447-450); the empty-list lines show only with no corpses (KC:452-459).
- **HK8:** A ground corpse with no custom name: txt with a nil argument reads the key bare (KC:30-39, 185); prove the row's name ("Dead %1" or the bare key). The game passes nil too (BHU:470-474).
- **HK9:** Small screens and Large text: the value column is a fixed 84 units from the row's start (KC:416-418), so a longer part label (the game's words, other languages) or Large text runs into it; the Gather button is at least 58 units (KC:420). The card is 480 units at 1280x800 (FA10).
- **HK10:** MP: the using player is set only on the server during an action (RMA:68-77), so In use shows only mid-action; when another player takes the last part, the client's updateCorpseDatas takes the carcass down locally through the bridge (BU:673-677; KC:87-95). Prove the card and the hook on both clients.
- **HK11:** Words: the card's blood reads "%.2f L" (KC:44), the Animals tab's row "%.1f" (AT:2004) for the same carcass; "Taken" for a part never there (HK6).
- **HK12:** No tests: section 4. FEATURE_MAP:369 "not yet".
