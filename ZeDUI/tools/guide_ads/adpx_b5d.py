"""Batch 5d of the survival guide's third-page ads (Nov 7 2026): eight pictures in ZeD's pixel art, the same engine and
print rules as adpx.py (one ink, every ramp from the paper to the ink, one art pixel = one design pixel, the one view:
front and a little from above, a level circle an ellipse VIEW = 0.26 as tall as it is wide). They register into
adpx.DESIGNS like adpx.py's own.
usage: python adpx_b5d.py [name ...]  -> px/<name>.png (ink on transparent); no names = this module's eight"""
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))     # beside adpx.py (python -I leaves it off)
import adpx                                                         # noqa: E402
from adpx import (E, Mask, INK, VIEW, design, render, ellipse_m, cyl_v, Cyl, band_v, capsule, disc, stroke,
                  glyphs)

INK_ = tuple(int(v) for v in INK)
MINE = []


def mine(w, h):
    def deco(fn):
        design(w, h)(fn); MINE.append(fn.__name__)
        return fn
    return deco


def rot(pts, ang, o):
    """points turned by `ang` degrees about o (screen axes: positive turns clockwise)"""
    a = math.radians(ang); ca, sa = math.cos(a), math.sin(a)
    return [(o[0] + x * ca - y * sa, o[1] + x * sa + y * ca) for x, y in pts]


def ink_line(d, pts, w=1.0):
    m = Mask(d.W, d.H).line(pts, w).get()
    d.emit[m, :3] = INK_; d.emit[m, 3] = 255
    return m


def tufts(d, x0, x1, y, seed=1, n=None):
    """grass at a foot line: short ink blades, a few to a tuft"""
    r = np.random.default_rng(seed)
    n = n or max(2, int((x1 - x0) / 7))
    ink_line(d, [(x0, y + 0.5), (x1, y + 0.5)], 1.0)                      # the ground's edge
    for k in range(n):
        x = x0 + (x1 - x0) * (k + r.uniform(0.1, 0.9)) / n
        for _ in range(int(r.integers(2, 4))):
            lean = r.uniform(-2.2, 2.2); hh = r.uniform(2.5, 5.5)
            ink_line(d, [(x, y), (x + lean, y - hh)], 1.0)
            x += r.uniform(1.0, 2.2)


def onslope(m, slope, x0):
    """shift each column of a mask so print rides a slope (dy per px of x, from x0)"""
    out = np.zeros_like(m)
    H = m.shape[0]
    for x in range(m.shape[1]):
        dy = int(round(slope * (x - x0)))
        col = m[:, x]
        if dy > 0: out[dy:, x] = col[:H - dy]
        elif dy < 0: out[:H + dy, x] = col[-dy:]
        else: out[:, x] = col
    return out


def textmask(d, t, x, y, font="35", scale=1, align="c"):
    g = glyphs(t, font)
    if scale > 1: g = np.kron(g, np.ones((scale, scale), bool))
    m = np.zeros((d.H, d.W), bool)
    if align == "c": x = int(round(x - g.shape[1] / 2))
    ya, xa = max(0, y), max(0, x)
    yb, xb = min(d.H, y + g.shape[0]), min(d.W, x + g.shape[1])
    m[ya:yb, xa:xb] = g[ya - y:yb - y, xa - x:xb - x]
    return m


# ------------------------------------------------------------------ Muldraugh Karate: a black belt
@mine(142, 104)
def karate(d):
    # a black belt tied in its square knot, laid flat (the loop pressed flat into one band, as a belt lies folded on
    # the mat), seen a little from above (the band's top edge catches the light); the two ends hang down from the knot
    # in a V, the right one with its three degree bars; rows of stitching run the belt's length
    X = d.XX + 0.5; Y = d.YY + 0.5
    band = Mask(d.W, d.H).rrect(4, 24, 134, 17, 6).get()
    d.slab(band, 7, "k", bevel=3, polish=0.45)
    d.slab(Mask(d.W, d.H).rrect(6, 22, 130, 4, 2).get() & ~band, 5, "k", bevel=1, polish=0.4)   # the back layer's edge
    for yy in (28, 31, 34, 37):                                                                  # the stitching
        d.paint(band & (np.abs(Y - yy - 0.5) < 0.5) & (X > 9) & (X < 133), "d")
    # the ends, hanging from under the knot: each a flat strip of the belt, easing out from the middle in a soft curve
    def strip(cl, hw):
        nl, nr = [], []
        for i, (x, y) in enumerate(cl):
            xa, ya = cl[max(0, i - 1)]; xb, yb = cl[min(len(cl) - 1, i + 1)]
            tx, ty = xb - xa, yb - ya; ln = math.hypot(tx, ty) or 1
            nx, ny = -ty / ln, tx / ln
            nl.append((x + nx * hw, y + ny * hw)); nr.append((x - nx * hw, y - ny * hw))
        return nl, nr
    def tail(x_end, bend, length, bars):
        o = (71.0, 38.0)
        cl = []
        for i in range(25):
            t = i / 24
            cl.append((o[0] + (x_end - o[0]) * t + bend * math.sin(math.pi * t), o[1] + length * t))
        nl, nr = strip(cl, 7.5)
        m = Mask(d.W, d.H).poly(nl + nr[::-1]).get()
        d.slab(m, 10, "k", bevel=3, polish=0.45)
        for off in (-4.5, -1.5, 1.5, 4.5):
            a_, b_ = strip(cl[2:-1], off)
            d.paint(Mask(d.W, d.H).line(a_, 0.8, caps=False).get() & m, "d")
        for k in range(bars):                                                              # the degree bars
            i0 = 24 - 5 - k * 3
            q = [nl[i0], nl[i0 + 1], nr[i0 + 1], nr[i0]]
            d.paint(Mask(d.W, d.H).poly(q).get() & m, "l")
        return m
    tail(42, -3, 62, 0)
    tail(104, 4, 60, 3)
    # the knot: the wrap round the band, round in section; the end crossing over it on the slant, into the right tail
    knot = Mask(d.W, d.H).rrect(61, 18, 21, 27, 6).get()
    dist = E.edt(knot)
    d.h = np.where(knot, 12 + np.sqrt(np.minimum(dist, 8.0) / 8.0) * 6, d.h).astype(np.float32)
    d.mat[knot] = d.mid("k"); d.solid |= knot; d.polish[knot] = 0.5; d.tex[knot] = 0
    up = Mask(d.W, d.H).rrect(64, 14, 15, 8, 3).get() & ~knot
    d.slab(up, 4, "k", bevel=2, polish=0.5, on=12)                                               # the loop over the top
    cross = Mask(d.W, d.H).line([(64, 21), (79, 42)], 8, caps=False).get() & Mask(d.W, d.H).rrect(59, 16, 25, 31, 6).get()
    d.slab(cross, 3, "k", bevel=2, polish=0.55, on=17)
    for off in (-1.5, 1.5):
        d.paint(Mask(d.W, d.H).line([(64 + off * 1.6, 21 - off * 1.1), (79 + off * 1.6, 42 - off * 1.1)], 0.8).get() & cross, "d")
    d.grain_pebble(d.solid & (d.mat == d.mid("k")), 0.03, seed=4)


