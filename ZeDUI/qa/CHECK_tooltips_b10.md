# In-game check: tooltips as Balloon Help, and the strip's arrows in the accent (Nov 8 2026, beta 10)

Punch list 118 and 119. Design: `ZeDUI/HANDOFF_design_tooltips_balloon_20261108.md` and the mockup
`ZeDUI/mockups/zed_tooltips_balloon_v1.html` (open it beside the game: the After panes are what should show).

What changed, in plain words:
- Every pop-up that explains a control is now one balloon in the theme's colors: surface 2, the strong border (two
  hairlines in High contrast), the hard shadow, square corners, and a stepped tail 10 hairline cells deep whose tip
  stops one hairline short of the thing it explains. That covers the strip's balloon (the white bubble is gone), the
  list menu's balloon, the hints on icon-only controls (belt, footers, tab strips, map inks, window boxes), the
  detail cards (ammo, dashboard lamps, skills, hair and beard, read status) and the moodle under the pointer.
- The balloon hangs off the control, not the pointer: above a row of controls (the strip, the belt, footers), beside a
  column (tab strips, the moodles, the list menu, skill rows). Near the right edge the tail moves to the lower right
  corner; with no room above it goes under (the strip: under the strip, tail up); with no room on the right it goes
  left. A box that still does not fit slides to stay 4 units inside the screen, and its tail stays on the control.
- Size: one-line hints wrap at 200 units, anything with a title at 320 (230 and 368 at Large text). A word longer than
  that widens the box up to half again, then breaks. Measured at the live scale and text size: nothing spills.
