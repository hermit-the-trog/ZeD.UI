"""Iron Mike's picture from the in-game capture (Nov 6 2026, the director: "in-game avatar that looks like this photo,
and then make it black and white"). The capture: the game's own 3D man doing the game's biceps curl (zedqa_iron_mike2.lua,
Spongie's muscle overlay, on green). Here it is keyed, cut down to the picture's size and printed the book's way: each
material (skin, cotton, hair, denim) on its own paper-to-ink ramp (adpx.RAMPS), stepped, no blending, no dithering,
lit hard from one side as in the reference. The game's dumbbell is drawn into his fist (a UI model holds nothing).

python mike_ink.py <capture.png> <out.png> [x0 y0 x1 y1] [W H]
"""
import sys
import numpy as np
from PIL import Image
import adpx                      # noqa: F401  (sets up the ink ramps)
from engine import RAMPS

src = sys.argv[1]
out = sys.argv[2]
box = tuple(int(v) for v in sys.argv[3:7]) if len(sys.argv) >= 7 else (1100, 230, 2700, 1900)
W, H = (int(sys.argv[7]), int(sys.argv[8])) if len(sys.argv) >= 9 else (112, 104)

a = np.asarray(Image.open(src).convert("RGB").crop(box)).astype(float) / 255.0
r, g, b = a[..., 0], a[..., 1], a[..., 2]
key = ((g > 0.45) & (g > r * 1.6) & (g > b * 1.6)) | (a.max(-1) < 0.06)   # green, or the black backdrop
alpha_hi = (~key).astype(float)

# material at full size: hair (dark), skin (warm), cotton (bright, grey), denim (blue)
lum = 0.30 * r + 0.59 * g + 0.11 * b
mx = a.max(-1); mn = a.min(-1)
sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
mat = np.full(lum.shape, 0, int)                  # 0 none
mat[(~key) & (sat < 0.22) & (abs(r - b) <= 0.025) & (lum > 0.2)] = 1   # cotton (any grey: lit or in shadow)
mat[(~key) & (sat >= 0.22) & (r > b + 0.08)] = 2   # skin
mat[(~key) & (lum < 0.22) & (r > b + 0.025)] = 3   # hair (brown; a shadow in the tee is grey)
mat[(~key) & (b > r + 0.05) & (mat == 0)] = 4      # denim
mat[(~key) & (mat == 0)] = 2

# down to the picture: area means of lum and alpha, the material by majority in each cell
def cells(arr, fn):
    h, w = arr.shape[:2]
    ys = np.linspace(0, h, H + 1).astype(int); xs = np.linspace(0, w, W + 1).astype(int)
    o = np.zeros((H, W))
    for j in range(H):
        for i in range(W):
            o[j, i] = fn(arr[ys[j]:ys[j + 1], xs[i]:xs[i + 1]])
    return o

A = cells(alpha_hi, np.mean)
L = cells(np.where(key, np.nan, lum), lambda c: np.nanmean(c) if np.isfinite(c).any() else 0)
M = cells(mat, lambda c: np.bincount(c[c > 0].ravel(), minlength=5).argmax() if (c > 0).any() else 0)

# the light: hard from the left of the frame (the reference's side light), the far side falling into shadow
xx = np.linspace(0, 1, W)[None, :]
light = 1.15 - 0.55 * xx
L = np.clip(L * light, 0, 1)

RAMP = {1: RAMPS["w"], 2: RAMPS["m"], 3: RAMPS["k"], 4: RAMPS["d"]}
LO = {1: 0.22, 2: 0.08, 3: 0.02, 4: 0.04}         # each material's own darkest and lightest capture value
HI = {1: 0.60, 2: 0.72, 3: 0.22, 4: 0.30}
img = np.zeros((H, W, 4), np.uint8)
for m, ramp in RAMP.items():
    sel = (M == m) & (A >= 0.5)
    t = np.clip((L - LO[m]) / (HI[m] - LO[m]), 0, 0.999)
    step = (t * len(ramp)).astype(int)
    for k, c in enumerate(ramp):
        s = sel & (step == k)
        img[s, :3] = c; img[s, 3] = 255
# the touch-up (the director, Nov 6: "Check the wrist ... it looks weird in a photo"; then: "All I did was close in the
# triangle from the hand to the wrist"): the game's low-poly hand bends in at the wrist, leaving a notch on the lit side
# between the fist and the forearm. That triangle is filled, the edge running straight from the fist down to the forearm;
# nothing else changes. Positions are this frame's (zqa_mike2_sw_01, 112 x 104).
RETOUCH = len(sys.argv) < 13 or sys.argv[12] != "noretouch"
if RETOUCH and (W, H) == (112, 104):
    skin = (M == 2) & (img[..., 3] > 0)
    def left(y, x0=18, x1=38):
        xs = [x for x in range(x0, x1) if skin[y, x]]
        return xs[0] if xs else None
    Y0, Y1 = 54, 66                       # the fist's last full row, the forearm's first
    l0, l1 = left(Y0), left(Y1)
    if l0 is not None and l1 is not None:
        for y in range(Y0 + 1, Y1):
            edge = int(round(l0 + (l1 - l0) * (y - Y0) / (Y1 - Y0)))
            cur = left(y)
            if cur is None or cur <= edge: continue
            col = img[y, cur, :3].copy()  # the row's own lit edge, carried out to the new edge
            for x in range(edge, cur):
                img[y, x, :3] = col; img[y, x, 3] = 255; M[y, x] = 2
# the edge: one ink pixel where the figure meets the paper (a white tee on white paper needs a line)
from adpx import OUTLINE
solid = img[..., 3] > 0
edge = np.zeros_like(solid)
edge[1:, :] |= solid[1:, :] & ~solid[:-1, :]; edge[:-1, :] |= solid[:-1, :] & ~solid[1:, :]
edge[:, 1:] |= solid[:, 1:] & ~solid[:, :-1]; edge[:, :-1] |= solid[:, :-1] & ~solid[:, 1:]
img[edge, :3] = OUTLINE
DUMBBELL = len(sys.argv) < 10 or sys.argv[9] != "nobell"
if DUMBBELL:
    import dumbbell
    bx, by = (float(sys.argv[10]), float(sys.argv[11])) if len(sys.argv) >= 12 else (None, None)
    img = dumbbell.draw(img, M, bx, by)
Image.fromarray(img, "RGBA").save(out)
print("saved", out, img.shape)
