"""The doll: one figure for every pictogram person (director, Oct 27 2026: "follow a template or doll").

A fixed pixel budget per size, the same for every pose, so every figure weighs the same and reads the same:
      16: head 5 rows, neck gap 1, trunk 5, legs 5        (16 rows, the bottom row is the ground)
      24: head 7 rows, neck gap 1, trunk 8, legs 8        (24 rows)
The head, the trunk and the sockets the limbs leave from sit on exact pixel columns; only the limbs are posed, by
angles (degrees; 0 = hanging straight down; + = forward in the side view, away from the body in the front view),
drawn with square brushes whose joints snap to the grid (odd widths on pixel centres, even ones on grid lines).
Two views: front (stand, wave, shrug, point, surrender, salute) and side, facing right (walk, run, sit, crouch,
climb, carry). Props (chair, box, ladder) hang off the same joints."""
import math

from PIL import Image

BUDGET = {16: dict(head=5, gap=1, trunk=5, legs=5, body=5, side=3, arm=1, leg=2, upper=3.0, fore=2.5),
          24: dict(head=7, gap=1, trunk=8, legs=8, body=7, side=3, arm=2, leg=3, upper=4.5, fore=4.0)}


class Px:
    def __init__(s, w, h=None):
        s.w = w; s.h = h or w; s.on = set()

    def put(s, x, y, v=True):
        x, y = int(x), int(y)
        if 0 <= x < s.w and 0 <= y < s.h: (s.on.add((x, y)) if v else s.on.discard((x, y)))

    def rect(s, x, y, w, h, v=True):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)): s.put(xx, yy, v)

    def brush(s, x, y, w, v=True):
        bx = math.floor(x - w / 2 + 1e-6); by = math.floor(y - w / 2 + 1e-6)
        for dy in range(w):
            for dx in range(w): s.put(bx + dx, by + dy, v)

    def seg(s, p0, p1, w, v=True):
        (x0, y0), (x1, y1) = p0, p1
        n = max(1, int(math.ceil(math.hypot(x1 - x0, y1 - y0) * 3)))
        for i in range(n + 1):
            t = i / n; s.brush(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, w, v)

    def chain(s, pts, w, v=True):
        for a, b in zip(pts, pts[1:]): s.seg(a, b, w, v)

    def disc(s, x0, y0, d, v=True):
        """a d x d pixel disc, top-left (x0, y0), corners trimmed"""
        r = d / 2; cx, cy = x0 + r, y0 + r
        for y in range(y0, y0 + d):
            for x in range(x0, x0 + d):
                if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r - (0.5 if d >= 6 else 0.0) + 0.01: s.put(x, y, v)

    def image(s):
        im = Image.new("RGBA", (s.w, s.h), (255, 255, 255, 0))
        for x, y in s.on: im.putpixel((x, y), (255, 255, 255, 255))
        return im


def snap(p, w):
    if w % 2: return (math.floor(p[0]) + 0.5, math.floor(p[1]) + 0.5)
    return (round(p[0]), round(p[1]))


def dirv(a):
    r = math.radians(a); return math.sin(r), math.cos(r)


def limb(c, start, a1, a2, L1, L2, w, mirror=1):
    """a two-bone limb from a socket: a1 for the first bone, a2 relative for the second; mirror -1 for the other side"""
    d1 = dirv(mirror * a1); d2 = dirv(mirror * (a1 + a2))
    j = snap((start[0] + d1[0] * L1, start[1] + d1[1] * L1), w)
    e = snap((j[0] + d2[0] * L2, j[1] + d2[1] * L2), w)
    c.chain([start, j, e], w)
    return j, e


