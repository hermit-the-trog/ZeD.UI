"""ZeDUI/tools/qa/scale_even_check.py  (Oct 21 2026)

Measures the captures of zedqa_scale_even.lua: line thicknesses and art-pixel
block sizes, so "even at every scale step" is a number, not a look.

    py scale_even_check.py <console.txt> <screenshot dir> [--label before]

Reads the "ZEDQA se ..." lines of the console for the geometry, opens
zqa_se_<step>_<what>.png from the screenshot dir and reports per step:

  frame    the window frame's thickness on each edge (both windows), sampled
           at many points along each edge: one value per edge means even
  lines    every horizontal line inside each window (a run of one colour 1-8
           px tall that carries on at least 40 px to both sides), grouped by
           colour: thickness histogram per colour, and the pitch between
           repeated lines of the same colour (row dividers)
  art      for the mini watch, the popped watch, the dashboard and the body
           figure: the zoom k expected (the drawn size over the art size), the
           share of colour edges that fall on the k grid, and the run-length
           histogram (every run a multiple of k when each art pixel is k x k)

Stdlib + PIL only.
"""
import os
import re
import sys
from collections import Counter, defaultdict

from PIL import Image

STEPS = ["x125", "x150", "x175", "x200"]
MINI_W, MINI_H = 44, 46      # WatchMini art
FIG_W, FIG_H = 220, 260      # body figure canvas
DASH_W = 792                 # ZeD_Dashboard BASE_W (checked from the console's rect / k)


def parse_console(path):
    raw = open(path, "rb").read().replace(b"\x00", b"").decode("utf-8", "replace")
    geo = defaultdict(dict)
    for line in raw.splitlines():
        m = re.search(r"ZEDQA se (x\d+) (geom|health|belt|watch|dash) (.*)$", line)
        if not m:
            continue
        step, kind, rest = m.groups()
        kv = {}
        for k, v in re.findall(r"(\w+)=(\S+)", rest):
            kv[k] = v
        geo[step][kind] = kv
    return geo


def rect(s):
    if not s or s == "nil":
        return None
    try:
        return tuple(int(float(v)) for v in s.split(","))
    except ValueError:
        return None


def close(a, b, tol=6):
    return abs(a[0] - b[0]) <= tol and abs(a[1] - b[1]) <= tol and abs(a[2] - b[2]) <= tol


def px(im, x, y):
    return im.getpixel((x, y))[:3]


# ---------------------------------------------------------------------------
# the frame: thickness on each edge
# ---------------------------------------------------------------------------
def edge_run(im, x, y, dx, dy, limit=12):
    c0 = px(im, x, y)
    n = 0
    while n < limit:
        xx, yy = x + dx * n, y + dy * n
        if not (0 <= xx < im.width and 0 <= yy < im.height):
            break
        if not close(px(im, xx, yy), c0, 4):
            break
        n += 1
    return n


def frame(im, r, top_skip):
    x, y, w, h = r
    out = {}
    ys = [y + top_skip + int((h - top_skip - 20) * i / 24) + 10 for i in range(25)]
    xs = [x + 20 + int((w - 40) * i / 24) for i in range(25)]
    out["left"] = Counter(edge_run(im, x, yy, 1, 0) for yy in ys)
    out["right"] = Counter(edge_run(im, x + w - 1, yy, -1, 0) for yy in ys)
    out["top"] = Counter(edge_run(im, xx, y, 0, 1) for xx in xs)
    out["bottom"] = Counter(edge_run(im, xx, y + h - 1, 0, -1) for xx in xs)
    return out


