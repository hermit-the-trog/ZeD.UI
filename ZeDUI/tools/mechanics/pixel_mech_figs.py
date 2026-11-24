"""Vehicle diagram redraw (Design, Nov 3 2026; punch list 79, spec section 3): the game's mechanics overlay layers
redrawn as ZeD pixel art, same shapes. Each part stays one layer, drawn in greys (the tab tints it with the part's
condition colour, so the shading survives the tint); the base is the body alone. The callout parts (engine, battery,
brakes, springs, gas tank, muffler) stand on their own beside it, where the game's boxes were, with no frame and no
leader (Nov 21 2026, director: "take the brakes and shocks and the engine and the battery out of the boxes that they
are in. Just have the parts no frame.").

usage: py pixel_mech_figs.py [stage dir] [--preview DIR]
  bakes every body shape in the game's overlay folder (SRC) to the stage dir (default ZeDUI/art/mech_pixel):
  textures/zm_*.png and MechFigs.lua; installing them is copying textures/ over 42/media/textures/ZeD/mech/ and
  MechFigs.lua over 42/media/lua/client/ZeD/MechFigs.lua (the tab no longer draws zm_gridbox.png, Nov 21 2026).
  --preview DIR also writes each body tinted with sample conditions at 2x (4K), and each body beside the figure the
  repo has installed now (_compare_<body>.png, compare_all.png): run it before installing to get before / after.
Nov 22 2026 (Car parts to the sides): the engine, battery, gas tank and muffler stand in the side columns with the
brakes and springs (to_sides below); the canvas is the car's height.
Nov 23 2026 (Car parts drawn): the brakes and springs are drawn here pixel by pixel (BRAKE and SPRING below) instead
of baked down from the game's icons, which came out blobby and scribbly at this size; the battery and the muffler too
(BATTERY, MUFFLER), and then the engine and the gas tank (ENGINE, TANK), which now stand the way the column has them
instead of turned on their side. The same day the glass's wear became cracks that run and branch (cracks())."""
import os, sys, glob, math, zlib
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

SRC = r"E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\ui\vehicles\mechanic overlay"
G = 2                      # one art pixel = 2 x 2 of the game's overlay pixels
LIGHT = np.array([-0.62, -0.78])   # the light from the top left (x, y)


def load(path):
    rgba = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32)
    a = rgba[..., 3] / 255.0 * (rgba[..., :3].mean(2) / 255.0)
    H, W = a.shape
    a = a[: H - H % G, : W - W % G]
    return a


def cells(a, mode="mean", th=0.5):
    h, w = a.shape[0] // G, a.shape[1] // G
    b = a.reshape(h, G, w, G)
    v = b.max(axis=(1, 3)) if mode == "max" else b.mean(axis=(1, 3))
    return v > th


def shade(m, base, hi, lo, depth=3.0, outline=None, rim_light=True):
    """a raised panel: its height rises from the edge, lit from the top left; four tones and a dark outline"""
    if not m.any(): return np.zeros(m.shape, np.float32)
    d = ndi.distance_transform_edt(m)
    h = np.clip(d / depth, 0, 1)
    gy, gx = np.gradient(ndi.gaussian_filter(h, 0.7))
    lit = -(gx * LIGHT[0] + gy * LIGHT[1]) * 3.0
    t = base + np.clip(lit, -1, 1) * np.where(lit > 0, hi - base, base - lo)
    t = np.round(t / 20.0) * 20.0                          # pixel-art steps
    edge = m & ~ndi.binary_erosion(m)
    if outline is not None: t = np.where(edge, outline, t)
    if rim_light:                                          # a lit pixel on the top-left rim
        tl = m & ~np.roll(m, 1, 0) | m & ~np.roll(m, 1, 1)
        t = np.where(tl & ~edge | (tl & (outline is None)), np.maximum(t, hi), t)
    return np.where(m, np.clip(t, 0, 255), 0).astype(np.float32)


def glass(m):
    t = shade(m, 150, 190, 120, depth=2.0, outline=100, rim_light=False)
    ys, xs = np.mgrid[0:m.shape[0], 0:m.shape[1]]
    glare = m & ~ndi.binary_erosion(m) == False
    inner = m & ndi.binary_erosion(m)
    if inner.any():
        ys_, xs_ = np.nonzero(inner)
        s0 = (xs_ + ys_).min(); span = max(1, (xs_ + ys_).max() - s0)
        sxy = xs + ys - s0
        band = inner & (sxy > span * 0.18) & (sxy < span * 0.18 + 2)
        band2 = inner & (sxy > span * 0.30) & (sxy < span * 0.30 + 1)
        t = np.where(band | band2, 235, t)
    return t


def tire(m):
    t = shade(m, 120, 150, 90, depth=1.5, outline=70, rim_light=False)
    ys, xs = np.mgrid[0:m.shape[0], 0:m.shape[1]]
    tread = m & ndi.binary_erosion(m, iterations=0 + 1) & (ys % 2 == 0)
    return np.where(tread, 65, t)


def lamp(m):
    return np.where(m, 255.0, 0.0).astype(np.float32)


def panel(m):
    """a body panel (door, hood, trunk, bed, roof): the raised shading, then its own pressed detail (Car wear, Nov 22
    2026; the director: "the body parts can take on some more texturing, like the glass"): a soft highlight band across
    it from the top left; on a panel wide and tall enough two creases along its length, each a darker pixel line with a
    lit one beside it, the way a pressed hood or trunk lid catches the light; on a door its belt line. All greys, so
    the condition tint still works."""
    t = shade(m, 235, 255, 185, depth=6.0, outline=140)
    inner = m & ndi.binary_erosion(m, iterations=2)
    if not inner.any(): return t
    ys, xs = np.nonzero(m)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    yy, xx = np.mgrid[0:m.shape[0], 0:m.shape[1]]
    # the highlight band: a two-pixel diagonal a fifth of the way in, one step lighter
    sxy = (xx - x0) + (yy - y0)
    span = max(1, (x1 - x0) + (y1 - y0))
    band = inner & (sxy >= int(span * 0.22)) & (sxy < int(span * 0.22) + 2)
    t = np.where(band, np.minimum(t + 20, 255), t)
    w, h = x1 - x0, y1 - y0
    if w >= 10 and h >= 10:
        # two creases running up and down the figure (front to back on the car)
        for f in (0.3, 0.7):
            cx = x0 + int(round(w * f))
            t = np.where(inner & (xx == cx), np.maximum(t - 40, 0), t)
            t = np.where(inner & (xx == cx + 1), np.minimum(t + 20, 255), t)
    elif h >= 10:
        # a door: its belt line, a darker row a third of the way down with a lit row under it
        cy = y0 + int(round(h * 0.35))
        t = np.where(inner & (yy == cy), np.maximum(t - 40, 0), t)
        t = np.where(inner & (yy == cy + 1), np.minimum(t + 20, 255), t)
    return np.where(m, t, 0).astype(np.float32)


