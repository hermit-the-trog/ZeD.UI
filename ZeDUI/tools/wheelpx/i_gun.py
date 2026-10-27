"""The firearm's wheel (vanilla ISFirearmRadialMenu) and the light source's batteries.
One grammar, vanilla's: the pistol (its slide across the top, its grip at the left), and in the pocket under the barrel
an arrow and what goes in or comes out; the arrow pointing left (at the grip) puts it in, pointing right takes it out.
Racking is the slide's travel, a two-headed arrow; a jam is a warning mark."""
import math

from kit import icon


def _pistol(c, s):
    """a pistol from the side, muzzle right: the long slide across the top, the raked grip at the left, the guard"""
    if s == 16:
        c.grid(["................",
                ".##############.",
                ".##############.",
                ".##############.",
                "..####..#.......",
                "..####..#.......",
                "..#######.......",
                ".####...........",
                ".####...........",
                ".####...........",
                ".####..........."])
    else:
        c.rect(1, 2, 22, 5)                                                    # the slide
        c.rect(3, 3, 1, 3, v=0); c.rect(5, 3, 1, 3, v=0)                       # its serrations
        c.rect(21, 1, 1, 1)                                                    # the front sight
        c.poly([(2.5, 7), (9, 7), (7.5, 18), (1, 18)])                         # the grip, raked
        c.rect(13, 7, 2, 5); c.rect(8, 10, 5, 2)                               # the guard
        c.rect(11, 7, 1, 2)                                                    # the trigger


def _arrow(c, s, inward):
    """the arrow in the pocket, under the guard: pointing left at the grip (in) or right (out)"""
    if s == 16:
        for i in range(3): c.rect(6 + (i if inward else 2 - i), 11 - i, 1, 1 + 2 * i)
    else:
        for i in range(4): c.rect(10 + (i if inward else 3 - i), 15 - i, 1, 2 + 2 * i)


def _bullet(c, s, x, y, w=None):
    """a cartridge standing up, nose at the top"""
    if s == 16:
        if (w or 3) == 3: c.px((x + 1, y)); c.rect(x, y + 1, 3, 7)
        else: c.rect(x, y, 2, 7)
    else:
        w = w or 4
        c.ellipse(x + w / 2, y + 3, w / 2, 3); c.rect(x, y + 3, w, 10)


def _mag(c, s, x):
    """a pistol magazine: the body raked like the grip, a round's nose at its lips, the base plate"""
    if s == 16:
        c.grid([".##.",
                "####",
                "####",
                "####",
                "###.",
                "###.",
                "###.",
                "###.",
                "####"], ox=x, oy=6)
        c.px((x + 1, 8), (x + 1, 10), v=0)
    else:
        c.rect(x + 2, 8, 2, 1)                                                 # a round at its lips
        c.poly([(x + 1, 9), (x + 6, 9), (x + 5, 20), (x, 20)]); c.rect(x - 1, 20, 7, 2)
        for yy in (12, 15.5): c.rect(x + 2, yy, 1, 2, v=0)


@icon("mag_in", "gun", "the pistol, a magazine, an arrow into the grip: put the magazine in", ["FirearmRadial_InsertMagazine"])
def mag_in(c, s):
    _pistol(c, s); _arrow(c, s, True); _mag(c, s, 11 if s == 16 else 17)


@icon("mag_out", "gun", "the pistol, an arrow out to a magazine: take the magazine out", ["FirearmRadial_EjectMagazine"])
def mag_out(c, s):
    _pistol(c, s); _arrow(c, s, False); _mag(c, s, 11 if s == 16 else 17)


@icon("rounds_in", "gun", "the pistol, an arrow in from two rounds: load rounds into the gun", ["FirearmRadial_BulletsIntoFirearm"])
def rounds_in(c, s):
    _pistol(c, s); _arrow(c, s, True)
    if s == 16: _bullet(c, s, 10, 6, 2); _bullet(c, s, 13, 6, 2)
    else: _bullet(c, s, 16, 9, 3); _bullet(c, s, 20, 9, 3)


