"""MOCKUP (Oct 29 2026): the 200 px narrow faces (PLATE_SIZES_SPEC.md), for the smallest settings only: fixed UI
scale 0.5, or Auto on a 720 or 800 screen with the 16 px font. Every face keeps its main face's click areas, kinds and
live parts, so the game treats them alike; the layouts are rearranged, not shrunk (the ham sets' narrow faces, Oct 25,
are the pattern)."""
import numpy as np
from scipy import ndimage as ndi

from d_ovens import *            # noqa: F401,F403
import d_micro as DM
import d_gen as DG
import d_grill as DGR
import m_brands as MB
import m_ham as MH
from physlib import *            # noqa: F401,F403
from engine import add_ramp
from d_walkie import (display, lay_walkie, lay_char, arc_dial, dot_grille, keypad, toggle_key, mic_jack, corner_screws,
                      PR, NARROW_W)

NW = 200


# =================================================================================== ranges
def green_range_n(units="F", on=False, worn=True):
    """the burners across the top under the maker, the control centre full width below"""
    W, H = NW, 206
    p = Plate("oven_green_n", W, H, seed=11, title="1956 range (narrow)")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 6).get()
    d.slab(body, Z_FACE, "enamel_mint", bevel=3.0, polish=0.75)
    spears = d.cyl(10, 5, W - 20, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    spears |= d.cyl(10, H - 8, W - 20, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    mx_, my_, mw_, mh_ = MB.mg_monogram(p, 60, 19)
    p.label("MASS-GENFAC CO.", mx_ + mw_ + 4, 17, "mg_blue", auto_ink=False)
    for bx, which in ((30, "LR"), (76, "LF"), (124, "RF"), (170, "RR")):
        by = 54
        kn = fluted_knob(p, bx, by, 10, on=Z_FACE, dome=0.9 if worn else 0.0)
        baked_pointer(p, kn, -90, 1, 8)
        scale_ring(p, bx, by, 13.5, [-90, 180, 45], ["OFF", "HI", "LO"], minor_angles=[150, 120, 90, 67], wear=0.22 if worn else 0)
        burner_icon(p, bx - 3, by + 19, which)
        p.hit("burner" + which, bx - 12, by - 12, 24, 24, kind="look")
    cx0, cy0, cw, ch = 10, 88, W - 20, H - 104
    F = Z_FACE + 1.2
    cc = rbox(d, cx0, cy0, cw, ch)
    d.flat(cc, F, "alu", polish=0.5); d.grain_brushed(cc, 0.05 if worn else 0.03, seed=4)
    chrome_frame(d, cx0 - 2, cy0 - 2, cw + 4, ch + 4, Z_FACE, t=2, mat="chrome", z=2.0)
    clx, cly = cx0 + 34, cy0 + 40
    clock_face(p, clx, cly, 28, face="cream", on=F, depth=1.6)
    p.part("clock", cx=clx, cy=cly, rh=13, rm=21, color="#1c1b17")
    mx, my = cx0 + 96, cy0 + 26
    fluted_knob(p, mx, my, 9, on=F, dome=0.9 if worn else 0.0)
    minutes_scale(p, mx, my, 13.5, wear=0.10 if worn else 0)
    p.label("MINUTE MINDER", mx, my + 27, "paint_k", align="c")
    p.part("ptr", src="timerF", cx=mx, cy=my, r0=1, r1=7, a0=-90, a1=210, color="#7a1a12", w=1)
    p.hit("timer", mx - 13, my - 13, 26, 26, needs="powered", kind="turn")
    ox, oy = cx0 + 150, my
    fluted_knob(p, ox, oy, 9, on=F, dome=0.9 if worn else 0.0)
    thermostat_scale(p, ox, oy, 13.5, units, wear=0.12 if worn else 0)
    p.label("OVEN", ox, oy + 27, "paint_k", align="c")
    p.part("ptr", src="ovenStop", cx=ox, cy=oy, r0=1, r1=7, angles=OVEN_STOP_ANGLES, color="#7a1a12", w=1)
    p.hit("heat", ox - 13, oy - 13, 26, 26, needs="powered", kind="turn")
    ky = my + 44
    keys = piano_keys(p, mx + 6, ky, ["ON", "OFF"], 20, 11, 0 if on else 1, mat="cream", on=F)
    p.hit("on", *keys[0], needs="powered"); p.hit("off", *keys[1], needs="powered")
    jewel(p, mx + 60, ky + 5, 4.0, on=F)
    p.lamp(disc(d, mx + 60, ky + 5, 4.0), "on", "#ffa630")
    if worn:
        en = WR.mat_mask(d, "enamel_mint")
        WR.gloss(d, en, band=(0.31, 30, 10, 0.13))
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 100, 20, 0.105, 150, 190, 0.045)
        WR.grime(d, d.solid, amount=0.30, seed=5)
        WR.chips(d, WR.face(d, Z_FACE, body), 0.004, seed=7, near=2.5)
        WR.pits(d, spears, 0.003, seed=9)
        WR.aged_face(d, clx, cly, 28, amount=0.12)
    return p


def red_range_n(units="F", worn=True):
    """the push buttons two by two in their strip; the oven selector and thermostat, then the timer and the lamp
    over the maker"""
    W, H = NW, 244
    p = Plate("oven_red_n", W, H, seed=12, title="1962 range (narrow)")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 5).get()
    d.slab(body, Z_FACE, "enamel_red", bevel=3.0, polish=0.75)
    trim = d.cyl(8, 4, W - 16, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    trim |= d.cyl(8, H - 7, W - 16, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    sx0, sy0, sw, sh = 12, 11, W - 24, 84
    F = Z_FACE + 1.0
    strip = rbox(d, sx0, sy0, sw, sh)
    d.flat(strip, F, "alu", polish=0.5); d.grain_brushed(strip, 0.05 if worn else 0.03, seed=14)
    chrome_frame(d, sx0 - 1, sy0 - 1, sw + 2, sh + 2, Z_FACE, t=1, mat="chrome", z=1.6)
    for k, which in enumerate(("LR", "RR", "LF", "RF")):
        gcx = sx0 + (sw // 4 if k % 2 == 0 else 3 * sw // 4)
        gy = sy0 + 2 + (k // 2) * 40
        gx0 = gcx - 29
        burner_icon(p, gcx - 3, gy + 2, which)
        piano_keys(p, gx0, gy + 14, ["", "1", "2", "3", "4", "HI"], 9, 13, 0, mat="enamel_white", on=F, frame="chrome",
                   mats=["bakelite", "enamel_white", "enamel_white", "enamel_white", "enamel_white", "enamel_white"])
        p.label("OFF", gx0 + 4, gy + 32, "paint_k", align="c", wear=0.15 if worn else 0)
        p.label("HI", gx0 + 54, gy + 32, "paint_k", align="c")
        p.hit("burner" + which, gx0, gy + 14, 59, 13, kind="look")
    ky = 132
    xs = (52, 146)
    insert_knob(p, xs[0], ky, 9, on=Z_FACE, insert_r=2.6)
    scale_ring(p, xs[0], ky, 13.5, [-90, -30, 30], ["OFF", "BAKE", "BROIL"], mat="paint_c", wear=0.10 if worn else 0)
    p.label("OVEN", xs[0], ky + 27, "paint_c", align="c", auto_ink=False)
    p.part("ptr", src="switched", cx=xs[0], cy=ky, r0=3.5, r1=7.5, angles=[-90, -30], color="#ece6d4", w=1)
    p.hit("onoff", xs[0] - 13, ky - 13, 26, 26, needs="powered")
    insert_knob(p, xs[1], ky, 11, on=Z_FACE, insert_r=3.0)
    thermostat_scale(p, xs[1], ky, 15.5, units, mat="paint_c", wear=0.10 if worn else 0)
    p.label("TEMPERATURE", xs[1], ky + 31, "paint_c", align="c", auto_ink=False)
    p.part("ptr", src="ovenStop", cx=xs[1], cy=ky, r0=4, r1=9.5, angles=OVEN_STOP_ANGLES, color="#ece6d4", w=1)
    p.hit("heat", xs[1] - 15, ky - 15, 30, 30, needs="powered", kind="turn")
    ty = 196
    insert_knob(p, xs[0], ty, 9, on=Z_FACE, insert_r=2.6)
    minutes_scale(p, xs[0], ty, 13.5, mat="paint_c", wear=0.08 if worn else 0)
    p.label("MINUTES", xs[0], ty + 27, "paint_c", align="c", auto_ink=False)
    p.part("ptr", src="timerF", cx=xs[0], cy=ty, r0=3.5, r1=7.5, a0=-90, a1=210, color="#ece6d4", w=1)
    p.hit("timer", xs[0] - 13, ty - 13, 26, 26, needs="powered", kind="turn")
    jy = ty - 16
    jewel(p, xs[1], jy, 4.0, off="jewel_red_off", on=Z_FACE)
    p.lamp(disc(d, xs[1], jy, 4.0), "on", "#ff5a3a")
    p.label("SIGNAL", xs[1], jy + 9, "paint_c", align="c", auto_ink=False)
    nameplate(d, "CGE", xs[1], jy + 22, on=Z_FACE, mat="chrome", font="57", align="c", z=1.4)
    p.label("ELECTRIC RANGE", xs[1], jy + 33, "paint_c", align="c", auto_ink=False)
    if worn:
        en = WR.mat_mask(d, "enamel_red")
        WR.gloss(d, en, band=(0.35, 70, 12, 0.12))
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 80, 26, 0.10, 150, 190, 0.04)
        WR.grime(d, d.solid, amount=0.30, seed=15)
        WR.chips(d, WR.face(d, Z_FACE, body), 0.004, seed=16, near=2.5)
        WR.pits(d, trim, 0.003, seed=17)
    return p


def _burner_row(p, xs, y, fn):
    for x, which in zip(xs, ("LR", "LF", "RF", "RR")):
        fn(x, y, which)


def grey_range_n(worn=True):
    W, H = NW, 176
    p = Plate("oven_grey_n", W, H, seed=13, title="1985 electric range (narrow)")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 4).get()
    d.slab(body, Z_FACE, "alu", bevel=2.5, polish=0.6); d.grain_brushed(body, 0.04, seed=18)
    def burner(kx, ky, which):
        electric_knob(p, kx, ky, worn=worn)
        burner_icon(p, kx - 3, ky + 22, which)
        p.hit("burner" + which, kx - 12, ky - 12, 24, 24, kind="look")
    _burner_row(p, (30, 76, 124, 170), 34, burner)
    gx0, gy0, gw, gh = 8, 72, W - 16, H - 80
    G = Z_FACE + 0.8
    glass_panel(p, gx0, gy0, gw, gh, on=G, r=2, frame="chrome")
    vx, vy, vw, vh = gx0 + 8, gy0 + 8, 104, 28
    CYAN, CYAN_GHOST = "#52f2d6", "#0a201d"
    vfd(p, vx, vy, vw, vh, G, CYAN, CYAN_GHOST, (vx + 4, vy + 7))
    lamp_text(p, "BAKE", vx + vw - 4, vy + 4, "on", CYAN, off="vfdoff", align="r")
    lamp_text(p, "TIMER", vx + vw - 4, vy + 11, "timerOn", CYAN, off="vfdoff", align="r")
    lamp_text(p, "F", vx + vw - 12, vy + 19, "unitF", CYAN, off="vfdoff", align="r")
    lamp_text(p, "C", vx + vw - 4, vy + 19, "unitC", CYAN, off="vfdoff", align="r")
    MB.lectromax_badge(p, (vx + vw + gx0 + gw) // 2 + 1, vy + 14, on=G, two_lines=False)
    px0, pw, ph, pg = gx0 + 8, 41, 16, 3
    ya, yb = gy0 + 48, gy0 + 70
    for i, (pid, lab) in enumerate((("bake", "BAKE"), ("broil", "BROIL"), ("timer", "TIMER"), ("clock", "CLOCK"))):
        glass_pad(p, px0 + i * (pw + pg), ya, pw, ph, lab)
        p.hit(pid, px0 + i * (pw + pg), ya, pw, ph, needs="powered", kind="look" if pid == "clock" else "press")
    glass_pad(p, px0, yb, pw, ph, icon="up"); p.hit("up", px0, yb, pw, ph, needs="powered")
    glass_pad(p, px0 + pw + pg, yb, pw, ph, icon="down"); p.hit("down", px0 + pw + pg, yb, pw, ph, needs="powered")
    glass_pad(p, px0 + 2 * (pw + pg), yb, 2 * pw + pg, ph, "CLEAR / OFF")
    p.hit("clearoff", px0 + 2 * (pw + pg), yb, 2 * pw + pg, ph, needs="powered")
    if worn:
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 30, 20, 0.08, 150, 200, 0.022)
        gl = WR.mat_mask(d, "blackglass")
        WR.gloss(d, gl, band=(0.55, 70, 26, 0.30))
        WR.smudge(d, gl & (d.YY > gy0 + 44), amount=-0.07, seed=19, sigma=1.6, thresh=0.78)
        WR.grime(d, d.solid, amount=0.26, seed=20)
        WR.scuffs(d, WR.face(d, Z_FACE, body), 0.0008, seed=21, amount=-0.08)
    return p


def modern_range_n(worn=True):
    W, H = NW, 196
    p = Plate("oven_modern_n", W, H, seed=14, title="1992 gas range (narrow)")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 4).get()
    d.slab(body, Z_FACE, "alu", bevel=2.5, polish=0.7); d.grain_brushed(body, 0.038, seed=22)
    def burner(kx, ky, which):
        gas_knob(p, kx, ky, 11, worn=worn)
        burner_icon(p, kx - 3, ky + 26, which)
        p.hit("burner" + which, kx - 13, ky - 13, 26, 26, kind="look")
    _burner_row(p, (30, 76, 124, 170), 34, burner)
    gx0, gy0, gw, gh = 8, 78, W - 16, H - 86
    cxm = gx0 + gw // 2
    G = Z_FACE + 0.8
    glass_panel(p, gx0, gy0, gw, gh, on=G, r=3, frame=None)
    GREEN, GREEN_GHOST = "#6dff8e", "#081e0e"
    vx, vy, vw, vh = cxm - 62, gy0 + 8, 124, 28
    vfd(p, vx, vy, vw, vh, G, GREEN, GREEN_GHOST, (vx + 34, vy + 7))
    lamp_text(p, "BAKE", vx + 4, vy + 4, "on", GREEN, off="vfdoff")
    lamp_text(p, "TIMER", vx + 4, vy + 11, "timerOn", GREEN, off="vfdoff")
    lamp_text(p, "F", vx + vw - 4, vy + 7, "unitF", GREEN, off="vfdoff", align="r")
    lamp_text(p, "C", vx + vw - 4, vy + 15, "unitC", GREEN, off="vfdoff", align="r")
    p.label("PREMIUM TECHNOLOGIES", cxm, vy + vh + 5, "glassline", align="c", auto_ink=False)
    fw, nw, ph, g = 30, 19, 14, 2
    x0 = cxm - (2 * fw + 5 * nw + 6 * g) // 2
    rows = ((("bake", "BAKE"), "12345", ("timer", "TIMER")), (("broil", "BROIL"), "67890", ("clock", "CLOCK")))
    y = gy0 + 52
    for left, nums, right in rows:
        glass_pad(p, x0, y, fw, ph, left[1]); p.hit(left[0], x0, y, fw, ph, needs="powered")
        for i, n in enumerate(nums):
            nx = x0 + fw + g + i * (nw + g)
            glass_pad(p, nx, y, nw, ph, n, font="57"); p.hit("d" + n, nx, y, nw, ph, needs="powered")
        rx = x0 + fw + g + 5 * (nw + g)
        glass_pad(p, rx, y, fw, ph, right[1])
        p.hit(right[0], rx, y, fw, ph, needs="powered", kind="look" if right[0] == "clock" else "press")
        y += ph + 4
    cw_ = 60
    glass_pad(p, x0, y, cw_, ph, "CANCEL"); p.hit("cancel", x0, y, cw_, ph, needs="powered")
    sx = x0 + 2 * fw + 5 * nw + 6 * g - cw_
    glass_pad(p, sx, y, cw_, ph, "START", ink="paint_g"); p.hit("start", sx, y, cw_, ph, needs="powered")
    if worn:
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 20, 18, 0.08, 150, 200, 0.02)
        gl = WR.mat_mask(d, "blackglass")
        WR.gloss(d, gl, band=(0.6, 130, 26, 0.30))
        WR.smudge(d, gl & (d.YY > gy0 + 48), amount=-0.07, seed=23, sigma=1.6, thresh=0.78)
        WR.grime(d, d.solid, amount=0.24, seed=24)
    return p


