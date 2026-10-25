"""The work vans' trade stickers (round 6, Oct 24 2026): 64 x 64 die-cut vinyl, the trade's sign on a coloured field,
a cream band under it where the game prints the business's own name (the first word or two of the car's name).

The game's own decals stand in where it has them (the Spiffo's, Fossoil and McCoy vans: media/textures/shirtdecals);
every other van with a trade in its name gets one of these; a plain van an owner's bumper sticker from the decals
(I love KY, the flag, the wolf, the cardinal). The art is drawn at 4x, cut to whole pixels, outlined like the plate.
usage: python stickers.py   (out/stickers/sticker_<trade>.png and a sheet)
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "stickers")
S = 4
W = H = 64
BAND = (8, 46, 56, 58)      # where the game prints the name (x0, y0, x1, y1)

TRADE = {   # field colour, sign colour, the sign
    "mechanic": ("#2a5a9a", "#f2efe6", "wrench"),
    "wood": ("#8a5a2a", "#f2e6c8", "saw"),
    "green": ("#3a7a2e", "#e8f2d0", "leaf"),
    "metal": ("#3a3e44", "#ff9a2a", "flame"),
    "electric": ("#e8b020", "#1a1a1a", "bolt"),
    "build": ("#e86a1a", "#1a1a1a", "hat"),
    "farm": ("#a8322a", "#f2efe6", "barn"),
    "radio": ("#5a2a7a", "#f2efe6", "tower"),
}


def _sign(dr, kind, c):
    """the trade's sign, drawn on the 4x canvas inside the field (8..56, 8..44)"""
    s = S
    def P(*pts): return [(x * s, y * s) for x, y in pts]
    if kind == "wrench":
        dr.line(P((18, 38), (40, 16)), fill=c, width=5 * s)
        dr.ellipse(P((36, 9), (48, 21)), fill=c); dr.polygon(P((42, 9), (49, 9), (49, 16), (44, 14)), fill=(0, 0, 0, 0))
        dr.ellipse(P((40, 12), (45, 17)), fill=(0, 0, 0, 0))
        dr.ellipse(P((13, 33), (23, 43)), fill=c); dr.ellipse(P((16, 36), (20, 40)), fill=(0, 0, 0, 0))
    elif kind == "saw":
        dr.polygon(P((12, 30), (46, 18), (48, 26), (16, 36)), fill=c)
        for i in range(8):
            x0 = 16 + i * 4
            dr.polygon(P((x0, 36 - i * 0.8), (x0 + 2, 39 - i * 0.8), (x0 + 4, 35 - i * 0.8)), fill=c)
        dr.rounded_rectangle(P((44, 12), (54, 30)), radius=3 * s, fill=c)
        dr.rounded_rectangle(P((47, 16), (51, 25)), radius=1 * s, fill=(0, 0, 0, 0))
    elif kind == "leaf":
        dr.ellipse(P((16, 10), (48, 42)), fill=c)
        dr.polygon(P((16, 42), (16, 26), (32, 42)), fill=c)
        dr.line(P((20, 38), (42, 16)), fill=(0, 0, 0, 0), width=2 * s)
        for t in (0.35, 0.55, 0.75):
            x, y = 20 + 22 * t, 38 - 22 * t
            dr.line(P((x, y), (x - 6, y - 6)), fill=(0, 0, 0, 0), width=1 * s)
            dr.line(P((x, y), (x + 6, y + 6)), fill=(0, 0, 0, 0), width=1 * s)
    elif kind == "flame":
        dr.polygon(P((32, 8), (42, 22), (44, 32), (38, 42), (26, 42), (20, 32), (24, 24), (28, 28), (28, 18)), fill=c)
        dr.polygon(P((32, 22), (37, 30), (36, 38), (28, 38), (27, 32), (30, 30)), fill="#ffe08a")
    elif kind == "bolt":
        dr.ellipse(P((14, 8), (50, 44)), outline=c, width=3 * s)
        dr.polygon(P((35, 12), (22, 28), (31, 28), (27, 40), (42, 23), (33, 23)), fill=c)
    elif kind == "hat":
        dr.chord(P((16, 12), (48, 44)), 180, 360, fill=c)
        dr.rectangle(P((12, 28), (52, 33)), fill=c)
        dr.rectangle(P((30, 12), (34, 28)), fill=(0, 0, 0, 0))
        dr.rectangle(P((14, 36), (50, 40)), fill=(0, 0, 0, 0))
    elif kind == "barn":
        dr.polygon(P((12, 22), (32, 10), (52, 22), (52, 42), (12, 42)), fill=c)
        dr.rectangle(P((24, 28), (40, 42)), fill=(0, 0, 0, 0))
        dr.line(P((24, 28), (40, 42)), fill=c, width=2 * s); dr.line(P((40, 28), (24, 42)), fill=c, width=2 * s)
        dr.rectangle(P((28, 16), (36, 22)), fill=(0, 0, 0, 0))
    elif kind == "tower":
        dr.polygon(P((32, 14), (40, 42), (24, 42)), outline=c, width=2 * s)
        dr.line(P((28, 30), (36, 30)), fill=c, width=2 * s); dr.line(P((26, 38), (38, 38)), fill=c, width=2 * s)
        dr.ellipse(P((29, 9), (35, 15)), fill=c)
        for r in (8, 13):
            dr.arc(P((32 - r, 12 - r), (32 + r, 12 + r)), 200, 250, fill=c, width=2 * s)
            dr.arc(P((32 - r, 12 - r), (32 + r, 12 + r)), 290, 340, fill=c, width=2 * s)


