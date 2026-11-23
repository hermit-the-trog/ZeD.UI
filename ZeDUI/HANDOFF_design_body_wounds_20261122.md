# Handoff: Design to Build, the body figure's flesh, wounds and height chart (Nov 22 2026)

Nothing in 42/ was touched, and nothing is committed: Build installs, commits and runs the checks. Everything is staged
in `ZeDUI/art/body_wounds_20261122/`: the art, the five Lua files as Design tested them, six of QA's sims fitted to
them, and three previews. Nine tool scripts are in `ZeDUI/tools/physpx/`: one changed, eight new.

**Made against main at `ab8bdfe49`, Nov 22 17:44** (the figure frame and the strain tint merged). Each staged Lua file
is main's own copy with this handoff's changes applied, in the checkout's line endings (CRLF). If
`git diff ab8bdfe49 -- <file>` prints nothing for a file, copy the staged one over it. If it prints anything, apply
that file's `.diff` (`git apply --ignore-whitespace`).

**This replaces the 16:50 version of this handoff,** which was made against `b643c516e` and not yet applied. Since then:

- **The height chart is new** (section 3).
- **The wounds read nothing of the game themselves.**
  - `ZeD_BodyFigure.woundsOf(bp, ...)` read every flag of every body part a second time on each Health refresh: about
    200 more getter calls on top of the 407 that QA's perf sim counts today.
  - Now the Health list keeps what it reads (`SEEN` in HealthTab.lua), and `ZeD_BodyFigure.woundsFrom(seen)` turns
    that into the wounds. The getter count is unchanged.
- **Six of QA's sims are fitted** (section 4, step 3). They stub the figure, and the earlier Lua stopped them.

## The director's calls

The notes, verbatim:

> (15:40) We have this really cool skeleton figure for health and temperature and protection. In the health panel,
> when there is an injury, is that injury visible on the skeleton? Is the bandage visible on that skeleton? I believe
> the base game UI draws bandages and cuts. And then the character outline that the skeleton sits in, can we add just
> some fleshiness instead of it being just an outline? The skeleton sits like a cutout. The muscles and tendons and
> blood vessels. I realize there isn't really much room for those, and I don't want to show all those in super
> detail. It's more just so it doesn't look like it's sitting in a gray cutout figure.

> (16:04) For flesh wounds and stitches and such, can we add a little skin that kind of fades out back to the skeleton
> just to show that it's a surface injury and not a skeletal injury?

> (16:27) That is really cool. Do one polish pass, because I know that an extra pass always helps. And then give me
> the handoff.

> (17:03) This needs to fit in a half card width. Draw a diagram background. Very simple, just to fill in the empty
> white space on each side.

> (17:15) I like A, but I think it should have old handwritten script identifying each part. This does not need to be
> legible. This is very much just a hint at that.

> (17:19) I like it.

"A" was the height chart, one of three diagram mocks. 17:19 passed the chart with the script, him and her, Dark and
Light, in the 4K frame. The mock is in the design refs:
`ZeD_design_refs\body_flesh_20261122\diagram\figure_frame_chart_script.png`.

What the game does, for the record:

- **Vanilla's health panel draws no wounds.** `ISBodyPartPanel` tints each part and draws an outline and nodes.
- **The 3D character shows them.**
  - Bandages are worn items, a clean and a bloody one per part: `media/clothing/clothingItems/Bandage_<Part>[_Blood].xml`.
  - Scratches, lacerations, bites and bandages are skin overlays: `media/textures/BodyDmg/`.

## 1. The flesh

`ZeDUI/tools/physpx/d_flesh.py` (new) fills the traced body under the bones. The layers, back to front:

1. A base of deep tissue.
2. The muscles, raised and lit from the top left like the bones, with a faint grain along their length.
3. Pale tendons at the wrists, knees and ankles and down the belly.
4. Faint veins (blue) up the arms and inner legs, and arteries (red) in the neck and thighs.

