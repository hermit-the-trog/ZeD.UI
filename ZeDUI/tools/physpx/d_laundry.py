"""The laundry machines (director, Oct 30 2026: "Washer and dryer I trust you. Do those so we can ship that too.";
redrawn Nov 2 2026 on his word: "the scale seems off compared to in-game, ours is wider than it should be", the clothes
"a thorough rebuild to look realistic, pixel arty, with some depth and lighting", or the drum filled with soapy water):
three faces for the game's three laundry objects, full card, at every width the machine plates come in (336, 392,
450, 562) and the narrow face for a card under 336.

  washer   IsoClothingWasher           Premium Technologies top-loader: needs power and water
  dryer    IsoClothingDryer            Premium Technologies dryer, the washer's pair: needs power
  combo    IsoCombinationWasherDryer   ValuTech compact washer-dryer: power; water in its washer mode

Drawn from the game's laundry model (appliances_laundry_P1_00: white enamel, a blue plastic control panel, a chrome-ringed
glass door), at the model's proportions: its front is 0.786 m wide and 0.895 m tall, so each face is a little taller
than it is wide. The card keys a face by the width it fills (the slot: 336 .. 562); the face itself is narrower and the
card centres it, as a machine stands in a room. Below a slot of 300 the panel is the narrow one.

What the game lets you do with them is small, and the faces offer exactly that, nothing for show that a player would try
to turn: power on and off (the game's toggle; the washer and the combination in its washer mode refuse without water),
the combination's WASH / DRY mode, and the door, which opens the machine's contents. What they show: the power lamp
(green running, red no power), the water meter, the phase lamps of a running cycle (WASH RINSE SPIN, DRY COOL), FILL
when the washer has no water, and behind the glass:
  - the clothes when there are any (the `clothes` picture): a heap of real garments, each cloth draped over the ones
    under it, folded, shaded and shadowed by the plate's light (jeans with their stitching, a flannel shirt, a T-shirt
    and its collar, a sweater sleeve's ribbed cuff, socks; towels and sweats in the dryer)
  - the water, in five pictures (`water1` .. `water5`, the game's fluid against capacity): soapy water from the bottom
    up, a head of foam along the top, suds and bubbles in it. It draws over the clothes, so a low fill shows the heap's
    top above the foam and a full one is all suds.

Live state (state() below): running, noPower, noWater, water 0..5, hasItems, modeWash / modeDry (the combination),
phWash / phRinse / phSpin / phDry / phCool (the phase lamps: Code steps them through a running cycle by the clock;
the game has no phases of its own), drumF 0..1 (the drum's baffle, turned by the clock while running), cycleF."""
import math

import numpy as np
from scipy import ndimage as ndi

from physlib import *            # noqa: F401,F403
from engine import add_ramp, edt
import wear as WR
import d_props as PR
import m_brands as MB

add_ramp("lb_blue", "#4f74a8", light=1.05)       # the model's blue panel
add_ramp("lb_blue_dk", "#2f4a74")
add_ramp("lb_white", "#e9e7e0", light=1.06)      # the model's white enamel
add_ramp("lb_grey", "#b9bcc0", light=1.06)       # the combination's light grey panel
add_ramp("lb_console", "#2d3036", light=1.18)    # the washer's and dryer's backsplash console
add_ramp("lb_ink_dim", "#6c717a")               # an unlit legend on the console
add_ramp("drum", "#5d6268", light=1.1)           # the steel drum behind the glass
add_ramp("water_lo", "#3a6ea8")
# the laundry: everyday 1993 clothing colours, matte
for _nm, _hx in {"cl_denim": "#3d5c8a", "cl_stitch": "#c98d3e", "cl_red": "#a6352d", "cl_red_dk": "#5c1916",
                 "cl_cream": "#d9cdae", "cl_white": "#dcdad1", "cl_khaki": "#ae9457", "cl_green": "#57724b",
                 "cl_grey": "#8b8e92", "cl_navy": "#2f3c60", "cl_teal": "#3e8787", "cl_yellow": "#c9a33f",
                 "cl_rose": "#b46f7c", "cl_red_xx": "#3a0f0d"}.items():
    add_ramp(_nm, _hx)
CLOTH_RAMPS = ("cl_denim", "cl_stitch", "cl_red", "cl_red_dk", "cl_cream", "cl_white", "cl_khaki", "cl_green", "cl_grey",
               "cl_navy", "cl_teal", "cl_yellow", "cl_rose", "cl_red_xx")
add_ramp("cl_white", "#dcdad1", dark=0.50)       # (again, softer: white cloth never shades to black)
add_ramp("cl_grey", "#8b8e92", dark=0.36)
add_ramp("cl_cream", "#d9cdae", dark=0.45)
add_ramp("suds", "#8fb1c8", light=1.12)          # soapy wash water: milky blue
add_ramp("foam", "#e7ecef", light=1.04, dark=0.58)   # the head of foam and the bubbles (soft, bluish shadows)

NARROW = 300
ASPECT = 0.786 / 0.895        # the model's front: width over height
TAU = 2 * math.pi


def _geom(W):
    """the slot W the card fills -> (narrow, face width, face height)"""
    narrow = W < NARROW
    H = 214 if narrow else int(round(W * 0.78))
    return narrow, int(round(H * ASPECT)), H


def body(p, W, H, case="lb_white"):
    d = p.d
    case_m = Mask(W, H).rrect(0, 0, W, H, 6).get()
    d.slab(case_m, Z_FACE, case, bevel=2.6, polish=0.55)
    d.grain_pebble(case_m, 0.015, seed=p.seed + 1 if hasattr(p, "seed") else 1)
    return case_m


def kick(p, W, H, louvres=False):
    """the toe kick along the bottom: a recessed strip (the dryer's has its vent louvres)"""
    d = p.d
    k = Mask(W, H).rrect(10, H - 16, W - 20, 10, 2).get()
    d.well(k, 1.2, "lb_white", bevel=0.8)
    if louvres:
        for x in range(18, W - 18, 6):
            d.well(Mask(W, H).rect(x, H - 14, 3, 6).get(), 1.0, "blackp", bevel=0.4)
    return H - 16


def panel(p, W, py, ph, mat="lb_blue"):
    d = p.d
    m = Mask(W, H := p.H).rrect(8, py, W - 16, ph, 3).get()
    d.slab(m, 0.8, mat, bevel=1.0, polish=0.6, on=Z_FACE)
    d.seam(Mask(W, H).rect(8, py + ph + 2, W - 16, 1).get(), 0.5)            # the joint between panel and front
    return Z_FACE + 0.8


def power_button(p, cx, cy, zp, ink="paint_w", label=True):
    """a round push button on its chrome ring, the power lamp beside it: green running, red no power"""
    d = p.d
    d.torus(cx, cy, 5.5, 7.5, 1.2, "chrome", polish=1.0, on=zp)
    d.dome(cx, cy, 5.5, 5.5, 1.8, "lb_white", polish=0.8, on=zp)
    m = ring(d, cx, cy, 2.0, 3.0) & ~((d.YY < cy - 1) & (np.abs(d.XX + 0.5 - cx) < 1.6))
    d.paint(m, "paint_k", flatlight=True); d.paint(rbox(d, int(cx), int(cy - 4), 1, 4), "paint_k", flatlight=True)
    p.hit("power", cx - 8, cy - 8, 16, 16, needs="powered")
    lx = cx - 13
    d.dome(lx, cy, 2.2, 2.2, 1.0, "jewel_off", polish=0.9, on=zp)
    p.lamp(disc(d, lx, cy, 2.0), "running", "#5dff7a")
    p.lamp(disc(d, lx, cy, 2.0), "noPower", "#ff3a2e")
    if label: p.label("POWER", cx, cy + 10, ink, align="c", auto_ink=False)


