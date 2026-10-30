"""MOCKUP (Oct 29 2026): microwaves, generators and the grill re-laid to the 336 px main face (PLATE_SIZES_SPEC.md).
Same parts and state wiring as d_micro / d_gen / d_grill; only the layout changes."""
import numpy as np
from scipy import ndimage as ndi

from physlib import *            # noqa: F401,F403
import wear as WR
import d_micro as DM
import d_gen as DG
import d_grill as DGR
import m_brands as MB

W = 336
NW = 200


def door_strip(p, W, H, case_mat, door_mat, cooking, door_right):
    """the narrow faces' door: the case, the door to `door_right`, a sliver of its window"""
    d = p.d
    case = Mask(W, H).rrect(-12, 0, W + 12, H, 7).get()
    d.slab(case, Z_FACE, case_mat, bevel=2.5, polish=0.6)
    DZ = Z_FACE + 1.0
    door = Mask(W, H).rrect(-12, 7, door_right + 12, H - 14, 4).get()
    d.slab(door, 1.0, door_mat, bevel=1.5, polish=0.6, on=Z_FACE)
    mesh_window(p, 0, 19, door_right - 22, H - 38, r=4, on=DZ, depth=2.2, lit=cooking, crop_left=True)
    return DZ


# =================================================================================== microwaves: the door narrows, the panel stays
def mw_white(cooking=False, worn=True, narrow=False):
    H = 168
    W = NW if narrow else 336
    p = Plate("mw_white" + ("_n" if narrow else ""), W, H, seed=21, title="1990 touchpad microwave")
    d = p.d
    px0, py0, pw, ph = W - 160, 9, 150, H - 18
    if narrow:
        DZ = door_strip(p, W, H, "enamel_white", "enamel_white", cooking, px0 - 8)
        door = rbox(p.d, -12, 7, px0 - 8 + 12, H - 14) & (p.d.mat == p.d.mid("enamel_white"))
    else:
        case, door, DZ = DM.door_and_case(p, W, H, "enamel_white", "enamel_white", cooking, door_w=px0 + 4)
    grip = Mask(W, H).rrect(px0 - 25, 40, 7, H - 80, 3).get()
    d.well(grip, 1.4, "enamel_white", bevel=1.5)
    d.seam(rbox(d, px0 - 8, 7, 1, H - 14), 0.6)
    PZ = Z_FACE - 0.4
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "pad_panel", polish=0.3)
    d.seam(panel & ~ndi.binary_erosion(panel, iterations=1), 0.35)
    cx = px0 + pw // 2
    MB.valutech_logo(p, cx, 14)
    lx, ly, lw, lh = px0 + 9, 26, pw - 18, 28
    window_glass(p, lx, ly, lw, lh, face="ledglass", bezel="blackp", depth=1.4, on=PZ, r=1, bezel_t=2, lens=True)
    p.part("digits", src="mwText", x=lx + 18, y=ly + 6, cw=10, ch=16, pitch=14, st=2, n=5, color="#ff3b2a", ghost="#2c0a09", align="r")
    lamp_text(p, "COOK", lx + lw - 5, ly + 7, "cooking", "#ff3b2a", off="ledoff", align="r")
    by = ly + lh + 6
    p.label("POWER", px0 + 9, by, "paint_k")
    bars = []
    bx0 = px0 + 9 + text_w("POWER") + 6
    for i in range(5):
        m = rbox(d, bx0 + i * 12, by, 10, 5)
        d.well(m, 0.6, "ledoff", bevel=0.4)
        bars.append(runs_of(m))
    p.part("bars", src="mwPower", max=5, bars=bars, color="#ff3b2a")
    p.ink_rect(bx0, by, 58, 5, "power lamps")
    p.label("HI", bx0 + 62, by, "paint_k")
    gx0, gw, gap = px0 + 8, 42, 4
    y = by + 12
    used = {"start": 0.20, "d1": 0.12, "d3": 0.12, "d0": 0.14, "power": 0.08}
    def pad(id_, x, yy, w, h, a, b=None, ink="paint_k", font="35"):
        membrane_pad(p, x, yy, w, h, a, label2=b, lab_mat=ink, on=PZ, font=font, wear=used.get(id_, 0.0) if worn else 0.0)
        p.hit(id_, x, yy, w, h, needs="powered")
    pad("power", gx0, y, 65, 15, "POWER", "LEVEL", ink="paint_b")
    pad("timecook", gx0 + 69, y, 65, 15, "TIME", "COOK", ink="paint_b")
    y += 18
    for row in ((1, 2, 3), (4, 5, 6), (7, 8, 9)):
        for c, n in enumerate(row):
            pad(f"d{n}", gx0 + c * (gw + gap), y, gw, 13, str(n), font="57")
        y += 16
    pad("stop", gx0, y, gw, 15, "STOP", "CLEAR", ink="paint_r")
    pad("d0", gx0 + gw + gap, y, gw, 15, "0", font="57")
    pad("start", gx0 + 2 * (gw + gap), y, gw, 15, "START", ink="paint_g")
    if worn:
        white_m = WR.mat_mask(d, "enamel_white")
        WR.gloss(d, white_m, band=(0.45, 210, 10, 0.08))
        WR.grime(d, d.solid, amount=0.24, seed=23)
        WR.scuffs(d, white_m & (d.YY > H - 20) & (d.XX < px0 - 8), 0.004, seed=24, amount=-0.09)
    return p


