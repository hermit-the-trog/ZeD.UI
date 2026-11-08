# Handoff to Code: the ignition key, the fob, the dash down to the screen edge, and the steering column (Oct 29 2026)

The director's brief, from the chat:

- "Rework the keys. Current is hard to tell it's a key, more like a wadded blob of materials."
- "Perspective is incorrect on the keys. It's OK to only see the edge, 1 point perspective."
- "Key is good now. The leather fob is tiny. They are usually a little bigger than the key." The references were teardrop leather fobs: a tab folded over the ring, a snap, stitching.
- "Extend the dash down to the edge of the display and use the larger fob."

Everything below is approved. It was drawn through the real pipeline by monkeypatch, so nothing in `tools/dashpx` is changed yet.

**Do this after `HANDOFF_dash_needles_green_20261029.md` has landed.** Both touch the export, `night.py`'s light map and `ZeD_Dashboard.lua`.

**Review material:** `ZeDUI/mockups/dash_fixes_20261029/`

- `keys_before_after_2x.png`, `keys_onepoint_before_after_2x.png`, `keys_fob_before_after_2x.png`: the rounds.
- `keys_teardrop_A_inside_B_hanging_3x.png`: the director picked B, the right-hand column.
- `dash_to_screen_edge_fob_2x.png`: five dashes on the 178 px plate, key at OFF, the B fob. This is the target.
- `key_proof4.py`, `key_proof6.py` and `dashlib_proof_h178.py`: the proof code.
  - `key_v4` is the key.
  - `fob_sprite` is the fob.
  - `dashlib_proof_h178.py` is `dashlib.py` with only the plate height and the shells' bottom changed.
  - Run from `tools/dashpx` with `py -3.14`.

## 1. The dash reaches the screen edge

Today the plate is 800 × 172 and the shells end at row 168. `_layout` also leaves `6 * k` under the dash, so 9 plate rows of game world show beneath it.

- **`dashlib.py`:**
  - `W, H = 800, 178`.
  - Every shell bottom that is written as `168` becomes `H - 1` (177), so the lower dash and the console run to the plate's last row. They are at:
    - `shell_boxy`: the dash, hood and console polygons, the console seam, `meta["console"]`;
    - `shell_curvy`: the outline, `meta["console"]`.
  - Nothing else moves. The lower rows, the controls and the hit areas stay where they are. The dash just has 9 more rows of its own vinyl at the bottom.
- **`ZeD_Dashboard.lua` `_layout`:** `y = top + height - h`, with no `- 6 * k`.
- **Check in game:** that nothing else ZeD or vanilla draws in that strip while driving is now covered (the belt, the action bar, prompts). Report it if something was relying on the gap.
- **The night light map** is one digit per 4 × 4 plate pixels, and 178 doesn't divide by 4. Round the rows up (45) in `night.py` and the export, and make the Lua's lookup agree.
- **The race car's dash** spans 10..789, not 6..793. Confirm its shell reaches the bottom too.

## 2. The key: one-point perspective, only its edge

This replaces `v6.key_turn_variants`. Both ignitions use it: `v6.ignition` on the boxy dashes and the curvy row's own ignition.

**The eye.** It sits at `VP = (250, 60)`, over the column and level with the cluster.

**The head.** The key points straight at the driver, so you see only its edge:

- A bar along the slot: `HALF_L = 8.5`, `HALF_T = 1.2`, so 17 × about 3 px.
- It turns with the slot: OFF 0° (vertical), ON 40°, START 80°.
- The head's near edge slides `DEPTH_PX = 2.5` away from the eye. The head is swept from the lock face to that edge, with height rising toward the driver, so the face toward the eye shows as a sliver (`dark` 0.25 on it). The near edge is the brightest line (`tex` +0.35 on nickel, +0.45 on black).
- At START it clears the START label, and the curved dashes' ST by about a pixel. **Don't lengthen it** without moving the labels out.

**Material, by era:**

- Bare nickel (`alu`, polish 1.0) on the wood-and-chrome cars: `wagon`, `luxury`, `horizon`. The lock face stays black behind it.
- Glossy black (`blackp`, polish 0.85) on every other car. Their lock face, the `blackp` disc inside r 6.5 that is the cylinder, becomes `alu` (polish 0.8) so the black head has something to stand against. That's a plate change in `v6.ignition`, not a sprite.

**The ring:**

