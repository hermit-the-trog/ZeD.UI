"""The body figure with its flesh and wounds, composed exactly as ZeD_BodyFigure.lua draws it (drawAt: the background
tinted by the theme, the skeleton on its flesh, the parts dim or tinted, then the wounds in six passes), for review. usage: python wounds_sheet.py [mod root]: writes the art (d_skeleton, d_wounds) and preview/body_wounds_review.png"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import d_skeleton as S
import d_wounds as WD

THEMES = {   # the shipped Teal accent's tones, for the review (the test uses its own)
    "dark": dict(surf=(20, 20, 20), dim=((161, 161, 161), 0.65), accent=(71, 161, 140), danger=(196, 90, 42),
                 warning=(196, 154, 42), ink=(220, 218, 214), icon=(240, 240, 235)),
    "light": dict(surf=(190, 190, 190), dim=((12, 12, 12), 0.72), accent=(26, 102, 85), danger=(122, 42, 17),
                  warning=(107, 85, 16), ink=(20, 20, 20), icon=(240, 240, 235)),
}


def font(size):
    """the sheet's label face: DejaVu Sans where there is one (Linux), else Segoe UI or Arial (Windows), else Pillow's"""
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", r"C:\Windows\Fonts\segoeui.ttf",
                 r"C:\Windows\Fonts\arial.ttf"):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


class Tex:
    """the exported pictures, read once each"""
    def __init__(s, root):
        s.root = root
        s.cache = {}

    def __call__(s, rel):
        if rel not in s.cache:
            s.cache[rel] = np.asarray(Image.open(os.path.join(s.root, "42", "media", "textures", "ZeD", "body", rel))
                                      .convert("RGBA")).astype(np.float32) / 255.0
        return s.cache[rel]


def blit(c, src, x, y, k=1, alpha=1.0, tint=(1.0, 1.0, 1.0)):
    """drawTextureScaledUniform: src at (x, y), each pixel k x k, its color times tint, its alpha times alpha"""
    if k != 1:
        src = np.repeat(np.repeat(src, k, axis=0), k, axis=1)
    h, w = src.shape[:2]
    H_, W_ = c.shape[:2]
    x0, y0, x1, y1 = max(0, x), max(0, y), min(W_, x + w), min(H_, y + h)
    if x1 <= x0 or y1 <= y0:
        return
    sub = src[y0 - y:y1 - y, x0 - x:x1 - x]
    col = sub[..., :3] * np.array(tint, np.float32)
    a = sub[..., 3:4] * alpha
    c[y0:y1, x0:x1] = c[y0:y1, x0:x1] * (1 - a) + col * a


def draw_wounds(c, tex, sex, layout, wounds, tone, xo=0, yo=0, k=1):
    """the six passes, every part in the figure's order each pass: cracks, bandages, skin, infected rings, marks (the
    bleeding below the last), splints"""
    tint = WD.skin_tints()[tone]
    for ps in range(1, 7):
        for p in S.PARTS:
            w = wounds.get(p)
            if not w:
                continue
            g = layout[p]
            marks = w.get("marks") or []
            n = max(1, len(marks))
            slots = g["slots"][n - 1]

            def at(name, pos, **kw):
                blit(c, tex(name), xo + pos[0] * k, yo + pos[1] * k, k, **kw)
            if ps == 1 and w.get("fracture"):
                at(f"wounds/{sex}-{p}-fracture.png", g["fracture"])
            elif ps == 2 and w.get("bandage"):
                nm = "bandage-dirty" if w["bandage"] == "dirty" else "bandage"
                at(f"wounds/{sex}-{p}-{nm}.png", g[nm])
            elif ps == 3 and (marks or w.get("bleed")):
                nm = f"skin{n}{'b' if w.get('bleed') else ''}"
                at(f"wounds/{sex}-{p}-{nm}.png", g[nm], tint=tint)
            elif ps == 4 and w.get("infected") and marks:
                cx, cy = slots[0]
                at(f"wounds/mark-{marks[0]}-infected.png", (cx - WD.MARK_C, cy - WD.MARK_C))
            elif ps == 5:
                for i, kind in enumerate(marks):
                    cx, cy = slots[i]
                    at(f"wounds/mark-{kind}.png", (cx - WD.MARK_C, cy - WD.MARK_C))
                if w.get("bleed"):                     # below and right of the last mark (with none, of the place)
                    lx, ly = slots[max(1, len(marks)) - 1]
                    lx, ly = lx + WD.BLEED_DX, ly + WD.BLEED_DY
                    at("wounds/mark-bleed.png", (lx - WD.MARK_C, ly - WD.MARK_C))
            elif ps == 6 and w.get("splint") and "splint" in g:
                at(f"wounds/{sex}-{p}-splint.png", g["splint"])


def layout_of(pics, places):
    """the Lua table's content for one sex, as Python: {part: {picture: (x, y), "slots": [[(x, y)], [(x, y), (x, y)]]}}"""
    out = {}
    for p in S.PARTS:
        d = {name: (x, y) for name, (_, x, y) in pics[p].items()}
        d["slots"] = places[p]
        out[p] = d
    return out