def mw_chrome(cooking=False, worn=True, narrow=False):
    """the fancy one (director, Oct 29 2026: flat buttons, 1993 or older, not today's): brushed chrome, smoked glass
    over the controls, a blue-green fluorescent display (the time, COOK, the power level in five bars), printed glass
    keys laid out like the white microwave's, so it uses the controls the game already runs for that one"""
    H = 168
    W = NW if narrow else 336
    p = Plate("mw_chrome" + ("_n" if narrow else ""), W, H, seed=22, title="1988 countertop microwave")
    d = p.d
    px0, py0, pw, ph = W - 162, 8, 152, H - 16
    if narrow:
        DZ = door_strip(p, W, H, "steel", "alu", cooking, px0 - 6)
        door = rbox(p.d, -12, 7, px0 - 8 + 12, H - 14) & (p.d.mat == p.d.mid("alu"))
    else:
        case, door, DZ = DM.door_and_case(p, W, H, "steel", "alu", cooking, door_w=px0 + 6)
    d.grain_brushed(door & (d.mat == d.mid("alu")), 0.035, seed=40)
    d.cyl(px0 - 24, 30, 8, H - 60, 3.0, "chrome", axis="v", polish=1.0, on=DZ)
    d.seam(rbox(d, px0 - 6, 7, 1, H - 14), 0.6)
    PZ = Z_FACE + 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.slab(panel, 0.6, "alu", bevel=1.0, polish=0.6, on=Z_FACE); d.grain_brushed(panel, 0.04, seed=41)
    gx0, gy0, gw, gh = px0 + 6, py0 + 6, pw - 12, ph - 12
    G = PZ + 0.4
    glass_panel(p, gx0, gy0, gw, gh, on=G, r=2, frame="chrome")
    p.label("PREMIUM TECHNOLOGIES", gx0 + gw // 2, gy0 + 7, "paint_w", align="c", auto_ink=False)
    TEAL, TEAL_GHOST = "#52f2d6", "#0a201d"
    vx, vy, vw, vh = gx0 + 8, gy0 + 18, gw - 16, 26
    d.flat(rbox(d, vx, vy, vw, vh), G - 0.2, "vfd", polish=0.6)
    lamp_text(p, "COOK", vx + 4, vy + 4, "cooking", TEAL, off="vfdoff")
    bars = []
    for i in range(5):
        m = rbox(d, vx + 4 + i * 5, vy + 14, 4, 6)
        d.paint(m, "vfdoff", flatlight=True)
        bars.append(runs_of(m))
    p.part("bars", src="mwPower", max=5, bars=bars, color=TEAL)
    p.ink_rect(vx + 4, vy + 14, 24, 6, "power bars")
    p.part("digits", src="mwText", x=vx + vw - 4 - 5 * 13, y=vy + 5, cw=9, ch=15, pitch=13, st=2, n=5, color=TEAL,
           ghost=TEAL_GHOST, align="r")
    p.ink_rect(vx + vw - 4 - 5 * 13, vy + 5, 5 * 13, 15, "display figures")
    kx0, kw, g = vx, 40, 2
    y = vy + vh + 6
    def pad(id_, x, yy, w, h, a, b=None, ink="paint_w", font="35"):
        glass_pad(p, x, yy, w, h, a, ink=ink, font=font, label2=b)
        p.hit(id_, x, yy, w, h, needs="powered")
    half = (vw - g) // 2
    pad("power", kx0, y, half, 15, "POWER", "LEVEL")
    pad("timecook", kx0 + half + g, y, vw - half - g, 15, "TIME", "COOK")
    y += 17
    for row in ((1, 2, 3), (4, 5, 6), (7, 8, 9)):
        for c, n in enumerate(row):
            pad(f"d{n}", kx0 + c * (kw + g), y, kw, 13, str(n), font="57")
        y += 15
    pad("stop", kx0, y, kw, 15, "STOP", "CLEAR", ink="paint_r")
    pad("d0", kx0 + kw + g, y, kw, 15, "0", font="57")
    pad("start", kx0 + 2 * (kw + g), y, kw, 15, "START", ink="paint_g")
    if y + 15 > gy0 + gh - 2: p.warn(f"keys run to {y + 15}, past the glass ({gy0 + gh})")
    if worn:
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 120, 40, 0.06, px0 - 120, px0 + 152, 0.02)
        gl = WR.mat_mask(d, "blackglass")
        WR.gloss(d, gl, band=(0.6, px0 + 40, 20, 0.26))
        WR.gloss(d, gl, band=(0.6, px0 + 64, 3, 0.36))
        WR.smudge(d, gl & (d.YY > vy + vh), amount=-0.06, seed=44, sigma=1.6, thresh=0.80)
        WR.grime(d, d.solid, amount=0.24, seed=42)
        WR.specks(d, WR.mat_mask(d, "steel"), 0.004, seed=43, amount=0.3)
    return p


