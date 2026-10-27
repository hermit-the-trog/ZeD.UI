# Cohesion phase 2: moving every surface onto the library (Oct 26 2026)

Read `COHESION_SPEC.md` first (the contract). This file lists the library APIs the phase 1 builders made and the rules
for moving a group of surface files onto them. Evidence for every finding (file:line): `ZeDUI/audits/COHESION_2026-10-26_*.md`.
Mockup: `ZeDUI/mockups/zed_cohesion_v1.html` (its JS draws the intended looks).

## Rules for every phase 2 builder

- Work only in `C:\Users\danie\ZeD-cohesion` (branch `cohesion`). Never touch `C:\Users\danie\Zomboid\mods\ZeD-UI`.
  Never launch the game. Never commit. Edit only the files of your group; if a fix needs another file, list it.
- Library files are finished for this phase (`Atoms.lua`, `AtomExtensions.lua`, `Molecules.lua`, `Organisms.lua`,
  `Input/FocusManager.lua`, `ZeD_FocusPaint.lua`, `ZeD_Surface.lua`, `ZeD_WindowMenu.lua`, `Tokens.lua`, `Settings.lua`):
  do not edit them; report a library bug with file:line and a suggested fix instead.
- **Do not edit `42/media/lua/shared/Translate/EN/UI.json`** (one builder owns it this phase). New strings: call
  `ZeD.tr("UI_ZeD_<Area>_<Name>")` and write each new key with its English text into
  `ZeDUI/i18n/pending_<your group>.json` (a flat JSON object); the session merges them. Caps strings already in UI.json
  are being fixed by the strings builder; your job is the caps that code makes (`string.upper`, `:upper()`, literal caps
  passed to draw calls).
- **Careful:** the item card dispatches verbs on their caps label: convert case at draw time only, never rewrite the
  source strings that code compares (search for comparisons before changing any label).
- Every length through `T.px` / `T.sp` / tokens; read `ZeD.T` fresh each frame; Kahlua: under ~150 locals per function,
  hoist forward declarations; keep behaviour (what a press does) unchanged unless the spec says so.
- Parse every edited Lua file with the game's compiler (KCheck; see `COHESION_SPEC.md` section 14) and run
  `ZeDUI/tools/qa/i18n_guard.py` (it will flag your pending keys as missing until merged: list them, that is expected).
- Comments: plain English, the why, matching the file's density; no session numbers.

## Library APIs (phase 1)

Window and surfaces (window builder):
- `ZeD.Surface.fill(panel, x, y, w, h, tokenName)`: draws `T[tokenName]` (default "surf2") at the window's see-through
  alpha and claims the rect so the window body is not drawn under it (no stacking). Use it for every band, header,
  strip or pane fill inside a window instead of `drawRect` with a `surfN` token or a literal alpha.
- `ZeD.Help.set(panel, text)`: the footer help line shows this plain-words text this frame (call while the pointer is
  over the thing). Words: what it is and what a press does ("Equip: put it in your hands").
- Window footer prompts: a window outside FocusManager returns them from `win:getFooterPrompts()` (pad-gated).
- Settings: `ZeD.Settings.focusStyle()`, `.hiddenActions()` ("folded" | "all" | "hide"), `.seeThrough()`, `.solidInUse()`.
- `ZeD_Window` now draws the frame last (overlay child), the window box, the 22u help line, resize zones.
  Small windows that set `themeFooter = false` (Prompt, Keyboard, Messages, Reader, Seat chooser, Station pop-out) must
  drop that flag, add `self:footerHeight()` to their height (Prompt ~872, Messages ~134, Seat ~277, Reader ~134/145,
  Keyboard ~288, Station ~100), remove their own prompt strip and turn `stripPrompts()` into a pad-gated
  `getFooterPrompts()`.

Focus, controls, text (focus builder):
- `ZeD.Focus.mark(panel, x, y, w, h, {win, solid, zone, focused, pad})` returns true when the element's words must switch
  to `T.textOnFocus`. Call it after the element's fill, before its words, only for the focused element. `win` defaults to
  the panel's window; surfaces with their own focus model pass `focused = true`; the main menu passes `pad = MM.gamepad()`.
- `ZeD.Input.Focus.isFocused(win, zoneName?, elementId?)` (also `liveZone(win)`, `liveElement(win)`, `cuesVisible()`):
  use it instead of `getFocusedZone(win)` for any paint decision (the old call answers for unfocused windows too).
- `ZeD.Focus.drawOverlay(panel, win)`: HUD panels without a window overlay (belt, dash) call `drawOverlay(self, self)` at
  the end of their render.
- `M.drawButton(panel, x, y, w, h, text, variant, pressed, colors, {hover, disabled, compact, focus, help, win, font})`
  returns x, y, w, h. `M.buttonW(text, opts)`. Variants: "default", "primary", "danger".
- `M.drawIconButton(panel, x, y, size?, texOrFn(p, x, y, s, color), {hover, active, disabled, pressed, focus, hint, id,
  help, win, iconSize, tint})`; `M.drawBackButton(panel, x, y, size, opts)`.
