"""The Timez watches (director, Oct 16 2026): the second brand beside CaZio, after the Timex of the time. Two digitals
(the red, and the steel that the Dress item turns up as half the time) and two analogues (the brown: an Easy Reader;
the military: a Camper). Timez's perk is the night light: every watch's screen and dial go faint after dark, and a Timez
lights its own blue-green for a few seconds when you press for it. Timez digitals give up the thermometer for it.

Digital (the Triathlon of '86): an octagon like CaZio's, its corners cut deeper and dulled softer, a pusher out of each
cut corner (SET and ALARM above, SPEED and START below, where the classics have them), and the big INDIGLOW key
under the screen.
Analogue: a plain round case, the main crown at three (push it for the light, as on a real one), a small crown at two
(the alarm: it opens the alarm's setting, like the CaZio crown), START at four and SPEED at eight; the speed marks and
PAUSE printed small on the dial (as on the expensive one).

States: "dark" (night and not lit: the screen or dial darkened, the figures faint) and "lit" (the glow). Each is a
picture over the plate plus the live parts' own night or lit colours.
"""
import math

import numpy as np

from physlib import *            # noqa: F401,F403
from engine import add_ramp
import d_watches as DW
from d_watches import soft_poly, octagon, strap, cover, nt, lcd_night

add_ramp("lcdglow", "#5ad8c8", light=1.25)        # the INDIGLOW glass: blue-green, lit from behind
add_ramp("dialglow", "#52d0c2", light=1.25)
add_ramp("resin_red_dk", "#5a1a1a")

GLOW_INK = "#0f2a28"                               # figures and hands against the glow: dark teal, crisp


def cushion(W, H, cx, cy, a, b, n=2.6):
    """a cushion: a superellipse, rounder than a rectangle and squarer than a circle (the eighties' Triathlon case)"""
    yy, xx = np.mgrid[0:H, 0:W]
    return (np.abs((xx + 0.5 - cx) / a) ** n + np.abs((yy + 0.5 - cy) / b) ** n) <= 1.0


def edge_r(a, b, n, th):
    """the cushion's radius in direction th (radians, y down)"""
    c, s = abs(math.cos(th)), abs(math.sin(th))
    return 1.0 / ((c / a) ** n + (s / b) ** n) ** (1.0 / n)


# ------------------------------------------------------------------ the digitals
TDIGITAL = {
    #               case         face        accent      light key   strap (mat, kind)        brand      print      pusher
    "timez_red":   ("red_resin", "face_ink", "paint_y", "paint_y", ("red_resin", "resin"), "paint_w", "paint_c", "steel"),
    "timez_steel": ("steel",     "face_ink", "key_teal", "key_teal", ("steel", "links"),    "paint_w", "paint_c", "steel"),
}
TLCD = (20, 56, 84, 38)
CX, CY, A, B, N = 62, 88, 54, 62, 2.6


