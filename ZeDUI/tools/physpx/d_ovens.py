"""The ovens: one plate per model the game has (the IsoStove 'stove' tiles), each its era's real controls.

Every oven shares the game's state: on or off, a temperature stop (0, 50 ... 300 degrees C), a timer (minutes),
and power. A printed thermostat is one dial in either unit: its angle is the true temperature, so a stop lands
where it really is on the Fahrenheit print and on its figure on the Celsius print (the player's setting picks
the print; the Celsius print is a state sprite). Burner controls the game has no state for are part of the look.
"""
import math

import numpy as np
from scipy import ndimage as ndi

from physlib import *            # noqa: F401,F403
import wear as WR

C2F = lambda c: c * 9 / 5 + 32
OVEN_TEMPS = (0, 50, 100, 150, 200, 250, 300)


def oven_angle_f(f): return -50 + (f - 150) * 0.6       # 150 F at -50 degrees ... 550 F at 190
def oven_angle_c(c): return oven_angle_f(C2F(c))
OVEN_OFF_A = -90
OVEN_STOP_ANGLES = [OVEN_OFF_A] + [round(oven_angle_c(c), 1) for c in OVEN_TEMPS[1:]]


def thermostat_scale(p, cx, cy, r_in, units, mat="paint_k", wear=0.0, off_label="OFF"):
    """the printed thermostat: OFF, then 200 to 500 F (or 100 to 300 C) with the minor marks between"""
    if units == "F":
        return scale_ring(p, cx, cy, r_in, [OVEN_OFF_A] + [oven_angle_f(f) for f in (200, 300, 400, 500)],
                          [off_label, "200", "300", "400", "500"], minor_angles=[oven_angle_f(f) for f in (150, 250, 350, 450, 550)],
                          mat=mat, wear=wear)
    return scale_ring(p, cx, cy, r_in, [OVEN_OFF_A] + [oven_angle_c(c) for c in (100, 150, 200, 250, 300)],
                      [off_label, "100", "150", "200", "250", "300"], minor_angles=[oven_angle_c(c) for c in (50, 75, 125, 175, 225, 275)],
                      mat=mat, wear=wear)


def minutes_scale(p, cx, cy, r_in, mat="paint_k", wear=0.0, a0=-90, a1=210, top=120):
    """a wind-up timer's scale: 0 to `top` minutes, linear"""
    ta = lambda m: a0 + (a1 - a0) * m / top
    step = 30 if top == 120 else 15
    return scale_ring(p, cx, cy, r_in, [ta(m) for m in range(0, top + 1, step)], [str(m) for m in range(0, top + 1, step)],
                      minor_angles=[ta(m) for m in range(0, top, 10 if top == 120 else 5) if m % step], mat=mat, wear=wear)


def state(tempC=0, minutes=0, on=False, hour=10, minute=8, celsius=False, powered=True, **kw):
    """a preview state, the way the game's side derives it"""
    stop = OVEN_TEMPS.index(min(OVEN_TEMPS, key=lambda t: abs(t - tempC)))
    s = dict(ovenStop=stop, timerF=min(1.0, minutes / 120.0), timerMin=minutes, on=on and powered, switched=on, hour=hour,
             minute=minute, celsius=celsius, power=powered, powered=powered)
    s.update(kw)
    return s


