"""The off-air screens on the three sets at the director's 1.75 (2x): each set's screen rect filled with a screen
rendered at that rect's size, its rounded corners masked; the antique set shows black and white (its tint)."""
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import plates_336  # noqa
from physlib import build
import preview as PV
import d_rtv as R
import offair as O
O.GAME_ROOT = '/mnt/user-data/uploads/Project Zomboid/SteamApps/common/ProjectZomboid'

FD = "/usr/share/fonts/truetype/dejavu/"


def on_set(fn, W, st, screen):
    p, base, sprites = build(fn, [], W=W)
    R.attach(p)
    im = PV.render_state(base, p.parts, sprites, st).convert("RGBA")
    q = [x for x in p.parts if x["t"] == "tvScreen"][0]
    a = O.crt(dict(O.screens())[screen](q["w"], q["h"]))
    if q.get("tint"):                                     # a black-and-white set: the picture's light, in the tube's tint
        lum = (a[..., 0] * 0.3 + a[..., 1] * 0.59 + a[..., 2] * 0.11)[..., None]
        a = lum * (np.array(O.hexc(q["tint"]), np.float32) / 255) * 1.15
    pic = O.to_img(a).convert("RGBA")
    m = Image.new("L", (q["w"], q["h"]), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, q["w"] - 1, q["h"] - 1], radius=q.get("r", 0), fill=255)
    im.paste(pic, (q["x"], q["y"]), m)
    return im


def main(out, k=2):
    rows = [(R.tv_wide, "bars", "Premium Technologies Television: colour bars"),
            (R.tv_black, "signoff_kpa", "ValuTech Television: KPATV signs off"),
            (R.tv_antique, "signoff_life", "Antique Television: Life and Living TV, in black and white"),
            (R.tv_wide, "signoff_triple_n", "Triple-N signs off (the game's logo)"),
            (R.tv_black, "snow_0", "No signal"),
            (R.tv_antique, "signoff_turbo", "Antique Television: TURBO (the game's logo)")]
    st = R.state_tv(True, ch=7, signal=4)
    ims = [(on_set(fn, 392, st, sc).resize((392 * k, 0 or 1), Image.NEAREST) if False else on_set(fn, 392, st, sc), t) for fn, sc, t in rows]
    ims = [(i.resize((i.width * k, i.height * k), Image.NEAREST), t) for i, t in ims]
    f = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 16)
    cw = max(i.width for i, _ in ims) + 30
    rh = [max(ims[j][0].height, ims[j + 1][0].height) + 40 for j in range(0, len(ims), 2)]
    S = Image.new("RGBA", (2 * cw + 20, sum(rh) + 20), (26, 26, 28, 255)); d = ImageDraw.Draw(S)
    y = 20
    for r, j in enumerate(range(0, len(ims), 2)):
        for c in range(2):
            im, t = ims[j + c]
            d.text((20 + c * cw, y), t, font=f, fill=(225, 225, 220))
            S.alpha_composite(im, (20 + c * cw, y + 24))
        y += rh[r]
    S.save(out); print("wrote", out, S.size)


if __name__ == "__main__":
    main(sys.argv[1])
