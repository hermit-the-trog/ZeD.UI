"""The generators: one front panel per model the game has (its four generator items), each its era's.

The game's generator state: running, connected (to the building; it only runs when connected), fuel (0 to 1),
condition (0 to 1), and the load it carries (from the fuel the powered things burn). Live on every plate: the
run control and its lamp, the fuel, the building's cord in its outlet (a state sprite; the outlet connects or
disconnects); OIL lamps light when the condition is under a quarter; meters read 120 volts and 60 cycles while
it runs and the load as it is. Breakers, chokes, posts and covers are part of the look.
"""
import numpy as np

from physlib import *            # noqa: F401,F403
import wear as WR


def state(running=False, connected=False, fuel=0.5, condition=0.9, load=0.0, **kw):
    s = dict(running=running, connected=connected or running, fuel=fuel, service=condition < 0.25,
             volts=(1.0 if running else 0.0), hz=(1.0 if running else 0.0), load=(load if running else 0.0))
    s.update(kw)
    return s


def housing(p, W, H, mat, frame_mat="steel", polish=0.45, frame=True):
    d = p.d
    hm = Mask(W, H).rrect(4, 4, W - 8, H - 8, 6).get()
    d.slab(hm, Z_FACE, mat, bevel=2.0, polish=polish)
    return hm


def finish(p, W, H, frame_mat, housing_mat, seed, worn, frame=True, louver_y=127):
    d = p.d
    louvers(p, 20, louver_y, W - 40, 10, 46, on=Z_FACE, depth=2.0)
    fr = tube_frame(p, 0, 0, W, H, 12, 6, mat=frame_mat, on=Z_FACE, z=3.0) if frame else None
    if worn:
        body = WR.mat_mask(d, housing_mat)
        WR.gloss(d, body, band=(0.40, 120, 8, 0.09))
        WR.scuffs(d, body, 0.0012, seed=seed, amount=0.12)
        WR.chips(d, WR.face(d, Z_FACE, body), 0.006, seed=seed + 1, near=2.0)
        if fr is not None:
            WR.specks(d, fr, 0.012, seed=seed + 3, amount=0.35)
            WR.scuffs(d, fr, 0.003, seed=seed + 4, length=(2, 5), amount=0.12)
        WR.grime(d, d.solid, amount=0.32, seed=seed + 5)
    return fr


# =================================================================================== red, 1988
def red(running=False, connected=False, worn=True):
    """an enclosed portable set in its tube frame: the maker's decal, a warning label, the black control panel
    (ENGINE rocker, choke, OUTPUT and OIL ALERT lamps, two outlets, ground, breakers, the 12 volt posts), the fuel gauge"""
    W, H = 456, 150
    p = Plate("gen_red", W, H, seed=31, title="1988 portable generator")
    d = p.d
    housing(p, W, H, "gen_red")
    p.label("MASS GENFAC", 16, 13, "paint_w", font="57", auto_ink=False)
    p.label("4000 WATT GENERATOR", 16, 23, "paint_w", auto_ink=False)
    sticker(p, 352, 11, 86, 19, "WARNING", lines=3)
    px0, py0, pw, ph = 12, 34, W - 24, 88
    PZ = Z_FACE - 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "panel_black", polish=0.35); d.grain_pebble(panel, 0.03, seed=8)
    ax = 40
    p.label("ENGINE", ax, 40, "paint_w", align="c")
    rocker_switch(p, ax - 8, 50, 16, 28, running, on=PZ)
    p.label("ON", ax + 14, 53, "paint_w", wear=0.15 if worn else 0); p.label("OFF", ax + 14, 70, "paint_w", wear=0.12 if worn else 0)
    p.hit("engine", ax - 10, 48, 20, 32)
    fluted_knob(p, ax, 99, 5, on=PZ, z=3.0, mat="blackp", skirt=None, ridges=10)
    p.label("CHOKE", ax, 108, "paint_w", align="c")
    p.hit("choke", ax - 7, 92, 14, 14, kind="look")
    bx = 108
    jewel(p, bx, 56, 3.5, off="jewel_red_off", bezel="chrome", on=PZ)
    p.lamp(disc(d, bx, 56, 3.5), "running", "#ff4a2a")
    p.label("OUTPUT", bx, 63, "paint_w", align="c")
    jewel(p, bx, 84, 3.5, off="jewel_off", bezel="chrome", on=PZ)
    p.lamp(disc(d, bx, 84, 3.5), "service", "#ffb02e")
    p.label("OIL ALERT", bx, 91, "paint_w", align="c")
    o1, o2 = 166, 198
    p.label("120V AC 20A", (o1 + o2) // 2, 40, "paint_w", align="c")
    faces = outlet_duplex(p, o1, 66, on=PZ, plate_mat="steel")
    outlet_duplex(p, o2, 66, on=PZ, plate_mat="steel")
    if connected:
        plug(p, faces[1], on=PZ, cord_to=H)
    p.hit("outlet", o1 - 11, 51, 22, 30)
    wing_nut(p, o2, 98, on=PZ)
    p.label("GROUND", o2, 106, "paint_w", align="c")
    cx_ = 274
    p.label("CIRCUIT BREAKERS", cx_, 40, "paint_w", align="c")
    for k in (-16, 16):
        breaker(p, cx_ + k, 58, on=PZ)
        p.label("20A", cx_ + k, 66, "paint_w", align="c")
        p.hit(f"breaker{k}", cx_ + k - 6, 52, 12, 12, kind="look")
    p.label("DC 12V 8A", cx_, 80, "paint_w", align="c")
    binding_post(p, cx_ - 16, 97, "paint_r", on=PZ); binding_post(p, cx_ + 16, 97, "blackp", on=PZ)
    p.label("+", cx_ - 16, 105, "paint_w", align="c"); p.label("-", cx_ + 16, 105, "paint_w", align="c")
    gx, gy, gr = 386, 78, 24
    an = fuel_gauge(p, gx, gy, gr, on=PZ)
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **an)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    fr = finish(p, W, H, "steel", "gen_red", 33, worn)
    if worn:
        WR.chips(d, WR.mat_mask(d, "decal_y"), 0.03, seed=35, near=1.5, mat="gen_red", dh=0.0)
    return p


