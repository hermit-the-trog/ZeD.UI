# QA audit: controller and input scripts (Nov 12 2026, read only)

Scope: every in-game script that tests the controller, focus, wheels, chords, keys, run+sneak or the pad on the body figure.
Results come from the 1,286 files in ZeDUI/qa/regression plus the QA_/CHECK_ reports. "Repairs" is the number of commits
that touched the script (git log --follow), which is the closest record of how often it was fixed.

How to read the results: the runner calls a script PASS when it reaches DONE with no FAIL/ERR line. Six scripts below
never print FAIL at all, so their PASS only means "did not crash". They are marked **no checks**.

Where things stage today:
- **Drag strip** (925,13040, Irvington Speedway, open asphalt, daylight): the prelude moves the character there before every run.
  Good for cars and crates. Wrong for animals (no pen, no feed, no trough, the game has no "usable animal" there).
- **Deep-run home** (10608,11151): where the character stood on Oct 23, before the move. This is the thick woods the
  prelude's own comment describes. The deep-run fixture put its car, hens, cow, farm plots and crates there. Every
  regression run starts at the drag strip, so any script that looks for "the deep-run car within 8 tiles" finds nothing
  and silently skips its car part (57 of 65 dpad-wheels runs, 49 of 51 button-picture runs).

## The table

