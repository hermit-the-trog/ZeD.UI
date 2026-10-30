"""The laundry machines (director, Oct 30 2026: "Washer and dryer I trust you. Do those so we can ship that too."):
three faces for the game's three laundry objects, full card, at every width the machine plates come in (336, 392,
450, 562) and the 200 px narrow face.

  washer   IsoClothingWasher           Premium Technologies front-loader: needs power and water
  dryer    IsoClothingDryer            Premium Technologies dryer, the washer's pair: needs power
  combo    IsoCombinationWasherDryer   ValuTech compact washer-dryer: power; water in its washer mode

Drawn from the game's laundry model (appliances_laundry_P1_00: white enamel, a blue plastic control panel, a chrome-ringed
glass door) and the game's own brands (m_brands). What the game lets you do with them is small, and the faces offer
exactly that, nothing for show that a player would try to turn: power on and off (the game's toggle; the washer and the
combination in its washer mode refuse without water), the combination's WASH / DRY mode, and the door, which opens the
machine's contents. What they show: the power lamp (green running, red no power), the water in the tub and a level
meter (the washer and the combination), the phase lamps of a running cycle (WASH RINSE SPIN, DRY COOL), FILL when the
washer has no water, and the clothes behind the glass when there are any (a sprite).

Live state (state() below): running, noPower, noWater, water 0..5, hasItems, modeWash / modeDry (the combination),
phWash / phRinse / phSpin / phDry / phCool (the phase lamps: Code steps them through a running cycle by the clock;
the game has no phases of its own), drumF 0..1 (the drum's baffle, turned by the clock while running).
W is the plate's width; W < 300 is the narrow face."""
import math

import numpy as np
from scipy import ndimage as ndi

from physlib import *            # noqa: F401,F403
import wear as WR
from engine import add_ramp
import d_props as PR
import m_brands as MB

add_ramp("lb_blue", "#4f74a8", light=1.05)       # the model's blue panel
add_ramp("lb_blue_dk", "#2f4a74")
add_ramp("lb_white", "#e9e7e0", light=1.06)      # the model's white enamel
add_ramp("lb_grey", "#b9bcc0", light=1.06)       # the combination's light grey panel
add_ramp("drum", "#5d6268", light=1.1)           # the steel drum behind the glass
add_ramp("water_lo", "#3a6ea8")

NARROW = 300


def _geom(W):
    narrow = W < NARROW
    H = 196 if narrow else int(round(W * 0.70))
    ph = 52 if narrow else 40                       # the control panel's height
    return narrow, H, ph


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
    for i in range(-1, 2):                          # the power mark pressed into its cap
        pass
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
    xs = []
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


CLOTH = ("cl_denim", "cl_red", "lb_white", "cl_khaki", "cl_green")
add_ramp("cl_denim", "#3e5a86")
add_ramp("cl_red", "#a8352e")
add_ramp("cl_khaki", "#b59a5a")
add_ramp("cl_green", "#56704a")


def load(p, inside, cx, cy, r, z, seed):
    """a load of washing heaped in the bottom of the drum: five cloths, each a lumpy shape with its fold lines, in
    everyday clothing colours, the front ones over the back"""
    d = p.d
    rng = np.random.default_rng(seed)
    spots = ((-0.42, 0.50, 0.36, 0.22), (0.30, 0.58, 0.40, 0.22), (0.02, 0.40, 0.34, 0.20), (0.52, 0.30, 0.24, 0.17),
             (-0.20, 0.66, 0.42, 0.18))
    ang = np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)
    for i, (dx, dy, rx, ry) in enumerate(spots):
        ox, oy = cx + dx * r, cy + dy * r
        a = np.arctan2(d.YY + 0.5 - oy, d.XX + 0.5 - ox)
        k = rng.uniform(0, 6.28, 3)
        wob = 1 + 0.16 * np.sin(3 * a + k[0]) + 0.10 * np.sin(5 * a + k[1])
        m = inside & ((((d.XX + 0.5 - ox) / (rx * r)) ** 2 + ((d.YY + 0.5 - oy) / (ry * r)) ** 2) <= wob ** 2)
        if not m.any(): continue
        d.slab(m, 1.4, CLOTH[i % len(CLOTH)], bevel=1.2, polish=0.15, on=z + 0.2 * i)
        # a fold or two: short dark arcs across the cloth
        for j in range(2):
            fy = oy + (j - 0.5) * ry * r * 0.7
            fold = m & (np.abs(d.YY + 0.5 - fy - 0.25 * (d.XX + 0.5 - ox) * (0.4 if j else -0.3)) < 0.6) & \
                (np.abs(d.XX + 0.5 - ox) < rx * r * 0.40)
            d.seam(fold, 0.22)


