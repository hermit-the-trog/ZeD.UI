"""The window tabs, in ink (the tabs' own metaphors, kept): loot, equip, health (the heart, in i_sym), thermal,
identity, journal, skills, radio (the walkie), craft, build, furniture (the chair), maps (the map), forage (the
magnifier), animals (the cow), vehicle (the car), appearance, traits"""
import math

from kit import icon


@icon("crate", "tab", "a slatted wooden crate, braced: the loot tab", ["loot tab"])
def crate(c, s):
    if s == 16:
        c.rect(1, 1, 14, 14); c.rect(2, 2, 12, 12, v=0)                          # the frame
        for y in (3, 7, 11): c.rect(2, y, 12, 2)                               # the slats
        c.line([(2.5, 2.5), (13.5, 13.5)], 3, v=0); c.line([(2.5, 2.5), (13.5, 13.5)], 1.2)   # the brace
    else:
        c.rect(1, 1, 22, 22); c.rect(3, 3, 18, 18, v=0)
        for y in (4.5, 10, 15.5): c.rect(3, y, 18, 4)
        c.line([(3.5, 3.5), (20.5, 20.5)], 4.6, v=0); c.line([(3.5, 3.5), (20.5, 20.5)], 2.2)


@icon("jacket", "tab", "a zipped jacket: the equipment tab", ["equip tab"])
def jacket(c, s):
    if s == 16:
        c.grid(["....###..###....",
                "...####..####...",
                "..######.#####..",
                ".#######.######.",
                ".##.####.####.##",
                ".##.####.####.##",
                ".##.####.####.##",
                ".##.####.####.##",
                ".##.####.####.##",
                ".##.####.####.##",
                ".##.####.####.##",
                ".##.####.####.##",
                "....####.####...",
                "....#########..."], oy=1)
        c.rect(8, 3, 1, 11, v=0)
        c.rect(5, 8, 2, 1, v=0); c.rect(10, 8, 2, 1, v=0)
    else:
        c.poly([(7, 1), (10, 1), (12, 6), (14, 1), (17, 1), (21, 4), (23, 8), (23, 21), (20, 21), (19.5, 10), (19, 23), (5, 23), (4.5, 10), (4, 21), (1, 21), (1, 8), (3, 4)])
        c.line([(4.5, 9.5), (5, 21)], 1, v=0); c.line([(19.5, 9.5), (19, 21)], 1, v=0)
        c.rect(11.5, 6, 1, 17, v=0)
        c.rect(7, 13, 3, 1.2, v=0); c.rect(14, 13, 3, 1.2, v=0)


@icon("thermometer", "tab", "a thermometer with its scale: the thermal tab", ["thermal tab"])
def thermometer(c, s):
    if s == 16:
        c.rect(5, 1, 4, 10); c.rect(6, 2, 2, 8, v=0); c.rect(6, 6, 2, 4)
        c.dot(7, 12.5, 3)
        for y in (2, 4, 6, 8): c.rect(11, y, 3 if y % 4 == 2 else 2, 1)
    else:
        c.rrect(7.5, 0.5, 6, 15, 3); c.rect(9.5, 2.5, 2, 12, v=0); c.rect(9.5, 8, 2, 7)
        c.dot(10.5, 18.5, 4.8)
        for y in (2, 5.5, 9, 12.5): c.rect(16, y, 5 if y in (2, 9) else 3.5, 2)


@icon("idcard", "tab", "an ID card, a portrait and its lines: the identity tab", ["identity tab"])
def idcard(c, s):
    if s == 16:
        c.rrect(1, 3, 14, 10, 1)
        c.rect(2, 4, 5, 8, v=0); c.rect(3, 5, 3, 3); c.rect(2, 9, 5, 3)          # the portrait
        c.rect(8, 5, 6, 1, v=0); c.rect(8, 7, 6, 1, v=0); c.rect(8, 9, 4, 1, v=0)  # the lines
    else:
        c.rrect(1, 4, 22, 16, 1.5)
        c.rect(3, 6, 8, 12, v=0); c.dot(7, 9.5, 2.4); c.rrect(3.5, 13, 7, 5, 2)
        c.rect(13, 7.5, 8, 1.5, v=0); c.rect(13, 11, 8, 1.5, v=0); c.rect(13, 14.5, 5, 1.5, v=0)