def front(c, n, x0, P):
    B = BUDGET[n]; hb = B["body"] // 2
    yt = B["head"] + B["gap"]; yl = yt + B["trunk"]
    c.disc(x0 - B["head"] // 2, 0, B["head"])
    c.rect(x0 - hb, yt, B["body"], B["trunk"])
    c.put(x0 - hb, yt, False); c.put(x0 + hb, yt, False)
    lw = B["leg"]
    for sg in (-1, 1):
        lx = x0 - lw / 2 if sg < 0 else x0 + 1 + lw / 2
        sp = P.get("splay", 0)
        c.seg((lx, yl + lw / 2), (lx + sg * sp, n - lw / 2), lw)
    J = {"hip": (x0, yl), "neck": (x0, yt)}
    aw = B["arm"]
    for side, sg in (("f", 1), ("b", -1)):
        if P.get("no_arm_" + side): continue
        sx = x0 + sg * (hb + 1) + (0.5 if aw % 2 else (1.0 if sg > 0 else 0.0))
        sy = yt + aw / 2 + (0 if aw % 2 == 0 else 0)
        sock = (sx, sy) if aw % 2 == 0 else (sx, yt + 0.5)
        J["el_" + side], J["wr_" + side] = limb(c, sock, P.get("sh_" + side, 20), P.get("el_" + side, 0),
                                                B["upper"], B["fore"], aw, mirror=sg)
    return J


def side(c, n, x0, P):
    B = BUDGET[n]
    yt = B["head"] + B["gap"]; yl = yt + B["trunk"]
    lean = P.get("lean", 0); sw = B["side"]
    tx = x0 - sw // 2
    for i in range(B["trunk"]):
        off = round(lean * (1 - i / max(1, B["trunk"] - 1)))
        c.rect(tx + off, yt + i, sw, 1)
    c.put(tx + lean, yt, False); c.put(tx + lean + sw - 1, yt, False)
    c.disc(x0 + lean - B["head"] // 2 + P.get("head_dx", 0), 0, B["head"])
    J = {"neck": (x0 + lean, yt), "hip": (x0, yl)}
    lw = B["leg"]
    hip = (x0 + (0.5 if lw % 2 else 0), yl - (0.5 if lw % 2 else 1))
    L = B["legs"] / 2
    for leg in ("b", "f"):
        if P.get("no_leg_" + leg): continue
        J["kn_" + leg], J["ft_" + leg] = limb(c, hip, P.get("hip_" + leg, 0), P.get("kn_" + leg, 0), L, L - lw / 2 + 0.5, lw)
    aw = B["arm"]
    sh = (x0 + lean + (0.5 if aw % 2 else 1), yt + (1.5 if aw % 2 else 2))
    for arm in ("b", "f"):
        if (arm == "b" and not P.get("back_arm")) or P.get("no_arm_" + arm): continue
        J["el_" + arm], J["wr_" + arm] = limb(c, sh, P.get("sh_" + arm, 0), P.get("el_" + arm, 0), B["upper"], B["fore"], aw)
    return J


POSES = {
    "stand": dict(view="front", sh_f=20, sh_b=20),
    "wave": dict(view="front", sh_f=150, el_f=15, sh_b=20),
    "shrug": dict(view="front", sh_f=75, el_f=-105, sh_b=75, el_b=-105),
    "point": dict(view="front", sh_f=90, sh_b=20),
    "surrender": dict(view="front", sh_f=125, el_f=55, sh_b=125, el_b=55),
    "salute": dict(view="front", sh_f=80, el_f=-140, sh_b=20),
    "walk": dict(view="side", lean=1, sh_f=45, el_f=35, back_arm=True, sh_b=-45, el_b=25, hip_f=35, kn_f=0, hip_b=-35, kn_b=10),
    "run": dict(view="side", lean=3, sh_f=80, el_f=-90, back_arm=True, sh_b=-60, el_b=60, hip_f=85, kn_f=-95, hip_b=-45, kn_b=30),
    "sit": dict(view="side", sh_f=40, el_f=45, hip_f=90, kn_f=-90, hip_b=90, kn_b=-90),
    "crouch": dict(view="side", lean=3, sh_f=60, el_f=0, hip_f=115, kn_f=-160, hip_b=60, kn_b=-140, head_dy=0),
    "climb": dict(view="side", sh_f=165, el_f=0, hip_f=100, kn_f=-100, hip_b=10),
    "carry": dict(view="side", sh_f=80, el_f=10, hip_f=20, kn_f=-5, hip_b=-20, kn_b=12),
}


def _chair(c, n, J):
    B = BUDGET[n]; hx, hy = J["hip"]
    seat = int(hy); x0 = int(hx) - B["side"] // 2 - 1; x1 = int(J["kn_f"][0]) + 1
    c.rect(x0, seat, x1 - x0 + 1, 1)
    c.rect(x0 - 1, seat - (5 if n == 16 else 8), 1, (5 if n == 16 else 8) + 1)
    c.rect(x0 - 1, seat, 1, c.h - seat); c.rect(x1, seat, 1, c.h - seat)


def _box(c, n, J):
    wx, wy = J["wr_f"]; s_ = 5 if n == 16 else 8
    c.rect(int(wx) - 1, int(wy) - s_ + 2, s_, s_)


def _ladder(c, n, J):
    wx, wy = J["wr_f"]; x = int(wx) + 1; w = 5 if n == 16 else 7
    c.rect(x, 0, 1, c.h); c.rect(x + w - 1, 0, 1, c.h)
    for y in range(1, c.h, 3 if n == 16 else 4): c.rect(x, y, w, 1)


PROPS = {"sit": _chair, "carry": _box, "climb": _ladder}


def figure(n, name, P=None, warn=None, extra=None):
    P = P or POSES[name]
    W = n + 16
    c = Px(W, n)
    x0 = W // 2
    J = (front if P.get("view") == "front" else side)(c, n, x0, P)
    if name in PROPS: PROPS[name](c, n, J)
    if extra: extra(c, n, J)
    xs = [x for x, y in c.on]
    w = max(xs) - min(xs) + 1
    if w > n and warn is not None: warn.append(f"{name} {n}: {w} wide")
    ox = (n - w) // 2 - min(xs) + P.get("dx", 0)
    out = Px(n)
    for x, y in c.on: out.put(x + ox, y)
    return out.image()
