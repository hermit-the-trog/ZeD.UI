"""The Workshop thumbnail in the dark theme (the director, Nov 11 2026: "Let's just make the window look like our dark
theme and get rid of the yellow. Keep the green stripe up at the top. And maybe the animations are a little too
much."). Self-contained: the pixel fonts and the drawing are copied from src_1993_y1993.py and src_1993_year2.py.

The window: ZeD Dark (body #1a1a1e, a grey frame, dark pinstriped title bar, the title in the accent orange).
The words: THE YEAR IS white on the green band (kept), 1993 in the text colour on its red shadow, the two lines in white (the director), ALL OF IT. in a brighter red. The desktop, the menu bar and the BETA tape stay.

The animation, calmer: no rainbow cycling, no sparkles, no white flashes, no zoom rectangles, no inverted slam.
The still holds while the tape crawls slowly; then the page clears and builds itself again
(the band wipes in, THE YEAR IS types, 1993 appears digit by digit, the white lines dither in, ALL OF IT. appears).

Usage: python src_1993_dark.py <out-dir>"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
G, K = 128, 8
INK, WHT = (16, 16, 16), (255, 255, 255)
TEAL, TEALD = (31, 122, 98), (18, 78, 62)
# ZeD Dark
BASE, SURF1, SURF3 = (0x1a, 0x1a, 0x1e), (0x22, 0x22, 0x26), (0x33, 0x33, 0x38)
FRAME, STRIPE = (0x6a, 0x6a, 0x72), (0x44, 0x44, 0x4a)
TEXT, ACCENT = (0xd4, 0xd4, 0xd8), (0x47, 0xA1, 0x8C)   # the title in PZ Teal, the default accent (Dark set; the director, Nov 11 2026)
GREEN, GREEND = (0x44, 0x88, 0xCC), (0x2F, 0x5F, 0x8E)   # the band: ZeD's Blue accent, text white (the director, Nov 11 2026)
BLUE = (110, 160, 255)          # 6.7:1 on the body (the old primary blue was 2.4:1)
RED = (236, 72, 64)             # 4.6:1 (was 3.3:1)
SHADOW_RED = (196, 36, 44)      # 1993's shadow
SHADOW_INK = (6, 6, 8)          # ALL's shadow, a shade under the body
TAPE, INKT = (246, 206, 38), (20, 20, 20)
FLAG_R, FLAG_W, FLAG_B = (178, 34, 52), (236, 236, 236), (60, 59, 110)   # Old Glory red, white, blue

F35 = {'A': ["010", "101", "111", "101", "101"], 'B': ["110", "101", "110", "101", "110"], 'C': ["011", "100", "100", "100", "011"],
       'D': ["110", "101", "101", "101", "110"], 'E': ["111", "100", "110", "100", "111"], 'F': ["111", "100", "110", "100", "100"],
       'H': ["101", "101", "111", "101", "101"], 'I': ["111", "010", "010", "010", "111"], 'J': ["001", "001", "001", "101", "010"],
       'L': ["100", "100", "100", "100", "111"], 'M': ["10001", "11011", "10101", "10001", "10001"], 'N': ["1001", "1101", "1011", "1001", "1001"],
       'O': ["010", "101", "101", "101", "010"], 'P': ["110", "101", "110", "100", "100"], 'R': ["110", "101", "110", "101", "101"],
       'S': ["011", "100", "010", "001", "110"], 'T': ["111", "010", "010", "010", "010"], 'U': ["101", "101", "101", "101", "111"],
       'V': ["101", "101", "101", "101", "010"], 'W': ["10001", "10001", "10101", "10101", "01010"], 'Y': ["101", "101", "010", "010", "010"],
       'Z': ["111", "001", "010", "100", "111"], ' ': ["00", "00", "00", "00", "00"], '.': ["0", "0", "0", "0", "1"]}
F57 = {'W': ["10001", "10001", "10001", "10101", "10101", "11011", "10001"], 'E': ["11111", "10000", "11110", "10000", "10000", "10000", "11111"],
       'L': ["10000", "10000", "10000", "10000", "10000", "10000", "11111"], 'C': ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
       'O': ["01110", "10001", "10001", "10001", "10001", "10001", "01110"], 'M': ["10001", "11011", "10101", "10001", "10001", "10001", "10001"],
       'T': ["11111", "00100", "00100", "00100", "00100", "00100", "00100"], 'Y': ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
       'U': ["10001", "10001", "10001", "10001", "10001", "10001", "01110"], 'R': ["11110", "10001", "10001", "11110", "10010", "10001", "10001"],
       'I': ["111", "010", "010", "010", "010", "010", "111"], 'S': ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
       'N': ["10001", "11001", "10101", "10011", "10001", "10001", "10001"], 'H': ["10001", "10001", "11111", "10001", "10001", "10001", "10001"],
       'A': ["01110", "10001", "10001", "11111", "10001", "10001", "10001"], 'K': ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
       'B': ["11110", "10001", "10001", "11110", "10001", "10001", "11110"], 'D': ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
       'F': ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
       ' ': ["000", "000", "000", "000", "000", "000", "000"], '.': ["0", "0", "0", "0", "0", "0", "1"]}
BIG = {'1': ["001100", "011100", "111100", "001100", "001100", "001100", "001100", "001100", "111111"],
       '9': ["011110", "110011", "110011", "110011", "011111", "000011", "000011", "110011", "011110"],
       '3': ["011110", "110011", "000011", "000011", "001110", "000011", "000011", "110011", "011110"],
       '.': ["00", "00", "00", "00", "00", "00", "00", "11", "11"]}
HV = {'A': ["011110", "110011", "110011", "110011", "111111", "110011", "110011", "110011", "110011"],
      'L': ["110000", "110000", "110000", "110000", "110000", "110000", "110000", "110000", "111111"]}


class Art:
    def __init__(s):
        s.im = Image.new("RGB", (G, G), TEAL); s.px = s.im.load(); s.d = ImageDraw.Draw(s.im)
    def P(s, x, y, c):
        if 0 <= x < G and 0 <= y < G: s.px[x, y] = c
    def R(s, x0, y0, x1, y1, c): s.d.rectangle([x0, y0, x1, y1], fill=c)
    def text(s, t, x, y, c, font=F35, gap=1, scale=1):
        for ch in t:
            g = font.get(ch, font[' '])
            for j, row in enumerate(g):
                for i, b in enumerate(row):
                    if b == '1': s.R(x + i * scale, y + j * scale, x + i * scale + scale - 1, y + j * scale + scale - 1, c)
            x += (len(g[0]) + gap) * scale
        return x
    @staticmethod
    def tw(t, font=F35, gap=1, scale=1): return (sum(len(font.get(ch, font[' '])[0]) + gap for ch in t) - gap) * scale
    def desktop(s):
        """the desktop is an American flag (the director, Nov 11 2026): 13 stripes from the menu bar to the tape, the
        blue canton at the upper left with a field of white star pixels; only its edges show round the window"""
        for y in range(G):
            for x in range(G):
                st = max(0, min(12, (y - 11) * 13 // 105))
                if x < 52 and st < 7:
                    star = (y - 11) % 4 == 1 and (x + (2 if ((y - 11) // 4) % 2 else 0)) % 4 == 1
                    s.px[x, y] = FLAG_W if star else FLAG_B
                else:
                    s.px[x, y] = FLAG_R if st % 2 == 0 else FLAG_W
    def menubar(s, items):
        s.R(0, 0, G - 1, 9, WHT); s.R(0, 10, G - 1, 10, INK)
        x = 4
        s.R(x, 2, x + 5, 2, INK); s.P(x + 4, 3, INK); s.P(x + 3, 4, INK); s.P(x + 2, 5, INK); s.P(x + 1, 6, INK); s.R(x, 7, x + 5, 7, INK)
        x += 12
        for it in items: x = s.text(it, x, 3, INK) + 6
    def window(s, x0, y0, x1, y1, title):
        """a ZeD Dark window: grey frame, dark pinstriped title bar, close box, the title in the accent on a chip"""
        s.R(x0 + 1, y0 + 1, x1 + 1, y1 + 1, INK)                          # the one-pixel drop shadow on the desktop
        s.R(x0, y0, x1, y1, SURF1); s.d.rectangle([x0, y0, x1, y1], outline=FRAME)
        ty = y0 + 1
        for y in range(ty + 1, ty + 9, 2): s.R(x0 + 2, y, x1 - 2, y, STRIPE)
        s.R(x0, ty + 10, x1, ty + 10, FRAME)
        s.R(x0 + 7, ty + 1, x0 + 15, ty + 9, SURF1); s.d.rectangle([x0 + 8, ty + 2, x0 + 14, ty + 8], outline=FRAME)
        w = s.tw(title) + 8; cx = (x0 + x1) // 2
        s.R(cx - w // 2, ty + 1, cx + w // 2, ty + 9, SURF1)
        s.text(title, cx - s.tw(title) // 2, ty + 3, ACCENT)
        return y0 + 12
    def big(s, t, cx, y, c, shadow, scale=3, gap=2):
        """big numerals; each glyph keeps its own width (the period is narrow). Returns the width and each glyph's
        columns, shadow included, for the rebuild"""
        ws = [len(BIG[ch][0]) for ch in t]
        w = (sum(ws) + (len(t) - 1) * gap) * scale
        x = cx - w // 2
        spans = []
        for dx, dy, col in ((2, 2, shadow), (0, 0, c)):
            xx = x; spans = []
            for ch, cw in zip(t, ws):
                for j, row in enumerate(BIG[ch]):
                    for i, b in enumerate(row):
                        if b == '1': s.R(xx + i * scale + dx, y + j * scale + dy, xx + i * scale + scale - 1 + dx, y + j * scale + scale - 1 + dy, col)
                spans.append((xx, xx + cw * scale + 2))
                xx += (cw + gap) * scale
        s.spans = spans
        return w


WIN = (6, 15, 120, 121)
BAND_H = 13


def base_window():
    A = Art(); A.desktop(); A.menubar(["FILE", "EDIT", "VIEW", "SPECIAL"])
    top = A.window(*WIN, "PROJECT ZOMBOID")
    A.R(7, top, 119, 120, BASE)
    return A, top


def card():
    A, top = base_window()
    # the director, Nov 11 2026: "the year is 1993, period. So is YOUR user interface."
    stack = [("THE YEAR IS", 1, WHT, "BAND", 5), ("1993", 0, None, None, 5), ("SO IS YOUR", 1, WHT, False, 2),
             ("USER INTERFACE.", 1, WHT, False, 5), ("ALL OF IT.", 2, RED, "ALL", 0)]
    total = sum((27 if s == 0 else (18 if b == 'ALL' else 7 * s)) + g for _, s, _, b, g in stack)
    rest = total - (7 + 5)
    yy0 = top + BAND_H + (116 - (top + BAND_H) - rest) // 2
    yy = top + 3
    for text, s, col, bold, g in stack:
        if s == 0:
            A.big("1993.", 63, yy, TEXT, SHADOW_RED, scale=3); yy += 27 + g
            global DIGIT_SPANS
            DIGIT_SPANS = A.spans
        elif bold == "ALL":
            hs, hg = 2, 2
            wa = (3 * 6 + 2 * hg) * hs
            wo = A.tw("OF IT.", F57, scale=s) + 1
            sp = 7
            x = 63 - (wa + sp + wo) // 2
            for dx, dy, c in ((2, 2, SHADOW_INK), (0, 0, col)):
                xx = x
                for ch in "ALL":
                    for j, row in enumerate(HV[ch]):
                        for i, b in enumerate(row):
                            if b == "1": A.R(xx + i * hs + dx, yy + j * hs + dy, xx + i * hs + hs - 1 + dx, yy + j * hs + hs - 1 + dy, c)
                    xx += (6 + hg) * hs
            base = yy + 9 * hs
            ox = x + wa + sp
            A.text("OF IT.", ox, base - 7 * s, col, F57, scale=s)
            A.text("OF IT.", ox + 1, base - 7 * s, col, F57, scale=s)
            yy += 9 * hs + g
        else:
            TR = 3
            if bold == "BAND":
                A.R(7, top, 119, top + BAND_H - 1, GREEN)
                A.R(7, top + BAND_H - 1, 119, top + BAND_H - 1, GREEND)
            w = A.tw(text, F57, gap=TR) + 1
            x = 63 - w // 2
            A.text(text, x, yy, col, F57, gap=TR); A.text(text, x + 1, yy, col, F57, gap=TR)
            yy = yy0 if bold == "BAND" else yy + 7 * s + g
    tape_draw(A, 0)
    return A


TY0, TY1 = 116, 127


def tape_draw(A, off):
    A.R(0, TY0, 127, TY1, TAPE)
    for y_ in range(TY0 + 1, TY1):
        for x in range(128):
            if ((x + y_ + off) // 4) % 2 == 0: A.P(x, y_, INKT)
    A.R(0, TY0, 127, TY0, INKT); A.R(0, TY1, 127, TY1, INKT)
    A.R(0, TY0 + 1, 127, TY0 + 1, (255, 232, 120))
    for cx in (32, 96):
        w = A.tw("BETA", F57) + 1
        x0 = cx - w // 2 - 5
        A.R(x0, TY0 + 2, x0 + w + 9, TY1 - 1, TAPE)
        A.text("BETA", x0 + 5, TY0 + 3, INKT, F57)


FINAL_ART = card()
FINAL = np.asarray(FINAL_ART.im).copy()
os.makedirs(OUT, exist_ok=True)
FINAL_ART.im.resize((G * K, G * K), Image.NEAREST).save(os.path.join(OUT, "year_1993_dark_1024.png"))
FINAL_ART.im.resize((512, 512), Image.NEAREST).save(os.path.join(OUT, "year_1993_dark_512.png"))
_e, _top = base_window()
EMPTY = np.asarray(_e.im).copy()


def tape(img, off):
    """the tape at offset off, over a frame (numpy)"""
    A = Art(); A.im = Image.fromarray(img.astype(np.uint8)); A.px = A.im.load(); A.d = ImageDraw.Draw(A.im)
    tape_draw(A, off)
    return np.asarray(A.im).copy()


ROWS = {"band": (27, 39), "year": (30, 36), "1993": (42, 71), "blue1": (74, 80), "blue2": (83, 89), "all": (95, 115)}
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]])


def dissolve(img, rows, t):
    y0, y1 = rows
    yy, xx = np.mgrid[y0:y1 + 1, 0:G]
    m = (BAYER[yy % 4, xx % 4] + 0.5) / 16 < t
    reg = img[y0:y1 + 1]; reg[m] = FINAL[y0:y1 + 1][m]
    return img


def cursor(img, on):
    if on: img[106:114, 112:116] = TEXT
    return img


# ------------------------------------------------------------------ scene 2 (the director, Nov 11 2026: "The next
# screen should say supercharged vanilla UI upgrade. Maybe with some flames.")
F57['G'] = ["01111", "10000", "10000", "10011", "10001", "10001", "01111"]
F57['P'] = ["11110", "10001", "10001", "11110", "10000", "10000", "10000"]
F57['-'] = ["000", "000", "000", "111", "000", "000", "000"]
F57['V'] = ["10001", "10001", "10001", "10001", "10001", "01010", "00100"]
FL_TIP, FL_RED, FL_ORA, FL_YEL, FL_HOT = (150, 24, 32), (220, 52, 44), (240, 128, 30), (250, 204, 56), (255, 240, 170)
FL_BOTTOM = 115


def scene2_art():
    """ALL-IN-ONE on the band (was THE ONE MOD) (the director, Nov 11 2026: "the one mod, supercharged vanilla UI upgrade"), then
    SUPERCHARGED, VANILLA big in the text color on a red shadow, UI UPGRADE, all white like scene 1's lines"""
    A, top = base_window()
    A.R(7, top, 119, top + BAND_H - 1, GREEN); A.R(7, top + BAND_H - 1, 119, top + BAND_H - 1, GREEND)
    t = "ALL-IN-ONE"; w = A.tw(t, F57, gap=3) + 1; x = 63 - w // 2             # as THE YEAR IS (the director: "No the")
    A.text(t, x, top + 3, WHT, F57, gap=3); A.text(t, x + 1, top + 3, WHT, F57, gap=3)
    t = "SUPERCHARGED"; w = A.tw(t, F57, gap=2) + 1; x = 63 - w // 2
    A.text(t, x, 45, WHT, F57, gap=2); A.text(t, x + 1, 45, WHT, F57, gap=2)
    t = "VANILLA"; w = A.tw(t, F57, gap=2, scale=2); x = 64 - w // 2
    for dx, dy, c in ((2, 2, SHADOW_RED), (3, 2, SHADOW_RED), (0, 0, TEXT), (1, 0, TEXT)):   # bold, as 1993
        A.text(t, x + dx, 56 + dy, c, F57, gap=2, scale=2)
    t = "UI UPGRADE"; w = A.tw(t, F57, gap=3) + 1; x = 63 - w // 2
    A.text(t, x, 77, WHT, F57, gap=3); A.text(t, x + 1, 77, WHT, F57, gap=3)
    return A


