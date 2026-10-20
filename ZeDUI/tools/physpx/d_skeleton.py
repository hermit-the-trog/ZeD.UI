"""The body figure's skeletons in lit pixel art (director, Oct 17 2026: "rework the body skeleton and background and
make female skelly"; lit pixel-art bones, the perspective grid redrawn, the flesh outline kept and refined).

One 220 x 260 canvas for both sexes (the figure's own size, ZeD.Spacing.figureW / H, so the pixels land whole at 1x
and 2x). Ivory bones lit from the top left like the plates; each bone belongs to one of the 17 body parts the Health,
Thermal and Equipment tabs colour. Female: a smaller skull and jaw, narrower shoulders and ribcage, a wider, rounder
pelvis, the thighs angled in toward the knees; her own silhouette.

Exports (media/textures/ZeD/body/):
  <s>-skeleton.png        the whole skeleton, lit (drawn untinted over the grid)
  <s>-<part>.png          each part's bones alone, same canvas (drawn tinted on top: injury, temperature, protection)
  fig-bg-<s>-<dark|light>.png   the perspective grid and the flesh outline (drawn tinted by the theme)
  and ZeD_BodyLayout.lua's tables (each part's hit rectangle, from its pixels)
s = m / f. usage: python d_skeleton.py [mod root]"""
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

from physlib import *            # noqa: F401,F403
from engine import add_ramp, OUTLINE

W, H = 220, 260
CX = 110
add_ramp("bone", "#e4d9bf", light=1.07)
add_ramp("bone_joint", "#cdbf9d", light=1.04)


# The skulls, drawn by hand (Oct 17 2026; director: "the skulls are really bad"): a front-view pixel map each, one
# character a pixel: # bone, o an eye socket, n the nose opening, t teeth, - the gap between the teeth rows. Hers is
# smaller and rounder, with a smaller jaw and chin.
SKULL_M = [
    ".........########.........",
    "......##############......",
    "....##################....",
    "...####################...",
    "..######################..",
    "..######################..",
    ".########################.",
    ".########################.",
    ".########################.",
    ".########################.",
    ".########################.",
    ".########################.",
    ".########################.",
    "..######################..",
    "..######################..",
    "..###oooo########oooo###..",
    "..##oooooo######oooooo##..",
    "..##oooooo######oooooo##..",              # the cheeks a pixel in each side (Oct 19 2026: the cranium sits
    "..##oooooo##nn##oooooo##..",              # inside the band now, and wider cheeks stood out from it again)
    "..##oooooo#nnnn#oooooo##..",
    "..###oooo##nnnn##oooo###..",
    "...########nnnn########...",
    "....########nn########....",
    "....##################....",
    ".....################.....",
    ".....#tttttttttttttt#.....",
    "......--------------......",
    "......#tttttttttttt#......",
    ".......############.......",
    "........##########........",
    "........cccccccccc........",
    ".........cccccccc.........",
]
SKULL_F = [
    "........########........",
    ".....##############.....",
    "...##################...",
    "..####################..",
    ".######################.",
    ".######################.",
    ".######################.",
    ".######################.",
    ".######################.",
    ".######################.",
    ".######################.",
    ".######################.",
    "..####################..",
    # the face narrower (Oct 19 2026): her outline's face is slim, and with the bones kept MARGIN in it clipped her
    # sockets and cheeks; five-pixel sockets, the same nose and jaw, all inside the band
    "..####ooo######ooo####..",
    "..###ooooo####ooooo###..",
    "..###ooooo####ooooo###..",
    "...##ooooo#nn#ooooo##...",
    "...###ooo#nnnn#ooo###...",
    "....######nnnn######....",
    "....#######nn#######....",
    ".....##############.....",
    ".....#tttttttttttt#.....",
    "......------------......",
    "......#tttttttttt#......",
    ".......##########.......",
    "........cccccccc........",
    ".........cccccc.........",
]
# a taller dome (Oct 17 2026: the skull sat low in the head outline once the neck was shortened): three more rows at
# the cranium's widest
SKULL_M[7:7] = [SKULL_M[7]] * 3
SKULL_F[5:5] = [SKULL_F[5]] * 3
for _sk in (SKULL_M, SKULL_F):
    assert len({len(r) for r in _sk}) == 1, [len(r) for r in _sk]

PARTS = ["head", "neck", "up-torso", "bicep-r", "bicep-l", "low-torso", "wrist-r", "wrist-l", "groin", "hand-r", "hand-l",
         "thigh-r", "thigh-l", "ankle-r", "ankle-l", "foot-r", "foot-l"]
PID = {p: i + 1 for i, p in enumerate(PARTS)}

# proportions, male and female (canvas pixels; "r" = the character's right = the viewer's left, x < 110)
SEX = {
    "m": dict(skull=(13.0, 14.0), jaw=10.0, sh=27.0, rib=21.5, rib_lo=17.0, pel_w=18.0, pel_top=110, pel_flare=1.0,
              hip=9.5, knee=11.5, ankle=12.5, elbow=32.0, wrist=39.0, carry=0.0, arm=6.2, leg=7.4, flesh=1.0,
              skull_map="SKULL_M", skull_top=8, neck_top=44.5),
    "f": dict(skull=(12.2, 13.2), jaw=8.4, sh=23.0, rib=19.0, rib_lo=14.5, pel_w=21.5, pel_top=111, pel_flare=1.25,
              hip=12.0, knee=11.0, ankle=11.5, elbow=29.5, wrist=38.0, carry=3.0, arm=5.4, leg=6.8, flesh=1.0,
              skull_map="SKULL_F", skull_top=11, neck_top=42.5),
}


MARGIN = 3          # the outline's line, a pixel of flesh, the bone's dark rim, then bone


def inner_region(sex):
    """where bone may go (Oct 19 2026: "a little of the outline peeking out the top of the shoulders and head, so
    skeleton parts all look evenly contained"). The bone's dark rim is drawn outside its pixels, so to show flesh
    between the rim and the outline's line the bone keeps MARGIN (3) pixels in. A limb only five to ten pixels across
    (her forearms and wrists, the hands, the ankles) has no room for that on both sides, so the band follows the room:
    3 where a disc 11 across fits (head, shoulders, chest, hips, thighs), 2 where one 7 across fits, else 1."""
    om = outline(sex)
    def disc_se(r):
        q = int(math.ceil(r))
        yy, xx = np.mgrid[-q:q + 1, -q:q + 1]
        return xx * xx + yy * yy <= r * r
    wide = ndi.binary_opening(om, structure=disc_se(5.6))
    mid = ndi.binary_opening(om, structure=disc_se(3.2))
    e = {k: ndi.binary_erosion(om, iterations=k) for k in (1, 2, MARGIN)}
    # the wide test spreads a little so a band never steps down right at a shoulder's or hip's own edge
    wide = ndi.binary_dilation(wide, iterations=1) & om
    return (e[MARGIN] & wide) | (e[2] & mid & ~wide) | (e[1] & ~mid & ~wide)


