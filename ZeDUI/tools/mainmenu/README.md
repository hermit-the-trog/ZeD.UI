# Main menu desk, v3

The lit night room behind the main menu, approved by the director on Oct 15 2026. On Oct 28 2026 the orange soda can replaced the cola (see Decisions).

The previews:
- `previews/main_menu_4x.png`: the desk at 4x, with the screen's contents pasted in from the S125 capture.
- `previews/lit_and_lamp_dipped_2x.png`: the lit room, and the room on a lamp flicker.
- `previews/lights_on_off_8x.png`: the hard disk light and the floppy light, each on and off.

## The art (staged, not live yet)

The files are in `ZeDUI/art/main_menu/v3/`. Swap them in together with the code changes below. The picture alone, without those changes, gets the wrong needle and light colours.

| File | Size | What it is |
|---|---|---|
| `desk.png` | 480 x 270 | Replaces the live `desk.png`. |
| `desk_lampdim.png` | 480 x 270 | **New.** The same room with the lamp dipped. The lamp now lights the whole left side, so a flicker swaps the whole picture. |
| `lamp_dim.png` | 42 x 36 | The old `LAMP` box, cut from `desk_lampdim.png`. Only needed until step 3 lands. |
| `dial_clean.png` | 7 x 10 | The boombox dial with its needle painted out. |
| `desk_info.json` | | The colours below, measured from the render. |

The contract is unchanged. The tube, both lights, the dial, the needle, the power button and the desk edge row (184) are where they were.

## Wiring it in (next code session)

1. Copy the four PNGs into `42/media/textures/ZeD/mainmenu/`.

2. In `ZeD_MainMenu.lua`, set the colours the code paints:
   ```lua
   local HDD_OFF    = { r = 0x1f / 255, g = 0x14 / 255, b = 0x04 / 255 }
   local FLOPPY_OFF = { r = 0x0e / 255, g = 0x18 / 255, b = 0x11 / 255 }
   local NEEDLE_C   = { r = 0x7f / 255, g = 0x20 / 255, b = 0x12 / 255 }
   ```
   - The off colours are dark lens plastic in the room's light. Lit, the lights are `#f49c21` and `#36c538`, pinned exactly in the picture.
   - `NEEDLE_C` must equal the baked needle, or the needle changes colour when it drifts.

3. **Lamp flicker.**
   - In `MM.drawDesk`, call `lifeTick(t)` before the picture is drawn.
   - On a dim beat, draw `desk_lampdim.png` in place of `desk.png`:
     ```lua
     lifeTick(t)
     local l = life.lamp
     local dipped = l.beats and l.i % 2 == 1
     local desk = tex(TEX .. (dipped and "desk_lampdim.png" or "desk.png"))
     ```
   - The light, dial and needle overlays still draw after it.
   - Delete the `LAMP` box draw at the end, and the `LAMP` constant with it.

4. **Margins.**
   - Margins only show where the tube forces a smaller multiple, such as ultrawide.
   - The picture's edges are dark now and differ by side, because the lamp is on the left. Fill each half of the screen with its own side's colours, then draw the picture over them:
     ```lua
     local WALL_L = { r = 0x11 / 255, g = 0x09 / 255, b = 0x07 / 255 }
     local WALL_R = { r = 0x1e / 255, g = 0x14 / 255, b = 0x0c / 255 }
     local DESK_L = { r = 0x1f / 255, g = 0x0d / 255, b = 0x07 / 255 }
     local DESK_R = { r = 0x0d / 255, g = 0x05 / 255, b = 0x03 / 255 }
     ```
   - These replace `WALL` and `DESKC`. The split row stays `EDGE_ROW`.

5. **Check pass.**
   - Capture the main menu at 1920 x 1080 three ways: normal, on a dim beat (`life.lamp`), and with the hard disk light off.
   - Compare the captures against `previews/`.
   - Put them in `ZeDUI/qa/`.

## Regenerating

You need Python 3 with numpy, scipy and Pillow. Run from this folder:

```
python gen_desk.py --to ../../art/main_menu/v3      # the textures and desk_info.json; prints the Lua colours
python preview.py ../../art/main_menu/v3/desk.png ../../qa/S125_mainmenu/01_main_menu.png previews/main_menu_4x.png
```

The textures the mod loads are graded from these by `../menugrade/grade.py` at strength 1.0 (see its header). Its frames folder only feeds the statistics it prints.

- **`gen_desk.py`:** the room.
  - `PAL` holds the materials.
  - The wall, desk, corkboard and posters are drawn at the top level. The objects are in `build_objects()`.
  - `RIG` holds the lights: the desk lamp, the monitor, moonlight from a window off the right, and ambient light.
- **`desk_engine.py`:** the renderer.
  - Every shape paints a material and its surface: normal, depth, gloss and glow.
  - Light is computed afterwards.
  - The lit and dipped frames are then fitted to one shared 256-colour palette, with ordered dithering.
  - The lit lights and the needle are pinned in the palette, so they keep their exact colours.
- **`palette_v3.json`:** the palette is locked.
  - It is the exact palette the approved room was fitted to.
  - Refitting it shifts colours across the whole picture: about one pixel in five, and the margin colours with them. So `gen_desk.py` quantises to the locked palette.
  - Materials drawn since the lock are listed in `FRESH`. They get their own entries (`FRESH_SLOTS`).
  - Redrawing an object therefore changes only that object's own pixels.
  - `--refit` fits a fresh palette instead and writes it to the output folder as `palette.json`. Adopt it by copying it over `palette_v3.json`, and only when the whole room is being redrawn.

## Decisions

- **The room:** night, lit by the desk lamp, the monitor and moonlight. The walnut paneling stays.
- **The desk:** one solid slab of dark walnut, darker than the paneling. The grain runs the length of the top.
- **Wall poster:** HEVEY DEWIS AND THE REPORTERS. The lower third sits behind the boombox on purpose.
- **Front game box:** THE SIMZ.
- **Corkboard:** the Princess Quest 3 cover stays.
- Both pieces are original parody art. Nothing is copied from a real cover.
- **Maker's mark:** reads KI on the monitor and on the case.
- **Orange soda can** (director, Oct 28 2026; it was a cola):
  - Corn and an orange, ORANGE SODA on the cream label, and the claim 25% HIGHER FRUCTOSE CORN! The claim was the director's.
  - The claim sits on a burnt orange band, the director's pick over navy. Cream type straight on the orange all but vanished under the night grade.
  - The can grew from 34 x 54 to 40 x 78 so the claim reads at 1080p.
  - Everything printed on it is drawn already wrapped: a line of type rides the can's curve, its end letters 1 px higher.
  - The review is in `ZeDUI/mockups/zed_orange_soda_can_v1/`.
- **Drawing:** whole multiples and nearest filtering only, as before.
