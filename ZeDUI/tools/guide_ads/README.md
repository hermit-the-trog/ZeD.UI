# Survival guide ads (ZeD-GUI, design, Nov 6 2026)

The plan is `docs/plans/GUIDE_ADS_PLAN.md`.

1. `python adpx.py [name ...]` draws the pictures in ZeD's pixel art (the dashes' engine, `../dashpx/engine.py`: a
   height field, a material per pixel, lit from above, real shadows, each material on its own ramp, no blending, no
   dithering), printed in the book's one ink: every ramp runs from the paper to the ink. One art pixel = one design
   pixel. Out: `px/<name>.png`.
2. `node render.js [name ...]` sets each ad (`src/<size>_<name>.html`, shared `ad.css` / `ad.js`) at 2x with
   Playwright: `out/preview/` on the book's paper for review, `out/final/` ink on transparent for the game.
   Without Node: `python render_edge.py [--out DIR] [name ...]` does the same in headless Edge (stdlib DevTools, fresh
   temp profile, closes only its own Edge); text edges differ slightly from the Linux renders, layout and art do not.

Sizes in design px (screen px at 1080p): full 440x628, half 440x310, third 440x205, quarter 215x310.
Fonts in `fonts/`: Old Standard TT, Open Sans, Caveat (the game's own print faces, OFL), Oswald, Alfa Slab One, Rye
(OFL), Yellowtail (Apache 2.0). Copy rules: 1987, evergreen, 502 / 555 numbers, English only, no flyer text.
