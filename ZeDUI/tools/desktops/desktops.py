"""ZeD OS desktops (director, Nov 21 2026: "options available other than the two desktop backgrounds, both the Game Art
desktops ... they had like patterns and colors for desktops in '93. Something on brand. Some simple options to create
less noise. And some other just fun ones.").

Every desktop is drawn in dots. A dot is the desktop icons' own pixel: the whole zoom ZeD_MainMenuDesktop draws the
32 px icons at (1 at 1080p, 2 at 4K with UI scale 1.75), so a pattern's pixels and the icons' pixels are the same size.
A tile repeats from the tube's top left corner, under the CRT glass.

One desktop for every theme (director, Nov 22 2026: "The desktop backgrounds, they need to be the same for dark or
light mode. So somewhere in the middle of bright and dark."): they sit in the middle tones, lighter than a Dark window
and darker than a Light one, so a window of either theme stands off them. Stars is the one dark night (director,
Nov 22: "Stars can go back to being a very dark midnight navy blue.").

The ground is the player's own color (director, Nov 22: "What if the background color before the pattern overlay was
what they select for their container highlight color? That lets them have control over that color, and it also
matches. It just eliminates creating an extra color picker option."): the game's "Color of Highlighted Container"
(options.ini objHighlightColor, getCore():getObjectHighlitedColor(); Options, Highlights in ZeD), brought to the middle
tone by tone() below: its hue kept, its lightness set to the middle grey's, its strength held to C_MAX. The game's
default, 0.98 0.56 0.11 (orange), gives a rust.

Four kinds:
  pattern  an overlay: a small tile of black (or white) dots, see-through, laid over the ground. It follows the
           player's color, not the theme. In the game: fill the tube with the toned color, then draw the overlay
           texture tiled over it (plain alpha blending)
  flat     the ground alone, the theme's accent at the middle tone, or a fixed color; Fine and Pinstripe are
           overlays this faint
  art      a tile made here in code, in its own fixed colors
  picture  a picture the size of the tube (960 x 720 dots on the 4K desk): the USA and Kentucky flags. In the game
           the field color fills the tube and the picture sits at its middle (USA: drawn to the tube's height)

Options, not yet picked: the director's board is the "ZeD Desktops" design canvas (Nov 21 2026).

usage: python desktops.py <ref dir> <out dir>
  ref dir: ZeD_design_refs/desktops_20261121/ref: sc4_desk.png (a 4K capture of the desk, UI scale 1.75, Dark, PZ
  Teal), desk_02/desk_04 (the two wallpapers' captures) and icons/*.png (the mod's own desktop icons)
  writes overlays/<id>.png (a pattern's see-through tile, 1 px a dot, RGBA), tiles1/<id>.png (an art tile, 1 px a
  dot), pictures/<id>.png (USA, Kentucky at the tube's 960 x 720 dots), swatches/<id>.png (the picker's 64 x 48 dots,
  2 px a dot, for the art and the pictures), crops/<id>.png (the desktop at 4K by the icons, in the game's default
  color), colors/<id>_<color>.png (three patterns in four colors), desk/<id>.png (the whole desk at 1080p) and
  check/ (zooms to look at)."""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

# ---------------------------------------------------------------------------------------------------------------
# colors
# ---------------------------------------------------------------------------------------------------------------
ACCENTS = {  # the design system's accent tokens (their Dark values: the desktop has no theme)
    "red": "#cc4444", "orange": "#d4922a", "yellow": "#ccaa22", "green": "#44aa44", "blue": "#4488cc",
    "teal": "#47a18c", "purple": "#8855bb", "pink": "#dd5588", "none": "#888888",
}


def hx(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], np.float32)


def mix(a, b, t):
    return a + (b - a) * t


def rgb01(r, g, b):
    """a color as options.ini keeps it (0..1 a channel), in 0..255"""
    return np.array([r, g, b], np.float32) * 255


CONTAINER = rgb01(0.98, 0.56, 0.11)   # the game's default "Color of Highlighted Container"
MID = hx("#6b6760")                   # the middle grey every desktop is built round (L* about 44)


# OKLab (Bjorn Ottosson, 2020): a lightness that looks the same in every hue, so "the middle tone" is the middle
# whatever color the player picks (an HSL lightness of 50% is bright in yellow and dark in blue)
def _lin(c):
    c = np.asarray(c, np.float64) / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def _srgb(c):
    c = np.clip(np.asarray(c, np.float64), 0.0, 1.0)
    return 255.0 * np.where(c <= 0.0031308, 12.92 * c, 1.055 * c ** (1 / 2.4) - 0.055)


def oklab(rgb):
    r, g, b = _lin(rgb)
    l = np.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    m = np.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    s = np.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
    return np.array([0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
                     1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
                     0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s])


def oklab_linear(L, a, b):
    """OKLab back to linear sRGB (0..1 inside the screen's colors)"""
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return np.array([4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                     -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                     -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s])


L_MID = float(oklab(MID)[0])   # the middle grey's lightness
C_MAX = 0.09                   # the most color a desktop ground carries (OKLab chroma): about Windows 95's teal


def tone(rgb, cmax=C_MAX):
    """any color brought to the middle tone: its hue kept, its lightness the middle grey's, its strength held to cmax
    (and lowered further where the screen can't show that hue that strong at that lightness). White and black come
    out as the middle grey"""
    _, a, b = oklab(rgb)
    c, h = min(math.hypot(a, b), cmax), math.atan2(b, a)

    def fits(c):
        v = oklab_linear(L_MID, c * math.cos(h), c * math.sin(h))
        return bool((v >= -1e-9).all() and (v <= 1 + 1e-9).all())

    if not fits(c):
        lo, hi = 0.0, c
        for _ in range(32):
            mid = (lo + hi) / 2
            lo, hi = (mid, hi) if fits(mid) else (lo, mid)
        c = lo
    return _srgb(oklab_linear(L_MID, c * math.cos(h), c * math.sin(h))).astype(np.float32)


def ground(color=None):
    """the desktop's ground: the player's Color of Highlighted Container at the middle tone"""
    return tone(CONTAINER if color is None else color)