| Script (tag) | What it checks | Where / how it stages | Place makes sense? | Time | Recent results (FAIL cause) | Duplicates | Repairs | Verdict |
|---|---|---|---|---|---|---|---|---|
| suite_gamepad (gp) | D-pad moves, row A/X, context menu B, stale zone after tab swap | Drag strip; no scene | Yes (no scene needed) | 7 s | 72 PASS, 3 not run. **No checks**: prints "(expect ...)" and never fails | wpt steps 1-3, navevents | 1 | **DROP** (wpt and navevents cover it with real checks) |
| zedqa_card_pad (cp) | Pad into the item card and back; Health tab drawer reach | Drag strip; character's own hammer | Yes | 4 s | 85 PASS, 1 WARN (ran twice). **No checks** | wpt steps 3 and 6 do the same with checks | 1 | **DROP** |
| zedqa_navevents (ev) | Where focus lands after card close, strip, tab, LB/RB, item taken, map fold | Drag strip | Yes | 5 s | 69 PASS. **No checks** (14 "expect" prints nobody reads) | wpt covers card/menu/transfer/LB-RB; the map part is unique | 2 | **MERGE** the map fold/unfold focus part into wpt as real checks; drop the rest |
| zedqa_navmap (nav) | Dry-run cone-nav of every tab: traps, islands, stuck stops | Drag strip; the windows only | Yes | 10 s | 76 PASS. **No checks**: TRAP/ISLAND are listed "for review" and never fail | padmap does the same dry run with pictures | 1 | **SHRINK**: count TRAP and ISLAND as FAIL, drop the full move dumps (the long part of every report) |
| zedqa_world_pad_take (wpt) | The director's World-window pad test: RB in, containers by Down, card on primary action, Take, B, object card, Character window parity, focus after menu/transfer, belt, every tab's bottom at both sizes | Drag strip; a crate built beside the character with four things, a padlock, six wounds; all taken back | Yes for the crate. Step 7's World Animals tab depends on whatever animals the builders left nearby | 68 s avg, 100 s max | 29 PASS, **43 WARN**, 5 not run. Oct 23-27: real mod bugs (the commits that day were the pad fixes). Nov 1-6: "hold A moved the hammer" in ~9 runs = **the test's own** (hold A changed to marking on Nov 1; the test lagged 5 days). Nov 5-6: World Animals tab bottom not reachable = likely a real reach bug, but only shows when leftover animals fill the tab. Comments and FAIL names still say "nails / hammer" though it now uses an eraser and a corkscrew | Covers cp, gp, half of ev, hp | 9 | **SHRINK**: split step 7 (every tab's bottom, both sizes) into its own short script; fix the stale names; keep steps 1-6 |
| zedqa_health_padprobe (hp) | Health tab at Large text: Down from the figure reaches the exercise band | Drag strip; wounds set by console | Yes | 3 s | 5 PASS, 3 WARN. The same 2 FAILs ("ended on invrow:1") in every Nov 7 run, with and without Wounds Overhaul. **Never diagnosed**: either a real bug or the band moved (Oct 30) and the test kept the old route | wpt step 7 (Health tab bottom with six wounds) | 3 | **MERGE** into wpt step 7 once Build says where Down from the figure should land |
| zedqa_pad_marks (pmk) | Hold A marks rows, D-pad with A held paints, X hold, in both windows and a World column | Drag strip; two crates built (A on show, B as a column) | Yes | 15 s | 3 runs, all **WARN** (Nov 1): "crate B opens as a column" = the test's own layout assumption (window width). Not run since Nov 1 | wpt builds the same crate | 3 | **MERGE** the mark checks into wpt's crate scene; drop the second crate and column |
| zedqa_break_pad (bpad) | 150 random presses per tab, fixed seed; focus must stay valid | Drag strip | Yes | 90 s | 1 PASS (Oct 31) | none | 1 | **KEEP** as a by-hand pre-release run (not regression) |
| zedqa_padmap (pm) + zedqa_deep_run (deep) | ~45 full captures with every stop and its moves, for padmap.py overlays | **Deep-run home in the woods** (teleports there); the stocked character, car, hens, cow, plots | **No**: the car is backed into woods, the animals and plots are in a forest | 99 s + deep run | 11 PASS; by hand | navmap (same dry run) | 2 + 4 | **RESTAGE** the deep-run fixture: car on the drag strip lot, animals at a real farm (a ranch with a pen and trough), crates in a building. Then keep padmap as the by-hand pad map |
| zedqa_ranch_pad (rpd) | Ranch page follows the focus to Totals and the last alert row | Drag strip, after zedqa_animals.lua builds a hen house, hens and a dead cow there (they stay, more each run) | **No**: animals on a racetrack, and the builder piles up animals every run | 7 s | 1 PASS, 2 WARN (Nov 5). FAILs depend on how many animals the builder left = **scene** | wpt step 7 (World Animals tab bottom) | 1 | **RESTAGE** at a real farm with a fixed herd, then **MERGE** into the split-out "tab bottoms" script |
| zedqa_wheel_sizes (ws) | The ZeD wheel at 3 to 11 slices, captures for the director's sizing question (Oct 15) | Drag strip; a pickup spawned beside the character, a pistol given | Yes (open asphalt) | 13 s | 59 PASS. **No checks** (captures only); spawns a pickup in 34 runs | wi takes the live wheel captures | 2 | **DROP** from regression (the sizing question was answered in October) |
| zedqa_wheels (wh) | Vanilla's wheels through vanilla's functions, routed slices | Drag strip; steps into a spawned pickup; pistol and torch handed | Yes | 23 s | 62 PASS. **No checks** | wi part 6 (vanilla radials live, in and out of the car) | 2 | **MERGE** into wi (or drop) |
| zedqa_wheel_icons (wi) | Every wheel icon: drawings load, box rule, vanilla words to pictures, tab icons, ZeD wheels' slices, live radials, captures at 1.75x and 1x | Drag strip; spawned pickup | Yes | 46 s | 36 PASS, 2 WARN (Nov 11, "12 px from a 16 px drawing"): the **test's own** expectation, per the Nov 11 commit | Parts 1-5 are data checks | 8 | **SHRINK** + **MOVE TO SIM**: parts 1-5 (load, box rule, word map, slice coverage) go to a sim; keep part 6-7 (live radials, captures) |
| zedqa_dpad_wheels (dw) | D-pad wheels and Select: slices on foot / in a car / by an animal, inner wheels, Back, one take each, paused, the gesture (tap, flick, timeout, dead zone), the UI queue | Drag strip. Car: **the deep-run car within 8 tiles, else skipped** (skipped 57 of 65). Animal: none tame near, so a cow is spawned on the asphalt and the game's "usable animal" function is **replaced by a stand-in** | Car: **no** (never there). Animal: **no** (racetrack; and stubbing the game's own lookup tests nothing real) | 38 s | 56 PASS, 2 WARN. 4 FAIL "World > Animal is live" = **scene** (the stand-in) | Gesture logic duplicates what a sim could do; known_issues_sim and everyday_leftovers_sim already load DpadWheels | 6 | **RESTAGE** (spawn the car on the strip like wi does; animal part at a real farm without the stub) + **MOVE TO SIM** the gesture and UI-queue section |
| zedqa_pad_glyphs (pg) | Button pictures in every set (PlayStation, Xbox, Deck, Nintendo), boxed keys, themes, the dash hint | Drag strip. Dash hint: **deep-run car within 8 tiles, else skipped** (skipped 49 of 51) | Dash part: **no** | 26 s | 45 PASS, 6 not run; the dash part has run twice | Picture counting is partly logic | 1 | **RESTAGE** the dash part (spawn a car on the strip) or cut it; otherwise KEEP |
| zedqa_quick_chords (qc) | Chord defaults, LB+X torch from a bag on/off, eat/drink/smoke queued, a gone thing's reason, the press swallowed, assigning from a wheel | Drag strip; a flashlight put in a bag | Yes, but the hands are not cleared: "LB + X from a bag: skipped" in 19 runs because a torch from wh/wi is already in hand | 20 s | 45 PASS, **8 WARN**. FAILs: "ZeD setup has Put things back", torch in hand/on = **test's own** (setup moved, leftover torch) | Defaults/names check is pure data | 5 | **RESTAGE** (empty hands and belt first) and move the defaults check to a sim; keep the live chord checks |
| zedqa_cov_input (cov_input) | Action map, input-mode detector on a stand-in pad (slot 15), bumper zoom chord states, the game's top-left buttons hidden, text scale override | Drag strip; Furniture tab cursor; stand-ins for getJoypadData and the controller | Yes, but most of it runs against stand-ins, not the game | unknown (timeout 240) | Written today (3 commits today), **never run** (1 SKIP) | coverage_bugs_sim already loads BumperChord; action map, detector and text-scale math need no game | 3 | **MOVE TO SIM** (action map, detector, chord state machine, text scale math) and **SHRINK** to the real RB/LB pad path and the hidden top-left buttons; 1,368 lines is the largest script in this area |
| zedqa_run_sneak (rs) | Run button also sneaks. A: timing driven through a stand-in input. B: by hand with the director's pad, 4 minutes of logging | Wherever the character is, on foot | Yes | A: seconds; B: 4 min by hand | No results filed anywhere. **6 rewrites today** following the rulings. Its tag "rs" is already zedqa_ring_squares' tag in regression.txt (the runner refuses a repeat) | run_sneak_sim.lua (1,176 lines) models the game's 42.22 frame and covers all of part A | 6 | **MOVE TO SIM**: drop part A (the sim does it better); keep part B as the director's by-hand pad check |
| zedqa_gamepad2 (gp2), zedqa_gamepad3 (gp3) | v5 pad flow: controller mode, enter a seat, hint placement | **Enters any SportsCar in the cell**; a far car drops the game to the main menu | **No** | 4-7 s | No results on record; left out of regression for the far-car hazard | wpt, dw | 1 each | **DROP** (dead since v5, unsafe) |
| zedqa_menu_nav (NAV) | Main menu screens with the pad: reach, moves, highlight | Main menu (never unattended) | Yes | n/a | No results on record since Oct 15; seven main menu windows became ZeD windows Nov 7 | mainmenu_vanilla_sim (163 checks) | 1 | **SHRINK** to the new main menu windows and run once by hand, or DROP if the sim covers it |

