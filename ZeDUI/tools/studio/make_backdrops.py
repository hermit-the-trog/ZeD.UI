"""The portrait studio's backdrops, first drafts (punch list 145, step 2; the director, Nov 10 2026: "go ahead with
those backdrops"). Build drafts them; the director refines or repaints them.

Each backdrop is painted procedurally (fractal noise, gradients, glows, bokeh) at 1024 x 576 (16:9) and saved as
42/media/textures/ZeD/studio/backdrop_<id>.png, which the studio draws over the whole screen ("cover": scaled to fill,
the edges cropped on screens of another shape). The plain grey seamless is drawn by the studio itself (no texture).

For the director: ZeDUI/art/studio_backdrops/
  contact_sheet.png     the five, named
  safe_area_1920.png    a 1920 x 1080 guide, transparent but for the zones: where the figure stands (full body,
                        centred, rows 46 to 1020 at 1080p), where the head sits in each framing, and the bar along the
                        foot (44 px at 1x) that covers the paper while setting up (not in the photo)
  <id>_1920.png         each draft at 1920 x 1080, to paint over

Run from the repo root:  python3 ZeDUI/tools/studio/make_backdrops.py
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1024, 576
OUT = "42/media/textures/ZeD/studio"
ART = "ZeDUI/art/studio_backdrops"
RNG = np.random.default_rng(1993)          # (the desk's year: the drafts come out the same every run)


def noise(w, h, octaves=6, base=4, persist=0.55, seed=None):
    """fractal value noise in 0..1: random grids upsampled bicubically, summed by octave"""
    rng = np.random.default_rng(seed) if seed is not None else RNG
    acc = np.zeros((h, w), np.float32)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        gw, gh = base * 2 ** o + 1, max(2, int(base * 2 ** o * h / w) + 1)
        grid = (rng.random((gh, gw)) * 255).astype(np.uint8)
        layer = np.asarray(Image.fromarray(grid).resize((w, h), Image.BICUBIC), np.float32) / 255.0
        acc += layer * amp
        total += amp
        amp *= persist
    acc /= total
    acc -= acc.min()
    acc /= max(1e-6, acc.max())
    return acc


def ramp(t, stops):
    """t (0..1 array) through colour stops [(pos, (r, g, b)), ...]"""
    t = np.clip(t, 0, 1)
    out = np.zeros(t.shape + (3,), np.float32)
    for i in range(len(stops) - 1):
        p0, c0 = stops[i]
        p1, c1 = stops[i + 1]
        m = (t >= p0) & (t <= p1)
        f = ((t - p0) / max(1e-6, p1 - p0))[m][:, None]
        out[m] = np.array(c0, np.float32) * (1 - f) + np.array(c1, np.float32) * f
    return out


def grids():
    ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
    return xs / (W - 1), ys / (H - 1)


def glow(cx, cy, r, sx=1.0):
    """a soft round light, 1 at (cx, cy) falling to 0 at r (in fractions of the height)"""
    x, y = grids()
    d = np.sqrt(((x - cx) * W / H / sx) ** 2 + (y - cy) ** 2) / r
    return np.clip(1 - d, 0, 1) ** 2


def vignette(strength=0.45):
    x, y = grids()
    d = np.sqrt(((x - 0.5) * 1.3) ** 2 + (y - 0.48) ** 2)
    return 1 - strength * np.clip(d / 0.75, 0, 1) ** 2


def to_img(arr):
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")


# ---------------------------------------------------------------------------------------------------------------------
# THE FIVE
# ---------------------------------------------------------------------------------------------------------------------
def mottled_blue():
    """the mall portrait studio's mottled blue: a painted canvas, darker at the edges, a light behind the head"""
    n = noise(W, H, octaves=7, base=3, persist=0.6, seed=11)
    n2 = noise(W, H, octaves=5, base=8, persist=0.5, seed=12)
    t = 0.65 * n + 0.35 * n2
    col = ramp(t, [(0.0, (14, 26, 58)), (0.35, (32, 58, 112)), (0.6, (58, 92, 160)), (0.85, (104, 132, 196)), (1.0, (150, 170, 220))])
    light = glow(0.5, 0.36, 0.62, 1.2)
    col = col * (0.72 + 0.55 * light[..., None])
    col *= vignette(0.5)[..., None]
    return to_img(col)


