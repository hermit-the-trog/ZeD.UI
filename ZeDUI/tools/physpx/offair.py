"""The TVs' off-air screens (director, Oct 30 2026: test cards and sign-off cards, "off air screens?"), drawn at any
screen size in plate pixels so they stay crisp at the plates' whole zoom:

  bars            the broadcast colour bars (seven bars, the reversed strip, the bottom row with the white block):
                  a channel with nothing on
  signoff_<id>    one sign-off card per channel in the game's broadcast data (media/radio/RadioData.xml): the channel's
                  own logo (designed here, after the early-80s station cards the director sent; no real station's
                  marks), its channel number and the county line
  standby         PLEASE STAND BY (technical difficulties)
  snow_0..2       three frames of static: between channels, no signal

Every screen goes through crt(): the tube's curve, darker corners, scanlines, a pixel of colour bleed, a little bloom.
usage: python offair.py out_dir W H        (writes every screen at W x H, and a contact sheet)
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "dashpx"))
from engine import FONTS          # noqa: E402  (the plates' two pixel fonts, 3x5 and 5x7)

# the game's ten TV channels (RadioData.xml, cat="Television"), in frequency order; the number is the channel the set
# shows (the antique set's dial prints 2-13: these are its stops 2-11)
CHANNELS = [("triple_n", "Triple-N", 2), ("wbln", "WBLN News", 3), ("life", "Life and Living TV", 4), ("turbo", "TURBO", 5),
            ("paws", "PawsTV", 6), ("kpa", "KPATV", 7), ("mvc", "Music Video Channel", 8), ("nst", "National Sports TV", 9),
            ("bmc", "Brennan Movie Channel", 10), ("gbc", "GBC", 11)]
COUNTY = "KNOX COUNTRY, KENTUCKY"

# the channels the game already has a logo for (director, Oct 30 2026: "There should be real logos for some of tv and
# radio in the game art"): the card draws the game's own picture, at runtime, from the game's files (nothing copied
# into the mod). LOGO_BOX is where it goes on the card, as fractions of the screen (x, y, w, h); the picture is fitted
# inside, keeping its shape. Triple-N's is its "3N News Now Network" (also on its van and its billboard).
GAME_LOGOS = {"triple_n": "media/textures/printMedia/logos/ENewsNowNetwork.png",
              "turbo": "media/textures/printMedia/logos/TurboTV.png"}
LOGO_BOX = {"triple_n": (0.10, 0.16, 0.80, 0.44), "turbo": (0.10, 0.20, 0.80, 0.34)}
GAME_ROOT = None          # where the game's media/ lives, to draw the logo into review pictures (None: leave the box empty)


# ------------------------------------------------------------------ drawing helpers (on numpy RGB float arrays 0..1)
def blank(w, h, rgb=(0, 0, 0)):
    a = np.zeros((h, w, 3), np.float32); a[:] = np.array(rgb, np.float32) / 255.0; return a


def hexc(c):
    c = c.lstrip("#"); return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))


def glyph_mask(t, font="57", scale=1, gap=1):
    f = FONTS[font]
    rows = len(f["A"])
    cols = []
    for ch in t:
        g = f.get(ch, f.get(ch.upper(), f[" "]))
        cols.append(g)
    w = sum(len(g[0]) + gap for g in cols) - gap
    m = np.zeros((rows, max(1, w)), bool)
    x = 0
    for g in cols:
        for yy, r in enumerate(g):
            for xx, c in enumerate(r):
                if c == "1": m[yy, x + xx] = True
        x += len(g[0]) + gap
    if scale > 1: m = np.kron(m, np.ones((scale, scale), bool))
    return m


def put(a, m, x, y, fill):
    """paint mask m at (x, y) with fill: an RGB tuple, or a function (yy fraction 0..1) -> RGB for a gradient"""
    H, W = a.shape[:2]
    h, w = m.shape
    x0, y0 = max(0, x), max(0, y); x1, y1 = min(W, x + w), min(H, y + h)
    if x1 <= x0 or y1 <= y0: return
    sub = m[y0 - y:y1 - y, x0 - x:x1 - x]
    if callable(fill):
        for yy in range(y0, y1):
            row = sub[yy - y0]
            if row.any(): a[yy, x0:x1][row] = np.array(fill((yy - y) / max(1, h - 1)), np.float32) / 255.0
    else:
        a[y0:y1, x0:x1][sub] = np.array(fill, np.float32) / 255.0


def grow(m, n=1):
    out = m.copy()
    for _ in range(n):
        p = np.pad(out, 1)
        out = p[1:-1, 1:-1] | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    return out


def pad_to(m, n):
    return np.pad(m, n)


def text(a, t, cx, y, scale=1, fill=(255, 255, 255), font="57", outline=None, shadow=None, align="c", gap=1, glow=None):
    m = glyph_mask(t, font, scale, gap)
    x = cx - m.shape[1] // 2 if align == "c" else (cx if align == "l" else cx - m.shape[1])
    if glow: add_glow(a, m, x, y, glow, radius=max(2, scale * 2))
    if shadow:
        put(a, m, x + max(1, scale // 2), y + max(1, scale // 2), shadow)
    if outline:
        o = grow(pad_to(m, 1), 1)
        put(a, o, x - 1, y - 1, outline)
    put(a, m, x, y, fill)
    return x, m.shape[1], m.shape[0]


def add_glow(a, m, x, y, rgb, radius=3, amount=0.6):
    H, W = a.shape[:2]
    canvas = Image.new("L", (W, H), 0)
    mm = Image.fromarray((m * 255).astype(np.uint8))
    canvas.paste(mm, (x, y))
    g = np.asarray(canvas.filter(ImageFilter.GaussianBlur(radius)), np.float32) / 255.0
    a += g[..., None] * (np.array(rgb, np.float32) / 255.0) * amount
    np.clip(a, 0, 1, out=a)


def chrome(top=(255, 255, 255), mid=(150, 160, 190), low=(60, 60, 90), lip=(255, 250, 220)):
    """an 80s chrome fill: bright sky, a hard horizon, a dark ground and a light lip at the bottom"""
    def f(t):
        if t < 0.48: k = t / 0.48; return tuple(int(top[i] + (mid[i] - top[i]) * k) for i in range(3))
        if t < 0.52: return low
        if t > 0.9: return lip
        k = (t - 0.52) / 0.38; return tuple(int(low[i] + (mid[i] - low[i]) * k * 0.8) for i in range(3))
    return f


def vgrad(c0, c1):
    return lambda t: tuple(int(c0[i] + (c1[i] - c0[i]) * t) for i in range(3))


def disc_mask(r):
    yy, xx = np.mgrid[-r:r + 1, -r:r + 1]; return (xx * xx + yy * yy) <= r * r


def ring_mask(r, t):
    yy, xx = np.mgrid[-r:r + 1, -r:r + 1]; d = np.sqrt(xx * xx + yy * yy); return (d <= r + 0.3) & (d >= r - t + 0.3)


def glint(a, cx, cy, n=4, rgb=(255, 255, 255)):
    """a four-point star glint"""
    for k in range(-n, n + 1):
        f = 1.0 - abs(k) / (n + 1)
        for (x, y) in ((cx + k, cy), (cx, cy + k)):
            if 0 <= x < a.shape[1] and 0 <= y < a.shape[0]:
                a[y, x] = np.maximum(a[y, x], np.array(rgb, np.float32) / 255 * f)
    for (dx, dy) in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        x, y = cx + dx, cy + dy
        if 0 <= x < a.shape[1] and 0 <= y < a.shape[0]: a[y, x] = np.maximum(a[y, x], np.array(rgb, np.float32) / 255 * 0.6)


def rect(a, x, y, w, h, rgb):
    H, W = a.shape[:2]
    x0, y0, x1, y1 = max(0, x), max(0, y), min(W, x + w), min(H, y + h)
    if x1 > x0 and y1 > y0: a[y0:y1, x0:x1] = np.array(rgb, np.float32) / 255.0


def big_scale(w, h, base=4):
    """the logo's pixel scale for a screen: 4 at about 360 wide, 3 at 270, 2 below"""
    return max(2, min(6, int(round(min(w / 72.0, h / 50.0)))))


