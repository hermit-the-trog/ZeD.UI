"""MOCKUP (Oct 29 2026): the ovens and fryer re-laid to the 336 px main face (PLATE_SIZES_SPEC.md).
Same parts, same materials, same state wiring as d_ovens; only the layout changes."""
from d_ovens import *            # noqa: F401,F403
import m_brands as MB


def _burner_pair_cols(p, W, top, pitch, kind, worn, xs=None, icon_dy=19, hit_r=12):
    """burners stacked in pairs either side: rear on top, front under it (LR/LF left, RR/RF right)"""
    xl, xr = xs
    for x, (a, b) in ((xl, ("LR", "LF")), (xr, ("RR", "RF"))):
        for k, which in enumerate((a, b)):
            y = top + k * pitch
            kind(x, y, which)


# =================================================================================== green, 1956
def green_range(units="F", on=False, worn=True):
    W, H = 336, 150
    p = Plate("oven_green", W, H, seed=11, title="1956 range")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 6).get()
    d.slab(body, Z_FACE, "enamel_mint", bevel=3.0, polish=0.75)
    spears = d.cyl(10, 5, W - 20, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    spears |= d.cyl(10, H - 8, W - 20, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    cx0, cy0, cw, ch = 66, 14, 204, H - 28
    F = Z_FACE + 1.2
    cc = rbox(d, cx0, cy0, cw, ch)
    d.flat(cc, F, "alu", polish=0.5); d.grain_brushed(cc, 0.05 if worn else 0.03, seed=4)
    chrome_frame(d, cx0 - 2, cy0 - 2, cw + 4, ch + 4, Z_FACE, t=2, mat="chrome", z=2.0)
    ccy = cy0 + ch // 2
    clx = cx0 + 36
    clock_face(p, clx, ccy - 8, 28, face="cream", on=F, depth=1.6)
    p.part("clock", cx=clx, cy=ccy - 8, rh=13, rm=21, color="#1c1b17")
    mx, my = cx0 + 104, ccy - 20
    fluted_knob(p, mx, my, 9, on=F, dome=0.9 if worn else 0.0)
    minutes_scale(p, mx, my, 13.5, wear=0.10 if worn else 0)
    p.label("MINUTE MINDER", mx, my + 27, "paint_k", align="c")
    p.part("ptr", src="timerF", cx=mx, cy=my, r0=1, r1=7, a0=-90, a1=210, color="#7a1a12", w=1)
    p.hit("timer", mx - 13, my - 13, 26, 26, needs="powered", kind="turn")
    ox, oy = cx0 + 168, my
    fluted_knob(p, ox, oy, 9, on=F, dome=0.9 if worn else 0.0)
    thermostat_scale(p, ox, oy, 13.5, units, wear=0.12 if worn else 0)
    p.label("OVEN", ox, oy + 27, "paint_k", align="c")
    p.part("ptr", src="ovenStop", cx=ox, cy=oy, r0=1, r1=7, angles=OVEN_STOP_ANGLES, color="#7a1a12", w=1)
    p.hit("heat", ox - 13, oy - 13, 26, 26, needs="powered", kind="turn")
    ky = my + 44
    keys = piano_keys(p, mx + 6, ky, ["ON", "OFF"], 20, 11, 0 if on else 1, mat="cream", on=F)
    p.hit("on", *keys[0], needs="powered"); p.hit("off", *keys[1], needs="powered")
    jx = mx + 60
    jewel(p, jx, ky + 5, 4.0, on=F)
    p.lamp(disc(d, jx, ky + 5, 4.0), "on", "#ffa630")
    # the surface burners, stacked in pairs either side of the control centre (look only)
    def burner(bx, by, which):
        kn = fluted_knob(p, bx, by, 10, on=Z_FACE, dome=0.9 if worn else 0.0)
        baked_pointer(p, kn, -90, 1, 8)
        scale_ring(p, bx, by, 13.5, [-90, 180, 45], ["OFF", "HI", "LO"], minor_angles=[150, 120, 90, 67], wear=0.22 if worn else 0)
        burner_icon(p, bx - 3, by + 19, which)
        p.hit("burner" + which, bx - 12, by - 12, 24, 24, kind="look")
    _burner_pair_cols(p, W, 50, 54, burner, worn, xs=(33, W - 33))
    MB.mg_monogram(p, 33, 17)                                   # Mass-Genfac Co.: the monogram left, the name right
    MB.mg_wordmark(p, W - 33, 13)
    p.label("CO.", W - 33, 20, "mg_blue", align="c", auto_ink=False)
    if worn:
        en = WR.mat_mask(d, "enamel_mint")
        WR.gloss(d, en, band=(0.31, 40, 12, 0.13))
        WR.gloss(d, en, band=(0.31, 53, 2, 0.13))
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 160, 20, 0.105, 220, 262, 0.045)
        WR.grime(d, d.solid, amount=0.30, seed=5)
        WR.chips(d, WR.face(d, Z_FACE, body), 0.004, seed=7, near=2.5)
        WR.pits(d, spears, 0.003, seed=9)
        WR.aged_face(d, clx, ccy - 8, 28, amount=0.12)
    return p


# =================================================================================== red, 1962
def red_range(units="F", worn=True):
    W, H = 336, 146
    p = Plate("oven_red", W, H, seed=12, title="1962 range")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 5).get()
    d.slab(body, Z_FACE, "enamel_red", bevel=3.0, polish=0.75)
    trim = d.cyl(8, 4, W - 16, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    trim |= d.cyl(8, H - 7, W - 16, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_FACE)
    sx0, sy0, sw, sh = 12, 11, W - 24, 44
    F = Z_FACE + 1.0
    strip = rbox(d, sx0, sy0, sw, sh)
    d.flat(strip, F, "alu", polish=0.5); d.grain_brushed(strip, 0.05 if worn else 0.03, seed=14)
    chrome_frame(d, sx0 - 1, sy0 - 1, sw + 2, sh + 2, Z_FACE, t=1, mat="chrome", z=1.6)
    for k, which in enumerate(("LR", "LF", "RF", "RR")):
        gcx = sx0 + round(sw * (2 * k + 1) / 8) + 1
        gx0 = gcx - 29
        burner_icon(p, gcx - 3, sy0 + 4, which)
        piano_keys(p, gx0, sy0 + 16, ["", "1", "2", "3", "4", "HI"], 9, 13, 0, mat="enamel_white", on=F, frame="chrome",
                   mats=["bakelite", "enamel_white", "enamel_white", "enamel_white", "enamel_white", "enamel_white"])
        p.label("OFF", gx0 + 4, sy0 + 34, "paint_k", align="c", wear=0.15 if worn else 0)
        p.label("HI", gx0 + 54, sy0 + 34, "paint_k", align="c")
        p.hit("burner" + which, gx0, sy0 + 16, 59, 13, kind="look")
    ky = 98
    xs = (44, 123, 205, 288)
    sel = insert_knob(p, xs[0], ky, 9, on=Z_FACE, insert_r=2.6)
    scale_ring(p, xs[0], ky, 13.5, [-90, -30, 30], ["OFF", "BAKE", "BROIL"], mat="paint_c", wear=0.10 if worn else 0)
    p.label("OVEN", xs[0], ky + 27, "paint_c", align="c", auto_ink=False)
    p.part("ptr", src="switched", cx=xs[0], cy=ky, r0=3.5, r1=7.5, angles=[-90, -30], color="#ece6d4", w=1)
    p.hit("onoff", xs[0] - 13, ky - 13, 26, 26, needs="powered")
    insert_knob(p, xs[1], ky, 11, on=Z_FACE, insert_r=3.0)
    thermostat_scale(p, xs[1], ky, 15.5, units, mat="paint_c", wear=0.10 if worn else 0)
    p.label("TEMPERATURE", xs[1], ky + 31, "paint_c", align="c", auto_ink=False)
    p.part("ptr", src="ovenStop", cx=xs[1], cy=ky, r0=4, r1=9.5, angles=OVEN_STOP_ANGLES, color="#ece6d4", w=1)
    p.hit("heat", xs[1] - 15, ky - 15, 30, 30, needs="powered", kind="turn")
    insert_knob(p, xs[2], ky, 9, on=Z_FACE, insert_r=2.6)
    minutes_scale(p, xs[2], ky, 13.5, mat="paint_c", wear=0.08 if worn else 0)
    p.label("MINUTES", xs[2], ky + 27, "paint_c", align="c", auto_ink=False)
    p.part("ptr", src="timerF", cx=xs[2], cy=ky, r0=3.5, r1=7.5, a0=-90, a1=210, color="#ece6d4", w=1)
    p.hit("timer", xs[2] - 13, ky - 13, 26, 26, needs="powered", kind="turn")
    # the signal lamp, and the maker under it
    jy = ky - 10
    jewel(p, xs[3], jy, 4.0, off="jewel_red_off", on=Z_FACE)
    p.lamp(disc(d, xs[3], jy, 4.0), "on", "#ff5a3a")
    p.label("SIGNAL", xs[3], jy + 9, "paint_c", align="c", auto_ink=False)
    nameplate(d, "CGE", xs[3], jy + 22, on=Z_FACE, mat="chrome", font="57", align="c", z=1.4)
    p.label("ELECTRIC RANGE", xs[3], jy + 33, "paint_c", align="c", auto_ink=False)
    if worn:
        en = WR.mat_mask(d, "enamel_red")
        WR.gloss(d, en, band=(0.35, 120, 12, 0.12))
        WR.gloss(d, en, band=(0.35, 134, 2, 0.12))
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 110, 26, 0.10, 250, 324, 0.04)
        WR.grime(d, d.solid, amount=0.30, seed=15)
        WR.chips(d, WR.face(d, Z_FACE, body), 0.004, seed=16, near=2.5)
        WR.pits(d, trim, 0.003, seed=17)
    return p


