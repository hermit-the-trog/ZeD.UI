"""ZeD-GUI Workshop thumbnail, option A in pixel art.
Drawn on a 128 x 128 grid with hard edges and a fixed palette, then doubled to 256 x 256
(nearest neighbour), so every art pixel is a clean 2 x 2 block on Steam."""
import sys
from PIL import Image, ImageDraw, ImageFont

import os
HERE = os.path.dirname(os.path.abspath(__file__)) + os.sep   # needs fxc900.ttf (Fira Sans Extra Condensed Black, SIL Open Font License) beside it
G = 128

C = dict(
    paper=(239, 233, 216), speck=(223, 214, 192), ink=(20, 20, 20), grey=(92, 88, 80),
    red=(200, 32, 42), redD=(132, 16, 24), redL=(232, 84, 76),
    grn=(31, 122, 98), grnD=(18, 78, 62), wht=(255, 255, 255),
    b0=(250, 245, 232), b1=(228, 220, 200), b2=(206, 197, 174), b3=(172, 162, 138), b4=(124, 115, 96), b5=(84, 77, 63),
    glass=(12, 18, 30), desk=(38, 66, 104), deskD=(28, 48, 80),
    win=(232, 229, 222), winG=(189, 184, 173), winD=(140, 136, 128),
    org=(212, 146, 42), orgL=(244, 220, 174), teal=(71, 161, 140), blu=(68, 136, 204), pur=(136, 85, 187),
    yel=(204, 170, 34), led=(63, 220, 90), amb=(232, 160, 32), shadow=(196, 188, 168),
)

# the mod's own pixel faces (PixelFonts.lua), capitals only, plus a comma
F35 = {
 'A':["010","101","111","101","101"],'B':["110","101","110","101","110"],'C':["011","100","100","100","011"],
 'D':["110","101","101","101","110"],'E':["111","100","110","100","111"],'F':["111","100","110","100","100"],
 'G':["011","100","101","101","011"],'H':["101","101","111","101","101"],'I':["111","010","010","010","111"],
 'J':["001","001","001","101","010"],'K':["101","101","110","101","101"],'L':["100","100","100","100","111"],
 'M':["10001","11011","10101","10001","10001"],'N':["1001","1101","1011","1001","1001"],'O':["010","101","101","101","010"],
 'P':["110","101","110","100","100"],'R':["110","101","110","101","101"],'S':["011","100","010","001","110"],
 'T':["111","010","010","010","010"],'U':["101","101","101","101","111"],'V':["101","101","101","101","010"],
 'W':["10001","10001","10101","10101","01010"],'Y':["101","101","010","010","010"],'Z':["111","001","010","100","111"],
 '0':["111","101","101","101","111"],'1':["010","110","010","010","111"],'2':["111","001","111","100","111"],
 '3':["111","001","011","001","111"],'4':["101","101","111","001","001"],'9':["111","101","111","001","110"],
 ' ':["00","00","00","00","00"],'.':["0","0","0","0","1"],'/':["001","001","010","100","100"],'+':["000","010","111","010","000"],
 '-':["000","000","111","000","000"],',':["0","0","0","1","1"],
}
F57 = {
 'A':["01110","10001","10001","11111","10001","10001","10001"],'B':["11110","10001","11110","10001","10001","10001","11110"],
 'C':["01111","10000","10000","10000","10000","10000","01111"],'D':["11110","10001","10001","10001","10001","10001","11110"],
 'E':["11111","10000","11110","10000","10000","10000","11111"],'F':["11111","10000","11110","10000","10000","10000","10000"],
 'G':["01111","10000","10000","10011","10001","10001","01111"],'H':["10001","10001","11111","10001","10001","10001","10001"],
 'I':["111","010","010","010","010","010","111"],'L':["10000","10000","10000","10000","10000","10000","11111"],
 'M':["10001","11011","10101","10001","10001","10001","10001"],'N':["10001","11001","10101","10011","10001","10001","10001"],
 'O':["01110","10001","10001","10001","10001","10001","01110"],'P':["11110","10001","10001","11110","10000","10000","10000"],
 'R':["11110","10001","10001","11110","10010","10001","10001"],'S':["01111","10000","10000","01110","00001","00001","11110"],
 'T':["11111","00100","00100","00100","00100","00100","00100"],'U':["10001","10001","10001","10001","10001","10001","01110"],
 'W':["10001","10001","10001","10101","10101","11011","10001"],'Y':["10001","10001","01010","00100","00100","00100","00100"],
 '2':["01110","10001","00001","00110","01000","10000","11111"],'4':["00010","00110","01010","10010","11111","00010","00010"],
 ' ':["000","000","000","000","000","000","000"],'.':["0","0","0","0","0","0","1"],',':["00","00","00","00","00","01","10"],
 '/':["00001","00010","00010","00100","01000","01000","10000"],
}

