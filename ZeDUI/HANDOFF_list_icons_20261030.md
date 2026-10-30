# Handoff: the outfit and loadout icons (Oct 30 2026)

Design → Code. The two pixel icons owed by `HANDOFF_equip_doll_v4_loadouts_20261029.md`, each with an add and a
remove version. Drawn in the wheels' ink (`tools/wheelpx`, same rules: 16 at rest, 24 pointed, 32 and 48 doubled).

| Id | Drawing | Use |
|---|---|---|
| `outfit` | a shirt on its hanger | the outfit everywhere: Journal rows, the mark strip, the submenu's saved outfits |
| `outfit_add` | the same, a plus | right-click "Save to outfit" |
| `outfit_remove` | the same, a minus | right-click "Take out of outfit" (where the item is already in one) |
| `loadout` | a clipboard with its list | the loadout everywhere |
| `loadout_add` | the same, a plus | right-click "Save to loadout" |
| `loadout_remove` | the same, a minus | right-click "Take out of loadout" |

They are kept apart from the everyday icons on purpose: the bare `hanger` stays Wear, the bare `shirt` stays
clothing, `view_list` stays List view. So a list never reads as an action.

Review sheet: `ZeDUI/mockups/zed_list_icons_v1/zed_list_icons_v1.png` (the six drawings zoomed, then a right-click
menu, the mark strip and the Journal rows in dark and light, at 1x and at 1.75).

## To do (Code)

1. `cd ZeDUI/tools/wheelpx && python export.py --game` writes the 24 new textures into
   `42/media/textures/ZeD/wheel/{16,24,32,48}/zw_<id>.png` (unchanged pixels keep their files).
2. `ZeD_Lists.lua`: `L.ICON = { outfit = "outfit", loadout = "loadout" }`, and use `<kind>_add` / `<kind>_remove`
   on the right-click rows that add and remove.
3. Mark strip: the item in the list draws the icon lit (the accent cell, text-on-accent ink, as the sheet shows); not
   in it, the plain ink. No badge on the strip; the plus and minus belong to the menu rows.
