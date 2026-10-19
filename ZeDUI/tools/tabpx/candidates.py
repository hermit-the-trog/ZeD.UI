"""Candidate redraws for three tab icons (Oct 19 2026; director: "The map icon on the tab did not communicate map
to me ... Same with livestock, maybe a cow head for that? Skills is also too hard to distinguish").
Same 16 x 16 grid and five tones as icons.py (w shine, l lit, m accent, d shade, k deep; lit from the top left).
Not wired into the game: `py candidates.py` renders a comparison sheet (the current icon beside each candidate, in
the real strips) to ZeDUI/mockups/zed_tab_icons_v1.png. The picked ones go into icons.py and export_tabs.py."""
import sys; sys.path.insert(0, ".")
import numpy as np
from PIL import Image, ImageDraw
import icons as IC
import render_icons as RI
import mock as MK


def blank():
    return [["."] * 16 for _ in range(16)]


def grid(g):
    return ["".join(r) for r in g]


def put(g, x, y, t):
    if 0 <= x < 16 and 0 <= y < 16: g[y][x] = t


def fill(g, x, y, w, h, t):
    for yy in range(y, y + h):
        for xx in range(x, x + w): put(g, xx, yy, t)


def disc(g, cx, cy, r, inner):
    """a lit round shape: top-left catches light, bottom-right falls into shade"""
    for y in range(16):
        for x in range(16):
            dx, dy = x - cx + 0.5, y - cy + 0.5
            d = (dx * dx + dy * dy) ** 0.5
            if d <= r:
                if d > r - 1.2:
                    put(g, x, y, "l" if dx + dy < -1 else ("d" if dx + dy > 1 else "m"))
                else:
                    put(g, x, y, inner)


# --- MAPS -----------------------------------------------------------------------------------------------------
def maps_a():
    """an opened road map: three panels on a zigzag fold, a dotted route, an X where it ends"""
    g = blank()
    for x in range(0, 5):   # left panel, lit
        fill(g, x, 3, 1, 10, "m"); put(g, x, 2, "l"); put(g, x, 13, "d")
    for x in range(5, 11):  # middle panel, in the fold's shade, one pixel lower
        fill(g, x, 4, 1, 10, "d"); put(g, x, 3, "m"); put(g, x, 14, "k")
    for x in range(11, 16):  # right panel, lit
        fill(g, x, 3, 1, 10, "m"); put(g, x, 2, "l"); put(g, x, 13, "d")
    fill(g, 0, 3, 1, 10, "l"); put(g, 0, 2, "w")
    fill(g, 15, 3, 1, 10, "d")
    for x, y in ((1, 11), (3, 10), (5, 10), (7, 9), (9, 8), (11, 7)):   # the route
        put(g, x, y, "w")
    for x, y in ((12, 4), (14, 4), (13, 5), (12, 6), (14, 6)):          # the X
        put(g, x, y, "k")
    return grid(g)


def maps_b():
    """a compass: a ring and a four-point star, north lit"""
    g = blank()
    disc(g, 8, 8, 7.4, ".")
    # the star
    for i in range(1, 6):
        put(g, 7, 7 - i, "w" if i > 2 else "l"); put(g, 8, 7 - i, "l")         # north (lit)
        put(g, 7, 8 + i, "d"); put(g, 8, 8 + i, "k")                              # south
        put(g, 7 - i, 7, "m"); put(g, 7 - i, 8, "d")                              # west
        put(g, 8 + i, 7, "m"); put(g, 8 + i, 8, "d")                              # east
    fill(g, 6, 6, 4, 4, "m"); put(g, 7, 7, "w"); put(g, 8, 8, "d")
    for x, y in ((6, 6), (9, 6), (6, 9), (9, 9)): put(g, x, y, "d")
    return grid(g)


