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
                          brand="CAZIO", brandCol="#c9a640", lcd="#0a0a0a", lcdEdge="#2a2a2a", band="rubber", bandCols=RUBBER_BLACK),
    "digital_gold": dict(kind="digital", case="#c9a33a", caseHi="#ecd27a", caseLo="#6a5216", line="#8a6a1e", face="#b8922e",
                         brand="CAZIO", brandCol="#4a3a10", lcd="#c8ccae", lcdEdge="#6a5216", band="bracelet", bandCols=GOLD_LINK),
    "timez_red": dict(kind="digital", case="#b0242a", caseHi="#d85a5a", caseLo="#5a0c10", line="#101010", face="#141414",
                      brand="TIMEZ", brandCol="#f0f0f0", lcd="#c8d0b0", lcdEdge="#3a3a3a", band="rubber",
                      bandCols=["#a02028", "#7a1820", "#4a0c10"], screws=True, light=True),
    "timez_steel": dict(kind="digital", case="#8a8e94", caseHi="#c8ccd0", caseLo="#40444a", line="#101010", face="#141414",
                        brand="TIMEZ", brandCol="#f0f0f0", lcd="#c8d0b0", lcdEdge="#3a3a3a", band="bracelet", bandCols=STEEL_LINK,
                        screws=True, light=True),
    "classic_black": dict(kind="analog", ring="#2a2a2a", ringHi="#5a5a5a", ringLo="#101010", edge="#050505", inner="#3a3a3a",
                          dial="#161616", ink="#e8e8e8", tick="#8a8a8a", push="#8e9298", band="rubber", bandCols=RUBBER_BLACK),
    "classic_gold": dict(kind="analog", ring="#c9a33a", ringHi="#ecd27a", ringLo="#6a5216", edge="#3a2c0a", inner="#b0902c",
                         dial="#e6dfc6", ink="#1e2022", tick="#8a8270", push="#c9a33a", band="bracelet", bandCols=GOLD_LINK),
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
    day.save(os.path.join(OUT, name + ".png"))
    night(day).save(os.path.join(OUT, name + "_night.png"))
    if p.get("light"): make(p, lit=True).save(os.path.join(OUT, name + "_lit.png"))

# a contact sheet for checking (not shipped)
names = list(PLATES)
sheet = Image.new("RGBA", (len(names) * 50, 3 * 52), (46, 52, 40, 255))
for i, n in enumerate(names):
    for j, suf in enumerate(("", "_night", "_lit")):
        f = os.path.join(OUT, n + suf + ".png")
        if os.path.exists(f):
            s = Image.open(f); sheet.paste(s, (i * 50 + 3, j * 52 + 3), s)
sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(os.path.join(HERE, "miniwatch_sheet.png"))
print("ok", len(names))