Every form is placed from the traced body's own landmarks. One set of colors serves both themes, as the bones do.

- **It stays one pixel inside the outline,** so the outline's line keeps the theme's tint.
- **`d_skeleton.py` (changed) bakes it into `<s>-skeleton.png`, under the bones.**
  - `FLESH = True`, just above `export`; `False` ships the bare skeleton as before.
  - Only the two skeleton textures change. The 38 others are pixel-identical to main's, and `_layout.lua.txt` is
    unchanged.
- **No Lua of its own.** Every figure gets the flesh: the Health tab, the Thermal tab, the Equipment tab's defense view
  and the medical check card.

## 2. The wounds

### What the player sees

On the Health tab's figure and the medical check card, each part shows its wounds and their care over its bones. The
bones keep their tint, by health or by muscle strain (`HealthTab.figureColor`), as now: the wounds draw over it.

| The list says | The figure draws | Read from the BodyPart |
|---|---|---|
| Bandaged | gauze wrapped round the middle of the part, a pixel proud of the body; it covers every wound under it | `bandaged()`, `getBandageLife() > 0` |
| Dirty bandage | the same, with blood soaked through | `bandaged()`, `getBandageLife() <= 0` |
| Splinted | two boards along the part, tied twice (not on the head, chest or belly: the game splints none of them) | `getSplintFactor() > 0` |
| Fracture | a zig-zag crack across the bone, with a chipped light edge | `getFractureTime() > 0` |
| Bitten | the teeth's two arcs | `bitten()` |
| Deep wound | an open gash | `deepWounded()`, not stitched |
| Stitched | cross stitches over a closed cut | `stitched()` |
| Lodged bullet | a hole | `haveBullet()` |
| Glass shards | two shards | `haveGlass()` |
| Cut | a slash | `isCut()` |
| Burn | a raw, charred patch | `getBurnTime() > 0` |
| Scratched | three claw lines | `scratched()` |
| Bleeding | blood running down from the last mark | `bleeding()` |
| Infected | a yellow-green ring round the first mark | `isInfectedWound()`, by the list's rule |

- **At most two marks a part,** most serious first: bite, deep wound, stitches, bullet, glass, cut, burn, scratch.
- **The list's own reading decides what shows.**
  - HealthTab's `classifyConditions` reads each flag once, as it did, and keeps it in `SEEN` as it goes.
  - `ZeD_BodyFigure.woundsFrom(seen)` draws from that, so the figure and the list cannot disagree.
  - Under a bandage only the bandage shows (and a splint or a crack, if there is one).
  - Infection shows when the list names it: to a First Aid 9+ doctor, or once it has grown past what the doctor's
    level can miss.
  - A part another mod holds back shows only its care: the bandage, the splint, the stitches.
- **Every mark on the body sits on a patch of skin.**
  - The patch is solid round the marks and fades out in see-through steps to the flesh and bones.
  - It is the character's own tone: `getHumanVisual():getSkinTextureIndex()`, 0 to 4, the five the game offers.
  - A fracture has no skin. It is a crack in the bone itself.
- **Nothing changes** on the Thermal tab or the Equipment tab's defense view: they never set wounds.

`preview/body_wounds_review.png` shows all of this:

- Before / Flesh / Hurt / Every mark, him and her, Dark and Light, at 2x;
- each mark at 4x;
- the five skin tones.

`preview/wounds_every_part.png` shows every part's bandage, dirty bandage, splint, crack, one mark, and two marks with
bleeding.

### How it draws

`ZeD_BodyFigure:_drawWounds(panel, xOff, yOff, s)` runs after `_drawParts`, in `drawAt` and `render`. It makes six
passes, and each pass visits every part in the figure's order, so one part's gauze never covers a neighbor's mark:

1. The cracks.
2. The bandages.
3. The skin, tinted by `SKIN_TINT[tone + 1]`.
4. The infected rings.
5. The marks, then the bleeding below and right of the last one.
6. The splints.