# ------------------------------------------------------------------ MindPeace Insurance: a house under an umbrella
@mine(150, 120)
def mindpeace(d):
    X = d.XX + 0.5; Y = d.YY + 0.5
    # the house, in the bed's three-quarter axes: its length runs right and a little up, its depth back and to the
    # left; the gable end toward us on the left, the long wall facing us, a roof slope over it, a chimney
    O = np.array([30.0, 112.0]); AL = np.array([1.0, -0.16]); AW = np.array([-0.48, -0.17])
    def P(l, w, h): q = O + l * AL + w * AW; return (float(q[0]), float(q[1] - h))
    def quad(*pts): return Mask(d.W, d.H).poly(list(pts)).get()
    L, Wd, H, R = 50, 30, 26, 18
    wall = quad(P(0, 0, 0), P(L, 0, 0), P(L, 0, H), P(0, 0, H))
    d.flat(wall, 10, "w", polish=0.2)
    for k in range(1, 7):                                                                       # the clapboard
        d.seam(Mask(d.W, d.H).line([P(0, 0, k * 3.8), P(L, 0, k * 3.8)], 0.8).get() & wall, 0.12)
    gable = quad(P(0, 0, 0), P(0, 0, H), P(0, Wd / 2, H + R), P(0, Wd, H), P(0, Wd, 0))
    d.ramp_h(gable, 4, 10, axis="x", mat="l", polish=0.2)
    for k in range(1, 9):
        d.seam(Mask(d.W, d.H).line([P(0, 0, k * 3.8), P(0, Wd, k * 3.8)], 0.8).get() & gable, 0.12)
    # the roof's front slope, from the eave up to the ridge, its edge over the gable
    roof = quad(P(-2, -3, H - 2), P(L + 2, -3, H - 2), P(L + 2, Wd / 2, H + R + 1), P(-2, Wd / 2, H + R + 1))
    d.ramp_h(roof, 6, 16, axis="y", mat="d", polish=0.3)
    for k in range(1, 5):                                                                       # the shingle courses
        f = k / 5
        a = P(-2, -3 + (Wd / 2 + 3) * f, H - 2 + (R + 3) * f); b = P(L + 2, -3 + (Wd / 2 + 3) * f, H - 2 + (R + 3) * f)
        d.seam(Mask(d.W, d.H).line([a, b], 0.8).get() & roof, 0.3)
    barge = quad(P(-2, -3, H - 2), P(-2, Wd / 2, H + R + 1), P(-2, Wd / 2, H + R + 4), P(-2, -3, H + 1))
    d.slab(barge, 17, "k", bevel=0.8)
    barge2 = quad(P(-2, Wd / 2, H + R + 1), P(-2, Wd + 3, H - 2), P(-2, Wd + 3, H + 1), P(-2, Wd / 2, H + R + 4))
    d.slab(barge2, 13, "k", bevel=0.8)
    # the chimney, standing on the slope
    ch = quad(P(36, 6, H + 6), P(43, 6, H + 6), P(43, 6, H + R + 3), P(36, 6, H + R + 3))
    d.slab(ch, 18, "m", bevel=1, polish=0.2)
    for k in range(1, 5):
        d.seam(Mask(d.W, d.H).line([P(36, 6, H + 6 + k * 4.4), P(43, 6, H + 6 + k * 4.4)], 0.7).get() & ch, 0.15)
    d.flat(quad(P(35, 6, H + R + 3), P(44, 6, H + R + 3), P(44, 10, H + R + 3), P(35, 10, H + R + 3)), 19, "k")
    # the door and the windows in the wall, the window in the gable
    door = quad(P(30, 0, 0), P(39, 0, 0), P(39, 0, 17), P(30, 0, 17))
    d.slab(door, 12, "d", bevel=0.8, polish=0.3)
    dx, dy = P(37, 0, 8); d.dome(dx, dy, 1.0, 1.0, 1, "chrome", on="add")
    for l0 in (7, 18):
        win = quad(P(l0, 0, 9), P(l0 + 8, 0, 9), P(l0 + 8, 0, 19), P(l0, 0, 19))
        d.well(win, 2, mat="k", bevel=0.6)
        a, b = P(l0 + 4, 0, 9), P(l0 + 4, 0, 19); d.paint(Mask(d.W, d.H).line([a, b], 0.8).get() & win, "l")
        a, b = P(l0, 0, 14), P(l0 + 8, 0, 14); d.paint(Mask(d.W, d.H).line([a, b], 0.8).get() & win, "l")
    gw = quad(P(0, 11, 12), P(0, 19, 12), P(0, 19, 21), P(0, 11, 21))
    d.well(gw, 2, mat="k", bevel=0.6)
    # the umbrella over it: a big canopy of eight gores, black and white by turns, seen a little from above (its rim a
    # level circle, an ellipse 0.26 tall); the fabric scallops up between the ribs' tips; the shaft runs straight down
    # beside the house into the ground
    cx, rimY, Rr, Hd = 84.0, 34.0, 64.0, 22.0
    se, ce = VIEW, math.sqrt(1 - VIEW ** 2)
    n = 8
    def pt(t, phi, lift=0.0):
        r = Rr * math.sin(t * math.pi / 2); y3 = Hd * math.cos(t * math.pi / 2) + lift
        return (cx + r * math.sin(phi), rimY - y3 * ce + r * math.cos(phi) * se)
    gores = []
    for i in range(n):
        p0 = 2 * math.pi * i / n + math.pi / n; p1 = p0 + 2 * math.pi / n
        pts = [pt(t / 12, p0) for t in range(13)]
        for k in range(1, 12):
            ph = p0 + (p1 - p0) * k / 12
            pts.append(pt(1 - (0.07 * math.sin(math.pi * k / 12) if math.cos(ph) > 0 else 0.0), ph))
        pts += [pt(t / 12, p1) for t in range(12, -1, -1)]
        gores.append(((math.cos((p0 + p1) / 2)), i, pts))
    can = np.zeros((d.H, d.W), bool)
    for _, i, pts in sorted(gores):
        m = Mask(d.W, d.H).poly(pts).get()
        can |= m
        d.mat[m] = d.mid("k" if i % 2 else "w"); d.solid |= m; d.polish[m] = 0.5; d.tex[m] = 0
    # its height: a dome over the canopy's outline, highest toward the front rim
    dist = E.edt(can)
    d.h = np.where(can, 30 + np.sqrt(np.minimum(dist, 14.0) / 14.0) * 10 + (Y - rimY) * 0.25, d.h).astype(np.float32)
    for i in range(n):
        ph = 2 * math.pi * i / n + math.pi / n
        if math.cos(ph) > -0.2:
            d.seam(Mask(d.W, d.H).line([pt(t / 12, ph) for t in range(13)], 0.8).get() & can, 0.25)   # the ribs
        tx, ty = pt(1, ph)
        if math.cos(ph) > 0: d.dome(tx, ty + 0.5, 1.3, 1.3, 2, "chrome", on="add")               # the rib tips
    ax, ay = pt(0, 0)
    capsule(d, [(ax, ay + 1), (ax, ay - 7)], 2.4, 3, "chrome", polish=1.0)                       # the finial
    d.dome(ax, ay - 7, 1.8, 1.8, 2, "chrome", on="add")
    fy = rimY + Rr * se                                                                         # under the front rim
    shaft = Mask(d.W, d.H).rect(cx - 1.5, fy - 2, 3, 112 - fy + 2).get() & ~can
    d.cyl(cx - 1.5, fy - 2, 3, 112 - fy + 2, 8, "chrome", axis="v", polish=1.0, mask=shaft)
    d.well(Mask(d.W, d.H).ellipse(cx, 112, 4, 1.2).get(), 1, mat="k", bevel=0.5)               # where it goes in
    tufts(d, 8, 64, 113, seed=3); tufts(d, 74, 96, 113, seed=5, n=4)
    # the rain coming down on it, short streaks that stop short of the canopy
    r = np.random.default_rng(9)
    near = E.edt(~can) <= 1.5
    for k in range(17):
        for row in range(4):
            x = 12 + k * 7.6 + r.uniform(-1.5, 1.5) + row * 3.5; y = -2 + row * 7 + r.uniform(-1.5, 1.5)
            m = Mask(d.W, d.H).line([(x, y), (x - 1, y + 4)], 1.0).get()
            if x > 142 or (m & (near | d.solid)).any() or (m & (d.emit[..., 3] > 0)).any(): continue
            d.emit[m, :3] = INK_; d.emit[m, 3] = 255