def hexof(c):
    return "#" + "".join(f"{int(round(float(v))):02x}" for v in np.clip(c, 0, 255))


# ---------------------------------------------------------------------------------------------------------------
# overlays: what a pattern lays over the ground, RGBA (rgb 0..255, alpha 0..1, kept to whole 255ths as a PNG keeps it)
# ---------------------------------------------------------------------------------------------------------------
def q(a):
    return round(a * 255) / 255


def grid(rows):
    return np.array([[c == "#" for c in r] for r in rows], bool)


def ov(m, depth):
    """a 1-bit grid as an overlay: black, see-through by depth where set, clear elsewhere (the ground darker there)"""
    o = np.zeros(m.shape + (4,), np.float32)
    o[m, 3] = q(depth)
    return o


def lay(g, o):
    """the ground with an overlay laid over it: plain alpha blending, as the game draws a texture over a fill"""
    a = o[..., 3:4]
    return np.asarray(g, np.float32) * (1 - a) + o[..., :3] * a


def by_majority(idx, u, n):
    """a canvas drawn u times up in n palette indices, brought down to dots: each dot takes the index most of its
    u x u samples hold (the ground, index 0, losing a tie, so a thin line drawn over it stays)"""
    h, w = idx.shape[0] // u, idx.shape[1] // u
    blocks = np.asarray(idx)[:h * u, :w * u].reshape(h, u, w, u)
    counts = np.stack([(blocks == k).sum((1, 3)).astype(np.float32) for k in range(n)], -1)
    counts[..., 0] -= 0.5
    return counts.argmax(-1)


def weave():
    a, b = ["####", "....", "####", "...."], ["#.#.", "#.#.", "#.#.", "#.#."]
    return grid([a[i] + b[i] for i in range(4)] + [b[i] + a[i] for i in range(4)])


def stamp(size, glyph, places):
    m = np.zeros((size, size), bool)
    g = grid(glyph)
    for (x, y) in places:
        for j in range(g.shape[0]):
            for i in range(g.shape[1]):
                if g[j, i]:
                    m[(y + j) % size, (x + i) % size] = True
    return m


def periodic_field(size, waves, seed):
    """a smooth height field that tiles: a sum of waves with whole periods across the tile"""
    r = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32) / size * 2 * math.pi
    h = np.zeros((size, size), np.float32)
    for (fx, fy, amp) in waves:
        ph = r.uniform(0, 2 * math.pi)
        h += amp * np.sin(fx * xx + fy * yy + ph)
    return h


def noise(S, seed, n, fx_max, fy_max, f_min, f_max, slope=1.3):
    """a tiling field of n waves at random whole frequencies (fx up to fx_max across, fy up to fy_max down, their
    length between f_min and f_max), the slow ones strongest: no two layers or tiles look alike"""
    r = np.random.default_rng(seed)
    waves = []
    while len(waves) < n:
        fx, fy = int(r.integers(-fx_max, fx_max + 1)), int(r.integers(0, fy_max + 1))
        f = math.hypot(fx, fy)
        if f_min <= f <= f_max:
            waves.append((fx, fy, f ** -slope))
    return periodic_field(S, waves, seed + 1000)


def camo():
    """woodland camo in four tones of the player's color: the ground, two darker blobs over it and near-black
    branches on top, lying across (their field changes faster down than across). Each layer is a tiling field cut at
    a level, so the blobs tile and have no seam (128 dots square)"""
    S = 128
    f1 = noise(S, 81, 18, 8, 8, 2, 8)
    f2 = noise(S, 82, 18, 9, 9, 2, 9)
    f3 = noise(S, 83, 16, 4, 11, 4, 11)
    o = np.zeros((S, S, 4), np.float32)
    o[f1 > np.percentile(f1, 50), 3] = q(0.20)     # the first darker tone over half the ground
    o[f2 > np.percentile(f2, 67), 3] = q(0.40)     # the second, a third of it
    o[f3 > np.percentile(f3, 88), 3] = q(0.64)     # the branches, near black
    return o


def squiggle():
    """an early-90s party-aisle pattern of our own: lighter dry-brush dabs, darker squiggles and little open
    triangles, scattered and kept apart over the ground (120 dots square, tiling). Drawn 4x up and brought down so
    the strokes keep their shape"""
    S, U = 120, 4
    r = np.random.default_rng(1991)
    big = Image.new("L", (S * U, S * U), 0)
    d = ImageDraw.Draw(big)
    placed = []

    def free(x, y, rad):
        for (px, py, pr) in placed:          # the distance across the tile's wrap
            dx, dy = abs(x - px), abs(y - py)
            if math.hypot(min(dx, S - dx), min(dy, S - dy)) < rad + pr + 4:
                return False
        return True

    def put(lines, fill, width, x, y):
        for ox in (-S, 0, S):                # each shape drawn nine times, so it wraps across the tile's edges
            for oy in (-S, 0, S):
                for pts in lines:
                    d.line([((x + ox + px) * U, (y + oy + py) * U) for px, py in pts], fill=fill,
                           width=max(1, int(round(width * U))), joint="curve")

    def turn(pts, ang):
        ca, sa = math.cos(ang), math.sin(ang)
        return [(px * ca - py * sa, px * sa + py * ca) for px, py in pts]

    def dab():                               # a swipe of a dry brush: five bristle runs side by side, bowed a little,
        ln, bow = r.uniform(18, 26), r.uniform(-3.5, 3.5)   # their ends ragged, a run in three skipping
        runs = []
        for k in range(5):
            off = (k - 2) * 1.6
            s0, s1 = r.uniform(0, 0.22), 1 - r.uniform(0, 0.22)
            spans = [(s0, s1)]
            if r.random() < 0.35:
                c = r.uniform(s0 + 0.25, s1 - 0.25)
                spans = [(s0, c - 0.06), (c + 0.06, s1)]
            for a, b in spans:
                runs.append([(-ln / 2 + ln * s, off + bow * (1 - (2 * s - 1) ** 2)) for s in np.linspace(a, b, 10)])
        return runs, 13

    def wave():                              # a thin line with two and a half turns in it
        ln, amp = r.uniform(24, 30), r.uniform(2.6, 3.4)
        n = int(ln * 2)
        return [[(-ln / 2 + ln * i / n, amp * math.sin(i / n * 5 * math.pi)) for i in range(n + 1)]], 15

    def tri():                               # a small open triangle
        s = r.uniform(6, 8)
        pts = [(s * math.cos(a), s * math.sin(a)) for a in (-math.pi / 2, math.pi / 6, 5 * math.pi / 6)]
        return [pts + [pts[0]]], 7

    for kind, count, fill, width in ((dab, 7, 1, 2.0), (wave, 7, 2, 2.0), (tri, 4, 2, 1.5)):
        got = tries = 0
        while got < count and tries < 4000:
            tries += 1
            lines, rad = kind()
            x, y = r.uniform(0, S), r.uniform(0, S)
            if not free(x, y, rad):
                continue
            ang = r.uniform(0, math.pi)
            put([turn(p, ang) for p in lines], fill, width, x, y)
            placed.append((x, y, rad))
            got += 1
    idx = by_majority(np.asarray(big), U, 3)
    o = np.zeros((S, S, 4), np.float32)
    o[idx == 1] = (255, 255, 255, q(0.20))    # the dabs: the ground lighter
    o[idx == 2] = (0, 0, 0, q(0.36))          # the squiggles and triangles: the ground darker
    return o


