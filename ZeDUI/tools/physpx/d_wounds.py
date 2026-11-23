"""The body figure's wounds and their care (director, Nov 22 2026): "In the health panel, when there is an injury, is
that injury visible on the skeleton? Is the bandage visible on that skeleton?" and then "for flesh wounds and stitches
and such, can we add a little skin that kind of fades out back to the skeleton just to show that it's a surface injury
and not a skeletal injury?"

Each kind of wound gets a mark on its part, and each kind of care shows: gauze wrapped round the part (blood come through
when the bandage is dirty), stitches, two boards tied along a splinted part. A fracture is a crack in the bone itself. A
surface wound sits on a patch of the character's own skin that fades back to the flesh and bones, so it reads as on the
body, not in the bone. The bones keep their tint by severity, as now; the wounds go over it.

Exports (media/textures/ZeD/body/wounds/), drawn by ZeD_BodyFigure over the parts:
  <s>-<part>-bandage.png, <s>-<part>-bandage-dirty.png    the gauze (and its shadow), cut to its own box
  <s>-<part>-fracture.png                                 the crack across the part's bone
  <s>-<part>-splint.png                                   the boards and their ties (not the head, chest or belly:
                                                          the game splints neither)
  <s>-<part>-skin<n>[b].png                               the skin under n marks (1 or 2), b with the bleeding under
                                                          them; white, shaded, drawn tinted by the skin tone
  mark-<kind>.png, mark-<kind>-infected.png               the marks, 15 x 15, their middle at (7, 7); the infected
                                                          ring goes under its mark
  _wounds.lua.txt                                         ZeD_BodyFigure.lua's tables: where each picture goes
s = m / f. Everything is placed from the part's own bones and its share of the traced body. usage: python d_wounds.py
[mod root]"""
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

import d_skeleton as S

PARTS = S.PARTS
LIMBS = {"bicep-r", "bicep-l", "wrist-r", "wrist-l", "thigh-r", "thigh-l", "ankle-r", "ankle-l"}
ENDS = {"hand-r", "hand-l", "foot-r", "foot-l"}
NO_SPLINT = {"head", "up-torso", "low-torso"}       # vanilla's HSplint: "can't splint chest/head"

# ---- the marks' colors: part of the art, the same in both themes (as the bones and the flesh are)
C = {
    "R": (222, 56, 44),     # blood, fresh
    "r": (164, 30, 30),     # blood
    "k": (96, 14, 18),      # blood, dark
    "H": (40, 6, 10),       # the deep of a wound
    "T": (24, 22, 30),      # thread
    "p": (196, 90, 86),     # the closed cut under the stitches
    "B": (206, 104, 60),    # burn, raw
    "b": (52, 30, 24),      # burn, charred
    "y": (238, 192, 146),   # burn, blister
    "G": (214, 240, 246),   # glass
    "c": (112, 164, 188),   # glass, its edge
}
INFECTION = (150, 176, 58)                  # the ring round an infected wound
RIM, RIM_A = (88, 22, 26), 0.85             # a wound's dark edge on the skin (wine, not black)
RIMS = {"glass": ((36, 56, 70), 0.85)}
GAUZE = [(244, 240, 230), (214, 208, 196), (170, 162, 150), (118, 110, 100)]   # light, shade, fold, rim
WOOD = [(196, 150, 92), (150, 106, 60), (98, 66, 36)]                          # top, face, rim
DIRTY = [(150, 34, 28), (122, 24, 22), (184, 128, 92)]                         # the blot, its heart, its seep
# the dirty gauze's noise lies on the body, not on the frame: one field over the build canvas's rows -16 to 255 and
# columns 50 to 155 (the frame as it stood when the director passed the wounds, Nov 22 2026), cut to the frame where it
# stands now, so moving the frame (Nov 23 2026: 18 rows up) leaves the blood's edge as it was
DIRTY_NOISE = dict(top=-16, left=50, shape=(272, 106), seed=3, sigma=1.2)
CRACK = (44, 26, 20)
CHIP = (246, 238, 214)                      # the broken bone's edge, catching the light
SHADOW_A = 0.35                             # gauze and boards cast a pixel of shadow down and right, on the body

