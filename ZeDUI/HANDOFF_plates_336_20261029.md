# Handoff: machine plates at 336 px, their 200 px narrow faces, the game's own brands (design, Oct 29 2026)

For Code. Design is done and approved by the director. Everything is drawn, exported and proven against the game's
own Lua. What's left is plugging it in, three small Lua changes, and an in-game look. Nothing in the repo was edited
by the design session; this folder is the whole change.

Spec: `ZeDUI/PLATE_SIZES_SPEC.md`. Review page: `ZeDUI/mockups/zed_plates_336_v1.html` (today / 336 / 200 narrow,
the fit at each UI scale). Notes on every design call: `ZeDUI/mockups/zed_plates_336_v1/README.md`.

## What changed

- **17 machine plates re-laid to the 336 px main face:** the six ranges, the fryer, both microwaves, the four
  generators, the grill, the three ham sets. Same click area ids, kinds and needs, and the same live parts as today,
  except the three listed under "Behaviour changes".
- **17 narrow faces at 200 px** (`<plate>_n`), for the smallest settings only. Each has exactly its main face's click
  areas and live parts. The three ham narrow faces already existed and are updated.
- **The game's own brands** (director: real brands from the game only, watches excepted). Four have logo art in the
  game and are redrawn from it as pixel badges (`m_brands.py`): Mass-Genfac Co., Lectromax, Knox Pack Kitchens,
  ValuTech.

  | Plate | Was | Now |
  |---|---|---|
  | Green range | Hollister Custom | Mass-Genfac Co. |
  | Red range | Meridian | CGE |
  | Grey range | Lectromax (text) | Lectromax badge |
  | Industrial range, large oven | Ironclad, Convectron | Knox Pack Kitchens |
  | Chrome microwave | Tempo | Premium Technologies |
  | Red / yellow / blue generator | Mass Genfac / Knox Power / Sundowner | Lectromax / Premium Technologies / ValuTech (the items' own names) |
  | Grill | Jorge Foreguy | Hector Lopez (the name players see; Jorge Foreguy is only the internal key) |

- **Other director calls folded in:** the red range's maker sits under its SIGNAL lamp; the chrome microwave is now
  the fancy 1988 glass-touch model; the ham sets' tuning knobs turn a clear cursor disc; the makeshift ham has
  hand-drilled speaker holes and red embossing-tape labels.

## The files

```
tools/physpx/          drop into ZeDUI/tools/physpx (all new files, nothing replaced)
  m_brands.py          the four logo badges, from the game's art
  m_ovens.py           ranges and fryer, 336
  m_more.py            microwaves, generators, grill, 336 (the microwaves take narrow=True too)
  m_ham.py             ham sets, 336; cursor_disc, drilled_grille, dymo
  m_narrow.py          all 17 narrow faces
  plates_336.py        lays all of the above over plates.py's registry without editing it; NARROW table
  export_336.py        export_phys.py + the `narrow` table in PhysPx.lua
  platesame_336.py     platesame.py over the 34 changed plates
  mock_sheet.py, mock_check.py, mock_narrow.py   the design session's own checks (optional)
prebuilt/42/...        the export's output: PhysPx.lua (all plates) + the 71 new or changed textures
```

## Plug-in steps

1. Copy `tools/physpx/*` into `ZeDUI/tools/physpx/`.
2. Regenerate from the repo, so the export uses whatever the engine is now:
   `python export_336.py <repo root>` (writes `42/media/textures/ZeD/physpx/` and `42/media/lua/client/ZeD/PhysPx.lua`).
   The `prebuilt/` folder holds the same output. It's only safe to copy it straight in if `tools/physpx`,
   `tools/dashpx` and the plate Lua haven't changed since **Oct 30 03:21 UTC** (the snapshot it was built from).
3. `python platesame_336.py`: expect **348 pictures, 0 different** (34 plates, every preview state, 1x and 2x).
4. The Lua changes below.
5. In game: one oven, microwave, generator and grill each at UI scale 1.75 (the director's), then at 0.5 to see the
   narrow faces. Reset the window layout (R) first.

## Lua changes (three places)

**a. Pick the narrow face.** `PhysPx.narrow[pid]` names each machine plate's narrow face. The rule is the one the
radio tab already uses for the ham sets (`RadioTab.lua` ~1286): draw the narrow face when the main face at the
plates' whole zoom is wider than the room.

```lua
-- ZeD_Plate.lua (or PixelParts): the face to draw in `availW` screen px
function PL.pick(pid, availW)
    local X = ZeD.PhysPx
    local des = X and X.plates[pid]
    if not des then return nil, pid end
    local Sc = ZeD.Scale
    local k0 = P.k((Sc and Sc.root and Sc.root()) or 1)
    local nid = X.narrow and X.narrow[pid]
    if nid and X.plates[nid] and des.w * k0 > availW then return X.plates[nid], nid end
    return des, pid
end
```

Call it where each card works out its zoom from the room it has, just before `P.kFit`:
- `StationAppliance.lua` ~524 (ovens, microwaves, fryer; room `w - T.sp.scrollbarW`)
- `ObjectCardPower.lua` ~243 (generators)
- `ObjectCardFire.lua` ~431 (grill)

The ham sets keep `twoway.narrow` (still exported) and `RadioTab` needs no change.

**b. Narrow ids route like their main plate.** `StationAppliance.SA.press` (~351) and `isOvenPlate` (~118) compare
plate ids, so `oven_grey_n`, `oven_modern_n`, `mw_white_n` and `fryer_n` would miss. Compare the base id:

```lua
local function baseOf(pid) return (pid:gsub("_n$", "")) end
```

**c. The chrome microwave uses the white one's keypad.** Its dials and START bar are gone. It has the white
microwave's exact click areas (power, timecook, d0-d9, stop, start, all presses) and the same live parts (mwText,
mwPower bars, cooking). The state already fills those for every microwave (~380). Route it:

```lua
local b = baseOf(pid)
if b == "mw_white" or b == "mw_chrome" then return mwWhitePress(player, st, r, p, id) end
```

## Behaviour changes to know about

- **Chrome microwave:** the controls are now the white microwave's keypad, as above. `power`/`timer` are presses,
  not turns; `timerF60` and `mwPowerIdx` are no longer read by this plate.
- **Ham sets' tuning knobs (civilian, army; wide and narrow):** the knob's pointer now reads `bandF` over the arc's
  sweep (-205 to 25 degrees) instead of `tuneF` over a free 360, so the knob and the hairline on its clear disc
  always agree. `bandF` is already supplied (it drove the old marker), so there's no Lua change; `tuneF` is simply
  no longer read by these plates.
- **Plate titles in PhysPx:** chrome microwave "1988", grill "Hector Lopez", generators name their makers.

## Checks run

- Every 336 face: 336 wide; click areas and live parts identical to today's (except the two above); click areas
  of at least 10 x 10 px; no new live part at the edge; no placement warnings (the export refuses any).
- Every narrow face: 200 wide; click areas and live parts identical to its 336 face; same rules.
- Exporting the untouched registry with the snapshot reproduces the repo's PhysPx.lua byte for byte. In the new
  export, every non-machine texture (watches, car radios, walkies, siren) is identical to today's.
- `platesame_336.py`: 348/348.

## Folding it in later

When convenient, move the functions into `d_ovens.py` / `d_micro.py` / `d_gen.py` / `d_grill.py` / `d_walkie.py`,
register them and the narrow faces in `plates.py`, add the `narrow` table to `export_phys.py`, then delete the
`m_*.py`, `plates_336.py`, `export_336.py` and `platesame_336.py` overlay.