S2 = np.asarray(scene2_art().im).copy()
S2_ROWS = {"band": (27, 39), "word": (30, 36), "super": (45, 51), "vanilla": (56, 71), "upgrade": (77, 83)}


def flames(img, phase, grow=1.0):
    """hot-rod fire licking up from the window's foot: yellow at the root, orange, red, dark red at the tips"""
    for x in range(7, 120):
        h = 11 + 6 * np.sin(x * 0.42 + phase * 0.8) + 4 * np.sin(x * 0.16 - phase * 0.5) + 2.5 * np.sin(x * 1.1 + phase * 1.3)
        h = int(max(2, min(28, h)) * grow)
        top = FL_BOTTOM - h
        for y in range(top, FL_BOTTOM + 1):
            d = y - top
            if tuple(img[y, x]) == BASE:                                 # behind the words, never over them
                img[y, x] = FL_TIP if d < 2 else FL_RED if d < 5 else FL_ORA if d < 9 else FL_YEL if d < 15 else FL_HOT
    return img


frames = []
def add(img, ms): frames.append((img.copy(), ms))


# the slant (the director, Nov 11 2026: "Can all of it have an animated slant? Like go from regular to italic?"): each
# line of words leans over on its own middle, background left in place; the flames and the tape stay upright
LINES1 = [(95, 115, BASE)]   # only ALL OF IT. (the director: "Only the word all and all of it gets the animated italic to regular")
LINES2 = [(30, 36, GREEN), (45, 51, BASE), (56, 73, BASE), (77, 83, BASE)]
SLANT = 0.28