def sky():
    """a soft summer sky: deep blue up top, pale at the horizon, cumulus drifting through"""
    x, y = grids()
    col = ramp(y, [(0.0, (52, 104, 168)), (0.55, (118, 164, 212)), (1.0, (206, 222, 236))])
    n = noise(W, H, octaves=7, base=3, persist=0.55, seed=21)
    band = np.clip(1 - np.abs(y - 0.42) / 0.45, 0, 1)
    c = np.clip((n - 0.52) / 0.2, 0, 1) * band
    shade = noise(W, H, octaves=4, base=6, seed=22)
    cloud = np.stack([245 - 30 * shade, 246 - 26 * shade, 250 - 18 * shade], -1)
    col = col * (1 - c[..., None]) + cloud * c[..., None]
    img = to_img(col).filter(ImageFilter.GaussianBlur(1.2))
    return img


def autumn():
    """an autumn wood, out of focus: warm mottling, bokeh of leaves, darker at the foot"""
    x, y = grids()
    n = noise(W, H, octaves=6, base=4, persist=0.6, seed=31)
    col = ramp(n, [(0.0, (58, 30, 16)), (0.3, (128, 58, 20)), (0.55, (196, 104, 30)), (0.8, (226, 160, 56)), (1.0, (240, 204, 120))])
    col *= (1 - 0.35 * np.clip((y - 0.55) / 0.45, 0, 1))[..., None]
    img = to_img(col).filter(ImageFilter.GaussianBlur(6))
    # the bokeh: soft discs of leaf colours, more at the sides
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rng = np.random.default_rng(32)
    cols = [(255, 196, 80), (240, 120, 40), (200, 60, 30), (255, 230, 150), (160, 80, 30)]
    for _ in range(140):
        side = rng.random()
        cx = rng.random() * 0.36 if side < 0.42 else (1 - rng.random() * 0.36 if side < 0.84 else 0.3 + rng.random() * 0.4)
        cy = rng.random() * 0.9
        r = 6 + rng.random() * 26
        c = cols[rng.integers(len(cols))]
        a = int(40 + rng.random() * 90)
        d.ellipse([cx * W - r, cy * H - r, cx * W + r, cy * H + r], fill=c + (a,))
    layer = layer.filter(ImageFilter.GaussianBlur(3))
    img = Image.alpha_composite(img.convert("RGBA"), layer).convert("RGB")
    arr = np.asarray(img, np.float32) * vignette(0.4)[..., None]
    return to_img(arr)


def knox():
    """Knox County at sundown: just a sunset over a field (the director, Nov 10 2026: "Just a sunset would be fine with a
    field in the background. Doesn't have to be too much." The first draft's water tower read as a floating object,
    and its fence went with it)"""
    x, y = grids()
    hz = 0.64                                            # the horizon
    sky = ramp(y / hz, [(0.0, (74, 62, 118)), (0.45, (186, 104, 116)), (0.8, (238, 152, 92)), (1.0, (252, 208, 138))])
    # the sun's warm haze, low behind the figure, and a hazy far edge of the field
    sun = glow(0.5, hz, 0.55, 1.6)
    sky = sky * (1 - 0.35 * sun[..., None]) + np.array((255, 226, 168), np.float32) * 0.35 * sun[..., None]
    t = np.clip((y - hz) / (1 - hz), 0, 1)
    field = ramp(t, [(0.0, (176, 140, 96)), (0.12, (128, 120, 72)), (0.5, (92, 98, 52)), (1.0, (62, 72, 38))])
    grass = noise(W, H, octaves=5, base=24, persist=0.5, seed=42)
    field *= (0.88 + 0.24 * grass)[..., None]
    field = field * (1 - 0.25 * sun[..., None]) + np.array((236, 186, 110), np.float32) * 0.25 * sun[..., None]
    # a gentle roll in the horizon, so the field isn't a ruler line
    edge = hz + 0.012 * np.sin(x * 5.0 + 1.3) + 0.006 * np.sin(x * 13.0 + 0.4)
    m = (y >= edge)[..., None]
    col = np.where(m, field, sky)
    img = to_img(col).filter(ImageFilter.GaussianBlur(1.6))
    arr = np.asarray(img, np.float32) * vignette(0.3)[..., None]
    return to_img(arr)


