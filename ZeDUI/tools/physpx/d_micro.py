"""The microwaves: the right of the door (its window over the perforated screen, cropped at the left) and the
control panel, each its era's. The game's microwave state: on or off, a power level (five), a timer, power.
While it runs, the oven lamp glows through the door's screen (a state sprite)."""
import numpy as np
from scipy import ndimage as ndi

from physlib import *            # noqa: F401,F403
import wear as WR

MW_POWERS = (50, 70, 90, 110, 130)


def state(text="10:08", power_i=4, cooking=False, powered=True, minutes=0, **kw):
    s = dict(mwText=text, mwPower=power_i + 1, mwPowerIdx=power_i, cooking=cooking and powered, power=powered,
             timerF60=min(1.0, minutes / 60.0))
    s.update(kw)
    return s


def door_and_case(p, W, H, case_mat, door_mat, cooking, frame_r=4, door_w=300):
    d = p.d
    case = Mask(W, H).rrect(-12, 0, W + 12, H, 7).get()
    d.slab(case, Z_FACE, case_mat, bevel=2.5, polish=0.6)
    DZ = Z_FACE + 1.0
    door = Mask(W, H).rrect(-12, 7, door_w, H - 14, frame_r).get()
    d.slab(door, 1.0, door_mat, bevel=1.5, polish=0.6, on=Z_FACE)
    mesh_window(p, 0, 19, door_w - 38, H - 38, r=4, on=DZ, depth=2.2, lit=cooking, crop_left=True)
    return case, door, DZ


# =================================================================================== white, 1990
def white(cooking=False, worn=True):
    """the touch panel: a red seven-segment readout (the time of day when idle, the cook time, the count down),
    COOK, the power level in five lamps, the pads (the number pads type the time like the real thing)"""
    W, H = 456, 168
    p = Plate("mw_white", W, H, seed=21, title="1990 touchpad microwave")
    d = p.d
    case, door, DZ = door_and_case(p, W, H, "enamel_white", "enamel_white", cooking)
    grip = Mask(W, H).rrect(271, 40, 7, H - 80, 3).get()
    d.well(grip, 1.4, "enamel_white", bevel=1.5)
    d.seam(rbox(d, 288, 7, 1, H - 14), 0.6)
    px0, py0, pw, ph = 296, 9, 150, H - 18
    PZ = Z_FACE - 0.4
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "pad_panel", polish=0.3)
    d.seam(panel & ~ndi.binary_erosion(panel, iterations=1), 0.35)
    cx = px0 + pw // 2
    p.label("VALUTECH", cx, 14, "paint_k", align="c", font="57")
    lx, ly, lw, lh = px0 + 9, 26, pw - 18, 28
    window_glass(p, lx, ly, lw, lh, face="ledglass", bezel="blackp", depth=1.4, on=PZ, r=1, bezel_t=2, lens=True)
    p.part("digits", src="mwText", x=lx + 18, y=ly + 6, cw=10, ch=16, pitch=14, st=2, n=5, color="#ff3b2a", ghost="#2c0a09",
           align="r")
    lamp_text(p, "COOK", lx + lw - 5, ly + 7, "cooking", "#ff3b2a", off="ledoff", align="r")
    by = ly + lh + 6
    p.label("POWER", px0 + 9, by, "paint_k")
    bars = []
    bx0 = px0 + 9 + text_w("POWER") + 6
    for i in range(5):
        m = rbox(d, bx0 + i * 12, by, 10, 5)
        d.well(m, 0.6, "ledoff", bevel=0.4)
        bars.append(runs_of(m))
    p.part("bars", src="mwPower", max=5, bars=bars, color="#ff3b2a")
    p.ink_rect(bx0, by, 58, 5, "power lamps")
    p.label("HI", bx0 + 62, by, "paint_k")
    gx0, gw, gap = px0 + 8, 42, 4
    y = by + 12
    used = {"start": 0.20, "d1": 0.12, "d3": 0.12, "d0": 0.14, "power": 0.08}
    def pad(id_, x, yy, w, h, a, b=None, ink="paint_k", font="35"):
        membrane_pad(p, x, yy, w, h, a, label2=b, lab_mat=ink, on=PZ, font=font, wear=used.get(id_, 0.0) if worn else 0.0)
        p.hit(id_, x, yy, w, h, needs="powered")
    pad("power", gx0, y, 65, 15, "POWER", "LEVEL", ink="paint_b")
    pad("timecook", gx0 + 69, y, 65, 15, "TIME", "COOK", ink="paint_b")
    y += 15 + 3
    for row in ((1, 2, 3), (4, 5, 6), (7, 8, 9)):
        for c, n in enumerate(row):
            pad(f"d{n}", gx0 + c * (gw + gap), y, gw, 13, str(n), font="57")
        y += 13 + 3
    pad("stop", gx0, y, gw, 15, "STOP", "CLEAR", ink="paint_r")
    pad("d0", gx0 + gw + gap, y, gw, 15, "0", font="57")
    pad("start", gx0 + 2 * (gw + gap), y, gw, 15, "START", ink="paint_g")
    if y + 15 > py0 + ph - 3: p.warn(f"pads run to {y + 15}, past the panel ({py0 + ph})")
    if worn:
        white_m = WR.mat_mask(d, "enamel_white")
        WR.gloss(d, white_m, band=(0.45, 330, 10, 0.08))
        WR.grime(d, d.solid, amount=0.24, seed=23)
        WR.scuffs(d, white_m & (d.YY > H - 20) & (d.XX < 288), 0.004, seed=24, amount=-0.09)
    return p


