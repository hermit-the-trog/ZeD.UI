"""The CaZio watches in the lit pixel art (director, Oct 16 2026): the eight faces of v5 redrawn, their controls and
layouts kept. The digitals take the old Casio case: an octagon, its corners cut on the angle and then dulled so they
are comfortable to the touch, not round and not sharp. The face sits in its own cut-corner frame; the two coloured
keys on the face, the two metal keys on the case below it (the A120 arrangement v5 locked).

A watch is a plate: the art, the live readout (a display layout: time in segments, day and date, PM, ALM, the
speed marks or PAUSE), the hands on the analogue ones, and the click areas (ALARM, SET, SPEED, START, the crown).
"""
import math

import numpy as np
from scipy import ndimage as ndi

from physlib import *            # noqa: F401,F403
import d_props as PR             # noqa: F401  (the display glasses' ramps)
from engine import add_ramp

add_ramp("resin", "#232427")                     # a digital's black resin case
add_ramp("strap", "#1b1c1e")                     # resin strap
add_ramp("lcdneg", "#0c0d0e")                    # a negative display's dark glass
add_ramp("face_ink", "#15161a")                  # a printed face, black
add_ramp("key_metal", "#a9adb3", light=1.1)
add_ramp("print_gold", "#c9a14a", light=1.1)
add_ramp("gold", "#c4a03a", light=1.15)            # gold plate (cases, bracelets)
add_ramp("red_resin", "#7c2222")                   # the red digital's case and strap
add_ramp("face_gold", "#a8893a", light=1.05)       # the gold digital's face
add_ramp("lcdpos", "#c3c8a6", light=1.05)          # a positive display (dark figures on a light glass)
add_ramp("lcdblue", "#b4c0cc", light=1.05)         # the dress watch's blue-grey glass
add_ramp("lcdwatch", "#b3b7ab", light=1.05)        # every CaZio screen (director, Oct 29 2026): one period grey, dark figures
add_ramp("key_violet", "#6c54cc"); add_ramp("key_teal", "#2ec0b4", light=1.05)
add_ramp("key_salmon", "#e29c7a", light=1.05); add_ramp("key_orange", "#d8662e")
add_ramp("key_blue", "#3a62c8")
add_ramp("dial_cream", "#e6dfc6", light=1.08)
add_ramp("dial_green", "#26301f")
add_ramp("leather", "#5a3a1e")
add_ramp("nylon_green", "#4b5a36")
# the dark (director, Oct 16 2026): every watch's screen and dial go faint at night; Timez lights its own
add_ramp("lcdpos_n", "#4b4f3f"); add_ramp("lcdblue_n", "#454c56"); add_ramp("lcdgrey_n", "#4a4c46"); add_ramp("lcdwatch_n", "#4a4c46")
add_ramp("dial_cream_n", "#58544a"); add_ramp("dial_green_n", "#151a12"); add_ramp("paint_dim", "#5e5f62")
add_ramp("enamel_white_n", "#5a5a56"); add_ramp("paint_r_n", "#5a2420")
add_ramp("lume", "#eeeadc", light=1.05); add_ramp("lume_glow", "#a6e6b0", light=1.25)
NIGHT = {"lcdwatch": "lcdwatch_n", "lcdpos": "lcdpos_n", "lcdblue": "lcdblue_n", "lcdgrey": "lcdgrey_n", "dial_cream": "dial_cream_n",
         "dial_green": "dial_green_n", "paint_w": "paint_dim", "paint_c": "paint_dim", "enamel_white": "enamel_white_n",
         "print_gold": "paint_dim", "lume": "lume_glow", "paint_r": "paint_r_n"}
def nt(mat, night):
    """a material as it looks in the dark (unchanged when it has no night shade)"""
    return NIGHT.get(mat, mat) if night else mat


def soft_poly(W, H, pts, r=2.5):
    """a filled polygon with its convex corners dulled by r px (opening by a disc)"""
    m = Mask(W, H).poly(pts).get(0.5)
    rr = int(math.ceil(r))
    yy, xx = np.mgrid[-rr:rr + 1, -rr:rr + 1]
    disc_ = (xx ** 2 + yy ** 2) <= r * r + 0.3
    return ndi.binary_opening(m, structure=disc_)


def octagon(x0, y0, x1, y1, c):
    """a rectangle with its corners cut on the angle, c px back from each corner"""
    return [(x0 + c, y0), (x1 - c, y0), (x1, y0 + c), (x1, y1 - c), (x1 - c, y1), (x0 + c, y1), (x0, y1 - c), (x0, y0 + c)]


