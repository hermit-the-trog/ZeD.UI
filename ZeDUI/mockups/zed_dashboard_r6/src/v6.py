"""ZeD dashboards, round 6 (director, Oct 24 2026): the parts the round adds or replaces.

  1. The key sits to the right of the steering column (the column comes up under the middle of the cluster,
     COLUMN_X) and turns: OFF, ON, START, three key sprites the game steps through while it cranks.
     The fake vent at the right of the lower dash is gone; the driver's own vent sits low on the left,
     under the outer end of the gauges.
  2. The console: the radio against the console's left edge, the ash tray (and the lighter) to its right.
     Some ash trays hang open with butts in them (a sprite, per car); the emergency vehicles carry a
     NO SMOKING plate there instead; the vans carry their sticker there. The taxi gets a fare meter that
     runs (a flag you pull) and a hula girl on the dash top. The vents are larger and built like vents:
     a bezel, the horizontal louvers in front with the centre tab you push them by, the vertical vanes
     behind, a thumbwheel to shut them.
"""
import math
import numpy as np
from engine import RAMPS, hx, add_ramp, text_w, edt, FONTS
from widgets import window, chrome_frame, knob, button, icon_mask, line_mask, rivet
import dashlib as DL
from dashlib import W, H, Z_FACE, box

add_ramp("ash", "#a29e96")
add_ramp("cork", "#c8874a")
add_ramp("paper", "#e6e2d6")
add_ramp("skin", "#c8875a")
add_ramp("grass", "#6a9a3a")
add_ramp("lei", "#e8508a")

COLUMN_X = 250          # the steering column: the binnacle is centred on it, on every shell
KEY_DX = 50             # the key's centre, right of the column


