"""The rod in hand while the line is out (brief: ZeDUI/mockups/zed_fish_sleep_DESIGN_BRIEF.md; director, Oct 16 2026):
a 1980s pistol-grip baitcasting rod, the director's own tackle (Daiwa Magforce / PT33P reels on All Star rods): cork
rear grip, a pistol trigger under a black seat, cork fore grip, a brown graphite blank with chrome guides on top, a
low-profile black baitcaster with two paddle handles and a star drag. Parody brand DAIZO. The reel's side plate has the
round dial: chrome rim, black face, cream ticks from 0 round to MAX, the last three red, MAX printed in red.

360 x 200 plate pixels, transparent; 17 frames by tension (rod_00 .. rod_16). Per frame the blank bows (its guides and
tip are the brief's anchors, F.ANCH in Overrides/Fishing.lua, kept exactly) and the eight thread wraps light one by
one from the reel toward the tip, ceil(i / 2) of them: 1-4 gold, 5-6 orange, 7-8 red. The handle and reel turn with
the rod as a rigid piece (placed per frame from the anchors' dial and start). Not drawn: the line, the dial's
pointer and hub (live in the game).
usage: python d_rod.py [mod root]   (default ./out/mod/ZeD-UI) -> media/textures/ZeD/props/rod_NN.png"""
import math
import os
import re
import sys

import numpy as np
from PIL import Image

from physlib import *            # noqa: F401,F403
from engine import add_ramp

add_ramp("cork", "#b8895a", light=1.05)
add_ramp("blank_graphite", "#4a2b1a")
add_ramp("reel_black", "#26272b")
add_ramp("reel_plate", "#1a1b1e")
add_ramp("dial_face", "#0c0c0d")
add_ramp("thread_white", "#e8e4da", light=1.05)
add_ramp("thread_gold", "#e2a83a", light=1.05)
add_ramp("thread_orange", "#e8702a")
add_ramp("thread_red", "#d4302a")
add_ramp("tick_cream", "#e6dcc0", light=1.05)
add_ramp("tick_red", "#e0382a")
add_ramp("print_gold_r", "#cfa04a", light=1.05)
add_ramp("seat_black", "#18181a")

W, H = 360, 200
FRAMES = 16


def anchors():
    """F.ANCH from the game's Overrides/Fishing.lua (the brief's anchors, plate pixels)"""
    here = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.join(here, "..", "..", "..", "42", "media", "lua", "client", "ZeD", "Overrides", "Fishing.lua")
    src = os.environ.get("ZED_FISHING_LUA") or (repo if os.path.exists(repo) else os.path.join(here, "lua", "Fishing.lua"))
    s = open(src).read()
    body = s[s.index("F.ANCH = {"):]
    body = body[:body.index("\n}") + 2]
    out = []
    for line in body.splitlines():
        if "tip =" not in line: continue
        nums = lambda key: [float(v) for v in re.search(key + r" = \{([^}]*)\}", line).group(1).split(",")]
        guides = [tuple(float(v) for v in g.split(",")) for g in re.findall(r"\{ ([\d.]+, [\d.]+) \}", line.split("guides =")[1].split("dial")[0])]
        out.append({"tip": nums("tip"), "start": nums("start"), "guides": guides, "dial": nums("dial"), "max": nums("max")})
    assert len(out) == FRAMES + 1, len(out)
    return out


# the handle and reel in their own frame: u along the rod toward the tip, v square to it (up-left positive), origin at
# the dial's centre, as frame 0 lies (the rod at -31 degrees)
A0 = math.radians(-31.0)
D0 = np.array([math.cos(A0), math.sin(A0)])
N0 = np.array([D0[1], -D0[0]])
AXIS_V = -21.0              # the rod's centre line, below the dial
START_UV = None             # set from frame 0's anchors


def uv_of(p, dial):
    q = np.array(p) - np.array(dial[:2])
    return float(q @ D0), float(q @ N0)