im = Image.new('RGB', (G, G), C['paper'])
px = im.load()
d = ImageDraw.Draw(im)

def P(x, y, c):
    if 0 <= x < G and 0 <= y < G: px[x, y] = C[c] if isinstance(c, str) else c
def R(x0, y0, x1, y1, c):  # inclusive rectangle
    d.rectangle([x0, y0, x1, y1], fill=C[c])
def H(x0, x1, y, c): R(x0, y, x1, y, c)
def V(x, y0, y1, c): R(x, y0, x, y1, c)
def text(s, x, y, c, font=F35, gap=1):
    for ch in s:
        g = font.get(ch, font[' '])
        for j, row in enumerate(g):
            for i, b in enumerate(row):
                if b == '1': P(x + i, y + j, c)
        x += len(g[0]) + gap
    return x
def tw(s, font=F35, gap=1): return sum(len(font.get(ch, font[' '])[0]) + gap for ch in s) - gap
def dither(x0, y0, x1, y1, ca, cb, t0, t1, vertical=True):
    """ordered dither from ca to cb across the box (t0..t1 is how much cb shows at each end)"""
    B = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            f = (y - y0) / max(1, y1 - y0) if vertical else (x - x0) / max(1, x1 - x0)
            t = t0 + (t1 - t0) * f
            P(x, y, cb if (B[y % 4][x % 4] + .5) / 16 < t else ca)


import random
random.seed(1993)
for _ in range(150):
    P(random.randrange(G), random.randrange(G), 'speck')

def ttf_mask(s, size):
    f = ImageFont.truetype(HERE + 'fxc900.ttf', size)
    m = Image.new('L', (G * 2, 80), 0); md = ImageDraw.Draw(m); md.fontmode = '1'
    md.text((0, 0), s, font=f, fill=255)
    m = m.crop(m.getbbox())
    # drop the round letters' one-pixel overshoot rows (they read as spurs: U$ER)
    def ink(row): return sum(1 for i in range(m.size[0]) if m.getpixel((i, row)) > 127)
    while ink(0) <= 3: m = m.crop((0, 1, m.size[0], m.size[1]))
    while ink(m.size[1] - 1) <= 3: m = m.crop((0, 0, m.size[0], m.size[1] - 1))
    return m

def stamp(mask, x, y, col, shadow=None):
    a = mask.load(); w, h = mask.size
    if shadow:
        for j in range(h):
            for i in range(w):
                if a[i, j] > 127: P(x + i + 1, y + j + 1, shadow)
    for j in range(h):
        for i in range(w):
            if a[i, j] > 127:
                P(x + i, y + j, col(i, j) if callable(col) else col)

