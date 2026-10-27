"""v3: as v2 (main 56 units, off 44), but one item in both hands keeps the main hand's circle, and the off hand
slides in behind it, peeking out PEEK units on the strap side (director, Oct 27 2026: "keeping the primary the
circle, and having the secondary peeking from behind when an item is in both hands"). Drawn at 1.75x with the
belt's pixel rules and the colours of the 4K capture."""
import math, os, sys
from PIL import Image
D = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, D)
import capsule as C
FR = sys.argv[1]
C.SURF2, C.BORDER, C.BASE, C.POS = (29, 28, 30, 255), (58, 56, 59, 255), (15, 14, 17, 255), (122, 154, 52, 255)
C.WARN = (196, 154, 42, 255)
src = Image.open(os.path.join(FR, "01_dark_small.png")).convert("RGBA")
W, Hh = src.size
SC, HAIR = 1.75, 2
SOFF, SMAIN, G, END, CY = 77, 98, 11, 18, 91.5     # 44u, 56u, the pair's 6u gap, the strap's 10u gap, the belt's middle
PEEK = int(sys.argv[2]) if len(sys.argv) > 2 else 14     # how far the off hand peeks out from behind the main (units)
strap = src.crop((78 + 91 + END, 0, 759 - END, Hh))

def disc(cx, cy, r, scale):
    """the picture inside a captured hand, as a round cut-out (r px), scaled"""
    box = src.crop((int(cx - r), int(cy - r), int(cx + r), int(cy + r)))
    m = Image.new("L", box.size, 0); mp = m.load()
    for y in range(box.height):
        for x in range(box.width):
            if math.hypot(x + .5 - r, y + .5 - r) < r: mp[x, y] = 255
    box.putalpha(m)
    if scale != 1: box = box.resize((round(box.width * scale), round(box.height * scale)), Image.LANCZOS)
    return box
knife = disc(123.5, 91.5, 26, 28 / 34)        # the off hand's picture: 28 units instead of 34
hammer = disc(804.5, 91.5, 26, 1)

def ring_hand(cv, x, y, s, f, pic):
    """one hand s px across at (x, y): fill, outline, picture, framed ring (ZeD_Belt.lua's order)"""
    C.put(cv, C.stadium_rows(s, 0), x, y, C.SURF2)
    C.put(cv, C.band_rows(s, 0, HAIR * 2), x, y, C.BORDER)
    cv.alpha_composite(pic, (x + (s - pic.width) // 2, y + (s - pic.height) // 2))
    ins, t, fw = 3 * HAIR, 6 * HAIR, HAIR
    rx, ry, rs = x + ins, y + ins, s - 2 * ins
    C.put(cv, C.band_rows(rs, 0, t), rx, ry, C.BASE)
    fs, ft = rs - 2 * fw, t - 2 * fw
    _, tot = C.track_param(0, 0, fs, 0, ft)
    C.put(cv, C.band_rows(fs, 0, ft), rx + fw, ry + fw, C.grad(f), keep=lambda X, Y: C.track_param(X, Y, fs, 0, ft)[0] <= f * tot)
    C.put(cv, C.band_rows(rs, 0, fw), rx, ry, C.BORDER)
    i = t - fw
    C.put(cv, C.band_rows(rs - 2 * i, 0, fw), rx + i, ry + i, C.BORDER)

def pair(cv, x, both):
    yo, ym = round(CY - SOFF / 2), round(CY - SMAIN / 2)
    if not both:
        ring_hand(cv, x, yo, SOFF, 0.50, knife)
        ring_hand(cv, x + SOFF + G, ym, SMAIN, 0.80, hammer)
        return
    # the off hand first, empty (fill and outline), slid in under the main hand; then the main hand over it
    xm = x + SOFF + G
    xo = xm - round(PEEK * SC)
    C.put(cv, C.stadium_rows(SOFF, 0), xo, yo, C.SURF2)
    C.put(cv, C.band_rows(SOFF, 0, HAIR * 2), xo, yo, C.BORDER)
    ring_hand(cv, xm, ym, SMAIN, 0.80, hammer)

def build(order, both):
    cv = Image.new("RGBA", (W, Hh), (0, 0, 0, 255))
    total = strap.width + END + SOFF + G + SMAIN
    x = (W - total) // 2
    if order == "right":
        cv.paste(strap, (x, 0)); pair(cv, x + strap.width + END, both)
    else:
        pair(cv, x, both); cv.paste(strap, (x + SOFF + G + SMAIN + END, 0))
    return cv

for order in ("right", "left"):
    build(order, False).save(os.path.join(D, "%s_two_v3.png" % order))
    build(order, True).save(os.path.join(D, "%s_both_v3.png" % order))
ims = [Image.open(os.path.join(D, n + ".png")) for n in ("right_two_v3", "right_both_v3", "left_two_v3", "left_both_v3")]
sh = Image.new("RGB", (W, Hh * 4)); [sh.paste(im, (0, Hh * i)) for i, im in enumerate(ims)]; sh.save(os.path.join(D, "sheet_v3.png"))
print("ok")
