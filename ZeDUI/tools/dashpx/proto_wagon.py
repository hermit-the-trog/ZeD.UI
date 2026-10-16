"""Prototype A: Chevalier Cerise Wagon. Late-70s / 80s, boxy, walnut applique, chrome lips, speed first:
a ribbon speedometer (85 mph, the 55 marked), fuel and temp in square windows, text warning lamps, no tach."""
import numpy as np
from engine import Dash, Mask, RAMPS, hx
from widgets import *

CAB = "v_walnut"
d = Dash(800, 172, seed=11)
W, H = d.W, d.H
M = d.M

# ------------------------------------------------------------------ silhouette and big forms
hood = M().poly([(14, 2), (486, 2), (494, 10), (494, 168), (6, 168), (6, 10)]).get()
cons = M().poly([(494, 16), (786, 16), (794, 24), (794, 168), (494, 168)]).get()
d.flat(hood | cons, 4.0, CAB, polish=0.15)
d.grain_pebble(hood | cons, 0.045)
# the brow: a sloped top (catches the windshield), a front face, a chrome lip under it
brow_top = M().poly([(14, 2), (486, 2), (494, 10), (494, 9), (6, 9), (6, 10)]).get() & hood
d.ramp_h(brow_top, 1.0, 10.0, axis="y", a0=2, a1=9)
brow_face = hood & (d.YY >= 9) & (d.YY < 16)
d.h[brow_face] = 10.0
lip = hood & (d.YY >= 15) & (d.YY < 18) & (d.XX >= 8) & (d.XX < 492)
d.cyl(8, 15, 484, 3, 1.2, "chrome", axis="h", polish=1.0, on=9.6, mask=lip)
for gx_ in range(120, 380, 4):
    slot_ = np.zeros((H, W), bool); slot_[4:7, gx_:gx_ + 2] = True
    d.seam(slot_, 0.6)
# console top: a short slope
ctop = cons & (d.YY < 23)
d.ramp_h(ctop, 1.5, 4.0, axis="y", a0=16, a1=23)
d.seam(np.zeros((H, W), bool) | ((d.XX == 494) & (d.YY >= 16)), 0.5)

# ------------------------------------------------------------------ the instrument panel: walnut in a chrome lip
wood = M().rect(18, 22, 464, 92).get()
d.flat(wood, 1.0, "walnut", polish=0.55)
d.grain_wood(wood, scale=1.0, seed=3)
chrome_frame(d, 16, 20, 468, 96, 1.0, t=2, r=1, z=2.2)

# ribbon speedometer
sx, sy, sw, sh = 128, 28, 248, 46
face = window(d, sx, sy, sw, sh, 2.5, bezel="chrome", r=2, bezel_t=2, on=1.0)
x0, x1 = sx + 14, sx + sw - 18                     # 0 .. 85 mph
mph = lambda v: x0 + (x1 - x0) * v / 85.0
for v in range(0, 86, 5):
    xx = int(round(mph(v)))
    big = v % 10 == 0
    m = np.zeros((H, W), bool); m[sy + 13:sy + 13 + (6 if big else 3), xx] = True
    d.paint(m, "paint_r" if v == 55 else "paint_w")
    if big:
        d.text(str(v), xx + (1 if v < 10 else 0), sy + 5, "paint_r" if v == 50 and False else "paint_w", align="c")
d.text("55", int(round(mph(55))), sy + 5, "paint_o", align="c")
base = np.zeros((H, W), bool); base[sy + 19, x0:x1 + 1] = True
d.paint(base, "paint_w")
for v in range(0, 141, 20):                          # km/h, smaller and cream
    xx = int(round(mph(v / 1.609)))
    if xx <= x1:
        m = np.zeros((H, W), bool); m[sy + 20:sy + 22, xx] = True; d.paint(m, "paint_c")
        d.text(str(v), xx, sy + 24, "paint_c", align="c")
