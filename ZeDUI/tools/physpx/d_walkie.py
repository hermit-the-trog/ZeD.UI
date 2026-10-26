"""The two-way radios in the radio tab (mockup, Oct 25 2026): the walkie talkies and the ManPack as a panel the size of
the item card (220 wide), the three tabletop ham sets at the drawer's full width. Each face is matched to the game's
own model: the walkies to their model textures (media/textures/weapons/1handed/WalkieTalkie_*.png) and world tiles
(appliances_com_01_16..48), the ManPack to its icon, the ham sets to their placed tiles (appliances_com_01_0/8/56).

Faces only (director, Oct 25): no antenna, no microphone, nothing standing off the front: the knobs and the push-to-talk
key are on the face. In the tab the face sits in its panel; full view shows the same plate on its own, no window frame,
like the watch.

Controls follow the car's two-way faces (d_props.ham / army), so the radio's workings are the same set:
  vol (turn: power and volume)   tune (turn: the frequency)   chup / chdn (step the memory channels)
  mem (store; hold to name)      mic (push to talk: the mic latched live or muted)   mute
The display is drawn live (part radioDisplay), its fields from LAYOUTS below.
"""
import math

import numpy as np

from physlib import *            # noqa: F401,F403
import wear as WR
from engine import add_ramp
import d_props as PR

# ---- the models' plastics and paints (sampled from the game's textures and tiles)
add_ramp("wt_char", "#3d3d3e")                 # Toys-R-Mine, ValuTech, Premium Tech.: dark grey plastic
add_ramp("wt_tac", "#46594a")                  # Tactical: green-black rubberised
add_ramp("wt_army", "#566a58")                 # US Army: olive green
add_ramp("wt_yellow", "#e2c626", light=1.1)    # ValuTech's display surround
add_ramp("wt_red", "#c42a20")                  # Premium Tech.'s display surround, the PTT bars
add_ramp("wt_ptt_grey", "#6a6d70")
add_ramp("duct", "#9a9c9e", light=1.1)         # duct tape
add_ramp("mp_olive", "#55613f")                # the ManPack's case
add_ramp("ham_silver", "#b9bcbd", light=1.12)  # Premium Technologies ham: brushed silver
add_ramp("ham_olive", "#66795c")               # US ARMY COMM. ham: olive case
add_ramp("ham_inset", "#4b4e4c")               # its grey front panel
add_ramp("crate", "#c4a473", light=1.08)       # the makeshift ham's crate
add_ramp("crate_face", "#ddd0b0", light=1.1)   # its front board
add_ramp("grille_ring", "#c9cccf", light=1.15)
RAMPS["lcd_light"] = [hx(c) for c in ("#6c7064", "#7a7e72", "#888c80", "#979b8e", "#a5a99c", "#b3b7aa", "#c1c5b8", "#cfd3c6")]
RAMPS["lcd_amber"] = [hx(c) for c in ("#6e5222", "#7e5e28", "#8e6b2f", "#9e7836", "#ae863e", "#be9447", "#cea251", "#deb15c")]
RAMPS["lcd_yg"] = [hx(c) for c in ("#5f6838", "#6c763f", "#798447", "#87924f", "#95a058", "#a3ae62", "#b1bc6d", "#bfc978")]
RAMPS["lcd_cyan"] = [hx(c) for c in ("#2c5c62", "#336a71", "#3a7880", "#42878f", "#4b969e", "#56a5ad", "#62b4bc", "#70c3cb")]
RAMPS["drum"] = [hx(c) for c in ("#8a8476", "#9a9486", "#aaa496", "#bab4a6", "#c9c3b5", "#d6d0c2", "#e2dccf", "#eee8dc")]

# readout colours: (figure, unlit-segment ghost)
STYLE = {
    "lcd_light": ("#1a1c16", "#9fa396"), "lcd_amber": ("#24180a", "#a8823e"), "lcd_yg": ("#1d2210", "#9aa65b"),
    "lcd_cyan": ("#0a2226", "#4f9aa2"), "drum": ("#1a1814", None), "led": ("#ff3a24", "#2a0806"),
    "lcdgrey": ("#16190f", "#727d68"), "char": ("#1f2a0c", "#8b9e4c"),
}


# ------------------------------------------------------------------ the displays' layouts (drawn live)
def lay_walkie(w):
    """a walkie's LCD (w x 44): CH and its memory number, the frequency big, the station marching, then the battery,
    the volume and the talk state"""
    return [
        {"t": "text", "src": "chLabel", "x": 4, "y": 3, "font": "35"},
        {"t": "text", "src": "ch", "x": 4, "y": 11, "font": "57"},
        {"t": "seg", "src": "big", "x": w - 4, "y": 3, "cw": 8, "ch": 18, "pitch": 12, "st": 2, "n": 6, "ghost": True},
        {"t": "text", "src": "line", "x": 4, "y": 25, "font": "57", "w": w - 8, "marquee": True},
        {"t": "text", "src": "batLabel", "x": 4, "y": 36, "font": "35"},
        {"t": "bars", "src": "batt", "x": 18, "y": 41, "n": 4, "bw": 3, "gap": 1, "h0": 5, "dh": 0},
        {"t": "text", "src": "volLabel", "x": 38, "y": 36, "font": "35"},
        {"t": "bars", "src": "vol", "x": 52, "y": 41, "n": 6, "bw": 2, "gap": 1, "h0": 1, "dh": 1},
        {"t": "text", "src": "tx", "x": w - 4, "y": 36, "font": "35", "align": "r"},
    ]


