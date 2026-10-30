"""Round 2 review: the other five faces at the director's 1.75 (2x): the black radio, the CD player and the makeshift
radio in the 180 panel, the black and antique TVs at 392; each off and on with the live parts drawn (the TV picture
is a stand-in, Code draws the real one)."""
import sys
from PIL import Image, ImageDraw, ImageFont
import plates_336  # noqa: F401
import rtv_sheet as S1
import d_rtv as R
import d_rtv_make as MK

FD = "/usr/share/fonts/truetype/dejavu/"


def st_black(on):
    s = R.state_port(on, freq="101.6", name="Knox Talk Radio", preset=3, batt=2)
    s["freqF"] = (101.6 - 88) / 20
    return s


def st_cd(on, phones=False):
    s = R.state_port(on, batt=3, phones=phones)
    if on: s["display"] = {"track": "03", "time": "3:42", "batt": 2, "line": "KENTUCKY RAIN"}
    s["hasMedia"] = on
    return s


def st_make(on):
    s = R.state_port(on, batt=1)
    if on: s["display"] = {"l1": "FM 93.2MHZ |||", "l2": "EMERGENCY BROADCAST"}
    return s


def st_ant(on):
    s = R.state_tv(on, ch=4, signal=3)
    s.update(chIdx=2, volF=0.55 if on else 0.0)
    return s


def main(out, k=2):
    rows = [(R.radio_black, 180, [st_black(False), st_black(True)], "ValuTech Radio - panel 180"),
            (R.cd_player, 180, [st_cd(False), st_cd(True, phones=True)], "CD Player - panel 180"),
            (MK.radio_make, 180, [st_make(False), st_make(True)], "Makeshift Radio - panel 180"),
            (R.tv_black, 392, [R.state_tv(False, power=False), R.state_tv(True, ch=7, signal=4, tape=True, counter="1:05:33")], "ValuTech Television - 392"),
            (R.tv_antique, 392, [st_ant(False), st_ant(True)], "Antique Television - 392")]
    f = ImageFont.truetype(FD + "DejaVuSans.ttf", 14); fb = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 18)
    up = lambda im: im.resize((im.width * k, im.height * k), Image.NEAREST)
    built = []
    for fn, W, sts, t in rows:
        p, ims = S1.face(fn, W, sts)
        built.append((p, [up(i) for i in ims], t))
    # radios three across in one band, TVs two across each
    rad = built[:3]; tvs = built[3:]
    rw = sum(max(i.width for i in b[1]) * 2 + 60 for b in rad)
    tw = max(sum(i.width + 30 for i in b[1]) for b in tvs)
    W_ = max(rw, tw) + 40
    rh = max(b[1][0].height for b in rad) + 60
    H_ = 20 + rh + sum(b[1][0].height + 70 for b in tvs) + 20
    S = Image.new("RGBA", (W_, H_), (30, 31, 34, 255)); d = ImageDraw.Draw(S)
    x = 20
    for p, ims, t in rad:
        d.text((x, 12), f"{t}, face {p.W} x {p.H}", font=fb, fill=(230, 230, 224))
        xx = x
        for im, lab in zip(ims, ("off", "on")):
            S.alpha_composite(im, (xx, 40)); d.text((xx, 44 + im.height), lab, font=f, fill=(160, 160, 155)); xx += im.width + 20
        x = xx + 40
    y = 20 + rh + 20
    for p, ims, t in tvs:
        d.text((20, y), f"{t}, {p.W} x {p.H}", font=fb, fill=(230, 230, 224)); y += 28
        xx = 20
        for im, lab in zip(ims, ("no power / off", "on")):
            S.alpha_composite(im, (xx, y)); d.text((xx, y + im.height + 4), lab, font=f, fill=(160, 160, 155)); xx += im.width + 30
        y += ims[0].height + 42
    S.save(out); print("wrote", out, S.size)
    for p, _, _ in built: print(p.id, p.W, p.H, [h["id"] for h in p.hits], p.warnings or "")


if __name__ == "__main__":
    main(sys.argv[1])
