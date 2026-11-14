"""main menu desk v8 (the director, Nov 13 2026): the Lua Console 93 box where the two blank books stood, the game's
arm lamp gone and no lamp in its place ("Just get rid of the lamp. I don't want a lamp there. It blocks a poster."),
the black radio for the boombox, its handle gone too. From v7's two pictures."""
import sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

SRC = sys.argv[1]; RADIO = sys.argv[2]; OUT = sys.argv[3]
A = np.asarray(Image.open(f"{SRC}/desk_lampdim.png").convert("RGB")).astype(int)
L = np.asarray(Image.open(f"{SRC}/desk.png").convert("RGB")).astype(int)
H, W = A.shape[:2]
D = L - A
NAVY = (0, 4, 19)

def poly(pts):
    im = Image.new("L", (W, H), 0); ImageDraw.Draw(im).polygon(pts, fill=255); return np.asarray(im) > 0

def line(p0, p1, w):
    im = Image.new("L", (W, H), 0); ImageDraw.Draw(im).line([p0, p1], fill=255, width=w); return np.asarray(im) > 0

def grade(rgb):
    """a full-colour picture into the right side's night"""
    s = np.asarray(rgb).astype(float)
    lum = (0.3 * s[..., 0] + 0.59 * s[..., 1] + 0.11 * s[..., 2]) / 255.0
    f = (1 - lum) ** 2
    o = np.stack([s[..., 0] * 0.18, s[..., 1] * 0.20 + 3 * f, s[..., 2] * 0.17 + 18 * f], -1)
    return o

def tex(o, x0, y0):
    """the picture's fine checker"""
    yy, xx = np.mgrid[0:o.shape[0], 0:o.shape[1]]
    return o * (1 + 0.035 * (((xx + x0 + yy + y0) % 2) * 2 - 1))[..., None]

N = A.copy()

# ---------------------------------------------------------------- left: the arm lamp out
head = poly([(38, 72), (46, 66), (60, 67), (100, 94), (100, 101), (66, 131), (59, 130)])
arm = line((0, 98), (45, 73), 9)
pole = np.zeros((H, W), bool); pole[94:214, 0:13] = True
old = ndi.binary_dilation(head | arm, iterations=2) | pole
yy, xx = np.mgrid[0:H, 0:W]
PX0, PX1, PY0, PY1 = 8, 97, 77, 175             # the poster
in_poster = (xx >= PX0) & (xx <= PX1) & (yy >= PY0) & (yy <= PY1)
sky_c = [(0, 16, 17), (0, 18, 18)]
def sky(x, y): return sky_c[(x + y) % 2]
# the trees, read from the clean left of the poster (columns 12..43), repeated across
def is_tree(x, y):
    sx = 22 + (x - 22) % 22
    c = A[y, sx]
    return c[1] < 10
for y in range(H):
    for x in range(W):
        if not old[y, x]: continue
        if in_poster[y, x]:
            if x <= 9 or y <= 78: N[y, x] = A[y, 60] if y <= 78 else A[min(y, 174), 96 if x == 8 else 95]
            elif y >= 139: N[y, x] = NAVY
            elif y >= 100 and is_tree(x, y): N[y, x] = NAVY
            else: N[y, x] = sky(x, y)
        elif y < PY0:                            # the wall over the poster: the bricks repeat every 17
            for dx in (34, -34, 17, -17, 51):
                sx = x + dx
                if 0 <= sx < 98 and not old[y, sx]: N[y, x] = A[y, sx]; break
        elif x < PX0:                            # the wall left of the poster
            N[y, x] = A[62 + (y - 62) % 15, x] if y <= 185 else NAVY
        elif x > PX1 and y < 176:               # the wall right of the poster
            N[y, x] = A[y + 14, x] if not old[y + 14, x] else A[y + 28, x]
        else:
            N[y, x] = NAVY