def industrial_range_n(units="F", on=False, worn=True):
    """the six burners three across and two deep (as their diagrams print them), then the oven's dial with its
    toggle and pilot, then the timer box beside the maker's badge"""
    W, H = NW, 256
    p = Plate("oven_industrial_n", W, H, seed=15, title="1980 restaurant range (narrow)")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 3).get()
    d.slab(body, Z_FACE, "alu", bevel=2.0, polish=0.55); d.grain_brushed(body, 0.05, seed=26)
    d.cyl(3, 3, W - 6, 10, 3.4, "alu", axis="h", polish=0.9, on=Z_FACE)
    order = [3, 4, 5, 0, 1, 2]                                # rear row first, as the wide plate's knob i
    for i in range(6):
        k = order.index(i) if False else i
        col, row = i % 3, i // 3
        kx, ky = 44 + col * 56, 44 + row * 62
        kn = knurled_knob(p, kx, ky, 12)
        baked_pointer(p, kn, -90, 2, 10, mat="paint_w")
        scale_ring(p, kx, ky, 15.5, [-90, 180], ["OFF", ""], minor_angles=[150, 120, 90], wear=0.15 if worn else 0)
        six_burner_icon(p, kx - 5, ky + 23, [3, 4, 5, 0, 1, 2][i])
        p.hit(f"burner{i}", kx - 13, ky - 13, 26, 26, kind="look")
    tx, ty = 62, 204
    d.slab(disc(d, tx, ty, 35), 0.6, "alu", bevel=1.0, polish=0.8, on=Z_FACE)
    d.torus(tx, ty, 34.5, 36.5, 1.2, "chrome", polish=1.0, on=Z_FACE)
    knurled_knob(p, tx, ty, 13, on=Z_FACE + 0.6)
    thermostat_scale(p, tx, ty, 16.5, units, wear=0.10 if worn else 0)
    p.label("OVEN", tx, ty + 42, "paint_k", align="c")
    p.part("ptr", src="ovenStop", cx=tx, cy=ty, r0=2, r1=11, angles=OVEN_STOP_ANGLES, color="#e8e4da", w=1)
    p.hit("heat", tx - 16, ty - 16, 32, 32, needs="powered", kind="turn")
    gx = 122
    p.label("ON", gx, ty - 28, "paint_k", align="c")
    bat_toggle(p, gx, ty - 6, on, on=Z_FACE)
    p.label("OFF", gx, ty + 10, "paint_k", align="c")
    p.hit("onoff", gx - 7, ty - 20, 14, 28, needs="powered")
    jewel(p, gx, ty + 30, 4.0, off="jewel_off", on=Z_FACE)
    p.lamp(disc(d, gx, ty + 30, 4.0), "on", "#ffa630")
    p.label("PILOT", gx, ty + 38, "paint_k", align="c")
    bx0, by0, bw, bh = 140, 172, 58, 68
    box = Mask(W, H).rrect(bx0, by0, bw, bh, 3).get()
    d.slab(box, 3.0, "enamel_black", bevel=1.6, polish=0.6, on=Z_FACE)
    BZ = Z_FACE + 3.0
    for sx, sy in ((bx0 + 4, by0 + 4), (bx0 + bw - 5, by0 + bh - 5)):
        screw(p, sx, sy, on=BZ, mat="alu")
    fx, fy = bx0 + bw // 2, by0 + 30
    fm = disc(d, fx, fy, 25)
    d.h[fm] = BZ - 0.8; d.mat[fm] = d.mid("cream"); d.solid |= fm; d.polish[fm] = 0.3; d.tex[fm] = 0
    d.torus(fx, fy, 24.6, 26.4, 1.4, "chrome", polish=1.0, on=BZ)
    fluted_knob(p, fx, fy, 7, on=BZ - 0.8, z=3.4, mat="blackp", skirt=None, ridges=12, dome=0.5)
    minutes_scale(p, fx, fy, 9.5, wear=0.08 if worn else 0)
    p.label("MINUTES", fx, by0 + bh - 11, "paint_w", align="c", auto_ink=False)
    p.part("ptr", src="timerF", cx=fx, cy=fy, r0=1.5, r1=6, a0=-90, a1=210, color="#e8e4da", w=1)
    p.hit("timer", fx - 12, fy - 12, 24, 24, needs="powered", kind="turn")
    MB.knoxpack_badge(p, bx0 + bw // 2, by0 - 16, on=Z_FACE)
    if worn:
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 70, 34, 0.07, 150, 200, 0.02)
        WR.grime(d, d.solid, amount=0.34, seed=27)
        WR.scuffs(d, WR.face(d, Z_FACE, body), 0.0015, seed=28, amount=-0.08)
        WR.specks(d, WR.face(d, Z_FACE, body), 0.002, seed=29, amount=0.3)
        WR.aged_face(d, fx, fy, 25, amount=0.10)
    return p