- **Per-part pictures** (`<s>-<part>-<picture>.png`) are cut to their own box. The generated tables give each box's
  top left in canvas pixels: `M_WOUNDS` and `F_WOUNDS`, from `d_wounds.py`.
- **Marks** (`mark-<kind>.png`, `mark-<kind>-infected.png`) are 15 x 15, their middle at (7, 7). The tables give each
  part's mark places: one place for a single mark, two for a pair.
- **Every picture is drawn** with `drawTextureScaledUniform` at `xOff + math.floor(x * s)`, like the parts, and loaded
  once with nearest filtering.
- **Nothing hurt costs nothing:** with no wounds set, `_drawWounds` returns at once.

## 3. The height chart

### What the player sees

In the margins of the figure's frame, on the Health tab, the Thermal tab, the Equipment tab's defense view and the
medical check card:

- **The ruler's half-foot lines carried out to either side,** each foot stronger than the half between. They stop 2 art
  pixels short of the frame's line and of the figure's canvas (the ruler's numbers).
- **The floor right across under the feet.** It leaves the ruler's own floor tick as the ruler draws it.
- **A word of old script on a line beside each part.**
  - The parts on the character's right side, the neck and the belly at the left; the rest at the right.
  - Each word sits on the free half-foot line nearest its part, flush with its margin's outer edge, so its line runs
    in toward the part.
  - The words are made up (`d_script.py`), not legible, as asked. A part keeps its word, and hers differ from his.
- **All of it in the ruler's ink,** tinted by the theme as the ruler is: white on Dark and High Contrast, near-black on
  Light. The lines at 10% and 20%, the floor and the script at 30%.
- **A side shows its words where its lines are long enough for its widest word.** A narrow frame keeps the lines alone.
- **Lite draws no chart.** Lite puts away the extras the game itself does not have (Settings.lua, Lite or Full), so the
  frame stays plain there. The flesh and the wounds show in both looks, as the figure does.

`preview/body_chart_review.png` is the chart as the game draws it: test_chart.py's own render, from the real Lua. It
shows the Health tab at 4K (him and her, Dark, Light, High Contrast), the medical card at 220 and 336, and the Health
tab at 1x. Where the script shows:

| Screen | Place | Frame | Margins, art px | The script |
|---|---|---|---|---|
| 4K, 1.75 | Health tab | halves, 384 wide, 2x | 42 / 42 | both sides |
| 4K | medical card, 336 | halves, 267, 2x | 12 / 13 | lines only |
| 4K | medical card, 220 drawer | stacked, 349, 2x | 33 / 33 | both sides |
| 1080p, 1.0 | Health tab | halves, 220, 1x | 56 / 56 | both sides |
| 1080p | medical card, 336 | halves, 153, 1x | 22 / 23 | lines only |
| 1080p | medical card, 220 drawer | stacked, 200, 1x | 46 / 46 | both sides |
| 1280x800, 0.75 | Health tab | halves, 164, 1x | 28 / 28 | both sides |
| 1280x800 | medical card, 336 | stacked, 236, 1x | 64 / 64 | both sides |
| 1280x800 | medical card, 220 drawer | stacked, 149, 1x | 20 / 21 | lines only |

Thermal and the defense view take the same layout (`layoutZoneA`) on their own widths. On the Steam Deck's Health tab
the lines are 24 pixels long and the widest word is 24, so every word shows there, whole.

### How it draws

`ZeD_BodyFigure:drawChart(panel, L)`, with `L` the frame's layout (`Molecules.figureFrame` or `layoutZoneA`). Six draws
at most, and no table made:

1. **The lines:** one picture, `fig-chart-lines.png`, a 1 x 272 column with each line's alpha on its row. It is
   stretched along each margin with `drawTextureScaled`, nearest-filtered, so the twelve lines a side are one draw.
2. **The floor:** two rectangles, either side of the ruler's floor tick (`floorGap` in the table).
3. **The script:** one picture a side, `fig-notes-<s>-left.png` and `-right.png`, white strokes drawn at 30%. The left
   one sits at the left margin's outer edge, the right one at the right margin's.

- **The margins** are counted in whole art pixels, from the canvas to the inside of the frame's line (`T.px(1)`, as
  `drawFigureFrame` draws it). Everything sits on the figure's pixel grid, at the frame's zoom.
