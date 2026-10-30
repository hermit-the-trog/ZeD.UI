# Handoff to Code: dash needles and green gauge light (Oct 29 2026)

The director's brief: "Check the vehicle dash gauges and needles for overlaps. Truck speedo needle is off. The late model cars in the game need green glow from the gauge lights instead of amber." The audit is done and the decisions are locked (Oct 29, chat). Two jobs follow, plus one tool repair.

- **Review material:** `ZeDUI/mockups/dash_fixes_20261029/`
  - `d6_speed_before.png`: the D6 fan speedometer today, needle at 0 / 25 / 45 / 55 / 75 / 100 mph. Pixels off the face are in magenta.
  - `d6_speed_after_proof.png`: the fix, with D6 on top and the fire pickup below.
  - `needle_audit.py`, `needle_audit_before.txt`: every needle on all 19 dashes swept through its travel.
  - `d6_proof.py`: the fix as a monkeypatch. It writes nothing.
  - `needle_crops.py`: crops of one gauge at six readings.
  - Run them from `tools/dashpx` with `py -3.14`. Python 3.12 there has no numpy.

## What the audit found

- **Only one gauge has a needle that leaves its dial: the D6 fan speedometer, and the fire pickup that shares `cl_d6`.**
  - The pivot (240, 100) sits 12 px below the window floor, and the sweep runs 205°–335°.
  - From 0 to about 7 mph, and from about 93 to 100 mph, the needle's root rises out of the bottom bezel (13 px off the face), not out of the hub shroud.
  - 0 mph is the parked state, so this is what the director sees.
  - The MPH legend sits in the needle's 42–60 mph band.
- **Nothing else leaves its face.** No needle crosses another gauge, a lamp, an LED or an odometer.
- **The other crossings are needles over printed legends:**
  - the police speedometer's CERTIFIED, at 0–15 and 125–140 mph;
  - the round speedometers' MPH, by a pixel at 0;
  - the Primani's twin fuel/temp needles over the centre icons, around half a tank.

  **Director: leave those.** Real gauges do this.

## Job 1: the D6 fan speedometer (`designs.cl_d6`)

**Director's pick:** lift the hub and tighten the sweep. The proof shows 0 px off the face at every reading, on both cars, and no build warnings.

| | Now | New |
|---|---|---|
| Pivot | (240, 100) | (240, **96**) |
| Tick radius `R` | 66 | **62** (the top ticks stay at y 34) |
| Sweep `a0`..`a1` | 205..335 | **210..330** (ticks, figures and needle together) |
| Needle `r0`..`r1` | 27..64 | 27..**60** (`R - 2`) |
| Shroud radius | 26 | 26 (unchanged) |
| MPH | `pcy - 37`, in the needle's path | **on the shroud**: `d.text("MPH", pcx, pcy - 20, "paint_c", align="c", flatlight=True)` |

- The window, the square gauges, the lamp columns and the odometer don't move.
- **Check the night wash still finds this window.** `night.gauge_faces` seeds from the needle's pivot, and the pivot now sits under the shroud, not below the window. Compare `nightsheet.py` for d6 and fire before and after.

## Job 2: green gauge light on the late models

**Director's picks:** blue-green; gauges only; plus the Cossette's switch lamps.

| Design (game script) | Green | Stays amber |
|---|---|---|
| `dashelite` (ModernCar) | gauge wash | console lamp, lower lamp |
| `primani` (ModernCar02) | gauge wash | console lamp, lower lamp |
| `suv` (SUV) | gauge wash | console lamp, lower lamp |
| `luxury`, Mercia Lang 4000 (CarLuxury) | the clock's wash | console lamp, lower lamp; the VFD keeps its own colour |
| `cossette` (SportsCar) | **its lamps** (console and lower): the one exception, since its pod lights itself | the VFD keeps its own colour |

Every other design stays as it is, at 2700 K.

**The green.** Start from `TINT_GREEN = (0.42, 1.00, 0.74)`, a blue-green filtered bulb (early-90s GM). It's a starting value: the director approves it on a night sheet before export.

**What it takes.** Today there's one bulb colour for everything: `night.TINT`, `night_ramp(warm_)`, the export's single `night.tint`, and `ZeD_Plate.lua`'s `L.tint`.

- **`designs.NIGHT`:** a tint per light source. For example, `wash=dict(..., tint="green")`, and a lamp entry that can carry its own tint. Amber is the default, so the other 14 entries don't change.
- **`night.py`:** two colours on one plate.
  - Keep the wash's light and the lamps' light apart in `light_field`.
  - Tint each pixel by the mix: `(E_wash * T_wash + E_lamp * T_lamp) / (E_wash + E_lamp)`. Do the same for the ramps `relight` warms.
  - The dark plate (bulbs off) is untouched.
  - The dither and the falloff stay as they are.
- **Export and `ZeD_Plate.lua`:** the live parts need the colour of the light they sit in, not one global tint. Code picks the form. One way is a second hex map beside the light map: which tint each 4 × 4 cell gets. Rules:
  - needles on a green gauge go green-lit;
  - tabs, knobs, the key and the radio under an amber lamp stay amber.
  - The dash's `night.tint` stays as the fallback, so older data still loads.
- **Needles: proof both, the director picks.**
  - (a) Needles on green gauges take the green like everything else.
  - (b) Needles keep their own orange and take only the level, as if light-piped. This is how GM did it, and it reads better: orange under a green multiply goes olive.
- `live.py` mirrors whatever the Lua does. The previews must agree with `luatest.py`.

## Tool repair (do this first)

`luatest.py` fails before drawing anything:

```
ZeD_Dashboard.lua:1030: attempt to call method 'isMouseOver' (a nil value)
```

The mock has fallen behind `prerender`. Add `isMouseOver` (returning false), then rerun all 19 so both jobs get checked against the real Lua.

## Make the audit permanent

Move `needle_audit.py`'s face check into `build.py` as an export-stopping check, alongside the lever-travel and flat-surface checks: every needle, swept through its whole travel, must stay on its face, its print, or its own hub. Needles over print are allowed, as above.

## Done means

1. `build.py`, `export_lua.py <mod root>`, then `luatest.py`, `luatest.py hints` and `luatest.py badges`: all clean, with no new warnings.
2. The needle audit shows 0 px off the face on all 19 dashes.
3. `nightsheet.py` at k 2 for the five green designs, plus d6 and fire. The director signs off the green and the needle choice from this sheet.
4. In game, at real play scale (fullscreen, ZeD UI scale 1.75x at 4K), with the window layout reset (R) before each test:
   - a parked D6 by day;
   - the fire pickup at speed;
   - each green car at night with the headlights on and then off.