class Skel:
    def __init__(s, sex):
        s.sex = sex
        s.c = SEX[sex]
        s.p = Plate(f"{sex}_skeleton", W, H, seed=41)
        s.d = s.p.d
        s.owner = np.zeros((H, W), np.int16)
        # the bones MARGIN pixels in from the body's edge all round (Oct 19 2026: "a little of the outline peeking out the
        # top of the shoulders and head, so skeleton parts all look evenly contained"): the outline's line, a pixel of
        # flesh, the bone's rim, then bone. Every mask is cut to this before it is shaped, so its bevel follows the cut.
        s.inner = inner_region(sex)

    def mark(s, m, part):
        s.owner[m] = PID[part]

    def bone(s, part, a, b, w0, w1=None, z=3.0, knob=True, mat="bone"):
        """a long bone from a to b, w0 thick at a, w1 at b, a waist in the shaft, knobbed ends (the joints)"""
        w1 = w0 if w1 is None else w1
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy)
        nx, ny = -dy / L, dx / L
        wm = (w0 + w1) / 2 * 0.74
        mid = (a[0] + dx / 2, a[1] + dy / 2)
        pts = [(a[0] + nx * w0 / 2, a[1] + ny * w0 / 2), (mid[0] + nx * wm / 2, mid[1] + ny * wm / 2),
               (b[0] + nx * w1 / 2, b[1] + ny * w1 / 2), (b[0] - nx * w1 / 2, b[1] - ny * w1 / 2),
               (mid[0] - nx * wm / 2, mid[1] - ny * wm / 2), (a[0] - nx * w0 / 2, a[1] - ny * w0 / 2)]
        m = Mask(W, H).poly(pts).get()
        if knob:
            m |= disc(s.d, a[0], a[1], w0 * 0.64) | disc(s.d, b[0], b[1], w1 * 0.64)
        m &= s.inner
        s.d.slab(m, Z_FACE + z, mat, bevel=max(1.2, min(w0, w1) * 0.45), polish=0.3, power=0.55)
        s.mark(m, part)
        return m

    def curve(s, part, pts, w, z=2.5, mat="bone"):
        m = Mask(W, H).line(pts, w).get(0.45) & s.inner
        s.d.slab(m, Z_FACE + z, mat, bevel=max(0.8, w / 2), polish=0.35, power=0.6)
        s.mark(m, part)
        return m

    def blob(s, part, m, z=3.0, bevel=2.5, mat="bone"):
        m = m & s.inner
        s.d.slab(m, Z_FACE + z, mat, bevel=bevel, polish=0.35, power=0.6)
        s.mark(m, part)
        return m

    def hole(s, m, depth=2.0, dark=0.6):
        m = m & s.inner
        s.d.well(m, depth, bevel=0.8)
        s.d.seam(m, dark)



# ---------------------------------------------------------------------------
# The bodies the skeletons are built into (director, Oct 17 2026: "use screens of the male and female avatar no
# clothing and build the skeleton to fit that outline"): the game's own unclothed male and female, captured front on
# (ZeDUI/tools/qa/zedqa_avatar.lua; ref/avatar_capture.png), traced to this canvas at one shared scale
# (ref/outline_<s>.png). The landmarks are read off each outline row by row and every joint is placed from them.
# ---------------------------------------------------------------------------
REF = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ref")


def outline(sex):
    return np.array(Image.open(os.path.join(REF, f"outline_{sex}.png"))) > 0


def runs(row):
    r=[];x=0;n=len(row)
    while x<n:
        if row[x]:
            s=x
            while x<n and row[x]: x+=1
            r.append((s,x-1))
        else: x+=1
    return r
def landmarks(sex):
    m=outline(sex)
    H,W=m.shape
    ys=np.nonzero(m.any(1))[0]; top,bot=ys.min(),ys.max()
    R=[runs(m[y]) for y in range(H)]
    wid=lambda y: (R[y][-1][1]-R[y][0][0]+1) if R[y] else 0
    # neck: narrowest row in the upper band
    band=range(top+18,top+40)
    neck=min(band,key=lambda y: wid(y) if len(R[y])==1 else 999)
    head=(R[top+12][0][0],R[top+12][-1][1]) # head width at mid-head
    hw=[wid(y) for y in range(top,neck)]
    head_l=min(R[y][0][0] for y in range(top,neck)); head_r=max(R[y][-1][1] for y in range(top,neck))
    # shoulders: first row below the neck at 90% of the widest upper-body row
    up=range(neck,neck+30)
    wmax=max(wid(y) for y in up)
    sh_y=next(y for y in up if wid(y)>=0.9*wmax)
    # armpit: first row with 3 runs
    armpit=next(y for y in range(neck,bot) if len(R[y])>=3)
    # crotch: first row (below armpit+40) where the middle splits into two legs: >=4 runs, or 2 runs below the hands
    crotch=next(y for y in range(armpit+40,bot) if len(R[y])>=4 or (len(R[y])==2 and R[y][0][1]>100-30 and R[y][1][0]<120+30 and (R[y][1][0]-R[y][0][1])<40))
    # torso middle run per row (between armpit and crotch)
    def mid(y):
        rr=R[y]
        if len(rr)>=3: return rr[1] if len(rr)==3 else None
        return None
    waist=min(range(armpit+5,crotch-8),key=lambda y: (mid(y)[1]-mid(y)[0]) if mid(y) else 999)
    hipy=max(range(waist,crotch),key=lambda y: (mid(y)[1]-mid(y)[0]) if mid(y) else 0)
    # arm centrelines (outer runs) per row while 3+ runs
    arm={}
    for y in range(armpit,bot):
        rr=R[y]
        if len(rr)>=3:
            arm[y]=((rr[0][0]+rr[0][1])/2,(rr[-1][0]+rr[-1][1])/2,rr[0][1]-rr[0][0]+1)
    arm_bot=max(arm) if arm else None
    # the arms' last rows (fingertips): rows with outer runs left of the legs
    fing=max(y for y in range(armpit,bot) if R[y] and R[y][0][1]<92)
    # legs: rows below crotch, the two runs nearest the centre
    leg={}
    for y in range(crotch+1,bot+1):
        rr=[r for r in R[y] if r[1]>=88 and r[0]<=132]
        if len(rr)==2: leg[y]=((rr[0][0]+rr[0][1])/2,(rr[1][0]+rr[1][1])/2,rr[0][1]-rr[0][0]+1)
    ly=sorted(leg)
    # ankle: narrowest leg in the bottom quarter (above the foot flare); knee: narrowest between thigh and calf
    lo=[y for y in ly if y>bot-35 and y<bot-6]
    ankle=min(lo,key=lambda y: leg[y][2])
    kband=[y for y in ly if crotch+25<y<ankle-25]
    knee=min(kband,key=lambda y: leg[y][2])
    return dict(top=int(top),bot=int(bot),neck=int(neck),head_l=int(head_l),head_r=int(head_r),sh_y=int(sh_y),
                sh_l=int(R[sh_y][0][0]),sh_r=int(R[sh_y][-1][1]),armpit=int(armpit),waist=int(waist),
                waist_w=int(mid(waist)[1]-mid(waist)[0]+1),hip_y=int(hipy),hip_w=int(mid(hipy)[1]-mid(hipy)[0]+1),
                crotch=int(crotch),fing=int(fing),knee=int(knee),ankle=int(ankle),
                arm={int(k):v for k,v in arm.items()},leg={int(k):v for k,v in leg.items()},
                chest_w=int(mid(armpit+4)[1]-mid(armpit+4)[0]+1) if mid(armpit+4) else None)


