"""
Lift vanilla's seat-chooser car drawings into line art (ZeD-UI, Oct 15 2026).

Vanilla's media/ui/vehicles/seatui/<shape>base_small.png (packed, 263 x 600
canvases) are white lines over a black-filled car: tinted, the fill stays black.
ZeDUI/tools/qa/zedqa_seat_outlines.lua draws each at 1.75x in game, once on
black and once on white, and screenshots both. Per pixel the two captures give
the drawing's own alpha (a = 1 - (white - black) / 255) and brightness
(black / a); the lines are kept (alpha x brightness), the black fill drops out.

Writes 42/media/textures/ZeD/seats/zs_car_<shape>.png (white, alpha = the
lines), the same 263 x 600 canvas at 1.75 px per unit, so the seat chooser
draws them exactly where vanilla's sit.

Usage:  py ZeDUI/tools/seats/bake_car_outlines.py <screenshots dir>
        (zqa_so_1_black.png, zqa_so_1_white.png, zqa_so_2_black.png, ...)
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = os.path.join(ROOT, "42", "media", "textures", "ZeD", "seats")
# the capture's layout (zedqa_seat_outlines.lua): four shapes a shot, 460 x 1050 each
BATCHES = {1: ["4door", "offroad", "smallcar", "sportscar"], 2: ["stationwagon", "suv", "truck", "van"]}
XS, Y, W, H = [20, 520, 1020, 1520], 15, 460, 1050


def lift(black, white):
    b = black.astype(np.float32).mean(axis=2)
    w = white.astype(np.float32).mean(axis=2)
    a = np.clip(1.0 - (w - b) / 255.0, 0.0, 1.0)
    f = np.where(a > 0.02, b / np.maximum(a, 1e-3), 0.0)
    lines = a * np.clip((f - 40.0) / 160.0, 0.0, 1.0)    # the black fill (f near 0) drops out
    # vanilla's lines are grey: bring the strongest to full strength (the game tints and fades them)
    top = np.percentile(lines[lines > 0.05], 98) if (lines > 0.05).any() else 1.0
    return np.clip(lines / max(top, 1e-3), 0.0, 1.0)


def main(src):
    os.makedirs(OUT, exist_ok=True)
    for b, shapes in BATCHES.items():
        black = np.asarray(Image.open(os.path.join(src, "zqa_so_%d_black.png" % b)).convert("RGB"))
        white = np.asarray(Image.open(os.path.join(src, "zqa_so_%d_white.png" % b)).convert("RGB"))
        for i, shape in enumerate(shapes):
            x = XS[i]
            bk, wh = black[Y:Y + H, x:x + W], white[Y:Y + H, x:x + W]
            if bk.shape[1] < W:
                # the last drawing runs past the 1920 px screen: that strip is empty canvas
                pad = W - bk.shape[1]
                bk = np.pad(bk, ((0, 0), (0, pad), (0, 0)), constant_values=0)
                wh = np.pad(wh, ((0, 0), (0, pad), (0, 0)), constant_values=255)
            lines = lift(bk, wh)
            rgba = np.zeros((H, W, 4), dtype=np.uint8)
            rgba[..., :3] = 255
            rgba[..., 3] = (lines * 255).astype(np.uint8)
            Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, "zs_car_%s.png" % shape), optimize=True)
            print(shape, "kept", int((lines > 0.1).sum()), "px")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.environ.get("USERPROFILE", ""), "Zomboid", "Screenshots"))