@icon("rounds_out", "gun", "the pistol, an arrow out to two rounds: unload the gun", ["FirearmRadial_BulletsFromFirearm"])
def rounds_out(c, s):
    _pistol(c, s); _arrow(c, s, False)
    if s == 16: _bullet(c, s, 10, 6, 2); _bullet(c, s, 13, 6, 2)
    else: _bullet(c, s, 16, 9, 3); _bullet(c, s, 20, 9, 3)


@icon("chamber", "gun", "the pistol, an arrow in from one round: chamber a round", ["FirearmRadial_ChamberRound"])
def chamber(c, s):
    _pistol(c, s); _arrow(c, s, True)
    if s == 16: _bullet(c, s, 11, 6)
    else: _bullet(c, s, 17, 9, 4)


@icon("rack", "gun", "the pistol, the slide's travel under it: rack the slide", ["FirearmRadial_Rack"])
def rack(c, s):
    _pistol(c, s)
    if s == 16:
        c.rect(7, 10, 7, 1); c.px((7, 9), (7, 11), (6, 10), (13, 9), (13, 11), (14, 10))
    else:
        c.rect(11, 15, 9, 2); c.poly([(8.5, 16), (12, 12.5), (12, 19.5)]); c.poly([(22.5, 16), (19, 12.5), (19, 19.5)])


@icon("unjam", "gun", "the pistol with a warning mark: clear the jam", ["FirearmRadial_Unjam"])
def unjam(c, s):
    _pistol(c, s)
    if s == 16: c.rect(11, 6, 2, 5); c.rect(11, 12, 2, 2)
    else: c.rect(16.5, 9, 3.5, 8.5); c.rect(16.5, 19, 3.5, 3.5)


@icon("rounds_mag", "gun", "a magazine, an arrow into it from two rounds: load the magazine", ["FirearmRadial_BulletsIntoMagazine"])
def rounds_mag(c, s):
    if s == 16:
        c.grid(["..###...",
                ".#####..",
                ".#####..",
                ".####...",
                ".####...",
                ".####...",
                ".####...",
                "####....",
                "####....",
                "####....",
                "####....",
                "######.."], ox=1, oy=2)
        c.px((3, 6), (3, 8), (3, 10), v=0)
        for i in range(3): c.rect(7 + i, 9 - i, 1, 1 + 2 * i)
        _bullet(c, s, 11, 5, 2); c.rect(13, 5, 2, 8)
    else:
        c.rect(5, 2, 3, 1)
        c.poly([(3, 3), (10, 3), (8.5, 20), (1.5, 20)]); c.rect(1, 20, 9, 2)
        for yy in (6, 9.5, 13): c.rect(5, yy, 1, 2, v=0)
        for i in range(4): c.rect(11 + i, 12 - i, 1, 2 + 2 * i)
        _bullet(c, s, 16, 6, 3); _bullet(c, s, 20, 6, 3)


# ------------------------------------------------------------------ the light source's batteries
def _battery(c, s):
    if s == 16:
        c.rect(1, 3, 11, 6); c.rect(12, 4, 2, 4)
        c.grid([".#.", "##.", ".##", ".#."], ox=5, oy=4, v=0)
    else:
        c.rrect(1, 4, 17, 10, 1); c.rect(18, 6.5, 3, 5)
        c.poly([(10.5, 5.5), (6.5, 9.6), (9.4, 9.6), (7.6, 12.6), (12, 8.4), (9.2, 8.4), (11, 5.5)], v=0)


@icon("battery_in", "gun", "a battery and a plus: put a battery in", ["LightSourceRadial_InsertBattery"])
def battery_in(c, s):
    _battery(c, s); c.badge("plus")


@icon("battery_out", "gun", "a battery and a minus: take the battery out", ["LightSourceRadial_RemoveBattery"])
def battery_out(c, s):
    _battery(c, s); c.badge("minus")
