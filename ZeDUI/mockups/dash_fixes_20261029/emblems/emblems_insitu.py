"""The picked emblems on real dashes, beside each maker's wordmark (proof): the emblem painted on its own transparent
canvas through the engine, laid on the drive preview left of the badge plate, centred on the wordmark's line.
usage (from tools/dashpx): py -3.14 C:\\Temp\\emblems_insitu.py out.png"""
import sys, os, json
sys.path.insert(0, os.getcwd()); sys.path.insert(0, r"C:\Temp")
import numpy as np
from PIL import Image
from engine import Dash
import emblems_r1 as E

OUT = os.path.join(os.getcwd(), "out")
PICK = {"chevalier": E.chev_a, "dash": E.dash_a, "franklin": E.frank_a, "mercia": E.merc_b, "masterson": E.mast_a}
CASES = [("d6", "chevalier", "make"), ("nyala", "chevalier", "make"), ("dashelite", "dash", "full"), ("bulldriver", "dash", "make"),
         ("van", "franklin", "make"), ("suv", "franklin", "sub"), ("luxury", "mercia", "model"), ("horizon", "masterson", "make")]


def sprite(fn):
    d = Dash(24, 24, seed=3)
    E.d, E.M = d, d.M
    fn(2, 2)
    img = d.render().convert("RGBA")
    a = np.array(img); a[..., 3] = np.where(d.solid, 255, 0).astype(np.uint8)
    return Image.fromarray(a)


spr = {k: sprite(f) for k, f in PICK.items()}
crops = []
for did, maker, role in CASES:
    doc = json.load(open(os.path.join(OUT, did, f"dash_{did}.json")))
    img = Image.open(os.path.join(OUT, did, "live_drive_1x.png")).convert("RGBA")
    b = [p for p in doc["parts"] if p["t"] == "badge" and p["role"] == role][0]
    cy = b["y"] + b["h"] / 2.0
    s = spr[maker]
    x = int(b["x"] - 4 - 24)
    img.alpha_composite(s, (x, int(round(cy - 12))))
    crops.append(img.crop((494, 0, 800, 120)))
w, h = crops[0].size
sheet = Image.new("RGBA", (w * 2 + 6, (h + 6) * 4), (0, 0, 0, 255))
for i, c in enumerate(crops): sheet.paste(c, ((i % 2) * (w + 6), (i // 2) * (h + 6)))
sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(sys.argv[1])
print(sheet.size)