def porthole(p, cx, cy, R, kind="washer", clothes=False, water=True):
    """the door: a white plastic ring on a chrome rim, the glass, the drum behind it (its perforations and one baffle,
    which turns while running: ptr drumF), the water in it (the washer: part bars, slices of the glass from the bottom
    up), the clothes when there are any (the variant), the handle at the right"""
    d = p.d
    zr = Z_FACE
    # the ring and the rim
    d.torus(cx, cy, R - 6, R, 2.6, "lb_white", polish=0.7, on=zr)
    d.torus(cx, cy, R - 8, R - 5, 1.6, "chrome", polish=1.0, on=zr + 1.0)
    gR = R - 8
    glass = disc(d, cx, cy, gR)
    # the drum behind the glass: dark steel, its holes in rings
    d.flat(glass, zr - 3.0, "drum", polish=0.4)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ang = np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)
    holes = glass & (rr < gR - 3) & ((np.round(rr) % 4) == 0) & ((np.round(ang * rr / 3.0) % 2) == 0)
    d.paint(holes, "hole", flatlight=True)
    d.seam(ring(d, cx, cy, gR * 0.20, gR * 0.20 + 1) & glass, 0.4)          # the drum's back: its hub ring
    if clothes:
        load(p, glass, cx, cy, gR, zr - 2.6, 7 if kind == "washer" else 9)
    if water:
        # the water: slices of the glass from the bottom, the lowest first (bars: the game's fluid against capacity)
        n = 5
        bars = []
        top = cy + gR; step = (gR * 1.1) / n
        for i in range(n):
            y1 = top - i * step; y0 = top - (i + 1) * step
            # every other row: the water seen through, the drum and the load under it (rows, not a checker: one rect
            # a row keeps the part small in PhysPx.lua)
            m = glass & (d.YY + 0.5 >= y0) & (d.YY + 0.5 < y1) & ((d.YY % 2) == 0)
            bars.append(runs_of(m))
        p.part("bars", src="water", max=5, bars=bars, color="#4f8fd0")
    # the baffle: one ridge on the drum, turned by the game's clock while running
    p.part("ptr", src="drumF", cx=cx, cy=cy, r0=gR * 0.55, r1=gR * 0.92, a0=-90, a1=270, color="#9aa1a8", w=2)
    # the glass over it all: one glare arc
    glare = glass & (rr > gR - 5) & (rr < gR - 3) & (ang > -2.6) & (ang < -1.6)
    d.paint(glare, "chrome", flatlight=True)
    # the handle: a recessed grip at the ring's right
    hx = int(cx + R - 3)
    d.well(Mask(d.W, d.H).rrect(hx - 2, int(cy - 9), 5, 18, 2).get(), 1.4, "lb_white", bevel=1.0)
    p.hit("door", cx - R, cy - R, 2 * R, 2 * R)
    return glass