# =================================================================================== green, 1956
def green_range(units="F", on=False, worn=True):
    W, H = 456, 128
    p = Plate("oven_green", W, H, seed=11, title="1956 range")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 6).get()
    d.slab(body, Z_FACE, "enamel_mint", bevel=3.0, polish=0.75)
    spears = d.cyl(10, 5, W - 20, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    spears |= d.cyl(10, H - 8, W - 20, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    # the control centre: brushed aluminium in a chrome frame, a step proud of the enamel
    cx0, cy0, cw, ch = 118, 14, 220, 100
    F = Z_FACE + 1.2
    cc = rbox(d, cx0, cy0, cw, ch)
    d.flat(cc, F, "alu", polish=0.5); d.grain_brushed(cc, 0.05 if worn else 0.03, seed=4)
    chrome_frame(d, cx0 - 2, cy0 - 2, cw + 4, ch + 4, Z_FACE, t=2, mat="chrome", z=2.0)
    clock_face(p, 154, 64, 28, face="cream", on=F, depth=1.6)
    p.part("clock", cx=154, cy=64, rh=13, rm=21, color="#1c1b17")
    # the Minute Minder: 0 to 120 minutes, the pointer unwinds as the timer runs
    mx, my = 222, 50
    fluted_knob(p, mx, my, 9, on=F, dome=0.9 if worn else 0.0)
    minutes_scale(p, mx, my, 13.5, wear=0.10 if worn else 0)
    p.label("MINUTE MINDER", mx, 77, "paint_k", align="c")
    p.part("ptr", src="timerF", cx=mx, cy=my, r0=1, r1=7, a0=-90, a1=210, color="#7a1a12", w=1)
    p.hit("timer", mx - 13, my - 13, 26, 26, needs="powered", kind="turn")
    # the thermostat
    ox, oy = 290, 50
    fluted_knob(p, ox, oy, 9, on=F, dome=0.9 if worn else 0.0)
    thermostat_scale(p, ox, oy, 13.5, units, wear=0.12 if worn else 0)
    p.label("OVEN", ox, 77, "paint_k", align="c")
    p.part("ptr", src="ovenStop", cx=ox, cy=oy, r0=1, r1=7, angles=OVEN_STOP_ANGLES, color="#7a1a12", w=1)
    p.hit("heat", ox - 13, oy - 13, 26, 26, needs="powered", kind="turn")
    # the ON and OFF keys (interlocked) and the pilot jewel
    keys = piano_keys(p, 228, 92, ["ON", "OFF"], 20, 11, 0 if on else 1, mat="cream", on=F)
    p.hit("on", *keys[0], needs="powered"); p.hit("off", *keys[1], needs="powered")
    jewel(p, 282, 97, 4.0, on=F)
    p.lamp(disc(d, 282, 97, 4.0), "on", "#ffa630")
    # the surface burners: part of the look (the game heats the whole stove as one)
    for bx, which in ((34, "LR"), (86, "LF"), (370, "RF"), (422, "RR")):
        kn = fluted_knob(p, bx, 64, 10, on=Z_FACE, dome=0.9 if worn else 0.0)
        baked_pointer(p, kn, -90, 1, 8)
        scale_ring(p, bx, 64, 13.5, [-90, 180, 45], ["OFF", "HI", "LO"], minor_angles=[150, 120, 90, 67], wear=0.22 if worn else 0)
        burner_icon(p, bx - 3, 83, which)
        p.hit("burner" + which, bx - 12, 52, 24, 24, kind="look")
    nameplate(d, "HOLLISTER", 60, 17, on=Z_FACE, mat="chrome", font="57", align="c", z=1.4)
    nameplate(d, "CUSTOM", 396, 17, on=Z_FACE, mat="chrome", font="57", align="c", z=1.4)
    if worn:
        en = WR.mat_mask(d, "enamel_mint")
        WR.gloss(d, en, band=(0.31, 60, 12, 0.13))
        WR.gloss(d, en, band=(0.31, 73, 2, 0.13))
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 200, 20, 0.105, 280, 338, 0.045)
        WR.grime(d, d.solid, amount=0.30, seed=5)
        WR.chips(d, WR.face(d, Z_FACE, body), 0.004, seed=7, near=2.5)
        WR.pits(d, spears, 0.003, seed=9)
        WR.aged_face(d, 154, 64, 28, amount=0.12)
    return p


# =================================================================================== red, 1962
def red_range(units="F", worn=True):
    """a 1962 electric range: red enamel, a brushed strip of push-button surface controls (one row of keys per
    burner, OFF held down), the oven selector, the thermostat, a wind-up timer and the signal lamp"""
    W, H = 456, 146
    p = Plate("oven_red", W, H, seed=12, title="1962 range")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 5).get()
    d.slab(body, Z_FACE, "enamel_red", bevel=3.0, polish=0.75)
    trim = d.cyl(8, 4, W - 16, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    trim |= d.cyl(8, H - 7, W - 16, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    # the push-button strip
    sx0, sy0, sw, sh = 12, 11, W - 24, 44
    F = Z_FACE + 1.0
    strip = rbox(d, sx0, sy0, sw, sh)
    d.flat(strip, F, "alu", polish=0.5); d.grain_brushed(strip, 0.05 if worn else 0.03, seed=14)
    chrome_frame(d, sx0 - 1, sy0 - 1, sw + 2, sh + 2, Z_FACE, t=1, mat="chrome", z=1.6)
    for gcx, which in ((80, "LR"), (179, "LF"), (278, "RF"), (377, "RR")):
        gx0 = gcx - 29
        burner_icon(p, gcx - 3, sy0 + 4, which)
        piano_keys(p, gx0, sy0 + 16, ["", "1", "2", "3", "4", "HI"], 9, 13, 0, mat="enamel_white", on=F, frame="chrome",
                   mats=["bakelite", "enamel_white", "enamel_white", "enamel_white", "enamel_white", "enamel_white"])
        p.label("OFF", gx0 + 4, sy0 + 34, "paint_k", align="c", wear=0.15 if worn else 0)
        p.label("HI", gx0 + 54, sy0 + 34, "paint_k", align="c")
        p.hit("burner" + which, gx0, sy0 + 16, 59, 13, kind="look")
    # the oven: selector, thermostat, timer, signal lamp; cream print on the enamel
    ky = 98
    sel = insert_knob(p, 176, ky, 9, on=Z_FACE, insert_r=2.6)
    scale_ring(p, 176, ky, 13.5, [-90, -30, 30], ["OFF", "BAKE", "BROIL"], mat="paint_c", wear=0.10 if worn else 0)
    p.label("OVEN", 176, 125, "paint_c", align="c", auto_ink=False)
    p.part("ptr", src="switched", cx=176, cy=ky, r0=3.5, r1=7.5, angles=[-90, -30], color="#ece6d4", w=1)
    p.hit("onoff", 176 - 13, ky - 13, 26, 26, needs="powered")
    insert_knob(p, 258, ky, 11, on=Z_FACE, insert_r=3.0)
    thermostat_scale(p, 258, ky, 15.5, units, mat="paint_c", wear=0.10 if worn else 0)
    p.label("TEMPERATURE", 258, 129, "paint_c", align="c", auto_ink=False)
    p.part("ptr", src="ovenStop", cx=258, cy=ky, r0=4, r1=9.5, angles=OVEN_STOP_ANGLES, color="#ece6d4", w=1)
    p.hit("heat", 258 - 15, ky - 15, 30, 30, needs="powered", kind="turn")
    insert_knob(p, 344, ky, 9, on=Z_FACE, insert_r=2.6)
    minutes_scale(p, 344, ky, 13.5, mat="paint_c", wear=0.08 if worn else 0)
    p.label("MINUTES", 344, 125, "paint_c", align="c", auto_ink=False)
    p.part("ptr", src="timerF", cx=344, cy=ky, r0=3.5, r1=7.5, a0=-90, a1=210, color="#ece6d4", w=1)
    p.hit("timer", 344 - 13, ky - 13, 26, 26, needs="powered", kind="turn")
    jewel(p, 410, ky, 4.0, off="jewel_red_off", on=Z_FACE)
    p.lamp(disc(d, 410, ky, 4.0), "on", "#ff5a3a")
    p.label("SIGNAL", 410, ky + 9, "paint_c", align="c", auto_ink=False)
    # the maker
    nameplate(d, "MERIDIAN", 78, 84, on=Z_FACE, mat="chrome", font="57", align="c", z=1.4)
    p.label("ELECTRIC RANGE", 78, 96, "paint_c", align="c", auto_ink=False)
    if worn:
        en = WR.mat_mask(d, "enamel_red")
        WR.gloss(d, en, band=(0.35, 120, 12, 0.12))
        WR.gloss(d, en, band=(0.35, 134, 2, 0.12))
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 150, 26, 0.10, 330, 444, 0.04)
        WR.grime(d, d.solid, amount=0.30, seed=15)
        WR.chips(d, WR.face(d, Z_FACE, body), 0.004, seed=16, near=2.5)
        WR.pits(d, trim, 0.003, seed=17)
    return p


# =================================================================================== shared bits for the electric and gas knobs
def electric_knob(p, cx, cy, r=10, on=Z_FACE, cap="blackp", skirt=1.6, ptr_mat="paint_w", worn=True):
    """an 80s surface-unit knob (look only): black, a bright skirt, the pointer moulded in at OFF; its scale:
    OFF at the top, HI a sixth of a turn on, down round the bottom to LO"""
    kn = fluted_knob(p, cx, cy, r, on=on, z=3.6, mat=cap, skirt=skirt, skirt_mat="chrome", ridges=20, dome=0.7 if worn else 0)
    baked_pointer(p, kn, -90, 1, r - 2, mat=ptr_mat)
    scale_ring(p, cx, cy, r + skirt + 2.0, [-90, -30, 150], ["OFF", "HI", "LO"], minor_angles=[0, 30, 60, 90, 120],
               mat="paint_k", wear=0.18 if worn else 0)
    return kn


def gas_knob(p, cx, cy, r=10, on=Z_FACE, cap="alu", ptr_mat="paint_k", worn=True):
    """a gas burner knob (look only): OFF at the top, full flame a quarter turn anticlockwise, LO near the end"""
    kn = fluted_knob(p, cx, cy, r, on=on, z=4.0, mat=cap, skirt=None, ridges=26, dome=0.8 if worn else 0)
    baked_pointer(p, kn, -90, 1, r - 2, mat=ptr_mat)
    scale_ring(p, cx, cy, r + 2.5, [-90, 180, 45], ["OFF", "HI", "LO"], minor_angles=[150, 120, 90, 67], mat="paint_k",
               wear=0.18 if worn else 0)
    return kn


def vfd(p, x, y, w, h, on, color, ghost, digits_at, n=5, cw=9, ch=15, pitch=13, st=2):
    """a fluorescent display behind the glass: its dark window and the live figures (part 'digits')"""
    d = p.d
    d.flat(rbox(d, x, y, w, h), on - 0.2, "vfd", polish=0.6)
    dx, dy = digits_at
    p.part("digits", src="vfdText", x=dx, y=dy, cw=cw, ch=ch, pitch=pitch, st=st, n=n, color=color, ghost=ghost, align="r")
    p.ink_rect(dx, dy, n * pitch, ch, "display figures")


# =================================================================================== grey, 1985
def grey_range(worn=True):
    """a 1985 electric range: brushed steel, a black glass control in the middle with a blue-green display
    (the time of day; the oven's temperature while it bakes; the timer counting down) and touch pads"""
    W, H = 456, 120
    p = Plate("oven_grey", W, H, seed=13, title="1985 electric range")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 4).get()
    d.slab(body, Z_FACE, "alu", bevel=2.5, polish=0.6); d.grain_brushed(body, 0.04, seed=18)
    gx0, gy0, gw, gh = 110, 9, 236, 102
    G = Z_FACE + 0.8
    glass_panel(p, gx0, gy0, gw, gh, on=G, r=2, frame="chrome")
    vx, vy, vw, vh = gx0 + 12, gy0 + 9, 108, 28
    CYAN, CYAN_GHOST = "#52f2d6", "#0a201d"
    vfd(p, vx, vy, vw, vh, G, CYAN, CYAN_GHOST, (vx + 6, vy + 7))
    lamp_text(p, "BAKE", vx + vw - 4, vy + 4, "on", CYAN, off="vfdoff", align="r")
    lamp_text(p, "TIMER", vx + vw - 4, vy + 11, "timerOn", CYAN, off="vfdoff", align="r")
    lamp_text(p, "F", vx + vw - 12, vy + 19, "unitF", CYAN, off="vfdoff", align="r")
    lamp_text(p, "C", vx + vw - 4, vy + 19, "unitC", CYAN, off="vfdoff", align="r")
    bx = (vx + vw + gx0 + gw) // 2
    p.label("LECTROMAX", bx, gy0 + 13, "paint_w", align="c", font="57", auto_ink=False)
    p.label("ELECTRONIC", bx, gy0 + 24, "glassline", align="c", auto_ink=False)
    # the pads
    px0, pw, ph, pg = gx0 + 12, 50, 16, 4
    ya, yb = gy0 + 52, gy0 + 72
    for i, (pid, lab) in enumerate((("bake", "BAKE"), ("broil", "BROIL"), ("timer", "TIMER"), ("clock", "CLOCK"))):
        glass_pad(p, px0 + i * (pw + pg), ya, pw, ph, lab)
        p.hit(pid, px0 + i * (pw + pg), ya, pw, ph, needs="powered", kind="look" if pid == "clock" else "press")
    glass_pad(p, px0, yb, pw, ph, icon="up"); p.hit("up", px0, yb, pw, ph, needs="powered")
    glass_pad(p, px0 + pw + pg, yb, pw, ph, icon="down"); p.hit("down", px0 + pw + pg, yb, pw, ph, needs="powered")
    glass_pad(p, px0 + 2 * (pw + pg), yb, 2 * pw + pg, ph, "CLEAR / OFF")
    p.hit("clearoff", px0 + 2 * (pw + pg), yb, 2 * pw + pg, ph, needs="powered")
    # the surface units' knobs on the steel either side
    for kx, which in ((30, "LR"), (80, "LF"), (376, "RF"), (426, "RR")):
        electric_knob(p, kx, 58, worn=worn)
        burner_icon(p, kx - 3, 82, which)
        p.hit("burner" + which, kx - 12, 46, 24, 24, kind="look")
    if worn:
        st = WR.mat_mask(d, "alu")
        WR.brushed_sheen(d, st, 60, 30, 0.08, 380, 456, 0.022)
        gl = WR.mat_mask(d, "blackglass")
        WR.gloss(d, gl, band=(0.55, 150, 30, 0.30))
        WR.gloss(d, gl, band=(0.55, 186, 3, 0.42))
        WR.smudge(d, gl & (d.YY > gy0 + 48), amount=-0.07, seed=19, sigma=1.6, thresh=0.78)
        WR.grime(d, d.solid, amount=0.26, seed=20)
        WR.scuffs(d, WR.face(d, Z_FACE, body), 0.0008, seed=21, amount=-0.08)
    return p


