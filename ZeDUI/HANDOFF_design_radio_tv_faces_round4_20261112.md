# Handoff: radio and TV faces, round 4 (Nov 12 2026)

From design, for Build. The director redrew four faces against the game's own models and approved them ("Radio and TV
faces have been approved, are approved, and now have been approved."). The other TVs, the ham sets and the CD player
are untouched ("Leave the other TVs alone ... Leave the ham radios alone.").

## What changed

| Plate | Change |
|---|---|
| `radio_black` (Base.RadioBlack) | Black case, grey face, one big louvred grille on the left, amber screen, PWR and MUTE keys, one big black knob, presets under the grille, volume keys under the screen, an aerial. **The analog tuning scale is gone** ("just get rid of the analog dial. Leave the digital screen"); the grey face sits high and the black band is at the foot. |
| `radio_red` (Base.RadioRed) | A rounder shell; round chrome-ringed speaker(s) on the left (two at 257, one below); screen, keys and knob on the right; the CD drawer the width of the top; eject beside play; an aerial. |
| `radio_handbuilt` (Base.RadioMakeShift) | **At 257 only:** a wider, two-rows-deeper board; a large cone speaker bottom left on the LM386's output (taped AMP, SPKR 8R); two C cells in a holder above it, printed SPIFFO CELL (brown jacket, orange band, yellow letters), which are the set's battery there (the three AA cells are gone from this width). 180 and 206 are as before. |
| `tv_antique`, `tv_antique_n` (Base.TvAntique) | The control side is black inside a chrome frame; brushed silver plate behind a black channel dial; silver speaker slats; white lettering. |

## What Build must allow for

1. **Height.** `radio_black` and `radio_red` are 146 px tall at every width (were 132): 14 px of aerial above the case.
   `radio_handbuilt@257` is 202 px tall (was 190).
2. **A part removed.** `radio_black` no longer has the `needle` part (src `freqF`). Its tune knob's `ptr` (src `tuneF`)
   and every control id are unchanged.
3. **Ids.** No click area or live part was renamed on any of the four. On `radio_handbuilt@257` the `battery` click
   area moved to the C-cell holder (top left, above the speaker) and is larger; `phones` and the rest are where they were.
4. **The makeshift's big speaker exists at 257 only** (it needs a 230 px face). The director was asked twice whether
   the makeshift should move to a wider or full card and has not ruled; shipped as is, the narrower panels show the
   small speaker and the AA cells. Raise it with him if the mismatch between widths bothers anyone in play.

## Files

- `ZeDUI/tools/physpx/d_rtv.py`, `d_rtv_make.py`: the edited designs (in place).
- `ZeDUI/art/rtv_faces_r4/rtv_plates_changed.zip`: the 19 changed plate pictures from `export_rtv.py` (default folder,
  not `--into-mod`), under `textures/ZeD/physpx/`. Copy only these; the tools are older than some committed art.
- `ZeDUI/art/rtv_faces_r4/PhysPx.generated.lua`: that export's whole table, for reference. Take from it only the
  entries for `radio_black`, `radio_red`, `radio_handbuilt` and `tv_antique` (all widths and `_n`); do not replace the
  mod's file with it.
- `ZeDUI/art/rtv_faces_r4/radios_before_after.png`, `makeshift_antique_before_after.png`: review sheets.

## Checked, and not

- Checked: all four draw with no plate warnings at every width they ship at (154/180/206/257; the makeshift at
  180/206/257; the TV at 200/336/392/450/562). The makeshift's board passes its net and paint checks. The export ran clean.
- Not checked: `platesame` (no Lua here), anything in game, the card layout with the taller radios, the antique TV's
  off-air screens (its screen rect was not changed, so they should still fit; confirm).
- Nothing is in `42/`. Wait for QA to be clear before writing there.
