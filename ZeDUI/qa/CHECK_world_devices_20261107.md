# In-game check: TV, radio and animal windows go to ZeD (Build, Nov 7 2026)

What changed: every way into the game's radio window, its animal info window and its livestock zone window now opens the ZeD screen that already shows the same thing (VANILLA_WINDOWS_20261107.md rows B1, B4 and B5). The TV and house radio still use today's radio card; their own faces come when design draws them.

Code: `ZeD/WorldRoutes.lua` (where each goes), `ZeD/Overrides/RadioWindow.lua`, `ZeD/Overrides/Animals.lua`, `ZeD/RadioTab.lua` (pinned devices, the tab staying on its radio), `ZeD/AnimalsTab.lua` and `ZeD/ZeD_WorldWindow.lua` (the zone view's help button, the animal view's reach). Sim: `lua51 ZeDUI/tools/qa/world_routes_sim.lua` (128 checks, 0 failed at commit). Not opened in game yet. The hooked vanilla functions were re-read on Stable 42.21 (`ISRadioWindow.activate` / `:update`, `AnimalContextMenu.onAnimalInfo` / `onCheckZone`, `ISOpenAnimalInfo:perform`, `ISAnimalZoneFirstInfo.showUI`, `ISAnimalUI:prerender`): the same as 42.22's.

## Build's calls on the three open questions (Nov 7 2026)

