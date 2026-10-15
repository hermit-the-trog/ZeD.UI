import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw
from gen_buckles import SET
import belt_mock
here = os.path.dirname(os.path.abspath(__file__))
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "out")          # where the buckles are
prev = os.path.join(here, "previews"); os.makedirs(prev, exist_ok=True)
def sheet(names, sc=4, cols=5, path="sheet_4x.png", labels=True):
    ims = [Image.open(os.path.join(out, f"buckle_{n}.png")) for n in names]
    cw, ch = 58 * sc + 14, 40 * sc + (22 if labels else 14)
    rows = (len(ims) + cols - 1) // cols
    sh = Image.new("RGBA", (cols * cw + 14, rows * ch + 14), (40, 36, 30, 255)); d = ImageDraw.Draw(sh)
    for i, (n, im) in enumerate(zip(names, ims)):
        x = 14 + (i % cols) * cw; y = 14 + (i // cols) * ch
        sh.alpha_composite(im.resize((58 * sc, 40 * sc), Image.NEAREST), (x, y))
        if labels: d.text((x, y + 40 * sc + 2), f"{i+1}. {n}", fill=(170, 164, 150))
    sh.save(os.path.join(prev, path)); return sh
def belts(names, s=2.0, path="belt_2x.png", cols=2):
    rows = [belt_mock.render(Image.open(os.path.join(out, f"buckle_{n}.png")), 58, 40, s=s) for n in names]
    w, h = rows[0].width, rows[0].height
    m = Image.new("RGBA", (cols * w, ((len(rows) + cols - 1) // cols) * h), (28, 30, 24, 255))
    for i, r in enumerate(rows): m.alpha_composite(r, ((i % cols) * w, (i // cols) * h))
    m.save(os.path.join(prev, path)); return m
if __name__ == "__main__":
    names = [n for n, _ in SET]
    sheet(names, path="buckles_sheet_4x.png")
    belts(names, path="buckles_on_belt_2x.png")
    print("ok")