# ------------------------------------------------------------------ Homeward Real Estate: the yard sign
@mine(122, 118)
def homeward(d):
    # a yard sign: a white-painted 4x4 post, its crossarm out to the right, the sign hung from two hooks reading FOR
    # SALE, a SOLD rider clipped on its top edge; seen from the front and a little from above (the tops of the post
    # and the arm catch the light)
    X = d.XX + 0.5; Y = d.YY + 0.5
    post = Mask(d.W, d.H).rect(10, 10, 11, 104).get()
    d.slab(post, 12, "l", bevel=2.5, polish=0.25)
    d.grain_wood(post, scale=0.5, seed=6, along="y"); d.tex[post] *= 0.35
    d.flat(Mask(d.W, d.H).poly([(10, 10), (21, 10), (23, 7), (12, 7)]).get(), 13, "w", polish=0.2)   # its top
    arm = Mask(d.W, d.H).rect(21, 18, 94, 8).get()
    d.slab(arm, 11, "l", bevel=2, polish=0.25)
    d.grain_wood(arm, scale=0.5, seed=7); d.tex[arm] *= 0.35
    d.flat(Mask(d.W, d.H).poly([(21, 18), (115, 18), (117, 16), (23, 16)]).get() & ~post, 12, "w", polish=0.2)
    d.slab(Mask(d.W, d.H).rect(114, 16, 3, 10).get(), 10, "m", bevel=0.6)                       # the arm's cut end
    # the brace from the post to the arm
    stroke(d, [(21, 40), (40, 26)], 4, 10, "l", polish=0.25)
    # the hooks: an eye screwed into the arm, an S down to the sign's top
    for hx in (44, 100):
        d.torus(hx, 29, 1.2, 2.8, 3, "chrome", on=11)
        capsule(d, [(hx, 31), (hx, 39)], 1.6, 2, "chrome", polish=1.0)
        d.torus(hx, 41, 1.0, 2.6, 3, "chrome", on=11)
    # the sign
    sg = Mask(d.W, d.H).rect(34, 42, 76, 54).get()
    d.slab(sg, 9, "w", bevel=1, polish=0.25)
    d.flat(Mask(d.W, d.H).rect(35, 41, 74, 1).get(), 10, "l")                                   # its top edge
    border = sg & ~Mask(d.W, d.H).rect(37, 45, 70, 48).get()
    d.paint(border, "p")
    for hx in (44, 100):
        d.well(Mask(d.W, d.H).ellipse(hx, 43.5, 1.2, 1.2).get(), 1, mat="k")
    d.text("FOR", 72, 50, "p", font="57", scale=2, align="c")
    d.text("SALE", 72, 67, "p", font="57", scale=2, align="c")
    d.paint(Mask(d.W, d.H).rect(37, 84, 70, 9).get(), "p")
    d.text("HOMEWARD", 72, 86, "pw", align="c")
    # the SOLD rider, clipped on the sign's top edge between the hooks
    rd = Mask(d.W, d.H).rect(57, 31, 30, 11).get()
    d.slab(rd, 11, "k", bevel=0.8, polish=0.3)
    d.text("SOLD", 72, 33, "pw", font="57", align="c")
    for cx_ in (61, 83):
        d.slab(Mask(d.W, d.H).rect(cx_ - 1.5, 40, 3, 4).get(), 12, "chrome", bevel=0.5, polish=1.0)  # its clips
    tufts(d, 4, 30, 115, seed=2, n=6)


