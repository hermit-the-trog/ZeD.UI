"""Prototypes for the director: the 1956 green range, the 1990 white touchpad microwave, the 1988 red generator."""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from physlib import *            # noqa: F401,F403
import preview as PV
import wear as WR

OUT = os.path.join(HERE, "out")
os.makedirs(OUT, exist_ok=True)

C2F = lambda c: c * 9 / 5 + 32
OVEN_TEMPS = (0, 50, 100, 150, 200, 250, 300)          # the game's oven stops, degrees C


# =================================================================================== the 1956 green range
# The thermostat's scale is one dial printed in either unit: the angle is the true temperature, so a stop lands
# where it really is on the Fahrenheit print and exactly on the figure on the Celsius print.
def oven_angle_f(f): return -50 + (f - 150) * 0.6       # 150 F at -50 degrees ... 550 F at 190
def oven_angle_c(c): return oven_angle_f(C2F(c))
OVEN_OFF_A = -90
OVEN_STOP_ANGLES = [OVEN_OFF_A] + [round(oven_angle_c(c), 1) for c in OVEN_TEMPS[1:]]


def green_range(units="F", on=False, worn=True):
    W, H = 456, 128
    p = Plate("oven_green", W, H, seed=11, title="1956 range")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 6).get()
    d.slab(body, Z_FACE, "enamel_mint", bevel=3.0, polish=0.75)
    spears = d.cyl(10, 5, W - 20, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    spears |= d.cyl(10, H - 8, W - 20, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)

    # ---- the control centre: brushed aluminium in a chrome frame, a step proud of the enamel
    cx0, cy0, cw, ch = 118, 14, 220, 100
    F = Z_FACE + 1.2
    cc = rbox(d, cx0, cy0, cw, ch)
    d.flat(cc, F, "alu", polish=0.5); d.grain_brushed(cc, 0.05 if worn else 0.03, seed=4)
    chrome_frame(d, cx0 - 2, cy0 - 2, cw + 4, ch + 4, Z_FACE, t=2, mat="chrome", z=2.0)

    # the clock (the game's time)
    ck = clock_face(p, 154, 64, 28, face="cream", on=F, depth=1.6)
    p.part("clock", cx=154, cy=64, rh=13, rm=21, color="#1c1b17")

    # the Minute Minder: 0 to 120 minutes on a linear scale, the pointer unwinds as the timer runs
    mx, my = 222, 50
    TA0, TA1 = -90, 210
    ta = lambda m: TA0 + (TA1 - TA0) * m / 120
    fluted_knob(p, mx, my, 9, on=F, dome=0.9 if worn else 0.0)
    scale_ring(p, mx, my, 13.5, [ta(m) for m in (0, 30, 60, 90, 120)], ["0", "30", "60", "90", "120"],
               minor_angles=[ta(m) for m in range(10, 120, 10) if m % 30], wear=0.10 if worn else 0)
    p.label("MINUTE MINDER", mx, 77, "paint_k", align="c")
    p.part("ptr", src="timerF", cx=mx, cy=my, r0=1, r1=7, a0=TA0, a1=TA1, color="#7a1a12", w=1)
    p.hit("timer", mx - 13, my - 13, 26, 26, needs="powered", kind="turn")

    # the oven thermostat: OFF, then the true temperature; Fahrenheit or Celsius print (the player's setting)
    ox, oy = 290, 50
    fluted_knob(p, ox, oy, 9, on=F, dome=0.9 if worn else 0.0)
    if units == "F":
        scale_ring(p, ox, oy, 13.5, [OVEN_OFF_A] + [oven_angle_f(f) for f in (200, 300, 400, 500)], ["OFF", "200", "300", "400", "500"],
                   minor_angles=[oven_angle_f(f) for f in (150, 250, 350, 450, 550)], wear=0.12 if worn else 0)
    else:
        scale_ring(p, ox, oy, 13.5, [OVEN_OFF_A] + [oven_angle_c(c) for c in (100, 150, 200, 250, 300)], ["OFF", "100", "150", "200", "250", "300"],
                   minor_angles=[oven_angle_c(c) for c in (50, 75, 125, 175, 225, 275)], wear=0.12 if worn else 0)
    p.label("OVEN", ox, 77, "paint_k", align="c")
    p.part("ptr", src="ovenStop", cx=ox, cy=oy, r0=1, r1=7, angles=OVEN_STOP_ANGLES, color="#7a1a12", w=1)
    p.hit("heat", ox - 13, oy - 13, 26, 26, needs="powered", kind="turn")

    # the oven's ON and OFF keys (interlocked: one is always down) and its pilot jewel
    keys = piano_keys(p, 228, 92, ["ON", "OFF"], 20, 11, 0 if on else 1, mat="cream", on=F)
    p.hit("on", *keys[0], needs="powered"); p.hit("off", *keys[1], needs="powered")
    jx, jy = 282, 97
    jewel(p, jx, jy, 4.0, on=F)
    p.lamp(disc(d, jx, jy, 4.0), "on", "#ffa630")

    # the surface burners: part of the look (the game heats the whole stove as one)
    for bx, which in ((34, "LR"), (86, "LF"), (370, "RF"), (422, "RR")):
        kn = fluted_knob(p, bx, 64, 10, on=Z_FACE, dome=0.9 if worn else 0.0)
        baked_pointer(p, kn, -90, 1, 8)
        # a gas valve turns anticlockwise from OFF: full flame (HI) a quarter turn on, down to LO near the end
        scale_ring(p, bx, 64, 13.5, [-90, 180, 45], ["OFF", "HI", "LO"], minor_angles=[150, 120, 90, 67], wear=0.22 if worn else 0)
        burner_icon(p, bx - 3, 83, which)
        p.hit("burner" + which, bx - 12, 52, 24, 24, kind="look")

    # the maker and the model, raised chrome letters
    nameplate(d, "HOLLISTER", 60, 17, on=Z_FACE, mat="chrome", font="57", align="c", z=1.4)
    nameplate(d, "CUSTOM", 396, 17, on=Z_FACE, mat="chrome", font="57", align="c", z=1.4)

    # ---- material and wear: glossy enamel, brushed aluminium, forty years of a kitchen
    if worn:
        en = WR.mat_mask(d, "enamel_mint")
        WR.gloss(d, en, top=0.0, foot=0.0, band=(0.31, 60, 12, 0.13))
        WR.gloss(d, en, top=0.0, foot=0.0, band=(0.31, 73, 2, 0.13))
        alu = WR.mat_mask(d, "alu")
        WR.brushed_sheen(d, alu, 200, 20, 0.105, 280, 338, 0.045)
        WR.grime(d, d.solid, amount=0.30, seed=5)
        WR.chips(d, en, 9, seed=7, near=2.5)
        WR.pits(d, spears, 7, seed=9)
        WR.aged_face(d, 154, 64, 28, amount=0.12)
    return p


def green_state(tempC, minutes, on, hour, minute, celsius=False):
    stop = OVEN_TEMPS.index(min(OVEN_TEMPS, key=lambda t: abs(t - tempC)))
    return dict(ovenStop=stop, timerF=min(1.0, minutes / 120.0), on=on, hour=hour, minute=minute, celsius=celsius)


# =================================================================================== the 1990 white touchpad microwave
MW_POWERS = (50, 70, 90, 110, 130)                       # the game's five powers, LO .. HI


def mw_white(cooking=False, worn=True):
    """the right of the door (its window, cropped) and the touch panel: a red seven-segment readout, the power
    level in five lamps, the pads"""
    W, H = 456, 168
    p = Plate("mw_white", W, H, seed=21, title="1990 touchpad microwave")
    d = p.d
    # the case: white enamel, the left side runs on past the plate (the door is cropped there)
    case = Mask(W, H).rrect(-12, 0, W + 12, H, 7).get()
    d.slab(case, Z_FACE, "enamel_white", bevel=2.5, polish=0.6)
    # the door: a white moulding a step proud of the case, its window over the perforated screen
    DZ = Z_FACE + 1.0
    door = Mask(W, H).rrect(-12, 7, 300, H - 14, 4).get()
    d.slab(door, 1.0, "enamel_white", bevel=1.5, polish=0.6, on=Z_FACE)
    mesh_window(p, 0, 19, 262, H - 38, r=4, on=DZ, depth=2.2, lit=cooking, crop_left=True)
    # the grip: a shallow recess down the door's right edge
    grip = Mask(W, H).rrect(271, 40, 7, H - 80, 3).get()
    d.well(grip, 1.4, "enamel_white", bevel=1.5)
    d.seam(rbox(d, 288, 7, 1, H - 14), 0.6)
    # the touch panel: a light grey membrane set into the case
    px0, py0, pw, ph = 296, 9, 150, H - 18
    PZ = Z_FACE - 0.4
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "pad_panel", polish=0.3)
    d.seam(panel & ~ndi.binary_erosion(panel, iterations=1), 0.35)
    cx = px0 + pw // 2
    p.label("VALUTECH", cx, 14, "paint_k", align="c", font="57")
    # the readout: smoked red glass, four figures and the colon; COOK lights while it runs
    lx, ly, lw, lh = px0 + 9, 26, pw - 18, 28
    win = window_glass(p, lx, ly, lw, lh, face="ledglass", bezel="blackp", depth=1.4, on=PZ, r=1, bezel_t=2, lens=True)
    DX, DY, CW, CH, PITCH, ST = lx + 18, ly + 6, 10, 16, 14, 2
    p.part("digits", src="mwText", x=DX, y=DY, cw=CW, ch=CH, pitch=PITCH, st=ST, n=5, color="#ff3b2a", ghost="#2c0a09",
           align="r")                                    # dark without power, like the real thing
    cook = d.text("COOK", lx + lw - 5, ly + 7, "ledoff", align="r", flatlight=True)
    p.lamp(cook, "cooking", "#ff3b2a", halo=False)
    # the power level: five lamps under the readout
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
    # the pads
    gx0, gw, gap = px0 + 8, 42, 4
    y = by + 12
    # the pads a cook presses most (START, the 1, 3 and 0, POWER LEVEL) have their print a little rubbed
    used = {"start": 0.20, "d1": 0.12, "d3": 0.12, "d0": 0.14, "power": 0.08}
    def pad(id_, x, yy, w, h, a, b=None, ink="paint_k", font="35"):
        membrane_pad(p, x, yy, w, h, a, label2=b, lab_mat=ink, on=PZ, font=font, wear=used.get(id_, 0.0) if worn else 0.0)
        p.hit(id_, x, yy, w, h, needs="powered")
    pad("power", gx0, y, 65, 15, "POWER", "LEVEL", ink="paint_b")
    pad("timecook", gx0 + 69, y, 65, 15, "TIME", "COOK", ink="paint_b")
    y += 15 + 3
    for r, row in enumerate(((1, 2, 3), (4, 5, 6), (7, 8, 9))):
        for c, n in enumerate(row):
            pad(f"d{n}", gx0 + c * (gw + gap), y, gw, 13, str(n), font="57")
        y += 13 + 3
    pad("stop", gx0, y, gw, 15, "STOP", "CLEAR", ink="paint_r")
    pad("d0", gx0 + gw + gap, y, gw, 15, "0", font="57")
    pad("start", gx0 + 2 * (gw + gap), y, gw, 15, "START", ink="paint_g")
    if y + 15 > py0 + ph - 3: p.warn(f"pads run to {y + 15}, past the panel ({py0 + ph})")

    # ---- material and wear: glossy white plastic, a few years of fingers on the pads
    if worn:
        white = WR.mat_mask(d, "enamel_white")
        WR.gloss(d, white, band=(0.45, 330, 10, 0.08))
        WR.grime(d, d.solid, amount=0.24, seed=23)
        WR.scuffs(d, white & (d.YY > H - 20) & (d.XX < 288), 6, seed=24, amount=-0.09)
    return p


