"""
Bake the ZeD OS desktop icons (Oct 15 2026; director: "Add icons to the desktop
to open the menus ... Normal application type icons that would be on a desktop.
Make a trashcan icon with system32.dll in the trash can (little joke).")

32 x 32 pixel art in the 1993 desktop manner: 1-pixel black outlines, a few flat
colours, light from the top left. Drawn in game at whole multiples (nearest
filtering), so every pixel stays square.

Writes 42/media/textures/ZeD/mainmenu/icons/<name>.png:
  pz        Project Zomboid (the application)   newgame   New Game (a fresh character sheet)
  load      Load Game (a floppy disk)           join      Join a Server (two computers on a cable)
  options   Options (the control panel)         mods      Mods (a folder with a gear)
  trash     the Trash (full: there is a file in it)
  computer  the Computer (inside the Trash: the old joke of throwing the computer away)

Usage:  py ZeDUI/tools/mainmenu/bake_desktop_icons.py [--sheet out.png]
"""
import os
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = os.path.join(ROOT, "42", "media", "textures", "ZeD", "mainmenu", "icons")

K = (0, 0, 0, 255)
W = (255, 255, 255, 255)
L = (204, 204, 204, 255)      # light grey
M = (153, 153, 153, 255)      # mid grey
D = (85, 85, 85, 255)         # dark grey
G = (60, 140, 60, 255)        # green
GL = (150, 190, 120, 255)     # zombie skin
GD = (70, 100, 60, 255)       # skin shade
B = (80, 110, 170, 255)       # blue
BL = (160, 180, 220, 255)     # light blue
Y = (232, 192, 64, 255)       # yellow
R = (184, 58, 46, 255)        # red
F = (204, 204, 255, 255)      # folder lilac (the 1993 folder colour)
FD = (136, 136, 204, 255)     # folder shade
BR = (150, 100, 60, 255)      # brown