def lay_drum(w):
    """the toy's tuning drum behind its slot: the frequency only"""
    return [{"t": "text", "src": "big", "x": w // 2, "y": 5, "font": "57", "align": "c"}]


def lay_char(cols):
    return [
        {"t": "cells", "src": "l1", "x": 4, "y": 4, "cols": cols, "pitch": 8, "font": "57"},
        {"t": "cells", "src": "l2", "x": 4, "y": 15, "cols": cols, "pitch": 8, "font": "57", "marquee": True},
    ]


def display(p, kind, style, x, y, w, h, layout, bezel="blackp", lens=False, lamp=None):
    """lamp: the backlight's colour on a set with a LAMP key (the glass goes dark at night until it is pressed)"""
    face = {"led": "ledglass", "char": "lcdlit"}.get(style, style)
    window_glass(p, x - 2, y - 2, w + 4, h + 3, face=face, bezel=bezel, depth=1.6,
                 on=Z_FACE, r=1, bezel_t=2, lens=lens)
    col, ghost = STYLE[style]
    p.part("radioDisplay", kind=kind, style=style, x=x, y=y, w=w, h=h, color=col, ghost=ghost, fields=layout, lamp=lamp)


# ------------------------------------------------------------------ walkie parts
def body_shape(p, x, y, w, h, mat, r=12, grain="pebble", seed=1):
    d = p.d
    m = Mask(p.W, p.H).rrect(x, y, w, h, r).get()
    d.slab(m, Z_FACE, mat, bevel=3.0, polish=0.4)
    if grain == "pebble": d.grain_pebble(m, 0.04, seed=seed)
    return m


def tx_led(p, cx, cy, on=Z_FACE):
    d = p.d
    d.dome(cx, cy, 2.6, 2.6, 1.1, "jewel_red_off", polish=0.9, on=on)
    p.lamp(disc(d, cx, cy, 2.4), "micLive", "#ff3a2e")


def squircle(d, cx, cy, rx, ry, n=4.0):
    """a superellipse |x/rx|^n + |y/ry|^n <= 1: n = 2 is an ellipse, 4 the squircle"""
    return (np.abs((d.XX + 0.5 - cx) / rx) ** n + np.abs((d.YY + 0.5 - cy) / ry) ** n) <= 1.0


def slot_grille(p, cx, cy, rx, ry, vertical=True, pitch=4, slot=2):
    """a speaker grille: a squircle with a moulded rim, slots across it (director, Oct 25: squircle the grilles)"""
    d = p.d
    oval = squircle(d, cx, cy, rx, ry)
    d.well(oval & ~squircle(d, cx, cy, rx - 2, ry - 2), 0.8, None, bevel=0.8)      # the moulded rim
    sl = np.zeros_like(oval)
    if vertical:
        for x in range(int(cx - rx + 4), int(cx + rx - 3), pitch): sl |= rbox(d, x, int(cy - ry), slot, int(2 * ry + 1))
    else:
        for y in range(int(cy - ry + 4), int(cy + ry - 3), pitch): sl |= rbox(d, int(cx - rx), y, int(2 * rx + 1), slot)
    inner = squircle(d, cx, cy, rx - 4, ry - 4)
    d.well(sl & inner, 2.0, "mesh", bevel=0.6)
    return oval


def round_key(p, pid, cx, cy, r=5, mat="blackp", on=Z_FACE, icon=None, ink="paint_w"):
    d = p.d
    d.dome(cx, cy, r, r, 2.0, mat, polish=0.7, on=on)
    if icon in ("up", "down"): arrow_icon(p, cx, cy + 0.5, icon == "up", ink, w=7, h=4)
    elif icon: d.text(icon, cx, cy - 2, ink, align="c", flatlight=True)
    p.hit(pid, cx - r - 1, cy - r - 1, 2 * r + 2, 2 * r + 2)


def keypad(p, x0, y0, keys, kw=26, kh=14, gx=6, gy=6, mat="blackp", lab="paint_w", mark=None, cols=3):
    """rows of rubber keys; keys: (pid, label or None, icon or None)"""
    d = p.d
    for i, (pid, label, icon) in enumerate(keys):
        x = x0 + (i % cols) * (kw + gx); y = y0 + (i // cols) * (kh + gy)
        if icon and label:
            PR.radio_key(p, pid, x, y, kw, kh, None, mat=mat, lab_mat=lab, z=1.8)
            d.text(label, x + kw // 2 - 5, y + (kh - 5) // 2, lab, align="c", flatlight=True)
            arrow_icon(p, x + kw // 2 + 7, y + kh / 2 + 0.5, icon == "up", lab, w=5, h=3)
        else:
            PR.radio_key(p, pid, x, y, kw, kh, label, mat=mat, lab_mat=lab, icon=icon, z=1.8)
        if mark: d.paint(rbox(d, x + 3, y + 2, 1, 3), mark, flatlight=True)


def worn(p, mat, seed, grime=0.24, scuffs=0.10):
    d = p.d
    WR.grime(d, d.solid, amount=grime, seed=seed)
    WR.scuffs(d, WR.mat_mask(d, mat), 0.0012, seed=seed + 1, amount=scuffs)


def arc_dial(p, cx, cy, r_in, r_out, a0=-205, a1=25, labels=("10", "100", "250", "500"), ink="paint_g"):
    """the green tuning arc over the dial (the tiles show it): ticks and a few figures; the game draws the red marker
    along it for the frequency's place in the band (part ptr, src bandF)"""
    d = p.d
    for i in range(25):
        a = math.radians(a0 + (a1 - a0) * i / 24)
        ln = r_out if i % 6 == 0 else r_in + (r_out - r_in) * 0.55
        m = Mask(p.W, p.H).line([(cx + r_in * math.cos(a), cy + r_in * math.sin(a)), (cx + ln * math.cos(a), cy + ln * math.sin(a))], 1.0).get(0.45)
        d.paint(m, ink, flatlight=True)
    arc = Mask(p.W, p.H).arc(cx, cy, r_in - 1, r_in - 1, a0, a1, 1.0).get(0.45)
    d.paint(arc, ink, flatlight=True)
    for i, lab in enumerate(labels):
        a = math.radians(a0 + (a1 - a0) * i / (len(labels) - 1))
        tx, ty = cx + (r_out + 7) * math.cos(a), cy + (r_out + 6) * math.sin(a)
        d.text(lab, int(tx), int(ty - 2), ink, align="c", flatlight=True)
    p.part("ptr", src="bandF", cx=cx, cy=cy, r0=r_in - 2, r1=r_out + 1, a0=a0, a1=a1, color="#e0301e", w=1)


def dot_grille(p, cx, cy, r, ring_mat=None, pitch=4):
    d = p.d
    if ring_mat: d.torus(cx, cy, r, r + 4, 2.4, ring_mat, polish=1.0, on=Z_FACE)
    else: d.well(ring(d, cx, cy, r, r + 2), 0.8, None, bevel=0.6)
    for y in range(int(cy - r), int(cy + r) + 1, pitch):
        for x in range(int(cx - r), int(cx + r) + 1, pitch):
            off = (pitch // 2) if ((y - int(cy - r)) // pitch) % 2 else 0
            if math.hypot(x + off - cx, y - cy) <= r - 3:
                d.well(disc(d, x + off + 0.5, y + 0.5, 1.2), 1.4, "mesh", bevel=0.5)


def toggle_key(p, pid, x, y, w, h, label, mat="paint_g", ink="paint_k"):
    """a green rocker key (the tiles' two green switches): MIC and MUTE"""
    PR.radio_key(p, pid, x, y, w, h, None, mat="enamel_mint" if mat == "paint_g" else mat, z=2.2)
    p.label(label, x + w // 2, y + h + 4, ink, align="c", auto_ink=False)


def face_knob(p, pid, cx, cy, r, label, ink="paint_w", mat="blackp", ridges=30, label_y=None):
    """a knob on the face: VOL - PWR (press: power, turn: volume) or TUNE; its pointer is drawn live"""
    return PR.radio_knob(p, cx, cy, r, mat=mat, ridges=ridges, pid=pid, label=label, label_y=label_y or int(cy + r + 5), lab_mat=ink)


def ptt_key(p, x, y, w, h, mat="wt_red", label="PUSH TO TALK", ink="paint_w", ridges=True):
    """the push-to-talk key, on the face: MIC (a click latches the mic live, again mutes it)"""
    d = p.d
    p.check_flat(x - 1, y - 1, w + 2, h + 2, "push to talk")
    m = Mask(p.W, p.H).rrect(x, y, w, h, 4).get()
    d.slab(m, 2.6, mat, bevel=1.8, polish=0.55, on=Z_FACE)
    if ridges:
        for xx in range(x + 6, x + w - 5, 4): d.dark[y + 3:y + 7, xx] += 0.2; d.dark[y + h - 7:y + h - 3, xx] += 0.2
    if label: d.text(label, x + w // 2, y + (h - 5) // 2, ink, align="c", flatlight=True)
    p.hit("mic", x, y, w, h)


def face_body(p, mat, r=18, seed=1, frame=True):
    d = p.d
    m = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, r).get()
    d.slab(m, Z_FACE, mat, bevel=3.0, polish=0.4)
    d.grain_pebble(m, 0.04, seed=seed)
    return m


def corner_screws(p, inset=12, mat="steel", on=Z_FACE):
    for (x, y) in ((inset, inset), (p.W - inset - 1, inset), (inset, p.H - inset - 1), (p.W - inset - 1, p.H - inset - 1)):
        screw(p, x, y, on=on, mat=mat)


WALKIE_W, WALKIE_H = 200, 360          # the face; it sits in the 220-wide panel with 10 px either side


# =================================================================================== the walkies
def toy(worn_=True):
    """Toys-R-Mine Walkie Talkie (Base.WalkieTalkie1): the toy. Dark grey shell, a big slotted grille, no screen: the
    frequency turns on a drum behind a slot. A big round red TALK button. No memory channels."""
    p = Plate("walkie_toy", WALKIE_W, WALKIE_H, seed=201, title="Toys-R-Mine Walkie Talkie")
    d = p.d
    face_body(p, "wt_char", r=22, seed=202)
    tx_led(p, 184, 16)
    face_knob(p, "vol", 40, 46, 15, "VOL - ON")
    face_knob(p, "tune", 160, 46, 15, "TUNE")
    display(p, "toy", "drum", 40, 90, 120, 17, lay_drum(120), bezel="blackp")
    slot_grille(p, 100, 172, 62, 46, vertical=True)
    d.dome(100, 252, 22, 22, 3.4, "wt_red", polish=0.7, on=Z_FACE)                  # TALK
    d.torus(100, 252, 22, 25, 1.2, "blackp", polish=0.5, on=Z_FACE)
    d.text("TALK", 100, 250, "paint_w", align="c", font="57", flatlight=True)
    p.hit("mic", 76, 228, 48, 48)
    st = Mask(p.W, p.H).rrect(22, 288, 156, 50, 5).get()
    d.slab(st, 0.3, "enamel_white", bevel=0.6, polish=0.6, on=Z_FACE)
    cols = ("paint_r", "paint_b", "paint_y", "paint_g", "paint_k", "paint_r", "paint_k", "paint_b", "paint_y", "paint_g", "paint_r")
    for i, (ch, col) in enumerate(zip("TOYS-R-MINE", cols)):
        d.text(ch, 56 + i * 8, 296, col, font="57", flatlight=True)
    d.text("2-WAY", 100, 310, "paint_k", align="c", font="57", flatlight=True)
    d.text("AGES 8 AND UP", 100, 326, "paint_k", align="c", flatlight=True)
    for (x, y) in ((14, 348), (185, 348)): screw(p, x, y, on=Z_FACE, mat="steel")
    if worn_: worn(p, "wt_char", 203)
    return p


def value_face(p, surround, brand, sub, seed):
    """ValuTech and Premium Tech. share a shell (the game's two textures differ only in the display's surround)"""
    d = p.d
    face_body(p, "wt_char", r=18, seed=seed)
    tx_led(p, 184, 14)
    p.label(brand, 100, 10, "paint_w", align="c", font="57", auto_ink=False)
    face_knob(p, "vol", 40, 46, 15, "VOL - PWR")
    face_knob(p, "tune", 160, 46, 15, "TUNE")
    sur = Mask(p.W, p.H).rrect(14, 84, 172, 98, 8).get()
    d.slab(sur, 1.6, surround, bevel=1.4, polish=0.7, on=Z_FACE)
    display(p, "walkie", "lcd_light", 24, 93, 152, 44, lay_walkie(152), bezel="blackp")
    zs = Z_FACE + 1.6
    round_key(p, "chdn", 56, 162, 8, on=zs, icon="down")
    round_key(p, "mem", 100, 162, 6, on=zs, icon="M")
    round_key(p, "chup", 144, 162, 8, on=zs, icon="up")
    slot_grille(p, 100, 228, 74, 30, vertical=False)
    ptt_key(p, 30, 270, 140, 26, mat="wt_red")
    p.label(sub, 100, 308, "paint_c", align="c", auto_ink=False)
    p.label("HOLD M TO NAME", 100, 320, "paint_c", align="c", auto_ink=False)
    for (x, y) in ((14, 346), (185, 346)): screw(p, x, y, on=Z_FACE, mat="steel")
    return p


def valutech(worn_=True):
    p = Plate("walkie_valutech", WALKIE_W, WALKIE_H, seed=211, title="ValuTech Walkie Talkie")
    value_face(p, "wt_yellow", "VALUTECH", "2-WAY  -  50-200 MHZ", 212)
    if worn_: worn(p, "wt_char", 213)
    return p


def premium(worn_=True):
    p = Plate("walkie_premium", WALKIE_W, WALKIE_H, seed=221, title="Premium Tech. Walkie Talkie")
    value_face(p, "wt_red", "PREMIUM TECH.", "2-WAY  -  25-300 MHZ", 222)
    if worn_: worn(p, "wt_char", 223, grime=0.16, scuffs=0.06)
    return p


def tactical(worn_=True):
    """Tactical Walkie Talkie (Base.WalkieTalkie4): rubberised green-black, an oval grille over an amber LCD, six keys"""
    p = Plate("walkie_tactical", WALKIE_W, WALKIE_H, seed=231, title="Tactical Walkie Talkie")
    d = p.d
    face_body(p, "wt_tac", r=14, seed=232)
    tx_led(p, 100, 14)
    face_knob(p, "vol", 40, 46, 16, "VOL - PWR")
    face_knob(p, "tune", 160, 46, 14, "TUNE", ridges=24)
    slot_grille(p, 100, 104, 78, 18, vertical=False)
    display(p, "walkie", "lcd_amber", 22, 134, 156, 44, lay_walkie(156), bezel="blackp", lamp="#ffd88a")
    keypad(p, 22, 192, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None),
                        ("scan", "SCAN", None), ("mute", "MUTE", None), ("lamp", "LAMP", None)],
           kw=48, kh=16, gx=6, gy=6, mark="paint_r")
    ptt_key(p, 22, 242, 156, 26, mat="wt_ptt_grey")
    p.label("TACTICAL", 100, 278, "paint_c", align="c", font="57", auto_ink=False)
    p.label("HOLD MEM TO NAME", 100, 292, "paint_c", align="c", auto_ink=False)
    for k in range(3):
        d.well(Mask(p.W, p.H).rrect(26, 306 + k * 12, 148, 4, 2).get(), 1.0, None, bevel=0.6)    # grip ribs
    if worn_: worn(p, "wt_tac", 233, grime=0.28, scuffs=0.12)
    return p


def army(worn_=True):
    """US Army Walkie Talkie (Base.WalkieTalkie5): olive green, grooves down the left, a slatted grille, a yellow-green
    LCD, six keys, the red talk lamp"""
    p = Plate("walkie_army", WALKIE_W, WALKIE_H, seed=241, title="US Army Walkie Talkie")
    d = p.d
    face_body(p, "wt_army", r=12, seed=242)
    face_knob(p, "vol", 40, 46, 16, "VOL - PWR")
    face_knob(p, "tune", 160, 46, 14, "TUNE", ridges=24)
    p.label("US ARMY", 100, 40, "paint_c", align="c", font="57", auto_ink=False)
    for k in range(3):
        d.well(Mask(p.W, p.H).rrect(14 + k * 7, 84, 3, 46, 1).get(), 1.2, None, bevel=0.6)              # the grooves
    slot_grille(p, 112, 107, 68, 24, vertical=False, pitch=5, slot=3)
    display(p, "walkie", "lcd_yg", 20, 146, 160, 44, lay_walkie(160), bezel="blackp", lamp="#e2f59a")
    keypad(p, 20, 204, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None),
                        ("scan", "SCAN", None), ("mute", "MUTE", None), ("lamp", "LAMP", None)],
           kw=48, kh=16, gx=8, gy=6, mat="blackp")
    ptt_key(p, 20, 252, 160, 24, mat="blackp")
    tx_led(p, 92, 288)
    p.label("TX", 98, 286, "paint_c", auto_ink=False)
    data_plate(p, 24, 300, 152, 36, ["RADIO SET  -  TWO-WAY", "200 KHZ - 1000 MHZ", "RANGE 16 KM  -  HOLD MEM TO NAME"],
               on=Z_FACE, mat="blackp", ink="paint_c", rivets=True)
    if worn_:
        ol = WR.mat_mask(d, "wt_army")
        WR.grime(d, d.solid, amount=0.30, seed=243)
        WR.chips(d, WR.face(d, Z_FACE, ol), 0.004, seed=244, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=245, amount=0.12)
    return p


def makeshift(worn_=True):
    """Makeshift Walkie Talkie (Base.WalkieTalkieMakeShift): the game gives it the toy's shell, so it is a gutted toy:
    pots for knobs, a scrap of board with a two-line character LCD and three tact switches under duct tape, and a
    big microswitch taped on as the talk key"""
    p = Plate("walkie_makeshift", WALKIE_W, WALKIE_H, seed=251, title="Makeshift Walkie Talkie")
    d = p.d
    face_body(p, "wt_char", r=22, seed=252)
    PR.pot(p, "vol", 40, 46, 11)
    PR.pot(p, "tune", 160, 46, 11)
    d.text("VOL", 40, 64, "paint_w", align="c", flatlight=True)
    d.text("TUNE", 160, 64, "paint_w", align="c", flatlight=True)
    brd = Mask(p.W, p.H).rrect(16, 80, 168, 98, 2).get()
    d.slab(brd, 1.4, "pcb", bevel=0.8, polish=0.5, on=Z_FACE)
    d.grain_pebble(brd, 0.03, seed=253)
    zb = Z_FACE + 1.4
    display(p, "walkiechar", "char", 46, 90, 13 * 8 + 4, 26, lay_char(13), bezel="blackp")
    for i, (pid, lab) in enumerate((("chdn", "CH-"), ("mem", "MEM"), ("chup", "CH+"))):
        x = 54 + i * 40
        PR.tact(p, pid, x, 128, 12, 12, None)
        d.text(lab, x + 6, 144, "paint_w", align="c", flatlight=True)
    PR.resistor(p, 120, 166); PR.solder(p, 54, 166); PR.solder(p, 62, 166)
    PR.trace(p, ((54, 166), (62, 166), (62, 160), (112, 160)))
    tx_led(p, 150, 166, on=zb)
    for (x, y, w, h) in ((18, 76, 22, 106), (160, 76, 22, 106)):
        t = Mask(p.W, p.H).rect(x, y, w, h).get()
        d.slab(t, 0.5, "duct", bevel=0.4, polish=0.5, on="cur")
        for yy in range(y + 3, y + h, 9): d.dark[yy, x + 1:x + w - 1] += 0.04
    slot_grille(p, 100, 226, 58, 34, vertical=True)
    # the talk key: a big microswitch, taped down
    sw = Mask(p.W, p.H).rrect(56, 272, 88, 30, 2).get()
    d.slab(sw, 2.0, "steel", bevel=0.8, polish=0.8, on=Z_FACE)
    d.dome(100, 287, 16, 9, 2.4, "blackp", polish=0.6, on=Z_FACE + 2.0)
    for x in (44, 140):
        t = Mask(p.W, p.H).rect(x, 280, 16, 14).get()
        d.slab(t, 0.5, "duct", bevel=0.4, polish=0.5, on="cur")
    d.text("PTT", 100, 285, "paint_w", align="c", flatlight=True)
    p.hit("mic", 56, 272, 88, 30)
    lbl = Mask(p.W, p.H).rect(66, 314, 68, 14).get()
    d.slab(lbl, 0.5, "tape", bevel=0.4, polish=0.4, on=Z_FACE)
    d.text("HOLD MEM", 100, 317, "paint_b", align="c", flatlight=True)
    for (x, y) in ((14, 348), (185, 348)): screw(p, x, y, on=Z_FACE, mat="steel")
    if worn_: worn(p, "wt_char", 254, grime=0.30, scuffs=0.14)
    return p


MANPACK_W, MANPACK_H = 200, 280


def manpack(worn_=True):
    """US ARMY COMM. Manpack Radio (Base.ManPackRadio): the backpack set's control face: audio sockets, the cyan LCD (as
    the game's icon), VOL and FREQ knobs, four keys, the talk key"""
    p = Plate("walkie_manpack", MANPACK_W, MANPACK_H, seed=261, title="US ARMY COMM. Manpack Radio")
    d = p.d
    body = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, 6).get()
    d.slab(body, Z_FACE, "mp_olive", bevel=2.4, polish=0.35)
    d.grain_pebble(body, 0.04, seed=262)
    chrome_frame(d, 4, 4, p.W - 8, p.H - 8, Z_FACE - 0.4, t=1, mat="mp_olive", z=0.8)
    corner_screws(p, inset=9, mat="mp_olive")
    p.label("US ARMY COMM.", 18, 14, "paint_c", font="57", auto_ink=False)
    p.label("MANPACK RADIO SET", 18, 25, "paint_c", auto_ink=False)
    for x in (150, 174):
        d.torus(x, 20, 4.0, 8.0, 2.4, "steel", polish=0.9, on=Z_FACE)
        d.dome(x, 20, 4.0, 4.0, -1.5, "hole", polish=0.2, on=Z_FACE)
    p.label("AUDIO", 162, 32, "paint_c", align="c", auto_ink=False)
    display(p, "walkie", "lcd_cyan", 20, 46, 160, 44, lay_walkie(160), bezel="blackp")
    face_knob(p, "vol", 52, 124, 22, "VOL - PWR", ink="paint_c")
    face_knob(p, "tune", 148, 124, 22, "FREQ", ink="paint_c", ridges=36)
    keypad(p, 20, 166, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None), ("mute", "MUTE", None)],
           kw=74, kh=16, gx=12, gy=6, cols=2, mat="blackp")
    ptt_key(p, 20, 212, 160, 26, mat="rubber")
    tx_led(p, 30, 254)
    p.label("TX", 36, 252, "paint_c", auto_ink=False)
    p.label("RANGE 20 KM", 180, 252, "paint_c", align="r", auto_ink=False)
    if worn_:
        ol = WR.mat_mask(d, "mp_olive")
        WR.grime(d, d.solid, amount=0.32, seed=263)
        WR.chips(d, WR.face(d, Z_FACE, ol), 0.006, seed=264, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=265, amount=0.12)
    return p


