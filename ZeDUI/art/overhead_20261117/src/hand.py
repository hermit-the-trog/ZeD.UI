"""The foraging pointer as a pointing hand (Nov 17 2026, the director: "What about pointing fingers? I know the cursor
already does that. But it can be like a different kind of point. Maybe it has a little arm attached to it.") A printer's
fist, the old manicule: a shirt sleeve, a white cuff, the hand side-on with the index finger out and the thumb laid
over the curled fingers. Drawn smooth (8x, box-filtered down) because the game turns it."""
import os
from PIL import Image, ImageDraw
SS = 8
INK = (14, 14, 16, 255); SLEEVE = (52, 66, 92, 255); SLEEVE_HI = (78, 96, 128, 255); CUFF = (240, 237, 228, 255)
SKIN = (236, 198, 160, 255); SKIN_SH = (204, 154, 116, 255); NAIL = (246, 222, 204, 255); LINK = (196, 150, 40, 255)

def hand(W=46, H=26, lw=1.25):
    im = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    s = lambda v: v * SS
    def rr(box, r, fill, outline=True):
        x0, y0, x1, y1 = box
        if outline: d.rounded_rectangle([s(x0 - lw), s(y0 - lw), s(x1 + lw), s(y1 + lw)], radius=s(r + lw), fill=INK)
        d.rounded_rectangle([s(x0), s(y0), s(x1), s(y1)], radius=s(r), fill=fill)
    def ln(pts, w=0.9, fill=INK): d.line([(s(x), s(y)) for x, y in pts], fill=fill, width=int(s(w)), joint="curve")
    # the sleeve, cut off at the left edge, and its cuff
    rr((1.5, 7.0, 12.5, 21.0), 1.0, SLEEVE)
    d.rectangle([s(1.5), s(8.2), s(12.5), s(9.4)], fill=SLEEVE_HI)
    rr((11.5, 5.8, 15.8, 22.2), 1.2, CUFF)
    d.ellipse([s(12.9), s(13.2), s(14.5), s(14.8)], fill=LINK)
    # the curled fingers (under), the fist, the index finger out, the thumb laid over
    rr((16.0, 6.6, 29.5, 21.6), 4.5, SKIN)
    for y in (13.4, 16.4, 19.4):                                           # the curled fingers' knuckles, front
        rr((23.6, y - 1.25, 31.6, y + 1.65), 1.6, SKIN)
    rr((26.0, 6.6, 43.8, 11.4), 2.4, SKIN)                                 # the index finger
    d.rounded_rectangle([s(26.4), s(9.6), s(43.4), s(11.0)], radius=s(0.6), fill=SKIN_SH)
    d.rounded_rectangle([s(39.6), s(7.4), s(42.8), s(9.6)], radius=s(1.0), fill=NAIL)   # its nail
    ln([(36.0, 6.9), (36.0, 8.2)], 0.7)                                     # its knuckle crease
    rr((17.6, 10.6, 28.6, 13.4), 1.4, SKIN)                                # the thumb, over the curled fingers
    d.rounded_rectangle([s(18.0), s(12.2), s(28.2), s(13.2)], radius=s(0.5), fill=SKIN_SH)
    d.rounded_rectangle([s(16.8), s(18.6), s(23.6), s(21.0)], radius=s(1.6), fill=SKIN_SH)  # the fist's underside
    return im.resize((W, H), Image.BOX)

if __name__ == "__main__":
    os.makedirs("art/hand", exist_ok=True)
    h = hand(); h.save("art/hand/forage_hand_right.png"); h.transpose(Image.FLIP_LEFT_RIGHT).save("art/hand/forage_hand_left.png")
    k = 10; S = Image.new("RGBA", (h.width * k + 40, h.height * k + 40), (110, 110, 106, 255)); S.alpha_composite(h.resize((h.width * k, h.height * k), Image.NEAREST), (20, 20)); S.save("hand_try1.png")
    print(h.size)
