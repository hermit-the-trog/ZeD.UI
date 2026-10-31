"""A Workshop gallery slide as a page spread from the used copy of "Bitchin' znix Programs": the book open on the
desk, one plain heading, the card's screenshots printed as figures, and the kernel guy's ballpoint notes in the
margins with arrows to what they explain. Reads the card from the gallery's shots.json (its title, caption, crops
and balloons), so every card can be set the same way.

Three grids: the desk and the book are pixel art at 4x (480 x 270); what is printed or written on the paper is 1-bit
at 2x, so a sentence stays readable; the screenshots are printed crisp at full size.
usage: python page_px.py <shots.json> <screens dir> <card id> out.png"""
import json
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FD = os.path.join(HERE, "fonts")
BALL = os.path.join(FD, "Caveat.ttf") if os.path.exists(os.path.join(FD, "Caveat.ttf")) else os.path.join(FD, "WnznHAc5bAfYB2QRah7pcpNvOx-pjRV6SII.ttf")
def _font(name, fallback):
    p = os.path.join(FD, name)
    return p if os.path.exists(p) else fallback
SERIF = _font("Charter-Regular.pfb", "/usr/share/fonts/X11/Type1/c0648bt_.pfb")      # Bitstream Charter, 1987
SERIF_B = _font("Charter-Bold.pfb", "/usr/share/fonts/X11/Type1/c0632bt_.pfb")
W, H, S = 480, 270, 4
OW, OH = W * S, H * S

C = dict(
    wd0=(30, 22, 17), wd1=(42, 31, 24), wd2=(54, 40, 30), wd3=(66, 50, 37),
    pg0=(222, 214, 192), pg1=(208, 198, 174), pg2=(190, 178, 152), pg3=(160, 148, 124), pg4=(120, 108, 88),
    cv0=(40, 30, 46), cv1=(58, 44, 66), ink=(26, 24, 30),
    # the four-colour ballpoint he writes with
    blu=(34, 50, 124), red=(196, 52, 44), blk=(30, 30, 34), grn=(36, 112, 62),
    flag0=(200, 170, 80), flag1=(176, 110, 104), ring=(150, 120, 90),
)
BAY = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
def dith(x, y, t): return (BAY[y % 4][x % 4] + .5) / 16 < t