# =================================================================================== grey, 1985
def grey_range(worn=True):
    W, H = 336, 128
    p = Plate("oven_grey", W, H, seed=13, title="1985 electric range")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 4).get()
    d.slab(body, Z_FACE, "alu", bevel=2.5, polish=0.6); d.grain_brushed(body, 0.04, seed=18)
    gx0, gy0, gw, gh = 58, 9, 220, H - 18
    G = Z_FACE + 0.8
    glass_panel(p, gx0, gy0, gw, gh, on=G, r=2, frame="chrome")
    vx, vy, vw, vh = gx0 + 10, gy0 + 9, 104, 28
    CYAN, CYAN_GHOST = "#52f2d6", "#0a201d"
    vfd(p, vx, vy, vw, vh, G, CYAN, CYAN_GHOST, (vx + 4, vy + 7))
    lamp_text(p, "BAKE", vx + vw - 4, vy + 4, "on", CYAN, off="vfdoff", align="r")
    lamp_text(p, "TIMER", vx + vw - 4, vy + 11, "timerOn", CYAN, off="vfdoff", align="r")
    lamp_text(p, "F", vx + vw - 12, vy + 19, "unitF", CYAN, off="vfdoff", align="r")
    lamp_text(p, "C", vx + vw - 4, vy + 19, "unitC", CYAN, off="vfdoff", align="r")
    bx = (vx + vw + gx0 + gw) // 2
    MB.lectromax_badge(p, bx, gy0 + 19, on=G)
    px0, pw, ph, pg = gx0 + 10, 47, 16, 4
    ya, yb = gy0 + 56, gy0 + 78
    for i, (pid, lab) in enumerate((("bake", "BAKE"), ("broil", "BROIL"), ("timer", "TIMER"), ("clock", "CLOCK"))):
        glass_pad(p, px0 + i * (pw + pg), ya, pw, ph, lab)
        p.hit(pid, px0 + i * (pw + pg), ya, pw, ph, needs="powered", kind="look" if pid == "clock" else "press")
    glass_pad(p, px0, yb, pw, ph, icon="up"); p.hit("up", px0, yb, pw, ph, needs="powered")
    glass_pad(p, px0 + pw + pg, yb, pw, ph, icon="down"); p.hit("down", px0 + pw + pg, yb, pw, ph, needs="powered")
    glass_pad(p, px0 + 2 * (pw + pg), yb, 2 * pw + pg, ph, "CLEAR / OFF")
    p.hit("clearoff", px0 + 2 * (pw + pg), yb, 2 * pw + pg, ph, needs="powered")
    def burner(kx, ky, which):
        electric_knob(p, kx, ky, worn=worn)
        burner_icon(p, kx - 3, ky + 22, which)
        p.hit("burner" + which, kx - 12, ky - 12, 24, 24, kind="look")
    _burner_pair_cols(p, W, 32, 58, burner, worn, xs=(29, W - 29))
    if worn:
        st = WR.mat_mask(d, "alu")
        WR.brushed_sheen(d, st, 40, 24, 0.08, 290, 336, 0.022)
        gl = WR.mat_mask(d, "blackglass")
        WR.gloss(d, gl, band=(0.55, 110, 30, 0.30))
        WR.gloss(d, gl, band=(0.55, 146, 3, 0.42))
        WR.smudge(d, gl & (d.YY > gy0 + 52), amount=-0.07, seed=19, sigma=1.6, thresh=0.78)
        WR.grime(d, d.solid, amount=0.26, seed=20)
        WR.scuffs(d, WR.face(d, Z_FACE, body), 0.0008, seed=21, amount=-0.08)
    return p


