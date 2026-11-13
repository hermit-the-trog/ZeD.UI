# In-game check: Lua Console 93 Professional Edition (1.0.0)

What it is: ZeD-GUI's Lua console as a mod of its own, built from ZeD-GUI's files by
`ZeDUI/tools/products/build_luaconsole93.py` into `products/LuaConsole93`. Mod id `LuaConsole93`, debug mode only.
It runs on the plain game; with ZeD-GUI on it steps aside and ZeD-GUI's console is used. It ships as its own
Workshop item, a full release (no beta), the same day as ZeD-GUI beta 12, once this check passes.

What is different from ZeD-GUI's console, on purpose: the game's own fonts (Noto Sans; the log, the line and the
scratchpad in the game's Noto Sans Mono code face, except in a language with letters that face lacks, where that role
is the language's own Small face), no window box at the title bar's right end (it opens ZeD-GUI's
window menu), the game's own on-screen keyboard for a controller, the game's Back button wheel as the controller's
way in, chat channels sent through the game's chat box, the game's default roles as the Commands page's levels on a
server (ZeD-GUI reads the server's), no safe mode, and its own files in Zomboid/Lua (`LuaConsole93_*`).

The usual rules: `Zomboid/Lua/zedqa.lock` reads free and the game is shut before starting; set it busy while the
game runs, free after; close the game after each run. The ZeD-QA save is not used here (its mods.txt must keep
listing ZeD_UI): this check uses a copy, `LC93-QA`.

## Before the runs (once)

1. Build, check and stage, from the repo root in PowerShell:
   ```
   $py = "$env:USERPROFILE\Documents\ComfyUI\.venv\Scripts\python.exe"
   $lua = "$env:USERPROFILE\.vscode\extensions\actboy168.lua-debug-2.3.0-win32-x64\runtime\win32-x64\lua51\lua.exe"
   & $py -I ZeDUI/tools/products/build_luaconsole93.py --stage
   & $lua ZeDUI/tools/qa/luaconsole93_sim.lua
   & $py -I ZeDUI/tools/qa/kahlua_guard.py --path products/LuaConsole93/42/media/lua
   ```
   Expect `BUILT ... 61 files`, `STAGED the mod to ~/Zomboid/mods/LuaConsole93`, `luaconsole93_sim: N checks, 0 failed`
   and `RESULT: PASS`.
2. Copy the folder `Zomboid/Saves/Sandbox/ZeD-QA` to `Zomboid/Saves/Sandbox/LC93-QA` (skip if it is there).
3. Copy `Zomboid/mods/default.txt` to `Zomboid/mods/default.txt.qa-backup` (the main menu's mod list; Run 1 changes
   it and the end of the check puts it back).

## Run 1: Lua Console 93 alone on the plain game (-debug -nosteam)

1. Write both `Zomboid/Saves/Sandbox/LC93-QA/mods.txt` and `Zomboid/mods/default.txt` as:
   ```
   VERSION = 1,

   mods
   {
       mod = LuaConsole93,
   }

   maps
   {
   }
   ```
2. Launch (-nosteam so the staged copy loads, not a Workshop one):
   ```
   Start-Process -FilePath 'E:\Project Zomboid\SteamApps\common\ProjectZomboid\ProjectZomboid64.exe' -ArgumentList '-debug -nosteam' -WorkingDirectory 'E:\Project Zomboid\SteamApps\common\ProjectZomboid'
   ```
3. Main menu, Mods: Lua Console 93 Professional Edition is listed with design's box art (the "LUA 93" icon and the
   retail box poster, from `ZeDUI/art/lua_console_93/`), version 1.0.0, and is the only mod on. The main menu is the game's own (no ZeD-GUI desk).
4. Continue LC93-QA. Press the game's console key (Toggle Lua Console; the backquote by default). Expected: a window
   titled "Lua Console 93", Dark with the PZ Teal accent, the page strip at the left (Log, Commands, Help), the
   filters (KIND / MOD / FILE), the search, the log, the line with its Scratchpad keycap, the band (Export, Copy,
   Clear, Run), the help line at the foot. No box at the title bar's right end. The game's own console never shows.
5. The line: type `print("hello")`, Enter. A "ran" row and a "hello" row. Up brings the line back. Type
   `print(LC93 ~= nil, ZeD == nil)`, Enter: `true true`.
6. An error: `local t = nil; print(t.x)`, Enter. An error row from Console; click it: its stack opens in place.
   Run it twice more: still one row, its count x3. Errors: 3 in the title bar.
7. The filters and search: untick KIND > Print (the prints go, the counts follow); tick it again; type `hello` in the
   search (one row). Clear the search.
8. Export. The band says "Saved n lines to Zomboid/Lua/LuaConsole93_<date>_<time>.log". Open the file: its first
   line starts `Lua Console 93 | `, its last line says the user name is taken out, and no path in it names your
   Windows user folder.
9. The scratchpad: click Scratchpad, type two lines (`print("a")`, Shift+Enter, `print("b")`), Enter. Rows `a` and
   `b` from Console. Save snippet, name it `two`, Save: `Zomboid/Lua/LuaConsole93_snippets.txt` holds it under
   `== two`. Right-click the snippet: rename works. One line swaps back.
10. Suggestions: type `getPl` in the line: the pull-down opens above the caret with `getPlayer`. Type
    `getPlayer():get`: Java methods marked Java, with their brackets. Tab takes one; Esc shuts them.
11. Commands page: single player, every command with its debug-menu way ("Debug menu > Cheats" and the rest). Pick
    `/godmode`: the game's Cheats window opens. Help page: the four fold headers open and shut; Back to the log.
12. Look, at 4K (fullscreen, the usual QA scale): text in the game's fonts and readable, borders 2 px, nothing cut
    at the window's edges; the window drags by its title bar and resizes from its edges and grow box. Then the Steam
    Deck's size (1280 x 800 windowed, the game's font size on Auto): the window fits the screen, the log readable,
    the band's four buttons whole.
