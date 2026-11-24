# Handoff: Design to Build, the belt row's boxes as the wheels' white blocks (Nov 23 2026)

Nothing in 42/ was touched, and nothing is committed: Build installs, commits and runs the checks. Everything is staged
in `ZeDUI/art/belt_blocks_20261123/`:
- `ZeD_Belt.lua` as Design tested it, and its diff;
- one of QA's sims, fitted, and its diff;
- the mock as passed.

**Made against main at `c11a7d341`, Nov 23 16:30.** That includes the belt's last two commits, `6dcc99689` (the lit
lamp) and `d0bbae90b` (the side tags). Both staged files are main's own copy with this handoff's changes, in main's
working-tree line endings (CRLF). If `git diff c11a7d341 -- <file>` prints nothing for a file, copy the staged one
over it. If it prints anything, apply that file's `.diff` with `git apply --ignore-whitespace`.

## The director's calls

The notes, verbatim:

> (16:00) The icon frames on the belt and other icons on the HUD strip currently just look way too modern and boring.
> We have on the rotary wheels, there are those white block frames. We could do something like that. I think that
> would read better than the current cleanly drawn square and circles.

> (16:54) Everything looks great. Keep B round. Stay round.

16:54 passed B of `preview/belt_blocks_as_passed.png`: every box a white block, the hands kept round. The sheet also
shows the wheels' cells it follows. A, every box square, was not taken.

## What the player sees

On the belt row, Full and Lite, in every theme:

- **Every box is a white block, the D-pad wheels' cell:** paper (`#F2F2F2`), a one-unit ink edge (`#141414`) and
  System 7's hard shadow, one unit right and down in black at half. That covers:
  - the bag button and the hands;
  - the slots, and any box a mod adds (`B.addBox`);
  - the five speed keys, and the speed keys alone above a car's dash;
  - on a server, the chat key and the PvP marker.
- **The hands stay round:** a paper disc, a one-unit ink ring and the same shadow as a disc. The ring used to be two
  units in the theme's frame color. A held item's condition ring is as it was.
- **Ink on the paper:**
  - the empty hands' icons;
  - the speed keys' icons;
  - the chat balloon;
  - the PvP words;
  - an empty slot's name, at 60%.

  Pictures keep their own colors.
- **The accent marks what it marked:**
  - a key's tag;
  - a drop that fits (its wash and its border);
  - an item in hand (the dashed edge);
  - the PvP zone's double line.

  **The speed in use is the wheel's pointed cell:** the accent fill with its bright edge, the icon in the accent's
  text color.
- **The R side tag, a white box, gets an ink edge** so it shows on the paper. The L tag, a black box, is as it was.
- **A box that won't take the dragged item goes grey** under an ink wash at 0.45. It was the theme's base at 0.6.
- **The row is the same in every theme.** The boxes no longer take `T.surf1` / `T.surf2`. So the busy and empty fills
  are one paper: a box's picture says it's busy.
- **Unchanged:**
  - the strap and the buckle, the wrist watch and the ammo tab;
  - the lamps, the slots' condition strips and the hands' condition rings;
  - the hover wash (the accent at 15 to 22%) and the controller's marks;
  - the hint balloons and the item card.

## How it draws

All of it is in `ZeD_Belt.lua`:

- **WHITE BLOCKS,** beside the side tags' inks, quotes both calls. It sets `PAPER`, `INK`, `INK_DIM`, `SHADOW` and
  `NO_A`, and `B.PAPER` and `B.INK` export the paper and the ink.
- **`blockShadow()`** draws `ZeD.Atoms.drawHardShadow` under a square box, or the disc one unit right and down under a
  hand.
- **`inkEdge()`** draws the one-unit edge as `T.hair` nested one-pixel borders, as `frameBox` drew its lines. The belt
  draws every frame, so that is one Java call a pixel of width where `ZeD.Atoms.frame` makes four.
