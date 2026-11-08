# Check: the Lua console in ZeD's parts (punch list 106, Nov 7 2026)

What changed: the game's debug-mode Lua console (the Java window that the Toggle Lua Console key opens, bottom left)
is now a ZeD window. The game's console stays the engine, parked off the screen: what you type runs through the
game's own ProcessCommand, the list is the game's own output box, the history and the Tab suggestion are the game's.
Code `42/media/lua/client/ZeD/ZeD_DebugConsole.lua`; ZeD wheel slice in `ZeD_DpadWheels.lua`; sim
`ZeDUI/tools/qa/debug_console_sim.lua` (689 checks, no game). HOOK_MAP rows: Owned table and row 32.

Not run in game yet. Everything below is for QA.

## Launch

- Debug mode only: launch with `-debug`. QA's `zedqa_run.ps1` already passes it (`-debug -nosteam` with
  ZEDQA_NOSTEAM=1). Without `-debug` nothing of this exists: check that once too (no console, no wheel slice).
- This rig's `Zomboid/debug-options.ini` has `UI.DebugConsole.StartVisible=true`, so the console is up when a game
  starts. With ZeD on, that is now ZeD's window at the bottom left. The gallery scripts that hide the game's console by
  its flag (`gallery_console_off.lua`, `gallery_hidecon.lua`, `gallery_beta_new.lua` and the others) shut ZeD's too,
  because ZeD's follows the game's flag. Worth one gallery run to confirm no console shows in a capture.
- Game versions: built against the 42.21 / 42.22 class (javap). Check on whatever the rig runs.

## What to do (mouse and keyboard)

1. In game, press the Toggle Lua Console key (Options > Keys, Toggle Lua Console). ZeD's "Lua console" window
   opens at the bottom left: striped title bar, close box, window box, the list, a `>` line, the band (Copy all,
   Clear, Run) and the help line. Press the key again: it shuts. The game's own grey console must never show.
2. The list shows what the game's console would: the "Lua Debug Console" banner and the game's log lines (with
   `UI.DebugConsole.DebugLog=true`).
3. Click the line, type `print("hello")`, press Enter. `hello` shows in the list (the game's log line). The line
   empties and keeps the keyboard. With `UI.DebugConsole.EchoCommand=true` the typed line is echoed first, as in the
   game's console.
4. Type `local t = nil; t.x = 1`, Enter. The error and its stack trace show with a red square at the first line and a
   red rule down the trace; the title bar says "Errors: 1". Click any line of the trace: the whole error is picked
   (accent wash); Copy now says Copy. Copy, paste into Notepad: the whole error. Click it again to let it go; Copy all
   copies the whole list.
5. Type `this is not lua`, Enter: the console's own compile message shows, marked red, "Errors: 2".
6. Up and Down in the line: the lines you ran, oldest at the top; Down past the newest gives back what you had typed.
   Running the same line twice keeps one history entry (the game's rule).
7. Type `getPl`: the help line says "Tab: IsoPlayer getPlayer" (the game's suggestion). Tab: the line becomes
   `getPlayer()`.
8. Clear: the list empties ("Nothing printed yet."), Copy all and Clear gray out. Typing `clear` and Enter does the
   same (the game's own command).
9. Scroll: mouse wheel and the scrollbar; scrolled up, a small accent square sits at the foot; new output does not
   move what you are reading. Resize from the edges and the grow box; drag by the title bar; double-click the title
   bar to roll it up.
10. Escape while typing: the line lets go of the keyboard and the window stays. Escape with the line not typing:
    the pause menu, as before (the console never takes Escape, since it can sit open all game).
11. Close box: shuts it; the key opens it again where it was.
12. Safe mode On (Options > Mods > ZeD-GUI): with ZeD's console open, the game's own grey console comes back in its
    place, open. Safe mode Off: ZeD's again.
13. Check `console.txt` for `[ZeD]` lines and Lua errors from `ZeD_DebugConsole.lua`. One line is expected only if the
    console's parts were not found ("the game's console parts were not found; the game's own stays").

## Controller

1. Select (Back) opens the ZeD wheel: in debug mode its last slice is "Lua console" (bug icon). Pick it: the window
   opens with the controller on the line (accent focus mark), help line "D-pad Move, A Keyboard, LB Older, RB Newer,
   B Close".
2. A: ZeD's pad keyboard opens docked at the screen's foot and types into the line. RT accepts: the controller lands
   on Run. A runs it.
3. LB and RB on the line step through the history. Up from the line goes into the list, the newest line picked; Up and
   Down walk it (an error is one step); Down past the newest comes back to the line. Down from the line: the band;
   Left and Right between Copy, Clear and Run.
4. B closes it and gives the controller back.
5. The game's key with a controller in use opens the window without taking the controller (as the game's console):
   reach it through the wheel.

## Sizes

- 4K fullscreen at 1.75x (QA's usual), Normal and Large text: the band whole, nothing clipped, the line's text inside
  its field, error marks in the gutter.
- Deck 1280x800 and 1280x720 at Auto, Normal and Large text (`zedqa_run.ps1 -Mode windowed -Width 1280 -Height 800`):
  the window fits on the screen; at its smallest (drag the grow box in) the list keeps at least three rows.

## Known limits

- On a server, a line runs only for a role with the game's UIManagerProcessCommands capability or the co-op host (the
  game's own test); otherwise Run grays and the help line says the server does not allow it. Not tried on a server.
- The suggestion and the output arrive on the game's UI tick (about every 100 ms on 42.22), as in the game's console.
- The line holds 256 characters, as the game's.