def italic(img, k, lines):
    if k <= 0: return img
    for y0, y1, bg in lines:
        mid = (y0 + y1) / 2
        for y in range(y0, y1 + 1):
            sh = int(round(k * (mid - y)))
            if sh == 0: continue
            row = img[y, 7:120].copy()
            content = np.any(row != np.array(bg), axis=-1)
            new = np.tile(np.array(bg, dtype=row.dtype), (row.shape[0], 1))
            xs = np.nonzero(content)[0]; nx = xs + sh; ok = (nx >= 0) & (nx < row.shape[0])
            new[nx[ok]] = row[xs[ok]]
            img[y, 7:120] = new
    return img


def ramp(i, n, up0, up1, down0, down1):
    """0 upright, 1 italic: upright until up0, leaning over to up1, italic until down0, back upright by down1"""
    if i < up0 or i >= down1: return 0.0
    if i < up1: return (i - up0 + 1) / (up1 - up0 + 1)
    if i < down0: return 1.0
    return 1 - (i - down0 + 1) / (down1 - down0 + 1)

# the hold: the still, the tape crawling one pixel every other frame (no cursor: it sat on IT.'s period)
off = 0
# ALL OF IT. (the director, Nov 11 2026): regular, starts moving, leans into italic, exits stage right, sliding out behind the
# window's right edge (clipped to the window's inside, so the frame and the flag stay on top)
def slide(img, dx, lines):
    for y0, y1, bg in lines:
        for y in range(y0, y1 + 1):
            row = img[y, 7:120].copy()
            content = np.any(row != np.array(bg), axis=-1)
            new = np.tile(np.array(bg, dtype=row.dtype), (row.shape[0], 1))
            xs = np.nonzero(content)[0]; nx = xs + dx; ok = nx < row.shape[0]
            new[nx[ok]] = row[xs[ok]]
            img[y, 7:120] = new
    return img


