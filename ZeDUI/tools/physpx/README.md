# physpx: the machine plates and watches in lit pixel art

The ovens, microwaves, fryer, generators, grill, car radios and siren, the no-watch speed keys and the nine watches,
drawn the dashboards' way (ZeDUI/tools/dashpx: a height field, a material per pixel, lit from above) and drawn in game
by the shared plate template `42/media/lua/client/ZeD/ZeD_Plate.lua` from the generated `PhysPx.lua`.

- `d_*.py` — the designs (one module per family: `d_ovens`, `d_micro`, `d_gen`, `d_grill`, `d_props` radios and siren,
  `d_walkie` the two-way radios in the radio tab (five walkies, the makeshift one, the ManPack, three ham sets),
  `d_makeshift` / `handwire` / `hw/` the hand-wired boards, `d_heads` the dash heads, `d_speedkeys`, `d_watches` CaZio
  and the expensive one, `d_timez` Timez plus the watch roster)
- `plates.py` — the registry: every plate, its state pictures and preview states
- `export_phys.py [mod root]` — writes the plate pictures, `PhysPx.lua` and `PixelFonts.lua` (default `out/mod/ZeD-UI`)
- `platesame.py [plate ...]` — proves the game's Lua draws every plate exactly as the preview does (export first)
- `test_*.py` — the organisms outside the game (`test_watch.py`: every watch item, night, light, alarm setting)

Run from a copy of this folder with Python 3, numpy, scipy, Pillow and lupa. In the repo the tests use the mod's own Lua
and textures; in a scratch copy, a `lua/` folder beside the scripts and the last export.

Watch addons: see `WATCH_ADDON_GUIDE.md` at the repo root.
