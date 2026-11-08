# Outside review of 0.3.0-beta7 (Claude on the director's Mac, 42.21, no Steam), Nov 7 2026: QA's code check on 42.22.2

The full report is in QA's chat (the director pasted it Nov 7). Its rig files are on the Mac: `~/Zomboid/qa/data/review_beta7_*.md`, `~/Zomboid/qa/logs/beta7/`, `~/Zomboid/qa/screens/beta7/`. This file keeps each finding, where it is, and what QA checked here. QA ran nothing in game: Build's queue is still open and QA tests after it.

The headline: no ZeD Lua error in about 2.5 hours of single-player and server play. The beta 6a weapon-kills finding is fixed in game, and so are the firearm facts, picks after off/on and the offline Player card leak.

## Found by clicking
1. **Medium (carried from beta 6a #2): ZeD controls still open the game's own windows.** Clicked: Player card > Check stats (PLAYER STATS), Server tab > See server options (SERVER OPTIONS), pause menu > Players (PLAYERS). QA check: all three are already on Build's merged list `docs/reference/VANILLA_WINDOWS_20261107.md` as C6, C2 and C1. The review's other 10 (Manage inventory, More tools, other players' claims) are C7 to C13. Nothing new; it waits on the director's scope picks.
2. **Low/Medium: an item card covers the right half of the drawer tab.** Journal in the drawer with the "Delete the entry?" confirm showing; open a card from the inventory: the confirm text is cut at the card's edge and Save / Delete / Cancel sit under the card until it closes. Also seen over Skills and Equipped. Not checked here.
3. **Low: the Simple dash strip mixes units.** CONFIRMED in code: `ZeD_Dashboard.lua:1699-1701` always prints speed in mph, while the Odometer and Trip cells follow the game's measurement option (`_plainCells` :1605, `_distText` :1600). With Metric on, the strip shows `0 mph` beside `95507 km`. Fix: speed follows `_metric()` too (speed_kmh is already in the state, :315), or both stay miles.
4. **Low: deleting the active custom sandbox preset picks the wrong base.** Apocalypse + 1 change, save as preset, delete it: the header reads "Six Months Later, 36 changed". `ZeD_MainMenuSandbox.lua`. Not traced here.
5. **Low: name prompts open with a default that is not selected, so typing appends.** CONFIRMED for the sandbox preset: `ZeD_MainMenuSandbox.lua:573-575` sets the text and focuses it without `selectAll()`. The same file already does `selectAll` for numeric cells (:259). The review saw the same in traits Builds > Save build and looks Presets > Save preset.
6. **Low: Options > Find shows ZeD's own options as the game's combo boxes** under a "Mods" header, instead of ZeD's radio rows.
7. **Low, server: a forged spawn with a bogus module spawns the base item and logs the bogus name.** CONFIRMED: `ZeD_ServerAdmin.lua:1173` checks `FindItem(item)` (which falls back to a bare-type search) but then spawns and logs the client's string (:1176, :1181, :1188). Fix: use `found:getFullName()` for the spawn and the log; ack false when `AddItem` returns nil (the review's "acked but not made" case).
8. **Low, seen once: the Craft button enabled at Required 1/4** ("Make Advanced Framepack Frame"). Pressing it flashed CRAFTING, made nothing and moved the recipe into Frequently Used. Needs a second look.
9. **Low/UX: Mute from an offline player's card does nothing visible.** "..." then back; no server log, no refusal line. The server-side mute works.
10. **Low/UX: ZeD chat keeps "/w name" in the line after a whisper.** Vanilla-like.

## Review-only (code, not run on the Mac)
- Dashboard: stem and ODO/TRIP presses unthrottled (each re-broadcasts the car's modData); a press made while the client is behind the server is undone by the SYNC answer; no miles count while the dash isn't drawing (UI hidden, safe mode).
- Kills: a run-over zombie that wasn't chasing someone in the car is counted by the game but not in ZeD's Vehicle row; `testCollideWithVehicles` kills count in the row but not the header; an MP client's fire kill of a remote zombie counts nowhere; book facts follow `getPlayer()` (beta 6a #11, plus `ItemCardOrganism.lua:605`).
- Admin/MP: an accepted invitation the server never applies is lost for the session (`ZeD_Claims.lua:452-477`); a decline while a yes is in flight never reaches the server.
- Mods/presets/widgets: the Custom preset radio with no custom file snaps back but marks "Changed" (`Settings.lua:792-809`); `ZeD_Dropdown` picks a scrolled-off option on a header click (`Molecules.lua:1451-1466`); `truncateRaw`/`shortName` can split an emoji; a missing `require` leaves a phantom id in the load order (vanilla parity).
- Still open from beta 6a: the ticket answer can post twice (`ZeD_TicketCards.lua:1388-1403`, not reproduced); a stale ticket card after Back (`TC.back`).

## Not covered on the Mac
Two live clients at once, right-click menus, real controller input, window resize by the grow box, fire/explosion/vehicle kills in game. The QA rig here covers right-click, the controller and two live players: they go into QA's pass once Build's queue is done.

## Left on the Mac rig
qa_player1 is muted on the local server; NoClip is on for qaadmin; `caffeinate` is still running (`pkill caffeinate` ends it).
