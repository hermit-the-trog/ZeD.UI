"""The handful of scipy.ndimage calls the pixel engine makes, in plain numpy, for a machine without scipy.

Same results as scipy (checked against the shipped plates, pixel for pixel): the exact Euclidean distance transform,
the Gaussian filters (truncate 4, mode 'reflect', one axis after another in the input's dtype), binary dilation and
hole filling (and erosion, for the radio faces from ../physpx). engine.py, dashlib.py and export_lua.py import it only when scipy is missing.
"""
import numpy as np


def distance_transform_edt(mask):
    """for every True pixel, the exact distance to the nearest False one (float64), as scipy does"""
    m = np.asarray(mask).astype(bool)
    h, w = m.shape
    big = h + w + 2
    # down each column: the distance to the nearest False above or below (an integer)
    g = np.where(m, big, 0).astype(np.int64)
    for y in range(1, h):
        g[y] = np.where(m[y], np.minimum(g[y], g[y - 1] + 1), 0)
    for y in range(h - 2, -1, -1):
        g[y] = np.minimum(g[y], g[y + 1] + 1)
    g2 = np.where(g >= big, np.int64(big) ** 2 * 4, g * g)
    # along each row: min over dx of g2(x + dx) + dx^2, widening dx until it cannot win anywhere
    d2 = g2.copy()
    dx = 1
    while dx < w:
        dd = dx * dx
        if dd > d2.max(): break
        d2[:, dx:] = np.minimum(d2[:, dx:], g2[:, :-dx] + dd)
        d2[:, :-dx] = np.minimum(d2[:, :-dx], g2[:, dx:] + dd)
        dx += 1
    return np.sqrt(d2.astype(np.float64))


def _kernel(sigma, truncate=4.0):
    radius = int(truncate * float(sigma) + 0.5)
    x = np.arange(-radius, radius + 1, dtype=np.float64)
    phi = np.exp(-0.5 / (float(sigma) * float(sigma)) * x ** 2)
    return phi / phi.sum(), radius


def gaussian_filter1d(a, sigma, axis=-1, truncate=4.0):
    a = np.asarray(a)
    if sigma <= 0: return a.copy()
    k, r = _kernel(sigma, truncate)
    src = np.moveaxis(a, axis, -1).astype(np.float64)
    n = src.shape[-1]
    # scipy 'reflect': d c b a | a b c d | d c b a
    idx = np.arange(-r, n + r)
    period = 2 * n
    idx = np.mod(idx, period)
    idx = np.where(idx >= n, period - 1 - idx, idx)
    ext = src[..., idx]
    out = k[r] * ext[..., r:r + n]
    for j in range(r, 0, -1):                       # scipy's order: the far taps first
        out = out + k[r + j] * (ext[..., r + j:r + j + n] + ext[..., r - j:r - j + n])
    out = out.astype(a.dtype if np.issubdtype(a.dtype, np.floating) else np.float64)
    return np.moveaxis(out, -1, axis)


def gaussian_filter(a, sigma, truncate=4.0):
    a = np.asarray(a)
    sig = sigma if isinstance(sigma, (tuple, list)) else [sigma] * a.ndim
    out = a
    for ax, s in enumerate(sig):
        if s > 0: out = gaussian_filter1d(out, s, axis=ax, truncate=truncate)
    return out if out is not a else a.copy()


def binary_dilation(mask, structure=None, iterations=1):
    m = np.asarray(mask).astype(bool)
    st = np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]], bool) if structure is None else np.asarray(structure).astype(bool)
    sh, sw = st.shape
    cy, cx = sh // 2, sw // 2
    h, w = m.shape
    for _ in range(max(1, iterations)):
        out = np.zeros_like(m)
        for oy in range(sh):
            for ox in range(sw):
                if not st[oy, ox]: continue
                dy, dx = oy - cy, ox - cx
                # out[y, x] |= m[y - dy, x - dx]  (scipy mirrors the structure: same for the symmetric ones used here)
                ys0, ys1 = max(0, dy), min(h, h + dy)
                xs0, xs1 = max(0, dx), min(w, w + dx)
                out[ys0:ys1, xs0:xs1] |= m[ys0 - dy:ys1 - dy, xs0 - dx:xs1 - dx]
        m = out
    return m


def binary_fill_holes(mask):
    """True where the mask is, plus every False region not joined (4-way) to the edge"""
    m = np.asarray(mask).astype(bool)
    bg = ~m
    reach = np.zeros_like(m)
    reach[0, :] = bg[0, :]; reach[-1, :] = bg[-1, :]; reach[:, 0] |= bg[:, 0]; reach[:, -1] |= bg[:, -1]
    while True:
        grow = binary_dilation(reach) & bg
        if (grow == reach).all(): break
        reach = grow
    return ~reach


def binary_erosion(mask, structure=None, iterations=1):
    """scipy's erosion with border_value 0: a pixel stays only if every pixel under the structure is set (outside = unset)"""
    m = np.asarray(mask).astype(bool)
    st = np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]], bool) if structure is None else np.asarray(structure).astype(bool)
    sh, sw = st.shape
    cy, cx = sh // 2, sw // 2
    h, w = m.shape
    for _ in range(max(1, iterations)):
        out = np.ones_like(m)
        for oy in range(sh):
            for ox in range(sw):
                if not st[oy, ox]: continue
                dy, dx = oy - cy, ox - cx
                sh_ = np.zeros_like(m)
                ys0, ys1 = max(0, -dy), min(h, h - dy)
                xs0, xs1 = max(0, -dx), min(w, w - dx)
                sh_[ys0:ys1, xs0:xs1] = m[ys0 + dy:ys1 + dy, xs0 + dx:xs1 + dx]
                out &= sh_
        m = out
    return m


def install_as_scipy():
    """let `from scipy import ndimage` find this module too (../physpx, which the radio faces are built with)"""
    import sys
    import types
    if "scipy" in sys.modules and hasattr(sys.modules["scipy"], "ndimage"): return
    sc = types.ModuleType("scipy")
    sc.ndimage = sys.modules[__name__]
    sys.modules["scipy"] = sc
    sys.modules["scipy.ndimage"] = sys.modules[__name__]