def lasers():
    """picture day: deep blue dark, neon beams fanning from the lower corners, a few sparkles"""
    x, y = grids()
    col = ramp(y, [(0.0, (8, 6, 30)), (0.7, (20, 14, 56)), (1.0, (34, 20, 80))])
    base = to_img(col * (0.85 + 0.3 * glow(0.5, 0.4, 0.7, 1.3)[..., None]))
    beams = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(beams)
    fans = [((0, H), (60, 220, 255), [(-0.3, 0.05), (0.15, -0.05), (0.45, 0.0), (0.8, 0.05)]),
            ((W, H), (255, 70, 210), [(1.3, 0.05), (0.85, -0.05), (0.55, 0.0), (0.2, 0.05)])]
    for (ox, oy), c, ends in fans:
        for ex, ey in ends:
            d.line([ox, oy, ex * W, ey * H], fill=c, width=5)
    glow_l = beams.filter(ImageFilter.GaussianBlur(10))
    core = beams.filter(ImageFilter.GaussianBlur(1.5))
    arr = np.asarray(base, np.float32) + np.asarray(glow_l, np.float32) * 1.6 + np.asarray(core, np.float32) * 0.9
    img = to_img(arr)
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(51)
    for _ in range(26):
        sx = (rng.random() * 0.34 if rng.random() < 0.5 else 0.66 + rng.random() * 0.34) * W
        sy = rng.random() * H * 0.8
        s = 3 + rng.random() * 6
        d.line([sx - s, sy, sx + s, sy], fill=(255, 255, 255), width=1)
        d.line([sx, sy - s, sx, sy + s], fill=(255, 255, 255), width=1)
    return img


def flag():
    """the American flag, draped (the director, Nov 10 2026: "Can you also add one that is the American flag?"): 13
    stripes and 50 stars at the flag's own proportions (the blue field 7/13 of the hoist high and 0.76 of it wide, the
    stars in nine rows of six and five), the height filling the screen and the fly cut at the right; soft folds and a
    little out of focus, as a studio's cloth flag hangs. The blue field sits at the top left, clear of the face."""
    S = 2                                               # (drawn at twice the size, then brought down: clean edges)
    w, h = W * S, H * S
    red, white, blue = (178, 34, 52), (244, 241, 234), (60, 59, 110)
    img = Image.new("RGB", (w, h), white)
    d = ImageDraw.Draw(img)
    for i in range(13):
        if i % 2 == 0:
            d.rectangle([0, round(h * i / 13), w, round(h * (i + 1) / 13) - 1], fill=red)
    cw, ch = round(0.76 * h), round(h * 7 / 13)
    d.rectangle([0, 0, cw, ch], fill=blue)
    # the stars: rows at 0.054 of the hoist, columns at 0.063; a star 0.0616 across
    r_out = 0.0616 * h / 2
    r_in = r_out * 0.382
    for row in range(9):
        for col in range(11):
            if (row % 2 == 0) != (col % 2 == 0):
                continue
            cx, cy = 0.063 * h * (col + 1), 0.054 * h * (row + 1)
            pts = []
            for k in range(10):
                ang = -np.pi / 2 + k * np.pi / 5
                rr = r_out if k % 2 == 0 else r_in
                pts.append((cx + rr * np.cos(ang), cy + rr * np.sin(ang)))
            d.polygon(pts, fill=white)
    # the drape: the cloth shifted by a few slow waves (at twice the size, so the stripes' edges stay smooth once
    # brought down), then lit and shaded along its folds
    arr = np.asarray(img, np.float32)
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    ux, uy = xs / (w - 1), ys / (h - 1)
    dx = S * (6 * np.sin(uy * 9.0 + ux * 3.0) + 3 * np.sin(ux * 17.0 + 1.1))
    dy = S * (5 * np.sin(ux * 7.0 + 0.6) + 2 * np.sin(ux * 19.0 + uy * 4.0))
    sx = np.clip(np.rint(xs + dx), 0, w - 1).astype(int)
    sy = np.clip(np.rint(ys + dy), 0, h - 1).astype(int)
    img = to_img(arr[sy, sx]).resize((W, H), Image.LANCZOS)
    arr = np.asarray(img, np.float32)
    x, y = grids()
    fold = np.sin(x * 11.0 + y * 2.5 + 0.3) * 0.5 + np.sin(x * 23.0 - y * 1.5) * 0.25
    arr = arr * (0.9 + 0.13 * fold)[..., None]
    img = to_img(arr).filter(ImageFilter.GaussianBlur(1.4))
    arr = np.asarray(img, np.float32) * vignette(0.35)[..., None]
    return to_img(arr)