def phase_window(p, x, y, legends, zp, extra=None):
    """the phase lamps: legends printed dark on a smoked strip that light in turn while a cycle runs; `extra` is a
    warning legend at the right (FILL: no water), lit in amber"""
    d = p.d
    w = 4
    for t, _ in legends: w += text_w(t) + 5
    if extra: w += text_w(extra[0]) + 7
    w += 1
    window_glass(p, x, y, w, 11, face="ledglass", bezel="blackp", depth=1.2, on=zp, r=1, bezel_t=1, lens=True)
    cx = x + 4
    for t, src in legends:
        lamp_text(p, t, cx, y + 3, src, "#7dff9a")
        cx += text_w(t) + 5
    if extra:
        cx += 2
        d.seam(Mask(d.W, d.H).rect(cx - 4, y + 2, 1, 7).get(), 0.4)
        lamp_text(p, extra[0], cx, y + 3, extra[1], "#ffb02e")
    return w


def phase_w(legends, extra=None):
    w = 4 + sum(text_w(t) + 5 for t, _ in legends) + 1
    return w + (text_w(extra[0]) + 7 if extra else 0)


def cycle_gauge(p, cx, cy, r, zp, ink="paint_w", label=True):
    """the cycle under glass: a small round gauge (no knob to turn) whose pointer goes from START round to END as a
    cycle runs (ptr cycleF: Code moves it by the clock while running, back to START when it stops)"""
    d = p.d
    d.torus(cx, cy, r, r + 2, 1.2, "chrome", polish=1.0, on=zp)
    face = disc(d, cx, cy, r)
    d.flat(face, zp - 0.8, "blackp", polish=0.5)
    a0, a1 = -225, 45
    for i in range(9):
        a = math.radians(a0 + (a1 - a0) * i / 8)
        r0 = r - (3 if i % 4 == 0 else 2)
        for t in np.linspace(r0, r - 1, 4):
            x, y = int(round(cx + math.cos(a) * t - 0.5)), int(round(cy + math.sin(a) * t - 0.5))
            if 0 <= x < d.W and 0 <= y < d.H: d.paint(rbox(d, x, y, 1, 1), "paint_w", flatlight=True)
    p.part("ptr", src="cycleF", cx=cx, cy=cy, r0=0, r1=r - 3, a0=a0, a1=a1, color="#ff8a3a", w=1)
    d.dome(cx, cy, 1.6, 1.6, 0.8, "chrome", polish=1.0, on=zp - 0.8)
    d.paint(face & (np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy) > r - 2) & (d.YY < cy - r * 0.5) & (d.XX < cx), "chrome",
            flatlight=True)                                         # the glass's glare
    if label: p.label("CYCLE", cx, cy + r + 4, ink, align="c", auto_ink=False)


def water_meter(p, x, y, zp, ink="paint_w"):
    """five bars: the water the machine holds (its fluid against its capacity)"""
    d = p.d
    p.label("WATER", x, y, ink, auto_ink=False)
    bx = x + text_w("WATER") + 4
    bars = []
    for i in range(5):
        m = rbox(d, bx + i * 5, y + 4 - i, 4, 2 + i)
        d.well(m, 0.5, "ledoff", bevel=0.3)
        bars.append(runs_of(m))
    p.part("bars", src="water", max=5, bars=bars, color="#58b4ff")
    return bx + 25 - x


METER_W = text_w("WATER") + 4 + 25


def right_controls(p, W, py, zp, rows2, ink="paint_w"):
    """the power button at the panel's right and the cycle gauge beside it: one row (a big gauge, its label under it)
    or the two-row panel's first row (a smaller gauge whose label lines up with POWER's)"""
    bx = W - 16 - 10 if not rows2 else W - 24
    if not rows2:
        by = py + 16
        power_button(p, bx, by, zp, ink=ink)
        cycle_gauge(p, bx - 46, py + 15, 11, zp, ink=ink)
        return bx - 46 - 13
    by = py + 14
    power_button(p, bx, by, zp, ink=ink)
    cycle_gauge(p, bx - 38, by - 2, 8, zp, ink=ink)
    return bx - 38 - 10


# =================================================================================== the laundry, behind the glass
def _local(d, cx, cy, ang):
    ca, sa = math.cos(ang), math.sin(ang)
    X = d.XX + 0.5 - cx; Y = d.YY + 0.5 - cy
    return X * ca + Y * sa, -X * sa + Y * ca


def blob(d, cx, cy, rx, ry, ang, rng, wob=0.20):
    """a crumpled piece of cloth seen from the front: an ellipse whose edge comes and goes"""
    u, v = _local(d, cx, cy, ang)
    a = np.arctan2(v / ry, u / rx)
    k = rng.uniform(0, TAU, 3)
    w = 1 + wob * (0.55 * np.sin(2 * a + k[0]) + 0.30 * np.sin(3 * a + k[1]) + 0.15 * np.sin(5 * a + k[2]))
    return (u / rx) ** 2 + (v / ry) ** 2 <= w ** 2


def tube(d, x0, y0, x1, y1, r0, r1, rng, wob=0.12):
    """a sleeve or a trouser leg: a capsule from (x0, y0) to (x1, y1), radius r0 to r1, its outline lumpy;
    returns the mask and t, 0 at the first end to 1 at the second"""
    X = d.XX + 0.5; Y = d.YY + 0.5
    dx, dy = x1 - x0, y1 - y0; L2 = dx * dx + dy * dy
    t = np.clip(((X - x0) * dx + (Y - y0) * dy) / L2, 0, 1)
    dist = np.hypot(X - (x0 + t * dx), Y - (y0 + t * dy))
    k = rng.uniform(0, TAU, 2)
    rad = (r0 + (r1 - r0) * t) * (1 + wob * (0.6 * np.sin(t * 9 + k[0]) + 0.4 * np.sin(t * 17 + k[1])))
    return dist <= rad, t


