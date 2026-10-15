"""ZeD main menu desk, lit. A G-buffer pixel-art renderer.

Every primitive paints a material (an albedo colour by name) plus the surface it belongs to: normal, depth,
gloss, emission, whether it may be dithered. Light is computed afterwards from a fixed rig — the desk lamp
(warm spot + halo + the bounce off its pool), the CRT (cool area light), moonlight from an off-frame window
on the right, ambient — then the frame is fitted to a 256-colour VGA palette with ordered dithering.

Coordinates: image pixels, x right, y down; z = depth toward the viewer (0 = the wall).
"""
import math, os
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

W, H = 480, 270
VPX, VPY = 240, 118


def hx(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lin(c):
    c = np.asarray(c, np.float32) / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def srgb(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


class Scene:
    def __init__(s, pal):
        s.pal = dict(pal); s.names = list(s.pal); s.idx = {n: i for i, n in enumerate(s.names)}
        s.alb = np.array([lin(hx(s.pal[n])) if s.pal[n] else (0, 0, 0) for n in s.names], np.float32)
        s.C = np.full((H, W), -1, np.int16)
        s.T = np.ones((H, W), np.float32)           # albedo multiplier (texture, print)
        s.N = np.zeros((H, W, 3), np.float32); s.N[..., 2] = 1
        s.Z = np.zeros((H, W), np.float32)
        s.G = np.zeros((H, W), np.float32)           # gloss 0..1
        s.E = np.zeros((H, W, 3), np.float32)        # emission, linear
        s.E_lamp = np.zeros((H, W, 3), np.float32)   # the part of E that belongs to the lamp
        s.D = np.ones((H, W), bool)                  # may dither
        s.SL = np.zeros((H, W), np.float32)          # shadow from the lamp, 0..1
        s.AO = np.zeros((H, W), np.float32)          # occlusion on whatever ends up there, 0..1
        s.shadows = []                               # (array, receiver) — occlusion that lands only on its receiver
        s.ctx = {"n": (0, 0, 1), "z": 0.0, "g": 0.0, "d": True, "e": None, "nf": None, "zf": None}
        s._stack = []

    # ---------------------------------------------------------------- context
    def push(s, **kw):
        s._stack.append(dict(s.ctx)); s.ctx.update(kw); return s

    def pop(s):
        s.ctx = s._stack.pop()

    class _With:
        def __init__(s, sc, kw): s.sc, s.kw = sc, kw
        def __enter__(s): s.sc.push(**s.kw); return s.sc
        def __exit__(s, *a): s.sc.pop()

    def surf(s, **kw):
        return Scene._With(s, kw)

    # ---------------------------------------------------------------- painting
    def paint(s, mask, c):
        """paint material c on mask, with the current surface context"""
        if not mask.any(): return
        ys, xs = np.nonzero(mask)
        s.C[ys, xs] = s.idx[c]
        s.T[ys, xs] = 1.0
        nf, zf = s.ctx["nf"], s.ctx["zf"]
        if nf is not None:
            n = np.asarray(nf(xs.astype(np.float32) + 0.5, ys.astype(np.float32) + 0.5), np.float32)
            if n.ndim == 1: n = np.broadcast_to(n, (len(xs), 3))
            s.N[ys, xs] = n
        else:
            s.N[ys, xs] = s.ctx["n"]
        s.Z[ys, xs] = zf(xs + 0.5, ys + 0.5) if zf is not None else s.ctx["z"]
        s.G[ys, xs] = s.ctx["g"]
        s.D[ys, xs] = s.ctx["d"]
        s.E[ys, xs] = lin(hx(s.ctx["e"])) if s.ctx["e"] else 0

    # masks (native coords, a pixel covers [x, x+1))
    @staticmethod
    def m_rect(x, y, w, h):
        m = np.zeros((H, W), bool)
        x0, y0, x1, y1 = max(0, int(x)), max(0, int(y)), min(W, int(x + w)), min(H, int(y + h))
        if x1 > x0 and y1 > y0: m[y0:y1, x0:x1] = True
        return m

    @staticmethod
    def m_poly(pts):
        """scanline fill identical to gen2's poly(): rows sampled at integer y"""
        m = np.zeros((H, W), bool)
        ys = [p[1] for p in pts]
        for yy in range(int(min(ys)), int(max(ys)) + 1):
            if not 0 <= yy < H: continue
            xs = []
            for i in range(len(pts)):
                (x1, y1), (x2, y2) = pts[i], pts[(i + 1) % len(pts)]
                if (y1 <= yy < y2) or (y2 <= yy < y1): xs.append(x1 + (yy - y1) * (x2 - x1) / (y2 - y1))
            xs.sort()
            for a, b in zip(xs[::2], xs[1::2]):
                a, b = int(round(a)), int(round(b))
                if b > a: m[yy, max(0, a):max(0, min(W, b))] = True
        return m

    @staticmethod
    def m_ellipse(cx, cy, rx, ry, half=None):
        m = np.zeros((H, W), bool)
        for yy in range(int(cy - ry), int(cy + ry) + 1):
            if not 0 <= yy < H: continue
            if half == "top" and yy > cy: continue
            if half == "bottom" and yy < cy: continue
            f = 1 - ((yy - cy) / float(ry)) ** 2 if ry else 1
            if f < 0: continue
            hw = rx * f ** 0.5
            a, b = int(round(cx - hw)), int(round(cx + hw)) + 1
            m[yy, max(0, a):max(0, min(W, b))] = True
        return m

    @staticmethod
    def m_disc(cx, cy, r):
        yy, xx = np.mgrid[0:H, 0:W]
        return (xx - cx) ** 2 + (yy - cy) ** 2 <= r * r + r * 0.5

    @staticmethod
    def m_line(x0, y0, x1, y1):
        m = np.zeros((H, W), bool); n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(int(n) + 1):
            x, y = int(round(x0 + (x1 - x0) * i / n)), int(round(y0 + (y1 - y0) * i / n))
            if 0 <= x < W and 0 <= y < H: m[y, x] = True
        return m

    # convenience painters
    def rect(s, x, y, w, h, c): s.paint(s.m_rect(x, y, w, h), c)
    def px(s, x, y, c):
        if 0 <= x < W and 0 <= y < H: s.paint(s.m_rect(x, y, 1, 1), c)
    def hline(s, x, y, w, c): s.rect(x, y, w, 1, c)
    def vline(s, x, y, h, c): s.rect(x, y, 1, h, c)
    def frame(s, x, y, w, h, c): s.hline(x, y, w, c); s.hline(x, y + h - 1, w, c); s.vline(x, y, h, c); s.vline(x + w - 1, y, h, c)
    def poly(s, pts, c): s.paint(s.m_poly(pts), c)
    def ellipse(s, cx, cy, rx, ry, c, half=None): s.paint(s.m_ellipse(cx, cy, rx, ry, half), c)
    def disc(s, cx, cy, r, c): s.paint(s.m_disc(cx, cy, r), c)
    def line(s, x0, y0, x1, y1, c): s.paint(s.m_line(x0, y0, x1, y1), c)

    def shade(s, arr, recv):
        """recv: 'desk', 'wall' (anything on the wall plane), 'cork', or a callable(scene) -> mask"""
        full = np.zeros((H, W), np.float32)
        if isinstance(arr, tuple):                   # (slice_y, slice_x, value)
            full[arr[0], arr[1]] = arr[2]
        else: full = arr.astype(np.float32)
        s.shadows.append((full, recv))

    def receivers(s, recv):
        if callable(recv): return recv(s)
        if recv == "desk": return s.mat_mask("desk", "desk_g")
        if recv == "wall": return (s.Z < 5) & (s.C >= 0)
        if recv == "cork": return s.mat_mask("cork")
        raise ValueError(recv)

    def tone(s, mask, t):
        """multiply albedo (texture / print variation) where mask"""
        s.T[mask] *= (t[mask] if isinstance(t, np.ndarray) else t)

    def mat_mask(s, *names):
        m = np.zeros((H, W), bool)
        for n in names: m |= s.C == s.idx[n]
        return m

    # ---------------------------------------------------------------- lighting
    def light(s, rig, lamp_scale=1.0, emit=None):
        """returns linear RGB"""
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        P = np.dstack([xx + 0.5, yy + 0.5, s.Z])
        Nn = s.N / np.maximum(np.linalg.norm(s.N, axis=2, keepdims=True), 1e-6)
        V = np.array([0, 0, 1.0], np.float32)
        acc = np.zeros((H, W, 3), np.float32)
        spec = np.zeros((H, W, 3), np.float32)

        def point(pos, col, power, radius, spot=None, emitter_n=None, shadow=None, gloss_scale=1.0):
            Lv = np.asarray(pos, np.float32) - P
            d = np.maximum(np.linalg.norm(Lv, axis=2), 1e-3)
            Ld = Lv / d[..., None]
            ndl = np.clip((Nn * Ld).sum(2), 0, 1)
            att = 1.0 / (1.0 + (d / radius) ** 2)
            f = ndl * att * power
            if spot is not None:
                sdir, cin, cout = spot
                cs = (-Ld * np.asarray(sdir, np.float32)).sum(2)
                f = f * np.clip((cs - cout) / (cin - cout), 0, 1) ** 1.5
            if emitter_n is not None:
                f = f * np.clip((-Ld * np.asarray(emitter_n, np.float32)).sum(2), 0, 1)
            if shadow is not None: f = f * (1 - shadow)
            c = np.asarray(col, np.float32)
            acc[...] += f[..., None] * c
            Hh = Ld + V; Hh /= np.maximum(np.linalg.norm(Hh, axis=2, keepdims=True), 1e-6)
            sp = np.clip((Nn * Hh).sum(2), 0, 1) ** (12 + 60 * s.G) * s.G * gloss_scale
            spec[...] += (sp * f * 2.2)[..., None] * c

        L = rig
        lamp = L["lamp"]
        point(lamp["pos"], lamp["col"], lamp["power"] * lamp_scale, lamp["radius"],
              spot=(lamp["dir"], math.cos(math.radians(lamp["inner"])), math.cos(math.radians(lamp["outer"]))), shadow=s.SL)
        point(lamp["pos"], lamp["halo_col"], lamp["halo"] * lamp_scale, lamp["halo_radius"], gloss_scale=0.3)
        b = L["bounce"]
        point(b["pos"], b["col"], b["power"] * lamp_scale, b["radius"], gloss_scale=0.0)
        crt = L["crt"]
        x0, y0, w, h = crt["rect"]
        for fx in (0.15, 0.5, 0.85):
            for fy in (0.15, 0.5, 0.85):
                point((x0 + w * fx, y0 + h * fy, crt["z"]), crt["col"], crt["power"] / 9.0, crt["radius"], emitter_n=(0, 0, 1), gloss_scale=0.6)
        # the glow of a bright tube in a dark room, falling off with distance from the glass
        dx = np.maximum(np.maximum(x0 - P[..., 0], P[..., 0] - (x0 + w)), 0)
        dy = np.maximum(np.maximum(y0 - P[..., 1], P[..., 1] - (y0 + h)), 0)
        dist = np.hypot(dx, dy)
        facing = 0.55 + 0.45 * np.clip(Nn[..., 2], 0, 1)
        acc += (np.exp(-dist / crt["wash_radius"]) * crt["wash"] * facing)[..., None] * np.asarray(crt["col"], np.float32)
        m = L["moon"]
        md = np.asarray(m["dir"], np.float32); md /= np.linalg.norm(md)
        ndl = np.clip((Nn * md).sum(2), 0, 1)
        side = np.clip((P[..., 0] - m.get("x0", 0)) / (W - m.get("x0", 0)), 0, 1) ** m.get("falloff", 1.0)
        ndl = ndl * (m.get("floor", 0.25) + (1 - m.get("floor", 0.25)) * side)
        acc += (ndl * m["power"])[..., None] * np.asarray(m["col"], np.float32)
        Hm = md + V; Hm /= np.linalg.norm(Hm)
        spec += ((np.clip((Nn * Hm).sum(2), 0, 1) ** (12 + 60 * s.G) * s.G * ndl * m["power"] * 1.5)[..., None] * np.asarray(m["col"], np.float32))
        acc += np.asarray(L["ambient"], np.float32)[None, None, :]
        acc += (np.clip(Nn[..., 2], 0, 1) * L["fill"])[..., None]
        ao = s.AO.copy()
        for arr, recv in s.shadows:
            m = s.receivers(recv)
            ao = np.where(m, np.maximum(ao, arr), ao)
        s.AO_final = ao
        acc *= (1 - ao)[..., None]
        alb = s.alb[np.maximum(s.C, 0)] * s.T[..., None]
        E = s.E if emit is None else emit
        E = E - s.E_lamp * (1 - lamp_scale)
        out = alb * acc + spec * (1 - ao)[..., None] + E
        out[s.C < 0] = 0
        return out

    # ---------------------------------------------------------------- palette + dithering
    @staticmethod
    def kmeans(X, k, iters=14, seed=3, init=None):
        rng = np.random.default_rng(seed)
        cent = X[rng.choice(len(X), k, replace=False)].copy() if init is None else init.copy()
        for _ in range(iters):
            d = ((X[:, None, :] - cent[None, :, :]) ** 2).sum(2)
            a = d.argmin(1)
            for j in range(k):
                sel = X[a == j]
                if len(sel): cent[j] = sel.mean(0)
        return cent

    def palette_for(s, frames, ncol=256, ndetail=56, pins=()):
        """most slots from the whole frame; a reserved block for small things that matter (lights, text, print, jacks);
        pins: exact sRGB colours (0..1) that must survive, e.g. the lit LEDs"""
        pins = np.asarray(pins, np.float32).reshape(-1, 3); ndetail -= len(pins)
        X = np.vstack([srgb(f).reshape(-1, 3) for f in frames])
        sample = X[np.random.default_rng(1).choice(len(X), min(len(X), 60000), replace=False)]
        general = s.kmeans(sample, ncol - ndetail)
        detail_mask = (~s.D) | (s.E.sum(2) > 0.02)
        Xd = np.vstack([srgb(f)[detail_mask] for f in frames])
        Xd = np.unique(np.round(Xd * 255).astype(int), axis=0).astype(np.float32) / 255
        detail = s.kmeans(Xd, min(ndetail, len(Xd)), iters=20) if len(Xd) > ndetail else Xd
        return np.vstack([general, detail, pins]) if len(pins) else np.vstack([general, detail])

    def quantize(s, rgb_lin, ncol=256, keep=(), dither=0.045, palette=None):
        """fit to a VGA-sized palette; ordered (Bayer 4x4) dithering on surfaces that allow it"""
        sr = srgb(rgb_lin)
        lab = sr.reshape(-1, 3)
        if palette is None:
            keep = np.asarray([np.asarray(hx(k), np.float32) / 255 for k in keep], np.float32).reshape(-1, 3)
            sample = lab[np.random.default_rng(1).choice(len(lab), min(len(lab), 40000), replace=False)]
            cent = s.kmeans(sample, ncol - len(keep))
            palette = np.vstack([cent, keep]) if len(keep) else cent
        bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float32) / 16.0 - 0.47
        yy, xx = np.mgrid[0:H, 0:W]
        th = bayer[yy % 4, xx % 4]
        jitter = (th * dither * s.D)[..., None]
        q = (sr + jitter).reshape(-1, 3)
        out = np.empty_like(q)
        for i in range(0, len(q), 20000):
            blk = q[i:i + 20000]
            d = ((blk[:, None, :] - palette[None, :, :]) ** 2).sum(2)
            out[i:i + 20000] = palette[d.argmin(1)]
        img = (np.clip(out.reshape(H, W, 3), 0, 1) * 255 + 0.5).astype(np.uint8)
        return img, palette
