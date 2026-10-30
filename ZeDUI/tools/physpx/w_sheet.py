"""Review sheets for the plates that fill the card (REQUEST_design_plates_fill_20261030.md): each face drawn in a stand-in
card at the UI scale it fills, at the plates' whole zoom, so the fit can be judged at real pixel size.
  python w_sheet.py scales out.png [pid ...]   one plate across the UI scales 0.75 .. 2.0 (default oven_green, walkie_army)
  python w_sheet.py at out.png <ui scale>      every plate at one UI scale (1.75: the director's play scale)
Card: full card 480 units (plate room 450), half card 220 (206 after the scrollbar); zoom = UI scale rounded to whole
(1x below 1.5, 2x from 1.5). The stand-in card is a plain dark panel with a title bar; the game's chrome is Code's."""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import w_check as C                  # noqa: E402  (plates_336 registry, render(), WP)
import w_plates as WP                # noqa: E402
from plates import DESIGNS           # noqa: E402

FD = "/usr/share/fonts/truetype/dejavu/"
BG, CARD, BAR, TXT, DIM = (18, 18, 20, 255), (34, 36, 40, 255), (48, 52, 58, 255), (228, 228, 224, 255), (150, 150, 146, 255)
SCALES = (0.75, 1.0, 1.25, 1.5, 1.75, 2.0)


def zoom_of(s): return 1 if s < 1.5 else 2 if s < 2.5 else 3 if s < 3.5 else 4


def pick(pid, s):
    """the width the game would draw at UI scale s: the widest in the plate's table that fits its card at the whole zoom"""
    W0, ws = WP.widths(pid)
    z = zoom_of(s)
    room = (206 if W0 == 220 else 450) * s           # units of room -> screen px
    fits = [w for w in sorted(set(ws) | {W0}) if w * z <= room + 0.5]
    return (max(fits) if fits else min(ws)), z


def face(pid, W):
    img, p = C.render(pid, WP.WIDE[pid], W)
    return img


def card(pid, s, font):
    W, z = pick(pid, s)
    W0, _ = WP.widths(pid)
    half = W0 == 220
    cw = int(round((220 if half else 480) * s))
    img = face(pid, W)
    fw, fh = img.size[0] * z, img.size[1] * z
    barh = int(round(22 * s))
    pad = int(round(15 * s))
    ch = barh + pad + fh + pad
    c = Image.new("RGBA", (cw, ch), CARD)
    d = ImageDraw.Draw(c)
    d.rectangle((0, 0, cw, barh), fill=BAR)
    d.text((pad, max(2, (barh - 12) // 2)), DESIGNS[pid]["title"], font=font, fill=TXT)
    if half:                                           # the scrollbar's 14 units on the right
        sb = int(round(14 * s)); d.rectangle((cw - sb, barh, cw, ch), fill=BAR)
        room = cw - sb
    else:
        room = cw
    x = (room - fw) // 2
    c.alpha_composite(img.resize((fw, fh), Image.NEAREST), (x, barh + pad))
    d.rectangle((0, 0, cw - 1, ch - 1), outline=(70, 74, 80, 255))
    label = f"UI {s:g}  zoom {z}x  face {W}{' panel' if half else ''} -> {fw} px in {room} px"
    return c, label


def sheet_scales(out, pids):
    f = ImageFont.truetype(FD + "DejaVuSans.ttf", 13)
    fb = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 16)
    cols = []
    for s in SCALES:
        cells = [card(pid, s, f) for pid in pids]
        cols.append((s, cells))
    colw = [max(c.size[0] for c, _ in cells) + 30 for _, cells in cols]
    rowh = [max(cols[j][1][i][0].size[1] for j in range(len(cols))) + 40 for i in range(len(pids))]
    sh = Image.new("RGBA", (sum(colw) + 30, sum(rowh) + 50), BG)
    d = ImageDraw.Draw(sh)
    x = 30
    for (s, cells), cw in zip(cols, colw):
        d.text((x, 12), f"UI scale {s:g}  (zoom {zoom_of(s)}x)", font=fb, fill=TXT)
        y = 50
        for (c, label), rh in zip(cells, rowh):
            sh.alpha_composite(c, (x, y))
            d.text((x, y + c.size[1] + 6), label, font=f, fill=DIM)
            y += rh
        x += cw
    sh.save(out); print("wrote", out, sh.size)


def sheet_at(out, s):
    f = ImageFont.truetype(FD + "DejaVuSans.ttf", 13)
    fb = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 16)
    pids = list(WP.WIDE)
    cells = [card(pid, s, f) for pid in pids]
    ncol = 4
    colw = max(c.size[0] for c, _ in cells) + 30
    rows = [cells[i:i + ncol] for i in range(0, len(cells), ncol)]
    rowh = [max(c.size[1] for c, _ in r) + 44 for r in rows]
    sh = Image.new("RGBA", (ncol * colw + 30, sum(rowh) + 50), BG)
    d = ImageDraw.Draw(sh)
    d.text((30, 12), f"Every plate in its card at UI scale {s:g}, zoom {zoom_of(s)}x (1:1 screen pixels)", font=fb, fill=TXT)
    y = 50
    for r, rh in zip(rows, rowh):
        x = 30
        for c, label in r:
            sh.alpha_composite(c, (x, y))
            d.text((x, y + c.size[1] + 6), label, font=f, fill=DIM)
            x += colw
        y += rh
    sh.save(out); print("wrote", out, sh.size)


if __name__ == "__main__":
    mode, out = sys.argv[1], sys.argv[2]
    if mode == "scales": sheet_scales(out, sys.argv[3:] or ["oven_green", "walkie_army"])
    else: sheet_at(out, float(sys.argv[3]))
