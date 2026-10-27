"""The character's wheel (D-pad down, ZeD_DpadWheels C.*): what you carry and do with your body"""
import math

from kit import icon


def U(o, u, pts):
    """points in a local frame: s along u, t across it (t toward u rotated +90)"""
    ux, uy = u; l = math.hypot(ux, uy); ux, uy = ux / l, uy / l; vx, vy = -uy, ux
    return [(o[0] + s * ux + t * vx, o[1] + s * uy + t * vy) for s, t in pts]


@icon("knife", "char", "a knife: the weapons, and killing an animal", ["Weapons", "AnimalActions_Kill"])
def knife(c, s):
    if s == 16:
        # a broad blade with its belly on the edge, a guard across, a handle with two rivets
        c.grid(["................",
                "..............#.",
                ".............##.",
                "............###.",
                "...........####.",
                "..........####..",
                ".........####...",
                "........####....",
                ".......####.....",
                ".....#.###......",
                "......#.#.......",
                ".....###.#......",
                "....###.........",
                "...###..........",
                "..###...........",
                "..##............"])
        c.px((4, 13), (6, 11), v=0)
    else:
        o = (9.5, 14.5); u = (1, -1)
        c.poly(U(o, u, [(0, -1.6), (17.4, -0.4), (17.8, 0.4), (12, 3.0), (5, 3.6), (0, 3.2)]))
        c.line(U(o, u, [(0, -3.8), (0, 5.0)]), 2.0)
        c.line(U(o, u, [(-1.8, 0.6), (-9.0, 0.6)]), 3.6)
        for k in (-4.0, -7.0): c.dot(*U(o, u, [(k, 0.6)])[0], 0.7, v=0)


@icon("apple", "char", "an apple: eat", ["ContextMenu_Eat"])
def apple(c, s):
    if s == 16:
        c.circle(6, 9.5, 4); c.circle(10, 9.5, 4); c.ellipse(8, 10.5, 5.5, 4.5)
        c.rect(7, 5, 2, 2, v=0)
        c.line([(8, 6), (8.5, 3)], 1.2)
        c.poly([(9, 3.5), (12, 2), (12.5, 3), (10, 4.5)])
        c.px((4, 8), (4, 9), (5, 7), v=0)
    else:
        c.circle(9, 14, 6); c.circle(15, 14, 6); c.ellipse(12, 15.5, 8, 6.5)
        c.rect(10.5, 7, 3, 3, v=0)
        c.line([(12, 9), (12.8, 4)], 1.6)
        c.poly([(13, 5.5), (17.5, 2.5), (18.5, 4.5), (14.5, 7)])
        c.line([(6, 12.5), (6, 15.5)], 1.4, v=0)


@icon("glass", "char", "a glass of water with a straw: drink", ["ContextMenu_Drink"])
def glass(c, s):
    if s == 16:
        c.poly([(2.5, 5), (12.5, 5), (11, 15), (4, 15)])                     # the glass, tapered
        c.poly([(3.6, 6), (11.4, 6), (10.1, 14), (4.9, 14)], v=0)
        c.poly([(4.1, 9), (10.9, 9), (10.1, 14), (4.9, 14)])                 # the water
        c.px((5, 10), (5, 11), v=0)                                           # a glint
        c.line([(8.5, 11), (11, 2.5), (14, 1.5)], 1.2)                         # the straw, bent over the rim
        c.rect(9, 6, 2, 3, v=0); c.line([(9.5, 9), (11, 3)], 1.2)
    else:
        c.poly([(3.5, 7), (19.5, 7), (17.5, 23), (5.5, 23)])
        c.poly([(5.2, 8.6), (17.8, 8.6), (16.0, 21.4), (7.0, 21.4)], v=0)
        c.poly([(5.9, 13), (17.1, 13), (16.0, 21.4), (7.0, 21.4)])
        c.rect(8, 15, 1.5, 4.5, v=0)
        c.rect(13, 8.6, 3, 4.4, v=0)
        c.line([(13, 17), (16, 4), (21, 2)], 1.8)


@icon("medkit", "char", "a first-aid case: medicine", ["UI_ZeD_Wheel_Medicine"])
def medkit(c, s):
    if s == 16:
        c.rect(5, 2, 6, 1); c.rect(5, 3, 1, 2); c.rect(10, 3, 1, 2)          # the handle
        c.rrect(1, 4, 14, 11, 2)
        c.rect(7, 6, 2, 7, v=0); c.rect(4, 8, 8, 2, v=0)                      # the cross, cut out
    else:
        c.rect(8, 3, 8, 2); c.rect(8, 5, 2, 3); c.rect(14, 5, 2, 3)
        c.rrect(2, 7, 20, 15, 3)
        c.rect(10, 9, 4, 11, v=0); c.rect(6, 12.5, 12, 4, v=0)