# the poster's left edge and what the lamp's post and its shadow hid there: the edge line, the sky, the trees
for y in range(78, 176):
    N[y, 8] = (0, 4, 20)
    for x in range(9, 22):
        if y >= 139: N[y, x] = NAVY if x < 12 else N[y, x]
        elif y <= 79: N[y, x] = A[y, 60]
        elif y >= 100 and is_tree(x, y): N[y, x] = NAVY
        else: N[y, x] = sky(x, y)
# under the poster, left: the bricks carry on to the edge of the picture (darker toward it), then the dark of the shelf
for y in range(176, 186):
    for x in range(0, 13): N[y, x] = A[y, x + 17] * (0.5 + 0.04 * x)
for y in range(186, 216):
    for x in range(0, 17):
        if x < 13 or A[y, x].max() < 40 and A[y, x][0] < 14: N[y, x] = (0, 3, 18) if (x + y) % 2 else (0, 4, 19)
# the sky one even green again: the old lamp's halo had tinted it past the shade's edge
for y in range(81, 139):
    for x in range(10, 96):
        if N[y, x][1] >= 12 and N[y, x][0] < 30: N[y, x] = sky(x, y)
mm = (A[80:110, 10:40, 0] >= 35); mys, mxs = np.nonzero(mm)
mcx, mcy = (mxs.min() + mxs.max()) / 2 + 10, (mys.min() + mys.max()) / 2 + 80
mr = max(mxs.max() - mxs.min(), mys.max() - mys.min()) / 2 + 0.3
moon = np.hypot(xx - mcx, yy - mcy) <= mr
N[moon] = (40, 49, 56)
# what the lamp gave the room, with the old lamp's own shape taken out of it
Df = D.astype(float)
grow = ndi.binary_dilation(old, iterations=3)
wgt = (~grow).astype(float)
num = np.stack([ndi.gaussian_filter(Df[..., c] * wgt, 7) for c in range(3)], -1)
den = ndi.gaussian_filter(wgt, 7)[..., None] + 1e-6
Dn = np.where(grow[..., None], num / den, Df)
# no ghost of the old lamp's beam across the poster's sky
soft = np.stack([ndi.gaussian_filter(Dn[..., c], 16) for c in range(3)], -1)
skyreg = in_poster & (yy < 139) & (yy > 79) & (xx > 9) & (xx < 96)
Dn = np.where(skyreg[..., None], soft, Dn)

# the poster's green zombie, whole (the lamp's shade had stood in front of all but its legs; the director, Nov 13 2026:
# "It's supposed to be a poster depicting the original. There was a zombie, a green zombie, in the trees.")
ZOMBIE = [
    "...#####...",
    "...#####...",
    "...#.#.#...",
    "...#####...",
    "...##.##...",
    "....###....",
    ".#########.",
    "###########",
    "##.#####.##",
    "##.#####.##",
    "##.#####.##",
    "##.#####.##",
    "##.#####.##",
    "##.#####.##",
    "#..#####.##",
    "...#####.##",
    "...#####..#",
    "...#####...",
    "...##.##...",
    "...##.##...",
]
NEAR = [
    "......######......",
    ".....########.....",
    ".....########.....",
    ".....#o####o#.....",
    ".....########.....",
    "......#oooo#......",
    "......######......",
    ".......####.......",
    "...############...",
    "..##############..",
    ".################.",
    "###.##########.###",
    "###.##########.###",
    "##..##########..##",
    "##..##########..##",
    "##..##########..##",
    "##..##########..##",
    "##..##########..##",
    "....##########....",
    "....##########....",
    "....#####.####....",
    "....####..####....",
    "....####..####....",
    "....####..####....",
    "....####..####....",
    "....####..####....",
    "....####..####....",
    "....####..####....",
    "....####..####....",
]
FAR = [".###.", ".###.", "..#..", "#####", "#.#.#", "#.#.#", ".#.#.", ".#.#.", ".#.#."]

