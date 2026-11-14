# Main menu desk, v8 (Nov 13 2026, design; punch list 182)

From v7's two pictures. The director's rulings, Nov 13:

- **The lamp is gone, nothing in its place** ("Just get rid of the lamp. I don't want a lamp there. It blocks a poster.").
  The Project Zomboid poster has a new picture of its own, the director's: "Just do a house. A silhouette of a
  stumbling zombie walking in profile towards the house. One or two trees, a moon ... Just use navies." A navy night,
  everything a silhouette, one lit window. It is an original picture, not the game's box art (which is The Indie
  Stone's and was not used). The poster's left edge and the bricks under it are repainted where the lamp's post stood.
- **The warm light stays** ("Keep the warm light. It's just a light from just off screen."): still two pictures,
  `desk.png` (the light on) and `desk_lampdim.png` (dimmer), the difference between them v7's with the lamp's own shape
  taken out. The file name `desk_lampdim` is kept so nothing in the code has to change.
- **The black radio stands where the boombox was**, its handle off the Hevey Dewis poster. The wall under the poster is
  board, as beside it.
- **The Lua Console 93 box** stands right of The Sim2 where the two blank books were, taller and thicker than its
  neighbours: the box's magenta spine, LUA CONSOLE 93 and PRO EDITION reading down.
- **The soda can's top has a rim** ("has no depth or lip to it"): the raised rim bright, a dark line inside it, the lid
  a shade lower. And it tapers in to that lid ("The lid is smaller than the diameter of the middle of the
  can"): a smaller lid, a taller bare-metal neck sloping out to the can's side ("Make the taper start from lower down"), the label starting under it. The lid is redrawn clean, its pull tab at ten o'clock, drawn at 45 degrees, and a larger opening.
- **The can's label** is orange from the (printed, orange) neck down to the dark band: no white strip, no SODA, the
  orange-and-corn picture lower, ORANGE in white where SODA was (the director, Nov 13).
- The pale lines along the foot of the boxes are gone ("leftover lines from other stuff").

## For Build

1. **The meter needle has nowhere to be.** The boombox's meter is gone; `NEEDLE_C` and whatever draws the needle over
   the desk should be removed (the black radio has no meter). Everything else in `desk_info.json` is v7's and unchanged:
   the HDD and floppy lamps, the wall and desk edge colours, the note's ink.
2. Nothing between x = 110 and x = 372 was touched (the monitor, the computer), so the screen rect and the lamps are
   where they were.
3. Goes into `42/media/textures/ZeD/mainmenu/` with item 174, once QA is clear. Not in `42/` now.

`build_v8.py <v7 folder> radio_black_257_src.png <out folder>` makes both pictures (Python, numpy, scipy, Pillow).
