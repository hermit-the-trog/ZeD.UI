# Handoff: full-card faces for the radios and the CD player (Nov 13 2026)

From Build, for design. The director's ruling, Nov 13 2026: "If it's a half card, it always loads a half card stereo. If
it's a full card, it can only load a full card stereo. It cannot load a half card stereo" in a full card. "I don't want
to see a small radio with a bunch of blank space on the left and the right side." Asked whether a placed radio should
open in the half card or get full-card faces, the director chose **design draws full faces**.

## The gap

A radio in your hand opens in the half card and its face fills it (widths 154 / 180 / 206 / 257, keyed by the half
card's panel width). A radio **placed in the world** opens in the World window's **full card** (480 units; 840 px at 4K
and 1.75), where the widest radio face, `radio_red@257` (237 px of art), sits centred with about 250 px blank either
side at 4K (QA, `Screenshots/zqa_rtv_4a_radio_red_placed.png`). The TVs, ovens, generators, microwaves and ham sets
already have full-card faces at 336 / 392 / 450 / 562; the radios and the CD player do not.

## What to draw

Full-card faces, each at the four machine widths **336, 392, 450, 562** (the face's own width, as the TVs and the ham
sets are keyed), for:

| Plate | Item |
|---|---|
| `radio_black` | Base.RadioBlack (the round 4 face: no analog dial, the aerial) |
| `radio_red` | Base.RadioRed (round 4: the rounder shell, round speakers, the CD drawer) |
| `radio_handbuilt` | Base.RadioMakeShift (round 4: at full width the large speaker and the Spiffo C cells fit at every size) |
| `cd_player` | Base.CDplayer |

Keep every control id and live part id the same as the half-card faces (power, tune, volume, presets, mute, seek,
scan, eject, play, the battery and phones areas), so the card's code and the pad's stops work unchanged. Height is
yours: the card scrolls as one unit; the ham sets and TVs are the reference for proportion at these widths.

## What Build does with them

Export into `42/media/textures/ZeD/physpx/` and the plate table as `radio_black@336` ... `@562` (and the others), and
add the four keys to each set's `PhysPx.widths` entry. `P.pickWidth` already takes the widest face that fits the card,
so a placed radio then fills the full card and an in-hand one keeps its half-card face. QA's `zedqa_rtv` now fails a
placed set whose face leaves more than about 20 px either side, so it shows when the faces are in.