# =================================================================================== modern, 1992
def modern_range(worn=True):
    W, H = 336, 136
    p = Plate("oven_modern", W, H, seed=14, title="1992 gas range")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 4).get()
    d.slab(body, Z_FACE, "alu", bevel=2.5, polish=0.7); d.grain_brushed(body, 0.038, seed=22)
    gx0, gy0, gw, gh = 58, 8, 220, H - 16
    cxm = gx0 + gw // 2
    G = Z_FACE + 0.8
    glass_panel(p, gx0, gy0, gw, gh, on=G, r=3, frame=None)
    GREEN, GREEN_GHOST = "#6dff8e", "#081e0e"
    vx, vy, vw, vh = cxm - 62, gy0 + 9, 124, 28
    vfd(p, vx, vy, vw, vh, G, GREEN, GREEN_GHOST, (vx + 34, vy + 7))
    lamp_text(p, "BAKE", vx + 4, vy + 4, "on", GREEN, off="vfdoff")
    lamp_text(p, "TIMER", vx + 4, vy + 11, "timerOn", GREEN, off="vfdoff")
    lamp_text(p, "F", vx + vw - 4, vy + 7, "unitF", GREEN, off="vfdoff", align="r")
    lamp_text(p, "C", vx + vw - 4, vy + 15, "unitC", GREEN, off="vfdoff", align="r")
    p.label("PREMIUM TECHNOLOGIES", cxm, vy + vh + 5, "glassline", align="c", auto_ink=False)
    fw, nw, ph, g = 38, 21, 14, 3
    x0 = cxm - (2 * fw + 5 * nw + 6 * g) // 2
    rows = ((("bake", "BAKE"), "12345", ("timer", "TIMER")), (("broil", "BROIL"), "67890", ("clock", "CLOCK")))
    y = gy0 + 56
    for left, nums, right in rows:
        glass_pad(p, x0, y, fw, ph, left[1]); p.hit(left[0], x0, y, fw, ph, needs="powered")
        for i, n in enumerate(nums):
            nx = x0 + fw + g + i * (nw + g)
            glass_pad(p, nx, y, nw, ph, n, font="57"); p.hit("d" + n, nx, y, nw, ph, needs="powered")
        rx = x0 + fw + g + 5 * (nw + g)
        glass_pad(p, rx, y, fw, ph, right[1])
        p.hit(right[0], rx, y, fw, ph, needs="powered", kind="look" if right[0] == "clock" else "press")
        y += ph + 4
    cw_ = 70
    glass_pad(p, x0, y, cw_, ph, "CANCEL"); p.hit("cancel", x0, y, cw_, ph, needs="powered")
    sx = x0 + 2 * fw + 5 * nw + 6 * g - cw_
    glass_pad(p, sx, y, cw_, ph, "START", ink="paint_g"); p.hit("start", sx, y, cw_, ph, needs="powered")
    def burner(kx, ky, which):
        gas_knob(p, kx, ky, 11, worn=worn)
        burner_icon(p, kx - 3, ky + 26, which)
        p.hit("burner" + which, kx - 13, ky - 13, 26, 26, kind="look")
    _burner_pair_cols(p, W, 36, 60, burner, worn, xs=(29, W - 29))
    if worn:
        st = WR.mat_mask(d, "alu")
        WR.brushed_sheen(d, st, 30, 22, 0.08, 296, 336, 0.02)
        gl = WR.mat_mask(d, "blackglass")
        WR.gloss(d, gl, band=(0.6, 220, 28, 0.30))
        WR.gloss(d, gl, band=(0.6, 253, 3, 0.42))
        WR.smudge(d, gl & (d.YY > gy0 + 52), amount=-0.07, seed=23, sigma=1.6, thresh=0.78)
        WR.grime(d, d.solid, amount=0.24, seed=24)
    return p


