"""The car props up close, in the dashboards' pixel art: the six fitted radios' faces (the same faces as the dash's
head units, brought up close: screws, legends, worn keys) and the police dash's siren controller.

Every control keeps the place the approved up-close layout gave it (RadioPlates.faces, SirenPlate), so the radio's
and the siren's workings stay as they are: the display, knob pointers, lamps, the CD's edge, the masking tape's
handwriting and the RANGE line are drawn live; a held key is shaded live. One plate pixel per design unit.
"""
import math

import numpy as np
from scipy import ndimage as ndi

from physlib import *            # noqa: F401,F403
import wear as WR
from engine import add_ramp
from dashlib import F35, F57

add_ramp("olive", "#4a4f32")
add_ramp("hamgrey", "#5a5e60")
add_ramp("pcb", "#2c5a2c")
add_ramp("copper", "#b07a3a")
add_ramp("solder", "#b8bcc0", light=1.2)
add_ramp("tape", "#e6dcb8", light=1.1)
add_ramp("resistor", "#d8c49a")
RAMPS["lcdlit"] = [hx(c) for c in ("#5f7034", "#6d7f3b", "#7a8d43", "#889c4b", "#95aa54", "#a3b85e", "#b0c56a", "#bed277")]
RAMPS["lcdgrey"] = [hx(c) for c in ("#5a6352", "#646e5b", "#6e7964", "#78836e", "#838e78", "#8e9983", "#99a48e", "#a5b09a")]

DISPLAY_KIND = {"premium": "vfd", "valutech": "amber", "makeshift": "char", "ham": "lcd", "army": "led", "hammake": "char"}
DISPLAY_FACE = {"vfd": "vfd", "amber": "lens", "char": "lcdlit", "lcd": "lcdgrey", "led": "ledglass"}


def radio_state(kind, on=True, freq="98.4", name="KNOX TALK", preset=2, volume=0.6, tune=0.3, muted=False, mic_muted=False,
                switch_on=True, has_media=False, **kw):
    s = dict(radioOn=on, power=on, radioFreq=freq, radioStation=name, presetIdx=preset, volF=volume, tuneDeg=tune * 360,
             muted=muted, micMuted=mic_muted and on, micLive=not mic_muted, switchOn=switch_on, hasMedia=has_media, kind=kind)
    s.update(kw)
    return s


# ------------------------------------------------------------------ shared bits
def plate_body(p, mat, grain=None, seed=1, edge="chrome", r=3):
    d = p.d
    body = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, r).get()
    d.slab(body, Z_FACE, mat, bevel=2.0, polish=0.45)
    if grain == "brushed": d.grain_brushed(body, 0.035, seed=seed)
    elif grain == "pebble": d.grain_pebble(body, 0.045, seed=seed)
    if edge: chrome_frame(d, 1, 1, p.W - 2, p.H - 2, Z_FACE - 0.4, t=1, mat=edge, z=0.9)
    return body


def display(p, kind, x, y, w, h, bezel="blackp"):
    """the display's glass (its face for the kind); the game draws the readout (part 'radioDisplay')"""
    dk = DISPLAY_KIND[kind]
    window_glass(p, x - 2, y - 2, w + 4, h + 3, face=DISPLAY_FACE[dk], bezel=bezel, depth=1.6, on=Z_FACE, r=1, bezel_t=2, lens=dk in ("vfd", "amber", "led"))
    p.part("radioDisplay", kind=kind, style=dk, x=x, y=y, w=w, h=h)


def radio_knob(p, cx, cy, r, mat="blackp", skirt=None, ridges=30, pid="vol", label=None, label_y=None, ptr="#e8e8e8",
               lab_mat="paint_w"):
    kn = fluted_knob(p, cx, cy, r, on=Z_FACE, z=5.0, mat=mat, skirt=skirt, skirt_mat="chrome", ridges=ridges, dome=1.0)
    src = "volF" if pid == "vol" else "tuneDeg"
    if pid == "vol":
        p.part("ptr", src="volF", cx=cx, cy=cy, r0=r * 0.30, r1=r * 0.78, a0=-225, a1=45, color=ptr, w=2 if r >= 20 else 1)
    else:
        p.part("ptr", src="tuneF", cx=cx, cy=cy, r0=r * 0.30, r1=r * 0.78, a0=-90, a1=270, color=ptr, w=2 if r >= 20 else 1)
    p.hit(pid, cx - r, cy - r, 2 * r, 2 * r, kind="turn")
    if label: p.label(label, cx, label_y if label_y is not None else int(cy + r + 6), lab_mat, align="c", auto_ink=False)
    return kn


