# Check: everyday vanilla windows, the leftovers (Nov 7 2026)

What changed, from the list of game windows still reachable with ZeD on (docs/reference/VANILLA_WINDOWS_20261107.md, section B), with the director's decisions and corrections of Nov 7. Nothing here has been opened in the game yet. The no-game check is `ZeDUI/tools/qa/everyday_leftovers_sim.lua` (148 checks, all pass; 41 of them fail on the code before this work).

Run every item twice: **4K fullscreen at 1.75x** and **Steam Deck 1280x800 at Auto** (Normal text, then Large text). Use the mouse first, then the controller. QA save only (Saves/Sandbox/ZeD-QA). Wait for windows to stop moving before any capture.

Prep: a car with the key in it near the drag strip; a carried CD and a video tape; a lipstick and an eyeshadow, a mirror (carried, and one on a wall); a second controller; a modded crafting station if one is in the compat set (Nov7_compat_r6), else skip B15's in-game part.

## B6 Heater and air conditioning: the key and the wheel slice go to the dash

1. Sit in the driver's seat, key in, engine off. Press the Heater key (the game's binding).
   - Should: no game heater window. The heater turns on; the dash's climate controls light up for about two seconds (the hover look on Heat, Off, the temperature and fan); the climate readout shows the heater on with the temperature it had.
2. Press the Heater key again. Should: the heater turns off; no window.
3. Take the key out. Press the Heater key with the heater off. Should: nothing turns on; the game's "Start the vehicle or put keys in ignition to start heater." shows over the head; the controls still light up.
4. V wheel > Heater On / Heater Off, and the D-pad World wheel > Vehicle > Heater. Should: the same as the key, never the game's window.
5. Controller, driver: the D-pad wheel's Heater slice. Should: the pad lands on the dash's first climate control (Heat on most dashes) with the dash's focus mark; B lets go back to driving.
6. Passenger seat: the key and the slice. Should: the heater still turns on and off (the game allowed it from any seat); the dash stays read-only, the pad does not go to it.
7. Simple dash (ZeD setup, Dashboard Simple): steps 1 and 5. Should: the plain strip's climate buttons light up and take the pad.
8. ZeD setup > ZeD screens > Dashboard set to the game's own. Press the key. Should: the game's heater window opens, as before.
- Deck: the lit controls and the focus mark must stay readable at the smaller dash.

## B7 Mini-map: out of ZeD's wheels

1. Controller: D-pad Right (World) > Map. Should: one slice, World map, then Back. No Toggle mini-map, no Focus mini-map. The Map slice is still second on the World wheel.
2. Hold the map key (keyboard) for the game's map wheel. Should: World map only.
3. A quick action chord that was set on a mini-map slice before: should do nothing (no error in console.txt).
4. A save that had the game's mini-map showing (or a mod that toggles it): load it. Should: no mini-map on the screen, not even for a moment at load. Turn safe mode on (or ZeD screens > Wheels given back): the mini-map it hid shows again; turn it off: hidden again.

## B8 Read label on a CD or a video tape

1. Inventory: right-click a CD > Read label. Should: ZeD's reader opens, small (about 640 wide at 1080p), no side column, no Paper or Words switch: a clean page with the recording's name at the top, who made it under that (when the game knows), and the label's lines as paragraphs ("Released February 1993. Potassium Records." as two lines). Back and the close box close it; Escape closes it.
2. The same on a video tape, and on a CD inside a bag.
3. Controller: Read label from ZeD's context menu with A. Should: the reader has the pad; D-pad up and down scroll; B closes; the help line says so.
4. Too dark or illiterate: the option is greyed with the game's reason (unchanged).
5. Safe mode on: the game's small label window, as before.
- Deck: the page fits the screen; long labels scroll.

## B9 Make-up: with the hair

1. Carry a lipstick (no mirror nearby). Open the Character window > Identity (ID) tab and scroll to Hair and beard.
   - Should: the switch reads Hair style, Beard style (a man), Make Up. A woman's reads Hair style, Make Up. With no make-up carried or worn the switch has no Make Up.
2. Pick Make Up. Should: rows for the spots the lipstick can do, under the game's category heads (Lips); each row with a small figure wearing that spot, face on, and the lipstick named on the right with a filled square. Without a mirror the rows are greyed or folded (by ZeD setup's Hidden actions) with the game's "needs a mirror" reason; the folded row says a mirror would let you put on make-up.
3. Stand by a wall mirror (or carry one). Pick a row. Should: the After head shows it on; the button beside the switch reads Apply; the line under it says it uses your lipstick. Apply: a short action, then "Done: ... is on", the license figure and Now head show it; the lipstick's uses drop by one.
4. The spot just applied now shows under Remove. Pick it, Remove. Should: it comes off at once, "Done: ... is off".
5. Inventory right-click the lipstick > Make Up. Should: no game make-up window; the Character window opens on ID, the section scrolled into view, on Make Up, that item's spots first. Paused game: the same, with the paused glass (B14).
6. Controller: on the switch, D-pad left and right go through Hair, Beard, Make Up; A on a row applies it; focus goes to the button (Stop while it runs).
7. ZeD screens > Windows given back to the game: Make Up opens the game's window.
- Deck and Large text: three switch labels fit (they truncate, never overlap); the row figures stay in their frames.

## B12 and B13 Controllers joining and leaving, and every notice from the Messages note

