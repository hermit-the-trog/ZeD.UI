# dashpx — the pixel-art dashboards

The 19 vehicle dashboards are painted here and read by the game from data. Nothing in `ZeD_Dashboard.lua` is specific to one design.

## How a dash is made

`engine.py` paints a dash as a height field (toward the driver) with a material per pixel, lit from the windshield, with real height-field shadows and per-material colour ramps (no blending, no dithering) — the method of the belt buckles and the main menu desk. `widgets.py` holds the parts (gauges, windows, knobs, buttons, rockers, toggles, vents). `dashlib.py` builds on both: the three shells, the cluster pieces, the lower rows, the consoles, the radio slot, and the live parts each piece hands the game. `designs.py` is the 19 designs.

Depth is one rule for every dash: dash top 0 (far), brow lip 11 (nearest), lower dash and console 5, cluster face −6 (sunk in the binnacle), dial faces −8.5. The binnacle's side walls and sill show, never its ceiling; the brow's shadow lies across the top of the dials. Every placed piece is checked against the one flat surface it sits on: a label, knob, dial or lamp that would cross a bezel or a seam stops the export.

Two more checks stop the export. Nothing that moves may travel over print: every lever tab and slider knob sweeps its whole travel, and a legend or tick mark anywhere under that sweep is a placement error (the legends under a slot start a clear pixel below the tab). Every needle, swept through its whole travel, must stay on its dial: on the face, on the face's print (a needle over a legend is allowed; real gauges do it) or on its own hub (the dome on its pivot, or a shroud the design registers with `Build.hub`, the D6's fan speedometer). It may not cross another needle's sweep or another live part. A miss stops the export (`build.needle_check`, Oct 29 2026). And the right end of the dash's top edge (`HINT_X0`..`HINT_X1` in `dashlib.py`) stays plain on every plate, because the game prints the gamepad hint there; the defroster grille stops short of it.

## The pipeline

```
python build.py [design ...]     plates, state sprites, parts, previews (out/<design>/)
python sheet.py                  a numbered contact sheet of the previews
python export_lua.py <mod root>  the PNGs into 42/media/textures/ZeD/dashpx/, and the generated
                                 42/media/lua/client/ZeD/DashPx.lua and PixelFonts.lua
python luatest.py [k]            runs the real Lua under LuaJIT with the game's API mocked and paints
                                 what the game would draw, for every design (out/luatest/)
python luatest.py hints          every gamepad hint line (each control focused, key out, key in, running)
                                 fits the room the plates leave for it
python luatest.py badges         the badge roles against the game's own car names (liveries, wrecks, fleet cars)
python luatest.py night [k] [design ...] [--needles own|lit]
                                 the dash at full night, lights on and off (out/luatest/<design>_night_on_<k>x.png), tinted
                                 textures drawn in their tint: what nightsheet.py's previews must agree with
```

`luatest.py` runs the Lua inside Python through `lupa`. Where `lupa` is not installed it runs the same through a LuaJIT
executable instead (`luacli.py`: `$LUAJIT`, or the LuaJIT the VS Code Lua debugger ships), the draw calls read back over
stdout. The van previews read the game's decals from `$ZED_DECALS` (its `media/textures/shirtdecals`).

```
python nightsheet.py <out.png> [k] [design ...] [--needles own|lit]
                                 day | dusk | night, lights on | night, lights off, at zoom k (2)
```

The export is deterministic: the same sources give the same files on every run, and a PNG whose pixels have not changed is left alone. Without scipy the engine uses `ndi_np.py` (the same calls in plain numpy, pixel for pixel the same plates).

## At night

