"""The nineteen dashboards. Each takes a Build and fills it: plate art plus the live parts the game draws.

Families (director, Oct 16 2026):
  wood and chrome, boxy ......... wagon, luxury, horizon
  vinyl and chrome, speed first . nyala, dart, d6, van (sticker blank), bulldriver, rancher
  fleet, plain .................. police (certified speedometer, siren controller), taxi (fare meter), ambulance, fire, ranger
  early 90s curves .............. dashelite, primani, suv
  RPM first ..................... race, cossette
A fleet car keeps its base model's cluster, made plain, and gets a fleet console.
"""
import math
import numpy as np
from dashlib import *
from engine import text_w, plane
import v6
from brands import plaque
from v6 import (hazard_under_ash, lower_boxy6, lower_curvy6, console_vents, ash_tray, no_smoking, taxi_meter6, meter_flag_variants,
                vent_louvered, vent_eyeball, ASH_W, ASH_H)
from widgets import (gauge, window, glare, chrome_frame, knob, button, rocker, toggle, vent_rect, vent_round, nameplate, dymo,
                     rivet, icon_mask, icon_size, line_mask)

RED, AMB, GRN, BLU = "#ff3a20", "#ffb02e", "#3cff6a", "#4aa8ff"
ICONS_90S = [("arrow_l", "turnL", GRN), ("beam", "hiBeam", BLU), ("batt", "genLamp", RED), ("oil", "oilLamp", RED),
             ("brake", "brakeLamp", RED), ("engine", "engLamp", AMB), ("arrow_r", "turnR", GRN)]
L_OIL, L_GEN, L_TEMP, L_BRAKE, L_BELTS = ("OIL", "oilLamp", RED), ("GEN", "genLamp", RED), ("TEMP", "tempLamp", RED), \
    ("BRAKE", "brakeLamp", RED), ("BELTS", "beltLamp", RED)
L_HI, L_LT, L_RT, L_ENG, L_4X4 = ("HI", "hiBeam", BLU), ("@arrow_l", "turnL", GRN), ("@arrow_r", "turnR", GRN), ("ENG", "engLamp", AMB), \
    ("4X4", "fourWD", AMB)
MPH100 = (list(range(0, 101, 10)), ["0", "", "20", "", "40", "", "60", "", "80", "", "100"])


# =================================================================================== small shared pieces
def inset(b, x, y, w, h, mat="walnut", frame="chrome", z=Z_FACE, seed=7, t=2):
    """a panel let into the dash face: walnut applique, brushed metal, a black plate"""
    d = b.d
    pad = t + 1 if frame == "chrome" else 1
    b.check_flat(x - pad, y - pad, w + 2 * pad, h + 2 * pad, "inset panel")
    m = box(x, y, w, h)
    d.flat(m, z, mat, polish=0.55 if mat == "walnut" else 0.3)
    if mat == "walnut": d.grain_wood(m, seed=seed)
    elif mat == "alu": d.grain_brushed(m, 0.06, seed=seed)
    elif mat in ("blackp", "steel"): d.tex[m & (plane(d.rng, (H, W)) > 0.6)] += 0.05
    if frame == "chrome": chrome_frame(d, x - t, y - t, w + 2 * t, h + 2 * t, z, t=t, r=1, z=2.0 if t > 1 else 1.4)
    elif frame == "seam": d.seam(box(x - 1, y - 1, w + 2, h + 2) & ~m, 0.6)
    return m


