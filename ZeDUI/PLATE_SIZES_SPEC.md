# Machine plates: sizes that fit the full card at every scale (Oct 29 2026)

For Design. The director's rule: a card is either the half card or the full card, and nothing may be wider than the full card. Today some machine plates are wider than the full card holds at some scales. To make them fit, the game either widens the drawer, which pushes the windows around, or draws the plate at half size. This spec sets plate sizes that fit at every UI scale.

## How a plate is drawn

- **Plate pixels are drawn at a whole zoom, so pixels stay square:**

  | UI scale | Zoom |
  |---|---|
  | below 1.5 | 1x |
  | 1.5 to 2.49 | 2x |
  | 2.5 to 3.49 | 3x |
  | 3.5 and up | 4x |

- **The full card** is 480 units wide. After the scrollbar and an 8-unit margin on each side, a plate gets **450 units**. A unit is one screen pixel at scale 1, 1.75 pixels at 1.75, and so on.
- **The tightest cases** are where the UI scale sits just under a zoom step: 0.75 (zoom 1) and 1.5 (zoom 2). There a plate gets only 450 x 0.75 = 337 plate pixels across.

## The sizes

| Face | Max width | Height | Where it's used |
|---|---|---|---|
| **Main face** | **336 px** | free; aim for 120-200 | the full card at every scale from 0.75 up: every Auto scale on screens 800 p and taller with the game's normal font size, and every fixed scale from 0.75 to 2.0, at 1080p, 1440p, 4K and Steam Deck |
| **Narrow face** | **200 px** | free; aim for 280-300 (like the ham sets' narrow faces) | the smallest settings: fixed scale 0.5, or Auto on a 720 or 800 screen with the game's 16 px font option, where even 336 doesn't fit. The ham sets already have narrow faces at this width. |

The height has no limit: the card scrolls as one piece. Keep a face short enough that its controls and the readout under it show together where you can.

The tab scrolls as one piece and the face sits on the plate's own background. Keep every live part (dials, lamps, buttons, needles) at least 1 plate pixel from the edge, and click areas at least 10 x 10 plate pixels: at zoom 1 they're 10 screen pixels.

## Fit check, the main face at 336 px

| UI scale | Zoom | Room in the card | Face drawn | Share of the card |
|---|---|---|---|---|
| 0.75 | 1x | 337 px | 336 px | 100% (tight) |
| 1.0 | 1x | 450 px | 336 px | 75% |
| 1.25 | 1x | 562 px | 336 px | 60% |
| 1.5 | 2x | 675 px | 672 px | 100% (tight) |
| 1.75 (the director's) | 2x | 788 px | 672 px | 85% |
| 2.0 | 2x | 900 px | 672 px | 75% |
| 2.5 | 3x | 1125 px | 1008 px | 90% |
| 3.0 | 3x | 1350 px | 1008 px | 75% |
| 4.0 | 4x | 1800 px | 1344 px | 75% |

Anything wider than 336 falls to the next smaller zoom at 0.75 and 1.5, which is half size or a third smaller.

## Plates to redraw

All are 456 px wide today. The main face goes to 336 px or narrower. Rearranging, like the ham sets' narrow faces, works better than shrinking: burners can stack, and the control panel can sit under the hob.

| Group | Plates | Shown in |
|---|---|---|
| Ranges | `oven_green` (Green range, 1956), `oven_red` (Red range, 1962), `oven_grey` (Grey range, 1985), `oven_modern` (Modern range, 1992), `oven_industrial` (Industrial range, 1980), `oven_large` (Large modern oven) | Craft tab at a station |
| Fryer | `fryer` (Fryers Club fryer) | Craft tab |
| Microwaves | `mw_white` (White touchpad microwave, 1990), `mw_chrome` (Chrome microwave, 1979) | Craft tab |
| Generators | `gen_red`, `gen_yellow`, `gen_blue`, `gen_old` | Generator object card |
| Grill | `grill_propane` (Propane grill, 1993) | Grill object card |
| Ham sets | `ham_civilian`, `ham_army`, `ham_makeshift`. Today 400 px wide; they need a 336 px main face. Their narrow faces (`ham_*_n`, 200 px) already meet the narrow spec. | Radio tab |

For the narrow face at 200 px (the smallest settings only): one per plate above. The ham sets already have theirs. If that's too much work for now, the code can fall back to the main face for those rare settings. The face would then be cut off at the card's edge, and nothing else would move.

## Not affected

These aren't shown in a card, so the two card widths don't apply to them:
- the car radios (the dash and the car radio up close)
- the siren controller
- the watches and the speed keys
- the walkie-talkies (200 px, which fits)

## Files

- Design hands back PNGs plus the parts and click areas, as before: `ZeDUI/tools/physpx/export_phys.py` builds `PhysPx.lua` from them.
- Plate pixels are measured in the plate's own pixels: one plate pixel is one screen pixel at zoom 1.
