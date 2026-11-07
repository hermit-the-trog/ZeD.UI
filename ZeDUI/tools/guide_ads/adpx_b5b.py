"""Batch 5b of the survival guide's thirds (Nov 7 2026): ads 9 to 16 of batch 5's lineup (batch5_lineup.json), drawn
in ZeD's pixel art the same way as adpx.py (the dashes' engine, the book's one ink, one art pixel = one design pixel)
and in the one view (VIEW: front and a little from above, a level circle an ellipse 0.26 as tall as it is wide).
These register into adpx.DESIGNS; adpx.py itself is not touched.
usage: python adpx_b5b.py [name ...]  -> px/<name>.png (ink on transparent), only this batch's names"""
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import adpx                                                      # noqa: E402
from adpx import (E, INK, Mask, VIEW, Cyl, band_v, capsule, cyl_v, design, disc, ellipse_m, glyphs,   # noqa: E402
                  print_wrap, render, taper_v)

MINE = []


def mine(w, h):
    """adpx's @design, and the name kept in this batch's list"""
    def deco(fn):
        MINE.append(fn.__name__)
        return design(w, h)(fn)
    return deco


INK_ = tuple(int(v) for v in INK)


def ink_line(d, pts, w=1.0):
    """a printed line: ink, flat, no edge (steam, a rope, a dashed outline)"""
    m = Mask(d.W, d.H).line(pts, w).get()
    d.emit[m, :3] = INK_; d.emit[m, 3] = 255
    return m


def ink_px(d, m):
    d.emit[m, :3] = INK_; d.emit[m, 3] = 255


def spline(ctrl, n=10):
    """a Catmull-Rom curve through the points"""
    C = [ctrl[0]] + list(ctrl) + [ctrl[-1]]; pts = []
    for i in range(1, len(C) - 2):
        p0, p1, p2, p3 = map(np.array, (C[i - 1], C[i], C[i + 1], C[i + 2]))
        for k in range(n):
            t = k / n
            pts.append(tuple(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t ** 2
                                    + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3)))
    pts.append(tuple(ctrl[-1]))
    return pts


