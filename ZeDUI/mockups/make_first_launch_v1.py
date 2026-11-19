"""First launch, mockup v1 (Nov 19 2026, beta 21). The director: "Pick their own experience including settings with
preview on first launch out of a live game, can be skipped and they get the setup we default to", "there should be a
choice to load a previous setup", and a tutorial "an option up front to skip. Balloons guide through each window."
One ZeD window on the main menu desk, the first time ZeD runs: three ways in at the top; under "Pick your own" the
few choices that change the most, with a live preview beside them; the tutorial as a pick-one; Skip at the foot.
Run from the repo root; writes ZeDUI/mockups/zed_first_launch_v1.png."""
import os
from PIL import Image, ImageDraw, ImageFont

FONTS = os.path.join("ZeDUI", "workshop", "gallery", "fonts")
S = 2
BG, SURF, SURF2, SURF3 = (26, 26, 30), (34, 34, 38), (42, 42, 46), (51, 51, 56)
TEXT, DIM, LINE, ACC = (212, 212, 216), (140, 140, 146), (110, 110, 116), (212, 146, 42)
GOOD = (51, 204, 77)


def f(n):
    return ImageFont.truetype(os.path.join(FONTS, "FiraMono-Regular.ttf"), n * S)


def T(d, x, y, s, size=10, col=TEXT, anchor="la"):
    d.text((x * S, y * S), s, font=f(size), fill=col, anchor=anchor)


def radio(d, x, y, on):
    d.ellipse((x * S, y * S, (x + 11) * S, (y + 11) * S), outline=LINE, width=S)
    if on:
        d.ellipse(((x + 3) * S, (y + 3) * S, (x + 8) * S, (y + 8) * S), fill=ACC)


def choices(d, x, y, items, pick):
    for i, s in enumerate(items):
        radio(d, x, y + 1, i == pick)
        T(d, x + 16, y, s, 9)
        x += 16 + len(s) * 5.6 + 14


def button(d, x, y, w, label, kind=None):
    col = GOOD if kind == "good" else LINE
    fill = (40, 80, 50) if kind == "good" else SURF2
    d.rounded_rectangle((x * S, y * S, (x + w) * S, (y + 22) * S), radius=4 * S, fill=fill, outline=col, width=2 * S)
    T(d, x + w / 2, y + 5, label, 9, TEXT, "ma")


def main():
    W, H = 720, 520
    im = Image.new("RGB", (W * S, H * S), BG)
    d = ImageDraw.Draw(im)
    for i in range(0, 20, 2):
        d.rectangle((0, i * S, W * S, (i + 1) * S), fill=SURF3)
    d.rectangle(((W // 2 - 90) * S, 2 * S, (W // 2 + 90) * S, 18 * S), fill=SURF2)
    T(d, W // 2, 4, "Welcome to ZeD-GUI", 10, ACC, "ma")
    T(d, 20, 32, "How do you want it? You can change any of this later in ZeD setup.", 10, TEXT)
    # the three ways in
    ways = [("Pick your own", "The choices below, with a preview", True),
            ("Load a setup", "From a file you saved before", False),
            ("Skip", "ZeD as it comes", False)]
    x = 20
    for title, sub, on in ways:
        d.rounded_rectangle((x * S, 52 * S, (x + 214) * S, 96 * S), radius=3 * S, fill=(70, 54, 28) if on else SURF2,
                            outline=ACC if on else LINE, width=2 * S)
        radio(d, x + 10, 60, on)
        T(d, x + 28, 59, title, 10)
        T(d, x + 28, 76, sub, 8, DIM)
        x += 230
    # the choices
    y = 118
    rows = [("Style", ["Full", "Lite"], 0), ("Theme", ["Dark", "Light", "High contrast"], 0),
            ("Text", ["Small", "Large"], 0), ("Playing with", ["Mouse and keys", "Controller"], 0),
            ("Moodles", ["Right", "Left", "Bottom"], 0), ("Tutorial", ["Show me around", "No thanks"], 0)]
    for label, items, pick in rows:
        T(d, 20, y, label, 9, DIM)
        choices(d, 120, y, items, pick)
        y += 30
    T(d, 20, y + 2, "Accent", 9, DIM)
    sw = [(212, 146, 42), (200, 70, 60), (210, 190, 60), (80, 170, 90), (70, 130, 210), (60, 170, 170), (150, 100, 200),
          (210, 110, 160), (180, 180, 180)]
    for i, c in enumerate(sw):
        bx = 120 + i * 20
        d.rectangle((bx * S, y * S, (bx + 14) * S, (y + 14) * S), fill=c, outline=TEXT if i == 0 else None, width=S)
    # the preview
    px, py, pw, ph = 470, 112, 230, 220
    T(d, px, py - 2, "PREVIEW", 9, ACC)
    py += 16
    d.rectangle((px * S, py * S, (px + pw) * S, (py + ph) * S), fill=(60, 70, 50))
    wx, wy = px + 12, py + 14
    d.rectangle((wx * S, wy * S, (wx + 160) * S, (wy + 130) * S), fill=SURF, outline=LINE, width=S)
    for i in range(0, 12, 2):
        d.rectangle(((wx + 1) * S, (wy + i + 1) * S, (wx + 159) * S, (wy + i + 2) * S), fill=SURF3)
    T(d, wx + 80, wy + 1, "Inventory", 7, ACC, "ma")
    for i, (n, c) in enumerate([("Apple (Fresh)", "Food"), ("Hunting Knife", "Weapon"), ("Lighter", "Fire"), ("Bandage", "Medical")]):
        yy = wy + 20 + i * 16
        if i == 0:
            d.rectangle(((wx + 2) * S, (yy - 2) * S, (wx + 158) * S, (yy + 12) * S), fill=(90, 66, 30))
        T(d, wx + 8, yy, n, 7)
        T(d, wx + 110, yy, c, 7, DIM)
    button(d, wx + 20, wy + 96, 56, "Drop")
    button(d, wx + 84, wy + 96, 56, "Eat", "good")
    T(d, px, py + ph + 8, "The preview changes as you pick.", 8, DIM)
    # the foot band
    fy = H - 44
    d.rectangle((0, fy * S, W * S, H * S), fill=SURF)
    d.line((0, fy * S, W * S, fy * S), fill=LINE, width=S)
    T(d, 20, fy + 15, "Skip gives you ZeD as it comes. Nothing here starts a game.", 8, DIM)
    button(d, W - 236, fy + 11, 96, "Save setup...")
    button(d, W - 128, fy + 11, 108, "Done", "good")
    p = os.path.join("ZeDUI", "mockups", "zed_first_launch_v1.png")
    im.save(p)
    print(p, im.size)


if __name__ == "__main__":
    main()
