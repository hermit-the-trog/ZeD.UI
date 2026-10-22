# dashpx — the pixel-art dashboards

The 19 vehicle dashboards are painted here and read by the game from data. Nothing in `ZeD_Dashboard.lua` is specific to one design.

## How a dash is made

`engine.py` paints a dash as a height field (toward the driver) with a material per pixel, lit from the windshield, with real height-field shadows and per-material colour ramps (no blending, no dithering) — the method of the belt buckles and the main menu desk. `widgets.py` holds the parts (gauges, windows, knobs, buttons, rockers, toggles, vents). `dashlib.py` builds on both: the three shells, the cluster pieces, the lower rows, the consoles, the radio slot, and the live parts each piece hands the game. `designs.py` is the 19 designs.

Depth is one rule for every dash: dash top 0 (far), brow lip 11 (nearest), lower dash and console 5, cluster face −6 (sunk in the binnacle), dial faces −8.5. The binnacle's side walls and sill show, never its ceiling; the brow's shadow lies across the top of the dials. Every placed piece is checked against the one flat surface it sits on: a label, knob, dial or lamp that would cross a bezel or a seam stops the export.

Two more checks stop the export. Nothing that moves may travel over print: every lever tab and slider knob sweeps its whole travel, and a legend or tick mark anywhere under that sweep is a placement error (the legends under a slot start a clear pixel below the tab). And the right end of the dash's top edge (`HINT_X0`..`HINT_X1` in `dashlib.py`) stays plain on every plate, because the game prints the gamepad hint there; the defroster grille stops short of it.

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
```

```
python nightsheet.py <out.png> [k] [design ...]   day | dusk | night, lights on | night, lights off, at zoom k (2)
```

The export is deterministic: the same sources give the same files on every run, and a PNG whose pixels have not changed is left alone. Without scipy the engine uses `ndi_np.py` (the same calls in plain numpy, pixel for pixel the same plates).

## At night

Director, Oct 21 2026: the gauges have no backlight. Behind the dash plate, in front of each gauge, a small incandescent bulb sits on one side of the opening, just out of sight (never drawn): its warm light washes across the face from that side, so the figures and the needle near the lit edge read and the far side stays dim; the plate round the openings (wood, vinyl, steel, aluminium) stays dark but for a faint spill on the rim. A lamp under the dash's brow shines down on the radio, the climate controls and the switches. `designs.NIGHT` gives each design the side its gauge bulbs sit on (each gauge a little off it and its own strength) and its lamp rows; the openings themselves are found from the gauges' parts (a needle's pivot, the clock, the ribbon's window). The VFD clusters (the Lang 4000, the Cossette) light themselves and get no gauge bulbs. `night.py` relights the same height field: every pixel on its own material's ramp warmed to a 2700 K bulb (two darker steps under each ramp for the night), the falloff stepped with an ordered 4 x 4 dither. The export adds per design `dash_<id>_night.png` (bulbs on) and `dash_<id>_dark.png` (bulbs off), and in `DashPx.lua` a `night` table: the light map (one hex digit per 4 x 4 plate pixels: the light a flat live part gets, as a share of the day's) and the backlit LCD glass.

The game (`ZeD_Dashboard.lua`, `ZeD_Plate.lua`): how dark the dash is follows `IsoGridSquare:getLightLevel` at the car (the darkest of its square and the four round it, settled over a second): day plate at 0.62 and above, night at 0.22 and below, in eighths between. The bulbs burn on vanilla's headlight switch while the lamps can light (`getHeadlightCanEmmitLight`). The night (or dark) plate goes over the day one; needles, pointers, tabs, the key, badges, the clock's hands and the radio's face take the light map's level under them; lamps, LEDs, VFD and LED figures and the radio's readout keep their colours, and LCD glass lights from behind while there is power. At n = 0 nothing differs from the day.

`live.py` is the game's side in Python (the previews). `luatest.py` is the game's side in Lua (the real files). The two should agree; when they don't, the Lua is what ships.

## What the game draws live

Badges never print a livery on a maker's plate. The game names a car "livery, maker, model" ("Fossoil Chevalier D6"); the dash finds the maker (Chevalier, Dash, Franklin, Masterson, Mercia) and splits there. A name with no maker in it uses the design's own `make` and `model` (from its title, or `BASE_CAR` in `export_lua.py`) when the car is one of the game's own families; a modded car keeps its own first word (after a model year) as the maker.

Per design, `DashPx.lua` lists parts by type: `needle`, `ribbon`, `lamp` (rect lists, with a halo), `led`, `gear`, `bars`, `digits`, `ptr` (knob pointers), `tab` (lever tabs and sliders), `sprite` (the key, the pulled headlamp knob, toggles and rockers: cut from a render of the plate in that state), `badge` (roles `full`, `make`, `model`, `sub`, `unit`), `clock`, `sticker`, `headunit`, `climate`, `meter`. Hits name the vanilla verb (`ACT` in `ZeD_Dashboard.lua`) and what it needs (`hasTrunk`, `running`, `hasHeater`, `hasLightbar`). Coordinates are plate pixels (800 × 172); angles are screen degrees (0 = right, 90 = down).

`ZeD_PixelParts.lua` (`ZeD.Px`) is the shelf atom that draws them: nearest-filtered textures at a whole multiple k, rect lists, needles rasterised on the art grid, seven-segment figures, the two pixel fonts.

## The sticker

The Spiffo's van carries the game's own decal, `media/textures/shirtdecals/Buisness_SpiffosDECAL.png`, read at runtime, one texel per plate pixel, on a die-cut backing. The art is not copied into the mod. Any other van shows the plain vinyl.
