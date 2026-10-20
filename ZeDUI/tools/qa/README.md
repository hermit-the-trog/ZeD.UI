# ZeD QA bridge — how to run tests inside the game without a restart

Requires the game launched with `-debug` (Steam launch option). `42/media/lua/client/ZeD/QABridge.lua` arms itself at world load and polls two files in the Zomboid user folder's `Lua/` directory every 30 ticks:

- `Lua/zedqa.lua` — the script to run (plain Lua chunk, full game API, `print` goes to `console.txt` as `LOG : Lua`).
- `Lua/zedqa.go` — the trigger. Any change to its first line runs `zedqa.lua` once.

Workflow from a shell:

```bash
cp ZeDUI/tools/qa/suite_verbs.lua "$ZOMBOID/Lua/zedqa.lua" && date +%s > "$ZOMBOID/Lua/zedqa.go"
tr -d '\000' < "$ZOMBOID/console.txt" | grep ZEDQA
```

(`tr -d '\000'` because a second game instance once truncated the log under the first.) Both ZeD windows must be open (`i`, game unpaused) for window scripts; scripts call `setGameSpeed(1)` when paused. Scripts schedule follow-up checks with an `Events.OnTick` counter (`at(n, fn)` pattern) so one trigger covers a whole sequence of timed actions.

Scripts in this folder were all run and passed on stable 42.20.2 in S123 (see `ZeDUI/deltas/SESSION_123_DELTA.md`). Gamepad A/X cannot be resolved without a physical controller (`getJoypadData(0)` is nil), so scripts call element callbacks (`onActivate`, `onContextMenu`) directly, which is exactly what the FocusManager resolver calls.

| File | Covers |
|---|---|
| `suite_verbs.lua` | ItemCard header verbs through `_dispatchHeaderVerb`: UNEQUIP/EQUIP clothing, READ, EQUIP 2H weapon, EAT, DROP, TAKE + `_effectiveContext` after each |
| `suite_tabs.lua` | Walk every tab in both windows via the real strip click handlers; focusable census per tab |
| `suite_gamepad.lua` | Simulated D-pad through `Focus.dispatchJoypadDir`, row callbacks (card open / live-swap / close, context menu, B), stale-zone check after a mouse Loot switch |
| `suite_band.lua` | Progress Band: reading via the queue poll, cancel via the card, cooking on a real stove with the danger state |
| `suite_perf.lua` | ms/tick per tab + builder cost of the recipe lists |

## Windowed launches (Oct 14 2026)

QA runs in a 1920 x 1080 window, never fullscreen (director). From PowerShell (the Bash tool hits the execution policy):

- `& ZeDUI/tools/qa/pzlaunchwin.ps1` — windowed, -debug, continues the latest save (the QA save) through the bridge's autoload flag, clicks "click to start".
- `& ZeDUI/tools/qa/pzlaunchwin.ps1 -MainMenu` — windowed, stops at the main menu (returns once the bridge has armed there).
- `& ZeDUI/tools/qa/pzrestorewin.ps1` — after the game has closed: puts back the fullscreen display settings it backed up.

The bridge polls OnFETick at the main menu and OnRenderTick in game (so it also runs while the pause menu is open). The window's client area is 1920 x 1080 at a desktop offset (find it with `GetClientRect` / `ClientToScreen`); real input: screen = offset + game coordinates.

## Unattended regression (Oct 19 2026)

`zedqa_run.ps1` runs the whole bridge library on its own and leaves a report, so keyboard-and-mouse QA can be replayed often at both of the director's setups. PowerShell 7, from any folder:

```powershell
& C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/zedqa_run.ps1                     # 1920 x 1080 window (default)
& C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/zedqa_run.ps1 -Mode fullscreen4k   # the director's 3840 x 2160 fullscreen
& C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/zedqa_run.ps1 -Check              # read the manifest only: no lock, no game
```

Other options: `-TimeoutSec 180` (per script), `-Manifest <file>`, `-Report <file.md>`, `-KeepOpen` (leave the game running at the end).

**The lock.** The game is one shared instance. The runner refuses to start (prints why, exit 2) while `Zomboid/Lua/zedqa.lock` says `busy`, while `ProjectZomboid64.exe` is running, or when `Zomboid/latestSave.ini` does not read `ZeD-QA` / `Sandbox` (the autoload continues the latest save). It writes `busy` for the whole run and `free` at the end in a `finally`, also when a run fails or the runner itself errors.

