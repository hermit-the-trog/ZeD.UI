"""Exports the lit tab icons for the game: per icon five white tone masks and its shadow mask, 16 x 16
(media/textures/ZeD/TabIcons/px/<id>_<w|l|m|d|k|sh>.png). The game tints each mask with a tone of the theme's accent
(ZeD_TabPx.lua). usage: python export_tabs.py [mod root]   (default ./out/mod/ZeD-UI)"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from icons import ICONS, TONES     # noqa: E402

DIR = "media/textures/ZeD/TabIcons/px"


def masks(name):
    g = ICONS[name]
    out = {t: np.array([[c == t for c in r] for r in g]) for t in TONES}
    out["sh"] = np.array([[c != "." for c in r] for r in g])
    return out


def export(root):
    d = os.path.join(root, "42", *DIR.split("/"))
    os.makedirs(d, exist_ok=True)
    n = 0
    for name in ICONS:
        for t, m in masks(name).items():
            a = np.zeros((16, 16, 4), np.uint8)
            a[..., :3] = 255
            a[..., 3] = m * 255
            Image.fromarray(a, "RGBA").save(os.path.join(d, f"{name}_{t}.png")); n += 1
    print("wrote", n, "masks to", d)


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "out", "mod", "ZeD-UI"))
