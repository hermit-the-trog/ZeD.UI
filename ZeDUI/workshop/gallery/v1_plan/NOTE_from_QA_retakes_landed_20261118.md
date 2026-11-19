# QA to Design: gallery retakes, Nov 18 2026 (evening)

## Landed in `Screenshots\gallery_v1_wip`

| Capture | Chapter | What it shows |
|---|---|---|
| `story_03_route_map` | 34, The Route | Beta 20's Survey map over West Point at zoom 14, Dark + PZ Teal, 4K at 1.75x, the glasses fix. Town roads drawn as streets (Build's 4980c0db7: only real highways like 31W stay red; the key has no "Secondary highway" row). The map key open on Colors, the pointer on the Fossoil pin with its card, and Angel's note "fossoil. my old pumps" beside the pin. |
| `story_03b_route_note` | 34, The Route | The same view with the pointer parked: no card, so the note reads. |

No earlier copies of these two were in `gallery_v1_wip`, so nothing went to `_replaced_20261118`.

The QA save's West Point is marked known and visited before the shot. Otherwise the game's fog over unvisited
ground draws soft dark patches on the Dark map, and one of them sat behind the note.

Angel is a man: he, him (the director, Nov 18).

## Landed later the same evening

All at 4K, UI scale 1.75x, the glasses fix, Dark + PZ Teal for ZeD, pointer hidden, nothing in front of Angel. Each
picture replaced is in `_replaced_20261118`.

| Capture | Pitch / chapter | What it shows |
|---|---|---|
| `g1_01_zed` | Pitch 1 | Dark + PZ Teal. The same spot, moment and items as `g1_01_vanilla`: the stock spot, three apples (their stack open), the shelf's ten things, zoom 0.75. Angel is by the shelves at the middle; the figure at the bottom edge is one of the story's extras. |
| `g1_26_zed` | Pitch 3, chapter 18 | Dark + PZ Teal. The forecourt, the Character window alone on Health, the figure open with the left forearm lit and "Bandaged" in its detail. |
| `g1_46_craft_van` | Pitch 4, chapter 36 | The game's crafting window with none of the debug extras: no "( DBG:MakeMolotovCocktail)" line, no Force Action button, no "(tags: ...)" lines in the recipe list. The West Point kitchen. |
| `g1_46_craft_zed`, `g1_04_build_zed` | Chapters 36 and 4 | Retaken with `g1_46_craft_van` so the pair matches: Angel moved to a kitchen square with clear floor in front (in the earlier pair the island hid his legs). Same square in all three. |
| `zed_08a_mods_folders` | Chapter 8 | The Mods window in folders: Quality of life (7), Medical (4), Crafting (2), Maps (3, folded shut), Unfiled folded; the Quality of life folder's page on the right. 17 real Workshop mods. |
| `zed_08b_profiles` | Chapter 8 | Mod profiles, "Gallery run" picked: "Loading it: Turns on 1 (Expanded Media)" and its load order under three separators (Interface, Gameplay, Maps). |
| `zed_08c_load_order_separators` | Chapter 8 | The Load order with the three separators; Enhanced Medical – Chronic Conditions red at 9 ("needs Enhanced Medical (10)"), its rule shown on the right, Done waiting. |
| `zed_08d_seps_from_folders` | Chapter 8 (optional) | Just after "Replace separators with folders": five separators from the folders, "Nothing turned on or off." Retaken at 6 pm on Build's 2800b2651 (the director's call): mods in no folder keep their place, so Unfiled sits at the top with ZeD-GUI still first. All four chapter 8 pictures are from that same run. |

## Not landed

- **`zed_51_forage` (chapter 38):** on hold. The hand now follows the game's own pointer exactly (QA compared
  them side by side from the same spot). But the game puts a close find's pointer on a ring around the character,
  pointing outward, so the director reads the hands as "not pointing at the object". Build has put a choice to
  the director (hide the hand while its find is close and its pin shows). The retake follows the answer, with the
  hand at 40% (a455c5674) and nothing in front of the character.
