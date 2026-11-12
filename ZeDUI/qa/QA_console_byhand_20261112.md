# Lua console, by-hand answers (Nov 12 2026)

`-debug -nosteam`, ZeD-QA save, 4K fullscreen (the Deck size at 1280x800 windowed). Keys were injected with the OS keyboard (one action per call); computer-use key presses were refused by "user interrupt".

## Kahlua's error wording in ZeD's console log

- Typed `local x = nil; x.y = 1`. ZeD's rows: a "ran" row, then an error row `attempted index of non-table` (a second error row shows the stack line `zombie.ui.UIDebugConsole.ProcessCommand(U...`). console.txt: `Lua fail. Message: attempted index of non-table` and `java.lang.RuntimeException: attempted index of non-table at KahluaUtil.fail(KahluaUtil.java:100).` (There is no variable name in this wording; the con0 probe's pcall/loadstring route gave `attempted index: x of non-table: null java.lang.RuntimeException`.)
- Typed `1 +`. ZeD's error row: `console:1: unexpected symbol near `1``. Another incomplete line, `print("two"ab`, gave `console:1: ')' expected near `<eof>``, and `x1` gave `console:1: '=' expected near `<eof>``.

## print and tabs

`print("a", "b")` joins its arguments with a tab (console.txt: `a<TAB>b`). The output shows in two rows: a plain `a    b` row, and the `LOG : Lua f:19099> a    b` row (the DebugLog copy), so twice.

## Shift+Enter in the scratchpad

Plain Enter runs the code (observed: the box ran and cleared). Shift+Enter: the footer and the Help page say it makes a new line ("Enter runs the box, Shift+Enter makes a new line"; Help: "Shift+Enter: A new line in the scratchpad"), but with injected input the game saw Shift+Enter as plain Enter every time (three methods tried), so the new line was not confirmed by hand. It needs a real keyboard.

## Deck size

At 1280x800 windowed, Auto UI scale, Normal font, the console window fits: strip, filter column, log, line, Scratchpad button, the Export, Copy all, Clear and Run buttons and the footer are all inside the window, which sits in the lower left (about 690 x 360 px of the screen). Screenshot (not committed): `zqa_deck_1280x800_console.png` in the QA scratch folder.

## Suggestions and Commands

- Typing `getPl` shows the suggestion pull-down (getPlayerByOnlineID, getPlayerContextMenu, getPlayerData, getPlayerFromUsername, getPlayerHotbar, getPlayerInfo, getPlayerInfoPanel, "Globals | 12 more"); footer: "Tab or Enter takes the picked suggestion...".
- Tab takes the first suggestion: the line becomes `getPlayer()` with the cursor between the brackets.
- The Commands page opens and reads correctly (Single player 73 of 73, groups Players and Items and skills, each command with its text and the debug-menu route; the descriptions truncate with "..."; commands that single player cannot send read "Nothing like it alone").
- The Help page opens and reads correctly. One oddity: the first row of its Keys list reads `NONE` for "Opens and closes the console (the game's own key, Toggle Lua Console in its key options)", i.e. the key is shown as NONE (unbound on this machine).
