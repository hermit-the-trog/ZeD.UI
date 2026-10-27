"""The hands-together options from the 4K capture (zqa_fr_01 / 07 crops, 1.75x): strap and hands cut out and
placed again; the joined hands drawn with capsule.py in the colours the capture has."""
import math, os, sys
from PIL import Image
D = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, D)
import capsule as C
FR = sys.argv[1]
C.SURF2, C.BORDER, C.BASE, C.POS = (29, 28, 30, 255), (58, 56, 59, 255), (15, 14, 17, 255), (122, 154, 52, 255)
two = Image.open(os.path.join(FR, "01_dark_small.png")).convert("RGBA")
both = Image.open(os.path.join(FR, "07_both_hands.png")).convert("RGBA")
W, H = two.size                 # 930 x 165; hands at x 78 (off) and 759 (main), y 46, 91 across
S, Y, END, G = 91, 46, 18, 11   # hand, its top, the hand-to-strap gap (10u), the pair's gap (6u)
def sq(im, x): return im.crop((x - 2, Y - 2, x + S + 2, Y + S + 2))
off, main = sq(two, 78), sq(two, 759)
strap = two.crop((78 + S + END, 0, 759 - END, H))          # the strap with its slots and buckle
inner = two.crop((759, Y, 759 + S, Y + S))                   # the hammer inside its ring, for the joined picture

def canvas(): return Image.new("RGBA", (W, H), (0, 0, 0, 255))
def pair(cv, x, joined):
    if not joined:
        cv.paste(off, (x - 2, Y - 2)); cv.paste(main, (x + S + G - 2, Y - 2))
        return
    C.hand(cv, x, Y, 1.75, 0.80, L=S + G)
    # the picture: the hammer as the main hand shows it, inside a circle that stops short of its ring
    m = Image.new("L", (S, S), 0); mp = m.load()
    for yy in range(S):
        for xx in range(S):
            if math.hypot(xx + .5 - S / 2, yy + .5 - S / 2) < 26: mp[xx, yy] = 255
    cv.paste(inner, (x + (2 * S + G - S) // 2, Y), m)

def build(order, joined):
    cv = canvas()
    total = strap.width + END + 2 * S + G
    x = (W - total) // 2
    if order == "right":
        cv.paste(strap, (x, 0)); pair(cv, x + strap.width + END, joined)
    else:
        pair(cv, x, joined); cv.paste(strap, (x + 2 * S + G + END, 0))
    return cv

two.save(os.path.join(D, "today_two.png")); both.save(os.path.join(D, "today_both.png"))
for order in ("right", "left"):
    build(order, False).save(os.path.join(D, "%s_two.png" % order))
    build(order, True).save(os.path.join(D, "%s_both.png" % order))
print("ok")