ZED = ["#####", "...#.", "..#..", ".#...", "#####"]
DISK = ["#########.", "#..####..#", "#..#..#..#", "#..#..#..#", "#..####..#", "#........#", "#.######.#",
        "#.#....#.#", "#.######.#", "##########"]

PATTERNS = {
    # id: (name, note, overlay)
    "classic": ("Classic", "The checkerboard of 1993, in your color.", ov(grid(["#.", ".#"]), 0.24)),
    "weave": ("Weave", "Basket weave, two over two.", ov(weave(), 0.24)),
    "bricks": ("Bricks", "Running bond, a mortar line between rows.",
               ov(grid(["########", "#.......", "#.......", "#.......",
                        "########", "....#...", "....#...", "....#..."]), 0.24)),
    "diagonal": ("Diagonal", "A hairline every four dots, up to the right.",
                 ov(grid(["...#", "..#.", ".#..", "#..."]), 0.26)),
    "grid": ("Graph", "Graph paper, a line every eight dots.", ov(grid(["########"] + ["#......."] * 7), 0.22)),
    "dots": ("Dots", "Polka dots, every other row set over.",
             ov(grid(["##......", "##......", "........", "........",
                      "....##..", "....##..", "........", "........"]), 0.28)),
    "zeds": ("Zeds", "ZeD's own Z, every other row set over.", ov(stamp(16, ZED, [(1, 1), (9, 9)]), 0.30)),
    "disks": ("Disks", "The ZeD-GUI disk, every other row set over.", ov(stamp(24, DISK, [(2, 2), (14, 14)]), 0.28)),
    "camo": ("Camo", "Woodland camo in four tones of your color.", camo()),
    "squiggle": ("Squiggle", "Brush dabs and squiggles, straight off a 1993 party aisle.", squiggle()),
}

QUIET = {
    # id: (name, note, kind, value)
    "solid": ("Solid", "Your color alone, at a middle tone.", "flat", None),
    "accent": ("Accent", "Flat, your theme's accent at a middle tone.", "accent", "teal"),
    "slate": ("Slate", "Flat, a cool blue-grey.", "fixed", "#5b6474"),
    "fine": ("Fine", "One dot in sixteen, barely there.", "overlay",
             ov(grid(["#...", "....", "..#.", "...."]), 0.14)),
    "pinstripe": ("Pinstripe", "A faint line every four dots, as on a title bar.", "overlay",
                  ov(grid(["#", ".", ".", "."]), 0.10)),
}


def overlay(oid):
    return PATTERNS[oid][2] if oid in PATTERNS else QUIET[oid][3]


# ---------------------------------------------------------------------------------------------------------------
# the fun ones: tiles made in code, each in its own fixed colors, in the same middle tones as the rest (Stars apart)
# ---------------------------------------------------------------------------------------------------------------
def art_topo():
    """Knox County from the air: contour lines over rolling hills, every fifth line heavier, a creek in a valley"""
    S = 192
    h = periodic_field(S, [(1, 1, 1.0), (2, -1, 0.6), (1, 2, 0.4), (3, 1, 0.2), (-1, 3, 0.15)], seed=11)
    step = 0.2
    band = np.floor(h / step).astype(int)
    line = (band != np.roll(band, 1, 0)) | (band != np.roll(band, 1, 1))
    index = line & ((np.maximum(band, np.roll(band, 1, 0)) % 5 == 0) | (np.maximum(band, np.roll(band, 1, 1)) % 5 == 0))
    img = np.zeros((S, S, 3), np.float32)
    img[...] = hx("#6b6d58")                            # a survey map's olive, toned down
    low = h < np.percentile(h, 14)                      # the valley floors, a shade greener
    img[low] = hx("#646a56")
    img[line] = hx("#565a46")
    img[index] = hx("#474b39")
    # the creek: along the lowest band's middle
    creek = (np.abs(h - np.percentile(h, 4)) < 0.012)
    img[creek] = hx("#46677a")
    return img