def zombie(img, col):
    """the poster's picture, an original one that nods to the game (the director, Nov 13 2026: "Can you nod a little
    closer to the game?"; not the box art, which is The Indie Stone's): a boarded farmhouse with one lit window under
    the moon, the dead coming out of the tree line, one of them close"""
    col = np.asarray(col, float)
    dark = np.array((0, 4, 19.0))
    # the farmhouse, left, under the moon
    hs = np.array((2, 8, 22.0))
    for y in range(117, 139):
        for x in range(11, 36):
            roof = 117 <= y <= 124 and abs(x - 23) <= (y - 117) * 1.6 + 1
            wall = 125 <= y <= 138 and 14 <= x <= 32
            chim = 114 <= y <= 121 and 29 <= x <= 30
            if roof or wall or chim: img[y, x] = hs
    for y in range(114, 117): img[y, 29] = hs; img[y, 30] = hs
    amber = col * 0 + np.array((44, 32, 9.0)) * (col[1] / 30.0)
    for y in range(128, 134):
        for x in range(19, 26): img[y, x] = hs if (y in (129, 132) or x == 22) else amber      # its window, boarded
    # far ones, small, back in the trees
    for (x0, y0) in ((40, 122), (50, 119)):
        for r, row in enumerate(FAR):
            for c, ch in enumerate(row):
                if ch == "#": img[y0 + r, x0 + c] = col * 0.75
    # the one that always stood there
    x0, y0 = 59, 107
    for r, row in enumerate(ZOMBIE):
        for c, ch in enumerate(row):
            if ch == "#": img[y0 + r, x0 + c] = col
    for y in range(127, 138):
        for x in (61, 62, 66, 67): img[y, x] = col if y < 133 else col * (0.0, 0.97, 0.96)
    # the near one, right, cut off by the title
    x0, y0 = 75, 110
    for r, row in enumerate(NEAR):
        for c, ch in enumerate(row):
            if x0 + c > 95 or y0 + r > 138: continue
            if ch == "#": img[y0 + r, x0 + c] = col * 1.5
            elif ch == "o": img[y0 + r, x0 + c] = dark
    return img

WALKER = [
    "....###......",
    "...#####.....",
    "...#####.....",
    "...####......",
    "....###......",
    "...#####.....",
    "..###########",
    "..######....#",
    "..#########..",
    "..#####...##.",
    "..#####......",
    "..#####......",
    "..#####......",
    "..######.....",
    "..###.###....",
    ".###...###...",
    ".###....###..",
    "###.....###..",
    "###......###.",
    "##.......###.",
    "##........###",
    "###.......###",
]

def poster(img):
    """the poster's picture, the director's, Nov 13 2026: "Just do a house. A silhouette of a stumbling zombie walking
    in profile towards the house. One or two trees, a moon ... Just use navies." An original picture, not the game's
    box art: a night sky in navies, everything on it a silhouette, one lit window."""
    sil = np.array((0, 3, 16.0))
    for y in range(78, 139):
        t = max(0.0, (y - 80) / 58.0) ** 1.4
        c0 = np.array((0, 7, 25.0)) * (1 - t) + np.array((7, 25, 47.0)) * t
        for x in range(9, 97):
            if y <= 80 and img[y, x][0] > 25: continue          # the pins
            img[y, x] = c0 + ((x + y) % 2) * np.array((0, 1, 2.0))
    img[moon] = (40, 49, 56)
    def put(x, y):
        if 9 <= x <= 96 and 79 <= y <= 138: img[y, x] = sil
    # the ground
    for x in range(9, 97):
        for y in range(136, 139): put(x, y)
    # a pine, left, across the moon's edge; a smaller one beside the house
    for (tx, top, base, hw) in ((14, 97, 136, 7), (58, 117, 136, 4)):
        for y in range(top, base):
            f = (y - top) / (base - top)
            w = int(round(hw * f * (0.55 + 0.45 * (((y - top) % 9) / 9.0)))) if y < base - 3 else 0
            for x in range(tx - w, tx + w + 1): put(x, y)
            put(tx, y)
    # the house, right: its roof, chimney, body; one window lit, the door
    for y in range(106, 119):
        w = int((y - 106) * 1.25) + 1
        for x in range(78 - w, 78 + w + 1): put(x, y)
    for y in range(103, 112):
        for x in range(85, 88): put(x, y)
    for y in range(119, 137):
        for x in range(66, 91): put(x, y)
    amber = np.array((46, 34, 10.0))
    for y in range(123, 129):
        for x in range(69, 75):
            if not (y == 125 or x == 71): img[y, x] = amber
    for y in range(128, 137):
        for x in range(80, 85): img[y, x] = np.array((3, 10, 26.0))
    # the walker, stumbling toward it: leaning, arms out
    x0, y0 = 36, 115
    for r, row in enumerate(WALKER):
        lean = int(round((len(WALKER) - 1 - r) * 0.14))
        for c, ch in enumerate(row):
            if ch == "#": put(x0 + c + lean, y0 + r)
    return img