def radio_key(p, pid, x, y, w, h, label=None, mat="blackp", lab_mat="paint_w", icon=None, wear=0.0, z=2.0):
    d = p.d
    p.check_flat(x - 1, y - 1, w + 2, h + 2, f"key {pid}")
    m = Mask(d.W, d.H).rrect(x, y, w, h, 2).get()
    d.slab(m, z, mat, bevel=1.4, polish=0.5, on=Z_FACE)
    if icon == "up": arrow_icon(p, x + w / 2, y + h / 2, True, lab_mat)
    elif icon == "down": arrow_icon(p, x + w / 2, y + h / 2, False, lab_mat)
    elif icon == "eject":
        arrow_icon(p, x + w / 2, y + h / 2 - 2, True, lab_mat, w=9, h=5)
        d.paint(rbox(d, int(x + w / 2 - 4), int(y + h / 2 + 2), 9, 1), lab_mat, flatlight=True)
    elif icon == "play":
        tri = Mask(d.W, d.H).poly([(x + w / 2 - 9, y + h / 2 - 3.5), (x + w / 2 - 9, y + h / 2 + 3.5), (x + w / 2 - 3, y + h / 2)]).get(0.45)
        d.paint(tri, lab_mat, flatlight=True)
        d.paint(rbox(d, int(x + w / 2 + 2), int(y + h / 2 - 3), 7, 7), lab_mat, flatlight=True)
        d.paint(rbox(d, int(x + w / 2 - 1), int(y + h / 2 - 4), 1, 9), lab_mat, flatlight=True)
    elif label:
        fh = 5
        worn_text(d, label, x + w // 2, y + (h - fh) // 2, lab_mat, wear=wear, seed=x * 3 + y, align="c")
    p.hit(pid, x, y, w, h)
    return m


def screw_at(p, x, y, mat="steel"):
    screw(p, x, y, on=Z_FACE, mat=mat)


def range_strip(p, x, y, w=64, mat="alu", ink="#1a1a1a"):
    """the sticker or plate the set's RANGE line is printed on live"""
    d = p.d
    m = Mask(d.W, d.H).rrect(int(x - w // 2), int(y - 6), w, 11, 1).get()
    d.slab(m, 0.4, mat, bevel=0.6, polish=0.4, on=Z_FACE)
    p.part("rangeText", x=int(x), y=int(y - 2), color=ink)


# ------------------------------------------------------------------ PCB bits (the makeshift sets)
def trace(p, pts, w=1.0, mat="copper"):
    d = p.d
    m = Mask(d.W, d.H).line(pts, w).get(0.45)
    d.paint(m & d.solid, mat, flatlight=True)
    d.h[m] += 0.15
    return m


def solder(p, x, y):
    p.d.dome(x, y, 1.6, 1.6, 0.9, "solder", polish=1.0, on=Z_FACE)


def chip(p, x, y, w, h, label=None):
    d = p.d
    body = Mask(d.W, d.H).rrect(x, y, w, h, 1).get()
    d.slab(body, 1.8, "blackp", bevel=0.8, polish=0.5, on=Z_FACE)
    for k in range(2, w - 1, 3):
        for yy in (y - 2, y + h):
            d.flat(rbox(d, x + k, yy, 1, 2), Z_FACE + 0.4, "solder", polish=0.9)
    if label: d.text(label, x + w // 2, y + (h - 5) // 2, "paint_w", align="c", flatlight=True)


def resistor(p, x, y, bands=("paint_r", "paint_k", "paint_y")):
    d = p.d
    d.cyl(x - 4, y, 3, 1, 0.6, "solder", axis="h", polish=0.9, on=Z_FACE)
    d.cyl(x + 9, y, 3, 1, 0.6, "solder", axis="h", polish=0.9, on=Z_FACE)
    d.cyl(x - 1, y - 2, 11, 5, 2.2, "resistor", axis="h", polish=0.5, on=Z_FACE)
    for i, b in enumerate(bands):
        d.paint(rbox(d, x + 1 + i * 2, y - 2, 1, 5), b, flatlight=False)


def tact(p, pid, x, y, w, h, label=None):
    """a PCB tact switch: a square metal body, a round black button"""
    d = p.d
    body = rbox(d, x, y, w, h)
    d.slab(body, 1.4, "steel", bevel=0.6, polish=0.6, on=Z_FACE)
    d.dome(x + w / 2, y + h / 2, w * 0.32, h * 0.32, 1.6, "blackp", polish=0.6, on=Z_FACE + 1.4)
    for (lx, ly) in ((x - 1, y + 1), (x + w, y + 1), (x - 1, y + h - 2), (x + w, y + h - 2)):
        d.flat(rbox(d, lx, ly, 1, 1), Z_FACE + 0.3, "solder", polish=0.9)
    if label: d.text(label, x + w // 2, y + h + 3, "paint_w", align="c", flatlight=True)
    p.hit(pid, x, y, w, h)


def pot(p, pid, cx, cy, r, label=None):
    """a potentiometer with a small knurled black knob on it"""
    d = p.d
    d.slab(rbox(d, int(cx - r - 3), int(cy - r - 3), int(2 * r + 6), int(2 * r + 6)), 1.0, "steel", bevel=0.6, polish=0.5, on=Z_FACE)
    fluted_knob(p, cx, cy, r, on=Z_FACE + 1.0, z=4.0, mat="blackp", skirt=None, ridges=22, dome=0.6, check=False)
    if pid == "vol":
        p.part("ptr", src="volF", cx=cx, cy=cy, r0=r * 0.3, r1=r * 0.8, a0=-225, a1=45, color="#e8e8e8", w=1)
    else:
        p.part("ptr", src="tuneF", cx=cx, cy=cy, r0=r * 0.3, r1=r * 0.8, a0=-90, a1=270, color="#e8e8e8", w=1)
    p.hit(pid, cx - r, cy - r, 2 * r, 2 * r, kind="turn")
    if label: d.text(label, int(cx), int(cy + r + 6), "paint_w", align="c", flatlight=True)


def pcb_rocker(p, x, y, w, h, on_state):
    """the makeshift sets' power: a red rocker on the board, its top half lit while the set is on"""
    d = p.d
    rocker_switch(p, x + 2, y + 2, w - 4, h - 4, on_state, on=Z_FACE, mat="paint_r", bezel_mat="blackp", lift=1.8)
    p.hit("pwr", x, y, w, h)


def pcb_board(p, seed):
    d = p.d
    body = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, 3).get()
    d.slab(body, Z_FACE, "pcb", bevel=1.2, polish=0.55)
    d.grain_pebble(body, 0.025, seed=seed)
    for (x, y) in ((6, 6), (p.W - 7, 6), (6, p.H - 7), (p.W - 7, p.H - 7)):
        d.torus(x, y, 2.0, 3.4, 0.8, "solder", polish=0.9, on=Z_FACE)
        screw(p, x, y, on=Z_FACE, mat="steel")
    return body


# =================================================================================== the six radios
def premium(worn=True):
    W, H = 480, 150
    p = Plate("radio_premium", W, H, seed=81, title="Premium Technologies CD receiver")
    d = p.d
    plate_body(p, "blackp", grain="brushed", seed=82)
    p.label("PREMIUM TECHNOLOGIES", 14, 8, "paint_c", auto_ink=False)
    p.label("CD RECEIVER", W - 14, 8, "paint_c", align="r", auto_ink=False)
    display(p, "premium", 96, 28, 290, 58, bezel="chrome")
    radio_knob(p, 46, 60, 24, mat="alu", skirt=1.4, pid="vol", label="VOL - PUSH ON", label_y=92, ptr="#202226")
    radio_knob(p, 434, 60, 24, mat="alu", skirt=1.4, pid="tune", label="TUNE", label_y=92, ptr="#202226")
    # the CD slot and its eject
    slot = Mask(W, H).rrect(120, 93, 230, 8, 3).get()
    d.slab(slot, 1.0, "chrome", bevel=1.0, polish=1.0, on=Z_FACE)
    d.well(Mask(W, H).rrect(124, 95, 222, 4, 2).get(), 3.0, "rubber", bevel=0.6)
    p.part("slotDisc", x=128, y=96, w=214, color="#c6ccd2")
    p.hit("slot", 120, 93, 230, 8)
    radio_key(p, "eject", 356, 89, 30, 17, icon="eject", mat="blackp")
    used = {1: 0.18, 2: 0.14, 3: 0.08}
    for i in range(6):
        radio_key(p, f"p{i + 1}", 96 + i * 25, 110, 22, 17, str(i + 1), wear=used.get(i + 1, 0.0) if worn else 0)
    radio_key(p, "scan", 252, 110, 37, 17, "SCAN")
    radio_key(p, "seek", 295, 110, 37, 17, "SEEK", wear=0.10 if worn else 0)
    radio_key(p, "mute", 338, 110, 45, 17, "MUTE")
    radio_key(p, "play", 410, 110, 48, 17, icon="play")
    p.label("PRESET - HOLD TO STORE", 96, 134, "paint_c", auto_ink=False)
    p.label("COMPACT DISC", 434, 134, "paint_c", align="c", auto_ink=False)
    if worn:
        WR.grime(d, d.solid, amount=0.28, seed=83)
        WR.scuffs(d, WR.mat_mask(d, "blackp"), 0.0008, seed=84, amount=0.10)
    return p


def valutech(worn=True):
    W, H = 440, 122
    p = Plate("radio_valutech", W, H, seed=85, title="ValuTech radio")
    d = p.d
    plate_body(p, "blackp", grain="pebble", seed=86, edge=None)
    p.label("VALUTECH", 14, 10, "paint_w", font="57", auto_ink=False)
    p.label("FM STEREO", 14, 22, "paint_c", auto_ink=False)
    display(p, "valutech", 150, 12, 150, 38)
    radio_key(p, "mute", 310, 22, 40, 17, "MUTE")
    # SEEK left of the display, level with MUTE (director, Oct 25 2026: under MUTE it crowded the presets)
    radio_key(p, "seek", 100, 22, 40, 17, "SEEK", wear=0.12 if worn else 0)
    used = {1: 0.2, 2: 0.15, 4: 0.1}
    for i in range(6):
        radio_key(p, f"p{i + 1}", 92 + i * 46, 62, 40, 17, str(i + 1), wear=used.get(i + 1, 0.0) if worn else 0)
    # the masking tape under the presets (the names are written on it live, in ballpoint)
    tape = Mask(W, H).poly([(88, 85), (366, 84), (367, 98), (88, 99)]).get()
    d.slab(tape, 0.4, "tape", bevel=0.4, polish=0.2, on=Z_FACE)
    for (tx, ty) in ((88, 85), (88, 93), (366, 86), (366, 95)):
        d.seam(rbox(d, tx - (1 if tx < 100 else 0), ty, 2, 2) & tape, 0.3)
    p.part("tape", x=88, y=84, w=278, h=15, first=92, pitch=46)
    radio_knob(p, 43, 73, 19, mat="blackp", pid="vol", label="VOL - ON", label_y=98)
    radio_knob(p, 399, 73, 19, mat="blackp", pid="tune", label="TUNE", label_y=98)
    p.label("HOLD TO STORE", 227, 106, "paint_c", align="c", auto_ink=False)
    if worn:
        WR.grime(d, d.solid, amount=0.28, seed=87)
        WR.scuffs(d, WR.mat_mask(d, "blackp"), 0.0012, seed=88, amount=0.10)
    return p


def makeshift(switch_on=True, worn=True):
    W, H = 440, 128
    p = Plate("radio_makeshift", W, H, seed=89, title="makeshift radio")
    d = p.d
    pcb_board(p, 90)
    # traces first, then the parts on them
    for pts in (((50, 34), (60, 34), (60, 58), (140, 58)), ((52, 80), (52, 66), (120, 66), (150, 66)), ((392, 80), (392, 64), (300, 64)),
                ((300, 40), (330, 40), (330, 20), (420, 20)), ((150, 100), (240, 100), (240, 110), (380, 110)), ((96, 40), (140, 40))):
        trace(p, pts, 1.0)
    for pts in (((330, 40), (360, 52), (420, 46)), ((110, 92), (130, 84), (160, 92))):
        trace(p, pts, 1.0, mat="paint_y")
    for (x, y) in ((60, 34), (140, 58), (120, 66), (300, 64), (330, 20), (240, 100), (380, 110), (96, 40), (140, 40)):
        solder(p, x, y)
    p.label("MAKESHIFT - WIRES LIVE", 14, 10, "paint_w", auto_ink=False)
    pcb_rocker(p, 22, 26, 24, 16, switch_on)
    p.label("PWR", 34, 46, "paint_w", align="c", auto_ink=False)
    display(p, "makeshift", 148, 22, 144, 34, bezel="blackp")
    for i in range(6):
        tact(p, f"p{i + 1}", 158 + i * 22, 72, 12, 12, str(i + 1))
    tact(p, "seek", 310, 26, 14, 14, "SEEK")
    chip(p, 120, 86, 18, 9, None)
    p.label("LM386", 129, 98, "paint_w", align="c", auto_ink=False, check=False)
    resistor(p, 80, 108); resistor(p, 100, 116, ("paint_o", "paint_k", "paint_r"))
    d.dome(340, 92, 4.0, 4.0, 3.0, "paint_b", polish=0.8, on=Z_FACE)       # a trimmer
    d.dome(356, 96, 2.6, 2.6, 2.4, "paint_b", polish=0.8, on=Z_FACE)
    pot(p, "vol", 52, 92, 15, "VOL")
    pot(p, "tune", 392, 92, 15, "TUNE")
    if worn:
        WR.grime(d, d.solid, amount=0.24, seed=91)
    return p


def ham(worn=True):
    W, H = 500, 140
    p = Plate("radio_ham", W, H, seed=92, title="Premium Technologies two-way")
    d = p.d
    plate_body(p, "blackp", grain="pebble", seed=93, edge=None)
    p.label("PREMIUM TECHNOLOGIES  -  TWO-WAY  -  10-500 MHz", 120, 10, "paint_c", auto_ink=False)
    # the speaker grille
    for i in range(9):
        d.well(Mask(W, H).rrect(14 + i * 4, 24, 2, 96, 1).get(), 2.0, "rubber", bevel=0.6)
    radio_knob(p, 82, 60, 22, mat="blackp", skirt=None, pid="vol", label="VOL - PWR", label_y=90)
    display(p, "ham", 120, 24, 250, 62)
    for i, (pid, lab, icon) in enumerate((("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None), ("mic", "MIC", None), ("mute", "MUTE", None))):
        x = 120 + i * 48
        if icon:
            radio_key(p, pid, x, 96, 44, 17, None)
            d.text(lab, x + 15, 102, "paint_w", align="c", flatlight=True)
            arrow_icon(p, x + 30, 104.5, icon == "up", "paint_w")
        else:
            radio_key(p, pid, x, 96, 44, 17, lab, wear=0.12 if (worn and pid == "mic") else 0)
    d.dome(286, 121, 3.2, 3.2, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 286, 121, 3.0), "micMuted", "#ff3a2e")
    p.label("HOLD MEM TO NAME", 120, 122, "paint_c", auto_ink=False)
    radio_knob(p, 424, 54, 32, mat="blackp", skirt=1.6, ridges=40, pid="tune", label="DIAL", label_y=92)
    range_strip(p, 430, 120, w=84)
    if worn:
        WR.grime(d, d.solid, amount=0.28, seed=94)
        WR.scuffs(d, WR.mat_mask(d, "blackp"), 0.001, seed=95, amount=0.10)
    return p


def army(worn=True):
    W, H = 500, 150
    p = Plate("radio_army", W, H, seed=96, title="US Army two-way")
    d = p.d
    plate_body(p, "olive", grain="pebble", seed=97, edge=None)
    for (x, y) in ((7, 7), (W - 8, 7), (7, H - 8), (W - 8, H - 8)):
        screw_at(p, x, y, "olive")
    p.label("US ARMY COMM.", 22, 10, "paint_c", font="57", auto_ink=False)
    p.label("RADIO SET  -  TWO-WAY  -  10-500 MHz", 22, 22, "paint_c", auto_ink=False)
    radio_knob(p, 66, 84, 26, mat="blackp", pid="vol", label="VOL - PWR", label_y=118)
    display(p, "army", 120, 42, 250, 46)
    for i, (pid, lab, icon) in enumerate((("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None), ("mic", "MIC", None), ("mute", "MUTE", None))):
        x = 120 + i * 48
        if icon:
            radio_key(p, pid, x, 100, 44, 17, None)
            d.text(lab, x + 15, 106, "paint_w", align="c", flatlight=True)
            arrow_icon(p, x + 30, 108.5, icon == "up", "paint_w")
        else:
            radio_key(p, pid, x, 100, 44, 17, lab, wear=0.14 if (worn and pid in ("mic", "mem")) else 0)
    d.dome(286, 127, 3.2, 3.2, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 286, 127, 3.0), "micMuted", "#ff3a2e")
    p.label("HOLD MEM TO NAME", 120, 126, "paint_c", auto_ink=False)
    radio_knob(p, 432, 80, 32, mat="blackp", ridges=40, pid="tune", label="FREQ", label_y=118)
    range_strip(p, 432, 134, w=90, mat="blackp", ink="#ecead8")
    if worn:
        ol = WR.mat_mask(d, "olive")
        WR.grime(d, d.solid, amount=0.32, seed=98)
        WR.chips(d, WR.face(d, Z_FACE, ol), 0.006, seed=99, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=100, amount=0.12)
    return p


def hammake(switch_on=True, worn=True):
    W, H = 500, 138
    p = Plate("radio_hammake", W, H, seed=101, title="makeshift two-way")
    d = p.d
    pcb_board(p, 102)
    for pts in (((50, 38), (70, 38), (70, 60), (150, 60)), ((56, 82), (56, 70), (140, 70)), ((444, 70), (444, 60), (330, 60)),
                ((330, 30), (360, 30), (360, 16), (480, 16)), ((160, 108), (300, 108), (300, 120), (420, 120)), ((100, 44), (150, 44))):
        trace(p, pts, 1.0)
    for pts in (((360, 30), (400, 50), (470, 40)), ((110, 96), (130, 86), (160, 96)), ((50, 56), (90, 60), (120, 54))):
        trace(p, pts, 1.0, mat="paint_y" if pts[0][0] > 300 else "paint_r")
    for (x, y) in ((70, 38), (150, 60), (140, 70), (330, 60), (360, 16), (300, 108), (420, 120), (100, 44), (150, 44)):
        solder(p, x, y)
    p.label("HAM TX/RX", 14, 10, "paint_w", auto_ink=False)
    p.label("KEEP DRY", 380, 10, "paint_w", auto_ink=False)
    pcb_rocker(p, 22, 30, 24, 16, switch_on)
    p.label("PWR", 34, 50, "paint_w", align="c", auto_ink=False)
    display(p, "hammake", 158, 22, 164, 36, bezel="blackp")
    for i, (pid, lab) in enumerate((("chup", "CH+"), ("chdn", "CH-"), ("mem", "MEM"), ("mic", "MIC"), ("mute", "MUTE"))):
        tact(p, pid, 162 + i * 30, 76, 13, 13, lab)
    d.dome(318.5, 81, 3.0, 3.0, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 318.5, 81, 2.8), "micMuted", "#ff3a2e")
    chip(p, 340, 96, 20, 9, None); p.label("NE602", 350, 108, "paint_w", align="c", auto_ink=False, check=False)
    chip(p, 376, 96, 18, 9, None); p.label("LM386", 385, 108, "paint_w", align="c", auto_ink=False, check=False)
    resistor(p, 96, 112); resistor(p, 118, 120, ("paint_b", "paint_k", "paint_r"))
    pot(p, "vol", 56, 98, 16, "VOL")
    pot(p, "tune", 444, 92, 22, "DIAL")
    range_strip(p, 250, 124, w=84, mat="tape", ink="#1d2d7a")
    if worn:
        WR.grime(d, d.solid, amount=0.24, seed=103)
    return p


# =================================================================================== the siren controller
SIREN_ANGLES = (-60, -20, 20, 60)          # from straight up, clockwise (the switch's four positions)


def siren(worn=True):
    W, H = 440, 150
    p = Plate("siren", W, H, seed=104, title="siren controller")
    d = p.d
    plate_body(p, "blackp", grain="pebble", seed=105, edge=None)
    for (x, y) in ((7, 7), (W - 8, 7), (7, H - 8), (W - 8, H - 8)):
        screw_at(p, x, y, "steel")
    title = "SIREN CONTROLLER"
    tw = text_w(title)
    p.label(title, W // 2, 10, "paint_w", align="c", auto_ink=False)
    for x0, x1 in ((40, W // 2 - tw // 2 - 8), (W // 2 + tw // 2 + 8, W - 40)):
        d.paint(rbox(d, x0, 12, x1 - x0, 1), "paint_w", flatlight=True)
    groups = (("lights", "LIGHTS", 134, 100, (24, 54), "#5aa0ff", ("OFF", "1", "2", "3")),
              ("siren", "SIREN", 344, 100, (234, 54), "#ffb347", ("STANDBY", "YELP", "WAIL", "ALARM")))
    for gid, title_, kx, ky, (lx, ly), lc, words in groups:
        gx0 = kx - 122
        p.label(title_, gx0 + 12, 34, "paint_w", font="57", auto_ink=False)
        jewel(p, lx + 4, ly + 4, 3.6, off="jewel_off" if gid == "siren" else "jewel_off", bezel="chrome", on=Z_FACE)
        p.lamp(disc(d, lx + 4, ly + 4, 3.6), gid + "On", lc)
        fluted_knob(p, kx, ky, 25, on=Z_FACE, z=5.0, mat="blackp", skirt=2.0, skirt_mat="chrome", ridges=34, dome=1.0)
        scr = [a - 90 for a in SIREN_ANGLES]
        scale_ring(p, kx, ky, 29.5, scr, None, tick=3, mat="paint_w")
        for a, wd in zip(SIREN_ANGLES, words):
            ar = math.radians(a)
            cx_, cy_ = kx + 52 * math.sin(ar), ky - 52 * math.cos(ar)
            w_ = text_w(wd)
            x0, y0 = int(round(cx_ - w_ / 2)), int(round(cy_ - 2.5))
            p.check_flat(x0, y0, w_, 5, f"siren word {wd}")
            p.ink_rect(x0, y0, w_, 5, f"siren word {wd}")
            worn_text(d, wd, x0, y0, "paint_w", wear=0.10 if (worn and wd in ("WAIL", "1")) else 0, seed=x0 + y0)
            p.hit(f"{gid}:{SIREN_ANGLES.index(a)}", x0 - 3, y0 - 2, w_ + 6, 9)
        p.part("ptr", src=gid + "Mode", cx=kx, cy=ky, r0=4, r1=20, angles=scr, color="#f0f0f0", w=2)
        p.hit(gid + ":knob", kx - 25, ky - 25, 50, 50)
        p.meta.setdefault("groups", []).append({"id": gid, "x": gx0, "y": 28, "w": 206, "h": 112, "kx": kx, "ky": ky})
    if worn:
        WR.grime(d, d.solid, amount=0.30, seed=106)
        WR.scuffs(d, WR.mat_mask(d, "blackp"), 0.0015, seed=107, amount=0.10)
    return p


# =================================================================================== the displays' layouts (drawn live)
# Each field reads a string or number the radio's workings hand over (ZeD.RadioOps.displayReading: the same readings
# the approved display shows, blinking already applied):
#   band "FM" / "CD", big (the frequency, or the CD's elapsed time), unit "MHz", preset "P2", cdTag "CD" (a disc in),
#   tag (STORE n / SCAN / MUTE), bars (0..4 signal), line (the station or the CD's title, marching when too long),
#   ch "02", tx "TX OK" / "MIC OFF", l1 / l2 (the character displays' two lines).
STYLE = {   # colour, unlit-segment ghost
    "vfd": ("#62e6ff", "#0d2a33"), "amber": ("#ffb22e", "#2a1a06"), "led": ("#ff3a24", "#2a0806"),
    "lcd": ("#16190f", "#727d68"), "char": ("#1f2a0c", "#8b9e4c"),
}
LAYOUTS = {
    "premium": [
        {"t": "text", "src": "band", "x": 10, "y": 8, "font": "57"},
        {"t": "tri", "when": "cd", "x": 30, "y": 8, "size": 8},
        {"t": "seg", "src": "big", "x": 140, "y": 6, "cw": 14, "ch": 26, "pitch": 18, "st": 3, "n": 5, "ghost": True},
        {"t": "text", "src": "preset", "x": 148, "y": 8, "font": "57"},
        {"t": "text", "src": "unit", "x": 148, "y": 20, "font": "57"},
        {"t": "text", "src": "cdTag", "x": 222, "y": 8, "font": "57", "align": "r"},
        {"t": "text", "src": "tag", "x": 222, "y": 20, "font": "57", "align": "r"},
        {"t": "bars", "src": "bars", "x": 248, "y": 30, "n": 5, "bw": 4, "gap": 2, "h0": 4, "dh": 4},
        {"t": "text", "src": "line", "x": 10, "y": 42, "font": "57", "w": 270, "marquee": True},
    ],
    "valutech": [
        {"t": "text", "src": "tag", "x": 8, "y": 8, "font": "57"},
        {"t": "seg", "src": "big", "x": 120, "y": 7, "cw": 12, "ch": 24, "pitch": 16, "st": 3, "n": 5, "ghost": True},
        {"t": "text", "src": "band", "x": 144, "y": 8, "font": "57", "align": "r"},
    ],
    "makeshift": [
        {"t": "cells", "src": "l1", "x": 4, "y": 4, "cols": 17, "pitch": 8, "font": "57"},
        {"t": "cells", "src": "l2", "x": 4, "y": 19, "cols": 17, "pitch": 8, "font": "57", "marquee": True},
    ],
    "hammake": [
        {"t": "cells", "src": "l1", "x": 4, "y": 5, "cols": 20, "pitch": 8, "font": "57"},
        {"t": "cells", "src": "l2", "x": 4, "y": 20, "cols": 20, "pitch": 8, "font": "57", "marquee": True},
    ],
    "ham": [
        {"t": "text", "src": "chLabel", "x": 8, "y": 6, "font": "57"},
        {"t": "seg", "src": "ch", "x": 8, "y": 17, "cw": 9, "ch": 16, "pitch": 12, "st": 2, "n": 2, "align": "l", "ghost": True},
        {"t": "seg", "src": "big", "x": 46, "y": 6, "cw": 16, "ch": 30, "pitch": 22, "st": 3, "n": 6, "align": "l", "ghost": True},
        {"t": "text", "src": "unit", "x": 242, "y": 8, "font": "57", "align": "r"},
        {"t": "text", "src": "tx", "x": 242, "y": 22, "font": "57", "align": "r"},
        {"t": "text", "src": "line", "x": 8, "y": 48, "font": "57", "w": 234, "marquee": True},
    ],
    "army": [
        {"t": "text", "src": "chLabel", "x": 8, "y": 5, "font": "57"},
        {"t": "seg", "src": "ch", "x": 8, "y": 15, "cw": 9, "ch": 15, "pitch": 12, "st": 2, "n": 2, "align": "l", "ghost": True},
        {"t": "seg", "src": "big", "x": 52, "y": 4, "cw": 14, "ch": 25, "pitch": 20, "st": 3, "n": 6, "align": "l", "ghost": True},
        {"t": "text", "src": "unit", "x": 242, "y": 6, "font": "57", "align": "r"},
        {"t": "text", "src": "tx", "x": 242, "y": 17, "font": "57", "align": "r"},
        {"t": "text", "src": "line", "x": 8, "y": 34, "font": "57", "w": 234, "marquee": True},
    ],
}


def attach_layouts(p):
    for pp in p.parts:
        if pp["t"] == "radioDisplay":
            col, ghost = STYLE[pp["style"]]
            pp["color"], pp["ghost"], pp["fields"] = col, ghost, LAYOUTS[pp["kind"]]
    return p


def display_reading(kind, on=True, freq="98.4", name="KNOX TALK", preset=2, signal=True, cd=False, elapsed="3:42",
                    title="COMPACT DISC", tag=None, ch=2, tx="TX OK", has_media=False):
    """what the radio's workings hand the display (the same readings drawFM / drawHam show)"""
    if not on: return {}
    ham = kind in ("ham", "army", "hammake")
    if kind in ("makeshift",):
        l1 = "FM" + " " * max(1, 6 - len(freq)) + freq + "MHz"
        l1 = l1 + " " * max(1, 17 - len(l1) - 4) + ("||||" if signal else "")
        return {"l1": l1, "l2": tag or name.upper()}
    if kind == "hammake":
        return {"l1": f"CH{ch:02d} {freq} MHz", "l2": tag or name.upper()}
    if ham:
        return {"chLabel": "CH", "ch": f"{ch:02d}", "big": freq, "unit": "MHz", "tx": tx, "line": tag or name.upper()}
    r = {"band": "CD" if cd else "FM", "cd": cd, "big": elapsed if cd else freq, "unit": "" if cd else "MHz",
         "preset": (f"P{preset}" if (preset and not cd) else ""), "cdTag": "CD" if (has_media and not cd) else "",
         "tag": tag or "", "bars": 4 if (signal and not cd) else 0, "line": (title if cd else name).upper()}
    if kind == "valutech":
        r = {"big": freq, "band": "FM", "tag": tag or (f"P{preset}" if preset else "")}
    return r
