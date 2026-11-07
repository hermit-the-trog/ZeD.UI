# In-game check: mod support on the belt and the menu style fix (Nov 7 2026)

Four mods from the director's support list (compatibility round 6). The mods' copies are in
`C:\steamcmd\steamapps\workshop\content\108600\<id>\mods\<folder>`; `ZeDUI/tools/qa/batch_compat_r6.ps1` copies them
into `Zomboid\mods` for a run and takes them out after.

| Mod | Id | Folder |
|---|---|---|
| Auto-Hide Hotbar | 3835479468 | `AutoHideHotbar` |
| Mask Filter Indicator | 3832759095 | `MaskFilterIndicator` |
| Item Condition Restored | 3834708364 | `ItemConditionRestored` |
| Better Item Transfer | 3830103302 | `BetterItemTransfer` |

The QA save (Saves/Sandbox/ZeD-QA), ZeD last in the load order. Each part below is one mod on its own; part 5 is all
four together. Two screen sizes for every part:
- 4K fullscreen at 1.75x (the usual QA size);
- Steam Deck size, 1280x800, UI scale Auto, Normal text, then Large text.

Mouse first, then the controller. With the controller, D-pad Left (the Character wheel's Weapons slice, as today) or
the belt's own way in puts the focus on the belt.

Before any of it: the sim `ZeDUI/tools/qa/belt_mods_sim.lua` passes (78 checks), and with none of the four mods on
the belt draws exactly as before.

## 1. Item Condition Restored

Set up: the mod on. A pot with some water in it, a lighter, a battery radio with a battery, a knife and a shirt in the
inventory.

1. Attach the knife and the lighter to belt slots. Put the pot in the main hand and the radio in the off hand.
2. **What should show:**
   - under the knife: its condition, in the condition colors (green, amber, red by how much is left);
   - under the lighter: its uses left, in the condition colors;
   - the main hand's ring: the pot's water, in the theme's info color (blue in the dark theme), not the condition colors;
   - the off hand's ring: the radio's charge;
   - an empty pot in hand: the pot's condition (the mod does this for a pan or pot that is also a weapon).
3. Options > Mods > Item Condition Restored: set "Hotbar bar style" to **Vertical** (one color). The strips under the
   knife and the lighter turn one color, the theme's positive green. The pot's water stays blue.
4. Set "Equipped item circle style" to **None**. The hand rings go back to ZeD's own: the knife's condition in a hand;
   a lighter or radio in a hand shows no ring (they have no condition).
5. Set both back to the mod's default, Vertical (multicolor).
6. Change the theme (Dark, Light, High contrast) and the accent: the strips and rings follow the theme.
7. Safe mode on (ZeD setup): the game's hotbar and hand circles come back with the mod's own bars. Safe mode off again.

Controller: nothing new to press. Focus a slot and a hand: the strip and ring look the same under the focus mark.

## 2. Mask Filter Indicator

Set up: the mod on. A gas mask with a filter, two spare gas mask filters in the inventory, an SCBA with a tank (the
hazmat suit works too).

1. Wear the gas mask. **What should show:** a new box on the belt after the strap, before the Messages note (and before
   the chat key and PvP marker on a server), a slot's size:
   - the mask's picture;
   - the ten-segment strip under it at the filter left, in the condition colors;
   - "+2" on its top left, on the dim tag where a slot shows its key;
   - no lamp while the air is clean.
2. The mod's own strip above the hotbar does not show anywhere, and nothing invisible catches clicks where it would be.
   Try the mod's "Free (drag with mouse)" position too: still nothing on screen but the belt's box.
3. Hover the box: the hint reads "Gas Mask | 64% left | spares: 2" (the mask's name, its filter, the spares). The game's
   item tooltip stands above it, as on a slot.
4. Click the box, then right-click it: the mod's menu in ZeD's menu, "Take off mask" and "Replace filter". Replace
   filter works (the mod takes the mask off, swaps the filter, puts it back on). The spares count goes down by one.
5. Stand in a toxic building, or near six or more corpses: the box's lamp lights while the filter drains. Options > Mods
   > Mask Filter Indicator, "Blink the bar while the filter is being used" off: no lamp.
6. Remove the filter (the mod's menu or the game's): the strip is an empty well; the hint says "No Filter". With no
   spares the hint ends in the mod's "No spare filter".
7. "Mask HUD visibility" set to **Alert (only when low)**: the box goes while the filter is above a quarter, and comes
   back at a quarter or less, or with no filter fitted.
8. Wear the SCBA instead: the box shows the SCBA and its oxygen; its menu has Turn on / Turn off; the lamp is lit while it
   is on.
9. Take the mask off: the box goes and the belt closes up.
10. Get in a car: the belt and the box hide as usual; the mod's R hold and its firearm wheel slice still replace the
    filter.
11. Safe mode on: the mod's own strip is back above the game's hotbar (and its Free position, if picked). Safe mode off:
    it is parked again.

Controller: focus the belt and walk right with the D-pad to the mask's box (after the last slot). A opens the mod's menu
on the box, the focus in the menu; pick Replace filter. B closes the menu and the focus is back on the belt. X does the
same as A. Right past the box goes on to the Messages note; past the end leaves the belt, as before.

At Deck size with Large text: the box fits the belt like a slot; the hint and the "+2" badge are not cut.

## 3. Auto-Hide Hotbar

Set up: the mod on, its defaults (Fade + Slide, hide after 2.5 s).

1. Load in: the whole belt shows (hands, slots, ammo tab, watch, Messages note) for 2 s, then fades and slides down.
2. Move the pointer to the bottom of the screen under the belt: it comes back; leave it: it goes after 2.5 s.
3. Press a hotbar key (1 to 9): the belt shows for 2 s and the key works as before. Hold a key: the slot's list opens
   above the slot and the belt stays while the list is open.
4. Click and drag a slot's item off the belt: the belt stays while dragging. Drag an inventory item: it stays (the mod's
   "Dragging an item or slot" option).
5. Right-click a slot or a hand: the belt stays while the menu is open.
6. Options > Mods > Auto-Hide Hotbar: try Fade, Slide, Peek (a thin strip stays) and Instant, and a hidden opacity of
   30%. Each looks the same on the belt as the mod describes it for the hotbar. After every slide the belt sits exactly
   where it was (the buckle on the screen's center), and clicks land on the boxes.
7. Tick "The inventory is open": the belt stays while ZeD's Character window or World window is open.
8. Set a toggle key: it turns auto-hide off and on (the mod's note over the character).
9. Pick up a controller: the belt always shows (the mod does the same for the hotbar). Focus the belt with the pad: it
   stays.
10. Safe mode on: the game's hotbar is back and the mod hides that instead. Off again: the belt hides as before.

At Deck size: the hover area along the bottom edge reaches the belt; nothing else on the bottom of the screen hides.

## 4. Better Item Transfer: the menu style

Set up: the mod on. ZeD setup (or Options > Mods > ZeD-GUI), "Context menu" set to the icon strip.

1. Load in. Right-click an item: the icon strip, with the mod's options in it.
2. Switch "Context menu" to the list, Apply. Right-click an item at once: **the list on the first right-click**.
3. Switch back to the strip: the strip on the next right-click.
4. QA's scripts: `zedqa_ctxlist.lua` passes with the mod on (it set the style without saving and failed 4 of 4 runs
   before); `zedqa_ctx_bit.lua` pictures both styles full.
5. The mod's own options (Options > Mods > Better Item Transfer) still work: turn "showIcons" off and the menu loses its
   icons on the next right-click.

Controller: X on an inventory row after the switch: the list, focus in it.

## 5. All four together, then none

1. All four on, plus the compatibility round 6 suite (`compat_r5.txt`'s list through `zedqa_mods_run.ps1`): every check
   passes, the right-click list check included.
2. All four off: the belt has no extra box, its strips are ZeD's condition, it never hides, and the console has no
   `[ZeD] ModSupport` line for any of the four.
3. The console (`console.txt`): no errors from `ZeD/ModSupport`.

## Notes for the report

- Item Condition Restored's direction (vertical or horizontal), opacity and picked colors do not carry over: the belt's
  strip and ring are ZeD's, in the theme's colors.
- Mask Filter Indicator's position option has no meaning under ZeD: the mask is on the belt. In a vehicle there is no
  box (the belt is hidden there); ZeD's dash does not show the mask yet.
- Auto-Hide Hotbar hides the whole belt, the hands and watch with the slots: they are one strip under ZeD.
- The belt is player one's only, as the game's hotbar is; split-screen players two to four keep the game's hotbar and
  the mods' own drawing on it.
