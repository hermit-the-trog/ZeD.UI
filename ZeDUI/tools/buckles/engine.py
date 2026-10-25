"""ZeD buckle engine v3 — 58x40 native, Project Zomboid item-icon style.

A buckle is a height field. Plates, relief emblems, engravings and scroll ribbons all write heights;
render() lights the field from the top left, darkens the recesses (antique patina), brightens the
high points (buffed), drops a 1px cast shadow down-right of anything raised, quantizes each material
to its ramp (sampled from vanilla's medals, coins and badges), then adds a near-black outline and a
soft contact shadow.

Canvas: plate inside x 1..55, y 1..37 (55x37, odd so emblems can have a centre column at x=28),
outline ring at x 0/56, y 0/38, contact shadow at x 57 / y 39.  Centre (28, 19).
"""
import math
import numpy as np
from scipy import ndimage as ndi
from PIL import Image, ImageDraw

W, H = 58, 40
CX, CY = 28, 19
SS = 8                     # supersample for shape masks


def hx(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


# ramps dark -> light. Index 0 is patina (only recesses reach it), the top index is the specular glint.
RAMPS = {
    # pale yellow brass: vanilla's gold medal + sheriff badge
    "brass":  ["#2f2810", "#4a4020", "#665a2a", "#857639", "#a5944d", "#c4b468", "#ddd08e", "#f2ebc0"],
    # real gold: vanilla's gold ring, pushed warmer so it never reads as brass
    "gold":   ["#3a2208", "#5f3a0e", "#875717", "#ad7721", "#cf9a2e", "#e9bb45", "#f8d977", "#fff3c0"],
    # gold plate: bright lemon yellow, thinner and flatter than the real thing
    "goldplate": ["#3b2f0d", "#5d4a15", "#82691f", "#a6892b", "#c5a93c", "#ddc456", "#efdc82", "#fdf3c4"],
    # silver plate: vanilla's police badge, cool and bright
    "silver": ["#232428", "#393b41", "#55585f", "#73767e", "#94979e", "#b6b9bf", "#d8dade", "#f7f8fa"],
    # steel: blue grey, colder and darker than silver
    "steel":  ["#1b2128", "#2b343e", "#3f4b57", "#566472", "#6f7e8c", "#8b9aa7", "#adbac5", "#d7e0e8"],
    # copper
    "copper": ["#2a140d", "#4a2416", "#6a3520", "#8a482b", "#a85d39", "#c27a50", "#dc9f78", "#f2cdb0"],
    # black iron: blackened metal, only the high points catch light
    "iron":   ["#0e0e10", "#17181b", "#202226", "#2b2e33", "#383c42", "#4a4f56", "#666c74", "#959ba2"],
    # pewter: vanilla's silver medal (warm grey), extended both ways
    "pewter": ["#29282a", "#3e3d3b", "#55534d", "#6b6960", "#858277", "#a19e92", "#c3c1b6", "#e6e5de"],
    # bronze: vanilla's bronze trophy
    "bronze": ["#311f0f", "#53341a", "#6f4a24", "#8a612f", "#a3793d", "#bd954f", "#d8b574", "#f0d9a8"],
    # enamels: vanilla's medal ribbon red; turquoise for the stone
    "red":    ["#3a1212", "#5e1e1e", "#832f2f", "#a53d3d", "#c84848", "#e06464", "#f69090", "#ffc0b8"],
    "turq":   ["#103236", "#1b4e52", "#2a7275", "#3c9592", "#5bb5ab", "#8ad3c6", "#c4ece2", "#f0fffa"],
    # enamels for the veteran's shield and the gym sign: navy blue, white enamel (warm, so it sits with the metals)
    "blue":   ["#0c1430", "#14204a", "#1d2e66", "#283f84", "#3652a2", "#4d6bbd", "#7590d4", "#b4c6ee"],
    "white":  ["#4a4740", "#6b675d", "#8d897d", "#aeaa9c", "#cbc7b8", "#e0dccd", "#efebdf", "#fbf9f2"],
    "black":  ["#121110", "#1b1a18", "#252321", "#302e2b", "#3c3a36", "#4a4743", "#5c5954", "#7a7670"],
}
RAMPS = {k: [hx(c) for c in v] for k, v in RAMPS.items()}
MATS = list(RAMPS)
OUTLINE = (27, 23, 20)
MAT_OFFSET = {"red": -0.20, "black": -0.05, "turq": 0.02, "blue": -0.12, "white": 0.10}     # enamel sits darker and flatter than metal
RAISED_BOOST = {"iron": 0.16}                                   # blackened metal: the worn high points shine

# ------------------------------------------------------------------ 3x5 pixel font, variable width
FONT = {
    "A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"],
    "C": ["011", "100", "100", "100", "011"], "D": ["110", "101", "101", "101", "110"],
    "E": ["111", "100", "110", "100", "111"], "F": ["111", "100", "110", "100", "100"],
    "G": ["011", "100", "101", "101", "011"], "H": ["101", "101", "111", "101", "101"],
    "I": ["111", "010", "010", "010", "111"], "K": ["101", "101", "110", "101", "101"],
    "L": ["100", "100", "100", "100", "111"], "M": ["10001", "11011", "10101", "10001", "10001"],
    "N": ["1001", "1101", "1011", "1001", "1001"], "O": ["010", "101", "101", "101", "010"],
    "P": ["110", "101", "110", "100", "100"], "R": ["110", "101", "110", "101", "101"],
    "S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"],
    "U": ["101", "101", "101", "101", "111"], "V": ["101", "101", "101", "101", "010"],
    "W": ["10001", "10001", "10101", "10101", "01010"], "X": ["101", "101", "010", "101", "101"],
    "Y": ["101", "101", "010", "010", "010"],
    "0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
    "2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "011", "001", "111"],
    "4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "110"],
    "6": ["011", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
    "8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "110"],
    ".": ["0", "0", "0", "0", "1"], "&": ["010", "101", "010", "101", "011"], "'": ["1", "1", "0", "0", "0"], " ": ["00", "00", "00", "00", "00"],
}