def convection_oven_n(units="F", on=False, worn=True):
    W, H = NW, 196
    p = Plate("oven_large_n", W, H, seed=16, title="commercial convection oven (narrow)")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 3).get()
    d.slab(body, Z_FACE, "alu", bevel=2.0, polish=0.6); d.grain_brushed(body, 0.045, seed=30)
    px0, py0, pw, ph = 10, 10, W - 20, H - 20
    PZ = Z_FACE - 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "panel_black", polish=0.4); d.grain_pebble(panel, 0.025, seed=31)
    kx_, ky_, kw_, kh_ = MB.knoxpack_badge(p, 46, 25, on=PZ)
    p.label("CONVECTION", kx_ + kw_ + 8, ky_ + 4, "glassline", auto_ink=False)
    p.label("OVEN", kx_ + kw_ + 8, ky_ + 11, "glassline", auto_ink=False)
    tgx, tgy = 36, 70
    p.label("POWER", tgx, tgy - 26, "paint_w", align="c", auto_ink=False)
    bat_toggle(p, tgx, tgy, on, on=PZ)
    p.label("ON", tgx + 12, tgy - 12, "paint_w", auto_ink=False); p.label("OFF", tgx + 12, tgy + 8, "paint_w", auto_ink=False)
    p.hit("onoff", tgx - 7, tgy - 14, 14, 28, needs="powered")
    lx = 104
    jewel(p, lx, 56, 4.0, off="jewel_off", on=PZ)
    p.lamp(disc(d, lx, 56, 4.0), "on", "#ffa630")
    p.label("HEATING", lx, 64, "paint_w", align="c", auto_ink=False)
    jewel(p, lx + 46, 56, 4.0, off="jewel_grn_off", on=PZ)
    p.lamp(disc(d, lx + 46, 56, 4.0), "on", "#5cff7a")
    p.label("FAN", lx + 46, 64, "paint_w", align="c", auto_ink=False)
    ky = 122
    for kx, kind in ((56, "heat"), (144, "timer")):
        fluted_knob(p, kx, ky, 13, on=PZ, z=4.0, mat="blackp", skirt=2.0, skirt_mat="chrome", ridges=22, dome=0.6 if worn else 0)
        if kind == "heat":
            thermostat_scale(p, kx, ky, 17.5, units, mat="paint_w", wear=0.08 if worn else 0)
            p.label("TEMPERATURE", kx, ky + 36, "paint_w", align="c", auto_ink=False)
            p.part("ptr", src="ovenStop", cx=kx, cy=ky, r0=2, r1=11, angles=OVEN_STOP_ANGLES, color="#f2efe6", w=1)
            p.hit("heat", kx - 16, ky - 16, 32, 32, needs="powered", kind="turn")
        else:
            minutes_scale(p, kx, ky, 17.5, mat="paint_w", wear=0.08 if worn else 0)
            p.label("COOK TIMER", kx, ky + 36, "paint_w", align="c", auto_ink=False)
            p.part("ptr", src="timerF", cx=kx, cy=ky, r0=2, r1=11, a0=-90, a1=210, color="#f2efe6", w=1)
            p.hit("timer", kx - 16, ky - 16, 32, 32, needs="powered", kind="turn")
    louvers(p, 22, H - 30, W - 44, 10, 18, on=PZ, depth=2.2)
    if worn:
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 50, 40, 0.07, 150, 200, 0.02)
        WR.grime(d, d.solid, amount=0.30, seed=32)
        WR.scuffs(d, WR.mat_mask(d, "panel_black"), 0.0012, seed=33, amount=0.10)
    return p


