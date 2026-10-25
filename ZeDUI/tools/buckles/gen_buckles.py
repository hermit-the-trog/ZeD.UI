#!/usr/bin/env python3
"""ZeD profession belt buckles (gen_buckles.py) — 58x40 native (ZeD_Belt BUCKLE_W 58, BUCKLE_H 40), one texel per design unit.
Field of a rect plate: x 5..51, y 5..33; emblem zone x 6..50, y 5..26; ribbon rows 28..34. Centre column x=28
(mask coords: pixel x spans [x, x+1), so the centre line is 28.5)."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from engine import *

C = 28.5     # centre line in mask coordinates


# ------------------------------------------------------------------ geometry helpers
def star_pts(cx, cy, R, r, n=5, rot=-90):
    pts = []
    for k in range(2 * n):
        rad = R if k % 2 == 0 else r; a = math.radians(rot) + k * math.pi / n
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    return pts


def mirror(pts, cx=C):
    return [(2 * cx - x, y) for x, y in pts]


def tube(pts, widths, m=None):
    """a tapered stroke along a polyline: circles stamped along each segment"""
    m = m or M()
    for i in range(len(pts) - 1):
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]; w0, w1 = widths[i], widths[i + 1]
        steps = max(2, int(math.hypot(x1 - x0, y1 - y0) * 4))
        for t in np.linspace(0, 1, steps):
            x, y, r = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, (w0 + (w1 - w0) * t) / 2
            m.ellipse(x, y, r, r)
    return m


def local(origin, u, pts):
    """local (s along u, t across u) -> global"""
    ux, uy = u; l = math.hypot(ux, uy); ux, uy = ux / l, uy / l; vx, vy = -uy, ux
    ox, oy = origin
    return [(ox + s * ux + t * vx, oy + s * uy + t * vy) for s, t in pts]


def rect_plate(metal, corner="chamfer", **kw):
    return Buckle(metal).plate(shape_rect(corner, 4 if corner == "chamfer" else 5), **kw)



# ------------------------------------------------------------------ pixel masks and small type
def rows_mask(rows, ox, oy, ch="#"):
    m = np.zeros((H, W), bool)
    for r, row in enumerate(rows):
        for c, k in enumerate(row):
            if k in ch and 0 <= ox + c < W and 0 <= oy + r < H: m[oy + r, ox + c] = True
    return m


# ------------------------------------------------------------------ metal and plate shape per profession
PLATES = {
    "farmer":             ("pewter",    lambda: shape_rect("chamfer", 4), {}),
    "policeofficer":      ("brass",     shape_shield, {}),
    "burglar":            ("gold",      shape_oval, {"stipple": 0.12}),
    "unemployed":         ("brass",     lambda: shape_rect("round", 5), {}),
    "fireofficer":        ("brass",     shape_concave, {}),
    "parkranger":         ("pewter",    shape_arch, {}),
    "constructionworker": ("steel",     shape_hex, {}),
    "securityguard":      ("silver",    shape_round, {}),
    "carpenter":          ("copper",    lambda: shape_rect("square"), {}),
    "chef":               ("silver",    shape_octagon, {}),
    "repairman":          ("brass",     lambda: shape_rect("round", 5), {}),
    "fisherman":          ("bronze",    shape_oval, {"beads": False, "rope": True, "stipple": 0.12}),
    "doctor":             ("goldplate", shape_octagon, {}),
    "veteran":            ("brass",     lambda: shape_rect("chamfer", 4), {}),
    "nurse":              ("pewter",    shape_cushion, {}),
    "lumberjack":         ("iron",      shape_concave, {}),
    "fitnessinstructor":  ("silver",    lambda: shape_rect("round", 4), {"rim": 2, "beads": False, "stipple": 0}),
    "burgerflipper":      ("goldplate", lambda: shape_rect("round", 5), {}),
    "electrician":        ("copper",    shape_octagon, {}),
    "engineer":           ("steel",     lambda: shape_rect("square"), {}),
    "metalworker":        ("steel",     lambda: shape_rect("square"), {}),
    "mechanics":          ("iron",      shape_concave, {}),
    "smither":            ("iron",      lambda: shape_rect("chamfer", 4), {}),
    "tailor":             ("silver",    shape_cushion, {}),
    "rancher":            ("silver",    shape_oval, {"beads": False, "rope": True}),
}
RIBBON_METAL = {"lumberjack": "brass", "mechanics": "brass", "smither": "brass"}   # applied brass scrolls on black iron


def make_plate(name):
    metal, shp, kw = PLATES[name]
    b = Buckle(metal).plate(shp(), **kw)
    b.ribbon_metal = RIBBON_METAL.get(name)
    return b


# ================================================================== the set
def farmer():
    b = make_plate("farmer")
    b.relief(M().rect(6, 26, 45, 1), height=0.6, bevel=1)                                           # ground
    fence = M()
    for x in (7, 11): fence.rect(x, 19, 1, 7)
    fence.rect(6, 21, 10, 1)
    b.relief(fence, height=0.8, bevel=1)
    barn = M().poly([(14, 17), (17, 11), (24.5, 7), (32, 11), (35, 17)]).rect(16, 16, 18, 10)
    b.relief(barn, height=1.7, bevel=1.6)
    b.cut(M().rect(20, 18, 9, 1).rect(20, 18, 1, 8).rect(28, 18, 1, 8), 0.6)                      # door frame
    b.cut(M().line([(21, 19), (27.5, 25)], 1).line([(27.5, 19), (21, 25)], 1), 0.45)               # X brace
    b.cut(M().rect(23, 11, 3, 3), 0.7)                                                               # hay loft
    b.cut(M().line([(16.5, 15.5), (32.5, 15.5)], 1), 0.35)                                           # eave
    b.cylinder(38, 10, 8, 16, height=2.0)                                                            # silo
    b.dome(42, 10.5, 4, 3.2, height=2.2, on=FIELD_H + 0.4)
    for y in (14, 18, 22): b.relief(M().rect(38, y, 8, 1).get(), height=0.25, bevel=1, on="current", flat=True)
    b.ribbon("FARMER")
    return b


def police():
    b = make_plate("policeofficer")
    chief = M().rect(10, 5, 38, 7).get() & b.field
    b.relief(chief, height=1.6, bevel=1.0, polish=1.0)
    b.cut(text_mask("POLICE", 28 - text_w("POLICE") // 2, 6), 0.45)
    b.relief(M().poly(star_pts(C, 23.5, 10.5, 4.3)), height=2.2, pyramid=True, polish=1.0)
    b.dome(C, 23.5, 2.2, 2.2, height=0.7, on="current")
    return b


def burglar():
    b = make_plate("burglar")
    b.relief(M().ellipse(C, 16.5, 9, 7), height=1.4, bevel=1.2, polish=1.0)                         # bezel
    ring = M().ellipse(C, 16.5, 9, 7).get() & ~M().ellipse(C, 16.5, 7, 5).get()
    for y, x in zip(*np.nonzero(ring)):
        if (x + y) % 2 == 0: b.h[y, x] += 0.45
    b.dome(C, 16.5, 6.2, 4.6, height=2.0, on=FIELD_H + 0.9, mat="turq")                             # the stone
    b.cut(M().line([(25, 14), (27, 15.5), (29, 15), (31, 17.5)], 1).get() & M().ellipse(C, 16.5, 6, 4.4).get(), 0.25, patina=False)
    rays = M()                                                                                       # short bright-cut rays
    for a in range(0, 360, 24):
        if 45 <= a <= 135: continue
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        rays.line([(C + 11.5 * ca, 16.5 + 9 * sa), (C + 17.5 * ca, 17.5 + 12.5 * sa)], 0.8)
    b.cut(rays.get(0.5) & b.field & ~M().ellipse(C, 16.5, 9.5, 7.5).get(), 0.14, patina=False)
    word = "CHAMP"; tw = text_w(word); px0 = 28 - (tw + 5) // 2
    plaque = M(); plaque.d.rounded_rectangle([px0 * SS, 25 * SS, (px0 + tw + 5) * SS - 1, 32 * SS - 1], radius=2 * SS, fill=255)
    b.relief(plaque, height=1.5, bevel=1.0, polish=1.0)
    b.cut(text_mask(word, px0 + 3, 26), 0.45)
    return b

KY_LONLAT = [(-89.42, 36.50), (-89.13, 36.98), (-88.70, 37.08), (-88.47, 37.07), (-88.08, 37.47), (-88.03, 37.80),
             (-87.59, 37.84), (-87.11, 37.77), (-86.52, 38.04), (-86.03, 37.99), (-85.76, 38.25), (-85.42, 38.53),
             (-85.17, 38.69), (-84.80, 38.79), (-84.82, 39.10), (-84.51, 39.10), (-83.83, 38.66), (-83.30, 38.62),
             (-82.99, 38.73), (-82.60, 38.47), (-82.59, 38.17), (-82.30, 37.68), (-81.97, 37.54), (-82.35, 37.27),
             (-82.72, 37.04), (-83.12, 36.77), (-83.68, 36.60), (-85.00, 36.62), (-86.50, 36.64), (-88.07, 36.68),
             (-88.07, 36.50)]


def ky_poly(x0, x1, ytop):
    lons = [p[0] for p in KY_LONLAT]; lats = [p[1] for p in KY_LONLAT]
    lo0, lo1, la1 = min(lons), max(lons), max(lats)
    sx = (x1 - x0) / (lo1 - lo0); sy = sx / math.cos(math.radians(37.5))
    return [(x0 + (lo - lo0) * sx, ytop + (la1 - la) * sy) for lo, la in KY_LONLAT]


def unemployed():
    b = make_plate("unemployed")
    b.relief(M().poly(ky_poly(9, 48, 7)), height=1.8, bevel=1.8, polish=1.0)
    b.ribbon("KENTUCKY", pad=2)
    return b


def axe_head(origin, u, flip=1):
    """felling axe head at the top of a handle; blade on the +t side when flip=1"""
    return local(origin, u, [(-1.6, -2.5 * flip), (1.6, -2.5 * flip), (1.8, 2.5 * flip), (3.6, 6.5 * flip), (-3.6, 6.5 * flip), (-1.8, 2.5 * flip)])


def fireoff():
    b = make_plate("fireofficer")
    hyd = FIELD_H + 0.4
    b.relief(M().rect(7, 26, 43, 1), height=0.5, bevel=1)                                           # pavement
    b.cylinder(22, 25, 13, 2, height=1.2, axis="h", on=hyd)                                          # base flange
    for x in (23, 33): b.dome(x + 0.5, 25.5, 0.8, 0.8, height=0.5, on="current")
    b.cylinder(23, 12, 11, 13, height=2.2, on=hyd)                                                   # barrel
    b.cylinder(21, 11, 15, 2, height=1.0, axis="h", on=hyd + 1.4)                                    # top flange
    b.dome(C, 10.8, 6.4, 4.6, height=2.5, on=hyd)                                                    # bonnet
    b.relief(M().rect(27, 4.5, 3, 3), height=2.8, bevel=1, on=hyd)                                   # operating nut
    for sgn in (-1, 1):                                                                              # stubby side nozzles with caps
        b.cylinder(20 if sgn < 0 else 34, 15, 3, 5, height=1.6, axis="h", on=hyd + 0.3)
        b.cylinder(17 if sgn < 0 else 37, 14, 3, 7, height=2.0, on=hyd + 0.3)
        b.relief(M().rect(17 if sgn < 0 else 37, 17, 3, 1).get(), height=0.3, bevel=1, on="current", flat=True)
    b.dome(C, 19.5, 3.4, 3.4, height=1.4, on="current")                                             # pumper cap
    b.relief(M().rect(27, 18, 3, 3), height=0.45, bevel=1, on="current", flat=True)
    b.cut(M().rect(23, 23, 11, 1).get(), 0.25)
    b.ribbon("FIRE DEPT", style="red", letters="brass", pad=3)
    return b

def pine(m, cx, top, tiers, w0, dw, dy):
    for i in range(tiers):
        y = top + i * dy; w = w0 + i * dw
        m.poly([(cx, y), (cx - w, y + dy + 3), (cx + w, y + dy + 3)])
    return m


def parkranger():
    b = make_plate("parkranger")
    ridge = M().poly([(6, 22), (12, 15), (16, 18), (22, 12), (28, 17), (34, 11), (40, 16), (45, 13), (51, 19), (51, 26), (6, 26)])
    b.relief(ridge, height=0.55, bevel=1.4, polish=0.3)
    for cx, top, tiers, w0, dw, dy, hgt in ((13.5, 12, 3, 2.0, 1.4, 3.3, 1.5), (43.5, 12, 3, 2.0, 1.4, 3.3, 1.5), (C, 5, 4, 2.4, 1.8, 4.0, 1.9)):
        m = pine(M(), cx, top, tiers, w0, dw, dy)
        b.relief(m, height=hgt, bevel=1.5, on=FIELD_H + 0.3)
        for i in range(1, tiers):                                                                     # bough breaks
            y = top + i * dy + 2.6; w = w0 + (i - 1) * dw
            b.cut(M().line([(cx - w + 0.6, y), (cx + w - 0.6, y)], 0.8).get(0.5) & m.get(), 0.35)
        tx = int(cx); b.relief(M().rect(tx - 1 if cx == C else tx - 1, top + tiers * dy + 2, 3 if cx == C else 2, 2), height=1.0, bevel=1, on=FIELD_H + 0.3)
    b.relief(M().rect(6, 26, 45, 1), height=0.5, bevel=1)
    b.ribbon("RANGER")
    return b


def constructionworker():
    b = make_plate("constructionworker")
    # a hard hat, three-quarter front: ribbed dome over a brim whose peak dips toward us
    hb = FIELD_H + 0.3
    yy = np.mgrid[0:H, 0:W][0]
    brim = M().poly([(15, 19.2), (17.5, 18), (39.5, 18), (42, 19.2), (40.5, 21), (35, 23.6), (28.5, 25.6), (22, 23.6), (16.5, 21)]).get()
    b.relief(brim, height=1.5, bevel=1.6, on=hb, polish=1.0)
    dome = M().ellipse(C, 20, 11.5, 14).get() & (yy < 20)
    b.relief(dome, height=2.4, bevel=4.2, on=hb + 0.5, polish=0.95)
    for dx in (-4.5, 4.5):                                                                           # side ribs
        b.relief(M().arc(C + dx * 0.15, 20, abs(dx) + 0.6, 13.4, 200 if dx < 0 else 270, 270 if dx < 0 else 340, 1.2).get(0.5) & dome, height=0.45, bevel=1, on="current", flat=True, polish=1.0)
    b.relief(M().rect(27, 6.5, 3, 13).get() & dome, height=0.5, bevel=1, on="current", flat=True, polish=1.0)   # centre rib
    b.ribbon("LOCAL 189")
    return b

def securityguard():
    b = make_plate("securityguard")
    b.relief(M().poly(star_pts(C, 16.5, 11, 4.5)), height=2.2, pyramid=True, polish=1.0)
    b.dome(C, 16.5, 2.2, 2.2, height=0.7, on="current")
    b.ribbon("SECURITY", y=27)
    return b


def carpenter():
    b = make_plate("carpenter")
    pb = FIELD_H + 0.2
    # the cast body: sole along the bottom, the cheek rising in a long low curve, nose and heel rounded off
    body = M().poly([(7.5, 25), (49.5, 25), (49.5, 22.2), (47.0, 20.2), (40, 19.0), (16, 19.0), (10.0, 20.2), (7.5, 22.2)])
    b.relief(body, height=1.6, bevel=1.2, on=pb, mat="iron", polish=0.9)
    b.cut(M().rect(9, 23, 40, 1).get(), 0.25, patina=False)                                               # the sole's edge
    # the knob up front: a turned mushroom on a short neck
    b.relief(M().rect(12, 16, 4, 4), height=1.3, bevel=1.0, on=pb + 0.6)
    b.dome(14, 13.2, 3.4, 3.6, height=2.0, on=pb + 0.6, polish=0.9)
    b.cut(M().rect(11, 16, 6, 1).get(), 0.25)
    # the frog: lever cap and iron bedded at 45 degrees, leaning back toward the tote
    u = (1.0, -1.25)
    cap = M().poly(local((24.5, 19.5), u, [(0, -2.6), (14.0, -2.4), (14.0, 2.4), (0, 2.6)]))
    b.relief(cap, height=1.7, bevel=1.1, on=pb + 0.4, mat="steel", polish=1.0)
    iron = M().poly(local((24.5, 19.5), u, [(13.0, -1.8), (16.5, -1.8), (16.5, 1.4), (13.0, 1.4)]))
    b.relief(iron, height=1.3, bevel=1.0, on=pb + 0.4, mat="steel", polish=0.8)
    b.cut(M().line(local((24.5, 19.5), u, [(7.5, -1.2), (7.5, 1.2)]), 0.8).get(0.45), 0.35)             # the cap's lever
    b.dome(*local((24.5, 19.5), u, [(4.5, 0)])[0], 1.0, 1.0, height=0.6, on="current", polish=1.0)    # the cap screw
    # depth adjuster wheel behind the frog
    b.dome(33.5, 17.6, 1.7, 1.7, height=1.2, on=pb + 1.0, mat="brass", polish=1.0)
    # the tote: a pistol grip raked back, the front edge hollowed for the fingers, a horn curling forward on top
    tote = M().poly([(38.0, 20.5), (45.8, 20.5), (47.2, 16.0), (48.6, 11.0), (49.6, 8.0), (48.8, 6.0), (46.6, 5.4),
                     (44.2, 6.0), (43.0, 7.4), (44.4, 8.8), (43.8, 11.2), (42.4, 13.8), (41.4, 16.4), (40.6, 18.6)]).get()
    b.relief(tote, height=1.9, bevel=1.4, on=pb + 0.6, polish=0.85)
    b.dome(43.6, 18.6, 0.9, 0.9, height=0.4, on="current", polish=1.0)                                    # the tote bolt
    b.ribbon("CARPENTER", pad=2)
    return b


def chef():
    b = make_plate("chef")
    # toque: three puffs over a pleated band
    tq = M().ellipse(21.5, 11.5, 5, 4.6).ellipse(35.5, 11.5, 5, 4.6).ellipse(C, 9.5, 6.4, 5.2).ellipse(C, 13.5, 10.5, 4.5)
    b.relief(tq, height=2.0, bevel=2.6, on=FIELD_H + 0.4)
    band = M().rect(20, 16, 17, 10)
    b.cylinder(20, 16, 17, 10, height=1.8, on=FIELD_H + 0.4)
    for x in (23, 26, 31, 34): b.cut(M().rect(x, 17, 1, 9), 0.25)
    b.relief(M().rect(20, 16, 17, 2), height=0.3, bevel=1, on="current", flat=True)
    b.cut(M().rect(20, 18, 17, 1), 0.25)
    # fork, left
    fk = M()
    for x in (9, 11, 13): fk.rect(x, 6, 1, 6)
    fk.poly([(8.6, 11), (14.4, 11), (13, 15), (10, 15)]).rect(10.5, 14, 2, 12)
    b.relief(fk, height=1.4, bevel=1.0)
    # chef's knife, right: point up, edge on the right, bolster, riveted handle
    kn = M().poly([(46, 4.5), (48, 9), (48, 17), (44, 17), (44, 10)])
    b.relief(kn, height=1.2, bevel=1.0, polish=1.0)
    b.relief(M().rect(43.5, 17, 5, 2), height=1.5, bevel=1)
    b.cylinder(44, 19, 4, 7, height=1.5)
    b.cut(pix((46, 21), (46, 24)), 0.3)
    b.ribbon("CHEF")
    return b


def repairman():
    b = make_plate("repairman")
    sd = FIELD_H + 0.2
    # claw hammer leaning left out of the tray
    b.relief(tube([(19.5, 14), (15.5, 7.5)], [2.4, 2.4]), height=1.3, bevel=1, on=sd, polish=0.8)
    head = M().poly(local((15.2, 7.2), (-4, -6.5), [(-1.8, -4.6), (1.8, -4.6), (1.8, 3.0), (-1.8, 3.0)]))
    b.relief(head, height=1.9, bevel=1.0, on=sd + 0.2, polish=1.0)
    claw = tube(local((15.2, 7.2), (-4, -6.5), [(0, 3.0), (-0.6, 5.0), (-2.0, 6.4)]), [3.0, 2.2, 1.2]).get()
    b.relief(claw, height=1.6, bevel=1.0, on=sd + 0.2, polish=1.0)
    # wrench leaning right out of the tray
    b.relief(tube([(37.5, 14.5), (40.6, 7.4)], [2.6, 2.6]), height=1.3, bevel=1, on=sd, polish=1.0)
    jaw = M().ellipse(41.2, 5.6, 3.8, 3.4).get() & ~M().poly([(41.4, 5.8), (44.6, 0.8), (46.4, 2.6)]).get()
    b.relief(jaw, height=1.5, bevel=1, on=sd, polish=1.0)
    b.relief(M().rect(23, 7, 11, 2).rect(23, 7, 2, 7).rect(32, 7, 2, 7), height=1.4, bevel=1.0, on=FIELD_H + 0.3)     # carry handle
    bx = FIELD_H + 0.5
    b.relief(M().rect(10, 13, 37, 13), height=1.9, bevel=1.4, on=bx, mat="red", polish=0.9)          # red enamel box
    b.relief(M().rect(9, 13, 39, 3), height=2.3, bevel=1.0, on=bx, mat="red", polish=1.0)            # lid lip
    b.cut(M().rect(10, 16, 37, 1), 0.4)
    b.relief(M().rect(26, 15, 5, 4), height=2.4, bevel=1.0, on=bx, polish=1.0)                       # brass latch
    b.cut(pix((28, 17)), 0.4)
    for x in (12, 44): b.dome(x + 0.5, 23.5, 0.9, 0.9, height=0.4, on="current", mat="brass")
    b.ribbon("FIX IT")
    return b

BASS = {   # largemouth bass in profile, head at +s; units are pixels, origin mid-body
    "body": [(-13, -1.6), (-8, -4.2), (-2, -6.2), (4, -6.6), (9, -5.6), (12.5, -3.6), (15.5, -1.4), (13.4, 0.6), (16.4, 2.4),
             (13, 4.6), (8, 5.8), (2, 6.2), (-4, 5.2), (-9, 3.2), (-13, 1.6)],
    "tail": [(-12, -1.4), (-18, -6.2), (-16.6, 0), (-18, 6.2), (-12, 1.4)],
    "spiny": [(-4, -5.4), (-3, -10), (-1, -8.6), (0.5, -10.2), (2, -8.6), (3.5, -9.6), (5, -6.4)],
    "soft": [(-11, -2.6), (-9, -7.6), (-5.5, -5.2)],
    "anal": [(-8, 3.6), (-6, 8.2), (-3, 5.4)],
    "pelvic": [(2, 5.8), (3.5, 9), (5.5, 5.8)],
}


def fisherman():
    b = make_plate("fisherman")
    org = (27.5, 15.5); u = (math.cos(math.radians(-14)), math.sin(math.radians(-14)))
    P = lambda key: local(org, u, BASS[key])
    fb = FIELD_H + 0.2
    for key, hgt in (("tail", 1.2), ("spiny", 1.0), ("soft", 1.0), ("anal", 1.0), ("pelvic", 1.0)):
        b.relief(M().poly(P(key)), height=hgt, bevel=0.9, on=fb, polish=0.6)
    body = M().poly(P("body")).get()
    b.relief(body, height=2.2, bevel=2.4, on=fb + 0.1, polish=0.9)
    spiny = M().poly(P("spiny")).get()
    for s0 in (-2.5, -0.5, 1.5, 3.5):                                                                # fin rays
        b.cut(M().line(local(org, u, [(s0, -6.4), (s0 + 0.3, -9)]), 0.6).get(0.45) & spiny, 0.2)
    b.cut(M().line(local(org, u, [(-12, 0.2), (-6, -0.6), (0, 0.4), (6, -0.8)]), 0.9).get(0.45) & body, 0.35)   # dark lateral band
    b.cut(M().line(local(org, u, [(9.4, -4.2), (8.4, 0), (9.4, 4)]), 0.7).get(0.45) & body, 0.4)     # gill cover
    e = local(org, u, [(12, -2.4)])[0]
    b.dome(e[0], e[1], 1.3, 1.2, height=0.6, on="current", polish=1.0); b.cut(pix((int(e[0]), int(e[1]))), 0.45)
    mouth = local(org, u, [(15.6, -0.6), (12.6, 0.8), (15.6, 1.8)])
    b.cut(M().poly(mouth), 0.6)
    tip = local(org, u, [(14.2, 0.8)])[0]                                                            # the line, to the lure in its jaw
    b.relief(M().line([(15, 5.4), (24, 6.2), (tip[0], tip[1])], 0.7).get(0.35), height=0.4, bevel=1, flat=True, polish=1.0)
    for (x, y, rx) in ((10.5, 26.4, 1.0), (13.5, 25.2, 0.8), (40, 24.6, 0.8), (43, 25.8, 1.0)):     # splash
        b.dome(x, y, rx, rx, height=0.7, polish=1.0)
    b.relief(M().arc(27, 26.5, 13, 1.4, 180, 360, 1.0), height=0.5, bevel=1)
    b.ribbon("ANGLER")
    return b

SERIF_M = [
    "####.....####",
    ".###.....###.",
    ".####...####.",
    ".##.##.##.##.",
    ".##.##.##.##.",
    ".##..###..##.",
    ".##..###..##.",
    ".##...#...##.",
    ".##.......##.",
    ".##.......##.",
    ".##.......##.",
    "####.....####",
]
SERIF_D = [
    "########...",
    ".##....##..",
    ".##.....##.",
    ".##.....##.",
    ".##.....###",
    ".##.....###",
    ".##.....###",
    ".##.....###",
    ".##.....##.",
    ".##.....##.",
    ".##....##..",
    "########...",
]


def doctor():
    b = make_plate("doctor")
    eb = FIELD_H + 0.2
    # the staff, its ball finial and the wings spread from just under the ball
    b.relief(M().rect(28, 7, 1, 25), height=1.2, bevel=1, on=eb, polish=1.0)
    b.dome(C, 6.0, 1.6, 1.6, height=1.4, on=eb, polish=1.0)
    lw = [(27.6, 9.0), (24, 7.6), (20, 6.4), (15.5, 5.6), (13.0, 6.0), (15.0, 7.2), (13.4, 8.0), (16.4, 8.8),
          (15.4, 9.8), (19.0, 10.2), (18.6, 11.2), (22.6, 11.2), (27.6, 12.4)]
    wings = M().poly(lw).poly(mirror(lw))
    b.relief(wings, height=1.3, bevel=1.2, on=eb, polish=0.95)
    wm = wings.get()
    for sgn in (-1, 1):
        for (x1, y1) in ((15.8, 7.4), (16.4, 9.2), (19.4, 10.6)):
            x0, y0 = 25.0, 9.6
            xs = lambda x: C + sgn * (C - x)
            b.cut(M().line([(xs(x0 + (x1 - x0) * 0.4), y0 + (y1 - y0) * 0.4), (xs(x1), y1)], 0.55).get(0.45) & wm, 0.3)
    # two snakes twining up the staff, crossing at every turn, heads facing each other under the wings
    sn = M()
    for sgn in (-1, 1):
        pts = [(C + sgn * 2.6 * math.sin((y - 13.5) / 3.6 * math.pi) * (1.0 - (y - 13) / 40), y) for y in np.linspace(14.5, 29.5, 40)]
        sn = tube(pts, [1.25] * len(pts), sn)
        sn = tube([(C + sgn * 2.0, 14.6), (C + sgn * 2.6, 13.2), (C + sgn * 1.4, 12.6)], [1.6, 1.8, 1.2], sn)
    b.relief(sn, height=1.0, bevel=1.0, on=eb + 0.4, polish=1.0)
    # the letters, raised and buffed
    m = rows_mask(SERIF_M, 9, 15)
    d = rows_mask(SERIF_D, 37, 15)
    b.relief(m | d, height=1.6, bevel=1.0, on=eb, polish=1.0)
    return b


def veteran():
    b = make_plate("veteran")
    eb = FIELD_H + 0.2
    # wings displayed and raised, built feather by feather: each a tapered quill from the shoulder out to its tip,
    # laid lowest first so every feather above overlaps the one below and the overlaps read as clean steps
    tips = [(15.0, 19.8), (11.0, 17.6), (8.2, 14.6), (7.0, 11.0), (8.0, 7.6), (10.6, 4.6)]
    roots = [(23.6, 19.0), (23.0, 17.6), (22.6, 16.2), (22.6, 14.8), (23.0, 13.6), (24.4, 12.6)]
    wm = np.zeros((H, W), bool)
    owner = np.full((H, W), -1, np.int16)
    for i, (tp, rt) in enumerate(zip(tips, roots)):
        for sgn in (1, -1):
            pts = [rt, tp] if sgn > 0 else mirror([rt, tp])
            f = tube(pts, [3.4, 2.2]).get()
            b.relief(f, height=1.25, bevel=1.0, on=eb + 0.12 * i, polish=1.0)
            wm |= f; owner[f] = i
    # a dark seam where each feather tucks under the next one up
    up = np.full((H, W), -1, np.int16)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        up = np.maximum(up, np.roll(np.roll(owner, dy, 0), dx, 1))
    b.cut((owner >= 0) & (up > owner), 0.45)
    # the coverts: a smooth shoulder over the quill roots, its lower edge scalloped
    for sgn in (1, -1):
        cov = [(25.6, 12.4), (22.0, 11.4), (18.6, 11.0), (16.6, 12.6), (16.4, 14.6), (17.8, 16.6), (20.4, 18.0), (25.6, 18.6)]
        b.relief(M().poly(cov if sgn > 0 else mirror(cov)), height=1.45, bevel=1.4, on=eb + 0.5, polish=1.0)
    # the tail fanned under the shield
    tail = M().poly([(26.0, 22.0), (31.0, 22.0), (33.4, 26.6), (23.6, 26.6)])
    b.relief(tail, height=1.4, bevel=1.0, on=eb, polish=0.9)
    for x in (26.6, 30.4): b.cut(M().line([(x, 23.4), (C + (x - C) * 2.0, 26.0)], 0.5).get(0.5), 0.3)
    # olive branch in the right talon (viewer's left), arrows in the left
    b.relief(tube([(24.0, 21.8), (21.0, 23.4), (17.6, 24.0)], [1, 1, 1]), height=0.8, bevel=1, on=eb)
    for (x, y, a) in ((20.0, 22.4, -2.6), (17.8, 22.9, -2.9), (19.4, 25.0, 2.6)):
        b.relief(M().poly(leaf(x, y, a, L=1.5, Wd=0.85)), height=0.9, bevel=1, on=eb + 0.1, polish=0.9)
    for dy in (0.0, 1.6):
        b.relief(M().line([(33.0, 21.6 + dy * 0.3), (39.6, 22.8 + dy)], 0.7).get(0.5), height=0.7, bevel=1, on=eb, flat=True, polish=1.0)
    b.relief(pix((39, 21), (40, 22), (39, 25), (40, 25)), height=0.6, bevel=1, on=eb, flat=True)        # arrowheads
    # the white head turned to its right (viewer's left), hooked brass beak, a gap above it for the plate to show
    neck = M().poly([(25.6, 14.0), (31.4, 14.0), (31.0, 11.0), (26.0, 11.0)]).get()
    b.relief(neck, height=1.8, bevel=1.2, on=eb + 0.5, polish=0.9)
    head = M().ellipse(C, 9.2, 3.0, 2.8).get() | neck & (np.mgrid[0:H, 0:W][0] < 12)
    b.relief(head, height=2.0, bevel=1.3, on=eb + 0.8, polish=1.0)
    b.paint(head, "white")
    beak = M().poly([(26.0, 8.6), (23.2, 9.4), (23.4, 10.8), (24.4, 10.4), (26.0, 10.8)]).get() & ~head
    b.relief(beak, height=2.2, bevel=1.0, on=eb + 0.8, mat="goldplate", polish=1.0)
    b.cut(pix((27, 8)), 0.5)
    # the shield on the breast: blue chief with three stars, red and white pales, pointed foot
    shield = M().poly([(24, 13.5), (33, 13.5), (33, 19), (28.5, 22.6), (24, 19)])
    sm = shield.get()
    b.relief(sm, height=1.3, bevel=1.0, on=eb + 0.6, polish=1.0, flat=True)
    yy, xx = np.mgrid[0:H, 0:W]
    b.paint(sm, "white")
    chief = sm & (yy < 16)
    b.paint(chief, "blue")
    b.paint(sm & ~chief & (xx % 2 == 0), "red")
    b.paint(pix((26, 14), (28, 14), (30, 14)), "white")
    b.ribbon("VETERAN")
    return b


def leaf(cx, cy, ang, L=2.6, Wd=1.3):
    return [(cx + L * math.cos(t) * math.cos(ang) - Wd * math.sin(t) * math.sin(ang),
             cy + L * math.cos(t) * math.sin(ang) + Wd * math.sin(t) * math.cos(ang)) for t in np.linspace(0, 2 * math.pi, 14)]


def laurel(b, sgn, base=(None, 25)):
    stem = [(C + sgn * 8.5, 25.5), (C + sgn * 13.5, 23), (C + sgn * 16.5, 18), (C + sgn * 17, 12), (C + sgn * 15.5, 6.5)]
    b.relief(tube(stem, [1, 1, 1, 1, 1]), height=0.7, bevel=1)
    pts = []
    for i in range(len(stem) - 1):
        (x0, y0), (x1, y1) = stem[i], stem[i + 1]
        for t in (0.25, 0.75): pts.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, math.atan2(y1 - y0, x1 - x0)))
    for k, (x, y, a) in enumerate(pts):
        side = 1 if k % 2 else -1
        nx, ny = -math.sin(a) * side, math.cos(a) * side
        b.relief(M().poly(leaf(x + nx * 1.6, y + ny * 1.6, a + side * 0.6)), height=1.0, bevel=1.0, on=FIELD_H + 0.1, polish=0.9)


def nurse():
    b = make_plate("nurse")
    cross = M().rect(24.5, 4.5, 8, 22).rect(17.5, 11.5, 22, 8)
    b.relief(cross, height=2.2, pyramid=True, on=FIELD_H + 0.4, polish=1.0)
    b.ribbon("RN", style="red", letters="pewter")
    return b

def lumberjack():
    b = make_plate("lumberjack")
    for sgn in (-1, 1):
        top = (C + sgn * 13.5, 8.5); bot = (C - sgn * 12, 24)
        u = (top[0] - bot[0], top[1] - bot[1])
        b.relief(tube([bot, top], [2.8, 2.6]), height=1.3, bevel=1.0, on=FIELD_H + 0.1)
        head = M().poly(local(top, u, [(-1.9, -2.8 * sgn), (1.9, -2.8 * sgn), (2.1, 2.5 * sgn), (4.2, 7.0 * sgn), (-4.2, 7.0 * sgn), (-2.1, 2.5 * sgn)]))
        b.relief(head, height=1.6, bevel=1.1, on=FIELD_H + 0.3, polish=1.0)
        edge = local(top, u, [(-4.0, 6.6 * sgn), (4.0, 6.6 * sgn)])
        b.relief(M().line(edge, 0.8).get(0.4), height=0.25, bevel=1, on="current", flat=True, polish=1.0)
    # the log across the bottom, end grain to the left
    lg = FIELD_H + 0.6
    b.cylinder(10, 20, 38, 7, height=1.9, axis="h", on=lg)
    for (x, y, w) in ((15, 22, 4), (22, 24, 5), (31, 21, 4), (39, 24, 4), (43, 22, 3)):
        b.cut(M().rect(x, y, w, 1), 0.3)
    b.relief(M().ellipse(10.5, 23.5, 3, 3.6), height=2.0, bevel=1.2, on=lg, polish=0.4)
    b.cut(M().ellipse(10.5, 23.5, 1.8, 2.3).get() & ~M().ellipse(10.5, 23.5, 1.0, 1.4).get(), 0.25)
    b.ribbon("TIMBER")
    return b


BOLD = {
    "B": ["#####.", "##..##", "##..##", "#####.", "##..##", "##..##", "##..##", "#####."],
    "O": [".####.", "##..##", "##..##", "##..##", "##..##", "##..##", "##..##", ".####."],
    "D": ["#####.", "##..##", "##..##", "##..##", "##..##", "##..##", "##..##", "#####."],
    "Y": ["##..##", "##..##", "##..##", ".####.", "..##..", "..##..", "..##..", "..##.."],
    "C": [".#####", "##....", "##....", "##....", "##....", "##....", "##....", ".#####"],
    "H": ["##..##", "##..##", "##..##", "######", "##..##", "##..##", "##..##", "##..##"],
    "I": ["##", "##", "##", "##", "##", "##", "##", "##"],
    "S": [".#####", "##....", "##....", ".####.", "....##", "....##", "....##", "#####."],
    "E": ["#####", "##...", "##...", "####.", "##...", "##...", "##...", "#####"],
    "L": ["##...", "##...", "##...", "##...", "##...", "##...", "##...", "#####"],
}


def bold_w(t): return sum(len(BOLD[c][0]) + 1 for c in t) - 1


def bold_mask(t, x, y):
    m = np.zeros((H, W), bool); cx = x
    for c in t:
        m |= rows_mask(BOLD[c], cx, y); cx += len(BOLD[c][0]) + 1
    return m


def small_text(t, x, y, space=1):
    m = np.zeros((H, W), bool); cx = x
    for c in t:
        if c == " ": cx += space; continue
        m |= text_mask(c, cx, y); cx += len(FONT[c][0]) + 1
    return m


def small_w(t, space=1): return sum(space if c == " " else len(FONT[c][0]) + 1 for c in t) - 1


def fitnessinstructor():
    b = make_plate("fitnessinstructor")
    field = b.field.copy()
    b.paint(field, "black")                                                                            # black enamel sign
    lh = FIELD_H + 0.2
    top = bold_mask("BODY", 29 - bold_w("BODY") // 2 - 1, 6)
    mid = bold_mask("CHISEL", 29 - bold_w("CHISEL") // 2 - 1, 15)
    letters = top | mid
    b.relief(letters, height=1.1, bevel=0.8, on=lh, mat="white", polish=1.0, flat=True)
    yy, xx = np.mgrid[0:H, 0:W]
    def span(m): c = np.nonzero(m.any(0))[0]; return (xx >= c.min()) & (xx <= c.max())
    stripe = (((yy == 10) & span(top)) | ((yy == 19) & span(mid))) & field
    b.paint(stripe & letters, "red")
    b.relief(stripe & ~letters, height=0.25, bevel=1, on=FIELD_H, mat="red", polish=0.6, flat=True)
    # the chisel stroke cutting in at the top left
    bx = np.nonzero(top.any(0))[0].min()
    b.relief(M().line([(bx - 4.2, 4.2), (bx - 0.6, 7.2)], 0.9).get(0.45) & field, height=1.1, bevel=1, on=lh, mat="white", flat=True)
    tag = "GYM & FITNESS"
    tw = small_w(tag, space=0)                       # 46 px: the sign's field is 49, so the spaces go
    b.relief(small_text(tag, 28 - tw // 2, 26, space=0), height=0.6, bevel=1, on=FIELD_H, mat="silver", flat=True, polish=1.0)
    return b


def burgerflipper():
    b = make_plate("burgerflipper")
    word = "BEST FLIPPER"; tw = text_w(word); px0 = 28 - tw // 2 - 2
    plaque = M(); plaque.d.rounded_rectangle([px0 * SS, 4 * SS, (px0 + tw + 4) * SS - 1, 11 * SS - 1], radius=1.5 * SS, fill=255)
    b.relief(plaque, height=1.6, bevel=1.0, polish=1.0)
    b.cut(text_mask(word, 28 - tw // 2, 5), 0.45)
    bb = FIELD_H + 0.3
    yy = np.mgrid[0:H, 0:W][0]
    crown = M().ellipse(C, 17.5, 11, 5.6).get() & (yy < 18) & (yy >= 12)
    b.relief(crown, height=2.1, bevel=2.8, on=bb, polish=1.0)
    for (x, y) in ((23, 13), (28, 12.6), (33, 13), (25.5, 15), (30.5, 15)):                         # sesame seeds
        b.relief(pix((int(x), int(y)), (int(x) + 1, int(y))), height=0.35, bevel=1, on="current", flat=True, polish=1.0)
    lettuce = M().poly([(17, 18)] + [(17 + k, 19.4 + 0.7 * math.sin(k * 1.4)) for k in range(0, 24)] + [(40, 18)])
    b.relief(lettuce, height=1.3, bevel=1.0, on=bb)
    b.cylinder(18, 19.5, 22, 3, height=1.6, axis="h", on=bb)                                          # patty
    b.relief(M().poly([(21, 19.4), (23, 19.4), (22, 21.2)]).poly([(33, 19.4), (35, 19.4), (34, 21.6)]), height=1.7, bevel=1, on=bb, polish=1.0)   # cheese drips
    heel = M(); heel.d.rounded_rectangle([18 * SS, 22.6 * SS, 40 * SS - 1, 26.4 * SS - 1], radius=1.8 * SS, fill=255)
    b.relief(heel, height=1.8, bevel=1.4, on=bb)
    b.cut(M().rect(18, 22, 22, 1).get(), 0.3)
    b.ribbon("SPIFFOS '91", style="red", letters="goldplate", pad=2, tail_len=3)
    return b



def bolt_pts(cx, cy, ang, sc):
    a = math.radians(ang); ca, sa = math.cos(a), math.sin(a)
    return [(cx + sc * (x * ca - y * sa), cy + sc * (x * sa + y * ca)) for x, y in BOLT]


def fist(b, x, y, arm="down", arm_len=10):
    """front-on fist, knuckles up; (x, y) = top-left of the finger columns. 15 wide x 15 tall."""
    fa = FIELD_H + 1.0
    if arm == "down":
        a = M(); a.d.rounded_rectangle([(x + 2.1) * SS, (y + 11.6) * SS, (x + 12.1) * SS - 1, (y + 11.6 + arm_len) * SS - 1], radius=1.5 * SS, fill=255)
        b.relief(a, height=1.7, bevel=2.2, on=fa, polish=0.8)
    elif arm == "downright":
        b.relief(M().poly([(x + 6, y + 12), (x + 14.5, y + 10), (x + 20, y + 22), (x + 11, y + 23)]), height=1.7, bevel=2.2, on=fa, polish=0.8)
    palm = M(); palm.d.rounded_rectangle([x * SS, (y + 3.6) * SS, (x + 14.6) * SS - 1, (y + 14.6) * SS - 1], radius=3 * SS, fill=255)
    b.relief(palm, height=1.8, bevel=2.0, on=fa, polish=0.9)
    for x0 in (0, 3.8, 7.6, 11.4):
        f = M(); f.d.rounded_rectangle([(x + x0) * SS, y * SS, (x + x0 + 3.4) * SS - 1, (y + 9.2) * SS - 1], radius=1.7 * SS, fill=255)
        b.relief(f, height=1.7, bevel=1.2, on=fa + 0.6, polish=1.0)
    for dx in (3.6, 7.4, 11.2): b.cut(M().rect(int(x + dx), int(y + 1.1), 1, 7.5).get(), 0.7)
    # the thumb folds across the index finger and stops at about the middle finger
    th = tube([(x - 0.6, y + 10.6), (x + 2.4, y + 9.0), (x + 5.0, y + 8.3), (x + 6.4, y + 8.4)], [4.4, 3.8, 3.2, 2.6]).get()
    b.relief(th, height=1.5, bevel=1.2, on=fa + 1.4, polish=1.0)
    b.cut(M().line([(x + 4.6, y + 7.4), (x + 6.2, y + 7.5)], 0.6).get(0.4) & th, 0.25)               # thumbnail
    b.cut(M().line([(x + 0.4, y + 12.2), (x + 6.4, y + 10.6)], 0.6).get(0.45), 0.35)                # shadow under the thumb


STAND = [(29.5, 4.5), (39.5, 4.5), (32.5, 12.6), (38.5, 12.6), (20.5, 28), (25.6, 17.4), (19, 17.4)]


# palm-side raised fist, authored pixel by pixel. #=hand  c=crease  T=thumb  n=thumbnail  w=wrist  .=empty
FIST = [
    "...##..##..##..##.",
    "..################",
    "..####c###c###c###",
    "..####c###c###c###",
    "..####c###c###c###",
    ".TTTTTTTTTc###c###",
    "TTTTTTTTnTc###c###",
    "TTTTTTTTT#cccccccc",
    ".TTTTTTT##########",
    "..################",
    "...##############.",
    "....############..",
]

def sprite_masks(rows, ox, oy):
    ms = {}
    for r, row in enumerate(rows):
        for c, ch in enumerate(row):
            if ch == ".": continue
            ms.setdefault(ch, np.zeros((H, W), bool))[oy + r, ox + c] = True
    return ms

def fist3(b, ox, oy, arm_len=11, arm_w=(5, 14), sleeve=True):
    fa = FIELD_H + 1.0
    ms = sprite_masks(FIST, ox, oy)
    allm = np.zeros((H, W), bool)
    for m in ms.values(): allm |= m
    # forearm first, under the fist
    x0, x1 = ox + arm_w[0], ox + arm_w[1]
    arm = M().poly([(x0, oy + 11), (x1 + 1, oy + 11), (x1 + 2, oy + 11 + arm_len), (x0 - 1, oy + 11 + arm_len)]).get()   # forearm, widening toward the elbow
    b.relief(arm, height=1.6, bevel=2.2, on=fa - 0.1, polish=0.75)
    if sleeve:
        b.relief(M().rect(x0 - 1, oy + 18, x1 - x0 + 3, arm_len - 7).get(), height=1.9, bevel=1.2, on=fa - 0.1, polish=0.55)
        b.cut(M().rect(x0 - 1, oy + 19, x1 - x0 + 3, 1).get(), 0.3)
    b.relief(allm, height=1.9, bevel=1.4, on=fa, polish=0.95)                                        # the hand as one mass
    thumb = ms.get("T", 0) | ms.get("n", 0)
    b.relief(thumb, height=0.9, bevel=1.0, on="current", polish=1.0)                                 # thumb stands proud of the fingers
    b.cut(ms["c"], 0.55)                                                                              # creases stop inside the hand
    if "n" in ms: b.cut(ms["n"], 0.25, patina=False)

def electrician():
    b = make_plate("electrician")
    pts = [(px + 8, py + 0.5) for px, py in STAND]
    b.relief(M().poly(pts), height=2.0, bevel=1.0, on=FIELD_H + 0.2, polish=1.0)
    fist3(b, 11, 6, sleeve=False)                                                                      # raised fist closing on the bolt's edge
    b.ribbon("LOCAL 369")
    return b

def gear(b, cx, cy, r, teeth, tooth_h, height, on, bore, tw=1.4):
    m = M().ellipse(cx, cy, r, r)
    for k in range(teeth):
        a = 2 * math.pi * k / teeth + math.pi / teeth
        m.poly(local((cx, cy), (math.cos(a), math.sin(a)), [(r - 1, -tw), (r + tooth_h, -tw), (r + tooth_h, tw), (r - 1, tw)]))
    b.relief(m, height=height, bevel=1.2, on=on, polish=0.95)
    if bore: b.cut(M().ellipse(cx, cy, bore, bore), 0.8)
    return m

def engineer():
    b = make_plate("engineer")
    gear(b, 38.5, 19, 5.6, 9, 2.2, 1.6, FIELD_H + 0.2, 0, tw=1.25)
    b.dome(38.5, 19, 2.2, 2.2, height=0.7, on="current", polish=1.0); b.cut(pix((38, 18), (38, 19)), 0.6)
    gear(b, 22.5, 14.5, 8.0, 12, 2.4, 1.9, FIELD_H + 0.6, 0, tw=1.3)
    b.dome(22.5, 14.5, 3.4, 3.4, height=1.1, on="current", polish=1.0)                                 # boss
    b.cut(M().ellipse(22.5, 14.5, 1.2, 1.2), 0.9)                                                      # bore
    for k in range(4):                                                                                  # spokes between boss and rim
        a = math.pi / 4 + k * math.pi / 2
        b.cut(M().ellipse(22.5 + 5.6 * math.cos(a), 14.5 + 5.6 * math.sin(a), 0.9, 0.9), 0.35)
    b.ribbon("ENGINEER")
    return b

def metalworker():
    b = make_plate("metalworker")
    sh = FIELD_H + 0.3
    shell = M().ellipse(C, 14, 10.5, 9.5).poly([(19, 15), (38, 15), (35, 24), (31, 26.5), (26, 26.5), (22, 24)])   # hood
    b.relief(shell, height=2.1, bevel=3.0, on=sh, polish=0.85)
    b.relief(M().rect(20, 9, 17, 8), height=0.8, bevel=1, on="current", flat=True)                   # lens frame
    b.relief(M().rect(21, 10, 15, 6).get(), height=0.2, bevel=1, on=sh + 2.4, mat="black", flat=True, polish=1.0)
    b.lock[(22, 10)] = 7; b.lock[(23, 10)] = 6; b.lock[(22, 11)] = 6
    for sgn in (-1, 1): b.dome(C + sgn * 10.5, 14.5, 1.6, 1.6, height=2.2, on=sh, polish=1.0)        # headgear pivots
    sh = sh
    b.relief(M().poly(star_pts(44.5, 21.5, 5.2, 1.3, n=4, rot=-90)), height=1.4, pyramid=True, polish=1.0)   # the arc
    b.relief(M().poly(star_pts(44.5, 21.5, 3.4, 0.9, n=4, rot=-45)), height=1.0, pyramid=True, polish=1.0)
    for (x, y) in ((39, 25), (48, 17), (49, 25), (40, 17)): b.relief(pix((x, y)), height=0.7, bevel=1, flat=True, polish=1.0)
    b.ribbon("LOCAL 110")
    return b

def wrench(b, p_open, p_tail, on, hand=1):
    ux, uy = p_open[0] - p_tail[0], p_open[1] - p_tail[1]; L = math.hypot(ux, uy); ux, uy = ux / L, uy / L
    a = math.radians(15 * hand); jx, jy = ux * math.cos(a) - uy * math.sin(a), ux * math.sin(a) + uy * math.cos(a)
    neck = (p_open[0] - ux * 3.2, p_open[1] - uy * 3.2)
    b.relief(tube([p_tail, neck], [2.6, 2.8]), height=1.2, bevel=1.0, on=on, polish=1.0)
    b.relief(M().line([p_tail, neck], 0.7).get(0.5), height=0.25, bevel=1, on="current", flat=True, polish=1.0)   # centre rib
    head = M().ellipse(p_open[0], p_open[1], 4.4, 4.4).get() | tube([neck, p_open], [3.0, 5.0]).get()
    mouth = M().poly(local(p_open, (jx, jy), [(-0.2, -1.55), (6.0, -1.9), (6.0, 1.9), (-0.2, 1.55)])).get() | M().ellipse(p_open[0] - jx * 0.2, p_open[1] - jy * 0.2, 1.55, 1.55).get()
    b.relief(head & ~mouth, height=1.7, bevel=1.1, on=on, polish=1.0)
    b.dome(p_tail[0], p_tail[1], 1.5, 1.5, height=1.2, on=on, polish=0.9)

def mechanics():
    b = make_plate("mechanics")
    wrench(b, (40.5, 8.5), (15.5, 25), FIELD_H + 0.1, hand=1)
    wrench(b, (16.5, 8.5), (41.5, 25), FIELD_H + 0.8, hand=-1)
    b.ribbon("GARAGE")
    return b


def smither():
    b = make_plate("smither")
    av = FIELD_H + 0.3
    body = M().poly([(6, 14.5), (15, 13), (44, 13), (44, 18), (37, 19), (34, 21), (22, 21), (19, 19), (15, 17.5)])
    b.relief(body, height=2.1, bevel=1.6, on=av, polish=0.9)
    b.relief(M().rect(15, 13, 29, 1), height=0.3, bevel=1, on="current", flat=True, polish=1.0)       # the face, polished
    foot = M().poly([(20, 21), (36, 21), (40, 26), (16, 26)])
    b.relief(foot, height=1.7, bevel=1.3, on=av)
    b.cut(M().rect(39, 14, 1, 2), 0.4)                                                                 # hardy hole
    # hammer above, mid-swing: head and handle
    hm = FIELD_H + 0.3
    b.relief(tube([(44.5, 4.0), (34, 10.5)], [2.4, 2.4]), height=1.2, bevel=1.0, on=hm)
    head = M().poly(local((34, 10), (10.5, -6.5), [(-2.2, -4.8), (2.2, -4.8), (2.5, 4.8), (-2.5, 4.8)]))
    b.relief(head, height=1.8, bevel=1.1, on=hm, polish=1.0)
    for (x, y) in ((26, 9), (24, 11), (27, 6), (22, 8)):                                               # sparks off the face
        b.relief(pix((x, y)), height=0.6, bevel=1, flat=True, polish=1.0)
    b.ribbon("FORGE")
    return b


def tailor(k=0.86):
    """drawn at full size, then scaled by k about the base's bottom centre so the machine sits smaller on the plate"""
    b = make_plate("tailor")
    mb = FIELD_H + 0.2
    ox, oy = C, 26.0
    def P(pts): return [(ox + (x - ox) * k, oy + (y - oy) * k) for x, y in pts]
    def R(x, y, w, h): return M().poly(P([(x, y), (x + w, y), (x + w, y + h), (x, y + h)]))
    def E(cx, cy, rx, ry): (px, py), = P([(cx, cy)]); return M().ellipse(px, py, rx * k, ry * k)
    # the wooden-look base and the bed plate
    b.relief(R(7, 23, 43, 3), height=1.4, bevel=1.0, on=mb, polish=0.5)
    bed = R(9, 20, 39, 3).get()
    b.relief(bed, height=1.5, bevel=1.0, on=mb + 0.4, mat="black", polish=1.0)
    # the arm: a flared pillar at the right, the arm arching over (higher at the pillar), the head dropping at the left
    arm = M().poly(P([(35.0, 20), (45.0, 20), (44.0, 15), (44.0, 10.4), (42.4, 7.0), (38.4, 5.6), (30, 5.6), (22, 6.2),
                      (17.0, 6.8), (12.6, 7.4), (12.4, 16.8), (17.8, 16.8), (18.4, 11.6), (24, 10.2), (31, 10.0),
                      (35.6, 11.2), (37.6, 13.6), (37.2, 17.0)])).get()
    b.relief(arm, height=2.0, bevel=1.6, on=mb + 0.4, mat="black", polish=1.0)
    # gold decal lines along the arm, like a Singer's
    b.paint(M().line(P([(21, 8.4), (36, 8.2), (40, 9.6)]), 0.7).get(0.45) & arm, "goldplate")
    b.paint(M().line(P([(40.5, 14), (41.5, 15.2), (40.5, 16.4)]), 0.7).get(0.45) & arm, "goldplate")
    # needle bar and presser foot under the head
    b.relief(R(14, 17, 2, 3), height=1.0, bevel=1.0, on=mb + 0.6, mat="silver", polish=1.0)
    b.relief(R(12.6, 19.2, 4.4, 1.0).get(0.3), height=0.8, bevel=1, on=mb + 0.9, mat="silver", flat=True)
    # the handwheel at the right end, and the spool on its pin on top of the arm
    wheel = E(46.0, 12.5, 4.4, 4.8).get()
    b.relief(wheel, height=1.8, bevel=1.4, on=mb + 0.8, mat="silver", polish=1.0)
    (wx, wy), = P([(46.0, 12.5)])
    b.cut(M().ellipse(wx, wy, 2.6, 2.8).get() & ~M().ellipse(wx, wy, 1.6, 1.8).get(), 0.35)              # the rim's groove
    b.dome(wx, wy, 1.0, 1.0, height=0.6, on="current", mat="silver", polish=1.0)
    (sx, sy), = P([(31.5, 5.6)])
    b.relief(M().rect(round(sx) - 1, round(sy) - 2, 1, 2), height=1.0, bevel=1, on=mb + 0.6, mat="silver", flat=True)
    b.cylinder(round(sx) - 3, round(sy) - 3, 5, 2, height=1.2, on=mb + 1.4, mat="red", polish=0.7)              # the spool
    b.ribbon("TAILOR")
    return b