def cover(d, mask):
    """a part laid over the straps hides their ridges and links: a seam is darkening, which a later slab keeps, so it
    showed through the case as a line where the strap tucks under it (director, Oct 29 2026: the bottom connection)"""
    d.dark[mask] = 0.0


def strap(p, x, w, y0, y1, mat="strap", ridge=4, kind="resin"):
    """resin (ridges across), metal links (a bracelet: links across, split in three), leather (stitched edges),
    nylon (a stripe down the middle)"""
    d = p.d
    m = Mask(p.W, p.H).rect(x, y0, w, y1 - y0).get()
    d.slab(m, Z_FACE - 1.0, mat, bevel=1.4, polish=0.75 if kind == "links" else 0.35)
    if kind == "resin":
        for y in range(y0 + 2, y1, ridge):
            d.seam(rbox(d, x + 2, y, w - 4, 1) & m, 0.35)
    elif kind == "links":
        for y in range(y0 + 3, y1, 7):
            d.seam(rbox(d, x, y, w, 1) & m, 0.45)
        third = w // 3
        for y in range(y0, y1, 14):
            for k in (1, 2):
                d.seam(rbox(d, x + k * third, y + 3, 1, 7) & m, 0.4)
    elif kind == "leather":
        for y in range(y0 + 1, y1, 3):
            d.seam(rbox(d, x + 2, y, 1, 1) & m, 0.3); d.seam(rbox(d, x + w - 3, y, 1, 1) & m, 0.3)
    elif kind == "nylon":
        d.paint(rbox(d, x + w // 2 - 3, y0, 6, y1 - y0) & m, "paint_k", flatlight=False)
        for y in range(y0 + 1, y1, 2):
            d.seam(rbox(d, x + 1, y, w - 2, 1) & m, 0.12)
    return m


# ------------------------------------------------------------------ the CaZio light (director, Oct 21 2026)
# "the cazio watches would have a little bulb too in one of the sides. they didnt have glow but did have a crappy
# little yellow glowing bulb": a tiny incandescent bulb at the display's left edge, beside the LIGHT pusher at the
# top of the case's left side (the director's reference: a 1990s digital, LIGHT top left with its printed arrow).
# Pressed, the glass turns only a little warmer and lighter, a soft yellowish grey a touch stronger by the bulb and
# fading across; the figures stay dark; nothing glows. In the dark it just lets you read the time.
# Three steps of the glass warmed toward the bulb's colour, ordered-dithered between steps (hard pixels).
BULB_LIGHT = (255, 200, 90)                           # what the bulb adds to the glass at night (weak warm yellow)
BULB_DOT = ("#e2c25e", "#bf9a3e")                     # the lit bulb, tiny and dim: its hot corner, the rest of it
BULB_STEPS = {                                        # per glass: (day mix toward the day tint, night light added)
    "lcdneg": ((0.02, 0.04, 0.06), (0.03, 0.05, 0.08)),
    "lcdpos": ((0.04, 0.07, 0.11), (0.06, 0.11, 0.17)),
    "lcdgrey": ((0.04, 0.07, 0.11), (0.06, 0.11, 0.17)),
    "lcdwatch": ((0.04, 0.07, 0.11), (0.06, 0.11, 0.17)),
}
BULB_DAY_TINT = (236, 214, 130)
BAYER4 = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))
# a negative display's figures (light on dark glass) carry the light themselves: by x from the display's left edge,
# the figures within each step take its colour (ZeD_Plate.lua's radioDisplay, fields "bulbDay" / "bulbNight"); a
# little warmer and lighter than the night's grey, never bright
BULB_INK_NEG = {"bulbDay": [{"x": 14, "c": "#ebe4cc"}],
                "bulbNight": [{"x": 16, "c": "#878068"}, {"x": 34, "c": "#767264"}, {"x": 54, "c": "#67675f"}]}


def _rgb(c): return hx(c) if isinstance(c, str) else tuple(c)


def _hex(c): return "#%02x%02x%02x" % tuple(int(max(0, min(255, round(v)))) for v in c)


def bulb_ramp(glass, night, i):
    """the pool's step i (1 faintest .. 3) for a glass, day or night: the glass's own ramp, every shade warmed the same
    way (so the glass keeps its shading under the light), registered once as a material"""
    name = f"bulb_{glass}_{'n' if night else 'd'}{i}"
    if name not in RAMPS:
        day_t, night_t = BULB_STEPS[glass]
        src = RAMPS[nt(glass, night)]
        if night:
            t = night_t[i - 1]
            RAMPS[name] = [tuple(int(min(255, round(c + l * t))) for c, l in zip(sh, BULB_LIGHT)) for sh in src]
        else:
            t = day_t[i - 1]
            RAMPS[name] = [tuple(int(round(c + (dc - c) * t)) for c, dc in zip(sh, BULB_DAY_TINT)) for sh in src]
    return name


