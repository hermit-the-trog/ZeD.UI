"""The Kentucky license header, redrawn in pixel art (the director, Nov 2026: the old header "is in an old art style").

The header band is 24 art pixels tall. It comes as two pieces the game pins to the band's ends, each drawn at a
whole-number scale with nearest filtering (ZeD.Atoms' nearest loader), the band itself filled with the license blue
in between, so it fits any card width:
  ky_head_left.png   the state's outline, COMMONWEALTH OF / KENTUCKY / OPERATOR'S LICENSE
  ky_head_right.png  CLASS D, and the DONOR pill
One art pixel is one texel. Previews at 2x and 4x on bands of the card's real widths go to the out folder.

usage: py ky_header.py [out folder]
"""
import os
import sys
from PIL import Image

H = 24
BLUE = (27, 28, 146)          # KY.blue in IdentityTab.lua
SHADE = (13, 14, 92)          # the type's drop shadow, one pixel down and right
RULE = (64, 66, 190)          # the band's lighter top rule
WHITE = (255, 255, 255)
GOLD = (244, 196, 48)
PINK = (246, 170, 186)
RED = (190, 26, 52)
NAVY = (10, 11, 70)
STATE = (150, 196, 232)       # KY.skyBlue, the outline's fill

F57 = {
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"], "B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "C": ["01110", "10001", "10000", "10000", "10000", "10001", "01110"], "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"], "F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
    "G": ["01110", "10001", "10000", "10111", "10001", "10001", "01111"], "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "I": ["01110", "00100", "00100", "00100", "00100", "00100", "01110"], "J": ["00111", "00010", "00010", "00010", "00010", "10010", "01100"],
    "K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"], "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"], "N": ["10001", "10001", "11001", "10101", "10011", "10001", "10001"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"], "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "Q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"], "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"], "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"], "V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    "W": ["10001", "10001", "10001", "10101", "10101", "10101", "01010"], "X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"], "Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
    " ": ["000", "000", "000", "000", "000", "000", "000"],
}
F35 = {
    "A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"], "C": ["011", "100", "100", "100", "011"],
    "D": ["110", "101", "101", "101", "110"], "E": ["111", "100", "110", "100", "111"], "F": ["111", "100", "110", "100", "100"],
    "G": ["011", "100", "101", "101", "011"], "H": ["101", "101", "111", "101", "101"], "I": ["111", "010", "010", "010", "111"],
    "J": ["001", "001", "001", "101", "010"], "K": ["101", "101", "110", "101", "101"], "L": ["100", "100", "100", "100", "111"],
    "M": ["101", "111", "111", "101", "101"], "N": ["110", "101", "101", "101", "101"], "O": ["010", "101", "101", "101", "010"],
    "P": ["110", "101", "110", "100", "100"], "Q": ["010", "101", "101", "110", "011"], "R": ["110", "101", "110", "101", "101"],
    "S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"], "U": ["101", "101", "101", "101", "011"],
    "V": ["101", "101", "101", "101", "010"], "W": ["101", "101", "111", "111", "101"], "X": ["101", "101", "010", "101", "101"],
    "Y": ["101", "101", "010", "010", "010"], "Z": ["111", "001", "010", "100", "111"], "'": ["1", "1", "0", "0", "0"],
    " ": ["00", "00", "00", "00", "00"],
}
# Kentucky, west to east: the Purchase at the low west tip, the Ohio along the top rising to the northeast, the
# Big Sandy and the mountains down the east, the Tennessee line straight along the bottom
KY_SHAPE = [
    "......................#.....",
    "....................####....",
    "...............##..#######..",
    "............###############.",
    ".........###################",
    "......####################..",
    "...####################.....",
    ".####################.......",
    "#####################.......",
]
FRANKFORT = (17, 4)
# the donor is a BRAIN donor (the director's joke, kept: it's a zombie game): a brain from the side, its folds in pink
BRAIN = ["001101100", "011111110", "110110111", "111101101", "011111110", "000001100"]


def bold(g):
    """a glyph one pixel heavier: its own columns OR'd with themselves shifted one right"""
    w = len(g[0])
    return ["".join("1" if ((x < w and r[x] == "1") or (x > 0 and r[x - 1] == "1")) else "0" for x in range(w + 1)) for r in g]


def text_w(s, font, gap=1, heavy=False):
    return sum(len(font[ch][0]) + (1 if heavy else 0) + gap for ch in s) - gap


def put(img, x, y, s, font, c, gap=1, heavy=False, shadow=True):
    px = img.load()
    for ch in s:
        g = bold(font[ch]) if heavy else font[ch]
        for gy, row in enumerate(g):
            for gx, b in enumerate(row):
                if b == "1":
                    sx, sy = x + gx + 1, y + gy + 1
                    if shadow and 0 <= sx < img.width and 0 <= sy < img.height and px[sx, sy][:3] == BLUE:
                        px[sx, sy] = SHADE + (255,)
                    px[x + gx, y + gy] = c + (255,)
        x += len(g[0]) + gap
    return x


def mask(img, x, y, rows, c):
    px = img.load()
    for gy, row in enumerate(rows):
        for gx, b in enumerate(row):
            if b in ("#", "1"):
                px[x + gx, y + gy] = c + (255,)


def band(w):
    im = Image.new("RGBA", (w, H), BLUE + (255,))
    px = im.load()
    for x in range(w):
        px[x, 0] = RULE + (255,)
        px[x, H - 1] = SHADE + (255,)
    return im