def rancher():
    b = make_plate("rancher")
    sk = FIELD_H + 0.3
    for sgn in (-1, 1):                                                                                # horns
        pts = [(C + sgn * 5, 13), (C + sgn * 10, 13.2), (C + sgn * 14, 12.6), (C + sgn * 16.6, 11.2), (C + sgn * 17.4, 8.8)]
        b.relief(tube(pts, [4.2, 3.4, 2.6, 1.9, 1.0]), height=1.9, bevel=1.4, on=sk, polish=1.0)
        for x in (C + sgn * 8.5, C + sgn * 12): b.cut(M().line([(x, 11.6), (x + sgn * 0.6, 14.4)], 0.6).get(0.45), 0.2)
    skull = M().ellipse(C, 14, 6.4, 5.5).poly([(22.5, 14), (34.5, 14), (33, 20), (31.5, 25.5), (25.5, 25.5), (24, 20)])
    b.relief(skull, height=2.2, bevel=2.2, on=sk + 0.4, polish=0.9)
    for sgn in (-1, 1): b.cut(M().ellipse(C + sgn * 3.5, 15.5, 1.6, 1.8), 0.7)
    b.cut(pix((27, 23), (30, 23)), 0.5)
    b.cut(M().line([(C, 18.5), (C, 21)], 0.8).get(0.5), 0.2)
    b.ribbon("RANCH")
    return b


SET = [
    ("farmer", farmer), ("policeofficer", police), ("burglar", burglar), ("unemployed", unemployed), ("fireofficer", fireoff),
    ("parkranger", parkranger), ("constructionworker", constructionworker), ("securityguard", securityguard),
    ("carpenter", carpenter), ("chef", chef), ("repairman", repairman), ("fisherman", fisherman), ("doctor", doctor),
    ("veteran", veteran), ("nurse", nurse), ("lumberjack", lumberjack), ("fitnessinstructor", fitnessinstructor),
    ("burgerflipper", burgerflipper), ("electrician", electrician), ("engineer", engineer), ("metalworker", metalworker),
    ("mechanics", mechanics), ("smither", smither), ("tailor", tailor), ("rancher", rancher),
]

if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser(description="Render the profession buckles (58x40 PNGs).")
    ap.add_argument("--to", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "out"), help="output folder")
    ap.add_argument("only", nargs="*", help="profession ids to render (default: all)")
    args = ap.parse_args()
    os.makedirs(args.to, exist_ok=True)
    for name, fn in SET:
        if args.only and name not in args.only: continue
        fn().render().save(os.path.join(args.to, f"buckle_{name}.png"))
    print("wrote", args.to)
