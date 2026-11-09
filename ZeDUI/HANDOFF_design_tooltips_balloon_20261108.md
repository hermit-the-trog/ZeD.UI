# Handoff: tooltips as Balloon Help, and the strip's arrows in the accent (Nov 8 2026)

From design, for Build and then QA. Beta 10. Punch list items 118 and 119. The director approved the mockup on Nov 8
("That's the one") after three calls: text-safe status colors, the tooltip picture in, a 10-cell tail.

- **Mockup and spec:** `ZeDUI/mockups/zed_tooltips_balloon_v1.html` (open it in a browser; section 7 is the spec, and
  the drawing code in its script mirrors the Lua atoms named below). Published copy:
  https://claude.ai/artifact/QHC99z2w8JtSKAhnrgPBxM
- **Inputs:** the Mac's survey `ZeDUI/qa/ZeD-UI_tooltips_beta9t2.webp`, the Visual Catalog v2.0 (A07 Tooltip), the
  Nov 8 tooltip research, today's code.

## What changes

One balloon replaces every pop-up that explains a control:

| Today | Where | Becomes |
|---|---|---|
| The strip's white info bubble, F1 label, centered, never wrapped (spills past 250u) | `Molecules.drawContextBalloon` | the balloon, above the strip, tail to the cell |
| The list menu's balloon, fixed 280u, no tail, `<LINE>` turned into spaces | `ZeD_ContextList:_drawBalloon` | the balloon, beside the row, tail to the row |
| The hint, at the pointer (below right) | `Atoms.drawHintBox`, `requestHint` | the balloon, anchored to the control |
| The detail card, at the pointer | `Molecules.drawDetailCard`, `requestDetailCard` | the balloon with a title |
| ZeD_Tooltip | `Atoms.lua` 07 | the same balloon |
| The requirement tooltip printed twice, colorless | `drawContextBalloon` body + state rows | the requirement balloon (below) |
| The strip's end boxes, near-black on every theme | `AtomExtensions.drawTruncChevron` | accent boxes (item 119) |

