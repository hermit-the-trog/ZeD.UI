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
LOGO_BOX = {"triple_n": (0.12, 0.24, 0.76, 0.32), "turbo": (0.08, 0.25, 0.84, 0.32)}
# a tint multiplied into the game's picture (the texture drawn with this colour): TURBO's orange taken to the card's red
LOGO_TINT = {"turbo": (1.0, 0.42, 0.40)}
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
    """PLEASE STAND BY, made to read (director, Oct 30 2026: "please stand by is hard to read"): a plain slate, flat
    colour and solid letters, no chrome or glow: a white frame, a royal-blue panel, the words in white with a fat dark
    outline and shadow, the difficulties line in yellow on a black band"""
    s = big_scale(w, h)
    a = blank(w, h, (16, 16, 20))
    m = max(4, int(min(w, h) * 0.05))
    rect(a, m, m, w - 2 * m, h - 2 * m, (235, 235, 230))                  # the frame
    rect(a, m + max(2, s), m + max(2, s), w - 2 * m - 2 * max(2, s), h - 2 * m - 2 * max(2, s), (24, 64, 170))
    for i, word in enumerate(("PLEASE", "STAND BY")):
        gm = glyph_mask(word, "57", s, gap=1)
        gm = grow(pad_to(gm, 1), max(1, s // 3))                              # heavier strokes
        x = w // 2 - gm.shape[1] // 2; y = int(h * 0.20) + i * (gm.shape[0] + 2 * s)
        put(a, grow(pad_to(gm, 2), 2), x - 2 + s // 2 + 1, y - 2 + s // 2 + 1, (0, 0, 0))
        put(a, grow(pad_to(gm, 2), 2), x - 2, y - 2, (8, 16, 50))
        put(a, gm, x, y, (255, 255, 255))
    ss = max(1, s // 2)
    by = int(h * 0.66)
    rect(a, m + max(2, s), by, w - 2 * m - 2 * max(2, s), 2 * (7 * ss) + 4 * ss + 4, (0, 0, 0))
    text(a, "WE ARE EXPERIENCING", w // 2, by + 2 * ss + 1, ss, (255, 220, 60))
    text(a, "TECHNICAL DIFFICULTIES", w // 2, by + 2 * ss + 1 + 7 * ss + 2 * ss, ss, (255, 220, 60))
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


def chopper(a, hx0, hy0, L, s, stripe=(200, 30, 36), body=(225, 230, 240, 255)):
    """a news helicopter flying left, nose down: cabin, windscreen, a stripe down the side, tail boom, fin, the tail
    rotor's blur, the main rotor as a blurred line, skids"""
    h, w = a.shape[:2]
    ch_ = Image.new("RGBA", (w, h), (0, 0, 0, 0)); dc = ImageDraw.Draw(ch_)
    tilt = 0.10
    def T(x, y): return (hx0 + x * L, hy0 + (y + (x - 0.35) * tilt) * L)
    dc.ellipse([*T(0.02, 0.18), *T(0.42, 0.40)], fill=body)
    dc.polygon([T(0.38, 0.24), T(0.95, 0.27), T(0.95, 0.30), T(0.38, 0.34)], fill=body)
    dc.polygon([T(0.90, 0.16), T(0.97, 0.16), T(0.97, 0.30), T(0.92, 0.30)], fill=body)
    dc.ellipse([*T(0.88, 0.10), *T(1.02, 0.24)], outline=(200, 210, 230, 160), width=1)
    dc.ellipse([*T(0.04, 0.21), *T(0.17, 0.33)], fill=(60, 120, 190, 255))
    dc.polygon([T(0.10, 0.33), T(0.40, 0.31), T(0.40, 0.34), T(0.10, 0.36)], fill=tuple(stripe) + (255,))
    dc.rectangle([*T(0.18, 0.14), *T(0.26, 0.19)], fill=body)
    for k, al in ((0.0, 230), (0.02, 120), (-0.02, 120)):
        dc.line([T(-0.25, 0.14 + k), T(0.70, 0.14 + k)], fill=(235, 240, 250, al), width=1)
    for xx in (0.08, 0.32):
        dc.line([T(xx, 0.40), T(xx, 0.45)], fill=(200, 205, 215, 255), width=1)
    dc.line([T(0.0, 0.46), T(0.40, 0.44)], fill=(200, 205, 215, 255), width=max(1, s // 2))
    chp = np.asarray(ch_, np.float32) / 255
    al_ = chp[..., 3:4]
    a[:] = a * (1 - al_) + chp[..., :3] * al_


def signoff(cid, w, h):
    s = big_scale(w, h)
    name, ch = {c[0]: (c[1], c[2]) for c in CHANNELS}[cid]
    cx, cy = w // 2, int(h * 0.42)
    if cid == "triple_n":
        # more America (director, Oct 30 2026: "3N needs more MERICA"): the flag waving full-screen behind, the game's
        # logo on a white band across it, fireworks glints, AMERICA'S NEWS NOW under it
        a = blank(w, h)
        RED, WHITE, BLUE = np.array((190, 30, 40)), np.array((240, 240, 236)), np.array((30, 50, 120))
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        wave = np.sin(xx / w * 2 * math.pi * 1.2 + yy / h * 1.5) * h * 0.025       # the cloth's ripple
        sh = 0.82 + 0.18 * np.cos(xx / w * 2 * math.pi * 1.2 + yy / h * 1.5)          # its light and shade
        stripe = (((yy + wave) / (h / 13.0)).astype(int) % 2 == 0)
        a[:] = np.where(stripe[..., None], RED, WHITE) / 255.0
        canton = (xx < w * 0.42) & (yy + wave < h * 7 / 13.0)
        a[canton] = BLUE / 255.0
        a *= sh[..., None]
        sp = max(6, int(w * 0.42 / 8))
        for r in range(6):                                             # the stars, staggered
            for c in range(8):
                x = int(sp * 0.6 + c * sp + (sp // 2 if r % 2 else 0)); y = int(sp * 0.6 + r * sp * 0.85)
                if x < w * 0.40 and y < h * 7 / 13.0 - 3:
                    glint(a, x, int(y + np.sin(x / w * 2 * math.pi * 1.2 + y / h * 1.5) * h * 0.025), n=max(1, s // 2 + 1), rgb=(255, 255, 255))
        fx, fy, fw, fh = LOGO_BOX[cid]                                  # the white band the logo sits on
        by0, by1 = int(fy * h) - 2 * s, int((fy + fh) * h) + 2 * s
        rect(a, 0, by0 - 2, w, 2, (30, 50, 120)); rect(a, 0, by1, w, 2, (30, 50, 120))
        rect(a, 0, by0, w, by1 - by0, (246, 246, 242))
        game_logo(a, cid)
        rng = np.random.default_rng(1776)                              # fireworks over the flag
        for _ in range(5):
            gx_, gy_ = int(rng.integers(w // 2, w - 8)), int(rng.integers(6, by0 - 6))
            glint(a, gx_, gy_, n=2 + s, rgb=(255, 240, 200))
        text(a, "AMERICA'S NEWS NOW", w // 2, by1 + 2 * s + 1, max(1, s // 2), (255, 255, 255), outline=(20, 30, 80), shadow=(10, 10, 40))
        ss_ = max(1, s // 2)                                            # a navy bar under the footer's lines
        rect(a, 0, int(h * 0.78) - 3, w, 8 * ss_ + 14, (24, 36, 96))
    elif cid == "wbln":
        # the local news station, readable (director, Oct 30 2026: "WBLN is hard to read"): a newsroom-blue field with
        # a faint map grid, the globe beside the call letters (not under them), big white letters with a navy outline
        # and shadow, NEWS in a red bar under them, YOUR NEWS LEADER
        a = card_frame(w, h, (24, 52, 110), (6, 14, 40))
        for x in range(0, w, max(6, 3 * s)): a[:int(h * 0.74), x] *= 1.12      # the faint grid
        for y in range(0, int(h * 0.74), max(6, 3 * s)): a[y, :] *= 1.12
        np.clip(a, 0, 1, out=a)
        sc = s + 1
        m = glyph_mask("WBLN", "57", sc)
        r = int(5.5 * sc)                                                  # the globe's radius
        total = 2 * r + 3 * s + m.shape[1]
        gx_ = cx - total // 2 + r; gy_ = cy - s
        disc_ = disc_mask(r)
        put(a, grow(pad_to(disc_, 1), 1), gx_ - r - 1, gy_ - r - 1, (230, 236, 255))
        put(a, disc_, gx_ - r, gy_ - r, (40, 110, 210))
        yy_, xx_ = np.mgrid[-r:r + 1, -r:r + 1]
        inside = xx_ * xx_ + yy_ * yy_ <= r * r
        lines = np.zeros_like(inside)
        for k in (-0.55, 0.0, 0.55):                                      # meridians
            lines |= np.abs(xx_ - k * np.sqrt(np.clip(r * r - yy_ * yy_, 0, None))) < 0.7
        for k in (-0.5, 0.0, 0.5):                                        # parallels
            lines |= np.abs(yy_ - k * r) < 0.6
        put(a, lines & inside, gx_ - r, gy_ - r, (200, 225, 255))
        lx = gx_ + r + 3 * s; ly = gy_ - m.shape[0] // 2 - 2 * s
        put(a, grow(pad_to(m, 2), 2), lx - 2 + s // 2 + 1, ly - 2 + s // 2 + 1, (0, 0, 20))
        put(a, grow(pad_to(m, 2), 2), lx - 2, ly - 2, (10, 30, 90))
        put(a, m, lx, ly, (255, 255, 255))
        nb_y = ly + m.shape[0] + 2 * s                                     # NEWS in its red bar
        nm = glyph_mask("NEWS", "57", max(1, s // 2 + 1), gap=2)
        rect(a, lx - 2, nb_y, m.shape[1] + 4, nm.shape[0] + 2 * s, (200, 30, 36))
        put(a, nm, lx + (m.shape[1] - nm.shape[1]) // 2, nb_y + s, (255, 255, 255))
        text(a, "YOUR NEWS LEADER", cx, nb_y + nm.shape[0] + 3 * s + 2, 1, (200, 220, 255))
        # the news chopper in the shot (director, Oct 30 2026: "WBLN can have a chopper in shot flying")
        chopper(a, w * 0.62, h * 0.06, w * 0.26, s, (200, 30, 36))
    elif cid == "life":
        # the learning channels before reality TV (director, Oct 30 2026: "kinda like the TLC or Discover channel in
        # their old format"): the earth's rim seen from space, the sun cresting it, the name over the dark, a tagline
        a = card_frame(w, h, (4, 10, 30), (0, 2, 10))
        rng = np.random.default_rng(11)
        for _ in range(int(w * h / 500)):                                  # the stars
            x, y = int(rng.integers(0, w)), int(rng.integers(0, int(h * 0.6)))
            a[y, x] = np.array((1, 1, 1), np.float32) * float(rng.uniform(0.3, 0.9))
        R = int(w * 1.1)                                                   # the planet: a huge disc, only its top shows
        pcx, pcy = cx, int(h * 0.66) + R
        yy, xx = np.mgrid[0:h, 0:w]
        d = np.sqrt((xx - pcx) ** 2 + (yy - pcy) ** 2)
        body = d <= R
        k = np.clip((R - d) / (h * 0.35), 0, 1)
        sea = np.stack([0.05 + 0.10 * (1 - k), 0.20 + 0.25 * (1 - k), 0.45 + 0.30 * (1 - k)], -1)
        land = (np.sin(xx / (7.0 * s) + 1.3) + np.sin(yy / (4.0 * s) + xx / (13.0 * s)) > 1.0) & body
        a[body] = sea[body]
        a[land] = (np.array((0.18, 0.42, 0.20)) * (0.6 + 0.4 * (1 - k[..., None])))[land]
        rim = (d > R - 2) & (d <= R + 2)                                   # the atmosphere's thin bright edge
        a[rim] = np.maximum(a[rim], np.array((0.45, 0.80, 1.0), np.float32))
        add_glow(a, rim, 0, 0, (90, 170, 255), radius=3, amount=0.5)
        sx, sy = cx - int(w * 0.18), int(h * 0.66) + 1                     # the sun just over the rim, its flare
        add_glow(a, disc_mask(3 * s), sx - 3 * s, sy - 3 * s, (255, 220, 140), radius=4 * s, amount=1.0)
        put(a, disc_mask(2 * s), sx - 2 * s, sy - 2 * s, (255, 250, 230))
        glint(a, sx, sy, n=10 * s, rgb=(255, 240, 200))
        rect(a, sx - 30 * s, sy, 60 * s, 1, (255, 230, 180))
        ts = s if glyph_mask("LIFE & LIVING", "57", s).shape[1] <= w * 0.86 else s - 1      # the title keeps a margin
        text(a, "LIFE & LIVING", cx, int(h * 0.20), ts, (255, 255, 255), shadow=(0, 0, 0))
        text(a, "TELEVISION", cx, int(h * 0.20) + 8 * s + 2, max(1, s // 2), (255, 205, 110))
        text(a, "EXPLORE YOUR WORLD", cx, int(h * 0.20) + 8 * s + 4 + 9 * max(1, s // 2), 1, (160, 200, 255))
    elif cid == "turbo":
        # the car shows' look of the day (director, Oct 30 2026: "like motor trend from the day. black and red"): a black
        # set, a slanted red racing band above and below the name with a white pinstripe, the band's end cut in speed
        # slashes, a chequered strip under it all
        a = card_frame(w, h, (24, 22, 22), (0, 0, 0))
        RED, WHITE = (200, 22, 26), (235, 235, 230)

        def band(y0, th, slant, end_cut):
            for yy in range(th):
                off = int((th - yy) * slant)
                x1 = w - end_cut + off
                rect(a, 0, y0 + yy, max(0, x1), 1, RED)
                for k in range(3):                                         # the band's end in three slashes
                    sx = x1 + 4 * s + k * 5 * s
                    rect(a, sx, y0 + yy, 2 * s, 1, RED)

        th = max(4, int(h * 0.075))
        band(int(h * 0.12), th, 0.6, int(w * 0.30))
        rect(a, 0, int(h * 0.12) + th + 2, int(w * 0.62), 1, WHITE)
        band(int(h * 0.60), th, 0.6, int(w * 0.30))
        rect(a, 0, int(h * 0.60) - 3, int(w * 0.62), 1, WHITE)
        cs = max(3, s)                                                     # the chequered strip
        cy0 = int(h * 0.60) + th + 3
        for k in range(0, w // cs + 1):
            for r in range(2):
                if (k + r) % 2 == 0: rect(a, k * cs, cy0 + r * cs, cs, cs, WHITE)
        game_logo(a, cid)
    elif cid == "paws":
        # the cartoon and kids networks of the day (director, Oct 30 2026: "Paws is like a cartoon/kids network"): a
        # sunny field, a big orange paint splat behind bouncy balloon letters each its own colour, a paw print for the
        # A's place in the TV bug, a black-and-white chequer strip, CARTOONS ALL DAY
        a = card_frame(w, h, (90, 200, 255), (40, 120, 230))
        rng = np.random.default_rng(42)
        im = Image.new("L", (w, h), 0); dr = ImageDraw.Draw(im)              # the splat: a lumpy blob, its drips
        R0 = h * 0.26
        pts = []
        for k in range(28):
            ang = k * 2 * math.pi / 28
            rr = R0 * (1.0 + 0.18 * math.sin(k * 2.3) + float(rng.uniform(-0.08, 0.10)))
            pts.append((cx + math.cos(ang) * rr * 1.45, cy - 2 * s + math.sin(ang) * rr))
        dr.polygon(pts, fill=255)
        for k in range(5):                                                    # drips and flung drops
            dx_ = cx + int(rng.uniform(-R0, R0)); dl = int(rng.uniform(0.15, 0.35) * h)
            dr.rectangle([dx_ - 2 * s, cy, dx_ + 2 * s, cy + dl], fill=255)
            dr.ellipse([dx_ - 3 * s, cy + dl - 3 * s, dx_ + 3 * s, cy + dl + 3 * s], fill=255)
        for k in range(7):
            ang = rng.uniform(0, 2 * math.pi); rr = R0 * 1.7
            x, y = cx + math.cos(ang) * rr * 1.4, cy + math.sin(ang) * rr * 0.9
            r_ = float(rng.uniform(1.5, 3.5)) * s; dr.ellipse([x - r_, y - r_, x + r_, y + r_], fill=255)
        splat = np.asarray(im) > 127
        a[grow(splat, 2) & ~splat] = np.array((180, 60, 0), np.float32) / 255
        a[splat] = np.array((255, 120, 20), np.float32) / 255
        sc = s + 1                                                             # the balloon letters
        word = "PAWS"
        colors = ((170, 60, 230), (60, 200, 70), (255, 230, 40), (230, 40, 60))
        widths = [glyph_mask(c, "57", sc).shape[1] + 2 * (s // 2 + 1) for c in word]
        x = cx - (sum(widths) + 3 * s) // 2
        for i, (c, col) in enumerate(zip(word, colors)):
            gw_ = s // 2 + 1
            m = grow(pad_to(glyph_mask(c, "57", sc), gw_), gw_)
            y = cy - 6 * sc + int(math.sin(i * 1.7) * 2 * s)
            put(a, grow(pad_to(m, 2), 2), x - 2 + s // 2 + 1, y - 2 + s // 2 + 1, (40, 20, 0))   # shadow
            put(a, grow(pad_to(m, 2), 2), x - 2, y - 2, (255, 255, 255))                         # white outline
            put(a, m, x, y, col)
            x += widths[i] + s
        # the TV bug: a paw print in a white disc, with TV beside it
        pr = int(3 * s); bx, by = cx - 5 * s, cy + 9 * s                   # under the letters
        put(a, disc_mask(pr + s), bx - pr - s, by - pr - s, (255, 255, 255))
        put(a, disc_mask(int(pr * 0.5)), bx - int(pr * 0.5), by - int(pr * 0.5) + s, (60, 40, 30))
        for (dx, dy) in ((-0.55, -0.45), (-0.2, -0.75), (0.2, -0.75), (0.55, -0.45)):
            rr = max(1, int(pr * 0.22)); put(a, disc_mask(rr), int(bx + dx * pr) - rr, int(by + dy * pr) - rr + s, (60, 40, 30))
        text(a, "TV", bx + pr + 3 * s, by - 7 * max(1, s - 1) // 2, max(1, s - 1), (255, 255, 255), align="l", outline=(40, 20, 0))
        cs = max(3, s)                                                         # the chequer strip
        cy0 = int(h * 0.70)
        for k in range(0, w // cs + 1):
            for r in range(2):
                rect(a, k * cs, cy0 + r * cs, cs, cs, (255, 255, 255) if (k + r) % 2 == 0 else (10, 10, 10))
        text(a, "CARTOONS ALL DAY", cx, int(h * 0.08), max(1, s // 2), (255, 255, 255), outline=(20, 60, 140))
        a[int(h * 0.78) - 3:int(h * 0.78) - 3 + 8 * max(1, s // 2) + 14] *= 0.45
    elif cid == "kpa":
        # the call letters and the big ring numeral of the station IDs the director sent: KPA in white with a blue
        # outline and a soft blue glow, TV in red under it, the red ring with the 7 standing in it
        a = card_frame(w, h, (10, 12, 22), (0, 0, 0))
        sc = s + 1
        m = glyph_mask("KPA", "57", sc)
        r = int(6.5 * sc)
        total = m.shape[1] + 4 * s + 2 * r
        lx = cx - total // 2; ly = cy - m.shape[0] // 2 - 3 * s
        add_glow(a, m, lx, ly, (60, 140, 255), radius=2 * s, amount=0.8)
        put(a, grow(pad_to(m, 2), 2), lx - 2, ly - 2, (20, 50, 140))
        put(a, m, lx, ly, (255, 255, 255))
        tv = glyph_mask("TV", "57", max(1, s - 1))
        put(a, grow(pad_to(tv, 1), 1), lx + m.shape[1] - tv.shape[1] - 1, ly + m.shape[0] + 2 * s - 1, (40, 0, 0))
        put(a, tv, lx + m.shape[1] - tv.shape[1], ly + m.shape[0] + 2 * s, (230, 40, 36))
        rcx, rcy = lx + m.shape[1] + 4 * s + r, cy - s
        ring = ring_mask(r, max(3, int(1.6 * s)))
        add_glow(a, ring, rcx - r, rcy - r, (255, 60, 40), radius=2 * s, amount=0.5)
        put(a, ring, rcx - r, rcy - r, (230, 40, 36))
        sev = grow(pad_to(glyph_mask(str(ch), "57", sc), 1), 1)          # the numeral standing clear inside the ring
        put(a, sev, rcx - sev.shape[1] // 2, rcy - sev.shape[0] // 2, (230, 40, 36))
        # two choppers, and they know it (director, Oct 30 2026: "KPA has two choppers and they know it"): one in
        # front, its wingman behind and above, and the line that says so
        chopper(a, w * 0.16, h * 0.06, w * 0.28, s, (230, 40, 36))                        # the lead
        chopper(a, w * 0.58, h * 0.03, w * 0.22, s, (60, 140, 255), body=(200, 206, 220, 255))  # the wingman, behind
        text(a, "THE TWO-CHOPPER STATION", cx, ly + m.shape[0] + 9 * s, 1, (255, 220, 120), outline=(40, 20, 0))
    elif cid == "mvc":
        # the rap-video shows and sitcom openers of the day (director, Oct 30 2026: "more fresh prince, yo mtv raps
        # vibes"): a loud purple-to-teal field thrown with confetti shapes (triangles, squiggles, zigzags, dots), chunky
        # bouncing letters each its own colour with a fat black outline and a hard drop shadow, paint drips, the name on
        # a slanted black tag
        a = blank(w, h)
        for y in range(h):
            k = y / max(1, h - 1)
            a[y] = np.array((110 * (1 - k) + 0 * k, 20 * (1 - k) + 170 * k, 160 * (1 - k) + 170 * k), np.float32) / 255
        rng = np.random.default_rng(1990)
        cols = [(255, 230, 40), (255, 60, 170), (60, 240, 240), (255, 255, 255), (160, 255, 60)]
        im = Image.new("RGB", (w, h)); dr = ImageDraw.Draw(im)
        shapes = []
        for i in range(int(w * h / 1400)):
            kind = i % 4
            x, y = int(rng.integers(0, w)), int(rng.integers(0, h))
            c = cols[int(rng.integers(0, len(cols)))]
            r = int(rng.integers(3, 6)) * max(1, s // 2 + 1)
            shapes.append((kind, x, y, r, c, float(rng.uniform(0, math.pi))))
        for (kind, x, y, r, c, ang) in shapes:
            for (dx, dy, col) in ((max(1, s // 2), max(1, s // 2), (0, 0, 0)), (0, 0, c)):         # a black offset, then the colour
                X, Y = x + dx, y + dy
                if kind == 0:                                              # a triangle, outlined
                    pts = [(X + math.cos(ang + k * 2.094) * r, Y + math.sin(ang + k * 2.094) * r) for k in range(3)]
                    dr.polygon(pts, outline=col)
                elif kind == 1:                                            # a squiggle
                    pts = [(X + t - 2 * r, Y + math.sin(t / r * 3.1) * r * 0.4) for t in range(0, 4 * r + 1, 2)]
                    dr.line(pts, fill=col, width=max(1, s // 2))
                elif kind == 2:                                            # a zigzag
                    pts = [(X + k * r * 0.5 - r, Y + (r * 0.35 if k % 2 else -r * 0.35)) for k in range(5)]
                    dr.line(pts, fill=col, width=max(1, s // 2))
                else:                                                      # a dot
                    rr = max(1, r // 3); dr.ellipse([X - rr, Y - rr, X + rr, Y + rr], fill=col)
        conf = np.asarray(im, np.float32) / 255
        on = conf.sum(axis=2) > 0
        a[on] = conf[on]
        # the mark (director, Oct 30 2026: "Make the V the rabbit ears of a TV. M and C on each side of the TV"):
        # a little TV set in the middle, its rabbit-ear antenna the V, M to its left and C to its right
        sc = s + 2
        gw_ = max(1, s // 2)

        def chunky(mask, x, y, col, drips=True):
            put(a, grow(pad_to(mask, 2), 2), x - 2 + s, y - 2 + s, (0, 0, 0))                # the hard shadow
            put(a, grow(pad_to(mask, 2), 2), x - 2, y - 2, (0, 0, 0))                        # the fat outline
            put(a, mask, x, y, col)
            if drips:
                for d in range(2):                                         # paint drips off the foot
                    dx_ = x + int(rng.integers(sc, mask.shape[1] - sc)); dl = int(rng.integers(2, 5)) * s
                    rect(a, dx_, y + mask.shape[0] - 1, max(2, s // 2 + 1), dl, col)
                    put(a, disc_mask(max(1, s // 2 + 1)), dx_ - 1, y + mask.shape[0] - 1 + dl - 1, col)

        mM = grow(pad_to(glyph_mask("M", "57", sc), gw_), gw_)
        mC = grow(pad_to(glyph_mask("C", "57", sc), gw_), gw_)
        tvw, tvh = int(8.5 * sc), int(6.5 * sc)                             # the set: body, screen, knobs, feet
        gap = 2 * s
        total = mM.shape[1] + gap + tvw + gap + mC.shape[1]
        x0 = cx - total // 2
        base = cy + 2 * sc                                                   # the letters' and the set's foot line
        chunky(mM, x0, base - mM.shape[0] + s, (255, 230, 40))
        chunky(mC, x0 + mM.shape[1] + gap + tvw + gap, base - mC.shape[0] - s, (60, 240, 240))
        tx0 = x0 + mM.shape[1] + gap; ty0 = base - tvh
        body = np.zeros((tvh, tvw), bool)
        bim = Image.new("L", (tvw, tvh), 0); ImageDraw.Draw(bim).rounded_rectangle([0, 0, tvw - 1, tvh - 1], radius=max(2, sc), fill=255)
        body = np.asarray(bim) > 127
        # the antenna first (behind the set): two rods from the top middle out to balls, the V
        ax, ay = tx0 + tvw // 2, ty0 + 2
        ah = int(6.5 * sc); spread = int(4.2 * sc)
        rods = Image.new("L", (a.shape[1], a.shape[0]), 0); dr2 = ImageDraw.Draw(rods)
        for side in (-1, 1):
            dr2.line([(ax, ay), (ax + side * spread, ay - ah)], fill=255, width=max(2, sc // 2 + 1))
            rb = max(2, sc // 2 + 1)
            dr2.ellipse([ax + side * spread - rb, ay - ah - rb, ax + side * spread + rb, ay - ah + rb], fill=255)
        rm = np.asarray(rods) > 127
        a[grow(rm, 2)] = 0.0
        a[rm] = np.array((255, 60, 170), np.float32) / 255
        dome = disc_mask(max(2, sc // 2 + 2))
        put(a, grow(pad_to(dome, 2), 2), ax - dome.shape[1] // 2 - 2, ay - dome.shape[0] // 2 - 2, (0, 0, 0))
        put(a, dome, ax - dome.shape[1] // 2, ay - dome.shape[0] // 2, (255, 60, 170))
        chunky(body, tx0, ty0, (255, 60, 170), drips=False)
        sw_, sh_ = int(tvw * 0.62), int(tvh * 0.66)                          # the screen, its bars
        sx_, sy_ = tx0 + max(2, sc // 2), ty0 + (tvh - sh_) // 2
        sim = Image.new("L", (sw_, sh_), 0); ImageDraw.Draw(sim).rounded_rectangle([0, 0, sw_ - 1, sh_ - 1], radius=max(2, sc // 2), fill=255)
        sm = np.asarray(sim) > 127
        put(a, grow(pad_to(sm, 1), 1), sx_ - 1, sy_ - 1, (0, 0, 0))
        bars_ = [(255, 230, 40), (60, 240, 240), (160, 255, 60), (255, 255, 255), (170, 60, 230)]
        for i, c in enumerate(bars_):
            col_ = np.zeros_like(sm); x0b = int(i * sw_ / len(bars_)); x1b = int((i + 1) * sw_ / len(bars_))
            col_[:, x0b:x1b] = True
            put(a, sm & col_, sx_, sy_, c)
        kx = sx_ + sw_ + max(2, (tvw - sw_ - max(2, sc // 2)) // 2)          # the two knobs
        for k in range(2):
            kd = disc_mask(max(1, sc // 3 + 1))
            put(a, grow(pad_to(kd, 1), 1), kx - kd.shape[1] // 2 - 1, sy_ + sh_ // 4 + k * sh_ // 2 - kd.shape[0] // 2 - 1, (0, 0, 0))
            put(a, kd, kx - kd.shape[1] // 2, sy_ + sh_ // 4 + k * sh_ // 2 - kd.shape[0] // 2, (255, 230, 40))
        for fx_ in (tx0 + sc, tx0 + tvw - 2 * sc):                           # the feet
            rect(a, fx_, base, sc, s, (0, 0, 0))
        # the slanted black tag
        ty = base + 2 * s + 2
        tm = glyph_mask("MUSIC VIDEO CHANNEL", "57", max(1, s // 2))
        tw_, th_ = tm.shape[1] + 6 * s, tm.shape[0] + 3 * s
        tx = cx - tw_ // 2
        for yy in range(th_):
            rect(a, tx + (th_ - yy) // 2, ty + yy, tw_, 1, (10, 10, 10))
        put(a, tm, tx + 3 * s + th_ // 4, ty + (th_ - tm.shape[0]) // 2, (255, 255, 255))
        f0 = int(h * 0.78) - 3                                             # the confetti dimmed under the footer
        a[f0:f0 + 8 * max(1, s // 2) + 14] *= 0.3
    elif cid == "nst":
        # the all-sports network of the day (director, Oct 30 2026: "national sports tv is ESPN pretty much"): wide,
        # heavy red letters on black, cut through with fine horizontal lines, a red rule, the round-the-clock line
        a = card_frame(w, h, (14, 14, 16), (0, 0, 0))
        RED = (214, 24, 30)
        sc = s + 2
        m = glyph_mask("NST", "57", sc, gap=1)
        wide = grow(pad_to(np.repeat(m, 2, axis=1), s), max(1, s // 2 + 1))     # twice as wide and heavier: the broad face
        for yy in range(wide.shape[0]):                                     # the fine lines cut through
            if yy % sc == sc - 1 and 0.15 < yy / wide.shape[0] < 0.9: wide[yy] = False
        x0 = cx - wide.shape[1] // 2; y0 = cy - wide.shape[0] // 2 - 2 * s
        put(a, grow(pad_to(wide, 1), 1), x0 - 1, y0 - 1, (60, 0, 0))
        put(a, wide, x0, y0, RED)
        rect(a, x0, y0 + wide.shape[0] + 2 * s, wide.shape[1], max(1, s // 2), RED)
        text(a, "NATIONAL SPORTS TELEVISION", cx, y0 + wide.shape[0] + 4 * s, 1 if w < 330 else max(1, s // 2), (240, 240, 240))
        text(a, "SPORTS AROUND THE CLOCK", cx, y0 + wide.shape[0] + 4 * s + 10, 1, (200, 60, 60), font="35" if w < 330 else "57")
    elif cid == "bmc":
        a = card_frame(w, h, (30, 20, 10), (0, 0, 0))
        # an old film camera behind the name (director, Oct 30 2026: "an old film camera not an X"): two reels on top,
        # the box, the lens to the right, the tripod's head and legs, in a dim gold silhouette
        cam = Image.new("L", (w, h), 0); dc = ImageDraw.Draw(cam)
        u = h / 100.0
        bx0, by0, bx1, by1 = cx - 22 * u, 34 * u, cx + 14 * u, 62 * u                      # the box
        dc.rounded_rectangle([bx0, by0, bx1, by1], radius=2 * u, fill=255)
        for (rx, rr) in ((cx - 14 * u, 11 * u), (cx + 6 * u, 11 * u)):                        # the two reels
            dc.ellipse([rx - rr, by0 - 2 * rr + 2 * u, rx + rr, by0 + 2 * u], fill=255)
        dc.polygon([(bx1, by0 + 7 * u), (bx1 + 10 * u, by0 + 3 * u), (bx1 + 10 * u, by1 - 3 * u), (bx1, by1 - 7 * u)], fill=255)   # the lens hood
        dc.rectangle([cx - 6 * u, by1, cx + 2 * u, by1 + 6 * u], fill=255)                     # the tripod head
        for dxl in (-16, -2, 12):                                                              # the legs
            dc.line([(cx - 2 * u, by1 + 6 * u), (cx + dxl * u, 100 * u)], fill=255, width=max(2, int(2.2 * u)))
        holes = Image.new("L", (w, h), 0); dh_ = ImageDraw.Draw(holes)
        for (rx, rr) in ((cx - 14 * u, 11 * u), (cx + 6 * u, 11 * u)):                        # the reels' spokes, cut out
            for k in range(3):
                ang = math.radians(90 + k * 120)
                hx_, hy_ = rx + math.cos(ang) * rr * 0.5, by0 - rr + 2 * u + math.sin(ang) * rr * 0.5
                dh_.ellipse([hx_ - rr * 0.28, hy_ - rr * 0.28, hx_ + rr * 0.28, hy_ + rr * 0.28], fill=255)
        cm = (np.asarray(cam) > 127) & ~(np.asarray(holes) > 127)
        a[cm] = np.array((62, 46, 20), np.float32) / 255
        edge = grow(cm, 1) & ~cm
        a[edge] = np.array((110, 84, 36), np.float32) / 255
        rect(a, cx - 20 * s, cy - 2 * s, 40 * s, 12 * s, (20, 20, 20))                      # a film strip under the name
        for k in range(-9, 10):
            rect(a, cx + k * 2 * s, cy - s, s, s, (200, 190, 160)); rect(a, cx + k * 2 * s, cy + 8 * s, s, s, (200, 190, 160))
        text(a, "BMC", cx, cy, s + 1, chrome((255, 245, 200), (220, 170, 60), (90, 50, 10), (255, 230, 150)), outline=(30, 15, 0))
        text(a, "BRENNAN MOVIE CHANNEL", cx, cy + 12 * s, max(1, s // 2), (240, 210, 140), outline=(0, 0, 0))
    elif cid == "gbc":
        # public television (director, Oct 30 2026: "a head profile that hints at the old PBS logo"): a face in profile,
        # looking right, with two echoes of it stepping back behind it, beside the name
        a = card_frame(w, h, (20, 50, 120), (6, 16, 50))
        HEAD = [(0.30, 0.04), (0.56, 0.00), (0.76, 0.14), (0.82, 0.32), (0.80, 0.40), (0.98, 0.52), (0.84, 0.57),
                (0.88, 0.63), (0.83, 0.67), (0.87, 0.73), (0.80, 0.86), (0.64, 0.91), (0.64, 1.00), (0.30, 1.00),
                (0.28, 0.82), (0.12, 0.60), (0.10, 0.34), (0.16, 0.16)]
        hh = int(h * 0.40); hw = int(hh * 0.80)
        hx = cx - int(hw * 1.55); hy = cy - hh // 2 - s
        for k, col in ((2, (60, 110, 190)), (1, (130, 170, 230)), (0, (250, 250, 250))):
            im = Image.new("L", (hw + 2, hh + 2), 0)
            ImageDraw.Draw(im).polygon([(x * hw, y * hh) for x, y in HEAD], fill=255)
            m = np.asarray(im) > 127
            ox = hx - k * int(hw * 0.30)
            if k:                                                          # an echo: an outline behind
                put(a, grow(pad_to(m, 1), 1), ox - 1, hy - 1, col)
                put(a, m, ox, hy, (20, 50, 120) if k == 1 else (14, 36, 90))
            else:
                put(a, grow(pad_to(m, 1), 1), ox - 1, hy - 1, (6, 16, 50))
                put(a, m, ox, hy, col)
        gx = hx + hw + 4 * s
        text(a, "GBC", gx, cy - 7 * s // 2 - 2 * s, s + 1, (255, 255, 255), align="l", shadow=(6, 16, 50))
        text(a, "PUBLIC", gx + s, cy + 5 * s, max(1, s // 2), (200, 220, 255), align="l")
        text(a, "TELEVISION", gx + s, cy + 5 * s + 9 * max(1, s // 2), max(1, s // 2), (200, 220, 255), align="l")
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
    if cid in LOGO_TINT: rgb[..., :3] *= np.array(LOGO_TINT[cid], np.float32)
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
