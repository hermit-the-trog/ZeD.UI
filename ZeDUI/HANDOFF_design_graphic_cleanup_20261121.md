# Handoff: Design to Build, graphic cleanup for 1.0 (Nov 21 2026)

Nothing in 42/ was touched. The art is staged in `ZeDUI/art/graphic_cleanup_20261121/`. Three tool scripts changed
in `ZeDUI/tools/`. Nothing is committed: Build installs, commits and runs the checks.

**Rechecked against main at `742769551`, Nov 22 15:20.**

- No commit since this was written touches what it replaces: `ZeD_BodyFigure.lua`, the body and mech textures,
  `MechFigs.lua`, `ObjectCardLaundry.lua`, `Tokens.lua`, `ThermalTab.lua`, `ObjectCardMedic.lua` and the two QA sims.
  The staged art still goes in as it is.
- Today's commits moved three line numbers, now corrected below: `Molecules.lua` (1973–1975, 1981),
  `EquipmentTab.lua` (638, 725–731) and `MechanicsTab.lua` (1063–1064).
- This is separate from the desktops handoff (`HANDOFF_design_desktops_20261122.md`), which is already merged.

## The director's calls

The notes, verbatim (Nov 21, 18:53):

> This is some graphic cleanup notes for application before or for 1.0. First note is appliance cards that do not
> fill a full card width should receive a background similar to the tile background we gave to the industrial
> dishwasher. Just a wall of some sort. Keep it simple. Number two. Let's remove the room grid from the health figure
> skeletons, the background grid, and from the vehicle tab. Instead, for the health tab, just a simple height ruler
> that goes to 7 feet and lists the character at 5'9". That's how tall the skeleton is. So just some simple
> measurement lines on the left-hand side. And then increase the horizontal space for the text next to it, so that
> the skeleton does not dominate as much. For the vehicles, please take the brakes and shocks and the engine and the
> battery out of the boxes that they are in. Just have the parts no frame.

Then, after the mock-up:

> Actually, now that I look at the graphic, let's go with a little over 6 foot.

> It does not need a dotted line or text of the height. It's meant more of just a suggestion.

He also chose, from the mock-up's questions:

- **The ruler:** on every skeleton figure: the Health tab, the Thermal tab, the Equipment tab's defense view and the
  medical check card. The ruler is in the figure's background art, so it shows wherever the figure is drawn.
- **The wall:** option A, a painted wall with a wood baseboard.
- **The car:** every callout part comes out of its box: engine, battery, brakes, springs, gas tank and muffler, with
  no leader lines either.

## 1. The body figure

### What changed in the art

`ZeDUI/tools/physpx/d_skeleton.py`:

- **The room grid is gone.** The background is the body's outline (unchanged) and a height ruler at the left.
- **The ruler** is a rail from the floor to 6'3", which stops open at the top: no tick and no number there.
  - A long tick every foot and a short one every half foot run right, toward the body.
  - The numbers 1' to 6' sit left of the rail, in ZeD's 3×5 face.
  - The scale is the figure's own: he is 247 px tall, which is 5'9"; she comes to 5'8".
  - No line or number marks his height: "just a suggestion".
  - The tones are quiet, all under the outline's edge (0.62): the rail at 0.30, the foot ticks 0.34, the half ticks
    0.22, the numbers 0.40.
  - `RULER_NUMBERS = False` in the script drops the numbers, if the director wants the lines alone.
- **The frame is 106 × 272** (was 220 × 260): 114 narrower, 12 taller.
  - The bones are still built on the old canvas, then moved −50, +16, so every bone pixel is the same as before.
  - **The hit rectangles** are the old ones moved by exactly (−50, +16).
  - **The hit map** is the old map moved by whole cells: 25 left and 8 down. No cell is lost.
- `test_body.py`:
  - reads the frame from `d_skeleton.FW` and `FH` instead of 220 × 260;
  - its default Lua path now points at the mod's own `42/media/lua/client/ZeD/ZeD_BodyFigure.lua`.
- **Checked in Design's sandbox:** `test_body.py` passes, 0 failed, against a copy of `ZeD_BodyFigure.lua` patched
  exactly as in step 2 below.
- **Checked on the PC:** its export is pixel-identical to the sandbox's.

### Build's work

1. **Install the art.** Copy the 40 PNGs, but not `_layout.lua.txt`, over the body folder:

       Copy-Item ZeDUI\art\graphic_cleanup_20261121\42\media\textures\ZeD\body\*.png 42\media\textures\ZeD\body\ -Force

