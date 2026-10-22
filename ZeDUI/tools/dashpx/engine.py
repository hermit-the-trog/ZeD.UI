"""ZeD dashboard pixel engine — the buckles' method at dashboard size.

A dashboard is a height field (toward the viewer) with a material per pixel. render() lights it from the
windshield (top, a little left, toward the driver), casts real height-field shadows (the cluster brow
shades the dials), darkens recesses, then quantizes every material to its own ramp: no blending
between materials, no dithering. Chrome is lit by what it reflects (sky above, dark cabin ahead,
floor below), not by the lamp. Printed markings are a material too, so they sit in the same light.
Lit lamps and display segments are 'emit' pixels: drawn as is, on top.

Native resolution: one pixel per screen pixel at 1080p (the belt's density), whole multiples above.
"""
import math
import colorsys
import numpy as np
try:
    from scipy import ndimage as ndi
except ImportError:          # no scipy here: the same calls in plain numpy (ndi_np.py)
    import ndi_np as ndi
from PIL import Image, ImageDraw

SS = 4


def hx(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def ramp_from(base, n=8, at=4, dark=0.22, light=1.55, shift=0.025, sat_dark=1.08, sat_light=0.82):
    """a pixel-art ramp around a base colour: shadows cooler and a touch richer, highlights warmer and paler"""
    r, g, b = [v / 255 for v in hx(base)]
    hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
    out = []
    for i in range(n):
        t = (i - at) / max(at, n - 1 - at)                     # -1 .. 1
        if t < 0:
            L = ll * (1 + t * (1 - dark)); S = min(1, ss * (1 + (-t) * (sat_dark - 1))); H = hh - shift * (-t)
        else:
            L = ll + (min(0.97, ll * light) - ll) * t; S = ss * (1 + t * (sat_light - 1)); H = hh + shift * 0.6 * t
        rr, gg, bb = colorsys.hls_to_rgb(H % 1.0, max(0, min(1, L)), max(0, min(1, S)))
        out.append((int(rr * 255 + 0.5), int(gg * 255 + 0.5), int(bb * 255 + 0.5)))
    return out


RAMPS = {
    # chrome: index by what it reflects (see render), not by diffuse light
    "chrome":  [hx(c) for c in ("#15171b", "#24272d", "#3a3e46", "#5a5f69", "#848a94", "#b3b9c2", "#dde2e8", "#ffffff")],
    "alu":     [hx(c) for c in ("#2a2c2f", "#3d4044", "#53575c", "#6b6f75", "#868a90", "#a3a7ad", "#c3c6cb", "#e6e8eb")],
    "face":    [hx(c) for c in ("#060607", "#0b0b0d", "#111214", "#17181b", "#1e2023", "#272a2e", "#34373c", "#474b51")],
    "blackp":  [hx(c) for c in ("#0a0a0b", "#121214", "#1a1a1d", "#232327", "#2d2e32", "#3a3b40", "#4b4c52", "#64656c")],
    "rubber":  [hx(c) for c in ("#09090a", "#0f0f10", "#151517", "#1b1b1e", "#222226", "#2a2a2f", "#34343a", "#404048")],
    "walnut":  [hx(c) for c in ("#140904", "#1f0f07", "#2d170b", "#3e2010", "#512b16", "#66381e", "#7f4a29", "#a06338")],
    "lampoff": [hx(c) for c in ("#1a0b09", "#26110d", "#341813", "#43201a", "#542921", "#663329", "#7a3e33", "#924c3e")],
    "paint_w": [hx(c) for c in ("#2a2a2a", "#4a4a49", "#6e6d6a", "#97958f", "#bcbab2", "#dad8cf", "#efede4", "#ffffff")],
    "paint_c": [hx(c) for c in ("#2c2618", "#4d4430", "#72674c", "#9a8f70", "#bdb393", "#d8cfae", "#ece4c4", "#fff8e0")],
    "paint_r": [hx(c) for c in ("#2a0806", "#4a0e0a", "#6e1610", "#931f16", "#b72a1e", "#d43a2a", "#ea5a44", "#ff8a70")],
    "paint_o": [hx(c) for c in ("#2e1204", "#522008", "#7a320c", "#a14612", "#c45c18", "#e07422", "#f29440", "#ffbb70")],
    "paint_y": [hx(c) for c in ("#2e2404", "#52420a", "#7a6410", "#a18718", "#c4a822", "#e0c432", "#f2da5a", "#fff08c")],
    "dymo":    [hx(c) for c in ("#050505", "#0b0b0c", "#121214", "#18181b", "#1f1f23", "#29292e", "#36363c", "#46464d")],
    "lcd":     [hx(c) for c in ("#2a3022", "#3c4432", "#505a44", "#677257", "#7d896b", "#939f80", "#a9b495", "#c0caab")],
    "paint_k": [hx(c) for c in ("#060606", "#0e0e0d", "#171715", "#21201d", "#2b2a26", "#36342f", "#423f39", "#4f4b44")],
    "lens":    [hx(c) for c in ("#050608", "#0a0c10", "#10131a", "#171b24", "#1f2530", "#2a313e", "#3a4352", "#56606f")],
}
OUTLINE = (14, 12, 11)


def add_ramp(name, base, **kw):
    RAMPS[name] = ramp_from(base, **kw)


# cabin vinyls
for nm, base in {"v_walnut": "#5c4130", "v_slate": "#4a4f57", "v_red": "#6e2a28", "v_navy": "#2c3550", "v_burgundy": "#5a2430",
                 "v_cocoa": "#4e3a2c", "v_charcoal": "#35363a", "v_beige": "#9a8a70", "v_tan": "#86704e", "v_khaki": "#6f6a4a",
                 "v_fleet": "#55585c", "v_black": "#26262a", "v_white": "#a9aaa6", "v_patrol": "#23283a", "v_firered": "#6a1e1a"}.items():
    add_ramp(nm, base)


# ------------------------------------------------------------------ fonts (1 = ink)
F35 = {
    "A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"], "C": ["011", "100", "100", "100", "011"],
    "D": ["110", "101", "101", "101", "110"], "E": ["111", "100", "110", "100", "111"], "F": ["111", "100", "110", "100", "100"],
    "G": ["011", "100", "101", "101", "011"], "H": ["101", "101", "111", "101", "101"], "I": ["111", "010", "010", "010", "111"],
    "J": ["001", "001", "001", "101", "010"], "K": ["101", "101", "110", "101", "101"], "L": ["100", "100", "100", "100", "111"],
    "M": ["10001", "11011", "10101", "10001", "10001"], "N": ["1001", "1101", "1011", "1001", "1001"], "O": ["010", "101", "101", "101", "010"],
    "P": ["110", "101", "110", "100", "100"], "Q": ["010", "101", "101", "110", "011"], "R": ["110", "101", "110", "101", "101"],
    "S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"], "U": ["101", "101", "101", "101", "111"],
    "V": ["101", "101", "101", "101", "010"], "W": ["10001", "10001", "10101", "10101", "01010"], "X": ["101", "101", "010", "101", "101"],
    "Y": ["101", "101", "010", "010", "010"], "Z": ["111", "001", "010", "100", "111"],
    "0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"], "2": ["111", "001", "111", "100", "111"],
    "3": ["111", "001", "011", "001", "111"], "4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "110"],
    "6": ["011", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"], "8": ["111", "101", "111", "101", "111"],
    "9": ["111", "101", "111", "001", "110"], ".": ["0", "0", "0", "0", "1"], "'": ["1", "1", "0", "0", "0"],
    " ": ["00", "00", "00", "00", "00"], "-": ["000", "000", "111", "000", "000"], "/": ["001", "001", "010", "100", "100"],
    "+": ["000", "010", "111", "010", "000"], "%": ["101", "001", "010", "100", "101"], "·": ["0", "0", "1", "0", "0"], "\u00b0": ["111", "101", "111", "000", "000"],   # the degree sign (the digital watches' thermometer)
    "x": ["000", "101", "010", "101", "000"], ":": ["0", "1", "0", "1", "0"],
}
# a 5x7 face for nameplates and bigger numerals
F57 = {
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"], "B": ["11110", "10001", "11110", "10001", "10001", "10001", "11110"],
    "C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"], "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "E": ["11111", "10000", "11110", "10000", "10000", "10000", "11111"], "F": ["11111", "10000", "11110", "10000", "10000", "10000", "10000"],
    "G": ["01111", "10000", "10000", "10011", "10001", "10001", "01111"], "H": ["10001", "10001", "11111", "10001", "10001", "10001", "10001"],
    "I": ["111", "010", "010", "010", "010", "010", "111"], "K": ["10001", "10010", "11100", "10010", "10001", "10001", "10001"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"], "M": ["10001", "11011", "10101", "10001", "10001", "10001", "10001"],
    "N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"], "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"], "R": ["11110", "10001", "10001", "11110", "10010", "10001", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"], "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"], "V": ["10001", "10001", "10001", "10001", "01010", "01010", "00100"],
    "W": ["10001", "10001", "10001", "10101", "10101", "11011", "10001"], "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"], "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00110", "01000", "10000", "11111"], "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"], "5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
    "6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"], "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"], "9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
    " ": ["000", "000", "000", "000", "000", "000", "000"], ".": ["0", "0", "0", "0", "0", "0", "1"], "-": ["000", "000", "000", "111", "000", "000", "000"],
    "'": ["1", "1", "0", "0", "0", "0", "0"],
    "X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"], "Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
    "J": ["00111", "00010", "00010", "00010", "00010", "10010", "01100"], "Q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
    "/": ["00001", "00010", "00010", "00100", "01000", "01000", "10000"], "&": ["01100", "10010", "10100", "01000", "10101", "10010", "01101"],
    "\u00b7": ["0", "0", "0", "1", "0", "0", "0"],
    "\u00b0": ["0110", "1001", "1001", "0110", "0000", "0000", "0000"],
    # for the radios' character displays (the signal bars, a clock's colon, CH+)
    "|": ["1", "1", "1", "1", "1", "1", "1"], ":": ["0", "1", "0", "0", "0", "1", "0"],
    "+": ["00000", "00100", "00100", "11111", "00100", "00100", "00000"],
}
FONTS = {"35": F35, "57": F57}