def torso_half(sex, y, bc):
    """the body's half width at row y: the outline's run under the centre line"""
    m = outline(sex)
    y = int(round(min(max(y, 0), H - 1)))
    xc = int(round(bc))
    if not m[y, xc]: return 0.0
    l = xc
    while l > 0 and m[y, l - 1]: l -= 1
    r = xc
    while r < W - 1 and m[y, r + 1]: r += 1
    return min(xc - l, r - xc) + 0.5


def fit(sex):
    """every joint, from the outline's landmarks (canvas pixels; offsets are from the body's centre line)"""
    L = landmarks(sex)
    bc = (L["sh_l"] + L["sh_r"]) / 2.0
    arm, leg = L["arm"], L["leg"]
    def near(dct, y):
        k = min(dct, key=lambda q: abs(q - y))
        return dct[k]
    def arm_off(y, side=0):
        a = near(arm, y)
        if side < 0: return bc - a[0]
        if side > 0: return a[1] - bc
        return (a[1] - a[0]) / 2.0
    def leg_off(y, side=0):
        g = near(leg, y)
        if side < 0: return bc - g[0]
        if side > 0: return g[1] - bc
        return (g[1] - g[0]) / 2.0
    arm_w = near(arm, L["armpit"] + 3)[2]
    # the shoulder joint sits 6 under the collar bones; from it to the fingertips the arm divides 30 : 25 : 19 (upper
    # arm, forearm, hand), Oct 17 2026: the upper arm had grown too long when the collar bones moved up
    clav_y = L["neck"] + 0.42 * (L["sh_y"] - L["neck"])
    # the shoulder joint at the deltoid, two rows above the outline's full-shoulder row (Oct 19 2026: on the neck's slope
    # it pulled the shoulders in; the ribcage's top ribs widen to meet it, so it does not float)
    shj_y = L["sh_y"] - 2.0
    reach = L["fing"] - 1 - shj_y
    el_y = shj_y + reach * 30 / 74.0
    wr_y = shj_y + reach * 55 / 74.0
    up_leg_w = near(leg, L["crotch"] + 12)[2]
    low_leg_w = near(leg, L["knee"] + 14)[2]
    pt = L["crotch"] - 26
    return dict(
        bc=bc, top=L["top"], bot=L["bot"], neck=L["neck"],
        sh_y=clav_y, shj_y=shj_y, sh=(L["sh_r"] - L["sh_l"]) / 2.0 - arm_w / 2.0,
        arm_top=arm_off(L["armpit"] + 2), armpit=L["armpit"],
        # each side on its own traced centre line (the model is not quite symmetric: Oct 17 2026)
        side={sd: dict(arm_top=arm_off(L["armpit"] + 2, sd), elbow=arm_off(el_y, sd), wrist=arm_off(wr_y, sd),
                       hand=arm_off(L["fing"] - 3, sd), hip=leg_off(L["crotch"] + 3, sd) - 4.0,
                       troch=leg_off(L["crotch"] + 3, sd) + 1.5, knee=leg_off(L["knee"], sd), ankle=leg_off(L["ankle"], sd))
              for sd in (-1, 1)},
        el_y=el_y, elbow=arm_off(el_y), wr_y=wr_y, wrist=arm_off(wr_y), fing=L["fing"], hand=arm_off(L["fing"] - 3),
        arm=max(5.0, arm_w * 0.40),
        rib_top=clav_y + 2, rib_bot=pt - 12, rib=L["chest_w"] / 2.0 - 1.5, rib_lo=L["waist_w"] / 2.0 - 2.5,
        pel_top=pt, pel_w=L["hip_w"] / 2.0 - 3.0,
        hip_y=L["crotch"] - 9, hip=leg_off(L["crotch"] + 3) - 4.0, troch=leg_off(L["crotch"] + 3) + 1.5,
        knee_y=L["knee"], knee=leg_off(L["knee"]), ankle_y=L["ankle"], ankle=leg_off(L["ankle"]),
        femur=up_leg_w * 0.34, tibia=min(low_leg_w * 0.50, up_leg_w * 0.34 * 0.85))