# ---------------------------------------------------------------------------------------------------------------------
# THE PAINTED CANVASES (the director, Nov 11 2026, from three sets of references: classic hand-painted portrait cloths
# and plasters, "a bit pixelated like the other art we have done, but not sooooo heavy"). One engine: a wall of paint
# with a light behind the head and a darker edge, meeting a floor of the same paint at HZ; each canvas picks its
# palette and its textures. ZeD's own paintings in that style; none copies a reference.
# ---------------------------------------------------------------------------------------------------------------------
HZ = 0.80          # where the wall meets the floor (the figure, full body, stands with its feet on the floor below it)


def streaks(seed, axis="h", k=8, octaves=5, base=4):
    """noise smeared along an axis (brush strokes, a floor's grain): drawn small that way, then stretched"""
    if axis == "h":     # (strokes running across: few samples across, many down, stretched across)
        n = noise(max(8, W // k), H, octaves=octaves, base=base, seed=seed)
    else:
        n = noise(W, max(8, H // k), octaves=octaves, base=base, seed=seed)
    return np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC), np.float32) / 255.0


def diag_streaks(seed, angle=30, k=8):
    """brush strokes on a slant"""
    big = int(np.hypot(W, H)) + 4
    n = noise(big, max(8, big // k), octaves=5, base=4, seed=seed)
    img = Image.fromarray((n * 255).astype(np.uint8)).resize((big, big), Image.BICUBIC).rotate(angle, Image.BICUBIC)
    ox, oy = (big - W) // 2, (big - H) // 2
    return np.asarray(img.crop((ox, oy, ox + W, oy + H)), np.float32) / 255.0


def specks(seed, density=0.06, base=90):
    """fine granite: light and dark specks in -1..1"""
    n = noise(W, H, octaves=2, base=base, persist=0.5, seed=seed)
    hi = np.clip((n - (1 - density)) / density, 0, 1)
    lo = np.clip((density - n) / density, 0, 1)
    return hi - lo


def relief(seed, base=10, light=(-0.7, -0.7)):
    """stucco: a height map of ridged noise, lit from the upper left; -1..1"""
    n = noise(W, H, octaves=6, base=base, persist=0.55, seed=seed)
    h = 1 - np.abs(2 * n - 1)
    gy, gx = np.gradient(h)
    s = -(gx * light[0] + gy * light[1]) * 18
    return np.clip(s, -1, 1)


def folds(seed, freq=7.0, slant=0.18):
    """a hanging cloth's folds: near-vertical ridges, wider toward the foot, their phase wandering; sharp crests, soft
    troughs (cloth hangs in rounded valleys and folds over at the ridges)"""
    x, y = grids()
    wander = noise(W, H, octaves=3, base=2, seed=seed)
    ph = ((x - 0.5) / (0.75 + 0.35 * y) + slant * y) * freq + wander * 1.1
    w = 0.5 + 0.5 * np.sin(ph * 2 * np.pi)
    w2 = 0.5 + 0.5 * np.sin(ph * 2 * np.pi * 2.3 + 1.1)
    return (w ** 2.2 * 0.75 + w2 ** 3 * 0.25) * 2 - 0.6


def canvas(wall, floor, glow_at=(0.5, 0.36), glow_r=0.55, glow_k=0.55, vig=0.55, seed=0, tex=None, tint=None):
    """a painted cloth or plaster wall meeting its floor at HZ.
    wall, floor: colour stops for ramp(); tex: {"cloud": w, "speck": w, "brush": w, "vbrush": w, "dbrush": w,
    "relief": w, "flecks": w, "folds": w}; tint: optional (stops, field) laid over the wall (gold to violet)"""
    tex = tex or {}
    x, y = grids()
    n1 = noise(W, H, octaves=7, base=3, persist=0.6, seed=seed + 1)
    n2 = noise(W, H, octaves=5, base=9, persist=0.5, seed=seed + 2)
    t = (0.62 * n1 + 0.38 * n2) * tex.get("cloud", 1.0) + 0.5 * (1 - tex.get("cloud", 1.0))
    if "brush" in tex: t = t + (streaks(seed + 3, "h") - 0.5) * tex["brush"]
    if "vbrush" in tex: t = t + (streaks(seed + 4, "v") - 0.5) * tex["vbrush"]
    if "dbrush" in tex: t = t + (diag_streaks(seed + 5) - 0.5) * tex["dbrush"]
    if "folds" in tex: t = t + folds(seed + 6) * tex["folds"]
    # the light behind the head lifts the cloth's own mottle rather than painting a disc on it (a disc's outline turns
    # into rings when the colours are counted down)
    gl = glow(glow_at[0], glow_at[1], glow_r, 1.25) * (0.75 + 0.5 * n2)
    t = np.clip(t + (gl - 0.35) * glow_k * 0.55, 0, 1)
    col = ramp(t, wall)
    if tint is not None:
        stops, field = tint
        tc = ramp(field, stops)
        col = col * 0.25 + tc * 0.75
    if "relief" in tex: col = col * (1 + 0.28 * tex["relief"] * relief(seed + 7)[..., None])
    if "speck" in tex: col = col * (1 + 0.22 * tex["speck"] * specks(seed + 8)[..., None])
    if "flecks" in tex:
        f = np.clip((noise(W, H, octaves=3, base=40, seed=seed + 9) - 0.78) / 0.12, 0, 1) * tex["flecks"]
        col = col * (1 - f[..., None]) + np.array((236, 232, 222), np.float32) * f[..., None]
    # the floor: the same paint laid flat, its grain running across, lighter toward the viewer, a shadow at the wall
    d = np.clip((y - HZ) / (1 - HZ), 0, 1)
    grain = streaks(seed + 10, "h", k=14, octaves=5, base=5)
    ft = 0.35 + 0.4 * grain + 0.25 * d
    if "folds" in tex: ft = ft + folds(seed + 11, freq=5.0, slant=-0.8) * 0.25 * tex["folds"]
    fcol = ramp(ft, floor)
    fcol *= (0.78 + 0.22 * glow(glow_at[0], HZ + 0.12, 0.5, 2.2) * 1.4)[..., None]
    fcol *= (1 - 0.35 * np.clip(1 - d / 0.12, 0, 1))[..., None]          # (the shadow where it meets the wall)
    if "speck" in tex: fcol = fcol * (1 + 0.15 * tex["speck"] * specks(seed + 12)[..., None])
    # the wall darkens toward its foot, the junction a soft dark line, not a ruler
    col *= (1 - 0.32 * np.clip((y - (HZ - 0.12)) / 0.12, 0, 1))[..., None]
    edge = HZ + 0.006 * np.sin(x * 9.0 + seed) + 0.004 * (n2 - 0.5)
    m = np.clip((y - edge) / 0.008, 0, 1)[..., None]
    out = col * (1 - m) + fcol * m
    out *= vignette(vig)[..., None]
    return to_img(out)


def c_slate():
    return canvas([(0, (20, 21, 24)), (0.45, (48, 50, 54)), (0.75, (84, 86, 90)), (1, (124, 126, 128))],
                  [(0, (34, 35, 38)), (1, (88, 90, 92))], seed=100, glow_k=0.8, tex={"cloud": 0.9, "speck": 1.0})


def c_sage():
    return canvas([(0, (30, 44, 40)), (0.4, (62, 86, 78)), (0.7, (108, 132, 116)), (1, (156, 168, 140))],
                  [(0, (40, 58, 54)), (1, (104, 126, 112))], seed=110, tex={"cloud": 1.0, "brush": 0.12})


def c_tan():
    return canvas([(0, (96, 64, 36)), (0.4, (160, 116, 70)), (0.72, (206, 166, 112)), (1, (236, 206, 158))],
                  [(0, (128, 92, 58)), (1, (218, 180, 128))], seed=120, glow_k=0.7, vig=0.45,
                  tex={"cloud": 0.9, "speck": 0.4, "vbrush": 0.1})


def c_cream():
    return canvas([(0, (70, 44, 40)), (0.4, (168, 128, 106)), (0.75, (226, 198, 164)), (1, (246, 228, 196))],
                  [(0, (150, 116, 94)), (1, (226, 200, 166))], seed=130, glow_k=0.9, glow_r=0.66, vig=0.8,
                  tex={"cloud": 0.7})


def c_spotlight():
    return canvas([(0, (4, 8, 14)), (0.35, (20, 40, 58)), (0.65, (72, 112, 138)), (1, (176, 206, 220))],
                  [(0, (8, 16, 24)), (1, (120, 158, 180))], seed=140, glow_k=1.15, glow_r=0.6, glow_at=(0.5, 0.4), vig=0.9,
                  tex={"cloud": 0.9})


def c_dusk():
    return canvas([(0, (52, 24, 46)), (0.4, (120, 50, 70)), (0.7, (190, 100, 96)), (1, (236, 166, 128))],
                  [(0, (90, 44, 60)), (1, (204, 132, 116))], seed=150, glow_k=0.8,
                  tex={"cloud": 0.8, "brush": 0.3})


def c_drape():
    return canvas([(0, (36, 24, 18)), (0.45, (92, 68, 52)), (0.75, (132, 104, 82)), (1, (166, 136, 110))],
                  [(0, (48, 34, 26)), (1, (130, 102, 80))], seed=160, glow_k=0.35,
                  tex={"cloud": 0.75, "folds": 0.22})


def p_rust():
    return canvas([(0, (44, 22, 12)), (0.4, (110, 52, 22)), (0.7, (164, 92, 44)), (1, (204, 140, 80))],
                  [(0, (64, 32, 16)), (1, (160, 96, 50))], seed=200, glow_k=0.4,
                  tex={"cloud": 0.9, "speck": 1.2, "relief": 0.5})


def p_stucco():
    return canvas([(0, (12, 11, 10)), (0.45, (36, 34, 31)), (0.75, (64, 60, 54)), (1, (96, 90, 80))],
                  [(0, (20, 19, 18)), (1, (70, 66, 60))], seed=210, glow_k=0.3,
                  tex={"cloud": 0.7, "relief": 1.6})


def p_orange():
    return canvas([(0, (60, 26, 8)), (0.4, (126, 58, 16)), (0.72, (174, 92, 30)), (1, (210, 136, 60))],
                  [(0, (84, 38, 12)), (1, (176, 100, 40))], seed=220, glow_k=0.5,
                  tex={"cloud": 0.8, "brush": 0.18})


def p_lavender():
    return canvas([(0, (78, 62, 96)), (0.4, (138, 118, 152)), (0.72, (190, 172, 196)), (1, (232, 218, 220))],
                  [(0, (100, 84, 116)), (1, (196, 180, 196))], seed=230, glow_k=0.7,
                  tex={"cloud": 1.0})


def p_goldviolet():
    x, y = grids()
    n = noise(W, H, octaves=6, base=3, persist=0.6, seed=241)
    field = np.clip(1.05 - 0.85 * x - 0.45 * y + (n - 0.5) * 0.6, 0, 1)
    tint = ([(0, (52, 34, 92)), (0.35, (112, 70, 128)), (0.6, (186, 120, 104)), (0.82, (226, 172, 86)),
             (1, (246, 214, 132))], field)
    return canvas([(0, (90, 70, 80)), (0.5, (180, 150, 120)), (1, (240, 220, 170))],
                  [(0, (110, 86, 96)), (1, (210, 180, 130))], seed=240, glow_k=0.4, glow_at=(0.38, 0.3),
                  tex={"cloud": 0.6, "dbrush": 0.35}, tint=tint)


def planks(img, hz=HZ, base=((120, 84, 52), (150, 108, 70), (100, 70, 44)), seed=0, light=1.0):
    """a plank floor in perspective from HZ down, its seams running to a vanishing point over the middle"""
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(seed)
    top = int(hz * H)
    vx, vy = W * 0.5, top - H * 0.9
    n = 22
    xs = [W * 0.5 + (i - n / 2) * (W * 2.4 / n) for i in range(n + 1)]
    for i in range(n):
        c = np.array(base[rng.integers(len(base))], np.float32) * (0.85 + 0.3 * rng.random()) * light
        x0b, x1b = xs[i], xs[i + 1]
        t0 = (top - vy) / (H - vy)
        x0t, x1t = vx + (x0b - vx) * t0, vx + (x1b - vx) * t0
        d.polygon([(x0t, top), (x1t, top), (x1b, H), (x0b, H)], fill=tuple(int(v) for v in c))
        d.line([(x0t, top), (x0b, H)], fill=(40, 28, 18), width=2)
    arr = np.asarray(img, np.float32)
    x, y = grids()
    m = (y >= hz)
    grain = streaks(seed + 1, "v", k=10, octaves=4, base=8)
    dd = np.clip((y - hz) / (1 - hz), 0, 1)
    shade = (0.82 + 0.18 * grain) * (0.75 + 0.25 * dd) * (1 - 0.4 * np.clip(1 - dd / 0.1, 0, 1))
    arr[m] = arr[m] * shade[m][:, None]
    return to_img(arr)


def s_brick():
    """brick and boards: a brick wall, a pool of light on it from above, a plank floor"""
    x, y = grids()
    img = Image.new("RGB", (W, H), (60, 40, 32))
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(300)
    bh = int(H * 0.046)
    bw = int(bh * 2.3)
    mort = max(2, bh // 7)
    reds = [(150, 62, 44), (134, 54, 38), (168, 78, 50), (122, 60, 46), (176, 92, 60), (110, 46, 34), (140, 100, 84)]
    top = int(HZ * H)
    row = 0
    yy = 0
    while yy < top:
        off = (bw // 2) if row % 2 else 0
        xx = -off
        while xx < W:
            c = np.array(reds[rng.integers(len(reds))], np.float32) * (0.82 + 0.3 * rng.random())
            d.rectangle([xx + mort, yy + mort, xx + bw - 1, min(top, yy + bh) - 1], fill=tuple(int(v) for v in c))
            xx += bw
        yy += bh
        row += 1
    arr = np.asarray(img, np.float32)
    tex = noise(W, H, octaves=5, base=40, seed=301)
    arr *= (0.86 + 0.28 * tex)[..., None]
    arr *= (0.55 + 0.75 * glow(0.5, 0.18, 0.75, 1.0))[..., None]
    img = to_img(arr)
    img = planks(img, base=((96, 70, 48), (118, 86, 58), (84, 60, 40)), seed=302)
    arr = np.asarray(img, np.float32) * vignette(0.55)[..., None]
    return to_img(arr)


def s_plaster():
    """old plaster and boards: a warm weathered plaster wall, a dark baseboard, a plank floor"""
    img = canvas([(0, (74, 50, 30)), (0.4, (140, 100, 64)), (0.72, (196, 156, 108)), (1, (230, 200, 156))],
                 [(0, (90, 62, 40)), (1, (150, 110, 74))], seed=310, glow_k=0.7, vig=0.5,
                 tex={"cloud": 0.9, "relief": 0.7, "vbrush": 0.15})
    img = planks(img, base=((128, 92, 60), (150, 110, 74), (112, 80, 52)), seed=311, light=1.05)
    d = ImageDraw.Draw(img)
    top = int(HZ * H)
    d.rectangle([0, top - int(H * 0.028), W, top], fill=(54, 36, 24))
    d.line([0, top - int(H * 0.028), W, top - int(H * 0.028)], fill=(96, 70, 48), width=2)
    return img


# ---------------------------------------------------------------------------------------------------------------------
# THE PIXEL PASS ("a bit pixelated like the other art we have done, but not sooooo heavy"): each painting brought down
# to a 480 x 270 grid of art pixels in about 40 colours, no dithering; the game's texture doubles each art pixel
# (960 x 540, sharp under the game's filtering); the director's copies are exact four-times pixel art (1920 x 1080).
# ---------------------------------------------------------------------------------------------------------------------
ART_W, ART_H, COLORS = 480, 270, 96      # (the main menu's desk: the same grid, some 260 colours, no dithering)


def pixelate(img, seed=7):
    """the grid, the counted colours, no dithering; a whisper of noise first, so a step between two colours wanders
    the way a painted edge does rather than following a gradient's contour"""
    small = np.asarray(img.resize((ART_W, ART_H), Image.BOX), np.float32)
    small += np.random.default_rng(seed).normal(0, 2.2, small.shape[:2])[..., None]
    small = Image.fromarray(np.clip(small, 0, 255).astype(np.uint8))
    return small.quantize(colors=COLORS, method=Image.Quantize.MEDIANCUT, kmeans=3,
                          dither=Image.Dither.NONE).convert("RGB")


# the set, in the tray's order after the grey (drawn by the studio): the canvases, the plasters, the two sets, the
# three kept from the first drafts (Mottled blue, Sky and Autumn went: the canvases cover that ground; the director,
# Nov 11 2026, "go ahead with those")
BACKDROPS = [("slate", c_slate), ("sage", c_sage), ("tan", c_tan), ("cream", c_cream), ("spotlight", c_spotlight),
             ("dusk", c_dusk), ("drape", c_drape), ("rust", p_rust), ("stucco", p_stucco), ("orange", p_orange),
             ("lavender", p_lavender), ("goldviolet", p_goldviolet), ("brick", s_brick), ("plaster", s_plaster),
             ("knox", knox), ("lasers", lasers), ("flag", flag)]


def safe_area():
    """the guide at 1920 x 1080: the figure's zone, the heads of the three framings, the bar"""
    g = Image.new("RGBA", (1920, 1080), (0, 0, 0, 0))
    d = ImageDraw.Draw(g)
    # the figure's element at 1x (ZeD_Studio layout: bar 44, gaps 16, the figure 97% of the paper's height, 0.6 wide)
    bar, m = 44, 16
    bh = 1080 - bar - m * 2
    fh = int(bh * 0.97)
    fw = int(fh * 0.6)
    fx, fy = (1920 - fw) // 2, m + bh - fh
    d.rectangle([fx, fy, fx + fw, fy + fh], outline=(255, 60, 60, 255), width=4)
    d.rectangle([fx, fy, fx + fw, fy + fh], fill=(255, 60, 60, 36))
    d.text((fx + 10, fy + 10), "FIGURE (full body)", fill=(255, 255, 255, 255))
    # the head in full body sits near the element's top; the busier art stays out of this band behind it
    d.rectangle([fx + fw // 4, fy, fx + 3 * fw // 4, fy + fh // 7], outline=(255, 220, 60, 255), width=3)
    d.text((fx + fw // 4 + 8, fy + 8), "HEAD", fill=(255, 220, 60, 255))
    d.rectangle([0, 1080 - bar, 1920, 1080], fill=(60, 120, 255, 90))
    d.text((12, 1080 - bar + 14), "BAR while setting up (not in the photo)", fill=(255, 255, 255, 255))
    return g


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(ART, exist_ok=True)
    thumbs = []
    for bid, fn in BACKDROPS:
        art = pixelate(fn())
        art.resize((ART_W * 2, ART_H * 2), Image.NEAREST).save(os.path.join(OUT, "backdrop_%s.png" % bid), optimize=True)
        art.resize((ART_W * 4, ART_H * 4), Image.NEAREST).save(os.path.join(ART, "%s_1920.png" % bid), optimize=True)
        thumbs.append((bid, art.resize((W, H), Image.NEAREST)))
        print("backdrop", bid)
    # (the drafts no longer in the set)
    for gone in ("mottled", "sky", "autumn"):
        for path in (os.path.join(OUT, "backdrop_%s.png" % gone), os.path.join(ART, "%s_1920.png" % gone)):
            if os.path.exists(path): os.remove(path)
    safe_area().save(os.path.join(ART, "safe_area_1920.png"))
    # the contact sheet: two across, each with the guide over it
    tw, th = 480, 270
    cols = 3
    rows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new("RGB", (tw * cols + 10 * (cols + 1), (th + 30) * rows + 10), (24, 24, 28))
    d = ImageDraw.Draw(sheet)
    guide = safe_area().resize((tw, th))
    for i, (bid, img) in enumerate(thumbs):
        x, y = 10 + (i % cols) * (tw + 10), 10 + (i // cols) * (th + 30)
        t = img.resize((tw, th), Image.NEAREST).convert("RGBA")
        t = Image.alpha_composite(t, guide)
        sheet.paste(t.convert("RGB"), (x, y))
        d.text((x, y + th + 6), bid, fill=(230, 230, 230))
    sheet.save(os.path.join(ART, "contact_sheet.png"))
    print("contact sheet and guide in", ART)


if __name__ == "__main__":
    main()
