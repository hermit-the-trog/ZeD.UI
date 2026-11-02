"""The Steam upload set from the PNG masters (Nov 1 2026).

  py make_upload.py [out_spread] [upload]

Writes, in upload order:
  00_cover.jpg   from znix_01_cover.png (cover_px.py)
  00_title.jpg   from out_spread/00_title.png (title_spread.py)
  01_hero.jpg .. 60_machine_plates.jpg   from out_spread/NN_id.png (spread.py)

Each JPEG is kept under Steam's 1 MB. Colour is kept at full resolution (4:4:4) wherever that fits, so the red and
blue ink and the 1-bit print stay sharp; only a picture that will not fit drops to 4:2:0. Stale JPEGs in the upload
folder (a spread renamed or removed) are reported, never deleted. Renders nothing itself: run spread.py and
title_spread.py first.
"""
import glob
import os
import re
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
LIMIT = 1000000
TRIES = [(92, 0), (90, 0), (88, 0), (85, 0), (92, 2), (88, 2), (84, 2), (80, 2)]   # (quality, subsampling: 0 = 4:4:4)


def save_under(png, jpg):
    im = Image.open(png).convert("RGB")
    tmp = jpg + ".tmp"
    for q, ss in TRIES:
        im.save(tmp, "JPEG", quality=q, subsampling=ss, optimize=True)
        if os.path.getsize(tmp) < LIMIT:
            break
    os.replace(tmp, jpg)
    return im.size, q, "4:4:4" if ss == 0 else "4:2:0", os.path.getsize(jpg)


def main(out=None, up=None):
    out = out or os.path.join(HERE, "out_spread")
    up = up or os.path.join(HERE, "upload")
    os.makedirs(up, exist_ok=True)
    jobs = [(os.path.join(HERE, "znix_01_cover.png"), "00_cover.jpg"),
            (os.path.join(out, "00_title.png"), "00_title.jpg")]
    spreads = sorted(p for p in glob.glob(os.path.join(out, "*.png")) if re.match(r"\d\d_", os.path.basename(p))
                     and not os.path.basename(p).startswith("00_"))
    jobs += [(p, os.path.basename(p)[:-4] + ".jpg") for p in spreads]
    bad = 0
    for png, name in jobs:
        if not os.path.exists(png):
            print("MISSING", png)
            bad += 1
            continue
        size, q, ss, n = save_under(png, os.path.join(up, name))
        flag = "" if size == (1920, 1080) else "  SIZE %dx%d" % size
        if n >= LIMIT or flag:
            bad += 1
        print("%-30s q%d %s %7d bytes%s" % (name, q, ss, n, flag))
    nums = [int(os.path.basename(p)[:2]) for p in spreads]
    if nums != list(range(1, 61)):
        print("CHECK the spreads are not 01..60:", nums)
        bad += 1
    wrote = set(name for _, name in jobs)
    for p in sorted(glob.glob(os.path.join(up, "*.jpg"))):
        if os.path.basename(p) not in wrote:
            print("STALE (not from these masters):", os.path.basename(p))
    print("%d pictures, %s" % (len(jobs), "all fit" if not bad else "%d problem(s)" % bad))
    return bad


if __name__ == "__main__":
    sys.exit(1 if main(*sys.argv[1:3]) else 0)
