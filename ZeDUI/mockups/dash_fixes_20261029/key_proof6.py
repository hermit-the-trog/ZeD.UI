"""Proof only (writes nothing in the repo): the one-point key with a teardrop leather fob, after the director's references.
The fob is its own sprite (like the hula girl), so it may hang past the dash's bottom edge.
A: the biggest teardrop that stays inside the dash.  B: reference proportions, hanging past the edge.
usage (from tools/dashpx): py -3.14 C:\\Temp\\key_proof3.py out.png [k]"""
import sys, os, math, copy
sys.path.insert(0, os.getcwd()); sys.path.insert(0, r'C:\Temp\proofmods')
import numpy as np
from PIL import Image
import dashlib
import v6
import designs as DZ
from dashlib import Build, Z_FACE, H as PLATE_H
from engine import Dash

NICKEL = {"wagon", "luxury", "horizon"}
LIGHT_CABINS = {"v_tan", "v_beige", "v_khaki"}
VP = (250.0, 60.0); DEPTH_PX = 2.5; HALF_L, HALF_T = 8.5, 1.2
STEPS = (("off", 0), ("on", 40), ("start", 80))
RING_R0, RING_R1 = 3.6, 4.6          # a 10 px ring: in the references the ring is about as wide as a key's head
PAD = 22                             # preview room below the dash for B


def bar(d, cx, cy, ang, half_l, half_t):
    a = math.radians(ang - 90); ux, uy = math.cos(a), math.sin(a)
    X = d.XX + 0.5 - cx; Y = d.YY + 0.5 - cy
    return (np.abs(X * ux + Y * uy) <= half_l) & (np.abs(-X * uy + Y * ux) <= half_t)


def hang_point(cx, cy):
    c0x, c0y = cx + 0.5, cy + 0.5
    vx, vy = c0x - VP[0], c0y - VP[1]; n = math.hypot(vx, vy)
    return c0x + vx / n * DEPTH_PX, c0y + vy / n * DEPTH_PX


def key_v4(b, cx, cy, style="chrome", angles=STEPS):
    nickel = b.id in NICKEL
    c0x, c0y = cx + 0.5, cy + 0.5
    hx, hy = hang_point(cx, cy); ox, oy = hx - c0x, hy - c0y
    for pos, ang in angles:
        def fn(d, ang=ang):
            body = np.zeros_like(d.solid); hh = np.zeros(d.h.shape, np.float32)
            for i in range(13):
                t = i / 12
                m = bar(d, c0x + ox * t, c0y + oy * t, ang, HALF_L, HALF_T)
                body |= m; hh[m] = np.maximum(hh[m], Z_FACE + 1.0 + 7.0 * t)
            d.h[body] = hh[body]; d.mat[body] = d.mid("alu" if nickel else "blackp"); d.solid |= body
            d.polish[body] = 1.0 if nickel else 0.85; d.tex[body] = 0
            edge = bar(d, hx, hy, ang, HALF_L, HALF_T)
            d.tex[edge] += 0.35 if nickel else 0.45
            d.dark[body & ~edge] = np.maximum(d.dark[body & ~edge], 0.25)
            rcx, rcy = hx, hy + RING_R0 + 0.4
            rr = np.hypot(d.XX + 0.5 - rcx, d.YY + 0.5 - rcy)
            ring = (rr >= RING_R0) & (rr <= RING_R1) & ~(edge & (d.YY + 0.5 < hy + 0.5))
            d.h[ring] = Z_FACE + 9.5; d.mat[ring] = d.mid("chrome"); d.solid |= ring; d.polish[ring] = 1.0; d.tex[ring] = 0
        b.variant(f"key_{pos}_{b.id}", "keyPos", fn, pos)


