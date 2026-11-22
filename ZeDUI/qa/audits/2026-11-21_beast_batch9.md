# Beast day, batch 9 (Nov 21 2026, QA): Steam Deck size

From the 15 stress scripts at 1280x800 (a window, ZeD's UI scale Auto = 0.75, Small text), 19:15-19:42 on b7809b732
(reports ZeDUI/qa/regression/2026-11-21_bx_g?dk_deck.md). 12 of the 14 in-game scripts pass every check at this size;
these two are the rest. Each traced by one agent and confirmed by a second. Both pass at 4K, and both are in the live
v0.3.0-beta21b (the files are unchanged since).

### B9-1 On a Steam Deck the moodle column runs off the bottom of the screen (fix first: a player loses warnings)

- What the player meets: moodles on the right (ZeD's default, Settings.lua:234), a screen about 800 px tall: the
  column starts under ZeD's corner watch and only 9 moodles fit (at the game's medium 48 px) before the belt line. The
  10th runs below the belt line, the 11th is half off the screen, the 12th is not shown at all (with the game's large
  64 px moodles it runs off at 9). These are the game's own moodles, in the game's shuffled order: the lost one can be
  Bleeding or Hypothermia, with nothing to say so; a pile usually means a crisis. Left side, the bottom row and 4K fit.
  The game alone fits 11 whole on this screen.
- Where: ZeD_Moodles.lua ZeD_MoodleLayer:_place (338-371): line 349 centres the stack, 352 lifts it to end above the
  belt, 353 pushes it back under the watch, and 353 runs last, so a stack taller than the room runs from y 194 to 880 on
  an 800 px screen. _rightY 272-281 (watch bottom + px(10)), _rowY 257-269 (belt top - px(12)); keepOnScreen is off on
  purpose (:247); the game's column only stacks straight down (13-14; KNOWLEDGE-BANK Q198), so moving it cannot wrap.
  Run: bx_g3dk_deck.md:621-622, 628 (right 1222,194 48x686 FAIL); :613 left and :617 bottom pass.
- Fix: in _place, for right and left: perCol = max(1, floor((self:_rowY(0) - minY + 10) / (size + 10))). Up to perCol,
  nothing changes. Past it: move the game's column off screen (as the bottom row does, :323, setY(-10000)) and draw
  ZeD's copy (_drawMoodle, 404-415, as _drawRow does) from prerender (:572) in ceil(n / perCol) columns from minY, each
  column top to bottom in the game's order, the first at the screen edge and each next one size + 10 further in. The
  layer is cols x size + (cols - 1) x 10 wide and perCol slots tall; _hoverIndex (386-401), _drawBalloon (626-631) and
  _drawChipRaw (478-500) find a moodle by column and row; add cols and perCol to _rect (:370) so the Moodle Quarters
  support (ModSupport/moodle_quarters.lua 144-160) lays its plates the same way. On a Deck at 48 px: 9 + 3. Safety net
  after :353: y = min(y, screen top + screen height - stackH). (Shrinking would override the game's Moodle size setting;
  starting higher runs under the watch.)

### B9-2 On small screens a window comes back wider than it was, from Save position and from a reopen

- What the player meets: on a Steam Deck (1280x800, Auto, Small) the Character and World windows open 276 px wide (#150,
  so a full card fits beside them; 1280x720 the same, 1366x768 a 14 px jump). Park one in a bottom corner, Save position,
  move it, Go to saved position: it comes back 57 px wider (333 px); the Character window keeps its left edge on the
  screen edge and reaches 57 px further, the World window keeps its right edge and its left moves 57 px in (1004 -> 947).
  The same happens with no menu at all: leave a window in a corner, close the inventory and open it again (or load the
  save), and it opens 57 px wider (the same restore). Elsewhere on these screens the restore narrows to the room at the
  saved place (down to 204 px), not back to the width the window had. 1080p and 4K never narrow, so they come back exact.
- Where: save ZeD_WindowPlaces.lua 140-148 via charStateOf (ZeD_CharacterWindow.lua 182-192) and worldStateOf
  (ZeD_WorldWindow.lua 2610-2620): while the window is at the narrowed 296 units (276 px) they write the 444-unit width
  it started from (#150 on purpose, PUNCH_LIST.md 4077-4100, so a bigger screen gets the usual width back; the Character
  window's x becomes right edge - 444 = -76, off the screen). Restore applyCharState (ZeD_CharacterWindow.lua 330-358)
  and applyWorldState (ZeD_WorldWindow.lua 2677-2698) size the window at 444 units, clamp it onto the screen (pushing
  x -57 to 0, pulling the World window from 1004 to 947), then narrow by the room for a full card at that place; in a
  corner fitInvW (Scale.lua:116) finds no room even at the smallest inventory and answers nil, the same nil as "the usual
  width fits" (:113), so the 333 px stays. Run: bx_g1dk_deck.md:503-504, 509-510.
- Fix (restore only; the save keeps writing 444 for #150's round trip): in applyCharState and applyWorldState, work out
  the width BEFORE the clamp, measured from the edge each window keeps (the Character window's saved right edge,
  T.px(cs.anchorRightEdge); the World window's saved x). Make fitInvW's "not even the smallest inventory fits" a
  separate answer from "the usual width fits" (a second return value); in that case, on a screen that narrows windows at
  a fresh open, use the fresh-open width. Then place the window from its kept edge and clamp. (A fuller fix keeps the
  width the window had as fitW in the saved place, PAIR_FIELDS in ZeD_WindowPlaces.lua:32, and restores that when this
  screen narrows; keep _fitFromInvW / _fitInvW so the next save still writes 444.)