@icon("bandage", "char", "a sticking plaster: a wound", ["UI_ZeD_Wheel_Wound"])
def bandage(c, s):
    if s == 16:
        u = (math.sqrt(.5), -math.sqrt(.5))
        c.cap(2.5, 13.5, 13.5, 2.5, 2.6)                                        # the strip
        c.band(8, 8, *u, -2.6, -1.9, 2.8); c.band(8, 8, *u, 1.9, 2.6, 2.8)      # the pad's edges, across it
        c.px((4, 11), (11, 4), v=0)                                            # a hole at each end
    else:
        c.line([(4.5, 19.5), (19.5, 4.5)], 8.4)
        c.poly([(12, 7.6), (16.4, 12), (12, 16.4), (7.6, 12)], v=0)
        c.poly([(12, 9.4), (14.6, 12), (12, 14.6), (9.4, 12)])
        for (x, y) in ((5.5, 17.5), (7.5, 18.5), (6.5, 15.5), (17.5, 5.5), (18.5, 7.5), (15.5, 6.5)): c.rect(x, y, 1, 1, v=0)


@icon("bed", "char", "a bed: sleep", ["ContextMenu_Sleep"])
def bed(c, s):
    if s == 16:
        c.rect(1, 3, 2, 12)                                                   # the headboard
        c.rrect(4, 7, 4, 2, 0.8)                                              # the pillow
        c.rect(3, 9, 12, 3)                                                   # the mattress
        c.rect(8, 8, 7, 1)                                                    # the blanket's fold
        c.rect(3, 12, 12, 1, v=0)
        c.rect(3, 13, 12, 1)                                                  # the frame
        c.rect(13, 14, 2, 1)                                                  # the foot
    else:
        c.rect(1, 4, 3, 19)
        c.rrect(5, 9, 7, 4, 1.5)
        c.rect(4, 13, 19, 5)
        c.rect(12, 11.5, 11, 1.5)
        c.rect(4, 18, 19, 1, v=0)
        c.rect(4, 19, 19, 2)
        c.rect(20, 21, 3, 2)


@icon("shirt", "char", "a shirt: clothing", ["UI_ZeD_Wheel_Clothing"])
def shirt(c, s):
    if s == 16:
        c.poly([(5, 2), (1, 5), (2.5, 8.5), (4, 7.5), (4, 15), (12, 15), (12, 7.5), (13.5, 8.5), (15, 5), (11, 2)])
        c.poly([(6, 2), (10, 2), (8, 4.6)], v=0)
    else:
        c.poly([(7.5, 2.5), (1, 7.5), (3.5, 12.5), (6, 11), (6, 23), (18, 23), (18, 11), (20.5, 12.5), (23, 7.5), (16.5, 2.5)])
        c.poly([(9, 2.5), (15, 2.5), (12, 6.8)], v=0)
        c.line([(5.5, 11.5), (6.8, 10.5)], 1, v=0); c.line([(18.5, 11.5), (17.2, 10.5)], 1, v=0)


@icon("backpack", "char", "a backpack: use, and the hands-free bag", ["UI_ZeD_Wheel_Use"])
def backpack(c, s):
    if s == 16:
        c.rect(6, 1, 4, 1); c.rect(5, 2, 1, 2); c.rect(10, 2, 1, 2)
        c.rrect(3, 3, 10, 12, 2)
        c.rect(3, 7, 10, 1, v=0)
        c.rect(5, 9, 6, 5, v=0); c.rect(6, 10, 4, 3)
        c.rect(7, 8, 2, 2)
    else:
        c.rect(9, 1, 6, 1.5); c.rect(8, 2, 1.5, 3); c.rect(14.5, 2, 1.5, 3)
        c.rrect(4, 4, 16, 19, 3)
        c.rect(4, 10, 16, 1.5, v=0)
        c.rect(7, 13.5, 10, 7, v=0); c.rect(8.5, 15, 7, 4)
        c.rect(11, 11, 2, 4)


