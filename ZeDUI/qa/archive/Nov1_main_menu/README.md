# Main menu checks, Nov 1 2026 (QA; HANDOFF_main_menu_book_20261101.md)

Taken through `tools/qa/zedqa_menu_about_run.ps1` (a windowed main menu with no save, the look scripts around it).

- `mm_about_1280x720.png`, `mm_about_1280x800.png`: the ZeD menu pulled down with the rewritten About paragraph
  (t15). **Both pass:** the menu ends inside the monitor's glass with room under it (at 720 the drop ends about a
  quarter of the glass above its bottom edge; at 800 about the same). No hotfix.
- `mm_desk_v4_1920x1080.png` (lit), `mm_desk_v4_1920x1080_dim.png` (a lamp dim beat forced): the v4 desk as the mod
  draws it. **Matches `tools/mainmenu/previews/main_menu_v4_4x.png`:** the book spine out on the monitor's right
  with THE SIMZ turned beside it; everything left of the monitor as v3; the dial and needle untouched; on the dim
  beat the lamp's side of the desk drops as before.

## The lean-in pass (punch list 48, the evening of Nov 1 2026)

`tools/qa/zedqa_menu_lean.lua` through `zedqa_menu_about_run.ps1`, at 1280x800 and 1280x720, Normal then Large text
(`zedqa_menu_textlarge.lua` / `_textback.lua`). Game consoles: `qa/regression/2026-11-01_menu_lean_*.game_console.txt`.
**All four runs pass: 47 / 47 at Normal, 48 / 48 at Large, each size.** Root scale 1.0 at the menu with the game's
0.75 beside it. Normal text: the main view stays in the room (desk 3x, the window ending left of the icon block);
every page leans in (desk 4x, the monitor 960x720 whole on screen, 10 desk px of the right bezel) and Back leans out,
one dip each way; the mid-dip frame on the switch to Options is black (darkness 0.92 at 800, 0.84 at 720). Large
text: the main view leans in too and nothing dips. New game stepped Spawn, Sandbox, Traits, Looks and back out.
`lean/` holds the main, Options, Spawn, dip and back pictures of each run; all 50 are in
`Screenshots/menu_lean_nov1/`. `mm_desk_v4_1920x1080_after_lean.png` is the 1080p desk after the change: see the
compare line in PUNCH_LIST.md item 48.
