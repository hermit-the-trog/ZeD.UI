"""MOCKUP (Oct 29 2026): the game's own brands on the machine plates (director: real brands from the game only, the
watches excepted). Four have logo art in the game and are redrawn here as pixel badges from it:
  Mass-Genfac Co.     media/textures/printMedia/logos/MassGenfacCo.png, the van and the cap: the MG monogram, slate and cream
  Lectromax           media/textures/Vehicles/vehicle_van_lectromaxshell.png: white letters in a white-ruled red box
                      (the flyer prints the same box dark)
  Knox Pack Kitchens  media/textures/printMedia/logos/KnoxPackKitchens.png: yellow on blue, the O a compass, an arrow
  ValuTech            media/textures/printMedia/logos/Valutech.png: green italic, dark outline, tall V and T
The rest (Premium Technologies, CGE, Hector Lopez, Fryers Club, US ARMY COMM.) have no logo art: wordmarks."""
import numpy as np
from scipy import ndimage as ndi

from physlib import *            # noqa: F401,F403
from engine import add_ramp, FONTS

add_ramp("mg_blue", "#3f5068")
add_ramp("mg_cream", "#e6e1cf", light=1.05)
add_ramp("lx_red", "#b5232b", light=1.05)
add_ramp("lx_white", "#f3efe8", light=1.05)
add_ramp("lx_dark", "#3a3a3c")
add_ramp("kp_blue", "#2340a0")
add_ramp("kp_yellow", "#f0d64a", light=1.05)
add_ramp("vt_green", "#3fae3a", light=1.05)
add_ramp("vt_green_hi", "#8fdc5a", light=1.05)
add_ramp("vt_dark", "#101a10")


def glyphs(t, font="57", gap=1, extra=None):
    """the text as a bool mask (h, w) in the plates' own pixel faces; `extra` = glyphs drawn here (char: rows)"""
    cols, h = [], len(FONTS[font]["A"])
    for i, c in enumerate(t):
        g = (extra or {}).get(c) or FONTS[font].get(c, FONTS[font][" "])
        a = np.array([[ch == "1" for ch in row] for row in g], bool)
        cols.append(a)
        if i < len(t) - 1: cols.append(np.zeros((h, gap), bool))
    return np.hstack(cols)


def stamp(p, m, x, y, mat):
    """paint mask `m` at (x, y), flat-lit (printed)"""
    d = p.d
    full = np.zeros((p.H, p.W), bool)
    h, w = m.shape
    full[y:y + h, x:x + w] = m[:max(0, min(h, p.H - y)), :max(0, min(w, p.W - x))]
    d.paint(full, mat, flatlight=True)
    return full


def grid(rows, key):
    return np.array([[ch == key for ch in r] for r in rows], bool)


# ------------------------------------------------------------------ Mass-Genfac Co.
MG = ["bbbbbbbbbbbbb",
      "bbbbbbbbbbbbb",
      "bbcbbbbbbbcbb",
      "bbccbbbbbccbb",
      "bbcbcbbbcbcbb",
      "bbcbbcbcbbcbb",
      "bbcbbbcbbbcbb",
      "bbcbbbbbbbcbb",
      "bbcbbbcccbcbb",
      "bbcbbbcbbbcbb",
      "bbcbbbcccccbb",
      "bbbbbbbbbbbbb",
      "bbbbbbbbbbbbb"]


def mg_monogram(p, cx, cy, on=Z_FACE, z=0.8):
    """the MG square: cream strokes on slate, an enamel badge"""
    x, y = int(cx - 6), int(cy - 6)
    d = p.d
    d.slab(rbox(d, x, y, 13, 13), z, "mg_blue", bevel=0.6, polish=0.8, on=on)
    stamp(p, grid(MG, "c"), x, y, "mg_cream")
    p.ink_rect(x, y, 13, 13, "Mass-Genfac monogram")
    return x, y, 13, 13


