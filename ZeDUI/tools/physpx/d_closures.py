"""What closes the waist belt, where the leather belt has its profession buckle (director, Oct 16 2026: "rope is a
knot. web/nylon belts get rectangle flat clip closure"):

  knot   the rope belt tied off: the two ends crossed and wrapped into a square knot, the tails hanging out below,
         in the same jute as the rope (d_straps.py: three strands, the lay, the stray hairs)
  clip   webbing and the breathing pack's nylon belt: the classic web-belt buckle (the director's references), brass on
         olive and green webbing, black on camo and black nylon

Each sits in the buckle's 58 x 40 place, transparent round it, drawn over the waist strap (which runs on under it).
Lit from the top left like the rest. usage: python d_closures.py [mod root] -> media/textures/ZeD/belt/closure_*.png"""
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi
from scipy.spatial import cKDTree

from physlib import *            # noqa: F401,F403
from engine import add_ramp, OUTLINE
import d_straps as S

W, H = 58, 40
STRAP_Y = (H - S.H) // 2          # where the strap's 30 rows sit in this box (the Lua centres both the same way)

add_ramp("clip_pewter", "#8c867a", light=1.08)
add_ramp("clip_dark", "#4e4a43")


# ---------------------------------------------------------------------------
# the knot
# ---------------------------------------------------------------------------
def _curve(pts, n=400):
    """a smooth centreline through the points (Catmull-Rom), densely sampled, with its arc length"""
    P = np.array(pts, float)
    P = np.vstack([P[0] * 2 - P[1], P, P[-1] * 2 - P[-2]])
    out = []
    seg = len(P) - 3
    for i in range(seg):
        p0, p1, p2, p3 = P[i:i + 4]
        for t in np.linspace(0, 1, n // seg, endpoint=False):
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(P[-2])
    C = np.array(out)
    s = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(C, axis=0), axis=1))])
    return C, s


def _tube(d, pts, r, z, seed, s0=0.0, taper_end=0.0, fray_end=False, lay_dark=0.42, ao_amt=0.45, r_start=None, start_len=6.0, rope=None, only=None):
    """one strand of rope along the points: round in section, the jute's twist running along it like the strap's (lobes
    on the diagonal, a shadowed lay, fine fibres the other way), laid over whatever is under it. taper_end: how much the
    radius narrows toward the last point (an end coming loose). rope: which rope this strand is (no outline between two
    pieces of one rope); only: (u0, u1), draw just that stretch of it (to lay part of a rope back over another)"""
    C, s = _curve(pts)
    T = np.gradient(C, axis=0)
    T /= np.linalg.norm(T, axis=1, keepdims=True) + 1e-9
    yy, xx = d.YY.astype(float) + 0.5, d.XX.astype(float) + 0.5
    q = np.dstack([xx, yy]).reshape(-1, 2)
    dist, idx = cKDTree(C).query(q)
    dist = dist.reshape(d.H, d.W); idx = idx.reshape(d.H, d.W)
    v = np.dstack([xx, yy]) - C[idx]
    side = v[..., 0] * T[idx][..., 1] - v[..., 1] * T[idx][..., 0]     # signed: across the strand
    u = s[idx] / s[-1]
    rr = r * (1 - taper_end * np.clip((u - 0.6) / 0.4, 0, 1))
    if r_start is not None:
        # swelling back to the belt's own thickness where it comes out of the belt
        t = np.clip(s[idx] / start_len, 0, 1)
        rr = r_start + (rr - r_start) * (t * t * (3 - 2 * t))
    ends = (idx == 0) | (idx == len(C) - 1)
    m = (dist <= rr) & ~ends
    if only is not None:
        m &= (u >= only[0]) & (u <= only[1])
    prof = np.sqrt(np.clip(1 - (dist / rr) ** 2, 0, 1))
    hgt = z + rr * 0.55 * prof
    P = 64 / 5.0
    ph = ((s[idx] + s0) + side * 0.75) * (2 * math.pi / P)
    lobe = np.clip(0.5 + 0.5 * np.cos(ph), 0, 1) ** 0.6
    hgt = hgt + lobe * 1.8 - 0.8
    # what this strand lies over falls into its shade near it (an occlusion two or three pixels wide)
    under = d.solid & ~m
    if under.any():
        dd = ndi.distance_transform_edt(~m)
        ao = np.clip(1 - (dd - 1) / 3.0, 0, 1) * ao_amt
        d.dark[under] = np.maximum(d.dark[under], ao[under])
    d.h = np.where(m, hgt, d.h).astype(np.float32)
    if not hasattr(d, "owner"):
        d.owner = np.zeros((d.H, d.W), np.int16); d.rope = np.zeros((d.H, d.W), np.int16)
    d.owner[m] = d.owner.max() + 1
    d.rope[m] = rope if rope is not None else d.owner.max()
    d.mat[m] = d.mid("rope_tan"); d.solid |= m; d.polish[m] = 0.15
    rng = np.random.default_rng(seed)
    fib = np.sin(((s[idx] + s0) * 1.0 - side * 1.9) * 1.35)
    n = rng.random((d.H, d.W))
    d.tex[m] = (fib * 0.06 + np.where(n > 0.9, 0.05, np.where(n < 0.05, -0.05, 0.0)))[m]
    lay = np.cos(ph) < -0.86
    d.dark[m] = np.where(lay[m], lay_dark, 0.0)          # softer than the belt's: the strands' own outlines carry the knot
    if fray_end:
        # the cut end opened up: the three strands splayed into a short brush
        e = C[-1]; t = T[-1]
        nrm = np.array([-t[1], t[0]])
        for k, off in enumerate((-0.8, 0.0, 0.8)):
            a = e + nrm * off * rr.max() * 0.0 + nrm * off * 4
            for j in range(4):
                p = a + t * j + nrm * off * j * 0.5
                x, y = int(round(p[0])), int(round(p[1]))
                if 0 <= x < d.W and 0 <= y < d.H:
                    d.h[y, x] = z + 1.0 - j * 0.2; d.mat[y, x] = d.mid("jute_hair"); d.solid[y, x] = True
                    d.polish[y, x] = 0.1; d.tex[y, x] = 0.04 * (1 - (j % 2) * 2); d.dark[y, x] = 0
    return m