Not changed: the strip's cells and bumpers (locked paper and ink), the target card, the game's item box over the belt
(`ISToolTipInv` stays the game's: replacing its renderer is what makes tooltip mods fight).

## The balloon

1. Box: `T.surf2` at alpha 1, frame `T.borderS` at `T.borderW` hairlines (2 in High contrast), `drawHardShadow`,
   square corners. Padding 8u sides, 5u top and bottom. Line step: face height + 2u. 3u after the title.
2. Faces: a one-line hint in F2 `T.text`. Anything with a title: title in F4 `T.textHead`, a submenu path before it in
   F4 `T.textSec` with " > " between, lines in F2 `T.text`, numbers F3. No F1 in balloons.
3. Width: the longest unwrapped line + padding, capped at 200u (one-line hint) or 320u (with a title), both x1.15 at
   Large text. Everything wraps at word breaks, the title too. A word longer than the width widens the box to 1.5x the
   cap, then breaks. Height follows the lines. Never clipped, never spilling. Measure with `ZeD.TM` in the live faces,
   scale and text size; remeasure on `ZeD.Text.measureEpoch`.
4. A disabled control's balloon is drawn at full contrast.

## The tail

`drawRect` on the hairline grid (one cell = `T.hair`), outer triangle in `T.borderS`, inner in `T.surf2` inset by the
frame's width, the frame under the tail's base filled with `T.surf2` so it opens into the box. **10 cells deep.**
Straight edge 6u in from the box's corner; the tip stops one hairline short of the control.

```
under the box, lower left corner (# border, . fill; the box's bottom frame is opened over the first row's dots)
#........#
#.......#
#......#
#.....#
#....#
#...#
#..#
#.#
##
#      <- tip
```

Mirror for the lower right corner, flip for a balloon under the control, turn a quarter for a balloon beside a control
(tail on the box's left or right edge, straight edge along the top, 6u down). The tail is placed from its tip, so when
the box has to slide to stay on screen the tip stays on the control.

## Placement

1. Anchor to the control's rectangle, never the pointer. The strip and rows of controls (belt, footers): above, tail at
   the lower left, tip 12u into the control (its middle when narrower). Columns (tab strips, moodles) and the list menu:
   beside, tail on the near edge, tip at the control's middle height.
2. Keep 4u inside the screen: past the right edge, lower right corner; no room above, go under (the strip: under the
   target card); no room on the right beside, go left. Still too big: slide inside the screen.
3. Never cover the strip, the target card, the hovered row or the control.

## Behavior

1. Mouse: after `ZeD.HINT_DELAY_MS` (450 ms) at rest; moving to a neighbor while one is up shows the neighbor's at once.
   Pad and keys: at once on focus, the same balloon.
2. No timer. It stays while the pointer is on the control or on the balloon (WCAG 1.4.13). Escape or B hides it until
   the pointer or focus moves on; in the context menu B still closes the menu.
3. One at a time. No fades.

## The requirement balloon

1. Parse the option's `toolTip.description` (ISToolTip rich text; `ISDisassembleMenu` builds it from
   `getInfoPanelDescription`): `<LINE>` ends a line, `<SETX:n>` splits label from value, `<RGB:r,g,b>` colors what
   follows; drop other tags. A line with an empty label adds its value to the row above (alternative tools). A line with
   no `<SETX>` is a condition row. No `<SETX>` anywhere: plain lines, same marks rule.
2. State: the game's good highlight color (`getCore():getGoodHighlitedColor()`) = met, bad highlight color = missing,
   else neutral.
3. Layout: the picture first when the tooltip has one (`toolTip.texture`, the furniture's sprite): 32u square on
   `T.surf3` in a 1u `T.borderS` frame, at its aspect, then 8u. Labels in F2 `T.text` at the widest label's width; 8u;
   a 7-cell mark (check or cross) and 4u; values in F2, wrapping in their column. A condition row gets its mark and
   spans the label and value columns, its "- " dropped. The rows block is at least as tall as the picture.
4. Print once (no state rows under it), keep the game's row order, leave out a Name row that repeats the title.

```
check      cross
......#    #.....#
.....##    ##...##
#...##.    .##.##.
##.##..    ..###..
.###...    .##.##.
..#....    ##...##
.......    #.....#
```

## New tokens: text-safe status colors (the director, Nov 8)

Marks and values use `T.positiveText` and `T.dangerText` (Tokens.lua, each base theme), at least 4.5:1 on surface 2:

| Theme | positiveText | dangerText |
|---|---|---|
| Dark | #7A9A34 (= positive, 5.3:1) | **#DE7045** (5.3:1; danger #C45A2A is 3.9:1) |
| Light | **#204A0C** (5.1:1; positive #2A5511 is 4.3:1) | #7A2A11 (= danger, 4.8:1) |
| High contrast | #44DD44 (= positive) | #FF5533 (= danger) |

Move the crafting card's met and unmet lines (`CraftingCore.lua` ~2614) to the same tokens. Update the ZeD-UI Design
System artifact with the two tokens.

## Item 119

`drawTruncChevron`: fill `T.accent`, a 1u frame in the strip's ink, the 5px triangle in `T.textOnAccent`, the hard
shadow as now; pressed shifts the content 1u into the shadow, as the bumper does. Every accent clears 3:1 in every theme
(lowest: Purple in Dark, 3.8:1).

## Open (Build checks)

- The moodle hover is the game's own. Draw it as a balloon (title = moodle name, line = description) only if ZeD can
  take it over cleanly; otherwise leave it.

## QA

1. Every theme and accent, Small and Large text, 4K at 1.75x and 1280x800, EN, DE and RU (long strings).
2. No text outside a box; tails on target; the strip, target card and hovered row never covered.
3. Disassemble with a missing saw and full drawers: picture, checks and crosses, the condition row, printed once.
4. Pad focus shows the same balloon at once; Escape / B dismisses; the pointer can move onto a balloon.
5. A disabled button's balloon at full contrast. The strip's arrows readable on all nine accents.
6. Tooltip mods (Tooltiplib, Better Item Info): the game's item box still shows their lines.