N = poster(N.astype(float))

# ---------------------------------------------------------------- left: the table lamp
CX = 44
def lamp(img, lit):
    sh_t, sh_b = 105, 133
    for y in range(sh_t, sh_b + 1):
        t = (y - sh_t) / (sh_b - sh_t)
        hw = 11 + t * 10
        for x in range(int(CX - hw), int(CX + hw) + 1):
            if not (0 <= x < W): continue
            u = (x - CX) / hw                                   # -1..1 across the shade
            if lit:
                b = 1.0 - 0.55 * abs(u) ** 1.6 + 0.25 * t       # the bulb glows through, brightest low and middle
                c = np.array((30, 84, 96)) * b + np.array((16, 12, 2)) * max(0, 1 - abs(u) * 1.6) * (0.4 + t)
            else:
                b = 0.95 - 0.45 * (u + 0.25) ** 2
                c = np.array((9, 36, 50)) * b
            if abs(u) > 0.93: c = c * 0.6
            if y == sh_t: c = c * 1.25
            if y == sh_b: c = c * (0.7 if not lit else 1.15)
            img[y, x] = c * (1 + 0.035 * (((x + y) % 2) * 2 - 1))
    for y in range(sh_b + 1, sh_b + 4):                          # the lamp holder under the shade
        for x in range(CX - 2, CX + 3): img[y, x] = (22, 24, 26) if not lit else (40, 36, 26)
    for y in range(sh_b + 4, 191):                               # the stem, down behind the can
        if y >= 183 and A[y, CX].max() > 24: break
        img[y, CX - 1] = (16, 24, 34) if not lit else (26, 30, 34)
        img[y, CX] = (5, 10, 22)
    for y in range(189, 197):                                    # the round base, behind the can
        hw = {189: 4, 190: 8, 191: 10, 192: 11, 193: 11, 194: 10, 195: 8, 196: 4}[y]
        for x in range(CX - hw, CX + hw + 1):
            if img[y, x][0] < 12 and not (17 <= x <= 57 and y >= 186 and A[y, x][0] > 12):
                img[y, x] = (18, 26, 36) if y <= 191 else (8, 14, 26)
    return img

def glow(img):
    """the lit lamp on the wall and the poster: out of the shade's foot and, less, its top"""
    o = img.astype(float)
    for (gx, gy, r, amp) in ((CX, 142, 46, 1.0), (CX, 101, 26, 0.35)):
        dist = np.hypot(xx - gx, (yy - gy) * 1.15)
        f = np.clip(1 - dist / r, 0, 1) ** 1.6 * amp
        f = np.where(xx < 100, f, 0)
        o = o + f[..., None] * np.array((26, 19, 8)) * (0.35 + o.max(-1, keepdims=True) / 70.0)
    return o