# =================================================================================== generators
def gen_red(running=False, connected=False, worn=True):
    """one row, tighter: every control at full size"""
    H = 150
    p = Plate("gen_red", W, H, seed=31, title="1988 portable generator")
    d = p.d
    DG.housing(p, W, H, "gen_red")
    lx_, ly_, lw_, lh_ = MB.lectromax_badge(p, 46, 19, on=Z_FACE, box="lx_dark")
    p.label("4000 WATT GENERATOR", lx_ + lw_ + 6, 23, "paint_w", auto_ink=False)
    sticker(p, W - 104, 11, 86, 19, "WARNING", lines=3)
    px0, py0, pw, ph = 12, 34, W - 24, 88
    PZ = Z_FACE - 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "panel_black", polish=0.35); d.grain_pebble(panel, 0.03, seed=8)
    ax = 34
    p.label("ENGINE", ax, 40, "paint_w", align="c")
    rocker_switch(p, ax - 8, 50, 16, 28, running, on=PZ)
    p.label("ON", ax + 14, 53, "paint_w", wear=0.15 if worn else 0); p.label("OFF", ax + 14, 70, "paint_w", wear=0.12 if worn else 0)
    p.hit("engine", ax - 10, 48, 20, 32)
    fluted_knob(p, ax, 99, 5, on=PZ, z=3.0, mat="blackp", skirt=None, ridges=10)
    p.label("CHOKE", ax, 108, "paint_w", align="c")
    p.hit("choke", ax - 7, 92, 14, 14, kind="look")
    bx = 88
    jewel(p, bx, 56, 3.5, off="jewel_red_off", bezel="chrome", on=PZ)
    p.lamp(disc(d, bx, 56, 3.5), "running", "#ff4a2a")
    p.label("OUTPUT", bx, 63, "paint_w", align="c")
    jewel(p, bx, 84, 3.5, off="jewel_off", bezel="chrome", on=PZ)
    p.lamp(disc(d, bx, 84, 3.5), "service", "#ffb02e")
    p.label("OIL ALERT", bx, 91, "paint_w", align="c")
    o1, o2 = 132, 162
    p.label("120V AC 20A", (o1 + o2) // 2, 40, "paint_w", align="c")
    faces = DG.outlet_duplex(p, o1, 66, on=PZ, plate_mat="steel")
    DG.outlet_duplex(p, o2, 66, on=PZ, plate_mat="steel")
    if connected:
        plug(p, faces[1], on=PZ, cord_to=H)
    p.hit("outlet", o1 - 11, 51, 22, 30)
    wing_nut(p, o2, 98, on=PZ)
    p.label("GROUND", o2, 106, "paint_w", align="c")
    cx_ = 224
    p.label("CIRCUIT BREAKERS", cx_, 40, "paint_w", align="c")
    for k in (-16, 16):
        breaker(p, cx_ + k, 58, on=PZ)
        p.label("20A", cx_ + k, 66, "paint_w", align="c")
        p.hit(f"breaker{k}", cx_ + k - 6, 52, 12, 12, kind="look")
    p.label("DC 12V 8A", cx_, 80, "paint_w", align="c")
    binding_post(p, cx_ - 16, 97, "paint_r", on=PZ); binding_post(p, cx_ + 16, 97, "blackp", on=PZ)
    p.label("+", cx_ - 16, 105, "paint_w", align="c"); p.label("-", cx_ + 16, 105, "paint_w", align="c")
    gx, gy, gr = 290, 78, 24
    an = fuel_gauge(p, gx, gy, gr, on=PZ)
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **an)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    DG.finish(p, W, H, "steel", "gen_red", 33, worn)
    if worn:
        WR.chips(d, WR.mat_mask(d, "decal_y"), 0.03, seed=35, near=1.5, mat="gen_red", dh=0.0)
    return p