- **A stroke that lies on its own line** carries less alpha in its picture, so the two together come to 30%: a word
  reads the same on its line as off it, as in the mock.
- **The tint** is drawAt's own, `ZeD.colorBlend(iconWhite, accent, 0.45)`, worked out inline so no table is made.
- **The pictures** load once each, nearest-filtered, the first time they are drawn.
- **The table** `CHART` (`_chart.lua.txt`, from `d_chart.py`) holds the floor's row and gap, the margin, the script's
  alpha, the two inks and each script picture's top row and size.

### Where it is called

After the frame and before the controller's mark and the figure, so the mark and the figure sit on it:

- **Health and Thermal:** `_drawBodyFigure` takes the layout as an 8th argument, `frame`. It calls
  `fig:drawChart(panel, frame)` right after `setSex`, before the focus marks. The call sites pass `layout`.
- **Equipment:** `_drawDefenseFigure` the same.
- **The medical card:** `def.body` draws the frame and the chart before its focus marks. The frame's line used to come
  after the marks; now the order is the tabs'.

## 4. Build's work

1. **Install the art:** the two skeletons and the chart's five pictures, then the wound pictures.

       Copy-Item ZeDUI\art\body_wounds_20261122\42\media\textures\ZeD\body\*.png 42\media\textures\ZeD\body\ -Force
       New-Item -ItemType Directory -Force 42\media\textures\ZeD\body\wounds | Out-Null
       Copy-Item ZeDUI\art\body_wounds_20261122\42\media\textures\ZeD\body\wounds\*.png 42\media\textures\ZeD\body\wounds\ -Force

   That is 2 + 5 + 283 PNGs, 105 KB in all. The two `.lua.txt` files stay in the stage: they are the generated tables,
   already in the Lua.

2. **The Lua.** Five files are in `ZeDUI/art/body_wounds_20261122/lua/`, each with its `.diff`. Copy or apply as the
   note at the top says.
   - **`ZeD_BodyFigure.lua`:**
     - The header lists four layers and the chart.
     - `new` sets `o.wounds = {}` and `o.skinTone = 0`.
     - `render` and `drawAt` call `self:_drawWounds(...)` after `_drawParts`.
     - THE HEIGHT CHART sits after `_background`: the generated `CHART` table (`_chart.lua.txt`) and `drawChart`.
     - WOUNDS sits after `SUFFIX_TO_DISPLAY`: the generated tables (`_wounds.lua.txt`), `woundsFrom`, `skinToneOf`,
       `setPartWounds`, `clearWounds`, `setSkinTone` and `_drawWounds`.
     - On a regenerate, replace each generated table with its new `.lua.txt`, as `_layout.lua.txt` replaces the hit
       tables.
   - **`HealthTab.lua`:**
     - `classifyConditions` keeps what it reads of the wounds and their care in `SEEN`. Each flag is still read once.
     - `gatherData` keeps `held` (it called `heldBack` inline), fills `woundsByFigure` with `woundsFrom(SEEN)`, and
       returns `woundsByFigure` and `skinTone`.
     - `_drawBodyFigure` takes `frame` and draws the chart, then hands the figure the wounds and the skin tone after
       the colors.
   - **`ThermalTab.lua`, `EquipmentTab.lua`:** the chart, through the `frame` argument.
   - **`ObjectCardMedic.lua`:** `def.body` hands the patient's wounds and skin tone to its figure after the colors
     (`figureColor`), and draws the frame and the chart before the focus marks. `gatherData` is called with the patient,
     so nothing more.

