# Library fixes reported by the phase 2 builders (collect, then one pass)

## From world (Oct 26 2026)
1. `Molecules.lua:2850` `drawSortStrip`, `:2929` `drawAltBackStrip`, `:3427` `drawCraftActionStrip` take no focus
   option, so callers' marks land after the words; `:2993` `drawRecipeRow` can't switch its words to `textOnFocus`.
   Pass a focus id / opts through to `drawButton` / `drawIconButton` and the words.
2. `drawRecipeRow` (~`:3070`, `:3103`): selected name drawn in accent; station tag a hand-drawn 14u box → default text on
   the selected wash, `M.drawTag`.
3. `drawSortStrip`: mode words in accent with an underline (web-style tab) → System 7 radio buttons or a pop-up menu.
4. `drawAltRow` (~`:3157`, `:3210`): 0.06 positive tint and the count in positive colour → selected wash / default text +
   square mark.
5. `drawSlotRow` (~`:3300`): the alternatives tag is a bordered warning pill → `M.drawTag` with a square mark.
6. `drawCraftActionStrip`: keep the band look, but give it the band's height, structure line and `Surface.fill`
   (`M.drawBand` has no stepper); the craft card's recipe name in accent → heading ink.

## From hud
- Hands' 3u condition ring (`ZeD_Belt.lua` wearColor / ringArc) and the action bar's 2u progress strip
  (`ZeD_ActionBar.lua` ~553, 567): waiting for the director.

## Strings to follow up (strings builder finished)
- Full stops / caps: `UI_ZeD_Furn_NothingToPlace`, `UI_ZeD_Furn_PointFurniture`, `UI_ZeD_Furn_PointBuilt`,
  `UI_ZeD_Forage_FindsEmpty` (caps).
- `TRANSLATING.md` and `ZeDUI/i18n/UI_ZeD.context.md` still say all-caps English is meant to stay caps.
- `ZeD.trDefaults` fallback tables in Lua files may still hold old caps text.
- `Chord_NotOnZeD` says "stay on Select" (names the pad button).

## From character-tabs
7. `Molecules.lua:1681` `drawStatRow` still upper-cases its labels (Health, Journal kills) → `ZeD.textCase`.
8. `Atoms.lua:1029` `drawProgressBand`: a bevel cancel key and its own bar → push / icon button + `A.drawFillBar`.
9. `drawSegBar` has no frame → an optional framed mode (frame + well, at least 8u), used by meters.
10. `drawMoreRow` needs a measure / closed-only option (Hair and beard draws its own copy because the open block can't
    be sized before layout); also prints "With  you could ..." when a lone hidden verb has no `needs`.
11. `drawGradientBar` has 0.5-alpha segments → solid.
12. `A.mouseIn` ignores scroll views (callers bind hover per view).

## From object-cards
13. `ZeD.Surface` has no claim-only call: add `Surface.claim(panel, x, y, w, h)` for library strips drawn on a card that
    draws its own body (object cards work around it with `UI.claim`).
14. Round hardware lamps must stay round: `drawStatusDot` is square now; add `A.drawLamp` (round, scan-line circle) for
    hardware and move lamp callers to it (belt lamp `ZeD_Belt.lua:1301` fixed by the session).
15. See-through: the item card drawer no longer hides the tab drawer under it (it was 0.98 opaque); covered content
    must not draw (Character builder doing its window; World window needs the same).

## From small-windows
16. `Organisms.lua` `ZeD_Window.update` (~1261): the close box always calls `self:close()`; add a `closeAction` hook
    (the prompt's close = its No; it works around with `P.updateChrome`).
17. `Molecules.lua:3507` `drawContextCell` active border uses `drawRectBorder` (1 screen px) → `A.frame(..., T.hair)`.
18. `ZeD_WindowMenu.lua:~91` check ink keyed on `lv.sel == ri` → `lv.inkRow == ri` (focus ink on a light hover wash).
19. `M.drawBand` has no slot for a checkbox on the left (Messages draws "Show popups" itself).

## Follow-ups in surface files (after the builders finish)
- Messages "Delete" (all notes, was "Clear") can't be undone: give it a question band (ZeD_MessagesWindow.lua).
- Strings: `UI_ZeD_Reader_EraseAsk` → "Erase page %1? Its words can't be brought back."; unused now:
  `UI_ZeD_Msg_Help`, `UI_ZeD_Reader_KeepIt`, `UI_ZeD_Seat_NumberGetOut`, `UI_ZeD_Sbx_PutBack`; object cards left 36
  unused Need*/Confirm* keys (see its report).
- Sandbox in game tag colours (five) may be more than the director wants.

## From character-core
20. `Molecules.lua` `_resolveStatValColor` (used by `drawFactsRow` and the stat rows) colours values by class
    (warn / bad / good) → default text + a square mark by class.
21. `drawCardFlagStrip` (~2385) and `drawProgressBand` take no focus option (the mark lands after the words) →
    `opts.focus` per chip and for Cancel.
22. `drawCardBackBar` gives its back button no `help`.
- Strings: `UI_ZeD_Inv_Empty` → a full sentence. Stack rows keep a text chevron "> Apple x6" (InventoryRenderer row):
  decide (a triangle atom would match the category rows).

## From main-menu
23. `ZeD_Surface.lua` `claim()` is not stencil-aware: a half-scrolled section head or tab claims its full rect and leaves
    a hole in the window body above its pane. Clamp claims to the active stencil (builders currently draw such heads only
    when wholly inside the list).
- Follow-up: `ZeD_SandboxInGame.lua:651` calls `UI.insetBox` in a scrolled row: pass `loose = true`.
- Kept on purpose: desktop icon labels (the director's desk), 34u big buttons on the main window, 450 ms double-click
  timers, the diff wash in ModsPanes, pop-up item marks with the tick.
