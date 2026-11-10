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


BACKDROPS = [("mottled", mottled_blue), ("sky", sky), ("autumn", autumn), ("knox", knox), ("lasers", lasers), ("flag", flag)]


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
        img = fn()
        img.save(os.path.join(OUT, "backdrop_%s.png" % bid), optimize=True)
        img.resize((1920, 1080), Image.BICUBIC).save(os.path.join(ART, "%s_1920.png" % bid), optimize=True)
        thumbs.append((bid, img))
        print("backdrop", bid)
    safe_area().save(os.path.join(ART, "safe_area_1920.png"))
    # the contact sheet: two across, each with the guide over it
    tw, th = 640, 360
    rows = (len(thumbs) + 1) // 2
    sheet = Image.new("RGB", (tw * 2 + 30, (th + 34) * rows + 10), (24, 24, 28))
    d = ImageDraw.Draw(sheet)
    guide = safe_area().resize((tw, th))
    for i, (bid, img) in enumerate(thumbs):
        x, y = 10 + (i % 2) * (tw + 10), 10 + (i // 2) * (th + 34)
        t = img.resize((tw, th)).convert("RGBA")
        t = Image.alpha_composite(t, guide)
        sheet.paste(t.convert("RGB"), (x, y))
        d.text((x, y + th + 8), bid, fill=(230, 230, 230))
    sheet.save(os.path.join(ART, "contact_sheet.png"))
    print("contact sheet and guide in", ART)


if __name__ == "__main__":
    main()
