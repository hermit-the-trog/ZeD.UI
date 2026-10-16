"""Prototype C: Race car. RPM first: a big tach with a shift light, a small speedometer, oil/water/fuel;
a riveted aluminium panel, a padded cage bar across the top, toggles with label tape, sponsor decals."""
import math
import numpy as np
from engine import Dash, Mask, hx
from widgets import *

d = Dash(800, 172, seed=31)
W, H = d.W, d.H
M = d.M

# ------------------------------------------------------------------ the panel: brushed aluminium, riveted
panel = M().rrect(6, 12, 788, 156, 6).get()
d.flat(panel, 4.0, "alu", polish=0.55)
d.grain_brushed(panel, 0.11, seed=4)
edge = panel & (edt(panel) <= 2)
d.h[edge] = 3.0
dist = edt(panel)
d.dark[panel] = np.maximum(d.dark[panel], 0.10 * np.clip(1 - dist[panel] / 10.0, 0, 1))
for x in range(16, 790, 26):
    rivet(d, x, 18, on=4.0); rivet(d, x, 162, on=4.0)
for y in (44, 80, 116, 140):
    rivet(d, 12, y, on=4.0); rivet(d, 788, y, on=4.0)
# a split line: the switch panel is a separate plate, black crinkle
sp = M().rrect(500, 28, 284, 128, 3).get()
d.flat(sp, 4.8, "blackp", polish=0.1)
d.tex[sp & (d.rng.random((H, W)) > 0.55)] += 0.07
for (x, y) in ((506, 34), (778, 34), (506, 150), (778, 150)):
    d.dome(x, y, 1.8, 1.8, 1.0, "chrome", polish=1.0, on=4.8)
# the cage bar across the top, in its foam pad
bar = np.zeros((H, W), bool); bar[0:13, 0:800] = True
d.cyl(0, 0, 800, 13, 6.0, "rubber", axis="h", polish=0.15, on=7.0, mask=bar)
d.grain_pebble(bar, 0.05, seed=12)
for x in range(60, 800, 120):
    tie = np.zeros((H, W), bool); tie[0:13, x:x + 3] = True
    d.cyl(x, 0, 3, 13, 6.5, "blackp", axis="h", polish=0.4, on=7.0, mask=tie)

# ------------------------------------------------------------------ gauges
tach = gauge(d, 250, 92, 58, 150, 390, list(range(0, 10)), minor=1, labels=[str(i) for i in range(10)], bezel="chrome",
             bezel_w=3, depth=3.0, on=4.0, redzone=7, label="RPM", label2="X1000", label_y=112, hub=3.5)
# a shift light on top of the tach
d.torus(250, 26, 4, 6.5, 1.8, "chrome", polish=1.0, on=4.0)
sl = np.hypot(d.XX + 0.5 - 250, d.YY + 0.5 - 26) < 4
d.h[sl] = 5.5; d.mat[sl] = d.mid("paint_r"); d.polish[sl] = 1.0
d.text("SHIFT", 272, 24, "face", align="l")
spd = gauge(d, 112, 92, 34, 135, 405, list(range(0, 161, 20)), minor=1, labels=["0", "", "40", "", "80", "", "120", "", "160"],
            bezel="chrome", bezel_w=2, depth=2.5, on=4.0, label="MPH", label_y=104, hub=2.5)
small = {}
for key, cx, cy, labs, red_lo in (("oil", 386, 60, ("0", "80"), True), ("water", 452, 60, ("C", "H"), False), ("fuel", 386, 122, ("E", "F"), True), ("volts", 452, 122, ("8", "16"), True)):
    small[key] = gauge(d, cx, cy, 24, 150, 390, [0, 1, 2, 3, 4], minor=0, labels=None, bezel="chrome", bezel_w=2, depth=2.0,
                       on=4.0, hub=2.0)
    d.text(labs[0], cx - 13, cy + 9, "paint_w", align="c"); d.text(labs[1], cx + 13, cy + 9, "paint_w", align="c")
    d.text(key.upper(), cx, cy + 15, "paint_c", align="c")

