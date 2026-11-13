# Handoff: dashboard interior colors (Nov 12 2026)

From design, for Build. The director, Nov 12: "We just need to make a couple more color varieties ... We're not
changing any looks. We're just changing colors." Then: "a different color exterior, you might get a chance of getting a
different color interior." Colors, decade lists and pairing odds are all approved ("The pairings are fine, and the
decade list is fine.").

Only the cabin color changes (the `cabin` vinyl a design is built with). Wood, metal faces, gauges, layouts, parts and
click areas are untouched. The race car is not in this round.

## The colors

| Group | Dashboards | Interiors (name: ramp, base color) |
|---|---|---|
| Station wagon | wagon | brown: `v_walnut` (today's); slate blue: `v_navy70` #2a3442; army green: `v_army` #4d5030 |
| 70s | nyala, d6, bulldriver, rancher | moss green: `v_moss` #38472e; light brown: `v_ltbrown` #8a6a44; slate blue: `v_navy70` #2a3442 |
| 80s | horizon, dart, van | maroon: `v_maroon` #532131; navy: `v_navy` (the engine's own); beige: `v_beige_d` #7c6e56 |
| 90s late models | dashelite, primani, suv | beige: `v_beige_d` #7c6e56; gray: `v_grey` #5d6064; black: `v_black` (the engine's own) |
| Sports and luxury | cossette, luxury | brown leather: `l_brown` #7c4f2c; red leather: `l_red` #7a2420; black leather: `l_black` #242326 |
| Public service | police, taxi, ambulance, fire, ranger | black only: `v_black` |

Director's notes on three of them: beige "needs to be darkened" (so `v_beige_d` replaces `v_beige` wherever beige is
offered, the Primani included); the 70s blue is "really dark slate", "still blue"; the 80s maroon is a mauve, plum and
maroon blend, not brick red ("That's the color I remember").

Public service loses its own colors on purpose ("a standard black dashboard. We probably have too much variety in
those"): the fire truck's red, the ranger's green, the ambulance's gray and the police navy all become `v_black`.

## What changes for existing cars

- Fleet: five dashboards change color (above).
- Cossette: today's `v_red` is gone; brown leather is its lead color ("a supple brown leather interior").
- Lang 4000: today's `v_saddle` becomes `l_brown`.
- Primani: its beige is the darker one.
- Nyala (slate), d6 (cocoa), bulldriver (tan), rancher (khaki), horizon (burgundy), van (fleet gray), dashelite and suv
  (charcoal): today's single color is replaced by the group's three.

## Paint to interior: the odds

Bucket the car's paint by hue; roll once per car and keep the result with the car (the same car must show the same
dashboard every time). **Not verified by design:** that the mod can read a car's paint color. If it cannot, use the
"white, silver, gray, black" row of each table for every car.

**Station wagon**

| Paint | Odds |
|---|---|
| Brown, tan, yellow, orange, red | brown 80, army green 20 |
| Green | army green 75, brown 25 |
| Blue | slate blue 80, brown 20 |
| White, silver, gray, black | brown 40, slate blue 30, army green 30 |

**70s**

| Paint | Odds |
|---|---|
| Green | moss green 75, light brown 25 |
| Blue | slate blue 80, light brown 20 |
| Brown, tan, yellow, orange, red | light brown 85, moss green 15 |
| White, silver, gray, black | light brown 40, slate blue 30, moss green 30 |

**80s**

| Paint | Odds |
|---|---|
| Red, maroon | maroon 75, beige 25 |
| Blue | navy 80, beige 20 |
| Brown, tan, yellow, green | beige 85, maroon 15 |
| White, silver, gray, black | maroon 40, navy 35, beige 25 |

**90s late models**

| Paint | Odds |
|---|---|
| Brown, tan, green, white | beige 60, gray 40 |
| Blue, silver, gray | gray 70, black 30 |
| Red, black | black 50, gray 35, beige 15 |

**Sports and luxury**

| Paint | Odds |
|---|---|
| Red | black 60, brown 40 |
| Black, white, silver | red 45, black 35, brown 20 |
| Brown, tan, green, blue | brown 70, black 30 |

Public service: always black.

## Files

- `colors.py` (for `ZeDUI/tools/dashpx/`): the ramps, the `COLORS` table (design id -> its interiors) and `plate(did,
  cabin)`. `python colors.py <outdir> [design ...]` writes `<design>__<ramp>.png`, the plate only.
- `dash_colors_sheet_1_wagon_70s_80s.png`, `dash_colors_sheet_2_90s_leather_fleet.png`: every dashboard in every color
  (plates, unlit parts).

## What Build has to do (design did not)

1. `colors.py` renders the plate only, for review. A shipped color needs the whole of `build_one` run with that cabin:
   the state sprites are cut from the plate and several carry the cabin color (the ash tray, for one), and the night
   pictures are made from the plate too. The parts file should come out identical across a design's colors; check it.
2. Decide how a color's pictures are named and loaded, and what it costs in texture memory (44 plates where there
   were 18).
3. Confirm the paint color can be read, bucket it, roll, and store the result on the car.
4. Nothing here was run through `platesame` or the needle, legend and mover checks; run them per color (a darker or
   lighter cabin could change a printed legend's contrast).
5. Nothing is in `42/`. Wait for QA to be clear before writing there.