def art_carpet():
    """the arcade's carpet: confetti in four inks on indigo, the shapes kept small and far apart"""
    S = 72
    r = np.random.default_rng(93)
    img = np.zeros((S, S, 3), np.float32)
    img[...] = hx("#574e82")
    inks = [hx("#47c8b9"), hx("#dd63ad"), hx("#e2c45a"), hx("#a28cf0")]
    shapes = {
        "squiggle": ["#..", ".#.", "..#", ".#.", "#..", ".#."],
        "tri": ["..#..", ".#.#.", "#####"],
        "ring": [".##.", "#..#", "#..#", ".##."],
        "zig": ["#...#...", ".#.#.#.#", "..#...#."],
        "dot": ["##", "##"],
        "bar": ["#####"],
        "plus": [".#.", "###", ".#."],
    }
    names = list(shapes)
    occupied = np.zeros((S, S), bool)
    placed = 0
    tries = 0
    while placed < 30 and tries < 2000:
        tries += 1
        g = grid(shapes[names[r.integers(len(names))]])
        if r.integers(2):
            g = g.T
        if r.integers(2):
            g = g[::-1]
        x, y = r.integers(S), r.integers(S)
        ys, xs = np.nonzero(g)
        pts = [((y + j) % S, (x + i) % S) for j, i in zip(ys, xs)]
        # keep two dots of clear carpet round every shape
        if any(occupied[max(0, py - 2):py + 3, max(0, px - 2):px + 3].any() or
               occupied[(py - 2) % S, (px - 2) % S] for py, px in pts):
            continue
        ink = inks[placed % 4]
        for py, px in pts:
            img[py, px] = ink
            occupied[py, px] = True
        placed += 1
    return img


def art_paneling():
    """the den's wood paneling: pecan boards 12 dots wide, a groove between them, grain running down"""
    W, H = 96, 96
    r = np.random.default_rng(1974)
    img = np.zeros((H, W, 3), np.float32)
    base = [hx("#76563a"), hx("#7d5b3c"), hx("#71523a"), hx("#7a5939")]
    for b in range(W // 12):
        x0 = b * 12
        img[:, x0:x0 + 12] = base[b % 4]
        # grain: a few long streaks wandering down the board
        for _ in range(4):
            gx = x0 + 2 + r.integers(9)
            tone_ = hx("#8b6947") if r.integers(2) else hx("#5d4330")
            y = r.integers(H)
            for k in range(r.integers(30, 80)):
                yy = (y + k) % H
                if r.random() < 0.18:
                    gx = min(x0 + 10, max(x0 + 1, gx + (1 if r.integers(2) else -1)))
                img[yy, gx] = tone_
        img[:, x0] = hx("#3b2a1a")                  # the groove
        img[:, x0 + 1] = hx("#93704c")              # its lit edge
    return img


def art_flannel():
    """a flannel shirt's plaid, red over maroon (black would sink below the middle), a twill line through the
    threads"""
    S = 24
    red, dark, mid = hx("#a84f43"), hx("#62403a"), hx("#83473d")
    warp = np.array([1] * 10 + [0] * 2 + [1] * 2 + [0] * 10)        # across: red, a maroon pinstripe, red, maroon
    weft = warp.copy()
    img = np.zeros((S, S, 3), np.float32)
    yy, xx = np.mgrid[0:S, 0:S]
    a, b = warp[xx], weft[yy]
    img[(a == 1) & (b == 1)] = red
    img[(a == 0) & (b == 0)] = dark
    img[(a != b)] = mid
    twill = ((xx + yy) % 4 == 0)
    img[twill] = img[twill] * 0.84
    return img


def art_stars():
    """a clear night over Knox County, no lights for miles: midnight navy (the one dark desktop: director, Nov 22,
    "Stars can go back to being a very dark midnight navy blue"), the stars out, a few brighter, one in a while with
    points"""
    S = 160
    r = np.random.default_rng(1993)
    img = np.zeros((S, S, 3), np.float32)
    img[...] = hx("#0c1229")
    for _ in range(70):
        x, y = r.integers(S), r.integers(S)
        img[y, x] = hx("#3e4b79") if r.random() < 0.7 else hx("#7a88b6")
    for _ in range(6):
        x, y = r.integers(S), r.integers(S)
        img[y, x] = hx("#d8deef")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            img[(y + dy) % S, (x + dx) % S] = hx("#4c5888")
    return img


def art_tally():
    """days counted in pencil on the plaster: groups of four struck through by the fifth, two rows a tile, room
    between"""
    W, H = 216, 160
    r = np.random.default_rng(42)
    img = np.zeros((H, W, 3), np.float32)
    img[...] = hx("#6e6c66")
    for _ in range(220):                              # the plaster's grain: a few darker flecks
        img[r.integers(H), r.integers(W)] = hx("#66645e")
    chalk, faint = hx("#403f3b"), hx("#56544f")       # (the pencil, and where it skipped)
    for row, (y0, x) in enumerate(((22, 12), (102, 66))):
        for g in range(3):
            n = 5 if (row, g) != (1, 2) else 3          # one week still going
            top0 = y0 + r.integers(-3, 4)
            for k in range(min(n, 4)):
                xx = x + k * 5
                top = top0 + r.integers(-1, 2)
                for yy in range(top, top + 17):         # a mark two dots wide, the pencil skipping here and there
                    for dx in (0, 1):
                        if r.random() < (0.9 if dx == 0 else 0.55):
                            img[yy % H, (xx + dx) % W] = chalk if r.random() < 0.85 else faint
            if n == 5:                                 # the fifth day strikes the four
                for t in range(24):
                    yy, xx = top0 + 14 - int(t * 0.5), x - 3 + t
                    img[yy % H, xx % W] = chalk
                    if r.random() < 0.6:
                        img[(yy + 1) % H, xx % W] = faint
            x += 66 + r.integers(-5, 6)
    return img


ART = {
    "topo": ("Topo", "Knox County from the air: contour lines, a creek in the valley.", art_topo),
    "carpet": ("Carpet", "The arcade's carpet, confetti on indigo.", art_carpet),
    "paneling": ("Paneling", "The den's pecan wall boards.", art_paneling),
    "flannel": ("Flannel", "Plaid, red over maroon. It is 1993.", art_flannel),
    "stars": ("Stars", "A clear night, no lights for miles.", art_stars),
    "tally": ("Tally", "Days counted in pencil on the plaster.", art_tally),
}


# ---------------------------------------------------------------------------------------------------------------
# the pictures: a flag the size of the tube, drawn 4x up in palette indices and brought down to dots
# ---------------------------------------------------------------------------------------------------------------
TW, TH = 960, 720                 # the tube in dots on the 4K desk (1920 x 1440 px, 2 px a dot)
U = 4                             # drawn this many times up
SERIF = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"


def star(d, cx, cy, rad, fill):
    """a five-pointed star, one point up, its inner corners at 0.382 of its reach (a regular star)"""
    pts = []
    for i in range(10):
        rr = rad if i % 2 == 0 else rad * 0.382
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=fill)