# ------------------------------------------------------------------ the screens
def bars(w, h):
    """SMPTE colour bars: seven bars (two thirds), the reversed castellations, the bottom row"""
    a = blank(w, h)
    top = [(192, 192, 192), (192, 192, 0), (0, 192, 192), (0, 192, 0), (192, 0, 192), (192, 0, 0), (0, 0, 192)]
    mid = [(0, 0, 192), (19, 19, 19), (192, 0, 192), (19, 19, 19), (0, 192, 192), (19, 19, 19), (192, 192, 192)]
    y1, y2 = int(h * 0.67), int(h * 0.75)
    xs = [int(round(i * w / 7)) for i in range(8)]
    for i in range(7):
        rect(a, xs[i], 0, xs[i + 1] - xs[i], y1, top[i]); rect(a, xs[i], y1, xs[i + 1] - xs[i], y2 - y1, mid[i])
    # the bottom row: -I, white, +Q, black, then the three blacks of the brightness check
    b = int(round(w * 5 / 28))
    row = [((0, 33, 76), b), ((255, 255, 255), b), ((50, 0, 106), b), ((19, 19, 19), xs[5] - 3 * b)]
    x = 0
    for c, ww in row:
        rect(a, x, y2, ww, h - y2, c); x += ww
    t3 = (xs[6] - xs[5]) // 3
    for k, c in enumerate(((9, 9, 9), (19, 19, 19), (29, 29, 29))):
        rect(a, xs[5] + k * t3, y2, t3 if k < 2 else xs[6] - xs[5] - 2 * t3, h - y2, c)
    rect(a, xs[6], y2, w - xs[6], h - y2, (19, 19, 19))
    return a


