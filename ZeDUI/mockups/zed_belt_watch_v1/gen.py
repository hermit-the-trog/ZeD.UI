# ZeDUI/mockups/zed_belt_watch_v1/gen.py  (Oct 19 2026)
# The mini watch on the belt: pixel-art sprites at belt scale (one texel a
# design unit, like the strap and the buckle) and the full plates with a time
# drawn on them for the pop-out. Writes PNGs next to this file; the page
# (index.html) puts them on an HTML belt.
#   py gen.py
import math, os, shutil
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
TEX = os.path.join(HERE, "..", "..", "..", "42", "media", "textures", "ZeD")
OUT = os.path.join(HERE, "img")
os.makedirs(OUT, exist_ok=True)

def hexc(h, a=255):
    h = h.lstrip("#"); return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

# --- seven-segment digits ----------------------------------------------------
SEG = {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd",
       "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg"}

def digit(d, x, y, w, h, t, fg, dim=None):
    """A seven-segment digit, w x h, segments t thick; dim paints the unlit ones."""
    m = (h - 1) // 2
    segs = {"a": (x + t, y, x + w - 1 - t, y + t - 1), "d": (x + t, y + h - t, x + w - 1 - t, y + h - 1),
            "g": (x + t, y + m - t // 2, x + w - 1 - t, y + m - t // 2 + t - 1),
            "f": (x, y + t, x + t - 1, y + m - 1), "b": (x + w - t, y + t, x + w - 1, y + m - 1),
            "e": (x, y + m + 1, x + t - 1, y + h - 1 - t), "c": (x + w - t, y + m + 1, x + w - 1, y + h - 1 - t)}
    for s, r in segs.items():
        on = s in SEG[d]
        if on or dim:
            D.rectangle(r, fill=fg if on else dim)

def time_str(img, s, x, y, w, h, t, gap, fg, dim=None, colon=True):
    global D
    D = ImageDraw.Draw(img)
    cx = x
    for i, ch in enumerate(s):
        if ch == ":":
            if colon:
                D.rectangle((cx, y + h // 3 - t // 2, cx + t - 1, y + h // 3 - t // 2 + t - 1), fill=fg)
                D.rectangle((cx, y + 2 * h // 3 - t // 2, cx + t - 1, y + 2 * h // 3 - t // 2 + t - 1), fill=fg)
            cx += t + gap
        elif ch == " ":
            cx += w + gap
        else:
            digit(ch, cx, y, w, h, t, fg, dim)
            cx += w + gap
    return cx

def str_w(s, w, t, gap):
    return sum((t + gap) if c == ":" else (w + gap) for c in s) - gap

# --- 3x5 letters for the brand on the mini case ------------------------------
F35 = {"C": ["111", "100", "100", "100", "111"], "A": ["010", "101", "111", "101", "101"],
       "Z": ["111", "001", "010", "100", "111"], "I": ["111", "010", "010", "010", "111"],
       "O": ["111", "101", "101", "101", "111"]}

def text35(img, s, x, y, c):
    d = ImageDraw.Draw(img)
    for ch in s:
        for r, row in enumerate(F35[ch]):
            for k, b in enumerate(row):
                if b == "1": d.point((x + k, y + r), fill=c)
        x += 4

# =============================================================================
# CaZio mini: 44 x 46. Rubber band stubs, octagonal black case with the gold
# line, CAZIO, the LCD (time + three speed pips), a pusher on each side.
# =============================================================================
def cazio_mini(hhmm="10:42", speed=1, paused=False, night=False, armed=True):
    W, H = 44, 46
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # band stubs (ridged rubber)
    for y in list(range(0, 6)) + list(range(40, 46)):
        d.line((12, y, 31, y), fill=hexc("#1c1c1c") if y % 2 == 0 else hexc("#2a2a2a"))
    d.line((12, 0, 12, 5), fill=hexc("#0c0c0c")); d.line((31, 0, 31, 5), fill=hexc("#0c0c0c"))
    d.line((12, 40, 12, 45), fill=hexc("#0c0c0c")); d.line((31, 40, 31, 45), fill=hexc("#0c0c0c"))
    # pushers (drawn first, the case covers their inner ends)
    for (x0, x1) in ((0, 3), (40, 43)):
        d.rectangle((x0, 19, x1, 26), fill=hexc("#8e8e8e"))
        d.line((x0, 19, x1, 19), fill=hexc("#cfcfcf"))
        d.line((x0, 26, x1, 26), fill=hexc("#4a4a4a"))
    # case: octagon x 2..41, y 6..39, corners cut 4
    c = 4
    poly = [(2 + c, 6), (41 - c, 6), (41, 6 + c), (41, 39 - c), (41 - c, 39), (2 + c, 39), (2, 39 - c), (2, 6 + c)]
    d.polygon(poly, fill=hexc("#141414"), outline=hexc("#050505"))
    d.line((2 + c, 7, 41 - c, 7), fill=hexc("#3c3c3c"))          # top light
    d.line((3, 6 + c, 3, 39 - c), fill=hexc("#2e2e2e"))          # left light
    gold = hexc("#8a7330") if night else hexc("#c9a640")
    inner = [(5 + 2, 9), (38 - 2, 9), (38, 9 + 2), (38, 36 - 2), (38 - 2, 36), (5 + 2, 36), (5, 36 - 2), (5, 9 + 2)]
    d.polygon(inner, outline=gold)
    text35(im, "CAZIO", 12, 11, gold)
    # LCD
    lx0, ly0, lx1, ly1 = 8, 18, 35, 33
    d.rectangle((lx0, ly0, lx1, ly1), fill=hexc("#0a0a0a"), outline=hexc("#2a2a2a"))
    fg = hexc("#8c8c8c") if night else hexc("#e8e8e8")
    dim = hexc("#161616")
    w, h, t, gap = 4, 7, 1, 1
    s = hhmm
    tw = str_w(s, w, t, gap)
    time_str(im, s, lx0 + (lx1 - lx0 + 1 - tw) // 2, ly0 + 3, w, h, t, gap, fg)
    d = ImageDraw.Draw(im)
    # alarm armed: a dot top-left of the LCD
    if armed: d.point((lx0 + 2, ly0 + 2), fill=hexc("#d03030"))
    # speed pips under the time: lit up to the speed; hollow when paused
    for i in range(3):
        px = lx0 + 9 + i * 4
        if paused:
            d.point((px, ly1 - 3), fill=fg); d.point((px + 1, ly1 - 3), fill=dim)
        else:
            col = fg if i < speed else dim
            d.line((px, ly1 - 3, px + 1, ly1 - 3), fill=col)
    # the run mark (the full watch's green light) on the case, by the speed pusher
    if not paused: d.point((5, 30), fill=hexc("#44ee44") if not night else hexc("#2a8a2a"))
    return im

# =============================================================================
# Timez Easy Reader mini: 44 x 46. Brown leather stubs, steel round case, cream
# dial with hands, the crown (light) at 3, START at 4, SPEED at 8.
# =============================================================================
def timez_mini(h=10, m=42, night=False, lit=False):
    W, H = 44, 46
    S = 4                                    # supersample the round parts, then snap to a palette
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    leather, edge, stitch = hexc("#5a3a1e"), hexc("#3a2512"), hexc("#a8865a")
    for y0, y1 in ((0, 7), (39, 45)):
        d.rectangle((14, y0, 29, y1), fill=leather)
        d.line((14, y0, 14, y1), fill=edge); d.line((29, y0, 29, y1), fill=edge)
        for y in range(y0 + 1, y1, 2):
            d.point((16, y), fill=stitch); d.point((27, y), fill=stitch)
    cx, cy, R = 21.5, 23, 17.5
    steel, steel_hi, steel_lo = hexc("#7c8086"), hexc("#c9ccd0"), hexc("#4a4c50")
    dial = hexc("#52d0c2") if lit else (hexc("#7a766a") if night else hexc("#e6dfc6"))
    goldring = hexc("#cdbc8b") if not night else hexc("#6a6250")
    ink = hexc("#1e2022") if not lit else hexc("#0d3a36")
    # pushers at 4 and 8, the crown at 3
    def at(angle_deg, r):
        a = math.radians(angle_deg - 90)
        return cx + r * math.cos(a), cy + r * math.sin(a)
    for ang in (120, 240):                    # 4 o'clock, 8 o'clock
        x, y = at(ang, R + 1)
        d.rectangle((round(x) - 1, round(y) - 1, round(x) + 1, round(y) + 1), fill=hexc("#8e9298"))
    d.rectangle((39, 21, 43, 25), fill=hexc("#8e9298")); d.line((39, 21, 43, 21), fill=steel_hi)
    d.line((43, 21, 43, 25), fill=steel_lo)
    # the round case, pixel by pixel
    for y in range(H):
        for x in range(W):
            r = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if r <= R:
                if r > R - 3:
                    # steel bezel: lit from the top-left
                    lt = ((x + 0.5 - cx) + (y + 0.5 - cy)) / R
                    col = steel_hi if lt < -0.75 else (steel_lo if lt > 0.75 else steel)
                    if r > R - 0.9: col = hexc("#2c2e31")
                elif r > R - 4: col = goldring
                else: col = dial
                im.putpixel((x, y), col)
    # hour markers
    for k in range(12):
        x, y = at(k * 30, R - 6)
        X, Y = int(x), int(y)
        if k % 3 == 0:
            im.putpixel((X, Y), ink); im.putpixel((X, Y + (1 if k in (0, 6) else 0)), ink)
            if k in (3, 9): im.putpixel((X + (1 if k == 9 else -1), Y), ink)
        else:
            im.putpixel((X, Y), hexc("#8a8270") if not lit else hexc("#2a7a72"))
    # hands
    def hand(angle, length, col, width=1):
        x, y = at(angle, length)
        d.line((cx - 0.5, cy - 0.5, x - 0.5, y - 0.5), fill=col, width=width)
    hand((h % 12 + m / 60) * 30, 7, ink, 2)
    hand(m * 6, 11, ink, 1)
    d.point((int(cx), int(cy)), fill=hexc("#b02020"))
    return im

# =============================================================================
# The full plates with a time on them (the pop-out)
# =============================================================================
def cazio_full(hhmm="10:42"):
    im = Image.open(os.path.join(TEX, "physpx", "digital_black.png")).convert("RGBA")
    # lcd x 20 y 48 w 84 h 34; time centred on x 56, y 59 (size 17)
    w, h, t, gap = 9, 17, 2, 2
    tw = str_w(hhmm, w, t, gap)
    time_str(im, hhmm, 58 - tw // 2, 58, w, h, t, gap, hexc("#e8e8e8"), hexc("#161616"))
    d = ImageDraw.Draw(im)
    d.point((19, 130), fill=hexc("#44ee44")); d.point((20, 130), fill=hexc("#44ee44"))
    return im

def timez_full(h=10, m=42):
    im = Image.open(os.path.join(TEX, "physpx", "timez_easy.png")).convert("RGBA")
    W, H = im.size
    xs, ys = [], []
    for y in range(H):
        for x in range(W):
            if im.getpixel((x, y))[:3] == (230, 223, 198): xs.append(x); ys.append(y)
    cx, cy = (min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2
    d = ImageDraw.Draw(im)
    def hand(angle, length, width, col):
        a = math.radians(angle - 90)
        d.line((cx, cy, cx + length * math.cos(a), cy + length * math.sin(a)), fill=col, width=width)
    hand((h % 12 + m / 60) * 30, 18, 3, hexc("#1e2022"))
    hand(m * 6, 28, 2, hexc("#1e2022"))
    d.ellipse((cx - 2, cy - 2, cx + 1, cy + 1), fill=hexc("#b02020"))
    return im

def save(im, name): im.save(os.path.join(OUT, name))

save(cazio_mini(), "mini_cazio.png")
save(cazio_mini(speed=3), "mini_cazio_x3.png")
save(cazio_mini(paused=True), "mini_cazio_paused.png")
save(cazio_mini(night=True), "mini_cazio_night.png")
save(timez_mini(), "mini_timez.png")
save(timez_mini(night=True), "mini_timez_night.png")
save(timez_mini(lit=True), "mini_timez_lit.png")
save(cazio_full(), "full_cazio.png")
save(timez_full(), "full_timez.png")
for src, dst in (("belt/strap_l.png", "strap_l.png"), ("belt/strap_mid.png", "strap_mid.png"),
                 ("belt/strap_r.png", "strap_r.png"), ("belt/pack_mid.png", "pack_mid.png"),
                 ("buckles/buckle_unemployed.png", "buckle.png")):
    shutil.copy(os.path.join(TEX, src), os.path.join(OUT, dst))

# a contact sheet at 6x for checking the sprites
names = ["mini_cazio", "mini_cazio_x3", "mini_cazio_paused", "mini_cazio_night", "mini_timez", "mini_timez_night", "mini_timez_lit"]
sheet = Image.new("RGBA", (len(names) * 50, 52), (46, 52, 40, 255))
for i, n in enumerate(names):
    s = Image.open(os.path.join(OUT, n + ".png")); sheet.paste(s, (i * 50 + 3, 3), s)
sheet.resize((sheet.width * 6, sheet.height * 6), Image.NEAREST).save(os.path.join(HERE, "sheet.png"))
print("ok")

# a single self-contained page (the app's browser opens local pages as snapshots,
# so relative images do not load): index.html -> zed_belt_watch_v1.html
import base64, re
page = open(os.path.join(HERE, "index.html"), encoding="utf-8").read()
def inline(m):
    with open(os.path.join(HERE, m.group(1)), "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()
page = re.sub(r"(img/[\w]+\.png)", inline, page)
open(os.path.join(HERE, "..", "zed_belt_watch_v1.html"), "w", encoding="utf-8").write(page)
print("built")
