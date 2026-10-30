"""MOCKUP (Oct 29 2026): the three tabletop ham sets' main faces at 336 px (PLATE_SIZES_SPEC.md).
Same parts and state wiring as d_walkie's ham_civ / ham_army / ham_make; the speaker gives up most of the width."""
from d_walkie import *            # noqa: F401,F403
import numpy as np

HW, HH = 336, 172


def cursor_disc(p, cx, cy, r_disc, knob_r, a0=-205, a1=25):
    """the clear acrylic cursor disc under the tuning knob: it turns with the knob, the red hairline printed on it
    reads the band arc through it (director, Oct 29 2026). Replaces arc_dial's free marker; the knob's own pointer
    follows the same angle, so the two always agree."""
    d = p.d
    if p.parts and p.parts[-1].get("src") == "bandF": p.parts.pop()          # arc_dial's marker: now on the disc
    fm = disc(d, cx, cy, r_disc)
    d.h[fm] += 0.9                                                         # a sheet of acrylic, proud of the panel
    d.polish[fm] = np.maximum(d.polish[fm], 0.85)
    d.tex[fm] += 0.025
    glare(d, fm, slope=-0.6, width=max(3, r_disc // 4), offset=0.20, amount=0.07)
    p.part("ptr", src="bandF", cx=cx, cy=cy, r0=knob_r + 2, r1=r_disc - 2, a0=a0, a1=a1, color="#e0301e", w=1)


def drilled_grille(p, cx, cy, r, pitch=6, seed=7):
    """a speaker grille drilled by hand straight into the board (director, Oct 29 2026): no ring; a pencilled grid
    that wanders, holes a little off their marks and not all the same bit, a couple skipped"""
    import random
    rnd = random.Random(seed)
    d = p.d
    n = int(r // pitch) + 1
    for j in range(-n, n + 1):
        row_drift = rnd.uniform(-0.6, 0.6)                       # each pencilled row a little off level
        for i in range(-n, n + 1):
            big = rnd.random() < 0.2                                # a few with the bigger bit
            off = 0.5 if big else 0.0                               # 3 x 3 holes sit on a pixel, 2 x 2 on a corner
            x = round(cx + i * pitch + row_drift * 0.5 + rnd.gauss(0, 0.5)) + off     # whole pixels: clean drill marks
            y = round(cy + j * pitch + row_drift + rnd.gauss(0, 0.5)) + off
            if math.hypot(x - cx, y - cy) > r - 2: continue
            if rnd.random() < 0.03: continue                     # skipped
            hr = 1.5 if big else 0.75
            d.well(disc(d, x, y, hr), 1.6, "mesh", bevel=0.3)


add_ramp("dymo_red", "#b3202a", light=1.05)         # embossing tape: glossy red vinyl
add_ramp("dymo_white", "#f2e8e4", light=1.05)       # the letters, whitened where the wheel stretched the plastic


def dymo(p, t, x, y, align="c", seed=0):
    """a label punched on an old wheel-and-tape embosser (director, Oct 29 2026): red vinyl strip, raised white
    capitals spaced wide, cut square at both ends, stuck on by hand (now and then a pixel off level)"""
    import random
    d = p.d
    rnd = random.Random(hash((t, seed)) & 0xffff)
    tw = text_w(t, "35", gap=2)
    w, h = tw + 6, 9
    x0 = x - w // 2 if align == "c" else (x - w if align == "r" else x)
    y0 = y - 2 + rnd.choice((0, 0, 0, 1, -1))
    strip = Mask(p.W, p.H).rect(x0, y0, w, h).get()
    d.slab(strip, 0.6, "dymo_red", bevel=0.4, polish=0.85, on=Z_FACE)
    d.text(t, x0 + 3, y0 + 2, "dymo_white", gap=2, raise_=0.4, flatlight=True)
    p.ink_rect(x0, y0, w, h, f"label tape '{t}'")
    return x0, y0, w, h


def knob_reads_band(p, cx, cy, a0=-205, a1=25):
    """the tuning knob's pointer turns through the band's sweep (bandF), not a free 360"""
    for pt in p.parts:
        if pt.get("src") == "tuneF" and pt.get("cx") == cx and pt.get("cy") == cy:
            pt.update(src="bandF", a0=a0, a1=a1)


def ham_civ(worn_=True):
    p = Plate("ham_civilian", HW, HH, seed=301, title="Premium Technologies Ham Radio")
    d = p.d
    face = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, 3).get()
    d.slab(face, Z_FACE, "ham_silver", bevel=2.4, polish=0.7)
    d.grain_brushed(face, 0.04, seed=302)
    chrome_frame(d, 3, 3, p.W - 6, p.H - 6, Z_FACE - 0.4, t=1, mat="ham_silver", z=0.7)
    corner_screws(p, inset=9)
    p.label("PREMIUM TECHNOLOGIES", 16, 12, "paint_k", font="57", auto_ink=False)
    p.label("TWO-WAY  -  10-500 MHZ", 16, 23, "paint_k", auto_ink=False)
    arc_dial(p, 62, 100, 34, 40)
    cursor_disc(p, 62, 100, 42, 28)
    PR.radio_knob(p, 62, 100, 26, mat="blackp", skirt=1.4, ridges=40, pid="tune", label="DIAL", label_y=147, lab_mat="paint_k")
    knob_reads_band(p, 62, 100)
    d.dome(120, 42, 3.2, 3.2, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 120, 42, 3.0), "radioOn", "#ff3a2e")
    p.label("PWR", 120, 48, "paint_k", align="c", auto_ink=False)
    PR.radio_knob(p, 120, 84, 13, mat="blackp", pid="vol", label="VOL", label_y=101, lab_mat="paint_k")
    dx = 146
    display(p, "walkie", "lcdgrey", dx, 30, 120, 44, lay_walkie(120), bezel="blackp")
    keypad(p, dx, 86, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None)], kw=36, kh=15, gx=6, mat="hamgrey")
    p.label("HOLD MEM TO NAME", dx, 106, "paint_k", auto_ink=False)
    toggle_key(p, "mic", dx, 124, 36, 13, "MIC")
    toggle_key(p, "mute", dx + 42, 124, 36, 13, "MUTE")
    toggle_key(p, "scan", dx + 84, 124, 36, 13, "SCAN")
    dot_grille(p, 298, 68, 25)
    PR.range_strip(p, 298, 122, w=54, mat="blackp", ink="#ecead8")
    mic_jack(p, 298, 144)
    if worn_:
        WR.grime(d, face, amount=0.18, seed=303)
        WR.scuffs(d, WR.mat_mask(d, "ham_silver"), 0.001, seed=304, amount=0.08)
    return p


