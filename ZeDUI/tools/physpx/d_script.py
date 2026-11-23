"""Old handwritten script, in pixels, that says nothing (director, Nov 22 2026: "it should have old handwritten script
identifying each part. This does not need to be legible. This is very much just a hint at that."). A word is a run of
joined cursive strokes (humps, small loops, tall loops, descenders, a dotted stroke, a crossed one), led by a taller
flourish like a capital, leaning right as a pen does, drawn one pixel wide. Seeded, so a part keeps its word.
word(seed, letters) gives (alpha array, baseline row) with the strokes at 1.0."""
import math

import numpy as np

# each letter's pen path from its left foot on the baseline (y up is negative), and its width; a list of extra marks
# (a dot, a cross) drawn apart from the run
LETTERS = {
    "n": (3.2, [(0, 0), (0.4, -2.2), (1.3, -3.0), (2.3, -2.4), (2.8, -0.6), (3.2, 0)], []),
    "m": (5.0, [(0, 0), (0.4, -2.2), (1.2, -3.0), (2.0, -2.2), (2.4, -0.4), (2.8, -2.4), (3.6, -3.0), (4.4, -2.2),
                (4.8, -0.4), (5.0, 0)], []),
    "u": (3.2, [(0, -0.2), (0.4, -2.8), (0.6, -1.0), (1.4, 0), (2.4, -1.2), (2.6, -2.9), (2.7, -0.6), (3.2, 0)], []),
    "e": (2.8, [(0, -0.3), (1.6, -1.6), (2.0, -2.8), (1.2, -3.1), (0.6, -1.8), (1.2, -0.2), (2.8, -0.4)], []),
    "o": (3.0, [(0, -0.4), (0.8, -2.6), (1.8, -3.0), (2.4, -1.6), (1.6, -0.1), (0.9, -1.2), (1.8, -2.9), (3.0, -2.4)], []),
    "l": (3.0, [(0, -0.3), (1.8, -3.4), (2.4, -6.0), (1.6, -6.8), (1.0, -5.2), (1.2, -2.0), (1.8, -0.1), (3.0, -0.5)], []),
    "b": (3.4, [(0, -0.3), (1.8, -3.6), (2.2, -6.2), (1.4, -6.8), (0.9, -4.6), (1.1, -1.0), (2.0, -0.1), (2.8, -1.6),
                (2.2, -2.8), (3.4, -2.6)], []),
    "g": (3.0, [(0, -0.4), (0.8, -2.7), (2.0, -2.9), (2.2, -0.8), (2.0, 1.8), (1.2, 3.2), (0.6, 2.4), (1.4, 0.6),
                (3.0, -0.6)], []),
    "y": (3.2, [(0, -0.3), (0.4, -2.8), (0.8, -0.8), (1.6, -0.2), (2.4, -2.9), (2.4, 0.2), (2.0, 2.8), (1.2, 3.1),
                (1.2, 1.6), (3.2, -0.4)], []),
    "i": (2.0, [(0, -0.2), (0.9, -2.6), (1.0, -0.4), (2.0, -0.2)], [[(1.3, -4.4)]]),
    "t": (2.2, [(0, -0.2), (0.9, -4.6), (1.0, -0.6), (2.2, -0.2)], [[(0.0, -3.0), (2.2, -3.3)]]),
    "r": (2.8, [(0, -0.2), (0.6, -2.8), (1.4, -2.2), (2.2, -2.9), (2.0, -0.6), (2.8, -0.1)], []),
}
CAPS = {   # a taller flourish to start the word
    "A": (4.6, [(0, 0), (1.6, -4.0), (2.8, -7.4), (3.2, -6.0), (3.4, -2.0), (3.8, -0.2), (4.6, -0.6)],
          [[(1.0, -3.0), (4.0, -3.4)]]),
    "C": (4.0, [(3.4, -6.4), (2.2, -7.2), (0.8, -5.8), (0.4, -3.0), (1.2, -0.4), (2.8, -0.2), (4.0, -0.8)], []),
    "L": (4.4, [(1.6, -5.0), (2.6, -7.4), (3.6, -6.8), (2.6, -4.2), (1.0, -1.0), (0.2, -0.2), (1.6, 0), (4.4, -0.6)], []),
    "M": (5.6, [(0, 0), (1.0, -6.6), (1.6, -3.6), (2.4, -0.8), (3.2, -6.4), (4.0, -3.0), (4.6, -0.4), (5.6, -0.6)], []),
    "S": (4.0, [(3.6, -6.6), (2.4, -7.2), (1.2, -6.2), (1.6, -4.4), (3.0, -3.0), (2.6, -0.6), (1.0, -0.2), (0.2, -1.2),
                (4.0, -0.6)], []),
}
SLANT = 0.32           # a pen's lean: x moves right this much for every pixel up


def _spline(pts, n=14):
    """a Catmull-Rom curve through pts, n samples a span"""
    out = []
    P = [pts[0]] + pts + [pts[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = (np.array(P[i - 1]), np.array(P[i]), np.array(P[i + 1]), np.array(P[i + 2]))
        for t in np.linspace(0, 1, n, endpoint=False):
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(np.array(P[-2]))
    return out


def word(seed, letters=5, cap=True):
    """a made-up word in pixel script: (alpha array H x W, the baseline's row)"""
    rnd = np.random.default_rng(seed)
    run, extra = [], []
    x = 0.0
    keys = list(LETTERS)
    seq = []
    if cap:
        seq.append(("cap", list(CAPS)[int(rnd.integers(len(CAPS)))]))
    for i in range(letters):
        k = keys[int(rnd.integers(len(keys)))]
        while seq and seq[-1][1] == k:              # no letter twice running
            k = keys[int(rnd.integers(len(keys)))]
        seq.append(("low", k))
    for kind, k in seq:
        w, path, marks = (CAPS if kind == "cap" else LETTERS)[k]
        jit = rnd.uniform(-0.25, 0.25, size=(len(path), 2)) * np.array([0.5, 0.6])
        run += [(x + px + jx, py + jy) for (px, py), (jx, jy) in zip(path, jit)]
        for m in marks:
            extra.append([(x + px, py) for px, py in m])
        x += w + rnd.uniform(-0.1, 0.4)
    curves = [_spline(run)] + [(_spline(m) if len(m) > 1 else [np.array(m[0])]) for m in extra]
    pix = set()
    for c in curves:
        for (px, py) in c:
            px = px - SLANT * py                         # the lean (py is negative above the line)
            pix.add((int(math.floor(px + 0.5)), int(math.floor(py + 0.5))))
    xs = [p[0] for p in pix]
    ys = [p[1] for p in pix]
    x0, y0 = min(xs), min(ys)
    a = np.zeros((max(ys) - y0 + 1, max(xs) - x0 + 1), np.float32)
    for (px, py) in pix:
        a[py - y0, px - x0] = 1.0
    return a, -y0
