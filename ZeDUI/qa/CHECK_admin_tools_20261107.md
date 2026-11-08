# Check: the admin tools as ZeD cards (C9 to C14), Nov 7 2026

What changed: the Admin tab's Users row and More tools now open ZeD cards in place of the game's windows.

- **Users** (new row above Safehouses): the users card and one account's card (`ZeD_AdminUsers.lua`).
- **More tools > Show statistics, PVP Log Tool, Climate control, Zone editor**: ZeD cards (`ZeD_AdminTools.lua`, `ZeD_AdminZones.lua`). Non PVP Zone and Add Safezone are now inside the zones card, and See users moved to the Users row.
- **More tools > Sandbox options**: ZeD's in-game sandbox window over the pause screen, with Apply sending to the server (`ZeD_SandboxInGame.lua`).
- The Log row without ZeD's server part opens the PvP log card.

Still the game's own windows: See server options and Check your stats.

Sims: `admin_tools_sim.lua` (51,260 checks) covers every state at Deck, 720, 1080, 4K and the narrow stand-in, Normal and Large text, mouse and pad. It also walks every flow against the game's calls. The game itself has not run any of this yet.

## The rig

Use the local server kit. Never use a real save.

```
pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"
pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp
```

- Join as an admin (admin role).
- For the gray checks, join a second client as a moderator or a plain user.
- Run once without ZeD's server part (Log row), then once with it.
- Run each pass at 4K 1.75x and at Deck 1280x800 Auto (Normal and Large text), with the mouse and then the controller.

## Users

1. **Users row.** It opens the card.
   - Online accounts come first, with role tag, "online" or the last connection, and warnings.
   - With more than 25 accounts there are Previous and Next buttons.
2. **Find.** Try a name, a role and a banned IP.
   - Online only keeps online accounts.
3. **Add user.** Empty shows gray "Write a username first". An existing name shows gray "has an account already".
   - A new name: the server log shows the user added. After about 5 seconds the list shows it.
4. **Banned IPs / Steam IDs row.** It opens the Bans card. B goes back to the Users card.
5. **An account.** Check the role, Online and ping, auth type or (Not in whitelist), last connection, warning, suspicion and kick points, Steam ID, and the IP or Steam ID bans.
   - **Player card** opens the existing Player card.
   - **Set password** opens a field under Account with Cancel beside it, and Set password in the foot.
     - Empty: gray.
     - Typing shows stars, never the letters, including when a pop-up covers the field.
     - Typed: sends. Log in with the new password on the second client.
   - **Reset password, Reset TOTP Secret, Delete:** each asks in the foot (Keep it / the verb). Keep it does nothing.
   - **Delete:** the account card goes back with "account is gone".
   - **Ban by IP / UnBan by IP**, and on Steam **Ban by Steam ID / UnBan:**
     - Gray on yourself, on an admin (CantBeBannedByUser), and offline ("User is not online").
     - The Unban button appears while a ban is held.
6. **Gray checks** (moderator client): every button that role lacks stays on screen, gray, and says the capability and the role that has it.
   - Gray: an account whose role ranks above yours ("Their role sits above yours").

## Statistics

- The three tables show this client and the server, about once a second. Numbers not received yet show "-".
- The Show ticks hide and show each table.
- B, closing the World window, or leaving the tab: after about 2 seconds the server stops sending.
  - Check with the network numbers on a second admin's statistics.
- Opening the card again starts the numbers again.

## PvP log

- Use two clients with PvP on. A hit or a kill puts a line in, within about 10 seconds, newest first, in the Log card's style (PVP tag, time, place).
- Pick a line: Go there teleports you (gray without TeleportToCoordinates).
- **Send to chat** and **Write to file:** server options.
  - Gray without ChangeAndReloadServerOptions.
  - After a change, B sends /reloadoptions. Check the option in See server options.
- **Clear:** asks first. Gray with no lines.

## Climate

- **Apply** is gray ("Nothing changed yet") until a tick or a slider changes.
  - The foot then says "Not applied yet", with Revert and Apply.
  - X (controller) is Apply.
- Each slider moves with - and + (a twentieth of its range). The mouse sets it where the bar is pressed.
- **Apply:** the server's weather follows: wind, clouds, fog, rain or snow, temperature, darkness, desaturation, the light color.
  - A second admin's card shows the same values within a second.
- **Revert** returns to what the server holds.
- **Precipitation is snow** is gray until Precipitation is ticked.
- **Stop current weather / Trigger storm / tropical / blizzard** act at once, for the duration slider's length.
  - **Generate** uses the strength slider and the warm or cold front chip.
- **The game bug ZeD does not copy:** the game's own window, on unticking Precipitation, turns off the Desaturation override by mistake. ZeD turns off the snow switch instead.
  - Check that Desaturation stays put when Precipitation is unticked.

## Zones

- **Non-PvP zones list:** each zone shows name, corners and size.
  - Pick one: Go there (the middle of the zone), and Remove (asks first, then the zone is gone on the ground).
- **See zone on ground** shows the zones' tint around you. B on the card turns it off again.
- **Add a non-PvP zone:** the name is ready ("Zone #N").
  - Add zone stays gray, with the reason, until the zone has an area bigger than one square that overlaps no zone.
  - The area tints on the ground: blue when it can be added, red when it overlaps.
- **Pick on the map:**
  - The Maps tab opens with the banner "Drag over the zone's area" and Cancel pick on the band.
  - Drag (mouse), or hold A from one corner to the other (controller cursor).
  - The Admin tab comes back with the area, and the focus lands on Add zone.
  - Gray "The world map is off on this server" when the sandbox map is off.
- **Corner here / Other corner here** set the corners where your character stands.
- **Add a safe zone:**
  - Owner must be an online player.
  - The area must not overlap a safehouse.
  - Add zone claims it. It shows in the Admin tab's Safehouses list.
- While the zones card is open, the map draws the non-PvP zones and the safehouses as tinted squares.

## Server sandbox options

- **More tools > Sandbox options:** the pause screen opens with ZeD's sandbox window. Its title stat says "This server".
- Change two settings, then Apply. The foot asks "Send 2 changes to the server?". Apply sends them.
  - The note reads "Sent 2 changes to the server. Every player gets them".
  - A second client sees the values in See server options.
  - History lists them for this session only.
- **Close** goes back to the game.
- Fixed settings stay locked as in single player.
- A moderator without SandboxOptions sees the More tools button gray.

## Not covered by the sims

These need the game:

- the engine's real text boxes and keyboard
- focus landing after the map pick
- the server's own answers
- the climate's real values
- the statistics toggle on a real server
- the pause screen opening from the World window in multiplayer
