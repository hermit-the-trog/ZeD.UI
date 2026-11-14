# Handoff: radio faces, round 5: the full card, and the red radio redrawn (Nov 13 2026)

From design, for Build, answering `HANDOFF_build_full_card_radios_20261113.md`. This replaces round 4's radio pictures (punch list 180,
`HANDOFF_design_radio_tv_faces_round4_20261112.md`); round 4's antique TV is unchanged and still stands.

The director, Nov 13: "we never created full-width stereo face, full card width, not the half card ... let's do it."
Approved after the rounds below ("Thank you. That's good.").

## What changed

**All three radios now have full-card faces** (336, 392, 450, 562) as well as the half card's. From panel width 320 up
each draws its own full layout; the plate ids are the same (`radio_black@336` ...).

| Plate | Half card (154 / 180 / 206 / 257) | Full card (336 / 392 / 450 / 562) |
|---|---|---|
| `radio_black` | As round 4, less the battery door. | The slatted speaker on the left two thirds, the screen, keys, knob and presets on the right. |
| `radio_red` | **Redrawn.** Controls on the left, one D-shaped speaker on the right (flat toward the controls), every button a round chrome push button with its name printed under it, one row along the foot: volume, the four presets, eject, play. | The same set: controls left, the D speaker right, the CD drawer the width of the top. |
| `radio_handbuilt` | Unchanged from round 4 (180 / 206 / 257). | The 180 panel's small display board over the circuit ("Radio Shack parts"), a large speaker on its own red and black leads, the two Spiffo Cells, the whole set in the middle of the board. |

The director's rulings behind it: "The radios only have a speaker on the left side. So the controls take up a little
over a third"; red radio, "I don't like the two round speakers right next to each other ... The controls are on the
left, and the speaker is D-shaped"; "a retro radio inspired by like a 50s radio. So let's make all the buttons round
metal or chrome buttons"; "you can take off the battery lid and just leave the meter there"; the two widest cards,
"just bigger radios in general ... They're not believable"; "keep the buttons grouped together the same ... or make them
bigger to keep up with the scale".

## Sizes (half card: face = panel width - 20; full card: face = the key's width, as the TVs and ham sets are)

| Panel | `radio_black`, `radio_red` | `radio_handbuilt` |
|---|---|---|
| 154, 180, 206, 257 | 146 tall | 190 (180, 206); 202 (257); no 154 |
| 336, 392 | 184 | 202 |
| 450 | 242 | 250 |
| 562 | 298 | 298 |

At 450 and 562 the store radios are the 336 set scaled up (speaker, knob, keys, buttons, the CD drawer, the black
band); the lettering and the screen (24 px tall) are not scaled.

## What Build must allow for

1. **The pick table.** `rtv_plates.py` now gives the three radios the half and the full widths (`BOTH`); the card has
   to ask for the full widths when a radio is on the full card. Whether the radio card can be the full card at all is
   yours to wire.
2. **Heights** above, per width.
3. **Ids.** No click area or live part was renamed. On `radio_red` every control moved (controls are on the left now)
   and the click areas are the round buttons with their captions. `battery` on both store radios is the BATT meter's
   area (the door is gone, the area is where it was). `radio_black` has no `needle` part (round 4).
4. **The red radio's focus order** was not set by hand for the new layout; check the walk on a pad.
5. `radio_handbuilt` at the full widths: `battery` is the C-cell holder; the display is 160 px wide at every full width.

## Files

- `ZeDUI/tools/physpx/d_rtv.py`, `d_rtv_make.py`, `rtv_plates.py`: edited in place.
- `ZeDUI/art/rtv_faces_r5/rtv_radio_plates_r5.zip`: the 30 radio plate pictures from `export_rtv.py` (default folder,
  not `--into-mod`), under `textures/ZeD/physpx/`. They replace round 4's radio pictures. Copy only these.
- `ZeDUI/art/rtv_faces_r5/PhysPx.generated.lua`: that export's table, for reference; take only the `radio_black`,
  `radio_red` and `radio_handbuilt` entries (every width) and the `widths` rows for them.
- `ZeDUI/art/rtv_faces_r5/radios_full_card_all_widths.png`, `radios_half_card_all_widths.png`: review sheets.

## Checked, and not

- Checked: every radio at every width it ships at draws with no plate warnings; the makeshift board passes its net and
  paint checks at 180, 206, 257, 336, 392, 450, 562; the export ran clean.
- Not checked: `platesame` (no Lua here), anything in game, the cards with the new heights, pad focus order.
- Known and left: on the 154 panel the red radio's speaker is a small upright D and its foot row of buttons is tight;
  at 336 the makeshift's speaker is only a little larger than the half card's.
- **`cd_player` gets no full-card face.** The director, Nov 13: "The portable CD player is fine. It was the red radio,
  the black radio, the radios that we just did." So a placed CD player keeps its half-card face; `zedqa_rtv` should
  not fail it for the blank either side.
- Nothing is in `42/`. Wait for QA to be clear before writing there.
