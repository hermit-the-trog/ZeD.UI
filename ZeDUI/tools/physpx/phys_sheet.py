"""Progress sheets: a grid of plates (one chosen preview state each) at 2x with titles.
usage: python phys_sheet.py out_name.png "Title" id[:state_index] ...  (state index defaults to the last)"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from physlib import build
import preview as PV
from plates import DESIGNS

FD = "/usr/share/fonts/truetype/dejavu/"
F_T = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 28)
F_H = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 18)
F_S = ImageFont.truetype(FD + "DejaVuSans.ttf", 14)
BG, AMBER, TXT, DIM = (23, 23, 25, 255), (255, 214, 120, 255), (230, 230, 226, 255), (150, 150, 146, 255)


def render(pid, si=None):
    D = DESIGNS[pid]
    p, base, sprites = build(D["fn"], D["variants"], **D.get("base", {}))
    if D.get("post"): D["post"](p)
    for w in p.warnings: print("  !", pid, w)
    st = D["states"][si if si is not None else -1]
    return PV.render_state(base, p.parts, sprites, st), D


def sheet(name, title, items, cols=2, k=2, gap=24, note=None):
    cells = []
    for it in items:
        pid, _, si = it.partition(":")
        img, D = render(pid, int(si) if si else None)
        cells.append((img, D["title"], D["uses"]))
    cw = max(im.width for im, _, _ in cells) * k
    rows = (len(cells) + cols - 1) // cols
    rh = [max(im.height for im, _, _ in cells[r * cols:(r + 1) * cols]) * k + 56 for r in range(rows)]
    W = cols * cw + (cols + 1) * gap
    H = 70 + sum(rh) + (40 if note else 0)
    s = Image.new("RGBA", (W, H), BG); dr = ImageDraw.Draw(s)
    dr.text((gap, 20), title, font=F_T, fill=TXT)
    y = 70
    for r in range(rows):
        x = gap
        for im, t, uses in cells[r * cols:(r + 1) * cols]:
            dr.text((x, y), t, font=F_H, fill=AMBER)
            dr.text((x + dr.textlength(t, font=F_H) + 12, y + 3), uses, font=F_S, fill=DIM)
            s.alpha_composite(PV.scale(im, k), (x, y + 28))
            x += cw + gap
        y += rh[r]
    if note: dr.text((gap, y + 6), note, font=F_S, fill=DIM)
    out = os.path.join(HERE, "out", name)
    s.convert("RGB").save(out)
    print(out, s.size)
    return out


if __name__ == "__main__":
    sheet(sys.argv[1], sys.argv[2], sys.argv[3:])
