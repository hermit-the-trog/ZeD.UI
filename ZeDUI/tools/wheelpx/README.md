# wheelpx: the wheels' icons

One-colour pixel icons for the radial wheels (ZeD's D-pad wheels and the vanilla radials ZeD_Wheel draws), and later
the context strip. Director, Oct 27 2026: "Ink + pictogram figures", every icon drawn twice (16 at rest, 24 when
pointed), the figures on a template ("follow a template or doll"). Signed off Oct 27 after one round of notes
("Nailed it").

## Files
- `kit.py`: the canvas (vector shapes rendered 8x and cut at half cover, pixel-true discs, rings, capsules, bands,
  hand-placed grids), the badges (+ - x tick, the four arrows, the slash) and the registry (`@icon`). Its docstring
  holds the style rules.
- `i_char.py`, `i_world.py`, `i_vehicle.py`, `i_gun.py`, `i_animal.py`, `i_fig.py`, `i_sym.py`, `i_tabs.py`: the
  icons, a module per wheel or kind. `allicons.py` loads them all.
- `doll.py`, `fig16.py`, `fig24.py`: the figures' template (head, gap, trunk, legs on fixed rows) and the figures
  placed on it; `i_fig.py` registers them.
- `map.py`: which icon goes where (vanilla's words, vanilla's pictures, ZeD's own slices, the tabs). This decides;
  the `slices` noted on each `@icon` were first guesses while drawing.
- `export.py`: writes `out/export/wheel/{16,24,32,48}/zw_<id>.png` (32 and 48 are the 16 and 24 doubled, pixel for
  pixel) and `out/export/wheel_icons_map.json`. The `zw_` prefix keeps the names off the game's packed pictures (a
  plain `map.png` loads the game's own "map").
- `review.py`: review sheets (an icon's cells at 4-5x and 1x, wheels as rings, the whole set at true size).
- `_repl.py`: swaps one `@icon` block in a module (for redrawing an icon in place).

## Run
```
python export.py            # the textures and the map
python -c "import allicons, review as R; R.true_size(list(R.ICONS), 'true.png')"
```
Pillow is the only need.

## Rules (from kit.py)
- one colour, white on clear; the game tints it (ink on the paper cell, the theme's text-on-accent when pointed)
- 16: objects in the 14 x 14 live area, 1 px details; 24: objects in 22 x 22, 2 px lines
- masses solid, details cut out of them; outlines only where a mass would hide the meaning
- badges bottom right (top right on a figure, whose feet fill the bottom), one clear pixel round them
- turning a thing off strikes it through; stopping something a figure does takes the x; in and out are arrows; add
  and remove are plus and minus
- review every icon at true size and zoomed