def turned(d, cx, prof, z, mat, polish=0.6, on=0.0, foot_ry=None):
    """an upright turned body (a bottle, a cartridge) from a profile [(y, radius), ...] down its height, round across
    x; it overwrites what is behind it (drawn back to front). foot_ry closes the bottom in the view's ellipse"""
    ys = np.array([p[0] for p in prof], float); rs = np.array([p[1] for p in prof], float)
    Y = d.YY + 0.5; X = d.XX + 0.5
    r = np.interp(Y, ys, rs, left=0, right=0)
    t = (X - cx) / np.maximum(r, 1e-3)
    m = (np.abs(t) <= 1) & (r > 0.3) & (Y >= ys[0]) & (Y <= ys[-1])
    if foot_ry:
        m |= ellipse_m(d, cx, ys[-1], rs[-1], foot_ry) & (Y > ys[-1])
        t = np.where(Y > ys[-1], (X - cx) / rs[-1], t)
    prof_h = on + np.sqrt(np.clip(1 - np.clip(t, -1, 1) ** 2, 0, 1)) * z
    d.h = np.where(m, prof_h, d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = polish; d.tex[m] = 0
    return m


def on_plane(m, x0, run, rise):
    """shift a flat print so it lies in a face whose top edge rises `rise` px over `run` px from x0"""
    out = np.zeros_like(m)
    for x in range(m.shape[1]):
        dy = int(round(rise * (x - x0) / run))
        col = m[:, x]
        if dy < 0: out[:dy, x] = col[-dy:]
        elif dy > 0: out[dy:, x] = col[:-dy]
        else: out[:, x] = col
    return out


def type_at(d, t, x, y, font="35", align="c", scale=1, gap=1):
    """a bool mask of a line of the pixel faces at (x, y), for painting onto a face"""
    g = glyphs(t, font, gap)
    if scale > 1: g = np.kron(g, np.ones((scale, scale), bool))
    m = np.zeros((d.H, d.W), bool)
    if align == "c": x -= g.shape[1] // 2
    elif align == "r": x -= g.shape[1]
    y0, x0 = max(0, y), max(0, x)
    y1, x1 = min(d.H, y + g.shape[0]), min(d.W, x + g.shape[1])
    m[y0:y1, x0:x1] = g[y0 - y:y1 - y, x0 - x:x1 - x]
    return m


# ================================================================== the pictures
@mine(120, 112)
def mendys_eatery(d):
    # a thick diner mug on its saucer, handle to the right, the coffee inside, a curl of steam. The saucer and the
    # mug's mouth are level circles (ellipses 0.26); the mug sits in the saucer's middle, its stripes bow with the lid
    X = d.XX + 0.5; Y = d.YY + 0.5
    cx = 54
    # the saucer: its underside's curve below the rim, the rim a soft roll round a flat well
    srx, scy = 52, 95
    sry = srx * VIEW
    under = ellipse_m(d, cx, scy + 4, srx - 6, sry - 1.5) & (Y > scy)
    d.slab(under, 4, "l", bevel=2, polish=0.5)
    top = ellipse_m(d, cx, scy, srx, sry)
    rho = np.hypot((X - cx) / srx, (Y - scy) / sry)
    hgt = 6 + np.where(rho > 0.74, np.sqrt(np.clip(1 - ((rho - 0.87) / 0.13) ** 2, 0, 1)) * 3, 0)
    d.h = np.where(top, hgt, d.h).astype(np.float32)
    d.mat[top] = d.mid("l"); d.solid |= top; d.polish[top] = 0.7; d.tex[top] = 0
    # the handle first, so the body covers its roots: a thick loop out to the right
    hpts = [(cx + 24 + 17 * math.cos(math.radians(a)), 66 + 15 * math.sin(math.radians(a))) for a in range(-84, 85, 6)]
    capsule(d, hpts, 7.5, 9, "l", polish=0.8)
    # the mug: a heavy straight body, the foot rounding under it
    rx = 26
    ry = rx * VIEW
    body, lid = cyl_v(d, cx - rx, cx + rx, 40, 92, 20, "l", polish=0.8, top_ry=ry, bot_ry=ry, on=8)
    cy = Cyl(d, cx - rx, cx + rx, ry)
    foot = band_v(d, body, cy, 88, 93); d.dark[foot] = 0.10                                      # the foot's turn under
    band_v(d, body, cy, 47, 49, "d")                                                          # the diner stripes
    band_v(d, body, cy, 51, 52, "d")
    # the mouth: a thick rolled lip, the coffee a little down inside it, the inner wall showing above the coffee
    lip = ellipse_m(d, cx, 40, rx, ry) & ~ellipse_m(d, cx, 40, rx - 3.5, ry - 1)
    d.h = np.where(lip, 30 + (Y - 40) * 0.5, d.h).astype(np.float32); d.mat[lip] = d.mid("l"); d.solid |= lip
    inner = ellipse_m(d, cx, 40, rx - 3.5, ry - 1)
    d.flat(inner, 24, "l", polish=0.2); d.dark[inner] = 0.18
    coffee = ellipse_m(d, cx, 43.5, rx - 3.5, ry - 1) & inner
    d.flat(coffee, 23, "k", polish=1.0)
    d.paint(ellipse_m(d, cx - 8, 44, 6, 1.2) & coffee, "d")                                     # the light on the coffee
    # the steam: two thin curls rising off the coffee, broken as steam is
    for (x0, ph, top_y, gaps) in ((46, 0.0, 6, (18, 27)), (62, 1.8, 14, (22, 30))):
        pts = [(x0 + 4.5 * math.sin(ph + (36 - y) * 0.22) * (0.4 + (36 - y) / 40), y) for y in np.arange(36, top_y, -0.5)]
        pts = [p for p in pts if not (gaps[0] < p[1] < gaps[1] - 4)]
        run = [pts[0]]
        for p in pts[1:]:
            if abs(p[1] - run[-1][1]) > 1: ink_line(d, run, 1.0); run = []
            run.append(p)
        ink_line(d, run, 1.0)


@mine(124, 120)
def knox_distillery(d):
    # a bourbon bottle with a wax-dipped neck running down in drips, a paper label reading KNOX; a short rocks glass
    # beside it with a finger of whiskey (its rim and the whiskey's top level circles, ellipses 0.26)
    X = d.XX + 0.5; Y = d.YY + 0.5
    cx, R = 42, 22
    ry = R * VIEW
    prof = [(6, 6.4), (11, 6.4), (11.5, 5.2), (30, 5.6), (34, 8), (40, 15), (46, 20), (50, R), (112, R)]
    glass = turned(d, cx, prof, 18, "d", polish=1.0, foot_ry=ry)
    cy = Cyl(d, cx - R, cx + R, ry)
    d.paint(glass & (np.abs(X - (cx - 13)) < 1.0) & (Y > 52) & (Y < 108), "l")                 # the glass's long light
    d.paint(glass & (np.abs(X - (cx - 4.2)) < 0.6) & (Y > 14) & (Y < 32), "l")                 # and on the neck
    # the wax, dipped over the lip and the top of the neck (a coat standing a little proud of the glass), running down
    # in drips over the shoulder; red wax, so it prints a step lighter than the dark glass
    t_ = np.clip((Y - 6) / 24, 0, 1)
    coat = (np.abs(X - cx) <= np.interp(Y, [4, 6, 11, 12, 26, 30], [6.4, 7.6, 7.6, 6.6, 6.8, 7.4])) & (Y >= 4) & (Y < 27 + 2 * np.sin(X * 1.3))
    drip = np.zeros_like(coat)
    for (x0, L, w) in ((cx - 6, 9, 1.7), (cx - 2.5, 17, 2.0), (cx + 2, 6, 1.6), (cx + 5.5, 13, 1.8), (cx - 8.5, 5, 1.4)):
        tip = 26 + L
        drip |= ((np.abs(X - x0) < w) & (Y >= 24) & (Y < tip)) | (np.hypot((X - x0) / w, (Y - tip) / (w * 1.1)) <= 1)
    wax = coat | (drip & glass)
    dist = E.edt(wax)
    d.h = np.where(wax, np.maximum(d.h, 14 + np.sqrt(np.minimum(dist, 3) / 3) * 6) + 1, d.h).astype(np.float32)
    d.mat[wax] = d.mid("m"); d.solid |= wax; d.polish[wax] = 1.0; d.tex[wax] = 0
    d.seam(wax & (np.abs(Y - 11.5) < 0.6), 0.25)                                              # the lip under the wax
    # the paper label on the round body: its edges bow with the body, the print runs round it
    lab = glass & (cy.v >= 60) & (cy.v < 98) & (np.abs(cy.u) <= 18)
    d.mat[lab] = d.mid("w"); d.polish[lab] = 0.2; d.h[lab] += 0.5
    for vv in (63, 94):
        d.paint(lab & (cy.v >= vv) & (cy.v < vv + 1) & (np.abs(cy.u) <= 15), "p")              # the label's rules
    print_wrap(d, lab, cy, "KNOX", 68, "p", font="57")
    d.paint(lab & (cy.v >= 78) & (cy.v < 79) & (np.abs(cy.u) <= 6), "p")
    print_wrap(d, lab, cy, "BOURBON", 82, "p")
    # the rocks glass: heavy, short, clear (it prints pale); the whiskey a finger deep, its top a level circle lit from
    # above; the thick base under it; the mouth's back rim seen through the opening
    gx, gr = 98, 17
    gry = gr * VIEW
    body, lid = cyl_v(d, gx - gr, gx + gr, 80, 112, 12, "w", polish=1.0, top_ry=gry, bot_ry=gry)
    gc = Cyl(d, gx - gr, gx + gr, gry)
    whisky = band_v(d, body, gc, 97, 106, "d")
    d.tex[whisky] = 0.0
    d.flat(ellipse_m(d, gx, 97, gr - 1.5, gry - 0.4), 11, "m", polish=1.0)                    # the whiskey's top
    base = band_v(d, body, gc, 106, 113, "w"); d.seam(band_v(d, body, gc, 106, 107), 0.2)  # the base
    mouth = ellipse_m(d, gx, 80, gr - 1.6, gry - 0.6)
    d.flat(lid & ~mouth, 15, "w", polish=1.0)                                                 # the rim
    d.flat(mouth, 9, "w", polish=0.2)                                                         # through the glass
    d.paint(mouth & ~ellipse_m(d, gx, 81.2, gr - 2.6, gry - 0.9), "l")                        # the back wall's rim
    d.paint(body & (np.abs(X - (gx - 11)) < 0.8) & (Y > 84) & (Y < 106), "pw")                # the light down its side
    d.paint(body & (np.abs(X - (gx + 11.5)) < 0.7) & (Y > 84) & (Y < 104), "l")


@mine(132, 98)
def first_baptist_bake_sale(d):
    # a lattice-top pie in a fluted tin: the tin flares to its rim; the crust's crimped edge round the top (a level
    # circle); the lattice strips woven over the filling, laid in the pie's own plane so they follow its ellipse; a
    # pie server lying on the table in front
    X = d.XX + 0.5; Y = d.YY + 0.5
    cx, cy, rx = 66, 38, 56
    ry = rx * VIEW
    # the tin: wider at the rim than the foot, its flutes closing up toward the sides
    body, _ = taper_v(d, cx, cy, cy + 13, rx - 1, rx - 8, 10, "chrome", polish=0.8)
    r = (rx - 1) + ((rx - 8) - (rx - 1)) * np.clip((Y - cy) / 13, 0, 1)
    u = r * np.arcsin(np.clip((X - cx) / r, -1, 1))
    d.tex[body] = (0.10 * np.sin(u * 2 * math.pi / 5))[body]
    d.seam(body & (np.mod(u, 5) < 0.8), 0.25)
    # the filling, then the lattice over it, then the crust's crimped rim round them
    p = (X - cx); q = (Y - cy) / VIEW                                     # the pie's own plane (q toward us)
    rho = np.hypot(p / rx, (Y - cy) / ry)
    fill = rho <= 0.86
    d.flat(fill, 13, "d", polish=0.8)
    d.grain_pebble(fill, 0.12, seed=4)
    S, w = 19.0, 6.0
    s1 = (p + q) / math.sqrt(2); s2 = (p - q) / math.sqrt(2)
    f1 = np.abs(np.mod(s1 + S / 2, S) - S / 2); f2 = np.abs(np.mod(s2 + S / 2, S) - S / 2)
    i1 = np.floor((s1 + S / 2) / S); i2 = np.floor((s2 + S / 2) / S)
    m1 = (f1 < w / 2) & (rho <= 0.9); m2 = (f2 < w / 2) & (rho <= 0.9)
    over1 = np.mod(i1 + i2, 2) == 0                                       # the weave: over, under, over
    h1 = 15 + 2.2 * np.sqrt(np.clip(1 - (f1 / (w / 2)) ** 2, 0, 1)) + np.where(m2 & over1, 1.5, 0)
    h2 = 15 + 2.2 * np.sqrt(np.clip(1 - (f2 / (w / 2)) ** 2, 0, 1)) + np.where(m1 & ~over1, 1.5, 0)
    lat = m1 | m2
    top1 = m1 & (~m2 | over1)
    hh = np.where(top1, h1, h2)
    d.h = np.where(lat, hh, d.h).astype(np.float32)
    d.mat[lat] = d.mid("m"); d.solid |= lat; d.polish[lat] = 0.3; d.tex[lat] = 0
    d.seam(m1 & m2 & ~top1 & (f2 > w / 2 - 1.2), 0.3)                    # the edge of the strip on top, at each cross
    d.seam(m1 & m2 & top1 & (f1 > w / 2 - 1.2), 0.3)
    d.grain_pebble(lat, 0.05, seed=6)
    phi = np.arctan2((Y - cy) / ry, (X - cx) / rx)
    rim = (rho > 0.82) & (rho <= 1.03)
    rh = 16 + 3.2 * np.sqrt(np.clip(1 - ((rho - 0.925) / 0.105) ** 2, 0, 1)) + 1.2 * np.cos(phi * 26)
    d.h = np.where(rim, rh, d.h).astype(np.float32)
    d.mat[rim] = d.mid("m"); d.solid |= rim; d.polish[rim] = 0.3; d.tex[rim] = 0
    d.seam(rim & (np.cos(phi * 26) < -0.85), 0.2)                         # the crimps' folds
    # the pie server, lying on the table in front of the tin: a wedge blade, its neck, the handle out to the right.
    # Drawn in the table's plane (x across, depth squeezed by VIEW) and turned a little toward us
    ang = math.radians(-24)
    ca, sa = math.cos(ang), math.sin(ang)
    def T(a, b, h=0.0):                                                   # a: along the server, b: across it (depth)
        x = 62 + a * ca - b * sa; z = a * sa + b * ca
        return (x, 82 + z * VIEW - h)
    blade = Mask(d.W, d.H).poly([T(-50, 0), T(-42, -7), T(-14, -21), T(-6, -6), T(-6, 6), T(-14, 21), T(-42, 7)]).get()
    d.slab(blade, 3, "chrome", bevel=1.2, polish=1.0)
    d.slab(Mask(d.W, d.H).poly([T(-8, -3, 0.5), T(4, -2, 2.5), T(4, 2, 2.5), T(-8, 3, 0.5)]).get(), 4, "chrome", bevel=1, polish=1.0)
    capsule(d, [T(4, 0, 3), T(54, 0, 3.5)], 5.5, 6, "d", polish=0.5)                         # the handle
    d.grain_wood(Mask(d.W, d.H).line([T(5, 0, 3), T(53, 0, 3.5)], 5).get(), scale=0.5, seed=3)
    for a in (12, 44):
        d.dome(*T(a, 0, 4.5), 1.2, 1.2, 1, "chrome", on="add")                               # its rivets


@mine(124, 118)
def rusty_rifle(d):
    # a cardboard box of rifle cartridges, its lid open and propped behind, the rounds standing in rows in their
    # divider (each row a step further back, so a step higher; each staggered so the rows read), two loose rounds
    # lying in front. Front-on and a little from above: the box's top opening is its depth times VIEW
    X = d.XX + 0.5; Y = d.YY + 0.5
    x0, x1 = 12, 112
    front_top, front_bot = 69, 100
    depth = 44
    back_top = front_top - depth * VIEW
    # the lid, leaning back from the back edge: its inside face, lit as it tips up toward us; the tuck flap on top
    lid = Mask(d.W, d.H).rect(x0 + 1, 12, x1 - x0 - 2, back_top - 12 + 1).get()
    d.ramp_h(lid, 4, 9, axis="y", mat="w", polish=0.3)
    flap = Mask(d.W, d.H).poly([(x0 + 10, 12), (x1 - 10, 12), (x1 - 16, 5), (x0 + 16, 5)]).get()
    d.ramp_h(flap, 3, 4, axis="y", mat="l", polish=0.3)
    d.seam(Mask(d.W, d.H).rect(x0 + 10, 12, x1 - x0 - 20, 1).get(), 0.3)                    # the flap's fold
    for t, y, font, sc in (("30-30", 17, "57", 1), ("150 GR", 27, "35", 1), ("20 CENTERFIRE", 34, "35", 1)):
        d.paint(type_at(d, t, 62, y, font, scale=sc), "p")
    d.paint(Mask(d.W, d.H).rect(x0 + 8, 42, x1 - x0 - 16, 1).get(), "p")
    # the rounds: brass cases, a shoulder and neck, the copper bullet, its soft lead tip
    def round_up(x, base, on):
        L = 48.0
        top = base - L
        prof = [(top, 0.8), (top + 1.5, 1.8), (top + 5, 3.0), (top + 11, 3.5), (top + 12, 3.2), (top + 16, 3.2), (top + 21, 4.5),
                (base - 1, 4.6), (base, 4.8)]
        m = turned(d, x, prof, 5, "l", polish=1.0, on=on)
        d.mat[m & (Y < top + 12)] = d.mid("d")                            # the copper bullet
        d.mat[m & (Y < top + 2.5)] = d.mid("k")                           # its soft lead point
        d.seam(m & (np.abs(Y - (top + 12)) < 0.5), 0.3)                   # the case mouth
        d.dark[m & (np.abs(X - x) > np.interp(Y, [p[0] for p in prof], [p[1] for p in prof]) - 1.0)] = 0.38   # its edge
        return m
    inside = Mask(d.W, d.H).rect(x0, back_top, x1 - x0, front_top - back_top + 1).get()
    d.flat(inside, 6, "l", polish=0.2); d.dark[inside] = 0.2                                # the tray's inside, in shade
    rows = ((30, 5.5, 10, 0.14), (10, 0.0, 12, 0.0))                      # depth, stagger, height on, the box's shade
    for dz, off, on, shade in rows:
        base = front_bot - 2 - dz * VIEW
        for k in range(10):
            x = x0 + 7 + off + k * 11
            if x > x1 - 7: continue
            m = round_up(x, base, on)
            d.dark[m] = np.maximum(d.dark[m], shade)
    # the tray's front wall (over the rounds' feet) with its print
    for sx in (x0, x1 - 2):                                               # the side walls' cut tops
        wall = Mask(d.W, d.H).rect(sx, back_top, 2, front_top - back_top).get()
        d.ramp_h(wall, 12, 15, axis="y", mat="l", polish=0.3); d.dark[wall] = 0
    front = Mask(d.W, d.H).rect(x0, front_top, x1 - x0, front_bot - front_top).get()
    d.slab(front, 16, "w", bevel=1.2, polish=0.3); d.dark[front] = 0
    d.flat(Mask(d.W, d.H).rect(x0, front_top, x1 - x0, 2).get(), 17, "l", polish=0.3)          # the wall's cut edge
    band_ = Mask(d.W, d.H).rect(x0, front_top + 6, x1 - x0, 11).get()
    d.paint(band_, "d")
    d.paint(type_at(d, "RIFLE CARTRIDGES", 62, front_top + 9), "pw")
    d.paint(type_at(d, "KEEP AWAY FROM CHILDREN", 62, front_top + 19), "p")
    # two loose rounds lying on the table in front, side on, each a little turned
    def round_lying(xb, yb, ang, L=44.0):
        ca, sa = math.cos(ang), math.sin(ang)
        a = (X - xb) * ca + (Y - yb) * sa                                 # along it from the base
        b = -(X - xb) * sa + (Y - yb) * ca                                # across it
        rs = np.interp(a, [0, 1.0, 1.6, 27, 32, 36, 37, 43, 46.5, 48], [4.8, 4.8, 4.4, 4.4, 3.2, 3.2, 3.5, 3.0, 1.8, 0.8],
                       left=0, right=0)
        m = (np.abs(b) <= rs) & (rs > 0.3)
        hgt = 20 + np.sqrt(np.clip(1 - (b / np.maximum(rs, 1e-3)) ** 2, 0, 1)) * 5
        d.h = np.where(m, hgt, d.h).astype(np.float32)
        d.mat[m] = d.mid("l"); d.solid |= m; d.polish[m] = 1.0; d.tex[m] = 0
        d.mat[m & (a > 36)] = d.mid("d")
        d.mat[m & (a > 45.5)] = d.mid("k")
        d.seam(m & (np.abs(a - 1.6) < 0.5), 0.35)                         # the rim's groove
        d.seam(m & (np.abs(a - 36) < 0.5), 0.3)
    round_lying(8, 109, math.radians(-3))
    round_lying(118, 112, math.radians(186))


def poly_inside(poly, x, y):
    """is (x, y) inside the polygon (even-odd)"""
    n, c = len(poly), False
    for i in range(n):
        (x0, y0), (x1, y1) = poly[i], poly[(i + 1) % n]
        if (y0 > y) != (y1 > y) and x < x0 + (y - y0) * (x1 - x0) / (y1 - y0): c = not c
    return c


def dashed(d, paths, others=(), on=3.0, off=2.5, closed=True):
    """an ink outline in dashes along each path (a polygon's edge), skipping what lies inside the other polygons"""
    m = np.zeros((d.H, d.W), bool)
    for path in paths:
        pts = list(path) + ([path[0]] if closed else [])
        s = 0.0
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            L = math.hypot(x1 - x0, y1 - y0); n = max(1, int(L / 0.25))
            for k in range(n):
                t = k / n; x = x0 + (x1 - x0) * t; y = y0 + (y1 - y0) * t
                s_ = s + L * t
                if (s_ % (on + off)) >= on: continue
                if any(poly_inside(o, x, y) for o in others if o is not path): continue
                X, Y = int(math.floor(x)), int(math.floor(y))
                if 0 <= X < d.W and 0 <= Y < d.H: m[Y, X] = True
            s += L
    ink_px(d, m)
    return m


@mine(172, 64)
def invisible_sledgehammer(d):
    # the invisible sledgehammer: nothing but a dashed outline (the head standing on its face, the long handle run
    # down to rest its knob on the ground, the way a sledge lies), and its shadow, printed solid on the ground, cast
    # forward and to the right (front and a little from above: the ground's depth is squeezed by VIEW)
    G, K = 50.0, 1.18                                                    # the ground line under it; the drawing's scale
    px_, py_ = 26.0, G                                                   # it rests on the head's front lower edge
    th = math.atan2(13.0, 112.0)
    ct, st = math.cos(th), math.sin(th)
    def R(x, y):                                                         # the hammer's own axes: x along the handle
        dx, dy = (x - 18.0) * K, y * K                                    # from the pivot, y up is negative
        return (px_ + dx * ct - dy * st, py_ + dx * st + dy * ct)
    head = [R(*p) for p in ((2, 0), (16, 0), (18, -2), (18, -32), (16, -34), (2, -34), (0, -32), (0, -2))]
    handle = [R(*p) for p in ((18, -19.5), (40, -19.0), (100, -18.6), (118, -19.6), (128, -20), (131, -18), (131, -14),
                              (128, -12), (118, -12.6), (100, -13.6), (40, -14.2), (18, -14.0))]
    # the shadow: each point dropped to the ground along the light (out to the right, toward us, by its height)
    def S(p):
        hgt = G - p[1]
        return (p[0] + 0.62 * hgt, G + 0.26 * 0.95 * hgt)
    sh = Mask(d.W, d.H).poly([S(p) for p in head]).poly([S(p) for p in handle]).get()
    # where the hammer stands, its shadow begins: the head's foot and the knob's touch
    sh |= Mask(d.W, d.H).poly([head[0], head[1], S(head[1]), S(head[0])]).get()
    ink_px(d, sh)
    dashed(d, [head, handle], others=[head, handle])
    # the head's chamfers, the eye's wedge: dashed too, the lines a sledge is known by
    dashed(d, [[R(0, -5), R(18, -5)], [R(0, -29), R(18, -29)]], closed=False, on=2.0, off=2.0)


@mine(124, 124)
def electron_house(d):
    # a walkie-talkie standing up, facing us: the telescoping antenna up from its top, the channel knob beside it, the
    # speaker grille, the panel; the talk button on its side. Its twin lies on its back behind it, a little to the right
    X = d.XX + 0.5; Y = d.YY + 0.5
    # the twin on its back: the radio's side toward us, its face (the grille's slots run across it, so here they run
    # back, short upright strokes) turned up to the light; the knob and the stubby antenna out at its far end
    tb, tx0, tx1, T = 103, 46, 106, 12
    tdep = 40 * VIEW
    tface = Mask(d.W, d.H).rrect(tx0, tb - T - tdep, tx1 - tx0, tdep + 3, 3).get()
    d.ramp_h(tface, 8, 12, axis="y", mat="k", polish=0.6)
    tside = Mask(d.W, d.H).rrect(tx0, tb - T, tx1 - tx0, T, 3).get()
    d.slab(tside, 12, "k", bevel=3, polish=0.6)
    d.grain_pebble(tside | tface, 0.05, seed=12)
    for x in range(58, 82, 3):
        d.seam(Mask(d.W, d.H).rect(x, tb - T - tdep + 2, 1, tdep - 2).get(), 0.45)            # its grille, turned up
    d.paint(Mask(d.W, d.H).rect(86, tb - T - tdep + 2, 14, tdep - 2).get() & tface, "l")    # its panel
    d.slab(Mask(d.W, d.H).rect(tx1 - 1, tb - T - 2, 6, 8).get(), 11, "k", bevel=1.5, polish=0.6)   # the knob, on end
    for y in range(tb - T - 1, tb - T + 6, 2):
        d.seam(Mask(d.W, d.H).rect(tx1 + 1, y, 4, 1).get(), 0.3)
    capsule(d, [(tx1 + 2, tb - 4), (122, tb - 5)], 3.2, 3, "chrome", polish=1.0)              # the antenna, run in
    d.dome(122, tb - 5, 1.8, 1.8, 3, "chrome", polish=1.0)
    # the upright radio. The talk button first, so the body covers its root: a long ribbed bar on the left side
    ptt = Mask(d.W, d.H).rrect(10, 52, 9, 26, 2).get()
    d.slab(ptt, 10, "d", bevel=2, polish=0.5)
    for y in range(55, 76, 3):
        d.seam(Mask(d.W, d.H).rect(10, y, 4, 1).get(), 0.35)
    bx0, bx1, btop, bbot = 16, 58, 31, 120
    topf = Mask(d.W, d.H).rrect(bx0 + 1, btop - 5, bx1 - bx0 - 2, 10, 4).get()
    d.ramp_h(topf, 10, 14, axis="y", mat="k", polish=0.5)                                   # its top, a sliver from above
    body = Mask(d.W, d.H).rrect(bx0, btop, bx1 - bx0, bbot - btop, 6).get()
    d.slab(body, 14, "k", bevel=5, polish=0.6)
    d.grain_pebble(body | topf, 0.05, seed=13)
    # the antenna's collar on the top, the antenna in two drawn-out sections, the ball on its tip
    cyl_v(d, 20, 29, 21, 29, 5, "k", polish=0.6, top_ry=4.5 * VIEW, bot_ry=4.5 * VIEW, on=12)
    capsule(d, [(24.5, 22), (24.5, 11)], 3.2, 3, "chrome", polish=1.0)
    capsule(d, [(24.5, 12), (24.5, 3)], 2.0, 2, "chrome", polish=1.0)
    d.dome(24.5, 3, 2.0, 2.0, 3, "chrome", polish=1.0)
    # the channel knob on the top, ribbed round
    kb, kt = cyl_v(d, 43, 53, 21, 29, 6, "d", polish=0.6, top_ry=5 * VIEW, bot_ry=5 * VIEW, on=12)
    kc = Cyl(d, 43, 53, 5 * VIEW)
    d.seam(kb & (np.mod(kc.u + 0.5, 2.2) < 0.7), 0.35)
    # the speaker grille: a chrome plate set in, its slots across
    gr = Mask(d.W, d.H).rrect(22, 39, 30, 32, 3).get()
    d.slab(gr, 1.5, "chrome", bevel=1, polish=0.9, on=13)
    for y in range(42, 69, 3):
        d.well(Mask(d.W, d.H).rrect(25, y, 24, 1.6, 0.8).get(), 1.5, mat="k", bevel=0.5)
    # the panel: its band and print, the call button
    pn = Mask(d.W, d.H).rrect(22, 76, 30, 36, 2).get()
    d.slab(pn, 1, "l", bevel=0.6, polish=0.3, on=13.5)
    d.paint(type_at(d, "CB", 37, 80, "57", scale=2), "p")
    d.paint(type_at(d, "40 CH", 37, 97, "35"), "p")
    d.slab(Mask(d.W, d.H).rrect(29, 104, 16, 5, 2).get(), 2, "d", bevel=1, polish=0.5, on=14)   # the call button
    d.dome(49, 106.5, 1.6, 1.6, 1.5, "k", polish=1.0, on=14.5)                                   # the lamp


@mine(132, 110)
def plugged_in_electrics(d):
    # a portable gas generator in its frame of steel tube, front-on and a little from above: the fuel tank on top with
    # its round cap (a level circle) and gauge; the engine on the left, its pull-start cover facing us, the T-grip on
    # its rope; the outlet panel on the right; rubber feet. The frame's back loop shows above the tank (its depth by
    # VIEW), the front loop in front of everything
    X = d.XX + 0.5; Y = d.YY + 0.5
    def loop(top, bot, z, w=4.2):
        r = 8
        pts = [(8, bot)] + [(8 + r - r * math.cos(math.radians(a)), top + r - r * math.sin(math.radians(a))) for a in range(0, 91, 10)] \
            + [(124 - r + r * math.sin(math.radians(a)), top + r - r * math.cos(math.radians(a))) for a in range(0, 91, 10)] + [(124, bot)]
        capsule(d, pts, w, z, "chrome", polish=0.9)
        capsule(d, [(8, bot), (124, bot)], w, z, "chrome", polish=0.9)
    dep = 56 * VIEW
    loop(16 - dep, 100 - dep, 6)                                                              # the back loop
    d.dark[d.solid] = 0.12
    inside = Mask(d.W, d.H).rect(12, 44, 108, 54).get()
    d.flat(inside, 3, "k", polish=0.2); d.dark[inside] = 0.25                                  # the works, in shade
    # the tank: its top lit, its front face; the cap and the gauge on top; its print
    ttop = Mask(d.W, d.H).rrect(22, 20, 88, 16, 6).get()
    d.ramp_h(ttop, 10, 16, axis="y", mat="m", polish=0.6)
    tfr = Mask(d.W, d.H).rrect(20, 31, 92, 17, 4).get()
    d.slab(tfr, 16, "m", bevel=4, polish=0.6); d.dark[ttop | tfr] = 0
    cyl_v(d, 79, 93, 22, 27, 4, "d", polish=0.6, top_ry=7 * VIEW, bot_ry=7 * VIEW, on=14)      # the cap's collar
    cb, ct = cyl_v(d, 81, 91, 20, 24, 3, "k", polish=0.7, top_ry=5 * VIEW, bot_ry=5 * VIEW, on=17)
    d.seam(cb & (np.mod(X, 2) < 1), 0.3)                                                        # its ribs
    d.flat(ellipse_m(d, 42, 26, 7, 7 * VIEW + 0.6), 15, "l", polish=1.0)                      # the gauge, under glass
    d.paint(Mask(d.W, d.H).line([(42, 26.5), (46, 24.8)], 0.9).get(), "p")
    d.paint(type_at(d, "5000 WATTS", 66, 37, "35"), "p")
    # the engine: its pull-start cover facing us, vented in rings, the hub; the air cleaner over it
    d.slab(Mask(d.W, d.H).rrect(14, 50, 30, 12, 3).get(), 10, "d", bevel=2, polish=0.4)       # the air cleaner
    d.seam(Mask(d.W, d.H).rect(16, 55, 26, 1).get(), 0.3)
    rc = Mask(d.W, d.H).ellipse(40, 77, 21, 21).get()
    d.slab(rc, 12, "k", bevel=7, polish=0.7)
    R_ = np.hypot(X - 40, Y - 77)
    for r_ in (9, 13, 17):
        d.seam(rc & (np.abs(R_ - r_) < 0.6) & (np.mod(np.degrees(np.arctan2(Y - 77, X - 40)), 30) > 6), 0.45)
    d.dome(40, 77, 5, 5, 4, "chrome", polish=1.0, on=12)
    capsule(d, [(53, 91), (59, 95)], 1.2, 1, "d")                                               # the rope
    capsule(d, [(54, 97), (66, 94)], 4.4, 6, "d", polish=0.5)                                   # the T-grip
    # the outlet panel: two duplex receptacles, the breakers, the switch, the print
    pn = Mask(d.W, d.H).rrect(70, 51, 46, 46, 2).get()
    d.slab(pn, 13, "l", bevel=1, polish=0.4); d.dark[pn] = 0
    d.paint(type_at(d, "120 V AC", 93, 54, "35"), "p")
    for ox in (82, 104):
        d.slab(Mask(d.W, d.H).rrect(ox - 8, 61, 16, 24, 2).get(), 1.5, "w", bevel=0.6, polish=0.3, on=13)
        for oy in (63, 74):                                                                    # each face: two slots, the ground
            d.slab(Mask(d.W, d.H).rrect(ox - 6, oy, 12, 9, 3).get(), 1, "w", bevel=0.8, polish=0.4, on=14.5)
            d.well(Mask(d.W, d.H).rect(ox - 4, oy + 2, 1.4, 3.6).get(), 1.5, mat="k", bevel=0.4)
            d.well(Mask(d.W, d.H).rect(ox + 2.6, oy + 2, 1.4, 3.6).get(), 1.5, mat="k", bevel=0.4)
            d.well(Mask(d.W, d.H).ellipse(ox, oy + 7, 1.2, 1.0).get(), 1.5, mat="k", bevel=0.4)
    for bx_ in (78, 88):
        d.dome(bx_, 91, 3.2, 2.6, 3, "k", polish=0.8, on=13)                                    # the breakers
    d.slab(Mask(d.W, d.H).rrect(100, 87, 12, 8, 1).get(), 1.5, "d", bevel=0.6, on=13)           # the switch
    d.slab(Mask(d.W, d.H).rrect(102, 88, 4, 6, 1).get(), 3, "w", bevel=0.8, polish=0.6, on=14)
    # the front loop of the frame, then its feet
    loop(16, 100, 20)
    for fx in (16, 116):
        d.slab(Mask(d.W, d.H).rrect(fx - 6, 101, 12, 7, 2).get(), 9, "k", bevel=2, polish=0.4)


def book(d, cx, cy, L, Wd, T, ang, front="spine", cover="d", title=None, title_mat="pw", under=None):
    """a hardback lying flat, turned `ang` in the table's plane, each face a clean flat plane in its own tone (review,
    Nov 7: the ends read notchy): its top seen from a little above (its depth by VIEW), the face toward us (the rounded
    spine, or the page edges between the boards) and the end that turns toward us. cy is the screen y of its middle at
    its foot. `under`: the books already drawn below it, to ink the edge between and lay this one's shadow on them.
    Returns (top, front, end, all) masks, the front's corners and the placer P(a, b, h)"""
    ca, sa = math.cos(ang), math.sin(ang)
    def P(a, b, h):                                                       # a: along it, b: toward us, h: up
        return (cx + a * ca - b * sa, cy + (a * sa + b * ca) * VIEW - h)
    a0, a1, b1 = -L / 2, L / 2, Wd / 2
    aE = a1 if sa > 0 else a0                                             # the end that turns toward us
    frontp = [P(a0, b1, 0), P(a1, b1, 0), P(a1, b1, T), P(a0, b1, T)]
    endp = [P(aE, b1, 0), P(aE, -b1, 0), P(aE, -b1, T), P(aE, b1, T)]
    topp = [P(a0, -b1, T), P(a1, -b1, T), P(a1, b1, T), P(a0, b1, T)]
    M = lambda pts: Mask(d.W, d.H).poly(pts).get()
    top, fr, en = M(topp), M(frontp), M(endp)
    fr &= ~top; en &= ~(top | fr)
    allm = top | fr | en
    X = d.XX + 0.5; Y = d.YY + 0.5

    def tone(m, mat, k):                                                  # flat-lit, ramp step k (0 dark .. 7 light)
        d.h[m] = 0; d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = 0; d.tex[m] = 0
        d.flatlight |= m; d.noshadow |= m; d.dark[m] = 0.52 - k / 7.0

    def across(p_lo0, p_lo1, p_hi):
        """0 on the line p_lo0 -> p_lo1 (a face's bottom edge) .. 1 at p_hi (on its top edge), straight across"""
        (x0, y0), (x1, y1), (x2, y2) = p_lo0, p_lo1, p_hi
        ex, ey = x1 - x0, y1 - y0; n = math.hypot(ex, ey); ex, ey = ex / n, ey / n
        nx, ny = -ey, ex
        if (x2 - x0) * nx + (y2 - y0) * ny < 0: nx, ny = -nx, -ny
        full = (x2 - x0) * nx + (y2 - y0) * ny
        return ((X - x0) * nx + (Y - y0) * ny) / full

    def pages(m, t, thick, base):
        """a page block between two boards: the boards a line of the cover each, the pages' fine lines between"""
        tone(m, "w", base)
        board = m & ((t < 1.5 / thick) | (t > 1 - 1.5 / thick))
        tone(board, cover, 4 if base >= 5 else 3)
        for k in range(1, int(thick // 2)):
            tone(m & ~board & (np.abs(t - k * 2.0 / thick) < 0.5 / thick), "w", base - 2)

    # the top board: lit from above, its edge toward us a step lighter
    tone(top, cover, 5)
    tone(top & (across(topp[3], topp[2], topp[0]) < 0.07), cover, 6)
    # the end toward us: the page block, in shade
    pages(en, across(endp[0], endp[1], endp[3]), T, 3)
    if front == "spine":
        # the spine, rounded: in shade along its foot, lit along its top, in clean bands along its length
        t = across(frontp[0], frontp[1], frontp[3])
        for lo_, hi_, k in ((-1, 0.1, 2), (0.1, 0.3, 3), (0.3, 0.55, 4), (0.55, 0.82, 5), (0.82, 2, 6)):
            tone(fr & (t >= lo_) & (t < hi_), cover, k)
        # the bands near its ends and the title stamped on it
        # each pair two one-pixel rules with a clear pixel column between (review, Nov 7: they ran together into a
        # block): the outer rule snapped to a whole pixel, the inner one two pixels further in
        for aa, inward in ((a0 + 6, 1), (a1 - 6, -1)):
            p, q = P(aa, b1, 1.5), P(aa, b1, T - 1.5)
            for k in (0, 2):
                x = math.floor(p[0]) + 0.5 + inward * k
                d.paint(Mask(d.W, d.H).line([(x, p[1]), (x, q[1])], 0.9).get() & fr, title_mat)
        if title:
            mx, my = P(0, b1, T / 2 + 2.5)
            g = type_at(d, title, int(round(mx)), int(round(my)), "35")
            d.paint(on_plane(g, int(mx), L * ca, L * sa * VIEW) & fr, title_mat)
    else:
        pages(fr, across(frontp[0], frontp[1], frontp[3]), T, 5)
    if under is not None:
        # the edge between this book and the ones below: inked; its shadow a step down on what shows below it
        ring = np.zeros_like(allm)
        ring[1:, :] |= allm[:-1, :]; ring[:-1, :] |= allm[1:, :]; ring[:, 1:] |= allm[:, :-1]; ring[:, :-1] |= allm[:, 1:]
        ring &= under & ~allm
        sh = np.zeros_like(allm)
        for k in (2, 3):
            sh[k:, :] |= allm[:-k, :]
        sh[:, 1:] |= sh[:, :-1].copy()                                     # the light from up and a little left
        sh &= under & ~allm & ~ring
        d.dark[sh] += 2 / 7.0
        tone(ring, "p", 0)
    return top, fr, en, allm, frontp, P


@mine(136, 92)
def worm_of_books(d):
    # three hardbacks stacked flat, each turned its own way so the stack sits plainly askew: the two below with their
    # spines toward us and their titles, the top one with its page edges toward us; the top cover's stamped rule in its
    # own plane; the top book's pale ribbon marker out from between its pages and hanging down over the spines below
    X = d.XX + 0.5; Y = d.YY + 0.5
    base = 82
    b1m = book(d, 64, base, 104, 66, 15, math.radians(-6.0), front="spine", cover="m", title="FIRST AID",
               title_mat="p")[3]
    b2m = book(d, 70, base - 15, 96, 62, 15, math.radians(8.0), front="spine", cover="d", title="WESTERNS",
               title_mat="pw", under=b1m)[3]
    L3, W3, T3, a3, c3, y3 = 88, 58, 13, math.radians(-13.0), 63, base - 30
    top, fr, en, b3m, fp, P = book(d, c3, y3, L3, W3, T3, a3, front="pages", cover="k", under=b1m | b2m)
    # the stamped rule round the top cover, laid in the cover's plane (a line across the depth is 1/VIEW thick there)
    ca, sa = math.cos(a3), math.sin(a3)
    z = (Y + T3 - y3) / VIEW
    A = (X - c3) * ca + z * sa; B = -(X - c3) * sa + z * ca
    ia, ib = L3 / 2 - 6, W3 / 2 - 6 / VIEW * 0.45
    rule = ((np.abs(np.abs(A) - ia) < 0.6) & (np.abs(B) <= ib)) | ((np.abs(np.abs(B) - ib) < 0.6 / VIEW) & (np.abs(A) <= ia))
    rule &= top
    d.mat[rule] = d.mid("m"); d.dark[rule] = 0.52 - 3 / 7.0
    # the ribbon: out from between the top book's pages, down the spines below, its tail cut in a V
    (rx0, ry0) = P(20, W3 / 2, T3 / 2)
    yb = base + 7
    rib = Mask(d.W, d.H).poly([(rx0 - 2, ry0), (rx0 + 2, ry0), (rx0 + 2.6, yb), (rx0 + 0.3, yb - 3), (rx0 - 2, yb + 0.5)]).get()
    d.h[rib] = 0; d.mat[rib] = d.mid("l"); d.solid |= rib; d.polish[rib] = 0; d.tex[rib] = 0
    d.flatlight |= rib; d.noshadow |= rib; d.dark[rib] = 0.52 - 6 / 7.0
    edge = rib & ~Mask(d.W, d.H).poly([(rx0 - 1, ry0), (rx0 + 1, ry0), (rx0 + 1.6, yb - 1), (rx0 - 1, yb - 1)]).get()
    d.dark[edge & (Y > ry0 + 1)] = 0.52 - 3 / 7.0
    d.dark[Mask(d.W, d.H).line([(rx0 - 2, ry0 + 0.5), (rx0 + 2, ry0 + 0.5)], 1).get() & rib] = 0.52 - 2 / 7.0


if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    os.makedirs("px", exist_ok=True)
    names = sys.argv[1:] or MINE
    for n in names:
        if n not in MINE: sys.exit("not this batch's picture: " + n)
        im = render(n)
        im.save(os.path.join("px", n + ".png"))
        print(n, im.size)