def drape(d, m, mat, T, rng, folds=3, lam=7.0, amp=0.55, along=None, polish=0.10, lumps=0.45):
    """lay a cloth over what is there: it stands a little off what it lies on (its edge casts a shadow), rises to a
    soft thickness T away from its edge, and is folded in a few places (each fold a set of ridges under a soft window)"""
    if not m.any(): return m
    de = edt(m)
    inner = np.clip(de / 2.5, 0, 1)
    h = 0.5 + T * np.clip(de / max(2.0, T * 2.5), 0, 1) ** 0.55
    if lumps:                                   # the cloth's own lumps: smooth noise at about a fold's size
        nz = ndi.gaussian_filter(rng.random(m.shape).astype(np.float32), max(1.5, lam * 0.55))
        nz = (nz - nz[m].mean()) / max(1e-6, nz[m].std())
        h += lumps * nz * inner
    ys, xs = np.nonzero(m)
    for _ in range(folds + (2 if along is None else 1)):
        i = rng.integers(len(xs)); fx, fy = xs[i] + 0.5, ys[i] + 0.5
        ang = (along + rng.normal(0, 0.35)) if along is not None else rng.uniform(0, math.pi)
        u, v = _local(d, fx, fy, ang)
        sig = rng.uniform(0.8, 1.5) * lam * 1.25
        win = np.exp(-(u ** 2 + (v * 0.6) ** 2) / (2 * sig ** 2))
        bend = rng.uniform(-0.03, 0.03)
        lam_k = lam * rng.uniform(0.8, 1.25)
        h += amp * win * np.sin(TAU * (u + bend * v * v) / lam_k + rng.uniform(0, TAU)) * inner
    d.h = np.where(m, d.h + h, d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = polish; d.tex[m] = 0
    return m


def plaid(d, m, cx, cy, ang, period, dark="cl_red_dk", light="cl_cream"):
    """a flannel check: dark bands both ways, a thin light line between them"""
    u, v = _local(d, cx, cy, ang)
    bu = np.mod(u, period) < period * 0.42
    bv = np.mod(v, period) < period * 0.42
    d.paint(m & (bu | bv), dark)
    d.paint(m & bu & bv, "cl_red_xx")


def twill(d, m, amount=0.05):
    """denim's diagonal weave"""
    d.tex[m] += np.where(((d.XX + d.YY) % 3 == 0), amount, -amount * 0.4)[m]


def ribs(d, m, cx, cy, ang, amount=0.08):
    """a ribbed knit (a cuff, a collar): fine ridges across the band"""
    u, _ = _local(d, cx, cy, ang)
    d.tex[m] += np.where(np.mod(np.floor(u), 2) == 0, amount, -amount)[m]


def stitch(d, pts, mat="cl_stitch", within=None):
    """a line of stitching along a polyline: two pixels on, one off"""
    k = 0
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n):
            if k % 3 != 2:
                x = int(round(x0 + (x1 - x0) * i / max(1, n - 1) - 0.5)); y = int(round(y0 + (y1 - y0) * i / max(1, n - 1) - 0.5))
                if 0 <= x < d.W and 0 <= y < d.H and (within is None or within[y, x]):
                    d.paint(rbox(d, x, y, 1, 1), mat)
            k += 1


def heap(p, inside, cx, cy, r, seed, kind="wash"):
    """the load lying in the bottom of the drum, the back pieces first: each drapes over the ones before it, so they
    stack, shade and shadow one another under the plate's light. kind "wash": the washer's everyday load (khaki
    trousers, a sweater, a flannel shirt, a T-shirt, jeans, a sock, a dish towel); "dry": the dryer's (towels, a
    sweatshirt, a navy T-shirt, jeans, socks)"""
    d = p.d
    rng = np.random.default_rng(seed)
    s = r / 88.0
    lam = max(4.5, 7.5 * s)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    clip = inside & (rr < r - 1.0)
    P = lambda fx, fy: (cx + fx * r, cy + fy * r)
    if kind == "wash":
        # the dish towel at the back, its stripe
        x, y = P(0.12, 0.26)
        m = blob(d, x, y, 0.24 * r, 0.12 * r, -0.10, rng) & clip
        drape(d, m, "cl_yellow", 1.4 * s, rng, folds=2, lam=lam)
        u, v = _local(d, x, y, -0.10)
        d.paint(m & (np.abs(v - 0.03 * r) < 1.4 * s + 0.6), "cl_white")
        # khaki trousers, back left: a waistband along the top
        x, y = P(-0.36, 0.42)
        m = blob(d, x, y, 0.44 * r, 0.24 * r, -0.16, rng) & clip
        drape(d, m, "cl_khaki", 2.2 * s, rng, folds=4, lam=lam)
        u, v = _local(d, x, y, -0.16)
        band = m & (v < -0.13 * r) & (v > -0.13 * r - 3.2 * s)
        d.paint(band, "cl_khaki"); d.tex[band] += 0.06
        stitch(d, [(x - 0.30 * r, y - 0.11 * r), (x + 0.10 * r, y - 0.18 * r)], within=m)
        # the green sweater, back right: a sleeve's ribbed cuff hanging out of it
        x, y = P(0.40, 0.38)
        m = blob(d, x, y, 0.36 * r, 0.22 * r, 0.22, rng) & clip
        drape(d, m, "cl_green", 2.4 * s, rng, folds=3, lam=lam * 1.1)
        cuff, t = tube(d, cx + 0.56 * r, cy + 0.20 * r, cx + 0.72 * r, cy + 0.30 * r, 0.09 * r, 0.08 * r, rng)
        cuff &= clip
        drape(d, cuff, "cl_green", 1.4 * s, rng, folds=0)
        ribs(d, cuff, cx + 0.64 * r, cy + 0.25 * r, 0.56)
        # the red flannel shirt, the middle of the heap: its collar on the upper left edge, a placket of buttons
        x, y = P(0.02, 0.52)
        m = blob(d, x, y, 0.46 * r, 0.25 * r, 0.06, rng) & clip
        drape(d, m, "cl_red", 2.6 * s, rng, folds=4, lam=lam)
        plaid(d, m, x, y, 0.06 + 0.35, max(8.0, 15.0 * s))
        col = m & (np.hypot(d.XX + 0.5 - (x - 0.30 * r), d.YY + 0.5 - (y - 0.06 * r)) < 0.13 * r) & \
            (np.hypot(d.XX + 0.5 - (x - 0.30 * r), d.YY + 0.5 - (y - 0.06 * r)) > 0.13 * r - 3.0 * s)
        d.paint(col, "cl_red_dk")
        for i in range(3):
            bx, by_ = x + (0.06 + 0.07 * i) * r, y - (0.05 - 0.04 * i) * r
            if 0 <= int(bx) < d.W and 0 <= int(by_) < d.H and m[int(by_), int(bx)]:
                d.dome(bx, by_, 1.1 * max(1, s), 1.1 * max(1, s), 0.6, "cl_cream", polish=0.8, on="h")
        # the white T-shirt, front left: its round rib collar
        x, y = P(-0.44, 0.67)
        m = blob(d, x, y, 0.34 * r, 0.18 * r, -0.30, rng) & clip
        drape(d, m, "cl_white", 2.0 * s, rng, folds=3, lam=lam * 0.9)
        nx, ny = x + 0.10 * r, y - 0.03 * r
        rn = np.hypot(d.XX + 0.5 - nx, d.YY + 0.5 - ny)
        neck = m & (rn < 0.09 * r) & (rn > 0.09 * r - 2.6 * s)
        ribs(d, neck, nx, ny, 1.2, 0.07)
        d.dark[m & (rn < 0.09 * r - 2.6 * s)] = 0.35                       # the inside of the neck
        # the jeans: a leg across the front, its hem turned up, the outseam's stitching along it
        x0, y0, x1, y1 = cx - 0.12 * r, cy + 0.80 * r, cx + 0.62 * r, cy + 0.56 * r
        leg, t = tube(d, x0, y0, x1, y1, 0.14 * r, 0.12 * r, rng)
        leg &= clip
        drape(d, leg, "cl_denim", 2.6 * s, rng, folds=3, lam=lam * 0.8, along=math.atan2(y1 - y0, x1 - x0))
        twill(d, leg)
        hem = leg & (t > 0.86)
        d.paint(hem, "cl_denim"); d.tex[hem] += 0.10                         # the turned-up hem: the lighter inside
        d.seam(leg & (np.abs(t - 0.86) < 0.012), 0.35)
        nx, ny = -(y1 - y0), (x1 - x0); nl = math.hypot(nx, ny); nx, ny = nx / nl, ny / nl
        stitch(d, [(x0 + nx * 0.05 * r, y0 + ny * 0.05 * r), (x1 + nx * 0.04 * r, y1 + ny * 0.04 * r)], within=leg)
        # a grey sock, front right: its ribbed top
        sk, t = tube(d, cx + 0.42 * r, cy + 0.84 * r, cx + 0.70 * r, cy + 0.70 * r, 0.065 * r, 0.06 * r, rng)
        sk &= clip
        drape(d, sk, "cl_grey", 1.6 * s, rng, folds=1, lam=lam * 0.6)
        ribs(d, sk & (t > 0.55), cx + 0.6 * r, cy + 0.75 * r, -0.46 + math.pi / 2, 0.07)
    else:
        # the dryer: towels and sweats, fluffed
        x, y = P(-0.30, 0.36)
        m = blob(d, x, y, 0.42 * r, 0.20 * r, -0.12, rng) & clip
        drape(d, m, "cl_teal", 2.4 * s, rng, folds=3, lam=lam * 1.2)
        d.tex[m] += np.where(rng.random(m.shape) < 0.16, 0.035, 0.0)[m]      # terry: the loops catch the light
        u, v = _local(d, x, y, -0.12)
        d.paint(m & (np.abs(u - 0.22 * r) < 2.0 * s), "cl_white")           # the towel's woven band
        x, y = P(0.36, 0.40)
        m = blob(d, x, y, 0.38 * r, 0.22 * r, 0.18, rng) & clip
        drape(d, m, "cl_grey", 2.8 * s, rng, folds=3, lam=lam * 1.2)
        cuff, t = tube(d, cx + 0.10 * r, cy + 0.30 * r, cx + 0.30 * r, cy + 0.24 * r, 0.08 * r, 0.075 * r, rng)
        cuff &= clip
        drape(d, cuff, "cl_grey", 1.5 * s, rng, folds=0)
        ribs(d, cuff & (t > 0.6), cx + 0.25 * r, cy + 0.26 * r, -0.3 + math.pi / 2)
        x, y = P(-0.02, 0.56)
        m = blob(d, x, y, 0.40 * r, 0.22 * r, 0.05, rng) & clip
        drape(d, m, "cl_white", 2.6 * s, rng, folds=4, lam=lam * 1.1)
        d.tex[m] += np.where(rng.random(m.shape) < 0.14, 0.03, 0.0)[m]
        x, y = P(0.44, 0.68)
        m = blob(d, x, y, 0.30 * r, 0.16 * r, -0.35, rng) & clip
        drape(d, m, "cl_navy", 2.0 * s, rng, folds=3, lam=lam * 0.9)
        nx, ny = x - 0.06 * r, y - 0.04 * r
        rn = np.hypot(d.XX + 0.5 - nx, d.YY + 0.5 - ny)
        ribs(d, m & (rn < 0.08 * r) & (rn > 0.08 * r - 2.4 * s), nx, ny, 0.8, 0.07)
        x0, y0, x1, y1 = cx - 0.66 * r, cy + 0.62 * r, cx + 0.02 * r, cy + 0.84 * r
        leg, t = tube(d, x0, y0, x1, y1, 0.13 * r, 0.12 * r, rng)
        leg &= clip
        drape(d, leg, "cl_denim", 2.4 * s, rng, folds=3, lam=lam * 0.8, along=math.atan2(y1 - y0, x1 - x0))
        twill(d, leg)
        nx, ny = -(y1 - y0), (x1 - x0); nl = math.hypot(nx, ny); nx, ny = nx / nl, ny / nl
        stitch(d, [(x0 - nx * 0.05 * r, y0 - ny * 0.05 * r), (x1 - nx * 0.05 * r, y1 - ny * 0.05 * r)], within=leg)
        for (a0x, a0y, a1x, a1y, mat) in ((0.14, 0.80, 0.38, 0.88, "cl_rose"), (0.30, 0.74, 0.52, 0.82, "cl_white")):
            sk, t = tube(d, cx + a0x * r, cy + a0y * r, cx + a1x * r, cy + a1y * r, 0.06 * r, 0.055 * r, rng)
            sk &= clip
            drape(d, sk, mat, 1.5 * s, rng, folds=1, lam=lam * 0.6)
            ribs(d, sk & (t > 0.6), cx + a1x * r, cy + a1y * r, math.atan2(a1y - a0y, a1x - a0x) + math.pi / 2, 0.07)