# =================================================================================== industrial, 1980
def industrial_range(units="F", on=False, worn=True):
    """six burners stay in one row under the rail; the oven's dial, toggle, pilot and timer box drop to a second row"""
    W, H = 336, 176
    p = Plate("oven_industrial", W, H, seed=15, title="1980 restaurant range")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 3).get()
    d.slab(body, Z_FACE, "alu", bevel=2.0, polish=0.55); d.grain_brushed(body, 0.05, seed=26)
    rail = d.cyl(3, 3, W - 6, 10, 3.4, "alu", axis="h", polish=0.9, on=Z_FACE)
    for i in range(6):
        kx = 34 + i * 53
        kn = knurled_knob(p, kx, 46, 12)
        baked_pointer(p, kn, -90, 2, 10, mat="paint_w")
        scale_ring(p, kx, 46, 15.5, [-90, 180], ["OFF", ""], minor_angles=[150, 120, 90], wear=0.15 if worn else 0)
        six_burner_icon(p, kx - 5, 69, [3, 4, 5, 0, 1, 2][i])
        p.hit(f"burner{i}", kx - 13, 33, 26, 26, kind="look")
    # second row: thermostat dial plate, OVEN toggle and pilot, the bolted-on timer, the maker's plate under the dial
    tx, ty = 62, 118
    d.slab(disc(d, tx, ty, 35), 0.6, "alu", bevel=1.0, polish=0.8, on=Z_FACE)
    d.torus(tx, ty, 34.5, 36.5, 1.2, "chrome", polish=1.0, on=Z_FACE)
    knurled_knob(p, tx, ty, 13, on=Z_FACE + 0.6)
    thermostat_scale(p, tx, ty, 16.5, units, wear=0.10 if worn else 0)
    p.label("OVEN", tx, ty + 42, "paint_k", align="c")
    p.part("ptr", src="ovenStop", cx=tx, cy=ty, r0=2, r1=11, angles=OVEN_STOP_ANGLES, color="#e8e4da", w=1)
    p.hit("heat", tx - 16, ty - 16, 32, 32, needs="powered", kind="turn")
    gx = 130
    p.label("ON", gx, ty - 28, "paint_k", align="c")
    bat_toggle(p, gx, ty - 6, on, on=Z_FACE)
    p.label("OFF", gx, ty + 10, "paint_k", align="c")
    p.hit("onoff", gx - 7, ty - 20, 14, 28, needs="powered")
    jewel(p, gx, ty + 30, 4.0, off="jewel_off", on=Z_FACE)
    p.lamp(disc(d, gx, ty + 30, 4.0), "on", "#ffa630")
    p.label("PILOT", gx, ty + 38, "paint_k", align="c")
    MB.knoxpack_badge(p, 204, ty, on=Z_FACE)
    bx0, by0, bw, bh = 262, 80, 62, 84
    box = Mask(W, H).rrect(bx0, by0, bw, bh, 3).get()
    d.slab(box, 3.0, "enamel_black", bevel=1.6, polish=0.6, on=Z_FACE)
    BZ = Z_FACE + 3.0
    for sx, sy in ((bx0 + 5, by0 + 5), (bx0 + bw - 6, by0 + bh - 6)):
        screw(p, sx, sy, on=BZ, mat="alu")
    fx, fy = bx0 + bw // 2, by0 + 34
    fm = disc(d, fx, fy, 26)
    d.h[fm] = BZ - 0.8; d.mat[fm] = d.mid("cream"); d.solid |= fm; d.polish[fm] = 0.3; d.tex[fm] = 0
    d.torus(fx, fy, 25.6, 27.4, 1.4, "chrome", polish=1.0, on=BZ)
    fluted_knob(p, fx, fy, 7, on=BZ - 0.8, z=3.4, mat="blackp", skirt=None, ridges=12, dome=0.5)
    minutes_scale(p, fx, fy, 9.5, wear=0.08 if worn else 0)
    p.label("MINUTES", fx, by0 + bh - 14, "paint_w", align="c", auto_ink=False)
    p.part("ptr", src="timerF", cx=fx, cy=fy, r0=1.5, r1=6, a0=-90, a1=210, color="#e8e4da", w=1)
    p.hit("timer", fx - 12, fy - 12, 24, 24, needs="powered", kind="turn")
    if worn:
        st = WR.mat_mask(d, "alu")
        WR.brushed_sheen(d, st, 100, 34, 0.07, 250, 336, 0.02)
        WR.grime(d, d.solid, amount=0.34, seed=27)
        WR.scuffs(d, WR.face(d, Z_FACE, body), 0.0015, seed=28, amount=-0.08)
        WR.specks(d, WR.face(d, Z_FACE, body), 0.002, seed=29, amount=0.3)
        WR.aged_face(d, fx, fy, 26, amount=0.10)
    return p