13. Controller (if one is connected): hold Back. The wheel has a "Lua Console 93" slice with the "LUA 93" icon;
    choose it. The window opens with the hand on the line. A: the game's on-screen keyboard; type `print(2)`, Accept
    (or RT): the line holds `print(2)` and nothing ran yet (no "ran" row), the hand lands on Run; A runs it. Do the
    same on the Commands page's chat line: Accept fills it, nothing is sent until Send. D-pad walks the strip,
    filters, search, log, line and band; X exports; Y swaps the line and the scratchpad; B closes and the controller
    is the player's again. Then the keys: walk with WASD and press the console key: the player moves and the console
    opens (no hidden line kept the keys). Close it with the console key and walk again.
    Paused: pause the game (game speed 0), hold Back: the wheel has no Lua Console 93 slice (as it has no Player Info
    or Crafting slice then). Unpause.
14. The hand-back switch: quit the game. Create an empty file `Zomboid/Lua/LuaConsole93_off.txt`. Launch as in step
    2, Continue, press the console key: the game's own console opens (not Lua Console 93). console.txt has
    `[Lua Console 93] handed back to the game (Zomboid/Lua/LuaConsole93_off.txt)`. Quit; delete the file.
14a. Another language: Options > Language, Russian (the game restarts its Lua). Open the console: the band's buttons,
    the placeholders and the "N of M | Errors" line read in Cyrillic, no runs of "?". Do the same in Polish (its
    letters with tails, no "?"). Back to English: the buttons and counts in the code face again.