# ---- the marks, drawn upright ('.' = nothing); each sits on a 15 x 15 picture with its middle at (7, 7)
SPRITES = {
    "scratch": ["...R..R..R",
                "..R..R..R.",
                ".R..R..R..",
                "R..R..R..."],
    "cut":     [".....kR",
                "....kRk",
                "...kRk.",
                "..kRk..",
                ".kRk...",
                "kRk....",
                "Rk....."],
    "deep":    ["..k..",
                ".kRk.",
                "kRHRk",
                "kRHRk",
                "kRHRk",
                "kRHRk",
                ".kRk.",
                "..k.."],
    "bite":    [".R.R.R.",            # the teeth's two arcs, a mouth wide
                "R.....R",
                ".......",
                ".......",
                "R.....R",
                ".R.R.R."],
    "bleed":   ["R...",
                "R..R",
                "R..R",
                "RR.R",
                "RR..",
                "...R",
                "..RR",
                "..RR"],
    "burn":    ["..bb...",
                ".bBBb..",
                "bByBBb.",
                "bBBByBb",
                ".bBBBb.",
                "..bbb.."],
    "bullet":  [".rr.",
                "rHHr",
                "rHHr",
                ".rr."],
    "glass":   ["G....",
                "Gc...",
                "...G.",
                "..Gc.",
                "....."],
    "stitch":  ["T.T",
                ".p.",
                "T.T",
                ".p.",
                "T.T",
                ".p.",
                "T.T"],
}
KINDS = ["bite", "deep", "stitch", "bullet", "glass", "cut", "burn", "scratch"]   # most serious first
RIMMED = {"scratch", "cut", "deep", "bite", "bleed", "burn", "bullet", "glass"}
MARK_N, MARK_C = 15, 7                      # a mark's picture and its middle
BLEED_DX, BLEED_DY = 1, 6                   # the bleeding hangs this far right and below the wound above it

# ---- skin: the game's five tones (the middle of media/textures/Body/MaleBody01..05.png), warmed and taken down a
# little as the 3D model's lighting does, so the palest still parts from the ivory bone. The patch is white, shaded as
# a low dome lit from the top left in four steps; the game tints it by the character's tone, so each step comes out as
# the tone times the step.
GAME_TONES = [(248, 224, 183), (238, 198, 140), (206, 166, 115), (131, 93, 60), (89, 65, 35)]
WARM = (0.95, 0.86, 0.84)
SKIN_STEPS = (255, 227, 191, 158)           # light, the tone itself, shade, deep (227 / 255 = the tone)
SKIN_CORE, SKIN_OUTER = 2.5, 5.5            # solid this far from the marks, gone by this far: see-through steps between
SKIN_FOOT = 3.0                             # each mark's place counts as a disc this wide round its middle


def skin_tints():
    """the tint for each of the game's skin tones (getSkinTextureIndex 0..4), 0..1: tone / (227 / 255), at most 1"""
    out = []
    for tone in GAME_TONES:
        mid = [v * w for v, w in zip(tone, WARM)]
        out.append(tuple(round(min(1.0, m / SKIN_STEPS[1]), 3) for m in mid))
    return out


