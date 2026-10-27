"""Hands of two sizes (vanilla's way: the main hand bigger) and the joined shape for one item in both hands: the
hull of the two circles, its outline and a framed track round it, filled clockwise from the top centre."""
import math
import numpy as np
from PIL import Image
import capsule as C

def hull_mask(W, H, c1, a, c2, b):
    """pixels (centres) inside the hull of circle (c1, a) and circle (c2, b); centres on one row"""
    ys, xs = np.mgrid[0:H, 0:W].astype(float) + 0.5
    d = c2[0] - c1[0]
    inside = ((xs - c1[0]) ** 2 + (ys - c1[1]) ** 2 <= a * a) | ((xs - c2[0]) ** 2 + (ys - c2[1]) ** 2 <= b * b)
    if a > 0 and b > 0 and d > 0:
        ct = (a - b) / d; st = math.sqrt(max(0, 1 - ct * ct))
        for sgn in (-1, 1):                         # the top and the bottom tangent: inside = on the centre's side
            nx, ny = ct, sgn * st
            k = nx * c1[0] + ny * c1[1] + a        # n . p = k on the tangent line
            pass
        nT, nB = (ct, -st), (ct, st)
        kT = nT[0] * c1[0] + nT[1] * c1[1] + a
        kB = nB[0] * c1[0] + nB[1] * c1[1] + a
        between = (xs >= c1[0]) & (xs <= c2[0])
        inside |= between & (nT[0] * xs + nT[1] * ys <= kT) & (nB[0] * xs + nB[1] * ys <= kB)
    return inside

def path(c1, a, c2, b, n=3000):
    """the hull's outline clockwise from the top, midway between the centres: points and the length to each"""
    d = c2[0] - c1[0]
    ct = (a - b) / d; th = math.acos(max(-1, min(1, ct)))   # the angle of the top tangent's normal (screen y down)
    aT, aB = -th, th
    pts = []
    xm = (c1[0] + c2[0]) / 2
    T1 = (c1[0] + a * math.cos(aT), c1[1] + a * math.sin(aT)); T2 = (c2[0] + b * math.cos(aT), c2[1] + b * math.sin(aT))
    B1 = (c1[0] + a * math.cos(aB), c1[1] + a * math.sin(aB)); B2 = (c2[0] + b * math.cos(aB), c2[1] + b * math.sin(aB))
    def line(p, q, m):
        for i in range(m): pts.append((p[0] + (q[0] - p[0]) * i / m, p[1] + (q[1] - p[1]) * i / m))
    tM = (xm - T1[0]) / (T2[0] - T1[0]); M = (T1[0] + (T2[0] - T1[0]) * tM, T1[1] + (T2[1] - T1[1]) * tM)
    line(M, T2, n // 10)
    for i in range(n // 4): ang = aT + (aB - aT) * i / (n // 4); pts.append((c2[0] + b * math.cos(ang), c2[1] + b * math.sin(ang)))
    line(B2, B1, n // 5)
    for i in range(n // 4): ang = aB + (2 * math.pi - 2 * th) * i / (n // 4); pts.append((c1[0] + a * math.cos(ang), c1[1] + a * math.sin(ang)))
    line(T1, M, n // 10)
    pts.append(M)
    P = np.array(pts); seg = np.hypot(*np.diff(P, axis=0).T); L = np.concatenate([[0], np.cumsum(seg)])
    return P, L

def joined(im, ox, oy, sc, c1, a, c2, b, f):
    """the joined hands at (ox, oy): c1, c2 centres inside the box, a, b their radii (px)"""
    hair = max(1, math.floor(sc + 0.5)); W, H = im.width - ox, im.height - oy
    ins, t, fw = 3 * hair, 6 * hair, hair
    def band(r0, r1):          # between the hull inset by r0 and by r1 (r0 < r1)
        return hull_mask(W, H, c1, a - r0, c2, b - r0) & ~hull_mask(W, H, c1, a - r1, c2, b - r1)
    layers = [(hull_mask(W, H, c1, a, c2, b), C.SURF2), (band(0, 2 * hair), C.BORDER), (band(ins, ins + t), C.BASE)]
    fill = band(ins + fw, ins + t - fw)
    P, Ls = path(c1, a - ins - t / 2, c2, b - ins - t / 2)
    ys, xs = np.nonzero(fill)
    if len(xs):
        q = np.stack([xs + 0.5, ys + 0.5], 1)
        idx = np.argmin(((q[:, None, :] - P[None, :, :]) ** 2).sum(-1), axis=1)
        tot = Ls[-1]
        f = max(f, math.floor(2 * sc + 0.5) / tot)
        keep = Ls[idx] <= f * tot
        m = np.zeros_like(fill); m[ys[keep], xs[keep]] = True
        layers.append((m, C.grad(f)))
    layers += [(band(ins, ins + fw), C.BORDER), (band(ins + t - fw, ins + t), C.BORDER)]
    px = im.load()
    for mask, col in layers:
        for y, x in zip(*np.nonzero(mask)):
            px[ox + x, oy + y] = col
