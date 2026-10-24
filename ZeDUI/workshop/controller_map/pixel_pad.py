"""ZeDUI/workshop/controller_map/pixel_pad.py  (Oct 23 2026)

The controller for the Workshop's controller map card, in the ZNIX USER cover's pixel
art (ZeDUI/workshop/thumbnail/pixel_znix.py): the cover's palette (the beige computer
plastics b0..b5, the accents), hard edges, light from the top left (b0 rims up and left,
b4 / b5 rims down and right), ordered dither for the shading, the mod's own pixel faces
for the printed labels, the cover's typeface (fxc900.ttf) for the ZeD mark.

Director, Oct 23: "draw the controller in our on brand pixel art style", then "SNES/Genesis
shape controller, with modern buttons." A 16-bit era dog bone body (no maker's logo), beige
like the 1993 computer on the cover, with today's two sticks and four shoulder buttons. The face buttons carry the
letters ZeD's prompts use (A B X Y); the card's balloons give the PlayStation names.

Drawn on a 200 x 136 grid on a transparent ground, then scaled x8 (nearest neighbour) to
1600 x 1088: controller_pad_px.png. make_shots places it at half size (every art pixel a
clean 4 x 4 block on the 1920 card; "frame": false, "resample": "nearest").
Art-pixel positions of each control are printed for the card's balloon anchors
(source px = art px x 8 + 4).

Run (Linux shell or Windows, Pillow):  python3 pixel_pad.py
"""
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FXC = os.path.join(HERE, "..", "thumbnail", "fxc900.ttf")
GW, GH, K = 200, 136, 8

C = dict(
    ink=(20, 20, 20), wht=(255, 255, 255),
    b0=(250, 245, 232), b1=(228, 220, 200), b2=(206, 197, 174), b3=(172, 162, 138), b4=(124, 115, 96), b5=(84, 77, 63),
    red=(200, 32, 42), redD=(132, 16, 24), redL=(232, 84, 76),
    grn=(31, 122, 98), grnD=(18, 78, 62), grnL=(72, 170, 140),
    blu=(68, 136, 204), bluD=(40, 88, 150), bluL=(130, 180, 230),
    yel=(204, 170, 34), yelD=(150, 120, 20), yelL=(240, 214, 110),
    org=(212, 146, 42), shadow=(0, 0, 0),
)

# the mod's 3 x 5 pixel face (PixelFonts.lua), the letters the labels need
F35 = {
    'A': ["010", "101", "111", "101", "101"], 'B': ["110", "101", "110", "101", "110"], 'E': ["111", "100", "110", "100", "111"],
    'I': ["111", "010", "010", "010", "111"], 'L': ["100", "100", "100", "100", "111"], 'M': ["10001", "11011", "10101", "10001", "10001"],
    'N': ["1001", "1101", "1011", "1001", "1001"], 'R': ["110", "101", "110", "101", "101"], 'T': ["111", "010", "010", "010", "010"],
    'U': ["101", "101", "101", "101", "111"], 'V': ["101", "101", "101", "101", "010"], 'W': ["10001", "10001", "10101", "10101", "01010"],
    'X': ["101", "101", "010", "101", "101"], 'Y': ["101", "101", "010", "010", "010"], ' ': ["00", "00", "00", "00", "00"],
}
F57 = {
    'A': ["01110", "10001", "10001", "11111", "10001", "10001", "10001"], 'B': ["11110", "10001", "11110", "10001", "10001", "10001", "11110"],
    'X': ["10001", "10001", "01010", "00100", "01010", "10001", "10001"], 'Y': ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    ' ': ["000", "000", "000", "000", "000", "000", "000"],
}

im = Image.new("RGBA", (GW, GH), (0, 0, 0, 0))
px = im.load()


def P(x, y, c):
    if 0 <= x < GW and 0 <= y < GH:
        px[x, y] = (C[c] if isinstance(c, str) else c) + (255,)


def text(s, x, y, c, font=F35, gap=1):
    for ch in s:
        g = font.get(ch, font[' '])
        for j, row in enumerate(g):
            for i, b in enumerate(row):
                if b == '1':
                    P(x + i, y + j, c)
        x += len(g[0]) + gap
    return x