# ---------------------------------------------------------------------------------------------------------------
# Wear by condition (Car wear, Nov 22 2026; the director: "based on condition, like a red part would have a lot of
# rust spots all over it. A yellow part would have maybe a little bit of rust or a scratch. And green would be, you
# know, pristine."). Each part gets two overlays the size of its own texture, masked to its shape inside its outline:
#   zm_<key>_wear1.png  light (the warn band): a scratch or two and a small spot of rust
#   zm_<key>_wear2.png  heavy (the bad band): the same rust spots grown into wide worn-in splotches, a scratch or two
# Rust pass two (the director, same day: "Rust naturally just increases in size, usually along how water runs or
# pools up ... it usually becomes more of like a worn-in splotch of rust ... It usually starts in one or two places
# and then gradually rusts out from that spot."): one or two seeds per part, placed where water would sit (near the
# part's edges and seams, and toward its lower side), each grown outward into a splotch that spreads further
# downward and along the edges than up and into the middle of the panel. Both overlays share the seeds and the
# ragged edge, so a red part shows its yellow spots grown bigger. Layered like patina: a dark core, an orange-brown
# body and a lighter broken rim with a few flakes past it. Rust is a fixed rust colour (the tab draws the overlay
# untinted); scratches are light lines. Glass, tyres and lamps do not rust. Tyres and lamps get scuffs (light lines; the
# heavy one more of them). The glass cracks (Nov 23 2026; the director: "make the cracks in the windshield and window
# glass look like cracks running ... Fractaling"): a strike in the pane with cracks running out of it and branching
# (cracks() below). Everything is seeded from the part's own name: a bake is the same every time.
# ---------------------------------------------------------------------------------------------------------------
RUST_CORE = (78, 38, 20)       # the deep pitted heart
RUST_BODY = (128, 66, 30)      # the orange-brown spread
RUST_EDGE = (164, 98, 50)      # the lighter, broken rim where the paint is lifting
SCRATCH = (196, 192, 184)      # a light line, not white: bright specks read as noise
SPLOTCH_R = (0.10, 0.38)       # a splotch's reach in the light and heavy wear, times the root of the part's area
SPLOTCH_MAX = (4.0, 13.0)      # and its most, in art px
# a glass crack is cut into the pane, not drawn on it (the director, Nov 23 2026: "They're just a little too bright.
# They need some bevel or depth or something to not be just white lines"): a dark cut, and under it, a pixel down and
# right, its lit lip, the wall of the crack that faces the light from the top left
CRACK = (40, 38, 36)           # the cut
CRACK_LIP = (165, 170, 174)    # its lit lip, soft (a bright one read as a white line again)
CHIP = (30, 28, 26)            # the strike, the deepest point


# Glass cracks (Nov 23 2026; the director: "make the cracks in the windshield and window glass look like cracks
# running ... Fractaling"): a strike in the pane, cracks running out of it with a slight waver, branching as they go,
# each branch running shorter; a crack that meets another stops there, as cracks do. The yellow overlay is the red
# one's start: the strike as a chip with its main crack partly run; the red one has every crack run out (rings round
# the strike were tried: at this size they drew loops, not a web).
def _rng(key, *path):
    return np.random.default_rng(zlib.crc32(("crack:" + key + ":" + ":".join(map(str, path))).encode()))


def cracks(key, inner, heavy):
    """(crack mask, chip mask) for one pane; inner is the pane inside its outline"""
    H, W = inner.shape
    out = np.zeros((H, W), bool)
    chip = np.zeros((H, W), bool)
    area = int(inner.sum())
    if area < 6: return out, chip
    ys, xs = np.nonzero(inner)
    # the pane's size and its long axis
    h, w = ys.max() - ys.min() + 1, xs.max() - xs.min() + 1
    S = float(max(h, w))
    narrow = min(h, w) <= 6
    along = math.pi / 2 if h > w else 0.0
    # never more glass cracked than this: a share of a big pane; a narrow one has room for its crack's length
    cap = int(max(area * (0.24 if heavy else 0.10), S * (1.4 if heavy else 0.7)))
    g = 1.0 if heavy else (0.35 if narrow else 0.5)     # the yellow crack is the red one part run
    # the strike: away from the edge where the pane allows, a little low on a wide pane (where the stones hit)
    d = ndi.distance_transform_edt(inner)
    r0 = _rng(key, "strike")
    YY, XX = np.mgrid[0:H, 0:W]
    wgt = np.where(inner, np.clip(d - 1.0, 0.2, 3.0) ** 2, 0.0)
    # toward the middle of the pane's length (a strike at the very end only cracks the corner)
    if w >= h: mid = 1.0 - np.abs(XX - xs.mean()) / (w / 2.0)
    else: mid = 1.0 - np.abs(YY - ys.mean()) / (h / 2.0)
    wgt = wgt * np.clip(mid, 0.05, 1.0) ** 1.5
    if not narrow and w > h: wgt = wgt * (0.7 + 0.6 * YY / float(H))
    p = wgt[ys, xs] / wgt[ys, xs].sum()
    i0 = int(r0.choice(len(ys), p=p))
    sy, sx = int(ys[i0]), int(xs[i0])
    chip[sy, sx] = True
    owner = np.full((H, W), -1, np.int32)               # which crack drew each pixel (a crack stops on another)
    owner[sy, sx] = 0
    count = [1]
    nid = [1]

    def clump(y, x):
        """would cracking (y, x) fill a 2 x 2 block? (the strike's own ring of pixels may: the cracks leave it there)"""
        if abs(y - sy) <= 1 and abs(x - sx) <= 1: return False
        c = owner >= 0
        for oy in (-1, 0):
            for ox in (-1, 0):
                y0, x0 = y + oy, x + ox
                if 0 <= y0 and y0 + 1 < H and 0 <= x0 and x0 + 1 < W:
                    blk = c[y0:y0 + 2, x0:x0 + 2].copy(); blk[y - y0, x - x0] = True
                    if blk.all(): return True
        return False

    def walk(y, x, ang, length, depth, path, parent):
        """one crack from (y, x) on heading ang, one pixel a step along its main axis; it branches as it runs"""
        rg = _rng(key, *path)
        me = nid[0]; nid[0] += 1
        fy, fx = float(y), float(x)

        def ahead(a):                        # the next point on heading a: one pixel along the main axis
            dx, dy = math.cos(a), math.sin(a)
            s = max(abs(dx), abs(dy))
            return fy + dy / s, fx + dx / s

        def inside(q):
            qy, qx = int(round(q[0])), int(round(q[1]))
            return 0 <= qy < H and 0 <= qx < W and inner[qy, qx]

        head, drift, bounces = ang, 0.0, 0
        for step in range(int(length * g)):
            # a crack runs on in its heading with a slight waver (it never curls back), and now and then kinks
            drift = 0.8 * drift + rg.normal(0.0, 0.09)
            if rg.random() < 0.07: head += (1 if rg.random() < 0.5 else -1) * rg.uniform(0.15, 0.4)
            ang = head + drift
            q = ahead(ang)
            if not inside(q):
                # in a narrow pane a crack glances off the frame and runs on, zig-zagging (a lightning bolt); in a
                # big one it runs into the frame and stops
                if not narrow or bounces >= 4: return
                flip = (math.pi - ang) if h > w else -ang                  # off a long side (an end stops it)
                if not inside(ahead(flip)): return
                jig = flip + rg.normal(0.0, 0.2)                           # each leg its own slant
                head, drift, bounces = (jig if inside(ahead(jig)) else flip), 0.0, bounces + 1
                q = ahead(head)
            if count[0] >= cap: return
            fy, fx = q
            py, px = int(round(fy)), int(round(fx))
            # met another crack: join it and stop. For its first steps a crack still runs beside the one it left
            # and the others leaving the same point, so those do not count yet.
            y0_, x0_ = max(0, py - 1), max(0, px - 1)
            nb = owner[y0_:py + 2, x0_:px + 2]
            hit = (nb >= 0) & (nb != me)
            if step < 4:
                ny, nx = np.mgrid[y0_:y0_ + nb.shape[0], x0_:x0_ + nb.shape[1]]
                hit &= (nb != parent) & ((np.abs(ny - y) > 2) | (np.abs(nx - x) > 2))
            if hit.any():
                if owner[py, px] < 0 and not clump(py, px): out[py, px] = True; owner[py, px] = me; count[0] += 1
                return
            if owner[py, px] < 0:
                if clump(py, px): return             # a crack is a line: it never fills a 2 x 2 block
                out[py, px] = True; owner[py, px] = me; count[0] += 1
            # a branch: off to one side, shorter, and branching less
            pb = (0.075, 0.05, 0.0)[min(depth, 2)]
            if step >= 4 and rg.random() < pb:
                side = 1 if rg.random() < 0.5 else -1
                walk(py, px, ang + side * rg.uniform(0.3, 0.75), length * rg.uniform(0.3, 0.55), depth + 1,
                     path + (step,), me)

    # the main crack, both ways through the strike, along the pane (across a wide one, within a turn of its axis)
    rm = _rng(key, "main")
    base = along + (rm.choice([-1, 1]) * rm.uniform(0.45, 0.75) if narrow else
                    float(np.clip(rm.normal(0.0, 0.45), -0.7, 0.7)))
    if min(h, w) <= 2: base = along          # a pane a pixel or two across: the crack runs straight along it
    walk(sy, sx, base, S * 0.9, 0, ("m", 0), 0)
    walk(sy, sx, base + math.pi, S * 0.7, 0, ("m", 1), 0)
    if heavy:
        # the strike's other cracks, running out all round it
        k = 1 if narrow else (2 if min(h, w) <= 12 else (3 if area < 400 else 4))
        for j in range(k):
            a = base + (j + 1) * 2 * math.pi / (k + 2) + rm.normal(0.0, 0.25)
            walk(sy, sx, a, S * rm.uniform(0.3, 0.6), 1, ("r", j), 0)
    out &= ~chip
    return out, chip