def gen_yellow(running=False, connected=False, worn=True):
    """one row plus a right-hand column: the breakers over the fuel gauge; IDLE CONTROL and the locking outlet's
    rating wrap to two lines, BREAKERS loses CIRCUIT"""
    H = 160
    p = Plate("gen_yellow", W, H, seed=41, title="contractor's generator")
    d = p.d
    DG.housing(p, W, H, "gen_yellow")
    p.label("PREMIUM TECHNOLOGIES", 20, 13, "paint_k", font="57", auto_ink=False)
    p.label("CONTRACTOR 5500", 16, 23, "paint_k", auto_ink=False)
    sticker(p, W - 104, 11, 86, 19, "CAUTION", lines=3, mat="enamel_white")
    px0, py0, pw, ph = 12, 34, W - 24, 98
    PZ = Z_FACE - 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "steel", polish=0.4); d.grain_pebble(panel, 0.03, seed=42)
    ex, ey = 40, 72
    p.label("ENGINE", ex, 42, "paint_w", align="c")
    fluted_knob(p, ex, ey, 9, on=PZ, z=4.0, mat="blackp", skirt=None, ridges=14, dome=0.6)
    scale_ring(p, ex, ey, 11.5, [-135, -45], ["OFF", "RUN"], mat="paint_w", wear=0.12 if worn else 0)
    p.part("ptr", src="running", cx=ex, cy=ey, r0=1, r1=7, angles=[-135, -45], color="#f0ede4", w=1)
    p.hit("engine", ex - 12, ey - 12, 24, 24)
    p.label("IDLE", ex, 89, "paint_w", align="c")
    p.label("CONTROL", ex, 96, "paint_w", align="c")
    bat_toggle(p, ex, 114, True, on=PZ)
    p.hit("idle", ex - 6, 102, 12, 20, kind="look")
    an = rect_meter(p, 70, 48, 66, 42, ["0", "100", "200", "300"], 212, 328, on=PZ, title=None)
    p.part("needle", src="volts", color="#d42a1c", w=1, hub=2, **{**an, "a1": an["a0"] + (an["a1"] - an["a0"]) * 0.8})
    p.label("AC VOLTMETER", 103, 96, "paint_w", align="c")
    tx, ty = 166, 76
    p.label("120/240V", tx, 42, "paint_w", align="c")
    p.label("30A", tx, 49, "paint_w", align="c")
    twist_lock(p, tx, ty, 11, on=PZ)
    if connected:
        twist_plug(p, tx, ty, 12, on=PZ, cord_to=H)
    p.hit("outlet", tx - 15, ty - 15, 30, 30)
    for i, cx in enumerate((206, 232)):
        outlet_cover(p, cx, 76, on=PZ)
        p.hit(f"cover{i}", cx - 11, 61, 22, 30, kind="look")
    p.label("120V 20A", 219, 42, "paint_w", align="c")
    bcx = 290
    p.label("BREAKERS", bcx, 42, "paint_w", align="c")
    for kid, k, amps in ((-24, -17, "30A"), (0, 0, "20A"), (24, 17, "20A")):       # ids as today's plate
        breaker(p, bcx + k, 58, on=PZ)
        p.label(amps, bcx + k, 66, "paint_w", align="c")
        p.hit(f"breaker{kid}", bcx + k - 6, 52, 12, 12, kind="look")
    gx, gy, gr = bcx, 102, 20
    gan = fuel_gauge(p, gx, gy, gr, on=PZ)
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **gan)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    DG.finish(p, W, H, "blackp", "gen_yellow", 43, worn, louver_y=H - 23)
    return p


