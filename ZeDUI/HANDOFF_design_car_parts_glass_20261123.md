# Handoff: Design to Build, the Vehicle tab's car parts drawn and its glass cracked (Nov 23 2026)

Nothing in 42/ was touched, and nothing is committed: Build installs, commits and runs the checks. Everything is staged
in `ZeDUI/art/car_parts_20261123/`: 620 textures, the new `MechFigs.lua`, two diffs and seven previews. The changed
bake tool and a new check script are installed in `ZeDUI/tools/mechanics/`.

**Made against main at `c11a7d341`, Nov 23 16:30.** Nothing this touches has changed on main since Nov 22: the last
commits under `ZeDUI/tools/mechanics/`, `42/media/textures/ZeD/mech/` or `MechFigs.lua` are `2624e9444` and older.
- **The tool is installed in place.** Its diff is in the stage, against main's own copy.
- **The staged `MechFigs.lua`** is main's own table with this handoff's changes, in main's working-tree line endings
  (CRLF).

If `git log c11a7d341..HEAD -- <file>` lists nothing for a file, the installed or staged one stands. If it lists a
commit, apply that file's `.diff` to main's copy instead, with `git apply --ignore-whitespace`.

## The director's calls

The notes, verbatim:

> (15:49) The vehicle parts, could you please redraw the suspension and brakes? They just don't read well. Kind of
> blobby or scribbly, or both.

> (16:08) The brakes look great. The shocks are just a little bit too wide. So the springs can just be a bit more
> narrow, and I think those will be okay.

> (16:10) Now I'm thinking the muffler and battery could use a little extra attention as well.

> (16:15) Looks good. Okay. Give each of the car parts one more fidelity pass.

> (16:17) fidelity pass on the engine and fuel tank as well.

> (16:31) Can you make the cracks in the windshield and window glass look like cracks running? And ... Fractaling.

> (16:45) I like where you're going with the cracks. They're just a little too bright. They need some bevel or depth or
> something to not be just white lines.

> (16:54) Everything looks great. [...]

16:54 passed two sheets:
- the parts: `preview/parts_as_passed.png`;
- the glass: `preview/glass_as_passed.png`.

The same sheets from the staged art are `parts_as_staged.png` and `glass_as_staged.png`. The parts sheet differs from
the passed one in one way only: the column fix below moved some parts one art pixel.

## What the player sees

On the Vehicle tab, for every car:

- **The six parts in the side columns are drawn pictures,** no longer the game's icons baked down. Each picture is the
  same for every body, left and right.
  - **Brake:** the disc face on, its swept face ringed off from the lip, the hat with four lug nuts. The caliper is a dark
    block clamped over the rim at the top right, with its pad line and a bolt lit.
  - **Spring:** a coilover standing up, nine pixels wide: an eye and a seat at each end, and three open coils round
    the damper. The wire and the damper are lit at the left and shaded at the right.
  - **Battery:** the case from the front: two posts, a seam under the lid, a label band with minus and plus under their
    posts.
  - **Muffler:** the canister lying down, round, with rolled crimps near each end, the pipe in at the left and the
    tailpipe out at the right.
  - **Engine:** standing, seen from the side, the way the check-engine light draws one:
    - the block and the head, with the gasket between them and four plug boots;
    - the finned valve cover and the oil cap;
    - the oil pan with its sump and drain plug;
    - the fan edge on at the front, on its shaft through the pulley;
    - the exhaust manifold down the back.

    It is 23 pixels wide, as the game's engine was.
  - **Gas tank:** lying as it does under a car: two pressed halves with the seam standing out at the ends, two straps,
    the filler neck up at the front with its cap, the fuel line out low at the back.
- **The columns breathe more.** The engine and tank row is 22 rows tall (it was 42, the turned engine). The rows still
  spread evenly over the car's height, so the gaps between parts grow: 5.9 to 9.7 rows, by body (3.0 to 6.9 before).
- **The parts in each column now share one center line.** Python's `round()` takes halves to the even number. That put
  odd-width parts a pixel apart: a spring sat a pixel right of its brake. Places now round halves up.
