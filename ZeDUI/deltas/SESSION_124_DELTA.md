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

### Phase 1 verified (Oct 13, live)
Forced root scale 1.0 / 1.333 / 2.0 on the sports-car dash and the digital watch (`ZeDUI/qa/S124_scale/`): dash 800x172 -> 1066x229 -> 1600x344, watch 124x176 -> 165x234 -> 248x352, every overlay and label in place at each scale, zero errors. With the override cleared the rig's natural root is 2.0 (2160 / 1080, font option 26px = neutral), so the HUD props now draw at 2x on the 4K screen by default. Remaining softness in 2x text is the bitmap atlas; the distance-field Fira atlases replace it (baker running).

### Phase 1 text engine verified (Oct 13, live, commit dec84360)
- Five Fira roles baked as distance-field atlases (`ZeDUI/tools/fonts/bake_sdf.py`, Opus 5.5 subagent): 64 px face, spread 2, 512x512 pages (ASCII on page 1), 200 glyphs each. Slots: body=MainMenu1, sec=MainMenu2, stat=Title, head=Massive, title=Cred2 (`type = sdf`); `MediumNew` ignores the manifest. The windows keep the bitmap slots until phase 2.
- Finding (Q141): `drawText`/`drawTextZoomed` never bind the engine's SDF shader (only the PZAPI text atoms and the world map do), so the atlas ramp is blended raw and softens with zoom. A 32 px / spread 4 bake was crisp only at ~0.4x; the 64 px / spread 2 bake measures near-ideal anti-aliasing at 13 and 26 px, and live captures at root 2.0 and 1.0 show crisp readouts, labels and watch digits.
- Wrinkle to fix: lit preset labels (drawn as 9 px F5 over the plate's 4 px silkscreen) ghost against the baked label; cover the button face before the lit text or match the silkscreen size now that text scales.
- Ghost fixed: lit head-unit labels now repaint the button face (`face` colour recorded in the btn anchors by the generator, DashPlates regenerated; plates unchanged) before the lit text. Verified live on the Cossette console at root 2.0.

## Phase 2 — the windows (Oct 13, in progress)

Infrastructure (done, live at root 2.0 with zero errors):
- `ZeD.applyTheme` now builds the token table from the root: `T.scale` = root x preset, `T.px(units)`, every px token pre-scaled (titleBarH, rowH, buttonH, tabH, inputH, icons, fillBarH, checkbox, closeBox, statIcon, contentPad, colGap, cardIcon, contextRowH, modal, minWin), scaled copies of `ZeD.Spacing` (T.sp) and `ZeD.Ctx` (T.ctx, counts and ms excluded); the five role fonts point at the distance-field slots with `T.fontPx` / `T.fontFace` per UIFont; font heights are cached after the palette goes live; `ZeD.Scale._appliedRoot` + a tick hook re-apply the theme when the root changes.
- `Overrides/TextScale.lua`: `ISUIElement.drawText / drawTextRight / drawTextCentre` route the ZeD role fonts through the zoom path (`ZeD.Text.zoomOf` = px x root / face); vanilla fonts untouched, so the vanilla UI keeps its bitmap Fira.
- `ZeD.TM` (shared/ZeD/Scale.lua): every `getTextManager()` in the mod's 26 files was rewritten to this proxy, which scales MeasureStringX / MeasureStringY / getFontHeight for the role fonts and passes everything else through. AnimalsTab's 78 `UIFont.Small` literals became `ZeD.T.fontF2`.
- Captures: `qa_win2_200.png` (text + tokens at 2x, frame still 720x420 and strips 36 px) vs `qa_win2_100.png`.

Literal conversion (four subagents, disjoint file sets): window chrome + persistence (Character/World windows: strip widths, drawer widths, the 372 default, `ZeD_WinState` in design units), core library (Molecules, Atoms, AtomExtensions, Panel, ZoneList, Organisms, ContextMenu, Settings, Tooltip), tabs A (Animals, Radio, Journal, Identity, Health, Thermal, Protection, BodyFigure, Skills), tabs B + cards (CraftingCore/Tab, Building, Maps, Foraging, Equipment, ItemCard(+Organism), ItemFactsPanel, InventoryRenderer, TestInventory, KillTracker). Rule: px literal -> `T.px(n)`; counts/alphas/ms untouched; native texture draws -> drawTextureScaledAspect at T.px size.

### Phase 2 verified (Oct 13, live, commit 88602296 + follow-ups)
- All four agent passes merged: ~1,350 pixel literals / constant uses now go through `T.px(...)` (window chrome 362, core library ~535, tabs A ~506, tabs B + cards 590). Every file passes the game's own Kahlua compiler (`scratchpad/kcheck/KCheck.class`, compile-only, built from projectzomboid.jar by the tabs-B agent) and the save reloads with zero errors.
- Tab walk at the natural root 2.0 (`ZeDUI/qa/S124_windows/`): all 7 Character tabs and 6 World tabs render scaled and crisp; the loot pair is 888x840 (444x420 design), a drawer tab 1848 wide. Persisted geometry and `_baseInvW` are design units; old saves (written at scale 1.0) read back unchanged.
- Follow-ups applied: `Overrides/TextScale.lua` also replaces `drawRectBorder` with four `T.px(1)` rects for ZeD classes (flagged `zedScaled` on the 19 ZeD classes at load and OnGameBoot), so borders scale while vanilla panels keep the engine call; `T.borderW` stays design units (wrapped at use, as the core agent did); the licence name (IdentityTab) and the radio frequency (RadioTab, 30 px) draw free-size on the distance-field heading face via `ZeD.Text.zoomPx`.
- Root change at runtime: `ZeD.Scale` closes the open pair first (its close path persists geometry divided by the old scale), re-applies the theme, then reopens the pair three ticks later; verified live 888x840 -> 444x420 -> 888x840 with the forced override.
- Pre-existing, not from the conversion (noted by the agents, left alone): `CraftingCore.renderCraftCard` reads `mx`/`my` before declaring them (HOW TO LEARN path); `AnimalsTab:1033` passes a number where `drawTriangleLeft` wants a colour table; the loot CAT column truncates "Container" at every scale; the vanilla map inside the Maps tab draws its labels at the engine's own scale; `Overrides/Tooltip.lua` keeps vanilla px in vanilla's `doLayout` frame; the context menu's moodle allowance (140) follows the vanilla HUD.

### Two agent-flagged bugs fixed (Oct 13)
- `CraftingCore.renderCraftCard`: the HOW TO LEARN hover test read `mx`/`my` 40 lines before their `local` declaration (nil globals -> compare error on that path); the declaration is hoisted to the top of the card body and the late duplicate removed.
- `AnimalsTab` breadcrumb: `drawTriangleLeft` was handed four numbers; it takes one colour table (`{ r, g, b, a }`).
- Both compile-checked; smoke walk of all 13 tabs clean after a hot-load. Caution learned: a file edited while the game sits at the main menu was NOT picked up by quit-to-menu + CONTINUE (the stale chunk kept running; the debugger's source pane shows the disk file, so line numbers looked one off) - hot-load through the bridge or restart to desktop after editing at the menu.