# =================================================================================== large modern: a commercial convection oven
def convection_oven(units="F", on=False, worn=True):
    W, H = 336, 124
    p = Plate("oven_large", W, H, seed=16, title="commercial convection oven")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 3).get()
    d.slab(body, Z_FACE, "alu", bevel=2.0, polish=0.6); d.grain_brushed(body, 0.045, seed=30)
    px0, py0, pw, ph = 10, 10, W - 20, H - 20
    PZ = Z_FACE - 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "panel_black", polish=0.4); d.grain_pebble(panel, 0.025, seed=31)
    kx_, ky_, kw_, kh_ = MB.knoxpack_badge(p, 46, 25, on=PZ)
    p.label("CONVECTION OVEN", kx_ + kw_ + 6, ky_ + 7, "glassline", auto_ink=False)
    tgx = 36
    p.label("POWER", tgx, 44, "paint_w", align="c", auto_ink=False)
    bat_toggle(p, tgx, 70, on, on=PZ)
    p.label("ON", tgx + 12, 58, "paint_w", auto_ink=False); p.label("OFF", tgx + 12, 78, "paint_w", auto_ink=False)
    p.hit("onoff", tgx - 7, 56, 14, 28, needs="powered")
    for kx, kind in ((112, "heat"), (194, "timer")):
        fluted_knob(p, kx, 66, 13, on=PZ, z=4.0, mat="blackp", skirt=2.0, skirt_mat="chrome", ridges=22, dome=0.6 if worn else 0)
        if kind == "heat":
            thermostat_scale(p, kx, 66, 17.5, units, mat="paint_w", wear=0.08 if worn else 0)
            p.label("TEMPERATURE", kx, 102, "paint_w", align="c", auto_ink=False)
            p.part("ptr", src="ovenStop", cx=kx, cy=66, r0=2, r1=11, angles=OVEN_STOP_ANGLES, color="#f2efe6", w=1)
            p.hit("heat", kx - 16, 50, 32, 32, needs="powered", kind="turn")
        else:
            minutes_scale(p, kx, 66, 17.5, mat="paint_w", wear=0.08 if worn else 0)
            p.label("COOK TIMER", kx, 102, "paint_w", align="c", auto_ink=False)
            p.part("ptr", src="timerF", cx=kx, cy=66, r0=2, r1=11, a0=-90, a1=210, color="#f2efe6", w=1)
            p.hit("timer", kx - 16, 50, 32, 32, needs="powered", kind="turn")
    lx = 252
    jewel(p, lx, 52, 4.0, off="jewel_off", on=PZ)
    p.lamp(disc(d, lx, 52, 4.0), "on", "#ffa630")
    p.label("HEATING", lx, 60, "paint_w", align="c", auto_ink=False)
    jewel(p, lx, 82, 4.0, off="jewel_grn_off", on=PZ)
    p.lamp(disc(d, lx, 82, 4.0), "on", "#5cff7a")
    p.label("FAN", lx, 90, "paint_w", align="c", auto_ink=False)
    louvers(p, 278, 24, 44, 74, 5, on=PZ, depth=2.2)
    if worn:
        st = WR.mat_mask(d, "alu")
        WR.brushed_sheen(d, st, 70, 40, 0.07, 270, 336, 0.02)
        WR.grime(d, d.solid, amount=0.30, seed=32)
        WR.scuffs(d, WR.mat_mask(d, "panel_black"), 0.0012, seed=33, amount=0.10)
    return p