Director, Oct 21 2026: the gauges have no backlight. Behind the dash plate, in front of each gauge, a small incandescent bulb sits on one side of the opening, just out of sight (never drawn): its warm light washes across the face from that side, so the figures and the needle near the lit edge read and the far side stays dim; the plate round the openings (wood, vinyl, steel, aluminium) stays dark but for a faint spill on the rim. A lamp under the dash's brow shines down on the radio, the climate controls and the switches. `designs.NIGHT` gives each design the side its gauge bulbs sit on (each gauge a little off it and its own strength) and its lamp rows; the openings themselves are found from the gauges' parts (a needle's pivot, the clock, the ribbon's window). The VFD clusters (the Lang 4000, the Cossette) light themselves and get no gauge bulbs. `night.py` relights the same height field: every pixel on its own material's ramp warmed to a 2700 K bulb (two darker steps under each ramp for the night), the falloff stepped with an ordered 4 x 4 dither. The export adds per design `dash_<id>_night.png` (bulbs on) and `dash_<id>_dark.png` (bulbs off), and in `DashPx.lua` a `night` table: the light map (one hex digit per 4 x 4 plate pixels: the light a flat live part gets, as a share of the day's) and the backlit LCD glass.

Director, Oct 29 2026: the late models light their gauges blue-green (`night.TINT_GREEN`, a filtered bulb, the early-90s GM way): the Dash Elite, the Primani, the SUV and the Lang 4000's clock, under amber lamps; the Cossette's pod lights itself, so its lamps are the green ones. A light source names its tint in `designs.NIGHT` (`wash=dict(..., tint="green")`, or a lamp row's last item); none named is amber. `night.py` keeps each tint's light apart and warms every pixel (and the printed gradients) by the mix, each tint weighted by its own light; a dash lit in amber alone comes out exactly as before, and the dark plate is untouched. Such a dash also exports a tint map beside the light map (`tints`, a palette, and `tmap`, a hex digit per cell into it): a live part takes the colour of the light it sits in. Needles on the green gauges keep their own orange and take only the light's level, as if light-piped (`designs.NEEDLES_UNDER_TINT = "own"`, exported as `needleOwn`): the director's pick, Oct 29 2026 ("b, keep the orange needles"); `"lit"` (the needles taking the green) stays for the night sheets' `--needles lit`. The green clusters have three bulbs behind each face, spread over 140 degrees round the wash's side, each at 0.45 of the one bulb (`designs.GREEN_WASH`; `wash` takes `bulbs`, `spread`, `each`), and the Cossette's green lamps 1.9 times the power: measured at night, lights on, their gauge faces' mean light is 1.33 to 1.47 times the amber dashes' (the Cossette's console 1.37 times), with no more of a face lit to the top than on the amber ones (director: "not as bright as today, but brighter than the amber").

The game (`ZeD_Dashboard.lua`, `ZeD_Plate.lua`): how dark the dash is follows `IsoGridSquare:getLightLevel` at the car (the darkest of its square and the four round it, settled over a second): day plate at 0.62 and above, night at 0.22 and below, in eighths between. The bulbs burn on vanilla's headlight switch while the lamps can light (`getHeadlightCanEmmitLight`). The night (or dark) plate goes over the day one; needles, pointers, tabs, the key, badges, the clock's hands and the radio's face take the light map's level under them; lamps, LEDs, VFD and LED figures and the radio's readout keep their colours, and LCD glass lights from behind while there is power. At n = 0 nothing differs from the day.

`live.py` is the game's side in Python (the previews). `luatest.py` is the game's side in Lua (the real files). The two should agree; when they don't, the Lua is what ships.

## What the game draws live

Badges never print a livery on a maker's plate. The game names a car "livery, maker, model" ("Fossoil Chevalier D6"); the dash finds the maker (Chevalier, Dash, Franklin, Masterson, Mercia) and splits there. A name with no maker in it uses the design's own `make` and `model` (from its title, or `BASE_CAR` in `export_lua.py`) when the car is one of the game's own families; a modded car keeps its own first word (after a model year) as the maker.

