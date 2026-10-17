"""usage: python review.py id [id ...]  -> out/review_<id>.png (each preview state at 3x) and the warnings"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from physlib import build
import preview as PV
from plates import DESIGNS
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")


def strip(rows, k=3, pad=10, bg=(24, 24, 26, 255)):
    W = max(r.width for r in rows) * k + 2 * pad
    H = sum(r.height * k + pad for r in rows) + pad
    s = Image.new("RGBA", (W, H), bg); y = pad
    for r in rows:
        s.alpha_composite(PV.scale(r, k), (pad, y)); y += r.height * k + pad
    return s


def review(pid, k=3):
    D = DESIGNS[pid]
    p, base, sprites = build(D["fn"], D["variants"], **D.get("base", {}))
    if D.get("post"): D["post"](p)
    for w in p.warnings: print("  !", pid, w)
    rows = [PV.render_state(base, p.parts, sprites, st) for st in D["states"]]
    strip(rows, k).save(os.path.join(OUT, f"review_{pid}.png"))
    print(pid, p.W, "x", p.H, len(p.parts), "parts", len(p.hits), "hits", {n: im.size for n, im in sprites.items()})
    return p, base, sprites


if __name__ == "__main__":
    for pid in sys.argv[1:] or list(DESIGNS):
        review(pid)
