import sys; sys.path.insert(0, ".")
import numpy as np
from PIL import Image, ImageDraw
from icons import ICONS
import mock as MK

def tones(acc, bright, active=False, light=False):
    sh = MK.shade
    if active:   # on the lit accent panel: the object engraved in darker tones of the accent
        return {"w": sh(acc, 0.62), "l": sh(acc, 0.5), "m": sh(acc, 0.32), "d": sh(acc, 0.2), "k": sh(acc, 0.12)}
    white = np.array([255, 250, 240])
    return {"w": np.array(bright) * 0.45 + white * 0.55, "l": np.clip(sh(bright, 1.22), 0, 255), "m": np.array(acc),
            "d": sh(acc, 0.58), "k": sh(acc, 0.34)}

def draw_icon(img, name, x, y, acc, bright, active=False, shadow=True):
    g = ICONS[name]
    m = np.array([[c != "." for c in r] for r in g])
    if shadow: MK.blend(img, m, (0, 0, 0), 0.25 if active else 0.55, x + 1, y + 1)
    T = tones(acc, bright, active)
    for t in "wlmdk":
        mm = np.array([[c == t for c in r] for r in g])
        MK.blend(img, mm, T[t], 1.0, x, y)

def strip(kind, active=0, hover=None, bg=MK.BG, border=MK.BORDER, sep=MK.SEP):
    names = ["loot", "equip", "health", "thermal", None, "identity", "journal", "skills", "radio"] if kind == "char" else \
            ["loot", "craft", "build", "furniture", None, "maps", "forage", "animals", "radio", "vehicle"]
    acc, bright = MK.ACC[kind]
    W, B = MK.W, MK.B
    H = sum(9 if n is None else B for n in names)
    img = np.zeros((H, W, 4), np.uint8); img[..., :3] = bg; img[..., 3] = 255
    MK.rect(img, W - 1, 0, 1, H, border)
    y = 0; i = 0
    for n in names:
        if n is None:
            MK.rect(img, 4, y + 4, W - 8, 1, sep); y += 9; continue
        isA, isH = i == active, i == hover
        if isA:
            MK.rect(img, 0, y, W - 1, B, MK.shade(acc, 0.85))
            MK.rect(img, 0, y, W - 1, 1, MK.shade(bright, 1.1)); MK.rect(img, 0, y, 1, B, MK.shade(bright, 1.05))
            MK.rect(img, 0, y + B - 2, W - 1, 2, MK.shade(acc, 0.55)); MK.rect(img, W - 2, y, 1, B, MK.shade(acc, 0.6))
        elif isH: MK.rect(img, 0, y, W - 1, B, acc, 0.30)
        draw_icon(img, n, (W - 16) // 2, y + (B - 16) // 2, acc, bright, isA)
        MK.rect(img, 0, y + B - 1, W, 1, border)
        y += B; i += 1
    return Image.fromarray(img, "RGBA")

if __name__ == "__main__":
    k = 3
    a, b = strip("char", 0, 2), strip("world", 1, 3)
    old_a, old_b = MK.strip("char", "now", 0, 2), MK.strip("world", "now", 1, 3)
    # one big sheet: the icons at 8x, then the strips (now vs new) at 3x
    names = list(ICONS)
    acc, bright = MK.ACC["char"]
    big = np.zeros((16 * 8 + 20, len(names) * (16 * 8 + 12) + 12, 4), np.uint8); big[..., :3] = MK.BG; big[..., 3] = 255
    for i, n in enumerate(names):
        t = np.zeros((18, 18, 4), np.uint8); t[..., :3] = MK.BG; t[..., 3] = 255
        draw_icon(t, n, 0, 0, acc, bright)
        tim = Image.fromarray(t, "RGBA").resize((18 * 8, 18 * 8), Image.NEAREST)
        Image.fromarray(big).paste  # noqa
        bi = Image.fromarray(big, "RGBA"); bi.paste(tim, (12 + i * (16 * 8 + 12), 10)); big = np.array(bi)
    bi = Image.fromarray(big, "RGBA")
    half = (bi.width + 1) // 2
    two = Image.new("RGBA", (half + 12, bi.height * 2), (27, 25, 22, 255))
    two.paste(bi.crop((0, 0, half, bi.height)), (0, 0)); two.paste(bi.crop((half - 12, 0, bi.width, bi.height)), (0, bi.height))
    two.save("icons_new_8x.png")
    Hh = max(a.height, b.height, old_b.height) * k + 40
    sh = Image.new("RGBA", (4 * (36 * k + 14) + 60, Hh), (40, 40, 44, 255))
    d = ImageDraw.Draw(sh)
    x = 12
    for title, im in (("now", old_a), ("", old_b), ("new", a), ("", b)):
        d.text((x, 8), title, fill=(230, 230, 230, 255))
        sh.alpha_composite(im.resize((36 * k, im.height * k), Image.NEAREST), (x, 28)); x += 36 * k + 14 + (30 if title == "" else 0)
    sh.save("strips_new_3x.png"); print("ok")