def _hx(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def sticker(kind):
    field, ink, sign = TRADE[kind]
    big = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(big)
    dr.rounded_rectangle((2 * S, 2 * S, (W - 2) * S - 1, (H - 2) * S - 1), radius=8 * S, fill=_hx("#f4f2ea"))      # the die-cut white
    dr.rounded_rectangle((5 * S, 5 * S, (W - 5) * S - 1, 44 * S - 1), radius=6 * S, fill=_hx(field))
    layer = Image.new("RGBA", big.size, (0, 0, 0, 0))
    _sign(ImageDraw.Draw(layer), sign, _hx(ink))
    clip = Image.new("L", big.size, 0); ImageDraw.Draw(clip).rounded_rectangle((5 * S, 5 * S, (W - 5) * S - 1, 44 * S - 1), radius=6 * S, fill=255)
    big.paste(layer, (0, 0), Image.composite(layer.getchannel("A"), Image.new("L", big.size, 0), clip))
    dr.rounded_rectangle((BAND[0] * S, BAND[1] * S, BAND[2] * S - 1, BAND[3] * S - 1), radius=1 * S, fill=_hx("#e8e0c8"))
    im = big.resize((W, H), Image.BOX)
    a = im.split()[3].point(lambda v: 255 if v > 110 else 0)
    im = Image.merge("RGBA", (*[c.point(lambda v: v) for c in im.split()[:3]], a))
    # snap the colours back to the sticker's few inks (no soft edges), then a dark die-cut outline
    pal = [_hx("#f4f2ea"), _hx(field), _hx(ink), _hx("#e8e0c8"), _hx("#ffe08a")]
    px = im.load()
    for y in range(H):
        for x in range(W):
            r, g, b, al = px[x, y]
            if not al: continue
            px[x, y] = min(pal, key=lambda p: (p[0] - r) ** 2 + (p[1] - g) ** 2 + (p[2] - b) ** 2)
    out = im.copy(); po = out.load()
    for y in range(H):
        for x in range(W):
            if px[x, y][3]: continue
            if any(0 <= x + ox < W and 0 <= y + oy < H and px[x + ox, y + oy][3] for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                po[x, y] = (40, 36, 30, 255)
    return out


def build():
    os.makedirs(OUT, exist_ok=True)
    ims = {}
    for k in TRADE:
        ims[k] = sticker(k); ims[k].save(os.path.join(OUT, f"sticker_{k}.png"))
    return ims


if __name__ == "__main__":
    ims = build()
    sh = Image.new("RGBA", (len(ims) * 72 + 8, 80), (60, 62, 64, 255))
    for i, (k, im) in enumerate(ims.items()): sh.alpha_composite(im, (8 + i * 72, 8))
    sh.resize((sh.width * 3, sh.height * 3), Image.NEAREST).save(os.path.join(OUT, "sheet.png"))
    print("ok")