# ---------------------------------------------------------------- right: the homemade radio, the Lua Console 93 box
rim = Image.open(RADIO).convert("RGBA")
RW = 97; RH = int(round(rim.height * RW / rim.width))
rim = rim.resize((RW, RH), Image.LANCZOS)
ra = np.asarray(rim)[..., 3] > 110
RX, RY = 380, 191 - RH
PL, PR_ = 396, 467                              # the Hevey Dewis poster, its dark edge included
rg = tex(grade(np.asarray(rim)[..., :3]), RX, RY)
# what stands in front of it and stays: the leaning book, The Sim2 box
front = poly([(380, 170), (394, 170), (396, 176), (399, 192), (380, 192)]) | ((xx >= 404) & (xx <= 422) & (yy >= 168))
front &= (yy < 192)
FONT = {"L": ["100", "100", "100", "100", "111"], "U": ["101", "101", "101", "101", "111"], "A": ["010", "101", "111", "101", "101"],
        "C": ["111", "100", "100", "100", "111"], "O": ["111", "101", "101", "101", "111"], "N": ["101", "111", "111", "111", "101"],
        "S": ["111", "100", "111", "001", "111"], "E": ["111", "100", "110", "100", "111"], "9": ["111", "101", "111", "001", "111"],
        "3": ["111", "001", "011", "001", "111"], " ": ["000"] * 5, "P": ["111", "101", "111", "100", "100"], "R": ["110", "101", "110", "101", "101"],
        "F": ["111", "100", "110", "100", "100"], "I": ["111", "010", "010", "010", "111"], "T": ["111", "010", "010", "010", "010"],
        "D": ["110", "101", "101", "101", "110"]}
def vtext(img, s, x, y, col):
    """spine lettering, reading down (the letters' tops to the right)"""
    for ch in s:
        g = FONT[ch]
        for r in range(5):
            for c in range(3):
                if g[r][c] == "1": img[y + c, x + 4 - r] = col
        y += 4
    return y

def right(img):
    # the boombox's handle, off the poster: its bar (rows 102..104) and its two posts. On the wall either side of the
    # poster the boards run straight down, so a pixel comes from the same column higher up; on the poster, from its row
    for x in range(379, 470):
        on_wall = x < 397 or x > 467
        for y in range(101, 110):
            if on_wall: img[y, x] = A[y - 10, x]
            elif y in (102, 103): img[y, x] = A[101, x]
            elif y == 104: img[y, x] = A[105, x]
    for y in range(101, 110):
        for x in range(462, 467): img[y, x] = img[y, x - 5]
    # behind the radio, where the boombox was taller: the poster's foot, then the wall. The wall is boards, as beside
    # the poster: the lit board's two-colour weave, a dark seam every 17 (391, 408, 425 ... as along the top)
    for y in range(110, 191):
        for x in range(380, 477):
            if front[y, x]: continue
            if PL <= x <= PR_ and y <= 113: img[y, x] = img[106 + (y - 110) % 4, x]
            elif PL <= x <= PR_ and y == 114: img[y, x] = (0, 3, 20)
            elif x <= 391 or x >= 470: img[y, x] = A[92 + (y - 110) % 10, x]
            elif (x - 391) % 17 == 0: img[y, x] = (0, 3, 20)
            else: img[y, x] = A[92 + (y - 110) % 10, 386 + (x % 2)]
    reg = img[RY:RY + RH, RX:RX + RW]
    keep = front[RY:RY + RH, RX:RX + RW] | ~ra
    img[RY:RY + RH, RX:RX + RW] = np.where(keep[..., None], reg, rg)
    # the gap the second book leaves, right of the box
    for y in range(191, 237):
        for x in range(450, 456): img[y, x] = (0, 3, 18) if (x + y) % 2 else (0, 4, 18)
    # the pale lines along the foot of the boxes (rows 238..242) were left from older things (the director: "not
    # controller buttons ... leftover lines from other stuff"): the boxes run down to the controller, the dark behind them
    for y in range(237, 243):
        for x in range(402, W):
            if x <= 403: img[y, x] = A[236 + (y % 2), x]
            elif x in (404, 422, 423): img[y, x] = (0, 3, 20)
            elif x <= 421: img[y, x] = A[y - 6, x]
            else: img[y, x] = (0, 3, 18) if (x + y) % 2 else (0, 4, 18)
    bx0, bx1, by0, by1 = 424, 449, 150, 242
    mag = grade(np.array([[(214, 52, 132)]]))[0, 0]; mag_d = mag * 0.72
    cream = grade(np.array([[(245, 238, 215)]]))[0, 0]; yel = grade(np.array([[(244, 196, 48)]]))[0, 0]
    teal = grade(np.array([[(74, 166, 150)]]))[0, 0]; ink = np.array((0, 3, 18.0))
    for y in range(by0, by1 + 1):
        for x in range(bx0, bx1 + 1):
            edge = x in (bx0, bx1) or y == by0
            c = ink if edge else (mag_d if x >= bx1 - 2 else mag)
            img[y, x] = c * (1 + 0.035 * (((x + y) % 2) * 2 - 1))
    yend = vtext(img, "LUA CONSOLE 93", bx0 + 4, by0 + 5, cream)
    vtext(img, "PROFESSIONAL EDITION", bx0 + 13, by0 + 5, yel) if False else vtext(img, "PRO EDITION", bx0 + 13, by0 + 5, yel)
    return img

