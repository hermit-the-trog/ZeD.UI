# For Design: plates that fill their card at every scale (director, Oct 30 2026)

Answer to Design's question "which do you want?" (1: fix one scale, 2: a face per zoom step, 3: something else).
**The director's answer: neither 1 nor 2.** Each plate fills its card at every scale, the way text and buttons do
("scale scales everything"). This adds to `ZeDUI/PLATE_SIZES_SPEC.md`; everything in it not named here stands.

## What stays

- The whole-zoom rule: plate pixels are never resized, only drawn at 1x, 2x, 3x or 4x (zoom = the UI scale rounded).
- Today's level of detail. This is not new art per zoom step.
- **The 200 px narrow faces stay** (director, Oct 30). They are no longer for scale 0.5 (dropped), but for Auto on a
  720 or 800 high screen with the game's smallest (16 px) font option: the scale there is about 0.64 and even 336
  does not fit.
- The click areas, live parts and edge rules of the spec, on every width.

## What's new: four widths per plate

The same plate re-laid at four widths. The game draws the widest one that fits the card at the current zoom.

| Width | Fills the full card at UI scale | Fill |
|---|---|---|
| 336 px (today's main face) | 0.75 (1x) and 1.5 (2x) | 100% |
| **392 px** | **1.75 (2x), the director's** | 100% |
| 450 px | 1.0 (1x), 2.0 (2x), and 3.0 and 4.0 | 100% |
| 562 px | 1.25 (1x) | 100% |

- The full card gives a plate 450 units (480, less the scrollbar and an 8 unit margin each side). A width is the
  most plate pixels that fit: 450 x scale / zoom, rounded down. 1.75 works out to 393.75; 392 leaves a pixel for the
  game's rounding.
- Between the listed scales (Auto picks any value from the screen height) the widest face that fits is drawn,
  filling 85 to 100%. Example: a 1440 high screen is 1.33, zoom 1, room 600: the 562 face, 94%.
- Each width is a layout, not a stretch: more room can mean bigger controls and more space between them, so that
  every part stays about the same size against the card at every scale.

Plates: the 17 machine plates (six ranges, fryer, two microwaves, four generators, grill, three ham sets).

## The walkie-talkies: the same in the half card

A walkie's radio tab is the half card (220 units; director, Oct 25: "a panel the size of the info card"). Today the
walkie's 220 px panel, at a whole zoom plus a scrollbar, is wider than the half card at every scale, so the game
rounds the tab up to the full card (punch list item 2). Panel widths (face and its margins) that fill the half card
(206 units after the scrollbar):

| Panel width | Fills the half card at UI scale |
|---|---|
| 154 px | 0.75 and 1.5 |
| 180 px | 1.75 |
| 206 px | 1.0 and 2.0 |
| 257 px | 1.25 |

The ham sets stay in the full card (the table above).

## Hand back

As before: PNGs plus the parts and click areas, through `tools/physpx`, with each plate's widths named so the
export can list them (for example `oven_green@392`). Code adds the pick, and the QA session's check that the right
width loads and fills its card, crisp, at every scale.