def lamp_col(b, x, y, w, items, pitch=14, h_=11, on=Z_CL):
    """warning lamps stacked in a column, all one width"""
    d = b.d
    for i, (name, src, col) in enumerate(items):
        yy = y + i * pitch
        b.check_flat(x, yy, w, h_, f"lamp {name}")
        win = window(d, x, yy, w, h_, 1.2, bezel=None, face="lens", r=1, on=on, lens=False)
        if name.startswith("@"):
            iw, ih = icon_size(name[1:]); m = icon_mask(d, name[1:], x + (w - iw) // 2, yy + (h_ - ih) // 2)
        else:
            m = d.text(name, x + w // 2, yy + (h_ - 5) // 2, "lampoff", align="c", flatlight=True)
        d.paint(m, "lampoff", flatlight=True)
        b.lamp(m, src, col, within=win)


def screw(b, x, y, on=None):
    d = b.d
    z = float(d.h[y, x]) if on is None else on
    d.dome(x, y, 2.0, 2.0, 1.0, "alu", polish=0.9, on=z)
    d.seam(box(x - 1, y, 3, 1), 0.5)


def clock(b, cx, cy, r, bezel="chrome", nd="#f4f4f0"):
    """an analog clock; the game sets the hands from the game time"""
    d = b.d
    b.check_flat(cx - r - 3.5, cy - r - 3.5, 2 * r + 7, 2 * r + 7, "clock")
    fm = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy) <= r
    d.h[fm] = Z_DIAL; d.mat[fm] = d.mid("face"); d.solid |= fm; d.tex[fm] = 0; d.polish[fm] = 0.15
    if bezel: d.torus(cx, cy, r, r + 2.6, 2.0, bezel, polish=1.0, on=Z_CL)
    for i in range(12):
        a = i * 30
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        L = 3 if i % 3 == 0 else 1.5
        m = line_mask(d, cx + ca * (r - 1.5), cy + sa * (r - 1.5), cx + ca * (r - 1.5 - L), cy + sa * (r - 1.5 - L), 1.0) & fm
        d.paint(m, "paint_w")
    glare(d, fm, slope=-0.55, width=4, offset=0.16, amount=0.05)
    d.dome(cx, cy, 1.8, 1.8, 1.4, "blackp", polish=0.9, on=Z_DIAL)
    b.part("clock", cx=cx, cy=cy, rh=r * 0.5, rm=r - 3, color=nd)


def rocker_panel(b, x, y, items, title="EMERGENCY", pitch=24, margin=4):
    """a black switch plate: rockers that show the lightbar and siren state, the rest the crew's own. margin: the plate
    either side of the outer switches' pitch"""
    d = b.d
    w = len(items) * pitch + 2 * margin
    b.check_flat(x - 1, y - 1, w + 2, 42, "switch panel")
    d.slab(box(x, y, w, 40), 2.0, "blackp", bevel=1.0, polish=0.3, on=Z_FACE)
    zt = Z_FACE + 2.0
    d.text(title, x + w // 2, y + 3, "paint_c", align="c")
    for i, (lab, src, hid) in enumerate(items):
        rx = x + margin + (pitch - 16) // 2 + i * pitch
        rocker(d, rx, y + 11, 16, 20, on=zt, up=False)
        d.text(lab, rx + 8, y + 33, "paint_w", align="c")
        b.ink_rect(rx + 8 - text_w(lab) // 2, y + 33, text_w(lab), 5, f"label '{lab}'")     # (the build's checks see it)
        if src:
            def fn(dd, rx=rx): rocker(dd, rx, y + 11, 16, 20, on=zt, up=True)
            b.variant(f"rock_{src}_{b.id}", src, fn)
        if hid: b.hit(hid, rx, y + 11, 16, 20, needs="hasLightbar")


# =================================================================================== clusters
def cl_nyala(b, bz="chrome", nd="#f07a28"):
    """the Nyala (and its taxi and ranger): fuel, a big speedometer, temp; word lamps in columns; the gear strip"""
    lamp_col(b, 28, 24, 34, [L_OIL, L_GEN, L_TEMP, L_BRAKE])
    small_dial(b, 118, 58, 24, "fuel", "E", "F", icon="fuel", bezel=bz, red_left=True, needle=nd, low_src="fuelLamp")
    b.label("UNLEADED", 118, 90, "paint_c", align="c"); b.label("FUEL ONLY", 118, 97, "paint_c", align="c")
    dial(b, 240, 61, 39, 135, 405, *MPH100, "speed_mph", 100, minor=1, label="MPH", label_y=67, needle=nd, bezel=bz, hub=3.0)
    odo_under(b, 240, 61, 39)
    small_dial(b, 362, 58, 24, "temp", "C", "H", icon="temp", bezel=bz, red_right=True, needle=nd)
    lamp_col(b, 418, 24, 34, [L_BELTS, L_HI, L_LT, L_RT])
    prndl(b, 424, 95, pitch=7)


def cl_d6(b, bz="chrome", nd="#ff6a1a"):
    """the D6 truck (and the fire pickup): a fan speedometer over a hidden pivot, square gauges either side. The pivot
    sits under the shroud and the sweep stops short of the window's floor, so the needle's root never leaves the shroud
    (director, Oct 29 2026: it rose out of the bottom bezel at the ends of its travel)"""
    d = b.d
    sx, sy, sw, sh = 128, 22, 224, 66
    b.check_flat(sx - 1, sy - 1, sw + 2, sh + 2, "fan speedometer")
    face = window(d, sx, sy, sw, sh, 2.5, bezel=bz, r=3, bezel_t=2, on=Z_CL)
    pcx, pcy, R = 240, 96, 62
    a0, a1 = 210, 330
    for i, v in enumerate(range(0, 101, 5)):
        a = a0 + (a1 - a0) * v / 100.0
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        L = 6 if v % 10 == 0 else 3
        m = line_mask(d, pcx + ca * R, pcy + sa * R, pcx + ca * (R - L), pcy + sa * (R - L), 1.0) & face
        d.paint(m, "paint_r" if v == 55 else "paint_w")
        if v % 20 == 0:
            d.text(str(v), int(round(pcx + ca * (R - 14))), int(round(pcy + sa * (R - 14))) - 2, "paint_w", align="c")
    cap = np.hypot(d.XX + 0.5 - pcx, d.YY + 0.5 - pcy) <= 26
    capm = cap & face
    d.h[capm] = Z_CL - 1.0 + 1.6 * np.sqrt(np.clip(1 - (np.hypot(d.XX[capm] + 0.5 - pcx, d.YY[capm] + 0.5 - pcy) / 26.0) ** 2, 0, 1))
    d.mat[capm] = d.mid("blackp"); d.polish[capm] = 0.6; d.tex[capm] = 0
    b.hub(pcx, pcy, capm)
    d.text("MPH", pcx, pcy - 20, "paint_c", align="c", flatlight=True)      # on the shroud, out of the needle's path
    glare(d, face, slope=-0.4, width=8, offset=0.12, amount=0.05)
    b.part("needle", src="speed_mph", max=100, cx=pcx, cy=pcy, r0=27, r1=R - 2, a0=a0, a1=a1, color=nd, w=2, hub=0)
    sq_dial(b, 58, 22, "fuel", "E", "F", "fuel", w=64, h=40, needle=nd, red_left=True, low_src="fuelLamp", bezel=bz)
    sq_dial(b, 58, 66, "temp", "C", "H", "temp", w=64, h=38, needle=nd, red_right=True, bezel=bz)
    sq_dial(b, 422, 22, "oil", "L", "H", "oil", w=64, h=40, needle=nd, bezel=bz)
    sq_dial(b, 422, 66, "volts", "8", "18", "batt", w=64, h=38, needle=nd, bezel=bz)
    # Nov 6 2026 (Roadworthy): OIL added to the left column (five lamps at a 13 pitch); the right column as it was
    lamp_col(b, 96, 24, 28, [L_OIL, L_GEN, L_BRAKE, L_BELTS, L_LT], pitch=13)
    lamp_col(b, 356, 24, 28, [L_HI, L_ENG, ("TEMP", "tempLamp", RED), L_RT])
    odo_beside(b, 206, 93)


def cl_van(b, bz="blackp", nd="#ff7a2a"):
    """the Valuline van (and the ambulance): speedometer, a row of four gauges, a lamp row"""
    dial(b, 132, 61, 39, 135, 405, *MPH100, "speed_mph", 100, minor=1, label="MPH", label_y=67, needle=nd, bezel=bz, hub=3.0)
    odo_under(b, 132, 61, 39)
    for i, (src, lo, hi, ic, lab, rl, rr_) in enumerate((("fuel", "E", "F", "fuel", None, True, False), ("temp", "C", "H", "temp", None, False, True),
                                                         ("oil", "L", "H", None, "OIL", False, False), ("volts", "8", "18", None, "VOLTS", False, False))):
        small_dial(b, 236 + i * 60, 48, 22, src, lo, hi, icon=ic, label=lab, bezel=bz, red_left=rl, red_right=rr_, needle=nd,
                   low_src="fuelLamp" if src == "fuel" else None)
    lamp_text_row(b, 212, 82, [L_OIL, L_GEN, L_TEMP, L_BRAKE, L_BELTS, L_HI, L_LT, L_RT])      # Nov 6 2026: TEMP
    prndl(b, 392, 97, pitch=7)


def cl_cert(b, nd="#f4f4f0"):
    """police: a certified speedometer to 140, four gauges, two lamp columns, a clock"""
    d = b.d
    dial(b, 128, 61, 39, 135, 405, list(range(0, 141, 10)), ["0", "", "20", "", "40", "", "60", "", "80", "", "100", "", "120", "", "140"],
         "speed_mph", 140, minor=1, bezel="blackp", label="CERTIFIED", label_y=68, needle=nd, hub=3.0)
    d.text("MPH", 128, 45, "paint_w", align="c")
    odo_under(b, 128, 61, 39)
    small_dial(b, 252, 40, 17, "fuel", "E", "F", icon=None, label="FUEL", bezel="blackp", red_left=True, needle=nd, low_src="fuelLamp")
    small_dial(b, 312, 40, 17, "temp", "C", "H", icon=None, label="TEMP", bezel="blackp", red_right=True, needle=nd)
    small_dial(b, 252, 82, 17, "oil", "L", "H", icon=None, label="OIL", bezel="blackp", needle=nd)
    small_dial(b, 312, 82, 17, "volts", "8", "18", icon=None, label="VOLT", bezel="blackp", needle=nd)
    lamp_col(b, 342, 24, 30, [L_OIL, L_GEN, L_BRAKE, L_BELTS])
    lamp_col(b, 378, 24, 30, [L_HI, L_LT, L_RT, L_ENG, L_TEMP], pitch=13)        # Nov 6 2026: TEMP
    prndl(b, 352, 95, pitch=7)
    clock(b, 450, 52, 20, bezel="blackp")


def cl_bull(b, nd="#e8402a"):
    """the Bulldriver: brushed aluminium, speedometer and tach in chrome, four gauges in a block"""
    # Nov 6 2026 (Roadworthy): OIL and TEMP added, the six lamps in two columns of four
    lamp_col(b, 26, 22, 34, [L_OIL, L_GEN, L_BRAKE, L_BELTS], pitch=16)
    lamp_col(b, 64, 22, 34, [L_TEMP, L_HI, L_LT, L_RT], pitch=16)
    dial(b, 150, 61, 39, 135, 405, *MPH100, "speed_mph", 100, minor=1, label="MPH", label_y=67, needle=nd, bezel="chrome", hub=3.0)
    odo_under(b, 150, 61, 39)
    dial(b, 270, 61, 39, 135, 375, list(range(0, 7)), [str(i) for i in range(7)], "rpm", 6000, minor=1, redzone=5, label="RPM",
         label2="X1000", label_y=70, needle=nd, bezel="chrome", hub=3.0)
    for (cx, cy, src, lo, hi, lab, rl, rr_) in ((372, 40, "fuel", "E", "F", "FUEL", True, False), (434, 40, "temp", "C", "H", "TEMP", False, True),
                                                (372, 82, "oil", "L", "H", "OIL", False, False), (434, 82, "volts", "8", "18", "VOLT", False, False)):
        small_dial(b, cx, cy, 17, src, lo, hi, label=lab, bezel="chrome", red_left=rl, red_right=rr_, needle=nd,
                   low_src="fuelLamp" if src == "fuel" else None)


def cl_rancher(b, nd="#f0ece0", lamps_right=True):
    """the Rancher: a painted steel face with its screws, black-rimmed gauges, a 4X4 lamp"""
    for (x, y) in ((25, 21), (474, 21), (25, 100), (474, 100)): screw(b, x, y)
    dial(b, 108, 61, 39, 135, 405, *MPH100, "speed_mph", 100, minor=1, label="MPH", label_y=67, needle=nd, bezel="blackp", hub=3.0)
    odo_under(b, 108, 61, 39)
    for i, (src, lo, hi, ic, lab, rl, rr_) in enumerate((("fuel", "E", "F", "fuel", None, True, False), ("temp", "C", "H", "temp", None, False, True),
                                                         ("oil", "L", "H", None, "OIL", False, False), ("volts", "8", "18", None, "VOLT", False, False))):
        small_dial(b, 210 + i * 54, 46, 19, src, lo, hi, icon=ic, label=lab, bezel="blackp", red_left=rl, red_right=rr_, needle=nd,
                   low_src="fuelLamp" if src == "fuel" else None)
    lamp_text_row(b, 190, 78, [L_OIL, L_GEN, L_TEMP, L_BRAKE, L_BELTS])        # Nov 6 2026: TEMP
    if lamps_right:
        lamp_col(b, 420, 30, 34, [L_4X4, L_HI, L_LT, L_RT])


def cl_dart(b, nd="#ff8a2a"):
    """the Dart: a small cluster in a plain face, a 90 mph speedometer with km/h inside, fuel, and a blank where a tach would go"""
    d = b.d
    an = dial(b, 180, 60, 38, 135, 405, list(range(0, 91, 10)), ["0", "", "20", "", "40", "", "60", "", "80", ""], "speed_mph", 90,
              minor=1, label="MPH", label_y=66, needle=nd, bezel="alu", hub=3.0)
    odo_under(b, 180, 60, 38)
    small_dial(b, 286, 50, 22, "fuel", "E", "F", icon="fuel", bezel="alu", red_left=True, needle=nd, low_src="fuelLamp")
    # where the blank was (the tach option this car was not ordered with): the temperature gauge, the fuel gauge's twin
    # (Nov 6 2026, the director: "Yes, in the empty dial"; Roadworthy shows the engine's temperature)
    small_dial(b, 372, 52, 22, "temp", "C", "H", icon="temp", bezel="alu", red_right=True, needle=nd)
    # Nov 6 2026: BELTS added; the row moved left to keep its right margin
    lamp_text_row(b, 224, 84, [L_OIL, L_GEN, ("TEMP", "tempLamp", RED), L_BRAKE, L_BELTS, L_HI, L_LT, L_RT])


def cl_cossette(b):
    """the Cossette: a digital cluster in a proud pod: the tach is the arc, speed the figures inside it"""
    d = b.d
    gx, gy, gw, gh = 80, 28, 340, 74
    b.check_flat(gx - 1, gy - 1, gw + 2, gh + 2, "glass")
    win = window(d, gx, gy, gw, gh, 2.0, face="vfd", bezel=None, r=4, on=Z_CL)
    glare(d, win, slope=-0.4, width=14, offset=0.55, amount=0.04)
    cx, cy = 250, 96
    arc_bars(b, cx, cy, 44, 57, 180, 360, 30, "rpm", 7000, "#8aff5a", warn_from=21, red_from=26, grow=0)
    for v in range(0, 8):
        a = 180 + 180 * v / 7.0
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        d.text(str(v), int(round(cx + ca * 63)), int(round(cy + sa * 63)) - 2, "paint_c" if v < 6 else "paint_r", align="c")
    # (Nov 7 2026, the director: the digital speed follows the game's Metric option; the glass prints both units and
    # the one in use lights. The dials and wheels elsewhere stay in mph and miles)
    seg_readout(b, 227, 63, 3, 12, 22, 16, 3, "speedShown", "#ffb02e")
    m = d.text("MPH", 234, 88, "vfdoff", flatlight=True); b.lamp(m, "mphLamp", "#ffb02e")
    m = d.text("KM/H", 251, 88, "vfdoff", flatlight=True); b.lamp(m, "kmhLamp", "#ffb02e")
    bar_stack(b, 94, 36, 12, 50, 12, 1, "fuel", "#ffb02e")
    for t, yy in (("F", 36), ("E", 81)):
        m = d.text(t, 110, yy, "vfdoff", flatlight=True); b.lamp(m, "power", "#ffb02e")
    m = d.text("FUEL", 100, 90, "vfdoff", align="c", flatlight=True); b.lamp(m, "power", "#ffb02e")
    for i, (lab, src) in enumerate((("OIL", "oil"), ("TEMP", "temp"), ("VOLT", "volts"))):
        yy = 40 + i * 16
        m = d.text(lab, 356, yy, "vfdoff", align="r", flatlight=True); b.lamp(m, "power", "#8aff5a")
        bar_stack(b, 360, yy, 46, 5, 10, 1, src, "#8aff5a", vertical=False, warn_from=8 if src == "temp" else None)
    m = d.text("SHIFT", 384, 88, "vfdoff", align="c", flatlight=True); b.lamp(m, "shiftLamp", "#ff5a3a")
    # Nov 6 2026 (Roadworthy): the coolant and belt lamps; the odometer in the pod's left, between the fuel bars and the arc
    lamp_icon_strip(b, 124, 94, [("batt", "genLamp", RED), ("oil", "oilLamp", RED), ("brake", "brakeLamp", RED),
                                 ("temp", "tempLamp", RED), ("belt", "beltLamp", RED)], gap=5, check=False)
    lamp_icon_strip(b, 300, 94, [("beam", "hiBeam", BLU), ("engine", "engLamp", AMB)], gap=5, check=False)
    odo_digital(b, 124, 58, "#ffb02e", words_x=124, words_y=70, hit=(120, 54, 56, 26))


# =================================================================================== consoles
HU6 = (516, 67)          # round 6 (Oct 24): the radio against the console's left edge ...
ASH6 = (704, 67)         # ... and the ash tray (with the lighter) to its right


def con_sedan(b, chrome=True, vents="rect", climate="levers", inset_mat=None, badge_spec=None, hu=HU6, tab=None, fan_mat=None,
              knob_mat="blackp", ash=True):
    if inset_mat: inset(b, 504, 26, 282, 136, inset_mat, "chrome" if chrome and inset_mat == "walnut" else "seam", seed=17)
    if vents == "rect": console_vents(b, 26, chrome=chrome, w=88, h=30)
    elif vents == "round": console_vents(b, 26, chrome=chrome, h=28, round_=True)
    if badge_spec: plaque(b, **badge_spec)
    hy = hu[1]                     # balance pass: 7 px over the radio and 7 under it, for every vent
    headunit_slot(b, hu[0], hy, frame="chrome" if chrome else "bezel")
    if ash: ash_tray(b, ASH6[0], hy, chrome=chrome)
    if climate == "levers": climate_levers(b, 548, 128, chrome=chrome, fan_knob=(752, 140), tab=tab, fan_mat=fan_mat)
    elif climate == "knobs": climate_knobs(b, 540, hy + 72, pitch=46, r=11, mat=knob_mat, ring="chrome" if chrome else None)
    if ash and climate in ("knobs", "sliders"): hazard_under_ash(b)      # Oct 24: the hazard switch under the ash tray
    elif climate == "sliders": climate_sliders(b, 532, 130, w=126)


def con_fleet(b, top="siren", badge_role="unit", chrome=False):
    """fleet: the siren controller (or the fare meter) up top, the fitted radio against the left edge; the emergency
    vehicles a NO SMOKING plate to its right, the taxi an ash tray that has seen a lot of fares"""
    if top == "siren":
        siren_box(b, 510, 28, w=150)
        badge(b, 670, 34, 112, 12, style="stencil", role=badge_role, font="35", color="#e8e8e0", plate="stencil")
    elif top == "meter":
        px_, py_ = taxi_meter6(b, 512, 26)
        meter_flag_variants(b, px_, py_)
        v6.taxi_license(b, 650, 30)            # Oct 24: "under hula needs a taxi license plaque"
        vent_eyeball(b, 764, 44, 14, bezel="blackp")
        v6.hula(b, 650 + 46 - 15, 28 - 37)      # her base on the console's top lip, over the licence; she rises above the plate
    headunit_slot(b, 516, 76, frame="bezel")
    if top == "meter": ash_tray(b, 704, 76, chrome=False, levels=(3,), seed=11)   # a cab's: always the full one
    else: no_smoking(b, 704, 76)
    # three pixels higher than the sedans' so the AIR legends (a clear pixel under the tab) stay on the console
    climate_levers(b, 540, 135, chrome=chrome, fan_knob=(752, 146))


# =================================================================================== wood and chrome, boxy
def wagon(b):
    """Chevalier Cerise Wagon: walnut applique in a chrome lip, a ribbon speedometer, square fuel and temp, word lamps"""
    shell_boxy(b, face_wood=True, trim="chrome", wood_seed=3)
    ribbon_speedo(b, 128, 25, 248, 46, vmax=85, mode="fill", color="#f07a28")
    odo_beside(b, 220, 60)            # Nov 6 2026: the odometer and the trip odometer side by side under the ribbon
    sq_dial(b, 80, 28, "fuel", "E", "F", "fuel", w=72, h=42, red_left=True, low_src="fuelLamp")
    sq_dial(b, 426, 28, "temp", "C", "H", "temp", w=72, h=42, red_right=True)
    lamp_text_row(b, 130, 78, [L_OIL, L_GEN, L_TEMP, L_BRAKE, L_BELTS, L_LT, L_HI, L_RT])
    badge(b, 392, 84, 82, 9, style="chrome", role="model", font="57", shadow="#140904")
    lower_boxy6(b, y0=118, chrome=True, trunk_label="GATE", trunk_sub="TAILGATE")
    inset(b, 504, 26, 282, 136, "walnut", "chrome", seed=7)
    console_vents(b, 28, chrome=True, w=88, h=30)
    plaque(b, 602, 39, 86, 9, style="chrome", role="make", font="35", shadow="#140904")
    headunit_slot(b, *HU6, frame="chrome")
    ash_tray(b, *ASH6, chrome=True)
    climate_levers(b, 548, 128, chrome=True, fan_knob=(752, 140))


def luxury(b):
    """Mercia Lang 4000: burled walnut, a smoked glass electronic cluster, blue-green figures, an electronic climate panel"""
    shell_boxy(b, face_wood=True, trim="chrome", wood_seed=11)
    d = b.d
    VC = "#62f2d8"
    gx, gy, gw, gh = 70, 22, 360, 78
    b.check_flat(gx - 3, gy - 3, gw + 6, gh + 6, "glass cluster")
    win = window(d, gx, gy, gw, gh, 2.0, face="vfd", bezel="chrome", r=3, bezel_t=2, on=Z_CL)
    glare(d, win, slope=-0.4, width=12, offset=0.62, amount=0.05)
    # (Nov 7 2026: the figures in the game's units, both printed, the one in use lit; the Cossette's note)
    seg_readout(b, 196, 32, 3, 20, 36, 28, 4, "speedShown", VC, ghost="vfdoff")
    m = d.text("KM/H", 284, 54, "vfdoff", flatlight=True); b.lamp(m, "kmhLamp", VC)
    m = d.text("MPH", 284, 62, "vfdoff", flatlight=True); b.lamp(m, "mphLamp", VC)
    for (x0, src, lab, lo, hi) in ((84, "fuel", "FUEL", "E", "F"), (396, "temp", "COOLANT", "C", "H")):
        bar_stack(b, x0, 32, 20, 48, 10, 1, src, VC, ghost="vfdoff", warn_from=8 if src == "temp" else None)
        m = d.text(lab, x0 + 10, 84, "vfdoff", align="c", flatlight=True)
        m |= d.text(hi, x0 + 25, 32, "vfdoff", flatlight=True); m |= d.text(lo, x0 + 25, 75, "vfdoff", flatlight=True)
        b.lamp(m, "power", VC)
    out = {}
    for i, ch in enumerate("PRND21"):
        mm = d.text(ch, 214 + i * 9, 78, "vfdoff", align="c", flatlight=True); out[ch] = runs_of(mm)
    b.part("gear", letters=out, color=VC, box=None)
    lamp_icon_strip(b, 128, 91, [("batt", "genLamp", RED), ("oil", "oilLamp", RED), ("brake", "brakeLamp", RED)], gap=6, check=False)
    # Nov 6 2026 (Roadworthy): the coolant and belt lamps after the beam and engine; the odometer right of the gear letters
    lamp_icon_strip(b, 318, 91, [("beam", "hiBeam", BLU), ("engine", "engLamp", AMB), ("temp", "tempLamp", RED),
                                 ("belt", "beltLamp", RED)], gap=6, check=False)
    odo_digital(b, 280, 74, VC, words_x=332, words_y=74, hit=(276, 70, 76, 14))
    d.text("ELECTRONIC INSTRUMENT CLUSTER", 250, 92, "paint_c", align="c")
    clock(b, 456, 60, 17, bezel="chrome", nd="#e8e2d0")
    lower_boxy6(b, y0=118, chrome=True, trunk_label="TRUNK", trunk_sub="RELEASE")
    inset(b, 504, 26, 282, 136, "walnut", "chrome", seed=13)
    console_vents(b, 28, chrome=True, w=88, h=30)
    plaque(b, 602, 37, 86, 12, style="chrome", role="model", font="57", shadow="#140904")
    headunit_slot(b, *HU6, frame="chrome")
    ash_tray(b, *ASH6, chrome=True)
    climate_vfd(b, 516, 124)
    hazard_under_ash(b)


def horizon(b):
    """Masterson Horizon: burgundy, walnut across the cluster, speedometer and tach in chrome, a fuel and temp pair"""
    shell_boxy(b, face_wood=True, trim="chrome", wood_seed=21)
    nd = "#f05a28"
    dial(b, 150, 61, 39, 135, 405, *MPH100, "speed_mph", 100, minor=1, label="MPH", label_y=67, needle=nd, bezel="chrome", hub=3.0)
    odo_under(b, 150, 61, 39)
    dial(b, 262, 63, 31, 135, 375, list(range(0, 8)), [str(i) for i in range(8)], "rpm", 7000, minor=1, redzone=6, label="RPM",
         label2="X1000", label_y=71, needle=nd, bezel="chrome")
    small_dial(b, 360, 50, 22, "fuel", "E", "F", icon="fuel", red_left=True, needle=nd, low_src="fuelLamp")
    small_dial(b, 426, 50, 22, "temp", "C", "H", icon="temp", red_right=True, needle=nd)
    lamp_text_row(b, 334, 84, [L_OIL, L_GEN, L_BRAKE, L_HI])
    lamp_col(b, 34, 24, 30, [L_LT, L_BELTS, L_TEMP, L_RT])
    badge(b, 30, 90, 76, 9, style="chrome", role="model", font="57", shadow="#140904")
    lower_boxy6(b, y0=118, chrome=True, cruise=False)
    inset(b, 504, 122, 282, 40, "walnut", "chrome", seed=23)
    console_vents(b, 27, chrome=True, h=28, round_=True)
    plaque(b, 602, 38, 86, 9, style="chrome", role="make", font="35", shadow="#140904")
    headunit_slot(b, *HU6, frame="chrome")
    ash_tray(b, *ASH6, chrome=True)
    climate_levers(b, 548, 128, chrome=True, fan_knob=(752, 141))


# =================================================================================== vinyl and chrome, speed first
def nyala(b):
    """Chevalier Nyala: slate vinyl, chrome lips, a big speedometer between fuel and temp"""
    shell_boxy(b, trim="chrome")
    cl_nyala(b, bz="chrome", nd="#f07a28")
    lower_boxy6(b, y0=118, chrome=True)
    con_sedan(b, chrome=True, vents="rect", climate="levers",
              badge_spec=dict(x=605, y=33, w=80, h=16, style="chrome", role="make", font="35", plate="oval"))


def dart(b):
    """Chevalier Dart: navy, a small cluster in a plain face, silver trim, rotary climate knobs, no cruise"""
    shell_boxy(b, open_rect=(70, 18, 360, 94), trim="silver")
    cl_dart(b)
    lower_boxy6(b, y0=118, chrome=False, cruise=False)
    con_sedan(b, chrome=False, vents="round", climate="knobs",
              badge_spec=dict(x=605, y=33, w=80, h=16, style="chrome", role="make", font="35", plate="oval"))


def d6(b):
    """Chevalier D6: cocoa, a dark steel face, a fan speedometer, square gauges, round chrome vents"""
    shell_boxy(b, trim="chrome", face_mat="steel")
    cl_d6(b, bz="chrome", nd="#ff6a1a")
    lower_boxy6(b, y0=118, chrome=True, trunk_label="BED", trunk_sub="LOCK")
    con_sedan(b, chrome=True, vents="round", climate="levers", tab="tab_black", fan_mat="chrome",
              badge_spec=dict(x=599, y=30, w=92, h=22, style="emboss", role="make", font="57", color="#2a2c30", plate="stamped"))
    plaque(b, 603, 44, 84, 7, style="emboss", role="sub", font="35", color="#2a2c30", check=False)


def van(b):
    """Franklin Valuline: fleet grey, plain black gauges, a sticker blank by the radio (the Spiffo's van wears the game's own Spiffo)"""
    shell_boxy(b, trim="rubber")
    cl_van(b, bz="blackp", nd="#ff7a2a")
    lower_boxy6(b, y0=118, chrome=False, cruise=False, trunk_label="REAR", trunk_sub="DOORS")
    console_vents(b, 24, chrome=False, w=88, h=28)
    plaque(b, 602, 26, 86, 22, style="emboss", role="make", font="57", color="#2a2c30", plate="stamped")
    plaque(b, 604, 40, 82, 7, style="emboss", role="model", font="35", color="#2a2c30", check=False)
    headunit_slot(b, *HU6, frame="bezel")
    v6.van_right(b, 704, 67)          # switched sides (Oct 24): the radio went left; logo sticker, NO SMOKING or ash tray
    climate_levers(b, 548, 134, chrome=False, fan_knob=(752, 144))


def bulldriver(b):
    """Dash Bulldriver: tan, a brushed aluminium face, speedometer and tach in chrome, a four-gauge block"""
    shell_boxy(b, trim="chrome", face_mat="alu", wood_seed=5)
    cl_bull(b, nd="#e8402a")
    lower_boxy6(b, y0=118, chrome=True, trunk_label="BED", trunk_sub="LOCK")
    con_sedan(b, chrome=True, vents="round", climate="levers",
              badge_spec=dict(x=599, y=30, w=92, h=22, style="emboss", role="make", font="57", color="#2a2c30", plate="stamped"))
    plaque(b, 603, 44, 84, 7, style="emboss", role="model", font="35", color="#2a2c30", check=False)


def rancher(b):
    """Dash Rancher: khaki, a painted sand steel face with its screws, black-rimmed gauges, knobs for the heater"""
    shell_boxy(b, trim=None, face_mat="v_sand", wood_seed=9)
    cl_rancher(b)
    lower_boxy6(b, y0=118, chrome=False, cruise=False)
    inset(b, 504, 26, 282, 136, "steel", "seam")
    for (x, y) in ((508, 30), (781, 30), (508, 157), (781, 157)): screw(b, x, y)
    console_vents(b, 29, chrome=False, h=24, round_=True, x0=516, xr=778)
    plaque(b, 602, 30, 86, 22, style="emboss", role="make", font="57", color="#2a2c30", plate="stamped")
    plaque(b, 604, 44, 82, 7, style="emboss", role="model", font="35", color="#2a2c30", check=False)
    headunit_slot(b, 516, 64, frame="bezel")
    ash_tray(b, 704, 64, chrome=False)
    climate_knobs(b, 540, 136, pitch=46, r=11, mat="blackp")
    hazard_under_ash(b)


# =================================================================================== early 90s curves
def dashelite(b):
    """Dash Elite: one molded charcoal piece, an arched brow over a pill, speed first, icon lamps, push-button climate"""
    m = shell_curvy(b, pill=(24, 22, 452, 96, 40))
    d = b.d
    nd = "#ff5a2a"
    dial(b, 244, 68, 42, 135, 405, list(range(0, 121, 10)), ["0", "", "20", "", "40", "", "60", "", "80", "", "100", "", "120"],
         "speed_mph", 120, minor=1, bezel=None, label="MPH", label_y=82, needle=nd, hub=3.0)
    d.paint(Mask(W, H).arc(244, 68, 43.5, 43.5, 0, 360, 1.0).get() & m["face_mask"], "paint_w")
    dial(b, 104, 70, 32, 135, 375, list(range(0, 8)), [str(i) for i in range(8)], "rpm", 7000, minor=1, bezel=None, redzone=6,
         label="RPM", label2="X1000", label_y=78, needle=nd)
    d.paint(Mask(W, H).arc(104, 70, 33.5, 33.5, 0, 360, 1.0).get() & m["face_mask"], "paint_w")
    small_dial(b, 372, 54, 21, "fuel", "E", "F", icon="fuel", bezel=None, red_left=True, needle=nd, low_src="fuelLamp")
    small_dial(b, 428, 54, 21, "temp", "C", "H", icon="temp", bezel=None, red_right=True, needle=nd)
    for cx in (372, 428):
        d.paint(Mask(W, H).arc(cx, 54, 22.5, 22.5, 200, 340, 1.0).get() & m["face_mask"], "paint_w")
    # Nov 6 2026 (Roadworthy): the coolant and belt lamps join the strip, which starts further left to keep its margin
    lamp_icon_strip(b, 322, 88, ICONS_90S[:-1] + [("temp", "tempLamp", RED), ("belt", "beltLamp", RED), ICONS_90S[-1]], gap=4)
    prndl(b, 376, 100, pitch=8, color="#ff8a3a")
    # the odometer: six figures (four before) in the same LCD, which has to stay in the needle's dead wedge; no room for
    # words, so the trip shows as "t" and its miles ("t  128"), the 90s LCD way. A press switches, a long press zeroes
    window(d, 226, 92, 38, 12, 0.6, bezel=None, face="lcd", r=1, on=Z_CL, lens=False)
    # (Nov 6, review: six seven-segment figures at 4 pixels were a row of ghosts; the 3x5 face in black reads)
    b.part("drums", src="odoShownT", x=230, y=93, n=6, cw=5, ch=10, fg="#1c2418", last_fg="#1c2418", text=True)
    # the unlit marks under them (Nov 7 2026, punch list 94: in the dark they read as "E ' | | ' E" over four figures
    # in a window that holds five; the director: they should be 8s): one 3x5 "8" in each of the six places the figures
    # take (live.draw_drums: x + i*cw + (cw - 4) // 2, y + (ch - 5) // 2), printed like the old segments' ghosts
    for i in range(6):
        d.text("8", 230 + i * 5 + (5 - 4) // 2, 93 + (10 - 5) // 2, "segoff", flatlight=True)
    b.hit("odoButton", 224, 90, 42, 16)
    lower_curvy6(b, y0=122)
    cf = Mask(W, H).rrect(508, 34, 278, 128, 10).get()
    b.check_flat(506, 32, 282, 132, "console face")
    d.slab(cf, 1.0, "blackp", bevel=3.0, polish=0.2, on=Z_FACE - 1.0)
    d.grain_pebble(cf, 0.035, seed=9)
    vent_louvered(b, 514, 38, 100, 24, bezel="blackp", on=Z_FACE, wheel="left")
    vent_louvered(b, 680, 38, 100, 24, bezel="blackp", on=Z_FACE, wheel="right")
    headunit_slot(b, 518, 69, frame="bezel")
    ash_tray(b, 706, 69, chrome=False)
    hazard_under_ash(b)
    climate_buttons(b, 576, 124, lcd=True)
    b.label("AUTOMATIC CLIMATE CONTROL", 646, 154, "paint_c", align="c")
    plaque(b, 560, 25, 172, 7, style="flat", role="full", font="35", color="#d8d6cc", check=False)


def primani(b):
    """Chevalier Primani: beige, a lower, wider brow; a fuel-and-temp twin dial, the speedometer, the tach; sliders"""
    m = shell_curvy(b, pill=(20, 26, 460, 90, 30), end_y=34, console_top=28)
    d = b.d
    nd = "#ff6a2a"
    cx, cy, r = 92, 72, 30
    b.check_flat(cx - r - 2, cy - r - 2, 2 * r + 4, 2 * r + 4, "twin dial")
    fm = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy) <= r
    d.h[fm] = Z_CL - 2.0; d.mat[fm] = d.mid("face"); d.tex[fm] = 0
    d.paint(Mask(W, H).arc(cx, cy, r + 1.5, r + 1.5, 0, 360, 1.0).get() & m["face_mask"], "paint_w")
    for side, (a0, a1, lo, hi, src, ic) in enumerate(((125, 235, "E", "F", "fuel", "fuel"), (55, -55, "C", "H", "temp", "temp"))):
        for i in range(5):
            a = a0 + (a1 - a0) * i / 4
            ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
            mm = line_mask(d, cx + ca * (r - 1.5), cy + sa * (r - 1.5), cx + ca * (r - 4.5), cy + sa * (r - 4.5), 1.0) & fm
            red = (src == "fuel" and i == 0) or (src == "temp" and i == 4)
            d.paint(mm, "paint_r" if red else "paint_w")
        for a, t in ((a0, lo), (a1, hi)):
            ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
            red = (src == "fuel" and t == "E") or (src == "temp" and t == "H")
            d.text(t, int(round(cx + ca * (r - 9))), int(round(cy + sa * (r - 9))) - 2, "paint_r" if red else "paint_w", align="c")
        iw, ih = icon_size(ic)
        d.paint(icon_mask(d, ic, int(cx + (-13 if side == 0 else 13) - iw / 2), cy - 3), "paint_c", flatlight=True)
        b.part("needle", src=src, max=1, cx=cx, cy=cy, r0=3, r1=r - 4, a0=a0, a1=a1, color=nd, w=1, hub=3,
               low_src="fuelLamp" if src == "fuel" else None)
    glare(d, fm, slope=-0.55, width=5, offset=0.16, amount=0.05)
    d.dome(cx, cy, 2.6, 2.6, 1.8, "blackp", polish=0.9, on=Z_CL - 2.0)
    dial(b, 222, 68, 39, 135, 405, list(range(0, 141, 20)), ["0", "20", "40", "60", "80", "100", "120", "140"], "speed_mph", 140,
         minor=1, bezel=None, label="MPH", label_y=82, needle=nd, hub=3.0)
    d.paint(Mask(W, H).arc(222, 68, 40.5, 40.5, 0, 360, 1.0).get() & m["face_mask"], "paint_w")
    odo_under(b, 222, 68, 39)
    dial(b, 352, 70, 34, 135, 375, list(range(0, 9)), [str(i) for i in range(9)], "rpm", 8000, minor=1, bezel=None, redzone=7,
         label="RPM", label2="X1000", label_y=80, needle=nd)
    d.paint(Mask(W, H).arc(352, 70, 35.5, 35.5, 0, 360, 1.0).get() & m["face_mask"], "paint_w")
    # Nov 6 2026 (Roadworthy): the coolant and belt lamps, a third in the first two rows
    lamp_icon_strip(b, 404, 44, [("batt", "genLamp", RED), ("oil", "oilLamp", RED), ("temp", "tempLamp", RED)], gap=4)
    lamp_icon_strip(b, 404, 58, [("brake", "brakeLamp", RED), ("engine", "engLamp", AMB), ("belt", "beltLamp", RED)], gap=4)
    lamp_icon_strip(b, 404, 72, [("beam", "hiBeam", BLU), ("fuel", "fuelLamp", AMB)], gap=4)
    lamp_icon_strip(b, 404, 86, [("arrow_l", "turnL", GRN), ("arrow_r", "turnR", GRN)], gap=6)
    prndl(b, 410, 100, pitch=7, color="#ff8a3a")
    lower_curvy6(b, y0=122)
    inset(b, 512, 40, 272, 122, "blackp", "seam")
    vent_louvered(b, 516, 42, 88, 20, bezel="blackp", on=Z_FACE, wheel="left")       # 88 px, the boxy consoles' (Oct 29 2026:
    vent_louvered(b, 692, 42, 88, 20, bezel="blackp", on=Z_FACE, wheel="right")      # the maker's mark gets an 88 px slot)
    headunit_slot(b, 520, 68, frame="bezel")
    ash_tray(b, 705, 68, chrome=False)
    hazard_under_ash(b)
    climate_sliders(b, 532, 130, w=126)
    plaque(b, 560, 31, 172, 7, style="flat", role="full", font="35", color="#3a3226", check=False)


def suv(b):
    """Franklin All-Terrain: chunky early 90s, a square-shouldered pod, speedometer and tach with four gauges, rubber knobs"""
    shell_curvy(b, pill=(18, 24, 464, 92, 16), end_y=26, console_top=22)
    nd = "#ff6a2a"
    small_dial(b, 64, 47, 18, "oil", "L", "H", label="OIL", bezel="blackp", needle=nd)
    small_dial(b, 64, 88, 16, "volts", "8", "18", label="VOLT", bezel="blackp", needle=nd)
    # Nov 6 2026 (Roadworthy): the coolant and belt lamps, a fifth in each column
    lamp_col(b, 92, 28, 30, [("@batt", "genLamp", RED), ("@oil", "oilLamp", RED), ("@brake", "brakeLamp", RED),
                             ("@temp", "tempLamp", RED), L_LT])
    dial(b, 178, 66, 38, 135, 405, *MPH100, "speed_mph", 100, minor=1, bezel="blackp", bezel_w=2, label="MPH", label_y=78, needle=nd, hub=3.0)
    odo_under(b, 178, 66, 38)
    dial(b, 288, 68, 32, 135, 375, list(range(0, 7)), [str(i) for i in range(7)], "rpm", 6000, minor=1, bezel="blackp", bezel_w=2,
         redzone=5, label="RPM", label2="X1000", label_y=76, needle=nd)
    lamp_col(b, 334, 28, 34, [L_4X4, ("@beam", "hiBeam", BLU), ("@engine", "engLamp", AMB), ("@belt", "beltLamp", RED), L_RT])
    small_dial(b, 410, 47, 18, "temp", "C", "H", icon="temp", bezel="blackp", red_right=True, needle=nd)
    small_dial(b, 410, 88, 16, "fuel", "E", "F", label="FUEL", bezel="blackp", red_left=True, needle=nd, low_src="fuelLamp")
    prndl(b, 222, 104, pitch=7, color="#ff8a3a", window_=False) if False else None
    lower_curvy6(b, y0=122)
    inset(b, 512, 34, 272, 128, "blackp", "seam")
    vent_louvered(b, 516, 36, 96, 22, bezel="blackp", on=Z_FACE, wheel="left")
    vent_louvered(b, 684, 36, 96, 22, bezel="blackp", on=Z_FACE, wheel="right")
    headunit_slot(b, 520, 64, frame="bezel")
    ash_tray(b, 705, 64, chrome=False)
    hazard_under_ash(b)
    climate_knobs(b, 556, 136, pitch=50, r=10, mat="rubber")
    plaque(b, 622, 41, 48, 9, style="flat", role="sub", font="57", color="#d84a2a", check=True)


# =================================================================================== RPM first
def cossette(b):
    """Chevalier Cossette: red, a digital cluster in a proud pod, the tach the arc and speed the figures inside it"""
    shell_boxy(b, pod=(56, 444), open_rect=(66, 22, 368, 94), trim="rubber", grille=False, top_y=4)
    cl_cossette(b)
    lower_boxy6(b, y0=120, chrome=False)
    inset(b, 504, 26, 282, 136, "blackp", "seam")
    console_vents(b, 28, chrome=False, w=88, h=28)
    plaque(b, 602, 31, 86, 10, style="script", role="model", font="57", color="#e8e8e8", shadow="#3a0a08")
    plaque(b, 602, 44, 86, 7, style="flat", role="sub", font="35", color="#ff3a20", check=False)
    headunit_slot(b, 516, 64, frame="bezel")
    ash_tray(b, 704, 64, chrome=False)
    climate_sliders(b, 532, 130, w=126)
    hazard_under_ash(b)


def race(b):
    """Race car: a riveted aluminium panel, the tach biggest with a shift light, toggles on label tape, sponsor decals"""
    shell_panel(b)
    d = b.d; M = d.M
    nd = "#ff3a1a"
    sp = M().rrect(500, 28, 284, 128, 3).get()
    d.flat(sp, Z_FACE + 0.8, "blackp", polish=0.1)
    d.tex[sp & (plane(d.rng, (H, W)) > 0.55)] += 0.07
    for (x, y) in ((506, 34), (778, 34), (506, 150), (778, 150)):
        d.dome(x, y, 1.8, 1.8, 1.0, "chrome", polish=1.0, on=Z_FACE + 0.8)
    dial(b, 250, 92, 58, 150, 390, list(range(0, 10)), [str(i) for i in range(10)], "rpm", 9000, minor=1, bezel="chrome", bezel_w=3,
         redzone=7, label="RPM", label2="X1000", label_y=112, needle=nd, on=Z_FACE, hub=3.5)
    d.torus(250, 26, 4, 6.5, 1.8, "chrome", polish=1.0, on=Z_FACE)
    sl = np.hypot(d.XX + 0.5 - 250, d.YY + 0.5 - 26) < 4
    d.h[sl] = Z_FACE + 1.5; d.mat[sl] = d.mid("paint_r"); d.polish[sl] = 1.0
    b.part("lamp", src="shiftLamp", color="#ff5a3a", runs=runs_of(np.hypot(d.XX + 0.5 - 250, d.YY + 0.5 - 26) < 3.2))
    b.label("SHIFT", 262, 24, "paint_r")
    dial(b, 112, 92, 34, 135, 405, list(range(0, 161, 20)), ["0", "", "40", "", "80", "", "120", "", "160"], "speed_mph", 160,
         minor=1, bezel="chrome", bezel_w=2, label="MPH", label_y=104, needle=nd, on=Z_FACE)
    for key, src, cx, cy, labs in (("OIL", "oil", 386, 60, ("0", "80")), ("WATER", "temp", 452, 60, ("C", "H")),
                                   ("FUEL", "fuel", 386, 122, ("E", "F")), ("VOLTS", "volts", 452, 122, ("8", "16"))):
        dial(b, cx, cy, 24, 150, 390, [0, 1, 2, 3, 4], None, src, 1, minor=0, bezel="chrome", bezel_w=2, on=Z_FACE, needle=nd,
             hub=2.0, low_src="fuelLamp" if src == "fuel" else None)
        d.text(labs[0], cx - 13, cy + 9, "paint_w", align="c"); d.text(labs[1], cx + 13, cy + 9, "paint_w", align="c")
        d.text(key, cx, cy + 15, "paint_c", align="c")
    # Nov 6 2026 (Roadworthy; the director: "Oil and water only", no belt lamp under a harness, no high beam): two red
    # warning jewels between the tach and the gauges, the shift light's kind, each on its strip of label tape
    for src, lab, jy in (("oilLamp", "OIL", 48), ("tempLamp", "WATER", 90)):
        jx = 336
        b.check_flat(jx - 10, jy - 10, 20, 20, f"jewel {lab}")
        d.torus(jx, jy, 5, 8, 1.8, "chrome", polish=1.0, on=Z_FACE)
        jm = np.hypot(d.XX + 0.5 - jx, d.YY + 0.5 - jy) < 5
        d.h[jm] = Z_FACE + 1.5; d.mat[jm] = d.mid("paint_r"); d.polish[jm] = 1.0
        b.part("lamp", src=src, color="#ff3a20", runs=runs_of(np.hypot(d.XX + 0.5 - jx, d.YY + 0.5 - jy) < 4.2))
        dymo(d, lab, jx, jy + 11, on=Z_FACE, align="c")
    zt = Z_FACE + 0.8
    for i, (lab, src, hid) in enumerate((("IGN", "keysIn", "ignition"), ("FUEL", "running", None), ("FAN", "heaterOn", "fan"),
                                        ("LIGHTS", "lights", "lights"))):
        cx = 530 + i * 42
        dymo(d, lab, cx, 50, on=zt, align="c")
        toggle(d, cx, 80, up=False, on=zt)
        toggle_variant(b, cx, 80, src, zt, base_up=False)
        if hid: b.hit(hid, cx - 8, 66, 16, 28, needs="hasHeater" if hid == "fan" else None)
    d.torus(714, 78, 9, 12.5, 2.4, "chrome", polish=1.0, on=zt)
    st = np.hypot(d.XX + 0.5 - 714, d.YY + 0.5 - 78) <= 9
    d.h[st] = zt + 3.0 * np.sqrt(np.clip(1 - (np.hypot(d.XX[st] + 0.5 - 714, d.YY[st] + 0.5 - 78) / 9) ** 2, 0, 1))
    d.mat[st] = d.mid("paint_r"); d.polish[st] = 0.9
    dymo(d, "START", 714, 94, on=zt, align="c")
    b.hit("ignition", 702, 66, 25, 25)
    bolt = M().poly([(752, 52), (766, 52), (760, 64), (770, 64), (750, 84), (756, 68), (746, 68)]).get()
    d.paint(bolt & sp, "paint_y", flatlight=True)
    d.dome(758, 98, 6, 6, 2.5, "paint_r", polish=0.8, on=zt)
    d.text("KILL", 758, 108, "paint_w", align="c")
    b.hit("ignition", 751, 91, 15, 15)
    d.torus(560, 128, 6, 8.5, 2.0, "paint_r", polish=0.9, on=zt)
    d.text("FIRE", 560, 140, "paint_r", align="c")

    def decal(x, y, w, h, bg, fg, lines, r=2):
        m = M().rrect(x, y, w, h, r).get()
        d.paint(m, bg, flatlight=True)
        d.paint(m & (edt(m) <= 1), "paint_w", flatlight=True)
        yy = y + (h - 6 * len(lines)) // 2 + 1
        for t in lines:
            d.text(t, x + w // 2, yy, fg, align="c", flatlight=True); yy += 6
    decal(600, 118, 70, 22, "paint_y", "face", ["KNOX", "MOTOR OIL"])
    decal(682, 118, 92, 13, "paint_r", "paint_w", ["WEST POINT SPEEDWAY"])
    decal(682, 136, 92, 13, "face", "paint_y", ["MULDRAUGH AUTO PARTS"])
    toggle(d, 34, 138, up=True, on=Z_FACE); dymo(d, "WIPER", 34, 150, on=Z_FACE, align="c")
    d.torus(80, 140, 5, 7, 1.6, "chrome", polish=1.0, on=Z_FACE); d.dome(80, 140, 5, 5, 2.4, "blackp", polish=0.7, on=Z_FACE)
    dymo(d, "HORN", 80, 150, on=Z_FACE, align="c")
    num = M().rrect(166, 130, 34, 26, 4).get()
    d.paint(num, "paint_w", flatlight=True)
    d.text("12", 183, 134, "face", align="c", scale=3, flatlight=True)


# =================================================================================== fleet, plain
def police(b):
    """Police: patrol navy, a certified speedometer, four gauges and a clock; the siren controller on the console"""
    shell_boxy(b, trim="silver")
    cl_cert(b)
    lower_boxy6(b, y0=118, chrome=False, cruise=False)
    con_fleet(b, top="siren")


def taxi(b):
    """Taxi: a Nyala made plain, black vinyl, the fare meter on the console (no siren controller)"""
    shell_boxy(b, trim="silver")
    cl_nyala(b, bz="blackp", nd="#ffb02e")
    lower_boxy6(b, y0=118, chrome=False, cruise=False)
    con_fleet(b, top="meter")


def ambulance(b):
    """Ambulance: a Valuline made plain, medic grey; the emergency switches on the lower dash"""
    shell_boxy(b, trim="rubber")
    cl_van(b, bz="blackp", nd="#ff7a2a")
    # (Nov 7 2026: room for the key's ACC legend. The switches stay 24 apart, their legends a clear 4 px between; the
    # plate trims a pixel of margin either side (3, 4 before) and the lower row's spread sets it 3 px nearer the
    # column, and the key 3 px further right: ACC 4 px clear of the plate, as of OFF on the other dashes)
    px_ = lower_boxy6(b, y0=118, chrome=False, cruise=False, trunk_label="REAR", trunk_sub="DOORS", right_panel=5 * 24 + 6)
    rocker_panel(b, px_, 122, [("LIGHT", "lbarLamp", "lbar"), ("SIREN", "sirenLamp", "siren"), ("FLOOD", None, None),
                              ("SCENE", None, None), ("DOME", None, None)], pitch=24, margin=3)
    console_vents(b, 26, chrome=False, w=88, h=30)
    badge(b, 602, 35, 86, 12, style="stencil", role="unit", font="35", color="#e8e8e0", plate="stencil")
    headunit_slot(b, *HU6, frame="bezel")
    no_smoking(b, *ASH6)
    climate_levers(b, 548, 128, chrome=False, fan_knob=(752, 140))


def fire(b):
    """Fire department pickup: a D6 made plain on fire-red vinyl, the siren controller on the console"""
    shell_boxy(b, trim="rubber", face_mat="steel")
    cl_d6(b, bz="blackp", nd="#ffd040")
    lower_boxy6(b, y0=118, chrome=False, cruise=False, trunk_label="BED", trunk_sub="LOCK")
    con_fleet(b, top="siren")


def ranger(b):
    """Park ranger: a Nyala made plain on forest-green vinyl, the lightbar controller on the console"""
    shell_boxy(b, trim="silver")
    cl_nyala(b, bz="blackp", nd="#f0ece0")
    lower_boxy6(b, y0=118, chrome=False, cruise=False)
    con_fleet(b, top="siren")


# id: (preview name, lead cabin vinyl (CABINS below), seed, builder, sub line, fleet unit line, radio fitted in the previews)
DESIGNS = {
    "luxury":     ("Mercia Lang 4000", "l_brown", 12, luxury, None, None, "premium"),
    "nyala":      ("Chevalier Nyala", "v_moss", 41, nyala, None, None, "valutech"),
    "cossette":   ("Chevalier Cossette", "l_brown", 32, cossette, "5.0", None, "premium"),
    "police":     ("Meade Sheriff", "v_black", 51, police, None, "MEADE - UNIT 26", "ham"),
    "d6":         ("Chevalier D6", "v_moss", 42, d6, "D6", None, "valutech"),
    "dashelite":  ("Dash Elite", "v_beige_d", 21, dashelite, "EFI", None, "premium"),
    "primani":    ("Chevalier Primani", "v_beige_d", 22, primani, "EFI", None, "premium"),
    "dart":       ("Chevalier Dart", "v_maroon", 43, dart, None, None, "makeshift"),
    "horizon":    ("Masterson Horizon", "v_maroon", 13, horizon, None, None, "valutech"),
    "wagon":      ("Chevalier Cerise Wagon", "v_walnut", 11, wagon, None, None, "valutech"),
    "suv":        ("Franklin All-Terrain", "v_beige_d", 23, suv, "4X4", None, "premium"),
    "van":        ("Franklin Valuline", "v_maroon", 44, van, None, None, "valutech"),
    "bulldriver": ("Dash Bulldriver", "v_moss", 45, bulldriver, "V8", None, "valutech"),
    "rancher":    ("Dash Rancher", "v_moss", 46, rancher, "4X4", None, "army"),
    "taxi":       ("Taxi", "v_black", 52, taxi, None, "TAXI - CAB 26", "valutech"),
    "ambulance":  ("Ambulance", "v_black", 53, ambulance, None, "AMBULANCE - UNIT 26", "ham"),
    "fire":       ("Fire Department Chevalier D6", "v_black", 54, fire, None, "FIRE - ENGINE 26", "ham"),
    "ranger":     ("Ranger Chevalier Nyala", "v_black", 55, ranger, None, "RANGER - UNIT 26", "ham"),
    "race":       ("Race car", "v_race", 31, race, None, None, None),
}
ORDER = list(DESIGNS)

# The cabin colors (director, Nov 12 2026: "We're not changing any looks. We're just changing colors."; handoff
# ZeDUI/HANDOFF_design_dash_interior_colors_20261112.md). Each civilian dash ships in its group's three cabin vinyls,
# lead first (the lead is DESIGNS' cabin: the previews' and the game's fallback); the fleet dashes in standard black
# only; the race car keeps its own and is not in the round. Only the `cabin` vinyl changes: wood, faces, gauges, parts
# and click areas are the same in every color (the export checks the parts file is). (name, ramp): the names are the
# handoff's, for the review sheets. The game picks the color per car from its paint (ZeD_DashProto.lua's odds).
S70 = [("moss green", "v_moss"), ("light brown", "v_ltbrown"), ("slate blue", "v_navy70")]
S80 = [("maroon", "v_maroon"), ("navy", "v_navy"), ("beige", "v_beige_d")]
S90 = [("beige", "v_beige_d"), ("gray", "v_grey"), ("black", "v_black")]
LUX = [("brown leather", "l_brown"), ("red leather", "l_red"), ("black leather", "l_black")]
BLK = [("black", "v_black")]
CABINS = {
    "wagon": [("brown", "v_walnut"), ("slate blue", "v_navy70"), ("army green", "v_army")],
    "cossette": LUX, "luxury": LUX,
    "dashelite": S90, "primani": S90, "suv": S90,
    "nyala": S70, "d6": S70, "bulldriver": S70, "rancher": S70,
    "horizon": S80, "dart": S80, "van": S80,
    "police": BLK, "taxi": BLK, "ambulance": BLK, "fire": BLK, "ranger": BLK,
}
for _did, _cabs in CABINS.items():
    assert DESIGNS[_did][1] == _cabs[0][1], f"{_did}: DESIGNS' cabin is not its lead color"


def cabins(did):
    """a design's cabin ramps, lead first (the race car: its own one)"""
    return [r for _, r in CABINS[did]] if did in CABINS else [DESIGNS[did][1]]

# The console's maker mark (brands.py; director, Oct 29 2026: "The whole idea is to replace the generic plaques with
# branding"). Per civilian dash: its own maker, whether the console carries the model line (the Cerise Wagon and the
# Horizon wear the model on the driver's side already), and whether it is a curved console (the mark between the vents;
# the rim's name line is gone). The model line is the title's model and the design's sub line as its performance tag,
# the tag left out where it repeats the model (the D6). The game picks the mark by the car's own maker, not by the dash.
# The fleet dashes keep their unit stencils and the race car has no badge: none here.
BRANDS = {
    "luxury":     dict(maker="mercia"),
    "nyala":      dict(maker="chevalier"),
    "cossette":   dict(maker="chevalier"),
    "d6":         dict(maker="chevalier"),
    "dashelite":  dict(maker="dash", curvy=True),
    "primani":    dict(maker="chevalier", curvy=True),
    "dart":       dict(maker="chevalier"),
    "horizon":    dict(maker="masterson", model_line=False),
    "wagon":      dict(maker="chevalier", model_line=False),
    "suv":        dict(maker="franklin"),
    "van":        dict(maker="franklin"),
    "bulldriver": dict(maker="dash"),
    "rancher":    dict(maker="dash"),
}


# =================================================================================== at night (night.py, director Oct 21 2026)
# No gauge is backlit. Behind the plate, in front of each gauge, a small incandescent bulb sits on ONE side of the
# opening, just out of sight (never drawn): its light washes across the face from that side, bright at the near edge
# and dying toward the far one. The plate round the openings stays dark but for a faint spill on the rim. A lamp under
# the dash's brow aims down at the controls (the radio, the climate, the switches) and dies away downward.
#   wash:  side = where the hidden bulbs sit, in screen degrees (0 right, 90 down, 180 left, 270 up), each gauge
#          a little off it (jitter) and its own strength (an old bulb, a dusty lens); power scales them all.
#          The openings are found from the gauges' own parts (a needle's pivot, the clock, the ribbon's window);
#          a VFD cluster lights itself and gets none.
#          bulbs=n (spread, each): n bulbs behind each face, spread round that side (the late models: GREEN_WASH)
#   lamps: (x0, x1, y, z, power[, reach][, tint])     a row of points under a hood, aimed down
#   tint:  the bulb's colour, by name (night.TINTS): wash=dict(..., tint="green"), a lamp row's last item. None named
#          is amber, the 2700 K bulb. Director, Oct 29 2026: the late models (the Dash Elite, the Primani, the SUV,
#          the Lang 4000's clock) light their gauges blue-green, the early-90s GM way, and keep amber lamps over the
#          controls; the Cossette's pod lights itself, so its lamps are the green ones. Everything else stays amber.
CONSOLE_LAMP = (512, 776, 24, Z_FACE + 12.0, 1.0)        # under the console's top lip, over the radio and the climate
LOWER_LAMP = (34, 466, 115, Z_FACE + 10.0, 0.5)         # under the cluster's sill, over the lower row of switches
CURVY_LAMPS = lambda top: [(514, 774, top, Z_FACE + 12.0, 1.0), (34, 470, 120, Z_FACE + 8.0, 0.5)]
GREEN = "green"
tinted = lambda lamp, tint: tuple(lamp) + (tint,)
# a needle on a gauge lit green keeps its own orange and takes only the light's level, as if light-piped (how GM did
# it: orange under a green multiply goes olive). Director's pick, Oct 29 2026: "b, keep the orange needles". ("lit",
# the needles taking the green like everything else, stays in the code: the night sheets' --needles lit.)
NEEDLES_UNDER_TINT = "own"
# the late models' green clusters: three bulbs behind each face, spread over 140 degrees round the wash's side, each
# at 0.45 of the one bulb (director, Oct 29 2026: "add a couple more backlight bulbs to the moderns ... not as bright
# as today, but brighter than the amber"). Measured: the faces' mean light 1.33 to 1.47 times the amber dashes', no
# face lit to the top more than the amber ones are
GREEN_WASH = dict(tint=GREEN, bulbs=3, spread=140.0, each=0.45)
# the Cossette's green lamps (its pod lights itself): each lamp's hood holds more bulbs, 1.9 times the power
GREEN_LAMP = lambda lamp: tinted(tuple(lamp[:4]) + (lamp[4] * 1.9,) + tuple(lamp[5:]), GREEN)
LEFT, UPPER_LEFT, TOP, UPPER_RIGHT = 180.0, 215.0, 270.0, 320.0

NIGHT = {
    # wood and chrome: the bulbs sit behind the walnut fascia on the gauges' left
    "wagon":      dict(wash=dict(side=LEFT, power=1.0), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    "luxury":     dict(wash=dict(side=LEFT, power=1.0, **GREEN_WASH), lamps=[CONSOLE_LAMP, LOWER_LAMP]),    # the clock (the VFD lights itself)
    "horizon":    dict(wash=dict(side=UPPER_LEFT, power=1.0), lamps=[(512, 776, 22, Z_FACE + 12.0, 1.0), LOWER_LAMP]),
    # vinyl and chrome: the same bulbs behind a black (steel, aluminium, painted) fascia, from the top edge
    "nyala":      dict(wash=dict(side=TOP, power=1.0), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    "dart":       dict(wash=dict(side=UPPER_LEFT, power=1.0), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    "d6":         dict(wash=dict(side=TOP, power=1.0), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    "van":        dict(wash=dict(side=TOP, power=0.9), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    "bulldriver": dict(wash=dict(side=UPPER_RIGHT, power=1.0), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    "rancher":    dict(wash=dict(side=LEFT, power=0.95), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    # fleet: the same, plain
    "police":     dict(wash=dict(side=TOP, power=1.0), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    "taxi":       dict(wash=dict(side=TOP, power=0.95), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    "ambulance":  dict(wash=dict(side=TOP, power=1.0), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    "fire":       dict(wash=dict(side=TOP, power=1.0), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    "ranger":     dict(wash=dict(side=TOP, power=0.95), lamps=[CONSOLE_LAMP, LOWER_LAMP]),
    # early 90s curves: from under the arched brow
    "dashelite":  dict(wash=dict(side=UPPER_LEFT, power=1.0, **GREEN_WASH), lamps=CURVY_LAMPS(30)),
    "primani":    dict(wash=dict(side=UPPER_RIGHT, power=1.0, **GREEN_WASH), lamps=CURVY_LAMPS(34)),
    "suv":        dict(wash=dict(side=TOP, power=1.0, **GREEN_WASH), lamps=CURVY_LAMPS(28)),
    # RPM first: the Cossette's digital pod lights itself (no gauge bulbs); the race car's dials are lit from the left,
    # the switch panel by a lamp under the cage bar
    "cossette":   dict(lamps=[GREEN_LAMP(CONSOLE_LAMP), GREEN_LAMP(LOWER_LAMP)]),     # its lamps green: the one exception
    "race":       dict(wash=dict(side=LEFT, power=1.05), lamps=[(512, 772, 32, Z_FACE + 10.0, 0.9)]),
}