# it starts moving first, leans into italic as it picks up speed (the director, Nov 11 2026: "the text needs to start
# moving before it animates to italic"), then zooms off; the fire rises where it was and burns on into scene 2
EXIT = [1, 2, 3, 5, 8, 12, 18, 27, 40, 57, 80, 113]
LEAN = [0, 0, 0.25, 0.5, 0.75, 1, 1, 1, 1, 1, 1, 1]
for i in range(9):                                                      # regular, at rest
    off += 1; add(tape(FINAL, off // 2), 140)
ph = 0
for n, (dx, k) in enumerate(zip(EXIT, LEAN)):
    img = slide(italic(FINAL.copy(), SLANT * k, LINES1), dx, LINES1)
    ph += 1; off += 1; add(tape(flames(img, ph, (n + 1) / len(EXIT)), off // 2), 80 if n < 5 else 60)
GONE = slide(FINAL.copy(), 200, LINES1)


def burn(page, ms):
    """hold page for ms with the fire going: frames of 140 ms or less, the fire moving on each one"""
    global ph, off
    n = max(1, round(ms / 140))
    for _ in range(n):
        ph += 1; off += 1; add(tape(flames(page.copy(), ph), off // 2), ms // n)


burn(GONE, 560)                                                         # 1993 over the fire, a beat
# scene 2: the words clear above the fire, then ALL-IN-ONE / SUPERCHARGED / VANILLA / UI UPGRADE build over it
page = EMPTY.copy(); burn(page, 280)
for i in range(1, 7):                                                  # the band wipes across
    page = page.copy(); x = int(7 + 113 * i / 6)
    b0, b1 = S2_ROWS["band"]; page[b0:b1 + 1, 7:x] = S2[b0:b1 + 1, 7:x]
    y0, y1 = S2_ROWS["word"]; page[y0:y1 + 1, 7:x] = S2[28, 8]
    burn(page, 60)
for x in range(15, 121, 10):                                           # ALL-IN-ONE types
    y0, y1 = S2_ROWS["word"]; page[y0:y1 + 1, 7:x] = S2[y0:y1 + 1, 7:x]
    burn(page, 80)
y0, y1 = S2_ROWS["super"]; page[y0:y1 + 1] = S2[y0:y1 + 1]; burn(page, 420)     # SUPERCHARGED
y0, y1 = S2_ROWS["vanilla"]; page[y0:y1 + 3] = S2[y0:y1 + 3]; burn(page, 420)
y0, y1 = S2_ROWS["upgrade"]; page[y0:y1 + 1] = S2[y0:y1 + 1]; burn(page, 420)
burn(page, 2000)                                                        # and burns, gently

# ------------------------------------------------------------------ scene 3 (the director, Nov 11 2026: "The flames
# turn into smoke and ZeD-GUI ... comes rising from the smoke ... animate upward through the smoke from below")
F57['Z'] = ["11111", "00001", "00010", "00100", "01000", "10000", "11111"]
F57['e'] = ["00000", "00000", "01110", "10001", "11111", "10000", "01111"]
SMOKE = [(58, 58, 64), (92, 92, 98), (128, 128, 134)]          # thin, mid, thick
BODY = (27, 115)


def lerp(a, b, t): return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def cooling(img, phase, t):
    """the fire cooling: the same flames, their colours drawn toward smoke grey by t (0 fire, 1 grey)"""
    fl = flames(np.tile(np.array(BASE, dtype=img.dtype), img.shape[:2] + (1,)), phase)   # flames alone, to find them
    for col in (FL_TIP, FL_RED, FL_ORA, FL_YEL, FL_HOT):
        m = np.all(fl == np.array(col), axis=-1) & np.all(img == np.array(BASE), axis=-1)
        grey = SMOKE[1] if col in (FL_TIP, FL_RED) else SMOKE[2]
        img[m] = lerp(col, grey, t)
    return img


_rng = np.random.default_rng(1993)
_NOISE = [_rng.random((40, 24)), _rng.random((40, 24))]               # two octaves of value noise, wrapped


def _vnoise(R, x, y):
    h, w = R.shape
    x0 = np.floor(x).astype(int); y0 = np.floor(y).astype(int); fx = x - x0; fy = y - y0
    fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy)
    a = R[y0 % h, x0 % w]; b = R[y0 % h, (x0 + 1) % w]; c = R[(y0 + 1) % h, x0 % w]; d = R[(y0 + 1) % h, (x0 + 1) % w]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def smoke(img, phase, top, thin=0.0, floor=0):
    """dithered smoke billowing up over the body from row `top`; thinned by `thin`; `floor` keeps a low haze
    (the ashes) in the bottom rows whatever the thinning"""
    y0, y1 = BODY
    yy, xx = np.mgrid[y0:y1 + 1, 7:120].astype(float)
    n = 0.65 * _vnoise(_NOISE[0], xx / 9.0 + np.sin(yy / 13.0 + phase * 0.3) * 0.6, (yy + phase * 2.2) / 7.0) \
        + 0.35 * _vnoise(_NOISE[1], xx / 4.0, (yy + phase * 3.5) / 3.5)
    edge = np.clip((yy - top) / 16.0, 0, 1)
    d = np.clip(n * 1.25 * edge - thin, 0, 1)
    if floor:
        haze = np.clip((yy - (y1 - floor)) / floor, 0, 1) * n * 1.5
        d = np.maximum(d, haze)
    th = (BAYER[yy.astype(int) % 4, xx.astype(int) % 4] + 0.5) / 16
    reg = img[y0:y1 + 1, 7:120]
    for lvl, col in ((0.30, SMOKE[0]), (0.50, SMOKE[1]), (0.70, SMOKE[2])):
        reg[d > lvl + (th - 0.5) * 0.25] = col
    return img


EMBER = [(240, 128, 30), (250, 204, 56), (220, 52, 44)]


def embers(img, phase, k=7):
    """a few sparks in the ashes, blinking"""
    r = np.random.default_rng(phase)
    for _ in range(k):
        x = int(r.integers(9, 118)); y = int(r.integers(106, 115))
        img[y, x] = EMBER[int(r.integers(0, 3))]
    return img


def logo(img, y):
    """ZeD-GUI, big: the text colour on the red shadow, clipped to the body"""
    A = Art(); A.im = Image.fromarray(img.astype(np.uint8)); A.px = A.im.load(); A.d = ImageDraw.Draw(A.im)
    t = "ZeD-GUI"; SC, GP = 3, 2                                        # 3x letters, 2 pixels apart
    w = sum(len(F57[c][0]) * SC for c in t) + GP * (len(t) - 1); x0 = 64 - w // 2
    layer = Image.new("RGB", (G, G), (0, 0, 0)); L = Art(); L.im = layer; L.px = layer.load(); L.d = ImageDraw.Draw(layer)
    for dx, dy, col in ((2, 2, SHADOW_RED), (0, 0, TEXT)):
        x = x0
        for c in t:
            L.text(c, x + dx, y + dy, col, F57, scale=SC); x += len(F57[c][0]) * SC + GP
    arr = np.asarray(layer); out = img.copy()
    m = np.any(arr != 0, axis=-1); m[:BODY[0], :] = False; m[BODY[1] + 1:, :] = False; m[:, :7] = False; m[:, 120:] = False
    out[m] = arr[m]
    return out


for i in range(1, 7):                                                    # the flames cool to smoke
    ph += 1; off += 1
    img = cooling(page.copy(), ph, i / 6)
    img = smoke(img, ph, 112 - i * 9, thin=0.25 * (1 - i / 6))
    add(tape(img, off // 2), 110)
for i in range(1, 9):                                                    # the smoke rises and fills the window
    ph += 1; off += 1
    img = cooling(page.copy(), ph, 1.0)
    add(tape(smoke(img, ph, 79 - i * 10), off // 2), 110)
EMPTY3 = EMPTY.copy()
LOGO_Y = 58
RISE = [118, 108, 98, 89, 81, 74, 68, 63, 60, 58]                        # rising, slowing as it arrives
for n, y in enumerate(RISE):                                             # ZeD-GUI rises from below through the smoke
    ph += 1; off += 1
    img = logo(EMPTY3, y)
    img = smoke(img, ph, 0, thin=0.12 + 0.06 * n, floor=14)                    # the smoke over it, thinning as it comes up
    add(tape(img, off // 2), 110)
# a bald eagle soars across behind it, rising low left to high right (the director, Nov 11 2026), clipped to the
# window. The sprite is eagle_px_64.png, drawn by eagle_build.py in this picture's pixel style on the form of the
# director's photo (eagle_photo.jpg), facing right
EAGLE = np.asarray(Image.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "eagle_px_64.png")).convert("RGBA"))


def eagle(img, x, y):
    h, w = EAGLE.shape[:2]
    for j in range(h):
        yy = y + j
        if yy < BODY[0] or yy > BODY[1]: continue
        for i in range(w):
            xx = x + i
            if xx < 7 or xx > 119 or EAGLE[j, i, 3] == 0: continue
            img[yy, xx] = EAGLE[j, i, :3]
    return img


# small fireworks in the sky behind it, red, white and blue, as the eagle flies (the director, Nov 11 2026)
FW_COL = {"red": [(255, 120, 110), (236, 72, 64), (150, 30, 34)], "white": [(255, 255, 255), (220, 220, 214), (130, 130, 128)],
          "blue": [(170, 205, 255), (110, 160, 255), (50, 80, 160)]}
BURSTS = [(30, 40, 1, "red"), (98, 34, 5, "white"), (60, 95, 9, "blue"), (22, 92, 12, "white"), (96, 90, 15, "red"),
          (64, 33, 17, "blue")]                                         # (x, y, frame it launches, colour)


def firework(img, x, y, age, col):
    """age 0-2 the shell climbs (a spark and its trail), 3-9 it bursts: twelve spokes of dots spreading, then fading"""
    c = FW_COL[col]
    def put(px, py, cc):
        if 7 <= px <= 119 and BODY[0] <= py <= BODY[1]: img[py, px] = cc
    if age < 0 or age > 9: return img
    if age <= 2:
        sy = y + (2 - age) * 5
        put(x, sy, (255, 236, 170)); put(x, sy + 1, (200, 140, 60)); put(x, sy + 3, (120, 80, 40))
        return img
    k = age - 3                                                          # 0..6
    r = [1, 3, 5, 6, 7, 7.5, 8][k]
    tone = c[0] if k < 2 else c[1] if k < 5 else c[2]
    for a in range(12):
        ang = a * np.pi / 6 + (np.pi / 12 if a % 2 else 0)
        put(int(round(x + r * np.cos(ang))), int(round(y + r * np.sin(ang) + (k * k) * 0.08)), tone)
        if 1 <= k <= 4:
            put(int(round(x + (r - 2) * np.cos(ang))), int(round(y + (r - 2) * np.sin(ang))), c[1] if k < 3 else c[2])
    if k == 0: put(x, y, (255, 255, 255))
    return img


FLIGHT = 18                                                              # frames for the crossing
SKY = {"t": None}


def stand(i, n, ms, flight=None):
    global ph, off
    ph += 1; off += 1
    img = smoke(EMPTY3.copy(), ph // 3, 0, thin=0.4 + 0.08 * min(i, 8), floor=14)   # the ashes drift slowly (and keep the file small)
    img = embers(img, ph // 2)
    if SKY["t"] is not None:
        for bx, by, start, col in BURSTS: firework(img, bx, by, SKY["t"] - start, col)
        SKY["t"] += 1
    if flight is not None:
        t = flight / (FLIGHT - 1)
        img = eagle(img, int(round(-66 + t * 194)), int(round(96 - t * 112)))
    img = logo(img, LOGO_Y)
    add(tape(img, off // 2), ms)


for i in range(7):                                                       # it stands proud over the ashes
    stand(i, 7, 140)
SKY["t"] = 0
for f in range(FLIGHT):                                                  # the eagle crosses behind it
    stand(8, 0, 80, f)
for i in range(8):                                                       # and it stands on
    stand(8, 0, 140)
# back to 1993: the window clears and builds itself again (a cut, no zoom)
page = tape(EMPTY, off // 2); add(page, 400)
for i in range(1, 7):                                                  # the band wipes across
    page = page.copy(); x = int(7 + 113 * i / 6)
    b0, b1 = ROWS["band"]
    page[b0:b1 + 1, 7:x] = FINAL[b0:b1 + 1, 7:x]
    y0, y1 = ROWS["year"]
    page[y0:y1 + 1, 7:x] = FINAL[28, 8]                               # the band only, the words come next
    off += 1; add(tape(page, off // 2), 70)
xs = [c for c in range(G) if (FINAL[30:37, c] == 255).all(axis=-1).any()]
x_start, x_end = min(xs), max(xs) + 1
for x in range(x_start, x_end + 8, 8):                                 # THE YEAR IS types
    y0, y1 = ROWS["year"]
    page[y0:y1 + 1, :min(x, x_end)] = FINAL[y0:y1 + 1, :min(x, x_end)]
    off += 1; add(tape(page, off // 2), 90)
for a, b in DIGIT_SPANS:                                               # 1993., a glyph at a time
    y0, y1 = ROWS["1993"]
    page[y0:y1 + 1, a:b] = FINAL[y0:y1 + 1, a:b]
    off += 1; add(tape(page, off // 2), 220)
for i in range(1, 6):                                                  # the white lines dither in
    img = page.copy(); dissolve(img, ROWS["blue1"], i / 5); dissolve(img, ROWS["blue2"], max(0, (i - 1) / 4))
    off += 1; add(tape(img, off // 2), 90)
page = img.copy(); page[ROWS["blue1"][0]:ROWS["blue2"][1] + 1] = FINAL[ROWS["blue1"][0]:ROWS["blue2"][1] + 1]
off += 1; add(tape(page, off // 2), 400)
y0, y1 = ROWS["all"]; page[y0:y1 + 1] = FINAL[y0:y1 + 1]            # ALL OF IT. appears
off += 1; add(tape(page, off // 2), 300)

# the stills match frame 1: ALL OF IT. regular
_still = Image.fromarray(tape(FINAL.copy(), 0).astype(np.uint8))
_still.resize((G * K, G * K), Image.NEAREST).save(os.path.join(OUT, "year_1993_dark_1024.png"))
_still.resize((512, 512), Image.NEAREST).save(os.path.join(OUT, "year_1993_dark_512.png"))

# the GIF: 512, one palette, looping; frame 1 is the still (what Steam shows before it plays)
S = 4
pal = Image.fromarray(np.vstack([f for f, _ in frames[::2]]).astype(np.uint8)).quantize(colors=128, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
imgs = [Image.fromarray(f.astype(np.uint8)).resize((G * S, G * S), Image.NEAREST).quantize(palette=pal, dither=Image.Dither.NONE) for f, _ in frames]
durs = [ms for _, ms in frames]
path = os.path.join(OUT, "year_1993_dark_animated.gif")
imgs[0].save(path, save_all=True, append_images=imgs[1:], duration=durs, loop=0, optimize=True, disposal=1)
print(len(imgs), "frames,", sum(durs) / 1000, "s,", os.path.getsize(path) // 1024, "KB")
sheet = Image.new("RGB", (8 * 130, ((len(frames) + 15) // 16) * 130 + 10), (20, 20, 20))
for i, (f, _) in enumerate(frames[::2]):
    sheet.paste(Image.fromarray(f.astype(np.uint8)), ((i % 8) * 130, (i // 8) * 130))
sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(os.path.join(OUT, "year_1993_dark_frames.png"))
