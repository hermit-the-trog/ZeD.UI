# ZeDUI/tools/physpx/d_miniwatch.py  (Oct 19 2026)
# The mini watches that sit on the belt (ZeD/WatchMini.lua), one per watch
# plate: 44 x 46 texels, one texel a design unit like the strap and buckle.
# Two cases: the digital octagon (CaZio, Timez digital) and the round
# analogue (CaZio classic, Timez Easy Reader / Camper, Rollex). The time is
# NOT in the art: the game draws the digits and hands live over the blank
# LCD or dial (WatchMini.lua holds the same geometry).
#   py d_miniwatch.py   -> 42/media/textures/ZeD/physpx/mini/<plate>[_night|_lit].png
import math, os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "42", "media", "textures", "ZeD", "physpx", "mini")
os.makedirs(OUT, exist_ok=True)
W, H = 44, 46

def c(h, a=255):
    h = h.lstrip("#"); return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

F35 = {"C": ["111", "100", "100", "100", "111"], "A": ["010", "101", "111", "101", "101"],
       "Z": ["111", "001", "010", "100", "111"], "I": ["111", "010", "010", "010", "111"],
       "O": ["111", "101", "101", "101", "111"], "T": ["111", "010", "010", "010", "010"],
       "M": ["10001", "11011", "10101", "10001", "10001"], "E": ["111", "100", "110", "100", "111"]}

def text35(im, s, x, y, col):
    d = ImageDraw.Draw(im)
    for ch in s:
        for r, row in enumerate(F35[ch]):
            for k, b in enumerate(row):
                if b == "1": d.point((x + k, y + r), fill=col)
        x += len(F35[ch][0]) + 1

