# Session 124 delta — true UI scaling (Oct 13 2026)

Director brief: "ui scale next. BUT, I want true scaling. Adaptive to the resolution so really doesn't need to be adjusted. The font option is extra. The dream is everything scales not just the text." Approved: 1080p base, phase 1.

## Probes (live, stable 42.20.2, 3840x2160 rig) — Q138–Q140

- `ISUIElement:drawTextZoomed(str, x, y, zoom, r, g, b, a, font)` scales text continuously; `MeasureStringX * zoom` is the exact drawn width (underline rects matched at 1x / 1.37x / 2x / 2.5x / 3x). Bitmap atlases blur past ~1.4x.
- Distance-field text: `media/fonts/EN/fonts.txt` entries take `type = sdf` on ANY slot; shader `media/shaders/sdf.frag` thresholds alpha at 0.5. The engine's own SDF faces (Open Sans) zoomed 3x-4x stayed crisp. Vanilla atlases: BMFont, face size 32, padding 4, spacing -8, 512x512 pages numbered from 1.
- The engine font-size option (16px / 19px / 26px / 33px / 38px / "Scale with window height") does not change ZeD's bitmap slots - at option 2 the live `Small` slot measures the 1x face. It becomes the user's taste multiplier.
- `TakeFullScreenshot` writes an all-white frame while the fullscreen window is minimized (321,575-byte PNG).
- A browser-embedding route (the Fallout 4 HTML UI) has no equivalent here: no native plugin path for mods. The in-engine equivalent is one root scale in design units (CSS `rem`).

## Phase 1 — root scale + text engine

- `shared/ZeD/Scale.lua`: `ZeD.Scale.root()` = clamp(screenHeight / 1080, 0.75, 4) x user multiplier (`USER_MUL` by font option: 0.85 / 0.92 / 1.0 / 1.15 / 1.3 / 1.0), cached, refreshed every 30 ticks and on `OnResolutionChange`; `ZeD.Scale.px(units)`; `ZeD.Scale.override` for QA. `ZeD.Text.width / height / draw` wrap the zoom path and accept the rich font entries.
- `ZeD_Dashboard` / `ZeD_Watch`: `_scale()` reads the root scale (the text-size preset no longer multiplies in); `_text` draws through `drawTextZoomed` at the organism scale so glyphs follow the plates; `_measure` returns base units.
- Distance-field Fira: baker `ZeDUI/tools/fonts/bake_sdf.py` (Pillow + numpy, py -3.14) for the five roles sec / body / stat / head / title into `42/media/fonts/sdf/`; manifest entries `type = sdf` on the existing slots. (In progress - delegated.)
- Verification plan: forced root scale 1.0 / 1.333 / 2.0 captures of the sports-car dash + watch; then the same with SDF fonts after a restart (fonts load at boot).

## Phase 2 (next) — the windows

Survey: the Character and World windows read spacing and heights through `ZeD.T` tokens (269 token reads); literal pixels remain in window widths (372 + 36 + 36), strip and column sizes, and some molecules. Plan: scale the token table from the root (`titleBarH, rowH, buttonH, tabH, inputH, icon sizes, fillBarH, checkbox, sp.*`), route atom text through `ZeD.Text`, convert the remaining literals, verify at three scales with contact sheets.

## Also this session

- Health figure: the female thigh overlay files were named for the wrong side (each painted its thigh on the outer edge of its 120 px tile); swapped `f-thigh-l.png` / `f-thigh-r.png`. The male figure and the hit rects were already consistent: "-l" = the character's left, drawn on the viewer's right.
- Watch: thermo module on the digital LCDs, DigitalDress gold (S123 pass 5, commit 4c8693e6).