d.text("MPH", x1 + 8, sy + 9, "paint_w", align="c")
d.text("KM/H", x1 + 8, sy + 24, "paint_c", align="c")
# odometer drums
ox, oy = sx + sw // 2 - 24, sy + 33
for i, ch in enumerate("083174"):
    cell = np.zeros((H, W), bool); cell[oy:oy + 9, ox + i * 8:ox + i * 8 + 7] = True
    d.paint(cell, "blackp" if i < 5 else "paint_w")
    d.text(ch, ox + i * 8 + 2, oy + 2, "paint_w" if i < 5 else "face")
speedo = {"x0": x0, "x1": x1, "y": sy + 8, "h": 18, "max_mph": 85}

# fuel and temp: square windows, needle pivots at the bottom
def sq_gauge(cx, lab_l, lab_r, icon, frac):
    gx, gy = cx - 36, 30
    window(d, gx, gy, 72, 42, 2.5, bezel="chrome", r=2, bezel_t=2, on=1.0)
    pcx, pcy = cx, gy + 38
    an = gauge.__wrapped__ if hasattr(gauge, "__wrapped__") else None
    # arc ticks from 215 to 325 degrees
    for i in range(5):
        a = 215 + 110 * i / 4
        ca, sa = np.cos(np.radians(a)), np.sin(np.radians(a))
        m = line_mask(d, pcx + ca * 24, pcy + sa * 24, pcx + ca * (29 if i % 2 == 0 else 27), pcy + sa * (29 if i % 2 == 0 else 27), 1.0)
        d.paint(m, "paint_r" if (i == 0 and lab_l == "E") or (i == 4 and lab_r == "H") else "paint_w")
    d.text(lab_l, pcx - 27, pcy - 20, "paint_w", align="c")
    d.text(lab_r, pcx + 27, pcy - 20, "paint_w", align="c")
    iw, ih = icon_size(icon)
    d.paint(icon_mask(d, icon, pcx - 22, pcy - 9), "paint_c", flatlight=True)
    d.dome(pcx, pcy, 3.0, 3.0, 2.0, "blackp", polish=0.9, on=-1.5)
    return {"cx": pcx, "cy": pcy, "r0": -2, "r1": 22, "a0": 215, "a1": 325}

fuel = sq_gauge(80, "E", "F", "fuel", 0.8)
temp = sq_gauge(426, "C", "H", "temp", 0.45)