def text_w(t):
    return sum(len(FONT[c][0]) + 1 for c in t) - 1


def text_mask(t, x, y):
    m = np.zeros((H, W), bool); cx = x
    for c in t:
        g = FONT[c]
        for ry, row in enumerate(g):
            for rx, b in enumerate(row):
                if b == "1" and 0 <= cx + rx < W and 0 <= y + ry < H: m[y + ry, cx + rx] = True
        cx += len(g[0]) + 1
    return m


# ------------------------------------------------------------------ shape masks (native coords, supersampled)
class Mask:
    """Draw in native pixel coordinates (pixel (x,y) covers [x,x+1)x[y,y+1)); coverage >= thr becomes True."""

    def __init__(s):
        s.im = Image.new("L", (W * SS, H * SS), 0); s.d = ImageDraw.Draw(s.im)

    def _p(s, pts): return [(x * SS, y * SS) for x, y in pts]

    def poly(s, pts, v=255): s.d.polygon(s._p(pts), fill=v); return s

    def rect(s, x, y, w, h, v=255): s.d.rectangle([x * SS, y * SS, (x + w) * SS - 1, (y + h) * SS - 1], fill=v); return s

    def ellipse(s, cx, cy, rx, ry, v=255):
        s.d.ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS - 1, (cy + ry) * SS - 1], fill=v); return s

    def line(s, pts, w, v=255):
        s.d.line(s._p(pts), fill=v, width=max(1, int(round(w * SS))), joint="curve")
        r = w * SS / 2
        for x, y in s._p(pts): s.d.ellipse([x - r, y - r, x + r, y + r], fill=v)
        return s

    def arc(s, cx, cy, rx, ry, a0, a1, w, v=255):
        pts = [(cx + rx * math.cos(math.radians(a)), cy + ry * math.sin(math.radians(a))) for a in np.linspace(a0, a1, 48)]
        return s.line(pts, w, v)

    def get(s, thr=0.5):
        a = np.asarray(s.im.resize((W, H), Image.BOX), dtype=np.float32) / 255.0
        return a >= thr


def M(): return Mask()


def pix(*cells):
    m = np.zeros((H, W), bool)
    for x, y in cells:
        if 0 <= x < W and 0 <= y < H: m[y, x] = True
    return m


def edt(mask):
    p = np.pad(mask, 1, constant_values=False)
    return ndi.distance_transform_edt(p)[1:-1, 1:-1]


# ------------------------------------------------------------------ the buckle
FIELD_H = 1.2