def text_w(t, font="35", gap=1, scale=1):
    f = FONTS[font]; return (sum(len(f.get(c, f[" "])[0]) + gap for c in t) - gap) * scale


# ------------------------------------------------------------------ supersampled masks
class Mask:
    def __init__(s, w, h):
        s.w, s.h = w, h
        s.im = Image.new("L", (w * SS, h * SS), 0); s.d = ImageDraw.Draw(s.im)

    def _p(s, pts): return [(x * SS, y * SS) for x, y in pts]

    def poly(s, pts, v=255): s.d.polygon(s._p(pts), fill=v); return s

    def rect(s, x, y, w, h, v=255): s.d.rectangle([x * SS, y * SS, (x + w) * SS - 1, (y + h) * SS - 1], fill=v); return s

    def rrect(s, x, y, w, h, r, v=255):
        s.d.rounded_rectangle([x * SS, y * SS, (x + w) * SS - 1, (y + h) * SS - 1], radius=r * SS, fill=v); return s

    def ellipse(s, cx, cy, rx, ry, v=255):
        s.d.ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS - 1, (cy + ry) * SS - 1], fill=v); return s

    def line(s, pts, w, v=255, caps=True):
        s.d.line(s._p(pts), fill=v, width=max(1, int(round(w * SS))), joint="curve")
        if caps:
            r = w * SS / 2
            for x, y in s._p(pts): s.d.ellipse([x - r, y - r, x + r, y + r], fill=v)
        return s

    def arc(s, cx, cy, rx, ry, a0, a1, w, v=255, n=64):
        pts = [(cx + rx * math.cos(math.radians(a)), cy + ry * math.sin(math.radians(a))) for a in np.linspace(a0, a1, n)]
        return s.line(pts, w, v)

    def get(s, thr=0.5):
        a = np.asarray(s.im.resize((s.w, s.h), Image.BOX), dtype=np.float32) / 255.0
        return a >= thr


