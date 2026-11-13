Lua Console 93 Professional Edition 1.0.0
A Lua console for Project Zomboid Build 42, for mod makers. Debug mode only.

WHAT IT IS
The game's own Lua console (the one -debug gives you) as a window you can work in. The game's
console still runs everything: this mod is the window over it. Close the window and the game's
console is closed too.

OPENING IT
Start the game with -debug. In a game, press the game's console key (Toggle Lua Console in the
key options). With a controller, hold the Back button: the wheel has a Lua Console 93 slice.

WHAT IT DOES
- Log: everything the game prints in debug mode and the F11 Lua Debugger's errors, one row each.
  Filter by kind (print, warning, error, ran here), by mod and by file, and search. A repeated
  error is one row with a count; click an error to open its whole stack. Export writes what the
  filters show to a new .log file; Copy copies it.
- The line: type Lua and press Enter, and it runs through the game's own console. Up and Down
  step through what you ran.
- Scratchpad: many lines, past the game's 256 characters. Enter runs it, Shift+Enter makes a new
  line. Save what you write as snippets; your last runs are kept as history.
- Suggestions: globals after two letters, a table's fields after a dot, an object's methods
  after a colon, Java methods marked Java. Tab or Enter takes one.
- Commands: every server command with its syntax, an example and the role it needs. On a server
  only the ones your role may use; a click fills the line and Send sends it. In single player
  each one points at the debug menu's own way of doing it.
- Help: what runs where, the keys, the controller and the files, in the window.

FILES (in Zomboid/Lua)
- LuaConsole93_<date>_<time>.log: each Export.
- LuaConsole93_snippets.txt: your snippets (a plain text file: edit it freely).
- LuaConsole93_history.txt: your last runs.
- LuaConsole93_off.txt: make an empty file of this name and the game's own console is used instead,
  from the next game start.

WITH ZED-GUI
ZeD-GUI has this console built in. With ZeD-GUI on, Lua Console 93 steps aside and ZeD-GUI's
console is used; nothing to set. You do not need ZeD-GUI for Lua Console 93.

LOOK
Dark, with the PZ Teal accent, in the game's own fonts. The window grows with the screen and the
game's font size option. Its text is in the 28 languages the game ships.

CREDITS
Made from ZeD-GUI's Lua console by Hermit the Trog. ZeD-GUI's source-available license covers it.