class Buckle:
    def __init__(s, metal, seed=7):
        s.metal = metal
        s.h = np.zeros((H, W), np.float32)
        s.mat = np.full((H, W), -1, np.int16)
        s.solid = np.zeros((H, W), bool)
        s.field = np.zeros((H, W), bool)
        s.polish = np.zeros((H, W), np.float32)     # 0 matte (stippled) .. 1 polished
        s.patina = np.zeros((H, W), bool)           # forced into the patina tone (engraved lettering, cuts)
        s.lock = {}                                  # (x,y) -> ramp index override
        s.raised = np.zeros((H, W), bool)           # anything sitting on the field
        s.rng = np.random.default_rng(seed)
        s.shadow_ok = True

    # ---- plates
    def plate(s, shape, rim=3, beads=True, stipple=0.16, rope=False):
        m = shape if isinstance(shape, np.ndarray) else shape.get()
        d = edt(m)
        h = np.zeros_like(s.h)
        # outer bevel, rim top, inner bevel, recessed field
        prof = {1: 1.5, 2: 2.3, 3: 2.15, 4: 1.45}
        if rim == 2: prof = {1: 1.6, 2: 2.2, 3: 1.45}
        for k, v in prof.items(): h[(d >= k) & (d < k + 1)] = v
        inner = d >= max(prof) + 1
        h[inner] = FIELD_H
        if beads or rope:
            ring = (d >= 2) & (d < 3)
            ys, xs = np.nonzero(ring)
            for y, x in zip(ys, xs):
                if rope:
                    # twisted rope: slanted strands, 3px repeat along both axes
                    if (x + 2 * y) % 3 == 0: h[y, x] += 0.6
                    elif (x + 2 * y) % 3 == 1: h[y, x] += 0.2
                elif (x + y) % 2 == 0: h[y, x] += 0.55
        s.h[m] = h[m]; s.mat[m] = MATS.index(s.metal); s.solid |= m
        s.field = inner.copy()
        s.polish[m & ~inner] = 1.0
        if stipple:
            pits = (s.rng.random((H, W)) < 0.05) & inner
            s.h[pits] -= stipple * 1.25
        s.plate_mask = m
        return s

    # ---- relief: a mask raised above what is under it, with a rounded shoulder
    def relief(s, mask, height=1.5, bevel=1.4, on=None, mat=None, polish=0.85, flat=False, pyramid=False):
        if isinstance(mask, Mask): mask = mask.get()
        if not mask.any(): return s
        d = edt(mask)
        if pyramid: prof = 0.35 + d / max(d.max(), 1) * height
        else: prof = height if flat else np.minimum(d / bevel, 1.0) ** 0.6 * height
        base = FIELD_H if on is None else (s.h if on == "current" else on)
        newh = (base + prof) if np.isscalar(base) else base + prof
        s.h = np.where(mask, np.maximum(s.h, newh) if on is None else newh, s.h).astype(np.float32)
        s.mat[mask] = MATS.index(mat or s.metal); s.solid |= mask
        s.polish[mask] = polish
        s.patina[mask] = False
        s.raised |= mask
        return s

    def cylinder(s, x0, y0, w, h, height=1.8, axis="v", on=None, mat=None, polish=0.9, mask=None):
        """a round body (silo, barrel, handle): height follows a half-circle across its width"""
        yy, xx = np.mgrid[0:H, 0:W]
        if axis == "v":
            t = (xx + 0.5 - (x0 + w / 2)) / (w / 2)
        else:
            t = (yy + 0.5 - (y0 + h / 2)) / (h / 2)
        box = (xx >= x0) & (xx < x0 + w) & (yy >= y0) & (yy < y0 + h)
        if mask is not None: box &= mask
        prof = np.sqrt(np.clip(1 - t ** 2, 0, 1)) * height
        base = FIELD_H if on is None else (s.h if on == "current" else on)
        s.h = np.where(box, base + prof, s.h).astype(np.float32)
        s.mat[box] = MATS.index(mat or s.metal); s.solid |= box; s.polish[box] = polish; s.raised |= box
        return box

    def dome(s, cx, cy, rx, ry, height=1.8, on=None, mat=None, polish=1.0):
        """a cabochon / ball: height follows the ellipse profile, not a shoulder"""
        yy, xx = np.mgrid[0:H, 0:W]
        r2 = ((xx + 0.5 - cx) / rx) ** 2 + ((yy + 0.5 - cy) / ry) ** 2
        mask = r2 <= 1.0
        prof = np.sqrt(np.clip(1 - r2, 0, 1)) * height
        base = FIELD_H if on is None else (s.h if on == "current" else on)
        s.h = np.where(mask, (base + prof), s.h).astype(np.float32)
        s.mat[mask] = MATS.index(mat or s.metal); s.solid |= mask; s.polish[mask] = polish; s.raised |= mask
        return mask

    # ---- engrave: cut lines into whatever is there; cuts fill with patina
    def cut(s, mask, depth=0.7, patina=True):
        if isinstance(mask, Mask): mask = mask.get(0.5)
        s.h[mask] -= depth
        if patina: s.patina |= mask
        return s

    def paint(s, mask, mat):
        """recolour (enamel fill) without changing height"""
        if isinstance(mask, Mask): mask = mask.get()
        s.mat[mask & s.solid] = MATS.index(mat); return s

    # ---- scroll ribbon: band with folded ends and notched tails
    def ribbon(s, word, y=28, cx=CX, style="metal", pad=3, letters="cut", tails=True, mat=None, tail_len=4):
        tw = text_w(word); bw = tw + 2 * pad
        if bw % 2 == 0: bw += 1                    # odd width so it centres on the centre column
        bx = cx - bw // 2
        band = M().rect(bx, y, bw, 7).get()
        if mat: rmat = mat
        elif style == "metal": rmat = getattr(s, "ribbon_metal", None) or s.metal
        else: rmat = style
        if tails:
            for side in (-1, 1):
                fx = bx - 1 if side < 0 else bx + bw          # the fold column next to the band
                fold = pix(*[(fx, y + r) for r in range(1, 8)]) | pix(*[(fx - side, y + r) for r in range(2, 8)])
                tx0 = fx - side * 2
                tail = np.zeros((H, W), bool)
                for r in range(2, 9):
                    for k in range(tail_len):
                        tail |= pix((tx0 - side * k, y + r))
                # V notch at the free end
                nx = tx0 - side * (tail_len - 1)
                tail &= ~pix((nx, y + 4), (nx, y + 5), (nx, y + 6), (nx + side, y + 5))
                s.relief(tail, height=1.35, bevel=1.0, on=FIELD_H, mat=rmat, polish=0.6)
                s.relief(fold, height=1.0, bevel=1.0, on=FIELD_H, mat=rmat, polish=0.2, flat=True)
        s.relief(band, height=1.75, bevel=1.2, on=FIELD_H, mat=rmat, polish=1.0)
        tx = cx - tw // 2
        tm = text_mask(word, tx, y + 1)
        if letters == "cut":
            s.cut(tm, depth=0.45)
        else:                                       # raised metal letters on an enamel band
            s.relief(tm, height=0.45, bevel=0.6, on="current", mat=letters, polish=1.0, flat=True)
        s.ribbon_box = (bx, y, bw)
        return s

    # ---- render
    def render(s, light=(-1.0, -1.25, 1.35), debug=False):
        h = s.h.astype(np.float64)
        hh = np.where(s.solid, h, 0.0)
        gy, gx = np.gradient(hh)
        k = 1.0
        n = np.dstack([-gx * k, -gy * k, np.ones_like(hh)])
        n /= np.linalg.norm(n, axis=2, keepdims=True)
        L = np.array(light, float); L /= np.linalg.norm(L)
        diff = np.clip(n @ L, 0, 1)
        Hv = L + np.array([0, 0, 1.0]); Hv /= np.linalg.norm(Hv)
        spec = np.clip(n @ Hv, 0, 1) ** 28
        flat = float(np.array([0, 0, 1.0]) @ L)
        blur = ndi.gaussian_filter(hh, 1.1)
        cav = blur - hh
        shade = 0.50 + 0.62 * (diff - flat) + 0.55 * spec * (0.35 + 0.65 * s.polish)
        shade -= 0.55 * np.clip(cav, 0, None)            # patina in the recesses
        shade += 0.22 * np.clip(-cav, 0, None)           # buffed high points
        shade += 0.07 * (hh - 2.0)                       # higher reads a touch brighter
        # cast shadow: anything 0.6+ higher up-left of a pixel throws a shadow on it
        up1 = np.roll(np.roll(hh, 1, 0), 1, 1); up2 = np.roll(np.roll(hh, 2, 0), 2, 1)
        sh = ((up1 - hh) > 0.6) | ((up2 - hh) > 1.4)
        shade -= 0.16 * sh
        open_field = s.field & ~s.raised
        shade -= 0.11 * open_field
        shade += 0.06 * (s.raised & (s.polish > 0.7))
        for mi, name in enumerate(MATS):
            if name in MAT_OFFSET: shade[s.mat == mi] += MAT_OFFSET[name]
            if name in RAISED_BOOST: shade[(s.mat == mi) & s.raised & ~s.patina] += RAISED_BOOST[name]
        n_r = len(next(iter(RAMPS.values())))
        idx = np.clip(np.round(shade * (n_r - 1)), 1, n_r - 1).astype(int)
        idx[s.patina] = np.minimum(idx[s.patina], 1)
        idx[s.patina & (cav > 0.15)] = 0
        for (x, y), v in s.lock.items(): idx[y, x] = v
        img = np.zeros((H, W, 4), np.uint8)
        for mi, name in enumerate(MATS):
            sel = s.solid & (s.mat == mi)
            if not sel.any(): continue
            ramp = np.array(RAMPS[name], np.uint8)
            img[sel, :3] = ramp[idx[sel]]; img[sel, 3] = 255
        # outline: transparent pixels 4-adjacent to the solid
        sol = s.solid
        nb = np.zeros_like(sol)
        nb[1:, :] |= sol[:-1, :]; nb[:-1, :] |= sol[1:, :]; nb[:, 1:] |= sol[:, :-1]; nb[:, :-1] |= sol[:, 1:]
        ring = nb & ~sol
        img[ring, :3] = OUTLINE; img[ring, 3] = 255
        # contact shadow 1px down-right of the outlined shape
        if s.shadow_ok:
            o = sol | ring
            dr = np.zeros_like(o); dr[1:, 1:] = o[:-1, :-1]
            shd = dr & ~o
            img[shd, :3] = (0, 0, 0); img[shd, 3] = 90
        s.idx = idx
        return Image.fromarray(img, "RGBA")


