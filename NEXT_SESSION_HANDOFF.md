# Next session handoff (written Oct 29 2026)

Read this first. `STATE.md` has the feature detail; its header is stale (Oct 27). Memory notes in the project folder hold the release and QA habits.

## Where things stand (Oct 29 2026, midday)

- **Live:** tester build 0.2.0-t10 (Workshop item 3824968485, title "ZeD-GUI [TEST BUILD]"), PUBLIC for a window since Oct 28 10:40 pm; the director closes the door (back to Unlisted) on the evening of Oct 29. Repo public, tags v0.2.0-t1..t10.
- **0.2.0-t11 LIVE** (uploaded Oct 29 3:09 pm, 27.55 MB; tag v0.2.0-t11 at 31ab3f9; backup `D:\ZeD-UI backup6-10-29\`; the full 4K regression on it: 85/86, the icon-test first-run fluke). Still to do after it: the Discord note and first-post edit for t11 (computer-use on Discord needs the director's approval), the round-4 reply in the Compatibility thread (its text sits typed in the Browser pane's reply box; the Post click was refused to the session, the director presses it), and the director closes the public window (Unlisted) in the evening. Old line: Workshop/ZeD-UI/workshop.txt carries the t11 description (7,935 + 58 chars), Lua/ZeD_workshop.txt the change note (`ZeDUI/workshop/tester_changenote_0.2.0-t11.txt`). The director presses Upload twice, removes Contents, tags `v0.2.0-t11` at the staging commit, refreshes `D:\ZeD-UI backup\<date>\`.
- **Done Oct 29:**
  - Performance pass 2 (`ZeDUI/qa/perf/PERF_2026-10-29.md`, script `perf_now.lua`): the Skills tab 4.8 ms a frame to 0.95 at 4K (rows outside the scroll view not drawn, truncation cached); everything else at the cap. Next: the inventory list rows (1.6 ms), the item card (1.5), the Equip tab (1.5), the dash's pixel text.
  - Small screens (`ZeDUI/qa/Oct29_small_screens.md`): in game 1280x800 and 1280x720 pass (runner `-Width`/`-Height`). One real fault fixed: the game's own Character Info window showed at start on any screen size `layout.ini` has no block for (Q271, `Overrides/CharacterInfo.lua`). **The main menu does not fit at 1280x800** (Options, Spawn, Occupation overflow their frames; shots `ZeDUI/qa/Oct29_menu_1280x800/`): a small-tube layout is the next design piece before the Deck can be called supported.
  - 42.22: `getWorld():getGameMode()` is a Java object now; the Spawn window threw every frame (Q272, fixed with `tostring`).
  - Compatibility round 4 (`ZeDUI/workshop/compat_round4_candidates.md`): 34 new popular mods surveyed; the six on disk tested (Building Craft, Neat Crafting/Building XP, The Only Cure, The Only Cure+, Kilometers Per Hour, Knox Packs): all Compatible, 9/9. Xen's Enhanced GUI and the rest need a Steam sign-in in the browser pane (lapsed) before they can be subscribed.
  - The stack's total weight in brackets (`InventoryRenderer.lua`, `zedqa_wt_bracket.lua`) was built in a parallel session the same day; check it is committed before staging anything after t11.
- **Afternoon, Oct 29 (director: "more mods into t11, regression when I say, update by 5 pm"):** seven mods went from Compatible to Supported, each through a new general hook, a `ModSupport/<mod id>.lua` file and a QA script run with the mod on (`<x>_manifest.txt` + `<x>_mods.txt` in tools/qa): Easy Drop'n'Loot (`ContainerControls.addProvider`), Moodle Quarters (`ZeD.Moodles.setStandIn` / `rect`), Exp Recovery for Skill Books (`SkillsTab.addExtras`), Wound Expansion (`HealthTab.addExtras`; the part-menu stand-in now answers `getPatient`), Nested Containers (`ExtraContainers.lua`, `addContainerProvider` on both windows), Container Capacity Indicator (`StripDecorators.lua`, `addStripDecorator`), Evolving Traits World (rows in the Traits tab through `ModSupport/TraitsTab.lua` `addSource`, shared with Traits As Skills). HOOK_MAP and the round-3 results rows carry the detail; the round-4 thread post is drafted (`steam_threads/compat_v4/round4_post.txt`, not posted). `zedqa_hairbeard.lua` warns since the cohesion pass (it expects greyed no-tool rows that now fold): the test, not the code; being updated.
- **Open:** the main-menu small-tube layout (a design session has it); subscribe and test XEG; the Compatibility thread post for round 4; triage the Bug reports thread after the public window; the controller map screen ("Coming later.").

---

# Next session handoff (written Oct 23 2026)

Read this first. Read `STATE.md` only for feature detail. Its header and "Next session" line are stale: they stop at Oct 16. The sections below cover what happened since.

## Since Oct 16 (all committed and pushed, main)

- **Translation stage:** `ZeD.tr` and `UI.json` keys (about 2,185), plus the guard test `ZeDUI/tools/qa/i18n_guard.py` and `TRANSLATING.md`.
- **UI scale:** crisp fractional scale. Contrast tokens.
- **Performance:** roughly halved (098fd1d6; report in `ZeDUI/qa/perf/PERF_2026-10-22.md`).
- **Workshop gallery:** 31 cards, built by `ZeDUI/workshop/shots/shots.json` and `ZeDUI/tools/release/make_shots.py`.
- **Tester build 0.2.0-t1:** uploaded Unlisted as Workshop item 3824968485.
  - `Zomboid/Workshop/ZeD-UI/workshop.txt` holds the id. Never delete it.
  - The Steam threads are up; drafts are in `ZeDUI/workshop/steam_threads/`.
  - A tester call is on the PZ Modding Community Discord.
- **Fixes:**
  - Workshop window: the folder recheck, and the clipboard and keyboard in the description editor.
  - Window curtain.
  - Looks: "Presets" in place of "Outfits".
- **eabdf20a, the gamepad pass from the director's first hands-on test:**
  - Focus returns to where you started after an action.
  - Containers are reached in the natural direction.
  - A on a row opens the card with focus on Take; B goes back.
  - The belt no longer traps.
  - The bottoms of the Health and Skills tabs are reachable.
  - New tests: `zedqa_world_pad_take.lua`, and the pad map (`zedqa_padmap.lua` + `padmap.py` → `ZeDUI/qa/padmap/index.md`).
  - Mismatches dropped from 30/4652 to 6/4244.
  - The rules are in `GAMEPAD_SPEC.md`.

## Done in the evening session (Oct 23)

- **Pad map on the stocked character: 0 wrong moves of 8,332** (47 screens, both sizes, every object card except animal tracks). Overlays and the table: `ZeDUI/qa/padmap/`. The director has seen the overlays.
  - Most of the earlier 41 were captures taken while a window was still widening. `zedqa_padmap.lua` now waits until both windows are still (`whenStill`) before each capture. The director: "Windows need time to expand when you are taking screens."
  - **The Craft and Build "cut-off" was the same timing**, not a layout bug. On a still window the whole drawer shows.
  - One real move: Large text, Health, Left from the second bag row skipped Push-ups. `SpatialNav.cost` counted a 2 px overlap as 1.99 (fractional scaling); lined up is now an overlap of 1.5 px or more (`padmap.py` matches).
- **Hold A on a row now does what a double-click does** (`InventoryRenderer.quickUse`). A thing in a crate or a bag comes to the main inventory; a thing already there gets its basic action. Before, hold A ran only the basic action, which does nothing for a thing in a crate.
- **Moodles centred**, seen in game at right, left and bottom (`ZeDUI/qa/padmap/moodles_left_right_bottom.png`).
- **The stocked character (`zedqa_deep_run.lua`)** is built in the QA save. It adds a hutch and a butcher hook, restores full health before the wounds go on (they wore health down between runs), and puts the axe and torch back in hand each run. Its DONE prints a tick later, because the runner ignores a DONE that comes before the bridge's "run #" line.
- **The QA save's mod list was empty** (director: "You have to activate the mod"). The world loaded without ZeD, so the bridge never armed in game. `Saves/Sandbox/ZeD-QA/mods.txt` now lists ZeD_UI, and `zedqa_new_qa_save.lua` copies the active mods into a new save.
- **The runner clicks "click to start" only when the game is the front window** (`zedqa_run.ps1`).
- `zedqa_world_pad_take.lua` uses an eraser for its Take item (scissors count as a weapon, so their card rightly leads with Equip): 97/97.
- Last runs: the controller suites plus the pad map, 11/11 (`ZeDUI/qa/regression/2026-10-23_1847_fullscreen4k.md`); the setup plus the pad map, 3/3 (`..._1855_...`).
- Recipe for the pad map: manifest `zedqa_prelude.lua | pre`, `zedqa_deep_run.lua | deep | timeout=180`, `zedqa_padmap.lua | pm | timeout=1500`, then `py ZeDUI/tools/qa/padmap.py`. Run it without `zedqa_world_pad_take.lua` before it, or the moodles are gone (that test heals its wounds on the way out).

## Done late on Oct 23: the controller's wheels

- **The D-pad's four wheels and the Select ZeD wheel** (`DPAD_WHEELS_SPEC.md`, `ZeD_DpadWheels.lua`): Character (Left), World (Right), Social (Up), Here and now (Down), ZeD on Select (theme, accent, text size, UI scale, moodles, action bar, reset windows, ZeD setup, safe mode behind a prompt). They open only with no window holding the pad; hold, point with the right stick, let go; inner wheels in place with A / B and Back last; off slices give the reason. The belt no longer takes D-pad Left; ZeD_QuickWheel no longer adds to D-pad Right (its lists feed Character). The spec's section 6 lists what the build settled (no rooms editor, no stopwatch, no lie-down; Designated zones is World 8).
- **L3 / R3 in a window** (Hard Rule #11 amended by the director): L3 steps the list's sort, R3 flips List / Grid; footer prompts while the pad is on a list. Never bound in the world.
- The wheel bubble fits its words (`state.snug`, wheels only).
- QA: `zedqa_dpad_wheels.lua` (in `regression.txt`): every wheel on foot / in the car / by an animal, inner wheels, Back, takes, paused, the window guard, L3 / R3, every theme at both sizes; 4K and the 1080p window both pass. The test's steps run before their wait (`step(n, fn)` = n ticks after the last); a pause and its Play stay in one step (OnTick stops while paused). With no physical pad the game's usable animal is none; the test stands a spawned tame cow in for it.
- Full 4K regression with the wheels: 69/71, the two warnings were test state (an open stack from an earlier test, a curtain timing check) and pass on rerun; pad map 0 of 27,228.
- The gallery's Controller card was redrawn by the design session (commit 67587e74).

## Done on Oct 24

- **Tester build 0.2.0-t2 is up** (uploaded by the director; staged Contents removed after). The Workshop window now opens on the folder picked last with the description and change note already in (commit f4fb1c4f): Claude writes the build's `tester_description` bbcode into `workshop.txt` and its change note into `Zomboid/Lua/ZeD_workshop.txt`, and the director only presses Upload twice (`RELEASE_CHECKLIST.md` steps 12-14).
- **Driver's seat** (director: "the D-pad opens the wheels straight away; the dashboard's controls go on World > Vehicle"): sitting down no longer gives the dash the pad. World > Vehicle has **Dashboard** after the game's slices, before Back: it puts the pad on the dash's controls, B lets go (the dash also leaves the window list when LB / RB take the pad to a window). The dash's top-edge hint without the pad reads "D-pad Right: Vehicle / Dashboard". `zedqa_dpad_wheels.lua` checks all of it in the car scene.

## Open items, in order

1. The controller map screen (Help, Controller map) is "Coming later." in the wheel.
2. Triage tester reports from the Steam threads (an offer stands: a daily thread check).

## How to work (lessons from Oct 23)

- **QA setup:** fullscreen 3840x2160, ZeD scale 1.75x (`ModOptions uiScale|7`), on the deep-run character with every menu full. No 1080p window unless the director asks.
- **One complete brief per agent and per game run.** Collect new director feedback for the next run instead of messaging a running agent, unless the run is actively going wrong. Use a fresh agent per task. Tiers: Haiku for lookups, Sonnet for mechanical work, Opus for hard bugs.
- **Never kill a process the session did not start** (PID only). `pzfront.ps1` no longer stops TextInputHost.
- **Shared game:** check the lock, never launch while PZ runs, close the game when done.
- **Captures:** wait until the windows are still before a screenshot; a "cut off" in a capture is a timing suspect first.
- **"The bridge never armed in game":** check `Saves/Sandbox/ZeD-QA/mods.txt` lists ZeD_UI first.
- **Gamepad rules** (director): focus returns to its origin; directions match the screen; land on the primary action; common actions cost the fewest presses; the belt is never a trap.