# ------------------------------------------------------------------ U-Store It: three moving boxes
@mine(132, 116)
def ustore(d):
    # three moving boxes square to us, seen a little from above (each top a strip 0.26 of its depth): two taped shut on
    # the floor, side by side and touching, the third on top of them with its flaps open
    X = d.XX + 0.5; Y = d.YY + 0.5
    def box(x0, x1, y_top, y_bot, depth, z, tape=True, label=None, arrows=False, seed=1):
        dt = depth * VIEW
        front = Mask(d.W, d.H).rect(x0, y_top, x1 - x0, y_bot - y_top).get()
        top = Mask(d.W, d.H).rect(x0, y_top - dt, x1 - x0, dt).get()
        d.slab(front, z, "m", bevel=1.2, polish=0.2)
        d.ramp_h(top, z - 3, z, axis="y", mat="m", polish=0.2)
        d.tex[top] = 0.09                                                                       # the lit top
        d.grain_pebble(front, 0.03, seed=seed)
        d.seam(Mask(d.W, d.H).rect(x0, y_top, x1 - x0, 1).get(), 0.2)                           # the front edge
        cx = (x0 + x1) / 2
        if tape:
            t1 = Mask(d.W, d.H).rect(cx - 4, y_top - dt, 8, dt + 11).get()
            d.flat(t1, z + 0.4, "l", polish=0.8)
            d.seam(Mask(d.W, d.H).rect(cx - 0.5, y_top - dt, 1, dt).get(), 0.25)                 # the flaps' join
            d.dark[Mask(d.W, d.H).poly([(cx - 4, y_top + 11), (cx + 4, y_top + 10), (cx + 4, y_top + 11.5), (cx - 4, y_top + 12)]).get()] = 0.0
        if label:
            d.text(label, int(cx), int(y_top + 20), "p", align="c")
        if arrows:
            for ax in (x1 - 13, x1 - 7):
                d.paint(Mask(d.W, d.H).poly([(ax, y_bot - 14), (ax + 3, y_bot - 10), (ax - 3, y_bot - 10)]).get(), "p")
                d.paint(Mask(d.W, d.H).rect(ax - 1, y_bot - 10, 2, 5).get(), "p")
        hh = Mask(d.W, d.H).rrect(cx - 7, y_bot - 13 if not arrows else y_bot - 13, 14, 4, 2).get()
        return front, top
    box(4, 64, 66, 112, 30, 8, label="BOOKS", seed=2)
    box(64, 128, 66, 112, 30, 9, label="TOOLS", arrows=True, seed=3)
    # the top box, open: the back flap standing, the side flaps leaning out, the front flap hanging down over its front
    x0, x1, yt, yb, dep = 26, 100, 35, 65, 28
    dt = dep * VIEW
    front = Mask(d.W, d.H).rect(x0, yt, x1 - x0, yb - yt).get()
    back = Mask(d.W, d.H).poly([(x0 + 1, yt - dt), (x1 - 1, yt - dt), (x1 - 2, yt - dt - 15), (x0 + 2, yt - dt - 15)]).get()
    d.ramp_h(back, 8, 14, axis="y", mat="m", polish=0.2)
    d.tex[back] = -0.05
    lf = Mask(d.W, d.H).poly([(x0, yt), (x0 + 2, yt - dt), (x0 - 15, yt - dt - 12), (x0 - 17, yt - 9)]).get()
    rf = Mask(d.W, d.H).poly([(x1, yt), (x1 - 2, yt - dt), (x1 + 15, yt - dt - 12), (x1 + 17, yt - 9)]).get()
    d.ramp_h(lf, 18, 12, axis="x", mat="m", polish=0.2)
    d.ramp_h(rf, 12, 18, axis="x", mat="m", polish=0.2)
    d.tex[rf] = -0.06
    inside = Mask(d.W, d.H).rect(x0 + 2, yt - dt, x1 - x0 - 4, dt).get()
    d.flat(inside, 10, "k", polish=0.1)
    d.dark[inside & (Y < yt - dt + 3)] = 0.15
    d.slab(front, 18, "m", bevel=1.2, polish=0.2)
    d.grain_pebble(front, 0.03, seed=5)
    ff = Mask(d.W, d.H).poly([(x0, yt), (x1, yt), (x1 - 1, yt + 9), (x0 + 1, yt + 9)]).get()
    d.slab(ff, 1.2, "l", bevel=0.6, polish=0.2, on=18)                                          # the front flap, its inside out
    d.seam(Mask(d.W, d.H).rect(x0, yt, x1 - x0, 1).get(), 0.3)                                  # its fold
    # the torn tape on the flaps
    cx = (x0 + x1) / 2
    d.flat(Mask(d.W, d.H).poly([(cx - 4, yt + 1), (cx + 4, yt + 1), (cx + 4, yt + 7), (cx + 1, yt + 9), (cx - 2, yt + 6), (cx - 4, yt + 8)]).get(), 19.6, "w", polish=0.8)
    d.flat(Mask(d.W, d.H).poly([(cx - 4, yt - dt - 1), (cx + 4, yt - dt - 1), (cx + 4, yt - dt - 6), (cx + 2, yt - dt - 4), (cx - 1, yt - dt - 7), (cx - 4, yt - dt - 5)]).get() & back, 14.5, "w", polish=0.8)
    d.text("KITCHEN", int(cx), yt + 16, "p", align="c")
    d.paint(Mask(d.W, d.H).line([(cx - 14, yt + 23), (cx + 14, yt + 22)], 0.9).get() & front, "p")