def gen_blue(running=False, connected=False, worn=True):
    H = 150
    p = Plate("gen_blue", W, H, seed=51, title="1991 compact generator")
    d = p.d
    body = Mask(W, H).rrect(2, 2, W - 4, H - 4, 16).get()
    d.slab(body, Z_FACE, "gen_blue", bevel=6.0, polish=0.55, power=0.6)
    d.cyl(W // 2 - 78, 6, 156, 6, 2.2, "gen_blue", axis="h", polish=0.6, on=Z_FACE)
    vx_, vy_, vw_, vh_ = MB.valutech_logo(p, 52, 14)
    p.label("QUIET SERIES 1000", 22, 25, "paint_w", auto_ink=False)
    for i in range(7):
        d.well(Mask(W, H).rrect(W - 104, 12 + i * 3, 80, 2, 1).get(), 1.6, "blackp", bevel=0.6)
    px0, py0, pw, ph = 12, 38, W - 24, 88
    PZ = Z_FACE - 1.2
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 8).get()
    d.well(panel, 1.2, "panel_black", bevel=2.5, polish=0.45); d.grain_pebble(panel, 0.03, seed=52)
    ex, ey = 44, 86
    p.label("ENGINE", ex, 56, "paint_w", align="c")
    fluted_knob(p, ex, ey, 10, on=PZ, z=4.0, mat="blackp", skirt=1.6, skirt_mat="gen_blue", ridges=12, dome=0.6)
    scale_ring(p, ex, ey, 14.0, [-135, -45], ["OFF", "ON"], mat="paint_w", wear=0.12 if worn else 0)
    p.part("ptr", src="running", cx=ex, cy=ey, r0=1, r1=8, angles=[-135, -45], color="#f0ede4", w=1)
    p.hit("engine", ex - 13, ey - 13, 26, 26)
    for lx, lab, src, off, col in ((90, "OUTPUT", "running", "jewel_grn_off", "#5cff7a"), (126, "OVERLOAD", "overload", "jewel_red_off", "#ff4a2a"),
                                   (160, "OIL", "service", "jewel_off", "#ffb02e")):
        jewel(p, lx, 64, 3.5, off=off, bezel="blackp", on=PZ)
        p.lamp(disc(d, lx, 64, 3.5), src, col)
        p.label(lab, lx, 72, "paint_w", align="c")
    rocker_switch(p, 116, 92, 18, 12, False, on=PZ, lift=1.6)
    p.label("ECO THROTTLE", 125, 110, "paint_w", align="c")
    p.hit("eco", 114, 90, 22, 16, kind="look")
    p.label("120V 15A", 202, 56, "paint_w", align="c")
    faces = DG.outlet_duplex(p, 202, 88, on=PZ, plate_mat="blackp", mat="socket")
    if connected:
        plug(p, faces[1], on=PZ, cord_to=H)
    p.hit("outlet", 191, 73, 22, 30)
    p.label("DC 12V", 248, 72, "paint_w", align="c")
    binding_post(p, 238, 90, "paint_r", on=PZ); binding_post(p, 258, 90, "blackp", on=PZ)
    p.label("+", 238, 98, "paint_w", align="c"); p.label("-", 258, 98, "paint_w", align="c")
    gx, gy, gr = 296, 86, 21
    gan = fuel_gauge(p, gx, gy, gr, on=PZ)
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **gan)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    if worn:
        b = WR.mat_mask(d, "gen_blue")
        WR.gloss(d, b, band=(0.45, 70, 10, 0.10))
        WR.scuffs(d, b, 0.0015, seed=53, amount=0.12)
        WR.grime(d, d.solid, amount=0.30, seed=54)
    return p


