# Known issues pass (Nov 5 2026, QA; the director: "Yes, run them all")

Runs on the working copy, 4K at 1.75x unless a line says otherwise. Reports in `qa/regression/2026-11-05_*`.

## The public list

| Issue | Result |
|---|---|
| This Is Your Life | Passes. A hometown (Muldraugh: place, origin trait, map, journal) and a poster story (Bake Sale: Marianne Cole, the mod's own screens) both start through ZeD's screens with no ZeD errors. Off the page. |
| Multiplayer | Radio keys reach the server (channel, volume and power held over a rejoin). Deck with Large text fits. Safety system off: no PvP line, no marker. Not testable here: a player without admin rights (a -debug client must be an admin, `getRoles()` is empty on the client, the server refuses /setaccesslevel on the logged-in account), and two players at once. The page says tested with one player, as an admin. |
| Hair and beard | The cause is Hands-On Interactions (Isometric) 2.9.0, not ZeD: `HO_Carry.lua` lines 92, 93 and 186 call `hasTag` with a string inside a pcall; in 42.22 it takes an ItemTag. A call that fits no overload puts one of the game's pool records back twice (`hb_bisect_20261105.txt`, `pcallwatch_20261105.txt`, `hands_off_20261105.log`). The game alone with no mods gives the same error after one such call (`pool_repro_20261105.txt`). The known issue stays and names the mod. |
| Survival guide clips | Stays: needs an encoder and recording time. |
| Machine translations | Stays: needs native speakers. |

## Off the public list

| Item | Result |
|---|---|
| Lag spikes | The Animals alert poller walked 22,801 squares every game minute (about 3.7 s), 25 to 30 ms each. Fixed by Build. Windows shut: 16 slow frames to 0, worst 44 ms to 20 ms. |
| Hold A controller check | A stale test (hold A marks since Nov 1). It now checks hold X, which passes. |
| Mod manager | Order 24, folders 36, by hand 78 pass with the round 4 mods; Profiles runs with no errors. The deleted Steam report itself was never seen. |

## Found on the way, fixed by Build

The Ranch page did not scroll or reach Totals, and its footer drew over the rows; a blank square at the left edge on a server with the safety system on; a Workshop query from the main menu could land during a load.

## Today's other checks

Right-aligned list headings, one-line buttons (Dark, High contrast, Light), the real scroll bar on every main menu screen at 4K and Deck + Large, the arrow step, the Ranch page with the pad (`zedqa_ranch_pad.lua`), the corkboard note at five sizes.

The full regression after all of it: 100 of 101, 0 fails; the WARN is dke's old key-start timing (wagon, suv). The pcall watch logged nothing from ZeD in that run.

Not done by hand: a mouse press on each in-game bar (Cooking, Mechanics, the Reader, Maps' side list, prompts' long notes). The regression ran those surfaces clean. The controller's four marks on buttons: the test board's rerun is in `zqa_bnl_*`.

Stray input, Nov 5 15:24: the first Deck scroll bar run sent five clicks and two wheel notches to screen coordinates meant for the game window, so they landed outside the game, at the left of the main screen. No effect was seen; the script now presses the real mouse in fullscreen only.