def bulb(p, glass_mask, bx, by, glass, night=False, lit=False, reach=34.0, seed=0):
    """the bulb, a 1 x 2 speck at (bx, by) on the glass's left edge, and, lit, its light over the glass: a little
    stronger by the bulb and fading across, three steps of the glass warmed, ordered-dithered on a 4 x 4 Bayer grid"""
    d = p.d
    cx, cy = bx + 0.5, by + 1.0
    if lit:
        R = reach if night else reach * 0.6
        top = 3.4 if night else 2.6                      # by day the steps fade sooner
        yy, xx = np.mgrid[0:p.H, 0:p.W]
        dx, dy = xx + 0.5 - cx, (yy + 0.5 - cy) * 1.2
        th = np.arctan2(dy, dx)
        r = np.hypot(dx, dy) / (1.0 + 0.16 * np.sin(2.0 * th + 0.6 + seed) + 0.08 * np.cos(5.0 * th + 1.3 + seed))
        inten = top * np.clip(1.0 - r / R, 0, 1) ** 1.3
        thr = np.array(BAYER4, float)[yy % 4, xx % 4] / 16.0
        lev = np.clip(np.floor(inten + thr), 0, 3).astype(int)
        for i in (1, 2, 3):
            m = glass_mask & (lev == i)
            if m.any(): d.paint(m, bulb_ramp(glass, night, i))
        d.glow(rbox(d, bx, by, 1, 1), BULB_DOT[0]); d.glow(rbox(d, bx, by + 1, 1, 1), BULB_DOT[1])
    else:
        # the dead bulb: a dull speck at the glass's edge
        g = _rgb(RAMPS[nt(glass, night)][4])
        off = _hex([v * 0.55 + w * 0.45 for v, w in zip(g, (58, 52, 38) if glass != "lcdneg" else (70, 66, 56))])
        d.glow(rbox(d, bx, by, 1, 2), off)
    p.meta["light"] = "bulb"


