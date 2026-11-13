# Test scripts: what goes, what stays, where they run (Nov 12 2026)

## 1. The problem

The test folder holds 505 in-game scripts (plus about 150 one-off run files), and 110 of them sit in the main run, which takes about 75 minutes; another 117 "sims" check the same logic outside the game in seconds. Of the failing runs on record that could be traced, roughly 170 were the test's own fault (animals on a racetrack, cars staged in the woods where they never load, a car pushed by hand that never reaches speed, timing waits, another test's leftovers) against about 15 real ZeD bugs found since late October. The animal scripts alone took about 24 runs, 17 repairs and over three hours in 25 hours for one clean pass, the 19-car dash tours were repaired more than 30 times without one ZeD bug, and the soak test spends 10 to 13 minutes of every run and has never been able to fail.

## 2. Rules from now on

1. **Stage where the thing happens.** Animals at a farm, cars on pavement, kitchens and furniture in a house, fishing at a shore. No building a fake farm on a racetrack, no searching the woods for an old car.
2. **A setup failure gets one fix or the step is dropped.** If a test fails because of its own staging, timing or leftovers, it gets one repair. If it fails the same way again, that step is cut and the check moves to a sim or a by-hand look. No reruns of the same failure.
3. **In the game, check only what just changed, plus one short smoke run.** The full run happens before an upload, not after every change.
4. **Logic goes in sims.** Rules, counts, orders, text, timing and math are checked outside the game, where they run in seconds and cannot fail on staging.
5. **Every test cleans up after itself.** What it spawns or builds, it takes away. Any test that moves, folds or pins a window puts the layout back when it ends, even on an error. The run starts from the default window layout with the console closed.
6. **A test that cannot fail is not a test.** Picture-only scripts move to the gallery or picture tools. A skipped step reports "not run", never PASS.
7. **One copy of the staging code.** One shared helper spawns a car on a known clear stretch and checks the whole car, not one tile. Fixed once, not in ten copies.
8. **Done one-offs go to an archive folder.** Nothing is deleted.

## 3. Where tests run

| What | Place | Where it comes from |
|---|---|---|
| Windows, menus, cards, crates, cars | Irvington Speedway drag strip, 925,13040 (open pavement, daylight). Cars on one marked clear stretch; never the grandstand | Current home in every script |
| Storage, lockers, a tap (restock) | The grandstand beside the strip, about 964,13079 | zedqa_restock already uses it and it works |
| Kitchens, furniture, fridges, a house | Muldraugh, houses north east of the crossroads, 10737,10234; a kitchen stove at 10670,9772 | The gallery scripts and the cooking check already go there |
| Fishing | The shore at 13913,4555 (facing east) | The live fishing scripts; they pass |
| Animals, hen house, trough, butcher hook, farm plots, trailer | **A real farm: barn, fenced pasture with animals already living there, hen house, trough, tilled field. To scout** (one near Irvington would load fastest) | No farm on record; every animal script used the drag strip |
| The old "deep run" spot in the woods, 10608,11151 | **Retire it.** Its car goes to the strip, its animals to the farm, its crates to a Muldraugh house | Car checks there were skipped in 57 of 65 and 49 of 51 runs |

## 4. Verdict for each script

"Main run" = the list run before an upload. "On demand" = run only when that area or that other mod changes. The leading `zedqa_` is left off the names.

### KEEP: 50

