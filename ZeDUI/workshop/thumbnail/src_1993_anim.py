"""The animated Workshop thumbnail (the director, Nov 3 2026: "give it some ... what would have been cool effects for
1993, but nowadays are kind of cheesy ... Don't do anything that feels too modern").
Frame 1 is the approved still. Then: the hold (the tape crawls, 1993's shadow colour-cycles, sparkles on ALL, a
blinking cursor), the window closes in zoom rectangles, opens again, and the page rebuilds itself: the band wipes
in, THE YEAR IS types, 1993 stamps digit by digit, the blue lines dither in, ALL OF IT. slams in and flashes."""
import os, sys, io, contextlib
import numpy as np
from PIL import Image
import importlib.util
with contextlib.redirect_stdout(io.StringIO()):
    spec = importlib.util.spec_from_file_location("y2", r"C:\Temp\lead\thumb\year2.py")
    y2 = importlib.util.module_from_spec(spec); spec.loader.exec_module(y2)
y, F57, INK, RED, YEL = y2.y, y2.F57, y2.INK, y2.RED, y2.YEL
OUT = y.OUT
G = 128
FINAL = np.asarray(Image.open(os.path.join(OUT, "thumb_J_1993_and_so_is_the_ui.png")).resize((G, G), Image.NEAREST).convert("RGB")).copy()

# ------------------------------------------------------------------ the pieces
WIN = (6, 15, 120, 121)
TOP = 27
ROWS = {"band": (27, 39), "year": (30, 36), "1993": (42, 71), "blue1": (74, 80), "blue2": (83, 89), "all": (95, 115)}
TAPE_Y = (116, 127)


def art(): return y.Art()


def desktop_only():
    A = art(); A.desktop(); A.menubar(["FILE", "EDIT", "VIEW", "SPECIAL"])
    return np.asarray(A.im).copy()


def empty_window():
    A = art(); A.desktop(); A.menubar(["FILE", "EDIT", "VIEW", "SPECIAL"])
    top = A.window(*WIN, "PROJECT ZOMBOID")
    A.R(7, top, 119, 120, YEL)
    return np.asarray(A.im).copy()


DESK = desktop_only()
EMPTY = empty_window()


def tape(img, off):
    """the caution tape with its stripes moved along by off pixels (the plates stay put)"""
    TY0, TY1 = TAPE_Y
    INKT, TAPE = np.array((20, 20, 20)), np.array((246, 206, 38))
    for yy in range(TY0 + 1, TY1):
        for xx in range(G):
            img[yy, xx] = INKT if ((xx + yy + off) // 4) % 2 == 0 else TAPE
    img[TY0 + 1, :] = (255, 232, 120)
    # the plates and BETA: as in the still
    plates = FINAL[TY0 + 2:TY1, :]
    pm = np.all(FINAL[TY0 + 2:TY1, :] == FINAL[TY0 + 2, 26], axis=-1)        # plate yellow (left plate's top-left)
    # copy the still's pixels wherever the still has a plate or its letters (columns of the two plates)
    for cx in (32, 96):
        w = y.Art.tw("BETA", F57) + 1
        x0 = cx - w // 2 - 5
        img[TY0 + 2:TY1, x0:x0 + w + 10] = FINAL[TY0 + 2:TY1, x0:x0 + w + 10]
    return img


RAINBOW = [(210, 36, 44), (232, 108, 28), (236, 156, 20), (40, 160, 70), (30, 140, 200), (40, 76, 200), (150, 50, 190)]


def cycle_1993(img, phase):
    """Deluxe Paint colour cycling: 1993's red shadow runs through the rainbow, digit by digit"""
    y0, y1 = ROWS["1993"]
    reg = img[y0:y1 + 1]
    red = np.all(reg == np.array(RED), axis=-1)
    for xx in range(G):
        col = RAINBOW[(phase + xx // 10) % len(RAINBOW)]
        reg[:, xx][red[:, xx]] = col
    return img


def star(img, x, y_, size):
    """a four-point sparkle: a white centre and arms of `size`"""
    W = np.array((255, 255, 255))
    if size <= 0: return img
    for d in range(-size, size + 1):
        for (px, py) in ((x + d, y_), (x, y_ + d)):
            if 0 <= px < G and 0 <= py < G: img[py, px] = W
    if size >= 2:
        for (px, py) in ((x - 1, y_ - 1), (x + 1, y_ - 1), (x - 1, y_ + 1), (x + 1, y_ + 1)):
            img[py, px] = (255, 240, 160)
    return img


SPARKS = [(14, 96), (44, 112), (52, 94), (100, 46), (24, 44), (110, 70)]


def sparkles(img, t):
    for i, (sx, sy) in enumerate(SPARKS):
        k = (t + i * 3) % 12
        size = [0, 0, 0, 0, 0, 0, 1, 2, 3, 2, 1, 0][k]
        star(img, sx, sy, size)
    return img


def cursor(img, on):
    """the blinking block after ALL OF IT."""
    if on: img[106:114, 112:116] = INK
    return img


def reveal_rows(img, src, rows, x_to):
    """copy src into img in the rows, up to column x_to (typing / wiping)"""
    y0, y1 = rows
    img[y0:y1 + 1, :x_to] = src[y0:y1 + 1, :x_to]
    return img


BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]])