# =================================================================================== yellow: the contractor's set
def yellow(running=False, connected=False, worn=True):
    """a contractor's set: yellow steel in a black frame; a grey steel panel with the ENGINE switch, an AC
    voltmeter, the locking 120/240 volt outlet (the building's cord locks in here), two covered outlets, three
    breakers, the IDLE CONTROL, and the fuel gauge"""
    W, H = 456, 150
    p = Plate("gen_yellow", W, H, seed=41, title="contractor's generator")
    d = p.d
    housing(p, W, H, "gen_yellow")
    p.label("KNOX POWER", 16, 13, "paint_k", font="57", auto_ink=False)
    p.label("CONTRACTOR 5500", 16, 23, "paint_k", auto_ink=False)
    sticker(p, 352, 11, 86, 19, "CAUTION", lines=3, mat="enamel_white")
    px0, py0, pw, ph = 12, 34, W - 24, 88
    PZ = Z_FACE - 0.6
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 2).get()
    d.flat(panel, PZ, "steel", polish=0.4); d.grain_pebble(panel, 0.03, seed=42)
    # ENGINE: a rotary switch, OFF and RUN
    ex, ey = 40, 72
    p.label("ENGINE", ex, 42, "paint_w", align="c")
    fluted_knob(p, ex, ey, 9, on=PZ, z=4.0, mat="blackp", skirt=None, ridges=14, dome=0.6)
    scale_ring(p, ex, ey, 11.5, [-135, -45], ["OFF", "RUN"], mat="paint_w", wear=0.12 if worn else 0)
    p.part("ptr", src="running", cx=ex, cy=ey, r0=1, r1=7, angles=[-135, -45], color="#f0ede4", w=1)
    p.hit("engine", ex - 12, ey - 12, 24, 24)
    p.label("IDLE CONTROL", ex, 90, "paint_w", align="c")
    bat_toggle(p, ex, 108, True, on=PZ)
    p.hit("idle", ex - 6, 96, 12, 20, kind="look")
    # the voltmeter
    an = rect_meter(p, 76, 44, 70, 42, ["0", "100", "200", "300"], 212, 328, on=PZ, title=None)
    p.part("needle", src="volts", color="#d42a1c", w=1, hub=2, **{**an, "a1": an["a0"] + (an["a1"] - an["a0"]) * 0.8})
    p.label("AC VOLTMETER", 111, 92, "paint_w", align="c")
    # the locking outlet: the building's cord locks in here
    tx, ty = 184, 72
    p.label("120/240V 30A", tx, 42, "paint_w", align="c")
    twist_lock(p, tx, ty, 11, on=PZ)
    if connected:
        twist_plug(p, tx, ty, 12, on=PZ, cord_to=H)
    p.hit("outlet", tx - 15, ty - 15, 30, 30)
    # the covered outlets
    for i, cx in enumerate((236, 266)):
        outlet_cover(p, cx, 72, on=PZ)
        p.hit(f"cover{i}", cx - 11, 57, 22, 30, kind="look")
    p.label("120V 20A", 251, 42, "paint_w", align="c")
    # the breakers
    p.label("CIRCUIT BREAKERS", 328, 42, "paint_w", align="c")
    for k, amps in ((-24, "30A"), (0, "20A"), (24, "20A")):
        breaker(p, 328 + k, 60, on=PZ)
        p.label(amps, 328 + k, 68, "paint_w", align="c")
        p.hit(f"breaker{k}", 328 + k - 6, 54, 12, 12, kind="look")
    # the fuel gauge
    gx, gy, gr = 406, 82, 22
    gan = fuel_gauge(p, gx, gy, gr, on=PZ)
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **gan)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    finish(p, W, H, "blackp", "gen_yellow", 43, worn)
    return p