# ------------------------------------------------------------------ Old Mill Water: the pitcher pump
@mine(124, 122)
def oldmill(d):
    # a cast-iron pitcher pump on a short pipe stand over a concrete pad: the barrel with its beads, the round cap on
    # top (an ellipse 0.26) with the ear and link the handle pivots on, the plunger rod up to the handle's short end,
    # the handle raised up and out to the right; the spout out of the barrel's left, its mouth turned down; a
    # galvanized pail on the pad under the spout (its rim an ellipse 0.26, the bail leaning back), the water falling
    # into it (the director, Nov 7: "why is it pumping into a coffee mug? Not a bucket.")
    X = d.XX + 0.5; Y = d.YY + 0.5
    # the pad
    pad_f = Mask(d.W, d.H).rect(4, 108, 108, 11).get()
    pad_t = Mask(d.W, d.H).rect(4, 101, 108, 7).get()
    d.slab(pad_f, 6, "m", bevel=1, polish=0.1)
    d.ramp_h(pad_t, 3, 6, axis="y", mat="l", polish=0.1)
    d.grain_pebble(pad_f | pad_t, 0.08, seed=3)
    d.seam(Mask(d.W, d.H).rect(4, 108, 108, 1).get(), 0.15)
    # the pipe stand on its floor flange
    disc(d, 66, 103, 12, 12 * VIEW, 3, "k", polish=0.4, on=7)
    cyl_v(d, 60, 72, 76, 103, 8, "d", polish=0.7, on=6)
    cy_p = Cyl(d, 60, 72, 6 * VIEW)
    # the barrel on its base flange
    cyl_v(d, 48, 84, 72, 78, 12, "k", polish=0.5, top_ry=18 * VIEW, bot_ry=18 * VIEW, on=6)
    body, top = cyl_v(d, 52, 80, 32, 72, 12, "k", polish=0.55, top_ry=14 * VIEW, bot_ry=14 * VIEW, on=8)
    cy = Cyl(d, 52, 80, 14 * VIEW)
    for vv in (38, 66):
        r = band_v(d, body, cy, vv, vv + 2); d.h[r] += 1.2                                        # the cast beads
    d.grain_pebble(body, 0.05, seed=6)
    # the cap: a round lid with its rim over the barrel, a low crown, the boss in the middle with the rod's gland
    capb, capt = cyl_v(d, 50, 82, 28, 32, 13, "k", polish=0.5, top_ry=16 * VIEW, bot_ry=16 * VIEW, on=9)
    disc(d, 66, 28.4, 12, 12 * VIEW, 1.6, "k", polish=0.5, on=float(d.h[28, 66]))                  # the crown
    cyl_v(d, 62, 70, 24, 28, 4, "k", polish=0.6, top_ry=4 * VIEW, bot_ry=4 * VIEW, on=22)          # the boss
    d.well(Mask(d.W, d.H).ellipse(66, 24.2, 1.6, 0.6).get(), 1, mat="k")
    # the ear on the cap's right, the link standing up from it to the handle's pivot
    d.slab(Mask(d.W, d.H).rect(78, 23, 6, 6).get(), 23, "k", bevel=1.2, polish=0.5)
    d.slab(Mask(d.W, d.H).line([(81, 25), (82, 13)], 3.0).get(), 24, "k", bevel=1.0, polish=0.6)
    capsule(d, [(66, 24), (66, 17)], 2.4, 25, "chrome", polish=1.0)                              # the plunger rod
    # the handle: its short end over the rod, the pivot on the link, the long arm raised out to the right, the grip
    capsule(d, [(63, 18.5), (66, 17.5), (82, 13), (96, 8.5)], 4.6, 27, "k", polish=0.6)
    capsule(d, [(96, 8.5), (108, 5.5), (114, 5.5), (118, 7.5)], 3.8, 27, "k", polish=0.6)
    d.dome(118.5, 8, 2.6, 2.6, 3, "k", on="add")
    d.dome(82, 13, 1.7, 1.7, 2, "chrome", on="add")                                             # the pins
    d.dome(81, 25.5, 1.4, 1.4, 2, "chrome", on="add")
    d.dome(66, 17.5, 1.5, 1.5, 2, "chrome", on="add")
    # the spout: out of the barrel's left a little toward us, tapering, its end turned down to a flared mouth
    capsule(d, [(56, 45), (46, 46), (38, 48)], 8.4, 10, "k", polish=0.55)
    capsule(d, [(38, 48), (32, 50.5), (29.5, 54)], 7.0, 10, "k", polish=0.55)
    d.slab(Mask(d.W, d.H).line([(29.5, 53), (29, 57)], 6.4).get(), 10, "k", bevel=1.6, polish=0.55)
    mouth = ellipse_m(d, 29, 57.6, 4.4, 4.4 * VIEW + 0.6)                                          # the flared lip
    d.slab(mouth, 10.5, "k", bevel=0.8, polish=0.6)
    # the pail: a galvanized bucket, tapered, the bail leaning back over the far rim, the ears on its sides
    pcx, yt, yb, rt, rb = 28.5, 78.0, 103.0, 16.5, 13.0
    bail = Mask(d.W, d.H).arc(pcx, yt + 3.2, rt + 0.6, 15, 180, 360, 1.6).get()
    d.slab(bail, 9, "d", bevel=0.7, polish=0.9)
    frac = np.clip((Y - yt) / (yb - yt), 0, 1)
    hw = rt + (rb - rt) * frac
    pbody = (Y >= yt) & (Y <= yb) & (np.abs(X - pcx) <= hw)
    pbody |= ellipse_m(d, pcx, yb, rb, rb * VIEW) & (Y > yb)
    t = np.clip((X - pcx) / hw, -1, 1); c = np.sqrt(1 - t ** 2)
    d.h = np.where(pbody, 4 + c * 7, d.h).astype(np.float32)
    d.mat[pbody] = d.mid("m"); d.solid |= pbody; d.polish[pbody] = 0.7; d.tex[pbody] = 0
    for v0, ryv in ((87.0, rt * VIEW), (96.0, rb * VIEW)):                                          # the pressed rings
        rib = pbody & (np.abs(Y - (v0 + ryv * c)) < 0.9)
        d.h[rib] += 0.9
    rim = (ellipse_m(d, pcx, yt + 0.9, rt + 1.0, (rt + 1.0) * VIEW) | ellipse_m(d, pcx, yt - 0.9, rt + 1.0, (rt + 1.0) * VIEW))
    opening = ellipse_m(d, pcx, yt - 0.3, rt - 0.6, (rt - 0.6) * VIEW)
    d.slab(rim & ~opening, 12.5, "m", bevel=1.1, polish=0.9)                                       # the rolled rim
    # inside the rim: the far inside wall standing above the water line, in shadow, and the water a little below the
    # rim, dark and glassy, so the top reads as an open pail of water and not a lid
    oy = yt - 0.3
    wy, wrx = oy + 2.0, rt - 1.6                                                                   # the water line
    d.flat(opening, 11, "l", polish=0.0)                                                           # the inside wall
    d.flatlight |= opening; d.noshadow |= opening
    d.dark[opening] = -0.12
    wat = opening & ellipse_m(d, pcx, wy, wrx, wrx * VIEW)
    d.flat(wat, 11, "k", polish=0.0)                                                               # the water
    d.dark[wat] = 0.2
    d.seam(opening & ~wat & ellipse_m(d, pcx, wy, wrx + 0.8, (wrx + 0.8) * VIEW), 0.35)            # the water line
    for sx in (-1, 1):
        ex = pcx + sx * (rt + 0.6)
        d.slab(Mask(d.W, d.H).rect(ex - 1.5, yt + 1.5, 3, 4).get(), 12, "m", bevel=0.8, polish=0.9)  # the ears
        d.dome(ex, yt + 3.2, 1.0, 1.0, 1.5, "d", on="add")
    # the water falling from the mouth into the pail, into the water; a ripple ring round where it lands
    sx_ = 28.8
    stream = Mask(d.W, d.H).line([(29, 58.5), (29, 70), (sx_, wy)], 2.2).get()
    d.slab(stream, 14, "l", bevel=0.9, polish=1.0)
    d.noshadow |= stream
    ra = 6.0
    ring = [(sx_ + ra * math.cos(math.radians(t)), wy + ra * VIEW * math.sin(math.radians(t))) for t in range(0, 361, 10)]
    rip = Mask(d.W, d.H).line(ring, 1.0).get() & wat & ~(stream & (Y < wy))
    d.flat(rip, 11, "w", polish=0.0); d.flatlight |= rip; d.dark[rip] = -0.2
    d.noshadow |= rip


