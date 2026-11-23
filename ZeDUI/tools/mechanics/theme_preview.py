"""The Vehicle tab's car figure as drawFigure draws it, per theme (Car diagram per theme, Nov 22 2026; the director: "on a
light screen or on the light theme, the vehicle diagram looks muddy"). Reads the installed art (42/media/textures/ZeD/
mech/zm_*.png and MechFigs.lua) and the theme numbers below, which mirror the mechFig tokens in Tokens.lua, and
composites the figure the way the tab does: the base in the theme's dim color, the overall wash, each part in its
condition color, the wear untinted on top. The ground is the tab's: the drawer's wash over surface 1.

usage: py theme_preview.py OUT_DIR
  writes compare_themes.png (each theme a column: a mixed car, then all green, yellow and red) and
  wear_<theme>_<body>.png / wear_<theme>_all.png (all 13 bodies, green, yellow and red side by side) at 3x."""
import os, re, sys
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
TEX = os.path.join(REPO, "42", "media", "textures", "ZeD", "mech")
MF = os.path.join(REPO, "42", "media", "lua", "client", "ZeD", "MechFigs.lua")


def hexc(h): return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def over(dst, src_rgb, src_a, a):
    """the over composite: src_rgb (0-255) at alpha src_a (0-1) times a"""
    al = (src_a * a)[..., None]
    dst[...] = dst * (1 - al) + src_rgb * al


def lift(c, k):
    """a status color k of the way toward white (mechFig.lift)"""
    return tuple(v + (255 - v) * k for v in c)


# the themes as Tokens.lua sets them: the ground (surface 1 under the drawer's wash), textDim, the status colors and
# the mechFig numbers (keep these in step with Tokens.lua's mechFig tables)
THEMES = {
    "dark": dict(ground=(0x14 * 0.85,) * 3, dim=(161, 161, 161), pos=hexc("#7A9A34"), warn=hexc("#C49A2A"),
                 bad=hexc("#C45A2A"), fig=dict(baseA=0.45, partA=0.7, washA=0.22, wearA=0.9, lift=0.0, baseLight=False)),
    "light": dict(ground=tuple(0xBE * 0.88 + 255 * 0.12 for _ in range(3)), dim=(12, 12, 12), pos=hexc("#2A5511"),
                  warn=hexc("#6B5510"), bad=hexc("#7A2A11"),
                  fig=dict(baseA=0.30, partA=0.95, washA=0.18, wearA=1.0, lift=0.15, baseLight=False)),
    "hicon": dict(ground=(0x11 * 0.85,) * 3, dim=(199, 199, 199), pos=hexc("#44DD44"), warn=hexc("#FFCC22"),
                  bad=hexc("#FF5533"),
                  fig=dict(baseA=0.45, partA=0.7, washA=0.22, wearA=0.9, lift=0.0, baseLight=False)),
}


def load_rects():
    s = open(MF, encoding="utf-8").read()
    lay = {k: tuple(map(int, v)) for k, *v in re.findall(r'\["([A-Za-z0-9_]+)"\] = \{ x = (\d+), y = (\d+), w = (\d+), h = (\d+)', s)}
    return lay


_tex = {}
def tex(name):
    if name not in _tex:
        p = os.path.join(TEX, "zm_" + name + ".png")
        _tex[name] = np.asarray(Image.open(p).convert("RGBA")).astype(np.float32) if os.path.exists(p) else None
    return _tex[name]


def band(cond): return "pos" if cond > 60 else "warn" if cond > 20 else "bad"