# =================================================================================== the tabletop ham sets
HAM_W, HAM_H = 400, 172


def mic_jack(p, cx, cy, mat="chrome", tip="paint_r", label="MIC", ink="paint_k"):
    d = p.d
    d.torus(cx, cy, 2.5, 5.5, 2.2, mat, polish=1.0, on=Z_FACE)
    d.dome(cx, cy, 2.5, 2.5, 1.6, tip, polish=0.8, on=Z_FACE)
    if label: d.text(label, cx, cy + 8, ink, align="c", flatlight=True)


def ham_civ(worn_=True):
    """Premium Technologies Ham Radio (Base.HamRadio1, tiles appliances_com_01_0/1): a brushed silver box; the big
    black dial under its green arc, the red lamp, the round dotted speaker, green switches; a compact LCD sits
    between dial and speaker (the tile's set has none: it shows the channel, frequency and station)"""
    p = Plate("ham_civilian", HAM_W, HAM_H, seed=301, title="Premium Technologies Ham Radio")
    d = p.d
    face = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, 3).get()
    d.slab(face, Z_FACE, "ham_silver", bevel=2.4, polish=0.7)
    d.grain_brushed(face, 0.04, seed=302)
    chrome_frame(d, 3, 3, p.W - 6, p.H - 6, Z_FACE - 0.4, t=1, mat="ham_silver", z=0.7)
    corner_screws(p, inset=9)
    p.label("PREMIUM TECHNOLOGIES", 16, 12, "paint_k", font="57", auto_ink=False)
    p.label("TWO-WAY  -  10-500 MHZ", 16, 23, "paint_k", auto_ink=False)
    arc_dial(p, 68, 100, 34, 40)
    PR.radio_knob(p, 68, 100, 26, mat="blackp", skirt=1.4, ridges=40, pid="tune", label="DIAL", label_y=142, lab_mat="paint_k")
    d.dome(130, 42, 3.2, 3.2, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 130, 42, 3.0), "radioOn", "#ff3a2e")
    p.label("PWR", 130, 48, "paint_k", align="c", auto_ink=False)
    PR.radio_knob(p, 130, 84, 13, mat="blackp", pid="vol", label="VOL", label_y=101, lab_mat="paint_k")
    display(p, "walkie", "lcdgrey", 160, 30, 122, 44, lay_walkie(122), bezel="blackp")
    keypad(p, 160, 86, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None)], kw=38, kh=15, gx=4, mat="hamgrey")
    p.label("HOLD MEM TO NAME", 160, 106, "paint_k", auto_ink=False)
    toggle_key(p, "mic", 160, 124, 38, 13, "MIC")
    toggle_key(p, "mute", 202, 124, 38, 13, "MUTE")
    toggle_key(p, "scan", 244, 124, 38, 13, "SCAN")
    dot_grille(p, 342, 70, 32)
    PR.range_strip(p, 342, 122, w=66, mat="blackp", ink="#ecead8")
    mic_jack(p, 342, 144)
    if worn_:
        WR.grime(d, face, amount=0.18, seed=303)
        WR.scuffs(d, WR.mat_mask(d, "ham_silver"), 0.001, seed=304, amount=0.08)
    return p


