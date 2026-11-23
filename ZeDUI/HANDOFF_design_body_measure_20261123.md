# Handoff: Design to Build, the body figure's measure stops at the head (Nov 23 2026)

Nothing in 42/ was touched, and nothing is committed: Build installs, commits and runs the checks. Everything is staged
in `ZeDUI/art/body_measure_20261123/`: the art, the three Lua files as Design tested them, eight of QA's files fitted to
them, and four previews. The six tool scripts this changes are installed in `ZeDUI/tools/physpx/`.

**Made against main at `d4440db66`, Nov 23 10:22.** The work started at `d25cb62ae`; of the files it touches, only
`gc_cleanup.lua` and `FEATURE_MAP.md` changed since, and their fits are made on the 10:22 copies. Each staged file is
main's own copy with this handoff's changes applied, in main's line endings. If `git diff d4440db66 -- <file>` prints
nothing for a file, copy the staged one over it. If it prints anything, apply that file's `.diff` with
`git apply --ignore-whitespace`.

## The director's calls

The notes, verbatim:

> (09:36) remove the notes, move the skelly up the measure will stop at their height. reason, not filling the space
> with useful info.

> (09:50) handoff please. great job

09:50 passed the mock, him and her, Dark and Light, beside the figure as it is now:
`preview/figure_chart_no_script_mock.png`. Design read the note as four changes:

1. **The notes go:** the old script beside each part (Nov 22), all of it.
2. **The measure stops at their height:** the ruler's rail ends at the top of the head. His is 5'9", hers 5'8". No 6'
   tick and no 6' number; the feet are numbered 1' to 5'.
3. **The chart's lines stop there too.** They run up to 5'6", the last half foot under both heads. Both figures share
   the lines' picture, so the lines stop where both heads are above them.
4. **The skeleton moves up:** the 18 empty rows above his head are cut. The canvas goes from 106 x 272 to 106 x 254,
   with 4 rows over his head and 8 over hers.

## What the player sees

On the Health tab, the Thermal tab, the Equipment tab's defense view and the medical check card:

- **The figure sits higher in a shorter frame.** The frame loses 18 art pixels: 36 px at 4K, 18 at 1080p and on the
  Steam Deck. Everything under it on the tab moves up as much.
- **The ruler runs from the floor to the top of the head,** with a tick every half foot below it. The rail's end is the
  only mark of the height: no line and no number says it.
- **The lines out to either side, eleven a side now,** stop at 5'6". The floor runs right across under the feet as
  before.
- **No script anywhere,** in Full or Lite.
- **Nothing else changes.** The bones, the flesh, the parts, the wounds and their care, the tints and every hit area are
  the same pictures and rects, moved up 18 rows. Lite still draws the chart, as `611f5f729` made it.

`preview/body_chart_review.png` is the chart as the game draws it: test_chart.py's own render, from the staged Lua. It
shows the Health tab at 4K (him and her, Dark, Light, High Contrast), the medical card at 220 and 336, and the Health
tab at 1x.

## How it draws

`ZeD_BodyFigure:drawChart(panel, L)` makes four draws at most, and no table:

1. **The lines:** one picture, `fig-chart-lines.png`, a 1 x 254 column with each line's alpha on its row, stretched
   along each margin with `drawTextureScaled`.
2. **The floor:** two rectangles, either side of the ruler's floor tick (`floorGap`).

The script's code is gone: `NOTE_NAMES`, the two script draws, and `noteA` and `notes` in the `CHART` table. The rest
of `drawChart` is untouched, Lite included.

## Build's work

1. **Install the art:** the 40 body textures and the lines' column, then remove the four script pictures.

       Copy-Item ZeDUI\art\body_measure_20261123\42\media\textures\ZeD\body\*.png 42\media\textures\ZeD\body\ -Force
       git rm 42/media/textures/ZeD/body/fig-notes-*.png

   That is 41 PNGs, all 106 x 254 but the 1 x 254 column.
   - **The 283 wound pictures don't change.** The staged tools make them byte for byte as main has them.
   - **Three tables stay in the stage:** `_layout.lua.txt`, `_chart.lua.txt` and `wounds/_wounds.lua.txt`. They are
     the generated tables, already in the Lua.