@icon("hand", "char", "an open hand: hands free, nothing held", ["UI_ZeD_Wheel_HandsFree"])
def hand(c, s):
    if s == 16:
        c.grid(["................",
                "......##........",
                "...##.##.##.....",
                "...##.##.##.....",
                "...##.##.##.##..",
                "...##.##.##.##..",
                "...##.##.##.##..",
                "...###########..",
                "##.###########..",
                ".#.###########..",
                ".############...",
                "..###########...",
                "...#########....",
                "....#######.....",
                ".....#####......",
                "................"])
    else:
        for x, top in ((6.5, 4.5), (10.5, 2.5), (14.5, 3.5), (18.5, 6.5)):
            c.line([(x, top), (x, 13)], 3.2)
        c.rrect(5, 11, 15.2, 10, 3.5)
        c.line([(6, 18), (3.5, 14.5), (2.5, 11.5)], 3.2)                    # the thumb
        c.rect(5, 11, 15, 1)


@icon("cigarette", "char", "a cigarette with smoke: smoke", ["ContextMenu_Smoke"])
def cigarette(c, s):
    if s == 16:
        c.rect(1, 11, 10, 3); c.rect(12, 11, 3, 3)
        c.rect(1, 12, 1, 1, v=0)
        c.px((4, 9), (3, 8), (3, 7), (4, 6), (4, 5), (3, 4))
        c.px((7, 9), (7, 8), (8, 7), (8, 6))
    else:
        c.rect(2, 16, 15, 4); c.rect(18, 16, 4, 4)
        c.rect(2, 17, 1, 2, v=0)
        for x, y in ((5, 14), (4, 13), (4, 12), (5, 11), (5, 10), (4, 9), (4, 8), (5, 7), (5, 6)): c.rect(x, y, 1.5, 1)
        for x, y in ((9, 14), (9, 13), (10, 12), (10, 11), (9, 10), (9, 9)): c.rect(x, y, 1.5, 1)


@icon("book", "char", "an open book: read", ["ContextMenu_Read"])
def book(c, s):
    if s == 16:
        c.poly([(1, 3), (4, 2.4), (7.5, 3.6), (7.5, 13.4), (4, 12), (1, 12.6)])
        c.poly([(8.5, 3.6), (12, 2.4), (15, 3), (15, 12.6), (12, 12), (8.5, 13.4)])
        for y in (5, 7, 9): c.rect(2, y, 4, 1, v=0); c.rect(10, y, 4, 1, v=0)
        c.rect(1, 13, 14, 1)
    else:
        c.poly([(1, 4), (6, 3), (11.4, 5), (11.4, 20), (6, 18), (1, 19)])
        c.poly([(12.6, 5), (18, 3), (23, 4), (23, 19), (18, 18), (12.6, 20)])
        for y in (7, 10, 13, 16): c.rect(3, y, 6.5, 1.2, v=0); c.rect(14.5, y, 6.5, 1.2, v=0)
        c.rect(1, 20, 22, 2)


@icon("watch", "char", "a wristwatch: the watch", ["UI_ZeD_Wheel_Watch", "UI_ZeD_Wheel_OpenWatch"])
def watch(c, s):
    if s == 16:
        c.rect(5, 0, 6, 3); c.rect(5, 13, 6, 3)                              # the strap
        c.dot(8, 8, 5.5)
        c.dot(8, 8, 3.6, v=0)
        c.rect(7, 5, 1, 4); c.rect(8, 8, 3, 1)                                # the hands
        c.rect(14, 7, 1, 2)                                                    # the crown
    else:
        c.rect(7.5, 0, 9, 5); c.rect(7.5, 19, 9, 5)
        c.dot(12, 12, 8.5)
        c.dot(12, 12, 6.0, v=0)
        c.rect(11, 7, 2, 6); c.rect(12, 11, 5, 2)                             # the hands
        c.rect(11, 6, 2, 1, v=0)
        c.rect(20.5, 10.5, 2, 3)                                               # the crown


@icon("walkie", "char", "a two-way radio: the radio, and the radio tab", ["IGUI_ItemType_Radio", "radio tab"])
def walkie(c, s):
    if s == 16:
        c.rect(9, 1, 2, 4)                                                    # the antenna
        c.rect(5, 3, 2, 2)                                                    # a knob
        c.rrect(4, 5, 8, 10, 1)
        for y in (7, 9, 11): c.rect(6, y, 4, 1, v=0)                          # the grille
        c.px((6, 13), (9, 13), v=0)
    else:
        c.rrect(13.5, 0, 3, 9, 1.4)
        c.rect(8, 4, 3, 3)
        c.rrect(6, 7, 12, 16, 2)
        for y in (10, 12.5, 15): c.rect(9, y, 6, 1.2, v=0)
        for x in (9, 11.5, 14): c.rect(x, 18.5, 1.5, 1.5, v=0)