# The knot (director, Oct 16 2026: "that's the knot", a photo of two jute ropes joined in a square knot): each rope
# comes in along the belt, turns round the far side of the knot and runs back, the two turns locked through each other;
# one end leaves out of the top left and one out of the bottom right, each frayed into a brush. It stands taller than the
# buckle (the hands' full 52 rows), so its ends have room.
KH = 52                            # the knot's own height (the buckle's place is 40; centred on the same row)
KNOT_Y = KH // 2                   # the belt's middle row in it
KNOT_CUT = (14, 44)                # where the belt's run is cut (the Lua does the same): each rope's own strand takes over
KNOT_RF = 0.62                     # the knot's strands against the belt's thickness: pulled tight


def _knot_paths():
    W_, Y = W, KNOT_Y
    right = [(W_ + 4, Y), (44, Y - 1), (31, Y - 4), (21, Y - 4), (14.5, Y + 1.5), (17, Y + 10), (28, Y + 13.5), (39, Y + 12),
             (44, Y + 16), (47, Y + 19)]
    left = [(-4, Y), (14, Y + 1), (28, Y + 4), (40, Y + 3.5), (45.5, Y - 3), (41, Y - 11), (30, Y - 13.5), (19, Y - 12),
            (14, Y - 16), (11.5, Y - 19)]
    return left, right


def knot():
    """the square knot: the right rope first, round the left of the knot and out down-right; the left rope over it, round
    the right and out up-left; then the right rope's turn laid back over the left rope (the lock). The ends flare where
    they come apart"""
    p = Plate("closure_knot", W, KH, seed=21)
    d = p.d
    r0 = S.MATERIALS["rope"][1] / 2.0
    r = r0 * KNOT_RF
    left, right = _knot_paths()
    kw = dict(taper_end=-0.35, lay_dark=0.2, ao_amt=0.75, r_start=r0)
    _tube(d, right, r, Z_FACE + 2.0, 5, s0=3.0, rope=1, start_len=W + 10 - 44, **kw)
    _tube(d, left, r, Z_FACE + 3.0, 7, s0=1.0, rope=2, start_len=18.0, **kw)
    _tube(d, right, r, Z_FACE + 4.0, 5, s0=3.0, rope=1, start_len=W + 10 - 44, only=(0.30, 0.52), **kw)
    return p