# ------------------------------------------------------------------ Restwell & Sons: the wreath on its stand
@mine(122, 132)
def restwell(d):
    # a round wreath of carnations standing on its three-legged wire easel, face on; a satin sash across it from the
    # upper left, its tails hanging at the lower right with their notched ends
    X = d.XX + 0.5; Y = d.YY + 0.5
    cx, cy, R0, R1 = 61.0, 58.0, 19.0, 43.0
    # the easel behind: two front legs splayed from the top, the back leg between them, a brace across
    ap = (61, 6)
    capsule(d, [ap, (62, 118)], 1.8, 2, "k", polish=0.6)                                         # the back leg
    capsule(d, [ap, (22, 128)], 2.2, 3, "k", polish=0.6)
    capsule(d, [ap, (100, 128)], 2.2, 3, "k", polish=0.6)
    capsule(d, [(36, 110), (86, 110)], 1.8, 3, "k", polish=0.6)
    d.dome(ap[0], ap[1], 2.6, 2.6, 4, "k", on="add")
    # the wreath: a ring of greenery, carnations packed on it in three rings, leaves at the edges
    d.torus(cx, cy, R0, R1, 12, "d", polish=0.2, on=6)
    d.grain_pebble(d.solid & (d.mat == d.mid("d")), 0.12, seed=4)
    r = np.random.default_rng(5)
    def leaf(p, a, ln, wd, z):
        ca, sa = math.cos(a), math.sin(a)
        pts = [(p[0] + ca * ln * t - sa * wd * math.sin(math.pi * t), p[1] + sa * ln * t + ca * wd * math.sin(math.pi * t))
               for t in np.linspace(0, 1, 9)]
        pts += [(p[0] + ca * ln * t + sa * wd * math.sin(math.pi * t), p[1] + sa * ln * t - ca * wd * math.sin(math.pi * t))
                for t in np.linspace(1, 0, 9)[1:]]
        m = Mask(d.W, d.H).poly(pts).get()
        d.slab(m, 3, "d", bevel=1.2, polish=0.4, on=z)
        d.seam(Mask(d.W, d.H).line([p, (p[0] + ca * ln * 0.85, p[1] + sa * ln * 0.85)], 0.7).get() & m, 0.2)   # its vein
    for k in range(16):                                                                          # leaves out at the rim
        a = 2 * math.pi * (k + 0.5) / 16 + r.uniform(-0.08, 0.08)
        leaf((cx + (R1 - 6) * math.cos(a), cy + (R1 - 6) * math.sin(a)), a + r.uniform(-0.3, 0.3), 13, 3.2, 12)
    for k in range(9):                                                                           # and in at the hole
        a = 2 * math.pi * k / 9 + 0.3
        leaf((cx + (R0 + 5) * math.cos(a), cy + (R0 + 5) * math.sin(a)), a + math.pi + 0.4, 9, 2.4, 12)
    # the carnations: each a ruffled head (its edge pinked), low and soft, the petals' folds in it
    for ring, n, rad, off in ((R0 + 5.5, 10, 5.4, 0.0), ((R0 + R1) / 2, 14, 5.8, 0.25), (R1 - 6.0, 18, 5.6, 0.1)):
        for k in range(n):
            a = 2 * math.pi * (k + off) / n + r.uniform(-0.04, 0.04)
            fx, fy = cx + ring * math.cos(a), cy + ring * math.sin(a)
            mat = "l" if (k * 7 + n) % 4 == 0 else "w"
            pts = [(fx + (rad * (1.0 if j % 2 else 0.8)) * math.cos(2 * math.pi * j / 14 + k),
                    fy + (rad * (1.0 if j % 2 else 0.8)) * math.sin(2 * math.pi * j / 14 + k)) for j in range(14)]
            m = Mask(d.W, d.H).poly(pts).get()
            dist = E.edt(m)
            d.h = np.where(m, 14 + r.uniform(0, 1.5) + np.minimum(dist, 3.0) / 3.0 * 3, d.h).astype(np.float32)
            d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = 0.25; d.tex[m] = 0
            for j in range(3):                                                                   # the petals' folds
                b = 2 * math.pi * j / 3 + k
                arc = Mask(d.W, d.H).arc(fx, fy, rad * 0.5, rad * 0.5, math.degrees(b), math.degrees(b) + 80, 0.8).get()
                d.seam(arc & m, 0.22)
            d.grain_pebble(m, 0.07, seed=k + n)
    # the sash, across from the upper left to the lower right, over the flowers, lettered along its length
    a0, a1 = (14, 40), (108, 70)
    ang = math.atan2(a1[1] - a0[1], a1[0] - a0[0]); nx, ny = -math.sin(ang), math.cos(ang)
    wdt = 6.5
    sash = Mask(d.W, d.H).poly([(a0[0] + nx * wdt, a0[1] + ny * wdt), (a1[0] + nx * wdt, a1[1] + ny * wdt),
                                (a1[0] - nx * wdt, a1[1] - ny * wdt), (a0[0] - nx * wdt, a0[1] - ny * wdt)]).get()
    sash &= (np.hypot(X - cx, Y - cy) < R1 + 1)
    # the tails at the lower right, from under the sash's end, each cut in a notch
    for (bx, by), (ex, ey) in (((92, 74), (98, 118)), ((100, 70), (112, 110))):
        pts = [(bx - 5, by), (bx + 5, by), (ex + 5, ey), (ex, ey - 5), (ex - 5, ey)]
        d.slab(Mask(d.W, d.H).poly(pts).get(), 4, "w", bevel=1.5, polish=0.8, on=17)
    d.slab(sash, 4, "w", bevel=1.5, polish=0.8, on=19)
    d.seam(Mask(d.W, d.H).line([(a0[0] + nx * (wdt - 1.5), a0[1] + ny * (wdt - 1.5)), (a1[0] + nx * (wdt - 1.5), a1[1] + ny * (wdt - 1.5))], 0.7).get() & sash, 0.15)
    d.seam(Mask(d.W, d.H).line([(a0[0] - nx * (wdt - 1.5), a0[1] - ny * (wdt - 1.5)), (a1[0] - nx * (wdt - 1.5), a1[1] - ny * (wdt - 1.5))], 0.7).get() & sash, 0.15)
    slope = math.tan(ang)
    tm = textmask(d, "REST IN PEACE", int(cx), 0, font="57")
    yc = int(round(a0[1] + slope * (cx - a0[0]))) - 3
    tm2 = np.zeros_like(tm); tm2[yc:, :] = tm[:d.H - yc, :]
    d.paint(onslope(tm2, slope, cx) & sash, "p")