USA = [hx("#8f3a36"), hx("#a09b8e"), hx("#353d5e")]   # red, white, blue: a flag a few summers on the porch


def usa(W=TW, H=TH):
    """the Stars and Stripes filling the tube: thirteen stripes the tube's height, red at top and bottom; the union
    seven stripes tall and 0.76 of the height wide; fifty stars in nine rows of six and five, spaced and sized by the
    flag's own figures (Executive Order 10834). The fly runs off the tube's right edge"""
    HU, WU = H * U, W * U
    big = Image.new("L", (WU, HU), 0)
    d = ImageDraw.Draw(big)
    for i in range(13):
        y0, y1 = round(i * HU / 13), round((i + 1) * HU / 13)
        d.rectangle([0, y0, WU - 1, y1 - 1], fill=0 if i % 2 == 0 else 1)
    d.rectangle([0, 0, round(0.76 * HU) - 1, round(7 * HU / 13) - 1], fill=2)
    G, E, K = 0.063 * HU, 0.054 * HU, 0.0616 * HU       # across between stars, down between rows, a star's span
    for row in range(9):
        n, x0 = (6, G) if row % 2 == 0 else (5, 2 * G)
        for k in range(n):
            star(d, x0 + 2 * G * k, E * (row + 1), K / 2, 1)
    return np.array(USA)[by_majority(np.asarray(big), U, 3)]


KY = [  # the Commonwealth's flag, toned down to sit behind the windows (index: what it paints)
    hx("#28305a"),   # 0 the navy field, and the motto's letters
    hx("#b08f3c"),   # 1 gold: the seal's ring and the name over it
    hx("#a59e8c"),   # 2 the seal's pale ground
    hx("#4e6c46"),   # 3 green: the ground the men stand on, the goldenrod's leaves
    hx("#36503a"),   # 4 deep green: the goldenrod's stems
    hx("#8b6a47"),   # 5 buckskin
    hx("#694f34"),   # 6 buckskin, shaded: leggings, belt, fringe
    hx("#6e5c48"),   # 7 the coonskin cap
    hx("#4b3f31"),   # 8 its rings, moccasins
    hx("#b38a6d"),   # 9 skin
    hx("#3e3229"),   # 10 hair
    hx("#2b2b31"),   # 11 the statesman's coat
    hx("#57575e"),   # 12 his trousers
    hx("#cdc6b4"),   # 13 his shirt front
    hx("#27231f"),   # 14 his shoes
    hx("#c4a03e"),   # 15 goldenrod in bloom
    hx("#1d2136"),   # 16 the line round the men
]


def arc_text(big, text, font, cx, cy, r, mid_deg, outward, fill, track):
    """letters set round a circle of radius r (in drawn px) about (cx, cy), centered on mid_deg (screen degrees: 0
    right, 90 down). outward: over the top, read clockwise, tops away from the middle, the baseline on the circle.
    Not outward: along the bottom, read left to right, tops toward the middle, the baseline on the circle"""
    sgn = 1 if outward else -1
    adv = [font.getlength(ch) for ch in text]
    total = sum(adv) + track * (len(text) - 1)
    ang = math.radians(mid_deg) - sgn * (total / 2) / r
    S = int(font.size * 2)
    for ch, w in zip(text, adv):
        phi = ang + sgn * (w / 2) / r
        if ch != " ":
            g = Image.new("L", (S, S), 0)
            ImageDraw.Draw(g).text((S / 2, S / 2), ch, font=font, fill=255, anchor="ms")
            deg = math.degrees(phi)
            g = g.rotate(-(deg + 90) if outward else 90 - deg, resample=Image.BICUBIC, center=(S / 2, S / 2))
            m = Image.fromarray(((np.asarray(g) > 127) * 255).astype(np.uint8))
            x, y = cx + r * math.cos(phi), cy + r * math.sin(phi)
            big.paste(fill, (int(round(x - S / 2)), int(round(y - S / 2))), m)
        ang += sgn * (w + track) / r


def goldenrod(d, cx, cy, r, a0, a1, rng):
    """a spray of goldenrod in bloom along the circle of radius r from angle a0 to a1 (screen degrees): a stem, narrow
    leaves along it, and plumes of tiny flowers arching outward, the biggest at the tip (all in dots, drawn 4x up)"""
    P = lambda x, y: (x * U, y * U)
    n = 40
    pts = [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)), cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / n)))
           for i in range(n + 1)]
    d.line([P(*p) for p in pts], fill=4, width=3 * U, joint="curve")
    span = a1 - a0
    sg = 1 if span > 0 else -1
    for i, t in enumerate(np.clip(np.linspace(0.08, 0.98, 11) + rng.uniform(-0.02, 0.02, 11), 0, 1)):
        a = math.radians(a0 + span * t)
        bx, by = cx + r * math.cos(a), cy + r * math.sin(a)
        out = (math.cos(a), math.sin(a))                  # away from the seal
        fwd = (-math.sin(a) * sg, math.cos(a) * sg)       # along the stem, toward its tip
        # a leaf, inside and outside the stem by turns, laid along it
        side = -1 if i % 2 == 0 else 1
        lx, ly = bx + out[0] * side * 3, by + out[1] * side * 3
        ln, wd = 11, 2.8
        tip = (lx + fwd[0] * ln - out[0] * side * 3, ly + fwd[1] * ln - out[1] * side * 3)
        mid = ((lx + tip[0]) / 2, (ly + tip[1]) / 2)
        nrm = (-(tip[1] - ly) / ln, (tip[0] - lx) / ln)
        d.polygon([P(lx, ly), P(mid[0] + nrm[0] * wd, mid[1] + nrm[1] * wd), P(*tip),
                   P(mid[0] - nrm[0] * wd, mid[1] - nrm[1] * wd)], fill=3)
        # a plume: a branch arching out and on toward the tip, crowded with tiny flowers, widest past its middle
        blen = 12 + 22 * t
        cur = lambda s: (bx + out[0] * blen * 0.8 * s + fwd[0] * blen * 0.7 * s * s,
                         by + out[1] * blen * 0.8 * s + fwd[1] * blen * 0.7 * s * s)
        d.line([P(*cur(s)) for s in np.linspace(0, 1, 14)], fill=4, width=2 * U, joint="curve")
        for s in np.linspace(0.22, 1.0, 26):
            px, py = cur(s)
            tx, ty = out[0] * 0.8 + fwd[0] * 1.4 * s, out[1] * 0.8 + fwd[1] * 1.4 * s   # the branch's way at s
            tl = math.hypot(tx, ty) or 1
            wide = 3.2 * math.sin(math.pi * min(1.0, (s - 0.15) / 0.9))
            off = wide * rng.uniform(-1.0, 1.0)
            fx, fy = px - ty / tl * off, py + tx / tl * off
            rr = 1.4 + 0.6 * rng.random()
            d.ellipse([P(fx - rr, fy - rr), P(fx + rr, fy + rr)], fill=15)