class Icon:
    def __init__(self):
        self.im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        self.px = self.im.load()

    def p(self, x, y, c):
        if 0 <= x < 32 and 0 <= y < 32:
            self.px[x, y] = c

    def rect(self, x0, y0, x1, y1, c):            # filled, inclusive
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.p(x, y, c)

    def box(self, x0, y0, x1, y1, fill, edge=K):  # filled with a 1-px outline
        self.rect(x0, y0, x1, y1, edge)
        if x1 - x0 >= 2 and y1 - y0 >= 2:
            self.rect(x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill)

    def hline(self, x0, x1, y, c): self.rect(x0, y, x1, y, c)
    def vline(self, x, y0, y1, c): self.rect(x, y0, x, y1, c)

    def line(self, x0, y0, x1, y1, c):
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.p(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy; x0 += sx
            if e2 <= dx:
                err += dx; y0 += sy

    def shadow(self):
        """the 1993 drop: none (icons sat flat on the desktop); kept for symmetry"""
        return self


def document(ic, fill=W):
    """a page with a folded corner (x 6..25, y 2..29)"""
    x0, y0, x1, y1 = 6, 2, 25, 29
    ic.box(x0, y0, x1, y1, fill)
    # the fold
    for i in range(6):
        ic.hline(x1 - 5 + i, x1, y0 + i, (0, 0, 0, 0))
    ic.line(x1 - 6, y0, x1, y0 + 6, K)
    ic.vline(x1 - 6, y0, y0 + 6, K)
    ic.hline(x1 - 6, x1, y0 + 6, K)
    for i in range(1, 6):
        ic.hline(x1 - 5, x1 - 6 + i, y0 + i, L)


def icon_pz():
    ic = Icon()
    # the application diamond
    c = 15.5
    for y in range(32):
        for x in range(32):
            d = abs(x - c) + abs(y - c)
            if d <= 15:
                ic.p(x, y, K if d > 14 else (BL if (x + y) < 31 else B))
    # a zombie's head in it
    ic.box(10, 8, 21, 21, GL)
    ic.rect(11, 9, 20, 10, GD)                    # the hairline shadow
    ic.rect(12, 12, 14, 14, K); ic.p(13, 13, R)  # eyes, one red
    ic.rect(17, 12, 19, 14, K)
    ic.vline(15, 15, 16, GD)                      # nose
    ic.hline(12, 19, 18, K)                       # the stitched mouth
    for x in (13, 15, 17):
        ic.vline(x, 17, 19, K)
    ic.rect(14, 22, 17, 24, GD); ic.vline(14, 22, 24, K); ic.vline(17, 22, 24, K)   # neck
    return ic


def icon_newgame():
    ic = Icon()
    document(ic)
    # a person on the sheet (a fresh character)
    ic.box(13, 9, 18, 14, Y)                      # head
    ic.box(11, 16, 20, 25, B)                     # body
    ic.hline(12, 19, 16, BL)
    # the plus badge
    ic.box(18, 20, 26, 28, G)
    ic.hline(20, 24, 24, W); ic.vline(22, 22, 26, W)
    return ic


def icon_load():
    ic = Icon()
    ic.box(4, 4, 27, 27, D)                       # the disk's body
    ic.p(4, 4, (0, 0, 0, 0)); ic.p(27, 4, K)
    # the metal shutter
    ic.box(10, 4, 22, 13, L)
    ic.rect(18, 6, 20, 11, D)
    ic.hline(11, 21, 5, W)
    # the label
    ic.box(8, 16, 23, 27, W)
    ic.hline(10, 21, 19, B); ic.hline(10, 18, 22, B); ic.hline(10, 20, 25, M)
    ic.rect(5, 24, 6, 25, K)                      # write-protect hole
    return ic


def small_computer(ic, x, y, screen=BL):
    """a little computer: 12 wide, 13 tall, at (x, y)"""
    ic.box(x, y, x + 11, y + 9, L)
    ic.box(x + 2, y + 2, x + 9, y + 7, screen)
    ic.box(x + 1, y + 10, x + 10, y + 12, L)
    ic.hline(x + 6, x + 9, y + 11, D)


def icon_join():
    ic = Icon()
    small_computer(ic, 1, 3)
    small_computer(ic, 19, 15, screen=GL)
    # the cable between them
    ic.vline(7, 16, 24, K); ic.hline(7, 18, 24, K)
    ic.vline(8, 16, 23, M); ic.hline(8, 18, 23, M)
    # the plug's light
    ic.rect(4, 22, 5, 23, Y)
    return ic


def icon_options():
    ic = Icon()
    ic.box(3, 4, 28, 27, L)                       # the panel
    ic.hline(4, 27, 5, W); ic.vline(4, 5, 26, W)
    ic.hline(4, 27, 9, K); ic.rect(4, 6, 27, 8, M)   # its title strip
    for i, (kx, ky) in enumerate(((8, 20), (15, 13), (22, 17))):
        ic.vline(kx, 11, 25, K)                   # the slider track
        ic.vline(kx + 1, 11, 25, W)
        ic.box(kx - 2, ky - 1, kx + 3, ky + 2, (R, B, G)[i])
    return ic


def icon_mods():
    ic = Icon()
    # the folder's tab, then its body
    ic.box(3, 6, 13, 10, F)
    ic.box(3, 9, 28, 27, F)
    ic.hline(4, 27, 10, W)
    ic.rect(4, 24, 27, 26, FD)
    # a gear on it
    cx, cy = 16, 18
    for y in range(32):
        for x in range(32):
            dx, dy = x - cx, y - cy
            r2 = dx * dx + dy * dy
            if r2 <= 16:
                ic.p(x, y, D)
    for tx, ty in ((cx, cy - 5), (cx, cy + 5), (cx - 5, cy), (cx + 5, cy), (cx - 4, cy - 4), (cx + 4, cy - 4), (cx - 4, cy + 4), (cx + 4, cy + 4)):
        ic.rect(tx - 1 if tx != cx else tx, ty - 1 if ty != cy else ty, tx, ty, D)
    ic.rect(cx - 1, cy - 1, cx + 1, cy + 1, F)
    return ic


def icon_trash():
    ic = Icon()
    # papers sticking out of the full can
    ic.box(9, 3, 16, 9, W); ic.line(10, 5, 15, 5, M)
    ic.box(15, 2, 22, 8, Y)
    # the lid, bulging up a little, and its handle
    ic.box(5, 8, 26, 11, L)
    ic.box(13, 6, 18, 8, L)
    # the can, ribbed
    ic.box(7, 12, 24, 29, L)
    for x in (10, 13, 16, 19, 22):
        ic.vline(x, 14, 27, M)
        ic.vline(x + 1, 14, 27, W)
    ic.hline(8, 23, 28, M)
    return ic


def icon_computer():
    """the whole computer, an all-in-one of the time (Oct 21 2026: it sits in the Trash, the
    old joke of dragging the computer to the trash)"""
    ic = Icon()
    ic.box(6, 2, 25, 24, L)                       # the case
    ic.hline(7, 24, 3, W); ic.vline(7, 3, 23, W)  # its lit edges
    ic.hline(7, 24, 23, M); ic.vline(24, 4, 23, M)
    ic.box(9, 5, 22, 15, D)                       # the bezel
    ic.box(10, 6, 21, 14, BL)                     # the screen
    ic.hline(12, 16, 8, B); ic.hline(12, 19, 10, B); ic.hline(12, 14, 12, B)   # a few lines of text
    ic.rect(15, 12, 15, 12, K)                    # the cursor
    ic.hline(15, 22, 19, K); ic.hline(16, 21, 20, D)   # the floppy slot
    ic.rect(9, 19, 10, 20, G)                     # the power light
    ic.box(8, 25, 23, 28, L)                      # the foot
    ic.hline(9, 22, 27, M)
    return ic


ICONS = {"pz": icon_pz, "newgame": icon_newgame, "load": icon_load, "join": icon_join,
         "options": icon_options, "mods": icon_mods, "trash": icon_trash, "computer": icon_computer}


def main():
    os.makedirs(OUT, exist_ok=True)
    made = {}
    for name, fn in ICONS.items():
        im = fn().im
        im.save(os.path.join(OUT, name + ".png"))
        made[name] = im
    if "--sheet" in sys.argv:
        out = sys.argv[sys.argv.index("--sheet") + 1]
        sheet = Image.new("RGBA", (len(made) * 40 * 4 + 8, 48 * 4), (90, 70, 110, 255))
        for i, (name, im) in enumerate(made.items()):
            sheet.alpha_composite(im.resize((128, 128), Image.NEAREST), (8 + i * 160, 16))
        sheet.save(out)
    print("baked", len(made), "icons ->", OUT)


if __name__ == "__main__":
    main()
