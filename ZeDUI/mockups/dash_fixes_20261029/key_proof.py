"""Proof only (writes nothing in the repo): the reworked ignition key.
A slim paddle head out of the slot (black on the late cars, nickel on the wood-and-chrome ones), its bow hanging
down at OFF and turning clockwise; an open ring through the bow; a leather fob on a clip under the ring.
usage (from tools/dashpx): py -3.14 C:\\Temp\\key_proof.py out.png [k]"""
import sys, os, math, copy
sys.path.insert(0, os.getcwd())
import numpy as np
from PIL import Image
import v6
import designs as DZ
from dashlib import Build, Z_FACE

NICKEL = {"wagon", "luxury", "horizon"}           # the wood-and-chrome family: an all-metal key
BASE, STEPS = 180, (("off", 0), ("on", 45), ("start", 85))   # head hangs down at OFF, turns clockwise
HEAD = [(-1.5, 1.5), (1.5, 1.5), (1.5, -3.0), (3.5, -5.0), (3.5, -12.5), (2, -14), (-2, -14), (-3.5, -12.5), (-3.5, -5.0), (-1.5, -3.0)]
HOLE_Y = -11.3


def key_v2(b, cx, cy, style="chrome", angles=STEPS):
    nickel = b.id in NICKEL
    for pos, da in angles:
        def fn(d, ang=BASE + da):
            R = v6._rot
            head = d.M().poly(R(cx, cy, ang, HEAD)).get()
            edge = head & ~np.roll(head, 1, 0) | head & ~np.roll(head, -1, 0) | head & ~np.roll(head, 1, 1) | head & ~np.roll(head, -1, 1)
            if nickel:
                d.slab(head, 6.0, "alu", bevel=1.2, polish=1.0, on=Z_FACE + 1)
                d.dark[edge] = np.maximum(d.dark[edge], 0.45)              # a dark rim so metal reads against chrome
            else:
                d.slab(head, 6.0, "blackp", bevel=1.4, polish=0.9, on=Z_FACE + 1)     # glossy black plastic
                d.tex[edge] += 0.3                                          # a lit rim so black reads against black
            (hx, hy), = R(cx, cy, ang, [(0, HOLE_Y)]); hx += 0.5; hy += 0.5
            hole = np.hypot(d.XX + 0.5 - hx, d.YY + 0.5 - hy) < 1.15
            d.h[hole] -= 4; d.dark[hole] = 0.7
            rcx, rcy = hx, hy + 2.8                                          # the ring hangs from the bow, straight down
            rr = np.hypot(d.XX + 0.5 - rcx, d.YY + 0.5 - rcy)
            ring = (rr >= 2.6) & (rr <= 3.6) & ~hole
            d.h[ring] = Z_FACE + 9.0; d.mat[ring] = d.mid("chrome"); d.solid |= ring; d.polish[ring] = 1.0; d.tex[ring] = 0
            fx, fy = int(round(rcx - 2.5)), int(round(rcy + 3.6))
            clip = d.M().rrect(fx + 1, fy, 3, 2, 0).get()
            d.h[clip] = Z_FACE + 8.0; d.mat[clip] = d.mid("chrome"); d.solid |= clip; d.polish[clip] = 1.0; d.tex[clip] = 0
            strap = d.M().rrect(fx, fy + 2, 5, 7, 2).get()                  # the leather fob, round-bottomed
            d.slab(strap, 4.0, "v_tan", bevel=1.0, polish=0.35, on=Z_FACE + 0.5)
            fold = strap & (d.YY == fy + 3)
            d.dark[fold] = np.maximum(d.dark[fold], 0.35)
            stitch = strap & (d.YY >= fy + 5) & (d.YY <= fy + 7) & (d.XX == fx + 2) & ((d.YY % 2) == 0)
            d.tex[stitch] += 0.25
        b.variant(f"key_{pos}_{b.id}", "keyPos", fn, pos)


v6.key_turn_variants = key_v2
k = int(sys.argv[2]) if len(sys.argv) > 2 else 6
rows = []
for did in ("wagon", "luxury", "d6", "van", "police", "dashelite", "primani", "cossette"):
    title, cabin, seed, fn, *_ = DZ.DESIGNS[did]
    b = Build(did, cabin, seed=seed, title=title); fn(b)
    hit = [h for h in b.hits if h["id"] == "ignition"][0]
    cx, cy = hit["x"] + hit["w"] // 2, hit["y"] + hit["h"] // 2
    if did not in NICKEL:          # a black key wants a bright cylinder: the lock's face goes nickel
        d = b.d
        ig = (np.hypot(d.XX + 0.5 - (cx + 0.5), d.YY + 0.5 - (cy + 0.5)) < 6.5) & (d.mat == d.mid("blackp"))
        d.mat[ig] = d.mid("alu"); d.polish[ig] = 0.8
    box_ = (cx - 34, cy - 21, cx + 40, min(172, cy + 32))
    tiles = []
    for name, src, vfn, when in b.variants:
        if not name.startswith("key_"): continue
        d2 = copy.deepcopy(b.d); vfn(d2)
        tiles.append(d2.render().convert("RGBA").crop(box_))
    if b.warnings: print(did, b.warnings)
    w, h = tiles[0].size
    row = Image.new("RGBA", (w * 3 + 8, h), (20, 20, 20, 255))
    for i, t in enumerate(tiles): row.paste(t, (i * (w + 4), 0))
    rows.append(row)
W = max(r.width for r in rows); H = sum(r.height + 4 for r in rows)
sheet = Image.new("RGBA", (W, H), (20, 20, 20, 255)); y = 0
for r in rows: sheet.paste(r, (0, y)); y += r.height + 4
sheet.resize((W * k, H * k), Image.NEAREST).save(sys.argv[1])
sheet.save(sys.argv[1].replace(".png", "_1x.png"))
print(sheet.size)
