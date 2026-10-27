"""review sheets: every icon on its real cells (16 at rest on paper, 24 pointed on the accent) at 1x and 4x, so a
drawing is judged at the size it is seen and close enough to fix; and rings the way the wheel shows them"""
import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kit import ICONS, render

INK = (20, 20, 20, 255); PAPER = (242, 242, 242, 255); ACC = (232, 160, 40, 255)
BG = (58, 62, 52, 255)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
os.makedirs(OUT, exist_ok=True)


def tint(im, col):
    out = Image.new("RGBA", im.size, col); out.putalpha(im.getchannel("A")); return out


def cell(icon, size, bg, ink=INK):
    c = Image.new("RGBA", (size + 2, size + 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(c)
    d.rectangle([2, 2, size + 1, size + 1], fill=(0, 0, 0, 255))
    d.rectangle([0, 0, size - 1, size - 1], fill=INK)
    d.rectangle([1, 1, size - 2, size - 2], fill=bg)
    o = (size - icon.width) // 2
    c.alpha_composite(tint(icon, ink), (o, o))
    return c


def sheet(ids, path, k=5, per=5, title=None):
    """each icon: the two cells at k (to read the pixels) and at 1x and 2x beside (to read it as it is seen)"""
    cw = 22 * k + 33 * k + 16 + 90
    ch = 33 * k + 34
    rows = (len(ids) + per - 1) // per
    top = 24 if title else 0
    s = Image.new("RGBA", (per * cw + 20, rows * ch + 20 + top), BG); d = ImageDraw.Draw(s)
    if title: d.text((20, 6), title, fill=(230, 230, 220))
    for i, n in enumerate(ids):
        x = 20 + (i % per) * cw; y = 20 + top + (i // per) * ch
        a = cell(render(n, 16), 22, PAPER); b = cell(render(n, 24), 33, ACC)
        s.alpha_composite(a.resize((a.width * k, a.height * k), Image.NEAREST), (x, y + 11 * k // 2))
        s.alpha_composite(b.resize((b.width * k, b.height * k), Image.NEAREST), (x + 22 * k + 8, y))
        xs = x + 22 * k + 33 * k + 24
        s.alpha_composite(a, (xs, y)); s.alpha_composite(b, (xs + 28, y))
        a2 = a.resize((a.width * 2, a.height * 2), Image.NEAREST); b2 = b.resize((b.width * 2, b.height * 2), Image.NEAREST)
        s.alpha_composite(a2, (xs, y + 40)); s.alpha_composite(b2, (xs, y + 40 + 52))
        d.text((x, y + 33 * k + 8), n, fill=(225, 225, 215))
    s.save(os.path.join(OUT, path)); return s


def ring(ids, pointed=0, k=3, title=""):
    """a wheel as ZeD_Wheel draws it: resting cells on a ring, the pointed one grown on the accent"""
    n = len(ids); R = max(28, int((22 + 10) * n / (2 * math.pi)) + 4)
    W_ = 2 * R + 60; H_ = 2 * R + 70
    bg = Image.new("RGBA", (W_, H_), (84, 92, 60, 255))
    cx, cy = W_ // 2, H_ // 2 + 6
    for i, nm in enumerate(ids):
        a = math.radians(-90 + i * 360 / n)
        x, y = cx + R * math.cos(a), cy + R * math.sin(a)
        if i == pointed: continue
        c = cell(render(nm, 16), 22, PAPER); bg.alpha_composite(c, (int(x - 11), int(y - 11)))
    a = math.radians(-90 + pointed * 360 / n)
    x, y = cx + R * math.cos(a), cy + R * math.sin(a)
    c = cell(render(ids[pointed], 24), 33, ACC); bg.alpha_composite(c, (int(x - 16.5), int(y - 16.5)))
    d = ImageDraw.Draw(bg); d.rectangle([cx - 3, cy - 3, cx + 3, cy + 3], fill=PAPER, outline=INK)
    if title: d.text((6, 4), title, fill=(235, 235, 225))
    return bg.resize((W_ * k, H_ * k), Image.NEAREST)


def rings(groups, path, k=3, per=3):
    ims = [ring(ids, p, k, t) for t, ids, p in groups]
    cols = min(per, len(ims)); rws = (len(ims) + cols - 1) // cols
    cw = max(i.width for i in ims); chh = max(i.height for i in ims)
    s = Image.new("RGBA", (cols * (cw + 16) + 16, rws * (chh + 16) + 16), (40, 42, 36, 255))
    for i, im in enumerate(ims): s.alpha_composite(im, (16 + (i % cols) * (cw + 16), 16 + (i // cols) * (chh + 16)))
    s.save(os.path.join(OUT, path)); return s


def true_size(ids, path, per=24):
    """every icon at 1x on its cells, as the game shows them at 1080p: the real test"""
    rows = (len(ids) + per - 1) // per
    s = Image.new("RGBA", (per * 64 + 16, rows * 44 + 16), BG)
    for i, n in enumerate(ids):
        x = 16 + (i % per) * 64; y = 16 + (i // per) * 44
        s.alpha_composite(cell(render(n, 16), 22, PAPER), (x, y + 5))
        s.alpha_composite(cell(render(n, 24), 33, ACC), (x + 26, y))
    s.save(os.path.join(OUT, path)); return s


CAT_NAMES = {"char": "Character wheel", "world": "World wheel", "vehicle": "Vehicle wheel", "gun": "Firearm + light source",
             "animal": "Animal wheel", "fig": "Figures (emotes, stances)", "hand": "Hands", "sym": "Signs + ZeD setup",
             "tab": "Window tabs"}


def catalogue(cats, path, per=8, title=None):
    """every icon of the given groups: the 16 at rest on paper at 4x, the 24 pointed on the accent at 3x, its id"""
    tw, th = 22 * 4 + 33 * 3 + 22, 33 * 3 + 30
    groups = [(c_, [k for k, v in ICONS.items() if v["cat"] == c_]) for c_ in cats]
    H = 40 if title else 10
    for _, ids in groups: H += 30 + ((len(ids) + per - 1) // per) * th
    W = per * tw + 30
    s = Image.new("RGBA", (W, H + 10), (46, 48, 42, 255)); d = ImageDraw.Draw(s)
    y = 10
    if title: d.text((16, 12), title, fill=(240, 240, 228)); y = 40
    for c_, ids in groups:
        d.text((16, y + 8), CAT_NAMES.get(c_, c_) + f"  ({len(ids)})", fill=(232, 160, 40)); y += 30
        for i, n in enumerate(ids):
            x = 16 + (i % per) * tw; yy = y + (i // per) * th
            a = cell(render(n, 16), 22, PAPER); b = cell(render(n, 24), 33, ACC)
            s.alpha_composite(a.resize((a.width * 4, a.height * 4), Image.NEAREST), (x, yy + 8))
            s.alpha_composite(b.resize((b.width * 3, b.height * 3), Image.NEAREST), (x + 22 * 4 + 10, yy))
            d.text((x, yy + 33 * 3 + 8), n, fill=(225, 225, 215))
        y += ((len(ids) + per - 1) // per) * th
    s.save(os.path.join(OUT, path)); return s