# ====================================================================== vents
def vent_louvered(b, x, y, w, h, bezel="chrome", on=Z_FACE, wheel="right", check=True):
    """a rectangular vent built like one: a bezel, horizontal louvers in front (one carries the tab you push them by),
    the vertical vanes behind them, a knurled thumbwheel at one end that shuts it"""
    d = b.d
    if check: b.check_flat(x - 1, y - 1, w + 2, h + 2, "vent")
    depth = 4.5
    inner = window(d, x, y, w, h, depth, face="blackp", bezel=bezel, r=2, bezel_t=2, on=on, lens=False)
    floor = on - depth
    wx0, wx1 = (x + w - 11, x + w - 3) if wheel == "right" else (x + 3, x + 11)
    vx0, vx1 = (x + 3, wx0 - 1) if wheel == "right" else (wx1 + 1, x + w - 3)
    if wheel:
        div = inner & (d.XX >= (wx0 - 1 if wheel == "right" else wx1)) & (d.XX < (wx0 if wheel == "right" else wx1 + 1))
        d.h[div] = on - 0.6; d.mat[div] = d.mid(bezel if bezel else "blackp")
    # the vertical vanes, deep and dark
    for vx in range(vx0 + 2, vx1 - 1, 4):
        m = inner & (d.XX == vx) & (d.XX >= vx0) & (d.XX < vx1)
        d.h[m] = floor + 0.9; d.dark[m] = np.maximum(d.dark[m], 0.10)
    # the horizontal louvers, nearer, tipped a little up (their top edges catch the light)
    ly0, pitch = y + 3, 4
    rows = list(range(ly0, y + h - 3, pitch))
    for ly in rows:
        lm = inner & (d.YY >= ly) & (d.YY < ly + 2) & (d.XX >= vx0) & (d.XX < vx1)
        d.cyl(vx0, ly, vx1 - vx0, 2, 2.6, "blackp", axis="h", polish=0.45, on=floor + 0.8, mask=lm)
    # the tab on the middle louver
    mid = rows[len(rows) // 2]
    tcx = (vx0 + vx1) // 2
    tab = d.M().rrect(tcx - 3, mid - 1, 7, 4, 1).get()
    d.slab(tab, 4.2, "blackp", bevel=0.9, polish=0.7, on=floor + 0.8)
    d.seam(box(tcx, mid, 1, 2), 0.35)
    # the thumbwheel: a knurled drum seen edge on
    if wheel:
        wm = inner & (d.XX >= wx0) & (d.XX < wx1) & (d.YY >= y + 4) & (d.YY < y + h - 4)
        d.cyl(wx0, y + 4, wx1 - wx0, h - 8, 3.4, "blackp", axis="v", polish=0.5, on=floor + 0.5, mask=wm)
        kn = wm & (((d.YY - y) % 2) == 0)
        d.tex[kn] += 0.11
    return inner


def vent_eyeball(b, cx, cy, r, bezel="chrome", on=Z_FACE, check=True):
    """a round vent: a chrome ring, the ball inside it with its louvers across, a centre knob to aim it by"""
    d = b.d
    if check: b.check_flat(cx - r - 4, cy - r - 4, 2 * r + 8, 2 * r + 8, "round vent")
    d.torus(cx, cy, r + 0.5, r + 3.2, 2.4, bezel, polish=1.0, on=on)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    gap = (rr > r - 0.6) & (rr <= r + 0.5)
    d.h[gap] = on - 2.5; d.mat[gap] = d.mid("blackp"); d.solid |= gap; d.dark[gap] = np.maximum(d.dark[gap], 0.35)
    ball = rr <= r - 0.6
    d.h[ball] = on - 2.0 + np.sqrt(np.clip(1 - (rr[ball] / r) ** 2, 0, 1)) * 2.4
    d.mat[ball] = d.mid("blackp"); d.solid |= ball; d.polish[ball] = 0.5; d.tex[ball] = 0
    hole = ball & (rr <= r - 2.6)
    d.h[hole] -= 1.6
    for k in range(-r + 3, r - 2, 3):
        lm = hole & (d.YY == cy + k)
        d.h[lm] += 1.3; d.tex[lm] += 0.08
    d.dome(cx, cy, 2.4, 2.4, 2.6, "blackp", polish=0.9, on=on - 0.4)
    return ball


# ====================================================================== the key
def _rot(cx, cy, ang, pts):
    a = math.radians(ang); ca, sa = math.cos(a), math.sin(a)
    return [(cx + 0.5 + x * ca - y * sa - 0.5, cy + 0.5 + x * sa + y * ca - 0.5) for x, y in pts]


KEY_HEAD = [(-3, -12), (3, -12), (5.5, -9.5), (5.5, 1), (3, 3.5), (-3, 3.5), (-5.5, 1), (-5.5, -9.5)]


def key_turn_variants(b, cx, cy, style="chrome", angles=(("off", 0), ("on", 40), ("start", 80))):
    """three key sprites: the key at OFF, ON and START (src keyPos). The head turns about the barrel; the ring hangs
    from the head's hole and its tag hangs under it, both always straight down."""
    for pos, ang in angles:
        def fn(d, ang=ang):
            head = d.M().poly(_rot(cx, cy, ang, KEY_HEAD)).get()
            d.slab(head, 6.0, "alu", bevel=1.4, polish=0.9, on=Z_FACE + 1)
            blade = d.M().poly(_rot(cx, cy, ang, [(-1.5, -3.5), (1.5, -3.5), (1.5, 2.5), (-1.5, 2.5)])).get()
            d.seam(blade, 0.25)
            (hx_, hy_), = _rot(cx, cy, ang, [(0, -8.5)])
            hx_ += 0.5; hy_ += 0.5
            hole = np.hypot(d.XX + 0.5 - hx_, d.YY + 0.5 - hy_) < 1.3
            d.h[hole] -= 3; d.dark[hole] = 0.5
            rcx, rcy = hx_, hy_ + 3.0
            rr = np.hypot(d.XX + 0.5 - rcx, d.YY + 0.5 - rcy)
            ring = (rr >= 2.4) & (rr <= 3.6) & ~(np.hypot(d.XX + 0.5 - hx_, d.YY + 0.5 - hy_) < 1.0)
            d.h[ring] = Z_FACE + 9.0; d.mat[ring] = d.mid("chrome"); d.solid |= ring; d.polish[ring] = 1.0; d.tex[ring] = 0
            tag = d.M().rrect(int(round(rcx - 3)), int(round(rcy + 3.0)), 6, 6, 1).get()
            d.slab(tag, 5.0, "paint_r" if style == "chrome" else "paint_y", bevel=1.0, polish=0.5, on=Z_FACE + 0.5)
        b.variant(f"key_{pos}_{b.id}", "keyPos", fn, pos)


def ignition(b, cx, cy, met="chrome", labels=("OFF", "ON", "START"), style=None):
    """the lock cylinder in its chrome ring, the three positions printed round it (OFF up, ON up-right, START right)"""
    d = b.d
    b.check_flat(cx - 12, cy - 12, 25, 25, "ignition")
    d.torus(cx, cy, 7, 10, 2.2, met, polish=1.0, on=Z_FACE)
    ig = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy) < 7
    d.h[ig] = Z_FACE + 0.5; d.mat[ig] = d.mid("blackp"); d.polish[ig] = 0.5; d.tex[ig] = 0
    d.seam(box(cx - 1, cy - 4, 2, 9), 0.8)
    for t, a in zip(labels, (270, 320, 0)):
        if not t: continue
        DL.ring_label(b, cx + 0.5, cy + 0.5, 11, a, t, gap=2)
    key_turn_variants(b, cx, cy, style or ("chrome" if met == "chrome" else "black"))
    b.hit("ignition", cx - 12, cy - 12, 25, 25)


# ====================================================================== lower rows
LEFT_SPAN = (14, COLUMN_X - 28)       # the lower row left of the column, and right of it, each spread with equal
RIGHT_SPAN = (COLUMN_X + 28, 486)     #   gaps; the column's 56 px kept clear (balance pass, Oct 24)


def spread(x0, x1, widths):
    """left edges for blocks of these widths laid in x0..x1 with equal gaps before, between and after"""
    g = (x1 - x0 - sum(widths)) / (len(widths) + 1)
    out, x = [], x0 + g
    for w in widths:
        out.append(int(round(x))); x += w + g
    return out


def _lights_boxy(b, cx, y0, met, chrome):
    d = b.d
    b.check_flat(cx - 10, y0 + 12, 22, 22, "lights knob")
    knob(d, cx, y0 + 22, 8, mat=met, on=Z_FACE, z=4.5, knurl=not chrome)
    ins = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - (y0 + 22)) <= 5.2
    d.paint(ins, "blackp", flatlight=True)
    d.paint(icon_mask(d, "headlamp", cx - 3, y0 + 20), "paint_w", flatlight=True)
    b.label("LIGHTS", cx, y0 + 33, align="c")
    DL.pull_variant(b, cx, y0 + 22, 8, met)
    b.hit("lights", cx - 10, y0 + 12, 21, 21)


def _rocker_lab(b, x, y, icon, label, up=True):
    """a rocker with its icon, its name under it"""
    b.check_flat(x - 2, y - 2, 20, 26, f"rocker {icon}")
    DL.rocker(b.d, x, y, 16, 22, on=Z_FACE, up=up, icon=icon, icon_mat="paint_r" if icon == "hazard" else "paint_w")
    if label: b.label(label, x + 8, y + 25, align="c")