def kentucky(W=TW, H=TH):
    """the Commonwealth of Kentucky's flag filling the tube: navy, the seal at the middle with its wreath two-thirds
    the tube's height across (KRS 2.030): COMMONWEALTH OF KENTUCKY arched over it in gold, goldenrod in bloom under it.
    In the seal (KRS 2.020) a frontiersman in buckskin clasps a statesman's shoulder and shakes his hand, UNITED WE
    STAND over them, DIVIDED WE FALL under them"""
    cx, cy = W / 2, H / 2
    big = Image.new("L", (W * U, H * U), 0)
    d = ImageDraw.Draw(big)
    P = lambda x, y: ((cx + x) * U, (cy + y) * U)             # dots from the seal's middle, drawn 4x up
    E = lambda x0, y0, x1, y1, f: d.ellipse([P(x0, y0), P(x1, y1)], fill=f)
    G = lambda pts, f: d.polygon([P(x, y) for x, y in pts], fill=f)
    L = lambda pts, f, w: d.line([P(x, y) for x, y in pts], fill=f, width=int(w * U), joint="curve")
    rng = np.random.default_rng(1792)

    # the wreath's lower half: two sprays of goldenrod meeting under the seal, their stems crossed
    goldenrod(d, cx, cy, 202, 80, 164, rng)
    goldenrod(d, cx, cy, 202, 100, 16, rng)
    # the seal: a gold ring, its pale ground
    E(-168, -168, 168, 168, 1)
    E(-160, -160, 160, 160, 2)
    # the motto round the men
    motto = ImageFont.truetype(SERIF, 22 * U)
    arc_text(big, "UNITED WE STAND", motto, cx * U, cy * U, 129 * U, -90, True, 0, 2.5 * U)
    arc_text(big, "DIVIDED WE FALL", motto, cx * U, cy * U, 145 * U, 90, False, 0, 2.5 * U)
    # the ground they stand on
    E(-70, 80, 70, 96, 3)

    # the handshake (director, Nov 22: "their hands are supposed to be down at their waist shaking. Two hands shaking
    # two hands."): both men's arms come down and forward, and the four hands clasp between them at the waist
    def arm(path, color, w, edge):
        """an arm, a thick line; edge: a dark line round it, so a sleeve in front of a shirt of its own color shows"""
        if edge:
            L(path, 16, w + 2)
        L(path, color, w)

    def hand(x, y):
        E(x - 6, y - 4.5, x + 6, y + 4.5, 16)
        E(x - 5, y - 3.5, x + 5, y + 3.5, 9)

    # the far arms, behind their bodies: the frontiersman's in shaded buckskin, the statesman's in his coat
    arm([(-24, -57), (-16, -36), (-7, -19)], 6, 8, True)
    arm([(24, -58), (17, -37), (8, -20)], 11, 8, False)
    E(5, -23.5, 11, -16.5, 13)                                    # his shirt cuff

    # the statesman (right, facing left): coat tails, legs, coat, shirt front, head
    G([(42, -10), (60, -10), (65, 44), (52, 46)], 11)
    G([(40, -6), (55, -6), (54, 82), (44, 82)], 12)
    G([(22, -6), (37, -6), (35, 82), (25, 82)], 12)
    E(38, 79, 57, 89, 14)
    E(15, 79, 36, 89, 14)
    G([(17, -58), (25, -65), (50, -65), (58, -58), (60, -6), (18, -6)], 11)
    G([(26, -65), (35, -65), (30, -48)], 13)
    E(24, -95, 46, -70, 9)
    E(26, -99, 48, -83, 10)
    G([(40, -90), (48, -90), (48, -72), (42, -74)], 10)

    # the frontiersman (left, facing right): legs, moccasins, hunting shirt, belt, fringe, head, coonskin cap
    G([(-54, 16), (-40, 16), (-42, 82), (-53, 82)], 6)
    G([(-37, 16), (-23, 16), (-20, 82), (-31, 82)], 6)
    E(-57, 79, -38, 89, 8)
    E(-34, 79, -13, 89, 8)
    G([(-58, -60), (-50, -66), (-26, -66), (-17, -59), (-12, 20), (-64, 20)], 5)
    G([(-63, -15), (-14, -15), (-14, -9), (-63, -9)], 6)
    for x in range(-62, -13, 3):
        L([(x, 20), (x, 26)], 6, 1.3)
    for x in range(-56, -21, 4):                                  # the fringe across his shoulders
        L([(x, -57), (x, -51)], 6, 1.3)
    E(-46, -95, -24, -70, 9)
    G([(-47, -86), (-38, -86), (-40, -72), (-47, -74)], 10)
    E(-49, -104, -23, -85, 7)                                     # the coonskin cap
    G([(-48, -96), (-41, -95), (-52, -64), (-59, -67)], 7)        # its tail, down his back
    for t in (0.35, 0.6, 0.85):
        ax, ay = -48 + (-59 + 48) * t, -96 + (-67 + 96) * t
        L([(ax - 0.5, ay), (ax + 6.5, ay + 1)], 8, 2.2)

    # the near arms, in front of their bodies
    arm([(-34, -58), (-27, -34), (-10, -11)], 5, 8, True)
    arm([(34, -59), (27, -35), (10, -12)], 11, 8, True)
    E(6, -15.5, 12, -8.5, 13)                                     # his other cuff

    # the four hands, clasped at the waist: the far pair, then the near pair over them
    hand(4, -19)
    hand(-3, -17)
    hand(-4, -9)
    hand(4, -8)

    # COMMONWEALTH OF KENTUCKY over the seal
    name = ImageFont.truetype(SERIF, 30 * U)
    arc_text(big, "COMMONWEALTH OF KENTUCKY", name, cx * U, cy * U, 190 * U, -90, True, 1, 3 * U)

    idx = by_majority(np.asarray(big), U, 17)
    # a dark line round the men where they meet the seal's ground, as a sprite has
    men = (idx >= 5) & (idx <= 14)
    grow = men.copy()
    grow[1:] |= men[:-1]
    grow[:-1] |= men[1:]
    grow[:, 1:] |= men[:, :-1]
    grow[:, :-1] |= men[:, 1:]
    idx[grow & ~men & ((idx == 2) | (idx == 3))] = 16
    return np.array(KY)[idx]