def timez_digital(name="timez_red", worn=True, night=False, lit=False):
    case_m, face_m, accent, light_m, (strap_m, strap_k), brand_ink, ink, push_m = TDIGITAL[name]
    W, H = 124, 176
    p = Plate(name, W, H, seed=sum(map(ord, name)) % 997, title=name.replace("_", " "))
    d = p.d
    strap(p, 34, 56, 0, 34, strap_m, kind=strap_k)
    strap(p, 34, 56, 144, H, strap_m, kind=strap_k)
    # the case: an octagon like CaZio's (the two brands' faces were cousins then), but its corners cut deeper and
    # dulled softer; a pusher stands out of the middle of each cut corner, square to it
    CASE = (8, 26, 116, 150, 22)
    x0, y0, x1, y1, c = CASE
    for pid, (mx, my, sx, sy) in (("set", (x0 + c / 2, y0 + c / 2, -1, -1)), ("alarm", (x1 - c / 2, y0 + c / 2, 1, -1)),
                                  ("speed", (x0 + c / 2, y1 - c / 2, -1, 1)), ("start", (x1 - c / 2, y1 - c / 2, 1, 1))):
        k = 0.7071
        d.slab(line_mask(d, mx - sx * k * 4, my - sy * k * 4, mx + sx * k * 3.5, my + sy * k * 3.5, 6.0), Z_FACE - 0.2, push_m,
               bevel=1.0, polish=0.9)
        hx, hy = int(round(mx + sx * 1 - 8)), int(round(my + sy * 1 - 8))
        p.hit(pid, max(0, min(W - 16, hx)), max(0, min(H - 16, hy)), 16, 16)
    case = soft_poly(W, H, octagon(*CASE), 5.0)
    cover(d, d.slab(case, Z_FACE + 1.0, case_m, bevel=3.2, polish=0.6))
    d.grain_pebble(case, 0.02, seed=6)
    # the face: a smaller octagon sunk into it, longer at the bottom for the INDIGLOW key and the model name
    face = soft_poly(W, H, octagon(15, 33, 109, 140, 16), 3.0)
    d.well(face, 0.6, face_m, bevel=0.8)
    d.text("TIMEZ", CX, 36, brand_ink, align="c", font="57", flatlight=True)
    d.text("SET", 26, 47, ink, align="l", flatlight=True)       # each control's word toward its pusher
    d.text("ALARM", 98, 47, ink, align="r", flatlight=True)
    # the display
    x, y, w, h = TLCD
    glass = "lcdglow" if lit else nt("lcdwatch", night)          # the day glass is the CaZios' grey (Oct 29 2026)
    DW.window(d, x - 1, y - 1, w + 2, h + 2, 1.0, face=glass, bezel="blackp", r=1, bezel_t=1, on=Z_FACE + 0.4, lens=False)
    p.part("radioDisplay", kind="watch", style="lcd", x=x, y=y, w=w, h=h, color="#1a1c16", ghost="#a6aa9f", fields=TIMEZ_FIELDS,
           night=lcd_night("lcdwatch"), lit={"color": GLOW_INK, "ghost": False})
    DW.set_areas(p, x, y, w, h)
    # the INDIGLOW key under the screen, wide and round-ended, in the accent colour; SPEED and START under its ends
    key = soft_poly(W, H, octagon(38, 99, 86, 110, 3), 1.6)
    d.slab(key, 1.8, light_m, bevel=1.0, polish=0.6, on=Z_FACE)
    d.text("INDIGLOW", CX, 102, "paint_k", align="c", flatlight=True)
    p.hit("light", 36, 97, 52, 15)
    # the model name under the key; SPEED and START down in the bottom corners beside their pushers, as SET and ALARM
    # sit beside theirs at the top
    d.text("TRIATHLON", CX, 114, accent, align="c", flatlight=True)
    d.text("SPEED", 25, 126, ink, align="l", flatlight=True)
    d.text("START", 99, 126, ink, align="r", flatlight=True)
    if worn:
        import wear as WR
        WR.scuffs(d, WR.mat_mask(d, case_m), 0.0012, seed=8, amount=0.08)
    return p


TIMEZ_FIELDS = [
    # top row: the day at the left, the date big at the right (where CaZio has its thermometer)
    {"t": "text", "src": "day", "x": 3, "y": 3, "font": "35"},
    {"t": "seg", "src": "date", "x": 81, "y": 2, "cw": 5, "ch": 9, "pitch": 7, "n": 2},
    {"t": "text", "src": "pm", "x": 3, "y": 16, "font": "35"},
    {"t": "seg", "src": "time", "x": 68, "y": 14, "cw": 8, "ch": 15, "pitch": 11, "n": 5, "st": 2},
    {"t": "seg", "src": "sec", "x": 81, "y": 21, "cw": 4, "ch": 8, "pitch": 6, "n": 2},
    {"t": "bars", "src": "speed", "x": 3, "y": 36, "n": 3, "bw": 3, "gap": 1, "h0": 2, "dh": 2},
    {"t": "text", "src": "pause", "x": 3, "y": 31, "font": "35"},
    {"t": "text", "src": "alm", "x": 48, "y": 31, "font": "35"},
    {"t": "text", "src": "almTime", "x": 81, "y": 31, "font": "35", "align": "r"},
    {"t": "text", "src": "setTitle", "x": 42, "y": 3, "font": "35", "align": "c"},
    {"t": "seg", "src": "setVal", "x": 56, "y": 13, "cw": 8, "ch": 15, "pitch": 11, "n": 2, "st": 2},
    {"t": "text", "src": "setHint", "x": 42, "y": 31, "font": "35", "align": "c"},
]


# ------------------------------------------------------------------ the analogues
TANALOG = {
    #                case     dial          numerals   strap (mat, kind)          hands      kind
    "timez_easy":   ("steel", "dial_cream", "paint_k", ("leather", "leather"),     "#1c1b18", "easy"),
    "timez_camper": ("resin", "dial_green", "paint_w", ("nylon_green", "nylon"),   "#e6e3dc", "camper"),
}