3. **QA's sims.** Six are in `ZeDUI/art/body_wounds_20261122/qa/`, each with its `.diff`, for Build or QA to take in.
   Each stubs `ZeD_BodyFigure` and now needs its new calls; without the fit it stops with "attempt to call ... (a nil
   value)".
   - `trade_medic_sim.lua` and `strain_tint_sim.lua`: `woundsFrom`, `skinToneOf`, `setSkinTone`, `setPartWounds` and
     `drawChart` on their stubs.
   - `woundsov_sim.lua`: `woundsFrom` and `skinToneOf`.
   - `perf_throttles_sim.lua`: the same two. Its `oldShape` leaves `woundsByFigure` and `skinTone` out, as it leaves
     the strain fields out: new data the base never had. The changed-rule check goes through it too, so it stays not
     blind.
   - `tab_search_sim.lua`: `drawChart`.
   - `fix_tabfill_sim.lua`: `drawChart`, `setSkinTone`, `setPartWounds`, `woundsFrom`, `skinToneOf`.

4. **The tools.** Copy the nine scripts into `ZeDUI/tools/physpx/`:
   - `d_skeleton.py` (changed; `d_skeleton.py.diff` in the stage);
   - `d_flesh.py`, `d_wounds.py`, `wounds_sheet.py`, `wounds_gallery.py`, `test_wounds.py`, `d_script.py`,
     `d_chart.py`, `test_chart.py` (new).

5. **Run the checks.** The Python tests need lupa, numpy, scipy and Pillow, as `test_body.py` does. On the PC today
   neither Python (3.14, 3.12) has lupa; `py -3 -m pip install lupa` adds it.

       py ZeDUI\tools\physpx\test_body.py
       py ZeDUI\tools\physpx\test_wounds.py
       py ZeDUI\tools\physpx\test_chart.py

   Expect "0 failed" from all three: test_wounds runs 188 checks, test_chart 668.
   - **`test_wounds.py`:**
     - the mod's own figure draws the reference pixel for pixel: three states, both sexes, both bases, 1x, 2x and
       0.75x, and all five skin tones;
     - a figure with no wounds draws exactly as before;
     - every picture asked for exists, loads once and is nearest-filtered;
     - the flesh fills the body and stays off the outline's line;
     - `woundsFrom` gets 15 cases right;
     - the real HealthTab.lua's `gatherData` gives the figure the right wounds in 17 cases (bandage, dirty, stitches,
       the two-mark cap, infection by doctor level and cheat, held-back parts, splint, a bleed alone, the bandage
       hiding burn, glass and infection), reads no wound getter of a part twice, and passes the skin tone;
     - the skin tone holds to 0 to 4.
   - **`test_chart.py`:**
     - the frame, the chart and the figure come to the passed mock's layout under the figure, within one level in 255:
       both sexes, Dark, Light and High Contrast, at 4K, 1080p and 1280x800, on the Health tab, the medical card in
       halves and stacked, the narrowest halves, and a span too narrow for the figure (90 renders);
     - every draw sits inside the frame's line, on the art's grid, in the ruler's ink, with nothing under the
       figure's own pixels, and six draws at most;
     - the script shows where its lines hold it, and on the Health tab on all three screens;
     - Lite draws none; no table is made a frame;
     - the pictures exist, load once and are nearest-filtered, and the table is d_chart.py's;
     - the four places the figure sits call it after the frame and before the mark and the figure.

   Then QA's sims, as usual with lua51. Design ran these 19 on a copy of main with the staged files, and every one
   passes, as on main itself:
   `figure_frame_sim`, `trade_medic_sim`, `woundsov_sim`, `perf_throttles_sim`, `tab_search_sim`, `fix_tabfill_sim`,
   `drawer_tabs_perf_sim`, `gc_qa_cleanup_sim`, `strain_tint_sim`, `status_colors_sim`, `hint_strip_cover_sim`,
   `b8r3_sim`, `chip_dot_sim`, `director_review_fixes_sim`, `fix_shared_misc_sim`, `g4_character_tabs_sim`,
   `item_meter_sim`, `rows178_sim`, `tab_fill_sim`.
   - `perf_throttles_sim` still counts 519.2 -> 406.7 body-part getter calls a refresh.
   - **`drawer_tabs_perf_sim` against main reports the chart, by design.** Thermal and Equipment draw six more a frame,
     with six more Java calls and 840 more Lua instructions, and no more memory:
     - Thermal: 212 -> 218 draws a frame;
     - Equipment's list: 194 -> 200;
     - Equipment's doll: 359 -> 365.

     Its "draws the same as before" and "no more draws / Java calls" checks fail against main for that, as for any new
     drawing. With no base it passes (76 checks).

