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

## Not landed

- **`zed_51_forage` (chapter 38):** on hold. The hand now follows the game's own pointer exactly (QA compared
  them side by side from the same spot). But the game puts a close find's pointer on a ring around the character,
  pointing outward, so the director reads the hands as "not pointing at the object". Build has put a choice to
  the director (hide the hand while its find is close and its pin shows). The retake follows the answer, with the
  hand at 40% (a455c5674) and nothing in front of the character.
