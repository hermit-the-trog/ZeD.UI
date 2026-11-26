# KISS test: the Vehicle (Mechanics) tab (QA, Nov 26 2026)

The director, Nov 23 2026: "With every one of these micro QA passes, also do a KISS test." This covers the Mechanics sweep: mt.txt (mt_tab.lua), run at 4K and 1280x800 from f4efb9e92 to a0e0852af. The map is 2026-11-26_map_mechanics.md (M1-M18).

## Steps for the common jobs, the game against ZeD

| Job | The game | ZeD, Vehicle tab |
| --- | --- | --- |
| Look at a car | Right-click the car, Vehicle Mechanics (2), the walk and the look | The car's tab on the World window (1), the walk and the look |
| Take a part off | Right-click the part, Uninstall (2) | The row, Uninstall (2); pad A, A (2) |
| Put a part on | Right-click, Install, the item (3) | The row, the spare, Install (3); the best spare is picked for you (2) |
| Repair | Right-click, Repair, the recipe (3) | The row, Repair (2) |
| Fetch a tool and come back | The window stays up | The look stays while he's in reach (fixed in this pass) |
| See why not | The grayed option's tooltip | The NEEDS line on the card, in the game's words where it has them |

## Bugs (to Build, with evidence; seen at both sizes)

The first run proved 14:
- **M1:** Take engine parts said "loses condition"; the game sets the engine to 0.
- **M2:** a second press queued the whole chain again. Repair twice spent two sets of materials, and the hood was left open.
- **M3:** Install put on a different spare than the one picked.
- **M5:** pad A, A ran a secondary verb (Deflate, Take engine parts).
- **M8:** the half card drew the card off the tab.
- **M9:** Cancel left the uninstall queued.
- **M10a:** no reason given with the engine running.
- **M10c:** a step the game doesn't need.
- **M10f:** no "Can be repaired once uninstalled".
- **M11:** the pad's part menu was placed wrong, and B didn't shut it.
- **M12:** verbs ran while paused.
- **M13a:** a press on a part already gone.
- **M13b:** two cars of one model swapped names.
- **M16c:** the failure share read 35% where the real odds are 12%.

Build fixed them in fix/mechanics, then mech2 to mech6. Along the way:
- **M3:** Install's "did nothing" was the game dropping the chain when the picked spare from a crate wouldn't fit in his bags. The card now says "Too heavy for inventory" and greys Install, instead of failing silently.
- **M11:** the pad's menu opens by the row. The test had first read ZeD's full-screen menu layer instead of its list.

Test faults found and fixed in mt_tab:
- a logged "DONE" ended the run early;
- the game's testProfession throws on any string, so M10b SKIPs;
- the flash is drawn by the band;
- the half card is read from MT.layout;
- M3 staging overloaded him.

mt.txt on a0e0852af: 198 pass and 0 fail at both sizes. The 13 SKIPs are:
- multiplayer (M13c, M13d, M14);
- other languages (M17);
- the trailer hitch (M15);
- M10b profession;
- a debug game's seated menu (M11);
- M16c, which has nothing to show at 100% success.

## Design calls for the director

Asked as numbered choices in chat, option 1 QA's pick. **Decided Nov 26 2026:** Hermit picked option 1 on all four ("1 on all"). Built in fix/mech6 (f3b7e1a40, merged a0e0852af) and proved by mt_tab:
1. **M6, verbs from a seat:** grey every part verb while he sits in any car, with the game's "Must exit vehicle.", as the game's menu refuses. Proved: nothing queued from the seat, or at 25 km/h.
2. **M4, Repair at 100%:** grey, with "The part is at full condition." Proved: nothing spent.
3. **M7, the look:** kept while he's within 6 tiles. Leaving the tab no longer ends it or shuts the hood. Proved: Loot and back keeps the look.
4. **M10g, Install folded:** shown greyed, with the types that fit. Proved: 3 of 3 named.

Side effect: the tab's Open and Close window are now always grey (they were offered only while he sits). His own car's windows stay with the game's radial menu.

## Not staged

- Multiplayer: claims, another player taking a part or driving off.
- The trailer hitch, other languages and professions in part tables.
