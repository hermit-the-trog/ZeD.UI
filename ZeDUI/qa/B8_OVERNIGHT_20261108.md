# Beta 8 overnight QA, Nov 7 to Nov 8 2026

QA session. Game: Stable 42.21.0, QA save Saves/Sandbox/ZeD-QA, 4K fullscreen at 1.75x, `-nosteam`. Code tested: main 7b245635 (the speed work), then Build's round 1 (0581444a) and round 2 (d439a3a2) fixes. Everything below is on main; QA files only were committed by QA.

## Short answer

Single player is in good shape. The overnight failures were mostly the QA kit, not ZeD: the two windows were never pinned in the beta 8 manifests, so they rolled up when the mouse was away and most World window scripts looked broken (doll_v4, curtain, journal readers, sort groups, and so on). With the pin added the full regression went from 32/100 (61 never run) to 99/101. Real ZeD faults found on 42.21 were sent to Build and fixed (guide TV page, TV schedule, console, safe mode, balloon tail, radio in a bag). Multiplayer: setup, trade and medical check mostly work after Build's round 3 (two items still fail), and a problem stops bob from coming back after a kick or ban, so the later multiplayer checks (bans, mute, rules, mail) gave no verdict.

Ready to upload: single player yes, with the open items below; multiplayer not proven.

## Per stage

| Stage | Result | Report |
|---|---|---|
| Release check | 2/2 pass (night run, before the fixes) | ZeDUI/tools/qa/b8n_release |
| Regression, night run (unpinned windows) | 32/100 pass, 3 fail, 61 not run (a stuck script stopped it) | ZeDUI/tools/qa/b8n_regression |
| Regression with pinned windows, speed code | 96/101 pass, 2 fail, 3 warn | ZeDUI/tools/qa/b8n2_regression |
| Regression, after Build's round 1 (0581444a) | 99/101 pass, 0 fail, 2 warn (dashpx: two police cars did not spawn; dash_keys_edge: one car read start for acc, flaky) | ZeDUI/tools/qa/b8n4_regression |
| b8_guide_cards (7 scripts + prelude, pin) | 8/8 pass (d439a3a2) | ZeDUI/tools/qa/b8n5_b8_guide_cards |
| b8_world_everyday | 9/10 pass; b8dc (Lua console, debug only) 2 checks miss: the game's suggestion for "getPlay" stays empty | ZeDUI/tools/qa/b8n5_b8_world_everyday |
| b8_menus_review | 5/5 pass | ZeDUI/tools/qa/b8n5_b8_menus_review |
| Mods batch, Wounds Overhaul ZeD last and ZeD first | after Build round 3 and a script fix: 4/4 pass in both orders (earlier 3/4: the character bled to death with god mode off, which closed the window) | ZeDUI/qa/regression/2026-11-08_0645_mods_fullscreen4k.md and 0648 |
| Mods batch, the seven supported mods | 6/6 pass | ZeDUI/qa/regression/2026-11-08_0439_mods_fullscreen4k.md |
| Main menu (b8mm) | 26 pass, 0 fail; A1 (server Workshop items) not run: the screen exists only with Steam on | console of the run; scratch log in the commit |
| Multiplayer, whole batch | 259 pass, 36 fail, 21 manual (final full run, bob could not come back after a kick or ban); first full run 295 pass, 43 fail. Trade, medic and setup only, on Build round 3 (d8cae917): 106 pass, 5 fail, 6 manual | ZeDUI/qa/two_players_b8.txt (the last, trade and medic run), two_players_b8_full_run2.txt (the full run), two_players_b8_full_run1.txt, two_players_b8_kick_run.txt |

Why the mods batch did nothing overnight: batch_b8_mods.ps1 named a variable `$runs`, which PowerShell treats as the same name as its `-Runs` parameter, so the list of runs was empty ("== " and nothing else). Fixed (`$runList`); it ran twice since, with real results.

## ZeD faults sent to Build, and what landed

Round 1 (sent about 00:30, fixed in 0581444a, confirmed):
1. Guide TV page: `getReadLiterature():keySet():iterator()` does not work on 42.21 (HashMap). 50+ exceptions per second while the page was built. Fixed with a plain find on tostring(map). b8hf, b8fm, b8gd pass now.
2. TV schedule: all 10 TV channels had no active script on 42.21 (RadioScriptManager.Load clears them). Build now reads each channel's main script. The page now lists a schedule; on this save (day 9 to 10) it holds 0 to 9 teaching shows because the only teaching channel (Life and Living TV) runs out near day 12. Build says that matches the game's data. NOT checked against a real TV: see "For the director".
3. Debug Lua console on 42.21: runtime errors showed no error block, suggestions stale. Error block fixed and passes. The suggestion for a typed word still shows nothing in the test (debug only; accepted as known unless Build finds the trigger).
4. Wheel icon "bug": the suite's own icon list lacked the icon; QA fixed the suite. Slice now uses "pencil".
5. Safe mode hand-back of a screen (reread did not clear the 500 ms cache): fixed, passes.
6. First Messages balloon had no tail for a moment: fixed, passes.
7. Radio in a bag opened nothing: now opens ZeD's Radio tab ("Carried"). Passes in b8vw (radio in the hands); the bag case itself was not scripted.
8. Guide drew with nil ruleY (50 exceptions per run, ZeD_SurvivalGuide.lua:1364): fixed in d439a3a2, b8hf has no exceptions now.

