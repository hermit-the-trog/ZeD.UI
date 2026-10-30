"""Review: the three laundry faces at 392 (the director's 1.75, 2x) in their states, then every width."""
import sys
from PIL import Image, ImageDraw, ImageFont
import plates_336  # noqa: F401
from physlib import build
import preview as PV
import d_laundry as L

FD = "/usr/share/fonts/truetype/dejavu/"
VARIANTS = [("clothes", "hasItems", True, {"clothes": True})]


def render(fn, W, states):
    p, base, sprites = build(fn, VARIANTS, W=W)
    return p, [PV.render_state(base, p.parts, sprites, st).convert("RGBA") for st in states]


def main(out, k=2, widths=(392,)):
    f = ImageFont.truetype(FD + "DejaVuSans.ttf", 14); fb = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 18)
    rows = [("Premium Technologies washer", L.washer, "washer",
             [("no power", L.state("washer", powered=False, water=3)), ("powered, no water", L.state("washer", water=0)),
              ("running: WASH, clothes in", L.state("washer", running=True, water=4, items=True, phase="phWash", drum=0.3))]),
            ("Premium Technologies dryer", L.dryer, "dryer",
             [("no power", L.state("dryer", powered=False)), ("powered, clothes in", L.state("dryer", items=True)),
              ("running: DRY", L.state("dryer", running=True, items=True, phase="phDry", drum=0.6))]),
            ("ValuTech washer-dryer", L.combo, "combo",
             [("powered, wash mode, no water", L.state("combo", water=0)), ("running: RINSE", L.state("combo", running=True, water=3, items=True, phase="phRinse", drum=0.2)),
              ("dry mode, running: COOL", L.state("combo", running=True, mode="dry", items=True, phase="phCool", drum=0.8))])]
    blocks = []
    for title, fn, kind, sts in rows:
        for W in widths:
            p, ims = render(fn, W, [s for _, s in sts])
            if p.warnings: print(title, W, p.warnings)
            blocks.append((f"{title} - {W}, face {p.W} x {p.H}", ims, [t for t, _ in sts]))
    up = lambda im: im.resize((im.width * k, im.height * k), Image.NEAREST)
    Wt = max(sum(up(i).width + 24 for i in ims) for _, ims, _ in blocks) + 40
    Ht = sum(up(ims[0]).height + 80 for _, ims, _ in blocks) + 20
    S = Image.new("RGBA", (Wt, Ht), (30, 31, 34, 255)); d = ImageDraw.Draw(S)
    y = 16
    for title, ims, labels in blocks:
        d.text((20, y), title, font=fb, fill=(230, 230, 224)); y += 28
        x = 20
        for im, t in zip(ims, labels):
            S.alpha_composite(up(im), (x, y)); d.text((x, y + up(im).height + 4), t, font=f, fill=(160, 160, 155)); x += up(im).width + 24
        y += up(ims[0]).height + 52
    S.save(out); print("wrote", out, S.size)


if __name__ == "__main__":
    ws = tuple(int(a) for a in sys.argv[2:]) or (392,)
    main(sys.argv[1], widths=ws)