# =================================================================================== blue: the compact quiet set, 1991
def blue(running=False, connected=False, worn=True):
    """a 1991 compact quiet set: a moulded blue case, a dark moulded panel; the ENGINE switch, OUTPUT, OVERLOAD and
    OIL lamps, the ECO THROTTLE rocker, one outlet, the 12 volt posts and the fuel gauge"""
    W, H = 456, 150
    p = Plate("gen_blue", W, H, seed=51, title="1991 compact generator")
    d = p.d
    body = Mask(W, H).rrect(2, 2, W - 4, H - 4, 16).get()
    d.slab(body, Z_FACE, "gen_blue", bevel=6.0, polish=0.55, power=0.6)
    # the carry handle's front lip, moulded across the top
    d.cyl(150, 6, 156, 6, 2.2, "gen_blue", axis="h", polish=0.6, on=Z_FACE)
    p.label("SUNDOWNER", 22, 14, "paint_w", font="57", auto_ink=False)
    p.label("QUIET SERIES 1000", 22, 24, "paint_w", auto_ink=False)
    for i in range(7):                                       # the moulded intake slots
        d.well(Mask(W, H).rrect(352, 12 + i * 3, 80, 2, 1).get(), 1.6, "blackp", bevel=0.6)
    px0, py0, pw, ph = 16, 38, W - 32, 88
    PZ = Z_FACE - 1.2
    panel = Mask(W, H).rrect(px0, py0, pw, ph, 8).get()
    d.well(panel, 1.2, "panel_black", bevel=2.5, polish=0.45); d.grain_pebble(panel, 0.03, seed=52)
    # ENGINE switch
    ex, ey = 52, 86
    p.label("ENGINE", ex, 56, "paint_w", align="c")
    fluted_knob(p, ex, ey, 10, on=PZ, z=4.0, mat="blackp", skirt=1.6, skirt_mat="gen_blue", ridges=12, dome=0.6)
    scale_ring(p, ex, ey, 14.0, [-135, -45], ["OFF", "ON"], mat="paint_w", wear=0.12 if worn else 0)
    p.part("ptr", src="running", cx=ex, cy=ey, r0=1, r1=8, angles=[-135, -45], color="#f0ede4", w=1)
    p.hit("engine", ex - 13, ey - 13, 26, 26)
    # the lamps
    for lx, lab, src, off, col in ((112, "OUTPUT", "running", "jewel_grn_off", "#5cff7a"), (156, "OVERLOAD", "overload", "jewel_red_off", "#ff4a2a"),
                                   (200, "OIL", "service", "jewel_off", "#ffb02e")):
        jewel(p, lx, 64, 3.5, off=off, bezel="blackp", on=PZ)
        p.lamp(disc(d, lx, 64, 3.5), src, col)
        p.label(lab, lx, 72, "paint_w", align="c")
    # ECO THROTTLE (part of the look)
    rocker_switch(p, 148, 92, 18, 12, False, on=PZ, lift=1.6)
    p.label("ECO THROTTLE", 157, 110, "paint_w", align="c")
    p.hit("eco", 146, 90, 22, 16, kind="look")
    # the outlet
    p.label("120V 15A", 254, 56, "paint_w", align="c")
    faces = outlet_duplex(p, 254, 88, on=PZ, plate_mat="blackp", mat="socket")
    if connected:
        plug(p, faces[1], on=PZ, cord_to=H)
    p.hit("outlet", 243, 73, 22, 30)
    # the 12 volt posts
    p.label("DC 12V", 316, 72, "paint_w", align="c")
    binding_post(p, 304, 90, "paint_r", on=PZ); binding_post(p, 328, 90, "blackp", on=PZ)
    p.label("+", 304, 98, "paint_w", align="c"); p.label("-", 328, 98, "paint_w", align="c")
    # the fuel gauge
    gx, gy, gr = 396, 86, 22
    gan = fuel_gauge(p, gx, gy, gr, on=PZ)
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **gan)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    if worn:
        b = WR.mat_mask(d, "gen_blue")
        WR.gloss(d, b, band=(0.45, 90, 10, 0.10))
        WR.scuffs(d, b, 0.0015, seed=53, amount=0.12)
        WR.grime(d, d.solid, amount=0.30, seed=54)
    return p


