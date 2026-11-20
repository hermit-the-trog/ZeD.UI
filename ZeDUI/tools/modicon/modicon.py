"""ZeD-GUI's mod icons: the disk (Nov 20 2026).

Every mod in the ZeD-GUI family wears the same icon: a 3.5-inch disk. ZeD-GUI is the system disk and every add-on is
another disk in the box. The disk, its cut corner, the metal shutter, the paper label with its band and the Z pressed
into the plastic stay the same. A mod brings two things: its mark on the label (MARKS below) and one of ZeD's nine
accents for the plastic (PZ Teal is ZeD-GUI's alone). The rules, and the name pattern that goes with the icon, are in
README.md beside this file.

Drawn on a 32 x 32 grid; one cell is 2 px in the 64 x 64 icon.png. The game draws a mod's icon at 18 to 84 px with
plain bilinear filtering and no mipmaps (ZeD's Mods list: 24 units, so 24 px at 1080p, 18 on a Steam Deck, 84 at 4K
with UI scale 1.75), so every line in a mark is 2 cells or wider: a thinner one drops out at 18 px.

    py modicon.py <mark> <accent> <out.png>     one icon.png (64 x 64)
    py modicon.py --proof <out.png>             every mod in MODS at 2x, then at 24 and 18 px as the game draws them,
                                                magnified 4x, on ZeD's Dark and Light lists
    py modicon.py --modinfo <mod.info> <name>   sets the mod's name= and puts icon=icon.png after poster=
                                                (its line endings and the rest of the file are kept)

Change this script, never the picture.
"""
import math
import os
import sys

from PIL import Image, ImageDraw

N = 32
INK = (12, 12, 12)
PAPER = (242, 240, 236)
FACE = (214, 210, 202)          # the label's foot, and a mark's light parts ("o")
METAL, METAL_EDGE, METAL_LIT = (198, 196, 192), (90, 88, 84), (232, 230, 226)
WINDOW = (40, 38, 36)

# ZeD's nine accents: (the Dark theme value, its bright step), from the design system's tokens.
ACCENTS = {
    "red": ((204, 68, 68), (238, 102, 102)),
    "orange": ((212, 146, 42), (232, 168, 48)),
    "yellow": ((204, 170, 34), (238, 221, 68)),
    "green": ((68, 170, 68), (102, 204, 102)),
    "blue": ((68, 136, 204), (102, 170, 238)),
    "teal": ((71, 161, 140), (92, 196, 170)),      # PZ Teal: ZeD-GUI's alone
    "purple": ((136, 85, 187), (170, 119, 221)),
    "pink": ((221, 85, 136), (255, 119, 170)),
    "mono": ((136, 136, 136), (170, 170, 170)),    # Settings calls it None
}

# Each mod's mark on the label: X ink, o the light face, . the paper. At most 24 cells wide and 14 tall (it is
# centered on the label); every line 2 cells or wider.
MARKS = {
    "zed": [            # ZeD-GUI: the Z
        "XXXXXXXXXXXX",
        "XXXXXXXXXXXX",
        "........XXX.",
        ".......XXX..",
        "......XXX...",
        ".....XXX....",
        "....XXX.....",
        "...XXX......",
        "..XXX.......",
        ".XXX........",
        "XXXXXXXXXXXX",
        "XXXXXXXXXXXX",
    ],
    "slots": [          # Multi-Slot: one long thing across two squares, the two empty squares under it
        "XXXXXXXXXXXXXX",
        "XXXXXXXXXXXXXX",
        "XXXXXXXXXXXXXX",
        "XXXXXXXXXXXXXX",
        "XXXXXXXXXXXXXX",
        "XXXXXXXXXXXXXX",
        "..............",
        "..............",
        "XXXXXX..XXXXXX",
        "XXXXXX..XXXXXX",
        "XX..XX..XX..XX",
        "XX..XX..XX..XX",
        "XXXXXX..XXXXXX",
        "XXXXXX..XXXXXX",
    ],
    "check": [          # Picks: the tick
        "............XXX",
        "...........XXXX",
        "..........XXXXX",
        ".........XXXXXX",
        "........XXXXXX.",
        "XXX....XXXXXX..",
        "XXXX..XXXXXX...",
        "XXXXX.XXXXX....",
        ".XXXXXXXXX.....",
        "..XXXXXXX......",
        "...XXXXX.......",
        "....XXX........",
    ],
    "watch": [          # Watches (planned): a round case on its strap, two hands
        "..XXXXXX..",
        "..XXXXXX..",
        ".XXXXXXXX.",
        "XXXXXXXXXX",
        "XXooooooXX",
        "XXooXXooXX",
        "XXooXXXoXX",
        "XXooXXXoXX",
        "XXooooooXX",
        "XXooooooXX",
        "XXXXXXXXXX",
        ".XXXXXXXX.",
        "..XXXXXX..",
        "..XXXXXX..",
    ],
}

