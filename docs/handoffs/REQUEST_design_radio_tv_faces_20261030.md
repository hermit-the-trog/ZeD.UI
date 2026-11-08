# For Design: faces for the ordinary radios, the CD player and the TVs (director, Oct 30 2026)

The radio tab draws these as one generic box today. Each gets its own face, like the walkie-talkies and ham sets
(`HANDOFF_twoway_20261025.md`). Same pipeline: PNGs plus the parts and click areas through `tools/physpx`.
Widths follow `REQUEST_design_plates_fill_20261030.md`: every face comes at the widths that fill its card.

## The devices (game items, `media/scripts/generated/items/radio.txt`)

| Device | Item | Card | Notes from the game |
|---|---|---|---|
| Black radio | `RadioBlack` | half | portable, battery |
| Red radio | `RadioRed` | half | portable, battery, plays CDs |
| Makeshift radio | `RadioMakeShift` | half | portable, battery; hand-built, like the makeshift walkie and ham set |
| CD player | `CDplayer` | half | portable, battery, plays CDs, no tuner |
| Old wooden TV | `TvAntique` | full | mains power (grid or generator) |
| Black TV | `TvBlack` | full | mains power, plays video tapes |
| Widescreen TV | `TvWideScreen` | full | mains power, plays video tapes |

**Radios and TVs found in houses use these same faces** (director, Oct 30): the game picks the face by the model
the object turns into when picked up.

## Widths (director, Oct 30: radios and the CD player in the half card, TVs in the full card)

- **Half card** (radios, CD player): panels of **154, 180, 206 and 257 px** (face and its margins), as the walkies.
- **Full card** (TVs): **336, 392, 450 and 562 px**, plus a **200 px narrow face** for the smallest screens.

## The controls each face needs (what the game's radio window offers today)

| Control | Radios | CD player | TVs |
|---|---|---|---|
| Power on/off | yes | yes | yes |
| Battery: level, put in / take out | yes | yes | no (mains; a lamp for "no power") |
| Volume up / down, mute | yes | yes | yes |
| Headphones or earbuds: plug in / out | yes | yes | yes |
| Tuning: frequency readout, tune up / down, presets | yes | no | channel up / down and the channel shown |
| Signal strength | yes | no | yes |
| Media: insert / eject, play / stop, progress | CD on the red radio | CD | video tape on the black and widescreen TVs |
| Screen (picture or static, the station's text) | no | no | yes |

Live parts, as the walkies have them: the power lamp, battery level, frequency or channel readout, volume level,
signal, media state (playing, stopped, empty), and on the TVs the screen.

## Hand back

PNGs, parts and click areas per face and width, named so the export can list them (for example `radio_black@180`,
`tv_widescreen@392`, `tv_widescreen_n`). Code wires the controls to the game, picks the width, and points the house
objects at the same faces.
