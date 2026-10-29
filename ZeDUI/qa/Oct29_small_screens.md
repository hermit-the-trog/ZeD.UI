# Small screens: 1280x800 and 1280x720 (Oct 29 2026)

The director's priority before the release (Oct 28 2026): the Steam Deck (1280x800), 720p laptops and older gear. First pass, in a game window of each size on the ZeD-QA save (the stocked character, every menu full), ZeD's UI scale on Auto, game 42.22, the code after 0.2.0-t10 plus the Skills tab change of the same day.

## How

`zedqa_run.ps1 -Mode windowed -Width 1280 -Height 800` (new that day: `-Width` / `-Height` on the runner and on `pzlaunchwin.ps1`; the report's name carries the size, `..._windowed1280x800.md`). The manifest: the prelude, the tab walk, the window and scale scripts, the grid, Large text, the curtain, the pad map's cone audit, the card on the pad, the maps, the tab icons, the moodles, the hands, the D-pad wheels, Sandbox options, Messages, and the cohesion walk's 34 captures. At 720 the same with `zedqa_small_probe.lua` after the prelude (a census of every visible top-level element, the game's own Character Info window, ZeD's windows' rects, one shot bare and one with the pair). Screenshots kept beside this page: `Oct29_small_1280x800/`, `Oct29_small_1280x720/` (contact sheets `sheet_*.png`).

Reports: `regression/2026-10-29_0935_windowed1280x800.md` (18/19), `regression/2026-10-29_0947_windowed1280x720.md` (19/20).

## What the screen looks like

At both sizes the root scale is 0.75 (`ZeD.Scale.MIN`; 800/1080 would be 0.74, 720/1080 0.67). So the UI is three quarters of the 1080p design, and the windows have MORE design room than at 4K (a half-screen window is 640 px = 853 design units; at 4K and 1.75x it is 444 units): no column drops, no cut labels, the Craft tab's sort strip shows all its radio buttons inline (so no pop-up: the cohesion walk's one warning at both sizes is its own expectation, not a fault). Vertically the design has 1,067 units at 800 and 960 at 720; the windows open at their saved heights (315 px here, the QA save's), the card, the maps pop-out, Sandbox options, Messages, the wheels, the moodles and the belt all fit, at Small and at Large text, in every theme.

## The one fault, fixed

The game's own Character Info window (Info / Skills / Health / Protection / Temperature, the figure, "Zombies Killed") was on screen for the whole run, under ZeD's windows and plain when they were shut (`zqa_sp_bare.png`; the probe: `vanilla char info: visible=true @300,100 354x378 visibleOnStartup=true`). Cause: the game restores its windows from `Lua/layout.ini` per screen size; 1280x800 had no block, so the window kept its default (visible), and the game shows it at start when `visibleOnStartup` is true. Every tester on a screen size they have not used before, and every tester whose last vanilla game left that window open, would have seen it. Fix in `Overrides/CharacterInfo.lua`: the game's `initialise` is wrapped and `visibleOnStartup` cleared while ZeD is on (safe mode keeps the game's rule). Knowledge bank Q271; HOOK_MAP "Character info".

## Not a fault, worth knowing

- The debug build's `UIDebugConsole` (Output Log / Lua Command Line) is in some captures: the game's own, opened by `-debug`, not ZeD's.
- The windows' saved heights are the QA save's (315 px at this scale). A new player gets the defaults (600 design units: 450 px at 800, 450 of 720).

## The main menu at 1280x800: not ready

Walked the same day (`zedqa_r3_menu.lua` through the bridge at the main menu in a 1280x800 window; shots `Oct29_menu_1280x800/`, sheet `sheet_menu.png`, crops `crop_*.png`). The desk and the menu bar draw; the windows inside the monitor do not fit the tube:

- **Options:** the page list runs past the window's bottom edge (Interface, Accessibility, Mods drawn over the desk below the frame; `crop_options.png`); the right pane shows one control ("Base the...") with its words cut.
- **Spawn location / Sandbox:** only the Save Name field is in the window; the spawn list and map are off the right edge (a sliver of the map's paper shows at the frame; `crop_spawn.png`).
- **Occupation and traits:** the occupation names are cut to "...", the positive and negative trait columns are three rows tall, Starting skills is cut (`crop_traits.png`).
- Mods and Looks fit, cramped.

This is a layout job, not a bug fix: these windows are laid out for a tube that is wider and taller than 1280x800 gives at scale 0.75. They need a small-tube layout (fewer columns, lists that scroll, the detail pane under the list) or a smaller root for the menu alone. A design call for the director; proposed as its own piece of work (t12 or later), with the in-game windows already passing at these sizes.

Also seen on that walk, and at 1920x1080 too (317 times): `Lua((MOD:ZeD-GUI)).nameProblem> Exception thrown`, `__concat not defined for operands: Sandbox and \2026-10-29...` from `ZeD_MainMenuSpawn.lua:219`. Not a size matter: on 42.22 `getWorld():getGameMode()` is a Java object, so the join for the "save exists" key failed every frame the Spawn window drew (knowledge bank Q272). Fixed with `tostring` there, in the Spawn window's title and the desk's save title.

## Still to do for handhelds

- The main menu's small-tube layout (above).
- A real Deck: the glyph set, the pad at 16:10, the text at arm's length. Testers asked for in the Discord post (Oct 28).
- 1280x720 with the font-size option at its largest (the user knob multiplies the root): not tried.
