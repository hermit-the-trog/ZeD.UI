import numpy as np
from PIL import Image, ImageDraw, ImageFont
import compose_pins as CP
src = Image.open('/mnt/user-data/uploads/ZeD_design_refs/forage_arrow_20261117/zed_51_forage.png').convert('RGBA')
def fill(im, box):
    """cover what is under box by blending its four borders (the ground here is a smooth light falloff)"""
    a = np.asarray(im).astype(float); x0, y0, x1, y1 = box
    top, bot = a[y0 - 1, x0:x1], a[y1, x0:x1]; lef, rig = a[y0:y1, x0 - 1], a[y0:y1, x1]
    h, w = y1 - y0, x1 - x0
    ty = (np.arange(h) + 1) / (h + 1); tx = (np.arange(w) + 1) / (w + 1)
    v = top[None] * (1 - ty[:, None, None]) + bot[None] * ty[:, None, None]
    u = lef[:, None] * (1 - tx[None, :, None]) + rig[:, None] * tx[None, :, None]
    rng = np.random.default_rng(3); n = rng.normal(0, 2.2, (h, w, 1)); n = np.repeat(n, 4, 2); n[..., 3] = 0
    a[y0:y1, x0:x1] = np.clip((v + u) / 2 + n, 0, 255)
    return Image.fromarray(a.astype(np.uint8), 'RGBA')
base = src
for b in ((1758, 1128, 1800, 1168), (2088, 1150, 2132, 1194), (1704, 1064, 1750, 1122), (2152, 1096, 2198, 1152)):
    base = fill(base, b)
def pin(im, item, state, tip):
    p = CP.pin("B", item, state).resize((30, 45), Image.BOX)
    im.alpha_composite(p, (tip[0] - 15, tip[1] - 43))
def arrow(im, kind, c, ang):
    a = Image.open(f"art/arrow/forage_arrow_{kind}.png").rotate(ang, resample=Image.BICUBIC, expand=True)
    im.alpha_composite(a, (c[0] - a.width // 2, c[1] - a.height // 2))
out = []
for kind in ("glass", "solid"):
    im = base.copy()
    pin(im, "Item_MushroomChanterelle", "glass", (1727, 1116)); pin(im, None, "unknown", (2175, 1147))
    arrow(im, kind, (1778, 1147), 98); arrow(im, kind, (2110, 1171), -82)
    out.append(im)
F = "/mnt/user-data/uploads/ZeD_design_refs/overhead_refs_20261115/fonts/"
f = ImageFont.truetype(F + "FiraMono-Regular.ttf", 22)
crop = (1620, 980, 2260, 1260)
S = Image.new("RGBA", (1600, 3 * 610 + 200), (24, 24, 26, 255)); d = ImageDraw.Draw(S)
rows = ((src, "The game's arrows and pins (2x)"), (out[0], "ZeD: a chrome arrow with the pin's dark glass (2x)"), (out[1], "ZeD: a solid chrome arrow (2x)"))
for i, (im, lab) in enumerate(rows):
    y = i * 610; S.alpha_composite(im.crop(crop).resize((1280, 560), Image.NEAREST), (15, y + 10)); d.text((15, y + 575), lab, font=f, fill=(232, 230, 224))
y = 3 * 610 + 10
for i, im in enumerate((src, out[0], out[1])):
    S.alpha_composite(im.crop((1695, 1055, 2205, 1195)), (15 + i * 525, y))
d.text((15, y + 150), "Actual size at 4K: the game's, glass, solid", font=f, fill=(232, 230, 224))
S.save("/mnt/user-data/outputs/forage_arrow_review.png"); print(S.size)
