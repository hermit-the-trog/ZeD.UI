"""The survival guide's stills: one frame per game clip, shown when the game's Video effects option is off.

  py make_stills.py <frames dir from clip_stills.ps1>

Of each clip's five frames, keeps the one with the most detail (edge energy), passing over dark or washed-out
frames (fades), and writes it to 42/media/textures/ZeD/guide/<clip>.png at 480 x 240, quantised to keep the mod small.
Also writes _stills_sheet.png beside the frames for a look.
"""
import glob
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "..", "42", "media", "textures", "ZeD", "guide"))


def score(im):
    g = np.asarray(im.convert("L").resize((240, 120)), dtype=float)
    mean = g.mean()
    edges = np.asarray(im.convert("L").resize((240, 120)).filter(ImageFilter.FIND_EDGES), dtype=float).mean()
    penalty = 0.0
    if mean < 40 or mean > 220:
        penalty = 50.0
    return edges + g.std() * 0.15 - penalty


def main(src):
    os.makedirs(OUT, exist_ok=True)
    clips = sorted({os.path.basename(p).rsplit("_", 1)[0] for p in glob.glob(os.path.join(src, "*_[0-9].png"))})
    picks, total = [], 0
    for c in clips:
        frames = sorted(glob.glob(os.path.join(src, c + "_[0-9].png")))
        best = max(frames, key=lambda p: score(Image.open(p).convert("RGB")))
        im = Image.open(best).convert("RGB").resize((480, 240), Image.LANCZOS)
        q = im.quantize(colors=128, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
        dst = os.path.join(OUT, c + ".png")
        q.save(dst, optimize=True)
        total += os.path.getsize(dst)
        picks.append((c, im))
    cols = 8
    sheet = Image.new("RGB", (cols * 240, ((len(picks) + cols - 1) // cols) * 134), "black")
    d = ImageDraw.Draw(sheet)
    for i, (c, im) in enumerate(picks):
        x, y = (i % cols) * 240, (i // cols) * 134
        sheet.paste(im.resize((240, 120)), (x, y))
        d.text((x + 3, y + 121), c[3:], fill="white")
    sheet.save(os.path.join(src, "_stills_sheet.png"))
    print(len(picks), "stills,", round(total / 1048576, 2), "MB in", OUT)


if __name__ == "__main__":
    main(sys.argv[1])