def ham_army(worn_=True):
    """US ARMY COMM. Ham Radio (Base.HamRadio2, tiles appliances_com_01_8/9): an olive case round a grey panel; three
    small keys and the red lamp top left, the dial under its green arc, six memory keys, the dark display window,
    green switches, the red mic jack, a louvred speaker"""
    p = Plate("ham_army", HAM_W, HAM_H, seed=311, title="US ARMY COMM. Ham Radio")
    d = p.d
    case = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, 4).get()
    d.slab(case, Z_FACE + 1.0, "ham_olive", bevel=2.6, polish=0.4)
    d.grain_pebble(case, 0.04, seed=312)
    inset = Mask(p.W, p.H).rrect(10, 10, p.W - 20, p.H - 20, 2).get()
    d.slab(inset, Z_FACE, "ham_inset", bevel=0.8, polish=0.4, on=0.0)
    p.label("US ARMY COMM.", 20, 18, "paint_c", font="57", auto_ink=False)
    for i, (pid, ic) in enumerate((("chup", "up"), ("chdn", "down"), ("mem", None))):
        PR.radio_key(p, pid, 22 + i * 22, 32, 18, 12, None if ic else "M", mat="blackp", icon=ic, z=1.8)
    d.dome(98, 38, 3.0, 3.0, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 98, 38, 2.8), "micLive", "#ff3a2e")
    p.label("TX", 104, 36, "paint_c", auto_ink=False)
    arc_dial(p, 64, 106, 30, 36, labels=("0.2", "250", "500", "1000"))
    PR.radio_knob(p, 64, 106, 22, mat="blackp", ridges=40, pid="tune", label="FREQ", label_y=140)
    for i in range(6):
        PR.radio_key(p, f"p{i + 1}", 128 + (i % 3) * 18, 62 + (i // 3) * 18, 14, 13, str(i + 1), mat="blackp", z=1.6)
    p.label("MEM", 155, 100, "paint_c", align="c", auto_ink=False)
    PR.radio_knob(p, 146, 132, 12, mat="blackp", pid="vol", label=None)
    p.label("VOL", 164, 130, "paint_c", auto_ink=False)
    display(p, "walkie", "led", 196, 26, 124, 44, lay_walkie(124), bezel="blackp", lens=True)
    p.label("HOLD MEM TO NAME", 196, 78, "paint_c", auto_ink=False)
    toggle_key(p, "mic", 196, 94, 38, 13, "MIC", ink="paint_c")
    toggle_key(p, "mute", 239, 94, 38, 13, "MUTE", ink="paint_c")
    toggle_key(p, "scan", 282, 94, 38, 13, "SCAN", ink="paint_c")
    PR.range_strip(p, 258, 138, w=124, mat="blackp", ink="#ecead8")
    for k in range(9):
        d.well(Mask(p.W, p.H).rrect(338, 24 + k * 9, 44, 4, 2).get(), 1.6, "mesh", bevel=0.6)              # the speaker
    mic_jack(p, 360, 128, mat="steel", ink="paint_c")
    for (x, y) in ((5, 5), (p.W - 6, 5), (5, p.H - 6), (p.W - 6, p.H - 6)): screw(p, x, y, on=Z_FACE + 1.0, mat="ham_olive")
    if worn_:
        ol = WR.mat_mask(d, "ham_olive")
        WR.grime(d, d.solid, amount=0.30, seed=313)
        WR.chips(d, WR.face(d, Z_FACE + 1.0, ol), 0.006, seed=314, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=315, amount=0.12)
    return p


def ham_make(worn_=True, mic_live=False):
    """Makeshift Ham Radio (Base.HamRadioMakeShift, tiles appliances_com_01_56/57): the front of the wooden crate it is
    built into; the board carries the black display slot, the red lamp, the knobs and the big ringed speaker"""
    p = Plate("ham_makeshift", HAM_W, HAM_H, seed=321, title="Makeshift Ham Radio")
    d = p.d
    crate = Mask(p.W, p.H).rect(0, 0, p.W, p.H).get()
    d.slab(crate, Z_FACE + 1.4, "crate", bevel=1.4, polish=0.25)
    d.grain_wood(crate, 1.0, seed=322)
    board = Mask(p.W, p.H).rect(12, 12, p.W - 24, p.H - 24).get()
    d.slab(board, Z_FACE, "crate_face", bevel=0.8, polish=0.3, on=0.0)
    d.grain_wood(board, 0.6, seed=323)
    for (x, y) in ((6, 6), (p.W - 7, 6), (6, p.H - 7), (p.W - 7, p.H - 7)): screw(p, x, y, on=Z_FACE + 1.4, mat="steel")
    display(p, "hamchar", "char", 26, 26, 16 * 8 + 4, 26, lay_char(16), bezel="blackp")
    d.dome(176, 32, 3.0, 3.0, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 176, 32, 2.8), "radioOn", "#ff3a2e")
    for i, (pid, lab) in enumerate((("chdn", "CH-"), ("mem", "MEM"), ("chup", "CH+"))):
        x = 32 + i * 40
        PR.tact(p, pid, x, 70, 12, 12, None)
        d.text(lab, x + 6, 86, "paint_k", align="c", flatlight=True)
    PR.pot(p, "tune", 168, 76, 10)
    PR.pot(p, "vol", 204, 76, 10)
    d.text("TUNE", 168, 92, "paint_k", align="c", flatlight=True)
    d.text("VOL", 204, 92, "paint_k", align="c", flatlight=True)
    bat_toggle(p, 46, 126, mic_live, on=Z_FACE)          # up = TALK: a variant (micLive) flips it
    p.hit("mic", 38, 114, 16, 24)
    d.text("TALK", 62, 118, "paint_k", flatlight=True)
    d.text("LISTEN", 62, 130, "paint_k", flatlight=True)
    toggle_key(p, "mute", 112, 120, 30, 13, "MUTE", mat="blackp")
    tp = Mask(p.W, p.H).rect(156, 118, 70, 13).get()
    d.slab(tp, 0.5, "tape", bevel=0.4, polish=0.4, on=Z_FACE)
    d.text("HOLD MEM", 191, 122, "paint_b", align="c", flatlight=True)
    mic_jack(p, 236, 76, mat="steel", tip="blackp")
    dot_grille(p, 316, 86, 46, ring_mat="grille_ring")
    if worn_:
        WR.grime(d, d.solid, amount=0.26, seed=324)
    return p


# =================================================================================== the ham sets, narrow
# Small screens (director, Oct 25 2026, mockup zed_ham_narrow_v1, approved): where the radio tab cannot hold a 400-wide
# set at the plates' whole zoom, the same set's face rearranged into a walkie's width, in the same 220 panel, so a ham
# fits wherever a walkie does. Every control of the wide set is kept with the same hit ids. Full view keeps the wide set.
NARROW_W = 200


def ham_civ_n(worn_=True):
    """Premium Technologies Ham Radio, narrow: brushed silver; the PWR lamp by the maker's name, the grey LCD across,
    the big DIAL under its green arc with the round speaker beside it, VOL and the MIC socket under the speaker, the
    three grey keys, the three green switches, the RANGE plate"""
    p = Plate("ham_civilian_n", NARROW_W, 280, seed=331, title="Premium Technologies Ham Radio (narrow)")
    d = p.d
    face = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, 3).get()
    d.slab(face, Z_FACE, "ham_silver", bevel=2.4, polish=0.7)
    d.grain_brushed(face, 0.04, seed=332)
    chrome_frame(d, 3, 3, p.W - 6, p.H - 6, Z_FACE - 0.4, t=1, mat="ham_silver", z=0.7)
    corner_screws(p, inset=9)
    p.label("PREMIUM TECHNOLOGIES", 16, 12, "paint_k", font="57", auto_ink=False)
    p.label("TWO-WAY  -  10-500 MHZ", 16, 23, "paint_k", auto_ink=False)
    d.dome(176, 15, 3.2, 3.2, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 176, 15, 3.0), "radioOn", "#ff3a2e")
    p.label("PWR", 176, 21, "paint_k", align="c", auto_ink=False)
    display(p, "walkie", "lcdgrey", 18, 36, 164, 44, lay_walkie(164), bezel="blackp")
    arc_dial(p, 60, 132, 30, 35)
    PR.radio_knob(p, 60, 132, 22, mat="blackp", skirt=1.4, ridges=40, pid="tune", label="DIAL", label_y=168, lab_mat="paint_k")
    dot_grille(p, 150, 116, 26)
    PR.radio_knob(p, 136, 164, 11, mat="blackp", pid="vol", label="VOL", label_y=179, lab_mat="paint_k")
    mic_jack(p, 172, 164)
    keypad(p, 18, 192, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None)], kw=52, kh=15, gx=4, mat="hamgrey")
    p.label("HOLD MEM TO NAME", 100, 212, "paint_k", align="c", auto_ink=False)
    toggle_key(p, "mic", 18, 224, 52, 13, "MIC")
    toggle_key(p, "mute", 74, 224, 52, 13, "MUTE")
    toggle_key(p, "scan", 130, 224, 52, 13, "SCAN")
    PR.range_strip(p, 100, 260, w=80, mat="blackp", ink="#ecead8")
    if worn_:
        WR.grime(d, face, amount=0.18, seed=333)
        WR.scuffs(d, WR.mat_mask(d, "ham_silver"), 0.001, seed=334, amount=0.08)
    return p