- Mouse: 450 ms of rest, then the balloon; moving to the next control while one is up shows the next at once.
  Controller focus (belt slots and hands, icon buttons, tab strips, the doll's boxes, skill rows, hair and beard rows):
  at once. No timer: it stays while the pointer is on the control or on the balloon. Escape or B hides a hint until the
  pointer or focus moves on (B and Escape still do their own job). In the context menus B and Escape still go back.
- One balloon at a time; a menu's balloon wins over a window's hint.
- The requirement balloon (a greyed option's tooltip, World menu > Disassemble > a piece of furniture): the game's
  picture of the piece, then two columns, the game's labels, a check or a cross, the values one under another in green
  (met) or red (missing); "Has items in container." as a condition row with its cross; printed once; no Name row.
- New status colors safe as text (positiveText, dangerText): Dark danger text is lighter (#DE7045), Light positive text
  is darker (#204A0C). The crafting card's met / unmet squares (HOW TO LEARN) use them too.
- Item 119: the strip's end boxes (shown when the strip scrolls, more than 10 options) are filled with the accent and
  framed in the strip's ink; the arrow is the accent's text color. Pressed, the box moves one unit into its shadow.
- Not changed: the strip's cells, the game's item box over the belt (ISToolTipInv stays the game's, so tooltip mods
  keep adding their lines to it), the moodles' own drawing. A moodle notice that shows by itself (ZeD setup's Moodle
  notices) keeps its thought bubble; only the moodle under the pointer gets the balloon.

QA save `Saves/Sandbox/ZeD-QA`, at the drag strip. Two passes: 4K (3840x2160, UI scale 1.75, fullscreen4k) and
1280x800 (windowed, Auto). Languages: EN, then DE and RU (set the game's language, restart, repeat sections 1, 2, 3
and 6 at both sizes).

Before the game:
- `lua51 ZeDUI/tools/qa/balloon_b10_sim.lua` reads `780 passed, 0 failed`.
- `lua51 ZeDUI/tools/qa/ctx_reqtip_sim.lua` reads `85 pass, 0 fail`.
- `lua51 ZeDUI/tools/qa/ctx_list_still_sim.lua` reads `6 pass, 0 fail`.
- `python -I ZeDUI/tools/qa/kahlua_guard.py` reads `RESULT: PASS`.

Scripted: `zedqa_b10_tooltips.lua` (grep `ZEDQA b10tt`; shots `zqa_b10tt_*.png`), then `zedqa_ctx_overlap.lua` (grep
`ZEDQA ctxov`; its still-pointer line is now a check, `LIST a pointer perfectly still on Eat opens its submenu`, with the
list's state in the line if it fails).

## 1. The strip's balloon

Context menu set to Icon strip. Right-click an apple in the inventory, then a car seat item with a long option name
("Put in Container (Driver's Seat)" in a car).

| Step | Should show |
|---|---|
| Move along the strip | A dark (Light: grey) balloon above the strip, the option's name in the heading face, its tail from the lower left corner to the pointed cell. Each cell's name at once as the pointer moves. |
| Long name, Large text, RU | The name wraps inside the box (368 units at Large); no letter outside the frame. |
| In a submenu (Move to > Floor) | "Move to > Floor": the path in the dimmer secondary color, then the name. |
| Right-click near the right edge of the screen | The tail moves to the lower right corner; the tip still on the cell. |
| Right-click near the top of the screen | Strip under the pointer, balloon under the strip, tail up to the cell. The strip is never covered. |
| Pad: open with the pad, D-pad along | The same balloon, at once. B goes back / closes as before. |
| An option with a plain tooltip (Eat on food) | The name, then the tooltip's words under it, once. |

## 2. The requirement balloon

The script places the piece; by hand: stand by a chest of drawers with something in it, no saw in the inventory, a
hammer in it. Right-click it, World menu > Disassemble > the piece. Do it in the strip, then the list.

| Step | Should show |
|---|---|
| The balloon | Title "Disassemble > <piece>". The piece's picture (32 units, on a darker square, framed) at the left. |
| Rows | Skill: a check, the skill in green. Tool needed: a check, the four hammers one under another in green. Tool needed: a cross, the three saws in red. Then a cross and "Has items in container." in red across both columns, no dash. |
| Once | Nothing printed twice; no grey copy under a dashed line; no Name row. |
| Colors | Every theme: the green and red read clearly on the box (Dark: the red is a lighter orange-red). |
| Columns | Every value starts at one x. A long German or Russian label pushes the values right; a long value wraps under itself. |
| List look | The balloon beside the row (right; at the screen's right edge, left), its tail on the row's edge at its middle. |

## 3. Hints and detail cards

| Step | Should show |
|---|---|
| Belt: rest on a slot | After a short pause, the slot's name and key above the slot, tail to it. The game's item box (with any tooltip mod's lines) sits above the balloon, not over it. |
| Belt: move to the next slot | The next name at once. |
| Belt: pad focus on a slot or a hand | The name at once. |
| Belt: the ammo box (or the main hand with a gun, pad) | The gun's count as a titled balloon above it. |
| Character window tab strip: rest on a tab | The tab's name beside the strip (World window: on its left), tail to the tab. Pad focus on a tab: at once. |
| Inventory grid: rest on an item | Its name above the cell. A book: its read card above the cell (list view: above the row's name). |
| Equip tab doll: rest on a box; pad focus on a box | The item's name above the box. |
| Skills tab: rest on a skill row; pad focus | The skill's card beside the row. |
| Hair and beard rows | The card beside the row. |
| Dashboard (in a car): rest on a lamp | The lamp's card above it. |
| Main menu: rest on the power button | "Exit" above the button. |
| Map inks (Maps tab) | The ink's name above the swatch. |
| A disabled icon button (a footer's Transfer All with nothing to move) | The balloon at full contrast, not faded. |
| Move the pointer from a control onto its balloon | The balloon stays. Off both: it goes. |
| Escape (pointer still) / B (pad) | The balloon goes and stays gone until another control. B and Escape still do what they did. |

## 4. The moodles

| Step | Should show |
|---|---|
| Rest on a moodle (right column) | After the pause, the moodle's name as the title and its description under it, in a balloon to the left of the column, tail to the moodle. |
| Moodles on the left / in the bottom row (ZeD setup) | The balloon on the right / above. |
| ZeD setup's Moodle notices on, a moodle changes | The notice still shows by itself in its thought bubble (unchanged). |

## 5. The strip's end boxes (item 119)

Right-click something with more than 10 options (an apple with Debug on, a car), Icon strip.

| Step | Should show |
|---|---|
| Both ends | The boxes filled with the accent, framed in near-black, the arrow in black (Dark, HC) or off-white (Light). |
| All nine accents, all three themes | The arrow reads on every one (the script logs each ratio; 3 : 1 or more). |
| Press and hold an end box | It moves one unit down-right into its shadow. |

## 6. Every theme, accent and text size

For Dark, Light and High contrast, Small and Large text: repeat the strip balloon on a long name, the requirement
balloon, a belt hint and a moodle. High contrast: the frame and the tail's edge are two hairlines thick. No word outside
any box; the tails always on their control.

## 7. Tooltip mods

Subscribe Tooltiplib and Better Item Info (Workshop; ZeD last in the load order). Rest on a belt slot with an item and
on an inventory item with the game's tooltip (hover in the list).

| Step | Should show |
|---|---|
| The game's item box | Still the game's box, with the mods' extra lines. ZeD's balloon over the belt slot stays clear of it. |
| Console | No errors from the mods or from ZeD. |

## 8. The list menu's submenu on a still pointer

Context menu set to List. Right-click an apple, move onto "Eat" and hold the mouse perfectly still (no jitter).

| Step | Should show |
|---|---|
| Rest on Eat | Its submenu opens after about a fifth of a second, without moving the mouse again. |
| Press Shift while resting | No change: the submenu still opens. |
| Press Down instead | The keyboard takes the selection; the submenu of the pointed row does not open by itself. |
