"""Lite device face, mockup v1 (Nov 18 2026, beta 21): the radio's plain card as Lite would draw it.
The director: "Try to use more radio buttons than click buttons in the simple versions of our faces. It's very
button heavy right now." and "If vanilla does it, so does Lite." Today's plain card: a power switch, volume and tuning
steppers, six preset keys, mute and scan switches. Lite: every on/off and every choice a row of radio buttons (pick
one), the stations the set has found as one pick-one list (as the game's own radio window lists them), the presets
gone (the game has none), one button left (Scan). Run from the repo root; writes ZeDUI/mockups/zed_lite_device_v1.png."""
import os
from PIL import Image, ImageDraw, ImageFont

FONTS = os.path.join("ZeDUI", "workshop", "gallery", "fonts")
S = 3
BG, SURF, SURF3 = (26, 26, 30), (42, 42, 46), (51, 51, 56)
TEXT, DIM, LINE, ACC = (212, 212, 216), (140, 140, 146), (110, 110, 116), (212, 146, 42)
GOOD = (51, 204, 77)


def f(n, sans=False):
    name = "FiraSansCondensed-Regular.ttf" if sans else "FiraMono-Regular.ttf"
    p = os.path.join(FONTS, name)
    if not os.path.exists(p):
        p = os.path.join(FONTS, "FiraMono-Regular.ttf")
    return ImageFont.truetype(p, n * S)


def T(d, x, y, s, size=10, col=TEXT, sans=False):
    d.text((x * S, y * S), s, font=f(size, sans), fill=col)


def radio(d, x, y, on):
    r = 5
    d.ellipse(((x) * S, (y) * S, (x + 2 * r) * S, (y + 2 * r) * S), outline=LINE, width=S)
    if on:
        d.ellipse(((x + 3) * S, (y + 3) * S, (x + 2 * r - 3) * S, (y + 2 * r - 3) * S), fill=ACC)


def choices(d, x, y, items, pick):
    for i, s in enumerate(items):
        radio(d, x, y + 1, i == pick)
        T(d, x + 15, y, s)
        x += 15 + len(s) * 6.2 + 14


def stepper(d, x, y, w, frac, label):
    d.rounded_rectangle((x * S, y * S, (x + 18) * S, (y + 16) * S), radius=3 * S, outline=LINE, width=2 * S)
    T(d, x + 6, y + 2, "-")
    bx = x + 24
    bw = w - 48
    d.rectangle((bx * S, (y + 6) * S, (bx + bw) * S, (y + 10) * S), fill=SURF3)
    d.rectangle((bx * S, (y + 6) * S, (bx + bw * frac) * S, (y + 10) * S), fill=ACC)
    d.rounded_rectangle(((x + w - 18) * S, y * S, (x + w) * S, (y + 16) * S), radius=3 * S, outline=LINE, width=2 * S)
    T(d, x + w - 12, y + 2, "+")
    T(d, x + w + 8, y + 2, label, col=DIM)


def card():
    W, H = 330, 330
    im = Image.new("RGB", (W * S, H * S), BG)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, W * S - 1, H * S - 1), outline=LINE, width=S)
    T(d, 12, 10, "VALUTECH RADIO", 9, ACC)
    T(d, 12, 26, "98.0 MHz", 22)
    T(d, 150, 34, "NNR Radio", 11, DIM, sans=True)
    y = 66
    rows = [("Power", lambda yy: choices(d, 90, yy, ["Off", "On"], 1)),
            ("Volume", lambda yy: stepper(d, 90, yy - 1, 170, 0.6, "6")),
            ("Mute", lambda yy: choices(d, 90, yy, ["Off", "On"], 0))]
    for label, fn in rows:
        T(d, 12, y, label, 10, DIM)
        fn(y)
        y += 26
    T(d, 12, y + 4, "STATIONS FOUND", 9, ACC)
    y += 22
    for i, (fq, nm) in enumerate([("93.2", "LBMW - Kentucky Radio"), ("98.0", "NNR Radio"), ("89.4", "Hitz FM")]):
        radio(d, 14, y + 1, i == 1)
        T(d, 30, y, fq)
        T(d, 72, y, nm, 10, TEXT, sans=True)
        y += 20
    # the footer band: one button
    fy = H - 34
    d.rectangle((1 * S, fy * S, (W - 1) * S, (H - 1) * S), fill=SURF)
    d.line((0, fy * S, W * S, fy * S), fill=LINE, width=S)
    d.rounded_rectangle(((W - 82) * S, (fy + 7) * S, (W - 12) * S, (fy + 27) * S), radius=4 * S, outline=LINE, width=2 * S)
    T(d, W - 62, fy + 10, "Scan")
    T(d, 12, fy + 10, "Tune by hand: Scan, or pick a station", 8, DIM, sans=True)
    return im


def main():
    im = card()
    p = os.path.join("ZeDUI", "mockups", "zed_lite_device_v1.png")
    im.save(p)
    print(p, im.size)


if __name__ == "__main__":
    main()