dim = right(N.astype(float).copy())
lit = right(N.astype(float) + Dn)

LCX, LCY, LRX, LRY = 36.0, 191.0, 17.4, 4.8       # the can's lid: narrower than the can
OCX, OCY, ORX, ORY = 36.0, 192.0, 20.6, 5.6       # the flat top it had, as wide as the can
SCY = 196.0                                       # where the shoulder meets the can's full width (the director:
                                                  # "Make the taper start from lower down", as on his photo)

def can_taper(img):
    """the soda can tapers in to its lid (the director, Nov 13 2026: "The top of a real soda can, even in that day,
    tapered in towards the top ... The lid is smaller than the diameter of the middle of the can."): the lid drawn
    smaller, a bare-metal shoulder sloping from its rim out to the can's side"""
    old = img.copy()
    # the neck is printed too (the director: "make that taper orange because it's part of the printed can"): each
    # column's orange read from the label just under the neck, gaps (the fruit's outline, a leaf) filled from beside
    # one printed orange (the label's brightest, as on its lit right side), shaded round the can as a cylinder lit
    # from the right, the way the label itself is
    pool = [old[y, x] for y in range(196, 216) for x in range(17, 58)
            if old[y, x][0] > 40 and old[y, x][0] >= 1.6 * old[y, x][1] and old[y, x][0] >= 2.0 * old[y, x][2]]
    pool = sorted(pool, key=lambda c: c[0])
    base_or = np.mean(np.array(pool[int(len(pool) * 0.85):]), axis=0)
    orange = [None] * W
    for x in range(13, 60):
        u = max(-1.0, min(1.0, (x - OCX) / ORX))
        sh = 0.50 + 0.50 * ((u + 1) / 2) ** 1.2
        if u > 0.88: sh *= 0.86                                  # the far edge turning away
        orange[x] = base_or * sh
    for y in range(185, 206):
        for x in range(13, 60):
            eo = ((x - OCX) / ORX) ** 2 + ((y - OCY) / ORY) ** 2
            el = ((x - LCX) / LRX) ** 2 + ((y - LCY) / LRY) ** 2
            if y <= SCY: hw = LRX + (ORX - LRX) * max(0.0, min(1.0, (y - LCY) / (SCY - LCY))) if y >= LCY else -1
            else:
                q = 1 - ((y - SCY) / ORY) ** 2
                hw = ORX * q ** 0.5 if q > 0 else -1
            in_hull = abs(x - OCX) <= hw
            if y > OCY + ORY - 0.5:                                  # no wider than the can's body on that row
                body = [q for q in range(13, 60) if max(old[y, q]) >= 22]
                if not body or x < body[0] or x > body[-1]: in_hull = False
            if el <= 1.0:                                           # the lid: the old top, shrunk
                sx = OCX + (x - LCX) * ORX / LRX                    # clean metal, in the old top's own light
                qs = [int(min(max(round(sx) + d_, 19), 53)) for d_ in (-2, -1, 0, 1, 2)]
                img[y, x] = np.mean([old[194, q] for q in qs], axis=0)
            elif in_hull:                                           # the shoulder: bare metal, in the lid's own light
                xs_ = [min(max(x + d_, 18), 54) for d_ in (-2, -1, 0, 1, 2)]
                src = np.mean([old[194, q] for q in xs_], axis=0)
                t = (y - LCY) / (SCY + ORY - LCY)
                if el <= 1.22: img[y, x] = src * 0.92               # the bead just outside the lid's rim: bare metal
                else: img[y, x] = orange[x] * (0.86 + 0.14 * min(1.0, t)) * (1 + 0.035 * (((x + y) % 2) * 2 - 1))   # the printed neck
            elif eo <= 1.08 and y < SCY and max(old[y, x]) >= 26:   # where the flat top was wider: what is behind
                img[y, x] = old[y, 13] if x < OCX else old[y, 59]
    # the step where the bare neck meets the label: the label's top row a shade darker under it
    for x in range(13, 60):
        q = 1 - ((x - OCX) / ORX) ** 2
        if q <= 0: continue
        yb = int(SCY + ORY * q ** 0.5) + 1
        if yb < 270 and max(old[yb, x]) >= 22: img[yb, x] = old[yb, x] * 0.82
    return img