1. **The game's first-time livestock zone note.** Still no pop-up: it never comes up on its own under ZeD's window. ZeD's zone view has a help button instead (the "?" icon at the right of the Animals heading, left of Sort): pointing at it (or the controller on it) puts the note's first sentence on the window's help line, and pressing it opens the game's whole note, in the game's own words (`IGUI_Animal_ZoneFirstInfo`), as a ZeD note with one OK. No new text: the button's name is ZeD's existing "Help". If ZeD's note can't be built, the game's own note opens.
2. **The pinned far device.** The game's 10-tile reach stays, but only on the player's own floor: going up or down stairs drops the pin at once (whether or not the Radio tab is showing), and walking back does not bring it again. A device on another floor opens nothing (the game's window would have opened, since its reach reads only across the map, not up and down).
3. **The third question (Build's reading).** The build's notes carried no written third question, so Build took the one open reach point the work left: an animal view opened by the game's Info on an animal outside the ranch. Decided the way that keeps the game's reach and stakes: an animal with no livestock zone (a wild animal, one in a trailer or in a hutch outside a zone) keeps the game's reach for its info window: 5 tiles from the animal, 4 from the hutch or trailer; a held animal stays; past it, or once the animal dies or leaves the world, the view steps back (to the overview). The debug cheat lifts it, as it does the game's. Animals in a zone stay in the ranch view from anywhere, as before (ZeD's own ranch, approved earlier).

## Setup

- QA save (Saves/Sandbox/ZeD-QA), ZEDQA_NOSTEAM=1, the drag strip home. Spawn or find: a TV and a house radio in a powered house (or a generator), a portable radio (ValuTech or Premium) and a walkie, a car with a fitted radio, a livestock zone with two or three animals (one chicken in a hutch helps), one wild animal if one is near.
- Run each block twice: at 4K fullscreen (1.75x) and at Deck size (1280x800, Auto scale, Normal and Large text). Mouse first, then the controller.
- Close both ZeD windows before each step unless the step says otherwise, then try it again with both windows already open.
- What should never show in any step: the game's gray "Device Options" window with Power, Volume and Channel panels, the game's animal info window (the big stats window with the 3D animal), the game's zone window (the grid of animal portraits with Close / Reload / Info) or the game's first-time zone note (the long help page).

## 1. TV and house radio (World window, Radio tab)

| # | How | What should show |
|---|---|---|
| 1.1 | Stand next to a TV. Left-click the TV. | World window opens (or comes down if rolled up) on the Radio tab, showing that TV's face. |
| 1.2 | Sit on a couch 4 to 8 tiles from the TV. Right-click the TV > Device Options. | Radio tab on that TV. The header pill reads Floor and the browse count includes it. Power, volume and channel work from there. |
| 1.3 | From 1.2, walk 3 tiles toward the TV and back. | The tab stays on the TV the whole time (it doesn't jump to another radio as the list re-sorts). |
| 1.4 | From 1.2, walk more than 10 tiles away. Walk back. | The TV drops off the tab once you are past 10 tiles. Walking back does not bring it back unless it is within the usual reach (next to you). |
| 1.5 | Right-click a TV more than 10 tiles away > Device Options. | The game's own behavior: its window opens and closes at once (nothing in ZeD). Note it if anything else happens. |
| 1.5a | From 1.2 (TV pinned across the room), walk up the stairs, then come back down near the TV's room (within 10 tiles). | The TV drops off the tab as you go up and does not come back when you come down. |
| 1.5b | Close the World window, open the TV again from across the room, close the window, go upstairs and back, open the Radio tab. | The TV is not on the list (the pin dropped while the window was closed). |
| 1.5c | Upstairs, right-click a TV on the floor below (if the menu offers it, e.g. through an open stairwell) > Device Options. | Nothing opens: no ZeD tab, no game window. |
| 1.6 | House radio (the wall or table radio of a house): left-click it, then right-click > Device Options. | Same as 1.1 and 1.2, on the house radio. |
| 1.7 | Place a portable radio on the floor (Place Item). Right-click its floor item > Device Options. | Radio tab on that placed radio. |
| 1.8 | With an item card open in the World window drawer (any furniture or a hutch card), left-click the TV. | The card closes and the Radio tab shows the TV. |
| 1.9 | With two radios in reach, open one by right-click, then use the header's browse keys. | Browsing moves between them; the one you browse to stays selected as you move about. |

## 2. Carried radio (Character window, Radio tab)

| # | How | What should show |
|---|---|---|
| 2.1 | Equip a portable radio in the main hand. Right-click it in the inventory > Device Options. | Character window opens on the Radio tab, on that radio. |
| 2.2 | Radio in the off hand, walkie on the back (or in the other hand). Right-click the walkie > Device Options. | Radio tab on the walkie (its two-way face), not on the first radio. |
| 2.3 | Equip a radio with the Character window closed. | Nothing opens (unchanged: equipping never opens anything). |

## 3. Car radio and car device parts

| # | How | What should show |
|---|---|---|
| 3.1 | Driver's seat. Vehicle wheel (V) > Device Options. | The car radio comes up close above the dash (unchanged). |
| 3.2 | Outside the car, open the Vehicle tab's parts, right-click the Radio part > Device Options (if the menu offers it). | World window Radio tab on the car's radio (pill reads Vehicle), drawn as the simple radio card. |
| 3.3 | A modded car with a second device part (any mod that adds one), from the wheel. | World window Radio tab on that part. |
| 3.4 | From 3.2, take the radio out of the car. | The part drops off the tab. |

## 4. Animal info (World window, Animals tab, the animal's view)

| # | How | What should show |
|---|---|---|
| 4.1 | Right-click a zone animal within 5 tiles > Animal > Info. | World window on the Animals tab, on that animal's view (its zone above it in the breadcrumb). |
| 4.2 | Controller: D-pad Animal wheel near an animal > Info slice. | Both windows open, the pad is in the World window on the animal's view, B goes back to the zone. |
| 4.3 | Hutch chicken: hutch card > a bird's INFO. | The bird's view (unchanged, but check it still works). |
| 4.4 | A wild animal (debug or cheat, if your build shows Info on it). | The animal's view with no zone; Back goes to the overview. |
| 4.5 | Trailer with an animal: Vehicle tab > trailer > animal > INFO. | The animal's view (the walk happens first if you are not at the trailer). |
| 4.6 | From 4.4 (a wild animal's view), walk away or let it run off past 5 tiles. | The view steps back to the overview, as the game's window would close. |
| 4.7 | From 4.5, walk more than 4 tiles from the trailer. | The view steps back. |
| 4.8 | From 4.1 (a zone animal), walk far away. | The view stays (zone animals are the ranch's, seen from anywhere). |

## 5. Check zone (World window, Animals tab, the zone's view)

| # | How | What should show |
|---|---|---|
| 5.1 | Right-click inside a livestock zone > Check zone (name). | World window on the Animals tab, on that zone's view, the zone outlined on the ground. No first-time note. |
| 5.2 | Draw a new empty zone, then right-click inside it > Check zone. | That new zone's view (not the overview). |
| 5.3 | Controller: open the world menu with the pad inside a zone > Check zone. | Both windows open, the pad on the zone view's breadcrumb. |
| 5.4 | With the Animals tab already on another zone, Check zone on a second zone. | The view switches to the second zone. |
| 5.5 | In a zone's view, point at the "?" button left of Sort. | Its name "Help" after the delay; the help line reads the game note's first sentence ("Farm animals needs a Livestock Zone..."). |
| 5.6 | Press the "?" button. | A ZeD note (striped bar, one OK) with the game's whole livestock zone note. OK closes it; nothing else changes. Try it at Deck size with Large text: the note scrolls if it does not fit. |
| 5.7 | Controller: move to the "?" button, press A, then A on OK. | The note opens with the pad on OK; after OK the pad is back in the World window. |

## 6. Hand-backs

| # | How | What should show |
|---|---|---|
| 6.1 | Turn ZeD's safe mode on. Repeat 1.1, 2.1, 4.1 and 5.1. | The game's own windows open each time, and the first-time zone note shows the first time. Turn safe mode off: ZeD again, with no restart. |
| 6.2 | ZeD setup: turn the windows switch off (the game's inventory windows). Repeat 1.1 and 4.1. | The game's own windows (ZeD's World window can't open). |
| 6.3 | Split screen: player 1 with the World window open, player 2 left-clicks a TV and checks a zone. | Player 2 gets the game's own windows; player 1's window is untouched. |
| 6.4 | Check console.txt after the run for `[ZeD] WorldRoutes`, `[ZeD] RadioWindow` or `[ZeD] Animals:` lines. | None, unless a step fell back on purpose (3.3 on a radio with no face prints one line). |

## Captures

One each, after the window stops growing: 1.2 (TV across the room), 2.2 (walkie), 3.2 (car part, pill Vehicle), 4.1 (animal view), 5.1 (zone view), at 4K and at Deck size.
