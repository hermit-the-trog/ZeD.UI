"""Concepts for the game speed control when no watch is worn: three physical objects that set the pace without telling
the time of day (vanilla hides the time without a watch). Rough drafts for the director to choose from.
usage: python c_nowatch.py -> out/nowatch/concepts.png"""
import math
import os

import numpy as np
from PIL import Image

from physlib import *            # noqa: F401,F403
import d_props as PR             # noqa: F401  (tape, solder ramps)
from engine import add_ramp
add_ramp("brass", "#b8913a", light=1.1)
add_ramp("walnut", "#5a3a22")

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "nowatch")
os.makedirs(OUT, exist_ok=True)


def tri(d, cx, cy, w, h, mat, right=True):
    pts = [(cx - w / 2, cy - h / 2), (cx - w / 2, cy + h / 2), (cx + w / 2, cy)] if right else \
          [(cx + w / 2, cy - h / 2), (cx + w / 2, cy + h / 2), (cx - w / 2, cy)]
    d.paint(Mask(d.W, d.H).poly(pts).get(0.45), mat, flatlight=True)


def tape_deck(pressed=1):
    """A: a portable cassette recorder's key row, the deck's door and its counter wheels (tape counter, not a clock):
    PAUSE, PLAY, FAST FORWARD, and the stuck fast forward (two arrows)"""
    W, H = 184, 64
    p = Plate("nw_tape", W, H, seed=7)
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 4).get()
    d.slab(body, Z_FACE, "blackp", bevel=2.0, polish=0.45)
    d.grain_pebble(body, 0.04, seed=8)
    # the cassette door with its window
    door = Mask(W, H).rrect(8, 6, 96, 30, 2).get()
    d.slab(door, 0.8, "blackp", bevel=0.8, polish=0.6, on=Z_FACE)
    window(d, 22, 12, 68, 18, 1.0, face="blackglass", bezel="chrome", r=1, bezel_t=1, on=Z_FACE + 0.8, lens=True)
    for cx in (38, 74):                                   # the cassette's hubs behind the window
        d.dome(cx, 21, 4.5, 4.5, 0.6, "steel", polish=0.7, on=Z_FACE + 0.2)
        d.seam(disc(d, cx, 21, 1.8), 0.4)
    d.text("AUTO STOP", 56, 38, "paint_c", align="c", flatlight=True)
    # the counter: three wheels in a little window
    window(d, 118, 10, 22, 9, 0.8, face="cream", bezel="chrome", r=0, bezel_t=1, on=Z_FACE, lens=False)
    d.text("000", 129, 12, "paint_k", align="c", flatlight=True)
    d.text("COUNTER", 129, 21, "paint_c", align="c", flatlight=True)
    jewel(p, 160, 15, 3.0, off="jewel_red_off", bezel="chrome", on=Z_FACE)
    d.text("BATT", 160, 21, "paint_c", align="c", flatlight=True)
    # the key row in its chrome surround: the pressed one down
    rects = piano_keys(p, 8, 46, ["", "", "", ""], 42, 13, pressed, mat="steel", frame="chrome")
    for i, (x, y, w, h) in enumerate(rects):
        cx, cy = x + w / 2, y + h / 2
        if i == 0:
            d.paint(rbox(d, int(cx - 3), int(cy - 3), 2, 6), "paint_k", flatlight=True)
            d.paint(rbox(d, int(cx + 1), int(cy - 3), 2, 6), "paint_k", flatlight=True)
        elif i == 1:
            tri(d, cx, cy, 5, 6, "paint_k")
        else:
            for k in range(i):
                tri(d, cx - 3 * (i - 1) + 6 * k, cy, 5, 6, "paint_k")
    return p