# --- ANIMALS -----------------------------------------------------------------------------------------------------
def animals_a():
    """a cow's head from the front: horns, ears out to the sides, a pale muzzle with two nostrils"""
    g = blank()
    fill(g, 4, 3, 8, 10, "m")                       # the head
    fill(g, 4, 3, 8, 1, "l"); fill(g, 4, 3, 1, 9, "l"); put(g, 4, 3, "w"); put(g, 5, 3, "w")
    fill(g, 11, 4, 1, 8, "d")
    put(g, 4, 12, "."); put(g, 11, 12, ".")          # rounded chin corners
    fill(g, 1, 5, 3, 2, "m"); put(g, 1, 5, "l"); put(g, 1, 6, "d"); put(g, 0, 5, "l")       # left ear
    fill(g, 12, 5, 3, 2, "d"); put(g, 15, 5, "d"); put(g, 14, 6, "k")                         # right ear
    put(g, 3, 1, "w"); put(g, 3, 2, "l"); put(g, 4, 2, "l")                                  # left horn
    put(g, 12, 1, "l"); put(g, 12, 2, "d"); put(g, 11, 2, "d")                               # right horn
    put(g, 6, 6, "k"); put(g, 9, 6, "k")                                                      # eyes
    fill(g, 5, 9, 6, 4, "w"); fill(g, 5, 12, 6, 1, "l"); fill(g, 10, 9, 1, 4, "l")           # the muzzle
    put(g, 6, 11, "k"); put(g, 9, 11, "k")                                                    # nostrils
    fill(g, 6, 13, 4, 1, "d")
    put(g, 7, 4, "d"); put(g, 8, 4, "d"); put(g, 8, 5, "d")                                   # a spot on the brow
    return grid(g)


def animals_b():
    """a cow's head, no horns, big ears and a white blaze down the face"""
    g = blank()
    fill(g, 4, 2, 8, 11, "m")
    fill(g, 4, 2, 8, 1, "l"); fill(g, 4, 2, 1, 10, "l")
    fill(g, 11, 3, 1, 9, "d")
    put(g, 4, 12, "."); put(g, 11, 12, ".")
    fill(g, 0, 3, 4, 3, "m"); fill(g, 0, 3, 4, 1, "l"); put(g, 0, 5, "d"); put(g, 3, 5, "d")   # left ear
    fill(g, 12, 3, 4, 3, "d"); put(g, 15, 5, "k"); put(g, 12, 5, "k")                            # right ear
    fill(g, 7, 2, 2, 7, "w")                                                                     # the blaze
    put(g, 5, 6, "k"); put(g, 10, 6, "k")
    fill(g, 5, 9, 6, 4, "l"); fill(g, 5, 12, 6, 1, "m"); put(g, 6, 11, "k"); put(g, 9, 11, "k")
    fill(g, 6, 13, 4, 1, "d")
    return grid(g)


# --- SKILLS ------------------------------------------------------------------------------------------------------
def skills_a():
    """a medal on its ribbon, a star struck in it"""
    g = blank()
    for i in range(5):                                   # the ribbon, a V of two straps
        put(g, 3 + i, i, "l"); put(g, 4 + i, i, "m")
        put(g, 12 - i, i, "d"); put(g, 11 - i, i, "m")
    disc(g, 8, 10, 5.4, "m")
    for x, y in ((7, 7), (8, 7), (7, 8), (8, 8), (5, 9), (6, 9), (9, 9), (10, 9), (6, 10), (7, 10), (8, 10), (9, 10),
                 (6, 11), (9, 11), (5, 12), (10, 12)):   # the star
        put(g, x, y, "w" if y < 10 else "l")
    return grid(g)


def skills_b():
    """five rising level blocks, the game's own skill squares, three filled"""
    g = blank()
    for i in range(5):
        h = 3 + i * 2
        x = 1 + i * 3
        y = 14 - h
        filled = i < 3
        fill(g, x, y, 2, h, "m" if filled else ".")
        if filled:
            fill(g, x, y, 2, 1, "w" if i == 2 else "l"); fill(g, x + 1, y + 1, 1, h - 1, "d")
        else:
            fill(g, x, y, 2, 1, "d"); fill(g, x, y, 1, h, "d"); fill(g, x + 1, y + h - 1, 1, 1, "k"); fill(g, x + 1, y, 1, h, "k")
            fill(g, x, y + 1, 1, h - 2, "d")
    fill(g, 0, 14, 16, 1, "k")
    return grid(g)