def gen_old(running=False, connected=False, worn=True):
    """two rows: the three meters and the fuel gauge on top; the guarded toggles, the load terminals and the data plate under"""
    H = 200
    p = Plate("gen_old", W, H, seed=61, title="1960s military generator")
    d = p.d
    DG.housing(p, W, H, "olive_drab", polish=0.2)
    p.label("GENERATOR SET", 18, 13, "paint_c", font="57", auto_ink=False)
    p.label("GASOLINE ENGINE DRIVEN", 18, 23, "paint_c", auto_ink=False)
    PZ = Z_FACE
    meters = (("VOLTS", ["0", "50", "100", "150"], "volts", 0.8), ("AMPERES", ["0", "10", "20", "30"], "load", 1.0),
              ("FREQUENCY", ["55", "", "60", "", "65"], "hz", 0.5))
    for i, (title, labels, src, at) in enumerate(meters):
        mx = 44 + i * 68
        an = round_meter(p, mx, 70, 24, labels, a0=150, a1=390, on=PZ, title=None)
        span = an["a1"] - an["a0"]
        p.part("needle", src=src, color="#f0e9d8", w=1, hub=2.5, cx=an["cx"], cy=an["cy"], r0=-3, r1=20, a0=an["a0"],
               a1=an["a0"] + span * at)
        p.label(title, mx, 102, "paint_c", align="c", auto_ink=False)
        p.hit("meter" + str(i), mx - 24, 46, 48, 48, kind="look")
    gx, gy, gr = 280, 72, 22
    gan = fuel_gauge(p, gx, gy, gr, on=PZ, face="cream")
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **gan)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    dy = 82
    for tx, (l1, l2), live in ((40, ("MASTER", "SWITCH"), True), (84, ("BATTLE", "SHORT"), False)):
        p.label(l1, tx, 36 + dy, "paint_c", align="c", auto_ink=False)
        p.label(l2, tx, 43 + dy, "paint_c", align="c", auto_ink=False)
        bat_toggle(p, tx, 70 + dy, running if live else False, on=PZ, guard=True)
        if live:
            p.hit("engine", tx - 7, 56 + dy, 14, 28)
        else:
            p.hit("battle", tx - 7, 56 + dy, 14, 28, kind="look")
    p.label("ON", 49, 58 + dy, "paint_c", auto_ink=False)
    p.label("OFF", 49, 78 + dy, "paint_c", auto_ink=False)
    sx0, sy0 = 120, 130
    studs = terminal_board(p, sx0, sy0, ["L1", "L2", "L0"], on=PZ, pitch=18)
    if connected:
        for sx, sy in studs:
            lug = Mask(W, H).rrect(sx - 3, sy - 3, 6, 9, 2).get()
            d.slab(lug, 3.6, "chrome", bevel=1.2, polish=1.0, on=PZ + 1.6)
            d.cyl(sx - 2, sy + 5, 4, H - (sy + 5), 3.0, "cord", axis="v", polish=0.6, on=PZ)
    p.hit("outlet", sx0, sy0, 60, 28)
    data_plate(p, W - 132, 132, 112, 26, ["3 KILOWATT 120/240 VOLT", "60 CYCLE  SERIAL 1428"], on=Z_FACE, mat="alu", title=None)
    for x in range(16, W - 12, 28):
        for y in (34, H - 34):
            d.dome(x, y, 1.5, 1.5, 1.0, "olive_drab", polish=0.4, on=Z_FACE)
    DG.finish(p, W, H, "olive_drab", "olive_drab", 63, worn, louver_y=H - 26)
    return p


