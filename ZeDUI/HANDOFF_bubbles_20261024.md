# Handoff to Code: overhead speech and thought bubbles (Oct 24 2026)

Approved by the director on Oct 24: "Bubbles are good. Themed yes."

The mockup is `ZeDUI/mockups/zed_bubbles_v1/zed_bubbles_v4_final.png`. `bubbles.py` in the same folder draws both bubbles in design units, exactly as the game should. It is the reference for every pixel below.

## What changes

1. **Speech.** Text the character says over their head is drawn in a balloon in the style of the gallery's System 7 balloons. It replaces the engine's plain overhead line.
2. **Thought.** The action bar's VERBOSE mode (`ZeD_ActionBar.lua`, `AB.drawVerbose`) is drawn inside a rounded thought bubble. A trail of three small bubbles runs down to the head.
   - SIMPLE mode stays as it is.
   - The layout inside the bubble stays exactly as today: L1/R1 in the 5×7 face, L2/R2 in the 3×5 face, the 2-unit bar with its queue notches, done green, stopped grey, and the fades.

Both are drawn with `ZeD.Px` on whole multiples. Use the same `k` as the action bar: `AB.k()`, which is the root scale times vanilla's progress-bar size option. At 4K that is k = 2.

## Colours: the theme (read ZeD.T fresh every frame)

| Part | Token |
|---|---|
| fill | `T.surf1` |
| ink (the outline and tail) | `T.borderS` |
| speech text | `T.text` |
| thought L1 | `T.accent`; `T.positive` when done; the dim colour (`AB._dim`) when stopped or walking |
| thought R1 | `T.text` |
| thought L2 / R2 | `AB._legend` (T.text at 70%) |
| bar track | `T.surf3` |
| bar fill | as L1 |
| shadow | black at 35–45% alpha (no token; sync it like `AB._dim`) |

## Geometry (design units)

### Speech balloon
- **Body.** A box with stepped round corners: the rows are trimmed 2, 1 at each end (`round_box`). There is a 1-unit ink line round it.
- **Padding and text.** Padding is 5. The text is the 5×7 face in CAPITALS, lines 9 apart, each line centred. Wrap at 120 units.
- **Shadow.** The same box, offset +2, +2, filled with the shadow colour, drawn first.
- **Tail.**
  - Its base is 10 wide on the body's bottom line, a third of the way along from the side nearer the head.
  - Its point is on the head top: `AB.headScreen`, the same anchor the action bar uses.
  - The body sits 3 units above the head plus a 9-unit tail.
  - Draw the tail as a filled polygon outlined in ink, after the body, so it opens into it.
  - It casts the same shadow.
- **Width.** Text width + 10. Height: lines × 9 − 2 + 10.

### Thought bubble
- **Body.**
  - Corner radius 10.5: nearly half-round ends, no lobes.
  - 1-unit ink line, shadow +2, +2.
  - Inner padding 7; the content is 24 units tall; the body is 30 tall.
  - Width: the verbose content width (minimum 60) + 14.
- **Trail.** Hand-set bubbles; `#` is ink, `o` is fill:
  - The largest sits 2 units under the body, 3 right of its centre:
    `.###. / #ooo# / #ooo# / #ooo# / .###.`
  - The middle one is 6 below that, 1 right of centre:
    `.##. / #oo# / #oo# / .##.`
  - The smallest is 11 below, 1 left of centre: `## / ##`.
  - Each has the same shadow, offset +1, +1.
- **Placement.** The body sits 3 above the head plus a 15-unit trail, centred on the head and offset 6 right.

### Both at once
When the character speaks while a thought bubble is up:
- The speech balloon goes to the right of the thought bubble, 2 units clear. Its bottom sits 4 above the thought's bottom.
- Its tail runs from the balloon's lower-left corner to the right side of the head (head + 8, + 5), with a base 18 wide.

## Fonts
`PixelFonts.lua` lacks punctuation the speech needs. Add these to both faces; the glyphs are in `bubbles.py`, top of file:
- 5×7: `! ? , "`
- 3×5: `! ? , & |`

## The speech hook (to investigate)
The engine draws speech (`IsoGameCharacter` says through its chat element, Java side).

1. Find where Lua can learn what was said and stop the engine drawing it. Check for:
   - a Say event in B42;
   - wrapping `IsoPlayer.Say` where Lua calls it;
   - the chat-element API (`getChatElement`, `setTalkTime`, and similar).
2. If only Lua-side calls can be caught, wrap those, and leave Java-side lines to the engine. Tell me which lines stay plain.

## Scope
- **Local players only.** Other players' text in multiplayer stays the engine's, the same rule as the action bar.
- **Pickup notes.** Halo notes, such as the item card's pickup notes, are not part of this. The director has not asked for them.

## Testing
- Check at 4K (k = 2) and 1080p (k = 1). At 1080p, check that the 3×5 text in the thought bubble stays readable.
- Check every theme. A light theme's `T.surf1` is pale; check the ink line still holds.
- Check that a long line wraps.
- Check the speech-while-acting layout. Make sure the bubble doesn't run off-screen at the screen's right edge: flip the balloon to the left of the thought if it would.
