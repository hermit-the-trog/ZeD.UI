# Check: the last vanilla windows at the main menu (Nov 7 2026, Build)

What changed: seven of the game's own windows at the main menu and in Options are ZeD windows now
(VANILLA_WINDOWS_20261107.md, section A and D1). Not opened in game yet: this is the list for QA.

Run each at **4K fullscreen at 1.75x** and at **Steam Deck size, 1280x800 at Auto, Normal and Large text**. Each with the
**mouse**, then with a **controller** only. For every window: nothing runs off its edges, the band at the foot holds the
answers, the controller lands on a sensible button and can reach every one, B (or Escape) leaves and the help line
says what the button under the pointer does. Then once with **safe mode on** (Options > Mods > ZeD UI): the game's own
window must show instead, and work.

Sim (no game): `lua51 ZeDUI/tools/qa/mainmenu_vanilla_sim.lua` (159 checks; it runs the game's own screens from the
install). It proves the routing, not the look.

## 1. Server Workshop items (joining a server whose Workshop mods you lack)

- **Needs Steam mode** (the game builds this screen only with Steam; QA's usual `ZEDQA_NOSTEAM=1` runs never reach it).
- How: unsubscribe from one Workshop mod a server needs (a small one), then Multiplayer > Join a server > that server >
  Connect. The local MP kit server works if its `WorkshopItems=` lists that mod.
- Should show: the Connecting window, then a window titled "Server workshop items" with the game's line "The server you
  are joining requires these Steam Workshop items", a row per mod (its Workshop ID until Steam sends the details, then
  its name, size and state with a square: gray not subscribed, orange blinking while it downloads, green installed).
  While one downloads, a bar and "x of y MB" on the right of its row.
- Band: **Disconnect** | **Install** (Install grayed until the details arrive, and again once pressed).
- Install: the rows go to Downloading, then Installed. Then the **Connecting** window comes back by itself and follows
  the join to the end (the game's own showed an empty screen here). Joining goes on to Spawn / Character, or the game.
- Disconnect: back to Connecting, which then returns to Join a server.
- Pad: lands on Install once it is live (Disconnect before that); up walks the mods (A on a mod does nothing), Y
  installs, B disconnects.
- A Steam error (rare: hard to force) shows the game's words in the line above the list with a red square, and
  Install grays.

## 2. Server invite and Connect to

- **Server invite** (Steam): accept a friend's invite to a dedicated server, or start the game with
  `+connect 127.0.0.1:16261` with the local MP server up. Should show: a window "Server invite" on the monitor, the
  address large, an orange blinking square and "Contacting server...". Band: **Cancel** while it asks, **Back** once it
  failed ("The server failed to respond", red square). Cancel / Back: the main window again.
- **Connect to**: the same launch without Steam (`-nosteam +connect 127.0.0.1:16261`), or after the invite above finds a
  dedicated server. Should show: "You are about to connect to:", the address large, then Server password, Account
  username, Account password (filled from the last account used on that address) and the Use Steam Relay tick
  (Steam only). Empty the username: Connect grays and the game's "Please enter a user name." shows under it with a
  red square.
- Band: **Cancel** | **Connect**. Connect goes to the Connecting window with the name you typed (check the server's
  log or the player list); Cancel goes back to the main window.
- Pad: lands on Connect (on the username when it is empty); up walks the fields and the tick; A on a field brings up
  the on-screen keyboard; B cancels.

## 3. World select (map mods that make a second map group)

- How: turn on a map mod that is not merged into Kentucky (one that starts its own world), then New Game > Sandbox >
  Next. Also: from Sandbox options press Back.
- Should show: a "Select world" window on the monitor: a card per world on the left (a map square, the world's name,
  "n maps" and their names), the chosen world on the right (its name large, then each map with the game's
  description). The title bar counts the worlds.
- Band: **Back** | **Next**. Next goes on to Spawn (or Sandbox options) for the chosen world; check the started game is
  on the chosen world. Back: New Game. Double-click a card: Next.
- Pad: lands on the chosen card; up / down choose (the right side follows); A on a card is Next; B is Back.

## 4. Terms of service

- From the menu: the ZeD logo menu > Terms of service and **Y** on the main window with a controller.
  Should show: "Terms of service and privacy notice" on the monitor, the game's text in a box and the band **Back** |
  **Quit** | **View terms of service** | **View privacy policy** | **Accept**. View opens the page in the Steam
  overlay (or the browser without it). Accept or Back: the main window. Quit asks nothing (as the game's): it quits.
- First run: quit the game, set the terms version to 0 (in `Zomboid/options.ini`, the line for the terms of service
  version), start the game. Should show: the same window on its own, centred on the black start-up screen, with **no
  Back**; Accept goes on to the main menu (and the window must not come back on the next start); Quit quits.
  Mouse and pad both. If it shows the game's own window instead (a gray panel with Spiffo the judge), say so: that
  means ZeD's files were not loaded yet at that moment.
- Pad: lands on Accept; left / right walk the answers; up / down scroll the text.
- Also: Y on any other monitor window (Connecting, a New Game step) no longer jumps to the terms; only the main
  window's Y does (its footer says Legal).

## 5. Button map and test (Options > Controls)

- How: Options > Controls > the "Button map and test" row > Open controller setup. Desk and in game (pause > Options).
- Should show: the Options window's page "Button map and test": at the top "Test controller" with a pull-down; on the
  left a pad drawn in ZeD's lines with ZeD's button pictures for your pad style (Xbox, PlayStation, Steam Deck); on the
  right every button, both triggers and both sticks with what each does in game ("Nothing" when unbound).
- Live: with a controller in hand, every held button lights on the drawing, the triggers fill, the sticks' dots move.
  Pick your controller in "Test controller": the controller now only tests (the game's rule); hold **A and Y** together
  to end the test.
- Edit: click a row (or A): a pull-down lists the actions, the bound ones ticked; pick one to add or take it off. The
  row's words change, the title bar says Changed, Apply lights. Apply, leave Options, play: the change holds. A fixed
  preset becomes a new one, as in the game.
- Band: **Back** (to the Controls page) | **Apply**.
- Check the drawing's layout at 1280x800 Large text (it is the tightest).

## 6. Advanced game sounds (rare)

- How: only when the game's advanced sound options are on. In a `-debug` run, the Lua console:
  `SystemDisabler.setEnableAdvancedSoundOptions(true)`, then close and reopen Options. Options > Audio > Advanced.
- Should show: a page "Advanced game sounds" in the Options window: the game's categories on the left, each sound
  with a slider, its percent (0 to 200) and Play.
- Drag a slider, press Play: the sound plays at that level; Stop stops it. Leave the page, quit the game, start it
  again: the level holds.
- Pad: lands on the first sound; left / right step it by 5 percent; A plays; LB / RB change category; B back.

## 7. Tutorial

- File menu and the main window: the item reads "Tutorial (the game's own, without mods)". It starts the game's
  Tutorial as before (without ZeD). The help line under the button says so. Check all of the label fits the main
  window's button at 1280x800 Large text.

## Not built (left as the game's)

- A7: the server settings editor for a server whose mod list reloads Lua (the reload drops ZeD until Save or Cancel).
