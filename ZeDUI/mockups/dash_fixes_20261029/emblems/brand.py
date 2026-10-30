"""The five makers' brand lockups (proof, nothing in the repo): emblem + a wordmark lettered in the brand's own hand,
the model name under it. Drawn straight into a dash engine canvas so the letters stand off the vinyl and cast shadows.
  Chevalier (Chevrolet)  gold heraldic shield, bold gold block capitals
  Dash (Chrysler)        red speed bar, heavy chrome italics
  Franklin (Ford)        one navy enamel badge: the F block and the name in white, a chrome rim
  Mercia (Mercedes)      a fine chrome ring and M, thin chrome capitals, wide apart
  Masterson (fictional)  the banded sunset, italic capitals in sunset yellow over orange"""
import math
import numpy as np
from engine import text_w

d = None; M = None


def use(canvas):
    global d, M
    d = canvas; M = canvas.M


# ------------------------------------------------------------------ letters
G_CHEV = {   # bold block capitals, 7 tall: two-pixel stems
    "C": [".####.", "##..##", "##....", "##....", "##....", "##..##", ".####."],
    "H": ["##..##", "##..##", "##..##", "######", "##..##", "##..##", "##..##"],
    "E": ["######", "##....", "##....", "#####.", "##....", "##....", "######"],
    "V": ["##..##", "##..##", "##..##", "##..##", ".####.", "..##..", "..##.."],
    "A": [".####.", "##..##", "##..##", "######", "##..##", "##..##", "##..##"],
    "L": ["##....", "##....", "##....", "##....", "##....", "##....", "######"],
    "I": ["##", "##", "##", "##", "##", "##", "##"],
    "R": ["#####.", "##..##", "##..##", "#####.", "##.##.", "##..##", "##..##"],
}
G_DASH = {   # heavy capitals, 9 tall, sheared into italics
    "D": ["#####..", "##..##.", "##...##", "##...##", "##...##", "##...##", "##...##", "##..##.", "#####.."],
    "A": [".#####.", "##...##", "##...##", "##...##", "#######", "##...##", "##...##", "##...##", "##...##"],
    "S": [".#####.", "##...##", "##.....", "##.....", ".#####.", ".....##", ".....##", "##...##", ".#####."],
    "H": ["##...##", "##...##", "##...##", "##...##", "#######", "##...##", "##...##", "##...##", "##...##"],
}
G_FRANK = {  # plain condensed capitals, one-pixel strokes, white on the enamel
    "F": ["####", "#...", "#...", "###.", "#...", "#...", "#..."],
    "R": ["###.", "#..#", "#..#", "###.", "#.#.", "#..#", "#..#"],
    "A": [".##.", "#..#", "#..#", "####", "#..#", "#..#", "#..#"],
    "N": ["#..#", "##.#", "##.#", "#.##", "#.##", "#..#", "#..#"],
    "K": ["#..#", "#.#.", "##..", "##..", "#.#.", "#..#", "#..#"],
    "L": ["#...", "#...", "#...", "#...", "#...", "#...", "####"],
    "I": ["#", "#", "#", "#", "#", "#", "#"],
}
G_MERC = {   # thin capitals, wide apart
    "M": ["#.....#", "##...##", "#.#.#.#", "#..#..#", "#.....#", "#.....#", "#.....#"],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
    "I": ["#", "#", "#", "#", "#", "#", "#"],
    "A": ["..#..", ".#.#.", "#...#", "#...#", "#####", "#...#", "#...#"],
}
G_MAST = {   # italic capitals, sunset two-tone
    "M": ["##...##", "###.###", "##.#.##", "##...##", "##...##", "##...##", "##...##"],
    "A": [".###.", "##.##", "##.##", "#####", "##.##", "##.##", "##.##"],
    "S": [".####", "##...", "##...", ".###.", "...##", "...##", "####."],
    "T": ["######", "..##..", "..##..", "..##..", "..##..", "..##..", "..##.."],
    "E": ["#####", "##...", "##...", "####.", "##...", "##...", "#####"],
    "R": ["####.", "##.##", "##.##", "####.", "##.#.", "##.##", "##.##"],
    "O": [".###.", "##.##", "##.##", "##.##", "##.##", "##.##", ".###."],
    "N": ["##..##", "###.##", "######", "##.###", "##..##", "##..##", "##..##"],
}


def word_size(text, G, track, shear_px=0):
    w = sum(len(G[c][0]) for c in text) + track * (len(text) - 1) + shear_px
    return w, len(next(iter(G.values())))


def word_mask(x, y, text, G, track, shear=None):
    """the word's pixels; shear(row) = pixels the row moves right (italics)"""
    m = np.zeros((d.H, d.W), bool)
    h = len(next(iter(G.values())))
    cx = x
    for c in text:
        g = G[c]
        for r, row in enumerate(g):
            sx = shear(r) if shear else 0
            for k, ch in enumerate(row):
                if ch == "#":
                    X, Y = int(cx + k + sx), int(y + r)
                    if 0 <= X < d.W and 0 <= Y < d.H: m[Y, X] = True
        cx += len(g[0]) + track
    return m


