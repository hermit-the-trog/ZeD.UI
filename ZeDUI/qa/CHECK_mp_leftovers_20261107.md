# Check: the multiplayer windows the game still opened (Nov 7 2026, Build)

What changed (ZeDUI/VANILLA_WINDOWS_20261107.md, rows C1 to C5 and C15 to C17). Every one of these used to open the
game's own window over ZeD. Now each is ZeD's, through the game's own data and calls, and each falls back to the game's
window in safe mode.

| Row | Where | Now |
|---|---|---|
| C1 | Pause window > Players; D-pad Up social wheel > Players | A page of the pause window: the players, a pick, the game's actions for that player under the list |
| C2 | Server tab > See server options; Admin tab > More tools > See server options | A card in the Server tab, the options to read; staff who may change options get Change (the game's window) in its foot |
| C3 | Pause window > Invite (a Steam co-op host) | A page of the pause window: Find, the Steam friends, Invite in the band, Allow / Deny on a co-op host |
| C4 | The server saving | A notice in Messages (the belt's bubble), kept there |
| C5 | Maps tab on a server > right-click (or X) on your own mark > Sharing | A card in the map's drawer, at the map's right edge: Private, Everyone or Other (Faction, Safehouse, players), Accept in the band |
| C15 | Admin: inventory right-click > Debug > Edit item | The item's card in edit mode: the game's fields, Save in the band |
| C16 | Any admin pop-up (not the ticket note for staff) | A note in Messages; Teleport on it when the game's asked "Teleport?" |
| C17 | Kicked, banned or the connection lost | The desk comes back: a ZeD window on the monitor with the reason, for a ban the appeal line, Quit to desktop and Exit |

Sims (no game needed): `lua51 ZeDUI/tools/qa/mp_leftovers_sim.lua` (199 checks), plus the community, tickets and admin
card sims, all passing. The game was not launched for this build.

## Setup

- The local server kit: `tools/qa/mp_server.ps1 -Start -Mods ZeD_UI`, then `zedqa_run.ps1 -Mp` (joins as the server's
  admin). For two players (C1's actions, C5's player list, C17's kick and ban): `batch_two_b7.ps1` (the admin and bob).
  Remember `ZEDQA_NOSTEAM=1` and the QA lock. Put the server's database and ini back after.
- Sizes: 4K fullscreen at 1.75x, and the Deck (1280x800, Auto, Normal then Large text).
- Mouse, then controller, at each size.

## C1 Players

1. Escape > Players. The pause window widens and shows Players with "N connected" under its head, a row per player
   (yours says "(you)"), each with its ping. Nothing of the game's scoreboard shows.
2. As bob (a plain user): pick the admin's row. Under the list: Mute and Voice mute only. Mute, then the admin types
   in chat: bob does not see the line in ZeD's chat. Mute again (now Unmute) brings it back.
3. As the admin: pick bob's row. Teleport, Teleport to you, God mode, Invisible, Kick, Ban, Ban IP show (as the role
   allows). Teleport goes to bob. With ZeD's server part, Kick (and Ban, Ban IP) closes the pause window and opens
   the World window's Admin tab on bob's player card, which asks for the reason; kick him from there (he sees C17).
   Without the server part, Kick asks in the band ("Kick Bob from the server?"); Cancel leaves bob on; answer: kicked.
4. Your own row: only God mode and Invisible (by role), no Kick or Mute.
5. Refresh asks the server again. Back returns to the pause list with the controller on Players.
6. Controller: D-pad through the rows and the action buttons, A picks, B on a question is its Cancel (back on the
   button that asked), B otherwise goes back. With many players (a modded server, or mp_server with bots if the kit has
   them) the list scrolls by D-pad past its last row and by the wheel; the bar at its right drags.
7. D-pad Up social wheel > Players opens the same page.
8. Deck, Large text: the window fits the screen, names truncate before the ping, no text overlaps.

## C2 Server options

1. Character window > Server tab > See server options: a card titled Server options, one row per option, name at the
   left and value at the right (or under the name when long). Booleans read Yes / No, enums in the game's words.
2. As a plain user: no Change in the foot. As an admin with Change and reload server options: Change opens the game's
   own options window.
3. Admin tab > More tools > See server options: the Character window opens on the Server tab with the same card.
4. Controller: D-pad steps down the rows (each a stop, nothing to press), the card scrolls with it; B goes back.
5. Change an option from the game's window: within 5 seconds the card shows the new value.

## C3 Invite (Steam only: run from a Steam co-op host, not the no-Steam kit)

1. Host a game, Escape > Invite: a Find field, then the friends in the game's order (online first), each with a state
   square and word. Type part of a name: the list narrows; no match says so. Controller: A on Find opens the on-screen
   keyboard. Back and Invite again: the words are still in Find.
2. Pick a friend, Invite: the line "<name> invited!" shows for three seconds and the friend gets the Steam invite.
3. On the co-op host: Allow / Deny in the band and an Allow / Deny tag on each row. Back, then Invite again: the tags
   are as you left them (the game's invited.ini kept).
4. No friends (a fresh Steam account): "No Steam friends to show."

## C4 Server saving

1. On the server console: `save` (or wait for the autosave). "The server is saving the game. Please wait." arrives as
   a notice out of the belt's Messages icon (a toast if toasts are on) and stays in Messages under Admin. Nothing at
   the top of the screen or in a corner; the game's box with Spiffo does not show.
2. Safe mode on: the game's box.

## C5 Map mark sharing

1. On the server, put a mark on the map, right-click it > Sharing: a card in the map's drawer, against the map's
   right edge, no taller than the map. It starts as the mark is shared now. Also in the unfolded map window. It moves
   with the World window, cannot be dragged off it.
2. Everyone, Accept: bob sees the mark on his map. Other with Faction (when in one): only faction members see it.
   Other with bob ticked: bob sees it, a third player does not.
3. Faction, Safehouse and the players are gray unless Other is picked.
4. Cancel (or the close box, or B) changes nothing.
5. Controller: X on the mark > Sharing, the card takes the pad: D-pad down the rows to the band, A ticks or picks, B
   cancels and the map takes the pad back.

## C15 Edit item (admin)

1. As the admin, right-click an axe > Debug (or the admin's submenu) > Edit item: a card with the item's picture and
   name, the item type and file name as plain facts, then Name, Weight, Condition and the weapon's fields as fields.
2. Change the name and condition, Save: the item shows the new name; a condition over the item's maximum is held to
   it. Fields left alone stay exactly as they were (the weight keeps its full figure).
3. On a dyed shirt: the Color row's square opens the game's color picker; pick, Save: the shirt changes color.
4. Cancel writes nothing. Controller: A on a field opens the on-screen keyboard.
5. On another player's item (Admin tab > Player card > Inventory, then Edit item): the change reaches that player.

## C16 Admin messages

1. Make the server send an admin message to staff (a ticket on a client without AnswerTickets, or a check that sends
   one with a place). It arrives as a note in Messages (the belt's envelope, a toast if toasts are on), not a pop-up.
2. A message with a place: the note has Teleport; Teleport takes you there.
3. Safe mode on: the game's pop-up instead.

## C17 Kicked or disconnected

1. Kick bob (C1 step 3). On bob's screen: the desk comes back (the room, the monitor), and on the monitor a window
   "Disconnected" with "You were kicked from the server." and, in a dark slot under it, the game's own words for the
   kick. No appeal line for a kick.
2. Ban bob (with ZeD's server part and an appeal line set in Rules and news): "You were banned from the server.", the
   game's words in the slot, then "Appeal: <the appeal>".
3. Stop the server while joined: "The connection to the server ended." with the game's "Connection to server lost".
4. Check the game's line sits inside the dark slot at 4K and on the Deck, Normal and Large text (the engine draws it in
   the middle of the screen; the slot is placed for it). A long reason widens the window, never past the screen.
5. Exit (the main button) goes to the main menu; Quit to desktop quits. Controller: A on Exit; B moves to Quit
   without quitting.
6. Safe mode on: the game's own screen with its two buttons; a ban's appeal line under the game's words, none for a
   kick.

## Not covered by the sims

What the engine does: real fonts and widths, the engine's line landing in the slot, the focus landing, the on-screen
keyboard, Steam's friends and invites, a real kick and ban, the server's own saving events.
