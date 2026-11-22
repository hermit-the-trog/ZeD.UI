# KISS audit, batch K3 (Nov 22 2026, QA): the director's 46 design calls

The director picked every design call on the KISS report page (https://claude.ai/artifact/74SzWzsSjMZauzcuWZacSS)
between 11:25 and 11:40 on Nov 22, one by one. 41 match QA's pick; 5 differ (#11, #35, #58, #59, #60, marked below).
Each entry: the pick in the report's words (the option text, with QA's code pointers), what the player meets today,
the steps, and QA's reasoning (its pointers hold for the picked option unless the entry says the pick differs).
Behavior and look are as picked; how is Build's. QA proves each in game and pictures every visible change.

## How the picks fit together (read first)

- One rule for the container he faces: the World window shows it (#13), the pad's Y lands on its first row (#8) and
  a plain click on its picture shows it alone (#10; Ctrl-click or the pad's hold A adds a column).
- #43 (Lite on a pad takes the game's ways: Y to the crate, no pop-open, the car on D-pad Up) is mostly met by #8, #14
  and #20, which now hold in every style; #43 is whatever pad difference from the game is left after those.
- #9 and #25: the tab side starts pinned and stays until closed, and the same key or button again closes what it opened.
- #35 builds on K1-7: K1-7 already gives the line "Needs a table or counter nearby."; #35 drops the amber square.
- #58 reverses the earlier punch list 208 call (Turn on opened the stove's panel): the director's newer pick wins.
- #59 renames tabs to the game's page words (Inventory, Info, Temperature): UI.json, ZeD.tr, the tour, the guide, the
  keyboard map and every QA check that reads a tab's name follow (QA refits its checks).
- #12 changes the default text size on screens under 1080 tall: QA refits the release test's 1280x800 run.
- The four K2 items held for the picks need nothing more: #8's hint strip keeps "Y Loot" (Y now lands on the crate),
  #20's guide car pages are right again (D-pad Up seated), #29's tour Health line matches the left click on a wound and
  #44 lights the container, so the game's outline option is not grayed.
- Features new to ZeD get a FEATURE_MAP.md row (Check TODO) in the same commit, as usual.

### K3-1 (#7) Pictures without words: the right-click menu, the window tabs and Loot all
- Pick, option 1: The right-click menu opens as the word list for new players (the strip stays a choice in ZeD setup) and Loot all and Transfer all become word buttons, while the tabs keep their pictures.
- What the player meets: Every right-click opens a strip of small pictures (22 px at 1080p, about 16 on a Deck) with one name at a time in a balloon; Eat, Drink and Read sort first and the first is named at once, but to find Bandage, Unequip or Unjam he slides along reading each, past ten the strip scrolls and Lite keeps it. The word list, the game's own menu, is a row in ZeD setup that no first-launch question offers. Loot all, Transfer all and the window tabs are pictures too, named only on a hover, and a wrong guess on Transfer all drops his loose things on the floor.
- Steps now: 5 for a right-click action past the first (right-click, a hover per picture, click); 2 for Loot all the first time. Could be: 2 (right-click, click the word); 1 for Loot all.
- QA's reasoning: Option 1: the right-click menu is where a new player loses time every session and Loot all is the button every looter needs, while the strip's locked look (docs/specs/CONTEXT_MENU_SPEC.md:36-38) stays one row away and the tab pictures already name themselves at once in the help line.
- Already done either way: K2-1 (on a pad Up and Down step the strip as Left and Right do (they are no-ops at ZeD_ContextMenu.lua:978-981); the list look already takes them (ZeD_ContextList.lua:666-667)).

### K3-2 (#8) On a pad, Y lands in your own bags, not on the crate in front of you
- Pick, option 1: Near a container, Y lands the pad on that container's first row in the World window (the game's Loot), and a later Y returns to the row it left.
- What the player meets: He walks up to a crate and the hint over his belt says Y Loot, but Y opens both windows with the pad on his own first row and the World window on the Floor, so he presses Right through his bag strip to the crate's button, then A. RB, the game's way to switch containers, turns the World window from Loot to Craft instead, and after any Y to look at the world the pad comes back to his own bags, not the crate row he left.
- Steps now: 4 to 5 presses to the crate's first row (Y, Right, Right, A), at every crate. Could be: 1 (Y).
- QA's reasoning: Option 1: it changes only where Y lands, not that Y opens both windows, which the Nov 14 report kept (ZeDUI/qa/CONTROLLER_REPORT_20261114.md:75), and it makes the core job one press.

### K3-3 (#9) Open pages roll away by themselves
- Pick, option 1: The tab side starts pinned and stays until closed, while the inventory side keeps rolling like the game's.
- What the player meets: He presses H and reads his wounds with the pointer resting in the world, and two seconds later the page rolls up to its bar; it folds even with the pointer on the same window's list, and Skills, Craft and the Maps tab do the same, since both halves of both windows start unpinned. Working on the Equipment doll, the inventory side rolls away and the window narrows, so dragging a jacket means a 300 ms rest on the rod first, and a rolled bar gives its room to pins and the load until its own name reads S...
- Steps now: 2 (a 300 ms rest on the bar or the tab again, then on). Could be: 1 (the page stays until closed).
- QA's reasoning: Option 1: it keeps the director's Nov 8 rule that each half rolls and pins on its own (punch list 112, ZeDUI/PUNCH_LIST.md:3032-3040) and stops Health, Skills and Craft folding while he reads them.

### K3-4 (#10) A click on a container's picture adds a column instead of showing the container
- Pick, option 1: A plain click shows the container alone, and Ctrl-click or the pad's hold A adds it as a column.
- What the player meets: At a fridge he clicks its picture on the World window's strip, as he would the game's container button, and the window widens into two narrow columns, the fridge and the Floor, with names and weights only and no Loot all under either. The only bulk move left is a row of arrows for rows he already picked and his own Transfer all dims; after a click in the world the same picture swaps the list instead, so one click does two things.
- Steps now: 3 (click, the Floor picture to close the column, Loot all). Could be: 2 (click, Loot all).
- QA's reasoning: Option 1: it is the director's own Nov 18 picture of click opens this container, hold opens a second (ZeDUI/workshop/gallery/v1_plan/NOTE_for_Design_containers_how_20261118.md:3-8), and the pad's tap A already works that way.

### K3-5 (#11) What you wear and hold is missing from your inventory list
- Pick (the director's own answer, differs from QA's 1): "Options for 1 and 2. 1 default." Both as a choice
  in ZeD setup, option 1 the default:
  1. List worn and held things in their own group at the top of the inventory list, marked as the game marks them, where a double-click takes one off.
  2. Keep them on the Equipment tab, but the list ends with one line, Worn and held: Equipment, that opens the tab and replaces Nothing here while he wears things.
- What the player meets: He opens his inventory to take off a soaked jacket or put away the crowbar in his hand, and nothing he wears or holds is there; with nothing else on him the list says Nothing here while he stands fully dressed, and no line says the clothes live on the Equipment tab. There he clicks the jacket's row and then Unequip on its card, while a click on the belt's hand holding the crowbar does nothing, though the pad's A on it puts it away.
- Steps now: 4 (I, the Equipment tab, the row, Unequip). Could be: 2 (I, double-click the jacket), as in the game.
- QA's reasoning: Option 1: it puts back the game's one-place inventory and its double-click, the biggest single cut here (4 steps to 2).
- Already done either way: K2-2 (a click on a belt hand puts its item away, as the pad's A already does (ZeD_Belt.lua:2389-2413, 2611-2617)).

### K3-6 (#12) Text starts small, smallest on a Steam Deck
- Pick, option 1: Large text by default on screens under 1080 tall (the Deck, 720p), Small above.
- What the player meets: With the default Small text, body text is 13 px at 1080p, button words and titles 11 and the sort headings 9, where the game's own small font is 16 to 19; on a Deck everything draws at 0.75, so body text is near 10 px and button words near 8. 'Menus small' is the Workshop gripe word for word, and the bigger sizes hide in three knobs in two places: ZeD's Text size and UI scale and the game's Font size.
- Steps now: 3 to set Large (the three-line menu, Text size, Large), once he knows to look. Could be: 0 (readable from the start).
- QA's reasoning: Option 1: it answers the 'menus small' gripe where it bites and leaves the director's 0.75 Deck scale call alone (docs/specs/BETA_DECISIONS.md:7).

### K3-7 (#13) The World window opens on the empty Floor, not the container you face
- Pick, option 1: The World window shows the container he faces, as the game does, and seated it drops the Floor and lands on the glove box or his seat.
- What the player meets: At a full kitchen counter he presses I and the World window opens on the Floor, which reads Nothing here; the counter is one of several small pictures on the strip, so he hovers for names and clicks the right one, and the next cabinet is another click, since the list keeps the last container or falls back to the Floor. Seated in a car, the same window lands on an always empty Floor, so the car looks empty until he clicks his seat or the glove box.
- Steps now: 2 (I, then the container's picture), at every container. Could be: 1 (I).
- QA's reasoning: Option 1: it is the game's own rule, it saves a click at every container and it brings the pad's Y a step closer to the crate.

### K3-8 (#14) On a pad, a touch of the screen, the mouse or a key pops both windows open
- Pick, option 1: Open nothing when the input switches to the pad, and Y opens the windows when he wants them.
- What the player meets: On a Deck he taps the touch screen or a key, then pushes the stick to walk on, and both windows open over the game with the pad inside them, so A opens an item's card instead of the door and the D-pad walks the list instead of opening a wheel; his first pad press of a session can do it too. With a pad the windows never roll up by themselves, so he presses Y to get the game back.
- Steps now: 1 (Y to put them away), every session and after every touch. Could be: 0.
- QA's reasoning: Option 1: Y is one press when he wants the windows, and the pop-up stops landing on him mid-walk.

### K3-9 (#15) On a pad, Select lost crafting and speed, and Crafting opens the stove in a kitchen
- Pick, option 1: The World wheel's Crafting opens by hand, and the nearest bench gets a slice of its own named for it.
- What the player meets: He presses Select for crafting, building or the game's speed, as the game taught him, and gets ZeD's settings wheel (Theme, Accent, Text size and ten more). Crafting now sits three levels in (D-pad Right, Craft and build, Crafting) and that slice opens at the nearest station, so in a kitchen he lands on the oven's panel, not his recipes, and presses B to leave it.
- Steps now: 3 presses outside a kitchen, 4 in one (the B to leave the oven). Could be: 2.
- QA's reasoning: Option 1: it ends the kitchen trap with one change and leaves the director's Select design alone (docs/specs/DPAD_WHEELS_SPEC.md:95-97, 124).

### K3-10 (#16) Nothing on screen opens the windows
- Pick, option 1: One bag button at the belt's left end that opens both windows, one click or one A.
- What the player meets: A mouse player who skipped the tour, or is back after a break, looks for his inventory or his health: the game's left-column buttons and rolled inventory bars are hidden, ZeD's windows start closed and nothing on the belt or in the hint strip names the inventory key. A click on a container opens the World window, but the Character window opens only by a key and Build has no key at all by default.
- Steps now: 2 once he knows I (I, the tab); stuck until then. Could be: 1 (a visible button).
- QA's reasoning: Option 1: it sits where his eyes already are and keeps the game's left column hidden as designed, and the game's Building key could get a default on the keyboard map at the same time.

### K3-11 (#17) Craft and Build open on an empty list, and Show forgets Known when the window closes
- Pick, option 2: Building opens on Known, since it is empty under Ready until he carries the materials, and Craft keeps Ready with the better empty line.
- What the player meets: He presses B with little on him, or opens Build to see what he could put up, and the list says Nothing is ready to make with what is in reach: Show: Ready, the default, hides every recipe he can't make right now, and Build stays empty until he carries planks, nails and a hammer. He finds Show at the tab's foot and picks Known, and the next time he opens the inventory it is Ready again; under Ready a pinned recipe vanishes and a bench's recipes never show by hand.
- Steps now: 3 (B, Show, Known), again on every open. Could be: 1 (B).
- QA's reasoning: Option 2: Craft keeps the director's short Ready list (ZeDUI/deltas/SESSION_125_DELTA.md:485) while Build stops opening empty, and the empty line stops being a dead end.
- Already done either way: K2-3 (pinned rows stay listed under any Show, as the open card's row already does (CraftingCore.lua:1122-1133, 2165-2181)).

### K3-12 (#18) On a pad, Loot all sits under the last row, next to To floor
- Pick, option 2: That, plus Loot all in the list's heading one Up from the first row and X on a container's button taking all from it.
- What the player meets: With a crate's rows up he wants Loot all, the first picture in the button row under the last item, so he walks the D-pad down every row (a full fridge is a long hold), and the press past the last row lands on To floor, where an A tips the crate onto the floor. X on a container's button does nothing, and A on the tab already open clicks and does nothing.
- Steps now: 8 to 11 presses on a ten-row crate. Could be: 2.
- QA's reasoning: Option 2: a full fridge becomes one Up and an A, and nothing lands on To floor.
- Already done either way: K2-4 (A on the tab already open folds it, as a mouse click does (ZeD_CharacterWindow.lua:1204-1207; docs/specs/GAMEPAD_SPEC.md:52)).

### K3-13 (#19) A move into a full bag fails without a word
- Pick, option 1: Over a container that can't take it, the drag chip turns the danger color and reads No room.
- What the player meets: His backpack is nearly full; he drags a rifle from the crate onto it and lets go, but nothing moves and nothing says why, so he tries again, then checks the weights. The game tints rows that won't fit red during the drag, while ZeD's drag chip shows the item, the count and the weight only, though ZeD's own Move To already grays a full bag.
- Steps now: 2 (a dead drop, then the weights). Could be: 1 (the chip says No room before he lets go).
- QA's reasoning: Option 1: it is the game's own warning (the red tint before the drop) in ZeD's chip, and it costs nothing after.

### K3-14 (#20) On a pad, the car's wheel moved off D-pad Up
- Pick, option 1: Seated, D-pad Up opens the car's wheel at once, the game's place, and on foot it stays Social.
- What the player meets: In the driver's seat he taps D-pad Up for the car's wheel, as the game taught him, and gets gestures and Shout; the car's wheel is D-pad Right, Vehicle, then the slice, for headlights, heater, horn, lock, seats, refueling and mechanics (RT still starts the engine and A still gets him out). The dash is a level deeper and holds the pad until B, so after the Heater slice A presses a climate key instead of getting him out, and the game's own guide pages, which ZeD shows, still tell a controller player D-pad Up.
- Steps now: 3 to 4 inputs for a car job (the game: 2). Could be: 2 to 3.
- QA's reasoning: Option 1: the smallest change to the settled spec (docs/specs/DPAD_WHEELS_SPEC.md:60, 121), and it makes the game's own guide pages right again.
- Already done either way: K2-5 (the dash's first pad stop is the ignition and B reads Drive in both places (ZeD_Dashboard.lua:811, 2343-2346; UI.json:704, 2880); if the car's wheel stays off Up, the guide's car pages stop telling a controller player D-pad Up (ZeD_SurvivalGuide.lua:228-266, 411-431)).

### K3-15 (#21) On a pad, swapping weapons takes one more flick than the game
- Pick, option 1: Holding D-pad Left opens the Weapons ring at once, and a tap still opens the Character wheel.
- What the player meets: In the game, holding D-pad Left shows his weapons; in ZeD it opens the Character wheel (Tabs, Weapons, Eat, Drink, Medicine and more), so he flicks to Weapons, the ring swaps, then he flicks to the weapon: three moves with a zombie on him. The Hold setting changes the gesture, not the extra ring.
- Steps now: 3. Could be: 2.
- QA's reasoning: Option 1: the game's hold habit gets the game's ring while the tap keeps ZeD's Character wheel.

### K3-16 (#22) The game's speed hides in tiny pushers on the belt's watch
- Pick, option 1: A row of speed keys beside the belt's watch, one press each.
- What the player meets: In Full with a watch on, the game's corner speed keys are gone and the speed lives in the belt watch's SPEED and START pushers, 6 by 14 px of pixel art at 1080p and on a Deck, named only on hover. SPEED steps 1x, 5x, 20x, 40x one press at a time and does nothing while paused, where the game shows five keys, one press each; F2 to F6 still work, but nothing on screen says so.
- Steps now: 2 (find the pusher, step to the speed). Could be: 1.
- QA's reasoning: Option 1: one press per speed as in the game, and the watch stays on the belt where the director put it.

### K3-17 (#25) The second press doesn't put away what the first opened
- Pick, option 1: The same key or button again closes what it opened: H, B and M again close, a tap of Y closes both windows and B on the map closes it with the World window it opened.
- What the player meets: H opens both windows on Health and H again only folds the drawer, leaving both up, and B and M again do the same, where the game's second press closes the page; Escape over ZeD's map opens the pause menu. On a pad a tap of Y rolls the windows to two bars that stay on screen (only a hold clears them), B never puts them away and B on the map folds it into a World window that keeps the pad.
- Steps now: 3 by keys (H, H, then I to clear); 2 on a pad (Y, then a hold). Could be: 2 by keys (H, H); 1 on a pad (Y).
- QA's reasoning: Option 1: it is the game's habit on both inputs and the shortest way back to playing.
- Already done either way: K2-6 (Escape over ZeD's map closes it; its pop-out has no key handler and registers no Escape taker (MapsTab.lua:2462-2530), as the car radio does (Overrides/CarRadio.lua:43-45, run at Overrides/Prompts.lua:161-162)).

### K3-18 (#26) On a pad, nothing says the D-pad opens wheels or that a bumper and a button run quick actions
- Pick, option 1: For the first hours the hint strip adds one line: D-pad Wheels, LB or RB + button Quick actions.
- What the player meets: Walking around, the strip over the belt shows only the game's own prompts: nothing says a D-pad tap opens the Character, World, Social and Here and now wheels or that LB or RB with a face button eats, drinks or treats, and the Controller map that explains them is D-pad Down, Help, Controller map. When he does open a wheel it names only the slice the stick points at and closes by itself after 3 s if he reads without pointing.
- Steps now: 3 to find the Controller map, if he looks. Could be: 0 (the strip says it).
- QA's reasoning: Option 1: the hint strip already drops each hint after three uses, so it teaches the chords where his eyes are and then gets out of the way.

### K3-19 (#29) Healing has no front door: a click on a wound does nothing and a bandage's card can't bandage
- Pick, option 1: A left click on a wound or a hurt part opens its treatments (the pad's first stop being the worst wound), an empty menu names what is missing and first-aid cards get the game's verbs, Bandage and Take Pills.
- What the player meets: The tour told him to click a wound to treat it; he presses H, clicks the red forearm row and nothing happens, since only a right-click opens the treatments and no help line says so. A bandage's card offers only Drop and More, wipes and thread get a Use that does nothing, the Health tab's one bright button starts an exercise, a drag of the bandage onto the wound no longer works and with nothing to treat it the right-click opens nothing at all. On a pad the Health tab starts on its header, about six presses above the wounds.
- Steps now: 4 once he finds the right-click (H, right-click the wound, Bandage, the bandage); 13 presses on a pad. Could be: 3 by a left click, or 1 drag as in the game; 7 on a pad.
- QA's reasoning: Option 1: the click the tour already teaches starts working and the bandage goes where he clicks, with no new button (a left press only needs to reach _healthTreatAt, ZeD_CharacterWindow.lua:2762-2784).
- Already done either way: K2-7 (the tour's Health line matches what a click does (UI.json:5086); the Use that does nothing goes from wipes, thread and the other drainables the game's double-click ignores (ItemCardOrganism.lua:440-441; ItemCard.lua:957-962); and a drop on a body part or a wound row goes to the game's dropItemsOnBodyPart (vanilla ISHealthPanel.lua:1915-1940), which ZeD's drop handler never checks (InventoryRenderer.lua:3758-3884)).

### K3-20 (#30) On a pad, holding A eats in a crate where it marks elsewhere, and hold X's quick use is never named
- Pick, option 1: Outside his own bags hold A always marks, and in them it runs the game's quick use, named in the footer (Eat, Drink, Take Pills, Bandage).
- What the player meets: In a fridge he holds A on a can to mark it with two others, but holding A on food eats it, on a drink drinks it and on pills takes them, in a crate or on the floor too, while on any other row the same hold marks, so a fridge full of food can't be marked at all. Hold X runs the game's quick use (from a bandage row it bandages the worst wound) but no prompt names it, and on food hold A eats by ZeD's rules while hold X eats by the game's.
- Steps now: 5 to mark three cans, or one unwanted meal. Could be: 4.
- QA's reasoning: Option 1: it keeps the Nov 14 ruling that eating is a hold (punch list 225, ZeDUI/PUNCH_LIST.md:4953-4957) where it was asked for, in his own bags, and stops meals out of a fridge by accident.

### K3-21 (#31) Stacks: no Grab one or Grab half, and a double-click takes one
- Pick, option 1: A closed stack's right-click gets the game's own Grab one, Grab half and Grab all.
- What the player meets: He right-clicks a stack of 60 rounds in a crate to take half and gets only Grab, which takes all 60, where the game's menu has Grab one, Grab half and Grab all. A double-click on Nails (50) brings one nail and the card's Grab takes one, while a drag, the right-click Grab and the pad's X take the whole stack.
- Steps now: 4 (open the stack, click, Shift-click, drag). Could be: 2 (right-click, Grab half).
- QA's reasoning: Option 1: handing the game's menu the stack as one stack row (ZeD_WorldWindow.lua:2318-2323; ZeD_CharacterWindow.lua:552-610) brings its own three choices back.
- Already done either way: K2-8 (a double-click on a closed stack takes the whole stack, as the game's does and as every other ZeD move of a closed stack does (quickUse moves { item } at InventoryRenderer.lua:913-928; the drag carries the stack at 3731-3756)).

### K3-22 (#32) Crafting ten takes twelve clicks, and Build's amount keys never work
- Pick, option 1: A Max key after + that sets the most the band already knows, and no amount at all where the most is 1.
- What the player meets: He wants ten of something and the band shows - 1 + with no Max and no typed number, so ten crafts take nine clicks on + before Craft (the mouse wheel steps it only on a narrow screen). Every Build card shows the same - 1 + grayed beside Build, since building makes one at a time, and on a pad the focus still stops on both dead keys.
- Steps now: 12 for ten crafts. Could be: 4 (Max, Craft).
- QA's reasoning: Option 1: the game's own window has MAX (vanilla ISWidgetHandCraftControl.lua:30-49, 290-295), and Build's dead keys go.

### K3-23 (#33) Options has no Accept and Back can only discard; closing the first-launch window throws the picks away
- Pick, option 1: Back's question offers Apply as its main answer, as the Mods screen offers Keep, and the first-launch close box keeps the picks.
- What the player meets: He turns the music down: Apply keeps Options open and Back closes it, one click more than the game's Accept, and if he clicks Back first the band asks Discard 1 change? with only Keep editing and Discard changes, where the game asks to apply and ZeD's own Mods screen offers Keep. On the first-launch window the close box means Skip, and his Lite and Large picks go back before his eyes.
- Steps now: 5 (change, Back, Keep editing, Apply, Back). Could be: 3 (change, Back, Apply).
- QA's reasoning: Option 1: the same question then reads the same way in every ZeD window.

### K3-24 (#34) On a pad, a quick action pressed with the windows open turns a tab instead
- Pick, option 1: In a window, a bumper held with a face button runs the quick action and never turns a tab.
- What the player meets: The windows are up and he presses LB + A to eat, as he does in the world, and nothing is eaten: A works whatever the pad is on (it opens an item's card) and LB's release turns the Character window to its next tab. Held longer, LB steps the tabs back.
- Steps now: 3 (undo the tab, put the windows away, the chord). Could be: 2 (the chord).
- QA's reasoning: Option 1: one rule, so the same press eats everywhere.

### K3-25 (#35) An amber Surface warning on every surface recipe, table or not
- Pick, option 2 (the director's pick; QA had picked 1): Drop the square, and the line under the rows says Needs a table or counter only when none is near.
- What the player meets: He stands at a table and opens a recipe made on any surface: the row is green and Craft is lit, yet the card wears an amber Surface square, the warning color, as every such recipe does, and he looks for a table he is standing at. ZeD already knows whether one is within two squares, and the game marks these recipes in a plain color and warns only when no surface is near.
- Steps now: 1 (a look for a table that is there). Could be: 0.
- QA's reasoning: Option 1: it matches the game, keeps the one true hint when no table is near and stops a ready recipe reading as a warning.

### K3-26 (#36) On a pad, the World wheel's Map opens a ring with one choice in it
- Pick, option 1: The Map slice opens the map at once, with RB + Y's default path re-pointed in the same change (ZeD_QuickChords.lua:66, 224-225).
- What the player meets: After D-pad Right and a flick to Map a new ring opens holding only World map and Back, so he flicks again for the map; the mini-map slices it once held are gone, and the game opens its map in two presses. RB + Y still opens it in two.
- Steps now: 3. Could be: 2.
- QA's reasoning: Option 1: one press less, and the default chord keeps working.

### K3-27 (#40) The window menu: 13 rows, Style missing, the Keyboard map at the bottom
- Pick, option 1: Keep the rows, add Style, hide the pad rows without a pad and put Keyboard map and ZeD setup first.
- What the player meets: The three-line box on each title bar drops 13 rows: Keyboard map and ZeD setup, the two he wants mid-game, sit at the bottom with Hide the interface between them, and Controller highlight shows with no pad. Style is not there at all, so Full to Lite is six clicks through the pause screen against three presses on the pad's wheel, and the Keyboard map opens only from this menu, though its own header says the guide opens it. ZeD setup also shows its 17 controller rows to a mouse player.
- Steps now: 3 to the Keyboard map; 6 to switch Style. Could be: 2 to the Keyboard map; 3 to switch Style.
- QA's reasoning: Option 1: it keeps every quick change the window menu is praised for and fixes the order, and the guide's Keys topic should link the map, as the map's own header promises (ZeD_KeyboardMap.lua:14).

### K3-28 (#41) Paused, both windows go read-only
- Pick, option 1: Moves between bags are allowed while paused and run on play, as the game's drag does, and other actions stay grayed.
- What the player meets: He pauses to sort his bag in peace and opens the inventory: a gray veil lies over the list with a line saying why, and clicks and right-clicks do nothing until the game runs again. The game refuses its item menu while paused too, but lets a drag or a double-click queue a move that waits for play.
- Steps now: 3 (play, I again, then sort while time runs). Could be: 2.
- QA's reasoning: Option 1: it gives back exactly what the game allows and keeps the rest of the feature (ZeDUI/tools/qa/FEATURE_MAP.md:434).

### K3-29 (#42) A red count on the belt for other mods' errors
- Pick, option 1: Red only for ZeD's own errors, with other mods' errors counted in gray.
- What the player meets: Any Lua error, another mod's or the game's, is filed in Messages every two seconds and turns the belt note's count red. Balloons are off by default, so it appears with no word, and he can do nothing about another mod's error.
- Steps now: 2 (open Messages, find it isn't his to fix). Could be: 0.
- QA's reasoning: Option 1: the Bug report keeps every error while the red stays for something ZeD can fix.

### K3-30 (#43) Lite, the simple style, changes nothing on a pad
- Pick, option 1: Lite on a pad takes the game's ways where ZeD differs: Y to the crate, no pop-open, the car on D-pad Up.
- What the player meets: He picks Lite on the first launch to keep things like the game, and on the pad nothing changes: the windows still pop open, Y still lands on his bags, the bumpers still turn tabs and the D-pad wheels are still ZeD's four. Lite trims looks and two buttons and turns every addition off.
- Steps now: 4 (the pad costs above, unchanged). Could be: 1.
- QA's reasoning: Option 1, unless the pad themes above are fixed for everyone, which makes this one moot.

### K3-31 (#44) The container on show is not lit in the world
- Pick, option 1: Light the container on show and the one under the pointer, by the game's own outline option.
- What the player meets: In a kitchen with two counters, a cabinet and a fridge the strip shows four small pictures, two alike, and he can't tell which counter he is looking in; with several bodies on the ground every body is the same picture. The game outlined the container on show and the one under the pointer, and ZeD lights nothing, though the game's outline option still shows in Options.
- Steps now: 2 (hover the pictures, guess). Could be: 0.
- QA's reasoning: Option 1: the game's own option already says whether he wants it.

### K3-32 (#45) Picking every row needs a double-click on empty space
- Pick, option 1: A Pick all button in the list's heading, beside the Filter.
- What the player meets: He wants to move a whole bag into another, and ZeD picks every row only on a double-click in the empty space under the rows, which a long list doesn't show and nothing mentions (Ctrl+A went on the director's Nov 10 ruling, since A walks). So he clicks the first row, scrolls and Shift-clicks the last.
- Steps now: 3. Could be: 1.
- QA's reasoning: Option 1: a visible button that works on a list too long to show empty space.

### K3-33 (#46) The dash's switches give no name on hover, and the key never says No key
- Pick, option 1: Every switch names itself and its state on hover in the game's words, the key says No key when there is none and dead switches are painted blank.
- What the player meets: Pointing at a dash switch only washes it, with no name and no state, and the printed legends are 3 by 5 pixel letters on targets as small as 18 by 13 px at 1080p; with no key the lock goes dead with no word. With the key in his pocket a click only puts it in, so a second click starts the engine (W still starts it in one press), and some switches drawn on the plates, the Nyala's wiper and the Dash Elite's hazard key, do nothing at all.
- Steps now: 2 (a click that seems to do nothing, then another). Could be: 1.
- QA's reasoning: Option 1: the game names every dash icon on hover, and the director's rule puts hints on icon-only controls.

### K3-34 (#47) A double-click, or the pad's A, on a recipe doesn't craft as the game's list does
- Pick, option 1: A second click on the open row leaves the card open, and another row or Escape closes it.
- What the player meets: He double-clicks a recipe, the way the game's window crafts: the first click opens the card, the second shuts it and nothing is made. On a pad A opens the card with the focus on Craft and a second A crafts, where the game's A crafts at once.
- Steps now: 5 by double-click (then the row again and Craft); 2 on a pad. Could be: 3; 1 on a pad.
- QA's reasoning: Option 1: the card stops snapping shut under a double-click while he still looks before the materials go, and the pad's two As stay as documented (ZeD_WorldWindow.lua:5122-5127).

### K3-35 (#48) A repeated title row and an idle Station box crowd the craft list
- Pick, option 1: Drop the title row, and show the Station box only when a station is in reach.
- What the player meets: Above the list a row holds only Crafting (or Building), right under a window title that already ends + Crafting, and under it the Station box takes a third of the row and reads Station: Hand even with no station in reach, leaving the search a third. The station view already dropped the same title row as noise.
- Steps now: 0 (room, not steps). Could be: 0.
- QA's reasoning: Option 1: the Nov 20 station view ruling already chose it (Stations.lua:872-876), and the search gets the room.

### K3-36 (#49) Mouse and keyboard get no quick eat, drink or treat
- Pick, option 1: A click on Hungry, Thirsty or a wound moodle opens the same short list the pad's wheel shows, the best pick first.
- What the player meets: On a pad LB + A eats, LB + B drinks and RB + A treats, but with a mouse every meal is open the windows, find the food, click it, click Eat. The Hungry, Thirsty and Bleeding moodles say what is wrong, but a click on one passes through; the game has no keyboard quick eat either.
- Steps now: 3. Could be: 2.
- QA's reasoning: Option 1, once the picks are safe (the raw meat and bandage fixes above): it puts the pad's best feature under the mouse.

### K3-37 (#51) The tour plays over a live game, and once skipped it never comes back
- Pick, option 1: The game pauses while a tour balloon is up, as the guide pauses it, and a Show me around row in every window's menu starts it any time.
- What the player meets: Show me around is already picked on the first launch, so Accept turns the tour on: six seconds into his next game, a new one or a save continued mid-fight, twelve balloons open windows over the world while the game runs, and on a pad the tour holds the pad until it ends or he presses B. Skip, Escape, B or Load a setup turn it off for good, and no menu row in a game starts it again.
- Steps now: To get it back: 6 and a quit (Escape, Save and quit, Settings, ZeD setup: pick, save or load, Accept, Continue). Could be: 2 (a Show me around row).
- QA's reasoning: Option 1: no balloon lands on him mid-fight, and a player who skipped can take it when he has a minute.

### K3-38 (#53) The first-launch window: nine choices, Full or Lite unexplained, Accept far away on a pad
- Pick, option 1: Keep the approved rows, put the Style tip under Style, read Playing with from the device in use and let Y accept on a pad.
- What the player meets: The first thing a new subscriber sees is three cards, six rows of choices and nine accent swatches; the one that matters, Full or Lite, has no word on what changes, and Playing with only changes the tour's words, starting on Mouse and keys even when a pad drives the window. On a pad Accept is eight presses down and one right, with no Y or Start, and the Settings menu's ZeD setup: pick, save or load reopens this window, a second thing called ZeD setup.
- Steps now: 1 (Accept) to 9 (answer everything); 10 presses on a pad. Could be: 1; 1 on a pad (Y).
- QA's reasoning: Option 1: it keeps the approved layout and fixes the three things a new player can't answer or reach.

### K3-39 (#54) Guns: Jammed never names the fix, and the ammo count starts off
- Pick, option 1: Jammed names the Rack key wherever it shows: Jammed, press X.
- What the player meets: The gun clicks in a fight, and its card and hover card say Jammed but never name the Rack key (X) or offer Unjam. The belt's ammo box, which would show the rounds left and turn red when jammed, starts off like every addition, and its switch is hidden in Lite.
- Steps now: 3 by mouse (find Unjam in the right-click); 1 with X if he knows it. Could be: 1.
- QA's reasoning: Option 1: a cheap win the game doesn't have, with nothing new on Lite's screen.

### K3-40 (#55) The Journal's recipe list is a dead end
- Pick, option 1: An Open in Craft key in the Journal's band, through RecipeIndex.open.
- What the player meets: He browses Journal, Recipes, finds what he wants and clicks it, but the card is read-only, with no Craft, and its picture does nothing. To make it he opens the Craft tab, types the name again, clicks the row and Craft, where the game's recipe list opens a recipe in the crafting window in one click.
- Steps now: 6. Could be: 2.
- QA's reasoning: Option 1: the opener already exists (RecipeIndex.lua:229-235).

### K3-41 (#56) Passengers lose the belt and get a dash they can't use
- Pick, option 1: The belt shows for passengers and the dash for the driver only, as the game does.
- What the player meets: In a passenger seat his belt hides, hands, slots and ammo with it, though the game hides its bar only from the driver, and the number keys still draw weapons, blind. A read-only dash marked PASSENGER takes the bottom of the screen, where the game shows its dashboard to the driver only.
- Steps now: 2 (use a belt slot unseen). Could be: 1.
- QA's reasoning: Option 1: the spec's reason for the passenger dash, that the game shows its dashboard to all occupants (docs/specs/DASHBOARD_WATCH_SPEC.md:59), is not what the game's code does (vanilla ISVehicleDashboard.lua:601-606).

### K3-42 (#57) The card's Repair spends the first fixer without saying which
- Pick, option 1: The Repair button's balloon names the fixer: Repair with Duct Tape.
- What the player meets: Repair on a bat's card is one click, which is good, but it spends the first fixer he carries in the game's list and never names it or the odds, so he loses his only wood glue when he meant the duct tape. The first fixer is the game's strongest repair.
- Steps now: 2. Could be: 2, knowing what it spends.
- QA's reasoning: Option 1: the one click stays and he sees what it spends.

### K3-43 (#58) Turn on from the stove's menu opens its control panel
- Pick, option 1 (the director's pick; QA had picked 3): Turn on only turns it on, and the panel opens from Stove settings and the gears picture.
- What the player meets: He right-clicks the stove and picks Turn on to warm a can, and once he walks there the World window opens on the oven's panel, which he closes. The game only turns it on, and ZeD's own power picture turns it on with nothing opening.
- Steps now: 3. Could be: 2.
- QA's reasoning: Option 3: it was the director's own request (ZeDUI/PUNCH_LIST.md:4833-4837), it costs one close at most and the power picture already turns a stove on with nothing opening.

### K3-44 (#59) Both windows' first tab is called Loot, and some tabs aren't the game's words
- Pick, option 1 (the director's pick; QA had picked 2): The game's page words: Inventory, Info and Temperature.
- What the player meets: Both windows' first tab is Loot: on the World window what lies around him, on the Character window his own bags, which the game, the tour, the first-launch preview and ZeD's own rolled tab call Inventory. The game's Info and Temperature pages are ZeD's Identity and Thermal, though the words show only on a hover, so few players meet them.
- Steps now: 1. Could be: 1.
- QA's reasoning: Option 2: Inventory is already ZeD's own word on the rolled tab, in the tour and in the preview, and Identity and Thermal read fine.

### K3-45 (#60) A car's right-click has no Get in or Vehicle mechanics
- Pick, option 1 (the director's pick; QA had picked 2): Add Get in and Vehicle mechanics to the car's right-click, running the game's own onEnter and onMechanic.
- What the player meets: A mouse player right-clicks the car to get in or look under the hood, and the menu holds fuel, wash and trailer lines, often nothing. Getting in is E, which the hint strip names at the door, and the mechanics are U, V or the Vehicle tab; the game's menu is the same.
- Steps now: 2 (a wasted right-click, then E). Could be: 2.
- QA's reasoning: Option 2: E is one press and the strip already names it.

### K3-46 (#61) F1 with no tab open opens the guide book on its title page
- Pick, option 1: With no tab topic, F1 opens the book on its contents.
- What the player meets: With no Character or World tab showing, F1 in Full opens the printed guide book on its copyright and title pages, with Contents on page 3, so he turns a page or clicks Contents. With a tab open F1 lands on that tab's topic, which beats the game.
- Steps now: 3. Could be: 2.
- QA's reasoning: Option 1: one page less for a player who reads nothing.