def _bubble(d, x, y, r, z0, clip, mat="foam", polish=0.9):
    """one bubble or knob of foam: a small dome that piles on what is there (the higher wins), kept inside clip"""
    x0, x1 = max(0, int(x - r - 1)), min(d.W, int(x + r + 2)); y0, y1 = max(0, int(y - r - 1)), min(d.H, int(y + r + 2))
    if x1 <= x0 or y1 <= y0: return
    XX = d.XX[y0:y1, x0:x1] + 0.5; YY = d.YY[y0:y1, x0:x1] + 0.5
    r2 = ((XX - x) ** 2 + (YY - y) ** 2) / (r * r)
    m = (r2 <= 1.0) & clip[y0:y1, x0:x1]
    if not m.any(): return
    prof = (np.sqrt(np.clip(1 - r2, 0, 1)) * r * 0.9 + z0).astype(np.float32)
    hs = d.h[y0:y1, x0:x1]
    sel = m & ((prof > hs) | ~d.solid[y0:y1, x0:x1])
    hs[sel] = prof[sel]
    d.mat[y0:y1, x0:x1][sel] = d.mid(mat); d.solid[y0:y1, x0:x1][sel] = True
    d.polish[y0:y1, x0:x1][sel] = polish; d.tex[y0:y1, x0:x1][sel] = 0


def water_top(cy, gR, lv): return cy + gR - lv * 0.24 * gR


def soapy_water(p, inside, cx, cy, gR, lv, zw, seed):
    """wash water at level lv of 5, from the bottom of the glass up: a milky blue face that darkens with depth and
    ripples, suds and bubbles in it (more near the top), and a head of foam along the waterline with a few rafts of it"""
    d = p.d
    if lv <= 0: return
    rng = np.random.default_rng(seed * 10 + lv)
    s = gR / 88.0
    top = water_top(cy, gR, lv)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    clip = inside & (rr < gR - 1.0)
    wm = clip & (d.YY + 0.5 >= top)
    if not wm.any(): return
    yy = d.YY + 0.5 - top
    xx = d.XX + 0.5 - cx
    rip = 0.30 * np.sin(TAU * xx / (gR * 0.62) + 1.4 * np.sin(TAU * yy / (gR * 0.40))) * np.sin(TAU * yy / max(6.0, 9 * s))
    d.h = np.where(wm, zw + rip, d.h).astype(np.float32)
    d.mat[wm] = d.mid("suds"); d.solid |= wm; d.polish[wm] = 0.75; d.tex[wm] = 0; d.dark[wm] = 0
    d.flatlight[wm] = False
    depth = np.clip(yy / max(1.0, cy + gR - top), 0, 1)
    edge = np.clip((rr / gR - 0.78) / 0.22, 0, 1)                  # and toward the glass's edge, the drum's wall
    d.dark[wm] = (0.20 * depth ** 1.2 + 0.12 * edge ** 2)[wm]
    # swirls of suds in the water: pale streaks that follow the drum round
    ang = np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)
    sw = np.sin(ang * 3.0 + rr / (gR * 0.17) + seed) > 0.93
    d.tex[wm & sw] += 0.08
    # bubbles in the water, thicker toward the top
    ys, xs = np.nonzero(wm)
    n_b = int((40 + 22 * lv) * s * s)
    for _ in range(n_b):
        i = rng.integers(len(xs))
        if rng.random() > 0.35 + 0.65 * (1 - np.clip((ys[i] + 0.5 - top) / max(1.0, cy + gR - top), 0, 1)): continue
        _bubble(d, xs[i] + 0.5, ys[i] + 0.5, rng.uniform(0.7, 1.6) * max(1.0, s), zw + 0.2, clip, polish=1.0)
    # the head of foam: a band of bubbles along the waterline, its top uneven
    half = math.sqrt(max(0.0, gR * gR - (top - cy) ** 2))
    xl, xr = cx - half, cx + half
    x = xl
    head = 1.0 + 0.12 * lv
    while x < xr:
        for _ in range(3):
            rb = rng.uniform(1.6, 3.8) * max(1.0, s)
            _bubble(d, x + rng.uniform(-1, 1), top + rng.uniform(-2.6, 3.4) * s * head, rb, zw, clip)
        if rng.random() < 0.45:
            _bubble(d, x, top - rng.uniform(1.5, 4.0) * s * head, rng.uniform(1.4, 2.8) * max(1.0, s), zw + 0.4, clip)
        x += rng.uniform(1.5, 2.6) * max(1.0, s)
    for side in (-1, 1):                      # the foam climbs the glass a little at each end of the waterline
        for k in range(int(3 * s) + 2):
            a = math.asin(np.clip((top - cy) / gR, -1, 1)) - k * 0.028
            bx_, by_ = cx + side * math.cos(a) * (gR - 3), cy + math.sin(a) * (gR - 3)
            _bubble(d, bx_, by_, rng.uniform(1.4, 2.6) * max(1.0, s), zw + 0.3, clip)
    # rafts of foam floating just under the head
    for _ in range(int(3 + lv * s)):
        fx = rng.uniform(xl + 6, xr - 6) if xr - xl > 14 else cx
        fy = top + rng.uniform(4, 10) * s
        for _ in range(int(rng.integers(4, 9))):
            _bubble(d, fx + rng.normal(0, 3.2 * s), fy + rng.normal(0, 1.3 * s), rng.uniform(1.2, 2.4) * max(1.0, s), zw + 0.1, clip)


