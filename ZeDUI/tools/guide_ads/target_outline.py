"""West Point's paper target (the director, Nov 6 2026: "The target. ... Use one of the character outlines from one of
the avatars. We have a lot of screenshots for those already"): the outline of the game's own player model, cut from a
capture of ZeD's equipment doll (g5_equip_doll.png: the doll in the Character window, facing out, arms down, a ball
cap on, on the panel's flat ground) and saved as a mask the target prints in black.

The doll is keyed off the panel's flat colour. The rifle slung on his back stands up past his right shoulder (the left
of the picture); it is not the man, so it is taken out: above the shoulder everything left of his cap and face goes
(the line traced from the capture, FACE_EDGE), and where the stock still shows past the shoulder its walnut goes.
The outline is cut level at the hips, where a range's silhouette target ends.

python target_outline.py <capture.png> [out.png]  ->  refs/avatar_outline.png (white = the figure)"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

src = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else "refs/avatar_outline.png"
BOX = (700, 120, 940, 700)          # the doll's column in the Character window at 3840 x 2160
GROUND = np.array([30, 29, 26])     # the panel's flat colour behind the doll
# the left edge of his cap and face (x, y in the box), traced from the capture; left of it, above the shoulder, is rifle
FACE_EDGE = [(94, 0), (94, 43), (91, 44), (89, 52), (88, 60), (88, 80), (89, 86), (91, 95), (94, 101), (96, 113),
             (97, 118)]
SHOULDER = 118                      # the top of his shoulder on the rifle's side
STOCK_ROWS = (118, 128)             # where the stock still shows past the shoulder
CUT = 300                           # the hips (rows in the box): the target ends here

a = np.asarray(Image.open(src).convert("RGB").crop(BOX)).astype(int)
r, g, b = a[..., 0], a[..., 1], a[..., 2]
lum = 0.30 * r + 0.59 * g + 0.11 * b
fig = np.abs(a - GROUND).max(-1) > 3
fig = ndi.binary_opening(fig, np.ones((2, 2)))
lab, n = ndi.label(fig)
fig = lab == (np.argmax(ndi.sum(fig, lab, range(1, n + 1))) + 1)
fig = ndi.binary_fill_holes(fig)
brown = (r > g + 15) & (r > b + 25) & (g < 95)              # the rifle's stock: dark walnut
yy, xx = np.mgrid[0:fig.shape[0], 0:fig.shape[1]]
ey = [p[1] for p in FACE_EDGE]; ex = [p[0] for p in FACE_EDGE]
for y in range(0, SHOULDER):
    fig[y, :int(round(np.interp(y, ey, ex)))] = False
y0, y1 = STOCK_ROWS
fig[y0:y1] &= ~(brown[y0:y1] & (xx[y0:y1] < 86))
lab, n = ndi.label(fig)
fig = lab == (np.argmax(ndi.sum(fig, lab, range(1, n + 1))) + 1)
fig = ndi.binary_opening(fig, np.ones((3, 3)))
fig = ndi.binary_fill_holes(fig)
fig[CUT:] = False
ys, xs = np.nonzero(fig)
fig = fig[ys.min():CUT, xs.min():xs.max() + 1]
Image.fromarray((fig * 255).astype(np.uint8)).save(out)
print("saved", out, fig.shape, "box offset", xs.min(), ys.min())