# =================================================================================== old: a 1960s military set
def old(running=False, connected=False, worn=True):
    """a 1960s military set: olive drab, stencilled; VOLTS, AMPERES and FREQUENCY meters, the guarded MASTER SWITCH
    and BATTLE SHORT toggles, a riveted data plate, the load terminals (the building's leads bolt on), fuel gauge"""
    W, H = 456, 150
    p = Plate("gen_old", W, H, seed=61, title="1960s military generator")
    d = p.d
    hm = housing(p, W, H, "olive_drab", polish=0.2)
    p.label("GENERATOR SET", 18, 13, "paint_c", font="57", auto_ink=False)
    p.label("GASOLINE ENGINE DRIVEN", 18, 23, "paint_c", auto_ink=False)
    data_plate(p, 326, 10, 112, 26, ["3 KILOWATT 120/240 VOLT", "60 CYCLE  SERIAL 1428"], on=Z_FACE, mat="alu", title=None)
    # the meters
    PZ = Z_FACE
    meters = (("VOLTS", ["0", "50", "100", "150"], "volts", 0.8), ("AMPERES", ["0", "10", "20", "30"], "load", 1.0),
              ("FREQUENCY", ["55", "", "60", "", "65"], "hz", 0.5))
    for i, (title, labels, src, at) in enumerate(meters):
        mx = 44 + i * 70
        an = round_meter(p, mx, 70, 24, labels, a0=150, a1=390, on=PZ, title=None)
        span = an["a1"] - an["a0"]
        p.part("needle", src=src, color="#f0e9d8", w=1, hub=2.5, cx=an["cx"], cy=an["cy"], r0=-3, r1=20, a0=an["a0"],
               a1=an["a0"] + span * at)
        p.label(title, mx, 102, "paint_c", align="c", auto_ink=False)
        p.hit("meter" + str(i), mx - 24, 46, 48, 48, kind="look")
    # the guarded toggles
    for tx, (l1, l2), live in ((262, ("MASTER", "SWITCH"), True), (306, ("BATTLE", "SHORT"), False)):
        p.label(l1, tx, 36, "paint_c", align="c", auto_ink=False)
        p.label(l2, tx, 43, "paint_c", align="c", auto_ink=False)
        bat_toggle(p, tx, 70, running if live else False, on=PZ, guard=True)
        if live:
            p.hit("engine", tx - 7, 56, 14, 28)
        else:
            p.hit("battle", tx - 7, 56, 14, 28, kind="look")
    p.label("ON", 271, 58, "paint_c", auto_ink=False)
    p.label("OFF", 271, 78, "paint_c", auto_ink=False)
    # the load terminals
    studs = terminal_board(p, 330, 46, ["L1", "L2", "L0"], on=PZ, pitch=18)
    if connected:
        for sx, sy in studs:
            lug = Mask(W, H).rrect(sx - 3, sy - 3, 6, 9, 2).get()
            d.slab(lug, 3.6, "chrome", bevel=1.2, polish=1.0, on=PZ + 1.6)
            d.cyl(sx - 2, sy + 5, 4, H - (sy + 5), 3.0, "cord", axis="v", polish=0.6, on=PZ)
    p.hit("outlet", 330, 46, 60, 28)
    # the fuel gauge
    gx, gy, gr = 414, 84, 20
    gan = fuel_gauge(p, gx, gy, gr, on=PZ, face="cream")
    p.part("needle", src="fuel", color="#d42a1c", w=1, hub=2, **gan)
    p.hit("fuel", gx - gr, gy - gr, 2 * gr, 2 * gr, kind="look")
    # rivets round the panel
    for x in range(16, W - 12, 28):
        for y in (34, 116):
            d.dome(x, y, 1.5, 1.5, 1.0, "olive_drab", polish=0.4, on=Z_FACE)
    fr = finish(p, W, H, "olive_drab", "olive_drab", 63, worn, louver_y=124)
    return p