def lower_boxy6(b, y0=118, chrome=True, trunk_label="TRUNK", trunk_sub=None, cruise=True, lock=True, key_style=None,
                right_panel=None, vent=None):
    """director, Oct 24: left of the column the lights, the lock and the trunk; right of it the wiper, cruise (or a
    right_panel width the caller fills: the ambulance's switches) and the key, the key right-most. No vent down here.
    Each side spread with equal gaps. Returns the right panel's x when one is asked for."""
    d = b.d
    met = "chrome" if chrome else "blackp"
    fr = "chrome" if chrome else None
    tw = max(30, text_w(trunk_label) + 8)
    left = [("lights", 24)] + ([("lock", 18)] if lock else []) + [("trunk", max(tw, text_w(trunk_sub) if trunk_sub else 0))]
    for (kind, bw), x in zip(left, spread(*LEFT_SPAN, [w for _, w in left])):
        if kind == "lights":
            _lights_boxy(b, x + 12, y0, met, chrome)
        elif kind == "lock":
            b.check_flat(x - 2, y0 + 12, 22, 17, "lock button")
            button(d, x, y0 + 14, 18, 13, None, mat="blackp", on=Z_FACE, z=2.0, frame=fr)
            d.paint(icon_mask(d, "lock", x + 7, y0 + 18), "paint_w", flatlight=True)
            b.label("LOCK", x + 9, y0 + 31, align="c")
            b.led(x + 13, y0 + 16, 3, 2, "anyLocked", "#44ee44")
            b.hit("lock", x, y0 + 14, 18, 13)
        else:
            bx = x + (bw - tw) // 2
            b.check_flat(bx - 2, y0 + 12, tw + 4, 17, "trunk button")
            button(d, bx, y0 + 14, tw, 13, trunk_label, mat="blackp", on=Z_FACE, frame=fr)
            if trunk_sub: b.label(trunk_sub, bx + tw // 2, y0 + 31, align="c")
            b.hit("trunk", bx, y0 + 14, tw, 13, needs="hasTrunk")
    right = [("wiper", 22)]
    if right_panel: right.append(("panel", right_panel))
    elif cruise: right.append(("cruise", 34))
    right.append(("key", 44))
    panel_x = None
    for (kind, bw), x in zip(right, spread(*RIGHT_SPAN, [w for _, w in right])):
        if kind == "wiper":
            _rocker_lab(b, x + 3, y0 + 9, "wiper", "WIPER", up=False)
        elif kind == "panel":
            panel_x = x
        elif kind == "cruise":
            b.check_flat(x - 2, y0 + 12, 38, 17, "cruise button")
            button(d, x, y0 + 14, 34, 13, "CRUISE", mat="blackp", on=Z_FACE, frame=fr)
            b.label("ON  SET", x + 17, y0 + 31, align="c")
            b.led(x + 28, y0 + 16, 3, 2, "cruiseLamp", "#ffb02e")
            b.hit("cruise", x, y0 + 14, 34, 13, needs="running")
        else:
            ignition(b, x + 12, y0 + 22, met=met, style=key_style)
    return panel_x


def lower_curvy6(b, y0=122):
    """early 90s, the same order: the lights rotary, lock and trunk left of the column; wiper and defrost rockers,
    cruise and the key right of it, the key right-most (the hazard switch moved under the ash tray)"""
    d = b.d; M = d.M
    xs = spread(*LEFT_SPAN, [40, 22, 34])
    cx = xs[0] + 16
    b.check_flat(cx - 12, y0 + 6, 25, 25, "lights knob")
    knob(d, cx, y0 + 18, 10, mat="blackp", on=Z_FACE, z=3.0, knurl=True)
    d.paint(icon_mask(d, "headlamp", cx - 3, y0 + 31), "paint_w", flatlight=True)
    b.label("OFF", cx - 16, y0 + 2, align="c")
    d.paint(icon_mask(d, "beam", cx + 12, y0 + 1), "paint_w", flatlight=True)
    b.part("ptr", src="lights", cx=cx, cy=y0 + 18, r0=2, r1=8, angles=[225, 315], color="#e8e8e8", w=1)
    b.hit("lights", cx - 10, y0 + 8, 21, 21)
    x = xs[1]
    b.check_flat(x - 2, y0 + 9, 26, 18, "lock button")
    button(d, x, y0 + 11, 22, 14, None, mat="blackp", on=Z_FACE, r=3)
    d.paint(icon_mask(d, "lock", x + 9, y0 + 15), "paint_w", flatlight=True)
    b.led(x + 16, y0 + 13, 3, 2, "anyLocked", "#44ee44"); b.hit("lock", x, y0 + 11, 22, 14)
    x = xs[2]
    b.check_flat(x - 2, y0 + 9, 38, 18, "trunk button")
    button(d, x, y0 + 11, 34, 14, "TRUNK", mat="blackp", on=Z_FACE, r=3); b.hit("trunk", x, y0 + 11, 34, 14, needs="hasTrunk")
    xs = spread(*RIGHT_SPAN, [36, 40, 36])
    for i, (ic, up) in enumerate((("wiper", True), ("defrost", False))):
        b.check_flat(xs[0] + i * 20 - 2, y0 + 6, 20, 26, f"rocker {ic}")
        DL.rocker(d, xs[0] + i * 20, y0 + 8, 16, 22, on=Z_FACE, up=up, icon=ic, icon_mat="paint_w")
    x = xs[1]
    b.check_flat(x - 2, y0 + 9, 44, 18, "cruise button")
    button(d, x, y0 + 11, 40, 14, "CRUISE", mat="blackp", on=Z_FACE, r=3)
    b.led(x + 34, y0 + 13, 3, 2, "cruiseLamp", "#7aff6a"); b.hit("cruise", x, y0 + 11, 40, 14, needs="running")
    kx = xs[2] + 12
    b.check_flat(kx - 12, y0 + 6, 25, 25, "ignition")
    d.torus(kx, y0 + 18, 7, 9.5, 1.6, "blackp", polish=0.6, on=Z_FACE)
    ig = np.hypot(d.XX + 0.5 - kx, d.YY + 0.5 - (y0 + 18)) < 7
    d.h[ig] = Z_FACE + 0.6; d.mat[ig] = d.mid("alu"); d.polish[ig] = 0.8; d.tex[ig] = 0
    d.seam(box(kx - 1, y0 + 14, 2, 9), 0.8)
    for t, a in (("LOCK", 270), ("ON", 320), ("ST", 0)):
        DL.ring_label(b, kx + 0.5, y0 + 18.5, 10.5, a, t, gap=2)
    key_turn_variants(b, kx, y0 + 18, "black")
    b.hit("ignition", kx - 10, y0 + 8, 21, 21)


def hazard_under_ash(b):
    """director, Oct 24: the hazard switch under the ash tray, where the console has room: a square red-triangle
    push button centred under the drawer (decorative; the game has no hazard lamps)"""
    ax, ay, aw, ah = b.meta["ash"]
    bx, by = ax + aw // 2 - 11, ay + ah + 10
    b.check_flat(bx - 2, by - 2, 26, 20, "hazard button")
    button(b.d, bx, by, 22, 16, None, mat="blackp", on=Z_FACE, z=2.2, r=2)
    b.d.paint(icon_mask(b.d, "hazard", bx + 7, by + 5), "paint_r", flatlight=True)


# ====================================================================== the console
def console_vents(b, y, x0=510, w=88, h=30, chrome=True, round_=False, xr=780):
    """the two centre vents, larger: rectangles with louvers, tab and wheel, or round eyeballs (x0 .. xr)"""
    bz = "chrome" if chrome else "blackp"
    x1 = xr - w
    if round_:
        r = h // 2
        vent_eyeball(b, x0 + r + 4, y + r + 1, r, bezel=bz)
        vent_eyeball(b, xr - r - 4, y + r + 1, r, bezel=bz)
    else:
        vent_louvered(b, x0, y, w, h, bezel=bz, wheel="left")
        vent_louvered(b, x1, y, w, h, bezel=bz, wheel="right")


ASH_W, ASH_H = 74, 46


def _ash_closed(d, x, y, cabin, chrome=True, lighter=True):
    """the shut ash tray: a drawer with a pull along its top, the lighter beside it. Returns the drawer's width."""
    M = d.M
    met = "chrome" if chrome else "blackp"
    dw = ASH_W - (20 if lighter else 0)
    face = box(x + 1, y + 1, dw - 2, ASH_H - 2)
    d.flat(face, Z_FACE + 0.4, cabin, polish=0.2); DL._pebble(d, face, 0.04, seed=8)
    if chrome: chrome_frame(d, x, y, dw, ASH_H, Z_FACE, t=1, r=1, z=1.6)
    else: d.seam(box(x, y, dw, ASH_H) & ~box(x + 1, y + 1, dw - 2, ASH_H - 2), 0.5)
    pull = M().rrect(x + dw // 2 - 12, y + 4, 24, 4, 1).get()
    d.slab(pull, 2.6, met, bevel=1.0, polish=1.0, on=Z_FACE + 0.4)
    d.seam(box(x + dw // 2 - 10, y + 8, 20, 1), 0.4)
    if lighter:
        lx, ly = x + dw + 10, y + ASH_H // 2
        d.torus(lx, ly, 5, 7.5, 1.8, met, polish=1.0, on=Z_FACE)
        lt = np.hypot(d.XX + 0.5 - lx, d.YY + 0.5 - ly) < 5
        d.h[lt] = Z_FACE + 1.2; d.mat[lt] = d.mid("blackp"); d.tex[lt] = 0
        d.tex[lt & (((d.XX + d.YY) % 2) == 0)] += 0.1
        d.paint(box(lx - 3, ly + 10, 7, 1), "paint_w", flatlight=True)
    return dw


def _ash_open(d2, x, y, dw, cabin, level, chrome=True, seed=3):
    """slid out toward the driver: the bin's dark lip, grey ash, butts at their real size against the tray (director's
    photos, Oct 24). level 1, 2, 3 = two, four or six butts ("2 to 6, make em bigger, a reasonable amount of ash")"""
    M = d2.M
    met = "chrome" if chrome else "blackp"
    rng = np.random.default_rng(seed + level * 7)
    bowl_h = 28
    hole = box(x, y, dw, 3)                                   # the dark slot it slid out of
    d2.h[hole] = Z_FACE - 3.0; d2.mat[hole] = d2.mid("blackp"); d2.solid |= hole; d2.tex[hole] = 0
    d2.dark[hole] = np.maximum(d2.dark[hole], 0.6)
    bowl = box(x, y + 2, dw, bowl_h)
    d2.slab(bowl, 4.0, "blackp", bevel=1.2, polish=0.6, on=Z_FACE + 0.4)       # the bin, black plastic
    inner = box(x + 2, y + 4, dw - 4, bowl_h - 4)
    d2.flat(inner, Z_FACE + 1.0, "steel", polish=0.2)
    d2.dark[inner] = np.maximum(d2.dark[inner], 0.25)
    # the ash: a few lumpy drifts, more of it the fuller the tray, grey with white paper flecks
    Y, X = d2.YY, d2.XX
    n1 = rng.random((H, W)); n2 = rng.random((H, W))
    lump = np.zeros((H, W), np.float32)
    for _ in range(3 + 2 * level):
        cx_, cy_ = x + 3 + rng.random() * (dw - 6), y + 6 + rng.random() * (bowl_h - 10)
        r_ = 4 + rng.random() * 5
        lump += np.clip(1 - np.hypot(X + 0.5 - cx_, (Y + 0.5 - cy_) * 1.4) / r_, 0, 1) * (0.8 + rng.random())
    ashm = inner & (lump > 0.22)
    d2.h[ashm] = Z_FACE + 1.4 + np.clip(lump[ashm], 0, 2.2) * 1.3 + n1[ashm] * 0.5
    d2.mat[ashm] = d2.mid("ash"); d2.polish[ashm] = 0.05; d2.tex[ashm] = 0
    d2.tex[ashm & (n2 > 0.86)] += 0.16; d2.tex[ashm & (n2 < 0.10)] -= 0.16
    fl = ashm & (n1 > 0.93); d2.mat[fl] = d2.mid("paper")
    # the butts: round bars, a cork filter and a burnt paper end, laid at their angle, half sunk in the ash
    BR, BL, FL = 2.8, 17.0, 10.5

    def butt(cx_, cy_, ang, sink=0.6):
        a_ = np.radians(ang); ux, uy = np.cos(a_), np.sin(a_)
        px_, py_ = X + 0.5 - cx_, Y + 0.5 - cy_
        along = px_ * ux + py_ * uy; perp = -px_ * uy + py_ * ux
        m = (np.abs(perp) <= BR) & (along >= -BL / 2) & (along <= BL / 2) & inner
        if not m.any(): return
        prof = np.sqrt(np.clip(1 - (perp[m] / BR) ** 2, 0, 1))
        hh = Z_FACE + 2.2 + sink + prof * 3.0
        keep = hh > d2.h[m]
        sel = np.zeros((H, W), bool); sel[m] = keep
        d2.h[sel] = hh[keep]; d2.solid |= sel; d2.polish[sel] = 0.35; d2.tex[sel] = 0
        t = along + BL / 2
        cork = sel & (t < FL); paper = sel & (t >= FL) & (t < BL - 1.5); char = sel & (t >= BL - 1.5)
        d2.mat[cork] = d2.mid("cork"); d2.mat[paper] = d2.mid("paper"); d2.mat[char] = d2.mid("ash")
        d2.dark[char] = np.maximum(d2.dark[char], 0.4)
        d2.tex[cork & (n2 > 0.8)] += 0.08                      # the filter paper's speckle
        ring = sel & (t >= FL - 0.6) & (t < FL + 0.4); d2.tex[ring] -= 0.06
    placed = []
    for i in range(2 * level):
        for _try in range(60):
            cx_ = x + 10 + rng.random() * (dw - 20); cy_ = y + 9 + rng.random() * (bowl_h - 15)
            if all(math.hypot(cx_ - px2, cy_ - py2) > 9 for px2, py2 in placed): break
        placed.append((cx_, cy_))
        butt(cx_, cy_, rng.uniform(-28, 28) + (180 if rng.random() < 0.5 else 0), sink=rng.uniform(0.0, 1.0))
    # the bin's front lip, the drawer front out and lower, its pull
    lip = box(x - 1, y + bowl_h, dw + 2, 2)
    d2.slab(lip, 5.4, "blackp", bevel=0.8, polish=0.8, on=Z_FACE + 0.4)
    fr = box(x - 1, y + bowl_h + 2, dw + 2, ASH_H - bowl_h - 1)
    d2.slab(fr, 5.0, cabin, bevel=1.0, polish=0.2, on=Z_FACE + 0.4)
    if chrome: chrome_frame(d2, x - 1, y + bowl_h + 2, dw + 2, ASH_H - bowl_h - 1, Z_FACE + 5.0, t=1, r=1, z=1.2)
    pull2 = M().rrect(x + dw // 2 - 10, y + bowl_h + 6, 20, 3, 1).get()
    d2.slab(pull2, 2.4, met, bevel=1.0, polish=1.0, on=Z_FACE + 5.4)


def ash_tray(b, x, y, chrome=True, lighter=True, levels=(1, 2, 3), seed=3):
    """the ash tray to the radio's right, shut on the plate; open as sprites (src ashOpen = 1, 2, 3: two, four or six
    butts; the game picks per car, 0 = shut; a click opens or shuts it)"""
    b.check_flat(x - 1, y - 1, ASH_W + 2, ASH_H + 2, "ash tray")
    dw = _ash_closed(b.d, x, y, b.cabin, chrome, lighter)
    for lv in levels:
        b.variant(f"ash{lv}_{b.id}", "ashOpen", lambda d2, lv=lv: _ash_open(d2, x, y, dw, b.cabin, lv, chrome, seed), lv)
    b.hit("ash", x, y, dw, ASH_H)
    b.meta["ash"] = (x, y, dw, ASH_H)


def _no_smoking(d, x, y, w=ASH_W, h=ASH_H):
    M = d.M
    pl = M().rrect(x, y, w, h, 2).get()
    base = Z_FACE
    d.slab(pl, 1.0, "paint_w", bevel=0.8, polish=0.4, on=base)
    d.flatlight |= pl
    for (rx_, ry_) in ((x + 3, y + 3), (x + w - 4, y + 3), (x + 3, y + h - 4), (x + w - 4, y + h - 4)):
        rivet(d, rx_, ry_, on=base + 1.0)
    cx, cy, r = x + w // 2, y + 17, 12
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ringm = (rr <= r) & (rr > r - 2.4)
    cig = box(cx - 8, cy - 1, 13, 3) & (rr < r - 2.4)
    tip = box(cx + 5, cy - 1, 3, 3) & (rr < r - 2.4)
    smoke = (line_mask(d, cx + 6, cy - 3, cx + 4, cy - 7, 1.0) | line_mask(d, cx + 4, cy - 7, cx + 6, cy - 9, 1.0)) & (rr < r - 2.4)
    d.paint(cig, "paint_k", flatlight=True); d.paint(tip, "paint_o", flatlight=True); d.paint(smoke, "paint_k", flatlight=True)
    slash = line_mask(d, cx - 8, cy - 8, cx + 8, cy + 8, 2.2) & (rr <= r)
    d.paint(ringm | slash, "paint_r", flatlight=True)
    d.text("NO SMOKING", cx, y + h - 11, "paint_k", align="c", flatlight=True)


def no_smoking(b, x, y, w=ASH_W, h=ASH_H):
    """the emergency vehicles: a NO SMOKING plate riveted where the ash tray would be"""
    b.check_flat(x - 1, y - 1, w + 2, h + 2, "no smoking plate")
    _no_smoking(b.d, x, y, w, h)
    b.ink_rect(x, y, w, h, "no smoking plate")


# ====================================================================== the van's sticker, the taxi's meter and hula girl
VAN_LOGOS = {   # the vans whose business has a logo in the game (media/textures/shirtdecals): they wear it
    "VanSpiffo": "Buisness_SpiffosDECAL", "VanFossoil": "Buisness_FossoilDECAL",
    "VanMccoy": "Buisness_McCoysDECAL", "VanJohnMcCoy": "Buisness_McCoysDECAL",
}


def van_right(b, x, y):
    """the van, right of the radio (director, Oct 24): a business with a logo in the game wears it as a sticker (live,
    the sticker part); any other company's van has a NO SMOKING plate; a private van an ash tray. The plate is plain
    vinyl there; the game shows one (src vanRight = "ash" shut, "nosmoke", or nothing under a sticker; ashOpen as any
    car's)."""
    sx, sy = x + 3, y - 10
    b.check_flat(sx - 1, sy - 1, 70, 70, "sticker slot")
    b.part("sticker", x=sx, y=sy, w=68, h=68, match="logo")
    b.meta["sticker"] = (sx, sy, 68, 68)
    b.variant(f"vtray_{b.id}", "vanRight", lambda d2: _ash_closed(d2, x, y, b.cabin, False, True), "ash")
    b.variant(f"vsign_{b.id}", "vanRight", lambda d2: _no_smoking(d2, x, y), "nosmoke")
    dw = ASH_W - 20
    for lv in (1, 2, 3):
        b.variant(f"ash{lv}_{b.id}", "ashOpen",
                  lambda d2, lv=lv: (_ash_closed(d2, x, y, b.cabin, False, True), _ash_open(d2, x, y, dw, b.cabin, lv, False, 5)), lv)
    b.hit("ash", x, y, dw, ASH_H, needs="vanTray")
    b.meta["ash"] = (x, y, dw, ASH_H)


def taxi_meter6(b, x, y, on=Z_FACE):
    """the fare meter, bolted on the console top: red figures for the fare and the extras, and the flag on its arm:
    up reads FOR HIRE, pulled down starts the meter (sprite src meterOn, the flag down)"""
    d = b.d; M = d.M
    w, h = 118, 36
    b.check_flat(x - 1, y - 1, w + 2, h + 2, "taxi meter")
    body = M().rrect(x, y, w, h, 3).get()
    d.slab(body, 4.0, "blackp", bevel=1.6, polish=0.45, on=on)
    zt = on + 4.0
    window(d, x + 5, y + 5, 62, 16, 0.8, bezel=None, face="ledglass", r=1, on=zt, lens=False)
    for i in range(5):
        for k, m in DL.seg_masks(x + 9 + i * 11, y + 8, 7, 11, 1).items(): d.paint(m, "ledoff", flatlight=True)
    d.text("FARE", x + 9, y + 25, "paint_w"); d.text("$", x + 62, y + 25, "paint_w", align="r")
    window(d, x + 71, y + 5, 30, 10, 0.6, bezel=None, face="ledglass", r=1, on=zt, lens=False)
    for i in range(3):
        for k, m in DL.seg_masks(x + 74 + i * 8, y + 7, 5, 7, 1).items(): d.paint(m, "ledoff", flatlight=True)
    d.text("EXTRAS", x + 86, y + 18, "paint_w", align="c")
    b.part("meter", x=x + 9, y=y + 8, cw=7, ch=11, pitch=11, color="#ff3a1a", src="fare", demo="12.80", digits=5)
    b.part("meter", x=x + 74, y=y + 7, cw=5, ch=7, pitch=8, color="#ff3a1a", src="fareExtra", demo="0.50", digits=3)
    # the flag's arm on the right end, its pivot boss; the flag itself is a sprite (up: FOR HIRE)
    px_, py_ = x + w - 12, y + h - 9
    d.dome(px_, py_, 4, 4, 2.6, "chrome", polish=1.0, on=zt)
    b.meta["meter"] = (x, y, w, h)
    b.meta["meter_pivot"] = (px_, py_)
    b.hit("meter", x + w - 24, y - 2, 24, h + 2)
    return px_, py_


def meter_flag_variants(b, px_, py_):
    """the flag, two sprites: up (FOR HIRE) while the meter stands, down while it runs"""
    d = b.d; M = d.M

    def flag(dd, up):
        if up:
            arm = line_mask(dd, px_, py_, px_, py_ - 20, 1.6)
            plate = M().rrect(px_ - 8, py_ - 31, 18, 12, 1).get()
        else:   # turned down, out to the right: its edge toward the driver, a short red bar
            arm = line_mask(dd, px_, py_, px_ + 12, py_, 1.6)
            plate = M().rrect(px_ + 10, py_ - 3, 18, 7, 1).get()
        dd.h[arm] = Z_FACE + 7.0; dd.mat[arm] = dd.mid("chrome"); dd.solid |= arm; dd.polish[arm] = 1.0; dd.tex[arm] = 0
        dd.slab(plate, 1.2, "paint_r", bevel=0.8, polish=0.5, on=Z_FACE + 6.0)
        dd.flatlight |= plate
        if up:
            dd.text("FOR", px_ + 1, py_ - 30, "paint_w", align="c", flatlight=True)
            dd.text("HIRE", px_ + 1, py_ - 25, "paint_w", align="c", flatlight=True)
    b.variant(f"flagup_{b.id}", "meterOn", lambda dd: flag(dd, True), False)
    b.variant(f"flagdn_{b.id}", "meterOn", lambda dd: flag(dd, False), True)


# The hula girl, after the director's photo (Oct 24), drawn larger ("too small"): the round grass base with its gold
# script, short legs, the wide green grass skirt with strands and fringe, the red fuzzy waistband, a maroon top under a
# yellow lei, the yellow flower crown, long black hair down her back, one arm raised holding a feathered gourd, a flower
# at her hip. 25 x 35, set by runs: (column, pixels) per row. She stands on the console's top lip and rises above the
# plate's top edge (the sprite's y is negative: the game draws her over the windscreen view, as a real one would sit).
HULA_W = 25
HULA_RUNS = [
    [(1, "mmy"), (9, "yYyYyYy")],
    [(0, "mmmyy"), (7, "yYyYyYyYyy")],
    [(0, "mmyy"), (4, "s"), (7, "kkkkkkkkkk")],
    [(1, "m"), (4, "ss"), (7, "kksssssskk")],
    [(5, "s"), (7, "kksssssss"), (16, "kk")],
    [(5, "s"), (7, "kks"), (10, "esses"), (15, "s"), (16, "kk")],
    [(6, "s"), (7, "kk"), (9, "sssssss"), (16, "kkk")],
    [(6, "s"), (7, "kk"), (9, "ssrrsss"), (16, "kkk")],
    [(6, "s"), (7, "kk"), (9, "SsssssS"), (16, "kkk")],
    [(7, "s"), (8, "kk"), (11, "sss"), (15, "kkkk")],
    [(7, "s"), (8, "k"), (9, "yYy"), (12, "s"), (13, "yYy"), (16, "kkk")],
    [(7, "ss"), (9, "yY"), (11, "sss"), (14, "Yy"), (16, "sss"), (19, "kk")],
    [(8, "s"), (9, "y"), (10, "mmmmm"), (15, "y"), (16, "ss"), (19, "kk")],
    [(8, "ss"), (10, "y"), (11, "mmm"), (14, "y"), (15, "s"), (17, "s"), (19, "kk")],
    [(9, "ss"), (11, "yYy"), (14, "ss"), (17, "s"), (19, "k")],
    [(9, "SsssssS"), (17, "s")],
    [(9, "Sssssss"), (16, "smYm")],
    [(8, "rRrRrRrRr"), (17, "mYm")],
    [(7, "RrRrRrRrRrR")],
    [(6, "gGgGgGgGgGgGg")],
    [(5, "gGgGgGgGgGgGgGg")],
    [(5, "GgGgGgGgGgGgGgG")],
    [(4, "gGgGgGgGgGgGgGgGg")],
    [(4, "GgdgGgdgGgdgGgdgG")],
    [(3, "gGgGgGgGgGgGgGgGgGg")],
    [(3, "GgdGgdGgdGgdGgdGgdG")],
    [(3, "gdgdgdgdgdgdgdgdgdg")],
    [(2, "g.g.g.g.g.g.g.g.g.g.g")],
    [(10, "s"), (14, "s")],
    [(10, "s"), (14, "s")],
    [(9, "SSs"), (14, "sSS")],
    [(5, "bBbBbBbBbBbBbBb")],
    [(4, "bbbbbbbbbbbbbbbbb")],
    [(4, "BbBbByYyYyYbBbBbB")],
    [(5, "bbbbbbbbbbbbbbb")],
]
HULA_PAL = {"k": "#16100c", "s": "#b8744a", "S": "#8c5030", "e": "#120c08", "y": "#e2b848", "Y": "#f6e4a4", "m": "#7a2432",
            "r": "#d8402a", "R": "#a82a1e", "g": "#5aa07e", "G": "#8ecab0", "d": "#3a7a5c", "b": "#3c5a30", "B": "#5e7c46"}
HULA_ROWS = dict(head=9, body=18, skirt=27)        # the last row of each part (the head lags, the skirt swings)


def hula_frames():
    """three frames: still, hips swung left, hips swung right (the game picks one by the car's turning and bumps).
    The skirt and waistband swing, the fringe furthest; the head lags a pixel the other way; legs and base stay."""
    from PIL import Image
    rows = []
    for runs in HULA_RUNS:
        r = ["."] * HULA_W
        for c0, px_ in runs:
            for i, ch in enumerate(px_):
                if ch != "." and 0 <= c0 + i < HULA_W: r[c0 + i] = ch
        rows.append(r)
    fr = []
    for sway in (0, -1, 1):
        Hh, Ww = len(rows), HULA_W + 4
        out = [["."] * Ww for _ in range(Hh)]
        for yy, r in enumerate(rows):
            if yy <= HULA_ROWS["head"]: dx = -sway
            elif yy <= HULA_ROWS["body"] - 2: dx = 0
            elif yy <= HULA_ROWS["skirt"]: dx = sway * (1 if yy < 23 else 2)
            else: dx = 0
            for xx, c in enumerate(r):
                if c != ".": out[yy][xx + 2 + dx] = c
        im = Image.new("RGBA", (Ww + 2, Hh + 2), (0, 0, 0, 0))
        px = im.load()
        filled = {(xx + 1, yy + 1) for yy in range(Hh) for xx in range(Ww) if out[yy][xx] != "."}
        for (xx, yy) in filled:
            for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if (xx + ox, yy + oy) not in filled: px[xx + ox, yy + oy] = (16, 12, 10, 255)
        for (xx, yy) in filled:
            px[xx, yy] = hx(HULA_PAL[out[yy - 1][xx - 1]]) + (255,)
        fr.append(im)
    return fr


def taxi_license(b, x, y, w=92, h=30):
    """the cab's taxi license (Oct 24: "Taxi license"), a framed card riveted to the console under the hula girl: the driver's photo, TAXI
    LICENSE, the cab's unit (live: the badge's unit role, TAXI - CAB 26) and a licence number"""
    d = b.d; M = d.M
    b.check_flat(x - 1, y - 1, w + 2, h + 2, "taxi license")
    fr_ = M().rrect(x, y, w, h, 1).get()
    d.slab(fr_, 1.6, "alu", bevel=0.8, polish=0.8, on=Z_FACE)
    card = box(x + 2, y + 2, w - 4, h - 4)
    d.flat(card, Z_FACE + 1.0, "paint_c", polish=0.1); d.flatlight |= card
    for (rx_, ry_) in ((x + 2, y + 2), (x + w - 3, y + 2), (x + 2, y + h - 3), (x + w - 3, y + h - 3)):
        rivet(d, rx_, ry_, on=Z_FACE + 1.6)
    # the photo: a head and shoulders on pale blue
    px_, py_ = x + 6, y + 5
    d.paint(box(px_, py_, 16, 20), "paint_w", flatlight=True)
    d.glow(box(px_ + 1, py_ + 1, 14, 18), "#b8c8d8")
    head = (np.hypot(d.XX + 0.5 - (px_ + 8), (d.YY + 0.5 - (py_ + 8)) * 0.9) <= 4.2)
    d.glow(head, "#b88262")
    d.glow(box(px_ + 4, py_ + 3, 8, 2) & ~head | (box(px_ + 4, py_ + 3, 8, 2) & (d.YY < py_ + 5)), "#3a2a20")
    d.glow(box(px_ + 2, py_ + 14, 12, 5), "#4a5a7a")
    d.glow(box(px_ + 6, py_ + 13, 4, 2), "#b88262")
    d.text("TAXI LICENSE", x + 24, y + 5, "paint_r", flatlight=True)
    d.text("NO 4417", x + 24, y + 21, "paint_k", flatlight=True)
    b.ink_rect(x + 24, y + 5, w - 26, 21, "taxi license")
    b.part("badge", role="unit", x=x + 24, y=y + 13, w=w - 28, h=5, style="flat", font="35", scale=1, color="#1a1a1a", align="l",
           shadow=None)
    b.meta["license"] = (x, y, w, h)


TRADES = {   # the work vans' trades: the game's van scripts by name, and the sticker each wears (see the handoff)
    "mechanic": ("VanMechanic", "VanMobileMechanics", "VanMooreMechanics", "VanPlattAuto", "StepVan_Mechanic"),
    "wood": ("VanCarpenter", "VanRosewoodworking", "VanOldMill", "PickUpVanLightsCarpenter", "PickUpVanYingsWood"),
    "green": ("VanGardener", "VanGardenGods", "VanLouisvilleLandscaping", "VanGreenes", "PickUpVanCallowayLandscaping"),
    "metal": ("VanMetalworker", "VanMeltingPointMetal", "VanSchwabSheetMetal", "VanJonesFabrication", "VanRiversideFabrication",
              "VanMetalheads", "PickUpVanHeltonMetalWorking", "PickUpVanWeldingbyCamille"),
    "electric": ("VanPluggedInElectrics",),
    "build": ("VanBuilder", "VanKerrHomes", "PickUpVanBuilder", "PickUpVanKimbleKonstruction", "PickUpVanMarchRidgeConstruction",
              "PickUpVanBrickingIt"),
    "farm": ("VanOvoFarm", "VanDeerValley", "VanPennSHam"),
    "radio": ("VanRadio", "VanRadio_3N", "VanKnoxCom"),
}


def hula(b, x, y):
    """the taxi's hula girl standing on the dash top: three hand-set frames (src hula = 0 still, 1 left, 2 right)"""
    if not hasattr(b, "extra"): b.extra = {}
    for i, im in enumerate(hula_frames()):
        name = f"hula{i}_{b.id}"
        b.extra[name] = im
        b.part("sprite", src="hula", when=i, sprite=name, x=x, y=y, w=im.width, h=im.height)
