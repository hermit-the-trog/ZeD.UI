"""Contact sheets of the dashboards: numbered, named, at a whole-number scale (nearest), live parts in a given state."""
import os
import sys
from PIL import Image, ImageDraw, ImageFont
import designs as DZ

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
FONT_PATHS = ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]


def font(sz, bold=True):
    for p in (FONT_PATHS if bold else FONT_PATHS[1:]):
        if os.path.exists(p): return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def sheet(ids, state="drive", k=1, out="sheet.png", bg=(24, 24, 26), cols=1, notes=None):
    tiles = []
    for did in ids:
        p = os.path.join(OUT, did, f"live_{state}_{k}x.png")
        tiles.append((did, Image.open(p).convert("RGBA")))
    tw, th = tiles[0][1].size
    head = 30 if k >= 2 else 24
    pad = 14
    rows = (len(tiles) + cols - 1) // cols
    W = cols * (tw + pad) + pad
    H = rows * (th + head + pad) + pad
    sh = Image.new("RGBA", (W, H), bg + (255,))
    dr = ImageDraw.Draw(sh)
    f1, f2 = font(16 if k >= 2 else 14), font(13 if k >= 2 else 11, bold=False)
    for i, (did, im) in enumerate(tiles):
        c, r = i % cols, i // cols
        x = pad + c * (tw + pad); y = pad + r * (th + head + pad)
        n = DZ.ORDER.index(did) + 1
        title = DZ.DESIGNS[did][0]
        dr.text((x, y + 2), f"{n}  {title}", fill=(236, 232, 222), font=f1)
        if notes and did in notes:
            dr.text((x + 330 * (1 if k == 1 else 1.4), y + 4), notes[did], fill=(150, 146, 138), font=f2)
        # a grass-and-asphalt backdrop behind the transparent edges, like the game behind the dash
        back = Image.new("RGBA", im.size, (52, 60, 40, 255))
        back.alpha_composite(im)
        sh.paste(back, (x, y + head))
    sh.save(os.path.join(OUT, out))
    return os.path.join(OUT, out)


if __name__ == "__main__":
    state = sys.argv[1] if len(sys.argv) > 1 else "drive"
    print(sheet(DZ.ORDER, state=state, k=1, out=f"sheet_{state}_1x.png"))
