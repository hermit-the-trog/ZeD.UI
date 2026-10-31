"""The Workshop gallery's title card, in the mod's pixel art: a used copy of "Bitchin' znix Programs" on the desk,
marked up by the man who wrote the kernel. Drawn on a 480 x 270 grid with a fixed palette and ordered dither, then
scaled 4x (nearest) to 1920 x 1080, so every art pixel is a clean 4 x 4 block.
Lives in ZeDUI/workshop/gallery/. Fonts: the title face from ../thumbnail/fxc900.ttf, the two hands from ./fonts
(see fonts/FONTS.md); the mod's pixel faces from ../../tools/dashpx/engine.py.
usage: python cover_px.py [out.png]   (writes out.png at 1920 x 1080 and out_1x.png at 480 x 270)"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FD = os.path.join(HERE, "fonts")
W, H, S = 480, 270, 4
MARKER = os.path.join(FD, "PermanentMarker-Regular.ttf")
BALL = os.path.join(FD, "Caveat.ttf")
TITLE = os.path.join(HERE, "..", "thumbnail", "fxc900.ttf")

C = dict(
    # the desk
    wd0=(30, 22, 17), wd1=(42, 31, 24), wd2=(54, 40, 30), wd3=(66, 50, 37), wd4=(80, 61, 45),
    # the sky at dusk, faded
    s0=(28, 30, 52), s1=(40, 36, 64), s2=(58, 42, 74), s3=(84, 52, 80), s4=(112, 62, 74), s5=(140, 80, 66), s6=(166, 106, 70),
    cl0=(70, 56, 78), cl1=(96, 74, 90), sun=(196, 146, 86), sunD=(170, 118, 72), star=(150, 146, 170),
    sea0=(26, 32, 52), sea1=(36, 44, 68), sea2=(48, 58, 84), gl=(150, 112, 76),
    sd0=(118, 98, 66), sd1=(140, 118, 80), sd2=(160, 138, 94), sd3=(98, 80, 54),
    p0=(26, 40, 26), p1=(40, 60, 36), p2=(60, 84, 48), p3=(84, 106, 60),
    rb0=(120, 52, 66), rb1=(150, 82, 70), rb2=(96, 40, 54),
    tl0=(78, 128, 118), tl1=(92, 146, 134), tl2=(62, 104, 96),
    ink=(30, 26, 36), off=(226, 218, 198), offS=(52, 34, 58), yel=(196, 176, 104), yelS=(70, 50, 54),
    bad0=(204, 176, 70), board=(196, 186, 162), boardD=(160, 150, 128), wear=(176, 164, 140),
    page0=(214, 206, 184), page1=(188, 178, 156), spine=(52, 40, 60),
    tape0=(206, 198, 170), tape1=(180, 170, 142), coffee=(110, 76, 52),
    b0=(230, 222, 200), b1=(208, 198, 172), b2=(182, 172, 146), b3=(140, 130, 108), b4=(100, 92, 76), scr0=(18, 24, 30), scr1=(30, 44, 50),
    win=(150, 156, 150), winD=(96, 104, 100),
    red=(178, 38, 44), redD=(120, 24, 30), pen=(222, 70, 56), blu=(36, 52, 128), sticky=(214, 196, 98), stickyD=(176, 158, 72),
    fl0=(34, 36, 42), fl1=(50, 52, 60), fl2=(70, 72, 80), met0=(150, 154, 160), met1=(190, 194, 198), met2=(110, 114, 120),
    lab=(226, 220, 204), labL=(170, 180, 196), pen0=(200, 160, 60), pen1=(170, 130, 44), pen2=(230, 196, 104), wood=(214, 178, 132), lead=(40, 40, 44),
    pink=(196, 130, 130), metal=(160, 160, 160),
    gf0=(38, 38, 42), gf1=(54, 54, 58), gf2=(70, 70, 74),
    mug0=(196, 188, 170), mug1=(160, 152, 136), mug2=(120, 112, 100), cof0=(44, 28, 20), cof1=(66, 44, 30),
    flag0=(200, 170, 80), flag1=(176, 110, 104),
    pb0=(36, 60, 118), pb1=(58, 92, 160), pb2=(104, 140, 196), pw0=(226, 224, 214), pw1=(192, 190, 180), pw2=(146, 144, 136),
    brass=(196, 166, 92), tabB=(44, 62, 150), tabR=(178, 46, 44), tabK=(34, 34, 38), tabG=(56, 120, 70),
    rd0=(92, 28, 30), rd1=(128, 40, 40), rd2=(160, 62, 58),
    bb0=(92, 44, 18), bb1=(132, 68, 26), bb2=(170, 98, 40), bb3=(204, 138, 62),
    ic0=(176, 132, 84), ic1=(210, 178, 132), ic2=(236, 224, 200), gls=(150, 160, 164), glsH=(224, 230, 230),
)
BAY = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

im = Image.new("RGB", (W, H), C["wd1"])
px = im.load()
rng = random.Random(1993)


def col(c): return C[c] if isinstance(c, str) else c
def P(x, y, c):
    if 0 <= x < W and 0 <= y < H: px[x, y] = col(c)
def get(x, y): return px[x, y] if 0 <= x < W and 0 <= y < H else None
def R(x0, y0, x1, y1, c):
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(max(0, x0), min(W, x1 + 1)): px[x, y] = col(c)
def dith(x, y, t): return (BAY[y % 4][x % 4] + .5) / 16 < t
def band(x0, y0, x1, y1, ca, cb, t0, t1, mask=None):
    for y in range(y0, y1 + 1):
        f = (y - y0) / max(1, y1 - y0); t = t0 + (t1 - t0) * f
        for x in range(x0, x1 + 1):
            if mask and not mask(x, y): continue
            P(x, y, cb if dith(x, y, t) else ca)


# ---------------------------------------------------------------- type
def ttf_mask(s, size, path=TITLE):
    f = ImageFont.truetype(path, size)
    m = Image.new("L", (size * len(s) + 16, size * 2), 0); md = ImageDraw.Draw(m); md.fontmode = "1"
    md.text((4, 4), s, font=f, fill=255)
    return m.crop(m.getbbox())
def stamp(mask, x, y, c, shadow=None, dx=1, dy=1, rot=0):
    if rot: mask = mask.rotate(rot, resample=Image.NEAREST, expand=True)
    a = mask.load(); w, h = mask.size
    if shadow:
        for j in range(h):
            for i in range(w):
                if a[i, j] > 127: P(x + i + dx, y + j + dy, shadow)
    for j in range(h):
        for i in range(w):
            if a[i, j] > 127: P(x + i, y + j, c)
    return w, h

sys.path.insert(0, os.path.join(HERE, "..", "..", "tools", "dashpx"))
from engine import FONTS   # noqa: E402
def glyph(f, ch):
    return f.get(ch) or f.get(" ")
def text(s, x, y, c, font="57", gap=1, shadow=None):
    f = FONTS[font]
    for ch in s:
        g = glyph(f, ch)
        for (ox, oy, cc) in ((1, 1, shadow), (0, 0, c)) if shadow else ((0, 0, c),):
            for j, row in enumerate(g):
                for i, b in enumerate(row):
                    if b == "1": P(x + i + ox, y + j + oy, cc)
        x += len(g[0]) + gap
    return x
def tw(s, font="57", gap=1):
    f = FONTS[font]; return sum(len(glyph(f, ch)[0]) + gap for ch in s) - gap


# ---------------------------------------------------------------- the desk: long planks, quiet grain, light from the upper left
PL = 34
seams = {}
for p in range(H // PL + 2):
    seams[p] = rng.randrange(60, 420)                        # where this plank's butt joint falls
streaks = []
for p in range(H // PL + 2):
    for _ in range(5):
        streaks.append((p, rng.randrange(3, PL - 2), rng.random() * 6.28, rng.random() * 6.28, rng.choice(("wd0", "wd0", "wd2"))))
for y in range(H):
    for x in range(W):
        l = 1 - (0.6 * x / W + 0.45 * y / H)          # 1 at the top left, 0 at the bottom right
        c = "wd1"
        if dith(x, y, max(0, l - 0.45) * 1.4): c = "wd2"
        if dith(x, y, max(0, 0.42 - l) * 1.6): c = "wd0"
        px[x, y] = C[c]
for (p, oy, ph, ph2, c) in streaks:
    for x in range(W):
        y = p * PL + oy + int(round(1.6 * math.sin(x / 41 + ph) + 0.7 * math.sin(x / 13 + ph2)))
        if p * PL < y < (p + 1) * PL - 1 and math.sin(x / 23 + ph * 3) > -0.55:
            if c == "wd2" and get(x, y) == C["wd1"]: P(x, y, "wd3")
            elif c == "wd0": P(x, y, "wd0")
for p in range(H // PL + 2):
    for x in range(W): P(x, p * PL, "wd0"); P(x, p * PL + 1, "wd3") if dith(x, p, 0.3) else None
    sx = seams[p]
    for y in range(p * PL, (p + 1) * PL): P(sx, y, "wd0")


# ---------------------------------------------------------------- the book
BX, BY, BW, BH = 60, 12, 200, 247
def BP(x, y, c): P(BX + x, BY + y, c)
def BR(x0, y0, x1, y1, c): R(BX + x0, BY + y0, BX + x1, BY + y1, c)
def bd(x, y, t): return dith(BX + x, BY + y, t)

# shadow on the desk
for y in range(BY + 5, BY + BH + 6):
    for x in range(BX + 5, BX + BW + 8):
        if dith(x, y, 0.8): P(x, y, "wd0")
# page block at the fore-edge and the foot (a paperback, read many times)
for y in range(BY + 2, BY + BH + 1):
    P(BX + BW, y, "page1"); P(BX + BW + 1, y, "page0" if (y * 7) % 5 else "page1"); P(BX + BW + 2, y, "page1")
for x in range(BX + 2, BX + BW + 2):
    P(x, BY + BH, "page1"); P(x, BY + BH + 1, "page0" if (x * 7) % 5 else "page1")
# post-it flags stuck in at the fore-edge
for (fy, c, ln) in ((58, "flag0", 11), (64, "flag1", 8), (150, "flag0", 9)):
    R(BX + BW + 1, BY + fy, BX + BW + ln, BY + fy + 5, c)
    for x in range(BX + BW + 1, BX + BW + ln + 1): P(x, BY + fy + 5, "wd0")

HZ = 140
# the sky at dusk
SKY = ["s0", "s1", "s2", "s3", "s4", "s5", "s6"]
stops = [0, 34, 62, 88, 108, 124, 134, HZ]
for i in range(len(SKY) - 1):
    for y in range(stops[i], stops[i + 1] + 1):
        f = (y - stops[i]) / max(1, stops[i + 1] - stops[i])
        for x in range(BW):
            BP(x, y, SKY[i + 1] if bd(x, y, f) else SKY[i])
for _ in range(22):
    BP(rng.randrange(10, BW - 10), rng.randrange(3, 70), "star")
def cloud(cx, cy, w, h, c, c2):
    for y in range(cy - h, cy + h + 1):
        for x in range(cx - w, cx + w + 1):
            dx, dy = (x - cx) / w, (y - cy) / max(1, h)
            if dx * dx + dy * dy + 0.18 * math.sin(x * 0.4 + cy) < 1:
                BP(x, y, c2 if (y > cy and bd(x, y, 0.6)) else c)
cloud(150, 100, 46, 3, "cl1", "cl0"); cloud(56, 112, 50, 2, "cl1", "cl0"); cloud(132, 122, 40, 2, "cl0", "s3")
cloud(176, 88, 30, 2, "cl0", "s2"); cloud(26, 92, 28, 2, "cl0", "s2")
# the sun, half down, through the haze
SX = 109
for y in range(HZ - 10, HZ + 1):
    for x in range(SX - 11, SX + 12):
        d = math.hypot(x - SX, (y - HZ) * 1.15)
        if d < 10: BP(x, y, "sunD" if (d > 7.5 and bd(x, y, .5)) else "sun")
cloud(SX, 134, 14, 1, "s4", "s4")
# the sea and the sun's track on it
SAND = 158
for y in range(HZ + 1, SAND):
    for x in range(BW):
        k = (y - HZ) % 5
        c = "sea0" if k == 4 else ("sea2" if (k == 2 and bd(x, y, .35)) else "sea1")
        BP(x, y, c)
for y in range(HZ + 2, SAND, 2):
    w_ = 3 + (y - HZ) // 3
    for x in range(SX - w_, SX + w_):
        if bd(x, y, 0.55 - (y - HZ) / 50): BP(x, y, "gl")
# the sand
for y in range(SAND, 236):
    for x in range(BW):
        BP(x, y, "sd1" if bd(x, y, (y - SAND) / 78 * 0.7) else "sd0")
for (cx, cy, rx, ry) in [(30, 172, 14, 3), (150, 210, 20, 4), (96, 224, 12, 2), (182, 170, 12, 2), (60, 220, 10, 2)]:
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 < 1: BP(x, y, "sd3" if bd(x, y, .6) else "sd0")
for y in range(SAND + 1, 236):
    for x in range(BW):
        if (x * 7 + y * 13) % 23 == 0: BP(x, y, "sd2")
# the border along the foot
for y in range(236, BH):
    for x in range(BW):
        k = (x + (y - 236) * 2) % 12
        BP(x, y, "rb0" if k < 5 else ("rb1" if k < 8 else "rb2"))
for x in range(BW): BP(x, 236, "rb2")

# palm fronds down both edges
def frond(x0, y0, ang, length, curve, mirror):
    a = math.radians(ang)
    x1, y1 = x0 + math.cos(a) * length * .55, y0 + math.sin(a) * length * .55
    a2 = math.radians(ang + curve)
    x2, y2 = x1 + math.cos(a2) * length * .45, y1 + math.sin(a2) * length * .45
    n = 40
    for i in range(1, n):
        t = i / n
        bx = (1 - t) ** 2 * x0 + 2 * (1 - t) * t * x1 + t * t * x2
        by = (1 - t) ** 2 * y0 + 2 * (1 - t) * t * y1 + t * t * y2
        dx = 2 * (1 - t) * (x1 - x0) + 2 * t * (x2 - x1); dy = 2 * (1 - t) * (y1 - y0) + 2 * t * (y2 - y1)
        Ln = math.hypot(dx, dy); ux, uy = dx / Ln, dy / Ln; nx, ny = -uy, ux
        ll = (1 - t) ** 0.6 * length * 0.30 + 2
        if i % 2 == 0:
            for s_ in (1, -1):
                for k in range(int(ll)):
                    q = k / max(1, ll)
                    X = int(round(bx + ux * k * 0.5 + nx * s_ * k)); Y = int(round(by + uy * k * 0.5 + ny * s_ * k))
                    c = ("p1" if s_ > 0 else "p2") if q <= 0.7 else "p0"
                    if mirror: X = BW - 1 - X
                    if 0 <= X < BW and 0 <= Y < 236: BP(X, Y, c)
        X = int(round(bx)); Y = int(round(by))
        if mirror: X = BW - 1 - X
        if 0 <= X < BW and 0 <= Y < 236: BP(X, Y, "p0")
for mirror in (False, True):
    for ang, y, ln, cv in [(-34, 4, 56, 40), (-12, 34, 60, 34), (8, 120, 66, 30), (22, 156, 62, 30), (36, 190, 50, 34)]:
        frond(-6, y, ang, ln, cv, mirror)

# the title
t1 = ttf_mask("Bitchin\u2019 znix", 32); t2 = ttf_mask("Programs", 32)
TY1 = 19; TY2 = TY1 + t1.size[1] + 3
stamp(t1, BX + (BW - t1.size[0]) // 2, BY + TY1, "off", "offS", 1, 2)
stamp(t2, BX + (BW - t2.size[0]) // 2, BY + TY2, "off", "offS", 1, 2)
SY = TY2 + t2.size[1] + 5
l1, l2 = "A GUIDE TO LEARNING", "PEARS SOFTWARE"
text(l1, BX + (BW - tw(l1)) // 2, BY + SY, "yel", shadow="yelS")
sx2 = BX + (BW - tw(l2)) // 2
text(l2, sx2, BY + SY + 10, "yel", shadow="yelS")
SUB2 = (sx2, BY + SY + 10, sx2 + tw(l2), BY + SY + 16)

# the teal box: author, three plain lines
tx0, ty0, tx1, ty1 = BX + 10, BY + 125, BX + 100, BY + 209
band(tx0, ty0, tx1, ty1, "tl0", "tl2", 0.0, 0.4)
for x in range(tx0, tx1 + 1): P(x, ty0, "tl1")
for y in range(ty0, ty1 + 1): P(tx1 + 1, y, "tl2")
AUTH = (tx0 + 5, ty0 + 5)
text("ZNIX DOCS", AUTH[0], AUTH[1], "ink"); text("GROUP", AUTH[0], AUTH[1] + 9, "ink")
for x in range(tx0 + 4, tx1 - 3): P(x, ty0 + 27, "tl2"); P(x, ty0 + 28, "tl1")
y = ty0 + 33
for ls in (["FOR BUILD 42"], ["CHARACTER AND", "WORLD WINDOWS"], ["MOUSE AND", "GAMEPAD"]):
    R(tx0 + 4, y + 2, tx0 + 5, y + 3, "ink")
    for j, s_ in enumerate(ls): text(s_, tx0 + 9, y + j * 9, "ink", gap=1)
    y += len(ls) * 9 + 4
# the computer on the sand, backlit; its shadow toward us
cx0, cy0 = BX + 124, BY + 126
for y in range(cy0 + 58, BY + 210):
    sp = (y - (cy0 + 58)) * 0.6
    for x in range(int(cx0 + 2 - sp * 1.2), int(cx0 + 56 - sp * 0.4)):
        if dith(x, y, 0.55): P(x, y, "sd3")
R(cx0 + 2, cy0, cx0 + 50, cy0 + 44, "b2"); R(cx0, cy0 + 2, cx0 + 52, cy0 + 42, "b2")
band(cx0, cy0, cx0 + 52, cy0 + 44, "b2", "b3", 0.2, 0.85)
for x in range(cx0 + 2, cx0 + 51): P(x, cy0, "b1")
for y in range(cy0 + 2, cy0 + 43): P(cx0, y, "b1"); P(cx0 + 52, y, "b4")
R(cx0 + 6, cy0 + 5, cx0 + 46, cy0 + 34, "b4"); band(cx0 + 7, cy0 + 6, cx0 + 45, cy0 + 33, "scr1", "scr0", 0.0, 0.9)
wx0, wy0, wx1, wy1 = cx0 + 11, cy0 + 9, cx0 + 41, cy0 + 30
R(wx0, wy0, wx1, wy1, "win")
for x in range(wx0, wx1 + 1): P(x, wy0, "ink"); P(x, wy1, "ink"); P(x, wy0 + 4, "ink")
for yy in range(wy0, wy1 + 1): P(wx0, yy, "ink"); P(wx1, yy, "ink")
for x in range(wx0 + 6, wx1 - 1):
    P(x, wy0 + 1, "ink"); P(x, wy0 + 3, "ink")
R(wx0 + 2, wy0 + 1, wx0 + 4, wy0 + 3, "ink"); R(wx0 + 3, wy0 + 2, wx0 + 3, wy0 + 2, "win")
for k in range(4):
    R(wx0 + 3, wy0 + 7 + k * 5, wx0 + 5, wy0 + 8 + k * 5, "winD"); R(wx0 + 8, wy0 + 7 + k * 5, wx1 - 4 - (k % 3) * 4, wy0 + 7 + k * 5, "winD")
R(cx0 + 30, cy0 + 38, cx0 + 40, cy0 + 39, "b4"); P(cx0 + 44, cy0 + 38, (96, 150, 92))
R(cx0 + 18, cy0 + 45, cx0 + 34, cy0 + 47, "b3")
R(cx0 - 4, cy0 + 48, cx0 + 56, cy0 + 56, "b2"); band(cx0 - 4, cy0 + 48, cx0 + 56, cy0 + 56, "b2", "b3", 0.2, 0.9)
for x in range(cx0 - 4, cx0 + 57): P(x, cy0 + 48, "b1"); P(x, cy0 + 57, "b4")
for k in range(7): R(cx0 + k * 7, cy0 + 51, cx0 + k * 7 + 5, cy0 + 52, "b3")

# the publisher's badge, bottom right
bx0, by0 = BX + 171, BY + 211
R(bx0, by0, bx0 + 23, by0 + 21, "bad0")
for x in range(bx0, bx0 + 24): P(x, by0, "ink"); P(x, by0 + 21, "ink")
for yy in range(by0, by0 + 22): P(bx0, yy, "ink"); P(bx0 + 23, yy, "ink")
PEAR = ["....1.....", "....1.11..", "....111...", "...111....", "...111....", "..11111...", ".1111111..", ".1111111..", "..11111..."]
for j, row in enumerate(PEAR):                 # a pear, with its stem and leaf
    for i, b in enumerate(row):
        if b == "1": P(bx0 + 7 + i, by0 + 3 + j, "ink")
text("PEARS", bx0 + 12 - tw("PEARS", "35") // 2, by0 + 14, "ink", font="35")


# ---------------------------------------------------------------- years of use
# the spine edge, wrapped in black cloth tape, frayed
for y in range(BH):
    for x in range(0, 6):
        BP(x, y, "gf1" if bd(x, y, 0.3) else "gf0")
    if rng.random() < 0.5: BP(6, y, "gf0")
    if y % 9 == 0: BP(3, y, "gf2")
# corners rubbed round
def rub(cx, cy, sx, sy):
    for k in range(5):
        for j in range(5):
            if j + k < 3: P(BX + cx + sx * j, BY + cy + sy * k, "wd0")
            elif j + k == 3: P(BX + cx + sx * j, BY + cy + sy * k, "boardD")
rub(BW - 1, BH - 1, -1, -1); rub(0, BH - 1, 1, -1); rub(0, 0, 1, 1)
# edges rubbed through to the board
for x in range(BW):
    for (yy, p_) in ((0, .45), (1, .15), (BH - 1, .5), (BH - 2, .15)):
        if rng.random() < p_: BP(x, yy, "wear")
for y in range(BH):
    for (xx, p_) in ((BW - 1, .5), (BW - 2, .15)):
        if rng.random() < p_: BP(xx, y, "wear")
# dog-ear: the top right corner folded down, showing the grey inside of the cover
DE = 16
for j in range(DE + 1):
    for i in range(DE + 1 - j):
        x, y = BW - 1 - i, j
        P(BX + x, BY + y, "wd0" if dith(BX + x, BY + y, .7) else "wd1")      # the desk shows where the corner was
for j in range(DE + 1):
    for i in range(DE + 1 - j):
        x, y = BW - 1 - DE + j, DE - i                 # the flap, reflected over the fold
        c = "board" if (i + j) < DE - 1 else "boardD"
        if i == 0 or j == 0: c = "boardD"
        P(BX + x - 0, BY + y, c)
for k in range(DE + 1): P(BX + BW - 1 - DE + k, BY + k, "b4")
# a long crease across the cover where it was bent back
for k in range(70):
    x, y = 120 + k, 236 - int(k * 0.9)
    if bd(x, y, .85): BP(x, y, "wear")
# scuffs
for _ in range(18):
    x, y, ln = rng.randrange(12, BW - 10), rng.randrange(10, BH - 20), rng.randrange(3, 9)
    for k in range(ln):
        if rng.random() < .8: BP(x + k, y + k // 3, "wear")
# a ring where a wet glass sat
ccx, ccy, rr = BX + 158, BY + 58, 15
for y in range(ccy - rr - 2, ccy + rr + 3):
    for x in range(ccx - rr - 2, ccx + rr + 3):
        d = math.hypot((x - ccx) * 0.9, y - ccy)
        if rr - 1.3 < d < rr + 0.6 and math.sin(math.atan2(y - ccy, x - ccx) * 3 + 1) > -0.6:
            o = get(x, y)
            if o: P(x, y, tuple(int(o[i] * 0.66 + C["coffee"][i] * 0.34) for i in range(3)))
# the used-book sticker, top left, half peeled
ux0, uy0 = BX + 12, BY + 3
R(ux0, uy0, ux0 + 31, uy0 + 15, "lab")
for x in range(ux0, ux0 + 32): P(x, uy0 + 15, "b3")
text("USED", ux0 + 3, uy0 + 2, "red", font="35")
text("4.50", ux0 + 3, uy0 + 8, "ink", font="35")
for k in range(5):
    for j in range(5 - k): P(ux0 + 31 - j, uy0 + k, "b2" if j == 4 - k else "lab")

# ---------------------------------------------------------------- the kernel guy's marks
x0_, y0_, x1_, y1_ = SUB2
for x in range(x0_ - 3, x1_ + 4):
    P(x, y0_ + 2 + (x - x0_) // 45, "pen"); P(x, y0_ + 3 + (x - x0_) // 45, "pen")
    P(x, y0_ + 5 - (x - x0_) // 60, "pen")
zg = ttf_mask("ZeD-GUI", 22, MARKER)
zx = BX + 104 - zg.size[0] // 2; zy = y1_ + 3
stamp(zg, zx, zy, "pen", rot=3)
for k in range(6):                                  # a caret up into the struck line
    P(zx - 8 + k, y1_ + 9 - k, "pen"); P(zx - 8 + k, y1_ + 10 - k, "pen")
    P(zx - 2 + k, y1_ + 4 + k, "pen"); P(zx - 2 + k, y1_ + 5 + k, "pen")
ax, ay = AUTH
for x in range(ax - 2, ax + tw("ZNIX DOCS") + 3): P(x, ay + 3, "pen")
for x in range(ax - 2, ax + tw("GROUP") + 3): P(x, ay + 12, "pen")
hm = ttf_mask("hermit", 18, BALL); stamp(hm, ax + 35, ay + 6, "blu", rot=5)
# masking tape across the foot, his line on it
tpx, tpy, tpw, tph = BX + 14, BY + 211, 152, 24
for y in range(tpy, tpy + tph):
    for x in range(tpx, tpx + tpw):
        if (x - tpx < 2 and (y * 5) % 3 == 0) or (tpx + tpw - x < 3 and (y * 7) % 4 < 2): continue
        P(x, y, "tape1" if dith(x, y, 0.22) else "tape0")
m1 = ttf_mask("the hacked guide to", 15, MARKER); m2 = ttf_mask("approaching znix", 15, MARKER)
stamp(m1, tpx + 4, tpy + 1, "ink"); stamp(m2, tpx + 16, tpy + 12, "ink")


# ---------------------------------------------------------------- beside the book
# Scale: the book is about 7.4 x 9.2 inches, so about 27 art pixels to the inch. A 3.5 inch disk is about 95 x 100,
# a rocks glass about 90 across, a 3 inch sticky note about 81, a pencil about 200 long and 7 thick.
def blend(x, y, c, a):
    o = get(x, y)
    if o: P(x, y, tuple(int(o[i] * (1 - a) + col(c)[i] * a) for i in range(3)))

def disk(fx0, fy0, label=False, shadow=True, body=("fl0", "fl1", "fl2"), note=None):
    fw, fh = 95, 100
    f0, f1, f2 = body
    if shadow:
        for y in range(fy0 + 4, fy0 + fh + 6):
            for x in range(fx0 + 4, fx0 + fw + 5):
                if dith(x, y, .75): P(x, y, "wd0")
    R(fx0, fy0, fx0 + fw, fy0 + fh, f1)
    for x in range(fx0, fx0 + fw + 1): P(x, fy0, f2); P(x, fy0 + fh, f0)
    for y in range(fy0, fy0 + fh + 1): P(fx0, y, f2); P(fx0 + fw, y, f0)
    for k in range(7):
        for j in range(7 - k): P(fx0 + fw - j, fy0 + k, get(fx0 + fw + 8, fy0 + k + 8) or C["wd1"])   # the cut corner
    R(fx0 + 24, fy0, fx0 + 69, fy0 + 31, "met0"); R(fx0 + 24, fy0, fx0 + 25, fy0 + 31, "met1"); R(fx0 + 68, fy0, fx0 + 69, fy0 + 31, "met2")
    R(fx0 + 52, fy0 + 5, fx0 + 61, fy0 + 26, f0)
    R(fx0 + 5, fy0 + fh - 11, fx0 + 9, fy0 + fh - 5, f0)                       # write-protect hole
    R(fx0 + fw - 9, fy0 + fh - 11, fx0 + fw - 5, fy0 + fh - 5, f0)
    if label is False:
        R(fx0 + 8, fy0 + 40, fx0 + fw - 8, fy0 + fh - 3, "lab")
        for yy in range(fy0 + 57, fy0 + fh - 3, 11):
            for x in range(fx0 + 9, fx0 + fw - 8): P(x, yy, "labL")
        if note is not None:          # "UNINSTALLER 911" lettered by hand: the marker face turns U into V and 1 into a bar this small
            HAND = {
                "U": ["11..11"] * 7 + ["111111", ".1111."],
                "N": ["11..11", "111.11", "111.11", "111111", "11.111", "11.111", "11..11", "11..11", "11..11"],
                "I": ["1111"] + [".11."] * 7 + ["1111"],
                "S": [".1111.", "111111", "11....", "11....", ".1111.", "....11", "....11", "111111", ".1111."],
                "T": ["111111", "111111"] + ["..11.."] * 7,
                "A": [".1111.", "111111", "11..11", "11..11", "111111", "111111", "11..11", "11..11", "11..11"],
                "L": ["11...."] * 7 + ["111111", "111111"],
                "E": ["111111", "111111", "11....", "11....", "11111.", "11....", "11....", "111111", "111111"],
                "R": ["11111.", "111111", "11..11", "11..11", "111111", "11111.", "11.11.", "11..11", "11..11"],
            }
            x = fx0 + 11
            for k, ch in enumerate("UNINSTALLER"):
                g = HAND[ch]; jit = (0, 1, 0, -1, 0, 1, 1, 0, -1, 0, 1)[k]
                for j, row in enumerate(g):
                    for i, b in enumerate(row):
                        if b == "1": P(x + i, fy0 + 73 + j + jit, "ink")
                x += len(g[0]) + 1
            NINE = [".11111.", "1111111", "11...11", "11...11", "1111111", ".111111", ".....11", ".....11", "....11.", "...111.", ".1111..", ".111..."]
            ONE = ["..11.", ".111.", "1111.", "..11.", "..11.", "..11.", "..11.", "..11.", "..11.", "..11.", "..11.", "..11."]
            x = fx0 + 13
            for g in (NINE, ONE, ONE):
                for j, row in enumerate(g):
                    for i, b in enumerate(row):
                        if b == "1": P(x + i - j // 6, fy0 + 85 + j, "ink")
                x += len(g[0]) + 2
        return
    R(fx0 + 8, fy0 + 40, fx0 + fw - 8, fy0 + fh - 3, "lab")
    for yy in range(fy0 + 57, fy0 + fh - 3, 11):
        for x in range(fx0 + 9, fx0 + fw - 8): P(x, yy, "labL")
    zl = ttf_mask("ZeD-GUI", 17, MARKER); stamp(zl, fx0 + 13, fy0 + 42, "ink")
    b1 = ttf_mask("Build 42", 16, BALL); stamp(b1, fx0 + 13, fy0 + 60, "blu")
    b2 = ttf_mask("disk 1 of 12", 16, BALL); stamp(b2, fx0 + 13, fy0 + 71, "blu")

# the install set: twelve disks, the first on top of the pile
RED = ("rd0", "rd1", "rd2")
for n, (ox, oy, body, note) in enumerate(((19, 17, None, None), (13, 10, None, None), (8, 36, RED, ()))):
    # a loose pile, each a little off the one below; the red one is the uninstall disk, slid out under the top one
    kw = {"body": body} if body else {}
    disk(284 + ox, 8 + oy, shadow=(n != 1), note=note, **kw)
    for x in range(284 + ox, 284 + ox + 96): P(x, 8 + oy + 101, "wd0")
    for y in range(8 + oy, 8 + oy + 102): P(284 + ox + 96, y, "wd0")
disk(284, 8, label=True, shadow=False)

# bourbon on ice in a rocks glass, seen from above, the frame cutting its right edge
gx, gy, gr = 438, 64, 45
for y in range(gy - gr, gy + gr + 12):                                       # its shadow, and a wet ring where it sat before
    for x in range(gx - gr, gx + gr + 12):
        if math.hypot(x - gx - 7, y - gy - 8) < gr and dith(x, y, .8): P(x, y, "wd0")
for y in range(150, 196):
    for x in range(398, 470):
        d = math.hypot(x - 432, y - 172)
        if gr - 24 - 1.4 < d < gr - 24 + 0.4 and math.sin(math.atan2(y - 172, x - 432) * 2) > -0.7: blend(x, y, (20, 14, 10), .45)
ICE = [(-10, -9, 30, 0.5), (13, 10, 28, -0.25)]
def in_ice(x, y):
    for (ox, oy, sz, a) in ICE:
        dx, dy = x - (gx + ox), y - (gy + oy)
        u = dx * math.cos(a) + dy * math.sin(a); v = -dx * math.sin(a) + dy * math.cos(a)
        if abs(u) < sz / 2 and abs(v) < sz / 2:
            return u / (sz / 2), v / (sz / 2)
    return None
for y in range(gy - gr, gy + gr + 1):
    for x in range(gx - gr, gx + gr + 1):
        d = math.hypot(x - gx, y - gy)
        if d > gr: continue
        if d > gr - 6:                                                        # the heavy glass wall
            blend(x, y, "gls", .45)
            ang = math.atan2(y - gy, x - gx)
            if -2.6 < ang < -1.2 and d > gr - 3: P(x, y, "glsH")
            if d > gr - 1: blend(x, y, "glsH", .4)
            continue
        q = in_ice(x, y)
        if q:
            u, v = q
            c = "bb3" if dith(x, y, 0.55) else "ic0"                          # clear ice, the bourbon showing through
            if u < -0.78 or v < -0.78: c = "ic2"                              # lit edges, upper left
            elif u > 0.78 or v > 0.78: c = "bb1"
            elif -0.6 < u < -0.3 and -0.6 < v < -0.3: c = "ic1"
            P(x, y, c)
            continue
        t = (x - gx + y - gy) / (2 * gr) + 0.5                                # the light comes through to the lower right
        c = "bb1"
        if t < 0.35 and not dith(x, y, t * 2.4): c = "bb0"
        if t > 0.62 and dith(x, y, (t - 0.62) * 3): c = "bb2"
        if t > 0.86 and dith(x, y, (t - 0.86) * 5): c = "bb3"
        P(x, y, c)
for (x, y) in ((gx - 31, gy - 18), (gx - 32, gy - 17), (gx - 29, gy - 21), (gx + 22, gy + 27)): P(x, y, "glsH")

# the sticky note
nx0, ny0 = 290, 151
for y in range(ny0 + 4, ny0 + 87):
    for x in range(nx0 + 4, nx0 + 86):
        if dith(x, y, .75): P(x, y, "wd0")
band(nx0, ny0, nx0 + 81, ny0 + 81, "sticky", "stickyD", 0.0, 0.45)
for x in range(nx0, nx0 + 82): P(x, ny0, "stickyD")
for k in range(6):
    for j in range(6 - k): P(nx0 + 81 - j, ny0 + 81 - k, "stickyD" if j + k == 5 else "wd0")
n1 = ttf_mask("Options >", 17, BALL); stamp(n1, nx0 + 7, ny0 + 9, "blu")
n2 = ttf_mask("Mods >", 17, BALL); stamp(n2, nx0 + 14, ny0 + 28, "blu")
n3 = ttf_mask("ZeD-GUI", 17, BALL); stamp(n3, nx0 + 21, ny0 + 47, "blu")

# a four-colour ballpoint, about 5.8 inches: blue barrel, white top, two of its four tabs facing up, the clip to one side
def fourpen(tx, ty, L, deg):
    a = math.radians(deg); ux, uy = math.cos(a), -math.sin(a); nx, ny = -uy, ux     # u runs tip to end, v across
    xs = [tx, tx + ux * L]; ys = [ty, ty + uy * L]
    box = (int(min(xs)) - 14, int(min(ys)) - 14, int(max(xs)) + 14, int(max(ys)) + 14)
    def at(x, y):
        dx, dy = x - tx, y - ty
        return dx * ux + dy * uy, dx * nx + dy * ny
    def shape(u, v):
        r = 6.0
        if u < 0 or u > L: return None
        if u < 3: return "brass" if abs(v) < 1.2 else None
        if u < 12:                                                            # the cone
            if abs(v) < 1.6 + (u - 3) / 9 * (r - 1.6): return "b"
            return None
        if u > L - 7:                                                         # the hanging ring at the end
            d = math.hypot(u - (L - 3.5), v)
            if 1.4 < d < 3.6: return "w"
            return None
        if u > L - 11:                                                        # the domed cap
            if abs(v) < r - (u - (L - 11)) * 0.9: return "w"
            return None
        if abs(v) <= r:
            if 0.62 * L <= u < 0.64 * L: return "ring"
            if u < 0.62 * L: return "b"
            if L - 30 <= u < L - 13:                                          # the colour tabs in their slots
                if -4.6 <= v <= -1.6: return "tabB"
                if 1.6 <= v <= 4.6: return "tabR"
                if v < -5.2: return "tabK"
            return "w"
        if 0.66 * L <= u < L - 16 and -r - 3.5 <= v < -r:                      # the clip, standing off the side
            return "clip"
        return None
    sh = []
    for y in range(box[1], box[3] + 8):
        for x in range(box[0], box[2] + 8):
            u, v = at(x - 2, y - 5)
            if shape(u, v) and dith(x, y, .8): sh.append((x, y))
    for (x, y) in sh: P(x, y, "wd0")
    for y in range(box[1], box[3]):
        for x in range(box[0], box[2]):
            u, v = at(x, y); c = shape(u, v)
            if not c: continue
            if c == "b":   c = "pb2" if v < -3.6 else ("pb0" if v > 3.4 else "pb1")
            elif c == "w": c = "pw0" if v < -2.5 else ("pw2" if v > 4 else "pw1")
            elif c == "clip": c = "pw0" if v < -7.5 else "pw2"
            elif c == "ring": c = "ink"
            P(x, y, c)
fourpen(298, 266, 158, 14)

out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "znix_01_cover.png")
im.resize((W * S, H * S), Image.NEAREST).save(out)
im.save(out.replace(".png", "_1x.png"))
print("wrote", out)