def skills_c():
    """an open book, a star on the right page (the skill books)"""
    g = blank()
    fill(g, 1, 4, 6, 9, "l"); fill(g, 9, 4, 6, 9, "m")       # pages
    fill(g, 1, 4, 6, 1, "w"); fill(g, 7, 5, 2, 9, "k")        # top edge, the spine
    fill(g, 0, 5, 1, 9, "d"); fill(g, 15, 5, 1, 9, "k")
    fill(g, 1, 13, 6, 1, "d"); fill(g, 9, 13, 6, 1, "k")
    for y in (6, 8, 10): fill(g, 2, y, 4, 1, "m")             # lines of text, left page
    for x, y in ((11, 6), (12, 7), (11, 7), (10, 7), (11, 8), (10, 9), (12, 9)):   # a small star, right page
        put(g, x, y, "w")
    return grid(g)


CANDIDATES = {
    "maps": [("now", IC.ICONS["maps"]), ("A: road map", maps_a()), ("B: compass", maps_b())],
    "animals": [("now", IC.ICONS["animals"]), ("A: cow, horns", animals_a()), ("B: cow, blaze", animals_b())],
    "skills": [("now", IC.ICONS["skills"]), ("A: medal", skills_a()), ("B: level blocks", skills_b()),
               ("C: skill book", skills_c())],
}


def tile(g, kind, active=False, scale=6):
    acc, bright = MK.ACC[kind]
    W = 36
    img = np.zeros((W, W, 4), np.uint8); img[..., :3] = MK.BG; img[..., 3] = 255
    if active:
        MK.rect(img, 0, 0, W - 1, W, MK.shade(acc, 0.85))
        MK.rect(img, 0, 0, W - 1, 1, MK.shade(bright, 1.1)); MK.rect(img, 0, 0, 1, W, MK.shade(bright, 1.05))
        MK.rect(img, 0, W - 2, W - 1, 2, MK.shade(acc, 0.55)); MK.rect(img, W - 2, 0, 1, W, MK.shade(acc, 0.6))
    RI.ICONS["__c"] = g
    RI.draw_icon(img, "__c", 10, 10, acc, bright, active)
    return Image.fromarray(img, "RGBA").resize((W * scale, W * scale), Image.NEAREST)


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "../../mockups/zed_tab_icons_v1.png"
    S = 4
    cell = 36 * S
    rows = [("maps", "world"), ("animals", "world"), ("skills", "char")]
    cols = max(len(CANDIDATES[k]) for k, _ in rows)
    W = 170 + cols * (cell * 2 + 40)
    H = 40 + len(rows) * (cell + 70)
    sheet = Image.new("RGBA", (W, H), (34, 33, 31, 255))
    d = ImageDraw.Draw(sheet)
    d.text((14, 12), "Tab icons: the current one, then candidates (each idle and active, 4x; the game draws them at 1x / 2x)",
           fill=(220, 220, 220, 255))
    y = 40
    for key, kind in rows:
        d.text((14, y + cell // 2), key.upper(), fill=(230, 200, 140, 255))
        x = 170
        for title, g in CANDIDATES[key]:
            d.text((x, y), title, fill=(220, 220, 220, 255))
            sheet.alpha_composite(tile(g, kind, False, S), (x, y + 18))
            sheet.alpha_composite(tile(g, kind, True, S), (x + cell + 8, y + 18))
            # 1x and 2x, as small as the game draws them at 1080p / 4K
            sheet.alpha_composite(tile(g, kind, False, 1), (x, y + 18 + cell + 6))
            sheet.alpha_composite(tile(g, kind, False, 2), (x + 44, y + 18 + cell + 6 - 36))
            x += cell * 2 + 40
        y += cell + 70
    sheet.save(out)
    print("ok", out)
