"""ZeD foraging pins (the director, Nov 15 2026): "look similar to what they look like in the game, just more to match
our look ... the icon showing what the item discovered is, or showing a hint ... behind a magnifying glass".
Two layers per pin, drawn by ZeD's renderPinIcon in this order: BACK (shadow, body, ring, the glass's dark), the item's
own icon at 100% (vanilla draws it at 67%: the lens magnifies), then GLASS (the ring again, the tint and glare; or the
frost: half for a hint, full with a ? for unknown). Canvas 60 x 90, vanilla's, so the Lua's placement is unchanged."""
import os, sys, math
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, os.environ.get("ZED_DASHPX", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools", "dashpx")))
from engine import Dash, Mask, add_ramp, FONTS

OUT = "art/pins"
W, H = 60, 90
add_ramp("pinbody", "#2a2c30")
add_ramp("lensdark", "#1b2229")

def shadow_under(img, off=(2, 2), a=110):
    al = np.asarray(img)[..., 3] > 0
    sh = np.zeros((H, W, 4), np.uint8)
    m = np.zeros_like(al); m[off[1]:, off[0]:] = al[:H - off[1], :W - off[0]]
    sh[m] = (0, 0, 0, a)
    base = Image.fromarray(sh, "RGBA"); base.alpha_composite(img); return base

def teardrop_mask(cx, cy, r, tipy):
    m = Mask(W, H).ellipse(cx, cy, r, r)
    d = tipy - cy; a = math.asin(r / d)
    # tangent points: from the centre, at angle (90 - a) either side of straight down
    t = math.pi / 2 - a
    p1 = (cx + r * math.sin(t), cy + r * math.cos(t)); p2 = (cx - r * math.sin(t), cy + r * math.cos(t))
    m.poly([p2, p1, (cx, tipy)])
    return m

def pin_A():
    """the game's pin, ZeD's: a dark teardrop, a chrome bezel round the lens in its head"""
    cx, cy, rb, ri, ro = 29, 28, 25, 16, 22
    d = Dash(W, H, seed=11)
    d.slab(teardrop_mask(cx, cy, rb, 84), 5.0, "pinbody", bevel=3.0, polish=0.45)
    d.torus(cx, cy, ri, ro, 3.2, "chrome", polish=1.0, on="cur")
    d.well(Mask(W, H).ellipse(cx, cy, ri, ri), 1.6, "lensdark", bevel=0.8)
    return d, (cx, cy, ri, ro)

def pin_B():
    """the magnifying glass is the pin: the lens on top, its handle pointing at the find"""
    cx, cy, ri, ro = 29, 26, 21.5, 25.5          # (the director, Nov 15: "more pronounced glass": a thinner rim)
    d = Dash(W, H, seed=12)
    grip = Mask(W, H).poly([(23.5, 57), (34.5, 57), (32.2, 78), (29, 86), (25.8, 78)])
    d.slab(grip, 5.0, "blackp", bevel=3.2, polish=0.35)
    d.cyl(24.5, 50, 9, 8, 5.5, "chrome", axis="v", polish=1.0)          # the collar
    d.slab(Mask(W, H).ellipse(cx, cy, ro + 0.2, ro + 0.2), 2.0, "chrome", bevel=1.0, polish=1.0)
    d.torus(cx, cy, ri, ro, 3.4, "chrome", polish=1.0, on="cur")
    d.well(Mask(W, H).ellipse(cx, cy, ri, ri), 2.0, "lensdark", bevel=0.8)
    return d, (cx, cy, ri, ro)

def disc(cx, cy, r, dx=0, dy=0):
    yy, xx = np.mgrid[0:H, 0:W]
    return np.hypot(xx + 0.5 - cx - dx, yy + 0.5 - cy - dy) <= r

def glass_layer(full, geom, frost=0, q=False):
    """the ring (opaque, over anything the item spilled onto it), then the glass: a cool tint, a darker edge, the glare.
    frost: 0 clear, 1 a hint (the item shows through, out of focus), 2 unknown (milky, a ? on it)"""
    cx, cy, ri, ro = geom
    A = np.asarray(full).copy()
    out = np.zeros((H, W, 4), np.uint8)
    yy, xx = np.mgrid[0:H, 0:W]
    rr = np.hypot(xx + 0.5 - cx, yy + 0.5 - cy)
    ring = (rr > ri - 0.2) & (rr <= ro + 1.6) & (A[..., 3] > 0)
    out[ring] = A[ring]
    inner = rr <= ri - 0.2
    def put(mask, c, a):
        sel = mask & inner
        out[sel] = (*c, a)
    if frost:
        dither = ((xx + yy) % 2 == 0)
        put(np.ones_like(inner), (196, 210, 218), 172 if frost == 1 else 226)
        put(dither & (rr > ri - 6), (176, 192, 202), 165 if frost == 1 else 232)
    else:
        put(np.ones_like(inner), (150, 190, 214), 30)
    put((rr > ri - 2.6), (6, 10, 14), 105)                                   # the lens's edge
    cres = disc(cx, cy, ri - 2.2) & ~disc(cx, cy, ri - 2.2, 2.2, 2.4) & (xx + yy < cx + cy - 2)
    put(cres, (236, 244, 250), 120)                                            # the glare along the top left
    sx, sy = cx - ri * 0.42, cy - ri * 0.52
    put((np.abs(xx + 0.5 - sx) <= 1.6) & (np.abs(yy + 0.5 - sy) <= 1.0), (255, 255, 255), 230)
    put((np.abs(xx + 0.5 - (sx + 3.5)) <= 0.6) & (np.abs(yy + 0.5 - (sy + 2.2)) <= 0.6), (255, 255, 255), 200)
    if not frost:
        t = (xx + 0.5 - cx) + (yy + 0.5 - cy)                                  # a soft diagonal streak
        put((np.abs(t + ri * 0.15) <= 1.1) & (xx + 0.5 - cx < ri * 0.25) & (yy + 0.5 - cy < ri * 0.25), (255, 255, 255), 38)
    if q:                                                                       # the ?, a bold ink one on the frost
        g = ["0111110", "1100011", "0000011", "0001110", "0011000", "0000000", "0011000", "0011000"]
        s = 2; gw, gh = 7, 8
        gx0 = int(round(cx - gw * s / 2)); gy0 = int(round(cy - gh * s / 2)) + 1
        for r_, row in enumerate(g):
            for c_, b in enumerate(row):
                if b == "1": out[gy0 + r_ * s: gy0 + r_ * s + s, gx0 + c_ * s: gx0 + c_ * s + s] = (30, 36, 44, 255)
    return Image.fromarray(out, "RGBA")

SKULL = ["..XXXXXX..", ".XXXXXXXX.", "XXXXXXXXXX", "XX..XX..XX", "XX..XX..XX", "XXXXXXXXXX",
         ".XXX..XXX.", "..XXXXXX..", "..X.XX.X..", "..XXXXXX.."]
def poison_mark():
    """the game's SkullPoison, ZeD's: a green skull on an ink tile, 12 x 12"""
    im = Image.new("RGBA", (12, 12), (0, 0, 0, 0)); px = im.load()
    for y in range(12):
        for x in range(12): px[x, y] = (12, 12, 12, 255)
    for y, row in enumerate(SKULL):
        for x, ch in enumerate(row):
            if ch == "X": px[x + 1, y + 1] = (128, 214, 92, 255) if y < 3 else (92, 178, 66, 255)
    return im

def make(name, fn):
    d, geom = fn()
    full = d.render()
    back = shadow_under(full)
    back.save(f"{OUT}/{name}_back.png")
    for tag, fr, q in (("glass", 0, False), ("hint", 1, False), ("unknown", 2, True)):
        glass_layer(full, geom, fr, q).save(f"{OUT}/{name}_{tag}.png")
    return geom

GEOM = {"A": make("pinA", pin_A), "B": make("pinB", pin_B)}
poison_mark().save(f"{OUT}/poison_mark.png")
print(GEOM)
