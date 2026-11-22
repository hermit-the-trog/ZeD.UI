# KISS audit, batch K2 (Nov 22 2026, QA): the fixes that stand whichever way the director picks

From the KISS audit (see 2026-11-22_kiss_bugs_K1.md for the method). The ranker attached these to design calls as
"whatever the call": each is plain consistency with the game or with ZeD's own other path, and none depends on the
option the director picks for its theme. Theme numbers are the ranks on the KISS report page
(https://claude.ai/artifact/74SzWzsSjMZauzcuWZacSS). Lines marked "read from code" want one look in game; QA proves
each fix in game once it lands.

Held back for the director's picks (not in this batch): #8 the hint strip's Y label (Loot or Windows, by the Y call),
#20 the guide's car pages (only if the car's wheel stays off D-pad Up), #29 the tour's Health line (matches whatever a
click on a wound does after the call) and #44 graying the game's container outline option (only if the call is not
option 1).

### K2-1 (#7) On a pad, Up and Down do nothing on the right-click strip
- What the player meets: the strip lies in one row and only Left and Right move along it; Up and Down are dead, while
  the List look already takes them.
- Fix: Up and Down step the strip as Left and Right do (the no-ops at ZeD_ContextMenu.lua:978-981); the list look's
  handling is at ZeD_ContextList.lua:666-667. Read from code.

### K2-2 (#11) A click on a hand on the belt does nothing
- What the player meets: he clicks the belt's hand holding the crowbar to put it away and nothing happens, though the
  pad's A on the same hand puts it away.
- Fix: a left click on a belt hand puts its item away, the pad's A path (ZeD_Belt.lua:2389-2413, 2611-2617).

### K2-3 (#17) A pinned recipe vanishes under Show: Ready
- What the player meets: he pins a recipe to keep it at the top; under Ready it drops out of the list whenever he
  can't make it right now.
- Fix: pinned rows stay listed under any Show, as the open card's row already does (CraftingCore.lua:1122-1133,
  2165-2181).

### K2-4 (#18) On a pad, A on the tab already open does nothing
- What the player meets: A on the tab that is open clicks and nothing happens, where a mouse click on it folds it.
- Fix: A on the open tab folds it, as a mouse click does (ZeD_CharacterWindow.lua:1204-1207; docs/specs/GAMEPAD_SPEC.md:52).

### K2-5 (#20) In a car on a pad, the dash's first stop isn't the ignition and B's word differs
- What the player meets: the dash holds the pad from its first stop, the trip reset (the odometer key on Lite's dash),
  not the ignition; the dash calls B Drive while the wheel's line calls it Back.
- Fix: the dash's first pad stop is the ignition and B reads Drive in both places (ZeD_Dashboard.lua:811, 2343-2346;
  UI.json:704, 2880).

### K2-6 (#25) Escape doesn't close ZeD's map
- What the player meets: Escape over the map opens the game's pause menu, not closes the map.
- Fix: the map's pop-out takes Escape; it has no key handler and registers no Escape taker (MapsTab.lua:2462-2530),
  as the car radio does (Overrides/CarRadio.lua:43-45, run at Overrides/Prompts.lua:161-162).

### K2-7 (#29) Use on wipes and thread does nothing, and a bandage dropped on a wound does nothing
- What the player meets: the card offers Use on wipes, thread and the other drainables the game's double-click
  ignores, and it does nothing; dragging a bandage onto a body part or a wound row on the Health tab does nothing,
  where the game's own health panel treats the part.
- Fix: no Use on those cards (ItemCardOrganism.lua:440-441; ItemCard.lua:957-962); a drop on a body part or a wound
  row goes to the game's dropItemsOnBodyPart (vanilla ISHealthPanel.lua:1915-1940), which ZeD's drop handler never
  checks (InventoryRenderer.lua:3758-3884).

### K2-8 (#31) A double-click on a closed stack takes one
- What the player meets: he double-clicks Nails (50) in a crate and gets one nail; the game's double-click and every
  other ZeD move of a closed stack take the whole stack.
- Fix: a double-click on a closed stack takes the stack (quickUse moves { item } at InventoryRenderer.lua:913-928; the
  drag carries the stack at 3731-3756).
