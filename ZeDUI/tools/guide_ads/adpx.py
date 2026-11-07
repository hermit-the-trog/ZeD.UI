"""The survival guide ads' pictures in ZeD's pixel art (director, Nov 6 2026: "any of the images need to use our pixel
art"): the dashes' engine (tools/dashpx/engine.py: a height field, a material per pixel, lit from above, real
shadows, every material quantized to its own ramp, no blending, no dithering), printed the book's way: one ink on the
paper, so every ramp runs between the paper and the ink (a tint per step, as a 1987 printer's screens).

One art pixel = one design pixel (one screen pixel at 1080p); the ads are drawn at 2x, so each art pixel is 2 x 2.
usage: python adpx.py [name ...]  -> px/<name>.png (ink on transparent)"""
import math
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
for _p in (os.path.join(HERE, "..", "dashpx"), os.path.join(HERE, "engine")):     # the repo's engine, else a copy beside
    if os.path.exists(os.path.join(_p, "engine.py")): sys.path.insert(0, _p); break
import engine as E                                    # noqa: E402
from engine import Dash, Mask, RAMPS                  # noqa: E402

PAPER = np.array(E.hx("#f5ecd2"), float)
INK = np.array(E.hx("#232a3a"), float)


def tint(t):
    c = PAPER * (1 - t) + INK * t
    return tuple(int(round(v)) for v in c)


def ink_ramp(dark, light, n=8):
    """a ramp from `dark` (share of ink at the darkest step) to `light` (at the lightest)"""
    return [tint(dark + (light - dark) * i / (n - 1)) for i in range(n)]


# the print ramps: what each surface prints as (a black thing, a mid-grey thing, a pale thing, bare paper)
RAMPS["k"] = ink_ramp(1.00, 0.52)        # black: rubber, black paint, iron
RAMPS["d"] = ink_ramp(1.00, 0.30)        # dark: wood, steel, a dark label
RAMPS["m"] = ink_ramp(0.92, 0.14)        # mid: brass, tin, flesh, cardboard
RAMPS["l"] = ink_ramp(0.78, 0.04)        # light: white paint, glass, cotton
RAMPS["w"] = ink_ramp(0.55, 0.00)        # paper-white: a label's ground, a mattress cover
RAMPS["chrome"] = ink_ramp(1.00, 0.00)   # chrome: everything it reflects, black to paper
RAMPS["p"] = [tint(1.0)] * 8             # print: ink, flat
RAMPS["pw"] = [tint(0.0)] * 8            # print: paper, flat (reversed-out type)
OUTLINE = tint(1.0)

DESIGNS = {}
# THE VIEW (the director, Nov 6: "get all the perspectives right"): every picture is seen from the front and a little
# from above, the same for all of them, so a level circle (a can's lid, a ripple, a hat's brim) is an ellipse this
# much as tall as it is wide, and anything round bows down through the middle by the same rule
VIEW = 0.26


def design(w, h):
    def deco(fn):
        DESIGNS[fn.__name__] = (w, h, fn)
        return fn
    return deco


def render(name):
    w, h, fn = DESIGNS[name]
    d = Dash(w, h, seed=11)
    fn(d)
    im = d.render(chrome_env="room")
    a = np.array(im)
    ring = (a[..., 3] == 255) & np.all(a[..., :3] == np.array(E.OUTLINE, np.uint8), axis=2)
    a[ring, :3] = OUTLINE
    return Image.fromarray(a, "RGBA")


# ------------------------------------------------------------------ helpers
def ellipse_m(d, cx, cy, rx, ry):
    return ((d.XX + 0.5 - cx) / rx) ** 2 + ((d.YY + 0.5 - cy) / ry) ** 2 <= 1.0


def cyl_v(d, x0, x1, y0, y1, z, mat, polish=0.5, top_ry=0.0, bot_ry=0.0, on=0.0):
    """an upright cylinder seen from the front, a little from above: its body round across x, the top an ellipse,
    the bottom's curve"""
    cx, rx = (x0 + x1) / 2, (x1 - x0) / 2
    body = (d.XX >= x0) & (d.XX < x1) & (d.YY >= y0) & (d.YY < y1)
    if bot_ry: body |= ellipse_m(d, cx, y1, rx, bot_ry) & (d.YY >= y1)
    t = (d.XX + 0.5 - cx) / rx
    prof = np.sqrt(np.clip(1 - t ** 2, 0, 1)) * z
    d.h = np.where(body, on + prof, d.h).astype(np.float32)
    d.mat[body] = d.mid(mat); d.solid |= body; d.polish[body] = polish; d.tex[body] = 0
    top = None
    if top_ry:
        top = ellipse_m(d, cx, y0, rx, top_ry)
        # the lid faces up toward the light: a flat at the body's height, tipped toward the viewer
        d.h = np.where(top, on + z * 0.55 + (d.YY + 0.5 - y0) * 0.6, d.h).astype(np.float32)
        d.mat[top] = d.mid(mat); d.solid |= top; d.polish[top] = polish
    return body, top


class Cyl:
    """an upright cylinder's surface seen a little from above (the director, Nov 6: "the wording and the label doesn't
    wrap. It just is flat"): u = the distance round the surface from the front (so print squeezes toward the sides),
    v = the height on the surface (so a band, a rib or a line of print bows down through the middle, as the lid's
    ellipse does). v is measured where the line meets the silhouette's edges."""
    def __init__(s, d, x0, x1, ry):
        s.cx, s.rx, s.ry = (x0 + x1) / 2, (x1 - x0) / 2, ry
        t = np.clip((d.XX + 0.5 - s.cx) / s.rx, -1, 1)
        s.c = np.sqrt(1 - t ** 2)
        s.u = s.rx * np.arcsin(t)
        s.v = d.YY + 0.5 - ry * s.c


def band_v(d, body, cy, v0, v1, mat=None):
    m = body & (cy.v >= v0) & (cy.v < v1)
    if mat: d.mat[m] = d.mid(mat); d.tex[m] = 0
    return m


def glyphs(t, font="35", gap=1):
    """the flat print of a line of type: a bool array (rows, cols)"""
    f = E.FONTS[font]
    rows = len(f["A"]); w = E.text_w(t, font, gap)
    a = np.zeros((rows, w), bool); x = 0
    for ch in t:
        g = f.get(ch, f.get(ch.upper(), f[" "]))
        for ry, row in enumerate(g):
            for rx, b in enumerate(row):
                if b == "1": a[ry, x + rx] = True
        x += len(g[0]) + gap
    return a


def print_wrap(d, body, cy, t, v_top, mat, font="35", u0=0.0, scale=1, gap=1):
    """type printed round the cylinder, centred at u0 (the front), its top at height v_top. A pixel artist's wrap:
    each letter keeps its own pixels (a 3-pixel letter can't be squeezed and stay a letter); the letters' places close
    up toward the sides as the surface turns away, and every column of a letter rides the curve"""
    f = E.FONTS[font]
    widths = [len(f.get(ch, f.get(ch.upper(), f[" "]))[0]) * scale for ch in t]
    total = sum(widths) + gap * scale * (len(t) - 1)
    m = np.zeros_like(body); x = -total / 2
    xs = []
    for gw in widths:
        uc = x + gw / 2 + u0
        xs.append(int(round(cy.cx + cy.rx * math.sin(max(-1.5, min(1.5, uc / cy.rx))) - gw / 2)))
        x += gw + gap * scale
    # the letters close up toward the sides, but never onto each other: out from the middle, each keeps clear of the last
    mid = len(xs) // 2
    for i in range(mid + 1, len(xs)): xs[i] = max(xs[i], xs[i - 1] + widths[i - 1] + 1)
    for i in range(mid - 1, -1, -1): xs[i] = min(xs[i], xs[i + 1] - widths[i] - 1)
    for ch, gw, sx in zip(t, widths, xs):
        g = f.get(ch, f.get(ch.upper(), f[" "]))
        for ry_, row in enumerate(g):
            for rx_, b in enumerate(row):
                if b != "1": continue
                for a_ in range(scale):
                    for b_ in range(scale):
                        X = sx + rx_ * scale + a_
                        if not (0 <= X < d.W): continue
                        tt = max(-1.0, min(1.0, (X + 0.5 - cy.cx) / cy.rx))
                        Y = int(math.floor(v_top + ry_ * scale + b_ + cy.ry * math.sqrt(1 - tt * tt)))
                        if 0 <= Y < d.H and body[Y, X]: m[Y, X] = True
    d.mat[m] = d.mid(mat); d.tex[m] = 0
    return m

def band(d, body, y0, y1, mat):
    m = body & (d.YY >= y0) & (d.YY < y1)
    d.mat[m] = d.mid(mat); d.tex[m] = 0
    return m


def stroke(d, pts, w, z, mat, polish=0.5, on=0.0, bevel=None):
    m = Mask(d.W, d.H).line(pts, w).get()
    d.slab(m, z, mat, bevel=bevel or max(1.0, w / 2), polish=polish, on=on)
    return m


# ------------------------------------------------------------------ the pictures
@design(316, 116)
def ready_prep(d):
    # the #10 can: the beads, the label and its print all run round it
    body, top = cyl_v(d, 8, 84, 24, 98, 30, "chrome", polish=0.9, top_ry=10, bot_ry=10)
    cy = Cyl(d, 8, 84, 10)
    for vv in (29, 92):
        r = band_v(d, body, cy, vv, vv + 1); d.h[r] -= 0.8; d.dark[r] = 0.25                 # the rolled beads
    lab = band_v(d, body, cy, 37, 82, "d")
    for vv in (37, 81):
        e = band_v(d, body, cy, vv, vv + 1); d.h[e] += 0.4                                    # the label's lapped edges
    rim = top & ~ellipse_m(d, 46, 24, 33, 8); d.h[rim] += 1.2
    print_wrap(d, body, cy, "SURVIVAL", 42, "pw")
    print_wrap(d, body, cy, "BEEF STEW", 50, "pw")
    print_wrap(d, body, cy, "25 YR", 60, "pw", font="57")
    print_wrap(d, body, cy, "NET 3 LB", 72, "pw")
    # the water cube (the director, Nov 6: "what if we instead put it in a plastic cube, like a big water cube, on a
    # crate or pallet"; then his two photos of one, "water tank pallet": ZeD_design_refs/ads/refs/ibc_ref_1.jpg, _2.jpg):
    # an IBC tote, seen in the cookie box's three-quarter axes. On a wooden pallet (deck boards over blocks, the fork
    # openings dark between them), the white tank, its fill cap on top; round it the cage of steel tube: rings round
    # it at five heights, uprights on every face, the top rim; the label plate wired to the cage on the front, proud to
    # be sealed with BPA "for added longevity" (the chemical later bottles bragged of lacking); the drain valve low on
    # the front
    F = [(126, 34), (186, 26), (186, 92), (126, 100)]          # the front face: right edge higher, as the box's
    S = [(104, 28), (126, 34), (126, 100), (104, 94)]          # the left side, turning away
    T = [(104, 28), (164, 20), (186, 26), (126, 34)]           # the top, seen a little from above
    def fy(x, y0=0.0): return y0 - 8.0 * (x - 126) / 60.0      # along the front: 8 px up over 60
    def sy(x, y0=0.0): return y0 + 6.0 * (x - 104) / 22.0      # along the side: 6 px down over 22
    def band(xa, xb, ya, h, along):                            # a strip along a face, its top edge at ya (at x = xa)
        f = fy if along == "f" else sy
        ya0 = ya - f(xa)
        return Mask(d.W, d.H).poly([(xa, f(xa, ya0)), (xb, f(xb, ya0)), (xb, f(xb, ya0) + h), (xa, f(xa, ya0) + h)]).get()
    # the pallet: the fork openings' shadow, the blocks, the deck boards' edges on top of them
    d.flat(band(123, 190, 103.5, 8, "f") | band(101, 123, 97.5, 8, "s"), 2, "d", polish=0.2)
    for xa, xb in ((123, 131), (152, 161), (182, 190)):
        blk = band(xa, xb, 103.5 - 8.0 * (xa - 123) / 60.0 * 0 + fy(xa) - fy(123), 7, "f")
        d.slab(blk, 7, "l", bevel=0.8, polish=0.3); d.grain_wood(blk, scale=0.5, seed=xa)
    for xa, xb in ((101, 107), (116, 123)):
        blk = band(xa, xb, 97.5 + sy(xa) - sy(101), 7, "s")
        d.slab(blk, 5, "m", bevel=0.8, polish=0.3); d.grain_wood(blk, scale=0.5, seed=xa)
    deck = band(123, 190, 100.5, 3.5, "f"); d.slab(deck, 9, "l", bevel=0.8, polish=0.3); d.grain_wood(deck, scale=0.5, seed=31)
    deck = band(101, 123, 94.5, 3.5, "s"); d.slab(deck, 7, "m", bevel=0.8, polish=0.3); d.grain_wood(deck, scale=0.5, seed=32)
    # the tank: white, its side a step darker as it turns away, the top lit
    front = Mask(d.W, d.H).poly(F).get(); side = Mask(d.W, d.H).poly(S).get(); top = Mask(d.W, d.H).poly(T).get()
    d.ramp_h(front, 12, 12, axis="x", mat="w", polish=0.5)
    d.ramp_h(side, 4, 12, axis="x", mat="l", polish=0.5)
    d.flat(top, 16, "w", polish=0.5)
    # the fill cap on the top, a level circle, its ribbed collar
    disc(d, 148, 26, 9, 9 * VIEW + 1.5, 4, "d", polish=0.5, on=16)
    disc(d, 148, 25, 6, 6 * VIEW + 1, 3, "k", polish=0.6, on=19)
    for k in range(-4, 5, 2):
        d.seam(Mask(d.W, d.H).rect(148 + k, 25, 1, 3).get(), 0.25)
    # the cage of steel tube: the rings round it at five heights, the uprights, the top rim's back edges
    def tube(p, q, w=1.3, z=14.5):
        capsule(d, [p, q], w, z, "chrome", polish=0.7)
    for x in (141, 156, 171):                                   # the front's uprights (the corners after)
        tube((x, fy(x, 34)), (x, fy(x, 100)))
    tube((115, sy(115, 28)), (115, sy(115, 94)))                # the side's
    for k in range(5):
        t = k / 4.0
        tube((126, 34 + t * 66), (186, 26 + t * 66), 1.5, 15)   # round the front
        tube((104, 28 + t * 66), (126, 34 + t * 66), 1.5, 15)   # and the side
    for (x, y0, y1) in ((104, 28, 94), (126, 34, 100), (186, 26, 92)):
        tube((x, y0), (x, y1), 1.6, 15.5)                       # the corner uprights
    tube((104, 28), (164, 20), 1.5, 17); tube((164, 20), (186, 26), 1.5, 17)
    # the drain valve low on the front, between the last two rings: its spout toward us and the lever
    disc(d, 134, 91, 3.2, 3.6, 5, "d", polish=0.6, on=14)
    disc(d, 134, 91, 1.6, 1.8, 2, "k", polish=0.5, on=19)
    d.slab(Mask(d.W, d.H).rrect(135, 85, 7, 3, 1).get(), 21, "k", bevel=1, polish=0.7)        # the lever
    # the label plate wired to the cage on the front, its print in the face's plane (8 px up over 60)
    lab = Mask(d.W, d.H).poly([(140, 48), (180, 43), (180, 75), (140, 80)]).get()
    d.slab(lab, 21, "w", bevel=1, polish=0.3)
    def onface(m, x0=140, run=60.0, rise=-8.0):
        out = np.zeros_like(m)
        for x in range(d.W):
            dy = int(round(rise * (x - x0) / run))
            col = m[:, x]
            if dy < 0: out[:dy, x] = col[-dy:]
            elif dy > 0: out[dy:, x] = col[:-dy]
            else: out[:, x] = col
        return out & lab
    for txt, y, font in (("WATER", 50, "57"), ("275 GAL", 59, "35"), ("SEALED", 66, "35"), ("WITH BPA", 72, "35")):
        g = glyphs(txt, font); m = np.zeros((d.H, d.W), bool)
        x0 = 160 - g.shape[1] // 2; m[y:y + g.shape[0], x0:x0 + g.shape[1]] = g
        d.paint(onface(m), "p")
    # the kerosene lantern, a hurricane lantern built the way they are (the director, Nov 6: "lantern isnt connected"):
    # the fount at the bottom; the burner collar on it; the globe on the collar; the two side tubes rising from the
    # fount and bending in to hold the top cap over the globe; the bail hooked through the tubes' tops
    body, top = cyl_v(d, 222, 286, 98, 108, 16, "chrome", polish=0.9, top_ry=32 * VIEW, bot_ry=32 * VIEW)   # the fount
    foot = band_v(d, body, Cyl(d, 222, 286, 32 * VIEW), 104, 108); d.h[foot] += 1.0                         # its rolled foot
    body, top = cyl_v(d, 240, 268, 86, 94, 9, "k", polish=0.5, top_ry=14 * VIEW, bot_ry=14 * VIEW)       # the burner collar
    d.slab(Mask(d.W, d.H).rect(268, 91, 7, 4).get(), 7, "k", bevel=1, on=4)                              # the wick knob's stem
    disc(d, 277, 93, 2.2, 4.0, 4, "chrome", polish=1.0, on=6)                                             # the wick knob, edge on
    r2 = ((d.XX + 0.5 - 254) / 23) ** 2 + ((d.YY + 0.5 - 62) / 25) ** 2
    glob = (r2 <= 1) & (d.YY < 87) & (d.YY >= 40)
    d.h = np.where(glob, 2 + np.sqrt(np.clip(1 - r2, 0, 1)) * 16, d.h).astype(np.float32)
    d.mat[glob] = d.mid("l"); d.solid |= glob; d.polish[glob] = 0.9
    flame = Mask(d.W, d.H).poly([(254, 52), (262, 68), (260, 80), (248, 80), (246, 68)]).get()
    d.paint(flame, "d")
    d.paint(Mask(d.W, d.H).poly([(254, 62), (257, 72), (256, 78), (252, 78), (251, 72)]).get(), "pw")
    d.paint(Mask(d.W, d.H).rect(248, 80, 12, 3).get() & glob, "k")                              # the wick tube
    # the cap: a cone over the globe, its rim a level circle, so its lower edge bows down; the chimney on top
    cx_ = 254
    tt = np.clip((d.XX + 0.5 - cx_) / 25, -1, 1)
    low = 40 + 25 * VIEW * np.sqrt(1 - tt ** 2)
    tw = 8 + (d.YY + 0.5 - 28) / 12 * 17                           # the cone's half-width at each row
    cap = (np.abs(d.XX + 0.5 - cx_) <= tw) & (d.YY >= 28) & (d.YY <= low) & (np.abs(d.XX + 0.5 - cx_) <= 25)
    d.h = np.where(cap, 14 + np.sqrt(np.clip(1 - ((d.XX + 0.5 - cx_) / np.maximum(tw, 1)) ** 2, 0, 1)) * 8 - (d.YY - 28) * 0.4, d.h).astype(np.float32)
    d.mat[cap] = d.mid("chrome"); d.solid |= cap; d.polish[cap] = 0.9
    body, top = cyl_v(d, 244, 264, 20, 30, 10, "chrome", polish=0.9, top_ry=10 * VIEW, bot_ry=10 * VIEW, on=12)   # the chimney
    cyc = Cyl(d, 244, 264, 10 * VIEW)
    for k in range(3):
        print_wrap(d, body, cyc, "-", 22 + k * 0, "k", u0=(k - 1) * 6)                                    # its vent slots
    for side in (-1, 1):
        x0 = 254 + side * 33
        capsule(d, [(x0, 98), (x0, 46), (254 + side * 26, 38)], 4.2, 15, "chrome", polish=1.0)  # the side tube
        capsule(d, [(254 + side * 26, 38), (254 + side * 20, 36)], 4.2, 15, "chrome", polish=1.0)
        d.slab(Mask(d.W, d.H).rect(x0 - 3, 48, 6, 5).get(), 16.5, "chrome", bevel=1.5, polish=1.0)  # the bail's pivot clip
    m = Mask(d.W, d.H).arc(254, 50, 33, 46, 180, 360, 2.2).get() & (d.YY <= 49)
    d.slab(m, 17, "k", bevel=1, polish=0.6)                                                      # the bail
    d.slab(Mask(d.W, d.H).rrect(246, 2, 16, 5, 2).get(), 19, "d", bevel=1.5, polish=0.3)         # its wooden grip