def build(sex):
    S = Skel(sex)
    c = S.c
    d = S.d
    M = lambda: Mask(W, H)
    mir = lambda x: 2 * CX - x            # the character's left, mirrored

    # ---- the skull, from its hand-drawn map
    sk = SKULL_M if c["skull_map"] == "SKULL_M" else SKULL_F
    sw, shh = len(sk[0]), len(sk)
    F0 = fit(sex)
    y0 = F0["neck"] - 1 - shh
    # centred on the head's own outline (the cranium's rows), not the shoulders' centre line
    om0 = outline(sex)
    hcs = [(np.nonzero(om0[y])[0].min() + np.nonzero(om0[y])[0].max()) / 2.0 for y in range(y0 + 4, y0 + 12) if om0[y].any()]
    x0 = int(math.floor(float(np.mean(hcs)) - sw / 2.0 + 0.5))
    def cells(chars):
        m = np.zeros((H, W), bool)
        for r_, row in enumerate(sk):
            for q, ch in enumerate(row):
                if ch in chars: m[y0 + r_, x0 + q] = True
        return m
    whole = cells("#ontr-c")
    # the skull symmetric inside the band (Oct 19 2026: her traced head is lopsided at the crown, and the skull cut to it
    # took a dent): the room on each side is the narrower of the two, mirrored about the skull's centre
    cx2 = 2 * x0 + sw - 1
    xs_ = np.arange(W)
    mirror_ok = np.zeros_like(S.inner)
    ok_x = (cx2 - xs_ >= 0) & (cx2 - xs_ < W)
    mirror_ok[:, ok_x] = S.inner[:, (cx2 - xs_)[ok_x]]
    whole &= mirror_ok
    # and no swelling at the temples where the outline reaches out to the ears (Oct 17 2026 "ear like"): the cranium's
    # rows above the eyes never wider than the eye rows themselves, once the dome has reached that width
    eye_r = y0 + [i for i, r in enumerate(sk) if "o" in r][0]
    face_w = max(int(whole[y].sum()) for y in range(eye_r, eye_r + 3))
    reached = False
    for y in range(y0, eye_r):
        w_ = int(whole[y].sum())
        if w_ >= face_w - 2: reached = True
        if reached and w_ > face_w:
            xs = np.nonzero(whole[y])[0]
            cut = (w_ - face_w) // 2
            whole[y, xs[:cut]] = False; whole[y, xs[len(xs) - cut:]] = False
    S.blob("head", whole, z=4.6, bevel=4.0)                     # the dome rounds over from every edge
    # the brow and the cheekbones a little proud, the temples a little in
    eyes = cells("o")
    brow = ndi.binary_dilation(eyes, iterations=1) & ~eyes & whole
    brow &= (d.YY < y0 + np.argmax([("o" in r) for r in sk]) + 1)
    d.h[brow] += 0.5
    S.hole(eyes, 3.0, 0.95)
    S.hole(cells("n"), 2.2, 0.92)
    teeth = cells("t") & S.inner
    S.hole(cells("-"), 1.6, 0.72)
    # the lower jaw its own surface below the teeth, flatter than the dome so it takes the light, and the chin standing
    # proud at its foot (Oct 17 2026: "needs a chin")
    gap_row = [i for i, r in enumerate(sk) if "-" in r][0]
    jaw = cells("#c") & (d.YY > y0 + gap_row + 1) & S.inner
    d.slab(jaw, Z_FACE + 4.0, "bone", bevel=1.4, polish=0.35, power=0.6)
    chin = cells("c") & S.inner
    d.slab(chin, Z_FACE + 4.6, "bone", bevel=1.0, polish=0.4, power=0.6)
    d.seam(jaw & (d.YY == y0 + gap_row + 2), 0.18)          # under the lower teeth
    # the teeth over it all: flat and evenly lit (Oct 17 2026: hers looked crooked in the dome's shading), a gap every
    # second pixel counted from the skull's centre so the upper and lower rows line up
    d.slab(teeth, Z_FACE + 4.3, "bone", bevel=0.4, polish=0.3, power=0.6)
    d.tex[teeth] = 0.06
    d.dark[teeth] = 0.0
    mid_q = (sw - 1) / 2.0
    for q in range(sw):
        if int(round(abs(q - mid_q) + 0.5)) % 2 == 0:
            d.seam(teeth & (d.XX == x0 + q), 0.30)
    # the jaw's edges in shade (the U of the mandible reads), the chin brighter, a little fold above it
    jaw_all = jaw | chin
    d.dark[jaw_all & ~ndi.binary_erosion(jaw_all, structure=np.array([[0, 0, 0], [1, 1, 1], [0, 0, 0]]))] = 0.30
    d.tex[chin] += 0.14
    crow = chin.nonzero()[0].min()
    above = jaw & (d.YY == crow - 1) & (np.abs(d.XX - (x0 + sw / 2.0 - 0.5)) < 2.5)
    d.seam(above, 0.30)
    d.seam(cells("-") | (ndi.binary_dilation(cells("-"), iterations=1) & teeth & (d.XX < x0 + 0)), 0.0)

    F = fit(sex)
    BC = F["bc"]
    # ---- the neck: small vertebrae from under the jaw down to the shoulders
    for y in np.arange(y0 + shh + 0.5, F["sh_y"] + 1.5, 2.1):
        S.blob("neck", M().rrect(BC - 3.0, y, 6.0, 1.8, 0.6).get(), z=2.6, bevel=0.8)

    # ---- the shoulder joints: on each arm's centre line, inside the shoulder's outline at the full-shoulder row
    sh, shy = F["sh"], F["sh_y"]
    aw = F["arm"]
    shj_of = {}
    om_ = outline(sex)
    for side in (-1, 1):
        sy = F["shj_y"]
        xs = np.nonzero(om_[int(round(sy))])[0]
        # against the top corner of the ribcage (the director's references, Oct 19 2026): just outside the cage's top
        # ribs, never past the arm's own line or the shoulder's outline
        off = F["side"][side]["arm_top"]
        if len(xs):
            edge = (xs.max() - BC) if side > 0 else (BC - xs.min())
            off = min(off, edge - aw * 0.72 - MARGIN + 0.5)
        # low enough that the ball and the shoulder blade's tip over it clear the shoulder's top by the margin
        cx_ = int(round(BC + side * off))
        col = np.nonzero(om_[:, cx_])[0]
        col = col[col > F["neck"]]
        if len(col): sy = max(sy, col.min() + MARGIN + aw * 0.72 - 0.5)
        shj_of[side] = (BC + side * off, sy)
    # ---- the collar bones: near straight from the breastbone out to the top of each shoulder ball, the shoulder
    # blade's tip (acromion) capping the ball
    for side in (-1, 1):
        hx, hy = shj_of[side]
        ex = hx - side * 0.5
        S.curve("up-torso", [(BC + side * 3, shy + 2.0), ((BC + ex) / 2.0, shy + 0.8), (ex, hy - aw * 0.55)], 2.8, z=3.6)
        S.curve("up-torso", [(ex - side * 1.0, hy - aw * 0.6), (hx + side * aw * 0.55, hy - aw * 0.35)], 2.4, z=3.9)
    # ---- the ribcage, inside the chest's outline: eight pairs from the spine round to the breastbone
    rt, rb, rib, rib_lo = F["rib_top"], F["rib_bot"], F["rib"], F["rib_lo"]
    S.blob("up-torso", M().rect(BC - 1.8, rt - 2, 3.6, rb - rt + 8).get(), z=1.8, bevel=0.8, mat="bone_joint")
    sb = rt + 0.68 * (rb - rt)                  # the breastbone's tip
    reach_ = min(abs(shj_of[-1][0] - BC), abs(shj_of[1][0] - BC)) - aw * 0.7
    # Oct 19 2026 ("bottom of the ribs are too sharp, IRL round out"; the director's pixel references): the cage drawn
    # as one rounded barrel and cut into separate rib bars by curved gaps, the way the references read. Its lower corners
    # are round, and under the breastbone it opens in a smooth arch (the costal arch), so nothing hangs to a point.
    cb = rb + 2.0                               # the cage's foot
    hgt = cb - rt
    # the cage's half width down its height: wide at the top to carry the shoulders (the upper ribs reach the joints,
    # Oct 19 2026), fullest a little above the middle, narrowing to the waist
    ky = [rt, rt + 0.30 * hgt, rt + 0.58 * hgt, cb]
    kw = [reach_ * 0.96, max(rib, reach_ * 0.86), rib, rib_lo]
    R_lo, R_hi = 7.0, 2.5                       # the corners' radii, foot and top
    def half(y):
        w_ = float(np.interp(y, ky, kw))
        if y > cb - R_lo:
            q = (y - (cb - R_lo)) / R_lo
            w_ -= R_lo * (1.0 - math.sqrt(max(0.0, 1.0 - q * q)))
        if y < rt + R_hi:
            q = ((rt + R_hi) - y) / R_hi
            w_ -= R_hi * (1.0 - math.sqrt(max(0.0, 1.0 - q * q)))
        return w_
    arch_w = rib_lo * 0.60                      # the arch's half width at the cage's foot
    cage = np.zeros((H, W), bool)
    for yy in range(int(math.floor(rt)), int(math.ceil(cb)) + 1):
        yc = yy + 0.5
        if yc < rt or yc > cb: continue
        ax = np.abs(d.XX[yy] + 0.5 - BC)
        row = ax <= half(yc)
        if yc > sb:
            row &= ax >= arch_w * math.sqrt((yc - sb) / (cb - sb))
        cage[yy] = row
    # the gaps between the ribs: level at the breastbone, dropping toward the sides, more so lower down
    n = 10
    pitch = hgt / (n + 0.15)
    gaps = M()
    for j in range(1, n):
        yg = rt + j * pitch
        hw_ = half(yg)
        droop = 2.0 + 3.2 * j / (n - 1)
        for side in (-1, 1):
            pts = [(BC + side * x, yg - 0.4 + droop * (x / hw_) ** 1.7) for x in np.linspace(2.0, hw_ + 3.0, 24)]
            gaps.line(pts, 1.5)
    ribs = cage & ~gaps.get(0.45)
    # no slivers: a rib the gaps and the round corner leave too small to read is dropped, not left as a crumb
    lab, nl_ = ndi.label(ribs)
    if nl_:
        sizes = ndi.sum(ribs, lab, range(1, nl_ + 1))
        for i_, sz in enumerate(sizes):
            if sz < 10: ribs[lab == i_ + 1] = False
    S.blob("up-torso", ribs, z=2.6, bevel=1.1)
    # the costal cartilage: the ribs' inner ends along the arch and beside the breastbone a touch darker than bone
    cart = ribs & ~ndi.binary_erosion(cage | ~ribs, iterations=1) & (d.YY > sb)
    d.tex[cart] -= 0.05
    S.blob("up-torso", M().poly([(BC - 3.0, rt + 1), (BC + 3.0, rt + 1), (BC + 2.2, sb - 3), (BC, sb), (BC - 2.2, sb - 3)]).get(),
           z=3.4, bevel=1.2)
    # ---- the lower back: lumbar vertebrae from the ribs to the pelvis
    pt = F["pel_top"]
    nl = 5
    for k in range(nl):
        y = rb + 1 + k * (pt + 3 - rb - 1) / nl
        hgt = max(1.8, (pt + 3 - rb) / nl - 0.6)
        S.blob("low-torso", M().rrect(BC - 3.8, y, 7.6, hgt, 0.8).get(), z=2.8, bevel=1.0)
        for side in (-1, 1):
            S.blob("low-torso", M().rect(BC + side * 3.4 - (1.6 if side < 0 else 0), y + 0.5, 1.6, max(1.0, hgt - 1)).get(),
                   z=2.4, bevel=0.6)

    # ---- the pelvis, inside the hips' outline
    pw = F["pel_w"]
    fl = c["pel_flare"]
    pel_pts = [(BC - pw, pt + 1), (BC - pw * 0.55, pt - 1), (BC - 4, pt + 3), (BC + 4, pt + 3), (BC + pw * 0.55, pt - 1),
               (BC + pw, pt + 1), (BC + pw * 1.02, pt + 8), (BC + pw * 0.72, pt + 14), (BC + pw * 0.70, pt + 22),
               (BC + 5 * fl, pt + 23), (BC + 2.5 * fl, pt + 20), (BC - 2.5 * fl, pt + 20), (BC - 5 * fl, pt + 23),
               (BC - pw * 0.70, pt + 22), (BC - pw * 0.72, pt + 14), (BC - pw * 1.02, pt + 8)]
    # every point inside the body at its own row, two pixels in (Oct 17 2026: the hips poked out of the outline)
    def inside(pt_):
        x, y = pt_
        lim = torso_half(sex, y, BC) - 2.0
        dx = x - BC
        if abs(dx) > lim: dx = math.copysign(max(lim, 0.0), dx)
        return (BC + dx, y)
    pel_pts = [inside(q) for q in pel_pts]
    S.blob("groin", M().poly(pel_pts).get(), z=3.0, bevel=2.2)
    S.hole(M().ellipse(BC, pt + 10, pw * 0.42 * fl ** 0.5, 5.6 * fl ** 0.3).get(), 1.8, 0.45)
    S.blob("groin", M().poly([(BC - 4.2, pt + 3), (BC + 4.2, pt + 3), (BC + 2, pt + 15), (BC - 2, pt + 15)]).get(), z=3.4,
           bevel=1.2, mat="bone_joint")
    for side in (-1, 1):
        S.hole(M().ellipse(BC + side * pw * 0.42, pt + 18.5, 2.8 * fl ** 0.4, 2.4).get(), 1.8, 0.62)

    # ---- a limb's room, row by row: the run of the inner region nearest a guide line, its edges smoothed (Oct 19 2026:
    # the forearms and shins are drawn to fit the room inside the band rather than placed and then shaved by it)
    def room(ya, yb, xa, xb):
        ys_, ls_, rs_ = [], [], []
        for y in range(int(math.ceil(ya)), int(math.floor(yb)) + 1):
            tx = xa + (xb - xa) * (y - ya) / max(1e-6, yb - ya)
            xs = np.nonzero(S.inner[y])[0]
            if not len(xs): continue
            runs_, st = [], xs[0]
            for i_ in range(1, len(xs) + 1):
                if i_ == len(xs) or xs[i_] != xs[i_ - 1] + 1:
                    runs_.append((st, xs[i_ - 1])); st = xs[i_] if i_ < len(xs) else st
            l_, r_ = min(runs_, key=lambda rr: 0 if rr[0] <= tx <= rr[1] else min(abs(rr[0] - tx), abs(rr[1] - tx)))
            if not (l_ - 3 <= tx <= r_ + 3): continue
            ys_.append(y + 0.5); ls_.append(float(l_)); rs_.append(r_ + 1.0)
        if len(ys_) < 3: return None
        ys_ = np.array(ys_)
        deg = 2 if len(ys_) > 8 else 1
        L_ = np.polyval(np.polyfit(ys_, ls_, deg), ys_)
        R_ = np.polyval(np.polyfit(ys_, rs_, deg), ys_)
        # never past the real room on any row
        return ys_, np.maximum(L_, ls_), np.minimum(R_, rs_)
    def strip(rm, side, f0, f1, minw=0.0, cap=None):
        """the part of a limb's room between fractions f0..f1 across it, measured from the body's side (medial); where
        the room is wider than the bones need (cap), they keep their own width, centred in it"""
        ys_, L_, R_ = rm
        left, right = [], []
        for y, l_, r_ in zip(ys_, L_, R_):
            if cap is not None and r_ - l_ > cap:
                c_ = (l_ + r_) / 2.0
                l_, r_ = c_ - cap / 2.0, c_ + cap / 2.0
            a_, b_ = (l_, r_) if side > 0 else (r_, l_)          # from medial to lateral
            p0, p1 = a_ + (b_ - a_) * f0, a_ + (b_ - a_) * f1
            lo, hi = min(p0, p1), max(p0, p1)
            if hi - lo < minw: c_ = (lo + hi) / 2.0; lo, hi = c_ - minw / 2.0, c_ + minw / 2.0
            left.append((lo, y)); right.append((hi, y))
        return M().poly(left + right[::-1]).get()

    # ---- the arms, down each arm's centre line in the outline
    aw = F["arm"]
    for side in (-1, 1):
        sfx = "r" if side < 0 else "l"
        Fs = F["side"][side]
        shj = shj_of[side]
        S.blob(f"bicep-{sfx}", disc(d, shj[0], shj[1], aw * 0.72), z=3.8, bevel=1.4, mat="bone")       # the shoulder ball
        el = (BC + side * Fs["elbow"], F["el_y"])
        wr = (BC + side * Fs["wrist"], F["wr_y"])
        S.bone(f"bicep-{sfx}", shj, el, aw, aw * 0.9, z=3.4)
        # the forearm's two bones side by side in the room the band leaves, or one where it is too slim for two
        rm = room(el[1] + 2.0, wr[1] + 0.5, el[0], wr[0])
        if rm is not None:
            if float(np.median(rm[2] - rm[1])) >= 5.0:
                S.blob(f"wrist-{sfx}", strip(rm, side, 0.0, 0.46, cap=aw * 1.3), z=3.2, bevel=1.0)
                S.blob(f"wrist-{sfx}", strip(rm, side, 0.58, 1.0, cap=aw * 1.3), z=3.0, bevel=1.0)
            else:
                S.blob(f"wrist-{sfx}", strip(rm, side, 0.0, 1.0, 1.6, cap=aw * 0.8), z=3.1, bevel=0.9)
        # the hand: the wrist's little bones, then the fingers spread across the hand's own width in the outline, row by
        # row down to its fingertips, so they follow its bend and stay inside it (Oct 17 2026)
        om = S.inner                      # the hand's room inside the band (Oct 19 2026)
        rows_ = []
        tx = wr[0]
        for y in range(int(round(wr[1])) + 2, F["fing"]):
            xs = np.nonzero(om[y])[0]
            if not len(xs): break
            # the run nearest the tracked hand line
            runs_, st = [], xs[0]
            for i_ in range(1, len(xs) + 1):
                if i_ == len(xs) or xs[i_] != xs[i_ - 1] + 1:
                    runs_.append((st, xs[i_ - 1])); st = xs[i_] if i_ < len(xs) else st
            l_, r_ = min(runs_, key=lambda rr: 0 if rr[0] <= tx <= rr[1] else min(abs(rr[0] - tx), abs(rr[1] - tx)))
            if not (l_ - 3 <= tx <= r_ + 3): break
            rows_.append((y, l_, r_))
            tx = (l_ + r_) / 2.0
        hc = (wr[0], wr[1] + 3.0)
        S.blob(f"hand-{sfx}", M().ellipse(hc[0], hc[1], min(3.0, aw * 0.6), 2.2).get(), z=3.0, bevel=1.2, mat="bone_joint")
        if rows_:
            top_y = rows_[0][0] + 2
            tip_y = rows_[-1][0]
            for k, frac in enumerate((0.22, 0.42, 0.62, 0.82)):
                ln_end = tip_y - (1.5, 0.3, 0.0, 1.2)[k]
                pts = []
                for (y, l_, r_) in rows_:
                    if y < top_y or y > ln_end: continue
                    f_ = frac if side > 0 else 1.0 - frac            # the little finger on the outside of each hand
                    pts.append((l_ + 0.5 + (r_ - l_) * f_, y + 0.5))
                if len(pts) >= 2:
                    mid_ = len(pts) // 2
                    S.curve(f"hand-{sfx}", pts[:mid_ + 1], 1.5, z=3.2)
                    S.curve(f"hand-{sfx}", pts[mid_:], 1.2, z=3.3)
                    d.seam(disc(d, pts[mid_][0], pts[mid_][1], 0.6), 0.25)
            # the thumb toward the body, shorter
            th = [(l_ + 0.5 + (r_ - l_) * (0.10 if side > 0 else 0.90), y + 0.5) for (y, l_, r_) in rows_
                  if top_y - 2 <= y <= top_y - 2 + (tip_y - top_y) * 0.55]
            if len(th) >= 2: S.curve(f"hand-{sfx}", th, 1.5, z=3.2)

    # ---- the legs, down each leg's centre line
    for side in (-1, 1):
        sfx = "r" if side < 0 else "l"
        Fs = F["side"][side]
        hip = (BC + side * Fs["hip"], F["hip_y"])
        top = (BC + side * Fs["troch"], F["hip_y"] + 5)
        knee = (BC + side * Fs["knee"], F["knee_y"])
        ank = (BC + side * Fs["ankle"], F["ankle_y"])
        fw, tw = F["femur"], F["tibia"]
        S.blob(f"thigh-{sfx}", disc(d, hip[0], hip[1], fw * 0.5), z=3.6, bevel=1.4)
        S.curve(f"thigh-{sfx}", [hip, top], fw * 0.55, z=3.4)
        S.blob(f"thigh-{sfx}", disc(d, top[0] + side * 1.4, top[1] - 0.5, fw * 0.32), z=3.2, bevel=1.0, mat="bone_joint")
        S.bone(f"thigh-{sfx}", top, (knee[0], knee[1] - 2), fw * 0.92, fw * 1.05, z=3.4)
        S.blob(f"ankle-{sfx}", disc(d, knee[0], knee[1] + 1, fw * 0.48), z=4.2, bevel=1.4, mat="bone_joint")    # kneecap
        # the shin: the tibia on the inside, the slim fibula outside it, both in the room the band leaves
        rm = room(knee[1] + 4.0, ank[1] + 0.5, knee[0], ank[0])
        if rm is not None:
            if float(np.median(rm[2] - rm[1])) >= 6.0:
                S.blob(f"ankle-{sfx}", strip(rm, side, 0.0, 0.66, cap=tw * 1.25), z=3.4, bevel=1.4)
                S.blob(f"ankle-{sfx}", strip(rm, side, 0.78, 1.0, 1.4, cap=tw * 1.25), z=3.0, bevel=0.8)
            else:
                S.blob(f"ankle-{sfx}", strip(rm, side, 0.0, 1.0, 1.6, cap=tw * 0.9), z=3.3, bevel=1.1)
        # the foot from the front, down to the outline's soles
        fb = F["bot"] - 1
        S.blob(f"foot-{sfx}", M().ellipse(ank[0], ank[1] + 4, 4.0, 2.6).get(), z=3.4, bevel=1.4, mat="bone_joint")
        for k in range(5):
            p0 = (ank[0] + side * (-2.4 + 1.3 * k), ank[1] + 6.0)
            p1 = (ank[0] + side * (-3.2 + 1.7 * k + 0.4 * (k - 1)), fb - abs(k - 1) * 0.8)
            S.curve(f"foot-{sfx}", [p0, p1], 1.7 if k == 0 else 1.4, z=3.3)

    # ---- every bone inside the body's outline, MARGIN pixels in (Oct 17, Oct 19 2026), so nothing touches its edge
    d.solid &= S.inner
    S.owner[~d.solid] = 0
    return S


