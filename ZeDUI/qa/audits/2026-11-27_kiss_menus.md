# KISS test: the menus (QA, Nov 27 2026)

The director, Nov 23 2026: "With every one of these micro QA passes, also do a KISS test." This covers the menus sweep (the main menu desk, New game, Load, Join and Host, Options with the welcome, the mod manager and its folders and load order), Hermit's go on Nov 27 ("2").

Maps (in ZeDUI/qa/audits):
- 2026-11-27_map_menu_desk.md (DK1-DK70)
- 2026-11-27_map_menu_newgame.md (NG1-NG64)
- 2026-11-27_map_menu_loadjoinhost.md (LJ1-LJ70)
- 2026-11-27_map_menu_options.md (OP1-OP80)
- 2026-11-27_map_menu_mods.md (MM1-MM78)
- 2026-11-27_map_menu_modorder.md (MO1-MO60)

Scripts (main menu only, each through zedqa_menu_mods_run.ps1 with ZeD alone, at 4K and windowed 1280x800): mu_desk, mu_new, mu_ljh, mu_opt, mu_mods, mu_order. Nothing is pressed that starts a game, loads or deletes a save, joins or starts a server, reaches Steam or the web, applies the game's Options or accepts a mod change; stand-ins take those calls. Every file the menus write was snapshotted and put back after each run; no save folder appeared or went.

## Where it stands (run 2, main 3be7262be)

| Sweep | 4K | 1280x800 | What fails |
| --- | --- | --- | --- |
| Desk | 170 pass, 8 fail | 168 pass, 10 fail | bugs only (DK47 at 1280 was a test fault, fixed c0547ec8e) |
| New game | 106 pass, 9 fail | 106 pass, 9 fail | bugs only |
| Load, Join, Host | 80 pass, 18 fail | 80 pass, 18 fail | bugs only |
| Options and welcome | 164 pass, 9 fail | 162 pass, 11 fail | bugs only |
| Mods | 103 pass, 6 fail | 103 pass, 6 fail | bugs only |
| Folders and load order | 67 pass, 7 fail | 67 pass, 7 fail | bugs only |

After Build's fixes (fix/menus, main d71db6c3a; scripts refit 6a038034f, 8c1897a77, f2b8262c4):

| Sweep | 4K | 1280x800 | What fails |
| --- | --- | --- | --- |
| Desk | 185 pass | 185 pass | nothing |
| New game | 116 pass | 116 pass | nothing |
| Load, Join, Host | 102 pass (103 with the LJ35 title check, fix/menus2) | 102 pass (103) | nothing |
| Options and welcome | 182 pass, 1 fail; 183 pass after fix/menus2 | 182 pass, 1 fail; 183 pass after fix/menus2 | nothing (OP43 fixed in fix/menus2, main 058f5e572) |
| Mods | 116 pass | 116 pass | nothing |
| Folders and load order | 76 pass | 76 pass | nothing |

- fix/menus2 (main 058f5e572): OP43 (Find is read-only and unfocused under a question) and the Connect to title and heading masked under Streamer mode (found while refitting LJ35). EVERY MENUS CHECK PASSES AT BOTH SIZES (mu_opt and mu_ljh rerun on d4fbb1088).
- Build's other known gaps: safe mode turned off while on Spawn or Looks leaves an empty map or figure box until reopened (NG23, NG62, not staged); LJ43 has no port range check; LJ40's new account is not kept.
- Test faults found in the refit: "a and K.press(...) or b" read every successful answer (nil) as "no question open" (DK19, DK59, MM2, MM53); a masked port field reads back as stars (LJ43).

Skips are cases a main-menu script must not or cannot stage (a real load, join, server, Steam, a Lua reload, other languages, other screen sizes, a real pad), each named in its line.

## Bugs for Build

Desk (ZeD_MainMenu*.lua):
- DK59, DK19: leaving the Workshop or the description editor by the menu bar, an icon or the power button drops unsaved edits with no question (the window's own Back asks). MM2 is the same on Mods: the waiting change becomes the baseline and Back stops asking.
- DK58: an upload left and come back to forgets it is waiting for Steam (onShow clears busy), so Steam's answer is dropped and Upload lights for a second send.
- DK51: File > Continue goes straight to the game's item, past MM.showView: up to 1.5 s of notepad typing is lost.
- DK14: with the pad on Cancel, the quit question's footer (and the Trash's) still says "A Quit".
- DK2: the D-pad moves the main window's focus while the monitor switches on (the pointer waits; MM.joyDir and MM.joyDown do not test MM.poweringOn).
- DK18: the power button's hint never points at the button (its hit is on the desk, the hint looks on the glass).
- DK21 (1280x800): menu bar pull-downs are never fitted to the tube: the ZeD menu ends at 720, the tube at 625.
- From the notes: DK30 (once the left column reaches the icons, Mail, Documents and every sticky note are dropped from the desk), DK44 (the Desktop window has no scroll on a short tube).

