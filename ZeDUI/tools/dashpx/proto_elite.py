"""Prototype B: Dash Elite. Early 90s: one molded charcoal piece, an arched brow over a pill-shaped cluster,
no chrome, speed first (a 120 mph speedometer in the middle, the tach smaller), icon lamps, push-button climate."""
import math
import numpy as np
from engine import Dash, Mask, hx
from widgets import *

CAB = "v_charcoal"
d = Dash(800, 172, seed=21)
W, H = d.W, d.H
M = d.M


def arch(x0, x1, ytop, yend, n=60):
    """an elliptical top edge from (x0, yend) up to ytop at the middle and down to (x1, yend)"""
    cx = (x0 + x1) / 2; rx = (x1 - x0) / 2; ry = yend - ytop
    return [(cx + rx * math.cos(math.radians(a)), yend - ry * math.sin(math.radians(a))) for a in np.linspace(180, 0, n)]


# ------------------------------------------------------------------ silhouette: the arched brow flows into a lower console
top = arch(6, 500, 2, 30)
outline = [(6, 168)] + top + [(500, 30), (520, 24), (780, 24), (794, 36), (794, 168)]
body = M().poly(outline).get()
d.flat(body, 4.0, CAB, polish=0.12)
d.grain_pebble(body, 0.04, seed=3)
# the soft pad: the top 10 px of the brow, rounded over toward the windshield
pad = body & ~M().poly([(6, 168)] + [(x, y + 11) for x, y in top] + [(500, 41), (500, 168)]).get() & (d.XX < 500)
dd = edt(~pad)
d.h[pad] = 4.0 + 5.0 * np.clip((d.YY[pad] - 2) / 10.0, 0, 1) ** 0.6
d.mat[pad] = d.mid("v_charcoal"); d.polish[pad] = 0.25
cpad = body & (d.XX >= 500) & (d.YY < 32)
d.ramp_h(cpad, 2.0, 4.0, axis="y", a0=24, a1=32)
# the cluster opening: a pill, recessed, black, under the brow
face = M().rrect(28, 26, 444, 90, 34).get()
lip = M().rrect(24, 22, 452, 98, 38).get() & ~face
d.slab(lip, 2.0, "blackp", bevel=2.5, polish=0.3, on=7.0)
d.flat(face, -1.0, "face", polish=0.1)
glare(d, face, slope=-0.5, width=9, offset=0.08, amount=0.07)

# ------------------------------------------------------------------ gauges (printed rings, no chrome)
spd = gauge(d, 238, 70, 46, 135, 405, list(range(0, 121, 10)), minor=1,
            labels=["0", "", "20", "", "40", "", "60", "", "80", "", "100", "", "120"], bezel=None, depth=0.0, on=-1.0,
            label="MPH", label_y=86, hub=3.0)
ring = Mask(W, H).arc(238, 70, 47.5, 47.5, 0, 360, 1.0).get(); d.paint(ring & face, "paint_w")
tach = gauge(d, 98, 72, 34, 135, 375, list(range(0, 8)), minor=1, labels=[str(i) for i in range(8)], bezel=None, depth=0.0,
             on=-1.0, redzone=6, label="RPM", label2="X1000", label_y=82, hub=2.5)
ring = Mask(W, H).arc(98, 72, 35.5, 35.5, 0, 360, 1.0).get(); d.paint(ring & face, "paint_w")
# fuel: a half dial, E left F right (a0 150 -> a1 30 going over the top means sweeping counter-clockwise; use 210..330)
temp = None
d.paint(Mask(W, H).arc(366, 58, 23.5, 23.5, 200, 340, 1.0).get() & face, "paint_w")
d.text("E", 346, 52, "paint_r"); d.text("F", 384, 52, "paint_w")
d.paint(icon_mask(d, "fuel", 364, 64), "paint_c", flatlight=True)
fuel = {"cx": 366, "cy": 58, "r0": -3, "r1": 19, "a0": 210, "a1": 330}
d.paint(Mask(W, H).arc(428, 58, 23.5, 23.5, 200, 340, 1.0).get() & face, "paint_w")
d.text("C", 408, 52, "paint_w"); d.text("H", 446, 52, "paint_r")
d.paint(icon_mask(d, "temp", 426, 63), "paint_c", flatlight=True)
temp = {"cx": 428, "cy": 58, "r0": -3, "r1": 19, "a0": 210, "a1": 330}
for an in (fuel, temp):
    for i in range(5):
        a = 210 + 120 * i / 4
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        m = line_mask(d, an["cx"] + ca * 19, an["cy"] + sa * 19, an["cx"] + ca * 22, an["cy"] + sa * 22, 1.0)
        d.paint(m & face, "paint_w")
    d.dome(an["cx"], an["cy"], 2.2, 2.2, 1.8, "blackp", polish=0.9, on=-1.0)
