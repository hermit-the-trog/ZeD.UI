"""The belt's round hands as ready-made pictures (Oct 22 2026, the drawing-cost work: PERF_2026-10-22.md).

ZeD_Belt.lua used to draw each hand circle (its fill, its outline, the focus wash) one screen row at a time: about
500 rectangles a frame. These are the same shapes, pixel for pixel, as white masks: the Lua draws one picture tinted
with the colour and alpha the rows had. The rows are computed here exactly as the Lua computes them (the same
floating-point steps), so the picture and the rows cover the same pixels.

  d<s>.png        the filled circle in an s x s box            (disc(), s = 36 .. 136)
  r<s>_<t>.png    a ring, t screen pixels thick                (ring(); the sizes per thickness in RING_SIZES)

That covers the hands, their outlines, the focus wash and the framed condition ring (its well, fill and two frame
lines, Oct 27 2026; High contrast's two-hairline frames too) at every scale from 0.7 to 2.35 (Large text included).
Each picture is cropped to what the rows cover; its left edge sits ox pixels from the box (a row can stick out one
pixel left of the box), which the Lua works out the same way. A size outside these ranges draws the old way, row
runs merged.

usage: py d_rounds.py [mod root]   ->   42/media/textures/ZeD/belt/round/*.png"""
import math
import os
import sys

from PIL import Image

DISC_RANGE = (36, 136)
# thickness -> (first size, last size); ZeD_Belt.lua RING_BAKED is the same table
RING_SIZES = {1: (20, 72), 2: (22, 110), 3: (36, 80), 4: (28, 122), 6: (30, 122), 8: (62, 106), 12: (66, 110)}


def disc_rows(s):
    """[(row, x0, w)] relative to the box, as ZeD_Belt.lua disc()"""
    rad = s / 2
    out = []
    for row in range(s):
        dy = abs(row - rad + 0.5)
        hw = math.floor(math.sqrt(max(0, rad * rad - dy * dy)) + 0.5)
        if hw > 0:
            out.append((row, math.floor(rad) - hw, hw * 2))
    return out


def ring_rows(s, t):
    """[(row, x0, w)] relative to the box, as ZeD_Belt.lua ring()"""
    rad = s / 2
    inner = max(0, rad - t)
    out = []
    for row in range(s):
        dy = abs(row - rad + 0.5)
        hw = math.floor(math.sqrt(max(0, rad * rad - dy * dy)) + 0.5)
        if hw > 0:
            iw = math.floor(math.sqrt(inner * inner - dy * dy) + 0.5) if dy < inner else 0
            cx = math.floor(rad)
            if iw <= 0:
                out.append((row, cx - hw, hw * 2))
            else:
                out.append((row, cx - hw, hw - iw))
                out.append((row, cx + iw, hw - iw))
    return out


def picture(rows):
    rows = [r for r in rows if r[2] > 0]
    x0 = min(r[1] for r in rows)
    x1 = max(r[1] + r[2] for r in rows)
    y0 = min(r[0] for r in rows)
    y1 = max(r[0] for r in rows) + 1
    im = Image.new("RGBA", (x1 - x0, y1 - y0), (255, 255, 255, 0))
    px = im.load()
    for row, x, w in rows:
        for xx in range(x, x + w):
            px[xx - x0, row - y0] = (255, 255, 255, 255)
    return im


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "..", "..")
    out = os.path.join(root, "42", "media", "textures", "ZeD", "belt", "round")
    os.makedirs(out, exist_ok=True)
    n = 0
    for s in range(DISC_RANGE[0], DISC_RANGE[1] + 1):
        picture(disc_rows(s)).save(os.path.join(out, "d%d.png" % s))
        n += 1
    for t, (lo, hi) in sorted(RING_SIZES.items()):
        for s in range(lo, hi + 1):
            picture(ring_rows(s, t)).save(os.path.join(out, "r%d_%d.png" % (s, t)))
            n += 1
    print("%d pictures -> %s" % (n, os.path.normpath(out)))


if __name__ == "__main__":
    main()