- 10 px across (`RING_R0` 3.6, `RING_R1` 4.6), `chrome`, height `Z_FACE + 9.5`.
- It hangs from the hole in the middle of the near edge, straight down in every position. Its centre is at the hang point + (0, `RING_R0` + 0.4).
- The near edge covers its top.

**The fob: a teardrop, face on, inside the key's three sprites (see `fob_sprite`):**

- 15 px wide.
- The body is 20 px long, below a tab 6 px wide and 6 px tall (0.4 of the width).
- The tab folds over the ring's wire. Its top sits 1.5 px above the ring's bottom, with a darker fold row and a chrome snap (r 1.3) 3 px above the tab's foot.
- The body flares from the tab to the full width (`half = tab/2 + (r - tab/2) * t ** 0.4`), then a round bottom.
- Dotted stitching (`tex` +0.5) runs in a band 1.6–2.6 px inside the edge, below the tab.
- Leather: `v_tan`, or `v_cocoa` on the light cabins (`v_tan`, `v_beige`, `v_khaki`), so it doesn't disappear into the vinyl.
- In the proof the fob is a separate canvas pasted with a faked shadow. **Draw it in the key variants instead**, on the plate canvas, so the engine casts its real shadow. On the 178 px plate it fits.
- **The Cossette:** its ignition sits 2 px lower, so the fob would end 2 px past the plate. Make its body 18 there.

**Gone:** the old aluminium octagon head, the small ring and the red or yellow tag.

## 3. The steering column, suggested

The director, on adding a column: "Suggest being keyword." Then, on the shape: "More of a half squircle." And: "They are kinda chunky irl." He picked **100 × 46 px on every dash**: "100. Excellent."

**Review:** `mockups/dash_fixes_20261029/column_chunky_84_vs_100_2x.png`. The right-hand column of that image is the pick.

**Proof:** `column_proof3.py`. Its `shroud(b, a, bh)` was run with `a = 50`, `bh = 46`.

**The shape.** Only the top of the shroud shows, coming up at the driver from below the frame and cut by the screen's edge.

- A half squircle standing on the plate's last row: `|x/50|^3.5 + |y/46|^3.5 <= 1`.
- `y` is measured up from row `H - 0.5`, and the shape is centred on `v6.COLUMN_X` (250).
- No wheel, no stalks, no centre line. The director wants it suggested, not drawn out.

**How it's drawn:**

- It is plate art in every shell, not a sprite. Draw it after the lower row so it sits in front of the vinyl.
- Material: the design's own cabin vinyl (`b.cabin`), `polish` 0.3, `dark` 0.12. It reads as moulded plastic a shade under the dash.
- Its height crowns toward the middle (`Z_FACE + 3 + 13 * (1 - r) ** (1/3.5)`), so the engine shades it round and lets it cast its shadow.
- Where it turns away (`r > 0.80`) it is `dark` 0.32.

**The lower row makes room.** `v6.LEFT_SPAN = (14, COLUMN_X - 52)` and `RIGHT_SPAN = (COLUMN_X + 52, 486)`: 104 px kept clear instead of 56. The controls on both sides re-spread with equal gaps, as `spread` already does. This covers both the boxy and the curvy lower rows.

**Check:**

- Nothing in the lower row overlaps the shroud, and no hit area reaches into it.
- The key and fob stay clear.
- On the race car's own panel, which doesn't use the spans, the shroud sits clear of its switches. Report it if it doesn't fit there.

## 4. Checks

1. `build.py`, `export_lua.py <mod root>`, then `luatest.py`, `luatest.py hints` and `luatest.py badges`: all clean, with no new flat-surface or travel warnings.
   - The fob's swing is fixed (it always hangs down), but **nothing printed may sit under the ring or the fob** in any key position. Add the three key sprites to the lever-travel check.
2. The needle audit, rerun on the taller plate: still 0 px off the face.
3. `nightsheet.py`:
   - the key and fob take the light map like the other sprites;
   - the 9 new rows go dark with the rest of the lower dash.
4. In game at real play scale (fullscreen, ZeD UI scale 1.75x at 4K), with the window layout reset (R) first:
   - the dash sits flush on the screen's bottom edge;
   - the column's shroud meets the screen edge with no gap, in each cabin's colour;
   - the key reads OFF, then START while the starter turns, then ON;
   - the fob hangs whole on every car. Check the Cossette in particular.
