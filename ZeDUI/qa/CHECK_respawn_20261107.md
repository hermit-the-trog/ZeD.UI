# In-game check: back to the desk after a death (B3), Nov 7 2026

What changed: Restart on the death screen and a second controller's "Add new player" no longer show the game's own character screens over the world. The desk comes up over the world (the room, the monitor switching on, the menu bar with only the ZeD menu), and the next survivor is made in ZeD's Spawn, Traits and Looks windows, as in a new game. The game still makes the character: same world and save in single player, same connection on a server.

Code: `42/media/lua/client/ZeD/Overrides/Respawn.lua` (new), small changes in `ZeD_MainMenu.lua`, `ZeD_MainMenuSpawn.lua`, `ZeD_MainMenuTraits.lua`, `ZeD_MainMenuLooks.lua`, `ModSupport/ThisIsYourLife.lua`. Sim: `ZeDUI/tools/qa/respawn_sim.lua` (128 checks, the game's own respawn files).

After the review (Nov 7): Play switches the desk off with the CRT switch-off (the same as starting a game from the main menu) before the character is made; the pad goes to the server name step when Back shows it; This Is Your Life's town opens its Hometown window on the respawn desk too; Escape and B on an empty monitor go back instead of doing nothing; Random never lands on the mod's town or a "with player" place and says so when there is nothing to land on; Return after typing a name keeps the name; pop-ups stay on the monitor at Deck size.

Sizes: 4K fullscreen at 1.75x (the usual QA setting), then Deck 1280 x 800 at Auto with Normal and Large text. Mouse first, then pad. The QA save (Saves/Sandbox/ZeD-QA) only; close the game after.

How to die quickly: god mode off, then `getPlayer():setHealth(0)` in the debug console, or the bridge's kill if the runner has one. Wait the three seconds for the death alert.

## 1. Single player, mouse (4K)

1. Die. The ZeD death alert shows (gravestone, the record, Shut down | Main menu | Restart).
2. Click Restart.
   - The world disappears behind the desk: the room picture, the monitor dark, then the CRT switch-on (dot, line, picture).
   - The menu bar shows only the ZeD logo and the clock. The ZeD menu opens to the About block only (no Credits, Terms, Report bug). No File, Multiplayer or Settings menus.
   - The case's power button does nothing (no "Exit" hint, no quit question).
   - The Spawn window is on the monitor: the towns and Random ("With player" places show only in split-screen or when a server allows them), the map and the town's words. No save name or seed fields.
3. Pick a town, Next: the Traits window (occupations, traits, points). Next: the Looks window with the 3D figure.
4. Back from Looks: Traits. Back from Traits: Spawn. Back from Spawn: the death alert again, the desk gone, the world behind it.
5. Restart again, through to Play.
   - Play: the monitor switches off first, as when starting a game from the main menu (the picture squeezes into a bright line, the line into a dot, the dot fades, the hard disk light flickers), about half a second. Then the desk goes. Clicks, keys and the pad do nothing during the switch-off; Return or A pressed again does not make two characters.
   - The desk goes; the new character stands in the chosen town in the same world (same day and time, same save; the old body is where it fell).
   - Check the name, occupation, traits and clothing are what was chosen.
   - The HUD, belt and windows come back as before the death.
6. Random on the Spawn window: Next goes to a town (never "With player"); Play lands there.
   - Random with nothing to land on (only "With player" places and Random in the list, e.g. a split-screen respawn on a map mod with one town that is This Is Your Life's): the words under the map say there is no town for Random to pick, and Next is greyed. Hard to set up; note it if seen.
7. Keys: Return on Spawn and Traits goes Next, on Looks plays; Escape is Back on each (and from Spawn back to the death alert). Escape does not open the pause menu while the desk is up.
8. The fields: on Looks click the forename, type, Return; the name sticks to the made character.
   - Return after typing a name: type a forename quickly and hit Return straight after the last letter. The field lets go, the typed name stays in the field (the old name does not come back), and the same Return does not press Play. Then Return again plays, with that name.

What should not happen: the game's black character screens over the world; the pause menu's bottom panel or the pause window changing after this (open the pause menu once the character is made: Resume, Options, Save and Quit all there).

## 2. Single player, pad (4K, then Deck)

1. Die with the pad. Restart is A.
2. On the desk: the footer shows pad prompts. D-pad walks the towns, A picks / Next, B is Back on every window, X random, Y builds (Traits) / outfits (Looks), LB / RB turn the figure on Looks.
3. Y on Spawn does nothing (no Terms of service).
4. A name field on Looks opens the on-screen keyboard; typing and closing returns the pad to the desk.
5. Through to Play: the new character takes the pad (moves, the radial wheels open).
6. Back from Spawn: the death alert, A / X / B on its buttons again.
7. A pop-up with the pad (Looks: the pose and outfits pop-ups; Traits: the builds pop-up): D-pad walks its rows, A picks, B closes it.

## 3. Deck size (1280 x 800 Auto, Normal and Large text)

Repeat 1.2 to 1.5 with the mouse. The desk should lean in (the monitor whole on the screen) as the main menu's New Game does at this size. Every window fits the monitor: the Spawn list and map, all three Traits columns, the Looks rows with the figure. Nothing cut at the foot (the band's Back and Next are reachable). Large text: the same, rows scroll.

Pop-ups on the monitor: open each pop-up (Looks: the pose button beside the figure, Outfits in the band, a clothing row's list; Traits: Builds in the band). Each stays inside the monitor's picture, top to bottom and side to side, never over the desk's wood or the bezel; a long list that does not fit scrolls inside the monitor. Same at 4K for comparison.

## 4. Split-screen: Add new player (pad 2)

1. With player 1 alive, press A on a second controller, Add new player.
2. The game pauses (the game's own rule) and the desk comes up full screen, driven by pad 2 only. Player 1's mouse and keys do not move the desk's windows' focus (the mouse can still click).
3. Through to Play: player 2 appears; the screen splits; the game runs again.
4. Again, but Back out from the first window: the desk goes, the game runs, no player 2.
5. Watch for ZeD HUD pieces of player 1 drawn over the desk (dash, watch, moodle hover): note any.

## 5. Multiplayer (the local server kit: zedqa_run -Mp)

1. Die on the server. Restart: the desk, Spawn shows the server's choices (the server spawn point, a safehouse when the server allows it, "With player" only if the server options allow it).
2. Play: the character is made on the same connection (no reconnect, no loading screen); the server's chat and the Server tab work after.
3. A second split-screen player on the server: the game's own name step shows over the world first (the desk hidden), then Next brings the desk with Spawn. Play: player 2 joins under that name.
   - Back to the name step with the pad: on the desk's Spawn window press B. The game's name step shows over the world (the desk hidden) and pad 2 drives it at once: the name field takes the pad's keyboard, D-pad down reaches its Next and Back, A on Next brings the desk back with Spawn and pad 2 on it. B on the name step goes back to the game (no player 2).
4. A server with DropOffWhiteListAfterDeath: Restart is not offered (unchanged).

## 5b. This Is Your Life on Restart (the mod subscribed and on in the QA save's mod list; Workshop 3773911887)

1. Die, Restart. The Spawn window lists the mod's town "This Is Your Life" with ZeD's words for it.
2. Pick it, Next: the Hometown window (ZeD's Spawn window again, the mod's hometowns with their origin trait, then the poster stories in single player). Not an empty monitor.
3. Back on the Hometown window: the town list. Escape the same.
4. A hometown, Next: Traits, then Looks, Play (the CRT switch-off). The character starts in that hometown, with the mod's origin trait and its map reveal.
5. Again with a poster story: the mod's own occupation and looks screens run (they fill themselves in); the desk may show behind them. Note what shows, and whether the pad reaches the mod's screens.
6. Random on the town list, several times: never the mod's town, never a "With player" place.

## 6. Safe mode

1. ZeD setup, Safe mode On. Die, Restart: the game's own screens (black panels over the world), as vanilla. Turn Safe mode Off: the next death gets the desk.
2. Restart with the pad, then with the desk up press Escape on the keyboard (with the mouse, Escape belongs to the desk; the pad's Start is not taken on the desk, as on the game's own screens) for the pause menu, Options, Mods, ZeD UI, Safe mode On, Resume: the desk goes and the death screen (the game's own now) is back. Restart: the game's screens.

## Things to note, not fix on the spot

- The new wallpaper (the title video) on the monitor in game: does it play, or does the painting stand in?
- The town videos on the Spawn window in game.
- Any frame where the world shows between the death alert and the desk (expected: none, the desk goes up the same frame).
- The pause menu by keyboard Escape over a pad respawn: the desk hides while it is open and comes back on Resume.
- After Play: the moment the world comes back (the CRT switch-off done) against starting a game from the main menu: the same feel.
