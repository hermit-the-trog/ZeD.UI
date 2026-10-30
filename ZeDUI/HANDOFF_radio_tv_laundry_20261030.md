# Handoff: radios, CD player, TVs and the laundry machines (Oct 30 2026)

Design → Code. Answers `REQUEST_design_radio_tv_faces_20261030.md`, and adds the washer, the dryer and the
washer-dryer (director, Oct 30: "Washer and dryer I trust you. Do those so we can ship that too.").

> **Status: waiting on the director's sign-off.** The spec sheets below are what he signs. Build from this once he
> hands it over; if he changes a face, Design re-exports and this note says so.

## What's in this commit

Design's files only. Nothing under `42/` is touched; the export below writes there, and that run is yours.

| File | What |
|---|---|
| `tools/physpx/d_rtv.py` | the two radios, the CD player, the three TVs (and the TVs' narrow faces), parametric in `W` |
| `tools/physpx/d_rtv_make.py` | the makeshift radio as a hand-wired board (every wire routed and checked against the circuit) |
| `tools/physpx/d_laundry.py` | the washer, the dryer, the washer-dryer, parametric in `W` (W < 300 is the narrow face) |
| `tools/physpx/rtv_plates.py` | registers all ten over the plate registry and the fill tables; `ITEMS`, `CLASSES` |
| `tools/physpx/export_rtv.py` | the export: everything `export_fill.py` does, plus these faces, the off-air screens and three tables |
| `tools/physpx/rtv_check.py` | the proof: every width and narrow face builds clean, with the base face's click areas and live parts |
| `tools/physpx/spec_sheet.py`, `rtv_widths.py`, `laundry_sheet.py` | the sheets |
| `mockups/zed_radio_tv_v1/spec/spec_<pid>.png` | **one spec sheet per device**: at play scale, every click area and live part, every width, the notes |
| `mockups/zed_radio_tv_v1/rtv_widths.png`, `mockups/zed_laundry_v1/*.png` | all faces at all widths; the laundry states |

## The faces

| Plate | Picked by | Card | Widths (key) | Narrow |
|---|---|---|---|---|
| `radio_black` | item `Base.RadioBlack` | half | panel 154, 180, 206, 257 (180 is the base face) | |
| `radio_red` | item `Base.RadioRed` | half | panel 154, 180, 206, 257 | |
| `radio_handbuilt` | item `Base.RadioMakeShift` | half | panel 180, 206, 257 | |
| `cd_player` | item `Base.CDplayer` | half | panel 154, 180, 206, 257 | |
| `tv_widescreen` | item `Base.TvWideScreen` | full | plate 336, 392, 450, 562 (336 is the base face) | `tv_widescreen_n` |
| `tv_black` | item `Base.TvBlack` | full | 336, 392, 450, 562 | `tv_black_n` |
| `tv_antique` | item `Base.TvAntique` | full | 336, 392, 450, 562 | `tv_antique_n` |
| `washer` | class `IsoClothingWasher` | full | 336, 392, 450, 562 | `washer_n` |
| `dryer` | class `IsoClothingDryer` | full | 336, 392, 450, 562 | `dryer_n` |
| `washer_dryer` | class `IsoCombinationWasherDryer` | full | 336, 392, 450, 562 | `washer_dryer_n` |

The car makeshift radio keeps `radio_makeshift`; the portable one is the new `radio_handbuilt`. Its circuit needs a
160 px board, so there is **no 154 face**: at UI scale 0.75 and 1.5 its card falls back the way the walkies did before
the fill work (the full card). Radios and TVs placed in houses use the same faces: pick by the item the object turns
into when picked up (request, director Oct 30).

## Export

```
cd ZeDUI/tools/physpx
python export_rtv.py <mod root>        # instead of export_fill.py: it runs that first, then adds these
python rtv_check.py                    # optional: "all faces agree"
```

Writes on top of `export_fill.py`'s output (548 textures in all; PhysPx.lua about 400 KB, loads in a stock Lua):

- the ten faces as plates, their widths in `widths` and their narrow faces in `narrow`, exactly like the machine
  plates and walkies (`<pid>`, `<pid>@<W>`, `<pid>_n`, each with its state sprites)
- `rtv = { items = { ["Base.RadioBlack"] = "radio_black", ... } }`
- `laundry = { classes = { IsoClothingWasher = "washer", IsoClothingDryer = "dryer", IsoCombinationWasherDryer = "washer_dryer" } }`
- `offair = { channels = {...}, screens = {...}, logos = {...}, sets = { ["tv_black@392"] = "offair/tv_black@392/", ... } }`
  and the textures `<texdir>offair/<plate>/<screen>.png`, one set per TV face at that face's screen size, corners
  already cut, the antique set's in black and white. Draw the one you want over the `tvScreen` rect as it is.

The pick is the fill handoff's `pickWidth(pid, roomPx, zoom)`; the half card's key is the panel width (the face is 20 px
narrower), the full card's the plate width. The narrow rule is unchanged.

## Wiring

Every face at every width has the same click areas and live parts (`rtv_check.py`), so one set of wiring serves all
of a device's faces. Click areas carry `kind = "turn"` where they are knobs; `needs = "powered"` where the game refuses
without power.

**Radios and the CD player** (`ZeD_RadioOps`, as the car radio and the walkies):

| Click area | Does |
|---|---|
| `power`, `mute`, `voldn` / `volup` | as today (`vol` is a turned knob on `radio_handbuilt`) |
| `tune` (turn) | the frequency; feeds `tuneF` back, and `freqF` (88-108 as 0..1) for the ValuTech's dial needle |
| `p1`..`p4` | press: tune to the preset; hold: store |
| `phones` | headphones in / out (`phonesIn`) |
| `battery` | batteries in / out. On the CD player this is the battery meter on its screen (director: "clicking the meter on the screen or right click in the inventory can change the battery") |
| `slot`, `eject`, `play` | the CD (red radio, CD player): insert, eject, play / stop. On the CD player `slot` is the lid and `eject` the OPEN lip |

Live: `radioOn`, `batt` 0..4, `phonesIn`, `hasMedia`, `switchOn` (the hand-built radio's rocker sprite),
`display` per its layout (in the plate data: `fm`, `port`, `makeshift2`, `disc`).

**TVs**:

| Click area | Does |
|---|---|
| `power`, `mute`, `voldn` / `volup`, `phones` | as the radios. The antique set's `power` and `vol` share the volume knob: press is pull on / push off, turn is the volume (`volF`) |
| `chdn` / `chup` | channel down / up |
| `channel` (turn, antique) | twelve stops printed 2 to 13; stops 0..9 are the game's ten channels in frequency order (`offair.channels`), 10 and 11 tune nothing. `chIdx` 0..11 back |
| `slot`, `eject`, `play` | the video tape (widescreen, black): insert, eject, play / stop |

Live: `radioOn` (green), `noPower` (red: no grid or generator), `phonesIn`, `hasMedia`, the tape counter
`display = { counter = "h:mm:ss", playing = bool }`, the channel `display = { ch = "08" }`, and the signal light: one of
`sigBad` (signal 1), `sigFair` (2), `sigGood` (3 and up), none for 0.

**The screen** (`tvScreen`): the picture is yours (the broadcast's lines, as today). Design's suggestion for the
off-air screens, yours to fit to what the game knows:

| Screen | When |
|---|---|
| `snow_0..2` (cycle them, about 8 a second) | no signal, or between channels |
| `bars` | a channel number with no station on it |
| `signoff_<channel>` | the station exists but has nothing on air right now |
| `standby` | the station is gone for good (the broadcasts the game ends) |

Triple-N and TURBO leave a box on their sign-off card for the game's own logo: draw `offair.logos[id].file` (from the
game's files, nothing copied) fitted into `box` (fractions of the screen: x, y, w, h), keeping its shape, multiplied
by `tint`. On the antique set multiply by its tube tint (`#a8c0a0`) instead; it will read tinted rather than grey.

**Laundry** (vanilla's own handlers and actions; the plates replace only the picture):

| Click area | Does |
|---|---|
| `power` | the toggle: `ISToggleClothingWasher` / `ISToggleClothingDryer` / `ISToggleComboWasherDryer` after `luautils.walkAdj`, as vanilla's loot-window handlers do. `needs = "powered"`; the washer (and the washer-dryer in washer mode) also needs water, as vanilla checks |
| `mode_wash` / `mode_dry` (washer-dryer) | `ISWorldObjectContextMenu.onSetComboWasherDryerMode(player, object, "washer" / "dryer")` when it is not already that mode. `needs = "powered"` |
| `door` | open the machine's container (its contents) |

Live: `running` (`isActivated`), `noPower` (`not getContainer():isPowered()`), `water` 0..5 (fluid against capacity;
it fills both the meter and the drum), `noWater` (washer mode with no fluid: FILL), `hasItems` (anything inside: the
clothes sprite), `modeWash` / `modeDry` (`isModeWasher`). The rest is the clock's, not the game's (it has no phases):
while running, step the phase lamps (`phWash` → `phRinse` → `phSpin` on the washer, `phDry` → `phCool` on the dryer,
the washer-dryer's by its mode; a few game minutes each, round again), move `cycleF` 0 → 1 with them, and turn `drumF`
(about one turn in two seconds). Stopped: all phase lamps dark, `cycleF` back to 0.

## Where they open

Radios, the CD player and TVs: the radio tab's card (half card for the radios, full for the TVs), in place of the
generic box. The laundry machines: the full card a machine plate uses (as the stove's), wherever Code shows a
machine's controls today (the loot window's object controls open it); Code's call.

## Checked

`rtv_check.py`: all ten faces agree at every width and narrow face, no placement warnings, no overlapping click areas.
The export runs clean and PhysPx.lua loads in a Lua runtime and reads back (`widths.radio_black`, `narrow.washer`,
`rtv.items`, `laundry.classes`, `offair.sets`).