def mg_wordmark(p, cx, y, font="35", mat="mg_blue", align="c"):
    t = "MASS-GENFAC CO." if font == "57" else "MASS-GENFAC"
    m = glyphs(t, font)
    x = int(cx - m.shape[1] // 2) if align == "c" else int(cx)
    stamp(p, m, x, y, mat)
    p.ink_rect(x, y, m.shape[1], m.shape[0], "Mass-Genfac wordmark")
    return x, y, m.shape[1], m.shape[0]


# ------------------------------------------------------------------ Lectromax
def lectromax_badge(p, cx, cy, on=Z_FACE, box="lx_red", two_lines=True, z=0.6):
    """white letters in a white-ruled box: LECTROMAX over MANUFACTURING (the van); `box` lx_dark for the flyer's"""
    d = p.d
    l1 = glyphs("LECTROMAX", "57")
    l2 = glyphs("MANUFACTURING", "35") if two_lines else None
    w = max(l1.shape[1], l2.shape[1] if two_lines else 0) + 8
    h = 7 + 6 + (6 if two_lines else 0)
    x, y = int(cx - w // 2), int(cy - h // 2)
    d.slab(rbox(d, x, y, w, h), z, box, bevel=0.5, polish=0.75, on=on)
    rule = rbox(d, x + 1, y + 1, w - 2, h - 2) & ~rbox(d, x + 2, y + 2, w - 4, h - 4)
    d.paint(rule, "lx_white", flatlight=True)
    stamp(p, l1, x + (w - l1.shape[1]) // 2, y + 3, "lx_white")
    if two_lines: stamp(p, l2, x + (w - l2.shape[1]) // 2, y + 12, "lx_white")
    p.ink_rect(x, y, w, h, "Lectromax badge")
    return x, y, w, h


# ------------------------------------------------------------------ Knox Pack Kitchens
COMPASS_O = ["01110", "10001", "10001", "10101", "10001", "10001", "01110"]   # the O with the compass pivot
ARROW = ["000100", "000110", "111111", "000110", "000100"]   # the arrow into KITCHENS


def knoxpack_badge(p, cx, cy, on=Z_FACE, z=0.8):
    """KNOX (the O a compass) PACK over an arrow and KITCHENS: yellow on a blue enamel badge"""
    d = p.d
    a = glyphs("KNOX", "57", extra={"O": COMPASS_O})
    b = glyphs("PACK", "35")
    k = glyphs("KITCHENS", "35")
    arr = np.array([[c == "1" for c in r] for r in ARROW], bool)
    w1 = a.shape[1] + 2 + b.shape[1]
    w2 = arr.shape[1] + 2 + k.shape[1]
    w = max(w1, w2) + 6
    h = 7 + 1 + 5 + 6
    x, y = int(cx - w // 2), int(cy - h // 2)
    d.slab(rbox(d, x, y, w, h), z, "kp_blue", bevel=0.6, polish=0.8, on=on)
    rule = rbox(d, x + 1, y + 1, w - 2, h - 2) & ~rbox(d, x + 2, y + 2, w - 4, h - 4)
    d.paint(rule, "kp_yellow", flatlight=True)
    x1 = x + (w - w1) // 2
    stamp(p, a, x1, y + 3, "kp_yellow")
    stamp(p, b, x1 + a.shape[1] + 2, y + 5, "kp_yellow")
    x2 = x + (w - w2) // 2
    stamp(p, arr, x2, y + 11, "kp_yellow")
    stamp(p, k, x2 + arr.shape[1] + 2, y + 11, "kp_yellow")
    p.ink_rect(x, y, w, h, "Knox Pack badge")
    return x, y, w, h


# ------------------------------------------------------------------ ValuTech
def valutech_logo(p, cx, y, outline="vt_dark", gap=2):
    """the green italic wordmark with its dark outline, printed straight on the case. At pixel size the logo's small
    letters drown in the outline, so all eight are the 5 x 7 capitals, spaced 2 apart so the outlines stay apart"""
    m = glyphs("VALUTECH", "57", gap=gap)
    h = m.shape[0]
    sh = np.zeros((h, m.shape[1] + 2), bool)               # italic: the top leans a pixel right every third row
    for r in range(h):
        s_ = (h - 1 - r) // 3
        sh[r, s_:s_ + m.shape[1]] = m[r]
    pad = np.pad(sh, 1)
    ring = ndi.binary_dilation(pad, iterations=1) & ~pad
    x = int(cx - pad.shape[1] // 2)
    stamp(p, ring, x, y - 1, outline)
    top = pad.copy(); top[pad.shape[0] // 2 + 1:] = False
    stamp(p, pad & ~top, x, y - 1, "vt_green")
    stamp(p, top, x, y - 1, "vt_green_hi")
    p.ink_rect(x, y - 1, pad.shape[1], pad.shape[0], "ValuTech logo")
    return x, y - 1, pad.shape[1], pad.shape[0]