# --- masthead: ZNIX in accent stripes, USER in ink ----------------------------------------
STR = ['red', 'org', 'yel', 'grn2', 'teal', 'blu', 'pur']
C['grn2'] = (68, 170, 68)
zn = ttf_mask('ZNIX', 28); us = ttf_mask('USER', 28)
gap = 5; total = zn.size[0] + gap + us.size[0]
x0 = (G - total) // 2; y0 = 3
def stripe(i, j):
    return STR[min(len(STR) - 1, j * len(STR) // zn.size[1])]
mh = max(zn.size[1], us.size[1])
stamp(zn, x0, y0 + mh - zn.size[1], stripe, shadow='shadow')
stamp(us, x0 + zn.size[0] + gap, y0 + mh - us.size[1], 'ink', shadow='shadow')
mb = y0 + max(zn.size[1], us.size[1])

# --- issue band ---------------------------------------------------------------------------
by = mb + 3
R(2, by, G - 3, by + 7, 'grn'); H(2, G - 3, by + 8, 'grnD')
text('JULY 1993', 5, by + 2, 'wht')
s_ = 'BUILD 42'; text(s_, G - 5 - tw(s_), by + 2, 'wht')

# --- cover story: ZeD-GUI ------------------------------------------------------------------
z = ttf_mask('ZeD', 34); g = ttf_mask('-GUI', 34)
f34 = ImageFont.truetype(HERE + 'fxc900.ttf', 34)
zx = (G - (z.size[0] + g.size[0] + 1)) // 2; zy = by + 13
# align baselines: both masks were cropped, so use their font bboxes
zb = f34.getbbox('ZeD'); gb = f34.getbbox('-GUI')
hb = max(z.size[1], g.size[1])
stamp(z, zx, zy + hb - z.size[1], 'red', shadow='redD')
stamp(g, zx + z.size[0] + 1, zy + hb - g.size[1], 'ink', shadow='shadow')
zbottom = zy + hb

# --- deck line ------------------------------------------------------------------------------
dk = 'THE WHOLE INTERFACE, REBUILT.'
text(dk, (G - tw(dk)) // 2, zbottom + 3, 'red')

# --- cover lines --------------------------------------------------------------------------
y = zbottom + 12
for head_ in ('2 WINDOWS', 'PAD/MOUSE', 'GRID/LIST'):
    H(3, 55, y, 'grn'); H(3, 55, y + 1, 'grn')
    text(head_, 3, y + 4, 'ink', F57)
    y += 14

# --- the computer, bottom right ---------------------------------------------------------------
mx0, my0, mx1, my1 = 68, zbottom + 11, 122, zbottom + 49
mw = mx1 - mx0; mcx = (mx0 + mx1) // 2
cx0, cy0 = mx0 - 8, my1 + 7
R(cx0 - 3, cy0 + 2, G - 1, G - 1, 'shadow')
R(cx0 + 2, cy0, G - 1, cy0 + 2, 'b0'); H(cx0 + 1, G - 1, cy0 + 3, 'b1')
dither(cx0, cy0 + 4, G - 1, G - 1, C['b1'], C['b2'], .1, .8)
V(cx0, cy0 + 4, G - 1, 'b3')
R(mcx - 7, my1 + 1, mcx + 7, my1 + 3, 'b2'); H(mcx - 8, mcx + 8, my1 + 4, 'b3'); R(mcx - 12, my1 + 4, mcx + 12, my1 + 6, 'b1'); H(mcx - 12, mcx + 12, my1 + 6, 'b3')
R(mx0 + 2, my0, mx1 - 2, my1, 'b1'); R(mx0, my0 + 2, mx1, my1 - 2, 'b1'); R(mx0 + 1, my0 + 1, mx1 - 1, my1 - 1, 'b1')
dither(mx0 + 1, my0 + 1, mx1 - 1, my1 - 1, C['b1'], C['b2'], 0, .55)
H(mx0 + 2, mx1 - 2, my0, 'b0'); V(mx0, my0 + 2, my1 - 2, 'b0'); P(mx0 + 1, my0 + 1, 'b0')
H(mx0 + 2, mx1 - 2, my1, 'b4'); V(mx1, my0 + 2, my1 - 2, 'b3'); P(mx1 - 1, my1 - 1, 'b4')
sx0, sy0, sx1, sy1 = mx0 + 5, my0 + 4, mx1 - 5, my1 - 8
R(sx0 - 2, sy0 - 2, sx1 + 2, sy1 + 2, 'b3'); H(sx0 - 1, sx1 + 1, sy1 + 2, 'b0'); V(sx1 + 2, sy0 - 1, sy1 + 1, 'b2')
R(sx0 - 1, sy0 - 1, sx1 + 1, sy1 + 1, 'b5')
R(mx0 + 4, my1 - 5, mx0 + 10, my1 - 3, 'red')
for k in range(4): V(mx1 - 14 + k * 2, my1 - 5, my1 - 2, 'b3')
P(mx1 - 5, my1 - 4, 'led')
# screen: a ZeD window
R(sx0, sy0, sx1, sy1, 'desk'); dither(sx0, sy0, sx1, sy1, C['desk'], C['deskD'], 0, .6)
wx0, wy0, wx1, wy1 = sx0 + 2, sy0 + 2, sx1 - 2, sy1 - 1
R(wx0, wy0, wx1, wy1, 'win'); d.rectangle([wx0, wy0, wx1, wy1], outline=C['ink'])
H(wx0, wx1, wy0 + 5, 'ink')
for k in (1, 3): H(wx0 + 2, wx1 - 2, wy0 + 1 + k, 'ink')
R(wx0 + 2, wy0 + 1, wx0 + 5, wy0 + 4, 'win'); d.rectangle([wx0 + 2, wy0 + 1, wx0 + 5, wy0 + 4], outline=C['ink'])
R(wx0 + 1, wy0 + 6, wx1 - 1, wy0 + 8, 'winG'); R(wx0 + 2, wy0 + 6, wx0 + 7, wy0 + 8, 'org')
midx = wx0 + (wx1 - wx0) // 2
V(midx, wy0 + 9, wy1 - 1, 'ink')
for i, c in enumerate(['red', 'org', 'teal', 'blu']):
    yy = wy0 + 11 + i * 3
    if yy + 1 >= wy1: break
    if i == 1: R(wx0 + 1, yy - 1, midx - 1, yy + 1, 'orgL')
    R(wx0 + 2, yy, wx0 + 3, yy + 1, c); H(wx0 + 5, midx - 5 - (i % 3) * 2, yy, 'winD'); H(midx - 4, midx - 2 - (i % 2), yy + 1, 'org')
gc = ['red', 'teal', 'org', 'blu', 'yel', 'pur', 'grn', 'red', 'blu']
for i in range(9):
    gx = midx + 2 + (i % 3) * 5; gy = wy0 + 11 + (i // 3) * 5
    if gx + 3 >= wx1 or gy + 3 >= wy1: continue
    R(gx, gy, gx + 3, gy + 3, 'wht'); d.rectangle([gx, gy, gx + 3, gy + 3], outline=C['winD']); R(gx + 1, gy + 1, gx + 2, gy + 2, gc[i])

# --- the test build's band (run with --test): red across the foot, TEST BUILD in white -----------
# (Oct 28 2026: the test item's cover while its door is open; the release item gets the plain cover)
if '--test' in sys.argv:
    by0, by1 = G - 14, G - 1
    R(0, by0, G - 1, by1, 'red'); H(0, G - 1, by0, 'redL'); H(0, G - 1, by1, 'redD')
    tb = 'TEST BUILD'
    text(tb, (G - tw(tb, F57)) // 2, by0 + 4, 'wht', F57)
    im.resize((256, 256), Image.NEAREST).save(HERE + 'znix_256_test.png', optimize=True)
    im.resize((1024, 1024), Image.NEAREST).save(HERE + 'znix_1024_test.png')
else:
    im.resize((256, 256), Image.NEAREST).save(HERE + 'znix_256.png', optimize=True)
    im.resize((1024, 1024), Image.NEAREST).save(HERE + 'znix_1024.png')
print('mast', mb, 'band', by, 'zed bottom', zbottom, 'lines end', y, 'monitor', my0, my1, 'case', cy0)