@design(206, 50)
def militia(d):
    # a lever-action rifle, muzzle right: walnut stock and fore-end, blued receiver, barrel and magazine tube
    stock = Mask(d.W, d.H).poly([(2, 20), (10, 14), (60, 19), (74, 21), (74, 30), (62, 30), (12, 37), (2, 35)]).get()
    d.slab(stock, 8, "d", bevel=4, polish=0.35)
    d.grain_wood(stock, scale=0.6, seed=5)
    d.slab(Mask(d.W, d.H).rect(2, 14, 4, 23).get(), 9, "k", bevel=1)              # the butt plate
    rec = Mask(d.W, d.H).poly([(72, 18), (112, 18), (114, 29), (72, 31)]).get()
    d.slab(rec, 9, "k", bevel=2, polish=0.7)
    d.paint(Mask(d.W, d.H).rect(84, 21, 18, 1).get(), "m")                          # the loading gate's edge
    d.cyl(110, 19, 94, 5, 6, "k", axis="h", polish=0.8)                             # barrel
    d.cyl(110, 24, 74, 4, 5, "k", axis="h", polish=0.8)                             # magazine tube
    fe = Mask(d.W, d.H).poly([(112, 23), (156, 23), (158, 31), (114, 32)]).get()
    d.slab(fe, 8, "d", bevel=3, polish=0.35); d.grain_wood(fe, scale=0.6, seed=8)
    d.slab(Mask(d.W, d.H).rect(180, 23, 4, 6).get(), 7, "k", bevel=1)               # the band
    d.slab(Mask(d.W, d.H).rect(199, 15, 2, 4).get(), 7, "k", bevel=0.5)            # front sight
    d.slab(Mask(d.W, d.H).rect(122, 16, 3, 3).get(), 7, "k", bevel=0.5)            # rear sight
    lever = Mask(d.W, d.H).line([(78, 31), (78, 40), (88, 45), (100, 42), (104, 31)], 2.6, caps=True).get()
    d.slab(lever, 5, "k", bevel=1, polish=0.8)
    d.slab(Mask(d.W, d.H).line([(84, 31), (86, 37)], 1.8).get(), 4, "k", bevel=0.8)  # trigger
    d.dome(76, 20, 2.4, 2.4, 3, "chrome", on="add")                                  # the hammer


