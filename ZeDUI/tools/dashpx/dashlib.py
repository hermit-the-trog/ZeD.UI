"""ZeD dashboards, pixel art: shells, clusters, lower rows, consoles, and the live parts each one hands the game.

Depth (h, toward the driver), the same on every dash so nothing crosses a layer it could not:
  dash top 0 (far, sloping up to the brow) . brow lip 11 (nearest) . lower dash and console faces 5
  cluster face -6 (sunk in the binnacle) . dial faces -8.5 (sunk in their bezels)
The brow overhangs the cluster, so its height-field shadow lies across the top of the dials; the binnacle's
side walls and its sill show (the driver sits above and between them), its ceiling never does.

Every builder records 'parts' (what the game draws live) and 'hits' (what you can click), in plate pixels,
and checks that what it places sits on one flat surface (labels never cross a bezel, knobs never cross a seam).
"""
import math
import numpy as np
from scipy import ndimage as ndi
from engine import Dash, Mask, RAMPS, hx, text_w, edt, add_ramp, F35, F57, FONTS
from widgets import (gauge, window, glare, chrome_frame, knob, button, rocker, toggle, vent_rect, vent_round,
                     nameplate, dymo, rivet, icon_mask, icon_size, line_mask, ICONS)

W, H = 800, 172
Z_TOP, Z_BROW, Z_FACE, Z_CL, Z_DIAL = 0.0, 11.0, 5.0, -6.0, -8.5
# the room the game keeps at the right end of the dash's top edge for the gamepad hint (right-aligned at HINT_X1,
# 3 x 5 letters, 124 px for the longest line, "A SHUT OFF  X REMOVE KEY  B DRIVE"); the art leaves it plain
HINT_X1, HINT_W = 486, 126
HINT_X0 = HINT_X1 - HINT_W
PRINTED = {"paint_w", "paint_c", "paint_r", "paint_o", "paint_y", "paint_k", "lampoff", "segoff", "vfdoff", "ledoff", "lens"}

for nm, base in {"v_saddle": "#7a5636", "v_medic": "#8e908c", "v_taxi": "#262628", "v_race": "#202022", "v_forest": "#3c4a36",
                 "v_sand": "#8c7a5a"}.items():
    add_ramp(nm, base)
RAMPS["vfd"] = [hx(c) for c in ("#020607", "#04090b", "#060e10", "#0a1416", "#0e1b1e", "#132327", "#1a2d31", "#22393e")]
RAMPS["vfdoff"] = [hx(c) for c in ("#030c0b", "#04100f", "#061413", "#081917", "#0a1e1c", "#0d2421", "#102b27", "#14322e")]
RAMPS["ledglass"] = [hx(c) for c in ("#070202", "#0c0303", "#120505", "#190707", "#210909", "#2b0c0c", "#370f0f", "#451414")]
RAMPS["ledoff"] = [hx(c) for c in ("#1a0605", "#220807", "#2b0a09", "#350d0b", "#40100d", "#4c1310", "#581713", "#661b16")]
RAMPS["segoff"] = [hx(c) for c in ("#5c6450", "#66705a", "#717b64", "#7c876e", "#879279", "#929d84", "#9da88f", "#a8b39a")]
RAMPS["steel"] = [hx(c) for c in ("#1e2022", "#2b2e31", "#3a3d41", "#4a4e53", "#5c6066", "#70747a", "#878b91", "#a2a6ac")]


def runs_of(mask):
    """a mask as horizontal runs [x, y, w] (the game fills these)"""
    out = []
    ys, xs = np.nonzero(mask)
    if not len(ys): return out
    for y in np.unique(ys).tolist():
        row = np.nonzero(mask[y])[0]
        start = prev = None
        for x in row.tolist():
            if start is None: start = prev = x
            elif x == prev + 1: prev = x
            else: out.append([start, y, prev - start + 1]); start = prev = x
        if start is not None: out.append([start, y, prev - start + 1])
    return out


def halo_of(mask, within=None):
    grow = ndi.binary_dilation(mask, structure=np.ones((3, 3), bool))
    m = grow & ~mask
    if within is not None: m &= within
    return m


def box(x, y, w, h):
    m = np.zeros((H, W), bool); m[max(0, y):max(0, y + h), max(0, x):max(0, x + w)] = True; return m


class Build:
    def __init__(s, design_id, cabin, seed=7, title=""):
        s.id = design_id; s.cabin = cabin; s.title = title
        s.d = Dash(W, H, seed=seed)
        s.parts = []; s.hits = []; s.variants = []; s.warnings = []; s.meta = {}
        s.inks = []   # printed legends and marks (x, y, w, h, what): nothing that moves may travel over them

    # ---- records
    def part(s, t, **kw):
        kw = {"t": t, **kw}; s.parts.append(kw); return kw

    def hit(s, id_, x, y, w, h, needs=None):
        s.hits.append({"id": id_, "x": int(x), "y": int(y), "w": int(w), "h": int(h), "needs": needs})

    def lamp(s, mask, src, color, within=None):
        p = s.part("lamp", src=src, color=color, runs=runs_of(mask))
        if within is not None:
            hm = halo_of(mask, within)
            if hm.any(): p["halo"] = runs_of(hm)
        return p

    def led(s, x, y, w, h, src, color):
        m = box(x, y, w, h); s.d.paint(m, "lens", flatlight=True)
        s.part("led", x=int(x), y=int(y), w=int(w), h=int(h), src=src, color=color)

    def variant(s, name, src, fn, when=True):
        s.variants.append((name, src, fn, when))

    def warn(s, msg): s.warnings.append(msg)

    def ink_rect(s, x, y, w, h, what):
        """a printed legend or mark that has to stay readable: a lever tab or slider knob may not ride over it"""
        s.inks.append((int(x), int(y), int(w), int(h), what))

    # ---- the flat-surface check
    def check_flat(s, x, y, w, h, what, tol=0.8):
        d = s.d
        x0, y0, x1, y1 = max(0, int(math.floor(x))), max(0, int(math.floor(y))), min(W, int(math.ceil(x + w))), min(H, int(math.ceil(y + h)))
        if x1 <= x0 or y1 <= y0: s.warn(f"{what}: off the plate"); return False
        sol = d.solid[y0:y1, x0:x1]
        if not sol.all(): s.warn(f"{what} at {x0},{y0} {x1 - x0}x{y1 - y0}: hangs off the dash"); return False
        hh = d.h[y0:y1, x0:x1]
        mats = set(np.unique(d.mat[y0:y1, x0:x1]).tolist())
        names = {d.names[m] for m in mats} - PRINTED
        if hh.max() - hh.min() > tol or len(names) > 1:
            s.warn(f"{what} at {x0},{y0} {x1 - x0}x{y1 - y0}: crosses surfaces (h {hh.min():.1f}..{hh.max():.1f}, {sorted(names)})")
            return False
        return True

    def ink_for(s, x, y, w, h, mat):
        """printed legends: white or cream on dark surfaces, a dark ink on light ones"""
        d = s.d
        x0, y0 = max(0, int(x)), max(0, int(y))
        reg = d.mat[y0:y0 + max(1, int(h)), x0:x0 + max(1, int(w))]
        names = [d.names[m] for m in np.unique(reg).tolist() if m >= 0 and d.names[m] not in PRINTED]
        if not names: return mat
        ramp = RAMPS[names[0]]
        r, g, b_ = ramp[4]
        lum = (0.299 * r + 0.587 * g + 0.114 * b_) / 255.0
        if lum > 0.42 and mat in ("paint_w", "paint_c"): return "paint_k"
        return mat

    def label(s, t, x, y, mat="paint_w", align="l", font="35", scale=1, flatlight=False, check=True):
        w = text_w(t, font, 1, scale); hgt = len(FONTS[font]["A"]) * scale
        x0 = x - w // 2 if align == "c" else (x - w if align == "r" else x)
        if check: s.check_flat(x0, y, w, hgt, f"label '{t}'")
        s.ink_rect(x0, y, w, hgt, f"label '{t}'")
        mat = s.ink_for(x0, y, w, hgt, mat)
        return s.d.text(t, x, y, mat, font=font, align=align, flatlight=flatlight, scale=scale)


