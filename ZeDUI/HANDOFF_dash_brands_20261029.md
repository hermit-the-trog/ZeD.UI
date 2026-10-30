# Handoff to Code: maker branding replaces the console plaques (Oct 29 2026)

The director's brief: "The whole idea is to replace the generic plaques with branding." Approved Oct 29: "Ready to send to code. Much better."

The grey stamped plates, the chrome ovals and the bare-text name lines on the consoles go away. Each of the game's five makers gets its own mark: its emblem, its name lettered in that brand's own hand, and the model's name under it.

**Do this after `HANDOFF_dash_keys_edge_20261029.md` has landed.** Both touch `designs.py`, the export and `ZeD_Dashboard.lua`. The taller plate in that handoff doesn't move the console slots.

**Review material:** `ZeDUI/mockups/dash_fixes_20261029/emblems/`

- `brand_before_after_2x.png` and `brand_curvy_before_after_2x.png`: the target, next to today's plaques.
- `brand_all_13_dashes_2x.png`: every civilian dash, branded.
- `brand_lockups_4x.png` (and `_1x`): the five marks on dark vinyl, tan vinyl and walnut.
- `brand.py`: **the source.** Letters, emblems, materials, sizes. Port it into `tools/dashpx` as a shelf module (`brands.py`) rather than redrawing anything.
- `brand_insitu.py` and `brand_slots.py`: the proof's placement. Monkeypatches; run from `tools/dashpx` with `py -3.14`.
- `emb_r2_4x.png`: the emblem round the picks came from.

## Who's who

The parodies, from the director and the wiki:

| Maker | Parody of |
|---|---|
| Chevalier | Chevrolet |
| Dash | Chrysler (Dodge, Jeep) |
| Franklin | Ford, the Louisville hometown maker |
| Mercia | Mercedes-Benz |
| Masterson | Fictional |

None of the marks may come to read as a real logo.

## The five marks

The emblems are drawn at 18 px tall (0.9 of the 20 px emblem designs). Each wordmark sits 5 px right of its emblem, and the model line sits 3 px under the wordmark. Every raised letter casts a 1-pixel drop shadow (`dark` 0.5) right and down; the model line casts one at 0.45. That shadow is what keeps the light lettering readable on the tan and khaki cabins.

| Maker | Emblem | Wordmark | Model line |
|---|---|---|---|
| **Chevalier** | Heraldic shield in gold enamel (`paint_y`) with a chrome rim and a chrome chevron | `CHEVALIER`: bold block capitals, 7 tall, two-pixel stems, gold, tracking 1 | Gold |
| **Dash** | Forward-leaning bar in red enamel (`paint_r`) with a chrome rim and two chrome speed lines | `DASH`: heavy capitals, 9 tall, sheared into italics (row `r` moves `(8 - r) // 3` px right), white (`paint_w`), tracking 2 | White |
| **Franklin** | One navy enamel badge (`v_patrol`), 66 × 14, chrome rim and chrome divider. The left 14 px is the F block, a white 3-px-stem F; the rest holds `FRANKLIN` | Plain condensed capitals, 7 tall, one-pixel strokes, white, flat paint, tracking 2 | White, centred under the badge |
| **Mercia** | Fine chrome ring, black field, chrome M of two peaks | `MERCIA`: thin capitals, 7 tall, polished alloy (`alu`, **lit flat**: flat chrome facing the driver reflects the dark cabin and goes grey), tracking 3 | Cream (`paint_c`) |
| **Masterson** | Rounded square, chrome rim, black field. An orange sun cut by black bands on rows 11, 13 and 15 of the 20 px design | `MASTERSON`: italic capitals, 7 tall (row `r` moves `round((6 - r) / 3)` px), two-tone: top 3 rows sunset yellow (`paint_y`), the rest orange (`paint_o`), tracking 1 | Orange |

The letterforms are bitmaps in `brand.py`: `G_CHEV`, `G_DASH`, `G_FRANK`, `G_MERC` and `G_MAST`. Take them as they are; they were drawn for these sizes.

