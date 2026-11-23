"""Before / after sheet for the director: the laundry machines' narrow faces as they were (188 x 214) and redrawn to fit
the half card's 138-unit body at 1x (130 x 190), each in a few states, on a 138-wide strip marking the card's body.
(Narrow washer, the director, Nov 22 2026)
usage: python make_sheet.py   (writes before_after.png and after_<face>.png beside this file)"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.normpath(os.path.join(HERE, "..", "..", "tools", "physpx"))
sys.path.insert(0, TOOLS)
import rtv_plates  # noqa: E402,F401
import d_laundry as L  # noqa: E402
import preview as PV  # noqa: E402
from physlib import build  # noqa: E402
from plates import DESIGNS  # noqa: E402

K = 3
BODY = 138
FACES = [("washer_n", "Premium Technologies washer (top-loader)", "washer",
          [("no power", L.state("washer", powered=False)),
           ("running: WASH, clothes in, water 4", L.state("washer", running=True, water=4, items=True, phase="phWash"))]),
         ("dryer_n", "Premium Technologies dryer", "dryer",
          [("no power", L.state("dryer", powered=False)),
           ("running: DRY, clothes in", L.state("dryer", running=True, items=True, phase="phDry", drum=0.6))]),
         ("washer_dryer_n", "ValuTech washer-dryer", "combo",
          [("wash mode, no water", L.state("combo", water=0)),
           ("running: RINSE, clothes in, water 3", L.state("combo", running=True, water=3, items=True, phase="phRinse", drum=0.2))])]


def renders(pid, states):
    D = DESIGNS[pid]
    p, base, sprites = build(D["fn"], D["variants"], **D.get("base", {}))
    return p, [PV.render_state(base, p.parts, sprites, st).convert("RGBA") for _, st in states]


def old_geometry():
    """the face as it was: 188 x 214 and the 188 layout (no narrow console)"""
    L.NARROW_W, L.NARROW_H, L.TIGHT = 188, 214, 0


def new_geometry():
    L.NARROW_W, L.NARROW_H, L.TIGHT = 130, 190, 150


def font(sz, bold=False):
    for name in (("arialbd.ttf" if bold else "arial.ttf"), "DejaVuSans.ttf"):
        try: return ImageFont.truetype(name, sz)
        except OSError: pass
    return ImageFont.load_default()


def on_body(im):
    """the face centred on a strip the width of the half card's body (138), as the card centres it; what runs past
    the strip is what overhung the card"""
    w = max(BODY, im.width) + 40
    S = Image.new("RGBA", (w, im.height + 8), (30, 31, 34, 255))
    d = ImageDraw.Draw(S)
    bx = (w - BODY) // 2
    d.rectangle([bx, 0, bx + BODY - 1, im.height + 7], fill=(58, 60, 66, 255))
    S.alpha_composite(im, ((w - im.width) // 2 if im.width <= BODY else bx + (BODY - im.width) // 2, 4))
    d.line([bx - 1, 0, bx - 1, im.height + 7], fill=(255, 90, 60, 255))
    d.line([bx + BODY, 0, bx + BODY, im.height + 7], fill=(255, 90, 60, 255))
    return S


def main():
    up = lambda im: im.resize((im.width * K, im.height * K), Image.NEAREST)
    fb, f = font(26, True), font(18)
    rows = []
    for pid, title, kind, states in FACES:
        old_geometry(); _, before = renders(pid, states)
        new_geometry(); p, after = renders(pid, states)
        rows.append((pid, title, states, before, after, p))
        up(after[-1]).save(os.path.join(HERE, f"after_{pid}.png"))
    tiles = []
    for pid, title, states, before, after, p in rows:
        tb = [up(on_body(im)) for im in before]
        ta = [up(on_body(im)) for im in after]
        tiles.append((pid, title, states, tb, ta))
    colw = max(t.width for _, _, _, tb, ta in tiles for t in tb + ta) + 24
    W = 40 + colw * 4
    H = 90 + sum(max(t.height for t in tb + ta) + 110 for _, _, _, tb, ta in tiles)
    S = Image.new("RGBA", (W, H), (22, 23, 26, 255))
    d = ImageDraw.Draw(S)
    d.text((20, 16), "Narrow laundry faces: before (188 x 214, overhangs the half card) and after (130 x 190, fits at 1x)",
           font=fb, fill=(235, 235, 228))
    d.text((20, 50), "Grey strip = the half card's 138-unit body at 1x; red lines = its edges. Shown at 3x.", font=f,
           fill=(170, 170, 165))
    y = 90
    for pid, title, states, tb, ta in tiles:
        d.text((20, y), f"{title}  ({pid})", font=fb, fill=(235, 235, 228)); y += 40
        x = 20
        for i, (tile, tag) in enumerate([(t, "BEFORE") for t in tb] + [(t, "AFTER") for t in ta]):
            lab = states[i % len(states)][0]
            S.alpha_composite(tile, (x, y))
            d.text((x, y + tile.height + 6), f"{tag}: {lab}", font=f, fill=(200, 200, 195) if tag == "AFTER" else (150, 150, 145))
            x += colw
        y += max(t.height for t in tb + ta) + 70
    S.convert("RGB").save(os.path.join(HERE, "before_after.png"))
    print("wrote", os.path.join(HERE, "before_after.png"), S.size)


if __name__ == "__main__":
    main()
