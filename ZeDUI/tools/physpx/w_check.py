"""Checks the parametric plates: at W=336 each must match the approved 336 face (m_*), and at every width the
click areas and live parts must be the same set (ids, kinds, needs, sources) with the same sizes. Prints a table and
writes a sheet of every plate at the four widths (2x) with the 336 difference count.
usage: python w_check.py out.png [pid ...]"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import plates_336  # noqa: F401,E402  (the registry with the 336 faces as "today")
from plates import DESIGNS  # noqa: E402
from physlib import build  # noqa: E402
import preview as PV  # noqa: E402
import w_plates as WP  # noqa: E402

WIDTHS = (336, 392, 450, 562)
FD = "/usr/share/fonts/truetype/dejavu/"
F_H = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 18)
F_S = ImageFont.truetype(FD + "DejaVuSans.ttf", 13)
BG, TXT, DIM, BAD, OK = (23, 23, 25, 255), (230, 230, 226, 255), (150, 150, 146, 255), (255, 80, 60, 255), (120, 220, 120, 255)


def render(pid, fn, W=None, si=None):
    D = DESIGNS[pid]
    kw = dict(D.get("base", {}))
    if W is not None: kw["W"] = W
    p, base, sprites = build(fn, D["variants"], **kw)
    if D.get("post"): D["post"](p)
    st = D["states"][si if si is not None else -1]
    return PV.render_state(base, p.parts, sprites, st), p


def sig(p):
    """what must not change between widths: each click area's id, kind, needs and size; each part's type, source and
    size-ish fields (not positions)"""
    # a click area may grow with the layout (a wide pad spanning two slots), never shrink below 10 x 10
    hits = sorted((h["id"], h.get("kind", "press"), h.get("needs"), h["w"] >= 10 and h["h"] >= 10) for h in p.hits)
    def keep(q, k):
        if k in ("x", "y", "cx", "cy", "sprite", "runs", "halo", "bars", "fields"): return False   # pixel positions
        if k in ("w", "h") and q["t"] in ("sprite", "radioDisplay"): return False   # a sprite's rect and a display's width follow the layout
        return True
    parts = sorted(tuple(sorted((k, str(v)) for k, v in q.items() if keep(q, k))) for q in p.parts)
    return hits, parts


def main(out, only=None):
    pids = only or list(WP.WIDE)
    rows = []
    for pid in pids:
        ref, pref = render(pid, DESIGNS[pid]["fn"])
        cells = []
        W0, ws = WP.widths(pid)
        for W in (W0,) + tuple(w for w in ws if w != W0):
            img, p = render(pid, WP.WIDE[pid], W)
            note = ""
            if W == W0:
                a, b = np.asarray(ref.convert("RGBA")).astype(int), np.asarray(img.convert("RGBA")).astype(int)
                ndiff = -1 if a.shape != b.shape else int((np.abs(a - b).sum(axis=2) > 0).sum())
                note = f"{W0} diff: {ndiff} px" + ("" if a.shape == b.shape else f" (size {img.size} vs {ref.size})")
                same_sig = sig(p) == sig(pref)
            else:
                same_sig = sig(p) == sig(pref)
            if p.W != (W - 20 if W0 == 220 else W): note += f" WIDTH {p.W}!"
            if p.warnings: note += " " + "; ".join(p.warnings)
            cells.append((W, img, note, same_sig, len(p.hits), len(p.parts)))
            print(f"{pid:16s} {W}: {img.size[0]}x{img.size[1]}  hits {len(p.hits)} parts {len(p.parts)}  sig {'same' if same_sig else 'DIFFERENT'}  {note}")
        rows.append((pid, cells))
    # the sheet: one row per plate, the four widths across, 2x
    k = 2
    ncol = max(len(cells) for _, cells in rows)
    colw = [max(cells[i][1].size[0] for _, cells in rows if i < len(cells)) * k + 24 for i in range(ncol)]
    rowh = [max(c[1].size[1] for c in cells) * k + 56 for _, cells in rows]
    sheet = Image.new("RGBA", (sum(colw) + 24, sum(rowh) + 40), BG)
    dr = ImageDraw.Draw(sheet)
    x = 24
    for i, cw in enumerate(colw):
        dr.text((x, 10), " / ".join(sorted({str(cells[i][0]) for _, cells in rows if i < len(cells)})) + " px", font=F_H, fill=TXT); x += cw
    y = 40
    for (pid, cells), rh in zip(rows, rowh):
        x = 24
        for (W, img, note, same_sig, nh, npart), cw in zip(cells, colw):
            big = img.resize((img.size[0] * k, img.size[1] * k), Image.NEAREST)
            sheet.alpha_composite(big, (x, y + 24))
            dr.text((x, y + 4), f"{pid}  {nh} hits {npart} parts", font=F_S, fill=DIM)
            if note: dr.text((x, y + 24 + big.size[1] + 4), note, font=F_S, fill=OK if "diff: 0 px" in note else BAD)
            if not same_sig: dr.text((x + 300, y + 4), "parts/hits differ", font=F_S, fill=BAD)
            x += cw
        y += rh
    sheet.save(out)
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:] or None)