# ---------------------------------------------------------------------------
# the body: each part's bones and its share of the flesh
# ---------------------------------------------------------------------------
class Body:
    def __init__(s, sex):
        s.sex = sex
        _, _, owner = S.render(sex)
        s.sil = S.silhouette(sex)
        s.inside = ndi.binary_erosion(s.sil)             # the flesh's own pixels (d_flesh), inside the outline's line
        s.bones = {p: owner == S.PID[p] for p in PARTS}
        # each part's flesh: grown out from its bones through the body only, so an arm's flesh never jumps the gap to
        # the flank beside it
        lab = owner.astype(np.int32).copy()
        allowed = s.inside | (owner > 0)
        four = ndi.generate_binary_structure(2, 1)
        for _ in range(80):
            free = allowed & (lab == 0)
            if not free.any():
                break
            grow = np.zeros_like(lab)
            for i in range(1, len(PARTS) + 1):
                g = ndi.binary_dilation(lab == i, structure=four) & free & (grow == 0)
                grow[g] = i
            if not grow.any():
                break
            lab[grow > 0] = grow[grow > 0]
        s.region = {p: lab == S.PID[p] for p in PARTS}
        s.YY, s.XX = np.mgrid[0:S.FH, 0:S.FW]
        s.axis = {}
        for p in PARTS:
            ys, xs = np.nonzero(s.region[p])
            c = np.array([xs.mean() + 0.5, ys.mean() + 0.5])
            _, evec = np.linalg.eigh(np.cov(np.vstack([xs, ys]).astype(np.float64)))
            u = evec[:, 1]
            if u[1] < 0:
                u = -u                                    # pointing down the body
            s.axis[p] = (c, u)

    def coords(s, p):
        """each pixel's place along the part (t, 0 at its middle) and across it (v), in pixels"""
        (cx, cy), (ux, uy) = s.axis[p]
        dx, dy = s.XX + 0.5 - cx, s.YY + 0.5 - cy
        return dx * ux + dy * uy, dx * -uy + dy * ux

    def slots(s, p):
        """where the marks' middles go: [[one mark], [first, second]], whole pixels; the second lower on the part"""
        (cx, cy), (ux, uy) = s.axis[p]
        t, _ = s.coords(p)
        ts = t[s.region[p]]
        L = ts.max() - ts.min()
        if p == "head":                                   # on the brow, not the nose
            k = ts.min() + 0.36 * L
            cx, cy = cx + ux * k, cy + uy * k
        step = min(9.0, 0.32 * L)
        one = [(int(math.floor(cx + 0.5)), int(math.floor(cy + 0.5)))]
        two = [(int(math.floor(cx + ux * o + 0.5)), int(math.floor(cy + uy * o + 0.5))) for o in (-step / 2, step / 2)]
        return [one, two]


# ---------------------------------------------------------------------------
# the pictures
# ---------------------------------------------------------------------------
def sprite(kind):
    """a mark's 15 x 15 RGBA picture (0..1), its middle at (7, 7), its rim round it"""
    rows = SPRITES[kind]
    h, w = len(rows), len(rows[0])
    x0, y0 = MARK_C - w // 2, MARK_C - h // 2
    lay = np.zeros((MARK_N, MARK_N, 4), np.float32)
    m = np.zeros((MARK_N, MARK_N), bool)
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch != ".":
                lay[y0 + j, x0 + i, :3] = np.array(C[ch]) / 255.0
                lay[y0 + j, x0 + i, 3] = 1.0
                m[y0 + j, x0 + i] = True
    if kind in RIMMED:
        ring = ndi.binary_dilation(m) & ~m
        col, a = RIMS.get(kind, (RIM, RIM_A))
        lay[ring, :3] = np.array(col) / 255.0
        lay[ring, 3] = a
    return lay


def halo(kind):
    """the yellow-green ring round an infected mark: two pixels out from the mark's own pixels and rim"""
    m = sprite(kind)[..., 3] > 0
    ring = ndi.binary_dilation(m, iterations=2) & ~m
    lay = np.zeros((MARK_N, MARK_N, 4), np.float32)
    lay[ring, :3] = np.array(INFECTION) / 255.0
    lay[ring, 3] = 0.85
    return lay


def place_sprite(kind, cx, cy, shape):
    """a mark's picture laid on a frame-sized layer with its middle at (cx, cy)"""
    out = np.zeros(shape + (4,), np.float32)
    spr = sprite(kind)
    x0, y0 = cx - MARK_C, cy - MARK_C
    ys, xs = np.nonzero(spr[..., 3] > 0)
    for y, x in zip(ys, xs):
        if 0 <= y0 + y < shape[0] and 0 <= x0 + x < shape[1]:
            out[y0 + y, x0 + x] = spr[y, x]
    return out


def shadow_of(mask, body):
    """a pixel of shadow down and right of a mask, on the body only"""
    sh = np.zeros_like(mask)
    sh[1:, 1:] = mask[:-1, :-1]
    return sh & ~mask & body.inside


def dirty_noise():
    """the dirty gauze's noise in the frame (FH x FW): a smoothed, normalized random field laid on the body"""
    n = DIRTY_NOISE
    rnd = ndi.gaussian_filter(np.random.default_rng(n["seed"]).random(n["shape"]), n["sigma"])
    rnd = (rnd - rnd.mean()) / (rnd.std() + 1e-6)
    y0, x0 = -S.DY - n["top"], -S.DX - n["left"]          # the frame's (0, 0) in the field
    assert 0 <= y0 and y0 + S.FH <= n["shape"][0] and 0 <= x0 and x0 + S.FW <= n["shape"][1], (y0, x0)
    return rnd[y0:y0 + S.FH, x0:x0 + S.FW]


