# KISS test: the Crafting and Build tabs (QA, Nov 25 2026)

The director, Nov 23 2026: "With every one of these micro QA passes, also do a KISS test." This covers the Craft and Build sweep (cb.txt: cr_tab + bd_tab, run at 4K and 1280x800 on e03647b72 and 60a9d636d). The maps are 2026-11-25_map_crafting.md (C1-C24) and 2026-11-25_map_build.md (B1-B20).

## Steps for the common jobs, the game against ZeD

| Job | The game | ZeD, Crafting tab |
| --- | --- | --- |
| Craft one | Row, Craft (2) | Row, Craft (2); pad A, A (2) |
| Craft many | Max or a number, Craft (2) | Max, Craft (2); the amount shows only when more than one can be made |
| Choose inputs | Auto off, then pick each item (n) | Slot, type, Back, Craft (4); by type, never by item |
| See progress | A bar on the window; Craft grayed while it runs | Craft grayed while it runs (fixed in this pass); no bar |
| Know a tool may wear | The input tooltip says it may degrade, sharpness, worn or not | Not shown |
| Pin a recipe | Star (1), the game's Favourites | Star or right-click (1); ZeD's list of 8, now merged with the game's favourites; a 9th drops the oldest silently |

| Job | The game | ZeD, Build tab |
| --- | --- | --- |
| Start placing | Pick, Build (2), or a double-click (1) | Pick, Build (2); a double-click only opens the card |
| Build another | Click again once the first ends | Click again (fixed in this pass: the cursor re-arms) |
| Cancel | Esc or right-click (1) | Esc or right-click (1) (fixed: one Esc) |
| Choose which planks | The manual-select panel | None |
| Find one | Category, search; every recipe listed | Category, search; opens on Known, skill-short ones hidden |

## Bugs (to Build, with evidence; every one seen at both sizes)

The first run (e03647b72) proved 16:
- **Build tab:** B1, B2, B3, B4, B5, B6, B7, B10, B11.
- **Crafting tab:** C1, C4, C7, C9, C12, C13, C18.

Build merged fixes as 60a9d636d. The rerun found 13 fixed. Still open and with Build:
- B10: the skill line is cut to "Req...".
- B6: the preview's facing doesn't reach the cursor on a mouse Build.
- B7: a build placed far from its materials runs its whole time for nothing.
- New, small: on the half card, the pin star's zone runs past the tab's edge.

## Design calls for the director

Asked as numbered choices in chat. Option 1 is QA's pick in each.
1. **Which item a craft uses.** The game lets you pick each item; ZeD picks by type. Options: item-level choice in the alternatives list, or keep.
2. **Progress while crafting.** The game shows a bar. Options: a progress band on the craft card while it runs, or keep.
3. **Tool wear.** The game's tooltip says a tool may degrade, its sharpness, and whether it must be worn. Options: show those on the card's tool rows, or keep.
4. **The 9th pin.** It silently drops the oldest. Options: no cap (pins grow the group), a word when one drops, or keep.
5. **Build double-click.** The game's double-click starts placing; ZeD's opens the card. Options: double-click starts placing, or keep.
6. **Build list opens on Known.** Recipes you lack the skill for are hidden. Options: open on All, with skill-short ones marked, or keep.
7. **Choosing materials.** The game's manual-select lets you pick which planks. Options: a pick list on the card's materials, or keep.

## Not staged

- A lit kiln or forge: it needs fuel and in-game hours; a pottery wheel stood in.
- Recipe-at-hand literature: no recipe the game lets through was found in the QA world.
- A table 2 squares away.
- Admin and server-only paths.
- MP safehouses.
- Languages other than EN (only key coverage is checked).
