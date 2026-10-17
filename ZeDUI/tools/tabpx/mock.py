"""Concepts for the window tab strips: the current look and three ways to tie them to the lit pixel art, theme-safe
(everything drawn from the theme's colours at run time, no baked colour)."""
from PIL import Image, ImageDraw
import numpy as np
S = "/mnt/user-data/uploads/Zomboid/Lua/zed_stage/tabicons/"
CHAR = ["loot", "equipment", "health", "thermal", None, "identy", "journal", "skills"]
WORLD = ["loot", "craft", "build", "move", None, "map", "forage", "farm", "vehicle"]
BG = np.array([27, 25, 22]); BORDER = np.array([32, 32, 32]); SEP = np.array([56, 56, 56])
ACC = {"char": (np.array([0xD4, 0x92, 0x2A]), np.array([0xE8, 0xA8, 0x30])), "world": (np.array([0x44, 0x88, 0xCC]), np.array([0x66, 0xAA, 0xEE]))}
ONACC = np.array([12, 12, 12])
W, B = 36, 36


def mask(name):
    im = Image.open(S + f"{name}-tab-white.png").convert("RGBA")
    a = np.array(im)[..., 3] > 100
    return a


def blend(img, m, c, a=1.0, ox=0, oy=0):
    H, Wd = m.shape
    reg = img[oy:oy + H, ox:ox + Wd, :3].astype(float)
    mm = m[..., None] * a
    img[oy:oy + H, ox:ox + Wd, :3] = (reg * (1 - mm) + np.array(c) * mm).astype(np.uint8)


def rect(img, x, y, w, h, c, a=1.0):
    m = np.ones((h, w), bool); blend(img, m, c, a, x, y)


def edges(m):
    up = np.zeros_like(m); up[1:] = m[:-1]
    lf = np.zeros_like(m); lf[:, 1:] = m[:, :-1]
    dn = np.zeros_like(m); dn[:-1] = m[1:]
    rt = np.zeros_like(m); rt[:, :-1] = m[:, 1:]
    hi = m & ~up                      # the top edge of each stroke catches the light from above
    sh = m & ~dn & ~hi                # the bottom edge falls into shade
    return hi, sh


def shade(c, f): return np.clip(np.array(c) * f, 0, 255)


