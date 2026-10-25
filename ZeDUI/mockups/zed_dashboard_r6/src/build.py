"""Builds the dashboards: plate PNG, state sprites, the parts file, and previews of the live parts at a few states.
usage: python build.py [design ...]   (no names: all)"""
import copy
import json
import os
import sys
import time
import numpy as np
from PIL import Image, ImageDraw
import dashlib
from dashlib import Build, tab_sprite, TAB_SPRITES
from live import render_live
import designs as DZ
import radios

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
os.makedirs(OUT, exist_ok=True)

STATES = {
    "off": dict(keysIn=False, keyPos=None, ashOpen=False, meterOn=False, hula=0, running=False, lights=False, speed_kmh=0, rpm=0, fuel=0.6, battery=0.8, heaterOn=False, heaterTemp=0, fan=0,
                gear="P", hour=10, minute=8),
    "keyon": dict(keysIn=True, keyPos="off", ashOpen=False, meterOn=False, hula=0, running=False, lights=False, speed_kmh=0, rpm=0, fuel=0.62, battery=0.9, heaterOn=False, heaterTemp=0,
                  fan=0, radio=None, radioOn=False, gear="P", anyLocked=False, hour=10, minute=8),
    "drive": dict(keysIn=True, keyPos="on", meterOn=True, hula=1, fare=12.80, fareExtra=0.5, running=True, lights=True, speed_kmh=72, rpm=2600, fuel=0.62, battery=0.9, heaterOn=True, heaterTemp=17,
                  fan=2, ac=False, radio="valutech", radioOn=True, radioFreq="98.4", gear="D", anyLocked=True, cruise=True,
                  lightbar=2, siren=1, hour=10, minute=8),
}


def badge_names(did):
    title, cabin, seed, fn, sub, unit, radio = DZ.DESIGNS[did]
    words = title.upper().split()
    make, model = (words[0], " ".join(words[1:])) if len(words) > 1 else (words[0], words[0])
    return {"badge_full": title.upper(), "badge_make": make, "badge_model": model, "badge_sub": sub or "", "badge_unit": unit or "",
            "radio": radio}


def cut_variant(base, img):
    a = np.array(base); b_ = np.array(img)
    diff = np.any(a != b_, axis=2)
    if not diff.any(): return None, None
    ys, xs = np.nonzero(diff)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    sub = b_[y0:y1, x0:x1].copy()
    sub[~diff[y0:y1, x0:x1], 3] = 0
    return Image.fromarray(sub, "RGBA"), (int(x0), int(y0))


def build_one(did, verbose=True):
    title, cabin, seed, fn, sub, unit, radio = DZ.DESIGNS[did]
    t0 = time.time()
    b = Build(did, cabin, seed=seed, title=title)
    fn(b)
    base = b.d.render()
    sprites = {}
    for name, src, vfn, when in b.variants:
        d2 = copy.deepcopy(b.d)
        vfn(d2)
        img = d2.render()
        spr, at = cut_variant(base, img)
        if spr is None: b.warn(f"variant {name} changed nothing"); continue
        sprites[name] = spr
        b.part("sprite", src=src, when=when, sprite=name, x=at[0], y=at[1], w=spr.width, h=spr.height)
    for name, im in getattr(b, "extra", {}).items():     # hand-set sprites (round 6: the taxi's hula girl)
        sprites[name] = im
    for k in TAB_SPRITES:
        if any(p.get("sprite") == k for p in b.parts): sprites[k] = tab_sprite(k)
    # a lever tab or slider knob sweeps its whole travel: no printed legend or mark may lie under it anywhere
    for p in b.parts:
        if p["t"] != "tab" or p["sprite"] not in sprites: continue
        sw, sh = sprites[p["sprite"]].size
        rx0, ry0, rx1, ry1 = p["x0"], p["y"], p["x1"] + sw, p["y"] + sh
        for (ix, iy, iw, ih, what) in b.inks:
            if ix < rx1 and ix + iw > rx0 and iy < ry1 and iy + ih > ry0:
                b.warn(f"{what} at {ix},{iy} lies under the {p['src']} tab's travel ({rx0},{ry0} to {rx1},{ry1})")
    ddir = os.path.join(OUT, did); os.makedirs(ddir, exist_ok=True)
    base.save(os.path.join(ddir, f"dash_{did}.png"))
    for k, im in sprites.items(): im.save(os.path.join(ddir, f"{k}.png"))
    meta = {kk: vv for kk, vv in b.meta.items() if kk != "face_mask"}
    doc = {"id": did, "title": title, "cabin": cabin, "w": dashlib.W, "h": dashlib.H, "meta": meta, "parts": b.parts, "hits": b.hits,
           "sprites": {k: [im.width, im.height] for k, im in sprites.items()}}
    with open(os.path.join(ddir, f"dash_{did}.json"), "w") as f: json.dump(doc, f, separators=(",", ":"))
    return b, base, sprites, doc, time.time() - t0


DECALS = os.environ.get("ZED_DECALS", "/mnt/user-data/uploads/Project Zomboid/SteamApps/common/ProjectZomboid/media/textures/shirtdecals")
ASH_OPEN = {"taxi", "d6", "bulldriver", "horizon", "rancher", "cossette", "dart"}   # the previews' used ash trays


def preview(did, base, sprites, doc, heads=None, state="drive", k=1, extra=None, night=None):
    st = dict(STATES[state]); st.update(badge_names(did))
    if state == "drive": st["ashOpen"] = did in ASH_OPEN
    if did == "van" and state != "off":        # the previews' van is the Spiffo's
        p_ = os.path.join(DECALS, "Buisness_SpiffosDECAL.png")
        if os.path.exists(p_): st["sticker_im"] = Image.open(p_).convert("RGBA")
    if state in ("off", "keyon"): st["radioOn"] = False
    if extra: st.update(extra)
    return render_live(base, doc, st, k=k, sprites=sprites, heads=heads, night=night)


if __name__ == "__main__":
    names = sys.argv[1:] or DZ.ORDER
    heads = radios.build()
    blank = Image.open(os.path.join(radios.OUT, "hu_blank.png"))
    for did in names:
        b, base, sprites, doc, dt = build_one(did)
        sprites["hu_blank"] = blank
        for stn in ("off", "keyon", "drive"):
            for k in (1, 2):
                preview(did, base, sprites, doc, heads=heads, state=stn, k=k).save(os.path.join(OUT, did, f"live_{stn}_{k}x.png"))
        print(f"{did:10s} {dt:5.1f}s parts={len(doc['parts']):3d} hits={len(doc['hits']):2d} sprites={len(sprites)}")
        for w in b.warnings: print("   !", w)
