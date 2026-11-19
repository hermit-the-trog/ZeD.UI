"""Keyboard map, mockup v1 (Nov 19 2026, beta 21). The director: "Keyboard display and binding assistance."
A ZeD window like the Controller map: a drawn 1993 keyboard with every key the game uses lit (a key with two jobs in
the bad color, a conflict), then the actions in groups, each with its key; click a key box and press a key to change
it; Reset to the game's keys at the foot. Run from the repo root; writes ZeDUI/mockups/zed_keyboard_map_v1.png."""
import os
from PIL import Image, ImageDraw, ImageFont

FONTS = os.path.join("ZeDUI", "workshop", "gallery", "fonts")
S = 2
BG, SURF, SURF2, SURF3 = (26, 26, 30), (34, 34, 38), (42, 42, 46), (51, 51, 56)
TEXT, DIM, LINE, ACC, BAD = (212, 212, 216), (140, 140, 146), (110, 110, 116), (212, 146, 42), (230, 64, 64)


def f(n):
    return ImageFont.truetype(os.path.join(FONTS, "FiraMono-Regular.ttf"), n * S)


def T(d, x, y, s, size=10, col=TEXT, anchor="la"):
    d.text((x * S, y * S), s, font=f(size), fill=col, anchor=anchor)


ROWS = [
    [("Esc", 1), ("", 0.5), ("F1", 1), ("F2", 1), ("F3", 1), ("F4", 1), ("", 0.5), ("F5", 1), ("F6", 1), ("F7", 1), ("F8", 1), ("", 0.5), ("F9", 1), ("F10", 1), ("F11", 1), ("F12", 1)],
    [("`", 1), ("1", 1), ("2", 1), ("3", 1), ("4", 1), ("5", 1), ("6", 1), ("7", 1), ("8", 1), ("9", 1), ("0", 1), ("-", 1), ("=", 1), ("Back", 2)],
    [("Tab", 1.5), ("Q", 1), ("W", 1), ("E", 1), ("R", 1), ("T", 1), ("Y", 1), ("U", 1), ("I", 1), ("O", 1), ("P", 1), ("[", 1), ("]", 1), ("\\", 1.5)],
    [("Caps", 1.75), ("A", 1), ("S", 1), ("D", 1), ("F", 1), ("G", 1), ("H", 1), ("J", 1), ("K", 1), ("L", 1), (";", 1), ("'", 1), ("Enter", 2.25)],
    [("Shift", 2.25), ("Z", 1), ("X", 1), ("C", 1), ("V", 1), ("B", 1), ("N", 1), ("M", 1), (",", 1), (".", 1), ("/", 1), ("Shift", 2.75)],
    [("Ctrl", 1.5), ("", 1), ("Alt", 1.5), ("Space", 7), ("Alt", 1.5), ("", 1), ("Ctrl", 1.5)],
]
LIT = {"W", "A", "S", "D", "E", "Q", "R", "F", "Tab", "I", "M", "C", "Space", "Shift", "Ctrl", "Alt", "Esc", "1", "2", "3",
       "4", "5", "Z", "X", "G", "B", "L", "Enter"}
CONFLICT = {"G"}
PICK = "E"


def keyboard(d, x0, y0, u):
    y = y0
    for r, row in enumerate(ROWS):
        x = x0
        for label, w in row:
            if label == "":
                x += w * u
                continue
            box = (x * S, y * S, (x + w * u - 3) * S, (y + u - 3) * S)
            lit = label in LIT
            col = BAD if label in CONFLICT else (ACC if lit else LINE)
            fill = SURF3 if lit else SURF2
            if label == PICK:
                fill = (90, 66, 30)
            d.rounded_rectangle(box, radius=3 * S, fill=fill, outline=col, width=(2 if lit else 1) * S)
            T(d, x + 4, y + 3, label, 8, TEXT if lit else DIM)
            x += w * u
        y += u + (6 if r == 0 else 0)
    return y


def main():
    W, H = 640, 560
    im = Image.new("RGB", (W * S, H * S), BG)
    d = ImageDraw.Draw(im)
    # title bar
    for i in range(0, 20, 2):
        d.rectangle((0, i * S, W * S, (i + 1) * S), fill=SURF3)
    d.rectangle((W // 2 - 60) * S, 2 * S, (W // 2 + 60) * S, 18 * S) if False else None
    d.rectangle(((W // 2 - 62) * S, 2 * S, (W // 2 + 62) * S, 18 * S), fill=SURF2)
    T(d, W // 2, 4, "Keyboard map", 10, ACC, "ma")
    d.rectangle((6 * S, 5 * S, 16 * S, 15 * S), outline=LINE, width=S)
    y = keyboard(d, 18, 32, 40)
    T(d, 18, y + 4, "Lit: a key the game uses.  Red: one key, two jobs.  Pick a key to see its jobs.", 8, DIM)
    y += 24
    # the actions table
    groups = [("MOVING", [("Forward", "W", False), ("Run", "Shift", False), ("Sneak", "C", False)]),
              ("HANDS", [("Interact", "E", True), ("Reload", "R", False), ("Turn on a light", "F", False)]),
              ("WINDOWS", [("Character window", "Tab", False), ("World window", "I", False), ("Map", "M", False),
                           ("Shout", "G", False), ("Build", "G", False)])]
    col_w = [210, 210, 210]
    x = 18
    for gi, (gname, rows) in enumerate(groups):
        yy = y
        T(d, x, yy, gname, 9, ACC)
        yy += 18
        for name, key, picked in rows:
            T(d, x, yy + 3, name, 9, TEXT)
            kx = x + 130
            conflict = key in CONFLICT
            outline = BAD if conflict else (ACC if picked else LINE)
            d.rounded_rectangle((kx * S, yy * S, (kx + 62) * S, (yy + 18) * S), radius=3 * S,
                                fill=(90, 66, 30) if picked else SURF2, outline=outline, width=2 * S)
            T(d, kx + 31, yy + 4, "Press a key" if picked else key, 8, TEXT, "ma")
            yy += 24
        x += col_w[gi]
    # the foot band
    fy = H - 40
    d.rectangle((0, fy * S, W * S, H * S), fill=SURF)
    d.line((0, fy * S, W * S, fy * S), fill=LINE, width=S)
    T(d, 18, fy + 13, "Interact: press the new key, or Esc to leave it as it was", 8, DIM)
    for label, bx, bw in (("Reset to the game's keys", W - 290, 180), ("Close", W - 98, 80)):
        d.rounded_rectangle((bx * S, (fy + 9) * S, (bx + bw) * S, (fy + 31) * S), radius=4 * S, outline=LINE, width=S)
        T(d, bx + bw // 2, fy + 13, label, 9, TEXT, "ma")
    p = os.path.join("ZeDUI", "mockups", "zed_keyboard_map_v1.png")
    im.save(p)
    print(p, im.size)


if __name__ == "__main__":
    main()
