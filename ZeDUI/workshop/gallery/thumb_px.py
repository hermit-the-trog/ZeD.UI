"""The Workshop preview picture (256 x 256) cut from the gallery's title card: the used copy of "Bitchin' znix
Programs" with ZeD-GUI marked on its cover (the director, Nov 2 2026: "change our preview thumbnail to the bitchin'
ZNIX programs book ... this would never be featured in a magazine like that"; it replaces the ZNIX USER magazine
cover in ../thumbnail/). The card is drawn at 480 x 270 by cover_px.py, one art pixel per screen pixel, so a 256 x 256
cut of it is the art at 1x, nothing resampled.

The build's colour (the director, Nov 2 2026): red is a test build, yellow the beta, green the release.
  --style strip    a band across the foot with the word, as the test build's cover had (default)
  --style sticker  a price-sticker on the book's corner, in the fiction of the used copy
usage: python thumb_px.py --test | --beta | --release | --plain  [--style strip|sticker]  [--out file.png]
Writes thumb_256_<tag>[_sticker].png beside this script unless --out is given."""
import os
import subprocess
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools", "dashpx"))

BANDS = {
    "--test": ("TEST BUILD", (178, 38, 44), (214, 84, 76), (120, 24, 30), (240, 234, 220), "test"),
    "--beta": ("BETA", (232, 192, 40), (250, 226, 120), (160, 124, 16), (30, 26, 36), "beta"),
    "--release": ("RELEASE", (40, 140, 76), (96, 196, 128), (20, 86, 44), (240, 234, 220), "release"),
}


def card():
    """The title card at 1x, drawn fresh by cover_px.py (into a temp file beside this script)."""
    tmp = os.path.join(HERE, "_thumb_card.png")
    subprocess.run([sys.executable, "-I", os.path.join(HERE, "cover_px.py"), tmp], check=True, capture_output=True)
    im = Image.open(tmp.replace(".png", "_1x.png")).convert("RGB")
    for f in (tmp, tmp.replace(".png", "_1x.png")):
        try:
            os.remove(f)
        except OSError:
            pass
    return im


def cut(im):
    """256 x 256 around the book (cover_px.py: BX, BY, BW, BH = 60, 12, 200, 247; its page edges and flags run to
    about x 272). The floppy's edge peeks in at the right: the desk from the left margin is mirrored over it."""
    x0, y0 = 34, 8
    sq = im.crop((x0, y0, x0 + 256, y0 + 256))
    edge = 283 - x0                                   # where the floppy starts in the cut
    if edge < 256:
        strip = sq.crop((0, 0, 256 - edge, 256)).transpose(Image.FLIP_LEFT_RIGHT)
        sq.paste(strip, (edge, 0))
    return sq


def pixel_text(img, s, x, y, colour, scale=1):
    """The mod's 5 x 7 pixel face (tools/dashpx/engine.py), as the cover's own small capitals."""
    import engine  # noqa: E402  (tools/dashpx)
    font = engine.F57 if hasattr(engine, "F57") else None
    px = img.load()
    cx = x
    for ch in s:
        g = font.get(ch) if font else None
        if g is None:
            cx += 4 * scale
            continue
        for j, row in enumerate(g):
            for i, b in enumerate(row):
                if b == "1":
                    for dy in range(scale):
                        for dx in range(scale):
                            px[cx + i * scale + dx, y + j * scale + dy] = colour
        cx += (len(g[0]) + 1) * scale
    return cx - x


def text_w(s, scale=1):
    import engine  # noqa: E402
    w = 0
    for ch in s:
        g = engine.F57.get(ch)
        w += ((len(g[0]) + 1) if g else 4) * scale
    return w - scale


def strip(sq, label, mid, light, dark, ink):
    px = sq.load()
    y0, y1 = 256 - 15, 255
    for y in range(y0, y1 + 1):
        for x in range(256):
            px[x, y] = light if y == y0 else (dark if y == y1 else mid)
    w = text_w(label)
    pixel_text(sq, label, (256 - w) // 2, y0 + 4, ink)


def sticker(sq, label, mid, light, dark, ink):
    """A price-sticker on the cover's top right corner, slightly crooked, like the USED one on the left."""
    px = sq.load()
    w = text_w(label) + 10
    h = 13
    x0, y0 = 256 - 34 - w - 2, 10
    for y in range(h):
        off = y // 7                                   # a one-pixel lean
        for x in range(w):
            xx, yy = x0 + x + off, y0 + y
            edge = x == 0 or x == w - 1 or y == 0 or y == h - 1
            px[xx, yy] = dark if edge else (light if y == 1 else mid)
    for y in range(h):                                 # its shadow on the cover
        px[x0 + w + y // 7, y0 + y + 1] = (40, 30, 34)
    pixel_text(sq, label, x0 + 5, y0 + 3, ink)


def main():
    a = sys.argv[1:]
    style = a[a.index("--style") + 1] if "--style" in a else "strip"
    out = a[a.index("--out") + 1] if "--out" in a else None
    band = next((b for k, b in BANDS.items() if k in a), None)
    sq = cut(card())
    tag = "plain"
    if band:
        label, mid, light, dark, ink, tag = band
        (sticker if style == "sticker" else strip)(sq, label, mid, light, dark, ink)
        if style == "sticker":
            tag += "_sticker"
    out = out or os.path.join(HERE, "thumb_256_%s.png" % tag)
    sq.save(out, optimize=True)
    print("wrote", out, os.path.getsize(out), "bytes")


if __name__ == "__main__":
    main()