def ham_army_n(worn_=True):
    """US ARMY COMM. Ham Radio, narrow: the olive case round its grey panel; the maker's name and the TX lamp, the red
    LED display, the FREQ dial under its green arc beside the six memory keys and VOL, the three small keys, the green
    switches, the RANGE strip with the MIC socket, the louvred speaker along the foot"""
    p = Plate("ham_army_n", NARROW_W, 300, seed=341, title="US ARMY COMM. Ham Radio (narrow)")
    d = p.d
    case = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, 4).get()
    d.slab(case, Z_FACE + 1.0, "ham_olive", bevel=2.6, polish=0.4)
    d.grain_pebble(case, 0.04, seed=342)
    inset = Mask(p.W, p.H).rrect(10, 10, p.W - 20, p.H - 20, 2).get()
    d.slab(inset, Z_FACE, "ham_inset", bevel=0.8, polish=0.4, on=0.0)
    p.label("US ARMY COMM.", 20, 18, "paint_c", font="57", auto_ink=False)
    d.dome(166, 21, 3.0, 3.0, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 166, 21, 2.8), "micLive", "#ff3a2e")
    p.label("TX", 172, 19, "paint_c", auto_ink=False)
    display(p, "walkie", "led", 22, 36, 156, 44, lay_walkie(156), bezel="blackp", lens=True)
    arc_dial(p, 62, 134, 28, 33, labels=("0.2", "250", "500", "1000"))
    PR.radio_knob(p, 62, 134, 20, mat="blackp", ridges=40, pid="tune", label="FREQ", label_y=168)
    for i in range(6):
        PR.radio_key(p, f"p{i + 1}", 122 + (i % 3) * 18, 98 + (i // 3) * 18, 14, 13, str(i + 1), mat="blackp", z=1.6)
    p.label("MEM", 149, 134, "paint_c", align="c", auto_ink=False)
    PR.radio_knob(p, 134, 158, 10, mat="blackp", pid="vol", label=None)
    p.label("VOL", 150, 156, "paint_c", auto_ink=False)
    for i, (pid, ic) in enumerate((("chup", "up"), ("chdn", "down"), ("mem", None))):
        PR.radio_key(p, pid, 22 + i * 22, 184, 18, 12, None if ic else "M", mat="blackp", icon=ic, z=1.8)
    p.label("HOLD MEM TO NAME", 92, 188, "paint_c", auto_ink=False)
    toggle_key(p, "mic", 22, 206, 48, 13, "MIC", ink="paint_c")
    toggle_key(p, "mute", 76, 206, 48, 13, "MUTE", ink="paint_c")
    toggle_key(p, "scan", 130, 206, 48, 13, "SCAN", ink="paint_c")
    PR.range_strip(p, 82, 244, w=116, mat="blackp", ink="#ecead8")
    mic_jack(p, 164, 241, mat="steel", ink="paint_c")
    for k in range(3):
        d.well(Mask(p.W, p.H).rrect(24, 260 + k * 9, 152, 4, 2).get(), 1.6, "mesh", bevel=0.6)              # the speaker
    for (x, y) in ((5, 5), (p.W - 6, 5), (5, p.H - 6), (p.W - 6, p.H - 6)): screw(p, x, y, on=Z_FACE + 1.0, mat="ham_olive")
    if worn_:
        ol = WR.mat_mask(d, "ham_olive")
        WR.grime(d, d.solid, amount=0.30, seed=343)
        WR.chips(d, WR.face(d, Z_FACE + 1.0, ol), 0.006, seed=344, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=345, amount=0.12)
    return p


def ham_make_n(worn_=True, mic_live=False):
    """Makeshift Ham Radio, narrow: the crate stood on end; on its board the character display and the red lamp, the
    three tact switches with the TUNE and VOL pots, the TALK / LISTEN toggle, MUTE, the taped HOLD MEM and the MIC
    socket, the big ringed speaker below"""
    p = Plate("ham_makeshift_n", NARROW_W, 290, seed=351, title="Makeshift Ham Radio (narrow)")
    d = p.d
    crate = Mask(p.W, p.H).rect(0, 0, p.W, p.H).get()
    d.slab(crate, Z_FACE + 1.4, "crate", bevel=1.4, polish=0.25)
    d.grain_wood(crate, 1.0, seed=352)
    board = Mask(p.W, p.H).rect(12, 12, p.W - 24, p.H - 24).get()
    d.slab(board, Z_FACE, "crate_face", bevel=0.8, polish=0.3, on=0.0)
    d.grain_wood(board, 0.6, seed=353)
    for (x, y) in ((6, 6), (p.W - 7, 6), (6, p.H - 7), (p.W - 7, p.H - 7)): screw(p, x, y, on=Z_FACE + 1.4, mat="steel")
    display(p, "hamchar", "char", 24, 26, 16 * 8 + 4, 26, lay_char(16), bezel="blackp")
    d.dome(172, 32, 3.0, 3.0, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 172, 32, 2.8), "radioOn", "#ff3a2e")
    for i, (pid, lab) in enumerate((("chdn", "CH-"), ("mem", "MEM"), ("chup", "CH+"))):
        x = 26 + i * 32
        PR.tact(p, pid, x, 66, 12, 12, None)
        d.text(lab, x + 6, 82, "paint_k", align="c", flatlight=True)
    PR.pot(p, "tune", 134, 72, 10)
    PR.pot(p, "vol", 168, 72, 10)
    d.text("TUNE", 134, 88, "paint_k", align="c", flatlight=True)
    d.text("VOL", 168, 88, "paint_k", align="c", flatlight=True)
    bat_toggle(p, 34, 116, mic_live, on=Z_FACE)          # up = TALK: a variant (micLive) flips it
    p.hit("mic", 26, 104, 16, 24)
    d.text("TALK", 48, 108, "paint_k", flatlight=True)
    d.text("LISTEN", 48, 120, "paint_k", flatlight=True)
    toggle_key(p, "mute", 92, 108, 30, 13, "MUTE", mat="blackp")
    mic_jack(p, 166, 114, mat="steel", tip="blackp")
    tp = Mask(p.W, p.H).rect(64, 138, 72, 13).get()
    d.slab(tp, 0.5, "tape", bevel=0.4, polish=0.4, on=Z_FACE)
    d.text("HOLD MEM", 100, 142, "paint_b", align="c", flatlight=True)
    dot_grille(p, 100, 212, 50, ring_mat="grille_ring")
    if worn_:
        WR.grime(d, d.solid, amount=0.26, seed=354)
    return p


# ------------------------------------------------------------------ preview states (the registry's, platesame's)
def reading(kind, on=True, freq="146.520", name="Sheriff dispatch", ch=2, batt=3, vol=4, mic_live=False, ac=False):
    """what the display shows (ZeD.TwoWay's reading in the game)"""
    if not on: return {}
    if kind == "toy": return {"big": f"{freq} MHZ"}
    if kind in ("walkiechar", "hamchar"):
        return {"l1": f"CH{ch:02d} {freq}"[:16], "l2": name.upper()}
    return {"chLabel": "CH", "ch": f"{ch:02d}", "big": freq, "line": name.upper(), "batLabel": "AC" if ac else "BAT",
            "batt": 0 if ac else batt, "volLabel": "VOL", "vol": vol, "tx": "TX OK" if mic_live else "MIC OFF"}


def state(kind, on=True, mic_live=False, range_=None, dark=False, lamp=False, **kw):
    return {"range": range_ if on else None, "power": on, "radioOn": on, "micLive": mic_live and on, "volF": kw.get("vol", 4) / 6,
            "tuneF": 0.4, "bandF": 0.35, "dark": dark, "lampLit": lamp, "display": reading(kind, on, mic_live=mic_live, **kw)}


# plate id -> (design, display kind, preview reading)
MODELS = {
    "walkie_toy": (toy, "toy", dict(freq="121.40")),
    "walkie_valutech": (valutech, "walkie", dict(freq="146.520", name="Farm", ch=1)),
    "walkie_premium": (premium, "walkie", dict(freq="162.400", name="Weather", ch=3)),
    "walkie_tactical": (tactical, "walkie", dict(freq="295.000", name="Sheriff dispatch", ch=2, mic_live=True)),
    "walkie_army": (army, "walkie", dict(freq="500.000", name="Base camp", ch=4)),
    "walkie_makeshift": (makeshift, "walkiechar", dict(freq="88.20", name="Bob", ch=1)),
    "walkie_manpack": (manpack, "walkie", dict(freq="245.600", name="Convoy", ch=5, mic_live=True)),
    "ham_civilian": (ham_civ, "walkie", dict(freq="146.520", name="Sheriff dispatch", ch=2, range_="RANGE 7 KM")),
    "ham_army": (ham_army, "walkie", dict(freq="245.600", name="Base camp", ch=4, mic_live=True, range_="RANGE 20 KM", ac=True)),
    "ham_makeshift": (ham_make, "hamchar", dict(freq="146.520", name="Farm", ch=1)),
    "ham_civilian_n": (ham_civ_n, "walkie", dict(freq="146.520", name="Sheriff dispatch", ch=2, range_="RANGE 7.5 KM")),
    "ham_army_n": (ham_army_n, "walkie", dict(freq="245.600", name="Base camp", ch=4, mic_live=True, range_="RANGE 20 KM", ac=True)),
    "ham_makeshift_n": (ham_make_n, "hamchar", dict(freq="146.520", name="Farm", ch=1)),
}
# a ham set's narrow face (the radio tab draws it where the wide one cannot fit)
NARROW = {"ham_civilian": "ham_civilian_n", "ham_army": "ham_army_n", "ham_makeshift": "ham_makeshift_n"}
