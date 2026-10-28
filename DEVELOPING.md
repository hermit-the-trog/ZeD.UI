# Building and testing ZeD-GUI

One page for whoever maintains this next. It says what the project needs, where the
parts are, how to check a change in the game and how a build goes to the Workshop.
It was written on October 28, 2026 against Build 42.22; the game moves, so check
dates on anything that looks stale.

## What the project is

A Project Zomboid Build 42 mod, Lua only. The game loads it from
`Zomboid/mods/ZeD-UI/42/` (mod id `ZeD_UI`, never change it: saves and server
configs name it). Everything else in the repository is the workshop around the mod:
documents, tools, tests and the Workshop texts. The Workshop upload ships only
`42/` and `common/`, plus the small helper mod `ZeDUI/picks_mod/ZeD_Picks`.

Layout, from the root:

- `42/media/lua/client/ZeD/` is the mod: about 140 files, one per window, tab, HUD
  part or screen, with `Overrides/` holding the hooks into the game's own screens
  and `ZeD_*` the ZeD surfaces. `shared/ZeD/` holds the tokens and icon tables.
  `QABridge.lua` is the test bridge (below) and is left out of uploads.
- `42/media/textures/ZeD/` is the pixel art, `42/media/fonts/` the baked fonts.
- `ZeDUI/tools/` are the kits that make the art and fonts, run the tests and stage
  a build. `ZeDUI/qa/` holds test reports and captures. `ZeDUI/workshop/` holds
  every Workshop description, change note and gallery card.