**Performance tags** (the design's sub line: 5.0, V8, 4X4, EFI) follow the model name in red (`paint_r`), as the Cossette's and the All-Terrain's already were. Skip the tag when it repeats the model, as the D6's does.

## Where they go

Each mark is centred in the clear flat field left once the console plaque is gone. `brand_slots.clear_field` finds it: the largest rectangle on the one surface round the old plaque's centre, or round (646, 46) on the curved consoles.

| Dash | Field | Mark | Model line |
|---|---|---|---|
| Lang 4000 | 94 × 37 | Mercia | LANG 4000 |
| Nyala | 94 × 41 | Chevalier | NYALA |
| Cossette | 94 × 32 | Chevalier | COSSETTE **5.0** |
| D6 | 200 × 41 | Chevalier | D6 |
| Dart | 200 × 39 | Chevalier | DART |
| Cerise Wagon | 94 × 37 | Chevalier | none: the model already sits on the cluster |
| Horizon | 200 × 41 | Masterson | none: the model already sits on the driver's side |
| Valuline | 94 × 39 | Franklin | VALULINE |
| All-Terrain | 72 × 24 | Franklin | ALL-TERRAIN **4X4**, replacing the old red 4X4 line |
| Bulldriver | 200 × 41 | Dash | BULLDRIVER **V8** |
| Rancher | 200 × 32 | Dash | RANCHER **4X4** |
| Dash Elite | 66 × 29, between the vents | Dash | ELITE **EFI** |
| Primani | 88 × 22, between the vents | Chevalier | PRIMANI **EFI** |

**The curved consoles (Elite, Primani).** Their top-edge name line (the `full` badge) is removed. Nothing is printed on the rim: the director said the model "moves down into the emblem, not printed on the dash."

**The Primani's vents** go from 100 px to the boxy consoles' 88 px. The left one stays at x 516 and the right one moves to x 692, so the mark gets an 88 px slot. The Elite's vents stay as they are, since its mark fits in its 66 px gap.

**Unchanged:**
- The fleet dashes (police, taxi, ambulance, fire, ranger) keep their unit stencils. Those are fleet labels, not maker plaques.
- The race car has no badge.
- The driver's-side model badges on the Cerise Wagon and the Horizon stay.

## How the game picks the mark

**Pick by the car's maker, never by the dash design.**

- The Chevalier Step Van uses the Valuline's dash, so the van dash has to be able to show the Chevalier mark.
- Modded cars fall back to the Nyala's dash with their own maker word.
- The Lua already splits a car's name into livery, maker and model (`_brandName`). Use that maker.

Suggested shape (Code's call):

- **Each mark is a sprite cut per dash** through the existing variant mechanism (`b.variant` and `cut_variant`), as the key and ash trays are. That way it's shaded on that dash's own surface, carries its drop shadow, and takes the night light map like the other sprites.
  - Cut all five makers' marks for every civilian dash. They're small, and it lets any maker show on any dash.
  - Draw the plate itself with an empty slot.
- **The model line stays live text** (font `35`), so liveries and modded names still work.
  - Colour: the brand's model colour, the tag in red.
  - Position: left-aligned 3 px under the wordmark; centred under the badge for Franklin.
  - It's fitted with the existing `fit_text` to the room between the wordmark's left edge and the field's right edge, so a long modded name never runs into a vent.
- **The mark doesn't move with the model's length.** Centre each (dash, maker) mark at build time on its emblem, its wordmark and the model line it normally carries on that dash.
- **A maker we don't know** (modded cars) gets today's plaque, now as a sprite: the old plate art cut as a variant, with its live name as today. That's the only place the generic plaque survives.

## Checks

1. `build.py`, `export_lua.py <mod root>`, then `luatest.py`, `luatest.py hints` and `luatest.py badges`: all clean.
   - Each mark sits on one surface: `check_flat` over its box.
   - `luatest.py badges` (the game's own car names against the badge roles) now also checks which mark each name gets. The Step Van and the fleet liveries are the edge cases.
2. A modded name ("Ford Bronco" on the Nyala's dash) shows the fallback plaque. "Chevalier Step Van" on the van dash shows the Chevalier mark with STEP VAN under it.
3. `nightsheet.py` for the Elite, Primani, All-Terrain, Lang 4000 and Cossette: the marks take the light like the rest of the console. They sit under the console lamp, which stays amber on the green-gauge cars.
4. In game at real play scale (fullscreen, ZeD UI scale 1.75x at 4K), with the window layout reset (R) first. One car of each maker, checking that each mark is crisp and centred and that the model line and tag read.
