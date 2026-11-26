# Power, Fluid and Fire cards: map for the gamut sweep (QA, Nov 26 2026)

A read-only map of three of ZeD's object cards against the game's own windows and actions (B42: the generator's Info window and its timed actions, the Fluid system's Transfer and Info panels with their transfer and empty actions, the camping and barbecue menus with their fire actions), written before the sweep scripts. It also maps the surfaces that reach the cards or share their code (the face pop-outs, the D-pad Lights wheel, the Loot window's fire buttons) only as far as the cards reach them. Line refs are as read on Nov 26. Nothing was run.

**The three cards live in the World window's card drawer, always at the full card.** Each is a kind registered with the shared host (OC.register, OC:79): `generator` (OCP:344, 704), `fluid` (OFL:181, 810), `fire` (OCF:69, 598). OC.open resolves the target and hands it to ZeD_WorldWindow.openObjectCard (OC:152-159, WW:6576-6599), which opens the window if needed and lays the card over the tab or the Loot view. None of the three is marked half, so the drawer is the full card (480) whatever the screen (WW:2224-2228, 2286-2288). Every frame OC.tick checks the target, the leash (6 tiles, 6.5 with slack; held while an action the card started runs), a vehicle and death, refreshes the data every 250 ms and rescans the nearby list every second (OC:252-306). The verbs row, the folded "With ... you could ..." row, the question band and the pad stops are the host's (OC:938-960, 1205-1281, 1512-1534, 1677-1711).

Short names: OCP ObjectCardPower.lua, OFL ObjectCardFluid.lua, OCF ObjectCardFire.lua, OC ObjectCards.lua, IC Overrides/InfoCards.lua, OFH Overrides/Fluids.lua, FP FacePop.lua, CCt ContainerControls.lua, DW ZeD_DpadWheels.lua, WW ZeD_WorldWindow.lua, MO Molecules.lua (ZeD.Disclose), TRO ObjectCardTrough.lua, QW ZeD_QuickWheel.lua, ICd ItemCard.lua, ZUI shared/Translate/EN/UI.json (ZeD's words).
The game's files (media/lua unless noted): WOCM client/ISUI/ISWorldObjectContextMenu.lua, JML zombie/iso/ISWorldObjectContextMenuLogic.class in projectzomboid.jar (the B42 world menu is Java; read only as its string table, so its order is a hint, not proof), GIW client/ISUI/ISGeneratorInfoWindow.lua, AG shared/TimedActions/ISActivateGenerator.lua, PG .../ISPlugGenerator.lua, FG .../ISFixGenerator.lua, AF .../ISAddFuel.lua, TG .../ISTakeGenerator.lua, FTUI client/Fluids/ISFluidTransferUI.lua, FIUI client/Fluids/ISFluidInfoUI.lua, FCP client/Fluids/ISFluidContainerPanel.lua, FPA client/Fluids/ISFluidPanelAction.lua, FU shared/Fluids/ISFluidUtil.lua, FC shared/Fluids/ISFluidContainer.lua, FTA shared/Fluids/ISFluidTransferAction.lua, FEA shared/Fluids/ISFluidEmptyAction.lua, FCM client/ISUI/ISFluidContainerMenu.lua, RBS server/RainBarrel/SRainBarrelSystem.lua, FLT media/scripts/generated/fluids.txt, FJ shared/Translate/EN/Fluids.json, CM shared/Camping/ISCampingMenu.lua, CF server/Camping/camping_fuel.lua, SCS server/Camping/SCampfireSystem.lua, RCA shared/Camping/TimedActions/ISRemoveCampfireAction.lua, BBQ client/ISUI/ISBBQMenu.lua, BIT shared/TimedActions/ISBBQInsertPropaneTank.lua, IPCM client/ISUI/ISInventoryPaneContextMenu.lua, BTA shared/TimedActions/ISBaseTimedAction.lua.
FEATURE_MAP rows 360 and 361 cite old InfoCards lines (39-41 and 45-55; the hooks are IC:62-64 and 67-78); row 362 cites grillFace 503 and popOut 570 (now OCF:522 and 589), says the burner knob turns with the D-pad (its zone has no knob, OCF:548-550) and says "not here" although zedqa_plates_fill and ck_tab K14 run the grill; row 366's InfoCards:59-62 is now IC:81-85. Row 364 (fluid hooks OFH:40, 49, 58, 68, 74) and row 406 (IC:24, 33, 46, 60) are right. FP's header still says Generator info and the grill's info pop the face out (FP:26-28); IC opens the card (IC:25-26), and face_popouts_sim:458 checks the card.

---

## Power card (ObjectCardPower.lua)

### 1. What the card does

**Getting there:**
- The game's Generator > Info: ISWorldObjectContextMenu.onInfoGenerator is swapped so the card opens at once, with no walk (IC:33-43, 62-63); the game's own handler walks adjacent first (WOCM:533-538). ISGeneratorInfoAction's perform is the fallback for any other caller (IC:46-58, 64).
- The face pop-out (Immersive devices only, FP.on FP:68-76): a left click on the generator within 3 tiles on his floor (FP:317-331), A on a pad at it (the Interact prompt, FP:349-373), the face clicked away from its controls or the header's expand button (OC:200-204, 1121-1132). The pop-out draws the face alone and runs its two controls as the card would (FP:126-150, 165-172).
- The D-pad Lights wheel's Generator slice turns the first generator of def.nearby on or off with the game's handler, without the card (DW:1645-1663).
- Safe mode: every hook hands back to the game (IC:38, 51).

**Data (def.refresh OCP:369-439, every 250 ms):** fuel (getFuel) and max (getMaxFuel, else 10), percent, condition, on, connected; base and total draw and their strings; what it powers (getItemsPowered, "Fridge (0.0800 L/h)" split into name and value, OCP:313-319, 384-390); indoors (not outside and in a building, as the game's toxic line, OCP:392, GIW:49, 67); its item type, name and icon; petrol cans in the bags while it is off and under 100% (OCP:321-342, 397); Electricity 3 or the Generator recipe known (OCP:304-306); Scrap Electronics in the bags (OCP:399).

**The view (def.body OCP:642-702):**
- A red warning box when indoors: "Indoors. Running it here fills the building with toxic fumes. Move it outside first." (OCP:648-650, ZUI:2320).
- The face: one of four pixel plates by the generator's item (red 1988 portable, yellow contractor's, blue compact, the 1960s military set; a modded set borrows one), its engine switch and lamp, fuel gauge, the cord in the outlet, an OIL lamp under 25% condition (ZeD's own threshold), 120 V and 60 Hz meters while it runs, a load needle or OVERLOAD lamp (OCP:289-297, 484-538). Under it, "Run time left" (fuel over total draw, hours, days past 100 h, OCP:465-482) and "Fuel x.x of N L" (OCP:558-561).
- Condition with bar; at 50% or less "| may fail to start" in the warning color (OCP:659-662, ZUI:2322).
- Running: "Powering (n)", one row per powered thing, the generator's own idle draw and the total (OCP:664-679). Off with cans: "Add fuel from your bags", one row per can with its fill, where it is, "+x.x L" and Add (OCP:680-699).
- The header: name, icon, the tag Running or Off, the browse arrows when more generators are within 6 tiles, the pop-out button (OCP:441-451, OC:1079-1173).

**Verbs (OCP:402-438), each through the game's handler:**
- Turn on / Turn off: onActivateGenerator (WOCM:547-552), walks adjacent, ISActivateGenerator (30 ticks). Lit while on or connected with fuel (OCP:405). The game's action refuses unconnected, no fuel or condition 0 (AG:5-13), and at 50% or less a start fails half the time (AG:42-43).
- Add fuel: a jump to the first can's row (gen:can:1); the row's Add runs doAddFuelGenerator with that can (OCP:686-697, WOCM:648-662: walk, equip, ISAddFuel; the pour is min(can, room), AF:47-61).
- Fix: onFixGenerator (WOCM:554-563); off, under 100%, the skill, Scrap Electronics (OCP:413). The game's action chains itself until 100% or the scrap runs out (FG:36-49, 73-75).
- Connect / Disconnect: onPlugGenerator (WOCM:540-545); off and the skill, both ways (OCP:414, 429-433).
- Take: onTakeGenerator (WOCM:665-677: no vehicle, walk, both hands emptied, ISTakeGenerator); off and disconnected (OCP:415).
- The main verb: Turn off while on; Add fuel when empty with a can; Turn on when it can; Connect when it can (OCP:416).
- Every verb that can't run waits on "the generator turned off" first, then its own need (OCP:417-437, ZUI:4013-4019).

**Settings:** hidden actions (folded, all, hide: MO:5279-5292); Devices row (Immersive draws the face; Simple and Lite draw the plain card); UI scale and text size pick the face's width (OCP:548-554); the sandbox fuel factor scales the load needle (OCP:502-506).

**Lite:** ZeD.Settings.devicesSimple is ZeD.Settings.lite (Settings.lua:686-688), so Lite draws the plain card (OCP:587-640): the run time and fuel in large type over a fuel bar, the engine switch and the outlet as rows (the same fids and runs), then the readings this model's face shows. No pop-out in Lite (FP:68-76, OCP:443).

**Pad (focus zone worldItemCard):**
- Header: oc:back, oc:prev, oc:next, oc:pop (OC:1088-1151).
- Verbs: oc:verb:fuel, oc:verb:power, oc:verb:fix, oc:verb:plug, oc:verb:take; oc:more and oc:hv:<id> when folded (OC:1234-1275).
- Body: gen:engine, gen:outlet (the face's or the plain card's), gen:can:<i>; oc:face is not a stop (OC:200-204).
- The card opens on its main verb, else the first lit one (OC:1216-1226, 1408-1414). B closes the card (OC:1693-1695).

**Small screens:** always the full card (480 units) beside the inventory, even where a tab would get the half card (WW:2265-2291). The face picks a narrower plate when the main one does not fit at a whole zoom (OCP:548-554). The powered rows cut names with "..." (OC:507).

**Related surfaces:** the face pop-out (FacePop, TwoWayFull: the face alone, no warning box); the Lights wheel's Generator slice (DW:1653-1663); the plain card's parts (OCP:42-287), shared by the fire and laundry cards.

### 2. Against the game (steps)

| Job | Game | ZeD Power card |
| --- | --- | --- |
| Read fuel and condition | Right-click (1), Generator (1), Info (1), the walk | Right-click (1), Generator (1), Info (1), no walk; or a click on it within 3 tiles (the face, no condition) |
| Turn it on | Right-click (1), Generator (1), Turn on (1); the tooltip carries the toxic line (GIW:45-52) | The card's Turn on (1) or the engine switch (1); the pop-out's switch (2 from the world); the Lights wheel (2) |
| Connect it | Right-click, Generator, Connect (3) | Connect or the outlet (1) |
| Add one can | Right-click, Generator, Add fuel, the can (4) | The can's Add (1) |
| Add every can | Right-click, Generator, Add fuel, Add all (4) (WOCM:617-620) | One Add per can |
| Fix it | Right-click, Generator, Fix (3) | Fix (1) |
| Take it | Right-click, Generator, Take (3) | Take (1), only after Disconnect, which needs the skill here (PW3) |
| Know the run time left | None (percent only, GIW:54-56) | Under the face |

ZeD has, the game doesn't: run time left in hours, fuel in liters, the load and overload, an OIL lamp, the powered list in the card with no hover, an indoors warning box above everything, the face and its switches, a run-time readout in Lite.

The game has, ZeD doesn't: Add all cans; Disconnect without the skill (PW3); the percent; Info's walk (the card opens wherever the click came from, PW9); neither shows the power range (the sandbox tile and vertical range).

### 3. States to sweep

- **Generators:** each of the four plates (the red, yellow, blue and military sets) and a modded one; indoors (in a garage, in a house), outdoors, on a roof, on a second floor.
- **Fuel:** 0, 0.1 L, half, full; a can with petrol and water mixed; two cans of one type, three types; a can in a backpack, in a bag in a bag.
- **Condition:** 100, 51, 50, 25, 24, 1, 0; a failed start at 50 (no word expected); running down to 0.
- **Power:** connected and off, on with nothing powered, a fridge, a whole house, two houses (overload); the grid on in the same building; the sandbox fuel factor at 0.5, 1, 2.
- **Skill:** Electricity 0, 2, 3; the Generator magazine read; the Electrician profession; Fix with 1 scrap and with 10 (to 100%).
- **Presses:** each verb twice (mouse, pad A A), during the walk and during the action; Turn on at 50% three times; Take with both hands full; Take while seated.
- **Reach:** Info from 2, 7 and 15 tiles; the card open while he walks off; a click on the generator from 4 tiles (no pop-out); the pad's A at it.
- **Changes while open:** another player turns it off, takes it, adds fuel; it runs dry; the grid comes back; a second generator set down within 6 tiles (browse).
- **Pad:** every stop; the pop-out from A; B in the card and in the pop-out.
- **Layout:** 1280x720 and 1280x800 at UI scale 1 and 2 with Large text, the inventory open and shut; 4K; a long modded name.
- **Settings:** hidden actions folded, all, hide; Immersive, Simple, Lite.
- **Languages:** EN, DE, ES, FR, RU, JP: the powered names (the game's), the needs lines, the warning box.
- **MP:** two players at one generator; the server's fuel and condition against the card's.

### 4. What the tests check already

| Script | What it checks |
| --- | --- |
| rt_cards (963-994) | The game's Info opens the generator card on it; full card; fuel and condition read as the game's; Off |
| rt_cards (997-1061) | Connected and fueled, gen:engine starts it and stops it; with fuel 0 the switch refuses |
| rt_cards (1382-1526) | The generator beside the oven run for the oven's power, stopped after |
| bx_world (409-594) | Info opens the card; reads off and not connected and the game's fuel; no Turn on unconnected; Connect on the card (or skipped without the skill); the switch on; windows closed and reopened while it runs; five presses in one frame; runs dry; out of fuel no Turn on; Add on a can's row pours; the generator removed with its card open closes it; the Lights wheel's slice read beside each step |
| zedqa_plates_fill, zedqa_plates_336, zedqa_two_widths (343-352) | The plates fill the card at the widths; the face's fids |
| face_popouts_sim (458 and around) | Source checks: Info opens the card, not the pop-out; the pop-out's drivers |
| gallery_t14_indoor (397-423), zedqa_deep_run (357-368), zedqa_b17_scroll | Pictures and a stocked generator for the deep run |

**Gaps:**
- Fix, Take and Disconnect never pressed; Fix's chain and its scrap use never counted.
- Turn on at condition 0 and at 50% (the failure roll); the card's words at 0.
- The indoors box against the game's toxic rule; the pop-out and the Lights wheel indoors (PW1, PW2).
- Run time left against the clock; the load needle against the draw.
- Two generators in reach: the wheel's pick, the browse arrows.
- Info from far off; the card in a vehicle.
- Skill paths: the magazine, Electrician, Electricity 2.
- Simple and Lite plain cards pressed (only drawn in gallery runs); hidden actions all and hide.
- Languages other than EN; MP.

### 5. Suspicions (to prove in the game)

Ordered by what they can cost: a dead character, then a lost generator, then fuel and parts, then time.

- **PW1:** The face pop-out and the Lights wheel start a generator indoors with no word about fumes. The warning box is drawn only in the card's body (OCP:648-650; grep finds UI_ZeD_Power_Fumes nowhere else). The pop-out draws ZeD.ObjectCardPower.face alone, the plate and its live engine switch (FP:126-141, 165-172; OCP:515-538), and opens from a plain left click on the machine within 3 tiles or the pad's A at it (FP:317-331, 349-373). The Lights wheel's Generator slice runs onActivateGenerator with only "Turn on" as its detail (DW:1653-1663). The game's own Turn on carried getRichText with the toxic line in B41 (GIW:45-52); JML lists getRichText inside the generator menu. Prove: a generator in a garage, Turn on from the pop-out and from the wheel; what the player is told.
- **PW2:** The Lights wheel turns on or off the first generator in reading order, not the nearest. It takes gl[1] of def.nearby (DW:1653-1655), and def.nearby sorts by row then column over a 13 by 13 square (OCP:357-367, OC:112-131). With one generator outside and one in the garage within 6 tiles, the slice can start the indoor one or stop the one powering the fridge. Prove with two generators, the character beside the southern one.
- **PW3:** Disconnect needs Electricity 3 or the magazine on the card, and Take needs it disconnected, so a character without the skill can't pick up a connected generator from the card. plugOK is "off and the skill" for both ways (OCP:414, 429-433; NEEDS "Electricity 3", ZUI:4016) and takeOK wants it disconnected (OCP:415). The game's action has no skill check (PG:5-8); in JML's string table ContextMenu_GeneratorPlugTT follows only ContextMenu_GeneratorPlug, none follows ContextMenu_GeneratorUnplug (B41's Lua gated only Connect and Fix the same way). Prove the game's menu offers Disconnect at Electricity 0 and the card does not.
- **PW4:** A broken generator reads as one that may start. At condition 0 the game's action refuses (AG:7-10), but the card lights Turn on (onOK has no condition check, OCP:405), makes it the main verb (OCP:416) and reads "0% | may fail to start" (OCP:661, ZUI:2322); a press walks there and nothing happens, with no word. The wheel already refuses at 0 (DW:1656). A failed start at 50% or less (AG:42-43) also leaves the card on Off with no word.
- **PW5:** Fix spends every Scrap Electronics in the bags. ISFixGenerator queues itself again after each piece until 100% or none is left (FG:36-49, 73-75), each piece +4 plus half the Electricity level (FG:70). The card's help says "Fix: repair it with scrap electronics" (ZUI:4001) and the row shows no count or result. The NEEDS word "Electricity 3" (ZUI:4016) leaves out the magazine and the profession the game's tooltip names (ContextMenu_GeneratorPlugTT). Prove: Fix at 60% with 10 scrap at Electricity 3; count what is left.
- **PW6:** The generator changing while the card is open. The data is re-read every 250 ms (OC:63, 290-295); a press in that time acts on the last read (toggle reads isActivated live, OCP:406-408, so a second press during the walk queues the opposite action only after the first lands). Another player's Take, Turn off or Add fuel must redraw within 250 ms; a generator taken closes the card (bx_world checks one removal). In MP the card reads the client's copy; prove fuel and condition against the server after a long run.
- **PW7:** Add fuel goes one can at a time. There is no Add all (the game's WOCM:617-620); each row's press is its own walk, equip and pour (OCP:695-697, WOCM:654-661). Cans show only while it is off and under 100% (OCP:397, 412), as the game. A can with water and petrol counts all its liquid as fuel (OCP:326, AF:54), as the game. Prove the second can's Add while the first pours.
- **PW8:** Readings to prove. Run time is fuel over getTotalPowerUsing, said to carry the sandbox factor (OCP:462-482); the game's string is "#.#### L/h" (IsoGenerator strings), but the burn per game hour is not proven. The load needle divides the draw above idle by the factor again (OCP:502-506). The OIL lamp at 25% (OCP:289, 498) and the 120 V / 60 Hz meters (OCP:499-500) are ZeD's, not the game's condition bands (IsoGenerator: GeneratorLowCondition, Warning, Critical, Minimum). Condition's color turns at 50 (OCP:659), the same as the failure rule.
- **PW9:** Reach. Info from more than 6.5 tiles opens the card and closes it on its first frame (OC:285-288): the game would walk there (WOCM:535-536); ZeD shows nothing and the game's window never runs (IC:40). Seated, every card closes (OC:272).
- **PW10:** Words and docs. "+%.1f L" and the "%.4f L/h" fallback are built in code (OCP:673, 690). The FP header and FEATURE_MAP rows 360, 362 are stale (see the top).

---

## Fluid card (ObjectCardFluid.lua)

### 1. What the card does

**Getting there (OFH:36-81):**
- An item's Liquid > Show info or Transfer (ISFluidContainerMenu.showUI, OFH:55-64): the card opens on the item; the game's would first move it to the main inventory and queue ISFluidPanelAction (FCM:230-234).
- A world container's Show info or Transfer (rain collectors, barrels, troughs, anything with a FluidContainer; ISWorldObjectContextMenu.onFluidTransfer and onFluidInfo, OFH:65-79): the card opens at once with no walk; the game's walks adjacent first (WOCM:2829-2854).
- Any other caller of ISFluidTransferUI.OpenPanel or ISFluidInfoUI.OpenPanel (crafting stations' fluid slots, mods) (OFH:37-54).
- The trough card's Add water and Pour rows open it aimed (TRO:124-126).
- Not reached from a sink, a toilet or a well: their Drink, Fill (ISTakeWaterAction) and Wash stay the game's (WOCM:2033-2089); the card opens only on a FluidContainer.
- Safe mode: the game's windows (OFH:41, 50, 59, 69, 75).

**Data (def.refresh OFL:225-339, every 250 ms):**
- The two sides, From (left) and Into (right): the opened container goes left when it is the source or for Info or when it holds something, else right (OFL:194-207). A side whose item left the bags empties (OFL:227-228).
- Rows: the world container the card opened on, pinned first with its distance, then every liquid container in the bags and bags in bags that the player may empty, by name (OFL:127-140, 238-247). Each: amount, capacity, hidden or not, color, From and Into with a tag from the engine's own answer: Empty, Same, Mixes (warning), Full, Won't mix, Won't take, Too heavy (OFL:142-171, 248-279).
- The pour: can (FluidContainer.CanTransfer), Max Pour = roundTransfer(min(from amount, room in into)) (OFL:283-288), the engine's reason when refused.
- Liquids on the left, largest first, each with its share (OFL:66-78); Tainted by ZeD's reading of the game's tooltip (OFL:80-90); the poison level only in debug (OFL:294-298); "Mixture" for several (OFL:111-115).
- Pouring: the queued ISFluidTransferAction is tracked until it leaves the queue (OFL:234-235).

**The view (def.body OFL:754-808):**
- Two tanks, Pouring From and Pouring To, filled in each liquid's color, a hatched band for what leaves and what arrives and a line where each ends (OFL:390-499); the level hidden when the game hides it (OFL:488, 495).
- Between them the arrow, the liquid with its dot, the amount in large type and "Max Pour x L" (OFL:502-542).
- Amount: a slider and 1/4, 1/2, All (OFL:545-601), shown when a pour can happen; pouring, a strip "Pouring", progress, "x of y" and Stop (OFL:604-635).
- Liquids: one row each with color, name, a Tainted tag, a ten-segment bar, liters and share (OFL:638-685).
- Your containers (n): each row with icon, name, where, a gauge with "amount / capacity", the tag, From and Into (OFL:688-752).
- The header: the left side's name, the tag Tainted, the liquid or Empty (OFL:362-373).

**Verbs (OFL:306-338):**
- Pour (main): queues transferIfNeeded for each item side, walks to a world container when more than 2 tiles off (ISFluidUtil.doWalkTo, FU:22-41), then ISFluidTransferAction with the chosen amount (OFL:343-360), as the game's Transfer (FTUI:500-507).
- Switch: swaps the sides and resets the amount to All (OFL:219-223, 320-323).
- Empty (red): asks "Empty the container? x of y is lost." (ZUI:3940), then the game's empty: an item through ISFluidContainerMenu.emptyFluidContainer (FCM:225-228), a world container through onFluidEmpty (WOCM:2856-2869). Only for the left side, never a resource (OFL:324-337).
- From and Into on a row pick or swap the sides (OFL:708-718).

**Settings:** hidden actions (Pour waits with its need, or the engine's own sentence, OFL:309-318); text size and UI scale. No Devices row branch.

**Lite:** no branch in OFL.

**Pad:**
- Verbs: oc:verb:pour, oc:verb:switch, oc:verb:empty; oc:confirm:no and oc:confirm:yes (focus lands on No, OC:946).
- Body: fl:step:1..3, fl:slider (the D-pad's left and right move 5% of Max Pour, OFL:593-599), fl:stop, fl:from:<key>, fl:into:<key> (key "pin" or "i<item id>").
- The card opens on the first row that takes the pour when the right side is empty (def.openFocus OFL:376-383), else on Pour.

**Small screens:** always the full card. The two tanks are 150 units each (OFL:34-35, 781-788), the arrow gets what is left (about 140 at 480); the rows reserve two buttons, the widest tag and a 104-unit gauge (OFL:695, 720-743), so names are cut with "..." early at Large text.

**Related surfaces:** the trough card (TRO), the loot card and the item facts panel share ZeD.Fluid's L, liquidsOf, taintedShown and fluidLabel (OFL:117-119; ZeD_LootCard.lua:174, ItemFactsPanel.lua:433).

### 2. Against the game (steps)

| Job | Game | ZeD Fluid card |
| --- | --- | --- |
| Fill a bottle from a rain collector | Right-click (1), Transfer (1), the walk, drop the bottle in the right slot (1), Transfer (1) | Right-click (1), Transfer (1), Into on the bottle (1, where the pad lands), Pour (1); the walk at Pour |
| Pour half | Drag the slider | 1/2 (1) |
| Pour between two bottles | Liquid > Transfer (2), drop the second (1), Transfer (1) | Liquid > Transfer (2), Into (1), Pour (1) |
| Empty a bottle | Liquid > Empty (2), no question | The same (the item's Empty is not hooked); or in the card Empty (1), Yes (1) |
| Empty a rain collector | Right-click, Empty (2), no question | The same; or in the card Switch if needed, Empty, Yes |
| See what a container holds | Show info (2) | Show info (2): the card, with Pour and Empty too |
| Stop a pour | Move, or the action bar | Stop on the strip (only once the pour has begun, FL3) |
| Drink or fill from a sink or a well | Right-click, Drink or Fill (2-3) | The game's; the card is not reached |

ZeD has, the game doesn't: every carried container listed with what a pour into it would do, before it is picked; 1/4, 1/2, All; the after-lines on both tanks; the pour's progress in liters; a question before Empty; a real cause for the inventory-full refusal (Too heavy).

The game has, ZeD doesn't: the walk to the container before the window opens; the panel closing past 2 tiles (FTUI:271-276, FIUI:117-132; the card holds to 6); the slider back at 0 after a pour (FTUI:507); its window while seated (FL5).

### 3. States to sweep

- **Containers:** a water bottle, a pop bottle, a pot, a bucket, a gas can, a canteen worn on the belt, a bottle in a bag in a bag; a rain collector (empty, half, full), a barrel, a trough, a crafting station's fluid slot; a container whose amount the game hides.
- **Liquids:** water, tainted water (rain collector water, RBS:58), a mix of the two at 1:9 and 9:1, under and over 1 L of tainted water (FLT:33-37), bleach, petrol, a drink, a mixture of three.
- **Sandbox:** tainted water text on and off.
- **Pours:** All, 1/2, 1/4, the slider at 0.05; into a container that mixes, that won't mix, that won't take it, that is full; with the inventory over its limit (Too heavy); into a bottle in a bag; from the world container 1, 3 and 6 tiles away.
- **Presses:** Pour twice (mouse, pad A A); Stop during the item moves, the walk and the pour; Switch during the pour; Empty, Cancel, Empty, Yes; Empty after Switch with the collector on the left.
- **Changes while open:** the bottle dropped, drunk or put in a crate; another player draining the collector mid-pour; the collector picked up or destroyed; rain filling it.
- **Reach:** Transfer from 2, 7 and 15 tiles; a walk away past 6 tiles; seated in a car.
- **Pad:** every stop; the slider on the D-pad; the question.
- **Layout:** 1280x720 and 1280x800 at UI scale 1 and 2 with Large text; 4K; a long container name; ten bottles.
- **Settings:** hidden actions folded, all, hide.
- **Languages:** EN, DE, ES, FR, RU, JP: the game's liquid names, the question (lowercased liquid), the tags.
- **MP:** two players pouring from one collector.

### 4. What the tests check already

| Script | What it checks |
| --- | --- |
| zedqa_cov_objcards (870-960) | A bottle's Transfer opens the card with it on the left; Empty and Full tags; the pad lands on an Into; Into sets it; 1/2 and the slider's D-pad; Pour moves that much; Switch; Empty asks with the liters, Cancel keeps it, Yes empties |
| bx_cook (1302-1457) | Transfer on a rain collector opens the card, collector left; Pour waits with no Into; the bottle picked, sized to the bottle; half poured; a full pour stopped (Stop ends it); filled to the top, Pour off; Switch, Empty asks; the bottle taken and the collector destroyed while the card shows |
| zedqa_padmap (426-429), zedqa_two_widths (299-301) | The card's stops and its widths on a world container |
| fast_loot_sim (224-280), item_meter_sim | Source checks that the loot card shares ZeD.Fluid's rules |
| vx_windows (420-535) | Fluid pins (the belt), not the card |

**Gaps:**
- Tainted water at all: the tag, the pill and the Liquids rows against the game's isTaintedStatusKnown, with the sandbox text on and off; a mix; under 1 L.
- Stop during the walk or the item moves (bx_cook's collector is within 2 tiles, so no walk).
- Pour pressed twice; Switch mid-pour.
- Empty after Switch with the world container on the left.
- A hidden amount; a resource container; petrol into water.
- Seated in a car; Transfer from far off.
- Too heavy; Won't mix; Won't take.
- Hidden actions all and hide; languages other than EN; MP.

### 5. Suspicions (to prove in the game)

Ordered by what they can cost: health from water, then lost water, then time.

- **FL1:** Tainted is ZeD's own rule, and it can say plain "Water". taintedShown returns false whenever the container's poison effect is "None", before it looks at isTainted (OFL:83-90). TaintedWater's poison has minAmount 1.0 and diluteRatio 0.2 (FLT:33-37) and its display name is "Water" (FJ:183), so a bottle under 1 L of rain-collector water (rain collectors collect TaintedWater, RBS:58) or a weak mix may read "Water" in the header, the arrow and the Liquids rows with the sandbox text on. ZeD has three other rules: the trough's calls a mix tainted whatever the sandbox (TRO:67-77), the item card's uses isTainted with no sandbox check (ICd:152, 276), the quick wheel's uses the game's isTaintedStatusKnown (QW:77-86). Prove each surface against isTaintedStatusKnown and against drinking the bottle.
- **FL2:** Empty empties whatever is on the left, and its question doesn't say which container. The verb acts on t.from (OFL:324-337); the question names only the amount and the liquid (ZUI:3940; OFL:327). After Switch or a From press (OFL:320-323, 711-713) the left can be the rain collector or the trough (TRO:126 opens with the trough on the right; Switch puts it left). The game's Empty sits on the named object's own menu. Prove: open on a bottle and a full collector, Switch, Empty; the question's words.
- **FL3:** Stop does nothing until the pour itself begins. The strip and its Stop show as soon as the action is queued (OFL:234, 792-793), through the item moves and the walk; Stop calls act:forceStop() (OFL:626), which calls self.action:forceStop() (BTA:28-30), nil until the action starts; the error is swallowed by the pcall, the walk goes on and the pour runs. Prove: Pour from a collector 5 tiles off, Stop at once; then Pour into a container tagged Mixes and Stop.
- **FL4:** A second press pours again. d.pouring is read only at the next refresh (OFL:234; the press sets the refresh 3 sixtieths out, OC:958), so a double click or pad A A inside that time queues a second transfer at the last Max Pour (OFL:346). After a pour the amount stays where it was (OFL:308, 346) where the game's slider goes back to 0 (FTUI:507), so the next Pour pours the most again. Prove: Pour twice fast from a collector into a pot holding bleach.
- **FL5:** Seated, the item's Liquid > Transfer and Show info open nothing. The hook hands the call to the card (OFH:58-62), openObjectCard says yes (WW:6576-6599), then the card closes on its first frame in a vehicle (OC:272; the fluid kind has no vehicleOk) and the game's window never runs. Prove from a passenger seat with two bottles.
- **FL6:** Hidden amounts leak. The tanks hide the level (OFL:488), but the rows' gauges (OFL:255, 736-737), the Liquids bars and shares (OFL:659-668), the arrow's amount and Max Pour (OFL:286, 525-539) show it; the game's panel writes Unknown for stored, capacity and free (FCP:171-187). Prove which containers hide their amount.
- **FL7:** Reach. Transfer or Info on a world container opens the card with no walk (OFH:68-78); from more than 6.5 tiles it closes on its first frame (OC:285-288) and nothing else happens. The game walks first (WOCM:2829-2854) and closes its panel past 2 tiles (FTUI:271-276); the card holds to 6 (OC:57) and walks only at Pour.
- **FL8:** Pour moves bag items into the main inventory and leaves them there (OFL:348-351, transferIfNeeded), where the game moves the item once, when its window opens (FCM:232). Too heavy is ZeD's reading of the engine's last reason (OFL:159-171); prove it against a real full inventory and a near-full one.
- **FL9:** Changes while open. The progress "x of y" is the planned amount times the action's delta (OFL:615-618), not what moved: a collector drained by another player mid-pour reads the plan. Max Pour and the tags are up to 250 ms old (OC:63). A side's item put in a crate empties that side (OFL:227-228); prove the card does not keep a stale tank.
- **FL10:** Words. The question lowercases the liquid's name (OFL:327): German nouns lose their capitals. "L", "1/4" and "1/2" are written in code (OFL:41-46, 535, 553). All 110 UI_ZeD keys of the three cards are present in DE, FR, RU, JP, ES and PTBR; the few that match EN are numbers or "Tank".

---

## Fire card (ObjectCardFire.lua)

### 1. What the card does

**Getting there:**
- The game's fuel line on a campfire's menu (ISCampingMenu.onDisplayInfo, shown within 2 tiles, CM:385-391) and on a barbecue's or fireplace's (ISBBQMenu.onDisplayInfo, BBQ:40-54): the card opens at once, no walk (IC:67-78); the game's walks adjacent (CM:431-442, BBQ:86-98). The info actions' perform is the fallback (IC:71, 78).
- The Loot window's fire buttons: Light and Add fuel open the card and jump to its first Light or Add row (CCt:122-125, 549-561).
- The D-pad Lights wheel's fire slice: Put out on the first fire of def.nearby when lit, else opens its card (DW:1665-1683).
- The propane grill's face pop-out: a left click on it within 3 tiles, the pad's A at it, the header button (FP:173-176, 229-236).
- Safe mode: the game's windows.

**Data (def.refresh OCF:227-307; the propane grill OCF:182-212):**
- Fuel in minutes (a campfire's Lua fuelAmt after updateFromIsoObject, else getFuelAmount), lit, smoldering (not for campfires), the sandbox maximum (getCampingFuelMax, else MaximumFireFuelHours times 60), name, icon, its container (OCF:229-247).
- What burns: the game's getNearbyFuelInfo (every container in the inventory and the loot window, CM:92-151, IPCM:2425-2443), cached 1.5 s or until his square changes (OCF:217-225). Fuel rows by burn time, longest first, with count, where, whether one fits and how many fit (OCF:119-148).
- Light rows: petrol plus the first starter (fuel in, a lighter or matches), each tinder plus the first starter, the notched plank with a stick or branch (needs fuel and endurance) (OCF:151-180).
- Propane: lit, tank in, gas, minutes, a spare tank in the bags or on the floor around it (ISBBQMenu.FindPropaneTank, BBQ:100-121).

**The view:**
- Fire: the time left in large type, "of fuel | holds N h", one strip to the maximum (amber lit, half amber smoldering, muted out), Now, three hour marks, Full (OCF:329-364).
- Light with (unlit): one row per method with its gain and the starter or what it needs (OCF:373-387).
- Add fuel from your bags: All fuel (N) when more than one piece and the whole lot fits, then each type's Add and, for several, All or All that fit (OCF:389-428).
- On the fire (n): the item card's cooking reading per item (OC:622-682), on = lit (OCF:430-435). The Cooking sweep checked these minutes as K12 (2026-11-25_map_cooking.md:213); not redone here.
- Propane: the Jorge Foreguy grill's face (burner knob, flames under the hood, lid thermometer that creeps over 4 s, tank gauge, the tank in the cart) or its plain card, then "Gas left" and Tank In or None, then On the grill (OCF:440-585). The tank gauge (fuel over 1200 minutes) is the Cooking sweep's K14 (2026-11-25_map_cooking.md:215-217; ck_tab 2195-2210); not redone here.
- The tag: Burning, Smoldering (the game's IGUI_Fireplace_Smouldering), Out; propane Burning, No tank, Off (OCF:312-324).

**Verbs, each through the game's handler:**
- Add fuel: a jump to fire:fuel:1; a row's Add is ISCampingMenu.onAddFuel with the type (the first valid item of that type in reach, moved to the inventory, the walk to the fire, ISAddFuelAction or ISBBQAddFuel, CM:509-525); All and All that fit are onAddMultipleFuel with the count that fits (OCF:258-261, CM:528-571); All fuel is onAddAllFuel (OCF:262-265, CM:553-561). Gone when full (OCF:281, 289).
- Light: a jump to fire:light:1; a row's Light is onLightFromPetrol, onLightFromLiterature or onLightFromKindle with the campfire's or the barbecue's action (OCF:266-278, CM:585-625).
- Put out: onPutOutCampfire (CM:573-577) or ISBBQMenu.onExtinguish (BBQ:124-129); only while lit (OCF:292-297).
- Take apart (campfire, red, asks "Take the campfire apart? The fire is lost.", ZUI:3927): onRemoveCampfire (CM:579-583; 3 stones, what is on it to the ground, RCA:39-46, SCS:79-85).
- Propane: Turn on or off (ISBBQMenu.onToggle, BBQ:152-157), Insert tank (only when none is in), Remove tank (OCF:194-211); the face's burner, igniter and tank keys ask the grill for gas when pressed (OCF:456-468).
- The main verb: Light when it can, else Add fuel; propane Turn on with gas, else Insert tank (OCF:197-201, 289-300).

**Settings:** hidden actions; Devices row (the grill's face or plain card; the fires have no face); the sandbox maximum fire fuel; the Cooking tab's reading for the rows.

**Lite:** the plain grill card (OCF:485-515), no pop-out (OCF:589). The campfire, charcoal barbecue and fireplace have no Lite branch.

**Pad:**
- Verbs: oc:verb:fuel, oc:verb:out, oc:verb:light, oc:verb:take; propane oc:verb:power, oc:verb:insert, oc:verb:remove; oc:more, oc:hv:<id>; oc:confirm:no, oc:confirm:yes.
- Body: fire:light:<i>, fire:fuelall, fire:fuel:<i>, fire:fuelmany:<i>; propane bbq:burner, bbq:ignite, bbq:tank.
- A on Light or Add fuel moves focus to the list (OC:949-953); a second A runs its first row.

**Small screens:** always the full card. The pick rows fit icon, name, where, tag, gain and button in one line (OC:520-558); long tinder names and "Nearby" cut the name first. The grill's face picks a narrow plate when needed (OCF:566-571).

**Related surfaces:** the Loot window's fire buttons (CCt); the Lights wheel (DW); the propane face pop-out (FP); the cook rows (OC.cookRows, the Cooking sweep's).

### 2. Against the game (steps)

| Job | Game | ZeD Fire card |
| --- | --- | --- |
| Read fuel left | Right-click (1), the fire (1), the fuel line within 2 tiles | Right-click (1), the fire (1), the fuel line (1): the card; or the Loot window's buttons |
| Add one piece | Right-click, the fire, Add fuel, the item (4) | The row's Add (1) |
| Add all of a type | Right-click, the fire, Add fuel, the item (N), All (5) | The row's All (1) |
| Add everything in reach | Right-click, the fire, Add fuel, All (N) (4) | All fuel (1), at the top of the list |
| Light with paper | Right-click, the fire, Light, paper + matches (4) | Light (1), the row's Light (1); the starter is chosen for you |
| Put out | Right-click, the fire, Put out (3) | Put out (1); the Lights wheel (2) |
| Take the campfire apart | Right-click, the fire, Remove (3), no question | Take apart (1), Yes (1) |
| Swap an empty propane tank | Right-click, Insert tank (2): the old one drops (BIT:65-72) | Remove tank (1), then Insert tank (1): two walks |
| Light the propane grill | Right-click, Turn on (2) | The knob or the igniter (1) |

ZeD has, the game doesn't: fuel as a strip with hour marks; each piece's burn time and where it lies in one list; how many fit; the cook rows with minutes; a question before Take apart; the grill's face with lid heat and tank gauge.

The game has, ZeD doesn't: every starter offered for each tinder (CM:282-288; the card uses the first, unsorted); its lists sorted by name (CM:195, 251, 275); the swap of a propane tank in one step; the corpse onto the campfire (CM:393-411).

### 3. States to sweep

- **Fires:** a campfire outdoors and indoors on wood, carpet and tile floors; a charcoal barbecue; a fireplace; a propane grill with no tank, an empty tank, a half and a full one, a spare in the bags and on the floor beside it.
- **Fuel:** 0, 1 minute, half, the maximum less one log, full; the sandbox maximum at 4 h and 24 h.
- **States:** out, lit, smoldering (barbecue, fireplace), rain on a campfire.
- **What burns in reach:** planks, logs, paper, a newspaper, a skill book, a recipe magazine, a paper map, cotton and leather clothing, a favorite book, an equipped shirt, a full bag; in the bags, on the floor, in a crate, on a bookshelf, in the fire's own container.
- **Lighting:** matches only, a lighter only, both; petrol can with and without fuel in the fire; a notched plank with a stick, with a branch, with no endurance.
- **Presses:** each Add and Light twice; All fuel with a skill book in the crate; Light pad A A; Put out twice; Take apart on a lit fire with a steak on it.
- **Changes while open:** a log picked up by another player between the scan and the press; the fire burning out; a second fire lit within 6 tiles (browse); the campfire removed; rain.
- **Reach:** Info from 2, 7 and 15 tiles; seated in a car; the wheel with two fires in reach.
- **Pad:** every stop; the jumps; the question.
- **Layout:** 1280x720 and 1280x800 at UI scale 1 and 2 with Large text; 4K; twenty kinds of fuel.
- **Settings:** hidden actions folded, all, hide; Immersive, Simple, Lite (the grill).
- **Languages:** EN, DE, ES, FR, RU, JP: the game's item names, "+%1 H", the question.
- **MP:** two players feeding one campfire; the server's fuel against the card's.

### 4. What the tests check already

| Script | What it checks |
| --- | --- |
| rt_cards (1064-1190) | The campfire's Info opens the fire card; new reads no fuel, not lit, Out; fire:fuel:1 adds fuel time; fire:light:1 lights it, the tag reads burning; the flame logs no error; Put out puts it out |
| bx_fire (1185-1489) | Info opens the card; no Put out on a dead fire and pressing it queues nothing; Light only with something to light; as many fuel kinds as the game finds; Add three times in one frame stays under the maximum; Add with the tab switched; full: no Add fuel, every row full; Light with paper; Add on a lit fire with the windows shut; the leash at 10 tiles; Put out twice; Take apart asks, Cancel keeps, Yes takes it, the card closes |
| bx_fire (1490-1688) | A world fire: no card for a plain flame, no browse entry |
| bx_cook (1458-1553) | A campfire's card; Light's rule; Add fuel stopped at once; lit behind the card's back; the card's fuel is the fire's own; a steak cooks on it; removed while open, the card closes |
| zedqa_cov_objcards (966-1080) | Info opens it; Out; Light waits; carried planks and paper become rows; Light is the main verb with a lighter; Add fuel jumps to its list; a plank adds its burn time; paper lights it; Put out; Take apart asks, Cancel, Yes |
| vx_world (1253-1360) | W34: the fuel scan about every 1.5 s, rescanned on a step, a new log listed within 2 s |
| zedqa_container_controls | The Loot window's fire buttons open the card on its list |
| ck_tab (2195-2210), cook_minutes_sim | K14 the propane gauge, K12 the cook minutes (the Cooking sweep) |
| zedqa_plates_fill (394-399), zedqa_plates_336 | The grill's face fills the card; its tank key puts a tank in |
| face_popouts_sim | Source checks of the grill's pop-out driver |

**Gaps:**
- The charcoal barbecue and the fireplace: never opened by the game's way, no verb pressed.
- Petrol lighting, the notched plank, the starter chosen.
- All fuel and All that fit pressed; what they take from crates and shelves (FI2).
- An indoor campfire (FI1).
- Propane: Turn on and off from the verbs, Insert with an empty tank in, Remove, the igniter; Lite's plain grill.
- Smoldering states; rain.
- Two fires in reach: the wheel's pick, the browse arrows.
- Info from far off; seated.
- Hidden actions all and hide; languages other than EN; MP.

### 5. Suspicions (to prove in the game)

Ordered by what they can cost: a house fire, then lost things (books, maps, clothes, food), then fuel, then time.

- **FI1:** An indoor campfire can set the house on fire and the card says nothing. A lit campfire indoors tries every ten game minutes, one time in five, to start a fire on an adjacent wood or carpet floor (SCS:97-125, 173-184). The card's body has no indoors line (OCF:366-437) while the generator card warns about fumes indoors (OCP:648-650); Light is its main verb (OCF:298). The game warns neither. Prove: a campfire on a wooden floor, lit from the card, an hour on fast-forward.
- **FI2:** All fuel burns everything burnable in reach, not only the bags. The list is the game's getNearbyFuelInfo over the inventory and every loot container (CM:92-151, IPCM:2425-2443), and Literature (skill books, magazines), Maps and fabric Clothing count as fuel and tinder (CF:87-91, 160-164). The card heads it "Add fuel from your bags" (OCF:390, ZUI:1017) and puts "All fuel (N)" first with the first row's icon, one press, no question (OCF:394-404); onAddAllFuel takes every valid item in every container (CM:553-561). The game's All (N) sits in a submenu with the items listed under it (CM:172-193). Only favorites and equipped items are spared (CM:30-43). Prove: a skill book on a shelf and a map in a crate beside the fire, All fuel.
- **FI3:** A pad's A then A lights with whatever heads the tinder list. Light jumps to fire:light:1 (OCF:298, OC:949-953); with fuel in and petrol carried the first row is petrol (OCF:155-158), else the tinder in container order (OCF:159-166; the game sorts by name, CM:275), which can be a skill book or the only map. Only the first starter is offered, unsorted (OCF:153-154; the game offers each, CM:282-288), so matches may go before the lighter. Prove with a skill book in the main inventory and paper in a bag.
- **FI4:** The Lights wheel puts out the first fire in reading order, not the nearest. It takes fl[1] of def.nearby (DW:1665-1672; OCF:99-112, OC:125-131). With a fireplace and the campfire cooking dinner both within 6 tiles, the slice can put out the wrong one. Prove with two lit fires.
- **FI5:** Take apart drops what is cooking on the ground. The game's removal moves the fire's items to the ground and gives 3 stones (SCS:79-85, RCA:39-46), lit or not; the question says only "The fire is lost." (ZUI:3927); the unused key UI_ZeD_Fire_ConfirmTakeApart said "You get 3 stones; what is on it drops." (ZUI:1020). Prove: a pot of stew on a lit campfire, Take apart, Yes.
- **FI6:** Propane: the card hides the one-step tank swap. Insert tank makes no sense to the card while any tank is in (sensible = not d.tank, OCF:201-202), so with an empty tank in the only verb is Remove tank, and the face's tank key removes first (OCF:456-461); the game offers Insert whenever a spare is found, and its action drops the old tank (BBQ:64-67, BIT:65-72). Its NEEDS says "a propane tank in your bags" (ZUI:3926) though the game also takes one from the floor beside the grill (BBQ:105-120).
- **FI7:** Smoldering. Put out is gone while a barbecue or fireplace smolders (OCF:292-293), as in the game (BBQ:78-83); the cook rows take "on" from lit only (OCF:434), so food on a smoldering fire reads Raw. Prove whether a smoldering fire heats and whether it relights with fuel.
- **FI8:** The fire changing while the card is open. The fuel list is up to 1.5 s old (OCF:217-225) and fits use the last refresh's fuel (OCF:141, 253): a piece taken by another player between the scan and the press makes onAddFuel take the first of that type elsewhere (a different copy, maybe from a crate) or quietly do nothing (CM:509-518). Two players adding at once can pass the maximum; prove what the game does with the surplus.
- **FI9:** Reach. Info opens the card from anywhere, with no walk (IC:67-78); past 6.5 tiles it closes on its first frame (OC:285-288). Seated, every card closes (OC:272); the game's menus also return in a vehicle (CM:356, BBQ:11).
- **FI10:** Words and docs. "+%1 H" is put in text case (OCF:358, ZUI:1045); "Light: needs a lighter or matches in your bags" shows when the fire has no fuel and no starter, though tinder alone can light it (OCF:299). FEATURE_MAP rows 361 and 362 are stale (see the top).
