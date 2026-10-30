"""Review: every radio, CD player and TV face at every width it ships at, lit (2x)."""
import sys
from PIL import Image, ImageDraw, ImageFont
import plates_336  # noqa: F401
import rtv_sheet as S
import rtv_sheet2 as S2
import d_rtv as R
import d_rtv_make as MK

FD = "/usr/share/fonts/truetype/dejavu/"
HALF = (154, 180, 206, 257)
FULL = (200, 336, 392, 450, 562)
ROWS = [("ValuTech Radio", R.radio_black, HALF, S2.st_black(True)),
        ("Premium Technologies Radio", R.radio_red, HALF, R.state_port(True, freq="98.4", name="Knox Talk Radio", preset=2, batt=3)),
        ("Makeshift Radio", MK.radio_make, HALF, S2.st_make(True)),
        ("CD Player", R.cd_player, HALF, S2.st_cd(True, phones=True)),
        ("Premium Technologies Television", R.tv_wide, FULL, R.state_tv(True, ch=8, signal=4, tape=True)),
        ("ValuTech Television", R.tv_black, FULL, R.state_tv(True, ch=3, signal=2)),
        ("Antique Television", R.tv_antique, FULL, S2.st_ant(True))]


def main(out, k=2, only=None):
    f = ImageFont.truetype(FD + "DejaVuSans.ttf", 14); fb = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 18)
    blocks = []
    for title, fn, ws, st in ROWS:
        if only and title not in only: continue
        ims = []
        for W in ws:
            try:
                p, im = S.face(fn, W, [st]); ims.append((W, p, im[0]))
            except Exception as e:
                print(title, W, "FAILED", e); ims.append((W, None, None))
        blocks.append((title, ims))
    up = lambda im: im.resize((im.width * k, im.height * k), Image.NEAREST)
    Wt = max(sum((up(i).width if i else 300) + 24 for _, _, i in ims) for _, ims in blocks) + 40
    Ht = sum(max((up(i).height if i else 40) for _, _, i in ims) + 70 for _, ims in blocks) + 20
    Sht = Image.new("RGBA", (Wt, Ht), (30, 31, 34, 255)); d = ImageDraw.Draw(Sht)
    y = 16
    for title, ims in blocks:
        d.text((20, y), title, font=fb, fill=(230, 230, 224)); y += 28
        x = 20; hmax = 0
        for W, p, im in ims:
            if im is None:
                d.text((x, y + 10), f"{W}: not laid out", font=f, fill=(220, 120, 110)); x += 300; continue
            Sht.alpha_composite(up(im), (x, y))
            warn = f"  {len(p.warnings)} warnings" if p.warnings else ""
            d.text((x, y + up(im).height + 4), f"{W}  (face {p.W} x {p.H}){warn}", font=f, fill=(160, 160, 155) if not warn else (230, 120, 110))
            x += up(im).width + 24; hmax = max(hmax, up(im).height)
        y += hmax + 42
    Sht.save(out); print("wrote", out, Sht.size)


if __name__ == "__main__":
    main(sys.argv[1], only=sys.argv[2:] or None)
