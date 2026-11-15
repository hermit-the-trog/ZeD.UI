"""The seat picker's cabin (the director, Nov 15 2026): "interior only ... Just show the floor, the dashboard, the
seats"; the box grows a row at a time (a truck's bench is the smallest). Then: knees out past the seat's edge, nothing
melted into anything (each part is drawn on its own and laid on in order: floor, dash, seats, people, things, wheel),
and the dashboard is the vehicle's own ZeD dashboard, shrunk ("a mini dashboard of one of our dashboards"), at the
same pixel size as the rest ("not very detailed ... more of a suggestion"), across the whole car: the stereo stack in
the middle over the console, the glove box on the passenger's side (minidash.py).
Parts are drawn the dashboards' way (dashpx) at 1 unit = 1 px and laid on at k."""
import sys
import os
HERE = os.path.dirname(os.path.abspath(__file__))
DASHPX = os.environ.get("ZED_DASHPX") or os.path.join(HERE, "..", "dashpx")   # ZeDUI/tools/dashpx beside this folder
import numpy as np
from PIL import Image
sys.path.insert(0, DASHPX); sys.path.insert(0, HERE)
from engine import Dash, Mask, add_ramp
import minidash as MD

import re

# the interior in the vehicle's own colour (the director, Nov 15 2026: "match the interior colors, like the floor and
# the seats"): the seats in the dashboard's own vinyl, the carpet a darker shade of it, the floor pan's rim between
_SRC = DASHPX + os.sep
CAB_BASE = {}
for _f in ("engine.py", "dashlib.py", "colors.py"):
    for _n, _h in re.findall(r'"([vl]_\w+)": "(#[0-9a-fA-F]{6})"', open(_SRC + _f).read()): CAB_BASE[_n] = _h

def _shade(hexc, k):
    r, g, b = (int(hexc[i:i + 2], 16) for i in (1, 3, 5))
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(c * k))) for c in (r, g, b))

def interior(cab):
    """(seat, carpet, rim) materials for a cabin colour"""
    base = CAB_BASE[cab]
    if "carpet_" + cab not in _DONE:
        add_ramp("carpet_" + cab, _shade(base, 0.62)); add_ramp("tub_" + cab, _shade(base, 0.85)); _DONE.add("carpet_" + cab)
    return cab, "carpet_" + cab, "tub_" + cab
_DONE = set()
add_ramp("cardboard", "#9a7a4e"); add_ramp("duffel", "#4d5a3c"); add_ramp("accent", "#3fa08f")
add_ramp("dummyY", "#e8c23a"); add_ramp("grey_d", "#7d8086")
add_ramp("accent_d", "#2c7366"); add_ramp("grey_d_d", "#5a5d63"); add_ramp("wheelrub", "#232326")

BW = 112                      # the box
IN = 3                        # the tub's rim
DASH_W = BW - 2 * IN
WELL = 12                     # the footwell between the dash and the front seats (the wheel sits over it)
ROW = 52
PAD = 6
SEAT_W, SEAT_H, GAP = 46, 42, 8
LX = (BW - 2 * SEAT_W - GAP) // 2
COL_X = LX + SEAT_W / 2 - IN  # on the dash: the column (the driver's middle) and the stack (the car's middle)
STACK_X = BW / 2 - IN
DASH_H = round(178 * (STACK_X - COL_X) / (MD.STACK_X - MD.COLUMN_X))    # the plate's own proportions at that scale (12)
_MINI = {}

def mini(dash):
    if dash not in _MINI: _MINI[dash] = MD.mini_dash(dash, DASH_W, COL_X, STACK_X)[0]
    return _MINI[dash]

def top(): return IN + DASH_H + WELL
def box_h(rows): return top() + len(rows) * ROW + PAD

def seat_boxes(rows):
    out = []
    for r in range(len(rows)):
        y = top() + r * ROW
        out.append((LX, y, SEAT_W, SEAT_H)); out.append((LX + SEAT_W + GAP, y, SEAT_W, SEAT_H))
    return out

def part(w, h, draw, seed=7):
    """one part on its own canvas (1 unit margin for the outline), rendered lit"""
    d = Dash(w + 2, h + 2, seed=seed)
    draw(d, 1, 1)
    return d.render(chrome_env="room")