def dissolve(img, src, rows, t):
    """an ordered-dither dissolve: t from 0 to 1"""
    y0, y1 = rows
    yy, xx = np.mgrid[y0:y1 + 1, 0:G]
    m = (BAYER[yy % 4, xx % 4] + 0.5) / 16 < t
    reg = img[y0:y1 + 1]; reg[m] = src[y0:y1 + 1][m]
    return img


def zoom_rects(base, frac_list):
    """the window's zoom: black outline rectangles from the centre to the window, one per fraction"""
    img = base.copy()
    cx, cy = (WIN[0] + WIN[2]) / 2, (WIN[1] + WIN[3]) / 2
    for f in frac_list:
        x0 = int(round(cx + (WIN[0] - cx) * f)); x1 = int(round(cx + (WIN[2] - cx) * f))
        y0 = int(round(cy + (WIN[1] - cy) * f)); y1 = int(round(cy + (WIN[3] - cy) * f))
        img[y0, x0:x1 + 1] = INK; img[y1, x0:x1 + 1] = INK; img[y0:y1 + 1, x0] = INK; img[y0:y1 + 1, x1] = INK
    return img


# ------------------------------------------------------------------ the frames: (image, ms)
frames = []
def add(img, ms): frames.append((img.copy(), ms))

add(FINAL, 1400)                                                     # 1: the still itself
off, t = 0, 0
for i in range(30):                                                  # the hold
    img = FINAL.copy(); off += 1; t += 1
    tape(img, off); cycle_1993(img, i); sparkles(img, t); cursor(img, (i // 4) % 2 == 0)
    add(img, 90)
for f in ([1.0, 0.8, 0.6], [0.7, 0.5, 0.3], [0.4, 0.2, 0.08]):        # the window closes
    img = zoom_rects(DESK, f); tape(img, off); off += 1; add(img, 70)
img = DESK.copy(); tape(img, off); add(img, 260)
for f in ([0.08, 0.2, 0.4], [0.3, 0.5, 0.7], [0.6, 0.8, 1.0]):        # and opens again
    img = zoom_rects(DESK, f); tape(img, off); off += 1; add(img, 70)
page = EMPTY.copy(); tape(page, off); add(page, 160)
for i in range(1, 9):                                                # the green band wipes across, then the words type
    page = page.copy(); x = int(7 + 113 * i / 8)
    page[ROWS["band"][0]:ROWS["band"][1] + 1, 7:x] = FINAL[ROWS["band"][0]:ROWS["band"][1] + 1, 7:x]
    page[ROWS["year"][0]:ROWS["year"][1] + 1, 7:x] = FINAL[27 + 0:27 + 0, 7:x] if False else page[ROWS["year"][0]:ROWS["year"][1] + 1, 7:x]
    # the band only, no letters yet: paint the band's green over the letters' rows
    band_green = FINAL[28, 8]
    page[ROWS["year"][0]:ROWS["year"][1] + 1, 7:x] = band_green
    tape(page, off); off += 1; add(page, 50)
xs = [c for c in range(G) if (FINAL[30:37, c] == 255).all(axis=-1).any()]
x_start, x_end = min(xs), max(xs) + 1
for x in range(x_start, x_end + 6, 6):                               # THE YEAR IS: typed, a block cursor ahead of it
    page = page.copy(); reveal_rows(page, FINAL, ROWS["year"], min(x, x_end))
    img = page.copy()
    if x < x_end: img[30:37, x:x + 4] = (255, 255, 255)
    tape(img, off); off += 1; add(img, 70)
digits = [(15, 37), (39, 61), (63, 85), (87, 112)]                    # 1993: each digit stamps in
for k, (a, b) in enumerate(digits):
    for step, ms in ((0, 60), (1, 110)):
        img = page.copy()
        y0, y1 = ROWS["1993"]
        if step == 0:                                                # a white flash where it lands
            mask = np.any(FINAL[y0:y1 + 1, a:b] != np.array(YEL), axis=-1)
            reg = img[y0:y1 + 1, a:b]; reg[mask] = (255, 255, 255)
        else:
            page[y0:y1 + 1, a:b] = FINAL[y0:y1 + 1, a:b]; img = page.copy()
        tape(img, off); off += 1; add(img, ms)
for i in range(1, 9):                                                # the blue lines dither in
    img = page.copy()
    dissolve(img, FINAL, ROWS["blue1"], i / 8); dissolve(img, FINAL, ROWS["blue2"], max(0, (i - 1) / 7))
    tape(img, off); off += 1; add(img, 60)
page = img.copy()
page[ROWS["blue1"][0]:ROWS["blue2"][1] + 1] = FINAL[ROWS["blue1"][0]:ROWS["blue2"][1] + 1]
img = page.copy(); y0, y1 = ROWS["all"]                              # ALL OF IT.: inverted for a beat, then slams in
mask = np.any(FINAL[y0:y1 + 1, 7:120] != np.array(YEL), axis=-1)
reg = img[y0:y1 + 1, 7:120]; reg[mask] = (255, 255, 255); tape(img, off); off += 1; add(img, 80)
img = page.copy(); reg = img[y0:y1 + 1, 7:120]; reg[mask] = INK; tape(img, off); off += 1; add(img, 80)
page[y0:y1 + 1] = FINAL[y0:y1 + 1]
for i in range(8):                                                   # and sparkles
    img = page.copy(); tape(img, off); off += 1; cycle_1993(img, i); sparkles(img, i * 2); add(img, 80)

# ------------------------------------------------------------------ the GIF: 512 x 512, one shared palette, looping
S = 4
pal_src = Image.fromarray(np.vstack([f for f, _ in frames[::3]] + [np.array([RAINBOW * 4], np.uint8).reshape(-1, 7, 3)[:1].repeat(1, 0).reshape(1, -1, 3).repeat(1, 0)[:, :G] if False else FINAL]).astype(np.uint8))
pal_img = pal_src.quantize(colors=64, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
imgs = [Image.fromarray(f.astype(np.uint8)).resize((G * S, G * S), Image.NEAREST).quantize(palette=pal_img, dither=Image.Dither.NONE)
        for f, _ in frames]
durs = [ms for _, ms in frames]
path = os.path.join(OUT, "thumb_1993_animated.gif")
imgs[0].save(path, save_all=True, append_images=imgs[1:], duration=durs, loop=0, optimize=False, disposal=1)
print(len(imgs), "frames,", sum(durs) / 1000, "s,", os.path.getsize(path) // 1024, "KB")
# a contact sheet of every 6th frame to look at
sheet = Image.new("RGB", (8 * 130, ((len(frames) + 47) // 48) * 130 + 10), (20, 20, 20))
for i, (f, _) in enumerate(frames[::6]):
    sheet.paste(Image.fromarray(f.astype(np.uint8)), ((i % 8) * 130, (i // 8) * 130))
sheet = sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST)
sheet.save(os.path.join(OUT, "thumb_1993_animated_frames.png"))