# ---------------------------------------------------------------------------
# the flesh outline: soft capsules round the bones, wider at the hips on her, a waist, the chest's contour
# ---------------------------------------------------------------------------
def silhouette(sex):
    """the body's outline: the game's own body, traced (ref/outline_<s>.png)"""
    return outline(sex)


# ---------------------------------------------------------------------------
# the perspective grid: a room seen from the front, its back wall a grid, floor, ceiling and walls converging
# ---------------------------------------------------------------------------
def grid(light):
    """tone image (0..1 per pixel) for the room: drawn tinted by the theme. Every line exactly one pixel wide (Oct 17
    2026, director: "can those lines be even and fix line weights"): the back wall a grid of even 16-pixel squares, the
    floor, ceiling and side walls running from each of its grid lines out to the frame, three depth bands evenly spaced
    between the back wall and the frame. Two weights: the frame, the room's corners and the back wall's edge brighter,
    everything else one softer tone"""
    a = np.zeros((H, W), np.float32)
    FRAME, GRID = 0.46, 0.20

    def px_line(x0, y0, x1, y1, v):
        # Bresenham: one pixel per step, never doubled
        x0, y0, x1, y1 = int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))
        dx, sx = abs(x1 - x0), (1 if x0 < x1 else -1)
        dy, sy = -abs(y1 - y0), (1 if y0 < y1 else -1)
        e = dx + dy
        while True:
            if 0 <= x0 < W and 0 <= y0 < H: a[y0, x0] = max(a[y0, x0], v)
            if x0 == x1 and y0 == y1: break
            e2 = 2 * e
            if e2 >= dy: e += dy; x0 += sx
            if e2 <= dx: e += dx; y0 += sy

    CELL_ = 16
    bx0, bx1 = 22, 22 + CELL_ * 11                # 22 .. 198
    by0, by1 = 26, 26 + CELL_ * 13                # 26 .. 234
    X1, Y1 = W - 1, H - 1
    # the floor, ceiling and side walls: from each back-wall grid line straight out to the frame
    def out_x(x): return (x - (bx0 + bx1) / 2.0) * X1 / (bx1 - bx0) + X1 / 2.0
    def out_y(y): return (y - (by0 + by1) / 2.0) * Y1 / (by1 - by0) + Y1 / 2.0
    for x in range(bx0 + CELL_, bx1, CELL_):
        px_line(x, by1, out_x(x), Y1, GRID)
        px_line(x, by0, out_x(x), 0, GRID)
    for y in range(by0 + CELL_, by1, CELL_):
        px_line(bx0, y, 0, out_y(y), GRID)
        px_line(bx1, y, X1, out_y(y), GRID)
    # three depth bands, evenly spaced between the back wall and the frame
    for t in (0.25, 0.5, 0.75):
        xx0, xx1 = bx0 * (1 - t), bx1 + (X1 - bx1) * t
        yt, yb = by0 * (1 - t), by1 + (Y1 - by1) * t
        px_line(xx0, yt, xx1, yt, GRID); px_line(xx0, yb, xx1, yb, GRID)
        px_line(xx0, yt, xx0, yb, GRID); px_line(xx1, yt, xx1, yb, GRID)
    # the back wall's grid
    for x in range(bx0 + CELL_, bx1, CELL_): px_line(x, by0, x, by1, GRID)
    for y in range(by0 + CELL_, by1, CELL_): px_line(bx0, y, bx1, y, GRID)
    # the brighter lines: the room's corners, the back wall's edge, the frame
    for (x0, y0, x1, y1) in ((0, 0, bx0, by0), (X1, 0, bx1, by0), (0, Y1, bx0, by1), (X1, Y1, bx1, by1)):
        px_line(x0, y0, x1, y1, FRAME)
    for (x0, y0, x1, y1) in ((bx0, by0, bx1, by0), (bx0, by1, bx1, by1), (bx0, by0, bx0, by1), (bx1, by0, bx1, by1)):
        px_line(x0, y0, x1, y1, FRAME)
    a[0, :] = FRAME; a[-1, :] = FRAME; a[:, 0] = FRAME; a[:, -1] = FRAME
    return a