def left_piece():
    t1, t2, t3 = "COMMONWEALTH OF", "KENTUCKY", "OPERATOR'S LICENSE"
    sx = len(KY_SHAPE[0]) + 6
    w = sx + max(text_w(t1, F35), text_w(t2, F57, heavy=True), text_w(t3, F35)) + 2
    im = band(w)
    px = im.load()
    # the state, a pixel of navy round its fill, beside the KENTUCKY line
    oy = 9
    for y, r in enumerate(KY_SHAPE):
        for x, b in enumerate(r):
            if b == "#":
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        px[3 + x + dx, oy + y + dy] = NAVY + (255,)
    mask(im, 3, oy, KY_SHAPE, STATE)
    px[3 + FRANKFORT[0], oy + FRANKFORT[1]] = GOLD + (255,)
    put(im, sx, 3, t1, F35, WHITE)
    put(im, sx, 9, t2, F57, WHITE, heavy=True)
    put(im, sx, 17, t3, F35, GOLD)
    return im


def right_piece():
    don_w = 2 + 9 + 2 + text_w("DONOR", F35) + 2
    key = 11
    w = max(don_w, text_w("CLASS", F35) + 2 + key) + 3
    im = band(w)
    px = im.load()
    kx, ky = w - 3 - key, 2
    for y in range(key):
        for x in range(key):
            if not ((x in (0, key - 1)) and (y in (0, key - 1))):
                px[kx + x, ky + y] = NAVY + (255,)
    put(im, kx + 3, ky + 2, "D", F57, WHITE, shadow=False)
    put(im, kx - 2 - text_w("CLASS", F35), ky + 3, "CLASS", F35, WHITE)
    pw, ph = don_w, 10
    px0, py0 = w - 3 - pw, H - 2 - ph
    for y in range(ph):
        for x in range(pw):
            if not ((x in (0, pw - 1)) and (y in (0, ph - 1))):
                px[px0 + x, py0 + y] = PINK + (255,)
    mask(im, px0 + 2, py0 + 2, BRAIN, RED)
    put(im, px0 + 13, py0 + 3, "DONOR", F35, RED, shadow=False)
    return im


def donor_badge():
    """the BRAIN DONOR pill on its own, for the narrow card (beside the seal, where Tennessee puts its donor heart)"""
    pw, ph = 2 + 9 + 2 + text_w("DONOR", F35) + 2, 10
    im = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
    px = im.load()
    for y in range(ph):
        for x in range(pw):
            if not ((x in (0, pw - 1)) and (y in (0, ph - 1))):
                px[x, y] = PINK + (255,)
    mask(im, 2, 2, BRAIN, RED)
    put(im, 13, 3, "DONOR", F35, RED, shadow=False)
    return im


def tall_piece():
    """the narrow card's header (the director, Nov 5 2026: the vertical license, laid out like Tennessee's): the three
    lines stacked and centered, no outline (the state is the security pattern's watermark there); CLASS D and DONOR
    move into the card's own fields"""
    t1, t2, t3 = "COMMONWEALTH OF", "KENTUCKY", "OPERATOR'S LICENSE"
    w = max(text_w(t1, F35), text_w(t2, F57, heavy=True), text_w(t3, F35)) + 6
    im = band(w)
    put(im, (w - text_w(t1, F35)) // 2, 3, t1, F35, WHITE)
    put(im, (w - text_w(t2, F57, heavy=True)) // 2, 9, t2, F57, WHITE, heavy=True)
    put(im, (w - text_w(t3, F35)) // 2, 17, t3, F35, GOLD)
    return im


CREAM = (232, 228, 218)        # KY.cardBg
WAVE = (214, 222, 232)         # the guilloche's pale blue
WAVE2 = (224, 220, 206)        # and its warm second line


def bg_tile():
    """the security pattern, tiled behind the card's fields: two faint wave lines a period apart (16 x 8)"""
    im = Image.new("RGBA", (16, 8), CREAM + (255,))
    px = im.load()
    a = [2, 1, 1, 0, 0, 1, 1, 2, 3, 4, 4, 5, 5, 4, 4, 3]
    for x in range(16):
        px[x, a[x]] = WAVE + (255,)
        px[x, (a[(x + 8) % 16] + 4) % 8] = WAVE2 + (255,)
    return im


def watermark():
    """the state, large and faint, for the narrow card's field area (4 texels a shape pixel)"""
    k = 4
    w, h = len(KY_SHAPE[0]) * k, len(KY_SHAPE) * k
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    for y, r in enumerate(KY_SHAPE):
        for x, b in enumerate(r):
            if b == "#":
                for yy in range(k):
                    for xx in range(k):
                        px[x * k + xx, y * k + yy] = WAVE + (150,)
    return im


def preview(left, right, card_w, k):
    """the header as the card would draw it: the band at the card's inner width, the pieces at its ends, scale k"""
    im = band(card_w // k + 1).resize(((card_w // k + 1) * k, H * k), Image.NEAREST).crop((0, 0, card_w, H * k))
    im.alpha_composite(left.resize((left.width * k, H * k), Image.NEAREST), (0, 0))
    r = right.resize((right.width * k, H * k), Image.NEAREST)
    im.alpha_composite(r, (card_w - r.width, 0))
    return im


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
    os.makedirs(out, exist_ok=True)
    L, R = left_piece(), right_piece()
    L.save(os.path.join(out, "ky_head_left.png"))
    R.save(os.path.join(out, "ky_head_right.png"))
    T_ = tall_piece()
    T_.save(os.path.join(out, "ky_head_tall.png"))
    bg_tile().save(os.path.join(out, "ky_bg_tile.png"))
    watermark().save(os.path.join(out, "ky_watermark.png"))
    donor_badge().save(os.path.join(out, "ky_donor.png"))
    print("left", L.size, "right", R.size, "tall", T_.size)
    for cw, k in ((300, 2), (420, 2), (600, 4), (840, 4)):
        preview(L, R, cw, k).save(os.path.join(out, f"preview_{cw}_x{k}.png"))
    print("wrote", out)
