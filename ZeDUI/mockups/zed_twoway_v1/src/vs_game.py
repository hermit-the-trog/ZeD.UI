"""the faces beside the game's own art: python vs_game.py (needs the game's tiles and textures; see the paths)"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import walkie_sheet as WS
import preview as PV

R = os.environ.get("ZED_TILES", "ref/tiles2x") + "/appliances_com_01_"          # Tiles2x.pack, pulled with pz_unpack.py
I = os.environ.get("ZED_ICONS", "ref/icons") + "/Item_"                        # UI2.pack
T = os.environ.get("ZED_PZ_MEDIA", "media") + "/textures/weapons/1handed/WalkieTalkie_"


def tile(n, h=150):
    im = Image.open(R + f"{n}.png"); im = im.crop(im.getbbox()); s = max(1, h // im.height)
    return im.resize((im.width * s, im.height * s), Image.NEAREST)


def icon(n, h=150):
    im = Image.open(I + n + ".png"); im = im.crop(im.getbbox()); s = max(1, h // im.height)
    return im.resize((im.width * s, im.height * s), Image.NEAREST)


def tex(n, h=150): return Image.open(T + n + ".png").convert("RGBA").resize((h, h), Image.NEAREST)


def walkies(k=2, pad=16):
    refs = {"walkie_toy": [tile(16), tex("Toy")], "walkie_valutech": [tile(24), tex("ValuTech")], "walkie_premium": [tile(32), tex("Premium")],
            "walkie_tactical": [tile(40), tex("Tactical")], "walkie_army": [tile(48), tex("USArmy")], "walkie_makeshift": [tex("Makeshift")],
            "walkie_manpack": [icon("ManPack")]}
    ims = [(e[0], WS.build(e)[2]) for e in WS.MODELS]
    colw = 220 * k + pad; H = pad + 170 + 330 * k + pad + 20
    s = Image.new("RGBA", (pad + colw * len(ims), H), (30, 30, 32, 255)); d = ImageDraw.Draw(s)
    for i, (nm, on) in enumerate(ims):
        x = pad + i * colw; rx = x
        for r in refs[nm]: s.alpha_composite(r, (rx, pad)); rx += r.width + 8
        s.alpha_composite(PV.scale(on, k), (x, pad + 170))
        d.text((x, H - pad - 10), nm + ("   (top: the game's tile and model texture)" if i == 0 else ""), fill=(170, 170, 170))
    s.save(os.path.join(WS.OUT, "walkies_vs_game_2x.png"))


def hams(k=2, pad=16):
    rows = [(tile(n, 172), WS.build(e)[2]) for e, n in zip(WS.HAMS, (0, 8, 56))]
    W = pad * 3 + max(r[0].width for r in rows) + 400 * k; H = pad + len(rows) * (344 + pad)
    s = Image.new("RGBA", (W, H), (30, 30, 32, 255)); y = pad
    for t, on in rows:
        s.alpha_composite(t, (pad, y + (344 - t.height) // 2)); s.alpha_composite(PV.scale(on, k), (pad * 2 + t.width, y)); y += 344 + pad
    s.save(os.path.join(WS.OUT, "hams_vs_game_2x.png"))


if __name__ == "__main__":
    walkies(); hams(); print("ok")
