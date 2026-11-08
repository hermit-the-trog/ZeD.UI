# Outside review of 0.3.0-beta8 (Mac test rig, Nov 8 2026)

Pasted by the director on Nov 8 2026: a Mac rig QA of the live beta 8 (42.21, no Steam). It combined eight parallel code reviewers with in-game single player and a local server played with one client at a time. That rig found no ZeD Lua errors.

**QA spot-check (main, Nov 8):**
- #2 is confirmed: `ZeD_AdminUsers.lua:554` reads `D.fieldText`, which is `box:getText()` (`ZeD_TicketCards.lua:437-440`). On a masked box that returns the stars.
- #9 is intended: the director ruled Nov 7 that a mod which replaces a screen gets it back. Our in-game run passed 4/4 with Character Info handed to Wounds Overhaul.
- #1's cause is the reviewer's trace, not re-run here.

## Findings
| # | Sev | Where | What |
|---|---|---|---|
| 1 | High | Pause > Sandbox options (single player, "Sandbox options in game" on) | Every control is dead: pages, values, Close, Undo, Apply. Hover, help and Find work. Cause (traced): `ZeD_MainMenuOptions.lua:1857`. Each update the main-menu pointer runs for the hidden in-game Options window first, with the shared click state, and takes the press, so the Sandbox window (derived from it) never gets one. After Escape, the next Escape reopens the pause screen into the stuck window. |
| 2 | High | Admin > Users > account card > Set password | Sends the masked stars. Fix: read masked boxes with `getInternalText()`. |
| 3 | Med | Mail "reported letter" tickets | A forged report (`ZeDT t_new {kind="GRIEF", report={letter=true, ...}}` from a client) shows to staff as "The reported letter ... As the player received it." The server never saw the letter. Fix: say, as the chat report does, that the server keeps no copy. |
| 4 | Med (review) | Timed ZeD bans | They also set the game's ban, which resets the account's role to `user` when it ends. |
| 5 | Med (review) | Mail store | Letters are silently dropped and deleted after a server's mail table starts over (a wipe, or a new save on the same address). |
| 6 | Med (review) | Identity > Make Up | A make-up item picked from its own Make Up option is never re-checked: it works after it is used up, dropped or stored. |
| 7 | Med (review) | Post-death desk | The ZeD menu lists CletusWorks and Mail. Picking either blanks the monitor; Escape is the only way on, and it loses the traits and looks picked. |
| 8 | Med (review) | Second controller | An unused plugged-in controller throws a Lua error every frame after its first A press. |
| 9 | (intended) | Step aside + Wounds Overhaul | WO is not on the supported list, so Character Info is handed back. That's the Nov 7 ruling. |
| 10 | Low | Server tab > See server options > Change | Opens the game's SERVER OPTIONS window, and under the ZeD windows. |
| 11 | Low | Mail | A letter to an existing account that hasn't joined since beta 8 bounces ("nobody called qa_player1 has joined this server since it began keeping mail"). This hits every server that updates. |
| 12 | Low | CletusWorks / Documents Rename | The name is pre-filled but not selected, so typing appends. |
| 13 | Low | Loadouts > Restock (Casual) | The weight check runs once per batch: from 9.3/12 kg it took a bat and an axe, ending at 14.3/12 (`ZeD_Restock.lua:1071`). |
| 14 | Low | Dashboards (Metric), Luxury and Cossette plates | KM/H beside an odometer in unconverted miles with no unit ("43507 ODO"). The code cites a director rule; needs a ruling. |
| 15 | Low | Maps > unfold | The unfolded paper map opens behind the World window. |
| 16 | Low | Identity card | The portrait goes blank (plain blue) while an item card is open. |
| 17 | Low | Desk icons | The menu samples the mouse every 100 ms, so a quick double-click can count as one click (Mail failed to open 4 of 4 injected double-clicks). |
| 18 | Info | Mail > Reply in game | Fills To and "Re:" but doesn't quote; the desk app's Reply quotes with "> ". |

## beta 7 items still open (their review)
- Custom radio snap-back.
- Foraging drop-down hidden option.
- Phantom `require` ids.
- Ticket double-answer and stale card (beta6a #9/#10).
- Claims invitation/decline (beta7 L5/L6).
- Odometer presses unthrottled and undone by SYNC.
- Miles not counted while the dash is hidden.
- Emoji truncation.
- Kill-credit drift.
- Belt per-frame allocations.
- Journal drawer question still clipped.
- Stats fallback routes (ticket cards when the Admin tab can't show, the game's own admin panel).

## Review-only lows
- **Mail:**
  - One player can push every waiting letter out of an offline player's 50-letter box.
  - A mute made within 2 s, or while not dialed in, never reaches the server.
  - A dropped "got these" reply stops letters past the first 10 for the session.
  - An Outbox letter opened in game shows "nil" as its author.
  - Nothing ends a trade when its player dies.
- **Admin:**
  - The Edit item color swatch opens the game's color picker.
  - Unban by Steam ID can lift the name ban instead.
  - The Zones card shows the raw key `IGUI_PvpZone_ZoneInterception` (missing from the game too).
  - A second account on a banned Steam ID causes three false "ban did not take" rounds.
  - A split-screen guest is refused every ZeD command when join rules are on.
- **Main menu:**
  - The Options sub-pages leave the main Find field drawn over them.
  - Rename + Return in Documents also opens the note.
  - Players > Kick/Ban does nothing when windows are handed to the game.
  - Leaving Options through the menu bar leaves a pad test or sound preview running.
- **Looks:**
  - Remove make-up takes the item out on the client only.
  - One mirror verdict is applied to every row.
  - The paused look resets `activeWhilePaused` for other ZeD windows.
- **Character:**
  - The TV-schedule fallback searches for "[" where Java prints "{".
  - The infection page needs a First Aid volume a high-skill character can't read.
  - Drainables never show "Remaining %" (`getUsedDelta` only exists on Clothing).
- **Radio/vehicle:**
  - The ash tray is never reconciled after a server refusal.
  - The heater wheel slice opens the game's window for split-screen players 2-4.
- **World/HUD:**
  - Device Options on a radio 10+ tiles away falls through to the game's window.
  - Per-frame allocations in the belt, notice balloons and map extension.
  - No clock-back guard in the new clock-based timers.
  - The hint strip's "First hours" searches every frame.
- **Crafting/misc:**
  - Craft greyed with no reason given.
  - The Read label falls back to `ISMediaInfo`.
  - Log furniture opens the game's entity window (deliberate).
  - The general station view refreshes every 20 frames.
- **Translations:** 3-12 of the ~500 new keys per language are still English.

## Their rig left on purpose
On their server: ticket #22 in Spam; qa_player1 muted, logging in with Invisible/God/NoClip (origin unknown).