def mw_state(text, power_i, cooking, powered=True):
    return dict(mwText=text, mwPower=power_i + 1, cooking=cooking and powered, power=powered)


# =================================================================================== the 1988 red generator
def gen_red(running=False, connected=False, worn=True):
    """the front of an enclosed portable set in its tube frame: the maker's decal, a warning label, the black control
    panel (ENGINE rocker, choke, output and oil lamps, two outlets, ground, breakers, the 12 V posts), the fuel gauge"""
    W, H = 456, 150
    p = Plate("gen_red", W, H, seed=31, title="1988 portable generator")
    d = p.d
    housing = Mask(W, H).rrect(4, 4, W - 8, H - 8, 6).get()
    d.slab(housing, Z_FACE, "gen_red", bevel=2.0, polish=0.45)
    # the maker's decal and the warning label on the housing
    p.label("MASS GENFAC", 16, 13, "paint_w", font="57", auto_ink=False)
    p.label("4000 WATT GENERATOR", 16, 23, "paint_w", auto_ink=False)
    sticker(p, 352, 11, 86, 19, "WARNING", lines=3)
    # the black control panel, set a step into the housing
    px0, py0, pw, ph = 12, 34, W - 24, 88
    PZ = Z_FACE - 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "panel_black", polish=0.35); d.grain_pebble(panel, 0.03, seed=8)
    # ENGINE: a big rocker (ON at the top), the choke below it
    ax = 40
    p.label("ENGINE", ax, 40, "paint_w", align="c")
    rocker_switch(p, ax - 8, 50, 16, 28, running, on=PZ)
    p.label("ON", ax + 14, 53, "paint_w", wear=0.15 if worn else 0); p.label("OFF", ax + 14, 70, "paint_w", wear=0.12 if worn else 0)
    p.hit("engine", ax - 10, 48, 20, 32)
    fluted_knob(p, ax, 99, 5, on=PZ, z=3.0, mat="blackp", skirt=None, ridges=10)
    p.label("CHOKE", ax, 108, "paint_w", align="c")
    p.hit("choke", ax - 7, 92, 14, 14, kind="look")
    # the lamps: OUTPUT (neon red: the engine is making power), OIL ALERT (amber: the set needs service)
    bx = 108
    jewel(p, bx, 56, 3.5, off="jewel_red_off", bezel="chrome", on=PZ)
    p.lamp(disc(d, bx, 56, 3.5), "running", "#ff4a2a")
    p.label("OUTPUT", bx, 63, "paint_w", align="c")
    jewel(p, bx, 84, 3.5, off="jewel_off", bezel="chrome", on=PZ)
    p.lamp(disc(d, bx, 84, 3.5), "service", "#ffb02e")
    p.label("OIL ALERT", bx, 91, "paint_w", align="c")
    # the outlets: two 120 V duplexes; a heavy cord plugs into the left one's lower socket when connected
    o1, o2 = 166, 198
    p.label("120V AC 20A", (o1 + o2) // 2, 40, "paint_w", align="c")
    faces = outlet_duplex(p, o1, 66, on=PZ, plate_mat="steel")
    outlet_duplex(p, o2, 66, on=PZ, plate_mat="steel")
    if connected:
        plug(p, faces[1], on=PZ, cord_to=H)
    p.hit("outlet", o1 - 11, 51, 22, 30)
    wing_nut(p, o2, 98, on=PZ)
    p.label("GROUND", o2, 106, "paint_w", align="c")
    # the breakers and the battery-charging posts
    cx_ = 274
    p.label("CIRCUIT BREAKERS", cx_, 40, "paint_w", align="c")
    for k in (-16, 16):
        breaker(p, cx_ + k, 58, on=PZ)
        p.label("20A", cx_ + k, 66, "paint_w", align="c")
        p.hit(f"breaker{k}", cx_ + k - 6, 52, 12, 12, kind="look")
    p.label("DC 12V 8A", cx_, 80, "paint_w", align="c")
    binding_post(p, cx_ - 16, 97, "paint_r", on=PZ); binding_post(p, cx_ + 16, 97, "blackp", on=PZ)
    p.label("+", cx_ - 16, 105, "paint_w", align="c"); p.label("-", cx_ + 16, 105, "paint_w", align="c")
    # the fuel gauge (the tank's sender, brought to the panel)
    gx, gy, gr = 386, 78, 24
    an = fuel_gauge(p, gx, gy, gr, on=PZ)
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **an)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    # the louvres along the bottom and the tube frame round it all
    louvers(p, 20, 127, W - 40, 10, 46, on=Z_FACE, depth=2.0)
    frame = tube_frame(p, 0, 0, W, H, 12, 6, mat="steel", on=Z_FACE, z=3.0)

    # ---- material and wear: a work machine's paint, scuffed, chipped at the edges, dirty where things meet
    if worn:
        red = WR.mat_mask(d, "gen_red")
        WR.gloss(d, red, band=(0.40, 120, 8, 0.09))
        WR.scuffs(d, red, 9, seed=33, amount=0.12)
        WR.chips(d, red, 10, seed=34, near=2.0)
        WR.chips(d, WR.mat_mask(d, "decal_y"), 5, seed=35, near=1.5, mat="gen_red", dh=0.0)
        WR.specks(d, frame, 14, seed=36, amount=0.35)
        WR.scuffs(d, frame, 6, seed=37, length=(2, 5), amount=0.12)
        WR.grime(d, d.solid, amount=0.32, seed=38)
    return p