# text warning lamps under the speedometer
LAMPS = [("OIL", "#ff3a20"), ("GEN", "#ff3a20"), ("TEMP", "#ff3a20"), ("BRAKE", "#ff3a20"), ("BELTS", "#ff3a20"), ("<", "#3cff6a"), ("HI", "#4aa8ff"), (">", "#3cff6a")]
lamps = []
lx = sx + 2
for name, col in LAMPS:
    w = 30 if len(name) > 2 else 14
    window(d, lx, 80, w, 11, 1.5, bezel=None, face="lens", r=1, on=1.0)
    m = d.text(name if name not in "<>" else "", lx + w // 2, 83, "lampoff", align="c", flatlight=True)
    if name in "<>":
        m = icon_mask(d, "arrow_l" if name == "<" else "arrow_r", lx + 5, 83)
        d.paint(m, "lampoff", flatlight=True)
    lamps.append({"name": name, "x": lx, "y": 80, "w": w, "h": 11, "color": col, "ink": m})
    lx += w + 3
# a chrome script on the wood
nameplate(d, "CERISE", 400, 96, on=1.0, mat="chrome", font="35", scale=2)

# ------------------------------------------------------------------ lower dash
lightsK = knob(d, 34, 140, 8, mat="chrome", on=4.0, z=4.5, knurl=False)
ins = np.hypot(d.XX + 0.5 - 34, d.YY + 0.5 - 140) <= 5.2
d.paint(ins, "blackp", flatlight=True)
d.paint(icon_mask(d, "headlamp", 31, 138), "paint_w", flatlight=True)
d.text("LIGHTS", 34, 151, "paint_w", align="c")
# ignition: chrome bezel, black face, key slot
d.torus(80, 140, 7, 10, 2.2, "chrome", polish=1.0, on=4.0)
ig = np.hypot(d.XX + 0.5 - 80, d.YY + 0.5 - 140) < 7
d.h[ig] = 4.5; d.mat[ig] = d.mid("blackp"); d.polish[ig] = 0.5
slot = np.zeros((H, W), bool); slot[136:145, 79:81] = True
d.seam(slot, 0.8)
for t, (tx, ty) in (("OFF", (66, 125)), ("ON", (88, 125)), ("START", (101, 135))):
    d.text(t, tx, ty, "paint_w", align="c")
ign = {"cx": 80, "cy": 140, "r": 7}
# lighter
d.torus(124, 140, 4, 6, 1.6, "chrome", polish=1.0, on=4.0)
lt = np.hypot(d.XX + 0.5 - 124, d.YY + 0.5 - 140) < 4
d.h[lt] = 5.0; d.mat[lt] = d.mid("blackp")
d.tex[lt & (((d.XX + d.YY) % 2) == 0)] += 0.1
# ashtray: chrome-lipped door with a pull
ash = M().rect(144, 128, 78, 26).get()
d.flat(ash, 4.2, CAB, polish=0.2)
d.grain_pebble(ash, 0.04, seed=8)
chrome_frame(d, 143, 127, 80, 28, 4.0, t=1, r=1, z=1.6)
pull = M().rect(172, 129, 22, 3).get()
d.slab(pull, 2.4, "chrome", bevel=1.0, polish=1.0, on=5.2)
# push buttons
lockB = button(d, 240, 132, 18, 13, None, mat="blackp", on=4.0, z=2.0, frame="chrome")
d.paint(icon_mask(d, "lock", 247, 136), "paint_w", flatlight=True)
d.text("LOCK", 249, 149, "paint_w", align="c")
gateB = button(d, 274, 132, 30, 13, "GATE", mat="blackp", on=4.0, frame="chrome")
d.text("TAILGATE", 289, 149, "paint_w", align="c")
cruiseB = button(d, 320, 132, 30, 13, "CRUISE", mat="blackp", on=4.0, frame="chrome", led=(342, 134))
d.text("ON  SET", 335, 149, "paint_w", align="c")
# driver's vent
vent_rect(d, 384, 124, 98, 38, on=4.0)

# ------------------------------------------------------------------ console
cw = M().rect(504, 26, 282, 136).get()
d.flat(cw, 4.6, "walnut", polish=0.55)
d.grain_wood(cw, scale=1.0, seed=7)
chrome_frame(d, 502, 24, 286, 140, 4.6, t=2, r=1, z=2.0)
vent_rect(d, 512, 32, 82, 20, on=4.6)
vent_rect(d, 696, 32, 82, 20, on=4.6)
nameplate(d, "WAGON", 645, 37, on=4.6, mat="chrome", font="35", align="c", scale=2)
# radio opening (the head unit sits in it)
hu = (556, 58, 178, 46)
op = M().rect(hu[0] - 3, hu[1] - 3, hu[2] + 6, hu[3] + 6).get()
d.well(op, 2.0, "blackp", bevel=0.8)
chrome_frame(d, hu[0] - 4, hu[1] - 4, hu[2] + 8, hu[3] + 8, 4.6, t=1, r=0, z=1.4)
# ---- head unit (ValuTech AM/FM cassette), its own face
hx0, hy0, hw, hh = hu
plate = M().rect(hx0, hy0, hw, hh).get()
d.flat(plate, 3.0, "blackp", polish=0.35)
d.grain_brushed(plate, 0.03, seed=4)
knob(d, hx0 + 13, hy0 + 15, 7, mat="blackp", on=3.0, z=3.0, pointer=230, skirt=1.2)
knob(d, hx0 + hw - 14, hy0 + 15, 7, mat="blackp", on=3.0, z=3.0, pointer=300, skirt=1.2)
d.text("VOL", hx0 + 13, hy0 + 26, "paint_w", align="c")
d.text("TUNE", hx0 + hw - 14, hy0 + 26, "paint_w", align="c")
disp = window(d, hx0 + 30, hy0 + 5, 118, 17, 1.4, bezel=None, face="lens", r=1, on=3.0)
d.text("VALUTECH", hx0 + 89, hy0 + 25, "paint_c", align="c")
tape = M().rect(hx0 + 38, hy0 + 32, 102, 9).get()
d.well(tape, 1.4, "blackp", bevel=0.6)
d.seam(np.zeros((H, W), bool) | ((d.YY == hy0 + 36) & (d.XX >= hx0 + 40) & (d.XX < hx0 + 138)), 0.6)
for i in range(6):
    button(d, hx0 + 30 + i * 20, hy0 + 33, 16, 7, None, mat="alu", on=3.0, z=1.4) if False else None
pre = []
for i in range(5):
    pre.append(button(d, hx0 + 31 + i * 23, hy0 + 32 + 0, 20, 8, str(i + 1), mat="alu", on=3.0, z=1.5, lab_mat="blackp"))
headunit = {"x": hx0, "y": hy0, "w": hw, "h": hh, "display": (hx0 + 30, hy0 + 5, 118, 17)}
# ---- climate: two levers and a fan knob, on the walnut
tempL = lever_slot(d, 520, 122, 120, on=4.6, pos=0.66, labels=["COLD", "", "", "WARM"], lab_y=130, grad=("#3a6ad8", "#d83a2a"))
modeL = lever_slot(d, 520, 146, 120, on=4.6, pos=0.25, labels=["OFF", "VENT", "HEAT", "DEF"], lab_y=154)
d.text("TEMP", 520, 112, "paint_c")
d.text("AIR", 520, 138, "paint_c")
fanK = knob(d, 724, 138, 12, mat="chrome", on=4.6, z=4.0, knurl=True, pointer=200, ptr_mat="blackp")
for t, a in (("OFF", 150), ("LO", 200), ("2", 250), ("HI", 300)):
    ca, sa = np.cos(np.radians(a)), np.sin(np.radians(a))
    d.text(t, int(724 + ca * 21), int(138 + sa * 21) - 2, "paint_w", align="c")
d.text("FAN", 724, 154, "paint_c", align="c")
acB = button(d, 668, 128, 26, 11, "A/C", mat="blackp", on=4.6, frame="chrome", led=(690, 130))
heatB = button(d, 668, 144, 26, 11, "HEAT", mat="blackp", on=4.6, frame="chrome", led=(690, 146))

# ------------------------------------------------------------------ render the plate, then a live preview on top
plate_img = d.render()
plate_img.save("wagon_plate.png")

# preview: needles, lit lamps, display, LEDs (the code draws these live)
def ribbon_needle(v):
    xx = int(round(mph(v)))
    m = np.zeros((H, W), bool); m[sy + 8:sy + 27, xx - 1:xx + 1] = True
    d.glow(m, "#f07a28")
    e = np.zeros((H, W), bool); e[sy + 8:sy + 27, xx + 1] = True
    d.glow(e, "#7a2a08")
ribbon_needle(38)
needle(d, fuel, 0.78); needle(d, temp, 0.45)
for lp in lamps:
    if lp["name"] in ("HI", ">"):
        d.glow(lp["ink"], lp["color"])
        bg = np.zeros((H, W), bool); bg[lp["y"] + 2:lp["y"] + 9, lp["x"] + 1:lp["x"] + lp["w"] - 1] = True
seg_x = hx0 + 74
for i, ch in enumerate("98.4"):
    if ch == ".":
        m = np.zeros((H, W), bool); m[hy0 + 18:hy0 + 20, seg_x + 1:seg_x + 3] = True; d.glow(m, "#ffb02e"); seg_x += 5; continue
    seg_digit(d, ch, seg_x, hy0 + 8, 8, 12, "#ffb02e", "#3a2408", t=2); seg_x += 11
dot_text(d, "FM", hx0 + 38, hy0 + 9, "#ffb02e"); dot_text(d, "ST", hx0 + 38, hy0 + 15, "#ffb02e")
for led in (cruiseB["led"], heatB["led"]):
    lx_, ly_, lw_, lh_ = led
    m = np.zeros((H, W), bool); m[ly_:ly_ + lh_, lx_:lx_ + lw_] = True; d.glow(m, "#ffb02e")
preview = d.render()
preview.save("wagon_live.png")
print("ok")