@icon("notebook", "tab", "a spiral notebook and a pencil: the journal tab", ["journal tab"])
def notebook(c, s):
    if s == 16:
        c.rect(1, 2, 10, 13)
        for x in (2, 4, 6, 8): c.rect(x, 1, 1, 3)
        c.rect(1, 4, 10, 1, v=0)
        for y in (7, 9, 11): c.rect(3, y, 6, 1, v=0)
        c.rect(13, 1, 2, 11); c.px((13, 12))
        c.rect(13, 3, 2, 1, v=0)
    else:
        c.rect(1, 3, 16, 20)
        for x in (3, 6.5, 10, 13.5): c.rect(x, 1, 1.5, 4.5)
        c.rect(1, 5.5, 16, 1.5, v=0)
        for y in (10, 13.5, 17): c.rect(4, y, 10, 1.5, v=0)
        c.rect(19.5, 1, 3, 16); c.poly([(19.5, 17), (22.5, 17), (21, 21.5)]); c.rect(19.5, 4, 3, 1.2, v=0)


@icon("skills", "tab", "bars rising: the skills tab", ["skills tab"])
def skills(c, s):
    if s == 16:
        for i, x in enumerate((1, 5, 9, 13)): c.rect(x, 14 - (4 + 3 * i), 2, 4 + 3 * i)
    else:
        for i, x in enumerate((1.5, 7.5, 13.5, 19.5)): c.rect(x, 22 - (5 + 5.5 * i), 3, 5 + 5.5 * i)


@icon("craft", "tab", "a hammer and a wrench, upright: crafting, the craft tab", ["IGUI_BackButton_Crafting", "Carpentry_On", "craft tab"])
def craft(c, s):
    if s == 16:
        c.rect(1, 1, 6, 3); c.rect(1, 3, 1, 1, v=0); c.rect(3, 4, 2, 11)              # the hammer
        c.grid(["##..##",
                "##..##",
                "######",
                ".####.",
                "..##..",
                "..##..",
                "..##..",
                "..##..",
                "..##..",
                ".####.",
                "##..##",
                "##..##",
                ".####."], ox=9, oy=2)
    else:
        c.rect(1.5, 1.5, 9, 4.5); c.rect(1.5, 4.5, 1.5, 1.5, v=0); c.rect(4.5, 6, 3, 17)
        c.dot(18.5, 5, 4.5); c.rect(16.8, 0, 3.4, 5.5, v=0)
        c.rect(17, 8, 3, 9)
        c.dot(18.5, 19.5, 3.8); c.dot(18.5, 19.5, 1.6, v=0)


@icon("bricks", "tab", "a brick wall: building, the build tab", ["IGUI_BackButton_Building", "Build_Tool", "build tab"])
def bricks(c, s):
    if s == 16:
        for row, y in enumerate((2, 5, 8, 11)):
            off = 0 if row % 2 == 0 else -3
            for x in range(1 + off, 16, 6):
                x0, x1 = max(1, x), min(15, x + 5)
                if x1 > x0: c.rect(x0, y, x1 - x0, 2)
        c.rect(1, 14, 14, 1)
    else:
        for row, y in enumerate((2, 7, 12, 17)):
            off = 0 if row % 2 == 0 else -5
            for x in range(1 + off, 24, 10):
                x0, x1 = max(1, x), min(23, x + 9)
                if x1 > x0: c.rect(x0, y, x1 - x0, 4)
        c.rect(1, 22, 22, 1.5)


@icon("mirror", "tab", "a hand mirror and a hairbrush: the appearance tab", ["appearance tab"])
def mirror(c, s):
    if s == 16:
        c.oring(4.5, 5, 4, 1.4); c.px((3, 4), (4, 3))
        c.rect(4, 9, 2, 6)
        c.rrect(10, 1, 5, 7, 1.4)
        for (x, y) in ((11, 2), (13, 2), (11, 4), (13, 4)): c.rect(x, y, 1, 1, v=0)      # the bristles
        c.rect(11, 8, 3, 7)
    else:
        c.ellipse(7, 7.5, 6, 7); c.ellipse(7, 7.5, 3.8, 4.8, v=0); c.line([(5, 5), (6.5, 3.5)], 1.2)
        c.rect(5.5, 14.5, 3, 8.5)
        c.rrect(14.5, 1, 8, 11, 2.5)
        for (x, y) in ((16.5, 3), (19.5, 3), (16.5, 6), (19.5, 6), (16.5, 9) , (19.5, 9)): c.rect(x, y, 1.5, 1.5, v=0)
        c.rect(17, 12, 3, 11)


@icon("traits", "tab", "a level slider, its marker: the traits tab", ["traits tab"])
def traits(c, s):
    if s == 16:
        c.poly([(7, 1), (12, 1), (9.5, 4)])
        c.rect(1, 5, 14, 6); c.rect(2, 6, 12, 4, v=0); c.rect(2, 6, 8, 4)
        for x in (2, 6, 10, 13): c.rect(x, 12, 1, 2)
    else:
        c.poly([(11, 1), (19, 1), (15, 5.5)])
        c.rect(1, 7, 22, 9); c.rect(3, 9, 18, 5, v=0); c.rect(3, 9, 12, 5)
        for x in (2, 8, 14, 20): c.rect(x, 17.5, 2, 3)