def standby(w, h):
    a = blank(w, h, (12, 20, 70))
    for y in range(h):                                   # a deep blue field, lighter toward the middle
        k = 1 - abs(y / h - 0.5) * 1.2
        a[y] = np.array((12 + 30 * k, 20 + 40 * k, 70 + 70 * k), np.float32) / 255
    s = big_scale(w, h)
    text(a, "PLEASE", w // 2, int(h * 0.26), s, chrome(), outline=(10, 10, 40), shadow=(0, 0, 20), glow=(120, 160, 255))
    text(a, "STAND BY", w // 2, int(h * 0.26) + 7 * s + 2 * s, s, chrome(), outline=(10, 10, 40), shadow=(0, 0, 20), glow=(120, 160, 255))
    text(a, "WE ARE EXPERIENCING", w // 2, int(h * 0.70), max(1, s // 2), (230, 230, 240), font="57")
    text(a, "TECHNICAL DIFFICULTIES", w // 2, int(h * 0.70) + 9 * max(1, s // 2), max(1, s // 2), (230, 230, 240), font="57")
    return a


def snow(w, h, seed=0):
    rng = np.random.default_rng(seed)
    v = rng.random((h, w)).astype(np.float32)
    v = v ** 1.6
    # horizontal streaks: some rows brighter or darker, as a tuner hunting
    rows = rng.normal(0, 0.12, (h, 1)).astype(np.float32)
    v = np.clip(v + rows, 0, 1)
    a = np.repeat(v[..., None], 3, axis=2)
    a[..., 2] *= 1.04
    return np.clip(a, 0, 1)


def card_frame(w, h, top, bottom):
    a = blank(w, h)
    for y in range(h):
        k = y / max(1, h - 1)
        a[y] = np.array([top[i] + (bottom[i] - top[i]) * k for i in range(3)], np.float32) / 255
    return a


def footer(a, w, h, ch, s, col=(240, 240, 230)):
    ss = max(1, s // 2)
    text(a, f"CHANNEL {ch}", w // 2, int(h * 0.78), ss, col, outline=(0, 0, 0))
    text(a, COUNTY, w // 2, int(h * 0.78) + 8 * ss + 3, 1, col, font="57", outline=(0, 0, 0))


def signoff(cid, w, h):
    s = big_scale(w, h)
    name, ch = {c[0]: (c[1], c[2]) for c in CHANNELS}[cid]
    cx, cy = w // 2, int(h * 0.42)
    if cid == "triple_n":
        a = card_frame(w, h, (196, 200, 210), (120, 126, 140))       # a light studio grey: the logo is drawn for paper
        game_logo(a, cid)
    elif cid == "wbln":
        a = card_frame(w, h, (30, 10, 10), (6, 2, 2))
        r = int(10 * s)
        put(a, ring_mask(r, max(2, s)), cx - r, cy - r, (220, 220, 230))                 # a globe: its ring and meridians
        for k in (-0.5, 0, 0.5):
            m = np.zeros((2 * r + 1, 2 * r + 1), bool)
            yy, xx = np.mgrid[-r:r + 1, -r:r + 1]
            m |= (np.abs(xx - k * np.sqrt(np.clip(r * r - yy * yy, 0, None))) < 0.8) & (xx * xx + yy * yy <= r * r)
            put(a, m, cx - r, cy - r, (140, 150, 170))
        rect(a, cx - r, cy - 1, 2 * r, 2, (140, 150, 170))
        text(a, "WBLN", cx, cy - 4 * s, s, chrome(), outline=(40, 0, 0), shadow=(0, 0, 0))
        rect(a, cx - 14 * s, cy + r + s, 28 * s, 8 * max(1, s // 2) + 4, (200, 30, 30))
        text(a, "NEWS", cx, cy + r + s + 2, max(1, s // 2), (255, 255, 255))
    elif cid == "life":
        a = card_frame(w, h, (250, 200, 170), (200, 120, 150))
        r = int(7 * s)
        put(a, disc_mask(r), cx - r, cy - 3 * s - r, (255, 210, 80))                      # a rising sun with its rays
        for k in range(9):
            ang = math.pi + k * math.pi / 8
            for t in range(r + s, r + 4 * s):
                x = int(cx + math.cos(ang) * t); y = int(cy - 3 * s + math.sin(ang) * t)
                if 0 <= x < w and 0 <= y < h: a[y, x] = np.array((255, 230, 120), np.float32) / 255
        rect(a, cx - 18 * s, cy - 3 * s, 36 * s, 3 * s, (250, 200, 170))
        text(a, "LIFE & LIVING", cx, cy + s, max(1, s - 1), (120, 30, 70), outline=(255, 240, 230))
        text(a, "TV", cx, cy + s + 9 * max(1, s - 1), max(1, s - 1), (120, 30, 70), outline=(255, 240, 230))
    elif cid == "turbo":
        a = card_frame(w, h, (10, 0, 30), (60, 0, 80))
        hy = int(h * 0.62)                                                                 # the neon grid to the horizon
        for k in range(1, 9):
            y = hy + int((h - hy) * (k / 8) ** 1.8)
            rect(a, 0, y, w, 1, (255, 40, 200))
        for k in range(-10, 11):
            x0 = cx + k * (w // 10)
            for y in range(hy, h):
                t = (y - hy) / max(1, h - hy)
                x = int(cx + (x0 - cx) * (0.2 + 0.8 * t))
                if 0 <= x < w: a[y, x] = np.array((255, 40, 200), np.float32) / 255
        rect(a, 0, hy, w, 1, (120, 220, 255))
        game_logo(a, cid)
    elif cid == "paws":
        a = card_frame(w, h, (40, 120, 70), (10, 50, 30))
        r = int(5 * s)
        put(a, disc_mask(r), cx - r, cy - r + s, (250, 240, 220))                          # the pad and four toes
        for (dx, dy) in ((-1.2, -1.1), (-0.4, -1.6), (0.4, -1.6), (1.2, -1.1)):
            rr = max(2, int(r * 0.42))
            put(a, disc_mask(rr), int(cx + dx * r) - rr, int(cy + dy * r) - rr + s, (250, 240, 220))
        text(a, "PAWS TV", cx, cy + r + 3 * s, max(1, s - 1), (255, 220, 90), outline=(20, 40, 20), shadow=(0, 20, 0))
    elif cid == "kpa":
        a = card_frame(w, h, (6, 6, 10), (0, 0, 0))
        r = int(11 * s)                                                                     # the big ring numeral
        rx = cx + 12 * s
        put(a, ring_mask(r, 2 * s), rx - r, cy - r, (230, 50, 40))
        text(a, str(ch), rx, cy - 7 * s, 2 * s, (230, 50, 40))
        text(a, "KPA", cx - 10 * s, cy - 5 * s, s + 1, vgrad((120, 255, 200), (40, 160, 120)), outline=(0, 30, 20), glow=(80, 255, 180))
        text(a, "TV", cx - 10 * s, cy + 4 * s, max(1, s - 1), (255, 230, 80), outline=(40, 30, 0))
    elif cid == "mvc":
        a = card_frame(w, h, (20, 0, 50), (0, 0, 20))
        rng = np.random.default_rng(7)
        for _ in range(int(w * h / 900)):
            glint(a, int(rng.integers(0, w)), int(rng.integers(0, int(h * 0.7))), n=int(rng.integers(1, 3)), rgb=(200, 200, 255))
        text(a, "MVC", cx, cy - 5 * s, s + 1, vgrad((255, 240, 120), (255, 80, 200)), outline=(30, 0, 40), glow=(255, 80, 220))
        text(a, "MUSIC VIDEO CHANNEL", cx, cy + 5 * s, max(1, s // 2), (120, 230, 255), outline=(0, 0, 30))
        glint(a, cx + 9 * s, cy - 6 * s, n=2 + s); glint(a, cx - 10 * s, cy + s, n=1 + s)
    elif cid == "nst":
        a = card_frame(w, h, (14, 30, 90), (4, 10, 40))
        for k in range(5):                                                                  # the stripes behind
            rect(a, 0, int(h * 0.30) + k * 3 * s, w, s, (200, 30, 40) if k % 2 == 0 else (240, 240, 240))
        star = np.zeros((9 * s, 9 * s), bool)
        pts = []
        for k in range(10):
            ang = -math.pi / 2 + k * math.pi / 5; rr = (4.4 if k % 2 == 0 else 1.8) * s
            pts.append((4.5 * s + math.cos(ang) * rr, 4.5 * s + math.sin(ang) * rr))
        im = Image.new("L", (9 * s, 9 * s), 0); ImageDraw.Draw(im).polygon(pts, fill=255); star = np.asarray(im) > 127
        put(a, grow(pad_to(star, 1), 1), cx - 22 * s - 1, cy - 6 * s - 1, (10, 20, 80))
        put(a, star, cx - 22 * s, cy - 6 * s, (255, 255, 255))
        text(a, "NST", cx + 4 * s, cy - 5 * s, s + 1, chrome(), outline=(0, 0, 40), shadow=(0, 0, 0))
        text(a, "NATIONAL SPORTS TV", cx, cy + 6 * s, max(1, s // 2), (255, 255, 255), outline=(0, 0, 40))
    elif cid == "bmc":
        a = card_frame(w, h, (30, 20, 10), (0, 0, 0))
        for side in (-1, 1):                                                                # two searchlights crossing
            bx0 = cx - side * int(w * 0.42); by0 = h
            for t in np.linspace(0, 1, 400):
                x = bx0 + (cx + side * 18 * s - bx0) * t * 1.3; y = by0 + (-by0 * 0.95) * t
                half = 1 + int(t * 6 * s)
                for dx in range(-half, half + 1):
                    xi, yi = int(x + dx), int(y)
                    if 0 <= xi < w and 0 <= yi < h:
                        k = (1 - abs(dx) / (half + 1)) * 0.35
                        a[yi, xi] = np.maximum(a[yi, xi], np.array((255, 230, 170), np.float32) / 255 * k)
        rect(a, cx - 20 * s, cy - 2 * s, 40 * s, 12 * s, (20, 20, 20))                      # a film strip under the name
        for k in range(-9, 10):
            rect(a, cx + k * 2 * s, cy - s, s, s, (200, 190, 160)); rect(a, cx + k * 2 * s, cy + 8 * s, s, s, (200, 190, 160))
        text(a, "BMC", cx, cy, s + 1, chrome((255, 245, 200), (220, 170, 60), (90, 50, 10), (255, 230, 150)), outline=(30, 15, 0))
        text(a, "BRENNAN MOVIE CHANNEL", cx, cy + 12 * s, max(1, s // 2), (240, 210, 140), outline=(0, 0, 0))
    elif cid == "gbc":
        a = card_frame(w, h, (60, 60, 64), (20, 20, 24))
        bw, bh = 30 * s, 14 * s
        m = np.zeros((bh, bw), bool); m[:] = True
        m[0, 0] = m[0, -1] = m[-1, 0] = m[-1, -1] = False
        put(a, grow(pad_to(m, 1), 1), cx - bw // 2 - 1, cy - bh // 2 - 1, (240, 240, 240))
        put(a, m, cx - bw // 2, cy - bh // 2, (30, 90, 170))
        text(a, "GBC", cx, cy - 7 * s // 2 - 1, s, (255, 255, 255))
        text(a, "PUBLIC TELEVISION", cx, cy + bh // 2 + 2 * s, max(1, s // 2), (230, 230, 230))
    footer(a, w, h, ch, s)
    return a


def game_logo(a, cid):
    """the game's own logo fitted in its box (review pictures only; in the game Code draws the texture there)"""
    if not GAME_ROOT: return
    from PIL import Image as _I
    h, w = a.shape[:2]
    fx, fy, fw, fh = LOGO_BOX[cid]
    bx, by, bw, bh = int(fx * w), int(fy * h), int(fw * w), int(fh * h)
    lg = _I.open(os.path.join(GAME_ROOT, GAME_LOGOS[cid])).convert("RGBA")
    k = min(bw / lg.width, bh / lg.height)
    lg = lg.resize((max(1, int(lg.width * k)), max(1, int(lg.height * k))), _I.LANCZOS)
    x0, y0 = bx + (bw - lg.width) // 2, by + (bh - lg.height) // 2
    rgb = np.asarray(lg, np.float32) / 255
    al = rgb[..., 3:4]
    reg = a[y0:y0 + lg.height, x0:x0 + lg.width]
    reg[:] = reg * (1 - al) + rgb[..., :3] * al


def screens():
    out = [("bars", bars), ("standby", standby)]
    for cid, _, _ in CHANNELS: out.append((f"signoff_{cid}", (lambda c: (lambda w, h: signoff(c, w, h)))(cid)))
    for k in range(3): out.append((f"snow_{k}", (lambda kk: (lambda w, h: snow(w, h, kk)))(k)))
    return out


# ------------------------------------------------------------------ the tube
def crt(a, curve=0.0, vignette=0.65, scan=0.16, bleed=True, bloom=0.25):
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    nx, ny = (xx + 0.5) / w * 2 - 1, (yy + 0.5) / h * 2 - 1
    r2 = nx * nx + ny * ny
    sx, sy = nx * (1 + curve * r2), ny * (1 + curve * r2)                  # barrel (off by default: it would eat pixel columns)
    px_ = np.clip(((sx + 1) / 2 * w).astype(int), 0, w - 1)
    py_ = np.clip(((sy + 1) / 2 * h).astype(int), 0, h - 1)
    out = a[py_, px_]
    outside = (np.abs(sx) > 1) | (np.abs(sy) > 1)
    out[outside] = 0
    if bloom:
        im = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8))
        bl = np.asarray(im.filter(ImageFilter.GaussianBlur(1.6)), np.float32) / 255
        out = np.clip(out + bl * bloom * (bl > 0.5), 0, 1)
    if bleed:                                                               # a pixel of colour bleed
        out[:, 1:, 0] = 0.7 * out[:, 1:, 0] + 0.3 * out[:, :-1, 0]
        out[:, :-1, 2] = 0.7 * out[:, :-1, 2] + 0.3 * out[:, 1:, 2]
    out[1::2] *= (1 - scan)                                                  # scanlines
    v = 1 - vignette * np.clip(r2 - 0.25, 0, None) ** 1.2                    # darker corners
    out *= v[..., None]
    return np.clip(out, 0, 1)


def to_img(a): return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


def render_all(w, h, tube=True):
    return {name: to_img(crt(fn(w, h)) if tube else fn(w, h)) for name, fn in screens()}


if __name__ == "__main__":
    out, W, H = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    os.makedirs(out, exist_ok=True)
    ims = render_all(W, H)
    for n, im in ims.items(): im.save(os.path.join(out, f"{n}.png"))
    cols = 5; k = 2
    names = list(ims)
    rows_ = (len(names) + cols - 1) // cols
    S = Image.new("RGB", (cols * (W * k + 12) + 12, rows_ * (H * k + 12) + 12), (24, 24, 26))
    for i, n in enumerate(names):
        S.paste(ims[n].resize((W * k, H * k), Image.NEAREST), (12 + (i % cols) * (W * k + 12), 12 + (i // cols) * (H * k + 12)))
    S.save(os.path.join(out, "_sheet.png")); print("wrote", len(ims), "screens and _sheet.png")