# =================================================================================== modern, 1992
def modern_range(worn=True):
    """a 1992 gas range: brushed steel, a wide black glass oven control with a green display, the oven's pads and
    a full number pad (type the temperature or the minutes, then START), silver gas knobs either side"""
    W, H = 456, 128
    p = Plate("oven_modern", W, H, seed=14, title="1992 gas range")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 4).get()
    d.slab(body, Z_FACE, "alu", bevel=2.5, polish=0.7); d.grain_brushed(body, 0.038, seed=22)
    gx0, gy0, gw, gh = 96, 8, 264, 112
    G = Z_FACE + 0.8
    glass_panel(p, gx0, gy0, gw, gh, on=G, r=3, frame=None)
    GREEN, GREEN_GHOST = "#6dff8e", "#081e0e"
    vx, vy, vw, vh = 228 - 62, gy0 + 7, 124, 28
    vfd(p, vx, vy, vw, vh, G, GREEN, GREEN_GHOST, (vx + 34, vy + 7))
    lamp_text(p, "BAKE", vx + 4, vy + 4, "on", GREEN, off="vfdoff")
    lamp_text(p, "TIMER", vx + 4, vy + 11, "timerOn", GREEN, off="vfdoff")
    lamp_text(p, "F", vx + vw - 4, vy + 7, "unitF", GREEN, off="vfdoff", align="r")
    lamp_text(p, "C", vx + vw - 4, vy + 15, "unitC", GREEN, off="vfdoff", align="r")
    p.label("PREMIUM TECHNOLOGIES", 228, vy + vh + 4, "glassline", align="c", auto_ink=False)
    # the pads: BAKE and BROIL, the number pad, TIMER and CLOCK; CANCEL and START under them
    fw, nw, ph, g = 40, 22, 14, 3
    x0 = 228 - (2 * fw + 5 * nw + 6 * g) // 2
    rows = ((("bake", "BAKE"), "12345", ("timer", "TIMER")), (("broil", "BROIL"), "67890", ("clock", "CLOCK")))
    y = gy0 + 52
    for left, nums, right in rows:
        glass_pad(p, x0, y, fw, ph, left[1]); p.hit(left[0], x0, y, fw, ph, needs="powered")
        for i, n in enumerate(nums):
            nx = x0 + fw + g + i * (nw + g)
            glass_pad(p, nx, y, nw, ph, n, font="57"); p.hit("d" + n, nx, y, nw, ph, needs="powered")
        rx = x0 + fw + g + 5 * (nw + g)
        glass_pad(p, rx, y, fw, ph, right[1])
        p.hit(right[0], rx, y, fw, ph, needs="powered", kind="look" if right[0] == "clock" else "press")
        y += ph + 4
    cw_ = 72
    glass_pad(p, x0, y, cw_, ph, "CANCEL"); p.hit("cancel", x0, y, cw_, ph, needs="powered")
    sx = x0 + 2 * fw + 5 * nw + 6 * g - cw_
    glass_pad(p, sx, y, cw_, ph, "START", ink="paint_g"); p.hit("start", sx, y, cw_, ph, needs="powered")
    # the burners' silver knobs
    for kx, which in ((28, "LR"), (70, "LF"), (386, "RF"), (428, "RR")):
        gas_knob(p, kx, 60, 11, worn=worn)
        burner_icon(p, kx - 3, 86, which)
        p.hit("burner" + which, kx - 13, 47, 26, 26, kind="look")
    if worn:
        st = WR.mat_mask(d, "alu")
        WR.brushed_sheen(d, st, 40, 26, 0.08, 400, 456, 0.02)
        gl = WR.mat_mask(d, "blackglass")
        WR.gloss(d, gl, band=(0.6, 300, 28, 0.30))
        WR.gloss(d, gl, band=(0.6, 333, 3, 0.42))
        WR.smudge(d, gl & (d.YY > gy0 + 48), amount=-0.07, seed=23, sigma=1.6, thresh=0.78)
        WR.grime(d, d.solid, amount=0.24, seed=24)
    return p