# ------------------------------------------------------------------ Knox Lock & Key: a ring of keys
# each key is drawn in its own frame: the hole at the origin (where the ring runs through it), the blade down +y;
# rot() turns it out from the ring's middle so the five fan out round the ring's foot
LAYERS = ("h", "mat", "solid", "polish", "tex", "dark")


def snap(d):
    return {k: getattr(d, k).copy() for k in LAYERS}


def through(d, hole, before):
    """a hole punched through what was just drawn: what was there before (a key behind, or the paper) shows in it"""
    for k in LAYERS:
        getattr(d, k)[hole] = before[k][hole]


def key_house(d, o, ang, mat, z, cut, L=46, hole_r=4.4, hole_y=-2.0):
    before = snap(d)
    bow = [(-8, -5), (-4.5, -8.5), (4.5, -8.5), (8, -5), (8, 7), (5, 10), (-5, 10), (-8, 7)]
    sh = [(-6.5, 9), (6.5, 9), (6.5, 12), (-6.5, 12)]
    cuts = []; yy = 15
    for dep in cut:
        if yy > L - 8: break
        cuts += [(4, yy), (4 - dep, yy + 1.5), (4 - dep, yy + 3), (4, yy + 4.5)]; yy += 5
    blade = [(-4, 12), (-4, L), (-1, L + 4), (4, L - 2)] + list(reversed(cuts)) + [(4, 12)]
    head = Mask(d.W, d.H).poly(rot(bow, ang, o)).poly(rot(sh, ang, o)).get()
    d.slab(head, z, mat, bevel=2.2, polish=0.9)
    bl = Mask(d.W, d.H).poly(rot(blade, ang, o)).get() & ~head
    d.slab(bl, z - 0.6, mat, bevel=1.2, polish=0.9)
    d.seam(Mask(d.W, d.H).line(rot([(-1.5, 15), (-1.5, L - 1)], ang, o), 0.8).get() & bl, 0.3)    # the keyway
    hx, hy = rot([(0, hole_y)], ang, o)[0]
    hole = ellipse_m(d, hx, hy, hole_r, hole_r)
    through(d, hole, before)                                                                    # the ring's hole
    return head | bl, head, hole


def key_car(d, o, ang, z, L=44, hole_r=4.4, hole_y=-3.0):
    # a car key of the day: the black plastic head with its grip lines, the nickel blade cut on both edges
    before = snap(d)
    hd = [(-9, -6), (-6, -9), (6, -9), (9, -6), (9, 9), (6, 12), (-6, 12), (-9, 9)]
    head = Mask(d.W, d.H).poly(rot(hd, ang, o)).get()
    d.slab(head, z, "k", bevel=3.0, polish=0.6)
    for k in (2, 5, 8):
        d.seam(Mask(d.W, d.H).line(rot([(-5, k), (5, k)], ang, o), 0.8).get() & head, 0.25)
    blade = [(-3.5, 12), (-3.5, L - 3), (0, L + 1), (3.5, L - 3), (3.5, 12)]
    bl = Mask(d.W, d.H).poly(rot(blade, ang, o)).get() & ~head
    d.slab(bl, z - 1, "chrome", bevel=1.2, polish=1.0)
    for k in range(4):
        y0 = 16 + k * 6
        for sgn in (-1, 1):
            q = rot([(sgn * 3.6, y0), (sgn * 1.8, y0 + 2), (sgn * 1.8, y0 + 3.5), (sgn * 3.6, y0 + 5)], ang, o)
            d.well(Mask(d.W, d.H).poly(q).get() & bl, 1.0)
    hx, hy = rot([(0, hole_y)], ang, o)[0]
    hole = ellipse_m(d, hx, hy, hole_r, hole_r)
    through(d, hole, before)
    return head | bl, head, hole


def key_skeleton(d, o, ang, z):
    # the old iron skeleton key: an oval bow (the ring runs through it), a collar, the long round shank, the bit with
    # its wards cut in steps
    pts = [(7.5 * math.cos(math.radians(a)), 4 + 8.5 * math.sin(math.radians(a))) for a in range(-90, 271, 10)]
    bowm = Mask(d.W, d.H).line(rot(pts, ang, o), 3.4).get()
    dist = E.edt(bowm)
    d.h = np.where(bowm, z - 2 + np.sqrt(np.minimum(dist, 1.7) / 1.7) * 3, d.h).astype(np.float32)
    d.mat[bowm] = d.mid("d"); d.solid |= bowm; d.polish[bowm] = 0.7; d.tex[bowm] = 0
    capsule(d, rot([(0, 13), (0, 16)], ang, o), 5.4, z, "d", polish=0.7)                         # the collar
    sh = capsule(d, rot([(0, 15), (0, 62)], ang, o), 3.4, z - 1, "d", polish=0.8)
    bit = Mask(d.W, d.H).poly(rot([(1, 50), (10, 50), (10, 53), (7, 53), (7, 55.5), (10, 55.5), (10, 60), (1, 60)], ang, o)).get()
    d.slab(bit, z - 1, "d", bevel=1.0, polish=0.7)
    return bowm | sh | bit, bowm, np.zeros_like(bowm)