**A run.** Windowed: `pzlaunchwin.ps1`. 4K: `pzrestorewin.ps1` first, autoload `1`, `ProjectZomboid64.exe -debug`, then a click at the screen centre (1920,1080) for "click to start". The runner waits for `[ZeD.QA] bridge armed (in game` (clicks again if it does not come) and checks the loaded save is `Saves/Sandbox/ZeD-QA` before any script runs. Per manifest line: copy the script to `Lua/zedqa.lua`, bump `Lua/zedqa.go` with a counter kept in `Lua/zedqa.counter` (starts at 10000), then read only what `console.txt` gained since the bump (NULs stripped) until `ZEDQA <tag> DONE` (counted only after that bump's own `[ZeD.QA] run #` line, so a late DONE of the script before cannot end it), `[ZeD.QA] run #N ok=false` or the timeout; no console line at all within 20 s of the bump means the bridge had not armed, so it bumps once more (a game that is logging but slow is never bumped twice: that would run the script twice); 3 s between scripts. The prelude runs right after the bridge arms; if it reports `ERR OnTick never ran` (the game still paused behind "click to start") the runner clicks again and reruns it, twice at most. A timeout (the script may still be running in the game), a game still paused, or the game closing / dropping to the main menu stops the run there: the rest are reported as not run. At the end: autoload `0`, `getCore():quit()` twice (in game to the main menu, then at the menu to the desktop), `pzrestorewin.ps1` after a windowed run once the game has closed. It never kills the game; if the game will not close the report says so.

**Statuses.** PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with an ERR line of the script's own (a `ZEDQA` line with `ERR` or `FAIL`, case-sensitive, `spawn failed`, `step error` or `step <n> failed`), or the script ran twice (a re-bump). FAIL: `ok=false` / a compile error, a Java `Exception thrown` or `attempted index` in the script's window (each one is shown with its first detail line), or the game closed / dropped to the main menu. TIMEOUT: no DONE in time. Not run (SKIP): after a timeout, a paused game or a lost game. A `ZEDQA` line whose tag is another manifest entry's is listed as "late output from <tag>" and not charged; untagged prints (`ZEDQA step error: ...`) count for the script running. `(expect ...)` prints are shown, not checked: read them in the report. With `-debug` the game logs a stack trace even for an error a script catches, so a step ERR usually comes with an exception and reads FAIL; WARN is an ERR line with no Java exception behind it.

**The manifest** is `regression.txt` beside the runner: one script per line, relative to this folder, `<script> | <tag> | timeout=<s> | end=<regex> | expect=<regex>   # comment`. Only the script is needed; the tag defaults to the script's own `say()` prefix and must be unique across the manifest (the runner and `-Check` refuse a repeat), `end=` names the closing line of a script that prints no DONE (`zedqa_furniture.lua`), `expect=` an exception a script raises on purpose (`zedqa_audit_fixes.lua`). It starts with `zedqa_prelude.lua` (opens the window pair, unpauses, god mode, prints `ZEDQA pre DONE`), then the five suites, then 53 in-game scripts grouped by area, the vehicle tours and `zedqa_soak.lua` last. Its closing comments name every script left out and why. `-Check` prints the resolved list and names any `zedqa_*.lua` / `suite_*.lua` here that the manifest neither lists nor mentions, so a new script gets a decision.

**Allowlist rule.** A script goes in only if it runs in game, ends with a DONE line (or an `end=` line) and puts back what it adds; god mode on, the character moved beside the pickup and the radio captures' clear weather are accepted leftovers. Setup builders, real-mouse companions, multi-run scripts, scripts that enter any car in the cell, main-menu scripts and the never-unattended set stay out. The runner itself refuses the never-unattended names (`zedqa_new_qa_save`, `zedqa_mod_workshop`, `zedqa_mods_*`, anything with workshop or upload in its name, `zedqa_overnight_*`, `zedqa_menu_*`, `zedqa_desktop`, `zedqa_desk_v3`, `zedqa_menushot`, `zedqa_titlevideo`, `zedqa_death_sleep`, `zedqa_modapi_probe*`, `zedqa_body`, `zedqa_avatar*`, `zedqa_figure_tabs`) and any script whose source can quit the game, make a save, reach the Workshop or runs on `OnFETick`, whatever a manifest says. Known leftover: `suite_verbs.lua` keeps the book, bat and apple it spawns (three more each run).

**The report** goes to `ZeDUI/qa/regression/<yyyy-MM-dd_HHmm>_<mode>.md` and is rewritten after every script, so a stopped run still leaves one: a header (start and finish, mode, the display lines of `options.ini`, the game build from the log, the mod version from `42/mod.info`, the manifest, the result, the go numbers), run notes (launch, clicks, quit, restore), a results table (script, tag, status, seconds, the screenshots it produced: `zqa_` / `zedqa_` names from its source or its output written after its bump, notes), one section per script (go numbers, notes, every `ZEDQA` line and every ZeD / Lua ERROR entry with its message and Lua frames), and "Console errors outside scripts": the ERROR lines from launch to quit that fall in no script's window, once each with a count. Screenshots stay in `Zomboid/Screenshots`; the next run overwrites them. The runner prints one line to stdout, `<pass>/<total> pass, <warn> warn, <fail> fail, <timeout> timeout[, <n> not run] -> <report path>` (the not-run count appears when scripts were skipped, so the line adds up), and exits 0 when nothing failed, timed out or was skipped, 1 otherwise.
