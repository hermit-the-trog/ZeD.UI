# Test cleanup, phase 2 (Nov 12 2026)

Plan: `ZeDUI/qa/PLAN_test_cleanup_20261112.md`. Phase 1 archived the DROP list. Phase 2 makes a short smoke run that
can fail and a trimmed main run. File work only: nothing here has run in the game yet. Every edited script parses
with the game's own Lua compiler (KCheck), and the new shared helpers pass a stand-in run outside the game.

## 1. What changed, per script

### The prelude (`zedqa_prelude.lua`)

- **The window rule.** At the start of every run it closes ZeD's console, the game's console, the guide, Messages
  and the studio if open, calls the mod's own reset (`ZeD_Window.resetLayout`, the same call as "Reset windows"),
  pins both halves of both windows, and puts the bag back to a list. It prints the layout it left and which copy of
  ZeD is loaded. `zedqa_pin_windows.lua` and `zedqa_loot_tabs.lua` are this step now.
- **Layout helpers** for the scripts: `ZEDQA_LAYOUT_SNAP()` (each window's place, size, rolled state and pins),
  `ZEDQA_LAYOUT_BACK(snap, tag)` (puts that back, never throws, safe after an error), `ZEDQA_LAYOUT_DEFAULT(tag)`
  and `ZEDQA_LAYOUT_IS_DEFAULT()`.
- **One car spawn** for every script: `ZEDQA_CAR_SPAWN`, `ZEDQA_CAR_READY`, `ZEDQA_CAR_WAIT`, `ZEDQA_CAR_PREP`,
  `ZEDQA_CAR_ENTER`, `ZEDQA_CAR_AWAY`. Seven fixed spots round the home square on the drag strip. The whole car's
  footprint is checked (3 by 7 tiles: loaded, outdoors, free, no tree, no other car within 3 tiles), not one tile.
  Spots are used in turn. A car that is far (over 25 tiles) or whose physics never woke is never entered. A car is
  removed two ticks after the character is out of it, never in the same tick.

### Scripts that now put the window layout back

| Script | Change |
|---|---|
| `zedqa_curtain.lua` | Three tabs instead of thirteen (World: Forage, Craft; Character: Skills). No longer leaves both windows rolled at the end: it puts the layout back and checks it. Covers what `zedqa_curtain2.lua` did. |
| `zedqa_two_widths.lua` | No trip to the woods. The object-card leg is cut (it needed the woods and skipped six or more cards each run). A thing that is not there reads "not run". Layout put back. |
| `zedqa_world_pad_take.lua` | Step 7 (every tab's bottom at two text sizes) is cut. Steps 1 to 6 and the focus-comes-back checks stay. Layout put back. The belt check reads "not run" when the belt is not drawn. |
| `zedqa_uiscale.lua` | Real checks: at each scale both windows are open, wholly on screen and not overlapping, and the icon has a drawing; at the end the scale and the layout are as found. |
| `zedqa_release_check.lua` | A real right-click the helper did not make reads "not run" (and "NOT RUN" on the RESULT line), never FAIL or PASS. Prints which ZeD copy is loaded. Leaves the windows open when it found them open. Layout put back. |
| `zedqa_faiv.lua`, `zedqa_doll_v4.lua` | Layout put back at the end. |

### Scripts shrunk for the smoke run

| Script | Change |
|---|---|
| `zedqa_soak.lua` | 2 rounds (about 2 minutes) with a before-and-after check: no more UI elements at the end of round 2 than round 1, and no slowdown. The 12-round one: run `zedqa_soak_long.lua` right before it, once per release. |
| `zedqa_navmap.lua` | Traps and islands are counted. First run: they are listed ("LIST trap ...", "LIST island ..."), not failed (amendment 7). Set `STRICT = true` in the script after the list is triaged. The long move dumps are off. |
| `suite_verbs.lua` | Its "(expect ...)" prints are real checks. The book, bat and apple are taken back. |
| `suite_tabs.lua` | Each tab pressed must become the active tab. Windows that are not open end it with a FAIL, not a timeout. |
| `zedqa_onepath.lua` | Its printed results are checks (Move to, Rename, double-click, Take all, the no-craft chip). |
| `zedqa_dashpx.lua` | This is the one 19-car pass. Each car is checked: character in, key in, engine running, a dash of a known design wholly on screen. `zedqa_dash_one.lua` right before it makes the next run take one car (the smoke run's car). |

### Scripts that use the shared car spawn

`zedqa_dashpx`, `zedqa_dashnight`, `zedqa_dash_keys_edge`, `zedqa_dash_brands`, `zedqa_dash_green`,
`zedqa_dash_lamps`, `zedqa_dash_odo`, `zedqa_dash_r6_parts`, `zedqa_cov_vehicles`, `zedqa_mech79` (the sedan and the
tour cars), `zedqa_wheel_icons` (its own pickup now, not whatever pickup was near), `zedqa_container_controls`,
`zedqa_container_bottom`, `zedqa_sort_groups`, `zedqa_capacity`, `zedqa_dropnloot` (the pickup they spawn when none
is near), `zedqa_dpad_wheels` and `zedqa_pad_glyphs` (their car scenes used the deep run's car in the woods and were
skipped in nearly every run; they spawn their own car now).

### Other plain cuts

| Script | Change |
|---|---|
| `zedqa_dashnight.lua` | Three cars, not seven. |
| `zedqa_dash_green.lua` | The fire pickup pushed to speed is cut. |
| `zedqa_prompts.lua` | No pictures in the regular run. |
| `zedqa_b8_station.lua` | Given nails for its builds; what is left is taken back. |
| `zedqa_put_back.lua`, `zedqa_quick_chords.lua` | A scene that cannot run says "not run", not "skipped". |

### One fix applied (Build's triage of today's smoke failures)

1. `zedqa_wheel_icons.lua`: one fix applied. The Fishing tab's entry, `fishing-tab-white` = `rod`.
2. `zedqa_rtv.lua` faceChecks: one fix applied. In the World window the full card is expected; the half card only
   in the Character window or in a World window held in (the mod's own held-in rule).
3. `zedqa_cov_input.lua` text scale: one fix applied. It tests `ZeD.Text.withFontScale` (1.3 times the zoom inside,
   the zoom back after, `_mulFont` nil).
4. `zedqa_cov_input.lua` placeholder: one fix applied. nil is accepted as well as "".
5. `zedqa_cov_vehicles.lua` alarm clock: one fix applied. It waits (5 s at most) for a sleep-panel frame.
6. `zedqa_cov_vehicles.lua` seats: one fix applied, in two parts. The driver's door is checked against vanilla's
   exit rule. The planks wait (5 s at most) for the chooser to show them.
7. `zedqa_twoway.lua` ValuTech: one fix applied. The window grows by the real fill height before the scrollbar
   check.

## 2. The smoke run: `ZeDUI/tools/qa/smoke.txt`

Run it with the real-mouse helper: `pwsh -File ZeDUI/tools/qa/release_check.ps1 -Manifest smoke.txt`. Without the
helper (`zedqa_run.ps1 -Manifest smoke.txt`) the real right-click reads "not run".

| Step | Script | Expected time |
|---|---|---:|
| 1. Prelude | `zedqa_prelude.lua` | 2 s |
| 2. Release check | `zedqa_release_check.lua` | 15 s |
| 3. Every tab | `suite_tabs.lua` | 14 s |
| 4. Item paths and verbs | `zedqa_onepath.lua`, `suite_verbs.lua` | 21 s + 17 s |
| 5. Pad into the World window | `zedqa_world_pad_take.lua` | about 20 s (was 73 s with step 7) |
| 6. Pad map | `zedqa_navmap.lua` | 14 s |
| 7. One car | `zedqa_dash_one.lua`, `zedqa_dashpx.lua` | 1 s + about 8 s |
| 8. Messages and safe mode | `zedqa_messages.lua`, `zedqa_safemode.lua` | 12 s + 12 s |
| 9. Soak, 2 rounds | `zedqa_soak.lua` | about 135 s |

Scripts: about 4 min 30 s. Gaps between scripts (3 s each): about 35 s. Launch and quit: about 1 min 20 s (from the
release check runs on record). **Total: about 6 and a half minutes.** Times are medians from the November reports;
the two marked "about" are estimates because those scripts changed.

What can fail in each: the prelude on a missing window or reset; the release check on any of its checks; tabs on a
tab that does not open; verbs and onepath on their checks; the pad test on its checks; navmap on a Lua error or an
empty Loot tab (traps and islands are listed until STRICT is on); the car on not getting in, key, engine or dash;
Messages and safe mode on their checks; the soak on a pile-up or a slowdown.

## 3. The main run: `ZeDUI/tools/qa/main_run.txt`

94 lines. `regression.txt` stays in place with a first line that points here, because merges still add lines to it.
Build's four added lines (pad_figure, cov_equipfurn, cov_reading, cov_b9to11) are carried over.

| Block | Lines | Expected time |
|---|---:|---:|
| Prelude and suites | 5 | 1 min |
| Windows, cards, pad, scale, lists, messages | 30 | 12 min |
| Containers, wheels and chords | 7 | 4 min |
| Vehicles (with the four that wait for cov_vehicles to go green) | 10 | 9 min |
| Build's coverage lines (no times on record; 1 min each assumed) | 4 | 4 min |
| Scripts the plan did not judge, kept as they were | 28 | 9 min |
| Waiting for Build's sim mapping | 8 | 9 min |
| Safe mode and the 2-round soak | 2 | 2 min 30 s |
| Gaps, launch and quit | | 6 min |

**Total: about 57 minutes now, against 75 before.** It is not at the plan's 35 to 40 yet. The difference is
listed work, not guesswork: the eight sim-move scripts (9 min) leave when Build's sims take them; the four car
picture scripts leave when cov_vehicles has a green run (1 min); the shrinks not done below (faiv, sort_groups,
b10_tooltips, restock, wheel_icons, cov_input) are worth about 4 more; and the 28 unjudged scripts (9 min) were left
alone as in phase 1. With the first two gone the run is about 47 minutes.

Not in the main run on purpose: every animal script and b8_animals (amendment 1), cov_objcards (it stages hens and
a trough on the strip), furniture (it read nothing and passed), immersive_searching (compat run only), b11_notes,
dash_odo and dash_odo_reload (they need a quit and a second launch: `dash_odo_a.txt`, then `dash_odo_b.txt`), the
fishing shore scripts and the compat set.

## 4. Not done, and why

- **Moving the merged scripts to the archive** (pin_windows, loot_tabs, curtain2, win, rootchange, scalewalk, doll,
  dash19, wheels, large): they are out of main_run.txt but still on disk. pin_windows is named in 82 other run
  lists and the rest in regression.txt, which has to stay whole for now. One pass later, with regression.txt.
- **The full 19-car merge** (dash_keys_edge and dash_brands into dashpx): their key order and badge choice are
  sim moves, which wait for Build's mapping. Both stay as they are in main_run.txt until then.
- **world_pad_take: every tab's bottom as its own script**, navevents' map part and pad_marks joined in,
  health_padprobe: each needs new test code, and health_padprobe needs Build's answer on where Down should land.
- **ctx_icons** shrink and its pin icon line (amendment 6): needs a new menu check.
- **sort_groups** shrink, and **a crate instead of the pickup** in container_controls, sort_groups, capacity and
  dropnloot: the scripts are written round the truck bed; swapping it is a rewrite. The pickup now comes from the
  shared spawn on the strip, so it can no longer stand indoors.
- **container_bottom into container_controls**, **view_toggle into grid**: two step lists to weave together, not a
  cut.
- **furniture** with a real chair and a real pickup check: a new scene.
- **put_back's tire scene**: needs a staged car with a tire, a trunk and tools; it reads "not run" until then.
- **quick_chords** empty hands and belt first: its light handling is intricate; one skip relabeled only.
- **faiv** to the loot-flash check only: the part to cut shares helpers with the put-back, and the third part (the
  list is the selection) needs a decision.
- **b10_tooltips** to 3 or 4 balloons, **bubbles** under 20 s, **restock**, **wheel_icons**, **cov_input**,
  **cov_vehicles** shrinks: each is a sim move first (list below).
- **dash_r6_parts** pictures only, **dash_odo** the real drive only, **dash_r6_persist** into dash_odo_reload,
  **car_radio_cd** into cov_vehicles: outside the main run; the last two wait on amendment 3.
- **The survival guide set**, **the one menu smoke**, **fishing_tab merges**, **uiscale absorbing large's checks**:
  new scripts, not cuts.
- **b11_notes** notes 155 and 157 into onepath or suite_tabs: needs new checks.
- **cov_objcards** split (campfire and placement on the strip, the rest at a farm): no farm yet.
- **deep_run** and **padmap** restage, and every **farm restage**: not touched (no farm yet).
- **Screenshot steps checking the layout is the default**: the helper exists (`ZEDQA_LAYOUT_IS_DEFAULT`); it is
  wired into curtain only, not into every picture script.
- **release_check's real-mouse roll and pin** (amendment 6): a by-hand step; noted in the script's header.
- **messages "clears the inbox first"**: it already does at its first step; no change made.

## 5. For Build

**Reset layout.** Nothing is missing: `ZeD_Window.resetLayout()` is used. Three things it does not cover, which the
prelude does itself and Build may want in one call: closing the guide, Messages and the studio (the prelude tries
`ZeD.GuideBook.close(0)`, `ZeD.Studio.close()` and `:close()` on `ZeD.Guide.windows[0]` and
`ZeD.MessagesWindow.windows[0]`; please confirm those two tables); the pins; the bag's list or grid view.

**Sim moves** (nothing was cut from these scripts; they wait for the script-to-sim mapping):

- Whole scripts: segbars, sc_font, 158_balloon (plus one look by hand in Chinese), button_case_game, ctx_overlap,
  guide_bubble (keep a 10 s check that it shows), guide_ads, dual_pin, window_saved_pos, tab_search,
  inventory_filter, footer_picked, the four console scripts, files_game, files_menu, files_after, the lang key
  counts, kinsoku, run_sneak part A, animals_list, b8_dash plain speed, mods order, folders and separators.
- Parts of scripts: the dash key order (dash_keys_edge), the car badge choice (dash_brands), the dash night plate
  (dashnight), the needle at a given speed (dash_green), the taxi fare and hula sway (dash_r6_parts), the rod, clock
  and sleep-clock plates (cov_vehicles), the icon table (ctx_icons), the day math (restock), the half and full
  width rule (two_widths), parts 1 to 5 (wheel_icons), the action map, detector, chord states and text scale math
  (cov_input), the gesture and UI queue (dpad_wheels), the chord defaults (quick_chords), the sort orders
  (sort_groups), the 162 stack bar (b11_notes).

**One question:** where should Down from the body figure land on the Health tab at Large text (health_padprobe has
failed the same two checks since Nov 7).

## 6. What the first in-game proving run should look for

Run smoke.txt first, then main_run.txt.

1. **The prelude.** Lines "ZEDQA layout pre default (...)", "ZEDQA pre layout char ... pinned true/true", the same
   for world, "ZeD version=...". No ERR line. Both windows at the default spread in the first picture, no console.
2. **Layout put-backs.** Each script that moves windows prints "ZEDQA layout <tag> put back". After curtain, the
   windows are unrolled. The next script's first picture shows the default layout.
3. **The car spawn.** "ZEDQA car <tag> ... spawned on spot N (x,y)" for every car, on the strip. No "car not
   ready", no "fell through the ground". If a spot keeps failing its footprint check, the line says which tile and
   why: move or drop that spot in the prelude's list.
4. **The release check.** With the helper: all checks PASS. Without: "not run: 3 the real right-click" and "NOT
   RUN" on the RESULT line.
5. **navmap.** The "LIST trap" and "LIST island" lines are the triage list. After triage, set STRICT.
6. **The one car.** Five PASS lines for 02_nyala in about 10 seconds.
7. **The soak.** Its three PASS lines and its real time (expected about 135 s). If "after the run, the reader shut"
   fails by one or two elements with no growth between rounds, the allowance is wrong, not the mod.
8. **Time.** The smoke run's wall time against 6 and a half minutes.
9. **Main run only.** The car scenes of dpad_wheels and pad_glyphs run for the first time in most runs: their
   results are new information either way. uiscale's "wholly on the screen" check at 1.5x on a small screen. The
   seven "one fix applied" scripts. cov_vehicles: one green run lets the four car picture scripts go.
10. **Rule 2.** A step that fails on its own staging gets one fix. If it fails the same way again, cut it.
