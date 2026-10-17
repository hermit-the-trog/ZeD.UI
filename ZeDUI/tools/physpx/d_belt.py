"""The leather strap behind the hotbar (director, Oct 16 2026, option A): no stitching; rolled, burnished edges, the
leather's own grain and mottle, and a creaser line pressed along each edge. Drawn the plates' way (a height field lit
from the top left), 30 plate pixels tall.

The strap's length follows the hotbar's slots, so it is exported in three pieces drawn at a whole multiple by
ZeD_Belt.lua: the left end, a 64-pixel middle that repeats without a seam, and the right end.
usage: python d_belt.py [mod root]   (default ./out/mod/ZeD-UI) -> media/textures/ZeD/belt/strap_{l,mid,r}.png"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

from physlib import *            # noqa: F401,F403
from engine import add_ramp

add_ramp("belt_leather", "#56391f")
H, TILE, END = 30, 64, 8
CREASE_DEPTH, CREASE_DARK = 0.33, 0.19    # Oct 16 2026: between the first press (0.45 / 0.28) and half of it (director)
DIR = "media/textures/ZeD/belt"


def strap(W, seed=3):
    """a strap W long; its grain repeats every TILE pixels so the middle can be cut out as a seamless tile"""
    p = Plate("belt_strap", W, H, seed=seed)
    d = p.d
    m = Mask(W, H).rect(0, 0, W, H).get()
    d.slab(m, Z_FACE + 2.0, "belt_leather", bevel=3.0, polish=0.28, power=0.6)    # the edges rolled and burnished
    r = np.random.default_rng(seed)
    # fine pebble grain and a soft mottle, both periodic in TILE
    n = r.random((H, TILE)).astype(np.float32)
    peb = np.where(n > 0.86, -0.035, np.where(n < 0.06, 0.035, 0.0))
    mott = ndi.gaussian_filter(r.random((H, TILE)).astype(np.float32), (3.0, 9.0), mode="wrap") - 0.5
    t = np.tile(peb + mott * 0.10, (1, W // TILE + 1))[:, :W]
    d.tex[m] = t[m]
    for y in (4, H - 5):                                   # the creaser lines, pressed light (director: subtler)
        d.h[y, 1:W - 1] -= CREASE_DEPTH
        d.dark[y, 1:W - 1] = np.maximum(d.dark[y, 1:W - 1], CREASE_DARK)
    for x in (0, W - 1):                                   # the cut ends, burnished darker
        d.seam(rbox(d, x, 0, 1, H), 0.35)
    return p


def pieces():
    W = TILE * 3
    img = strap(W).d.render(chrome_env="room")
    left = img.crop((0, 0, END, H))
    mid = img.crop((TILE, 0, 2 * TILE, H))
    right = img.crop((W - END, 0, W, H))
    return left, mid, right


def export(root):
    d = os.path.join(root, "42", *DIR.split("/"))
    os.makedirs(d, exist_ok=True)
    l, m, r = pieces()
    l.save(os.path.join(d, "strap_l.png")); m.save(os.path.join(d, "strap_mid.png")); r.save(os.path.join(d, "strap_r.png"))
    print("wrote strap_l, strap_mid, strap_r to", d)
    return l, m, r


def assemble(w, k=1):
    """the strap as ZeD_Belt draws it: w screen pixels long at k: the ends, the middle repeated and cut at the end"""
    l, m, r = pieces()
    out = Image.new("RGBA", (w, H * k), (0, 0, 0, 0))
    L, M, R = (im.resize((im.width * k, H * k), Image.NEAREST) for im in (l, m, r))
    x = END * k
    while x < w - END * k:
        seg = M.crop((0, 0, min(M.width, w - END * k - x), H * k)); out.alpha_composite(seg, (x, 0)); x += M.width
    out.alpha_composite(L, (0, 0)); out.alpha_composite(R, (w - END * k, 0))
    return out


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "mod", "ZeD-UI"))
    a = assemble(252)
    # the seam check: the middle tile next to itself
    l, m, r = pieces()
    two = Image.new("RGBA", (TILE * 2, H)); two.alpha_composite(m, (0, 0)); two.alpha_composite(m, (TILE, 0))
    os.makedirs("out/belt", exist_ok=True)
    two.resize((TILE * 2 * 6, H * 6), Image.NEAREST).save("out/belt/tile_seam_6x.png")
    a.resize((a.width * 4, a.height * 4), Image.NEAREST).save("out/belt/strap_assembled_4x.png")