6. **After it ships,** Design updates the ZeD-GUI Design System's BodyFigure card: the flesh, the wound layer, the
   skin tone and the chart.

## QA

Run these at 4K with UI scale 1.75 (window layout reset first) and on the Steam Deck (1x).

To make injuries in a debug game, call `ISHealthPanel.onCheatCurrentPlayer(bodyPart, action, player)` with one of:
`"scratched"`, `"cut"`, `"deepWound"`, `"bite"`, `"bleeding"`, `"bullet"`, `"glass"`, `"burned"`, `"fracture"` or
`"infected"`. Treat them with real items through the figure's own treatment menu: bandage, stitch, splint.

### The flesh: Health, Thermal, Equipment's defense view, the medical check card

- [ ] Red muscle, pale tendons and faint vessels fill the body. The outline's line still shows all round, in the
      theme's tint, on Dark, Light and High Contrast.
- [ ] Every part still tints, hovers and selects: mouse, pad A, and the focus boxes.

### The wounds: Health tab and the medical check card

- [ ] Each injury makes its mark on the right part. One mark sits in the middle of the part; two sit along it.
      Bleeding runs from the last.
- [ ] Every mark sits on a patch of the character's skin that fades out. Try a pale tone and a dark one.
- [ ] A crack shows in the bone, with no skin under it.
- [ ] Bandaging hides the part's marks and shows the gauze. A spent bandage shows blood. Removing it brings the marks
      back.
- [ ] A splint shows boards. Stitching a deep wound turns the gash into stitches.
- [ ] Infection shows on a First Aid 0 character only once it has grown, and at once with First Aid 9+.
- [ ] The medical check of another player (MP) shows the patient's wounds on the patient's skin, by the doctor's
      level.
- [ ] Nothing new shows on the Thermal tab or the Equipment tab's defense view.
- [ ] No frame-rate change with every part hurt.

### The chart: Health, Thermal, Equipment's defense view, the medical check card

- [ ] Faint lines run out from the ruler's ticks to either side, a foot stronger than the half between. They stop short
      of the frame's line and of the figure.
- [ ] The floor runs right across under the feet. The ruler's floor tick looks as it did.
- [ ] A faint scribbled word sits on a line beside each part, flush with the frame's outer edges. Hers differ from his.
- [ ] Dark, Light, High Contrast and a change of accent: the chart takes the ruler's ink and tint at once.
- [ ] The 336 medical card in halves shows the lines alone. The 220 drawer card, stacked, shows the words.
- [ ] Lite shows no chart; Full brings it back at once.
- [ ] The controller's hand and the focus box sit on the chart, not under it.
- [ ] `gc_cleanup.lua`'s figure frame checks still pass. The chart draws no text, no rectangle on the frame's line and
      no picture named grid.

## Files

