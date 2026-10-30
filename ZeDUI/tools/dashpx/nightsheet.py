"""A contact sheet of the dashboards from day to night: per design, at the art zoom k (default 2), side by side:
  day | dusk (half dark, the dash lights on) | night, lights on | night, lights off
The live parts are drawn by live.py's copy of the game's rule (ZeD_Plate.lua): the plate's night picture over the day
one by the nightness, the parts that make no light dimmed by the light map under them, the lamps and displays as they are.

usage: python nightsheet.py <out.png> [k] [design ...] [--needles own|lit]
  --needles: the needles on gauges lit in another colour than amber (the late models' green), light-piped in their own
             colour ("own") or lit like everything else ("lit"); default designs.NEEDLES_UNDER_TINT"""
import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

try:
    from scipy import ndimage  # noqa: F401
except ImportError:
    import ndi_np
    ndi_np.install_as_scipy()
import build
import designs as DZ
import night as NT
import radios
from live import Night

FONTS = ["C:/Windows/Fonts/consola.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"]
COLS = (("DAY", 0.0, True), ("DUSK, LIGHTS ON", 0.5, True), ("NIGHT, LIGHTS ON", 1.0, True), ("NIGHT, LIGHTS OFF", 1.0, False))


def font(sz):
    for p in FONTS:
        if os.path.exists(p): return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def heads_for_preview():
    out = {}
    for kind, (img, parts, sprites) in radios.build().items():
        NT.head_glass(img, parts)
        out[kind] = (img, parts)
    return out


def tiles(did, heads, k=2, needles=None):
    b, base, sprites, doc, dt = build.build_one(did)
    blank = Image.open(os.path.join(radios.OUT, "hu_blank.png"))
    sprites["hu_blank"] = blank
    night, dark, data, lv = NT.bake(did, b, base, DZ.NIGHT[did], seed=DZ.DESIGNS[did][2], needles=needles or DZ.NEEDLES_UNDER_TINT)
    out = []
    for label, n, lit in COLS:
        nt = Night(n, lit, lv, night, dark, data["glass"], data["cell"], data=data) if n > 0 else None
        extra = {"lights": lit}
        out.append((label, build.preview(did, base, sprites, doc, heads=heads, state="drive", k=k, extra=extra, night=nt)))
    return out


def main(path, k=2, ids=None, needles=None):
    ids = ids or DZ.ORDER
    heads = heads_for_preview()
    pad, head = 16, 34
    f1, f2 = font(22), font(16)
    rows = []
    for did in ids:
        rows.append((did, tiles(did, heads, k, needles)))
        print(did, flush=True)
    tw, th = rows[0][1][0][1].size
    W = len(COLS) * (tw + pad) + pad
    H = len(rows) * (th + head + pad) + pad
    sh = Image.new("RGBA", (W, H), (20, 20, 22, 255))
    dr = ImageDraw.Draw(sh)
    for r, (did, ts) in enumerate(rows):
        y = pad + r * (th + head + pad)
        for c, (label, im) in enumerate(ts):
            x = pad + c * (tw + pad)
            dr.text((x, y + 4), f"{DZ.ORDER.index(did) + 1}  {DZ.DESIGNS[did][0]}  |  {label}", fill=(236, 232, 222), font=f1 if c == 0 else f2)
            back = Image.new("RGBA", im.size, (14, 16, 18, 255))       # the road at night behind the transparent edges
            back.alpha_composite(im)
            sh.paste(back, (x, y + head))
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    sh.save(path)
    return path


if __name__ == "__main__":
    args = sys.argv[1:]
    nd = None
    if "--needles" in args:
        i = args.index("--needles"); nd = args[i + 1]; del args[i:i + 2]
    p = args[0] if args else os.path.join(build.OUT, "night_contact.png")
    k = int(args[1]) if len(args) > 1 else 2
    print(main(p, k, args[2:] or None, nd))