def seat_part(w, h, mat, bench_split=False, headrest=True):
    def dr(d, x, y):
        d.slab(Mask(d.W, d.H).rrect(x + 2, y + 1, w - 4, h - 11, 5), 3.0, mat, bevel=3.0, polish=0.35)
        d.slab(Mask(d.W, d.H).rrect(x, y + h - 12, w, 11, 4), 6.5, mat, bevel=3.5, polish=0.35)
        if headrest:
            for hx in ([x + 14] if not bench_split else [x + 13, x + w - 13 - (w // 2 - 26)]):
                pass
        d.seam(Mask(d.W, d.H).rect(x + 6, y + 13, w - 12, 1).get(), 0.3)
        if bench_split: d.seam(Mask(d.W, d.H).rect(x + w // 2, y + 3, 1, h - 5).get(), 0.35)
    return part(w, h, dr)

def dummy_part(mine):
    """a crash test dummy from above, sitting: shoulders against the seat's back, thighs forward, the knees out past
    the cushion's front edge; the target on its head"""
    mat = "accent" if mine else "grey_d"
    W_, H_ = 40, 50
    def dr(d, x, y):
        legs = mat + "_d"
        for sx in (-1, 1):                                                   # thighs, a shade darker, knees out front
            d.slab(Mask(d.W, d.H).rrect(x + 20 + sx * 7 - 6, y, 12, 30, 6), 4.0, legs, bevel=3.0, polish=0.4)
        d.slab(Mask(d.W, d.H).rrect(x + 2, y + 26, 36, 14, 6), 5.5, mat, bevel=4, polish=0.4)      # shoulders
        d.dome(x + 20, y + 33, 8, 8, 7.0, "dummyY", polish=0.6)
        yy, xx = np.mgrid[0:d.H, 0:d.W]
        cx, cy = x + 20, y + 33
        q = (np.hypot(xx + 0.5 - cx, yy + 0.5 - cy) <= 8) & (((xx + 0.5 - cx) * (yy + 0.5 - cy)) > 0)
        d.paint(q, "paint_k")
    return part(W_, H_, dr)

def bag_part():
    return part(22, 13, lambda d, x, y: d.slab(Mask(d.W, d.H).rrect(x, y, 22, 13, 6), 5.0, "duffel", bevel=3, polish=0.3))

def box_part():
    def dr(d, x, y):
        d.slab(Mask(d.W, d.H).rrect(x, y, 20, 15, 1), 6.0, "cardboard", bevel=1.0, polish=0.2)
        d.seam(Mask(d.W, d.H).rect(x, y + 7, 20, 1).get(), 0.45)
    return part(20, 15, dr)

def console_part(h):
    def dr(d, x, y):
        d.slab(Mask(d.W, d.H).rrect(x, y, 6, h, 2), 4.0, "blackp", bevel=1.5, polish=0.3)
        d.dome(x + 3, y + 8, 2.4, 2.4, 3.0, "chrome")
    return part(6, h, dr)

def wheel_part():
    """the steering wheel from above: nearly upright, so a flat ring; its column into the dash"""
    def dr(d, x, y):
        d.slab(Mask(d.W, d.H).rect(x + 11, y, 3, 5), 3.0, "blackp", bevel=1.0, polish=0.4)              # the column
        ring = Mask(d.W, d.H).ellipse(x + 12.5, y + 7, 12.5, 4.5).get() & ~Mask(d.W, d.H).ellipse(x + 12.5, y + 7, 9.5, 2.0).get()
        d.slab(ring, 4.0, "wheelrub", bevel=1.2, polish=0.5)
        d.slab(Mask(d.W, d.H).rrect(x + 9, y + 5, 7, 4, 1), 4.5, "blackp", bevel=1.0, polish=0.5)       # the hub
    return part(25, 12, dr)

def floor_part(rows, carpet, tub):
    H = box_h(rows)
    d = Dash(BW, H, seed=5)
    d.slab(Mask(BW, H).rrect(0, 0, BW, H, 7), 5.0, tub, bevel=2.5, polish=0.3)
    m = Mask(BW, H).rrect(IN, IN, BW - 2 * IN, H - 2 * IN, 5)
    d.well(m, 3.5, carpet, bevel=1.2, polish=0.1)
    d.grain_pebble(m.get(), 0.05, seed=5)
    return d.render(chrome_env="room")

def cabin(rows, states, dash, k):
    """the cabin at k pixels a unit"""
    H = box_h(rows)
    seat_m, carpet_m, tub_m = interior(dash.split("__")[1])
    img = floor_part(rows, carpet_m, tub_m).resize((BW * k, H * k), Image.NEAREST)
    def lay(p, x, y):
        img.alpha_composite(p.resize((p.width * k, p.height * k), Image.NEAREST), (int((x - 1) * k), int((y - 1) * k)))
    lay(mini(dash), IN + 1, IN + 1)                   # the vehicle's own dashboard, at the cabin's pixel size
    boxes = seat_boxes(rows)
    for r, kind in enumerate(rows):
        a, b = boxes[2 * r], boxes[2 * r + 1]
        sa, sb = states.get(2 * r + 1, "free"), states.get(2 * r + 2, "free")
        if kind == "bench":
            if sa != "missing" and sb != "missing":
                lay(seat_part(b[0] + b[2] - a[0], SEAT_H, seat_m, bench_split=True), a[0], a[1])
            else:
                for (x, y, w, h), st in ((a, sa), (b, sb)):
                    if st != "missing": lay(seat_part(w + GAP // 2, h, seat_m), x if x == LX else x - GAP // 2, y)
        else:
            if r == 0: lay(console_part(SEAT_H - 8), LX + SEAT_W + 1, a[1] + 2)
            for (x, y, w, h), st in ((a, sa), (b, sb)):
                if st != "missing": lay(seat_part(w, h, seat_m), x, y)
    for i, (x, y, w, h) in enumerate(boxes):
        st = states.get(i + 1, "free")
        if st in ("you", "other"):
            lay(dummy_part(st == "you"), x + w / 2 - 20, y - 6)              # the knees 7 past the cushion's edge
        if st == "items":
            lay(bag_part(), x + 20, y + 21)                                   # the bag first; the box sits on it
            lay(box_part(), x + 6, y + 18)
    if states.get(1) != "missing":
        lay(wheel_part(), LX + SEAT_W / 2 - 12.5, IN + DASH_H - 2)           # over the driver's knees
    return img