def _fray(a, end, direction, n=18, ln=(4, 9), spread=0.95, seed=1):
    """a frayed jute end: fibres fanning out from `end` along `direction`, light and dark, doubled at the root"""
    r = np.random.default_rng(seed)
    dx, dy = direction
    L = math.hypot(dx, dy); dx, dy = dx / L, dy / L
    base = math.atan2(dy, dx)
    cols = [np.array([214, 182, 126, 255]), np.array([186, 150, 96, 255]), np.array([150, 116, 70, 255]), np.array([228, 200, 146, 255])]
    for i in range(n):
        ang = base + (i / (n - 1) - 0.5) * 2 * spread + r.uniform(-0.12, 0.12)
        ln_ = r.uniform(*ln); c = cols[i % len(cols)]
        ox, oy = end[0] + r.uniform(-3.5, 3.5) * -dy - dx * 2, end[1] + r.uniform(-3.5, 3.5) * dx - dy * 2
        for t in np.arange(0, ln_, 0.5):
            w = math.sin(t * 1.3 + i) * 0.4                        # a little wave in each fibre
            x = int(round(ox + math.cos(ang) * t - math.sin(ang) * w)); y = int(round(oy + math.sin(ang) * t + math.cos(ang) * w))
            if 0 <= x < a.shape[1] and 0 <= y < a.shape[0]:
                a[y, x] = c
                if t < ln_ * 0.4 and 0 <= x + 1 < a.shape[1]: a[y, x + 1] = cols[(i + 1) % len(cols)]
    return a


# ---------------------------------------------------------------------------
# the clip
# ---------------------------------------------------------------------------
# the classic web-belt buckle (the director's references, Oct 16 2026: GI brass on olive drab, black on black nylon):
# a face wider than tall with gently bowed sides and the clamp rail's round ends standing proud top and bottom. Worn,
# that is all that shows (director, Oct 16 2026): the belt's tail runs back through the tunnel over the frame that holds
# the buckle on, hiding it, so the webbing runs straight on either side of the face
FACE = (11, 6, 36, 28)             # x, y, w, h
FINISH = {
    # finish: (face ramp, frame ramp, polish, wear: tarnish blotches or rubbed scuffs)
    "brass": ("clip_brass", "clip_brass_d", 0.75, "tarnish"),
    "black": ("clip_black", "clip_black_d", 0.95, "scuff"),
    "chrome": ("clip_nickel", "clip_nickel_d", 1.0, "none"),
}
add_ramp("clip_brass", "#c4a24a", light=1.15)
add_ramp("clip_brass_d", "#9c7c34", light=1.08)
add_ramp("clip_tarnish", "#8a7034")
add_ramp("clip_nickel", "#a4a7ab", light=1.2)
add_ramp("clip_nickel_d", "#7e8186", light=1.1)
add_ramp("clip_black", "#2b2c30", light=1.25)
add_ramp("clip_black_d", "#1f2023", light=1.15)
add_ramp("clip_rub", "#55565a", light=1.1)


def _barrel(x, y, w, h, bow=1.0, r=2):
    """a face whose left and right sides bow out a pixel at the middle, corners rounded"""
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    t = (yy - (y + (h - 1) / 2.0)) / (h / 2.0)
    out = bow * (1 - np.clip(t, -1, 1) ** 2)
    m = (yy >= y) & (yy < y + h) & (xx >= x - out) & (xx < x + w + out)
    # round the corners
    for cx_, cy_ in ((x + r, y + r), (x + w - 1 - r, y + r), (x + r, y + h - 1 - r), (x + w - 1 - r, y + h - 1 - r)):
        corner = (np.abs(xx - cx_) > 0) & (((xx < x + r) if cx_ < x + w / 2 else (xx > x + w - 1 - r)) &
                                            ((yy < y + r) if cy_ < y + h / 2 else (yy > y + h - 1 - r)))
        m &= ~(corner & ((xx - cx_) ** 2 + (yy - cy_) ** 2 > (r + 0.5) ** 2))
    return m


