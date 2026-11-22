# Beast day, batch 8 (Nov 21 2026, QA): what the 4K pictures showed

Found by zooming into the day's 4K pictures (Screenshots/beast_day_report/), which no check had caught. Each was traced
in the code by one agent and confirmed by a second with its own crops of the picture. All three are real.

### B8-1 A jammed gun's Ammo line runs off the narrow item card's left edge (fix first)

- What the player meets: the narrow card beside the inventory list, a jammed gun: the last facts line has no label and
  starts mid-word at the card's left edge, "ammed | 9x19mm Round | 10 / 15". The Ammo label, the J and the red jam square
  are all cut away, so nothing on the line is red. Picture: B5-11_jammed_pouch_card.png (the card, top left).
- Cause: Molecules.lua drawFactsRow (logic 3138-3173) draws the value right-aligned at x + w - vw and never shortens it;
  only the label is fitted into what is left (w - vw - square - gap, here about -77 px, and Atoms.lua truncateText
  :2034 returns "" for that). B5-11 (f0189e024) put "Jammed | " in front of the value (ItemFactsPanel.lua M.CombatFacts
  316-318, 323-324): 31 mono letters, about 355 px at 4K, in a row about 311 px wide, so it starts 43 px left of the row
  and the body's stencil (ItemCardOrganism.lua :1496) cuts it. The weak spot is older (b93fb71a6, Oct 20).
- Fix, two parts:
  1. drawFactsRow: never draw the value left of x, never hand truncateText a room of 0 or less. Put the value on a
     second line, right-aligned, when the value plus its square is wider than the row, or when it leaves the label less
     room than the label needs and less than half the row; follow drawCardStatRow's wrapValue (Molecules.lua 2958-2973):
     label alone on line 1, value on line 2 cut with "..." only if even the full row is too narrow, the square before
     the value, return two row heights (drawFactsGroups already adds the returned height). This also covers long round
     names, translations, Large text and the other rows on this molecule.
  2. ItemFactsPanel.lua CombatFacts: the jam as its own row in group 3, as LiquidFacts shows Tainted (:421):
     {label = ZeD.tr("UI_ZeD_Jammed"), value = "", valueClass = "bad"} after Condition; the Ammo row back to
     "9x19mm Round | 10 / 15" with its old class. (QA follows in bx_combat.lua near :425 and bxr_inv.lua S.jamWords.)
- Same molecule, worked out from the numbers, not seen: a gun that is NOT jammed already leaves the Ammo label about 46 px
  on the narrow card at 4K (likely "A..."), a 5.56 or 7.62 rifle about 11 px. Part 1 fixes these too.
- Small, related (B8-1b): the card's Weight reads getActualWeight (ItemCardOrganism.lua :526), the bare gun, 1.5 kg;
  the list rows, the picked line, vanilla's inventory and the game's tooltip all use getUnequippedWeight (gun plus
  magazine and rounds, 1.9 kg). Suggest getUnequippedWeight on the card too (it would also weigh a bag with its contents,
  as the bag's row does).

### B8-2 The right-click strip's icons are blank until their pictures load

- What the player meets: the first time a strip (or the list look) shows a given icon after the game starts, and again
  after a UI scale change, that tile is plain paper (or the teal pick with nothing on it) until the picture has loaded.
  Picture: W15_strip_at_rest.png (taken one frame after the strip's first draw: 9 of 10 tiles blank, only Place Item's
  icon there).
- Cause: the strip's pictures are loose files (Atoms.lua PXI.tex :316-325 picks media/textures/ZeD/wheel/<size>/zw_<id>.png);
  nothing asks for them before a cell first draws, and the game loads a loose picture in the background after the first
  ask (docs/reference/PZAPI-KNOWLEDGE-BANK.md Q247). The desk, the dash plates and the belt already ask early. Not a
  regression: the strip has loaded on first draw since its pixel icons came (52cb25186, Oct 28); W15 (2a00af40d) took
  away the 180 ms slide that used to hide the moment on long strips.
- Fix: PXI.warm(box) in Atoms.lua after PXI.has: for each id in ZeD.ContextPxIcons plus ZeD's own row ids (and the _mk
  file for ids in ZeD.PxIconMark), ask Texture.getSharedTexture(path, 3) for the size PXI.tex would draw in that box
  (the largest of 48/32/24/16 not above it, 16 under 16), in a pcall, without storing the answer in _pxTex; the same
  flags as pxTex (3 = nearest: a texture's first load sets its filtering for the session, Q205). Run it once per box size:
  at game start and after a UI scale change.

### B8-3 The corner clock steps out from under the World window and lands under the Character window

- What the player meets: the clock in the top right corner (the worn wristwatch, the Lite clock, or the game-speed keys
  when no watch is worn) slips under the Character window: a faint ghost through the see-through window, nothing at
  See-through 100%, and its keys can't be pressed (light, alarm, set, speed, start; Lite: Pause, x1, x2, x3). Picture:
  B5-7_2x_side_by_side.png (after a 1x -> 2x scale change, both windows side by side at the right edge).
- Cause: ZeD_Watch.lua _layout (about :455-467), the Nov 20 B1 step-aside (f6ecdf87d, shipped in beta21a/21b): it
  steps clear of the World window only and does not look again after the step. The Character window always stands just
  left of the World window (10 design units apart in the default spread; B5-7's unpile lays a scaled-up pair the same
  way), so the clock lands under it.
- Fix: step clear of both of the player's windows and check the new spot again after every step. A file-level helper
  (no table or closure per frame; the file has about 38 top-level locals):
  `local function _overBox(win, x, y, w, h) if not (win and win.getIsVisible and win:getIsVisible()) then return false end
  local wx, wy = win:getX(), win:getY(); return x < wx + win:getWidth() and x + w > wx and y < wy + win:getHeight() and y + h > wy end`
  and in _layout: while the clock's box is over either window, move it left of that window (or below both when there is
  no room), at most a few steps.