# ------------------------------------------------------------------ switches with label tape
row_y = 64
tog = {}
for i, (lab, up) in enumerate((("IGN", True), ("FUEL", True), ("FAN", False), ("LIGHTS", False))):
    cx = 530 + i * 42
    tog[lab] = toggle(d, cx, row_y + 14, up=up, on=4.8)
    dymo(d, lab, cx, row_y + 26, on=4.8, align="c")
# start button and kill switch
d.torus(714, 78, 9, 12.5, 2.4, "chrome", polish=1.0, on=4.8)
st = np.hypot(d.XX + 0.5 - 714, d.YY + 0.5 - 78) <= 9
d.h[st] = 4.8 + 3.0 * np.sqrt(np.clip(1 - (np.hypot(d.XX[st] + 0.5 - 714, d.YY[st] + 0.5 - 78) / 9) ** 2, 0, 1))
d.mat[st] = d.mid("paint_r"); d.polish[st] = 0.9
dymo(d, "START", 714, 94, on=4.8, align="c")
# the electrical cut-off: red key in a yellow bolt decal
bolt = M().poly([(752, 52), (766, 52), (760, 64), (770, 64), (750, 84), (756, 68), (746, 68)]).get()
d.paint(bolt & sp, "paint_y", flatlight=True)
d.dome(758, 98, 6, 6, 2.5, "paint_r", polish=0.8, on=4.8)
d.text("KILL", 758, 108, "paint_w", align="c")
# fire system pull
d.torus(560, 128, 6, 8.5, 2.0, "paint_r", polish=0.9, on=4.8)
d.text("FIRE", 560, 140, "paint_r", align="c")
d.text("PULL", 560, 146, "paint_w", align="c") if False else None
# decals: original sponsors (die-cut vinyl, flat on the plate)
def decal(x, y, w, h, bg, fg, lines, r=2):
    m = M().rrect(x, y, w, h, r).get()
    d.paint(m, bg, flatlight=True)
    edge = m & (edt(m) <= 1)
    d.paint(edge, "paint_w", flatlight=True)
    yy = y + (h - 6 * len(lines)) // 2 + 1
    for t in lines:
        d.text(t, x + w // 2, yy, fg, align="c", flatlight=True); yy += 6
decal(600, 118, 70, 22, "paint_y", "face", ["KNOX", "MOTOR OIL"])
decal(682, 118, 92, 13, "paint_r", "paint_w", ["WEST POINT SPEEDWAY"])
decal(682, 136, 92, 13, "face", "paint_y", ["MULDRAUGH AUTO PARTS"])
# lower left: a toggle pair for the wipers and the horn button, and the car's number plate
toggle(d, 34, 138, up=True, on=4.0); dymo(d, "WIPER", 34, 150, on=4.0, align="c")
d.torus(80, 140, 5, 7, 1.6, "chrome", polish=1.0, on=4.0); d.dome(80, 140, 5, 5, 2.4, "blackp", polish=0.7, on=4.0)
dymo(d, "HORN", 80, 150, on=4.0, align="c")
num = M().rrect(166, 130, 34, 26, 4).get()
d.paint(num, "paint_w", flatlight=True)
d.text("12", 183, 134, "face", align="c", scale=3, flatlight=True)

plate_img = d.render()
plate_img.save("race_plate.png")
# ------------------------------------------------------------------ preview of the live parts
needle(d, tach, 6.4 / 9, color="#ff3a1a"); needle(d, spd, 74 / 160, color="#ff3a1a")
needle(d, small["oil"], 0.62, color="#ff3a1a"); needle(d, small["water"], 0.5, color="#ff3a1a")
needle(d, small["fuel"], 0.85, color="#ff3a1a"); needle(d, small["volts"], 0.6, color="#ff3a1a")
sl_on = np.hypot(d.XX + 0.5 - 250, d.YY + 0.5 - 26) < 3.2
d.glow(sl_on, "#ff4a2a")
preview = d.render()
preview.save("race_live.png")
print("ok")
