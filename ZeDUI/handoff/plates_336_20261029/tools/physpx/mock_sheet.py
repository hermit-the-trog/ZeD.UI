"""MOCKUP sheets: today's plate beside its 336 px re-layout, same preview state, 2x, with the 336 limit marked.
usage: python mock_sheet.py out.png "Title" pid[:state] ..."""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from physlib import build
import preview as PV
from plates import DESIGNS
import m_ovens as MO

MOCK = {"oven_green": MO.green_range, "oven_red": MO.red_range, "oven_grey": MO.grey_range,
        "oven_modern": MO.modern_range, "oven_industrial": MO.industrial_range, "oven_large": MO.convection_oven,
        "fryer": MO.fryer}
try:
    import m_more as MM
    MOCK.update(MM.MOCK)
except ImportError:
    pass
import m_ham as MH
MOCK.update(MH.MOCK)

FD = "/usr/share/fonts/truetype/dejavu/"
F_T = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 28)
F_H = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 18)
F_S = ImageFont.truetype(FD + "DejaVuSans.ttf", 14)
BG, AMBER, TXT, DIM, LIM = (23, 23, 25, 255), (255, 214, 120, 255), (230, 230, 226, 255), (150, 150, 146, 255), (255, 80, 60, 255)
WARN = {}


def render(pid, fn, si=None):
    D = DESIGNS[pid]
    p, base, sprites = build(fn, D["variants"], **D.get("base", {}))
    if D.get("post"): D["post"](p)
    WARN[(pid, fn is D["fn"])] = list(p.warnings)
    st = D["states"][si if si is not None else -1]
    return PV.render_state(base, p.parts, sprites, st), p


def sheet(name, title, items, k=2, gap=28):
    rows = []
    for it in items:
        pid, _, si = it.partition(":")
        si = int(si) if si else None
        old, _ = render(pid, DESIGNS[pid]["fn"], si)
        new, p = render(pid, MOCK[pid], si)
        rows.append((pid, DESIGNS[pid]["title"], old, new, p))
    cw = max(r[2].width for r in rows) * k
    nw = 336 * k
    W = gap + cw + gap * 2 + nw + gap
    H = 90 + sum(max(r[2].height, r[3].height) * k + 64 for r in rows)
    s = Image.new("RGBA", (W, H), BG); dr = ImageDraw.Draw(s)
    dr.text((gap, 20), title, font=F_T, fill=TXT)
    dr.text((gap, 58), "TODAY", font=F_S, fill=DIM)
    dr.text((gap * 3 + cw, 58), "336 PX MAIN FACE (mockup)", font=F_S, fill=AMBER)
    y = 90
    for pid, t, old, new, p in rows:
        dr.text((gap, y), t, font=F_H, fill=AMBER)
        dr.text((gap + dr.textlength(t, font=F_H) + 12, y + 3), f"{old.width}x{old.height}  ->  {new.width}x{new.height}",
                font=F_S, fill=DIM)
        s.alpha_composite(PV.scale(old, k), (gap, y + 28))
        nx = gap * 3 + cw
        s.alpha_composite(PV.scale(new, k), (nx, y + 28))
        rh = max(old.height, new.height) * k
        dr.line([(nx + nw, y + 24), (nx + nw, y + 28 + rh)], fill=LIM, width=1)
        y += rh + 64
    s.save(name)
    for (pid, isold), w in WARN.items():
        if w and not isold:
            print("NEW", pid, *w, sep="\n   ")


if __name__ == "__main__":
    sheet(sys.argv[1], sys.argv[2], sys.argv[3:])