def six_burner_icon(p, x, y, which, mat="paint_k"):
    """a six-burner range's position diagram (3 across, 2 deep); `which` = 0..5, front row first"""
    d = p.d
    for k in range(6):
        ox, oy = (k % 3) * 4, (1 - k // 3) * 4
        m = rbox(d, x + ox, y + oy, 3, 3)
        if k != which: m &= ~rbox(d, x + ox + 1, y + oy + 1, 1, 1)
        d.paint(m, mat, flatlight=True)
    p.check_flat(x, y, 11, 7, f"burner diagram {which}")
    p.ink_rect(x, y, 11, 7, f"burner diagram {which}")


# =================================================================================== industrial, 1980
def industrial_range(units="F", on=False, worn=True):
    """a 1980 restaurant range: satin stainless under a round front rail, six big knurled burner knobs, the oven's
    thermostat on its own dial plate, the OVEN toggle and pilot, and a 60-minute-style timer bolted on in its box"""
    W, H = 456, 124
    p = Plate("oven_industrial", W, H, seed=15, title="1980 restaurant range")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 3).get()
    d.slab(body, Z_FACE, "alu", bevel=2.0, polish=0.55); d.grain_brushed(body, 0.05, seed=26)
    rail = d.cyl(3, 3, W - 6, 10, 3.4, "alu", axis="h", polish=0.9, on=Z_FACE)
    # the six burners (look only): knurled black knobs, OFF at the top
    for i in range(6):
        kx = 32 + i * 44
        kn = knurled_knob(p, kx, 56, 12)
        baked_pointer(p, kn, -90, 2, 10, mat="paint_w")
        scale_ring(p, kx, 56, 15.5, [-90, 180], ["OFF", ""], minor_angles=[150, 120, 90], wear=0.15 if worn else 0)
        six_burner_icon(p, kx - 5, 79, [3, 4, 5, 0, 1, 2][i])
        p.hit(f"burner{i}", kx - 13, 43, 26, 26, kind="look")
    # the maker's plate
    plate = Mask(W, H).rrect(104, 96, 76, 15, 1).get()
    d.slab(plate, 0.8, "enamel_black", bevel=0.8, polish=0.6, on=Z_FACE)
    for rx in (107, 177):
        d.dome(rx, 103.5, 1.4, 1.4, 1.0, "alu", polish=1.0, on=Z_FACE + 0.8)
    nameplate(d, "IRONCLAD", 142, 100, on=Z_FACE + 0.8, mat="chrome", font="57", align="c", z=1.0)
    # the oven: thermostat on a round dial plate
    tx, ty = 310, 58
    d.slab(disc(d, tx, ty, 35), 0.6, "alu", bevel=1.0, polish=0.8, on=Z_FACE)
    d.torus(tx, ty, 34.5, 36.5, 1.2, "chrome", polish=1.0, on=Z_FACE)
    kn = knurled_knob(p, tx, ty, 13, on=Z_FACE + 0.6)
    thermostat_scale(p, tx, ty, 16.5, units, wear=0.10 if worn else 0)
    p.label("OVEN", tx, 100, "paint_k", align="c")
    p.part("ptr", src="ovenStop", cx=tx, cy=ty, r0=2, r1=11, angles=OVEN_STOP_ANGLES, color="#e8e4da", w=1)
    p.hit("heat", tx - 16, ty - 16, 32, 32, needs="powered", kind="turn")
    # the OVEN toggle and the pilot
    gx = 366
    p.label("ON", gx, 30, "paint_k", align="c")
    bat_toggle(p, gx, 52, on, on=Z_FACE)
    p.label("OFF", gx, 68, "paint_k", align="c")
    p.hit("onoff", gx - 7, 38, 14, 28, needs="powered")
    jewel(p, gx, 88, 4.0, off="jewel_off", on=Z_FACE)
    p.lamp(disc(d, gx, 88, 4.0), "on", "#ffa630")
    p.label("PILOT", gx, 96, "paint_k", align="c")
    # the timer, bolted on in its own black box
    bx0, by0, bw, bh = 386, 20, 62, 84
    box = Mask(W, H).rrect(bx0, by0, bw, bh, 3).get()
    d.slab(box, 3.0, "enamel_black", bevel=1.6, polish=0.6, on=Z_FACE)
    BZ = Z_FACE + 3.0
    for sx, sy in ((bx0 + 5, by0 + 5), (bx0 + bw - 6, by0 + bh - 6)):
        screw(p, sx, sy, on=BZ, mat="alu")
    fx, fy = bx0 + bw // 2, by0 + 34
    fm = disc(d, fx, fy, 26)
    d.h[fm] = BZ - 0.8; d.mat[fm] = d.mid("cream"); d.solid |= fm; d.polish[fm] = 0.3; d.tex[fm] = 0
    d.torus(fx, fy, 25.6, 27.4, 1.4, "chrome", polish=1.0, on=BZ)
    fluted_knob(p, fx, fy, 7, on=BZ - 0.8, z=3.4, mat="blackp", skirt=None, ridges=12, dome=0.5)
    minutes_scale(p, fx, fy, 9.5, wear=0.08 if worn else 0)
    p.label("MINUTES", fx, by0 + bh - 14, "paint_w", align="c", auto_ink=False)
    p.part("ptr", src="timerF", cx=fx, cy=fy, r0=1.5, r1=6, a0=-90, a1=210, color="#e8e4da", w=1)
    p.hit("timer", fx - 12, fy - 12, 24, 24, needs="powered", kind="turn")
    if worn:
        st = WR.mat_mask(d, "alu")
        WR.brushed_sheen(d, st, 130, 34, 0.07, 330, 456, 0.02)
        WR.grime(d, d.solid, amount=0.34, seed=27)
        WR.scuffs(d, WR.face(d, Z_FACE, body), 0.0015, seed=28, amount=-0.08)
        WR.specks(d, WR.face(d, Z_FACE, body), 0.002, seed=29, amount=0.3)
        WR.aged_face(d, fx, fy, 26, amount=0.10)
    return p


