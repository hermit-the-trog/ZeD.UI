"""make_b21.py - the beta 21 gallery pictures (Nov 19 2026, Build).

The director (asked as a choice): "A beta 21 set: ... a few new pictures: Lite next to Full, the first-launch setup, a
tour balloon, the keyboard map." Made as the 1.0 set's pitch pictures are (upload_v1/00a..00d): the real screen, in
game, with one ZeD window across it saying what it shows, two keycaps at its foot. Sources: QA's 4K captures copied
into Zomboid/Screenshots/gallery_b21/. Writes upload_b21/b21_*.jpg, 1920 x 1080, each under 1 MB, and a contact sheet.

Run from the repo root:  python ZeDUI/workshop/gallery/make_b21.py
"""
import os
from PIL import Image, ImageDraw, ImageEnhance, ImageFont

SRC = os.path.join(os.path.expanduser("~"), "Zomboid", "Screenshots", "gallery_b21")
HERE = os.path.join("ZeDUI", "workshop", "gallery")
OUT = os.path.join(HERE, "upload_b21")
FONTS = os.path.join(HERE, "fonts")
W, H = 1920, 1080

BASE, SURF2, LINE, STRIPE = (26, 26, 30), (34, 34, 38), (110, 110, 116), (58, 58, 64)
TEXT, TEAL = (222, 222, 226), (92, 184, 170)
GOOD, BAD = (51, 204, 77), (230, 64, 64)


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size)


def src(name):
    return Image.open(os.path.join(SRC, name)).convert("RGB")


def wrap(d, text, f, maxw):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if d.textlength(t, font=f) <= maxw:
            cur = t
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def keycap(d, x, y, w, h, label, kind):
    """The System 7 keycap: plain (one line), default (two lines, the accent), or Lite's filled good / bad."""
    f = font("FiraMono-Regular.ttf", 26)
    if kind in ("good", "bad"):
        c = GOOD if kind == "good" else BAD
        fill = tuple(int(SURF2[i] * 0.75 + c[i] * 0.25) for i in range(3))
        d.rounded_rectangle((x, y, x + w, y + h), radius=6, fill=fill, outline=c, width=3)
        tc = TEXT
    elif kind == "default":
        d.rounded_rectangle((x, y, x + w, y + h), radius=6, fill=SURF2, outline=TEAL, width=2)
        d.rounded_rectangle((x + 4, y + 4, x + w - 4, y + h - 4), radius=4, outline=TEAL, width=2)
        tc = TEAL
    else:
        d.rounded_rectangle((x, y, x + w, y + h), radius=6, fill=SURF2, outline=LINE, width=2)
        d.rounded_rectangle((x + 4, y + 4, x + w - 4, y + h - 4), radius=4, outline=LINE, width=1)
        tc = TEXT
    l, t, r, b = d.textbbox((0, 0), label, font=f)
    d.text((x + (w - (r - l)) / 2 - l, y + (h - (b - t)) / 2 - t), label, font=f, fill=tc)


def caption(im, box, text, keys, size=44):
    """A ZeD window across the picture: the striped title bar with its close box and window box, the words, then the
    foot band with the keycaps right-aligned (keys: [(label, kind)])."""
    x0, y0, x1 = box
    d = ImageDraw.Draw(im)
    f = font("FiraSans-SemiBold.ttf", size)
    lines = wrap(d, text, f, x1 - x0 - 80)
    lh = int(size * 1.25)
    tb, foot = 40, 88
    h = tb + 30 + len(lines) * lh + 30 + foot
    y1 = y0 + h
    d.rectangle((x0 + 6, y0 + 6, x1 + 6, y1 + 6), fill=(0, 0, 0))                 # the hard shadow
    d.rectangle((x0, y0, x1, y1), fill=BASE, outline=LINE, width=2)
    for i in range(10, tb - 8, 4):                                                   # the title bar's stripes
        d.line((x0 + 56, y0 + i, x1 - 56, y0 + i), fill=STRIPE, width=2)
    d.rectangle((x0 + 16, y0 + 10, x0 + 38, y0 + 32), outline=TEXT, width=2)         # the close box
    d.line((x0 + 21, y0 + 15, x0 + 33, y0 + 27), fill=TEXT, width=2)
    d.line((x0 + 33, y0 + 15, x0 + 21, y0 + 27), fill=TEXT, width=2)
    d.rectangle((x1 - 38, y0 + 10, x1 - 16, y0 + 32), outline=TEXT, width=2)         # the window box
    for k in (16, 21, 26):
        d.line((x1 - 33, y0 + k, x1 - 21, y0 + k), fill=TEXT, width=2)
    d.line((x0, y0 + tb, x1, y0 + tb), fill=LINE, width=2)
    ty = y0 + tb + 30
    for ln in lines:
        l, t, r, b = d.textbbox((0, 0), ln, font=f)
        d.text((x0 + (x1 - x0 - (r - l)) / 2 - l, ty), ln, font=f, fill=TEXT)
        ty += lh
    fy = y1 - foot
    d.rectangle((x0 + 2, fy, x1 - 2, y1 - 2), fill=SURF2)
    d.line((x0, fy, x1, fy), fill=LINE, width=2)
    kx = x1 - 24
    for label, kind in reversed(keys):
        kw = max(150, int(d.textlength(label, font=font("FiraMono-Regular.ttf", 26))) + 60)
        kx -= kw
        keycap(d, kx, fy + 18, kw, 54, label, kind)
        kx -= 22
    return y1


