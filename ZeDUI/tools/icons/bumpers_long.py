# ZeDUI/tools/icons/bumpers_long.py  (Nov 2 2026, the director's sketch for the controller map)
# Lengthens the controller map's bumpers (LB, RB) outward along the pad's shoulders in
# 42/media/textures/ZeD/controller_map.png, so each one's outer end follows the curve of the pad's body.
# The art is drawn in 4 x 4 pixel cells. Each new bumper column is a copy of a column of that bumper (the same dot
# phase), lowered so it sits on the body's top edge there; the outer end takes the bumper's own end look (a light edge
# on the left, a shaded edge and dark outline on the right). The triggers above stay; their lower part goes behind
# the longer bumper, as on a real pad.
# Run: py -3 -I bumpers_long.py <in.png> <out.png>
import sys
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")
W, H = im.size
C = 4
CW, CH = W // C, H // C
grid = [[im.getpixel((cx * C + 1, cy * C + 1)) for cy in range(CH)] for cx in range(CW)]
EMPTY = (0, 0, 0, 0)
LIGHT, SHADE, OUTLINE = (250, 245, 232, 255), (172, 162, 138, 255), (124, 115, 96, 255)
BODY = {(228, 220, 200, 255), (206, 197, 174, 255), (250, 245, 232, 255), (172, 162, 138, 255), (124, 115, 96, 255)}
TOP, BOT = 31, 37          # the bumpers' rows (cells)
FLAT = 38                  # the body's top edge where it is flat

def body_top(cx):
    # the first cell of the body in this column, from the flat top down
    for cy in range(FLAT, CH):
        if grid[cx][cy] != EMPTY and grid[cx][cy] in BODY:
            return cy
    return None

def extend(cols, tmpl_lo, tmpl_hi, outer):
    """cols: the columns to (re)draw, inner to outer; templates from [tmpl_lo, tmpl_hi]; outer: -1 left, +1 right"""
    new = {}
    for cx in cols:
        bt = body_top(cx)
        if bt is None:
            continue
        s = bt - FLAT
        tc = next(t for t in range(tmpl_lo, tmpl_hi + 1) if t % 4 == cx % 4)
        for r in range(TOP, BOT + 1):
            new[(cx, r + s)] = grid[tc][r]
        # the seam under the bumper: one light line, as under its flat part (the right shoulder's dark outline
        # goes to the bumper's outer end instead)
        if grid[cx][bt] == OUTLINE:
            grid[cx][bt] = LIGHT
    for (cx, cy), c in new.items():
        grid[cx][cy] = c
    # the outer end: per row, the outermost new cell
    rows = {}
    for (cx, cy) in new:
        if cy not in rows or (cx - rows[cy]) * outer > 0:
            rows[cy] = cx
    for cy, cx in rows.items():
        bottom = (cx, cy + 1) not in new
        if outer < 0:
            grid[cx][cy] = SHADE if bottom else LIGHT
        else:
            grid[cx][cy] = SHADE
            nx = cx + 1
            if nx < CW and (nx, cy) not in new and grid[nx][cy] not in BODY - {OUTLINE}:
                grid[nx][cy] = OUTLINE
    return new

# LB: from its old left end (cell 47) out to the shoulder (cell 18); its dots copied from cells 50 to 61
extend(range(47, 17, -1), 50, 61, -1)
# RB: mirrored, from cell 152 out to cell 181; its dots copied from cells 130 to 141
extend(range(152, 182), 130, 141, +1)

out = Image.new("RGBA", (W, H), EMPTY)
px = out.load()
for cx in range(CW):
    for cy in range(CH):
        c = grid[cx][cy]
        for dx in range(C):
            for dy in range(C):
                px[cx * C + dx, cy * C + dy] = c
# keep anything the cells cannot hold (sub-cell detail) where the cells did not change
orig = im.load()
for cx in range(CW):
    for cy in range(CH):
        if grid[cx][cy] == im.getpixel((cx * C + 1, cy * C + 1)):
            for dx in range(C):
                for dy in range(C):
                    px[cx * C + dx, cy * C + dy] = orig[cx * C + dx, cy * C + dy]
out.save(dst)
print("written", dst)