def can_top(img):
    """its top with a rim ("has no depth or lip to it"): the raised rim bright all round, a dark line inside it where
    the lid sits lower, the lid a shade down, its tab as it was"""
    for y in range(185, 197):
        for x in range(16, 57):
            e = ((x - LCX) / LRX) ** 2 + ((y - LCY) / LRY) ** 2
            if e > 1.0: continue
            c = img[y, x]
            el_ = lambda yy_: ((x - LCX) / LRX) ** 2 + ((yy_ - LCY) / LRY) ** 2
            if e > 0.70 or el_(y - 1) > 1.0 or el_(y + 1) > 1.0: k = 1.16      # the rim, unbroken all round
            elif e > 0.44 or el_(y - 2) > 1.0: k = 0.66 if y <= LCY else 0.78  # deeper shadow under the far rim
            else: k = 0.9
            img[y, x] = np.minimum(c * k, 255)
    # the pull tab, lying at ten o'clock (the director: "make the pull tab angled at 10 o'clock"): from its rivet at
    # the middle of the lid up and to the left, its finger hole near the end; the mouth it opens, scored, toward four
    # (then: "the tab is at 10 o'clock, but it's pointing at 9 o'clock. So it needs to angle 45 degrees ... Make the
    # opening larger.") Drawn at 45 degrees on the picture, steeper than the low view of the lid would truly show.
    base = img[int(LCY), int(LCX)].copy()
    cx_, cy_ = int(LCX), int(LCY)
    # (then the director's photo of a real can: the tab a rounded loop with its ring hole at the far end, the opening
    # a dark oval reaching toward the rim at four to five o'clock)
    for (mx, my) in [(x, y) for y in (192, 193, 194) for x in range(35, 50)]:
        if ((mx - 42.0) / 6.2) ** 2 + ((my - 193.0) / 1.8) ** 2 <= 1.0: img[my, mx] = base * 0.42
    TAB = {191: (35, 40), 190: (33, 39), 189: (31, 37), 188: (31, 35)}              # a leaning loop, widest at its ring
    for y_, (xa, xb) in TAB.items():
        for x_ in range(xa, xb + 1):
            edge = x_ in (xa, xb) or y_ == 188
            img[y_, x_] = np.minimum(base * (1.5 if edge else 1.22), 255)
    for (hx, hy) in ((33, 189), (34, 189), (35, 190), (36, 190)): img[hy, hx] = base * 0.5      # the ring's hole
    img[191, 38] = np.minimum(base * 1.8, 255)                                     # the rivet
    return img