def fob_sprite(width, body_len, leather):
    """a teardrop fob, face on: a narrow tab folded over the ring and held by a snap, the body widening to a round
    bottom, stitched a pixel inside its edge. Returns the sprite and the x of its centre line."""
    W_, H_ = width + 4, body_len + 10
    d = Dash(W_, H_, seed=5)
    cx = W_ / 2.0
    tab_w, tab_h = max(4, round(width * 0.4)), 6
    r = width / 2.0
    bcy = H_ - 2 - r                                     # the round bottom's centre
    top = 3                                              # where the body starts, under the tab
    X = d.XX + 0.5 - cx; Y = d.YY + 0.5
    # the teardrop: straight flanks from the tab's width at the top to the full circle
    t = np.clip((Y - top) / max(1.0, bcy - top), 0, 1)
    half = tab_w / 2.0 + (r - tab_w / 2.0) * t ** 0.4
    drop = ((Y >= top) & (Y <= bcy) & (np.abs(X) <= half)) | (np.hypot(X, Y - bcy) <= r)
    d.slab(drop, 3.0, leather, bevel=1.4, polish=0.35, on=0.0)
    # stitching: dotted, a pixel and a half inside the edge, below the tab
    ins = ((Y >= top + 1.5) & (Y <= bcy) & (np.abs(X) <= half - 1.6)) | (np.hypot(X, Y - bcy) <= r - 1.6)
    ins2 = ((Y >= top + 2.5) & (Y <= bcy) & (np.abs(X) <= half - 2.6)) | (np.hypot(X, Y - bcy) <= r - 2.6)
    stitch = ins & ~ins2 & (Y >= top + tab_h) & (((d.XX + d.YY) % 2) == 0)
    d.tex[stitch] += 0.5
    # the tab folded over the ring: it lies on top of the body, a shade darker at its fold, with a snap
    tab = (np.abs(X) <= tab_w / 2.0) & (Y >= 0) & (Y <= top + tab_h)
    tab_round = tab & ~((Y > top + tab_h - 1.5) & (np.abs(X) > tab_w / 2.0 - 1.0))
    d.slab(tab_round, 4.5, leather, bevel=1.0, polish=0.35, on=0.0)
    d.dark[tab_round & (Y <= 1.5)] = 0.4
    snap = np.hypot(X, Y - (top + tab_h - 3.0)) <= 1.3
    d.h[snap] = 6.0; d.mat[snap] = d.mid("chrome"); d.polish[snap] = 1.0; d.tex[snap] = 0; d.solid |= snap
    return d.render(), cx


def composite(img, spr, x, y):
    a = np.array(spr)
    sh = Image.fromarray(np.dstack([np.zeros_like(a[..., :3]), (a[..., 3] * 0.45).astype(np.uint8)]), "RGBA")
    img.alpha_composite(sh, (int(x) + 1, int(y) + 2)); img.alpha_composite(spr, (int(x), int(y)))



# ---- full dashes on the taller plate (the dash meets the screen's bottom edge), key at OFF, the big teardrop fob
v6.key_turn_variants = key_v4
k = int(sys.argv[2]) if len(sys.argv) > 2 else 2
print("plate height", PLATE_H)
shots = []
for did in ("wagon", "d6", "dashelite", "cossette", "police"):
    title, cabin, seed, fn, *_ = DZ.DESIGNS[did]
    b = Build(did, cabin, seed=seed, title=title); fn(b)
    if b.warnings: print(did, "WARN", b.warnings)
    hit = [h for h in b.hits if h["id"] == "ignition"][0]
    cx, cy = hit["x"] + hit["w"] // 2, hit["y"] + hit["h"] // 2
    if did not in NICKEL:
        d = b.d
        ig = (np.hypot(d.XX + 0.5 - (cx + 0.5), d.YY + 0.5 - (cy + 0.5)) < 6.5) & (d.mat == d.mid("blackp"))
        d.mat[ig] = d.mid("alu"); d.polish[ig] = 0.8
    leather = "v_cocoa" if cabin in LIGHT_CABINS else "v_tan"
    hx, hy = hang_point(cx, cy)
    fy = hy + RING_R0 + 0.4 + RING_R1 - 1.5
    spr, sc = fob_sprite(15, 20, leather)
    off = [v for v in b.variants if v[0] == f"key_off_{did}"][0]
    d2 = copy.deepcopy(b.d); off[2](d2)
    img = d2.render().convert("RGBA")
    composite(img, spr, hx - sc, fy)
    bottom = fy + spr.height
    print(f"{did}: fob bottom at y {bottom:.0f} of {PLATE_H}")
    shots.append(img)
W = shots[0].width; Hh = sum(s.height + 6 for s in shots)
sheet = Image.new("RGBA", (W, Hh), (0, 0, 0, 255)); y = 0
for s in shots: sheet.paste(s, (0, y)); y += s.height + 6
sheet.resize((W * k, Hh * k), Image.NEAREST).save(sys.argv[1])