2. **The Lua.** Three files are in `ZeDUI/art/body_measure_20261123/lua/`, each with its `.diff`. Copy or apply as the
   note at the top says.
   - **`ZeD_BodyFigure.lua`:**
     - The header says 106 x 254 and the chart without the script.
     - `CANVAS_H = 254`.
     - The generated tables, swapped whole for the new ones:
       - `M_HITS`, `F_HITS`: every rect 18 rows up;
       - `M_HITMAP`, `F_HITMAP`: 9 cell rows shorter, the empty ones at the top gone;
       - the wound tables, every row 18 less;
       - `CHART`: the eleven rows, the floor at 251, no `noteA` or `notes`.
     - THE HEIGHT CHART's header quotes the 09:36 note, `NOTE_NAMES` is gone, and `drawChart` ends at the floor.
     - The rest is untouched: `_drawWounds` and its `pairs` loop, `woundsFrom`, Lite.
   - **`Tokens.lua`:** `figureH = 254`. The frames and the tabs take it from there (`T.sp.figureH`).
   - **`Molecules.lua`:** one comment, the canvas's size.

3. **The tools.** The six changed scripts are installed in `ZeDUI/tools/physpx/`, and each has its `.diff` in the
   stage's `tools/`. Remove the old script maker, which nothing imports now:

       git rm ZeDUI/tools/physpx/d_script.py

   - **`d_skeleton.py`:**
     - `FH = 254`, `DY = -2`.
     - `head_top(sex)` is new. `ruler(sex)` runs the rail to the top of the head, with no tick at or above it.
     - `RULER_TOP_FT` is gone.
   - **`d_chart.py`:**
     - No script: no `d_script` and no `notes`.
     - The lines are the ruler's ticks under both heads. It stops if the two figures would want different lines.
     - It exports the column and `_chart.lua.txt` only.
   - **`d_wounds.py`:** the dirty gauze's noise now lies on the body (`DIRTY_NOISE`), not on the frame. Moving the frame
     would otherwise have redrawn the blood's edge on all 34 dirty bandages. With it, all 283 wound pictures come out as
     main has them.
   - **`test_chart.py`:**
     - no script picture drawn or asked for;
     - four draws at most;
     - his chart and hers the same draws;
     - Lite draws the same chart as Full;
     - the measure: the rail ends at the head, the ticks are the floor and the lines, nothing above the head, him 5'9"
       and her 5'8" at rows 4 and 8;
     - the canvas is 106 x 254 in `ZeD_BodyFigure.lua` and in `Tokens.lua`;
     - a picture the tools don't make fails a check instead of stopping the test.
   - **`test_body.py`, `test_wounds.py`:** the panel under 1x is now half the canvas high (0.5), as 204 of 272 rows was
     0.75.

4. **QA's files.** Eight are in `ZeDUI/art/body_measure_20261123/qa/`, each with its `.diff`, for Build or QA to take
   in.
   - **The two in-game scripts need theirs:**
     - `gc_cleanup.lua` checks the real tokens and the drawn background against 106 x 272, so it fails on the new
       figure without the fit.
     - `vk8_wounds.lua` expects words where the lines hold them, both sides on the Health tab, and the words on the 220
       card. The fit reads the chart as the lines and the floor, and fails on any `fig-notes-*` picture or a fifth draw.
   - **The five sims pass either way.** They stub their own tokens, so the fits only keep their numbers the figure's:
     `figure_frame_sim`, `fix_tabfill_sim`, `gc_qa_cleanup_sim`, `trade_medic_sim`, `strain_tint_sim`.
   - **`FEATURE_MAP.md`:** the chart's row says what it is now. It also drops "Lite: none", stale since `611f5f729`.

