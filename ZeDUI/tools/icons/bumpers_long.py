# ZeDUI/tools/icons/bumpers_long.py  (Nov 2 2026, the director's sketches for the controller map)
# Lengthens the controller map's bumpers (LB, RB) outward in 42/media/textures/ZeD/controller_map.png, straight, until
# each outer end meets the start of the curve of the pad's body (the director's second mark: the bumpers do not bend
# down over the shoulders). Run on the ORIGINAL art (git show 5c3705df:42/media/textures/ZeD/controller_map.png).
# The art is drawn in 4 x 4 pixel cells. The new length is the bumper's own columns (the same dot phase); the outer
# ends are the bumpers' own ends moved out: LB's rounded light left end for LB, LB's shaded right end (its outline and
# drop shadow) for RB. The triggers above stay; their lower part goes behind the longer bumpers.
# Run: py -3 -I bumpers_long.py <original.png> <out.png>
import sys
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")
W, H = im.size
C = 4
CW, CH = W // C, H // C
orig = [[im.getpixel((cx * C + 1, cy * C + 1)) for cy in range(CH)] for cx in range(CW)]
EMPTY = (0, 0, 0, 0)

# ---- the triggers (with their LT / RT labels) nudged in toward the middle by NUDGE cells (the director, Nov 2 2026:
# "nudge those like 3 pixels in"). Only the rows above the bumpers move (14 to 30); below, the bumpers cover them.
NUDGE = 3
def move_block(x0, x1, dx):
    block = {(cx, cy): orig[cx][cy] for cx in range(x0, x1 + 1) for cy in range(14, 31)}
    for (cx, cy) in block: orig[cx][cy] = EMPTY
    for (cx, cy), c in block.items():
        if c != EMPTY: orig[cx + dx][cy] = c
move_block(26, 60, NUDGE)       # LT and its label (the LB label starts at cell 64)
move_block(139, 173, -NUDGE)    # RT and its label (the RB label ends at cell 137)
grid = [col[:] for col in orig]
BUMPER = {(250, 245, 232, 255), (206, 197, 174, 255), (172, 162, 138, 255)}   # its light edge, fill and dots
TOP, BOT = 31, 37          # the bumpers' rows (cells)

def tmpl(cx, lo, hi): return next(t for t in range(lo, hi + 1) if t % 4 == cx % 4)

def fill(cols, lo, hi):
    for cx in cols:
        tc = tmpl(cx, lo, hi)
        for r in range(TOP, BOT + 1):
            grid[cx][r] = orig[tc][r]

# ---- LB: straight out to cell 30 (the body's flat top starts at 28; its curve begins there)
SHIFT_L = -12              # (a multiple of 4: the dots keep their phase)
fill(range(30 + 0, 48), 50, 61)
for r in range(TOP, BOT + 1):
    start = next(cx for cx in range(40, 50) if orig[cx][r] in BUMPER)   # LB's own left end in this row
    ns = start + SHIFT_L
    for cx in range(26, ns):
        grid[cx][r] = EMPTY                 # left of the new end: empty (the trigger now starts right of it)
    for k in range(0, 4):
        grid[ns + k][r] = orig[start + k][r]   # the rounded light end, moved out

# ---- RB: straight out to the body's right end (cell 171), with LB's shaded right end as its outer end
SHIFT_R = 96               # LB's right end (cells 70 to 77) lands at 166 to 173
fill(range(150, 176), 130, 141)
for r in range(TOP, BOT + 1):
    end = max(cx for cx in range(60, 80) if orig[cx][r] in BUMPER)      # LB's own right end in this row
    ne = end + SHIFT_R
    for k in range(-3, 3):
        grid[ne + k][r] = orig[end + k][r]     # the shaded end, its outline and shadow, moved out
    for cx in range(ne + 3, 178):
        grid[cx][r] = EMPTY                    # past it: empty

out = Image.new("RGBA", (W, H), EMPTY)
px = out.load()
opx = im.load()
for cx in range(CW):
    for cy in range(CH):
        same = grid[cx][cy] == im.getpixel((cx * C + 1, cy * C + 1))   # (unchanged from the file: keep its pixels)
        for dx in range(C):
            for dy in range(C):
                px[cx * C + dx, cy * C + dy] = opx[cx * C + dx, cy * C + dy] if same else grid[cx][cy]
out.save(dst)
print("written", dst)