# ------------------------------------------------------------------ plate shapes (inside the outline ring)
def shape_rect(corner="chamfer", r=4):
    m = M()
    x0, y0, x1, y1 = 1, 1, 56, 38                      # exclusive right/bottom
    if corner == "chamfer":
        m.poly([(x0 + r, y0), (x1 - r, y0), (x1, y0 + r), (x1, y1 - r), (x1 - r, y1), (x0 + r, y1), (x0, y1 - r), (x0, y0 + r)])
    elif corner == "round":
        m.d.rounded_rectangle([x0 * SS, y0 * SS, x1 * SS - 1, y1 * SS - 1], radius=r * SS, fill=255)
    else:
        m.rect(x0, y0, x1 - x0, y1 - y0)
    return m


def shape_cushion(r=9):
    return shape_rect("round", r)


def shape_octagon(r=9):
    return shape_rect("chamfer", r)


def shape_concave(r=5.5):
    """western cut: a rectangle with quarter-round bites out of the corners"""
    m = shape_rect("square")
    for cx, cy in ((1, 1), (56, 1), (1, 38), (56, 38)): m.ellipse(cx, cy, r, r, v=0)
    return m


def shape_arch():
    """flat bottom, arched top, like a park sign"""
    return M().ellipse(28.5, 13, 27.5, 12).rect(1, 13, 55, 25)


def shape_hex():
    """a hex nut lying on its side"""
    return M().poly([(9, 1), (48, 1), (56, 19.5), (48, 38), (9, 38), (1, 19.5)])


def shape_oval():
    return M().ellipse(28.5, 19.5, 27.5, 18.5)


def shape_round(r=18.5):
    return M().ellipse(28.5, 19.5, r, r)


def shape_shield():
    # police shield: flat top with clipped corners, straight sides, pointed bottom; 39 wide x 37 tall
    return M().poly([(11, 1), (46, 1), (48, 3), (48, 19), (45, 27), (38, 33), (28.5, 38), (19, 33), (12, 27), (9, 19), (9, 3)])