- **What uses them:**
  - `_drawBox` (slots, hands, mods' boxes): the shadow, then the paper, then the ink edge.
  - `_drawButton` (the bag, the speed keys), `_drawChat` and `_drawPvp`: the same.
- **`frameBox` and `B.frameBox` stay** for anything else that asks for them. `condRing` is untouched: its well sits
  three units in, as before, so a two-unit band of paper shows between the ink ring and the condition ring.
- **The draw cost:** about 30 more draw calls a frame at 4K and about 20 at 1x, on a belt with five slots. Each box's
  shadow is two rectangles, and each hand's is one picture. The edges cost what the old frames did, but a key's edge
  costs one more call at 4K.

## Build's work

1. **The Lua:**

       Copy-Item ZeDUI\art\belt_blocks_20261123\lua\ZeD_Belt.lua 42\media\lua\client\ZeD\ -Force

   Or apply `lua/ZeD_Belt.lua.diff`, as the note at the top says.

2. **QA's sim, `belt_mods_sim.lua`.** The fitted copy is in `ZeDUI/art/belt_blocks_20261123/qa/`, with its diff.

       Copy-Item ZeDUI\art\belt_blocks_20261123\qa\belt_mods_sim.lua ZeDUI\tools\qa\ -Force

   - **Why it needs the fit:** its SAME runs compare the belt, no mod on, with the belt at `2bb40b79`. Each look
     changed on purpose since then is put back before the compare: the bag button, the speed keys, the side marks.
   - **The fit puts the white blocks back the same way:** five pieces of `_drawBox` (the paper and its shadow, the two
     inks, the ring, the edge). It checks that all five were found, so it has one check more: 244.
   - **The SAME belts** have no bag, speed keys, chat key, PvP marker, drag or side mark, so nothing else needs putting
     back.

3. **Run the checks.** Design ran QA's sims with lua51 on two copies of main at `c11a7d341`: main's own, and the same
   with the staged Lua and the fitted sim.
   - The copies held `42/media/lua`, `ZeDUI/tools/qa`, `ZeDUI/i18n` and `ZeDUI/PUNCH_LIST.md`.
   - **All 32 pass on both copies,** with the same counts but one: the fitted `belt_mods_sim` has one check more (244,
     main's own 243). They are the 21 the last handoffs ran:
     `figure_frame_sim`, `trade_medic_sim`, `woundsov_sim`, `perf_throttles_sim`, `tab_search_sim`, `fix_tabfill_sim`,
     `drawer_tabs_perf_sim`, `gc_qa_cleanup_sim`, `strain_tint_sim`, `status_colors_sim`, `hint_strip_cover_sim`,
     `b8r3_sim`, `chip_dot_sim`, `director_review_fixes_sim`, `fix_shared_misc_sim`, `g4_character_tabs_sim`,
     `item_meter_sim`, `rows178_sim`, `tab_fill_sim`, `card_title_fit_sim`, `object_card_fill_sim`.

     And eleven that touch the belt or the desk: `belt_ring_sim` 310, `belt_keys_dash_sim` 18, `belt_mods_sim` 244,
     `belt_watch_pad_sim` 65, `b9a_sim` 28, `grid_layout_sim` 184, `everyday_leftovers_sim` 193, `known_issues_sim`
     167, `kiss_k3_pad_sim` 41, `vskdash_sim` 404, `desk_sim` 199.
   - **`belt_mods_sim` without its fit** fails eight checks, its "SAME draws" in four scenarios, Full and Simple. That
     is the white blocks, and the fit is for exactly that. The fitted sim against main's Lua fails one check: "the white
     blocks found to put back", since main has none.
   - **No in-game script checks the boxes' colors.**
     - `bl_side.lua` finds the side tags by their height and place, and checks their fills. The R tag's new ink edge is
       one hairline tall or wide, so it doesn't take the tag's place in that search.
     - The `zedqa_*` belt scripts take pictures for review.

4. **After it ships,** Design updates the Design System's belt card: the white blocks, the hands round.

## QA

Run these at 4K with UI scale 1.75 (window layout reset first) and on the Steam Deck (1x), in Dark, Light and High
contrast, with an accent change. Open a D-pad wheel beside the belt to compare.

### The blocks

- [ ] Every box on the row looks like the wheel's cells: paper, a thin ink edge, the hard shadow at the right and the
      bottom. That is the bag, the slots, the speed keys and, Full and Lite, a mod's box.
- [ ] The hands are round: a paper disc with an ink ring and a round shadow. Empty, each shows its hand icon in ink.
      Holding something, each shows its picture and condition ring.
- [ ] One item in both hands: the off hand peeks from under the main hand, and the main hand's shadow falls on it.
- [ ] A gun in hand: the ammo tab comes out from under the main hand, looking as it did.
- [ ] Slots: the key tag in the accent; L a black tag, R a white tag with an ink edge; the condition strip; a lit
      flashlight's lamp.
- [ ] An empty slot's name reads in dim ink.
- [ ] The speed in use is the accent with a bright edge. The other keys' icons are ink.

### Use

- [ ] The pointer's hover wash shows on the paper. The controller's mark shows in each style: hand, corners, wash and
      ants.
- [ ] Drag an item over the belt: the boxes that take it light in the accent, the others go grey.
- [ ] In a car: the speed keys alone above the dash are blocks.
- [ ] On a server: the chat key and the PvP marker are blocks, and the PvP zone shows its accent double line.
- [ ] Mask Filter Indicator, or another mod that adds a box: its box is a block too.

## Files

| What | Where |
|---|---|
| The Lua as tested, and its diff | `ZeDUI/art/belt_blocks_20261123/lua/ZeD_Belt.lua` (`.diff` beside it) |
| QA's sim, fitted, and its diff | `ZeDUI/art/belt_blocks_20261123/qa/belt_mods_sim.lua` (`.diff` beside it) |
| The mock as passed (B taken) | `ZeDUI/art/belt_blocks_20261123/preview/belt_blocks_as_passed.png` |