def edt(mask):
    p = np.pad(mask, 1, constant_values=False)
    return ndi.distance_transform_edt(p)[1:-1, 1:-1]


# ------------------------------------------------------------------ the canvas
class Dash:
    def __init__(s, w=800, h=172, seed=7):
        s.W, s.H = w, h
        s.h = np.zeros((h, w), np.float32)
        s.mat = np.full((h, w), -1, np.int16)
        s.names = list(RAMPS)
        s.solid = np.zeros((h, w), bool)
        s.polish = np.zeros((h, w), np.float32)
        s.tex = np.zeros((h, w), np.float32)          # material texture: grain, pebble, brushing (shade offset)
        s.dark = np.zeros((h, w), np.float32)         # extra darkening: seams, soot, visor gloom
        s.emit = np.zeros((h, w, 4), np.uint8)         # lit things, drawn as is
        s.flatlight = np.zeros((h, w), bool)          # ignore normals here (printed on a curved face, decals)
        s.noshadow = np.zeros((h, w), bool)
        s.lock = {}
        s.rng = np.random.default_rng(seed)
        s.YY, s.XX = np.mgrid[0:h, 0:w]

    def M(s): return Mask(s.W, s.H)

    def mid(s, name):
        if name not in s.names:
            s.names.append(name)
        return s.names.index(name)

    def _m(s, mask):
        return mask.get() if isinstance(mask, Mask) else mask

    # ---- forms
    def slab(s, mask, z, mat, bevel=2.0, polish=0.25, on=None, power=0.7):
        """a raised form at height z above `on` (default: absolute), shoulders rounded over `bevel` px"""
        m = s._m(mask)
        if not m.any(): return m
        d = edt(m)
        prof = np.minimum(d / max(bevel, 1e-3), 1.0) ** power * z
        base = 0.0 if on is None else (s.h if isinstance(on, str) else on)
        newh = base + prof
        s.h = np.where(m, newh, s.h).astype(np.float32)
        s.mat[m] = s.mid(mat); s.solid |= m; s.polish[m] = polish; s.tex[m] = 0
        return m

    def ramp_h(s, mask, z0, z1, axis="y", mat=None, polish=None, a0=None, a1=None):
        """set a linear height ramp across a region (a sloped face): z0 at a0, z1 at a1"""
        m = s._m(mask)
        coord = s.YY if axis == "y" else s.XX
        ys, xs = np.nonzero(m)
        if a0 is None: a0 = (ys if axis == "y" else xs).min()
        if a1 is None: a1 = (ys if axis == "y" else xs).max()
        t = np.clip((coord - a0) / max(1e-3, a1 - a0), 0, 1)
        s.h = np.where(m, z0 + (z1 - z0) * t, s.h).astype(np.float32)
        if mat: s.mat[m] = s.mid(mat); s.solid |= m
        if polish is not None: s.polish[m] = polish
        return m

    def well(s, mask, depth, mat=None, bevel=1.0, polish=None):
        """recess the region by depth below what is there, with a sloped wall"""
        m = s._m(mask)
        d = edt(m)
        prof = np.minimum(d / max(bevel, 1e-3), 1.0) * depth
        s.h = np.where(m, s.h - prof, s.h).astype(np.float32)
        if mat: s.mat[m] = s.mid(mat); s.solid |= m
        if polish is not None: s.polish[m] = polish
        return m

    def flat(s, mask, z, mat, polish=0.2):
        m = s._m(mask)
        s.h[m] = z; s.mat[m] = s.mid(mat); s.solid |= m; s.polish[m] = polish; s.tex[m] = 0
        return m

    def torus(s, cx, cy, r0, r1, z, mat, polish=1.0, on=None):
        """a ring (bezel): round section between radius r0 and r1, peak z above `on`"""
        rr = np.hypot(s.XX + 0.5 - cx, s.YY + 0.5 - cy)
        m = (rr >= r0) & (rr <= r1)
        t = (rr - (r0 + r1) / 2) / max(1e-3, (r1 - r0) / 2)
        prof = np.sqrt(np.clip(1 - t ** 2, 0, 1)) * z
        base = 0.0 if on is None else (s.h if isinstance(on, str) else on)
        s.h = np.where(m, base + prof, s.h).astype(np.float32)
        s.mat[m] = s.mid(mat); s.solid |= m; s.polish[m] = polish; s.tex[m] = 0
        return m

    def dome(s, cx, cy, rx, ry, z, mat, polish=0.8, on=None, power=0.5):
        r2 = ((s.XX + 0.5 - cx) / rx) ** 2 + ((s.YY + 0.5 - cy) / ry) ** 2
        m = r2 <= 1.0
        prof = np.clip(1 - r2, 0, 1) ** power * z
        base = 0.0 if on is None else (s.h if isinstance(on, str) else on)
        s.h = np.where(m, base + prof, s.h).astype(np.float32)
        s.mat[m] = s.mid(mat); s.solid |= m; s.polish[m] = polish; s.tex[m] = 0
        return m

    def cyl(s, x0, y0, w, h, z, mat, axis="h", polish=0.6, on=None, mask=None):
        """a round bar: across its height (axis h: a horizontal bar) or width (axis v)"""
        if axis == "h": t = (s.YY + 0.5 - (y0 + h / 2)) / (h / 2)
        else: t = (s.XX + 0.5 - (x0 + w / 2)) / (w / 2)
        m = (s.XX >= x0) & (s.XX < x0 + w) & (s.YY >= y0) & (s.YY < y0 + h)
        if mask is not None: m &= s._m(mask)
        prof = np.sqrt(np.clip(1 - t ** 2, 0, 1)) * z
        base = 0.0 if on is None else (s.h if isinstance(on, str) else on)
        s.h = np.where(m, base + prof, s.h).astype(np.float32)
        s.mat[m] = s.mid(mat); s.solid |= m; s.polish[m] = polish; s.tex[m] = 0
        return m

    def paint(s, mask, mat, polish=None, flatlight=False):
        """recolour what is there (markings, decals) without changing its height"""
        m = s._m(mask) & s.solid
        s.mat[m] = s.mid(mat); s.tex[m] = 0
        if polish is not None: s.polish[m] = polish
        if flatlight: s.flatlight |= m
        return m

    def text(s, t, x, y, mat, font="35", gap=1, raise_=0.0, align="l", flatlight=False, scale=1):
        f = FONTS[font]; w = text_w(t, font, gap, scale)
        if align == "c": x = x - w // 2
        elif align == "r": x = x - w
        m = np.zeros((s.H, s.W), bool); cx = x
        for c in t:
            g = f.get(c, f.get(c.upper(), f[" "]))
            for ry, row in enumerate(g):
                for rx, b in enumerate(row):
                    if b == "1":
                        y0, x0 = y + ry * scale, cx + rx * scale
                        m[max(0, y0):max(0, min(s.H, y0 + scale)), max(0, x0):max(0, min(s.W, x0 + scale))] = True
            cx += (len(g[0]) + gap) * scale
        if raise_:
            s.h[m] += raise_
            s.mat[m] = s.mid(mat); s.solid |= m
        else:
            s.paint(m, mat, flatlight=flatlight)
        return m

    def seam(s, mask, amount=0.55):
        """a panel gap or groove: darken (and a hair deeper)"""
        m = s._m(mask)
        s.dark[m] = np.maximum(s.dark[m], amount); s.h[m] -= 0.3
        return m

    def chrome_tone(s, mask, idx):
        if not hasattr(s, "ctone"): s.ctone = np.full((s.H, s.W), -1, np.int8)
        s.ctone[s._m(mask)] = idx

    def glow(s, mask, color, a=255):
        m = s._m(mask)
        c = hx(color) if isinstance(color, str) else color
        s.emit[m, :3] = c; s.emit[m, 3] = a
        return m

    def grain_wood(s, mask, scale=1.0, seed=3, along="x"):
        """printed walnut veneer (an 80s applique): long, nearly straight grain, fine lines, slow figure"""
        m = s._m(mask)
        r = np.random.default_rng(seed)
        y = s.YY.astype(np.float32); x = s.XX.astype(np.float32)
        if along == "y": x, y = y, x
        und = 1.3 * np.sin(x * 0.012 + seed) + 0.7 * np.sin(x * 0.037 + y * 0.015 + 1.1) + 0.35 * np.sin(x * 0.09)
        yy = (y + und) / scale
        fine = np.sin(yy * 2.05) * 0.5 + 0.5                       # ~3 px line period
        streak = ndi.gaussian_filter(r.random(s.YY.shape).astype(np.float32), (0.45, 14.0)) - 0.5
        slow = ndi.gaussian_filter(r.random(s.YY.shape).astype(np.float32), (4.0, 40.0)) - 0.5
        lines = (fine < 0.12) & (streak < 0.02)
        t = 1.6 * streak + 2.4 * slow - 0.09 * lines + 0.03 * fine
        s.tex[m] = t[m]
        return m

    def grain_pebble(s, mask, amount=0.05, seed=5):
        m = s._m(mask)
        r = np.random.default_rng(seed)
        n = r.random(s.YY.shape).astype(np.float32)
        t = np.where(n > 0.86, -amount, np.where(n < 0.06, amount, 0.0))
        s.tex[m] = t[m]
        return m

    def grain_brushed(s, mask, amount=0.07, seed=9):
        m = s._m(mask)
        r = np.random.default_rng(seed)
        rows = ndi.gaussian_filter1d(r.random(s.H).astype(np.float32), 0.7) - 0.5
        streak = ndi.gaussian_filter(r.random(s.YY.shape).astype(np.float32), (0.3, 8.0)) - 0.5
        t = amount * (rows[:, None] * 1.6 + streak * 3.0)
        s.tex[m] = t[m]
        return m

    # ---- render
    def render(s, light=(-0.45, -1.0, 0.95), outline=True, gloom=None, chrome_env="car"):
        """chrome_env: what chrome reflects. "car": sky above, the dark cabin ahead, the floor below (the dashboards).
        "room": a lit room; a face toward the viewer shows the room's middle tones, not a dark cabin (the appliances)."""
        h = s.h.astype(np.float64)
        hh = np.where(s.solid, h, h.min() if s.solid.any() else 0)
        gy, gx = np.gradient(hh)
        n = np.dstack([-gx, -gy, np.ones_like(hh)])
        n /= np.linalg.norm(n, axis=2, keepdims=True)
        n[s.flatlight] = (0, 0, 1)
        L = np.array(light, float); L /= np.linalg.norm(L)
        diff = np.clip(n @ L, 0, 1)
        flat = float(np.array([0, 0, 1.0]) @ L)
        V = np.array([0, 0, 1.0])
        Hv = L + V; Hv /= np.linalg.norm(Hv)
        spec = np.clip(n @ Hv, 0, 1) ** 30
        blur = ndi.gaussian_filter(hh, 1.4)
        cav = blur - hh
        shade = 0.52 + 0.70 * (diff - flat) + 0.55 * spec * s.polish
        shade -= 0.30 * np.clip(cav, 0, None)
        shade += 0.10 * np.clip(-cav, 0, None)
        # height-field shadows: march toward the light; a ray that hits something higher is shadowed
        lxy = np.hypot(L[0], L[1]); dx, dy = L[0] / lxy, L[1] / lxy; rise = L[2] / lxy
        sh = np.zeros_like(hh, dtype=np.float32)
        for k in range(1, 26):
            ox, oy = int(round(-dx * k)), int(round(-dy * k))
            src = np.full_like(hh, -1e9)
            ys0, ys1 = max(0, oy), min(s.H, s.H + oy); xs0, xs1 = max(0, ox), min(s.W, s.W + ox)
            if ys1 <= ys0 or xs1 <= xs0: break
            # src[y, x] = hh[y - oy, x - ox]  (the pixel k steps toward the light)
            src[ys0:ys1, xs0:xs1] = hh[ys0 - oy:ys1 - oy, xs0 - ox:xs1 - ox]
            sh = np.maximum(sh, np.clip((src - hh - rise * k - 0.35) / 1.6, 0, 1))
        sh[s.noshadow] = 0
        shade -= 0.34 * sh
        shade += s.tex
        shade -= s.dark
        if gloom is not None: shade -= gloom
        nmax = 7
        idx = np.clip(np.round(shade * nmax), 0, nmax).astype(int)
        # chrome: by reflection (n.y < 0 faces up: sky; facing the driver: dark cabin; facing down: the floor)
        ci = s.mid("chrome")
        cm = s.mat == ci
        if cm.any():
            ny = n[..., 1]; nz = n[..., 2]
            if chrome_env == "room":
                env = np.where(ny < -0.45, 7, np.where(ny < -0.18, 6, np.where(ny > 0.40, 2, np.where(ny > 0.15, 3, 4))))
            else:
                env = np.where(ny < -0.45, 7, np.where(ny < -0.18, 6, np.where(ny > 0.40, 4, np.where(ny > 0.15, 5, 2))))
            env = env + (spec > 0.55) * 2 - np.round(sh * 2).astype(int) - (cav > 0.25) * 1
            env = env - (np.abs(n[..., 0]) > 0.55) * 1
            idx[cm] = np.clip(env[cm], 0, 7)
            if hasattr(s, "ctone"):
                ct = (s.ctone >= 0) & cm
                idx[ct] = np.clip(s.ctone[ct] - np.round(sh[ct] * 2).astype(int), 0, 7)
        for (x, y), v in s.lock.items(): idx[y, x] = v
        img = np.zeros((s.H, s.W, 4), np.uint8)
        for mi, name in enumerate(s.names):
            sel = s.solid & (s.mat == mi)
            if not sel.any(): continue
            ramp = np.array(RAMPS[name], np.uint8)
            img[sel, :3] = ramp[idx[sel]]; img[sel, 3] = 255
        e = s.emit[..., 3] > 0
        img[e] = s.emit[e]
        if outline:
            sol = s.solid
            nb = np.zeros_like(sol)
            nb[1:, :] |= sol[:-1, :]; nb[:-1, :] |= sol[1:, :]; nb[:, 1:] |= sol[:, :-1]; nb[:, :-1] |= sol[:, 1:]
            ring = nb & ~sol
            img[ring, :3] = OUTLINE; img[ring, 3] = 255
        s.idx = idx; s.shadowmask = sh > 0.5
        # what the night pass (night.py) relights from: the surface's normals and hollows, the day's shade before its ramp
        s.lit_terms = {"n": n, "cav": cav, "hh": hh, "shade": shade, "env_chrome": cm}
        return Image.fromarray(img, "RGBA")