- **The figure is the same size:** the biggest figure is still 147 x 169, so the tab's zoom holds (2 at 4K). The
  columns are still 30 wide, set by the muffler.
- **The trailers'** springs and brakes are the same pictures, in the game's places: each spring over its brake, three
  rows apart.
- **The glass cracks** instead of taking short scratch dashes. Every window gets its own pattern from its name, the same
  every time.
  - **Yellow:** a chip with one crack running out of it both ways, part of the way.
  - **Red:** that crack run out to the frame, and more cracks running out of the strike all round. Every crack wavers a
    little, kinks now and then and branches as it goes; a crack that meets another stops there.
  - **Narrow side windows:** the crack zig-zags off the frame, like a lightning bolt.
  - **Cut into the glass:** each crack is a dark line, with a soft lit lip a pixel down and to the right, the wall that
    faces the light. The strike is the darkest point. The wear draws untinted, so the cracks look the same in every
    theme.
- **Nothing else changes.** The body, the panels, the wheels, the lamps, the rust and every scratch on the other parts
  are main's own pictures. Tires and lamps keep their scuffs.

`preview/compare_themes.png` shows the figure in Dark, Light and High contrast. `wear_dark_all.png` and
`wear_light_all.png` show all 13 bodies in green, yellow and red. All three come from `theme_preview.py`, run on the
staged art.

## How it draws

No Lua changes. `MechanicsTab.lua`'s `drawFigure` draws every layer by its key, as it does today:
- `zm_<key>`, tinted by its condition;
- its `_rim`;
- its `_wear1` or `_wear2`, untinted.

Each part's hit box is its layer's rect plus two units (`figZones`), so the pointer and the pad pick the new pictures
where they are. `MechFigs.lua` changes on 138 lines, in two ways:
- **130 layers' rects:** the six drawn parts only, every other layer as main has it;
- **8 of the 13 unions:**
  - four cars' are a pixel narrower: the sedan, the small car, the station wagon and the van, where the left column
    moved a pixel right;
  - the four trailers' change size: the horse trailer's is 120 x 152.

  The biggest stays 147 x 169.

## Build's work

1. **Install the art:**

       Copy-Item ZeDUI\art\car_parts_20261123\42\media\textures\ZeD\mech\*.png 42\media\textures\ZeD\mech\ -Force
       Copy-Item ZeDUI\art\car_parts_20261123\42\media\lua\client\ZeD\MechFigs.lua 42\media\lua\client\ZeD\ -Force

   - **That is 620 PNGs.** Each is the picture, its rim and both wear overlays:
     - 200 springs and 176 brakes, the trailers' included;
     - 36 each for the battery, muffler, engine and gas tank;
     - the 100 window wear overlays.

     No file is added or removed: the folder stays 1217 files.
   - **Install the staged pictures; don't bake on the PC.**
     - Main's own tool, baked here, differs from main's own art in 176 rust overlays of parts this change does not
       touch. Main's pictures came from a bake on another machine, and some rust edges move with the numpy and scipy
       versions.
     - So the stage holds only the files this change touches, and every other picture stays main's. This bake used
       Python 3.13.18, numpy 2.5.3, scipy 1.18.1 and Pillow 12.3.0.

