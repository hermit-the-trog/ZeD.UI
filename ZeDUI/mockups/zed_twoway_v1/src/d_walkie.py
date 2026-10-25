"""The two-way radios in the radio tab (mockup, Oct 25 2026): the walkie talkies and the ManPack as a panel the size of
the item card (220 wide), the three tabletop ham sets at the drawer's full width. Each face is matched to the game's
own model: the walkies to their model textures (media/textures/weapons/1handed/WalkieTalkie_*.png) and world tiles
(appliances_com_01_16..48), the ManPack to its icon, the ham sets to their placed tiles (appliances_com_01_0/8/56).

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


def display(p, kind, style, x, y, w, h, layout, bezel="blackp", lens=False):
    face = {"led": "ledglass", "char": "lcdlit"}.get(style, style)
    window_glass(p, x - 2, y - 2, w + 4, h + 3, face=face, bezel=bezel, depth=1.6,
                 on=Z_FACE, r=1, bezel_t=2, lens=lens)
    col, ghost = STYLE[style]
    p.part("radioDisplay", kind=kind, style=style, x=x, y=y, w=w, h=h, color=col, ghost=ghost, fields=layout)


# ------------------------------------------------------------------ walkie parts
def body_shape(p, x, y, w, h, mat, r=12, grain="pebble", seed=1):
    d = p.d
    m = Mask(p.W, p.H).rrect(x, y, w, h, r).get()
    d.slab(m, Z_FACE, mat, bevel=3.0, polish=0.4)
    if grain == "pebble": d.grain_pebble(m, 0.04, seed=seed)
    return m


def top_knob(p, pid, cx, top, w, h, mat="blackp", label=None):
    """a knob on the radio's top, seen from the front: a knurled cylinder standing on the top edge; its setting shows
    on the display (CH for the channel knob, the VOL bars for the volume)"""
    d = p.d
    x0 = int(cx - w // 2)
    d.cyl(x0, top, w, h, 3.6, mat, axis="v", polish=0.6, on=Z_FACE - 1.0)
    for x in range(x0 + 1, x0 + w - 1, 2):
        d.dark[top + 2:top + h, x] += 0.18
    d.cyl(x0 + 1, top - 2, w - 2, 3, 2.6, mat, axis="h", polish=0.9, on=Z_FACE + 0.6)      # the cap's rim
    p.hit(pid, x0 - 2, top - 3, w + 4, h + 4, kind="turn")


def antenna(p, cx, top, base_y, w=8, mat="rubber"):
    d = p.d
    d.cyl(int(cx - w // 2), top + 3, w, base_y - top - 3, 3.2, mat, axis="v", polish=0.35, on=Z_FACE - 1.0)
    d.dome(cx, top + 4, w / 2, 3.5, 3.2, mat, polish=0.35, on=Z_FACE - 1.0)
    for y in range(top + 10, base_y - 4, 6):
        d.dark[y, int(cx - w // 2) + 1:int(cx + w // 2) - 1] += 0.2
    d.cyl(int(cx - w // 2 - 2), base_y - 5, w + 4, 6, 3.4, "chrome", axis="v", polish=1.0, on=Z_FACE - 0.6)


def side_ptt(p, x, y, w, h, mat="wt_red", ridges=True):
    """the push-to-talk bar on the left side: MIC (click latches the mic live, again to mute)"""
    d = p.d
    m = Mask(p.W, p.H).rrect(x, y, w, h, 2).get()
    d.slab(m, 3.0, mat, bevel=1.4, polish=0.55, on=Z_FACE - 1.4)
    if ridges:
        for yy in range(y + 4, y + h - 3, 3): d.dark[yy, x + 1:x + w - 1] += 0.22
    p.hit("mic", x - 2, y, w + 4, h)


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


WALKIE_W, WALKIE_H = 220, 330


# =================================================================================== the walkies
def toy(worn_=True):
    """Toys-R-Mine Walkie Talkie (Base.WalkieTalkie1): the toy. Dark grey shell, a big slotted grille, a red talk bar,
    no screen: the frequency turns on a drum behind a slot. No memory channels."""
    p = Plate("walkie_toy", WALKIE_W, WALKIE_H, seed=201, title="Toys-R-Mine Walkie Talkie")
    d = p.d
    bx, by, bw, bh = 46, 66, 128, 248
    antenna(p, 146, 4, by + 2, w=10)
    top_knob(p, "vol", 78, by - 14, 22, 16)
    top_knob(p, "tune", 108, by - 12, 16, 14)
    body_shape(p, bx, by, bw, bh, "wt_char", r=16, seed=202)
    side_ptt(p, bx - 7, by + 70, 9, 64)
    p.label("TALK", bx + 4, by + 140, "paint_w", font="35", auto_ink=False)
    # the tuning slot and its drum
    display(p, "toy", "drum", bx + 24, by + 22, 80, 17, lay_drum(80), bezel="blackp")
    p.label("TUNE", bx + 64, by + 44, "paint_c", align="c", auto_ink=False)
    tx_led(p, bx + 112, by + 14)
    slot_grille(p, bx + 64, by + 108, 38, 46, vertical=True)
    # the sticker: the brand in toy colours
    st = Mask(p.W, p.H).rrect(bx + 14, by + 172, bw - 28, 36, 4).get()
    d.slab(st, 0.3, "enamel_white", bevel=0.6, polish=0.6, on=Z_FACE)
    for i, (ch, col) in enumerate(zip("TOYS-R-MINE", ("paint_r", "paint_b", "paint_y", "paint_g", "paint_k", "paint_r", "paint_k",
                                                      "paint_b", "paint_y", "paint_g", "paint_r"))):
        d.text(ch, bx + 22 + i * 8, by + 178, col, font="57", flatlight=True)
    d.text("2-WAY", bx + 64, by + 192, "paint_k", align="c", font="57", flatlight=True)
    p.label("AGES 8 AND UP", bx + 64, by + 222, "paint_c", align="c", auto_ink=False)
    for (x, y) in ((bx + 10, by + bh - 12), (bx + bw - 11, by + bh - 12)): screw(p, x, y, on=Z_FACE, mat="steel")
    if worn_: worn(p, "wt_char", 203)
    return p


def value_body(p, surround, brand, sub, seed):
    """ValuTech and Premium Tech. share a shell (the game's two textures differ only in the display's surround)"""
    d = p.d
    bx, by, bw, bh = 40, 64, 140, 256
    antenna(p, 152, 2, by + 2, w=10)
    top_knob(p, "vol", 74, by - 14, 22, 16)
    top_knob(p, "tune", 104, by - 14, 22, 16)
    body_shape(p, bx, by, bw, bh, "wt_char", r=14, seed=seed)
    side_ptt(p, bx - 7, by + 76, 9, 70)
    p.label("PTT", bx + 4, by + 150, "paint_w", font="35", auto_ink=False)
    tx_led(p, bx + 122, by + 12)
    p.label(brand, bx + 8, by + 9, "paint_w", font="57", auto_ink=False)
    # the coloured surround: the LCD, then the channel keys and MEM
    sur = Mask(p.W, p.H).rrect(bx + 10, by + 22, bw - 20, 92, 6).get()
    d.slab(sur, 1.6, surround, bevel=1.4, polish=0.7, on=Z_FACE)
    display(p, "walkie", "lcd_light", bx + 18, by + 30, bw - 36, 44, lay_walkie(bw - 36), bezel="blackp")
    zs = Z_FACE + 1.6
    round_key(p, "chdn", bx + 34, by + 94, 7, on=zs, icon="down")
    round_key(p, "mem", bx + 70, by + 94, 5, on=zs, icon="M")
    round_key(p, "chup", bx + 106, by + 94, 7, on=zs, icon="up")
    slot_grille(p, bx + 70, by + 160, 44, 26, vertical=False)
    p.label(sub, bx + 70, by + 200, "paint_c", align="c", auto_ink=False)
    p.label("HOLD M TO NAME", bx + 70, by + 214, "paint_c", align="c", auto_ink=False)
    for (x, y) in ((bx + 10, by + bh - 12), (bx + bw - 11, by + bh - 12)): screw(p, x, y, on=Z_FACE, mat="steel")
    return p


def valutech(worn_=True):
    p = Plate("walkie_valutech", WALKIE_W, WALKIE_H, seed=211, title="ValuTech Walkie Talkie")
    value_body(p, "wt_yellow", "VALUTECH", "2-WAY  -  50-200 MHz", 212)
    if worn_: worn(p, "wt_char", 213)
    return p


def premium(worn_=True):
    p = Plate("walkie_premium", WALKIE_W, WALKIE_H, seed=221, title="Premium Tech. Walkie Talkie")
    value_body(p, "wt_red", "PREMIUM TECH.", "2-WAY  -  25-300 MHz", 222)
    if worn_: worn(p, "wt_char", 223, grime=0.16, scuffs=0.06)
    return p


def tactical(worn_=True):
    """Tactical Walkie Talkie (Base.WalkieTalkie4): rubberised green-black, an oval grille over an amber LCD, six keys"""
    p = Plate("walkie_tactical", WALKIE_W, WALKIE_H, seed=231, title="Tactical Walkie Talkie")
    d = p.d
    bx, by, bw, bh = 38, 60, 144, 262
    antenna(p, 156, 0, by + 2, w=10)
    top_knob(p, "vol", 70, by - 16, 24, 18)
    top_knob(p, "tune", 102, by - 14, 20, 16)
    body_shape(p, bx, by, bw, bh, "wt_tac", r=12, seed=232)
    side_ptt(p, bx - 7, by + 84, 9, 74, mat="wt_ptt_grey")
    tx_led(p, bx + 126, by + 12)
    slot_grille(p, bx + 72, by + 34, 52, 16, vertical=False)
    display(p, "walkie", "lcd_amber", bx + 16, by + 62, bw - 32, 44, lay_walkie(bw - 32), bezel="blackp")
    keypad(p, bx + 17, by + 120, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None),
                                  ("scan", "SCAN", None), ("mute", "MUTE", None), ("lamp", "LAMP", None)],
           kw=32, kh=16, gx=7, gy=7, mark="paint_r")
    p.label("TACTICAL", bx + 72, by + 176, "paint_c", align="c", font="57", auto_ink=False)
    p.label("PTT  -  HOLD MEM TO NAME", bx + 72, by + 190, "paint_c", align="c", auto_ink=False)
    for k in range(3):
        d.well(Mask(p.W, p.H).rrect(bx + 20, by + 206 + k * 12, bw - 40, 4, 2).get(), 1.0, None, bevel=0.6)    # grip ribs
    if worn_: worn(p, "wt_tac", 233, grime=0.28, scuffs=0.12)
    return p


def army(worn_=True):
    """US Army Walkie Talkie (Base.WalkieTalkie5): olive green, grooves down the left, a slatted grille, a yellow-green
    LCD, six keys, the red talk lamp low on the face"""
    p = Plate("walkie_army", WALKIE_W, WALKIE_H, seed=241, title="US Army Walkie Talkie")
    d = p.d
    bx, by, bw, bh = 36, 58, 148, 266
    antenna(p, 160, 0, by + 2, w=11, mat="blackp")
    top_knob(p, "vol", 70, by - 16, 26, 18)
    top_knob(p, "tune", 104, by - 14, 20, 16)
    body_shape(p, bx, by, bw, bh, "wt_army", r=10, seed=242)
    side_ptt(p, bx - 7, by + 84, 9, 76, mat="blackp")
    for k in range(3):
        d.well(Mask(p.W, p.H).rrect(bx + 10 + k * 7, by + 18, 3, 50, 1).get(), 1.2, None, bevel=0.6)          # the grooves
    slot_grille(p, bx + 42 + (bw - 60) / 2, by + 34, (bw - 56) / 2, 19, vertical=False, pitch=5, slot=3)           # the grille
    p.label("US ARMY", bx + 42 + (bw - 60) // 2, by + 60, "paint_c", align="c", font="57", auto_ink=False)
    display(p, "walkie", "lcd_yg", bx + 16, by + 76, bw - 32, 44, lay_walkie(bw - 32), bezel="blackp")
    keypad(p, bx + 18, by + 134, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None),
                                  ("scan", "SCAN", None), ("mute", "MUTE", None), ("lamp", "LAMP", None)],
           kw=32, kh=16, gx=8, gy=7, mat="blackp")
    p.label("HOLD MEM TO NAME", bx + bw // 2, by + 182, "paint_c", align="c", auto_ink=False)
    tx_led(p, bx + bw // 2, by + 200)
    p.label("TX", bx + bw // 2 + 6, by + 198, "paint_c", auto_ink=False)
    dp = data_plate(p, bx + 22, by + 214, bw - 44, 34, ["RADIO SET  -  TWO-WAY", "200 KHZ - 1000 MHZ", "RANGE 16 KM"], on=Z_FACE,
                    mat="blackp", ink="paint_c", rivets=True)
    if worn_:
        ol = WR.mat_mask(d, "wt_army")
        WR.grime(d, d.solid, amount=0.30, seed=243)
        WR.chips(d, WR.face(d, Z_FACE, ol), 0.004, seed=244, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=245, amount=0.12)
    return p


def makeshift(worn_=True):
    """Makeshift Walkie Talkie (Base.WalkieTalkieMakeShift): the game gives it the toy's shell, so it is a gutted toy:
    the slot and sticker gone under duct tape, a two-line character LCD and three tact switches on a scrap of board,
    the talk bar a microswitch lever taped to the side"""
    p = Plate("walkie_makeshift", WALKIE_W, WALKIE_H, seed=251, title="Makeshift Walkie Talkie")
    d = p.d
    bx, by, bw, bh = 46, 66, 128, 248
    antenna(p, 146, 4, by + 2, w=10)
    # a pot standing in for the volume knob, a trimmer for the tuning
    top_knob(p, "vol", 78, by - 14, 22, 16)
    top_knob(p, "tune", 108, by - 12, 16, 14, mat="steel")
    body_shape(p, bx, by, bw, bh, "wt_char", r=16, seed=252)
    slot_grille(p, bx + 64, by + 160, 38, 40, vertical=True)
    # the board, taped on
    brd = Mask(p.W, p.H).rrect(bx + 10, by + 18, bw - 20, 92, 2).get()
    d.slab(brd, 1.4, "pcb", bevel=0.8, polish=0.5, on=Z_FACE)
    d.grain_pebble(brd, 0.03, seed=253)
    zb = Z_FACE + 1.4
    display(p, "walkiechar", "char", bx + 20, by + 26, 11 * 8 + 4, 26, lay_char(11), bezel="blackp")
    for i, (pid, lab) in enumerate((("chdn", "CH-"), ("mem", "MEM"), ("chup", "CH+"))):
        x = bx + 22 + i * 30
        PR.tact(p, pid, x, by + 66, 12, 12, None)
        d.text(lab, x + 6, by + 82, "paint_w", align="c", flatlight=True)
    PR.resistor(p, bx + 84, by + 98); PR.solder(p, bx + 22, by + 99); PR.solder(p, bx + 30, by + 99)
    PR.trace(p, ((bx + 22, by + 99), (bx + 30, by + 99), (bx + 30, by + 92), (bx + 78, by + 92)))
    tx_led(p, bx + 104, by + 99, on=zb)
    # duct tape: two strips over the board's ends, one over the old slot, one holding the lever
    for (x, y, w, h) in ((bx + 4, by + 14, 20, 100), (bx + bw - 24, by + 14, 20, 100), (bx - 10, by + 96, 26, 22)):
        t = Mask(p.W, p.H).rect(x, y, w, h).get()
        d.slab(t, 0.5, "duct", bevel=0.4, polish=0.5, on="cur")
        for yy in range(y + 3, y + h, 9): d.dark[yy, x + 1:x + w - 1] += 0.04
    lev = Mask(p.W, p.H).poly([(bx - 8, by + 70), (bx - 3, by + 70), (bx - 1, by + 150), (bx - 7, by + 150)]).get()
    d.slab(lev, 2.4, "steel", bevel=1.0, polish=0.9, on=Z_FACE - 1.4)
    p.hit("mic", bx - 10, by + 70, 12, 80)
    # marker on the tape
    d.text("PTT", bx - 3, by + 103, "paint_k", align="c", flatlight=True)
    lbl = Mask(p.W, p.H).rect(bx + 30, by + 210, 68, 14).get()
    d.slab(lbl, 0.5, "tape", bevel=0.4, polish=0.4, on=Z_FACE)
    d.text("HOLD MEM", bx + 64, by + 213, "paint_b", align="c", flatlight=True)
    for (x, y) in ((bx + 10, by + bh - 12), (bx + bw - 11, by + bh - 12)): screw(p, x, y, on=Z_FACE, mat="steel")
    if worn_: worn(p, "wt_char", 254, grime=0.30, scuffs=0.14)
    return p


def manpack(worn_=True):
    """US ARMY COMM. Manpack Radio (Base.ManPackRadio): the control face of the backpack set: whip antenna and audio
    sockets on top, the big knobs, the cyan LCD (as the game's icon), four keys, and the handset on its curly cord;
    the handset's bar is the talk switch"""
    p = Plate("walkie_manpack", WALKIE_W, WALKIE_H, seed=261, title="US ARMY COMM. Manpack Radio")
    d = p.d
    bx, by, bw, bh = 10, 56, 160, 264
    # whip antenna on its base, top left
    d.cyl(26, 0, 6, by - 4, 3.0, "blackp", axis="v", polish=0.4, on=Z_FACE - 1.0)
    d.cyl(20, by - 14, 18, 14, 4.0, "steel", axis="v", polish=0.9, on=Z_FACE - 0.8)
    body = Mask(p.W, p.H).rrect(bx, by, bw, bh, 6).get()
    d.slab(body, Z_FACE, "mp_olive", bevel=2.4, polish=0.35)
    d.grain_pebble(body, 0.04, seed=262)
    chrome_frame(d, bx + 4, by + 4, bw - 8, bh - 8, Z_FACE - 0.4, t=1, mat="mp_olive", z=0.8)
    for (x, y) in ((bx + 9, by + 9), (bx + bw - 10, by + 9), (bx + 9, by + bh - 10), (bx + bw - 10, by + bh - 10)):
        screw(p, x, y, on=Z_FACE, mat="mp_olive")
    p.label("US ARMY COMM.", bx + 18, by + 16, "paint_c", font="57", auto_ink=False)
    p.label("MANPACK RADIO SET", bx + 18, by + 27, "paint_c", auto_ink=False)
    # the two audio sockets
    for i, x in enumerate((bx + 118, bx + 142)):
        d.torus(x, by + 20, 4.0, 8.0, 2.4, "steel", polish=0.9, on=Z_FACE)
        d.dome(x, by + 20, 4.0, 4.0, -1.5, "hole", polish=0.2, on=Z_FACE)
    p.label("AUDIO", bx + 130, by + 32, "paint_c", align="c", auto_ink=False)
    display(p, "walkie", "lcd_cyan", bx + 18, by + 46, bw - 36, 44, lay_walkie(bw - 36), bezel="blackp")
    PR.radio_knob(p, bx + 40, by + 132, 22, mat="blackp", pid="vol", label="VOL - PWR", label_y=by + 160)
    PR.radio_knob(p, bx + 118, by + 132, 22, mat="blackp", ridges=36, pid="tune", label="FREQ", label_y=by + 160)
    keypad(p, bx + 18, by + 178, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None), ("mute", "MUTE", None)],
           kw=56, kh=16, gx=12, gy=7, cols=2, mat="blackp")
    tx_led(p, bx + 30, by + 230)
    p.label("TX", bx + 36, by + 228, "paint_c", auto_ink=False)
    p.label("RANGE 20 KM", bx + bw - 18, by + 228, "paint_c", align="r", auto_ink=False)
    # the handset hanging on the right, on its curly cord from the near socket
    hs_x, hs_y = 182, 120
    for k in range(12):
        d.torus(196 + (k % 2), 70 + k * 4, 2.0, 4.0, 1.4, "cord", polish=0.5, on=Z_FACE)
    hs = Mask(p.W, p.H).rrect(hs_x, hs_y, 28, 150, 10).get()
    d.slab(hs, 4.6, "blackp", bevel=2.6, polish=0.5, on=0.0)
    d.dome(hs_x + 14, hs_y + 14, 13, 13, 5.4, "blackp", polish=0.5, on=0.0)
    d.dome(hs_x + 14, hs_y + 136, 13, 13, 5.4, "blackp", polish=0.5, on=0.0)
    for k in range(4):
        d.well(disc(d, hs_x + 10 + (k % 2) * 8, hs_y + 10 + (k // 2) * 8, 1.6), 1.0, "hole", bevel=0.5)
    bar = Mask(p.W, p.H).rrect(hs_x - 4, hs_y + 56, 8, 36, 2).get()
    d.slab(bar, 5.4, "rubber", bevel=1.2, polish=0.5, on=0.0)
    p.hit("mic", hs_x - 6, hs_y + 50, 14, 48)
    d.text("PTT", hs_x + 14, hs_y + 98, "paint_c", align="c", flatlight=True)
    if worn_:
        ol = WR.mat_mask(d, "mp_olive")
        WR.grime(d, d.solid, amount=0.32, seed=263)
        WR.chips(d, WR.face(d, Z_FACE, ol), 0.006, seed=264, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=265, amount=0.12)
    return p


# =================================================================================== the tabletop ham sets
HAM_W, HAM_H = 400, 172


def desk_mic(p, x, base_mat="blackp", lamp=True, ptt=True):
    """the desk microphone beside the set (the tiles put it there): capsule, stem, base; the bar on the stem is the
    talk switch (MIC), the lamp in the base lights while the mic is live"""
    d = p.d
    cx = x + 30
    d.slab(Mask(p.W, p.H).ellipse(cx, HAM_H - 14, 30, 10).get(), 3.6, base_mat, bevel=3.0, polish=0.6, on=0.0)
    d.cyl(cx - 4, 64, 8, HAM_H - 80, 3.0, "chrome", axis="v", polish=1.0, on=0.4)
    cap = Mask(p.W, p.H).rrect(cx - 15, 12, 30, 52, 12).get()
    d.slab(cap, 5.0, "chrome", bevel=4.0, polish=1.0, on=0.0)
    for y in range(20, 58, 4): d.well(rbox(d, cx - 11, y, 22, 2) & cap, 1.2, "mesh", bevel=0.5)
    if ptt:
        bar = Mask(p.W, p.H).rrect(cx - 7, 96, 14, 30, 3).get()
        d.slab(bar, 4.2, "blackp", bevel=1.6, polish=0.5, on=0.8)
        p.hit("mic", cx - 9, 94, 18, 34)
        d.text("PTT", cx, 128, "paint_w", align="c", flatlight=True)
    if lamp:
        d.dome(cx + 16, HAM_H - 16, 2.6, 2.2, 1.0, "jewel_red_off", polish=0.9, on=3.6)
        p.lamp(disc(d, cx + 16, HAM_H - 16, 2.2), "micLive", "#ff3a2e")
    return cx


def mic_cord(p, x0, y0, x1, y1, n=None):
    """the curly cord, a tight coil drooping between the jack and the mic's base"""
    d = p.d
    n = n or int(math.hypot(x1 - x0, y1 - y0) / 2.4)
    for k in range(n + 1):
        t = k / n
        x = x0 + (x1 - x0) * t; y = y0 + (y1 - y0) * t + math.sin(t * math.pi) * 8
        d.torus(x, y, 0.8, 2.6, 1.2, "cord", polish=0.5, on=Z_FACE - 2.0 if k else Z_FACE)


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


def ham_civ(worn_=True):
    """Premium Technologies Ham Radio (Base.HamRadio1, tiles appliances_com_01_0/1): a brushed silver box; the big
    black dial under its green arc, the red lamp, the round dotted speaker, two green switches; a compact LCD sits
    between dial and speaker (the tile's set has none: it shows the channel, frequency and station)"""
    p = Plate("ham_civilian", HAM_W, HAM_H, seed=301, title="Premium Technologies Ham Radio")
    d = p.d
    fw = 318
    face = Mask(p.W, p.H).rrect(0, 4, fw, HAM_H - 8, 3).get()
    d.slab(face, Z_FACE, "ham_silver", bevel=2.4, polish=0.7)
    d.grain_brushed(face, 0.04, seed=302)
    chrome_frame(d, 3, 7, fw - 6, HAM_H - 14, Z_FACE - 0.4, t=1, mat="ham_silver", z=0.7)
    p.label("PREMIUM TECHNOLOGIES", 12, 14, "paint_k", font="57", auto_ink=False)
    p.label("TWO-WAY  -  10-500 MHZ", 12, 25, "paint_k", auto_ink=False)
    arc_dial(p, 62, 96, 34, 40)
    PR.radio_knob(p, 62, 96, 26, mat="blackp", skirt=1.4, ridges=40, pid="tune", label="DIAL", label_y=136, lab_mat="paint_k")
    d.dome(116, 46, 3.2, 3.2, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 116, 46, 3.0), "radioOn", "#ff3a2e")
    p.label("PWR", 116, 52, "paint_k", align="c", auto_ink=False)
    PR.radio_knob(p, 116, 82, 12, mat="blackp", pid="vol", label="VOL", label_y=98, lab_mat="paint_k")
    display(p, "walkie", "lcdgrey", 140, 34, 108, 44, lay_walkie(108), bezel="blackp")
    keypad(p, 140, 90, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None)], kw=32, kh=15, gx=6, mat="hamgrey")
    p.label("HOLD MEM TO NAME", 140, 110, "paint_k", auto_ink=False)
    dot_grille(p, 284, 62, 26)
    toggle_key(p, "mute", 140, 128, 30, 13, "MUTE")
    toggle_key(p, "scan", 178, 128, 30, 13, "SCAN")
    # the mic jack and its curly cord to the desk mic
    d.torus(232, 136, 2.5, 5.5, 2.2, "chrome", polish=1.0, on=Z_FACE)
    d.dome(232, 136, 2.5, 2.5, 1.6, "paint_r", polish=0.8, on=Z_FACE)
    for (x, y) in ((9, 13), (fw - 10, 13), (9, HAM_H - 14), (fw - 10, HAM_H - 14)): screw(p, x, y, on=Z_FACE, mat="steel")
    PR.range_strip(p, 284, 106, w=56, mat="blackp", ink="#ecead8")
    mic_cord(p, 232, 136, 350, HAM_H - 22)
    desk_mic(p, 330)
    if worn_:
        WR.grime(d, face, amount=0.18, seed=303)
        WR.scuffs(d, WR.mat_mask(d, "ham_silver"), 0.001, seed=304, amount=0.08)
    return p