2. **Update `ZeD_BodyFigure.lua`.**
   - Set `local CANVAS_W = 106` and `local CANVAS_H = 272` (lines 27–28).
   - Replace the four generated tables with the stage's `_layout.lua.txt`. That is everything from
     `local M_HITS = {` to the closing `}` of `F_HITMAP`, just before `local PART_ORDER`. The file's first line is
     a comment naming the canvas: keep it or drop it.
   - In the header comment:
     - "One 220 x 260 canvas" becomes "One 106 x 272 canvas".
     - Layer 1 becomes "the height ruler and the body's outline".
3. **Update `Tokens.lua`** (lines 500–501): `figureW = 106`, `figureH = 272`.
4. **Update the comments in `Molecules.layoutZoneA`.** The code is unchanged: it reads `T.sp.figureW`. Its comments
   still say 220 (lines 1973–1975 and 1981), so update them.
   - The text column gains 114 units: 228 px at 4K with UI scale 1.75.
   - Zone A grows 12 units wherever the figure is the taller column.
5. **The callers.** Nothing to change, but look at each:
   - **HealthTab:** `layoutZoneA` and `_measureZoneA` both use `T.sp.figureH`.
   - **ThermalTab:** lines 260–271.
   - **EquipmentTab:** lines 638 and 725–731.
   - **ObjectCardMedic:** line 307, `two = w >= figW + T.px(170)`. The two-column layout now starts on cards 114
     units narrower; check it reads well there.
6. **Update the QA sims.** Their mock tokens still say `figureW = 220, figureH = 260`:
   - `ZeDUI/tools/qa/fix_tabfill_sim.lua`, line 69;
   - `ZeDUI/tools/qa/trade_medic_sim.lua`, line 501.

   Set both to 106 and 272, then rerun them.
7. **Run the body test:** `py ZeDUI\tools\physpx\test_body.py`. Expect "0 failed".

## 2. The Vehicle tab's car

### What changed in the art

`ZeDUI/tools/mechanics/pixel_mech_figs.py`:

- **The base is the car body alone.** The game's callout boxes and their leader lines are left out.
  - Before, a leader that touched the car's outline joined its box to the car. That is why the battery and wheel
    boxes came out shaded like body panels.
  - Now the script opens away the one-cell lines first, takes the car as the biggest shape left, and puts back the
    cell the opening shaved off its outline. A two-pass trim then removes the one-cell nub where a leader met the car.
- **The parts are untouched.** Engine, battery, brakes, springs, gas tank and muffler stand beside the car where the
  boxes were, with no frame.
- **Only the 13 `zm_<body>_base.png` change.** All 13 body shapes were checked, trailers included: the hitches
  survive. Every part layer and rim is byte-identical to what ships.
- **`MechFigs.lua`:**
  - Only the 13 base rectangles and the 13 unions change. The unions shrink by the frames: 4door goes from 126×256 to
    120×249.
  - The script now writes Build's own header, so the file goes in exactly as written.
- **Checked on the PC:** its bake is pixel-identical to the sandbox's.

### Build's work

1. **Install the art:**

       Copy-Item ZeDUI\art\graphic_cleanup_20261121\mech\textures\* 42\media\textures\ZeD\mech\ -Force
       Copy-Item ZeDUI\art\graphic_cleanup_20261121\mech\MechFigs.lua 42\media\lua\client\ZeD\MechFigs.lua -Force

   Only the 13 bases differ in bytes; the other 602 files are identical.
2. **Remove the grid draw.** In `MechanicsTab.lua`, `drawFigure`, delete lines 1063–1064 (as of main `742769551`).
   Keep `local dim` above them: the base and unknown parts still use it.

   ```lua
   local gb = tex("gridbox")
   if gb then panel:drawTextureScaledAspect(gb, fx, fy, fw, fh, 0.30, dim.r, dim.g, dim.b) end
   ```

   - That is the only use of `zm_gridbox.png`, so it can be removed with `git rm`.
   - The old `bake_mech_figs.py` still writes the file. That tool is legacy, so leave it.
3. **Check the fit.** The union is a few cells smaller, but `drawFigure`'s fit rule (`sci / sc >= 0.85`) keeps the
   whole scale at 4K, 2x. The part zones come from the layer rectangles, so they follow.

## 3. The laundry card's wall and floor

The laundry faces keep the machine's own shape: the main face is 230×262 and @450 is 308×351. That leaves the card
bare either side, and they are the only appliance faces narrower than their card.

The director picked a painted wall with a wood baseboard. Then, on Nov 22:

