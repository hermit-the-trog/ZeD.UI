# Pixel icons outside the wheels: QA (Oct 27 2026)

ZeD's own pixel icons replaced the licensed pictures in the container row, the item card's marks (option A: the
icon in place of the square, the words kept) and the windows' small controls; the chevrons are drawn by code.

Runs (manifest `ZeDUI/tools/qa/px_icons_manifest.txt`, both 9/9 pass, no ZeD errors in the console):
- `4k/`: fullscreen 3840x2160 at 1.75x (`ZeDUI/qa/regression/2026-10-27_1933_fullscreen4k.md`); the icon box is
  28 px, the 24 drawing shows, two colours inside a box (no smoothing).
- `1x/`: a 1920x1080 window at Auto = 1x (`ZeDUI/qa/regression/2026-10-27_1939_windowed.md`); the box is 16 px, the
  16 drawing shows.

Captures: `zqa_px_panel` (every icon at rest, pointed, lit, off, warning; the card's mark strip wide and narrow,
off and on; the chevrons at 5-16 units), `zqa_px_card` (the item card with Fav and Dispose on), `zqa_px_rows`,
`zqa_ct_*` (the rows, the campfire's buttons), `zqa_grid_2` (List | Grid), `zqa_doll_1` (List | Doll), `zqa_ms_*`
(the Maps tab's fold button), `zqa_pr_*` (the prompt's marks), `zqa_wi_dpad_down` (a wheel, through the shared lookup).
Not seen live: the seat chooser's doors (no car entered), the appliance pop-out, the Radio tab's full view, the
description editor, the Mods screen's star (main menu); each takes the same lookup.
