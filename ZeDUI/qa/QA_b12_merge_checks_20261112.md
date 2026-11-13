# QA b12 merge checks - 2026-11-12 - STOPPED AT PART 1

Tested on main commit 6f1df63a2. The director halted all in-game runs while the QA scripts are rewritten, so only part 1 (the smoke run) was started and parts 2 to 8 were not reached.

## Part 1: smoke (regression.txt, fullscreen 4K, no Steam)

The run was stopped by hand at script 101 of 110 (runner and game closed by their own PIDs), so the runner wrote no report file. Results come from the runner's console log. Scripts 1 to 100 finished: 95 passed, 5 warned, none failed, none timed out. Scripts 101 (dash_brands) to 110 did not run. No crash and no Lua error stopped the run.

### Real-looking mod bug (not checked in a screenshot)
- wheel_icons: "the tab icons, and every tab of both windows has one: fishing (fishing-tab-white) has no wheel icon" and "145 slices on ZeD's five wheels, 125 with a wheel icon, the rest items, glyphs or colours: right > Tabs > Fishing: no picture"

### Test trouble (not rerun)
- cov_input: three FAILs, all on the script's known list as far as its header goes (not compared line by line): "text scale: a raised role px ... reaches the zoom (0.355 vs 0.462)", "the game's own placeholder of a ZeD entry is emptied (nil vs empty)", and a pad-unplug check that could not run because one real pad is connected.
- cov_vehicles: four FAILs (alarm clock lights ALARM; driver's door offered to get out; eight planks on seat 3 read as items; seat-move reason text). Unclear: could be the staging car, could be a real text difference; not looked at.
- twoway: "valutech: the grown window shows the whole face, no scrollbar". Unclear: a window-size timing issue or a real clip.
- rtv: three "half card where a width fits, else the full (840 px, want 385)" FAILs (radio_red, house_bare, house_ci_radio). Unclear: could be the staged window width.

## Parts 2 to 8: not reached
Console scripts, run and sneak part A, coverage-bug fixes, new coverage scripts, window and inventory checks, fix groups and bug 158 were not run.

## For the director (part 3, part B needs a real controller)
Part B manual steps live in the header of zedqa_run_sneak.lua; they were not copied because that part was not reached.

## Cleanup
Game closed, options.ini and ModOptions.ini restored from backup, zedqa.autoload 0, lock free, game speed untouched (never changed), no loops left.