class Place:
    """frame i's rigid placement of the handle: rotation about the dial and the dial's own position"""
    def __init__(s, a, a0):
        u, v = uv_of(a0["start"], a0["dial"])
        q = np.array(a["start"]) - np.array(a["dial"][:2])
        ang0 = math.atan2(*(u * D0 + v * N0)[::-1])
        ang1 = math.atan2(q[1], q[0])
        s.th = ang1 - ang0
        s.c = np.array(a["dial"][:2], float)
        c, sn = math.cos(s.th), math.sin(s.th)
        s.d = np.array([c * D0[0] - sn * D0[1], sn * D0[0] + c * D0[1]])
        s.n = np.array([s.d[1], -s.d[0]])

    def __call__(s, u, v):
        p = s.c + u * s.d + v * s.n
        return float(p[0]), float(p[1])

    def poly(s, pts): return [s(u, v) for u, v in pts]


def rounded(pts_uv, r, n=5):
    """a polygon (u, v) with its corners rounded by r (a few points per corner)"""
    out = []
    m = len(pts_uv)
    for i in range(m):
        p0, p1, p2 = np.array(pts_uv[i - 1]), np.array(pts_uv[i]), np.array(pts_uv[(i + 1) % m])
        a, b = p0 - p1, p2 - p1
        la, lb = np.linalg.norm(a), np.linalg.norm(b)
        rr = min(r, la / 2, lb / 2)
        s0, s1 = p1 + a / la * rr, p1 + b / lb * rr
        for k in range(n + 1):
            t = k / n
            q = (1 - t) ** 2 * s0 + 2 * (1 - t) * t * p1 + t ** 2 * s1
            out.append((float(q[0]), float(q[1])))
    return out


def wrap_colour(i, k):
    """the k-th wrap (1 at the reel, 8 at the tip) at frame i"""
    lit = math.ceil(i / 2)
    if k > lit: return "thread_white"
    return "thread_gold" if k <= 4 else ("thread_orange" if k <= 6 else "thread_red")