# ---------------------------------------------------------------------------
# horizontal lines inside a rect
# ---------------------------------------------------------------------------
def hlines(im, r, skip_top=0):
    x, y, w, h = r
    found = {}
    cols = [x + 12 + int((w - 24) * i / 15) for i in range(16)]
    for cx in cols:
        yy = y + skip_top
        while yy < y + h - 1:
            c = px(im, cx, yy)
            n = 1
            while yy + n < y + h and close(px(im, cx, yy + n), c, 2):
                n += 1
            if 1 <= n <= 8:
                above = px(im, cx, yy - 1) if yy > 0 else None
                below = px(im, cx, yy + n) if yy + n < im.height else None
                if above and below and not close(above, c, 6) and not close(below, c, 6):
                    ok = True
                    for d in (-40, -20, 20, 40):
                        xx = cx + d
                        if not (x <= xx < x + w) or not close(px(im, xx, yy), c, 2) or not close(px(im, xx, yy + n - 1), c, 2):
                            ok = False
                            break
                        # a line, not the top of a filled box: the pixel past it differs too
                        if close(px(im, xx, yy + n), c, 2) or close(px(im, xx, yy - 1), c, 2):
                            ok = False
                            break
                    if ok:
                        key = (yy, n)
                        found.setdefault(key, (c, cx))
            yy += n
    by_col = defaultdict(list)
    for (yy, n), (c, cx) in found.items():
        q = tuple(v // 8 * 8 for v in c)
        by_col[q].append((yy, n))
    return by_col


# ---------------------------------------------------------------------------
# pixel art: edge alignment on a k grid and run lengths
# ---------------------------------------------------------------------------
def art(im, r, k):
    x, y, w, h = r
    x0, y0 = max(0, x), max(0, y)
    x1, y1 = min(im.width, x + w), min(im.height, y + h)
    edges_x = Counter()
    runs = Counter()
    for yy in range(y0, y1):
        run_start = x0
        prev = px(im, x0, yy)
        for xx in range(x0 + 1, x1):
            c = px(im, xx, yy)
            if c != prev:
                edges_x[(xx - x) % k if k else 0] += 1
                if run_start > x0:
                    runs[xx - run_start] += 1
                run_start = xx
                prev = c
    edges_y = Counter()
    for xx in range(x0, x1, max(1, (x1 - x0) // 60)):
        prev = px(im, xx, y0)
        for yy in range(y0 + 1, y1):
            c = px(im, xx, yy)
            if c != prev:
                edges_y[(yy - y) % k if k else 0] += 1
                prev = c
    tot_x, tot_y = sum(edges_x.values()), sum(edges_y.values())
    on_x = max(edges_x.values()) / tot_x if tot_x else 0
    on_y = max(edges_y.values()) / tot_y if tot_y else 0
    mult = sum(n for L, n in runs.items() if k and L % k == 0)
    tot_r = sum(runs.values())
    small = {L: runs.get(L, 0) for L in range(1, 7)}
    return {"k": k, "grid_x": round(on_x, 3), "grid_y": round(on_y, 3),
            "runs_multiple_of_k": round(mult / tot_r, 3) if tot_r else 0, "runs_1to6": small}


def load(d, name):
    for cand in (name + ".png", name):
        p = os.path.join(d, cand)
        if os.path.exists(p):
            return Image.open(p).convert("RGB")
    return None


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    console, shots = sys.argv[1], sys.argv[2]
    label = sys.argv[sys.argv.index("--label") + 1] if "--label" in sys.argv else ""
    geo = parse_console(console)
    print("# scale_even_check %s" % label)
    for step in STEPS:
        g = geo.get(step)
        if not g:
            print("\n## %s: no geometry in the console" % step)
            continue
        gg = g.get("geom", {})
        print("\n## %s  root=%s px1=%s rowH=%s titleBarH=%s pk=%s art=%s" % (
            step, gg.get("root"), gg.get("px1"), gg.get("rowH"), gg.get("titleBarH"), gg.get("pk"), gg.get("art")))
        im = load(shots, "zqa_se_%s_win" % step)
        tb = int(gg.get("titleBarH", "0") or 0)
        if im:
            for name in ("char", "world", "card"):
                r = rect(gg.get(name))
                if not r:
                    continue
                if name != "card":
                    f = frame(im, r, tb + 4)
                    print("  frame %-5s %s  " % (name, r) + "  ".join("%s=%s" % (e, dict(c)) for e, c in f.items()))
                lines = hlines(im, r, tb + 2 if name != "card" else 0)
                for col, ls in sorted(lines.items(), key=lambda kv: -len(kv[1])):
                    if len(ls) < 2:
                        continue
                    th = Counter(n for _, n in ls)
                    ys = sorted(yy for yy, _ in ls)
                    pitch = Counter(b - a for a, b in zip(ys, ys[1:]))
                    print("  lines %-5s colour %s  n=%d thickness=%s pitch=%s" % (
                        name, col, len(ls), dict(th), dict(pitch.most_common(6))))
        else:
            print("  (no window capture)")
        # the mini watch on the belt
        b = g.get("belt", {})
        wr = rect(b.get("watch"))
        im = load(shots, "zqa_se_%s_belt" % step)
        if im and wr:
            # the art is centred in the box at the multiple used; find it from the box and k guesses
            for k in (1, 2):
                aw, ah = MINI_W * k, MINI_H * k
                ax, ay = wr[0] + (wr[2] - aw) // 2, wr[1] + (wr[3] - ah) // 2
                if aw <= wr[2] + 2 * k + 24:
                    a = art(im, (ax, ay, aw, ah), k)
                    print("  mini watch box=%s try k=%d art rect=%s: %s" % (wr, k, (ax, ay, aw, ah), a))
        c = b.get("closure")
        print("  belt hud=%s closure k=%s buckle=%s" % (b.get("hud"), b.get("k"), b.get("buckle")))
        # the popped watch
        wt = g.get("watch", {})
        r = rect(wt.get("rect"))
        im = load(shots, "zqa_se_%s_pop" % step)
        if im and r:
            k = int(wt.get("k", "1") or 1)
            print("  watch rect=%s k=%s: %s" % (r, k, art(im, r, k)))
        # the dashboard
        d = g.get("dash", {})
        r = rect(d.get("rect"))
        im = load(shots, "zqa_se_%s_dash" % step)
        if im and r:
            k = int(float(d.get("k", "1") or 1))
            print("  dash rect=%s k=%s: %s" % (r, k, art(im, r, k)))
        # the body figure
        hh = g.get("health", {})
        im = load(shots, "zqa_se_%s_health" % step)
        try:
            s = float(hh.get("s"))
            if hh.get("absx", "nil") != "nil":
                fx, fy = int(float(hh["absx"])), int(float(hh["absy"]))
            else:
                # older captures: the Health panel sits right of the 36-unit tab strip, under the title bar
                root = float(gg.get("root", "1"))
                wx, wy = (int(v) for v in hh.get("winabs", "0,0").split(","))
                fx = wx + int(36 * root + 0.5) + int(float(hh["x"]))
                fy = wy + int(gg.get("titleBarH", "0")) + int(float(hh["y"]))
        except (TypeError, ValueError, KeyError):
            s, fx, fy = None, None, None
        if im and s and fx is not None:
            k = int(round(s)) if abs(s - round(s)) < 1e-6 else 0
            r = (fx, fy, int(FIG_W * s), int(FIG_H * s))
            print("  figure s=%s rect=%s on screen %dx%d: %s" % (s, r, r[2], r[3], art(im, r, k or 1)))
        elif hh:
            print("  figure s=%s (no screen origin printed)" % hh.get("s"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