# The family: (name in the Mods menu, mod id, mark, accent, where its icon.png lives).
MODS = [
    ("ZeD-GUI [BETA]", "ZeD_UI", "zed", "teal", "this repo: 42/icon.png"),
    ("ZeD-GUI: Multi-Slot [BETA]", "ZeDMultiSlot", "slots", "orange", "the ZeD-MultiSlot repo: 42/icon.png"),
    ("ZeD-GUI: Picks", "ZeD_Picks", "check", "green", "this repo: ZeDUI/picks_mod/ZeD_Picks/42/icon.png"),
    ("ZeD-GUI: Watches", None, "watch", "blue", "planned"),
]

# the Z pressed into the plastic, at the disk's top left
Z_SMALL = ["XXXX", "..X.", ".X..", "XXXX"]


def shade(c, f):
    return tuple(max(0, min(255, round(v * f))) for v in c)


def disk(mark, accent):
    """The icon as a 32 x 32 RGBA picture (one pixel per cell); the cut corner is clear."""
    if mark not in MARKS:
        raise SystemExit("no mark called %r; the marks are: %s" % (mark, ", ".join(MARKS)))
    if accent not in ACCENTS:
        raise SystemExit("no accent called %r; the accents are: %s" % (accent, ", ".join(ACCENTS)))
    c, cb = ACCENTS[accent]
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    p = im.load()

    def put(x, y, col):
        if 0 <= x < N and 0 <= y < N:
            p[x, y] = col + (255,)

    def rect(x0, y0, x1, y1, col):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                put(x, y, col)

    def box(x0, y0, x1, y1, col):
        rect(x0, y0, x1, y0, col)
        rect(x0, y1, x1, y1, col)
        rect(x0, y0, x0, y1, col)
        rect(x1, y0, x1, y1, col)

    def grid(rows, x0, y0, cols):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in cols:
                    put(x0 + i, y0 + j, cols[ch])

    for y in range(N):                              # the plastic, its top right corner cut
        for x in range(N):
            if x - y <= 27:
                put(x, y, c)
    for y in range(N):                              # its ink outline
        for x in range(N):
            if x - y <= 27 and (x in (0, N - 1) or y in (0, N - 1) or x - y == 27):
                put(x, y, INK)
    for k in range(4):                              # the cut's edge, doubled where it meets the sides
        put(28 + k, k, INK)
    rect(1, 1, 1, 30, cb)                           # the lit edges
    rect(1, 1, 26, 1, cb)
    grid(Z_SMALL, 2, 4, {"X": shade(c, 0.55)})      # the maker's Z, pressed into the plastic
    rect(8, 1, 21, 10, METAL)                       # the shutter and its window
    box(8, 1, 21, 10, METAL_EDGE)
    rect(9, 2, 20, 2, METAL_LIT)
    rect(16, 3, 19, 8, WINDOW)
    rect(4, 13, 27, 29, PAPER)                      # the label, its band and its foot
    rect(4, 13, 27, 14, shade(c, 0.85))
    rect(4, 29, 27, 29, FACE)
    rows = MARKS[mark]
    w, h = max(len(r) for r in rows), len(rows)
    if w > 24 or h > 14:
        raise SystemExit("the %s mark is %d x %d cells; it has to fit 24 x 14" % (mark, w, h))
    grid(rows, 4 + (24 - w) // 2, 15 + (14 - h) // 2, {"X": INK, "o": FACE})
    return im


def icon(mark, accent, scale=2):
    return disk(mark, accent).resize((N * scale, N * scale), Image.NEAREST)


def game_scale(im, size):
    """As the game draws a mod's icon (drawTextureScaled): bilinear on premultiplied color, no mipmaps."""
    src = im.convert("RGBA")
    w, h = src.size
    p = src.load()
    out = Image.new("RGBA", (size, size))
    q = out.load()
    s = w / size
    for oy in range(size):
        v = (oy + 0.5) * s - 0.5
        y0 = math.floor(v)
        fy = v - y0
        for ox in range(size):
            u = (ox + 0.5) * s - 0.5
            x0 = math.floor(u)
            fx = u - x0
            acc = [0.0, 0.0, 0.0, 0.0]
            for dx, dy, wt in ((0, 0, (1 - fx) * (1 - fy)), (1, 0, fx * (1 - fy)), (0, 1, (1 - fx) * fy), (1, 1, fx * fy)):
                r, g, b, a = p[min(max(x0 + dx, 0), w - 1), min(max(y0 + dy, 0), h - 1)]
                a /= 255.0
                acc[0] += r * a * wt
                acc[1] += g * a * wt
                acc[2] += b * a * wt
                acc[3] += a * wt
            al = acc[3]
            q[ox, oy] = tuple(round(v / al) if al > 0 else 0 for v in acc[:3]) + (round(al * 255),)
    return out


def proof(out):
    """Every mod in MODS: the icon at 2x, then at 24 and 18 px on ZeD's Dark and Light lists, magnified 4x."""
    dark, light = (26, 24, 21), (189, 183, 173)       # surf1 in ZeD's Dark and Light themes
    pad, mag, row_h, x_icon = 4, 4, 152, 140
    tile = (24 + 2 * pad) * mag
    sheet = Image.new("RGB", (x_icon + 4 * (tile + 8) + 8, 18 + row_h * len(MODS)), (48, 48, 48))
    d = ImageDraw.Draw(sheet)
    d.text((8, 3), "24 px (1080p) and 18 px (Steam Deck) on Dark and Light, as the game draws them, shown 4x",
           fill=(230, 230, 230))
    for k, (name, _, mark, accent, _) in enumerate(MODS):
        y = 18 + k * row_h
        big = icon(mark, accent, 4)
        ground = Image.new("RGBA", big.size, (80, 80, 80, 255))
        ground.alpha_composite(big)
        sheet.paste(ground.convert("RGB"), (6, y + 2))
        d.text((6, y + 134), "%s  (%s, %s)" % (name, mark, accent), fill=(255, 220, 90))
        x = x_icon
        for size in (24, 18):
            for bg in (dark, light):
                t = Image.new("RGBA", (size + 2 * pad, size + 2 * pad), bg + (255,))
                t.alpha_composite(game_scale(icon(mark, accent), size), (pad, pad))
                t = t.convert("RGB").resize((t.width * mag, t.height * mag), Image.NEAREST)
                sheet.paste(t, (x, y + 2 + (tile - t.height) // 2))
                x += tile + 8
    sheet.save(out)
    return sheet.size


def set_modinfo(path, name):
    """The mod's name= and icon=icon.png in its mod.info; everything else in the file stays as it was."""
    raw = open(path, "rb").read()
    bom = raw.startswith(b"\xef\xbb\xbf")
    text = raw.decode("utf-8-sig")
    eol = "\r\n" if "\r\n" in text else "\n"
    lines = text.splitlines()
    if not any(l.startswith("name=") for l in lines):
        raise SystemExit("%s has no name= line" % path)
    lines = ["name=" + name if l.startswith("name=") else l for l in lines]
    if not any(l.strip() == "icon=icon.png" for l in lines):
        lines = [l for l in lines if not l.startswith("icon=")]
        at = next((i + 1 for i, l in enumerate(lines) if l.startswith("poster=")), len(lines))
        lines.insert(at, "icon=icon.png")
    new = eol.join(lines) + (eol if text.endswith(("\n", "\r")) else "")
    open(path, "wb").write((b"\xef\xbb\xbf" if bom else b"") + new.encode("utf-8"))
    return new


if __name__ == "__main__":
    a = sys.argv[1:]
    if len(a) == 2 and a[0] == "--proof":
        print("wrote", a[1], proof(os.path.expanduser(a[1])))
    elif len(a) == 3 and a[0] == "--modinfo":
        print(set_modinfo(os.path.expanduser(a[1]), a[2]))
    elif len(a) == 3:
        mark, accent, out = a
        out = os.path.expanduser(out)
        os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
        icon(mark, accent).save(out)
        print("wrote", out, "(%s on %s, 64 x 64)" % (mark, accent))
    else:
        raise SystemExit(__doc__)
