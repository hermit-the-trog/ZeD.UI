# Handoff: the dashes' new lamps, odometers and trip odometers (Nov 6 2026)

From design, for Build and then QA. Answers `HANDOFF_design_dash_indicators_20261106.md`. **For the next beta, not
beta 6:** nothing here touches `42/` yet. The art is in `ZeDUI/tools/dashpx/` (designs.py, dashlib.py, widgets.py,
live.py), built with `build.py` (19 dashes, no warnings). `export_lua.py` has **not** been run; Build runs it when the
beta 6 regression is done. Punch list item 92.

## The director's answers (Nov 6)

1. **Seat belt lamp on every road car.** ZeD's cars are all 1993 or older, but a belt reminder lamp was on US cars from
   1972, and a dash without one looks wrong next to Roadworthy. The race car is the exception.
2. **The race car gets OIL and WATER only:** no belt, no high beam (a race car has a harness and no headlamps).
3. **The Dart gets a temperature gauge** in its empty third dial.
4. **Odometer in miles on the plate** (the cars are American); **the Simple dash follows the player's units.**
5. Design's call: **lamps with nothing to show stay dark**, lighting only in the key-on bulb check, until Roadworthy (or
   ZeD itself) gives them a state. Art is baked into plates, so they're always drawn.

## What's drawn

| Dash | Added |
|---|---|
| d6, fire | OIL and BELTS in the left column (pitch 13); odometer and trip beside the speedo's ribbon |
| van, ambulance | TEMP in the lamp row |
| police | TEMP in the second column (pitch 13) |
| bulldriver | two columns of four: OIL GEN BRAKE BELTS / TEMP HI and the turns |
| rancher | TEMP in the row |
| dart | a C-H temperature gauge in the third dial; BELTS and TEMP in the row |
| cossette | temp and belt icons in the strip; the VFD odometer with ODO / TRIP words |
| luxury | a second icon strip (beam, engine, temp, belt); the VFD odometer with ODO / TRIP words |
| dashelite | temp and belt icons in the strip; the LCD odometer, six figures |
| primani | temp and belt icons |
| suv | temp and belt icons in the columns |
| race | two jewel lamps, OIL and WATER, chrome rings, Dymo labels |
| every dash with a speedo dial | the mechanical odometer and trip odometer in the dial's dead wedge |

nyala, taxi, ranger, horizon and wagon already had all four lamps; they get the odometer only. The race car has no
odometer. The belt icon is new in `widgets.py` (`ICONS["belt"]`, 7x7: a figure with the strap across).

## New parts and verbs for Lua

### `drums` (new part type, `ZeD_PixelParts.lua`)

The mechanical odometer: `{ t = "drums", src, x, y, n, cw, ch, fg, last_fg, tenths }`.
- n wheels, each cw wide (cw - 1 painted, a 1 px gap), ch tall. The figures are the 3x5 face (F35), centered in each
  wheel: `gx = x + i*cw + (cw - 4) // 2`, `gy = y + (ch - 5) // 2`.
- The first n - 1 wheels are whole miles (`floor(value) % 10^(n-1)`, zero padded) in `fg`; the last is tenths in
  `last_fg` (dark on the white wheel).
- **The tenths roll:** the wheel holds its figure for the first 80% of each tenth and turns over in the last 20%,
  the next figure coming up from below, clipped to the wheel (`roll = max(0, (frac - 0.8) / 0.2)`, offset
  `round(roll * ch)`). A figure caught halfway at 5 px reads as neither, so it doesn't sit there.
- Mechanical: drawn with or without power, lit like the print it sits on (dimmed by the light map at night).
- `text = true` is the LCD kind (Dash Elite): `src` is a string, right-aligned to n characters, no roll, drawn only with
  power. Lower-case letters fall back to capitals (F35 has "T", not "t").
- `live.py draw_drums` is the reference.

Sources: `odo` and `trip` (miles, with decimals) for wheels; `odoShownT` for the LCD.

### State keys (`ZeD_Dashboard.lua`, the state builder)

- `odo`, `trip`: miles, with decimals. Replace today's made-up `st.odo` (line ~803).
- `odoTrip`: the electronic dashes are showing the trip (per car, saved).
- `odoShown`: `floor(trip)` if odoTrip else `floor(odo)`; for the VFD `digits` parts (cossette, luxury).
- `odoShownT`: `"t" .. pad5(floor(trip))` if odoTrip else `pad6(floor(odo) % 1000000, "0")`.
- `odoMode = power and not odoTrip`; `tripMode = power and odoTrip` (the ODO and TRIP words).
- **`tempLamp` bulb-checks too:** `check or (power and temp > 0.8)` (today it has no check, line ~353). live.py has it.