Do this section first with ZeD setup's notice pop-ups at their default (Off): the controller balloons must still show (they replace windows the game always showed); a mod's note or an error must not. Then once with them On.

1. While playing with mouse and keyboard, plug in a controller.
   - Should: a speech balloon pops up out of the Messages note on the belt (the belt's right end), tail down to the note, in the balloons' capitals: CONTROLLER PLUGGED IN, then CONTROLLERS | PRESS A ON IT TO JOIN. The note's count goes up. Nothing in the middle of the screen.
   Press A on it. Should: still nothing in the middle; the balloon again, now PRESS A ON IT AGAIN TO CHOOSE HOW IT JOINS (the same note, replaced, not a second one).
2. Press A on that controller again. Should: Messages opens on Controllers with that controller driving it: the note's buttons are the game's own choices (Take over player 1, Add new player, Add <saved name>). D-pad to one, A. Should: the game's own step happens (taking over, or the game's new player screens); Messages closes; the note keeps "You answered: ...".
3. Instead of 2, press B on that controller: nothing opens; the next A shows the note again (no second note for the same controller).
4. Mouse: click the balloon. Should: Messages opens on Controllers; a click on a choice does the same as 2.
5. Unplug player one's controller while playing with it. Should: no banner in the middle; a balloon CONTROLLER UNPLUGGED, then CONTROLLERS | PLAYER 1'S CONTROLLER WAS UNPLUGGED. PLUG IT BACK IN TO GO ON. Messages' note has the game's Use Keyboard and Mouse button; clicking it hands player one to the mouse.
6. Plug it back in. Should: a balloon CONTROLLER PLUGGED IN ... PLAYER 1'S CONTROLLER IS BACK; the unplugged note is replaced, not added to.
7. Split screen: unplug player two's controller. Should: the same note for player 2, without the keyboard button.
7b. Open Messages with a new controller (A on it twice), then unplug that controller. Should: Messages closes, nothing stuck. Close the guest Messages window while player one plays on a pad: player one's pad keeps working where it was.
7c. Player one: unplug, press Use Keyboard and Mouse, then plug a controller in later. Should: "Controller plugged in, press A on it to join", never "Player 1's controller is back".
8. Every other ZeD notice comes the same way now: let a mod's note be caught, an error, a ticket answer, an invitation (MP rig). Should: each a balloon out of the note, newest lowest, at most three, gone after six seconds; nothing in the top right corner any more.
9. In a vehicle seat (the belt hides), with anything kept in Messages: every dash, full and Simple, shows the Messages note at its top right (the belt's box, paper and count). Trigger a notice. Should: the balloons come out of that note, tail down to it. Click the note: Messages opens. With nothing kept, no note on the dash.
9b. Split screen: unplug player two's controller. Should: the balloon comes out of player two's belt note when player two has a belt (the per-player belt branch), else player one's.
9c. Moodle notices: unchanged, still beside the moodles.
10. Safe mode on: the game's list and banner come back.
- Deck 1280x800 and 720p: the balloons stay on the screen (they shift left when the note is near the right edge), clear the belt and never cover the hands. Large text does not change the balloons (pixel face).

## B14 Paused: the Character window for looking

1. Pause (the pause key or speed 0). Press the Skills key, then Health, Info, Protection. Should: ZeD's Character window opens alone (no World window) on that tab; never the game's Character info window.
2. Over the tab and the item list: a thin veil and a line at the top, "Paused: look only until the game plays". Clicks, right clicks, drags and double clicks there do nothing; the mouse wheel still scrolls; the tab strip on the left and the bags on the right still work.
3. Unpause. Should: the veil goes the same frame; everything works again.
4. The inventory key while paused: opens or closes the Character window alone.
4b. Open the World window too, then pause. Should: the same veil and line over the World window between its bags (left) and its tab strip (right); its actions held, its tabs and bags free.
5. Controller, paused: Back wheel > Player Info. Should: the Character window on its tab, and the pad works in it while paused: the D-pad moves, B backs out, LB and RB swap to the World window (same veil), the tabs change; A and X on items do nothing. Unpause: everything acts again. Open a D-pad wheel and close it while paused: the window still answers the pad.
6. A dead character: as before (the windows close).
- Deck: the line at the top of the veil fits or truncates cleanly.

## B15 Crafting stations other than benches, drying racks and stoves (modded only)

1. With a mod that adds a station with its own logic (a furnace, a still, a tank): right-click > its station option, or the controller's Interact.
   - Should: no game entity window. The World window's Craft tab, bound to it: the STATION select and band (its name, distance, Station, Running or Idle), then Recipe, Start or Stop with the progress strip, each of its stores (Input, Output or Holds; items with Take, a fluid as "2.5 of 10 L" with a strip), and From your bags with Add for what its inputs take.
2. Start, Take, Add: each walks to the station first and runs the game's action. B (pad) leaves the station.
2b. The game's own Butcher Hook, Log Bench, Log Stool, Log Table: their station option opens what it opened before this work (the game's window), never the general card.
3. A machine on the game's own craft logic that is not a drying rack (if a mod has one): it gets the drying rack's view; its empty bag line reads "Nothing you carry fits." (not "this rack").
4. Safe mode: the game's window.

## Console

After each section: no new lines starting with `[ZeD]` that say "failed" or "kept the game's window", and no Lua errors in console.txt.
