"""Batch 5a of the survival guide's third-page ads (Nov 7 2026): ads 1 to 8 of batch 5's lineup (batch5_lineup.json).
The same pixel art as adpx.py (the dashes' engine, the book's one ink, VIEW = 0.26: seen from the front and a little
from above); this module only adds its own designs to adpx.DESIGNS.
usage: python adpx_b5a.py [name ...]  -> px/<name>.png (ink on transparent)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path: sys.path.insert(0, HERE)
import adpx                                            # noqa: E402
from adpx import *                                     # noqa: E402,F401,F403
from adpx import (DESIGNS, VIEW, INK, Mask, E, np, design, render, ellipse_m, cyl_v, Cyl, band_v,   # noqa: E402
                  print_wrap, stroke, capsule, disc, taper_v, revolve, facet)

INK_ = tuple(int(v) for v in INK)
B5A = []


def b5a(w, h):
    def deco(fn):
        B5A.append(fn.__name__)
        return design(w, h)(fn)
    return deco


# ------------------------------------------------------------------ helpers
def cone_seg(d, p0, p1, r0, r1, z, mat, polish=0.6, on=0.0, keep_max=False):
    """a round bar or cone from p0 (radius r0) to p1 (radius r1), round across its axis; flat ends"""
    X = d.XX + 0.5; Y = d.YY + 0.5
    (x0, y0), (x1, y1) = p0, p1
    vx, vy = x1 - x0, y1 - y0; L = math.hypot(vx, vy); ux, uy = vx / L, vy / L
    t = ((X - x0) * ux + (Y - y0) * uy) / L
    dist = np.abs((X - x0) * -uy + (Y - y0) * ux)
    r = r0 + (r1 - r0) * np.clip(t, 0, 1)
    m = (t >= 0) & (t <= 1) & (dist <= r)
    prof = on + np.sqrt(np.clip(1 - (dist / np.maximum(r, 1e-3)) ** 2, 0, 1)) * z * (r / max(r0, r1))
    d.h = np.where(m, np.maximum(d.h, prof) if keep_max else prof, d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = polish; d.tex[m] = 0
    return m


def rot_ellipse(d, cx, cy, a, b, ang):
    """an ellipse with semi-axes a (along ang, degrees) and b"""
    X = d.XX + 0.5 - cx; Y = d.YY + 0.5 - cy
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    u = X * c + Y * s; v = -X * s + Y * c
    return (u / a) ** 2 + (v / b) ** 2 <= 1


def inkline(d, pts, w=1.0):
    m = Mask(d.W, d.H).line(pts, w).get()
    d.emit[m, :3] = INK_; d.emit[m, 3] = 255
    return m


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


# ------------------------------------------------------------------ 1. Gas-2-Go
@b5a(124, 118)
def gas_2_go(d):
    # a 5-gallon steel jerry can standing, its flat side to us with the stamped X; the three handles across the top;
    # the spout and its clamped cap on the near top corner; a tin funnel lying on its side in front
    X = d.XX + 0.5; Y = d.YY + 0.5
    x0, x1, y0, y1 = 8, 80, 32, 112
    top = Mask(d.W, d.H).poly([(x0 + 5, 22), (x1 - 5, 22), (x1 - 1, 33), (x0 + 1, 33)]).get()
    d.ramp_h(top, 6, 15, axis="y", mat="m", polish=0.5)                                        # the top, toward the light
    d.tex[top] = 0.12
    face = Mask(d.W, d.H).rrect(x0, y0, x1 - x0, y1 - y0, 6).get()
    d.slab(face, 16, "m", bevel=5, polish=0.5)
    d.seam(Mask(d.W, d.H).rrect(x0 + 1, y0 + 1, x1 - x0 - 2, 1, 0).get() & face, 0.3)          # the welded seam's edge
    # the stamped panel: a raised border round it, the X pressed in across it
    pn = Mask(d.W, d.H).rrect(x0 + 7, y0 + 8, x1 - x0 - 14, y1 - y0 - 16, 4).get()
    d.well(pn, 2.5, bevel=1.5)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    for (a, b) in (((x0 + 10, y0 + 11), (x1 - 10, y1 - 11)), ((x1 - 10, y0 + 11), (x0 + 10, y1 - 11))):
        m = Mask(d.W, d.H).line([a, b], 6).get() & pn
        dd = E.edt(m)
        d.h = np.where(m, d.h + np.minimum(dd / 2.5, 1.0) * 2.6, d.h).astype(np.float32)   # the X's ridges
    # the three handles standing on the top, each a loop of tube; the spout behind them on the near corner
    for hx in (35, 52, 69):
        loop = Mask(d.W, d.H).rrect(hx - 8, 14, 16, 15, 5).get() & ~Mask(d.W, d.H).rrect(hx - 5, 17, 10, 6, 2).get()
        loop &= Y < 28
        dd = E.edt(loop)
        d.h = np.where(loop, 16 + np.sqrt(np.clip(dd / 1.6, 0, 1)) * 4, d.h).astype(np.float32)
        d.mat[loop] = d.mid("m"); d.solid |= loop; d.polish[loop] = 0.6; d.tex[loop] = 0
    # the spout on the near corner, angled out, its cap clamped on by a lever
    cone_seg(d, (19, 29), (13, 19), 5.5, 5.0, 6, "m", polish=0.6, on=14)
    cap = cone_seg(d, (14, 20.5), (9.5, 12.5), 7.0, 7.0, 7, "d", polish=0.8, on=15)
    d.dome(9.5, 12.5, 6.4, 3.4, 4, "d", polish=0.8, on=15)
    d.seam(Mask(d.W, d.H).line([(8.5, 20), (16, 16)], 1).get() & cap, 0.3)                   # where the cap meets the neck
    capsule(d, [(16, 14), (25, 10)], 3, 5, "k", polish=0.9)                                   # the cap's clamp lever
    d.dome(16, 14, 1.6, 1.6, 6, "chrome", polish=1.0, on=17)
    # the funnel lying on its side in front, its mouth to the right turned a little toward us
    sp = cone_seg(d, (64, 106), (78, 103), 2.2, 2.6, 3, "chrome", polish=0.9, on=18)          # the spout
    body = cone_seg(d, (77, 103), (106, 97), 3.0, 14.0, 12, "chrome", polish=0.9, on=18)      # the cone
    mouth = rot_ellipse(d, 106, 97, 14.5, 7.0, -78)
    d.flat(mouth, 26, "chrome", polish=0.9)
    inner = rot_ellipse(d, 106.5, 97, 12.5, 5.2, -78)
    d.flat(inner, 22, "d", polish=0.2); d.dark[inner] = 0.15                                  # inside, in shadow
    d.ramp_h(inner & (X > 106), 18, 24, axis="x")
    d.grain_pebble(face & ~pn, 0.04, seed=3)


# ------------------------------------------------------------------ 2. Nolan's Used Cars
@b5a(118, 118)
def nolans_used_cars(d):
    # a car key on a split ring, hanging; a round paper price tag tied to the ring by a string, turned a little, AS IS
    # written on it by hand
    X = d.XX + 0.5; Y = d.YY + 0.5
    rcx, rcy = 34, 18
    d.torus(rcx, rcy, 10, 14, 4, "chrome", polish=1.0)                                        # the split ring
    rr = np.hypot(X - rcx, Y - rcy)
    d.seam((np.abs(rr - 12) < 0.5) & (X > rcx + 2) & (Y < rcy + 4), 0.35)                    # its second turn
    # the key, hanging from the ring: the black head with its hole, the blade below
    ang = math.radians(6)
    def R(x, y, cx=34, cy=32): x -= cx; y -= cy; return (cx + x * math.cos(ang) - y * math.sin(ang), cy + x * math.sin(ang) + y * math.cos(ang))
    head = Mask(d.W, d.H).poly([R(x, y) for x, y in
                                ((24, 30), (44, 30), (49, 36), (49, 50), (43, 58), (25, 58), (19, 50), (19, 36))]).get()
    d.slab(head, 8, "k", bevel=3, polish=0.6)
    hx, hy = R(34, 36)
    d.well(Mask(d.W, d.H).ellipse(hx, hy, 3, 3).get(), 6, bevel=1)
    d.seam(Mask(d.W, d.H).poly([R(25, 46), R(43, 46), R(43, 47), R(25, 47)]).get(), 0.3)     # the head's grip line
    shoulder = Mask(d.W, d.H).poly([R(x, y) for x, y in ((28, 57), (40, 57), (40, 62), (38, 64), (30, 64), (28, 62))]).get()
    d.slab(shoulder, 5, "chrome", bevel=1, polish=1.0)
    # the blade: cut along its right edge, the tip rounded off, a groove down its length
    cuts = [(30, 63), (38, 63), (38, 68), (40, 71), (38, 74), (40, 78), (38, 82), (40, 86), (38, 90), (40, 94), (36, 99),
            (32, 99), (30, 97)]
    blade = Mask(d.W, d.H).poly([R(x, y) for x, y in cuts]).get()
    d.slab(blade, 4, "chrome", bevel=1.0, polish=1.0)
    d.seam(Mask(d.W, d.H).line([R(33, 66), R(33, 95)], 1).get() & blade, 0.4)
    # the string, from the ring out to the tag's hole
    tcx, tcy, ta, tb, tang = 80, 70, 25, 21, -14
    hole = (tcx - 6, tcy - 19)
    inkline(d, spline([(rcx + 12, rcy + 6), (52, 30), (62, 40), (hole[0] - 1, hole[1] + 1)], 8), 1.0)
    inkline(d, [(hole[0] - 1, hole[1] + 1), (hole[0] + 1, hole[1] - 2), (hole[0] + 3, hole[1])], 1.0)
    tag = rot_ellipse(d, tcx, tcy, ta, tb, tang)
    d.slab(tag, 3, "w", bevel=1.2, polish=0.15)
    d.grain_pebble(tag, 0.03, seed=4)
    reinf = (np.hypot(X - hole[0], Y - hole[1]) <= 4.2)
    d.slab(reinf & tag, 3.6, "l", bevel=0.8, polish=0.2)
    d.well(Mask(d.W, d.H).ellipse(hole[0], hole[1], 1.6, 1.6).get(), 3, bevel=0.5)
    # AS IS, by hand (a felt pen): each letter a few strokes, the line climbing a little with the tag's turn
    c, s = math.cos(math.radians(tang)), math.sin(math.radians(tang))
    def T(u, v): return (tcx + u * c - v * s, tcy + u * s + v * c)
    A = [[(-21, 5), (-16, -8), (-11, 5)], [(-19, 0), (-13, 0)]]
    S1 = [[(-3, -6), (-6, -8), (-9, -6), (-8, -2), (-4, 0), (-3, 3), (-6, 5), (-10, 4)]]
    I = [[(7, -8), (7, 5)]]
    S2 = [[(20, -6), (17, -8), (14, -6), (15, -2), (19, 0), (20, 3), (17, 5), (13, 4)]]
    for stroke_ in A + S1 + I + S2:
        inkline(d, spline([T(u, v) for u, v in stroke_], 4), 1.6)
    inkline(d, spline([T(-19, 10), (T(0, 11)), T(18, 9)], 6), 1.2)                           # underlined


# ------------------------------------------------------------------ 3. Car Fix-ation
@b5a(140, 84)
def car_fixation(d):
    # a four-way lug wrench lying flat on the floor, seen a little from above, so its cross is foreshortened front to
    # back: a socket on each of three ends, the hubcap pry tip on the fourth; a spark plug lying across in front
    cx, cy = 70, 34
    CE = math.cos(math.radians(15))
    def P(gx, gz, gy): return (cx + gx, cy + gz * VIEW - gy * CE)
    ang = 24
    arms = []
    for k in range(4):
        a = math.radians(ang + 90 * k); arms.append((math.cos(a), math.sin(a), k))
    # back to front: the arms pointing away first
    arms.sort(key=lambda t: t[1])
    socket_r = {0: 6.2, 1: 5.4, 2: 6.8, 3: 0}
    hub = P(0, 0, 5.5)
    for (ux, uz, k) in arms:
        end = P(ux * 46, uz * 46, 5.5)
        capsule(d, [hub, end], 5.6, 6, "chrome", polish=0.9)
        if socket_r[k] == 0:                                                                   # the pry tip, flattened
            tip = P(ux * 62, uz * 62, 3.2)
            d.slab(Mask(d.W, d.H).line([end, tip], 7).get(), 4, "chrome", bevel=1.5, polish=0.9)
            continue
        r = socket_r[k]
        s0 = P(ux * 44, uz * 44, r); s1 = P(ux * 61, uz * 61, r)
        cone_seg(d, s0, s1, r, r, r + 1, "chrome", polish=0.9)
        # the open end, a vertical circle facing along the arm: seen as an ellipse
        bx, by = -uz, ux * VIEW                                                               # the end's width, across
        wd = r * math.hypot(bx, by)
        if uz > -0.2:
            a_ = math.degrees(math.atan2(by, bx))
            ex, ey = s1
            face = rot_ellipse(d, ex, ey, max(wd, 1.2), r * CE, a_)
            d.flat(face, r + 1, "chrome", polish=0.9)
            hole = rot_ellipse(d, ex, ey, max(wd * 0.6, 0.6), r * CE * 0.6, a_)
            d.flat(hole, 0, "k", polish=0.1); d.dark[hole] = 0.4
    d.dome(*hub, 5, 3, 7.5, "chrome", polish=1.0)                                              # the weld at the cross
    # the spark plug, lying across in front, side on: terminal nut, the ribbed white insulator, the hex, the thread,
    # the ground electrode's hook
    py, ox = 70, 22
    def bar(xa, xb, r, mat, polish=0.6):
        return d.cyl(ox + xa, py - r, xb - xa, 2 * r, r + 2, mat, axis="h", polish=polish)
    bar(0, 8, 3.4, "chrome", 0.9)                                                              # the terminal nut
    bar(8, 12, 2.0, "chrome", 0.9)
    ins = bar(12, 46, 6.0, "w", 0.8)                                                           # the insulator
    for xr in (16, 21, 26, 31):
        d.seam(Mask(d.W, d.H).rect(ox + xr, py - 6, 1, 12).get() & ins, 0.35)                 # its ribs
    bar(46, 51, 7.0, "chrome", 0.9)                                                            # the crimp
    hexm = bar(51, 66, 9.4, "chrome", 0.9)                                                     # the hex
    for yy in (py - 5, py + 4):
        d.seam(Mask(d.W, d.H).rect(ox + 51, yy, 15, 1).get() & hexm, 0.4)                     # its flats' edges
    bar(66, 69, 7.8, "chrome", 0.9)                                                            # the gasket
    thr = bar(69, 88, 6.0, "chrome", 0.9)                                                      # the thread
    for xr in range(70, 88, 2):
        d.seam(Mask(d.W, d.H).line([(ox + xr, py - 6), (ox + xr + 2, py + 6)], 1).get() & thr, 0.4)
    bar(88, 92, 1.6, "w", 0.8)                                                                 # the center electrode
    d.slab(Mask(d.W, d.H).poly([(ox + x, py + y) for x, y in ((87, 5), (96, 5), (96, -3), (93, -3), (93, 2), (87, 2))]).get(),
           5, "chrome", bevel=0.6, polish=0.9)                                                 # the ground electrode


# ------------------------------------------------------------------ 4. Louisville Motorshop
@b5a(136, 122)
def louisville_motorshop(d):
    # a 12-volt car battery, front on and a little from above: its lid with the two posts and the row of six fill caps,
    # the carry strap across; a pair of jumper-cable clamps lying in front, on their sides, jaws to the middle
    X = d.XX + 0.5; Y = d.YY + 0.5
    x0, x1 = 14, 122
    yt0, yt1, yb = 26, 42, 92                                         # the lid's back edge, its front edge, the foot
    # the carry strap, arching over the lid from end to end (behind the posts and caps)
    strap = spline([(x0 + 3, 36), (32, 12), (68, 4), (104, 12), (x1 - 3, 36)], 10)
    capsule(d, strap, 3.6, 4, "k", polish=0.5)
    for ex in (x0 + 2, x1 - 2):
        d.slab(Mask(d.W, d.H).rrect(ex - 3, 32, 6, 10, 2).get(), 6, "k", bevel=1, polish=0.6)   # its end clips
    lid = Mask(d.W, d.H).rect(x0, yt0, x1 - x0, yt1 - yt0).get()
    d.ramp_h(lid, 8, 14, axis="y", mat="d", polish=0.4); d.tex[lid] = 0.08
    face = Mask(d.W, d.H).rect(x0, yt1, x1 - x0, yb - yt1).get()
    d.slab(face, 16, "k", bevel=2, polish=0.45)
    lip = Mask(d.W, d.H).rect(x0 - 1, yt1, x1 - x0 + 2, 4).get()
    d.slab(lip, 17, "d", bevel=1, polish=0.5)                                                  # the lid's overhang
    for xr in (x0 + 4, x1 - 6):
        d.seam(Mask(d.W, d.H).rect(xr, yt1 + 6, 2, yb - yt1 - 10).get(), 0.3)                 # the case's end ribs
    # the label on the front
    lab = Mask(d.W, d.H).rect(x0 + 14, yt1 + 9, x1 - x0 - 28, 31).get()
    d.slab(lab, 0.8, "w", bevel=0.5, polish=0.2, on="h")
    d.text("12 VOLT", (x0 + x1) // 2, yt1 + 13, "p", font="57", align="c", scale=2)
    d.text("HEAVY DUTY", (x0 + x1) // 2, yt1 + 31, "p", align="c")
    # the six fill caps in a row down the middle of the lid
    for i in range(6):
        ccx = 38 + i * 12
        body, top = cyl_v(d, ccx - 4, ccx + 4, 31, 35, 3, "k", polish=0.6, top_ry=4 * VIEW + 0.6, bot_ry=4 * VIEW, on=11)
        d.seam(Mask(d.W, d.H).rect(ccx - 2, 30, 4, 1).get() & top, 0.3)                      # the cap's slot
    # the posts: tapered lead on their seats, the + and - cast in the lid beside them
    for pcx in (25, 111):
        d.slab(ellipse_m(d, pcx, 37, 7, 7 * VIEW + 0.5), 13, "d", bevel=1, polish=0.5)
        body, top = taper_v(d, pcx, 26, 36, 3.4, 4.6, 5, "m", polish=0.8)
        d.h[body] += 13.5
        d.flat(top, 19, "m", polish=0.8)
    d.paint(Mask(d.W, d.H).rect(32, 38, 3, 1).get() | Mask(d.W, d.H).rect(33, 37, 1, 3).get(), "w")
    d.paint(Mask(d.W, d.H).rect(102, 38, 3, 1).get(), "w")
    # the jumper-cable clamps, side on: the sleeved handles spread behind the pivot, the toothed jaws shut, the
    # cable out of the lower handle's end
    def clamp(ox, oy, flip, grip):
        # the origin is the pivot; the grips behind it (fat rubber sleeves splayed in a V), the jaws ahead of it a
        # little open, a row of teeth on each, the coil spring round the pivot, the cable out of the lower grip's end
        def Q(x, y): return (ox + (-x if flip else x), oy + y)
        capsule(d, spline([Q(-23, 7), Q(-30, 9), Q(-33, 14), Q(-26, 17), Q(-14, 16)], 6), 4.2, 4, "k", polish=0.6)
        capsule(d, [Q(-24, -7), Q(-3, -2.5)], 7.6, 7, grip, polish=0.5)
        capsule(d, [Q(-23, 7), Q(-3, 2.5)], 7.6, 7, grip, polish=0.5)
        for (yy, s_) in ((-1, -1), (1, 1)):
            jaw = Mask(d.W, d.H).poly([Q(-2, 4.5 * s_), Q(15, 4 * s_ + 1.2 * s_), Q(19, 2.2 * s_), Q(19, 1.0 * s_ - s_ * 0.5),
                                       Q(-2, 0.5 * s_)]).get()
            d.slab(jaw, 6, "chrome", bevel=1.2, polish=1.0)
            for k in range(2, 19, 3):                                                         # the teeth
                tx, ty = Q(k, 1.2 * s_)
                d.paint(Mask(d.W, d.H).poly([(tx - 1, ty), (tx + 1, ty), (tx, ty - 1.6 * s_)]).get(), "k")
        d.dome(*Q(0, 0), 4.8, 5.6, 9, "chrome", polish=1.0)                                     # the spring
        for k in (-2, 0, 2):
            d.seam(Mask(d.W, d.H).rect(*Q(k, -5), 1, 10).get() & ellipse_m(d, *Q(0, 0), 4.8, 5.6), 0.35)
    clamp(42, 104, False, "k")
    clamp(96, 108, True, "m")


# ------------------------------------------------------------------ 5. Echo Creek Feed & Seed
@b5a(112, 118)
def echo_creek_feed_seed(d):
    # a galvanized chicken feeder: the cone-topped hopper standing in its round pan, the pan's rim a level circle, the
    # feed heaped in it round the hopper's foot; a few grains of scratch on the ground in front
    X = d.XX + 0.5; Y = d.YY + 0.5
    cx = 56
    pr, py = 50, 94                                                   # the pan's rim: radius, its center's height
    outer = ellipse_m(d, cx, py, pr, pr * VIEW)
    inside = ellipse_m(d, cx, py, pr - 3, (pr - 3) * VIEW)
    ring = outer & ~inside
    d.flat(ring & (Y < py), 9, "chrome", polish=0.9)                                           # the far rim
    # the hopper: a cylinder with rolled beads round it, standing in the feed
    body, _ = cyl_v(d, cx - 22, cx + 22, 30, py + 2, 20, "chrome", polish=0.8, bot_ry=22 * VIEW)
    c = Cyl(d, cx - 22, cx + 22, 22 * VIEW)
    for vv in (44, 60, 76):
        r = band_v(d, body, c, vv, vv + 2); d.h[r] += 1.4
        r2 = band_v(d, body, c, vv + 2, vv + 3); d.dark[r2] = 0.2
    d.grain_pebble(body, 0.05, seed=12)
    # the feed in the pan, heaped a little round the hopper's foot
    feed = inside & ~body
    d.flat(feed, 10, "d", polish=0.1); d.grain_pebble(feed, 0.3, seed=5)
    d.h[feed & (np.hypot((X - cx) / 34, (Y - py - 4) / 6) < 1)] += 1.5
    # the front wall under the rim, tapering to the foot, and the rolled rim over it
    rr = pr + (pr - 5 - pr) * np.clip((Y - py) / 9, 0, 1)
    wall = ((np.abs(X - cx) <= rr) & (Y >= py) & (Y <= py + 9)) | (ellipse_m(d, cx, py + 9, pr - 5, (pr - 5) * VIEW) & (Y > py + 9))
    wall &= ~outer
    t = np.clip((X - cx) / rr, -1, 1)
    d.h = np.where(wall, np.sqrt(1 - t ** 2) * 12, d.h).astype(np.float32)
    d.mat[wall] = d.mid("chrome"); d.solid |= wall; d.polish[wall] = 0.85; d.tex[wall] = 0
    d.flat(ring & (Y >= py), 15, "chrome", polish=1.0)
    # the cone top overhanging the hopper, a shallow cone round across, its rolled edge; the wire bail for hanging
    cone, base = taper_v(d, cx, 14, 30, 2.0, 29, 14, "chrome", polish=0.8)
    d.h[cone] += (Y[cone] - 14) * 0.35
    lip = (ellipse_m(d, cx, 30, 29, 29 * VIEW) & (Y >= 30)) | (cone & (Y >= 28))
    d.slab(lip, 20, "chrome", bevel=1, polish=0.9)
    d.grain_pebble(cone, 0.05, seed=13)
    d.dome(cx, 13, 2.6, 2.0, 16, "chrome", polish=1.0)
    capsule(d, [(cx, 12), (cx, 9)], 1.6, 3, "chrome", polish=1.0, )
    d.torus(cx, 6, 2.2, 4.6, 3, "chrome", polish=1.0)
    # scratch on the ground in front, left and right of the pan's foot
    for k, (gx, gy) in enumerate(((6, 112), (11, 115), (16, 110), (4, 116), (22, 116), (92, 113), (99, 116), (104, 111),
                                  (88, 116), (108, 115))):
        disc(d, gx, gy, 1.8, 1.1, 1.5, ("m", "l", "d")[k % 3], polish=0.4)


# ------------------------------------------------------------------ 6. Brott Cattle Farm
@b5a(104, 124)
def brott_cattle_farm(d):
    # a cowbell hanging from its leather strap and buckle, front on: the bell flares to its mouth, the mouth's lip a
    # level ellipse, the clapper hanging inside, its ball just showing below the lip
    X = d.XX + 0.5; Y = d.YY + 0.5
    cx = 52
    # the strap: a loop of leather up from the bell's yoke, buckled on the left strand, its tail hanging out
    loop = spline([(cx - 7, 62), (cx - 15, 36), (cx - 10, 12), (cx, 6), (cx + 10, 12), (cx + 15, 36), (cx + 7, 62)], 12)
    sm = Mask(d.W, d.H).line(loop, 7).get()
    d.slab(sm, 4, "d", bevel=1.2, polish=0.35, power=1.0)                                     # flat leather
    d.grain_pebble(sm, 0.04, seed=8)
    d.dome(cx, 4, 1.6, 1.6, 6, "k")                                                            # the nail it hangs on
    tail = spline([(cx - 15, 36), (cx - 21, 48), (cx - 25, 60)], 6)
    tm = Mask(d.W, d.H).line(tail, 6).get()
    d.slab(tm, 5, "d", bevel=1.2, polish=0.35, power=1.0)                                     # the strap's tail
    for (hx, hy) in ((cx - 21, 48), (cx - 24, 56)):
        d.well(Mask(d.W, d.H).ellipse(hx, hy, 1.3, 1.3).get(), 3, bevel=0.5)                  # the punched holes
    bk = Mask(d.W, d.H).rrect(cx - 23, 27, 15, 13, 2).get() & ~Mask(d.W, d.H).rect(cx - 20, 30, 9, 7).get()
    d.slab(bk, 8, "chrome", bevel=1, polish=1.0)                                               # the buckle's frame
    capsule(d, [(cx - 21, 33.5), (cx - 12, 33.5)], 1.6, 8.5, "chrome", polish=1.0)            # its tongue
    # the yoke: a riveted iron strap over the bell's crown
    d.slab(Mask(d.W, d.H).rrect(cx - 10, 56, 20, 10, 3).get() & ~Mask(d.W, d.H).rect(cx - 6, 58, 12, 4).get(), 7, "k", bevel=1.2, polish=0.7)
    # the bell: round across, flaring from the crown to the mouth
    y0, y1 = 64, 108
    r0, r1 = 19, 30
    r = r0 + (r1 - r0) * np.clip((Y - y0) / (y1 - y0), 0, 1) ** 1.4
    t = (X - cx) / r
    bell = (np.abs(t) <= 1) & (Y >= y0) & (Y <= y1)
    lipry = r1 * VIEW * 0.75
    bell |= ellipse_m(d, cx, y1, r1, lipry) & (Y > y1)
    crown = ellipse_m(d, cx, y0, r0, r0 * VIEW * 0.75)
    bell |= crown
    d.h = np.where(bell, np.sqrt(np.clip(1 - np.clip(t, -1, 1) ** 2, 0, 1)) * 16 + 2, d.h).astype(np.float32)
    d.mat[bell] = d.mid("m"); d.solid |= bell; d.polish[bell] = 0.8; d.tex[bell] = 0
    d.ramp_h(crown & (Y < y0), 13, 17, axis="y")
    c = Cyl(d, cx - r1, cx + r1, lipry)
    band_ = bell & (c.v >= y1 - 4)
    d.h[band_] += 1.4; d.tex[band_] = 0.1                                                      # the rolled lip
    d.seam(bell & (c.v >= y1 - 5) & (c.v < y1 - 4), 0.35)
    d.seam(bell & (c.v >= y0 + 4) & (c.v < y0 + 5), 0.25)                                      # the crown's seam
    for (rx_, ry_) in ((cx - 5, 61), (cx + 5, 61)):
        d.dome(rx_, ry_, 1.4, 1.4, 9, "chrome", polish=1.0)                                  # the yoke's rivets
    d.grain_pebble(bell, 0.04, seed=21)
    # the clapper's ball, hanging just below the lip
    d.dome(cx + 2, y1 + lipry + 4, 4, 3.6, 6, "k", polish=0.8)


# ------------------------------------------------------------------ 7. Thumbs of Green
@b5a(156, 112)
def thumbs_of_green(d):
    # a galvanized watering can side on, the spout and its rose out to the right, the fill opening on its top a level
    # ellipse, the arched handle over it; a Mason jar with its ring lid standing beside it
    X = d.XX + 0.5; Y = d.YY + 0.5
    cx, rx, y0, y1 = 70, 30, 44, 102
    # the spout first (the body stands in front of its root), a brace from the body to its middle
    cone_seg(d, (90, 92), (140, 40), 6.0, 3.4, 7, "chrome", polish=0.9)
    capsule(d, [(98, 62), (112, 70)], 2.4, 3, "chrome", polish=0.9)
    # the rose: a short flare, its face turned up the spout and a little toward us, pierced
    cone_seg(d, (138, 42), (145, 35), 3.6, 7.0, 8, "chrome", polish=0.9)
    rose = rot_ellipse(d, 145.5, 34.5, 10.5, 4.6, -45)
    d.flat(rose, 12, "chrome", polish=0.9); d.ramp_h(rose, 10, 14, axis="y")
    for (u, v) in ((-6, 0), (-3, -1.5), (0, 0), (3, 1.5), (6, 0), (-3, 1.5), (3, -1.5), (0, 3), (0, -3)):
        a = math.radians(-45); px_, py_ = 145.5 + u * math.cos(a) - v * math.sin(a) * 0.9, 34.5 + u * math.sin(a) + v * math.cos(a) * 0.9
        d.seam((np.hypot(X - px_, Y - py_) < 0.8) & rose, 0.5)
    # the body: an upright round can, the beads round it bowing with the view
    body, top = cyl_v(d, cx - rx, cx + rx, y0, y1, 20, "chrome", polish=0.85, top_ry=rx * VIEW, bot_ry=rx * VIEW)
    c = Cyl(d, cx - rx, cx + rx, rx * VIEW)
    for vv in (54, 90):
        r = band_v(d, body, c, vv, vv + 2); d.h[r] += 1.3
        r2 = band_v(d, body, c, vv + 2, vv + 3); d.dark[r2] = 0.2
    d.ramp_h(top, 18, 24, axis="y"); d.tex[top] = 0.05
    rimr = top & ~ellipse_m(d, cx, y0, rx - 2, (rx - 2) * VIEW); d.h[rimr] += 1.2
    # the fill opening, toward the back of the top, with its collar
    fo = ellipse_m(d, cx - 10, y0, 12, 12 * VIEW)
    col_b, col_t = cyl_v(d, cx - 22, cx + 2, y0 - 4, y0, 6, "chrome", polish=0.9, top_ry=12 * VIEW, on=20)
    hole = ellipse_m(d, cx - 10, y0 - 4, 9.5, 9.5 * VIEW)
    d.flat(hole, 14, "k", polish=0.1); d.dark[hole] = 0.3
    # the handle: a flat strap arching over the top from back to front, and the rear handle down the back
    arch = spline([(cx - 26, y0 + 2), (cx - 22, 18), (cx, 8), (cx + 20, 16), (cx + 24, y0 + 1)], 10)
    capsule(d, arch, 4, 5, "chrome", polish=0.9)
    rear = spline([(cx - rx + 1, 56), (cx - rx - 9, 62), (cx - rx - 10, 76), (cx - rx + 1, 86)], 8)
    capsule(d, rear, 4, 5, "chrome", polish=0.9)
    d.grain_pebble(body | top, 0.06, seed=17)
    # the Mason jar, to the left: the glass, the beans showing through, the ring lid
    # (glass: the shoulder rounds in to the neck, the beans fill it to the shoulder, the headspace clear above them)
    jx, jr = 20, 14
    prof = [(62, 9.5), (66, 10), (68, 12.5), (71, 14), (100, 14), (104, 13)]
    jb = revolve(d, jx, prof, 12, "l", polish=1.0)
    jb |= ellipse_m(d, jx, 103, 13, 13 * VIEW) & (Y > 103)
    d.mat[jb] = d.mid("l"); d.solid |= jb
    jc = Cyl(d, jx - jr, jx + jr, jr * VIEW)
    beans = jb & (jc.v >= 73)
    d.paint(beans, "d"); d.grain_pebble(beans, 0.22, seed=2)
    hl = jb & (np.abs(X - (jx - 7)) < 1.0) & (jc.v > 70) & (jc.v < 99)
    d.paint(hl, "w", polish=1.0)                                                               # the glass's highlight
    rb, rt = cyl_v(d, jx - 10, jx + 10, 55, 62, 11, "chrome", polish=1.0, top_ry=10 * VIEW, bot_ry=10 * VIEW)
    rc = Cyl(d, jx - 10, jx + 10, 10 * VIEW)
    for vv in (57, 59):
        d.seam(band_v(d, rb, rc, vv, vv + 1), 0.25)                                            # the ring's threads
    d.ramp_h(rt, 11, 14, axis="y"); d.tex[rt] = 0.05
    d.flat(ellipse_m(d, jx, 55, 7, 7 * VIEW), 13.5, "m", polish=0.5)                           # the flat lid in the ring


# ------------------------------------------------------------------ 8. Five Alarm Firehouse Chili
@b5a(132, 118)
def five_alarm_chili(d):
    # a cast-iron pot on three stubby legs, its rim a level ellipse, chili in it with a ladle standing in it, the lid
    # leaning against the pot's side, a wisp of steam rising
    X = d.XX + 0.5; Y = d.YY + 0.5
    cx, ry0 = 54, 44
    # the lid, leaning on the pot's right side (the pot, drawn after, hides where they meet)
    lid = rot_ellipse(d, 104, 78, 30, 12, -72)
    d.slab(lid, 10, "k", bevel=5, polish=0.7)
    d.torus(104, 78, 0, 0, 0, "k") if False else None
    rib = rot_ellipse(d, 104, 78, 22, 8.5, -72) & ~rot_ellipse(d, 104, 78, 20, 7.4, -72)
    d.h[rib] += 1.2
    d.dome(102.5, 77.5, 4, 5, 15, "k", polish=0.9)                                             # its knob
    # the legs: one toward us, two at the back corners
    for (lx, ly, top_) in ((cx - 28, 92, 84), (cx + 28, 92, 84), (cx, 104, 94)):
        d.slab(Mask(d.W, d.H).poly([(lx - 4, top_), (lx + 4, top_), (lx + 3, ly), (lx - 3, ly)]).get(), 7, "k", bevel=2, polish=0.6)
    # the belly
    prof = [(ry0, 38), (ry0 + 6, 38), (ry0 + 18, 42), (ry0 + 30, 41), (ry0 + 42, 34), (ry0 + 50, 24), (ry0 + 54, 0.5)]
    pot = revolve(d, cx, prof, 26, "k", polish=0.75)
    d.grain_pebble(pot, 0.05, seed=31)
    # the rim: a level ring, the chili inside a little below it, the pot's far inside wall between
    rim_o = ellipse_m(d, cx, ry0, 39, 39 * VIEW)
    rim_i = ellipse_m(d, cx, ry0, 34, 34 * VIEW)
    d.flat(rim_o & ~rim_i, 28, "k", polish=0.7); d.ramp_h(rim_o & ~rim_i & (Y < ry0), 26, 28, axis="y")
    wall = rim_i
    d.flat(wall, 20, "k", polish=0.2); d.dark[wall] = 0.25
    chili = ellipse_m(d, cx, ry0 + 3, 33, 33 * VIEW) & rim_i
    d.flat(chili, 22, "d", polish=0.3)
    rng = np.random.default_rng(14)
    for _ in range(26):                                                                         # beans and meat
        bx, by = cx + rng.uniform(-28, 28), ry0 + 3 + rng.uniform(-6, 6)
        if ((bx - cx) / 30) ** 2 + ((by - ry0 - 3) / 7) ** 2 < 1:
            m = ellipse_m(d, bx, by, 2.2, 1.3) & chili
            d.h[m] += 1.4; d.mat[m] = d.mid(("m", "k", "d")[_ % 3])
    # the ladle, standing in the chili and leaning on the rim, its hooked end up at the right
    capsule(d, [(cx + 10, ry0 + 2), (cx + 30, 10), (cx + 33, 4)], 3.6, 6, "chrome", polish=1.0)
    capsule(d, [(cx + 33, 4), (cx + 37, 4), (cx + 38, 8)], 2.6, 5, "chrome", polish=1.0)
    d.flat(ellipse_m(d, cx + 10, ry0 + 2.5, 5, 2) & chili, 23, "d", polish=0.3)               # where it goes in
    # steam, rising off the pot
    for (sx, ph, h) in ((cx - 10, 0.0, 30), (cx - 22, 1.7, 22)):
        pts = [(sx + 3.0 * math.sin(ph + k * 0.45), ry0 - 4 - k * 1.0) for k in range(h)]
        inkline(d, pts, 1.0)


if __name__ == "__main__":
    os.chdir(HERE)
    os.makedirs("px", exist_ok=True)
    names = sys.argv[1:] or B5A
    for n in names:
        im = render(n)
        im.save(os.path.join("px", n + ".png"))
        print(n, im.size)