def bandage(body, p, dirty=False):
    """gauze wrapped round the middle of the part, a pixel proud of the body either side; the turns run on the slant"""
    reg = body.region[p]
    t, v = body.coords(p)
    ts = t[reg]
    lo, hi = ts.min(), ts.max()
    if p in LIMBS:
        keep = (t > lo + 0.16 * (hi - lo)) & (t < hi - 0.16 * (hi - lo))
    elif p == "head":
        keep = (t > lo + 0.10 * (hi - lo)) & (t < lo + 0.34 * (hi - lo))          # round the brow
    elif p in ENDS:
        keep = (t > lo + 0.05 * (hi - lo)) & (t < lo + 0.55 * (hi - lo))
    else:
        keep = (t > lo + 0.25 * (hi - lo)) & (t < hi - 0.25 * (hi - lo))
    core = reg & keep
    m = ndi.binary_dilation(core) & keep
    # shaded as a round limb lit from the top left: light, then shade toward the right edge, a fold where each turn
    # laps the next
    left = np.full(m.shape, 1e9)
    right = np.full(m.shape, -1e9)
    for y in np.unique(body.YY[m]):
        xs = body.XX[y][m[y]]
        left[y], right[y] = xs.min(), xs.max()
    across = np.clip((body.XX - left) / np.maximum(1, right - left), 0, 1)
    col = np.zeros(m.shape + (3,), np.float32) + np.array(GAUZE[0], np.float32)
    col[across > 0.58] = GAUZE[1]
    col[across > 0.86] = GAUZE[2]
    turn = np.floor((t - 0.5 * v) / 3.0)
    fold = np.diff(turn, axis=0, prepend=turn[:1]) != 0
    col[fold & (across <= 0.58)] = GAUZE[1]
    col[fold & (across > 0.58)] = GAUZE[2]
    lay = np.zeros(m.shape + (4,), np.float32)
    lay[m, :3] = col[m] / 255.0
    lay[m, 3] = 1.0
    ring = ndi.binary_dilation(m) & ~m
    lay[ring, :3] = np.array(GAUZE[3]) / 255.0
    lay[ring, 3] = 0.9
    sh = shadow_of(m | ring, body)
    lay[sh, :3] = 0.0
    lay[sh, 3] = SHADOW_A
    if dirty:                                     # the blood come through in the middle, soaked to an uneven edge
        ys_, xs_ = np.nonzero(m)
        cx, cy = xs_.mean() + 0.5, ys_.mean() + 0.5   # (the gauze's own middle: the head's is above the face)
        r = np.hypot(body.XX + 0.5 - cx, (body.YY + 0.5 - cy) / 1.4)
        rnd = dirty_noise()                       # (on the body: the same blood wherever the frame stands)

        def one(mask):                            # the piece round the middle only, no spatter
            lab, _ = ndi.label(mask)
            k = lab[int(cy), int(cx)]
            return lab == k if k else mask
        for f, a, col_ in ((4.3, 0.7, DIRTY[2]), (3.0, 0.6, DIRTY[0]), (1.4, 0.3, DIRTY[1])):
            blot = one(m & (r < f + a * rnd))
            lay[blot, :3] = np.array(col_) / 255.0
    return lay


def splint(body, p):
    """two boards along the part either side of the bone, tied on twice"""
    reg = body.region[p]
    t, v = body.coords(p)
    ts, vs = t[reg], v[reg]
    lo, hi = ts.min(), ts.max()
    vlo, vhi = np.percentile(vs, 4), np.percentile(vs, 96)
    span = (t > lo + 0.08 * (hi - lo)) & (t < hi - 0.08 * (hi - lo))
    lay = np.zeros(reg.shape + (4,), np.float32)
    boards = np.zeros(reg.shape, bool)
    for edge in (vlo - 0.5, vhi - 1.5):                   # each board 2 px wide, at the part's edges
        b = span & (v >= edge) & (v < edge + 2.0)
        boards |= b
        lay[b, :3] = np.array(WOOD[1]) / 255.0
        lay[b & (v < edge + 1.0), :3] = np.array(WOOD[0]) / 255.0
    lay[boards, 3] = 1.0
    ties = np.zeros(reg.shape, bool)
    for f in (0.30, 0.70):
        tt = lo + f * (hi - lo)
        ties |= (t >= tt - 1.0) & (t < tt + 1.0) & (v >= vlo - 0.5) & (v < vhi + 0.5)
    lay[ties, :3] = np.array(GAUZE[0]) / 255.0
    lay[ties, 3] = 1.0
    m = boards | ties
    ring = ndi.binary_dilation(m) & ~m
    lay[ring, :3] = np.array(WOOD[2]) / 255.0
    lay[ring, 3] = 0.9
    sh = shadow_of(m | ring, body)
    lay[sh, :3] = 0.0
    lay[sh, 3] = SHADOW_A
    return lay