# =================================================================================== the grill: the badge goes up on the lid
def grill_propane(tank=False, worn=True):
    H = 156
    p = Plate("grill_propane", W, H, seed=71, title="propane grill")
    d = p.d
    for sx in (0, W - 20):
        for k in range(2):
            b = Mask(W, H).rrect(sx, 47 + k * 6, 20, 5, 1).get()
            d.slab(b, 2.0, "walnut", bevel=1.0, polish=0.3, on=Z_FACE - 1.0)
            d.grain_wood(b, scale=0.6, seed=72 + k)
    cart = Mask(W, H).rrect(24, 102, W - 48, H - 102, 2).get()
    d.slab(cart, Z_FACE - 0.5, "enamel_black", bevel=1.5, polish=0.5)
    ox0, ow = 100, 144
    opening = Mask(W, H).rrect(ox0, 110, ow, H - 110 + 4, 2).get()
    d.well(opening, 3.0, "blackp", bevel=1.2)
    door = Mask(W, H).rrect(252, 110, 60, H - 112, 2).get()
    d.slab(door, 0.8, "enamel_black", bevel=1.0, polish=0.55, on=Z_FACE - 0.5)
    d.cyl(264, 126, 4, 14, 1.8, "chrome", axis="v", polish=1.0, on=Z_FACE + 0.3)
    gx, gy = 60, 130
    gan = fuel_gauge(p, gx, gy, 14, on=Z_FACE - 0.5, label=None)
    p.part("needle", src="tankF", color="#d42a1c", w=1, hub=2, **gan)
    p.label("TANK", gx, gy + 18, "paint_w", align="c", auto_ink=False, check=False)
    p.hit("gauge", gx - 14, gy - 14, 28, 28, kind="look")
    tc = ox0 + ow // 2                     # the tank's centre line (228 on the 456 plate)
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
    panel = Mask(W, H).rrect(22, 48, W - 44, 54, 2).get()
    d.slab(panel, Z_FACE, "alu", bevel=1.6, polish=0.6); d.grain_brushed(panel, 0.045, seed=73)
    p.label("GAS GRILL", 46, 86, "paint_k", align="c")
    for i, kx in enumerate((98, 158, 218)):
        fluted_knob(p, kx, 75, 11, on=Z_FACE, z=4.2, mat="blackp", skirt=1.8, skirt_mat="chrome", ridges=18, dome=0.7 if worn else 0)
        scale_ring(p, kx, 75, 15.0, [-90, 180, 45], ["OFF", "HI", "LO"], minor_angles=[150, 120, 90, 67], wear=0.15 if worn else 0)
        p.part("ptr", src="lit", cx=kx, cy=75, r0=2, r1=9, angles=[-90, 180], color="#f2efe6", w=1)
        p.hit("burner" if i == 1 else f"burner{i}", kx - 14, 61, 28, 28, kind="press" if i == 1 else "look")
    ix, iy = 278, 72
    d.torus(ix, iy, 5.4, 7.4, 1.6, "chrome", polish=1.0, on=Z_FACE)
    d.dome(ix, iy, 5.4, 5.4, 3.4, "paint_r", polish=0.8, on=Z_FACE, power=0.6)
    p.label("IGNITE", ix, 84, "paint_k", align="c")
    p.hit("ignite", ix - 8, iy - 8, 16, 16)
    gap = rbox(d, 30, 44, W - 60, 4)
    d.flat(gap, Z_FACE - 2.5, "blackp", polish=0.2)
    p.lamp(rbox(d, 34, 45, W - 68, 2), "lit", "#ff8a2a", halo=False)
    hood = Mask(W, H).rrect(26, -8, W - 52, 52, 10).get()
    d.slab(hood, Z_FACE + 2.0, "enamel_black", bevel=5.0, polish=0.85, power=0.5)
    HZ = Z_FACE + 2.0
    for ex0 in (26, W - 26 - 16):
        cap = hood & rbox(d, ex0, -8, 16, 52)
        d.mat[cap] = d.mid("steel"); d.polish[cap] = 0.5
        d.seam(hood & rbox(d, ex0 + (15 if ex0 == 26 else 0), 0, 1, 44), 0.5)
    d.tex[hood & (d.YY >= 5) & (d.YY <= 6) & (d.mat == d.mid("enamel_black"))] += 0.16
    # the maker's badge, on the lid left of the thermometer
    badge = Mask(W, H).rrect(52, 10, 94, 18, 6).get()
    d.slab(badge, 1.2, "chrome", bevel=1.0, polish=1.0, on=HZ)
    nameplate(d, "HECTOR LOPEZ", 99, 15, on=HZ + 1.2, mat="enamel_black", font="57", align="c", z=0.6)
    tan = DGR.thermometer(p, W // 2 + 40, 19, 15, on=HZ)
    p.part("needle", src="grillTemp", color="#1b1b1d", w=1, hub=1.6, **tan)
    p.hit("thermo", W // 2 + 26, 5, 28, 28, kind="look")
    for sx in (W // 2 - 100, W // 2 + 94):
        d.slab(Mask(W, H).rrect(sx, 34, 6, 7, 1).get(), 2.0, "chrome", bevel=1.0, polish=1.0, on=HZ)
    d.cyl(W // 2 - 104, 36, 208, 5, 3.4, "chrome", axis="h", polish=1.0, on=HZ + 1.0)
    if worn:
        hood_m = WR.mat_mask(d, "enamel_black")
        WR.gloss(d, hood_m & (d.YY < 46), band=(0.5, 70, 10, 0.12))
        WR.brushed_sheen(d, WR.mat_mask(d, "alu"), 90, 30, 0.07, 240, 314, 0.025)
        WR.grime(d, d.solid, amount=0.36, seed=74)
        WR.specks(d, hood_m, 0.004, seed=75, amount=-0.2)
        WR.scuffs(d, WR.mat_mask(d, "alu"), 0.0015, seed=76, amount=-0.08)
    return p


MOCK = {"mw_white": mw_white, "mw_chrome": mw_chrome, "gen_red": gen_red, "gen_yellow": gen_yellow, "gen_blue": gen_blue,
        "gen_old": gen_old, "grill_propane": grill_propane}
