"""The belt's slots on their own attachment materials (director, Oct 16 2026: "quick look you can see what is attached
to what"): each hotbar slot sits on a run of whatever provides it in vanilla. The waist belt stays the leather strap
(d_belt.py) and carries the buckle; the others:

  rope      the rope belt (RopeBelt), crafted frame packs' bedroll lashing
  webbing   ALICE belt and suspenders (olive, green, woodland camo), ALICE packs' bedroll straps
  harness   the breathing pack (SCBA): black nylon with a reflective band
  pack      hiking and survivor packs' bedroll straps, the back slot with a bag on: a padded nylon strap
  sling     the back slot with no bag: a canvas sling
  holster   holsters by their item: brown or black leather, green nylon, duct tape, hide

Each is a height field lit from the top left like the plates, 30 rows tall (the material itself may be narrower and
sits centred), exported as a left end, a 64-pixel middle that repeats without a seam, and a right end."""
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

from physlib import *            # noqa: F401,F403
from engine import add_ramp

H, TILE, END = 30, 64, 8

add_ramp("rope_tan", "#b88d52", light=1.08)     # jute (director's reference, Oct 16 2026)
add_ramp("jute_hair", "#d8b67c", light=1.05)
add_ramp("web_olive", "#5a5c38")
add_ramp("web_green", "#3f5232")
# woodland camo (Oct 16 2026, director: stronger, so it reads as camo and not olive): green ground, brown, black, khaki
add_ramp("camo_a", "#4d5a34"); add_ramp("camo_b", "#1f211a"); add_ramp("camo_c", "#6e5232"); add_ramp("camo_d", "#9a9466", light=1.05)
add_ramp("harness_black", "#202124")
add_ramp("reflect", "#c8c86a", light=1.15)
add_ramp("pack_nylon", "#33373c")
add_ramp("pack_bind", "#1f2226")
add_ramp("canvas_khaki", "#8a7a52", light=1.05)
add_ramp("holster_brown", "#5e3420")
add_ramp("holster_black", "#1e1c1b")
add_ramp("tape_grey", "#9a9da0", light=1.2)
add_ramp("hide_tan", "#a98b62", light=1.05)
add_ramp("hide_spot", "#6e5236")
add_ramp("belt_leather", "#56391f")

# material: (ramp, thickness in rows, bevel, polish, the weave / grain)
MATERIALS = {
    "leather":        ("belt_leather", 30, 3.0, 0.28, "leather"),
    "rope":           ("rope_tan", 18, 9.0, 0.15, "rope"),
    "webbing_olive":  ("web_olive", 24, 1.6, 0.30, "webbing"),
    "webbing_green":  ("web_green", 24, 1.6, 0.30, "webbing"),
    "webbing_camo":   ("camo_a", 24, 1.6, 0.30, "camo"),
    "harness":        ("harness_black", 26, 1.6, 0.40, "harness"),
    "pack":           ("pack_nylon", 30, 6.0, 0.35, "pack"),
    "sling":          ("canvas_khaki", 22, 1.8, 0.15, "canvas"),
    "holster_brown":  ("holster_brown", 28, 3.0, 0.40, "leather"),
    "holster_black":  ("holster_black", 28, 3.0, 0.50, "leather"),
    "holster_green":  ("web_green", 26, 1.6, 0.30, "webbing"),
    "holster_tape":   ("tape_grey", 26, 1.2, 1.0, "tape"),
    "holster_hide":   ("hide_tan", 28, 3.0, 0.15, "hide"),
}