def fryer_n(units="F", on=False, worn=True):
    W, H = NW, 220
    p = Plate("fryer_n", W, H, seed=17, title="Fryers Club deep fryer (narrow)")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 3).get()
    d.slab(body, Z_FACE, "alu", bevel=2.0, polish=0.6); d.grain_brushed(body, 0.045, seed=34)
    bx0, by0, bw, bh = (W - 104) // 2, 10, 104, 30
    badge = Mask(W, H).rrect(bx0, by0, bw, bh, 4).get()
    d.slab(badge, 1.4, "enamel_red", bevel=1.2, polish=0.8, on=Z_FACE)
    chrome_frame(d, bx0 - 1, by0 - 1, bw + 2, bh + 2, Z_FACE, t=1, mat="chrome", z=1.8)
    p.label("FRYERS CLUB", bx0 + bw // 2, by0 + 6, "paint_w", align="c", font="57", auto_ink=False)
    p.label("INDUSTRIAL 2000", bx0 + bw // 2, by0 + 18, "paint_c", align="c", auto_ink=False)
    cx0, cy0, cw, ch = 10, 48, W - 20, 150
    box = Mask(W, H).rrect(cx0, cy0, cw, ch, 2).get()
    d.slab(box, 2.0, "panel_black", bevel=1.2, polish=0.4, on=Z_FACE)
    CZ = Z_FACE + 2.0
    for sx, sy in ((cx0 + 4, cy0 + 4), (cx0 + cw - 5, cy0 + 4), (cx0 + 4, cy0 + ch - 5), (cx0 + cw - 5, cy0 + ch - 5)):
        screw(p, sx, sy, on=CZ, mat="alu")
    rx, ry = 48, cy0 + 12
    p.label("POWER", rx, ry, "paint_w", align="c", auto_ink=False)
    rocker_switch(p, rx - 8, ry + 12, 16, 28, on, on=CZ)
    win = rbox(d, rx - 6, ry + 14, 12, 11)
    d.mat[win & d.solid] = d.mid("jewel_red_off"); d.flatlight[win] = True
    p.lamp(win, "on", "#ff4a2a", halo=False)
    p.label("ON", rx + 14, ry + 15, "paint_w", auto_ink=False); p.label("OFF", rx + 14, ry + 32, "paint_w", auto_ink=False)
    p.hit("onoff", rx - 10, ry + 10, 20, 32, needs="powered")
    jewel(p, 146, ry + 22, 4.0, off="jewel_off", on=CZ)
    p.lamp(disc(d, 146, ry + 22, 4.0), "on", "#ffa630")
    p.label("HEATING", 146, ry + 30, "paint_w", align="c", auto_ink=False)
    ky = cy0 + 96
    kx = 56
    fluted_knob(p, kx, ky, 13, on=CZ, z=4.0, mat="blackp", skirt=2.0, skirt_mat="chrome", ridges=22, dome=0.6 if worn else 0)
    thermostat_scale(p, kx, ky, 17.5, units, mat="paint_w", wear=0.10 if worn else 0)
    p.label("TEMPERATURE", kx, ky + 36, "paint_w", align="c", auto_ink=False)
    p.part("ptr", src="ovenStop", cx=kx, cy=ky, r0=2, r1=11, angles=OVEN_STOP_ANGLES, color="#f2efe6", w=1)
    p.hit("heat", kx - 16, ky - 16, 32, 32, needs="powered", kind="turn")
    tx = 144
    fluted_knob(p, tx, ky, 13, on=CZ, z=4.0, mat="blackp", skirt=2.0, skirt_mat="chrome", ridges=22, dome=0.6 if worn else 0)
    minutes_scale(p, tx, ky, 17.5, mat="paint_w", wear=0.08 if worn else 0)
    p.label("BASKET TIMER", tx, ky + 36, "paint_w", align="c", auto_ink=False)
    p.part("ptr", src="timerF", cx=tx, cy=ky, r0=2, r1=11, a0=-90, a1=210, color="#f2efe6", w=1)
    p.hit("timer", tx - 16, ky - 16, 32, 32, needs="powered", kind="turn")
    louvers(p, 12, H - 18, W - 24, 9, 18, on=Z_FACE, depth=2.0)
    if worn:
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 30, 30, 0.07, 150, 200, 0.02)
        WR.grime(d, d.solid, amount=0.36, seed=35)
        WR.specks(d, WR.face(d, Z_FACE, body), 0.003, seed=36, amount=0.3)
        WR.gloss(d, WR.mat_mask(d, "enamel_red"), band=(0.5, 70, 6, 0.12))
    return p


# =================================================================================== microwaves: the panel whole, the door a strip
import m_more as MM


def mw_white_n(cooking=False, worn=True):
    return MM.mw_white(cooking, worn, narrow=True)


def mw_chrome_n(cooking=False, worn=True):
    return MM.mw_chrome(cooking, worn, narrow=True)


# =================================================================================== generators
def gen_red_n(running=False, connected=False, worn=True):
    W, H = NW, 236
    p = Plate("gen_red_n", W, H, seed=31, title="1988 portable generator (narrow)")
    d = p.d
    DG.housing(p, W, H, "gen_red")
    lx_, ly_, lw_, lh_ = MB.lectromax_badge(p, 46, 19, on=Z_FACE, box="lx_dark")
    sticker(p, W - 98, 11, 80, 19, "WARNING", lines=3)
    p.label("4000 WATT GENERATOR", 16, 33, "paint_w", auto_ink=False)
    px0, py0, pw, ph = 12, 42, W - 24, 162
    PZ = Z_FACE - 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "panel_black", polish=0.35); d.grain_pebble(panel, 0.03, seed=8)
    ax = 32
    p.label("ENGINE", ax, py0 + 6, "paint_w", align="c")
    rocker_switch(p, ax - 8, py0 + 16, 16, 28, running, on=PZ)
    p.label("ON", ax + 14, py0 + 19, "paint_w", wear=0.15 if worn else 0); p.label("OFF", ax + 14, py0 + 36, "paint_w", wear=0.12 if worn else 0)
    p.hit("engine", ax - 10, py0 + 14, 20, 32)
    fluted_knob(p, ax, py0 + 62, 5, on=PZ, z=3.0, mat="blackp", skirt=None, ridges=10)
    p.label("CHOKE", ax, py0 + 71, "paint_w", align="c")
    p.hit("choke", ax - 7, py0 + 55, 14, 14, kind="look")
    bx = 78
    jewel(p, bx, py0 + 22, 3.5, off="jewel_red_off", bezel="chrome", on=PZ)
    p.lamp(disc(d, bx, py0 + 22, 3.5), "running", "#ff4a2a")
    p.label("OUTPUT", bx, py0 + 29, "paint_w", align="c")
    jewel(p, bx, py0 + 50, 3.5, off="jewel_off", bezel="chrome", on=PZ)
    p.lamp(disc(d, bx, py0 + 50, 3.5), "service", "#ffb02e")
    p.label("OIL ALERT", bx, py0 + 57, "paint_w", align="c")
    o1, o2 = 114, 142
    p.label("120V AC 20A", (o1 + o2) // 2, py0 + 6, "paint_w", align="c")
    faces = DG.outlet_duplex(p, o1, py0 + 32, on=PZ, plate_mat="steel")
    DG.outlet_duplex(p, o2, py0 + 32, on=PZ, plate_mat="steel")
    if connected:
        plug(p, faces[1], on=PZ, cord_to=H)
    p.hit("outlet", o1 - 11, py0 + 17, 22, 30)
    wing_nut(p, o2, py0 + 62, on=PZ)
    p.label("GROUND", o2, py0 + 70, "paint_w", align="c")
    cx_, cy_ = 154, py0 + 92
    p.label("CIRCUIT BREAKERS", cx_, cy_, "paint_w", align="c")
    for k in (-16, 16):
        breaker(p, cx_ + k, cy_ + 18, on=PZ)
        p.label("20A", cx_ + k, cy_ + 26, "paint_w", align="c")
        p.hit(f"breaker{k}", cx_ + k - 6, cy_ + 12, 12, 12, kind="look")
    p.label("DC 12V 8A", cx_, cy_ + 38, "paint_w", align="c")
    binding_post(p, cx_ - 16, cy_ + 54, "paint_r", on=PZ); binding_post(p, cx_ + 16, cy_ + 54, "blackp", on=PZ)
    p.label("+", cx_ - 16, cy_ + 62, "paint_w", align="c"); p.label("-", cx_ + 16, cy_ + 62, "paint_w", align="c")
    gx, gy, gr = 56, py0 + 122, 24
    an = fuel_gauge(p, gx, gy, gr, on=PZ)
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **an)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    DG.finish(p, W, H, "steel", "gen_red", 33, worn, louver_y=H - 23)
    if worn:
        WR.chips(d, WR.mat_mask(d, "decal_y"), 0.03, seed=35, near=1.5, mat="gen_red", dh=0.0)
    return p