def raise_(mask, z, mat, base, polish=0.9, bevel=0.5, shadow=0.0):
    d.slab(mask, z, mat, bevel=bevel, polish=polish, on=base)
    if shadow: drop(mask, shadow)


def drop(mask, amount=0.5):
    """a raised letter's shadow on the vinyl, a pixel right and down: it keeps light letters off light vinyl"""
    sh = np.zeros_like(mask); sh[1:, 1:] = mask[:-1, :-1]; sh &= ~mask
    d.dark[sh] = np.maximum(d.dark[sh], amount)


def text(t, x, y, mat, align="l", shadow=0.45):
    before = d.mat.copy()
    d.text(t, x, y, mat, font="35", align=align, flatlight=True)
    if shadow: drop(d.mat != before, shadow)


# ------------------------------------------------------------------ emblems, at scale s (s = 1: 20 px)
def _P(x, y, s, pts): return [(x + a * s, y + b * s) for a, b in pts]
def _circ(cx, cy, r): return M().ellipse(cx, cy, r, r).get()


def em_chev(x, y, s, base):
    sh = M().poly(_P(x, y, s, [(1, 0), (19, 0), (19, 9), (16, 15), (10, 20), (4, 15), (1, 9)])).get()
    inner = M().poly(_P(x, y, s, [(2.5, 1.5), (17.5, 1.5), (17.5, 9), (15, 14), (10, 18.3), (5, 14), (2.5, 9)])).get()
    raise_(sh & ~inner, 2.0, "chrome", base, 1.0, 0.8); raise_(inner, 1.2, "paint_y", base, 0.8, 0.8)
    cv = M().poly(_P(x, y, s, [(2, 13), (10, 5), (18, 13), (18, 16.5), (10, 8.5), (2, 16.5)])).get() & inner
    raise_(cv, 2.2, "chrome", base, 1.0, 0.8)


def em_dash(x, y, s, base):
    o = M().poly(_P(x, y, s, [(5, 3), (21, 3), (17, 17), (1, 17)])).get()
    i = M().poly(_P(x, y, s, [(6.3, 4.5), (19.2, 4.5), (16, 15.5), (3, 15.5)])).get()
    raise_(o & ~i, 2.0, "chrome", base, 1.0, 0.8); raise_(i, 1.0, "paint_r", base, 0.6, 0.8)
    k = -4.0 / 14.0
    for yy in (8.0, 11.5):
        l0, r0 = 5 + k * (yy - 3) + 1.0, 21 + k * (yy - 3) - 1.0
        l1, r1 = l0 + k * 1.5, r0 + k * 1.5
        ln = M().poly(_P(x, y, s, [(l0, yy), (r0, yy), (r1, yy + 1.5), (l1, yy + 1.5)])).get() & i
        raise_(ln, 2.0, "chrome", base, 1.0, 0.8)


def em_merc(x, y, s, base):
    c = 10 * s
    o, i = _circ(x + c, y + c, 10 * s), _circ(x + c, y + c, 8.8 * s)
    raise_(o & ~i, 1.6, "chrome", base, 1.0, 0.8); raise_(i, 0.8, "blackp", base, 0.6, 0.8)
    m = M().poly(_P(x, y, s, [(4.5, 14.5), (4.5, 6), (6.5, 6), (10, 10.5), (13.5, 6), (15.5, 6), (15.5, 14.5), (13.5, 14.5),
                              (13.5, 9.5), (10, 13.5), (6.5, 9.5), (6.5, 14.5)])).get()
    raise_(m & i, 2.0, "chrome", base, 1.0, 0.8)


def em_mast(x, y, s, base):
    o = M().rrect(x + 1 * s, y + 1 * s, 18 * s, 18 * s, 4 * s).get(); i = M().rrect(x + 2.5 * s, y + 2.5 * s, 15 * s, 15 * s, 3 * s).get()
    raise_(o & ~i, 2.0, "chrome", base, 1.0, 0.8); raise_(i, 0.8, "blackp", base, 0.5, 0.8)
    sun = _circ(x + 10 * s, y + 10 * s, 6.5 * s) & i
    for gy in (11, 13, 15): sun &= ~(d.YY == int(round(y + gy * s)))
    raise_(sun, 1.6, "paint_o", base, 0.7, 0.8)


# ------------------------------------------------------------------ the lockups
EMB = 18                 # an emblem's height in a lockup
MODEL_GAP = 3


def _sh_dash(r): return (8 - r) // 3
def _sh_mast(r): return int(round((6 - r) / 3.0))