Round 3 (sent at about 05:30, Build fixed in d8cae917, QA reran at 06:45 to 07:01):
- Console suggestion (debug only), see 3 above.
- Wounds Overhaul (round 3, fixed): the nil menu came from the character dying (god mode off, bleeding from the neck wound), not from a ZeD window closing. ContextMenu.get now returns nil quietly; the script keeps the character alive. Passes in both load orders.
- Multiplayer trade (Build changed ZeD_Trade to compare worn and held item ids): the check "worn, held and favorite things are not listed" STILL fails on the admin client in the last run (07:00). Everything else about the trade passes. Possibly the stage items are not really equipped on the client when the picker reads them; Build should look at the admin client with a worn jacket.
- Multiplayer medical check (Build changed the fixture and the wait): the card now lists bob's wounds and offers Bandage and Remove bandage. Still failing: after the Bandage is chosen, bob's hand does not show "Bandaged" on the admin's copy within 40 s (b8md 5, b8bm 5). Either the server reply or the bandage action does not reach the card.

## QA script faults fixed (all in ZeDUI/tools/qa)

- Manifests regression.txt and the b8 manifests: pin windows after the prelude (zedqa_pin_windows.lua). This was the main cause of the night's failures.
- zedqa_b8_windows (radio activate needs the player object and a radio in hand; summary line printed "0 FAIL" which the runner counts as an error), zedqa_b8_cards, zedqa_b8_dash (same summary line).
- zedqa_b8_recipes (field name, cache wait, Cooking level 0 has no recipe in this game's data).
- zedqa_b8_respawn_smoke (the desk object outlives the game start).
- zedqa_b8_paper_map (waited on the wrong thing), zedqa_b8_everyday_a (the game puts keys in the ignition only when the character holds the car's key), zedqa_b8_everyday_b (balloon anchor timing), zedqa_b8_focus (hand-back wait), zedqa_b8_hidden (a show in progress), zedqa_b8_console, zedqa_b8_stepaside (window not yet "really visible"), zedqa_b8_seven_hud (reveal timing), zedqa_b8_seven_menus (the owner must be a table), zedqa_b8_wounds (the Bandage entry is a sub menu; not yet rerun), zedqa_b8_mainmenu (A1 needs Steam).
- zedqa_dpad_wheels (Mini-map slice was removed from the Map wheel), zedqa_seat_lightbar_vanilla (spawn square), zedqa_safemode (poll tolerance), zedqa_dash_keys_edge (key out before the first click), zedqa_wheel_icons (icon list).
- batch_b8_mods.ps1 (variable clash, above).
- Multiplayer: zedqa_b8_mp_trade and bob_trade (counts and names on 42.21), zedqa_b8_mp_bob_leave_kick and _ban (they ran on OnTick, which stops after a kick; now also OnFETick). That last fix did not yet bring bob back to the menu in the final run.
- New probes: zedqa_b8_probe.lua, zedqa_b8_probe2.lua (what 42.21 offers for reading and radio calls), zedqa_dke_only.lua.

## Environment notes

- Game is Stable 42.21.0; beta 6 ran on 42.22. Two real differences: `getReadLiterature` and the radio scripts (above).
- The QA save: its auto roll-up pin is not kept between runs; every manifest must pin. The save is at game day 9 to 10.
- The multiplayer test server's world was saved by 42.22 and 42.21 refuses it ("savefile appears to be from a newer version"). QA moved it to %USERPROFILE%\Zomboid\zedqa_mp_42_22_world_backup\zedqa and the server made a fresh world (admin zedqa and bob are made fresh; they are test accounts on the local server).
- A1 (server Workshop items window) needs Steam; QA runs without Steam because Steam would load its own copy of ZeD.
- In debug mode a "Lua console" ZeD window opens at the bottom left in every QA run (new in b8); pictures show it.
- Two police cars (dashpx) and one car in dash_keys_edge fail now and then to spawn or to read ACC; the vehicle kit is flaky, not ZeD.
- The multiplayer helper session needs Python, which is not installed here; skipped (`-NoHelper`).
- `pwsh -File batch_b8_mp.ps1 -Only a,b` receives one string; use `& .\batch_b8_mp.ps1 -Only a,b`.

## Speed, before and after (suite_perf, ms per tick, average, 4K)

"Before" is b8_base2 (code before the speed work, windows NOT pinned, so partly rolled up: not a clean comparison). "After 1" and "After 2" are the same suite after the speed work, windows pinned (b8n2 before Build's round 1, b8n4 after it).

| Tab | Before (max) | After 1 (max) | After 2 (max) |
|---|---|---|---|
| char loot | 8.46 (16) | 10.08 (20) | 9.54 (21) |
| char equip | 14.97 (157) | 16.13 (29) | 14.39 (21) |
| char health | 8.86 (18) | 11.88 (23) | 10.63 (20) |
| char thermal | 8.78 (18) | 16.83 (23) | 14.53 (22) |
| char identity | 11.27 (142) | 15.67 (23) | 16.03 (26) |
| char journal | 9.37 (22) | 11.20 (24) | 10.33 (24) |
| char skills | 16.68 (201) | 17.19 (28) | 15.75 (28) |
| world craft | 10.35 (173) | 14.28 (26) | 16.07 (28) |
| world build | 8.46 (16) | 10.83 (21) | 11.85 (25) |
| world maps | 11.13 (186) | 12.04 (22) | 11.58 (24) |
| world forage | 13.26 (200) | 13.40 (25) | 12.09 (22) |
| world animals | 10.66 (23) | 9.43 (18) | 10.29 (21) |
| world loot | 9.30 (154) | 9.02 (21) | 8.53 (17) |

Reading it: the long spikes (150 to 200 ms, the first draw of a tab) are gone after the speed work, but the averages are not lower; several are higher. Because the "before" run had rolled-up windows, QA cannot say the speed work helped or hurt the average. A fair answer needs the old code run with pinned windows; QA could not do that without swapping the shared checkout.

## For the director in the morning

Hands-on controller checks (QA cannot do these):
1. The paused Character and World windows with the controller: pause the game, open both with the controller, move around, confirm they take the pad while paused (pictures: Screenshots\zqa_b8eb_paused_char.png, zqa_b8eb_paused_both.png, zqa_b8_vw_b14_character_window_while_paused.png).
2. Unplug and plug the controller in and out: the Messages bubble should pop out of the belt's Messages icon with its tail pointing at it, never more than three bubbles, "plugged in" replacing "unplugged" (pictures: zqa_b8eb_balloon_unplugged.png, zqa_b8eb_balloons_three.png).
3. The TV page in the survival guide. QA only has a save at game day 9 to 10, where no teaching show airs. Use a new game or a save at day 8 or earlier: read a TV Monthly, open the guide's TV page and compare the listed times with a TV in the game (Life and Living TV has the lessons). If they do not match, the fallback must come out (Build's words).
4. A1, the server Workshop items window: needs Steam and a server with missing Workshop mods.
5. A radio in a backpack (not in a hand): right click, Device Options; it should open the Radio tab with the radio as "Carried".
6. Multiplayer, by hand with two players: the trade card (the offer list should not show worn, held or favorite things), the medical check of another player (the card should list his wounds and offer Bandage), the kicked screen (picture from QA's run: the monitor shows "You were kicked from the server" with the reason and a Back to menu button; saved only in QA's scratch folder, not in the repo), bans, mute, rules and mail.

Pictures worth a look (%USERPROFILE%\Zomboid\Screenshots, the next run overwrites them): zqa_b8_gd_first_spread.png, zqa_b8_gd_tv_rules.png, zqa_b8_hf_tv_found.png (guide and TV page); zqa_b8ea_heater_lit.png, zqa_b8ea_dash_note.png, zqa_b8ea_makeup.png (everyday leftovers); zqa_b8pm_paper_stash.png, zqa_b8pm_find_on_map.png (paper maps); zqa_b8dc_errors.png (Lua console error block); zqa_b8wd_car_part.png, zqa_b8wd_walkie.png, zqa_b8an_animal_view.png (world devices and animals); b8_mp\claims, b8_mp\trade, b8_mp\medic (multiplayer, 1280x800).

## What still blocks an upload

- Multiplayer is partly proven: setup, trade and the medical check now work except two items (worn things listed in the trade picker; the bandage does not show on bob's hand on the admin client). Bob still does not come back to the main menu after a kick or ban in the kit, so bans, mute, rules, mail and the desk checks have no verdict (36 failures in the last full run, most of them that). Whether the kit or ZeD is at fault there is not known: the kicked screen itself shows correctly.
- (Wounds Overhaul is done: 4/4 in both orders.)
- The TV schedule needs the director's check.
- The speed claim is unproven (above).