def gen_yellow_n(running=False, connected=False, worn=True):
    W, H = NW, 240
    p = Plate("gen_yellow_n", W, H, seed=41, title="contractor's generator (narrow)")
    d = p.d
    DG.housing(p, W, H, "gen_yellow")
    p.label("PREMIUM", 18, 12, "paint_k", font="57", auto_ink=False)
    p.label("TECHNOLOGIES", 18, 21, "paint_k", font="57", auto_ink=False)
    p.label("CONTRACTOR 5500", 18, 31, "paint_k", auto_ink=False)
    sticker(p, W - 88, 11, 70, 19, "CAUTION", lines=3, mat="enamel_white")
    px0, py0, pw, ph = 12, 42, W - 24, 166
    PZ = Z_FACE - 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "steel", polish=0.4); d.grain_pebble(panel, 0.03, seed=42)
    ex, ey = 36, py0 + 30
    p.label("ENGINE", ex, py0 + 6, "paint_w", align="c")
    fluted_knob(p, ex, ey, 9, on=PZ, z=4.0, mat="blackp", skirt=None, ridges=14, dome=0.6)
    scale_ring(p, ex, ey, 11.5, [-135, -45], ["OFF", "RUN"], mat="paint_w", wear=0.12 if worn else 0)
    p.part("ptr", src="running", cx=ex, cy=ey, r0=1, r1=7, angles=[-135, -45], color="#f0ede4", w=1)
    p.hit("engine", ex - 12, ey - 12, 24, 24)
    p.label("IDLE", ex, ey + 18, "paint_w", align="c")
    p.label("CONTROL", ex, ey + 25, "paint_w", align="c")
    bat_toggle(p, ex, ey + 42, True, on=PZ)
    p.hit("idle", ex - 6, ey + 30, 12, 20, kind="look")
    an = rect_meter(p, 68, py0 + 8, 66, 42, ["0", "100", "200", "300"], 212, 328, on=PZ, title=None)
    p.part("needle", src="volts", color="#d42a1c", w=1, hub=2, **{**an, "a1": an["a0"] + (an["a1"] - an["a0"]) * 0.8})
    p.label("AC VOLTMETER", 101, py0 + 56, "paint_w", align="c")
    tx, ty = 164, py0 + 34
    p.label("120/240V", tx, py0 + 6, "paint_w", align="c")
    p.label("30A", tx, py0 + 13, "paint_w", align="c")
    twist_lock(p, tx, ty, 11, on=PZ)
    if connected:
        twist_plug(p, tx, ty, 12, on=PZ, cord_to=H)
    p.hit("outlet", tx - 15, ty - 15, 30, 30)
    ry = py0 + 100
    for i, cx in enumerate((104, 130)):
        outlet_cover(p, cx, ry, on=PZ)
        p.hit(f"cover{i}", cx - 11, ry - 15, 22, 30, kind="look")
    p.label("120V 20A", 117, ry - 26, "paint_w", align="c")
    bcx, bcy = 117, py0 + 124
    p.label("BREAKERS", bcx, bcy, "paint_w", align="c")
    for kid, k, amps in ((-24, -17, "30A"), (0, 0, "20A"), (24, 17, "20A")):
        breaker(p, bcx + k, bcy + 16, on=PZ)
        p.label(amps, bcx + k, bcy + 24, "paint_w", align="c")
        p.hit(f"breaker{kid}", bcx + k - 6, bcy + 10, 12, 12, kind="look")
    gx, gy, gr = 50, py0 + 116, 22
    gan = fuel_gauge(p, gx, gy, gr, on=PZ)
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **gan)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    DG.finish(p, W, H, "blackp", "gen_yellow", 43, worn, louver_y=H - 23)
    return p


