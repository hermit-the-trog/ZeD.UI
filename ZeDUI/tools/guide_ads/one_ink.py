"""One ink (the director, Nov 22 2026: "The F1 guide, advertisements, use white ink. There should only be black ink."):
turns each rendered ad into the book's one ink on a clear ground. Every pixel is read as the share of ink it carries
(its color laid over the paper, then measured on the line from the paper to the ink); out comes the ink alone, with that
share as its alpha. Bare paper comes out clear, so the book's own page shows through where nothing is printed, and no
pixel is ever lighter than the page (a paper-colored mark drawn over the page read as white ink in the game).

python one_ink.py [--src DIR] [--dst DIR] [name ...]
  default: out/final/*.png rewritten in place; --dst writes there instead (e.g. the game's ads folder)."""
import argparse, glob, os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
INK = np.array([0x23, 0x2a, 0x3a], float)
PAPER = np.array([0xf5, 0xec, 0xd2], float)


def one_ink(im):
    """an RGBA image -> the same picture as the ink alone over a clear ground (alpha = the share of ink)"""
    a = np.asarray(im.convert("RGBA")).astype(float)
    al = a[..., 3:4] / 255.0
    over = a[..., :3] * al + PAPER * (1 - al)               # the picture as printed on the paper
    d = INK - PAPER
    t = np.clip(((over - PAPER) @ d) / (d @ d), 0.0, 1.0)   # how far each pixel sits from the paper toward the ink
    out = np.zeros(a.shape, np.uint8)
    out[..., :3] = INK.astype(np.uint8)
    out[..., 3] = np.round(t * 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("names", nargs="*")
    ap.add_argument("--src", default=os.path.join(HERE, "out", "final"))
    ap.add_argument("--dst", default=None)
    a = ap.parse_args()
    dst = a.dst or a.src
    os.makedirs(dst, exist_ok=True)
    files = [os.path.join(a.src, n if n.endswith(".png") else n + ".png") for n in a.names] or \
            sorted(glob.glob(os.path.join(a.src, "*.png")))
    for f in files:
        one_ink(Image.open(f)).save(os.path.join(dst, os.path.basename(f)))
        print("one ink", os.path.basename(f))


if __name__ == "__main__":
    main()