# --- bands: the stubs above and below the case (x0..x1, rows y0..y1) --------
def band(im, kind, x0, x1, rows, cols):
    d = ImageDraw.Draw(im)
    for (y0, y1) in rows:
        for y in range(y0, y1 + 1):
            if kind == "rubber":
                d.line((x0, y, x1, y), fill=cols[0] if y % 2 == 0 else cols[1])
            elif kind == "bracelet":            # links: two rows a link, a seam down the middle
                d.line((x0, y, x1, y), fill=cols[0] if (y // 2) % 2 == 0 else cols[1])
                d.point(((x0 + x1) // 2, y), fill=cols[2])
            elif kind == "nylon":               # olive with a centre stripe
                d.line((x0, y, x1, y), fill=cols[0])
                m = (x0 + x1) // 2
                d.line((m - 2, y, m + 1, y), fill=cols[1])
            elif kind == "leather":
                d.line((x0, y, x1, y), fill=cols[0])
                if y % 2 == 1: d.point((x0 + 2, y), fill=cols[2]); d.point((x1 - 2, y), fill=cols[2])
        d.line((x0, y0, x0, y1), fill=cols[-1]); d.line((x1, y0, x1, y1), fill=cols[-1])

# =============================================================================
# DIGITAL: octagon x 2..41, y 6..39; LCD x 8..35, y 18..33 (WatchMini.lua)
# =============================================================================
def digital(p, lit=False):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    band(im, p["band"], 12, 31, ((0, 5), (40, 45)), p["bandCols"])
    for (x0, x1) in ((0, 3), (40, 43)):                  # side pushers
        d.rectangle((x0, 19, x1, 26), fill=c("#8e8e8e"))
        d.line((x0, 19, x1, 19), fill=c("#cfcfcf")); d.line((x0, 26, x1, 26), fill=c("#4a4a4a"))
    k = 4
    poly = [(2 + k, 6), (41 - k, 6), (41, 6 + k), (41, 39 - k), (41 - k, 39), (2 + k, 39), (2, 39 - k), (2, 6 + k)]
    d.polygon(poly, fill=c(p["case"]), outline=c(p["caseLo"]))
    d.line((2 + k, 7, 41 - k, 7), fill=c(p["caseHi"]))
    d.line((3, 6 + k, 3, 39 - k), fill=c(p["caseHi"]))
    d.line((40, 6 + k, 40, 39 - k), fill=c(p["caseLo"]))
    if p.get("screws"):
        for (sx, sy) in ((4, 8), (39, 8), (4, 37), (39, 37)): d.point((sx, sy), fill=c("#9a9a9a"))
    inner = [(7, 9), (36, 9), (38, 11), (38, 34), (36, 36), (7, 36), (5, 34), (5, 11)]
    d.polygon(inner, fill=c(p.get("face", p["case"])), outline=c(p["line"]))
    tw = sum(len(F35[ch][0]) + 1 for ch in p["brand"]) - 1
    text35(im, p["brand"], 22 - tw // 2, 11, c(p["brandCol"]))
    d = ImageDraw.Draw(im)
    d.rectangle((8, 18, 35, 33), fill=c("#52d0c2") if lit else c(p["lcd"]), outline=c(p["lcdEdge"]))
    return im

# =============================================================================
# ANALOGUE: round case centre (21.5, 23) radius 17.5; dial inside r 13.5
# =============================================================================
def analog(p, lit=False):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    band(im, p["band"], 14, 29, ((0, 7), (39, 45)), p["bandCols"])
    cx, cy, R = 21.5, 23, 17.5
    def at(ang, r):
        a = math.radians(ang - 90); return cx + r * math.cos(a), cy + r * math.sin(a)
    for ang in (120, 240):                                 # START at 4, SPEED at 8
        x, y = at(ang, R + 1)
        d.rectangle((round(x) - 1, round(y) - 1, round(x) + 1, round(y) + 1), fill=c(p["push"]))
    d.rectangle((39, 21, 43, 25), fill=c(p["push"]))       # the crown at 3
    d.line((39, 21, 43, 21), fill=c(p["ringHi"])); d.line((43, 21, 43, 25), fill=c(p["ringLo"]))
    dial = c("#52d0c2") if lit else c(p["dial"])
    for y in range(H):
        for x in range(W):
            r = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if r <= R:
                if r > R - 3:
                    lt = ((x + 0.5 - cx) + (y + 0.5 - cy)) / R
                    col = c(p["ringHi"]) if lt < -0.75 else (c(p["ringLo"]) if lt > 0.75 else c(p["ring"]))
                    if r > R - 0.9: col = c(p["edge"])
                elif r > R - 4: col = c(p["inner"])
                else: col = dial
                im.putpixel((x, y), col)
    ink = c(p["ink"]) if not lit else c("#0d3a36")
    for k in range(12):
        x, y = at(k * 30, R - 6)
        X, Y = int(x), int(y)
        if k % 3 == 0:
            im.putpixel((X, Y), ink); im.putpixel((X, Y + (1 if k in (0, 6) else 0)), ink)
            if k in (3, 9): im.putpixel((X + (1 if k == 9 else -1), Y), ink)
        else:
            im.putpixel((X, Y), c(p["tick"]) if not lit else c("#2a7a72"))
    return im

# --- a CaZio's bulb (Oct 21 2026): a 1 x 2 speck at the display's (or the dial's) left edge; pressed, the glass goes a
# little warmer and lighter by it, fading across in three dithered steps (the full watch's look, d_watches.bulb)
BAYER4 = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))
BULB_LIGHT = (255, 200, 90)
BULB_DAY_TINT = (236, 214, 130)
BULB_DOT = ("#e2c25e", "#bf9a3e")
BULB_AT = {"digital": (9, 24, 22.0), "analog": (9, 25, 16.0)}     # the speck's top texel and the light's reach

def bulb_pool(im, kind, inside, night_, neg):
    """warm the texels for which inside(x, y) holds, by the bulb; im is the day or the night picture"""
    bx, by, reach = BULB_AT[kind]
    cx, cy = bx + 0.5, by + 1.0
    R = reach if night_ else reach * 0.6
    top = 3.4 if night_ else 2.6
    steps = ((0.03, 0.05, 0.08) if neg else (0.06, 0.11, 0.17)) if night_ else ((0.02, 0.04, 0.06) if neg else (0.04, 0.07, 0.11))
    px = im.load()
    for y in range(H):
        for x in range(W):
            if not inside(x, y): continue
            dx, dy = x + 0.5 - cx, (y + 0.5 - cy) * 1.2
            th = math.atan2(dy, dx)
            r = math.hypot(dx, dy) / (1.0 + 0.16 * math.sin(2.0 * th + 0.6) + 0.08 * math.cos(5.0 * th + 1.3))
            inten = top * max(0.0, 1.0 - r / R) ** 1.3
            lev = min(3, int(math.floor(inten + BAYER4[y % 4][x % 4] / 16.0)))
            if lev <= 0: continue
            t = steps[lev - 1]
            r0, g0, b0, a = px[x, y]
            if night_: col = [min(255, round(v + l * t)) for v, l in zip((r0, g0, b0), BULB_LIGHT)]
            else: col = [round(v + (d - v) * t) for v, d in zip((r0, g0, b0), BULB_DAY_TINT)]
            px[x, y] = (col[0], col[1], col[2], a)
    px[bx, by] = c(BULB_DOT[0]); px[bx, by + 1] = c(BULB_DOT[1])
    return im

def bulb_off(im, kind, neg):
    bx, by, _ = BULB_AT[kind]
    px = im.load()
    for y in (by, by + 1):
        r0, g0, b0, a = px[bx, y]
        w = (70, 66, 56) if neg else (58, 52, 38)
        px[bx, y] = (round(r0 * 0.55 + w[0] * 0.45), round(g0 * 0.55 + w[1] * 0.45), round(b0 * 0.55 + w[2] * 0.45), a)

def glass_inside(p):
    if p["kind"] == "digital": return lambda x, y: 9 <= x <= 34 and 19 <= y <= 32
    return lambda x, y: math.hypot(x + 0.5 - 21.5, y + 0.5 - 23) <= 17.5 - 4

# --- night: the whole picture darker and a little blue (the plates' night look)
def night(im):
    out = im.copy(); px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a: px[x, y] = (int(r * 0.45), int(g * 0.47), int(b * 0.55), a)
    return out

RUBBER_BLACK = ["#1c1c1c", "#2a2a2a", "#0c0c0c"]
GOLD_LINK = ["#c9a33a", "#a8842a", "#6a5216", "#6a5216"]
STEEL_LINK = ["#a4a8ae", "#80848a", "#4a4e54", "#4a4e54"]
PLATES = {
    "digital_black": dict(kind="digital", case="#141414", caseHi="#3c3c3c", caseLo="#050505", line="#c9a640",
                          brand="CAZIO", brandCol="#c9a640", lcd="#b8bbb3", lcdEdge="#2a2a2a", band="rubber", bandCols=RUBBER_BLACK,
                          bulb=True),
    "digital_gold": dict(kind="digital", case="#c9a33a", caseHi="#ecd27a", caseLo="#6a5216", line="#8a6a1e", face="#b8922e",
                         brand="CAZIO", brandCol="#4a3a10", lcd="#b8bbb3", lcdEdge="#6a5216", band="bracelet", bandCols=GOLD_LINK,
                         bulb=True),
    "timez_red": dict(kind="digital", case="#b0242a", caseHi="#d85a5a", caseLo="#5a0c10", line="#101010", face="#141414",
                      brand="TIMEZ", brandCol="#f0f0f0", lcd="#b8bbb3", lcdEdge="#3a3a3a", band="rubber",
                      bandCols=["#a02028", "#7a1820", "#4a0c10"], screws=True, light=True),
    "timez_steel": dict(kind="digital", case="#8a8e94", caseHi="#c8ccd0", caseLo="#40444a", line="#101010", face="#141414",
                        brand="TIMEZ", brandCol="#f0f0f0", lcd="#b8bbb3", lcdEdge="#3a3a3a", band="bracelet", bandCols=STEEL_LINK,
                        screws=True, light=True),
    "classic_black": dict(kind="analog", ring="#2a2a2a", ringHi="#5a5a5a", ringLo="#101010", edge="#050505", inner="#3a3a3a",
                          dial="#161616", ink="#e8e8e8", tick="#8a8a8a", push="#8e9298", band="rubber", bandCols=RUBBER_BLACK,
                          bulb=True),
    "classic_gold": dict(kind="analog", ring="#c9a33a", ringHi="#ecd27a", ringLo="#6a5216", edge="#3a2c0a", inner="#b0902c",
                         dial="#e6dfc6", ink="#1e2022", tick="#8a8270", push="#c9a33a", band="bracelet", bandCols=GOLD_LINK,
                         bulb=True),
    "timez_easy": dict(kind="analog", ring="#7c8086", ringHi="#c9ccd0", ringLo="#4a4c50", edge="#2c2e31", inner="#cdbc8b",
                       dial="#e6dfc6", ink="#1e2022", tick="#8a8270", push="#8e9298", band="leather",
                       bandCols=["#5a3a1e", "#5a3a1e", "#a8865a", "#3a2512"], light=True),
    "timez_camper": dict(kind="analog", ring="#5a5e64", ringHi="#9a9ea4", ringLo="#33363a", edge="#1a1c1e", inner="#2a2a2a",
                         dial="#1a1c1a", ink="#f0f0f0", tick="#8a8a8a", push="#8e9298", band="nylon",
                         bandCols=["#4a5a2a", "#2a3a1a", "#2a3a1a"], light=True),
    "expensive": dict(kind="analog", ring="#c9a33a", ringHi="#ecd27a", ringLo="#6a5216", edge="#3a2c0a", inner="#e0c66a",
                      dial="#efeadb", ink="#2a2a2a", tick="#9a9280", push="#c9a33a", band="bracelet", bandCols=GOLD_LINK),
}

for name, p in PLATES.items():
    make = digital if p["kind"] == "digital" else analog
    day = make(p)
    if p.get("bulb"): bulb_off(day, p["kind"], p.get("neg"))
    day.save(os.path.join(OUT, name + ".png"))
    night(day).save(os.path.join(OUT, name + "_night.png"))
    if p.get("light"): make(p, lit=True).save(os.path.join(OUT, name + "_lit.png"))
    if p.get("bulb"):
        lit = make(p)
        bulb_pool(lit, p["kind"], glass_inside(p), False, p.get("neg")).save(os.path.join(OUT, name + "_bulb.png"))
        bulb_pool(night(make(p)), p["kind"], glass_inside(p), True, p.get("neg")).save(os.path.join(OUT, name + "_bulb_night.png"))

# a contact sheet for checking (not shipped)
names = list(PLATES)
SUF = ("", "_night", "_lit", "_bulb", "_bulb_night")
sheet = Image.new("RGBA", (len(names) * 50, len(SUF) * 52), (46, 52, 40, 255))
for i, n in enumerate(names):
    for j, suf in enumerate(SUF):
        f = os.path.join(OUT, n + suf + ".png")
        if os.path.exists(f):
            s = Image.open(f); sheet.paste(s, (i * 50 + 3, j * 52 + 3), s)
sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(os.path.join(HERE, "miniwatch_sheet.png"))
print("ok", len(names))