def relabel(img):
    """the can's label (the director, Nov 13 2026: "Remove the word soda, keep the word orange, move orange down to
    where soda is, move the orange and the corn graphic down so it just says orange"; then "just not do a white label
    strip at all and just have orange and white text over the orange background"): orange from the neck down to the
    dark band, the orange-and-corn picture lower, ORANGE in white where SODA was"""
    src = img.copy()
    X0, X1 = 17, 56
    isor = lambda c: c[0] >= 1.6 * c[1] and c[0] >= 2.0 * c[2] and c[0] >= 25
    # each column's printed orange, from the picture band's own background, smoothed round the can
    bg = np.full((W, 3), np.nan)
    for x in range(X0, X1 + 1):
        got = [src[y, x] for y in range(197, 214) if isor(src[y, x])]
        if len(got) >= 2: bg[x] = np.median(np.array(got), axis=0)
    xs_ok = [x for x in range(X0, X1 + 1) if not np.isnan(bg[x, 0])]
    for c in range(3):
        bg[X0:X1 + 1, c] = np.interp(range(X0, X1 + 1), xs_ok, [bg[x, c] for x in xs_ok])
    lum = lambda c: 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]
    # one printed orange shaded round the can by the light the plain dark band below it shows, column by column
    # (no stripes: the band is one flat print, so its light is the can's light)
    prof = np.array([lum(np.median(src[235:239, x], axis=0)) for x in range(W)], float)
    prof[X0:X1 + 1] = np.convolve(np.pad(prof[X0:X1 + 1], 1, mode="edge"), np.ones(3) / 3, mode="valid")
    xr = max(range(X0, X1 + 1), key=lambda x: prof[x])
    oref = bg[xr]
    for x in range(X0, X1 + 1):
        bg[x] = oref * prof[x] / prof[xr]
    cx_f, cy_f, r_f = 29.5, 205.5, 6.8                        # the fruit, in the old band
    # the white, as bright as the old band's brightest, shaded round the can the way the orange is
    whites = sorted([src[y, x] for y in range(213, 217) for x in range(X0, X1 + 1)
                     if not isor(src[y, x]) and max(src[y, x]) >= 30], key=lum)
    wref = np.mean(np.array(whites[int(len(whites) * 0.85):]), axis=0)
    bmax = max(lum(bg[x]) for x in range(X0, X1 + 1))
    D = 9                                                    # the picture moves down this far
    for y in range(197, 237):
        for x in range(X0, X1 + 1):
            if y >= 234 and (max(src[y, x]) < 26 or isor(src[y, x])): continue   # the dark band below stays
            img[y, x] = bg[x] * (1 + 0.035 * (((x + y) % 2) * 2 - 1))
            sy = y - D
            if 198 <= sy <= 212:                               # the orange and the corn, on the same orange
                c = src[sy, x]
                near = np.hypot(x - cx_f, sy - cy_f) <= r_f + 0.8
                leaf = c[1] > c[0] and c[1] > c[2]
                if sy in (198, 212) and not (near or leaf): continue   # the old band's top and bottom edge lines
                if not (isor(c) and not near): img[y, x] = c
    # ORANGE, white on the orange, where SODA stood (its letters read from the old band, rows 216..222)
    for y in range(216, 223):
        for x in range(24, 51):
            c = src[y, x]
            if c[0] >= 1.25 * c[1] and c[0] >= 1.25 * c[2]:
                img[y + 9, x] = np.minimum(wref * (lum(bg[x]) / bmax) ** 0.7, 255)
    return img

dim = relabel(dim); lit = relabel(lit)
dim = can_top(can_taper(dim)); lit = can_top(can_taper(lit))
dim = can_top(dim); lit = can_top(lit)
for nm, im in (("desk_lampdim.png", dim), ("desk.png", lit)):
    Image.fromarray(np.clip(np.rint(im), 0, 255).astype("uint8")).save(f"{OUT}/{nm}")
print("ok")
