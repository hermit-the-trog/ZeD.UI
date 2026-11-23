"""The body figure's flesh (director, Nov 22 2026): "can we add just some fleshiness instead of it being just an
outline? The skeleton sits like a cutout. The muscles and tendons and blood vessels. I realize there isn't really much
room for those, and I don't want to show all those in super detail. It's more just so it doesn't look like it's sitting
in a gray cutout figure."

Inside the traced body, one pixel in from the outline (so the outline's own line stays the theme's): a base of deep
tissue, the muscles raised on it with a faint grain along their length, pale tendons at the wrists, knees and ankles and
down the belly, and faint veins (blue) and arteries (red). Lit from the top left like the bones, by the same engine.
Every form is placed from the traced body's own landmarks (d_skeleton.fit / landmarks), mirrored for the two sides.
One set of colors for both themes, as the bones have.

d_skeleton.export lays it under the bones in <s>-skeleton.png, so the game draws it with no change to the Lua.
flesh(sex) gives the frame's RGBA (FH x FW x 4, uint8)."""
import math

import numpy as np
from scipy import ndimage as ndi

import d_skeleton as S
from engine import Dash, Mask, add_ramp

W, H = S.W, S.H

# the tissue's colors: muted, darker than the bones so the bones lead. The deep tissue between the muscles is the
# darkest, so each muscle reads as a form of its own; the tendons a cool pearl, apart from the ivory bones.
add_ramp("flesh", "#4e2c2e", dark=0.42, light=1.40, sat_light=0.85)
add_ramp("muscle", "#8c3d3a", dark=0.30, light=1.42, sat_light=0.88)
add_ramp("tendon", "#bdb5a8", dark=0.50, light=1.14, sat_dark=1.0)
ARTERY = np.array([196, 58, 52], np.float32)
VEIN = np.array([78, 98, 150], np.float32)
VESSEL_A = 0.72             # the vessels show through: three parts in four
FIBER = 0.075               # the muscle's grain: every third line along its length a touch darker
FIBER_EVERY = 3


def _oval(a, b, w):
    """an oval from point a to point b, w across"""
    (ax, ay), (bx, by) = a, b
    cx, cy = (ax + bx) / 2, (ay + by) / 2
    L = math.hypot(bx - ax, by - ay) / 2
    ux, uy = (bx - ax) / (2 * L), (by - ay) / (2 * L)
    nx, ny = -uy, ux
    pts = [(cx + ux * L * math.cos(t) + nx * w / 2 * math.sin(t), cy + uy * L * math.cos(t) + ny * w / 2 * math.sin(t))
           for t in np.linspace(0, 2 * math.pi, 48, endpoint=False)]
    return Mask(W, H).poly(pts).get()


def _strap(pts, w):
    return Mask(W, H).line(pts, w).get(0.45)


def _poly(pts):
    return Mask(W, H).poly(pts).get()