def background(sex, light):
    """the grid plus the flesh outline, as a white (dark themes) or near-black (light theme) picture with alpha; the
    game tints it with the theme's colour"""
    g = grid(light)
    sil = silhouette(sex)
    # the silhouette: a faint fill (hiding the grid behind the body a little) and a crisp one-pixel edge
    edge = sil & ~ndi.binary_erosion(sil)
    out_a = np.where(sil, 0.15, g)
    out_a = np.where(edge, 0.62, out_a)
    img = np.zeros((H, W, 4), np.uint8)
    col = (24, 24, 26) if light else (255, 255, 255)
    img[..., :3] = col
    img[..., 3] = np.clip(out_a * 255, 0, 255).astype(np.uint8)
    # the body's fill a touch lighter (dark themes) / darker (light theme) than the room so the figure stands forward
    return Image.fromarray(img, "RGBA")


# ---------------------------------------------------------------------------
def render(sex):
    """the lit skeleton, and each part's own pixels (owner of the topmost bone; the outline ring goes with the part
    it rings)"""
    S = build(sex)
    img = S.d.render(chrome_env="room")
    a = np.array(img)
    owner = S.owner.copy()
    # the outline ring belongs to the nearest part
    sol = S.d.solid
    ring_ = (a[..., 3] > 0) & ~sol
    if ring_.any():
        _, (iy, ix) = ndi.distance_transform_edt(owner == 0, return_indices=True)
        owner = np.where(ring_, owner[iy, ix], owner)
    parts = {}
    for p in PARTS:
        m = owner == PID[p]
        pa = np.zeros_like(a)
        pa[m] = a[m]
        parts[p] = Image.fromarray(pa, "RGBA")
    return img, parts, owner