15. console.txt for the whole run: no line `[Lua Console 93] <place>: <error>` (the mod's logged failures), no Lua
    error from a `LuaConsole93/` file in the F11 list, no `[ZeD]` line.
    ```
    Select-String -Path "$env:USERPROFILE\Zomboid\console.txt" -Pattern 'Lua Console 93|LuaConsole93|\[ZeD\]' | ForEach-Object { $_.Line }
    ```

## Run 2: both installed, in each load order

ZeD-GUI from the repo (`Zomboid/mods/ZeD-UI`, beta 12) and Lua Console 93 staged. -debug -nosteam as in Run 1.

1. Order A: write `LC93-QA/mods.txt` and `default.txt` with `mod = ZeD_UI,` then `mod = LuaConsole93,`.
2. Launch, Continue LC93-QA, press the console key. Expected: ZeD-GUI's console (title "Lua console", ZeD-GUI's
   Fira fonts, the window box at the title bar's right end), never Lua Console 93's. In its line:
   `print(LC93 == nil, ZeD ~= nil)` gives `true true`.
3. console.txt holds `[Lua Console 93] ZeD-GUI is on: its console is used`, once each time the game loads its Lua
   (the main menu's load, and the save's when the game loads Lua again for it), and no other `[Lua Console 93]`
   line.
4. Controller: hold Back: the game's wheel has no Lua Console 93 slice (ZeD-GUI's Select wheel has its own console
   slice).
5. ZeD-GUI's console works as before: a print, Export (its file is `Zomboid/Lua/ZeD_console_<date>_<time>.log`),
   the scratchpad's snippets in `ZeD_console_snippets.txt`. Lua Console 93's own files are not touched.
6. Quit. Order B: `mod = LuaConsole93,` first, then `mod = ZeD_UI,`. Steps 2 to 5 again: the same answers.

## Run 3: the release check list

- [ ] `build_luaconsole93.py --check` says products/LuaConsole93 is what the sources build (no hand edit), after
      the last console change in ZeD-GUI.
- [ ] `luaconsole93_sim.lua` 0 failed; `kahlua_guard.py --path products/LuaConsole93/42/media/lua` PASS; the five
      console sims of ZeD-GUI 0 failed.
- [ ] `products/LuaConsole93/42/mod.info`: name Lua Console 93 Professional Edition, id LuaConsole93, modversion
      1.0.0, versionMin 42.17.0, url empty, poster.png, icon.png and LICENSE.txt beside it, no require= line.
- [ ] The pictures are design's latest export: `products/LuaConsole93/workshop/preview.png`, `42/poster.png` and
      `42/icon.png` are the bytes of `ZeDUI/art/lua_console_93/` (the sim checks it; a re-export needs a build).
- [ ] No "beta" anywhere a player reads: the window, mod.info, README.txt, workshop_description.bbcode, the
      poster, the preview, the icon (the build refuses a "beta" in text; the pictures by eye).
- [ ] Runs 1 and 2 passed on 42.22 (the game's console fields the mod reads by name are 42.21 and 42.22's).
- [ ] The Workshop item is a new one (not ZeD-GUI's 3824968485): title Lua Console 93 Professional Edition, the
      text from `workshop_description.bbcode`, the preview `workshop/preview.png`, the gallery shots in
      `ZeDUI/workshop/luaconsole93/` (listed in `products/LuaConsole93/workshop/README.txt`), tags Build 42 and the director's picks. The upload is the director's step.
- [ ] The upload's folder: `Contents/mods/LuaConsole93/42/...` copied from `products/LuaConsole93/42` (the
      staged `~/Zomboid/mods/LuaConsole93` is the same files).

## The end of the check

Put back `Zomboid/mods/default.txt` from `default.txt.qa-backup` and delete the backup; delete
`Zomboid/Lua/LuaConsole93_off.txt` if it is there; set `zedqa.lock` to free. LC93-QA and the staged mod stay for the
next check.

## What to send back

- Each step's answer (pass, or what showed), with a capture of anything that looks wrong.
- The console.txt lines from Run 1 step 15 and Run 2 step 3.
- The gallery shots (`products/LuaConsole93/workshop/README.txt` lists them), saved in `ZeDUI/workshop/luaconsole93/`
  (not in `products/LuaConsole93/workshop/`: every build rewrites that folder), if Run 1 passed.