def draw(body, theme, conds, rects, scale=3):
    """the figure for one body; conds: part name -> condition 0-100 (missing: 80)"""
    th = THEMES[theme]; fig = th["fig"]
    U = rects[body + "_"]
    img = np.zeros((U[3], U[2], 3), np.float32); img[...] = th["ground"]

    def put(key, col, a):
        t = tex(key)
        if t is None: return
        x, y, w, h = rects[key]
        sub = img[y - U[1]:y - U[1] + h, x - U[0]:x - U[0] + w]
        over(sub, t[..., :3] / 255.0 * np.asarray(col, np.float32), t[..., 3] / 255.0, a)

    names = sorted(k[len(body) + 1:] for k in rects if k.startswith(body + "_") and k != body + "_" and k != body + "_base")
    mean = sum(conds.get(n, 80) for n in names) / float(max(1, len(names)))
    base_col = (255, 255, 255) if fig["baseLight"] else th["dim"]
    put(body + "_base", base_col, fig["baseA"])
    put(body + "_base", lift(th[band(mean)], fig["lift"]), fig["washA"])
    for n in names:
        c = conds.get(n, 80)
        put(body + "_" + n, lift(th[band(c)], fig["lift"]), fig["partA"])
        if c <= 60:
            wt = tex(body + "_" + n + ("_wear2" if c <= 20 else "_wear1"))
            if wt is not None:
                x, y, w, h = rects[body + "_" + n]
                sub = img[y - U[1]:y - U[1] + h, x - U[0]:x - U[0] + w]
                over(sub, wt[..., :3], wt[..., 3] / 255.0, fig["wearA"])
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    return im.resize((im.width * scale, im.height * scale), Image.NEAREST)


MIXED = {"brake_front_left": 10, "wheel_front_left": 10, "battery": 40, "window_rear_left": 40,
         "door_rear_right": 10, "muffler": 40, "hood": 40, "trunk": 15, "engine": 70}
LABEL = {"dark": "Dark", "light": "Light", "hicon": "High contrast"}


def labelled(ims, labels, gap=16, top=22, bg=(20, 21, 24)):
    S = Image.new("RGB", (sum(i.width for i in ims) + gap * (len(ims) - 1), max(i.height for i in ims) + top), bg)
    d = ImageDraw.Draw(S); x = 0
    for im, lb in zip(ims, labels):
        S.paste(im, (x, top)); d.text((x + 2, 4), lb, fill=(200, 200, 200)); x += im.width + gap
    return S


def stack(ims, gap=16, bg=(20, 21, 24)):
    S = Image.new("RGB", (max(i.width for i in ims), sum(i.height for i in ims) + gap * (len(ims) - 1)), bg)
    y = 0
    for im in ims: S.paste(im, (0, y)); y += im.height + gap
    return S


def main(out):
    os.makedirs(out, exist_ok=True)
    rects = load_rects()
    bodies = sorted(k[:-1] for k in rects if k.endswith("_") and k[:-1] + "_base" in rects)
    rows = []
    for th in ("dark", "light", "hicon"):
        ims = [draw("4door", th, MIXED, rects)]
        for c, lb in ((80, "green"), (40, "yellow"), (10, "red")):
            names = [k[len("4door_"):] for k in rects if k.startswith("4door_")]
            ims.append(draw("4door", th, {n: c for n in names}, rects))
        rows.append(labelled(ims, [LABEL[th] + ": mixed", "all green", "all yellow", "all red"]))
    stack(rows).save(os.path.join(out, "compare_themes.png"))
    for th in ("dark", "light", "hicon"):
        sheets = []
        for b in bodies:
            names = [k[len(b) + 1:] for k in rects if k.startswith(b + "_")]
            ims = [draw(b, th, {n: c for n in names}, rects) for c in (80, 40, 10)]
            S = labelled(ims, [f"{b} {LABEL[th]}: green", "yellow", "red"])
            S.save(os.path.join(out, f"wear_{th}_{b}.png")); sheets.append(S)
        cols = 2
        cw, ch = max(i.width for i in sheets) + 20, max(i.height for i in sheets) + 20
        A = Image.new("RGB", (cw * cols, ch * ((len(sheets) + cols - 1) // cols)), (20, 21, 24))
        for i, im in enumerate(sheets): A.paste(im, ((i % cols) * cw + 10, (i // cols) * ch + 10))
        A.save(os.path.join(out, f"wear_{th}_all.png"))


if __name__ == "__main__":
    main(sys.argv[1])
