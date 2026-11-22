# Beast day, batch 7 (Nov 21 2026, QA): from the stress scripts' second run and the proof runs

The second run of the stress scripts (15:29-16:00, on 9053bdef9 and the working tree before it) and the proof runs
(16:02-16:09) failed 20 checks. One agent per script sorted each fail against the code and the game log, and a second,
skeptical agent re-checked every verdict both ways. Most were the scripts' own faults (fixed by QA); two were checks
that had not caught up with a fix (W35, B5-11: updated). These are the ZeD faults that both kept. The scripts keep a
failing check for each.

### B7-1 A side asked to come down before its tab has drawn once never comes down

- What the player meets: the inventory side rolls under its tab and, on the same 100 ms UI update, something asks it
  back down: a quick click on a crate in the world whose release lands on the update where the side's 2-second timer
  runs out (the B5-1 path), or on the pad the aim roll-up and a bumper or Y in the same frame. The side stays gone and in
  its place stands a blank full-height strip with a title bar and a close box but no tab; hovering or pressing it does
  nothing. It clears when the drawer closes, Loot is pressed, the window rolls up, or an item is dragged over it.
- Where: WindowCurtain.lua:345-352 (C.unroll sets rod._target = win:getHeight(), which C.roll at :333 had just set as
  rod._h; a new rod only joins the UI list on the next update, :334-339), :121-126 (the rod's prerender moves and calls
  finishUnroll only inside `if self._h ~= self._target`); WindowHalves.lua:612-614 (drive never asks again once _target is
  above the title bar). Old curtain code; ed813a48a (B5-1) added one more caller that reaches it.
- Likely fix: in C.unroll, finish at once when the rod has not moved yet (`if rod and rod:isVisible() and rod._h <
  win:getHeight() then rod._target = win:getHeight() else C.finishUnroll(win) end`), or let the prerender finish when
  _h == _target and _target is above the title bar.
- Seen: bx_inventory 6d in both runs today (240 ticks, side still rolled, the list already on the clicked crate).

### B7-2 B5-6 is still open: a fast wheel spin empties a long right-click strip

- What the player meets: on a strip with 11 or more actions, a notch on every drawn frame (a free-spinning wheel, or a
  fast roll at a low frame rate) for 11 to 26 notches: the strip stops sliding, loses cells and goes empty while the wheel
  turns; up does the same off the other end. On the committed code the blank comes just after the wheel stops (0 of 10
  cells about 50 to 250 ms after the last notch, until the settle).
- Where: ZeD_ContextMenu.lua:290-294 and 308-315 (_layout restarts the slide's clock on every new target, so a step every
  frame means the drawn strip never moves), :501-514 (the uncommitted _stepPos shifts that stuck picture a whole copy at
  each wrap, off the track; page() at :556-565 has the same shape); Molecules.lua:4275-4309 draws only cells that exist.
- Likely fix: keep the drawn strip within a few cells of its target (do not restart the slide from zero on each step, or
  cap the gap in _layout before easing); as a safety net the strip's draw could wrap the cell index.
- Seen: bx_context, 0 of 10 cells at frame 31 of the spin; reproduced with ZeD's own code offline. The check now spins
  down and up and counts until half a second after the last notch.

### B7-3 The controller wheel never names the seat

- What the player meets: on the wheel, sitting on a bed, the Sleep slice's line reads "Sleep on Ground"; beside a chair or
  a bed the sit slice reads "Sit on a seat", never "Sit on: <name>". The sleep itself uses the bed; only the words are wrong.
- Where: ZeD_DpadWheels.lua:1355 (H.sleep) and :1551 (H.sitWheel) call safe(getMoveableDisplayName, seat); that global is
  nil in the game, so both fall back every time. There since the wheels were built (629b0e219).
- Likely fix: call ISWorldObjectContextMenu.getMoveableDisplayName in both lines, as AnimalsTab.lua:1948, FacePop.lua:365
  and ObjectCardLaundry.lua:90 already do.
- Seen: bx_health (sleep slice "Sleep on Ground" on the placed bed; the game reported bed type goodBed).