def capsule(d, pts, w, z, mat, polish=0.4, power=0.5):
    """a round limb or bar along pts: a true round section (height = sqrt of the distance in from the edge)"""
    m = Mask(d.W, d.H).line(pts, w).get()
    dist = E.edt(m)
    r = w / 2
    prof = np.sqrt(np.clip(1 - ((r - np.minimum(dist, r)) / r) ** 2, 0, 1)) * z
    d.h = np.where(m, np.maximum(d.h, prof), d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = polish; d.tex[m] = 0
    return m


def disc(d, cx, cy, rx, ry, z, mat, polish=0.4, on=0.0, power=0.5, clip=None):
    r2 = ((d.XX + 0.5 - cx) / rx) ** 2 + ((d.YY + 0.5 - cy) / ry) ** 2
    m = r2 <= 1
    if clip is not None: m &= clip
    d.h = np.where(m, on + np.clip(1 - r2, 0, 1) ** power * z, d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = polish; d.tex[m] = 0
    return m


@design(170, 132)
def better_bed(d):
    # the crown: a ring in the view; its points stand round the front, and the band (with its jewels) is in front of
    # their feet (the director, Nov 6: "the rim of the crown needs to be in front of the points")
    cx_, rx_ = 96, 26
    ry_ = rx_ * VIEW
    t = np.clip((d.XX + 0.5 - cx_) / rx_, -1, 1); c = np.sqrt(1 - t ** 2)
    inside = (np.abs(d.XX + 0.5 - cx_) < rx_ - 2)
    d.flat(inside & (d.YY >= 20 - ry_ * c) & (d.YY < 24 - ry_ * c), 3, "d", polish=0.3)     # the band's far side
    for a in (-62, -31, 0, 31, 62):
        px_ = cx_ + rx_ * math.sin(math.radians(a)); cc = math.cos(math.radians(a))
        base = 24 + ry_ * cc
        tip = base - 16 * (0.75 + 0.25 * cc)
        hw = 6.0 * cc + 1.5
        d.slab(Mask(d.W, d.H).poly([(px_ - hw, base), (px_, tip), (px_ + hw, base)]).get(), 4 + 5 * cc, "m", bevel=2, polish=0.9)
        d.dome(px_, tip, 2.4, 2.4, 3, "l", on="add")                                      # the pearl on each point
    band = (np.abs(d.XX + 0.5 - cx_) < rx_) & (d.YY >= 20 + ry_ * c) & (d.YY < 30 + ry_ * c)
    d.h = np.where(band, 10 + c * 8, d.h).astype(np.float32)
    d.mat[band] = d.mid("m"); d.solid |= band; d.polish[band] = 0.9
    for e in (21, 29):
        ed = band & (np.abs(d.YY + 0.5 - (e + ry_ * c)) < 0.6); d.h[ed] += 1.0             # its rolled edges
    for a in (-50, -25, 0, 25, 50):
        cc = math.cos(math.radians(a))
        d.dome(cx_ + rx_ * math.sin(math.radians(a)), 25 + ry_ * cc, 2.2 * cc + 0.6, 2.4, 3, "chrome", on="add")

    # the bed, in the cookie box's three-quarter view (the director, Nov 6: "The bed's perspective is wrong"): one
    # set of axes for every part. Its length runs right and a little up, its width runs back and to the left, up is
    # up. The head is at the left end, the headboard across it, the footboard across the right end.
    O = np.array([46.0, 118.0]); AL = np.array([1.0, -0.18]); AW = np.array([-0.52, -0.20])
    def P(l, w, h): q = O + l * AL + w * AW; return (float(q[0]), float(q[1] - h))
    def quad(*pts): return Mask(d.W, d.H).poly(list(pts)).get()
    L, Wd = 112, 54
    # the footboard (behind the mattress at the far end of its length), then the mattress over it
    MT = 14 + 10 * 4                                                 # the mattress's top: ten layers of four
    fb = quad(P(L, 0, 4), P(L, Wd, 4), P(L, Wd, MT + 12), P(L, 0, MT + 12))
    d.ramp_h(fb, 6, 12, axis="x", mat="d", polish=0.3); d.grain_wood(fb, scale=0.5, seed=9, along="y")
    d.slab(quad(P(L, 0, MT + 12), P(L, Wd, MT + 12), P(L, Wd, MT + 15), P(L, 0, MT + 15)), 13, "d", bevel=1, polish=0.4)   # its cap rail
    # the rail and the legs
    d.slab(quad(P(0, 0, 8), P(L, 0, 8), P(L, 0, 14), P(0, 0, 14)), 12, "k", bevel=1)
    for l, w in ((L, 0), (0, 0)):
        x, y = P(l, w, 0); d.slab(Mask(d.W, d.H).rect(x - 2, y - 9, 5, 10).get(), 12, "d", bevel=1)
    # the mattress (the director, Nov 6: "make it like 10 layers ... compressed foam cushioning and 1 million rub
    # tested fabric"): its side toward us shows the ten layers, each a soft roll of foam in its fabric, light and
    # pale by turns, a welt between each; the top lit, the tufting on the top in its own grid
    for i in range(10):
        lay = quad(P(0, 0, 14 + i * 4), P(L, 0, 14 + i * 4), P(L, 0, 18 + i * 4), P(0, 0, 18 + i * 4))
        x_, y_ = P(0, 0, 18 + i * 4)
        frac = np.clip((d.YY + 0.5 - (y_ - 0.18 * (d.XX + 0.5 - x_))) / 4.0, 0, 1)
        d.h = np.where(lay, 16 + np.sin(np.pi * frac) * 1.6, d.h).astype(np.float32)
        d.mat[lay] = d.mid("w" if i % 2 else "l"); d.solid |= lay; d.polish[lay] = 0.2; d.tex[lay] = 0
        if i: d.seam(Mask(d.W, d.H).line([P(0, 0, 14 + i * 4), P(L, 0, 14 + i * 4)], 0.8).get(), 0.22)
    top = quad(P(0, 0, MT), P(L, 0, MT), P(L, Wd, MT), P(0, Wd, MT))
    d.ramp_h(top, 4, 16, axis="y", mat="w", polish=0.2)
    d.seam(Mask(d.W, d.H).line([P(0, 0, MT - 1), P(L, 0, MT - 1)], 1).get(), 0.15)            # the top's welt
    for i in range(1, 7):
        for j in (1, 2):
            x, y = P(i * L / 7, j * Wd / 3, MT); d.well(Mask(d.W, d.H).ellipse(x, y, 1.4, 0.9).get(), 1.4, bevel=1.2)
    # the label sewn on the side
    lx, ly = P(L - 30, 0, 20)
    d.slab(Mask(d.W, d.H).rect(lx, ly - 10, 18, 9).get(), 17.5, "d", bevel=0.6, polish=0.3)
    d.text("2000", int(round(lx + 9)), int(round(ly - 8)), "pw", align="c")
    # the pillow: a soft box lying on the top by the head, its corners pulled in, puffed in the middle
    pl = [(3, 4), (30, 4), (30, Wd - 4), (3, Wd - 4)]
    cushion = Mask(d.W, d.H)
    pts = []
    for (l0, w0), (l1, w1) in zip(pl, pl[1:] + pl[:1]):
        for k in range(8):
            u = k / 8; l = l0 + (l1 - l0) * u; w = w0 + (w1 - w0) * u
            pull = 2.5 * math.sin(math.pi * u)                      # each edge sags in toward the middle
            l += pull * (1 if l0 == l1 and l0 == 3 else -1 if l0 == l1 else 0)
            w += pull * (1 if w0 == w1 and w0 == 4 else -1 if w0 == w1 else 0)
            pts.append(P(l, w, MT + 8))
    pm = cushion.poly(pts).get()
    front_pts = [P(3, 4, MT), P(30, 4, MT), P(30, 4, MT + 9), P(3, 4, MT + 9)]
    pm |= Mask(d.W, d.H).poly(front_pts).get()
    pdist = E.edt(pm)
    d.h = np.where(pm, 16 + np.sqrt(np.minimum(pdist, 8.0) / 8.0) * 10, d.h).astype(np.float32)
    d.mat[pm] = d.mid("w"); d.solid |= pm; d.polish[pm] = 0.3
    d.seam(Mask(d.W, d.H).line([P(16, 8, MT + 9), P(16, Wd - 8, MT + 9)], 0.8).get() & pm, 0.12)    # its middle crease
    # the headboard, across the head end, nearest us: a slab in the end's plane, its top an arch
    hb_pts = [P(-2, 0, 0)] + [P(-2, Wd * k / 16, MT + 24 + 10 * math.sin(math.pi * k / 16)) for k in range(17)] + [P(-2, Wd, 0)]
    hb = Mask(d.W, d.H).poly(hb_pts).get()
    d.ramp_h(hb, 22, 18, axis="x", mat="d", polish=0.3); d.grain_wood(hb, scale=0.5, seed=4, along="y")
    in_pts = [P(-2, 8, MT - 6)] + [P(-2, 8 + (Wd - 16) * k / 12, MT + 16 + 7 * math.sin(math.pi * k / 12)) for k in range(13)] + [P(-2, Wd - 8, MT - 6)]
    d.well(Mask(d.W, d.H).poly(in_pts).get(), 1.4, bevel=1.2)                                  # its raised panel
    hb_edge = quad(P(-2, 0, 0), P(0, 0, 0), P(0, 0, MT + 24), P(-2, 0, MT + 24))
    d.slab(hb_edge, 23, "k", bevel=0.8)                                                        # its edge toward us


@design(150, 150)
def zacs(d):
    # the padlock alone (the director, Nov 6: "Just ditch the nails, ditch the hammer, just the padlock"), bigger:
    # the shackle into its top, the top seen from above, the brass body of laminated plates, the keyhole
    cx = 75
    m = Mask(d.W, d.H).arc(cx, 46, 30, 34, 180, 360, 11).get()
    dist = E.edt(m); d.h = np.where(m, 17 + np.sqrt(np.clip(1 - ((5.5 - np.minimum(dist, 5.5)) / 5.5) ** 2, 0, 1)) * 7, d.h).astype(np.float32)   # (at the legs' height)
    d.mat[m] = d.mid("chrome"); d.solid |= m; d.polish[m] = 1.0
    lid = Mask(d.W, d.H).poly([(cx - 46, 56), (cx + 46, 56), (cx + 50, 66), (cx - 50, 66)]).get()
    d.ramp_h(lid, 10, 18, axis="y", mat="m", polish=0.8)                                   # the body's top, from above
    # the shackle's legs run down into their holes in the top (the director, Nov 6: "The actual hook is not connected
    # ... It's outside of the holes. It's sitting behind it"): each hole a dark oval a little wider than the leg, the leg
    # standing in it, the hole's front lip across the leg's foot
    X = d.XX + 0.5; Y = d.YY + 0.5
    for x in (cx - 30, cx + 30):
        d.well(Mask(d.W, d.H).ellipse(x, 61, 7, 2.8).get(), 3, mat="k", bevel=1)
        front = 61 + 2.8 * np.sqrt(np.clip(1 - ((X - x) / 7) ** 2, 0, 1)) - 1.2               # the lip, a little in
        d.cyl(x - 5.5, 44, 11, 22, 7, "chrome", axis="v", polish=1.0, on=17, mask=(Y < front))
    body = Mask(d.W, d.H).rrect(cx - 50, 64, 100, 80, 8).get()
    d.slab(body, 14, "m", bevel=7, polish=0.8, on=4)
    for yy in range(72, 140, 7):
        d.seam(Mask(d.W, d.H).rect(cx - 46, yy, 92, 1).get(), 0.18)                          # the laminated plates
    d.slab(Mask(d.W, d.H).rrect(cx - 18, 82, 36, 46, 5).get(), 2, "chrome", bevel=2, polish=1.0, on="add")   # the plate
    kh = Mask(d.W, d.H).ellipse(cx, 98, 6, 6).poly([(cx - 3.5, 100), (cx + 3.5, 100), (cx + 6, 120), (cx - 6, 120)]).get()
    d.well(kh, 6, mat="k", bevel=1.0)
    d.text("ZAC'S", cx, 134, "d", align="c", raise_=0.6, font="57")


@design(140, 92)
def body_chisel(d):
    # square to us, from a little above (the director, Nov 6: the ends sat behind the plates they hold): each plate
    # is a disc on edge, its rim toward us and its top edge seen from above; the bar runs through; the collars and the
    # sleeves' ends sit outside the plates, in front of nothing, holding them on
    capsule(d, [(4, 48), (136, 48)], 7, 6, "chrome", polish=1.0)                              # the bar
    knurl = (d.XX >= 52) & (d.XX < 88) & (np.abs(d.YY - 48) < 2.5) & (((d.XX + d.YY) % 2) == 0)
    d.dark[knurl] = 0.2
    def plate(x, w, R):
        # the plate's rim, round across its face's width, its top edge an ellipse (the disc seen from above)
        rim = Mask(d.W, d.H).rrect(x, 48 - R, w, 2 * R, 3).get()
        t = (d.XX + 0.5 - (x + w / 2)) / (w / 2)
        d.h = np.where(rim, 10 + np.sqrt(np.clip(1 - t ** 2, 0, 1)) * 4, d.h).astype(np.float32)
        d.mat[rim] = d.mid("k"); d.solid |= rim; d.polish[rim] = 0.5
        top = ellipse_m(d, x + w / 2, 48 - R + 1, w / 2, w / 2 * VIEW + 1) & (d.YY < 48 - R + 2)
        d.flat(top, 15, "m", polish=0.4)
        for k in range(1, 4):
            d.seam(Mask(d.W, d.H).rect(x + 1, 48 - R + k * (2 * R) // 4, w - 2, 1).get(), 0.08)
    for x, w, R in ((20, 10, 38), (31, 8, 30), (101, 8, 30), (110, 10, 38)):
        plate(x, w, R)
    for x0, x1 in ((12, 19), (121, 128)):
        d.cyl(x0, 40, x1 - x0, 16, 12, "chrome", axis="v", polish=1.0)                        # the collars, outside
        d.slab(Mask(d.W, d.H).rect(x0 + 2, 39, x1 - x0 - 4, 2).get(), 13, "chrome", bevel=0.8)
        d.seam(Mask(d.W, d.H).rect(x0, 46, x1 - x0, 1).get(), 0.3)                            # the set screw's line
    for x0 in (4, 129):
        d.cyl(x0, 43, 7, 10, 9, "chrome", axis="h", polish=1.0)                                # the sleeves' ends


@design(120, 118)
def salt_river(d):
    # a hook lying on its side with its line (the director, Nov 6: "Fishing, maybe a hook laying with the line"):
    # the J hook tipped over (shank, bend, point and barb, the eye), the line tied on and lying in loose loops, a
    # bobber and a split shot on it
    INK_ = tuple(int(v) for v in INK)
    ang = math.radians(-58); ca, sa = math.cos(ang), math.sin(ang)
    def R(x, y, cx=52, cy=50): x -= cx; y -= cy; return (cx + x * ca - y * sa + 4, cy + x * sa + y * ca + 6)
    def line(pts, w=1.0):
        m = Mask(d.W, d.H).line(pts, w).get()
        d.emit[m, :3] = INK_; d.emit[m, 3] = 255                                            # the line: ink, no edge
        return m
    shank = [(70, 14), (70, 70)]
    bend = [(52 + 18 * math.cos(math.radians(a)), 70 + 18 * math.sin(math.radians(a))) for a in range(0, 181, 10)]
    point = [(34, 70), (34, 46)]
    capsule(d, [R(*q) for q in shank + bend[1:] + point[1:]], 4.0, 4, "chrome", polish=1.0)
    d.slab(Mask(d.W, d.H).poly([R(34, 38), R(30.5, 50), R(34, 54)]).get(), 4, "chrome", bevel=1, polish=1.0)   # the point
    d.slab(Mask(d.W, d.H).poly([R(35, 51), R(41, 58), R(35, 57)]).get(), 3.6, "chrome", bevel=0.8, polish=1.0) # the barb
    ex, ey = R(70, 8)
    d.torus(ex, ey, 3, 7, 4, "chrome", polish=1.0)                                             # the eye
    # the line: the knot through the eye, then loose loops lying out to the right and down
    kx, ky = R(73, 2)
    line([R(70, 2), (kx, ky), R(76, 8)], 1.3)
    # off the eye and away from the hook: down the left side in a slack curve, one loose loop at the bottom
    x0, y0 = R(76, 8)
    ctrl = [(x0, y0), (x0 - 10, y0 + 4), (20, 30), (16, 52), (18, 74), (28, 92), (44, 98), (52, 88), (40, 80), (28, 88),
            (30, 104), (52, 112), (78, 110), (100, 114)]
    pts = []
    C = [ctrl[0]] + ctrl + [ctrl[-1]]
    for i in range(1, len(C) - 2):
        p0, p1, p2, p3 = map(np.array, (C[i - 1], C[i], C[i + 1], C[i + 2]))
        for k in range(10):
            t = k / 10
            pts.append(tuple(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t ** 2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3)))
    line(pts, 1.0)
    bx, by = pts[36]
    d.dome(bx, by - 4, 6.5, 5.5, 7, "w", polish=0.9)                                           # the bobber's top half
    d.dome(bx, by + 4, 6.5, 5.5, 7, "d", polish=0.9)                                           # and its bottom
    d.slab(Mask(d.W, d.H).rect(bx - 6.5, by - 0.5, 13, 1).get(), 7.2, "k", bevel=0.5)
    capsule(d, [(bx + 6, by - 8), (bx + 9, by - 12)], 1.8, 2, "k")                             # its peg
    sx, sy = pts[112]
    d.dome(sx, sy, 3.2, 3.0, 3, "chrome", polish=1.0)                                          # the split shot
@design(120, 140)
def pioneer(d):
    # the cookie box in three-quarter: front, side and top, the troop's pine on the front
    front = Mask(d.W, d.H).poly([(40, 30), (106, 18), (106, 106), (40, 120)]).get()
    side = Mask(d.W, d.H).poly([(14, 22), (40, 30), (40, 120), (14, 110)]).get()
    top = Mask(d.W, d.H).poly([(14, 22), (82, 8), (106, 18), (40, 30)]).get()
    d.ramp_h(front, 10, 10, axis="x", mat="w", polish=0.3)
    d.ramp_h(side, 2, 10, axis="x", mat="m", polish=0.3)
    d.ramp_h(top, 12, 10, axis="y", mat="w", polish=0.3)
    d.h[top] = 10 + (d.YY[top] - 8) * -0.0 + 4
    # the print lies in the front face's plane: everything on it drops 12 px over the face's 66 px (its top edge's slope)
    def onface(m):
        out = np.zeros_like(m)
        for x in range(d.W):
            dy = int(round(-12.0 * (x - 40) / 66.0))
            col = m[:, x]
            if dy < 0: out[:dy, x] = col[-dy:]
            elif dy > 0: out[dy:, x] = col[:-dy]
            else: out[:, x] = col
        return out & front
    tree = Mask(d.W, d.H).poly([(73, 38), (63, 56), (69, 56), (59, 72), (66, 72), (55, 90), (91, 90), (80, 72), (87, 72), (77, 56), (83, 56)]).get()
    trunk = Mask(d.W, d.H).rect(70, 90, 6, 7).get()
    d.paint(onface(tree | trunk), "d")
    t1 = np.zeros((d.H, d.W), bool); t2 = np.zeros((d.H, d.W), bool)
    g = glyphs("PIONEER"); t1[103:108, 73 - g.shape[1] // 2:73 - g.shape[1] // 2 + g.shape[1]] = g
    g = glyphs("COOKIES"); t2[110:115, 73 - g.shape[1] // 2:73 - g.shape[1] // 2 + g.shape[1]] = g
    d.paint(onface(t1 | t2), "p")
    band_ = np.zeros((d.H, d.W), bool); band_[30:36, 40:107] = True
    d.paint(onface(band_), "d")                                                               # the band across the top
    # cookies, stacked in front: each a short cylinder in the view, its top a level circle
    for i, (cx, base) in enumerate(((22, 132), (22, 127), (22, 122), (53, 133))):
        body, top = cyl_v(d, cx - 15, cx + 15, base - 4, base, 3, "m", polish=0.2, top_ry=15 * VIEW, bot_ry=15 * VIEW, on=12 + i * 2)
        d.grain_pebble(body | top, 0.12, seed=20 + i)
        for k in range(5):
            jx = cx - 9 + (k * 37 % 18); jy = base - 4 - 2 + (k * 11 % 4)
            d.paint((np.hypot(d.XX - jx, (d.YY - jy) * 1.6) < 1.4) & top, "k")             # the chips


@design(130, 140)
def maps(d):
    disc(d, 65, 10, 6, 6, 4, "m", polish=0.9)                                                  # the bail
    d.well(Mask(d.W, d.H).ellipse(65, 10, 2.5, 2.5).get(), 3, bevel=1)
    rim = (np.hypot(d.XX + 0.5 - 65, d.YY + 0.5 - 72) <= 62) & (d.YY < 76)
    d.flat(rim, 4, "m", polish=0.6); d.dark[rim] = 0.12                                       # the case's top edge, its depth
    d.torus(65, 76, 50, 62, 9, "m", polish=0.9)                                                # the brass case
    disc(d, 65, 76, 50, 50, 3, "w", polish=0.2, power=2)                                      # the card
    for a in range(0, 360, 10):
        r0 = 42 if a % 90 else 36
        x0, y0 = 65 + r0 * math.cos(math.radians(a)), 76 + r0 * math.sin(math.radians(a))
        x1, y1 = 65 + 47 * math.cos(math.radians(a)), 76 + 47 * math.sin(math.radians(a))
        d.paint(Mask(d.W, d.H).line([(x0, y0), (x1, y1)], 1.1 if a % 30 else 1.8).get(), "p")
    for t, x, y in (("N", 65, 38), ("S", 65, 108), ("E", 98, 74), ("W", 32, 74)):
        d.text(t, x, y, "p", align="c", font="57")
    ang = math.radians(-70)                       # north points a little east of up (the needle settles; the card is the map's)
    ux, uy = math.cos(ang), math.sin(ang); px_, py_ = -uy, ux
    P = lambda r, w: (65 + ux * r + px_ * w, 76 + uy * r + py_ * w)
    north = Mask(d.W, d.H).poly([P(40, 0), P(0, 6), P(0, -6)]).get()
    south = Mask(d.W, d.H).poly([P(-40, 0), P(0, 6), P(0, -6)]).get()
    d.slab(north, 3, "k", bevel=2, polish=0.8, on=3); d.slab(south, 3, "l", bevel=2, polish=0.8, on=3)
    d.dome(65, 76, 3.5, 3.5, 4, "chrome", on=6)


@design(170, 62)
def xray(d):
    for cx in (48, 122):
        disc(d, cx, 32, 24, 24, 3, "l", polish=1.0, power=2)                                  # the lens
        T = 7.0 * math.pi
        t = np.linspace(0.4, T, 400)
        pts = [(cx + (1.0 + 20.0 * tt / T) * math.cos(tt), 32 + (1.0 + 20.0 * tt / T) * math.sin(tt)) for tt in t]
        d.paint(Mask(d.W, d.H).line(pts, 1.6).get() & (np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - 32) < 22), "p")
        d.torus(cx, 32, 22, 28, 6, "k", polish=0.8)                                           # the rim
    capsule(d, [(74, 28), (84, 22), (96, 28)], 4, 4, "k", polish=0.8)                          # bridge
    capsule(d, [(22, 26), (20, 17)], 2.2, 2, "d", polish=0.6)                                  # the temples, running back
    capsule(d, [(148, 26), (150, 17)], 2.2, 2, "d", polish=0.6)
    for hx_ in (21, 149): d.dome(hx_, 27, 3, 3, 7, "k", polish=0.8)                           # the hinges


@design(112, 104)
def iron_mike(d):
    # a flexed right arm, the strongman's pose (the director, Nov 6: "that arm is rough. That does not look like a
    # flexing arm"): built as one smooth body from its muscles (signed distances, blended), so the outline runs
    # clean: the upper arm level out of the sleeve, the biceps' high peak, the elbow, the forearm up, the fist on top
    X = d.XX + 0.5; Y = d.YY + 0.5
    def cap(ax, ay, bx, by, ra, rb):
        px, py = X - ax, Y - ay; vx, vy = bx - ax, by - ay
        t = np.clip((px * vx + py * vy) / (vx * vx + vy * vy), 0, 1)
        return np.hypot(px - vx * t, py - vy * t) - (ra + (rb - ra) * t)
    def ell(cx, cy, rx, ry):
        k = np.hypot((X - cx) / rx, (Y - cy) / ry)
        return (k - 1) * min(rx, ry)
    def rbox(cx, cy, hx, hy, r):
        qx = np.abs(X - cx) - hx + r; qy = np.abs(Y - cy) - hy + r
        return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r
    def smin(a, b, k=6.0):
        h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
        return b * (1 - h) + a * h - k * h * (1 - h)
    parts = [cap(0, 82, 66, 86, 15, 12),          # the upper arm
             ell(40, 70, 24, 16),                 # the biceps
             cap(0, 74, 12, 72, 16, 14),          # the deltoid
             cap(80, 84, 79, 38, 13, 8.5),        # the forearm
             ell(84, 64, 10, 19),                 # its muscle by the elbow
             rbox(78, 22, 14, 13, 9)]             # the fist
    sd = parts[0]
    for q in parts[1:]: sd = smin(sd, q)
    arm = sd < 0
    depth = np.clip(-sd, 0, 12) / 12
    d.h = np.where(arm, np.sqrt(depth) * 18, d.h).astype(np.float32)
    d.mat[arm] = d.mid("m"); d.solid |= arm; d.polish[arm] = 0.5
    # the biceps stand a little prouder than the rest, and a crease where they meet the forearm
    bic = np.clip(-ell(40, 70, 26, 20), 0, 16) / 16
    d.h = np.where(arm, d.h + bic * bic * (3 - 2 * bic) * 7, d.h).astype(np.float32)        # the biceps, one smooth swell
    d.seam(Mask(d.W, d.H).line([(60, 66), (66, 58), (70, 48)], 1.0).get() & arm, 0.4)
    d.seam(Mask(d.W, d.H).arc(86, 96, 9, 6, 200, 300, 1.0).get() & arm, 0.25)                 # the elbow's point
    # the muscle under the biceps (the director, Nov 6: "a little too flat"): the triceps' long belly along the
    # underside of the upper arm, and the forearm's swell over the elbow
    tri = np.clip(-ell(40, 94, 28, 9), 0, 6) / 6
    d.h = np.where(arm, d.h + tri * tri * (3 - 2 * tri) * 4, d.h).astype(np.float32)
    fore = np.clip(-ell(84, 66, 9, 17), 0, 6) / 6
    d.h = np.where(arm, d.h + np.sqrt(fore) * 3, d.h).astype(np.float32)
    # the fist (the director, Nov 6: "you should be able to see some fingers curling"): the back of the hand to the
    # right, and toward us the four fingers curled over, each its own roll with its knuckle, stacked from the index at
    # the top to the little finger at the wrist, their tips tucked in; the thumb laid across the middle two, its nail
    fist = (rbox(78, 22, 14, 13, 9) < 0) & arm
    base = d.h.copy()
    d.h = np.where(fist, 12 + np.sqrt(np.clip(-rbox(78, 22, 14, 13, 9), 0, 6) / 6) * 6, d.h).astype(np.float32)
    for k, (y, ln) in enumerate(((12.5, 19), (18.5, 20), (24.5, 19), (30, 15))):
        r = 3.1 if k < 3 else 2.6
        f = cap(66 + (20 - ln) * 0.4, y, 66 + ln, y - 0.6, r, r) < 0
        prof = np.sqrt(np.clip(-cap(66 + (20 - ln) * 0.4, y, 66 + ln, y - 0.6, r, r), 0, r) / r)
        d.h = np.where(f, 15 + prof * 6, d.h).astype(np.float32)
        d.mat[f] = d.mid("m"); d.solid |= f; d.polish[f] = 0.5
        kx = 66 + ln - 1
        d.dome(kx, y - 0.4, 2.6, r * 0.9, 1.5, "m", on="add", polish=0.7)                    # its knuckle
        d.seam(Mask(d.W, d.H).line([(64 + (20 - ln) * 0.4 + 6, y - 2), (64 + (20 - ln) * 0.4 + 6, y + 2)], 0.7).get() & f, 0.25)  # the middle joint's fold
    thumb = cap(63, 25, 83, 21, 3.9, 3.3)
    tm = thumb < 0
    d.h = np.where(tm, 23 + np.sqrt(np.clip(-thumb, 0, 3.6) / 3.6) * 5, d.h).astype(np.float32)
    d.mat[tm] = d.mid("l"); d.solid |= tm; d.polish[tm] = 0.6
    d.dark[(thumb > -0.9) & (thumb < 0) & (d.YY > 21)] = 0.35                                 # its lower edge, over the fingers
    nail = Mask(d.W, d.H).ellipse(81, 21, 2.4, 1.7).get() & tm
    d.mat[nail] = d.mid("w")                                                                   # the thumbnail
    # the hand runs smooth into the wrist: no shadow from it on the forearm, only the wrist's turn
    d.noshadow[arm & (d.YY >= 30)] = True
    # the heel of the hand and the wrist: one surface; the fingers' own rolls stop at the little finger, and below it
    # the hand meets the forearm at the same height (no step, so no shade line across the wrist)
    wr = arm & (d.YY >= 31) & (d.YY <= 44) & ~tm
    fz = np.sqrt(np.clip(-sd, 0, 12) / 12) * 18
    w_ = np.clip((d.YY - 31) / 6.0, 0, 1)                                                  # the hand's heel, easing into it
    d.h = np.where(wr, d.h * (1 - w_) + fz * w_, d.h).astype(np.float32)
    d.mat[wr] = d.mid("m")
    # the T-shirt's sleeve at the shoulder
    sl = arm & (X < 15)
    d.mat[sl] = d.mid("w"); d.h[sl] += 2
    d.seam(Mask(d.W, d.H).line([(15, 50), (15, 104)], 1.2).get() & (arm | sl), 0.5)
    d.seam(Mask(d.W, d.H).line([(11, 52), (11, 104)], 0.7).get() & sl, 0.2)                   # its hem's stitching
@design(72, 46)
def safari(d):
    disc(d, 36, 36, 35, 35 * VIEW, 4, "l", polish=0.3)                                         # the brim
    t = np.clip((d.XX + 0.5 - 36) / 24, -1, 1); c = np.sqrt(1 - t ** 2)
    r2 = ((d.XX + 0.5 - 36) / 24) ** 2 + ((d.YY + 0.5 - 34) / 30) ** 2
    crown = (r2 <= 1) & (d.YY < 34 + 24 * VIEW * c)
    d.h = np.where(crown, 4 + np.sqrt(np.clip(1 - r2, 0, 1)) * 22, d.h).astype(np.float32)
    d.mat[crown] = d.mid("l"); d.solid |= crown; d.polish[crown] = 0.3
    d.grain_pebble(crown, 0.05, seed=4)
    pug = crown & (d.YY >= 27 + 24 * VIEW * c) & (d.YY < 33 + 24 * VIEW * c)
    d.mat[pug] = d.mid("d"); d.h[pug] += 1.0                                                   # the band, round the crown
    d.dome(36, 5, 4, 4 * VIEW + 1.5, 3, "l", on="add", polish=0.5)
    for k in (-2, -1, 1, 2):
        a = k * 0.55
        d.seam(Mask(d.W, d.H).line([(36 + 4 * math.sin(a), 6), (36 + 23 * math.sin(a), 26 + 6 * math.cos(a))], 0.8).get() & crown, 0.18)


@design(120, 104)
def brine(d):
    gb, gt = cyl_v(d, 32, 88, 90, 94, 4, "m", polish=0.6, top_ry=28 * VIEW, bot_ry=28 * VIEW)   # the glass foot, under the bowl
    r2 = ((d.XX + 0.5 - 60) / 56) ** 2 + ((d.YY + 0.5 - 54) / 42) ** 2
    bowl = (r2 <= 1) & (d.YY >= 16)
    d.h = np.where(bowl, np.sqrt(np.clip(1 - r2, 0, 1)) * 26, d.h).astype(np.float32)
    d.mat[bowl] = d.mid("w"); d.solid |= bowl; d.polish[bowl] = 1.0
    wl = 40 + 50 * VIEW * np.sqrt(np.clip(1 - ((d.XX + 0.5 - 60) / 50) ** 2, 0, 1))
    water = bowl & (d.YY >= wl)
    d.mat[water] = d.mid("l")
    d.paint(bowl & (np.abs(d.YY + 0.5 - wl) < 0.7), "d")
    back = bowl & (np.abs(d.YY + 0.5 - (40 - 50 * VIEW * np.sqrt(np.clip(1 - ((d.XX + 0.5 - 60) / 50) ** 2, 0, 1)))) < 0.6)
    d.paint(back, "m")                                                                       # the surface's far edge, through the glass
    lip = Mask(d.W, d.H).ellipse(60, 16, 30, 30 * VIEW).get() & ~Mask(d.W, d.H).ellipse(60, 16, 26, 26 * VIEW).get()
    d.slab(lip, 4, "l", bevel=1.5, polish=1.0, on=8)
    # sea monkeys (brine shrimp, the director, Nov 6: "they're not supposed to be fish"): each a long curled body of
    # rings, a fringe of little legs along the belly, a forked tail, a head with two eyes on stalks and a feeler
    # drawn as print on the glass's own light, not as raised parts: a curled body of rings, the legs a fringe under
    # it, a forked tail, the head with two eyes on stalks and a feeler, all in the tank's light
    def pm(pts, w): return Mask(d.W, d.H).line(pts, w).get() & bowl
    def shrimp(cx, cy, sc, flip, curl):
        # a silhouette in flat ink, as the old mail-order ads printed them: the body tapering to the tail, the fork,
        # a fringe of legs, a round head, two eyes out on stalks (paper with an ink pupil), one long feeler
        pts = []
        for k in range(9):
            u = k / 8
            pts.append((cx + flip * (u - 0.5) * 22 * sc, cy - curl * 7 * sc * math.sin(math.pi * u)))
        for k in range(8):
            w = (1.6 + 2.6 * (k / 7)) * sc
            d.paint(pm([pts[k], pts[k + 1]], w), "p")
        tx, ty = pts[0]
        for dy in (-3.2, 3.2):
            d.paint(pm([(tx, ty), (tx - flip * 5.5 * sc, ty + dy * sc)], 1.3), "p")         # the forked tail
        for k in range(3, 8):
            x, y = pts[k]
            d.paint(pm([(x, y + 2 * sc), (x - flip * 1.5 * sc, y + 5.5 * sc)], 0.9), "p")    # the legs
        hx, hy = pts[-1]; hx += flip * 2.5 * sc
        d.paint(Mask(d.W, d.H).ellipse(hx, hy, 3.8 * sc, 3.4 * sc).get() & bowl, "p")       # the head
        for dy in (-1, 1):
            ex, ey = hx + flip * 5 * sc, hy + dy * 4 * sc - 1
            d.paint(pm([(hx + flip * 2 * sc, hy + dy * sc), (ex, ey)], 1.0), "p")
            d.paint(Mask(d.W, d.H).ellipse(ex, ey, 2.0, 2.0).get() & bowl, "p")
            d.paint(Mask(d.W, d.H).ellipse(ex, ey, 1.0, 1.0).get() & bowl, "pw")            # the eye
        d.paint(pm([(hx + flip * 3 * sc, hy + 2), (hx + flip * 10 * sc, hy + 6 * sc), (hx + flip * 13 * sc, hy + 3 * sc)], 0.9), "p")
    for cx, cy, sc, flip, curl in ((34, 64, 1.1, 1, 0.5), (90, 60, 1.0, -1, -0.45), (62, 84, 0.95, 1, 0.35)):
        shrimp(cx, cy, sc, flip, curl)
    gl = (np.hypot(d.XX - 34, d.YY - 44) < 18) & (np.hypot(d.XX - 31, d.YY - 41) > 16) & bowl & (d.XX < 30)
    d.mat[gl] = d.mid("pw")



# ================================================================== batch 2 (Nov 6): the fulls and the halves
@design(200, 150)
def greene(d):
    # a paper grocery sack, full: a loaf and celery standing up out of it, two cans in front (staples by the case)
    F = [(48, 40), (138, 40), (142, 140), (44, 140)]                 # the sack's front, a hair wider at the foot
    G = [(138, 40), (160, 34), (164, 132), (142, 140)]               # its gusset, turning away
    front = Mask(d.W, d.H).poly(F).get(); gus = Mask(d.W, d.H).poly(G).get()
    # what stands in it, drawn first so the sack's lip overlaps them
    loaf = Mask(d.W, d.H).rrect(66, 8, 30, 46, 12).get()
    d.slab(loaf, 14, "m", bevel=10, polish=0.3)
    for k in range(4):
        d.seam(Mask(d.W, d.H).line([(70, 16 + k * 8), (92, 12 + k * 8)], 1.2).get(), 0.35)   # the scored crust
    box = Mask(d.W, d.H).poly([(100, 14), (130, 10), (132, 50), (102, 52)]).get()           # a box of rice, leaning
    d.slab(box, 12, "l", bevel=1.5, polish=0.3)
    bside = Mask(d.W, d.H).poly([(130, 10), (138, 14), (140, 50), (132, 50)]).get()
    d.slab(bside, 8, "m", bevel=1, polish=0.3)
    d.paint(Mask(d.W, d.H).poly([(101, 22), (131, 18), (131, 30), (101, 34)]).get(), "d")
    d.text("RICE", 116, 22, "pw", align="c")
    d.ramp_h(front, 10, 10, axis="x", mat="w", polish=0.15)
    d.ramp_h(gus, 3, 10, axis="x", mat="l", polish=0.15)
    d.grain_pebble(front | gus, 0.06, seed=4)
    lip = Mask(d.W, d.H).poly([(46, 40), (140, 40), (140, 48), (46, 48)]).get()
    d.slab(lip, 12, "w", bevel=1.5, polish=0.2)                                               # the rolled lip
    d.seam(Mask(d.W, d.H).line([(150, 38), (152, 134)], 1).get(), 0.25)                      # the gusset's fold
    # the store's name printed on the sack
    d.text("GREENE'S", 93, 62, "p", font="57", align="c", scale=2)
    d.text("GROCERY", 93, 82, "p", font="57", align="c")
    d.text("SINCE 1952", 93, 94, "p", align="c")
    # two cans in front of the sack, standing on the counter
    for cx, cy in ((34, 146), (64, 148)):
        body, top = cyl_v(d, cx - 14, cx + 14, cy - 34, cy - 4, 14, "chrome", polish=0.9, top_ry=14 * VIEW, bot_ry=14 * VIEW, on=10)
        c = Cyl(d, cx - 14, cx + 14, 14 * VIEW)
        band_v(d, body, c, cy - 28, cy - 10, "d")
        print_wrap(d, body, c, "BEANS" if cx < 50 else "PEAS", cy - 23, "pw")


@design(120, 160)
def crossroads(d):
    # the mall's sign out at the road: a post at the crossroads, its arrow boards pointing every which way, a cap on top
    capsule(d, [(60, 12), (60, 158)], 7, 7, "k", polish=0.7)                                 # the post
    d.dome(60, 10, 6, 5, 6, "chrome", polish=1.0)                                             # its cap
    def board(y, x0, x1, point_right, txt, mat="w", tilt=0.0):
        # an arrow board at its own slope: the long edges, the tip on the center line carried out, and the lettering
        # (the 5 x 7 face) on that center line, each column riding the slope (the director, Nov 6: "Can the text on the
        # Crossroads Mall signs be larger and ... align perpendicular with the board that it's written on?")
        L = float(x1 - x0)
        if point_right:
            tip = x1 + 10
            def yat(x): return y + tilt * (x - x0) / L
            pts = [(x0, yat(x0)), (x1, yat(x1)), (tip, yat(tip) + 9), (x1, yat(x1) + 18), (x0, yat(x0) + 18)]
        else:
            tip = x0 - 10
            def yat(x): return y + tilt * (x1 - x) / L
            pts = [(x1, yat(x1)), (x0, yat(x0)), (tip, yat(tip) + 9), (x0, yat(x0) + 18), (x1, yat(x1) + 18)]
        m = Mask(d.W, d.H).poly(pts).get()
        d.slab(m, 10, mat, bevel=1.5, polish=0.4)
        g = glyphs(txt, "57"); gh, gw = g.shape
        xs = int(round((x0 + x1) / 2 + (4 if point_right else -4) - gw / 2))
        t = np.zeros((d.H, d.W), bool)
        for i in range(gw):
            x = xs + i
            if 0 <= x < d.W:
                ty = int(round(yat(x + 0.5) + 9 - gh / 2))
                t[ty:ty + gh, x] |= g[:, i]
        d.paint(t & m, "p" if mat != "k" else "pw")
    # the four boards (the director, Nov 6): "The top one says bones. The second one says thugs. The third one says
    # harmonies. And the fourth one says ... meet you there", each pointing its own way
    board(28, 16, 92, True, "BONES", tilt=-5)
    board(52, 26, 104, False, "THUGS", mat="k", tilt=4)
    board(76, 16, 94, True, "HARMONIES", tilt=4)
    board(102, 12, 108, False, "MEET YOU THERE", mat="k", tilt=-4)
    # the ground at the foot: a little curb
    d.slab(Mask(d.W, d.H).poly([(30, 150), (90, 150), (96, 158), (24, 158)]).get(), 4, "m", bevel=1, polish=0.2)


@design(150, 150)
def jamieton(d):
    # a gas mask, face on, drawn after the director's photo (Nov 6, 2026: ZeD_design_refs/ads/refs/gasmask_ref.jpg,
    # after "Just take another pass at the gas mask"). Every point below is the photo's (990 x 1075) mapped onto the
    # picture (P). As in the photo: a black rubber faceblank, its forehead up to the harness tabs; two big lenses, flat
    # across the top and narrowing to the nose, in thick rubber rims; the round perforated voicemitter standing out on
    # the chin; the filter canister, a big drum, screwed on the left cheek on its silver ring, its end turned out to the
    # side; the harness straps cut short, sticking out from the forehead, temples and cheeks, each through its buckle
    S_ = 0.145
    def P(x, y): return ((x - 40) * S_ + 8, (y - 25) * S_ + 1)
    def poly(*pts): return Mask(d.W, d.H).poly([P(x, y) for x, y in pts]).get()
    def rounded(m, r):
        # the corners rounded off: in by r, then out by r (the photo's lenses have no corners)
        core = E.edt(m) > r
        k = int(r) + 2                                       # (padded: the picture's edge is not a shape's edge)
        near = E.edt(np.pad(~core, k, constant_values=True))[k:-k, k:-k] <= r
        return core | near
    # the harness straps behind the faceblank, out to their serrated tabs, each through a buckle
    straps = (((300, 250), (250, 70)), ((605, 245), (645, 50)), ((215, 380), (60, 372)), ((775, 362), (860, 296)),
              ((228, 640), (152, 598)), ((772, 600), (868, 572)))
    for (p, q) in straps:
        capsule(d, [P(*p), P(*q)], 6.0, 2.5, "k", polish=0.3, power=1.0)                       # flat rubber straps
    for (x, y) in ((282, 190), (628, 185), (178, 378), (800, 340), (196, 622), (812, 590)):
        X_, Y_ = P(x, y)
        d.slab(Mask(d.W, d.H).rect(X_ - 2.5, Y_ - 2.5, 5, 5).get(), 6, "chrome", bevel=1, polish=1.0)
        d.well(Mask(d.W, d.H).rect(X_ - 1, Y_ - 1, 2, 2).get(), 3, bevel=0.5)
    # the faceblank: a shield, wide at the eyes, the forehead up to the tabs, narrowing to the chin
    face = poly((300, 262), (360, 250), (480, 246), (600, 250), (662, 262), (730, 300), (770, 350), (790, 420),
                (792, 560), (782, 650), (762, 705), (700, 765), (630, 835), (560, 900), (482, 932), (400, 902),
                (330, 832), (270, 762), (226, 702), (206, 640), (200, 560), (200, 420), (215, 350), (252, 300))
    d.slab(face, 20, "k", bevel=9, polish=0.45, power=0.5)
    d.seam(Mask(d.W, d.H).line([P(490, 256), P(490, 420)], 1).get(), 0.35)                    # the moulding's seam
    d.seam(Mask(d.W, d.H).line([P(300, 330), P(480, 318), P(680, 328)], 1).get() & face, 0.25)  # the forehead's ridge
    # the lenses in their rims: the rim a raised rubber ring, the glass set in it
    lenses = ([(232, 405), (470, 414), (495, 446), (482, 560), (455, 640), (420, 668), (300, 695), (250, 690),
               (222, 650), (212, 520), (215, 430)],
              [(515, 446), (540, 413), (760, 400), (778, 430), (784, 520), (774, 650), (746, 698), (690, 702),
               (580, 670), (548, 640), (524, 560)])
    for pts in lenses:
        rim = rounded(poly(*pts), 4.0)
        d.slab(rim, 26, "k", bevel=2.5, polish=0.6, power=0.6)
        glass = rim & (E.edt(rim) > 3.8)
        d.flat(glass, 22, "l", polish=1.0)
        xs = [x for x, _ in pts]; ys = [y for _, y in pts]
        X0, Y0 = P(min(xs), min(ys)); X1, Y1 = P(max(xs), max(ys))
        streak = Mask(d.W, d.H).line([(X0 + 5, Y0 + 9), (X0 + 11, Y0 + 5)], 1.6).get() & glass   # the sky in the glass
        d.paint(streak, "w")
        d.paint(glass & (d.YY > Y0 + (Y1 - Y0) * 0.62), "m")                                  # the dark below
    # the voicemitter on the chin: a short drum standing out, its face a grille of holes
    d.dome(*P(482, 805), 132 * S_, 130 * S_, 30, "k", polish=0.6, power=0.35)
    X_, Y_ = P(486, 816)
    face_v = ellipse_m(d, X_, Y_, 104 * S_, 104 * S_)
    d.flat(face_v, 31, "k", polish=0.5)
    for i in range(-8, 9):
        for j in range(-8, 9):
            hx, hy = X_ + i * 2 + (1 if j % 2 else 0), Y_ + j * 2                             # the grille, edge to edge
            if (hx - X_) ** 2 + (hy - Y_) ** 2 > (104 * S_ - 2.2) ** 2: continue
            d.well(Mask(d.W, d.H).rect(int(hx), int(hy), 1, 1).get(), 4, bevel=0.3)
    # the canister on the left cheek: its silver ring, the drum turned out to the side, the drum's end
    d.cyl(*P(700, 668), int(round(178 * S_)), int(round(368 * S_)), 24, "k", axis="h", polish=0.7)
    X_, Y_ = P(680, 815)
    ring = ellipse_m(d, X_, Y_, 24 * S_, 88 * S_)
    d.slab(ring, 26, "chrome", bevel=1.5, polish=1.0)
    X_, Y_ = P(872, 850)
    end = ellipse_m(d, X_, Y_, 76 * S_, 192 * S_)
    d.slab(end, 26, "k", bevel=2.5, polish=0.7, power=0.6)
    d.seam(Mask(d.W, d.H).arc(X_, Y_, 60 * S_, 160 * S_, 0, 360, 1).get(), 0.3)              # the intake's ring

@design(160, 84)
def mccoys(d):
    # a stack of 2x4s, three-quarter: their cut ends toward us in rows (each with its rings), the top boards running
    # back up and to the left (the director, Nov 6: "McCoy's lumber, just the lumber is fine. Just get rid of that saw")
    bw, bh, gap = 22, 13, 1
    DX, DY = -40, -26                                                   # the boards' length, back into the picture
    x0, y0 = 54, 38
    rows = [(0, 4), (1, 4), (2, 3)]                                     # (row from the bottom, boards in it)
    for r, n in rows:
        y = y0 + 2 * (bh + gap) - r * (bh + gap)
        xs = x0 + (4 - n) * (bw + gap) // 2
        for k in range(n):
            x = xs + k * (bw + gap)
            if r == 2 or (r == 1 and k in (0, 3)) or True:
                top = Mask(d.W, d.H).poly([(x, y), (x + bw, y), (x + bw + DX, y + DY), (x + DX, y + DY)]).get()
                d.flat(top, 10 + r * 2, "m", polish=0.3); d.grain_wood(top, scale=0.6, seed=7 + k + r * 5, along="x")
            if k == 0:
                side = Mask(d.W, d.H).poly([(x, y), (x + DX, y + DY), (x + DX, y + bh + DY), (x, y + bh)]).get()
                d.flat(side, 4 + r * 2, "d", polish=0.3); d.grain_wood(side, scale=0.6, seed=3 + r, along="x")
            end = Mask(d.W, d.H).rect(x, y, bw, bh).get()
            d.slab(end, 14 + r * 2, "l", bevel=0.8, polish=0.2)
            cx, cy = x + bw * (0.2 + 0.6 * ((k + r) % 2)), y + bh * 1.6
            for rr in range(3, 30, 3):
                ring = end & (np.abs(np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy) - rr) < 0.55)
                d.dark[ring] = np.maximum(d.dark[ring], 0.22)


@design(130, 140)
def pharmahug(d):
    # a prescription bottle with its child-safe cap and label, two tablets and a capsule spilled in front
    body, top = cyl_v(d, 26, 92, 34, 124, 24, "d", polish=0.9, top_ry=0, bot_ry=33 * VIEW)   # the amber bottle
    cy = Cyl(d, 26, 92, 33 * VIEW)
    lab = band_v(d, body, cy, 58, 104, "w")
    print_wrap(d, body, cy, "PHARMAHUG", 62, "p")
    print_wrap(d, body, cy, "RX 26001", 72, "p")
    print_wrap(d, body, cy, "TAKE 1 DAILY", 82, "p")
    print_wrap(d, body, cy, "WITH FOOD", 90, "p")
    capb, capt = cyl_v(d, 22, 96, 18, 36, 26, "w", polish=0.4, top_ry=37 * VIEW, bot_ry=37 * VIEW)   # the cap
    cc = Cyl(d, 22, 96, 37 * VIEW)
    for k in range(0, 74, 3):
        rib = capb & (np.abs(cc.u - (k - 37)) < 0.6)
        d.dark[rib] = 0.18                                                                  # the grip ribs
    d.text("PUSH DOWN", 59, 26 - 9, "p", align="c")
    # tablets and a capsule in front, lying on the counter (level circles)
    for cx, cy_ in ((100, 128), (114, 134)):
        disc(d, cx, cy_, 7, 7 * VIEW + 1.2, 3, "w", polish=0.5, on=2)
        d.seam(Mask(d.W, d.H).line([(cx - 5, cy_), (cx + 5, cy_)], 1).get(), 0.25)           # the score
    capsule(d, [(10, 132), (24, 128)], 6, 5, "l", polish=0.9)
    capsule(d, [(17, 130), (24, 128)], 6, 5, "d", polish=0.9)


# ================================================================== batch 3 (Nov 6): the thirds
@design(130, 140)
def knobcreek(d):
    # a whitetail's rack on a wooden plaque (the director, Nov 6: "the hunting trophy needs another pass"): the shield
    # plaque with its routed edge; the skull plate covered in leather; from each burr the main beam sweeps out, up and
    # in, and the tines rise straight up off it (brow tine low, the long G2 and G3); antler pale, darker at the bases
    X = d.XX + 0.5; Y = d.YY + 0.5
    plaque = Mask(d.W, d.H).poly([(36, 74), (94, 74), (98, 84), (96, 108), (65, 136), (34, 108), (32, 84)]).get()
    d.slab(plaque, 8, "d", bevel=4, polish=0.5); d.grain_wood(plaque, scale=0.6, seed=12, along="y")
    inner = Mask(d.W, d.H).poly([(42, 80), (88, 80), (90, 106), (65, 128), (40, 106)]).get()
    d.slab(inner, 10, "d", bevel=2, polish=0.6, on=1)
    d.dome(65, 86, 16, 11, 9, "k", polish=0.3, on=10)                                        # the leather-covered skull plate
    for k in range(6):
        d.seam(Mask(d.W, d.H).rect(52 + k * 5, 94, 2, 1).get(), 0.4)                         # its stitching
    for side in (-1, 1):
        P = lambda x, y: (65 + side * x, y)
        d.dome(*P(11, 80), 5, 4, 6, "m", polish=0.2, on=14)                                   # the burr
        d.grain_pebble(Mask(d.W, d.H).ellipse(*P(11, 80), 5, 4).get(), 0.25, seed=4)
        beam = [P(12, 78), P(26, 74), P(40, 64), P(48, 48), P(48, 32), P(42, 18), P(34, 10)]
        capsule(d, beam[:3], 7, 9, "m", polish=0.45)
        capsule(d, beam[2:5], 6, 8, "l", polish=0.45)
        capsule(d, beam[4:], 4.6, 7, "l", polish=0.5)
        for (bx, by), (tx, ty), w in (((17, 77), (19, 60), 4.0), ((30, 72), (28, 34), 4.6), ((43, 58), (36, 22), 4.2)):
            capsule(d, [P(bx, by), P(tx, ty)], w, 8, "l", polish=0.5)                         # the tines, straight up
            d.dome(*P(tx, ty), w / 2, w / 2, 8, "w", polish=0.6)                              # their polished tips
        d.dome(*P(34, 10), 2.3, 2.3, 7, "w", polish=0.6)

@design(150, 84)
def aaron(d):
    # a hand-carved wooden decoy, side on and a little from above, facing right (the director's references, Nov 6):
    # a low loaf of a body with a flat bottom, the chest full and round, the tail rising to a blunt point; the round
    # head set right down on the body at a carved seam, no neck to speak of; the bill straight out; a glass eye; worn
    # dark paint with the white flank, the wing patch and carved feather scallops on the back, chips showing the wood
    X = d.XX + 0.5; Y = d.YY + 0.5
    def sd_ell(cx, cy, rx, ry):
        k = np.hypot((X - cx) / rx, (Y - cy) / ry); return (k - 1) * min(rx, ry)
    def smin(a, b, k=6.0):
        h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1); return b * (1 - h) + a * h - k * h * (1 - h)
    body = smin(sd_ell(72, 54, 54, 23), sd_ell(24, 44, 22, 8), 9)           # the loaf and the tail sweeping up behind
    body = np.maximum(body, Y - 72)                                         # the flat bottom it floats on
    m = body <= 0
    dist = E.edt(m)
    rb = ((X - 72) / 54) ** 2 + ((Y - 50) / 26) ** 2                       # a rounded back, lit from above
    d.h = np.where(m, np.sqrt(np.clip(1 - rb, 0, 1)) * 18 + np.sqrt(np.clip(dist / 8.0, 0, 1)) * 6, d.h).astype(np.float32)
    d.mat[m] = d.mid("k"); d.solid |= m; d.polish[m] = 0.35; d.tex[m] = 0
    flank = m & (sd_ell(44, 64, 34, 8) <= 0) & (X < 76)
    d.paint(flank, "w")                                                     # the white flank, low on the side, rear
    d.paint(m & (sd_ell(46, 46, 11, 3) <= 0), "l")                          # the wing patch
    for k in range(5):                                                       # carved feather scallops on the back
        cx_ = 48 + k * 12
        arc = m & (np.abs(np.hypot(X - cx_, (Y - 43) * 1.6) - 8) < 0.75) & (Y < 45) & (Y > 34)
        d.dark[arc] = np.maximum(d.dark[arc], 0.3)
    for (cx_, cy_, r) in ((36, 54, 3.5), (92, 62, 2.5), (74, 44, 3)):         # worn chips: the wood shows
        d.paint(m & (np.hypot(X - cx_, (Y - cy_) * 1.3) < r), "m")
    d.grain_pebble(m, 0.08, seed=21)
    # the head: round, set down on the chest at a seam, the bill straight out
    hm = sd_ell(112, 28, 15, 14) <= 0
    hd = E.edt(hm)
    d.h = np.where(hm, 20 + np.sqrt(np.clip(hd / 9.0, 0, 1)) * 12, d.h).astype(np.float32)
    d.mat[hm] = d.mid("k"); d.solid |= hm; d.polish[hm] = 0.4
    d.seam(Mask(d.W, d.H).arc(110, 41, 13, 3, 0, 180, 1.2).get() & hm, 0.4)  # the seam where it sits on the body
    bill = Mask(d.W, d.H).poly([(122, 24), (146, 28), (148, 32), (144, 35), (122, 36)]).get()
    d.slab(bill, 30, "m", bevel=3, polish=0.4)
    d.seam(Mask(d.W, d.H).line([(123, 30), (144, 32)], 1).get(), 0.3)       # the bill's parting line
    d.dome(116, 24, 2.6, 2.6, 2, "l", polish=1.0, on="add")                 # the glass eye
    d.paint(Mask(d.W, d.H).ellipse(116.3, 24.3, 1.1, 1.1).get(), "p")
    d.paint(hm & (np.hypot(X - 104, (Y - 18) * 1.4) < 3), "m")              # a chip on the crown


def outline(d, path, x0, y0, h):
    """a mask from a picture (white = in) scaled to `h` pixels tall, its top-left at (x0, y0): each pixel in if most of
    the picture under it is"""
    src = Image.open(os.path.join(HERE, path)).convert("L")
    w = max(1, int(round(src.width * h / src.height)))
    a = np.asarray(src.resize((w, h), Image.BOX)) >= 128
    m = np.zeros((d.H, d.W), bool)
    xa, ya = max(0, x0), max(0, y0)
    xb, yb = min(d.W, x0 + w), min(d.H, y0 + h)
    m[ya:yb, xa:xb] = a[ya - y0:yb - y0, xa - x0:xb - x0]
    return m


@design(110, 140)
def westpoint(d):
    # a silhouette target (the director, Nov 6: "the shooting target is weird", then: "Use one of the character outlines
    # from one of the avatars"): a sheet of white paper hung from two clips on the range's carrier wire; printed on it in
    # black, the outline of the game's own man, cut from ZeD's equipment doll (refs/avatar_outline.png, made by
    # target_outline.py: ball cap, neck, the vest's shoulders, arms down, cut at the hips); the scoring rings as white
    # ovals on his chest with their numbers, a ring on the head; a tight group in the ten, one flier, and one in the head
    X = d.XX + 0.5; Y = d.YY + 0.5
    capsule(d, [(0, 6), (110, 6)], 2, 2, "chrome", polish=1.0)                                 # the carrier's wire
    sheet = Mask(d.W, d.H).rect(8, 12, 94, 126).get()
    d.slab(sheet, 4, "w", bevel=0.6, polish=0.1)
    for cx_ in (24, 86):
        d.slab(Mask(d.W, d.H).rect(cx_ - 6, 6, 12, 10).get(), 8, "k", bevel=1.5, polish=0.7)   # the binder clips
        capsule(d, [(cx_ - 4, 7), (cx_ - 2, 2)], 1.4, 2, "chrome", polish=1.0)
        capsule(d, [(cx_ + 4, 7), (cx_ + 2, 2)], 1.4, 2, "chrome", polish=1.0)
    # the man: his middle (the outline's x 86) on the sheet's middle, his feet off the foot of the sheet
    H_ = 116; sc = H_ / 273
    sil = outline(d, "refs/avatar_outline.png", int(round(55 - 86 * sc)), 138 - H_, H_) & sheet
    d.paint(sil, "k")
    CX, CY = 55, 96
    for rx, ry, n in ((6, 8, "10"), (12, 16, "9"), (18, 24, "8"), (25, 32, "7")):
        ring = (np.abs(np.hypot((X - CX) / rx, (Y - CY) / ry) - 1) * min(rx, ry) < 0.6) & sil
        d.paint(ring, "pw")
        d.text(n, CX, int(CY - ry + 2), "pw", align="c")
    HX, HY = 56, 47
    ring = (np.abs(np.hypot((X - HX) / 5, (Y - HY) / 7) - 1) * 5 < 0.55) & sil
    d.paint(ring, "pw")                                                                       # the head's ring
    for hx_, hy in ((53, 99), (56, 97), (55, 102), (58, 100), (51, 101), (71, 113), (56, 46)):
        d.paint(Mask(d.W, d.H).ellipse(hx_, hy, 1.4, 1.4).get() & sheet, "pw")                # the holes: the paper torn
        d.paint(Mask(d.W, d.H).ellipse(hx_, hy, 0.6, 0.6).get() & sheet, "p")


@design(140, 120)
def nailsnuts(d):
    # a hex nut, a carriage bolt and two nails, lying on the bench
    cx, cy, R = 44, 64, 30
    hexa = [(cx + R * math.cos(math.radians(a)), cy + R * VIEW * 2.2 * math.sin(math.radians(a))) for a in range(0, 360, 60)]
    top = Mask(d.W, d.H).poly(hexa).get()
    sides = Mask(d.W, d.H).poly([hexa[0], hexa[1], hexa[2], hexa[3], (hexa[3][0], hexa[3][1] + 14), (hexa[2][0], hexa[2][1] + 14),
                                 (hexa[1][0], hexa[1][1] + 14), (hexa[0][0], hexa[0][1] + 14)]).get()
    d.slab(sides, 10, "chrome", bevel=1, polish=0.9)
    for k in (1, 2):
        x = hexa[k][0]; d.seam(Mask(d.W, d.H).rect(x - 0.5, hexa[k][1], 1, 14).get(), 0.35)
    d.flat(top, 18, "chrome", polish=0.8)
    hole = Mask(d.W, d.H).ellipse(cx, cy, 13, 13 * VIEW * 2.2).get()
    d.well(hole, 14, mat="k", bevel=1)
    for r in (8, 11):
        d.dark[(np.abs(np.hypot(d.XX + 0.5 - cx, (d.YY + 0.5 - cy) / (VIEW * 2.2)) - r) < 0.6) & hole] = 0.3   # the thread
    # the bolt: round head, square neck, threaded shank, lying to the right
    capsule(d, [(86, 30), (132, 30)], 9, 8, "chrome", polish=0.9)
    for x in range(100, 132, 3):
        d.dark[(np.abs(d.XX - x) < 0.6) & (np.abs(d.YY - 30) < 4.5)] = 0.3
    d.slab(Mask(d.W, d.H).rect(80, 25, 8, 10).get(), 9, "chrome", bevel=1, polish=0.9)
    d.dome(76, 30, 6, 11, 10, "chrome", polish=1.0)
    for y in (94, 106):                                                                       # the nails
        capsule(d, [(76, y), (126, y - 4)], 3.4, 4, "chrome", polish=1.0)
        d.slab(Mask(d.W, d.H).poly([(126, y - 6), (134, y - 4.5), (126, y - 2)]).get(), 3, "chrome", bevel=0.8, polish=1.0)
        disc(d, 76, y, 2.2, 5, 5, "chrome", polish=1.0)


@design(150, 96)
def time4sport(d):
    # four bats in rows, as on the store's rack, each with its model burned into the barrel (the director, Nov 6: "the
    # head of the baseball bat is the wrong perspective. The ball is too big ... Maybe there should be four rows of
    # bats. One says Super Slugger. Wood Slugger. Aluminum Slugger ... Youth Slugger"). Side on, the way a bat lies: the
    # knob a thin flange seen edge-on, the handle, the taper, the barrel rounding off at its end; one ball at its true
    # size (a little fatter than the barrel) by the short youth bat
    X = d.XX + 0.5; Y = d.YY + 0.5
    def bat(x0, cy, L, rb, rh, rk, mat, polish, label, ink, grip=False):
        u = (X - x0) / L
        t = np.clip((u - 0.30) / 0.40, 0, 1); t = t * t * (3 - 2 * t)
        r = rh + (rb - rh) * t
        ex = x0 + L - rb                                                    # the barrel's rounded end, side on
        body = (u >= 0.03) & (X <= ex) & (np.abs(Y - cy) <= r)
        cap = (X > ex) & (np.hypot(X - ex, Y - cy) <= rb)
        knob = (u >= 0) & (u < 0.03) & (np.abs(Y - cy) <= rk)
        m = body | cap | knob
        rr = np.where(cap, np.sqrt(np.clip(rb ** 2 - (X - ex) ** 2, 0, None)), np.where(knob, rk, r))
        prof = np.sqrt(np.clip(rr ** 2 - (Y - cy) ** 2, 0, None)) * 1.3
        d.h = np.where(m, prof, d.h).astype(np.float32)
        d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = polish; d.tex[m] = 0
        if mat != "chrome":
            d.grain_wood(m, scale=0.6, seed=int(cy), along="x")
        if grip:                                                            # the grip tape, wound on
            g = m & (u >= 0.03) & (u < 0.30)
            d.mat[g] = d.mid("k"); d.tex[g] = 0
            for k in range(int(x0 + L * 0.04), int(x0 + L * 0.30), 3):
                d.seam(g & (np.abs(X - k - (Y - cy) * 0.5) < 0.5), 0.3)
        d.text(label, int(round(x0 + L * 0.74)), int(round(cy - 2)), ink, align="c")
        return m
    bat(4, 12, 142, 5.3, 1.9, 3.3, "d", 0.7, "SUPER SLUGGER", "pw")
    bat(4, 36, 142, 5.3, 1.9, 3.3, "m", 0.6, "WOOD SLUGGER", "p")
    bat(4, 60, 142, 5.2, 1.9, 3.3, "chrome", 1.0, "ALUMINUM SLUGGER", "p", grip=True)
    bat(4, 84, 120, 4.6, 1.7, 3.0, "m", 0.6, "YOUTH SLUGGER", "p")
    # the ball, its true size, the stitching's two curves
    bx, by, br = 138, 86, 6.2
    d.dome(bx, by, br, br, 8, "w", polish=0.4)
    ball = ellipse_m(d, bx, by, br - 0.5, br - 0.5)
    for side in (-1, 1):
        pts = [(bx + side * (br * 0.95 - 3.2 * math.cos(math.radians(a))), by + br * 0.85 * math.sin(math.radians(a)))
               for a in range(-70, 71, 14)]
        d.paint(Mask(d.W, d.H).line(pts, 0.9).get() & ball, "d")


@design(140, 110)
def zippee(d):
    # a flashlight lying on its side and two D cells standing (the director, Nov 6: "just a little bit of cleanup"):
    # the barrel round with a clean highlight, the knurled grip on the middle only, the push switch, the bell of the
    # head flaring to a chrome bezel with the lens set in it (seen near edge on), the tail cap
    capsule(d, [(14, 88), (80, 88)], 16, 12, "k", polish=0.7)                                  # the barrel
    for x in range(34, 64, 3):
        d.dark[(np.abs(d.XX + 0.5 - x) < 0.6) & (np.abs(d.YY + 0.5 - 88) < 6)] = 0.28         # the knurled grip
    d.slab(Mask(d.W, d.H).rect(8, 80, 8, 16).get(), 12, "k", bevel=3, polish=0.7)              # the tail cap
    d.seam(Mask(d.W, d.H).rect(16, 80, 1, 16).get(), 0.4)
    d.slab(Mask(d.W, d.H).rrect(66, 76, 9, 5, 2).get(), 15, "chrome", bevel=1, polish=0.9)     # the switch
    bell = Mask(d.W, d.H).poly([(80, 80), (100, 72), (100, 104), (80, 96)]).get()
    d.slab(bell, 14, "k", bevel=4, polish=0.8)
    bez = ((d.XX + 0.5 - 101) / 5) ** 2 + ((d.YY + 0.5 - 88) / 17) ** 2 <= 1                 # the bezel, edge on
    d.slab(bez, 16, "chrome", bevel=2, polish=1.0)
    lens = ((d.XX + 0.5 - 102) / 3) ** 2 + ((d.YY + 0.5 - 88) / 13) ** 2 <= 1
    d.flat(lens, 15, "l", polish=1.0)
    d.dome(102, 82, 1.2, 4, 1, "w", polish=1.0, on="add")
    for cx in (112, 130):
        body, top = cyl_v(d, cx - 9, cx + 9, 22, 62, 11, "d", polish=0.8, top_ry=9 * VIEW, bot_ry=9 * VIEW)
        c = Cyl(d, cx - 9, cx + 9, 9 * VIEW)
        band_v(d, body, c, 22, 30, "chrome")
        print_wrap(d, body, c, "D", 40, "pw", font="57")
        d.dome(cx, 20, 3.2, 2, 3, "chrome", on=11)

@design(84, 108)
def phils(d):
    # a pawned gold pocket watch (the director, Nov 6: "I'm not sure what that pawn shop thing is supposed to be": the
    # three balls gave way to the thing a pawn shop is full of; then: "Remove the tag from the pocket watch")
    cx, cy = 42, 69
    d.torus(cx, cy, 30, 38, 9, "m", polish=1.0)                                                # the gold case
    disc(d, cx, cy, 30, 30, 3, "w", polish=0.3, power=2, on=4)                                # the dial
    for a in range(0, 360, 30):
        r0 = 22 if a % 90 else 19
        x0, y0 = cx + r0 * math.sin(math.radians(a)), cy - r0 * math.cos(math.radians(a))
        x1, y1 = cx + 27 * math.sin(math.radians(a)), cy - 27 * math.cos(math.radians(a))
        d.paint(Mask(d.W, d.H).line([(x0, y0), (x1, y1)], 1.6 if a % 90 == 0 else 1.0).get(), "p")
    d.paint(Mask(d.W, d.H).line([(cx, cy), (cx + 13, cy - 7)], 2.0).get(), "p")               # the hour hand
    d.paint(Mask(d.W, d.H).line([(cx, cy), (cx - 4, cy - 22)], 1.4).get(), "p")               # the minute hand
    disc(d, cx, cy + 14, 6, 6, 1, "l", polish=0.3, on=6)                                       # the seconds' little dial
    d.paint(Mask(d.W, d.H).line([(cx, cy + 14), (cx + 3, cy + 10)], 1).get(), "p")
    d.dome(cx, cy, 2.2, 2.2, 2, "m", on=7)
    d.slab(Mask(d.W, d.H).rect(cx - 5, cy - 46, 10, 9).get(), 10, "m", bevel=2, polish=1.0)    # the crown's stem
    d.dome(cx, cy - 48, 6, 4, 9, "m", polish=1.0)                                              # the crown, ribbed
    for k in range(-4, 5, 2):
        d.dark[(np.abs(d.XX + 0.5 - cx - k) < 0.5) & (np.abs(d.YY + 0.5 - (cy - 48)) < 3.5)] = 0.25
    d.torus(cx, cy - 58, 6, 9, 5, "m", polish=1.0)                                             # the bow


@design(150, 82)
def hitvids(d):
    # a VHS cassette laid out the way they are (the director's reference, Nov 6): the hinged door across the top with
    # its ribs and the arrow, the ribbed shell below, two windows at the sides (round on their outer ends), the full
    # reel of tape on the left and the near-empty one on the right, each hub toward the middle, the label between them
    X = d.XX + 0.5; Y = d.YY + 0.5
    d.flat(Mask(d.W, d.H).poly([(6, 6), (144, 6), (148, 10), (2, 10)]).get(), 12, "d", polish=0.5)   # the top edge
    shell = Mask(d.W, d.H).rect(2, 10, 146, 70).get()
    d.slab(shell, 12, "k", bevel=1.2, polish=0.45)
    for y in range(32, 80, 2):
        d.seam(Mask(d.W, d.H).rect(4, y, 142, 1).get(), 0.12)                                  # the shell's fine ribs
    door = Mask(d.W, d.H).rect(8, 12, 134, 16).get()
    d.slab(door, 14, "k", bevel=0.8, polish=0.5)
    for y in (17, 21, 25):
        d.seam(Mask(d.W, d.H).rect(10, y, 130, 1).get(), 0.28)                                 # the door's ribs
    d.slab(Mask(d.W, d.H).poly([(75, 17), (80, 23), (70, 23)]).get(), 15, "d", bevel=0.5)       # the arrow
    d.slab(Mask(d.W, d.H).rect(2, 10, 6, 20).get(), 13, "k", bevel=0.8)                         # the door's hinge ends
    d.slab(Mask(d.W, d.H).rect(142, 10, 6, 20).get(), 13, "k", bevel=0.8)
    # (second pass, the director: "Take another pass at vhs"; proportions measured off the reference: door 23% of the
    # height, windows 47%, the band below 22%; windows 22% of the width each, the label 40% between them)
    def window(x0, x1, round_left):
        w_ = Mask(d.W, d.H).rrect(x0, 33, x1 - x0, 33, 3).get()
        cx_ = x0 if round_left else x1                                      # the outer end: big round corners
        corner = ((X - (cx_ + (9 if round_left else -9))) ** 2 + (np.minimum(np.abs(Y - 33), np.abs(Y - 66)) - 9) ** 2 > 81) \
                 & ((X < cx_ + 9) if round_left else (X > cx_ - 9)) & ((Y < 42) | (Y > 57))
        w_ &= ~corner
        d.well(w_, 6, mat="l", bevel=1, polish=1.0)
        return w_
    wl = window(8, 40, True); wr = window(110, 142, False)
    d.dark[wl | wr] = 0                                                                          # clear plastic: no ribs
    # the tape: a full dark pack round the left hub, a thin one round the right; each hub at the window's inner side
    for (hx_, R, w_) in ((32, 22.0, wl), (118, 9.0, wr)):
        pack = (np.hypot(X - hx_, Y - 49.5) < R) & w_
        d.paint(pack, "d")
        for rr in range(8, int(R), 3):
            d.dark[pack & (np.abs(np.hypot(X - hx_, Y - 49.5) - rr) < 0.5)] = 0.15
        disc(d, hx_, 49.5, 6.5, 6.5, 3, "w", polish=0.8, on=8)
        for a_ in (90, 210, 330):                                                                # the hub's three notches
            d.paint(Mask(d.W, d.H).ellipse(hx_ + 4.2 * math.cos(math.radians(a_)), 49.5 + 4.2 * math.sin(math.radians(a_)), 1.3, 1.3).get(), "k")
        d.paint(Mask(d.W, d.H).ellipse(hx_, 49.5, 1.6, 1.6).get(), "d")
    # the tape's run across the bottom of the right window, under its guide
    d.paint(Mask(d.W, d.H).rect(111, 62, 26, 1).get() & wr, "d")
    lab = Mask(d.W, d.H).rrect(46, 33, 58, 33, 2).get()
    d.slab(lab, 13, "w", bevel=0.6, polish=0.2)
    d.text("HIT VIDS", 75, 37, "p", font="57", align="c")
    d.paint(Mask(d.W, d.H).rect(50, 47, 50, 1).get(), "p")
    d.text("BE KIND,", 75, 51, "p", align="c")
    d.text("REWIND", 75, 58, "p", align="c")
    d.well(Mask(d.W, d.H).rect(72, 10, 6, 2).get(), 3, bevel=0.5)                              # the door's latch notch


# ================================================================== batch 4 (Nov 6): the quarters
def facet(d, pts, zs, mat, polish=0.6):
    """a flat triangle whose height runs between its corners' heights: a cut face, lit by its own slope"""
    m = Mask(d.W, d.H).poly(pts).get()
    (x0, y0), (x1, y1), (x2, y2) = pts
    X = d.XX + 0.5; Y = d.YY + 0.5
    den = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
    a = ((y1 - y2) * (X - x2) + (x2 - x1) * (Y - y2)) / den
    b = ((y2 - y0) * (X - x2) + (x0 - x2) * (Y - y2)) / den
    c = 1 - a - b
    z = a * zs[0] + b * zs[1] + c * zs[2]
    d.h = np.where(m, z, d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = polish; d.tex[m] = 0
    return m


def taper_v(d, cx, y0, y1, r0, r1, z, mat, polish=0.4, top_ry=None):
    """an upright tapered round body (a flower pot): radius r0 at the top, r1 at the foot, round across x; the top's
    opening a level ellipse"""
    Y = d.YY + 0.5; X = d.XX + 0.5
    r = r0 + (r1 - r0) * np.clip((Y - y0) / (y1 - y0), 0, 1)
    t = (X - cx) / r
    body = (np.abs(t) <= 1) & (Y >= y0) & (Y <= y1)
    body |= ellipse_m(d, cx, y1, r1, r1 * VIEW) & (Y >= y1)
    d.h = np.where(body, np.sqrt(np.clip(1 - np.clip(t, -1, 1) ** 2, 0, 1)) * z, d.h).astype(np.float32)
    d.mat[body] = d.mid(mat); d.solid |= body; d.polish[body] = polish; d.tex[body] = 0
    top = ellipse_m(d, cx, y0, r0, top_ry if top_ry else r0 * VIEW)
    return body, top
def revolve(d, cx, prof, z, mat, polish=0.6, y0=0):
    """an upright turned shape (a pin, a vase): prof is [(y, radius), ...] down its height; round across x"""
    ys = np.array([p[0] for p in prof], float); rs = np.array([p[1] for p in prof], float)
    r = np.interp(d.YY + 0.5, ys, rs, left=0, right=0)
    t = (d.XX + 0.5 - cx) / np.maximum(r, 1e-3)
    m = (np.abs(t) <= 1) & (r > 0.3)
    prof_h = np.sqrt(np.clip(1 - t ** 2, 0, 1)) * z * (r / rs.max())
    d.h = np.where(m, np.maximum(d.h, prof_h), d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = polish; d.tex[m] = 0
    return m


@design(150, 120)
def magic(d):
    # the magician's hat upside down on the table, a rabbit's ears up out of it, the wand lying in front with sparkles
    # (the director, Nov 6: "The magic wand is going through the hat")
    X = d.XX + 0.5; Y = d.YY + 0.5
    # the crown rests on the table; the open end is at the top, with the brim round it
    body, top = cyl_v(d, 44, 104, 40, 104, 22, "k", polish=0.6, top_ry=30 * VIEW, bot_ry=30 * VIEW)
    c = Cyl(d, 44, 104, 30 * VIEW)
    band_v(d, body, c, 44, 54, "d")                                                            # the band, by the brim
    # the ears, rising out of the opening (drawn before the brim's front so the brim crosses their roots)
    for (bx, tx, lean) in ((66, 58, -4), (80, 86, 6)):
        ear = ((X - (bx + (tx - bx) * (40 - Y) / 34)) / 6.5) ** 2 + ((Y - 22) / 20) ** 2 <= 1
        ear &= Y < 40
        d.h = np.where(ear, 30 + np.sqrt(np.clip(1 - ((X - (bx + (tx - bx) * (40 - Y) / 34)) / 6.5) ** 2, 0, 1)) * 6, d.h).astype(np.float32)
        d.mat[ear] = d.mid("w"); d.solid |= ear; d.polish[ear] = 0.3
        inner = ear & (np.abs(X - (bx + (tx - bx) * (40 - Y) / 34)) < 2.4) & (Y > 8) & (Y < 36)
        d.paint(inner, "l")
    # the brim: a level ring round the opening, its far side behind the ears, its near side in front
    ring = ellipse_m(d, 74, 40, 44, 44 * VIEW + 2) & ~ellipse_m(d, 74, 40, 30, 30 * VIEW)
    d.flat(ring & (Y >= 40), 34, "k", polish=0.6)
    d.flat(ring & (Y < 40) & ~(d.mat == d.mid("w")), 26, "k", polish=0.6)
    hole = ellipse_m(d, 74, 40, 30, 30 * VIEW) & ~(d.mat == d.mid("w"))
    d.flat(hole, 18, "k", polish=0.2); d.dark[hole] = 0.4
    # the wand on the table in front, white tips; a few sparkles
    capsule(d, [(10, 114), (94, 104)], 5, 8, "k", polish=0.9, )
    capsule(d, [(10, 114), (18, 113)], 5, 8, "w", polish=0.9)
    capsule(d, [(86, 105), (94, 104)], 5, 8, "w", polish=0.9)
    INK_ = tuple(int(v) for v in INK)
    for (x, y, r) in ((118, 18, 5), (130, 34, 3), (110, 6, 3), (28, 22, 4)):
        for a_ in (0, 90):
            m = Mask(d.W, d.H).line([(x - r * math.cos(math.radians(a_)), y - r * math.sin(math.radians(a_))),
                                     (x + r * math.cos(math.radians(a_)), y + r * math.sin(math.radians(a_)))], 1).get()
            d.emit[m, :3] = INK_; d.emit[m, 3] = 255

@design(130, 124)
def seeds(d):
    # a seed packet standing at a lean, its picture of a tomato plant, seeds spilled in front; a seedling in a clay pot
    # (the director, Nov 6: "The seed is not in a pot. It's just in a cylinder of dirt"): the pot tapers to its foot,
    # a rolled rim round the top, the soil inside the rim, the sprout's two leaves
    pk = Mask(d.W, d.H).poly([(14, 14), (74, 8), (82, 100), (22, 106)]).get()
    d.slab(pk, 6, "w", bevel=1.2, polish=0.2)
    d.slab(Mask(d.W, d.H).poly([(14, 14), (74, 8), (75, 18), (15, 24)]).get(), 7, "l", bevel=1, polish=0.2)
    win = Mask(d.W, d.H).poly([(22, 30), (70, 26), (74, 70), (26, 74)]).get()
    d.paint(win, "l")
    for (x, y, r) in ((38, 50, 7), (56, 46, 8), (50, 62, 6)):
        d.dome(x, y, r, r, 4, "d", polish=0.8, on="add")
        d.dome(x - 2, y - 2, 2, 2, 1, "w", on="add")
    d.paint(Mask(d.W, d.H).line([(46, 30), (48, 66)], 1.4).get() & win, "k")
    d.text("TOMATO", 50, 78, "p", align="c"); d.text("KY SEED CO", 52, 88, "p", align="c")
    for k in range(9):
        x = 26 + (k * 23) % 56; y = 112 + (k * 7) % 8
        disc(d, x, y, 2.2, 1.5, 2, "m", polish=0.6)
    body, top = taper_v(d, 108, 84, 118, 17, 12, 12, "m", polish=0.3)                         # the pot
    rim, rtop = cyl_v(d, 89, 127, 78, 86, 14, "m", polish=0.35, top_ry=19 * VIEW, bot_ry=19 * VIEW)   # the rolled rim
    d.flat(ellipse_m(d, 108, 78.5, 16, 16 * VIEW), 13, "d", polish=0.1)                       # the soil
    d.grain_pebble(ellipse_m(d, 108, 78.5, 16, 16 * VIEW), 0.3, seed=8)
    capsule(d, [(108, 78), (107, 56)], 2.2, 3, "l", polish=0.4)                               # the stem
    d.dome(100, 54, 8, 4, 4, "l", polish=0.4); d.dome(114, 50, 8, 4, 4, "l", polish=0.4)    # the seed leaves
    d.seam(Mask(d.W, d.H).line([(94, 54), (106, 54)], 1).get(), 0.25)
    d.seam(Mask(d.W, d.H).line([(108, 50), (120, 50)], 1).get(), 0.25)

@design(176, 60)
def kittenknives(d):
    # a fixed-blade hunting knife, point right (the director, Nov 6: "just needs a little bit of refinement"; "I like
    # that you put the kitten on there"): the clip-point blade with its spine, the ground edge running the length as
    # a lighter bevel, the swedge at the clip; a brass guard; a stacked-leather handle with spacers; an aluminum pommel
    X = d.XX + 0.5; Y = d.YY + 0.5
    spine = 20.0; edge_y = lambda x: 41 - np.clip((x - 128) / 44, 0, 1) ** 1.6 * 13     # the belly sweeps up to the point
    clip_y = lambda x: spine + np.clip((x - 136) / 36, 0, 1) * 9                          # the clip drops to the point
    blade = (X >= 66) & (X <= 172) & (Y >= clip_y(X)) & (Y <= edge_y(X)) & (clip_y(X) < edge_y(X) - 0.5)
    d.h = np.where(blade, 6 + (Y - spine) * 0.0, d.h).astype(np.float32)
    d.mat[blade] = d.mid("chrome"); d.solid |= blade; d.polish[blade] = 1.0; d.tex[blade] = 0
    flat_ = blade & (Y < edge_y(X) - 7)
    d.h[flat_] = 7.0
    bevel = blade & (Y >= edge_y(X) - 7)
    d.h[bevel] = (7.0 - (Y[bevel] - (edge_y(X)[bevel] - 7)) * 0.9)                           # the edge bevel, falling away
    d.seam(Mask(d.W, d.H).line([(70, 33), (150, 33.5)], 1).get() & blade, 0.15)             # the grind line
    sw = blade & (X > 136) & (Y < clip_y(X) + 2)
    d.h[sw] -= 1.2                                                                         # the swedge
    d.slab(Mask(d.W, d.H).rect(70, 41, 6, 3).get(), 5, "chrome", bevel=1, polish=1.0)      # the choil
    d.text("KITTEN", 104, 25, "p", align="c")                                              # the etched mark
    # a little cat's head after the name, two ears and a round face
    d.paint(Mask(d.W, d.H).ellipse(122, 28, 3, 2.5).get() | Mask(d.W, d.H).poly([(119, 27), (120, 23), (122, 26)]).get()
            | Mask(d.W, d.H).poly([(122, 26), (124, 23), (125, 27)]).get(), "p")
    d.slab(Mask(d.W, d.H).rrect(58, 12, 9, 38, 2).get(), 10, "m", bevel=2, polish=1.0)    # the brass guard
    handle = Mask(d.W, d.H).poly([(14, 22), (58, 20), (58, 42), (14, 41)]).get() & Mask(d.W, d.H).rrect(12, 19, 48, 24, 8).get()
    d.slab(handle, 11, "d", bevel=7, polish=0.4)
    for x in range(18, 56, 4):
        d.seam(Mask(d.W, d.H).rect(x, 19, 1, 24).get() & handle, 0.25)                    # the leather washers
    for x in (30, 44):
        d.paint(Mask(d.W, d.H).rect(x, 19, 2, 24).get() & handle, "k")                     # the spacers
    d.slab(Mask(d.W, d.H).rrect(4, 20, 11, 22, 5).get(), 12, "chrome", bevel=4, polish=0.9) # the pommel

@design(150, 124)
def barkner(d):
    # a 50-pound sack of dog food (the director, Nov 6: "the bag looks a little too boxy. Soften it up ... it's kind of
    # flabby"): paper settled under its own weight, wider and rounder at the foot, its top rolled over and stitched,
    # the sides bowed and creased; a steel bowl heaped full of kibble, full but not spilling over
    X = d.XX + 0.5; Y = d.YY + 0.5
    def sde(cx, cy, rx, ry): return (np.hypot((X - cx) / rx, (Y - cy) / ry) - 1) * min(rx, ry)
    def smin(a, b, k):
        h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1); return b * (1 - h) + a * h - k * h * (1 - h)
    lean = (Y - 60) * -0.06
    upper = np.maximum(np.abs(X - 64 - lean) - 40, np.abs(Y - 44) - 32) - 0                 # the sack's upper body
    sag = sde(64, 92, 50, 22)                                                               # the slumped, rounder foot
    sack = smin(upper, sag, 12)
    sack = np.maximum(sack, Y - 112)                                                        # standing on the floor
    m = sack <= 0
    dist = E.edt(m)
    d.h = np.where(m, np.sqrt(np.clip(dist / 16.0, 0, 1)) * 18, d.h).astype(np.float32)
    d.mat[m] = d.mid("w"); d.solid |= m; d.polish[m] = 0.2; d.tex[m] = 0
    d.grain_pebble(m, 0.05, seed=9)
    for (p, q) in (((30, 70), (36, 104)), ((98, 66), (92, 102)), ((46, 98), (58, 108)), ((80, 100), (88, 106))):
        d.seam(Mask(d.W, d.H).line([p, q], 1).get() & m, 0.22)                             # the creases where it slumps
    roll = Mask(d.W, d.H).rrect(22, 4, 86, 13, 6).get()
    d.slab(roll, 14, "l", bevel=5, polish=0.2)                                              # the top, rolled over
    for x in range(26, 104, 4):
        d.seam(Mask(d.W, d.H).rect(x, 15, 2, 1).get(), 0.45)                               # its stitching
    bone = (Mask(d.W, d.H).rrect(46, 30, 36, 10, 4).get() | Mask(d.W, d.H).ellipse(46, 30, 6, 6).get()
            | Mask(d.W, d.H).ellipse(46, 40, 6, 6).get() | Mask(d.W, d.H).ellipse(82, 30, 6, 6).get()
            | Mask(d.W, d.H).ellipse(82, 40, 6, 6).get())
    d.paint(bone & m, "d")
    d.text("50 LB", 64, 52, "p", font="57", align="c", scale=2)
    d.text("DOG FOOD", 64, 72, "p", align="c")
    d.text("PURRFECT", 64, 80, "p", align="c")
    # the bowl, heaped: a steel dish, its rim a level ring, the kibble in a mound above the rim
    body, top = cyl_v(d, 98, 146, 104, 116, 8, "chrome", polish=1.0, top_ry=24 * VIEW, bot_ry=20 * VIEW)
    rng = np.random.default_rng(3)
    pieces = []
    for _ in range(400):                                                                  # the heap, piece by piece
        kx, ky = 122 + rng.uniform(-21, 21), 104 + rng.uniform(-10, 3)
        if ((kx - 122) / 22) ** 2 + ((ky - 105) / 10) ** 2 < 1 and ky < 106:
            pieces.append((ky, kx, rng.integers(0, 3)))
    for ky, kx, t in sorted(pieces)[::2]:                                                 # back to front
        d.dome(kx, ky, 2.4, 1.9, 9 + (106 - ky) * 0.9, ("m", "d", "m")[t], polish=0.3)

@design(176, 112)
def motorbikes(d):
    # a motorcycle, side on, facing right (the director, Nov 6: "The motorbikes and more, what the hell is that?"):
    # two spoked wheels, the fenders over them, the fork and handlebar with its round headlamp, the teardrop tank, the
    # seat, the finned engine low between the wheels, the exhaust running back to the rear, the kickstand
    INK_ = tuple(int(v) for v in INK)
    for cx, cy in ((36, 84), (140, 84)):
        d.torus(cx, cy, 17, 24, 8, "k", polish=0.5)                                          # the tire
        d.torus(cx, cy, 14, 17, 5, "chrome", polish=1.0)                                     # the rim
        for a in range(0, 360, 20):
            m = Mask(d.W, d.H).line([(cx + 3 * math.cos(math.radians(a)), cy + 3 * math.sin(math.radians(a))),
                                     (cx + 14 * math.cos(math.radians(a + 25)), cy + 14 * math.sin(math.radians(a + 25)))], 0.9).get()
            d.flat(m, 3, "chrome", polish=1.0)                                               # the spokes
        d.dome(cx, cy, 4.5, 4.5, 6, "chrome", polish=1.0)                                     # the hub
    d.slab(Mask(d.W, d.H).arc(140, 84, 27, 27, 200, 330, 4).get(), 10, "k", bevel=1.5, polish=0.8)   # front fender
    d.slab(Mask(d.W, d.H).arc(36, 84, 27, 27, 200, 300, 4).get(), 10, "k", bevel=1.5, polish=0.8)    # rear fender
    capsule(d, [(36, 84), (78, 70)], 4, 6, "k", polish=0.7)                                  # the swingarm
    capsule(d, [(52, 50), (36, 80)], 3.4, 6, "chrome", polish=1.0)                           # the rear shock
    capsule(d, [(140, 84), (122, 30)], 5, 7, "chrome", polish=1.0)                           # the fork
    capsule(d, [(116, 20), (126, 26), (136, 24)], 3.2, 7, "chrome", polish=1.0)              # the handlebar
    capsule(d, [(110, 18), (118, 20)], 4.2, 7, "k", polish=0.4)                              # its grip
    disc(d, 134, 36, 6, 8, 8, "chrome", polish=1.0)                                          # the headlamp, side on
    d.dome(138, 36, 2, 6, 3, "l", polish=1.0, on="add")
    # the engine: a block low between the wheels, a finned cylinder rising from it
    eng = Mask(d.W, d.H).rrect(70, 60, 34, 24, 4).get()
    d.slab(eng, 12, "chrome", bevel=3, polish=0.8)
    for k in range(5):
        d.slab(Mask(d.W, d.H).rrect(76, 44 + k * 4, 22, 3, 1).get(), 13, "d", bevel=1, polish=0.8)   # the fins
    d.slab(Mask(d.W, d.H).rect(70, 66, 34, 2).get(), 13, "d", bevel=0.5)
    capsule(d, [(76, 80), (60, 92), (16, 90)], 5, 8, "chrome", polish=1.0)                    # the exhaust, running back
    capsule(d, [(14, 90), (24, 90)], 7, 9, "chrome", polish=1.0)                              # its muffler's end
    # the frame's backbone, the tank, the seat
    capsule(d, [(52, 50), (90, 42), (120, 30)], 4, 6, "k", polish=0.7)
    tank = ((d.XX + 0.5 - 96) / 20) ** 2 + ((d.YY + 0.5 - 40) / 9) ** 2 <= 1
    tank &= d.YY + 0.5 < 46
    d.dome(96, 40, 20, 9, 14, "k", polish=1.0)
    d.paint(tank & (np.abs(d.YY + 0.5 - 40) < 1.5), "w")                                     # the pinstripe
    d.dome(92, 34, 6, 2, 2, "l", polish=1.0, on="add")                                       # a shine on the tank
    seat = Mask(d.W, d.H).poly([(44, 44), (76, 40), (78, 46), (46, 52)]).get()
    d.slab(seat, 13, "d", bevel=3, polish=0.4)
    capsule(d, [(74, 86), (82, 104)], 2.6, 4, "k", polish=0.7)                                # the kickstand

@design(150, 100)
def wizard(d):
    # a real twenty-sided die (the director, Nov 6: "I'd like to see you roll anything other than a 20 with that d20"):
    # an icosahedron seen with one face toward us, so its outline is a hexagon; the face toward us, the three that share
    # its edges, and six more round the rim, each face flat and lit by its own slope; numbers on the faces we can read
    # (the standard die: 20 sits among 2, 8 and 14); and a six-sided die beside it
    cx, cy, R = 50, 52, 44
    Hx = [(cx + R * math.cos(math.radians(a)), cy + R * math.sin(math.radians(a))) for a in (-90, -30, 30, 90, 150, 210)]
    r_ = R * 0.52
    T = [(cx + r_ * math.cos(math.radians(a)), cy + r_ * math.sin(math.radians(a))) for a in (-90, 30, 150)]
    zc, zt, zh = 24, 20, 4
    facet(d, T, (zt, zt, zt), "l")                                                       # the face toward us
    # edge faces: each shares an edge of T; its third corner is the hexagon corner opposite that edge
    ef = [((T[0], T[1]), Hx[1]), ((T[1], T[2]), Hx[3]), ((T[2], T[0]), Hx[5])]
    for (a, b), h in ef:
        facet(d, [a, b, h], (zt, zt, zh), "l")
    # rim faces: each T corner with its two neighbouring hexagon corners
    rim = [(T[0], Hx[0], Hx[1]), (T[0], Hx[5], Hx[0]), (T[1], Hx[1], Hx[2]), (T[1], Hx[2], Hx[3]), (T[2], Hx[3], Hx[4]), (T[2], Hx[4], Hx[5])]
    for a, b, c in rim:
        facet(d, [a, b, c], (zt, zh, zh), "l")
    for p, q in [(T[0], T[1]), (T[1], T[2]), (T[2], T[0])] + [(t, h) for (a, b), h in ef for t in (a, b)] + [(a, b) for a, b, c in rim] + [(a, c) for a, b, c in rim]:
        d.seam(Mask(d.W, d.H).line([p, q], 1).get(), 0.3)                                  # the edges
    d.text("20", cx, cy - 4, "p", font="57", align="c")
    for ((a, b), h), n in zip(ef, ("8", "14", "2")):
        gx = (a[0] + b[0] + h[0]) / 3; gy = (a[1] + b[1] + h[1]) / 3
        d.text(n, int(round(gx)), int(round(gy)) - 2, "p", align="c")
    # the six-sided die, three-quarter
    F = [(104, 52), (136, 46), (138, 80), (106, 86)]; Tp = [(98, 40), (128, 34), (136, 46), (104, 52)]; S = [(98, 40), (104, 52), (106, 86), (100, 74)]
    d.ramp_h(Mask(d.W, d.H).poly(F).get(), 12, 12, axis="x", mat="w", polish=0.6)
    d.flat(Mask(d.W, d.H).poly(Tp).get(), 16, "w", polish=0.6)
    d.ramp_h(Mask(d.W, d.H).poly(S).get(), 6, 12, axis="x", mat="l", polish=0.6)
    for (x, y) in ((112, 58), (121, 66), (130, 74), (112, 74), (130, 58)):
        d.well(Mask(d.W, d.H).ellipse(x, y, 2.6, 2.6).get(), 3, mat="k", bevel=0.6)
    d.well(Mask(d.W, d.H).ellipse(117, 43, 2.6, 1.6).get(), 3, mat="k", bevel=0.6)

@design(150, 136)
def bowling(d):
    # a bowling pin standing, its two neck stripes; a ball beside it with its three holes
    prof = [(4, 0), (6, 6), (12, 9), (22, 9), (32, 7), (40, 6.5), (50, 9), (66, 15), (86, 17), (104, 15), (120, 11), (128, 9), (130, 0)]
    pin = revolve(d, 46, prof, 18, "w", polish=0.6)
    for y0 in (30, 36):
        m = pin & (d.YY >= y0) & (d.YY < y0 + 3)
        d.mat[m] = d.mid("k")
    d.dome(106, 100, 34, 34, 34, "k", polish=1.0)                                             # the ball
    for (x, y, r) in ((96, 86, 4.5), (110, 84, 4.5), (104, 100, 5.5)):
        d.well(Mask(d.W, d.H).ellipse(x, y, r, r * 0.9).get(), 6, bevel=1)


@design(176, 90)
def recliner(d):
    # a recliner, side on, kicked back with its footrest out, drawn after the director's photo (Nov 6, 2026:
    # ZeD_design_refs/ads/refs/recliner_ref.png, after "What the hell is going on with that chair?" and "The arm of the recliner. And like
    # there's a part coming out of the seat that's going the wrong direction. It should be connected to the footrest").
    # Every point below is the photo's, 600 x 600, mapped onto the picture (P). As in the photo: the back leans well
    # back, its padded outer panel slanting, the head pillow above it; the arm is a big box to the base with its back
    # corner cut on the slant and a padded roll along its top; the release handle near its front; the footrest is a thin
    # pad out in front, a little below the arm, on a black steel linkage that runs down from under the pad to the
    # chair's front; the chair sits on a black steel glider base
    S_ = 0.31
    def P(x, y): return ((x - 31) * S_ + 2, (y - 199) * S_ + 3)
    def poly(*pts): return Mask(d.W, d.H).poly([P(x, y) for x, y in pts]).get()
    def bar(p, q, w=1.6, z=6): return capsule(d, [P(*p), P(*q)], w, z, "k", polish=0.8)
    def soft(mask, z, mat="m", b=6):
        return d.slab(mask, z, mat, bevel=b, polish=0.25, power=0.5)
    # the glider base, under it all: a long rail on two feet, one at the back and one at the front (the director, Nov 6:
    # "There's two in the back, one in the middle, and nothing up front ... Just put one in the back, one in the front")
    bar((180, 446), (440, 446), 1.8, 5)
    for (p, q) in (((182, 446), (176, 463)), ((436, 446), (442, 463))):
        bar(p, q, 1.8, 5)
        X_, Y_ = P(*q)
        d.slab(Mask(d.W, d.H).rect(X_ - 2.5, Y_ - 0.5, 5, 2).get(), 4, "k", bevel=0.6, polish=0.8)   # its pad on the floor
    # the back: its lower part behind the arm, the head pillow, the outer panel on the slant
    # (its top reaches up under the pillow to the arm's slanted corner: the director, Nov 6, "Close the gap")
    soft(poly((145, 337), (182, 281), (212, 268), (230, 262), (230, 440), (188, 440), (176, 382), (163, 352)), 10)
    pillow = poly((34, 246), (44, 214), (62, 200), (98, 199), (132, 216), (172, 238), (204, 258), (214, 274), (188, 300),
                  (120, 300))
    soft(pillow, 14, b=7)
    outer = poly((32, 252), (56, 218), (182, 281), (148, 340))
    soft(outer, 18, b=5)
    d.seam(Mask(d.W, d.H).line([P(108, 236), P(200, 268)], 1).get() & pillow & ~outer, 0.3)  # the pillow's fold
    # the arm: the box to the base, the back corner cut on the slant, the roll along its top
    arm = poly((217, 272), (244, 252), (446, 249), (452, 256), (452, 432), (446, 438), (224, 438), (217, 431))
    soft(arm, 20, b=4)
    roll = poly((226, 262), (248, 244), (444, 242), (452, 250), (452, 258), (238, 262))
    soft(roll, 22, b=3)
    # the release handle near the arm's front: a recess with its lever
    d.well(Mask(d.W, d.H).rrect(*P(362, 280), 12, 8, 3).get(), 2.5, bevel=1)
    d.slab(Mask(d.W, d.H).rrect(*P(368, 284), 7, 4, 2).get(), 21, "k", bevel=1.2, polish=0.8)
    # the footrest: the linkage first (from under the pad down to the chair's front, every bar pinned at both ends),
    # its small lower flap, then the thin pad
    bar((456, 372), (532, 318), 1.7, 7)
    bar((462, 352), (548, 318), 1.7, 6)
    bar((500, 316), (556, 316), 1.5, 6)                                                       # the bracket under the pad
    soft(poly((452, 312), (470, 304), (482, 314), (462, 336), (452, 338)), 9, b=3)          # the flap
    pad = poly((462, 300), (470, 295), (578, 296), (584, 302), (580, 309), (470, 314), (462, 310))
    soft(pad, 12, b=3)
    d.grain_pebble(d.solid & (d.mat == d.mid("m")), 0.06, seed=5)
    for (x, y) in ((456, 372), (462, 352), (532, 318), (548, 318)):
        X_, Y_ = P(x, y)
        d.dome(X_, Y_, 1.2, 1.2, 9, "chrome", polish=1.0)                                     # the pins

@design(150, 72)
def fannypack(d):
    # a fanny pack (the director, Nov 6: "It's not a fanny pack. It ain't a purse. This is a professional survival kit"):
    # the game's own (Base.Bag_FannyPackFront), laid out flat and seen from the front, a little from above: a puffy
    # two-tone nylon pouch, its main zipper over the top with the pull hanging, a front pocket with its own zipper and a
    # sewn patch; the webbing belt out to both sides, a slider on the left, the big side-release buckle on the right
    # (buckled: "you gotta have man muscles just to buckle this thing")
    X = d.XX + 0.5; Y = d.YY + 0.5
    def web(x0, x1, y0=23, h=8):
        m = Mask(d.W, d.H).rect(x0, y0, x1 - x0, h).get()
        d.slab(m, 2, "k", bevel=0.7, polish=0.3, power=1.0)                                  # flat webbing
        d.seam(m & ((d.XX % 3) == 0) & ((d.YY == y0 + 1) | (d.YY == y0 + h - 2)), 0.25)     # the weave's stitch line
        return m
    web(3, 36); web(114, 148)
    d.slab(Mask(d.W, d.H).rrect(1, 23, 5, 8, 2).get(), 2.5, "k", bevel=0.8, polish=0.3, power=1.0)   # the hemmed end
    # the slider on the left (a flat frame the webbing threads through), the buckle on the right
    d.slab(Mask(d.W, d.H).rect(13, 20, 8, 14).get(), 5, "k", bevel=1.0, polish=0.8, power=1.0)
    d.well(Mask(d.W, d.H).rect(15, 22, 4, 10).get(), 3, bevel=0.5)
    d.slab(Mask(d.W, d.H).rect(15, 26, 4, 2).get(), 5, "k", bevel=0.5, polish=0.8, power=1.0)   # its middle bar
    buckle = Mask(d.W, d.H).rrect(121, 19, 24, 16, 4).get()
    d.slab(buckle, 9, "k", bevel=2, polish=0.85)
    d.seam(Mask(d.W, d.H).line([(133, 20), (133, 34)], 1).get(), 0.5)                     # where the halves meet
    for y in (21, 31):
        d.well(Mask(d.W, d.H).rect(135, y, 7, 2).get(), 2.5, bevel=0.5)                      # the prongs' windows
    d.well(Mask(d.W, d.H).rrect(124, 24, 7, 6, 2).get(), 2, bevel=0.6)                       # the female half's grip
    # the pouch: wide, rounded, the top a shallow arch
    pouch = (Mask(d.W, d.H).rrect(31, 14, 88, 48, 18).get()
             & (Y >= 14 + 6 * ((X - 75) / 44) ** 2))
    d.slab(pouch, 16, "d", bevel=12, polish=0.35, power=0.5)
    pocket = Mask(d.W, d.H).rrect(42, 31, 66, 27, 11).get()
    d.slab(pocket, 6, "m", bevel=5, polish=0.35, power=0.5, on="h")                         # the front pocket
    # the zippers: teeth (a dark line, every other pixel catching the light) and their pulls
    def zipper(pts):
        z = Mask(d.W, d.H).line(pts, 1.6).get()
        d.seam(z, 0.55)
        d.paint(z & (((d.XX + d.YY) % 2) == 0), "w")
        return z
    zipper([(36, 25), (55, 20.5), (75, 19.5), (95, 20.5), (114, 25)])
    zipper([(47, 35), (103, 35)])
    d.slab(Mask(d.W, d.H).rrect(96, 20, 4, 8, 1).get(), 1.5, "chrome", bevel=0.6, polish=1.0, on="h")
    d.slab(Mask(d.W, d.H).rrect(51, 35, 4, 7, 1).get(), 1.5, "chrome", bevel=0.6, polish=1.0, on="h")
    # the patch, sewn on the pocket
    patch = Mask(d.W, d.H).rect(66, 42, 18, 10).get()
    d.slab(patch, 0.8, "w", bevel=0.5, polish=0.2, on="h")
    d.text("PRO", 75, 45, "p", align="c")
    d.grain_pebble(d.solid & (d.mat == d.mid("d")), 0.05, seed=7)

# pictures made another way, which a plain run must not overwrite: Iron Mike is the in-game capture (mike_ink.py); the
# drawn design above is kept for the record and runs only by name
CAPTURED = {"iron_mike"}

if __name__ == "__main__":
    os.makedirs("px", exist_ok=True)
    names = sys.argv[1:] or [n for n in DESIGNS if n not in CAPTURED]
    for n in names:
        im = render(n)
        im.save(os.path.join("px", n + ".png"))
        print(n, im.size)