# =================================================================================== chrome, 1979
def chrome(cooking=False, worn=True):
    """a 1979 countertop microwave: a dark case, a bright brushed front; the power selector (WARM to HIGH), the
    wind-up timer (0 to 60 minutes), the COOK lamp and the START bar"""
    W, H = 456, 168
    p = Plate("mw_chrome", W, H, seed=22, title="1979 countertop microwave")
    d = p.d
    case, door, DZ = door_and_case(p, W, H, "steel", "alu", cooking)
    d.grain_brushed(door & (d.mat == d.mid("alu")), 0.035, seed=40)
    # the door's handle: a bright bar down its right edge
    d.cyl(270, 30, 8, H - 60, 3.0, "chrome", axis="v", polish=1.0, on=DZ)
    d.seam(rbox(d, 288, 7, 1, H - 14), 0.6)
    # the control panel
    px0, py0, pw, ph = 294, 8, 152, H - 16
    PZ = Z_FACE + 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.slab(panel, 0.6, "alu", bevel=1.0, polish=0.6, on=Z_FACE); d.grain_brushed(panel, 0.04, seed=41)
    p.label("TEMPO", px0 + 12, 14, "paint_k", font="57")
    p.label("MICROWAVE OVEN", px0 + 12, 24, "paint_k")
    jewel(p, 432, 18, 4.0, off="jewel_off", on=PZ)
    p.lamp(disc(d, 432, 18, 4.0), "cooking", "#ffa630")
    p.label("COOK", 422, 16, "paint_k", align="r")
    # the power selector: five settings, the game's five powers
    kx, ky = 373, 62
    PA = [135, 202.5, 270, 337.5, 405]
    fluted_knob(p, kx, ky, 13, on=PZ, z=4.4, mat="chrome", skirt=None, ridges=28, dome=0.6)
    scale_ring(p, kx, ky, 15.5, PA, ["WARM", "DEFROST", "SIMMER", "ROAST", "HIGH"], mat="paint_k", wear=0.08 if worn else 0)
    p.part("ptr", src="mwPowerIdx", cx=kx, cy=ky, r0=2, r1=11, angles=PA, color="#17181b", w=1)
    p.hit("power", kx - 16, ky - 16, 32, 32, needs="powered", kind="turn")
    # the wind-up timer: 0 to 60 minutes
    tx, ty = 373, 116
    fluted_knob(p, tx, ty, 12, on=PZ, z=4.4, mat="chrome", skirt=None, ridges=28, dome=0.6)
    ta = lambda m: -90 + 300 * m / 60
    scale_ring(p, tx, ty, 14.5, [ta(m) for m in (0, 15, 30, 45, 60)], ["0", "15", "30", "45", "60"],
               minor_angles=[ta(m) for m in range(5, 60, 5) if m % 15], mat="paint_k", wear=0.08 if worn else 0)
    p.part("ptr", src="timerF60", cx=tx, cy=ty, r0=2, r1=10, a0=-90, a1=210, color="#17181b", w=1)
    p.hit("timer", tx - 15, ty - 15, 30, 30, needs="powered", kind="turn")
    # START
    sb = Mask(W, H).rrect(px0 + 14, 145, pw - 28, 12, 3).get()
    d.slab(sb, 2.4, "chrome", bevel=1.4, polish=1.0, on=PZ)
    d.text("START", px0 + pw // 2, 149, "paint_k", align="c", flatlight=True)
    p.hit("start", px0 + 14, 145, pw - 28, 12, needs="powered")
    if worn:
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 200, 40, 0.06, 330, 446, 0.02)
        WR.grime(d, d.solid, amount=0.28, seed=42)
        WR.specks(d, WR.mat_mask(d, "steel"), 0.004, seed=43, amount=0.3)
    return p
