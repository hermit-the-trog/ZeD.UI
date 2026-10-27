"""The 24 px side-view figures, placed on the doll's 24 template (head rows 0-6, gap 7, trunk 8-15, legs 16-23):
a 7 px head, a 4 px trunk, 2 px arms, 3 px legs; strokes go through chosen centres (3 px on pixel centres,
2 px on grid lines), so nothing is left to snapping."""
from doll import Px


def head(c, x0, y0=0):
    c.disc(x0, y0, 7)


def trunk(c, x0, y0=8, h=8, w=4, lean=0):
    for i in range(h):
        off = round(lean * (1 - i / max(1, h - 1)))
        c.rect(x0 + off, y0 + i, w, 1)
    c.put(x0 + lean, y0, False); c.put(x0 + lean + w - 1, y0, False)


def walk():
    c = Px(24)
    head(c, 8); trunk(c, 9)
    c.chain([(9, 10), (6, 13), (5, 15)], 2)                 # back arm
    c.chain([(13, 10), (16, 13), (19, 14)], 2)              # front arm
    c.chain([(10.5, 16.5), (7.5, 19.5), (5.5, 22.5)], 3)    # back leg
    c.chain([(11.5, 16.5), (14.5, 19.5), (16.5, 22.5)], 3)  # front leg
    return c


RUN24 = [
    "................###.....",
    "...............#####....",
    "..............#######...",
    "..............#######...",
    "..............#######...",
    "...............#####....",
    "................###.....",
    "........................",
    "..............##.....##.",
    ".............#####...##.",
    "..........######.##..##.",
    ".........##.####..##.#..",
    "....######.####....##...",
    "....####...####.........",
    "..........####..........",
    "..........####..........",
    "..........######........",
    ".........###.######.....",
    "........###.....###.....",
    ".......###......###.....",
    "......###......###......",
    ".....###.......###......",
    "....###.................",
    "...###..................",
]


def run():
    """redrawn Oct 27 by hand (the director: the first "looks like yoga"; a straight line of arms through the shoulders
    and a planted front shin made it a lunge): leaning in, the front arm bent and pumping, the back arm behind, the
    front knee up with its foot off the ground, the back leg pushing off"""
    c = Px(24)
    for y, r in enumerate(RUN24):
        for x, ch in enumerate(r):
            if ch == "#": c.put(x, y)
    return c


def sit():
    c = Px(24)
    head(c, 7); trunk(c, 8)
    c.chain([(11, 10), (14, 13), (17, 13)], 2)              # the arm on the knee
    c.rect(8, 15, 10, 3)                                    # the thigh
    c.rect(15, 18, 3, 6)                                    # the shin
    c.rect(4, 9, 1, 15)                                     # the chair's back
    c.rect(4, 18, 10, 1); c.rect(13, 18, 1, 6)              # its seat and front leg
    return c


def crouch():
    c = Px(24)
    head(c, 12, 5)
    c.chain([(13.5, 13.5), (10.5, 17.5)], 4)                # the trunk, bent forward
    c.chain([(15, 14), (18, 17), (19, 19)], 2)              # the arm down to the knee
    c.chain([(10.5, 18.5), (16.5, 18.5), (16.5, 22.5)], 3)  # front leg: thigh forward, shin down
    c.chain([(9.5, 18.5), (7.5, 22.5)], 3)                  # back leg, knee down
    c.rect(4, 22, 5, 2)                                     # the back foot
    return c


def climb():
    c = Px(24)
    for x in (16, 22): c.rect(x, 0, 1, 24)                  # the ladder
    for y in (2, 7, 12, 17, 22): c.rect(16, y, 7, 1)
    head(c, 6); trunk(c, 7)
    c.chain([(11, 9), (13, 5), (15, 2)], 2)                 # the arm up to the rung
    c.chain([(9.5, 16.5), (13.5, 14.5), (14.5, 16.5)], 3)   # the front leg, foot on the rung
    c.rect(7, 16, 3, 8)                                     # the back leg
    return c


def carry():
    c = Px(24)
    head(c, 6); trunk(c, 7)
    c.rect(15, 6, 8, 8)                                     # the box
    c.rect(11, 9, 4, 2)                                     # the arms out to it
    c.chain([(8.5, 16.5), (5.5, 22.5)], 3)                  # back leg
    c.chain([(9.5, 16.5), (12.5, 22.5)], 3)                 # front leg
    return c


G24 = {"walk": walk, "run": run, "sit": sit, "crouch": crouch, "climb": climb, "carry": carry}