def gen_blue_n(running=False, connected=False, worn=True):
    W, H = NW, 220
    p = Plate("gen_blue_n", W, H, seed=51, title="1991 compact generator (narrow)")
    d = p.d
    body = Mask(W, H).rrect(2, 2, W - 4, H - 4, 16).get()
    d.slab(body, Z_FACE, "gen_blue", bevel=6.0, polish=0.55, power=0.6)
    d.cyl(W // 2 - 50, 6, 100, 6, 2.2, "gen_blue", axis="h", polish=0.6, on=Z_FACE)
    MB.valutech_logo(p, 52, 16)
    p.label("QUIET SERIES 1000", 22, 26, "paint_w", auto_ink=False)
    for i in range(7):
        d.well(Mask(W, H).rrect(W - 72, 14 + i * 3, 52, 2, 1).get(), 1.6, "blackp", bevel=0.6)
    px0, py0, pw, ph = 12, 40, W - 24, 164
    PZ = Z_FACE - 1.2
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 8).get()
    d.well(panel, 1.2, "panel_black", bevel=2.5, polish=0.45); d.grain_pebble(panel, 0.03, seed=52)
    ex, ey = 44, py0 + 40
    p.label("ENGINE", ex, py0 + 10, "paint_w", align="c")
    fluted_knob(p, ex, ey, 10, on=PZ, z=4.0, mat="blackp", skirt=1.6, skirt_mat="gen_blue", ridges=12, dome=0.6)
    scale_ring(p, ex, ey, 14.0, [-135, -45], ["OFF", "ON"], mat="paint_w", wear=0.12 if worn else 0)
    p.part("ptr", src="running", cx=ex, cy=ey, r0=1, r1=8, angles=[-135, -45], color="#f0ede4", w=1)
    p.hit("engine", ex - 13, ey - 13, 26, 26)
    for lx, lab, src, off, col in ((96, "OUTPUT", "running", "jewel_grn_off", "#5cff7a"), (132, "OVERLOAD", "overload", "jewel_red_off", "#ff4a2a"),
                                   (168, "OIL", "service", "jewel_off", "#ffb02e")):
        jewel(p, lx, py0 + 22, 3.5, off=off, bezel="blackp", on=PZ)
        p.lamp(disc(d, lx, py0 + 22, 3.5), src, col)
        p.label(lab, lx, py0 + 30, "paint_w", align="c")
    rocker_switch(p, 123, py0 + 48, 18, 12, False, on=PZ, lift=1.6)
    p.label("ECO THROTTLE", 132, py0 + 66, "paint_w", align="c")
    p.hit("eco", 121, py0 + 46, 22, 16, kind="look")
    oy = py0 + 118
    p.label("120V 15A", 44, oy - 32, "paint_w", align="c")
    faces = DG.outlet_duplex(p, 44, oy, on=PZ, plate_mat="blackp", mat="socket")
    if connected:
        plug(p, faces[1], on=PZ, cord_to=H)
    p.hit("outlet", 33, oy - 15, 22, 30)
    p.label("DC 12V", 94, oy - 18, "paint_w", align="c")
    binding_post(p, 84, oy, "paint_r", on=PZ); binding_post(p, 104, oy, "blackp", on=PZ)
    p.label("+", 84, oy + 8, "paint_w", align="c"); p.label("-", 104, oy + 8, "paint_w", align="c")
    gx, gy, gr = 152, oy, 22
    gan = fuel_gauge(p, gx, gy, gr, on=PZ)
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **gan)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    if worn:
        b = WR.mat_mask(d, "gen_blue")
        WR.gloss(d, b, band=(0.45, 50, 10, 0.10))
        WR.scuffs(d, b, 0.0015, seed=53, amount=0.12)
        WR.grime(d, d.solid, amount=0.30, seed=54)
    return p


