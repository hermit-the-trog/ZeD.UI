"""Mock: the belt with each slot on its own material, two loadouts, at today's gap (7) and a wider gap (14)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw, ImageFont
import d_straps as S
BOX, HAND, PAD, END_GAP, SIDE_GAP, BW, BH, STRAP = 44, 52, 12, 10, 14, 58, 40, 30
FONT = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 8)
BUCKLE = Image.open("/mnt/user-data/uploads/ZeD-UI/42/media/textures/ZeD/buckles/buckle_unemployed.png").convert("RGBA")
_cache = {}
def seg(name, w):
    key = (name, w)
    if key not in _cache: _cache[key] = S.assemble(name, w)
    return _cache[key]

def belt(slots, gap, waist="leather"):
    n = len(slots); k = (n + 1) // 2
    x = HAND + END_GAP; strapX = x; x += PAD
    boxes = []
    for i in range(n):
        if i == k: x += SIDE_GAP + BW + SIDE_GAP - gap
        boxes.append(x); x += BOX + gap
    x -= gap
    buckleX = strapX + PAD + k * BOX + (k - 1) * gap + SIDE_GAP
    x += PAD; strapW = x - strapX; x += END_GAP
    W = x + HAND; Hh = HAND
    img = Image.new("RGBA", (W, Hh + 14), (86, 90, 52, 255))
    sy = (Hh - STRAP) // 2
    # the waist belt's leather only round the buckle; each slot on its own run (a narrower one shows the world past it)
    half = gap // 2
    runs = []
    for i, (lab, mat) in enumerate(slots):
        x0 = strapX if i == 0 else boxes[i] - half
        x1 = strapX + strapW if i == n - 1 else boxes[i] + BOX + half
        runs.append((x0, x1, mat))
    lx0 = runs[k - 1][1] if k > 0 else strapX
    lx1 = runs[k][0] if k < n else strapX + strapW
    # merge neighbouring runs of the same material (one strap, one piece)
    pieces_ = []
    for x0, x1, mat in runs[:k] + [(lx0, lx1, waist)] + runs[k:]:
        if pieces_ and pieces_[-1][2] == mat and pieces_[-1][1] >= x0 - 1: pieces_[-1] = (pieces_[-1][0], x1, mat)
        else: pieces_.append((x0, x1, mat))
    for x0, x1, mat in pieces_:
        img.alpha_composite(seg(mat, x1 - x0), (x0, sy))
    img.alpha_composite(BUCKLE, (buckleX, (Hh - BH) // 2))
    d = ImageDraw.Draw(img)
    for bx, (lab, mat) in zip(boxes, slots):
        y = (Hh - BOX) // 2
        d.rectangle([bx, y, bx + BOX - 1, y + BOX - 1], fill=(22, 24, 24, 255), outline=(60, 62, 62, 255))
        d.text((bx + BOX // 2, y + BOX // 2), lab, fill=(140, 140, 140, 255), font=FONT, anchor="mm")
    for hx in (0, W - HAND):
        d.rectangle([hx, 0, hx + HAND - 1, HAND - 1], fill=(22, 24, 24, 255), outline=(60, 62, 62, 255))
    return img

L1 = [("BACK", "sling"), ("BELT L", "leather"), ("BELT R", "leather"), ("HOLSTER", "holster_brown")]
L2 = [("BACK", "pack"), ("BELT L", "webbing_camo"), ("BELT R", "webbing_camo"), ("WEB L", "webbing_camo"), ("WEB R", "webbing_camo"),
      ("BEDROLL", "webbing_olive"), ("HOLSTER", "holster_tape")]
L3 = [("BACK", "pack"), ("BELT L", "rope"), ("BEDROLL", "rope"), ("HOLSTER", "holster_hide")]
L4 = [("BACK", "sling"), ("BELT L", "harness"), ("BELT R", "harness"), ("WEB L", "harness")]
rows = []
for gap in (7, 14):
    for lab, L, waist in (("civilian: leather belt, holster", L1, "leather"),
                          ("military: ALICE webbing (camo), pack, bedroll, taped holster", L2, "webbing_camo"),
                          ("makeshift: rope belt, frame pack lashing, hide holster", L3, "rope"),
                          ("firefighter: breathing pack harness", L4, "harness")):
        rows.append((f"gap {gap}: {lab}", belt(L, gap, waist)))
k = 2
Wd = max(r[1].width for r in rows) * k + 20
sheet = Image.new("RGBA", (Wd, sum(r[1].height * k + 24 for r in rows) + 10), (40, 40, 44, 255))
d = ImageDraw.Draw(sheet); y = 8
for lab, im in rows:
    d.text((10, y), lab, fill=(230, 230, 230, 255)); sheet.alpha_composite(im.resize((im.width * k, im.height * k), Image.NEAREST), (10, y + 14)); y += im.height * k + 24
os.makedirs("out/belt", exist_ok=True); sheet.save("out/belt/straps_mock.png"); print(sheet.size)
# swatches
sw = Image.new("RGBA", (12 * 0 + 140 * 3 + 40, ((len(S.MATERIALS) + 2) // 3) * 52 + 10), (40, 40, 44, 255)); d = ImageDraw.Draw(sw)
for i, name in enumerate(S.MATERIALS):
    x = 10 + (i % 3) * 145; y = 8 + (i // 3) * 52
    d.text((x, y), name, fill=(230, 230, 230, 255)); sw.alpha_composite(S.assemble(name, 130), (x, y + 14))
sw.resize((sw.width * 2, sw.height * 2), Image.NEAREST).save("out/belt/straps_swatches_2x.png")