# =================================================================================== the washer
def washer(W=392, worn_=True, clothes=False):
    """Premium Technologies front-loading washer (IsoClothingWasher)"""
    narrow, H, ph = _geom(W)
    p = Plate("washer" + ("_n" if narrow else ""), W, H, seed=501, title="Premium Technologies washer")
    d = p.d
    body(p, W, H)
    py = 8
    zp = panel(p, W, py, ph)
    kick_y = kick(p, W, H)
    # the detergent drawer at the panel's left: the brand on its face, a finger pull under it
    dw_, dh_ = (64 if not narrow else 60), (ph - 10 if not narrow else 22)
    dx_, dy_ = 14, py + 5
    dr = Mask(W, H).rrect(dx_, dy_, dw_, dh_, 2).get()
    d.slab(dr, 1.4, "lb_white", bevel=1.0, polish=0.6, on=zp)
    d.well(Mask(W, H).rrect(dx_ + 8, dy_ + dh_ - 6, dw_ - 16, 3, 1).get(), 0.8, "lb_white", bevel=0.5)
    p.label("PREMIUM", dx_ + dw_ // 2, dy_ + 4, "lb_blue_dk", align="c", auto_ink=False)
    p.label("TECHNOLOGIES", dx_ + dw_ // 2, dy_ + 10, "lb_blue_dk", align="c", auto_ink=False)
    # power at the panel's right
    bx = W - 16 - 10
    by = py + (16 if not narrow else 14)
    power_button(p, bx, by, zp)
    if not narrow: cycle_gauge(p, bx - 46, py + 15, 11, zp)
    else: cycle_gauge(p, W - 28, py + 40, 8, zp, label=False)
    if not narrow: p.label("AUTOMATIC WASHER", 14, py + ph + 8, "lb_grey", auto_ink=False)
    # the phase lamps and FILL, the water meter
    legends = [("WASH", "phWash"), ("RINSE", "phRinse"), ("SPIN", "phSpin")]
    if not narrow:
        x0 = dx_ + dw_ + 12
        ww = phase_window(p, x0, py + 8, legends, zp, extra=("FILL", "noWater"))
        water_meter(p, x0, py + 25, zp)
    else:
        x0 = 14
        phase_window(p, x0, py + 31, legends, zp, extra=("FILL", "noWater"))
        water_meter(p, dx_ + dw_ + 10, py + 9, zp)
    # the door
    top = py + ph + 6
    R = int(min((kick_y - 4 - top) / 2, W * 0.25))
    cx, cy = W // 2, top + (kick_y - 4 - top) // 2
    porthole(p, cx, cy, R, "washer", clothes=clothes, water=True)
    if worn_:
        WR.grime(d, d.solid, amount=0.16, seed=503)
        WR.scuffs(d, WR.mat_mask(d, "lb_white") & (d.YY > H - 30), 0.003, seed=504, amount=-0.06)
    return p


# =================================================================================== the dryer
def dryer(W=392, worn_=True, clothes=False):
    """Premium Technologies dryer (IsoClothingDryer), the washer's pair: a solid door with a smoked window"""
    narrow, H, ph = _geom(W)
    p = Plate("dryer" + ("_n" if narrow else ""), W, H, seed=511, title="Premium Technologies dryer")
    d = p.d
    body(p, W, H)
    py = 8
    zp = panel(p, W, py, ph)
    kick_y = kick(p, W, H, louvres=True)
    # the brand on a white plate at the panel's left, where the washer has its drawer
    dw_, dh_ = (64 if not narrow else 60), (ph - 10 if not narrow else 22)
    dx_, dy_ = 14, py + 5
    d.slab(Mask(W, H).rrect(dx_, dy_, dw_, dh_, 2).get(), 0.8, "lb_white", bevel=0.8, polish=0.5, on=zp)
    p.label("PREMIUM", dx_ + dw_ // 2, dy_ + (dh_ - 12) // 2, "lb_blue_dk", align="c", auto_ink=False)
    p.label("TECHNOLOGIES", dx_ + dw_ // 2, dy_ + (dh_ - 12) // 2 + 6, "lb_blue_dk", align="c", auto_ink=False)
    bx = W - 16 - 10
    by = py + (16 if not narrow else 14)
    power_button(p, bx, by, zp)
    if not narrow: cycle_gauge(p, bx - 46, py + 15, 11, zp)
    else: cycle_gauge(p, W - 28, py + 40, 8, zp, label=False)
    if not narrow: p.label("AUTOMATIC DRYER", 14, py + ph + 8, "lb_grey", auto_ink=False)
    legends = [("DRY", "phDry"), ("COOL", "phCool")]
    if not narrow:
        x0 = dx_ + dw_ + 12
        phase_window(p, x0, py + 8, legends, zp)
        lamp_text(p, "HEAT", x0, py + 26, "running", "#ff6a3a", off="lb_blue_dk")
    else:
        x0 = dx_ + dw_ + 10
        phase_window(p, x0, py + 8, legends, zp)
        lamp_text(p, "HEAT", 14, py + 33, "running", "#ff6a3a", off="lb_blue_dk")
    # the door: white, round, a smoked window in it; the lint screen's slot under it
    top = py + ph + 6
    R = int(min((kick_y - 4 - top) / 2, W * 0.25))
    cx, cy = W // 2, top + (kick_y - 4 - top) // 2
    d.torus(cx, cy, R - 2, R, 1.6, "chrome", polish=1.0, on=Z_FACE)
    door = disc(d, cx, cy, R - 2)
    d.slab(door, 2.2, "lb_white", bevel=1.6, polish=0.7, on=Z_FACE)
    wR = int(R * 0.62)
    win = disc(d, cx, cy, wR)
    d.flat(win, Z_FACE - 2.0, "drum", polish=0.4)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ang = np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)
    d.paint(win & (rr < wR - 2) & ((np.round(rr) % 4) == 0) & ((np.round(ang * rr / 3.0) % 2) == 0), "hole", flatlight=True)
    d.seam(ring(d, cx, cy, wR * 0.22, wR * 0.22 + 1) & win, 0.4)
    if clothes:
        load(p, win, cx, cy, wR, Z_FACE - 1.8, 11)
    p.part("ptr", src="drumF", cx=cx, cy=cy, r0=wR * 0.5, r1=wR * 0.9, a0=-90, a1=270, color="#9aa1a8", w=2)
    d.torus(cx, cy, wR, wR + 2, 1.0, "chrome", polish=1.0, on=Z_FACE + 2.2)
    d.paint(win & (rr > wR - 4) & (rr < wR - 2) & (ang > -2.6) & (ang < -1.6), "chrome", flatlight=True)
    # the handle: a bar across the door's right
    hx = int(cx + R * 0.72)
    d.slab(Mask(W, H).rrect(hx - 2, int(cy - R * 0.32), 5, int(R * 0.64), 2).get(), 1.4, "lb_white", bevel=1.0, polish=0.7,
           on=Z_FACE + 2.2)
    p.hit("door", cx - R, cy - R, 2 * R, 2 * R)
    if worn_:
        WR.grime(d, d.solid, amount=0.16, seed=513)
        WR.scuffs(d, WR.mat_mask(d, "lb_white") & (d.YY > H - 30), 0.003, seed=514, amount=-0.06)
    return p


# =================================================================================== the combination
def combo(W=392, worn_=True, clothes=False):
    """ValuTech compact washer-dryer (IsoCombinationWasherDryer): grey panel, the mode keys WASH and DRY (their lamps),
    the washer's phase lamps and FILL, DRY and COOL, the water meter, power"""
    narrow, H, ph = _geom(W)
    p = Plate("combo" + ("_n" if narrow else ""), W, H, seed=521, title="ValuTech washer-dryer")
    d = p.d
    body(p, W, H)
    py = 8
    zp = panel(p, W, py, ph, mat="lb_grey")
    kick_y = kick(p, W, H)
    MB.valutech_logo(p, 14 + 36, py + 6)
    # the mode keys: two push keys under the logo, each with its lamp
    ky = py + 18
    for i, (t, src, mid) in enumerate((("WASH", "modeWash", "mode"), ("DRY", "modeDry", "mode"))):
        kx = 14 + i * 37
        PR.radio_key(p, f"mode_{t.lower()}", kx, ky, 34, 12, t, mat="lb_white", lab_mat="paint_k", z=1.4)
        lx = kx + 30
        d.dome(lx, ky - 3, 1.6, 1.6, 0.8, "jewel_off", polish=0.9, on=zp)
        p.lamp(disc(d, lx, ky - 3, 1.5), src, "#7dff9a")
    # the two keys are one control in the game (set the other mode): both ask for it, Code sends the mode named
    for h in p.hits:
        if h["id"] in ("mode_wash", "mode_dry"): h["needs"] = "powered"
    bx = W - 16 - 10
    by = py + (16 if not narrow else 14)
    power_button(p, bx, by, zp, ink="paint_k")
    if not narrow: cycle_gauge(p, bx - 46, py + 15, 11, zp, ink="paint_k")
    else: cycle_gauge(p, W - 28, py + 40, 8, zp, label=False)
    if not narrow: p.label("WASHER-DRYER", 14, py + ph + 8, "lb_grey", auto_ink=False)
    legends = [("WASH", "phWash"), ("RINSE", "phRinse"), ("SPIN", "phSpin"), ("DRY", "phDry"), ("COOL", "phCool")]
    if not narrow:
        x0 = 14 + 2 * 37 + 8
        phase_window(p, x0, py + 8, legends, zp, extra=("FILL", "noWater"))
        water_meter(p, x0, py + 25, zp, ink="paint_k")
    else:
        phase_window(p, 14, py + 34, legends, zp, extra=("FILL", "noWater"))
        water_meter(p, 14 + 2 * 37 + 6, py + 9, zp, ink="paint_k")
    top = py + ph + 6
    R = int(min((kick_y - 4 - top) / 2, W * 0.25))
    cx, cy = W // 2, top + (kick_y - 4 - top) // 2
    porthole(p, cx, cy, R, "combo", clothes=clothes, water=True)
    if worn_:
        WR.grime(d, d.solid, amount=0.18, seed=523)
        WR.scuffs(d, WR.mat_mask(d, "lb_white") & (d.YY > H - 30), 0.003, seed=524, amount=-0.06)
    return p


def state(kind, running=False, powered=True, water=5, items=False, mode="wash", phase=None, drum=0.0):
    """the live state for the previews (and the names Code feeds): kind washer / dryer / combo"""
    wash_mode = kind == "washer" or (kind == "combo" and mode == "wash")
    s = dict(power=powered, running=running and powered, noPower=not powered, hasItems=items, drumF=drum,
             water=water if (kind != "dryer" and wash_mode) else 0,
             noWater=powered and wash_mode and kind != "dryer" and water <= 0)
    if kind == "combo": s.update(modeWash=powered and mode == "wash", modeDry=powered and mode == "dry")
    for ph_ in ("phWash", "phRinse", "phSpin", "phDry", "phCool"): s[ph_] = bool(running and powered and phase == ph_)
    return s


WIDE = {"washer": washer, "dryer": dryer, "combo": combo}