SPEC = {
    "chevalier": dict(word="CHEVALIER", G=G_CHEV, track=1, shear=None, shear_px=0, emblem=em_chev, ew=EMB, mat="paint_y", model_mat="paint_y"),
    "dash": dict(word="DASH", G=G_DASH, track=2, shear=_sh_dash, shear_px=2, emblem=em_dash, ew=int(EMB * 21 / 20), mat="paint_w", model_mat="paint_w"),
    "mercia": dict(word="MERCIA", G=G_MERC, track=3, shear=None, shear_px=0, emblem=em_merc, ew=EMB, mat="alu", model_mat="paint_c"),
    "masterson": dict(word="MASTERSON", G=G_MAST, track=1, shear=_sh_mast, shear_px=2, emblem=em_mast, ew=EMB, mat="sunset", model_mat="paint_o"),
    "franklin": dict(word="FRANKLIN", G=G_FRANK, track=2, shear=None, shear_px=0, emblem=None, ew=0, mat="paint_w", model_mat="paint_w"),
}
FR_H, FR_BLOCK = 14, 14  # Franklin's badge: its height and the F block's width


def _franklin_size():
    ww, _ = word_size("FRANKLIN", G_FRANK, 2)
    return FR_BLOCK + 1 + 4 + ww + 4, FR_H


def size(brand, model="", form="h", sub=""):
    S = SPEC[brand]
    model = (model + " " + sub).strip() if sub else model
    mw = text_w(model, "35") if model else 0
    if brand == "franklin":
        bw, bh = _franklin_size()
        return max(bw, mw), bh + ((MODEL_GAP + 5) if model else 0)
    ww, wh = word_size(S["word"], S["G"], S["track"], S["shear_px"])
    block_h = wh + ((MODEL_GAP + 5) if model else 0)
    if form == "h":
        return S["ew"] + 5 + max(ww, mw), max(EMB, block_h)
    return max(S["ew"], ww, mw), EMB + 3 + block_h


def _franklin(x, y, base):
    bw, bh = _franklin_size()
    outer = M().rrect(x, y, bw, bh, 2).get(); inner = M().rrect(x + 1, y + 1, bw - 2, bh - 2, 1).get()
    raise_(outer & ~inner, 2.0, "chrome", base, 1.0, 0.8); raise_(inner, 1.2, "v_patrol", base, 0.6, 0.8)
    div = M().rect(x + FR_BLOCK, y + 1, 1, bh - 2).get()
    raise_(div, 2.0, "chrome", base, 1.0, 0.5)
    fx, fy = x + 4, y + 3
    f = M().rect(fx, fy, 3, 8).get() | M().rect(fx, fy, 7, 2).get() | M().rect(fx, fy + 3, 5, 2).get()
    raise_(f, 2.0, "paint_w", base, 0.4, 0.4)
    wm = word_mask(x + FR_BLOCK + 1 + 4, y + (bh - 7) // 2, "FRANKLIN", G_FRANK, 2)
    d.paint(wm, "paint_w", flatlight=True)


def model_text(model, sub, x, y, mat, align="l"):
    """the model's name in the brand's colour; a performance tag after it (5.0, V8, 4X4, EFI) in red"""
    full = (model + " " + sub).strip() if sub else model
    x0 = x - text_w(full, "35") // 2 if align == "c" else x
    if model: text(model, x0, y, mat)
    if sub: text(sub, x0 + (text_w(model + " ", "35") if model else 0), y, "paint_r")


def draw(brand, x, y, model="", form="h", base=None, sub=""):
    """the lockup with its top left at (x, y)"""
    S = SPEC[brand]
    full = (model + " " + sub).strip() if sub else model
    if base is None: base = float(d.h[min(d.H - 1, y + 4), min(d.W - 1, x + 4)])
    W, H = size(brand, model, form, sub)
    if brand == "franklin":
        bw, bh = _franklin_size()
        _franklin(x + (W - bw) // 2, y, base)
        if full: model_text(model, sub, x + W // 2, y + bh + MODEL_GAP, S["model_mat"], align="c")
        return W, H
    ww, wh = word_size(S["word"], S["G"], S["track"], S["shear_px"])
    block_h = wh + ((MODEL_GAP + 5) if full else 0)
    s = EMB / 20.0
    if form == "h":
        S["emblem"](x, y + (H - EMB) // 2, s, base)
        tx, ty = x + S["ew"] + 5, y + (H - block_h) // 2
        wx = tx
    else:
        S["emblem"](x + (W - S["ew"]) // 2, y, s, base)
        ty = y + EMB + 3; tx = x + W // 2; wx = x + (W - ww) // 2
    m = word_mask(wx, ty, S["word"], S["G"], S["track"], S["shear"])
    if S["mat"] == "sunset":
        top = m & (d.YY < ty + 3)
        raise_(top, 1.0, "paint_y", base, 0.8); raise_(m & ~top, 1.0, "paint_o", base, 0.8); drop(m, 0.5)
    else:
        raise_(m, 1.2, S["mat"], base, 1.0 if S["mat"] in ("chrome", "alu") else 0.85, 0.35 if S["mat"] == "alu" else 0.5, shadow=0.5)
        if S["mat"] == "alu": d.flatlight[m] = True     # polished alloy: lit flat, it never goes dark like chrome
    if full:
        model_text(model, sub, tx, ty + wh + MODEL_GAP, S["model_mat"], "l" if form == "h" else "c")
    return W, H