def rod(i, A=None, worn=True):
    A = A or anchors()
    a, a0 = A[i], A[0]
    P = Place(a, a0)
    p = Plate(f"rod_{i:02d}", W, H, seed=71)
    d = p.d
    M = lambda: Mask(W, H)

    # ---- the blank: from the fore grip, under each guide, to the tip; tapering
    fg_end = P(44, AXIS_V)
    gs = [np.array(g) for g in a["guides"]]
    tip = np.array(a["tip"])
    pts = [np.array(fg_end)]
    for k, g in enumerate(gs):
        prev = pts[-1]
        nxt = gs[k + 1] if k + 1 < len(gs) else tip
        t = nxt - prev
        t = t / max(1e-6, np.linalg.norm(t))
        nrm = np.array([t[1], -t[0]])                    # the up side of the curve
        off = 3.6 - 1.4 * k / max(1, len(gs) - 1)       # the guides stand lower toward the tip
        pts.append(g - nrm * off)
    t = tip - pts[-1]; t = t / max(1e-6, np.linalg.norm(t))
    pts.append(tip - np.array([t[1], -t[0]]) * 0.6)
    # a smooth line through them (Catmull-Rom), then drawn as short segments, thick at the butt, thin at the tip
    def cr(p0, p1, p2, p3, s):
        return 0.5 * ((2 * p1) + (-p0 + p2) * s + (2 * p0 - 5 * p1 + 4 * p2 - p3) * s * s + (-p0 + 3 * p1 - 3 * p2 + p3) * s ** 3)
    ext = [pts[0] - (pts[1] - pts[0])] + pts + [pts[-1] + (pts[-1] - pts[-2])]
    curve = []
    for k in range(1, len(ext) - 2):
        for s in np.linspace(0, 1, 10, endpoint=False):
            curve.append(cr(ext[k - 1], ext[k], ext[k + 1], ext[k + 2], s))
    curve.append(pts[-1])
    L = len(curve)
    blank = np.zeros((H, W), bool)
    for k in range(L - 1):
        w_ = 4.6 - 2.8 * k / (L - 1)
        blank |= M().line([tuple(curve[k]), tuple(curve[k + 1])], w_).get(0.45)
    d.slab(blank, Z_FACE + 2.0, "blank_graphite", bevel=1.6, polish=0.75, power=0.6)
    # the eight thread wraps: two above the fore grip, one at each guide's foot
    def along(frac):
        return curve[min(L - 1, int(frac * (L - 1)))]
    wrap_pts = [along(0.02), along(0.05)] + [pts[k + 1] for k in range(len(gs))]
    for k, q in enumerate(wrap_pts, 1):
        j = min(range(L), key=lambda m: np.sum((curve[m] - q) ** 2))
        t = curve[min(L - 1, j + 1)] - curve[max(0, j - 1)]; t = t / max(1e-6, np.linalg.norm(t))
        half = 1.6 if k > 2 else 2.0
        w_ = (4.6 - 2.8 * j / (L - 1)) + 1.2
        m = M().line([tuple(q - t * half), tuple(q + t * half)], w_).get(0.45)
        d.slab(m, Z_FACE + 2.3, wrap_colour(i, k), bevel=1.0, polish=0.5, power=0.6)
    # the guides: a chrome foot on the blank and a ring the line runs through (its hole left open)
    for k, g in enumerate(gs):
        foot = pts[k + 1]
        r_out = 2.6 - 0.8 * k / max(1, len(gs) - 1)
        m = M().line([tuple(foot), tuple(g)], 1.4).get(0.45)
        d.slab(m, Z_FACE + 2.6, "chrome", bevel=0.6, polish=1.0)
        rg = ring(d, g[0], g[1], max(0.6, r_out - 1.1), r_out)
        d.slab(rg, Z_FACE + 3.0, "chrome", bevel=0.5, polish=1.0)
    d.slab(disc(d, tip[0], tip[1], 1.3), Z_FACE + 3.0, "chrome", bevel=0.5, polish=1.0)    # the tip top

    # ---- the handle: rear cork grip, seat, trigger, fore grip (all in the handle's own frame)
    rear = M().line([P(-71, AXIS_V), P(-12, AXIS_V)], 10.5).get(0.45)
    d.slab(rear, Z_FACE + 3.0, "cork", bevel=5.0, polish=0.2, power=0.55)
    d.grain_pebble(rear, 0.06, seed=7)
    d.seam(M().line([P(-71.5, AXIS_V - 4.5), P(-71.5, AXIS_V + 4.5)], 1.6).get(0.45), 0.5)          # the butt cap
    trig = M().poly(P.poly([(-19, AXIS_V - 3), (-11, AXIS_V - 3), (-12, AXIS_V - 13), (-16, AXIS_V - 17),
                            (-19, AXIS_V - 16), (-17, AXIS_V - 12)])).get(0.5)
    d.slab(trig, Z_FACE + 2.4, "seat_black", bevel=1.2, polish=0.6)
    seat = M().line([P(-13, AXIS_V), P(31, AXIS_V)], 8.0).get(0.45)
    d.slab(seat, Z_FACE + 3.2, "seat_black", bevel=2.0, polish=0.7)
    fore = M().line([P(30, AXIS_V), P(44, AXIS_V)], 8.5).get(0.45)
    d.slab(fore, Z_FACE + 3.0, "cork", bevel=4.0, polish=0.2, power=0.55)
    d.grain_pebble(fore, 0.06, seed=9)

    # ---- the reel: two paddle handles and the star drag on the far side, the low body, the side plate with the dial
    for (pu, pv) in ((-20, 30), (-6, 32)):
        pad = M().ellipse(*P(pu, pv), 5.2, 4.2).get(0.5)
        d.slab(pad, Z_FACE + 3.4, "reel_black", bevel=2.0, polish=0.55)
    arm = M().line([P(-20, 30), P(-6, 32)], 2.6).get(0.45)
    d.slab(arm, Z_FACE + 3.6, "chrome", bevel=0.8, polish=1.0)
    star = disc(d, *P(-13, 24), 4.0)
    d.slab(star, Z_FACE + 3.8, "chrome", bevel=1.2, polish=1.0)
    for kk in range(5):
        ang = kk * 72
        q = P(-13 + 4.2 * math.cos(math.radians(ang)), 24 + 4.2 * math.sin(math.radians(ang)))
        d.slab(disc(d, q[0], q[1], 1.2), Z_FACE + 3.6, "chrome", bevel=0.6, polish=1.0)
    body_uv = rounded([(-29, -14), (47, -14), (50, -2), (44, 19), (24, 24), (-22, 22), (-30, 10)], 6.0)
    body = M().poly(P.poly(body_uv)).get(0.5)
    d.slab(body, Z_FACE + 5.0, "reel_black", bevel=3.4, polish=0.7, power=0.6)
    d.grain_brushed(body, 0.03, seed=11)
    # the level wind at the front, where the line leaves the reel
    lw = M().line([P(45, -8), P(48, -5)], 3.0).get(0.45)
    d.slab(lw, Z_FACE + 5.6, "chrome", bevel=0.8, polish=1.0)
    # the side plate: a dark well round the dial, a chrome rim, the black face, the ticks
    dc = a["dial"]
    cx, cy, R = dc[0], dc[1], dc[2]
    plate_ = disc(d, cx + 0.5, cy + 0.5, R + 3.0) & body
    d.well(plate_, 0.6, "reel_plate", bevel=1.0)
    rim = ring(d, cx + 0.5, cy + 0.5, R - 2.0, R)
    d.slab(rim, Z_FACE + 5.6, "chrome", bevel=0.8, polish=1.0)
    face = disc(d, cx + 0.5, cy + 0.5, R - 2.0)
    d.flat(face, Z_FACE + 4.8, "dial_face", polish=0.3)
    n_t = 11
    for kk in range(n_t):
        deg = -135 + 270 * kk / (n_t - 1)
        rad = math.radians(deg)
        r0, r1 = R - 5.5, R - 3.0
        x0, y0 = cx + 0.5 + r0 * math.sin(rad), cy + 0.5 - r0 * math.cos(rad)
        x1, y1 = cx + 0.5 + r1 * math.sin(rad), cy + 0.5 - r1 * math.cos(rad)
        m = M().line([(x0, y0), (x1, y1)], 1.1).get(0.4) & face
        d.paint(m, "tick_red" if kk >= n_t - 3 else "tick_cream", flatlight=True)
    # MAX printed in red where the anchor says (the game lights a glow over it near the limit); DAIZO in gold
    mx, my, mw, mh = a["max"]
    d.text("MAX", int(round(mx + (mw - 11) / 2)), int(round(my + (mh - 5) / 2)), "tick_red", font="35", flatlight=True)
    dz = P(19, 6)
    d.text("DAIZO", int(round(dz[0])), int(round(dz[1])), "print_gold_r", font="35", flatlight=True)
    if worn:
        import wear as WR
        WR.scuffs(d, WR.mat_mask(d, "reel_black"), 0.0015, seed=5, amount=0.05)
    return p


def render(i, A=None):
    return rod(i, A).d.render(chrome_env="room")


def export(root, A=None):
    A = A or anchors()
    dd = os.path.join(root, "42", "media", "textures", "ZeD", "props")
    os.makedirs(dd, exist_ok=True)
    for i in range(FRAMES + 1):
        render(i, A).save(os.path.join(dd, f"rod_{i:02d}.png"))
    print("wrote rod_00 .. rod_16 to", dd)


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "mod", "ZeD-UI"))