def fracture(body, p):
    """a zig-zag crack across the part's bone where its marks go, at most 9 pixels long"""
    (sx, sy) = body.slots(p)[0][0]
    t, v = body.coords(p)
    (cx, cy), (ux, uy) = body.axis[p]
    t0 = (sx + 0.5 - cx) * ux + (sy + 0.5 - cy) * uy
    v0 = (sx + 0.5 - cx) * -uy + (sy + 0.5 - cy) * ux
    bone = body.bones[p]
    zig = np.array([0.0, 1.0, 2.0, 1.0])[(np.floor(v).astype(int)) % 4]    # up and down over two rows
    reach = np.abs(v - v0) <= 4.5
    crack = bone & reach & (np.abs(t - t0 - zig) < 0.55)
    # a pixel of broken edge catching the light just above the crack (toward the head), where there is bone
    above = np.zeros_like(crack)
    above[:-1, :] = crack[1:, :]
    chip = above & bone & ~crack
    lay = np.zeros(bone.shape + (4,), np.float32)
    lay[chip, :3] = np.array(CHIP) / 255.0
    lay[chip, 3] = 1.0
    lay[crack, :3] = np.array(CRACK) / 255.0
    lay[crack, 3] = 1.0
    return lay


def skin(body, p, n, bleed):
    """the skin under n marks (and the bleeding under the last, if bleed): white, shaded as a low dome, solid near the
    marks and fading out in see-through steps; never over the outline's line"""
    slots = body.slots(p)[n - 1]
    foot = np.zeros(body.inside.shape, bool)
    for (cx, cy) in slots:
        foot |= np.hypot(body.XX - cx, body.YY - cy) <= SKIN_FOOT
    if bleed:
        lx, ly = slots[-1]
        foot |= place_sprite("bleed", lx + BLEED_DX, ly + BLEED_DY, body.inside.shape)[..., 3] > 0
    dist = ndi.distance_transform_edt(~foot)
    fade = np.clip((SKIN_OUTER - dist) / (SKIN_OUTER - SKIN_CORE), 0, 1)
    keep = (dist < SKIN_OUTER) & body.inside
    alpha = np.where(dist <= SKIN_CORE, 1.0, np.ceil(fade * 3) / 4)
    ys, xs = np.nonzero(foot)
    cx, cy = xs.mean() + 0.5, ys.mean() + 0.5
    R = max(3.0, np.hypot(xs + 0.5 - cx, ys + 0.5 - cy).max() + SKIN_OUTER)
    dx, dy = (body.XX + 0.5 - cx) / R, (body.YY + 0.5 - cy) / R
    nz = np.sqrt(np.clip(1 - dx * dx - dy * dy, 0.05, 1))
    L = np.array([-0.45, -1.0, 0.95])
    L /= np.linalg.norm(L)
    lit = (dx * L[0] + dy * L[1] + nz * L[2]) / np.sqrt(dx * dx + dy * dy + nz * nz)
    step = np.where(lit > 0.93, 0, np.where(lit > 0.70, 1, np.where(lit > 0.45, 2, 3)))
    gray = np.array(SKIN_STEPS, np.float32)[step] / 255.0
    lay = np.zeros(body.inside.shape + (4,), np.float32)
    lay[keep, 0] = lay[keep, 1] = lay[keep, 2] = gray[keep]
    lay[keep, 3] = alpha[keep]
    return lay


# ---------------------------------------------------------------------------
# export
# ---------------------------------------------------------------------------
def to_png(lay):
    return Image.fromarray(np.clip(np.round(lay * 255), 0, 255).astype(np.uint8), "RGBA")


