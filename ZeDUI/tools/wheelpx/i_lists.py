"""The two lists' own icons (equip doll v4, loadouts and outfits; handoff Oct 29 2026: "an outfit (a hanger) and a
loadout (a list)"). They serve the right-click menu, the item card's mark strip, the Equip bar and the Journal page.
Drawn apart from the everyday icons they grew from, so a list never reads as an action:

  outfit          a shirt on its hanger: an outfit (the bare hanger stays "wear"; the bare shirt stays "clothing")
  outfit_add      ... with a plus: save to an outfit, put this in the outfit
  outfit_remove   ... with a minus: take this out of the outfit
  loadout         a clipboard with its list: a loadout (the bare lines stay "list view")
  loadout_add     ... with a plus: save to a loadout, put this in the loadout
  loadout_remove  ... with a minus: take this out of the loadout

ZeD_Lists.lua: L.ICON = { outfit = "outfit", loadout = "loadout" }.
"""
from kit import icon


# ------------------------------------------------------------------ the outfit: a shirt hung on its hanger
def _outfit(c, s):
    """the hanger's own hook (as "hanger") over a shirt's mass: no collar cut, so the hook never reads as a question"""
    if s == 16:
        c.grid(["......###.......",      # the hook, as the hanger's
                ".....##.##......",
                ".........##.....",
                "........##......",
                ".......##.......",
                "....########....",      # the shirt on the hanger's shoulders
                "..############..",
                ".##############.",
                ".###.######.###.",      # the sleeves part from the body
                "....########....",
                "....########....",
                "....########....",
                "....########....",
                "....########....",
                "....########...."], oy=0)
    else:
        c.arc(12, 4.5, 3, 180, 440, 2.4, caps=True)                    # the hook, as the hanger's
        c.line([(12, 7.5), (12, 9)], 2.4)
        c.poly([(7, 9), (1, 13.5), (3, 18.5), (6, 17), (6, 23), (18, 23), (18, 17), (21, 18.5), (23, 13.5), (17, 9)])
        c.line([(5.6, 17.6), (6.9, 16.3)], 1.2, v=0); c.line([(18.4, 17.6), (17.1, 16.3)], 1.2, v=0)   # the sleeves part


@icon("outfit", "lists", "a shirt on its hanger: an outfit", ["outfit"])
def outfit(c, s):
    _outfit(c, s)


@icon("outfit_add", "lists", "a shirt on its hanger, a plus: save to an outfit", ["outfit add"])
def outfit_add(c, s):
    _outfit(c, s); c.badge("plus")


@icon("outfit_remove", "lists", "a shirt on its hanger, a minus: take out of the outfit", ["outfit remove"])
def outfit_remove(c, s):
    _outfit(c, s); c.badge("minus")


# ------------------------------------------------------------------ the loadout: a clipboard and its list
def _loadout(c, s):
    if s == 16:
        c.rect(2, 3, 12, 12)                                             # the board
        c.rect(4, 1, 8, 4, v=0)                                          # clear round the clip
        c.rect(5, 1, 6, 3); c.rect(7, 0, 2, 1)                           # the clip and its eye
        c.rect(7, 1, 2, 1, v=0)
        for y in (6, 9, 12):                                             # the list: a box and a line per row
            c.rect(4, y, 2, 2, v=0); c.rect(7, y, 5, 1, v=0)
    else:
        c.rect(3, 4, 18, 19)
        c.rect(6, 1, 12, 6, v=0)
        c.rect(7, 2, 10, 4); c.rect(10, 0, 4, 2)
        c.rect(11, 1, 2, 2, v=0)
        for y in (9, 13.5, 18):
            c.rect(6, y, 3, 3, v=0); c.rect(11, y + 0.5, 7, 2, v=0)


@icon("loadout", "lists", "a clipboard with its list: a loadout", ["loadout"])
def loadout(c, s):
    _loadout(c, s)


@icon("loadout_add", "lists", "a clipboard with its list, a plus: save to a loadout", ["loadout add"])
def loadout_add(c, s):
    _loadout(c, s); c.badge("plus")


@icon("loadout_remove", "lists", "a clipboard with its list, a minus: take out of the loadout", ["loadout remove"])
def loadout_remove(c, s):
    _loadout(c, s); c.badge("minus")
