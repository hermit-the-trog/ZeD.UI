"""The walkie-talkies and the ManPack at the half card's four panel widths (REQUEST_design_plates_fill_20261030.md:
154, 180, 206 and 257 px). W is the PANEL width from the fit table; the face is W - 20, today's 10 px margins either
side kept (today: 220 panel, 200 face). At W=220 each reproduces d_walkie exactly.

The rule is the same as the ovens', with one difference the narrow panels force: the knobs, lamps, screws and the talk
key's switch keep their size, the display and the pads take the width, labels stay centred -- but the key pads (text
on a pad) scale with the face, so three still fit across a 134 px face (154 panel). Their labels are the fixed small
font either way.
"""
from d_walkie import *            # noqa: F401,F403
from d_walkie import WALKIE_H, MANPACK_H, face_body, tx_led, face_knob, display, lay_walkie, lay_drum, lay_char, \
    slot_grille, round_key, keypad, ptt_key, worn, value_face as _vf, corner_screws   # noqa: F401
import d_props as PR
import wear as WR

F0 = 200                  # today's face
PANEL0 = 220


def _geom(W):
    F = W - 20
    s = F / F0
    X = lambda x: int(round(x * s))          # a horizontal position scaled with the face
    return F, s, X


def toy(W=PANEL0, worn_=True):
    F, s, X = _geom(W)
    p = Plate("walkie_toy", F, WALKIE_H, seed=201, title="Toys-R-Mine Walkie Talkie")
    d = p.d
    face_body(p, "wt_char", r=22, seed=202)
    tx_led(p, F - 16, 16)
    face_knob(p, "vol", X(40), 46, 15, "VOL - ON")
    face_knob(p, "tune", X(160), 46, 15, "TUNE")
    dx = X(40); dw = F - 2 * dx
    display(p, "toy", "drum", dx, 90, dw, 17, lay_drum(dw), bezel="blackp")
    slot_grille(p, F // 2, 172, X(62), 46, vertical=True)
    d.dome(F // 2, 252, 22, 22, 3.4, "wt_red", polish=0.7, on=Z_FACE)                  # TALK
    d.torus(F // 2, 252, 22, 25, 1.2, "blackp", polish=0.5, on=Z_FACE)
    d.text("TALK", F // 2, 250, "paint_w", align="c", font="57", flatlight=True)
    p.hit("mic", F // 2 - 24, 228, 48, 48)
    sx = X(22)
    st = Mask(p.W, p.H).rrect(sx, 288, F - 2 * sx, 50, 5).get()
    d.slab(st, 0.3, "enamel_white", bevel=0.6, polish=0.6, on=Z_FACE)
    cols = ("paint_r", "paint_b", "paint_y", "paint_g", "paint_k", "paint_r", "paint_k", "paint_b", "paint_y", "paint_g", "paint_r")
    for i, (ch, col) in enumerate(zip("TOYS-R-MINE", cols)):
        d.text(ch, F // 2 - 44 + i * 8, 296, col, font="57", flatlight=True)
    d.text("2-WAY", F // 2, 310, "paint_k", align="c", font="57", flatlight=True)
    d.text("AGES 8 AND UP", F // 2, 326, "paint_k", align="c", flatlight=True)
    for (x, y) in ((14, 348), (F - 15, 348)): screw(p, x, y, on=Z_FACE, mat="steel")
    if worn_: worn(p, "wt_char", 203)
    return p


def value_face(p, surround, brand, sub, seed):
    F = p.W; _, s, X = _geom(F + 20)
    d = p.d
    face_body(p, "wt_char", r=18, seed=seed)
    tx_led(p, F - 16, 14)
    p.label(brand, F // 2, 10, "paint_w", align="c", font="57", auto_ink=False)
    face_knob(p, "vol", X(40), 46, 15, "VOL - PWR")
    face_knob(p, "tune", X(160), 46, 15, "TUNE")
    dm = 24 if F >= 160 else 13                      # a narrow face pulls the display's margins in (the readout needs ~106)
    sur = Mask(p.W, p.H).rrect(dm - 10, 84, F - 2 * dm + 20, 98, 8).get()
    d.slab(sur, 1.6, surround, bevel=1.4, polish=0.7, on=Z_FACE)
    display(p, "walkie", "lcd_light", dm, 93, F - 2 * dm, 44, lay_walkie(F - 2 * dm), bezel="blackp")
    zs = Z_FACE + 1.6
    round_key(p, "chdn", X(56), 162, 8, on=zs, icon="down")
    round_key(p, "mem", F // 2, 162, 6, on=zs, icon="M")
    round_key(p, "chup", X(144), 162, 8, on=zs, icon="up")
    slot_grille(p, F // 2, 228, X(74), 30, vertical=False)
    ptt_key(p, 30, 270, F - 60, 26, mat="wt_red")
    p.label(sub, F // 2, 308, "paint_c", align="c", auto_ink=False)
    p.label("HOLD M TO NAME", F // 2, 320, "paint_c", align="c", auto_ink=False)
    for (x, y) in ((14, 346), (F - 15, 346)): screw(p, x, y, on=Z_FACE, mat="steel")
    return p


def valutech(W=PANEL0, worn_=True):
    p = Plate("walkie_valutech", W - 20, WALKIE_H, seed=211, title="ValuTech Walkie Talkie")
    value_face(p, "wt_yellow", "VALUTECH", "2-WAY  -  50-200 MHZ", 212)
    if worn_: worn(p, "wt_char", 213)
    return p


def premium(W=PANEL0, worn_=True):
    p = Plate("walkie_premium", W - 20, WALKIE_H, seed=221, title="Premium Tech. Walkie Talkie")
    value_face(p, "wt_red", "PREMIUM TECH.", "2-WAY  -  25-300 MHZ", 222)
    if worn_: worn(p, "wt_char", 223, grime=0.16, scuffs=0.06)
    return p


def tactical(W=PANEL0, worn_=True):
    F, s, X = _geom(W)
    p = Plate("walkie_tactical", F, WALKIE_H, seed=231, title="Tactical Walkie Talkie")
    d = p.d
    face_body(p, "wt_tac", r=14, seed=232)
    tx_led(p, F // 2, 14)
    face_knob(p, "vol", X(40), 46, 16, "VOL - PWR")
    face_knob(p, "tune", X(160), 46, 14, "TUNE", ridges=24)
    slot_grille(p, F // 2, 104, X(78), 18, vertical=False)
    dm = 22 if F >= 160 else 12
    display(p, "walkie", "lcd_amber", dm, 134, F - 2 * dm, 44, lay_walkie(F - 2 * dm), bezel="blackp", lamp="#ffd88a")
    kw = (F - 2 * dm - 12) // 3
    keypad(p, dm + (F - 2 * dm - 3 * kw - 12) // 2, 192, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None),
                        ("scan", "SCAN", None), ("mute", "MUTE", None), ("lamp", "LAMP", None)],
           kw=kw, kh=16, gx=6, gy=6, mark="paint_r")
    ptt_key(p, dm, 242, F - 2 * dm, 26, mat="wt_ptt_grey")
    p.label("TACTICAL", F // 2, 278, "paint_c", align="c", font="57", auto_ink=False)
    p.label("HOLD MEM TO NAME", F // 2, 292, "paint_c", align="c", auto_ink=False)
    for k in range(3):
        d.well(Mask(p.W, p.H).rrect(26, 306 + k * 12, F - 52, 4, 2).get(), 1.0, None, bevel=0.6)    # grip ribs
    if worn_: worn(p, "wt_tac", 233, grime=0.28, scuffs=0.12)
    return p


def army(W=PANEL0, worn_=True):
    F, s, X = _geom(W)
    p = Plate("walkie_army", F, WALKIE_H, seed=241, title="US Army Walkie Talkie")
    d = p.d
    face_body(p, "wt_army", r=12, seed=242)
    face_knob(p, "vol", X(40), 46, 16, "VOL - PWR")
    face_knob(p, "tune", X(160), 46, 14, "TUNE", ridges=24)
    p.label("US ARMY", F // 2, 40, "paint_c", align="c", font="57", auto_ink=False)
    for k in range(3):
        d.well(Mask(p.W, p.H).rrect(14 + k * 7, 84, 3, 46, 1).get(), 1.2, None, bevel=0.6)              # the grooves
    slot_grille(p, 112 + (F - F0) // 2, 107, 68 + (F - F0) // 2, 24, vertical=False, pitch=5, slot=3)
    dm = 20 if F >= 160 else 12
    display(p, "walkie", "lcd_yg", dm, 146, F - 2 * dm, 44, lay_walkie(F - 2 * dm), bezel="blackp", lamp="#e2f59a")
    kw = (F - 2 * dm - 16) // 3
    keypad(p, dm + (F - 2 * dm - 3 * kw - 16) // 2, 204, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None),
                        ("scan", "SCAN", None), ("mute", "MUTE", None), ("lamp", "LAMP", None)],
           kw=kw, kh=16, gx=8, gy=6, mat="blackp")
    ptt_key(p, dm, 252, F - 2 * dm, 24, mat="blackp")
    tx_led(p, X(92), 288)
    p.label("TX", X(92) + 6, 286, "paint_c", auto_ink=False)
    lines = ["RADIO SET  -  TWO-WAY", "200 KHZ - 1000 MHZ", "RANGE 16 KM  -  HOLD MEM TO NAME"] if F >= F0 else \
            ["RADIO SET - 2-WAY", "200 KHZ-1000 MHZ", "HOLD MEM TO NAME"]          # the short plate on the narrow faces
    data_plate(p, 24, 300, F - 48, 36, lines, on=Z_FACE, mat="blackp", ink="paint_c", rivets=True)
    if worn_:
        ol = WR.mat_mask(d, "wt_army")
        WR.grime(d, d.solid, amount=0.30, seed=243)
        WR.chips(d, WR.face(d, Z_FACE, ol), 0.004, seed=244, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=245, amount=0.12)
    return p


def makeshift(W=PANEL0, worn_=True):
    F, s, X = _geom(W)
    p = Plate("walkie_makeshift", F, WALKIE_H, seed=251, title="Makeshift Walkie Talkie")
    d = p.d
    face_body(p, "wt_char", r=22, seed=252)
    PR.pot(p, "vol", X(40), 46, 11)
    PR.pot(p, "tune", X(160), 46, 11)
    d.text("VOL", X(40), 64, "paint_w", align="c", flatlight=True)
    d.text("TUNE", X(160), 64, "paint_w", align="c", flatlight=True)
    brd = Mask(p.W, p.H).rrect(16, 80, F - 32, 98, 2).get()
    d.slab(brd, 1.4, "pcb", bevel=0.8, polish=0.5, on=Z_FACE)
    d.grain_pebble(brd, 0.03, seed=253)
    zb = Z_FACE + 1.4
    tw, dx0 = (22, 46) if F >= 176 else (6, 24)      # the tape strips and where the module starts (thin tape below 176, so the module keeps 10+ cells)
    cols = (F - 2 * dx0 - 4) // 8                    # the character module between the two tapes
    display(p, "walkiechar", "char", dx0, 90, cols * 8 + 4, 26, lay_char(cols), bezel="blackp")
    for i, (pid, lab) in enumerate((("chdn", "CH-"), ("mem", "MEM"), ("chup", "CH+"))):
        x = X(60 + i * 40) - 6
        PR.tact(p, pid, x, 128, 12, 12, None)
        d.text(lab, x + 6, 144, "paint_w", align="c", flatlight=True)
    PR.resistor(p, X(120), 166); PR.solder(p, X(54), 166); PR.solder(p, X(54) + 8, 166)
    PR.trace(p, ((X(54), 166), (X(54) + 8, 166), (X(54) + 8, 160), (X(112), 160)))
    tx_led(p, X(150), 166, on=zb)
    for (x, y, w, h) in ((18, 76, tw, 106), (F - 18 - tw, 76, tw, 106)):
        t = Mask(p.W, p.H).rect(x, y, w, h).get()
        d.slab(t, 0.5, "duct", bevel=0.4, polish=0.5, on="cur")
        for yy in range(y + 3, y + h, 9): d.dark[yy, x + 1:x + w - 1] += 0.04
    slot_grille(p, F // 2, 226, X(58), 34, vertical=True)
    # the talk key: a big microswitch, taped down (the switch is a part: it keeps its size)
    sw = Mask(p.W, p.H).rrect(F // 2 - 44, 272, 88, 30, 2).get()
    d.slab(sw, 2.0, "steel", bevel=0.8, polish=0.8, on=Z_FACE)
    d.dome(F // 2, 287, 16, 9, 2.4, "blackp", polish=0.6, on=Z_FACE + 2.0)
    for x in (F // 2 - 56, F // 2 + 40):
        t = Mask(p.W, p.H).rect(x, 280, 16, 14).get()
        d.slab(t, 0.5, "duct", bevel=0.4, polish=0.5, on="cur")
    d.text("PTT", F // 2, 285, "paint_w", align="c", flatlight=True)
    p.hit("mic", F // 2 - 44, 272, 88, 30)
    lbl = Mask(p.W, p.H).rect(F // 2 - 34, 314, 68, 14).get()
    d.slab(lbl, 0.5, "tape", bevel=0.4, polish=0.4, on=Z_FACE)
    d.text("HOLD MEM", F // 2, 317, "paint_b", align="c", flatlight=True)
    for (x, y) in ((14, 348), (F - 15, 348)): screw(p, x, y, on=Z_FACE, mat="steel")
    if worn_: worn(p, "wt_char", 254, grime=0.30, scuffs=0.14)
    return p


def manpack(W=PANEL0, worn_=True):
    F, s, X = _geom(W)
    p = Plate("walkie_manpack", F, MANPACK_H, seed=261, title="US ARMY COMM. Manpack Radio")
    d = p.d
    body = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, 6).get()
    d.slab(body, Z_FACE, "mp_olive", bevel=2.4, polish=0.35)
    d.grain_pebble(body, 0.04, seed=262)
    chrome_frame(d, 4, 4, p.W - 8, p.H - 8, Z_FACE - 0.4, t=1, mat="mp_olive", z=0.8)
    corner_screws(p, inset=9, mat="mp_olive")
    p.label("US ARMY COMM.", 18, 14, "paint_c", font="57", auto_ink=False)
    p.label("MANPACK RADIO SET", 18, 25, "paint_c", auto_ink=False)
    so = 0 if F >= 160 else 12                       # the sockets sit closer to the edge on a narrow face
    for x in (F - 50 + so, F - 26 + so):
        d.torus(x, 20, 4.0, 8.0, 2.4, "steel", polish=0.9, on=Z_FACE)
        d.dome(x, 20, 4.0, 4.0, -1.5, "hole", polish=0.2, on=Z_FACE)
    p.label("AUDIO", F - 38 + so, 32, "paint_c", align="c", auto_ink=False)
    dm = 20 if F >= 160 else 12
    display(p, "walkie", "lcd_cyan", dm, 46, F - 2 * dm, 44, lay_walkie(F - 2 * dm), bezel="blackp")
    face_knob(p, "vol", X(52), 124, 22, "VOL - PWR", ink="paint_c")
    face_knob(p, "tune", X(148), 124, 22, "FREQ", ink="paint_c", ridges=36)
    kw = (F - 2 * dm - 12) // 2
    keypad(p, dm + (F - 2 * dm - 2 * kw - 12) // 2, 166, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None), ("mute", "MUTE", None)],
           kw=kw, kh=16, gx=12, gy=6, cols=2, mat="blackp")
    ptt_key(p, dm, 212, F - 2 * dm, 26, mat="rubber")
    tx_led(p, 30, 254)
    p.label("TX", 36, 252, "paint_c", auto_ink=False)
    p.label("RANGE 20 KM", F - 20, 252, "paint_c", align="r", auto_ink=False)
    if worn_:
        ol = WR.mat_mask(d, "mp_olive")
        WR.grime(d, d.solid, amount=0.32, seed=263)
        WR.chips(d, WR.face(d, Z_FACE, ol), 0.006, seed=264, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=265, amount=0.12)
    return p


WIDE = {"walkie_toy": toy, "walkie_valutech": valutech, "walkie_premium": premium, "walkie_tactical": tactical,
        "walkie_army": army, "walkie_makeshift": makeshift, "walkie_manpack": manpack}
PANELS = (154, 180, 206, 257)       # the half card's fit table; today's 220 is the check width