2. **The tools,** installed in `ZeDUI/tools/mechanics/`.
   - **`pixel_mech_figs.py`:** its diff is `ZeDUI/art/car_parts_20261123/tools/pixel_mech_figs.py.diff`.
     - The six drawings `BRAKE`, `SPRING`, `BATTERY`, `MUFFLER`, `ENGINE` and `TANK`, with their tones (`TONES`).
       `sprite()` and `bevel()` turn a drawing into its greys: lit at the top left, shaded at the bottom right.
     - `redraw_callouts()` swaps the drawings in before the columns are laid out. A trailer's spring and brake go
       round the pair's old center, `PAIR_GAP` apart.
     - `to_sides()` no longer turns a drawn part (`TURN` stays for a part baked from the game's icon). Places round
       halves up (`half_up()`).
     - `cracks()` draws the glass's cracks. `wear()` gives a window the cut (`CRACK`), its lip (`CRACK_LIP`) and the
       strike (`CHIP`). Tires and lamps keep `scratch()`.
     - The docstring and the section notes quote the calls above.
   - **`test_mech_figs.py`** is new. It checks the installed art (no argument) or a whole bake (its folder):
     - every layer's texture, rim and wear overlays are there at the table's size;
     - the biggest figure is 147 x 169 and every layer lies in its union;
     - every drawn part is its drawing, mask and tones;
     - each car's six rows run in order, clear of each other, with both parts of a row on one line;
     - each column shares one center, and both columns stand as far off the car;
     - every window's wear is the crack's three tones only, inside the pane and off its outline, with one strike at
       most and no blots;
     - red glass is cracked, at least as much as yellow.

3. **Run the checks:**

       py ZeDUI\tools\mechanics\test_mech_figs.py

   - **Expect "3633 checks, 0 failed"** once the art is in. On main today it fails 288: the game's icons are not the
     drawings, and the old scratches are not cracks. That is the check working.
   - **Design ran it on main's art with the stage copied over it, as Build will install it:** 0 failed, here and on
     the PC's Python (3.14.3). The parts sheet from that copy matches `parts_as_staged.png` pixel for pixel.
   - **QA's sims:** no lua51 sim reads `MechFigs.lua` or the mech textures. The one in-game script that does,
     `gc_cleanup.lua`, checks four things that all still hold:
     - no grid box is drawn;
     - the car's base picture is MechFigs' size (the base pictures don't change);
     - the car is centered at a whole zoom, 2 at 4K (the biggest figure doesn't change);
     - the missing battery and the smashed windshield draw their rims (the rims are there for every part).

4. **After it ships,** Design updates the Design System's vehicle figure, if it shows one: the drawn parts and the
   cracked glass.

## QA

Run these at 4K with UI scale 1.75 (window layout reset first) and on the Steam Deck (1x). Use a sedan, a van, a
pickup, a sports car and the horse trailer.

### The parts

- [ ] Each part reads as what it is:
  - the brake disc with its caliper at the top right;
  - the spring, a coilover standing up;
  - the battery, with minus and plus;
  - the muffler lying down;
  - the engine standing, fan at the front;
  - the gas tank lying down, filler neck up at the front.
- [ ] Each column's parts line up on one center. The rows spread evenly down each side; no part touches another or the
      car.
- [ ] The car is the size on screen it was before (2 at 4K, 1 on the Deck), centered as before.
- [ ] Green, yellow and red tint each part, and yellow and red parts show their rust. Dark, Light, High contrast and
      a change of accent all read.
- [ ] Hover and select each part with the pointer and with the pad. The box drawn round the lit part fits its new
      picture.
- [ ] A missing battery draws its rim (`gc_cleanup.lua`'s check).

### The glass

- [ ] A chipped windshield (yellow) shows one crack running from a chip. A smashed one (red) shows the crack run to
      the frame, with cracks branching out of the strike.
- [ ] Side windows crack in zig-zags, yellow shorter than red.
- [ ] The cracks read as cut into the glass, not as white lines: Dark, Light and High contrast.
- [ ] A broken window that is gone draws its rim as before.

## Files

| What | Where |
|---|---|
| The 620 changed textures | `ZeDUI/art/car_parts_20261123/42/media/textures/ZeD/mech/` |
| The new table and its diff | `ZeDUI/art/car_parts_20261123/42/media/lua/client/ZeD/MechFigs.lua` (`.diff` beside it) |
| The tool's diff | `ZeDUI/art/car_parts_20261123/tools/pixel_mech_figs.py.diff` |
| The sheets as passed and as staged, the themes, all 13 bodies' wear | `ZeDUI/art/car_parts_20261123/preview/` |
| Scripts | `ZeDUI/tools/mechanics/`: `pixel_mech_figs.py` (changed), `test_mech_figs.py` (new) |

To regenerate, from `ZeDUI\tools\mechanics` (change the drawing or the code, never the picture):

    py pixel_mech_figs.py <stage dir>

It bakes every body to the stage. Copy only the parts and the window wear from it, for the reason in step 1.
