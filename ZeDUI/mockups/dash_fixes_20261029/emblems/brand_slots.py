"""Proof helper (writes nothing in the repo): build each dash with its console plaques taken away, measure the clear
flat field round where the plaque was, and render the consoles so the empty slots can be seen.
usage (from tools/dashpx): py -3.14 C:\\Temp\\brand_slots.py out.png"""
import sys, os, json, copy
sys.path.insert(0, os.getcwd())
import numpy as np
from PIL import Image, ImageDraw
import dashlib
import designs as DZ

REMOVED = {}


def no_plaque(b, x, y, w, h, style="flat", role="label", font="35", scale=1, color="#d8dade", plate=None, align="c",
              shadow=None, check=True):
    """the generic plaque and its live name, left out on the console; recorded so the brand can take the spot"""
    if x >= 494 and role in ("make", "model", "full", "sub"):
        REMOVED.setdefault(b.id, []).append(dict(role=role, x=x, y=y, w=w, h=h, plate=plate, style=style, font=font))
        return
    return ORIG(b, x, y, w, h, style=style, role=role, font=font, scale=scale, color=color, plate=plate, align=align,
                shadow=shadow, check=check)


ORIG = dashlib.badge
dashlib.badge = no_plaque; DZ.badge = no_plaque


def clear_field(d, cx, cy, tol=0.8):
    """the largest rectangle round (cx, cy) on the one flat surface found there"""
    m0, h0 = d.mat[cy, cx], d.h[cy, cx]
    ok = (d.mat == m0) & (np.abs(d.h - h0) <= tol) & d.solid
    x0 = x1 = cx; y0 = y1 = cy
    grew = True
    while grew:
        grew = False
        for side in ("l", "r", "u", "d"):
            if side == "l" and x0 > 0 and ok[y0:y1 + 1, x0 - 1].all(): x0 -= 1; grew = True
            if side == "r" and x1 < d.W - 1 and ok[y0:y1 + 1, x1 + 1].all(): x1 += 1; grew = True
            if side == "u" and y0 > 0 and ok[y0 - 1, x0:x1 + 1].all(): y0 -= 1; grew = True
            if side == "d" and y1 < d.H - 1 and ok[y1 + 1, x0:x1 + 1].all(): y1 += 1; grew = True
    return x0, y0, x1 - x0 + 1, y1 - y0 + 1


if __name__ == "__main__":
    shots, report = [], {}
    for did in DZ.ORDER:
        if did in ("race",): continue
        title, cabin, seed, fn, *_ = DZ.DESIGNS[did]
        b = dashlib.Build(did, cabin, seed=seed, title=title); fn(b)
        rem = REMOVED.get(did, [])
        if not rem: continue
        xs = [r["x"] for r in rem] + [r["x"] + r["w"] for r in rem]; ys = [r["y"] for r in rem] + [r["y"] + r["h"] for r in rem]
        cx, cy = int((min(xs) + max(xs)) / 2), int((min(ys) + max(ys)) / 2)
        f = clear_field(b.d, cx, cy)
        report[did] = dict(title=title, cabin=cabin, removed=rem, centre=(cx, cy), field=f)
        print(f"{did:10s} {title:28s} field x{f[0]} y{f[1]} {f[2]}x{f[3]}  centre {cx},{cy}  removed {[r['role'] for r in rem]}")
        img = b.d.render().convert("RGBA")
        dr = ImageDraw.Draw(img)
        dr.rectangle([f[0], f[1], f[0] + f[2] - 1, f[1] + f[3] - 1], outline=(255, 0, 255, 255))
        shots.append(img.crop((494, 0, 800, 110)))
    json.dump(report, open(r"C:\Temp\brand_slots.json", "w"), indent=1)
    w, h = shots[0].size
    cols = 3; rows = (len(shots) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * (w + 6), rows * (h + 6)), (0, 0, 0, 255))
    for i, s in enumerate(shots): sheet.paste(s, ((i % cols) * (w + 6), (i // cols) * (h + 6)))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(sys.argv[1])