# ---------------------------------------------------------------- the art layer (480 x 270)
def art_layer(seed):
    rng = random.Random(seed)
    im = Image.new("RGB", (W, H), C["wd1"]); px = im.load()
    def P(x, y, c):
        if 0 <= x < W and 0 <= y < H: px[x, y] = C[c] if isinstance(c, str) else c
    # the desk, as on the cover
    PL = 34
    for y in range(H):
        for x in range(W):
            l = 1 - (0.6 * x / W + 0.45 * y / H)
            c = "wd1"
            if dith(x, y, max(0, l - 0.45) * 1.4): c = "wd2"
            if dith(x, y, max(0, 0.42 - l) * 1.6): c = "wd0"
            px[x, y] = C[c]
    for p in range(H // PL + 2):
        for _ in range(5):
            oy, ph, ph2, c = rng.randrange(3, PL - 2), rng.random() * 6.28, rng.random() * 6.28, rng.choice(("wd0", "wd0", "wd2"))
            for x in range(W):
                y = p * PL + oy + int(round(1.6 * math.sin(x / 41 + ph) + 0.7 * math.sin(x / 13 + ph2)))
                if p * PL < y < (p + 1) * PL - 1 and math.sin(x / 23 + ph * 3) > -0.55: P(x, y, "wd3" if c == "wd2" else "wd0")
        for x in range(W): P(x, p * PL, "wd0")
    # the book open: boards, page stacks, pages
    X0, X1, Y0, Y1, G = 6, 474, 5, 265, 240
    for y in range(Y0 + 3, Y1 + 5):                                           # shadow
        for x in range(X0 + 3, X1 + 5):
            if dith(x, y, .8): P(x, y, "wd0")
    for y in range(Y0, Y1 + 1):
        for x in range(X0, X1 + 1): P(x, y, "cv0" if dith(x, y, .7) else "cv1")
    for y in range(Y0 + 2, Y1 - 1):                                           # page stacks at the outer edges
        for k in range(4):
            P(X0 + 2 + k, y, "pg2" if k % 2 else "pg3"); P(X1 - 2 - k, y, "pg2" if k % 2 else "pg3")
    for x in range(X0 + 2, X1 - 1):
        for k in range(3): P(x, Y1 - 2 - k, "pg2" if k % 2 else "pg3")
    PX0, PX1, PY0, PY1 = X0 + 6, X1 - 6, Y0 + 2, Y1 - 5
    for y in range(PY0, PY1 + 1):
        for x in range(PX0, PX1 + 1):
            d_g = abs(x - G)                                                  # into the gutter
            d_e = min(x - PX0, PX1 - x, y - PY0, PY1 - y)                      # toward the worn edges
            c = "pg0"
            if dith(x, y, 0.18 + max(0, 6 - d_e) * 0.09): c = "pg1"
            if d_g < 14 and dith(x, y, (14 - d_g) / 14 * 0.9): c = "pg1"
            if d_g < 7 and dith(x, y, (7 - d_g) / 7 * 0.9): c = "pg2"
            if d_g < 2: c = "pg3"
            px[x, y] = C[c]
    for _ in range(40):                                                       # foxing
        x, y = rng.randrange(PX0 + 4, PX1 - 4), rng.randrange(PY0 + 4, PY1 - 4)
        if abs(x - G) > 10: P(x, y, "pg1")
    return im, (PX0, PX1, PY0, PY1, G)


def overlay_art(im, geom, seed):
    """What sits on top of everything: the folded corner."""
    rng = random.Random(seed + 7)
    px = im.load(); PX0, PX1, PY0, PY1, G = geom
    def P(x, y, c):
        if 0 <= x < W and 0 <= y < H: px[x, y] = C[c] if isinstance(c, str) else c
    DE = 13                                                                   # dog-ear, the outer bottom corner
    fl = (lambda x: PX0 + PX1 - x) if G == "left" else (lambda x: x)
    for j in range(DE + 1):
        for i in range(DE + 1 - j):
            x, y = PX1 - i, PY1 - j
            P(fl(x), y, "cv0" if dith(x, y, .6) else "cv1")
    for j in range(DE + 1):
        for i in range(DE + 1 - j):
            x, y = PX1 - DE + j, PY1 - DE + i
            P(fl(x), y, "pg1" if (i and j) else "pg3")
    for k in range(DE + 1): P(fl(PX1 - DE + k), PY1 - k, "pg4")


# ---------------------------------------------------------------- the 2x grid: print and ink
def mask2(text, path, size):
    f = ImageFont.truetype(path, size)
    b = f.getbbox(text)
    m = Image.new("L", (b[2] - b[0] + 8, b[3] - b[1] + 8), 0); d = ImageDraw.Draw(m); d.fontmode = "1"
    d.text((4 - b[0], 4 - b[1]), text, font=f, fill=255)
    m = m.crop(m.getbbox() or (0, 0, 1, 1))
    return m.resize((m.width * 2, m.height * 2), Image.NEAREST)

def wrap(text, path, size, maxw):
    f = ImageFont.truetype(path, size); words = text.split(); lines = []; cur = ""
    for w_ in words:
        t = (cur + " " + w_).strip()
        if f.getlength(t) * 2 <= maxw: cur = t
        else: lines.append(cur); cur = w_
    if cur: lines.append(cur)
    return lines

def put(canvas, mask, x, y, col):
    canvas.paste(col, (int(x), int(y)), mask)

def ink_line(d, pts, col, w=2):
    """A ballpoint stroke on the 2x grid: points snapped to even pixels, 2 px square nib."""
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for k in range(n + 1):
            t = k / n; x = int(x0 + (x1 - x0) * t) // 2 * 2; y = int(y0 + (y1 - y0) * t) // 2 * 2
            d.rectangle((x, y, x + w - 1, y + w - 1), fill=col)

def arrow(d, a, b, col, bend=0.18):
    """From a (the note) to b (the thing), a slight curve, an open arrowhead."""
    mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
    nx, ny = -(b[1] - a[1]) * bend, (b[0] - a[0]) * bend
    cx, cy = mx + nx, my + ny
    pts = [((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * cx + t * t * b[0], (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * cy + t * t * b[1]) for t in [i / 24 for i in range(25)]]
    ink_line(d, pts, col)
    ex, ey = pts[-1]; px_, py_ = pts[-4]
    ang = math.atan2(ey - py_, ex - px_)
    for s in (2.6, -2.6):
        ink_line(d, [(ex, ey), (ex - 18 * math.cos(ang + s / 4.5), ey - 18 * math.sin(ang + s / 4.5))], col)


# ---------------------------------------------------------------- one slide
def render(shot, screens, out):
    seed = shot.get("n", 1) * 97
    art, geom = art_layer(seed)
    PX0, PX1, PY0, PY1, G = geom
    canvas = art.resize((OW, OH), Image.NEAREST).convert("RGB")
    d = ImageDraw.Draw(canvas)
    ink, prn = C["blu"], C["ink"]
    L0, L1 = PX0 * S + 44, G * S - 36                                         # the left page's text block
    R0, R1 = G * S + 36, PX1 * S - 44
    top = PY0 * S + 36

    # the heading: the card's title, nothing else
    hm = mask2(shot["title"], SERIF_B, 24)
    put(canvas, hm, L0, top, prn)
    y = top + hm.height + 18
    # the caption, printed as the page's opening line
    if shot.get("caption"):
        for ln in wrap(shot["caption"], SERIF, 12, L1 - L0):
            m = mask2(ln, SERIF, 12); put(canvas, m, L0, y, prn); y += 30
    fig_top = y + 22

    # the figures: crop 0 on the left page, crop 1 on the right (more crops share a page later)
    src_cache = {}
    def get(name):
        p = name if os.path.isabs(name) or ":" in name[:3] else os.path.join(screens, name)
        p = p.replace("C:/Users/danie/Zomboid/Screenshots", screens.rsplit("/", 1)[0]) if not os.path.exists(p) else p
        if p not in src_cache: src_cache[p] = Image.open(p).convert("RGB")
        return src_cache[p]
    crops = shot.get("crops", [])
    figs = []
    for i, c in enumerate(crops[:2]):
        src = get(c.get("src") or shot["src"])
        bx0, by0, bx1, by1 = c["box"]; cw, ch = bx1 - bx0, by1 - by0
        page = (L0, L1) if i == 0 else (R0, R1)
        maxh = PY1 * S - 60 - fig_top
        ftop = fig_top
        s = min(490 / cw, maxh / ch)
        fw, fh = int(cw * s), int(ch * s)
        fx = page[1] - fw if i == 0 else page[0]                              # figures sit toward the gutter
        tile = src.crop((bx0, by0, bx1, by1)).resize((fw, fh), Image.LANCZOS)
        canvas.paste(tile, (fx, ftop))
        d.rectangle((fx - 2, ftop - 2, fx + fw + 1, ftop + fh + 1), outline=prn, width=2)
        figs.append((fx, ftop, s, bx0, by0, fw, fh))

    # the notes: each balloon, in ballpoint, in the outer margin beside what it explains
    notes = {0: [], 1: []}
    for b in shot.get("balloons", []):
        ci = b.get("crop", 0)
        if ci > 1: continue
        fx, fy, s, bx0, by0, fw, fh = figs[ci]
        tx0, ty0, tx1, ty1 = b["target"]
        t = (fx + (tx0 - bx0) * s, fy + (ty0 - by0) * s, fx + (tx1 - bx0) * s, fy + (ty1 - by0) * s)
        notes[ci].append((b["text"], t))
    for ci, lst in notes.items():
        if not lst: continue
        fx, fy, s, bx0, by0, fw, fh = figs[ci]
        mx0, mx1 = (L0, fx - 40) if ci == 0 else (fx + fw + 40, R1)
        lst.sort(key=lambda n: (n[1][1] + n[1][3]) / 2)
        cur = fy - 10
        for text, t in lst:
            lines = wrap(text, BALL, 15, mx1 - mx0)
            hgt = len(lines) * 34
            ty = (t[1] + t[3]) / 2
            ny = max(cur, ty - hgt / 2)
            masks = [mask2(ln, BALL, 15) for ln in lines]
            wmax = max(m.width for m in masks)
            for k, m in enumerate(masks):
                x = mx0
                put(canvas, m, x, ny + k * 34 + (k % 2) * 2, ink)
            # the arrow leaves the line nearest the thing and stops just short of it
            ay = ny + min(len(lines) - 1, max(0, int((ty - ny) // 34))) * 34 + 16
            if ci == 0:
                lw = masks[min(len(masks) - 1, max(0, int((ty - ny) // 34)))].width
                a = (mx0 + lw + 12, ay); bpt = (t[0] - 10, ty)
            else:
                a = (mx0 - 10, ay); bpt = (t[2] + 10, ty)
            arrow(d, a, bpt, ink, bend=0.12 if ci == 0 else -0.12)
            cur = ny + hgt + 26

    # the wear over everything, on the art grid
    top_art = Image.new("RGB", (W, H)); top_art.paste(art)
    before = top_art.copy()
    overlay_art(top_art, geom, seed)
    diff = Image.new("L", (W, H), 0); dp = diff.load(); a, b_ = before.load(), top_art.load()
    for yy in range(H):
        for xx in range(W):
            if a[xx, yy] != b_[xx, yy]: dp[xx, yy] = 255
    ring_or_ear = top_art.resize((OW, OH), Image.NEAREST); m4 = diff.resize((OW, OH), Image.NEAREST)
    # the ring tints what is printed under it rather than painting over it
    canvas_px = canvas.load(); r_px = ring_or_ear.load(); m_px = m4.load(); a4 = before.resize((OW, OH), Image.NEAREST).load()
    for yy in range(OH):
        for xx in range(OW):
            if m_px[xx, yy]:
                nb, ob = r_px[xx, yy], a4[xx, yy]
                if xx > PX1 * S - 14 * S and yy > PY1 * S - 14 * S: canvas_px[xx, yy] = nb       # the dog-ear covers
                else:
                    o = canvas_px[xx, yy]; canvas_px[xx, yy] = tuple(int(o[i] * .8 + C["ring"][i] * .2) for i in range(3))
    canvas.save(out)
    print("wrote", out)


if __name__ == "__main__":
    spec = json.load(open(sys.argv[1]))
    shot = next(s for s in spec["shots"] if s.get("id") == sys.argv[3])
    render(shot, sys.argv[2], sys.argv[4])


def art_layer_close(seed, side="right"):
    """The camera close on one page: the spine and a sliver of the facing page down one edge of the frame, the
    page's fore-edge and its stack down the other. Nothing is laid out across the spine."""
    rng = random.Random(seed)
    im = Image.new("RGB", (W, H), C["wd1"]); px = im.load()
    def P(x, y, c):
        if 0 <= x < W and 0 <= y < H: px[x, y] = C[c] if isinstance(c, str) else c
    for y in range(H):
        for x in range(W):
            l = 1 - (0.6 * x / W + 0.45 * y / H)
            c = "wd1"
            if dith(x, y, max(0, l - 0.45) * 1.4): c = "wd2"
            if dith(x, y, max(0, 0.42 - l) * 1.6): c = "wd0"
            px[x, y] = C[c]
    SP = 14                                    # the spine's position from the frame edge
    PX0, PX1, PY0, PY1 = SP + 2, W - 9, 3, H - 6
    for y in range(0, H):                      # the facing page's sliver, curving away into the spine
        for x in range(0, SP):
            t = x / SP
            c = "pg1" if dith(x, y, 0.3 + t * 0.4) else "pg2"
            if t > 0.7 and dith(x, y, (t - 0.7) * 3): c = "pg3"
            P(x, y, c)
    for y in range(PY0 - 3, PY1 + 6):          # the stack and the board at the fore-edge and the foot
        for k in range(5): P(PX1 + 1 + k, y, "pg2" if k % 2 else "pg3")
        for k in range(3): P(PX1 + 6 + k, y, "cv1" if dith(PX1 + 6 + k, y, .5) else "cv0")
    for x in range(SP, PX1 + 9):
        for k in range(3): P(x, PY1 + 1 + k, "pg2" if k % 2 else "pg3")
        for k in range(2): P(x, PY1 + 4 + k, "cv0")
    for y in range(PY0, PY1 + 1):
        for x in range(PX0, PX1 + 1):
            d_g = x - PX0
            d_e = min(PX1 - x, y - PY0 + 6, PY1 - y)
            c = "pg0"
            if dith(x, y, 0.18 + max(0, 6 - d_e) * 0.09): c = "pg1"
            if d_g < 16 and dith(x, y, (16 - d_g) / 16 * 0.9): c = "pg1"
            if d_g < 7 and dith(x, y, (7 - d_g) / 7 * 0.9): c = "pg2"
            if d_g < 2: c = "pg3"
            px[x, y] = C[c]
    for y in range(H): P(SP, y, "pg4"); P(SP + 1, y, "pg3")
    for _ in range(40):
        x, y = rng.randrange(PX0 + 14, PX1 - 4), rng.randrange(PY0 + 4, PY1 - 4)
        P(x, y, "pg1")
    if side == "left":
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
        PX0, PX1 = W - 1 - PX1, W - 1 - PX0
    return im, (PX0, PX1, PY0, PY1, side)
