# Handoff: laundry faces redesign (Nov 2 2026), ready to build

Director approved ("These are great. I love them."), asked to send to build. Design session work; nothing committed.

## What changed
- **Scale**: all three faces are now the game model's proportions (0.786 m wide x 0.895 m tall), a little taller than
  wide. The face is narrower than its slot and the card centres it (PL.centre), like the other machine plates.
  Faces: narrow 188x214, 336 -> 230x262, 392 -> 269x306, 450 -> 308x351, 562 -> 385x438.
- **Washer (IsoClothingWasher)**: now a top-loader as the game draws it: the controls on a dark backsplash console,
  the lid up against it, the open tub seen from above (perforated basket, agitator, bleach cup), the load lying
  round the agitator, and soapy water rising through the clothes at the game's 5 water levels.
- **Dryer (IsoClothingDryer)**: same front door and clothes, now under the matching dark backsplash console.
- **Washer-dryer (IsoCombinationWasherDryer)**: still the front-loader (it is one in game); new clothes and soapy water.
- The clothes are a real load in every machine (buffalo-check flannel, jeans with stitching, khakis, sweater, tees,
  towels, socks), shaded and shadowed by the plate light.

## Files (all uncommitted, laundry only)
- `ZeDUI/tools/physpx/d_laundry.py` (the design), `ZeDUI/tools/physpx/rtv_plates.py` (variants -> `L.VARIANTS[...]`)
- `42/media/lua/client/ZeD/PhysPx.lua`: only the 15 laundry plate entries (washer / dryer / washer_dryer, base, _n,
  @392, @450, @562). Everything else is HEAD byte for byte.
- `42/media/lua/client/ZeD/ObjectCardLaundry.lua`, plateState: two new states, after `st.hasItems`:
  `st.waterLoad = st.hasItems and w or 0` and `st.waterBare = (not st.hasItems) and w or 0`.
  Why: seen from above, the washer's water fills *around* the clothes, so its water pictures depend on the load too.
  `washer*_soak1..5` draw when waterLoad == n (water + clothes, over the clothes picture); `washer*_water1..5` when
  waterBare == n (the empty tub). The washer-dryer keeps `water` as before (`washer_dryer*_water1..5`).
- `42/media/textures/ZeD/physpx/`: the laundry pictures redrawn (M) and the new water / soak pictures (??), 105 in all.

## Please
1. Commit the files above (only those; check `git status -- 42 ZeDUI/tools/physpx`).
2. In game: check the three machines at a couple of UI scales: empty, clothes in, each water level with and without
   clothes (washer), power off / running lamps, the door/lid click opens the contents.
3. Retake the laundry QA captures and the gallery's laundry spread (59) when convenient.

## Note on the export
`export_rtv.py` rebuilds every machine plate, and the committed oven / generator / grill / ham / walkie / microwave
textures and 6 oven/ham entries in PhysPx.lua are newer than what the tools make today. So this was exported to a
scratch folder and only the laundry files copied in. Running `export_rtv.py` straight into the mod would put older
art back on those plates; worth a look on Code's side (the tools and the committed textures have drifted).
