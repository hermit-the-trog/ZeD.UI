# KISS test: the Equipment and Thermal tabs (QA, Nov 24 2026)

The director, Nov 23 2026: "With every one of these micro QA passes, also do a KISS test." This covers the Equipment and Thermal sweep (et.txt: eq_tab + th_tab, run at 4K and 1280x800 on 377c8329d and 583f02d5f). The maps are 2026-11-24_map_equipment.md and 2026-11-24_map_thermal.md.

## Steps for the common jobs, the game against ZeD

| Job | The game | ZeD, Equipment tab |
| --- | --- | --- |
| Put a garment on | Double-click it (1) | No way from the List view or by pad; a drag onto the doll (1, mouse only) |
| Take a garment off | Double-click it (1) | Its row, then UNEQUIP (2); no double-click on the tab |
| Weapon to the off hand | Menu, Equip Secondary (2) | Menu (2), or the card's MORE then the option (3) |
| Hang a tool on the belt | Menu, Attach, the slot (3) | ATTACH, then the tool (2), plus 1 to open Held and Belt when folded |
| Take it off the belt | Menu, Remove (2) | DETACH (1) |
| Hood or sleeves | Menu (2) | Menu (2), the card's MORE (3), the pad's Clothing wheel |
| Read every part's defense | The Protection tab: one table (1) | The grade at a glance (0); each part's numbers by hovering it (1 per part) |

| Job | The game | ZeD, Thermal tab |
| --- | --- | --- |
| Open it | No key: another tab's key, then the tab (2) | The Character window's tab (1) |
| Read the core temperature | A bar only, no number | The number, a meter, Air and Wind chill (0 more) |
| Read one part's details | Click the part (1) | Hover or pad focus (0), or a grid cell (1); a click on the figure picks nothing |

## Bugs (to Build, with evidence; every one seen at both sizes)

1. **Taking off a layer.** UNEQUIP or DROP on a layered slot's card turns the card into the layer underneath. On the pad, A then A takes off the jacket and the sweater both.
2. **Hat over a hood.** A hat dropped on the doll with a hood up takes the hoodie off; the game's Wear lowers the hood.
3. **Drop in a car.** Seated with the window shut, the card's DROP does nothing and says nothing; the game grays Drop and says why.
4. **Narrow Thermal card.** On the 220 card no grid cell shows its body part's name (all 17, both text sizes).
5. **Stuck detail box.** Folding the figure by pad while the mouse rests on a part leaves the detail box on that part.
6. **Hover through the heading.** The pointer on the pinned "Body figure" heading hovers the part hidden beneath it.
7. (Being confirmed with a picture) After a column is dragged wider, the protection dots draw past the card's edge on the narrow card.

## Checked and fine

- Every body location the game has lands in a row and a doll slot. The four the map named sit in different places in the two views, and legs5 (unused by the game) sits in neither.
- Defense: every part's bite, scratch and bullet equal the game's own numbers; the grade, average, worst and best follow from them.
- Readings: core, Air, Wind chill and Body heat match the game outdoors and indoors.
- Units follow the display option, even with the oven's own C/F set the other way.
- All 7 views color all 17 parts, and every cell shows a value.

## Design calls for the director

See the closing message (numbered choices), each with the data the sweep recorded:
- **Core meter.** At 36.2 C the game shows Hypothermia 1 and ZeD's meter is green. At 37.3 C there is no moodle and the meter is amber. Hypothermia 3 and 4 both show 1 segment.
- **Wetness colors.** Dry shows the "cold" blue and soaked the "hot" red. The game's wetness view goes from green (dry) to blue (soaked).
- **One reading, two ways.** Upper Torso wind resistance reads 0.59 in the grid, 59% in the detail box and 2.34 in the game's own panel.
- **The wetness word.** "Dry" up to 49%, while the game's WET moodle is already on from 15%.
- **Putting clothes on from the Equipment tab.** There is no way from the List view, an empty slot or the pad, and no double-click to take off.
- **Empty belt slots.** They stay hidden until Held and Belt is opened.
- **Two-handed weapons.** The off-hand row reads empty.
- **Hand moves on an equipped weapon's card.** Off hand and Two hands are only under MORE.
- **The doll's Main and Off boxes.** A weapon dropped on them does nothing.

## Not staged

- Hyperthermia 3 and 4: the game holds the core at 40.0 C however high the stat is set.
- A belt with more than 8 slots: the QA character tops out at 7.