def gen_state(running, connected, fuel, service=False):
    return dict(running=running, connected=connected, fuel=fuel, service=service)


# =================================================================================== the build and the sheet
def build_mw():
    return build(mw_white, [("mw_lit", "cooking", True, {"cooking": True})])


def build_gen():
    return build(gen_red, [("gen_on", "running", True, {"running": True}), ("gen_plug", "connected", True, {"connected": True})])


def build_green():
    return build(green_range, [("keys_on", "on", True, {"on": True}), ("dial_c", "celsius", True, {"units": "C"})])


def strip(rows, k=3, pad=10, bg=(24, 24, 26, 255)):
    W = max(r.width for r in rows) * k + 2 * pad
    H = sum(r.height * k + pad for r in rows) + pad
    s = Image.new("RGBA", (W, H), bg); y = pad
    for r in rows:
        s.alpha_composite(PV.scale(r, k), (pad, y)); y += r.height * k + pad
    return s


if __name__ == "__main__":
    which = sys.argv[1:] or ["green"]
    if "green" in which:
        p, base, sprites = build_green()
        for w in p.warnings: print("  !", w)
        rows = [PV.render_state(base, p.parts, sprites, green_state(0, 0, False, 7, 40)),
                PV.render_state(base, p.parts, sprites, green_state(200, 35, True, 6, 10)),
                PV.render_state(base, p.parts, sprites, green_state(200, 35, True, 6, 10, celsius=True))]
        strip(rows).save(os.path.join(OUT, "proto_green_3x.png"))
        base.save(os.path.join(OUT, "oven_green.png"))
        print("green ok", len(p.parts), "parts", len(p.hits), "hits", {k: v.size for k, v in sprites.items()})
    if "mw" in which:
        p, base, sprites = build_mw()
        for w in p.warnings: print("  !", w)
        rows = [PV.render_state(base, p.parts, sprites, mw_state("10:08", 4, False)),
                PV.render_state(base, p.parts, sprites, mw_state("1:30", 2, False)),
                PV.render_state(base, p.parts, sprites, mw_state("0:47", 2, True))]
        strip(rows).save(os.path.join(OUT, "proto_mw_3x.png"))
        base.save(os.path.join(OUT, "mw_white.png"))
        print("mw ok", len(p.parts), "parts", len(p.hits), "hits", {k: v.size for k, v in sprites.items()})
    if "gen" in which:
        p, base, sprites = build_gen()
        for w in p.warnings: print("  !", w)
        rows = [PV.render_state(base, p.parts, sprites, gen_state(False, False, 0.35)),
                PV.render_state(base, p.parts, sprites, gen_state(True, True, 0.8)),
                PV.render_state(base, p.parts, sprites, gen_state(True, True, 0.12, service=True))]
        strip(rows).save(os.path.join(OUT, "proto_gen_3x.png"))
        base.save(os.path.join(OUT, "gen_red.png"))
        print("gen ok", len(p.parts), "parts", len(p.hits), "hits", {k: v.size for k, v in sprites.items()})