- The documents at the root: `STATE.md` (what is true now, rewritten at every
  close-out), `HOOK_MAP.md` (every place the mod hooks the game, and how),
  `GLOSSARY.md` (the project's words), the `*_SPEC.md` files (one per system),
  `TRANSLATING.md` (how text and translations work), `LICENSE` and `SUCCESSORS`.

Start with `STATE.md`, then `HOOK_MAP.md`. The specs explain the why of a
system before you change its how.

## What you need on the machine

Nothing is installed by a package manager; these are the things the tools call.

| Need | Used for | Notes |
| --- | --- | --- |
| Project Zomboid, Build 42, Steam | running and testing | the tools look for it at `E:\Project Zomboid\SteamApps\common\ProjectZomboid`; change the path where they say so (search the tools for `E:\Project Zomboid` and `C:\Users\danie`, about nine files) |
| PowerShell 7 (`pwsh`) | every runner and the staging script | the `#Requires -Version 7.0` line at the top of each |
| Python 3.12 or newer with numpy, Pillow and scipy | the art and font kits, the gallery cards, the preview picture | `lupa` is optional: the dashboard tests fall back to a Lua executable |
| A Lua 5.1 or LuaJIT executable | syntax-checking a file without starting the game | any `lua.exe` will do: `lua -e "assert(loadfile('path.lua'))"` |
| JDK 19 or newer (`javap`) | reading the game's engine API from `projectzomboid.jar` | optional, for engine questions: `javap -cp projectzomboid.jar zombie.ui.UIManager` |
| A 3840 x 2160 screen | the regression runs fullscreen at 4K, UI scale 1.75x | 1080p windowed is a fallback (`-Mode windowed`), not the standard |

The game must be launched with `-debug` for any test: the bridge is inert
without it. Put `-debug` in the Steam launch options, or start
`ProjectZomboid64.exe -debug` from the game folder as the runners do.

## How a change is checked

The game is one shared instance. `Zomboid/Lua/zedqa.lock` says `busy` while a
run owns it; never launch the game for a test while it says busy or while the game
is running. Every runner sets it and frees it, also on failure.

**The bridge.** `QABridge.lua` arms itself under `-debug` and polls
`Zomboid/Lua/zedqa.go`. When that file's text changes, it runs
`Zomboid/Lua/zedqa.lua` inside the game and everything the script prints lands
in `Zomboid/console.txt`. So a test is a Lua file that prints lines starting with
`ZEDQA <tag>`, with `PASS` / `FAIL` per check and `DONE` at the end. Read
`ZeDUI/tools/qa/zedqa_mods_nag.lua` as a short example, and the step table
pattern (`at(n, fn)` on `OnTick` or `OnFETick`) in any of them.

**The QA save.** Tests run in `Zomboid/Saves/Sandbox/ZeD-QA` only: zombies off,
a stocked character in god mode on open ground. Never test in a real save. If the
QA save is missing, `zedqa_new_qa_save.lua` builds it (run at the main menu, then
once in game). Its `mods.txt` must list `mod = ZeD_UI,` or the bridge never arms
in the world.

**The regression.** `pwsh -File ZeDUI/tools/qa/zedqa_run.ps1` runs every script in
`ZeDUI/tools/qa/regression.txt` through the bridge, fullscreen at 4K, and writes a
Markdown report to `ZeDUI/qa/regression/`. It must end with exit code 0 before an
upload. A full run takes about three quarters of an hour; for one change, run only the scripts
that cover it (`-Manifest` with a short manifest file: see the small `*.txt` files
beside the scripts for the format). Run the full set before every upload, after
every game update, and after a change to shared plumbing such as the window
library or the tokens.

**Main-menu tests** (mods screen, prompts, wallpaper, Workshop window) use
`zedqa_menu_mods_run.ps1 -ModList <file> -Script <lua> -Tag <tag>`;
`mods_none.txt` is the empty mod list. **Other mods alongside ZeD** use
`zedqa_mods_run.ps1 -ModList <ids>`; the compatibility notes are in
`ZeDUI/workshop/steam_threads/2_compatibility*.txt`.

**Captures.** `getCore():TakeFullScreenshot("name.png")` from a test writes a
3840 x 2160 picture to `Zomboid/Screenshots/`. Keep full-size captures out of the
repository (the history is already heavy with them); commit a downscaled JPG or a
contact sheet.

**Things that bite.** With `-debug` the game stops on every Lua error, other mods'
included, and the Lua debugger's Break On Error is on again at every launch.
`Zomboid/debug-options.ini` is read under `-debug` (for example
`UI.DisableWelcomeMessage` hides the About Mods warning). `console.txt` is
replaced at every start, so copy it before relaunching. Kahlua, the game's Lua,
counts every local in a function against a limit of 200 under `-debug`, and
closures capture names at creation: forward declarations go above the function
that uses them. The engine quirks the project has met are in `HOOK_MAP.md` and the
specs; read the matching one before touching a hook.

## How the art and fonts are made

Each kit under `ZeDUI/tools/` has a header or README saying what it builds and
how to run it; none is needed to run the mod, only to change its pictures.

- `wheelpx/`, `tabpx/`, `icons/`: the pixel icons, drawn in Python and baked at
  the sizes the UI draws, one PNG per size under `42/media/textures/ZeD/`.
- `dashpx/`, `plates/`, `physpx/`: the car dashboards, radios and appliance faces,
  painted from data; `dashpx/luatest.py` checks the exported Lua.
- `fonts/bake_sdf.py`: the five text roles, baked from Fira Sans Condensed and
  Fira Mono (SIL Open Font License) into distance-field atlases. You need the TTF
  files; they are not in the repository.
- `mainmenu/`, `buckles/`, `seats/`, `mechanics/`: the desk, the belt buckles and
  the vehicle drawings.
- `release/make_shots.py` draws the Workshop gallery cards from captures;
  `ZeDUI/workshop/thumbnail/pixel_znix.py` draws the preview picture.

## How a build goes to the Workshop

`ZeDUI/tools/release/RELEASE_CHECKLIST.md` is the full list; the shape is:

1. Full regression, exit code 0. Commit everything that should go up.
2. `pwsh -File ZeDUI/tools/release/stage_workshop.ps1 -Version 0.2.0-tN` stages
   the mod into `Zomboid/Workshop/ZeD-UI/Contents` and stamps the version. It
   leaves out tools, notes, test art and the bridge, and copies `LICENSE` in as
   `42/media/LICENSE.txt`. `-DryRun` shows what would go up.
3. Write the build's description (`ZeDUI/workshop/tester_description_<version>.bbcode`)
   into the `description=` lines of `Zomboid/Workshop/ZeD-UI/workshop.txt`, and the
   change note (`tester_changenote_<version>.txt`) into `Zomboid/Lua/ZeD_workshop.txt`.
   Steam's limit is 8,000 characters including 58 the game adds.
4. Start Steam, start the game without `-debug`, open Workshop from the desk and
   press Upload. `workshop.txt` holds the item id: never delete it, or the next
   upload creates a second item.
5. Remove `Contents` afterwards (the staged copy shadows the dev mod) and tag the
   commit: `git tag -a v0.2.0-tN -m "Tester build 0.2.0-tN, uploaded <date>"`.

Gallery pictures go up by hand on the item page; the game uploads only the preview.

## Habits that keep the project safe

- Push at the end of every session. Tag every build. Keep a dated copy of the
  things outside the repository (the Workshop item folder, the QA save, the font
  TTFs) somewhere that is not the working drive.
- Change `42/mod.info` before every upload (name, description, author, url,
  versionMin) and keep `modversion` in step with the tag.
- Never upload without the maintainer's sign-off; never make the item Public until
  the public release is decided.
- Test at real play scale. A bug that does not show at 4K fullscreen may still show
  at 1080p, and the other way round; run both before a public build.
