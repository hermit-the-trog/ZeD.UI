# Handoff: the vehicle diagrams redrawn in pixel art (Nov 3 2026), ready to install

Punch list 79, spec section 3 (VEHICLE_TAB_SPEC.md). Director: "The vehicle mockup looks awesome." Design (Cowork).
Staged, not installed: nothing under 42/ has changed.

## What it is
All 13 body shapes (4door, smallcar, sportscar, racecar, stationwagon, suv, offroad, van, truck and the four
trailers), every part layer, redrawn from the game's own overlay shapes as ZeD pixel art: each part a shaded panel lit
from the top left (glass with a glare streak, tires dark, lights bright), the callout icons keeping their detail, the
roof dark with a light outline so the parts read on it. The scanline fill is gone.

The layers stay grey: the tab tints them with the condition colour as it does now (statusColor, the dim base, the
danger pulse for missing parts, the accent and the text-colour rim for the lit part), so the colourblind modes work
unchanged.

## Files (uncommitted)
- `ZeDUI/tools/mechanics/pixel_mech_figs.py`: the generator. `py pixel_mech_figs.py` bakes every body from the game's
  overlay folder to `ZeDUI/art/mech_pixel/`; `--preview DIR` also writes tinted previews.
- `ZeDUI/art/mech_pixel/textures/`: 615 textures, `zm_<body>_<part>.png` and `_rim.png`, the same names as the live
  set in `42/media/textures/ZeD/mech/` (checked: none missing, none extra; zm_gridbox stays as it is).
- `ZeDUI/art/mech_pixel/MechFigs.lua`: the anchors in the same form (314 layers, 13 unions). Units are art pixels
  (1 = 2 overlay pixels, about one design unit); drawFigure only uses them relative to the union, and `K` is read
  nowhere.
- `bake_mech_figs.py` stays as it is (its gridbox function is still the source of zm_gridbox).

## Install
1. Copy `ZeDUI/art/mech_pixel/textures/*` over `42/media/textures/ZeD/mech/` (gridbox untouched).
2. Copy `ZeDUI/art/mech_pixel/MechFigs.lua` over `42/media/lua/client/ZeD/MechFigs.lua`.
3. **Crispness:** the art is 1 art pixel per design unit. In drawFigure, round the fit scale `sc` down to a whole
   multiple of T.px(1) where the box allows (it does in the 205 x 244 column at the whole UI scales), so each art
   pixel lands on whole screen pixels; if the game filters these textures linearly when scaled, the art blurs.
   The other pixel art (plates, desk) is drawn at whole multiples for the same reason.
4. Commit with the staged files.

## QA
- The Vehicle tab on a sedan, a pickup, a van, a sports car and a trailer at 4K and on the Deck: the figure crisp (no
  blur, no uneven pixels), every part tinted by its condition, a missing part's pulse, the lit part's accent and
  outline, hover and click on the figure picking the right part (the hit zones come from the anchors).
- A modded vehicle that brings its own overlay: whatever it showed before (it has no zm_ layers of its own).
