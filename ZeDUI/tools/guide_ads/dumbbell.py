"""The game's dumbbell (Base.DumbBell: a short chrome bar, two black plates a side, chrome collars) drawn into Iron
Mike's fist, in the book's ink. The capture's model holds nothing (a UI model has no hands to fill), so it is drawn
here, after the in-world curl (zqa_mike3_world_e_08.png): the bar runs across the fist along his shoulders, nearly
level on the page; the plates face along the bar, so we see them almost edge-on, as tall narrow ovals."""
import numpy as np
from engine import RAMPS
from adpx import OUTLINE

CX, CY = 50.0, 45.0        # the middle of the fist
TILT = 0.0               # the bar's slope (rise per pixel to the right)
GRIP = 5                   # half the fist's width: the bar hidden behind the fingers
PLATES = [(8.5, 2.8, 11.5), (12.5, 2.6, 10.0)]   # (the director, Nov 6: "make the dumbbell larger")   # (distance from the middle, half-width, half-height), inner then outer
COLLAR = 16.0              # the bar's ends


def draw(img, M, cx=None, cy=None):
    global CX, CY
    if cx is not None: CX, CY = cx, cy
    H, W = img.shape[:2]
    out = img.copy()
    yy, xx = np.mgrid[0:H, 0:W] + 0.5
    k = RAMPS["k"]; ch = RAMPS["chrome"]
    mask = np.zeros((H, W), bool)

    def put(sel, col):
        out[sel, :3] = col; out[sel, 3] = 255; mask[sel] = True

    for side in (-1, 1):
        # the bar: two pixels thick, light on top
        for d in np.arange(GRIP, COLLAR + 0.5, 0.25):
            x = CX + side * d; y = CY + side * d * TILT
            xi, yi = int(x), int(y)
            if 0 <= xi < W and 0 <= yi < H - 1:
                put((yy.astype(int) == yi) & (xx.astype(int) == xi), ch[6])
                put((yy.astype(int) == yi + 1) & (xx.astype(int) == xi), ch[3])
        # the plates, inner first so the outer one sits on it
        for dist, rx, ry in PLATES:
            px = CX + side * dist; py = CY + side * dist * TILT + 0.5
            e = ((xx - px) / rx) ** 2 + ((yy - py) / ry) ** 2 <= 1.0
            # lit from the left: the left rim catches the light, the face goes dark toward the right
            t = np.clip((px - xx) / rx * 0.5 + 0.5, 0, 1)            # 1 at the left rim
            v = (yy - py) / ry                                         # a little lighter toward the top
            step = np.clip((t * 4 + (v < -0.3) * 1).astype(int), 0, 7)
            for s in range(8):
                put(e & (step == s), k[s])
        # the collar at the end: a chrome nub
        x = CX + side * COLLAR; y = CY + side * COLLAR * TILT
        nub = (np.abs(xx - x) <= 1.0) & (np.abs(yy - y - 0.5) <= 1.6)
        put(nub & (yy < y + 0.5), ch[7]); put(nub & (yy >= y + 0.5), ch[2])
    # an ink line round the dumbbell where it meets the paper or the figure's lighter parts
    edge = np.zeros_like(mask)
    edge[1:, :] |= ~mask[1:, :] & mask[:-1, :]; edge[:-1, :] |= ~mask[:-1, :] & mask[1:, :]
    edge[:, 1:] |= ~mask[:, 1:] & mask[:, :-1]; edge[:, :-1] |= ~mask[:, :-1] & mask[:, 1:]
    fist = (np.abs(xx - CX) <= GRIP) & (np.abs(yy - CY) <= 5)
    edge &= ~fist
    out[edge, :3] = OUTLINE; out[edge, 3] = 255
    return out