def wear(key, m, heavy):
    """the RGBA wear overlay for one part (key: <body>_<part>; m: its cropped mask)"""
    import zlib
    H, W = m.shape
    out = np.zeros((H, W, 4), np.uint8)
    inner = (m & ndi.binary_erosion(m)) if min(H, W) >= 3 else m.copy()
    if not inner.any(): return out
    no_rust = any(k in key for k in ("window", "wheel", "light"))
    area = int(inner.sum())
    YY, XX = np.mgrid[0:H, 0:W]
    # two streams: the rust's (the same for both overlays, so red grows from yellow's spots) and the scratches'
    rr = np.random.default_rng(zlib.crc32((key + "_rust").encode()))
    rs = np.random.default_rng(zlib.crc32((key + ("_2" if heavy else "_1")).encode()))

    def put(mask, col):
        mask = mask & inner
        out[mask, 0], out[mask, 1], out[mask, 2], out[mask, 3] = col[0], col[1], col[2], 255

    def scratch():
        ys, xs = np.nonzero(inner)
        i = rs.integers(len(ys))
        y, x = ys[i], xs[i]
        dy, dx = [(1, 1), (1, -1), (0, 1), (1, 0), (1, 2), (2, 1)][rs.integers(6)]
        mk = np.zeros_like(inner)
        for k in range(int(rs.integers(3, 6))):
            yy, xx = int(round(y + dy * k * 0.5)), int(round(x + dx * k * 0.5))
            if 0 <= yy < H and 0 <= xx < W: mk[yy, xx] = True
        put(mk, SCRATCH)

    if no_rust:
        if "window" in key:                  # glass: cracks running out of a strike (Nov 23 2026)
            cr, chip = cracks(key, inner, heavy)
            cut = cr | chip
            lip = np.zeros_like(cut)
            lip[1:, 1:] = cut[:-1, :-1]      # a pixel down and right of the cut
            put(lip & ~cut, CRACK_LIP); put(cr, CRACK); put(chip, CHIP)
            return out
        for _ in range(1 if area < 40 else 2): scratch()
        if heavy:
            for _ in range(max(1, area // 260)): scratch()               # a scuffed tyre, a lamp
        return out

    # where water sits: near an edge or seam (the outline, and the part's own detail lines show as its edge) and
    # low in the part; the seeds are drawn from that weight
    edge_d = ndi.distance_transform_edt(m)
    wet = np.exp(-(edge_d - 1.0) / 1.6) * (0.25 + (YY + 1.0) / H) ** 2
    wet = np.where(inner, wet, 0.0)
    ys, xs = np.nonzero(inner)
    pw = wet[ys, xs]; pw = pw / pw.sum()
    n_seed = 1 if area < 120 else 2
    seeds = [int(rr.choice(len(ys), p=pw))]
    if n_seed > 1:
        # the second spot somewhere else wet, at least a third of the part's reach away from the first
        far = np.hypot(ys - ys[seeds[0]], xs - xs[seeds[0]]) >= 0.33 * np.sqrt(area)
        if far.any():
            p2 = np.where(far, pw, 0.0); seeds.append(int(rr.choice(len(ys), p=p2 / p2.sum())))
    # a soft noise field for the ragged edge, the same in both overlays
    noise = ndi.gaussian_filter(rr.random((H, W)), 1.1)
    noise = (noise - noise.mean()) / max(1e-6, noise.std())
    # the rim breaks in clumps, not salt: a smoothed field, and a few lone flakes past it
    clump = ndi.gaussian_filter(rr.random((H, W)), 0.8)
    clump = (clump - clump.mean()) / max(1e-6, clump.std())
    flake = rr.random((H, W))
    # the reach from the nearest seed: moving down costs less than moving up (water runs down), and running along
    # an edge costs less than heading into the open panel
    reach = np.full((H, W), 1e9)
    for i in seeds:
        dy = YY - ys[i]
        dx = XX - xs[i]
        dyw = np.where(dy > 0, dy * 0.6, -dy * 1.5)
        reach = np.minimum(reach, np.sqrt(dx * dx + dyw * dyw))
    reach = reach * (0.75 + 0.25 * np.clip((edge_d - 1.0) / 3.0, 0, 1))
    R = max(1.2 if not heavy else 2.6, SPLOTCH_R[1 if heavy else 0] * np.sqrt(area))
    R = min(R, SPLOTCH_MAX[1 if heavy else 0])     # a big panel (a truck bed) rusts in spots too, not all over
    d = reach / R + noise * 0.16
    body = d < 1.0
    put(body & (d >= 0.78) & (clump > -0.5), RUST_EDGE)                    # the broken rim
    put(body & (d < 0.78), RUST_BODY)
    put(body & (d < (0.38 if heavy else 0.30)), RUST_CORE)
    put(~body & (d < 1.2) & (flake < 0.05), RUST_EDGE)                     # a few flakes lifting past it
    for _ in range(1 if area < 200 else 2): scratch()
    return out


def part_metal(m, a_full):
    """the callout icons (engine, battery, brakes, springs, tank, muffler): metal, their own detail lines kept"""
    return shade(m, 240, 255, 190, depth=2.5, outline=150)


KIND = [("window", glass), ("wheel", tire), ("headlight", lamp), ("taillight", lamp), ("light", lamp)]


def tone_for(name, m, a):
    for k, fn in KIND:
        if k in name: return fn(m)
    if any(k in name for k in ("door", "hood", "trunk", "bed", "roof")): return panel(m)
    return part_metal(m, a)


def to_rgba(t, m):
    g = np.clip(t, 0, 255).astype(np.uint8)
    rgba = np.zeros(m.shape + (4,), np.uint8)
    rgba[..., 0] = rgba[..., 1] = rgba[..., 2] = g
    rgba[..., 3] = np.where(m, 255, 0)
    return rgba


def rim_of(m):
    e = m & ~ndi.binary_erosion(m)
    return to_rgba(np.where(e, 255.0, 0.0), e)


def hitch_gap(lines, filled, car):
    """the open space inside a trailer's tow hitch (Car parts to the sides, Nov 22 2026; the director: "The tow hitch
    extensions ... are square tubing that come to an intersection where the tow hitch is. So there's no panel in the
    middle."). Filling the car's outline also filled the triangle the two arms close with the trailer's front, so it
    came out a grey panel. That triangle is a hole in the line art that starts in a point (one or two cells wide at
    its top) a little under the ball, about half fills its box (a triangle) and sits in the car's top third; the
    ball's own ring (right at the top) and the panels (square, or wide at the top) are left alone. Returns its cells."""
    gap = np.zeros_like(car)
    ys, xs = np.nonzero(car)
    top, H = ys.min(), ys.max() + 1 - ys.min()
    lab, k = ndi.label(filled & ~lines)
    for i in range(1, k + 1):
        hy, hx = np.nonzero(lab == i)
        n = len(hy)
        if n < 10: continue
        h, w = hy.max() - hy.min() + 1, hx.max() - hx.min() + 1
        tip = int((hy == hy.min()).sum())
        if tip <= 2 and n / float(w * h) <= 0.7 and hy.min() > top + 4 and hy.min() < top + H / 3.0:
            gap |= lab == i
    return gap


def build(body, out):
    os.makedirs(out, exist_ok=True)
    files = sorted(glob.glob(os.path.join(SRC, body + "_*.png")))
    names = [os.path.basename(f)[len(body) + 1:-4] for f in files]
    layers = {}
    for f, n in zip(files, names):
        a = load(f)
        layers[n] = (a, cells(a, "max" if n == "base" else "mean", 0.35 if n == "base" else 0.45))
    base_a, lines = layers.pop("base")
    parts = np.zeros_like(lines)
    for n, (a, m) in layers.items(): parts |= m
    # the body: the car's outline filled (the biggest closed shape in the base), its own panels shaded. The game's
    # callout boxes and their leader lines are left out (Nov 21 2026): a leader touching the car's outline joined its
    # box to the car (the battery and wheel boxes came out shaded like body panels), so the one-cell lines are opened
    # away first, the car taken as the biggest shape left, and the cell the opening shaved off its outline put back.
    filled = ndi.binary_fill_holes(lines)
    sq = np.ones((3, 3), bool)
    opened = ndi.binary_opening(filled, structure=sq)
    lab, k = ndi.label(opened)
    sizes = ndi.sum(opened, lab, range(1, k + 1))
    car = filled & ndi.binary_dilation(lab == (1 + int(np.argmax(sizes))), structure=sq)
    for _ in range(2):          # the first cell of a leader comes back with the outline: a nub, one side touching
        nb = ndi.convolve(car.astype(np.uint8), np.array([[0, 1, 0], [1, 0, 1], [0, 1, 0]], np.uint8), mode="constant")
        car &= ~(car & (nb <= 1))
    if "trailer" in body: car &= ~hitch_gap(lines, filled, car)
    body_m = car & ~parts
    bt = shade(body_m, 95, 135, 70, depth=4.0, outline=None)
    bt = np.where(car & ~ndi.binary_erosion(car), 230, bt)             # the car's own outline, light
    base_t = np.where(body_m | (car & ~ndi.binary_erosion(car)), bt, 0)
    base_m = body_m | (car & ~ndi.binary_erosion(car))
    out_layers = {"base": (base_t, base_m)}
    for n, (a, m) in layers.items():
        tt = tone_for(n, m, a)
        icon = not any(k in n for k in ("window", "wheel", "light", "door", "hood", "trunk", "bed", "roof"))
        detail = m & lines & ndi.binary_erosion(m) & icon        # only the callout icons: the leaders cross the panels
        out_layers[n] = (np.where(detail, 70, tt), m)
    redraw_callouts(out_layers)          # the drawn parts (Nov 23 2026)
    to_sides(out_layers, layers, lines)
    return save_layers(body, out, out_layers)


# ---------------------------------------------------------------------------------------------------------------
# Car parts drawn (Nov 23 2026; the director: "The vehicle parts, could you please redraw the suspension
# and brakes? They just don't read well. Kind of blobby or scribbly, or both.", then "the muffler and battery could
# use a little extra attention as well", then "fidelity pass on the engine and fuel tank as well"). The game's icons
# are 32 overlay pixels square; baked down to 16 art pixels, the spring's diagonal coils turned to hatching, the
# disc's lug holes and caliper to a blob and the battery's top to a tangle of lines, and the engine and the tank,
# turned on their side, to scribbles. These six are drawn at their own size instead, one picture each, used for every
# body shape, left and right alike (the game's own icons are not mirrored either):
#   BRAKE   the disc face on, its swept face ringed off from its lip, its hat with four lug nuts and the axle, the
#           caliper a dark block clamped over the rim at the top right and standing out past it, its pad line and a
#           bolt lit (the game's icon, the right way round; "The brakes look great")
#   SPRING  a coilover upright: an eye at each end, a spring seat under the top eye and over the bottom one, and
#           three coils round the damper, each coil open (the panel shows through) with its far side dark behind
#           the damper and its near side in front of it, the wire and the damper lit at the left and shaded at the
#           right so they read round
#   BATTERY the case from the front: two terminal posts on its lid, a seam under the lid, a label band across the
#           case with the minus and the plus each under its own post
#   MUFFLER the canister lying on its side as the column has it, round (a lit band near its top, a shaded one near
#           its foot), its rolled crimps near each end (a dark line, a lit one), the pipe in at the left and
#           the tailpipe out at the right, a little lower (drawn lying down, as the column has it)
#   ENGINE  the engine from the side, standing (the way the check-engine light draws one, so it reads as an engine):
#           the block, the head on it with the head gasket between them and four plug boots along it, the finned
#           valve cover on the head with the oil cap, the oil pan under the block with its sump deeper at the back
#           and the drain plug, the fan edge on at the front on its shaft through the water pump pulley, and the
#           exhaust manifold off the back of the head and down the back (23 wide, as the game's engine was, so the
#           figure is no wider and the tab's zoom does not change)
#   TANK    the gas tank lying as it does under a car: its two pressed halves with the seam round the middle
#           standing out at the ends, round (a lit band near its top, a shaded one near its foot), two straps round
#           it, the filler neck up and out at the front end with its cap, and the fuel line out low at the back
# The letters are tones (TONES): a grey, or a bevelled region (face, lit top / left edge, shaded bottom / right edge),
# so the light still comes from the top left and the tab's condition tint keeps the shading. A sprite stands where
# the game's icon stood (its centre); the cars' side columns then lay it out with the rest (to_sides). The trailers
# keep the game's places, a spring over its brake: each pair is set round the pair's old centre, PAIR_GAP apart, so
# the taller spring does not run into its brake.
# ---------------------------------------------------------------------------------------------------------------
BRAKE = [
    ".......xxxx....",
    ".......xcccxx..",
    "....ooooxcicxx.",
    "..oofffffxccicx",
    ".offnnnnffxcicx",
    ".ofnffffnfxcicx",
    "ofnffhhhfnfxccx",
    "ofnfhlhlhfnxccx",
    "ofnfhhdhhfnxxxx",
    "ofnfhlhlhfnfo..",
    "ofnffhhhffnfo..",
    ".ofnffffnnfo...",
    ".offnnnnnffo...",
    "..oofffffoo....",
    "....ooooo......",
]
SPRING = [                 # (9 wide: the director, Nov 23 2026: "The shocks are just a little bit too wide")
    "...ooo...",
    "..oeeeo..",
    "..oeDeo..",
    ".ooeeeoo.",
    "opppppppo",
    ".oBjkgBo.",
    "oS.jkg.zo",
    ".oSssszo.",
    ".oBjkgBo.",
    "oS.jkg.zo",
    ".oSssszo.",
    ".oBjkgBo.",
    "oS.jkg.zo",
    ".oSssszo.",
    "opppppppo",
    ".ooeeeoo.",
    "..oeDeo..",
    "..oeeeo..",
    "...ooo...",
]
BATTERY = [
    "..ooo.....ooo..",
    "..oto.....oto..",
    "ooooooooooooooo",
    "oaaaaaaaaaaaaao",
    "ommmmmmmmmmmmmo",
    "offfffffffffffo",
    "oyyyyyyyyyydyyo",
    "oydddyyyyydddyo",
    "oyyyyyyyyyydyyo",
    "offfffffffffffo",
    "ooooooooooooooo",
]
MUFFLER = [
    "........oooooooooooooo........",
    ".......ofmSfffffffffmSo.......",
    ".......oSmSSSSSSSSSSmSo.......",
    "oooooooofmSfffffffffmSo.......",
    "oqqqqqqofmSfffffffffmSoooooooo",
    "oooooooofmSfffffffffmSoqqqqqqd",
    ".......ozmzzzzzzzzzzmzo.......",
    ".......ofmffffffffffmfo.......",
    "........oooooooooooooo........",
]
ENGINE = [
    ".........ooooo.........",
    ".........olllo.........",
    "........ooooooooo......",
    ".......ooaaaaaaaoo.....",
    "ooo....oaSaSaSaSao.....",
    "oco....oaSaSaSaSao.....",
    "oco..ooooooooooooooo...",
    "oco..ohhhhhhhhhhhhhoooo",
    "oco..ohdhhdhhdhhdhhqqqo",
    "ocoooohhhhhhhhhhhhhqqqo",
    "ocoeeommmmmmmmmmmmmoqqo",
    "oceeeofffffffffffffoqqo",
    "oceeeofffffffffffffoqqo",
    "ocoeeofffffffffffffoqqo",
    "ocoooofffffffffffffoqqo",
    "oco..offfffffffffffoqqo",
    "oco..offfffffffffffoqqo",
    "oco..oooooooooooooooooo",
    "ooo...opppppppppppo....",
    "......ooooopppppppo....",
    "..........oooooDooo....",
    "..............ooo......",
]
TANK = [
    "ooooo........................",
    "orrro........................",
    "orrroo.......................",
    "oooqqoo......................",
    "..ooqqoo.....................",
    "...ooqqoooo........ooo.......",
    "....ooqqouoooooooooouooooo...",
    "...ooffffuffffffffffuffffoo..",
    "...ofSSSSuSSSSSSSSSSuSSSSfo..",
    "...offfffuffffffffffufffffo..",
    "...offfffuffffffffffufffffo..",
    "..oofffffuffffffffffufffffoo.",
    "..ommmmmmummmmmmmmmmummmmmmoo",
    "..oofffffuffffffffffufffffqqo",
    "...offfffuffffffffffufffffooo",
    "...ofzzzzuzzzzzzzzzzuzzzzfo..",
    "...ooffffuffffffffffuffffoo..",
    "....ooooouoooooooooouooooo...",
    "........ooo........ooo.......",
]
TONES = {
    "o": 150,                  # the outline, as the other callout parts have it
    "f": (235, 255, 195),      # the disc's face
    "h": (190, 225, 160),      # the disc's hat, the engine's head
    "l": 245,                  # a lug nut, the engine's oil cap
    "d": 70, "D": 70,          # the axle, an eye's hole, a plug boot, the drain plug
    "c": (150, 180, 120),      # the caliper, the engine's fan
    "x": 90,                   # the caliper's outline: darker, so it stands off the disc
    "e": (200, 230, 165),      # an eye, the fan's shaft and the water pump pulley
    "p": (205, 235, 170),      # a spring seat, the oil pan
    "s": 235,                  # a coil's near side
    "B": 105,                  # a coil's far side, behind the damper
    "k": 150,                  # the damper
    "t": (200, 230, 165),      # a battery terminal
    "a": (205, 235, 170),      # the battery's lid, the valve cover
    "m": 175,                  # a seam: under the battery's lid, the muffler's crimps, the head gasket, the tank's
    "q": (190, 220, 150),      # a pipe (the exhaust manifold, the filler neck and the fuel line too)
    # the fidelity pass (the director, Nov 23 2026: "Give each of the car parts one more fidelity pass")
    "n": 205,                  # the ring round the disc's swept face
    "i": 205,                  # the caliper's pad line and its bolt
    "S": 255,                  # a lit pixel on a round part: a coil's left, the muffler's and the tank's lit band,
                               # the valve cover's fins
    "z": 190,                  # a shaded pixel on a round part: a coil's right, the muffler's and the tank's foot band
    "j": 180,                  # the damper's lit side
    "g": 115,                  # the damper's shaded side
    "y": 210,                  # the battery's label band
    "r": (215, 245, 180),      # the gas cap
    "u": 120,                  # a strap round the tank
}
PAIR_GAP = 3       # rows between a trailer's spring and its brake


def half_up(v):
    """a place to a whole pixel, halves up: Python's round() takes halves to the even number, which set a column's
    odd-width parts a pixel apart (a spring a pixel right of its brake)"""
    return int(math.floor(v + 0.5))


def bevel(reg, face, hi, lo):
    """a region's tones: its top / left edge lit, its bottom / right edge shaded (a pixel on both stays the face)"""
    p = np.pad(reg, 1)
    lit = reg & ~(p[:-2, 1:-1] & p[1:-1, :-2])            # nothing of it above or to the left
    sh = reg & ~(p[2:, 1:-1] & p[1:-1, 2:])               # nothing of it below or to the right
    t = np.full(reg.shape, float(face), np.float32)
    t[sh & ~lit] = lo
    t[lit & ~sh] = hi
    return t


def sprite(rows):
    """a drawn picture: (tones, mask)"""
    W = len(rows[0])
    assert all(len(r) == W for r in rows), "every row the same width"
    g = np.array([list(r) for r in rows], dtype="<U1")
    t = np.zeros(g.shape, np.float32)
    for ch, spec in TONES.items():
        reg = g == ch
        if not reg.any(): continue
        t[reg] = bevel(reg, *spec)[reg] if isinstance(spec, tuple) else spec
    return t, g != "."


def drawn_for(name):
    if name.startswith("brake_"): return BRAKE
    if name.startswith("suspension_"): return SPRING
    if name == "battery": return BATTERY
    if name == "muffler": return MUFFLER
    if name == "engine": return ENGINE
    if name == "gastank": return TANK
    return None


def redraw_callouts(out_layers):
    """the drawn parts swapped in for the baked ones (in place), each centred where the game's icon stood; a
    trailer's spring and brake set as a pair round the pair's old centre (the cars' columns are laid out after)"""
    old = {}
    for n, (t, m) in out_layers.items():
        if drawn_for(n) and m.any():
            ys, xs = np.nonzero(m)
            old[n] = (ys.min(), ys.max() + 1, xs.min(), xs.max() + 1)
    if not old: return
    Hc, Wc = next(iter(out_layers.values()))[1].shape

    def place(n, top, cx):
        t, m = sprite(drawn_for(n))
        h, w = m.shape
        x = half_up(cx - w / 2.0)
        x = min(max(x, 0), Wc - w); top = min(max(half_up(top), 0), Hc - h)
        nt, nm = np.zeros((Hc, Wc), np.float32), np.zeros((Hc, Wc), bool)
        nt[top:top + h, x:x + w], nm[top:top + h, x:x + w] = np.where(m, t, 0), m
        out_layers[n] = (nt, nm)

    done = set()
    if not any(n in out_layers for n, side, turn in MOVE):          # a trailer: the game's places, pairs kept apart
        # (QA, Nov 23 2026: the game's left and right icons stand a pixel apart, so each side's own centre set the left
        # and right pairs a pixel apart in height; both sides now share the mean of their two centres)
        def pair_mid(pos, side):
            sp, br = f"suspension_{pos}_{side}", f"brake_{pos}_{side}"
            return (old[sp][0] + old[br][1]) / 2.0 if (sp in old and br in old) else None
        for side in ("left", "right"):
            for pos in ("front", "rear"):
                sp, br = f"suspension_{pos}_{side}", f"brake_{pos}_{side}"
                if sp in old and br in old:
                    hs, hb = len(SPRING), len(BRAKE)
                    mids = [m for m in (pair_mid(pos, "left"), pair_mid(pos, "right")) if m is not None]
                    mid = sum(mids) / len(mids)
                    top = mid - (hs + PAIR_GAP + hb) / 2.0
                    place(sp, top, (old[sp][2] + old[sp][3]) / 2.0)
                    place(br, top + hs + PAIR_GAP, (old[br][2] + old[br][3]) / 2.0)
                    done |= {sp, br}
    for n, (y0, y1, x0, x1) in old.items():
        if n not in done:
            place(n, (y0 + y1) / 2.0 - len(drawn_for(n)) / 2.0, (x0 + x1) / 2.0)


# ---------------------------------------------------------------------------------------------------------------
# Car parts to the sides (Car parts to the sides, Nov 22 2026; the director: "move all of the car parts to one side
# or the other side of the car ... just like the brakes and the shocks ... Then the car figure can hopefully get a
# little larger because it gains some vertical space"). The game's overlay puts the engine and battery above the car
# and the gas tank and muffler below it. They go into the two side columns with the brakes and springs: the engine
# and battery on the left (the front parts), the gas tank and muffler on the right (fuel and exhaust). Baked from the
# game's icons, the engine, gas tank and muffler lay on their side (turned a quarter, then shaded) so the columns
# stayed narrow; all four are drawn now (Nov 23 2026, above), each the way the column has it, so nothing is turned
# (TURN is kept for a part baked from the game's icon). Nothing stays above or below the car, so the canvas is the
# car's height.
# Then (the director, same day: "Space out the vehicle parts a little more on each side. Just balance everything
# out.") each column is laid out again as six rows, the same on both sides: front spring, front brake, engine / gas
# tank, battery / muffler, rear spring, rear brake. A row is as tall as the taller of its two parts, and the rows
# are spread evenly over the car's height with equal gaps between them and above and below (space evenly). Both
# columns are as wide as the widest part in either, stand CLEAR cells off the body, and each part is centred in its
# cell, so left and right mirror each other. The trailers have no parts to move and keep the game's layout.
# ---------------------------------------------------------------------------------------------------------------
MOVE = [("engine", "left", True), ("battery", "left", False),
        ("gastank", "right", True), ("muffler", "right", True)]
ROWS = [("suspension_front_left", "suspension_front_right"), ("brake_front_left", "brake_front_right"),
        ("engine", "gastank"), ("battery", "muffler"),
        ("suspension_rear_left", "suspension_rear_right"), ("brake_rear_left", "brake_rear_right")]
TURN = {n: turn for n, side, turn in MOVE}
PADX = 24        # cells added each side of the overlay canvas: the columns may stand past its edges
CLEAR = 6        # cells between a column and the car body (4 before the director's spacing note)


def to_sides(out_layers, layers, lines):
    """lays the side columns out again (ROWS); out_layers is changed in place, every layer padded by PADX"""
    for n in list(out_layers):
        t, m = out_layers[n]
        out_layers[n] = (np.pad(t, ((0, 0), (PADX, PADX))), np.pad(m, ((0, 0), (PADX, PADX))))
    lines = np.pad(lines, ((0, 0), (PADX, PADX)))
    if not any(n in out_layers for n, side, turn in MOVE): return
    bm = out_layers["base"][1]
    ys, xs = np.nonzero(bm)
    car_y0, car_y1, car_x0, car_x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    # each part cut out of its layer (turned when it lies on its side), its own detail lines kept on the turned
    # ones (they are shaded again after turning); the others keep their tones as they are
    cut = {}
    for pair in ROWS:
        for n in pair:
            if n not in out_layers: continue
            t, m = out_layers[n]
            yy, xx = np.nonzero(m)
            y0, y1, x0, x1 = yy.min(), yy.max() + 1, xx.min(), xx.max() + 1
            mc, tc = m[y0:y1, x0:x1], t[y0:y1, x0:x1]
            if TURN.get(n) and not drawn_for(n):         # (a drawn part is drawn the way the column has it)
                dc = mc & lines[y0:y1, x0:x1] & ndi.binary_erosion(mc)
                mc, dc = np.rot90(mc), np.rot90(dc)
                tc = np.where(dc, 70, tone_for(n, mc, None))
            cut[n] = (tc, mc)
    rows = [pair for pair in ROWS if any(n in cut for n in pair)]
    rh = [max(cut[n][1].shape[0] for n in pair if n in cut) for pair in rows]
    cw = max(m.shape[1] for t, m in cut.values())
    gap = (car_y1 - car_y0 - sum(rh)) / float(len(rows) + 1)
    if gap < 2: print(f"  warning: the side columns are tight (a gap of {gap:.1f} rows)")
    centre = {0: car_x0 - CLEAR - cw / 2.0, 1: car_x1 + CLEAR + cw / 2.0}   # left and right column centre lines
    y = car_y0 + gap
    for pair, h_row in zip(rows, rh):
        for k, n in enumerate(pair):
            if n not in cut: continue
            tc, mc = cut[n]
            h, w = mc.shape
            x = half_up(centre[k] - w / 2.0)
            yy = half_up(y + (h_row - h) / 2.0)
            nt, nm = np.zeros(bm.shape, np.float32), np.zeros(bm.shape, bool)
            nt[yy:yy + h, x:x + w], nm[yy:yy + h, x:x + w] = np.where(mc, tc, 0), mc
            out_layers[n] = (nt, nm)
        y += h_row + gap
    print(f"  columns {cw} wide, {CLEAR} off the body; rows {rh}, gap {gap:.1f}")


def save_layers(body, out, out_layers):
    for n, (t, m) in out_layers.items():
        Image.fromarray(to_rgba(t, m)).save(os.path.join(out, f"{body}_{n}.png"))
        if n != "base": Image.fromarray(rim_of(m)).save(os.path.join(out, f"{body}_{n}_rim.png"))
    return out_layers


BODY_TINT_A = 0.22   # the base wash's alpha, the same number drawFigure uses (MechanicsTab.lua)


def preview(body, out_layers, path, scale=3, cond=None):
    """the figure as the tab draws it: the base dim, each part tinted by a condition colour"""
    H, W = next(iter(out_layers.values()))[1].shape
    img = np.zeros((H, W, 3), np.float32); img[...] = (34, 36, 40)
    def over(t, m, col, alpha):
        c = np.asarray(col, np.float32) / 255.0
        src = t[..., None] / 255.0 * c[None, None, :] * 255.0
        a = (m * alpha)[..., None]
        img[...] = img * (1 - a) + src * a
    dim = (150, 150, 140)
    over(*out_layers["base"], dim, 0.6)
    cols = {"good": (90, 200, 110), "warn": (230, 170, 60), "bad": (225, 70, 60)}
    # the base's light wash in the vehicle's overall condition color, as the tab draws it (Nov 22 2026): the mean of
    # the parts' sample conditions (good 80, warn 40, bad 10), banded as the status bars band it
    names = [n for n in out_layers if n != "base"]
    bands = [cond.get(n, "good") if isinstance(cond, dict) else (cond or "good") for n in names]
    mean = sum({"good": 80, "warn": 40, "bad": 10}[b] for b in bands) / float(max(1, len(bands)))
    over(*out_layers["base"], cols["good" if mean > 60 else "warn" if mean > 20 else "bad"], BODY_TINT_A)
    for i, (n, (t, m)) in enumerate(out_layers.items()):
        if n == "base": continue
        c = cond.get(n, "good") if isinstance(cond, dict) else (cond or "good")
        over(t, m, cols[c], 0.7)       # the tab's strength for a part's condition colour (Nov 22 2026)
        if c != "good" and m.any():    # and its wear on top, untinted, as the tab draws it (Car wear, Nov 22 2026)
            ys, xs = np.nonzero(m)
            y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
            wv = wear(body + "_" + n, m[y0:y1, x0:x1], c == "bad").astype(np.float32)
            a = wv[..., 3:4] / 255.0
            sub = img[y0:y1, x0:x1]
            sub[...] = sub * (1 - a) + wv[..., :3] * a
    # cropped to the figure's union, as the tab fits it (Car parts to the sides, Nov 22 2026)
    allm = np.zeros((H, W), bool)
    for t, m in out_layers.values(): allm |= m
    ys, xs = np.nonzero(allm)
    img = img[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    H, W = img.shape[:2]
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).resize((W * scale, H * scale), Image.NEAREST)
    im.save(path)


def compare(body, out_layers, path):
    import glob as _g
    REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
    MOD = os.path.join(REPO, "42", "media", "textures", "ZeD", "mech")
    MF = open(os.path.join(REPO, "42", "media", "lua", "client", "ZeD", "MechFigs.lua"), encoding="utf-8").read()
    import re
    rects = {k: tuple(map(int, v)) for k, *v in re.findall(r'\["([A-Za-z0-9_]+)"\] = \{ x = (\d+), y = (\d+), w = (\d+), h = (\d+)', MF)}
    U = rects[body + "_base"]
    ux0 = min(r[0] for k, r in rects.items() if k.startswith(body + "_")); uy0 = min(r[1] for k, r in rects.items() if k.startswith(body + "_"))
    ux1 = max(r[0] + r[2] for k, r in rects.items() if k.startswith(body + "_")); uy1 = max(r[1] + r[3] for k, r in rects.items() if k.startswith(body + "_"))
    old = np.zeros((uy1 - uy0, ux1 - ux0, 3), np.float32); old[...] = (34, 36, 40)
    cond = COND
    cols = {"good": (90, 200, 110), "warn": (230, 170, 60), "bad": (225, 70, 60)}
    for k, (x, y, w, h) in rects.items():
        if not k.startswith(body + "_"): continue
        n = k[len(body) + 1:]
        p = os.path.join(MOD, "zm_" + k + ".png")
        if not os.path.exists(p): continue
        im = np.asarray(Image.open(p).convert("RGBA")).astype(np.float32)
        col = (150, 150, 140) if n == "base" else cols[cond.get(n, "good")]
        al = (0.45 if n == "base" else 0.7) * im[..., 3:4] / 255.0   # the tab's 0.7 (Nov 22 2026)
        src = im[..., :3] / 255.0 * np.asarray(col, np.float32)
        sub = old[y - uy0:y - uy0 + h, x - ux0:x - ux0 + w]
        sub[...] = sub * (1 - al) + src * al
    old_im = Image.fromarray(old.astype(np.uint8))
    new_im = Image.open(os.path.join(os.path.dirname(path), f"_preview_{body}.png"))
    # both at 2x (the new preview is written at 2x; today's figure is 1 art px per design unit too), the same
    # scale side by side, so the heights compare (Car parts to the sides, Nov 22 2026)
    old_im = old_im.resize((old_im.width * 2, old_im.height * 2), Image.NEAREST)
    from PIL import ImageDraw
    top = 22
    H = max(old_im.height, new_im.height) + top
    S = Image.new("RGB", (old_im.width + new_im.width + 30, H), (20, 21, 24))
    S.paste(old_im, (0, top)); S.paste(new_im, (old_im.width + 30, top))
    d = ImageDraw.Draw(S)
    d.text((2, 4), f"{body} before {old_im.width // 2}x{old_im.height // 2}", fill=(200, 200, 200))
    d.text((old_im.width + 32, 4), f"after {new_im.width // 2}x{new_im.height // 2}", fill=(200, 200, 200))
    S.save(path)
    return S


COND = {"brake_front_left": "bad", "wheel_front_left": "bad", "battery": "warn", "window_rear_left": "warn",
        "door_rear_right": "bad", "muffler": "warn", "hood": "warn"}




# ---------------------------------------------------------------------------------------------------------------
# The bake: every body shape's layers, cropped, as the tab loads them (zm_<body>_<part>.png and _rim), and their
# anchors as ZeD.MechFigs (same form as bake_mech_figs.py's: per-layer crop origin and size, a union per body). The
# units are art pixels (1 = 2 of the game's overlay pixels, about one design unit); the tab only uses them relative
# to the union, so K is informational.
# ---------------------------------------------------------------------------------------------------------------
def bake_all(stage):
    tex_dir = os.path.join(stage, "textures"); os.makedirs(tex_dir, exist_ok=True)
    bodies = sorted(os.path.basename(f)[:-len("_base.png")] for f in glob.glob(os.path.join(SRC, "*_base.png")))
    anchors, unions = {}, {}
    for b in bodies:
        L = build(b, os.path.join(stage, "_layers", b))
        for n, (t, m) in L.items():
            ys, xs = np.nonzero(m)
            if len(xs) == 0: continue
            x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
            key = f"{b}_{n}"
            Image.fromarray(to_rgba(t, m)[y0:y1, x0:x1]).save(os.path.join(tex_dir, f"zm_{key}.png"), optimize=True)
            if n != "base":
                Image.fromarray(rim_of(m)[y0:y1, x0:x1]).save(os.path.join(tex_dir, f"zm_{key}_rim.png"), optimize=True)
                # the wear overlays, the layer's own size, so the tab draws them in the part's rect (Car wear, Nov 22 2026)
                for k, heavy in ((1, False), (2, True)):
                    Image.fromarray(wear(key, m[y0:y1, x0:x1], heavy)).save(
                        os.path.join(tex_dir, f"zm_{key}_wear{k}.png"), optimize=True)
            anchors[key] = (int(x0), int(y0), int(x1 - x0), int(y1 - y0))
            p = b + "_"
            u = unions.get(p)
            unions[p] = (min(u[0], x0), min(u[1], y0), max(u[2], x1), max(u[3], y1)) if u else (x0, y0, x1, y1)
    with open(os.path.join(stage, "MechFigs.lua"), "w", encoding="utf-8", newline="\n") as fh:
        # the header as the mod ships it (Build's house form), so the file goes in as written
        fh.write("-- ZeD-UI/42/media/lua/client/ZeD/MechFigs.lua\n"
                 "-- ============================================================================\n"
                 "-- MECH FIGURES -- client; a generated data table (the pixel_mech_figs.py\n"
                 "-- mechanics tool writes it: do not edit by hand, regenerate). The Vehicle\n"
                 "-- tab's pixel-art car figures, drawn by MechanicsTab.lua: per-layer crop\n"
                 f"-- origin + size in art pixels (1 = {G} of the game's 263x600 overlay pixels),\n"
                 "-- and the union box per body shape.\n"
                 "-- ============================================================================\n")
        fh.write("ZeD = ZeD or {}\nZeD.MechFigs = {\n  K = %s,\n  art = \"pixel\",\n  layers = {\n" % (1.0 / G))
        for k in sorted(anchors):
            x, y, w, h = anchors[k]
            fh.write(f'    ["{k}"] = {{ x = {x}, y = {y}, w = {w}, h = {h} }},\n')
        fh.write("  },\n  unions = {\n")
        for p in sorted(unions):
            x0, y0, x1, y1 = unions[p]
            fh.write(f'    ["{p}"] = {{ x = {int(x0)}, y = {int(y0)}, w = {int(x1 - x0)}, h = {int(y1 - y0)} }},\n')
        fh.write("  },\n}\nreturn ZeD.MechFigs\n")
    import shutil
    shutil.rmtree(os.path.join(stage, "_layers"), ignore_errors=True)
    print(f"baked {len(anchors)} layers for {len(unions)} body shapes -> {stage}")
    return anchors, unions


if __name__ == "__main__":
    args = sys.argv[1:]
    prev = None
    if "--preview" in args:
        i = args.index("--preview"); prev = args[i + 1]; del args[i:i + 2]
    here = os.path.dirname(os.path.abspath(__file__))
    stage = args[0] if args else os.path.join(here, "..", "..", "art", "mech_pixel")
    bake_all(stage)
    if prev:
        os.makedirs(prev, exist_ok=True)
        for b in sorted(os.path.basename(f)[:-len("_base.png")] for f in glob.glob(os.path.join(SRC, "*_base.png"))):
            L = build(b, os.path.join(prev, "_layers"))
            preview(b, L, os.path.join(prev, f"_preview_{b}.png"), scale=2, cond=COND)
        # before (the repo's figure as installed now: run --preview BEFORE copying the new bake in) and after, per
        # body, and all 13 on one sheet (Car parts to the sides, Nov 22 2026)
        sheets = []
        for b in sorted(os.path.basename(f)[:-len("_base.png")] for f in glob.glob(os.path.join(SRC, "*_base.png"))):
            sheets.append(compare(b, None, os.path.join(prev, f"_compare_{b}.png")))
        import shutil
        shutil.rmtree(os.path.join(prev, "_layers"), ignore_errors=True)
        cols = 4
        cw, ch = max(i.width for i in sheets) + 20, max(i.height for i in sheets) + 20
        rows = (len(sheets) + cols - 1) // cols
        sheet = Image.new("RGB", (cw * cols, ch * rows), (20, 21, 24))
        for i, im in enumerate(sheets): sheet.paste(im, ((i % cols) * cw + 10, (i // cols) * ch + 10))
        sheet.save(os.path.join(prev, "compare_all.png"))
        # wear sheets (Car wear, Nov 22 2026): each body all good, all warn and all bad side by side, all 13 on one
        from PIL import ImageDraw
        wears = []
        for b in sorted(os.path.basename(f)[:-len("_base.png")] for f in glob.glob(os.path.join(SRC, "*_base.png"))):
            L = build(b, os.path.join(prev, "_layers"))
            ims = []
            for c in ("good", "warn", "bad"):
                pth = os.path.join(prev, f"_wear_{b}_{c}.png")
                preview(b, L, pth, scale=3, cond=c)
                ims.append(Image.open(pth).convert("RGB")); os.remove(pth)
            top = 22
            S = Image.new("RGB", (sum(i.width for i in ims) + 40, max(i.height for i in ims) + top), (20, 21, 24))
            d = ImageDraw.Draw(S); x = 0
            for c, im in zip(("good (green): pristine", "warn (yellow): light wear", "bad (red): heavy rust"), ims):
                S.paste(im, (x, top)); d.text((x + 2, 4), f"{b}  {c}", fill=(200, 200, 200)); x += im.width + 20
            S.save(os.path.join(prev, f"wear_{b}.png")); wears.append(S)
        shutil.rmtree(os.path.join(prev, "_layers"), ignore_errors=True)
        cols = 2
        cw, ch = max(i.width for i in wears) + 20, max(i.height for i in wears) + 20
        rows = (len(wears) + cols - 1) // cols
        sheet = Image.new("RGB", (cw * cols, ch * rows), (20, 21, 24))
        for i, im in enumerate(wears): sheet.paste(im, ((i % cols) * cw + 10, (i // cols) * ch + 10))
        sheet.save(os.path.join(prev, "wear_all.png"))
