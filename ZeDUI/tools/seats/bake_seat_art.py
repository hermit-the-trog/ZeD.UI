"""
Bake the seat chooser's art (ZeD-UI, Oct 15 2026; mockup zed_seats_lightbar_v1.html).

A seat seen from above (cushion with bolsters, backrest, headrest), a crash test
dummy sitting in it (the quartered calibration target on its head, bolted
shoulders and knees, segmented arms) and a pile of junk (a plank, a box, a bag),
each as white alpha masks the game tints when it draws them:

  zs_seat_fill   the seat's silhouette (fill; also the step shadow, offset)
  zs_seat_line   its outline and seams (painter's order: the backrest covers the
                 cushion's back edge)
  zs_seat_dash   the dashed outline of a seat that is not fitted
  zs_seat_stip   diagonal stipple inside the silhouette (a seat out of reach)
  zs_dummy_fill  the dummy's body       zs_dummy_light  the target's white disc
  zs_dummy_ink   its outlines, bolts and the target's black quarters
  zs_junk_fill   the junk's bodies      zs_junk_ink     their outlines and seams

Geometry is the mockup's SVG, in a 42 x 58 unit box (x -1..41, y -1..57). Each
layer is baked at 1, 2 and 3 px per unit (suffix _1x, _2x, _3x); the game picks
the smallest that is at least as fine as the screen needs. Shapes are drawn in
the SVG's order: a later shape's fill hides earlier outlines under it.

Usage:  py ZeDUI/tools/seats/bake_seat_art.py
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = os.path.join(ROOT, "42", "media", "textures", "ZeD", "seats")
BOX_W, BOX_H, ORG = 42, 58, -1     # the unit box (the SVG viewBox "-1 -1 42 58")
SS = 8                             # supersampling


class Canvas:
    def __init__(self, ppu):
        self.ppu = ppu
        self.s = ppu * SS
        self.W, self.H = BOX_W * self.s, BOX_H * self.s

    def p(self, x, y):
        return ((x - ORG) * self.s, (y - ORG) * self.s)

    def blank(self):
        return np.zeros((self.H, self.W), dtype=np.float32)

    def poly_mask(self, pts):
        im = Image.new("L", (self.W, self.H), 0)
        ImageDraw.Draw(im).polygon([self.p(*q) for q in pts], fill=255)
        return np.asarray(im, dtype=np.float32) / 255.0

    def line_mask(self, pts, width, closed=False):
        im = Image.new("L", (self.W, self.H), 0)
        q = [self.p(*a) for a in pts]
        if closed:
            q = q + [q[0], q[1]]
        ImageDraw.Draw(im).line(q, fill=255, width=max(1, int(round(width * self.s))), joint="curve")
        return np.asarray(im, dtype=np.float32) / 255.0

    def disc_mask(self, cx, cy, r):
        im = Image.new("L", (self.W, self.H), 0)
        x0, y0 = self.p(cx - r, cy - r)
        x1, y1 = self.p(cx + r, cy + r)
        ImageDraw.Draw(im).ellipse([x0, y0, x1, y1], fill=255)
        return np.asarray(im, dtype=np.float32) / 255.0

    def save(self, arr, name):
        a = np.clip(arr, 0, 1)
        im = Image.fromarray((a * 255).astype(np.uint8), "L")
        im = im.resize((BOX_W * self.ppu, BOX_H * self.ppu), Image.BOX)
        rgba = Image.new("RGBA", im.size, (255, 255, 255, 0))
        rgba.putalpha(im)
        rgba.save(os.path.join(OUT, "%s_%dx.png" % (name, self.ppu)), optimize=True)


# ---- geometry helpers (unit space) ----
def quad(p0, c, p1, n=10):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p1[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p1[1]) for t in [i / n for i in range(1, n + 1)]]


def rrect(x, y, w, h, r, n=8):
    r = min(r, w / 2, h / 2)
    pts = []
    for cx, cy, a0 in ((x + w - r, y + r, -90), (x + w - r, y + h - r, 0), (x + r, y + h - r, 90), (x + r, y + r, 180)):
        for i in range(n + 1):
            a = math.radians(a0 + 90 * i / n)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def rotate(pts, deg, cx, cy):
    a = math.radians(deg)
    ca, sa = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * ca - (y - cy) * sa, cy + (x - cx) * sa + (y - cy) * ca) for x, y in pts]


def circle(cx, cy, r, n=48):
    return [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n)) for i in range(n)]


# the seat: cushion "M7 3 H33 Q36 3 36 7 V33 H4 V7 Q4 3 7 3 Z", backrest
# "M4 32 H36 Q38 32 38 35 V43 Q38 47 34 47 H6 Q2 47 2 43 V35 Q2 32 4 32 Z", headrest rect
CUSHION = [(7, 3), (33, 3)] + quad((33, 3), (36, 3), (36, 7)) + [(36, 33), (4, 33), (4, 7)] + quad((4, 7), (4, 3), (7, 3))
BACKREST = ([(4, 32), (36, 32)] + quad((36, 32), (38, 32), (38, 35)) + [(38, 43)] + quad((38, 43), (38, 47), (34, 47))
            + [(6, 47)] + quad((6, 47), (2, 47), (2, 43)) + [(2, 35)] + quad((2, 35), (2, 32), (4, 32)))
HEADREST = rrect(13, 47, 14, 6, 2)
SEAT = [CUSHION, BACKREST, HEADREST]
SEAMS = [((10, 7), (10, 32)), ((30, 7), (30, 32)), ((8, 39.5), (32, 39.5))]


def dash_path(pts, on=3.0, off=2.0):
    """split a closed polyline into dash segments (unit lengths)"""
    pts = pts + [pts[0]]
    segs, cur, left, drawing = [], [pts[0]], on, True
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        L = math.hypot(x1 - x0, y1 - y0)
        pos = 0.0
        while L - pos > 1e-6:
            step = min(left, L - pos)
            pos += step
            t = pos / L
            pt = (x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)
            if drawing:
                cur.append(pt)
            left -= step
            if left <= 1e-6:
                if drawing and len(cur) > 1:
                    segs.append(cur)
                drawing = not drawing
                left = on if drawing else off
                cur = [pt]
    if drawing and len(cur) > 1:
        segs.append(cur)
    return segs


def bake(ppu):
    c = Canvas(ppu)
    # --- the seat ---
    fill, line = c.blank(), c.blank()
    for shape in SEAT:
        inside = c.poly_mask(shape)
        fill = np.maximum(fill, inside)
        line = np.maximum(line * (1 - inside), c.line_mask(shape, 1.0, closed=True))
    seams = c.blank()
    for a, b in SEAMS:
        seams = np.maximum(seams, c.line_mask([a, b], 1.0))
    line = np.maximum(line, seams * 0.55)
    c.save(fill, "zs_seat_fill")
    c.save(line, "zs_seat_line")
    dash = c.blank()
    for shape in SEAT:
        for seg in dash_path(shape):
            dash = np.maximum(dash, c.line_mask(seg, 1.0))
    c.save(dash, "zs_seat_dash")
    # stipple: 1-unit lines every 4 units at 45 degrees, inside the silhouette
    yy, xx = np.mgrid[0:c.H, 0:c.W].astype(np.float32) / c.s
    period = 4.0 * math.sqrt(2)
    stripe = (np.mod(xx + yy, period) < math.sqrt(2)).astype(np.float32)
    c.save(stripe * fill, "zs_seat_stip")

    # --- the crash test dummy ---
    body, ink, light = c.blank(), c.blank(), c.blank()

    def paint(pts):
        nonlocal body, ink
        inside = c.poly_mask(pts)
        body = np.maximum(body, inside)
        ink = np.maximum(ink * (1 - inside), c.line_mask(pts, 1.0, closed=True))

    for r in ((11.5, 16, 7, 16, 2), (21.5, 16, 7, 16, 2)):
        paint(rrect(*r))
    for cx, cy in ((15, 15.5), (25, 15.5)):
        paint(circle(cx, cy, 3.4))
    for r in ((5, 20, 6, 9, 2), (5, 30, 6, 9, 2), (29, 20, 6, 9, 2), (29, 30, 6, 9, 2)):
        paint(rrect(*r))
    paint(rrect(6, 31.5, 28, 11, 4))
    paint(circle(20, 37, 7.2))
    for cx, cy in ((9.5, 37), (30.5, 37), (15, 15.5), (25, 15.5)):
        ink = np.maximum(ink, c.disc_mask(cx, cy, 1.1))
    disc = c.disc_mask(20, 37, 4.3)
    light = disc
    ink = ink * (1 - disc)
    ring = np.clip(c.disc_mask(20, 37, 4.3 + 0.45) - c.disc_mask(20, 37, 4.3 - 0.45), 0, 1)
    ink = np.maximum(ink, ring)
    tl = [(20, 37)] + [(20 + 4.3 * math.cos(math.radians(a)), 37 + 4.3 * math.sin(math.radians(a))) for a in range(180, 271, 5)]
    br = [(20, 37)] + [(20 + 4.3 * math.cos(math.radians(a)), 37 + 4.3 * math.sin(math.radians(a))) for a in range(0, 91, 5)]
    ink = np.maximum(ink, np.maximum(c.poly_mask(tl), c.poly_mask(br)))
    c.save(body, "zs_dummy_fill")
    c.save(light, "zs_dummy_light")
    c.save(ink, "zs_dummy_ink")

    # --- the junk: a plank, a box, a bag ---
    jf, ji = c.blank(), c.blank()

    def jpaint(pts):
        nonlocal jf, ji
        inside = c.poly_mask(pts)
        jf = np.maximum(jf, inside)
        ji = np.maximum(ji * (1 - inside), c.line_mask(pts, 1.0, closed=True))

    jpaint(rotate(rrect(5, 37, 32, 4.5, 1), -24, 21, 39))
    box = [(7.5, 8), (24.5, 8), (24.5, 24), (7.5, 24)]
    jpaint(rotate(box, -10, 16, 16))
    ji = np.maximum(ji, c.line_mask(rotate([(16, 8), (16, 24)], -10, 16, 16), 1.0))
    ji = np.maximum(ji, c.line_mask(rotate([(12, 15), (20, 15)], -10, 16, 16), 1.0) * 0.6)
    jpaint(rotate(rrect(17.5, 21, 17, 11, 4.5), 12, 26, 27))
    ji = np.maximum(ji, c.line_mask(rotate([(20.5, 24), (31.5, 24)], 12, 26, 27), 1.0))
    handle = [(22.5, 21)] + quad((22.5, 21), (26, 16.5), (29.5, 21))
    ji = np.maximum(ji, c.line_mask(rotate(handle, 12, 26, 27), 1.0))
    c.save(jf, "zs_junk_fill")
    c.save(ji, "zs_junk_ink")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for ppu in (1, 2, 3):
        bake(ppu)
    print("baked to", OUT, sorted(os.listdir(OUT)))
