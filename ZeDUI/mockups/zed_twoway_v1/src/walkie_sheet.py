"""review sheets for the two-way radios mockup: python walkie_sheet.py [ids]"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import physlib
import preview as PV
import d_walkie as DW

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out_walkie")
os.makedirs(OUT, exist_ok=True)


def reading(kind, on=True, freq="146.520", name="Sheriff dispatch", ch=2, batt=3, vol=4, mic_live=False):
    if not on: return {}
    if kind == "toy": return {"big": f"{freq} MHZ"}
    if kind in ("walkiechar", "hamchar"):
        return {"l1": f"CH{ch:02d} {freq}"[:16], "l2": name.upper()}
    return {"chLabel": "CH", "ch": f"{ch:02d}", "big": freq, "line": name.upper(), "batLabel": "BAT", "batt": batt,
            "volLabel": "VOL", "vol": vol, "tx": "TX" if mic_live else "MIC OFF"}


def state(kind, on=True, mic_live=False, range_=None, **kw):
    s = {"range": range_ if on else None, "power": on, "radioOn": on, "micLive": mic_live and on, "volF": kw.get("vol", 4) / 6, "tuneF": 0.4, "bandF": 0.35,
         "display": reading(kind, on, mic_live=mic_live, **kw)}
    return s


MODELS = [  # id, design, display kind, states
    ("walkie_toy", DW.toy, "toy", dict(freq="121.40")),
    ("walkie_valutech", DW.valutech, "walkie", dict(freq="146.520", name="Farm", ch=1)),
    ("walkie_premium", DW.premium, "walkie", dict(freq="162.400", name="Weather", ch=3)),
    ("walkie_tactical", DW.tactical, "walkie", dict(freq="295.000", name="Sheriff dispatch", ch=2, mic_live=True)),
    ("walkie_army", DW.army, "walkie", dict(freq="500.000", name="Base camp", ch=4)),
    ("walkie_makeshift", DW.makeshift, "walkiechar", dict(freq="88.20", name="Bob", ch=1)),
    ("walkie_manpack", DW.manpack, "walkie", dict(freq="245.600", name="Convoy", ch=5, mic_live=True)),
]


def build(entry):
    pid, fn, kind, kw = entry
    p, base, spr = physlib.build(fn, [])
    for w in p.warnings: print("  !", pid, w)
    on = PV.render_state(base, p.parts, spr, state(kind, True, **kw))
    off = PV.render_state(base, p.parts, spr, state(kind, False))
    return p, base, on, off


def sheet(models, k=2, name="walkies_2x.png"):
    ims = []
    for e in models:
        p, base, on, off = build(e)
        print(e[0], p.W, "x", p.H, len(p.hits), "hits:", " ".join(h["id"] for h in p.hits))
        ims.append((e[0], on))
    pad = 16
    W = sum(im.width * k + pad for _, im in ims) + pad
    H = max(im.height for _, im in ims) * k + 2 * pad + 14
    s = Image.new("RGBA", (W, H), (30, 30, 32, 255)); d = ImageDraw.Draw(s); x = pad
    for nm, im in ims:
        s.alpha_composite(PV.scale(im, k), (x, pad)); d.text((x, H - pad - 8), nm, fill=(170, 170, 170)); x += im.width * k + pad
    s.save(os.path.join(OUT, name))
    return s


HAMS = [
    ("ham_civilian", DW.ham_civ, "walkie", dict(freq="146.520", name="Sheriff dispatch", ch=2, range_="RANGE 7 KM")),
    ("ham_army", DW.ham_army, "walkie", dict(freq="245.600", name="Base camp", ch=4, mic_live=True, range_="RANGE 20 KM")),
    ("ham_makeshift", DW.ham_make, "hamchar", dict(freq="146.520", name="Farm", ch=1)),
]


def column(models, k=2, name="hams_2x.png"):
    ims = []
    for e in models:
        p, base, on, off = build(e)
        print(e[0], p.W, "x", p.H, len(p.hits), "hits:", " ".join(h["id"] for h in p.hits))
        ims.append((e[0], on))
    pad = 16
    W = max(im.width for _, im in ims) * k + 2 * pad
    H = sum(im.height * k + pad + 12 for _, im in ims) + pad
    s = Image.new("RGBA", (W, H), (30, 30, 32, 255)); d = ImageDraw.Draw(s); y = pad
    for nm, im in ims:
        s.alpha_composite(PV.scale(im, k), (pad, y)); y += im.height * k + 2; d.text((pad, y), nm, fill=(170, 170, 170)); y += pad + 10
    s.save(os.path.join(OUT, name))
    return s


if __name__ == "__main__":
    ids = sys.argv[1:]
    w = [m for m in MODELS if not ids or m[0] in ids]
    h = [m for m in HAMS if not ids or m[0] in ids]
    if w: sheet(w)
    if h: column(h)