### B7-4 The hover balloon never says a gun is jammed (B5-11 missed one place)

- What the player meets: pointing at a jammed gun (its row, the Equip tab, the belt's hand box), ZeD's loot card balloon
  shows it as ready; the game's tooltip it stands in for says "Weapon jammed. Rack it." (HandWeapon.DoTooltip,
  Tooltip_weapon_Jammed). A jammed gun carried but not held looks ready on hover.
- Where: ZeD_LootCard.lua (LC.facts, LC.content), shown by ZeD_InvTip and ZeD_Belt's _tooltip. f0189e024 fixed the pouch,
  the item card's facts and the facts panel, not this file.
- Seen: bx_combat's new check "pistol jammed: ZeD's loot card says Jammed" fails on the current code.

### B7-5 A removed animal zone stays on the Animals tab while its animals stand in it

- What the player meets: Zone page > Remove zone > Remove on a pen with animals in it. The overview still draws the
  removed zone's card with those animals counted, and their zone name still reads it, until each animal's own zone check
  comes round (a 2000 timer, up to about 42 s at normal speed). On the ghost card, Rename shows the Save and Cancel band
  with no name box (renameZone sets _animalsRenaming before its lookup fails), and Remove leaves its question up
  (confirmRemoveZone returns before it clears _animalsRemoveConfirm).
- Where: AnimalsAlertPoller.lua:117-123 (the fallback uses obj:getDZone() without checking the zone still exists); met
  through AnimalsTab.lua:807-819 (confirmRemoveZone), drawn at :1616-1628.
- Likely fix: in the fallback take getDZone() only when that zone is one DesignationZoneAnimal.getAllZones() listed (keep
  a set of the zones walked in the loop above). Also clear _animalsRenaming / _animalsRemoveConfirm when the lookup fails.
- Seen: bx_farm "remove: Remove takes the zone away, on the Animals tab too | false".

### B7-6 A car taken out of the world still counts as there: its inspection and its seat window stay

- What the player meets: a car removed while he stands by it (a burnt wreck dismantled with the torch, an admin or the
  server removing it, a mod that scraps cars): ZeD's seat window stays on screen with its seats still pickable, and the car
  stays inspected, until he clicks elsewhere or walks six tiles away. The Vehicle tab's list itself drops the car.
- Where: ZeD decides a car is gone with vehicle:getSquare(), which for a BaseVehicle only looks up the ground at its last
  x,y,z: MechanicsTab.lua:229 (inspections), :233 (pins), MT.inReach :213, the render guard :2238;
  ZeD_SeatPopout.lua:751; ZeD_SeatChooser.lua:604; ModSupport/MaskaradsSummerCar.lua:174.
- Likely fix: test the car itself, `v == nil or v:isRemovedFromWorld()` (no arguments, in 42.22), beside the square test
  for unloaded ground, in one shared helper. Drop the inspection's entry, not only the answer (it is keyed by the car's
  id, which the game hands to the next car it adds). On removal, skip endInspection's ISCloseVehicleDoor (it would send him
  to close the hood of a car that is gone).
- Seen: bx_vehicles, two checks (the console 15:51 shows the removal and the windows left up).

### B7-7 (small, cosmetic, older than today) French fleet cars paint the maker on their unit line

- What the player meets: in French the fire truck's unit line reads "DASH - UNITE nn" and the police and ranger cars'
  "CHEVALIER - UNITE nn", where English shows the service.
- Where: ZeD_Dashboard.lua _badges takes the livery to be the words before the maker in the translated car name; the
  French names put the service after it ("Dash Bulldriver de Pompiers", "Chevalier Nyala de Police", "Chevalier Nyala de
  garde forestier"), so the livery comes out empty. The same at a4fc05567~1.
- Found by the vx_vehicles reviewer, run offline in the game's Lua engine on HEAD.

## Still open from earlier batches (Build has them)

B5-5 (List look: world right-click headings read "Item"), B5-6 (see B7-2), B5-9 (food in ZeD's lists never ages),
B6-5 (Steam Deck: with a controller assigned, a moving mouse or finger no longer moves the strip's selection), B6-9
(seated drops through a shut window on the other paths).
