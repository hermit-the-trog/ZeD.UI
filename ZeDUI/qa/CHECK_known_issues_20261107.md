# Check: the beta 7 known issues (Nov 7 2026, Build)

What changed, and how to check each in the game. Sims (no game): `mods_order_sim.lua` (ZeD picks),
`dash_odo_sim.lua` SERVER and SPLIT (the dashes and the ash tray, client side), `known_issues_sim.lua` (the ash tray on
the server, the split-screen gates, the belts, the month words). All 22 sims and the i18n guard pass.

Settings for every part unless it says otherwise: 4K fullscreen at 1.75x, then the Deck (1280x800, Auto, Normal text).
Mouse and keyboard first, then a pad. Close the game after.

## 1. ZeD picks comes back with ZeD-GUI, every way

Before: ZeD picks (which needs ZeD-GUI) went off with ZeD-GUI and came back only when ZeD-GUI was ticked again on its
own row. Now it comes back whichever way ZeD-GUI goes off and on again in one visit to the Mods screen.

Setup: ZeD-GUI and ZeD picks both on; at least one other mod; a folder holding ZeD-GUI (not picks); on the Load order
page, a separator with ZeD-GUI under it.

| Off by | On by | Expected |
|---|---|---|
| ZeD-GUI's row | ZeD-GUI's row | picks on (as before) |
| ZeD-GUI's row | the folder's box | picks on |
| the folder's box | ZeD-GUI's row | picks on |
| the folder's box | the folder's box | picks on |
| Turn all off | ZeD-GUI's row | picks on; nothing else comes on |
| Turn all off | Turn all on | everything on |
| No mods (Profiles) | ZeD-GUI's row | picks on |
| the separator's box (Load order) | the separator's box | picks on |
| ZeD-GUI's row | a mod that needs ZeD-GUI | ZeD-GUI and picks on |

These stay as they were: picks turned off on its own row stays off whatever ZeD-GUI does; a saved profile with
ZeD-GUI on and picks off loads that way; Undo changes puts back the set the screen opened with; leaving and coming back
to the Mods screen forgets. The note under the list names picks when it comes along. With a pad: the same table, the
boxes and rows pressed with A.

## 2. Split-screen

Two pads, both local players in one game (single player, then on the local server: `mp_server.ps1 -Start`, both
players joining). Player 1 on pad 1 (or mouse and keyboard), player 2 on pad 2.

**What to expect.** ZeD's Character and World windows (and their drawer, cards and wheels) are player 1's. Player 2 gets
the game's own windows, their own, on their half of the screen, driven by their pad. Each player gets their own belt
and their own dash.

1. Player 2 presses Y: the game's inventory and loot open on player 2's half; player 1's ZeD windows do not move, open
   or close. Player 2 moves through their inventory with their pad; player 1's windows ignore pad 2 entirely.
2. Player 1 presses Y (or I on the keyboard): ZeD's windows open as before, on the full screen layout.
3. Player 2's D-pad and Select: the game's own wheels (Player Info, Investigate, the map). Player 1's D-pad: ZeD's.
   Player 2's Player Info, Investigate This Area, the map (Show, Hide, Toggle), Inspect on a garment, crafting and
   building: the game's own windows for player 2; player 1's ZeD windows untouched.
4. Belts: each player's belt at the bottom of their own half, showing their own hands and hotbar. Player 2 in a car:
   their belt hides, player 1's stays. Player 2 on a pad: D-pad Left onto the belt and B off it returns them to their
   game, never to player 1's window. Drag an item from player 1's ZeD window onto player 1's belt: it attaches there.
5. The moodles and the hint strip of each player sit above their own belt (and their own dash in a car).
6. Dashes: player 2 drives, player 1 rides (and the other way round): each has their own dash on their own half,
   with the car's figures. The controller on the dash (World wheel, Vehicle > Dashboard): player 1 only, as before.
7. **On the server:** player 2 drives a few miles, stops the engine, gets out. Restart the server, rejoin, sit at the
   wheel: the odometer kept player 2's miles (before: they were lost). Then player 2 rides with player 1 driving:
   player 2's dash shows player 1's miles as they go.

Not done (needs the pad focus made per player first, see the report): ZeD's own windows for player 2.

## 3. The dash ash tray is the car's, saved with it (server)

Before: on a server each player's tray was their own, forgotten at the end of the session.

On the local server with two players (two machines or two game instances, one each; split-screen also works):
1. Player A in the driver's seat opens the tray. Player B in the passenger seat sees it open within a moment.
2. They swap seats (the dash's controls are the driver's, as before); player B shuts it; player A sees it shut.
3. Both get out; player B gets back in later: the tray as it was left. Another car's tray is its own.
4. Restart the server and rejoin: the tray as it was left.
5. Clicking fast: the tray answers (each press shows at once on your dash); the server takes one press each half second
   a player, so a very fast double click may settle back to one change. Nothing in the server log but ZeD's usual lines.
6. Single player: as before (it was always kept with the save).

Mouse first; then a pad on the dash (player 1 only) pressing the tray.

## 4. French and Hungarian month words

Before: "3 Jan 1993" in French, "1993 Jan 3." in Hungarian. Now lower case: "3 jan 1993", "1993 jan 3.".
Languages FR and HU: the Journal's entry dates, the server ticket and log cards' dates, the main menu's save and played
dates and the Mods screen's "updated" date. English, German and the rest unchanged. Large text too (no width change:
the words kept their length). A native speaker's pass on the short forms (French writes "janv.", Hungarian "jan.") is
still open.

## Untested

Nothing here has run in the game: no in-game run was allowed for this build. The split-screen and server parts need
two pads and the local server.