Not in this area, though the names suggest it: zedqa_dash_keys_edge and zedqa_dash_r6_keys (ignition keys on the dash:
vehicles), zedqa_mapkey (the map legend), zedqa_padlock (padlock card setup builder), zedqa_b8_focus (pause on alt-tab),
zedqa_figure_tabs (body figure captures), zedqa_container_controls_mouse (real mouse).

## The worst offenders

1. **The deep-run fixture lives in the woods.** It was built on Oct 23 where the character first stood (10608,11151,
   thick forest), before every run moved to the drag strip. Its car, hens, cow and farm plots are still there.
   dpad_wheels and pad_glyphs look for that car "within 8 tiles", do not find it, and skip their car parts: 57 of 65
   and 49 of 51 runs. Those car checks have effectively never run unattended. padmap teleports back into the woods.
2. **Animals on a racetrack.** zedqa_animals builds a hen house, hens and a dead cow on the drag strip and never takes
   them away, so each run adds more. ranch_pad and wpt's Animals-tab check then pass or fail depending on how many are
   lying around. dpad_wheels spawns a cow on the asphalt and replaces the game's own "which animal can I use" lookup
   with a stand-in, so its animal check tests the stand-in, not the game.
3. **wpt is the loop.** 43 WARN in 77 runs and 9 repairs. After the October bug fixes, most of its FAILs were its own:
   the hold-A expectation stayed 5 days behind a design change, and its tab-bottom step fails on leftover animals.
   It still names "nails" and a "hammer" it no longer uses.
4. **Six scripts never fail.** suite_gamepad, card_pad, navevents, navmap, wheel_sizes and wheels print "expect ..."
   or captures and report PASS whatever happens: about 60 s of every regression and ~70 green rows each that prove
   only "it did not crash". Two can go outright (gp, cp), two can merge (ev, wh), navmap needs its TRAP/ISLAND counted.
5. **Logic tested in the game that a sim does better.** cov_input (1,368 lines, never run) drives stand-in pads and
   stand-in joypad data; run_sneak part A drives a stand-in input while run_sneak_sim already models the game's frame;
   the dpad_wheels gesture section and wheel_icons parts 1-5 are data and timing logic. These are cheap outside the
   game and only cost restarts inside it.
6. **Undiagnosed repeats.** health_padprobe has failed the same 2 checks in every run since Nov 7 and nobody decided
   whether it is a bug or an old route. One look from Build ends it.

If all verdicts land: the unattended input block drops from 12 scripts (~260 s plus cov_input) to about 7 (wpt split
in two, wi, dw, pg, qc, nav, a short cov_input), every one of which can fail for a reason.