# =================================================================================== large modern: a commercial convection oven
def convection_oven(units="F", on=False, worn=True):
    """a commercial convection oven's control panel: black paint inset in stainless, POWER toggle, thermostat,
    cook timer, HEATING and FAN lamps (the fan runs whenever the oven does), and the motor's vent"""
    W, H = 456, 124
    p = Plate("oven_large", W, H, seed=16, title="commercial convection oven")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 3).get()
    d.slab(body, Z_FACE, "alu", bevel=2.0, polish=0.6); d.grain_brushed(body, 0.045, seed=30)
    px0, py0, pw, ph = 10, 10, W - 20, H - 20
    PZ = Z_FACE - 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "panel_black", polish=0.4); d.grain_pebble(panel, 0.025, seed=31)
    p.label("CONVECTRON", 22, 17, "paint_w", font="57", auto_ink=False)
    p.label("CONVECTION OVEN", 22, 27, "glassline", auto_ink=False)
    # POWER
    tgx = 50
    p.label("POWER", tgx, 44, "paint_w", align="c", auto_ink=False)
    bat_toggle(p, tgx, 70, on, on=PZ)
    p.label("ON", tgx + 12, 58, "paint_w", auto_ink=False); p.label("OFF", tgx + 12, 78, "paint_w", auto_ink=False)
    p.hit("onoff", tgx - 7, 56, 14, 28, needs="powered")
    # thermostat and timer: black knobs on bright skirts, white print
    for kx, kind in ((150, "heat"), (252, "timer")):
        fluted_knob(p, kx, 66, 13, on=PZ, z=4.0, mat="blackp", skirt=2.0, skirt_mat="chrome", ridges=22, dome=0.6 if worn else 0)
        if kind == "heat":
            thermostat_scale(p, kx, 66, 17.5, units, mat="paint_w", wear=0.08 if worn else 0)
            p.label("TEMPERATURE", kx, 102, "paint_w", align="c", auto_ink=False)
            p.part("ptr", src="ovenStop", cx=kx, cy=66, r0=2, r1=11, angles=OVEN_STOP_ANGLES, color="#f2efe6", w=1)
            p.hit("heat", kx - 16, 50, 32, 32, needs="powered", kind="turn")
        else:
            minutes_scale(p, kx, 66, 17.5, mat="paint_w", wear=0.08 if worn else 0)
            p.label("COOK TIMER", kx, 102, "paint_w", align="c", auto_ink=False)
            p.part("ptr", src="timerF", cx=kx, cy=66, r0=2, r1=11, a0=-90, a1=210, color="#f2efe6", w=1)
            p.hit("timer", kx - 16, 50, 32, 32, needs="powered", kind="turn")
    # the lamps
    lx = 322
    jewel(p, lx, 52, 4.0, off="jewel_off", on=PZ)
    p.lamp(disc(d, lx, 52, 4.0), "on", "#ffa630")
    p.label("HEATING", lx, 60, "paint_w", align="c", auto_ink=False)
    jewel(p, lx, 82, 4.0, off="jewel_grn_off", on=PZ)
    p.lamp(disc(d, lx, 82, 4.0), "on", "#5cff7a")
    p.label("FAN", lx, 90, "paint_w", align="c", auto_ink=False)
    # the motor's vent
    louvers(p, 360, 24, 76, 74, 9, on=PZ, depth=2.2)
    if worn:
        st = WR.mat_mask(d, "alu")
        WR.brushed_sheen(d, st, 90, 40, 0.07, 360, 456, 0.02)
        WR.grime(d, d.solid, amount=0.30, seed=32)
        WR.scuffs(d, WR.mat_mask(d, "panel_black"), 0.0012, seed=33, amount=0.10)
    return p