# icon lamps (unlit lens tint) in a strip under fuel/temp
LAMPS = [("arrow_l", "#3cff6a"), ("beam", "#4aa8ff"), ("batt", "#ff3a20"), ("oil", "#ff3a20"), ("brake", "#ff3a20"), ("engine", "#ffb02e"), ("arrow_r", "#3cff6a")]
lamps = []
lx = 340
for name, col in LAMPS:
    iw, ih = icon_size(name)
    m = icon_mask(d, name, lx, 92 - ih // 2)
    d.paint(m, "lampoff", flatlight=True)
    lamps.append({"name": name, "ink": m, "color": col})
    lx += iw + 5
# trip LCD in the speedometer
lcd = window(d, 220, 94, 38, 11, 0.6, bezel=None, face="lens", r=1, on=-1.0, lens=False)

# ------------------------------------------------------------------ lower dash: rotary lights, ignition, rockers, buttons
lt = knob(d, 38, 140, 10, mat="blackp", on=4.0, z=3.0, knurl=True, pointer=225)
d.paint(icon_mask(d, "headlamp", 29, 152), "paint_w", flatlight=True)
d.text("OFF", 22, 126, "paint_w", align="c"); d.paint(icon_mask(d, "beam", 49, 124), "paint_w", flatlight=True)
d.torus(84, 140, 7, 9.5, 1.6, "blackp", polish=0.6, on=4.0)
ig = np.hypot(d.XX + 0.5 - 84, d.YY + 0.5 - 140) < 7
d.h[ig] = 4.6; d.mat[ig] = d.mid("alu"); d.polish[ig] = 0.8
slot = np.zeros((H, W), bool); slot[136:145, 83:85] = True; d.seam(slot, 0.8)
d.text("LOCK", 84, 126, "paint_w", align="c")
for i, ic in enumerate(("hazard", "defrost", "wiper")):
    rocker(d, 116 + i * 22, 130, 16, 22, on=4.0, up=(i != 1), icon=ic, icon_mat="paint_r" if ic == "hazard" else "paint_w")
lockB = button(d, 196, 133, 22, 14, None, mat="blackp", on=4.0, r=3)
d.paint(icon_mask(d, "lock", 205, 137), "paint_w", flatlight=True)
trunkB = button(d, 226, 133, 34, 14, "TRUNK", mat="blackp", on=4.0, r=3)
cruiseB = button(d, 268, 133, 40, 14, "CRUISE", mat="blackp", on=4.0, r=3, led=(302, 135))
# a long soft vent sweeping under the cluster
vent = M().rrect(330, 128, 150, 26, 12).get()
d.slab(vent, 1.0, "blackp", bevel=2.0, polish=0.2, on=4.0)
for k in range(132, 151, 3):
    lm = vent & (d.YY == k) & (d.XX > 338) & (d.XX < 472)
    d.seam(lm, 0.5)

# ------------------------------------------------------------------ console: Premium CD receiver, push-button climate
cf = M().rrect(506, 34, 280, 128, 10).get()
d.slab(cf, 1.0, "blackp", bevel=3.0, polish=0.2, on=3.0)
d.grain_pebble(cf, 0.035, seed=9)
for vx in (514, 690):
    v = M().rrect(vx, 40, 88, 18, 8).get()
    d.well(v, 2.5, "blackp", bevel=1.5)
    for k in range(44, 56, 3):
        d.cyl(vx + 6, k, 76, 2, 1.2, "blackp", axis="h", polish=0.3, on=2.0, mask=v)
hu = (562, 64, 178, 46)
hx0, hy0, hw, hh = hu
op = M().rect(hx0 - 2, hy0 - 2, hw + 4, hh + 4).get()
d.well(op, 2.0, "rubber", bevel=0.6)
plate = M().rect(hx0, hy0, hw, hh).get()
d.flat(plate, 2.4, "blackp", polish=0.4)
knob(d, hx0 + 12, hy0 + 14, 7, mat="alu", on=2.4, z=3.0, pointer=240)
knob(d, hx0 + hw - 13, hy0 + 14, 7, mat="alu", on=2.4, z=3.0, pointer=300)
d.text("VOL", hx0 + 12, hy0 + 25, "paint_w", align="c"); d.text("TUNE", hx0 + hw - 13, hy0 + 25, "paint_w", align="c")
disp = window(d, hx0 + 28, hy0 + 4, 122, 19, 1.2, bezel=None, face="lens", r=1, on=2.4, lens=False)
d.text("PREMIUM TECHNOLOGIES", hx0 + 89, hy0 + 26, "paint_c", align="c")
cd = M().rect(hx0 + 30, hy0 + 33, 118, 3).get(); d.well(cd, 1.2, "rubber", bevel=0.5)
for i in range(6):
    button(d, hx0 + 29 + i * 20, hy0 + 38, 17, 6, None, mat="blackp", on=2.4, z=1.2, r=1)
    d.text(str(i + 1), hx0 + 37 + i * 20, hy0 + 39, "paint_w", align="c") if False else None
# climate: LCD and two rows of buttons, a fan knob
clcd = window(d, 520, 122, 46, 22, 1.0, bezel=None, face="lcd", r=2, on=4.0, lens=False)
cl = {}
for i, (lab, key) in enumerate((("TEMP-", "tempdn"), ("TEMP+", "tempup"), ("A/C", "ac"), ("AUTO", "auto"))):
    cl[key] = button(d, 576 + i * 36, 120, 32, 11, lab, mat="blackp", on=4.0, r=3, led=(603 + i * 36, 122) if key in ("ac", "auto") else None)
for i, (lab, key) in enumerate((("FAN-", "fandn"), ("FAN+", "fanup"), ("DEF", "def"), ("OFF", "off"))):
    cl[key] = button(d, 576 + i * 36, 136, 32, 11, lab, mat="blackp", on=4.0, r=3)
d.text("AUTOMATIC CLIMATE CONTROL", 646, 152, "paint_c", align="c")
# nameplate: printed on the console top
d.text("DASH ELITE", 646, 27, "paint_w", align="c", scale=1)

plate_img = d.render()
plate_img.save("elite_plate.png")
# ------------------------------------------------------------------ preview of the live parts
needle(d, spd, 34 / 120, color="#ff5a2a", edge=None); needle(d, tach, 0.75 / 7, color="#ff5a2a")
needle(d, fuel, 0.7, color="#ff5a2a"); needle(d, temp, 0.48, color="#ff5a2a")
for lp in lamps:
    if lp["name"] in ("beam",): d.glow(lp["ink"], lp["color"])
# trip LCD
for i, ch in enumerate("1234"):
    seg_digit(d, ch, 225 + i * 7, 96, 5, 7, "#62ff8a", "#0c2414", t=1)
d.glow(np.zeros((H, W), bool), "#000000")
# radio VFD
x = hx0 + 66
for ch in "101.2":
    if ch == ".":
        m = np.zeros((H, W), bool); m[hy0 + 17:hy0 + 19, x + 1:x + 3] = True; d.glow(m, "#5ff2ff"); x += 5; continue
    seg_digit(d, ch, x, hy0 + 7, 8, 12, "#5ff2ff", "#0e2a33", t=2); x += 11
dot_text(d, "FM", hx0 + 34, hy0 + 8, "#5ff2ff"); dot_text(d, "KNOXTALK", hx0 + 34, hy0 + 15, "#5ff2ff") if False else None
dot_text(d, "MHZ", hx0 + 124, hy0 + 15, "#5ff2ff")
# climate LCD
seg_digit(d, "7", 526, 126, 7, 12, "#1c2418", None, t=2); seg_digit(d, "2", 536, 126, 7, 12, "#1c2418", None, t=2)
dot_text(d, "AUTO", 548, 127, "#1c2418"); dot_text(d, "F", 548, 135, "#1c2418")
lcdbg = np.zeros((H, W), bool)
for led in (cl["auto"]["led"], cruiseB["led"]):
    lx_, ly_, lw_, lh_ = led; m = np.zeros((H, W), bool); m[ly_:ly_ + lh_, lx_:lx_ + lw_] = True; d.glow(m, "#7aff6a")
preview = d.render()
preview.save("elite_live.png")
print("ok")
