"""the radio tab with a two-way face in it: the faces at k=2 dropped into the 4K capture of the World window's radio tab
(ZeDUI/qa/padmap/run_world_radio_top_clean.png), the old chassis painted out. python walkie_comp.py"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import walkie_sheet as WS

SRC = os.environ.get("ZED_COMP_SRC", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "qa", "padmap", "run_world_radio_top_clean.png"))
BG = (26, 26, 26)
F_HEAD = ImageFont.truetype(os.environ.get("ZED_FONT_HEAD", "DejaVuSansCondensed-Bold.ttf"), 25)   # stand-ins for the window fonts
F_FOOT = ImageFont.truetype(os.environ.get("ZED_FONT_FOOT", "DejaVuSansMono-Bold.ttf"), 17)


def comp(entry, title, foot_l, foot_r, name, k=2):
    p, base, on, off = WS.build(entry)
    im = Image.open(SRC).convert("RGBA")
    d = ImageDraw.Draw(im)
    hb = im.getpixel((1520, 70))
    d.rectangle([990, 48, 1530, 96], fill=hb)
    d.text((996, 59), title, font=F_HEAD, fill=(240, 241, 241))
    d.rectangle([712, 112, 1552, 1780], fill=BG)
    face = on.resize((on.width * k, on.height * k), Image.NEAREST)
    im.alpha_composite(face, (732, 132))
    d.rectangle([720, 1786, 1545, 1814], fill=BG)
    d.text((732, 1790), foot_l, font=F_FOOT, fill=(220, 220, 220))
    d.text((1538, 1790), foot_r, font=F_FOOT, fill=(160, 160, 160), anchor="ra")
    im = im.crop((0, 0, im.width, 1846))
    im.save(os.path.join(WS.OUT, name))
    return im


if __name__ == "__main__":
    W = {m[0]: m for m in WS.MODELS + WS.HAMS}
    a = comp(W["walkie_valutech"], "ValuTech Walkie Talkie", "VALUTECH", "* 2-WAY PORTABLE", "comp_walkie.png")
    b = comp(W["ham_civilian"], "Premium Technologies Ham Radio", "PREMIUM TECHNOLOGIES", "* 2-WAY BASE SET", "comp_ham.png")
    both = Image.new("RGBA", (2 * 900 + 30, 1000), (14, 14, 15, 255))
    for i, im in enumerate((a, b)):
        c = im.crop((700, 20, 1617, 1846)).resize((900 // 2 * 2, int(1826 * 900 / 917) // 2 * 2))
        c.thumbnail((900, 1000))
        both.alpha_composite(c, (10 + i * 910, 0))
    both.save(os.path.join(WS.OUT, "comp_both.png"))
    print("ok")
