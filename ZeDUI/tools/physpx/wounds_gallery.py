"""Every per-part wound picture at once, one figure per kind (bandage, dirty bandage, splint, fracture, one mark, two
marks and bleeding), both sexes, Dark, at 2x: for checking each part's art. usage: python wounds_gallery.py ROOT OUT.png
(ROOT holds the exported art: d_skeleton.py and d_wounds.py)"""
import os, sys
from PIL import Image, ImageDraw, ImageFont
import d_skeleton as S, d_wounds as WD, wounds_sheet as WS
root = sys.argv[1]; out = sys.argv[2]
pics = {}; places = {}
for sex in "mf":
    b = WD.Body(sex); pics[sex], places[sex] = WD.pictures(b)
layouts = {sex: WS.layout_of(pics[sex], places[sex]) for sex in "mf"}
tex = WS.Tex(root)
font = WS.font(15)
P = S.PARTS
states = [
    ("Bandage, every part", {p: dict(bandage="clean") for p in P}),
    ("Dirty, every part", {p: dict(bandage="dirty") for p in P}),
    ("Splint, every part", {p: dict(splint=True) for p in P if p not in WD.NO_SPLINT}),
    ("Fracture, every part", {p: dict(fracture=True) for p in P}),
    ("One mark (cut)", {p: dict(marks=["cut"]) for p in P}),
    ("Two marks + bleed", {p: dict(marks=["bite", "scratch"], bleed=True) for p in P}),
]
K = 2
cw, ch = S.FW * K + 16, S.FH * K + 36
img = Image.new("RGB", (len(states) * 2 * cw + 20, ch + 20), (40, 38, 34))
d = ImageDraw.Draw(img)
for i, (name, w) in enumerate(states):
    for j, sex in enumerate("mf"):
        x = 10 + (i * 2 + j) * cw
        fig = WS.figure(tex, layouts[sex], sex, "dark", None, w, WS.TONE[sex], K)
        img.paste(fig, (x, 34))
        d.text((x, 8), name if j == 0 else "", fill=(220, 218, 214), font=font)
img.save(out); print(out, img.size)
