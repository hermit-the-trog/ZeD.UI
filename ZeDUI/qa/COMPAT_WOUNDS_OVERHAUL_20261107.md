# Wounds Overhaul (3775026731, v0.6.2) with ZeD: QA, Nov 7 2026, game 42.21

The report: a Workshop comment by ezeepeezee says "it totally breaks compatibility for stuff like Wounds Overhaul. I can't even open my inventory, I THINK... I am getting no errors". Their load order is unknown. The director replied that ZeD will support WO.

The mod was downloaded with SteamCMD (no subscription), copied into `Zomboid\mods` for each run and removed after. QA save, 4K.

## Runs
| Run | Result | Report |
|---|---|---|
| WO, then ZeD last: prelude, every tab, Health on a controller, the right-click list, the item card, exercise info | 4 of 6 pass; the 2 failures are the same with WO off (below) | `qa/regression/2026-11-07_1632_mods_fullscreen4k.md` |
| ZeD first, then WO: the same suite | the same | `qa/regression/2026-11-07_1636_mods_fullscreen4k.md` |
| Without WO: the same suite (the baseline) | the same 2 failures, so not WO's | `qa/regression/2026-11-07_woundsov_baseline.md` |
| WO + ZeD: `zedqa_woundsov.lua` (the inventory key through the game's key event, the game's Character Info window, ZeD's own part click on the Health tab) | pass: the key opens and shuts ZeD's pair; the part menu opens with WO's entries ("Wounds Overhaul" and Cheat, in -debug) | `qa/regression/2026-11-07_1646_mods_fullscreen4k.md` |

No WO or ZeD error in any run, in either order. **The comment's "can't open my inventory" did not reproduce.** The Health tab and exercise failures in the suite are the test scripts reading a window the hover roll-up had folded. They fail the same way without WO; the release check needed the same hold today.

## What does break: WO's examination is unreachable with ZeD on
WO's design: "The Health tab becomes an examination". The body is colored by severity only; left-click examines a part (it takes time, trains First Aid); right-click treats. Until a part is examined, the treatment menu shows only "Something is wrong here." (greyed).
- WO puts its examination panel in **the game's Character Info window**, replacing the Health tab (`Wounds_Panel.lua:1354`, `ISCharacterInfoWindow:createChildren` and `:prerender`).
- **ZeD hides that window for the whole game** (`Overrides/CharacterInfo.lua:141-190`), so a player never sees WO's panel. In this run its tab row still read "Info, Skills, Health, Protection, Temperature": WO's tab never even took Health's place.
- ZeD's own Health tab names the wounds outright (cut, deep wound, fracture...). That gives away what WO hides until examined.
- WO wraps `ISHealthPanel.doBodyPartContextMenu` on game start (`Wounds_BodyView.lua:4741-4800`). It holds the menu back for any panel that is not its own, unless `Wounds.menuFromView` is set. ZeD's part click goes through that wrapper. **So on a wound that needs examining, ZeD's menu shows only "Something is wrong here." There's no way to examine, so no way to treat.** That is most likely the "breaks" a player meets. (Not reproduced here: the prelude's god mode heals the test cut at once, so the part read as not needing examination. A rerun with god mode off and invincible on will show it.)
- WO also replaces `ISHealthPanel:checkItems` (splint gate), `ISHealthPanel:render`, `ISHealthBodyPartListBox:doDrawItem` and `ISHealthPanel.setBodyPartActionForPlayer`, and wraps `ISTimedActionQueue.add` (fainting). ZeD's adapter carries getDoctor/getPatient, so `checkItems` works through it.

## Precedent inside WO
WO ships compat for other health UIs: `Wounds_ErgUICompat.lua` (Ergonomic UI: wraps its `healthPartStatus` / `healthPartStatusLines` with the exam gate, keeping care rows: bandage, splint, stitches, pain, stiffness) and `Wounds_MHPCompat.lua` (Mini Health Panel). The gate is `Wounds.body.needsExamFirst(bodyPart)`; the setting is `Wounds.examineMode()` (1 here); the examination is `WoundsExamineAction:new(character, bodyPart, onFinish, familiar, workload)` (`Wounds_ExamineAction.lua:308`, started from `Wounds_BodyView.lua:2892`).

## For Build: what support needs (Build's call how)
1. ZeD's Health tab obeys WO's gate. An unexamined part shows only what WO lets through (pain, care given), like WO's own Ergonomic UI shim.
2. A way to examine from ZeD: an "Examine" entry for the part (WO's `WoundsExamineAction`), or WO's own panel hosted as the Health tab while WO is on (ZeD already hosts mod pages through `_extTabs`).
3. When ZeD opens the menu for an examined part, WO's treatments show. Check with god mode off: a cut, a deep wound, a fracture, then stitching (WO's suture minigame window must take the mouse over ZeD).
4. Today's workaround for players: hand "Character info" back to the game in ZeD setup's ZeD screens. Then WO's panel is reachable from the game's window (not tested).

Files: `ZeDUI/tools/qa/batch_woundsov.ps1`, `woundsov_manifest.txt`, `woundsov_keys.txt`, `woundsov_mods.txt`, `zedqa_woundsov.lua`.
