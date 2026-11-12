# Punch list 170: the Mods screen's Files tab and the error cards (in-game checks, Nov 11 2026)

Mockups: `ZeDUI/mockups/zed_mods_file_switches_v1.html`, `ZeDUI/mockups/zed_errors_v1.html`. The sim
(`ZeDUI/tools/qa/mods_files_sim.lua`, 75 checks) runs the engine's rule for which copy of a file runs; none of this has
been seen in the game yet. Report each as ok, wrong (what you saw, a picture) or not run.

Setup: ZeD-UI and ZeD_Picks in `~/Zomboid/mods` (both come in the build zip). Real Workshop mods with a broken file:
**Bandits** + **Bandits Week One** (its scheduler errors once a game minute, BWOScheduler.lua line 42, in a save not
started with it) and **Ladders!? (v0.0.13)** (a name with brackets). Keep **ZeD-GUI** on. Single player, a test save.
Before you start, copy `~/Zomboid/Lua/ZeD_picks.txt` if it exists (put it back at the end).

## 1. Errors in the game: one card per place
- Load a save not started with Bandits Week One, play two game minutes, open Messages (the note on the belt).
- Under Errors, Bandits Week One: the top card says how many errors and "From 1 place, on the card below."
- The place card: "BWOScheduler.lua, line 42, in generateSchedule" (or the file and line the game gives), "N times:
  first Day x, last Day y", the game's message in mono, "In plain words: the code looked up "schedule" in something
  that is not there.", "Called from MasterControl (...)". The count rises on the same card, no new cards.
- Copy on the card: paste in a text editor: the header, the place line with its count, one error in full, no user name.
- Controller: D-pad reaches Open in Mods and Copy on each card; A presses; B closes.

## 2. Open in Mods
- On the card press Open in Mods: Messages closes and the pause window opens on its Mods page, with a line under the
  list: "At the main menu, Mods opens at BWOScheduler.lua in Bandits Week One. ..."
- Save and quit to the main menu, open Mods: Bandits Week One is picked, on its Files tab, BWOScheduler.lua picked with
  its card open and in view (scrolled down if needed). The pad starts on the Files tab.
- Open Mods a second time: it opens as usual (the jump is used once).

## 3. The Files tab
- Bandits Week One: the tab reads "Files N"; the counts line "N code files | all on"; files grouped CLIENT / SHARED /
  SERVER with a count each; sizes at the right (B or KB) once read; sub-folder files show as "ISUI/....lua".
- BWOScheduler.lua carries a red "N errors" tag; the mod's row in the list carries "N errors" too (from the last game).
- "used by N" tags on files others name. Pick a file with no tag: its card says no other file names it, shows its first
  4 lines, and has Turn off.
- A mod with no code (a map): "This mod has no code files." and the tab is grayed. A mod that is off: "Turn it on and
  reload to see its files."
- A Simple view of the Mods screen shows no tabs (as before).

## 4. Switching a file off, and back on
- Pick a file with no "used by" and no errors, click its box (or A on its row): it is struck through, a dot at its left,
  the note says "1 file off in Bandits Week One. A reload puts it in place, no restart."; the band says "Files switched
  in ..." with Reload. The mod's row says "1 file off"; ZeD picks' row counts it.
- Pick a file "used by" others: the box opens its card instead: it names the files, says they will likely error, offers
  Turn off anyway and Turn off with the N. Same for BWOScheduler.lua (its errors, and the cleaner-fix line when 3 or
  more use it).
- Reload. Look in `~/Zomboid/mods/ZeD_Picks/common/media/lua/client/`: the file is there, one comment line. Bandits
  Week One's own folder is unchanged (its file date and size).
- In a game, the part that file did is gone (BWOIntro.lua: no intro music at boot) and nothing else of the mod changed.
- Quit the game fully and start again: the file is still off (the tab, the row's tag).
- Turn back on (the card) or Turn all back on (the counts line), Reload: the mod's own file runs again (the helper's copy
  now matches the mod's own text).

## 5. Never a game file
- A mod that replaces one of the game's files (for example any mod shipping `media/lua/client/ISUI/ISInventoryPane.lua`
  or another vanilla path): that row has the "game file" tag, its box is grayed, its card says it cannot be switched off.

## 6. Steam updates and lists
- With a file off, let Steam update the mod (or rename the file in a local copy of a mod): the file stays off; if the
  update took it out, the row says "gone" and its card offers Forget it.
- Host / server settings' mod list: the Files tab lists files but says they cannot be switched off there.

## 7. Sizes and languages
- Deck size (1280x800, Auto) and 4K at 1.75x, Normal and Large text: the tags never cover the file name; long names cut
  with "...". Check the tab, a card, and the Messages cards in one other language (FR or RU).

At the end: Turn all back on for every mod you changed, Reload, and put back your copy of `ZeD_picks.txt`.
