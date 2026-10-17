"""Concepts for the leather strap behind the hotbar (director, Oct 16 2026): no stitching, more material, a subtle
stamped impression. Three ways, drawn the plates' way (a height field, lit from the top left), 30 px tall.
usage: python c_belt.py -> out/belt/concepts.png"""
import os
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
from physlib import *            # noqa: F401,F403
from engine import add_ramp

add_ramp("belt_leather", "#56391f")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "belt")
os.makedirs(OUT, exist_ok=True)
H = 30


def base(W, seed=3):
    p = Plate("belt", W, H, seed=seed)
    d = p.d
    m = Mask(W, H).rect(0, 0, W, H).get()
    d.slab(m, Z_FACE + 2.0, "belt_leather", bevel=3.0, polish=0.28, power=0.6)    # the edges rolled and burnished
    # the leather's own grain: fine pebble, and a soft mottle so it is not one flat brown
    d.grain_pebble(m, 0.035, seed=seed)
    r = np.random.default_rng(seed + 1)
    mott = ndi.gaussian_filter(r.random((H, W)).astype(np.float32), (3.0, 9.0)) - 0.5
    d.tex[m] += (mott * 0.10)[m]
    # the cut ends, burnished darker
    for x in (0, W - 1):
        d.seam(rbox(d, x, 0, 1, H), 0.35)
    return p, d


def crease(d, W, inset=4, depth=0.45):
    """a creaser line pressed along both edges (what replaces the stitching)"""
    for y in (inset, H - 1 - inset):
        d.h[y, 1:W - 1] -= depth
        d.dark[y, 1:W - 1] = np.maximum(d.dark[y, 1:W - 1], 0.28)


def option_a(W):
    """A: creased edges only: two pressed lines and the leather"""
    p, d = base(W)
    crease(d, W)
    return p


def option_b(W):
    """B: creased edges and a basketweave stamp between them: little pressed bars, three across then three down"""
    p, d = base(W)
    crease(d, W)
    cell = 6
    y0, y1 = 7, H - 7
    for cx in range(3, W - 3, cell):
        for cy in range(y0, y1 - 1, cell):
            horiz = ((cx // cell) + (cy // cell)) % 2 == 0
            for k in range(3):
                if horiz: xs, ys, w, h = cx, cy + k * 2, cell - 1, 1
                else: xs, ys, w, h = cx + k * 2, cy, 1, cell - 1
                xe, ye = min(xs + w, W - 3), min(ys + h, y1)
                if xe > xs and ye > ys:
                    d.h[ys:ye, xs:xe] -= 0.28
                    d.dark[ys:ye, xs:xe] = np.maximum(d.dark[ys:ye, xs:xe], 0.14)
    return p


def option_c(W):
    """C: creased edges and a small stamped diamond every so often down the middle, a dot raised in each"""
    p, d = base(W)
    crease(d, W)
    cy = H // 2
    for cx in range(10, W - 6, 18):
        dm = (np.abs(d.XX + 0.5 - cx) + np.abs(d.YY + 0.5 - cy)) <= 5.0
        ring = dm & ~((np.abs(d.XX + 0.5 - cx) + np.abs(d.YY + 0.5 - cy)) <= 3.0)
        d.h[dm] -= 0.4
        d.dark[ring] = np.maximum(d.dark[ring], 0.18)
        dot = (np.abs(d.XX + 0.5 - cx) + np.abs(d.YY + 0.5 - cy)) <= 1.0
        d.h[dot] += 0.5
    return p


def composite(strap, src="../tabs/belt_now.png"):
    """the strap under the real belt's boxes and buckle (a screenshot): only the old strap's pixels are replaced"""
    im = np.array(Image.open(src).convert("RGB")).astype(int)
    out = im.copy()
    y0 = 18
    st = np.array(strap.convert("RGB")).astype(int)
    for y in range(y0, y0 + H):
        for x in range(60, 330):
            r, g, b = im[y, x]
            leather = (40 <= r <= 110) and (g < r * 0.76) and (b < g) and (r - b > 18)
            stitch = abs(r - 159) < 22 and abs(g - 127) < 22 and abs(b - 83) < 22
            edge = (r, g, b) == (26, 17, 8)
            if leather or stitch or edge:
                sx = x - 68
                if 0 <= sx < st.shape[1]: out[y, x] = st[y - y0, sx]
    return Image.fromarray(out.astype(np.uint8), "RGB")


if __name__ == "__main__":
    W = 252
    rows = [("NOW", None)] + [(t, f(W)) for t, f in (("A  CREASED EDGES", option_a), ("B  BASKETWEAVE STAMP", option_b),
                                                     ("C  STAMPED DIAMONDS", option_c))]
    k = 3
    tiles = []
    for title, p in rows:
        if p is None:
            img = Image.open("../tabs/belt_now.png").convert("RGB"); strap = None
        else:
            strap = p.d.render(chrome_env="room")
            img = composite(strap)
        tiles.append((title, img, strap))
    sheet = Image.new("RGB", (385 * k + 40, len(tiles) * (65 * k + 34) + 20), (40, 40, 44))
    d = ImageDraw.Draw(sheet)
    y = 10
    for title, img, strap in tiles:
        d.text((20, y), title, fill=(230, 230, 230))
        sheet.paste(img.resize((img.width * k, img.height * k), Image.NEAREST), (20, y + 18))
        y += 65 * k + 34
    sheet.save(os.path.join(OUT, "concepts.png"))
    # the bare straps at 4x too
    bare = Image.new("RGB", (W * 4 + 20, 3 * (H * 4 + 12) + 10), (40, 40, 44))
    for i, (_, _, strap) in enumerate(tiles[1:]):
        bare.paste(strap.convert("RGB").resize((W * 4, H * 4), Image.NEAREST), (10, 10 + i * (H * 4 + 12)))
    bare.save(os.path.join(OUT, "straps_4x.png"))
    print("ok")
