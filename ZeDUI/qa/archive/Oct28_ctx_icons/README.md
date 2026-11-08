# Right-click menu: pixel icons (Oct 28 2026)

The menu's 389 licensed pictures replaced by ZeD's pixel icons (`shared/ZeD/ContextPxIcons.lua`), drawn by the box
rule. Manifest `ZeDUI/tools/qa/ctx_icons_manifest.txt` (prelude, `zedqa_ctx_icons.lua`, `zedqa_ctxlist.lua`,
`zedqa_wheel_icons.lua`, `zedqa_wheels.lua`).

- `report_4k.md`: 5/5 at 4K fullscreen, UI scale 1.75x (cell 39 px, icon box 28, the 24 drawing).
- `report_1x.md`: 5/5 in a 1080p window at 1x (cell 22 px, icon box 16, the 16 drawing).
- `4k/`, `1x/`: `grid.png` is every icon the menu uses (291) in real strip cells, at rest and pointed at; the rest are
  the strip and the list on an apple, a pistol, a bandage, a hammer and the floor.

Checks:
- all 389 picture names in `ZeD.ContextIcons` have a pixel icon with its four drawings; the lookup returns the icon
  for English names, for names read through the game's words (Eat, Drink, Equip Primary, Barricade) and for labels
  with a changing part ("Read ..." takes the book);
- the grid capture checked pixel for pixel against the exported drawings at both scales (scratch script
  `ctx_px_check.py`): all 582 cells match exactly, two colours per icon box;
- the live menus: no licensed picture left. The hammer's Belt Left / Belt Right have no icon (they had none before;
  the cell shows its letters).

Note: the drawings load in the background. The test panel asks for all 291 at once and they were ready after 69
frames; a menu asks for about a dozen.