### Verbs (ACT)

- `tripReset` (the round stem by the trip wheels): A zeroes the trip. Hit 9x9.
- `odoButton` (the electronic dashes' odometer window): A switches ODO / TRIP; **X (secondary) zeroes the trip**. The
  handoff said "long press"; the dash's other controls use secondary for the second action (temp, fan, tune), so this
  follows them. Zeroing only while the trip is showing (so a stray X on ODO does nothing).

Both are pad-reachable like every other hit (the focus walk picks them up from the hit list).

## Saving the miles

- `odo` and `trip` live on the car's modData (`ZeD_odo`, `ZeD_trip`), so they survive sessions and every player in the
  car sees the same figures. The taxi's fare keeps its own session counter (`_trips[id].fareMiles`), unchanged.
- Count miles only while running, as `_trip` does now (speed in km/h x 0.6214).
- **Found cars need a starting mileage** (the game keeps none): seed once, the first time ZeD sees the car, from its
  ID and its condition: a wreck has been driven further. Suggested: `20000 + (id * 7919) % 60000`, plus up to 60000
  more for low condition. Trip starts at 0. Build's call; whatever it is, it's stable for a given car.
- On a server: the driver's client writes modData and sends it (`transmitModData`), no more than every tenth of a mile
  so it isn't chatty. QA to test with two players in one car.
- **With Roadworthy:** if it keeps its own odometer and trip, read those instead of ZeD's, so its dash and ours agree.
  QA finds the names once it's running Roadworthy.

## The lamps and Roadworthy

Today `oilLamp`, `beltLamp` and `brakeLamp` are bulb check only, and `tempLamp` lights only on an engine warning. When
QA has Roadworthy running, Build wires them to its states: high beam, coolant (hot), seat belt (not buckled, 1972 and
on: all ZeD cars), oil. Without Roadworthy they stay as they are. The race car's WATER jewel is `tempLamp`.

## The Simple dash

It has the lamp words already (Belt, Hot, Oil). It needs a **Trip** cell beside Odometer, both in the player's units
(mi or km, one decimal on Trip), and the same verbs: A on Trip zeroes it. A new key: `UI_ZeD_DashPlain_Trip = "Trip"`,
`UI_ZeD_DashPlain_Km = "%1 km"`.

## Night

`nightsheet.py` (the nine changed dashes, `ZeD_design_refs/dash/keyon2/night_A.png`): the new lamps light as lamps,
the drums dim with the dial print under the panel lights.

**The LCD glass at night (the director, Nov 6: "When it's in the dark, it's glowing white still. It's the same gray
color that it is when it's in light").** This is live in the game today, on the Dash Elite's odometer and climate
LCDs: at night the glass is redrawn in its day gray whenever the key is on, lights or no lights. Fixed in the tools:
- `night.py glass_runs` now bakes the glass in its **backlight** color: the day color at 55% (`BACKLIGHT`), in the
  color of the dash's bulbs at that spot (the tint map: green in the Dash Elite's speedo, amber at the console).
- The glass lights only **with the panel lights on**. Lights off, it stays in the dark like the rest of the plate.
- `live.py` has both. The sheet: `ZeD_design_refs/dash/keyon2/night_dashelite.png` (day, dusk lit, night lit,
  night dark).
- **Build:** re-export (the colors are baked into `DashPx.lua`'s `night.glass`), and one condition in
  `ZeD_Plate.lua` (~line 767): `if st.power and L.glass then` becomes `if st.power and L.lit and L.glass then`.
  This one can ship on its own, ahead of the rest, since it fixes what players see now.

## QA

1. Key on: every lamp on every dash lights in the bulb check (the hot lamp too), goes dark when the engine runs.
2. The odometer counts: drive a measured mile (the map's scale) and read it on a drum dash and on the Dash Elite.
3. The tenths wheel turns over cleanly (no half figure sitting there).
4. The stem zeroes the trip; on cossette, luxury and dashelite A switches ODO / TRIP and X zeroes.
5. Quit and reload: both figures kept. A car never driven has a stable starting mileage across reloads.
6. Two players, one car, on a server: both read the same figures.
7. The Simple dash: Odometer and Trip in miles, then in km with the units switched.
8. Night: lights on and off, the drums and the new lamps.
9. With Roadworthy (when QA has it): the four lamps follow its states; the odometers agree with its own.

## Files

- Previews: `Zomboid/ZeD_design_refs/dash/keyon2/` (each dash at key-on, 1x; drive at 2x; `*_trip2x.png` trip mode).
- Before: `Zomboid/ZeD_design_refs/dash/keyon/`.
- Every change in `designs.py` is marked "Nov 6 2026 (Roadworthy)".