def strap(name, W, seed=3):
    """the material W long, 30 rows tall (centred), its texture periodic in TILE so the middle tiles without a seam"""
    ramp, thick, bevel, polish, kind = MATERIALS[name]
    p = Plate(f"strap_{name}", W, H, seed=seed)
    d = p.d
    y0 = (H - thick) // 2
    m = Mask(W, H).rect(0, y0, W, thick).get()
    if kind == "rope":
        # the rope's outline bulges where each strand comes to the edge and dips at the lay between them
        yy_, xx_ = np.mgrid[0:H, 0:W]
        yc_ = y0 + thick / 2.0
        P_ = 64 / 5.0
        def lobe_at(y):
            return np.clip(0.5 + 0.5 * np.cos((xx_ + (y - yc_) * 0.75) * (2 * math.pi / P_)), 0, 1)
        dip_top = 2.2 * (1 - lobe_at(y0))
        dip_bot = 2.2 * (1 - lobe_at(y0 + thick - 1))
        m = m & (yy_ >= y0 + dip_top) & (yy_ <= y0 + thick - 1 - dip_bot)
    d.slab(m, Z_FACE + 2.0, ramp, bevel=bevel, polish=polish, power=0.6)
    r = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:H, 0:W]
    per = lambda a: np.tile(a, (1, W // TILE + 1))[:, :W]
    if kind == "leather":
        n = r.random((H, TILE)).astype(np.float32)
        peb = np.where(n > 0.86, -0.035, np.where(n < 0.06, 0.035, 0.0))
        mott = ndi.gaussian_filter(r.random((H, TILE)).astype(np.float32), (3.0, 9.0), mode="wrap") - 0.5
        d.tex[m] = per(peb + mott * 0.10)[m]
        for y in (y0 + 4, y0 + thick - 5):              # the creaser lines, as on the belt
            d.h[y, 1:W - 1] -= 0.33
            d.dark[y, 1:W - 1] = np.maximum(d.dark[y, 1:W - 1], 0.19)
    elif kind == "rope":
        # jute, three strands laid in a twist (the director's reference): each strand a fat lobe crossing on the
        # diagonal, a deep shadowed lay between strands, fine fibres twisted the other way along each strand, and
        # stray hairs standing off the rope's edges
        yc = y0 + thick / 2.0
        P = 64 / 5.0                                       # five strand crossings a tile, so the middle repeats
        ph = (xx + (yy - yc) * 0.75) * (2 * math.pi / P)
        lobe = np.clip(0.5 + 0.5 * np.cos(ph), 0, 1) ** 0.6   # fat, rounded strands
        d.h[m] += (lobe * 1.8 - 0.8)[m]
        lay = np.cos(ph) < -0.86
        d.dark[m & lay] = np.maximum(d.dark[m & lay], 0.65)
        fib = np.sin((xx * 1.0 - (yy - yc) * 1.9) * 1.35)
        d.tex[m] = (fib * 0.06)[m]
        n = per(r.random((H, TILE)).astype(np.float32))
        d.tex[m] += np.where(n > 0.9, 0.05, np.where(n < 0.05, -0.05, 0.0))[m]
    elif kind in ("webbing", "camo", "harness"):
        # woven nylon webbing (director's reference, Oct 16 2026): rows of little slanted grains, the slant flipping
        # every three rows into a herringbone; each grain raised and lit, the gaps between them sunk
        ry = (yy - y0)
        band = (ry // 4) % 2
        slant = np.where(band == 0, xx + ry // 2, xx - ry // 2)
        grain = (slant % 4) < 2
        d.h[m & grain] += 0.32
        d.h[m & ~grain] -= 0.15
        d.dark[m & ~grain] = np.maximum(d.dark[m & ~grain], 0.20)
        fl = per(r.random((H, TILE)).astype(np.float32))
        d.tex[m] = np.where(fl > 0.92, 0.03, 0.0)[m]
        if kind == "camo":
            # big soft blobs, each colour its own field, cut hard (as printed); about a quarter of the strap each
            for mat_, thr, sig in (("camo_c", 0.55, (3.0, 6.0)), ("camo_b", 0.60, (2.4, 5.0)), ("camo_d", 0.66, (2.0, 4.0))):
                blob = per(ndi.gaussian_filter(r.random((H, TILE)).astype(np.float32), sig, mode="wrap"))
                blob = (blob - blob.min()) / (blob.max() - blob.min() + 1e-6)
                bm = m & (blob > thr)
                d.mat[bm] = d.mid(mat_)
        if kind == "harness":
            band = Mask(W, H).rect(0, H // 2 - 3, W, 6).get() & m
            d.slab(band, 0.4, "reflect", bevel=0.6, polish=0.9, on=Z_FACE + 2.0)
    elif kind == "pack":
        # padded pack cloth (an oxford weave: pairs of threads over and under, the director's reference): a puffed
        # centre, a bound edge
        bind = m & ~ndi.binary_erosion(m, iterations=2)
        d.paint(bind, "pack_bind")
        over = ((xx // 2 + yy) % 2) == 0
        d.h[m & over] += 0.20
        d.dark[m & ~over] = np.maximum(d.dark[m & ~over], 0.14)
        fl = per(r.random((H, TILE)).astype(np.float32))
        d.tex[m] = np.where(fl > 0.92, 0.025, 0.0)[m]
    elif kind == "canvas":
        # a plain weave: a light cross-hatch
        wv = ((xx + yy) % 2 == 0)
        d.h[m & wv] += 0.15
        d.tex[m] = np.where(wv, 0.05, -0.05)[m]
        n = per(ndi.gaussian_filter(r.random((H, TILE)).astype(np.float32), (2.0, 6.0), mode="wrap") - 0.5)
        d.tex[m] += (n * 0.08)[m]
    elif kind == "tape":
        # silver duct tape (the director's reference): glossy, the cloth scrim showing through as a fine embossed grid,
        # long soft wrinkles running along it, and where one wrap ends over the next a torn, ragged edge
        grid = ((xx % 3) == 0) | (((yy - y0) % 3) == 0)
        d.h[m & grid] += 0.12
        d.dark[m & grid] = np.maximum(d.dark[m & grid], 0.08)
        wr = np.zeros((H, TILE), np.float32)
        for kk in range(4):
            cx_ = r.uniform(0, TILE); cy_ = r.uniform(y0 + 3, y0 + thick - 3); sl = r.uniform(-0.18, 0.18)
            ln = r.uniform(18, 34); amp = r.uniform(0.5, 0.9) * (1 if kk % 2 == 0 else -1)
            for dx in (-TILE, 0, TILE):
                xs = np.arange(TILE)[None, :] - cx_ - dx
                ys = np.arange(H)[:, None] - (cy_ + sl * xs)
                wr += amp * np.exp(-(ys ** 2) / 1.6) * np.exp(-(xs ** 2) / (2 * (ln / 2) ** 2))
        d.h[m] += per(wr)[m]
        # one torn wrap end a tile: the next wrap's edge, ragged, a shadow under it
        tx = int(r.integers(8, TILE - 8))
        for y in range(y0, y0 + thick):
            jx = tx + int(r.integers(-1, 2))
            for rep_ in range(0, W, TILE):
                xe = rep_ + jx
                if 0 <= xe < W:
                    d.seam(rbox(d, xe, y, 1, 1) & m, 0.35)
                    if xe + 1 < W: d.h[y, xe + 1] += 0.3
    elif kind == "hide":
        sp = per(ndi.gaussian_filter(r.random((H, TILE)).astype(np.float32), (1.5, 3.0), mode="wrap"))
        sp = (sp - sp.min()) / (sp.max() - sp.min() + 1e-6)
        d.mat[m & (sp > 0.66)] = d.mid("hide_spot")
        n = per(r.random((H, TILE)).astype(np.float32))
        d.tex[m] = np.where(n > 0.85, -0.04, 0.0)[m]
    for x in (0, W - 1):
        d.seam(rbox(d, x, 0, 1, H) & m, 0.35)
    return p


def jute_hairs(img, seed=5):
    """stray jute hairs off the rope's top and bottom edges, laid on the rendered picture (no outline round them),
    periodic in TILE"""
    a = np.array(img)
    r = np.random.default_rng(seed)
    thick = MATERIALS["rope"][1]
    y0 = (H - thick) // 2
    col = np.array([214, 182, 126, 210])
    for k in range(8):
        hx = int(r.integers(0, TILE)); top = k % 2 == 0
        ln = int(r.integers(1, 3)); sl = 1 if r.random() < 0.5 else -1
        for t in range(ln):
            y = (y0 - 1 - t) if top else (y0 + thick + t)
            for rep_ in range(0, a.shape[1], TILE):
                x = rep_ + (hx + sl * t) % TILE
                if 0 <= x < a.shape[1] and 0 <= y < H and a[y, x, 3] == 0: a[y, x] = col
    return Image.fromarray(a, "RGBA")


def pieces(name):
    W = TILE * 3
    img = strap(name, W).d.render(chrome_env="room")
    if name == "rope": img = jute_hairs(img)
    return img.crop((0, 0, END, H)), img.crop((TILE, 0, 2 * TILE, H)), img.crop((W - END, 0, W, H))


def assemble(name, w, k=1):
    l, m, r = pieces(name)
    out = Image.new("RGBA", (w, H * k), (0, 0, 0, 0))
    L, M, R = (im.resize((im.width * k, H * k), Image.NEAREST) for im in (l, m, r))
    x = END * k
    while x < w - END * k:
        out.alpha_composite(M.crop((0, 0, min(M.width, w - END * k - x), H * k)), (x, 0)); x += M.width
    out.alpha_composite(L, (0, 0)); out.alpha_composite(R, (w - END * k, 0))
    return out


def export(root):
    d = os.path.join(root, "42", "media", "textures", "ZeD", "belt")
    os.makedirs(d, exist_ok=True)
    for name in MATERIALS:
        if name == "leather": continue        # the waist belt is d_belt.py's
        l, m, r = pieces(name)
        for part, im in (("l", l), ("mid", m), ("r", r)):
            im.save(os.path.join(d, f"{name}_{part}.png"))
    print("wrote", len(MATERIALS) - 1, "materials to", d)


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "mod", "ZeD-UI"))