Per design, `DashPx.lua` lists parts by type: `needle`, `ribbon`, `lamp` (rect lists, with a halo), `led`, `gear`, `bars`, `digits`, `ptr` (knob pointers), `tab` (lever tabs and sliders), `sprite` (the key, the pulled headlamp knob, toggles and rockers: cut from a render of the plate in that state), `badge` (roles `full`, `make`, `model`, `sub`, `unit`), `clock`, `sticker`, `headunit`, `climate`, `meter`. Hits name the vanilla verb (`ACT` in `ZeD_Dashboard.lua`) and what it needs (`hasTrunk`, `running`, `hasHeater`, `hasLightbar`). Coordinates are plate pixels (800 × 178; 172 before Oct 29 2026, when the dash was taken down to the screen's edge); angles are screen degrees (0 = right, 90 = down).

`ZeD_PixelParts.lua` (`ZeD.Px`) is the shelf atom that draws them: nearest-filtered textures at a whole multiple k, rect lists, needles rasterised on the art grid, seven-segment figures, the two pixel fonts.

## The van's right side (round 6)

A business van whose logo the game ships wears it there: `v6.VAN_LOGOS` maps the van's script to the game's own decal in
`media/textures/shirtdecals/` (Spiffo's, Fossoil, McCoy's), read at runtime, one texel per plate pixel, on a die-cut
backing the export bakes per decal (`DashPx.stickers`, `DashPx.vanLogos`). The art is not copied into the mod. Any other
company's van shows a NO SMOKING plate, a private van (plain Van, VanSeats and its paint jobs, a plain StepVan) an ash
tray (`ZeD_Dashboard.lua`, `_vanRight`).

## Round 6 in the game (Oct 24 2026)

- **Sprites with a value:** a sprite part shows while `st[src]` equals `when` when `when` is a string or a number (the
  key's `keyPos` "off" / "on" / "start", `ashOpen` 1..3, `hula` 0..2, `vanRight`), or as a flag otherwise.
- **The key:** OFF with the key in, START while the starter turns (the engine's state reads Starting or
  RetryingStarting), ON while it runs; it rests 120 ms on ON between the ends.
- **Ash trays:** shut on 6 cars in 10, the rest open at one of the design's levels, from the car's key number; a click
  opens or shuts it (`modData.ZeD_ash`).
- **The taxi's meter:** the fares are ZeD sandbox options (`SandboxVars.ZeD.TaxiFlagDrop`, `TaxiPerFifthMile`,
  `TaxiPerMinuteWaiting`, `TaxiPerExtraPassenger`; `42/media/sandbox-options.txt`). The `meter` parts fill `digits` cells.
- **The hula girl** sits at y = -9: the dash draws her above its own top edge.

## The key, the column and the screen's edge (Oct 29 2026)

- **The plate is 800 × 178** and the dash runs to its last row: the game sets it flush on the bottom of the player's
  screen (`_layout`, no gap). The race car's panel runs on past the edge, its bottom cut square. The light map rounds
  its rows up (45); the last row of cells is the mean of the plate rows it holds. Random fields (grain, speckle, ash,
  the night's lumps) are drawn through `engine.plane`, which keeps every value a 172-row plate had: growing the plate
  changed only its bottom rows.
- **The key** (`v6.key_turn_variants`) is seen edge-on from an eye over the column (one-point perspective): a bar
  along the slot, bare nickel on the wagon, the Lang 4000 and the Horizon, glossy black elsewhere (their lock face
  aluminium). A 10 px chrome ring hangs from the middle of its near edge, and from the ring a teardrop leather fob
  (tan, or cocoa on the light cabins), drawn on the plate in each key sprite so the engine casts its shadow.
- **The column's shroud** (`v6.column_shroud`): a 100 × 46 half squircle in the cabin's vinyl standing on the last
  row at `COLUMN_X`, after the lower row; the lower rows keep 104 px clear for it (`LEFT_SPAN`, `RIGHT_SPAN`). Where
  the right side has no room left for the wiper (the ambulance's switch panel) the wiper moves left of the column.
  The race car has none (its tach sits where the shroud would).
- **One more check** (`build.mover_check`): no printed legend or mark under the key, its ring or its fob in any
  position; nothing printed, no live part, no click area and no key on the shroud.
