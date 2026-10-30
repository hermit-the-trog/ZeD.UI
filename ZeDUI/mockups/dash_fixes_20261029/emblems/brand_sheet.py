"""The five lockups on three cabin finishes (dark vinyl, tan vinyl, walnut), 1x, then 2x and 4x.
usage (from tools/dashpx): py -3.14 C:\\Temp\\brand_sheet.py out_prefix"""
import sys, os
sys.path.insert(0, os.getcwd()); sys.path.insert(0, r"C:\Temp")
import numpy as np
from PIL import Image
from engine import Dash
import brand as B

ITEMS = [("chevalier", "D6"), ("dash", "BULLDRIVER V8"), ("franklin", "VALULINE"), ("mercia", "LANG 4000"), ("masterson", "HORIZON")]
FINISH = ["v_charcoal", "v_tan", "walnut"]
GAP, PAD = 14, 8
sizes = [B.size(b, m) for b, m in ITEMS]
W = PAD * 2 + sum(w for w, h in sizes) + GAP * (len(ITEMS) - 1)
RH = max(h for w, h in sizes) + 12
H = PAD * 2 + RH * len(FINISH)
d = Dash(W, H, seed=4); B.use(d)
BASE = 5.0
for r, fin in enumerate(FINISH):
    band = (d.YY >= PAD + r * RH - 4) & (d.YY < PAD + (r + 1) * RH - 4)
    d.slab(band, BASE, fin, bevel=0.1, polish=0.15, on=0.0)
for r, fin in enumerate(FINISH):
    x = PAD
    for (b, m), (w, h) in zip(ITEMS, sizes):
        B.draw(b, x, PAD + r * RH + (RH - 12 - h) // 2, m, "h", base=BASE)
        x += w + GAP
img = d.render().convert("RGBA")
pre = sys.argv[1]
img.save(pre + "_1x.png")
for k in (2, 4): img.resize((W * k, H * k), Image.NEAREST).save(pre + f"_{k}x.png")
print(W, H, sizes)