# =================================================================================== Fryers Club "Industrial 2000" deep fryer
def fryer(units="F", on=False, worn=True):
    """the game's Fryers Club Industrial 2000: its red maker's badge, a black control box with a lit POWER rocker,
    the thermostat, the HEATING lamp and the basket timer; louvres under it"""
    W, H = 456, 120
    p = Plate("fryer", W, H, seed=17, title="Fryers Club deep fryer")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 3).get()
    d.slab(body, Z_FACE, "alu", bevel=2.0, polish=0.6); d.grain_brushed(body, 0.045, seed=34)
    # the badge
    bx0, by0, bw, bh = 14, 30, 104, 38
    badge = Mask(W, H).rrect(bx0, by0, bw, bh, 4).get()
    d.slab(badge, 1.4, "enamel_red", bevel=1.2, polish=0.8, on=Z_FACE)
    d.torus  # (the rim is a chrome lip)
    chrome_frame(d, bx0 - 1, by0 - 1, bw + 2, bh + 2, Z_FACE, t=1, mat="chrome", z=1.8)
    p.label("FRYERS CLUB", bx0 + bw // 2, by0 + 9, "paint_w", align="c", font="57", auto_ink=False)
    p.label("INDUSTRIAL 2000", bx0 + bw // 2, by0 + 22, "paint_c", align="c", auto_ink=False)
    # the control box
    cx0, cy0, cw, ch = 134, 12, 308, 86
    box = Mask(W, H).rrect(cx0, cy0, cw, ch, 2).get()
    d.slab(box, 2.0, "panel_black", bevel=1.2, polish=0.4, on=Z_FACE)
    CZ = Z_FACE + 2.0
    for sx, sy in ((cx0 + 4, cy0 + 4), (cx0 + cw - 5, cy0 + 4), (cx0 + 4, cy0 + ch - 5), (cx0 + cw - 5, cy0 + ch - 5)):
        screw(p, sx, sy, on=CZ, mat="alu")
    # POWER: a rocker whose ON half is a red window, lit while the fryer is on
    rx = 166
    p.label("POWER", rx, 20, "paint_w", align="c", auto_ink=False)
    rocker_switch(p, rx - 8, 32, 16, 28, on, on=CZ)
    win = rbox(d, rx - 6, 34, 12, 11) if True else None
    d.mat[win & d.solid] = d.mid("jewel_red_off"); d.flatlight[win] = True
    p.lamp(win, "on", "#ff4a2a", halo=False)
    p.label("ON", rx + 14, 35, "paint_w", auto_ink=False); p.label("OFF", rx + 14, 52, "paint_w", auto_ink=False)
    p.hit("onoff", rx - 10, 30, 20, 32, needs="powered")
    # the thermostat
    kx = 244
    fluted_knob(p, kx, 50, 13, on=CZ, z=4.0, mat="blackp", skirt=2.0, skirt_mat="chrome", ridges=22, dome=0.6 if worn else 0)
    thermostat_scale(p, kx, 50, 17.5, units, mat="paint_w", wear=0.10 if worn else 0)
    p.label("TEMPERATURE", kx, 86, "paint_w", align="c", auto_ink=False)
    p.part("ptr", src="ovenStop", cx=kx, cy=50, r0=2, r1=11, angles=OVEN_STOP_ANGLES, color="#f2efe6", w=1)
    p.hit("heat", kx - 16, 34, 32, 32, needs="powered", kind="turn")
    # HEATING
    jewel(p, 314, 44, 4.0, off="jewel_off", on=CZ)
    p.lamp(disc(d, 314, 44, 4.0), "on", "#ffa630")
    p.label("HEATING", 314, 52, "paint_w", align="c", auto_ink=False)
    # the basket timer
    tx = 390
    fluted_knob(p, tx, 50, 13, on=CZ, z=4.0, mat="blackp", skirt=2.0, skirt_mat="chrome", ridges=22, dome=0.6 if worn else 0)
    minutes_scale(p, tx, 50, 17.5, mat="paint_w", wear=0.08 if worn else 0)
    p.label("BASKET TIMER", tx, 86, "paint_w", align="c", auto_ink=False)
    p.part("ptr", src="timerF", cx=tx, cy=50, r0=2, r1=11, a0=-90, a1=210, color="#f2efe6", w=1)
    p.hit("timer", tx - 16, 34, 32, 32, needs="powered", kind="turn")
    louvers(p, 14, 104, W - 28, 9, 40, on=Z_FACE, depth=2.0)
    if worn:
        st = WR.mat_mask(d, "alu")
        WR.brushed_sheen(d, st, 60, 30, 0.07, 400, 456, 0.02)
        WR.grime(d, d.solid, amount=0.36, seed=35)
        WR.specks(d, WR.face(d, Z_FACE, body), 0.003, seed=36, amount=0.3)
        WR.gloss(d, WR.mat_mask(d, "enamel_red"), band=(0.5, 40, 6, 0.12))
    return p