def strip(kind, style, active=0, hover=None):
    names = CHAR if kind == "char" else WORLD
    acc, bright = ACC[kind]
    H = sum(9 if n is None else B for n in names)
    img = np.zeros((H, W, 4), np.uint8); img[..., :3] = BG; img[..., 3] = 255
    rect(img, W - 1, 0, 1, H, BORDER)
    y = 0; i = 0
    for n in names:
        if n is None:
            rect(img, 4, y + 4, W - 8, 1, SEP); y += 9; continue
        isA, isH = (i == active), (i == hover)
        m = mask(n); hi, sh = edges(m)
        ix, iy = (W - 16) // 2, y + (B - 16) // 2
        if style == "now":
            if isA: rect(img, 0, y, W - 1, B, acc, 0.55); rect(img, 0, y, 2, B, acc)
            elif isH: rect(img, 0, y, W - 1, B, acc, 0.55)
            blend(img, m, ONACC if isA else acc, 1.0 if isA else 0.7, ix, iy)
            rect(img, 0, y + B - 1, W, 1, BORDER)
        elif style == "shaded":
            # A: same strip; the icon lit like the plates (top-left edge catches the light, bottom-right falls off,
            # a one-pixel shadow under it); the active tab a bevelled lit panel instead of a flat wash
            if isA:
                rect(img, 0, y, W - 1, B, shade(acc, 0.85))
                rect(img, 0, y, W - 1, 1, shade(bright, 1.1)); rect(img, 0, y, 1, B, shade(bright, 1.05))
                rect(img, 0, y + B - 2, W - 1, 2, shade(acc, 0.55)); rect(img, W - 2, y, 1, B, shade(acc, 0.6))
            elif isH: rect(img, 0, y, W - 1, B, acc, 0.30)
            if isA:
                blend(img, m, (0, 0, 0), 0.0, ix, iy)
                blend(img, m, shade(acc, 0.35), 1.0, ix + 1, iy + 1)           # pressed-in: the icon's shadow
                blend(img, m, ONACC, 1.0, ix, iy)
                blend(img, hi, shade(acc, 0.45), 1.0, ix, iy)
            else:
                blend(img, m, (0, 0, 0), 0.55, ix + 1, iy + 1)
                blend(img, m, acc, 1.0, ix, iy)
                blend(img, hi, shade(bright, 1.18), 1.0, ix, iy)
                blend(img, sh, shade(acc, 0.62), 1.0, ix, iy)
            rect(img, 0, y + B - 1, W, 1, BORDER)
        elif style == "keys":
            # B: each tab a small key like the tape deck's: raised in the window's own grey, the active one pressed
            # down and lit with the accent
            kx, ky, kw, kh = 3, y + 2, W - 7, B - 4
            if isA:
                rect(img, kx, ky, kw, kh, shade(acc, 0.9))
                rect(img, kx, ky, kw, 1, shade(acc, 0.45)); rect(img, kx, ky, 1, kh, shade(acc, 0.5))
                rect(img, kx, ky + kh - 1, kw, 1, shade(bright, 1.15)); rect(img, kx + kw - 1, ky, 1, kh, shade(bright, 1.05))
                blend(img, m, ONACC, 1.0, ix, iy + 1)
                blend(img, hi, shade(acc, 0.45), 1.0, ix, iy + 1)
            else:
                face = np.array([44, 43, 40]) if not isH else np.array([58, 55, 50])
                rect(img, kx, ky, kw, kh, face)
                rect(img, kx, ky, kw, 1, np.array([78, 76, 72])); rect(img, kx, ky, 1, kh, np.array([70, 68, 64]))
                rect(img, kx, ky + kh - 2, kw, 2, np.array([16, 15, 14])); rect(img, kx + kw - 1, ky, 1, kh, np.array([20, 19, 18]))
                blend(img, m, (0, 0, 0), 0.5, ix + 1, iy)
                blend(img, m, shade(acc, 0.85), 1.0, ix, iy - 1)
                blend(img, hi, shade(bright, 1.15), 1.0, ix, iy - 1)
                blend(img, sh, shade(acc, 0.5), 1.0, ix, iy - 1)
        elif style == "lamp":
            # C: A's lit icons; the active tab marked by a lit lamp at the strip's edge (the plates' lamps) and a
            # soft wash, the side bar gone
            if isA:
                rect(img, 0, y, W - 1, B, acc, 0.22)
            elif isH: rect(img, 0, y, W - 1, B, acc, 0.12)
            ly = y + B // 2 - 3
            rect(img, 2, ly, 3, 6, np.array([14, 13, 12]))
            if isA:
                rect(img, 2, ly, 3, 6, shade(bright, 1.1)); rect(img, 3, ly + 1, 1, 2, np.array([255, 245, 220]))
                rect(img, 0, ly - 2, 7, 10, bright, 0.18)
            else:
                rect(img, 3, ly + 1, 1, 4, np.array([40, 38, 34]))
            blend(img, m, (0, 0, 0), 0.55, ix + 2, iy + 1)
            c0 = bright if isA else shade(acc, 0.8)
            blend(img, m, c0, 1.0, ix + 1, iy)
            blend(img, hi, shade(bright, 1.25), 1.0, ix + 1, iy)
            blend(img, sh, shade(acc, 0.5), 1.0, ix + 1, iy)
            rect(img, 0, y + B - 1, W, 1, BORDER)
        y += B; i += 1
    return Image.fromarray(img, "RGBA")


if __name__ == "__main__":
    k = 3
    cols = []
    for style, title in (("now", "NOW"), ("shaded", "A  LIT ICONS"), ("keys", "B  KEYS"), ("lamp", "C  LAMP")):
        a = strip("char", style, active=0, hover=2); b = strip("world", style, active=1, hover=3)
        cols.append((title, a, b))
    Wd = len(cols) * (2 * W * k + 3 * 12) + 12
    Hh = max(c[2].height for c in cols) * k + 60
    sh = Image.new("RGBA", (Wd, Hh), (40, 40, 44, 255))
    d = ImageDraw.Draw(sh)
    x = 12
    for title, a, b in cols:
        d.text((x, 12), title, fill=(230, 230, 230, 255))
        sh.alpha_composite(a.resize((W * k, a.height * k), Image.NEAREST), (x, 36))
        sh.alpha_composite(b.resize((W * k, b.height * k), Image.NEAREST), (x + W * k + 12, 36))
        x += 2 * W * k + 3 * 12
    sh.save("concepts_3x.png"); print(sh.size)
    # true size too
    t = Image.new("RGBA", (len(cols) * (2 * W + 30) + 12, max(c[2].height for c in cols) + 20), (40, 40, 44, 255))
    x = 10
    for title, a, b in cols:
        t.alpha_composite(a, (x, 10)); t.alpha_composite(b, (x + W + 6, 10)); x += 2 * W + 30
    t.resize((t.width * 2, t.height * 2), Image.NEAREST).save("concepts_1x_at2.png")