PICTURES = {
    "usa": ("USA", "The Stars and Stripes, faded by a few summers on the porch.", usa),
    "kentucky": ("Kentucky", "The Commonwealth's flag: the seal, its motto, goldenrod in bloom.", kentucky),
}


# ---------------------------------------------------------------------------------------------------------------
# one tile (or picture), any option
# ---------------------------------------------------------------------------------------------------------------
def tile(oid, color=None):
    """one tile of a desktop, 1 px a dot, the same in every theme; color: the player's Color of Highlighted
    Container (0..255), the game's default when None"""
    g = ground(color)
    if oid in PATTERNS:
        return lay(g, PATTERNS[oid][2])
    if oid in QUIET:
        _, _, kind, v = QUIET[oid]
        if kind == "flat":
            return np.broadcast_to(g, (8, 8, 3)).copy()
        if kind == "accent":
            return np.broadcast_to(tone(hx(ACCENTS[v])), (8, 8, 3)).copy()
        if kind == "fixed":
            return np.broadcast_to(hx(v), (8, 8, 3)).copy()
        return lay(g, v)
    if oid in ART:
        return ART[oid][2]()
    return PICTURES[oid][2]()


def name_of(oid):
    for d in (PATTERNS, QUIET, ART, PICTURES):
        if oid in d:
            return d[oid][0], d[oid][1]
    return oid, ""


# ---------------------------------------------------------------------------------------------------------------
# the desk: the tube filled, the CRT glass over it, ZeD's own windows, bar and icons back on top (from the capture)
# ---------------------------------------------------------------------------------------------------------------
TUBE = (960, 240, 1920, 1440)            # the tube on the 4K capture (desk 8x)
DOT = 2                                  # the icons' whole zoom at 4K with UI scale 1.75
STEP, LINE = 5, 2                        # MM.drawGlass's scanlines at that scale: T.px(3), T.px(1)
BAR = (960, 240, 1920, 42)               # the menu bar
WINDOW = (1342, 317, 1155, 821)          # the Project Zomboid window
ICONS = {  # icon, top left (found on the capture)
    "pz": (2732, 307), "newgame": (2732, 443), "load": (2732, 579), "join": (2732, 715), "options": (2732, 851),
    "mods": (2732, 987), "trash": (2732, 1543), "pasties": (1044, 307), "cletusworks": (1044, 443),
    "mail": (1044, 579), "documents": (1044, 715),
}


def fill_tube(t, w, h, d):
    th, tw = t.shape[:2]
    reps = (math.ceil(h / (th * d)) + 1, math.ceil(w / (tw * d)) + 1, 1)
    big = np.tile(np.repeat(np.repeat(t, d, 0), d, 1), reps)
    return big[:h, :w]


def glass(a):
    """MM.drawGlass over the tube: the scanlines, then the edges falling off"""
    h, w = a.shape[:2]
    for y in range(0, h, STEP):
        a[y:y + LINE] *= (1 - 0.11)
    band = max(1, int(min(w, h) * 0.008))
    for i in range(1, 9):
        d = i * band
        a[:d] *= 0.975
        a[h - d:] *= 0.975
        a[d:h - d, :d] *= 0.975
        a[d:h - d, w - d:] *= 0.975
    return a


class Desk:
    def __init__(self, ref):
        self.cap = np.asarray(Image.open(os.path.join(ref, "sc4_desk.png")).convert("RGB")).astype(np.float32)
        self.icons = {k: np.asarray(Image.open(os.path.join(ref, "icons", k + ".png")).convert("RGBA")
                                    .resize((64, 64), Image.NEAREST)) for k in ICONS}
        # each icon's name on its backing, placed as ZeD_MainMenuDesktop places it: the backing T.px(6) under the
        # picture, the font's height plus T.px(4) tall. Its width: the run of the backing's own tone along its top row
        # (the name never reaches that row) through the icon's middle
        self.labels = {}
        s = self.cap.sum(2)
        for k, (x, y) in ICONS.items():
            ly, lh, cx = y + 64 + 11, 36, x + 32
            row = (s[ly] >= 45) & (s[ly] <= 80)
            x0, x1 = cx, cx
            while row[x0 - 1]:
                x0 -= 1
            while row[x1 + 1]:
                x1 += 1
            # (the painting shows through the backing at 8%, which can break that run: the name's own letters,
            # the brightest thing there, and T.px(4) past them, keep it whole)
            txt = np.nonzero((s[ly:ly + lh, cx - 120:cx + 120] >= 400).any(0))[0]
            if len(txt):
                x0, x1 = min(x0, cx - 120 + txt.min() - 7), max(x1, cx - 120 + txt.max() + 7)
            self.labels[k] = (x0, ly, x1 - x0 + 1, lh)

    def render(self, t, window=True):
        """the whole 4K desk with t on the tube; window=False: the Project Zomboid window closed"""
        out = self.cap.copy()
        tx, ty, tw, th = TUBE
        out[ty:ty + th, tx:tx + tw] = glass(fill_tube(t, tw, th, DOT).astype(np.float32))
        for (x, y, w, h) in ((BAR, WINDOW) if window else (BAR,)):
            out[y:y + h, x:x + w] = self.cap[y:y + h, x:x + w]
        for k, (x, y) in ICONS.items():
            m = self.icons[k][..., 3] > 128
            out[y:y + 64, x:x + 64][m] = self.cap[y:y + 64, x:x + 64][m]
            lx, ly, lw, lh = self.labels[k]
            out[ly:ly + lh, lx:lx + lw] = self.cap[ly:ly + lh, lx:lx + lw]
        return out