def kitchen_timer(pos=1):
    """B: a wind-up kitchen timer turned into the pace dial: STOP, then one, two, three (the dial's pointer at the
    chosen speed; no minutes on it, so it never tells the time)"""
    W, H = 120, 96
    p = Plate("nw_timer", W, H, seed=9)
    d = p.d
    cx, cy = 60, 52
    base = disc(d, cx, cy + 2, 40)
    d.slab(base, Z_FACE - 1.0, "enamel_white", bevel=3.0, polish=0.5)
    d.slab(disc(d, cx, cy, 36), 1.4, "enamel_white", bevel=2.0, polish=0.6, on=Z_FACE - 1.0)
    angles = [-150, -110, -70, -30]
    scale_ring(p, cx, cy, 24, angles, ["0", "1", "2", "3"], tick=3, mat="paint_k", lab_mat="paint_k")
    a = math.radians(angles[pos])
    fluted_knob(p, cx, cy, 18, on=Z_FACE + 0.4, z=4.0, mat="paint_r", skirt=None, ridges=24, dome=0.8, check=False)
    d.paint(line_mask(d, cx, cy, cx + math.cos(a) * 15, cy + math.sin(a) * 15, 1.6), "paint_w", flatlight=True)
    d.text("PACE", cx, 4, "paint_k", align="c", flatlight=True)
    return p


def metronome(pos=1, running=True):
    """C: a wind-up metronome: its weight slides to one of three tempos, the start lever on its side stops it"""
    W, H = 96, 100
    p = Plate("nw_metro", W, H, seed=11)
    d = p.d
    cx = 48
    body = Mask(W, H).poly([(cx - 34, 96), (cx + 34, 96), (cx + 12, 6), (cx - 12, 6)]).get()
    d.slab(body, Z_FACE, "walnut", bevel=2.5, polish=0.55)
    d.grain_brushed(body, 0.05, seed=12)
    face = Mask(W, H).poly([(cx - 20, 80), (cx + 20, 80), (cx + 7, 14), (cx - 7, 14)]).get()
    d.slab(face, 0.6, "enamel_almond", bevel=0.8, polish=0.4, on=Z_FACE)
    for k, (y, lab) in enumerate(((30, "3"), (46, "2"), (62, "1"))):
        d.paint(rbox(d, cx - 9, y, 7, 1), "paint_k", flatlight=True)
        d.paint(rbox(d, cx + 3, y, 7, 1), "paint_k", flatlight=True)
        d.text(lab, cx - 13, y - 2, "paint_k", align="c", flatlight=True)
    # the pendulum rod and its weight at the chosen tempo
    ang = math.radians(12 if running else 0)
    x0, y0 = cx, 84
    x1, y1 = cx + math.sin(ang) * 70, y0 - math.cos(ang) * 70
    d.slab(line_mask(d, x0, y0, x1, y1, 1.6), 1.6, "steel", bevel=0.6, polish=0.9, on=Z_FACE + 0.6)
    wy = {0: 62, 1: 62, 2: 46, 3: 30}[pos]
    t = (y0 - wy) / 70
    wx = x0 + (x1 - x0) * t
    d.slab(Mask(W, H).rrect(int(wx - 5), int(wy - 4), 10, 8, 1).get(), 2.4, "brass", bevel=1.0,
           polish=0.9, on=Z_FACE + 0.6)
    # the start/stop lever on the side
    d.slab(Mask(W, H).rrect(cx + 22, 76 if running else 70, 12, 4, 1).get(), 1.8, "chrome", bevel=0.6, polish=1.0, on=Z_FACE)
    d.text("STOP", cx, 88, "paint_w", align="c", flatlight=True)
    return p


if __name__ == "__main__":
    k = 4
    pics = []
    for fn, states in ((tape_deck, (0, 1, 3)), (kitchen_timer, (0, 1, 3)), (metronome, ((0, False), (1, True), (3, True)))):
        row = []
        for s in states:
            q = fn(*s) if isinstance(s, tuple) else fn(s)
            row.append(q.d.render(chrome_env="room"))
        pics.append(row)
    W = max(sum(i.width * k + 16 for i in r) for r in pics) + 16
    H = sum(max(i.height for i in r) * k + 24 for r in pics) + 8
    sheet = Image.new("RGBA", (W, H), (40, 40, 44, 255))
    y = 12
    for r in pics:
        x = 12
        for im in r:
            sheet.alpha_composite(im.resize((im.width * k, im.height * k), 0), (x, y)); x += im.width * k + 16
        y += max(i.height for i in r) * k + 24
    sheet.save(os.path.join(OUT, "concepts.png"))
    print("ok", sheet.size)