New game:
- NG34: ZeD's tick box passes changeOptionArg1 and 2, but B42's ISTickBox keeps them in changeOptionArgs[1] and [2] (ISTickBox.lua:47, 317), so the game's tick handlers get no option name: unticking Zombie Migrate leaves Redistribute hours at 12.0 (the game sets 0.0). ZeD_MainMenuOptions.lua:356; any game tick handler that reads its args is hit.
- NG50: the Traits help band has room for 2 lines; 20 occupations' descriptions run 4 to 7 (Blacksmith 5, Chef 5...): cut with no scroll.
- NG51: Save build offers the occupation's name with no number (the game offers "Custom Occupation 1") and saving it overwrites that build with no question.
- NG39: a preset saved under a built-in's name (Apocalypse) reloads as the built-in.
- NG12: the World step's Next help says "start the new game in the chosen world"; Next goes to the spawn town.
- NG30: in debug the shutoff rows read "Water Shutoff" where the game reads "[DEBUG] WaterShutModifier".
- NG23, NG62: after Spawn or Looks has been shown, the game's map panel and 3D figure stay inside ZeD's hidden windows (the map's mouse swapped to ZeD's); safe mode's hand-back does not return them, so the game's own screens would have no map or figure.
- NG4 (modded only): the challenge grid has no scroll; with many challenge mods the rows run under the band.
- From the notes: NG61 (the voice preview sets the music state to InGame and nothing puts the menu music back).

Load, Join, Host:
- LJ12: New player on a save that cannot be played still calls setSavefilePlayer1(-1) before Play refuses in silence (New player is not greyed in More).
- LJ9: with player 1 dead and another character alive, the row and preview read "Alive Al, dead".
- LJ18: click a save, arrow off and back, click again within 450 ms: it plays (clickSave compares only the key and the time).
- LJ33: a click on another row while Remove asks changes what Remove removes (Load keeps the target; Join does not).
- LJ34: under the password question, a double click on another account connects that one.
- LJ35: Streamer mode does not mask the address and port in the server form, and the invite view's heading prints host : port.
- LJ56: the host screen never draws why a server stopped (the game always shows it).
- LJ57: a settings name starting with n breaks its folder path in the Delete world question (the backslash and n become a line break).
- LJ2: leaving an idle Host by the menu bar leaves the game's host screen shown, parked off screen.
- LJ16: the preview's Version label is a bare English word, not a key.
- Pad dead ends: LJ10 (Playing as), LJ24 (Rename's field), LJ36 (Join's filters, sort heads, Streamer mode; Remember password and Steam relay), LJ49 (the authenticator code), LJ30 (the mode heads fold by mouse only). LJ25: Rename's field and Join's password field have no click box.
- From the notes: LJ43 (an empty port saves as 16262 where the form offers 16261), LJ44 (the second of two saved servers on one address cannot be picked, edited or removed), LJ40 (Connect on a public server saved with two accounts jumps to Saved with no account picker).

Options and the welcome:
- OP43: under Back's question the rows and pages still take clicks (27 row and 9 page hit boxes live).
- OP44: a question raised on the button map page is never drawn there.
- OP46: Back with no row changed asks "Discard 1 changes?".
- OP61: on the pad the key band's focus lands on confirm:yes, an answer the band does not have.
- OP74: reopening the welcome starts Tutorial on "Show me around" again, so Accept turns the tour back on.
- OP75: Load a setup takes the UI scale and Playing with but applies neither until the next menu or game start.
- OP76: a setup file with no valid line loads as done (0 lines) and the welcome closes with nothing changed and no word.
- OP33: a stored color off the 84 swatches gets no frame and the pad starts on swatch 1.
- OP5: the Advanced (Reload) sound button's row has no name and no help.
- OP31 (1280x800): ZeD setup tips over three lines are cut at the help band with no mark (Menu opens on its best guess; Preset; Other mods' notes).
- Measured, for Build to weigh: one letter in Find halves the frame rate (156 to 74 frames in 1.5 s at 4K): every group and help line is rebuilt each frame.

Mods:
- MM53: Paste over an existing profile's name replaces and saves it, then says "Nothing to add: the text is not a profile".
- MM57: a pasted profile whose ids lead with "\" keeps its mods but its order comes out empty (ZeD_MainMenuMods.lua:1002).
- MM3: ZeD-GUI's own Open in Options is not greyed while a change waits (every other mod's is), so it leaves as in MM2.
- MM4: the close box on the Profiles page leaves its Rename question open on the list page.
- MM5: a waiting reload (files switched) is forgotten when the window is left and opened again, so Accept does not reload.
- From the code: MM64 (Discard changes leaves a changed load order in place, while its help says it throws away everything).