def figure(tex, layout, sex, theme, tints=None, wounds=None, tone=1, k=1):
    """the whole figure as drawAt draws it at k x, on the theme's surface"""
    T = THEMES[theme]
    c = np.zeros((S.FH * k, S.FW * k, 3), np.float32) + np.array(T["surf"], np.float32) / 255.0
    bgt = tuple((0.55 * T["icon"][i] + 0.45 * T["accent"][i]) / 255.0 for i in range(3))
    blit(c, tex(f"fig-bg-{sex}-{theme}.png"), 0, 0, k, tint=bgt)
    blit(c, tex(f"{sex}-skeleton.png"), 0, 0, k)
    for p in S.PARTS:
        if tints and p in tints:
            blit(c, tex(f"{sex}-{p}.png"), 0, 0, k, alpha=0.65, tint=tuple(v / 255.0 for v in T[tints[p]]))
        else:
            blit(c, tex(f"{sex}-{p}.png"), 0, 0, k, alpha=0.10, tint=tuple(v / 255.0 for v in T["dim"][0]))
    if wounds:
        draw_wounds(c, tex, sex, layout, wounds, tone, 0, 0, k)
    return Image.fromarray(np.clip(np.round(c * 255), 0, 255).astype(np.uint8))


# ---- the states shown
SOME = {"wrist-r": dict(bandage="clean"), "thigh-l": dict(bandage="dirty"), "head": dict(marks=["cut"], bleed=True),
        "bicep-l": dict(marks=["stitch"])}
SOME_TINT = {"wrist-r": "danger", "thigh-l": "warning", "head": "warning", "bicep-l": "warning"}
EVERY = {
    "head": dict(marks=["cut"], bleed=True),
    "neck": dict(marks=["scratch"]),
    "up-torso": dict(marks=["stitch"]),
    "bicep-r": dict(marks=["cut"], infected=True),
    "bicep-l": dict(marks=["bite"]),
    "wrist-r": dict(bandage="clean"),
    "wrist-l": dict(marks=["deep"], bleed=True),
    "hand-l": dict(marks=["burn"]),
    "thigh-r": dict(marks=["bullet", "glass"], bleed=True),
    "thigh-l": dict(bandage="dirty"),
    "ankle-r": dict(fracture=True, splint=True),
    "ankle-l": dict(fracture=True),
}
EVERY_TINT = {p: ("danger" if p in ("bicep-l", "wrist-r", "wrist-l", "thigh-r", "ankle-r", "ankle-l") else "warning")
              for p in EVERY}
TONE = {"m": 1, "f": 3}          # the game's second tone for him, its fourth for her (the skin follows the character)
LEGEND = [("Scratched", "neck"), ("Cut, bleeding", "head"), ("Deep, bleeding", "wrist-l"),
          ("Bitten", "bicep-l"), ("Infected", "bicep-r"), ("Bullet, glass", "thigh-r"),
          ("Burned", "hand-l"), ("Stitched", "up-torso"), ("Bandaged", "wrist-r"), ("Dirty bandage", "thigh-l"),
          ("Fracture", "ankle-l"), ("Splinted", "ankle-r")]