def ring_label(b, cx, cy, r, a, t, mat="paint_w", gap=2):
    """a legend just outside a circle of radius r at angle a, its near edge toward the circle"""
    ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
    px, py = cx + ca * (r + gap), cy + sa * (r + gap)
    w = text_w(t)
    if ca < -0.35: x0 = px - w
    elif ca > 0.35: x0 = px
    else: x0 = px - w / 2
    if sa < -0.35: y0 = py - 5
    elif sa > 0.35: y0 = py
    else: y0 = py - 2.5
    return b.label(t, int(round(x0)), int(round(y0)), mat, align="l")


# ====================================================================== shells
def _pebble(d, m, amt=0.045, seed=3):
    d.grain_pebble(m, amt, seed=seed)


def _tunnel(d, ox, oy, ow, oh, wall, sill, wall_mat, z_out=Z_FACE, z_in=Z_CL):
    """the binnacle opening: side walls and sill sloping down from the dash face to the cluster face"""
    tun = box(ox, oy, ow, oh)
    dl = np.clip((d.XX - ox + 0.5) / wall, 0, 1); dr = np.clip((ox + ow - 0.5 - d.XX) / wall, 0, 1)
    db = np.clip((oy + oh - 0.5 - d.YY) / sill, 0, 1)
    k = np.minimum(np.minimum(dl, dr), db)
    d.h[tun] = (z_out + (z_in - z_out) * k)[tun]
    d.mat[tun] = d.mid(wall_mat); d.solid |= tun; d.tex[tun] = 0; d.polish[tun] = 0.15
    return box(ox + wall, oy, ow - 2 * wall, oh - sill)