def porthole(p, cx, cy, R, kind="washer", clothes=False, water_lv=0):
    """the door: a white plastic ring on a chrome rim, the glass, the drum behind it (its perforations and one baffle,
    which turns while running: ptr drumF), the clothes when there are any, the soapy water at water_lv of 5 (the
    `water` pictures), the handle at the right"""
    d = p.d
    zr = Z_FACE
    d.torus(cx, cy, R - 6, R, 2.6, "lb_white", polish=0.7, on=zr)
    d.torus(cx, cy, R - 8, R - 5, 1.6, "chrome", polish=1.0, on=zr + 1.0)
    gR = R - 8
    glass = disc(d, cx, cy, gR)
    d.flat(glass, zr - 3.0, "drum", polish=0.4)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ang = np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)
    holes = glass & (rr < gR - 3) & ((np.round(rr) % 4) == 0) & ((np.round(ang * rr / 3.0) % 2) == 0)
    d.paint(holes, "hole", flatlight=True)
    d.seam(ring(d, cx, cy, gR * 0.20, gR * 0.20 + 1) & glass, 0.4)          # the drum's back: its hub ring
    d.dark[glass] = np.maximum(d.dark[glass], (0.30 * np.clip((rr / gR - 0.60) / 0.40, 0, 1) ** 1.5)[glass])   # the drum's wall, receding
    if clothes:
        heap(p, glass, cx, cy, gR, 7 if kind == "washer" else 13, kind="wash")
    if water_lv:
        soapy_water(p, glass, cx, cy, gR, water_lv, zr - 0.6, 5 if kind == "washer" else 9)
    p.part("ptr", src="drumF", cx=cx, cy=cy, r0=gR * 0.80, r1=gR * 0.96, a0=-90, a1=270, color="#8e959d", w=2)
    glare = glass & (rr > gR - 5) & (rr < gR - 3) & (ang > -2.6) & (ang < -1.6)
    d.paint(glare, "chrome", flatlight=True)
    hx_ = int(cx + R - 3)
    d.well(Mask(d.W, d.H).rrect(hx_ - 2, int(cy - 9), 5, 18, 2).get(), 1.4, "lb_white", bevel=1.0)
    p.hit("door", cx - R, cy - R, 2 * R, 2 * R)
    return glass


def door_area(p, py, ph, kick_y, W, label):
    top = py + ph + (16 if label else 8)
    avail = kick_y - 6 - top
    R = int(min(avail / 2, W * 0.37))
    return R, W // 2, top + avail // 2


def _wear(p, W, H, inside, seed):
    d = p.d
    WR.grime(d, d.solid & ~inside, amount=0.16, seed=seed)
    WR.scuffs(d, WR.mat_mask(d, "lb_white") & (d.YY > H - 30), 0.003, seed=seed + 1, amount=-0.06)


# =================================================================================== the console (washer and dryer)
def console(p, W, py, ph):
    """the backsplash at the back of the top: a dark console standing up off the cabinet, white end caps, its shadow
    on the top in front of it (the game's washer and dryer both carry their controls on one)"""
    d = p.d; H = p.H
    m = Mask(W, H).rrect(4, py, W - 8, ph, 4).get()
    d.slab(m, 2.4, "lb_console", bevel=1.4, polish=0.55, on=Z_FACE)
    for x in (4, W - 9):
        d.slab(Mask(W, H).rrect(x, py, 5, ph, 2).get(), 0.8, "lb_white", bevel=0.7, polish=0.7, on=Z_FACE + 2.4)
    d.seam(Mask(W, H).rect(9, py + ph + 1, W - 18, 1).get(), 0.5)
    return Z_FACE + 2.4


