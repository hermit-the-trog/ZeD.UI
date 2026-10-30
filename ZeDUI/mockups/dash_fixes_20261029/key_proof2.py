"""Proof only (writes nothing in the repo): the ignition key in one-point perspective.
The key sticks straight out at the driver, so only the head's edge shows: a thin bar along the slot, turning with it
(OFF vertical, ON 40, START 80). The eye sits at the steering column (VP), so the head's near end slides a few
pixels away from it and the face toward the eye shows as a sliver. The ring hangs from the bow's hole (the middle of
the near edge), straight down in every position; the leather fob hangs from the ring.
usage (from tools/dashpx): py -3.14 C:\\Temp\\key_proof2.py out.png [k]"""
import sys, os, math, copy
sys.path.insert(0, os.getcwd())
import numpy as np
from PIL import Image
import v6
import designs as DZ
from dashlib import Build, Z_FACE

NICKEL = {"wagon", "luxury", "horizon"}
VP = (250.0, 60.0)            # the driver's eye: over the column, level with the cluster
DEPTH_PX = 2.5                # how far the head's near edge slides away from the eye
HALF_L, HALF_T = 8.5, 1.2     # the head's width (seen as the bar's length) and thickness, halves
STEPS = (("off", 0), ("on", 40), ("start", 80))
FOB_L = int(sys.argv[3]) if len(sys.argv) > 3 else 14      # the strap's length below the loop (the key's head is 17)
LIGHT_CABINS = {"v_tan", "v_beige", "v_khaki"}             # on these the fob is dark brown; elsewhere tan


def bar(d, cx, cy, ang, half_l, half_t):
    a = math.radians(ang - 90)                       # 0 = the slot vertical
    ux, uy = math.cos(a), math.sin(a)
    X = d.XX + 0.5 - cx; Y = d.YY + 0.5 - cy
    along = X * ux + Y * uy; across = -X * uy + Y * ux
    return (np.abs(along) <= half_l) & (np.abs(across) <= half_t)


def key_v3(b, cx, cy, style="chrome", angles=STEPS):
    nickel = b.id in NICKEL
    c0x, c0y = cx + 0.5, cy + 0.5
    vx, vy = c0x - VP[0], c0y - VP[1]; n = math.hypot(vx, vy)
    ox, oy = vx / n * DEPTH_PX, vy / n * DEPTH_PX
    for pos, ang in angles:
        def fn(d, ang=ang):
            mat = "alu" if nickel else "blackp"
            body = np.zeros_like(d.solid); hh = np.zeros(d.h.shape, np.float32)
            N = 12
            for i in range(N + 1):                         # the head swept from the lock face to its near edge
                t = i / N
                m = bar(d, c0x + ox * t, c0y + oy * t, ang, HALF_L, HALF_T)
                body |= m; hh[m] = np.maximum(hh[m], Z_FACE + 1.0 + 7.0 * t)
            d.h[body] = hh[body]; d.mat[body] = d.mid(mat); d.solid |= body
            d.polish[body] = 1.0 if nickel else 0.85; d.tex[body] = 0
            edge = bar(d, c0x + ox, c0y + oy, ang, HALF_L, HALF_T)      # the near edge: the brightest line
            d.tex[edge] += 0.35 if nickel else 0.45
            side = body & ~edge
            d.dark[side] = np.maximum(d.dark[side], 0.25)
            hx, hy = c0x + ox, c0y + oy                                 # the bow's hole: the middle of the near edge
            rcx, rcy = hx, hy + 3.2
            rr = np.hypot(d.XX + 0.5 - rcx, d.YY + 0.5 - rcy)
            ring = (rr >= 2.6) & (rr <= 3.6) & ~(edge & (d.YY + 0.5 < hy + 0.5))
            d.h[ring] = Z_FACE + 9.5; d.mat[ring] = d.mid("chrome"); d.solid |= ring; d.polish[ring] = 1.0; d.tex[ring] = 0
            # the leather fob, longer than the key's head: a folded loop through a clip, a rivet, a stitched strap
            fx, fy = int(round(rcx - 3.5)), int(round(rcy + 3.6))
            clip = d.M().rrect(fx + 2, fy, 3, 2, 0).get()
            d.h[clip] = Z_FACE + 8.5; d.mat[clip] = d.mid("chrome"); d.solid |= clip; d.polish[clip] = 1.0; d.tex[clip] = 0
            leather = "v_cocoa" if b.cabin in LIGHT_CABINS else "v_tan"   # the fob stands off the vinyl behind it
            loop = d.M().rrect(fx + 1, fy + 2, 5, 3, 1).get()
            d.slab(loop, 4.5, leather, bevel=0.8, polish=0.35, on=Z_FACE + 0.5)
            d.dark[loop] = np.maximum(d.dark[loop], 0.3)
            body = d.M().rrect(fx, fy + 4, 7, FOB_L, 3).get()
            d.slab(body, 4.0, leather, bevel=1.2, polish=0.35, on=Z_FACE + 0.5)
            rivet = (d.XX == fx + 3) & (d.YY == fy + 5)
            d.h[rivet] += 0.6; d.mat[rivet] = d.mid("chrome"); d.polish[rivet] = 1.0; d.tex[rivet] = 0
            inner = d.M().rrect(fx + 1, fy + 5, 5, FOB_L - 2, 2).get()
            ring_px = body & ~d.M().rrect(fx + 2, fy + 6, 3, FOB_L - 4, 1).get() & inner
            stitch = ring_px & (((d.XX + d.YY) % 2) == 0) & ~rivet
            d.tex[stitch] += 0.45
        b.variant(f"key_{pos}_{b.id}", "keyPos", fn, pos)


v6.key_turn_variants = key_v3
k = int(sys.argv[2]) if len(sys.argv) > 2 else 4
rows = []
for did in ("wagon", "luxury", "d6", "van", "police", "dashelite", "primani", "cossette"):
    title, cabin, seed, fn, *_ = DZ.DESIGNS[did]
    b = Build(did, cabin, seed=seed, title=title); fn(b)
    hit = [h for h in b.hits if h["id"] == "ignition"][0]
    cx, cy = hit["x"] + hit["w"] // 2, hit["y"] + hit["h"] // 2
    if did not in NICKEL:
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
