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
brakes and springs (to_sides below); the canvas is the car's height."""
import os, sys, glob
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
#   zm_<key>_wear1.png  light (the warn band): a scratch or two and a speck or two of rust
#   zm_<key>_wear2.png  heavy (the bad band): rust spots all over, a fine speckle between them, a few scratches
# Rust is a fixed rust colour (the tab draws the overlay untinted); scratches are light lines. Glass, tyres and lamps
# do not rust: they get scuffs and cracks only (light lines; the heavy one more of them). Each part's pattern is
# seeded from its own name, so a bake is the same every time and nothing changes frame to frame.
# ---------------------------------------------------------------------------------------------------------------
RUST = [(84, 42, 22), (112, 58, 30), (150, 86, 42)]     # deep, mid and a lighter flaking rust
SCRATCH = (196, 192, 184)     # a light line, not white: bright specks read as noise


def wear(key, m, heavy):
    """the RGBA wear overlay for one part (key: <body>_<part>; m: its cropped mask)"""
    import zlib
    rng = np.random.default_rng(zlib.crc32((key + ("_2" if heavy else "_1")).encode()))
    H, W = m.shape
    out = np.zeros((H, W, 4), np.uint8)
    inner = (m & ndi.binary_erosion(m)) if min(H, W) >= 3 else m.copy()
    if not inner.any(): return out
    no_rust = any(k in key for k in ("window", "wheel", "light"))
    area = int(inner.sum())
    YY, XX = np.mgrid[0:H, 0:W]

    def put(mask, col):
        mask = mask & inner
        out[mask, 0], out[mask, 1], out[mask, 2], out[mask, 3] = col[0], col[1], col[2], 255

    def anywhere():
        ys, xs = np.nonzero(inner)
        i = rng.integers(len(ys))
        return ys[i], xs[i]

    def scratch():
        y, x = anywhere()
        dy, dx = [(1, 1), (1, -1), (0, 1), (1, 0), (1, 2), (2, 1)][rng.integers(6)]
        mk = np.zeros_like(inner)
        for k in range(int(rng.integers(3, 6))):
            yy, xx = int(round(y + dy * k * 0.5)), int(round(x + dx * k * 0.5))
            if 0 <= yy < H and 0 <= xx < W: mk[yy, xx] = True
        put(mk, SCRATCH)

    def spot(r):
        y, x = anywhere()
        d = (YY - y) ** 2 + (XX - x) ** 2
        blob = d <= r * r + int(rng.integers(0, 2))
        put(blob, RUST[1])
        put(blob & (d <= max(0, (r - 1) ** 2)), RUST[0])                 # a deeper heart
        if r >= 2: put(blob & (d > (r - 0.5) ** 2) & (rng.random((H, W)) < 0.5), RUST[2])   # a ragged, flaking edge

    if not heavy:
        for _ in range(1 if area < 40 else 2): scratch()
        if not no_rust:
            for _ in range(1 if area < 60 else 2): spot(0 if area < 30 else 1)
    else:
        for _ in range(max(1, area // 220)): scratch()
        if no_rust:
            for _ in range(max(1, area // 140)): scratch()               # a cracked pane, a scuffed tyre
        else:
            for _ in range(max(2, area // 35)): spot(int(rng.integers(0, 3 if area >= 60 else 2)))
            put(inner & (rng.random((H, W)) < 0.03), RUST[1])             # a fine speckle between the spots
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
    to_sides(out_layers, layers, lines)
    return save_layers(body, out, out_layers)


# ---------------------------------------------------------------------------------------------------------------
# Car parts to the sides (Car parts to the sides, Nov 22 2026; the director: "move all of the car parts to one side
# or the other side of the car ... just like the brakes and the shocks ... Then the car figure can hopefully get a
# little larger because it gains some vertical space"). The game's overlay puts the engine and battery above the car
# and the gas tank and muffler below it. They go into the two side columns with the brakes and springs: the engine
# and battery on the left (the front parts), the gas tank and muffler on the right (fuel and exhaust). The engine,
# gas tank and muffler lie on their side (turned a quarter) so the columns stay narrow; they are shaded after
# turning, so the light still comes from the top left. Nothing stays above or below the car, so the canvas is the
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
            if TURN.get(n):
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
            x = int(round(centre[k] - w / 2.0))
            yy = int(round(y + (h_row - h) / 2.0))
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
        al = (0.45 if n == "base" else 0.95) * im[..., 3:4] / 255.0
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
