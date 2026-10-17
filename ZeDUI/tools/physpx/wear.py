"""Material and wear: the passes a design runs last, after every part is in place.

Gloss on enamel (the room reflected: a brighter top, a darker foot, one band of light across it), the bands a
brushed metal throws, grime where things meet, chips knocked out of enamel near its edges, pits in chrome,
aged faces. In this engine a surface's tone is its light quantized to its own eight-step ramp, so each pass
moves a pixel one clean step up or down that ramp, never a blend. Every pass is seeded: a model always wears
the same way, and a state variant (a key down, the other unit's dial) wears exactly like its base.
"""
import numpy as np
from scipy import ndimage as ndi

from engine import edt, RAMPS, hx

RAMPS["chip"] = [hx(c) for c in ("#0b0b0c", "#121213", "#19191b", "#212124", "#2a2a2e", "#343439", "#3f3f45", "#4b4b52")]


def _noise(shape, seed, sigma):
    r = np.random.default_rng(seed)
    n = ndi.gaussian_filter(r.random(shape).astype(np.float32), sigma)
    return (n - n.min()) / max(1e-6, float(n.max() - n.min()))


def face(d, z, within=None, tol=0.05):
    """the flat face at height z (print included, since print does not change height): where chips may fall"""
    m = d.solid & (np.abs(d.h - z) < tol)
    return m & within if within is not None else m


def mat_mask(d, *names):
    m = np.zeros((d.H, d.W), bool)
    for nm in names:
        if nm in d.names: m |= d.mat == d.names.index(nm)
    return m & d.solid


def gloss(d, mask, top=0.0, foot=0.0, band=None):
    """glossy enamel reflects the room: the upper part a step brighter, the foot a step darker; `band` =
    (slope, x at the top edge, width, amount) adds one diagonal band of reflected light"""
    ys = np.nonzero(mask)[0]
    if not len(ys): return
    y0, y1 = ys.min(), ys.max()
    t = np.clip((d.YY - y0) / max(1, y1 - y0), 0, 1)
    g = top + (foot - top) * t ** 1.5
    d.tex[mask] += g[mask]
    if band:
        slope, x_top, w, a = band
        u = d.XX + (d.YY - y0) * slope
        b = mask & (np.abs(u - x_top) < w / 2)
        d.tex[b] += a


def brushed_bands(d, mask, bands):
    """horizontally brushed metal lights up in vertical bands: [(x centre, width, amount), ...]"""
    for xc, w, a in bands:
        m = mask & (np.abs(d.XX + 0.5 - xc) < w / 2)
        d.tex[m] += a


def brushed_sheen(d, mask, x_light, w_light, a_light, x_dark0, x_dark1, a_dark):
    """the light a horizontally brushed sheet throws, graded: a soft bright band round x_light, then darker and
    darker from x_dark0 to x_dark1 (the streaks thicken instead of a hard edge)"""
    x = d.XX + 0.5
    g = a_light * np.exp(-((x - x_light) / w_light) ** 2) - a_dark * np.clip((x - x_dark0) / max(1, x_dark1 - x_dark0), 0, 1)
    d.tex[mask] += g[mask].astype(np.float32)


def grime(d, mask, amount=0.25, seed=1, reach=2.0):
    """dirt where things meet: in recesses and round the foot of everything that stands proud, in patches"""
    hh = np.where(d.solid, d.h, d.h[d.solid].min() if d.solid.any() else 0).astype(np.float32)
    blur = ndi.gaussian_filter(hh, reach)
    cav = np.clip(blur - hh, 0, 1.6) / 1.6
    patch = _noise(hh.shape, seed, 3.0)
    g = amount * cav * (0.35 + 1.0 * patch)
    d.dark[mask] += g[mask]


def _field(d, seed):
    """a fixed random value per pixel position: a pass picks its pixels by position, so a state variant that only
    changes print somewhere else wears in exactly the same places"""
    return np.random.default_rng(seed).random((d.H, d.W))


def chips(d, mask, density, seed, near=2.5, mat="chip", dh=-0.3):
    """enamel chips: small spots knocked off near an edge (about `density` of the edge pixels), the dark steel
    showing through (or, for a label, the paint under it: `mat`)"""
    e = edt(mask)
    cand = mask & (e <= near) & (e >= 1)
    R = _field(d, seed); R2 = _field(d, seed + 1)
    centres = cand & (R < density)
    out = centres.copy()
    for y, x in np.argwhere(centres):
        k = int(R2[y, x] * 3)                       # 0..2 more pixels
        for j in range(k):
            dy, dx = ((0, 1), (1, 0), (1, 1), (0, -1))[(int(R2[y, x] * 97) + j) % 4]
            yy, xx = y + dy, x + dx
            if 0 <= yy < d.H and 0 <= xx < d.W and mask[yy, xx]: out[yy, xx] = True
    d.mat[out] = d.mid(mat); d.h[out] += dh; d.polish[out] = 0.1; d.tex[out] = 0; d.flatlight[out] = True
    return out


def scuffs(d, mask, density, seed, length=(3, 8), amount=0.10):
    """fine scuffs: short, nearly level hairlines a step lighter (a worn finish catching the light)"""
    R = _field(d, seed); R2 = _field(d, seed + 1); R3 = _field(d, seed + 2)
    out = np.zeros_like(mask)
    for y, x in np.argwhere(mask & (R < density)):
        L = length[0] + int(R2[y, x] * (length[1] - length[0] + 1)); slope = (R3[y, x] - 0.5) * 0.5
        for k in range(L):
            xx, yy = x + k, int(round(y + k * slope))
            if 0 <= yy < d.H and 0 <= xx < d.W and mask[yy, xx]: out[yy, xx] = True
    d.tex[out] += amount
    return out


def pits(d, mask, density, seed, tone=1):
    """pits in chrome: single dark specks (chrome is lit by what it reflects, so a pit is set as a chrome tone)"""
    out = mask & (_field(d, seed) < density)
    d.chrome_tone(out, tone)
    return out


def specks(d, mask, density, seed, amount=0.35):
    """rust and grime specks on painted or bare steel: single pixels a step or two darker"""
    out = mask & (_field(d, seed) < density)
    d.dark[out] += amount
    return out


def aged_face(d, cx, cy, r, amount=0.10, start=0.62):
    """an old dial face: a step darker toward its rim"""
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    t = np.clip((rr / r - start) / (1 - start), 0, 1)
    m = (rr <= r) & d.solid
    d.dark[m] += (amount * t ** 2)[m]


def smudge(d, mask, amount=0.06, seed=3, sigma=2.5, thresh=0.62):
    """a few soft smudges (hands at the controls): patches a step darker"""
    n = _noise((d.H, d.W), seed, sigma)
    m = mask & (n > thresh)
    d.dark[m] += amount
    return m
