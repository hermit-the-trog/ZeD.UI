# Machine plates at 336 px: mockup v1 (Oct 29 2026)

The 17 machine plates from `PLATE_SIZES_SPEC.md` re-laid to the 336 px main face, drawn by the real physpx code.
Nothing here is wired into `plates.py` or exported. The page is `../zed_plates_336_v1.html`.

- `m_ovens.py`: the six ranges and the fryer
- `m_more.py`: the two microwaves, four generators and the grill
- `m_ham.py`: the three ham sets' main faces
- `mock_sheet.py out.png "Title" pid ...`: today's plate beside the 336 face, at 2x
- `mock_check.py`: every face is 336 wide, keeps today's click area ids, kinds and live parts, has click areas of
  10 x 10 or more, puts no new live part at the edge, and builds without warnings (all 17 pass)
- `mock_export.py` + `mock_page_template.html`: rebuild the page

Run from a copy of `tools/physpx` with these files beside it. Once approved, each function replaces its
counterpart in `d_ovens.py` / `d_micro.py` / `d_gen.py` / `d_grill.py` / `d_walkie.py` (same signatures; each module's `MOCK` maps plate id to function),
then export and run `platesame.py`.

Not done: the 200 px narrow faces (the hams already have theirs).

## Oct 29: the cursor disc (both ham sets, wide; the narrow faces to follow)

The red band marker used to slide over the printed arc with nothing physical carrying it. Now a clear acrylic disc
sits under the tuning knob with the hairline printed on it (`cursor_disc` in `m_ham.py`), and the knob's pointer
reads `bandF` over the arc's sweep (-205 to 25 degrees) instead of `tuneF` over a free 360. That is the only
change `mock_check.py` reports, and it is intended. No new data is needed: `bandF` already drives the old marker.

## Oct 29: the red range and the chrome microwave

- **Red range:** MERIDIAN moves under the SIGNAL lamp and the middle band closes up, so the face keeps its original
  146 px height.
- **Chrome microwave:** the fancy one, now 1988 (director: flat buttons, 1993 or older, not today's). Smoked glass
  over brushed chrome, a blue-green fluorescent display (`mwText`, COOK, `mwPower` in five bars) and printed glass
  keys. It takes the white microwave's key set (power, timecook, d0-d9, stop, start) in place of the two dials and
  the START bar. `mock_check.py` reports that change, and it is intended. Retitle it in `plates.py` when it goes in.

## Oct 29: the makeshift ham's speaker

No ring. `drilled_grille` in `m_ham.py` drills the holes straight into the board by hand: a pencilled grid whose rows
wander, each hole up to a pixel off its mark, mostly 2 x 2 with about one in five drilled with the bigger 3 x 3 bit,
and a few skipped. Holes sit on whole pixels so every one is a clean drill mark at 2x. Seeded, so it never changes
between exports. The narrow face (`ham_makeshift_n`) should get the same.

## Oct 29: the makeshift ham's labels

Every label (CH-, MEM, CH+, TUNE, VOL, MIC, TALK, LISTEN, MUTE, HOLD MEM) is red embossing tape from an old
wheel label maker: `dymo()` in `m_ham.py`. A 9 px glossy red vinyl strip (`dymo_red`), raised pale capitals in the
3 x 5 face spaced 2 px apart (`dymo_white`), cut square, now and then stuck a pixel off level (seeded per label).
HOLD MEM was masking tape and is now embossing tape too. The narrow face should get the same.

## Oct 29: the game's own brands (director: real brands from the game only, watches excepted; picks approved)

`m_brands.py` draws the four brands the game has logo art for, from that art, in the plates' own pixel faces:
Mass-Genfac Co. (MG monogram + wordmark), Lectromax (white-ruled box, red as on the van or dark as on the flyer),
Knox Pack Kitchens (compass O, arrow) and ValuTech (green italic, dark outline; all 5 x 7 capitals at this size).

| Plate | Was | Now | Source in the game |
|---|---|---|---|
| Green range | Hollister Custom | Mass-Genfac Co. | logo, van, cap, key |
| Red range | Meridian | CGE | the Save the CGE flyer (Kentucky, 1961-1980) |
| Grey range | Lectromax | Lectromax badge | van livery |
| Industrial range, large oven | Ironclad, Convectron | Knox Pack Kitchens | logo; their ad sells industrial stoves |
| Chrome microwave | Tempo | Premium Technologies | the premium brand |
| Red / yellow / blue generator | Mass Genfac / Knox Power / Sundowner | Lectromax / Premium Technologies / ValuTech | the items' own names |
| Grill | Jorge Foreguy | Hector Lopez | the name players see (Jorge Foreguy is the internal key) |

Unchanged: Modern range and ham (Premium Technologies), white microwave (ValuTech), fryer (Fryers Club), US ARMY
COMM., the old generator (unbranded in the game), the makeshift ham. Retitle the grill in `plates.py` when it goes in.

## Oct 29: the 200 px narrow faces (director: yes, for the small screens)

`m_narrow.py`: one narrow face per plate, for the smallest settings only (fixed UI scale 0.5, or Auto on a 720 or
800 screen with the 16 px font). Rearranged, not shrunk; every control at full size. `mock_narrow.py out.png [pid ...]`
draws them and checks each against its 336 face: 200 wide, the same click area ids, kinds and needs, the same live
parts, click areas of 10 x 10 or more, no warnings. All 17 pass. Plate ids take `_n`, like the ham sets'.

| Plate | Narrow face | Layout |
|---|---|---|
| Green range | 200 x 206 | Mass-Genfac, the four burners across, the control centre full width |
| Red range | 200 x 244 | push buttons two by two, oven and thermostat, then timer and the lamp over CGE |
| Grey / modern range | 200 x 176 / 196 | the four burners across, the glass panel full width under them |
| Industrial range | 200 x 256 | six burners three across, two deep (as their diagrams print them); dial, toggle, pilot; timer box under Knox Pack |
| Large oven, fryer | 200 x 196 / 220 | badge on top, lamps and switch, then the two dials |
| Microwaves | 200 x 168 | the control panel whole, the door a strip |
| Generators | 200 x 220-270 | two or three rows; on the red and yellow sets the building's cord drops clear of the fuel gauge |
| Grill | 200 x 156 | lid (Hector Lopez badge, thermometer), knob panel full width, the tank bay (side shelves and door go) |
| Ham sets | as before | civilian and army get the cursor disc; the makeshift gets the tape labels and the drilled grille |

The microwave functions in `m_more.py` take `narrow=True` and share their panel with the 336 face.