def gen_old_n(running=False, connected=False, worn=True):
    W, H = NW, 270
    p = Plate("gen_old_n", W, H, seed=61, title="1960s military generator (narrow)")
    d = p.d
    DG.housing(p, W, H, "olive_drab", polish=0.2)
    p.label("GENERATOR SET", 18, 13, "paint_c", font="57", auto_ink=False)
    p.label("GASOLINE ENGINE DRIVEN", 18, 23, "paint_c", auto_ink=False)
    PZ = Z_FACE
    meters = (("VOLTS", ["0", "50", "100", "150"], "volts", 0.8), ("AMPERES", ["0", "10", "20", "30"], "load", 1.0),
              ("FREQUENCY", ["55", "", "60", "", "65"], "hz", 0.5))
    for i, (title, labels, src, at) in enumerate(meters):
        mx, my = (48, 152, 48)[i], (70, 70, 138)[i]
        an = round_meter(p, mx, my, 24, labels, a0=150, a1=390, on=PZ, title=None)
        span = an["a1"] - an["a0"]
        p.part("needle", src=src, color="#f0e9d8", w=1, hub=2.5, cx=an["cx"], cy=an["cy"], r0=-3, r1=20, a0=an["a0"],
               a1=an["a0"] + span * at)
        p.label(title, mx, my + 32, "paint_c", align="c", auto_ink=False)
        p.hit("meter" + str(i), mx - 24, my - 24, 48, 48, kind="look")
    gx, gy, gr = 152, 140, 22
    gan = fuel_gauge(p, gx, gy, gr, on=PZ, face="cream")
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **gan)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    dy = 154
    for tx, (l1, l2), live in ((36, ("MASTER", "SWITCH"), True), (80, ("BATTLE", "SHORT"), False)):
        p.label(l1, tx, 36 + dy - 8, "paint_c", align="c", auto_ink=False)
        p.label(l2, tx, 43 + dy - 8, "paint_c", align="c", auto_ink=False)
        bat_toggle(p, tx, 70 + dy - 8, running if live else False, on=PZ, guard=True)
        if live:
            p.hit("engine", tx - 7, 56 + dy - 8, 14, 28)
        else:
            p.hit("battle", tx - 7, 56 + dy - 8, 14, 28, kind="look")
    p.label("ON", 45, 58 + dy - 8, "paint_c", auto_ink=False)
    p.label("OFF", 45, 78 + dy - 8, "paint_c", auto_ink=False)
    sx0, sy0 = 120, 196
    studs = terminal_board(p, sx0, sy0, ["L1", "L2", "L0"], on=PZ, pitch=18)
    if connected:
        for sx, sy in studs:
            lug = Mask(W, H).rrect(sx - 3, sy - 3, 6, 9, 2).get()
            d.slab(lug, 3.6, "chrome", bevel=1.2, polish=1.0, on=PZ + 1.6)
            d.cyl(sx - 2, sy + 5, 4, H - (sy + 5), 3.0, "cord", axis="v", polish=0.6, on=PZ)
    p.hit("outlet", sx0, sy0, 60, 28)
    data_plate(p, 104, 170, 84, 18, ["3 KW 120/240 VOLT", "60 CYCLE  SER 1428"], on=Z_FACE, mat="alu", title=None)
    for x in range(16, W - 12, 28):
        for y in (34, H - 34):
            d.dome(x, y, 1.5, 1.5, 1.0, "olive_drab", polish=0.4, on=Z_FACE)
    DG.finish(p, W, H, "olive_drab", "olive_drab", 63, worn, louver_y=H - 26)
    return p


