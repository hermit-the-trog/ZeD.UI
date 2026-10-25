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
    d.rectangle([990, 48, 1480, 96], fill=hb)
    d.text((996, 59), title, font=F_HEAD, fill=(240, 241, 241))
    d.rectangle([712, 112, 1552, 1780], fill=BG)
    face = on.resize((on.width * k, on.height * k), Image.NEAREST)
    x0 = 732 + ((220 - on.width) * k // 2 if on.width <= 220 else (402 - on.width) * k // 2)   # a walkie centred in its 220 panel
    im.alpha_composite(face, (x0, 132))
    # the full view button at the header's right end (the map's pop-out button's place and size)
    bx, by, bs = 1488, 50, 40
    d.rectangle([bx, by, bx + bs, by + bs], outline=(110, 112, 112), width=2, fill=(32, 34, 34))
    g = (240, 241, 241)
    for (ax, ay, sx, sy) in ((bx + 10, by + 10, 1, 1), (bx + bs - 10, by + bs - 10, -1, -1)):
        d.line([(ax, ay), (ax + sx * 9, ay + sy * 9)], fill=g, width=3)
        d.line([(ax, ay), (ax + sx * 9, ay)], fill=g, width=3); d.line([(ax, ay), (ax, ay + sy * 9)], fill=g, width=3)
    d.rectangle([720, 1786, 1545, 1814], fill=BG)
    d.text((732, 1790), foot_l, font=F_FOOT, fill=(220, 220, 220))
    d.text((1538, 1790), foot_r, font=F_FOOT, fill=(160, 160, 160), anchor="ra")
    im = im.crop((0, 0, im.width, 1846))
    im.save(os.path.join(WS.OUT, name))
    return im


STREET = os.environ.get("ZED_STREET", "ws_23_hud_only_street.png")    # Screenshots/workshop_src, 4K, HUD only


def full_view(entry, name, at=None, k=2):
    """full view: the face on its own over the world, no window frame (like the watch popped from the belt)"""
    p, base, on, off = WS.build(entry)
    im = Image.open(STREET).convert("RGBA")
    face = on.resize((on.width * k, on.height * k), Image.NEAREST)
    x, y = at or ((im.width - face.width) // 2 + 300, (im.height - face.height) // 2 - 200)
    sh = Image.new("RGBA", face.size, (0, 0, 0, 0)); sh.putalpha(face.getchannel("A").point(lambda a: 90 if a else 0))
    im.alpha_composite(sh, (x + 6, y + 8)); im.alpha_composite(face, (x, y))
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
    if os.path.exists(STREET):
        full_view(W["walkie_tactical"], "full_walkie_4k.png")
        full_view(W["ham_army"], "full_ham_4k.png")
    print("ok")