def ham_army(worn_=True):
    p = Plate("ham_army", HW, HH, seed=311, title="US ARMY COMM. Ham Radio")
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
    arc_dial(p, 60, 106, 30, 36, labels=("0.2", "250", "500", "1000"))
    cursor_disc(p, 60, 106, 38, 22)
    PR.radio_knob(p, 60, 106, 22, mat="blackp", ridges=40, pid="tune", label="FREQ", label_y=147)
    knob_reads_band(p, 60, 106)
    for i in range(6):
        PR.radio_key(p, f"p{i + 1}", 116 + (i % 3) * 18, 62 + (i // 3) * 18, 14, 13, str(i + 1), mat="blackp", z=1.6)
    p.label("MEM", 141, 100, "paint_c", align="c", auto_ink=False)
    PR.radio_knob(p, 132, 132, 12, mat="blackp", pid="vol", label=None)
    p.label("VOL", 150, 130, "paint_c", auto_ink=False)
    dx, dw = 178, 106
    display(p, "walkie", "led", dx, 26, dw, 44, lay_walkie(dw), bezel="blackp", lens=True)
    p.label("HOLD MEM TO NAME", dx, 78, "paint_c", auto_ink=False)
    toggle_key(p, "mic", dx, 94, 34, 13, "MIC", ink="paint_c")
    toggle_key(p, "mute", dx + 36, 94, 34, 13, "MUTE", ink="paint_c")
    toggle_key(p, "scan", dx + 72, 94, 34, 13, "SCAN", ink="paint_c")
    PR.range_strip(p, dx + dw // 2, 138, w=dw, mat="blackp", ink="#ecead8")
    for k in range(9):
        d.well(Mask(p.W, p.H).rrect(292, 24 + k * 9, 26, 4, 2).get(), 1.6, "mesh", bevel=0.6)              # the speaker
    mic_jack(p, 305, 128, mat="steel", ink="paint_c")
    for (x, y) in ((5, 5), (p.W - 6, 5), (5, p.H - 6), (p.W - 6, p.H - 6)): screw(p, x, y, on=Z_FACE + 1.0, mat="ham_olive")
    if worn_:
        ol = WR.mat_mask(d, "ham_olive")
        WR.grime(d, d.solid, amount=0.30, seed=313)
        WR.chips(d, WR.face(d, Z_FACE + 1.0, ol), 0.006, seed=314, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=315, amount=0.12)
    return p


def ham_make(worn_=True, mic_live=False):
    p = Plate("ham_makeshift", HW, HH, seed=321, title="Makeshift Ham Radio")
    d = p.d
    crate = Mask(p.W, p.H).rect(0, 0, p.W, p.H).get()
    d.slab(crate, Z_FACE + 1.4, "crate", bevel=1.4, polish=0.25)
    d.grain_wood(crate, 1.0, seed=322)
    board = Mask(p.W, p.H).rect(12, 12, p.W - 24, p.H - 24).get()
    d.slab(board, Z_FACE, "crate_face", bevel=0.8, polish=0.3, on=0.0)
    d.grain_wood(board, 0.6, seed=323)
    for (x, y) in ((6, 6), (p.W - 7, 6), (6, p.H - 7), (p.W - 7, p.H - 7)): screw(p, x, y, on=Z_FACE + 1.4, mat="steel")
    display(p, "hamchar", "char", 26, 26, 16 * 8 + 4, 26, lay_char(16), bezel="blackp")
    d.dome(172, 32, 3.0, 3.0, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 172, 32, 2.8), "radioOn", "#ff3a2e")
    for i, (pid, lab) in enumerate((("chdn", "CH-"), ("mem", "MEM"), ("chup", "CH+"))):
        x = 32 + i * 40
        PR.tact(p, pid, x, 70, 12, 12, None)
        dymo(p, lab, x + 6, 87)
    PR.pot(p, "tune", 158, 76, 10)
    PR.pot(p, "vol", 190, 76, 10)
    dymo(p, "TUNE", 158, 93)
    dymo(p, "VOL", 190, 93)
    bat_toggle(p, 46, 126, mic_live, on=Z_FACE)
    p.hit("mic", 38, 114, 16, 24)
    dymo(p, "TALK", 60, 118, align="l")
    dymo(p, "LISTEN", 60, 131, align="l")
    PR.radio_key(p, "mute", 112, 120, 30, 13, None, mat="blackp", z=2.2)
    dymo(p, "MUTE", 127, 138)
    dymo(p, "HOLD MEM", 186, 123)
    mic_jack(p, 222, 76, mat="steel", tip="blackp", label=None)
    dymo(p, "MIC", 222, 87)
    drilled_grille(p, 278, 88, 38)
    if worn_:
        WR.grime(d, d.solid, amount=0.26, seed=324)
    return p


MOCK = {"ham_civilian": ham_civ, "ham_army": ham_army, "ham_makeshift": ham_make}