def sheet(root, layouts, out):
    tex = Tex(root)
    font_l, font_s = font(15), font(13)
    K = 2
    cols = [("Before", None, None, False), ("Flesh", None, None, True), ("Flesh, hurt", SOME_TINT, SOME, True),
            ("Every mark", EVERY_TINT, EVERY, True)]
    cw, ch = S.FW * K + 24, S.FH * K + 40
    leg_k, leg_w, leg_h = 4, 26, 32
    cell_w, cell_h = leg_w * leg_k + 12, leg_h * leg_k + 30
    W_ = len(cols) * 2 * cw + 40
    img = Image.new("RGB", (W_, 2 * ch + 20 + 2 * (cell_h + 34) + 20), (40, 38, 34))
    d = ImageDraw.Draw(img)
    ink = (220, 218, 214)
    before = os.environ.get("ZED_BEFORE_ROOT")              # the shipped textures, for the Before column
    btex = Tex(before) if before else None
    for r, theme in enumerate(("dark", "light")):
        for si, sex in enumerate("mf"):
            for ci, (name, tints, wounds, fl) in enumerate(cols):
                x, y = 20 + (si * len(cols) + ci) * cw, 10 + r * ch
                panel = Image.new("RGB", (cw - 8, ch - 8), THEMES[theme]["surf"])
                t_ = tex if fl or not btex else btex
                panel.paste(figure(t_, layouts[sex], sex, theme, tints, wounds, TONE[sex], K), (8, 28))
                ImageDraw.Draw(panel).text((8, 6), f"{name} ({sex})", fill=THEMES[theme]["ink"], font=font_l)
                img.paste(panel, (x, y))

    def tile(fig, cx, cy, gx, gy, label):
        box = (int(cx - leg_w / 2), int(cy - leg_h / 2))
        cr = fig.crop((box[0], box[1], box[0] + leg_w, box[1] + leg_h)).resize((leg_w * leg_k, leg_h * leg_k), Image.NEAREST)
        img.paste(cr, (gx, gy))
        d.text((gx, gy + leg_h * leg_k + 4), label, fill=ink, font=font_s)
    y0 = 10 + 2 * ch + 14
    d.text((20, y0), "Each mark at 4x (him, Dark). A wound on the body sits on a patch of his own skin that fades back "
           "to the flesh and bones; a fracture is a crack in the bone itself.", fill=ink, font=font_l)
    full = figure(tex, layouts["m"], "m", "dark", EVERY_TINT, EVERY, TONE["m"])
    for i, (label, p) in enumerate(LEGEND):
        sl = layouts["m"][p]["slots"]
        n = max(1, len((EVERY[p].get("marks") or [])))
        pts = sl[n - 1]
        cx = sum(q[0] for q in pts) / len(pts)
        cy = sum(q[1] for q in pts) / len(pts) + (3 if EVERY[p].get("bleed") else 0)
        tile(full, cx, cy, 20 + i * cell_w, y0 + 24, label)
    y1 = y0 + 24 + cell_h + 10
    d.text((20, y1), "The skin follows the character's own skin tone, the game's five: a cut on the brow, a deep wound on "
           "the forearm", fill=ink, font=font_l)
    TW = {"head": dict(marks=["cut"], bleed=True), "wrist-l": dict(marks=["deep"], bleed=True)}
    TT = {"head": "warning", "wrist-l": "danger"}
    for t in range(5):
        fig = figure(tex, layouts["m"], "m", "dark", TT, TW, t)
        for j, p in enumerate(("head", "wrist-l")):
            (cx, cy) = layouts["m"][p]["slots"][0][0]
            tile(fig, cx, cy + 3, 20 + (2 * t + j) * cell_w, y1 + 24, f"Tone {t + 1}, {'brow' if p == 'head' else 'forearm'}")
    img.save(out)
    return img


if __name__ == "__main__":
    # the art into the root (as d_skeleton.py and d_wounds.py write it), the bare skeleton beside it for the Before
    # column, and the review sheet into root/preview
    import tempfile
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "mod", "ZeD-UI")
    S.export(root)
    pics, places = WD.export(root)
    layouts = {sex: layout_of(pics[sex], places[sex]) for sex in ("m", "f")}
    before = tempfile.mkdtemp()
    S.FLESH = False
    S.export(before)
    S.FLESH = True
    os.environ["ZED_BEFORE_ROOT"] = before
    os.makedirs(os.path.join(root, "preview"), exist_ok=True)
    p = os.path.join(root, "preview", "body_wounds_review.png")
    print(p, sheet(root, layouts, p).size)