def crop(lay):
    """a frame-sized layer cut to its drawn pixels: (picture, x, y)"""
    ys, xs = np.nonzero(lay[..., 3] > 0)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    return lay[y0:y1, x0:x1], int(x0), int(y0)


def pictures(body):
    """every per-part picture for one body: {part: {name: (layer, x, y)}} and each part's mark places"""
    out, places = {}, {}
    for p in PARTS:
        pics = {"bandage": crop(bandage(body, p)), "bandage-dirty": crop(bandage(body, p, dirty=True)),
                "fracture": crop(fracture(body, p))}
        if p not in NO_SPLINT:
            pics["splint"] = crop(splint(body, p))
        for n in (1, 2):
            for b in (False, True):
                pics[f"skin{n}{'b' if b else ''}"] = crop(skin(body, p, n, b))
        out[p] = pics
        places[p] = body.slots(p)
    return out, places


def lua_tables(pics_by_sex, places_by_sex):
    """ZeD_BodyFigure.lua's generated tables: each part's pictures' top left corners and its marks' middles"""
    tints = skin_tints()
    L = [f"-- generated by d_wounds.py for the {S.FW} x {S.FH} canvas",
         'local WOUND_DIR = "media/textures/ZeD/body/wounds/"',
         f"local MARK_C = {MARK_C}                  -- a mark's picture is {MARK_N} x {MARK_N}, its middle at ({MARK_C}, {MARK_C})",
         f"local BLEED_DX, BLEED_DY = {BLEED_DX}, {BLEED_DY}       -- the bleeding hangs this far right and below the wound above it",
         "local SKIN_TINT = {                 -- the game's five skin tones (getSkinTextureIndex 0 to 4), as the skin's tint"]
    for i, (r, g, b) in enumerate(tints):
        L.append(f"    {{ r = {r:.3f}, g = {g:.3f}, b = {b:.3f} }},   -- {i}")
    L.append("}")
    for sex in ("m", "f"):
        L.append(f"local {sex.upper()}_WOUNDS = {{   -- generated by d_wounds.py: each picture's top left, each mark's middle")
        for p in PARTS:
            pics, (one, two) = pics_by_sex[sex][p], places_by_sex[sex][p]
            fields = []
            for name in ("bandage", "bandage-dirty", "fracture", "splint", "skin1", "skin1b", "skin2", "skin2b"):
                if name in pics:
                    _, x, y = pics[name]
                    fields.append(f'["{name}"] = {{ {x}, {y} }}')
            L.append(f'    ["{p}"] = {{')
            L.append("        " + ", ".join(fields[:4]) + ",")
            L.append("        " + ", ".join(fields[4:]) + ",")
            L.append(f"        slots = {{ {{ {{ {one[0][0]}, {one[0][1]} }} }}, "
                     f"{{ {{ {two[0][0]}, {two[0][1]} }}, {{ {two[1][0]}, {two[1][1]} }} }} }},")
            L.append("    },")
        L.append("}")
    return "\n".join(L)


def export(root):
    dd = os.path.join(root, "42", "media", "textures", "ZeD", "body", "wounds")
    os.makedirs(dd, exist_ok=True)
    pics_by_sex, places_by_sex = {}, {}
    for sex in ("m", "f"):
        body = Body(sex)
        pics, places = pictures(body)
        for p, d in pics.items():
            for name, (lay, _, _) in d.items():
                to_png(lay).save(os.path.join(dd, f"{sex}-{p}-{name}.png"))
        pics_by_sex[sex], places_by_sex[sex] = pics, places
    for kind in SPRITES:
        to_png(sprite(kind)).save(os.path.join(dd, f"mark-{kind}.png"))
        if kind != "bleed":
            to_png(halo(kind)).save(os.path.join(dd, f"mark-{kind}-infected.png"))
    with open(os.path.join(dd, "_wounds.lua.txt"), "w") as f:
        f.write(lua_tables(pics_by_sex, places_by_sex) + "\n")
    n = len([x for x in os.listdir(dd) if x.endswith(".png")])
    print(f"wrote {n} wound pictures and the tables to", dd)
    return pics_by_sex, places_by_sex


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "mod", "ZeD-UI"))