def brand_plate(p, W, py, ph, rows2, zp):
    d = p.d
    dw_, dh_ = (64, ph - 10) if not rows2 else (60, 22)
    dx_, dy_ = (15 if not rows2 else 14), py + 5
    d.slab(Mask(W, p.H).rrect(dx_, dy_, dw_, dh_, 2).get(), 0.8, "lb_white", bevel=0.8, polish=0.5, on=zp)
    p.label("PREMIUM", dx_ + dw_ // 2, dy_ + (dh_ - 12) // 2, "lb_blue_dk", align="c", auto_ink=False)
    p.label("TECHNOLOGIES", dx_ + dw_ // 2, dy_ + (dh_ - 12) // 2 + 6, "lb_blue_dk", align="c", auto_ink=False)
    return dx_, dw_


# =================================================================================== the top-loader's tub, from above
def tub(p, cx, cy, tR, zdeck, s):
    """the basket seen from above: its perforated wall sloping down to the floor, the balance ring round its mouth;
    returns (basket mask, floor z, depth, floor radius)"""
    d = p.d
    Dp = 6.5 + 2.5 * s
    zf = zdeck - Dp
    fR = tR * 0.80
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ang = np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)
    basket = rr < tR
    t = np.clip((rr - fR) / (tR - fR), 0, 1)
    hw = zf + (Dp - 1.2) * t ** 1.6
    d.h = np.where(basket, hw, d.h).astype(np.float32)
    d.mat[basket] = d.mid("drum"); d.solid |= basket; d.polish[basket] = 0.45; d.tex[basket] = 0
    d.flatlight[basket] = False; d.dark[basket] = (0.16 * (1 - t))[basket]
    wall = basket & (rr > fR + 1.5) & (rr < tR - 2)
    holes = wall & ((np.round(rr) % 3) == 0) & ((np.round(ang * rr / 3.0) % 2) == 0)
    d.paint(holes, "hole", flatlight=True)
    drain = basket & (np.abs(rr - fR * 0.62) < 0.8) & ((np.round(ang * rr / 4.0) % 2) == 0)
    d.paint(drain, "hole", flatlight=True)
    d.torus(cx, cy, tR - 1.5, tR + 2.5, 1.2, "lb_grey", polish=0.6, on=zdeck - 1.4)      # the balance ring
    return basket, zf, Dp, fR


def agitator(p, cx, cy, ra, zf, Dp):
    """the agitator in the middle: a skirt with four fins, the post, the softener cup on top"""
    d = p.d
    d.dome(cx, cy, ra * 2.0, ra * 2.0, 1.6, "lb_grey", polish=0.6, on=zf)
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        u, v = _local(d, cx, cy, a)
        fin = (u > ra * 0.8) & (u < ra * 2.3) & (np.abs(v) < max(1.2, ra * 0.16))
        hf = zf + 1.6 + 1.8 * np.clip(1 - (u - ra) / (ra * 1.3), 0, 1)
        sel = fin & (hf > d.h)
        d.h = np.where(sel, hf, d.h).astype(np.float32); d.mat[sel] = d.mid("lb_grey"); d.polish[sel] = 0.6
        d.tex[sel] = 0; d.solid |= sel
    d.dome(cx, cy, ra, ra, Dp * 0.95, "lb_grey", polish=0.75, on=zf + 1.0)
    d.torus(cx, cy, ra * 0.45, ra * 0.72, 0.6, "lb_white", polish=0.9, on="h")
    d.dome(cx, cy, ra * 0.45, ra * 0.45, 0.8, "lb_white", polish=0.9, on="h")
    return disc(d, cx, cy, ra * 2.35)


def heap_top(p, cx, cy, tR, fR, ra, seed):
    """the washer's load seen from above, lying round the agitator: the back pieces first, each draped over the ones
    before it (the same garments as the front-loader's: a dish towel, khaki trousers, a green sweater and its cuff, the
    red flannel, a white T-shirt, the jeans with their stitching, a sock)"""
    d = p.d
    rng = np.random.default_rng(seed)
    s = fR / 70.0
    lam = max(4.5, 7.0 * s)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    clip = (rr < tR * 0.96) & (rr > ra * 2.2)
    rad = math.radians
    P = lambda adeg, f: (cx + math.cos(rad(adeg)) * f * fR, cy + math.sin(rad(adeg)) * f * fR)
    def piece(adeg, f, rx, ry, mat, T, folds, lamk=1.0):
        x, y = P(adeg, f)
        m = blob(d, x, y, rx * fR, ry * fR, rad(adeg + 90), rng) & clip
        drape(d, m, mat, T * s, rng, folds=folds, lam=lam * lamk)
        return m, x, y
    piece(-85, 0.70, 0.52, 0.30, "cl_navy", 2.0, 4)       # a navy T-shirt at the back, under the rest
    piece(-175, 0.80, 0.40, 0.22, "cl_grey", 1.8, 3)
    # the dish towel, its stripe
    m, x, y = piece(-30, 0.68, 0.46, 0.30, "cl_yellow", 1.8, 3)
    u, v = _local(d, x, y, rad(-35 + 90))
    d.paint(m & (np.abs(u + 0.06 * fR) < 1.4 * s + 0.6), "cl_white")
    # khaki trousers, a waistband
    m, x, y = piece(-140, 0.66, 0.62, 0.32, "cl_khaki", 2.4, 5)
    u, v = _local(d, x, y, rad(-140 + 90))
    band = m & (v > 0.12 * fR) & (v < 0.12 * fR + 3.2 * s)
    d.tex[band] += 0.06
    # the green sweater, its ribbed cuff reaching in toward the agitator
    m, x, y = piece(35, 0.66, 0.56, 0.32, "cl_green", 2.6, 4, 1.1)
    c0, c1 = P(58, 0.62), P(74, 0.42)
    cuff, t = tube(d, c0[0], c0[1], c1[0], c1[1], 0.12 * fR, 0.11 * fR, rng)
    cuff &= clip
    drape(d, cuff, "cl_green", 1.8 * s, rng, folds=0)
    ribs(d, cuff & (t > 0.55), c1[0], c1[1], math.atan2(c1[1] - c0[1], c1[0] - c0[0]) + math.pi / 2)
    # the red flannel shirt across the front, buffalo check, buttons on its placket
    m, x, y = piece(100, 0.64, 0.64, 0.34, "cl_red", 2.8, 5)
    plaid(d, m, x, y, 0.35, max(8.0, 14.0 * s))
    for i in range(3):
        bx, by_ = x + (-0.10 + 0.09 * i) * fR, y - 0.05 * fR
        if 0 <= int(bx) < d.W and 0 <= int(by_) < d.H and m[int(by_), int(bx)]:
            d.dome(bx, by_, 1.1 * max(1, s), 1.1 * max(1, s), 0.6, "cl_cream", polish=0.8, on="h")
    # the white T-shirt at the left, its collar
    m, x, y = piece(175, 0.64, 0.50, 0.32, "cl_white", 2.4, 4, 0.9)
    nx, ny = x + 0.04 * fR, y - 0.10 * fR
    rn = np.hypot(d.XX + 0.5 - nx, d.YY + 0.5 - ny)
    ribs(d, m & (rn < 0.10 * fR) & (rn > 0.10 * fR - 2.6 * s), nx, ny, 1.2, 0.07)
    d.dark[m & (rn < 0.10 * fR - 2.6 * s)] = 0.35
    # the jeans: a leg over the top of the load, its outseam stitched, the hem turned up
    a0, a1 = P(-118, 0.74), P(-48, 0.56)
    leg, t = tube(d, a0[0], a0[1], a1[0], a1[1], 0.17 * fR, 0.15 * fR, rng)
    leg &= clip
    drape(d, leg, "cl_denim", 2.8 * s, rng, folds=3, lam=lam * 0.8, along=math.atan2(a1[1] - a0[1], a1[0] - a0[0]))
    twill(d, leg)
    hem = leg & (t > 0.86); d.tex[hem] += 0.10; d.seam(leg & (np.abs(t - 0.86) < 0.012), 0.35)
    nx, ny = -(a1[1] - a0[1]), (a1[0] - a0[0]); nl = math.hypot(nx, ny); nx, ny = nx / nl, ny / nl
    stitch(d, [(a0[0] + nx * 0.06 * fR, a0[1] + ny * 0.06 * fR), (a1[0] + nx * 0.05 * fR, a1[1] + ny * 0.05 * fR)], within=leg)
    # a grey sock
    s0, s1 = P(140, 0.80), P(155, 0.56)
    sk, t = tube(d, s0[0], s0[1], s1[0], s1[1], 0.085 * fR, 0.08 * fR, rng)
    sk &= clip
    drape(d, sk, "cl_grey", 1.6 * s, rng, folds=1, lam=lam * 0.6)
    ribs(d, sk & (t > 0.55), s1[0], s1[1], math.atan2(s1[1] - s0[1], s1[0] - s0[0]) + math.pi / 2, 0.07)


TOP_LEVELS = (0.06, 0.14, 0.25, 0.40, 0.80)


def water_from_above(p, cx, cy, tR, ra, zf, Dp, lv, seed):
    """wash water at level lv of 5 rising in the tub: it fills everything lower than its surface, so the clothes'
    tops stand out of it until it covers them; suds swirl round the agitator, foam gathers where the water meets the
    clothes, the agitator and the wall, and floats in rafts"""
    d = p.d
    if lv <= 0: return
    rng = np.random.default_rng(seed * 10 + lv)
    s = tR / 88.0
    zw = zf + Dp * TOP_LEVELS[lv - 1]
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ang = np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)
    basin = rr < tR - 1
    wm = basin & (d.h < zw)
    if not wm.any(): return
    depth = (zw - d.h)
    cloth_ids = np.array([d.mid(n) for n in CLOTH_RAMPS])
    seen = wm & np.isin(d.mat, cloth_ids) & (depth < 1.3 * max(1.0, s)) & (((d.XX + d.YY) % 2) == 0)
    wm = wm & ~seen
    d.dark[seen] = np.maximum(d.dark[seen], 0.18)
    rip = 0.16 * np.sin(rr / max(2.0, 2.4 * s) - 3 * ang) + 0.10 * np.sin(rr / max(1.5, 1.3 * s) + 2 * ang)
    d.h = np.where(wm, zw + rip, d.h).astype(np.float32)
    d.mat[wm] = d.mid("suds"); d.polish[wm] = 0.75; d.tex[wm] = 0; d.flatlight[wm] = False
    d.dark[wm] = np.clip(0.035 * depth + 0.10 * np.clip((rr / tR - 0.80) / 0.20, 0, 1) ** 2, 0, 0.30)[wm]
    sw = np.sin(ang * 4.0 + rr / (tR * 0.13) + seed) > 0.93                 # the swirl the agitator stirs
    d.tex[wm & sw] += 0.08
    ys, xs = np.nonzero(wm)
    for _ in range(int((30 + 14 * lv) * s * s)):                          # bubbles in it
        i = rng.integers(len(xs))
        _bubble(d, xs[i] + 0.5, ys[i] + 0.5, rng.uniform(0.7, 1.4) * max(1.0, s), zw + 0.1, basin, polish=1.0)
    bnd = wm & ndi.binary_dilation(~wm, iterations=2)                    # foam where the water meets anything
    by, bx = np.nonzero(bnd)
    if len(bx):
        for _ in range(int((50 + 45 * lv) * s * s)):
            i = rng.integers(len(bx))
            _bubble(d, bx[i] + 0.5 + rng.uniform(-1, 1), by[i] + 0.5 + rng.uniform(-1, 1),
                    rng.uniform(1.2, 3.0) * max(1.0, s), zw, basin)
    if lv >= 2:                                                           # a ring of suds round the agitator
        for _ in range(int((20 + 12 * lv) * s)):
            a = rng.uniform(0, TAU); r_ = ra * rng.uniform(1.05, 1.35 + 0.08 * lv)
            _bubble(d, cx + math.cos(a) * r_, cy + math.sin(a) * r_, rng.uniform(1.4, 2.8) * max(1.0, s), zw + 0.2, basin)
    for _ in range(int(2 + lv * s)):                                      # rafts of foam
        a = rng.uniform(0, TAU); r_ = rng.uniform(ra * 2.6, tR * 0.85)
        fx, fy = cx + math.cos(a) * r_, cy + math.sin(a) * r_
        if not (0 <= int(fx) < d.W and 0 <= int(fy) < d.H and wm[int(fy), int(fx)]): continue
        for _ in range(int(rng.integers(5, 11))):
            _bubble(d, fx + rng.normal(0, 3.0 * s), fy + rng.normal(0, 2.0 * s), rng.uniform(1.2, 2.4) * max(1.0, s),
                    zw + 0.1, basin)