def tw(s, font=F35, gap=1):
    return sum(len(font.get(ch, font[' '])[0]) + gap for ch in s) - gap


BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def mask_of(draw_fn):
    m = Image.new("L", (GW, GH), 0)
    draw_fn(ImageDraw.Draw(m))
    return m.load()


def inside(m, x, y):
    return 0 <= x < GW and 0 <= y < GH and m[x, y] > 127


def shade(m, base, dark, t0, t1, y0, y1, hi="b0", lo="b4", lo2=None):
    """fill a mask: base dithered toward dark from t0 (top) to t1 (bottom); a light rim where the
    pixel above or to the left is outside, a dark rim where the pixel below or to the right is"""
    for y in range(GH):
        for x in range(GW):
            if not inside(m, x, y):
                continue
            f = (y - y0) / max(1, y1 - y0)
            t = t0 + (t1 - t0) * max(0.0, min(1.0, f))
            c = dark if (BAYER[y % 4][x % 4] + .5) / 16 < t else base
            if not inside(m, x, y - 1) or not inside(m, x - 1, y):
                c = hi
            if not inside(m, x, y + 1) or not inside(m, x + 1, y):
                c = lo
            if lo2 and (not inside(m, x, y + 2) or not inside(m, x + 2, y)) and c != lo and c != hi:
                c = lo2
            P(x, y, c)


def hard_shadow(m, dx=2, dy=2):
    for y in range(GH):
        for x in range(GW):
            if inside(m, x, y) and not inside(m, x + dx, y + dy):
                P(x + dx, y + dy, (0, 0, 0))


def disc(cx, cy, r):
    return lambda d: d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)


# ---- geometry (art px) -------------------------------------------------------------------
# Director, Oct 23: "SNES/Genesis shape controller, with modern buttons." A flat dog bone: two
# round lobes joined by a bridge, the bridge's underside bowed up a little the way the Genesis
# pad dips between the hands; no hanging grips. The shoulders wrap the top of each lobe the way
# the SNES L and R do, with a trigger peeking out behind each bumper.
import math
LOBE_L = (52, 80, 41)               # centre x, y, radius
LOBE_R = (148, 80, 41)             # Oct 23 clean-up: mirrored exactly about x = 100, the grid centre
BRIDGE = (52, 44, 148)              # left x, top y, right x (the top dips 5 px below the lobes')
BRIDGE_BOT = (119, 113)             # underside: y at the lobes, y at the centre (bowed up)
DPAD_C = (50, 71)                   # controls up 3 px: the top and bottom margins now match
FACE_C = (150, 71)
FACE = {"Y": (150, 59), "A": (150, 83), "X": (138, 71), "B": (162, 71)}
STICK_L = (84, 92)                  # each stick straight under View / Menu
STICK_R = (116, 92)
VIEW_ = (79, 65, 89, 69)
MENU_ = (111, 65, 121, 69)