def hit_rects(owner, pad=3):
    out = {}
    for p in PARTS:
        ys, xs = np.nonzero(owner == PID[p])
        if len(xs) == 0: continue
        out[p] = (int(xs.min()) - pad, int(ys.min()) - pad, int(xs.max() - xs.min() + 1) + 2 * pad,
                  int(ys.max() - ys.min() + 1) + 2 * pad)
    return out


CELL, REACH = 2, 4


def hit_map(owner):
    """which part a click lands on: one character per CELL x CELL cell ('a' = the first part in PARTS, '.' = none), the
    part whose bones are nearest within REACH pixels (so a click just beside a thin bone still counts)"""
    dist, (iy, ix) = ndi.distance_transform_edt(owner == 0, return_indices=True)
    near = np.where(dist <= REACH, owner[iy, ix], 0)
    # a cell's vote is weighted toward the smaller parts, so a thin one (the neck) is not outvoted at its edges by the
    # big parts beside it
    area = np.bincount(owner.ravel(), minlength=len(PARTS) + 1).astype(np.float64)
    wgt = np.where(area > 0, 1.0 / np.sqrt(np.maximum(area, 1)), 0.0)
    rows = []
    for y in range(0, H, CELL):
        row = []
        for x in range(0, W, CELL):
            cell = near[y:y + CELL, x:x + CELL].ravel()
            cell = cell[cell > 0]
            if len(cell):
                votes = np.bincount(cell, minlength=len(PARTS) + 1) * wgt
                row.append(chr(96 + int(votes.argmax())))
            else:
                row.append(".")
        rows.append("".join(row))
    return rows


