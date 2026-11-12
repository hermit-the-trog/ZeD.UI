"""The eagle sprite for the thumbnail (the director, Nov 11 2026): "Use the pixel art one as a reference and use the
real flying cutout bird as the form." The form is traced from the photo (its outline, its light and dark), then drawn
in this picture's own pixel style: a small brown ramp, white head and tail, yellow beak and feet, an ink outline.
Mirrored to face right, the way it flies across the window."""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

INK = (20, 13, 8)
RAMP = [(46, 28, 14), (74, 46, 22), (104, 68, 34), (138, 98, 56), (170, 140, 104)]    # dark brown .. sunlit edge
WH, WHS, WHD = (246, 244, 238), (204, 200, 192), (150, 146, 138)
YE, YED = (242, 186, 34), (186, 124, 14)


def _box(x, W, H): return np.asarray(Image.fromarray(x.astype(np.float32), mode="F").resize((W, H), Image.BOX))


def build(photo, W, out):
    a = np.asarray(Image.open(photo).convert("RGB")).astype(float)
    mn, mx = a.min(-1), a.max(-1)
    bg = (mn > 222) & (mx - mn < 12)
    m = ndimage.binary_fill_holes(~bg)
    ys, xs = np.nonzero(m); sl = (slice(ys.min(), ys.max() + 1), slice(xs.min(), xs.max() + 1)); a = a[sl]; m = m[sl]
    H = round(a.shape[0] * W / a.shape[1])
    r, g, b = a[..., 0], a[..., 1], a[..., 2]; lum = 0.3 * r + 0.59 * g + 0.11 * b; sat = a.max(-1) - a.min(-1)
    yel = m & (r > 150) & (b < 110) & (sat > 70)
    whi = m & (lum > 175) & (sat < 45) & ~yel
    cov = _box(m, W, H); fy = _box(yel, W, H); fw = _box(whi, W, H)
    L = _box(lum * m, W, H) / np.maximum(cov, 1e-3)
    L = ndimage.gaussian_filter(L, 0.7)                                  # calm the photo's grain into broad shading
    o = np.zeros((H, W, 4), np.uint8)
    for y in range(H):
        for x in range(W):
            if cov[y, x] < 0.32: continue
            if fy[y, x] > 0.18: c = YE if fy[y, x] > 0.4 else YED
            elif fw[y, x] > 0.42 and y > H * 0.62: c = WH                  # white only in the tail; the head is drawn below
            elif fw[y, x] > 0.25 and y > H * 0.62: c = WHS
            else:
                l = L[y, x]
                c = INK if l < 30 else RAMP[0] if l < 55 else RAMP[1] if l < 80 else RAMP[2] if l < 110 else RAMP[3] if l < 150 else RAMP[4]
            o[y, x, :3] = c; o[y, x, 3] = 255
    o = o[:, ::-1].copy()
    # the head, drawn bold the way pixel art does it (the photo's head is a few cells at this size): a white head on
    # the photo's head, a big hooked yellow beak, a dark eye under a brow
    fwm = fw[:, ::-1].copy(); fwm[int(H * 0.62):] = 0                    # where the photo's white head is
    hy, hx = np.nonzero(fwm > 0.3)
    cy, cx = int(round(hy.mean())), int(round(hx.mean()))
    rx, ry = max(4, W // 16), max(3, W // 22)
    for y in range(cy - ry - 1, cy + ry + 2):
        for x in range(cx - rx - 1, cx + rx + 2):
            if ((x - cx) / (rx + 0.5)) ** 2 + ((y - cy) / (ry + 0.5)) ** 2 <= 1 and 0 <= y < H and 0 <= x < W:
                o[y, x] = WH + (255,)
    for x in range(cx - rx, cx - rx + 3):                               # the neck's feathers, ragged into the brown
        for y in (cy + ry, cy + ry - 1):
            if (x + y) % 2 == 0 and 0 <= y < H: o[y, x] = WHS + (255,)
    bx = cx + rx                                                         # beak: from the face, hooking down at the tip
    for dx, ys, c in ((0, (cy - 1, cy, cy + 1), YE), (1, (cy - 1, cy, cy + 1), YE), (2, (cy - 1, cy, cy + 1), YE),
                      (3, (cy, cy + 1), YE), (4, (cy + 1, cy + 2), YED), (1, (cy + 1,), YED), (2, (cy + 1,), YED)):
        for y in ys:
            if 0 <= bx + dx < W and 0 <= y < H: o[y, bx + dx] = c + (255,)
    o[cy - 1, cx + rx - 2] = INK + (255,)                                # eye
    o[cy - 2, cx + rx - 3: cx + rx - 0] = WHS + (255,)                   # brow
    o = np.pad(o, ((1, 1), (1, 1), (0, 0)))
    m2 = o[..., 3] > 0; e = np.zeros_like(m2)
    e[1:] |= m2[:-1]; e[:-1] |= m2[1:]; e[:, 1:] |= m2[:, :-1]; e[:, :-1] |= m2[:, 1:]
    o[e & ~m2] = INK + (255,)
    Image.fromarray(o).save(out)
    return o


if __name__ == "__main__":
    build(sys.argv[1], int(sys.argv[2]), sys.argv[3])