def shell_boxy(b, open_rect=(14, 16, 472, 98), face_mat="face", face_wood=False, trim="chrome", grille=True, console_top=16,
               wall=6, sill=8, pod=None, console_mat=None, top_y=2, wood_seed=3):
    """late 70s / 80s: square shoulders, a flat brow with a lip, the cluster sunk in a square tunnel.
    pod=(x0, x1): the brow is a proud pod only that wide; the dash top either side of it sits lower."""
    d = b.d; M = d.M
    cab = b.cabin
    if pod:
        px0, px1 = pod
        hood = M().poly([(6, 30), (14, 24), (px0 - 6, 24), (px0, 18), (px0 + 6, top_y), (px1 - 6, top_y), (px1, 18), (px1 + 6, 24),
                         (486, 24), (494, 30), (494, 168), (6, 168)]).get()
    else:
        hood = M().poly([(14, top_y), (486, top_y), (494, top_y + 8), (494, 168), (6, 168), (6, top_y + 8)]).get()
    cons = M().poly([(494, console_top), (786, console_top), (794, console_top + 8), (794, 168), (494, 168)]).get()
    d.flat(hood | cons, Z_FACE, cab, polish=0.15); _pebble(d, hood | cons)
    ox, oy, ow, oh = open_rect
    if pod:
        podm = hood & (d.XX >= px0) & (d.XX < px1)
        top = podm & (d.YY < oy - 7)
        d.ramp_h(top, Z_TOP, Z_BROW, axis="y", a0=top_y, a1=oy - 7)
        shelf = hood & ~podm & (d.YY < 31)
        d.ramp_h(shelf, Z_TOP + 1, Z_FACE, axis="y", a0=24, a1=31)
        brow = podm & (d.YY >= oy - 7) & (d.YY < oy)
        d.h[brow] = Z_BROW
        for sx, sgn in ((px0, 1), (px1 - 1, -1)):
            side = hood & (np.abs(d.XX - sx) < 6) & (d.YY >= 20) & (d.YY < oy + oh + 2)
            t_ = np.clip((d.XX - sx) * sgn / 6.0, 0, 1)
            d.h[side] = np.maximum(d.h[side], (Z_FACE + (Z_BROW - Z_FACE) * np.sqrt(t_))[side])
    else:
        top = hood & (d.YY < top_y + 7)
        d.ramp_h(top, Z_TOP, Z_BROW, axis="y", a0=top_y, a1=top_y + 7)
        brow = hood & (d.YY >= top_y + 7) & (d.YY < oy)
        d.h[brow] = Z_BROW
    if grille:
        # the defroster grille, centred on the cluster; it stops short of HINT_X0 so the top edge's right end stays
        # plain for the words the game prints there (the gamepad hint), whatever the opening's width
        cx = ox + ow // 2
        half = min(ow // 2 - 100, HINT_X0 - 4 - cx)
        last = None
        for gx in range(cx - half, cx + half - 1, 4):
            if pod and not (px0 + 14 < gx < px1 - 16): continue
            d.seam(box(gx, top_y + 2, 2, 3) & hood, 0.6)
            last = gx + 2
        if last is not None and last > HINT_X0 - 4: b.warn(f"grille runs to {last}, into the hint's room ({HINT_X0}..{HINT_X1})")
    face = _tunnel(d, ox, oy, ow, oh, wall, sill, cab)
    if face_wood:
        d.flat(face, Z_CL, "walnut", polish=0.5); d.grain_wood(face, seed=wood_seed)
    else:
        d.flat(face, Z_CL, face_mat, polish=0.1 if face_mat == "face" else 0.45)
        if face_mat == "alu": d.grain_brushed(face, 0.06, seed=wood_seed)
        if face_mat == "steel" or face_mat.startswith("v_"): _pebble(d, face, 0.035, seed=wood_seed)
    if trim == "chrome":
        lip = box(ox - 2, oy - 2, ow + 4, 3)
        d.cyl(ox - 2, oy - 2, ow + 4, 3, 1.4, "chrome", axis="h", polish=1.0, on=Z_BROW - 0.4, mask=lip)
    elif trim == "silver":
        lip = box(ox - 2, oy - 1, ow + 4, 1); d.paint(lip, "alu"); d.h[lip] = Z_BROW
    elif trim == "rubber":
        lip = box(ox - 2, oy - 2, ow + 4, 3)
        d.cyl(ox - 2, oy - 2, ow + 4, 3, 1.0, "rubber", axis="h", polish=0.2, on=Z_BROW - 0.4, mask=lip)
    d.seam(box(494, console_top + 1, 1, 168 - console_top), 0.5)
    ct = cons & (d.YY < console_top + 7)
    d.ramp_h(ct, Z_TOP + 1.5, Z_FACE, axis="y", a0=console_top, a1=console_top + 7)
    if console_mat:
        cm = cons & (d.YY >= console_top + 7)
        d.flat(cm, Z_FACE, console_mat, polish=0.2)
        if console_mat == "walnut": d.grain_wood(cm, seed=wood_seed + 4)
    fx, fy, fw, fh = ox + wall, oy, ow - 2 * wall, oh - sill
    b.meta.update(face=(fx, fy + 1, fw, fh - 1), lower_y=oy + oh, console=(494, console_top, 300, 168 - console_top))
    return b.meta


def shell_curvy(b, pill=(28, 26, 444, 88, 34), top_y=2, end_y=30, console_top=24, x1=500, cheek=12):
    """early 90s: one molded piece, an arched brow over a pill-shaped binnacle"""
    d = b.d; M = d.M
    x0 = 6
    cx = (x0 + x1) / 2; rx = (x1 - x0) / 2; ry = end_y - top_y

    def arch_y(x):
        u = np.clip((x - cx) / rx, -1, 1)
        return end_y - ry * np.sqrt(1 - u ** 2)
    arch = [(float(x), float(arch_y(x))) for x in np.linspace(x0, x1, 120)]
    outline = [(6, 168)] + arch + [(x1, end_y), (x1 + 16, console_top), (782, console_top), (794, console_top + 12), (794, 168)]
    body = M().poly(outline).get()
    d.flat(body, Z_FACE, b.cabin, polish=0.12); _pebble(d, body, 0.04)
    yt = arch_y(d.XX.astype(np.float32))
    dtop = d.YY - yt
    px, py, pw, ph, pr = pill
    hood = body & (d.XX < x1)
    pad = hood & (dtop < 11)
    d.h[pad] = (Z_TOP + (Z_BROW - Z_TOP) * np.clip(dtop / 11.0, 0, 1) ** 0.6)[pad]
    browline = py + pr
    brow = hood & ~pad & (d.YY < browline)
    d.h[brow] = Z_BROW
    chk = hood & ~pad & (d.YY >= browline)
    fall = np.clip(1 - (d.YY - browline) / float(cheek), 0, 1)
    d.h[chk] = (Z_FACE + (Z_BROW - Z_FACE) * fall)[chk]
    op = M().rrect(px, py, pw, ph, pr).get()
    dist = edt(op)
    yfrac = np.clip((d.YY - (py + ph * 0.30)) / (ph * 0.55), 0, 1)
    wall_w = 6.0 * yfrac
    wall = op & (dist <= wall_w)
    zout = d.h.copy()
    hh = Z_CL + (np.minimum(zout, Z_BROW) - Z_CL) * np.clip(1 - dist / np.maximum(wall_w, 0.01), 0, 1)
    d.h[wall] = hh[wall]; d.mat[wall] = d.mid(b.cabin); d.tex[wall] = 0
    face = op & ~wall
    d.flat(face, Z_CL, "face", polish=0.1)
    roll = (~op) & (edt(~op) <= 3) & hood & (d.YY < py + ph * 0.42)
    d.h[roll] = Z_BROW + 0.8
    cpad = body & (d.XX >= x1) & (d.YY < console_top + 8)
    d.ramp_h(cpad, Z_TOP + 2, Z_FACE, axis="y", a0=console_top, a1=console_top + 8)
    b.meta.update(face=(px, py, pw, ph), face_mask=face, lower_y=py + ph, console=(x1, console_top, 794 - x1, 168 - console_top))
    return b.meta


def shell_panel(b):
    """race: a riveted aluminium panel under a padded cage bar"""
    d = b.d; M = d.M
    panel = M().rrect(6, 12, 788, 156, 6).get()
    d.flat(panel, Z_FACE, "alu", polish=0.55); d.grain_brushed(panel, 0.11, seed=4)
    e = panel & (edt(panel) <= 2); d.h[e] = Z_FACE - 1
    dist = edt(panel); d.dark[panel] = np.maximum(d.dark[panel], 0.10 * np.clip(1 - dist[panel] / 10.0, 0, 1))
    for x in range(16, 790, 26):
        rivet(d, x, 18, on=Z_FACE); rivet(d, x, 162, on=Z_FACE)
    for y in (44, 80, 116, 140):
        rivet(d, 12, y, on=Z_FACE); rivet(d, 788, y, on=Z_FACE)
    bar = box(0, 0, 800, 13)
    d.cyl(0, 0, 800, 13, 6.0, "rubber", axis="h", polish=0.15, on=Z_BROW - 3, mask=bar)
    d.grain_pebble(bar, 0.05, seed=12)
    for x in range(60, 800, 120):
        tie = box(x, 0, 3, 13)
        d.cyl(x, 0, 3, 13, 6.5, "blackp", axis="h", polish=0.4, on=Z_BROW - 3, mask=tie)
    b.meta.update(face=(6, 14, 788, 154), lower_y=128, console=(494, 28, 300, 140))
    return b.meta


# ====================================================================== dials and their live parts
def dial(b, cx, cy, r, a0, a1, majors, labels, src, vmax, minor=1, bezel="chrome", bezel_w=2, redzone=None, label=None,
         label2=None, label_y=None, needle="#f07a28", needle_w=2, on=Z_CL, face="face", hub=2.5, low_src=None, lab_mat="paint_c",
         num_r=None, peg=False, glass=True):
    pad = bezel_w + 1.5 if bezel else 1
    b.check_flat(cx - r - pad, cy - r - pad, 2 * (r + pad), 2 * (r + pad), f"dial {src}")
    depth = (on - Z_DIAL) if on > Z_DIAL else 2.5
    an = gauge(b.d, cx, cy, r, a0, a1, majors, minor=minor, labels=labels, bezel=bezel, bezel_w=bezel_w, depth=depth,
               on=on, redzone=redzone, label=label, label2=label2, label_y=label_y, face=face, hub=hub, lab_mat=lab_mat, num_r=num_r)
    if glass:
        fm = np.hypot(b.d.XX + 0.5 - cx, b.d.YY + 0.5 - cy) <= r
        glare(b.d, fm, slope=-0.55, width=max(4, r // 6), offset=0.16, amount=0.06)
    b.part("needle", src=src, max=vmax, cx=cx, cy=cy, r0=round(an["r0"], 1), r1=round(an["r1"], 1), a0=a0, a1=a1,
           color=needle, w=needle_w, low_src=low_src, hub=hub + 0.5, peg=peg)
    return an


def small_dial(b, cx, cy, r, src, left, right, icon=None, label=None, needle="#f07a28", bezel="chrome", red_left=False,
               red_right=False, on=Z_CL, a0=210, a1=330, face="face", low_src=None, ticks=5):
    """a half dial (pivot in the middle, sweep over the top): fuel E-F, temp C-H, oil, volts"""
    d = b.d
    pad = 3.2 if bezel else 1
    b.check_flat(cx - r - pad, cy - r - pad, 2 * (r + pad), 2 * (r + pad), f"small dial {src}")
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    fm = rr <= r
    d.h[fm] = on - 2.0; d.mat[fm] = d.mid(face); d.solid |= fm; d.tex[fm] = 0; d.polish[fm] = 0.15
    if bezel: d.torus(cx, cy, r, r + 2.2, 1.8, bezel, polish=1.0, on=on)
    for i in range(ticks):
        a = a0 + (a1 - a0) * i / (ticks - 1)
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        L = 3 if i % 2 == 0 else 2
        m = line_mask(d, cx + ca * (r - 1.5), cy + sa * (r - 1.5), cx + ca * (r - 1.5 - L), cy + sa * (r - 1.5 - L), 1.0) & fm
        red = (i == 0 and red_left) or (i == ticks - 1 and red_right)
        d.paint(m, "paint_r" if red else "paint_w")
    ca0, sa0 = math.cos(math.radians(a0)), math.sin(math.radians(a0))
    ca1, sa1 = math.cos(math.radians(a1)), math.sin(math.radians(a1))
    lr = r - 7
    d.text(left, int(round(cx + ca0 * lr)) + 1, int(round(cy + sa0 * lr)) - 1, "paint_r" if red_left else "paint_w", align="c")
    d.text(right, int(round(cx + ca1 * lr)) - 1, int(round(cy + sa1 * lr)) - 1, "paint_r" if red_right else "paint_w", align="c")
    if icon:
        iw, ih = icon_size(icon)
        d.paint(icon_mask(d, icon, int(cx - iw / 2), int(cy + 4)), "paint_c", flatlight=True)
    if label:
        d.text(label, int(cx), int(cy + 4 + (7 if icon else 0)), "paint_c", align="c")
    glare(d, fm, slope=-0.55, width=4, offset=0.16, amount=0.05)
    d.dome(cx, cy, 2.2, 2.2, 1.6, "blackp", polish=0.9, on=on - 2.0)
    b.part("needle", src=src, max=1, cx=cx, cy=cy, r0=-2, r1=r - 4, a0=a0, a1=a1, color=needle, w=1, low_src=low_src, hub=2.5)


def sq_dial(b, cx, top, src, left, right, icon, w=72, h=42, needle="#f07a28", red_left=False, red_right=False, on=Z_CL, low_src=None,
            bezel="chrome"):
    """a square window, pivot at its foot, a short arc over the top (the wagon's fuel and temp)"""
    d = b.d
    gx, gy = cx - w // 2, top
    b.check_flat(gx - 1, gy - 1, w + 2, h + 2, f"square dial {src}")
    face = window(d, gx, gy, w, h, 2.5, bezel=bezel, r=2, bezel_t=2, on=on)
    pcx, pcy = cx, gy + h - 5
    rr = min(29, h - 13)
    for i in range(5):
        a = 215 + 110 * i / 4
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        rl = rr if i % 2 == 0 else rr - 2
        m = line_mask(d, pcx + ca * (rr - 5), pcy + sa * (rr - 5), pcx + ca * rl, pcy + sa * rl, 1.0)
        d.paint(m & face, "paint_r" if (i == 0 and red_left) or (i == 4 and red_right) else "paint_w")
    d.text(left, pcx - rr + 2, pcy - rr + 9, "paint_r" if red_left else "paint_w", align="c")
    d.text(right, pcx + rr - 2, pcy - rr + 9, "paint_r" if red_right else "paint_w", align="c")
    iw, ih = icon_size(icon)
    d.paint(icon_mask(d, icon, gx + 6, gy + h - ih - 5), "paint_c", flatlight=True)
    d.dome(pcx, pcy, 3.0, 3.0, 2.0, "blackp", polish=0.9, on=on - 2.5)
    b.part("needle", src=src, max=1, cx=pcx, cy=pcy, r0=-2, r1=rr - 6, a0=215, a1=325, color=needle, w=1, low_src=low_src, hub=3)


def ribbon_speedo(b, x, y, w, h, vmax=85, mode="fill", kmh=True, color="#f07a28", on=Z_CL, mark55=True):
    """a horizontal speedometer: the 70s ribbon (fill) or a travelling pointer"""
    d = b.d
    b.check_flat(x - 1, y - 1, w + 2, h + 2, "ribbon speedometer")
    window(d, x, y, w, h, 2.5, bezel="chrome", r=2, bezel_t=2, on=on)
    x0, x1 = x + 14, x + w - 24
    mph = lambda v: x0 + (x1 - x0) * v / float(vmax)
    for v in range(0, vmax + 1, 5):
        xx = int(round(mph(v))); big = v % 10 == 0
        if mark55 and v == 55:
            d.paint(box(xx, y + 9, 1, 10), "paint_o"); d.paint(box(xx - 1, y + 9, 3, 1), "paint_o")
        else:
            d.paint(box(xx, y + 13, 1, 6 if big else 3), "paint_w")
        if big: d.text(str(v), xx + (1 if v < 10 else 0), y + 5, "paint_w", align="c")
    d.paint(box(x0, y + 19, x1 - x0 + 1, 1), "paint_w")
    if kmh:
        for v in range(0, int(vmax * 1.609) + 1, 20):
            xx = int(round(mph(v / 1.609)))
            if xx <= x1:
                d.paint(box(xx, y + 20, 1, 2), "paint_c")
                d.text(str(v), xx, y + 24, "paint_c", align="c")
    d.text("MPH", x1 + 12, y + 9, "paint_w", align="c")
    if kmh: d.text("KM/H", x1 + 12, y + 24, "paint_c", align="c")
    b.part("ribbon", src="speed_mph", max=vmax, x0=x0, x1=x1, y=y + 14 if mode == "fill" else y + 8, h=4 if mode == "fill" else 19,
           color=color, mode=mode)
    return {"x0": x0, "x1": x1}


def lamp_text_row(b, x, y, items, on=Z_CL, gap=3, h_=11):
    """warning lamps with their words printed on the lens; lit by the game"""
    d = b.d
    for name, src, col in items:
        icon = name.startswith("@")
        if icon:
            iw, ih = icon_size(name[1:]); w = iw + 8
        else:
            w = max(14, text_w(name) + 8)
        b.check_flat(x, y, w, h_, f"lamp {name}")
        win = window(d, x, y, w, h_, 1.2, bezel=None, face="lens", r=1, on=on, lens=False)
        if icon:
            m = icon_mask(d, name[1:], x + 4, y + (h_ - ih) // 2)
        else:
            m = d.text(name, x + w // 2, y + (h_ - 5) // 2, "lampoff", align="c", flatlight=True)
        d.paint(m, "lampoff", flatlight=True)
        b.lamp(m, src, col, within=win)
        x += w + gap
    return x


def lamp_text_width(items, gap=3):
    tot = 0
    for name, _, _ in items:
        tot += (icon_size(name[1:])[0] + 8 if name.startswith("@") else max(14, text_w(name) + 8)) + gap
    return tot - gap


def lamp_icon_strip(b, x, y, items, on=Z_CL, gap=5, check=True):
    d = b.d
    for name, src, col in items:
        iw, ih = icon_size(name)
        if check: b.check_flat(x - 1, y - ih // 2 - 1, iw + 2, ih + 2, f"lamp {name}")
        m = icon_mask(d, name, x, y - ih // 2)
        d.paint(m, "lampoff", flatlight=True)
        b.lamp(m, src, col, within=box(x - 1, y - ih // 2 - 1, iw + 2, ih + 2))
        x += iw + gap
    return x


def prndl(b, x, y, pitch=8, color="#ffb02e", letters="PRND21", style="lit", window_=True, on=Z_CL):
    """the gear strip: letters printed dark, the selected one lit (or marked) by the game"""
    d = b.d
    w = pitch * len(letters) + 4
    if window_:
        b.check_flat(x - pitch // 2 - 3, y - 3, w + 2, 11, "gear strip")
        window(d, x - pitch // 2 - 2, y - 2, w, 9, 1.0, bezel=None, face="lens", r=1, on=on, lens=False)
    out = {}; boxes = {}
    for i, ch in enumerate(letters):
        m = d.text(ch, x + i * pitch, y, "lampoff" if style == "lit" else "paint_w", align="c", flatlight=True)
        out[ch] = runs_of(m)
        boxes[ch] = [x + i * pitch - 3, y - 2, 7, 9]
    b.part("gear", letters=out, color=color, box=boxes if style == "marker" else None)


def odometer(b, x, y, digits="83174", cw=6, ch=8):
    """odometer drums: dark wheels, the tenths wheel white"""
    d = b.d
    b.check_flat(x - 1, y - 1, len(digits) * cw + 1, ch + 2, "odometer")
    for i, c in enumerate(digits):
        last = i == len(digits) - 1
        d.paint(box(x + i * cw, y, cw - 1, ch), "paint_w" if last else "blackp")
        d.text(c, x + i * cw + (cw - 4) // 2, y + (ch - 5) // 2, "face" if last else "paint_w")


def odo_under(b, cx, cy, r):
    """the odometer under a dial's hub, below its bottom figures"""
    odometer(b, cx - 15, cy + int(r * 0.6), "83174")


# ---- digital
def seg_masks(x, y, w, h, t=1):
    r = {
        "a": (x + t, y, w - 2 * t, t), "d": (x + t, y + h - t, w - 2 * t, t), "g": (x + t, y + (h - t) // 2, w - 2 * t, t),
        "f": (x, y + t, t, (h - t) // 2 - t), "b": (x + w - t, y + t, t, (h - t) // 2 - t),
        "e": (x, y + (h - t) // 2 + t, t, h - (h - t) // 2 - 2 * t), "c": (x + w - t, y + (h - t) // 2 + t, t, h - (h - t) // 2 - 2 * t),
    }
    return {k: box(*v) for k, v in r.items()}


def seg_readout(b, x, y, n, cw, ch, pitch, t, src, color, fmt="int", ghost="vfdoff", always=False):
    """n seven-segment digits; the plate prints the unlit segments (ghosts), the game lights them"""
    d = b.d
    for i in range(n):
        for k, m in seg_masks(x + i * pitch, y, cw, ch, t).items():
            d.paint(m, ghost, flatlight=True)
    b.part("digits", src=src, fmt=fmt, x=x, y=y, n=n, cw=cw, ch=ch, pitch=pitch, st=t, color=color, align="r", always=always)


def bar_stack(b, x, y, w, h, n, gap, src, color, ghost="vfdoff", vertical=True, warn_from=None, red_from=None, low_color=None):
    """a bargraph of n bars, lit from the bottom (vertical) or the left"""
    d = b.d
    bars = []
    for i in range(n):
        if vertical:
            bh = (h - gap * (n - 1)) // n
            m = box(x, y + h - (i + 1) * bh - i * gap, w, bh)
        else:
            bw = (w - gap * (n - 1)) // n
            m = box(x + i * (bw + gap), y, bw, h)
        d.paint(m, ghost, flatlight=True)
        bars.append(runs_of(m))
    b.part("bars", src=src, bars=bars, color=color, warn_from=warn_from, red_from=red_from, low_color=low_color)


def arc_bars(b, cx, cy, r0, r1, a0, a1, n, src, vmax, color, ghost="vfdoff", warn_from=None, red_from=None, width_frac=0.62,
             grow=0.0):
    """a sweep of n segments around an arc (the 80s electronic tach); grow lengthens them toward the top end"""
    d = b.d
    bars = []
    step = (a1 - a0) / float(n)
    wd = step * width_frac
    ang = np.degrees(np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)) % 360
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    for i in range(n):
        ac = a0 + step * (i + 0.5)
        lo, hi = (ac - wd / 2) % 360, (ac + wd / 2) % 360
        am = (ang >= lo) & (ang < hi) if lo < hi else ((ang >= lo) | (ang < hi))
        rin = r0 - grow * i / max(1, n - 1)
        m = am & (rr >= rin) & (rr <= r1)
        d.paint(m, ghost, flatlight=True)
        bars.append(runs_of(m))
    b.part("bars", src=src, max=vmax, bars=bars, color=color, warn_from=warn_from, red_from=red_from)


# ====================================================================== head unit slot (the fitted radio's face goes in it)
HU_W, HU_H = 178, 46


def headunit_slot(b, x, y, frame="chrome", z=Z_FACE):
    d = b.d; M = d.M
    b.check_flat(x - 6, y - 6, HU_W + 12, HU_H + 12, "radio slot")
    op = box(x - 3, y - 3, HU_W + 6, HU_H + 6)
    d.flat(op, z - 3.0, "rubber", polish=0.1)
    if frame == "chrome":
        chrome_frame(d, x - 4, y - 4, HU_W + 8, HU_H + 8, z, t=1, r=0, z=1.4)
    elif frame == "bezel":
        ring = M().rrect(x - 6, y - 6, HU_W + 12, HU_H + 12, 3).get() & ~op
        d.slab(ring, 1.4, "blackp", bevel=1.5, polish=0.3, on=z)
    b.part("headunit", x=x, y=y, w=HU_W, h=HU_H)
    b.meta["headunit"] = (x, y, HU_W, HU_H)


# ====================================================================== the key, the lights knob (state sprites)
def key_variant(b, cx, cy, style="chrome"):
    """the key in the ignition: its head toward the driver, a ring and a tag hanging off it"""
    def fn(d):
        M = d.M
        head = M().rrect(cx - 4, cy - 8, 9, 12, 3).get()
        d.slab(head, 7.0, "blackp", bevel=1.6, polish=0.6, on=Z_FACE + 1)
        hole = np.hypot(d.XX + 0.5 - (cx + 0.5), d.YY + 0.5 - (cy - 5)) < 1.3
        d.h[hole] -= 3; d.dark[hole] = 0.5
        rr = np.hypot(d.XX + 0.5 - (cx + 0.5), d.YY + 0.5 - (cy + 7))
        ring = (rr >= 2.2) & (rr <= 3.4)
        d.h[ring] = Z_FACE + 6.0; d.mat[ring] = d.mid("chrome"); d.solid |= ring; d.polish[ring] = 1.0; d.tex[ring] = 0
        tag = M().rrect(cx - 3, cy + 10, 7, 6, 1).get()
        d.slab(tag, 5.0, "paint_r" if style == "chrome" else "paint_y", bevel=1.0, polish=0.5, on=Z_FACE + 0.5)
    b.variant(f"key_{b.id}", "keysIn", fn)


def pull_variant(b, cx, cy, r, mat="chrome"):
    """the headlamp pull knob drawn out: the knob nearer (a longer shadow) and its shaft showing"""
    def fn(d):
        rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
        shaft = (rr <= r + 1.6) & (rr > r - 0.5)
        d.h[shaft] = np.maximum(d.h[shaft], Z_FACE + 3.0); d.mat[shaft] = d.mid("chrome"); d.solid |= shaft; d.polish[shaft] = 1.0; d.tex[shaft] = 0
        m = rr <= r
        d.h[m] += 5.0
    b.variant(f"pull_{b.id}", "lights", fn)


def toggle_variant(b, cx, cy, src, on, base_up=False):
    def fn(d):
        rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
        wipe = (np.abs(d.XX + 0.5 - cx) <= 3.5) & (np.abs(d.YY + 0.5 - cy) <= 12.5) & (rr > 4.3)
        d.h[wipe] = on; d.mat[wipe] = d.mid("blackp"); d.tex[wipe] = 0.0
        toggle(d, cx, cy, up=not base_up, on=on)
    b.variant(f"tog_{src}_{b.id}", src, fn)


# ====================================================================== lower rows
def lower_boxy(b, y0=118, chrome=True, ashtray=True, lighter=True, trunk_label="TRUNK", trunk_sub=None, vent=True, cruise=True,
               lock=True, x_end=380, key_style=None):
    d = b.d; M = d.M
    met = "chrome" if chrome else "blackp"
    b.check_flat(24, y0 + 12, 22, 22, "lights knob")
    knob(d, 34, y0 + 22, 8, mat=met, on=Z_FACE, z=4.5, knurl=not chrome)
    ins = np.hypot(d.XX + 0.5 - 34, d.YY + 0.5 - (y0 + 22)) <= 5.2
    d.paint(ins, "blackp", flatlight=True)
    d.paint(icon_mask(d, "headlamp", 31, y0 + 20), "paint_w", flatlight=True)
    b.label("LIGHTS", 34, y0 + 33, align="c")
    pull_variant(b, 34, y0 + 22, 8, met)
    b.hit("lights", 24, y0 + 12, 21, 21)
    b.check_flat(68, y0 + 10, 25, 25, "ignition")
    d.torus(80, y0 + 22, 7, 10, 2.2, met, polish=1.0, on=Z_FACE)
    ig = np.hypot(d.XX + 0.5 - 80, d.YY + 0.5 - (y0 + 22)) < 7
    d.h[ig] = Z_FACE + 0.5; d.mat[ig] = d.mid("blackp"); d.polish[ig] = 0.5; d.tex[ig] = 0
    d.seam(box(79, y0 + 18, 2, 9), 0.8)
    for t, tx, ty in (("OFF", 66, y0 + 4), ("ON", 94, y0 + 4), ("START", 106, y0 + 20)):
        b.label(t, tx, ty, align="c")
    key_variant(b, 80, y0 + 22, key_style or ("chrome" if chrome else "black"))
    b.hit("ignition", 68, y0 + 10, 25, 25)
    x = 124
    if lighter:
        b.check_flat(x - 3, y0 + 15, 14, 14, "lighter")
        d.torus(x + 4, y0 + 22, 4, 6, 1.6, met, polish=1.0, on=Z_FACE)
        lt = np.hypot(d.XX + 0.5 - (x + 4), d.YY + 0.5 - (y0 + 22)) < 4
        d.h[lt] = Z_FACE + 1; d.mat[lt] = d.mid("blackp"); d.tex[lt] = 0
        d.tex[lt & (((d.XX + d.YY) % 2) == 0)] += 0.1
        x += 18
    if ashtray:
        b.check_flat(x + 2, y0 + 8, 74, 30, "ashtray")
        ash = box(x + 4, y0 + 10, 70, 26)
        d.flat(ash, Z_FACE + 0.2, b.cabin, polish=0.2); _pebble(d, ash, 0.04, seed=8)
        if chrome: chrome_frame(d, x + 3, y0 + 9, 72, 28, Z_FACE, t=1, r=1, z=1.6)
        else: d.seam(box(x + 3, y0 + 9, 72, 28) & ~box(x + 4, y0 + 10, 70, 26), 0.5)
        pull = M().rect(x + 28, y0 + 11, 22, 3).get()
        d.slab(pull, 2.4, met, bevel=1.0, polish=1.0, on=Z_FACE + 1.2)
        x += 84
    lx = x + 10
    if lock:
        b.check_flat(lx - 2, y0 + 12, 22, 17, "lock button")
        button(d, lx, y0 + 14, 18, 13, None, mat="blackp", on=Z_FACE, z=2.0, frame="chrome" if chrome else None)
        d.paint(icon_mask(d, "lock", lx + 7, y0 + 18), "paint_w", flatlight=True)
        b.label("LOCK", lx + 9, y0 + 31, align="c")
        b.led(lx + 13, y0 + 16, 3, 2, "anyLocked", "#44ee44")
        b.hit("lock", lx, y0 + 14, 18, 13)
        lx += 32
    tw = max(30, text_w(trunk_label) + 8)
    b.check_flat(lx - 2, y0 + 12, tw + 4, 17, "trunk button")
    button(d, lx, y0 + 14, tw, 13, trunk_label, mat="blackp", on=Z_FACE, frame="chrome" if chrome else None)
    if trunk_sub: b.label(trunk_sub, lx + tw // 2, y0 + 31, align="c")
    b.hit("trunk", lx, y0 + 14, tw, 13, needs="hasTrunk")
    cx_ = lx + tw + 14
    if cruise:
        b.check_flat(cx_ - 2, y0 + 12, 38, 17, "cruise button")
        button(d, cx_, y0 + 14, 34, 13, "CRUISE", mat="blackp", on=Z_FACE, frame="chrome" if chrome else None)
        b.label("ON  SET", cx_ + 17, y0 + 31, align="c")
        b.led(cx_ + 28, y0 + 16, 3, 2, "cruiseLamp", "#ffb02e")
        b.hit("cruise", cx_, y0 + 14, 34, 13, needs="running")
        cx_ += 48
    if vent and cx_ < x_end:
        b.check_flat(x_end + 2, y0 + 4, 102, 42, "driver vent")
        vent_rect(d, x_end + 4, y0 + 6, 98, 38, on=Z_FACE, bezel="chrome" if chrome else "blackp")
    return cx_


def lower_curvy(b, y0=122, vent=True, x_vent=330):
    d = b.d; M = d.M
    b.check_flat(26, y0 + 6, 25, 25, "lights knob")
    knob(d, 38, y0 + 18, 10, mat="blackp", on=Z_FACE, z=3.0, knurl=True)
    d.paint(icon_mask(d, "headlamp", 35, y0 + 31), "paint_w", flatlight=True)
    b.label("OFF", 22, y0 + 2, align="c")
    d.paint(icon_mask(d, "beam", 50, y0 + 1), "paint_w", flatlight=True)
    b.part("ptr", src="lights", cx=38, cy=y0 + 18, r0=2, r1=8, angles=[225, 315], color="#e8e8e8", w=1)
    b.hit("lights", 28, y0 + 8, 21, 21)
    b.check_flat(72, y0 + 6, 25, 25, "ignition")
    d.torus(84, y0 + 18, 7, 9.5, 1.6, "blackp", polish=0.6, on=Z_FACE)
    ig = np.hypot(d.XX + 0.5 - 84, d.YY + 0.5 - (y0 + 18)) < 7
    d.h[ig] = Z_FACE + 0.6; d.mat[ig] = d.mid("alu"); d.polish[ig] = 0.8; d.tex[ig] = 0
    d.seam(box(83, y0 + 14, 2, 9), 0.8)
    b.label("LOCK", 84, y0 + 1, align="c")
    key_variant(b, 84, y0 + 18, "black")
    b.hit("ignition", 74, y0 + 8, 21, 21)
    for i, ic in enumerate(("hazard", "defrost", "wiper")):
        b.check_flat(114 + i * 22, y0 + 6, 20, 26, f"rocker {ic}")
        rocker(d, 116 + i * 22, y0 + 8, 16, 22, on=Z_FACE, up=(i != 1), icon=ic, icon_mat="paint_r" if ic == "hazard" else "paint_w")
    b.check_flat(194, y0 + 9, 26, 18, "lock button")
    button(d, 196, y0 + 11, 22, 14, None, mat="blackp", on=Z_FACE, r=3)
    d.paint(icon_mask(d, "lock", 205, y0 + 15), "paint_w", flatlight=True)
    b.led(212, y0 + 13, 3, 2, "anyLocked", "#44ee44"); b.hit("lock", 196, y0 + 11, 22, 14)
    b.check_flat(224, y0 + 9, 38, 18, "trunk button")
    button(d, 226, y0 + 11, 34, 14, "TRUNK", mat="blackp", on=Z_FACE, r=3); b.hit("trunk", 226, y0 + 11, 34, 14, needs="hasTrunk")
    b.check_flat(266, y0 + 9, 44, 18, "cruise button")
    button(d, 268, y0 + 11, 40, 14, "CRUISE", mat="blackp", on=Z_FACE, r=3)
    b.led(302, y0 + 13, 3, 2, "cruiseLamp", "#7aff6a"); b.hit("cruise", 268, y0 + 11, 40, 14, needs="running")
    if vent:
        b.check_flat(x_vent - 2, y0 + 4, 154, 30, "driver vent")
        v = M().rrect(x_vent, y0 + 6, 150, 26, 12).get()
        d.slab(v, 1.0, "blackp", bevel=2.0, polish=0.2, on=Z_FACE)
        for k in range(y0 + 10, y0 + 29, 3):
            d.seam(v & (d.YY == k) & (d.XX > x_vent + 8) & (d.XX < x_vent + 142), 0.5)


# ====================================================================== climate blocks
TAB_SPRITES = ("tab_chrome", "tab_black", "slider", "tab_wood")


def slot(b, x, y, w, labels=None, lab_y=None, grad=None, on=Z_FACE):
    d = b.d
    b.check_flat(x - 1, y - 4, w + 2, 7, "lever slot")
    d.well(box(x, y, w, 2), 1.5, "rubber", bevel=0.6)
    if grad:
        cs = [hx(c) for c in grad]
        for i in range(w):
            t = i / max(1, w - 1)
            c = tuple(int(cs[0][k] + (cs[1][k] - cs[0][k]) * t) for k in range(3))
            d.emit[y - 3, x + i] = (*c, 255)
    if labels:
        ly = lab_y if lab_y is not None else y + 6
        n = len(labels)
        for i, t in enumerate(labels):
            if not t: continue
            lx = int(x + 4 + (w - 8) * i / max(1, n - 1))
            b.label(t, lx, ly, align="c")


def climate_levers(b, x, y, w=110, chrome=True, mode_labels=("OFF", "VENT", "HEAT", "DEF"), fan_knob=(752, 140),
                   ac_heat=True, on=Z_FACE, fan_mat=None, tab=None):
    """two levers (TEMP, AIR) riding in slots, a fan knob; the game slides the tabs. Spans y-4 .. y+32.
    A tab is 10 px tall from y-3 (y+17 for AIR), so the legends under each slot start a clear pixel below it
    (y+8, y+28): a tab parked on OFF or WARM never covers its own word."""
    d = b.d
    slot(b, x, y, w, ["COLD", "", "", "WARM"], y + 8, ("#3a6ad8", "#d83a2a"))
    slot(b, x, y + 20, w, list(mode_labels), y + 28)
    b.label("TEMP", x - 5, y - 2, "paint_c", align="r"); b.label("AIR", x - 5, y + 18, "paint_c", align="r")
    spr = tab or ("tab_chrome" if chrome else "tab_black")
    b.part("tab", src="tempF", x0=x, x1=x + w - 8, y=y - 3, sprite=spr)
    b.part("tab", src="modeF", x0=x, x1=x + w - 8, y=y + 17, sprite=spr)
    b.hit("temp", x, y - 4, w, 10, needs="hasHeater"); b.hit("heat", x, y + 16, w, 10, needs="hasHeater")
    fx, fy = fan_knob
    fm = fan_mat or ("chrome" if chrome else "blackp")
    b.check_flat(fx - 12, fy - 12, 24, 24, "fan knob")
    knob(d, fx, fy, 10, mat=fm, on=on, z=4.0, knurl=True)
    for lab, a in (("OFF", 150), ("LO", 205), ("2", 260), ("HI", 315)):
        ring_label(b, fx, fy, 11, a, lab, gap=2)
    b.label("FAN", fx, fy + 14, "paint_c", align="c")
    b.part("ptr", src="fan", cx=fx, cy=fy, r0=3, r1=8, angles=[150, 205, 260, 315], color="#101010" if fm == "chrome" else "#e8e8e8", w=1)
    b.hit("fan", fx - 10, fy - 10, 20, 20, needs="hasHeater")
    if ac_heat:
        bx = fx - 58
        b.check_flat(bx - 2, fy - 12, 30, 31, "A/C buttons")
        button(d, bx, fy - 10, 26, 11, "A/C", mat="blackp", on=on, frame="chrome" if chrome else None)
        b.led(bx + 22, fy - 8, 3, 2, "ac", "#ffb02e"); b.hit("ac", bx, fy - 10, 26, 11, needs="hasHeater")
        button(d, bx, fy + 6, 26, 11, "DEF", mat="blackp", on=on, frame="chrome" if chrome else None)
        b.hit("def", bx, fy + 6, 26, 11, needs="hasHeater")


def climate_sliders(b, x, y, w=118, on=Z_FACE, buttons=True):
    d = b.d
    for i, (lab, src, hid) in enumerate((("TEMP", "tempF", "temp"), ("FAN", "fanF", "fan"))):
        yy = y + i * 22
        # the knob is 11 px tall from yy-4: the fan's detent ticks sit a clear pixel below it (yy+8), never under it
        b.check_flat(x - 1, yy - 4, w + 2, 9 if lab == "TEMP" else 14, f"{lab} slider")
        d.well(box(x, yy, w, 2), 1.5, "rubber", bevel=0.6)
        if lab == "TEMP":
            for j in range(w):
                tt = j / max(1, w - 1)
                c = (int(58 + (216 - 58) * tt), int(106 + (58 - 106) * tt), int(216 + (42 - 216) * tt))
                d.emit[yy - 3, x + j] = (*c, 255)
        else:
            for j in range(4):
                tx = x + 4 + j * (w - 8) // 3
                d.paint(box(tx, yy + 8, 1, 2), "paint_w")
                b.ink_rect(tx, yy + 8, 1, 2, f"fan tick {j}")
        b.label(lab, x, yy - 10)
        b.part("tab", src=src, x0=x, x1=x + w - 8, y=yy - 4, sprite="slider")
        b.hit(hid, x, yy - 5, w, 12, needs="hasHeater")
    if buttons:
        bx = x + w + 14
        for i, (lab, key, led) in enumerate((("A/C", "ac", "ac"), ("DEF", "def", None), ("OFF", "off", None))):
            by = y - 8 + i * 13
            b.check_flat(bx - 1, by - 1, 30, 13, f"{lab} button")
            button(d, bx, by, 28, 11, lab, mat="blackp", on=on, r=3)
            if led: b.led(bx + 23, by + 2, 3, 2, led, "#7aff6a")
            b.hit(key, bx, by, 28, 11, needs="hasHeater")


def climate_buttons(b, x, y, lcd=True, on=Z_FACE, pitch=36, units="F"):
    d = b.d
    if lcd:
        b.check_flat(x - 57, y + 1, 48, 24, "climate display")
        window(d, x - 56, y + 2, 46, 22, 1.0, bezel=None, face="lcd", r=2, on=on, lens=False)
        b.part("climate", x=x - 52, y=y + 6, w=40, h=16, style="lcd", color="#1c2418", units=units)
    for i, (lab, key) in enumerate((("TEMP-", "tempdn"), ("TEMP+", "tempup"), ("A/C", "ac"), ("AUTO", "heat"))):
        b.check_flat(x + i * pitch - 1, y - 1, 34, 13, f"{lab} button")
        button(d, x + i * pitch, y, 32, 11, lab, mat="blackp", on=on, r=3)
        if key in ("ac", "heat"): b.led(x + i * pitch + 27, y + 2, 3, 2, "ac" if key == "ac" else "heatOn", "#7aff6a")
        b.hit(key, x + i * pitch, y, 32, 11, needs="hasHeater")
    for i, (lab, key) in enumerate((("FAN-", "fandn"), ("FAN+", "fanup"), ("DEF", "def"), ("OFF", "off"))):
        b.check_flat(x + i * pitch - 1, y + 15, 34, 13, f"{lab} button")
        button(d, x + i * pitch, y + 16, 32, 11, lab, mat="blackp", on=on, r=3)
        b.hit(key, x + i * pitch, y + 16, 32, 11, needs="hasHeater")


def climate_vfd(b, x, y, on=Z_FACE, units="F"):
    """luxury: an electronic climate panel, a blue-green readout and rocker keys"""
    d = b.d
    b.check_flat(x - 1, y - 1, 62, 26, "climate display")
    window(d, x, y, 60, 24, 1.2, bezel="chrome", face="vfd", r=1, on=on, lens=False)
    b.part("climate", x=x + 5, y=y + 6, w=50, h=13, style="vfd", color="#5ff2d0", units=units)
    for i, (lab, key, sec) in enumerate((("TEMP", "tempup", "tempdn"), ("FAN", "fanup", "fandn"), ("A/C", "ac", None), ("DEF", "def", None))):
        rx = x + 72 + i * 34
        b.check_flat(rx - 1, y - 1, 28, 26, f"{lab} rocker")
        rocker(d, rx, y, 26, 24, on=on, up=True, mat="blackp")
        b.label(lab, rx + 13, y + 28, align="c")
        if sec:
            b.hit(key, rx, y, 26, 12, needs="hasHeater"); b.hit(sec, rx, y + 12, 26, 12, needs="hasHeater")
        else:
            b.hit(key, rx, y, 26, 24, needs="hasHeater")


def climate_knobs(b, x, y, pitch=46, r=11, mat="blackp", on=Z_FACE, ring=None, ac=True):
    """three rotary knobs: temperature (blue to red), fan (0 to 3), air (vent to defrost)"""
    d = b.d
    cx = x
    for lab in ("TEMP", "FAN", "AIR"):
        b.check_flat(cx - r - 9, y - r - 9, 2 * r + 18, 2 * r + 24, f"{lab} knob")
        if lab == "TEMP":
            for j in range(13):
                a = 150 + 240 * j / 12.0
                t = j / 12.0
                c = (int(58 + (216 - 58) * t), int(106 + (58 - 106) * t), int(216 + (42 - 216) * t))
                ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
                m = line_mask(d, cx + ca * (r + 3), y + sa * (r + 3), cx + ca * (r + 6), y + sa * (r + 6), 1.2)
                d.emit[m] = (*c, 255)
        elif lab == "FAN":
            for j, t in enumerate(("0", "1", "2", "3")):
                a = 150 + 80 * j
                ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
                d.text(t, int(cx + ca * (r + 6)), int(y + sa * (r + 6)) - 2, "paint_w", align="c")
        else:
            for j, ic in enumerate(("fan", "defrost")):
                a = 200 if j == 0 else 340
                ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
                iw, ih = icon_size(ic)
                d.paint(icon_mask(d, ic, int(cx + ca * (r + 7)) - iw // 2, int(y + sa * (r + 7)) - ih // 2), "paint_w", flatlight=True)
        knob(d, cx, y, r, mat=mat, on=on, z=4.0, knurl=True, skirt=1.4 if ring == "chrome" else None)
        b.label(lab, cx, y + r + 8, "paint_c", align="c")
        if lab == "TEMP":
            b.part("ptr", src="tempF", cx=cx, cy=y, r0=3, r1=r - 2, a0=150, a1=390, color="#e8e8e8", w=1)
            b.hit("temp", cx - r, y - r, 2 * r, 2 * r, needs="hasHeater")
        elif lab == "FAN":
            b.part("ptr", src="fan", cx=cx, cy=y, r0=3, r1=r - 2, angles=[150, 230, 310, 390], color="#e8e8e8", w=1)
            b.hit("fan", cx - r, y - r, 2 * r, 2 * r, needs="hasHeater")
        else:
            b.part("ptr", src="modeF", cx=cx, cy=y, r0=3, r1=r - 2, a0=200, a1=340, color="#e8e8e8", w=1)
            b.hit("heat", cx - r, y - r, 2 * r, 2 * r, needs="hasHeater")
        cx += pitch
    if ac:
        bx = cx - pitch + r + 14
        b.check_flat(bx - 1, y - 12, 26, 28, "A/C button")
        button(d, bx, y - 10, 24, 11, "A/C", mat="blackp", on=on, r=2)
        b.led(bx + 19, y - 8, 3, 2, "ac", "#7aff6a"); b.hit("ac", bx, y - 10, 24, 11, needs="hasHeater")
        button(d, bx, y + 4, 24, 11, "DEF", mat="blackp", on=on, r=2)
        b.hit("def", bx, y + 4, 24, 11, needs="hasHeater")


def siren_box(b, x, y, w=150, on=Z_FACE, label="SIREN CONTROLLER"):
    """the fleet's siren controller: LIGHTS and SIREN rotaries, their pilot lamps (the prop up close is the same unit)"""
    d = b.d; M = d.M
    b.check_flat(x - 1, y - 1, w + 2, 40, "siren controller")
    bx = M().rrect(x, y, w, 38, 2).get()
    d.slab(bx, 2.6, "blackp", bevel=1.2, polish=0.3, on=on)
    d.tex[bx & (d.rng.random((H, W)) > 0.6)] += 0.05
    zt = on + 2.6
    d.text(label, x + w // 2, y + 3, "paint_c", align="c")
    for (lab, src, hid, kx, lamp_src, lamp_col) in (("LIGHTS", "lightbar", "lbar", x + 34, "lbarLamp", "#3a8aff"),
                                                    ("SIREN", "siren", "siren", x + w - 34, "sirenLamp", "#ff3a20")):
        knob(d, kx, y + 23, 7, mat="blackp", on=zt, z=2.5, knurl=True, skirt=1.2)
        for j in range(4):
            a = 200 + 46.7 * j
            ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
            m = line_mask(d, kx + ca * 10, y + 23 + sa * 10, kx + ca * 12, y + 23 + sa * 12, 1.0)
            d.paint(m, "paint_w")
        d.text(lab, kx, y + 32, "paint_w", align="c")
        b.part("ptr", src=src, cx=kx, cy=y + 23, r0=2, r1=6, angles=[200, 246.7, 293.4, 340], color="#e8e8e8", w=1)
        b.hit(hid, kx - 8, y + 15, 16, 16, needs="hasLightbar")
        lx = kx + (14 if kx < x + w // 2 else -18)
        lm = M().ellipse(lx + 2, y + 31, 2, 2).get()
        d.slab(lm, 1.0, "lens", bevel=0.8, polish=1.0, on=zt)
        b.part("led", x=lx, y=y + 29, w=4, h=4, src=lamp_src, color=lamp_col)
    b.meta["siren"] = (x, y, w, 38)


def taxi_meter(b, x, y, on=Z_FACE):
    """a fare meter bolted on the console: red figures, a HIRE flag lamp"""
    d = b.d; M = d.M
    b.check_flat(x - 1, y - 1, 92, 30, "taxi meter")
    body = M().rrect(x, y, 90, 28, 2).get()
    d.slab(body, 4.0, "blackp", bevel=1.4, polish=0.4, on=on)
    window(d, x + 6, y + 4, 52, 15, 0.8, bezel=None, face="ledglass", r=1, on=on + 4.0, lens=False)
    for i in range(5):
        for k, m in seg_masks(x + 10 + i * 9, y + 7, 6, 9, 1).items(): d.paint(m, "ledoff", flatlight=True)
    d.text("FARE $", x + 32, y + 21, "paint_w", align="c")
    lm = M().rrect(x + 64, y + 5, 20, 8, 1).get(); d.slab(lm, 0.6, "lens", bevel=0.6, polish=1.0, on=on + 4.0)
    ink = d.text("HIRE", x + 74, y + 7, "lampoff", align="c", flatlight=True)
    b.lamp(ink, "running", "#ff4a2a", within=lm)
    for i in range(2):
        button(d, x + 64 + i * 11, y + 17, 9, 7, None, mat="paint_r" if i == 0 else "blackp", on=on + 4.0, z=1.2)
    b.part("meter", x=x + 10, y=y + 7, cw=6, ch=9, pitch=9, color="#ff3a1a", src="fare", demo="3.40")
    b.meta["meter"] = (x, y, 90, 28)


def vents_pair(b, y, round_=False, chrome=True, x0=510, x1=696, w=88, h=20, on=Z_FACE):
    d = b.d
    if round_:
        r = h // 2
        for cx in (x0 + r + 2, x1 + w - r - 2):
            b.check_flat(cx - r - 3, y - 1, 2 * r + 6, 2 * r + 6, "round vent")
            vent_round(d, cx, y + r + 2, r, on=on, bezel="chrome" if chrome else "blackp")
    else:
        for vx in (x0, x1):
            b.check_flat(vx - 1, y - 1, w + 2, h + 2, "vent")
            vent_rect(d, vx, y, w, h, on=on, bezel="chrome" if chrome else "blackp")


def badge(b, x, y, w, h, style="flat", role="label", font="35", scale=1, color="#d8dade", plate=None, align="c", shadow=None,
          check=True):
    """the vehicle's name, drawn live by the game (a fleet car's unit number changes per car)"""
    d = b.d; M = d.M
    if check: b.check_flat(x - 2, y - 2, w + 4, h + 4, f"badge {role}")
    th = len(FONTS[font]["A"]) * scale
    ty = y + (h - th) // 2
    base = float(d.h[y + h // 2, x + w // 2])
    if plate == "chrome":
        m = M().rrect(x, y, w, h, 2).get(); d.slab(m, 1.4, "chrome", bevel=1.0, polish=1.0, on=base)
    elif plate == "black":
        m = M().rrect(x, y, w, h, 2).get(); d.slab(m, 0.8, "blackp", bevel=0.8, polish=0.3, on=base)
        chrome_frame(d, x - 1, y - 1, w + 2, h + 2, base, t=1, r=2, z=1.2)
    elif plate == "white":
        d.paint(box(x, y, w, h), "paint_w", flatlight=True)
    elif plate == "oval":
        outer = M().ellipse(x + w / 2, y + h / 2, w / 2, h / 2).get()
        inner = M().ellipse(x + w / 2, y + h / 2, w / 2 - 2, h / 2 - 2).get()
        d.slab(outer & ~inner, 1.6, "chrome", bevel=0.8, polish=1.0, on=base)
        d.slab(inner, 0.8, "blackp", bevel=0.6, polish=0.4, on=base)
    elif plate == "stencil":
        m = M().rect(x, y, w, h).get(); d.slab(m, 0.6, "blackp", bevel=0.6, polish=0.2, on=base)
    elif plate == "stamped":
        m = M().rrect(x, y, w, h, 1).get(); d.slab(m, 1.0, "alu", bevel=0.8, polish=0.6, on=base)
        for rx_ in (x + 3, x + w - 4): rivet(d, rx_, y + h // 2, on=base + 1.0)
    b.part("badge", role=role, x=x, y=ty, w=w, h=th, style=style, font=font, scale=scale, color=color, align=align, shadow=shadow)


def sticker_slot(b, x, y, w, h, match="spiffo"):
    """a blank for a sticker the game lays on only for some vehicles (the Spiffo's van gets the game's own Spiffo art)"""
    b.check_flat(x - 1, y - 1, w + 2, h + 2, "sticker slot")
    b.part("sticker", x=x, y=y, w=w, h=h, match=match)


# ====================================================================== sprites for sliding parts
def tab_sprite(kind):
    """a lever tab or slider knob, rendered alone with its outline (it slides, so its outline stands in for a shadow)"""
    d = Dash(14, 14, seed=3)
    M = d.M
    g = np.zeros((14, 14), bool)
    if kind == "tab_chrome":
        m = M().rrect(1, 1, 8, 8, 1).get(); d.slab(m, 3.2, "chrome", bevel=1.4, polish=1.0)
    elif kind == "tab_black":
        m = M().rrect(1, 1, 8, 8, 1).get(); d.slab(m, 3.2, "blackp", bevel=1.4, polish=0.6)
        g[3:7, 4] = True; g[3:7, 6] = True; d.seam(g, 0.35)
    elif kind == "tab_wood":
        m = M().rrect(1, 1, 8, 8, 1).get(); d.slab(m, 3.2, "walnut", bevel=1.4, polish=0.6)
    elif kind == "slider":
        m = M().rrect(1, 1, 8, 9, 2).get(); d.slab(m, 3.0, "blackp", bevel=1.6, polish=0.5)
        g[4:8, 5] = True; d.paint(g, "paint_w", flatlight=True)
    img = d.render()
    return img.crop(img.getbbox())