- **Main run (26):** prelude (adds the layout reset and closes the console), suite_tabs, suite_verbs (takes its items back), audit_fixes, ctxlist, onepath, grid, wt_bracket, doll_v4, charinfo, equipdrag, lists, mech79 (add it; it found real bugs), dash_odo_reload, dash_lamps, fishing (rod meter), px_icons, messages (clears the inbox first), ring_squares, sandbox_ig, safemode, b10_guide_open_frames, suite_perf, release_check (a missed real-mouse step reads "not run"), b8_station (give it nails), b8_animals (restage at the farm when it exists)
- **Fishing, run when fishing changes (2):** fishing_tab_live (the one fishing run), fishing_tab_live_reload
- **On demand for other mods (15):** exinfo, immersive_searching, capacity, dropnloot, nested, isearch, roadworthy, msc_run1, msc_run2 (until the Summer Car bug is fixed), r3_D_cars, b8_seven_menus (ignore other mods' errors), minsidebar, cml, responsiveui, modlist
- **By hand or picture tools, not tests (7):** break_pad, run_sneak part B (your pad), car_radio_build, car_radio_live, tab_review, recheck_tabs, padmap (after the deep run moves)

### RESTAGE: 16

- **To the farm:** animals (the builder: use what the farm has, take away what it adds), animals_quick (also SHRINK: one Milk, one Shear, one Feed at normal speed, the greyed-reason pictures, the pad landing; no speed hack, no far cow), the Ranch page script (see MERGE), trailer (with a take-back), cov_objcards' trough, hen house and plot cards (split out of the seven-card run; no timed sitting hen), gallery_farm_ranch, dpad_wheels' animal part (a real animal, no stand-in), deep_run's animals and plots
- **To the strip:** deep_run's car, dpad_wheels' car part, pad_glyphs' dash part, put_back's tire scene (its own parked pickup, or cut the step), quick_chords (empty hands and belt first)
- **A crate instead of a spawned pickup:** container_controls, sort_groups (also SHRINK), capacity and dropnloot
- **A real chair:** furniture (and its pickup check must really check)

### SHRINK: 22

cov_vehicles (rod, clock and sleep clock to a sim), dashnight (2 or 3 cars), dash_green (no push to speed), dash_r6_parts (pictures only), dash_odo (the real drive only), curtain (3 tabs, does not leave windows rolled), world_pad_take (steps 1 to 6; every tab's bottom becomes its own short script), ctx_icons (one live menu; the icon table to a sim), faiv (the loot-flash check only), restock (the day math to a sim), two_widths (no trip to the woods; waits for windows to settle), wheel_icons (live wheels only), navmap (a trap or island now counts as FAIL), cov_input (real bumper path and hidden buttons only), soak (2 rounds with a real before-and-after check; the long one once per release), prompts (no 17 pictures), b10_tooltips (3 or 4 balloons), bubbles (under 20 s), uiscale (real checks; absorbs win, rootchange, scalewalk, large), the survival guide set (one guide smoke plus book83_lang), menu_nav (once by hand on the new menu windows), fish_smoke (ZeD-off baseline only when fishing changes)

### MERGE: 34 scripts into 13

- animals_quick_more into animals_quick
- animals_page, ranch_pad, ranch_long into one Ranch page script (at the farm)
- dash19, dashpx, dash_keys_edge, dash_brands into **one 19-car pass** (each car spawned once)
- dash_r6_persist into dash_odo_reload
- car_radio_cd into cov_vehicles
- pin_windows, loot_tabs into the prelude
- doll into doll_v4; curtain2 into curtain; container_bottom into container_controls; view_toggle into grid
- win, rootchange, scalewalk, large into uiscale
- navevents' map part, pad_marks into world_pad_take; health_padprobe into the tab-bottoms script once Build says where Down should land
- wheels into wheel_icons; staged_ver into release_check
- fishing_tab's pictures and fish_smoke's ZeD-on half into fishing_tab_live
- the main menu checks (menu_audit, menu_case, menu_zed_switches, button_case_menu, settings, screens) and what is left of the mods screen scripts into **one menu smoke**, once per release; headers_lang and mods_lang into the Chinese, Japanese, Korean and Thai picture run

### MOVE TO SIM: 27 (most sims already exist)

animals_list, dash key order (from dash_keys_edge and dash_r6_keys), car badge choice, dash night plate, taxi fare and hula sway, b8_dash plain speed, ctx_overlap, dual_pin, window_saved_pos, tab_search, inventory_filter, footer_picked, segbars, sc_font, 158_balloon (plus one look by hand in Chinese), button_case_game, guide_bubble (keep a 10 s check that it shows), guide_ads, the four console scripts (Lua Console 93 has its own sims), files_game, files_menu, files_after, lang key counts, kinsoku, run_sneak part A, the 162 stack bar from b11_notes, mods order, folders and separators

### DROP (archive): about 105

- **Animals:** animals_quick_far, animals_restore and animals_cleanup_far (once the strip is clean), animals_clip
- **Cars:** dash_props_smoke, seat_lightbar_vanilla, tm, tour, tour3, dash_green_only, dash_r6_keys, vehicle_small, vehicle_review, mech, mech2, seats_build, car_radio_vanilla, probe_car_ticks, carspawn_off, compat_vehicles, r3_D_cars2, radio_review
- **Pad:** suite_gamepad, card_pad, wheel_sizes, gamepad2, gamepad3
- **Windows and inventory:** tabicons, tabs_lit, container_controls_captures, autocollapse, pins, tab_sweep, tab_cost, loot_click, loot_paths, drag_real, card_real, floor_rclick, b6a_left, b8_cards, b8_windows, morerow, container_v2, container_ribbon, container_controls_mouse, padlock, qa_pickup, inv_cleanup, move_to, doll_view_on, restock_probe, world_widths (grid_off stays as a one-time save setting)
- **Per-beta checklists, already shipped:** b11_notes and its two copies, the b9a set, b8a_report, b8a_sandbox, b8a_password, b8_console, b8_guide, beta_ig, sandbox_ig_pages, sandbox_dump
- **Main menu one-offs and pictures:** testlang (from the run; by hand when a layout changes), menu_about, desk_v4, textback, menu_note, menushot, desktop, desk_v3, desk_ws, desktop_uploader, wallpaper, titlevideo, menu_beta, menu_forms, menu_lean, menu_pagelist, menu_questions, menu_sandbox_pages, menu_bars, m1_menu, r3_menu, b8_mainmenu, tiyl_menu, tiyl_game, trash_quit, offsave, tutorial_start, mods_hand, mods_hold, mods_read2, mods_prof
- **Guide, console, language probes:** guide82 and its icons, measure and stills, book83 atoms, fonts, pause and reopen, guide_device, topic_shot, house_ad, console_probe, halo_probe, halo_off, thai_bytes, de_names, scale_even, scalecap, header_fit, hint_strip

The other roughly 250 scripts in the folder (gallery, multiplayer and older one-offs) were not judged by name. The same rule applies: anything in no run list goes to the archive.

## 5. The smoke run

Run after each build, beside the checks for what just changed. One game launch, **about 8 minutes including launch and quit**, every step able to fail:

1. Prelude: drag strip, default window layout, console closed, right ZeD copy loaded
2. Release check: windows open, a floor transfer round trip, pad A and B on a row, a real right-click, the watch time
3. suite_tabs: every tab of both windows opens without an error
4. onepath and suite_verbs: Move to, Rename, Take all, the main item verbs
5. world_pad_take steps 1 to 6: the pad into the World window and back
6. navmap: no traps or islands on any tab
7. One car from the 19-car pass: get in, key, dash draws
8. messages and safemode: notes arrive, safe mode recovers
9. Soak, 2 rounds: nothing piles up

The full main run, before an upload only, should drop from about 75 minutes to **35 to 40 minutes**, with the sims (seconds) run every time.

## 6. Amendments from the review of this plan
1. No farm yet. Animal scripts (including b8_animals) stay out of every run until a farm is picked. The farm gets one scouting try; if it doesn't load cleanly, the animal checks are animals_quick_sim plus one look by hand.
2. No Muldraugh trip. Near scenes (crate, fridge, shelves, a car with its trunk) go on the drag strip lot, and furniture builds its chair beside the character.
3. The car drops (dash_props_smoke, seat_lightbar_vanilla, seats_build, car_radio_vanilla, car_radio_cd) wait until cov_vehicles has one green run.
4. exinfo stays in the main run (ZeD's own feature).
5. b11_notes: notes 155 and 157 fold into onepath or suite_tabs; only 162 moves to a sim.
6. release_check gets one real-mouse roll-and-pin step, by hand. ctx_icons gets the pin icon line.
7. navmap's first run under the new rule makes a list, not FAILs; it turns strict after that list is triaged.
8. The window rule (the director): the prelude puts every window at its default layout and closes the console. Any test that moves, folds, pins or resizes a window snapshots the layout and puts it back at the end, on error too. Screenshot steps check the layout is the default.
