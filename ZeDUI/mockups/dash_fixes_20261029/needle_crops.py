"""Read-only: crops of one design's gauges with its needles drawn at several readings; pixels off the dial face in magenta.
usage (from tools/dashpx): py -3.14 C:\\Temp\\needle_crops.py <design> <src> x0 y0 x1 y1 out.png"""
import sys, os
sys.path.insert(0, os.getcwd())
import numpy as np
from PIL import Image
from dashlib import Build, PRINTED
from live import needle_pixels
import designs as DZ

did, src = sys.argv[1], sys.argv[2]
x0, y0, x1, y1 = map(int, sys.argv[3:7]); outp = sys.argv[7]
title, cabin, seed, fn, *_ = DZ.DESIGNS[did]
b = Build(did, cabin, seed=seed, title=title); fn(b)
plate = np.array(b.d.render().convert("RGBA"))
n = [p for p in b.parts if p["t"] == "needle" and p["src"] == src][0]
tiles = []
for f in (0.0, 0.25, 0.45, 0.55, 0.75, 1.0):
    im = plate.copy()
    a = n["a0"] + (n["a1"] - n["a0"]) * f
    body, edge = needle_pixels(n["cx"], n["cy"], a, n["r0"], n["r1"], n.get("w", 2), n.get("hub", 0) or 0)
    bad = 0
    for (x, y) in body | edge:
        m = b.d.mat[y, x]; nm = b.d.names[m] if m >= 0 else "none"
        ok = nm == "face" or nm in PRINTED
        im[y, x] = (255, 106, 26, 255) if ok else (255, 0, 255, 255)
        bad += not ok
    print(f"{src} at {f * n['max']:.0f}: {bad} px off the face")
    tiles.append(im[y0:y1, x0:x1])
sheet = np.concatenate([np.concatenate(tiles[:3], axis=1), np.concatenate(tiles[3:], axis=1)], axis=0)
Image.fromarray(sheet).resize((sheet.shape[1] * 3, sheet.shape[0] * 3), Image.NEAREST).save(outp)
