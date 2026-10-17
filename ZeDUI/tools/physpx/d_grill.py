"""The propane grill: the game's Jorge Foreguy (its propane barbecue tiles), as a 1993 cart grill.

The game's state: lit or not, a tank in the cart or not, the tank's gas (minutes; a full tank is 1200). Live:
the three burner knobs' pointers (the game lights the grill as one), the lid thermometer, the flames' glow under
the hood, the tank gauge, and the tank itself (a state sprite: click the cart to put a tank in or take it out).
The centre knob and the red igniter light it or shut it off.
"""
import numpy as np

from physlib import *            # noqa: F401,F403
import wear as WR
from engine import add_ramp

add_ramp("brass", "#a8883e")
add_ramp("tank_white", "#d8d8d2", light=1.1)


def state(lit=False, tank=True, gas=0.7, **kw):
    s = dict(lit=lit, tank=tank, tankF=(gas if tank else 0.0), grillTemp=(0.74 if lit else 0.04))
    s.update(kw)
    return s


def thermometer(p, cx, cy, r, on):
    """the lid thermometer: a bright bezel, a white face with WARM, IDEAL and HOT; the needle is live"""
    d = p.d
    fm = disc(d, cx, cy, r)
    d.h[fm] = on - 1.0; d.mat[fm] = d.mid("cream"); d.solid |= fm; d.polish[fm] = 0.3; d.tex[fm] = 0
    d.torus(cx, cy, r - 0.3, r + 2.4, 2.0, "chrome", polish=1.0, on=on)
    a0, a1 = 160, 380
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ang = (np.degrees(np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)) - a0) % 360
    band = fm & (rr >= r - 4.2) & (rr <= r - 1.2)
    for lo, hi, mat in ((0, 80, "paint_b"), (80, 160, "paint_g"), (160, 220, "paint_r")):
        d.paint(band & (ang >= lo) & (ang < hi), mat, flatlight=True)
    d.text("HOT", int(cx + 1), int(cy + r * 0.30), "paint_k", align="c", flatlight=True)
    glare(d, fm, slope=-0.6, width=max(3, r // 3), offset=0.22, amount=0.07)
    d.dome(cx, cy, 1.6, 1.6, 1.0, "blackp", polish=0.9, on=on - 1.0)
    return {"cx": cx, "cy": cy, "r0": -2, "r1": r - 4, "a0": a0, "a1": a1}


def jorge(tank=False, worn=True):
    W, H = 456, 156
    p = Plate("grill_propane", W, H, seed=71, title="propane grill")
    d = p.d
    # the side shelves' front boards
    for sx in (0, 436):
        for k in range(2):
            b = Mask(W, H).rrect(sx, 47 + k * 6, 20, 5, 1).get()
            d.slab(b, 2.0, "walnut", bevel=1.0, polish=0.3, on=Z_FACE - 1.0)
            d.grain_wood(b, scale=0.6, seed=72 + k)
    # the cart under the grill
    cart = Mask(W, H).rrect(24, 102, W - 48, H - 102, 2).get()
    d.slab(cart, Z_FACE - 0.5, "enamel_black", bevel=1.5, polish=0.5)
    opening = Mask(W, H).rrect(140, 110, 176, H - 110 + 4, 2).get()
    d.well(opening, 3.0, "blackp", bevel=1.2)
    door = Mask(W, H).rrect(326, 110, 98, H - 112, 2).get()
    d.slab(door, 0.8, "enamel_black", bevel=1.0, polish=0.55, on=Z_FACE - 0.5)
    d.cyl(340, 126, 4, 14, 1.8, "chrome", axis="v", polish=1.0, on=Z_FACE + 0.3)
    # the tank's gauge, mounted on the cart
    gx, gy = 82, 130
    gan = fuel_gauge(p, gx, gy, 14, on=Z_FACE - 0.5, label=None)
    p.part("needle", src="tankF", color="#d42a1c", w=1, hub=2, **gan)
    p.label("TANK", gx, gy + 18, "paint_w", align="c", auto_ink=False, check=False)
    p.hit("gauge", gx - 14, gy - 14, 28, 28, kind="look")
    # the tank, or the empty shelf and the hanging regulator
    if tank:
        # a cylinder standing in the cart: round in section (lit down its middle), domed shoulders
        t = Mask(W, H).rrect(186, 116, 84, H - 110, 26).get() & (d.YY >= 116)
        d.cyl(186, 116, 84, H - 116, 7.0, "tank_white", axis="v", polish=0.5, on=Z_FACE - 3.5, mask=t)
        d.h[t] += (np.clip((d.YY[t] - 116) / 14.0, 0, 1) ** 0.5 * 2.0 - 2.0).astype(np.float32)
        collar = Mask(W, H).rrect(196, 112, 64, 22, 4).get() & ~Mask(W, H).rrect(204, 118, 18, 10, 3).get() \
            & ~Mask(W, H).rrect(234, 118, 18, 10, 3).get()
        d.slab(collar, 1.6, "tank_white", bevel=1.0, polish=0.5, on=Z_FACE + 1.0)
        d.dome(228, 128, 5, 3, 3.0, "brass", polish=0.9, on=Z_FACE + 1.0)
        d.torus(228, 121, 3.0, 6.0, 1.6, "brass", polish=0.9, on=Z_FACE + 3.0)
        d.cyl(226, 100, 4, 21, 2.4, "cord", axis="v", polish=0.6, on=Z_FACE + 2.0)
    else:
        d.cyl(226, 100, 4, 30, 2.4, "cord", axis="v", polish=0.6, on=Z_FACE - 2.0)
        d.dome(228, 134, 5, 4, 2.4, "brass", polish=0.9, on=Z_FACE - 3.0)
    p.hit("tank", 140, 110, 176, H - 110)
    # the control panel: brushed stainless
    panel = Mask(W, H).rrect(22, 48, W - 44, 54, 2).get()
    d.slab(panel, Z_FACE, "alu", bevel=1.6, polish=0.6); d.grain_brushed(panel, 0.045, seed=73)
    # the maker's badge
    badge = Mask(W, H).rrect(34, 62, 94, 18, 6).get()
    d.slab(badge, 1.2, "enamel_black", bevel=1.0, polish=0.8, on=Z_FACE)
    nameplate(d, "JORGE FOREGUY", 81, 67, on=Z_FACE + 1.2, mat="chrome", font="57", align="c", z=1.0)
    p.label("GAS GRILL", 81, 86, "paint_k", align="c")
    # the three burners: the game lights them as one; the centre knob is the one that takes a hand
    for i, kx in enumerate((168, 238, 308)):
        fluted_knob(p, kx, 75, 11, on=Z_FACE, z=4.2, mat="blackp", skirt=1.8, skirt_mat="chrome", ridges=18, dome=0.7 if worn else 0)
        scale_ring(p, kx, 75, 15.0, [-90, 180, 45], ["OFF", "HI", "LO"], minor_angles=[150, 120, 90, 67], wear=0.15 if worn else 0)
        p.part("ptr", src="lit", cx=kx, cy=75, r0=2, r1=9, angles=[-90, 180], color="#f2efe6", w=1)
        p.hit("burner" if i == 1 else f"burner{i}", kx - 14, 61, 28, 28, kind="press" if i == 1 else "look")
    # the igniter
    ix, iy = 380, 72
    d.torus(ix, iy, 5.4, 7.4, 1.6, "chrome", polish=1.0, on=Z_FACE)
    d.dome(ix, iy, 5.4, 5.4, 3.4, "paint_r", polish=0.8, on=Z_FACE, power=0.6)
    p.label("IGNITE", ix, 84, "paint_k", align="c")
    p.hit("ignite", ix - 8, iy - 8, 16, 16)
    # the hood: black porcelain over the panel, its thermometer, its handle; the flames glow in the gap under it
    gap = rbox(d, 30, 44, W - 60, 4)
    d.flat(gap, Z_FACE - 2.5, "blackp", polish=0.2)
    p.lamp(rbox(d, 34, 45, W - 68, 2), "lit", "#ff8a2a", halo=False)
    hood = Mask(W, H).rrect(26, -8, W - 52, 52, 10).get()
    d.slab(hood, Z_FACE + 2.0, "enamel_black", bevel=5.0, polish=0.85, power=0.5)
    HZ = Z_FACE + 2.0
    # cast end caps on the hood, and the lid's curve catching the light along its top
    for ex0 in (26, W - 26 - 16):
        cap = hood & rbox(d, ex0, -8, 16, 52)
        d.mat[cap] = d.mid("steel"); d.polish[cap] = 0.5
        d.seam(hood & rbox(d, ex0 + (15 if ex0 == 26 else 0), 0, 1, 44), 0.5)
    d.tex[hood & (d.YY >= 5) & (d.YY <= 6) & (d.mat == d.mid("enamel_black"))] += 0.16
    tan = thermometer(p, 228, 19, 15, on=HZ)
    p.part("needle", src="grillTemp", color="#1b1b1d", w=1, hub=1.6, **tan)
    p.hit("thermo", 214, 5, 28, 28, kind="look")
    for sx in (124, 326):
        d.slab(Mask(W, H).rrect(sx, 34, 6, 7, 1).get(), 2.0, "chrome", bevel=1.0, polish=1.0, on=HZ)
    d.cyl(120, 36, 216, 5, 3.4, "chrome", axis="h", polish=1.0, on=HZ + 1.0)
    if worn:
        hood_m = WR.mat_mask(d, "enamel_black")
        WR.gloss(d, hood_m & (d.YY < 46), band=(0.5, 90, 10, 0.12))
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 120, 30, 0.07, 340, 434, 0.025)
        WR.grime(d, d.solid, amount=0.36, seed=74)
        WR.specks(d, hood_m, 0.004, seed=75, amount=-0.2)
        WR.scuffs(d, WR.mat_mask(d, "alu"), 0.0015, seed=76, amount=-0.08)
    return p