# =================================================================================== the washer
def washer(W=392, worn_=True, clothes=False, water_lv=0):
    """Premium Technologies top-loading washer (IsoClothingWasher), as the game draws it: the controls on a dark
    console at the back, the lid up against it, the tub open to the player: the agitator, the load round it and the
    water rising through it"""
    narrow, Wf, H = _geom(W)
    p = Plate("washer" + ("_n" if narrow else ""), Wf, H, seed=501, title="Premium Technologies washer")
    d = p.d
    rows2 = Wf < 300
    legends = [("WASH", "phWash"), ("RINSE", "phRinse"), ("SPIN", "phSpin")]
    body(p, Wf, H)
    py = 8
    ph = 40 if not rows2 else 50
    zp = console(p, Wf, py, ph)
    kick_y = kick(p, Wf, H)
    dx_, dw_ = brand_plate(p, Wf, py, ph, rows2, zp)
    right_controls(p, Wf, py, zp, rows2)
    if not rows2:
        x0 = dx_ + dw_ + 12
        phase_window(p, x0, py + 8, legends, zp, extra=("FILL", "noWater"))
        water_meter(p, x0, py + 25, zp)
    else:
        phase_window(p, 15, py + 33, legends, zp, extra=("FILL", "noWater"))
        water_meter(p, 15 + phase_w(legends, ("FILL", "noWater")) + 8, py + 35, zp)
    # the top: the lid standing up against the console, the opening, the tub in it
    top = py + ph + 4
    bot = kick_y - (22 if not narrow else 8)
    lh = 7 if not narrow else 5
    d.slab(Mask(Wf, H).rrect(14, top, Wf - 28, lh, 2).get(), 3.2, "lb_white", bevel=1.2, polish=0.7, on=Z_FACE)
    d.seam(Mask(Wf, H).rect(16, top + lh, Wf - 32, 1).get(), 0.5)
    d.seam(Mask(Wf, H).rect(10, bot, Wf - 20, 1).get(), 0.6)                  # the top's front edge
    d.paint(Mask(Wf, H).rect(10, bot - 1, Wf - 20, 1).get(), "lb_white", flatlight=True)
    oy0, oy1 = top + lh + 4, bot - 4
    g = max(5, int(Wf * 0.025))
    tR = int(min((oy1 - oy0 - 2 * g) / 2, (Wf - 20 - 2 * g - 12) / 2))
    cx, cy = Wf / 2, (oy0 + oy1) / 2
    side = 2 * (tR + g)
    op = Mask(Wf, H).rrect(int(cx - side / 2), int(cy - side / 2), side, side, int(tR * 0.5)).get()
    d.well(op, 1.4, "lb_grey", bevel=1.0)
    bc = (int(cx - side / 2) + max(5, g) + 2, int(cy - side / 2) + max(5, g) + 2)  # the bleach cup in a corner
    d.torus(bc[0], bc[1], 2.5 * max(1, tR / 88), 4.0 * max(1, tR / 88), 0.8, "lb_white", polish=0.8, on=Z_FACE - 1.4)
    s = tR / 88.0
    basket, zf, Dp, fR = tub(p, cx, cy, tR, Z_FACE - 1.4, max(1.0, s))
    ra = max(5.0, tR * 0.13)
    agitator(p, cx, cy, ra, zf, Dp)
    if clothes:
        heap_top(p, cx, cy, tR, fR, ra, 7)
    if water_lv:
        water_from_above(p, cx, cy, tR, ra, zf, Dp, water_lv, 5)
    if not narrow: p.label("AUTOMATIC WASHER", 14, bot + 7, "lb_grey", auto_ink=False)
    p.hit("door", cx - side / 2, cy - side / 2, side, side)
    if worn_: _wear(p, Wf, H, op, 503)
    return p