def timez_analog(name="timez_easy", worn=True, night=False, lit=False):
    case_m, dial_m, num_m, (strap_m, strap_k), hands_c, kind = TANALOG[name]
    W, H = 150, 176
    p = Plate(name, W, H, seed=sum(map(ord, name)) % 997, title=name.replace("_", " "))
    d = p.d
    cx, cy = 75, 88
    metal = "steel"
    strap(p, 50, 50, 0, 46, strap_m, kind=strap_k)
    strap(p, 50, 50, 130, H, strap_m, kind=strap_k)
    # straight lugs
    for ly in (30, 132):
        for lx in (48, 94):
            cover(d, d.slab(Mask(W, H).rrect(lx, ly - 8, 8, 20, 2).get(), Z_FACE + 0.6, case_m, bevel=1.6, polish=0.6))
    # the pushers and crowns first (the case covers their roots)
    for pid, (x, y) in (("speed", (21, 107)), ("start", (115, 107))):
        px = x + 2 if x < cx else x - 2
        d.slab(Mask(W, H).rrect(px, y + 4, 12, 7, 2).get(), Z_FACE - 0.2, metal, bevel=1.0, polish=0.9)
        p.hit(pid, x, y, 14, 15)
    # the alarm's small crown at two
    th = math.radians(-45)
    ax, ay = cx + math.cos(th) * 50, cy + math.sin(th) * 50
    d.slab(line_mask(d, cx + math.cos(th) * 46, cy + math.sin(th) * 46, ax + math.cos(th) * 3, ay + math.sin(th) * 3, 6.5),
           Z_FACE - 0.2, metal, bevel=1.0, polish=0.9)
    p.hit("crown", int(ax - 6), int(ay - 8), 15, 15)
    # the main crown at three: push for the light
    d.slab(Mask(W, H).rrect(121, 81, 10, 14, 2).get(), Z_FACE - 0.2, metal, bevel=1.0, polish=0.9)
    for k in range(4):
        d.seam(rbox(d, 123 + k * 2, 82, 1, 12), 0.3)
    p.hit("light", 122, 79, 14, 18)
    for (x, y, t) in ((122, 41, "ALARM"), (28, 125, "SPEED"), (122, 125, "START"), (137, 72, "LIGHT")):
        nameplate(d, t, x, y, on=Z_FACE - 1.0, mat="paint_w", font="35", z=0.4, align="c")
    body = disc(d, cx, cy, 48)
    cover(d, d.slab(body, Z_FACE + 1.2, case_m, bevel=3.0, polish=0.7 if case_m == "steel" else 0.4))
    # a thin smooth bezel, then the dial
    ring = disc(d, cx, cy, 43) & ~disc(d, cx, cy, 40)
    d.slab(ring, Z_FACE + 2.2, case_m, bevel=1.0, polish=0.9 if case_m == "steel" else 0.5)
    dial = disc(d, cx, cy, 40)
    dm = "dialglow" if lit else nt(dial_m, night)
    d.flat(dial, Z_FACE + 1.0, dm, polish=0.2)
    # under the glow, light numerals turn to shadows; dark ones stay dark
    nm = ("paint_k" if lit else nt(num_m, night))
    # the minute track: a dot a minute, a bar every five
    for i in range(60):
        a = math.radians(i * 6 - 90)
        if i % 5:
            d.paint(disc(d, cx + math.cos(a) * 37.5, cy + math.sin(a) * 37.5, 0.5) & dial, nm, flatlight=True)
    if kind == "easy":
        # the Easy Reader: twelve big numerals, the date where the three would be
        for i in range(1, 13):
            if i == 3: continue
            a = math.radians(i * 30 - 90)
            r = 30 if i not in (10, 11, 12, 1, 2) else 30.5
            tx, ty = cx + math.cos(a) * r, cy + math.sin(a) * r
            d.text(str(i), int(round(tx)) + (0 if i < 10 else 1), int(round(ty - 3.5)), nm, align="c", font="57", flatlight=True)
        d.text("TIMEZ", cx, 67, nm, align="c", flatlight=True)
        d.text("INDIGLOW", cx, 75, "paint_k" if lit else nt("print_gold", night), align="c", flatlight=True)
        DW.window(d, 100, 84, 14, 9, 0.6, face=nt("enamel_white", night) if not lit else "dialglow", bezel=case_m, r=0, bezel_t=1,
                  on=Z_FACE + 1.0, lens=False)
        p.part("radioDisplay", kind="watch", style="dial", x=101, y=85, w=12, h=7, color="#1a1a1a", ghost=None,
               fields=[{"t": "text", "src": "dateWin", "x": 6, "y": 1, "font": "35", "align": "c"}],
               night={"color": "#2a2a26"}, lit={"color": GLOW_INK})
        sp = (56, 98, 40, 10)
    else:
        # the Camper: twelve numerals, the twenty-four hours in a small inner ring, no date
        for i in range(1, 13):
            a = math.radians(i * 30 - 90)
            tx, ty = cx + math.cos(a) * 31, cy + math.sin(a) * 31
            d.text(str(i), int(round(tx)) + (0 if i < 10 else 1), int(round(ty - 3.5)), nm, align="c", font="57", flatlight=True)
            ix, iy = cx + math.cos(a) * 23, cy + math.sin(a) * 23
            d.text(str(i + 12), int(round(ix)) + 1, int(round(iy - 2.5)), "paint_k" if lit else nt("paint_r", night), align="c",
                   flatlight=True)
        d.text("TIMEZ", cx, 75, nm, align="c", flatlight=True)
        sp = (56, 94, 40, 9)
    # the speed marks and PAUSE printed small on the dial, the alarm's dot beside them
    x, y, w, h = sp
    p.part("radioDisplay", kind="watch", style="dial", x=x, y=y, w=w, h=h,
           color="#8a6a22" if kind == "easy" else "#e0c860", ghost="#d8cfb2" if kind == "easy" else "#3a4430",
           fields=[{"t": "bars", "src": "speed", "x": 12, "y": h - 2, "n": 3, "bw": 4, "gap": 2, "h0": 3, "dh": 1},
                   {"t": "text", "src": "pause", "x": 20, "y": 2, "font": "35", "align": "c"},
                   {"t": "text", "src": "setText", "x": 20, "y": 2, "font": "35", "align": "c"}],
           night={"color": "#3e3a2c" if kind == "easy" else "#4a4630", "ghost": False},
           lit={"color": GLOW_INK, "ghost": False})
    DW.set_areas(p, 41, y - 4, 68, h + 14)
    # the alarm's dot just left of the speed marks, clear of the numerals
    d.dome(x + 6, y + h - 4, 1.4, 1.4, 0.4, "jewel_red_off", polish=0.9, on=Z_FACE + 1.0)
    p.lamp(disc(d, x + 6, y + h - 4, 1.3), "alarmOn", "#ff3a2e", halo=False)
    p.part("clock", cx=cx, cy=cy, rh=17, rm=27, color=hands_c, night={"color": DW.hands_night(hands_c)},
           lit={"color": GLOW_INK})
    if worn:
        import wear as WR
        WR.scuffs(d, WR.mat_mask(d, case_m), 0.0012, seed=10, amount=0.08)
    return p


