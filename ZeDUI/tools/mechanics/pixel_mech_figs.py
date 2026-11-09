"""Vehicle diagram redraw (Design, Nov 3 2026; punch list 79, spec section 3): the game's mechanics overlay layers
redrawn as ZeD pixel art, same shapes. Each part stays one layer, drawn in greys (the tab tints it with the part's
condition colour, so the shading survives the tint); the base is the body, the callout boxes and their leaders.

usage: py pixel_mech_figs.py [stage dir] [--preview DIR]
  bakes every body shape in the game's overlay folder (SRC) to the stage dir (default ZeDUI/art/mech_pixel):
  textures/zm_*.png and MechFigs.lua; installing them is copying textures/ over 42/media/textures/ZeD/mech/ (the
  gridbox stays) and MechFigs.lua over 42/media/lua/client/ZeD/MechFigs.lua.
  --preview DIR also writes each body tinted with sample conditions at 2x (4K), and the sedan beside today's figure."""
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
    return shade(m, 235, 255, 185, depth=6.0, outline=140)


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
    # the body: the car's outline filled (the biggest closed shape in the base), its own panels shaded
    filled = ndi.binary_fill_holes(lines)
    lab, k = ndi.label(filled)
    sizes = ndi.sum(filled, lab, range(1, k + 1))
    car = lab == (1 + int(np.argmax(sizes)))
    body_m = car & ~parts
    bt = shade(body_m, 95, 135, 70, depth=4.0, outline=None)
    bt = np.where(car & ~ndi.binary_erosion(car), 230, bt)             # the car's own outline, light
    boxes = lines & ~car                                                # the callout boxes and leaders, as lines
    base_t = np.where(body_m | (car & ~ndi.binary_erosion(car)), bt, 0) + np.where(boxes, 230, 0)
    base_m = (body_m | (car & ~ndi.binary_erosion(car)) | boxes)
    out_layers = {"base": (base_t, base_m)}
    for n, (a, m) in layers.items():
        tt = tone_for(n, m, a)
        icon = not any(k in n for k in ("window", "wheel", "light", "door", "hood", "trunk", "bed", "roof"))
        detail = m & lines & ndi.binary_erosion(m) & icon        # only the callout icons: the leaders cross the panels
        out_layers[n] = (np.where(detail, 70, tt), m)
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
        c = (cond or {}).get(n, "good")
        over(t, m, cols[c], 0.95)
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
    # today's figure is baked for 2x; the new art is 1 px per design unit, so 2x for 4K
    H = max(old_im.height, new_im.height)
    S = Image.new("RGB", (old_im.width + new_im.width + 30, H), (20, 21, 24))
    S.paste(old_im, (0, 0)); S.paste(new_im, (old_im.width + 30, 0))
    S.save(path)


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
            anchors[key] = (int(x0), int(y0), int(x1 - x0), int(y1 - y0))
            p = b + "_"
            u = unions.get(p)
            unions[p] = (min(u[0], x0), min(u[1], y0), max(u[2], x1), max(u[3], y1)) if u else (x0, y0, x1, y1)
    with open(os.path.join(stage, "MechFigs.lua"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("-- GENERATED by ZeDUI/tools/mechanics/pixel_mech_figs.py - do not edit.\n")
        fh.write("-- Vehicle tab car figures, the pixel-art redraw (Design, Nov 3 2026; punch list 79): per-layer crop\n")
        fh.write(f"-- origin + size in art pixels (1 = {G} of the game's 263x600 overlay pixels); union box per body shape.\n")
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
        compare("4door", build("4door", os.path.join(prev, "_layers")), os.path.join(prev, "_compare_4door_4k.png"))