# =================================================================================== Fryers Club "Industrial 2000" deep fryer
def fryer(units="F", on=False, worn=True):
    """the badge moves up to its own band over the control box; the box keeps every control at full size"""
    W, H = 336, 156
    p = Plate("fryer", W, H, seed=17, title="Fryers Club deep fryer")
    d = p.d
    body = Mask(W, H).rrect(0, 0, W, H, 3).get()
    d.slab(body, Z_FACE, "alu", bevel=2.0, polish=0.6); d.grain_brushed(body, 0.045, seed=34)
    bx0, by0, bw, bh = 12, 10, 104, 30
    badge = Mask(W, H).rrect(bx0, by0, bw, bh, 4).get()
    d.slab(badge, 1.4, "enamel_red", bevel=1.2, polish=0.8, on=Z_FACE)
    chrome_frame(d, bx0 - 1, by0 - 1, bw + 2, bh + 2, Z_FACE, t=1, mat="chrome", z=1.8)
    p.label("FRYERS CLUB", bx0 + bw // 2, by0 + 6, "paint_w", align="c", font="57", auto_ink=False)
    p.label("INDUSTRIAL 2000", bx0 + bw // 2, by0 + 18, "paint_c", align="c", auto_ink=False)
    louvers(p, 132, 14, W - 144, 22, 26, on=Z_FACE, depth=2.0)
    cx0, cy0, cw, ch = 12, 48, W - 24, 86
    box = Mask(W, H).rrect(cx0, cy0, cw, ch, 2).get()
    d.slab(box, 2.0, "panel_black", bevel=1.2, polish=0.4, on=Z_FACE)
    CZ = Z_FACE + 2.0
    for sx, sy in ((cx0 + 4, cy0 + 4), (cx0 + cw - 5, cy0 + 4), (cx0 + 4, cy0 + ch - 5), (cx0 + cw - 5, cy0 + ch - 5)):
        screw(p, sx, sy, on=CZ, mat="alu")
    oy = cy0 - 12
    rx = 38
    p.label("POWER", rx, oy + 20, "paint_w", align="c", auto_ink=False)
    rocker_switch(p, rx - 8, oy + 32, 16, 28, on, on=CZ)
    win = rbox(d, rx - 6, oy + 34, 12, 11)
    d.mat[win & d.solid] = d.mid("jewel_red_off"); d.flatlight[win] = True
    p.lamp(win, "on", "#ff4a2a", halo=False)
    p.label("ON", rx + 14, oy + 35, "paint_w", auto_ink=False); p.label("OFF", rx + 14, oy + 52, "paint_w", auto_ink=False)
    p.hit("onoff", rx - 10, oy + 30, 20, 32, needs="powered")
    kx = 116
    fluted_knob(p, kx, oy + 50, 13, on=CZ, z=4.0, mat="blackp", skirt=2.0, skirt_mat="chrome", ridges=22, dome=0.6 if worn else 0)
    thermostat_scale(p, kx, oy + 50, 17.5, units, mat="paint_w", wear=0.10 if worn else 0)
    p.label("TEMPERATURE", kx, oy + 86, "paint_w", align="c", auto_ink=False)
    p.part("ptr", src="ovenStop", cx=kx, cy=oy + 50, r0=2, r1=11, angles=OVEN_STOP_ANGLES, color="#f2efe6", w=1)
    p.hit("heat", kx - 16, oy + 34, 32, 32, needs="powered", kind="turn")
    jewel(p, 184, oy + 44, 4.0, off="jewel_off", on=CZ)
    p.lamp(disc(d, 184, oy + 44, 4.0), "on", "#ffa630")
    p.label("HEATING", 184, oy + 52, "paint_w", align="c", auto_ink=False)
    tx = 262
    fluted_knob(p, tx, oy + 50, 13, on=CZ, z=4.0, mat="blackp", skirt=2.0, skirt_mat="chrome", ridges=22, dome=0.6 if worn else 0)
    minutes_scale(p, tx, oy + 50, 17.5, mat="paint_w", wear=0.08 if worn else 0)
    p.label("BASKET TIMER", tx, oy + 86, "paint_w", align="c", auto_ink=False)
    p.part("ptr", src="timerF", cx=tx, cy=oy + 50, r0=2, r1=11, a0=-90, a1=210, color="#f2efe6", w=1)
    p.hit("timer", tx - 16, oy + 34, 32, 32, needs="powered", kind="turn")
    louvers(p, 12, 140, W - 24, 9, 30, on=Z_FACE, depth=2.0)
    if worn:
        st = WR.mat_mask(d, "alu")
        WR.brushed_sheen(d, st, 50, 30, 0.07, 290, 336, 0.02)
        WR.grime(d, d.solid, amount=0.36, seed=35)
        WR.specks(d, WR.face(d, Z_FACE, body), 0.003, seed=36, amount=0.3)
        WR.gloss(d, WR.mat_mask(d, "enamel_red"), band=(0.5, 30, 6, 0.12))
    return p


MOCK = {"oven_green": green_range, "oven_red": red_range, "oven_grey": grey_range, "oven_modern": modern_range,
        "oven_industrial": industrial_range, "oven_large": convection_oven, "fryer": fryer}