# ------------------------------------------------------------------ the state pictures every watch carries
def variants(name):
    """the dark picture (when the plate changes in the dark) and, on a Timez, the lit one"""
    v = []
    v.append(("night", "dark", True, {"night": True}))   # every glass darkens now (the black went grey, Oct 29 2026)
    if name.startswith("timez_"):
        v.append(("lit", "lit", True, {"lit": True}))
    if name.startswith("digital_") or name.startswith("classic_"):
        # a CaZio's bulb (Oct 21 2026): its pool by day and over the night picture
        v.append(("bulb", "bulbDay", True, {"bulb_on": True}))
        v.append(("bulb_night", "bulbNight", True, {"bulb_on": True, "night": True}))
    return v


def design(name):
    if name.startswith("timez_"):
        fn = timez_digital if name in TDIGITAL else timez_analog
        return lambda **kw: fn(name, **kw)
    if name.startswith("digital_"): return lambda **kw: DW.digital(name, **kw)
    if name.startswith("classic_"): return lambda **kw: DW.classic(name, **kw)
    return lambda **kw: DW.expensive(**kw)


# the roster in game (director, Oct 16 2026): CaZio keeps the black and gold digitals and the black and gold classics;
# Timez takes the red (DigitalRed), the steel (half the DigitalDress watches), the brown (Easy Reader) and the military
# (Camper); the expensive one stays itself
ALL = ["digital_black", "digital_gold", "timez_red", "timez_steel",
       "classic_black", "classic_gold", "timez_easy", "timez_camper", "expensive"]