def ham_army(worn_=True):
    """US ARMY COMM. Ham Radio (Base.HamRadio2, tiles appliances_com_01_8/9): an olive case round a grey panel; three
    small keys and the red lamp top left, the dial under its green arc, six memory keys, the black display window,
    two green switches and the red mic jack"""
    p = Plate("ham_army", HAM_W, HAM_H, seed=311, title="US ARMY COMM. Ham Radio")
    d = p.d
    fw = 318
    case = Mask(p.W, p.H).rrect(0, 4, fw, HAM_H - 8, 4).get()
    d.slab(case, Z_FACE + 1.0, "ham_olive", bevel=2.6, polish=0.4)
    d.grain_pebble(case, 0.04, seed=312)
    inset = Mask(p.W, p.H).rrect(10, 14, fw - 20, HAM_H - 28, 2).get()
    d.slab(inset, Z_FACE, "ham_inset", bevel=0.8, polish=0.4, on=0.0)
    p.label("US ARMY COMM.", 20, 22, "paint_c", font="57", auto_ink=False)
    for i, (pid, ic) in enumerate((("chup", "up"), ("chdn", "down"), ("mem", None))):
        x = 22 + i * 22
        PR.radio_key(p, pid, x, 34, 18, 12, None if ic else "M", mat="blackp", icon=ic, z=1.8)
    d.dome(98, 40, 3.0, 3.0, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 98, 40, 2.8), "micLive", "#ff3a2e")
    p.label("TX", 104, 38, "paint_c", auto_ink=False)
    arc_dial(p, 62, 104, 30, 36, labels=("0.2", "250", "500", "1000"))
    PR.radio_knob(p, 62, 104, 22, mat="blackp", ridges=40, pid="tune", label="FREQ", label_y=136)
    # six memory keys, straight to a channel
    for i in range(6):
        x = 124 + (i % 3) * 18; y = 70 + (i // 3) * 18
        PR.radio_key(p, f"p{i + 1}", x, y, 14, 13, str(i + 1), mat="blackp", z=1.6)
    p.label("MEM", 151, 108, "paint_c", align="c", auto_ink=False)
    PR.radio_knob(p, 151, 136, 11, mat="blackp", pid="vol", label=None)
    p.label("VOL", 168, 134, "paint_c", auto_ink=False)
    display(p, "walkie", "led", 192, 30, 110, 44, lay_walkie(110), bezel="blackp", lens=True)
    p.label("HOLD MEM TO NAME", 192, 82, "paint_c", auto_ink=False)
    toggle_key(p, "mute", 194, 100, 28, 13, "MUTE", ink="paint_c")
    toggle_key(p, "scan", 230, 100, 28, 13, "SCAN", ink="paint_c")
    d.torus(284, 108, 2.5, 5.5, 2.2, "steel", polish=1.0, on=Z_FACE)
    d.dome(284, 108, 2.5, 2.5, 1.6, "paint_r", polish=0.8, on=Z_FACE)
    PR.range_strip(p, 248, 136, w=108, mat="blackp", ink="#ecead8")
    for (x, y) in ((6, 9), (fw - 7, 9), (6, HAM_H - 10), (fw - 7, HAM_H - 10)): screw(p, x, y, on=Z_FACE + 1.0, mat="ham_olive")
    mic_cord(p, 284, 108, 350, HAM_H - 22)
    desk_mic(p, 330, base_mat="ham_olive")
    if worn_:
        ol = WR.mat_mask(d, "ham_olive")
        WR.grime(d, d.solid, amount=0.30, seed=313)
        WR.chips(d, WR.face(d, Z_FACE + 1.0, ol), 0.006, seed=314, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=315, amount=0.12)
    return p


def ham_make(worn_=True, mic_live=False):
    """Makeshift Ham Radio (Base.HamRadioMakeShift, tiles appliances_com_01_56/57): built into a wooden crate; the
    front board carries the black display slot, the red lamp, a small knob and the big ringed speaker; antenna rods
    and wires stand up out of the open top"""
    p = Plate("ham_makeshift", HAM_W, HAM_H, seed=321, title="Makeshift Ham Radio")
    d = p.d
    fw = 318
    # what stands out of the crate's open top: two rods, a loop of wire
    for (x, h) in ((70, 34), (226, 26)):
        d.cyl(x, 2, 4, h, 2.6, "steel", axis="v", polish=0.9, on=0.0)
    wire = Mask(p.W, p.H).line([(110, 26), (126, 8), (150, 6), (172, 14), (186, 26)], 2.0).get(0.45)
    d.slab(wire, 2.0, "paint_b", bevel=1.0, polish=0.6, on=0.0)
    crate = Mask(p.W, p.H).rect(0, 24, fw, HAM_H - 28).get()
    d.slab(crate, Z_FACE + 1.4, "crate", bevel=1.4, polish=0.25)
    d.grain_wood(crate, 1.0, seed=322)
    board = Mask(p.W, p.H).rect(12, 36, fw - 24, HAM_H - 52).get()
    d.slab(board, Z_FACE, "crate_face", bevel=0.8, polish=0.3, on=0.0)
    d.grain_wood(board, 0.6, seed=323)
    for (x, y) in ((6, 30), (fw - 7, 30), (6, HAM_H - 10), (fw - 7, HAM_H - 10)): screw(p, x, y, on=Z_FACE + 1.4, mat="steel")
    display(p, "hamchar", "char", 24, 48, 16 * 8 + 4, 26, lay_char(16), bezel="blackp")
    d.dome(170, 54, 3.0, 3.0, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 170, 54, 2.8), "radioOn", "#ff3a2e")
    PR.pot(p, "vol", 184, 92, 9)
    PR.pot(p, "tune", 152, 92, 9)
    d.text("TUNE", 152, 106, "paint_k", align="c", flatlight=True)
    d.text("VOL", 184, 106, "paint_k", align="c", flatlight=True)
    for i, (pid, lab) in enumerate((("chdn", "CH-"), ("mem", "MEM"), ("chup", "CH+"))):
        x = 28 + i * 34
        PR.tact(p, pid, x, 88, 12, 12, None)
        d.text(lab, x + 6, 104, "paint_k", align="c", flatlight=True)
    bat_toggle(p, 44, 132, mic_live, on=Z_FACE)          # up = TALK: a variant (micLive) flips it
    p.hit("mic", 36, 120, 16, 22)
    d.text("TALK", 64, 124, "paint_k", flatlight=True)
    d.text("LISTEN", 64, 136, "paint_k", flatlight=True)
    toggle_key(p, "mute", 108, 126, 28, 13, "MUTE", mat="blackp")
    dot_grille(p, 258, 92, 34, ring_mat="grille_ring")
    tp = Mask(p.W, p.H).rect(160, 124, 70, 13).get()
    d.slab(tp, 0.5, "tape", bevel=0.4, polish=0.4, on=Z_FACE)
    d.text("HOLD MEM", 195, 128, "paint_b", align="c", flatlight=True)
    d.torus(210, 150, 2.5, 5.0, 2.0, "steel", polish=1.0, on=Z_FACE)
    mic_cord(p, 210, 150, 350, HAM_H - 22)
    desk_mic(p, 330, ptt=False, lamp=False)
    if worn_:
        WR.grime(d, d.solid, amount=0.26, seed=324)
    return p
