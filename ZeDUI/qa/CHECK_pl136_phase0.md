# In-game check: the console probe (punch list 136, Phase 0)

What it is: one QA script, `ZeDUI/tools/qa/zedqa_console_probe.lua`, that asks the game on 42.22.2 what a bigger Lua console can reach before any of it is built: the F11 error list (in and out of debug, and across a save reload), loadstring, what lands in the game's console box, sending a slash command the way chat does, listing a Java object's methods, and reading or writing log files. Each answer is one line starting `ZEDQA con0` (PASS, FACT or NOTE); nothing in the world or the save changes.

What it leaves behind on purpose: one Lua error in the corner's red count (raised so the error list has an entry to read), `/help` and one unknown command sent as chat sends them, and the file `Zomboid/Lua/zedqa_con0_test.log` (overwritten each run; it carries the run's marker to the next run, which is how the reload question is answered). With -debug the game's console (ZeD's console window) may pop open for a second and shut again.

The usual rules: `Zomboid/Lua/zedqa.lock` reads free and the game is shut before starting; the ZeD-QA save only; close the game after.

## Run 1: with -debug (automatic)

```
pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Manifest ZeDUI/tools/qa/console_probe.txt
```

The runner always launches with -debug, so this is the debug half. The drop-in from Run 2 must not be in the mod folder for this run. The verdict may read WARN or FAIL (deliberate errors, Java exceptions from the tries); the answers are the `ZEDQA con0` lines in the report.

## Run 2: a normal game, then a save reload (by hand)

1. Copy `ZeDUI/tools/qa/zedqa_console_probe.lua` to `%USERPROFILE%/Zomboid/mods/ZeD-UI/42/media/lua/client/zzz_zedqa_con0.lua`. As a game file it waits for a game to start, then runs by itself.
2. Set `Zomboid/Lua/zedqa.lock` to busy. Launch without -debug, with -nosteam so the dev copy of ZeD loads rather than Steam's:
   ```
   Start-Process -FilePath 'E:\Project Zomboid\SteamApps\common\ProjectZomboid\ProjectZomboid64.exe' -ArgumentList '-nosteam' -WorkingDirectory 'E:\Project Zomboid\SteamApps\common\ProjectZomboid'
   ```
3. Continue the ZeD-QA save. Don't pause; wait about 10 seconds (the first pass ends with `ZEDQA con0 DONE` in console.txt).
4. Escape, Quit to the main menu, Continue the same save. Wait another 10 seconds (the second pass, with the `q1.reload` answer).
5. Quit the game. Copy the lines out before the next launch rotates console.txt:
   ```
   Select-String -Path "$env:USERPROFILE\Zomboid\console.txt" -Pattern 'ZEDQA con0' | ForEach-Object { $_.Line } > "$env:USERPROFILE\Desktop\con0_normal.txt"
   ```

## Run 3: the save reload with -debug (by hand)

Steps 2 to 5 again with `-ArgumentList '-debug -nosteam'`, saved as `con0_debug_reload.txt`. Then delete `zzz_zedqa_con0.lua` from the mod's client folder and set the lock to free.

## What to send back

- Run 1's report (its `ZEDQA con0` lines), `con0_normal.txt` and `con0_debug_reload.txt`.
- Any `ZEDQA con0 ERR` line (a probe step broke; the rest still ran).
- Anything odd on screen: the console window flashing is expected under -debug; a debugger window, a stuck pause or a chat box appearing is not.
- By hand, if there is time (not scripted): the game's own console with -debug and ZeD's console handed back (Safe mode: Lua console On): can you paste into its line, select and copy in its box, how far back it scrolls, does it follow the UI scale; does a controller reach the console, the debug menu or the Admin Panel.

What each line answers, for reading the files: `q1.*` the error list (`q1.uncaught` and `q1.shape`: whether an uncaught error lands in it and what one entry looks like; `q1.reload`: whether the list survives a quit-to-menu and Continue); `q2.*` loadstring; `q3.*` the game's console object, its callable methods and which of print, DebugLog.log and errors reach its box; `q4.*` SendCommandToServer and what comes back; `q5.*` reflection on the player; `q6.*` reading console.txt and other logs, writing a .log; `q7.*` the debug menu file, wrapping print, error and log events.