def flat_key(p, pid, x, y, w, h, mat, label=None, lab_mat="paint_k", z=1.4, r=2):
    d = p.d
    m = soft_poly(p.W, p.H, octagon(x, y, x + w, y + h, 2), 1.0)
    d.slab(m, z, mat, bevel=0.9, polish=0.6, on=Z_FACE)
    if label:
        d.text(label, x + w // 2, y + (h - 5) // 2, lab_mat, align="c", flatlight=True)
    p.hit(pid, x, y, w, h)
    return m


# ------------------------------------------------------------------ the digital family
DIGITAL = {
    #                case         face         ring        key L         key R         metal        print       lcd glass  ink        ghost      strap (mat, kind)        brand ink   metal key ink
    "digital_black": ("resin",     "face_ink",  "paint_c", "paint_r",    "paint_y",    "key_metal", "paint_c", "lcdwatch", "#1a1c16", "#a6aa9f", ("strap", "resin"),      "paint_w", "paint_k"),
    "digital_red":   ("red_resin", "face_ink",  "paint_c", "paint_y",    "key_blue",   "red_resin", "paint_c", "lcdwatch", "#1a1c16", "#a6aa9f", ("red_resin", "resin"),  "paint_w", "paint_w"),
    "digital_dress": ("steel",     "face_ink",  "paint_c", "key_violet", "key_teal",   "key_metal", "paint_c", "lcdwatch", "#1a1c16", "#a6aa9f", ("steel", "links"),      "paint_w", "paint_k"),
    "digital_gold":  ("gold",      "face_gold", "paint_k", "key_salmon", "key_orange", "gold",      "paint_k", "lcdwatch", "#1a1c16", "#a6aa9f", ("gold", "links"),       "paint_k", "paint_k"),
}
LCD = (20, 49, 84, 38)
ARROW_INK = {"face_gold": "paint_k"}                     # the printed tab beside LIGHT: gold ink, dark on a gold face


def digital(name="digital_black", worn=True, night=False, bulb_on=False):
    case_m, face_m, ring_m, kl, kr, metal, ink, glass, lcd_ink, lcd_ghost, (strap_m, strap_k), brand_ink, key_ink = DIGITAL[name]
    W, H = 124, 176
    p = Plate(name, W, H, seed=sum(map(ord, name)) % 997, title=name.replace("_", " "))
    d = p.d
    # the strap: under the case at both ends
    strap(p, 34, 56, 0, 34, strap_m, kind=strap_k)
    strap(p, 34, 56, 144, H, strap_m, kind=strap_k)
    # the LIGHT pusher high on the case's left side (the case covers its root)
    d.slab(Mask(W, H).rrect(3, 43, 8, 7, 2).get(), Z_FACE - 0.2, metal, bevel=1.0, polish=0.9)
    p.hit("light", 0, 38, 14, 16)
    # the case: an octagon with dulled corners, its rim bevelled down to the strap
    case = soft_poly(W, H, octagon(8, 24, 116, 152, 17), 3.0)
    d.slab(case, Z_FACE + 1.0, case_m, bevel=3.0, polish=0.6)
    cover(d, case)
    d.grain_pebble(case, 0.02, seed=5)
    # the face in its own cut-corner frame, a hair down from the case's top
    face = soft_poly(W, H, face_pts(), 2.0)
    d.well(face, 0.6, face_m, bevel=0.8)
    ring = face & ~ndi.binary_erosion(face, iterations=2)
    d.paint(ring & ~ndi.binary_erosion(face, iterations=1), ring_m, flatlight=True)
    d.text("CaZio", 30, 35, brand_ink, font="57", flatlight=True)   # clear of the face's cut corner
    wr = soft_poly(W, H, octagon(78, 35, 94, 42, 2), 0.8)
    d.paint(wr, "paint_b", flatlight=True)
    d.text("WR", 86, 36, "paint_w", align="c", flatlight=True)
    # the second row: LIGHT at the left with its printed tab pointing at the pusher, the model's features at the right
    tab = ARROW_INK.get(face_m, "print_gold")
    d.paint(rbox(d, 19, 44, 3, 3) | rbox(d, 18, 45, 1, 1), tab, flatlight=True)   # a small tab, its point to the side
    d.text("LIGHT", 24, 43, ink, flatlight=True)
    d.text("ALARM-THERMO", 105, 43, ink, align="r", flatlight=True)
    # the display
    x, y, w, h = LCD
    gl = window(d, x - 1, y - 1, w + 2, h + 2, 1.0, face=nt(glass, night), bezel="blackp", r=1, bezel_t=1, on=Z_FACE + 0.4, lens=False)
    # the bulb on the display's left edge, level with the day, near its pusher (clear of every field)
    bulb(p, gl, x, y + 4, glass, night=night, lit=bulb_on, reach=60.0)
    extra = BULB_INK_NEG if glass == "lcdneg" else {}
    p.part("radioDisplay", kind="watch", style="lcd", x=x, y=y, w=w, h=h, color=lcd_ink, ghost=lcd_ghost, fields=DIGITAL_FIELDS,
           night=lcd_night(glass), **extra)
    set_areas(p, x, y, w, h)
    # a rule under the display, then the two coloured keys on the face with their words over them
    d.paint(rbox(d, 20, 92, 84, 1), ink, flatlight=True)
    d.text("ALARM", 40, 96, ink, align="c", flatlight=True)
    d.text("SET", 84, 96, ink, align="c", flatlight=True)
    flat_key(p, "alarm", 22, 103, 36, 9, kl)
    flat_key(p, "set", 66, 103, 36, 9, kr)
    # the two metal keys on the case under the face, cut to its shape: their outer corners angled like the case's,
    # their top outer corners swept up the face's cut corner (3 px off it), the two of them meeting in the middle
    for pid, lab, side in (("speed", "SPEED", -1), ("start", "START", 1)):
        pts = metal_key_pts(side)
        m = soft_poly(W, H, pts, 1.6)
        d.slab(m, 2.0, metal, bevel=1.1, polish=0.65, on=Z_FACE + 1.0)
        lx = 39 if side < 0 else 88       # SPEED leaves room for its light; START centred on its key
        d.text(lab, lx, 129, key_ink, align="c", flatlight=True)
        p.hit(pid, 16 if side < 0 else 64, 121, 44, 20)
    # SPEED's running mark in line with its word, the pair centred on the key: lit while the game runs
    d.dome(25, 131, 1.5, 1.5, 0.4, "jewel_grn_off", polish=0.9, on=Z_FACE + 3.0)
    p.lamp(disc(d, 25, 131, 1.4), "running", "#44ee44", halo=False)
    if worn:
        import wear as WR
        WR.scuffs(d, WR.mat_mask(d, case_m), 0.0012, seed=7, amount=0.08)
    return p


def set_areas(p, x, y, w, h):
    """while the alarm is being set: the left half of (x, y, w, h) takes the hour back, the right half on (one hour
    past 23 or before 0 is OFF)"""
    p.hit("setdn", x, y, w // 2, h, needs="setOpen")
    p.hit("setup", x + w // 2, y, w - w // 2, h, needs="setOpen")


def lcd_night(glass):
    """a display's figures in the dark: faint against the darkened glass, no ghost segments"""
    return {"color": "#55585a" if glass == "lcdneg" else "#25271f", "ghost": False}   # False, not None: it must override


def face_pts(gap=2, dgap=3):
    """the digital's face: the case's cut corners at the top; at the bottom it follows the metal keys, its edge gap px
    off their top edge and dgap px (measured up) off their swept corners, so the dark between reads the same on both (director, Oct 29 2026: close the gap)"""
    l = metal_key_pts(-1)
    ky = l[0][1]                                   # the keys' top edge
    (cx0, cy0), (cx1, cy1) = l[4], l[5]            # a key's swept corner, outer end up to inner end
    yb = ky - gap                                  # the face's bottom edge
    x0, x1, y0, c = 15, 109, 31, 11
    # the swept corner's line moved up by gap: where it meets the face's side and its bottom edge
    k = (cx1 - cx0) / (cy1 - cy0)
    xb = cx0 + (yb - (cy0 - dgap)) * k             # on the bottom edge
    ys = (cy0 - dgap) + (x0 - cx0) / k             # on the side
    return [(x0 + c, y0), (x1 - c, y0), (x1, y0 + c), (x1, ys), (124 - xb, yb), (xb, yb), (x0, ys), (x0, y0 + c)]


def metal_key_pts(side):
    """a bottom metal key's outline (side -1 left, +1 right), mirrored about the watch's centre line x = 62"""
    left = [(60, 121), (60, 141), (21, 141), (12, 132), (12, 114), (19, 121)]
    return [(124 - x, y) for (x, y) in left] if side > 0 else left


# the digital readout: big time, small seconds, day, date, PM, ALM, the three speed marks or PAUSE; in the alarm's set
# mode, the hour and the hint instead (fields draw only when their reading is there)
DIGITAL_FIELDS = [
    # top row: day and date at the left; the thermometer, big, at the right with its unit (the digital's perk)
    {"t": "text", "src": "day", "x": 3, "y": 3, "font": "35"},
    {"t": "seg", "src": "date", "x": 28, "y": 2, "cw": 4, "ch": 7, "pitch": 6, "n": 2},
    {"t": "seg", "src": "temp", "x": 70, "y": 2, "cw": 5, "ch": 9, "pitch": 7, "n": 3},
    {"t": "text", "src": "tempUnit", "x": 71, "y": 2, "font": "57"},
    # the time: P for afternoon, big figures, small seconds
    {"t": "text", "src": "pm", "x": 3, "y": 16, "font": "35"},
    {"t": "seg", "src": "time", "x": 68, "y": 14, "cw": 8, "ch": 15, "pitch": 11, "n": 5, "st": 2},
    {"t": "seg", "src": "sec", "x": 81, "y": 21, "cw": 4, "ch": 8, "pitch": 6, "n": 2},
    # bottom row: the speed marks (or PAUSE) at the left; the alarm, when it is set, with its hour at the right
    {"t": "bars", "src": "speed", "x": 3, "y": 36, "n": 3, "bw": 3, "gap": 1, "h0": 2, "dh": 2},
    {"t": "text", "src": "pause", "x": 3, "y": 31, "font": "35"},
    {"t": "text", "src": "alm", "x": 48, "y": 31, "font": "35"},
    {"t": "text", "src": "almTime", "x": 81, "y": 31, "font": "35", "align": "r"},
    # the alarm's set mode: its hour big, the hint under it (the other readings are left out meanwhile)
    {"t": "text", "src": "setTitle", "x": 42, "y": 3, "font": "35", "align": "c"},
    {"t": "seg", "src": "setVal", "x": 56, "y": 13, "cw": 8, "ch": 15, "pitch": 11, "n": 2, "st": 2},
    {"t": "text", "src": "setHint", "x": 42, "y": 31, "font": "35", "align": "c"},
]


# ------------------------------------------------------------------ the classic family (round ana-digi)
CLASSIC = {
    #                   case     bezel    dial          index      strap (mat, kind)          print      brand      hands      lcd glass
    "classic_black":    ("resin", "steel", "face_ink",   "paint_w", ("strap", "resin"),         "paint_c", "paint_w", "#e6e3dc", "lcdwatch"),
    "classic_brown":    ("steel", "steel", "dial_cream", "paint_k", ("leather", "leather"),     "paint_k", "paint_k", "#26241f", "lcdwatch"),
    "classic_gold":     ("gold",  "gold",  "dial_cream", "paint_k", ("gold", "links"),          "paint_k", "paint_k", "#26241f", "lcdwatch"),
    "classic_military": ("resin", "resin", "dial_green", "paint_w", ("nylon_green", "nylon"),   "paint_c", "paint_w", "#e6e3dc", "lcdwatch"),
}


def classic(name="classic_black", worn=True, night=False, bulb_on=False):
    case_m, bezel_m, dial_m, idx_m, (strap_m, strap_k), ink, brand_ink, hands_c, glass = CLASSIC[name]
    W, H = 150, 176
    p = Plate(name, W, H, seed=sum(map(ord, name)) % 997, title=name.replace("_", " "))
    d = p.d
    cx, cy = 75, 88
    strap(p, 48, 54, 0, 46, strap_m, kind=strap_k)
    strap(p, 48, 54, 130, H, strap_m, kind=strap_k)
    # lugs, then the case: a round body. The top lug mirrors the bottom one (y 40 against 120), so the strap
    # runs into the case the same way at both ends (director, Oct 29 2026: "match the bottom")
    for ly in (34, 126):
        cover(d, d.slab(Mask(W, H).rrect(46, ly + 6 if ly < 88 else ly - 6, 58, 16, 3).get(), Z_FACE + 0.6, case_m, bevel=2.0, polish=0.5))
    # pushers and crown first (the case covers their inner ends)
    for pid, (x, y, w, h) in (("set", (21, 54, 14, 15)), ("alarm", (115, 54, 14, 15)), ("speed", (21, 107, 14, 15)),
                              ("start", (115, 107, 14, 15))):
        px = x + 2 if x < cx else x - 2
        d.slab(Mask(W, H).rrect(px, y + 4, 12, 7, 2).get(), Z_FACE - 0.2, "gold" if case_m == "gold" else "steel", bevel=1.0, polish=0.9)
        p.hit(pid, x, y, w, h)
    d.slab(Mask(W, H).rrect(122, 82, 8, 12, 2).get(), Z_FACE - 0.2, "gold" if case_m == "gold" else "steel", bevel=1.0, polish=0.9)
    for k in range(3):
        d.seam(rbox(d, 124 + k * 2, 83, 1, 10), 0.3)
    p.hit("crown", 125, 80, 12, 16)
    # the LIGHT pusher at nine, on the display's side (the crown's opposite)
    d.slab(Mask(W, H).rrect(18, 84, 10, 8, 2).get(), Z_FACE - 0.2, "gold" if case_m == "gold" else "steel", bevel=1.0, polish=0.9)
    p.hit("light", 12, 80, 14, 16)
    body = disc(d, cx, cy, 50)
    cover(d, d.slab(body, Z_FACE + 1.2, case_m, bevel=3.0, polish=0.55))
    # the bezel ring and the dial under the glass
    ring = disc(d, cx, cy, 44) & ~disc(d, cx, cy, 39)
    d.slab(ring, Z_FACE + 2.4, bezel_m, bevel=1.2, polish=0.9)
    dial = disc(d, cx, cy, 39)
    d.flat(dial, Z_FACE + 1.0, nt(dial_m, night), polish=0.2)
    for i in range(12):
        a = math.radians(i * 30 - 90)
        r0, r1 = (31, 37) if i % 3 == 0 else (33, 37)
        m = line_mask(d, cx + math.cos(a) * r0, cy + math.sin(a) * r0, cx + math.cos(a) * r1, cy + math.sin(a) * r1, 2.0 if i % 3 == 0 else 1.2)
        d.paint(m & dial, nt(idx_m, night), flatlight=True)
    d.text("CaZio", cx, 62, nt(brand_ink, night), align="c", flatlight=True)
    d.text("QUARTZ", cx, 69, nt(ink, night), align="c", flatlight=True)
    # the pushers' words, printed beside them on the case's flank (v5's places)
    for (x, y, t) in ((28, 46, "SET"), (122, 46, "ALARM"), (28, 125, "SPEED"), (122, 125, "START"), (13, 76, "LIGHT")):
        nameplate(d, t, x, y, on=Z_FACE - 1.0, mat="paint_w", font="35", z=0.4, align="c")
    # the display window in the dial's lower half, its bulb on the left edge
    x, y, w, h = 53, 98, 44, 14
    gl = window(d, x - 1, y - 1, w + 2, h + 2, 0.6, face=nt(glass, night), bezel=bezel_m, r=0, bezel_t=1, on=Z_FACE + 1.0, lens=False)
    bulb(p, gl, x, y + 6, glass, night=night, lit=bulb_on, reach=36.0, seed=1.1)
    p.part("radioDisplay", kind="watch", style="lcd", x=x, y=y, w=w, h=h, color="#1a1c16", ghost="#a6aa9f", fields=CLASSIC_FIELDS,
           night=lcd_night("lcdwatch"))
    set_areas(p, 41, 94, 68, 24)
    d.dome(89, 84, 1.4, 1.4, 0.4, "jewel_red_off", polish=0.9, on=Z_FACE + 1.0)
    p.lamp(disc(d, 89, 84, 1.3), "alarmOn", "#ff3a2e", halo=False)
    p.part("clock", cx=cx, cy=cy, rh=16, rm=25, color=hands_c, night={"color": hands_night(hands_c)})
    if worn:
        import wear as WR
        WR.scuffs(d, WR.mat_mask(d, case_m), 0.0012, seed=9, amount=0.08)
    return p


def expensive(worn=True, night=False):
    """the expensive one: a round gold case, a fluted bezel, a cream dial with the date window at three, the crown
    (the alarm) and two pushers (START above, SPEED below); its speed marks and PAUSE printed small on the dial live"""
    W, H = 150, 176
    p = Plate("expensive", W, H, seed=211, title="expensive")
    d = p.d
    cx, cy = 75, 88
    strap(p, 46, 58, 0, 46, "gold", kind="links")
    strap(p, 46, 58, 130, H, "gold", kind="links")
    for ly in (34, 126):
        cover(d, d.slab(Mask(W, H).rrect(44, ly + 6 if ly < 88 else ly - 6, 62, 16, 3).get(), Z_FACE + 0.6, "gold", bevel=2.0, polish=0.8))
    for pid, (x, y, w, h) in (("start", (115, 55, 14, 14)), ("speed", (115, 108, 14, 14))):
        d.slab(Mask(W, H).rrect(x - 2, y + 4, 12, 7, 2).get(), Z_FACE - 0.2, "gold", bevel=1.0, polish=0.9)
        p.hit(pid, x, y, w, h)
    d.slab(Mask(W, H).rrect(120, 82, 9, 12, 2).get(), Z_FACE - 0.2, "gold", bevel=1.0, polish=0.9)
    for k in range(4):
        d.seam(rbox(d, 121 + k * 2, 83, 1, 10), 0.3)
    p.hit("crown", 123, 80, 12, 16)
    for (x, y, t) in ((122, 47, "START"), (122, 126, "SPEED"), (135, 76, "ALARM")):
        nameplate(d, t, x, y, on=Z_FACE - 1.0, mat="paint_w", font="35", z=0.4, align="c")
    body = disc(d, cx, cy, 50)
    cover(d, d.slab(body, Z_FACE + 1.2, "gold", bevel=3.0, polish=0.85))
    # the fluted bezel: ridges all round
    ring = disc(d, cx, cy, 46) & ~disc(d, cx, cy, 39)
    d.slab(ring, Z_FACE + 2.8, "gold", bevel=1.0, polish=1.0)
    ang = np.degrees(np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx))
    flutes = ring & ((np.floor((ang + 180) / 6) % 2) == 0)
    d.h[flutes] -= 0.6
    dial = disc(d, cx, cy, 38)
    d.flat(dial, Z_FACE + 1.0, nt("dial_cream", night), polish=0.3)
    for i in range(12):
        if i == 3: continue                      # the date window sits at three
        a = math.radians(i * 30 - 90)
        r0, r1 = (29, 36) if i % 3 == 0 else (32, 36)
        m = line_mask(d, cx + math.cos(a) * r0, cy + math.sin(a) * r0, cx + math.cos(a) * r1, cy + math.sin(a) * r1, 2.2 if i % 3 == 0 else 1.4)
        d.slab(m & dial, 0.6, "gold", bevel=0.4, polish=1.0, on=Z_FACE + 1.0)
        # the luminous dot inside each index: cream by day, glowing in the dark (the expensive one reads at night)
        lr = r0 - 2.5
        d.paint(disc(d, cx + math.cos(a) * lr, cy + math.sin(a) * lr, 1.2) & dial, nt("lume", night), flatlight=True)
    d.text("ROLLEX", cx, 64, "paint_k", align="c", font="57", flatlight=True)
    d.text("PERPETUAL", cx, 73, "paint_k", align="c", flatlight=True)
    # the date window at three: a cut in the dial with its own white wheel
    window(d, 96, 84, 14, 9, 0.6, face=nt("enamel_white", night), bezel="gold", r=0, bezel_t=1, on=Z_FACE + 1.0, lens=False)
    p.part("radioDisplay", kind="watch", style="dial", x=97, y=85, w=12, h=7, color="#1a1a1a", ghost=None,
           fields=[{"t": "text", "src": "dateWin", "x": 6, "y": 1, "font": "35", "align": "c"}], night={"color": "#2a2a26"})
    # the speed marks and PAUSE, printed live on the dial's lower half; the alarm's dot beside them
    p.part("radioDisplay", kind="watch", style="dial", x=56, y=104, w=40, h=10, color="#9a7a22", ghost="#d8cfb2",
           fields=[{"t": "bars", "src": "speed", "x": 12, "y": 8, "n": 3, "bw": 4, "gap": 2, "h0": 3, "dh": 1},
                   {"t": "text", "src": "pause", "x": 20, "y": 2, "font": "35", "align": "c"},
                   {"t": "text", "src": "setText", "x": 20, "y": 2, "font": "35", "align": "c"}],
           night={"color": "#3e3a2c", "ghost": False})
    set_areas(p, 44, 96, 62, 22)
    d.dome(48, 109, 1.4, 1.4, 0.4, "jewel_red_off", polish=0.9, on=Z_FACE + 1.0)
    p.lamp(disc(d, 48, 109, 1.3), "alarmOn", "#ff3a2e", halo=False)
    p.part("clock", cx=cx, cy=cy, rh=17, rm=26, color="#4a3a14", night={"color": "#a6e6b0"})
    if worn:
        import wear as WR
        WR.scuffs(d, WR.mat_mask(d, "gold"), 0.0008, seed=13, amount=0.06)
    return p


def hands_night(c):
    """plain hands in the dark: light ones go grey, dark ones sink into the dial"""
    return "#6a6a66" if c.lower() in ("#e6e3dc",) else "#1e1d1a"


CLASSIC_FIELDS = [
    {"t": "text", "src": "day", "x": 2, "y": 2, "font": "35"},
    {"t": "seg", "src": "date", "x": 42, "y": 2, "cw": 4, "ch": 7, "pitch": 6, "n": 2},
    {"t": "bars", "src": "speed", "x": 2, "y": 12, "n": 3, "bw": 3, "gap": 1, "h0": 2, "dh": 1},
    {"t": "text", "src": "pause", "x": 2, "y": 8, "font": "35"},
    {"t": "text", "src": "alm", "x": 42, "y": 8, "font": "35", "align": "r"},
    # the alarm's set mode: AL and the hour (or OFF), the hint under it
    {"t": "text", "src": "setText", "x": 22, "y": 2, "font": "35", "align": "c"},
    {"t": "text", "src": "setHint", "x": 22, "y": 8, "font": "35", "align": "c"},
]


def set_reading(alarm, alarm_hour, date):
    """the alarm's set mode: only the setting shows (and the date window, which is a separate wheel)"""
    return {"setTitle": "ALARM" if alarm else "ALARM OFF", "setVal": f"{alarm_hour:02d}" if alarm else "",
            "setHint": "-1H  +1H", "setText": f"AL {alarm_hour:02d}" if alarm else "AL OFF", "dateWin": str(date)}


def reading(hour=10, minute=58, sec=50, day="MO", date=26, speed=1, alarm=False, pm=False, digital_=True, temp=21, unit="C",
            alarm_hour=6, set_open=False):
    if set_open: return set_reading(alarm, alarm_hour, date)
    r = {"day": day, "date": str(date), "dateWin": str(date)}
    if digital_:
        h12 = hour
        r.update(time=f"{h12:2d}:{minute:02d}", sec=f"{sec:02d}", pm="P" if pm else "")
        if temp is not None: r.update(temp=str(temp), tempUnit="\u00b0" + unit)
        if alarm: r["almTime"] = f"{alarm_hour}:00"
    if speed == 0: r["pause"] = "PAUSE"
    else: r["speed"] = speed
    if alarm: r["alm"] = "ALM"
    return r


def state(**kw):
    dig = kw.pop("digital_", True)
    dark, lit = kw.pop("dark", False), kw.pop("lit", False)
    bulb_on = kw.pop("bulb", False)          # a CaZio's bulb (ZeD_Watch.lua: the night stays, the pool goes over it)
    s = {"display": reading(digital_=dig, **kw), "hour": kw.get("hour", 10), "minute": kw.get("minute", 58),
         "running": kw.get("speed", 1) > 0, "alarmOn": kw.get("alarm", False), "dark": dark and not lit, "lit": lit,
         "setOpen": kw.get("set_open", False), "bulb": bulb_on, "bulbDay": bulb_on and not dark,
         "bulbNight": bulb_on and dark}
    return s