def clip(finish="brass"):
    face_r, frame_r, pol, wear = FINISH[finish]
    p = Plate(f"closure_clip_{finish}", W, H, seed=23)
    d = p.d
    # the face, a little cushioned
    x, y, w, h = FACE
    face = _barrel(x, y, w, h)
    d.slab(face, Z_FACE + 5.0, face_r, bevel=3.2, polish=pol, power=0.55)
    # the face curves round left to right, so the room shows on it in upright bands (the polished references): light at
    # the left edge, a dark band, the bright window a little right of centre, falling off toward the right edge
    u = (d.XX - x) / float(w)
    refl = (0.10 * np.exp(-((u - 0.06) ** 2) / 0.004) - 0.16 * np.exp(-((u - 0.34) ** 2) / 0.010)
            + 0.30 * np.exp(-((u - 0.60) ** 2) / 0.004) + 0.05 * np.exp(-((u - 0.70) ** 2) / 0.008) - 0.10 * u)
    vert = (d.YY - y) / float(h)
    d.tex[face] = (refl - 0.04 * vert)[face]
    r = np.random.default_rng(31 if finish == "brass" else 37)
    if wear == "tarnish":
        # patina in the low places, worn bright where a thumb rubs: soft blotches, a little speckle
        blot = ndi.gaussian_filter(r.random((H, W)).astype(np.float32), 1.8)
        blot = (blot - blot.min()) / (blot.max() - blot.min() + 1e-6)
        # light wear only: a little patina in the corners, where a thumb does not reach
        corners = np.minimum(np.abs(u - 0.5), 0.5) * 2 * np.abs(vert - 0.5) * 2
        tm = face & (blot * 0.6 + corners * 0.7 > 0.82)
        d.paint(tm, "clip_tarnish")
        d.tex[tm] = (refl * 0.5)[tm]
    elif wear == "scuff":
        # black finish rubbed through to grey metal along the raised edges, a few scuffs
        edge = face & ~ndi.binary_erosion(face, iterations=1)
        rub = edge & (r.random((H, W)) < 0.35)
        d.paint(rub, "clip_rub")
        fl = r.random((H, W))
        sc = face & (fl < 0.008)
        d.paint(sc, "clip_rub")
    # the clamp rail that presses the belt in place: its round ends standing proud above and below the face
    for (kx, ky) in ((x + 9, y - 2), (x + 9, y + h - 1)):      # one rail: its two ends in line
        knob = Mask(W, H).rrect(kx, ky, 3, 3, 1).get()
        d.slab(knob, Z_FACE + 5.6, frame_r, bevel=1.0, polish=pol)
    return p


CLIPS = ("brass", "black", "chrome")


# ---------------------------------------------------------------------------
def render(name):
    p = knot() if name == "knot" else clip(name.split("_", 1)[1])
    img = p.d.render(chrome_env="room")
    if name == "knot":
        # no outline where the ropes come out of the belt: the belt runs on under them
        a = np.array(img)
        L, R = KNOT_CUT
        ky = KNOT_Y - S.H // 2
        for band in ((slice(ky + 4, ky + S.H - 3), slice(0, L - 2)), (slice(ky + 4, ky + S.H - 3), slice(R + 2, W))):
            a[band][(a[band][..., 3] > 0) & ~p.d.solid[band]] = 0
        a = np.array(_strand_outlines(Image.fromarray(a, "RGBA"), p.d.owner, p.d.rope))
        left, right = _knot_paths()
        a = _fray(a, (11, KNOT_Y - 20), (-0.55, -1), seed=11)
        a = _fray(a, (48, KNOT_Y + 20), (0.55, 1), seed=13)
        img = Image.fromarray(a, "RGBA")
    return img


def _strand_outlines(img, owner, rope=None):
    """a one-pixel outline on the lower strand wherever another lies over it, as the render outlines the silhouette,
    so each crossing reads as over and under"""
    a = np.array(img)
    lower = np.zeros(owner.shape, bool)
    if rope is None: rope = owner
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nb = np.roll(np.roll(owner, dy, 0), dx, 1)
        nbr = np.roll(np.roll(rope, dy, 0), dx, 1)
        lower |= (owner > 0) & (nb > owner) & (nbr != rope)
    a[lower, :3] = OUTLINE
    return Image.fromarray(a, "RGBA")


def export(root):
    dd = os.path.join(root, "42", "media", "textures", "ZeD", "belt")
    os.makedirs(dd, exist_ok=True)
    names = ["knot"] + ["clip_" + f for f in CLIPS]
    for name in names:
        render(name).save(os.path.join(dd, f"closure_{name}.png"))
    print("wrote", ", ".join(f"closure_{n}.png" for n in names), "to", dd)


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "mod", "ZeD-UI"))