def chip(im, x, y, text):
    d = ImageDraw.Draw(im)
    f = font("FiraMono-Regular.ttf", 30)
    l, t, r, b = d.textbbox((0, 0), text, font=f)
    d.rectangle((x, y, x + (r - l) + 24, y + (b - t) + 16), fill=TEAL)
    d.text((x + 12 - l, y + 8 - t), text, font=f, fill=BASE)


def scene(name, crop, dim=1.0):
    im = src(name).crop(crop).resize((W, H), Image.LANCZOS)
    if dim != 1.0:
        im = ImageEnhance.Brightness(im).enhance(dim)
    return im


def lite_full():
    im = scene("lite_01_world.png", (0, 0, 3840, 2160), 0.45)
    box = (740, 0, 1930, 745)   # the Character window and its drawer, 4K
    s = 0.78
    pw, ph = int((box[2] - box[0]) * s), int((box[3] - box[1]) * s)
    gap = (W - 2 * pw) // 3
    for i, (name, label) in enumerate([("lite_01_world.png", "LITE"), ("full_10_same.png", "FULL")]):
        p = src(name).crop(box).resize((pw, ph), Image.LANCZOS)
        x = gap + i * (pw + gap)
        im.paste(p, (x, 60))
        ImageDraw.Draw(im).rectangle((x - 1, 59, x + pw, 60 + ph), outline=LINE, width=2)
        chip(im, x, 60 + ph + 10, label)
    caption(im, (300, 770, 1620), "Lite on the left, Full on the right.", [("Lite", "good"), ("Full", "default")])
    return im


def first_launch():
    im = scene("welcome_12.png", (480, 120, 3360, 1740))
    caption(im, (1400, 690, 1900), "Your setup, the first time ZeD runs.", [("Skip", "plain"), ("Done", "default")], 38)
    return im


def tour():
    im = scene("tour_18.png", (300, 0, 3180, 1620))
    caption(im, (40, 740, 980), "Show me around: a balloon tour of every window, the tabs too.",
            [("Stop tour", "plain"), ("Next", "default")], 40)
    return im


def keyboard():
    im = src("kbmap_11.png").crop((0, 0, 1920, 1080))
    caption(im, (960, 650, 1890), "Every key the game uses, on one keyboard. Click a key box to change it.",
            [("Reset", "plain"), ("Close", "default")], 40)
    return im


def main():
    os.makedirs(OUT, exist_ok=True)
    made = []
    for name, fn in [("b21_a_lite_full", lite_full), ("b21_b_first_launch", first_launch), ("b21_c_tour", tour),
                     ("b21_d_keyboard_map", keyboard)]:
        im = fn()
        p = os.path.join(OUT, name + ".jpg")
        q = 92
        while True:
            im.save(p, "JPEG", quality=q, subsampling=0, optimize=True)
            if os.path.getsize(p) < 1000000 or q <= 70:
                break
            q -= 4
        made.append(p)
        print(p, os.path.getsize(p), "q", q)
    sheet = Image.new("RGB", (W, H), BASE)
    for i, p in enumerate(made):
        t = Image.open(p).resize((W // 2, H // 2))
        sheet.paste(t, ((i % 2) * (W // 2), (i // 2) * (H // 2)))
    sheet.save(os.path.join(HERE, "upload_contact_b21.jpg"), quality=85)


if __name__ == "__main__":
    main()
