# Handoff: plates that fill the card at every scale (Oct 30 2026)

Design → Code. Answers `REQUEST_design_plates_fill_20261030.md`. Director's brief: each plate fills its card at every
UI scale the way text and buttons do; keep the whole-zoom rule, today's level of detail and the 200 px narrow faces.

## What's in this commit

Design's files only. Nothing under `42/` is touched; the export below writes there, and that run is yours.

| File | What |
|---|---|
| `tools/physpx/w_ovens.py` | the six ranges and the fryer, parametric in `W` |
| `tools/physpx/w_more.py` | both microwaves, the four generators, the grill, parametric in `W` |
| `tools/physpx/w_ham.py` | the three ham sets, parametric in `W` |
| `tools/physpx/w_walkie.py` | the six walkies and the ManPack, parametric in `W` (the half card's PANEL width; face = W − 20) |
| `tools/physpx/w_plates.py` | `WIDE[pid]`, `widths(pid)` → (today's width, the widths the game picks from) |
| `tools/physpx/w_check.py` | the proof: 0 px difference from today's face at today's width; same click areas and parts at every width |
| `tools/physpx/w_sheet.py` | the review sheets (a face in a stand-in card at each UI scale) |
| `tools/physpx/export_fill.py` | the export: everything `export_336.py` does, plus every extra width and the `widths` table |
| `mockups/plates_fill/fill_at_1.75.png` | every face in its card at 1.75 |
| `mockups/plates_fill/fill_scales.png` | five faces across 0.75 … 2.0 |

## The widths

Full card (17 machine plates): plate room 450 units, zoom = UI scale rounded to whole (1x below 1.5, 2x from 1.5,
3x from 2.5, 4x from 3.5). Half card (walkies): 206 units after the scrollbar.

| Machine plate width | Fills at UI scale | | Walkie panel width (face) | Fills at UI scale |
|---|---|---|---|---|
| 336 (today) | 0.75, 1.5 | | 154 (134) | 0.75, 1.5 |
| 392 | 1.75 | | 180 (160) | 1.75 |
| 450 | 1.0, 2.0, 3.0, 4.0 | | 206 (186) | 1.0, 2.0 |
| 562 | 1.25 | | 257 (237) | 1.25 |

Today's 220 walkie panel stays the reference the parametric faces are checked against; it is not in the pick table
(it never fit the half card, which is why the tab rounds up to the full card today).

## Export

```
cd ZeDUI/tools/physpx
python export_fill.py <mod root>        # the folder that holds 42/
```

Writes, on top of today's export and the `narrow` table:

- textures `42/media/textures/ZeD/physpx/<pid>@<W>.png` and `<pid>@<W>_<state>.png` (79 extra faces, 260 textures in all)
- `PhysPx.lua`: each `<pid>@<W>` is a full entry in `plates` (`w`, `h`, `parts`, `hits`, plus `base = "<pid>"` and
  `fill = <W>`), and a new table

```lua
widths = {
  oven_green = { [336] = "oven_green", [392] = "oven_green@392", [450] = "oven_green@450", [562] = "oven_green@562" },
  walkie_toy = { [154] = "walkie_toy@154", [180] = "walkie_toy@180", [206] = "walkie_toy@206", [257] = "walkie_toy@257" },
  ...
}
```

The key is the number from the tables above: the plate's own width for machines, the panel width for walkies (the
texture is 20 px narrower). PhysPx.lua grows from 118 KB to 276 KB; it loads in a stock Lua 5.4 runtime (checked).
`@` in a texture path is fine on disk; if `getTexture` dislikes it, say so and I'll switch the separator — one line in
`export_fill.py`.

## The pick

Where today's code resolves a plate id (StationAppliance ~524, ObjectCardPower ~243, ObjectCardFire ~431 per the 336
handoff; the radio tab for walkies), after `narrow`:

```lua
-- room: the card's plate room in screen px (full card: width minus its margins; half card: minus the scrollbar too)
-- zoom: the plates' whole zoom at the current UI scale
local function pickWidth(pid, roomPx, zoom)
    local t = ZeD.PhysPx.widths[pid]
    if not t then return pid end
    local best, bestW = nil, -1
    for w, key in pairs(t) do
        if w * zoom <= roomPx and w > bestW then best, bestW = key, w end
    end
    return best or pid            -- nothing fits: today's face, and the existing narrow rule takes it from there
end
```

For walkies compare the PANEL width (the key) against the half card's room; draw the face centred with 10 px margins
as today. The narrow (200 px) faces are unchanged and still the answer when even 336 × zoom does not fit.

Nothing else changes: the plate template reads `w`, `h`, `parts`, `hits` off the picked entry exactly as it does for
today's plates; the click ids, kinds and `needs` are identical across widths (w_check enforces that), so the handlers
keyed by hit id need no change.

## QA (the QA session's checks)

1. At each UI scale 0.75, 1.0, 1.25, 1.5, 1.75, 2.0 (fullscreen 4K, and 1080p), open a range, a generator, a microwave,
   the grill, a ham set and a walkie: the face fills the card's plate room with the small margin and nothing else; no
   half pixels (zoom is whole), no blur.
2. Every click area still works at every width (the hit rects are per entry, so a wrong entry shows up at once).
3. Live parts (lamps, bars, displays) light in the right place at each width.
4. Auto scale on 1280×720 / 1280×800 with the smallest font still gets the 200 px narrow faces.
5. Memory: 136 extra textures; check load time and texture memory on the 4K machine once.

## Design notes for the director (flagged in chat, not blocking)

- Walkie 154 panel (134 px face): the key pads scale with the face so three still fit; the readout's side margins
  pull in to keep its layout. Knobs, lamps, screws and the talk switch keep their size. The one place the "controls
  don't shrink" rule bends.
- Grey and modern ranges at 562: a fixed keypad in a wide glass; empty field either side. Not filled with invention;
  the director may want a wider display window on those two.
- The makeshift ham's character display gets more cells on wider boards (30 at 562), as a longer module would.