# =================================================================================== the grill
def grill_propane_n(tank=False, worn=True):
    """the lid with the maker's badge and thermometer, the knob panel across the full width, the cart with the
    tank bay and its gauge (the side shelves and the cabinet door give way)"""
    W, H = NW, 156
    p = Plate("grill_propane_n", W, H, seed=71, title="propane grill (narrow)")
    d = p.d
    cart = Mask(W, H).rrect(14, 102, W - 28, H - 102, 2).get()
    d.slab(cart, Z_FACE - 0.5, "enamel_black", bevel=1.5, polish=0.5)
    ox0, ow = 62, 112
    opening = Mask(W, H).rrect(ox0, 110, ow, H - 110 + 4, 2).get()
    d.well(opening, 3.0, "blackp", bevel=1.2)
    gx, gy = 36, 130
    gan = fuel_gauge(p, gx, gy, 14, on=Z_FACE - 0.5, label=None)
    p.part("needle", src="tankF", color="#d42a1c", w=1, hub=2, **gan)
    p.label("TANK", gx, gy + 18, "paint_w", align="c", auto_ink=False, check=False)
    p.hit("gauge", gx - 14, gy - 14, 28, 28, kind="look")
    tc = ox0 + ow // 2
    s = tc - 228
    if tank:
        t = Mask(W, H).rrect(186 + s, 116, 84, H - 110, 26).get() & (d.YY >= 116)
        d.cyl(186 + s, 116, 84, H - 116, 7.0, "tank_white", axis="v", polish=0.5, on=Z_FACE - 3.5, mask=t)
        d.h[t] += (np.clip((d.YY[t] - 116) / 14.0, 0, 1) ** 0.5 * 2.0 - 2.0).astype(np.float32)
        collar = Mask(W, H).rrect(196 + s, 112, 64, 22, 4).get() & ~Mask(W, H).rrect(204 + s, 118, 18, 10, 3).get() \
            & ~Mask(W, H).rrect(234 + s, 118, 18, 10, 3).get()
        d.slab(collar, 1.6, "tank_white", bevel=1.0, polish=0.5, on=Z_FACE + 1.0)
        d.dome(228 + s, 128, 5, 3, 3.0, "brass", polish=0.9, on=Z_FACE + 1.0)
        d.torus(228 + s, 121, 3.0, 6.0, 1.6, "brass", polish=0.9, on=Z_FACE + 3.0)
        d.cyl(226 + s, 100, 4, 21, 2.4, "cord", axis="v", polish=0.6, on=Z_FACE + 2.0)
    else:
        d.cyl(226 + s, 100, 4, 30, 2.4, "cord", axis="v", polish=0.6, on=Z_FACE - 2.0)
        d.dome(228 + s, 134, 5, 4, 2.4, "brass", polish=0.9, on=Z_FACE - 3.0)
    p.hit("tank", ox0, 110, ow, H - 110)
    panel = Mask(W, H).rrect(6, 48, W - 12, 54, 2).get()
    d.slab(panel, Z_FACE, "alu", bevel=1.6, polish=0.6); d.grain_brushed(panel, 0.045, seed=73)
    for i, kx in enumerate((38, 90, 142)):
        fluted_knob(p, kx, 75, 11, on=Z_FACE, z=4.2, mat="blackp", skirt=1.8, skirt_mat="chrome", ridges=18, dome=0.7 if worn else 0)
        scale_ring(p, kx, 75, 15.0, [-90, 180, 45], ["OFF", "HI", "LO"], minor_angles=[150, 120, 90, 67], wear=0.15 if worn else 0)
        p.part("ptr", src="lit", cx=kx, cy=75, r0=2, r1=9, angles=[-90, 180], color="#f2efe6", w=1)
        p.hit("burner" if i == 1 else f"burner{i}", kx - 14, 61, 28, 28, kind="press" if i == 1 else "look")
    ix, iy = 180, 72
    d.torus(ix, iy, 5.4, 7.4, 1.6, "chrome", polish=1.0, on=Z_FACE)
    d.dome(ix, iy, 5.4, 5.4, 3.4, "paint_r", polish=0.8, on=Z_FACE, power=0.6)
    p.label("IGNITE", ix, 84, "paint_k", align="c")
    p.hit("ignite", ix - 8, iy - 8, 16, 16)
    gap = rbox(d, 18, 44, W - 36, 4)
    d.flat(gap, Z_FACE - 2.5, "blackp", polish=0.2)
    p.lamp(rbox(d, 22, 45, W - 44, 2), "lit", "#ff8a2a", halo=False)
    hood = Mask(W, H).rrect(14, -8, W - 28, 52, 10).get()
    d.slab(hood, Z_FACE + 2.0, "enamel_black", bevel=5.0, polish=0.85, power=0.5)
    HZ = Z_FACE + 2.0
    for ex0 in (14, W - 14 - 12):
        cap = hood & rbox(d, ex0, -8, 12, 52)
        d.mat[cap] = d.mid("steel"); d.polish[cap] = 0.5
        d.seam(hood & rbox(d, ex0 + (11 if ex0 == 14 else 0), 0, 1, 44), 0.5)
    d.tex[hood & (d.YY >= 5) & (d.YY <= 6) & (d.mat == d.mid("enamel_black"))] += 0.16
    badge = Mask(W, H).rrect(30, 10, 84, 18, 6).get()
    d.slab(badge, 1.2, "chrome", bevel=1.0, polish=1.0, on=HZ)
    nameplate(d, "HECTOR LOPEZ", 72, 15, on=HZ + 1.2, mat="enamel_black", font="57", align="c", z=0.6)
    tan = DGR.thermometer(p, 150, 19, 15, on=HZ)
    p.part("needle", src="grillTemp", color="#1b1b1d", w=1, hub=1.6, **tan)
    p.hit("thermo", 136, 5, 28, 28, kind="look")
    for sx in (40, 154):
        d.slab(Mask(W, H).rrect(sx, 34, 6, 7, 1).get(), 2.0, "chrome", bevel=1.0, polish=1.0, on=HZ)
    d.cyl(36, 36, 128, 5, 3.4, "chrome", axis="h", polish=1.0, on=HZ + 1.0)
    if worn:
        hood_m = WR.mat_mask(d, "enamel_black")
        WR.gloss(d, hood_m & (d.YY < 46), band=(0.5, 40, 10, 0.12))
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 50, 30, 0.07, 150, 194, 0.025)
        WR.grime(d, d.solid, amount=0.36, seed=74)
        WR.specks(d, hood_m, 0.004, seed=75, amount=-0.2)
        WR.scuffs(d, WR.mat_mask(d, "alu"), 0.0015, seed=76, amount=-0.08)
    return p


# =================================================================================== the ham sets' narrow faces, updated
# (cursor disc on the two tuning dials; the makeshift's embossing-tape labels and hand-drilled grille)
def ham_civilian_n(worn_=True):
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
    MH.cursor_disc(p, 60, 132, 37, 24)
    PR.radio_knob(p, 60, 132, 22, mat="blackp", skirt=1.4, ridges=40, pid="tune", label="DIAL", label_y=173, lab_mat="paint_k")
    MH.knob_reads_band(p, 60, 132)
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
    MH.cursor_disc(p, 62, 134, 35, 20)
    PR.radio_knob(p, 62, 134, 20, mat="blackp", ridges=40, pid="tune", label="FREQ", label_y=172)
    MH.knob_reads_band(p, 62, 134)
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


def ham_makeshift_n(worn_=True, mic_live=False):
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
        MH.dymo(p, lab, x + 6, 83)
    PR.pot(p, "tune", 134, 72, 10)
    PR.pot(p, "vol", 168, 72, 10)
    MH.dymo(p, "TUNE", 134, 89)
    MH.dymo(p, "VOL", 168, 89)
    bat_toggle(p, 34, 116, mic_live, on=Z_FACE)          # up = TALK: a variant (micLive) flips it
    p.hit("mic", 26, 104, 16, 24)
    MH.dymo(p, "TALK", 46, 108, align="l")
    MH.dymo(p, "LISTEN", 46, 121, align="l")
    PR.radio_key(p, "mute", 102, 108, 30, 13, None, mat="blackp", z=2.2)
    MH.dymo(p, "MUTE", 117, 126)
    mic_jack(p, 166, 114, mat="steel", tip="blackp", label=None)
    MH.dymo(p, "MIC", 166, 125)
    MH.dymo(p, "HOLD MEM", 100, 145)
    MH.drilled_grille(p, 100, 214, 54, seed=11)
    if worn_:
        WR.grime(d, d.solid, amount=0.26, seed=354)
    return p