# =================================================================================== the dryer
def dryer(W=392, worn_=True, clothes=False):
    """Premium Technologies dryer (IsoClothingDryer), the washer's pair: the same dark console at the back, a white
    door with a smoked window"""
    narrow, Wf, H = _geom(W)
    p = Plate("dryer" + ("_n" if narrow else ""), Wf, H, seed=511, title="Premium Technologies dryer")
    d = p.d
    rows2 = Wf < 300
    body(p, Wf, H)
    py = 8
    ph = 40 if not rows2 else 50
    zp = console(p, Wf, py, ph)
    kick_y = kick(p, Wf, H, louvres=True)
    dx_, dw_ = brand_plate(p, Wf, py, ph, rows2, zp)
    right_controls(p, Wf, py, zp, rows2)
    legends = [("DRY", "phDry"), ("COOL", "phCool")]
    if not rows2:
        x0 = dx_ + dw_ + 12
        phase_window(p, x0, py + 8, legends, zp)
        lamp_text(p, "HEAT", x0, py + 26, "running", "#ff6a3a", off="lb_ink_dim")
    else:
        w = phase_window(p, 15, py + 33, legends, zp)
        lamp_text(p, "HEAT", 15 + w + 8, py + 36, "running", "#ff6a3a", off="lb_ink_dim")
    if not narrow: p.label("AUTOMATIC DRYER", 14, py + ph + 8, "lb_grey", auto_ink=False)
    # the door: white, round, a smoked window in it
    R, cx, cy = door_area(p, py, ph, kick_y, Wf, not narrow)
    d.torus(cx, cy, R - 2, R, 1.6, "chrome", polish=1.0, on=Z_FACE)
    door = disc(d, cx, cy, R - 2)
    d.slab(door, 2.2, "lb_white", bevel=1.6, polish=0.7, on=Z_FACE)
    wR = int(R * 0.64)
    win = disc(d, cx, cy, wR)
    d.flat(win, Z_FACE - 2.0, "drum", polish=0.4)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ang = np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)
    d.paint(win & (rr < wR - 2) & ((np.round(rr) % 4) == 0) & ((np.round(ang * rr / 3.0) % 2) == 0), "hole", flatlight=True)
    d.seam(ring(d, cx, cy, wR * 0.22, wR * 0.22 + 1) & win, 0.4)
    d.dark[win] = np.maximum(d.dark[win], (0.30 * np.clip((rr / wR - 0.60) / 0.40, 0, 1) ** 1.5)[win])
    if clothes:
        heap(p, win, cx, cy, wR, 11, kind="dry")
    p.part("ptr", src="drumF", cx=cx, cy=cy, r0=wR * 0.78, r1=wR * 0.95, a0=-90, a1=270, color="#8e959d", w=2)
    d.torus(cx, cy, wR, wR + 2, 1.0, "chrome", polish=1.0, on=Z_FACE + 2.2)
    d.paint(win & (rr > wR - 4) & (rr < wR - 2) & (ang > -2.6) & (ang < -1.6), "chrome", flatlight=True)
    hx_ = int(cx + R * 0.72)
    d.slab(Mask(Wf, H).rrect(hx_ - 2, int(cy - R * 0.32), 5, int(R * 0.64), 2).get(), 1.4, "lb_white", bevel=1.0, polish=0.7,
           on=Z_FACE + 2.2)
    p.hit("door", cx - R, cy - R, 2 * R, 2 * R)
    if worn_: _wear(p, Wf, H, win, 513)
    return p


# =================================================================================== the combination
def combo(W=392, worn_=True, clothes=False, water_lv=0):
    """ValuTech compact washer-dryer (IsoCombinationWasherDryer): grey panel, the mode keys WASH and DRY (their lamps),
    the washer's phase lamps and FILL, DRY and COOL, the water meter, power"""
    narrow, Wf, H = _geom(W)
    p = Plate("combo" + ("_n" if narrow else ""), Wf, H, seed=521, title="ValuTech washer-dryer")
    d = p.d
    legends = [("WASH", "phWash"), ("RINSE", "phRinse"), ("SPIN", "phSpin"), ("DRY", "phDry"), ("COOL", "phCool")]
    pw = phase_w(legends, ("FILL", "noWater"))
    rows2 = Wf < 330
    rows3 = rows2 and 14 + pw + 8 + METER_W > Wf - 12
    body(p, Wf, H)
    py = 8
    ph = 40 if not rows2 else (52 if not rows3 else 64)
    zp = panel(p, Wf, py, ph, mat="lb_grey")
    kick_y = kick(p, Wf, H)
    MB.valutech_logo(p, 14 + 36, py + 6)
    # the mode keys: two push keys under the logo, each with its lamp
    ky = py + 18
    for i, (t, src) in enumerate((("WASH", "modeWash"), ("DRY", "modeDry"))):
        kx = 14 + i * 37
        PR.radio_key(p, f"mode_{t.lower()}", kx, ky, 34, 12, t, mat="lb_white", lab_mat="paint_k", z=1.4)
        lx = kx + 30
        d.dome(lx, ky - 3, 1.6, 1.6, 0.8, "jewel_off", polish=0.9, on=zp)
        p.lamp(disc(d, lx, ky - 3, 1.5), src, "#7dff9a")
    # the two keys are one control in the game (set the other mode): both ask for it, Code sends the mode named
    for h in p.hits:
        if h["id"] in ("mode_wash", "mode_dry"): h["needs"] = "powered"
    right_controls(p, Wf, py, zp, rows2, ink="paint_k")
    if not rows2:
        x0 = 14 + 2 * 37 + 8
        phase_window(p, x0, py + 8, legends, zp, extra=("FILL", "noWater"))
        water_meter(p, x0, py + 25, zp, ink="paint_k")
    elif not rows3:
        phase_window(p, 14, py + 35, legends, zp, extra=("FILL", "noWater"))
        water_meter(p, 14 + pw + 8, py + 37, zp, ink="paint_k")
    else:
        phase_window(p, 14, py + 35, legends, zp, extra=("FILL", "noWater"))
        water_meter(p, 14, py + 51, zp, ink="paint_k")
    if not narrow: p.label("WASHER-DRYER", 14, py + ph + 8, "lb_grey", auto_ink=False)
    R, cx, cy = door_area(p, py, ph, kick_y, Wf, not narrow)
    inside = porthole(p, cx, cy, R, "combo", clothes=clothes, water_lv=water_lv)
    if worn_: _wear(p, Wf, H, inside, 523)
    return p


def state(kind, running=False, powered=True, water=5, items=False, mode="wash", phase=None, drum=0.0):
    """the live state for the previews (and the names Code feeds): kind washer / dryer / combo"""
    wash_mode = kind == "washer" or (kind == "combo" and mode == "wash")
    s = dict(power=powered, running=running and powered, noPower=not powered, hasItems=items, drumF=drum,
             water=water if (kind != "dryer" and wash_mode) else 0,
             noWater=powered and wash_mode and kind != "dryer" and water <= 0)
    s["waterLoad"] = s["water"] if items else 0        # the top-loader's water: among the clothes, or in the bare tub
    s["waterBare"] = 0 if items else s["water"]
    if kind == "combo": s.update(modeWash=powered and mode == "wash", modeDry=powered and mode == "dry")
    for ph_ in ("phWash", "phRinse", "phSpin", "phDry", "phCool"): s[ph_] = bool(running and powered and phase == ph_)
    return s


CLOTHES = [("clothes", "hasItems", True, {"clothes": True})]
WATER = [(f"water{i}", "water", i, {"water_lv": i}) for i in range(1, 6)]   # after the clothes: the water draws over them
# the top-loader's water fills round the clothes (they stand out of it till it covers them), so it has its own pictures
# with the load in (`soak`, over the clothes picture) and without (`water`): Code sets waterLoad / waterBare
TOP_WATER = ([(f"water{i}", "waterBare", i, {"water_lv": i}) for i in range(1, 6)] +
             [(f"soak{i}", "waterLoad", i, {"water_lv": i, "clothes": True}) for i in range(1, 6)])
VARIANTS = {"washer": CLOTHES + TOP_WATER, "dryer": CLOTHES, "combo": CLOTHES + WATER}
WIDE = {"washer": washer, "dryer": dryer, "combo": combo}