5. **Run the checks.**

       py ZeDUI\tools\physpx\test_body.py
       py ZeDUI\tools\physpx\test_wounds.py
       py ZeDUI\tools\physpx\test_chart.py

   Expect "0 failed" from all three: test_body runs 116 checks, test_wounds 188, test_chart 663.
   - **Main's own `test_chart.py` fails one check today:** "Lite: no chart", since `611f5f729`. The new one checks that
     Lite draws the same chart as Full.
   - **Then QA's sims,** as usual with lua51. Design ran these 21 on a copy of main at `d4440db66`. All pass on main's
     copy, with the staged Lua and the fitted sims, and with the staged Lua and main's sims:
     `figure_frame_sim`, `trade_medic_sim`, `woundsov_sim`, `perf_throttles_sim`, `tab_search_sim`,
     `fix_tabfill_sim`, `drawer_tabs_perf_sim`, `gc_qa_cleanup_sim`, `strain_tint_sim`, `status_colors_sim`,
     `hint_strip_cover_sim`, `b8r3_sim`, `chip_dot_sim`, `director_review_fixes_sim`, `fix_shared_misc_sim`,
     `g4_character_tabs_sim`, `item_meter_sim`, `rows178_sim`, `tab_fill_sim`, `card_title_fit_sim`,
     `object_card_fill_sim`.
   - **`drawer_tabs_perf_sim` against main** (`d4440db66`) gives the figure's tabs two draws fewer a frame, two fewer
     Java calls and, with the pointer away, 238 fewer Lua instructions:
     - Thermal: 218 -> 216 draws a frame;
     - Equipment's list: 200 -> 198;
     - Equipment's doll: 365 -> 363.

     Its checks against main fail in two ways, both expected:
     - **"draws the same as before" fails on every Thermal and Equipment view.** The script's draws are gone, and
       everything under the figure draws 36 px higher at 1.75 (Thermal's first draw to differ: y 657 -> 621).
     - **"no more memory a frame" fails once, on Thermal with the pointer over: 13.90 -> 13.96 KB.** The sim's pointer
       walks a fixed path down the card, and with the rows 36 px higher it passes over different ones.
       - A control run shows it is the layout, not the chart: the staged Lua with only `figureH` left at 272 (the
         frame at its old height) passes that check, 13.9 KB a frame as on main.
       - That control fails only the "draws the same" checks: the shorter lines' column and the script.
     - With no base it passes (76 checks).

6. **After it ships,** Design updates the ZeD-GUI Design System's BodyFigure card: the chart without the script, and the
   canvas.

## QA

Run these at 4K with UI scale 1.75 (window layout reset first) and on the Steam Deck (1x).

### The measure: Health, Thermal, Equipment's defense view, the medical check card

- [ ] The ruler's rail ends at the top of the head, him and her: no tick, number or line above it. The feet are
      numbered 1' to 5'.
- [ ] The lines out to either side stop under the head, at 5'6", on both figures. The floor runs right across under
      the feet, and the ruler's floor tick looks as it did.
- [ ] No script on any figure, in Full or Lite.
- [ ] The figure sits higher: over the head there is only the frame's inset and a sliver of canvas (4 art pixels
      over his head, 8 over hers), where the ruler used to run on past 6'.
- [ ] Everything under the figure sits where it should, with no gap or overlap: Health's rows, Thermal's grid,
      Equipment's list, the medical card's text.
- [ ] Dark, Light, High Contrast and a change of accent: the ruler and the chart take the ink and tint as before.

### Unchanged, moved up with the figure

- [ ] Every part tints, hovers and selects where its bones are: mouse, pad A and the focus boxes.
- [ ] The wounds and their care sit on the right parts: a cut on the brow, gauze on a thigh, boards on a shin.
- [ ] `gc_cleanup.lua` and `vk8_wounds.lua` (fitted) pass.

## Files

| What | Where |
|---|---|
| The 40 body textures and the lines' column | `ZeDUI/art/body_measure_20261123/42/media/textures/ZeD/body/` |
| The generated tables | `_layout.lua.txt`, `_chart.lua.txt` and `wounds/_wounds.lua.txt`, beside the pictures |
| The three Lua files as tested, and their diffs | `ZeDUI/art/body_measure_20261123/lua/` |
| Eight of QA's files, fitted, and their diffs | `ZeDUI/art/body_measure_20261123/qa/` |
| The six tool changes as diffs | `ZeDUI/art/body_measure_20261123/tools/` |
| The mock as passed; the chart as drawn; the wounds review; every part's wounds | `ZeDUI/art/body_measure_20261123/preview/` |
| Scripts | `ZeDUI/tools/physpx/`: `d_skeleton.py`, `d_chart.py`, `d_wounds.py`, `test_chart.py`, `test_body.py`, `test_wounds.py` (changed); `d_script.py` to remove |

