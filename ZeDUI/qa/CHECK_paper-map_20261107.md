# Paper maps in ZeD's map: in-game check (Nov 7 2026, Build)

What changed: Read Map on a map item (a town map, a Louisville square, a stash map) opens ZeD's map window on that
paper instead of the game's map window. The window is the World window's unfolded map, titled with the map's name,
showing only the paper's area as the game draws it, with the paper's own marks and ZeD's marking tools. The game's
read is kept: the walk to the main inventory, the stash's building, the map counted as read, the area revealed on
the world map. Files: `client/ZeD/PaperMap.lua`, `client/ZeD/Overrides/PaperMap.lua`, small hooks in `MapsTab.lua`,
`MapNotes.lua`, `MapsTabExt.lua`, `MapsTabKey.lua`, `Overrides/WorldMap.lua`, `Input/FocusManager.lua`
(`Focus.isRegistered`). Sim: `ZeDUI/tools/qa/paper_map_sim.lua` (72 checks, all pass).

Later the same evening, Build's calls on the author's questions: when Read Map had to open the World window just to
show the paper, closing the paper closes the World window again (as closing the game's map window returns you to
play); a World window that was already open stays. The stash map's button keeps its words, "Find on map", with its
help line (ZeD's buttons are worded; icons only where ZeD already uses icon buttons). The game is on Stable 42.21
again: its Read Map (`onCheckMap`), paper window (`ISMap`) and map-reading action are the same as 42.22's.

Set-up: the QA save (Saves/Sandbox/ZeD-QA), ZEDQA_NOSTEAM=1, the Irvington drag strip in daylight. Spawn in the main
inventory: one town map (`Base.MuldraughMap`), one stash map (`Base.MulStashMap1` or any `*StashMap*`), one map in a
backpack (`Base.RosewoodMap`), a pencil, a red pen and an eraser. Run each part at 4K 1.75x, then at Deck size
(1280x800, Auto scale, Normal and Large text). Mouse first, then the pad.

## 1. Opening (mouse)

1. Right-click the town map in the Character window's list > Read Map.
   - ZeD's map window opens in the middle of the screen, titled "Muldraugh, KY" (the map's name), the MapOpen sound.
   - The map shows only the paper's area, in the game's paper colors, the whole paper in view. No fog over it, no
     player dot, no stash icons or flyer pins.
   - The band at the foot has no Survey / Color / Paper. The Key button is there (it opens the map key over the
     bottom-left, the eight colors).
   - No game ISMap window anywhere behind it.
2. Close it (the window's close box). MapClose sound. If the World window was closed before Read Map, it closes
   again with the paper (you are back in play). If it was open before, it stays open, its map tab as it was.
3. Double-click the town map in the list. Same window opens (a double-click is Read Map too).
4. Right-click the map in the backpack > Read Map. The character first moves it to the main inventory (the game's
   transfer bar), then the window opens.
5. Open the world map (M). Find the town map's area: it is now explored (no fog there), as with the game's window.
6. Darkness: at night indoors with no light, Read Map is greyed with "Too dark to read" (the game's check, unchanged).

## 2. Stash map

1. Read Map on the stash map. Its crosses and notes (the stash's marks) show on the paper.
2. The band shows a Find on map button. Its help line: "Find the place this map shows on your world map."
3. Click it. The character reads (the game's short map-reading bar). When it ends the paper closes and ZeD's world map
   opens unfolded, centered on the stash's area, the place pulsing. The stash's map icon shows on the world map there.
4. On a server with the world map turned off: the button is greyed, its help says why, and clicking does nothing.

## 3. Marking on the paper

1. With a pencil in the inventory, pick the X mark and click the paper. The mark lands on the paper.
2. Write a note (Note tool, type, click). It lands on the paper.
3. Close and read the same map again: the mark and the note are still on it. Open the world map (M): they are NOT on
   the world map (they belong to that paper, as in the game).
4. Drop the map, pick it up, read it: the marks travel with the item.
5. Right-click a mark: Delete and Change color (Edit note on a note), greyed without an eraser. No Sharing option, even
   on a server.
6. Marks made on the world map before (M) are not shown on the paper.

## 4. Closing rules

Do each of 1 to 5 twice: once with the World window closed before Read Map, once with it open.

1. With the paper open, drop the map on the floor (drag it out, or the game's drop). The window closes by itself
   (and the World window with it, when Read Map opened it).
2. Read a second map while one is open: the first closes, the second opens; the World window stays meanwhile. Closing
   the second paper closes the World window when the first Read Map opened it.
3. With the world map unfolded (M), Read Map on a paper: the world map folds, the paper opens.
4. With the paper open press M: the game's map-reading bar runs, then the world map opens and the paper is put away.
5. Close the World window (its close box) with the paper open: the paper closes with it, no error in the console.
6. World window closed, Read Map on the stash map, Find on map: after the reading bar the World window stays open with
   the world map unfolded in it. Folding that world map leaves the World window open.
7. World window closed, Read Map, then click the World window's own map fold (the drawer's placeholder or its unfold
   button): the paper folds and the World window stays (you reached into it).

## 5. Controller

1. From the Character window list, A on the town map > the item card's or the menu's Read Map (whichever the pad
   reaches it by). The paper opens and the pad is on the map's cursor (the crosshair in the middle).
2. D-pad and left stick move the cursor; at the paper's edge the map pans. Triggers zoom in and out.
3. Up from the map reaches the toolbar (marks, inks, the unfold button); down reaches the band (Key, and Find on map on
   a stash map). A on a mark, then A on the map places it. X on a mark opens its menu.
4. The hint strip says B Close (the game's word), not Fold.
5. B closes the paper. The pad lands back in the Character window list, on the map's row, not in the World window.
   With the World window closed before Read Map, it closes again with B and the pad stays in the Character window.
6. Find on map with the pad on a stash map: the world map opens after the reading bar, the pad on its cursor.

## 6. Small screens (Deck 1280x800, 720p)

1. At Auto scale, Normal and Large text: the paper window fits the screen, its title and the band's buttons are
   whole, the Find on map words fit the band next to Key.
2. The note box under the toolbar is readable at Large text.

## 7. Safe mode and fallbacks

1. Turn safe mode on (ZeD setup). Read Map opens the game's own window (ISMap) with its own buttons.
2. Turn the windows switch on (ZeD's World window off). Read Map opens the game's window.
3. Split screen (a second pad player): the World window belongs to player 1. Player 2's Read Map opens the game's
   window in player 2's part of the screen. Player 1's opens ZeD's.
4. Console: no `[ZeD] paper map` lines. If a paper can't be drawn the console says "paper map not drawn" and the game's
   window opens on the same map instead.

## 8. Other mods

- Draw On The Map (if subscribed): its Draw button does not show on the paper window (its strokes would land on the
  world map). It still shows on the world map. Drawing on paper maps is an open item.
- Map extensions from other mods (players list, teleport) do not show on the paper window.
