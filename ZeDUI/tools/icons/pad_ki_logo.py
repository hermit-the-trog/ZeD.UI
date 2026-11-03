# ZeDUI/tools/icons/pad_ki_logo.py  (Nov 2 2026, the director: the controller map's pad wears the computer's maker)
# Replaces the red "ZeD" on the controller map's pad (42/media/textures/ZeD/controller_map.png) with the Kentucky
# Instruments mark from the desk's computer (ZeDUI/tools/mainmenu/gen_desk.py: ky_mark, the state, then "KI" in the
# desk's 3 x 5 letters): one art cell (4 x 4 pixels) per desk pixel, printed in the pad's dark trim colour, centred
# where the old logo sat. The old logo's cells take the pad's own dot texture back.
# Run: py -3 -I pad_ki_logo.py <in.png> <out.png>
import sys
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")
W, H = im.size
C = 4
px = im.load()
RED = {(200, 32, 42, 255), (132, 16, 24, 255)}
TEX = {(228, 220, 200, 255), (206, 197, 174, 255)}      # the pad's plastic and its dots
INK = (84, 77, 63, 255)                                # the pad's dark trim (the triggers' dots, the D-pad's shade)

# the mark, as gen_desk.py draws it: the state, two pixels gap, then K and I (gap 1); the letters one pixel lower
KY = ["........##..", "......#####.", "....#######.", "..##########", ".#########..", "##########.."]
FONT = {"I": ["111", "010", "010", "010", "111"], "K": ["101", "101", "110", "101", "101"]}
cells = set()
for ry, row in enumerate(KY):
    for rx, b in enumerate(row):
        if b == "#": cells.add((rx, ry))
x = len(KY[0]) + 2
for ch in "KI":
    for ry, row in enumerate(FONT[ch]):
        for rx, b in enumerate(row):
            if b == "1": cells.add((x + rx, 1 + ry))
    x += 3 + 1
mw = max(c[0] for c in cells) + 1
mh = max(c[1] for c in cells) + 1

def cell(cx, cy): return px[cx * C + 1, cy * C + 1]
def paint(cx, cy, col):
    for dx in range(C):
        for dy in range(C):
            px[cx * C + dx, cy * C + dy] = col

# 1. the old logo out: each red cell takes the texture of the nearest plain cell in its row with the same dot phase
LOGO = (84, 116, 42, 62)   # the old logo's area in cells (x0, x1, y0, y1): the B button is the same red, so look only here
red = [(cx, cy) for cx in range(LOGO[0], LOGO[1] + 1) for cy in range(LOGO[2], LOGO[3] + 1) if cell(cx, cy) in RED]
x0, x1 = min(c[0] for c in red), max(c[0] for c in red)
y0, y1 = min(c[1] for c in red), max(c[1] for c in red)
for (cx, cy) in red:
    for k in range(1, 20):
        found = None
        for sx in (cx + 4 * k, cx - 4 * k):
            if 0 <= sx < W // C and cell(sx, cy) in TEX: found = sx; break
        if found is not None:
            paint(cx, cy, cell(found, cy)); break

# 2. the KI mark, centred on the pad's middle, on the old logo's middle row
pad_mid = W // C // 2
ox = pad_mid - mw // 2
oy = (y0 + y1 + 1) // 2 - mh // 2
for (rx, ry) in cells:
    paint(ox + rx, oy + ry, INK)
im.save(dst)
print("old logo cells", x0, "-", x1, "x", y0, "-", y1, "| KI mark", mw, "x", mh, "at", ox, oy, "| written", dst)