To regenerate, from `ZeDUI\tools\physpx` (change the script, never the picture):

    py wounds_sheet.py
    py wounds_gallery.py out\mod\ZeD-UI ..\..\art\body_measure_20261123\preview\wounds_every_part.png
    py test_chart.py ..\..\..\42\media\lua\client\ZeD ..\..\art\body_measure_20261123\preview\body_chart_review.png

- The first writes everything into `out\mod\ZeD-UI`: the 40 body textures and `_layout.lua.txt`, the wound pictures
  and their table, and the review sheet (`preview\body_wounds_review.png` there).
- The second writes the every-part sheet.
- The third writes the lines' column and `_chart.lua.txt` (it runs `d_chart.py`), checks the mod's own Lua, and writes
  the chart as drawn.

## Checked in Design's sandbox

- Main's three Lua files, patched exactly as staged, and QA's eight fitted files compile under LuaJIT (Lua 5.1, as
  Kahlua).
- **The three Python tests pass from the staged scripts against the staged Lua,** in a tree laid out as the repo:
  test_body 116 checks, test_wounds 188, test_chart 663, 0 failed each.
- **The tests catch a broken change.** Each of these 10 breaks fails its test:
  - main's Lua and tokens as they are;
  - `CANVAS_H` left at 272;
  - `figureH` left at 272;
  - `drawChart` skipping Lite;
  - the floor drawn through the ruler's tick;
  - a script picture drawn again;
  - the ruler back up to 6 1/4 ft (the tool refuses it);
  - the rail run up to the canvas's top;
  - the lines carried on to 6 ft;
  - the frame's top 2 rows lower, caught by both test_chart and test_body.
- **The staged pictures and tables are exactly what the staged scripts make:** 41 pictures by pixel, 3 tables by text.
  The tables in the staged Lua are those.
- **The figure is main's, moved up:**
  - The 34 parts and the 2 skeletons are main's pictures moved up 18 rows, pixel for pixel, and main's are pixel for
    pixel what main's tools make.
  - The 4 backgrounds differ from main's moved up only in the rail above the head. The 18 rows cut off held the rail's
    top, the 6' tick and its number.
  - The hit rects and the wound tables are main's, 18 rows up. The hit maps are main's, less the 9 empty cell rows at
    the top.
- **The mock re-renders exactly from the staged tools** and `Molecules.lua`: 8 tiles, 4K and 1080p, him and her, Dark
  and Light, with no pixel different. test_chart holds the game's drawing to that layout within one level in 255.
- **`vk8_wounds.lua`'s fitted chart reading, run outside the game on the real `drawChart`:**
  - The staged Lua passes it everywhere the script looks: the Health tab and the medical card at 336 and 220, at 4K,
    1080p and 1280x800, him and her (36 checks).
  - Main's Lua, with its script, fails 24 of them.

On the PC:

- QA's 21 sims ran with the PC's lua51 on a copy of main at `d4440db66`. The copy held `42/media/lua`,
  `ZeDUI/tools/qa`, `ZeDUI/i18n` and ZeDUI's notes, in the design refs folder, not the repo.
  - All 21 pass on main's copy, with the staged files, and with the staged Lua and main's sims.
  - `drawer_tabs_perf_sim` against `d4440db66` and the control run gave the numbers in step 5.
  - The logs are in `ZeD_design_refs\body_measure_20261123\sims\`: `base6.log`, `patched6f.log`, `patched6u.log`,
    `perf6f_vs_main6.log` and `perf_ctrl6_vs_main6.log`.
- Every staged file landed byte for byte (checked by hash). Nothing in 42/ is touched.