def build(sex):
    """the flesh on the build canvas (H x W x 4, uint8)"""
    F = S.fit(sex)
    L = S.landmarks(sex)
    inside = ndi.binary_erosion(S.outline(sex))       # one pixel in: the outline's own line stays the theme's
    bc = F["bc"]
    d = Dash(W, H, seed=5)
    d.slab(inside, 2.2, "flesh", bevel=3.0, polish=0.15, power=0.6)

    def X(sd, dx):
        return bc + sd * dx

    def arm_c(sd, y):                                 # the arm's own center line at row y (traced)
        a = L["arm"][min(L["arm"], key=lambda q: abs(q - y))]
        return a[0] if sd < 0 else a[1]

    def leg_c(sd, y):
        g = L["leg"][min(L["leg"], key=lambda q: abs(q - y))]
        return g[0] if sd < 0 else g[1]

    def leg_w(y):
        return L["leg"][min(L["leg"], key=lambda q: abs(q - y))][2]

    musc = []      # (mask, z, bevel, material[, grain direction])
    tend = []      # (mask, z)
    veins, arteries = [], []                          # point lists, drawn as 1 px lines
    neck, shy, shj = F["neck"], F["sh_y"], F["shj_y"]
    rt, rb = F["rib_top"], F["rib_bot"]
    pt, crotch = F["pel_top"], L["crotch"]
    ky, ay = F["knee_y"], F["ankle_y"]
    for sd in (-1, 1):
        # the neck: the strap from behind the ear to the breastbone, the trapezius sloping to the shoulder
        musc.append((_strap([(X(sd, 7.5), neck - 7), (X(sd, 2.0), shy + 1)], 3.2), 1.3, 1.6, "muscle"))
        musc.append((_poly([(X(sd, 5), neck - 1), (X(sd, 9), neck - 2), (X(sd, F["sh"] + 1), shj - 6),
                            (X(sd, F["sh"] - 2), shj - 3), (X(sd, 7), shy)]), 1.2, 1.8, "muscle"))
        # the shoulder's cap
        musc.append((_oval((X(sd, F["sh"] + 2.5), shj - 5), (X(sd, F["sh"] + 6.5), shj + 12), 11), 1.8, 2.6, "muscle"))
        # the chest: the fan from the breastbone toward the armpit
        musc.append((_poly([(X(sd, 1.2), rt + 3), (X(sd, 13), rt + 2), (X(sd, F["sh"] - 2), shj + 6),
                            (X(sd, F["sh"] - 4), shj + 14), (X(sd, 10), rt + 30), (X(sd, 1.2), rt + 27)]), 1.6, 2.6,
                     "muscle"))
        # the belly: four blocks a side either side of the pale middle line (their grain runs up and down), the flanks
        top, bot = rb - 16, pt + 18
        cuts = np.linspace(top, bot, 5)
        for i in range(4):
            y0, y1 = cuts[i] + 0.6, cuts[i + 1] - 0.6
            wide = 7.5 if i < 3 else 6.5
            musc.append((Mask(W, H).rrect(X(sd, 1.2) if sd > 0 else X(sd, 1.2 + wide), y0, wide, y1 - y0, 1.6).get(),
                         1.4, 1.8, "muscle", (0.0, 1.0)))
        musc.append((_poly([(X(sd, 9.5), rb - 14), (X(sd, F["rib"] + 1), rb - 18), (X(sd, L["waist_w"] / 2 + 1), L["waist"]),
                            (X(sd, F["pel_w"] + 1), pt + 4), (X(sd, 11), pt + 14), (X(sd, 9.5), pt)]), 1.3, 2.2, "muscle"))
        # the arm: the biceps down the upper arm, the forearm's muscles, their tendons over the wrist
        el, wr = F["el_y"], F["wr_y"]
        musc.append((_oval((arm_c(sd, shj + 14), shj + 12), (arm_c(sd, el - 3), el - 2), 6.5), 1.6, 2.2, "muscle"))
        musc.append((_oval((arm_c(sd, el + 3), el + 2), (arm_c(sd, wr - 6), wr - 6), 6.0), 1.5, 2.0, "muscle"))
        tend.append((_strap([(arm_c(sd, wr - 8), wr - 8), (arm_c(sd, wr + 2), wr + 2)], 1.6), 0.8))

        # the thigh: the outer and middle front muscles, the inner teardrop over the knee, the inner thigh
        def lc(y):
            return leg_c(sd, y)
        ya, yb = crotch - 4, ky - 6
        musc.append((_oval((lc(ya + 6) + sd * leg_w(ya + 6) * 0.30, ya + 2), (lc(yb) + sd * leg_w(yb) * 0.28, yb), 7.5),
                     1.7, 2.6, "muscle"))
        musc.append((_oval((lc(ya + 4), ya + 4), (lc(yb - 4), yb - 2), 6.0), 1.6, 2.4, "muscle"))
        musc.append((_oval((lc(ky - 16) - sd * leg_w(ky - 16) * 0.26, ky - 18),
                           (lc(ky - 3) - sd * leg_w(ky - 3) * 0.18, ky - 3), 5.5), 1.6, 2.2, "muscle"))
        musc.append((_oval((lc(crotch + 2) - sd * leg_w(crotch + 2) * 0.30, crotch),
                           (lc(crotch + 26) - sd * leg_w(crotch + 26) * 0.30, crotch + 26), 5.0), 1.4, 2.0, "muscle"))
        # the long strap across the thigh, hip to inner knee: a muscle, over the others
        musc.append((_strap([(X(sd, F["pel_w"] - 1), pt + 10), (lc(crotch + 12), crotch + 14),
                             (lc(ky - 8) - sd * leg_w(ky - 8) * 0.36, ky - 6)], 2.4), 2.0, 1.0, "muscle"))
        # the knee's tendon, the shin's muscle and its tendon over the ankle, the calf showing either side
        tend.append((_strap([(lc(ky + 4), ky + 4), (lc(ky + 11), ky + 11)], 2.4), 0.9))
        musc.append((_oval((lc(ky + 10) + sd * leg_w(ky + 10) * 0.22, ky + 10),
                           (lc(ay - 12) + sd * leg_w(ay - 12) * 0.12, ay - 12), 4.6), 1.4, 1.8, "muscle"))
        musc.append((_oval((lc(ky + 8) - sd * leg_w(ky + 8) * 0.30, ky + 8),
                           (lc(ky + 34) - sd * leg_w(ky + 34) * 0.22, ky + 34), 5.0), 1.6, 2.0, "muscle"))
        musc.append((_oval((lc(ky + 8) + sd * leg_w(ky + 8) * 0.36, ky + 8),
                           (lc(ky + 30) + sd * leg_w(ky + 30) * 0.34, ky + 30), 3.6), 1.4, 1.6, "muscle"))
        tend.append((_strap([(lc(ay - 12), ay - 12), (lc(ay + 2), ay + 3)], 1.4), 0.8))
        # the vessels: a vein up the outside of the arm and one up the inside of the leg; the arteries in the neck and
        # the thigh
        veins.append([(arm_c(sd, shj + 16) + sd * 2.5, shj + 16), (arm_c(sd, el) + sd * 2.8, el),
                      (arm_c(sd, wr - 4) + sd * 2.2, wr - 4)])
        veins.append([(lc(ay - 4) - sd * leg_w(ay - 4) * 0.40, ay - 4), (lc(ky) - sd * leg_w(ky) * 0.44, ky),
                      (lc(crotch + 10) - sd * leg_w(crotch + 10) * 0.40, crotch + 10), (X(sd, 6.5), crotch - 2)])
        arteries.append([(X(sd, 4.6), neck - 5), (X(sd, 3.2), shy)])
        arteries.append([(X(sd, 8.0), pt + 14), (lc(crotch + 8) - sd * leg_w(crotch + 8) * 0.18, crotch + 8),
                         (lc(ky - 22) - sd * leg_w(ky - 22) * 0.30, ky - 22)])
    # the pale line down the middle of the belly
    tend.append((_strap([(bc, rb - 16), (bc, pt + 18)], 1.2), 0.6))

    for item in musc:
        m, z, bev, mat = item[:4]
        m = m & inside
        m = ndi.binary_erosion(m) if m.sum() > 30 else m       # a groove of deep tissue between neighbours
        if not m.any():
            continue
        d.slab(m, z, mat, bevel=bev, polish=0.22, on="h", power=0.62)
        if m.sum() < 6:
            continue
        # the grain: faint lines along the muscle's length (its long way, unless given)
        if len(item) > 4:
            ax, ay_ = item[4]
        else:
            ys, xs = np.nonzero(m)
            _, evec = np.linalg.eigh(np.cov(np.vstack([xs, ys]).astype(np.float64)))
            ax, ay_ = evec[:, 1]
        n = math.hypot(ax, ay_)
        nx, ny = -ay_ / n, ax / n
        v = (d.XX + 0.5) * nx + (d.YY + 0.5) * ny
        grain = np.floor(v) % FIBER_EVERY == 0
        d.tex[m] = np.where(grain[m], -FIBER, 0.0)
    for m, z in tend:
        d.slab(m & inside, z, "tendon", bevel=1.0, polish=0.30, on="h", power=0.7)
    img = np.array(d.render(chrome_env="room", outline=False)).astype(np.float32)
    for lines, col in ((veins, VEIN), (arteries, ARTERY)):
        for pts in lines:
            m = Mask(W, H).line(pts, 1.0).get(0.5) & inside
            img[m, :3] = img[m, :3] * (1 - VESSEL_A) + col * VESSEL_A
    img[~inside] = 0
    return np.clip(np.round(img), 0, 255).astype(np.uint8)


def flesh(sex):
    """the flesh in the frame (FH x FW x 4, uint8)"""
    return S.reframe(build(sex))
