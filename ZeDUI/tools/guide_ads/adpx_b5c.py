"""Batch 5c of the survival guide's third-page ads (Nov 7 2026): eight pictures in ZeD's pixel art, drawn the same way as
adpx.py's (the dashes' engine, one ink, the one view: front and a little from above, a level circle an ellipse VIEW = 0.26
as tall as it is wide). The designs register into adpx.DESIGNS; adpx.py is not edited (other batches run beside this).
usage: python adpx_b5c.py [name ...]  -> px/<name>.png (ink on transparent), only this batch's names"""
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import adpx                                                    # noqa: E402
from adpx import (E, Mask, VIEW, INK, design, render, capsule, disc, cyl_v, Cyl, band_v, glyphs,   # noqa: E402
                  ellipse_m, tint)

MINE = ["awl_work_sew_play", "barg_n_clothes", "optima_eyes", "family_dentistry", "pet_health_pawmise",
        "pony_roam_o", "abc_driving_school", "rosewood_fire_first_aid"]


# ------------------------------------------------------------------ helpers
def rod(d, pts, w, z, mat, polish=0.5, on=0.0):
    """a round bar along pts sitting at height `on` (capsule() sits on the ground): a true round section"""
    m = Mask(d.W, d.H).line(pts, w).get()
    if not m.any(): return m
    dist = E.edt(m); r = w / 2
    prof = np.sqrt(np.clip(1 - ((r - np.minimum(dist, r)) / r) ** 2, 0, 1)) * z
    d.h = np.where(m, on + prof, d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = polish; d.tex[m] = 0
    return m


def lathe(d, p0, p1, prof, z, mat, polish=0.5, on=0.0, clip=None):
    """a turned thing lying along p0 -> p1 (a handle, a shaft): prof = [(u 0..1, radius), ...] along it; its section
    round, its top the highest. Returns the mask and u (the place along it) for banding"""
    X = d.XX + 0.5; Y = d.YY + 0.5
    ax, ay = p1[0] - p0[0], p1[1] - p0[1]; L = math.hypot(ax, ay); ux, uy = ax / L, ay / L
    u = ((X - p0[0]) * ux + (Y - p0[1]) * uy) / L
    s = (X - p0[0]) * -uy + (Y - p0[1]) * ux
    us = np.array([p[0] for p in prof]); rs = np.array([p[1] for p in prof])
    r = np.interp(u, us, rs)
    m = (u >= 0) & (u <= 1) & (np.abs(s) <= r) & (r > 0.25)
    if clip is not None: m &= clip
    rmax = rs.max()
    hh = on + np.sqrt(np.clip(r ** 2 - s ** 2, 0, None)) / rmax * z
    d.h = np.where(m, hh, d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = polish; d.tex[m] = 0
    return m, u


def blit(d, g, x, y, scale=1):
    """a bool glyph array placed at (x, y) (its top left), each pixel scale x scale: a mask"""
    m = np.zeros((d.H, d.W), bool)
    for ry, row in enumerate(g):
        for rx, b in enumerate(row):
            if b:
                y0, x0 = y + ry * scale, x + rx * scale
                m[max(0, y0):max(0, min(d.H, y0 + scale)), max(0, x0):max(0, min(d.W, x0 + scale))] = True
    return m


def word(d, t, cx, y, font="57", scale=1, gap=1):
    """a line of the engine's pixel type centered at cx, its top at y (each letter scale x scale): a mask"""
    g = glyphs(t, font, gap)
    w = g.shape[1] * scale
    return blit(d, g, int(round(cx - w / 2)), y, scale)


def spline(ctrl, n=10):
    """a Catmull-Rom curve through the control points"""
    C = [ctrl[0]] + list(ctrl) + [ctrl[-1]]; pts = []
    for i in range(1, len(C) - 2):
        p0, p1, p2, p3 = map(np.array, (C[i - 1], C[i], C[i + 1], C[i + 2]))
        for k in range(n):
            t = k / n
            pts.append(tuple(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t ** 2
                                    + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3)))
    pts.append(tuple(ctrl[-1]))
    return pts


def ink_line(d, pts, w=1.0, t=1.0):
    """a thread or a fine line: printed flat in the ink (t = its share of ink), no edge"""
    m = Mask(d.W, d.H).line(pts, w).get()
    c = tint(t)
    d.emit[m, :3] = c; d.emit[m, 3] = 255
    return m


# ------------------------------------------------------------------ the pictures
@design(120, 118)
def awl_work_sew_play(d):
    # a wooden spool of thread standing on end: the bottom flange, the wound thread between the flanges (its turns bowing
    # down through the middle as the flanges' rims do), the top flange with its paper end label round the hole; a needle
    # pushed into the thread at a slant, the thread's loose end run up through its eye; a stitching awl lying in front
    cx, RF, RT = 58, 34, 27
    fb, ft = cyl_v(d, cx - RF, cx + RF, 76, 82, 10, "l", polish=0.4, top_ry=RF * VIEW, bot_ry=RF * VIEW)
    d.grain_wood(fb | ft, scale=0.5, seed=7)
    body, _ = cyl_v(d, cx - RT, cx + RT, 24, 76, 14, "m", polish=0.55, bot_ry=RT * VIEW, on=5)
    cy = Cyl(d, cx - RT, cx + RT, RT * VIEW)
    # the turns of thread: shallow grooves round the spool, each one riding the 0.26 ellipse (bowing down through the
    # middle, closing up toward the sides) as the feeder hopper's beads do
    for v in range(18, 76, 3):
        g = band_v(d, body, cy, v, v + 1); d.h[g] -= 0.7; d.dark[g] = 0.16
    tq = np.clip((d.XX + 0.5 - cx) / RT, -1, 1)
    d.dark[body] += (0.22 * np.clip(tq, 0, 1) ** 1.5)[body]                                       # round, away from the light
    tb, tt = cyl_v(d, cx - RF, cx + RF, 16, 24, 10, "l", polish=0.4, top_ry=RF * VIEW, bot_ry=RF * VIEW, on=20)
    # the top flange's shadow on the thread: a soft band under its rim, following the rim's curve (the cast shadow's
    # hard wedge is off here)
    X = d.XX + 0.5; Y = d.YY + 0.5
    rim = 24 + RF * VIEW * np.sqrt(np.clip(1 - ((X - cx) / RF) ** 2, 0, 1))
    d.noshadow |= body
    for k, a in enumerate((0.30, 0.22, 0.14, 0.07)):
        s_ = body & ~(tb | tt) & (Y >= rim + k) & (Y < rim + k + 1)
        d.dark[s_] = np.maximum(d.dark[s_], a)
    d.grain_wood(tb | tt, scale=0.5, seed=8)
    lab = ellipse_m(d, cx, 16, 16, 16 * VIEW + 0.6) & tt
    d.paint(lab, "w")                                                                           # the end label
    d.paint(lab & ~ellipse_m(d, cx, 16, 15, 15 * VIEW), "m")
    d.well(Mask(d.W, d.H).ellipse(cx, 16, 5.5, 2.2).get(), 5, mat="k", bevel=1)                # the hole
    # the needle, in at the thread's face and out up to the right; the loose end runs off the spool and up through it
    nd = rod(d, [(74, 52), (104, 28)], 2.4, 2, "chrome", polish=1.0, on=26)
    d.dark[Mask(d.W, d.H).line([(100.5, 31), (102.5, 29.4)], 0.8).get() & nd] = 0.6            # its eye
    ink_line(d, spline([(85, 64), (92, 58), (98, 46), (101, 31)], 8), 1.0, 0.62)
    ink_line(d, spline([(102, 30), (107, 34), (109, 44), (112, 52)], 8), 1.0, 0.62)
    # the awl: a turned wooden handle, the brass ferrule, the steel blade to its point
    m, u = lathe(d, (8, 104), (112, 97), [(0, 3.5), (0.03, 5.5), (0.12, 6.8), (0.24, 6.6), (0.34, 5.0), (0.36, 4.0),
                                          (0.44, 4.0), (0.45, 1.9), (0.9, 1.6), (1.0, 0.3)], 8, "m", polish=0.5)
    wood = m & (u < 0.36); d.grain_wood(wood, scale=0.5, seed=3)
    fer = m & (u >= 0.36) & (u < 0.45); d.mat[fer] = d.mid("chrome"); d.polish[fer] = 0.9
    for uu in (0.37, 0.435):
        d.dark[m & (np.abs(u - uu) < 0.004)] = 0.3
    bl = m & (u >= 0.45); d.mat[bl] = d.mid("chrome"); d.polish[bl] = 1.0


def boot(d, cx, by, zo, seed):
    """one leather work boot, toe toward us: the lugged sole, the stitched welt, the toe box and the vamp rising off it
    (its top lit), the shaft round across and a little flared to the padded collar, laced high through eyelets and
    speed hooks, the bow on top, the pull tab standing up behind"""
    X = d.XX + 0.5; Y = d.YY + 0.5
    top, ank = by - 72, by - 28
    # the pull tab at the back, standing up behind the collar
    d.slab(Mask(d.W, d.H).rrect(cx - 3, top - 9, 6, 10, 2).get(), zo + 3, "d", bevel=1, polish=0.3)
    d.well(Mask(d.W, d.H).rect(cx - 1, top - 7, 2, 5).get(), 1, mat="k", bevel=0.5)
    # the shaft: round across, 16 wide a side at the collar, 14 at the ankle
    hw = 13 + 3 * (1 - np.clip((Y - top) / (ank - top), 0, 1)) ** 1.6
    t = (X - cx) / hw
    c = np.sqrt(np.clip(1 - t ** 2, 0, 1))
    body = (np.abs(t) <= 1) & (Y >= top) & (Y < ank + 4)
    d.h = np.where(body, zo + 4 + c * 14, d.h).astype(np.float32)
    d.mat[body] = d.mid("m"); d.solid |= body; d.polish[body] = 0.35; d.tex[body] = 0
    d.grain_pebble(body, 0.05, seed=seed)
    v = Y - 16 * VIEW * c                                                                           # height on the round shaft
    coll = body & (v < top + 4)
    d.mat[coll] = d.mid("d"); d.h[coll] += 1.5                                                   # the padded collar
    d.seam(body & (v >= top + 4) & (v < top + 5), 0.35)
    d.seam(body & (np.abs(np.abs(X - cx) - (hw - 3.5)) < 0.5) & (v > top + 6), 0.18)              # the quarters' seams
    op = ellipse_m(d, cx, top, 16, 16 * VIEW)
    d.flat(op, zo + 10, "d", polish=0.3)
    d.well(ellipse_m(d, cx, top + 0.5, 12, 12 * VIEW), 4, mat="k", bevel=1)                     # the opening
    # the tongue between the lace rows, its top up out of the opening
    tg = (np.abs(X - cx) <= 5.5) & (Y >= top - 3) & (Y < ank + 2)
    tg &= ~((Y < top - 1) & ~ellipse_m(d, cx, top - 1, 5.5, 2.2))
    d.h = np.where(tg, zo + 18 + np.sqrt(np.clip(1 - ((X - cx) / 5.5) ** 2, 0, 1)) * 1.5, d.h).astype(np.float32)
    d.mat[tg] = d.mid("d"); d.solid |= tg; d.polish[tg] = 0.3; d.tex[tg] = 0
    # the vamp and the toe box, wider than the shaft: its top rising toward us (lit), the toe's front face, round across
    side = spline([(13, ank - 2), (14.5, ank + 5), (18.5, by - 20), (20, by - 14), (19.5, by - 9)], 6)
    vm = Mask(d.W, d.H).poly([(cx - x, y) for x, y in side] + [(cx + x, y) for x, y in reversed(side)]).get()
    tx = np.clip((X - cx) / 20.0, -1, 1)
    yt = np.clip((Y - ank) / 16.0, 0, 1)                                                          # 0 at the ankle, 1 at the toe
    hv = zo + 8 + 16 * np.sin(yt * math.pi / 2) + np.sqrt(1 - tx ** 2) * 6
    d.h = np.where(vm, hv, d.h).astype(np.float32)
    d.mat[vm] = d.mid("m"); d.solid |= vm; d.polish[vm] = 0.5; d.tex[vm] = 0
    d.grain_pebble(vm, 0.04, seed=seed + 1)
    # the toe cap's stitched seam across the vamp, and the stitch row inside it
    cap = [(cx - 18 + 36 * k / 20, by - 13 - 7 * math.sin(math.pi * k / 20)) for k in range(21)]
    d.seam(Mask(d.W, d.H).line(cap, 1.0).get() & vm, 0.4)
    for x_, y_ in cap[1:-1:2]:
        d.dark[int(y_) + 2, int(x_)] = 0.25
    # the welt and the sole, the lugs notched along the sole's foot
    welt = Mask(d.W, d.H).rrect(cx - 21, by - 10, 42, 4, 1).get()
    d.slab(welt, zo + 24, "l", bevel=1, polish=0.3)
    for x in range(cx - 19, cx + 20, 2):
        d.dark[by - 8, x] = 0.4                                                                     # the welt's stitches
    sole = Mask(d.W, d.H).rrect(cx - 21, by - 6, 42, 6, 1.5).get()
    d.slab(sole, zo + 23, "k", bevel=1, polish=0.3)
    for x in range(cx - 18, cx + 19, 4):
        d.seam(Mask(d.W, d.H).rect(x, by - 3, 1, 3).get() & sole, 0.4)                       # the lugs
    # the laces: eyelets up the shaft, speed hooks at the top, crossed between; two crossings down the vamp
    ys = [ank - 1, ank - 8, ank - 15, ank - 22, ank - 29, top + 9]
    for y0, y1 in zip(ys[:-1], ys[1:]):
        rod(d, [(cx - 7, y0), (cx + 7, y1)], 1.6, 1.2, "w", polish=0.3, on=zo + 20)
        rod(d, [(cx + 7, y0), (cx - 7, y1)], 1.6, 1.2, "w", polish=0.3, on=zo + 20.5)
    for y0, y1 in ((by - 19, ank + 5), (ank + 5, ank - 1)):
        rod(d, [(cx - 6.5, y0), (cx + 6.5, y1)], 1.6, 1.2, "w", polish=0.3, on=zo + 24)
        rod(d, [(cx + 6.5, y0), (cx - 6.5, y1)], 1.6, 1.2, "w", polish=0.3, on=zo + 24.5)
    for i, y in enumerate(ys + [ank + 5, by - 19]):
        for sx in (-1, 1):
            x = cx + sx * (7.5 if i < 6 else 7)
            if i in (4, 5): d.dome(x, y, 2.0, 1.7, 2, "chrome", polish=1.0, on=zo + 21)       # hooks
            else: d.torus(x, y, 0.5, 1.8, 1.5, "chrome", polish=1.0, on=zo + (25 if i >= 6 else 21))   # eyelets
    # the bow on top: two flat loops either side of the knot, the ends down over the shaft
    yb = top + 7
    for sx in (-1, 1):
        lp = Mask(d.W, d.H).arc(cx + sx * 6, yb, 5, 2.4, 0, 360, 1.5).get()
        d.h = np.where(lp, zo + 23, d.h).astype(np.float32); d.mat[lp] = d.mid("w"); d.solid |= lp; d.polish[lp] = 0.3
        d.tex[lp] = 0; d.dark[lp] = 0
        end = [(cx + sx * 1, yb + 1), (cx + sx * 4, yb + 8), (cx + sx * 5, yb + 15)]
        rod(d, end, 1.6, 1.2, "w", polish=0.3, on=zo + 22)
        d.dome(cx + sx * 5.2, yb + 16.5, 1.1, 1.8, 1, "k", on=zo + 22)                          # the aglets
    d.dome(cx, yb + 0.5, 2.2, 1.8, 2, "w", polish=0.3, on=zo + 24)                              # the knot


@design(120, 118)
def barg_n_clothes(d):
    # a pair of leather work boots side by side, toes toward us, the right one a step ahead (lower in the view, nearer)
    boot(d, 37, 104, 0, 3)
    boot(d, 83, 114, 6, 5)


# the eye chart's smallest row: letters too small to read, marks only
TINY = [[1, 1, 1], [1, 0, 0], [1, 1, 1]], [[1, 1, 0], [1, 0, 1], [1, 1, 0]], [[1, 1, 1], [1, 0, 1], [1, 1, 1]], \
       [[1, 1, 1], [1, 1, 0], [1, 0, 0]], [[1, 0, 1], [1, 1, 1], [1, 0, 1]], [[1, 1, 1], [0, 1, 0], [0, 1, 0]]


@design(120, 118)
def optima_eyes(d):
    # an eye chart on a little easel, front-on: the A-frame's two front legs and the back leg, the ledge the card stands
    # on (its front lip across the card's foot), the card: the big E, then rows of letters getting smaller
    for (x0, x1) in ((60, 14), (60, 106)):
        lg = Mask(d.W, d.H).line([(x0, 2), (x1, 114)], 5).get()
        d.slab(lg, 6, "d", bevel=1.5, polish=0.3); d.grain_wood(lg, scale=0.5, seed=x1, along="y")
    bk = Mask(d.W, d.H).line([(60, 4), (60, 106)], 4).get()
    d.slab(bk, 4, "d", bevel=1.2, polish=0.3); d.dark[bk] = 0.18                                # the back leg, farther
    d.dome(60, 4, 4, 3.5, 4, "chrome", polish=0.9, on=6)                                         # the hinge at the top
    card = Mask(d.W, d.H).rect(26, 8, 68, 92).get()
    d.ramp_h(card, 10, 12, axis="y", mat="w", polish=0.2)
    d.tex[card] = 0; d.dark[card] = 0                                                               # nothing of the legs behind
    d.slab(Mask(d.W, d.H).rect(26, 8, 68, 92).get() & ~Mask(d.W, d.H).rect(27, 9, 66, 90).get(), 12, "l", bevel=0.5)
    ink = word(d, "E", 60, 13, "57", 3)
    rows = [("F P", "57", 2, 40), ("T O Z", "35", 2, 58), ("L P E D", "57", 1, 72), ("P E C F D", "35", 1, 83)]
    for t, f, s, y in rows:
        ink |= word(d, t, 60, y, f, s, gap=1)
    x = 60 - (6 * 3 + 5 * 2) // 2
    for k in range(6):
        ink |= blit(d, TINY[(k * 4 + 1) % 6], x + k * 5, 91)
    d.paint(ink & card, "p")
    for y in (36, 55, 69, 80):
        d.paint(Mask(d.W, d.H).rect(30, y, 60, 1).get() & card, "l")                              # the rows' faint rules
    # the ledge across the legs, its top lit, its lip in front of the card's foot
    ledge_top = Mask(d.W, d.H).rect(16, 96, 88, 3).get()
    d.ramp_h(ledge_top, 13, 16, axis="y", mat="d", polish=0.3); d.dark[ledge_top] = 0
    lf = Mask(d.W, d.H).rect(16, 99, 88, 5).get()
    d.slab(lf, 16, "d", bevel=1, polish=0.3); d.grain_wood(lf | ledge_top, scale=0.5, seed=4)
    for x in (24, 96):
        d.dome(x, 101.5, 1.4, 1.4, 1.2, "chrome", polish=1.0, on=16)                              # its pegs


@design(120, 118)
def family_dentistry(d):
    # a big molar standing up: the crown with its four cusps (the chewing face seen a little from above, the grooves
    # between the cusps), the neck, the two roots tapering to their tips; a toothbrush lying in front, bristles up
    X = d.XX + 0.5; Y = d.YY + 0.5
    cx = 60
    tooth = Mask(d.W, d.H).rrect(cx - 36, 18, 72, 40, 16).ellipse(cx - 17, 21, 19, 12).ellipse(cx + 17, 21, 19, 12)
    tooth.poly([(cx - 32, 52), (cx + 32, 52), (cx + 28, 64), (cx - 28, 64)])
    # the roots, each a tapering curve to a round tip, the right one splaying a little more
    tooth.poly([(cx - 30, 58), (cx - 6, 58), (cx - 10, 76), (cx - 15, 92), (cx - 21, 92), (cx - 27, 78)])
    tooth.ellipse(cx - 18, 91, 4, 4)
    tooth.poly([(cx + 6, 58), (cx + 30, 58), (cx + 28, 78), (cx + 23, 92), (cx + 17, 92), (cx + 10, 76)])
    tooth.ellipse(cx + 20, 91, 4, 4)
    tm = tooth.get()
    gap = Mask(d.W, d.H).poly([(cx - 8, 92), (cx - 6, 70), (cx, 64), (cx + 6, 70), (cx + 8, 92)]).get()
    tm &= ~gap
    d.slab(tm, 22, "w", bevel=15, polish=0.9, power=0.55)
    root = tm & (Y > 60)
    d.mat[root] = d.mid("l")                                                                        # the roots, duller
    d.polish[root] = 0.4
    d.seam(Mask(d.W, d.H).line([(cx - 31, 58), (cx - 10, 61.5), (cx, 60.5), (cx + 10, 61.5), (cx + 31, 58)], 1).get() & tm, 0.15)
    # the chewing face: a level oval on top, the four cusps raised on it, the grooves between them
    oc = ellipse_m(d, cx, 22, 31, 31 * VIEW + 2) & tm
    d.h = np.where(oc, 20 + (Y - 14) * 0.5, d.h).astype(np.float32)
    for (ux, uy, r) in ((-15, 17, 12), (15, 17, 12), (-15, 26, 12), (15, 26, 12)):
        d.dome(cx + ux, uy, r, r * 0.45, 4, "w", polish=0.9, on="add")
    groove = Mask(d.W, d.H).line([(cx - 27, 22), (cx - 10, 21), (cx, 22.5), (cx + 10, 21), (cx + 27, 22)], 1.2).get()
    groove |= Mask(d.W, d.H).line([(cx, 14), (cx - 1, 22.5), (cx + 1, 30)], 1.2).get()
    d.seam(groove & oc, 0.35)
    # the toothbrush, lying in front: the handle with its ribbed grip, the neck, the head with its tufts standing up
    m, u = lathe(d, (6, 110), (112, 103), [(0, 2.6), (0.03, 3.6), (0.45, 3.4), (0.62, 2.2), (0.72, 2.0), (0.76, 3.0),
                                          (0.99, 3.0), (1.0, 1.0)], 5, "m", polish=0.8, on=8)
    gr = m & (u > 0.08) & (u < 0.38)
    d.mat[gr] = d.mid("d")
    for k in range(10):
        d.dark[gr & (np.abs(u - (0.1 + k * 0.028)) < 0.005)] = 0.3
    for row, (dy, zz, tone) in enumerate(((-1.5, 18, 0.18), (0.5, 20, 0.0))):
        for k in range(7):
            uu = 0.775 + k * 0.032
            px_ = 6 + (112 - 6) * uu; py_ = 110 + (103 - 110) * uu
            tf = Mask(d.W, d.H).rrect(px_ - 1.6, py_ - 10 + dy, 3.2, 9, 1.4).get()
            d.slab(tf, zz, "l", bevel=1.2, polish=0.2)
            d.dark[tf] = np.maximum(d.dark[tf], tone)


@design(120, 118)
def pet_health_pawmise(d):
    # a dog bone lying flat (its two knuckles at each end, one behind the other), the stethoscope's tube coiled twice
    # round its shaft and away to the headset lying open behind it; the chest piece in front, its disc lying flat
    # the headset first (behind everything): the yoke, two chrome ear tubes bowing out and in to the ear tips
    for sx in (-1, 1):
        rod(d, spline([(84, 36), (84 + sx * 11, 27), (84 + sx * 17, 16), (84 + sx * 15, 8), (84 + sx * 9, 4)], 8),
            2.2, 2, "chrome", polish=1.0, on=1)
        d.dome(84 + sx * 7, 4, 3.4, 2.8, 3, "k", polish=0.6, on=2)                                  # the ear tips
    d.slab(Mask(d.W, d.H).rrect(81, 33, 6, 6, 2).get(), 4, "chrome", bevel=1, polish=1.0)        # the yoke
    rod(d, spline([(59, 49), (64, 43), (74, 39), (84, 38)], 8), 4.0, 3, "k", polish=0.6, on=1)  # the tube, up from the bone
    # the bone: the far knuckles, the shaft, the near knuckles
    for (kx, ky) in ((19, 50), (101, 50)):
        d.dome(kx, ky, 11, 9, 9, "l", polish=0.5, on=2)
    lathe(d, (18, 58), (102, 58), [(0, 6.5), (0.15, 6.0), (0.5, 5.4), (0.85, 6.0), (1, 6.5)], 9, "l", polish=0.5, on=3)
    for (kx, ky) in ((16, 62), (104, 62)):
        d.dome(kx, ky, 11, 9, 10, "l", polish=0.5, on=4)
    bone = (d.mat == d.mid("l")) & d.solid
    d.grain_pebble(bone, 0.04, seed=12)
    # the tube from the chest piece up to the bone, then twice over the shaft's front (the turns behind are hidden)
    rod(d, spline([(61, 93), (56, 87), (46, 79), (39, 68)], 8), 4.0, 3, "k", polish=0.6, on=1)
    for (x0, x1) in ((39, 46), (53, 60)):
        rod(d, [(x0, 67), (x0 + 3, 59), (x1, 51)], 4.0, 3, "k", polish=0.6, on=13)
    # the chest piece lying flat: the stem back to the tube, the chrome rim, the diaphragm
    rod(d, [(61, 98), (61, 90)], 3.2, 2.5, "chrome", polish=1.0, on=2)
    cyl_v(d, 44, 78, 99, 103, 5, "chrome", polish=1.0, top_ry=17 * VIEW, bot_ry=17 * VIEW, on=3)
    dia = ellipse_m(d, 61, 99.4, 13, 13 * VIEW)
    d.flat(dia, 9, "d", polish=0.6)
    d.dark[dia & ~ellipse_m(d, 61, 99.4, 11, 11 * VIEW)] = 0.25


@design(120, 118)
def pony_roam_o(d):
    # a horseshoe hung open end up on a nail (the nail under the toe's inner edge, the shoe resting on it): the web with
    # its fuller groove and the nail holes along it, the squared heels; a lead rope looped over the same nail behind its
    # head, its two strands down in front of the toe and hanging below, a bolt snap on one end and a whipped end on the
    # other
    cx = 56
    half = [(cx - 21, 6), (cx - 27.5, 24), (cx - 30, 43), (cx - 26, 61), (cx - 16, 77), (cx, 83)]
    path = spline(half + [(2 * cx - x, y) for (x, y) in reversed(half[:-1])], 8)
    shoe = Mask(d.W, d.H).line(path, 14, caps=False).get()
    shoe |= Mask(d.W, d.H).rect(cx - 28, 2, 14, 5).get() | Mask(d.W, d.H).rect(cx + 14, 2, 14, 5).get()
    d.slab(shoe, 8, "d", bevel=3.5, polish=0.8)
    d.grain_pebble(shoe, 0.03, seed=4)
    # the fuller: a groove nearer the outer edge, the nail holes in it (none at the toe)
    ful = spline([(x + (x - cx) * 0.09, y + (y - 44) * 0.06) for (x, y) in half] +
                 [(2 * cx - x - (x - cx) * 0.09, y + (y - 44) * 0.06) for (x, y) in reversed(half[:-1])], 8)
    fm = Mask(d.W, d.H).line(ful[5:-5], 1.6).get() & shoe
    d.well(fm, 1.4, bevel=0.8)
    for i in (13, 19, 25, 31):
        for p in (ful[i], ful[len(ful) - 1 - i]):
            d.well(Mask(d.W, d.H).rect(p[0] - 1.2, p[1] - 1.5, 2.4, 3).get(), 4, mat="k", bevel=0.6)
    nx, ny = cx, 71.5
    # the rope: its loop over the nail's shank (behind the head), both strands down in front of the toe and on below
    def rope(pts, w=3.8, on=10):
        m = rod(d, pts, w, 3, "l", polish=0.2, on=on)
        d.dark[m & (((d.XX + d.YY) % 3) == 0)] = 0.22                                               # its lay, twisted
        return m
    rope(spline([(nx - 5.5, 77), (nx - 5, 70), (nx, 66.8), (nx + 5, 70), (nx + 5.5, 77)], 6), on=9)
    rope(spline([(nx - 5.5, 76), (nx - 7, 88), (nx - 6, 97), (nx - 4, 104)], 8))
    rope(spline([(nx + 5.5, 76), (nx + 7.5, 85), (nx + 11.5, 92), (nx + 15.5, 96)], 8))
    # the nail's round head toward us, in front of the loop
    d.dome(nx, ny, 4.4, 4.4, 4, "chrome", polish=1.0, on=14)
    # the whipped end on the left strand: the wrapping, the frayed tip
    d.slab(Mask(d.W, d.H).line([(nx - 4.3, 102), (nx - 3.7, 106)], 4.6).get(), 14, "d", bevel=1, polish=0.3)
    for k in (-1.2, 0, 1.2):
        ink_line(d, [(nx - 3.5 + k, 108.5), (nx - 3.5 + k * 1.8, 112)], 0.8, 0.55)
    # the bolt snap on the right strand: its swivel eye, the body, the hook and the spring bolt
    sx, sy = nx + 17.5, 99
    d.torus(sx, sy, 1.2, 3.2, 2.5, "chrome", polish=1.0, on=12)
    d.slab(Mask(d.W, d.H).rrect(sx - 2.2, sy + 2.5, 4.4, 10, 1.5).get(), 15, "chrome", bevel=1.2, polish=1.0)
    hk = Mask(d.W, d.H).arc(sx + 3.2, sy + 12.5, 3.2, 3.8, -10, 190, 2.0).get()
    d.slab(hk, 15, "chrome", bevel=0.8, polish=1.0)
    d.seam(Mask(d.W, d.H).rect(sx - 0.5, sy + 5, 1, 6).get(), 0.4)


@design(120, 112)
def abc_driving_school(d):
    # a three-spoke steering wheel standing up and facing us: the round rim (a near circle, a hair squat as it leans back),
    # the spokes left, right and down, dished toward the horn pad in the middle; the column's shroud below it
    X = d.XX + 0.5; Y = d.YY + 0.5
    cx, cy = 60, 54
    col = (np.abs(X - cx) <= 9) & (Y > cy + 20)
    t = (X - cx) / 9
    d.h = np.where(col, np.sqrt(np.clip(1 - t ** 2, 0, 1)) * 8, d.h).astype(np.float32)
    d.mat[col] = d.mid("k"); d.solid |= col; d.polish[col] = 0.5; d.tex[col] = 0
    d.seam(col & (np.abs(Y - 108.5) < 0.6), 0.3)
    rr = np.hypot((X - cx) * 0.96, Y - cy)
    # the spokes: a broad bar each, tapering out to the rim, rising toward the hub
    for a in (180, 0, 90):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        px_, py_ = -sa, ca
        def P(r, w): return (cx + ca * r / 0.96 + px_ * w, cy + sa * r + py_ * w)
        sp = Mask(d.W, d.H).poly([P(10, -8), P(46, -4.5), P(46, 4.5), P(10, 8)]).get()
        d.slab(sp, 4, "chrome", bevel=2, polish=0.8, on=6)
        d.h[sp] += np.clip(1 - (rr[sp] - 10) / 36, 0, 1) * 8
        d.grain_brushed(sp, 0.05, seed=a + 1)
    # the rim
    rim = (rr >= 41) & (rr <= 52)
    tt = (rr - 46.5) / 5.5
    d.h = np.where(rim, 10 + np.sqrt(np.clip(1 - tt ** 2, 0, 1)) * 9, d.h).astype(np.float32)
    d.mat[rim] = d.mid("k"); d.solid |= rim; d.polish[rim] = 0.6; d.tex[rim] = 0
    ang = np.degrees(np.arctan2(Y - cy, (X - cx) * 0.96)) % 360
    for a in range(20, 170, 9):                                                                     # the finger grips underneath
        if abs(a - 90) < 12: continue
        d.dark[rim & (np.abs(ang - a) < 1.2) & (rr < 44)] = 0.3
    # the horn pad: a padded cushion, its seam inset round it
    pad = Mask(d.W, d.H).rrect(cx - 19, cy - 15, 38, 30, 12).get()
    d.slab(pad, 10, "d", bevel=8, polish=0.4, on=12)
    inset = Mask(d.W, d.H).rrect(cx - 15, cy - 11, 30, 22, 9).get()
    d.seam(pad & ~inset & Mask(d.W, d.H).rrect(cx - 16, cy - 12, 32, 24, 10).get(), 0.25)


# the stencil letters for the first aid box's lid: 2 px strokes, the counters bridged the way a stencil's are
STENCIL = {
    "F": ["1111111", "1111111", "11.....", "11.....", "111111.", "111111.", "11.....", "11.....", "11.....", "11....."],
    "I": ["11"] * 10,
    "R": ["11.111.", "11.1111", "11...11", "11...11", "11.1111", "11.111.", "11..11.", "11..11.", "11...11", "11...11"],
    "S": [".111111", "1111111", "11.....", "11.....", "111111.", ".111111", ".....11", ".....11", "1111111", "111111."],
    "T": ["111111", "111111", "..11..", "..11..", "..11..", "..11..", "..11..", "..11..", "..11..", "..11.."],
    "A": [".11.11.", "111.111", "11...11", "11...11", "1111111", "1111111", "11...11", "11...11", "11...11", "11...11"],
    "D": ["11.111.", "11.1111", "11...11", "11...11", "11...11", "11...11", "11...11", "11...11", "11.1111", "11.111."],
}


def stencil(d, t, cx, y, gap=2, space=5):
    gl = [[[c == "1" for c in row] for row in STENCIL[ch]] if ch != " " else None for ch in t]
    w = sum((len(g[0]) if g else space) for g in gl) + gap * (len(t) - 1)
    x = int(round(cx - w / 2)); m = np.zeros((d.H, d.W), bool)
    for g in gl:
        if g: m |= blit(d, g, x, y); x += len(g[0]) + gap
        else: x += space + gap
    return m


@design(120, 118)
def rosewood_fire_first_aid(d):
    # a closed metal first aid box, front-on and a little from above: the top (lit), the carry handle standing on it
    # between its two lugs, the lid's front with FIRST AID stenciled on it, the lid's lip over the base, the draw latch;
    # a roll of gauze in front, its end toward us, its loose end unrolled along the ground
    X = d.XX + 0.5; Y = d.YY + 0.5
    x0, x1, yt, yf, yb = 8, 112, 14, 26, 86
    top = Mask(d.W, d.H).rrect(x0, yt, x1 - x0, yf - yt + 2, 3).get()
    d.ramp_h(top, 10, 18, axis="y", mat="m", polish=0.5)
    front = Mask(d.W, d.H).rrect(x0, yf, x1 - x0, yb - yf, 3).get()
    d.slab(front, 20, "m", bevel=2.5, polish=0.5)
    d.grain_brushed(front, 0.03, seed=2)
    # the lid's lip, a hair proud of the base, the seam under it
    lip = Mask(d.W, d.H).rect(x0, 55, x1 - x0, 3).get()
    d.slab(lip, 21.5, "m", bevel=1, polish=0.6)
    d.seam(Mask(d.W, d.H).rect(x0 + 1, 58, x1 - x0 - 2, 1).get(), 0.5)
    # two pressed ribs round the base
    for y in (68, 76):
        d.slab(Mask(d.W, d.H).rect(x0 + 2, y, x1 - x0 - 4, 2).get(), 21, "m", bevel=0.8, polish=0.6)
    # FIRST AID, stenciled on the lid's front (in the face's plane: the face is square to us)
    d.paint(stencil(d, "FIRST AID", 60, 36) & front, "pw")
    # the draw latch on the seam: the plate on the lid, the hook over the base's keeper
    d.slab(Mask(d.W, d.H).rrect(54, 50, 12, 8, 1.5).get(), 23, "chrome", bevel=1, polish=0.9)
    d.slab(Mask(d.W, d.H).rrect(56, 57, 8, 7, 1.5).get(), 24, "chrome", bevel=1, polish=0.9)
    d.seam(Mask(d.W, d.H).rect(56, 53, 8, 1).get(), 0.35)
    # the carry handle: two lugs on the top, the bail standing up between them, its grip
    for x in (40, 80):
        d.slab(Mask(d.W, d.H).rrect(x - 3, 17, 6, 5, 1.5).get(), 20, "chrome", bevel=1, polish=0.9)
    rod(d, [(40, 19), (41, 9), (44, 5), (76, 5), (79, 9), (80, 19)], 2.4, 2, "chrome", polish=1.0, on=19)
    gp = Mask(d.W, d.H).rrect(46, 2, 28, 6, 3).get()
    d.slab(gp, 24, "k", bevel=2.5, polish=0.5)
    # the gauze: the roll's top seen from above behind its end, the end with its turns, the tail along the ground
    gx, gy, R = 88, 96, 14
    tail = Mask(d.W, d.H).poly([(36, 105), (84, 105), (84, 110.5), (38, 110.5)]).get()
    d.ramp_h(tail, 22, 24, axis="y", mat="w", polish=0.1)
    weave = tail & ((d.XX % 2 == 0) & (d.YY % 2 == 0))
    d.dark[weave] = 0.12
    d.dark[tail & (X < 40)] = 0.08
    back = (np.hypot(X - gx, Y - (gy - 5)) <= R) | ((np.abs(X - gx) <= R) & (Y >= gy - 5) & (Y <= gy))
    d.ramp_h(back, 22, 28, axis="y", mat="w", polish=0.2)
    end = np.hypot(X - gx, Y - gy) <= R
    d.flat(end, 30, "w", polish=0.2)
    rr = np.hypot(X - gx, Y - gy); an = np.arctan2(Y - gy, X - gx)
    spiral = end & (np.abs(((rr - an / (2 * math.pi) * 3.0) % 3.0) - 1.5) < 0.45) & (rr > 4)
    d.dark[spiral] = 0.22
    d.well(end & (rr <= 3.6), 3, mat="l", bevel=1)


if __name__ == "__main__":
    os.chdir(HERE)
    os.makedirs("px", exist_ok=True)
    names = sys.argv[1:] or MINE
    for n in names:
        if n not in MINE: sys.exit("not one of batch 5c's pictures: " + n)
        im = render(n)
        im.save(os.path.join("px", n + ".png"))
        print(n, im.size)
