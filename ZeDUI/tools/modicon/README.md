# ZeD-GUI's mod icons and names

One look and one name pattern for every mod in the ZeD-GUI family, so they read as one family in the Mods menu.
The director picked the disk from five options on Nov 20 2026, and the name pattern with it.

## The icon: a disk

ZeD-GUI is the system disk; every add-on is another disk in the box.

- **Stays the same:** the 3.5-inch disk and its cut corner, the metal shutter, the paper label with its band, the Z
  pressed into the plastic.
- **Each mod brings two things:** its mark on the label, and one of ZeD's nine accents for the plastic. PZ Teal is
  ZeD-GUI's alone, and no two mods share an accent.
- **The file:** `icon.png`, 64 x 64, beside `mod.info` in the version folder (`42/`), named there by `icon=icon.png`.
  The cut corner is clear. ZeD's release staging ships whatever `poster=` and `icon=` name.
- **Why 64 px and thick lines:** the game draws a mod's icon at 18 to 84 px with plain bilinear filtering and no
  mipmaps (ZeD's Mods list: 24 units, so 24 px at 1080p, 18 on a Steam Deck, 84 at 4K with UI scale 1.75; vanilla's
  list: its button height; its load order: 28). The icon is drawn on a 32 x 32 grid, one cell to 2 px, and every line
  in a mark is 2 cells or wider. A thinner line drops out at 18 px.
- **Not the poster:** `poster.png` stays the mod's own picture, the big one in the Mods screen's details. The icon is
  never a shrunken poster.

## A mark

- A text grid in `MARKS` in `modicon.py`: `X` ink, `o` the light face, `.` the paper.
- At most 24 cells wide and 14 tall; the tool centers it on the label.
- One idea, one silhouette. Check it with `--proof` before it ships: it has to read at 18 px on Dark and Light.

## The name

- ZeD-GUI itself: `ZeD-GUI`.
- Every other mod in the family: `ZeD-GUI: <its name>`. The colon sits right after ZeD-GUI, then the mod's own name
  as it is spelled (Multi-Slot, Picks). In the Mods menu they sort right under ZeD-GUI.
- While a mod's version is a beta, ` [BETA]` ends its name. A released mod has no tag.
- A mod with its own Workshop item uses the same string as its Workshop title.
- At release, the tag comes off `name=` in mod.info and off the Workshop title, in the same change as the version.
- The family is ZeD-GUI, its add-ons and its helpers. Lua Console 93 and the other standalone mods keep their own
  names and icons; the dev-only QA mods never ship.

## The family now

| Mod | Mod id | Name in the Mods menu | Mark | Accent | icon.png |
|---|---|---|---|---|---|
| ZeD-GUI | ZeD_UI | ZeD-GUI [BETA] | zed | teal | `42/icon.png` |
| Multi-Slot | ZeDMultiSlot | ZeD-GUI: Multi-Slot [BETA] | slots | orange | `42/icon.png` in the ZeD-MultiSlot repo |
| Picks | ZeD_Picks | ZeD-GUI: Picks | check | green | `ZeDUI/picks_mod/ZeD_Picks/42/icon.png` |
| Watches (planned) | | ZeD-GUI: Watches | watch | blue | |

## Making them

From this folder:

    py modicon.py zed teal ../../../42/icon.png
    py modicon.py check green ../../picks_mod/ZeD_Picks/42/icon.png
    py modicon.py slots orange ~/Zomboid/ZeD-MultiSlot/42/icon.png
    py modicon.py --modinfo ../../../42/mod.info "ZeD-GUI [BETA]"
    py modicon.py --proof proof.png

A new add-on: draw its mark in `MARKS`, add its row to `MODS`, pick a free accent, run `--proof`, then write its
icon.png and run `--modinfo` on its mod.info with its name. Change the script, never the picture.