- `A.drawCheckbox`, `A.drawRadio(panel, x, y, on, {hover, disabled})` (returns size), `ZeD_Dropdown` for one-of-many.
- `M.drawBand(panel, x, yTop, w, {status = {text, color} | question, buttons = {{label, variant, disabled, hover, focus,
  help, id, minW}, ... main last}, icons = {...}, win, noLine})` returns H and `{buttons, icons}` rects. `M.bandH()`.
  `M.drawQuestionBand(panel, x, y, w, question, verb, {danger, cancelFocus, verbFocus, win})` returns H, cancelRect,
  verbRect.
- `M.drawNeedsLine(panel, x, y, w, text)`, `M.drawEmptyLine(panel, x, y, w, text)` return heights.
- `M.drawTag(panel, x, y, text, statusColor?, opts)` returns w, h. `A.drawBadge` already draws the tag look in place.
- `A.drawStatusDot` / `drawStatusHollow` / `drawStatusHalf`: 6u squares.
- Headings: `M.drawTabHeader(..., opts{focus})`, `M.drawSectionHeader(..., opts{focus})` (20u default, sentence case),
  `M.drawCategoryRow(panel, x, y, w, text, count, expanded, {hover, focus, noArrow, bleedLeft, inset})` (15u),
  `M.drawTab(..., opts{font, focus})` for sub-tab strips.
- Hover boxes: `A.requestHint(win, key, text, panel)` / `M.drawHint`; detail card `A.requestDetailCard(win, key, {title,
  lines = {"text" | {text, font = "F2"|"F3", color}}, maxW, exact}, panel)` / `M.drawDetailCard`. `A.hoverReady(state,
  key)` for surfaces that keep their own timer; `ZeD.HINT_DELAY_MS` (450) replaces every local 450 constant.
- Hidden actions: `ZeD.Disclose.split(verbs, setting?)` (verbs carry `canDo`, `needs`, `sensible`, `hint`) returns
  shown, hidden; `M.drawMoreRow(panel, x, y, w, hidden, key, {hover, focus, inset, win})` returns height, rowRect,
  verbRects; `ZeD.Disclose.toggle(key)`, `.isOpen(key)`, `.needsLine(v)`. Hints name only what the game itself shows.
- Helpers: `A.windowOf`, `A.surfaceFill`, `A.drawHardShadow`, `A.mouseIn`, `A.textCase` / `ZeD.textCase`.

## What each group does (all of it applies to its files)

1. **Focus:** replace every old focus look (0.55 rect, rings, outlines, ring + fill, 0.30 tab wash) with
   `ZeD.Focus.mark`; gate paint on `Focus.isFocused(win, zone, id)`; words switch to `T.textOnFocus` only when `mark`
   returns true. Words are never painted under a wash: draw the cue first.
2. **Hover:** `T.hover` on every pressable row, button, tab, slot, header (list rows and card buttons gain it); call
   `ZeD.Help.set` with plain words while hovered.
3. **Selected:** the `T.selectionA` wash only; remove side bars, solid selection fills, borders.
4. **Buttons:** library push buttons / icon buttons / back button; no bevel keys outside hardware plates; no hand-rolled
   buttons; System 7 checkbox / radio / dropdown for choices (no switches, pills, segmented pairs; List / Grid and List /
   Doll as two separate icon buttons 4u apart, the active one solid).
5. **Bands and questions:** every action footer becomes `M.drawBand`; every question before an irreversible act becomes
   `M.drawQuestionBand` ("<Verb> the <thing>? <What is lost>.", Cancel + the verb, danger when it can't be undone);
   Journal entry delete gains one; Animals' Yes / No and Vehicle's Yes / No become Cancel + the verb.
6. **Hidden actions** on the first surfaces (item cards, object cards, Vehicle part cards, Hair and beard, Animals, tab
   bands): verbs through `ZeD.Disclose.split` + `M.drawMoreRow`; nonsensical verbs gone; empty bands not drawn.
7. **NEEDS, tags, headings, empty lines, hover boxes:** onto the library parts (spec section 9).
8. **Caps:** no all caps made by code in your files (section heads, labels, tags, status words, column heads) except
   hardware plates and the pixel faces; sentence case through `ZeD.textCase` when the text arrives in caps.
9. **Status:** coloured status words become default text + a square mark (`A.drawStatusDot`).
10. **Line work:** nothing draws over the window frame (no dividers across the title bar or help line, no full-height
    `win.render` dividers that cross them); pane dividers and band tops are 1u `T.borderS` meeting the frame; content
    lines 1u `T.border`; fills via `ZeD.Surface.fill` (no literal alphas, no `drawRect` of a surface token over the body).
11. **Shared timers / delays:** `ZeD.HINT_DELAY_MS`.
12. **Words:** spec section 11 (Delete / Remove / Undo changes / Discard changes / Choose, US spelling, sentence case,
    no button letters in running text) for strings your code builds; UI.json is the strings builder's.

## Report (final message, under 1,000 words)

Per file: what moved onto which part; anything not done and why (file:line); library bugs found; pending string keys
written (count and file); KCheck results; behaviour you were unsure you kept.