@mine(132, 116)
def knoxlock(d):
    # a split ring of keys, face on, the five hanging fanned out round its foot: a brass house key, a car key with its
    # black head, the old iron skeleton key in the middle, a nickel house key, a short brass padlock key. Each key
    # hangs by its hole on the ring's wire: the wire runs in front of the key on one side of the hole, through the
    # hole, and on behind it (the director, Nov 7: "the key ring is not threaded through the keyholes")
    X = d.XX + 0.5; Y = d.YY + 0.5
    cx, cy, rr, wr = 66.0, 26.0, 22.0, 1.2
    def at(ang, push=0.0):
        a = math.radians(ang)
        return (cx - (rr + push) * math.sin(a), cy + (rr + push) * math.cos(a))
    owner = np.full((d.H, d.W), -1, np.int16)
    keys = []
    def hang(k, ang, res):
        allm, head, hole = res
        prev = owner.copy()
        owner[allm] = k; owner[hole] = prev[hole]
        keys.append((ang, head, hole))
    # back to front: the skeleton key behind (its long shank shows down the middle), the car key's black head in front;
    # each hole's center on the wire, so the wire shows across it with the paper above and below
    hang(0, 0, key_skeleton(d, at(0, 1.3), 0, 6))
    hang(1, 68, key_house(d, at(68, 2.0), 68, "m", 7, (2, 1, 3, 2, 1, 3), L=34))
    hang(2, -68, key_house(d, at(-68, 2.0), -68, "m", 7, (1, 3, 2, 3, 1, 2), L=30))
    hang(3, -35, key_house(d, at(-35, 2.0), -35, "chrome", 9, (3, 1, 2, 1, 3, 2, 1), L=42))
    hang(4, 35, key_car(d, at(35, 3.0), 35, 11, L=40))
    # the split ring: where a key owns the pixel, the wire is in front on the hole's near side (counterclockwise of
    # it) and behind on the far side; in each hole it shows across the middle, a step down
    rho = np.hypot(X - cx, Y - cy)
    wire = np.abs(rho - rr) <= wr
    phi = np.degrees(np.arctan2(-(X - cx), Y - cy))
    hidden = np.zeros_like(wire); sunk = np.zeros_like(wire)
    for k, (ang, head, hole) in enumerate(keys):
        hidden |= (owner == k) & head & (phi > ang)
        sunk |= hole & (owner < k)                                                               # the hole still in view
    show = wire & (~hidden | sunk)
    prof = np.sqrt(np.clip(1 - ((rho - rr) / wr) ** 2, 0, 1)) * 3
    base = np.where(sunk, 8.0, 12.0)
    d.h = np.where(show, base + prof, d.h).astype(np.float32)
    d.mat[show] = d.mid("chrome"); d.solid |= show; d.polish[show] = 1.0; d.tex[show] = 0
    # the split ring's second coil showing at the top, where its end laps over
    d.seam(Mask(d.W, d.H).line([(cx - 2.0, cy - rr - 1.6), (cx + 2.5, cy - rr + 1.6)], 0.8).get() & show, 0.45)


# ------------------------------------------------------------------ Throw Your Voice: the booklet and the thrower
@mine(112, 118)
def voice(d):
    # the little booklet standing upright, its cover printed THROW YOUR VOICE over sound waves, its stapled spine and
    # the top of its pages seen from a little above; the round tin voice thrower lying in front (an ellipse 0.26)
    X = d.XX + 0.5; Y = d.YY + 0.5
    x0, x1, y0, y1 = 20, 92, 8, 104
    pages = Mask(d.W, d.H).poly([(x0 + 1, y0), (x1, y0), (x1 + 2, y0 - 2), (x0 + 3, y0 - 2)]).get()
    d.flat(pages, 8, "w", polish=0.1)
    for k in range(x0 + 4, x1, 3): d.dark[(d.XX == k) & pages] = 0.12
    cover = Mask(d.W, d.H).rect(x0, y0, x1 - x0, y1 - y0).get()
    d.slab(cover, 8, "w", bevel=1, polish=0.15)
    d.slab(Mask(d.W, d.H).rect(x1, y0 - 1, 2, y1 - y0).get() & ~cover, 7, "l", bevel=0.5)          # the page edges
    # the waves: three lines rippling across, the title over them
    for k, yy in enumerate((37, 47, 57, 67)):
        pts = [(x, yy + 2.6 * math.sin((x - x0) * 0.42 + k * 1.7) * (0.3 + 0.7 * math.sin(math.pi * (x - x0) / (x1 - x0))))
               for x in np.linspace(x0 + 4, x1 - 4, 80)]
        d.paint(Mask(d.W, d.H).line(pts, 1.2).get() & cover, "l")
    d.paint(Mask(d.W, d.H).rect(x0 + 3, y0 + 3, x1 - x0 - 6, 21).get(), "p")
    d.text("THROW", int((x0 + x1) / 2), y0 + 7, "pw", font="57", scale=2, align="c")
    t = textmask(d, "YOUR", int((x0 + x1) / 2), 36, font="57", scale=2) | textmask(d, "VOICE", int((x0 + x1) / 2), 56, font="57", scale=2)
    halo = (E.edt(~t) <= 1.5) & ~t
    d.paint(halo & cover, "w"); d.paint(t, "p")
    d.paint(Mask(d.W, d.H).rect(x0 + 8, 80, x1 - x0 - 16, 1).get(), "p")
    d.text("32 PAGES", int((x0 + x1) / 2), 85, "p", align="c")
    frame = cover & ~Mask(d.W, d.H).rect(x0 + 2, y0 + 2, x1 - x0 - 4, y1 - y0 - 4).get()
    d.paint(frame, "p")
    for sy in (24, 86):
        d.slab(Mask(d.W, d.H).rect(x0 + 3, sy, 1.6, 7).get(), 9, "chrome", bevel=0.5, polish=1.0)   # the staples
    # the thrower: a little round tin, lying flat in front, a slot across its face, its rolled edge
    tx, ty, rx = 70, 106, 17
    ry = rx * VIEW
    side = Mask(d.W, d.H).rect(tx - rx, ty, 2 * rx, 3).get() | ellipse_m(d, tx, ty + 3, rx, ry)
    d.slab(side, 12, "chrome", bevel=1, polish=1.0)
    face = ellipse_m(d, tx, ty, rx, ry)
    d.h = np.where(face, 14 + (Y - ty) * 0.3, d.h).astype(np.float32)
    d.mat[face] = d.mid("chrome"); d.solid |= face; d.polish[face] = 1.0
    d.chrome_tone(face, 5)
    d.chrome_tone(face & ~ellipse_m(d, tx, ty, rx - 2, ry - 1), 7)
    d.well(Mask(d.W, d.H).ellipse(tx, ty, 6, 1.0).get(), 1.2, mat="k")
    d.seam(Mask(d.W, d.H).rect(tx - rx, ty + 1, 2 * rx, 1).get() & side & ~face, 0.3)


if __name__ == "__main__":
    os.makedirs("px", exist_ok=True)
    names = sys.argv[1:] or MINE
    for n in names:
        im = render(n)
        im.save(os.path.join("px", n + ".png"))
        print(n, im.size)