> isn't one of the washer a top load? Therefore you would see the floor, not the wall and baseboard.

- **The washer gets floor.** The Premium Technologies washer is a top-loader, drawn looking down into its tub. What
  shows either side of it is the floor, seen from above:
  - vinyl tiles a foot square (the machine is 0.786 m wide, so a tile is 0.388 of the face's width);
  - two close shades laid in a checker, a few specks in each;
  - columns start from the machine's sides and rows from its front;
  - the machine's own shadow is two dots along each side.
- **The dryer and the ValuTech washer-dryer keep the wall.** Both are drawn from the front.
- **Where the code came from:** both follow the industrial dishwasher's tile wall, `tileWall` in
  `ObjectCardDishwasher.lua`. That is on the unmerged `dishwasher-faces` branch, which is 10 commits ahead of main
  while main is 347 ahead of it.
  - The reference below is self-contained: `rng` is copied from there.
  - Its colors go through `ZeD.paperTone`, which main has.

- **Where it goes:** `ObjectCardLaundry.lua`, next to `drawFace`. In `drawFace`, call `drawRoom` right after `px0` is
  worked out and before `OC.faceZone`, so the room sits behind the face. `faceId` is what `P.pick` returned there.

  ```lua
  local px0 = x + PL.centre(w, des.w, k)
  drawRoom(card, x, y, w, px0, des, k, faceId)  -- (behind the face: the room either side of it)
  OC.faceZone(card, px0, y, des.w * k, des.h * k, t.obj)
  ```

- **`P.baseId` strips the width and the `_n`**, so `"washer"` covers every washer face, the narrow one too.
- **Not in `LD.face`.** The face's pop-out stays the face alone, as the dishwasher's does. The room belongs to the
  Immersive face; the Simple plain card is untouched.
- **Cost:**
  - The wall: 5 rects for the field and baseboard, plus the stipple on the two visible sides (about 740 one-pixel
    specks at @450, about 410 on the main face). That is fewer rects than the dishwasher's tile wall.
  - The floor: about 70 rects a side.
  - `P.rects` can merge them if it shows in a profile.
- **Preview:** `preview/laundry_backdrops.png` is drawn by a Python port of exactly this code: the same `rng`, rects
  and colors.
- **Checked in Design's sandbox:** the Lua below ran in LuaJIT with `P` and `ZeD` stubbed as main has them. Its
  picture equals the preview's to the pixel for the washer @450, the washer on the 336 card, the dryer and the
  washer-dryer.

```lua
-- ---------------------------------------------------------------------------
-- the wall behind the laundry machine (director, Nov 21 2026: "appliance cards that do not fill a full card width
-- should receive a background similar to the tile background we gave to the industrial dishwasher. Just a wall of
-- some sort. Keep it simple."; he picked a painted wall with a wood baseboard). The face keeps the machine's own
-- shape, so the card's width either side is wall: paint with a light stipple, and a baseboard along the machine's
-- foot. Colors as printed, shown at the paper tone like the dishwasher's tile.
-- ---------------------------------------------------------------------------
local WALL_PRINTED = { paint = "#e6dfcf", speckHi = "#ece5d5", speckLo = "#ddd6c6",
                       board = "#8c6a46", boardHi = "#b48c60", boardMid = "#a07a52", boardLo = "#5e4630" }
local WALL = nil
local function wallColors()
    if WALL then return WALL end
    WALL = {}
    for key, v in pairs(WALL_PRINTED) do WALL[key] = ZeD.paperTone(P.color(v)) end
    return WALL
end
-- a small repeatable number stream (kept under 2^31: Kahlua's % breaks past it), as the dishwasher's
local function rng(seed)
    local s = (seed % 65521) + 1
    return function(n) s = (s * 75 + 74) % 65537; return s % n end
end
-- the baseboard's height in art px: about 4 inches against the machine's 27-inch front (12 on the main face, 16 @450)
local function boardH(H) return math.floor(H * 0.046 + 0.5) end
-- the paint and the baseboard from art x0 for aw, rows 0 .. H (the machine's foot at H)
local function wallField(cv, x0, aw, H)
    if aw <= 0 then return end
    local C, bb = wallColors(), boardH(H)
    P.rect(cv, x0, 0, aw, H - bb, C.paint)
    P.rect(cv, x0, H - bb, aw, bb, C.board)
    P.rect(cv, x0, H - bb, aw, 1, C.boardHi)          -- the board's lit top edge
    P.rect(cv, x0, H - bb + 1, aw, 1, C.boardMid)
    P.rect(cv, x0, H - 2, aw, 2, C.boardLo)           -- the shadow at the floor
end
-- the paint's stipple where the wall shows: a speck to every 64 art px, a fixed seed so it holds still
local function wallSpecks(cv, x0, aw, H, seed)
    if aw <= 0 then return end
    local C, r = wallColors(), rng(seed)
    local ph = H - boardH(H)
    for _ = 1, math.floor(aw * ph / 64) do
        local sx = r(aw)                                -- (one call at a time, in this order: the preview's order)
        local sy = r(ph)
        local c = (r(2) == 0) and C.speckHi or C.speckLo
        P.rect(cv, x0 + sx, sy, 1, 1, c)
    end
end
-- a column of screen pixels narrower than one art pixel at the card's edge, in the wall's colors
local function wallSliver(card, sx, sw, y, k, H)
    if sw <= 0 then return end
    local C, bb = wallColors(), boardH(H)
    local function band(y0, y1, c) card:drawRect(sx, y + y0 * k, sw, (y1 - y0) * k, 1, c.r, c.g, c.b) end
    band(0, H - bb, C.paint); band(H - bb, H - 2, C.board); band(H - 2, H, C.boardLo)
end
--- The wall across the card behind a face drawn at screen x px0 (art 0) and zoom k, filling x .. x + w (it shows
--- either side of the machine and round its edges), as the dishwasher's tileWall.
local function drawWall(card, x, y, w, px0, des, k)
    local H = des.h
    local cv = P.canvas(card, px0, y, k)
    local lg = px0 - x
    local la = math.floor(lg / k)
    local rx = px0 + des.w * k
    local rg = x + w - rx
    local ra = math.floor(rg / k)
    wallField(cv, -la, la + des.w + ra, H)
    wallSpecks(cv, -la, la, H, 7)
    wallSpecks(cv, des.w, ra, H, 13)
    wallSliver(card, x, lg - la * k, y, k, H)
    wallSliver(card, rx + ra * k, rg - ra * k, y, k, H)
end

-- ---------------------------------------------------------------------------
-- the floor round the top-loading washer (director, Nov 22 2026: "isn't one of the washer a top load? Therefore you
-- would see the floor, not the wall and baseboard"). Its face looks down into the tub, so what shows either side of
-- it is the floor, seen from above: vinyl tiles a foot square in two close shades, a few specks in each, columns from
-- the machine's sides and rows from its front, and the machine's own shadow along each side. Paper tone, as the wall.
-- ---------------------------------------------------------------------------
local FLOOR_PRINTED = { tileA = "#c3bdb0", tileB = "#bbb5a8", speckLo = "#a7a194", speckHi = "#d0cabd", seam = "#8e887b" }
local FLOOR = nil
local SHADOW = { r = 0, g = 0, b = 0 }
local function floorColors()
    if FLOOR then return FLOOR end
    FLOOR = {}
    for key, v in pairs(FLOOR_PRINTED) do FLOOR[key] = ZeD.paperTone(P.color(v)) end
    return FLOOR
end
-- a tile a foot square, in art px: the machine is 0.786 m wide, so a foot is 0.388 of the face's width
local function tileFt(faceW) return math.floor(faceW * 0.388 + 0.5) end
-- one side of floor from art x0 for aw, rows 0 .. H (the machine's front at H); edge = the machine's side the
-- columns start from, dir = -1 laying them leftward, 1 rightward; s = the tile
local function floorSide(cv, x0, aw, H, edge, dir, s, seed)
    if aw <= 0 then return end
    local C, r = floorColors(), rng(seed)
    local x1 = x0 + aw
    local function clip(x, y, w, h, c)
        local a, b = math.max(x, x0), math.min(x + w, x1)
        local c0, c1 = math.max(y, 0), math.min(y + h, H)
        if b > a and c1 > c0 then P.rect(cv, a, c0, b - a, c1 - c0, c) end
    end
    local cols, rows = math.floor(aw / s) + 1, math.floor(H / s) + 1
    for row = 0, rows do
        local ty = H - (row + 1) * s
        for col = 0, cols do
            local tx = (dir < 0) and (edge - (col + 1) * s) or (edge + col * s)
            clip(tx, ty, s, s, ((row + col) % 2 == 0) and C.tileA or C.tileB)
            clip(tx, ty, s, 1, C.seam)                                  -- the seam along its far edge
            clip((dir < 0) and tx or (tx + s - 1), ty, 1, s, C.seam)    -- and along its outer side
            for _ = 1, 6 do                                             -- (in this order: the preview's)
                local sx = r(s - 4)
                local sy = r(s - 4)
                local c = (r(2) == 0) and C.speckLo or C.speckHi
                clip(tx + 2 + sx, ty + 2 + sy, 1, 1, c)
            end
        end
    end
    P.rect(cv, (dir < 0) and (edge - 2) or edge, 0, 2, H, SHADOW, 0.25)   -- the machine's shadow along its side
end
-- a column of screen pixels narrower than one art pixel at the card's edge, in the floor's tile color
local function floorSliver(card, sx, sw, y, k, H)
    if sw <= 0 then return end
    local c = floorColors().tileA
    card:drawRect(sx, y, sw, H * k, 1, c.r, c.g, c.b)
end
--- The floor either side of a face drawn at screen x px0 (art 0) and zoom k, filling x .. x + w.
local function drawFloor(card, x, y, w, px0, des, k)
    local H = des.h
    local cv = P.canvas(card, px0, y, k)
    local lg = px0 - x
    local la = math.floor(lg / k)
    local rx = px0 + des.w * k
    local rg = x + w - rx
    local ra = math.floor(rg / k)
    local s = tileFt(des.w)
    floorSide(cv, -la, la, H, 0, -1, s, 7)
    floorSide(cv, des.w, ra, H, des.w, 1, s, 13)
    floorSliver(card, x, lg - la * k, y, k, H)
    floorSliver(card, rx + ra * k, rg - ra * k, y, k, H)
end

--- The room either side of a face: the floor round the top-loading washer (seen from above), the wall behind the
--- dryer and the combination washer-dryer (seen from the front).
local function drawRoom(card, x, y, w, px0, des, k, faceId)
    if P.baseId(faceId) == "washer" then return drawFloor(card, x, y, w, px0, des, k) end
    return drawWall(card, x, y, w, px0, des, k)
end
```

## QA

Run these at 4K with UI scale 1.75 (window layout reset first) and on the Steam Deck. The Deck draws 1x art, so the
ruler's numbers are 3×5 pixels there.

### The body figure: Health, Thermal, Equipment's defense view and the medical check card

- [ ] No grid behind the body. The ruler is at the left: the rail is open above 6', with no head line and no height
      text.
- [ ] The numbers 1' to 6' read at 2x and on the Deck.
- [ ] The ruler and the outline sit at the same quiet level on Dark, Light and High Contrast.
- [ ] Health: the text column is wider and Overall's lines rewrap. Zone A is 272 tall, or the text's height if
      taller.
- [ ] Every part hovers and selects: mouse, pad A, and the focus boxes (`getPartRects`).
- [ ] Medical check card: the two-column layout on a narrower card reads well.

### The Vehicle tab

- [ ] No grid, no boxes and no leaders on any body shape (13, trailers included).
- [ ] Every part is tinted by its condition. Missing and smashed parts show their rims; the highlighted part shows its
      outline.
- [ ] The car is centered, at 2x at 4K.

### The laundry card

- [ ] The washer, on the full card (@450) and the narrow one: floor tiles either side, the seams square to the
      machine, its shadow along both sides.
- [ ] The dryer and the washer-dryer, the same cards: the painted wall either side, with the baseboard on the
      machine's foot.
- [ ] Nothing is drawn outside the card, and there is no gap at the card's edges.
- [ ] The pop-out is unchanged.

## Files

| What | Where |
|---|---|
| Body figure art (40 PNGs and the Lua tables) | `ZeDUI/art/graphic_cleanup_20261121/42/media/textures/ZeD/body/` |
| Car art (615 PNGs, 13 changed) and `MechFigs.lua` | `ZeDUI/art/graphic_cleanup_20261121/mech/` |
| Before / after sheets | `ZeDUI/art/graphic_cleanup_20261121/preview/`: `figure_before_after.png`, `car_before_after.png`, `car_all.png`, `laundry_backdrops.png` |
| Scripts changed | `ZeDUI/tools/physpx/d_skeleton.py`, `ZeDUI/tools/physpx/test_body.py`, `ZeDUI/tools/mechanics/pixel_mech_figs.py` |

After this ships, Design updates the ZeD-GUI Design System to match: the BodyFigure card still says one 220 × 260
canvas with the perspective grid, and the Desk and ObjectCard cards should mention the car without boxes and the
laundry's wall and floor.

To regenerate, from the tool folders (change the script, never the picture):

    py d_skeleton.py ..\..\art\graphic_cleanup_20261121
    py pixel_mech_figs.py ..\..\art\graphic_cleanup_20261121\mech