def layout_lua(rects_by_sex, maps_by_sex=None):
    """the Lua tables of each part's hit rectangle, per sex (drawn into ZeD_BodyFigure.lua)"""
    lines = []
    for sex in ("m", "f"):
        lines.append(f"local {sex.upper()}_HITS = {{   -- generated by d_skeleton.py: each part's pixels plus 3")
        for p in PARTS:
            x, y, w, h = rects_by_sex[sex][p]
            lines.append(f'    ["{p}"] = {{ x = {x}, y = {y}, w = {w}, h = {h} }},')
        lines.append("}")
    if maps_by_sex:
        for sex in ("m", "f"):
            lines.append(f"local {sex.upper()}_HITMAP = {{   -- generated by d_skeleton.py: the part under each {CELL} x {CELL} cell")
            for r in maps_by_sex[sex]:
                lines.append(f'    "{r}",')
            lines.append("}")
    return "\n".join(lines)


def export(root):
    dd = os.path.join(root, "42", "media", "textures", "ZeD", "body")
    os.makedirs(dd, exist_ok=True)
    rects, maps = {}, {}
    for sex in ("m", "f"):
        img, parts, owner = render(sex)
        img.save(os.path.join(dd, f"{sex}-skeleton.png"))
        for p, im in parts.items():
            im.save(os.path.join(dd, f"{sex}-{p}.png"))
        for light in (False, True):
            background(sex, light).save(os.path.join(dd, f"fig-bg-{sex}-{'light' if light else 'dark'}.png"))
        rects[sex] = hit_rects(owner)
        maps[sex] = hit_map(owner)
    with open(os.path.join(dd, "_layout.lua.txt"), "w") as f:
        f.write(layout_lua(rects, maps) + "\n")
    print("wrote the skeletons, parts and backgrounds to", dd)
    return rects


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "mod", "ZeD-UI"))