| What | Where |
|---|---|
| The two skeletons on their flesh, and the chart's five pictures | `ZeDUI/art/body_wounds_20261122/42/media/textures/ZeD/body/` |
| 283 wound pictures | `ZeDUI/art/body_wounds_20261122/42/media/textures/ZeD/body/wounds/` |
| The generated tables | `_chart.lua.txt` and `wounds/_wounds.lua.txt`, beside the pictures |
| The five Lua files as tested, and their diffs | `ZeDUI/art/body_wounds_20261122/lua/` |
| Five of QA's sims, fitted, and their diffs | `ZeDUI/art/body_wounds_20261122/qa/` |
| The wounds review, the every-part sheet, the chart as drawn | `ZeDUI/art/body_wounds_20261122/preview/` |
| The tool change | `ZeDUI/art/body_wounds_20261122/d_skeleton.py.diff` |
| Scripts | `ZeDUI/tools/physpx/`: `d_skeleton.py` (changed); `d_flesh.py`, `d_wounds.py`, `wounds_sheet.py`, `wounds_gallery.py`, `test_wounds.py`, `d_script.py`, `d_chart.py`, `test_chart.py` (new) |

To regenerate, from the tool folder (change the script, never the picture):

    py wounds_sheet.py ..\..\art\body_wounds_20261122
    py wounds_gallery.py ..\..\art\body_wounds_20261122 ..\..\art\body_wounds_20261122\preview\wounds_every_part.png
    py d_chart.py ..\..\art\body_wounds_20261122
    py test_chart.py ..\..\..\42\media\lua\client\ZeD ..\..\art\body_wounds_20261122\preview\body_chart_review.png

- The first writes all 40 body textures, `_layout.lua.txt`, the wound pictures and their tables, and the review sheet.
  Only the two skeletons are staged from those 40, because the rest are unchanged.
- The second writes the every-part sheet.
- The third writes the chart's five pictures and `_chart.lua.txt`.
- The fourth runs the chart test on the mod's own Lua and writes the chart as drawn.

## Checked in Design's sandbox

- Main's five Lua files (`ab8bdfe49`), patched exactly as staged, compile under LuaJIT (Lua 5.1, as Kahlua).
- `test_body.py`: 0 failed. `test_wounds.py`: 188 checks, 0 failed. `test_chart.py`: 668 checks, 0 failed. All three
  ran from the staged scripts against the staged Lua.
- The tests catch a broken figure. Each of these 18 breaks fails its test:
  - test_chart: the script a pixel off; the floor drawn through the ruler's tick; Dark's ink on Light; a side's words
    held back when its lines just hold them; the lines a row low; the lines a pixel nearer the figure; Lite ignored; a
    table made each frame; the Health tab's chart call dropped; the script's strokes not lightened on their lines;
  - test_wounds: the bleeding moved a pixel; the bleeding's skin dropped; the cut lost; a wound getter read twice;
    the held-back rule lost; the cheat lost from the infection rule; a spent bandage called clean; bullet and glass
    swapped.
- `d_chart.approved`, the layout the test holds the game to, is the mock the director passed, alpha for alpha, at
  margins of 30 to 56 art pixels, both sexes. It differs only on the ruler's floor tick, where the mock's figure covered
  its own floor. Below 30 the mock cut the widest words short; the game shows a side's words whole where its lines hold
  them, and none where they don't.
- The staged pictures and tables are exactly what the staged scripts make: 290 pictures compared by pixel.
- The body tools Design started from are main's (`d_skeleton.py`, `test_body.py`, `physlib.py`, `engine.py`, compared
  without line endings), and main's 40 body textures are pixel-identical to Design's. Main has not changed them since.

On the PC:

- QA's 19 sims ran with the PC's lua51 on a copy of main at `ab8bdfe49` (`42/media/lua`, the body textures,
  `ZeDUI/tools/qa`, `ZeDUI/i18n` and ZeDUI's notes), in the design refs folder, not the repo.
  - All 19 pass on main's copy, and all 19 pass with the staged Lua and the six fitted sims.
  - With the staged Lua and main's sims as they are, the six of step 3 stop.
  - `drawer_tabs_perf_sim` against `ab8bdfe49` gives the numbers in step 5.
- Every staged file landed byte for byte (checked by hash). `git status` on the staged paths shows `d_skeleton.py`
  changed and the rest new. Nothing in 42/ is touched.
