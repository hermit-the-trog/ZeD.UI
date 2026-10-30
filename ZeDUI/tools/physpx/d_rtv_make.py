"""The Makeshift Radio (Base.RadioMakeShift) as a hand-wired board that would work (director, Oct 30 2026: "should
use the circuit board diagram like the car version. like it would really work").

The circuit is the car makeshift radio's (hw/nets.py RADIO: Philips' TDA7000 test circuit and National's LM386
minimum-parts amplifier) with what a portable adds:
  - the battery (4.5 V: three AA cells) sits in a holder soldered to the board, not on leads off the edge;
  - the speaker is on the board;
  - a switched headphone jack (J2) between the amplifier's output capacitor and the speaker: plugging in lifts the
    speaker off (tip to C20 -, the tip's normally-closed contact to the speaker, sleeve to ground).
The salvaged display board is bolted on top as on the car set; its ribbon takes power and ground only; it carries the
four presets and MUTE. Every wire is routed on the board's lattice and checked against the netlist below
(handwire.Board.check_nets) and as painted (check_paint), exactly as the car version is.

W is the half card's PANEL width (154 / 180 / 206 / 257); the face is W - 20. This first cut is drawn at 180.
"""
import os
import sys

from physlib import *            # noqa: F401,F403
import wear as WR
import handwire as H

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "hw"))
import nets as N                 # noqa: E402

# ------------------------------------------------------------------ the circuit: the car radio's, with the portable's jack
PARTS = dict(N.RADIO_PARTS)
PARTS["J2"] = ("jack", "3.5 mm switched", ["T", "TN", "S"])
NETS = {k: list(v) for k, v in N.RADIO_NETS.items()}
NETS["GND"] = NETS["GND"] + ["J2.S"]
NETS["SPKP"] = ["C20.-", "J2.T"]            # the output capacitor to the jack's tip
NETS["SPKN"] = ["J2.TN", "SPK.1"]           # the tip's normally-closed contact on to the speaker
OPEN = list(N.RADIO_OPEN)

OX, OY = 4, 4
ADD_Z = Z_FACE + 3.5