def arc_band(cx, cy, r0, r1, a0, a1, n=64):
    """a band around a lobe's rim, angles in degrees (0 = right, 90 = down, so the top is 180..360)"""
    out = [(cx + r1 * math.cos(math.radians(a0 + (a1 - a0) * i / n)), cy + r1 * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]
    inn = [(cx + r0 * math.cos(math.radians(a1 - (a1 - a0) * i / n)), cy + r0 * math.sin(math.radians(a1 - (a1 - a0) * i / n))) for i in range(n + 1)]
    return out + inn


BODY_TOP = 38                       # one flat top across both lobes and the bridge (Oct 23: "raise the
TOP_R = 26                          #   top curves to fill the gap"), its corners tighter than the lobes
BOT_N = 2.4                         # the lobes' undersides: a superellipse, a little squarer than a circle


def body_draw(d):
    (lx, cy, r), (rx_, _, _) = LOBE_L, LOBE_R
    # the top half: one rounded slab from lobe edge to lobe edge
    d.rounded_rectangle([lx - r, BODY_TOP, rx_ + r, cy + 1], radius=TOP_R, fill=255, corners=(True, True, False, False))
    # the bottom half of each lobe, a little less round than a circle
    for cx in (lx, rx_):
        pts = []
        for i in range(181):
            t = math.pi * i / 180                     # 0..pi sweeps the lower half
            c, sn = math.cos(t), math.sin(t)
            pts.append((cx + r * math.copysign(abs(c) ** (2 / BOT_N), c), cy + r * abs(sn) ** (2 / BOT_N)))
        d.polygon(pts, fill=255)
    x0, y0, x1 = BRIDGE
    yl, yc = BRIDGE_BOT
    bot = [(x, yl - (yl - yc) * math.sin(math.pi * (x - x0) / (x1 - x0))) for x in range(x0, x1 + 1)]
    d.polygon([(x0, cy), (x1, cy)] + bot[::-1], fill=255)


body = mask_of(body_draw)

# ---- shoulders --------------------------------------------------------------------------------
STYLE = os.environ.get("PAD_SHOULDERS", "B")   # Oct 23: director picked B (flat bars)


def arc_capsule(cx, cy, rc, hw, a0, a1):
    """a curved capsule: a band hw either side of radius rc from a0 to a1, with round ends"""
    def draw(d):
        n = 90
        for i in range(n + 1):
            t = math.radians(a0 + (a1 - a0) * i / n)
            x, y = cx + rc * math.cos(t), cy + rc * math.sin(t)
            d.ellipse([x - hw, y - hw, x + hw, y + hw], fill=255)
    return draw


def shoulder(m, kind, ytop, ybot):
    hard_shadow(m, 2, 2)
    # a step darker than the body so each part reads on its own: the bumper b2, the trigger b4
    if kind == "T":
        shade(m, "b4", "b5", 0, .35, ytop, ybot, hi="b3", lo="ink")
    else:
        shade(m, "b2", "b3", 0, .45, ytop, ybot, hi="b0", lo="b4", lo2="b3")


SHOULDER = {}


def label_at(name, cx, cy, r, ang, c="ink"):
    lx = round(cx + r * math.cos(math.radians(ang)))
    ly = round(cy + r * math.sin(math.radians(ang)))
    text(name, lx - tw(name) // 2, ly - 2, c)


if STYLE == "A":
    # SNES: each shoulder a curved capsule hugging the top of its lobe; the trigger rides behind
    # and above the bumper, shorter, darker, set toward the outside where the finger reaches it
    for side, (cx, cy, rl) in (("L", LOBE_L), ("R", LOBE_R)):
        flip = (lambda a: a) if side == "L" else (lambda a: 540 - a)
        ta0, ta1 = sorted((flip(222), flip(262)))
        ba0, ba1 = sorted((flip(216), flip(290)))
        tm = mask_of(arc_capsule(cx, cy, 52, 6, ta0, ta1))
        shoulder(tm, "T", cy - 58, cy - 46)
        label_at(side + "T", cx, cy, 54, flip(238), "b1")
        bm = mask_of(arc_capsule(cx, cy, 44, 5, ba0, ba1))
        shoulder(bm, "B", cy - 49, cy - 39)
        label_at(side + "B", cx, cy, 45, flip(246))
else:
    # flat bars side by side on the top edge (Oct 23: "trigger bumper side by side instead of on
    # top of one another"; then "the curve of the trigger starts at the body curve ends. Put the
    # button label above not in, the bumpers slightly overlap the inside edge of triggers").
    # The trigger's corner curve starts where the body's top corner curve meets the flat top; it is a
    # little taller and darker; the bumper, shorter and wider, is drawn after it, lapping just past
    # the trigger's centre.
    # The names are printed above each button, light, for the gallery's dark ground.
    # Oct 23: "Right at the body curve end": the trigger's own corner curve begins there, so its
    # outer edge sits one trigger radius further out
    TR = 6                                          # the trigger's corner radius
    flat_l = LOBE_L[0] - LOBE_L[2] + TOP_R - TR     # x where the top-left corner curve ends, less TR
    flat_r = LOBE_R[0] + LOBE_R[2] - TOP_R + TR     # x where the top-right one begins, plus TR
    TW, BW, LAP = 25, 34, 14                        # Oct 23: bumpers shorter, wider, lapping just past
    BTOP = 49                                       #   the trigger's centre (TW / 2 = 12.5); BTOP: cy - top
    for side, (cx, cy, rl) in (("L", LOBE_L), ("R", LOBE_R)):
        if side == "L":
            T = (flat_l, cy - 56, flat_l + TW, cy - 40)
            B = (T[2] - LAP, cy - BTOP, T[2] - LAP + BW, cy - 40)
        else:
            T = (flat_r - TW, cy - 56, flat_r, cy - 40)
            B = (T[0] + LAP - BW, cy - BTOP, T[0] + LAP, cy - 40)
        SHOULDER[side + "T"], SHOULDER[side + "B"] = T, B
        for r, kind in ((T, "T"), (B, "B")):
            m = mask_of(lambda d, q=r: d.rounded_rectangle(q, radius=TR if kind == "T" else 5, fill=255))
            shoulder(m, kind, r[1], r[3])
            # each name the same 3 px gap above its own button (Oct 23); the bumper's centred on the
            # part of it that shows past the trigger, which keeps it clear of the trigger
            name = side + kind
            if kind == "T":
                mid = (r[0] + r[2]) // 2
            else:
                mid = (T[2] + r[2]) // 2 if side == "L" else (r[0] + T[0]) // 2
            text(name, mid - tw(name) // 2 + 1, r[1] - 8, "b2")

# ---- the body ------------------------------------------------------------------------------
hard_shadow(body, 3, 3)
shade(body, "b1", "b2", .05, .75, BODY_TOP, 150, hi="b0", lo="b4", lo2="b3")

# the ZeD mark, the cover's typeface, red with its dark shadow, top centre
f = ImageFont.truetype(FXC, 13)
mk = Image.new("L", (80, 30), 0)
md = ImageDraw.Draw(mk)
md.fontmode = "1"
md.text((0, 0), "ZeD", font=f, fill=255)
mk = mk.crop(mk.getbbox())
ma = mk.load()
mx, my = (GW - mk.size[0]) // 2, 47
for j in range(mk.size[1]):
    for i in range(mk.size[0]):
        if ma[i, j] > 127:
            P(mx + i + 1, my + j + 1, "redD")
for j in range(mk.size[1]):
    for i in range(mk.size[0]):
        if ma[i, j] > 127:
            P(mx + i, my + j, "red")


# a recessed well: darker rim up and left (the shadow inside), light lip down and right
def well(cx, cy, r, base="b2"):
    m = mask_of(disc(cx, cy, r))
    for y in range(GH):
        for x in range(GW):
            if not inside(m, x, y):
                continue
            c = base
            if not inside(m, x, y - 1) or not inside(m, x - 1, y):
                c = "b4"
            elif not inside(m, x, y - 2) or not inside(m, x - 2, y):
                c = "b3"
            if not inside(m, x, y + 1) or not inside(m, x + 1, y):
                c = "b0"
            P(x, y, c)


# ---- D-pad -----------------------------------------------------------------------------------
dx, dy = DPAD_C
well(dx, dy, 17)                    # a little larger, to weigh the same as the face buttons' well
cross = mask_of(lambda d: (d.rectangle([dx - 4, dy - 13, dx + 4, dy + 13], fill=255),
                           d.rectangle([dx - 13, dy - 4, dx + 13, dy + 4], fill=255)))
hard_shadow(cross, 1, 1)
shade(cross, "b5", "b5", 0, 0, dy - 13, dy + 13, hi="b4", lo="ink")
for (ax, ay, vx, vy) in ((0, -10, 0, 1), (0, 10, 0, -1), (-10, 0, 1, 0), (10, 0, -1, 0)):   # arrows pressed in
    tx, ty = dx + ax, dy + ay
    for k in range(3):
        for s in range(-k, k + 1):
            if vx == 0:
                P(tx + s, ty + k * vy, "b3")
            else:
                P(tx + k * vx, ty + s, "b3")
P(dx, dy, "b4")

# ---- face buttons -----------------------------------------------------------------------------
well(FACE_C[0], FACE_C[1], 21)
COL = {"A": ("grn", "grnD", "grnL", "wht"), "B": ("red", "redD", "redL", "wht"),
       "X": ("blu", "bluD", "bluL", "wht"), "Y": ("yel", "yelD", "yelL", "ink")}
for k, (cx, cy) in FACE.items():
    base, dark, light, lab = COL[k]
    m = mask_of(disc(cx, cy, 6))
    hard_shadow(m, 1, 1)
    shade(m, base, dark, 0, .5, cy - 6, cy + 6, hi=light, lo=dark)
    g = F57[k]
    text(k, cx - len(g[0]) // 2, cy - 3, lab, F57)

# ---- View and Menu, with their names printed under them -----------------------------------------
for box, lab in ((VIEW_, "VIEW"), (MENU_, "MENU")):
    m = mask_of(lambda d, b=box: d.rounded_rectangle(b, radius=2, fill=255))
    hard_shadow(m, 1, 1)
    shade(m, "b4", "b4", 0, 0, box[1], box[3], hi="b3", lo="b5")
    text(lab, (box[0] + box[2]) // 2 - tw(lab) // 2 + 1, box[3] + 3, "b4")

# ---- sticks -----------------------------------------------------------------------------------
for (cx, cy) in (STICK_L, STICK_R):
    well(cx, cy, 13, base="b3")
    cap = mask_of(disc(cx, cy, 9))
    hard_shadow(cap, 1, 1)
    shade(cap, "b5", "b5", 0, 0, cy - 9, cy + 9, hi="b4", lo="ink")
    ring = mask_of(lambda d, x=cx, y=cy: d.ellipse([x - 5, y - 5, x + 5, y + 5], outline=255))
    for y in range(GH):
        for x in range(GW):
            if inside(ring, x, y):
                P(x, y, "b4" if (x + y) % 2 == 0 else "b5")
    P(cx - 4, cy - 6, "b3"); P(cx - 5, cy - 5, "b3"); P(cx - 6, cy - 4, "b3")   # a glint, top left

out = im.resize((GW * K, GH * K), Image.NEAREST)
suffix = "" if STYLE == "B" else "_" + STYLE
out.save(os.path.join(HERE, "controller_pad_px%s.png" % suffix), optimize=True)
im.resize((GW * 3, GH * 3), Image.NEAREST).save(os.path.join(HERE, "controller_pad_px%s_preview.png" % suffix))


def src(p):
    return (p[0] * K + K // 2, p[1] * K + K // 2)


print("anchors (source px):")
for name, p in (("LT", ((SHOULDER["LT"][0] + SHOULDER["LT"][2]) // 2, SHOULDER["LT"][1] - 10)), ("LB", ((SHOULDER["LT"][2] + SHOULDER["LB"][2]) // 2, SHOULDER["LB"][1] - 10)),
                ("RT", ((SHOULDER["RT"][0] + SHOULDER["RT"][2]) // 2, SHOULDER["RT"][1] - 10)), ("RB", ((SHOULDER["RB"][0] + SHOULDER["RT"][0]) // 2, SHOULDER["RB"][1] - 10)),
                ("DPAD", (DPAD_C[0] - 13, DPAD_C[1])),
                ("VIEW", (VIEW_[0], (VIEW_[1] + VIEW_[3]) // 2)), ("MENU", (MENU_[2], (MENU_[1] + MENU_[3]) // 2)),
                ("Y", (FACE["Y"][0] + 6, FACE["Y"][1])), ("X", (FACE["X"][0], FACE["X"][1] - 6)),
                ("B", (FACE["B"][0] + 6, FACE["B"][1])), ("A", (FACE["A"][0] + 6, FACE["A"][1])),
                ("LS", (STICK_L[0] - 9, STICK_L[1] + 6)), ("RS", (STICK_R[0] + 9, STICK_R[1] + 6))):
    print("  %-5s %s" % (name, src(p)))
print("size", out.size)