def save(a, path):
    Image.fromarray(np.clip(np.round(a), 0, 255).astype(np.uint8)).save(path, optimize=True)


CROP = (slice(240, 240 + 420), slice(2400, 2400 + 480))    # by the icons at 4K, 1:1: the bar's clock end, the
                                                           # window's edge, two icons and their names
CROP_UNION = (slice(240, 240 + 420), slice(960, 960 + 480))   # the tube's top left corner: the union, two icons
CROP_SEAL = (slice(960 - 420, 960 + 420), slice(1920 - 480, 1920 + 480))   # the tube's middle, halved to 1080p
GAME_ART = {  # the two there now, from captures of the game
    "painting": ("Painting", "The game's old title painting, dimmed behind the windows.", "sc4_desk.png"),
    "video": ("Title video", "Build 42's title video, playing on the monitor.", "desk_04_video_wallpaper_setting.png"),
}
SWATCH_AT = {"topo": (40, 60), "carpet": (4, 10), "stars": (30, 40), "tally": (4, 14)}
COLORS = {  # a few Colors of Highlighted Container, to show the ground following the player's pick
    "orange": CONTAINER, "green": rgb01(0.25, 0.80, 0.25), "blue": rgb01(0.25, 0.50, 1.00), "white": rgb01(1, 1, 1),
}
DESK = ("classic", "camo", "usa", "kentucky")


def swatch(t, w=64, h=48, at=(0, 0)):
    """a picker swatch: w x h dots of the desktop from dot (x, y) of the tile, 2 px a dot (sharp at 2x)"""
    th, tw = t.shape[:2]
    big = np.tile(t, (h // th + 2, w // tw + 2, 1))
    x, y = at
    return np.repeat(np.repeat(big[y:y + h, x:x + w], 2, 0), 2, 1)


def half(a):
    return a.reshape(a.shape[0] // 2, 2, a.shape[1] // 2, 2, 3).mean((1, 3))


def main(ref, out):
    for d in ("overlays", "tiles1", "pictures", "swatches", "crops", "colors", "desk", "check"):
        os.makedirs(os.path.join(out, d), exist_ok=True)
    desk = Desk(ref)
    print("ground, the game's default:", hexof(ground()), "| others:",
          {k: hexof(ground(c)) for k, c in COLORS.items()}, "| Accent (PZ Teal):", hexof(tone(hx(ACCENTS["teal"]))))
    # the overlays: what the page (and the game) lays over the ground, 1 px a dot, at least 16 x 16 for a page to repeat
    for oid in list(PATTERNS) + [k for k, v in QUIET.items() if v[2] == "overlay"]:
        o = overlay(oid)
        th, tw = o.shape[:2]
        o = np.tile(o, (max(1, 16 // th), max(1, 16 // tw), 1))
        rgba = np.dstack([o[..., :3], o[..., 3:4] * 255])
        Image.fromarray(np.clip(np.round(rgba), 0, 255).astype(np.uint8), "RGBA").save(
            os.path.join(out, "overlays", oid + ".png"), optimize=True)
    for oid in ART:
        t = tile(oid)
        th, tw = t.shape[:2]
        save(np.tile(t, (max(1, 16 // th), max(1, 16 // tw), 1)), os.path.join(out, "tiles1", oid + ".png"))
        save(swatch(t, at=SWATCH_AT.get(oid, (0, 0))), os.path.join(out, "swatches", oid + ".png"))
    pics = {}
    for oid in PICTURES:
        p = pics[oid] = tile(oid)
        save(p, os.path.join(out, "pictures", oid + ".png"))
        Image.fromarray(np.clip(np.round(p), 0, 255).astype(np.uint8)).resize((128, 96), Image.BOX).save(
            os.path.join(out, "swatches", oid + ".png"))
    # each desktop by the icons at 4K, 1:1, in the game's default color (the flags: where they show themselves)
    for oid in list(PATTERNS) + list(QUIET) + list(ART) + list(PICTURES):
        t = pics.get(oid)
        t = tile(oid) if t is None else t
        if oid == "usa":
            crop = desk.render(t)[CROP_UNION]
        elif oid == "kentucky":
            crop = half(desk.render(t, window=False)[CROP_SEAL])
        else:
            crop = desk.render(t)[CROP]
        save(crop, os.path.join(out, "crops", oid + ".png"))
        if oid in DESK:   # the whole desk at 1080p (half: what a 1080p screen shows, a dot to a pixel)
            save(half(desk.render(t)), os.path.join(out, "desk", oid + ".png"))
        print(oid, t.shape)
    # the ground following the player's color: three patterns in four colors, by the icons
    for oid in ("classic", "camo", "squiggle"):
        for cname, c in COLORS.items():
            save(desk.render(tile(oid, c))[CROP], os.path.join(out, "colors", f"{oid}_{cname}.png"))
    # zooms to look at
    for oid in ("camo", "squiggle"):
        t = np.tile(tile(oid), (2, 2, 1))
        save(np.repeat(np.repeat(t, 3, 0), 3, 1), os.path.join(out, "check", oid + ".png"))
    for oid, p in pics.items():
        save(np.repeat(np.repeat(p, 2, 0), 2, 1), os.path.join(out, "check", oid + "_2x.png"))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