def tact_on(p, pid, x, y, w, h, label, on):
    d = p.d
    d.slab(rbox(d, x, y, w, h), 1.4, "steel", bevel=0.6, polish=0.6, on=on)
    d.dome(x + w / 2, y + h / 2, w * 0.32, h * 0.32, 1.6, "blackp", polish=0.6, on=on + 1.4)
    for (lx, ly) in ((x - 1, y + 1), (x + w, y + 1), (x - 1, y + h - 2), (x + w, y + h - 2)):
        d.flat(rbox(d, lx, ly, 1, 1), on + 0.3, "solder", polish=0.9)
    if label: p.label(label, x + w // 2, y + h + 3, "paint_w", align="c", auto_ink=False)
    p.hit(pid, x, y, w, h)


def display_board(p, F):
    """the salvaged display-and-keys board on four spacers along the top: the two-line character display, the four
    presets and MUTE, the controller chip and the ribbon header"""
    d = p.d
    x0, y0, x1, y1 = 6, 5, F - 6, 47
    body = Mask(d.W, d.H).rrect(x0, y0, x1 - x0, y1 - y0, 2).get()
    d.slab(body, ADD_Z, "pcb", bevel=1.0, polish=0.55)
    d.grain_pebble(body, 0.03, seed=371)
    for (sx, sy) in ((x0 + 4, y0 + 4), (x1 - 5, y0 + 4), (x0 + 4, y1 - 5), (x1 - 5, y1 - 5)):
        d.torus(sx, sy, 1.8, 3.0, 0.8, "solder", polish=0.9, on=ADD_Z)
        screw(p, sx, sy, on=ADD_Z, mat="steel")
    cols = (x1 - x0 - 22) // 6
    dw = cols * 6 + 6
    frame = Mask(d.W, d.H).rrect(x0 + 9, y0 + 3, dw + 6, 24, 1).get()
    d.slab(frame, 1.0, "steel", bevel=0.8, polish=0.7, on=ADD_Z)
    window_glass(p, x0 + 11, y0 + 5, dw + 2, 20, face="lcdlit", bezel="blackp", depth=1.4, on=ADD_Z + 1.0, r=1, bezel_t=1, lens=False)
    p.part("radioDisplay", kind="makeshift2", style="char", x=x0 + 12, y=y0 + 6, w=dw, h=18,
           color="#1f2a0c", ghost="#8b9e4c",
           fields=[{"t": "cells", "src": "l1", "x": 3, "y": 3, "cols": cols, "pitch": 6, "font": "35"},
                   {"t": "cells", "src": "l2", "x": 3, "y": 11, "cols": cols, "pitch": 6, "font": "35", "marquee": True}])
    ky = y0 + 31
    for i in range(4):
        tact_on(p, f"p{i + 1}", x0 + 10 + i * 16, ky, 9, 9, str(i + 1), ADD_Z)
    tact_on(p, "mute", x0 + 10 + 4 * 16 + 6, ky, 9, 9, None, ADD_Z)
    p.label("MUTE", x0 + 10 + 4 * 16 + 18, ky + 2, "paint_w", auto_ink=False)
    # the controller and the 2 x 5 header the ribbon leaves from
    hx0 = x1 - 30
    d.slab(rbox(d, hx0, ky - 1, 22, 6), 2.2, "blackp", bevel=0.6, polish=0.5, on=ADD_Z)
    for k in range(5):
        for yy in (ky, ky + 3):
            d.flat(rbox(d, hx0 + 2 + k * 4, yy, 1, 1), ADD_Z + 2.4, "solder", polish=0.9)
    return body, (hx0 + 11, ky + 6)


def battery_holder(B, x, y, w, h, plus, minus):
    """three AA cells in a black holder glued to the board, its two tabs soldered to holes; the click area takes the
    batteries out and puts them in"""
    p, d = B.p, B.d
    m = Mask(d.W, d.H).rrect(x, y, w, h, 2).get()
    d.slab(m, 2.0, "blackp", bevel=0.9, polish=0.4, on=Z_FACE)
    cw = (w - 6) / 3
    for i in range(3):
        cx = x + 3 + i * cw
        c = Mask(d.W, d.H).rrect(cx + 1, y + 3, cw - 2, h - 6, 2).get()
        d.slab(c, 2.4, "chrome" if i % 2 else "alu", bevel=1.4, polish=0.9, on=Z_FACE + 2.0)
        d.slab(Mask(d.W, d.H).rrect(cx + 1, y + 3 + (h - 6) * 0.55, cw - 2, (h - 6) * 0.45, 1).get(), 0.2, "paint_r", bevel=0.4,
               polish=0.6, on="cur")
    def edge_pt(key):
        kx, ky = B.fc(key)
        return (min(max(kx, x + 2), x + w - 2), y + 0.5 if ky < y else (y + h - 0.5 if ky > y + h else ky))
    H.tabs(B, "BT1", [(edge_pt(plus), plus), (edge_pt(minus), minus)], w=2.0)
    B._body("BT1", m); B.keep_mask(m, 2)
    B.add_part("BT1", "batt", {"+": plus, "-": minus})
    p.hit("battery", x, y, w, h)
    return m


def speaker(B, cx, cy, r, pins):
    p, d = B.p, B.d
    m = disc(d, cx, cy, r)
    d.slab(m, 1.2, "steel", bevel=0.8, polish=0.6, on=Z_FACE)
    d.dome(cx, cy, r - 3, r - 3, -2.0, "paint_k", polish=0.25, on=Z_FACE + 1.2)
    d.dome(cx, cy, r * 0.3, r * 0.3, 1.0, "steel", polish=0.6, on=Z_FACE - 0.8)
    edge = []
    for key in pins.values():
        kx, ky = B.fc(key)
        import math as _m
        ang = _m.atan2(ky - cy, kx - cx)
        edge.append(((cx + _m.cos(ang) * (r - 1), cy + _m.sin(ang) * (r - 1)), key))
    H.tabs(B, "SPK", edge, w=1.6)
    B._body("SPK", m); B.keep_mask(m, 2)
    B.add_part("SPK", "spk", dict(pins))
    return m


def jack(B, x, y, pins):
    """a switched 3.5 mm jack on the board: its black body, the socket (the plug's tip lit when one is in), three tabs"""
    p, d = B.p, B.d
    m = Mask(d.W, d.H).rrect(x, y, 14, 12, 1).get()
    d.slab(m, 3.0, "blackp", bevel=0.8, polish=0.5, on=Z_FACE)
    cx, cy = x + 7, y + 6
    d.torus(cx, cy, 2.0, 4.0, 1.2, "chrome", polish=1.0, on=Z_FACE + 3.0)
    d.dome(cx, cy, 2.0, 2.0, -1.4, "hole", polish=0.2, on=Z_FACE + 3.0)
    p.lamp(disc(d, cx, cy, 1.8), "phonesIn", "#cfd3d6", halo=False)
    p.hit("phones", x, y, 14, 12)
    edge = []
    for key in pins.values():
        kx, ky = B.fc(key)
        ex = min(max(kx, x + 1), x + 13)
        ey = y + 12 if ky > y + 12 else (y if ky < y else ky)
        edge.append(((ex, ey), key))
    H.tabs(B, "J2", edge, w=1.6)
    B._body("J2", m); B.keep_mask(m, 2)
    B.add_part("J2", "jack", dict(pins))
    return m


def radio_make(W=180, worn_=True, switch_on=True, soft=False):
    F = W - 20
    rows = 31
    Hh = OY + 6 * (rows - 1) + 6
    p = Plate("radio_make", F, Hh, seed=341, title="Makeshift Radio")
    d = p.d
    cols = (F - OX - 2) // 6 + 1
    B = H.Board(p, OX, OY, cols, rows)
    B.soft = soft
    B.paint_board(0, 0, F, Hh)
    # the display board stands on four spacers screwed through the perforated board: keep wire off them
    for (sx, sy) in ((10, 9), (F - 11, 9), (10, 44), (F - 11, 44)):
        B.keep_box(sx - 3, sy - 3, sx + 3, sy + 3, margin=0)

    # ---------------- the receiver, right: the car board's layout moved (car column c -> c - 43, row r -> r + 8)
    def R(i, j): return (i - 43, j + 8)
    H.dip(B, "U1", R(66, 7), 18, along=(-1, 0), across=(0, -1), label="TDA7000")
    H.two_lead(B, "C18", R(66, 4), R(66, 1), "disc", "220p")
    H.two_lead(B, "C17", R(65, 4), R(65, 1), "disc", "330p")
    H.two_lead(B, "C15", R(63, 4), R(63, 1), "disc_b", "100n")
    H.two_lead(B, "C14", R(62, 4), R(62, 2), "disc", "220p")
    H.two_lead(B, "C13", R(61, 4), R(61, 2), "disc", "220p", pins=("2", "1"))
    H.two_lead(B, "C12", R(60, 4), R(60, 1), "disc", "150p")
    H.two_lead(B, "C11", R(59, 4), R(59, 1), "disc", "3n3")
    H.two_lead(B, "C10", R(59, 4), R(57, 2), "disc", "330p")
    H.two_lead(B, "C1", R(66, 7), R(66, 9), "film", "150n", body_len=8)
    H.two_lead(B, "C3", R(64, 7), R(64, 9), "disc_b", "22n")
    H.two_lead(B, "C4", R(63, 7), R(63, 9), "disc", "10n")
    H.two_lead(B, "C8", R(59, 7), R(59, 9), "disc", "180p")
    H.two_lead(B, "C7", R(58, 7), R(56, 7), "disc", "3n3", pins=("2", "1"))
    H.two_lead(B, "L1", R(58, 11), R(61, 11), "coil", "56nH")
    H.two_lead(B, "CP", R(58, 13), R(61, 13), "disc", "33p")
    H.two_lead(B, "CS", R(61, 17), R(61, 15), "disc", "100p")
    H.polyvaricon(B, "CV", 134, 140, 30, {"1": R(62, 11), "2": R(61, 17)}, [R(66, 11)], 12, "tune")

    # ---------------- the amplifier, left: the power rocker, the volume control, the LM386 and its output parts
    rx, ry = 6, 58
    bez = Mask(d.W, d.H).rrect(rx, ry, 22, 14, 2).get()
    rocker_switch(p, rx + 2, ry + 2, 18, 10, switch_on, on=Z_FACE, mat="paint_r", bezel_mat="blackp", lift=1.8)
    p.hit("power", rx, ry, 22, 14)
    H.tabs(B, "SW1", [((rx + 5.5, ry + 13.5), (1, 12)), ((rx + 16.5, ry + 13.5), (3, 12))], w=2.0)
    B._body("SW1", bez); B.keep_mask(bez, 2)
    B.add_part("SW1", "switch", {"1": (1, 12), "2": (3, 12)})
    # the volume control at the left, its three lugs toward the chip: ground, wiper, the hot end
    H.pot(B, "VR1", 18.5, 104.5, 10, [(5, 19), (5, 18), (5, 17)], 8, "vol")
    H.dip(B, "U2", (5, 15), 8, along=(1, 0), across=(0, -1), label="LM386")
    H.can(B, "C20", (10, 11), (10, 15), D=13.0)
    H.two_lead(B, "C21", (10, 11), (12, 11), "green", "0.05u", body_len=8)
    H.resistor(B, "R20", (12, 11), (12, 15), "10R")
    # the receiver's load, its 1n8 and the joining capacitor: the audio along row 21, ground along row 24
    H.two_lead(B, "CC", (7, 21), (7, 19), "disc_b", "220n", pins=("1", "2"))
    H.resistor(B, "RL", (9, 21), (9, 24), "22k")
    H.two_lead(B, "C2", (11, 21), (11, 24), "disc", "1n8", pins=("1", "2"))
    # ---------------- along the bottom: the battery holder, the headphone jack, the speaker
    battery_holder(B, 6, 156, 40, 22, (0, 25), (5, 25))
    jack(B, 50, 160, {"S": (8, 25), "TN": (10, 25), "T": (10, 29)})
    speaker(B, 97.5, 166.5, 10, {"1": (15, 25), "2": (17, 25)})
    # ---------------- the display board's ribbon lands on the supply and ground, 10n across them
    # the ribbon comes straight down over the 10n: its outer two conductors land in the 10n's own holes
    B.add_part("J1", "ribbon", {"VP": (23, 8), "GND": (21, 8)})
    H.two_lead(B, "C5", (23, 8), (21, 8), "disc", "10n", pins=("1", "2"))
    ant = B.edge("ANT", F + 4, OY + 6 * 7, entry=(2 * (cols - 1), 2 * 7))     # tucked under the display board, out the side
    B.add_part("ANT", "ant", {"1": ant})

    # ---------------- the wiring
    rw = [
        # ---- the receiver, as on the car board
        ("blue", (R(57, 2), R(58, 4)), {}),
        ("green", (R(56, 7), R(60, 7)), {"via": [(26, 36), (34, 36)]}),
        ("yellow", (R(61, 7), R(61, 11), R(61, 13), R(61, 15)), {}),     # insulated here: the audio crosses it
        ("red", (R(59, 1), R(60, 1)), {"bare": True}),
        ("red", (R(60, 1), R(63, 1)), {}),                 # insulated over C14's top, so its ground can cross
        ("red", (R(63, 1), R(65, 1), R(66, 1)), {"bare": True}),
        ("red", (R(62, 7), R(62, 9), R(63, 9), R(64, 9)), {"bare": True}),
        ("red", (R(64, 9), R(66, 9)), {}),                 # insulated past pin 2, so the audio can cross it
        ("red", (R(62, 9), R(62, 11)), {"bare": True}),
        ("red", (R(58, 11), R(58, 13)), {"bare": True}),
        ("red", (R(59, 9), R(62, 9)), {}),
        ("red", (R(59, 9), R(58, 11)), {}),
        ("red", (R(66, 1), R(66, 9)), {}),
        ("black", (R(62, 2), (21, 8)), {}),                # C14 up across the bus to the ribbon's ground ...
        ("black", (R(64, 4), (21, 8)), {}),                # ... and pin 16 beside it
        ("orange", (R(61, 2), ant), {"via": [(36, 14)]}),
        # ---- the supply: the battery's + straight up the left edge to the switch; the switch to pin 6; on to the bus
        ("red", ((0, 25), (1, 12)), {}),
        ("red", ((3, 12), (7, 12)), {}),
        ("red", ((7, 12), R(59, 1)), {"via": [(14, 14)]}),
        ("red", ((23, 8), R(66, 1)), {}),
        # ---- the amplifier
        ("orange", ((8, 12), (10, 11)), {"bare": True}),              # pin 5 to C20 + and C21
        ("black", ((5, 17), (6, 15)), {}),                            # the control's ground to pin 2
        ("black", ((6, 15), (5, 25)), {"via": [(12, 46)]}),           # pin 2 down to the battery's -
        ("green", ((5, 18), (7, 15)), {}),                            # the wiper to pin 3
        ("white", ((10, 15), (10, 29)), {"via": [(24, 32), (24, 56)]}),   # C20 - down col 12 to the jack's tip
        ("white", ((5, 19), (7, 19)), {}),                            # the control's hot end to the joining capacitor
        ("black", ((8, 15), (12, 15)), {}),                           # and R20
        # ---- the receiver's audio: east past the varicon, along under it, up to the load and the joining capacitor
        ("white", (R(65, 7), (11, 21)), {"via": [(44, 36), (50, 36), (50, 60), (26, 60), (26, 44)]}),
        ("white", ((11, 21), (9, 21), (7, 21)), {}),
        # ---- ground: the ribbon's ground under the display board down to the amplifier; pin 4 down to the row-24 strip
        ("black", ((21, 8), (12, 15)), {"via": [(42, 12), (26, 12), (26, 28)]}),
        ("black", ((8, 15), (9, 24)), {}),
        ("black", ((9, 24), (11, 24)), {}),
        ("black", ((9, 24), (8, 25)), {}),                            # the jack's sleeve
        ("black", ((8, 25), (5, 25)), {}),                            # and the battery's -
        ("black", ((11, 24), (17, 25)), {}),                          # the speaker's other side
        # ---- the jack's break contact on to the speaker
        ("white", ((10, 25), (15, 25)), {}),
    ]
    for color, keys, kw in rw:
        B.wire(color, *keys, **kw)
    B.paint_wires()
    B.paint_joints()
    body, hdr = display_board(p, F)
    cx_ = (B.px((21, 8))[0] + B.px((23, 8))[0]) / 2 + 0.5
    H.ribbon_paint(B, "J1", (cx_, hdr[1]), (cx_, 47.5), 5, {"GND": (0, (21, 8)), "VP": (4, (23, 8))})
    H.tape(p, 7, 84, 20, 8, "VOL")
    H.tape(p, 31, 59, 22, 8, "PWR")
    B.cover_holes()
    if worn_:
        WR.grime(d, d.solid, amount=0.22, seed=343)
    # focus walks the click areas in reading order: power, the presets, mute, volume, tune, phones, the battery
    from d_makeshift import keep_order
    keep_order(p, ["power", "p1", "p2", "p3", "p4", "mute", "vol", "tune", "phones", "battery"], ["radioDisplay", "volF", "tuneF"])
    errs = B.check_paint() + B.check_nets(NETS, OPEN)
    for e in errs: p.warn("wiring: " + e)
    for e in B.failed: p.warn("route: " + e)
    return p
