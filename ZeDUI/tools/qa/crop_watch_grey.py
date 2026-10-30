"""Crops the 4K frames of zedqa_watch_grey.lua down to the watches (no 4K full captures in the repo).
Reads the "ZEDQA wgrey RECT <name> x y w h" lines from Zomboid/console.txt (the last run's), takes each zqa_wg_<name>.png from
Zomboid/Screenshots, crops the watch with a margin and writes a JPG to ZeDUI/qa/Oct29_watch_grey/<name>.jpg; with --sheet also a
contact sheet per state (sheet_<state>.jpg, every kind side by side). --clean deletes the 4K frames after cropping.
usage: python crop_watch_grey.py [--sheet] [--clean] [--margin 12] [--out DIR]"""
import os
import re
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ZOMBOID = os.path.expanduser("~/Zomboid")
CONSOLE = os.path.join(ZOMBOID, "console.txt")
SHOTS = os.path.join(ZOMBOID, "Screenshots")
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "qa", "Oct29_watch_grey"))


def rects():
    txt = open(CONSOLE, "rb").read().replace(b"\x00", b"").decode("utf-8", "replace")
    out = {}
    for m in re.finditer(r"ZEDQA wgrey RECT (\S+) (-?\d+) (-?\d+) (\d+) (\d+)", txt):
        out[m.group(1)] = tuple(int(v) for v in m.groups()[1:])      # a later run of the same name wins
    return out


def main(argv):
    margin = int(argv[argv.index("--margin") + 1]) if "--margin" in argv else 12
    out_dir = argv[argv.index("--out") + 1] if "--out" in argv else OUT
    os.makedirs(out_dir, exist_ok=True)
    got = {}
    for name, (x, y, w, h) in rects().items():
        src = os.path.join(SHOTS, f"zqa_wg_{name}.png")
        if not os.path.exists(src):
            print("missing", src); continue
        im = Image.open(src).convert("RGB")
        box = (max(0, x - margin), max(0, y - margin), min(im.width, x + w + margin), min(im.height, y + h + margin))
        crop = im.crop(box)
        dst = os.path.join(out_dir, f"{name}.jpg")
        crop.save(dst, quality=92)
        got[name] = crop
        print(f"{name}: {box} -> {crop.size}")
        if "--clean" in argv: os.remove(src)
    if "--sheet" in argv:
        states = {}
        for name, im in got.items():
            state, _, kind = name.partition("_")
            if name.startswith("miny"): state, _, kind = name.partition("_")
            states.setdefault(state, []).append((kind, im))
        for state, items in states.items():
            W = sum(i.width + 8 for _, i in items) + 8
            H = max(i.height for _, i in items) + 16
            sheet = Image.new("RGB", (W, H), (60, 60, 60))
            x = 8
            for _, i in items:
                sheet.paste(i, (x, 8)); x += i.width + 8
            sheet.save(os.path.join(out_dir, f"sheet_{state}.jpg"), quality=90)
    print(len(got), "crops in", out_dir)


if __name__ == "__main__":
    main(sys.argv[1:])
