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

## In flight when this was written (uncommitted)

1. **Moodles centered on the screen edge** (`ZeD_Moodles.lua`, `UI.json`, the context file).
   - The Right and Left placements center the column vertically. It stays clamped under the watch and above the belt.
   - Option text: "Right edge", plus a new tip.
   - KCheck and i18n_guard pass. **Not yet seen in game.**
   - To do: capture moodles in the right, left and bottom placements on the deep-run character, then commit.
2. **Deep-run fixture** `ZeDUI/tools/qa/zedqa_deep_run.lua` (untracked, mid-rework).
   - The first run killed the character: it was overweight, and wounds were applied without god mode.
   - Required: god mode and invisible first; strength 10 and the carry traits (Strong, Organized); weight under the max, with no Heavy Load; extra stock in the nearby containers; mild wounds that stick; a radio, TV and car within reach; a padlocked door; liquids; map notes.
   - Fix `zedqa_padmap.lua` so it opens every world and object card.
   - Rebuild the QA save first with `zedqa_new_qa_save.lua`.
   - Then rerun the pad map on the full state and compare it with the 6/4244 baseline.
   - An agent may still be running this. Check `Zomboid/Lua/zedqa.lock` and whether ProjectZomboid64 is running before you start anything.

## Open items, in order

1. Finish item 2 above, then fix the nav mismatches the full-state pad map finds. Show the director the padmap overlays (a numbered stop on a real screenshot; red marks a mismatch).
2. **The Craft and Build drawers are cut off** at the tab strip in the World window (window 1060 wide, drawer laid out to about 1540). Some controls end up off-screen. Not investigated.
3. Commit the moodle change once it's seen in game.
4. Tester build **0.2.0-t2**. Steps are in `ZeDUI/tools/release/RELEASE_CHECKLIST.md`.
   - Run the full 4K regression first.
   - Stage with `stage_workshop.ps1 -Version 0.2.0-t2`.
   - Save, re-pick the folder, then Upload. **The director presses Upload.**
   - Remove the staged Contents afterwards.
   - The t2 change note: Presets, the gamepad pass, centered moodles, the restart step.
5. The director adds the restart line on the live Steam page (their step).
6. Triage tester reports from the Steam threads (an offer stands: a daily thread check).

## How to work (lessons from Oct 23)

- **QA setup:** fullscreen 3840x2160, ZeD scale 1.75x (`ModOptions uiScale|7`), on the deep-run character with every menu full. No 1080p window unless the director asks.
- **One complete brief per agent and per game run.** Collect new director feedback for the next run instead of messaging a running agent, unless the run is actively going wrong. Use a fresh agent per task. Tiers: Haiku for lookups, Sonnet for mechanical work, Opus for hard bugs.
- **Never kill a process the session did not start** (PID only). `pzfront.ps1` no longer stops TextInputHost.
- **Shared game:** check the lock, never launch while PZ runs, close the game when done.
- **Gamepad rules** (director): focus returns to its origin; directions match the screen; land on the primary action; common actions cost the fewest presses; the belt is never a trap.