Folders and load order:
- MO5: a deleted folder's color and label stay under its number: a later folder 1 starts red and blue.
- MO8: Move to folder says "5 mods are in QA Dest now" when 2 moved (3 were there).
- MO13: closing a folder by its triangle leaves the pad's focus on a hidden row.
- MO32: Done refused on a red row across separators says "or press Auto", which cannot fix it.
- MO33: Start separators from folders' help says each section "is then sorted", but each keeps its order.
- MO43: a requirement that is not installed reads "needs X (off)", the words for one that is off.
- MO9: the 99-folder cap (and any refusal) reads "ModFolders.cfg could not be written".
- From the notes: MO12 (Delete folder's question does not say that member lines for mods not installed go too).

## Test faults found (QA's side)

- MM10 wrote an empty tab to ZeD_modsview.txt, so the next visit opened on a tab with no rows and the script gave up on the rest (4K run 1).
- DK47: a rewind meets the top on its first frame and plays on; the end of the roll was read from a box height 90 px off at 1280x800.
- DK52 and DK58 staged failures that raise inside ZeD's own pcall; a -debug run counts caught errors. The upload is now faked at its first Steam wait.
- NG64 judged the stub's removal by a raw nil the window never had.
- LJ6's stand-in save info throws on purpose; its errors are now taken off the count.
- OP19 expected the dot from one setting; the trio's choice as found was 3.
- MM15: the list picks its first row on the first frame by design.
- MO55: with ZeD alone the game's own map order is empty too (includeVanilla false).
- The models' server list key read the server settings screen, which the main menu does not have.

## KISS: what costs the player most (ranked)

1. Work lost with no question when a window is left by the menu bar, an icon or the power button (Workshop, description editor, Mods changes, a waiting reload).
2. Pad dead ends on Load and Join (Playing as, Rename, the filters, the account form, the code field, folding groups): the player must reach for a mouse.
3. Help text cut with no mark (the Traits band, ZeD setup tips at 1280x800, long tips).
4. Words that say the wrong thing (World's Next, "or press Auto", "sorted", "needs X (off)", "could not be written", "Nothing to add", "Discard 1 changes?").
5. Questions that land the pad on the action (Exit on the quit question, Turn on for a template) and one-press actions the game asks about (Homepage, the terms' Quit).

## Design calls for the director (asked Nov 27 2026)

Option 1 is QA's pick in each.

Hermit's picks (Nov 27 2026): "1 (1); 2 (2); 3 (1); 4 (2); 5 (1); 6 (2); 7 (1); 8 (1); 9 (1)".
- To build: 1 the quit questions land the pad on Cancel; 3 B in the welcome goes back one step (Skip only its own button); 5 a chord pick counts as a change Discard undoes; 6 No mods says in its question that it turns ZeD-GUI off; 7 Homepage asks first; 8 leaving the load order page after a move asks "Keep the new order?"; 9 a new account may have an empty password.
- No change: 2 the terms' Quit quits at once (the game's way); 4 Reset to defaults resets everything, as today.

1. **DK13, the quit question on a pad:** the pad lands on Exit, so A then A quits. (1) land on Cancel, as the notepad, Documents and Mail questions do; (2) keep it on Exit.
2. **DK48, the terms' Quit:** it quits at once, as the game's does, while every other quit on the desk asks. (1) ask, like the rest of the desk; (2) keep the game's way.
3. **OP72, B in the welcome:** B (the pad's usual back) is Skip: every pick is thrown away and the setup is marked seen. (1) B goes back one step and Skip is only its own button; (2) keep B as Skip.
4. **OP29, Reset to defaults:** it also resets Safe mode, the input lock and every screen given back to the game. (1) leave those three alone; (2) reset everything, as today.
5. **OP24, chords and Discard:** a chord pick saves at once and Discard does not bring it back. (1) count it as a change that Discard undoes; (2) keep saving at once.
6. **MM25, No mods:** it turns ZeD-GUI off too, with no word. (1) keep ZeD-GUI on under No mods; (2) say so in the question; (3) keep as is.
7. **MM31, Homepage:** it opens the mod's page in the browser at once; the game asks first. (1) ask first, as the game; (2) keep one press.
8. **MO40, leaving the load order page:** B and Escape leave after a move with no question and the move is dropped; the game asks whether to keep a changed order. (1) ask "Keep the new order?"; (2) drop it silently, as today.
9. **LJ37, an account with no password:** ZeD refuses a new account with an empty password; the game allows one. (1) allow it, as the game; (2) keep refusing.

## Not staged

- Anything that loads a save, joins or starts a server, reaches Steam or the Workshop, reloads Lua or quits.
- A real pad, a real mouse drag, real key presses timed by hand.
- Languages other than EN, screen sizes other than 4K and 1280x800, 1280x720 with Large text.
- Safe mode's hand-back of the game's screens (NG23 and NG62 prove the panels are left inside; turning safe mode on was not staged).
